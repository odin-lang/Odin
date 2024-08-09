//+build darwin, freebsd, openbsd, netbsd
package tests_core_posix

import "core:log"
import "core:testing"
import "core:sys/posix"

// This test tests some of the process APIs of posix while also double checking size and alignment
// of the structs we bound.

@(test)
execute_struct_checks :: proc(t: ^testing.T) {
	log.debug("compiling C project")
	{
		switch pid := posix.fork(); pid {
		case -1:
			log.errorf("fork() failed: %s", posix.strerror())
		case 0:
			c_compiler := posix.getenv("CC")
			if c_compiler == nil {
				c_compiler = "clang"
			}

			posix.execlp(c_compiler,
				c_compiler, #directory + "/structs/structs.c", "-o", #directory + "/structs/c_structs", nil)
			posix.exit(69)
		case:
			if !wait_for(t, pid) { return }
			log.debug("C code has been compiled!")
		}
	}

	log.debug("compiling Odin project")
	{
		switch pid := posix.fork(); pid {
		case -1:
			log.errorf("fork() failed: %s", posix.strerror())
		case 0:
			posix.execlp(ODIN_ROOT + "/odin",
				ODIN_ROOT + "/odin", "build", #directory + "/structs/structs.odin", "-out:" + #directory + "/structs/odin_structs", "-file", nil)
			posix.exit(69)
		case:
			if !wait_for(t, pid) { return }
			log.debug("Odin code has been compiled!")
		}
	}

	c_buf: [dynamic]byte
	defer delete(c_buf)
	c_out := get_output(t, &c_buf, #directory + "/structs/c_structs", nil)

	odin_buf: [dynamic]byte
	defer delete(odin_buf)
	odin_out := get_output(t, &odin_buf, #directory + "/structs/odin_structs", nil)

	testing.expectf(t, c_out == odin_out, "The C output and Odin output differ!\nC output:\n%s\n\n\n\nOdin Output:\n%s", c_out, odin_out)

	/* ----------- HELPERS ----------- */

	wait_for :: proc(t: ^testing.T, pid: posix.pid_t) -> (ok: bool) {
		log.debugf("waiting on pid %v", pid)

		waiting: for {
			status: i32
			wpid := posix.waitpid(pid, &status, {})
			if !testing.expectf(t, wpid != -1, "waitpid() failure: %v", posix.strerror()) {
				return false
			}

			switch {
			case posix.WIFEXITED(status):
				ok = testing.expect_value(t, posix.WEXITSTATUS(status), 0)
				break waiting
			case posix.WIFSIGNALED(status):
				log.errorf("child process raised: %v", posix.strsignal(posix.WTERMSIG(status)))
				ok = false
				break waiting
			case:
				log.errorf("unexpected status (this should never happen): %v", status)
				ok = false
				break waiting
			}
		}

		return
	}

	get_output :: proc(t: ^testing.T, output: ^[dynamic]byte, cmd: ..cstring) -> (out_str: string) {
		log.debugf("capturing output of: %v", cmd)

		pipe: [2]posix.FD
		if !testing.expect_value(t, posix.pipe(&pipe), posix.result.OK) {
			return
		}

		switch pid := posix.fork(); pid {
		case -1:
			log.errorf("fork() failed: %s", posix.strerror())
			return
		case 0:
			posix.close(pipe[0])
			posix.dup2(pipe[1], 1)
			posix.execv(cmd[0], raw_data(cmd[:]))
			panic(string(posix.strerror()))
		case:
			posix.close(pipe[1])
			log.debugf("waiting on pid %v", pid)

			reader: for {
				buf: [256]byte
				switch read := posix.read(pipe[0], &buf[0], 256); {
				case read  < 0:
					log.errorf("read output failed: %v", posix.strerror())
					return
				case read == 0:
					break reader
				case:
					append(output, ..buf[:read])
				}
			}

			wait_for(t, pid)

			return string(output[:])
		}
	}
}
