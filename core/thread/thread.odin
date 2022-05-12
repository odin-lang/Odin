package thread

import "core:runtime"
import "core:mem"
import "core:intrinsics"

_ :: intrinsics

Thread_Proc :: #type proc(^Thread)

MAX_USER_ARGUMENTS :: 8

Thread :: struct {
	using specific: Thread_Os_Specific,
	id:             int,
	procedure:      Thread_Proc,
	data:           rawptr,
	user_index:     int,
	user_args:      [MAX_USER_ARGUMENTS]rawptr,

	init_context: Maybe(runtime.Context),


	creation_allocator: mem.Allocator,
}

#assert(size_of(Thread{}.user_index) == size_of(uintptr))

Thread_Priority :: enum {
	Normal,
	Low,
	High,
}

create :: proc(procedure: Thread_Proc, priority := Thread_Priority.Normal) -> ^Thread {
	return _create(procedure, priority)
}
destroy :: proc(thread: ^Thread) {
	_destroy(thread)
}

start :: proc(thread: ^Thread) {
	_start(thread)
}

is_done :: proc(thread: ^Thread) -> bool {
	return _is_done(thread)
}


join :: proc(thread: ^Thread) {
	_join(thread)
}


join_multiple :: proc(threads: ..^Thread) {
	_join_multiple(..threads)
}

terminate :: proc(thread: ^Thread, exit_code: int) {
	_terminate(thread, exit_code)
}

yield :: proc() {
	_yield()
}



run :: proc(fn: proc(), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal) {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc())t.data
		fn()
		destroy(t)
	}
	t := create(thread_proc, priority)
	t.data = rawptr(fn)
	t.init_context = init_context
	start(t)
}

run_with_data :: proc(data: rawptr, fn: proc(data: rawptr), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal) {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc(rawptr))t.data
		assert(t.user_index >= 1)
		data := t.user_args[0]
		fn(data)
		destroy(t)
	}
	t := create(thread_proc, priority)
	t.data = rawptr(fn)
	t.user_index = 1
	t.user_args = data
	t.init_context = init_context
	start(t)
}

run_with_poly_data :: proc(data: $T, fn: proc(data: T), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal)
	where size_of(T) <= size_of(rawptr) {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc(T))t.data
		assert(t.user_index >= 1)
		data := (^T)(&t.user_args[0])^
		fn(data)
		destroy(t)
	}
	t := create(thread_proc, priority)
	t.data = rawptr(fn)
	t.user_index = 1
	data := data
	mem.copy(&t.user_args[0], &data, size_of(data))
	t.init_context = init_context
	start(t)
}

run_with_poly_data2 :: proc(arg1: $T1, arg2: $T2, fn: proc(T1, T2), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal)
	where size_of(T1) <= size_of(rawptr),
	      size_of(T2) <= size_of(rawptr) {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc(T1, T2))t.data
		assert(t.user_index >= 2)
		arg1 := (^T1)(&t.user_args[0])^
		arg2 := (^T2)(&t.user_args[1])^
		fn(arg1, arg2)
		destroy(t)
	}
	t := create(thread_proc, priority)
	t.data = rawptr(fn)
	t.user_index = 2
	arg1, arg2 := arg1, arg2
	mem.copy(&t.user_args[0], &arg1, size_of(arg1))
	mem.copy(&t.user_args[1], &arg2, size_of(arg2))
	t.init_context = init_context
	start(t)
}

run_with_poly_data3 :: proc(arg1: $T1, arg2: $T2, arg3: $T3, fn: proc(arg1: T1, arg2: T2, arg3: T3), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal)
	where size_of(T1) <= size_of(rawptr),
	      size_of(T2) <= size_of(rawptr),
	      size_of(T3) <= size_of(rawptr) {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc(T1, T2, T3))t.data
		assert(t.user_index >= 3)
		arg1 := (^T1)(&t.user_args[0])^
		arg2 := (^T2)(&t.user_args[1])^
		arg3 := (^T3)(&t.user_args[2])^
		fn(arg1, arg2, arg3)
		destroy(t)
	}
	t := create(thread_proc, priority)
	t.data = rawptr(fn)
	t.user_index = 3
	arg1, arg2, arg3 := arg1, arg2, arg3
	mem.copy(&t.user_args[0], &arg1, size_of(arg1))
	mem.copy(&t.user_args[1], &arg2, size_of(arg2))
	mem.copy(&t.user_args[2], &arg3, size_of(arg3))
	t.init_context = init_context
	start(t)
}
run_with_poly_data4 :: proc(arg1: $T1, arg2: $T2, arg3: $T3, arg4: $T4, fn: proc(arg1: T1, arg2: T2, arg3: T3, arg4: T4), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal)
	where size_of(T1) <= size_of(rawptr),
	      size_of(T2) <= size_of(rawptr),
	      size_of(T3) <= size_of(rawptr) {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc(T1, T2, T3, T4))t.data
		assert(t.user_index >= 4)
		arg1 := (^T1)(&t.user_args[0])^
		arg2 := (^T2)(&t.user_args[1])^
		arg3 := (^T3)(&t.user_args[2])^
		arg4 := (^T4)(&t.user_args[3])^
		fn(arg1, arg2, arg3, arg4)
		destroy(t)
	}
	t := create(thread_proc, priority)
	t.data = rawptr(fn)
	t.user_index = 4
	arg1, arg2, arg3, arg4 := arg1, arg2, arg3, arg4
	mem.copy(&t.user_args[0], &arg1, size_of(arg1))
	mem.copy(&t.user_args[1], &arg2, size_of(arg2))
	mem.copy(&t.user_args[2], &arg3, size_of(arg3))
	mem.copy(&t.user_args[3], &arg4, size_of(arg4))
	t.init_context = init_context
	start(t)
}



