//+build wasm32
package sys_wasi

foreign import wasi "wasi_snapshot_preview1"

DIRCOOKIE_START :: u64(0)
size_t :: uint

filesize_t :: distinct u64
timestamp_t :: distinct u64

clockid_t :: distinct u32
CLOCK_REALTIME           :: clockid_t(0)
CLOCK_MONOTONIC          :: clockid_t(1)
CLOCK_PROCESS_CPUTIME_ID :: clockid_t(2)
CLOCK_THREAD_CPUTIME_ID  :: clockid_t(3)

errno_t :: enum u16 {
	NONE = 0,
	// No error occurred. System call completed successfully.
	SUCCESS = 0,
	// Argument list too long.
	TOOBIG = 1,
	// Permission denied.
	ACCESS = 2,
	// Address in use.
	ADDRINUSE = 3,
	// Address not available.
	ADDRNOTAVAIL = 4,
	// Address family not supported.
	AFNOSUPPORT = 5,
	// Resource unavailable, or operation would block.
	AGAIN = 6,
	// Connection already in progress.
	ALREADY = 7,
	// Bad file descriptor.
	BADF = 8,
	// Bad message.
	BADMSG = 9,
	// Device or resource busy.
	BUSY = 10,
	// Operation canceled.
	CANCELED = 11,
	// No child processes.
	CHILD = 12,
	// Connection aborted.
	CONNABORTED = 13,
	// Connection refused.
	CONNREFUSED = 14,
	// Connection reset.
	CONNRESET = 15,
	// Resource deadlock would occur.
	DEADLK = 16,
	// Destination address required.
	DESTADDRREQ = 17,
	// Mathematics argument out of domain of function.
	DOM = 18,
	// Reserved.
	DQUOT = 19,
	// File exists.
	EXIST = 20,
	// Bad address.
	FAULT = 21,
	// File too large.
	FBIG = 22,
	// Host is unreachable.
	HOSTUNREACH = 23,
	// Identifier removed.
	IDRM = 24,
	// Illegal byte sequence.
	ILSEQ = 25,
	// Operation in progress.
	INPROGRESS = 26,
	// Interrupted function.
	INTR = 27,
	// Invalid argument.
	INVAL = 28,
	// I/O error.
	IO = 29,
	// Socket is connected.
	ISCONN = 30,
	// Is a directory.
	ISDIR = 31,
	// Too many levels of symbolic links.
	LOOP = 32,
	// File descriptor value too large.
	MFILE = 33,
	// Too many links.
	MLINK = 34,
	// Message too large.
	MSGSIZE = 35,
	// Reserved.
	MULTIHOP = 36,
	// Filename too long.
	NAMETOOLONG = 37,
	// Network is down.
	NETDOWN = 38,
	// Connection aborted by network.
	NETRESET = 39,
	// Network unreachable.
	NETUNREACH = 40,
	// Too many files open in system.
	NFILE = 41,
	// No buffer space available.
	NOBUFS = 42,
	// No such device.
	NODEV = 43,
	// No such file or directory.
	NOENT = 44,
	// Executable file format error.
	NOEXEC = 45,
	// No locks available.
	NOLCK = 46,
	// Reserved.
	NOLINK = 47,
	// Not enough space.
	NOMEM = 48,
	// No message of the desired type.
	NOMSG = 49,
	// Protocol not available.
	NOPROTOOPT = 50,
	// No space left on device.
	NOSPC = 51,
	// Function not supported.
	NOSYS = 52,
	// The socket is not connected.
	NOTCONN = 53,
	// Not a directory or a symbolic link to a directory.
	NOTDIR = 54,
	// Directory not empty.
	NOTEMPTY = 55,
	// State not recoverable.
	NOTRECOVERABLE = 56,
	// Not a socket.
	NOTSOCK = 57,
	// Not supported, or operation not supported on socket.
	NOTSUP = 58,
	// Inappropriate I/O control operation.
	NOTTY = 59,
	// No such device or address.
	NXIO = 60,
	// Value too large to be stored in data type.
	OVERFLOW = 61,
	// Previous owner died.
	OWNERDEAD = 62,
	// Operation not permitted.
	PERM = 63,
	// Broken pipe.
	PIPE = 64,
	// Protocol error.
	PROTO = 65,
	// Protocol not supported.
	PROTONOSUPPORT = 66,
	// Protocol wrong type for socket.
	PROTOTYPE = 67,
	// Result too large.
	RANGE = 68,
	// Read-only file system.
	ROFS = 69,
	// Invalid seek.
	SPIPE = 70,
	// No such process.
	SRCH = 71,
	// Reserved.
	STALE = 72,
	// Connection timed out.
	TIMEDOUT = 73,
	// Text file busy.
	TXTBSY = 74,
	// Cross-device link.
	XDEV = 75,
	// Extension: Capabilities insufficient.
	NOTCAPABLE = 76,
}


