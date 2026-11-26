#+build linux, darwin, netbsd, openbsd, freebsd
#+private
package testing

import "core:c/libc"
import "core:sys/posix"

__setup_signal_handler :: proc() {
	libc.signal(posix.SIGTRAP, stop_test_callback)
}

// Called on the test's thread, in the signal handler, before the runner is
// told to stop it. Task threads cancel asynchronously (core:thread), so the
// runner's `pthread_cancel` can act through its signal while
// `pthread_testcancel` below is already unwinding the thread: the unwinder's
// one-time initialisation in libgcc_s is then entered again from that
// signal's handler, and the thread waits for ever on itself, with the runner
// joining it. Only `pthread_cancel`, `pthread_setcancelstate` and
// `pthread_setcanceltype` may run while cancellation is asynchronous.
// Deferred, the cancellation acts only at a cancellation point, here
// `pthread_testcancel`.
_test_thread_defer_cancel :: proc "contextless" () {
	posix.pthread_setcanceltype(.DEFERRED, nil)
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
