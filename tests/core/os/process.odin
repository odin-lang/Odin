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
@(test)
test_pipe_has_data_on_a_closed_descriptor :: proc(t: ^testing.T) {
	r, w, err := os.pipe()
	if !testing.expect_value(t, err, nil) {
		return
	}
	defer os.close(w)
	fd := posix.FD(os.fd(r))
	posix.close(fd)
	has_data, perr := os.pipe_has_data(r)
	// The number taken again, so the File's close below closes its own.
	null := posix.open("/dev/null", {})
	posix.dup2(null, fd)
	posix.close(null)
	os.close(r)
	testing.expect_value(t, has_data, false)
	testing.expectf(t, perr != nil, "a closed descriptor reads as an empty pipe (err %v)", perr)
}
