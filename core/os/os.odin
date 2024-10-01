package os

import "base:intrinsics"
import "base:runtime"
import "core:io"
import "core:strconv"
import "core:unicode/utf8"


OS :: ODIN_OS
ARCH :: ODIN_ARCH
ENDIAN :: ODIN_ENDIAN

SEEK_SET :: 0
SEEK_CUR :: 1
SEEK_END :: 2

write_string :: proc(fd: Handle, str: string) -> (int, Error) {
	return write(fd, transmute([]byte)str)
}

write_byte :: proc(fd: Handle, b: byte) -> (int, Error) {
	return write(fd, []byte{b})
}

write_rune :: proc(fd: Handle, r: rune) -> (int, Error) {
	if r < utf8.RUNE_SELF {
		return write_byte(fd, byte(r))
	}

	b, n := utf8.encode_rune(r)
	return write(fd, b[:n])
}

write_encoded_rune :: proc(f: Handle, r: rune) -> (n: int, err: Error) {
	wrap :: proc(m: int, merr: Error, n: ^int, err: ^Error) -> bool {
		n^ += m
		if merr != nil {
			err^ = merr
			return true
		}
		return false
	}

	if wrap(write_byte(f, '\''), &n, &err) { return }

	switch r {
	case '\a': if wrap(write_string(f, "\\a"), &n, &err) { return }
	case '\b': if wrap(write_string(f, "\\b"), &n, &err) { return }
	case '\e': if wrap(write_string(f, "\\e"), &n, &err) { return }
	case '\f': if wrap(write_string(f, "\\f"), &n, &err) { return }
	case '\n': if wrap(write_string(f, "\\n"), &n, &err) { return }
	case '\r': if wrap(write_string(f, "\\r"), &n, &err) { return }
	case '\t': if wrap(write_string(f, "\\t"), &n, &err) { return }
	case '\v': if wrap(write_string(f, "\\v"), &n, &err) { return }
	case:
		if r < 32 {
			if wrap(write_string(f, "\\x"), &n, &err) { return }
			b: [2]byte
			s := strconv.append_bits(b[:], u64(r), 16, true, 64, strconv.digits, nil)
			switch len(s) {
			case 0: if wrap(write_string(f, "00"), &n, &err) { return }
			case 1: if wrap(write_rune(f, '0'), &n, &err)    { return }
			case 2: if wrap(write_string(f, s), &n, &err)    { return }
			}
		} else {
			if wrap(write_rune(f, r), &n, &err) { return }
		}
	}
	_ = wrap(write_byte(f, '\''), &n, &err)
	return
}

read_at_least :: proc(fd: Handle, buf: []byte, min: int) -> (n: int, err: Error) {
	if len(buf) < min {
		return 0, io.Error.Short_Buffer
	}
	nn := max(int)
	for nn > 0 && n < min && err == nil {
		nn, err = read(fd, buf[n:])
		n += nn
	}
	if n >= min {
		err = nil
	}
	return
}

read_full :: proc(fd: Handle, buf: []byte) -> (n: int, err: Error) {
	return read_at_least(fd, buf, len(buf))
}


@(require_results)
file_size_from_path :: proc(path: string) -> i64 {
	fd, err := open(path, O_RDONLY, 0)
	if err != nil {
		return -1
	}
	defer close(fd)

	length: i64
	if length, err = file_size(fd); err != nil {
		return -1
	}
	return length
}

@(require_results)
read_entire_file_from_filename :: proc(name: string, allocator := context.allocator, loc := #caller_location) -> (data: []byte, success: bool) {
	err: Error
	data, err = read_entire_file_from_filename_or_err(name, allocator, loc)
	success = err == nil
	return
}

@(require_results)
read_entire_file_from_handle :: proc(fd: Handle, allocator := context.allocator, loc := #caller_location) -> (data: []byte, success: bool) {
	err: Error
	data, err = read_entire_file_from_handle_or_err(fd, allocator, loc)
	success = err == nil
	return
}

read_entire_file :: proc {
	read_entire_file_from_filename,
	read_entire_file_from_handle,
}

@(require_results)
read_entire_file_from_filename_or_err :: proc(name: string, allocator := context.allocator, loc := #caller_location) -> (data: []byte, err: Error) {
	context.allocator = allocator

	fd := open(name, O_RDONLY, 0) or_return
	defer close(fd)

	return read_entire_file_from_handle_or_err(fd, allocator, loc)
}

@(require_results)
read_entire_file_from_handle_or_err :: proc(fd: Handle, allocator := context.allocator, loc := #caller_location) -> (data: []byte, err: Error) {
	context.allocator = allocator

	length := file_size(fd) or_return
	if length <= 0 {
		return nil, nil
	}

	data = make([]byte, int(length), allocator, loc) or_return
	if data == nil {
		return nil, nil
	}
	defer if err != nil {
		delete(data, allocator)
	}

	bytes_read := read_full(fd, data) or_return
	data = data[:bytes_read]
	return
}

read_entire_file_or_err :: proc {
	read_entire_file_from_filename_or_err,
	read_entire_file_from_handle_or_err,
}


write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (success: bool) {
	return write_entire_file_or_err(name, data, truncate) == nil
}

@(require_results)
write_entire_file_or_err :: proc(name: string, data: []byte, truncate := true) -> Error {
	flags: int = O_WRONLY|O_CREATE
	if truncate {
		flags |= O_TRUNC
	}

	mode: int = 0
	when OS == .Linux || OS == .Darwin {
		// NOTE(justasd): 644 (owner read, write; group read; others read)
		mode = S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH
	}

	fd := open(name, flags, mode) or_return
	defer close(fd)

	for n := 0; n < len(data); {
		n += write(fd, data[n:]) or_return
	}
	return nil
}

write_ptr :: proc(fd: Handle, data: rawptr, len: int) -> (int, Error) {
	return write(fd, ([^]byte)(data)[:len])
}

read_ptr :: proc(fd: Handle, data: rawptr, len: int) -> (int, Error) {
	return read(fd, ([^]byte)(data)[:len])
}

heap_allocator_proc :: runtime.heap_allocator_proc
heap_allocator :: runtime.heap_allocator

heap_alloc  :: runtime.heap_alloc
heap_resize :: runtime.heap_resize
heap_free   :: runtime.heap_free

@(require_results)
processor_core_count :: proc() -> int {
	return _processor_core_count()
}
