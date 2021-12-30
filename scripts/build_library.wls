#!/usr/bin/env wolframscript
(* ::Package:: *)

Needs["CCompilerDriver`"];

pacletDir = DirectoryName[$InputFileName, 2];
srcDir = FileNameJoin[{pacletDir, "src"}];
libDir = FileNameJoin[{pacletDir, "LibraryResources", $SystemID}];
qoiDir = FileNameJoin[{pacletDir, "qoi"}];

If[!DirectoryQ[qoiDir],
	Print["The qoi repository is required to build the library. Run ./scripts/get_qoi.sh to clone it."];
	Exit[1]
];

srcFiles = FileNames["*.c", srcDir];

warningsFlags = {"-Wall", "-Wextra", "-Werror", "-pedantic", "-Wno-unused"};

Print["Building the library in ", libDir];
libPath = CCompilerDriver`CreateLibrary[
	srcFiles,
	"wolfram_qoi",
	"ShellCommandFunction" -> Echo,
	"ShellOutputFunction" -> Echo,
	"TargetDirectory" -> libDir,
	"CleanIntermediate" -> True,
	"Language" -> "C",
	"CompileOptions" -> warningsFlags,
	"IncludeDirectories" -> {qoiDir}
];
If[!FileExistsQ[libPath],
	Print["Failed to build the library."];
	Exit[1]
];

Print["The library was built successfully: ", libPath];
Exit[0]
