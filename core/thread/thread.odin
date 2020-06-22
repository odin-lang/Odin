package thread

import "core:runtime"

Thread_Proc :: #type proc(^Thread);

Thread :: struct {
	using specific:   Thread_Os_Specific,
	procedure:        Thread_Proc,
	data:             rawptr,
	user_index:       int,

	init_context: Maybe(runtime.Context),
}

#assert(size_of(Thread{}.user_index) == size_of(uintptr));


run :: proc(fn: proc(), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal) {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc())t.data;
		fn();
		destroy(t);
	}
	t := create(thread_proc, priority);
	t.data = rawptr(fn);
	t.init_context = init_context;
	start(t);
}


run_with_data :: proc(fn: proc(data: rawptr), data: rawptr, init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal) {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc(rawptr))t.data;
		data := rawptr(uintptr(t.user_index));
		fn(data);
		destroy(t);
	}
	t := create(thread_proc, priority);
	t.data = rawptr(fn);
	t.user_index = int(uintptr(data));
	t.init_context = init_context;
	start(t);
}


run_with_thread_proc :: proc(fn: Thread_Proc, init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal) {
	t := create(fn, priority);
	t.init_context = init_context;
	start(t);
}
