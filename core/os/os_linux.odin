package os

foreign import dl   "system:dl"
foreign import libc "system:c"

import "core:runtime"
import "core:strings"

OS :: "linux";

Handle    :: distinct i32;
File_Time :: distinct u64;
Errno     :: distinct i32;
Syscall   :: distinct int;

INVALID_HANDLE :: ~Handle(0);

ERROR_NONE:    Errno : 0;
EPERM:         Errno : 1;
ENOENT:        Errno : 2;
EINTR:         Errno : 4;
EIO:           Errno : 5;
ENXIO:         Errno : 6;
EBADF:         Errno : 9;
EAGAIN:        Errno : 11;
EWOULDBLOCK:   Errno : EAGAIN;
ENOMEM:        Errno : 12;
EACCES:        Errno : 13;
EFAULT:        Errno : 14;
EEXIST:        Errno : 17;
ENODEV:        Errno : 19;
ENOTDIR:       Errno : 20;
EISDIR:        Errno : 21;
EINVAL:        Errno : 22;
ENFILE:        Errno : 23;
EMFILE:        Errno : 24;
ETXTBSY:       Errno : 26;
EFBIG:         Errno : 27;
ENOSPC:        Errno : 28;
ESPIPE:        Errno : 29;
EROFS:         Errno : 30;
EPIPE:         Errno : 32;
ENAMETOOLONG:  Errno : 36;
ELOOP:         Errno : 40;
EOVERFLOW:     Errno : 75;
EDESTADDRREQ:  Errno : 89;
EOPNOTSUPP:    Errno : 95;
EDQUOT:        Errno : 122;

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
RTLD_LAZY         :: 0x001;
RTLD_NOW          :: 0x002;
RTLD_BINDING_MASK :: 0x3;
RTLD_GLOBAL       :: 0x100;

// "Argv" arguments converted to Odin strings
args := _alloc_command_line_arguments();

_File_Time :: struct {
	seconds:     i64,
	nanoseconds: i64,
}

Stat :: struct {
	device_id:     u64, // ID of device containing file
	serial:        u64, // File serial number
	nlink:         u64, // Number of hard links
	mode:          u32, // Mode of the file
	uid:           u32, // User ID of the file's owner
	gid:           u32, // Group ID of the file's group
	_padding:      i32, // 32 bits of padding
	rdev:          u64, // Device ID, if device
	size:          i64, // Size of the file, in bytes
	block_size:    i64, // Optimal bllocksize for I/O
	blocks:        i64, // Number of 512-byte blocks allocated

	last_access:   _File_Time, // Time of last access
	modified:      _File_Time, // Time of last modification
	status_change: _File_Time, // Time of last status change

	_reserve1,
	_reserve2,
	_reserve3:     i64,
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

F_OK :: 0; // Test for file existance
X_OK :: 1; // Test for execute permission
W_OK :: 2; // Test for write permission
R_OK :: 4; // Test for read permission

TimeSpec :: struct {
	tv_sec  : i64,  /* seconds */
	tv_nsec : i64,  /* nanoseconds */
};

CLOCK_REALTIME           :: 0;
CLOCK_MONOTONIC          :: 1;
CLOCK_PROCESS_CPUTIME_ID :: 2;
CLOCK_THREAD_CPUTIME_ID  :: 3;
CLOCK_MONOTONIC_RAW      :: 4;
CLOCK_REALTIME_COARSE    :: 5;
CLOCK_MONOTONIC_COARSE   :: 6;
CLOCK_BOOTTIME           :: 7;
CLOCK_REALTIME_ALARM     :: 8;
CLOCK_BOOTTIME_ALARM     :: 9;

SYS_GETTID: Syscall : 186;

foreign libc {
	@(link_name="__errno_location") __errno_location    :: proc() -> ^int ---;
	@(link_name="syscall")          syscall             :: proc(number: Syscall, #c_vararg args: ..any) -> int ---;

	@(link_name="open")             _unix_open          :: proc(path: cstring, flags: int, #c_vararg mode: ..any) -> Handle ---;
	@(link_name="close")            _unix_close         :: proc(fd: Handle) -> int ---;
	@(link_name="read")             _unix_read          :: proc(fd: Handle, buf: rawptr, size: int) -> int ---;
	@(link_name="write")            _unix_write         :: proc(fd: Handle, buf: rawptr, size: int) -> int ---;
	@(link_name="lseek64")          _unix_seek          :: proc(fd: Handle, offset: i64, whence: i32) -> i64 ---;
	@(link_name="gettid")           _unix_gettid        :: proc() -> u64 ---;
	@(link_name="stat")             _unix_stat          :: proc(path: cstring, stat: ^Stat) -> int ---;
	@(link_name="fstat")            _unix_fstat         :: proc(fd: Handle, stat: ^Stat) -> int ---;
	@(link_name="access")           _unix_access        :: proc(path: cstring, mask: int) -> int ---;

	@(link_name="malloc")           _unix_malloc        :: proc(size: int) -> rawptr ---;
	@(link_name="calloc")           _unix_calloc        :: proc(num, size: int) -> rawptr ---;
	@(link_name="free")             _unix_free          :: proc(ptr: rawptr) ---;
	@(link_name="realloc")          _unix_realloc       :: proc(ptr: rawptr, size: int) -> rawptr ---;
	@(link_name="getenv")           _unix_getenv        :: proc(cstring) -> cstring ---;

	@(link_name="clock_gettime")    _unix_clock_gettime :: proc(clock_id: u64, timespec: ^TimeSpec) ---;
	@(link_name="nanosleep")        _unix_nanosleep     :: proc(requested: ^TimeSpec, remaining: ^TimeSpec) -> int ---;
	@(link_name="sleep")            _unix_sleep         :: proc(seconds: u64) -> int ---;

	@(link_name="exit")             _unix_exit          :: proc(status: int) -> ! ---;
}
foreign dl {
	@(link_name="dlopen")           _unix_dlopen        :: proc(filename: cstring, flags: int) -> rawptr ---;
	@(link_name="dlsym")            _unix_dlsym         :: proc(handle: rawptr, symbol: cstring) -> rawptr ---;
	@(link_name="dlclose")          _unix_dlclose       :: proc(handle: rawptr) -> int ---;
	@(link_name="dlerror")          _unix_dlerror       :: proc() -> cstring ---;
}

is_path_separator :: proc(r: rune) -> bool {
	return r == '/';
}

get_last_error :: proc() -> Errno {
	return Errno(__errno_location()^);
}

open :: proc(path: string, flags: int = O_RDONLY, mode: int = 0) -> (Handle, Errno) {
	cstr := strings.clone_to_cstring(path);
	handle := _unix_open(cstr, flags, mode);
	delete(cstr);
	if handle == -1 {
		return INVALID_HANDLE, Errno(get_last_error());
	}
	return handle, ERROR_NONE;
}

close :: proc(fd: Handle) -> Errno {
	result := _unix_close(fd);
	if result == -1 {
		return Errno(get_last_error());
	}
	return ERROR_NONE;
}

read :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	bytes_read := _unix_read(fd, &data[0], len(data));
	if bytes_read == -1 {
		return -1, Errno(get_last_error());
	}
	return bytes_read, ERROR_NONE;
}

write :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	bytes_written := _unix_write(fd, &data[0], len(data));
	if bytes_written == -1 {
		return -1, Errno(get_last_error());
	}
	return bytes_written, ERROR_NONE;
}

seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Errno) {
	res := _unix_seek(fd, offset, i32(whence));
	if res == -1 {
		return -1, Errno(get_last_error());
	}
	return res, ERROR_NONE;
}

