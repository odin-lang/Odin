package build

import "core:unicode/utf8"
import "core:runtime"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:encoding/json"
import "core:path/filepath"

// Important Note(Dragos): We need a system for handling imported dependencies when configuring the devenv because the paths might be goofy. This might also impact odin build... We'll see...

VSCode_Debugger_Type :: enum {
	cppvsdbg,
	cppdbg,
}

VSCode_Request_Type :: enum {
	launch,
}

VSCode_Config_Json :: struct {
	type: string,
	request: string,
	preLaunchTask: string,
	name: string,
	program: string,
	args: [dynamic]string,
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

S_IRUSR :: 0x0400
S_IWUSR :: 0x0200

/*
_generate_vscode :: proc(target: ^Target, settings: Settings, opts: Dev_Options) {
	config := target_config(target, settings) // Note(Dragos): I really don't like settings being based around

	if os.is_dir(".vscode") || os.make_directory(".vscode") == os.ERROR_NONE {
		launch_file, launch_err := os.open(".vscode/launch.json", os.O_CREATE | os.O_TRUNC | os.O_RDWR, S_IRUSR | S_IWUSR)
		tasks_file, tasks_err := os.open(".vscode/tasks.json", os.O_CREATE | os.O_TRUNC | os.O_RDWR, S_IRUSR | S_IWUSR)
		if launch_err == os.ERROR_NONE && tasks_err  == os.ERROR_NONE {
			defer {
				os.close(launch_file)
				os.close(tasks_file)
			}
			launch_json: VSCode_Launch_Json
			
			tasks_json: VSCode_Tasks_Json
			tasks_json.version = "2.0.0"
			launch_json.version = "0.2.0"
			
			debug_config_json: VSCode_Config_Json
			if opts.custom_cwd != "" {
				fmt.eprintf("Cannot currently have a custom cwd for vscode.\n")
			} else if .Cwd_Out in opts.flags {
				debug_config_json.cwd = filepath.join({"%{workspaceFolder}/", config.out_dir}) // Note(Dragos): Test this
			} else if .Cwd_Workspace in opts.flags {
				debug_config_json.cwd = "${workspaceFolder}"
			} else {
				debug_config_json.cwd = "${workspaceFolder}"
			}

			debug_config_json.program, _ = filepath.abs(filepath.join({config.out_dir, config.out_file}))
			debug_config_json.type = "cppvsdbg" if opts.vscode_debugger_type == .cppvsdbg else "cppdbg"
			debug_config_json.request = "launch"
			debug_config_json.name = target.name
			if opts.launch_args != "" {
				append(&debug_config_json.args, opts.launch_args)
			}


			if .Build_Pre_Launch in opts.flags {
				task_json: VSCode_Task_Json
				task_json.label = "Build"
				debug_config_json.preLaunchTask = task_json.label
				task_json.type = "shell"
				task_json.command = strings.concatenate({"build ", target.name})
				append(&tasks_json.tasks, task_json)
			}

			append(&launch_json.configurations, debug_config_json)

			marshal_opts: json.Marshal_Options
			marshal_opts.pretty = true
			
			if data, err := json.marshal(launch_json, marshal_opts); err == nil {
				os.write_string(launch_file, string(data))
			} else {
				fmt.eprintf("Error serializing launch_json %v\n", err)
			}

			if data, err := json.marshal(tasks_json, marshal_opts); err == nil {
				os.write_string(tasks_file, string(data))
			} else {
				fmt.eprintf("Error serializing tasks_json %v\n", err)
			}

		} else {
			fmt.eprintf("Error making vscode launch.json and/or tasks.json\n")
		}
	} else {
		fmt.eprintf("Error making vscode directory.\n")
	}
}
*/

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

generate_odin_devenv :: proc(target: ^Target, odin_config: Odin_Config, args: []Arg, loc := #caller_location) -> bool {

	return true
}

build_ols_json :: proc(config: Odin_Config, opts: Language_Server_Options, allocator := context.allocator) -> ([]u8, json.Marshal_Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	ols_json: Ols_Json
	ols_json.collections = make([dynamic]Collection, context.temp_allocator)
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

write_ols_json :: proc(target: ^Target, file: string, config: Odin_Config, opts: Language_Server_Options) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	
	data, err := build_ols_json(config, opts, context.temp_allocator)
	if err != nil {
		return false
	}
	return os.write_entire_file(file, data)
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

Odin_Dev_Opts :: struct {
	flags: Odin_Dev_Flags,
	editors: Editors,
	vscode_debugger_type: VSCode_Debugger_Type,
	launch_args: string,
	custom_cwd: string,
	build_system_args: string,
}