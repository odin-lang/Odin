package os

foreign import dl "system:dl"
foreign import libc "system:c"

import "base:runtime"
import "core:strings"
import "core:c"

Handle :: distinct i32
File_Time :: distinct u64
Errno :: distinct i32

INVALID_HANDLE :: ~Handle(0)

ERROR_NONE:      Errno : 0
EPERM:           Errno : 1
ENOENT:          Errno : 2
ESRCH:           Errno : 3
EINTR:           Errno : 4
EIO:             Errno : 5
ENXIO:           Errno : 6
E2BIG:           Errno : 7
ENOEXEC:         Errno : 8
EBADF:           Errno : 9
ECHILD:          Errno : 10
EBEADLK:         Errno : 11
ENOMEM:          Errno : 12
EACCESS:         Errno : 13
EFAULT:          Errno : 14
ENOTBLK:         Errno : 15
EBUSY:           Errno : 16
EEXIST:          Errno : 17
EXDEV:           Errno : 18
ENODEV:          Errno : 19
ENOTDIR:         Errno : 20
EISDIR:          Errno : 21
EINVAL:          Errno : 22
ENFILE:          Errno : 23
EMFILE:          Errno : 24
ENOTTY:          Errno : 25
ETXTBSY:         Errno : 26
EFBIG:           Errno : 27
ENOSPC:          Errno : 28
ESPIPE:          Errno : 29
EROFS:           Errno : 30
EMLINK:          Errno : 31
EPIPE:           Errno : 32
EDOM:            Errno : 33
ERANGE:          Errno : 34 /* Result too large */
EAGAIN:          Errno : 35
EINPROGRESS:     Errno : 36
EALREADY:        Errno : 37
ENOTSOCK:        Errno : 38
EDESTADDRREQ:    Errno : 39
EMSGSIZE:        Errno : 40
EPROTOTYPE:      Errno : 41
ENOPROTOOPT:     Errno : 42
EPROTONOSUPPORT: Errno : 43
ESOCKTNOSUPPORT: Errno : 44
EOPNOTSUPP:      Errno : 45
EPFNOSUPPORT:    Errno : 46
EAFNOSUPPORT:    Errno : 47
EADDRINUSE:      Errno : 48
EADDRNOTAVAIL:   Errno : 49
ENETDOWN:        Errno : 50
ENETUNREACH:     Errno : 51
ENETRESET:       Errno : 52
ECONNABORTED:    Errno : 53
ECONNRESET:      Errno : 54
ENOBUFS:         Errno : 55
EISCONN:         Errno : 56
ENOTCONN:        Errno : 57
ESHUTDOWN:       Errno : 58
ETIMEDOUT:       Errno : 60
ECONNREFUSED:    Errno : 61
ELOOP:           Errno : 62
ENAMETOOLING:    Errno : 63
EHOSTDOWN:       Errno : 64
EHOSTUNREACH:    Errno : 65
ENOTEMPTY:       Errno : 66
EPROCLIM:        Errno : 67
EUSERS:          Errno : 68
EDQUOT:          Errno : 69
ESTALE:          Errno : 70
EBADRPC:         Errno : 72
ERPCMISMATCH:    Errno : 73
EPROGUNAVAIL:    Errno : 74
EPROGMISMATCH:   Errno : 75
EPROCUNAVAIL:    Errno : 76
ENOLCK:          Errno : 77
ENOSYS:          Errno : 78
EFTYPE:          Errno : 79
EAUTH:           Errno : 80
ENEEDAUTH:       Errno : 81
EIDRM:           Errno : 82
ENOMSG:          Errno : 83
EOVERFLOW:       Errno : 84
ECANCELED:       Errno : 85
EILSEQ:          Errno : 86
ENOATTR:         Errno : 87
EDOOFUS:         Errno : 88
EBADMSG:         Errno : 89
EMULTIHOP:       Errno : 90
ENOLINK:         Errno : 91
EPROTO:          Errno : 92
ENOTCAPABLE:     Errno : 93
ECAPMODE:        Errno : 94
ENOTRECOVERABLE: Errno : 95
EOWNERDEAD:      Errno : 96

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


