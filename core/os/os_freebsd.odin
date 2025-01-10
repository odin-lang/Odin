package os

foreign import dl "system:dl"
foreign import libc "system:c"

import "base:runtime"
import "core:strings"
import "core:c"
import "core:sys/freebsd"

Handle :: distinct i32
File_Time :: distinct u64

INVALID_HANDLE :: ~Handle(0)

_Platform_Error :: enum i32 {
	NONE            = 0,
	EPERM           = 1,
	ENOENT          = 2,
	ESRCH           = 3,
	EINTR           = 4,
	EIO             = 5,
	ENXIO           = 6,
	E2BIG           = 7,
	ENOEXEC         = 8,
	EBADF           = 9,
	ECHILD          = 10,
	EBEADLK         = 11,
	ENOMEM          = 12,
	EACCESS         = 13,
	EFAULT          = 14,
	ENOTBLK         = 15,
	EBUSY           = 16,
	EEXIST          = 17,
	EXDEV           = 18,
	ENODEV          = 19,
	ENOTDIR         = 20,
	EISDIR          = 21,
	EINVAL          = 22,
	ENFILE          = 23,
	EMFILE          = 24,
	ENOTTY          = 25,
	ETXTBSY         = 26,
	EFBIG           = 27,
	ENOSPC          = 28,
	ESPIPE          = 29,
	EROFS           = 30,
	EMLINK          = 31,
	EPIPE           = 32,
	EDOM            = 33,
	ERANGE          = 34, /* Result too large */
	EAGAIN          = 35,
	EINPROGRESS     = 36,
	EALREADY        = 37,
	ENOTSOCK        = 38,
	EDESTADDRREQ    = 39,
	EMSGSIZE        = 40,
	EPROTOTYPE      = 41,
	ENOPROTOOPT     = 42,
	EPROTONOSUPPORT = 43,
	ESOCKTNOSUPPORT = 44,
	EOPNOTSUPP      = 45,
	EPFNOSUPPORT    = 46,
	EAFNOSUPPORT    = 47,
	EADDRINUSE      = 48,
	EADDRNOTAVAIL   = 49,
	ENETDOWN        = 50,
	ENETUNREACH     = 51,
	ENETRESET       = 52,
	ECONNABORTED    = 53,
	ECONNRESET      = 54,
	ENOBUFS         = 55,
	EISCONN         = 56,
	ENOTCONN        = 57,
	ESHUTDOWN       = 58,
	ETIMEDOUT       = 60,
	ECONNREFUSED    = 61,
	ELOOP           = 62,
	ENAMETOOLING    = 63,
	EHOSTDOWN       = 64,
	EHOSTUNREACH    = 65,
	ENOTEMPTY       = 66,
	EPROCLIM        = 67,
	EUSERS          = 68,
	EDQUOT          = 69,
	ESTALE          = 70,
	EBADRPC         = 72,
	ERPCMISMATCH    = 73,
	EPROGUNAVAIL    = 74,
	EPROGMISMATCH   = 75,
	EPROCUNAVAIL    = 76,
	ENOLCK          = 77,
	ENOSYS          = 78,
	EFTYPE          = 79,
	EAUTH           = 80,
	ENEEDAUTH       = 81,
	EIDRM           = 82,
	ENOMSG          = 83,
	EOVERFLOW       = 84,
	ECANCELED       = 85,
	EILSEQ          = 86,
	ENOATTR         = 87,
	EDOOFUS         = 88,
	EBADMSG         = 89,
	EMULTIHOP       = 90,
	ENOLINK         = 91,
	EPROTO          = 92,
	ENOTCAPABLE     = 93,
	ECAPMODE        = 94,
	ENOTRECOVERABLE = 95,
	EOWNERDEAD      = 96,
}
EPERM           :: Platform_Error.EPERM
ENOENT          :: Platform_Error.ENOENT
ESRCH           :: Platform_Error.ESRCH
EINTR           :: Platform_Error.EINTR
EIO             :: Platform_Error.EIO
ENXIO           :: Platform_Error.ENXIO
E2BIG           :: Platform_Error.E2BIG
ENOEXEC         :: Platform_Error.ENOEXEC
EBADF           :: Platform_Error.EBADF
ECHILD          :: Platform_Error.ECHILD
EBEADLK         :: Platform_Error.EBEADLK
ENOMEM          :: Platform_Error.ENOMEM
EACCESS         :: Platform_Error.EACCESS
EFAULT          :: Platform_Error.EFAULT
ENOTBLK         :: Platform_Error.ENOTBLK
EBUSY           :: Platform_Error.EBUSY
EEXIST          :: Platform_Error.EEXIST
EXDEV           :: Platform_Error.EXDEV
ENODEV          :: Platform_Error.ENODEV
ENOTDIR         :: Platform_Error.ENOTDIR
EISDIR          :: Platform_Error.EISDIR
EINVAL          :: Platform_Error.EINVAL
ENFILE          :: Platform_Error.ENFILE
EMFILE          :: Platform_Error.EMFILE
ENOTTY          :: Platform_Error.ENOTTY
ETXTBSY         :: Platform_Error.ETXTBSY
EFBIG           :: Platform_Error.EFBIG
ENOSPC          :: Platform_Error.ENOSPC
ESPIPE          :: Platform_Error.ESPIPE
EROFS           :: Platform_Error.EROFS
EMLINK          :: Platform_Error.EMLINK
EPIPE           :: Platform_Error.EPIPE
EDOM            :: Platform_Error.EDOM
ERANGE          :: Platform_Error.ERANGE
EAGAIN          :: Platform_Error.EAGAIN
EINPROGRESS     :: Platform_Error.EINPROGRESS
EALREADY        :: Platform_Error.EALREADY
ENOTSOCK        :: Platform_Error.ENOTSOCK
EDESTADDRREQ    :: Platform_Error.EDESTADDRREQ
EMSGSIZE        :: Platform_Error.EMSGSIZE
EPROTOTYPE      :: Platform_Error.EPROTOTYPE
ENOPROTOOPT     :: Platform_Error.ENOPROTOOPT
EPROTONOSUPPORT :: Platform_Error.EPROTONOSUPPORT
ESOCKTNOSUPPORT :: Platform_Error.ESOCKTNOSUPPORT
EOPNOTSUPP      :: Platform_Error.EOPNOTSUPP
EPFNOSUPPORT    :: Platform_Error.EPFNOSUPPORT
EAFNOSUPPORT    :: Platform_Error.EAFNOSUPPORT
EADDRINUSE      :: Platform_Error.EADDRINUSE
EADDRNOTAVAIL   :: Platform_Error.EADDRNOTAVAIL
ENETDOWN        :: Platform_Error.ENETDOWN
ENETUNREACH     :: Platform_Error.ENETUNREACH
ENETRESET       :: Platform_Error.ENETRESET
ECONNABORTED    :: Platform_Error.ECONNABORTED
ECONNRESET      :: Platform_Error.ECONNRESET
ENOBUFS         :: Platform_Error.ENOBUFS
EISCONN         :: Platform_Error.EISCONN
ENOTCONN        :: Platform_Error.ENOTCONN
ESHUTDOWN       :: Platform_Error.ESHUTDOWN
ETIMEDOUT       :: Platform_Error.ETIMEDOUT
ECONNREFUSED    :: Platform_Error.ECONNREFUSED
ELOOP           :: Platform_Error.ELOOP
ENAMETOOLING    :: Platform_Error.ENAMETOOLING
EHOSTDOWN       :: Platform_Error.EHOSTDOWN
EHOSTUNREACH    :: Platform_Error.EHOSTUNREACH
ENOTEMPTY       :: Platform_Error.ENOTEMPTY
EPROCLIM        :: Platform_Error.EPROCLIM
EUSERS          :: Platform_Error.EUSERS
EDQUOT          :: Platform_Error.EDQUOT
ESTALE          :: Platform_Error.ESTALE
EBADRPC         :: Platform_Error.EBADRPC
ERPCMISMATCH    :: Platform_Error.ERPCMISMATCH
EPROGUNAVAIL    :: Platform_Error.EPROGUNAVAIL
EPROGMISMATCH   :: Platform_Error.EPROGMISMATCH
EPROCUNAVAIL    :: Platform_Error.EPROCUNAVAIL
ENOLCK          :: Platform_Error.ENOLCK
ENOSYS          :: Platform_Error.ENOSYS
EFTYPE          :: Platform_Error.EFTYPE
EAUTH           :: Platform_Error.EAUTH
ENEEDAUTH       :: Platform_Error.ENEEDAUTH
EIDRM           :: Platform_Error.EIDRM
ENOMSG          :: Platform_Error.ENOMSG
EOVERFLOW       :: Platform_Error.EOVERFLOW
ECANCELED       :: Platform_Error.ECANCELED
EILSEQ          :: Platform_Error.EILSEQ
ENOATTR         :: Platform_Error.ENOATTR
EDOOFUS         :: Platform_Error.EDOOFUS
EBADMSG         :: Platform_Error.EBADMSG
EMULTIHOP       :: Platform_Error.EMULTIHOP
ENOLINK         :: Platform_Error.ENOLINK
EPROTO          :: Platform_Error.EPROTO
ENOTCAPABLE     :: Platform_Error.ENOTCAPABLE
ECAPMODE        :: Platform_Error.ECAPMODE
ENOTRECOVERABLE :: Platform_Error.ENOTRECOVERABLE
EOWNERDEAD      :: Platform_Error.EOWNERDEAD

