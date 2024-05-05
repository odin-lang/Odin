//+private
//+build linux, darwin, freebsd, openbsd, haiku
package testing

import "base:runtime"
import "core:sync"
import "core:thread"
import "core:time"

Runner_Thread_Data :: struct {
	t: ^T,
	it: Internal_Test,
}

Watcher_Thread_Data :: struct {
	t: ^T,
	duration: time.Duration,
	loc: runtime.Source_Code_Location,
}

global_timeout_futex: sync.Futex

run_internal_test :: proc(t: ^T, it: Internal_Test) {
	runner := thread.create(proc(runner: ^thread.Thread) {
		data := cast(^Runner_Thread_Data)runner.data

		// Run the test.
		data.it.p(data.t)

		// Test completed; tell the main and watcher thread to continue.
		sync.futex_broadcast(&global_timeout_futex)
	})

	// This data can live on the stack, since it will outlive the runner
	// thread.
	data: Runner_Thread_Data = {t, it}
	runner.data = &data

	thread.start(runner)

	// Wait for either the runner thread to finish or the watcher thread to
	// broadcast a failure.
	sync.futex_wait(&global_timeout_futex, 0)

	if !thread.is_done(runner) {
		// The runner thread is still going, which means it's been timed out;
		// forcibly terminate it.
		thread.terminate(runner, 1)
	}

	// Destroy the runner thread and join it to this thread.
	thread.destroy(runner)
}

_fail_timeout :: proc(t: ^T, duration: time.Duration, loc := #caller_location) {
	watcher := thread.create(proc(watcher: ^thread.Thread) {
		data := cast(^Watcher_Thread_Data)watcher.data

		// Wait for either a timeout or the runner thread to clear us.
		ok := sync.futex_wait_with_timeout(&global_timeout_futex, 0, data.duration)

		if !ok {
			// If the wait went beyond the duration, we tell the test suite
			// that the test failed.
			fail_now(data.t, "TIMEOUT", data.loc)
		}

		// Tell the main thread to resume operation.
		sync.futex_broadcast(&global_timeout_futex)

		// Cleanup allocations.
		free(watcher.data)
		thread.destroy(watcher)
	})

	// Allocate a new struct for this data, because it will live longer than
	// the scope of this procedure.
	ftd := new(Watcher_Thread_Data)
	ftd^ = {t, duration, loc} 
	watcher.data = ftd

	thread.start(watcher)
}
