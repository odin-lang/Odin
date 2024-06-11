package os

foreign import dl   "system:dl"
foreign import libc "system:System.framework"
foreign import pthread "system:System.framework"

import "base:runtime"
import "core:strings"
import "core:c"

Handle    :: distinct i32
File_Time :: distinct u64
Errno     :: distinct int

INVALID_HANDLE :: ~Handle(0)

ERROR_NONE: Errno : 0
EPERM:		Errno : 1		/* Operation not permitted */
ENOENT:		Errno : 2		/* No such file or directory */
ESRCH:		Errno : 3		/* No such process */
EINTR:		Errno : 4		/* Interrupted system call */
EIO:		Errno : 5		/* Input/output error */
ENXIO:		Errno : 6		/* Device not configured */
E2BIG:		Errno : 7		/* Argument list too long */
ENOEXEC:	Errno : 8		/* Exec format error */
EBADF:		Errno : 9		/* Bad file descriptor */
ECHILD:		Errno : 10		/* No child processes */
EDEADLK:	Errno : 11		/* Resource deadlock avoided */
ENOMEM:		Errno : 12		/* Cannot allocate memory */
EACCES:		Errno : 13		/* Permission denied */
EFAULT:		Errno : 14		/* Bad address */
ENOTBLK:	Errno : 15		/* Block device required */
EBUSY:		Errno : 16		/* Device / Resource busy */
EEXIST:		Errno : 17		/* File exists */
EXDEV:		Errno : 18		/* Cross-device link */
ENODEV:		Errno : 19		/* Operation not supported by device */
ENOTDIR:	Errno : 20		/* Not a directory */
EISDIR:		Errno : 21		/* Is a directory */
EINVAL:		Errno : 22		/* Invalid argument */
ENFILE:		Errno : 23		/* Too many open files in system */
EMFILE:		Errno : 24		/* Too many open files */
ENOTTY:		Errno : 25		/* Inappropriate ioctl for device */
ETXTBSY:	Errno : 26		/* Text file busy */
EFBIG:		Errno : 27		/* File too large */
ENOSPC:		Errno : 28		/* No space left on device */
ESPIPE:		Errno : 29		/* Illegal seek */
EROFS:		Errno : 30		/* Read-only file system */
EMLINK:		Errno : 31		/* Too many links */
EPIPE:		Errno : 32		/* Broken pipe */

/* math software */
EDOM:		Errno : 33		/* Numerical argument out of domain */
ERANGE:		Errno : 34		/* Result too large */

/* non-blocking and interrupt i/o */
EAGAIN:			Errno : 35		/* Resource temporarily unavailable */
EWOULDBLOCK: 	Errno : EAGAIN		/* Operation would block */
EINPROGRESS: 	Errno : 36		/* Operation now in progress */
EALREADY:		Errno : 37		/* Operation already in progress */

/* ipc/network software -- argument errors */
ENOTSOCK:			Errno : 38		/* Socket operation on non-socket */
EDESTADDRREQ:		Errno : 39		/* Destination address required */
EMSGSIZE:			Errno : 40		/* Message too long */
EPROTOTYPE:			Errno : 41		/* Protocol wrong type for socket */
ENOPROTOOPT:		Errno : 42		/* Protocol not available */
EPROTONOSUPPORT:	Errno : 43		/* Protocol not supported */
ESOCKTNOSUPPORT:	Errno : 44		/* Socket type not supported */
ENOTSUP:			Errno : 45		/* Operation not supported */
EOPNOTSUPP::		ENOTSUP
EPFNOSUPPORT:		Errno : 46		/* Protocol family not supported */
EAFNOSUPPORT:		Errno : 47		/* Address family not supported by protocol family */
EADDRINUSE:			Errno : 48		/* Address already in use */
EADDRNOTAVAIL:		Errno : 49		/* Can't assign requested address */

/* ipc/network software -- operational errors */
ENETDOWN:		Errno : 50		/* Network is down */
ENETUNREACH:	Errno : 51		/* Network is unreachable */
ENETRESET:		Errno : 52		/* Network dropped connection on reset */
ECONNABORTED:	Errno : 53		/* Software caused connection abort */
ECONNRESET:		Errno : 54		/* Connection reset by peer */
ENOBUFS:		Errno : 55		/* No buffer space available */
EISCONN:		Errno : 56		/* Socket is already connected */
ENOTCONN:		Errno : 57		/* Socket is not connected */
ESHUTDOWN:		Errno : 58		/* Can't send after socket shutdown */
ETOOMANYREFS:	Errno : 59		/* Too many references: can't splice */
ETIMEDOUT:		Errno : 60		/* Operation timed out */
ECONNREFUSED:	Errno : 61		/* Connection refused */

