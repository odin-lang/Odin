package src_build

import "core:build"
import "core:os"
import "core:strings"
import "core:fmt"

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
		name = "dbg",
		 // Note(Dragos): The nil abi should be changed. Maybe add it to config instead of platform as it's unintuitive and not mentioning it errors
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

run_target :: proc(target: ^build.Target, mode: build.Run_Mode, args: []build.Arg, loc := #caller_location) -> bool {
	target := cast(^Target)target
	config: build.Odin_Config
	config.platform = target.platform
	config.out_file = "demo.exe" if target.platform.os == .Windows else "demo"
	
	// paths must be set with build.relpath / build.abspath in order for them to be relative to the build system root directory (build/../). build.t*path alternatives use context.temp_allocator
	config.src_path = build.trelpath(target, "src")
	config.out_dir = build.trelpath(target, fmt.tprintf("out/%s", target.name))

	switch target.mode {
	case .Debug:
		config.opt = .None
		config.flags += {.Debug}
	case .Release:
		config.opt = .Speed
	}

	switch mode {
	case .Build:
		// Pre-build stuff here
		build.odin(target, .Build, config) or_return 
		// Post-build stuff here
	case .Dev: 
		return build.generate_odin_devenv(target, config, args)
	
	case .Help:
		return false // mode not implemented
	}
	return true
}

@init
_ :: proc() {
	project.name = "Build System Demo"
	build.add_target(&project, &target_debug, run_target)
	build.add_target(&project, &target_release, run_target)
}

main :: proc() {
	info: build.Cli_Info
	info.project = &project
	info.default_target = &target_debug
	build.run_cli(info, os.args)
}
