package testing

import "core:fmt"
import "core:io"

// IMPORTANT NOTE: Compiler requires this layout
Test_Signature :: proc(^T);

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
}


error :: proc(t: ^T, args: ..any, loc := #caller_location) {
	log(t=t, args=args, loc=loc);
	t.error_count += 1;
}

errorf :: proc(t: ^T, format: string, args: ..any, loc := #caller_location) {
	logf(t=t, format=format, args=args, loc=loc);
	t.error_count += 1;
}

fail :: proc(t: ^T) {
	error(t, "FAIL");
	t.error_count += 1;
}

failed :: proc(t: ^T) -> bool {
	return t.error_count != 0;
}

log :: proc(t: ^T, args: ..any, loc := #caller_location) {
	fmt.wprintln(t.w, ..args);
}

logf :: proc(t: ^T, format: string, args: ..any, loc := #caller_location) {
	fmt.wprintf(t.w, format, ..args);
	fmt.wprintln(t.w);
}


// cleanup registers a procedure and user_data, which will be called when the test, and all its subtests, complete
// cleanup proceduers will be called in LIFO (last added, first called) order.
cleanup :: proc(t: ^T, procedure: proc(rawptr), user_data: rawptr) {
	append(&t.cleanups, Internal_Cleanup{procedure, user_data});
}

expect :: proc(t: ^T, ok: bool, msg: string = "", loc := #caller_location) -> bool {
	if !ok {
		error(t=t, args={msg}, loc=loc);
	}
	return ok;
}
