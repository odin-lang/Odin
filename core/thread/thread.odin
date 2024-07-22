package thread

import "base:runtime"
import "core:mem"
import "base:intrinsics"

_ :: intrinsics

/*
Value, specifying whether `core:thread` functionality is available on the
current platform.
*/
IS_SUPPORTED :: _IS_SUPPORTED

/*
Type for a procedure that will be run in a thread, after that thread has been
started.
*/
Thread_Proc :: #type proc(^Thread)

/*
Maximum number of user arguments for polymorphic thread procedures.
*/
MAX_USER_ARGUMENTS :: 8

/*
Type representing the state/flags of the thread.
*/
Thread_State :: enum u8 {
	Started,
	Joined,
	Done,
	Self_Cleanup,
}

/*
Type representing a thread handle and the associated with that thread data.
*/
Thread :: struct {
	using specific: Thread_Os_Specific,
	flags: bit_set[Thread_State; u8],
	// Thread ID.
	id: int,
	// The thread procedure.
	procedure: Thread_Proc,
	// User-supplied pointer, that will be available to the thread once it is
	// started. Should be set after the thread has been created, but before
	// it is started.
	data: rawptr,
	// User-supplied integer, that will be available to the thread once it is
	// started. Should be set after the thread has been created, but before
	// it is started.
	user_index: int,
	// User-supplied array of arguments, that will be available to the thread,
	// once it is started. Should be set after the thread has been created,
	// but before it is started.
	user_args: [MAX_USER_ARGUMENTS]rawptr,
	// The thread context.
	// This field can be assigned to directly, after the thread has been
	// created, but __before__ the thread has been started. This field must
	// not be changed after the thread has started.
	//
	// **Note**: If this field is **not** set, the temp allocator will be managed
	// automatically. If it is set, the allocators must be handled manually.
	//
	// **IMPORTANT**:
	// By default, the thread proc will get the same context as `main()` gets.
	// In this situation, the thread will get a new temporary allocator which
	// will be cleaned up when the thread dies. ***This does NOT happen when
	// `init_context` field is initialized***.
	//
	// If `init_context` is initialized, and `temp_allocator` field is set to
	// the default temp allocator, then `runtime.default_temp_allocator_destroy()`
	// procedure needs to be called from the thread procedure, in order to prevent
	// any memory leaks.
	init_context: Maybe(runtime.Context),
	// The allocator used to allocate data for the thread.
	creation_allocator: mem.Allocator,
}

when IS_SUPPORTED {
	#assert(size_of(Thread{}.user_index) == size_of(uintptr))
}

/*
Type representing priority of a thread.
*/
Thread_Priority :: enum {
	Normal,
	Low,
	High,
}

/*
Create a thread in a suspended state with the given priority.

This procedure creates a thread that will be set to run the procedure
specified by `procedure` parameter with a specified priority. The returned
thread will be in a suspended state, until `start()` procedure is called.

To start the thread, call `start()`. Also the `create_and_start()`
procedure can be called to create and start the thread immediately.
*/
create :: proc(procedure: Thread_Proc, priority := Thread_Priority.Normal) -> ^Thread {
	return _create(procedure, priority)
}

/*
Wait for the thread to finish and free all data associated with it.
*/
destroy :: proc(thread: ^Thread) {
	_destroy(thread)
}

/*
Start a suspended thread.
*/
start :: proc(thread: ^Thread) {
	_start(thread)
}

/*
Check if the thread has finished work.
*/
is_done :: proc(thread: ^Thread) -> bool {
	return _is_done(thread)
}

/*
Wait for the thread to finish work.
*/
join :: proc(thread: ^Thread) {
	_join(thread)
}

/*
Wait for all threads to finish work.
*/
join_multiple :: proc(threads: ..^Thread) {
	_join_multiple(..threads)
}

/*
Forcibly terminate a running thread.
*/
terminate :: proc(thread: ^Thread, exit_code: int) {
	_terminate(thread, exit_code)
}

/*
Yield the execution of the current thread to another OS thread or process.
*/
yield :: proc() {
	_yield()
}

/*
Run a procedure on a different thread.

This procedure runs the given procedure on another thread. The context
specified by `init_context` will be used as the context in which `fn` is going
to execute. The thread will have priority specified by the `priority` parameter.

**IMPORTANT**: If `init_context` is specified and the default temporary allocator
is used, the thread procedure needs to call `runtime.default_temp_allocator_destroy()`
in order to free the resources associated with the temporary allocations.
*/
run :: proc(fn: proc(), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal) {
	create_and_start(fn, init_context, priority, true)
}

