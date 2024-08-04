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


@(require_results, no_instrumentation)
get_last_error :: proc "contextless" () -> Error {
	return _get_last_error()
}

@(require_results)
open :: proc(path: string, flags: int = O_RDWR, mode: int = 0) -> (handle: Handle, err: Error) {
	return _open(path, flags, mode)
}

close :: proc(fd: Handle) -> Error {
	return _close(fd)
}

flush :: proc(fd: Handle) -> Error {
	return _flush(fd)
}

write :: proc(fd: Handle, data: []byte) -> (int, Error) {
	return _write(fd, data)
}
read :: proc(fd: Handle, data: []byte) -> (int, Error) {
	return _read(fd, data)
}
read_at :: proc(fd: Handle, data: []byte, offset: i64) -> (int, Error) {
	return _read_at(fd, data, offset)
}
write_at :: proc(fd: Handle, data: []byte, offset: i64) -> (int, Error) {
	return _write_at(fd, data, offset)
}
seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Error) {
	return _seek(fd, offset, whence)
}

@(require_results)
last_write_time :: proc(fd: Handle) -> (time: File_Time, err: Error) {
	return _last_write_time(fd)
}

@(require_results)
last_write_time_by_name :: proc(name: string) -> (time: File_Time, err: Error) {
	return _last_write_time_by_name(name)
}

@(require_results)
is_path_separator_rune :: proc "contextless" (r: rune) -> bool {
	return _is_path_separator(r)
}
@(require_results)
is_path_separator_byte :: proc "contextless" (b: byte) -> bool {
	return _is_path_separator(rune(b))
}

is_path_separator :: proc{
	is_path_separator_rune,
	is_path_separator_byte,
}

@(require_results)
is_file_handle :: proc(fd: Handle) -> bool {
	return _is_file_handle(fd)
}

@(require_results)
is_file_path :: proc(path: string, follow_links: bool = true) -> bool {
	return _is_file_path(path, follow_links)
}

@(require_results)
is_dir_handle :: proc(fd: Handle) -> bool {
	return _is_dir_handle(fd)
}

@(require_results)
is_dir_path :: proc(path: string, follow_links: bool = true) -> bool {
	return _is_dir_path(path, follow_links)
}

is_file :: proc {is_file_path, is_file_handle}
is_dir :: proc {is_dir_path, is_dir_handle}


@(require_results)
file_size :: proc(fd: Handle) -> (i64, Error) {
	return _file_size(fd)
}

@(require_results)
exists :: proc(path: string) -> bool {
	return _exists(path)
}

rename :: proc(old, new: string) -> Error {
	return _rename(old, new)
}

remove :: proc(path: string) -> Error {
	return _remove(path)
}

link :: proc(old_name, new_name: string) -> (err: Error) {
	return _link(old_name, new_name)
}
unlink :: proc(path: string) -> (err: Error) {
	return _unlink(path)
}
ftruncate :: proc(fd: Handle, length: i64) -> (err: Error) {
	return _ftruncate(fd, length)
}

truncate :: proc(path: string, length: i64) -> (err: Error) {
	return _truncate(path, length)
}


@(require_results)
pipe :: proc() -> (r, w: Handle, err: Error) {
	return _pipe()
}

@(require_results)
read_dir :: proc(fd: Handle, n: int, allocator := context.allocator) -> (fi: []File_Info, err: Error) {
	return _read_dir(fd, n, allocator)
}



@(require_results)
absolute_path_from_handle :: proc(fd: Handle) -> (path: string, err: Error) {
	return _absolute_path_from_handle(fd)
}
@(require_results)
absolute_path_from_relative :: proc(rel: string) -> (path: string, err: Error) {
	return _absolute_path_from_relative(rel)
}

access :: proc(path: string, mask: int) -> (bool, Error) {
	return _access(path, mask)
}


@(require_results)
environ :: proc(allocator := context.allocator) -> []string {
	return _environ(allocator)
}
@(require_results)
lookup_env :: proc(key: string, allocator := context.allocator) -> (value: string, found: bool) {
	return _lookup_env(key, allocator)
}

@(require_results)
get_env :: proc(key: string, allocator := context.allocator) -> (value: string) {
	return _get_env(key, allocator)
}

set_env :: proc(key, value: string) -> Error {
	return _set_env(key, value)
}
unset_env :: proc(key: string) -> Error {
	return _unset_env(key)
}

clear_env :: proc() {
	_clear_env()
}


@(require_results)
get_current_directory :: proc() -> string {
	return _get_current_directory()
}


set_current_directory :: proc(path: string) -> (err: Error) {
	return _set_current_directory(path)
}

change_directory :: set_current_directory


make_directory :: proc(path: string, mode: u32 = 0o775) -> Error {
	return _make_directory(path, mode)
}

remove_directory :: proc(path: string) -> Error {
	return _remove_directory(path)
}

exit :: proc "contextless" (code: int) -> ! {
	_exit(code)
}

@(require_results)
current_thread_id :: proc "contextless" () -> int {
	return _current_thread_id()
}

@(require_results)
get_page_size :: proc() -> int {
	return _get_page_size()
}


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

	_ = write(fd, data) or_return
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
