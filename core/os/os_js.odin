//+build js
package os

import "base:runtime"


@(require_results, no_instrumentation)
_get_last_error :: proc "contextless" () -> Error {
	return nil
}

@(require_results)
_is_path_separator :: proc "contextless" (c: rune) -> bool {
	return c == '/' || c == '\\'
}

@(require_results)
_open :: proc(path: string, mode: int = O_RDONLY, perm: int = 0) -> (Handle, Error) {
	unimplemented("core:os procedure not supported on JS target")
}

_close :: proc(fd: Handle) -> Error {
	unimplemented("core:os procedure not supported on JS target")
}

_flush :: proc(fd: Handle) -> (err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}



_write :: proc(fd: Handle, data: []byte) -> (int, Error) {
	unimplemented("core:os procedure not supported on JS target")
}

@(private="file")
_read_console :: proc(handle: Handle, b: []byte) -> (n: int, err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}

_read :: proc(fd: Handle, data: []byte) -> (int, Error) {
	unimplemented("core:os procedure not supported on JS target")
}

_seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Error) {
	unimplemented("core:os procedure not supported on JS target")
}

@(require_results)
_file_size :: proc(fd: Handle) -> (i64, Error) {
	unimplemented("core:os procedure not supported on JS target")
}


@(private)
MAX_RW :: 1<<30

@(private)
pread :: proc(fd: Handle, data: []byte, offset: i64) -> (int, Error) {
	unimplemented("core:os procedure not supported on JS target")
}
@(private)
pwrite :: proc(fd: Handle, data: []byte, offset: i64) -> (int, Error) {
	unimplemented("core:os procedure not supported on JS target")
}

_read_at :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}
_write_at :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}

stdout: Handle = 1
stderr: Handle = 2

@(require_results)
get_std_handle :: proc "contextless" (h: uint) -> Handle {
	context = runtime.default_context()
	unimplemented("core:os procedure not supported on JS target")
}


@(require_results)
_exists :: proc(path: string) -> bool {
	unimplemented("core:os procedure not supported on JS target")
}

@(require_results)
_is_file_path :: proc(path: string, _: bool) -> bool {
	unimplemented("core:os procedure not supported on JS target")
}

@(require_results)
_is_dir_path :: proc(path: string, _: bool) -> bool {
	unimplemented("core:os procedure not supported on JS target")
}

@(require_results)
_is_file_handle :: proc(handle: Handle) -> bool {
	unimplemented("core:os procedure not supported on JS target")
}

@(require_results)
_is_dir_handle :: proc(handle: Handle) -> bool {
	unimplemented("core:os procedure not supported on JS target")
}

// NOTE(tetra): GetCurrentDirectory is not thread safe with SetCurrentDirectory and GetFullPathName
//@private cwd_lock := win32.SRWLOCK{} // zero is initialized

@(require_results)
_get_current_directory :: proc(allocator := context.allocator) -> string {
	unimplemented("core:os procedure not supported on JS target")
}

_set_current_directory :: proc(path: string) -> (err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}



_change_directory :: proc(path: string) -> (err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}

_make_directory :: proc(path: string, mode: u32 = 0) -> (err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}


_remove_directory :: proc(path: string) -> (err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}



@(private, require_results)
is_abs :: proc(path: string) -> bool {
	unimplemented("core:os procedure not supported on JS target")
}

@(private, require_results)
fix_long_path :: proc(path: string) -> string {
	unimplemented("core:os procedure not supported on JS target")
}


_link :: proc(old_name, new_name: string) -> (err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}

_unlink :: proc(path: string) -> (err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}



_rename :: proc(old_path, new_path: string) -> (err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}


_ftruncate :: proc(fd: Handle, length: i64) -> (err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}

_truncate :: proc(path: string, length: i64) -> (err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}


_remove :: proc(name: string) -> Error {
	unimplemented("core:os procedure not supported on JS target")
}


@(require_results)
_pipe :: proc() -> (r, w: Handle, err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}

@(require_results)
_read_dir :: proc(fd: Handle, n: int, allocator := context.allocator) -> (fi: []File_Info, err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}

Handle    :: distinct uintptr
File_Time :: distinct u64

_Platform_Error :: enum i32 {
	NONE = 0,
	FILE_NOT_FOUND      = 2,
	PATH_NOT_FOUND      = 3,
	ACCESS_DENIED       = 5,
	INVALID_HANDLE      = 6,
	NOT_ENOUGH_MEMORY   = 8,
	NO_MORE_FILES       = 18,
	HANDLE_EOF          = 38,
	NETNAME_DELETED     = 64,
	FILE_EXISTS         = 80,
	INVALID_PARAMETER   = 87,
	BROKEN_PIPE         = 109,
	BUFFER_OVERFLOW     = 111,
	INSUFFICIENT_BUFFER = 122,
	MOD_NOT_FOUND       = 126,
	PROC_NOT_FOUND      = 127,
	DIR_NOT_EMPTY       = 145,
	ALREADY_EXISTS      = 183,
	ENVVAR_NOT_FOUND    = 203,
	MORE_DATA           = 234,
	OPERATION_ABORTED   = 995,
	IO_PENDING          = 997,
	NOT_FOUND           = 1168,
	PRIVILEGE_NOT_HELD  = 1314,
	WSAEACCES             = 10013,
	WSAECONNRESET         = 10054,

	// Windows reserves errors >= 1<<29 for application use
	FILE_IS_PIPE    = 1<<29 + 0,
	FILE_IS_NOT_DIR = 1<<29 + 1,
	NEGATIVE_OFFSET = 1<<29 + 2,
}


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


