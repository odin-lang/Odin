#+build !windows
#+build !wasi
package tests_core_os

import "core:os"
import "core:log"
import "core:sync"
import "core:sys/posix"
import "core:testing"
import "core:thread"
import "core:time"

@(test)
test_process_exec :: proc(t: ^testing.T) {
	state, stdout, stderr, err := os.process_exec({
		command = {"echo", "hellope"},
	}, context.allocator)
	defer delete(stdout)
	defer delete(stderr)

	if err == .Unsupported {
		log.warn("process_exec unsupported")
		return
	}

	testing.expect_value(t, state.exited,  true)
	testing.expect_value(t, state.success, true)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, string(stdout), "hellope\n")
	testing.expect_value(t, string(stderr), "")
}

@(test)
test_process_exit_code :: proc(t: ^testing.T) {
	state, stdout, stderr, err := os.process_exec({
		command = {"sh", "-c", "exit 3"},
	}, context.allocator)
	defer delete(stdout)
	defer delete(stderr)

	if err == .Unsupported {
		log.warn("process_exec unsupported")
		return
	}

	testing.expect_value(t, err, nil)
	testing.expect_value(t, state.exited,    true)
	testing.expect_value(t, state.success,   false)
	testing.expect_value(t, state.exit_code, 3)
	testing.expect_value(t, state.signal,    0)
}

@(test)
test_process_signal :: proc(t: ^testing.T) {
	state, stdout, stderr, err := os.process_exec({
		command = {"sh", "-c", "kill -s KILL $$"},
	}, context.allocator)
	defer delete(stdout)
	defer delete(stderr)

	if err == .Unsupported {
		log.warn("process_exec unsupported")
		return
	}

	testing.expect_value(t, err, nil)
	testing.expect_value(t, state.exited,    true)
	testing.expect_value(t, state.success,   false)
	testing.expect_value(t, state.exit_code, 9)
	testing.expect_value(t, state.signal,    9)
}

@(private="file")
ignore_signal :: proc "c" (_: posix.Signal) {}

// A program with a signal handler, such as one that handles SIGCHLD, has its
// `poll` calls interrupted with EINTR. `process_exec` must read the child's
// output to the end anyway.
@(test)
test_process_exec_interrupted_by_signals :: proc(t: ^testing.T) {
	action := posix.sigaction_t{sa_handler = ignore_signal}
	previous: posix.sigaction_t
	testing.expect_value(t, posix.sigaction(.SIGUSR1, &action, &previous), posix.result.OK)
	defer posix.sigaction(.SIGUSR1, &previous, nil)

	done: bool
	interrupter := thread.create_and_start_with_poly_data2(&done, posix.pthread_self(), proc(done: ^bool, target: posix.pthread_t) {
		for !sync.atomic_load(done) {
			posix.pthread_kill(target, .SIGUSR1)
			time.sleep(100 * time.Microsecond)
		}
	})

	state, stdout, stderr, err := os.process_exec({
		command = {"sh", "-c", "sleep 0.2; echo hellope"},
	}, context.allocator)
	defer delete(stdout)
	defer delete(stderr)

	sync.atomic_store(&done, true)
	thread.join(interrupter)
	thread.destroy(interrupter)

	if err == .Unsupported {
		log.warn("process_exec unsupported")
		return
	}

	testing.expect_value(t, err, nil)
	testing.expect_value(t, state.exited,  true)
	testing.expect_value(t, state.success, true)
	testing.expect_value(t, string(stdout), "hellope\n")
	testing.expect_value(t, string(stderr), "")
}
