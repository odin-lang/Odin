#+private
package runtime

import "base:intrinsics"

SYS_getthrid :: uintptr(299)

_get_current_thread_id :: proc "contextless" () -> int {
	result, _ := intrinsics.syscall_bsd(SYS_getthrid)
	return int(result)
}