ELOOP:			Errno : 62		/* Too many levels of symbolic links */
ENAMETOOLONG:	Errno : 63		/* File name too long */

/* should be rearranged */
EHOSTDOWN:		Errno : 64		/* Host is down */
EHOSTUNREACH:	Errno : 65		/* No route to host */
ENOTEMPTY:		Errno : 66		/* Directory not empty */

/* quotas & mush */
EPROCLIM:		Errno : 67		/* Too many processes */
EUSERS:			Errno : 68		/* Too many users */
EDQUOT:			Errno : 69		/* Disc quota exceeded */

/* Network File System */
ESTALE:			Errno : 70		/* Stale NFS file handle */
EREMOTE:		Errno : 71		/* Too many levels of remote in path */
EBADRPC:		Errno : 72		/* RPC struct is bad */
ERPCMISMATCH:	Errno : 73		/* RPC version wrong */
EPROGUNAVAIL:	Errno : 74		/* RPC prog. not avail */
EPROGMISMATCH:	Errno : 75		/* Program version wrong */
EPROCUNAVAIL:	Errno : 76		/* Bad procedure for program */

ENOLCK:	Errno : 77		/* No locks available */
ENOSYS:	Errno : 78		/* Function not implemented */

EFTYPE:	Errno : 79		/* Inappropriate file type or format */
EAUTH:	Errno : 80		/* Authentication error */
ENEEDAUTH:	Errno : 81		/* Need authenticator */

/* Intelligent device errors */
EPWROFF:	Errno : 82	/* Device power is off */
EDEVERR:	Errno : 83	/* Device error, e.g. paper out */
EOVERFLOW:	Errno : 84		/* Value too large to be stored in data type */

/* Program loading errors */
EBADEXEC:	Errno : 85	/* Bad executable */
EBADARCH:	Errno : 86	/* Bad CPU type in executable */
ESHLIBVERS:	Errno : 87	/* Shared library version mismatch */
EBADMACHO:	Errno : 88	/* Malformed Macho file */

ECANCELED:	Errno : 89		/* Operation canceled */

EIDRM:		Errno : 90		/* Identifier removed */
ENOMSG:		Errno : 91		/* No message of desired type */
EILSEQ:		Errno : 92		/* Illegal byte sequence */
ENOATTR:	Errno : 93		/* Attribute not found */

EBADMSG:	Errno : 94		/* Bad message */
EMULTIHOP:	Errno : 95		/* Reserved */
ENODATA:	Errno : 96		/* No message available on STREAM */
ENOLINK:	Errno : 97		/* Reserved */
ENOSR:		Errno : 98		/* No STREAM resources */
ENOSTR:		Errno : 99		/* Not a STREAM */
EPROTO:		Errno : 100		/* Protocol error */
ETIME:		Errno : 101		/* STREAM ioctl timeout */

ENOPOLICY:	Errno : 103		/* No such policy registered */

ENOTRECOVERABLE:	Errno : 104		/* State not recoverable */
EOWNERDEAD:			Errno : 105		/* Previous owner died */

EQFULL:	Errno : 106		/* Interface output queue is full */
ELAST:	Errno : 106		/* Must be equal largest errno */

O_RDONLY   :: 0x0000
O_WRONLY   :: 0x0001
O_RDWR     :: 0x0002
O_CREATE   :: 0x0200
O_EXCL     :: 0x0800
O_NOCTTY   :: 0
O_TRUNC    :: 0x0400
O_NONBLOCK :: 0x0004
O_APPEND   :: 0x0008
O_SYNC     :: 0x0080
O_ASYNC    :: 0x0040
O_CLOEXEC  :: 0x1000000

SEEK_DATA  :: 3
SEEK_HOLE  :: 4
SEEK_MAX   :: SEEK_HOLE



// NOTE(zangent): These are OS specific!
// Do not mix these up!
RTLD_LAZY     :: 0x1
RTLD_NOW      :: 0x2
RTLD_LOCAL    :: 0x4
RTLD_GLOBAL   :: 0x8
RTLD_NODELETE :: 0x80
RTLD_NOLOAD   :: 0x10
RTLD_FIRST    :: 0x100

SOL_SOCKET :: 0xFFFF

SOCK_STREAM    :: 1
SOCK_DGRAM     :: 2
SOCK_RAW       :: 3
SOCK_RDM       :: 4
SOCK_SEQPACKET :: 5

