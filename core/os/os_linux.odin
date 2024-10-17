package os

foreign import dl   "system:dl"
foreign import libc "system:c"

import "base:runtime"
import "core:strings"
import "core:c"
import "core:strconv"

// NOTE(flysand): For compatibility we'll make core:os package
// depend on the old (scheduled for removal) linux package.
// Seeing that there are plans for os2, I'm imagining that *that*
// package should inherit the new sys functionality.
// The reasons for these are as follows:
//  1. It's very hard to update this package without breaking *a lot* of code.
//  2. os2 is not stable anyways, so we can break compatibility all we want
// It might be weird to bring up compatibility when Odin in it's nature isn't
// all that about compatibility. But we don't want to push experimental changes
// and have people's code break while it's still work in progress.
import unix "core:sys/unix"
import linux "core:sys/linux"

Handle    :: distinct i32
Pid       :: distinct i32
File_Time :: distinct u64
Socket    :: distinct int

INVALID_HANDLE :: ~Handle(0)

_Platform_Error :: linux.Errno
EPERM           :: Platform_Error.EPERM
ENOENT          :: Platform_Error.ENOENT
ESRCH           :: Platform_Error.ESRCH
EINTR           :: Platform_Error.EINTR
EIO             :: Platform_Error.EIO
ENXIO           :: Platform_Error.ENXIO
EBADF           :: Platform_Error.EBADF
EAGAIN          :: Platform_Error.EAGAIN
ENOMEM          :: Platform_Error.ENOMEM
EACCES          :: Platform_Error.EACCES
EFAULT          :: Platform_Error.EFAULT
EEXIST          :: Platform_Error.EEXIST
ENODEV          :: Platform_Error.ENODEV
ENOTDIR         :: Platform_Error.ENOTDIR
EISDIR          :: Platform_Error.EISDIR
EINVAL          :: Platform_Error.EINVAL
ENFILE          :: Platform_Error.ENFILE
EMFILE          :: Platform_Error.EMFILE
ETXTBSY         :: Platform_Error.ETXTBSY
EFBIG           :: Platform_Error.EFBIG
ENOSPC          :: Platform_Error.ENOSPC
ESPIPE          :: Platform_Error.ESPIPE
EROFS           :: Platform_Error.EROFS
EPIPE           :: Platform_Error.EPIPE

ERANGE          :: Platform_Error.ERANGE          /* Result too large */
EDEADLK         :: Platform_Error.EDEADLK         /* Resource deadlock would occur */
ENAMETOOLONG    :: Platform_Error.ENAMETOOLONG    /* File name too long */
ENOLCK          :: Platform_Error.ENOLCK          /* No record locks available */

ENOSYS          :: Platform_Error.ENOSYS          /* Invalid system call number */

