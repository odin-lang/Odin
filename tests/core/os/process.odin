#+build !windows
package tests_core_os

import "core:os"
import "core:log"
import "core:sys/posix"
import "core:testing"

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

// A read end whose descriptor was closed under it (by a stray close
// elsewhere) is no empty pipe: pipe_has_data reports an error, so
// process_exec's read loop, which polls until an error, EOF or
// Broken_Pipe, ends instead of spinning.
//
// The descriptor is closed in a forked child: the child has one thread and
// its own copy of the descriptor table, so the close cannot free a number
// that a test on another thread holds. The child calls only close, poll
// (inside pipe_has_data) and _exit, which are async-signal-safe.
@(test)
test_pipe_has_data_on_a_closed_descriptor :: proc(t: ^testing.T) {
	r, w, err := os.pipe()
	if !testing.expect_value(t, err, nil) {
		return
	}
	defer os.close(r)
	defer os.close(w)

	pid := posix.fork()
	if !testing.expect(t, pid >= 0, "fork failed") {
		return
	}
	if pid == 0 {
		posix.close(posix.FD(os.fd(r)))
		_, perr := os.pipe_has_data(r)
		posix._exit(0 if perr != nil else 1)
	}

	status: i32
	testing.expect_value(t, posix.waitpid(pid, &status, {}), pid)
	testing.expectf(t, posix.WIFEXITED(status) && posix.WEXITSTATUS(status) == 0,
		"a closed descriptor reads as an empty pipe (child status %x)", status)
}
