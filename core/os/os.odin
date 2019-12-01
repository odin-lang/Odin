package os

import "core:mem"
import "core:strconv"
import "core:unicode/utf8"

write_string :: proc(fd: Handle, str: string) -> (int, Errno) {
	return write(fd, transmute([]byte)str);
}

write_byte :: proc(fd: Handle, b: byte) -> (int, Errno) {
	return write(fd, []byte{b});
}

write_rune :: proc(fd: Handle, r: rune) -> (int, Errno) {
	if r < utf8.RUNE_SELF {
		return write_byte(fd, byte(r));
	}

	b, n := utf8.encode_rune(r);
	return write(fd, b[:n]);
}

write_encoded_rune :: proc(fd: Handle, r: rune) {
	write_byte(fd, '\'');

	switch r {
	case '\a': write_string(fd, "\\a");
	case '\b': write_string(fd, "\\b");
	case '\e': write_string(fd, "\\e");
	case '\f': write_string(fd, "\\f");
	case '\n': write_string(fd, "\\n");
	case '\r': write_string(fd, "\\r");
	case '\t': write_string(fd, "\\t");
	case '\v': write_string(fd, "\\v");
	case:
		if r < 32 {
			write_string(fd, "\\x");
			b: [2]byte;
			s := strconv.append_bits(b[:], u64(r), 16, true, 64, strconv.digits, nil);
			switch len(s) {
			case 0: write_string(fd, "00");
			case 1: write_rune(fd, '0');
			case 2: write_string(fd, s);
			}
		} else {
			write_rune(fd, r);
		}
	}
	write_byte(fd, '\'');
}


file_size_from_path :: proc(path: string) -> i64 {
	fd, err := open(path, O_RDONLY, 0);
	if err != 0 {
		return -1;
	}
	defer close(fd);

	length: i64;
	if length, err = file_size(fd); err != 0 {
		return -1;
	}
	return length;
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
/*
	//
	// NOTE(tetra, 2019-11-10): The heap doesn't respect alignment.
	// HACK: Overallocate, align forwards, and then use the two bytes immediately before
	// the address we return, to store the padding we inserted.
	// This allows us to pass the original pointer we got back from the heap to `free` later.
	//

	align_and_store_padding :: proc(ptr: rawptr, alignment: int) -> rawptr {
		ptr := mem.ptr_offset(cast(^u8) ptr, 2);
		new_ptr := cast(^u8) mem.align_forward(ptr, uintptr(alignment));
		offset := mem.ptr_sub(new_ptr, cast(^u8) ptr) + 2;
		assert(offset < int(max(u16)));
		(^[2]u8)(mem.ptr_offset(new_ptr, -2))^ = transmute([2]u8) u16(offset);
		return new_ptr;
	}

	recover_original_pointer :: proc(ptr: rawptr) -> rawptr {
		ptr := cast(^u8) ptr;
		offset := transmute(u16) (^[2]u8)(mem.ptr_offset(ptr, -2))^;
		ptr = mem.ptr_offset(ptr, -int(offset));
		return ptr;
	}

	aligned_heap_alloc :: proc(size: int, alignment: int) -> rawptr {
		// NOTE(tetra): Alignment 1 will mean we only have one extra byte.
		// This is not enough for a u16 - so we ensure there is at least two bytes extra.
		// This also means that the pointer is always aligned to at least 2.
		extra := alignment;
		if extra <= 1 do extra = 2;

		orig := cast(^u8) heap_alloc(size + extra);
		if orig == nil do return nil;
		ptr := align_and_store_padding(orig, alignment);
		assert(recover_original_pointer(ptr) == orig);
		return ptr;
	}

	switch mode {
	case .Alloc:
		return aligned_heap_alloc(size, alignment);

	case .Free:
		if old_memory != nil {
			ptr := recover_original_pointer(old_memory);
			heap_free(ptr);
		}
		return nil;

	case .Free_All:
		// NOTE(bill): Does nothing

	case .Resize:
		if old_memory == nil {
			return aligned_heap_alloc(size, alignment);
		}
		ptr := recover_original_pointer(old_memory);
		ptr = heap_resize(ptr, size);
		assert(ptr != nil);
		return align_and_store_padding(ptr, alignment);
	}

	return nil;
*/
	switch mode {
	case .Alloc:
		return heap_alloc(size);

	case .Free:
		if old_memory != nil {
			heap_free(old_memory);
		}
		return nil;

	case .Free_All:
		// NOTE(bill): Does nothing

	case .Resize:
		return heap_resize(old_memory, size);
	}

	return nil;
}

heap_allocator :: proc() -> mem.Allocator {
	return mem.Allocator{
		procedure = heap_allocator_proc,
		data = nil,
	};
}