rights_t :: distinct bit_set[rights_flag_t; u64]
rights_flag_t :: enum u64 {
	/**
	 * The right to invoke `fd_datasync`.
	 * If `path_open` is set, includes the right to invoke
	 * `path_open` with `fdflags::dsync`.
	 */
	FD_DATASYNC = 0,

	/**
	 * The right to invoke `fd_read` and `sock_recv`.
	 * If `rights::fd_seek` is set, includes the right to invoke `fd_pread`.
	 */
	FD_READ = 1,

	/**
	 * The right to invoke `fd_seek`. This flag implies `rights::fd_tell`.
	 */
	FD_SEEK = 2,

	/**
	 * The right to invoke `fd_fdstat_set_flags`.
	 */
	FD_FDSTAT_SET_FLAGS = 3,

	/**
	 * The right to invoke `fd_sync`.
	 * If `path_open` is set, includes the right to invoke
	 * `path_open` with `fdflags::rsync` and `fdflags::dsync`.
	 */
	FD_SYNC = 4,

	/**
	 * The right to invoke `fd_seek` in such a way that the file offset
	 * remains unaltered (i.e., `whence::cur` with offset zero), or to
	 * invoke `fd_tell`.
	 */
	FD_TELL = 5,

	/**
	 * The right to invoke `fd_write` and `sock_send`.
	 * If `rights::fd_seek` is set, includes the right to invoke `fd_pwrite`.
	 */
	FD_WRITE = 6,

	/**
	 * The right to invoke `fd_advise`.
	 */
	FD_ADVISE = 7,

	/**
	 * The right to invoke `fd_allocate`.
	 */
	FD_ALLOCATE = 8,

	/**
	 * The right to invoke `path_create_directory`.
	 */
	PATH_CREATE_DIRECTORY = 9,

	/**
	 * If `path_open` is set, the right to invoke `path_open` with `oflags::creat`.
	 */
	PATH_CREATE_FILE = 10,

	/**
	 * The right to invoke `path_link` with the file descriptor as the
	 * source directory.
	 */
	PATH_LINK_SOURCE = 11,

	/**
	 * The right to invoke `path_link` with the file descriptor as the
	 * target directory.
	 */
	PATH_LINK_TARGET = 12,

	/**
	 * The right to invoke `path_open`.
	 */
	PATH_OPEN = 13,

	/**
	 * The right to invoke `fd_readdir`.
	 */
	FD_READDIR = 14,

	/**
	 * The right to invoke `path_readlink`.
	 */
	PATH_READLINK = 15,

	/**
	 * The right to invoke `path_rename` with the file descriptor as the source directory.
	 */
	PATH_RENAME_SOURCE = 16,

	/**
	 * The right to invoke `path_rename` with the file descriptor as the target directory.
	 */
	PATH_RENAME_TARGET = 17,

	/**
	 * The right to invoke `path_filestat_get`.
	 */
	PATH_FILESTAT_GET = 18,

	/**
	 * The right to change a file's size (there is no `path_filestat_set_size`).
	 * If `path_open` is set, includes the right to invoke `path_open` with `oflags::trunc`.
	 */
	PATH_FILESTAT_SET_SIZE = 19,

	/**
	 * The right to invoke `path_filestat_set_times`.
	 */
	PATH_FILESTAT_SET_TIMES = 20,

	/**
	 * The right to invoke `fd_filestat_get`.
	 */
	FD_FILESTAT_GET = 21,

	/**
	 * The right to invoke `fd_filestat_set_size`.
	 */
	FD_FILESTAT_SET_SIZE = 22,

	/**
	 * The right to invoke `fd_filestat_set_times`.
	 */
	FD_FILESTAT_SET_TIMES = 23,

	/**
	 * The right to invoke `path_symlink`.
	 */
	PATH_SYMLINK = 24,

	/**
	 * The right to invoke `path_remove_directory`.
	 */
	PATH_REMOVE_DIRECTORY = 25,

	/**
	 * The right to invoke `path_unlink_file`.
	 */
	PATH_UNLINK_FILE = 26,

	/**
	 * If `rights::fd_read` is set, includes the right to invoke `poll_oneoff` to subscribe to `eventtype::fd_read`.
	 * If `rights::fd_write` is set, includes the right to invoke `poll_oneoff` to subscribe to `eventtype::fd_write`.
	 */
	POLL_FD_READWRITE = 27,

	/**
	 * The right to invoke `sock_shutdown`.
	 */
	SOCK_SHUTDOWN = 28,
}

fd_t :: distinct i32

// iovec_t :: struct {
// 	buf: [^]u8,
// 	buf_len: size_t,
// }
// ciovec_t :: struct {
// 	buf: [^]u8,
// 	buf_len: size_t,
// }
iovec_t :: []byte
ciovec_t :: []byte


filedelta_t :: distinct i64

whence_t :: enum u8 {
	SET = 0,
	CUR = 1,
	END = 2,
}

dircookie_t :: distinct u64
dirnamlen_t :: distinct u32
inode_t :: distinct u64

filetype_t :: enum u8 {
	/**
	 * The type of the file descriptor or file is unknown or is different from any of the other types specified.
	 */
	UNKNOWN = 0,

	/**
	 * The file descriptor or file refers to a block device inode.
	 */
	BLOCK_DEVICE = 1,

	/**
	 * The file descriptor or file refers to a character device inode.
	 */
	CHARACTER_DEVICE = 2,

	/**
	 * The file descriptor or file refers to a directory inode.
	 */
	DIRECTORY = 3,

	/**
	 * The file descriptor or file refers to a regular file inode.
	 */
	REGULAR_FILE = 4,

	/**
	 * The file descriptor or file refers to a datagram socket.
	 */
	SOCKET_DGRAM = 5,

	/**
	 * The file descriptor or file refers to a byte-stream socket.
	 */
	SOCKET_STREAM = 6,

	/**
	 * The file refers to a symbolic link inode.
	 */
	SYMBOLIC_LINK = 7,
}

dirent_t :: struct {
	d_next:   dircookie_t,
	d_ino:    inode_t,
	d_namlen: dirnamlen_t,
	d_type:   filetype_t,
}

advice_t :: enum u8 {
	/**
	 * The application has no advice to give on its behavior with respect to the specified data.
	 */
	NORMAL = 0,

	/**
	 * The application expects to access the specified data sequentially from lower offsets to higher offsets.
	 */
	SEQUENTIAL = 1,

	/**
	 * The application expects to access the specified data in a random order.
	 */
	RANDOM = 2,

	/**
	 * The application expects to access the specified data in the near future.
	 */
	WILLNEED = 3,

	/**
	 * The application expects that it will not access the specified data in the near future.
	 */
	DONTNEED = 4,

	/**
	 * The application expects to access the specified data once and then not reuse it thereafter.
	 */
	NOREUSE = 5,
}

