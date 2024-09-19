#+private
package testing

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Feoramund:   Total rewrite.
*/

import "base:runtime"
import "core:log"

Stop_Reason :: enum {
	Unknown,
	Illegal_Instruction,
	Arithmetic_Error,
	Segmentation_Fault,
	Unhandled_Trap,
}

test_assertion_failure_proc :: proc(prefix, message: string, loc: runtime.Source_Code_Location) -> ! {
	log.fatalf("%s: %s", prefix, message, location = loc)
	runtime.trap()
}

setup_signal_handler :: proc() {
	_setup_signal_handler()
}

setup_task_signal_handler :: proc(test_index: int) {
	_setup_task_signal_handler(test_index)
}

should_stop_runner :: proc() -> bool {
	return _should_stop_runner()
}

should_stop_test :: proc() -> (test_index: int, reason: Stop_Reason, ok: bool) {
	return _should_stop_test()
}