create_and_start :: proc(fn: Thread_Proc, init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal) -> ^Thread {
	t := create(fn, priority)
	t.init_context = init_context
	start(t)
	return t
}




create_and_start_with_data :: proc(data: rawptr, fn: proc(data: rawptr), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal) -> ^Thread {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc(rawptr))t.data
		assert(t.user_index >= 1)
		data := t.user_args[0]
		fn(data)
	}
	t := create(thread_proc, priority)
	t.data = rawptr(fn)
	t.user_index = 1
	t.user_args = data
	t.init_context = init_context
	start(t)
	return t
}

create_and_start_with_poly_data :: proc(data: $T, fn: proc(data: T), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal) -> ^Thread 
	where size_of(T) <= size_of(rawptr) {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc(T))t.data
		assert(t.user_index >= 1)
		data := (^T)(&t.user_args[0])^
		fn(data)
	}
	t := create(thread_proc, priority)
	t.data = rawptr(fn)
	t.user_index = 1
	data := data
	mem.copy(&t.user_args[0], &data, size_of(data))
	t.init_context = init_context
	start(t)
	return t
}

create_and_start_with_poly_data2 :: proc(arg1: $T1, arg2: $T2, fn: proc(T1, T2), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal) -> ^Thread 
	where size_of(T1) <= size_of(rawptr),
	      size_of(T2) <= size_of(rawptr) {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc(T1, T2))t.data
		assert(t.user_index >= 2)
		arg1 := (^T1)(&t.user_args[0])^
		arg2 := (^T2)(&t.user_args[1])^
		fn(arg1, arg2)
	}
	t := create(thread_proc, priority)
	t.data = rawptr(fn)
	t.user_index = 2
	arg1, arg2 := arg1, arg2
	mem.copy(&t.user_args[0], &arg1, size_of(arg1))
	mem.copy(&t.user_args[1], &arg2, size_of(arg2))
	t.init_context = init_context
	start(t)
	return t
}

create_and_start_with_poly_data3 :: proc(arg1: $T1, arg2: $T2, arg3: $T3, fn: proc(arg1: T1, arg2: T2, arg3: T3), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal) -> ^Thread 
	where size_of(T1) <= size_of(rawptr),
	      size_of(T2) <= size_of(rawptr),
	      size_of(T3) <= size_of(rawptr) {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc(T1, T2, T3))t.data
		assert(t.user_index >= 3)
		arg1 := (^T1)(&t.user_args[0])^
		arg2 := (^T2)(&t.user_args[1])^
		arg3 := (^T3)(&t.user_args[2])^
		fn(arg1, arg2, arg3)
	}
	t := create(thread_proc, priority)
	t.data = rawptr(fn)
	t.user_index = 3
	arg1, arg2, arg3 := arg1, arg2, arg3
	mem.copy(&t.user_args[0], &arg1, size_of(arg1))
	mem.copy(&t.user_args[1], &arg2, size_of(arg2))
	mem.copy(&t.user_args[2], &arg3, size_of(arg3))
	t.init_context = init_context
	start(t)
	return t
}
create_and_start_with_poly_data4 :: proc(arg1: $T1, arg2: $T2, arg3: $T3, arg4: $T4, fn: proc(arg1: T1, arg2: T2, arg3: T3, arg4: T4), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal) -> ^Thread 
	where size_of(T1) <= size_of(rawptr),
	      size_of(T2) <= size_of(rawptr),
	      size_of(T3) <= size_of(rawptr) {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc(T1, T2, T3, T4))t.data
		assert(t.user_index >= 4)
		arg1 := (^T1)(&t.user_args[0])^
		arg2 := (^T2)(&t.user_args[1])^
		arg3 := (^T3)(&t.user_args[2])^
		arg4 := (^T4)(&t.user_args[3])^
		fn(arg1, arg2, arg3, arg4)
	}
	t := create(thread_proc, priority)
	t.data = rawptr(fn)
	t.user_index = 4
	arg1, arg2, arg3, arg4 := arg1, arg2, arg3, arg4
	mem.copy(&t.user_args[0], &arg1, size_of(arg1))
	mem.copy(&t.user_args[1], &arg2, size_of(arg2))
	mem.copy(&t.user_args[2], &arg3, size_of(arg3))
	mem.copy(&t.user_args[3], &arg4, size_of(arg4))
	t.init_context = init_context
	start(t)
	return t
}
