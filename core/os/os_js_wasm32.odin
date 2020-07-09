package os

Handle :: distinct i32;
Errno :: distinct i32;

ERROR_NONE :: Errno(0);

O_RDONLY   :: 0x00000;
O_WRONLY   :: 0x00001;
O_RDWR     :: 0x00002;
O_CREATE   :: 0x00040;
O_EXCL     :: 0x00080;
O_NOCTTY   :: 0x00100;
O_TRUNC    :: 0x00200;
O_NONBLOCK :: 0x00800;
O_APPEND   :: 0x00400;
O_SYNC     :: 0x01000;
O_ASYNC    :: 0x02000;
O_CLOEXEC  :: 0x80000;

stdout: Handle;
stderr: Handle;
stdin: Handle;


write :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	return 0, 0;
}
read :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	return 0, 0;
}
open :: proc(path: string, mode: int = O_RDONLY, perm: int = 0) -> (Handle, Errno) {
	return 0, 0;
}
close :: proc(fd: Handle) -> Errno {
	return 0;
}


current_thread_id :: proc "contextless" () -> int {
	return 0;
}


file_size :: proc(fd: Handle) -> (i64, Errno) {
	return 0, 0;
}



heap_alloc :: proc(size: int) -> rawptr {
	return nil;
}
heap_resize :: proc(ptr: rawptr, new_size: int) -> rawptr {
	if new_size == 0 {
		heap_free(ptr);
		return nil;
	}
	if ptr == nil do return heap_alloc(new_size);

	return nil;
}
heap_free :: proc(ptr: rawptr) {
	if ptr == nil do return;
}
