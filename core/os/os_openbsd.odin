package os

foreign import libc "system:c"

import "core:runtime"
import "core:strings"
import "core:c"
import "core:intrinsics"

Socket    :: distinct int
Handle    :: distinct i32
Pid       :: distinct i32
File_Time :: distinct u64
Errno     :: distinct i32

socklen_t :: c.int

INVALID_HANDLE :: ~Handle(0)

AF_UNSPEC:    int : 0
AF_UNIX:      int : 1
AF_LOCAL:     int : AF_UNIX
AF_INET:      int : 2
AF_INET6:     int : 24
AF_BLUETOOTH: int : 32

SOCK_STREAM:    int : 1
SOCK_DGRAM:     int : 2
SOCK_RAW:       int : 3
SOCK_RDM:       int : 4
SOCK_SEQPACKET: int : 5

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


SOL_SOCKET:       int : 1
SO_DEBUG	: int : 0x0001 /* turn on debugging info recording */
SO_ACCEPTCONN	: int : 0x0002 /* socket has had listen() */
SO_REUSEADDR	: int : 0x0004 /* allow local address reuse */
SO_KEEPALIVE	: int : 0x0008 /* keep connections alive */
SO_DONTROUTE	: int : 0x0010 /* just use interface addresses */
SO_BROADCAST	: int : 0x0020 /* permit sending of broadcast msgs */
SO_USELOOPBACK	: int : 0x0040 /* bypass hardware when possible */
SO_LINGER	: int : 0x0080 /* linger on close if data present */
SO_OOBINLINE	: int : 0x0100 /* leave received OOB data in line */
SO_REUSEPORT	: int : 0x0200 /* allow local address & port reuse */
SO_TIMESTAMP	: int : 0x0800 /* timestamp received dgram traffic */
SO_BINDANY	: int : 0x1000 /* allow bind to any address */
SO_ZEROIZE	: int : 0x2000 /* zero out all mbufs sent over socket */

SO_SNDBUF	: int : 0x1001 /* send buffer size */
SO_RCVBUF	: int : 0x1002 /* receive buffer size */
SO_SNDLOWAT	: int : 0x1003 /* send low-water mark */
SO_RCVLOWAT	: int : 0x1004 /* receive low-water mark */
SO_SNDTIMEO	: int : 0x1005 /* send timeout */
SO_RCVTIMEO	: int : 0x1006 /* receive timeout */
SO_ERROR	: int : 0x1007 /* get error status and clear */
SO_TYPE		: int : 0x1008 /* get socket type */
SO_NETPROC	: int : 0x1020 /* multiplex; network processing */
SO_RTABLE	: int : 0x1021 /* routing table to be used */
SO_PEERCRED	: int : 0x1022 /* get connect-time credentials */
SO_SPLICE	: int : 0x1023 /* splice data to other socket */
SO_DOMAIN	: int : 0x1024 /* get socket domain */
SO_PROTOCOL	: int : 0x1025 /* get socket protocol */

TCP_NODELAY: int : 1
TCP_CORK:    int : 3

MSG_PEEK  : int : 0x02
MSG_TRUNC : int : 0x20

ERROR_NONE:	Errno: 0

