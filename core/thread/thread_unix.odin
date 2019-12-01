// +build linux, darwin
package thread;

import "core:sys/unix"
import "core:sync"

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
	start_gate: sync.Condition,

	// if true, the thread has been started and the start_gate has been destroyed.
	started: bool,

	// NOTE: with pthreads, it is undefined behavior for multiple threads
	// to call join on the same thread at the same time.
	// this value is atomically updated to detect this.
	// See the comment in `join`.
	already_joined: bool,
}

Thread_Priority :: enum {
	Normal,
	Low,
	High,
}

//
// Creates a thread which will run the given procedure.
// It then waits for `start` to be called.
//
// You may provide a slice of bytes to use as the stack for the new thread,
// but if you do, you are expected to set up the guard pages yourself.
//
// The stack must also be aligned appropriately for the platform.
// We require it's at least 16 bytes aligned to help robustness; other
// platforms may require page-size alignment.
// Note also that pthreads requires the stack is at least 6 OS pages in size:
// 4 are required by pthreads, and two extra for guards pages that will be applied.
//
create :: proc(procedure: Thread_Proc, priority := Thread_Priority.Normal) -> ^Thread {
	__linux_thread_entry_proc :: proc "c" (t: rawptr) -> rawptr {
		t := (^Thread)(t);
		sync.condition_wait_for(&t.start_gate);
		sync.condition_destroy(&t.start_gate);
		t.start_gate = {};

		c := context;
		if t.use_init_context {
			c = t.init_context;
		}
		context = c;

		t.procedure(t);
		sync.atomic_store(&t.done, true, .Sequentially_Consistent);
		return nil;
	}

	attrs: unix.pthread_attr_t;
	if unix.pthread_attr_init(&attrs) != 0 do return nil; // NOTE(tetra, 2019-11-01): POSIX OOM.
	defer unix.pthread_attr_destroy(&attrs);

	// NOTE(tetra, 2019-11-01): These only fail if their argument is invalid.
	assert(unix.pthread_attr_setdetachstate(&attrs, unix.PTHREAD_CREATE_JOINABLE) == 0);
	assert(unix.pthread_attr_setinheritsched(&attrs, unix.PTHREAD_EXPLICIT_SCHED) == 0);

	thread := new(Thread);
	if thread == nil do return nil;

	// Set thread priority.
	policy: i32;
	res := unix.pthread_attr_getschedpolicy(&attrs, &policy);
	assert(res == 0);
	params: unix.sched_param;
	res = unix.pthread_attr_getschedparam(&attrs, &params);
	fmt.println(params.sched_priority);
	assert(res == 0);
	low := unix.sched_get_priority_min(policy);
	high := unix.sched_get_priority_max(policy);
	switch priority {
	case .Low:
		params.sched_priority = low + 1;
	case .High:
		params.sched_priority = high;
	}
	fmt.println(low, high, params.sched_priority);
	res = unix.pthread_attr_setschedparam(&attrs, &params);
	assert(res == 0);

	sync.condition_init(&thread.start_gate);
	if unix.pthread_create(&thread.unix_thread, &attrs, __linux_thread_entry_proc, thread) != 0 {
		free(thread);
		return nil;
	}
	thread.procedure = procedure;

	return thread;
}

start :: proc(t: ^Thread) {
	if sync.atomic_swap(&t.started, true, .Sequentially_Consistent) do return;
	sync.condition_signal(&t.start_gate);
}

is_done :: proc(t: ^Thread) -> bool {
	return sync.atomic_load(&t.done, .Sequentially_Consistent);
}

join :: proc(t: ^Thread) {
	if unix.pthread_equal(unix.pthread_self(), t.unix_thread) do return;
	// if unix.pthread_self().x == t.unix_thread.x do return;

	// NOTE(tetra): It's apparently UB for multiple threads to join the same thread
	// at the same time.
	// If someone else already did, spin until the thread dies.
	// See note on `already_joined` field.
	// TODO(tetra): I'm not sure if we should do this, or panic, since I'm not
	// sure it makes sense to need to join from multiple threads?
	if sync.atomic_swap(&t.already_joined, true, .Sequentially_Consistent) {
		for {
			if sync.atomic_load(&t.done, .Sequentially_Consistent) do return;
			sync.yield_processor();
		}
	}

	// NOTE(tetra): If we're already dead, don't bother calling to pthread_join as that
	// will just return 3 (ESRCH).
	// We do this instead because I don't know if there is a danger
	// that you may join a different thread from the one you called join on,
	// if the thread handle is reused.
	if sync.atomic_load(&t.done, .Sequentially_Consistent) do return;

	ret := unix.pthread_join(t.unix_thread, nil);
	assert(ret == 0, "cannot join thread");
	assert(sync.atomic_load(&t.done, .Sequentially_Consistent), "thread not done after join");
}

import "core:fmt"
destroy :: proc(t: ^Thread) {
	join(t);
	t.unix_thread = {};
	free(t);
}
