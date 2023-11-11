package build

import "core:strings"
import "core:path/filepath"
import "core:os"
import "core:fmt"
import "core:slice"
import "core:runtime"


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
		case bool:   fmt.sbprintf(&sb, " -define:%s=%s", define.name, val)
		case int:    fmt.sbprintf(&sb, " -define:%s=%s", define.name, val)
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
	if target != nil {
		config.src_path = filepath.join({target.root_dir, config.src_path}, context.temp_allocator) // Note(Dragos): different places might require this type of pathing. Maybe add a build.path(target, str, allocator) proc
		//config.src_path, _ = filepath.rel(target.root_dir, config.src_path, context.temp_allocator) // Note(Dragos): build.path could be relative
		config.out_dir = filepath.join({target.root_dir, config.out_dir}, context.temp_allocator)
		if config.rc_path != "" do config.rc_path = filepath.join({target.root_dir, config.rc_path}, context.temp_allocator) // Note(Dragos): Yes, this is ridiculous. please make build.path and let the user handle it correctly. silly dragos
	}
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
		for arg in args[1:] { // args[0] is cmd
			fmt.printf("\t%s\n", arg)
		}
	}

	ret := exec("odin", args)
	
	return ret == 0
}