#+private
package runtime

import "base:intrinsics"

SYS__lwp_self :: uintptr(311)

_get_current_thread_id :: proc "contextless" () -> int {
	result, _ := intrinsics.syscall_bsd(SYS__lwp_self)
	return int(result)
}
