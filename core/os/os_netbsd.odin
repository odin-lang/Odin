package os

foreign import dl "system:dl"
foreign import libc "system:c"

import "base:runtime"
import "core:strings"
import "core:c"

Handle :: distinct i32
File_Time :: distinct u64

INVALID_HANDLE :: ~Handle(0)

_Platform_Error :: enum i32 {
	NONE            = 0,
	EPERM           = 1,          /* Operation not permitted */
	ENOENT          = 2,          /* No such file or directory */
	EINTR           = 4,          /* Interrupted system call */
	ESRCH           = 3,          /* No such process */
	EIO             = 5,          /* Input/output error */
	ENXIO           = 6,          /* Device not configured */
	E2BIG           = 7,          /* Argument list too long */
	ENOEXEC         = 8,          /* Exec format error */
	EBADF           = 9,          /* Bad file descriptor */
	ECHILD          = 10,         /* No child processes */
	EDEADLK         = 11,         /* Resource deadlock avoided. 11 was EAGAIN */
	ENOMEM          = 12,         /* Cannot allocate memory */
	EACCES          = 13,         /* Permission denied */
	EFAULT          = 14,         /* Bad address */
	ENOTBLK         = 15,         /* Block device required */
	EBUSY           = 16,         /* Device busy */
	EEXIST          = 17,         /* File exists */
	EXDEV           = 18,         /* Cross-device link */
	ENODEV          = 19,         /* Operation not supported by device */
	ENOTDIR         = 20,         /* Not a directory */
	EISDIR          = 21,         /* Is a directory */
	EINVAL          = 22,         /* Invalid argument */
	ENFILE          = 23,         /* Too many open files in system */
	EMFILE          = 24,         /* Too many open files */
	ENOTTY          = 25,         /* Inappropriate ioctl for device */
	ETXTBSY         = 26,         /* Text file busy */
	EFBIG           = 27,         /* File too large */
	ENOSPC          = 28,         /* No space left on device */
	ESPIPE          = 29,         /* Illegal seek */
	EROFS           = 30,         /* Read-only file system */
	EMLINK          = 31,         /* Too many links */
	EPIPE           = 32,         /* Broken pipe */

	/* math software */
	EDOM            = 33,         /* Numerical argument out of domain */
	ERANGE          = 34,         /* Result too large or too small */

	/* non-blocking and interrupt i/o */
	EAGAIN          = 35,         /* Resource temporarily unavailable */
	EWOULDBLOCK     = EAGAIN,     /*  Operation would block */
	EINPROGRESS     = 36,         /* Operation now in progress */
	EALREADY        = 37,         /* Operation already in progress */

	/* ipc/network software -- argument errors */
	ENOTSOCK        = 38,         /* Socket operation on non-socket */
	EDESTADDRREQ    = 39,         /* Destination address required */
	EMSGSIZE        = 40,         /* Message too long */
	EPROTOTYPE      = 41,         /* Protocol wrong type for socket */
	ENOPROTOOPT     = 42,         /* Protocol option not available */
	EPROTONOSUPPORT = 43,         /* Protocol not supported */
	ESOCKTNOSUPPORT = 44,         /* Socket type not supported */
	EOPNOTSUPP      = 45,         /* Operation not supported */
	EPFNOSUPPORT    = 46,         /* Protocol family not supported */
	EAFNOSUPPORT    = 47,         /* Address family not supported by protocol family */
	EADDRINUSE      = 48,         /* Address already in use */
	EADDRNOTAVAIL   = 49,         /* Can't assign requested address */

	/* ipc/network software -- operational errors */
	ENETDOWN        = 50,         /* Network is down */
	ENETUNREACH     = 51,         /* Network is unreachable */
	ENETRESET       = 52,         /* Network dropped connection on reset */
	ECONNABORTED    = 53,         /* Software caused connection abort */
	ECONNRESET      = 54,         /* Connection reset by peer */
	ENOBUFS         = 55,         /* No buffer space available */
	EISCONN         = 56,         /* Socket is already connected */
	ENOTCONN        = 57,         /* Socket is not connected */
	ESHUTDOWN       = 58,         /* Can't send after socket shutdown */
	ETOOMANYREFS    = 59,         /* Too many references: can't splice */
	ETIMEDOUT       = 60,         /* Operation timed out */
	ECONNREFUSED    = 61,         /* Connection refused */

	ELOOP           = 62,         /* Too many levels of symbolic links */
	ENAMETOOLONG    = 63,         /* File name too long */

	/* should be rearranged */
	EHOSTDOWN       = 64,         /* Host is down */
	EHOSTUNREACH    = 65,         /* No route to host */
	ENOTEMPTY       = 66,         /* Directory not empty */

	/* quotas & mush */
	EPROCLIM        = 67,         /* Too many processes */
	EUSERS          = 68,         /* Too many users */
	EDQUOT          = 69,         /* Disc quota exceeded */

	/* Network File System */
	ESTALE          = 70,         /* Stale NFS file handle */
	EREMOTE         = 71,         /* Too many levels of remote in path */
	EBADRPC         = 72,         /* RPC struct is bad */
	ERPCMISMATCH    = 73,         /* RPC version wrong */
	EPROGUNAVAIL    = 74,         /* RPC prog. not avail */
	EPROGMISMATCH   = 75,         /* Program version wrong */
	EPROCUNAVAIL    = 76,         /* Bad procedure for program */

	ENOLCK          = 77,         /* No locks available */
	ENOSYS          = 78,         /* Function not implemented */

	EFTYPE          = 79,         /* Inappropriate file type or format */
	EAUTH           = 80,         /* Authentication error */
	ENEEDAUTH       = 81,         /* Need authenticator */

	/* SystemV IPC */
	EIDRM           = 82,         /* Identifier removed */
	ENOMSG          = 83,         /* No message of desired type */
	EOVERFLOW       = 84,         /* Value too large to be stored in data type */

	/* Wide/multibyte-character handling, ISO/IEC 9899/AMD1:1995 */
	EILSEQ          = 85,         /* Illegal byte sequence */

	/* From IEEE Std 1003.1-2001 */
	/* Base, Realtime, Threads or Thread Priority Scheduling option errors */
	ENOTSUP         = 86,         /* Not supported */

	/* Realtime option errors */
	ECANCELED       = 87,         /* Operation canceled */

	/* Realtime, XSI STREAMS option errors */
	EBADMSG         = 88,         /* Bad or Corrupt message */

	/* XSI STREAMS option errors  */
	ENODATA         = 89,         /* No message available */
	ENOSR           = 90,         /* No STREAM resources */
	ENOSTR          = 91,         /* Not a STREAM */
	ETIME           = 92,         /* STREAM ioctl timeout */

	/* File system extended attribute errors */
	ENOATTR         = 93,         /* Attribute not found */

	/* Realtime, XSI STREAMS option errors */
	EMULTIHOP       = 94,         /* Multihop attempted */
	ENOLINK         = 95,         /* Link has been severed */
	EPROTO          = 96,         /* Protocol error */

	/* Robust mutexes */
	EOWNERDEAD      = 97,         /* Previous owner died */
	ENOTRECOVERABLE = 98,         /* State not recoverable */

	ELAST           = 98,         /* Must equal largest Error */
}

