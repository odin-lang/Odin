//+private
//+build freebsd
package sync

import "core:c"
import "core:time"

UMTX_OP_WAIT :: 2
UMTX_OP_WAKE :: 3

ETIMEDOUT :: 60

foreign import libc "system:c"

foreign libc {
	_umtx_op :: proc "c" (obj: rawptr, op: c.int, val: c.ulong, uaddr: rawptr, uaddr2: rawptr) -> c.int ---
	__error :: proc "c" () -> ^c.int ---
}

_futex_wait :: proc "contextless" (f: ^Futex, expected: u32) -> bool {
	timeout := [2]i64{14400, 0} // 4 hours
	for {
		res := _umtx_op(f, UMTX_OP_WAIT, c.ulong(expected), nil, &timeout)

		if res != -1 {
			return true
		}

		if __error()^ == ETIMEDOUT {
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

	timeout := [2]i64{i64(duration/1e9), i64(duration%1e9)}

	res := _umtx_op(f, UMTX_OP_WAIT, c.ulong(expected), nil, &timeout)
	if res != -1 {
		return true
	}

	if __error()^ == ETIMEDOUT {
		return false
	}

	_panic("_futex_wait_with_timeout failure")
}

_futex_signal :: proc "contextless" (f: ^Futex) {
	res := _umtx_op(f, UMTX_OP_WAKE, 1, nil, nil)

	if res == -1 {
		_panic("_futex_signal failure")
	}
}

_futex_broadcast :: proc "contextless" (f: ^Futex)  {
	res := _umtx_op(f, UMTX_OP_WAKE, c.ulong(max(i32)), nil, nil)

	if res == -1 {
		_panic("_futex_broadcast failure")
	}
}
