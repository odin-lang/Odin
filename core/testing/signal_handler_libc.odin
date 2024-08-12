//+private
//+build windows, linux, darwin, freebsd, openbsd, netbsd, haiku
package testing

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Feoramund:   Total rewrite.
*/

import "base:intrinsics"
import "core:c/libc"
import "core:encoding/ansi"
import "core:sync"
import "core:os"
@require import "core:sys/unix"

@(private="file") stop_runner_flag: libc.sig_atomic_t

@(private="file") stop_test_gate:   sync.Mutex
@(private="file") stop_test_index:  libc.sig_atomic_t
@(private="file") stop_test_reason: libc.sig_atomic_t
@(private="file") stop_test_alert:  libc.sig_atomic_t

@(private="file", thread_local)
local_test_index: libc.sig_atomic_t

// Windows does not appear to have a SIGTRAP, so this is defined here, instead
// of in the libc package, just so there's no confusion about it being
// available there.
SIGTRAP :: 5

@(private="file")
stop_runner_callback :: proc "c" (sig: libc.int) {
	prev := intrinsics.atomic_add(&stop_runner_flag, 1)

	// If the flag was already set (if this is the second signal sent for example),
	// consider this a forced (not graceful) exit.
	if prev > 0 {
		os.exit(int(sig))
	}
}

@(private="file")
stop_test_callback :: proc "c" (sig: libc.int) {
	if local_test_index == -1 {
		// We're the test runner, and we ourselves have caught a signal from
		// which there is no recovery.
		//
		// The most we can do now is make sure the user's cursor is visible,
		// nuke the entire processs, and hope a useful core dump survives.

		// NOTE(Feoramund): Using these write calls in a signal handler is
		// undefined behavior in C99 but possibly tolerated in POSIX 2008.
		// Either way, we may as well try to salvage what we can.
		show_cursor := ansi.CSI + ansi.DECTCEM_SHOW
		libc.fwrite(raw_data(show_cursor), size_of(byte), len(show_cursor), libc.stdout)
		libc.fflush(libc.stdout)

		// This is an attempt at being compliant by avoiding printf.
		sigbuf: [8]byte
		sigstr: string
		{
			signum := cast(int)sig
			i := len(sigbuf) - 2
			for signum > 0 {
				m := signum % 10
				signum /= 10
				sigbuf[i] = cast(u8)('0' + m)
				i -= 1
			}
			sigstr = cast(string)sigbuf[1 + i:len(sigbuf) - 1]
		}

		advisory_a := `
The test runner's main thread has caught an unrecoverable error (signal `
		advisory_b := `) and will now forcibly terminate.
This is a dire bug and should be reported to the Odin developers.
`
		libc.fwrite(raw_data(advisory_a), size_of(byte), len(advisory_a), libc.stderr)
		libc.fwrite(raw_data(sigstr), size_of(byte), len(sigstr), libc.stderr)
		libc.fwrite(raw_data(advisory_b), size_of(byte), len(advisory_b), libc.stderr)

		// Try to get a core dump.
		libc.abort()
	}

	if sync.mutex_guard(&stop_test_gate) {
		intrinsics.atomic_store(&stop_test_index, local_test_index)
		intrinsics.atomic_store(&stop_test_reason, cast(libc.sig_atomic_t)sig)
		intrinsics.atomic_store(&stop_test_alert, 1)

		for {
			// Idle until this thread is terminated by the runner,
			// otherwise we may continue to generate signals.
			intrinsics.cpu_relax()

			when ODIN_OS != .Windows {
				// NOTE(Feoramund): Some UNIX-like platforms may require this.
				//
				// During testing, I found that NetBSD 10.0 refused to
				// terminate a task thread, even when its thread had been
				// properly set to PTHREAD_CANCEL_ASYNCHRONOUS.
				//
				// The runner would stall after returning from `pthread_cancel`.
			
				unix.pthread_testcancel()
			}
		}
	}
}

_setup_signal_handler :: proc() {
	local_test_index = -1

	// Catch user interrupt / CTRL-C.
	libc.signal(libc.SIGINT, stop_runner_callback)
	// Catch polite termination request.
	libc.signal(libc.SIGTERM, stop_runner_callback)

	// For tests:
	// Catch asserts and panics.
	libc.signal(libc.SIGILL, stop_test_callback)
	when ODIN_OS == .Linux || ODIN_OS == .FreeBSD || ODIN_OS == .Haiku || ODIN_OS == .OpenBSD || ODIN_OS == .NetBSD || ODIN_OS == .Darwin {
		// Catch panics on Darwin and unhandled calls to `debug_trap`.
		libc.signal(SIGTRAP, stop_test_callback)
	}
	// Catch arithmetic errors.
	libc.signal(libc.SIGFPE, stop_test_callback)
	// Catch segmentation faults (illegal memory access).
	libc.signal(libc.SIGSEGV, stop_test_callback)
}

_setup_task_signal_handler :: proc(test_index: int) {
	local_test_index = cast(libc.sig_atomic_t)test_index
}

_should_stop_runner :: proc() -> bool {
	return intrinsics.atomic_load(&stop_runner_flag) == 1
}

@(private="file")
unlock_stop_test_gate :: proc(_: int, _: Stop_Reason, ok: bool) {
	if ok {
		sync.mutex_unlock(&stop_test_gate)
	}
}

@(deferred_out=unlock_stop_test_gate)
_should_stop_test :: proc() -> (test_index: int, reason: Stop_Reason, ok: bool) {
	if intrinsics.atomic_load(&stop_test_alert) == 1 {
		intrinsics.atomic_store(&stop_test_alert, 0)

		test_index = cast(int)intrinsics.atomic_load(&stop_test_index)
		switch intrinsics.atomic_load(&stop_test_reason) {
		case libc.SIGFPE: reason = .Arithmetic_Error
		case libc.SIGILL: reason = .Illegal_Instruction
		case libc.SIGSEGV: reason = .Segmentation_Fault
		case      SIGTRAP: reason = .Unhandled_Trap
		}
		ok = true
	}

	return
}