O_RDONLY   :: 0x00000
O_WRONLY   :: 0x00001
O_RDWR     :: 0x00002
O_NONBLOCK :: 0x00004
O_APPEND   :: 0x00008
O_ASYNC    :: 0x00040
O_SYNC     :: 0x00080
O_CREATE   :: 0x00200
O_TRUNC    :: 0x00400
O_EXCL     :: 0x00800
O_NOCTTY   :: 0x08000
O_CLOEXEC  :: 0100000


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

KINFO_FILE_SIZE :: 1392

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

KInfo_File :: struct {
	structsize: c.int,
	type:       c.int,
	fd:         c.int,
	ref_count:  c.int,
	flags:      c.int,
	pad0:       c.int,
	offset:     i64,

	// NOTE(Feoramund): This field represents a complicated union that I am
	// avoiding implementing for now. I only need the path data below.
	_union: [336]byte,

	path: [MAX_PATH]c.char,
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


@(require_results) S_ISLNK  :: #force_inline proc(m: mode_t) -> bool { return (m & S_IFMT) == S_IFLNK  }
@(require_results) S_ISREG  :: #force_inline proc(m: mode_t) -> bool { return (m & S_IFMT) == S_IFREG  }
@(require_results) S_ISDIR  :: #force_inline proc(m: mode_t) -> bool { return (m & S_IFMT) == S_IFDIR  }
@(require_results) S_ISCHR  :: #force_inline proc(m: mode_t) -> bool { return (m & S_IFMT) == S_IFCHR  }
@(require_results) S_ISBLK  :: #force_inline proc(m: mode_t) -> bool { return (m & S_IFMT) == S_IFBLK  }
@(require_results) S_ISFIFO :: #force_inline proc(m: mode_t) -> bool { return (m & S_IFMT) == S_IFIFO  }
@(require_results) S_ISSOCK :: #force_inline proc(m: mode_t) -> bool { return (m & S_IFMT) == S_IFSOCK }

F_OK :: 0 // Test for file existance
X_OK :: 1 // Test for execute permission
W_OK :: 2 // Test for write permission
R_OK :: 4 // Test for read permission

F_KINFO :: 22

foreign libc {
	@(link_name="__error")		__Error_location :: proc() -> ^c.int ---

	@(link_name="open")             _unix_open          :: proc(path: cstring, flags: c.int, #c_vararg mode: ..u16) -> Handle ---
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
	@(link_name="fcntl")            _unix_fcntl         :: proc(fd: Handle, cmd: c.int, #c_vararg args: ..any) -> c.int ---
	@(link_name="dup")              _unix_dup           :: proc(fd: Handle) -> Handle ---
	
	@(link_name="fdopendir")        _unix_fdopendir     :: proc(fd: Handle) -> Dir ---
	@(link_name="closedir")         _unix_closedir      :: proc(dirp: Dir) -> c.int ---
	@(link_name="rewinddir")        _unix_rewinddir     :: proc(dirp: Dir) ---
	@(link_name="readdir_r")        _unix_readdir_r     :: proc(dirp: Dir, entry: ^Dirent, result: ^^Dirent) -> c.int ---

	@(link_name="malloc")           _unix_malloc        :: proc(size: c.size_t) -> rawptr ---
	@(link_name="calloc")           _unix_calloc        :: proc(num, size: c.size_t) -> rawptr ---
	@(link_name="free")             _unix_free          :: proc(ptr: rawptr) ---
	@(link_name="realloc")          _unix_realloc       :: proc(ptr: rawptr, size: c.size_t) -> rawptr ---
	
	@(link_name="getenv")           _unix_getenv        :: proc(cstring) -> cstring ---
	@(link_name="realpath")         _unix_realpath      :: proc(path: cstring, resolved_path: [^]byte = nil) -> cstring ---
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

@(require_results)
is_path_separator :: proc(r: rune) -> bool {
	return r == '/'
}

@(require_results, no_instrumentation)
get_last_error :: proc "contextless" () -> Error {
	return Platform_Error(__Error_location()^)
}

@(require_results)
open :: proc(path: string, flags: int = O_RDONLY, mode: int = 0) -> (Handle, Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	handle := _unix_open(cstr, c.int(flags), u16(mode))
	if handle == -1 {
		return INVALID_HANDLE, get_last_error()
	}
	return handle, nil
}

close :: proc(fd: Handle) -> Error {
	result := _unix_close(fd)
	if result == -1 {
		return get_last_error()
	}
	return nil
}

flush :: proc(fd: Handle) -> Error {
	return cast(_Platform_Error)freebsd.fsync(cast(freebsd.Fd)fd)
}

// If you read or write more than `INT_MAX` bytes, FreeBSD returns `EINVAL`.
// In practice a read/write call would probably never read/write these big buffers all at once,
// which is why the number of bytes is returned and why there are procs that will call this in a
// loop for you.
// We set a max of 1GB to keep alignment and to be safe.
@(private)
MAX_RW :: 1 << 30

read :: proc(fd: Handle, data: []byte) -> (int, Error) {
	to_read    := min(c.size_t(len(data)), MAX_RW)
	bytes_read := _unix_read(fd, &data[0], to_read)
	if bytes_read == -1 {
		return -1, get_last_error()
	}
	return int(bytes_read), nil
}

write :: proc(fd: Handle, data: []byte) -> (int, Error) {
	if len(data) == 0 {
		return 0, nil
	}

	to_write      := min(c.size_t(len(data)), MAX_RW)
	bytes_written := _unix_write(fd, &data[0], to_write)
	if bytes_written == -1 {
		return -1, get_last_error()
	}
	return int(bytes_written), nil
}

read_at :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Error) {
	if len(data) == 0 {
		return 0, nil
	}

	to_read := min(uint(len(data)), MAX_RW)

	bytes_read, errno := freebsd.pread(cast(freebsd.Fd)fd, data[:to_read], cast(freebsd.off_t)offset)

	return bytes_read, cast(_Platform_Error)errno
}

write_at :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Error) {
	if len(data) == 0 {
		return 0, nil
	}

	to_write := min(uint(len(data)), MAX_RW)

	bytes_written, errno := freebsd.pwrite(cast(freebsd.Fd)fd, data[:to_write], cast(freebsd.off_t)offset)

	return bytes_written, cast(_Platform_Error)errno
}

seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Error) {
	switch whence {
	case SEEK_SET, SEEK_CUR, SEEK_END:
		break
	case:
		return 0, .Invalid_Whence
	}
	res := _unix_seek(fd, offset, c.int(whence))
	if res == -1 {
		errno := get_last_error()
		switch errno {
		case .EINVAL:
			return 0, .Invalid_Offset
		case:
			return 0, errno
		}
	}
	return res, nil
}

@(require_results)
file_size :: proc(fd: Handle) -> (size: i64, err: Error) {
	size = -1
	s := _fstat(fd) or_return
	size = s.size
	return
}

rename :: proc(old_path, new_path: string) -> Error {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	old_path_cstr := strings.clone_to_cstring(old_path, context.temp_allocator)
	new_path_cstr := strings.clone_to_cstring(new_path, context.temp_allocator)
	res := _unix_rename(old_path_cstr, new_path_cstr)
	if res == -1 {
		return get_last_error()
	}
	return nil
}

remove :: proc(path: string) -> Error {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	res := _unix_unlink(path_cstr)
	if res == -1 {
		return get_last_error()
	}
	return nil
}

make_directory :: proc(path: string, mode: mode_t = 0o775) -> Error {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	res := _unix_mkdir(path_cstr, mode)
	if res == -1 {
		return get_last_error()
	}
	return nil
}

remove_directory :: proc(path: string) -> Error {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	res := _unix_rmdir(path_cstr)
	if res == -1 {
		return get_last_error()
	}
	return nil
}

@(require_results)
is_file_handle :: proc(fd: Handle) -> bool {
	s, err := _fstat(fd)
	if err != nil {
		return false
	}
	return S_ISREG(s.mode)
}

@(require_results)
is_file_path :: proc(path: string, follow_links: bool = true) -> bool {
	s: OS_Stat
	err: Error
	if follow_links {
		s, err = _stat(path)
	} else {
		s, err = _lstat(path)
	}
	if err != nil {
		return false
	}
	return S_ISREG(s.mode)
}

@(require_results)
is_dir_handle :: proc(fd: Handle) -> bool {
	s, err := _fstat(fd)
	if err != nil {
		return false
	}
	return S_ISDIR(s.mode)
}

@(require_results)
is_dir_path :: proc(path: string, follow_links: bool = true) -> bool {
	s: OS_Stat
	err: Error
	if follow_links {
		s, err = _stat(path)
	} else {
		s, err = _lstat(path)
	}
	if err != nil {
		return false
	}
	return S_ISDIR(s.mode)
}

is_file :: proc {is_file_path, is_file_handle}
is_dir :: proc {is_dir_path, is_dir_handle}

@(require_results)
exists :: proc(path: string) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cpath := strings.clone_to_cstring(path, context.temp_allocator)
	res := _unix_access(cpath, O_RDONLY)
	return res == 0
}

