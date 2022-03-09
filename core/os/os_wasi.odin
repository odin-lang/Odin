package os

import "core:sys/wasm/wasi"
import "core:runtime"

Handle :: distinct i32
Errno :: distinct i32

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
	return 0, -1
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


file_size :: proc(fd: Handle) -> (i64, Errno) {
	stat, err := wasi.fd_filestat_get(wasi.fd_t(fd))
	if err != nil {
		return 0, Errno(err)
	}
	return i64(stat.size), 0
}



heap_alloc :: proc(size: int) -> rawptr {
	return nil
}
heap_resize :: proc(ptr: rawptr, new_size: int) -> rawptr {
	if new_size == 0 {
		heap_free(ptr)
		return nil
	}
	if ptr == nil {
		return heap_alloc(new_size)
	}

	return nil
}
heap_free :: proc(ptr: rawptr) {
	if ptr == nil {
		return
	}
}


exit :: proc "contextless" (code: int) -> ! {
	runtime._cleanup_runtime_contextless()
	wasi.proc_exit(wasi.exitcode_t(code))
}