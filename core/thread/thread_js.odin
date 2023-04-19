//+build js
package thread

import "core:intrinsics"
import "core:sync"
import "core:mem"

Thread_State :: enum u8 {
	Started,
	Joined,
	Done,
}

Thread_Os_Specific :: struct {
	flags:       bit_set[Thread_State; u8],
}

_thread_priority_map := [Thread_Priority]i32{
	.Normal = 0,
	.Low = -2,
	.High = +2,
}

_create :: proc(procedure: Thread_Proc, priority := Thread_Priority.Normal) -> ^Thread {
	unimplemented("core:thread procedure not supported on js target")
}

_start :: proc(t: ^Thread) {
	unimplemented("core:thread procedure not supported on js target")
}

_is_done :: proc(t: ^Thread) -> bool {
	unimplemented("core:thread procedure not supported on js target")
}

_join :: proc(t: ^Thread) {
	unimplemented("core:thread procedure not supported on js target")
}

_join_multiple :: proc(threads: ..^Thread) {
	unimplemented("core:thread procedure not supported on js target")
}

_destroy :: proc(thread: ^Thread) {
	unimplemented("core:thread procedure not supported on js target")
}

_terminate :: proc(using thread : ^Thread, exit_code: int) {
	unimplemented("core:thread procedure not supported on js target")
}

_yield :: proc() {
	unimplemented("core:thread procedure not supported on js target")
}

