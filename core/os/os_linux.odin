package os

foreign import dl   "system:dl"
foreign import libc "system:c"

import "base:runtime"
import "core:strings"
import "core:c"
import "core:strconv"
import "base:intrinsics"

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

Handle    :: distinct i32
Pid       :: distinct i32
File_Time :: distinct u64
Errno     :: distinct i32
Socket    :: distinct int

INVALID_HANDLE :: ~Handle(0)

ERROR_NONE:     Errno : 0
EPERM:          Errno : 1
ENOENT:         Errno : 2
ESRCH:          Errno : 3
EINTR:          Errno : 4
EIO:            Errno : 5
ENXIO:          Errno : 6
EBADF:          Errno : 9
EAGAIN:         Errno : 11
ENOMEM:         Errno : 12
EACCES:         Errno : 13
EFAULT:         Errno : 14
EEXIST:         Errno : 17
ENODEV:         Errno : 19
ENOTDIR:        Errno : 20
EISDIR:         Errno : 21
EINVAL:         Errno : 22
ENFILE:         Errno : 23
EMFILE:         Errno : 24
ETXTBSY:        Errno : 26
EFBIG:          Errno : 27
ENOSPC:         Errno : 28
ESPIPE:         Errno : 29
EROFS:          Errno : 30
EPIPE:          Errno : 32

ERANGE:         Errno : 34 /* Result too large */
EDEADLK:        Errno : 35 /* Resource deadlock would occur */
ENAMETOOLONG:   Errno : 36 /* File name too long */
ENOLCK:         Errno : 37 /* No record locks available */

ENOSYS:         Errno : 38	/* Invalid system call number */

