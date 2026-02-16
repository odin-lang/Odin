#+build linux
package test_wycheproof

import "core:log"
import "core:os"
import "core:strings"
import "core:sys/linux"

@(private)
PIPE_BUF :: 4096

case_should_panic :: proc(fn: panic_fn, fn_arg: any, panic_str: string) -> bool {
	stderr_pipe: [2]linux.Fd

	if err := linux.pipe2(&stderr_pipe, linux.Open_Flags{}); err != .NONE {
		log.errorf("panic_case: failed to create pipe: %v", err)
		return false
	}

	pid, err := linux.fork()
	switch {
	case err != .NONE:
		log.errorf("panic_case: failed to fork: %v", err)
		return false
	case pid == 0:
		// In the child, redirect stderr to the pipe, run the function that
		// is supposed to panic, and exit normally.
		linux.dup2(stderr_pipe[1], 2)
		fn(fn_arg)
		os.exit(0)
	}

	// Parent.
	defer linux.close(stderr_pipe[0])
	defer linux.close(stderr_pipe[1])

	// Wait for the child to terminate, and ensure it terminated
	// abnormally (SIGILL/SIGTRAP).
	wait_status: u32
	linux.wait4(pid, &wait_status, linux.Wait_Options{}, nil)
	if !linux.WIFSIGNALED(wait_status) {
		log.errorf("panic_case: child did not terminate via signal: %x", wait_status)
		return false
	}
	term_sig := linux.Signal(linux.WTERMSIG(wait_status))
	if term_sig != .SIGILL && term_sig != .SIGTRAP {
		log.errorf("panic_case: child terminated via wrong signal: %v", term_sig)
		return false
	}

	// Consume the child's stderr output from the pipe buffer.
	//
	// Note: POSIX requires PIPE_BUF be >= 512 bytes, Linux defaults
	// to 4096 bytes.  Either is sufficient to buffer output for our
	// test cases.
	buf: [PIPE_BUF]byte
	n, _ := linux.read(stderr_pipe[0], buf[:])
	if n == 0 {
		log.errorf("panic_case: child stderr empty")
		return false
	}
	s := string(buf[:n])

	log.debugf("panic case: child stderr: '%s'", s)

	return strings.contains(s, panic_str)
}

can_test_panic :: proc() -> bool {
	return true
}
