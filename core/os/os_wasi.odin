package os

import "core:sys/wasm/wasi"
import "base:runtime"

Handle :: distinct i32
_Platform_Error :: wasi.errno_t

INVALID_HANDLE :: -1

O_RDONLY   :: 0x00000
O_WRONLY   :: 0x00001
O_RDWR     :: 0x00002
O_CREATE   :: 0x00040
O_EXCL     :: 0x00080
O_NOCTTY   :: 0x00100
O_TRUNC    :: 0x00200
O_NONBLOCK :: 0x00800
O_APPEND   :: 0x00400
O_SYNC     :: 0x01000
O_ASYNC    :: 0x02000
O_CLOEXEC  :: 0x80000

stdin:  Handle = 0
stdout: Handle = 1
stderr: Handle = 2

args := _alloc_command_line_arguments()

@(require_results)
_alloc_command_line_arguments :: proc() -> (args: []string) {
	args = make([]string, len(runtime.args__))
	for &arg, i in args {
		arg = string(runtime.args__[i])
	}
	return
}

// WASI works with "preopened" directories, the environment retrieves directories
// (for example with `wasmtime --dir=. module.wasm`) and those given directories
// are the only ones accessible by the application.
//
// So in order to facilitate the `os` API (absolute paths etc.) we keep a list
// of the given directories and match them when needed (notably `os.open`).

@(private)
Preopen :: struct {
	fd:     wasi.fd_t,
	prefix: string,
}
@(private)
preopens: []Preopen

@(init, private)
init_preopens :: proc() {

	strip_prefixes :: proc(path: string) -> string {
		path := path
		loop: for len(path) > 0 {
			switch {
			case path[0] == '/':
				path = path[1:]
			case len(path) > 2  && path[0] == '.' && path[1] == '/':
				path = path[2:]
			case len(path) == 1 && path[0] == '.':
				path = path[1:]
			case:
				break loop
			}
		}
		return path
	}

	dyn_preopens: [dynamic]Preopen
	loop: for fd := wasi.fd_t(3); ; fd += 1 {
		desc, err := wasi.fd_prestat_get(fd)
		#partial switch err {
		case .BADF: break loop
		case:       panic("fd_prestat_get returned an unexpected error")
		case .SUCCESS:
		}

		switch desc.tag {
		case .DIR:
			buf := make([]byte, desc.dir.pr_name_len) or_else panic("could not allocate memory for filesystem preopens")
			if err = wasi.fd_prestat_dir_name(fd, buf); err != .SUCCESS {
				panic("could not get filesystem preopen dir name")
			}
			append(&dyn_preopens, Preopen{fd, strip_prefixes(string(buf))})
		}
	}
	preopens = dyn_preopens[:]
}

@(require_results)
wasi_match_preopen :: proc(path: string) -> (wasi.fd_t, string, bool) {
	@(require_results)
	prefix_matches :: proc(prefix, path: string) -> bool {
		// Empty is valid for any relative path.
		if len(prefix) == 0 && len(path) > 0 && path[0] != '/' {
			return true
		}

		if len(path) < len(prefix) {
			return false
		}

		if path[:len(prefix)] != prefix {
			return false
		}

		// Only match on full components.
		i := len(prefix)
		for i > 0 && prefix[i-1] == '/' {
			i -= 1
		}
		return path[i] == '/'
	}

	path := path
	for len(path) > 0 && path[0] == '/' {
		path = path[1:]
	}

	match: Preopen
	#reverse for preopen in preopens {
		if (match.fd == 0 || len(preopen.prefix) > len(match.prefix)) && prefix_matches(preopen.prefix, path) {
			match = preopen
		}
	}

	if match.fd == 0 {
		return 0, "", false
	}

	relative := path[len(match.prefix):]
	for len(relative) > 0 && relative[0] == '/' {
		relative = relative[1:]
	}

	if len(relative) == 0 {
		relative = "."
	}

	return match.fd, relative, true
}

write :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	iovs := wasi.ciovec_t(data)
	n, err := wasi.fd_write(wasi.fd_t(fd), {iovs})
	return int(n), Platform_Error(err)
}
read :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	iovs := wasi.iovec_t(data)
	n, err := wasi.fd_read(wasi.fd_t(fd), {iovs})
	return int(n), Platform_Error(err)
}
write_at :: proc(fd: Handle, data: []byte, offset: i64) -> (int, Errno) {
	iovs := wasi.ciovec_t(data)
	n, err := wasi.fd_pwrite(wasi.fd_t(fd), {iovs}, wasi.filesize_t(offset))
	return int(n), Platform_Error(err)
}
read_at :: proc(fd: Handle, data: []byte, offset: i64) -> (int, Errno) {
	iovs := wasi.iovec_t(data)
	n, err := wasi.fd_pread(wasi.fd_t(fd), {iovs}, wasi.filesize_t(offset))
	return int(n), Platform_Error(err)
}
@(require_results)
open :: proc(path: string, mode: int = O_RDONLY, perm: int = 0) -> (Handle, Errno) {
	oflags: wasi.oflags_t
	if mode & O_CREATE == O_CREATE {
		oflags += {.CREATE}
	}
	if mode & O_EXCL == O_EXCL {
		oflags += {.EXCL}
	}
	if mode & O_TRUNC == O_TRUNC {
		oflags += {.TRUNC}
	}

	rights: wasi.rights_t = {.FD_SEEK, .FD_FILESTAT_GET}
	switch mode & (O_RDONLY|O_WRONLY|O_RDWR) {
	case O_RDONLY: rights += {.FD_READ}
	case O_WRONLY: rights += {.FD_WRITE}
	case O_RDWR:   rights += {.FD_READ, .FD_WRITE}
	}

	fdflags: wasi.fdflags_t
	if mode & O_APPEND == O_APPEND {
		fdflags += {.APPEND}
	}
	if mode & O_NONBLOCK == O_NONBLOCK {
		fdflags += {.NONBLOCK}
	}
	if mode & O_SYNC == O_SYNC {
		fdflags += {.SYNC}
	}

	dir_fd, relative, ok := wasi_match_preopen(path)
	if !ok {
		return INVALID_HANDLE, Errno(wasi.errno_t.BADF)
	}

	fd, err := wasi.path_open(dir_fd, {.SYMLINK_FOLLOW}, relative, oflags, rights, {}, fdflags)
	return Handle(fd), Platform_Error(err)
}
close :: proc(fd: Handle) -> Errno {
	err := wasi.fd_close(wasi.fd_t(fd))
	return Platform_Error(err)
}

flush :: proc(fd: Handle) -> Error {
	// do nothing
	return nil
}

seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Errno) {
	n, err := wasi.fd_seek(wasi.fd_t(fd), wasi.filedelta_t(offset), wasi.whence_t(whence))
	return i64(n), Platform_Error(err)
}
@(require_results)
current_thread_id :: proc "contextless" () -> int {
	return 0
}
@(private, require_results)
_processor_core_count :: proc() -> int {
	return 1
}

@(require_results)
file_size :: proc(fd: Handle) -> (size: i64, err: Errno) {
	stat := wasi.fd_filestat_get(wasi.fd_t(fd)) or_return
	size = i64(stat.size)
	return
}


exit :: proc "contextless" (code: int) -> ! {
	runtime._cleanup_runtime_contextless()
	wasi.proc_exit(wasi.exitcode_t(code))
}