fdflags_t :: distinct bit_set[fdflag_t; u16]
fdflag_t :: enum u16 {
	/**
	 * Append mode: Data written to the file is always appended to the file's end.
	 */
	APPEND = 0,

	/**
	 * Write according to synchronized I/O data integrity completion. Only the data stored in the file is synchronized.
	 */
	DSYNC = 1,

	/**
	 * Non-blocking mode.
	 */
	NONBLOCK = 2,

	/**
	 * Synchronized read I/O operations.
	 */
	RSYNC = 3,

	/**
	 * Write according to synchronized I/O file integrity completion. In
	 * addition to synchronizing the data stored in the file, the implementation
	 * may also synchronously update the file's metadata.
	 */
	SYNC = 4,
}

fdstat_t :: struct {
	/**
	 * File type.
	 */
	fs_filetype: filetype_t,

	/**
	 * File descriptor flags.
	 */
	fs_flags: fdflags_t,

	/**
	 * Rights that apply to this file descriptor.
	 */
	fs_rights_base: rights_t,

	/**
	 * Maximum set of rights that may be installed on new file descriptors that
	 * are created through this file descriptor, e.g., through `path_open`.
	 */
	fs_rights_inheriting: rights_t,
}

device_t :: distinct u64


fstflags_t :: distinct bit_set[fstflag_t; u16]
fstflag_t :: enum u16 {
	/**
	 * Adjust the last data access timestamp to the value stored in `filestat::atim`.
	 */
	ATIM = 0,

	/**
	 * Adjust the last data access timestamp to the time of clock `clockid::realtime`.
	 */
	ATIM_NOW = 1,

	/**
	 * Adjust the last data modification timestamp to the value stored in `filestat::mtim`.
	 */
	MTIM = 2,

	/**
	 * Adjust the last data modification timestamp to the time of clock `clockid::realtime`.
	 */
	MTIM_NOW = 3,

}

lookupflags_t :: distinct bit_set[lookupflag_t; u32]
lookupflag_t :: enum u32 {
	/**
	 * As long as the resolved path corresponds to a symbolic link, it is expanded.
	 */
	SYMLINK_FOLLOW = 0,
}

oflags_t :: distinct bit_set[oflag_t; u16]
oflag_t :: enum u16 {
	/**
	 * Create file if it does not exist.
	 */
	CREATE = 0,

	/**
	 * Fail if not a directory.
	 */
	DIRECTORY = 1,

	/**
	 * Fail if file already exists.
	 */
	EXCL = 2,

	/**
	 * Truncate file to size 0.
	 */
	TRUNC = 3,
}

linkcount_t :: distinct u64

filestat_t :: struct {
	/**
	 * Device ID of device containing the file.
	 */
	dev: device_t,

	/**
	 * File serial number.
	 */
	ino: inode_t,

	/**
	 * File type.
	 */
	filetype: filetype_t,

	/**
	 * Number of hard links to the file.
	 */
	nlink: linkcount_t,

	/**
	 * For regular files, the file size in bytes. For symbolic links, the length in bytes of the pathname contained in the symbolic link.
	 */
	size: filesize_t,

	/**
	 * Last data access timestamp.
	 */
	atim: timestamp_t,

	/**
	 * Last data modification timestamp.
	 */
	mtim: timestamp_t,

	/**
	 * Last file status change timestamp.
	 */
	ctim: timestamp_t,
}

userdata_t :: distinct u64

eventtype_t :: enum u8 {
	/**
	 * The time value of clock `subscription_clock::id` has
	 * reached timestamp `subscription_clock::timeout`.
	 */
	CLOCK = 0,

	/**
	 * File descriptor `subscription_fd_readwrite::file_descriptor` has data
	 * available for reading. This event always triggers for regular files.
	 */
	FD_READ = 1,

	/**
	 * File descriptor `subscription_fd_readwrite::file_descriptor` has capacity
	 * available for writing. This event always triggers for regular files.
	 */
	FD_WRITE = 2,
}

eventrwflags_t :: distinct bit_set[eventrwflag_t; u16]
eventrwflag_t :: enum u16 {
	/**
	 * The peer of this socket has closed or disconnected.
	 */
	FD_READWRITE_HANGUP = 0,
}

event_fd_readwrite_t :: struct {
	/**
	 * The number of bytes available for reading or writing.
	 */
	nbytes: filesize_t,

	/**
	 * The state of the file descriptor.
	 */
	flags: eventrwflags_t,
}

event_t :: struct {
	/**
	 * User-provided value that got attached to `subscription::userdata`.
	 */
	userdata: userdata_t,

	/**
	 * If non-zero, an error that occurred while processing the subscription request.
	 */
	error: errno_t,

	/**
	 * The type of event that occured
	 */
	type: eventtype_t,

	/**
	 * The contents of the event, if it is an `eventtype::fd_read` or
	 * `eventtype::fd_write`. `eventtype::clock` events ignore this field.
	 */
	fd_readwrite: event_fd_readwrite_t,
}

subclockflags_t :: distinct bit_set[subclockflag_t; u16]
subclockflag_t :: enum u16 {
	/**
	 * If set, treat the timestamp provided in
	 * `subscription_clock::timeout` as an absolute timestamp of clock
	 * `subscription_clock::id`. If clear, treat the timestamp
	 * provided in `subscription_clock::timeout` relative to the
	 * current time value of clock `subscription_clock::id`.
	 */
	SUBSCRIPTION_CLOCK_ABSTIME = 0,

}

subscription_clock_t :: struct {
	/**
	 * The clock against which to compare the timestamp.
	 */
	id: clockid_t,

	/**
	 * The absolute or relative timestamp.
	 */
	timeout: timestamp_t,

	/**
	 * The amount of time that the implementation may wait additionally
	 * to coalesce with other events.
	 */
	precision: timestamp_t,

	/**
	 * Flags specifying whether the timeout is absolute or relative
	 */
	flags: subclockflags_t,
}

subscription_fd_readwrite_t :: struct {
	/**
	 * The file descriptor on which to wait for it to become ready for reading or writing.
	 */
	file_descriptor: fd_t,
}

