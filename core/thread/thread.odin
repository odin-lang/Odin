package thread

import "core:runtime"
import "core:sync"
import "core:mem"
import "intrinsics"

_ :: intrinsics;

Thread_Proc :: #type proc(^Thread);

MAX_USER_ARGUMENTS :: 8;

Thread :: struct {
	using specific: Thread_Os_Specific,
	procedure:      Thread_Proc,
	data:           rawptr,
	user_index:     int,
	user_args:      [MAX_USER_ARGUMENTS]rawptr,

	init_context: Maybe(runtime.Context),


	creation_allocator: mem.Allocator,
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
		assert(t.user_index >= 1);
		data := t.user_args[0];
		fn(data);
		destroy(t);
	}
	t := create(thread_proc, priority);
	t.data = rawptr(fn);
	t.user_index = 1;
	t.user_args = data;
	t.init_context = init_context;
	start(t);
}

run_with_poly_data :: proc(data: $T, fn: proc(data: T), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal)
	where intrinsics.type_is_pointer(T) || size_of(T) == size_of(rawptr) {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc(rawptr))t.data;
		assert(t.user_index >= 1);
		data := t.user_args[0];
		fn(data);
		destroy(t);
	}
	t := create(thread_proc, priority);
	t.data = rawptr(fn);
	t.user_index = 1;
	t.user_args[0] = transmute(rawptr)data;
	t.init_context = init_context;
	start(t);
}

run_with_poly_data2 :: proc(arg1: $T1, arg2: $T2, fn: proc(T1, T2), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal)
	where intrinsics.type_is_pointer(T1) || size_of(T1) == size_of(rawptr),
	      intrinsics.type_is_pointer(T2) || size_of(T2) == size_of(rawptr) {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc(rawptr, rawptr))t.data;
		assert(t.user_index >= 2);
		fn(t.user_args[0], t.user_args[1]);
		destroy(t);
	}
	t := create(thread_proc, priority);
	t.data = rawptr(fn);
	t.user_index = 2;
	t.user_args[0] = transmute(rawptr)arg1;
	t.user_args[1] = transmute(rawptr)arg2;
	t.init_context = init_context;
	start(t);
}

run_with_poly_data3 :: proc(arg1: $T1, arg2: $T2, arg3: $T3, fn: proc(arg1: T1, arg2: T2, arg3: T3), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal)
	where intrinsics.type_is_pointer(T1) || size_of(T1) == size_of(rawptr),
	      intrinsics.type_is_pointer(T2) || size_of(T2) == size_of(rawptr),
	      intrinsics.type_is_pointer(T3) || size_of(T3) == size_of(rawptr) {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc(rawptr, rawptr, rawptr))t.data;
		assert(t.user_index >= 3);
		fn(t.user_args[0], t.user_args[1], t.user_args[2]);
		destroy(t);
	}
	t := create(thread_proc, priority);
	t.data = rawptr(fn);
	t.user_index = 3;
	t.user_args[0] = transmute(rawptr)arg1;
	t.user_args[1] = transmute(rawptr)arg2;
	t.user_args[2] = transmute(rawptr)arg3;
	t.init_context = init_context;
	start(t);
}
run_with_poly_data4 :: proc(arg1: $T1, arg2: $T2, arg3: $T3, arg4: $T4, fn: proc(arg1: T1, arg2: T2, arg3: T3, arg4: T4), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal)
	where intrinsics.type_is_pointer(T1) || size_of(T1) == size_of(rawptr),
	      intrinsics.type_is_pointer(T2) || size_of(T2) == size_of(rawptr),
	      intrinsics.type_is_pointer(T3) || size_of(T3) == size_of(rawptr) {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc(rawptr, rawptr, rawptr))t.data;
		assert(t.user_index >= 3);
		fn(t.user_args[0], t.user_args[1], t.user_args[2]);
		destroy(t);
	}
	t := create(thread_proc, priority);
	t.data = rawptr(fn);
	t.user_index = 3;
	t.user_args[0] = transmute(rawptr)arg1;
	t.user_args[1] = transmute(rawptr)arg2;
	t.user_args[2] = transmute(rawptr)arg3;
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
