package os

import "core:mem"
import "core:strconv"
import "core:unicode/utf8"


OS :: ODIN_OS;
ARCH :: ODIN_ARCH;
ENDIAN :: ODIN_ENDIAN;

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
	if read_err != ERROR_NONE {
		delete(data);
		return nil, false;
	}
	return data[:bytes_read], true;
}

write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (success: bool) {
	flags: int = O_WRONLY|O_CREATE;
	if truncate {
		flags |= O_TRUNC;
	}

	mode: int = 0;
	when OS == "linux" || OS == "darwin" {
		// NOTE(justasd): 644 (owner read, write; group read; others read)
		mode = S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH;
	}

	fd, err := open(name, flags, mode);
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

	//
	// NOTE(tetra, 2020-01-14): The heap doesn't respect alignment.
	// Instead, we overallocate by `alignment + size_of(rawptr) - 1`, and insert
	// padding. We also store the original pointer returned by heap_alloc right before
	// the pointer we return to the user.
	//

	aligned_alloc :: proc(size, alignment: int, old_ptr: rawptr = nil) -> rawptr {
		a := max(alignment, align_of(rawptr));
		space := size + a - 1;

		allocated_mem: rawptr;
		if old_ptr != nil {
			original_old_ptr := mem.ptr_offset((^rawptr)(old_ptr), -1)^;
			allocated_mem = heap_resize(original_old_ptr, space+size_of(rawptr));
		} else {
			allocated_mem = heap_alloc(space+size_of(rawptr));
		}
		aligned_mem := rawptr(mem.ptr_offset((^u8)(allocated_mem), size_of(rawptr)));

		ptr := uintptr(aligned_mem);
		aligned_ptr := (ptr - 1 + uintptr(a)) & -uintptr(a);
		diff := int(aligned_ptr - ptr);
		if (size + diff) > space {
			return nil;
		}

		aligned_mem = rawptr(aligned_ptr);
		mem.ptr_offset((^rawptr)(aligned_mem), -1)^ = allocated_mem;

		return aligned_mem;
	}

	aligned_free :: proc(p: rawptr) {
		if p != nil {
			heap_free(mem.ptr_offset((^rawptr)(p), -1)^);
		}
	}

	aligned_resize :: proc(p: rawptr, old_size: int, new_size: int, new_alignment: int) -> rawptr {
		if p == nil do return nil;
		return aligned_alloc(new_size, new_alignment, p);
	}

	switch mode {
	case .Alloc:
		return aligned_alloc(size, alignment);

	case .Free:
		aligned_free(old_memory);

	case .Free_All:
		// NOTE(tetra): Do nothing.

	case .Resize:
		if old_memory == nil {
			return aligned_alloc(size, alignment);
		}
		return aligned_resize(old_memory, old_size, size, alignment);

	case .Query_Features:
		set := (^mem.Allocator_Mode_Set)(old_memory);
		if set != nil {
			set^ = {.Alloc, .Free, .Resize, .Query_Features};
		}
		return set;

	case .Query_Info:
		return nil;
	}

	return nil;
}

heap_allocator :: proc() -> mem.Allocator {
	return mem.Allocator{
		procedure = heap_allocator_proc,
		data = nil,
	};
}
