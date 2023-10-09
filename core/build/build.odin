package build

import "core:strings"
import "core:fmt"
import "core:os"
import "core:c/libc"
import "core:path/filepath"
import "core:sync"
import "core:encoding/json"


config_make :: proc(allocator := context.allocator) -> (config: Config) {
    config.defines = make(map[string]Define_Val, 32, allocator)
    config.collections = make(map[string]string, 16, allocator)
    config.post_build_commands = make([dynamic]Command, allocator)
    config.pre_build_commands = make([dynamic]Command, allocator)
    return
}

syscall :: proc(cmd: string, echo: bool) -> int {
    cstr := strings.clone_to_cstring(cmd, context.temp_allocator)
    if echo {
        fmt.printf("%s\n", cmd)
    }
    return cast(int)libc.system(cstr)
}

config_delete :: proc(config: Config) {
    delete(config.defines)
    delete(config.collections)
    delete(config.post_build_commands)
    delete(config.pre_build_commands)
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

_define_to_arg :: proc(sb: ^strings.Builder, name: string, val: Define_Val) {
    using strings
    
    fmt.sbprintf(sb, "-define:%s=", name)

    switch v in val {
        case bool: {
            write_string(sb, "true" if v else "false")
        }
        case int: {
            write_int(sb, v)
        }
        case string: {
            fmt.sbprintf(sb, `"%s"`, v)
        }
    }
}

_platform_to_arg :: proc(sb: ^strings.Builder, platform: Platform) {
    if platform.os != .Unknown {
        fmt.sbprintf(sb, "-target:%s_%s", _os_to_arg[platform.os], _arch_to_arg[platform.arch])
    }
}

_collection_to_arg :: proc(sb: ^strings.Builder, collection: string, path: string) {
    fmt.sbprintf(sb, `-collection:%s="%s"`, collection, path)
}

_flags_to_arg :: proc(sb: ^strings.Builder, flags: Compiler_Flags) {
    for flag in Compiler_Flag do if flag in flags {
        fmt.sbprintf(sb, "%s ", _compiler_flag_to_arg[flag])
    }
}

_config_to_args :: proc(sb: ^strings.Builder, config: Config) {
    using strings, fmt

    for flag in Vet_Flag do if flag in config.vet {
        sbprintf(sb, "%s ", _vet_flag_to_arg[flag])
    }

    sbprintf(sb, "%s ", _build_mode_to_arg[config.build_mode])
    if config.style != .None {
        sbprintf(sb, "%s ", _style_mode_to_arg[config.style])
    }
    sbprintf(sb, "%s ", _opt_mode_to_arg[config.opt])

    _platform_to_arg(sb, config.platform)
    write_string(sb, " ")
    _flags_to_arg(sb, config.flags)
    // function already returns space
    for key, val in config.collections {
        _collection_to_arg(sb, key, val)
        write_string(sb, " ")
    }

    for key, val in config.defines {
        _define_to_arg(sb, key, val)
        write_string(sb, " ")
    }

    sbprintf(sb, `-out:"%s"`, config.out_path)
}


build_package :: proc(config: Config) {
    config_output_dirs: {
        dir := filepath.dir(config.out_path, context.temp_allocator) 
        slashDir, _ := filepath.to_slash(dir, context.temp_allocator)
        dirs := strings.split_after(slashDir, "/", context.temp_allocator)
        for _, i in dirs {
            newDir := strings.concatenate(dirs[0 : i + 1], context.temp_allocator)
            os.make_directory(newDir)
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

generate_ols :: proc(config: Config) {
    argsBuilder := strings.builder_make()
    _config_to_args(&argsBuilder, config)
    args := strings.to_string(argsBuilder)
    settings := default_language_server_settings(context.temp_allocator)
    for name, path in config.collections {
        append(&settings.collections, Collection{name = name, path = path})
    }
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

/*
    output.exe <config-name|all> // build 1 target or all
    output.exe -devenv:<editor> <config-name> // Setup the devenv without building. If no editor is specified, it will just generate ols.json
    output.exe help
*/
build_options_make_from_args :: proc(args: []string) -> (o: Build_Options) {
    if len(args) == 0 {
        o.command_type = .Display_Help
        return
    }
    command := args[0] 
    switch {
        case strings.has_prefix(command, "-devenv"): {
            o.command_type = .Dev_Setup
            components := strings.split(command, ":", context.temp_allocator)
            if len(components) == 2 {
                switch components[1] {
                    case "vscode": {
                        o.dev_env = .VSCode 
                    }
                    case: {
                        o.dev_env = .None 
                        o.command_type = .Invalid
                    }
                }
            } else {
                o.dev_env = .None
            }
        }

        case: {
            o.command_type = .Build
        }
    }

    #partial switch o.command_type {
        case .Build: {
            assert(len(args) == 1, "Expected 1 argument for build command")
            o.config_name = args[0] 
        }
        
        case .Dev_Setup: {
            assert(len(args) == 2, "Expected 1 argument for devenv command")
            o.config_name = args[1]
        }
    }

    assert(o.command_type != .Invalid, "Invalid arguments")
    return
}

syscall_command :: proc($cmd: string) -> Command {
    return proc(config: Config) {
        cstr := strings.clone_to_cstring(cmd, context.temp_allocator)
        result := cast(int)libc.system(cstr)
        return result
    }
}

add_target :: #force_inline proc(project: ^Project($Target), target: Target) {
    append(&project.targets, target)
}

display_command_help :: proc(project: Project($Target)) {
    fmt.printf("Possible usages:\n")
    fmt.printf("%s <configuration name|all> -> builds the specified configuration or all targets\n", os.args[0])
    fmt.printf("%s -devenv:<editor> <configuration name> -> generates project files configured for the given configuration. If no editor is specified, it will generate only ols.json\n", os.args[0]) 
    fmt.printf("Available Configurations:\n")
    for target in project.targets {
        config := project->configure_target_proc(target)
        fmt.printf("\t%s\n", config.name)
    }
}

build_project :: proc(project: Project($Target), options: Build_Options) {
    switch options.command_type {
        case .Invalid: {}

        case .Build_Dependencies: {
            
        }
            
        case .Display_Help: {
           display_command_help(project)
        }

        case .Build: {
            foundTarget := false
            for target in project.targets {
                config := project->configure_target_proc(target)
                if patterns.match(options.config_name, config.name) {
                    foundTarget = true
                    build_package(config)
                }
            }

            if !foundTarget {
                fmt.printf("Could not find configuration %s\n", options.config_name)
            }
            
        }

        case .Dev_Setup: {
            foundTarget := false
                for target in project.targets {
                    config := project->configure_target_proc(target)
                    if patterns.match(options.config_name, config.name) {
                        foundTarget = true
                        generate_ols(config)
                        break
                    }
                }

                if !foundTarget {
                    fmt.printf("Could not find configuration %s\n", options.config_name)
                }
        }
    }
    
}