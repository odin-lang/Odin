// +build linux, darwin, freebsd, openbsd, netbsd, haiku
// +private
package thread

import "base:runtime"
import "core:sync"
import "core:sys/unix"
import "core:time"

_IS_SUPPORTED :: true

CAS :: sync.atomic_compare_exchange_strong

// NOTE(tetra): Aligned here because of core/unix/pthread_linux.odin/pthread_t.
// Also see core/sys/darwin/mach_darwin.odin/semaphore_t.
Thread_Os_Specific :: struct #align(16) {
	unix_thread: unix.pthread_t, // NOTE: very large on Darwin, small on Linux.
	cond:        sync.Cond,
	mutex:       sync.Mutex,
}
//
// Creates a thread which will run the given procedure.
// It then waits for `start` to be called.
//
_create :: proc(procedure: Thread_Proc, priority: Thread_Priority) -> ^Thread {
	__unix_thread_entry_proc :: proc "c" (t: rawptr) -> rawptr {
		t := (^Thread)(t)

		// We need to give the thread a moment to start up before we enable cancellation.
		can_set_thread_cancel_state := unix.pthread_setcancelstate(unix.PTHREAD_CANCEL_ENABLE, nil) == 0

		sync.lock(&t.mutex)

		t.id = sync.current_thread_id()

		for (.Started not_in sync.atomic_load(&t.flags)) {
			// HACK: use a timeout so in the event that the condition is signalled at THIS comment's exact point
			// (after checking flags, before starting the wait) it gets itself out of that deadlock after a ms.
			sync.wait_with_timeout(&t.cond, &t.mutex, time.Millisecond)
		}

		if .Joined in sync.atomic_load(&t.flags) {
			return nil
		}

		// Enable thread's cancelability.
		if can_set_thread_cancel_state {
			unix.pthread_setcanceltype (unix.PTHREAD_CANCEL_ASYNCHRONOUS, nil)
			unix.pthread_setcancelstate(unix.PTHREAD_CANCEL_ENABLE,       nil)
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

		sync.unlock(&t.mutex)

		if .Self_Cleanup in sync.atomic_load(&t.flags) {
			res := unix.pthread_detach(t.unix_thread)
			assert_contextless(res == 0)

			t.unix_thread = {}
			// NOTE(ftphikari): It doesn't matter which context 'free' received, right?
			context = {}
			free(t, t.creation_allocator)
		}

		return nil
	}

	attrs: unix.pthread_attr_t
	if unix.pthread_attr_init(&attrs) != 0 {
		return nil // NOTE(tetra, 2019-11-01): POSIX OOM.
	}
	defer unix.pthread_attr_destroy(&attrs)

	// NOTE(tetra, 2019-11-01): These only fail if their argument is invalid.
	res: i32
	res = unix.pthread_attr_setdetachstate(&attrs, unix.PTHREAD_CREATE_JOINABLE)
	assert(res == 0)
	when ODIN_OS != .Haiku && ODIN_OS != .NetBSD {
		res = unix.pthread_attr_setinheritsched(&attrs, unix.PTHREAD_EXPLICIT_SCHED)
		assert(res == 0)
	}

	thread := new(Thread)
	if thread == nil {
		return nil
	}
	thread.creation_allocator = context.allocator

	// Set thread priority.
	policy: i32
	when ODIN_OS != .Haiku && ODIN_OS != .NetBSD {
		res = unix.pthread_attr_getschedpolicy(&attrs, &policy)
		assert(res == 0)
	}
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
	if unix.pthread_create(&thread.unix_thread, &attrs, __unix_thread_entry_proc, thread) != 0 {
		free(thread, thread.creation_allocator)
		return nil
	}

	return thread
}

_start :: proc(t: ^Thread) {
	sync.atomic_or(&t.flags, { .Started })
	sync.signal(&t.cond)
}

_is_done :: proc(t: ^Thread) -> bool {
	return .Done in sync.atomic_load(&t.flags)
}

_join :: proc(t: ^Thread) {
	// sync.guard(&t.mutex)

	if unix.pthread_equal(unix.pthread_self(), t.unix_thread) {
		return
	}

	// Preserve other flags besides `.Joined`, like `.Started`.
	unjoined := sync.atomic_load(&t.flags) - {.Joined}
	joined   := unjoined + {.Joined}

	// Try to set `t.flags` from unjoined to joined. If it returns joined,
	// it means the previous value had that flag set and we can return.
	if res, ok := CAS(&t.flags, unjoined, joined); res == joined && !ok {
		return
	}
	// Prevent non-started threads from blocking main thread with initial wait
	// condition.
	if .Started not_in unjoined {
		_start(t)
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
	unix.pthread_cancel(t.unix_thread)
}

_yield :: proc() {
	unix.sched_yield()
}