// NOTE(bill): Uses startup to initialize it

stdin: Handle  = 0
stdout: Handle = 1
stderr: Handle = 2

/* TODO(zangent): Implement these!                                                                                   
last_write_time :: proc(fd: Handle) -> File_Time {}                                                                  
last_write_time_by_name :: proc(name: string) -> File_Time {}                                                        
*/
@(require_results)
last_write_time :: proc(fd: Handle) -> (File_Time, Error) {
	s, err := _fstat(fd)
	if err != nil {
		return 0, err
	}
	modified := s.modified.seconds * 1_000_000_000 + s.modified.nanoseconds
	return File_Time(modified), nil
}

@(require_results)
last_write_time_by_name :: proc(name: string) -> (File_Time, Error) {
	s, err := _stat(name)
	if err != nil {
		return 0, err
	}
	modified := s.modified.seconds * 1_000_000_000 + s.modified.nanoseconds
	return File_Time(modified), nil
}

@(private, require_results)
_stat :: proc(path: string) -> (OS_Stat, Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	s: OS_Stat = ---
	result := _unix_lstat(cstr, &s)
	if result == -1 {
		return s, get_last_error()
	}
	return s, nil
}

@(private, require_results)
_lstat :: proc(path: string) -> (OS_Stat, Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	
	// deliberately uninitialized
	s: OS_Stat = ---
	res := _unix_lstat(cstr, &s)
	if res == -1 {
		return s, get_last_error()
	}
	return s, nil
}

