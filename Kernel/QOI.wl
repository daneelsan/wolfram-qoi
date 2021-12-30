(* ::Package:: *)

BeginPackage["QOI`"];

QOIEncode;
QOIDecode;

Begin["`Private`"];

(*******************************************************************************
QOIEncode
*******************************************************************************)

SyntaxInformation[QOIEncode] = {
	"ArgumentsPattern" -> {img_}
};

QOIEncode[args___] /; CheckArguments[QOIEncode[args], 1] := 
	Module[{img, dimensions, channels, colorSpace},
		img = ArgumentsOptions[QOIEncode[args], 1][[1, 1]];
		If[!ImageQ[img],
			Return @ Failure["QOIFailure", <|
				"MessageTemplate" -> "Invalid Image `1`.",
				"MessageParameters" -> {img},
				"Input" -> img
			|>]
		];

		dimensions = Length[ImageDimensions[img]];
		If[dimensions =!= 2,
			Return @ Failure["QOIFailure", <|
				"MessageTemplate" -> "Supported image dimensions: `1`.",
				"MessageParameters" -> {StringRiffle[{2}, ", "]},
				"Dimensions" -> dimensions
			|>]
		];

		channels = ImageChannels[img];
		If[channels =!= 3 && channels =!= 4,
			Return @ Failure["QOIFailure", <|
				"MessageTemplate" -> "Supported image channels: `1`.",
				"MessageParameters" -> {StringRiffle[{3, 4}, ", "]},
				"Channels" -> channels
			|>]
		];

		colorSpace = ImageColorSpace[img];
		If[colorSpace =!= "RGB",
			Return @ Failure["QOIFailure", <|
				"MessageTemplate" -> "Supported color spaces: `1`.",
				"MessageParameters" -> {StringRiffle[{"RGB"}, ", "]},
				"ColorSpace" -> colorSpace
			|>]
		];

		qoiEncode[img]
	];

qoiEncode[img_] := 
	Module[{init, ba},
		init = initializeLibrary[];
		If[FailureQ[init], Return[init]];

		ba = $libraryFunctions["qoi_encode"][img];

		If[ByteArrayQ[ba],
			ba
		,
			Failure["QOIFailure", <|
				"MessageTemplate" -> "Failed to encode the image `1`.",
				"MessageParameters" -> {img},
				"Reason" -> ba
			|>]
		]
	];

(*******************************************************************************
QOIDecode
*******************************************************************************)

SyntaxInformation[QOIDecode] = {
	"ArgumentsPattern" -> {ba_}
};

QOIDecode[args___] /; CheckArguments[QOIDecode[args], 1] := 
	Module[{ba},
		ba = ArgumentsOptions[QOIDecode[args], 1][[1, 1]];
		If[!ByteArrayQ[ba],
			Return @ Failure["QOIFailure", <|
				"MessageTemplate" -> "Invalid ByteArray `1`.",
				"MessageParameters" -> {ba},
				"Input" -> ba
			|>]
		];
		qoiDecode[ba]
	];

qoiDecode[ba_] := 
	Module[{init, img},
		init = initializeLibrary[];
		If[FailureQ[init], Return[init]];

		img = $libraryFunctions["qoi_decode"][ba];

		If[ImageQ[img],
			img
		,
			Failure["QOIFailure", <|
				"MessageTemplate" -> "Failed to decode the byte array `1`.",
				"MessageParameters" -> {ba},
				"Reason" -> img
			|>]
		]
	];

(*******************************************************************************
LibraryLink
*******************************************************************************)

If[!ValueQ[$libraryInitialized],
	$libraryInitialized = False
];

If[!ValueQ[$libraryFunctions],
	$libraryFunctions = <||>
];

initializeLibrary[] /; !TrueQ[$libraryInitialized] :=
	Module[{qoiLib},
		qoiLib = FindLibrary["wolfram_qoi"];
		If[!FileExistsQ[qoiLib],
			Return @ Failure["QOIFailure", <|
				"MessageTemplate" -> "Unable to find the `1` library.",
				"MessageParameters" -> {"wolfram_qoi." <> Internal`DynamicLibraryExtension[]}
			|>]
		];

		$libraryFunctions["qoi_encode"] = LibraryFunctionLoad[qoiLib, "wolfram_qoi_encode", {LibraryDataType[Image]}, LibraryDataType[ByteArray]];
		If[Head[$libraryFunctions["qoi_encode"]] =!= LibraryFunction,
			Return @ Failure["QOIFailure", <|
				"MessageTemplate" -> "Unable to load the `1` library function.",
				"MessageParameters" -> {"wolfram_qoi_encode"}
			|>]
		];

		$libraryFunctions["qoi_decode"] = LibraryFunctionLoad[qoiLib, "wolfram_qoi_decode", {LibraryDataType[ByteArray]}, LibraryDataType[Image]];
		If[Head[$libraryFunctions["qoi_decode"]] =!= LibraryFunction,
			Return @ Failure["QOIFailure", <|
				"MessageTemplate" -> "Unable to load the `1` library function.",
				"MessageParameters" -> {"wolfram_qoi_decode"}
			|>]
		];

		$libraryInitialized = True;
	];

(*******************************************************************************
Utilities
*******************************************************************************)

End[];

EndPackage[];