SO_DEBUG       :: 0x0001
SO_ACCEPTCONN  :: 0x0002
SO_REUSEADDR   :: 0x0004
SO_KEEPALIVE   :: 0x0008
SO_DONTROUTE   :: 0x0010
SO_BROADCAST   :: 0x0020
SO_USELOOPBACK :: 0x0040
SO_LINGER      :: 0x0080
SO_OOBINLINE   :: 0x0100
SO_REUSEPORT   :: 0x0200
SO_TIMESTAMP   :: 0x0400

SO_DONTTRUNC   :: 0x2000
SO_WANTMORE    :: 0x4000
SO_WANTOOBFLAG :: 0x8000
SO_SNDBUF      :: 0x1001
SO_RCVBUF      :: 0x1002
SO_SNDLOWAT	   :: 0x1003
SO_RCVLOWAT    :: 0x1004
SO_SNDTIMEO    :: 0x1005
SO_RCVTIMEO    :: 0x1006
SO_ERROR       :: 0x1007
SO_TYPE        :: 0x1008
SO_PRIVSTATE   :: 0x1009
SO_NREAD       :: 0x1020
SO_NKE         :: 0x1021

AF_UNSPEC     :: 0
AF_LOCAL      :: 1
AF_UNIX       :: AF_LOCAL
AF_INET       :: 2
AF_IMPLINK    :: 3
AF_PUP        :: 4
AF_CHAOS      :: 5
AF_NS         :: 6
AF_ISO        :: 7
AF_OSI        :: AF_ISO
AF_ECMA       :: 8
AF_DATAKIT    :: 9
AF_CCITT      :: 10
AF_SNA        :: 11
AF_DECnet     :: 12
AF_DLI        :: 13
AF_LAT        :: 14
AF_HYLINK     :: 15
AF_APPLETALK  :: 16
AF_ROUTE	  :: 17
AF_LINK		  :: 18
pseudo_AF_XTP :: 19
AF_COIP		  :: 20
AF_CNT		  :: 21
pseudo_AF_RTIP :: 22
AF_IPX         :: 23
AF_SIP         :: 24
pseudo_AF_PIP  :: 25
pseudo_AF_BLUE :: 26
AF_NDRV        :: 27
AF_ISDN        :: 28
AF_E164        :: AF_ISDN
pseudo_AF_KEY  :: 29
AF_INET6       :: 30
AF_NATM        :: 31
AF_SYSTEM      :: 32
AF_NETBIOS     :: 33
AF_PPP         :: 34

TCP_NODELAY	:: 0x01
TCP_MAXSEG	:: 0x02
TCP_NOPUSH	:: 0x04
TCP_NOOPT	:: 0x08

IPPROTO_ICMP :: 1
IPPROTO_TCP  :: 6
IPPROTO_UDP  :: 17

SHUT_RD   :: 0
SHUT_WR   :: 1
SHUT_RDWR :: 2

F_GETFL: int : 3 /* Get file flags */
F_SETFL: int : 4 /* Set file flags */

// "Argv" arguments converted to Odin strings
args := _alloc_command_line_arguments()

Unix_File_Time :: struct {
	seconds: i64,
	nanoseconds: i64,
}

OS_Stat :: struct {
	device_id:     i32, // ID of device containing file
	mode:          u16, // Mode of the file
	nlink:         u16, // Number of hard links
	serial:        u64, // File serial number
	uid:           u32, // User ID of the file's owner
	gid:           u32, // Group ID of the file's group
	rdev:          i32, // Device ID, if device

	last_access:   Unix_File_Time, // Time of last access
	modified:      Unix_File_Time, // Time of last modification
	status_change: Unix_File_Time, // Time of last status change
	created:       Unix_File_Time, // Time of creation

	size:          i64,  // Size of the file, in bytes
	blocks:        i64,  // Number of blocks allocated for the file
	block_size:    i32,  // Optimal blocksize for I/O
	flags:         u32,  // User-defined flags for the file
	gen_num:       u32,  // File generation number ..?
	_spare:        i32,  // RESERVED
	_reserve1,
	_reserve2:     i64,  // RESERVED
}

DARWIN_MAXPATHLEN :: 1024
Dirent :: struct {
	ino:    u64,
	off:    u64,
	reclen: u16,
	namlen: u16,
	type:   u8,
	name:   [DARWIN_MAXPATHLEN]byte,
}

Dir :: distinct rawptr // DIR*

ADDRESS_FAMILY :: c.char
SOCKADDR :: struct #packed {
	len: c.char,
	family: ADDRESS_FAMILY,
	sa_data: [14]c.char,
}