ENOTEMPTY:      Errno : 39	/* Directory not empty */
ELOOP:          Errno : 40	/* Too many symbolic links encountered */
EWOULDBLOCK:    Errno : EAGAIN /* Operation would block */
ENOMSG:         Errno : 42	/* No message of desired type */
EIDRM:          Errno : 43	/* Identifier removed */
ECHRNG:         Errno : 44	/* Channel number out of range */
EL2NSYNC:       Errno : 45	/* Level 2 not synchronized */
EL3HLT:         Errno : 46	/* Level 3 halted */
EL3RST:         Errno : 47	/* Level 3 reset */
ELNRNG:         Errno : 48	/* Link number out of range */
EUNATCH:        Errno : 49	/* Protocol driver not attached */
ENOCSI:         Errno : 50	/* No CSI structure available */
EL2HLT:         Errno : 51	/* Level 2 halted */
EBADE:          Errno : 52	/* Invalid exchange */
EBADR:          Errno : 53	/* Invalid request descriptor */
EXFULL:         Errno : 54	/* Exchange full */
ENOANO:         Errno : 55	/* No anode */
EBADRQC:        Errno : 56	/* Invalid request code */
EBADSLT:        Errno : 57	/* Invalid slot */
EDEADLOCK:      Errno : EDEADLK
EBFONT:         Errno : 59	/* Bad font file format */
ENOSTR:         Errno : 60	/* Device not a stream */
ENODATA:        Errno : 61	/* No data available */
ETIME:          Errno : 62	/* Timer expired */
ENOSR:          Errno : 63	/* Out of streams resources */
ENONET:         Errno : 64	/* Machine is not on the network */
ENOPKG:         Errno : 65	/* Package not installed */
EREMOTE:        Errno : 66	/* Object is remote */
ENOLINK:        Errno : 67	/* Link has been severed */
EADV:           Errno : 68	/* Advertise error */
ESRMNT:         Errno : 69	/* Srmount error */
ECOMM:          Errno : 70	/* Communication error on send */
EPROTO:         Errno : 71	/* Protocol error */
EMULTIHOP:      Errno : 72	/* Multihop attempted */
EDOTDOT:        Errno : 73	/* RFS specific error */
EBADMSG:        Errno : 74	/* Not a data message */
EOVERFLOW:      Errno : 75	/* Value too large for defined data type */
ENOTUNIQ:       Errno : 76	/* Name not unique on network */
EBADFD:         Errno : 77	/* File descriptor in bad state */
EREMCHG:        Errno : 78	/* Remote address changed */
ELIBACC:        Errno : 79	/* Can not access a needed shared library */
ELIBBAD:        Errno : 80	/* Accessing a corrupted shared library */
ELIBSCN:        Errno : 81	/* .lib section in a.out corrupted */
ELIBMAX:        Errno : 82	/* Attempting to link in too many shared libraries */
ELIBEXEC:       Errno : 83	/* Cannot exec a shared library directly */
EILSEQ:         Errno : 84	/* Illegal byte sequence */
ERESTART:       Errno : 85	/* Interrupted system call should be restarted */
ESTRPIPE:       Errno : 86	/* Streams pipe error */
EUSERS:         Errno : 87	/* Too many users */
ENOTSOCK:       Errno : 88	/* Socket operation on non-socket */
EDESTADDRREQ:   Errno : 89	/* Destination address required */
EMSGSIZE:       Errno : 90	/* Message too long */
EPROTOTYPE:     Errno : 91	/* Protocol wrong type for socket */
ENOPROTOOPT:    Errno : 92	/* Protocol not available */
EPROTONOSUPPORT:Errno : 93	/* Protocol not supported */
ESOCKTNOSUPPORT:Errno : 94	/* Socket type not supported */
EOPNOTSUPP: 	Errno : 95	/* Operation not supported on transport endpoint */
EPFNOSUPPORT: 	Errno : 96	/* Protocol family not supported */
EAFNOSUPPORT: 	Errno : 97	/* Address family not supported by protocol */
EADDRINUSE: 	Errno : 98	/* Address already in use */
EADDRNOTAVAIL: 	Errno : 99	/* Cannot assign requested address */
ENETDOWN: 		Errno : 100	/* Network is down */
ENETUNREACH: 	Errno : 101	/* Network is unreachable */
ENETRESET: 		Errno : 102	/* Network dropped connection because of reset */
ECONNABORTED: 	Errno : 103	/* Software caused connection abort */
ECONNRESET: 	Errno : 104	/* Connection reset by peer */
ENOBUFS: 		Errno : 105	/* No buffer space available */
EISCONN: 		Errno : 106	/* Transport endpoint is already connected */
ENOTCONN: 		Errno : 107	/* Transport endpoint is not connected */
ESHUTDOWN: 		Errno : 108	/* Cannot send after transport endpoint shutdown */
ETOOMANYREFS: 	Errno : 109	/* Too many references: cannot splice */
ETIMEDOUT: 		Errno : 110	/* Connection timed out */
ECONNREFUSED: 	Errno : 111	/* Connection refused */
EHOSTDOWN: 		Errno : 112	/* Host is down */
EHOSTUNREACH: 	Errno : 113	/* No route to host */
EALREADY: 		Errno : 114	/* Operation already in progress */
EINPROGRESS: 	Errno : 115	/* Operation now in progress */
ESTALE: 		Errno : 116	/* Stale file handle */
EUCLEAN: 		Errno : 117	/* Structure needs cleaning */
ENOTNAM: 		Errno : 118	/* Not a XENIX named type file */
ENAVAIL: 		Errno : 119	/* No XENIX semaphores available */
EISNAM: 		Errno : 120	/* Is a named type file */
EREMOTEIO: 		Errno : 121	/* Remote I/O error */
EDQUOT: 		Errno : 122	/* Quota exceeded */

ENOMEDIUM: 		Errno : 123	/* No medium found */
EMEDIUMTYPE: 	Errno : 124	/* Wrong medium type */
ECANCELED: 		Errno : 125	/* Operation Canceled */
ENOKEY: 		Errno : 126	/* Required key not available */
EKEYEXPIRED: 	Errno : 127	/* Key has expired */
EKEYREVOKED: 	Errno : 128	/* Key has been revoked */
EKEYREJECTED: 	Errno : 129	/* Key was rejected by service */

/* for robust mutexes */
EOWNERDEAD: 	Errno : 130	/* Owner died */
ENOTRECOVERABLE: Errno : 131	/* State not recoverable */

ERFKILL: 		Errno : 132	/* Operation not possible due to RF-kill */

EHWPOISON: 		Errno : 133	/* Memory page has hardware error */

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
RTLD_LAZY         :: 0x001
RTLD_NOW          :: 0x002
RTLD_BINDING_MASK :: 0x3
RTLD_GLOBAL       :: 0x100

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

