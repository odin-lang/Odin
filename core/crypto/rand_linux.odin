package crypto

import "core:fmt"
import "core:os"
import "core:sys/unix"

_MAX_PER_CALL_BYTES :: 33554431 // 2^25 - 1

_rand_bytes :: proc (dst: []byte) {
	dst := dst
	l := len(dst)

	for l > 0 {
		to_read := min(l, _MAX_PER_CALL_BYTES)
		ret := unix.sys_getrandom(raw_data(dst), to_read, 0)
		if ret < 0 {
			switch os.Errno(-ret) {
			case os.EINTR:
				// Call interupted by a signal handler, just retry the
				// request.
				continue
			case os.ENOSYS:
				// The kernel is apparently prehistoric (< 3.17 circa 2014)
				// and does not support getrandom.
				panic("crypto: getrandom not available in kernel")
			case:
				// All other failures are things that should NEVER happen
				// unless the kernel interface changes (ie: the Linux
				// developers break userland).
				panic(fmt.tprintf("crypto: getrandom failed: %d", ret))
			}
		}

		l -= ret
		dst = dst[ret:]
	}
}
