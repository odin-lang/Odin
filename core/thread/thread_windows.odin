//+build windows
//+private
package thread

import "base:intrinsics"
import "core:sync"
import win32 "core:sys/windows"

_IS_SUPPORTED :: true

Thread_Os_Specific :: struct {
	win32_thread:    win32.HANDLE,
	win32_thread_id: win32.DWORD,
	mutex:           sync.Mutex,
}

_thread_priority_map := [Thread_Priority]i32{
	.Normal = 0,
	.Low = -2,
	.High = +2,
}

_create :: proc(procedure: Thread_Proc, priority: Thread_Priority) -> ^Thread {
	win32_thread_id: win32.DWORD

	__windows_thread_entry_proc :: proc "system" (t_: rawptr) -> win32.DWORD {
		t := (^Thread)(t_)

		if .Joined in t.flags {
			return 0
		}

		t.id = sync.current_thread_id()

		{
			init_context := t.init_context

			// NOTE(tetra, 2023-05-31): Must do this AFTER thread.start() is called, so that the user can set the init_context, etc!
			// Here on Windows, the thread is created in a suspended state, and so we can select the context anywhere before the call
			// to t.procedure().
			context = _select_context_for_thread(init_context)
			defer _maybe_destroy_default_temp_allocator(init_context)

			t.procedure(t)
		}

		intrinsics.atomic_store(&t.flags, t.flags + {.Done})

		if .Self_Cleanup in t.flags {
			win32.CloseHandle(t.win32_thread)
			t.win32_thread = win32.INVALID_HANDLE
			// NOTE(ftphikari): It doesn't matter which context 'free' received, right?
			context = {}
			free(t, t.creation_allocator)
		}

		return 0
	}


	thread := new(Thread)
	if thread == nil {
		return nil
	}
	thread.creation_allocator = context.allocator

	win32_thread := win32.CreateThread(nil, 0, __windows_thread_entry_proc, thread, win32.CREATE_SUSPENDED, &win32_thread_id)
	if win32_thread == nil {
		free(thread, thread.creation_allocator)
		return nil
	}
	thread.procedure       = procedure
	thread.win32_thread    = win32_thread
	thread.win32_thread_id = win32_thread_id

	ok := win32.SetThreadPriority(win32_thread, _thread_priority_map[priority])
	assert(ok == true)

	return thread
}

_start :: proc(t: ^Thread) {
	sync.guard(&t.mutex)
	t.flags += {.Started}
	win32.ResumeThread(t.win32_thread)
}

_is_done :: proc(t: ^Thread) -> bool {
	// NOTE(tetra, 2019-10-31): Apparently using wait_for_single_object and
	// checking if it didn't time out immediately, is not good enough,
	// so we do it this way instead.
	return .Done in sync.atomic_load(&t.flags)
}

_join :: proc(t: ^Thread) {
	sync.guard(&t.mutex)

	if .Joined in t.flags || t.win32_thread == win32.INVALID_HANDLE {
		return
	}

	t.flags += {.Joined}

	if .Started not_in t.flags {
		t.flags += {.Started}
		win32.ResumeThread(t.win32_thread)
	}

	win32.WaitForSingleObject(t.win32_thread, win32.INFINITE)
	win32.CloseHandle(t.win32_thread)
	t.win32_thread = win32.INVALID_HANDLE
}

_join_multiple :: proc(threads: ..^Thread) {
	MAXIMUM_WAIT_OBJECTS :: 64

	handles: [MAXIMUM_WAIT_OBJECTS]win32.HANDLE

	for k := 0; k < len(threads); k += MAXIMUM_WAIT_OBJECTS {
		count := min(len(threads) - k, MAXIMUM_WAIT_OBJECTS)
		j := 0
		for i in 0..<count {
			handle := threads[i+k].win32_thread
			if handle != win32.INVALID_HANDLE {
				handles[j] = handle
				j += 1
			}
		}
		win32.WaitForMultipleObjects(u32(j), &handles[0], true, win32.INFINITE)
	}

	for t in threads {
		win32.CloseHandle(t.win32_thread)
		t.win32_thread = win32.INVALID_HANDLE
	}
}

_destroy :: proc(thread: ^Thread) {
	_join(thread)
	free(thread, thread.creation_allocator)
}

_terminate :: proc(thread: ^Thread, exit_code: int) {
	win32.TerminateThread(thread.win32_thread, u32(exit_code))
}

_yield :: proc() {
	win32.SwitchToThread()
}

