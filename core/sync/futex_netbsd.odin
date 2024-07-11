//+private
package sync

import "base:intrinsics"
import "core:time"
import "core:c"
import "core:sys/unix"

foreign import libc "system:c"

FUTEX_PRIVATE_FLAG :: 128

FUTEX_WAIT_PRIVATE :: 0 | FUTEX_PRIVATE_FLAG
FUTEX_WAKE_PRIVATE :: 1 | FUTEX_PRIVATE_FLAG

EINTR     :: 4		/* Interrupted system call */
EAGAIN    :: 35		/* Resource temporarily unavailable */
ETIMEDOUT :: 60		/* Operation timed out */

Time_Spec :: struct {
	time_sec:  uint,
	time_nsec: uint,
}

get_last_error :: proc "contextless" () -> int {
	foreign libc {
		__errno :: proc() -> ^c.int ---
	}
	return int(__errno()^)
}

_futex_wait :: proc "contextless" (futex: ^Futex, expected: u32) -> bool {
	if error, ok := intrinsics.syscall_bsd(unix.SYS___futex, uintptr(futex), FUTEX_WAIT_PRIVATE, uintptr(expected), 0, 0, 0); !ok {
		switch error {
		case EINTR, EAGAIN:
			return true
		case:
			_panic("futex_wait failure")
		}	
	}
	return true
}

_futex_wait_with_timeout :: proc "contextless" (futex: ^Futex, expected: u32, duration: time.Duration) -> bool {
	if duration <= 0 {
		return false
	}
	if error, ok := intrinsics.syscall_bsd(unix.SYS___futex, uintptr(futex), FUTEX_WAIT_PRIVATE, uintptr(expected), cast(uintptr) &Time_Spec{
		time_sec  = cast(uint)(duration / 1e9),
		time_nsec = cast(uint)(duration % 1e9),
	}, 0, 0); !ok {
		switch error {
		case EINTR, EAGAIN:
			return true
		case ETIMEDOUT:
			return false
		case:
			_panic("futex_wait_with_timeout failure")
		}
	}
	return true
}

_futex_signal :: proc "contextless" (futex: ^Futex) {
	if _, ok := intrinsics.syscall_bsd(unix.SYS___futex, uintptr(futex), FUTEX_WAKE_PRIVATE, 1, 0, 0, 0); !ok {
		_panic("futex_wake_single failure")
	}
}

_futex_broadcast :: proc "contextless" (futex: ^Futex)  {
	if _, ok := intrinsics.syscall_bsd(unix.SYS___futex, uintptr(futex), FUTEX_WAKE_PRIVATE, uintptr(max(i32)), 0, 0, 0); !ok {
		_panic("_futex_wake_all failure")
	}
}