SOCKADDR_STORAGE_LH :: struct #packed {
	len: c.char,
	family: ADDRESS_FAMILY,
	__ss_pad1: [6]c.char,
	__ss_align: i64,
	__ss_pad2: [112]c.char,
}

sockaddr_in :: struct #packed {
	sin_len: c.char,
	sin_family: ADDRESS_FAMILY,
	sin_port: u16be,
	sin_addr: in_addr,
	sin_zero: [8]c.char,
}

sockaddr_in6 :: struct #packed {
	sin6_len: c.char,
	sin6_family: ADDRESS_FAMILY,
	sin6_port: u16be,
	sin6_flowinfo: c.uint,
	sin6_addr: in6_addr,
	sin6_scope_id: c.uint,
}

in_addr :: struct #packed {
	s_addr: u32,
}

in6_addr :: struct #packed {
	s6_addr: [16]u8,
}

SIOCGIFFLAG :: enum c.int {
	UP             = 0,  /* Interface is up.  */
	BROADCAST      = 1,  /* Broadcast address valid.  */
	DEBUG          = 2,  /* Turn on debugging.  */
	LOOPBACK       = 3,  /* Is a loopback net.  */
	POINT_TO_POINT = 4,  /* Interface is point-to-point link.  */
	NO_TRAILERS    = 5,  /* Avoid use of trailers.  */
	RUNNING        = 6,  /* Resources allocated.  */
	NOARP          = 7,  /* No address resolution protocol.  */
	PROMISC        = 8,  /* Receive all packets.  */
	ALL_MULTI      = 9,  /* Receive all multicast packets. Unimplemented. */
}
SIOCGIFFLAGS :: bit_set[SIOCGIFFLAG; c.int]

ifaddrs :: struct {
	next:              ^ifaddrs,
	name:              cstring,
	flags:             SIOCGIFFLAGS,
	address:           ^SOCKADDR,
	netmask:           ^SOCKADDR,
	broadcast_or_dest: ^SOCKADDR,  // Broadcast or Point-to-Point address
	data:              rawptr,     // Address-specific data.
}

Timeval :: struct {
	seconds: i64,
	microseconds: int,
}

Linger :: struct {
	onoff: int,
	linger: int,
}

Socket    :: distinct int
socklen_t :: c.int

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

S_ISLNK  :: #force_inline proc(m: u16) -> bool { return (m & S_IFMT) == S_IFLNK  }
S_ISREG  :: #force_inline proc(m: u16) -> bool { return (m & S_IFMT) == S_IFREG  }
S_ISDIR  :: #force_inline proc(m: u16) -> bool { return (m & S_IFMT) == S_IFDIR  }
S_ISCHR  :: #force_inline proc(m: u16) -> bool { return (m & S_IFMT) == S_IFCHR  }
S_ISBLK  :: #force_inline proc(m: u16) -> bool { return (m & S_IFMT) == S_IFBLK  }
S_ISFIFO :: #force_inline proc(m: u16) -> bool { return (m & S_IFMT) == S_IFIFO  }
S_ISSOCK :: #force_inline proc(m: u16) -> bool { return (m & S_IFMT) == S_IFSOCK }

R_OK :: 4 // Test for read permission
W_OK :: 2 // Test for write permission
X_OK :: 1 // Test for execute permission
F_OK :: 0 // Test for file existance

F_GETPATH :: 50 // return the full path of the fd