ERROR_FILE_NOT_FOUND      :: Platform_Error.FILE_NOT_FOUND
ERROR_PATH_NOT_FOUND      :: Platform_Error.PATH_NOT_FOUND
ERROR_ACCESS_DENIED       :: Platform_Error.ACCESS_DENIED
ERROR_INVALID_HANDLE      :: Platform_Error.INVALID_HANDLE
ERROR_NOT_ENOUGH_MEMORY   :: Platform_Error.NOT_ENOUGH_MEMORY
ERROR_NO_MORE_FILES       :: Platform_Error.NO_MORE_FILES
ERROR_HANDLE_EOF          :: Platform_Error.HANDLE_EOF
ERROR_NETNAME_DELETED     :: Platform_Error.NETNAME_DELETED
ERROR_FILE_EXISTS         :: Platform_Error.FILE_EXISTS
ERROR_INVALID_PARAMETER   :: Platform_Error.INVALID_PARAMETER
ERROR_BROKEN_PIPE         :: Platform_Error.BROKEN_PIPE
ERROR_BUFFER_OVERFLOW     :: Platform_Error.BUFFER_OVERFLOW
ERROR_INSUFFICIENT_BUFFER :: Platform_Error.INSUFFICIENT_BUFFER
ERROR_MOD_NOT_FOUND       :: Platform_Error.MOD_NOT_FOUND
ERROR_PROC_NOT_FOUND      :: Platform_Error.PROC_NOT_FOUND
ERROR_DIR_NOT_EMPTY       :: Platform_Error.DIR_NOT_EMPTY
ERROR_ALREADY_EXISTS      :: Platform_Error.ALREADY_EXISTS
ERROR_ENVVAR_NOT_FOUND    :: Platform_Error.ENVVAR_NOT_FOUND
ERROR_MORE_DATA           :: Platform_Error.MORE_DATA
ERROR_OPERATION_ABORTED   :: Platform_Error.OPERATION_ABORTED
ERROR_IO_PENDING          :: Platform_Error.IO_PENDING
ERROR_NOT_FOUND           :: Platform_Error.NOT_FOUND
ERROR_PRIVILEGE_NOT_HELD  :: Platform_Error.PRIVILEGE_NOT_HELD
WSAEACCES                 :: Platform_Error.WSAEACCES
WSAECONNRESET             :: Platform_Error.WSAECONNRESET

ERROR_FILE_IS_PIPE        :: General_Error.File_Is_Pipe
ERROR_FILE_IS_NOT_DIR     :: General_Error.Not_Dir

// "Argv" arguments converted to Odin strings
args := _alloc_command_line_arguments()





@(require_results)
_last_write_time :: proc(fd: Handle) -> (File_Time, Error) {
	unimplemented("core:os procedure not supported on JS target")
}

@(require_results)
_last_write_time_by_name :: proc(name: string) -> (File_Time, Error) {
	unimplemented("core:os procedure not supported on JS target")
}


@(require_results)
_get_page_size :: proc() -> int {
	return 1<<16
}

@(private, require_results)
_processor_core_count :: proc() -> int {
	unimplemented("core:os procedure not supported on JS target")
}

_exit :: proc "contextless" (code: int) -> ! {
	context = runtime.default_context()
	unimplemented("core:os procedure not supported on JS target")
}



@(require_results)
_current_thread_id :: proc "contextless" () -> int {
	context = runtime.default_context()
	unimplemented("core:os procedure not supported on JS target")
}



@(require_results)
_alloc_command_line_arguments :: proc() -> []string {
	return nil
}

@(require_results)
_absolute_path_from_handle :: proc(fd: Handle) -> (path: string, err: Error) {
	unimplemented("TODO: _absolute_path_from_handle")
}
@(require_results)
_absolute_path_from_relative :: proc(rel: string) -> (path: string, err: Error) {
	unimplemented("TODO: _absolute_path_from_relative")
}

_access :: proc(path: string, mask: int) -> (bool, Error) {
	unimplemented("TODO: _access")
}


@(require_results)
_environ :: proc(allocator := context.allocator) -> []string {
	unimplemented("TODO: _environ")
}
@(require_results)
_lookup_env :: proc(key: string, allocator := context.allocator) -> (value: string, found: bool) {
	unimplemented("TODO: _lookup_env")
}

@(require_results)
_get_env :: proc(key: string, allocator := context.allocator) -> (value: string) {
	unimplemented("TODO: _get_env")
}

_set_env :: proc(key, value: string) -> Error {
	unimplemented("TODO: _set_env")
}
_unset_env :: proc(key: string) -> Error {
	unimplemented("TODO: _unset_env")
}

_clear_env :: proc() {
	unimplemented("TODO: _clear_env")
}
