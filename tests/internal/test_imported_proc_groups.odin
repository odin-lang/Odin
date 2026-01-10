package test_internal

import "core:testing"
import "test_imported_proc_groups"

@test
test_ :: proc(t: ^testing.T) {
    use_proc :: proc(proc()) { }
    use_proc(test_imported_proc_groups.proc_group)
}
