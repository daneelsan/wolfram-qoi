#include "WolframLibrary.h"
#include "WolframNumericArrayLibrary.h"
#include "WolframImageLibrary.h"

#define QOI_IMPLEMENTATION
#define QOI_NO_STDIO
#include "qoi.h"

EXTERN_C DLLEXPORT mint WolframLibrary_getVersion(void)
{
    return WolframLibraryVersion;
}

EXTERN_C DLLEXPORT int WolframLibrary_initialize(WolframLibraryData libData)
{
    return 0;
}

EXTERN_C DLLEXPORT int wolfram_qoi_encode(WolframLibraryData libData, mint argc, MArgument *args, MArgument res)
{
    mint err = LIBRARY_NO_ERROR;
    if (argc != 1) {
        return LIBRARY_FUNCTION_ERROR;
    }

    WolframNumericArrayLibrary_Functions naFuns = libData->numericarrayLibraryFunctions;
    WolframImageLibrary_Functions imgFuns = libData->imageLibraryFunctions;

    MImage image = MArgument_getMImage(args[0]);

    void *image_data = imgFuns->MImage_getRawData(image);

    qoi_desc desc;
    desc.width = imgFuns->MImage_getColumnCount(image);
    desc.height = imgFuns->MImage_getRowCount(image);
    desc.channels = imgFuns->MImage_getChannels(image);
    // TODO: What is the equivalent of QOI_LINEAR in WL?
    desc.colorspace = (imgFuns->MImage_getColorSpace(image) == MImage_CS_RGB) ? QOI_SRGB : QOI_LINEAR;
    int size;

    unsigned char *encoded = qoi_encode(image_data, &desc, &size);
    if (encoded == NULL) {
        return LIBRARY_NO_ERROR;
    }

    MNumericArray byte_array;
    mint length = size;
    err = naFuns->MNumericArray_new(MNumericArray_Type_UBit8, 1, &length, &byte_array);
    if (err) {
        goto cleanup;
    }
    unsigned char *bytes = naFuns->MNumericArray_getData(byte_array);

    for (mint i = 0; i < size; i += 1) {
        bytes[i] = encoded[i];
    }

cleanup:
    QOI_FREE(encoded);
    if (err == LIBRARY_NO_ERROR) {
        MArgument_setMNumericArray(res, byte_array);
    }
    return err;
}

EXTERN_C DLLEXPORT int wolfram_qoi_decode(WolframLibraryData libData, mint argc, MArgument *args, MArgument res)
{
    mint err = LIBRARY_NO_ERROR;
    if (argc != 1) {
        return LIBRARY_FUNCTION_ERROR;
    }

    WolframNumericArrayLibrary_Functions naFuns = libData->numericarrayLibraryFunctions;
    WolframImageLibrary_Functions imgFuns = libData->imageLibraryFunctions;

    MNumericArray byte_array = MArgument_getMNumericArray(args[0]);
    void *data = naFuns->MNumericArray_getData(byte_array);
    int size = naFuns->MNumericArray_getFlattenedLength(byte_array);

    qoi_desc desc;
    qoi_rgba_t *rgba_pixels = qoi_decode(data, size, &desc, 4);
    if (rgba_pixels == NULL) {
        return LIBRARY_FUNCTION_ERROR;
    }

    MImage image;
    mbool alphaQ = desc.channels == 4;
    mint channels = alphaQ ? 4 : 3; 
    colorspace_t colorSpace = (desc.colorspace == QOI_SRGB) ? MImage_CS_RGB : MImage_CS_Automatic;
    err = imgFuns->MImage_new2D(desc.width, desc.height, channels, MImage_Type_Bit8, colorSpace, True, &image);
    if (err) { goto cleanup; }

    mint pos[2];
    for (mint row = 1; row <= desc.height; row += 1) {
        pos[0] = row;
        for (mint col = 1; col <= desc.width; col += 1) {
            pos[1] = col;
            qoi_rgba_t px = rgba_pixels[desc.width * (row - 1) + (col - 1)];

            for (int c = 1; c <= channels; c += 1) {
                raw_t_ubit8 byte = 0;
                switch (c) {
                    case 1: byte = px.rgba.r; break;
                    case 2: byte = px.rgba.g; break;
                    case 3: byte = px.rgba.b; break;
                    case 4: byte = px.rgba.a; break;
                }
                err = imgFuns->MImage_setByte(image, pos, c, byte);
                if (err) { goto cleanup; }
            }
        }
    }

cleanup:
    QOI_FREE(rgba_pixels);
    if (err == LIBRARY_NO_ERROR) {
        MArgument_setMImage(res, image);
    }
    return err;
}

