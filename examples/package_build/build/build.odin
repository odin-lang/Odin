package src_build

import "core:build"
import "core:os"

Mode :: enum {
    Debug,
    Release,
}

Target :: struct {
    using target: build.Target,
    mode: Mode,
}

project: build.Project
target_debug: Target = {
    target = {
        name = "deb",
        platform = {ODIN_OS, ODIN_ARCH},
    },
    mode = .Debug,
}
target_release: Target = {
    target = {
        name = "rel",
        platform = {ODIN_OS, ODIN_ARCH},
    },
    mode = .Release,
}

config_target :: proc(project: ^build.Project, target: ^build.Target) -> (config: build.Config) {
    target := cast(^Target)target
    config.name = target.name 
    config.platform = target.platform

    config.defines["HELLOPE_DEFINES"] = 23 // works with bools, ints, strings
    
    switch target.mode {
    case .Debug:
        config.flags += {.Debug}
        config.opt = .None

    case .Release:
        config.flags += {.Disable_Assert}
        config.opt = .Speed
    }

    return config
}

@init
_ :: proc() {
    project.name = "Build System Demo"
    build.add_target(&project, &target_debug)
    build.add_target(&project, &target_release)
    build.add_project(&project)
    project.configure_target_proc = config_target
}

main :: proc() {
    opts := build.build_options_make_from_args(os.args)
    opts.default_config_name = "deb"
    opts.display_external_configs = true
    build.run(&project, opts)
}
