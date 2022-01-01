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



read_entire_file :: proc(name: string, allocator := context.allocator) -> ([]byte, Error) {
	f, ferr := open(name)
	if ferr != nil {
		return nil, ferr
	}
	defer close(f)

	size: int
	if size64, err := file_size(f); err == nil {
		if i64(int(size64)) != size64 {
			size = int(size64)
		}
	}
	size += 1 // for EOF

	// TODO(bill): Is this correct logic?
	total: int
	data := make([]byte, size, allocator)
	for {
		n, err := read(f, data[total:])
		total += n
		if err != nil {
			if err == .EOF {
				err = nil
			}
			return data[:total], err
		}
	}
}

write_entire_file :: proc(name: string, data: []byte, perm: File_Mode, truncate := true) -> Error {
	flags := O_WRONLY|O_CREATE
	if truncate {
		flags |= O_TRUNC
	}
	f, err := open_file(name, flags, perm)
	if err != nil {
		return err
	}
	_, err = write(f, data)
	if cerr := close(f); cerr != nil && err == nil {
		err = cerr
	}
	return err
}

