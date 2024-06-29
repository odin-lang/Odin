package os

import "core:sys/wasm/wasi"
import "base:runtime"

Handle :: distinct i32
Errno :: distinct i32

INVALID_HANDLE :: -1

ERROR_NONE :: Errno(wasi.errno_t.SUCCESS)

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
current_dir: Handle = 3

args := _alloc_command_line_arguments()

_alloc_command_line_arguments :: proc() -> (args: []string) {
	args = make([]string, len(runtime.args__))
	for &arg, i in args {
		arg = string(runtime.args__[i])
	}
	return
}

write :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	iovs := wasi.ciovec_t(data)
	n, err := wasi.fd_write(wasi.fd_t(fd), {iovs})
	return int(n), Errno(err)
}
read :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	iovs := wasi.iovec_t(data)
	n, err := wasi.fd_read(wasi.fd_t(fd), {iovs})
	return int(n), Errno(err)
}
write_at :: proc(fd: Handle, data: []byte, offset: i64) -> (int, Errno) {
	iovs := wasi.ciovec_t(data)
	n, err := wasi.fd_pwrite(wasi.fd_t(fd), {iovs}, wasi.filesize_t(offset))
	return int(n), Errno(err)
}
read_at :: proc(fd: Handle, data: []byte, offset: i64) -> (int, Errno) {
	iovs := wasi.iovec_t(data)
	n, err := wasi.fd_pread(wasi.fd_t(fd), {iovs}, wasi.filesize_t(offset))
	return int(n), Errno(err)
}
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
	fd, err := wasi.path_open(wasi.fd_t(current_dir),{.SYMLINK_FOLLOW},path,oflags,rights,{},fdflags)
	return Handle(fd), Errno(err)
}
close :: proc(fd: Handle) -> Errno {
	err := wasi.fd_close(wasi.fd_t(fd))
	return Errno(err)
}
seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Errno) {
	n, err := wasi.fd_seek(wasi.fd_t(fd), wasi.filedelta_t(offset), wasi.whence_t(whence))
	return i64(n), Errno(err)
}
current_thread_id :: proc "contextless" () -> int {
	return 0
}
@(private)
_processor_core_count :: proc() -> int {
	return 1
}

file_size :: proc(fd: Handle) -> (i64, Errno) {
	stat, err := wasi.fd_filestat_get(wasi.fd_t(fd))
	if err != nil {
		return 0, Errno(err)
	}
	return i64(stat.size), 0
}


exit :: proc "contextless" (code: int) -> ! {
	runtime._cleanup_runtime_contextless()
	wasi.proc_exit(wasi.exitcode_t(code))
}
