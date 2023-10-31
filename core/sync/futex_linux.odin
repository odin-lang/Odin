//+private
//+build linux
package sync

import "core:time"
import "core:sys/linux"

_futex_wait :: proc "contextless" (futex: ^Futex, expected: u32) -> bool {
	errno := linux.futex(cast(^linux.Futex) futex, linux.FUTEX_WAIT, {.PRIVATE}, expected)
	if errno == .ETIMEDOUT {
		return false
	}
	#partial switch errno {
	case .NONE, .EINTR, .EAGAIN:
		return true
	case:
		// TODO(flysand): More descriptive panic messages based on the vlaue of `errno`
		_panic("futex_wait failure")
	}
}

_futex_wait_with_timeout :: proc "contextless" (futex: ^Futex, expected: u32, duration: time.Duration) -> bool {
	if duration <= 0 {
		return false
	}
	errno := linux.futex(cast(^linux.Futex) futex, linux.FUTEX_WAIT, {.PRIVATE}, expected, &linux.Time_Spec{
		time_sec  = cast(uint)(duration/1e9),
		time_nsec = cast(uint)(duration%1e9),
	})
	if errno == .ETIMEDOUT {
		return false
	}
	#partial switch errno {
	case .NONE, .EINTR, .EAGAIN:
		return true
	case:
		_panic("futex_wait_with_timeout failure")
	}
}

_futex_signal :: proc "contextless" (futex: ^Futex) {
	_, errno := linux.futex(cast(^linux.Futex) futex, linux.FUTEX_WAKE, {.PRIVATE}, 1)
	#partial switch errno {
	case .NONE:
		return
	case:
		_panic("futex_wake_single failure")
	}
}

_futex_broadcast :: proc "contextless" (futex: ^Futex)  {
	// NOTE(flysand): This code was kinda funny and I don't want to remove it, but here I will
	// record history of what has been in here before
	//     FUTEX_WAKE_PRIVATE | FUTEX_WAKE
	_, errno := linux.futex(cast(^linux.Futex) futex, linux.FUTEX_WAKE, {.PRIVATE}, max(i32))
	#partial switch errno {
	case .NONE:
		return
	case:
		_panic("_futex_wake_all failure")
	}
}
