package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// fcntl.h - file control options

foreign lib {
	/*
	Implemented as `return open(path, O_WRONLY|O_CREAT|O_TRUNC, mode);`

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/creat.html ]]
	*/
	creat :: proc(path: cstring, mode: mode_t) -> FD ---

	/*
	Perform the operations on open files.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/fcntl.html ]]
	*/
	fcntl :: proc(fd: FD, cmd: FCNTL_Cmd, #c_vararg args: ..any) -> c.int ---

	/*
	Establish the connection between a file and a file descriptor.
	It shall create an open file description that refers to a file and a file descriptor that
	refers to that open file description. The file descriptor is used by other I/O functions to
	refer to that file.
	The path argument points to a pathname naming the file

	Returns: -1 on failure (setting errno), a file descriptor on success.

	Example:
		// The following example opens the file /tmp/file, either by creating it (if it does not already exist),
		// or by truncating its length to 0 (if it does exist). In the former case, if the call creates a new file,
		// the access permission bits in the file mode of the file are set to permit reading and writing by the owner,
		// and to permit reading only by group members and others.
		fd := posix.open("/tmp/file", { .WRONLY, .CREAT, .TRUNC }, { .IRUSR, .IWUSR, .IRGRP, .IROTH })

		// The following example uses the open() function to try to create the LOCKFILE file and open it for writing.
		// Since the open() function specifies the O_EXCL flag, the call fails if the file already exists.
		// In that case, the program assumes that someone else is updating the password file and exits.
		fd := posix.open("/etc/ptmp", { .WRONLY, .CREAT, .EXCL }, { .IRUSR, .IWUSR, .IRGRP, .IROTH })
		if fd == -1 {
			fmt.println("cannot open /etc/ptmp")
		}

		// The following example opens a file for writing, creating the file if it does not already exist.
		// If the file does exist, the system truncates the file to zero bytes.
		fd := posix.open("/etc/ptmp", { .WRONLY, .CREAT, .TRUNC }, { .IRUSR, .IWUSR, .IRGRP, .IROTH })
		if fd == -1 {
			fmt.println("cannot open output file")
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/open.html ]]
	*/
	open :: proc(path: cstring, flags: O_Flags, #c_vararg mode: ..mode_t) -> FD ---

	/*
	Equivalent to the open() function except in the case where path specifies a relative path.
	In this case the file to be opened is determined relative to the directory associated with the
	file descriptor fd instead of the current working directory.

	Returns: -1 on failure (setting errno), a file descriptor on success.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/open.html ]]
	*/
	openat :: proc(fd: FD, path: cstring, flags: O_Flags, mode: mode_t = {}) -> FD ---
}

FCNTL_Cmd :: enum c.int {
	DUPFD         = F_DUPFD,
	DUPFD_CLOEXEC = F_DUPFD_CLOEXEC,
	GETFD         = F_GETFD,
	SETFD         = F_SETFD,
	GETFL         = F_GETFL,
	SETFL         = F_SETFL,
	GETLK         = F_GETLK,
	SETLK         = F_SETLK,
	SETLKW        = F_SETLKW,
	GETOWN        = F_GETOWN,
	SETOWN        = F_SETOWN,
}

Lock_Type :: enum c.short {
	RDLCK = F_RDLCK,
	UNLCK = F_UNLCK,
	WRLCK = F_WRLCK,
}

O_Flag_Bits :: enum c.int {
	// Sets FD_CLOEXEC on the file descriptor.
	CLOEXEC   = log2(O_CLOEXEC),
	// If not exists, combined with DIRECTORY will cause creation of a directory, otherwise a regular file.
	CREAT     = log2(O_CREAT),
	// Fails if the opened descriptor would not be a directory.
	DIRECTORY = log2(O_DIRECTORY),
	// If combined with CREAT, causes a failure if the file already exists.
	EXCL      = log2(O_EXCL),
	// If terminal device, do not make it the controlling terminal for the process.
	NOCTTY    = log2(O_NOCTTY),
	// Don't follow symbolic links, fail with errno ELOOP.
	NOFOLLOW  = log2(O_NOFOLLOW),
	// If exists and regular, truncate the length to 0.
	TRUNC     = log2(O_TRUNC),

	// NOTE: use with `posix.O_TTY_INIT + { .OTHER_FLAG, .OTHER_FLAG }`, unfortunately can't be in
	// this bit set enum because it is 0 on some platforms and a value on others.
	// TTY_INIT = O_TTY_INIT,

	// Set file offset to end of file prior to each write.
	APPEND    = log2(O_APPEND),
	// Write I/O shall complete as defined by synchronized I/O data integrity completion.
	DSYNC     = log2(O_DSYNC),
	// Causes nonblocking behaviour in various situations.
	NONBLOCK  = log2(O_NONBLOCK),
	// Write I/O shall complete as defined by synchronized I/O file integrity completion.
	SYNC      = log2(O_SYNC),

	// NOTE: use with `posix.O_RSYNC + { .OTHER_FLAG, .OTHER_FLAG }`, unfortunately can't be in
	// this bit set enum because it is 0 on some platforms and a value on others.
	// RSYNC = O_RSYNC,

	// Execute only.
	EXEC      = log2(O_EXEC),
	// Reading and writing.
	RDWR      = log2(O_RDWR),
	// Writing only.
	WRONLY    = log2(O_WRONLY),
	// Reading only.
	// RDONLY = 0, // Default
}

O_Flags :: bit_set[O_Flag_Bits; c.int]

O_ACCMODE :: O_Flags{ .EXEC, .RDWR, .WRONLY }

AT_Flag_Bits :: enum c.int {
	EACCESS          = log2(AT_EACCESS),
	SYMLINK_NOFOLLOW = log2(AT_SYMLINK_NOFOLLOW),
	SYMLINK_FOLLOW   = log2(AT_SYMLINK_FOLLOW),
	REMOVEDIR        = log2(AT_REMOVEDIR),
}
AT_Flags :: bit_set[AT_Flag_Bits; c.int]

when ODIN_OS == .Darwin {

	off_t :: distinct c.int64_t
	pid_t :: distinct c.int32_t

	F_DUPFD         :: 0
	F_DUPFD_CLOEXEC :: 67
	F_GETFD         :: 1
	F_SETFD         :: 2
	F_GETFL         :: 3
	F_SETFL         :: 4
	F_GETLK         :: 7
	F_SETLK         :: 8
	F_SETLKW        :: 9
	F_GETOWN        :: 5
	F_SETOWN        :: 6

	FD_CLOEXEC :: 1

	F_RDLCK :: 1
	F_UNLCK :: 2
	F_WRLCK :: 3

	O_CLOEXEC   :: 0x01000000
	O_CREAT     :: 0x00000200
	O_DIRECTORY :: 0x00100000
	O_EXCL      :: 0x00000800
	O_NOCTTY    :: 0x00020000
	O_NOFOLLOW  :: 0x00000100
	O_TRUNC     :: 0x00000400

	_O_TTY_INIT :: 0
	O_TTY_INIT  :: O_Flags{}

	O_APPEND   :: 0x00000008
	O_DSYNC    :: 0x00400000
	O_NONBLOCK :: 0x00000004
	O_SYNC     :: 0x0080

	_O_RSYNC :: 0
	O_RSYNC  :: O_Flags{}

	O_EXEC   :: 0x40000000
	O_RDONLY :: 0
	O_RDWR   :: 0x0002
	O_WRONLY :: 0x0001

	_O_SEARCH :: O_EXEC | O_DIRECTORY
	O_SEARCH  :: O_Flags{.EXEC, .DIRECTORY}

	AT_FDCWD: FD: -2

	AT_EACCESS          :: 0x0010
	AT_SYMLINK_NOFOLLOW :: 0x0020
	AT_SYMLINK_FOLLOW   :: 0x0040
	AT_REMOVEDIR        :: 0x0080

	flock :: struct {
		l_start:  off_t,     /* [PSX] relative offset in bytes */
		l_len:    off_t,     /* [PSX] size; if 0 then until EOF */
		l_pid:    pid_t,     /* [PSX] process ID of the process holding the lock */
		l_type:   Lock_Type, /* [PSX] type of lock */
		l_whence: c.short,   /* [PSX] flag (Whence) of starting offset */
	}

} else when ODIN_OS == .FreeBSD {

	off_t :: distinct c.int64_t
	pid_t :: distinct c.int32_t

	F_DUPFD         :: 0
	F_DUPFD_CLOEXEC :: 17
	F_GETFD         :: 1
	F_SETFD         :: 2
	F_GETFL         :: 3
	F_SETFL         :: 4
	F_GETLK         :: 7
	F_SETLK         :: 8
	F_SETLKW        :: 9
	F_GETOWN        :: 5
	F_SETOWN        :: 6

	FD_CLOEXEC :: 1

	F_RDLCK :: 1
	F_UNLCK :: 2
	F_WRLCK :: 3

	O_CLOEXEC   :: 0x00100000
	O_CREAT     :: 0x0200
	O_DIRECTORY :: 0x00020000
	O_EXCL      :: 0x0800
	O_NOCTTY    :: 0x8000
	O_NOFOLLOW  :: 0x0100
	O_TRUNC     :: 0x0400

	_O_TTY_INIT :: 0x00080000
	O_TTY_INIT  :: O_Flags{O_Flag_Bits(log2(_O_TTY_INIT))}

	O_APPEND   :: 0x0008
	O_DSYNC    :: 0x01000000
	O_NONBLOCK :: 0x0004
	O_SYNC     :: 0x0080
	_O_RSYNC   :: 0
	O_RSYNC    :: O_Flags{} // NOTE: not defined in headers

	O_EXEC   :: 0x00040000
	O_RDONLY :: 0
	O_RDWR   :: 0x0002
	O_WRONLY :: 0x0001

	_O_SEARCH :: O_EXEC
	O_SEARCH  :: O_Flags{ .EXEC }

	AT_FDCWD: FD: -100

	AT_EACCESS          :: 0x0100
	AT_SYMLINK_NOFOLLOW :: 0x0200
	AT_SYMLINK_FOLLOW   :: 0x0400
	AT_REMOVEDIR        :: 0x0800

	flock :: struct {
		l_start:  off_t,     /* [PSX] relative offset in bytes */
		l_len:    off_t,     /* [PSX] size; if 0 then until EOF */
		l_pid:    pid_t,     /* [PSX] process ID of the process holding the lock */
		l_type:   Lock_Type, /* [PSX] type of lock */
		l_whence: c.short,   /* [PSX] flag (Whence) of starting offset */
		l_sysid:  c.int,
	}

} else when ODIN_OS == .NetBSD {

	off_t :: distinct c.int64_t
	pid_t :: distinct c.int32_t

	F_DUPFD         :: 0
	F_DUPFD_CLOEXEC :: 12
	F_GETFD         :: 1
	F_SETFD         :: 2
	F_GETFL         :: 3
	F_SETFL         :: 4
	F_GETLK         :: 7
	F_SETLK         :: 8
	F_SETLKW        :: 9
	F_GETOWN        :: 5
	F_SETOWN        :: 6

	FD_CLOEXEC :: 1

	F_RDLCK :: 1
	F_UNLCK :: 2
	F_WRLCK :: 3

	O_CLOEXEC   :: 0x00400000
	O_CREAT     :: 0x0200
	O_DIRECTORY :: 0x0020000
	O_EXCL      :: 0x0800
	O_NOCTTY    :: 0x8000
	O_NOFOLLOW  :: 0x0100
	O_TRUNC     :: 0x0400

	_O_TTY_INIT :: 0
	O_TTY_INIT  :: O_Flags{} // NOTE: not defined in the headers

	O_APPEND   :: 0x0008
	O_DSYNC    :: 0x010000
	O_NONBLOCK :: 0x0004
	O_SYNC     :: 0x0080

	_O_RSYNC :: 0x0002
	O_RSYNC  :: O_Flags{O_Flag_Bits(log2(_O_RSYNC))}


	O_EXEC   :: 0x04000000
	O_RDONLY :: 0
	O_RDWR   :: 0x0002
	O_WRONLY :: 0x0001

	_O_SEARCH :: 0x00800000
	O_SEARCH  :: O_Flags{O_Flag_Bits(log2(_O_SEARCH))}

	AT_FDCWD: FD: -100

	AT_EACCESS          :: 0x100
	AT_SYMLINK_NOFOLLOW :: 0x200
	AT_SYMLINK_FOLLOW   :: 0x400
	AT_REMOVEDIR        :: 0x800

	flock :: struct {
		l_start:  off_t,     /* [PSX] relative offset in bytes */
		l_len:    off_t,     /* [PSX] size; if 0 then until EOF */
		l_pid:    pid_t,     /* [PSX] process ID of the process holding the lock */
		l_type:   Lock_Type, /* [PSX] type of lock */
		l_whence: c.short,   /* [PSX] flag (Whence) of starting offset */
	}
} else when ODIN_OS == .OpenBSD {

	off_t :: distinct c.int64_t
	pid_t :: distinct c.int32_t

	F_DUPFD         :: 0
	F_DUPFD_CLOEXEC :: 10
	F_GETFD         :: 1
	F_SETFD         :: 2
	F_GETFL         :: 3
	F_SETFL         :: 4
	F_GETLK         :: 7
	F_SETLK         :: 8
	F_SETLKW        :: 9
	F_GETOWN        :: 5
	F_SETOWN        :: 6

	FD_CLOEXEC :: 1

	F_RDLCK :: 1
	F_UNLCK :: 2
	F_WRLCK :: 3

	O_CLOEXEC   :: 0x10000
	O_CREAT     :: 0x0200
	O_DIRECTORY :: 0x20000
	O_EXCL      :: 0x0800
	O_NOCTTY    :: 0x8000
	O_NOFOLLOW  :: 0x0100
	O_TRUNC     :: 0x0400

	_O_TTY_INIT :: 0
	O_TTY_INIT  :: O_Flags{} // NOTE: not defined in the headers

	O_APPEND   :: 0x0008
	O_DSYNC    :: 0x010000
	O_NONBLOCK :: 0x0004
	O_SYNC     :: 0x0080

	_O_RSYNC :: O_SYNC
	O_RSYNC  :: O_Flags{.SYNC}

	O_EXEC   :: 0x04000000 // NOTE: not defined in the headers
	O_RDONLY :: 0
	O_RDWR   :: 0x0002
	O_WRONLY :: 0x0001

	_O_SEARCH :: 0
	O_SEARCH  :: O_Flags{} // NOTE: not defined in the headers

	AT_FDCWD: FD: -100

	AT_EACCESS          :: 0x01
	AT_SYMLINK_NOFOLLOW :: 0x02
	AT_SYMLINK_FOLLOW   :: 0x04
	AT_REMOVEDIR        :: 0x08

	flock :: struct {
		l_start:  off_t,     /* [PSX] relative offset in bytes */
		l_len:    off_t,     /* [PSX] size; if 0 then until EOF */
		l_pid:    pid_t,     /* [PSX] process ID of the process holding the lock */
		l_type:   Lock_Type, /* [PSX] type of lock */
		l_whence: c.short,   /* [PSX] flag (Whence) of starting offset */
	}

} else when ODIN_OS == .Linux {

	off_t :: distinct c.int64_t
	pid_t :: distinct c.int

	F_DUPFD  :: 0
	F_GETFD  :: 1
	F_SETFD  :: 2
	F_GETFL  :: 3
	F_SETFL  :: 4
	F_GETLK  :: 5
	F_SETLK  :: 6
	F_SETLKW :: 7
	F_SETOWN :: 8
	F_GETOWN :: 9
	F_RDLCK  :: 0
	F_UNLCK  :: 2
	F_WRLCK  :: 1

	F_DUPFD_CLOEXEC :: 1030

	FD_CLOEXEC :: 1

	O_CREAT     :: 0o0_000_100
	O_EXCL      :: 0o0_000_200
	O_NOCTTY    :: 0o0_000_400
	O_TRUNC     :: 0o0_001_000
	O_DIRECTORY :: 0o0_200_000
	O_NOFOLLOW  :: 0o0_400_000
	O_CLOEXEC   :: 0o2_000_000

	_O_TTY_INIT :: 0
	O_TTY_INIT  :: O_Flags{}

	O_APPEND   :: 0o0_002_000
	O_NONBLOCK :: 0o0_004_000
	O_DSYNC    :: 0o0_010_000
	O_SYNC     :: 0o4_010_000

	_O_RSYNC :: 0
	O_RSYNC  :: O_Flags{}

	O_EXEC   :: 0x04000000 // NOTE: not defined in the headers

	O_RDONLY :: 0
	O_WRONLY :: 0o1
	O_RDWR   :: 0o2

	_O_SEARCH :: 0
	O_SEARCH  :: O_Flags{}

	AT_FDCWD: FD: -100

	AT_EACCESS          :: 0x200
	AT_SYMLINK_NOFOLLOW :: 0x100
	AT_SYMLINK_FOLLOW   :: 0x400
	AT_REMOVEDIR        :: 0x200

	flock :: struct {
		l_start:  off_t,     /* [PSX] relative offset in bytes. */
		l_len:    off_t,     /* [PSX] size; if 0 then until EOF. */
		l_pid:    pid_t,     /* [PSX] process ID of the process holding the lock. */
		l_type:   Lock_Type, /* [PSX] type of lock. */
		l_whence: c.short,   /* [PSX] flag (Whence) of starting offset. */
	}

} else {
	#panic("posix is unimplemented for the current target")
}
