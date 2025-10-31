package os2

import "base:runtime"
import "core:strconv"
import "core:unicode/utf8"

write_string :: proc(f: ^File, s: string) -> (n: int, err: Error) {
	return write(f, transmute([]byte)s)
}

write_strings :: proc(f: ^File, strings: ..string) -> (n: int, err: Error) {
	for s in strings {
		m: int
		m, err = write_string(f, s)
		n += m
		if err != nil {
			return
		}
	}
	return
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
			s := strconv.write_bits(b[:], u64(r), 16, true, 64, strconv.digits, nil)
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

read_at_least :: proc(f: ^File, buf: []byte, min: int) -> (n: int, err: Error) {
	if len(buf) < min {
		return 0, .Short_Buffer
	}
	nn := max(int)
	for nn > 0 && n < min && err == nil {
		nn, err = read(f, buf[n:])
		n += nn
	}
	if n >= min {
		err = nil
	}
	return
}

read_full :: proc(f: ^File, buf: []byte) -> (n: int, err: Error) {
	return read_at_least(f, buf, len(buf))
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

@(require_results)
read_entire_file_from_path :: proc(name: string, allocator: runtime.Allocator, loc := #caller_location) -> (data: []byte, err: Error) {
	f := open(name) or_return
	defer close(f)
	return read_entire_file_from_file(f, allocator, loc)
}

@(require_results)
read_entire_file_from_file :: proc(f: ^File, allocator: runtime.Allocator, loc := #caller_location) -> (data: []byte, err: Error) {
	size: int
	has_size := false
	if size64, serr := file_size(f); serr == nil {
		if i64(int(size64)) == size64 {
			has_size = true
			size = int(size64)
		}
	}

	if has_size && size > 0 {
		total: int
		data = make([]byte, size, allocator, loc) or_return
		for total < len(data) {
			n: int
			n, err = read(f, data[total:])
			total += n
			if err != nil {
				if err == .EOF {
					err = nil
				}
				data = data[:total]
				break
			}
		}
		return
	} else {
		buffer: [1024]u8
		out_buffer := make([dynamic]u8, 0, 0, allocator, loc)
		total := 0
		for {
			n: int
			n, err = read(f, buffer[:])
			total += n
			append_elems(&out_buffer, ..buffer[:n], loc=loc) or_return
			if err != nil {
				if err == .EOF || err == .Broken_Pipe {
					err = nil
				}
				data = out_buffer[:total]
				return
			}
		}
	}
}

read_entire_file_as_cstring :: proc{
	read_entire_file_from_path_as_cstring,
	read_entire_file_from_file_as_cstring,
}

@(require_results)
read_entire_file_from_path_as_cstring :: proc(name: string, allocator: runtime.Allocator) -> (data: cstring, size: int, err: Error) {
	f := open(name) or_return
	defer close(f)
	return read_entire_file_from_file_as_cstring(f, allocator)
}

@(require_results)
read_entire_file_from_file_as_cstring :: proc(f: ^File, allocator: runtime.Allocator) -> (data: cstring, size: int, err: Error) {

	has_size := false
	if size64, serr := file_size(f); serr == nil {
		if i64(int(size64)) == size64 {
			has_size = true
			size = int(size64)
		}
	}

	if has_size && size > 0 {
		total: int
		// one extra byte for null terminator
		buffer := make([]byte, size + 1, allocator) or_return
		data = cstring(raw_data(buffer))
		for total < size {
			n: int
			n, err = read(f, buffer[total:size])
			total += n
			if err != nil {
				if err == .EOF {
					err = nil
				}
				size = total
				break
			}
		}
		return
	} else {
		buffer: [1024]u8
		out_buffer := make([dynamic]u8, 0, 0, allocator)
		data = cstring(raw_data(out_buffer))
		for {
			n: int
			n, err = read(f, buffer[:])
			append_elems(&out_buffer, ..buffer[:n]) or_return
			size += n
			data = cstring(raw_data(out_buffer))
			if err != nil {
				if err == .EOF || err == .Broken_Pipe {
					err = nil
				}
				append_nothing(&out_buffer) or_return // null terminator
				data = cstring(raw_data(out_buffer))
				return
			}
		}
	}
}

@(require_results)
write_entire_file :: proc(name: string, data: []byte, perm := Permissions_Read_All + {.Write_User}, truncate := true) -> Error {
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

