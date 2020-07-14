package thread

import "core:runtime"
import "core:sync"
import win32 "core:sys/windows"

Thread_Os_Specific :: struct {
	win32_thread:    win32.HANDLE,
	win32_thread_id: win32.DWORD,
	done: bool, // see note in `is_done`
}


Thread_Priority :: enum {
	Normal,
	Low,
	High,
}

_thread_priority_map := [Thread_Priority]i32{
	.Normal = 0,
	.Low = -2,
	.High = +2,
};

create :: proc(procedure: Thread_Proc, priority := Thread_Priority.Normal) -> ^Thread {
	win32_thread_id: win32.DWORD;

	__windows_thread_entry_proc :: proc "stdcall" (t_: rawptr) -> win32.DWORD {
		t := (^Thread)(t_);
		context = runtime.default_context();
		c := context;
		if ic, ok := t.init_context.?; ok {
			c = ic;
		}
		context = c;

		t.procedure(t);

		if t.init_context == nil {
			if context.temp_allocator.data == &runtime.global_default_temp_allocator_data {
				runtime.default_temp_allocator_destroy(auto_cast context.temp_allocator.data);
			}
		}

		sync.atomic_store(&t.done, true, .Sequentially_Consistent);
		return 0;
	}


	thread := new(Thread);

	win32_thread := win32.CreateThread(nil, 0, __windows_thread_entry_proc, thread, win32.CREATE_SUSPENDED, &win32_thread_id);
	if win32_thread == nil {
		free(thread);
		return nil;
	}
	thread.procedure       = procedure;
	thread.win32_thread    = win32_thread;
	thread.win32_thread_id = win32_thread_id;
	thread.init_context = context;

	ok := win32.SetThreadPriority(win32_thread, _thread_priority_map[priority]);
	assert(ok == true);

	return thread;
}

start :: proc(using thread: ^Thread) {
	win32.ResumeThread(win32_thread);
}

is_done :: proc(using thread: ^Thread) -> bool {
	// NOTE(tetra, 2019-10-31): Apparently using wait_for_single_object and
	// checking if it didn't time out immediately, is not good enough,
	// so we do it this way instead.
	return sync.atomic_load(&done, .Sequentially_Consistent);
}

join :: proc(using thread: ^Thread) {
	if win32_thread != win32.INVALID_HANDLE {
		win32.WaitForSingleObject(win32_thread, win32.INFINITE);
		win32.CloseHandle(win32_thread);
		win32_thread = win32.INVALID_HANDLE;
	}
}

join_multiple :: proc(threads: ..^Thread) {
	MAXIMUM_WAIT_OBJECTS :: 64;

	handles: [MAXIMUM_WAIT_OBJECTS]win32.HANDLE;

	for k := 0; k < len(threads); k += MAXIMUM_WAIT_OBJECTS {
		count := min(len(threads) - k, MAXIMUM_WAIT_OBJECTS);
		n, j := u32(0), 0;
		for i in 0..<count {
			handle := threads[i+k].win32_thread;
			if handle != win32.INVALID_HANDLE {
				handles[j] = handle;
				j += 1;
			}
		}
		win32.WaitForMultipleObjects(n, &handles[0], true, win32.INFINITE);
	}

	for t in threads {
		win32.CloseHandle(t.win32_thread);
		t.win32_thread = win32.INVALID_HANDLE;
	}
}

destroy :: proc(thread: ^Thread) {
	join(thread);
	free(thread);
}

terminate :: proc(using thread : ^Thread, exit_code: u32) {
	win32.TerminateThread(win32_thread, exit_code);
}

yield :: proc() {
	win32.SwitchToThread();
}