when ODIN_ARCH == .arm64 {
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


S_ISLNK  :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFLNK  }
S_ISREG  :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFREG  }
S_ISDIR  :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFDIR  }
S_ISCHR  :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFCHR  }
S_ISBLK  :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFBLK  }
S_ISFIFO :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFIFO  }
S_ISSOCK :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFSOCK }

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
	@(link_name="realpath")         _unix_realpath      :: proc(path: cstring, resolved_path: rawptr) -> rawptr ---

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

is_path_separator :: proc(r: rune) -> bool {
	return r == '/'
}

// determine errno from syscall return value
@private
_get_errno :: proc(res: int) -> Errno {
	if res < 0 && res > -4096 {
		return Errno(-res)
	}
	return 0
}

// get errno from libc
get_last_error :: proc "contextless" () -> int {
	return int(__errno_location()^)
}

personality :: proc(persona: u64) -> (Errno) {
	res := unix.sys_personality(persona)
	if res == -1 {
		return _get_errno(res)
	}
	return ERROR_NONE
}

fork :: proc() -> (Pid, Errno) {
	pid := unix.sys_fork()
	if pid == -1 {
		return -1, _get_errno(pid)
	}
	return Pid(pid), ERROR_NONE
}

execvp :: proc(path: string, args: []string) -> Errno {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)

	args_cstrs := make([]cstring, len(args) + 2, context.temp_allocator)
	args_cstrs[0] = strings.clone_to_cstring(path, context.temp_allocator)
	for i := 0; i < len(args); i += 1 {
		args_cstrs[i+1] = strings.clone_to_cstring(args[i], context.temp_allocator)
	}

	_unix_execvp(path_cstr, raw_data(args_cstrs))
	return Errno(get_last_error())
}


open :: proc(path: string, flags: int = O_RDONLY, mode: int = 0o000) -> (Handle, Errno) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	handle := unix.sys_open(cstr, flags, uint(mode))
	if handle < 0 {
		return INVALID_HANDLE, _get_errno(handle)
	}
	return Handle(handle), ERROR_NONE
}

close :: proc(fd: Handle) -> Errno {
	return _get_errno(unix.sys_close(int(fd)))
}

// If you read or write more than `SSIZE_MAX` bytes, result is implementation defined (probably an error).
// `SSIZE_MAX` is also implementation defined but usually the max of a `ssize_t` which is `max(int)` in Odin.
// In practice a read/write call would probably never read/write these big buffers all at once,
// which is why the number of bytes is returned and why there are procs that will call this in a
// loop for you.
// We set a max of 1GB to keep alignment and to be safe.
@(private)
MAX_RW :: 1 << 30

read :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	if len(data) == 0 {
		return 0, ERROR_NONE
	}

	to_read := min(uint(len(data)), MAX_RW)

	bytes_read := unix.sys_read(int(fd), raw_data(data), to_read)
	if bytes_read < 0 {
		return -1, _get_errno(bytes_read)
	}
	return bytes_read, ERROR_NONE
}

write :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	if len(data) == 0 {
		return 0, ERROR_NONE
	}

	to_write := min(uint(len(data)), MAX_RW)

	bytes_written := unix.sys_write(int(fd), raw_data(data), to_write)
	if bytes_written < 0 {
		return -1, _get_errno(bytes_written)
	}
	return bytes_written, ERROR_NONE
}

read_at :: proc(fd: Handle, data: []byte, offset: i64) -> (int, Errno) {
	if len(data) == 0 {
		return 0, ERROR_NONE
	}

	to_read := min(uint(len(data)), MAX_RW)

	bytes_read := unix.sys_pread(int(fd), raw_data(data), to_read, offset)
	if bytes_read < 0 {
		return -1, _get_errno(bytes_read)
	}
	return bytes_read, ERROR_NONE
}

write_at :: proc(fd: Handle, data: []byte, offset: i64) -> (int, Errno) {
	if len(data) == 0 {
		return 0, ERROR_NONE
	}

	to_write := min(uint(len(data)), MAX_RW)

	bytes_written := unix.sys_pwrite(int(fd), raw_data(data), to_write, offset)
	if bytes_written < 0 {
		return -1, _get_errno(bytes_written)
	}
	return bytes_written, ERROR_NONE
}

seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Errno) {
	res := unix.sys_lseek(int(fd), offset, whence)
	if res < 0 {
		return -1, _get_errno(int(res))
	}
	return i64(res), ERROR_NONE
}

