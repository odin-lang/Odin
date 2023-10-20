package src_build

import "core:build"
import "core:os"
import "core:strings"

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

config_target :: proc(project: ^build.Project, target: ^build.Target, settings: build.Settings) -> (config: build.Config) {
	target := cast(^Target)target
	config.name = target.name 
	config.platform = target.platform
	config.out_file = "demo.exe" if target.platform.os == .Windows else "demo.out"
	config.out_dir = strings.concatenate({"out/", target.name})
	config.build_mode = .EXE
	config.src_path = "src"

	config.defines["DEFINED_INT"] = 99
	config.defines["DEFINED_STRING"] = "Hellope #config"
	config.defines["DEFINED_BOOL"] = true
	
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
	context = build.default_context()
	project.name = "Build System Demo"
	build.add_target(&project, &target_debug)
	build.add_target(&project, &target_release)
	build.add_project(&project)
	project.configure_target_proc = config_target
}

main :: proc() {
	context = build.default_context()
	settings: build.Settings
	build.settings_init_from_args(&settings, os.args, {})
	settings.default_config_name = "deb"
	settings.display_external_configs = true
	build.run(&project, settings)
}