SEEK_DATA  :: 3
SEEK_HOLE  :: 4
SEEK_MAX   :: SEEK_HOLE

// NOTE: These are OS specific!
// Do not mix these up!
RTLD_LAZY         :: 0x001
RTLD_NOW          :: 0x002
//RTLD_BINDING_MASK :: 0x3 // Called MODEMASK in dlfcn.h
RTLD_GLOBAL       :: 0x100
RTLD_LOCAL        :: 0x000
RTLD_TRACE        :: 0x200
RTLD_NODELETE     :: 0x01000
RTLD_NOLOAD       :: 0x02000

MAX_PATH :: 1024

args := _alloc_command_line_arguments()

Unix_File_Time :: struct {
	seconds: time_t,
	nanoseconds: c.long,
}

dev_t :: u64
ino_t :: u64
nlink_t :: u64
off_t :: i64
mode_t :: u16
pid_t :: u32
uid_t :: u32
gid_t :: u32
blkcnt_t :: i64
blksize_t :: i32
fflags_t :: u32

when ODIN_ARCH == .amd64 || ODIN_ARCH == .arm64 /* LP64 */ {
	time_t :: i64
} else {
	time_t :: i32
}


OS_Stat :: struct {
	device_id: dev_t,
	serial: ino_t,
	nlink: nlink_t,
	mode: mode_t,
	_padding0: i16,
	uid: uid_t,
	gid: gid_t,
	_padding1: i32,
	rdev: dev_t,

	last_access: Unix_File_Time,
	modified: Unix_File_Time,
	status_change: Unix_File_Time,
	birthtime: Unix_File_Time,

	size: off_t,
	blocks: blkcnt_t,
	block_size: blksize_t,

	flags: fflags_t,
	gen: u64,
	lspare: [10]u64,
}


// since FreeBSD v12
Dirent :: struct {
	ino: ino_t,
	off: off_t,
	reclen: u16,
	type: u8,
	_pad0: u8,
	namlen: u16,
	_pad1: u16,
	name: [256]byte,
}

Dir :: distinct rawptr // DIR*

// File type
S_IFMT   :: 0o170000 // Type of file mask
S_IFIFO  :: 0o010000 // Named pipe (fifo)
S_IFCHR  :: 0o020000 // Character special
S_IFDIR  :: 0o040000 // Directory
S_IFBLK  :: 0o060000 // Block special
S_IFREG  :: 0o100000 // Regular
S_IFLNK  :: 0o120000 // Symbolic link
S_IFSOCK :: 0o140000 // Socket
//S_ISVTX  :: 0o001000 // Save swapped text even after use

// File mode
// Read, write, execute/search by owner
S_IRWXU :: 0o0700 // RWX mask for owner
S_IRUSR :: 0o0400 // R for owner
S_IWUSR :: 0o0200 // W for owner
S_IXUSR :: 0o0100 // X for owner

	// Read, write, execute/search by group
S_IRWXG :: 0o0070 // RWX mask for group
S_IRGRP :: 0o0040 // R for group
S_IWGRP :: 0o0020 // W for group
S_IXGRP :: 0o0010 // X for group

	// Read, write, execute/search by others
S_IRWXO :: 0o0007 // RWX mask for other
S_IROTH :: 0o0004 // R for other
S_IWOTH :: 0o0002 // W for other
S_IXOTH :: 0o0001 // X for other

S_ISUID :: 0o4000 // Set user id on execution
S_ISGID :: 0o2000 // Set group id on execution
S_ISVTX :: 0o1000 // Directory restrcted delete


