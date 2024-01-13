package build

import "core:strings"
import "core:os"
import "core:fmt"
import "core:slice"
import "core:runtime"

Build_Mode :: enum {
	EXE,
	Shared,
	OBJ,
	ASM,
	LLVM_IR,
}


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

Odin_Command_Type :: enum {
	Build,
	Check,
}

Odin_Config :: struct {
	platform: Platform,
	abi: Platform_ABI, // Only makes sense for freestanding
	src_path: string,
	out_dir: string,
	out_file: string,
	pdb_name: string,
	rc_path: string,
	subsystem: Subsystem_Kind,
	thread_count: int,
	build_mode: Build_Mode,
	flags: Compiler_Flags,
	opt: Opt_Mode,
	vet: Vet_Flags,
	style: Style_Mode,
	reloc: Reloc_Mode,
	sanitize: Sanitize_Flags,
	timings: Timings_Export,
	defines: []Define,
	collections: []Collection,
}

split_odin_args :: proc(args: string, allocator := context.allocator) -> []string {
	return strings.split(args, " ", allocator)
}

build_odin_args :: proc(config: Odin_Config, allocator := context.allocator) -> (args: string) {
	insert_space :: proc(sb: ^strings.Builder) {
		strings.write_rune(sb, ' ')
	}

	context.allocator = allocator
	sb := strings.builder_make()

	fmt.sbprintf(&sb, `-out:"%s/%s"`, config.out_dir, config.out_file)

	if config.platform.os == .Windows {
		if config.pdb_name != "" do fmt.sbprintf(&sb, ` -pdb-name:"%s"`, config.pdb_name)
		if config.rc_path != ""  do fmt.sbprintf(&sb, ` -resource:"%s"`, config.rc_path)
		switch config.subsystem {
		case .Console: strings.write_string(&sb, " -subsystem:console")
		case .Windows: strings.write_string(&sb, " -subsystem:windows")
		}
	}
	
	insert_space(&sb)
	strings.write_string(&sb, _build_mode_to_arg[config.build_mode])

	insert_space(&sb)
	strings.write_string(&sb, _opt_mode_to_arg[config.opt])

	insert_space(&sb)
	strings.write_string(&sb, _reloc_mode_to_arg[config.reloc])

	for flag in Vet_Flag do if flag in config.vet {
		insert_space(&sb)
		strings.write_string(&sb, _vet_flag_to_arg[flag])
	}
	for flag in Compiler_Flag do if flag in config.flags {
		insert_space(&sb)
		strings.write_string(&sb, _compiler_flag_to_arg[flag])
	}
	for flag in Sanitize_Flag do if flag in config.sanitize {
		insert_space(&sb)
		strings.write_string(&sb, _sanitize_to_arg[flag])
	}
	if config.style != .None {
		insert_space(&sb)
		strings.write_string(&sb, _style_mode_to_arg[config.style])
	}
	for collection in config.collections {
		fmt.sbprintf(&sb, " -collection:%s=\"%s\"", collection.name, collection.path)
	}
	for define in config.defines {
		switch val in define.val {
		case string: fmt.sbprintf(&sb, " -define:%s=\"%s\"", define.name, val)
		case bool:   fmt.sbprintf(&sb, " -define:%s=%s", define.name, "true" if val else "false")
		case int:    fmt.sbprintf(&sb, " -define:%s=%d", define.name, val)
		}
	}
	
	if config.abi == .Default {
		fmt.sbprintf(&sb, " -target:%s_%s", _os_to_arg[config.platform.os], _arch_to_arg[config.platform.arch])
	} else {
		fmt.sbprintf(&sb, " -target:%s_%s_%s", _os_to_arg[config.platform.os], _arch_to_arg[config.platform.arch], _abi_to_arg[config.abi])
	}

	if config.thread_count > 0 {
		fmt.sbprintf(&sb, " -thread-count:%d", config.thread_count)
	}

	return strings.to_string(sb)
}


// Runs the odin compiler. If target is not nil, use target.root_dir for configuring paths
odin :: proc(target: ^Target, command_type: Odin_Command_Type, config: Odin_Config, print_command := true, loc := #caller_location) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	config := config
	cmd: string
	switch command_type {
	case .Check: cmd = "check"
	case .Build: cmd = "build"
	case: panic("Invalid command_type")
	}
	make_directory(config.out_dir)
	args_str := build_odin_args(config, context.temp_allocator)
	args_str = strings.join({cmd, config.src_path, args_str}, " ", context.temp_allocator)
	args := split_odin_args(args_str, context.temp_allocator)
	if print_command {
		fmt.printf("odin %s \"%s\"\n", cmd, config.src_path)
		for arg in args[2:] { // args[0] is cmd, arg[1] is package
			fmt.printf("\t%s\n", arg)
		}
	}

	ret := exec("odin", args)
	
	return ret == 0
}