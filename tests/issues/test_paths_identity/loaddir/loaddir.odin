package loaddir

import "core:fmt"

main :: proc() {
	files := #load_directory("files")
	for f in files {
		fmt.println(f.name)
	}
}
