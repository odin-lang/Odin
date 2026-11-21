package tests_core_os

import "core:fmt"
import "core:os"
import "core:testing"
import win32 "core:sys/windows"

@(test)
test_long_path_without_prefix :: proc(t: ^testing.T) {
	root, root_err := os.make_directory_temp("", "odin-long-path-*", context.temp_allocator)
	if root_err != nil {
		testing.fail_now(t, "could not create temporary directory")
	}
	defer os.remove_all(root)

	deepest := root
	for _ in 0..<12 {
		next, next_err := os.join_path({deepest, "abcdefghijklmnopqrstuvwxyz"}, context.temp_allocator)
		if next_err != nil {
			testing.fail_now(t, "could not construct nested directory path")
		}
		deepest = next
	}
	testing.expect(t, len(deepest) > win32.MAX_PATH)

	if err := os.make_directory_all(deepest); err != nil {
		testing.fail_now(t, fmt.tprintf("make_directory_all failed beyond MAX_PATH: %v", err))
	}
	testing.expect(t, os.is_directory(deepest))

	leaf, leaf_err := os.join_path({deepest, "file.txt"}, context.temp_allocator)
	testing.expect_value(t, leaf_err, nil)
	testing.expect_value(t, os.write_entire_file(leaf, "long path\n"), nil)

	fi, stat_err := os.stat(leaf, context.temp_allocator)
	testing.expect_value(t, stat_err, nil)
	testing.expect_value(t, fi.type, os.File_Type.Regular)
	testing.expect_value(t, fi.size, 10)

	data, read_err := os.read_entire_file(leaf, context.temp_allocator)
	testing.expect_value(t, read_err, nil)
	testing.expect_value(t, string(data), "long path\n")

	fis, list_err := os.read_all_directory_by_path(deepest, context.temp_allocator)
	testing.expect_value(t, list_err, nil)
	testing.expect_value(t, len(fis), 1)
	if len(fis) == 1 {
		testing.expect_value(t, fis[0].name, "file.txt")
	}

	renamed, renamed_err := os.join_path({deepest, "renamed.txt"}, context.temp_allocator)
	testing.expect_value(t, renamed_err, nil)
	testing.expect_value(t, os.rename(leaf, renamed), nil)
	testing.expect(t, os.exists(renamed))
	testing.expect_value(t, os.remove(renamed), nil)
	testing.expect(t, !os.exists(renamed))

	testing.expect_value(t, os.remove_all(root), nil)
	testing.expect(t, !os.exists(root))
}
