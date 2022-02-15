// +build linux, darwin, freebsd
// +private
package thread

import "core:runtime"
import "core:intrinsics"
import "core:sync"
import "core:sys/unix"

// NOTE(tetra): Aligned here because of core/unix/pthread_linux.odin/pthread_t.
// Also see core/sys/darwin/mach_darwin.odin/semaphore_t.
Thread_Os_Specific :: struct #align 16 {
	unix_thread: unix.pthread_t, // NOTE: very large on Darwin, small on Linux.

	// NOTE: pthread has a proc to query this, but it is marked
	// as non-portable ("np") so we do this instead.
	done: bool,

	// since libpthread doesn't seem to have a way to create a thread
	// in a suspended state, we have it wait on this gate, which we
	// signal to start it.
	// destroyed after thread is started.
	start_gate:  sync.Condition,
	start_mutex: sync.Mutex,

	// if true, the thread has been started and the start_gate has been destroyed.
	started: bool,

	// NOTE: with pthreads, it is undefined behavior for multiple threads
	// to call join on the same thread at the same time.
	// this value is atomically updated to detect this.
	// See the comment in `join`.
	already_joined: bool,
}
//
// Creates a thread which will run the given procedure.
// It then waits for `start` to be called.
//
_create :: proc(procedure: Thread_Proc, priority := Thread_Priority.Normal) -> ^Thread {
	__linux_thread_entry_proc :: proc "c" (t: rawptr) -> rawptr {
		context = runtime.default_context()
		t := (^Thread)(t)
		sync.condition_wait_for(&t.start_gate)
		sync.condition_destroy(&t.start_gate)
		sync.mutex_destroy(&t.start_mutex)
		t.start_gate = {}
		t.start_mutex = {}

		context = t.init_context.? or_else runtime.default_context()
		
		t.id = sync.current_thread_id()
		t.procedure(t)

		if t.init_context == nil {
			if context.temp_allocator.data == &runtime.global_default_temp_allocator_data {
				runtime.default_temp_allocator_destroy(auto_cast context.temp_allocator.data)
			}
		}

		intrinsics.atomic_store(&t.done, true)
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
	
	sync.mutex_init(&thread.start_mutex)
	sync.condition_init(&thread.start_gate, &thread.start_mutex)

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

	if unix.pthread_create(&thread.unix_thread, &attrs, __linux_thread_entry_proc, thread) != 0 {
		free(thread, thread.creation_allocator)
		
		sync.condition_destroy(&thread.start_gate)
		sync.mutex_destroy(&thread.start_mutex)
		return nil
	}
	thread.procedure = procedure


	return thread
}

_start :: proc(t: ^Thread) {
	if intrinsics.atomic_xchg(&t.started, true) {
		return
	}
	sync.condition_signal(&t.start_gate)
}

_is_done :: proc(t: ^Thread) -> bool {
	return intrinsics.atomic_load(&t.done)
}

_join :: proc(t: ^Thread) {
	if unix.pthread_equal(unix.pthread_self(), t.unix_thread) {
		return
	}
	// if unix.pthread_self().x == t.unix_thread.x do return;

	// NOTE(tetra): It's apparently UB for multiple threads to join the same thread
	// at the same time.
	// If someone else already did, spin until the thread dies.
	// See note on `already_joined` field.
	// TODO(tetra): I'm not sure if we should do this, or panic, since I'm not
	// sure it makes sense to need to join from multiple threads?
	if intrinsics.atomic_xchg(&t.already_joined, true) {
		for {
			if intrinsics.atomic_load(&t.done) {
				return
			}
			intrinsics.cpu_relax()
		}
	}

	// NOTE(tetra): If we're already dead, don't bother calling to pthread_join as that
	// will just return 3 (ESRCH).
	// We do this instead because I don't know if there is a danger
	// that you may join a different thread from the one you called join on,
	// if the thread handle is reused.
	if intrinsics.atomic_load(&t.done) {
		return
	}

	ret_val: rawptr
	_ = unix.pthread_join(t.unix_thread, &ret_val)
	if !intrinsics.atomic_load(&t.done) {
		panic("thread not done after join")
	}
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
	// TODO(bill)
}

_yield :: proc() {
	unix.sched_yield()
}
