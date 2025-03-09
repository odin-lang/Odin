#+private
package runtime

import "base:intrinsics"

SYS_thr_self :: uintptr(432)

_get_current_thread_id :: proc "contextless" () -> int {
	when size_of(rawptr) == 4 {
		id: i32
	} else {
		id: i64
	}
	_, ok := intrinsics.syscall_bsd(SYS_thr_self, uintptr(&id))
	if !ok {
		panic_contextless("Failed to get current thread ID.")
	}
	return int(id)
}