foreign libc {
	@(link_name="__error") __error :: proc() -> ^c.int ---

	@(link_name="open")             _unix_open          :: proc(path: cstring, flags: i32, #c_vararg args: ..any) -> Handle ---
	@(link_name="close")            _unix_close         :: proc(handle: Handle) -> c.int ---
	@(link_name="read")             _unix_read          :: proc(handle: Handle, buffer: rawptr, count: c.size_t) -> int ---
	@(link_name="write")            _unix_write         :: proc(handle: Handle, buffer: rawptr, count: c.size_t) -> int ---
	@(link_name="pread")            _unix_pread         :: proc(handle: Handle, buffer: rawptr, count: c.size_t, offset: i64) -> int ---
	@(link_name="pwrite")           _unix_pwrite        :: proc(handle: Handle, buffer: rawptr, count: c.size_t, offset: i64) -> int ---
	@(link_name="lseek")            _unix_lseek         :: proc(fs: Handle, offset: int, whence: c.int) -> int ---
	@(link_name="gettid")           _unix_gettid        :: proc() -> u64 ---
	@(link_name="getpagesize")      _unix_getpagesize   :: proc() -> i32 ---
	@(link_name="stat64")           _unix_stat          :: proc(path: cstring, stat: ^OS_Stat) -> c.int ---
	@(link_name="lstat64")          _unix_lstat         :: proc(path: cstring, stat: ^OS_Stat) -> c.int ---
	@(link_name="fstat64")          _unix_fstat         :: proc(fd: Handle, stat: ^OS_Stat) -> c.int ---
	@(link_name="readlink")         _unix_readlink      :: proc(path: cstring, buf: ^byte, bufsiz: c.size_t) -> c.ssize_t ---
	@(link_name="access")           _unix_access        :: proc(path: cstring, mask: c.int) -> c.int ---
        @(link_name="fsync")            _unix_fsync         :: proc(handle: Handle) -> c.int ---

	@(link_name="fdopendir$INODE64") _unix_fdopendir_amd64 :: proc(fd: Handle) -> Dir ---
	@(link_name="readdir_r$INODE64") _unix_readdir_r_amd64 :: proc(dirp: Dir, entry: ^Dirent, result: ^^Dirent) -> c.int ---
	@(link_name="fdopendir")         _unix_fdopendir_arm64 :: proc(fd: Handle) -> Dir ---
	@(link_name="readdir_r")         _unix_readdir_r_arm64 :: proc(dirp: Dir, entry: ^Dirent, result: ^^Dirent) -> c.int ---

	@(link_name="closedir")         _unix_closedir      :: proc(dirp: Dir) -> c.int ---
	@(link_name="rewinddir")        _unix_rewinddir     :: proc(dirp: Dir) ---

	@(link_name="__fcntl")          _unix__fcntl        :: proc(fd: Handle, cmd: c.int, arg: uintptr) -> c.int ---

	@(link_name="rename") _unix_rename :: proc(old: cstring, new: cstring) -> c.int ---
	@(link_name="remove") _unix_remove :: proc(path: cstring) -> c.int ---

	@(link_name="fchmod") _unix_fchmod :: proc(fd: Handle, mode: u16) -> c.int ---

	@(link_name="malloc")   _unix_malloc   :: proc(size: int) -> rawptr ---
	@(link_name="calloc")   _unix_calloc   :: proc(num, size: int) -> rawptr ---
	@(link_name="free")     _unix_free     :: proc(ptr: rawptr) ---
	@(link_name="realloc")  _unix_realloc  :: proc(ptr: rawptr, size: int) -> rawptr ---
	@(link_name="getenv")   _unix_getenv   :: proc(cstring) -> cstring ---
	@(link_name="getcwd")   _unix_getcwd   :: proc(buf: cstring, len: c.size_t) -> cstring ---
	@(link_name="chdir")    _unix_chdir    :: proc(buf: cstring) -> c.int ---
	@(link_name="mkdir")    _unix_mkdir    :: proc(buf: cstring, mode: u16) -> c.int ---
	@(link_name="realpath") _unix_realpath :: proc(path: cstring, resolved_path: rawptr) -> rawptr ---

	@(link_name="strerror") _darwin_string_error :: proc(num : c.int) -> cstring ---
	@(link_name="sysctlbyname") _sysctlbyname    :: proc(path: cstring, oldp: rawptr, oldlenp: rawptr, newp: rawptr, newlen: int) -> c.int ---

	@(link_name="socket")           _unix_socket        :: proc(domain: int, type: int, protocol: int) -> int ---
	@(link_name="listen")           _unix_listen        :: proc(socket: int, backlog: int) -> int ---
	@(link_name="accept")           _unix_accept        :: proc(socket: int, addr: rawptr, addr_len: rawptr) -> int ---
	@(link_name="connect")          _unix_connect       :: proc(socket: int, addr: rawptr, addr_len: socklen_t) -> int ---
	@(link_name="bind")             _unix_bind          :: proc(socket: int, addr: rawptr, addr_len: socklen_t) -> int ---
	@(link_name="setsockopt")       _unix_setsockopt    :: proc(socket: int, level: int, opt_name: int, opt_val: rawptr, opt_len: socklen_t) -> int ---
	@(link_name="getsockopt")       _unix_getsockopt    :: proc(socket: int, level: int, opt_name: int, opt_val: rawptr, opt_len: socklen_t) -> int ---
	@(link_name="recvfrom")         _unix_recvfrom      :: proc(socket: int, buffer: rawptr, buffer_len: c.size_t, flags: int, addr: rawptr, addr_len: ^socklen_t) -> c.ssize_t ---
	@(link_name="recv")             _unix_recv          :: proc(socket: int, buffer: rawptr, buffer_len: c.size_t, flags: int) -> c.ssize_t ---
	@(link_name="sendto")           _unix_sendto        :: proc(socket: int, buffer: rawptr, buffer_len: c.size_t, flags: int, addr: rawptr, addr_len: socklen_t) -> c.ssize_t ---
	@(link_name="send")             _unix_send          :: proc(socket: int, buffer: rawptr, buffer_len: c.size_t, flags: int) -> c.ssize_t ---
	@(link_name="shutdown")         _unix_shutdown      :: proc(socket: int, how: int) -> int ---

	@(link_name="getifaddrs")       _getifaddrs         :: proc(ifap: ^^ifaddrs) -> (c.int) ---
	@(link_name="freeifaddrs")      _freeifaddrs        :: proc(ifa: ^ifaddrs) ---

	@(link_name="exit")    _unix_exit :: proc(status: c.int) -> ! ---
}

when ODIN_ARCH != .arm64 {
	_unix_fdopendir :: proc {_unix_fdopendir_amd64}
	_unix_readdir_r :: proc {_unix_readdir_r_amd64}
} else {
	_unix_fdopendir :: proc {_unix_fdopendir_arm64}
	_unix_readdir_r :: proc {_unix_readdir_r_arm64}
}

foreign dl {
	@(link_name="dlopen")  _unix_dlopen  :: proc(filename: cstring, flags: int) -> rawptr ---
	@(link_name="dlsym")   _unix_dlsym   :: proc(handle: rawptr, symbol: cstring) -> rawptr ---
	@(link_name="dlclose") _unix_dlclose :: proc(handle: rawptr) -> int ---
	@(link_name="dlerror") _unix_dlerror :: proc() -> cstring ---
}

get_last_error :: proc "contextless" () -> int {
	return int(__error()^)
}

get_last_error_string :: proc() -> string {
	return cast(string)_darwin_string_error(cast(c.int)get_last_error())
}


open :: proc(path: string, flags: int = O_RDWR, mode: int = 0) -> (Handle, Errno) {
	isDir := is_dir_path(path)
	flags := flags
	if isDir {
		/*
			@INFO(Platin): To make it impossible to use the wrong flag for dir's 
			               as you can't write to a dir only read which makes it fail to open
		*/
		flags = O_RDONLY
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	handle := _unix_open(cstr, i32(flags), u16(mode))
	if handle == -1 {
		return INVALID_HANDLE, cast(Errno)get_last_error()
	}

	/*
		@INFO(Platin): this is only done because O_CREATE for some reason fails to apply mode
		               should not happen if the handle is a directory
	*/
	if mode != 0 && !isDir {
		err := fchmod(handle, cast(u16)mode)
		if err != 0 {
			_unix_close(handle)
			return INVALID_HANDLE, cast(Errno)err
		}
	}

	return handle, 0
}

fchmod :: proc(fd: Handle, mode: u16) -> Errno {
	return cast(Errno)_unix_fchmod(fd, mode)
}

close :: proc(fd: Handle) -> Errno {
	return cast(Errno)_unix_close(fd)
}

// If you read or write more than `SSIZE_MAX` bytes, most darwin implementations will return `EINVAL`
// but it is really implementation defined. `SSIZE_MAX` is also implementation defined but usually
// the max of an i32 on Darwin.
// In practice a read/write call would probably never read/write these big buffers all at once,
// which is why the number of bytes is returned and why there are procs that will call this in a
// loop for you.
// We set a max of 1GB to keep alignment and to be safe.
@(private)
MAX_RW :: 1 << 30

write :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	if len(data) == 0 {
		return 0, ERROR_NONE
	}

	to_write := min(c.size_t(len(data)), MAX_RW)

	bytes_written := _unix_write(fd, raw_data(data), to_write)
	if bytes_written < 0 {
		return -1, Errno(get_last_error())
	}
	return bytes_written, ERROR_NONE
}

read :: proc(fd: Handle, data: []u8) -> (int, Errno) {
	if len(data) == 0 {
		return 0, ERROR_NONE
	}

	to_read := min(c.size_t(len(data)), MAX_RW)

	bytes_read := _unix_read(fd, raw_data(data), to_read)
	if bytes_read < 0 {
		return -1, Errno(get_last_error())
	}
	return bytes_read, ERROR_NONE
}

read_at :: proc(fd: Handle, data: []byte, offset: i64) -> (int, Errno) {
	if len(data) == 0 {
		return 0, ERROR_NONE
	}

	to_read := min(c.size_t(len(data)), MAX_RW)

	bytes_read := _unix_pread(fd, raw_data(data), to_read, offset)
	if bytes_read < 0 {
		return -1, Errno(get_last_error())
	}
	return bytes_read, ERROR_NONE
}

write_at :: proc(fd: Handle, data: []byte, offset: i64) -> (int, Errno) {
	if len(data) == 0 {
		return 0, ERROR_NONE
	}

	to_write := min(c.size_t(len(data)), MAX_RW)

	bytes_written := _unix_pwrite(fd, raw_data(data), to_write, offset)
	if bytes_written < 0 {
		return -1, Errno(get_last_error())
	}
	return bytes_written, ERROR_NONE
}

seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Errno) {
	assert(fd != -1)

	final_offset := i64(_unix_lseek(fd, int(offset), c.int(whence)))
	if final_offset == -1 {
		return 0, 1
	}
	return final_offset, 0
}