ENOTEMPTY       :: Platform_Error.ENOTEMPTY       /* Directory not empty */
ELOOP           :: Platform_Error.ELOOP           /* Too many symbolic links encountered */
EWOULDBLOCK     :: Platform_Error.EWOULDBLOCK     /* Operation would block */
ENOMSG          :: Platform_Error.ENOMSG          /* No message of desired type */
EIDRM           :: Platform_Error.EIDRM           /* Identifier removed */
ECHRNG          :: Platform_Error.ECHRNG          /* Channel number out of range */
EL2NSYNC        :: Platform_Error.EL2NSYNC        /* Level 2 not synchronized */
EL3HLT          :: Platform_Error.EL3HLT          /* Level 3 halted */
EL3RST          :: Platform_Error.EL3RST          /* Level 3 reset */
ELNRNG          :: Platform_Error.ELNRNG          /* Link number out of range */
EUNATCH         :: Platform_Error.EUNATCH         /* Protocol driver not attached */
ENOCSI          :: Platform_Error.ENOCSI          /* No CSI structure available */
EL2HLT          :: Platform_Error.EL2HLT          /* Level 2 halted */
EBADE           :: Platform_Error.EBADE           /* Invalid exchange */
EBADR           :: Platform_Error.EBADR           /* Invalid request descriptor */
EXFULL          :: Platform_Error.EXFULL          /* Exchange full */
ENOANO          :: Platform_Error.ENOANO          /* No anode */
EBADRQC         :: Platform_Error.EBADRQC         /* Invalid request code */
EBADSLT         :: Platform_Error.EBADSLT         /* Invalid slot */
EDEADLOCK       :: Platform_Error.EDEADLOCK
EBFONT          :: Platform_Error.EBFONT          /* Bad font file format */
ENOSTR          :: Platform_Error.ENOSTR          /* Device not a stream */
ENODATA         :: Platform_Error.ENODATA         /* No data available */
ETIME           :: Platform_Error.ETIME           /* Timer expired */
ENOSR           :: Platform_Error.ENOSR           /* Out of streams resources */
ENONET          :: Platform_Error.ENONET          /* Machine is not on the network */
ENOPKG          :: Platform_Error.ENOPKG          /* Package not installed */
EREMOTE         :: Platform_Error.EREMOTE         /* Object is remote */
ENOLINK         :: Platform_Error.ENOLINK         /* Link has been severed */
EADV            :: Platform_Error.EADV            /* Advertise error */
ESRMNT          :: Platform_Error.ESRMNT          /* Srmount error */
ECOMM           :: Platform_Error.ECOMM           /* Communication error on send */
EPROTO          :: Platform_Error.EPROTO          /* Protocol error */
EMULTIHOP       :: Platform_Error.EMULTIHOP       /* Multihop attempted */
EDOTDOT         :: Platform_Error.EDOTDOT         /* RFS specific error */
EBADMSG         :: Platform_Error.EBADMSG         /* Not a data message */
EOVERFLOW       :: Platform_Error.EOVERFLOW       /* Value too large for defined data type */
ENOTUNIQ        :: Platform_Error.ENOTUNIQ        /* Name not unique on network */
EBADFD          :: Platform_Error.EBADFD          /* File descriptor in bad state */
EREMCHG         :: Platform_Error.EREMCHG         /* Remote address changed */
ELIBACC         :: Platform_Error.ELIBACC         /* Can not access a needed shared library */
ELIBBAD         :: Platform_Error.ELIBBAD         /* Accessing a corrupted shared library */
ELIBSCN         :: Platform_Error.ELIBSCN         /* .lib section in a.out corrupted */
ELIBMAX         :: Platform_Error.ELIBMAX         /* Attempting to link in too many shared libraries */
ELIBEXEC        :: Platform_Error.ELIBEXEC        /* Cannot exec a shared library directly */
EILSEQ          :: Platform_Error.EILSEQ          /* Illegal byte sequence */
ERESTART        :: Platform_Error.ERESTART        /* Interrupted system call should be restarted */
ESTRPIPE        :: Platform_Error.ESTRPIPE        /* Streams pipe error */
EUSERS          :: Platform_Error.EUSERS          /* Too many users */
ENOTSOCK        :: Platform_Error.ENOTSOCK        /* Socket operation on non-socket */
EDESTADDRREQ    :: Platform_Error.EDESTADDRREQ    /* Destination address required */
EMSGSIZE        :: Platform_Error.EMSGSIZE        /* Message too long */
EPROTOTYPE      :: Platform_Error.EPROTOTYPE      /* Protocol wrong type for socket */
ENOPROTOOPT     :: Platform_Error.ENOPROTOOPT     /* Protocol not available */
EPROTONOSUPPOR  :: Platform_Error.EPROTONOSUPPORT /* Protocol not supported */
ESOCKTNOSUPPOR  :: Platform_Error.ESOCKTNOSUPPORT /* Socket type not supported */
EOPNOTSUPP      :: Platform_Error.EOPNOTSUPP      /* Operation not supported on transport endpoint */
EPFNOSUPPORT    :: Platform_Error.EPFNOSUPPORT    /* Protocol family not supported */
EAFNOSUPPORT    :: Platform_Error.EAFNOSUPPORT    /* Address family not supported by protocol */
EADDRINUSE      :: Platform_Error.EADDRINUSE      /* Address already in use */
EADDRNOTAVAIL   :: Platform_Error.EADDRNOTAVAIL   /* Cannot assign requested address */
ENETDOWN        :: Platform_Error.ENETDOWN        /* Network is down */
ENETUNREACH     :: Platform_Error.ENETUNREACH     /* Network is unreachable */
ENETRESET       :: Platform_Error.ENETRESET       /* Network dropped connection because of reset */
ECONNABORTED    :: Platform_Error.ECONNABORTED    /* Software caused connection abort */
ECONNRESET      :: Platform_Error.ECONNRESET      /* Connection reset by peer */
ENOBUFS         :: Platform_Error.ENOBUFS         /* No buffer space available */
EISCONN         :: Platform_Error.EISCONN         /* Transport endpoint is already connected */
ENOTCONN        :: Platform_Error.ENOTCONN        /* Transport endpoint is not connected */
ESHUTDOWN       :: Platform_Error.ESHUTDOWN       /* Cannot send after transport endpoint shutdown */
ETOOMANYREFS    :: Platform_Error.ETOOMANYREFS    /* Too many references: cannot splice */
ETIMEDOUT       :: Platform_Error.ETIMEDOUT       /* Connection timed out */
ECONNREFUSED    :: Platform_Error.ECONNREFUSED    /* Connection refused */
EHOSTDOWN       :: Platform_Error.EHOSTDOWN       /* Host is down */
EHOSTUNREACH    :: Platform_Error.EHOSTUNREACH    /* No route to host */
EALREADY        :: Platform_Error.EALREADY        /* Operation already in progress */
EINPROGRESS     :: Platform_Error.EINPROGRESS     /* Operation now in progress */
ESTALE          :: Platform_Error.ESTALE          /* Stale file handle */
EUCLEAN         :: Platform_Error.EUCLEAN         /* Structure needs cleaning */
ENOTNAM         :: Platform_Error.ENOTNAM         /* Not a XENIX named type file */
ENAVAIL         :: Platform_Error.ENAVAIL         /* No XENIX semaphores available */
EISNAM          :: Platform_Error.EISNAM          /* Is a named type file */
EREMOTEIO       :: Platform_Error.EREMOTEIO       /* Remote I/O error */
EDQUOT          :: Platform_Error.EDQUOT          /* Quota exceeded */

