package thread

import "core:runtime"
import "core:sync"
import "core:intrinsics"

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


run_with_data :: proc(data: rawptr, fn: proc(data: rawptr), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal) {
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


create_and_start :: proc(fn: Thread_Proc, init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal) -> ^Thread {
	t := create(fn, priority);
	t.init_context = init_context;
	start(t);
	return t;
}


Once :: struct {
	m:    sync.Blocking_Mutex,
	done: bool,
}
once_init :: proc(o: ^Once) {
	sync.blocking_mutex_init(&o.m);
	intrinsics.atomic_store_rel(&o.done, false);
}
once_destroy :: proc(o: ^Once) {
	sync.blocking_mutex_destroy(&o.m);
}

once_do :: proc(o: ^Once, fn: proc()) {
	if intrinsics.atomic_load(&o.done) == false {
		_once_do_slow(o, fn);
	}
}

_once_do_slow :: proc(o: ^Once, fn: proc()) {
	sync.blocking_mutex_lock(&o.m);
	defer sync.blocking_mutex_unlock(&o.m);
	if !o.done {
		fn();
		intrinsics.atomic_store_rel(&o.done, true);
	}
}