file_size :: proc(fd: Handle) -> (i64, Errno) {
	// deliberately uninitialized; the syscall fills this buffer for us
	s: OS_Stat = ---
	result := unix.sys_fstat(int(fd), rawptr(&s))
	if result < 0 {
		return 0, _get_errno(result)
	}
	return max(s.size, 0), ERROR_NONE
}

rename :: proc(old_path, new_path: string) -> Errno {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	old_path_cstr := strings.clone_to_cstring(old_path, context.temp_allocator)
	new_path_cstr := strings.clone_to_cstring(new_path, context.temp_allocator)
	return _get_errno(unix.sys_rename(old_path_cstr, new_path_cstr))
}

remove :: proc(path: string) -> Errno {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	return _get_errno(unix.sys_unlink(path_cstr))
}

make_directory :: proc(path: string, mode: u32 = 0o775) -> Errno {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	return _get_errno(unix.sys_mkdir(path_cstr, uint(mode)))
}

remove_directory :: proc(path: string) -> Errno {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	return _get_errno(unix.sys_rmdir(path_cstr))
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

	// deliberately uninitialized; the syscall fills this buffer for us
	s: OS_Stat = ---
	result := unix.sys_stat(cstr, &s)
	if result < 0 {
		return s, _get_errno(result)
	}
	return s, ERROR_NONE
}

@private
_lstat :: proc(path: string) -> (OS_Stat, Errno) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)

	// deliberately uninitialized; the syscall fills this buffer for us
	s: OS_Stat = ---
	result := unix.sys_lstat(cstr, &s)
	if result < 0 {
		return s, _get_errno(result)
	}
	return s, ERROR_NONE
}

@private
_fstat :: proc(fd: Handle) -> (OS_Stat, Errno) {
	// deliberately uninitialized; the syscall fills this buffer for us
	s: OS_Stat = ---
	result := unix.sys_fstat(int(fd), rawptr(&s))
	if result < 0 {
		return s, _get_errno(result)
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
			return strings.string_from_ptr(&buf[0], rc), ERROR_NONE
		}
	}
}

absolute_path_from_handle :: proc(fd: Handle) -> (string, Errno) {
	buf : [256]byte
	fd_str := strconv.itoa( buf[:], cast(int)fd )

	procfs_path := strings.concatenate( []string{ "/proc/self/fd/", fd_str } )
	defer delete(procfs_path)

	return _readlink(procfs_path)
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

	path = strings.clone(string(cstring(path_ptr)))

	return path, ERROR_NONE
}

access :: proc(path: string, mask: int) -> (bool, Errno) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	result := unix.sys_access(cstr, mask)
	if result < 0 {
		return false, _get_errno(result)
	}
	return true, ERROR_NONE
}

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

get_env :: proc(key: string, allocator := context.allocator) -> (value: string) {
	value, _ = lookup_env(key, allocator)
	return
}

set_env :: proc(key, value: string) -> Errno {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	key_cstring := strings.clone_to_cstring(key, context.temp_allocator)
	value_cstring := strings.clone_to_cstring(value, context.temp_allocator)
	// NOTE(GoNZooo): `setenv` instead of `putenv` because it copies both key and value more commonly
	res := _unix_setenv(key_cstring, value_cstring, 1)
	if res < 0 {
		return Errno(get_last_error())
	}
	return ERROR_NONE
}

unset_env :: proc(key: string) -> Errno {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	s := strings.clone_to_cstring(key, context.temp_allocator)
	res := _unix_putenv(s)
	if res < 0 {
		return Errno(get_last_error())
	}
	return ERROR_NONE
}

get_current_directory :: proc() -> string {
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

set_current_directory :: proc(path: string) -> (err: Errno) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	res := unix.sys_chdir(cstr)
	if res < 0 {
		return _get_errno(res)
	}
	return ERROR_NONE
}

exit :: proc "contextless" (code: int) -> ! {
	runtime._cleanup_runtime_contextless()
	_unix_exit(c.int(code))
}

current_thread_id :: proc "contextless" () -> int {
	return unix.sys_gettid()
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
	if page_size != -1 {
		return page_size
	}

	page_size = int(_unix_getpagesize())
	return page_size
}

@(private)
_processor_core_count :: proc() -> int {
	return int(_unix_get_nprocs())
}

