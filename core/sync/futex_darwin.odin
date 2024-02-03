//+private
//+build darwin
package sync

import "core:c"
import "core:time"

foreign import System "system:System.framework"

foreign System {
	// __ulock_wait is not available on 10.15
	// See https://github.com/odin-lang/Odin/issues/1959
	__ulock_wait  :: proc "c" (operation: u32, addr: rawptr, value: u64, timeout_us: u32) -> c.int ---
	__ulock_wake  :: proc "c" (operation: u32, addr: rawptr, wake_value: u64) -> c.int ---
}


UL_COMPARE_AND_WAIT :: 1
ULF_WAKE_ALL        :: 0x00000100
ULF_NO_ERRNO        :: 0x01000000

ENOENT    :: -2
EINTR     :: -4
EFAULT    :: -14
ETIMEDOUT :: -60

_futex_wait :: proc "contextless" (f: ^Futex, expected: u32) -> bool {
	return _futex_wait_with_timeout(f, expected, 0)
}

_futex_wait_with_timeout :: proc "contextless" (f: ^Futex, expected: u32, duration: time.Duration) -> bool {
	timeout_ns := u32(duration) * 1000
	
	s := __ulock_wait(UL_COMPARE_AND_WAIT | ULF_NO_ERRNO, f, u64(expected), timeout_ns)
	if s >= 0 {
		return true
	}
	switch s {
	case EINTR, EFAULT:
		return true
	case ETIMEDOUT:
		return false
	case:
		_panic("futex_wait failure")
	}
	return true

}

_futex_signal :: proc "contextless" (f: ^Futex) {
	loop: for {
		s := __ulock_wake(UL_COMPARE_AND_WAIT | ULF_NO_ERRNO, f, 0)
		if s >= 0 {
			return
		}
		switch s {
		case EINTR, EFAULT: 
			continue loop
		case ENOENT:
			return
		case:
			_panic("futex_wake_single failure")
		}
	}
}

_futex_broadcast :: proc "contextless" (f: ^Futex) {
	loop: for {
		s := __ulock_wake(UL_COMPARE_AND_WAIT | ULF_NO_ERRNO | ULF_WAKE_ALL, f, 0)
		if s >= 0 {
			return
		}
		switch s {
		case EINTR, EFAULT: 
			continue loop
		case ENOENT:
			return
		case:
			_panic("futex_wake_all failure")
		}
	}
}

