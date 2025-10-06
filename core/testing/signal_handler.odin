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

@(private, thread_local)
local_test_expected_failures: struct {
	signal:         i32,

	message_count:  int,
	messages:       [MAX_EXPECTED_ASSERTIONS_PER_TEST]string,

	location_count: int,
	locations:      [MAX_EXPECTED_ASSERTIONS_PER_TEST]runtime.Source_Code_Location,
}

@(private, thread_local)
local_test_assertion_raised: struct {
	message: string,
	location: runtime.Source_Code_Location,
}

Stop_Reason :: enum {
	Unknown,
	Successful_Stop,
	Illegal_Instruction,
	Arithmetic_Error,
	Segmentation_Fault,
	Unhandled_Trap,
}

test_assertion_failure_proc :: proc(prefix, message: string, loc: runtime.Source_Code_Location) -> ! {
	if local_test_expected_failures.message_count + local_test_expected_failures.location_count > 0 {
		local_test_assertion_raised = { message, loc }
		log.debugf("%s\n\tmessage: %q\n\tlocation: %w", prefix, message, loc)
	} else {
		log.fatalf("%s: %s", prefix, message, location = loc)
	}
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
