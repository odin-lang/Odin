//+private
//+build freebsd
package sync

import "core:c"
import "core:os"
import "core:time"

UMTX_OP_WAIT :: 2
UMTX_OP_WAKE :: 3

foreign import libc "system:c"

foreign libc {
	_umtx_op :: proc "c" (obj: rawptr, op: c.int, val: c.ulong, uaddr: rawptr, uaddr2: rawptr) -> c.int ---
}

_futex_wait :: proc(f: ^Futex, expected: u32) -> bool {
	timeout := os.Unix_File_Time{
		seconds = 5,
		nanoseconds = 0,
	}

	for {
		res := _umtx_op(f, UMTX_OP_WAIT, c.ulong(expected), nil, &timeout)

		if res != -1 {
			return true
		}

		if os.Errno(os.get_last_error()) == os.ETIMEDOUT {
			continue
		}

		panic("_futex_wait failure")
	}
	unreachable()
}

_futex_wait_with_timeout :: proc(f: ^Futex, expected: u32, duration: time.Duration) -> bool {
	if duration <= 0 {
		return false
	}

	res := _umtx_op(f, UMTX_OP_WAIT, c.ulong(expected), nil, &os.Unix_File_Time{
		seconds = (os.time_t)(duration/1e9),
		nanoseconds = (c.long)(duration%1e9),
	})

	if res != -1 {
		return true
	}

	if os.Errno(os.get_last_error()) == os.ETIMEDOUT {
		return false
	}

	panic("_futex_wait_with_timeout failure")
}

_futex_signal :: proc(f: ^Futex) {
	res := _umtx_op(f, UMTX_OP_WAKE, 1, nil, nil)

	if res == -1 {
		panic("_futex_signal failure")
	}
}

_futex_broadcast :: proc(f: ^Futex)  {
	res := _umtx_op(f, UMTX_OP_WAKE, c.ulong(max(i32)), nil, nil)

	if res == -1 {
		panic("_futex_broadcast failure")
	}
}
