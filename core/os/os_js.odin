//+build js
package os

import "base:runtime"

is_path_separator :: proc(c: byte) -> bool {
	return c == '/' || c == '\\'
}

open :: proc(path: string, mode: int = O_RDONLY, perm: int = 0) -> (Handle, Errno) {
	unimplemented("core:os procedure not supported on JS target")
}

close :: proc(fd: Handle) -> Errno {
	unimplemented("core:os procedure not supported on JS target")
}

flush :: proc(fd: Handle) -> (err: Errno) {
	unimplemented("core:os procedure not supported on JS target")
}



write :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	unimplemented("core:os procedure not supported on JS target")
}

@(private="file")
read_console :: proc(handle: Handle, b: []byte) -> (n: int, err: Errno) {
	unimplemented("core:os procedure not supported on JS target")
}

read :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	unimplemented("core:os procedure not supported on JS target")
}

seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Errno) {
	unimplemented("core:os procedure not supported on JS target")
}

file_size :: proc(fd: Handle) -> (i64, Errno) {
	unimplemented("core:os procedure not supported on JS target")
}


@(private)
MAX_RW :: 1<<30

@(private)
pread :: proc(fd: Handle, data: []byte, offset: i64) -> (int, Errno) {
	unimplemented("core:os procedure not supported on JS target")
}
@(private)
pwrite :: proc(fd: Handle, data: []byte, offset: i64) -> (int, Errno) {
	unimplemented("core:os procedure not supported on JS target")
}

read_at :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Errno) {
	unimplemented("core:os procedure not supported on JS target")
}
write_at :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Errno) {
	unimplemented("core:os procedure not supported on JS target")
}

stdout: Handle = 1
stderr: Handle = 2

get_std_handle :: proc "contextless" (h: uint) -> Handle {
	context = runtime.default_context()
	unimplemented("core:os procedure not supported on JS target")
}


exists :: proc(path: string) -> bool {
	unimplemented("core:os procedure not supported on JS target")
}

is_file :: proc(path: string) -> bool {
	unimplemented("core:os procedure not supported on JS target")
}

is_dir :: proc(path: string) -> bool {
	unimplemented("core:os procedure not supported on JS target")
}

// NOTE(tetra): GetCurrentDirectory is not thread safe with SetCurrentDirectory and GetFullPathName
//@private cwd_lock := win32.SRWLOCK{} // zero is initialized

get_current_directory :: proc(allocator := context.allocator) -> string {
	unimplemented("core:os procedure not supported on JS target")
}

set_current_directory :: proc(path: string) -> (err: Errno) {
	unimplemented("core:os procedure not supported on JS target")
}



change_directory :: proc(path: string) -> (err: Errno) {
	unimplemented("core:os procedure not supported on JS target")
}

make_directory :: proc(path: string, mode: u32 = 0) -> (err: Errno) {
	unimplemented("core:os procedure not supported on JS target")
}


remove_directory :: proc(path: string) -> (err: Errno) {
	unimplemented("core:os procedure not supported on JS target")
}



@(private)
is_abs :: proc(path: string) -> bool {
	unimplemented("core:os procedure not supported on JS target")
}

@(private)
fix_long_path :: proc(path: string) -> string {
	unimplemented("core:os procedure not supported on JS target")
}


link :: proc(old_name, new_name: string) -> (err: Errno) {
	unimplemented("core:os procedure not supported on JS target")
}

unlink :: proc(path: string) -> (err: Errno) {
	unimplemented("core:os procedure not supported on JS target")
}



rename :: proc(old_path, new_path: string) -> (err: Errno) {
	unimplemented("core:os procedure not supported on JS target")
}


ftruncate :: proc(fd: Handle, length: i64) -> (err: Errno) {
	unimplemented("core:os procedure not supported on JS target")
}

truncate :: proc(path: string, length: i64) -> (err: Errno) {
	unimplemented("core:os procedure not supported on JS target")
}


