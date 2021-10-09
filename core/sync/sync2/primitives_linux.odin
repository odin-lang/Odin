//+build linux
//+private
package sync2

import "core:intrinsics"

_current_thread_id :: proc "contextless" () -> int {
	SYS_GETTID :: 186
	return int(intrinsics.syscall(SYS_GETTID))
}
