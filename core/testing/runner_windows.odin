//+private
//+build windows
package testing

import win32 "core:sys/windows"
import "base:runtime"
import "base:intrinsics"
import "core:time"

Sema :: struct {
	count: i32,
}

sema_reset :: proc "contextless" (s: ^Sema) {
	intrinsics.atomic_store(&s.count, 0)
}
sema_wait :: proc "contextless" (s: ^Sema) {
	for {
		original_count := s.count
		for original_count == 0 {
			win32.WaitOnAddress(&s.count, &original_count, size_of(original_count), win32.INFINITE)
			original_count = s.count
		}
		if original_count == intrinsics.atomic_compare_exchange_strong(&s.count, original_count-1, original_count) {
			return
		}
	}
}
sema_wait_with_timeout :: proc "contextless" (s: ^Sema, duration: time.Duration) -> bool {	
	if duration <= 0 {
		return false
	}
	for {
	
		original_count := intrinsics.atomic_load(&s.count)
		for start := time.tick_now(); original_count == 0; /**/ {
			if intrinsics.atomic_load(&s.count) != original_count {
				remaining := duration - time.tick_since(start)
				if remaining < 0 {
					return false
				}
				ms := u32(remaining/time.Millisecond)
				if !win32.WaitOnAddress(&s.count, &original_count, size_of(original_count), ms) {
					return false
				}
			}
			original_count = s.count
		}
		if original_count == intrinsics.atomic_compare_exchange_strong(&s.count, original_count-1, original_count) {
			return true
		}
	}
}

sema_post :: proc "contextless" (s: ^Sema, count := 1) {
	intrinsics.atomic_add(&s.count, i32(count))
	if count == 1 {
		win32.WakeByAddressSingle(&s.count)
	} else {
		win32.WakeByAddressAll(&s.count)
	}
}



Thread_Proc :: #type proc(^Thread)

MAX_USER_ARGUMENTS :: 8

Thread :: struct {
	using specific: Thread_Os_Specific,
	procedure:      Thread_Proc,

	t:       ^T,
	it:      Internal_Test,
	success: bool,

	init_context: Maybe(runtime.Context),

	creation_allocator: runtime.Allocator,
	
	internal_fail_timeout: time.Duration,
	internal_fail_timeout_loc: runtime.Source_Code_Location,
}

Thread_Os_Specific :: struct {
	win32_thread:    win32.HANDLE,
	win32_thread_id: win32.DWORD,
	done: bool, // see note in `is_done`
}

thread_create :: proc(procedure: Thread_Proc) -> ^Thread {
	__windows_thread_entry_proc :: proc "system" (t_: rawptr) -> win32.DWORD {
		t := (^Thread)(t_)
		context = t.init_context.? or_else runtime.default_context()

		t.procedure(t)

		if t.init_context == nil {
			if context.temp_allocator.data == &runtime.global_default_temp_allocator_data {
				runtime.default_temp_allocator_destroy(auto_cast context.temp_allocator.data)
			}
		}

		intrinsics.atomic_store(&t.done, true)
		return 0
	}


	thread := new(Thread)
	if thread == nil {
		return nil
	}
	thread.creation_allocator = context.allocator

	win32_thread_id: win32.DWORD
	win32_thread := win32.CreateThread(nil, 0, __windows_thread_entry_proc, thread, win32.CREATE_SUSPENDED, &win32_thread_id)
	if win32_thread == nil {
		free(thread, thread.creation_allocator)
		return nil
	}
	thread.procedure       = procedure
	thread.win32_thread    = win32_thread
	thread.win32_thread_id = win32_thread_id
	thread.init_context = context

	return thread
}

thread_start :: proc "contextless" (thread: ^Thread) {
	win32.ResumeThread(thread.win32_thread)
}

thread_join_and_destroy :: proc(thread: ^Thread) {
	if thread.win32_thread != win32.INVALID_HANDLE {
		win32.WaitForSingleObject(thread.win32_thread, win32.INFINITE)
		win32.CloseHandle(thread.win32_thread)
		thread.win32_thread = win32.INVALID_HANDLE
	}
	free(thread, thread.creation_allocator)
}

thread_terminate :: proc "contextless" (thread: ^Thread, exit_code: int) {
	win32.TerminateThread(thread.win32_thread, u32(exit_code))
}


_fail_timeout :: proc(t: ^T, duration: time.Duration, loc := #caller_location) {
	assert(global_fail_timeout_thread == nil, "set_fail_timeout previously called", loc)
	
	thread := thread_create(proc(thread: ^Thread) {
		t := thread.t
		timeout := thread.internal_fail_timeout
		if !sema_wait_with_timeout(&global_fail_timeout_semaphore, timeout) {
			fail_now(t, "TIMEOUT", thread.internal_fail_timeout_loc)
		}
	})
	thread.internal_fail_timeout = duration
	thread.internal_fail_timeout_loc = loc
	thread.t = t
	global_fail_timeout_thread = thread
	thread_start(thread)
}

global_fail_timeout_thread: ^Thread
global_fail_timeout_semaphore: Sema

global_threaded_runner_semaphore: Sema
global_exception_handler: rawptr
global_current_thread: ^Thread
global_current_t: ^T

run_internal_test :: proc(t: ^T, it: Internal_Test) {
	thread := thread_create(proc(thread: ^Thread) {
		exception_handler_proc :: proc "system" (ExceptionInfo: ^win32.EXCEPTION_POINTERS) -> win32.LONG {
			switch ExceptionInfo.ExceptionRecord.ExceptionCode {
			case
				win32.EXCEPTION_DATATYPE_MISALIGNMENT,
				win32.EXCEPTION_BREAKPOINT,
				win32.EXCEPTION_ACCESS_VIOLATION,
				win32.EXCEPTION_ILLEGAL_INSTRUCTION,
				win32.EXCEPTION_ARRAY_BOUNDS_EXCEEDED,
				win32.EXCEPTION_STACK_OVERFLOW:

				sema_post(&global_threaded_runner_semaphore)
				return win32.EXCEPTION_EXECUTE_HANDLER
			}

			return win32.EXCEPTION_CONTINUE_SEARCH
		}
		global_exception_handler = win32.AddVectoredExceptionHandler(0, exception_handler_proc)
		
		context.assertion_failure_proc = proc(prefix, message: string, loc: runtime.Source_Code_Location) -> ! {
			errorf(global_current_t, "%s %s", prefix, message, loc=loc)
			intrinsics.trap()
		}
		
		t := thread.t

		global_fail_timeout_thread = nil
		sema_reset(&global_fail_timeout_semaphore)
		
		thread.it.p(t)
		
		sema_post(&global_fail_timeout_semaphore)
		if global_fail_timeout_thread != nil do thread_join_and_destroy(global_fail_timeout_thread)
		
		thread.success = true
		sema_post(&global_threaded_runner_semaphore)
	})

	sema_reset(&global_threaded_runner_semaphore)
	global_current_t = t

	t._fail_now = proc() -> ! {
		intrinsics.trap()
	}

	thread.t = t
	thread.it = it
	thread.success = false
	thread_start(thread)

	sema_wait(&global_threaded_runner_semaphore)
	thread_terminate(thread, int(!thread.success))
	thread_join_and_destroy(thread)

	win32.RemoveVectoredExceptionHandler(global_exception_handler)

	if !thread.success && t.error_count == 0 {
		t.error_count += 1
	}

	return
}
