// Tests issue #7547 https://github.com/odin-lang/Odin/issues/7547 (win32 implementation of `os.remove_all`)
#+build windows
package test_issue_7547

import testing "core:testing"
import filepath "core:path/filepath"
import fmt "core:fmt"
import os "core:os"
import win32 "core:sys/windows"
import log "core:log"
import time "core:time"

@(test)
test_issue_7547 :: proc(t: ^testing.T) {
	// Test first that `os.remove_all` works at all to avoid false positives.
	root, root_error := os.make_directory_temp("", "odin-issue-7547-*", context.temp_allocator)
	if root_error != nil {
		testing.fail_now(t, "could not create temporary directory")
	}
	defer os.remove_all(root)
	tree, tree_error := filepath.join({root, "tree"}, context.temp_allocator)
	if tree_error != nil {
		testing.fail_now(t, "could not construct tree directory path")
	}
	nested, nested_error := filepath.join({tree, "nested"}, context.temp_allocator)
	if nested_error != nil {
		testing.fail_now(t, "could not construct nested directory path")
	}
	if directory_error := os.make_directory_all(nested); directory_error != nil {
		testing.fail_now(t, "could not create nested directory")
	}
	leaf, leaf_error := filepath.join({nested, "file.txt"}, context.temp_allocator)
	if leaf_error != nil {
		testing.fail_now(t, "could not construct leaf file path")
	}
	if write_error := os.write_entire_file(leaf, "issue 7547\n"); write_error != nil {
		testing.fail_now(t, "could not create leaf file")
	}

	{
		err := os.remove(tree)
		testing.expect(t, err != nil, fmt.aprintf("os.remove should not have been able to delete a non-empty directory.", allocator = context.temp_allocator))
	}

	{
		remove_error := os.remove_all(tree)
		testing.expect(t, remove_error == nil, fmt.aprintf("os.remove_all failed to remove non-empty directory.", allocator = context.temp_allocator))

		// NOTE: The tree is a subdirectory of a temporary root this test keeps until it ends.
		// A temporary directory that seemed to linger was most likely another test re-creating
		// the same name: os.make_directory_temp used to draw its names from
		// context.random_generator, which the test runner seeds identically for every test.
		if os.exists(tree) {
			log.warnf("os.remove_all left the tree behind (first chance - will check again...): %v", tree)
			time.sleep(1 * time.Second)
			testing.expect(t, !os.exists(tree), fmt.aprintf("os.remove_all left the tree behind (second chance): %v", tree, allocator = context.temp_allocator))
			log.infof("Directory removal was OK after a short delay: %v", tree)
		}
	}
}

