package testing

import "base:intrinsics"
import "base:runtime"
import pkg_log "core:log"
import "core:reflect"
import "core:sync/chan"
import "core:time"

_ :: reflect // alias reflect to nothing to force visibility for -vet

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


@(deprecated="prefer `log.error`")
error :: proc(t: ^T, args: ..any, loc := #caller_location) {
	pkg_log.error(..args, location = loc)
}

@(deprecated="prefer `log.errorf`")
errorf :: proc(t: ^T, format: string, args: ..any, loc := #caller_location) {
	pkg_log.errorf(format, ..args, location = loc)
}

fail :: proc(t: ^T, loc := #caller_location) {
	pkg_log.error("FAIL", location=loc)
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
		pkg_log.error("FAIL:", msg, location=loc)
	} else {
		pkg_log.error("FAIL", location=loc)
	}
	runtime.trap()
}

failed :: proc(t: ^T) -> bool {
	return t.error_count != 0
}

@(deprecated="prefer `log.info`")
log :: proc(t: ^T, args: ..any, loc := #caller_location) {
	pkg_log.info(..args, location = loc)
}

@(deprecated="prefer `log.infof`")
logf :: proc(t: ^T, format: string, args: ..any, loc := #caller_location) {
	pkg_log.infof(format, ..args, location = loc)
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

expect :: proc(t: ^T, ok: bool, msg: string = "", loc := #caller_location) -> bool {
	if !ok {
		pkg_log.error(msg, location=loc)
	}
	return ok
}

expectf :: proc(t: ^T, ok: bool, format: string, args: ..any, loc := #caller_location) -> bool {
	if !ok {
		pkg_log.errorf(format, ..args, location=loc)
	}
	return ok
}

expect_value :: proc(t: ^T, value, expected: $T, loc := #caller_location) -> bool where intrinsics.type_is_comparable(T) {
	ok := value == expected || reflect.is_nil(value) && reflect.is_nil(expected)
	if !ok {
		pkg_log.errorf("expected %v, got %v", expected, value, location=loc)
	}
	return ok
}


set_fail_timeout :: proc(t: ^T, duration: time.Duration, loc := #caller_location) {
	chan.send(t.channel, Event_Set_Fail_Timeout {
		at_time = time.time_add(time.now(), duration),
		location = loc,
	})
}