/*
Run a procedure with one pointer parameter on a different thread.

This procedure runs the given procedure on another thread. The context
specified by `init_context` will be used as the context in which `fn` is going
to execute. The thread will have priority specified by the `priority` parameter.

**IMPORTANT**: If `init_context` is specified and the default temporary allocator
is used, the thread procedure needs to call `runtime.default_temp_allocator_destroy()`
in order to free the resources associated with the temporary allocations.
*/
run_with_data :: proc(data: rawptr, fn: proc(data: rawptr), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal) {
	create_and_start_with_data(data, fn, init_context, priority, true)
}

/*
Run a procedure with one polymorphic parameter on a different thread.

This procedure runs the given procedure on another thread. The context
specified by `init_context` will be used as the context in which `fn` is going
to execute. The thread will have priority specified by the `priority` parameter.

**IMPORTANT**: If `init_context` is specified and the default temporary allocator
is used, the thread procedure needs to call `runtime.default_temp_allocator_destroy()`
in order to free the resources associated with the temporary allocations.
*/
run_with_poly_data :: proc(data: $T, fn: proc(data: T), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal)
	where size_of(T) <= size_of(rawptr) * MAX_USER_ARGUMENTS {
	create_and_start_with_poly_data(data, fn, init_context, priority, true)
}

/*
Run a procedure with two polymorphic parameters on a different thread.

This procedure runs the given procedure on another thread. The context
specified by `init_context` will be used as the context in which `fn` is going
to execute. The thread will have priority specified by the `priority` parameter.

**IMPORTANT**: If `init_context` is specified and the default temporary allocator
is used, the thread procedure needs to call `runtime.default_temp_allocator_destroy()`
in order to free the resources associated with the temporary allocations.
*/
run_with_poly_data2 :: proc(arg1: $T1, arg2: $T2, fn: proc(T1, T2), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal)
	where size_of(T1) + size_of(T2) <= size_of(rawptr) * MAX_USER_ARGUMENTS {
	create_and_start_with_poly_data2(arg1, arg2, fn, init_context, priority, true)
}

/*
Run a procedure with three polymorphic parameters on a different thread.

This procedure runs the given procedure on another thread. The context
specified by `init_context` will be used as the context in which `fn` is going
to execute. The thread will have priority specified by the `priority` parameter.

**IMPORTANT**: If `init_context` is specified and the default temporary allocator
is used, the thread procedure needs to call `runtime.default_temp_allocator_destroy()`
in order to free the resources associated with the temporary allocations.
*/
run_with_poly_data3 :: proc(arg1: $T1, arg2: $T2, arg3: $T3, fn: proc(arg1: T1, arg2: T2, arg3: T3), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal)
	where size_of(T1) + size_of(T2) + size_of(T3) <= size_of(rawptr) * MAX_USER_ARGUMENTS {
	create_and_start_with_poly_data3(arg1, arg2, arg3, fn, init_context, priority, true)
}

/*
Run a procedure with four polymorphic parameters on a different thread.

This procedure runs the given procedure on another thread. The context
specified by `init_context` will be used as the context in which `fn` is going
to execute. The thread will have priority specified by the `priority` parameter.

**IMPORTANT**: If `init_context` is specified and the default temporary allocator
is used, the thread procedure needs to call `runtime.default_temp_allocator_destroy()`
in order to free the resources associated with the temporary allocations.
*/
run_with_poly_data4 :: proc(arg1: $T1, arg2: $T2, arg3: $T3, arg4: $T4, fn: proc(arg1: T1, arg2: T2, arg3: T3, arg4: T4), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal)
	where size_of(T1) + size_of(T2) + size_of(T3) + size_of(T4) <= size_of(rawptr) * MAX_USER_ARGUMENTS {
	create_and_start_with_poly_data4(arg1, arg2, arg3, arg4, fn, init_context, priority, true)
}

/*
Run a procedure on a different thread.

This procedure runs the given procedure on another thread. The context
specified by `init_context` will be used as the context in which `fn` is going
to execute. The thread will have priority specified by the `priority` parameter.

If `self_cleanup` is specified, after the thread finishes the execution of the
`fn` procedure, the resources associated with the thread are going to be
automatically freed. **Do not** dereference the `^Thread` pointer, if this
flag is specified.

**IMPORTANT**: If `init_context` is specified and the default temporary allocator
is used, the thread procedure needs to call `runtime.default_temp_allocator_destroy()`
in order to free the resources associated with the temporary allocations.
*/
create_and_start :: proc(fn: proc(), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal, self_cleanup := false) -> ^Thread {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc())t.data
		fn()
	}
	t := create(thread_proc, priority)
	t.data = rawptr(fn)
	if self_cleanup {
		t.flags += {.Self_Cleanup}
	}
	t.init_context = init_context
	start(t)
	return t
}