@(private, require_results)
_fstat :: proc(fd: Handle) -> (OS_Stat, Error) {
	s: OS_Stat = ---
	result := _unix_fstat(fd, &s)
	if result == -1 {
		return s, get_last_error()
	}
	return s, nil
}

@(private, require_results)
_fdopendir :: proc(fd: Handle) -> (Dir, Error) {
	dirp := _unix_fdopendir(fd)
	if dirp == cast(Dir)nil {
		return nil, get_last_error()
	}
	return dirp, nil
}

@(private)
_closedir :: proc(dirp: Dir) -> Error {
	rc := _unix_closedir(dirp)
	if rc != 0 {
		return get_last_error()
	}
	return nil
}

@(private)
_rewinddir :: proc(dirp: Dir) {
	_unix_rewinddir(dirp)
}

@(private, require_results)
_readdir :: proc(dirp: Dir) -> (entry: Dirent, err: Error, end_of_stream: bool) {
	result: ^Dirent
	rc := _unix_readdir_r(dirp, &entry, &result)

	if rc != 0 {
		err = get_last_error()
		return
	}

	if result == nil {
		end_of_stream = true
		return
	}

	return
}

@(private, require_results)
_readlink :: proc(path: string) -> (string, Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == context.allocator)

	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)

	bufsz : uint = MAX_PATH
	buf := make([]byte, MAX_PATH)
	for {
		rc := _unix_readlink(path_cstr, &(buf[0]), bufsz)
		if rc == -1 {
			delete(buf)
			return "", get_last_error()
		} else if rc == int(bufsz) {
			bufsz += MAX_PATH
			delete(buf)
			buf = make([]byte, bufsz)
		} else {
			return strings.string_from_ptr(&buf[0], rc), nil
		}	
	}

	return "", Error{}
}

