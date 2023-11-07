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
	defines: map[string]Define_Val,
	collections: map[string]string,
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
	for key, val in config.collections {
		fmt.sbprintf(&sb, " -collection:%s=\"%s\"", key, val)
	}
	for key, val in config.defines {
		switch v in val {
		case string: fmt.sbprintf(&sb, " -define:%s=\"%s\"", key, v)
		case bool:   fmt.sbprintf(&sb, " -define:%s=%s", key, v)
		case int:    fmt.sbprintf(&sb, " -define:%s=%s", key, v)
		}
	}
	
	if config.platform.abi == .Default {
		fmt.sbprintf(&sb, " -platform:%s_%s", _os_to_arg[config.platform.os], _arch_to_arg[config.platform.arch])
	} else {
		fmt.sbprintf(&sb, " -platform:%s_%s_%s", _os_to_arg[config.platform.os], _arch_to_arg[config.platform.arch], _abi_to_arg[config.platform.abi])
	}

	if config.thread_count > 0 {
		fmt.sbprintf(&sb, " -thread-count:%d", config.thread_count)
	}

	return strings.to_string(sb)
}

/*
_build_package :: proc(config: Config) -> (ok: bool) {
	config_output_dirs: {
		//dir := filepath.dir(config.out_path, context.temp_allocator) 
		// Note(Dragos): I wrote this a while ago. Is there a better way?
		slash_dir, _ := filepath.to_slash(config.out_dir, context.temp_allocator)
		dirs := strings.split_after(slash_dir, "/", context.temp_allocator)
		for _, i in dirs {
			new_dir := strings.concatenate(dirs[0 : i + 1], context.temp_allocator)
			os.make_directory(new_dir)
		}
	}
	
	argsBuilder := strings.builder_make() 
	_config_to_args(&argsBuilder, config)
	args := strings.to_string(argsBuilder)
	for cmd in config.pre_build_commands {
		if result := cmd.command(config); result != 0 {
			printf_error("Pre-Build Command '%s' failed with exit code %d", cmd.name, result)
			return
		}
	}
	command := fmt.tprintf("odin build \"%s\" %s", config.src_path, args)
	exit_code := shell_exec(command, true)
	if exit_code != 0 {
		printf_error("Build failed with exit code %v\n", exit_code)
		return
	} else {
		for cmd in config.post_build_commands {
			if result := cmd.command(config); result != 0 {
				printf_error("Post-Build Command '%s' failed with exit code %d", cmd.name, result)
				return
			}
		}
	}
	
	return true
}
*/

odin :: proc(command_type: Odin_Command_Type, config: Odin_Config, print_command := true, loc := #caller_location) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cmd: string
	switch command_type {
	case .Check: cmd = "check"
	case .Build: cmd = "build"
	case: panic("Invalid command_type")
	}
	make_directory(config.out_dir)
	args_str := build_odin_args(config, context.temp_allocator)
	args_str = strings.join({cmd, args_str}, " ", context.temp_allocator)
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