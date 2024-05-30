//+private
//+build !windows !linux !darwin !freebsd !openbsd !netbsd !haiku
package testing

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