file_size :: proc(fd: Handle) -> (i64, Errno) {
	prev, _   := seek(fd, 0, SEEK_CUR)
	size, err := seek(fd, 0, SEEK_END)
	seek(fd, prev, SEEK_SET)
	return i64(size), err
}



// NOTE(bill): Uses startup to initialize it
stdin:  Handle = 0 // get_std_handle(win32.STD_INPUT_HANDLE);
stdout: Handle = 1 // get_std_handle(win32.STD_OUTPUT_HANDLE);
stderr: Handle = 2 // get_std_handle(win32.STD_ERROR_HANDLE);

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


is_path_separator :: proc(r: rune) -> bool {
	return r == '/'
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

exists :: proc(path: string) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cpath := strings.clone_to_cstring(path, context.temp_allocator)
	res := _unix_access(cpath, O_RDONLY)
	return res == 0
}

rename :: proc(old: string, new: string) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	old_cstr := strings.clone_to_cstring(old, context.temp_allocator)
	new_cstr := strings.clone_to_cstring(new, context.temp_allocator)
	return _unix_rename(old_cstr, new_cstr) != -1
}

remove :: proc(path: string) -> Errno {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	res := _unix_remove(path_cstr)
	if res == -1 {
		return Errno(get_last_error())
	}
	return ERROR_NONE
}

