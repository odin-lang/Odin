//+build windows
//+private
package thread

import "core:runtime"
import "core:intrinsics"
import "core:sync"
import win32 "core:sys/windows"

Thread_State :: enum u8 {
	Started,
	Joined,
	Done,
}

Thread_Os_Specific :: struct {
	win32_thread:    win32.HANDLE,
	win32_thread_id: win32.DWORD,
	mutex:           sync.Mutex,
	flags:           bit_set[Thread_State; u8],
}

_thread_priority_map := [Thread_Priority]i32{
	.Normal = 0,
	.Low = -2,
	.High = +2,
}

_create :: proc(procedure: Thread_Proc, priority := Thread_Priority.Normal) -> ^Thread {
	win32_thread_id: win32.DWORD

	__windows_thread_entry_proc :: proc "stdcall" (t_: rawptr) -> win32.DWORD {
		t := (^Thread)(t_)
		context = t.init_context.? or_else runtime.default_context()
		
		t.id = sync.current_thread_id()

		t.procedure(t)

		intrinsics.atomic_store(&t.flags, t.flags + {.Done})

		if t.init_context == nil {
			if context.temp_allocator.data == &runtime.global_default_temp_allocator_data {
				runtime.default_temp_allocator_destroy(auto_cast context.temp_allocator.data)
			}
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
	thread.init_context = context

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

	win32.WaitForSingleObject(t.win32_thread, win32.INFINITE)
	win32.CloseHandle(t.win32_thread)
	t.win32_thread = win32.INVALID_HANDLE

	t.flags += {.Joined}
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

_terminate :: proc(using thread : ^Thread, exit_code: int) {
	win32.TerminateThread(win32_thread, u32(exit_code))
}

_yield :: proc() {
	win32.SwitchToThread()
}

