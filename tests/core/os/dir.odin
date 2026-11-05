package tests_core_os

import "core:os"
import "core:log"
import "core:slice"
import "core:testing"
import "core:strings"

@(test)
test_read_dir :: proc(t: ^testing.T) {
	path, err_join := os.join_path({#directory, "dir"}, context.allocator)
	defer delete(path)

	fis, err_read := os.read_all_directory_by_path(path, context.allocator)
	defer os.file_info_slice_delete(fis, context.allocator)

	slice.sort_by_key(fis, proc(fi: os.File_Info) -> string { return fi.name })

	if err_read == .Unsupported {
		log.warn("core:os directory functionality is unsupported, skipping test")
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
	path, err := os.join_path({#directory, "dir"}, context.allocator)
	defer delete(path)
	testing.expect_value(t, err, nil)

	w := os.walker_create(path)
	defer os.walker_destroy(&w)

	test_walker_internal(t, &w)
}

@(test)
test_walker_file :: proc(t: ^testing.T) {
	path, err_join := os.join_path({#directory, "dir"}, context.allocator)
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
		log.warn("core:os directory functionality is unsupported, skipping test")
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

// Builds `root/D/x.txt` and `root/D/maps/m.txt` in a fresh temporary directory.
@(private="file")
make_walker_tree :: proc(t: ^testing.T) -> (root: string, ok: bool) {
	err: os.Error
	root, err = os.make_directory_temp("", "odin_walker_*", context.temp_allocator)
	if err == .Unsupported {
		log.warn("core:os directory functionality is unsupported, skipping test")
		return
	}
	testing.expect_value(t, err, nil) or_return

	maps, _ := os.join_path({root, "D", "maps"}, context.temp_allocator)
	testing.expect_value(t, os.make_directory_all(maps), nil) or_return

	x, _ := os.join_path({root, "D", "x.txt"}, context.temp_allocator)
	testing.expect_value(t, os.write_entire_file(x, "x"), nil) or_return

	m, _ := os.join_path({root, "D", "maps", "m.txt"}, context.temp_allocator)
	testing.expect_value(t, os.write_entire_file(m, "m"), nil) or_return

	return root, true
}

// On Windows, renaming `root/D` fails while a handle to something inside it is still open.
@(private="file")
expect_rename_d :: proc(t: ^testing.T, root: string, loc := #caller_location) {
	d, _ := os.join_path({root, "D"}, context.temp_allocator)
	e, _ := os.join_path({root, "E"}, context.temp_allocator)
	testing.expect_value(t, os.rename(d, e), nil, loc)
}

@(test)
test_walker_destroy_releases_directories :: proc(t: ^testing.T) {
	root, ok := make_walker_tree(t)
	if !ok {
		return
	}
	defer os.remove_all(root)

	w := os.walker_create(root)
	count := 0
	for _ in os.walker_walk(&w) {
		count += 1
	}
	_, err := os.walker_error(&w)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, count, 4)
	os.walker_destroy(&w)

	expect_rename_d(t, root)
}

@(test)
test_walker_destroy_releases_directories_abandoned :: proc(t: ^testing.T) {
	root, ok := make_walker_tree(t)
	if !ok {
		return
	}
	defer os.remove_all(root)

	m, _ := os.join_path({"maps", "m.txt"}, context.temp_allocator)

	// Stop while the walker is reading `root/D/maps`.
	w := os.walker_create(root)
	found := false
	for info in os.walker_walk(&w) {
		if strings.has_suffix(info.fullpath, m) {
			found = true
			break
		}
	}
	testing.expect(t, found)
	os.walker_destroy(&w)

	expect_rename_d(t, root)
}

@(test)
test_walker_reuse_then_destroy_releases_directories :: proc(t: ^testing.T) {
	root, ok := make_walker_tree(t)
	if !ok {
		return
	}
	defer os.remove_all(root)

	maps, _ := os.join_path({root, "D", "maps"}, context.temp_allocator)

	// Abandon a walk of `root/D/maps`, reuse the walker on `root`, then destroy it.
	w := os.walker_create(maps)
	for _ in os.walker_walk(&w) {
		break
	}
	os.walker_init(&w, root)
	count := 0
	for _ in os.walker_walk(&w) {
		count += 1
	}
	testing.expect_value(t, count, 4)
	os.walker_destroy(&w)

	expect_rename_d(t, root)
}

@(test)
test_read_directory_iterator_destroy_releases_directory :: proc(t: ^testing.T) {
	root, ok := make_walker_tree(t)
	if !ok {
		return
	}
	defer os.remove_all(root)

	maps, _ := os.join_path({root, "D", "maps"}, context.temp_allocator)
	f, err := os.open(maps)
	testing.expect_value(t, err, nil)

	it := os.read_directory_iterator_create(f)
	count := 0
	for _ in os.read_directory_iterator(&it) {
		count += 1
	}
	testing.expect_value(t, count, 1)
	os.read_directory_iterator_destroy(&it)
	os.close(f)

	expect_rename_d(t, root)
}

@(test)
test_read_dir_releases_directory :: proc(t: ^testing.T) {
	root, ok := make_walker_tree(t)
	if !ok {
		return
	}
	defer os.remove_all(root)

	maps, _ := os.join_path({root, "D", "maps"}, context.temp_allocator)
	fis, err := os.read_all_directory_by_path(maps, context.allocator)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, len(fis), 1)
	os.file_info_slice_delete(fis, context.allocator)

	expect_rename_d(t, root)
}
