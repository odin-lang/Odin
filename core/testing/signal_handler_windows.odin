#+private
#+build windows
package testing

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's license.

	List of contributors:
		Feoramund:   Total rewrite.
		blob1807:    Windows Win32 API rewrite.
*/

import "base:runtime"
import "base:intrinsics"

import "core:os"
import "core:sync"
import "core:c/libc"
import "core:strconv"
import "core:terminal/ansi"

import win32 "core:sys/windows"


@(private="file") stop_runner_flag: int

@(private="file") stop_test_gate:   sync.Mutex
@(private="file") stop_test_index:  int
@(private="file") stop_test_signal: win32.DWORD
@(private="file") stop_test_passed: bool
@(private="file") stop_test_alert:  int


when ODIN_ARCH == .i386 {
	// Thread-local storage is problematic on Windows i386
	@(private="file")
	local_test_index: int
	@(private="file")
	local_test_index_set: bool
} else {
	@(private="file", thread_local)
	local_test_index: int
	@(private="file", thread_local)
	local_test_index_set: bool
}


@(private="file")
stop_runner_callback :: proc "system" (ctrl_type: win32.DWORD) -> win32.BOOL  {
	if ctrl_type == win32.CTRL_C_EVENT {
		prev := intrinsics.atomic_add(&stop_runner_flag, 1)

		// If the flag was already set (if this is the second signal sent for example),
		// consider this a forced (not graceful) exit.
		if prev > 0 {
			os.exit(1)
		}
		// Say we've hanndled the signal.
		return true
	}

	// This will also get called for other events which we don't handle for.
	// Instead we pass it on to the next handler.
	return false
}

@(private)
stop_test_callback :: proc "system" (info: ^win32.EXCEPTION_POINTERS) -> win32.LONG {
	if !local_test_index_set {
		// We're a thread created by a test thread.
		//
		// There's nothing we can do to inform the test runner about who
		// signalled, so hopefully the test will handle their own sub-threads.
		return win32.EXCEPTION_CONTINUE_SEARCH
	}

	context = runtime.default_context()
	code := info.ExceptionRecord.ExceptionCode

	if local_test_index == -1 {
		// We're the test runner, and we ourselves have caught a signal from
		// which there is no recovery.
		//
		// The most we can do now is make sure the user's cursor is visible,
		// nuke the entire processs, and hope a useful core dump survives.
		if !global_ansi_disabled {
			show_cursor := ansi.CSI + ansi.DECTCEM_SHOW
			os.write_string(os.stdout, show_cursor)
			os.flush(os.stdout)
		}

		expbuf: [8]byte
		expstr := strconv.write_uint(expbuf[:], cast(u64)code, 16)
		for &c in expbuf {
			if 'a' <= c && c <= 'f' {
				c -= 32
			}
		}

		advisory_a := `
The test runner's main thread has caught an unrecoverable error (exception 0x`
		advisory_b := `) and will now forcibly terminate.
This is a dire bug and should be reported to the Odin developers.
`
		os.write_string(os.stderr, advisory_a)
		os.write_string(os.stderr, expstr)
		os.write_string(os.stderr, advisory_b)
		os.flush(os.stderr)

		win32.TerminateProcess(win32.GetCurrentProcess(), 1)
	}

	if sync.mutex_guard(&stop_test_gate) {
		intrinsics.atomic_store(&stop_test_index, local_test_index)
		intrinsics.atomic_store(&stop_test_signal, code)
		passed: bool
		check_passing: {
			if location := local_test_assertion_raised.location; location != {} {
				for i in 0..<local_test_expected_failures.location_count {
					if local_test_expected_failures.locations[i] == location {
						passed = true
						break check_passing
					}
				}
			}
			if message := local_test_assertion_raised.message; message != "" {
				for i in 0..<local_test_expected_failures.message_count {
					if local_test_expected_failures.messages[i] == message {
						passed = true
						break check_passing
					}
				}
			}
			signal := local_test_expected_failures.signal
			switch signal {
			case libc.SIGILL:  passed = code == win32.EXCEPTION_ILLEGAL_INSTRUCTION
			case libc.SIGSEGV: passed = code == win32.EXCEPTION_ACCESS_VIOLATION
			case libc.SIGFPE:
				switch code {
				case win32.EXCEPTION_FLT_DENORMAL_OPERAND ..= win32.EXCEPTION_INT_OVERFLOW:
					passed = true
				}
			}
		}
		intrinsics.atomic_store(&stop_test_passed, passed)
		intrinsics.atomic_store(&stop_test_alert, 1)

	}

	// Pass on the exeption to the next handler. As we don't wont to recover from it.
	// This also allows debuggers handle it properly.
	return win32.EXCEPTION_CONTINUE_SEARCH
}

_setup_signal_handler :: proc() {
	local_test_index = -1
	local_test_index_set = true

	// Catch user interrupt / CTRL-C.
	win32.SetConsoleCtrlHandler(stop_runner_callback, win32.TRUE)

	// For tests:
	// Catch the following:
	// - Asserts and panics;
	// - Arithmetic errors; and
	// - Segmentation faults (illegal memory access).
	win32.AddVectoredExceptionHandler(0, stop_test_callback)
}

_setup_task_signal_handler :: proc(test_index: int) {
	local_test_index = test_index
	local_test_index_set = true
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

		test_index = intrinsics.atomic_load(&stop_test_index)
		if intrinsics.atomic_load(&stop_test_passed) {
			reason = .Successful_Stop
		} else {
			switch intrinsics.atomic_load(&stop_test_signal) {
			case win32.EXCEPTION_ILLEGAL_INSTRUCTION: reason = .Illegal_Instruction
			case win32.EXCEPTION_ACCESS_VIOLATION:    reason = .Segmentation_Fault
			case win32.EXCEPTION_BREAKPOINT:          reason = .Unhandled_Trap
			case win32.EXCEPTION_SINGLE_STEP:         reason = .Unhandled_Trap

			case win32.EXCEPTION_FLT_DENORMAL_OPERAND ..= win32.EXCEPTION_INT_OVERFLOW:
				reason = .Arithmetic_Error
			}
		}
		ok = true
	}

	return
}

