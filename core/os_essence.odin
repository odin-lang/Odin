foreign import api "system:api"

Handle    :: int;
Errno     :: int;

O_RDONLY   :: 1;
O_WRONLY   :: 2;
O_CREATE   :: 4;
O_TRUNC    :: 4;

OS_Node_Type :: enum i32 {
	File      = 0,
	Directory = 1,
}

OS_Node_Information :: struct {
	handle:   Handle,
	id:       [16]byte,
	ntype:    OS_Node_Type,
	size:     i64,
	position: i64,
}

foreign api {
	@(link_name="OSHelloWorld")       os_hello_world       :: proc() ---;
	@(link_name="OSPrintDirect")      os_print_direct      :: proc(string: ^byte, length: int) ---;
	@(link_name="OSHeapAllocate")     os_heap_allocate     :: proc(bytes: int, zero: bool) -> rawptr ---;
	@(link_name="OSHeapFree")         os_heap_free         :: proc(address: rawptr) ---;
	@(link_name="OSOpenNode")         os_open_node         :: proc(path: ^byte, path_length: int, flags: u64, information: ^OS_Node_Information) -> Errno ---;
	@(link_name="OSResizeFile")       os_resize_file       :: proc(handle: Handle, new_size: u64) -> Errno ---;
	@(link_name="OSCloseHandle")      os_close_handle      :: proc(handle: Handle) ---;
	@(link_name="OSWriteFileSync")    os_write_file_sync   :: proc(handle: Handle, offset: i64, size: i64, buffer: rawptr) -> i64 ---;
	@(link_name="OSReadFileSync")     os_read_file_sync    :: proc(handle: Handle, offset: i64, size: i64, buffer: rawptr) -> i64 ---;
	@(link_name="OSInitialiseAPI")    os_initialise_api    :: proc() -> int ---;
	@(link_name="OSTerminateProcess") os_terminate_process :: proc(handle: Handle) ---;
	@(link_name="realloc")            os_heap_reallocate   :: proc(address: rawptr, size: int) -> rawptr ---;
}

stdin  := Handle(-1); // Not implemented
stdout := Handle(0);
stderr := Handle(0);

current_thread_id :: proc() -> int {
	// Not implemented
	return -1;
}

heap_alloc :: proc(size: int) -> rawptr {
	return os_heap_allocate(size, true);
}

heap_free :: proc(address: rawptr) {
	os_heap_free(address);
}

heap_resize :: proc(address: rawptr, new_size: int) -> rawptr {
	return os_heap_reallocate(address, new_size);
}

open :: proc(path: string, mode: int = O_RDONLY, perm: u32 = 0) -> (Handle, Errno) {
	information := new(OS_Node_Information);
	error := os_open_node(&path[0], len(path), u64(mode), information);
	if error < -1 do return 0, 1;
	information.position = 0;
	if mode&O_TRUNC==O_TRUNC {
		error := os_resize_file(information.handle, 0);
		if error < -1 do return 0, 1;
	}
	return Handle(uintptr(information)), 0;
}

close :: proc(fd: Handle) {
	information := (^OS_Node_Information)(uintptr(fd));
	os_close_handle(information.handle);
	free(information);
}

file_size :: proc(fd: Handle) -> (i64, Errno) {
	// Not (properly) implemented
	information := cast(^OS_Node_Information)uintptr(fd);
	return information.size,0;
}

write :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	if fd == 0 {
		os_print_direct(&data[0], len(data));
		return len(data), 0;
	} else if fd == 1 {
		assert(false);
		return 0, 1;
	}
	information := (^OS_Node_Information)(uintptr(fd));
	count := os_write_file_sync(information.handle, information.position, i64(len(data)), &data[0]);
	if count < 0 do  return 0, 1;
	information.position += count;
	return int(count), 0;
}

read :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	if (fd == 0 || fd == 1) {
		assert(false);
		return 0, 1;
	}
	information := (^OS_Node_Information)(uintptr(fd));
	count := os_read_file_sync(information.handle, information.position, i64(len(data)), &data[0]);
	if count < 0 do return 0, 1;
	information.position += count;
	return int(count), 0;
}

os_terminate_this_process :: proc() {
	os_terminate_process(0x1001);
}
