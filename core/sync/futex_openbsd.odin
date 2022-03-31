//+private
//+build openbsd
package sync

import "core:c"
import "core:os"
import "core:time"

FUTEX_WAIT :: 1
FUTEX_WAKE :: 2

FUTEX_PRIVATE_FLAG :: 128

FUTEX_WAIT_PRIVATE :: (FUTEX_WAIT | FUTEX_PRIVATE_FLAG)
FUTEX_WAKE_PRIVATE :: (FUTEX_WAKE | FUTEX_PRIVATE_FLAG)

foreign import libc "system:c"

foreign libc {
	@(link_name="futex")
	_unix_futex :: proc "c" (f: ^Futex, op: c.int, val: u32, timeout: rawptr) -> c.int ---
}

_futex_wait :: proc(f: ^Futex, expected: u32) -> bool {
	res := _unix_futex(f, FUTEX_WAIT_PRIVATE, expected, nil)

	if res != -1 {
		return true
	}

	if os.Errno(os.get_last_error()) == os.ETIMEDOUT {
		return false
	}

	panic("futex_wait failure")
}

_futex_wait_with_timeout :: proc(f: ^Futex, expected: u32, duration: time.Duration) -> bool {
	if duration <= 0 {
		return false
	}

	timespec_t :: struct {
		tv_sec:  c.long,
		tv_nsec: c.long,
        }

	res := _unix_futex(f, FUTEX_WAIT_PRIVATE, expected, &timespec_t{
		tv_sec  = (c.long)(duration/1e9),
		tv_nsec = (c.long)(duration%1e9),
	})

	if res != -1 {
		return true
	}

	if os.Errno(os.get_last_error()) == os.ETIMEDOUT {
		return false
	}

	panic("futex_wait_with_timeout failure")
}

_futex_signal :: proc(f: ^Futex) {
	res := _unix_futex(f, FUTEX_WAKE_PRIVATE, 1, nil)

	if res == -1 {
		panic("futex_wake_single failure")
	}
}

_futex_broadcast :: proc(f: ^Futex)  {
	res := _unix_futex(f, FUTEX_WAKE_PRIVATE, u32(max(i32)), nil)

	if res == -1 {
		panic("_futex_wake_all failure")
	}
}
