package rand

import "core:sys/unix"

_system_random :: proc() -> u32 {
	for {
		value: u32
		ret := unix.sys_getrandom(([^]u8)(&value), 4, 0)
		if ret < 0 {
			switch ret {
			case -4: // EINTR
				// Call interupted by a signal handler, just retry the request.
				continue
			case -38: // ENOSYS
				// The kernel is apparently prehistoric (< 3.17 circa 2014)
				// and does not support getrandom.
				panic("getrandom not available in kernel")
			case:
				// All other failures are things that should NEVER happen
				// unless the kernel interface changes (ie: the Linux
				// developers break userland).
				panic("getrandom failed")
			}
		}
		return value
	}
}