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
import "core:terminal/ansi"

import win32 "core:sys/windows"


@(private="file") stop_runner_flag: int

@(private="file") stop_test_gate:   sync.Mutex
@(private="file") stop_test_index:  int
@(private="file") stop_test_signal: Exception_Code
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
Exception_Code :: enum win32.DWORD {
	Datatype_Misalignment     = win32.EXCEPTION_DATATYPE_MISALIGNMENT,
	Breakpoint                = win32.EXCEPTION_BREAKPOINT,
	Single_Step               = win32.EXCEPTION_SINGLE_STEP,
	Access_Violation          = win32.EXCEPTION_ACCESS_VIOLATION,
	In_Page_Error             = win32.EXCEPTION_IN_PAGE_ERROR,
	Illegal_Instruction       = win32.EXCEPTION_ILLEGAL_INSTRUCTION,
	Noncontinuable_Exception  = win32.EXCEPTION_NONCONTINUABLE_EXCEPTION,
	Invaild_Disposition       = win32.EXCEPTION_INVALID_DISPOSITION,
	Array_Bounds_Exceeded     = win32.EXCEPTION_ARRAY_BOUNDS_EXCEEDED,
	FLT_Denormal_Operand      = win32.EXCEPTION_FLT_DENORMAL_OPERAND,
	FLT_Divide_By_Zero        = win32.EXCEPTION_FLT_DIVIDE_BY_ZERO,
	FLT_Inexact_Result        = win32.EXCEPTION_FLT_INEXACT_RESULT,
	FLT_Invalid_Operation     = win32.EXCEPTION_FLT_INVALID_OPERATION,
	FLT_Overflow              = win32.EXCEPTION_FLT_OVERFLOW,
	FLT_Stack_Check           = win32.EXCEPTION_FLT_STACK_CHECK,
	FLT_Underflow             = win32.EXCEPTION_FLT_UNDERFLOW,
	INT_Divide_By_Zero        = win32.EXCEPTION_INT_DIVIDE_BY_ZERO,
	INT_Overflow              = win32.EXCEPTION_INT_OVERFLOW,
	PRIV_Instruction          = win32.EXCEPTION_PRIV_INSTRUCTION,
	Stack_Overflow            = win32.EXCEPTION_STACK_OVERFLOW,
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
	code := Exception_Code(info.ExceptionRecord.ExceptionCode)

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

		// This is an attempt at being compliant by avoiding printf.
		expbuf: [8]byte
		expstr: string
		{
			expnum := cast(int)code
			i := len(expbuf) - 2
			for expnum > 0 {
				m := expnum % 10
				expnum /= 10
				expbuf[i] = cast(u8)('0' + m)
				i -= 1
			}
			expstr = cast(string)expbuf[1 + i:len(expbuf) - 1]
		}

		advisory_a := `
The test runner's main thread has caught an unrecoverable error (signal `
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
			case libc.SIGILL:  passed = code == .Illegal_Instruction
			case libc.SIGSEGV: passed = code == .Access_Violation
			case libc.SIGFPE:
				#partial switch code {
				case .FLT_Denormal_Operand ..= .INT_Overflow:
					passed = true
				}
			}
		}
		intrinsics.atomic_store(&stop_test_passed, passed)
		intrinsics.atomic_store(&stop_test_alert, 1)

	}

	// Pass on the exeption to the next handler. As we don't wont to recover from it.
	// This will allow debuggers handle it properly.
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
			#partial switch intrinsics.atomic_load(&stop_test_signal) {
			case .Illegal_Instruction:      reason = .Illegal_Instruction
			case .Access_Violation:         reason = .Segmentation_Fault
			case .Breakpoint, .Single_Step: reason = .Unhandled_Trap

			case .FLT_Denormal_Operand ..= .INT_Overflow:
				reason = .Arithmetic_Error
			}
		}
		ok = true
	}

	return
}

