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
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
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
	mode: Mode,
	flag: Flag_Arg,
	help: string,
}


Cli_Info :: struct {
	project: ^Project, // this can be projects: []^Project
	additional_flags: []Flag_Desc, // This could be target flags per target
	additional_projects: []^Project,
	additional_targets: []^Target,
}

Cli_Flags_Error :: enum {
	Incompatible_Flags,
}

builtin_flags := [?]Flag_Desc {
	{.Help, {"-help", "", ""}, "Displays information about the build system or the target specified."},
	{.Dev, {"-ols", "", ""}, "Generates an ols.json for the configuration."},
	{.Dev, {"-vscode", "", ""}, "Generates .vscode folder for debugging."},
	{.Dev, {"-build-pre-launch", "", ""}, "Runs the build system before debugging."},
	{.Dev, {"-include-build-system", "<args>", ""}, "Include the build system as a debugging target."},
	{.Dev, {"-cwd", "<dir>", ""}, "Sets the CWD."},
	{.Dev, {"-cwd-workspace", "", ""}, "Sets the CWD to the root of the build system executable."},
	{.Dev, {"-cwd-out", "", ""}, "Sets the CWD to the output directory specified in the -out odin flag"},
	{.Dev, {"-launch-args", "<args>", ""}, "Generates an ols.json for the configuration."},
	{.Dev, {"-dbg", "<debugger name>", ""}, "Generates an ols.json for the configuration."},
}

print_general_help :: proc(info: Cli_Info) {
	fmt.printf("%s build system\n", info.project.name)
	fmt.printf("\tSyntax: %s <flags> <target>\n", os.args[0])
	fmt.printf("\tAvailable Targets:\n")
	for target in info.project.targets {
		prefixed_name := strings.concatenate({info.project.target_prefix, target.name}, context.temp_allocator)
		fmt.printf("\t\t%s\n", prefixed_name)
	}
	fmt.println()
	fmt.printf("\tBuiltin Flags - Only 1 [Type] group per call. Groups are incompatible\n")
	
	for flag_desc in builtin_flags {
		fmt.printf("\t\t%s %s", mode_strings[flag_desc.mode], flag_desc.flag)
		if flag_desc.flag.key != "" {
			fmt.printf(":\"%s\"", flag_desc.flag.key)
		}
		if flag_desc.flag.val != "" {
			fmt.printf("=\"%s\"", flag_desc.flag.key)
		}
		fmt.println()
		fmt.printf("\t\t\t%s\n", flag_desc.help)
		fmt.println()
	}
}

run_cli :: proc(info: Cli_Info, args: []string) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	args, err := parse_args(args, context.temp_allocator)
	mode: Maybe(Mode)
	mode_flag: string
	for arg in args {
		#partial switch v in arg {
		case string: 
		case Flag_Arg:
			switch v.flag {
			case "-help":
			case "-install":
			case "-uninstall":
			case "-ols":
			case "-vscode":
			case "-debugger":
			}
		}
	}
	return true
}