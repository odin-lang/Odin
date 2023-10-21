package build

import "core:runtime"

Build_Command_Type :: enum {
	Invalid,
	Build,
	Install,
	Dev,
	Display_Help,
}

Settings :: struct {
	// Configurable via settings_init_from_args
	command_type: Build_Command_Type,
	target_name: string,
	dev_opts: Dev_Options,
	custom_args: [dynamic]string,

	// Configurable in user code. 
	external_projects: [dynamic]^Project,
	// Note(Dragos): This can be made a ^Target
	default_target_name: string,    // Called when no config is specified in the args / config_name
}

settings_display_additional_projects :: proc(settings: ^Settings, projects: []^Project) {
	append(&settings.external_projects, ..projects)
}


// Static lib?
Build_Mode :: enum {
	EXE,
	Shared,
	OBJ,
	ASM,
	LLVM_IR,
}

// Note(Dragos): Since Target is standardized now, we can allow the user to call the target name directly. 
Config :: struct {
	platform: Platform,

	src_path: string,
	out_dir: string,
	out_file: string,
	pdb_name: string,
	rc_path: string,

	thread_count: int,
	
	build_mode: Build_Mode,
	flags: Compiler_Flags,
	opt: Opt_Mode,
	vet: Vet_Flags,
	style: Style_Mode,
	reloc: Reloc_Mode,
	sanitize: Sanitize_Flags,

	timings: Timings_Export,

	pre_build_commands: [dynamic]Command,
	post_build_commands: [dynamic]Command,
	defines: map[string]Define_Val,
	collections: map[string]string,
}


/*
	Can be used as-is or via a subtype
*/
Target :: struct {
	name: string,
	platform: Platform,

	project: ^Project,
	root_dir: string,
	depends: [dynamic]^Target,
	cached_config: Maybe(Config),
}

// Note(Dragos): If we gots dependencies, then the project should have a #location of sorts, and be appended to paths like the src folder, out dir etc.
//				That would mean that ALL build systems would EXPECT a certain structure (for example having the build script package as a subfolder of the main project)
Project :: struct {
	name: string,
	targets: [dynamic]^Target,
	target_prefix: string,
	configure_target_proc: Configure_Target_Proc,
}


Define_Val :: union #no_nil {
	bool,
	int,
	string,
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
	Default,
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
	Pic,
	Dynamic_No_Pic,
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

Command_Proc :: #type proc(config: Config) -> int

Command :: struct {
	name: string,
	command: Command_Proc,
}

Configure_Target_Proc :: #type proc(project: ^Project, target: ^Target, settings: Settings) -> Config