EPERM:		Errno: 1
ENOENT:		Errno: 2
ESRCH:		Errno: 3
EINTR:		Errno: 4
EIO:		Errno: 5
ENXIO:		Errno: 6
E2BIG:		Errno: 7
ENOEXEC:	Errno: 8
EBADF:		Errno: 9
ECHILD:		Errno: 10
EDEADLK:	Errno: 11
ENOMEM:		Errno: 12
EACCES:		Errno: 13
EFAULT:		Errno: 14
ENOTBLK:	Errno: 15
EBUSY:		Errno: 16
EEXIST:		Errno: 17
EXDEV:		Errno: 18
ENODEV:		Errno: 19
ENOTDIR:	Errno: 20
EISDIR:		Errno: 21
EINVAL:		Errno: 22
ENFILE:		Errno: 23
EMFILE:		Errno: 24
ENOTTY:		Errno: 25
ETXTBSY:	Errno: 26
EFBIG:		Errno: 27
ENOSPC:		Errno: 28
ESPIPE:		Errno: 29
EROFS:		Errno: 30
EMLINK:		Errno: 31
EPIPE:		Errno: 32
EDOM:		Errno: 33
ERANGE:		Errno: 34
EAGAIN:		Errno: 35
EWOULDBLOCK:	Errno: EAGAIN
EINPROGRESS:	Errno: 36
EALREADY:	Errno: 37
ENOTSOCK:	Errno: 38
EDESTADDRREQ:	Errno: 39
EMSGSIZE:	Errno: 40
EPROTOTYPE:	Errno: 41
ENOPROTOOPT:	Errno: 42
EPROTONOSUPPORT: Errno: 43
ESOCKTNOSUPPORT: Errno: 44
EOPNOTSUPP:	Errno: 45
EPFNOSUPPORT:	Errno: 46
EAFNOSUPPORT:	Errno: 47
EADDRINUSE:	Errno: 48
EADDRNOTAVAIL:	Errno: 49
ENETDOWN:	Errno: 50
ENETUNREACH:	Errno: 51
ENETRESET:	Errno: 52
ECONNABORTED:	Errno: 53
ECONNRESET:	Errno: 54
ENOBUFS:	Errno: 55
EISCONN:	Errno: 56
ENOTCONN:	Errno: 57
ESHUTDOWN:	Errno: 58
ETOOMANYREFS:	Errno: 59
ETIMEDOUT:	Errno: 60
ECONNREFUSED:	Errno: 61
ELOOP:		Errno: 62
ENAMETOOLONG:	Errno: 63
EHOSTDOWN:	Errno: 64
EHOSTUNREACH:	Errno: 65
ENOTEMPTY:	Errno: 66
EPROCLIM:	Errno: 67
EUSERS:		Errno: 68
EDQUOT:		Errno: 69
ESTALE:		Errno: 70
EREMOTE:	Errno: 71
EBADRPC:	Errno: 72
ERPCMISMATCH:	Errno: 73
EPROGUNAVAIL:	Errno: 74
EPROGMISMATCH:	Errno: 75
EPROCUNAVAIL:	Errno: 76
ENOLCK:		Errno: 77
ENOSYS:		Errno: 78
EFTYPE:		Errno: 79
EAUTH:		Errno: 80
ENEEDAUTH:	Errno: 81
EIPSEC:		Errno: 82
ENOATTR:	Errno: 83
EILSEQ:		Errno: 84
ENOMEDIUM:	Errno: 85
EMEDIUMTYPE:	Errno: 86
EOVERFLOW:	Errno: 87
ECANCELED:	Errno: 88
EIDRM:		Errno: 89
ENOMSG:		Errno: 90
ENOTSUP:	Errno: 91
EBADMSG:	Errno: 92
ENOTRECOVERABLE: Errno: 93
EOWNERDEAD:	Errno: 94
EPROTO:		Errno: 95

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
O_CLOEXEC  :: 0x10000

SEEK_SET :: 0
SEEK_CUR :: 1
SEEK_END :: 2

RTLD_LAZY     :: 0x001
RTLD_NOW      :: 0x002
RTLD_LOCAL    :: 0x000
RTLD_GLOBAL   :: 0x100
RTLD_TRACE    :: 0x200
RTLD_NODELETE :: 0x400

ADDRESS_FAMILY :: u8
SOCKADDR :: struct #packed {
	sa_len:    u8,
	sa_family: ADDRESS_FAMILY,
	sa_data:   [14]c.char,
}

SOCKADDR_STORAGE_LH :: struct #packed {
	sa_len:     u8,
	ss_family:  ADDRESS_FAMILY,
	__ss_pad1:  [6]c.char,
	__ss_align: i64,
	__ss_pad2:  [240]c.char,
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

MAX_PATH :: 1024

// "Argv" arguments converted to Odin strings
args := _alloc_command_line_arguments()

pid_t     :: i32
time_t    :: i64
mode_t    :: u32
dev_t     :: i32
ino_t     :: u64
nlink_t   :: u32
uid_t     :: u32
gid_t     :: u32
off_t     :: i64
blkcnt_t  :: u64
blksize_t :: i32

Unix_File_Time :: struct {
	seconds:     time_t,
	nanoseconds: c.long,
}

Timeval :: struct {
	seconds: i64,
	nanoseconds: int,
}

Linger :: struct {
	onoff: int,
	linger: int,
}

