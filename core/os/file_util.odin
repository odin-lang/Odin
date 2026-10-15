package os

import "base:runtime"
import "core:strconv"
import "core:unicode/utf8"

/*
	`write_string` writes a string `s` to file `f`.
	Returns the number of bytes written and an error, if any is encountered.
*/
write_string :: proc(f: ^File, s: string) -> (n: int, err: Error) {
	return write(f, transmute([]byte)s)
}

/*
	`write_strings` writes a variadic list of strings `strings` to file `f`.
	Returns the number of bytes written and an error, if any is encountered.
*/
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
/*
	`write_byte` writes a byte `b` to file `f`.
	Returns the number of bytes written and an error, if any is encountered.
*/
write_byte :: proc(f: ^File, b: byte) -> (n: int, err: Error) {
	return write(f, []byte{b})
}

/*
	`write_rune` writes a rune `r` as an UTF-8 encoded string to file `f`.
	Returns the number of bytes written and an error, if any is encountered.
*/
write_rune :: proc(f: ^File, r: rune) -> (n: int, err: Error) {
	if r < utf8.RUNE_SELF {
		return write_byte(f, byte(r))
	}

	b: [4]byte
	b, n = utf8.encode_rune(r)
	return write(f, b[:n])
}

// TODO xxxx maybe delete this? I think this is too high-level for core/os - just use io/writer for that.
@(deprecated="This writes a quoted rune, not just an encoded one. If that was intended, please call `write_quoted_rune` instead.")
write_encoded_rune :: #force_inline proc(f: ^File, r: rune) -> (n: int, err: Error) {
	return write_quoted_rune(f, r)
}

/*
	`write_quoted_rune` writes a rune `r` as an UTF-8 encoded string which with escaped control codes to file `f`.
	The rune is surrounded with single quotes (`'`), such that it would parse back as a valid rune literal in Odin syntax.
	Returns the number of bytes written and an error, if any is encountered.
*/
// TODO xxxx maybe delete this? I think this is too high-level for core/os - just use io/writer for that.
write_quoted_rune :: proc(f: ^File, r: rune) -> (n: int, err: Error) {
	buf: [strconv.QUOTED_RUNE_MAX_NEEDED_BYTES]byte
	result := strconv.quote_rune(buf[:], r)
	return write_string(f, result)
}

/*
	`write_ptr` is a utility procedure that writes the bytes points at `data` with length `len`.

	It is equivalent to: `write(f, ([^]byte)(data)[:len])`
*/
write_ptr :: proc(f: ^File, data: rawptr, len: int) -> (n: int, err: Error) {
	return write(f, ([^]byte)(data)[:len])
}

/*
	`read_ptr` is a utility procedure that reads the bytes points at `data` with length `len`.

	It is equivalent to: `read(f, ([^]byte)(data)[:len])`
*/
read_ptr :: proc(f: ^File, data: rawptr, len: int) -> (n: int, err: Error) {
	return read(f, ([^]byte)(data)[:len])
}


/*
	`write_slice` is a utility procedure that writes the bytes points at `slice`.

	It is equivalent to: `write(f, ([^]byte)(raw_data(slice))[:len(slice)*size_of(slice[0])])`
*/
write_slice :: proc(f: ^File, slice: $S/[]$T) -> (n: int, err: Error) {
	return write(f, ([^]byte)(raw_data(slice))[:len(slice)*size_of(slice[0])])
}

/*
	`read_slice` is a utility procedure that writes the bytes points at `slice`.

	It is equivalent to: `read(f, ([^]byte)(raw_data(slice))[:len(slice)*size_of(slice[0])])`
*/
read_slice :: proc(f: ^File, slice: $S/[]$T) -> (n: int, err: Error) {
	return read(f, ([^]byte)(raw_data(slice))[:len(slice)*size_of(slice[0])])
}



/*
	`read_at_least` reads from `f` into `buf` until it has read at least `min` bytes.
	It returns the number of bytes copied and an error if fewer bytes were read.
	The error is only an `io.EOF` if no bytes were read.
*/
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

/*
	`read_full` reads exactly `len(buf)` bytes from `f` into `buf`.
	It returns the number of bytes copied and an error if fewer bytes were read.
	The error is only an `io.EOF` if no bytes were read.

	It is equivalent to `read_at_least(f, buf, len(buf))`.
*/
read_full :: proc(f: ^File, buf: []byte) -> (n: int, err: Error) {
	return read_at_least(f, buf, len(buf))
}



read_entire_file :: proc{
	read_entire_file_from_path,
	read_entire_file_from_file,
}

/*
	`read_entire_file_from_path` reads the entire named file `name` into memory allocated with `allocator`.
	A slice of bytes and an error is returned, if any error is encountered.
*/
@(require_results)
read_entire_file_from_path :: proc(name: string, allocator: runtime.Allocator, loc := #caller_location) -> (data: []byte, err: Error) {
	f, ferr := open(name)
	if ferr != nil {
		return nil, ferr
	}
	defer close(f)
	return read_entire_file_from_file(f=f, allocator=allocator, loc=loc)
}

/*
	`read_entire_file_from_file` reads the entire file `f` into memory allocated with `allocator`.
	A slice of bytes and an error is returned, if any error is encountered.
*/
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
		out_buffer := make([dynamic]u8, 0, 0, allocator, loc) or_return
		for {
			n: int
			n, err = read(f, buffer[:])
			if _, aerr := append_elems(&out_buffer, ..buffer[:n], loc=loc); aerr != nil {
				return out_buffer[:], aerr
			}
			if err != nil {
				if err == .EOF || err == .Broken_Pipe {
					err = nil
				}
				data = out_buffer[:]
				return
			}
		}
	}
}

/*
	`write_entire_file` writes the contents of `data` into named file `name`.
	It defaults with the permssions `perm := Permissions_Read_All + {.Write_User}`, and `truncate`s by default.
	An error is returned if any is encountered.
*/
write_entire_file :: proc{
	write_entire_file_from_bytes,
	write_entire_file_from_string,
}

/*
	`write_entire_file_from_bytes` writes the contents of `data` into named file `name`.
	It defaults with the permssions `perm := Permissions_Read_All + {.Write_User}`, and `truncate`s by default.
	An error is returned if any is encountered.
*/
@(require_results)
write_entire_file_from_bytes :: proc(name: string, data: []byte, perm := Permissions_Read_All + {.Write_User}, truncate := true) -> Error {
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



/*
	`write_entire_file_from_string` writes the contents of `data` into named file `name`.
	It defaults with the permssions `perm := Permissions_Read_All + {.Write_User}`, and `truncate`s by default.
	An error is returned if any is encountered.
*/
@(require_results)
write_entire_file_from_string :: proc(name: string, data: string, perm := Permissions_Read_All + {.Write_User}, truncate := true) -> Error {
	return write_entire_file(name, transmute([]byte)data, perm, truncate)
}
