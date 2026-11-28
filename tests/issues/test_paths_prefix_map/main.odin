package test_paths_prefix_map

import "base:runtime"

main :: proc() {
	loc := #location()
	if #file != "src/main.odin" {
		runtime.print_string(#file)
		runtime.print_string("\n")
		runtime.trap()
	}
	if #directory != "src/" {
		runtime.print_string(#directory)
		runtime.print_string("\n")
		runtime.trap()
	}
	if loc.file_path != "src/main.odin" {
		runtime.print_string(loc.file_path)
		runtime.print_string("\n")
		runtime.trap()
	}
	if ODIN_ROOT != "root/" && ODIN_ROOT != "root\\" {
		runtime.print_string(ODIN_ROOT)
		runtime.print_string("\n")
		runtime.trap()
	}
}
