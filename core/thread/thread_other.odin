//+build js, wasi, orca
package thread

import "base:intrinsics"

_IS_SUPPORTED :: false

Thread_Os_Specific :: struct {}

_thread_priority_map := [Thread_Priority]i32{
	.Normal = 0,
	.Low = -2,
	.High = +2,
}

_create :: proc(procedure: Thread_Proc, priority := Thread_Priority.Normal) -> ^Thread {
	unimplemented("core:thread procedure not supported on target")
}

_start :: proc(t: ^Thread) {
	unimplemented("core:thread procedure not supported on target")
}

_is_done :: proc(t: ^Thread) -> bool {
	unimplemented("core:thread procedure not supported on target")
}

_join :: proc(t: ^Thread) {
	unimplemented("core:thread procedure not supported on target")
}

_join_multiple :: proc(threads: ..^Thread) {
	unimplemented("core:thread procedure not supported on target")
}

_destroy :: proc(thread: ^Thread) {
	unimplemented("core:thread procedure not supported on target")
}

_terminate :: proc(using thread : ^Thread, exit_code: int) {
	unimplemented("core:thread procedure not supported on target")
}

_yield :: proc() {
	unimplemented("core:thread procedure not supported on target")
}

