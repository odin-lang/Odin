package testing

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Ginger Bill: Initial implementation.
		Feoramund:   Total rewrite.
*/

import "base:intrinsics"
import "base:runtime"
import "core:log"
import "core:reflect"
import "core:sync"
import "core:sync/chan"
import "core:time"
import "core:mem"

_ :: reflect // alias reflect to nothing to force visibility for -vet
_ :: mem     // in case TRACKING_MEMORY is not enabled

MAX_EXPECTED_ASSERTIONS_PER_TEST :: 5

// IMPORTANT NOTE: Compiler requires this layout
Test_Signature :: proc(^T)

// IMPORTANT NOTE: Compiler requires this layout
Internal_Test :: struct {
	pkg:  string,
	name: string,
	p:    Test_Signature,
}


Internal_Cleanup :: struct {
	procedure: proc(rawptr),
	user_data: rawptr,
	ctx: runtime.Context,
}

T :: struct {
	error_count: int,

	// If your test needs to perform random operations, it's advised to use
	// this value to seed a local random number generator rather than relying
	// on the non-thread-safe global one.
	//
	// This way, your results will be deterministic.
	//
	// This value is chosen at startup of the test runner, logged, and may be
	// specified by the user. It is the same for all tests of a single run.
	seed: u64,

	channel: Update_Channel_Sender,

	cleanups: [dynamic]Internal_Cleanup,

	// This allocator is shared between the test runner and its threads for
	// cloning log strings, so they can outlive the lifetime of individual
	// tests during channel transmission.
	_log_allocator: runtime.Allocator,

	_fail_now_called: bool,
}


fail :: proc(t: ^T, loc := #caller_location) {
	log.error("FAIL", location=loc)
}

// fail_now will cause a test to immediately fail and abort, much in the same
// way a failed assertion or panic call will stop a thread.
//
// It is for when you absolutely need a test to fail without calling any of its
// deferred statements. It will be cleaner than a regular assert or panic,
// as the test runner will know to expect the signal this procedure will raise.
fail_now :: proc(t: ^T, msg := "", loc := #caller_location) -> ! {
	t._fail_now_called = true
	if msg != "" {
		log.error("FAIL:", msg, location=loc)
	} else {
		log.error("FAIL", location=loc)
	}
	runtime.trap()
}

failed :: proc(t: ^T) -> bool {
	return t.error_count != 0
}

// cleanup registers a procedure and user_data, which will be called when the test, and all its subtests, complete.
// Cleanup procedures will be called in LIFO (last added, first called) order.
//
// Each procedure will use a copy of the context at the time of registering,
// and if the test failed due to a timeout, failed assertion, panic, bounds-checking error,
// memory access violation, or any other signal-based fault, this procedure will
// run with greater privilege in the test runner's main thread.
//
// That means that any cleanup procedure absolutely must not fail in the same way,
// or it will take down the entire test runner with it. This is for when you
// need something to run no matter what, if a test failed.
//
// For almost every usual case, `defer` should be preferable and sufficient.
cleanup :: proc(t: ^T, procedure: proc(rawptr), user_data: rawptr) {
	append(&t.cleanups, Internal_Cleanup{procedure, user_data, context})
}

expect :: proc(t: ^T, ok: bool, msg := "", expr := #caller_expression(ok), loc := #caller_location) -> bool {
	if !ok {
		if msg == "" {
			log.errorf("expected %v to be true", expr, location=loc)
		} else {
			log.error(msg, location=loc)
		}
	}
	return ok
}

expectf :: proc(t: ^T, ok: bool, format: string, args: ..any, loc := #caller_location) -> bool {
	if !ok {
		log.errorf(format, ..args, location=loc)
	}
	return ok
}

expect_value :: proc(t: ^T, value, expected: $T, loc := #caller_location, value_expr := #caller_expression(value)) -> bool where intrinsics.type_is_comparable(T) {
	ok := value == expected || reflect.is_nil(value) && reflect.is_nil(expected)
	if !ok {
		log.errorf("expected %v to be %v, got %v", value_expr, expected, value, location=loc)
	}
	return ok
}

Memory_Verifier_Proc :: #type proc(t: ^T, ta: ^mem.Tracking_Allocator)

expect_leaks :: proc(t: ^T, client_test: proc(t: ^T), verifier: Memory_Verifier_Proc) {
	when TRACKING_MEMORY {
		client_test(t)
		ta := (^mem.Tracking_Allocator)(context.allocator.data)

		sync.mutex_lock(&ta.mutex)
		// The verifier can inspect this local tracking allocator.
		// And then call `testing.expect_*` as makes sense for the client test.
		verifier(t, ta)
		sync.mutex_unlock(&ta.mutex)

		clear(&ta.bad_free_array)
		free_all(context.allocator)
	}
}

set_fail_timeout :: proc(t: ^T, duration: time.Duration, loc := #caller_location) {
	chan.send(t.channel, Event_Set_Fail_Timeout {
		at_time = time.time_add(time.now(), duration),
		location = loc,
	})
}

/*
Let the test runner know that it should expect an assertion failure from a
specific location in the source code for this test.

In the event that an assertion fails, a debug message will be logged with its
exact message and location in a copyable format to make it convenient to write
tests which use this API.

This procedure may be called up to 5 times with different locations.

This is a limitation for the sake of simplicity in the implementation, and you
should consider breaking up your tests into smaller procedures if you need to
check for asserts in more than 2 places.
*/
expect_assert_from :: proc(t: ^T, expected_place: runtime.Source_Code_Location, caller_loc := #caller_location) {
	count := local_test_expected_failures.location_count
	if count == MAX_EXPECTED_ASSERTIONS_PER_TEST {
		panic("This test cannot handle that many expected assertions based on matching the location.", caller_loc)
	}
	local_test_expected_failures.locations[count] = expected_place
	local_test_expected_failures.location_count += 1
}

/*
Let the test runner know that it should expect an assertion failure with a
specific message for this test.

In the event that an assertion fails, a debug message will be logged with its
exact message and location in a copyable format to make it convenient to write
tests which use this API.

This procedure may be called up to 5 times with different messages.

This is a limitation for the sake of simplicity in the implementation, and you
should consider breaking up your tests into smaller procedures if you need to
check for more than a couple different assertion messages.
*/
expect_assert_message :: proc(t: ^T, expected_message: string, caller_loc := #caller_location) {
	count := local_test_expected_failures.message_count
	if count == MAX_EXPECTED_ASSERTIONS_PER_TEST {
		panic("This test cannot handle that many expected assertions based on matching the message.", caller_loc)
	}
	local_test_expected_failures.messages[count] = expected_message
	local_test_expected_failures.message_count += 1
}

expect_assert :: proc {
	expect_assert_from,
	expect_assert_message,
}

/*
Let the test runner know that it should expect a signal to be raised within
this test.

This API is for advanced users, as arbitrary signals will not be caught; only
the ones already handled by the test runner, such as

- SIGINT,                           (interrupt)
- SIGTERM,                          (polite termination)
- SIGILL,                           (illegal instruction)
- SIGFPE,                           (arithmetic error)
- SIGSEGV, and                      (segmentation fault)
- SIGTRAP (only on POSIX systems).  (trap / debug trap)

Note that only one signal can be expected per test.
*/
expect_signal :: proc(t: ^T, #any_int sig: i32) {
	local_test_expected_failures.signal = sig
}