@(private, require_results)
_dup :: proc(fd: Handle) -> (Handle, Error) {
	dup := _unix_dup(fd)
	if dup == -1 {
		return INVALID_HANDLE, get_last_error()
	}
	return dup, nil
}

@(require_results)
absolute_path_from_handle :: proc(fd: Handle) -> (string, Error) {
	// NOTE(Feoramund): The situation isn't ideal, but this was the best way I
	// could find to implement this. There are a couple outstanding bug reports
	// regarding the desire to retrieve an absolute path from a handle, but to
	// my knowledge, there hasn't been any work done on it.
	//
	// https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=198570
	//
	// This may be unreliable, according to a comment from 2023.

	kinfo: KInfo_File
	kinfo.structsize = KINFO_FILE_SIZE

	res := _unix_fcntl(fd, F_KINFO, cast(uintptr)&kinfo)
	if res == -1 {
		return "", get_last_error()
	}

	path := strings.clone_from_cstring_bounded(cast(cstring)&kinfo.path[0], len(kinfo.path))
	return path, nil
}

@(require_results)
absolute_path_from_relative :: proc(rel: string, allocator := context.allocator) -> (path: string, err: Error) {
	rel := rel
	if rel == "" {
		rel = "."
	}
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == context.allocator)

	rel_cstr := strings.clone_to_cstring(rel, context.temp_allocator)

	path_ptr := _unix_realpath(rel_cstr, nil)
	if path_ptr == nil {
		return "", get_last_error()
	}
	defer _unix_free(rawptr(path_ptr))

	return strings.clone(string(path_ptr), allocator)
}

