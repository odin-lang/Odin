//+private
//+build linux
package sync2

import "core:c"
import "core:time"
import "core:intrinsics"

FUTEX_WAIT :: 0
FUTEX_WAKE :: 1
FUTEX_PRIVATE_FLAG :: 128

FUTEX_WAIT_PRIVATE :: (FUTEX_WAIT | FUTEX_PRIVATE_FLAG)
FUTEX_WAKE_PRIVATE :: (FUTEX_WAKE | FUTEX_PRIVATE_FLAG)

foreign import libc "system:c"

foreign libc {
	__errno_location :: proc "c" () -> ^c.int ---	
}

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
	code := int(intrinsics.syscall(202, uintptr(f), uintptr(op), uintptr(val), uintptr(timeout), 0, 0))
	return get_errno(code)
}


_futex_wait :: proc(f: ^Futex, expected: u32) -> Futex_Error {
	err := internal_futex(f, FUTEX_WAIT_PRIVATE | FUTEX_WAIT, expected, nil)
	switch err {
	case ESUCCESS, EINTR, EAGAIN, EINVAL:
		// okay
	case ETIMEDOUT:
		return .Timed_Out
	case EFAULT: 
		fallthrough
	case:
		panic("futex_wait failure")
	}
	return nil
}

_futex_wait_with_timeout :: proc(f: ^Futex, expected: u32, duration: time.Duration) -> Futex_Error {
	timespec_t :: struct {
		tv_sec:  c.long,
		tv_nsec: c.long,
	}
	
	timeout: timespec_t
	timeout_ptr: ^timespec_t = nil
	
	if duration > 0 {
		timeout.tv_sec  = (c.long)(duration/1e9)
		timeout.tv_nsec = (c.long)(duration%1e9)
		timeout_ptr = &timeout
	}

	err := internal_futex(f, FUTEX_WAIT_PRIVATE | FUTEX_WAIT, expected, &timeout)
	switch err {
	case ESUCCESS, EINTR, EAGAIN, EINVAL:
		// okay
	case ETIMEDOUT:
		return .Timed_Out
	case EFAULT: 
		fallthrough
	case:
		panic("futex_wait_with_timeout failure")
	}
	return nil
}


_futex_wake_single :: proc(f: ^Futex) {
	err := internal_futex(f, FUTEX_WAKE_PRIVATE | FUTEX_WAKE, 1, nil)
	switch err {
	case ESUCCESS, EINVAL, EFAULT:
		// okay
	case:
		panic("futex_wake_single failure")
	}
}
_futex_wake_all :: proc(f: ^Futex)  {
	err := internal_futex(f, FUTEX_WAKE_PRIVATE | FUTEX_WAKE, u32(max(i32)), nil)
	switch err {
	case ESUCCESS, EINVAL, EFAULT:
		// okay
	case:
		panic("_futex_wake_all failure")
	}
}