OS_Stat :: struct {
	mode: mode_t,			// inode protection mode
	device_id: dev_t,		// inode's device
	serial: ino_t,			// inode's number
	nlink: nlink_t,			// number of hard links
	uid: uid_t,			// user ID of the file's owner
	gid: gid_t,			// group ID of the file's group
	rdev: dev_t,			// device type

	last_access: Unix_File_Time,	// time of last access
	modified: Unix_File_Time,	// time of last data modification
	status_change: Unix_File_Time,	// time of last file status change

	size: off_t,			// file size, in bytes
	blocks: blkcnt_t,		// blocks allocated for file
	block_size:	blksize_t,	// optimal blocksize for I/O

	flags:		u32,		// user defined flags for file
	gen:		u32,		// file generation number
	birthtime:	Unix_File_Time,	// time of file creation
}

MAXNAMLEN :: 255

// NOTE(laleksic, 2021-01-21): Comment and rename these to match OS_Stat above
Dirent :: struct {
	ino:      ino_t,	// file number of entry
	off:      off_t,	// offset after this entry
	reclen:   u16,		// length of this record
	type:     u8,		// file type
	namlen:   u8,		// length of string in name
	_padding: [4]u8,
	name:     [MAXNAMLEN + 1]byte, // name
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
S_ISVTX  :: 0o001000 // Save swapped text even after use

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
S_ISTXT :: 0o1000 // Sticky bit

S_ISLNK  :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFLNK  }
S_ISREG  :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFREG  }
S_ISDIR  :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFDIR  }
S_ISCHR  :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFCHR  }
S_ISBLK  :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFBLK  }
S_ISFIFO :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFIFO  }
S_ISSOCK :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFSOCK }

F_OK :: 0x00 // Test for file existance
X_OK :: 0x01 // Test for execute permission
W_OK :: 0x02 // Test for write permission
R_OK :: 0x04 // Test for read permission

AT_FDCWD            :: -100
AT_EACCESS          :: 0x01
AT_SYMLINK_NOFOLLOW :: 0x02
AT_SYMLINK_FOLLOW   :: 0x04
AT_REMOVEDIR        :: 0x08

@(default_calling_convention="c")
foreign libc {
	@(link_name="__errno")	__errno		:: proc() -> ^int ---

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

	@(link_name="socket")   _unix_socket    :: proc(domain: int, type: int, protocol: int) -> int ---
	@(link_name="connect")  _unix_connect   :: proc(sd: int, addr: rawptr, len: socklen_t) -> int ---
	@(link_name="accept")   _unix_accept    :: proc(sd: int, addr: rawptr, len: rawptr) -> int ---
	@(link_name="listen")   _unix_listen    :: proc(sd: int, backlog: int) -> int ---
	@(link_name="bind")     _unix_bind      :: proc(sd: int, addr: rawptr, len: socklen_t) -> int ---
	@(link_name="setsockopt") _unix_setsockopt :: proc(sd: int, level: int, optname: int, optval: rawptr, optlen: socklen_t) -> int ---
	@(link_name="recvfrom")   _unix_recvfrom   :: proc(sd: int, buf: rawptr, len: uint, flags: int, addr: rawptr, alen: uintptr) -> i64 ---
	@(link_name="sendto")     _unix_sendto     :: proc(sd: int, buf: rawptr, len: uint, flags: int, addr: rawptr, alen: socklen_t) -> i64 ---
	@(link_name="shutdown")   _unix_shutdown   :: proc(sd: int, how: int) -> int ---
}

is_path_separator :: proc(r: rune) -> bool {
	return r == '/'
}

get_last_error :: proc() -> int {
	return __errno()^
}

fork :: proc() -> (Pid, Errno) {
	pid := _unix_fork()
	if pid == -1 {
		return Pid(-1), Errno(Errno(get_last_error()))
	}
	return Pid(pid), ERROR_NONE
}

open :: proc(path: string, flags: int = O_RDONLY, mode: int = 0) -> (Handle, Errno) {
	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	handle := _unix_open(cstr, c.int(flags), c.int(mode))
	if handle == -1 {
		return INVALID_HANDLE, Errno(Errno(get_last_error()))
	}
	return handle, ERROR_NONE
}

close :: proc(fd: Handle) -> Errno {
	result := _unix_close(fd)
	if result == -1 {
		return Errno(Errno(get_last_error()))
	}
	return ERROR_NONE
}