EPERM           :: Platform_Error.EPERM           /* Operation not permitted */
ENOENT          :: Platform_Error.ENOENT          /* No such file or directory */
EINTR           :: Platform_Error.EINTR           /* Interrupted system call */
ESRCH           :: Platform_Error.ESRCH           /* No such process */
EIO             :: Platform_Error.EIO             /* Input/output error */
ENXIO           :: Platform_Error.ENXIO           /* Device not configured */
E2BIG           :: Platform_Error.E2BIG           /* Argument list too long */
ENOEXEC         :: Platform_Error.ENOEXEC         /* Exec format error */
EBADF           :: Platform_Error.EBADF           /* Bad file descriptor */
ECHILD          :: Platform_Error.ECHILD          /* No child processes */
EDEADLK         :: Platform_Error.EDEADLK         /* Resource deadlock avoided. 11 was EAGAIN */
ENOMEM          :: Platform_Error.ENOMEM          /* Cannot allocate memory */
EACCES          :: Platform_Error.EACCES          /* Permission denied */
EFAULT          :: Platform_Error.EFAULT          /* Bad address */
ENOTBLK         :: Platform_Error.ENOTBLK         /* Block device required */
EBUSY           :: Platform_Error.EBUSY           /* Device busy */
EEXIST          :: Platform_Error.EEXIST          /* File exists */
EXDEV           :: Platform_Error.EXDEV           /* Cross-device link */
ENODEV          :: Platform_Error.ENODEV          /* Operation not supported by device */
ENOTDIR         :: Platform_Error.ENOTDIR         /* Not a directory */
EISDIR          :: Platform_Error.EISDIR          /* Is a directory */
EINVAL          :: Platform_Error.EINVAL          /* Invalid argument */
ENFILE          :: Platform_Error.ENFILE          /* Too many open files in system */
EMFILE          :: Platform_Error.EMFILE          /* Too many open files */
ENOTTY          :: Platform_Error.ENOTTY          /* Inappropriate ioctl for device */
ETXTBSY         :: Platform_Error.ETXTBSY         /* Text file busy */
EFBIG           :: Platform_Error.EFBIG           /* File too large */
ENOSPC          :: Platform_Error.ENOSPC          /* No space left on device */
ESPIPE          :: Platform_Error.ESPIPE          /* Illegal seek */
EROFS           :: Platform_Error.EROFS           /* Read-only file system */
EMLINK          :: Platform_Error.EMLINK          /* Too many links */
EPIPE           :: Platform_Error.EPIPE           /* Broken pipe */

