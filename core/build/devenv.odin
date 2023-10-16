package build

import "core:unicode/utf8"
import "core:runtime"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:encoding/json"
import "core:path/filepath"




VSCode_Debugger_Type :: enum {
    cppvsdbg,
    cppdbg,
}

VSCode_Request_Type :: enum {
    launch,
}

VSCode_Config_Json :: struct {
    type: VSCode_Debugger_Type,
    request: VSCode_Request_Type,
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

_generate_vscode :: proc(config: Config, opts: Dev_Options) {
    if os.make_directory(".vscode") == os.ERROR_NONE {
        launch_file, launch_err := os.open(".vscode/launch.json", os.O_CREATE | os.O_TRUNC)
        tasks_file, tasks_err := os.open(".vscode/tasks.json", os.O_CREATE | os.O_TRUNC)
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
            if opts.custom_cwd == "" {
                fmt.eprintf("Cannot currently have a custom cwd for vscode.\n")
            } else if .Cwd_Out in opts.flags {
                debug_config_json.cwd = filepath.join({"%{workspaceFolder}/", config.out_dir}) // Note(Dragos): Test this
            } else if .Cwd_Workspace in opts.flags {
                debug_config_json.cwd = "${worspaceFolder}"
            }

            debug_config_json.program, _ = filepath.abs(filepath.join({config.out_dir, config.out_file}))
            debug_config_json.type = opts.vscode_debugger_type
            debug_config_json.request = .launch
            debug_config_json.name = config.name
            if opts.launch_args != "" {
                append(&debug_config_json.args, opts.launch_args)
            }

            if .Build_Pre_Launch in opts.flags {
                task_json: VSCode_Task_Json
                task_json.label = "Build"
                debug_config_json.preLaunchTask = task_json.label
                task_json.type = "shell"
                task_json.command = strings.concatenate({"build ", config.name})
                append(&tasks_json.tasks, task_json)
            }

            marshal_opts: json.Marshal_Options
            marshal_opts.pretty = true
            
            if data, err := json.marshal(launch_json, marshal_opts); err != nil {
                os.write_string(launch_file, string(data))
            } else {
                fmt.eprintf("Error serializing launch_json\n")
            }

            if data, err := json.marshal(tasks_json, marshal_opts); err != nil {
                os.write_string(tasks_file, string(data))
            } else {
                fmt.eprintf("Error serializing tasks_json\n")
            }

        } else {
            fmt.eprintf("Error making vscode launch.json and/or tasks.json\n")
        }
    } else {
        fmt.eprintf("Error making vscode directory.\n")
    }
}

Collection :: struct {
    name, path: string,
}

Language_Server_Settings :: struct {
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


Dev_Flag :: enum {
    Generate_Ols,
    Build_Pre_Launch,
    Cwd_Workspace,
    Cwd_Out,
    Include_Build_System,
}

Dev_Flags :: bit_set[Dev_Flag]

// Make this a megastruct
Dev_Options :: struct {
    flags: Dev_Flags,
    editors: Editors,
    vscode_debugger_type: VSCode_Debugger_Type,
    launch_args: string,
    custom_cwd: string,
    build_system_args: string,
}

_generate_devenv :: proc(config: Config, opts: Dev_Options) {
    if .Generate_Ols in opts.flags do _generate_ols(config)
    for editor in Editor do if editor in opts.editors {
        switch editor {
        case .VSCode: _generate_vscode(config, opts)
        }
    }
}



_generate_ols :: proc(config: Config) {
    argsBuilder := strings.builder_make()
    _config_to_args(&argsBuilder, config)
    args := strings.to_string(argsBuilder)
    settings := default_language_server_settings(context.temp_allocator)
    for name, path in config.collections {
        append(&settings.collections, Collection{name = name, path = path})
    }
    append(&settings.collections, Collection{name = "core", path = strings.concatenate({ODIN_ROOT, "core"})})
    append(&settings.collections, Collection{name = "vendor", path = strings.concatenate({ODIN_ROOT, "vendor"})})

    settings.checker_args = args
    marshalOpts: json.Marshal_Options
    marshalOpts.pretty = true
    if data, err := json.marshal(settings, marshalOpts, context.temp_allocator); err == nil {
        if file, err := os.open("ols.json", os.O_CREATE | os.O_TRUNC); err == os.ERROR_NONE {
            os.write_string(file, string(data))
            os.close(file)
        }   
    }
}