ENOMEDIUM       :: Platform_Error.ENOMEDIUM       /* No medium found */
EMEDIUMTYPE     :: Platform_Error.EMEDIUMTYPE     /* Wrong medium type */
ECANCELED       :: Platform_Error.ECANCELED       /* Operation Canceled */
ENOKEY          :: Platform_Error.ENOKEY          /* Required key not available */
EKEYEXPIRED     :: Platform_Error.EKEYEXPIRED     /* Key has expired */
EKEYREVOKED     :: Platform_Error.EKEYREVOKED     /* Key has been revoked */
EKEYREJECTED    :: Platform_Error.EKEYREJECTED    /* Key was rejected by service */

/* for robust mutexes */
EOWNERDEAD      :: Platform_Error.EOWNERDEAD      /* Owner died */
ENOTRECOVERABLE :: Platform_Error.ENOTRECOVERABLE /* State not recoverable */

ERFKILL   :: Platform_Error.ERFKILL               /* Operation not possible due to RF-kill */

EHWPOISON :: Platform_Error.EHWPOISON             /* Memory page has hardware error */

ADDR_NO_RANDOMIZE :: 0x40000

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


AF_UNSPEC:    int : 0
AF_UNIX:      int : 1
AF_LOCAL:     int : AF_UNIX
AF_INET:      int : 2
AF_INET6:     int : 10
AF_PACKET:    int : 17
AF_BLUETOOTH: int : 31

SOCK_STREAM:    int : 1
SOCK_DGRAM:     int : 2
SOCK_RAW:       int : 3
SOCK_RDM:       int : 4
SOCK_SEQPACKET: int : 5
SOCK_PACKET:    int : 10

INADDR_ANY:       c.ulong : 0
INADDR_BROADCAST: c.ulong : 0xffffffff
INADDR_NONE:      c.ulong : 0xffffffff
INADDR_DUMMY:     c.ulong : 0xc0000008

IPPROTO_IP:       int : 0
IPPROTO_ICMP:     int : 1
IPPROTO_TCP:      int : 6
IPPROTO_UDP:      int : 17
IPPROTO_IPV6:     int : 41
IPPROTO_ETHERNET: int : 143
IPPROTO_RAW:      int : 255

SHUT_RD:   int : 0
SHUT_WR:   int : 1
SHUT_RDWR: int : 2


SOL_SOCKET:   int : 1
SO_DEBUG:     int : 1
SO_REUSEADDR: int : 2
SO_DONTROUTE: int : 5
SO_BROADCAST: int : 6
SO_SNDBUF:    int : 7
SO_RCVBUF:    int : 8
SO_KEEPALIVE: int : 9
SO_OOBINLINE: int : 10
SO_LINGER:    int : 13
SO_REUSEPORT: int : 15
SO_RCVTIMEO_NEW: int : 66
SO_SNDTIMEO_NEW: int : 67

TCP_NODELAY: int : 1
TCP_CORK:    int : 3

MSG_TRUNC : int : 0x20

// TODO: add remaining fcntl commands
// reference: https://github.com/torvalds/linux/blob/master/include/uapi/asm-generic/fcntl.h
F_GETFL: int : 3 /* Get file flags */
F_SETFL: int : 4 /* Set file flags */

