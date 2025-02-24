package tests_core_os_os2

import os "core:os/os2"
import    "core:log"
import    "core:path/filepath"
import    "core:slice"
import    "core:testing"
import    "core:strings"

@(test)
test_read_dir :: proc(t: ^testing.T) {
	path := filepath.join({#directory, "../dir"})
	defer delete(path)

	fis, err := os.read_all_directory_by_path(path, context.allocator)
	defer os.file_info_slice_delete(fis, context.allocator)

	slice.sort_by_key(fis, proc(fi: os.File_Info) -> string { return fi.name })

	if err == .Unsupported {
		log.warn("os2 directory functionality is unsupported, skipping test")
		return
	}

	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(fis), 2)

	testing.expect_value(t, fis[0].name, "b.txt")
	testing.expect_value(t, fis[0].type, os.File_Type.Regular)

	testing.expect_value(t, fis[1].name, "sub")
	testing.expect_value(t, fis[1].type, os.File_Type.Directory)
}

@(test)
test_walker :: proc(t: ^testing.T) {
	path := filepath.join({#directory, "../dir"})
	defer delete(path)

	w := os.walker_create(path)
	defer os.walker_destroy(&w)

	test_walker_internal(t, &w)
}

@(test)
test_walker_file :: proc(t: ^testing.T) {
	path := filepath.join({#directory, "../dir"})
	defer delete(path)

	f, err := os.open(path)
	testing.expect_value(t, err, nil)
	defer os.close(f)

	w := os.walker_create(f)
	defer os.walker_destroy(&w)

	test_walker_internal(t, &w)
}

test_walker_internal :: proc(t: ^testing.T, w: ^os.Walker) {
	Seen :: struct {
		type: os.File_Type,
		path: string,
	}

	expected := [?]Seen{
		{.Regular,   filepath.join({"dir", "b.txt"})},
		{.Directory, filepath.join({"dir", "sub"})},
		{.Regular,   filepath.join({"dir", "sub", ".gitkeep"})},
	}

	seen: [dynamic]Seen
	defer delete(seen)

	for info in os.walker_walk(w) {

		errpath, err := os.walker_error(w)
		testing.expectf(t, err == nil, "walker error for %q: %v", errpath, err)

		append(&seen, Seen{
			info.type,
			strings.clone(info.fullpath),
		})
	}

	if _, err := os.walker_error(w); err == .Unsupported {
		log.warn("os2 directory functionality is unsupported, skipping test")
		return
	}

	testing.expect_value(t, len(seen), len(expected))

	for expectation in expected {
		found: bool
		for entry in seen {
			if strings.has_suffix(entry.path, expectation.path) {
				found = true
				testing.expect_value(t, entry.type, expectation.type)
				delete(entry.path)
			}
		}
		testing.expectf(t, found, "%q not found in %v", expectation, seen)
		delete(expectation.path)
	}
} 