S_ISLNK  :: #force_inline proc(m: mode_t) -> bool { return (m & S_IFMT) == S_IFLNK  }
S_ISREG  :: #force_inline proc(m: mode_t) -> bool { return (m & S_IFMT) == S_IFREG  }
S_ISDIR  :: #force_inline proc(m: mode_t) -> bool { return (m & S_IFMT) == S_IFDIR  }
S_ISCHR  :: #force_inline proc(m: mode_t) -> bool { return (m & S_IFMT) == S_IFCHR  }
S_ISBLK  :: #force_inline proc(m: mode_t) -> bool { return (m & S_IFMT) == S_IFBLK  }
S_ISFIFO :: #force_inline proc(m: mode_t) -> bool { return (m & S_IFMT) == S_IFIFO  }
S_ISSOCK :: #force_inline proc(m: mode_t) -> bool { return (m & S_IFMT) == S_IFSOCK }

F_OK :: 0 // Test for file existance
X_OK :: 1 // Test for execute permission
W_OK :: 2 // Test for write permission
R_OK :: 4 // Test for read permission

foreign libc {
	@(link_name="__error")		__errno_location :: proc() -> ^c.int ---

	@(link_name="open")             _unix_open          :: proc(path: cstring, flags: c.int, mode: c.int) -> Handle ---
	@(link_name="close")            _unix_close         :: proc(fd: Handle) -> c.int ---
	@(link_name="read")             _unix_read          :: proc(fd: Handle, buf: rawptr, size: c.size_t) -> c.ssize_t ---
	@(link_name="write")            _unix_write         :: proc(fd: Handle, buf: rawptr, size: c.size_t) -> c.ssize_t ---
	@(link_name="lseek")            _unix_seek          :: proc(fd: Handle, offset: i64, whence: c.int) -> i64 ---
	@(link_name="getpagesize")      _unix_getpagesize   :: proc() -> c.int ---
	@(link_name="stat")             _unix_stat          :: proc(path: cstring, stat: ^OS_Stat) -> c.int ---
	@(link_name="lstat")            _unix_lstat         :: proc(path: cstring, sb: ^OS_Stat) -> c.int ---
	@(link_name="fstat")            _unix_fstat         :: proc(fd: Handle, stat: ^OS_Stat) -> c.int ---
	@(link_name="readlink")         _unix_readlink      :: proc(path: cstring, buf: ^byte, bufsiz: c.size_t) -> c.ssize_t ---
	@(link_name="access")           _unix_access        :: proc(path: cstring, mask: c.int) -> c.int ---
	@(link_name="getcwd")           _unix_getcwd        :: proc(buf: cstring, len: c.size_t) -> cstring ---
	@(link_name="chdir")            _unix_chdir         :: proc(buf: cstring) -> c.int ---
	@(link_name="rename")           _unix_rename        :: proc(old, new: cstring) -> c.int ---
	@(link_name="unlink")           _unix_unlink        :: proc(path: cstring) -> c.int ---
	@(link_name="rmdir")            _unix_rmdir         :: proc(path: cstring) -> c.int ---
	@(link_name="mkdir")            _unix_mkdir         :: proc(path: cstring, mode: mode_t) -> c.int ---
	
	@(link_name="fdopendir")        _unix_fdopendir     :: proc(fd: Handle) -> Dir ---
	@(link_name="closedir")         _unix_closedir      :: proc(dirp: Dir) -> c.int ---
	@(link_name="rewinddir")        _unix_rewinddir     :: proc(dirp: Dir) ---
	@(link_name="readdir_r")        _unix_readdir_r     :: proc(dirp: Dir, entry: ^Dirent, result: ^^Dirent) -> c.int ---

	@(link_name="malloc")           _unix_malloc        :: proc(size: c.size_t) -> rawptr ---
	@(link_name="calloc")           _unix_calloc        :: proc(num, size: c.size_t) -> rawptr ---
	@(link_name="free")             _unix_free          :: proc(ptr: rawptr) ---
	@(link_name="realloc")          _unix_realloc       :: proc(ptr: rawptr, size: c.size_t) -> rawptr ---
	
	@(link_name="getenv")           _unix_getenv        :: proc(cstring) -> cstring ---
	@(link_name="realpath")         _unix_realpath      :: proc(path: cstring, resolved_path: rawptr) -> rawptr ---
	@(link_name="sysctlbyname")     _sysctlbyname       :: proc(path: cstring, oldp: rawptr, oldlenp: rawptr, newp: rawptr, newlen: int) -> c.int ---

	@(link_name="exit")             _unix_exit          :: proc(status: c.int) -> ! ---
}
foreign dl {
	@(link_name="dlopen")           _unix_dlopen        :: proc(filename: cstring, flags: c.int) -> rawptr ---
	@(link_name="dlsym")            _unix_dlsym         :: proc(handle: rawptr, symbol: cstring) -> rawptr ---
	@(link_name="dlclose")          _unix_dlclose       :: proc(handle: rawptr) -> c.int ---
	@(link_name="dlerror")          _unix_dlerror       :: proc() -> cstring ---

	@(link_name="pthread_getthreadid_np") pthread_getthreadid_np :: proc() -> c.int ---
}

