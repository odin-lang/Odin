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

Mode :: enum {
    Build,
    Install,
    Uninstall,
    Help,
    Dev,
}

Flag_Arg :: struct { // -flag:key=val
    flag: string,
    key: Arg_Val,
    val: Arg_Val,
}

Arg_Val :: union {
    string,
    int,
    f64,
    bool,
}

Arg :: union {
    Flag_Arg,
    string,
    int,
    f64,
    bool,
}

Args_Error :: enum {
    None,
    Invalid_Format,
}

string_to_arg_val :: proc(str: string) -> (Arg_Val, Args_Error) {
    if str == "true" do return true, .None
    if str == "false" do return false, .None
    is_negative := str[0] == '-'
    if strings.has_prefix(str, "0o") { // octal
        n_str := utf8.rune_string_at_pos(str, 2 + cast(int)is_negative)
        num: int
        return str, .None // unimplemented
    }
    if strings.has_prefix(str, "0x") { // hexadecimal
        n_str := utf8.rune_string_at_pos(str, 2 + cast(int)is_negative)
        num: int
        return str, .None // unimplemented
    }
    if strings.has_prefix(str, "0b") { // binary
        n_str := utf8.rune_string_at_pos(str, 2 + cast(int)is_negative)
        num: int
        return nil, .None // unimplemented
    }
    if !is_negative && unicode.is_digit(utf8.rune_at_pos(str, 0)) || is_negative && unicode.is_digit(utf8.rune_at_pos(str, 1)) { // base 10
        n_str := utf8.rune_string_at_pos(str, 0 + cast(int)is_negative)
        exp: int
        exp_div := 1
        found_dot := false
        for ch in n_str {
            if ch == '.' {
                if found_dot do return nil, .Invalid_Format // too many mantissas
                found_dot = true
            } else {
                if !unicode.is_digit(ch) do return nil, .Invalid_Format // treat it as a string instead of erroring
                // Note(Dragos): Either implement it to work directly on bits, or check for a parsing function in the core lib. This isn't very good and might overflow.
                if found_dot { 
                    exp_div *= 10
                } 
                exp = exp * 10 + int(ch - '0')
            }
        }
        sign := -1 if is_negative else 1
        if found_dot {
            return f64(sign) * f64(exp) / f64(exp_div), .None // get all the digits in 1 number and then divide by 10^(num_digits_on_the_right)
        }
        return sign * exp, .None
    }

    return str, .None
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
                    flag_arg.key = string_to_arg_val(equal_slice[0]) or_return
                case 2: /// key and value
                    flag_arg.key = string_to_arg_val(equal_slice[0]) or_return
                    flag_arg.val = string_to_arg_val(equal_slice[1]) or_return
                }
            
            case: // more than 1 colon found. Invalid syntax
                err = .Invalid_Format
                return
            }
            args[i] = flag_arg
        } else {
            val := string_to_arg_val(os_arg) or_return
            // Note(Dragos): This is an ugly workaround. It's weird.
            switch v in val {
            case string: args[i] = v
            case int:    args[i] = v
            case f64:    args[i] = v
            case bool:   args[i] = v
            }
        }
    }
    return
}

