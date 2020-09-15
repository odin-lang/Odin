package runtime

when ODIN_OS == "freestanding" {
	_OS_Errno  :: distinct int;
	_OS_Handle :: distinct uintptr;

	os_stdout :: proc "contextless" () -> _OS_Handle {
		return 1;
	}
	os_stderr :: proc "contextless" () -> _OS_Handle {
		return 2;
	}

	// TODO(bill): reimplement `os.write`
	os_write :: proc(fd: _OS_Handle, data: []byte) -> (int, _OS_Errno) {
		return 0, -1;
	}

	current_thread_id :: proc "contextless" () -> int {
		return 0;
	}

} else {
	import "core:os"

	_OS_Errno  :: distinct int;
	_OS_Handle :: os.Handle;

	os_stdout :: proc "contextless" () -> _OS_Handle {
		return os.stdout;
	}
	os_stderr :: proc "contextless" () -> _OS_Handle {
		return os.stderr;
	}

	// TODO(bill): reimplement `os.write`
	os_write :: proc(fd: _OS_Handle, data: []byte) -> (int, _OS_Errno) {
		n, err := os.write(fd, data);
		return int(n), _OS_Errno(err);
	}

	current_thread_id :: proc "contextless" () -> int {
		return os.current_thread_id();
	}
}
