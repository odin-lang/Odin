package thread

import "core:runtime"
import "core:sync"
import "core:sys/win32"

Thread_Os_Specific :: struct {
	win32_thread:    win32.Handle,
	win32_thread_id: u32,
	done: bool, // see note in `is_done`
}


Thread_Priority :: enum {
	Normal,
	Low,
	High,
}

_thread_priority_map := map[Thread_Priority]i32{
	.Normal = 0,
	.Low = -2,
	.High = +2,
};

create :: proc(procedure: Thread_Proc, priority := Thread_Priority.Normal) -> ^Thread {
	win32_thread_id: u32;

	__windows_thread_entry_proc :: proc "c" (t: ^Thread) -> i32 {
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
	thread.init_context = context;

	ok := win32.set_thread_priority(win32_thread, _thread_priority_map[priority]);
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
	if win32_thread != win32.INVALID_HANDLE {
		win32.wait_for_single_object(win32_thread, win32.INFINITE);
		win32.close_handle(win32_thread);
		win32_thread = win32.INVALID_HANDLE;
	}
}

destroy :: proc(thread: ^Thread) {
	join(thread);
	free(thread);
}

terminate :: proc(using thread : ^Thread, exit_code : u32) {
	win32.terminate_thread(win32_thread, exit_code);
}

yield :: proc() {
	win32.sleep(0);
}