// NOTE(zangent): These are OS specific!
// Do not mix these up!
RTLD_LAZY         :: 0x0001
RTLD_NOW          :: 0x0002
RTLD_BINDING_MASK :: 0x0003
RTLD_GLOBAL       :: 0x0100
RTLD_NOLOAD       :: 0x0004
RTLD_DEEPBIND     :: 0x0008
RTLD_NODELETE     :: 0x1000

socklen_t :: c.int

Timeval :: struct {
	seconds: i64,
	microseconds: int,
}

// "Argv" arguments converted to Odin strings
args := _alloc_command_line_arguments()

Unix_File_Time :: struct {
	seconds:     i64,
	nanoseconds: i64,
}

when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
	OS_Stat :: struct {
		device_id:     u64, // ID of device containing file
		serial:        u64, // File serial number
		mode:          u32, // Mode of the file
		nlink:         u32, // Number of hard links
		uid:           u32, // User ID of the file's owner
		gid:           u32, // Group ID of the file's group
		rdev:          u64, // Device ID, if device
		_:             u64, // Padding
		size:          i64, // Size of the file, in bytes
		block_size:    i32, // Optimal blocksize for I/O
		_:             i32, // Padding
		blocks:        i64, // Number of 512-byte blocks allocated

		last_access:   Unix_File_Time, // Time of last access
		modified:      Unix_File_Time, // Time of last modification
		status_change: Unix_File_Time, // Time of last status change

		_reserved:     [2]i32,
	}
	#assert(size_of(OS_Stat) == 128)
} else {
	OS_Stat :: struct {
		device_id:     u64, // ID of device containing file
		serial:        u64, // File serial number
		nlink:         u64, // Number of hard links
		mode:          u32, // Mode of the file
		uid:           u32, // User ID of the file's owner
		gid:           u32, // Group ID of the file's group
		_:             i32, // 32 bits of padding
		rdev:          u64, // Device ID, if device
		size:          i64, // Size of the file, in bytes
		block_size:    i64, // Optimal bllocksize for I/O
		blocks:        i64, // Number of 512-byte blocks allocated

		last_access:   Unix_File_Time, // Time of last access
		modified:      Unix_File_Time, // Time of last modification
		status_change: Unix_File_Time, // Time of last status change

		_reserved:     [3]i64,
	}
}

// NOTE(laleksic, 2021-01-21): Comment and rename these to match OS_Stat above
Dirent :: struct {
	ino:    u64,
	off:    u64,
	reclen: u16,
	type:   u8,
	name:   [256]byte,
}

ADDRESS_FAMILY :: u16
SOCKADDR :: struct #packed {
	sa_family: ADDRESS_FAMILY,
	sa_data: [14]c.char,
}

SOCKADDR_STORAGE_LH :: struct #packed {
	ss_family: ADDRESS_FAMILY,
	__ss_pad1: [6]c.char,
	__ss_align: i64,
	__ss_pad2: [112]c.char,
}

sockaddr_in :: struct #packed {
	sin_family: ADDRESS_FAMILY,
	sin_port: u16be,
	sin_addr: in_addr,
	sin_zero: [8]c.char,
}

sockaddr_in6 :: struct #packed {
	sin6_family: ADDRESS_FAMILY,
	sin6_port: u16be,
	sin6_flowinfo: c.ulong,
	sin6_addr: in6_addr,
	sin6_scope_id: c.ulong,
}

in_addr :: struct #packed {
	s_addr: u32,
}

in6_addr :: struct #packed {
	s6_addr: [16]u8,
}

rtnl_link_stats :: struct #packed {
	rx_packets:          u32,
	tx_packets:          u32,
	rx_bytes:            u32,
	tx_bytes:            u32,
	rx_errors:           u32,
	tx_errors:           u32,
	rx_dropped:          u32,
	tx_dropped:          u32,
	multicast:           u32,
	collisions:          u32,
	rx_length_errors:    u32,
	rx_over_errors:      u32,
	rx_crc_errors:       u32,
	rx_frame_errors:     u32,
	rx_fifo_errors:      u32,
	rx_missed_errors:    u32,
	tx_aborted_errors:   u32,
	tx_carrier_errors:   u32,
	tx_fifo_errors:      u32,
	tx_heartbeat_errors: u32,
	tx_window_errors:    u32,
	rx_compressed:       u32,
	tx_compressed:       u32,
	rx_nohandler:        u32,
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
	MASTER         = 10, /* Master of a load balancer.  */
	SLAVE          = 11, /* Slave of a load balancer.  */
	MULTICAST      = 12, /* Supports multicast.  */
	PORTSEL        = 13, /* Can set media type.  */
	AUTOMEDIA      = 14, /* Auto media select active.  */
	DYNAMIC        = 15, /* Dialup device with changing addresses.  */
	LOWER_UP       = 16,
	DORMANT        = 17,
	ECHO           = 18,
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