/* math software */
EDOM            :: Platform_Error.EDOM            /* Numerical argument out of domain */
ERANGE          :: Platform_Error.ERANGE          /* Result too large or too small */

/* non-blocking and interrupt i/o */
EAGAIN          :: Platform_Error.EAGAIN          /* Resource temporarily unavailable */
EWOULDBLOCK     :: EAGAIN        /*  Operation would block */
EINPROGRESS     :: Platform_Error.EINPROGRESS     /* Operation now in progress */
EALREADY        :: Platform_Error.EALREADY        /* Operation already in progress */

/* ipc/network software -- argument errors */
ENOTSOCK        :: Platform_Error.ENOTSOCK        /* Socket operation on non-socket */
EDESTADDRREQ    :: Platform_Error.EDESTADDRREQ    /* Destination address required */
EMSGSIZE        :: Platform_Error.EMSGSIZE        /* Message too long */
EPROTOTYPE      :: Platform_Error.EPROTOTYPE      /* Protocol wrong type for socket */
ENOPROTOOPT     :: Platform_Error.ENOPROTOOPT     /* Protocol option not available */
EPROTONOSUPPORT :: Platform_Error.EPROTONOSUPPORT /* Protocol not supported */
ESOCKTNOSUPPORT :: Platform_Error.ESOCKTNOSUPPORT /* Socket type not supported */
EOPNOTSUPP      :: Platform_Error.EOPNOTSUPP      /* Operation not supported */
EPFNOSUPPORT    :: Platform_Error.EPFNOSUPPORT    /* Protocol family not supported */
EAFNOSUPPORT    :: Platform_Error.EAFNOSUPPORT    /* Address family not supported by protocol family */
EADDRINUSE      :: Platform_Error.EADDRINUSE      /* Address already in use */
EADDRNOTAVAIL   :: Platform_Error.EADDRNOTAVAIL   /* Can't assign requested address */

/* ipc/network software -- operational errors */
ENETDOWN        :: Platform_Error.ENETDOWN        /* Network is down */
ENETUNREACH     :: Platform_Error.ENETUNREACH     /* Network is unreachable */
ENETRESET       :: Platform_Error.ENETRESET       /* Network dropped connection on reset */
ECONNABORTED    :: Platform_Error.ECONNABORTED    /* Software caused connection abort */
ECONNRESET      :: Platform_Error.ECONNRESET      /* Connection reset by peer */
ENOBUFS         :: Platform_Error.ENOBUFS         /* No buffer space available */
EISCONN         :: Platform_Error.EISCONN         /* Socket is already connected */
ENOTCONN        :: Platform_Error.ENOTCONN        /* Socket is not connected */
ESHUTDOWN       :: Platform_Error.ESHUTDOWN       /* Can't send after socket shutdown */
ETOOMANYREFS    :: Platform_Error.ETOOMANYREFS    /* Too many references: can't splice */
ETIMEDOUT       :: Platform_Error.ETIMEDOUT       /* Operation timed out */
ECONNREFUSED    :: Platform_Error.ECONNREFUSED    /* Connection refused */