read :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	bytes_read := _unix_read(fd, &data[0], c.size_t(len(data)))
	if bytes_read == -1 {
		return -1, Errno(Errno(get_last_error()))
	}
	return int(bytes_read), ERROR_NONE
}

write :: proc(fd: Handle, data: []byte) -> (int, Errno) {
	if len(data) == 0 {
		return 0, ERROR_NONE
	}
	bytes_written := _unix_write(fd, &data[0], c.size_t(len(data)))
	if bytes_written == -1 {
		return -1, Errno(Errno(get_last_error()))
	}
	return int(bytes_written), ERROR_NONE
}

seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Errno) {
	res := _unix_seek(fd, offset, c.int(whence))
	if res == -1 {
		return -1, Errno(Errno(get_last_error()))
	}
	return res, ERROR_NONE
}

file_size :: proc(fd: Handle) -> (i64, Errno) {
	s, err := _fstat(fd)
	if err != ERROR_NONE {
		return -1, err
	}
	return s.size, ERROR_NONE
}

rename :: proc(old_path, new_path: string) -> Errno {
	old_path_cstr := strings.clone_to_cstring(old_path, context.temp_allocator)
	new_path_cstr := strings.clone_to_cstring(new_path, context.temp_allocator)
	res := _unix_rename(old_path_cstr, new_path_cstr)
	if res == -1 {
		return Errno(Errno(get_last_error()))
	}
	return ERROR_NONE
}

remove :: proc(path: string) -> Errno {
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	res := _unix_unlink(path_cstr)
	if res == -1 {
		return Errno(Errno(get_last_error()))
	}
	return ERROR_NONE
}

make_directory :: proc(path: string, mode: mode_t = 0o775) -> Errno {
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	res := _unix_mkdir(path_cstr, mode)
	if res == -1 {
		return Errno(Errno(get_last_error()))
	}
	return ERROR_NONE
}

