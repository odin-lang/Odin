// Tests issue #7547 https://github.com/odin-lang/Odin/issues/7547
package test_issues

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:testing"

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
test_issue_7547 :: proc(t: ^testing.T) {
	when ODIN_OS == .Windows {
		for iteration in 0..<64 {
			root, root_error := os.make_directory_temp("", "odin-issue-7547-*", context.allocator)
			if root_error != nil {
				testing.fail_now(t, "could not create temporary directory")
			}
			nested, nested_error := filepath.join({root, "nested"}, context.allocator)
			if nested_error != nil {
				testing.fail_now(t, "could not construct nested directory path")
			}
			if directory_error := os.make_directory_all(nested); directory_error != nil {
				testing.fail_now(t, "could not create nested directory")
			}
			leaf, leaf_error := filepath.join({nested, "file.txt"}, context.allocator)
			if leaf_error != nil {
				testing.fail_now(t, "could not construct leaf file path")
			}
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
}