subscription_t :: struct {
	/**
	 * User-provided value that is attached to the subscription in the
	 * implementation and returned through `event::userdata`.
	 */
	userdata: userdata_t,

	/**
	 * The type of the event to which to subscribe, and its contents
	 */
	using contents: struct {
		tag: eventtype_t,
		using u: struct #raw_union {
			clock: subscription_clock_t,
			fd_read: subscription_fd_readwrite_t,
			fd_write: subscription_fd_readwrite_t,
		},
	},
}

exitcode_t :: distinct u32

signal_t :: enum u8 {
	/**
	 * No signal. Note that POSIX has special semantics for `kill(pid, 0)`,
	 * so this value is reserved.
	 */
	NONE = 0,

	/**
	 * Hangup.
	 * Action: Terminates the process.
	 */
	HUP = 1,

	/**
	 * Terminate interrupt signal.
	 * Action: Terminates the process.
	 */
	INT = 2,

	/**
	 * Terminal quit signal.
	 * Action: Terminates the process.
	 */
	QUIT = 3,

	/**
	 * Illegal instruction.
	 * Action: Terminates the process.
	 */
	ILL = 4,

	/**
	 * Trace/breakpoint trap.
	 * Action: Terminates the process.
	 */
	TRAP = 5,

	/**
	 * Process abort signal.
	 * Action: Terminates the process.
	 */
	ABRT = 6,

	/**
	 * Access to an undefined portion of a memory object.
	 * Action: Terminates the process.
	 */
	BUS = 7,

	/**
	 * Erroneous arithmetic operation.
	 * Action: Terminates the process.
	 */
	FPE = 8,

	/**
	 * Kill.
	 * Action: Terminates the process.
	 */
	KILL = 9,

	/**
	 * User-defined signal 1.
	 * Action: Terminates the process.
	 */
	USR1 = 10,

	/**
	 * Invalid memory reference.
	 * Action: Terminates the process.
	 */
	SEGV = 11,

	/**
	 * User-defined signal 2.
	 * Action: Terminates the process.
	 */
	USR2 = 12,

	/**
	 * Write on a pipe with no one to read it.
	 * Action: Ignored.
	 */
	PIPE = 13,

	/**
	 * Alarm clock.
	 * Action: Terminates the process.
	 */
	ALRM = 14,

	/**
	 * Termination signal.
	 * Action: Terminates the process.
	 */
	TERM = 15,

	/**
	 * Child process terminated, stopped, or continued.
	 * Action: Ignored.
	 */
	CHLD = 16,

	/**
	 * Continue executing, if stopped.
	 * Action: Continues executing, if stopped.
	 */
	CONT = 17,

	/**
	 * Stop executing.
	 * Action: Stops executing.
	 */
	STOP = 18,

	/**
	 * Terminal stop signal.
	 * Action: Stops executing.
	 */
	TSTP = 19,

	/**
	 * Background process attempting read.
	 * Action: Stops executing.
	 */
	TTIN = 20,

	/**
	 * Background process attempting write.
	 * Action: Stops executing.
	 */
	TTOU = 21,

	/**
	 * High bandwidth data is available at a socket.
	 * Action: Ignored.
	 */
	URG = 22,

	/**
	 * CPU time limit exceeded.
	 * Action: Terminates the process.
	 */
	XCPU = 23,

	/**
	 * File size limit exceeded.
	 * Action: Terminates the process.
	 */
	XFSZ = 24,

	/**
	 * Virtual timer expired.
	 * Action: Terminates the process.
	 */
	VTALRM = 25,

	/**
	 * Profiling timer expired.
	 * Action: Terminates the process.
	 */
	PROF = 26,

	/**
	 * Window changed.
	 * Action: Ignored.
	 */
	WINCH = 27,

	/**
	 * I/O possible.
	 * Action: Terminates the process.
	 */
	POLL = 28,

	/**
	 * Power failure.
	 * Action: Terminates the process.
	 */
	PWR = 29,

	/**
	 * Bad system call.
	 * Action: Terminates the process.
	 */
	SYS = 30,
}


riflags_t :: distinct bit_set[riflag_t; u16]
riflag_t :: enum u16 {
	/**
	 * Returns the message without removing it from the socket's receive queue.
	 */
	RECV_PEEK = 0,

	/**
	 * On byte-stream sockets, block until the full amount of data can be returned.
	 */
	RECV_WAITALL = 1,
}

roflags_t :: distinct bit_set[roflag_t; u16]
roflag_t :: enum u16 {
	/**
	 * Returned by `sock_recv`: Message data has been truncated.
	 */
	RECV_DATA_TRUNCATED = 0,
}

siflags_t :: distinct bit_set[siflag_t; u16]
siflag_t :: enum u16 {
}


sdflags_t :: distinct bit_set[sdflag_t; u8]
sdflag_t :: enum u8 {
	/**
	 * Disables further receive operations.
	 */
	RD = 0,

	/**
	 * Disables further send operations.
	 */
	WR = 1,
}

preopentype_t :: enum u8 {
	DIR = 0,
}

prestat_dir_t :: struct {
	pr_name_len: size_t,
}

prestat_t :: struct {
	tag: preopentype_t,
	using u: struct {
		dir: prestat_dir_t,
	},
}