remove_directory :: proc(path: string) -> Errno {
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	res := _unix_rmdir(path_cstr)
	if res == -1 {
		return Errno(Errno(get_last_error()))
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

stdin:  Handle = 0
stdout: Handle = 1
stderr: Handle = 2


socket :: proc(domain: int, type: int, protocol: int) -> (Socket, Errno) {
	result := _unix_socket(domain, type, protocol)
	if result < 0 {
		return 0, Errno(get_last_error())
	}
	return Socket(result), ERROR_NONE
}

bind :: proc(sd: Socket, addr: ^SOCKADDR, len: socklen_t) -> (Errno) {
	result := _unix_bind(int(sd), addr, len)
	if result < 0 {
		return Errno(get_last_error())
	}
	return ERROR_NONE
}


connect :: proc(sd: Socket, addr: ^SOCKADDR, len: socklen_t) -> (Errno) {
	result := _unix_connect(int(sd), addr, len)
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


recvfrom :: proc(sd: Socket, data: []byte, flags: int, addr: ^SOCKADDR, addr_size: ^socklen_t) -> (u32, Errno) {
	result := _unix_recvfrom(int(sd), raw_data(data), len(data), flags, addr, uintptr(addr_size))
	if result < 0 {
		return 0, Errno(get_last_error())
	}
	return u32(result), ERROR_NONE
}

recv :: proc(sd: Socket, data: []byte, flags: int) -> (u32, Errno) {
	result := _unix_recvfrom(int(sd), raw_data(data), len(data), flags, nil, 0)
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
	result := _unix_sendto(int(sd), raw_data(data), len(data), 0, nil, 0)
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
	cstr := strings.clone_to_cstring(path, context.temp_allocator)

	// deliberately uninitialized
	s: OS_Stat = ---
	res := _unix_stat(cstr, &s)
	if res == -1 {
		return s, Errno(Errno(get_last_error()))
	}
	return s, ERROR_NONE
}

@private
_lstat :: proc(path: string) -> (OS_Stat, Errno) {
	cstr := strings.clone_to_cstring(path, context.temp_allocator)

	// deliberately uninitialized
	s: OS_Stat = ---
	res := _unix_lstat(cstr, &s)
	if res == -1 {
		return s, Errno(Errno(get_last_error()))
	}
	return s, ERROR_NONE
}

@private
_fstat :: proc(fd: Handle) -> (OS_Stat, Errno) {
	// deliberately uninitialized
	s: OS_Stat = ---
	res := _unix_fstat(fd, &s)
	if res == -1 {
		return s, Errno(Errno(get_last_error()))
	}
	return s, ERROR_NONE
}

@private
_fdopendir :: proc(fd: Handle) -> (Dir, Errno) {
	dirp := _unix_fdopendir(fd)
	if dirp == cast(Dir)nil {
		return nil, Errno(Errno(get_last_error()))
	}
	return dirp, ERROR_NONE
}

@private
_closedir :: proc(dirp: Dir) -> Errno {
	rc := _unix_closedir(dirp)
	if rc != 0 {
		return Errno(Errno(get_last_error()))
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
		err = Errno(Errno(get_last_error()))
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
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)

	bufsz : uint = MAX_PATH
	buf := make([]byte, MAX_PATH)
	for {
		rc := _unix_readlink(path_cstr, &(buf[0]), bufsz)
		if rc == -1 {
			delete(buf)
			return "", Errno(Errno(get_last_error()))
		} else if rc == int(bufsz) {
			bufsz += MAX_PATH
			delete(buf)
			buf = make([]byte, bufsz)
		} else {
			return strings.string_from_ptr(&buf[0], rc), ERROR_NONE
		}	
	}
	unreachable()
}

// XXX OpenBSD
absolute_path_from_handle :: proc(fd: Handle) -> (string, Errno) {
	return "", Errno(ENOSYS)
}

absolute_path_from_relative :: proc(rel: string) -> (path: string, err: Errno) {
	rel := rel
	if rel == "" {
		rel = "."
	}

	rel_cstr := strings.clone_to_cstring(rel, context.temp_allocator)

	path_ptr := _unix_realpath(rel_cstr, nil)
	if path_ptr == nil {
		return "", Errno(Errno(get_last_error()))
	}
	defer _unix_free(path_ptr)

	path_cstr := transmute(cstring)path_ptr
	path = strings.clone( string(path_cstr) )

	return path, ERROR_NONE
}

access :: proc(path: string, mask: int) -> (bool, Errno) {
	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	res := _unix_access(cstr, c.int(mask))
	if res == -1 {
		return false, Errno(Errno(get_last_error()))
	}
	return true, ERROR_NONE
}

heap_alloc :: proc(size: int) -> rawptr {
	assert(size >= 0)
	return _unix_calloc(1, c.size_t(size))
}

heap_resize :: proc(ptr: rawptr, new_size: int) -> rawptr {
	// NOTE: _unix_realloc doesn't guarantee new memory will be zeroed on
	// POSIX platforms. Ensure your caller takes this into account.
	return _unix_realloc(ptr, c.size_t(new_size))
}

heap_free :: proc(ptr: rawptr) {
	_unix_free(ptr)
}

getenv :: proc(name: string) -> (string, bool) {
	path_str := strings.clone_to_cstring(name, context.temp_allocator)
	cstr := _unix_getenv(path_str)
	if cstr == nil {
		return "", false
	}
	return string(cstr), true
}

get_current_directory :: proc() -> string {
	buf := make([dynamic]u8, MAX_PATH)
	for {
		cwd := _unix_getcwd(cstring(raw_data(buf)), c.size_t(len(buf)))
		if cwd != nil {
			return string(cwd)
		}
		if Errno(Errno(get_last_error())) != ERANGE {
			return ""
		}
		resize(&buf, len(buf) + MAX_PATH)
	}
	unreachable()
}

set_current_directory :: proc(path: string) -> (err: Errno) {
	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	res := _unix_chdir(cstr)
	if res == -1 {
		return Errno(Errno(get_last_error()))
	}
	return ERROR_NONE
}

exit :: proc "contextless" (code: int) -> ! {
	_unix_exit(c.int(code))
}

current_thread_id :: proc "contextless" () -> int {
	return _unix_getthrid()
}

dlopen :: proc(filename: string, flags: int) -> rawptr {
	cstr := strings.clone_to_cstring(filename, context.temp_allocator)
	handle := _unix_dlopen(cstr, c.int(flags))
	return handle
}
dlsym :: proc(handle: rawptr, symbol: string) -> rawptr {
	assert(handle != nil)
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


_alloc_command_line_arguments :: proc() -> []string {
	res := make([]string, len(runtime.args__))
	for arg, i in runtime.args__ {
		res[i] = string(arg)
	}
	return res
}