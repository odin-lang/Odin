// Tests issue #6419 https://github.com/odin-lang/Odin/issues/6419
// A polymorphic procedure with default procedure literal parameters
// should not cause the compiler to hang.
package test_issues

import "core:testing"

// The proc that triggered the hang: polymorphic pointer param + default proc() {} params
undo_push :: proc(data: ^$T, undo_proc := proc() {}, redo_proc := proc() {}) {}

// Sanity check: non-polymorphic version still works
undo_push_int :: proc(data: ^int, undo_proc := proc() {}, redo_proc := proc() {}) {}

// Sanity check: non-polymorphic without pointer still works
undo_push_no_ptr :: proc(data: int, undo_proc := proc() {}, redo_proc := proc() {}) {}

// Sanity check: no data param at all still works
undo_push_no_data :: proc(undo_proc := proc() {}, redo_proc := proc() {}) {}

@(test)
test_issue_6419_polymorphic_default_proc_params :: proc(t: ^testing.T) {
	hey: int = 5
	undo_push(&hey)
	undo_push(&hey, proc() {}, proc() {})
	undo_push(
		&hey,
		proc() {},
		proc() {
			// non-empty body
		},
	)
}

@(test)
test_issue_6419_non_polymorphic_sanity :: proc(t: ^testing.T) {
	x: int = 10
	undo_push_int(&x)
	undo_push_no_ptr(42)
	undo_push_no_data()
}
