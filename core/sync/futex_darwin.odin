//+private
//+build darwin
package sync

import "core:c"
import "core:sys/darwin"
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
	when darwin.WAIT_ON_ADDRESS_AVAILABLE {
		s: i32
		if duration > 0 {
			s = darwin.os_sync_wait_on_address_with_timeout(f, u64(expected), size_of(Futex), {}, .MACH_ABSOLUTE_TIME, u64(duration))
		} else {
			s = darwin.os_sync_wait_on_address(f, u64(expected), size_of(Futex), {})
		}

		if s >= 0 {
			return true
		}

		switch darwin.errno() {
		case -EINTR, -EFAULT:
			return true
		case -ETIMEDOUT:
			return false
		case:
			_panic("darwin.os_sync_wait_on_address_with_timeout failure")
		}
	} else {

	timeout_ns := u32(duration)
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
}

_futex_signal :: proc "contextless" (f: ^Futex) {
	when darwin.WAIT_ON_ADDRESS_AVAILABLE {
		loop: for {
			s := darwin.os_sync_wake_by_address_any(f, size_of(Futex), {})
			if s >= 0 {
				return
			}
			switch darwin.errno() {
			case -EINTR, -EFAULT:
				continue loop
			case -ENOENT:
				return
			case:
				_panic("darwin.os_sync_wake_by_address_any failure")
			}
		}
	} else {

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
}

_futex_broadcast :: proc "contextless" (f: ^Futex) {
	when darwin.WAIT_ON_ADDRESS_AVAILABLE {
		loop: for {
			s := darwin.os_sync_wake_by_address_all(f, size_of(Futex), {})
			if s >= 0 {
				return
			}
			switch darwin.errno() {
			case -EINTR, -EFAULT:
				continue loop
			case -ENOENT:
				return
			case:
				_panic("darwin.os_sync_wake_by_address_all failure")
			}
		}
	} else {

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
}
