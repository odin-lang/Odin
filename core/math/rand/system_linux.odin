package rand

import "core:sys/linux"

@(require_results)
_system_random :: proc() -> u64 {
	for {
		value: u64
		value_buf := (cast([^]u8)&value)[:size_of(u64)]
		_, errno := linux.getrandom(value_buf, {})
		#partial switch errno {
		case .NONE:
			// Do nothing
		case .EINTR: 
			// Call interupted by a signal handler, just retry the request.
			continue
		case .ENOSYS: 
			// The kernel is apparently prehistoric (< 3.17 circa 2014)
			// and does not support getrandom.
			panic("getrandom not available in kernel")
		case:
			// All other failures are things that should NEVER happen
			// unless the kernel interface changes (ie: the Linux
			// developers break userland).
			panic("getrandom failed")
		}
		return value
	}
}