@(require_results) S_ISLNK  :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFLNK  }
@(require_results) S_ISREG  :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFREG  }
@(require_results) S_ISDIR  :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFDIR  }
@(require_results) S_ISCHR  :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFCHR  }
@(require_results) S_ISBLK  :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFBLK  }
@(require_results) S_ISFIFO :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFIFO  }
@(require_results) S_ISSOCK :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFSOCK }

F_OK :: 0 // Test for file existance
X_OK :: 1 // Test for execute permission
W_OK :: 2 // Test for write permission
R_OK :: 4 // Test for read permission

AT_FDCWD            :: ~uintptr(99)	/* -100 */
AT_REMOVEDIR        :: uintptr(0x200)
AT_SYMLINK_NOFOLLOW :: uintptr(0x100)

pollfd :: struct {
	fd:      c.int,
	events:  c.short,
	revents: c.short,
}

sigset_t :: distinct u64

foreign libc {
	@(link_name="__errno_location") __errno_location    :: proc() -> ^c.int ---

	@(link_name="getpagesize")      _unix_getpagesize   :: proc() -> c.int ---
	@(link_name="get_nprocs")       _unix_get_nprocs    :: proc() -> c.int ---
	@(link_name="fdopendir")        _unix_fdopendir     :: proc(fd: Handle) -> Dir ---
	@(link_name="closedir")         _unix_closedir      :: proc(dirp: Dir) -> c.int ---
	@(link_name="rewinddir")        _unix_rewinddir     :: proc(dirp: Dir) ---
	@(link_name="readdir_r")        _unix_readdir_r     :: proc(dirp: Dir, entry: ^Dirent, result: ^^Dirent) -> c.int ---

	@(link_name="malloc")           _unix_malloc        :: proc(size: c.size_t) -> rawptr ---
	@(link_name="calloc")           _unix_calloc        :: proc(num, size: c.size_t) -> rawptr ---
	@(link_name="free")             _unix_free          :: proc(ptr: rawptr) ---
	@(link_name="realloc")          _unix_realloc       :: proc(ptr: rawptr, size: c.size_t) -> rawptr ---

	@(link_name="execvp")           _unix_execvp       :: proc(path: cstring, argv: [^]cstring) -> int ---
	@(link_name="getenv")           _unix_getenv        :: proc(cstring) -> cstring ---
	@(link_name="putenv")           _unix_putenv        :: proc(cstring) -> c.int ---
	@(link_name="setenv")           _unix_setenv        :: proc(key: cstring, value: cstring, overwrite: c.int) -> c.int ---
	@(link_name="realpath")         _unix_realpath      :: proc(path: cstring, resolved_path: [^]byte = nil) -> cstring ---

	@(link_name="exit")             _unix_exit          :: proc(status: c.int) -> ! ---
}
foreign dl {
	@(link_name="dlopen")           _unix_dlopen        :: proc(filename: cstring, flags: c.int) -> rawptr ---
	@(link_name="dlsym")            _unix_dlsym         :: proc(handle: rawptr, symbol: cstring) -> rawptr ---
	@(link_name="dlclose")          _unix_dlclose       :: proc(handle: rawptr) -> c.int ---
	@(link_name="dlerror")          _unix_dlerror       :: proc() -> cstring ---

	@(link_name="getifaddrs")       _getifaddrs         :: proc(ifap: ^^ifaddrs) -> (c.int) ---
	@(link_name="freeifaddrs")      _freeifaddrs        :: proc(ifa: ^ifaddrs) ---
}

@(require_results)
is_path_separator :: proc(r: rune) -> bool {
	return r == '/'
}

// determine errno from syscall return value
@(private, require_results)
_get_errno :: proc(res: int) -> Error {
	if res < 0 && res > -4096 {
		return Platform_Error(-res)
	}
	return nil
}

// get errno from libc
@(require_results, no_instrumentation)
get_last_error :: proc "contextless" () -> Error {
	err := Platform_Error(__errno_location()^)
	#partial switch err {
	case .NONE:
		return nil
	case .EPERM:
		return .Permission_Denied
	case .EEXIST:
		return .Exist
	case .ENOENT:
		return .Not_Exist
	}
	return err
}