is_path_separator :: proc(r: rune) -> bool {
	return r == '/'
}

get_last_error :: proc "contextless" () -> int {
	return int(__errno_location()^)
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

// If you read or write more than `INT_MAX` bytes, FreeBSD returns `EINVAL`.
// In practice a read/write call would probably never read/write these big buffers all at once,
// which is why the number of bytes is returned and why there are procs that will call this in a
// loop for you.
// We set a max of 1GB to keep alignment and to be safe.
@(private)
MAX_RW :: 1 << 30

read :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	to_read    := min(c.size_t(len(data)), MAX_RW)
	bytes_read := _unix_read(fd, &data[0], to_read)
	if bytes_read == -1 {
		return -1, Errno(get_last_error())
	}
	return int(bytes_read), ERROR_NONE
}

write :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	if len(data) == 0 {
		return 0, ERROR_NONE
	}

	to_write      := min(c.size_t(len(data)), MAX_RW)
	bytes_written := _unix_write(fd, &data[0], to_write)
	if bytes_written == -1 {
		return -1, Errno(get_last_error())
	}
	return int(bytes_written), ERROR_NONE
}

seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Errno) {
	res := _unix_seek(fd, offset, c.int(whence))
	if res == -1 {
		return -1, Errno(get_last_error())
	}
	return res, ERROR_NONE
}

file_size :: proc(fd: Handle) -> (i64, Errno) {
	s, err := fstat(fd)
	if err != ERROR_NONE {
		return -1, err
	}
	return s.size, ERROR_NONE
}

rename :: proc(old_path, new_path: string) -> Errno {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	old_path_cstr := strings.clone_to_cstring(old_path, context.temp_allocator)
	new_path_cstr := strings.clone_to_cstring(new_path, context.temp_allocator)
	res := _unix_rename(old_path_cstr, new_path_cstr)
	if res == -1 {
		return Errno(get_last_error())
	}
	return ERROR_NONE
}

remove :: proc(path: string) -> Errno {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	res := _unix_unlink(path_cstr)
	if res == -1 {
		return Errno(get_last_error())
	}
	return ERROR_NONE
}

make_directory :: proc(path: string, mode: mode_t = 0o775) -> Errno {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	res := _unix_mkdir(path_cstr, mode)
	if res == -1 {
		return Errno(get_last_error())
	}
	return ERROR_NONE
}

remove_directory :: proc(path: string) -> Errno {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	res := _unix_rmdir(path_cstr)
	if res == -1 {
		return Errno(get_last_error())
	}
	return ERROR_NONE
}

is_file_handle :: proc(fd: Handle) -> bool {
	s, err := _fstat(fd)
	if err != ERROR_NONE {
		return false
	}
	return S_ISREG(s.mode)
}

is_file_path :: proc(path: string, follow_links: bool = true) -> bool {
	s: OS_Stat
	err: Errno
	if follow_links {
		s, err = _stat(path)
	} else {
		s, err = _lstat(path)
	}
	if err != ERROR_NONE {
		return false
	}
	return S_ISREG(s.mode)
}

