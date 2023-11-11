package build

import "core:runtime"

Build_Command_Type :: enum {
	Invalid,
	Build,
	Install,
	Dev,
	Display_Help,
}

// Static lib?
Build_Mode :: enum {
	EXE,
	Shared,
	OBJ,
	ASM,
	LLVM_IR,
}


/*
	Can be used as-is or via a subtype
*/


Define_Val :: union #no_nil {
	bool,
	int,
	string,
	// Todo(Dragos): Add $IDENTIFIER
}

Define :: struct {
	name: string,
	val: Define_Val,
}


Platform_ABI :: enum {
	Default,
	SysV,
}

Platform :: struct {
	os: runtime.Odin_OS_Type,
	arch: runtime.Odin_Arch_Type,
}

Vet_Flag :: enum {
	Unused,
	Shadowing,
	Using_Stmt,
	Using_Param,
	Style,
	Semicolon,
}

Vet_Flags :: bit_set[Vet_Flag]

Subsystem_Kind :: enum {
	Console,
	Windows,
}

Style_Mode :: enum {
	None, 
	Strict,
	Strict_Init_Only,
}

Opt_Mode :: enum {
	None,
	Minimal,
	Speed,
	Size,
	Aggressive,
}

Reloc_Mode :: enum {
	Default,
	Static,
	PIC,
	Dynamic_No_PIC,
}

Compiler_Flag :: enum {
	Keep_Temp_Files,
	Debug,
	Disable_Assert,
	No_Bounds_Check,
	No_CRT,
	No_Thread_Local,
	LLD, // maybe do Linker :: enum { Default, LLD, }
	Use_Separate_Modules,
	No_Threaded_Checker, // This is more like an user thing?
	Ignore_Unknown_Attributes,
	Disable_Red_Zone,
	Dynamic_Map_Calls,
	Disallow_Do, // Is this a vet thing? Ask Bill.
	Default_To_Nil_Allocator,

	// Do something different with these?
	Ignore_Warnings,
	Warnings_As_Errors,
	Terse_Errors,
	//

	Foreign_Error_Procedures,
	Ignore_Vs_Search,
	No_Entry_Point,
	Show_System_Calls,

	No_RTTI,
}

Compiler_Flags :: bit_set[Compiler_Flag]

Error_Pos_Style :: enum {
	Default, // .Odin
	Odin, // file/path(45:3)
	Unix, // file/path:45:3
}

Sanitize_Flag :: enum {
	Address,
	Memory,
	Thread,
}

Sanitize_Flags :: bit_set[Sanitize_Flag]

Timings_Mode :: enum {
	Disabled,
	Basic,
	Advanced,
}

Timings_Format :: enum {
	Default,
	JSON,
	CSV,
}

//TODO
Timings_Export :: struct {
	mode: Timings_Mode,
	format: Timings_Format,
	filename: Maybe(string),
}