package build

import "core:strings"
import "core:os"
import "core:path/filepath"
import "core:sync"
import "core:encoding/json"
import "core:runtime"
import "core:fmt"
import "core:slice"
import "core:log"

import "core:c/libc" // TODO: remove dependency on libc after core:os2


/*
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
					printf_warning("Flag %s is a builtin flag, but also specified as a custom flag. Builtin behavior will be skipped.")
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
					printf_warning("Flag %s not implemented", arg)
		
				case strings.has_prefix(arg, "-launch-args"):
					build_project = false
					printf_warning("Flag %s not implemented", arg)
		
				case strings.has_prefix(arg, "-include-build-system"):
					build_project = false
					settings.dev_opts.flags += {.Include_Build_System}
					printf_warning("Flag %s not implemented\n", arg)
		
				case: printf_error("Invalid flag %s", arg)
			}
		} else {
			if config_name != "" {
				printf_error("Config already set to %s and cannot be re-assigned to %s. Cannot have 2 configurations built with the same command (yet).", config_name, arg)
				return
			}
			config_name = arg // Todo(Dragos): Remove this variable
			settings.target_name = config_name
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
*/