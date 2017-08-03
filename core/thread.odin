_ :: compile_assert(ODIN_OS == "windows");

import win32 "sys/windows.odin";

Thread :: struct {
	using specific:   Os_Specific;
	procedure:        Proc;
	data:             any;
	user_index:       int;

	init_context:     Context;
	use_init_context: bool;

	Proc :: #type proc(^Thread) -> int;
	Os_Specific :: struct {
		win32_thread:    win32.Handle;
		win32_thread_id: u32;
	}
}


create :: proc(procedure: Thread.Proc) -> ^Thread {
	win32_thread_id: u32;

	__windows_thread_entry_proc :: proc(data: rawptr) -> i32 #cc_c {
		if data	== nil do return 0;

		t := cast(^Thread)data;

		c := context;
		if t.use_init_context {
			c = t.init_context;
		}

		exit := 0;
		push_context c {
			exit = t.procedure(t);
		}

		return cast(i32)exit;
	}


	win32_thread_proc := cast(rawptr)__windows_thread_entry_proc;
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
