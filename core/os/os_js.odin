#+build js
package os

foreign import "odin_env"

@(require_results)
is_path_separator :: proc(c: byte) -> bool {
	return c == '/' || c == '\\'
}

Handle :: distinct u32

stdout: Handle = 1
stderr: Handle = 2

@(require_results)
open :: proc(path: string, mode: int = O_RDONLY, perm: int = 0) -> (Handle, Error) {
	unimplemented("core:os procedure not supported on JS target")
}

close :: proc(fd: Handle) -> Error {
	return nil
}

flush :: proc(fd: Handle) -> (err: Error) {
	return nil
}

write :: proc(fd: Handle, data: []byte) -> (int, Error) {
	foreign odin_env {
		@(link_name="write")
		_write :: proc "contextless" (fd: Handle, p: []byte) ---
	}
	_write(fd, data)
	return len(data), nil
}

read :: proc(fd: Handle, data: []byte) -> (int, Error) {
	unimplemented("core:os procedure not supported on JS target")
}

seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Error) {
	unimplemented("core:os procedure not supported on JS target")
}

@(require_results)
file_size :: proc(fd: Handle) -> (i64, Error) {
	unimplemented("core:os procedure not supported on JS target")
}

read_at :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}
write_at :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}

@(require_results)
exists :: proc(path: string) -> bool {
	unimplemented("core:os procedure not supported on JS target")
}

@(require_results)
is_file :: proc(path: string) -> bool {
	unimplemented("core:os procedure not supported on JS target")
}

@(require_results)
is_dir :: proc(path: string) -> bool {
	unimplemented("core:os procedure not supported on JS target")
}

@(require_results)
get_current_directory :: proc(allocator := context.allocator) -> string {
	unimplemented("core:os procedure not supported on JS target")
}

set_current_directory :: proc(path: string) -> (err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}



change_directory :: proc(path: string) -> (err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}

make_directory :: proc(path: string, mode: u32 = 0) -> (err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}


remove_directory :: proc(path: string) -> (err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}


link :: proc(old_name, new_name: string) -> (err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}

unlink :: proc(path: string) -> (err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}



rename :: proc(old_path, new_path: string) -> (err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}


ftruncate :: proc(fd: Handle, length: i64) -> (err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}

truncate :: proc(path: string, length: i64) -> (err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}


remove :: proc(name: string) -> Error {
	unimplemented("core:os procedure not supported on JS target")
}


@(require_results)
pipe :: proc() -> (r, w: Handle, err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}

@(require_results)
read_dir :: proc(fd: Handle, n: int, allocator := context.allocator) -> (fi: []File_Info, err: Error) {
	unimplemented("core:os procedure not supported on JS target")
}

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

args: []string

@(require_results)
last_write_time :: proc(fd: Handle) -> (File_Time, Error) {
	unimplemented("core:os procedure not supported on JS target")
}

@(require_results)
last_write_time_by_name :: proc(name: string) -> (File_Time, Error) {
	unimplemented("core:os procedure not supported on JS target")
}


@(require_results)
get_page_size :: proc() -> int {
	unimplemented("core:os procedure not supported on JS target")
}

@(private, require_results)
_processor_core_count :: proc() -> int {
	return 1
}

exit :: proc "contextless" (code: int) -> ! {
	unimplemented_contextless("core:os procedure not supported on JS target")
}

@(require_results)
current_thread_id :: proc "contextless" () -> int {
	return 0
}
