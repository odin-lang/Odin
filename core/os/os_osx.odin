package os

foreign import dl   "system:dl"
foreign import libc "system:c"

import "core:runtime"
import "core:strings"

OS :: "osx";

Handle    :: distinct i32;
File_Time :: distinct u64;
Errno     :: distinct int;

INVALID_HANDLE :: ~Handle(0);

O_RDONLY   :: 0x00000;
O_WRONLY   :: 0x00001;
O_RDWR     :: 0x00002;
O_CREATE   :: 0x00040;
O_EXCL     :: 0x00080;
O_NOCTTY   :: 0x00100;
O_TRUNC    :: 0x00200;
O_NONBLOCK :: 0x00800;
O_APPEND   :: 0x00400;
O_SYNC     :: 0x01000;
O_ASYNC    :: 0x02000;
O_CLOEXEC  :: 0x80000;


SEEK_SET   :: 0;
SEEK_CUR   :: 1;
SEEK_END   :: 2;
SEEK_DATA  :: 3;
SEEK_HOLE  :: 4;
SEEK_MAX   :: SEEK_HOLE;



// NOTE(zangent): These are OS specific!
// Do not mix these up!
RTLD_LAZY     :: 0x1;
RTLD_NOW      :: 0x2;
RTLD_LOCAL    :: 0x4;
RTLD_GLOBAL   :: 0x8;
RTLD_NODELETE :: 0x80;
RTLD_NOLOAD   :: 0x10;
RTLD_FIRST    :: 0x100;


// "Argv" arguments converted to Odin strings
args := _alloc_command_line_arguments();

_File_Time :: struct {
	seconds: i64,
	nanoseconds: i64,
}

Stat :: struct {
	device_id:     i32, // ID of device containing file
	mode:          u16, // Mode of the file
	nlink:         u16, // Number of hard links
	serial:        u64, // File serial number
	uid:           u32, // User ID of the file's owner
	gid:           u32, // Group ID of the file's group
	rdev:          i32, // Device ID, if device

	last_access:   File_Time, // Time of last access
	modified:      File_Time, // Time of last modification
	status_change: File_Time, // Time of last status change
	created:       File_Time, // Time of creation

	size:          i64,  // Size of the file, in bytes
	blocks:        i64,  // Number of blocks allocated for the file
	block_size:    i32,  // Optimal blocksize for I/O
	flags:         u32,  // User-defined flags for the file
	gen_num:       u32,  // File generation number ..?
	_spare:        i32,  // RESERVED
	_reserve1,
	_reserve2:     i64,  // RESERVED
};

// File type
S_IFMT   :: 0o170000; // Type of file mask
S_IFIFO  :: 0o010000; // Named pipe (fifo)
S_IFCHR  :: 0o020000; // Character special
S_IFDIR  :: 0o040000; // Directory
S_IFBLK  :: 0o060000; // Block special
S_IFREG  :: 0o100000; // Regular
S_IFLNK  :: 0o120000; // Symbolic link
S_IFSOCK :: 0o140000; // Socket

// File mode
// Read, write, execute/search by owner
S_IRWXU :: 0o0700; // RWX mask for owner
S_IRUSR :: 0o0400; // R for owner
S_IWUSR :: 0o0200; // W for owner
S_IXUSR :: 0o0100; // X for owner

// Read, write, execute/search by group
S_IRWXG :: 0o0070; // RWX mask for group
S_IRGRP :: 0o0040; // R for group
S_IWGRP :: 0o0020; // W for group
S_IXGRP :: 0o0010; // X for group

// Read, write, execute/search by others
S_IRWXO :: 0o0007; // RWX mask for other
S_IROTH :: 0o0004; // R for other
S_IWOTH :: 0o0002; // W for other
S_IXOTH :: 0o0001; // X for other

S_ISUID :: 0o4000; // Set user id on execution
S_ISGID :: 0o2000; // Set group id on execution
S_ISVTX :: 0o1000; // Directory restrcted delete

S_ISLNK  :: inline proc(m: u32) -> bool do return (m & S_IFMT) == S_IFLNK;
S_ISREG  :: inline proc(m: u32) -> bool do return (m & S_IFMT) == S_IFREG;
S_ISDIR  :: inline proc(m: u32) -> bool do return (m & S_IFMT) == S_IFDIR;
S_ISCHR  :: inline proc(m: u32) -> bool do return (m & S_IFMT) == S_IFCHR;
S_ISBLK  :: inline proc(m: u32) -> bool do return (m & S_IFMT) == S_IFBLK;
S_ISFIFO :: inline proc(m: u32) -> bool do return (m & S_IFMT) == S_IFIFO;
S_ISSOCK :: inline proc(m: u32) -> bool do return (m & S_IFMT) == S_IFSOCK;

R_OK :: 4; // Test for read permission
W_OK :: 2; // Test for write permission
X_OK :: 1; // Test for execute permission
F_OK :: 0; // Test for file existance

