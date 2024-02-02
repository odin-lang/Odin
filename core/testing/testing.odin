package testing

import "core:fmt"
import "core:io"
import "core:time"
import "base:intrinsics"
import "core:reflect"

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
}

T :: struct {
	error_count: int,

	w: io.Writer,

	cleanups: [dynamic]Internal_Cleanup,

	_fail_now: proc() -> !,
}


error :: proc(t: ^T, args: ..any, loc := #caller_location) {
	fmt.wprintf(t.w, "%v: ", loc)
	fmt.wprintln(t.w, ..args)
	t.error_count += 1
}

errorf :: proc(t: ^T, format: string, args: ..any, loc := #caller_location) {
	fmt.wprintf(t.w, "%v: ", loc)
	fmt.wprintf(t.w, format, ..args)
	fmt.wprintln(t.w)
	t.error_count += 1
}

fail :: proc(t: ^T, loc := #caller_location) {
	error(t, "FAIL", loc=loc)
	t.error_count += 1
}

fail_now :: proc(t: ^T, msg := "", loc := #caller_location) {
	if msg != "" {
		error(t, "FAIL:", msg, loc=loc)
	} else {
		error(t, "FAIL", loc=loc)
	}
	t.error_count += 1
	if t._fail_now != nil {
		t._fail_now()
	}
}

failed :: proc(t: ^T) -> bool {
	return t.error_count != 0
}

log :: proc(t: ^T, args: ..any, loc := #caller_location) {
	fmt.wprintln(t.w, ..args)
}

logf :: proc(t: ^T, format: string, args: ..any, loc := #caller_location) {
	fmt.wprintf(t.w, format, ..args)
	fmt.wprintln(t.w)
}


// cleanup registers a procedure and user_data, which will be called when the test, and all its subtests, complete
// cleanup procedures will be called in LIFO (last added, first called) order.
cleanup :: proc(t: ^T, procedure: proc(rawptr), user_data: rawptr) {
	append(&t.cleanups, Internal_Cleanup{procedure, user_data})
}

expect :: proc(t: ^T, ok: bool, msg: string = "", loc := #caller_location) -> bool {
	if !ok {
		error(t, msg, loc=loc)
	}
	return ok
}

expectf :: proc(t: ^T, ok: bool, format: string, args: ..any, loc := #caller_location) -> bool {
	if !ok {
		errorf(t, format, ..args, loc=loc)
	}
	return ok
}

expect_value :: proc(t: ^T, value, expected: $T, loc := #caller_location) -> bool where intrinsics.type_is_comparable(T) {
	ok := value == expected || reflect.is_nil(value) && reflect.is_nil(expected)
	if !ok {
		errorf(t, "expected %v, got %v", expected, value, loc=loc)
	}
	return ok
}


set_fail_timeout :: proc(t: ^T, duration: time.Duration, loc := #caller_location) {
	_fail_timeout(t, duration, loc)
}