ELOOP           :: Platform_Error.ELOOP           /* Too many levels of symbolic links */
ENAMETOOLONG    :: Platform_Error.ENAMETOOLONG    /* File name too long */

/* should be rearranged */
EHOSTDOWN       :: Platform_Error.EHOSTDOWN       /* Host is down */
EHOSTUNREACH    :: Platform_Error.EHOSTUNREACH    /* No route to host */
ENOTEMPTY       :: Platform_Error.ENOTEMPTY       /* Directory not empty */

/* quotas & mush */
EPROCLIM        :: Platform_Error.EPROCLIM        /* Too many processes */
EUSERS          :: Platform_Error.EUSERS          /* Too many users */
EDQUOT          :: Platform_Error.EDQUOT          /* Disc quota exceeded */

/* Network File System */
ESTALE          :: Platform_Error.ESTALE          /* Stale NFS file handle */
EREMOTE         :: Platform_Error.EREMOTE         /* Too many levels of remote in path */
EBADRPC         :: Platform_Error.EBADRPC         /* RPC struct is bad */
ERPCMISMATCH    :: Platform_Error.ERPCMISMATCH    /* RPC version wrong */
EPROGUNAVAIL    :: Platform_Error.EPROGUNAVAIL    /* RPC prog. not avail */
EPROGMISMATCH   :: Platform_Error.EPROGMISMATCH   /* Program version wrong */
EPROCUNAVAIL    :: Platform_Error.EPROCUNAVAIL    /* Bad procedure for program */

ENOLCK          :: Platform_Error.ENOLCK          /* No locks available */
ENOSYS          :: Platform_Error.ENOSYS          /* Function not implemented */

EFTYPE          :: Platform_Error.EFTYPE          /* Inappropriate file type or format */
EAUTH           :: Platform_Error.EAUTH           /* Authentication error */
ENEEDAUTH       :: Platform_Error.ENEEDAUTH       /* Need authenticator */

/* SystemV IPC */
EIDRM           :: Platform_Error.EIDRM           /* Identifier removed */
ENOMSG          :: Platform_Error.ENOMSG          /* No message of desired type */
EOVERFLOW       :: Platform_Error.EOVERFLOW       /* Value too large to be stored in data type */

/* Wide/multibyte-character handling, ISO/IEC 9899/AMD1:1995 */
EILSEQ          :: Platform_Error.EILSEQ          /* Illegal byte sequence */

/* From IEEE Std 1003.1-2001 */
/* Base, Realtime, Threads or Thread Priority Scheduling option errors */
ENOTSUP         :: Platform_Error.ENOTSUP         /* Not supported */

/* Realtime option errors */
ECANCELED       :: Platform_Error.ECANCELED       /* Operation canceled */

/* Realtime, XSI STREAMS option errors */
EBADMSG         :: Platform_Error.EBADMSG         /* Bad or Corrupt message */

/* XSI STREAMS option errors  */
ENODATA         :: Platform_Error.ENODATA         /* No message available */
ENOSR           :: Platform_Error.ENOSR           /* No STREAM resources */
ENOSTR          :: Platform_Error.ENOSTR          /* Not a STREAM */
ETIME           :: Platform_Error.ETIME           /* STREAM ioctl timeout */

/* File system extended attribute errors */
ENOATTR         :: Platform_Error.ENOATTR         /* Attribute not found */

/* Realtime, XSI STREAMS option errors */
EMULTIHOP       :: Platform_Error.EMULTIHOP       /* Multihop attempted */
ENOLINK         :: Platform_Error.ENOLINK         /* Link has been severed */
EPROTO          :: Platform_Error.EPROTO          /* Protocol error */

/* Robust mutexes */
EOWNERDEAD      :: Platform_Error.EOWNERDEAD      /* Previous owner died */
ENOTRECOVERABLE :: Platform_Error.ENOTRECOVERABLE /* State not recoverable */

ELAST           :: Platform_Error.ELAST           /* Must equal largest Error */

/* end of Error */

O_RDONLY   :: 0x000000000
O_WRONLY   :: 0x000000001
O_RDWR     :: 0x000000002
O_CREATE   :: 0x000000200
O_EXCL     :: 0x000000800
O_NOCTTY   :: 0x000008000
O_TRUNC    :: 0x000000400
O_NONBLOCK :: 0x000000004
O_APPEND   :: 0x000000008
O_SYNC     :: 0x000000080
O_ASYNC    :: 0x000000040
O_CLOEXEC  :: 0x000400000