personality :: proc(persona: u64) -> Error {
	res := unix.sys_personality(persona)
	if res == -1 {
		return _get_errno(res)
	}
	return nil
}

@(require_results)
fork :: proc() -> (Pid, Error) {
	pid := unix.sys_fork()
	if pid == -1 {
		return -1, _get_errno(pid)
	}
	return Pid(pid), nil
}

execvp :: proc(path: string, args: []string) -> Error {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)

	args_cstrs := make([]cstring, len(args) + 2, context.temp_allocator)
	args_cstrs[0] = strings.clone_to_cstring(path, context.temp_allocator)
	for i := 0; i < len(args); i += 1 {
		args_cstrs[i+1] = strings.clone_to_cstring(args[i], context.temp_allocator)
	}

	_unix_execvp(path_cstr, raw_data(args_cstrs))
	return get_last_error()
}


@(require_results)
open :: proc(path: string, flags: int = O_RDONLY, mode: int = 0o000) -> (Handle, Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	handle := unix.sys_open(cstr, flags, uint(mode))
	if handle < 0 {
		return INVALID_HANDLE, _get_errno(handle)
	}
	return Handle(handle), nil
}

close :: proc(fd: Handle) -> Error {
	return _get_errno(unix.sys_close(int(fd)))
}

flush :: proc(fd: Handle) -> Error {
	return _get_errno(unix.sys_fsync(int(fd)))
}

// If you read or write more than `SSIZE_MAX` bytes, result is implementation defined (probably an error).
// `SSIZE_MAX` is also implementation defined but usually the max of a `ssize_t` which is `max(int)` in Odin.
// In practice a read/write call would probably never read/write these big buffers all at once,
// which is why the number of bytes is returned and why there are procs that will call this in a
// loop for you.
// We set a max of 1GB to keep alignment and to be safe.
@(private)
MAX_RW :: 1 << 30

read :: proc(fd: Handle, data: []byte) -> (int, Error) {
	if len(data) == 0 {
		return 0, nil
	}

	to_read := min(uint(len(data)), MAX_RW)

	bytes_read := unix.sys_read(int(fd), raw_data(data), to_read)
	if bytes_read < 0 {
		return -1, _get_errno(bytes_read)
	}
	return bytes_read, nil
}

write :: proc(fd: Handle, data: []byte) -> (int, Error) {
	if len(data) == 0 {
		return 0, nil
	}

	to_write := min(uint(len(data)), MAX_RW)

	bytes_written := unix.sys_write(int(fd), raw_data(data), to_write)
	if bytes_written < 0 {
		return -1, _get_errno(bytes_written)
	}
	return bytes_written, nil
}

read_at :: proc(fd: Handle, data: []byte, offset: i64) -> (int, Error) {
	if len(data) == 0 {
		return 0, nil
	}

	to_read := min(uint(len(data)), MAX_RW)

	bytes_read := unix.sys_pread(int(fd), raw_data(data), to_read, offset)
	if bytes_read < 0 {
		return -1, _get_errno(bytes_read)
	}
	return bytes_read, nil
}

write_at :: proc(fd: Handle, data: []byte, offset: i64) -> (int, Error) {
	if len(data) == 0 {
		return 0, nil
	}

	to_write := min(uint(len(data)), MAX_RW)

	bytes_written := unix.sys_pwrite(int(fd), raw_data(data), to_write, offset)
	if bytes_written < 0 {
		return -1, _get_errno(bytes_written)
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
	res := unix.sys_lseek(int(fd), offset, whence)
	if res < 0 {
		errno := _get_errno(int(res))
		switch errno {
		case .EINVAL:
			return 0, .Invalid_Offset
		}
		return 0, errno
	}
	return i64(res), nil
}

@(require_results)
file_size :: proc(fd: Handle) -> (i64, Error) {
	// deliberately uninitialized; the syscall fills this buffer for us
	s: OS_Stat = ---
	result := unix.sys_fstat(int(fd), rawptr(&s))
	if result < 0 {
		return 0, _get_errno(result)
	}
	return max(s.size, 0), nil
}

rename :: proc(old_path, new_path: string) -> Error {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	old_path_cstr := strings.clone_to_cstring(old_path, context.temp_allocator)
	new_path_cstr := strings.clone_to_cstring(new_path, context.temp_allocator)
	return _get_errno(unix.sys_rename(old_path_cstr, new_path_cstr))
}

remove :: proc(path: string) -> Error {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	return _get_errno(unix.sys_unlink(path_cstr))
}

make_directory :: proc(path: string, mode: u32 = 0o775) -> Error {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	return _get_errno(unix.sys_mkdir(path_cstr, uint(mode)))
}

remove_directory :: proc(path: string) -> Error {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	return _get_errno(unix.sys_rmdir(path_cstr))
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
	res := unix.sys_access(cpath, O_RDONLY)
	return res == 0
}

// NOTE(bill): Uses startup to initialize it

stdin:  Handle = 0
stdout: Handle = 1
stderr: Handle = 2

/* TODO(zangent): Implement these!
last_write_time :: proc(fd: Handle) -> File_Time {}
last_write_time_by_name :: proc(name: string) -> File_Time {}
*/
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

	// deliberately uninitialized; the syscall fills this buffer for us
	s: OS_Stat = ---
	result := unix.sys_stat(cstr, &s)
	if result < 0 {
		return s, _get_errno(result)
	}
	return s, nil
}