foreign libc {
	@(link_name="open")    _unix_open    :: proc(path: cstring, flags: int, #c_vararg mode: ..any) -> Handle ---;
	@(link_name="close")   _unix_close   :: proc(handle: Handle) ---;
	@(link_name="read")    _unix_read    :: proc(handle: Handle, buffer: rawptr, count: int) -> int ---;
	@(link_name="write")   _unix_write   :: proc(handle: Handle, buffer: rawptr, count: int) -> int ---;
	@(link_name="lseek")   _unix_lseek   :: proc(fs: Handle, offset: int, whence: int) -> int ---;
	@(link_name="gettid")  _unix_gettid  :: proc() -> u64 ---;
	@(link_name="stat")    _unix_stat    :: proc(path: cstring, stat: ^Stat) -> int ---;
	@(link_name="access")  _unix_access  :: proc(path: cstring, mask: int) -> int ---;

	@(link_name="malloc")  _unix_malloc  :: proc(size: int) -> rawptr ---;
	@(link_name="calloc")  _unix_calloc  :: proc(num, size: int) -> rawptr ---;
	@(link_name="free")    _unix_free    :: proc(ptr: rawptr) ---;
	@(link_name="realloc") _unix_realloc :: proc(ptr: rawptr, size: int) -> rawptr ---;
	@(link_name="getenv")  _unix_getenv  :: proc(cstring) -> cstring ---;

	@(link_name="exit")    _unix_exit    :: proc(status: int) ---;
}

foreign dl {
	@(link_name="dlopen")  _unix_dlopen  :: proc(filename: cstring, flags: int) -> rawptr ---;
	@(link_name="dlsym")   _unix_dlsym   :: proc(handle: rawptr, symbol: cstring) -> rawptr ---;
	@(link_name="dlclose") _unix_dlclose :: proc(handle: rawptr) -> int ---;
	@(link_name="dlerror") _unix_dlerror :: proc() -> cstring ---;
}

open :: proc(path: string, flags: int = O_RDONLY, mode: int = 0) -> (Handle, Errno) {
	cstr := strings.clone_to_cstring(path);
	handle := _unix_open(cstr, flags, mode);
	delete(cstr);
	if handle == -1 {
		return INVALID_HANDLE, 1;
	}
	return handle, 0;
}

close :: proc(fd: Handle) {
	_unix_close(fd);
}

write :: proc(fd: Handle, data: []u8) -> (int, Errno) {
	assert(fd != -1);

	bytes_written := _unix_write(fd, &data[0], len(data));
	if(bytes_written == -1) {
		return 0, 1;
	}
	return bytes_written, 0;
}

read :: proc(fd: Handle, data: []u8) -> (int, Errno) {
	assert(fd != -1);

	bytes_read := _unix_read(fd, &data[0], len(data));
	if bytes_read == -1 {
		return 0, 1;
	}
	return bytes_read, 0;
}

seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Errno) {
	assert(fd != -1);

	final_offset := i64(_unix_lseek(fd, int(offset), whence));
	if final_offset == -1 {
		return 0, 1;
	}
	return final_offset, 0;
}

file_size :: proc(fd: Handle) -> (i64, Errno) {
	prev, _   := seek(fd, 0, SEEK_CUR);
	size, err := seek(fd, 0, SEEK_END);
	seek(fd, prev, SEEK_SET);
	return i64(size), err;
}



// NOTE(bill): Uses startup to initialize it
stdin:  Handle = 0; // get_std_handle(win32.STD_INPUT_HANDLE);
stdout: Handle = 1; // get_std_handle(win32.STD_OUTPUT_HANDLE);
stderr: Handle = 2; // get_std_handle(win32.STD_ERROR_HANDLE);

/* TODO(zangent): Implement these!
last_write_time :: proc(fd: Handle) -> File_Time {}
last_write_time_by_name :: proc(name: string) -> File_Time {}
*/

is_path_separator :: proc(r: rune) -> bool {
	return r == '/';
}

stat :: inline proc(path: string) -> (Stat, bool) {
	s: Stat;
	cstr := strings.clone_to_cstring(path);
	defer delete(cstr);
	ret_int := _unix_stat(cstr, &s);
	return s, ret_int==0;
}

access :: inline proc(path: string, mask: int) -> bool {
	cstr := strings.clone_to_cstring(path);
	defer delete(cstr);
	return _unix_access(cstr, mask) == 0;
}

heap_alloc :: inline proc(size: int) -> rawptr {
	assert(size > 0);
	return _unix_calloc(1, size);
}
heap_resize :: inline proc(ptr: rawptr, new_size: int) -> rawptr {
	return _unix_realloc(ptr, new_size);
}
heap_free :: inline proc(ptr: rawptr) {
	_unix_free(ptr);
}

getenv :: proc(name: string) -> (string, bool) {
	path_str := strings.clone_to_cstring(name);
	defer delete(path_str);
	cstr := _unix_getenv(path_str);
	if cstr == nil {
		return "", false;
	}
	return string(cstr), true;
}

exit :: inline proc(code: int) -> ! {
	_unix_exit(code);
}


current_thread_id :: proc "contextless" () -> int {
	// return int(_unix_gettid());
	return 0;
}

dlopen :: inline proc(filename: string, flags: int) -> rawptr {
	cstr := strings.clone_to_cstring(filename);
	defer delete(cstr);
	handle := _unix_dlopen(cstr, flags);
	return handle;
}
dlsym :: inline proc(handle: rawptr, symbol: string) -> rawptr {
	assert(handle != nil);
	cstr := strings.clone_to_cstring(symbol);
	defer delete(cstr);
	proc_handle := _unix_dlsym(handle, cstr);
	return proc_handle;
}
dlclose :: inline proc(handle: rawptr) -> bool {
	assert(handle != nil);
	return _unix_dlclose(handle) == 0;
}
dlerror :: proc() -> string {
	return string(_unix_dlerror());
}


_alloc_command_line_arguments :: proc() -> []string {
	args := make([]string, len(runtime.args__));
	for arg, i in runtime.args__ {
		args[i] = string(arg);
	}
	return args;
}