@(default_calling_convention="contextless")
foreign wasi {
	/**
	 * Read command-line argument data.
	 * The size of the array should match that returned by `args_sizes_get`
	 */
	args_get :: proc(
		argv: [^]cstring,
		argv_buf: [^]byte,
	) -> errno_t ---
	/**
	 * Read environment variable data.
	 * The sizes of the buffers should match that returned by `environ_sizes_get`.
	 */
	environ_get :: proc(
		environ: [^]cstring,
		environ_buf: [^]byte,
	) -> errno_t ---
	/**
	 * Provide file advisory information on a file descriptor.
	 * Note: This is similar to `posix_fadvise` in POSIX.
	 */
	fd_advise :: proc(
		fd: fd_t,
		/**
		 * The offset within the file to which the advisory applies.
		 */
		offset: filesize_t,
		/**
		 * The length of the region to which the advisory applies.
		 */
		len: filesize_t,
		/**
		 * The advice.
		 */
		advice: advice_t,
	) -> errno_t ---
	/**
	 * Force the allocation of space in a file.
	 * Note: This is similar to `posix_fallocate` in POSIX.
	 */
	fd_allocate :: proc(
		fd: fd_t,
		/**
		 * The offset at which to start the allocation.
		 */
		offset: filesize_t,
		/**
		 * The length of the area that is allocated.
		 */
		len: filesize_t,
	) -> errno_t ---
	/**
	 * Close a file descriptor.
	 * Note: This is similar to `close` in POSIX.
	 */
	fd_close :: proc(
		fd: fd_t,
	) -> errno_t ---
	/**
	 * Synchronize the data of a file to disk.
	 * Note: This is similar to `fdatasync` in POSIX.
	 */
	fd_datasync :: proc(
		fd: fd_t,
	) -> errno_t ---
	/**
	 * Adjust the flags associated with a file descriptor.
	 * Note: This is similar to `fcntl(fd, F_SETFL, flags)` in POSIX.
	 */
	fd_fdstat_set_flags :: proc(
		fd: fd_t,
		/**
		 * The desired values of the file descriptor flags.
		 */
		flags: fdflags_t,
	) -> errno_t ---
	/**
	 * Adjust the rights associated with a file descriptor.
	 * This can only be used to remove rights, and returns `errno::notcapable` if called in a way that would attempt to add rights
	 */
	fd_fdstat_set_rights :: proc(
		fd: fd_t,
		/**
		 * The desired rights of the file descriptor.
		 */
		fs_rights_base: rights_t,
		fs_rights_inheritin: rights_t,
	) -> errno_t ---
	/**
	 * Adjust the size of an open file. If this increases the file's size, the extra bytes are filled with zeros.
	 * Note: This is similar to `ftruncate` in POSIX.
	 */
	fd_filestat_set_size :: proc(
		fd: fd_t,
		/**
		 * The desired file size.
		 */
		size: filesize_t,
	) -> errno_t ---
	/**
	 * Adjust the timestamps of an open file or directory.
	 * Note: This is similar to `futimens` in POSIX.
	 */
	fd_filestat_set_times :: proc(
		fd: fd_t,
		/**
		 * The desired values of the data access timestamp.
		 */
		atim: timestamp_t,
		/**
		 * The desired values of the data modification timestamp.
		 */
		mtim: timestamp_t,
		/**
		 * A bitmask indicating which timestamps to adjust.
		 */
		fst_flags: fstflags_t,
	) -> errno_t ---
	/**
	 * Atomically replace a file descriptor by renumbering another file descriptor.
	 * Due to the strong focus on thread safety, this environment does not provide
	 * a mechanism to duplicate or renumber a file descriptor to an arbitrary
	 * number, like `dup2()`. This would be prone to race conditions, as an actual
	 * file descriptor with the same number could be allocated by a different
	 * thread at the same time.
	 * This function provides a way to atomically renumber file descriptors, which
	 * would disappear if `dup2()` were to be removed entirely.
	 */
	fd_renumber :: proc(
		fd: fd_t,
		/**
		 * The file descriptor to overwrite.
		 */
		to: fd_t,
	) -> errno_t ---
	/**
	 * Synchronize the data and metadata of a file to disk.
	 * Note: This is similar to `fsync` in POSIX.
	 */
	fd_sync :: proc(
		f: fd_t,
	) -> errno_t ---
	/**
	 * Terminate the process normally. An exit code of 0 indicates successful
	 * termination of the program. The meanings of other values is dependent on
	 * the environment.
	 */
	proc_exit :: proc(
		/**
		 * The exit code returned by the process.
		 */
		rval: exitcode_t,
	) -> ! ---
	/**
	 * Send a signal to the process of the calling thread.
	 * Note: This is similar to `raise` in POSIX.
	 */
	proc_raise :: proc(
		/**
		 * The signal condition to trigger.
		 */
		sig: signal_t,
	) -> errno_t ---
	/**
	 * Temporarily yield execution of the calling thread.
	 * Note: This is similar to `sched_yield` in POSIX.
	 */
	sched_yield :: proc() -> errno_t ---
	/**
	 * Shut down socket send and receive channels.
	 * Note: This is similar to `shutdown` in POSIX.
	 */
	sock_shutdown :: proc(
		fd: fd_t,
		/**
		 * Which channels on the socket to shut down.
		 */
		how: sdflags_t,
	) -> errno_t ---


	/**
	 * Return a description of the given preopened file descriptor.
	 */
	fd_prestat_dir_name :: proc(
		fd: fd_t,
		/**
		 * A buffer into which to write the preopened directory name.
		 */
		path: []byte,
	) -> errno_t ---
	/**
	 * Create a directory.
	 * Note: This is similar to `mkdirat` in POSIX.
	 */
	path_create_directory :: proc(
		fd: fd_t,
		/**
		 * The path at which to create the directory.
		 */
		path: string,
	) -> errno_t ---
	/**
	 * Adjust the timestamps of a file or directory.
	 * Note: This is similar to `utimensat` in POSIX.
	 */
	path_filestat_set_times :: proc(
		fd: fd_t,
		/**
		 * Flags determining the method of how the path is resolved.
		 */
		flags: lookupflags_t,
		/**
		 * The path of the file or directory to operate on.
		 */
		path: string,
		/**
		 * The desired values of the data access timestamp.
		 */
		atim: timestamp_t,
		/**
		 * The desired values of the data modification timestamp.
		 */
		mtim: timestamp_t,
		/**
		 * A bitmask indicating which timestamps to adjust.
		 */
		fst_flags: fstflags_t,
	) -> errno_t ---
	/**
	 * Remove a directory.
	 * Return `errno::notempty` if the directory is not empty.
	 * Note: This is similar to `unlinkat(fd, path, AT_REMOVEDIR)` in POSIX.
	 */
	path_remove_directory :: proc(
		fd: fd_t,
		/**
		 * The path to a directory to remove.
		 */
		path: string,
	) -> errno_t ---
	/**
	 * Create a hard link.
	 * Note: This is similar to `linkat` in POSIX.
	 */
	path_link :: proc(
		old_fd: fd_t,
		/**
		 * Flags determining the method of how the path is resolved.
		 */
		old_flags: lookupflags_t,
		/**
		 * The source path from which to link.
		 */
		old_path: string,
		/**
		 * The working directory at which the resolution of the new path starts.
		 */
		new_fd: fd_t,
		/**
		 * The destination path at which to create the hard link.
		 */
		new_path: string,
	) -> errno_t ---

	/**
	 * Rename a file or directory.
	 * Note: This is similar to `renameat` in POSIX.
	 */
	path_rename :: proc(
		fd: fd_t,
		/**
		 * The source path of the file or directory to rename.
		 */
		old_path: string,
		/**
		 * The working directory at which the resolution of the new path starts.
		 */
		new_fd: fd_t,
		/**
		 * The destination path to which to rename the file or directory.
		 */
		new_path: string,
	) -> errno_t ---

	/**
	 * Create a symbolic link.
	 * Note: This is similar to `symlinkat` in POSIX.
	 */
	path_symlink :: proc(
		/**
		 * The contents of the symbolic link.
		 */
		old_path: string,
		fd: fd_t,
		/**
		 * The destination path at which to create the symbolic link.
		 */
		new_path: string,
	) -> errno_t ---

	/**
	 * Unlink a file.
	 * Return `errno::isdir` if the path refers to a directory.
	 * Note: This is similar to `unlinkat(fd, path, 0)` in POSIX.
	 */
	path_unlink_file :: proc(
		fd: fd_t,
		/**
		 * The path to a file to unlink.
		 */
		path: string,
	) -> errno_t ---

	/**
	 * Write high-quality random data into a buffer.
	 * This function blocks when the implementation is unable to immediately
	 * provide sufficient high-quality random data.
	 * This function may execute slowly, so when large mounts of random data are
	 * required, it's advisable to use this function to seed a pseudo-random
	 * number generator, rather than to provide the random data directly.
	 */
	random_get :: proc(
		/**
		 * The buffer to fill with random data.
		 */
		buf: []u8,
	) -> errno_t ---

}

