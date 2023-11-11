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

    run_proc: Target_Run_Proc,

	project: ^Project,
	root_dir: string,
	depends: [dynamic]^Target,
}

Target_Run_Proc :: #type proc(target: ^Target, mode: Run_Mode, args: []Arg, loc := #caller_location) -> bool


add_target :: proc(project: ^Project, target: ^Target, run_proc: Target_Run_Proc, loc := #caller_location) {
	append(&project.targets, target)
	target.project = project
	target.run_proc = run_proc
	slash_i := 0
	count := 0
	#reverse for ch, i in loc.file_path {
		if ch == '/' || ch == '\\' {
			count += 1 // first slash is the build package
		}
		if count == 2 { // this effectively makes the build system only runnable from the direct subdirectory of it (aka `odin run build` rather than `odin run .`)
			slash_i = i
			break
		}
	}
	target.root_dir = loc.file_path[:slash_i]
}

run_target :: proc(target: ^Target, mode: Run_Mode, args: []Arg, loc := #caller_location) -> bool {
	assert(target.run_proc != nil, "Target run proc not found.")
	return target.run_proc(target, mode, args, loc)
}
