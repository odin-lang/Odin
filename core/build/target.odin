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
}

Target_Run_Proc :: #type proc(target: ^Target, mode: Run_Mode, args: []Arg, loc := #caller_location) -> bool

add_target :: proc(project: ^Project, target: ^Target, run_proc: Target_Run_Proc, subdir_count := 1, loc := #caller_location) {
	assert(subdir_count >=  1, "The build system needs to be in a subdirectory")
	append(&project.targets, target)
	target.project = project
	target.run_proc = run_proc
	slash_i := 0
	count := 0
	#reverse for ch, i in loc.file_path {
		if ch == '/' || ch == '\\' {
			count += 1 // first slash is the build package
		}
		if count == subdir_count + 1 {
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

// Returns a path relative to the target root dir. Tries to return the shortest relative path before returning the absolute path
relpath :: proc(target: ^Target, path: string, allocator := context.allocator) -> (result: string) {
	is_temp_allocator := allocator == context.temp_allocator
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = is_temp_allocator)
	absolute_path := filepath.join({target.root_dir, path}, context.temp_allocator)
	relative_path, err := filepath.rel(target.root_dir, absolute_path, context.temp_allocator)
	result = absolute_path if err != nil else relative_path
	return strings.clone(result, allocator) if !is_temp_allocator else result
}

abspath :: proc(target: ^Target, path: string, allocator := context.allocator) -> (result: string) {
	return filepath.join({target.root_dir, path}, allocator)
}

trelpath :: proc(target: ^Target, path: string) -> (result: string) {
	return relpath(target, path, context.temp_allocator)
}

tabspath :: proc(target: ^Target, path: string) -> (result: string) {
	return abspath(target, path, context.temp_allocator)
}