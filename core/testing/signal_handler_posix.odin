#+build linux, darwin, netbsd, openbsd, freebsd
#+private
package testing

import "core:c/libc"
import "core:sys/posix"

__setup_signal_handler :: proc() {
	libc.signal(posix.SIGTRAP, stop_test_callback)
}

_test_thread_cancel :: proc "contextless" () {
	// NOTE(Feoramund): Some UNIX-like platforms may require this.
	//
	// During testing, I found that NetBSD 10.0 refused to
	// terminate a task thread, even when its thread had been
	// properly set to PTHREAD_CANCEL_ASYNCHRONOUS.
	//
	// The runner would stall after returning from `pthread_cancel`.

	posix.pthread_testcancel()
}
