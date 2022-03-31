//+private
//+build linux
package sync

import "core:c"
import "core:time"
import "core:intrinsics"
import "core:sys/unix"

FUTEX_WAIT :: 0
FUTEX_WAKE :: 1
FUTEX_PRIVATE_FLAG :: 128

FUTEX_WAIT_PRIVATE :: (FUTEX_WAIT | FUTEX_PRIVATE_FLAG)
FUTEX_WAKE_PRIVATE :: (FUTEX_WAKE | FUTEX_PRIVATE_FLAG)

ESUCCESS  :: 0
EINTR     :: -4
EAGAIN    :: -11
EFAULT    :: -14
EINVAL    :: -22
ETIMEDOUT :: -110

get_errno :: proc(r: int) -> int {
	if -4096 < r && r < 0 {
		return r
	}
	return 0
}

internal_futex :: proc(f: ^Futex, op: c.int, val: u32, timeout: rawptr) -> int {
	code := int(intrinsics.syscall(unix.SYS_futex, uintptr(f), uintptr(op), uintptr(val), uintptr(timeout), 0, 0))
	return get_errno(code)
}


_futex_wait :: proc(f: ^Futex, expected: u32) -> bool {
	err := internal_futex(f, FUTEX_WAIT_PRIVATE | FUTEX_WAIT, expected, nil)
	switch err {
	case ESUCCESS, EINTR, EAGAIN, EINVAL:
		// okay
	case ETIMEDOUT:
		return false
	case EFAULT: 
		fallthrough
	case:
		panic("futex_wait failure")
	}
	return true
}

_futex_wait_with_timeout :: proc(f: ^Futex, expected: u32, duration: time.Duration) -> bool {
	if duration <= 0 {
		return false
	}
	
	timespec_t :: struct {
		tv_sec:  c.long,
		tv_nsec: c.long,
	}
	
	err := internal_futex(f, FUTEX_WAIT_PRIVATE | FUTEX_WAIT, expected, &timespec_t{
		tv_sec  = (c.long)(duration/1e9),
		tv_nsec = (c.long)(duration%1e9),
	})
	switch err {
	case ESUCCESS, EINTR, EAGAIN, EINVAL:
		// okay
	case ETIMEDOUT:
		return false
	case EFAULT: 
		fallthrough
	case:
		panic("futex_wait_with_timeout failure")
	}
	return true
}


_futex_signal :: proc(f: ^Futex) {
	err := internal_futex(f, FUTEX_WAKE_PRIVATE | FUTEX_WAKE, 1, nil)
	switch err {
	case ESUCCESS, EINVAL, EFAULT:
		// okay
	case:
		panic("futex_wake_single failure")
	}
}
_futex_broadcast :: proc(f: ^Futex)  {
	err := internal_futex(f, FUTEX_WAKE_PRIVATE | FUTEX_WAKE, u32(max(i32)), nil)
	switch err {
	case ESUCCESS, EINVAL, EFAULT:
		// okay
	case:
		panic("_futex_wake_all failure")
	}
}
