package test_internal

import "core:testing"
import "test_imported_proc_groups"

// https://github.com/odin-lang/Odin/pull/6119
@test
test_use_imported_proc_group_as_argument :: proc(t: ^testing.T) {
	use_proc :: proc(proc()) { }
	use_proc(test_imported_proc_groups.proc_group)
}