@(private, require_results)
_lstat :: proc(path: string) -> (OS_Stat, Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)

	// deliberately uninitialized; the syscall fills this buffer for us
	s: OS_Stat = ---
	result := unix.sys_lstat(cstr, &s)
	if result < 0 {
		return s, _get_errno(result)
	}
	return s, nil
}

@(private, require_results)
_fstat :: proc(fd: Handle) -> (OS_Stat, Error) {
	// deliberately uninitialized; the syscall fills this buffer for us
	s: OS_Stat = ---
	result := unix.sys_fstat(int(fd), rawptr(&s))
	if result < 0 {
		return s, _get_errno(result)
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
	end_of_stream = false

	return
}

@(private, require_results)
_readlink :: proc(path: string) -> (string, Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == context.allocator)
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)

	bufsz : uint = 256
	buf := make([]byte, bufsz)
	for {
		rc := unix.sys_readlink(path_cstr, &(buf[0]), bufsz)
		if rc < 0 {
			delete(buf)
			return "", _get_errno(rc)
		} else if rc == int(bufsz) {
			// NOTE(laleksic, 2021-01-21): Any cleaner way to resize the slice?
			bufsz *= 2
			delete(buf)
			buf = make([]byte, bufsz)
		} else {
			return strings.string_from_ptr(&buf[0], rc), nil
		}
	}
}

@(private, require_results)
_dup :: proc(fd: Handle) -> (Handle, Error) {
	dup, err := linux.dup(linux.Fd(fd))
	return Handle(dup), err
}

@(require_results)
absolute_path_from_handle :: proc(fd: Handle) -> (string, Error) {
	buf : [256]byte
	fd_str := strconv.itoa( buf[:], cast(int)fd )

	procfs_path := strings.concatenate( []string{ "/proc/self/fd/", fd_str } )
	defer delete(procfs_path)

	return _readlink(procfs_path)
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
	result := unix.sys_access(cstr, mask)
	if result < 0 {
		return false, _get_errno(result)
	}
	return true, nil
}

@(require_results)
lookup_env :: proc(key: string, allocator := context.allocator) -> (value: string, found: bool) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == allocator)
	path_str := strings.clone_to_cstring(key, context.temp_allocator)
	// NOTE(tetra): Lifetime of 'cstr' is unclear, but _unix_free(cstr) segfaults.
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

set_env :: proc(key, value: string) -> Error {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	key_cstring := strings.clone_to_cstring(key, context.temp_allocator)
	value_cstring := strings.clone_to_cstring(value, context.temp_allocator)
	// NOTE(GoNZooo): `setenv` instead of `putenv` because it copies both key and value more commonly
	res := _unix_setenv(key_cstring, value_cstring, 1)
	if res < 0 {
		return get_last_error()
	}
	return nil
}

unset_env :: proc(key: string) -> Error {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	s := strings.clone_to_cstring(key, context.temp_allocator)
	res := _unix_putenv(s)
	if res < 0 {
		return get_last_error()
	}
	return nil
}

