//+private
//+build windows, linux, darwin, freebsd, openbsd, netbsd, haiku
package testing

import "base:intrinsics"
import "core:c/libc"

@(private="file")
abort_flag: libc.sig_atomic_t

setup_signal_handler :: proc() {
	libc.signal(libc.SIGINT, proc "c" (sig: libc.int) {
		intrinsics.atomic_add(&abort_flag, 1)
	})
}

should_abort :: proc() -> bool {
	return intrinsics.atomic_load(&abort_flag) > 0
}
