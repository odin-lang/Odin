package build

import "core:unicode/utf8"
import "core:runtime"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:encoding/json"
import "core:path/filepath"
import "core:slice"



S_IRUSR :: 0x0400
S_IWUSR :: 0x0200



Collection :: struct {
	name, path: string,
}

Language_Server_Option :: enum {
	Document_Symbols,
	Semantic_Tokens,
	Hover,
	Snippets,
}

Language_Server_Options :: bit_set[Language_Server_Option]

DEFAULT_OLS_OPTIONS :: Language_Server_Options{
	.Document_Symbols,
	.Semantic_Tokens,
	.Hover,
	.Snippets,
}

Language_Server_Settings :: struct {
	enable_document_symbols: bool,
	enable_semantic_tokens: bool,
	enable_hover: bool,
}

Ols_Json :: struct {
	collections: [dynamic]Collection,
	enable_document_symbols: bool,
	enable_semantic_tokens: bool,
	enable_hover: bool, 
	enable_snippets: bool,
	checker_args: string,
}


Editor :: enum {
	VSCode,
}

Editors :: bit_set[Editor]


Odin_Dev_Flag :: enum {
	Generate_Ols,
	Build_Pre_Launch,
	Cwd_Workspace,
	Cwd_Out,
	Include_Build_System,
}

Odin_Dev_Flags :: bit_set[Odin_Dev_Flag]

Default_Dev_Opts :: struct {
	flags: Odin_Dev_Flags,
	editors: Editors,
	launch_args: string,
	custom_cwd: string,
	debugger_type: string,
	build_system_args: string,
}

parse_default_devenv_args :: proc(args: []Arg) -> (opts: Default_Dev_Opts) {
	for arg in args do if arg, is_arg := arg.(Flag_Arg); is_arg {
		switch arg.flag {
		case "-ols":
			opts.flags += {.Generate_Ols}
		case "-vscode":
			opts.editors += {.VSCode}
		case "-build-pre-launch":
			opts.flags += {.Build_Pre_Launch}
		case "-include-build-system":
			opts.flags += {.Include_Build_System}
		case "-cwd-out":
			opts.flags += {.Cwd_Out}
		case "-cwd-workspace":
			opts.flags += {.Cwd_Workspace}
		case "-cwd":
			opts.custom_cwd = arg.key
		case "-launch-args":
			opts.launch_args = arg.key
		case "-dbg":
			opts.debugger_type = arg.key
		}
	}
	return opts
}

build_ols_json :: proc(config: Odin_Config, opts: Language_Server_Options, allocator := context.allocator) -> ([]u8, json.Marshal_Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator) // Note(Dragos): Fix issues with this
	ols_json: Ols_Json
	ols_json.collections = make([dynamic]Collection, context.temp_allocator)
	append(&ols_json.collections, ..config.collections)
	append(&ols_json.collections, Collection{"core", fmt.tprintf("%score", ODIN_ROOT)})
	append(&ols_json.collections, Collection{"vendor", fmt.tprintf("%svendor", ODIN_ROOT)})
	ols_json.checker_args = build_odin_args(config, context.temp_allocator)
	ols_json.enable_document_symbols = .Document_Symbols in opts
	ols_json.enable_semantic_tokens = .Semantic_Tokens in opts
	ols_json.enable_hover = .Hover in opts
	ols_json.enable_snippets = .Snippets in opts
	marshal_opts: json.Marshal_Options
	marshal_opts.pretty = true
	data, err := json.marshal(ols_json, marshal_opts, allocator)
	return data, err
}


VSCode_Config_Json :: struct {
	type: string,
	request: string,
	preLaunchTask: string,
	name: string,
	program: string,
	args: []string,
	cwd: string,
}

VSCode_Launch_Json :: struct {
	version: string,
	configurations: [dynamic]VSCode_Config_Json,
}

VSCode_Task_Json :: struct {
	label: string,
	type: string,
	command: string,
}

VSCode_Tasks_Json :: struct {
	version: string,
	tasks: [dynamic]VSCode_Task_Json,
}

build_vscode_json :: proc(target: ^Target, config: Odin_Config, opts: Default_Dev_Opts, allocator := context.allocator) -> (launch_data, tasks_data: []u8, err: json.Marshal_Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)

	launch_json: VSCode_Launch_Json
	launch_json.version = "0.2.0"
	launch_json.configurations = make([dynamic]VSCode_Config_Json, context.temp_allocator)

	debug_config_json: VSCode_Config_Json
	debug_config_json.type = opts.debugger_type if opts.debugger_type != "" else "cppvsdbg"
	debug_config_json.request = "launch"
	debug_config_json.cwd = opts.custom_cwd
	if .Cwd_Out in opts.flags do debug_config_json.cwd = filepath.join({"${workspaceFolder}/", config.out_dir}, context.temp_allocator) // Todo(Dragos): make this an absolute path, no workspacefodler
	if .Cwd_Workspace in opts.flags do debug_config_json.cwd = "${workspaceFolder}/"
	debug_config_json.args = strings.split(opts.launch_args, " ", context.temp_allocator) // Note(Dragos): Is this correct?
	debug_config_json.name = target.name
	debug_config_json.program = filepath.join({target.root_dir, config.out_dir, config.out_file}, context.temp_allocator)

	append(&launch_json.configurations, debug_config_json)

	tasks_json: VSCode_Tasks_Json
	tasks_json.version = "2.0.0"
	
	marshal_opts: json.Marshal_Options
	marshal_opts.pretty = true
	launch_data = json.marshal(launch_json, marshal_opts, allocator) or_return
	tasks_data = json.marshal(tasks_json, marshal_opts, allocator) or_return
	return launch_data, tasks_data, nil
}

generate_odin_devenv :: proc(target: ^Target, odin_config: Odin_Config, args: []Arg, loc := #caller_location) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	opts := parse_default_devenv_args(args)
	if opts.custom_cwd == "" && .Cwd_Out not_in opts.flags && .Cwd_Workspace not_in opts.flags {
		opts.flags += {.Cwd_Out} // Default cwd
	}
	if .Generate_Ols in opts.flags {
		ols_json, json_err := build_ols_json(odin_config, DEFAULT_OLS_OPTIONS, context.temp_allocator)
		if json_err != nil {
			fmt.eprintf("Failed to generate ols settings for target %s: %s\n", target.name, json_err)
			return false
		}
		ols_path := fmt.tprintf("%s/ols.json", target.root_dir) // Todo(Dragos): Fix this shit already
		if !os.write_entire_file(ols_path, ols_json) {
			fmt.eprintf("Failed to write %s for target %s\n", ols_path, target.name)
			return false
		}
	}

	for editor in Editor do if editor in opts.editors {
		switch editor {
		case .VSCode: 
			launch, tasks, json_err := build_vscode_json(target, odin_config, opts, context.temp_allocator)
			if json_err != nil {
				fmt.eprintf("Failed to generate vscode settings for target %s: %s\n", target.name, json_err)
				return false
			}
			vscode_dir := fmt.tprintf("%s/.vscode", target.root_dir)
			launch_path := fmt.tprintf("%s/launch.json", vscode_dir)
			tasks_path := fmt.tprintf("%s/tasks.json", vscode_dir)
			make_directory(vscode_dir)
			if !os.write_entire_file(launch_path, launch) {
				fmt.eprintf("Failed to write %s for target %s\n", launch_path, target.name)
				return false
			}
			if !os.write_entire_file(tasks_path, tasks) {
				fmt.eprintf("Failed to write %s for target %s\n", tasks_path, target.name)
				return false
			}
		}
	}
	
	return true
}
