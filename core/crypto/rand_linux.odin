package crypto

import "core:fmt"

import "core:sys/linux"

HAS_RAND_BYTES :: true

@(private)
_MAX_PER_CALL_BYTES :: 33554431 // 2^25 - 1

@(private)
_rand_bytes :: proc (dst: []byte) {
	dst := dst
	l := len(dst)

	for l > 0 {
		to_read := min(l, _MAX_PER_CALL_BYTES)
		n_read, errno := linux.getrandom(dst[:to_read], {})
		#partial switch errno {
		case .NONE:
			// Do nothing
		case .EINTR:
			// Call interupted by a signal handler, just retry the
			// request.
			continue
		case .ENOSYS:
			// The kernel is apparently prehistoric (< 3.17 circa 2014)
			// and does not support getrandom.
			panic("crypto: getrandom not available in kernel")
		case:
			// All other failures are things that should NEVER happen
			// unless the kernel interface changes (ie: the Linux
			// developers break userland).
			fmt.panicf("crypto: getrandom failed: %v", errno)
		}
		l -= n_read
		dst = dst[n_read:]
	}
}
