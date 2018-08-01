package os

import "core:mem"

write_string :: proc(fd: Handle, str: string) -> (int, Errno) {
	return write(fd, cast([]byte)str);
}

write_byte :: proc(fd: Handle, b: byte) -> (int, Errno) {
	return write(fd, []byte{b});
}


read_entire_file :: proc(name: string) -> (data: []byte, success: bool) {
	fd, err := open(name, O_RDONLY, 0);
	if err != 0 {
		return nil, false;
	}
	defer close(fd);

	length: i64;
	if length, err = file_size(fd); err != 0 {
		return nil, false;
	}

	if length <= 0 {
		return nil, true;
	}

	data = make([]byte, int(length));
	if data == nil {
		return nil, false;
	}

	bytes_read, read_err := read(fd, data);
	if read_err != 0 {
		delete(data);
		return nil, false;
	}
	return data[0:bytes_read], true;
}

write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (success: bool) {
	flags: int = O_WRONLY|O_CREATE;
	if truncate {
		flags |= O_TRUNC;
	}
	fd, err := open(name, flags, 0);
	if err != 0 {
		return false;
	}
	defer close(fd);

	_, write_err := write(fd, data);
	return write_err == 0;
}

write_ptr :: proc(fd: Handle, data: rawptr, len: int) -> (int, Errno) {
	s := transmute([]byte)mem.Raw_Slice{data, len};
	return write(fd, s);
}

read_ptr :: proc(fd: Handle, data: rawptr, len: int) -> (int, Errno) {
	s := transmute([]byte)mem.Raw_Slice{data, len};
	return read(fd, s);
}


heap_allocator_proc :: proc(allocator_data: rawptr, mode: mem.Allocator_Mode,
                               size, alignment: int,
                               old_memory: rawptr, old_size: int, flags: u64 = 0, loc := #caller_location) -> rawptr {
	using mem.Allocator_Mode;

	switch mode {
	case Alloc:
		return heap_alloc(size);

	case Free:
		heap_free(old_memory);
		return nil;

	case Free_All:
		// NOTE(bill): Does nothing

	case Resize:
		ptr := heap_resize(old_memory, size);
		assert(ptr != nil);
		return ptr;
	}

	return nil;
}

heap_allocator :: proc() -> mem.Allocator {
	return mem.Allocator{
		procedure = heap_allocator_proc,
		data = nil,
	};
}