access :: proc(path: string, mask: int) -> (bool, Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	result := _unix_access(cstr, c.int(mask))
	if result == -1 {
		return false, get_last_error()
	}
	return true, nil
}

@(require_results)
lookup_env :: proc(key: string, allocator := context.allocator) -> (value: string, found: bool) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == allocator)

	path_str := strings.clone_to_cstring(key, context.temp_allocator)
	cstr := _unix_getenv(path_str)
	if cstr == nil {
		return "", false
	}
	return strings.clone(string(cstr), allocator), true
}

@(require_results)
get_env :: proc(key: string, allocator := context.allocator) -> (value: string) {
	value, _ = lookup_env(key, allocator)
	return
}

@(require_results)
get_current_directory :: proc(allocator := context.allocator) -> string {
	context.allocator = allocator
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
		if get_last_error() != ERANGE {
			delete(buf)
			return ""
		}
		resize(&buf, len(buf)+page_size)
	}
	unreachable()
}

set_current_directory :: proc(path: string) -> (err: Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	res := _unix_chdir(cstr)
	if res == -1 {
		return get_last_error()
	}
	return nil
}

exit :: proc "contextless" (code: int) -> ! {
	runtime._cleanup_runtime_contextless()
	_unix_exit(c.int(code))
}

@(require_results)
current_thread_id :: proc "contextless" () -> int {
	return cast(int) pthread_getthreadid_np()
}

@(require_results)
dlopen :: proc(filename: string, flags: int) -> rawptr {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(filename, context.temp_allocator)
	handle := _unix_dlopen(cstr, c.int(flags))
	return handle
}
@(require_results)
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

@(require_results)
get_page_size :: proc() -> int {
	// NOTE(tetra): The page size never changes, so why do anything complicated
	// if we don't have to.
	@static page_size := -1
	if page_size != -1 {
		return page_size
	}

	page_size = int(_unix_getpagesize())
	return page_size
}

@(private, require_results)
_processor_core_count :: proc() -> int {
	count : int = 0
	count_size := size_of(count)
	if _sysctlbyname("hw.ncpu", &count, &count_size, nil, 0) == 0 {
		if count > 0 {
			return count
		}
	}

	return 1
}


@(require_results)
_alloc_command_line_arguments :: proc() -> []string {
	res := make([]string, len(runtime.args__))
	for arg, i in runtime.args__ {
		res[i] = string(arg)
	}
	return res
}
