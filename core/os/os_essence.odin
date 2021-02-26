package os

import "core:sys/es"

Handle :: distinct int;
Errno :: distinct int;

ERROR_NONE :: (Errno) (es.SUCCESS);

O_RDONLY :: 0x1;
O_WRONLY :: 0x2;
O_CREATE :: 0x4;
O_TRUNC  :: 0x8;

stderr : Handle = 0; 

current_thread_id :: proc "contextless" () -> int {
	return (int) (es.ThreadGetID(es.CURRENT_THREAD));
}

heap_alloc :: proc(size: int) -> rawptr {
	return es.HeapAllocate(size, false);
}

heap_free :: proc(ptr: rawptr) {
	es.HeapFree(ptr);
}

heap_resize :: proc(ptr: rawptr, new_size: int) -> rawptr {
	return es.HeapReallocate(ptr, new_size, false);
}

open :: proc(path: string, flags: int = O_RDONLY, mode: int = 0) -> (Handle, Errno) {
	return (Handle) (0), (Errno) (1);
}

close :: proc(fd: Handle) -> Errno {
	return (Errno) (1);
}

file_size :: proc(fd: Handle) -> (i64, Errno) {
	return (i64) (0), (Errno) (1);
}

read :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	return (int) (0), (Errno) (1);
}

write :: proc(fd: Handle, data: []u8) -> (int, Errno) {
	return (int) (0), (Errno) (1);
}

seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Errno) {
	return (i64) (0), (Errno) (1);
}