_alloc_command_line_arguments :: proc() -> []string {
	res := make([]string, len(runtime.args__))
	for arg, i in runtime.args__ {
		res[i] = string(arg)
	}
	return res
}

socket :: proc(domain: int, type: int, protocol: int) -> (Socket, Errno) {
	result := unix.sys_socket(domain, type, protocol)
	if result < 0 {
		return 0, _get_errno(result)
	}
	return Socket(result), ERROR_NONE
}

bind :: proc(sd: Socket, addr: ^SOCKADDR, len: socklen_t) -> (Errno) {
	result := unix.sys_bind(int(sd), addr, len)
	if result < 0 {
		return _get_errno(result)
	}
	return ERROR_NONE
}


connect :: proc(sd: Socket, addr: ^SOCKADDR, len: socklen_t) -> (Errno) {
	result := unix.sys_connect(int(sd), addr, len)
	if result < 0 {
		return _get_errno(result)
	}
	return ERROR_NONE
}

accept :: proc(sd: Socket, addr: ^SOCKADDR, len: rawptr) -> (Socket, Errno) {
	result := unix.sys_accept(int(sd), rawptr(addr), len)
	if result < 0 {
		return 0, _get_errno(result)
	}
	return Socket(result), ERROR_NONE
}

listen :: proc(sd: Socket, backlog: int) -> (Errno) {
	result := unix.sys_listen(int(sd), backlog)
	if result < 0 {
		return _get_errno(result)
	}
	return ERROR_NONE
}

setsockopt :: proc(sd: Socket, level: int, optname: int, optval: rawptr, optlen: socklen_t) -> (Errno) {
	result := unix.sys_setsockopt(int(sd), level, optname, optval, optlen)
	if result < 0 {
		return _get_errno(result)
	}
	return ERROR_NONE
}


recvfrom :: proc(sd: Socket, data: []byte, flags: int, addr: ^SOCKADDR, addr_size: ^socklen_t) -> (u32, Errno) {
	result := unix.sys_recvfrom(int(sd), raw_data(data), len(data), flags, addr, uintptr(addr_size))
	if result < 0 {
		return 0, _get_errno(int(result))
	}
	return u32(result), ERROR_NONE
}

recv :: proc(sd: Socket, data: []byte, flags: int) -> (u32, Errno) {
	result := unix.sys_recvfrom(int(sd), raw_data(data), len(data), flags, nil, 0)
	if result < 0 {
		return 0, _get_errno(int(result))
	}
	return u32(result), ERROR_NONE
}


sendto :: proc(sd: Socket, data: []u8, flags: int, addr: ^SOCKADDR, addrlen: socklen_t) -> (u32, Errno) {
	result := unix.sys_sendto(int(sd), raw_data(data), len(data), flags, addr, addrlen)
	if result < 0 {
		return 0, _get_errno(int(result))
	}
	return u32(result), ERROR_NONE
}

send :: proc(sd: Socket, data: []byte, flags: int) -> (u32, Errno) {
	result := unix.sys_sendto(int(sd), raw_data(data), len(data), 0, nil, 0)
	if result < 0 {
		return 0, _get_errno(int(result))
	}
	return u32(result), ERROR_NONE
}

shutdown :: proc(sd: Socket, how: int) -> (Errno) {
	result := unix.sys_shutdown(int(sd), how)
	if result < 0 {
		return _get_errno(result)
	}
	return ERROR_NONE
}

fcntl :: proc(fd: int, cmd: int, arg: int) -> (int, Errno) {
	result := unix.sys_fcntl(fd, cmd, arg)
	if result < 0 {
		return 0, _get_errno(result)
	}
	return result, ERROR_NONE
}

poll :: proc(fds: []pollfd, timeout: int) -> (int, Errno) {
	result := unix.sys_poll(raw_data(fds), uint(len(fds)), timeout)
	if result < 0 {
		return 0, _get_errno(result)
	}
	return result, ERROR_NONE
}

ppoll :: proc(fds: []pollfd, timeout: ^unix.timespec, sigmask: ^sigset_t) -> (int, Errno) {
	result := unix.sys_ppoll(raw_data(fds), uint(len(fds)), timeout, sigmask, size_of(sigset_t))
	if result < 0 {
		return 0, _get_errno(result)
	}
	return result, ERROR_NONE
}