is_dir_handle :: proc(fd: Handle) -> bool {
	s, err := _fstat(fd)
	if err != ERROR_NONE {
		return false
	}
	return S_ISDIR(s.mode)
}

is_dir_path :: proc(path: string, follow_links: bool = true) -> bool {
	s: OS_Stat
	err: Errno
	if follow_links {
		s, err = _stat(path)
	} else {
		s, err = _lstat(path)
	}
	if err != ERROR_NONE {
		return false
	}
	return S_ISDIR(s.mode)
}

is_file :: proc {is_file_path, is_file_handle}
is_dir :: proc {is_dir_path, is_dir_handle}

// NOTE(bill): Uses startup to initialize it

stdin: Handle  = 0
stdout: Handle = 1
stderr: Handle = 2

/* TODO(zangent): Implement these!                                                                                   
last_write_time :: proc(fd: Handle) -> File_Time {}                                                                  
last_write_time_by_name :: proc(name: string) -> File_Time {}                                                        
*/
last_write_time :: proc(fd: Handle) -> (File_Time, Errno) {
	s, err := _fstat(fd)
	if err != ERROR_NONE {
		return 0, err
	}
	modified := s.modified.seconds * 1_000_000_000 + s.modified.nanoseconds
	return File_Time(modified), ERROR_NONE
}

last_write_time_by_name :: proc(name: string) -> (File_Time, Errno) {
	s, err := _stat(name)
	if err != ERROR_NONE {
		return 0, err
	}
	modified := s.modified.seconds * 1_000_000_000 + s.modified.nanoseconds
	return File_Time(modified), ERROR_NONE
}

@private
_stat :: proc(path: string) -> (OS_Stat, Errno) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	s: OS_Stat = ---
	result := _unix_lstat(cstr, &s)
	if result == -1 {
		return s, Errno(get_last_error())
	}
	return s, ERROR_NONE
}

@private
_lstat :: proc(path: string) -> (OS_Stat, Errno) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	
	// deliberately uninitialized
	s: OS_Stat = ---
	res := _unix_lstat(cstr, &s)
	if res == -1 {
		return s, Errno(get_last_error())
	}
	return s, ERROR_NONE
}

@private
_fstat :: proc(fd: Handle) -> (OS_Stat, Errno) {
	s: OS_Stat = ---
	result := _unix_fstat(fd, &s)
	if result == -1 {
		return s, Errno(get_last_error())
	}
	return s, ERROR_NONE
}

@private
_fdopendir :: proc(fd: Handle) -> (Dir, Errno) {
	dirp := _unix_fdopendir(fd)
	if dirp == cast(Dir)nil {
		return nil, Errno(get_last_error())
	}
	return dirp, ERROR_NONE
}

@private
_closedir :: proc(dirp: Dir) -> Errno {
	rc := _unix_closedir(dirp)
	if rc != 0 {
		return Errno(get_last_error())
	}
	return ERROR_NONE
}

@private
_rewinddir :: proc(dirp: Dir) {
	_unix_rewinddir(dirp)
}

@private
_readdir :: proc(dirp: Dir) -> (entry: Dirent, err: Errno, end_of_stream: bool) {
	result: ^Dirent
	rc := _unix_readdir_r(dirp, &entry, &result)

	if rc != 0 {
		err = Errno(get_last_error())
		return
	}
	err = ERROR_NONE

	if result == nil {
		end_of_stream = true
		return
	}

	return
}

@private
_readlink :: proc(path: string) -> (string, Errno) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == context.allocator)

	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)

	bufsz : uint = MAX_PATH
	buf := make([]byte, MAX_PATH)
	for {
		rc := _unix_readlink(path_cstr, &(buf[0]), bufsz)
		if rc == -1 {
			delete(buf)
			return "", Errno(get_last_error())
		} else if rc == int(bufsz) {
			bufsz += MAX_PATH
			delete(buf)
			buf = make([]byte, bufsz)
		} else {
			return strings.string_from_ptr(&buf[0], rc), ERROR_NONE
		}	
	}

	return "", Errno{}
}