/*
Run a procedure with one pointer parameter on a different thread.

This procedure runs the given procedure on another thread. The context
specified by `init_context` will be used as the context in which `fn` is going
to execute. The thread will have priority specified by the `priority` parameter.

If `self_cleanup` is specified, after the thread finishes the execution of the
`fn` procedure, the resources associated with the thread are going to be
automatically freed. **Do not** dereference the `^Thread` pointer, if this
flag is specified.

**IMPORTANT**: If `init_context` is specified and the default temporary allocator
is used, the thread procedure needs to call `runtime.default_temp_allocator_destroy()`
in order to free the resources associated with the temporary allocations.
*/
create_and_start_with_data :: proc(data: rawptr, fn: proc(data: rawptr), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal, self_cleanup := false) -> ^Thread {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc(rawptr))t.data
		assert(t.user_index >= 1)
		data := t.user_args[0]
		fn(data)
	}
	t := create(thread_proc, priority)
	t.data = rawptr(fn)
	t.user_index = 1
	t.user_args[0] = data
	if self_cleanup {
		t.flags += {.Self_Cleanup}
	}
	t.init_context = init_context
	start(t)
	return t
}

/*
Run a procedure with one polymorphic parameter on a different thread.

This procedure runs the given procedure on another thread. The context
specified by `init_context` will be used as the context in which `fn` is going
to execute. The thread will have priority specified by the `priority` parameter.

If `self_cleanup` is specified, after the thread finishes the execution of the
`fn` procedure, the resources associated with the thread are going to be
automatically freed. **Do not** dereference the `^Thread` pointer, if this
flag is specified.

**IMPORTANT**: If `init_context` is specified and the default temporary allocator
is used, the thread procedure needs to call `runtime.default_temp_allocator_destroy()`
in order to free the resources associated with the temporary allocations.
*/
create_and_start_with_poly_data :: proc(data: $T, fn: proc(data: T), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal, self_cleanup := false) -> ^Thread
	where size_of(T) <= size_of(rawptr) * MAX_USER_ARGUMENTS {
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

	mem.copy(&t.user_args[0], &data, size_of(T))

	if self_cleanup {
		t.flags += {.Self_Cleanup}
	}

	t.init_context = init_context
	start(t)
	return t
}

/*
Run a procedure with two polymorphic parameters on a different thread.

This procedure runs the given procedure on another thread. The context
specified by `init_context` will be used as the context in which `fn` is going
to execute. The thread will have priority specified by the `priority` parameter.

If `self_cleanup` is specified, after the thread finishes the execution of the
`fn` procedure, the resources associated with the thread are going to be
automatically freed. **Do not** dereference the `^Thread` pointer, if this
flag is specified.

**IMPORTANT**: If `init_context` is specified and the default temporary allocator
is used, the thread procedure needs to call `runtime.default_temp_allocator_destroy()`
in order to free the resources associated with the temporary allocations.
*/
create_and_start_with_poly_data2 :: proc(arg1: $T1, arg2: $T2, fn: proc(T1, T2), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal, self_cleanup := false) -> ^Thread
	where size_of(T1) + size_of(T2) <= size_of(rawptr) * MAX_USER_ARGUMENTS {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc(T1, T2))t.data
		assert(t.user_index >= 2)
		
		user_args := mem.slice_to_bytes(t.user_args[:])
		arg1 := (^T1)(raw_data(user_args))^
		arg2 := (^T2)(raw_data(user_args[size_of(T1):]))^

		fn(arg1, arg2)
	}
	t := create(thread_proc, priority)
	t.data = rawptr(fn)
	t.user_index = 2

	arg1, arg2 := arg1, arg2
	user_args := mem.slice_to_bytes(t.user_args[:])

	n := copy(user_args,     mem.ptr_to_bytes(&arg1))
	_  = copy(user_args[n:], mem.ptr_to_bytes(&arg2))

	if self_cleanup {
		t.flags += {.Self_Cleanup}
	}

	t.init_context = init_context
	start(t)
	return t
}

