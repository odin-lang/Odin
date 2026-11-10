#+build darwin
package tests_core_os

import "core:os"
import "core:sync"
import "core:sys/posix"
import "core:testing"

foreign import libc "system:System"

foreign libc {
	pthread_atfork :: proc "c" (prepare, parent, child: proc "c" ()) -> i32 ---
}

// One at a time: they open pipes and move fd 0, and the runner runs tests in
// threads of one process.
@(private="file")
process_tests: sync.Mutex

@(private="file")
forks: int

@(private="file")
count_fork :: proc "c" () {
	sync.atomic_add(&forks, 1)
}

// A fork in a process with threads can kill the child in libSystem's fork
// handlers, before the exec, so process_start starts the program without one.
@(test)
test_process_start_takes_no_fork :: proc(t: ^testing.T) {
	sync.mutex_lock(&process_tests)
	defer sync.mutex_unlock(&process_tests)

	testing.expect_value(t, pthread_atfork(count_fork, nil, nil), 0)
	before := sync.atomic_load(&forks)

	state, stdout, stderr, err := os.process_exec({command = {"/usr/bin/true"}}, context.allocator)
	defer delete(stdout)
	defer delete(stderr)

	testing.expect_value(t, err, nil)
	testing.expect_value(t, state.success, true)
	testing.expect_value(t, sync.atomic_load(&forks), before)
}

@(private="file")
exec :: proc(t: ^testing.T, desc: os.Process_Desc) -> (state: os.Process_State, stdout, stderr: string, err: os.Error) {
	out, errs: []byte
	state, out, errs, err = os.process_exec(desc, context.temp_allocator)
	return state, string(out), string(errs), err
}

@(test)
test_process_start_working_dir :: proc(t: ^testing.T) {
	sync.mutex_lock(&process_tests)
	defer sync.mutex_unlock(&process_tests)

	state, stdout, _, err := exec(t, {working_dir = "/bin", command = {"/bin/sh", "-c", "pwd -P"}})
	testing.expect_value(t, err, nil)
	testing.expect_value(t, state.success, true)
	testing.expect_value(t, stdout, "/bin\n")
}

@(test)
test_process_start_reports_what_exec_and_chdir_refuse :: proc(t: ^testing.T) {
	sync.mutex_lock(&process_tests)
	defer sync.mutex_unlock(&process_tests)

	_, err := os.process_start({working_dir = "/no/such/directory", command = {"/usr/bin/true"}})
	testing.expect_value(t, err, os.Error(posix.Errno.ENOENT))
}

@(test)
test_process_start_passes_the_environment :: proc(t: ^testing.T) {
	sync.mutex_lock(&process_tests)
	defer sync.mutex_unlock(&process_tests)

	_, stdout, _, err := exec(t, {command = {"/bin/sh", "-c", "echo $A"}, env = {"A=b"}})
	testing.expect_value(t, err, nil)
	testing.expect_value(t, stdout, "b\n")
}

// A stream given by another stream's number: the child's stdout is the
// parent's fd 0, which the child's own stdin replaces.
@(test)
test_process_start_stream_on_another_streams_number :: proc(t: ^testing.T) {
	sync.mutex_lock(&process_tests)
	defer sync.mutex_unlock(&process_tests)

	in_r, in_w, ierr := os.pipe()
	out_r, out_w, oerr := os.pipe()
	testing.expect_value(t, ierr, nil)
	testing.expect_value(t, oerr, nil)
	defer os.close(in_r)
	defer os.close(out_r)

	saved := posix.dup(0)
	posix.dup2(posix.FD(os.fd(out_w)), 0)
	os.close(out_w)
	p, err := os.process_start({command = {"/bin/cat"}, stdin = in_r, stdout = os.stdin})
	posix.dup2(saved, 0)
	posix.close(saved)
	testing.expect_value(t, err, nil)

	os.write_string(in_w, "through\n")
	os.close(in_w)
	if err == nil {
		_, werr := os.process_wait(p)
		testing.expect_value(t, werr, nil)
	}
	buf: [16]byte
	n, _ := os.read(out_r, buf[:])
	testing.expect_value(t, string(buf[:n]), "through\n")
}

// A stream the description leaves out reads as /dev/null.
@(test)
test_process_start_left_out_stream :: proc(t: ^testing.T) {
	sync.mutex_lock(&process_tests)
	defer sync.mutex_unlock(&process_tests)

	_, stdout, _, err := exec(t, {command = {"/bin/sh", "-c", "cat; echo end"}})
	testing.expect_value(t, err, nil)
	testing.expect_value(t, stdout, "end\n")
}
