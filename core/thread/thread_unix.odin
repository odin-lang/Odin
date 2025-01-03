#+build linux, darwin, freebsd, openbsd, netbsd, haiku
#+private
package thread

import "base:runtime"
import "core:sync"
import "core:sys/posix"

_IS_SUPPORTED :: true

// NOTE(tetra): Aligned here because of core/unix/pthread_linux.odin/pthread_t.
// Also see core/sys/darwin/mach_darwin.odin/semaphore_t.
Thread_Os_Specific :: struct #align(16) {
	unix_thread: posix.pthread_t, // NOTE: very large on Darwin, small on Linux.
	start_ok:    sync.Sema,
}
//
// Creates a thread which will run the given procedure.
// It then waits for `start` to be called.
//
_create :: proc(procedure: Thread_Proc, priority: Thread_Priority) -> ^Thread {
	__unix_thread_entry_proc :: proc "c" (t: rawptr) -> rawptr {
		t := (^Thread)(t)

		// We need to give the thread a moment to start up before we enable cancellation.
		// NOTE(laytan): setting to .DISABLE on darwin, with .ENABLE pthread_cancel would deadlock
		// most of the time, don't ask me why.
		can_set_thread_cancel_state := posix.pthread_setcancelstate(.DISABLE when ODIN_OS == .Darwin else .ENABLE, nil) == nil

		t.id = sync.current_thread_id()

		if .Started not_in sync.atomic_load(&t.flags) {
			sync.wait(&t.start_ok)
		}

		if .Joined in sync.atomic_load(&t.flags) {
			return nil
		}

		// Enable thread's cancelability.
		// NOTE(laytan): Darwin does not correctly/fully support all of this, not doing this does
		// actually make pthread_cancel work in the capacity of my tests, while executing this would
		// basically always make it deadlock.
		if ODIN_OS != .Darwin && can_set_thread_cancel_state {
			err := posix.pthread_setcancelstate(.ENABLE, nil)
			assert_contextless(err == nil)

			err = posix.pthread_setcanceltype(.ASYNCHRONOUS, nil)
			assert_contextless(err == nil)
		}

		{
			init_context := t.init_context

			// NOTE(tetra, 2023-05-31): Must do this AFTER thread.start() is called, so that the user can set the init_context, etc!
			// Here on Unix, we start the OS thread in a running state, and so we manually have it wait on a condition
			// variable above. We must perform that waiting BEFORE we select the context!
			context = _select_context_for_thread(init_context)
			defer {
				_maybe_destroy_default_temp_allocator(init_context)
				runtime.run_thread_local_cleaners()
			}

			t.procedure(t)
		}

		sync.atomic_or(&t.flags, { .Done })

		if .Self_Cleanup in sync.atomic_load(&t.flags) {
			res := posix.pthread_detach(t.unix_thread)
			assert_contextless(res == nil)

			t.unix_thread = {}
			// NOTE(ftphikari): It doesn't matter which context 'free' received, right?
			context = {}
			free(t, t.creation_allocator)
		}

		return nil
	}

	attrs: posix.pthread_attr_t
	if posix.pthread_attr_init(&attrs) != nil {
		return nil // NOTE(tetra, 2019-11-01): POSIX OOM.
	}
	defer posix.pthread_attr_destroy(&attrs)

	// NOTE(tetra, 2019-11-01): These only fail if their argument is invalid.
	res: posix.Errno
	res = posix.pthread_attr_setdetachstate(&attrs, .CREATE_JOINABLE)
	assert(res == nil)
	when ODIN_OS != .Haiku && ODIN_OS != .NetBSD {
		res = posix.pthread_attr_setinheritsched(&attrs, .EXPLICIT_SCHED)
		assert(res == nil)
	}

	thread := new(Thread)
	if thread == nil {
		return nil
	}
	thread.creation_allocator = context.allocator

	// Set thread priority.
	policy: posix.Sched_Policy
	when ODIN_OS != .Haiku && ODIN_OS != .NetBSD {
		res = posix.pthread_attr_getschedpolicy(&attrs, &policy)
		assert(res == nil)
	}
	params: posix.sched_param
	res = posix.pthread_attr_getschedparam(&attrs, &params)
	assert(res == nil)
	low := posix.sched_get_priority_min(policy)
	high := posix.sched_get_priority_max(policy)
	switch priority {
	case .Normal: // Okay
	case .Low:  params.sched_priority = low + 1
	case .High: params.sched_priority = high
	}
	res = posix.pthread_attr_setschedparam(&attrs, &params)
	assert(res == nil)

	thread.procedure = procedure
	if posix.pthread_create(&thread.unix_thread, &attrs, __unix_thread_entry_proc, thread) != nil {
		free(thread, thread.creation_allocator)
		return nil
	}

	return thread
}

_start :: proc(t: ^Thread) {
	sync.atomic_or(&t.flags, { .Started })
	sync.post(&t.start_ok)
}

_is_done :: proc(t: ^Thread) -> bool {
	return .Done in sync.atomic_load(&t.flags)
}

_join :: proc(t: ^Thread) {
	if posix.pthread_equal(posix.pthread_self(), t.unix_thread) {
		return
	}

	// If the previous value was already `Joined`, then we can return.
	if .Joined in sync.atomic_or(&t.flags, {.Joined}) {
		return
	}

	// Prevent non-started threads from blocking main thread with initial wait
	// condition.
	if .Started not_in sync.atomic_load(&t.flags) {
		_start(t)
	}
	posix.pthread_join(t.unix_thread, nil)
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
	// NOTE(Feoramund): For thread cancellation to succeed on BSDs and
	// possibly Darwin systems, the thread must call one of the pthread
	// cancelation points at some point after this.
	//
	// The most obvious one of these is `pthread_cancel`, but there is an
	// entire list of functions that act as cancelation points available in the
	// pthreads manual page.
	//
	// This is in contrast to behavior I have seen on Linux where the thread is
	// just terminated.
	posix.pthread_cancel(t.unix_thread)
}

_yield :: proc() {
	posix.sched_yield()
}