file_size :: proc(fd: Handle) -> (i64, Errno) {
	s, err := fstat(fd);
	if err != ERROR_NONE {
		return -1, err;
	}
	return s.size, ERROR_NONE;
}


// NOTE(bill): Uses startup to initialize it

stdin:  Handle = 0;
stdout: Handle = 1;
stderr: Handle = 2;

/* TODO(zangent): Implement these!
last_write_time :: proc(fd: Handle) -> File_Time {}
last_write_time_by_name :: proc(name: string) -> File_Time {}
*/
last_write_time :: proc(fd: Handle) -> (File_Time, Errno) {
	s, err := fstat(fd);
	if err != ERROR_NONE {
		return 0, err;
	}
	return File_Time(s.modified.nanoseconds), ERROR_NONE;
}

last_write_time_by_name :: proc(name: string) -> (File_Time, Errno) {
	s, err := stat(name);
	if err != ERROR_NONE {
		return 0, err;
	}
	return File_Time(s.modified.nanoseconds), ERROR_NONE;
}

stat :: inline proc(path: string) -> (Stat, Errno) {
	cstr := strings.clone_to_cstring(path);
	defer delete(cstr);

	s: Stat;
	result := _unix_stat(cstr, &s);
	if result == -1 {
		return s, Errno(get_last_error());
	}
	return s, ERROR_NONE;
}

fstat :: inline proc(fd: Handle) -> (Stat, Errno) {
	s: Stat;
	result := _unix_fstat(fd, &s);
	if result == -1 {
		return s, Errno(get_last_error());
	}
	return s, ERROR_NONE;
}

access :: inline proc(path: string, mask: int) -> (bool, Errno) {
	cstr := strings.clone_to_cstring(path);
	defer delete(cstr);
	result := _unix_access(cstr, mask);
	if result == -1 {
		return false, Errno(get_last_error());
	}
	return true, ERROR_NONE;
}

heap_alloc :: proc(size: int) -> rawptr {
	assert(size >= 0);
	return _unix_calloc(1, size);
}

heap_resize :: proc(ptr: rawptr, new_size: int) -> rawptr {
	return _unix_realloc(ptr, new_size);
}

heap_free :: proc(ptr: rawptr) {
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

exit :: proc(code: int) -> ! {
	_unix_exit(code);
}

clock_gettime :: proc(clock_id: u64) -> TimeSpec {
	ts : TimeSpec;
	_unix_clock_gettime(clock_id, &ts);
	return ts;
}

sleep :: proc(seconds: u64) -> int {
	return _unix_sleep(seconds);
}

nanosleep :: proc(nanoseconds: i64) -> int {
	assert(nanoseconds <= 999999999);
	requested, remaining : TimeSpec;
	requested = TimeSpec{tv_nsec = nanoseconds};

	return _unix_nanosleep(&requested, &remaining);
}

current_thread_id :: proc "contextless" () -> int {
	return syscall(SYS_GETTID);
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