@private
_stat :: proc(path: string) -> (OS_Stat, Errno) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)

	s: OS_Stat
	result := _unix_stat(cstr, &s)
	if result == -1 {
		return s, Errno(get_last_error())
	}
	return s, ERROR_NONE
}

@private
_lstat :: proc(path: string) -> (OS_Stat, Errno) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)

	s: OS_Stat
	result := _unix_lstat(cstr, &s)
	if result == -1 {
		return s, Errno(get_last_error())
	}
	return s, ERROR_NONE
}

@private
_fstat :: proc(fd: Handle) -> (OS_Stat, Errno) {
	s: OS_Stat
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
	end_of_stream = false

	return
}

@private
_readlink :: proc(path: string) -> (string, Errno) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == context.allocator)
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)

	bufsz : uint = 256
	buf := make([]byte, bufsz)
	for {
		rc := _unix_readlink(path_cstr, &(buf[0]), bufsz)
		if rc == -1 {
			delete(buf)
			return "", Errno(get_last_error())
		} else if rc == int(bufsz) {
			// NOTE(laleksic, 2021-01-21): Any cleaner way to resize the slice?
			bufsz *= 2
			delete(buf)
			buf = make([]byte, bufsz)
		} else {
			return strings.string_from_ptr(&buf[0], rc), ERROR_NONE
		}
	}
}

