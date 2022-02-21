package os2

import "core:mem"
import "core:strconv"
import "core:unicode/utf8"

write_string :: proc(fd: Handle, s: string) -> (n: int, err: Error) {
	return write(fd, transmute([]byte)s)
}

write_byte :: proc(fd: Handle, b: byte) -> (n: int, err: Error) {
	return write(fd, []byte{b})
}

write_rune :: proc(fd: Handle, r: rune) -> (n: int, err: Error) {
	if r < utf8.RUNE_SELF {
		return write_byte(fd, byte(r))
	}

	b: [4]byte
	b, n = utf8.encode_rune(r)
	return write(fd, b[:n])
}

write_encoded_rune :: proc(fd: Handle, r: rune) -> (n: int, err: Error) {
	wrap :: proc(m: int, merr: Error, n: ^int, err: ^Error) -> bool {
		n^ += m
		if merr != nil {
			err^ = merr
			return true
		}
		return false
	}

	if wrap(write_byte(fd, '\''), &n, &err) { return }

	switch r {
	case '\a': if wrap(write_string(fd, "\\a"), &n, &err) { return }
	case '\b': if wrap(write_string(fd, "\\b"), &n, &err) { return }
	case '\e': if wrap(write_string(fd, "\\e"), &n, &err) { return }
	case '\f': if wrap(write_string(fd, "\\f"), &n, &err) { return }
	case '\n': if wrap(write_string(fd, "\\n"), &n, &err) { return }
	case '\r': if wrap(write_string(fd, "\\r"), &n, &err) { return }
	case '\t': if wrap(write_string(fd, "\\t"), &n, &err) { return }
	case '\v': if wrap(write_string(fd, "\\v"), &n, &err) { return }
	case:
		if r < 32 {
			if wrap(write_string(fd, "\\x"), &n, &err) { return }
			b: [2]byte
			s := strconv.append_bits(b[:], u64(r), 16, true, 64, strconv.digits, nil)
			switch len(s) {
			case 0: if wrap(write_string(fd, "00"), &n, &err) { return }
			case 1: if wrap(write_rune(fd, '0'), &n, &err)    { return }
			case 2: if wrap(write_string(fd, s), &n, &err)    { return }
			}
		} else {
			if wrap(write_rune(fd, r), &n, &err) { return }
		}
	}
	_ = wrap(write_byte(fd, '\''), &n, &err)
	return
}

write_ptr :: proc(fd: Handle, data: rawptr, len: int) -> (n: int, err: Error) {
	s := transmute([]byte)mem.Raw_Slice{data, len}
	return write(fd, s)
}

read_ptr :: proc(fd: Handle, data: rawptr, len: int) -> (n: int, err: Error) {
	s := transmute([]byte)mem.Raw_Slice{data, len}
	return read(fd, s)
}


read_at_least :: proc(fd: Handle, buf: []byte, min: int) -> (n: int, err: Error) {
	if len(buf) < min {
		return 0, .Short_Buffer
	}
	for n < min && err == nil {
		nn: int
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

file_size_from_path :: proc(path: string) -> (length: i64, err: Error) {
	fd := open(path, O_RDONLY, 0) or_return
	defer close(fd)
	return file_size(fd)
}

read_entire_file :: proc{
	read_entire_file_from_path,
	read_entire_file_from_handle,
}

read_entire_file_from_path :: proc(name: string, allocator := context.allocator) -> (data: []byte, err: Error) {
	fd := open(name, {.Read}) or_return
	defer close(fd)
	return read_entire_file_from_handle(fd, allocator)
}

read_entire_file_from_handle :: proc(fd: Handle, allocator := context.allocator) -> (data: []byte, err: Error) {
	length := file_size(fd) or_return
	if length <= 0 {
		return nil, nil
	}

	if i64(int(length)) != length {
		return nil, .Short_Buffer
	}

	data = make([]byte, int(length), allocator)
	if data == nil {
		return nil, .Short_Buffer
	}
	defer if err != nil {
		delete(data, allocator)
	}

	bytes_read := read_full(fd, data) or_return
	return data[:bytes_read], nil
}

write_entire_file :: proc(name: string, data: []byte, perm: File_Mode, truncate := true) -> Error {
	flags := O_WRONLY|O_CREATE
	if truncate {
		flags |= O_TRUNC
	}
	f := open(name, flags, perm) or_return

	_, err := write(f, data)
	if cerr := close(f); cerr != nil && err == nil {
		err = cerr
	}
	return err
}

