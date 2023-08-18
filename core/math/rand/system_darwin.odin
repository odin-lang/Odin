package rand

import "core:sys/darwin"

@(require_results)
_system_random :: proc() -> u64 {
	for {
		value: u64
		ret := darwin.syscall_getentropy(([^]u8)(&value), size_of(value))
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