/**
 * Return command-line argument data sizes.
 * @return
 * Returns the number of arguments and the size of the argument string
 * data, or an error.
 */
args_sizes_get :: proc "contextless" () -> (num_args, size_of_args: size_t, err: errno_t) {
	err = wasi_args_sizes_get(&num_args, &size_of_args)
	return
}
/**
 * Return environment variable data sizes.
 * @return
 * Returns the number of environment variable arguments and the size of the
 * environment variable data.
 */
environ_sizes_get :: proc "contextless" () -> (num_envs, size_of_envs: size_t, err: errno_t) {
	err = wasi_environ_sizes_get(&num_envs, &size_of_envs)
	return
}
/**
 * Return the resolution of a clock.
 * Implementations are required to provide a non-zero value for supported clocks. For unsupported clocks,
 * return `errno::inval`.
 * Note: This is similar to `clock_getres` in POSIX.
 * @return
 * The resolution of the clock, or an error if one happened.
 */
clock_res_get :: proc "contextless" (
	/**
	 * The clock for which to return the resolution.
	 */
	id: clockid_t,
) -> (ts: timestamp_t, err: errno_t) {
	err = wasi_clock_res_get(id, &ts)
	return
}
/**
 * Return the time value of a clock.
 * Note: This is similar to `clock_gettime` in POSIX.
 * @return
 * The time value of the clock.
 */
clock_time_get :: proc "contextless" (
	/**
	 * The clock for which to return the time.
	 */
	id: clockid_t,
	/**
	 * The maximum lag (exclusive) that the returned time value may have, compared to its actual value.
	 */
	precision: timestamp_t,
) -> (ts: timestamp_t, err: errno_t) {
	err = wasi_clock_time_get(id, precision, &ts)
	return
}
/**
 * Get the attributes of a file descriptor.
 * Note: This returns similar flags to `fsync(fd, F_GETFL)` in POSIX, as well as additional fields.
 * @return
 * The buffer where the file descriptor's attributes are stored.
 */
fd_fdstat_get :: proc "contextless" (
	fd: fd_t,
) -> (stat: fdstat_t, err: errno_t) {
	err = wasi_fd_fdstat_get(fd, &stat)
	return
}
/**
 * Return the attributes of an open file.
 * @return
 * The buffer where the file's attributes are stored.
 */
fd_filestat_get :: proc "contextless" (
	fd: fd_t,
) -> (stat: filestat_t, err: errno_t) {
	err = wasi_fd_filestat_get(fd, &stat)
	return
}




/**
 * Read from a file descriptor, without using and updating the file descriptor's offset.
 * Note: This is similar to `preadv` in POSIX.
 * @return
 * The number of bytes read.
 */
fd_pread :: proc "contextless" (
	fd: fd_t,
	/**
	 * List of scatter/gather vectors in which to store data.
	 */
	iovs: []iovec_t,
	/**
	 * The offset within the file at which to read.
	 */
	offset: filesize_t,
) -> (n: size_t, err: errno_t) {
	err = wasi_fd_pread(fd, iovs, offset, &n)
	return
}
/**
 * Return a description of the given preopened file descriptor.
 * @return
 * The buffer where the description is stored.
 */
fd_prestat_get :: proc "contextless" (
	fd: fd_t,
) -> (desc: prestat_t, err: errno_t) {
	err = wasi_fd_prestat_get(fd, &desc)
	return
}
/**
 * Write to a file descriptor, without using and updating the file descriptor's offset.
 * Note: This is similar to `pwritev` in POSIX.
 * @return
 * The number of bytes written.
 */
