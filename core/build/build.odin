package build

import "core:strings"
import "core:os"
import "core:path/filepath"
import "core:sync"
import "core:encoding/json"
import "core:log"
import "core:runtime"
import "core:fmt"
import "core:slice"

import "core:c/libc" // TODO: remove dependency on libc after core:os2

@(private="file") _context: runtime.Context

@init
_ :: proc() {
	_context = create_default_context()
}

create_default_context :: proc() -> runtime.Context {
	context = runtime.default_context()
	context.allocator = context.temp_allocator
	context.logger = log.create_console_logger(.Debug, {.Level})
	return context
}

default_context :: #force_inline proc() -> runtime.Context {
	return _context
}

shell_exec :: proc(cmd: string, echo: bool) -> int {
	cstr := strings.clone_to_cstring(cmd, context.temp_allocator)
	if echo {
		log.infof("%s\n", cmd)
	}
	return cast(int)libc.system(cstr)
}

shell_command :: proc($cmd: string) -> Command {
	return proc(config: Config) {
		cstr := strings.clone_to_cstring(cmd, context.temp_allocator)
		result := cast(int)libc.system(cstr)
		return result
	}
}

add_post_build_command :: proc(config: ^Config, name: string, cmd: Command_Proc) {
	command := Command {
		name = name,
		command = cmd,
	}
	append(&config.post_build_commands, command)
}

add_pre_build_command :: proc(config: ^Config, name: string, cmd: Command_Proc) {
	command := Command {
		name = name,
		command = cmd,
	}
	append(&config.pre_build_commands, command)
}

build_package :: proc(config: Config) -> (ok: bool) {
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
			log.errorf("Pre-Build Command '%s' failed with exit code %d", cmd.name, result)
			return
		}
	}
	command := fmt.tprintf("odin build %s %s", config.src_path, args)
	exit_code := shell_exec(command, true)
	if exit_code != 0 {
		log.errorf("Build failed with exit code %v\n", exit_code)
		return
	} else {
		for cmd in config.post_build_commands {
			if result := cmd.command(config); result != 0 {
				log.errorf("Post-Build Command '%s' failed with exit code %d", cmd.name, result)
				return
			}
		}
	}
	
	return true
}

BUILTIN_FLAGS := []string {
	"-help",
	"-ols",
	"-vscode",
	"-build-pre-launch",
	"-include-build-system",
	"-cwd-workspace",
	"-cwd-out",
	"-cwd",
	"-launch-args",
	"-use-cppvsdbg",
	"-use-cppdbg",
}

settings_init_from_args :: proc(settings: ^Settings, args: []string, custom_flags := []string{}) -> (ok: bool) {
	command := args[0]
	args := args[1:]
	if len(args) == 0 {
		settings.command_type = .Build
		return true
	}
	
	display_help := false
	build_project := true
	is_install := false
	config_name := ""
	for i in 0..<len(args) {
		arg := args[i]
		 
		if arg[0] == '-' {
			if _, found := slice.linear_search(custom_flags, arg); found {
				if _, found := slice.linear_search(BUILTIN_FLAGS, arg); found {
					log.warnf("Flag %s is a builtin flag, but also specified as a custom flag. Builtin behavior will be skipped.")
				}
				append(&settings.custom_args, arg)
			} else do switch {
				case arg == "-help":
					display_help = true
					build_project = false
		
				case arg == "-ols":
					build_project = false
					settings.dev_opts.flags += {.Generate_Ols}
				case arg == "-build-pre-launch":
					build_project = false
					settings.dev_opts.flags += {.Build_Pre_Launch}
		
				case arg == "-vscode":
					build_project = false
					settings.dev_opts.editors += {.VSCode}
		
				case arg == "-use-cppvsdbg":
					build_project = false
					settings.dev_opts.vscode_debugger_type = .cppvsdbg
		
				case arg == "-use-cppdbg":
					build_project = false
					settings.dev_opts.vscode_debugger_type = .cppdbg
		
				case arg == "-cwd-workspace":
					build_project = false
					settings.dev_opts.flags += {.Cwd_Workspace}
		
				case arg == "-cwd-out":
					build_project = false
					settings.dev_opts.flags += {.Cwd_Out}
		
				case arg == "-install":
					is_install = true
		
				case strings.has_prefix(arg, "-cwd"):
					build_project = false
					log.warnf("Flag %s not implemented", arg)
		
				case strings.has_prefix(arg, "-launch-args"):
					build_project = false
					log.warnf("Flag %s not implemented", arg)
		
				case strings.has_prefix(arg, "-include-build-system"):
					build_project = false
					settings.dev_opts.flags += {.Include_Build_System}
					log.warnf("Flag %s not implemented\n", arg)
		
				case: log.errorf("Invalid flag %s", arg)
			}
		} else {
			if config_name != "" {
				log.errorf("Config already set to %s and cannot be re-assigned to %s. Cannot have 2 configurations built with the same command (yet).", config_name, arg)
				return
			}
			config_name = arg
			settings.config_name = config_name
		}
	}

	// Note(Dragos): I do not like this approach
	if display_help {
		settings.command_type = .Display_Help
	} else if build_project {
		settings.command_type = .Install if is_install else .Build
	} else {
		settings.command_type = .Dev
	}
	return true
}

