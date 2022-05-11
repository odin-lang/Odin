// +build linux, darwin, freebsd, openbsd
// +private
package thread

import "core:runtime"
import "core:intrinsics"
import "core:sync"
import "core:sys/unix"

CAS :: intrinsics.atomic_compare_exchange_strong

Thread_State :: enum u8 {
	Started,
	Joined,
	Done,
}

// NOTE(tetra): Aligned here because of core/unix/pthread_linux.odin/pthread_t.
// Also see core/sys/darwin/mach_darwin.odin/semaphore_t.
Thread_Os_Specific :: struct #align 16 {
	unix_thread: unix.pthread_t, // NOTE: very large on Darwin, small on Linux.
	cond:        sync.Cond,
	mutex:       sync.Mutex,
	flags:       bit_set[Thread_State; u8],
}
//
// Creates a thread which will run the given procedure.
// It then waits for `start` to be called.
//
_create :: proc(procedure: Thread_Proc, priority := Thread_Priority.Normal) -> ^Thread {
	__linux_thread_entry_proc :: proc "c" (t: rawptr) -> rawptr {
		t := (^Thread)(t)

		// We need to give the thread a moment to start up before we enable cancellation.
		can_set_thread_cancel_state := unix.pthread_setcancelstate(unix.PTHREAD_CANCEL_DISABLE, nil) == 0

		context = runtime.default_context()

		sync.lock(&t.mutex)

		t.id = sync.current_thread_id()

		for (.Started not_in t.flags) {
			sync.wait(&t.cond, &t.mutex)
		}

		init_context := t.init_context
		context =	init_context.? or_else runtime.default_context()

		// Enable thread's cancelability.
		if can_set_thread_cancel_state {
			unix.pthread_setcanceltype (unix.PTHREAD_CANCEL_ASYNCHRONOUS, nil)
			unix.pthread_setcancelstate(unix.PTHREAD_CANCEL_DISABLE,      nil)
		}

		t.procedure(t)

		intrinsics.atomic_store(&t.flags, t.flags + { .Done })

		sync.unlock(&t.mutex)

		if init_context == nil && context.temp_allocator.data == &runtime.global_default_temp_allocator_data {
			runtime.default_temp_allocator_destroy(auto_cast context.temp_allocator.data)
		}

		return nil
	}

	attrs: unix.pthread_attr_t
	if unix.pthread_attr_init(&attrs) != 0 {
		return nil // NOTE(tetra, 2019-11-01): POSIX OOM.
	}
	defer unix.pthread_attr_destroy(&attrs)

	// NOTE(tetra, 2019-11-01): These only fail if their argument is invalid.
	assert(unix.pthread_attr_setdetachstate(&attrs, unix.PTHREAD_CREATE_JOINABLE) == 0)
	assert(unix.pthread_attr_setinheritsched(&attrs, unix.PTHREAD_EXPLICIT_SCHED) == 0)

	thread := new(Thread)
	if thread == nil {
		return nil
	}
	thread.creation_allocator = context.allocator

	// Set thread priority.
	policy: i32
	res := unix.pthread_attr_getschedpolicy(&attrs, &policy)
	assert(res == 0)
	params: unix.sched_param
	res = unix.pthread_attr_getschedparam(&attrs, &params)
	assert(res == 0)
	low := unix.sched_get_priority_min(policy)
	high := unix.sched_get_priority_max(policy)
	switch priority {
	case .Normal: // Okay
	case .Low:  params.sched_priority = low + 1
	case .High: params.sched_priority = high
	}
	res = unix.pthread_attr_setschedparam(&attrs, &params)
	assert(res == 0)

	thread.procedure = procedure
	if unix.pthread_create(&thread.unix_thread, &attrs, __linux_thread_entry_proc, thread) != 0 {
		free(thread, thread.creation_allocator)
		return nil
	}

	return thread
}

_start :: proc(t: ^Thread) {
	// sync.guard(&t.mutex)
	t.flags += { .Started }
	sync.signal(&t.cond)
}

_is_done :: proc(t: ^Thread) -> bool {
	return .Done in intrinsics.atomic_load(&t.flags)
}

_join :: proc(t: ^Thread) {
	// sync.guard(&t.mutex)

	if unix.pthread_equal(unix.pthread_self(), t.unix_thread) {
		return
	}

	// Preserve other flags besides `.Joined`, like `.Started`.
	unjoined := intrinsics.atomic_load(&t.flags) - {.Joined}
	joined   := unjoined + {.Joined}

	// Try to set `t.flags` from unjoined to joined. If it returns joined,
	// it means the previous value had that flag set and we can return.
	if res, ok := CAS(&t.flags, unjoined, joined); res == joined && !ok {
		return
	}
	unix.pthread_join(t.unix_thread, nil)
}

_join_multiple :: proc(threads: ..^Thread) {
	for t in threads {
		_join(t)
	}
}

_destroy :: proc(t: ^Thread) {
	_join(t)
	t.unix_thread = {}
	free(t, t.creation_allocator)
}

_terminate :: proc(t: ^Thread, exit_code: int) {
	unix.pthread_cancel(t.unix_thread)
}

_yield :: proc() {
	unix.sched_yield()
}
