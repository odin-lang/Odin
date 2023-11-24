package build

import "core:strings"
import "core:os"
import "core:path/filepath"
import "core:sync"
import "core:encoding/json"
import "core:runtime"
import "core:fmt"
import "core:slice"
import "core:unicode/utf8"
import "core:unicode"
import "core:strconv"
import "core:intrinsics"


Flag_Arg :: struct { // -flag:key=val
	flag: string,
	key: string,
	val: string,
}

Arg :: union {
	Flag_Arg,
	string,
}

Args_Error :: enum {
	None,
	Invalid_Format,
}

// Todo(Dragos): add option to handle ints, floats, bools as strings
parse_args :: proc(os_args: []string, allocator := context.allocator) -> (args: []Arg, err: Args_Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)
	context.allocator = allocator
	args = make([]Arg, len(os_args) - 1)
	for os_arg, i in os_args[1:] {
		if os_arg[0] == '-' {
			flag_arg: Flag_Arg
			colon_slice := strings.split(os_arg, ":", context.temp_allocator)
			switch len(colon_slice) {
			case 1: // only the flag found, no key-val
				flag_arg.flag = colon_slice[0]
				
			case 2: // key and/or value found
				flag_arg.flag = colon_slice[0]
				equal_slice := strings.split(colon_slice[1], "=", context.temp_allocator)
				switch len(equal_slice) {
				case 1: // only key, no value
					flag_arg.key = equal_slice[0]
				case 2: /// key and value
					flag_arg.key = equal_slice[0]
					flag_arg.val = equal_slice[1]
				}
			
			case: // more than 1 colon found. Invalid syntax
				err = .Invalid_Format
				return
			}
			args[i] = flag_arg
		} else {
			args[i] = os_arg
		}
	}
	return
}


Flag_Desc :: struct {
	mode: Run_Mode,
	flag: Flag_Arg,
	help: string,
}

Cli_Info :: struct {
	project: ^Project, // this can be projects: []^Project
	default_target: ^Target,
}

Cli_Flags_Error :: enum {
	Incompatible_Flags,
}

builtin_flags := [?]Flag_Desc {
	{.Help, {"-help", "", ""}, "Displays information about the build system or the target specified."},
	{.Dev, {"-ols", "", ""}, "Generates an ols.json for the configuration."},
	{.Dev, {"-vscode", "", ""}, "Generates .vscode folder for debugging."},
	{.Dev, {"-build-pre-launch", "", ""}, "Runs the build system before debugging. (WIP)"},
	{.Dev, {"-include-build-system", "<args>", ""}, "Include the build system as a debugging target. (WIP)"},
	{.Dev, {"-cwd", "<dir>", ""}, "Sets the CWD to the specified directory."},
	{.Dev, {"-cwd-workspace", "", ""}, "Sets the CWD to the root of the build system executable."},
	{.Dev, {"-cwd-out", "", ""}, "Sets the CWD to the output directory specified in the -out odin flag"},
	{.Dev, {"-launch-args", "<args>", ""}, "The arguments to be sent to the output executable when debugging."},
	{.Dev, {"-dbg", "<debugger name>", ""}, "Debugger type used. Works with -vscode. Sets the ./vscode/launch.json \"type\" argument"},
}

print_general_help :: proc(info: Cli_Info) {
	fmt.printf("Syntax: %s <flags> <target>\n", filepath.base(os.args[0]))
	fmt.printf("Available Targets:\n")
	for target in info.project.targets {
		prefixed_name := strings.concatenate({info.project.target_prefix, target.name}, context.temp_allocator)
		fmt.printf("\t%s\n", prefixed_name)
	}
	fmt.println()
	fmt.printf("Builtin Flags - Only 1 [Type] group per call. Groups are incompatible\n")
	
	for flag_desc in builtin_flags {
		fmt.printf("\t%s", flag_desc.flag.flag)
		if flag_desc.flag.key != "" {
			fmt.printf(":\"%s\"", flag_desc.flag.key)
		}
		if flag_desc.flag.val != "" {
			fmt.printf("=\"%s\"", flag_desc.flag.key)
		}
		fmt.println()
		fmt.printf("\t\t%s %s\n", mode_strings[flag_desc.mode], flag_desc.help)
		fmt.println()
	}
}

run_cli :: proc(info: Cli_Info, cli_args: []string) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	args, err := parse_args(cli_args, context.temp_allocator) // cli_args[0] should be the executable
	target_names_from_args := make_dynamic_array_len_cap([dynamic]string, 0, len(info.project.targets), context.temp_allocator) // This is not fully correct right now
	filtered_args_by_mode := make([dynamic]Arg, context.temp_allocator)
	current_mode: Maybe(Run_Mode)
	last_flag: Flag_Arg
	for arg in args {
		switch v in arg {
		case string: 
			append(&target_names_from_args, v)
		case Flag_Arg:
			flag_found := false
			for flag_desc in builtin_flags do if flag_desc.flag == v {
				flag_found = true
				if current_mode == nil {
					current_mode = flag_desc.mode
				}
				if current_mode != flag_desc.mode {
					fmt.eprintf("Mode %s set by %s is incompatible with previous mode %s set by previous flag %s. Run `%s -help`` for more details.\n", mode_strings[flag_desc.mode], flag_desc.flag, current_mode.?, last_flag, cli_args[0])
					return false
				}
				last_flag = v
				append(&filtered_args_by_mode, v)
				break
			}
			if !flag_found {
				fmt.eprintf("Flag %s does not exist. Run `%s -help` for a list of available flags.\n", v, cli_args[0])
				return false
			}
		}
	}

	if current_mode == nil do current_mode = .Build
	

	if len(target_names_from_args) > 0 do for name in target_names_from_args {
		for target in info.project.targets {
			prefixed_name := strings.concatenate({info.project.target_prefix, target.name})
			if _match(name, prefixed_name) {
				ok := run_target(target, current_mode.?, args)
				if !ok {
					fmt.eprintf("Error running %s mode for target %s\n", current_mode.?, target.name)
					return false
				}
			}
		}
	} else { // if no target is specified, use the default target
		if current_mode.? == .Help {
			print_general_help(info) // No target + -help is a special case. It doesn't print the help of the default target, only the general help.
		} else {
			ok := run_target(info.default_target, current_mode.?, args)
			if !ok {
				fmt.eprintf("Error running %s mode for target %s\n", current_mode.?, info.default_target.name)
				return false
			} 
		}
	}

	return true
}