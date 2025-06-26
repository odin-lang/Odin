package tests_core_os_os2

import os "core:os/os2"
import    "core:log"
import    "core:slice"
import    "core:testing"
import    "core:strings"

@(test)
test_read_dir :: proc(t: ^testing.T) {
	path, err_join := os.join_path({#directory, "../dir"}, context.allocator)
	defer delete(path)

	fis, err_read := os.read_all_directory_by_path(path, context.allocator)
	defer os.file_info_slice_delete(fis, context.allocator)

	slice.sort_by_key(fis, proc(fi: os.File_Info) -> string { return fi.name })

	if err_read == .Unsupported {
		log.warn("os2 directory functionality is unsupported, skipping test")
		return
	}

	testing.expect_value(t, err_join, nil)
	testing.expect_value(t, err_read, nil)
	testing.expect_value(t, len(fis), 2)

	testing.expect_value(t, fis[0].name, "b.txt")
	testing.expect_value(t, fis[0].type, os.File_Type.Regular)

	testing.expect_value(t, fis[1].name, "sub")
	testing.expect_value(t, fis[1].type, os.File_Type.Directory)
}

@(test)
test_walker :: proc(t: ^testing.T) {
	path, err := os.join_path({#directory, "../dir"}, context.allocator)
	defer delete(path)
	testing.expect_value(t, err, nil)

	w := os.walker_create(path)
	defer os.walker_destroy(&w)

	test_walker_internal(t, &w)
}

@(test)
test_walker_file :: proc(t: ^testing.T) {
	path, err_join := os.join_path({#directory, "../dir"}, context.allocator)
	defer delete(path)
	testing.expect_value(t, err_join, nil)

	f, err_open := os.open(path)
	testing.expect_value(t, err_open, nil)
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

	joined_1, err_joined_1 := os.join_path({"dir", "b.txt"}, context.allocator)
	joined_2, err_joined_2 := os.join_path({"dir", "sub"}, context.allocator)
	joined_3, err_joined_3 := os.join_path({"dir", "sub", ".gitkeep"}, context.allocator)

	testing.expect_value(t, err_joined_1, nil)
	testing.expect_value(t, err_joined_2, nil)
	testing.expect_value(t, err_joined_3, nil)

	expected := [?]Seen{
		{.Regular,   joined_1},
		{.Directory, joined_2},
		{.Regular,   joined_3},
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
