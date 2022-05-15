package rand

import "core:sys/darwin"

_system_random :: proc() -> u32 {
	for {
		value: u32
		ret := darwin.syscall_getentropy(([^]u8)(&value), 4)
		if ret < 0 {
			switch ret {
			case -4: // EINTR
				continue
			case -78: // ENOSYS
				panic("getentropy not available in kernel")
			case:
				panic("getentropy failed")
			}
		}
		return value
	}
}