fd_pwrite :: proc "contextless" (
	fd: fd_t,
	/**
	 * List of scatter/gather vectors from which to retrieve data.
	 */
	iovs: []ciovec_t,
	/**
	 * The offset within the file at which to write.
	 */
	offset: filesize_t,
) -> (n: size_t, err: errno_t) {
	err = wasi_fd_pwrite(fd, iovs, offset, &n)
	return
}
/**
 * Read from a file descriptor.
 * Note: This is similar to `readv` in POSIX.
 * @return
 * The number of bytes read.
 */
fd_read :: proc "contextless" (
	fd: fd_t,
	/**
	 * List of scatter/gather vectors to which to store data.
	 */
	iovs: []iovec_t,
) -> (n: size_t, err: errno_t) {
	err = wasi_fd_read(fd, iovs, &n)
	return
}
/**
 * Read directory entries from a directory.
 * When successful, the contents of the output buffer consist of a sequence of
 * directory entries. Each directory entry consists of a `dirent` object,
 * followed by `dirent::d_namlen` bytes holding the name of the directory
 * entry.
 * This function fills the output buffer as much as possible, potentially
 * truncating the last directory entry. This allows the caller to grow its
 * read buffer size in case it's too small to fit a single large directory
 * entry, or skip the oversized directory entry.
 * @return
 * The number of bytes stored in the read buffer. If less than the size of the read buffer, the end of the directory has been reached.
 */
fd_readdir :: proc "contextless" (
	fd: fd_t,
	/**
	 * The buffer where directory entries are stored
	 */
	buf: []byte,
	/**
	 * The location within the directory to start reading
	 */
	cookie: dircookie_t,
) -> (n: size_t, err: errno_t) {
	err = wasi_fd_readdir(fd, buf, cookie, &n)
	return
}
/**
 * Move the offset of a file descriptor.
 * Note: This is similar to `lseek` in POSIX.
 * @return
 * The new offset of the file descriptor, relative to the start of the file.
 */
fd_seek :: proc "contextless" (
	fd: fd_t,
	/**
	 * The number of bytes to move.
	 */
	offset: filedelta_t,
	/**
	 * The base from which the offset is relative.
	 */
	whence: whence_t,
) -> (new_offset: filesize_t, err: errno_t) {
	err = wasi_fd_seek(fd, offset, whence, &new_offset)
	return
}
/**
 * Return the current offset of a file descriptor.
 * Note: This is similar to `lseek(fd, 0, SEEK_CUR)` in POSIX.
 * @return
 * The current offset of the file descriptor, relative to the start of the file.
 */
fd_tell :: proc "contextless" (
	fd: fd_t,
) -> (offset: filesize_t, err: errno_t) {
	err = wasi_fd_tell(fd, &offset)
	return
}
/**
 * Write to a file descriptor.
 * Note: This is similar to `writev` in POSIX.
 */
fd_write :: proc "contextless" (
	fd: fd_t,
	/**
	 * List of scatter/gather vectors from which to retrieve data.
	 */
	iovs: []ciovec_t,
) -> (n: size_t, err: errno_t) {
	err = wasi_fd_write(fd, iovs, &n)
	return
}
/**
 * Return the attributes of a file or directory.
 * Note: This is similar to `stat` in POSIX.
 * @return
 * The buffer where the file's attributes are stored.
 */
path_filestat_get :: proc "contextless" (
	fd: fd_t,
	/**
	 * Flags determining the method of how the path is resolved.
	 */
	flags: lookupflags_t,
	/**
	 * The path of the file or directory to inspect.
	 */
	path: string,
) -> (offset: filestat_t, err: errno_t) {
	err = wasi_path_filestat_get(fd, flags, path, &offset)
	return
}
/**
 * Open a file or directory.
 * The returned file descriptor is not guaranteed to be the lowest-numbered
 * file descriptor not currently open; it is randomized to prevent
 * applications from depending on making assumptions about indexes, since this
 * is error-prone in multi-threaded contexts. The returned file descriptor is
 * guaranteed to be less than 2**31.
 * Note: This is similar to `openat` in POSIX.
 * @return
 * The file descriptor of the file that has been opened.
 */
path_open :: proc "contextless" (
	fd: fd_t,
	/**
	 * Flags determining the method of how the path is resolved.
	 */
	dirflags: lookupflags_t,
	/**
	 * The relative path of the file or directory to open, relative to the
	 * `path_open::fd` directory.
	 */
	path: string,
	/**
	 * The method by which to open the file.
	 */
	oflags: oflags_t,
	/**
	 * The initial rights of the newly created file descriptor. The
	 * implementation is allowed to return a file descriptor with fewer rights
	 * than specified, if and only if those rights do not apply to the type of
	 * file being opened.
	 * The *base* rights are rights that will apply to operations using the file
	 * descriptor itself, while the *inheriting* rights are rights that apply to
	 * file descriptors derived from it.
	 */
	fs_rights_base: rights_t,
	fs_rights_inheriting: rights_t,
	fdflags: fdflags_t,
) -> (file: fd_t, err: errno_t) {
	err = wasi_path_open(fd, dirflags, path, oflags, fs_rights_base, fs_rights_inheriting, fdflags, &file)
	return
}
/**
 * Read the contents of a symbolic link.
 * Note: This is similar to `readlinkat` in POSIX.
 * @return
 * The number of bytes placed in the buffer.
 */
path_readlink :: proc "contextless" (
	fd: fd_t,
	/**
	 * The path of the symbolic link from which to read.
	 */
	path: string,
	/**
	 * The buffer to which to write the contents of the symbolic link.
	 */
	buf: []u8,
) -> (n: size_t, err: errno_t) {
	err = wasi_path_readlink(fd, path, buf, &n)
	return
}
/**
 * Concurrently poll for the occurrence of a set of events.
 * @return
 * The number of events stored.
 */
