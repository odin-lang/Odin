package thread

import "core:runtime"
import "core:sys/win32"

Thread_Proc :: #type proc(^Thread) -> int;

Thread_Os_Specific :: struct {
	win32_thread:    win32.Handle,
	win32_thread_id: u32,
}

Thread :: struct {
	using specific:   Thread_Os_Specific,
	procedure:        Thread_Proc,
	data:             rawptr,
	user_index:       int,

	init_context:     runtime.Context,
	use_init_context: bool,
}


create :: proc(procedure: Thread_Proc) -> ^Thread {
	win32_thread_id: u32;

	__windows_thread_entry_proc :: proc "c" (t: ^Thread) -> i32 {
		c := context;
		if t.use_init_context {
			c = t.init_context;
		}
		context = c;

		return i32(t.procedure(t));
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

	return thread;
}

start :: proc(using thread: ^Thread) {
	win32.resume_thread(win32_thread);
}

is_done :: proc(using thread: ^Thread) -> bool {
	res := win32.wait_for_single_object(win32_thread, 0);
	return res != win32.WAIT_TIMEOUT;
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