remove :: proc(name: string) -> Errno {
	unimplemented("core:os procedure not supported on JS target")
}


pipe :: proc() -> (r, w: Handle, err: Errno) {
	unimplemented("core:os procedure not supported on JS target")
}

read_dir :: proc(fd: Handle, n: int, allocator := context.allocator) -> (fi: []File_Info, err: Errno) {
	unimplemented("core:os procedure not supported on JS target")
}

Handle    :: distinct uintptr
File_Time :: distinct u64
Errno     :: distinct int


INVALID_HANDLE :: ~Handle(0)



O_RDONLY   :: 0x00000
O_WRONLY   :: 0x00001
O_RDWR     :: 0x00002
O_CREATE   :: 0x00040
O_EXCL     :: 0x00080
O_NOCTTY   :: 0x00100
O_TRUNC    :: 0x00200
O_NONBLOCK :: 0x00800
O_APPEND   :: 0x00400
O_SYNC     :: 0x01000
O_ASYNC    :: 0x02000
O_CLOEXEC  :: 0x80000


ERROR_NONE:                   Errno : 0
ERROR_FILE_NOT_FOUND:         Errno : 2
ERROR_PATH_NOT_FOUND:         Errno : 3
ERROR_ACCESS_DENIED:          Errno : 5
ERROR_INVALID_HANDLE:         Errno : 6
ERROR_NOT_ENOUGH_MEMORY:      Errno : 8
ERROR_NO_MORE_FILES:          Errno : 18
ERROR_HANDLE_EOF:             Errno : 38
ERROR_NETNAME_DELETED:        Errno : 64
ERROR_FILE_EXISTS:            Errno : 80
ERROR_INVALID_PARAMETER:      Errno : 87
ERROR_BROKEN_PIPE:            Errno : 109
ERROR_BUFFER_OVERFLOW:        Errno : 111
ERROR_INSUFFICIENT_BUFFER:    Errno : 122
ERROR_MOD_NOT_FOUND:          Errno : 126
ERROR_PROC_NOT_FOUND:         Errno : 127
ERROR_DIR_NOT_EMPTY:          Errno : 145
ERROR_ALREADY_EXISTS:         Errno : 183
ERROR_ENVVAR_NOT_FOUND:       Errno : 203
ERROR_MORE_DATA:              Errno : 234
ERROR_OPERATION_ABORTED:      Errno : 995
ERROR_IO_PENDING:             Errno : 997
ERROR_NOT_FOUND:              Errno : 1168
ERROR_PRIVILEGE_NOT_HELD:     Errno : 1314
WSAEACCES:                    Errno : 10013
WSAECONNRESET:                Errno : 10054

// Windows reserves errors >= 1<<29 for application use
ERROR_FILE_IS_PIPE:           Errno : 1<<29 + 0
ERROR_FILE_IS_NOT_DIR:        Errno : 1<<29 + 1
ERROR_NEGATIVE_OFFSET:        Errno : 1<<29 + 2

// "Argv" arguments converted to Odin strings
args := _alloc_command_line_arguments()





last_write_time :: proc(fd: Handle) -> (File_Time, Errno) {
	unimplemented("core:os procedure not supported on JS target")
}

last_write_time_by_name :: proc(name: string) -> (File_Time, Errno) {
	unimplemented("core:os procedure not supported on JS target")
}


get_page_size :: proc() -> int {
	unimplemented("core:os procedure not supported on JS target")
}

@(private)
_processor_core_count :: proc() -> int {
	unimplemented("core:os procedure not supported on JS target")
}

exit :: proc "contextless" (code: int) -> ! {
	context = runtime.default_context()
	unimplemented("core:os procedure not supported on JS target")
}



current_thread_id :: proc "contextless" () -> int {
	context = runtime.default_context()
	unimplemented("core:os procedure not supported on JS target")
}



_alloc_command_line_arguments :: proc() -> []string {
	return nil
}