@(require_results)
get_current_directory :: proc(allocator := context.allocator) -> string {
	context.allocator = allocator
	// NOTE(tetra): I would use PATH_MAX here, but I was not able to find
	// an authoritative value for it across all systems.
	// The largest value I could find was 4096, so might as well use the page size.
	page_size := get_page_size()
	buf := make([dynamic]u8, page_size)
	for {
		#no_bounds_check res := unix.sys_getcwd(&buf[0], uint(len(buf)))

		if res >= 0 {
			return strings.string_from_null_terminated_ptr(&buf[0], len(buf))
		}
		if _get_errno(res) != ERANGE {
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
	res := unix.sys_chdir(cstr)
	if res < 0 {
		return _get_errno(res)
	}
	return nil
}

exit :: proc "contextless" (code: int) -> ! {
	runtime._cleanup_runtime_contextless()
	_unix_exit(c.int(code))
}

@(require_results)
current_thread_id :: proc "contextless" () -> int {
	return unix.sys_gettid()
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
	return int(_unix_get_nprocs())
}

@(require_results)
_alloc_command_line_arguments :: proc() -> []string {
	res := make([]string, len(runtime.args__))
	for arg, i in runtime.args__ {
		res[i] = string(arg)
	}
	return res
}

@(require_results)
socket :: proc(domain: int, type: int, protocol: int) -> (Socket, Error) {
	result := unix.sys_socket(domain, type, protocol)
	if result < 0 {
		return 0, _get_errno(result)
	}
	return Socket(result), nil
}

bind :: proc(sd: Socket, addr: ^SOCKADDR, len: socklen_t) -> Error {
	result := unix.sys_bind(int(sd), addr, len)
	if result < 0 {
		return _get_errno(result)
	}
	return nil
}


connect :: proc(sd: Socket, addr: ^SOCKADDR, len: socklen_t) -> Error {
	result := unix.sys_connect(int(sd), addr, len)
	if result < 0 {
		return _get_errno(result)
	}
	return nil
}

accept :: proc(sd: Socket, addr: ^SOCKADDR, len: rawptr) -> (Socket, Error) {
	result := unix.sys_accept(int(sd), rawptr(addr), len)
	if result < 0 {
		return 0, _get_errno(result)
	}
	return Socket(result), nil
}

listen :: proc(sd: Socket, backlog: int) -> Error {
	result := unix.sys_listen(int(sd), backlog)
	if result < 0 {
		return _get_errno(result)
	}
	return nil
}

setsockopt :: proc(sd: Socket, level: int, optname: int, optval: rawptr, optlen: socklen_t) -> Error {
	result := unix.sys_setsockopt(int(sd), level, optname, optval, optlen)
	if result < 0 {
		return _get_errno(result)
	}
	return nil
}


recvfrom :: proc(sd: Socket, data: []byte, flags: int, addr: ^SOCKADDR, addr_size: ^socklen_t) -> (u32, Error) {
	result := unix.sys_recvfrom(int(sd), raw_data(data), len(data), flags, addr, uintptr(addr_size))
	if result < 0 {
		return 0, _get_errno(int(result))
	}
	return u32(result), nil
}

recv :: proc(sd: Socket, data: []byte, flags: int) -> (u32, Error) {
	result := unix.sys_recvfrom(int(sd), raw_data(data), len(data), flags, nil, 0)
	if result < 0 {
		return 0, _get_errno(int(result))
	}
	return u32(result), nil
}


sendto :: proc(sd: Socket, data: []u8, flags: int, addr: ^SOCKADDR, addrlen: socklen_t) -> (u32, Error) {
	result := unix.sys_sendto(int(sd), raw_data(data), len(data), flags, addr, addrlen)
	if result < 0 {
		return 0, _get_errno(int(result))
	}
	return u32(result), nil
}

send :: proc(sd: Socket, data: []byte, flags: int) -> (u32, Error) {
	result := unix.sys_sendto(int(sd), raw_data(data), len(data), 0, nil, 0)
	if result < 0 {
		return 0, _get_errno(int(result))
	}
	return u32(result), nil
}

shutdown :: proc(sd: Socket, how: int) -> Error {
	result := unix.sys_shutdown(int(sd), how)
	if result < 0 {
		return _get_errno(result)
	}
	return nil
}

fcntl :: proc(fd: int, cmd: int, arg: int) -> (int, Error) {
	result := unix.sys_fcntl(fd, cmd, arg)
	if result < 0 {
		return 0, _get_errno(result)
	}
	return result, nil
}

@(require_results)
poll :: proc(fds: []pollfd, timeout: int) -> (int, Error) {
	result := unix.sys_poll(raw_data(fds), uint(len(fds)), timeout)
	if result < 0 {
		return 0, _get_errno(result)
	}
	return result, nil
}

@(require_results)
ppoll :: proc(fds: []pollfd, timeout: ^unix.timespec, sigmask: ^sigset_t) -> (int, Error) {
	result := unix.sys_ppoll(raw_data(fds), uint(len(fds)), timeout, sigmask, size_of(sigset_t))
	if result < 0 {
		return 0, _get_errno(result)
	}
	return result, nil
}
