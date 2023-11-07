package build

import "core:unicode/utf8"
import "core:runtime"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:encoding/json"
import "core:path/filepath"

// Creates a directory recursively or does nothing if it exists.
make_directory :: proc(name: string) {
	// Note(Dragos): I wrote this a while ago. Is there a better way?
	slash_dir, _ := filepath.to_slash(name, context.temp_allocator)
	dirs := strings.split_after(slash_dir, "/", context.temp_allocator)
	for _, i in dirs {
		new_dir := strings.concatenate(dirs[0 : i + 1], context.temp_allocator)
		os.make_directory(new_dir)
	}
}

exec :: proc(file: string, args: []string) -> int {
	return _exec(file, args)
}