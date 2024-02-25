package os

foreign import libc "system:c"

import "core:strings"
import "core:c"
import "base:runtime"

Handle    :: distinct i32
Pid       :: distinct i32
File_Time :: distinct i64
Errno     :: distinct i32

B_GENERAL_ERROR_BASE :: min(i32)
B_POSIX_ERROR_BASE   :: B_GENERAL_ERROR_BASE + 0x7000

INVALID_HANDLE :: ~Handle(0)

ERROR_NONE:	Errno: 0

stdin:  Handle = 0
stdout: Handle = 1
stderr: Handle = 2

foreign libc {
	@(link_name="_errnop")	__error		:: proc() -> ^c.int ---

	@(link_name="fork")	_unix_fork	:: proc() -> pid_t ---
	@(link_name="getthrid")	_unix_getthrid	:: proc() -> int ---

	@(link_name="open")	_unix_open	:: proc(path: cstring, flags: c.int, mode: c.int) -> Handle ---
	@(link_name="close")	_unix_close	:: proc(fd: Handle) -> c.int ---
	@(link_name="read")	_unix_read	:: proc(fd: Handle, buf: rawptr, size: c.size_t) -> c.ssize_t ---
	@(link_name="write")	_unix_write	:: proc(fd: Handle, buf: rawptr, size: c.size_t) -> c.ssize_t ---
	@(link_name="lseek")	_unix_seek	:: proc(fd: Handle, offset: off_t, whence: c.int) -> off_t ---
	@(link_name="stat")	_unix_stat	:: proc(path: cstring, sb: ^OS_Stat) -> c.int ---
	@(link_name="fstat")	_unix_fstat	:: proc(fd: Handle, sb: ^OS_Stat) -> c.int ---
	@(link_name="lstat")	_unix_lstat	:: proc(path: cstring, sb: ^OS_Stat) -> c.int ---
	@(link_name="readlink")	_unix_readlink	:: proc(path: cstring, buf: ^byte, bufsiz: c.size_t) -> c.ssize_t ---
	@(link_name="access")	_unix_access	:: proc(path: cstring, mask: c.int) -> c.int ---
	@(link_name="getcwd")	_unix_getcwd	:: proc(buf: cstring, len: c.size_t) -> cstring ---
	@(link_name="chdir")	_unix_chdir	:: proc(path: cstring) -> c.int ---
	@(link_name="rename")	_unix_rename	:: proc(old, new: cstring) -> c.int ---
	@(link_name="unlink")	_unix_unlink	:: proc(path: cstring) -> c.int ---
	@(link_name="rmdir")	_unix_rmdir	:: proc(path: cstring) -> c.int ---
	@(link_name="mkdir")	_unix_mkdir	:: proc(path: cstring, mode: mode_t) -> c.int ---

	@(link_name="getpagesize") _unix_getpagesize :: proc() -> c.int ---
	@(link_name="sysconf") _sysconf :: proc(name: c.int) -> c.long ---
	@(link_name="fdopendir") _unix_fdopendir :: proc(fd: Handle) -> Dir ---
	@(link_name="closedir")	_unix_closedir	:: proc(dirp: Dir) -> c.int ---
	@(link_name="rewinddir") _unix_rewinddir :: proc(dirp: Dir) ---
	@(link_name="readdir_r") _unix_readdir_r :: proc(dirp: Dir, entry: ^Dirent, result: ^^Dirent) -> c.int ---

	@(link_name="malloc")	_unix_malloc	:: proc(size: c.size_t) -> rawptr ---
	@(link_name="calloc")	_unix_calloc	:: proc(num, size: c.size_t) -> rawptr ---
	@(link_name="free")	_unix_free	:: proc(ptr: rawptr) ---
	@(link_name="realloc")	_unix_realloc	:: proc(ptr: rawptr, size: c.size_t) -> rawptr ---

	@(link_name="getenv")	_unix_getenv	:: proc(cstring) -> cstring ---
	@(link_name="realpath")	_unix_realpath	:: proc(path: cstring, resolved_path: rawptr) -> rawptr ---

	@(link_name="exit")	_unix_exit	:: proc(status: c.int) -> ! ---

	@(link_name="dlopen")	_unix_dlopen	:: proc(filename: cstring, flags: c.int) -> rawptr ---
	@(link_name="dlsym")	_unix_dlsym	:: proc(handle: rawptr, symbol: cstring) -> rawptr ---
	@(link_name="dlclose")	_unix_dlclose	:: proc(handle: rawptr) -> c.int ---
	@(link_name="dlerror")	_unix_dlerror	:: proc() -> cstring ---
}

is_path_separator :: proc(r: rune) -> bool {
	return r == '/'
}

get_last_error :: proc "contextless" () -> int {
	return int(__error()^)
}

fork :: proc() -> (Pid, Errno) {
	pid := _unix_fork()
	if pid == -1 {
		return Pid(-1), Errno(get_last_error())
	}
	return Pid(pid), ERROR_NONE
}

open :: proc(path: string, flags: int = O_RDONLY, mode: int = 0) -> (Handle, Errno) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	handle := _unix_open(cstr, c.int(flags), c.int(mode))
	if handle == -1 {
		return INVALID_HANDLE, Errno(get_last_error())
	}
	return handle, ERROR_NONE
}

close :: proc(fd: Handle) -> Errno {
	result := _unix_close(fd)
	if result == -1 {
		return Errno(get_last_error())
	}
	return ERROR_NONE
}

_alloc_command_line_arguments :: proc() -> []string {
	res := make([]string, len(runtime.args__))
	for arg, i in runtime.args__ {
		res[i] = string(arg)
	}
	return res
}
