package build

import "core:strings"
import "core:fmt"
import "core:os"
import "core:c/libc"
import "core:path/filepath"
import "core:sync"
import "core:encoding/json"

syscall :: proc(cmd: string, echo: bool) -> int {
    cstr := strings.clone_to_cstring(cmd, context.temp_allocator)
    if echo {
        fmt.printf("%s\n", cmd)
    }
    return cast(int)libc.system(cstr)
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

build_package :: proc(config: Config) {
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
            fmt.fprintf(os.stderr, "Pre-Build Command '%s' failed with exit code %d\n", cmd.name, result)
            return
        }
    }
    command := fmt.ctprintf("odin build %s %s", config.src_path, args)
    fmt.printf("%s\n", command)
    exit_code := libc.system(command)
    if exit_code != 0 {
        fmt.printf("Build failed with exit code %v\n", exit_code)
        return
    } else {
        for cmd in config.post_build_commands {
            if result := cmd.command(config); result != 0 {
                fmt.fprintf(os.stderr, "Post-Build Command '%s' failed with exit code %d\n", cmd.name, result)
                return
            }
        }
    }
    
   
}

default_language_server_settings :: proc(allocator := context.allocator) -> (settings: Language_Server_Settings) {
    settings.collections = make([dynamic]Collection, allocator)
    settings.enable_document_symbols = true 
    settings.enable_semantic_tokens = true 
    settings.enable_hover = true 
    settings.enable_snippets = true
    return 
}

default_build_options :: proc() -> (o: Build_Options) {
    o.command_type = .Build
    o.config_name = "*"
    return
}

syscall_command :: proc($cmd: string) -> Command {
    return proc(config: Config) {
        cstr := strings.clone_to_cstring(cmd, context.temp_allocator)
        result := cast(int)libc.system(cstr)
        return result
    }
}

parse_args :: proc(args: []string) -> (o: Build_Options, ok: bool) #optional_ok {
    command := args[0]
    args := args[1:]
    if len(args) == 0 {
        o.command_type = .Build
        return
    }
    
    display_help := false
    build_project := true
    config_name := ""
    for i in 0..<len(args) {
        arg := args[i]
         
        if arg[0] == '-' do switch {
        case arg == "-help":
            display_help = true
            build_project = false

        case arg == "-ols":
            build_project = false
            o.dev_opts.flags += {.Generate_Ols}
        case arg == "-build-pre-launch":
            build_project = false
            o.dev_opts.flags += {.Build_Pre_Launch}

        case arg == "-vscode":
            build_project = false
            o.dev_opts.editors += {.VSCode}

        case arg == "-use-cppvsdbg":
            build_project = false
            o.dev_opts.vscode_debugger_type = .cppvsdbg

        case arg == "-use-cppdbg":
            build_project = false
            o.dev_opts.vscode_debugger_type = .cppdbg

        case arg == "cwd-workspace":
            build_project = false
            o.dev_opts.flags += {.Cwd_Workspace}

        case arg == "cwd-out":
            build_project = false
            o.dev_opts.flags += {.Cwd_Out}

        case strings.has_prefix(arg, "-cwd"):
            build_project = false
            fmt.eprintf("Flag %s not implemented\n", arg)

        case strings.has_prefix(arg, "-launch-args"):
            build_project = false
            fmt.eprintf("Flag %s not implemented\n", arg)

        case strings.has_prefix(arg, "-include-build-system"):
            build_project = false
            o.dev_opts.flags += {.Include_Build_System}
            fmt.eprintf("Flag %s not implemented\n", arg)

        case: 
            fmt.eprintf("Invalid flag %s\n", arg)
            return
        } else {
            if config_name != "" {
                fmt.eprintf("Config already set to %s and cannot be re-assigned to %s. Cannot have 2 configurations built with the same command (yet). ", config_name, arg)
                return
            }
            config_name = arg
            o.config_name = config_name
        }
    }

    // Note(Dragos): I do not like this approach
    if display_help {
        o.command_type = .Display_Help
    } else if build_project {
        o.command_type = .Build
    } else {
        o.command_type = .Dev_Setup
    }
    return o, true
}

add_target :: proc(project: ^Project, target: ^Target) {
    append(&project.targets, target)
    target.project = project
}

add_project :: proc(project: ^Project) {
    append(&_build_ctx.projects, project)
}

run :: proc(main_project: ^Project, opts: Build_Options) {
    assert(len(_build_ctx.projects) != 0, "No projects were added. Use build.add_project to add one.")
    opts := opts
    if opts.config_name == "" do opts.config_name = opts.default_config_name

    switch opts.command_type {
    case .Build:
        found_config := false
        for project in _build_ctx.projects do if opts.display_external_configs || main_project == project {
            for target in project.targets {
                config := project->configure_target_proc(target)
                prefixed_name := strings.concatenate({project.config_prefix, config.name}, context.temp_allocator)
                if _match(opts.config_name, prefixed_name) {
                    found_config = true
                    build_package(config)
                }
            }
        }
        if !found_config {
            fmt.eprintf("Could not find configuration %s\n", opts.config_name)
        }
    
    case .Dev_Setup:
        found_config := false
        for project in _build_ctx.projects do if opts.display_external_configs || main_project == project  {  
            for target in project.targets {
                config := project->configure_target_proc(target)
                prefixed_name := strings.concatenate({project.config_prefix, config.name}, context.temp_allocator)
                if _match(opts.config_name, prefixed_name) {
                    found_config = true
                    _generate_devenv(config, opts.dev_opts)
                }
            }
        }
        if !found_config {
            fmt.eprintf("Could not find configuration %s\n", opts.config_name)
        }
    
    case .Display_Help:
        _display_command_help(main_project, opts)
    
    case .Invalid: fallthrough
    case: fmt.eprintf("Invalid command type\n")
    }
}