poll_oneoff :: proc "contextless" (
	/**
	 * The events to which to subscribe.
	 */
	subscription_in: ^subscription_t,
	/**
	 * The events that have occurred.
	 */
	event_out: ^event_t,
	/**
	 * Both the number of subscriptions and events.
	 */
	nsubscriptions: size_t,
) -> (n: size_t, err: errno_t) {
	err = wasi_poll_oneoff(subscription_in, event_out, nsubscriptions, &n)
	return
}
/**
 * Receive a message from a socket.
 * Note: This is similar to `recv` in POSIX, though it also supports reading
 * the data into multiple buffers in the manner of `readv`.
 * @return
 * Number of bytes stored in ri_data and message flags.
 */
sock_recv :: proc "contextless" (
	fd: fd_t,
	/**
	 * List of scatter/gather vectors to which to store data.
	 */
	ri_data: []iovec_t,
	/**
	 * Message flags.
	 */
	ri_flags: riflags_t,
) -> (n: size_t, flags: roflags_t, err: errno_t) {
	err = wasi_sock_recv(fd, ri_data, ri_flags, &n, &flags)
	return
}
/**
 * Send a message on a socket.
 * Note: This is similar to `send` in POSIX, though it also supports writing
 * the data from multiple buffers in the manner of `writev`.
 * @return
 * Number of bytes transmitted.
 */
sock_send :: proc "contextless" (
	fd: fd_t,
	/**
	 * List of scatter/gather vectors to which to retrieve data
	 */
	si_data: []ciovec_t,
	/**
	 * Message flags.
	 */
	si_flags: siflags_t,
) -> (n: size_t, err: errno_t) {
	err = wasi_sock_send(fd, si_data, si_flags, &n)
	return
}






@(default_calling_convention="contextless")
foreign wasi {
	@(link_name="args_sizes_get")
	wasi_args_sizes_get :: proc(
		retptr0: ^size_t,
		retptr1: ^size_t,
	) -> errno_t ---
	@(link_name="environ_sizes_get")
	wasi_environ_sizes_get :: proc(
		retptr0: ^size_t,
		retptr1: ^size_t,
	) -> errno_t ---
	@(link_name="clock_res_get")
	wasi_clock_res_get :: proc(
		id: clockid_t,
		retptr0: ^timestamp_t,
	) -> errno_t ---
	@(link_name="clock_time_get")
	wasi_clock_time_get :: proc(
		id: clockid_t,
		precision: timestamp_t,
		retptr0: ^timestamp_t,
	) -> errno_t ---
	@(link_name="fd_fdstat_get")
	wasi_fd_fdstat_get :: proc(
		fd: fd_t,
		retptr0: ^fdstat_t,
	) -> errno_t ---
	@(link_name="fd_filestat_get")
	wasi_fd_filestat_get :: proc(
		fd: fd_t,
		retptr0: ^filestat_t,
	) -> errno_t ---
	@(link_name="fd_pread")
	wasi_fd_pread :: proc(
		fd: fd_t,
		iovs: []iovec_t,
		offset: filesize_t,
		retptr0: ^size_t,
	) -> errno_t ---
	@(link_name="fd_prestat_get")
	wasi_fd_prestat_get :: proc(
		fd: fd_t,
		retptr0: ^prestat_t,
	) -> errno_t ---
	@(link_name="fd_pwrite")
	wasi_fd_pwrite :: proc(
		fd: fd_t,
		iovs: []ciovec_t,
		offset: filesize_t,
		retptr0: ^size_t,
	) -> errno_t ---
	@(link_name="fd_read")
	wasi_fd_read :: proc(
		fd: fd_t,
		iovs: []iovec_t,
		retptr0: ^size_t,
	) -> errno_t ---
	@(link_name="fd_readdir")
	wasi_fd_readdir :: proc(
		fd: fd_t,
		buf: []u8,
		cookie: dircookie_t,
		retptr0: ^size_t,
	) -> errno_t ---
	@(link_name="fd_seek")
	wasi_fd_seek :: proc(
		fd: fd_t,
		offset: filedelta_t,
		whence: whence_t,
		retptr0: ^filesize_t,
	) -> errno_t ---
	@(link_name="fd_tell")
	wasi_fd_tell :: proc(
		fd: fd_t,
		retptr0: ^filesize_t,
	) -> errno_t ---
	@(link_name="fd_write")
	wasi_fd_write :: proc(
		fd: fd_t,
		iovs: []ciovec_t,
		retptr0: ^size_t,
	) -> errno_t ---
	@(link_name="path_filestat_get")
	wasi_path_filestat_get :: proc(
		fd: fd_t,
		flags: lookupflags_t,
		/**
		 * The path of the file or directory to inspect.
		 */
		path: string,
		retptr0: ^filestat_t,
	) -> errno_t ---
	@(link_name="path_open")
	wasi_path_open :: proc(
		fd: fd_t,
		dirflags: lookupflags_t,
		path: string,
		oflags: oflags_t,
		fs_rights_base: rights_t,
		fs_rights_inheriting: rights_t,
		fdflags: fdflags_t,
		retptr: ^fd_t,
	) -> errno_t ---
	@(link_name="path_readlink")
	wasi_path_readlink :: proc(
		fd: fd_t,
		path: string,
		buf: []u8,
		retptr0: ^size_t,
	) -> errno_t ---
	@(link_name="poll_oneoff")
	wasi_poll_oneoff :: proc(
		subscription_in: ^subscription_t,
		event_out: ^event_t,
		nsubscriptions: size_t,
		retptr0: ^size_t,
	) -> errno_t ---
	@(link_name="sock_recv")
	wasi_sock_recv :: proc(
		fd: fd_t,
		ri_data: []iovec_t,
		ri_flags: riflags_t,
		retptr0: ^size_t,
		retptr1: ^roflags_t,
	) -> errno_t ---
	@(link_name="sock_send")
	wasi_sock_send :: proc(
		fd: fd_t,
		si_data: []ciovec_t,
		si_flags: siflags_t,
		retptr0: ^size_t,
	) -> errno_t ---
}
