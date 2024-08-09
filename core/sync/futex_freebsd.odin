//+private
//+build freebsd
package sync

import "core:c"
import "core:sys/freebsd"
import "core:time"

_futex_wait :: proc "contextless" (f: ^Futex, expected: u32) -> bool {
	timeout := freebsd.timespec {14400, 0} // 4 hours
	timeout_size := cast(rawptr)cast(uintptr)size_of(timeout)

	for {
		errno := freebsd._umtx_op(f, .WAIT_UINT, cast(c.ulong)expected, timeout_size, &timeout)

		if errno == nil {
			return true
		}

		if errno == .ETIMEDOUT {
			continue
		}

		_panic("_futex_wait failure")
	}

	unreachable()
}

_futex_wait_with_timeout :: proc "contextless" (f: ^Futex, expected: u32, duration: time.Duration) -> bool {
	if duration <= 0 {
		return false
	}

	timeout := freebsd.timespec {cast(freebsd.time_t)duration / 1e9, cast(c.long)duration % 1e9}
	timeout_size := cast(rawptr)cast(uintptr)size_of(timeout)

	errno := freebsd._umtx_op(f, .WAIT_UINT, cast(c.ulong)expected, timeout_size, &timeout)
	if errno == nil {
		return true
	}

	if errno == .ETIMEDOUT {
		return false
	}

	_panic("_futex_wait_with_timeout failure")
}

_futex_signal :: proc "contextless" (f: ^Futex) {
	errno := freebsd._umtx_op(f, .WAKE, 1, nil, nil)

	if errno != nil {
		_panic("_futex_signal failure")
	}
}

_futex_broadcast :: proc "contextless" (f: ^Futex)  {
	errno := freebsd._umtx_op(f, .WAKE, cast(c.ulong)max(i32), nil, nil)

	if errno != nil {
		_panic("_futex_broadcast failure")
	}
}
