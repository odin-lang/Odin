package os

import "core:sys/es"

Handle :: distinct int
_Platform_Error :: enum i32 {NONE}

// ERROR_NONE :: Error(es.SUCCESS)

O_RDONLY :: 0x1
O_WRONLY :: 0x2
O_CREATE :: 0x4
O_TRUNC  :: 0x8

stderr : Handle = 0

current_thread_id :: proc "contextless" () -> int {
	return (int) (es.ThreadGetID(es.CURRENT_THREAD))
}

heap_alloc :: proc(size: int, zero_memory := true) -> rawptr {
	return es.HeapAllocate(size, zero_memory)
}

heap_free :: proc(ptr: rawptr) {
	es.HeapFree(ptr)
}

heap_resize :: proc(ptr: rawptr, new_size: int) -> rawptr {
	return es.HeapReallocate(ptr, new_size, false)
}

open :: proc(path: string, flags: int = O_RDONLY, mode: int = 0) -> (Handle, Error) {
	return (Handle) (0), (Error) (1)
}

close :: proc(fd: Handle) -> Error {
	return (Error) (1)
}

file_size :: proc(fd: Handle) -> (i64, Error) {
	return (i64) (0), (Error) (1)
}

read :: proc(fd: Handle, data: []byte) -> (int, Error) {
	return (int) (0), (Error) (1)
}

write :: proc(fd: Handle, data: []u8) -> (int, Error) {
	return (int) (0), (Error) (1)
}

seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Error) {
	return (i64) (0), (Error) (1)
}

flush :: proc(fd: Handle) -> Error {
	// do nothing
	return nil
}