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

	/*
		These are values that the user can set as they wish, after the thread has been created.
		This data is easily available to the thread proc.

		These fields can be assigned to directly.

		Should be set after the thread is created, but before it is started.
	*/
	data:           rawptr,
	user_index:     int,
	user_args:      [MAX_USER_ARGUMENTS]rawptr,

	/*
		The context to be used as 'context' in the thread proc.

		This field can be assigned to directly, after the thread has been created, but __before__ the thread has been started.
		This field must not be changed after the thread has started.

		NOTE: If you __don't__ set this, the temp allocator will be managed for you;
		      If you __do__ set this, then you're expected to handle whatever allocators you set, yourself.

		IMPORTANT:
		By default, the thread proc will get the same context as `main()` gets.
		In this sitation, the thread will get a new temporary allocator which will be cleaned up when the thread dies.
		***This does NOT happen when you set `init_context`.***
		This means that if you set `init_context`, but still have the `temp_allocator` field set to the default temp allocator,
		then you'll need to call `runtime.default_temp_allocator_destroy(auto_cast the_thread.init_context.temp_allocator.data)` manually,
		in order to prevent any memory leaks.
		This call ***must*** be done ***in the thread proc*** because the default temporary allocator uses thread local state!
	*/
	init_context: Maybe(runtime.Context),


	creation_allocator: mem.Allocator,
}

#assert(size_of(Thread{}.user_index) == size_of(uintptr))

Thread_Priority :: enum {
	Normal,
	Low,
	High,
}

/*
	Creates a thread in a suspended state with the given priority.
	To start the thread, call `thread.start()`.

	See `thread.create_and_start()`.
*/
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


_select_context_for_thread :: proc(init_context: Maybe(runtime.Context)) -> runtime.Context {
	ctx, ok := init_context.?
	if !ok {
		return runtime.default_context()
	}

	/*
		NOTE(tetra, 2023-05-31):
			Ensure that the temp allocator is thread-safe when the user provides a specific initial context to use.
			Without this, the thread will use the same temp allocator state as the parent thread, and thus, bork it up.
	*/
	if ctx.temp_allocator.procedure == runtime.default_temp_allocator_proc {
		ctx.temp_allocator.data = &runtime.global_default_temp_allocator_data
	}
	return ctx
}

_maybe_destroy_default_temp_allocator :: proc(init_context: Maybe(runtime.Context)) {
	if init_context != nil {
		// NOTE(tetra, 2023-05-31): If the user specifies a custom context for the thread,
		// then it's entirely up to them to handle whatever allocators they're using.
		return
	}

	if context.temp_allocator.procedure == runtime.default_temp_allocator_proc {
		runtime.default_temp_allocator_destroy(auto_cast context.temp_allocator.data)
	}
}