/*
Run a procedure with three polymorphic parameters on a different thread.

This procedure runs the given procedure on another thread. The context
specified by `init_context` will be used as the context in which `fn` is going
to execute. The thread will have priority specified by the `priority` parameter.

If `self_cleanup` is specified, after the thread finishes the execution of the
`fn` procedure, the resources associated with the thread are going to be
automatically freed. **Do not** dereference the `^Thread` pointer, if this
flag is specified.

**IMPORTANT**: If `init_context` is specified and the default temporary allocator
is used, the thread procedure needs to call `runtime.default_temp_allocator_destroy()`
in order to free the resources associated with the temporary allocations.
*/
create_and_start_with_poly_data3 :: proc(arg1: $T1, arg2: $T2, arg3: $T3, fn: proc(arg1: T1, arg2: T2, arg3: T3), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal, self_cleanup := false) -> ^Thread
	where size_of(T1) + size_of(T2) + size_of(T3) <= size_of(rawptr) * MAX_USER_ARGUMENTS {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc(T1, T2, T3))t.data
		assert(t.user_index >= 3)

		user_args := mem.slice_to_bytes(t.user_args[:])
		arg1 := (^T1)(raw_data(user_args))^
		arg2 := (^T2)(raw_data(user_args[size_of(T1):]))^
		arg3 := (^T3)(raw_data(user_args[size_of(T1) + size_of(T2):]))^

		fn(arg1, arg2, arg3)
	}
	t := create(thread_proc, priority)
	t.data = rawptr(fn)
	t.user_index = 3

	arg1, arg2, arg3 := arg1, arg2, arg3
	user_args := mem.slice_to_bytes(t.user_args[:])

	n := copy(user_args,     mem.ptr_to_bytes(&arg1))
	n += copy(user_args[n:], mem.ptr_to_bytes(&arg2))
	_  = copy(user_args[n:], mem.ptr_to_bytes(&arg3))

	if self_cleanup {
		t.flags += {.Self_Cleanup}
	}

	t.init_context = init_context
	start(t)
	return t
}

/*
Run a procedure with four polymorphic parameters on a different thread.

This procedure runs the given procedure on another thread. The context
specified by `init_context` will be used as the context in which `fn` is going
to execute. The thread will have priority specified by the `priority` parameter.

If `self_cleanup` is specified, after the thread finishes the execution of the
`fn` procedure, the resources associated with the thread are going to be
automatically freed. **Do not** dereference the `^Thread` pointer, if this
flag is specified.

**IMPORTANT**: If `init_context` is specified and the default temporary allocator
is used, the thread procedure needs to call `runtime.default_temp_allocator_destroy()`
in order to free the resources associated with the temporary allocations.
*/
create_and_start_with_poly_data4 :: proc(arg1: $T1, arg2: $T2, arg3: $T3, arg4: $T4, fn: proc(arg1: T1, arg2: T2, arg3: T3, arg4: T4), init_context: Maybe(runtime.Context) = nil, priority := Thread_Priority.Normal, self_cleanup := false) -> ^Thread
	where size_of(T1) + size_of(T2) + size_of(T3) + size_of(T4) <= size_of(rawptr) * MAX_USER_ARGUMENTS {
	thread_proc :: proc(t: ^Thread) {
		fn := cast(proc(T1, T2, T3, T4))t.data
		assert(t.user_index >= 4)

		user_args := mem.slice_to_bytes(t.user_args[:])
		arg1 := (^T1)(raw_data(user_args))^
		arg2 := (^T2)(raw_data(user_args[size_of(T1):]))^
		arg3 := (^T3)(raw_data(user_args[size_of(T1) + size_of(T2):]))^
		arg4 := (^T4)(raw_data(user_args[size_of(T1) + size_of(T2) + size_of(T3):]))^

		fn(arg1, arg2, arg3, arg4)
	}
	t := create(thread_proc, priority)
	t.data = rawptr(fn)
	t.user_index = 4

	arg1, arg2, arg3, arg4 := arg1, arg2, arg3, arg4
	user_args := mem.slice_to_bytes(t.user_args[:])

	n := copy(user_args,     mem.ptr_to_bytes(&arg1))
	n += copy(user_args[n:], mem.ptr_to_bytes(&arg2))
	n += copy(user_args[n:], mem.ptr_to_bytes(&arg3))
	_  = copy(user_args[n:], mem.ptr_to_bytes(&arg4))

	if self_cleanup {
		t.flags += {.Self_Cleanup}
	}

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
