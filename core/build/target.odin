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

// Note(Dragos): If we gots dependencies, then the project should have a #location of sorts, and be appended to paths like the src folder, out dir etc.
//				That would mean that ALL build systems would EXPECT a certain structure (for example having the build script package as a subfolder of the main project)
Project :: struct {
	name: string,
	targets: [dynamic]^Target,
	target_prefix: string,
}

Run_Mode :: enum {
	Build, // Default Mode
	Help,
	Dev,
}

mode_strings := [Run_Mode]string {
	.Build = "[Build]",
	.Help = "[Help]",
	.Dev = "[Dev]",
}

Target :: struct {
	name: string,
	platform: Platform,

    run: Run_Target_Proc,

	project: ^Project,
	root_dir: string,
	depends: [dynamic]^Target,
}

Run_Target_Proc :: #type proc(target: ^Target, mode: Run_Mode, args: []Arg, loc := #caller_location) -> bool


add_target :: proc(project: ^Project, target: ^Target, loc := #caller_location) {
	append(&project.targets, target)
	target.project = project
	slash_i := 0
	#reverse for ch, i in loc.file_path {
		if ch == '/' || ch == '\\' {
			slash_i = i
			break
		}
	}
	target.root_dir = loc.file_path[:slash_i]
}

run_target :: proc(target: ^Target, mode: Run_Mode, args: []Arg, loc := #caller_location) -> bool {
	assert(target.run != nil, "Target run proc not found.")
	return target->run(mode, args, loc)
}

/*
target_build :: proc(target: ^Target, settings: Settings) -> (ok: bool) {
	config := target_config(target, settings)
	// Note(Dragos): This is a check for the new dependency thing
	config.src_path = filepath.join({target.root_dir, config.src_path}, context.temp_allocator)
	config.out_dir = filepath.join({target.root_dir, config.out_dir}, context.temp_allocator)
	config.rc_path = filepath.join({target.root_dir, config.rc_path}, context.temp_allocator)
	
	for dep in target.depends {
		target_build(dep, settings) or_return // Note(Dragos): Recursion breaks my brain a bit. Is THIS ok??
	}
	
	//return _build_package(config)
	return false
}*/
