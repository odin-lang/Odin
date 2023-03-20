//+build js
package os

import "core:intrinsics"
import "core:runtime"
import "core:unicode/utf16"

is_path_separator :: proc(c: byte) -> bool {
	return c == '/' || c == '\\'
}

open :: proc(path: string, mode: int = O_RDONLY, perm: int = 0) -> (Handle, Errno) {
	panic("core:os procedure not supported on JS target")
}

close :: proc(fd: Handle) -> Errno {
	panic("core:os procedure not supported on JS target")
}

flush :: proc(fd: Handle) -> (err: Errno) {
	panic("core:os procedure not supported on JS target")
}



write :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	panic("core:os procedure not supported on JS target")
}

@(private="file")
read_console :: proc(handle: win32.HANDLE, b: []byte) -> (n: int, err: Errno) {
	panic("core:os procedure not supported on JS target")
}

read :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	panic("core:os procedure not supported on JS target")
}

seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Errno) {
	panic("core:os procedure not supported on JS target")
}

file_size :: proc(fd: Handle) -> (i64, Errno) {
	panic("core:os procedure not supported on JS target")
}


@(private)
MAX_RW :: 1<<30

@(private)
pread :: proc(fd: Handle, data: []byte, offset: i64) -> (int, Errno) {
	panic("core:os procedure not supported on JS target")
}
@(private)
pwrite :: proc(fd: Handle, data: []byte, offset: i64) -> (int, Errno) {
	panic("core:os procedure not supported on JS target")
}

read_at :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Errno) {
	panic("core:os procedure not supported on JS target")
}
write_at :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Errno) {
	panic("core:os procedure not supported on JS target")
}



// NOTE(bill): Uses startup to initialize it
//stdin  := get_std_handle(uint(win32.STD_INPUT_HANDLE))
//stdout := get_std_handle(uint(win32.STD_OUTPUT_HANDLE))
//stderr := get_std_handle(uint(win32.STD_ERROR_HANDLE))


get_std_handle :: proc "contextless" (h: uint) -> Handle {
	panic("core:os procedure not supported on JS target")
}


exists :: proc(path: string) -> bool {
	panic("core:os procedure not supported on JS target")
}

is_file :: proc(path: string) -> bool {
	panic("core:os procedure not supported on JS target")
}

is_dir :: proc(path: string) -> bool {
	panic("core:os procedure not supported on JS target")
}

// NOTE(tetra): GetCurrentDirectory is not thread safe with SetCurrentDirectory and GetFullPathName
//@private cwd_lock := win32.SRWLOCK{} // zero is initialized

get_current_directory :: proc(allocator := context.allocator) -> string {
	panic("core:os procedure not supported on JS target")
}

set_current_directory :: proc(path: string) -> (err: Errno) {
	panic("core:os procedure not supported on JS target")
}



change_directory :: proc(path: string) -> (err: Errno) {
	panic("core:os procedure not supported on JS target")
}

make_directory :: proc(path: string, mode: u32 = 0) -> (err: Errno) {
	panic("core:os procedure not supported on JS target")
}


remove_directory :: proc(path: string) -> (err: Errno) {
	panic("core:os procedure not supported on JS target")
}



@(private)
is_abs :: proc(path: string) -> bool {
	panic("core:os procedure not supported on JS target")
}

@(private)
fix_long_path :: proc(path: string) -> string {
	panic("core:os procedure not supported on JS target")
}


link :: proc(old_name, new_name: string) -> (err: Errno) {
	panic("core:os procedure not supported on JS target")
}

unlink :: proc(path: string) -> (err: Errno) {
	panic("core:os procedure not supported on JS target")
}



rename :: proc(old_path, new_path: string) -> (err: Errno) {
	panic("core:os procedure not supported on JS target")
}


ftruncate :: proc(fd: Handle, length: i64) -> (err: Errno) {
	panic("core:os procedure not supported on JS target")
}

truncate :: proc(path: string, length: i64) -> (err: Errno) {
	panic("core:os procedure not supported on JS target")
}


remove :: proc(name: string) -> Errno {
	panic("core:os procedure not supported on JS target")
}


pipe :: proc() -> (r, w: Handle, err: Errno) {
	panic("core:os procedure not supported on JS target")
}