absolute_path_from_handle :: proc(fd: Handle) -> (string, Errno) {
	buf: [DARWIN_MAXPATHLEN]byte
	_, err := fcntl(int(fd), F_GETPATH, int(uintptr(&buf[0])))
	if err != ERROR_NONE {
		return "", err
	}

	path := strings.clone_from_cstring(cstring(&buf[0]))
	return path, err
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

access :: proc(path: string, mask: int) -> bool {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	return _unix_access(cstr, c.int(mask)) == 0
}

flush :: proc(fd: Handle) -> Errno {
    return cast(Errno)_unix_fsync(fd)
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
	page_size := get_page_size() // NOTE(tetra): See note in os_linux.odin/get_current_directory.
	buf := make([dynamic]u8, page_size)
	for {
		cwd := _unix_getcwd(cstring(raw_data(buf)), c.size_t(len(buf)))
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
	if res == -1 {
		return Errno(get_last_error())
	}
	return ERROR_NONE
}

make_directory :: proc(path: string, mode: u16 = 0o775) -> Errno {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	res := _unix_mkdir(path_cstr, mode)
	if res == -1 {
		return Errno(get_last_error())
	}
	return ERROR_NONE
}

exit :: proc "contextless" (code: int) -> ! {
	runtime._cleanup_runtime_contextless()
	_unix_exit(i32(code))
}

current_thread_id :: proc "contextless" () -> int {
	tid: u64
	// NOTE(Oskar): available from OSX 10.6 and iOS 3.2.
	// For older versions there is `syscall(SYS_thread_selfid)`, but not really
	// the same thing apparently.
	foreign pthread { pthread_threadid_np :: proc "c" (rawptr, ^u64) -> c.int --- }
	pthread_threadid_np(nil, &tid)
	return int(tid)
}

dlopen :: proc(filename: string, flags: int) -> rawptr {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(filename, context.temp_allocator)
	handle := _unix_dlopen(cstr, flags)
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
	if page_size != -1 {
		return page_size
	}

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
	for _, i in res {
		res[i] = string(runtime.args__[i])
	}
	return res
}

socket :: proc(domain: int, type: int, protocol: int) -> (Socket, Errno) {
	result := _unix_socket(domain, type, protocol)
	if result < 0 {
		return 0, Errno(get_last_error())
	}
	return Socket(result), ERROR_NONE
}

connect :: proc(sd: Socket, addr: ^SOCKADDR, len: socklen_t) -> (Errno) {
	result := _unix_connect(int(sd), addr, len)
	if result < 0 {
		return Errno(get_last_error())
	}
	return ERROR_NONE
}

bind :: proc(sd: Socket, addr: ^SOCKADDR, len: socklen_t) -> (Errno) {
	result := _unix_bind(int(sd), addr, len)
	if result < 0 {
		return Errno(get_last_error())
	}
	return ERROR_NONE
}

accept :: proc(sd: Socket, addr: ^SOCKADDR, len: rawptr) -> (Socket, Errno) {
	result := _unix_accept(int(sd), rawptr(addr), len)
	if result < 0 {
		return 0, Errno(get_last_error())
	}
	return Socket(result), ERROR_NONE
}

listen :: proc(sd: Socket, backlog: int) -> (Errno) {
	result := _unix_listen(int(sd), backlog)
	if result < 0 {
		return Errno(get_last_error())
	}
	return ERROR_NONE
}

setsockopt :: proc(sd: Socket, level: int, optname: int, optval: rawptr, optlen: socklen_t) -> (Errno) {
	result := _unix_setsockopt(int(sd), level, optname, optval, optlen)
	if result < 0 {
		return Errno(get_last_error())
	}
	return ERROR_NONE
}

getsockopt :: proc(sd: Socket, level: int, optname: int, optval: rawptr, optlen: socklen_t) -> Errno {
	result := _unix_getsockopt(int(sd), level, optname, optval, optlen)
	if result < 0 {
		return Errno(get_last_error())
	}
	return ERROR_NONE
}

recvfrom :: proc(sd: Socket, data: []byte, flags: int, addr: ^SOCKADDR, addr_size: ^socklen_t) -> (u32, Errno) {
	result := _unix_recvfrom(int(sd), raw_data(data), len(data), flags, addr, addr_size)
	if result < 0 {
		return 0, Errno(get_last_error())
	}
	return u32(result), ERROR_NONE
}

recv :: proc(sd: Socket, data: []byte, flags: int) -> (u32, Errno) {
	result := _unix_recv(int(sd), raw_data(data), len(data), flags)
	if result < 0 {
		return 0, Errno(get_last_error())
	}
	return u32(result), ERROR_NONE
}

sendto :: proc(sd: Socket, data: []u8, flags: int, addr: ^SOCKADDR, addrlen: socklen_t) -> (u32, Errno) {
	result := _unix_sendto(int(sd), raw_data(data), len(data), flags, addr, addrlen)
	if result < 0 {
		return 0, Errno(get_last_error())
	}
	return u32(result), ERROR_NONE
}

send :: proc(sd: Socket, data: []byte, flags: int) -> (u32, Errno) {
	result := _unix_send(int(sd), raw_data(data), len(data), 0)
	if result < 0 {
		return 0, Errno(get_last_error())
	}
	return u32(result), ERROR_NONE
}

shutdown :: proc(sd: Socket, how: int) -> (Errno) {
	result := _unix_shutdown(int(sd), how)
	if result < 0 {
		return Errno(get_last_error())
	}
	return ERROR_NONE
}

fcntl :: proc(fd: int, cmd: int, arg: int) -> (int, Errno) {
	result := _unix__fcntl(Handle(fd), c.int(cmd), uintptr(arg))
	if result < 0 {
		return 0, Errno(get_last_error())
	}
	return int(result), ERROR_NONE
}