// On Windows, os.remove_all used to hand its converted path to SHFileOperationW,
// which reads a double-NUL-terminated path list. The conversion produced a
// single terminator, so the shell operation scanned past the buffer until it
// found a zero u16 somewhere behind it — undefined behaviour that surfaced as
// a returned error, a fatal access violation, or a livelock once the scan
// left the arena block. Fresh arena memory is zero-filled, which hid the
// scan from small isolated programs; this test drives the thread's core:os
// temporary arena and the heap through enough churn, on the test runner's
// worker thread, to place converted paths in front of recycled non-zero
// bytes, which is how the crash manifested in real test suites.
// os.remove_all no longer calls SHFileOperationW or builds a double-NUL path
// list; it walks the tree with FindFirstFileW/FindNextFileW. The test remains
// as a stress test of that walk under the same allocator churn.
@(test)
test_issue_7547_dirty :: proc(t: ^testing.T) {
	base, base_error := os.make_directory_temp("", "odin-issue-7547-*", context.temp_allocator)
	if base_error != nil {
		testing.fail_now(t, "could not create temporary directory")
	}
	defer os.remove_all(base)

	pointers := make_dynamic_array_len_cap([dynamic]string, 0, 2000, context.allocator)
	defer {
		for p in pointers {
			delete(p, context.allocator)
		}
		delete(pointers)
	}

	for iteration in 0..<64 {
		root, root_error := os.make_directory_temp(base, "odin-issue-7547-*", context.allocator)
		if root_error != nil {
			testing.fail_now(t, "could not create temporary directory")
		}
		append(&pointers, root)
		nested, nested_error := filepath.join({root, "nested"}, context.allocator)
		if nested_error != nil {
			testing.fail_now(t, "could not construct nested directory path")
		}
		append(&pointers, nested)
		if directory_error := os.make_directory_all(nested); directory_error != nil {
			testing.fail_now(t, fmt.tprintf("could not create nested directory %v on iteration %v: %v", nested, iteration, directory_error))
		}
		leaf, leaf_error := filepath.join({nested, "file.txt"}, context.allocator)
		if leaf_error != nil {
			testing.fail_now(t, "could not construct leaf file path")
		}
		append(&pointers, leaf)
		if write_error := os.write_entire_file(leaf, "issue 7547\n"); write_error != nil {
			testing.fail_now(t, "could not create leaf file")
		}

		// Grow and recycle both allocators with path-shaped data so the
		// temporary arena has handed back, and the heap has reused,
		// non-zero memory behind the arena's current position.
		for scale in 0..<8 {
			garbage := fmt.aprintf("C:\\%s\\%d", root, scale*iteration, allocator=context.allocator)
			_, _ = os.lstat(garbage, context.allocator)
			delete(garbage, context.allocator)
		}

		remove_error := os.remove_all(root)
		testing.expect(t, remove_error == nil, fmt.aprintf("os.remove_all failed on iteration %d", iteration, allocator=context.temp_allocator))

		// NOTE: Each iteration's directory lives inside a temporary root this test keeps until it ends.
		// A temporary directory that seemed to linger was most likely another test re-creating
		// the same name: os.make_directory_temp used to draw its names from
		// context.random_generator, which the test runner seeds identically for every test.
		if os.exists(root) {
			log.warnf("os.remove_all left the tree behind on iteration %v (first chance - will check again...): %v", iteration, root)
			time.sleep(1 * time.Second)
			testing.expect(t, !os.exists(root), fmt.aprintf("os.remove_all left the tree behind on iteration %v (second chance): %v", iteration, root, allocator = context.temp_allocator))
			log.infof("Directory removal was OK after a short delay: %v", root)
		}
	}
}

@(test)
test_issue_7547_missing :: proc(t: ^testing.T) {
	root := make_root(t)
	defer os.remove_all(root)

	missing, missing_error := filepath.join({root, "missing", "deeper"}, context.temp_allocator)
	testing.expect_value(t, missing_error, nil)
	testing.expect_value(t, os.remove_all(missing), nil)
	testing.expect(t, os.exists(root))
}

@(test)
test_issue_7547_file :: proc(t: ^testing.T) {
	root := make_root(t)
	defer os.remove_all(root)

	leaf, leaf_error := filepath.join({root, "file.txt"}, context.temp_allocator)
	testing.expect_value(t, leaf_error, nil)
	testing.expect_value(t, os.write_entire_file(leaf, "issue 7547\n"), nil)

	testing.expect_value(t, os.remove_all(leaf), nil)
	testing.expect(t, !os.exists(leaf))
	testing.expect(t, os.exists(root))
}

@(test)
test_issue_7547_read_only :: proc(t: ^testing.T) {
	root := make_root(t)
	defer os.remove_all(root)
	tree := join(root, "tree")
	nested := join(tree, "nested")
	testing.expect_value(t, os.make_directory_all(nested), nil)

	for name in ([]string{"a.txt", "b.txt", "c.txt", "d.txt"}) {
		leaf := join(nested, name)
		testing.expect_value(t, os.write_entire_file(leaf, "issue 7547\n"), nil)
		testing.expect(t, bool(win32.SetFileAttributesW(win32.utf8_to_wstring(leaf, context.temp_allocator), win32.FILE_ATTRIBUTE_READONLY)))
	}

	testing.expect_value(t, os.remove_all(tree), nil)
	testing.expect(t, !os.exists(tree))
}

@(test)
test_issue_7547_long_path :: proc(t: ^testing.T) {
	root := make_root(t)
	defer os.remove_all(root)
	tree := join(root, "tree")

	deepest := tree
	for _ in 0..<16 {
		deepest = join(deepest, "abcdefghijklmnopqrstuvwxyz")
	}
	testing.expect(t, len(deepest) > win32.MAX_PATH)

	if directory_error := os.make_directory_all(deepest); directory_error != nil {
		testing.fail_now(t, fmt.tprintf("could not create a directory tree deeper than MAX_PATH: %v", directory_error))
	}
	testing.expect_value(t, os.write_entire_file(join(deepest, "file.txt"), "issue 7547\n"), nil)

	testing.expect_value(t, os.remove_all(tree), nil)
	testing.expect(t, !os.exists(tree))
}