_display_command_help :: proc(main_project: ^Project, opts: Settings) {
	fmt.printf("%s build system\n", main_project.name)
	fmt.printf("\tSyntax: %s <flags> <configuration name>\n", os.args[0])
	fmt.printf("\tAvailable Configurations:\n")
	for target in main_project.targets {
		//config := main_project->configure_target_proc(target, opts)
		//prefixed_name := strings.concatenate({main_project.target_prefix, target.name}, context.temp_allocator)
		//fmt.printf("\t\t%s\n", prefixed_name)
	}
	for project in opts.external_projects do for target in project.targets {
		//config := project->configure_target_proc(target, opts)
		//prefixed_name := strings.concatenate({main_project.target_prefix, target.name}, context.temp_allocator)
		//fmt.printf("\t\t%s\n", prefixed_name)
	}
	fmt.println()
	fmt.printf("\tFlags \n")
	
	fmt.printf("\t\t-help <optional target name>\n")
	fmt.printf("\t\t\tDisplays build system help. Cannot be used with other flags. \n\t\t\t[WIP] Specifying a target name will give you information about the target. \n")
	fmt.println()

	fmt.printf("\t\t-ols\n")
	fmt.printf("\t\t\tGenerates an ols.json for the configuration. \n")
	fmt.println()

	fmt.printf("\t\t-vscode\n")
	fmt.printf("\t\t\t[WIP] Generates .vscode/launch.json configuration for debugging. Must be used for other VSCode flags to function. \n")
	fmt.println()

	fmt.printf("\t\t-build-pre-launch\n")
	fmt.printf("\t\t\t[WIP] VSCode: Generates a pre launch command to build the project before debugging. \n\t\t\tEffectively runs `%s <config name>` before launching the debugger.\n", os.args[0])
	fmt.println()
	
	fmt.printf("\t\t-include-build-system:\"<args>\"\n")
	fmt.printf("\t\t\t[WIP] VSCode: Includes the build system as a debugging target.\n")
	fmt.println()

	fmt.printf("\t\t-cwd-workspace\n")
	fmt.printf("\t\t\t[WIP] VSCode: Use the workspace directory as the CWD when debugging.\n")
	fmt.println()

	fmt.printf("\t\t-cwd-out\n")
	fmt.printf("\t\t\t[WIP] VSCode: Use the output directory as the CWD when debugging. \n")
	fmt.println()

	fmt.printf("\t\t-cwd:\"<directory>\"\n")
	fmt.printf("\t\t\t[WIP] VSCode: Use the specified directory as the CWD when debugging. \n")
	fmt.println()


	fmt.printf("\t\t-launch-args:\"<args>\"\n")
	fmt.printf("\t\t\t[WIP] VScode: Specify the args sent to the executable when debugging.\n")
	fmt.println()

	fmt.printf("\t\t-use-cppvsdbg\n")
	fmt.printf("\t\t\t[WIP] VSCode: Use the VSCode debugger. Used by default with -vscode. \n")
	fmt.println()

	fmt.printf("\t\t-use-cppdbg\n")
	fmt.printf("\t\t\t[WIP] VSCode: Use the GDB/LLDB debugger. \n")
	fmt.println()
}

Flag_Desc :: struct {
    mode: Mode,
    flag: string,
    info: string,
}

Cli_Info :: struct {
    project: ^Project,
    additional_flags: []Flag_Desc,
    additional_projects: []^Project,
    additional_targets: []^Target,
}

Cli_Flags_Error :: enum {
    Incompatible_Flags,
}


print_help :: proc(info: Cli_Info) {

}

cli_validate_new_mode :: proc(last_mode: Mode, last_mode_flag: string, new_mode: Mode, new_mode_flag: string) -> (Mode, string, bool){ 
    if last_mode == new_mode {
        return new_mode, new_mode_flag, true
    }
    if last_mode == .Build { // .Build is the default
        return new_mode, new_mode_flag, true
    } 
    fmt.eprintf("Flag %s for mode %v overrides mode %v set by flag %s. Flags are incompatible\n.", new_mode_flag, new_mode, last_mode, last_mode_flag)
    return nil, "", false
}

run_cli :: proc(info: Cli_Info, args: []string) -> bool {
    args, err := parse_args(args, context.temp_allocator)
    mode: Mode = .Build
    mode_flag: string
    for arg in args {
        #partial switch v in arg {
        case string: 
        case Flag_Arg:
            switch v.flag {
            case "-help": mode, mode_flag = cli_validate_new_mode(mode, mode_flag, .Help, "-help") or_return
            
            }
        }
    }
    return true
}