#+build !windows
package tests_core_os

import "core:fmt"
import "core:os"
import "core:log"
import "core:strings"
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

// A child gets the parent's inheritable descriptors and its standard
// streams, nothing of process_start's own: the /dev/null it opens for a
// stream the description leaves out is not passed on through the exec.
// The child shell prints each of the descriptors 3 to 9 that is open in
// it (sh redirects only single-digit ones).
@(test)
test_process_start_leaks_no_descriptor :: proc(t: ^testing.T) {
	want := strings.builder_make(context.allocator)
	defer strings.builder_destroy(&want)
	for fd in 3 ..= 9 {
		flags := posix.fcntl(posix.FD(fd), .GETFD)
		if flags != -1 && flags & posix.FD_CLOEXEC == 0 {
			fmt.sbprintf(&want, "%d\n", fd)
		}
	}
	state, stdout, stderr, err := os.process_exec({
		command = {"/bin/sh", "-c", `for f in 3 4 5 6 7 8 9; do (: <&$f) 2>/dev/null && echo $f; done; true`},
	}, context.allocator)
	defer delete(stdout)
	defer delete(stderr)

	if err == .Unsupported {
		log.warn("process_exec unsupported")
		return
	}

	testing.expect_value(t, err, nil)
	testing.expect_value(t, state.success, true)
	testing.expect_value(t, string(stdout), strings.to_string(want))
}
