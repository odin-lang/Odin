// Tests issue #7547 https://github.com/odin-lang/Odin/issues/7547 (win32 implementation of `os.remove_all`)
#+build windows
package test_issues

import runtime "base:runtime"
import testing "core:testing"
import filepath "core:path/filepath"
import fmt "core:fmt"
import slice "core:slice"
import os "core:os"
import win32 "core:sys/windows"

@(test)
test_issue_7547 :: proc(t: ^testing.T) {
	// Test first that `os.remove_all` works at all to avoid false positives.
	root, root_error := os.make_directory_temp("", "odin-issue-7547-*", context.temp_allocator)
	if root_error != nil {
		testing.fail_now(t, "could not create temporary directory")
	}
	nested, nested_error := filepath.join({root, "nested"}, context.temp_allocator)
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
		err := os.remove(root)
		testing.expect(t, err != nil, fmt.aprintf("os.remove should not have been able to delete a non-empty directory.", allocator = context.temp_allocator))
	}

	{
		remove_error := os.remove_all(root)
		testing.expect(t, remove_error == nil, fmt.aprintf("os.remove_all failed to remove non-empty directory.", allocator = context.temp_allocator))
		testing.expect(t, !os.exists(root), fmt.aprintf("os.remove_all left the tree behind", allocator = context.temp_allocator))
	}
}

// On Windows, os.remove_all hands its converted path to SHFileOperationW,
// which reads a double-NUL-terminated path list. The conversion produced a
// single terminator, so the shell operation scanned past the buffer until it
// found a zero u16 somewhere behind it — undefined behaviour that surfaces as
// a returned error, a fatal access violation, or a livelock once the scan
// leaves the arena block. Fresh arena memory is zero-filled, which hides the
// scan from small isolated programs; this test drives the thread's core:os
// temporary arena and the heap through enough churn, on the test runner's
// worker thread, to place the converted path in front of recycled non-zero
// bytes, which is how the crash manifests in real test suites.
@(test)
test_issue_7547_dirty :: proc(t: ^testing.T) {
	pointers := make_dynamic_array_len_cap([dynamic]string, 0, 2000, context.allocator)
	defer {
		for p in pointers {
			delete(p, context.allocator)
		}
		delete(pointers)
	}

	for iteration in 0..<64 {
		root, root_error := os.make_directory_temp("", "odin-issue-7547-*", context.allocator)
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
			testing.fail_now(t, "could not create nested directory")
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
		testing.expect(t, !os.exists(root), fmt.aprintf("os.remove_all left the tree behind on iteration %d", iteration, allocator=context.temp_allocator))
	}
}

@(test)
test_issue_7547_internal :: proc(t: ^testing.T) {
	{
		dir, err := win32_utf8_to_pczzwstr_core("PATH")
		testing.expect_value(t, err, nil)
		testing.expect_value(t, len(dir), 6)
		testing.expect(t, slice.equal(dir, []u16{'P', 'A', 'T', 'H', 0, 0}))
	}

	{
		dir, err := win32_utf8_to_pczzwstr_core("")
		testing.expect_value(t, err, nil)
		testing.expect_value(t, len(dir), 2)
		testing.expect(t, slice.equal(dir, []u16{0, 0}))
	}

	{
		chinese_text := "你好"
		testing.expect(t, len(transmute([]u8)chinese_text) != 2)
		dir, err := win32_utf8_to_pczzwstr_core(chinese_text)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, len(dir), 4)
		testing.expect(t, slice.equal(dir, []u16{'你', '好', 0, 0}))
	}

	{
		invalid_utf8 := transmute(string)[]u8 { 0xC0, 0xAF } // overlong "/"
		dir, err := win32_utf8_to_pczzwstr_core(invalid_utf8)
		testing.expect(t, err != nil)
		testing.expect_value(t, len(dir), 0)
	}

}

// Used for `SHFILEOPSTRUCTW`, which requires double-null-terminated strings (`PCZZWSTR`).
@(private="package", require_results)
win32_utf8_to_pczzwstr_core :: proc(s: string, allocator: runtime.Allocator = context.temp_allocator) -> (ws: []u16, err: os.Error) {
	if len(s) < 1 {
		// We still need to provide a double-null-terminated empty string.
		t := make([]u16, 2, allocator) or_return
		ws = t
		return
	}

	b := transmute([]byte)s
	cstr := raw_data(b)
	n := win32.MultiByteToWideChar(win32.CP_UTF8, win32.MB_ERR_INVALID_CHARS, cstr, i32(len(s)), nil, 0)
	if n == 0 {
		err = os.Platform_Error.GEN_FAILURE
		return
	}

	text := make([]u16, n+2, allocator) or_return

	n1 := win32.MultiByteToWideChar(win32.CP_UTF8, win32.MB_ERR_INVALID_CHARS, cstr, i32(len(s)), raw_data(text), n)
	if n1 == 0 {
		err = os.Platform_Error.GEN_FAILURE
		delete(text, allocator)
		return
	}

	text[n+1] = 0
	text[n] = 0
	return text, nil
}
