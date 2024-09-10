//+private
//+build !windows
//+build !linux
//+build !darwin
//+build !freebsd
//+build !openbsd
//+build !netbsd
//+build !haiku
package testing

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Feoramund:   Total rewrite.
*/

_setup_signal_handler :: proc() {
	// Do nothing.
}

_setup_task_signal_handler :: proc(test_index: int) {
	// Do nothing.
}

_should_stop_runner :: proc() -> bool {
	return false
}

_should_stop_test :: proc() -> (test_index: int, reason: Stop_Reason, ok: bool) {
	return 0, {}, false
}
