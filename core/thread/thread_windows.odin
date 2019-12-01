package thread

import "core:sync"
import "core:sys/win32"

Thread_Os_Specific :: struct {
	win32_thread:    win32.Handle,
	win32_thread_id: u32,
	done: bool, // see note in `is_done`
}

THREAD_PRIORITY_IDLE   :: -15;
THREAD_PRIORITY_LOWEST :: -2;
THREAD_PRIORITY_BELOW_NORMAL :: -1;
THREAD_PRIORITY_NORMAL :: 0;
THREAD_PRIORITY_ABOVE_NORMAL :: 1;
THREAD_PRIORITY_HIGHEST :: 2;
THREAD_PRIORITY_TIME_CRITICAL :: 15;

Thread_Priority :: enum i32 {
	Normal = THREAD_PRIORITY_NORMAL,
	Low = THREAD_PRIORITY_LOWEST,
	High = THREAD_PRIORITY_HIGHEST,
}

create :: proc(procedure: Thread_Proc, priority := Thread_Priority.Normal) -> ^Thread {
	win32_thread_id: u32;

	__windows_thread_entry_proc :: proc "c" (t: ^Thread) -> i32 {
		c := context;
		if t.use_init_context {
			c = t.init_context;
		}
		context = c;

		t.procedure(t);
		sync.atomic_store(&t.done, true, .Sequentially_Consistent);
		return 0;
	}


	win32_thread_proc := rawptr(__windows_thread_entry_proc);
	thread := new(Thread);

	win32_thread := win32.create_thread(nil, 0, win32_thread_proc, thread, win32.CREATE_SUSPENDED, &win32_thread_id);
	if win32_thread == nil {
		free(thread);
		return nil;
	}
	thread.procedure       = procedure;
	thread.win32_thread    = win32_thread;
	thread.win32_thread_id = win32_thread_id;

	ok := win32.set_thread_priority(win32_thread, i32(priority));
	assert(ok == true);

	return thread;
}

start :: proc(using thread: ^Thread) {
	win32.resume_thread(win32_thread);
}

is_done :: proc(using thread: ^Thread) -> bool {
	// NOTE(tetra, 2019-10-31): Apparently using wait_for_single_object and
	// checking if it didn't time out immediately, is not good enough,
	// so we do it this way instead.
	return sync.atomic_load(&done, .Sequentially_Consistent);
}

join :: proc(using thread: ^Thread) {
	win32.wait_for_single_object(win32_thread, win32.INFINITE);
	win32.close_handle(win32_thread);
	win32_thread = win32.INVALID_HANDLE;
}

destroy :: proc(thread: ^Thread) {
	join(thread);
	free(thread);
}

terminate :: proc(using thread : ^Thread, exit_code : u32) {
	win32.terminate_thread(win32_thread, exit_code);
}