// XXX FreeBSD
absolute_path_from_handle :: proc(fd: Handle) -> (string, Errno) {
	return "", Errno(ENOSYS)
}

absolute_path_from_relative :: proc(rel: string) -> (path: string, err: Errno) {
	rel := rel
	if rel == "" {
		rel = "."
	}
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == context.allocator)

	rel_cstr := strings.clone_to_cstring(rel, context.temp_allocator)

	path_ptr := _unix_realpath(rel_cstr, nil)
	if path_ptr == nil {
		return "", Errno(get_last_error())
	}
	defer _unix_free(path_ptr)

	path_cstr := transmute(cstring)path_ptr
	path = strings.clone( string(path_cstr) )

	return path, ERROR_NONE
}

access :: proc(path: string, mask: int) -> (bool, Errno) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	result := _unix_access(cstr, c.int(mask))
	if result == -1 {
		return false, Errno(get_last_error())
	}
	return true, ERROR_NONE
}

lookup_env :: proc(key: string, allocator := context.allocator) -> (value: string, found: bool) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == allocator)

	path_str := strings.clone_to_cstring(key, context.temp_allocator)
	cstr := _unix_getenv(path_str)
	if cstr == nil {
		return "", false
	}
	return strings.clone(string(cstr), allocator), true
}

get_env :: proc(key: string, allocator := context.allocator) -> (value: string) {
	value, _ = lookup_env(key, allocator)
	return
}

get_current_directory :: proc() -> string {
	// NOTE(tetra): I would use PATH_MAX here, but I was not able to find
	// an authoritative value for it across all systems.
	// The largest value I could find was 4096, so might as well use the page size.
	page_size := get_page_size()
	buf := make([dynamic]u8, page_size)
	#no_bounds_check for {
		cwd := _unix_getcwd(cstring(&buf[0]), c.size_t(len(buf)))
		if cwd != nil {
			return string(cwd)
		}
		if Errno(get_last_error()) != ERANGE {
			delete(buf)
			return ""
		}
		resize(&buf, len(buf)+page_size)
	}
	unreachable()
}

set_current_directory :: proc(path: string) -> (err: Errno) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	res := _unix_chdir(cstr)
	if res == -1 do return Errno(get_last_error())
	return ERROR_NONE
}

exit :: proc "contextless" (code: int) -> ! {
	runtime._cleanup_runtime_contextless()
	_unix_exit(c.int(code))
}

current_thread_id :: proc "contextless" () -> int {
	return cast(int) pthread_getthreadid_np()
}

dlopen :: proc(filename: string, flags: int) -> rawptr {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(filename, context.temp_allocator)
	handle := _unix_dlopen(cstr, c.int(flags))
	return handle
}
dlsym :: proc(handle: rawptr, symbol: string) -> rawptr {
	assert(handle != nil)
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(symbol, context.temp_allocator)
	proc_handle := _unix_dlsym(handle, cstr)
	return proc_handle
}
dlclose :: proc(handle: rawptr) -> bool {
	assert(handle != nil)
	return _unix_dlclose(handle) == 0
}
dlerror :: proc() -> string {
	return string(_unix_dlerror())
}

get_page_size :: proc() -> int {
	// NOTE(tetra): The page size never changes, so why do anything complicated
	// if we don't have to.
	@static page_size := -1
	if page_size != -1 do return page_size

	page_size = int(_unix_getpagesize())
	return page_size
}

@(private)
_processor_core_count :: proc() -> int {
	count : int = 0
	count_size := size_of(count)
	if _sysctlbyname("hw.logicalcpu", &count, &count_size, nil, 0) == 0 {
		if count > 0 {
			return count
		}
	}

	return 1
}


_alloc_command_line_arguments :: proc() -> []string {
	res := make([]string, len(runtime.args__))
	for arg, i in runtime.args__ {
		res[i] = string(arg)
	}
	return res
}
