package os2

import "base:runtime"
import "core:strconv"
import "core:unicode/utf8"

write_string :: proc(f: ^File, s: string) -> (n: int, err: Error) {
	return write(f, transmute([]byte)s)
}

write_byte :: proc(f: ^File, b: byte) -> (n: int, err: Error) {
	return write(f, []byte{b})
}

write_rune :: proc(f: ^File, r: rune) -> (n: int, err: Error) {
	if r < utf8.RUNE_SELF {
		return write_byte(f, byte(r))
	}

	b: [4]byte
	b, n = utf8.encode_rune(r)
	return write(f, b[:n])
}

write_encoded_rune :: proc(f: ^File, r: rune) -> (n: int, err: Error) {
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


write_ptr :: proc(f: ^File, data: rawptr, len: int) -> (n: int, err: Error) {
	return write(f, ([^]byte)(data)[:len])
}

read_ptr :: proc(f: ^File, data: rawptr, len: int) -> (n: int, err: Error) {
	return read(f, ([^]byte)(data)[:len])
}


read_entire_file :: proc{
	read_entire_file_from_path,
	read_entire_file_from_file,
}

read_entire_file_from_path :: proc(name: string, allocator: runtime.Allocator) -> (data: []byte, err: Error) {
	f, ferr := open(name)
	if ferr != nil {
		return nil, ferr
	}
	defer close(f)
	return read_entire_file_from_file(f, allocator)
}

read_entire_file_from_file :: proc(f: ^File, allocator: runtime.Allocator) -> (data: []byte, err: Error) {
	size: int
	if size64, err := file_size(f); err == nil {
		if i64(int(size64)) != size64 {
			size = int(size64)
		}
	}
	size += 1 // for EOF

	// TODO(bill): Is this correct logic?
	total: int
	data = make([]byte, size, allocator) or_return
	for {
		n: int
		n, err = read(f, data[total:])
		total += n
		if err != nil {
			if err == .EOF {
				err = nil
			}
			data = data[:total]
			return
		}
	}
}

write_entire_file :: proc(name: string, data: []byte, perm: File_Mode, truncate := true) -> Error {
	flags := O_WRONLY|O_CREATE
	if truncate {
		flags |= O_TRUNC
	}
	f, err := open(name, flags, perm)
	if err != nil {
		return err
	}
	_, err = write(f, data)
	if cerr := close(f); cerr != nil && err == nil {
		err = cerr
	}
	return err
}

