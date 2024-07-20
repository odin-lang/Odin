package os

import "base:runtime"
import "core:strconv"
import "core:unicode/utf8"


OS :: ODIN_OS
ARCH :: ODIN_ARCH
ENDIAN :: ODIN_ENDIAN

SEEK_SET :: 0
SEEK_CUR :: 1
SEEK_END :: 2

write_string :: proc(fd: Handle, str: string) -> (int, Errno) {
	return write(fd, transmute([]byte)str)
}

write_byte :: proc(fd: Handle, b: byte) -> (int, Errno) {
	return write(fd, []byte{b})
}

write_rune :: proc(fd: Handle, r: rune) -> (int, Errno) {
	if r < utf8.RUNE_SELF {
		return write_byte(fd, byte(r))
	}

	b, n := utf8.encode_rune(r)
	return write(fd, b[:n])
}

write_encoded_rune :: proc(fd: Handle, r: rune) {
	write_byte(fd, '\'')

	switch r {
	case '\a': write_string(fd, "\\a")
	case '\b': write_string(fd, "\\b")
	case '\e': write_string(fd, "\\e")
	case '\f': write_string(fd, "\\f")
	case '\n': write_string(fd, "\\n")
	case '\r': write_string(fd, "\\r")
	case '\t': write_string(fd, "\\t")
	case '\v': write_string(fd, "\\v")
	case:
		if r < 32 {
			write_string(fd, "\\x")
			b: [2]byte
			s := strconv.append_bits(b[:], u64(r), 16, true, 64, strconv.digits, nil)
			switch len(s) {
			case 0: write_string(fd, "00")
			case 1: write_rune(fd, '0')
			case 2: write_string(fd, s)
			}
		} else {
			write_rune(fd, r)
		}
	}
	write_byte(fd, '\'')
}

read_at_least :: proc(fd: Handle, buf: []byte, min: int) -> (n: int, err: Errno) {
	if len(buf) < min {
		return 0, -1
	}
	nn := max(int)
	for nn > 0 && n < min && err == 0 {
		nn, err = read(fd, buf[n:])
		n += nn
	}
	if n >= min {
		err = 0
	}
	return
}

read_full :: proc(fd: Handle, buf: []byte) -> (n: int, err: Errno) {
	return read_at_least(fd, buf, len(buf))
}


file_size_from_path :: proc(path: string) -> i64 {
	fd, err := open(path, O_RDONLY, 0)
	if err != 0 {
		return -1
	}
	defer close(fd)

	length: i64
	if length, err = file_size(fd); err != 0 {
		return -1
	}
	return length
}

read_entire_file_from_filename :: proc(name: string, allocator := context.allocator, loc := #caller_location) -> (data: []byte, success: bool) {
	context.allocator = allocator

	fd, err := open(name, O_RDONLY, 0)
	if err != 0 {
		return nil, false
	}
	defer close(fd)

	return read_entire_file_from_handle(fd, allocator, loc)
}

read_entire_file_from_handle :: proc(fd: Handle, allocator := context.allocator, loc := #caller_location) -> (data: []byte, success: bool) {
	context.allocator = allocator

	length: i64
	err: Errno
	if length, err = file_size(fd); err != 0 {
		return nil, false
	}

	if length <= 0 {
		return nil, true
	}

	data = make([]byte, int(length), allocator, loc)
	if data == nil {
		return nil, false
	}

	bytes_read, read_err := read_full(fd, data)
	if read_err != ERROR_NONE {
		delete(data)
		return nil, false
	}
	return data[:bytes_read], true
}

read_entire_file :: proc {
	read_entire_file_from_filename,
	read_entire_file_from_handle,
}

write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (success: bool) {
	flags: int = O_WRONLY|O_CREATE
	if truncate {
		flags |= O_TRUNC
	}

	mode: int = 0
	when OS == .Linux || OS == .Darwin {
		// NOTE(justasd): 644 (owner read, write; group read; others read)
		mode = S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH
	}

	fd, err := open(name, flags, mode)
	if err != 0 {
		return false
	}
	defer close(fd)

	_, write_err := write(fd, data)
	return write_err == 0
}

write_ptr :: proc(fd: Handle, data: rawptr, len: int) -> (int, Errno) {
	return write(fd, ([^]byte)(data)[:len])
}

read_ptr :: proc(fd: Handle, data: rawptr, len: int) -> (int, Errno) {
	return read(fd, ([^]byte)(data)[:len])
}

heap_allocator_proc :: runtime.heap_allocator_proc
heap_allocator :: runtime.heap_allocator

heap_alloc  :: runtime.heap_alloc
heap_resize :: runtime.heap_resize
heap_free   :: runtime.heap_free

processor_core_count :: proc() -> int {
	return _processor_core_count()
}