add_target :: proc(project: ^Project, target: ^Target, loc := #caller_location) {
	append(&project.targets, target)
	target.project = project
	file_dir := filepath.dir(loc.file_path, context.temp_allocator)
	root_dir := filepath.join({file_dir, ".."}, context.temp_allocator)
	target.root_dir = filepath.clean(root_dir) // This effectively makes the build system dependent on being a subfolder of the main project root
}

Add_Dependency_Error :: enum {
	None,
	Circular_Dependency,
}

find_dependency :: proc(target: ^Target, depend: ^Target) -> bool {
	// Note(Dragos): is this logic correct?
	if target == depend {
		return true
	}
	for d in target.depends {
		return find_dependency(d, depend)
	}
	return false
}

// Note(Dragos): Ideally this should be proc(^Config, ^Target). This needs a rework of the API a tiny bit
add_dependency :: proc(target: ^Target, depends_on: ^Target) -> (err: Add_Dependency_Error) {
	if find_dependency(target, depends_on) {
		return // dependency already present
	}

	if find_dependency(depends_on, target) {
		log.errorf("Circular dependency detected for [%s - %s] and [%s - %s]", target.project.name, target.name, depends_on.project.name, depends_on.name)
		return .Circular_Dependency
	}
	
	append(&target.depends, depends_on)

	return
}

run :: proc(main_project: ^Project, opts: Settings) {
	opts := opts
	if opts.config_name == "" do opts.config_name = opts.default_config_name

	switch opts.command_type {
	case .Build, .Install, .Dev:
		found_config := false

		
		for target in main_project.targets { // Code duplicate here... Fix this somehow
			config := main_project->configure_target_proc(target, opts)
			prefixed_name := strings.concatenate({main_project.config_prefix, config.name}, context.temp_allocator)
			if _match(opts.config_name, prefixed_name) {
				found_config = true
				if opts.command_type == .Dev {
					_generate_devenv(config, opts.dev_opts)
				} else {
					build_package(config)
				}
			}
		} // Code duplicate here... Fix this somehow
		for project in opts.external_projects do for target in project.targets {	
			config := project->configure_target_proc(target, opts)
			prefixed_name := strings.concatenate({project.config_prefix, config.name}, context.temp_allocator)
			if _match(opts.config_name, prefixed_name) {
				found_config = true
				if opts.command_type == .Dev {
					_generate_devenv(config, opts.dev_opts)
				} else {
					build_package(config)
				}
			}
		} // Code duplicate here... Fix this somehow

		if !found_config {
			log.errorf("Could not find configuration %s", opts.config_name)
			return
		}
	
	case .Display_Help:
		_display_command_help(main_project, opts)
	
	case .Invalid: fallthrough
	case: log.errorf("Invalid command type")
	}
}