RTLD_LAZY         :: 0x001
RTLD_NOW          :: 0x002
RTLD_GLOBAL       :: 0x100
RTLD_LOCAL        :: 0x200
RTLD_TRACE        :: 0x200
RTLD_NODELETE     :: 0x01000
RTLD_NOLOAD       :: 0x02000

F_GETPATH :: 15

MAX_PATH :: 1024
MAXNAMLEN :: 511

args := _alloc_command_line_arguments()

Unix_File_Time :: struct {
	seconds: time_t,
	nanoseconds: c.long,
}

dev_t :: u64
ino_t :: u64
nlink_t :: u32
off_t :: i64
mode_t :: u32
pid_t :: u32
uid_t :: u32
gid_t :: u32
blkcnt_t :: i64
blksize_t :: i32
fflags_t :: u32
time_t :: i64

OS_Stat :: struct {
	device_id: dev_t,
	mode: mode_t,
	_padding0: i16,
	ino: ino_t,
	nlink: nlink_t,
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
	gen: u32,
	lspare: [2]u32,
}

Dirent :: struct {
	ino: ino_t,
	reclen: u16,
	namlen: u16,
	type: u8,
	name: [MAXNAMLEN + 1]byte,
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

@(require_results) S_ISLNK  :: #force_inline proc "contextless" (m: mode_t) -> bool { return (m & S_IFMT) == S_IFLNK  }
@(require_results) S_ISREG  :: #force_inline proc "contextless" (m: mode_t) -> bool { return (m & S_IFMT) == S_IFREG  }
@(require_results) S_ISDIR  :: #force_inline proc "contextless" (m: mode_t) -> bool { return (m & S_IFMT) == S_IFDIR  }
@(require_results) S_ISCHR  :: #force_inline proc "contextless" (m: mode_t) -> bool { return (m & S_IFMT) == S_IFCHR  }
@(require_results) S_ISBLK  :: #force_inline proc "contextless" (m: mode_t) -> bool { return (m & S_IFMT) == S_IFBLK  }
@(require_results) S_ISFIFO :: #force_inline proc "contextless" (m: mode_t) -> bool { return (m & S_IFMT) == S_IFIFO  }
@(require_results) S_ISSOCK :: #force_inline proc "contextless" (m: mode_t) -> bool { return (m & S_IFMT) == S_IFSOCK }

F_OK :: 0 // Test for file existance
X_OK :: 1 // Test for execute permission
W_OK :: 2 // Test for write permission
R_OK :: 4 // Test for read permission

foreign libc {
	@(link_name="__errno")          __errno_location    :: proc() -> ^c.int ---

	@(link_name="open")             _unix_open          :: proc(path: cstring, flags: c.int, #c_vararg mode: ..u32) -> Handle ---
	@(link_name="close")            _unix_close         :: proc(fd: Handle) -> c.int ---
	@(link_name="read")             _unix_read          :: proc(fd: Handle, buf: rawptr, size: c.size_t) -> c.ssize_t ---
	@(link_name="pread")            _unix_pread         :: proc(fd: Handle, buf: rawptr, size: c.size_t, offset: i64) -> c.ssize_t ---
	@(link_name="write")            _unix_write         :: proc(fd: Handle, buf: rawptr, size: c.size_t) -> c.ssize_t ---
	@(link_name="pwrite")           _unix_pwrite        :: proc(fd: Handle, buf: rawptr, size: c.size_t, offset: i64) -> c.ssize_t ---
	@(link_name="lseek")            _unix_seek          :: proc(fd: Handle, offset: i64, whence: c.int) -> i64 ---
	@(link_name="getpagesize")      _unix_getpagesize   :: proc() -> c.int ---
	@(link_name="stat")             _unix_stat          :: proc(path: cstring, stat: ^OS_Stat) -> c.int ---
	@(link_name="__lstat50")        _unix_lstat         :: proc(path: cstring, sb: ^OS_Stat) -> c.int ---
	@(link_name="__fstat50")        _unix_fstat         :: proc(fd: Handle, stat: ^OS_Stat) -> c.int ---
	@(link_name="readlink")         _unix_readlink      :: proc(path: cstring, buf: ^byte, bufsiz: c.size_t) -> c.ssize_t ---
	@(link_name="access")           _unix_access        :: proc(path: cstring, mask: c.int) -> c.int ---
	@(link_name="getcwd")           _unix_getcwd        :: proc(buf: cstring, len: c.size_t) -> cstring ---
	@(link_name="chdir")            _unix_chdir         :: proc(buf: cstring) -> c.int ---
	@(link_name="rename")           _unix_rename        :: proc(old, new: cstring) -> c.int ---
	@(link_name="unlink")           _unix_unlink        :: proc(path: cstring) -> c.int ---
	@(link_name="rmdir")            _unix_rmdir         :: proc(path: cstring) -> c.int ---
	@(link_name="mkdir")            _unix_mkdir         :: proc(path: cstring, mode: mode_t) -> c.int ---
	@(link_name="fcntl")            _unix_fcntl         :: proc(fd: Handle, cmd: c.int, #c_vararg args: ..any) -> c.int ---
	@(link_name="fsync")            _unix_fsync         :: proc(fd: Handle) -> c.int ---
	@(link_name="dup")              _unix_dup           :: proc(fd: Handle) -> Handle ---
	
	@(link_name="fdopendir")        _unix_fdopendir     :: proc(fd: Handle) -> Dir ---
	@(link_name="closedir")         _unix_closedir      :: proc(dirp: Dir) -> c.int ---
	@(link_name="rewinddir")        _unix_rewinddir     :: proc(dirp: Dir) ---
	@(link_name="__readdir_r30")    _unix_readdir_r     :: proc(dirp: Dir, entry: ^Dirent, result: ^^Dirent) -> c.int ---

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
}

@(private)
foreign libc {
	_lwp_self :: proc() -> i32 ---
}

// NOTE(phix): Perhaps share the following functions with FreeBSD if they turn out to be the same in the end.

@(require_results)
is_path_separator :: proc(r: rune) -> bool {
	return r == '/'
}

@(require_results, no_instrumentation)
get_last_error :: proc "contextless" () -> Error {
	return Platform_Error(__errno_location()^)
}

@(require_results)
open :: proc(path: string, flags: int = O_RDONLY, mode: int = 0) -> (Handle, Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	handle := _unix_open(cstr, c.int(flags), c.uint(mode))
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
	result := _unix_fsync(fd)
	if result == -1 {
		return get_last_error()
	}
	return nil
}

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

	bytes_read := _unix_pread(fd, raw_data(data), to_read, offset)
	if bytes_read < 0 {
		return -1, get_last_error()
	}
	return bytes_read, nil
}

write_at :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Error) {
	if len(data) == 0 {
		return 0, nil
	}

	to_write := min(uint(len(data)), MAX_RW)

	bytes_written := _unix_pwrite(fd, raw_data(data), to_write, offset)
	if bytes_written < 0 {
		return -1, get_last_error()
	}
	return bytes_written, nil
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
		}
		return 0, errno
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

@(require_results)
fcntl :: proc(fd: int, cmd: int, arg: int) -> (int, Error) {
	result := _unix_fcntl(Handle(fd), c.int(cmd), uintptr(arg))
	if result < 0 {
		return 0, get_last_error()
	}
	return int(result), nil
}

// NOTE(bill): Uses startup to initialize it

stdin: Handle  = 0
stdout: Handle = 1
stderr: Handle = 2

@(require_results)
last_write_time :: proc(fd: Handle) -> (time: File_Time, err: Error) {
	s := _fstat(fd) or_return
	modified := s.modified.seconds * 1_000_000_000 + s.modified.nanoseconds
	return File_Time(modified), nil
}

@(require_results)
last_write_time_by_name :: proc(name: string) -> (time: File_Time, err: Error) {
	s := _stat(name) or_return
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
	err = nil

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
absolute_path_from_handle :: proc(fd: Handle) -> (path: string, err: Error) {
	buf: [MAX_PATH]byte
	_ = fcntl(int(fd), F_GETPATH, int(uintptr(&buf[0]))) or_return
	return strings.clone_from_cstring(cstring(&buf[0]))
}

@(require_results)
absolute_path_from_relative :: proc(rel: string) -> (path: string, err: Error) {
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

	path = strings.clone(string(path_ptr))

	return path, nil
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
	return int(_lwp_self())
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

@(require_results)
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
	if _sysctlbyname("hw.logicalcpu", &count, &count_size, nil, 0) == 0 {
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