@(test)
test_issue_7547_junction :: proc(t: ^testing.T) {
	root := make_root(t)
	defer os.remove_all(root)
	outside := join(root, "outside")
	testing.expect_value(t, os.make_directory(outside), nil)
	kept := join(outside, "kept.txt")
	testing.expect_value(t, os.write_entire_file(kept, "issue 7547\n"), nil)

	tree := join(root, "tree")
	testing.expect_value(t, os.make_directory(tree), nil)
	link := join(tree, "link")
	testing.expect_value(t, os.make_directory(link), nil)
	if !make_junction(link, outside) {
		testing.fail_now(t, "could not create a directory junction")
	}
	testing.expect(t, os.exists(join(link, "kept.txt")))

	testing.expect_value(t, os.remove_all(tree), nil)
	testing.expect(t, !os.exists(tree))
	testing.expect(t, os.exists(kept))
}

@(test)
test_issue_7547_junction_root :: proc(t: ^testing.T) {
	root := make_root(t)
	defer os.remove_all(root)
	target := join(root, "target")
	testing.expect_value(t, os.make_directory(target), nil)
	kept := join(target, "kept.txt")
	testing.expect_value(t, os.write_entire_file(kept, "issue 7547\n"), nil)

	link := join(root, "link")
	testing.expect_value(t, os.make_directory(link), nil)
	if !make_junction(link, target) {
		testing.fail_now(t, "could not create a directory junction")
	}

	testing.expect_value(t, os.remove_all(link), nil)
	testing.expect(t, !os.exists(link))
	testing.expect(t, os.exists(kept))

	testing.expect_value(t, os.make_directory(link), nil)
	if !make_junction(link, target) {
		testing.fail_now(t, "could not create a directory junction")
	}
	testing.expect_value(t, os.remove_all(fmt.tprintf(`%s\`, link)), nil)
	testing.expect(t, !os.exists(link))
	testing.expect(t, os.exists(kept))
}

@(test)
test_issue_7547_read_only_directory :: proc(t: ^testing.T) {
	root := make_root(t)
	defer os.remove_all(root)
	tree := join(root, "tree")
	nested := join(tree, "nested", "empty")
	testing.expect_value(t, os.make_directory_all(nested), nil)
	testing.expect_value(t, os.write_entire_file(join(tree, "nested", "file.txt"), "issue 7547\n"), nil)

	for path in ([]string{nested, filepath.dir(nested), tree}) {
		testing.expect(t, bool(win32.SetFileAttributesW(win32.utf8_to_wstring(path, context.temp_allocator), win32.FILE_ATTRIBUTE_READONLY)))
	}

	testing.expect(t, os.remove(nested) == nil)
	testing.expect_value(t, os.make_directory(nested), nil)
	testing.expect(t, bool(win32.SetFileAttributesW(win32.utf8_to_wstring(nested, context.temp_allocator), win32.FILE_ATTRIBUTE_READONLY)))

	testing.expect(t, os.remove(tree) != nil)
	attributes := win32.GetFileAttributesW(win32.utf8_to_wstring(tree, context.temp_allocator))
	testing.expect(t, attributes != win32.INVALID_FILE_ATTRIBUTES && attributes & win32.FILE_ATTRIBUTE_READONLY != 0)

	testing.expect_value(t, os.remove_all(tree), nil)
	testing.expect(t, !os.exists(tree))
}

@(test)
test_issue_7547_locked :: proc(t: ^testing.T) {
	root := make_root(t)
	defer os.remove_all(root)
	tree := join(root, "tree")
	nested := join(tree, "nested")
	testing.expect_value(t, os.make_directory_all(nested), nil)
	locked := join(nested, "locked.txt")
	testing.expect_value(t, os.write_entire_file(locked, "issue 7547\n"), nil)
	sibling := join(tree, "sibling.txt")
	testing.expect_value(t, os.write_entire_file(sibling, "issue 7547\n"), nil)

	handle := win32.CreateFileW(win32.utf8_to_wstring(locked, context.temp_allocator), win32.GENERIC_READ, win32.FILE_SHARE_READ, nil, win32.OPEN_EXISTING, 0, nil)
	if handle == win32.INVALID_HANDLE_VALUE {
		testing.fail_now(t, "could not open the file to lock it")
	}

	testing.expect(t, os.remove_all(tree) != nil)
	testing.expect(t, os.exists(locked))
	testing.expect(t, !os.exists(sibling))

	win32.CloseHandle(handle)
	testing.expect_value(t, os.remove_all(tree), nil)
	testing.expect(t, !os.exists(tree))
}

@(test)
test_issue_7547_invalid_utf16 :: proc(t: ^testing.T) {
	root := make_root(t)
	defer os.remove_all(root)
	tree := join(root, "tree")
	testing.expect_value(t, os.make_directory(tree), nil)
	tree_utf16 := win32.utf8_to_utf16(tree, context.temp_allocator)

	directory := wide_join(tree_utf16, 'd', 0xD800)
	nested := wide_join(directory, 0xDC00, 'n')
	testing.expect(t, bool(win32.CreateDirectoryW(cstring16(raw_data(directory)), nil)))
	testing.expect(t, bool(win32.CreateDirectoryW(cstring16(raw_data(nested)), nil)))

	for file in ([][]u16{wide_join(tree_utf16, 0xDFFF), wide_join(directory, 'f', 0xD800, 'f'), wide_join(nested, 0xDBFF)}) {
		handle := win32.CreateFileW(cstring16(raw_data(file)), win32.GENERIC_WRITE, 0, nil, win32.CREATE_NEW, win32.FILE_ATTRIBUTE_NORMAL, nil)
		testing.expect(t, handle != win32.INVALID_HANDLE_VALUE)
		win32.CloseHandle(handle)
		testing.expect(t, win32.GetFileAttributesW(cstring16(raw_data(file))) != win32.INVALID_FILE_ATTRIBUTES)
	}

	testing.expect_value(t, os.remove_all(tree), nil)
	testing.expect(t, !os.exists(tree))
}

wide_join :: proc(parent: []u16, name: ..u16) -> []u16 {
	path := make([]u16, len(parent) + 1 + len(name) + 1, context.temp_allocator)
	copy(path, parent)
	path[len(parent)] = '\\'
	copy(path[len(parent) + 1:], name)
	return path[:len(path) - 1]
}

make_root :: proc(t: ^testing.T, loc := #caller_location) -> string {
	root, root_error := os.make_directory_temp("", "odin-issue-7547-*", context.temp_allocator)
	if root_error != nil {
		testing.fail_now(t, "could not create temporary directory", loc)
	}
	return root
}

join :: proc(elems: ..string) -> string {
	path, _ := filepath.join(elems, context.temp_allocator)
	return path
}

make_junction :: proc(link, target: string) -> bool {
	substitute := win32.utf8_to_utf16(fmt.tprintf(`\??\%s`, target), context.temp_allocator)
	if len(substitute) == 0 {
		return false
	}

	buffer: [win32.MAXIMUM_REPARSE_DATA_BUFFER_SIZE]u8
	header_size := size_of(win32.REPARSE_DATA_BUFFER)
	names_offset := header_size + int(offset_of(win32.MOUNT_POINT_REPARSE_BUFFER, PathBuffer))
	names_size := (len(substitute) + 2) * size_of(u16)
	if names_offset + names_size > len(buffer) {
		return false
	}

	header := (^win32.REPARSE_DATA_BUFFER)(&buffer[0])
	mount_point := (^win32.MOUNT_POINT_REPARSE_BUFFER)(&buffer[header_size])
	names := ([^]u16)(&buffer[names_offset])
	copy(names[:len(substitute)], substitute)
	mount_point.SubstituteNameOffset = 0
	mount_point.SubstituteNameLength = u16(len(substitute) * size_of(u16))
	mount_point.PrintNameOffset = u16((len(substitute) + 1) * size_of(u16))
	mount_point.PrintNameLength = 0
	header.ReparseTag = win32.IO_REPARSE_TAG_MOUNT_POINT
	header.ReparseDataLength = u16(names_offset - header_size + names_size)

	handle := win32.CreateFileW(
		win32.utf8_to_wstring(link, context.temp_allocator),
		win32.GENERIC_WRITE,
		0,
		nil,
		win32.OPEN_EXISTING,
		win32.FILE_FLAG_BACKUP_SEMANTICS | win32.FILE_FLAG_OPEN_REPARSE_POINT,
		nil,
	)
	if handle == win32.INVALID_HANDLE_VALUE {
		return false
	}
	defer win32.CloseHandle(handle)

	returned: win32.DWORD
	return bool(win32.DeviceIoControl(handle, win32.FSCTL_SET_REPARSE_POINT, &buffer[0], win32.DWORD(names_offset + names_size), nil, 0, &returned, nil))
}
