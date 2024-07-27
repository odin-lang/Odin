package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// sys/stat.h - data returned by the stat() function

foreign lib {

	/*
	Equivalent to either stat or lstat (based on the SYMLINK_NOFOLLOW bit in flags)
	but resolves relative paths based on the given fd.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/fstatat.html ]]
	*/
	@(link_name="fstatat" + INODE_SUFFIX)
	fstatat :: proc(fd: FD, path: cstring, buf: ^stat_t, flag: AT_Flags) -> result ---

	/*
	Obtain information about a "file" at the given path.

	Follows symbolic links.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/fstatat.html ]]
	*/
	@(link_name=LSTAT)
	stat :: proc(path: cstring, buf: ^stat_t) -> result ---

	/*
	Obtain information about an open file.

	Follows symbol links.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/fstat.html ]]
	*/
	@(link_name=LFSTAT)
	fstat :: proc(fildes: FD, buf: ^stat_t) -> result ---

	/*
	Obtain information about a "file" at the given path.

	Does not follow symlinks (will stat the symlink itself).

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/fstatat.html ]]
	*/
	@(link_name=LLSTAT)
	lstat :: proc(path: cstring, buf: ^stat_t) -> result ---

	/*
	Change the mode of a file.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/chmod.html ]]
	*/
	chmod :: proc(path: cstring, mode: mode_t) -> result ---

	/*
	Equivalent to chmod but takes an open file descriptor.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/fchmod.html ]]
	*/
	fchmod :: proc(fd: FD, mode: mode_t) -> result ---

	/*
	Equivalent to chmod but follows (or doesn't) symlinks based on the flag and resolves
	relative paths from the given fd.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/chmod.html ]]
	*/
	fchmodat :: proc(fd: FD, path: cstring, mode: mode_t, flag: AT_Flags) -> result ---

	/*
	Make a directory.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/mkdir.html ]]
	*/
	mkdir :: proc(path: cstring, mode: mode_t) -> result ---

	/*
	Equivalent to mkdir but relative paths are relative to fd.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/mkdir.html ]]
	*/
	mkdirat :: proc(fd: FD, path: cstring, mode: mode_t) -> result ---

	/*
	Make a FIFO special file.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/mkfifo.html ]]
	*/
	mkfifo :: proc(path: cstring, mode: mode_t) -> result ---

	/*
	Equivalent to mkfifo but relative paths are relative to fd.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/mkfifo.html ]]
	*/
	mkfifoat :: proc(fd: FD, path: cstring, mode: mode_t) -> result ---

	/*
	Make directory, special file, or regular file.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/mknodat.html ]]
	*/
	@(link_name=LMKNOD)
	mknod :: proc(path: cstring, mode: mode_t, dev: dev_t) -> result ---

	/*
	Equivalent to mknod but relative paths are relative to fd.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/mknodat.html ]]
	*/
	mknodat :: proc(fd: FD, path: cstring, mode: mode_t, dev: dev_t) -> result ---

	/*
	Sets the file access and modification time of the given file descriptor.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/futimens.html ]]
	*/
	futimens :: proc(fd: FD, times: ^[2]timespec) -> result ---

	/*
	Equivalent to futimens.
	Relative directories are based on fd.
	Symlinks may or may not be followed based on the flags.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/futimens.html ]]
	*/
	utimensat :: proc(fd: FD, path: cstring, times: ^[2]timespec, flag: AT_Flags) -> result ---

	/*
	Set and get the file mode creation flags.

	Makes the file mode permissions bits in cmask the new default for the process.

	Returns: the previous value

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/umask.html ]]
	*/
	umask :: proc(cmask: mode_t) -> mode_t ---
}

// Read, write, execute user.
S_IRWXU :: mode_t{ .IRUSR, .IWUSR, .IXUSR }
// Read, write, execute group.
S_IRWXG :: mode_t{ .IRGRP, .IWGRP, .IXGRP }
// Read, write, execute other.
S_IRWXO :: mode_t{ .IROTH, .IWOTH, .IXOTH }

Mode_Bits :: enum c.int {
	// File type:

	IFBLK  = log2(S_IFBLK),  /* Block special */
	IFCHR  = log2(S_IFCHR),  /* Character special */
	IFIFO  = log2(S_IFIFO),  /* FIFO special */
	IFREG  = log2(S_IFREG),  /* Regular */
	IFDIR  = log2(S_IFDIR),  /* Directory */
	IFLNK  = log2(S_IFLNK),  /* Symbolic link */
	IFSOCK = log2(S_IFSOCK), /* Socket */

	// Permissions:

	IRUSR  = log2(_S_IRUSR), /* R for owner */
	IWUSR  = log2(_S_IWUSR), /* W for owner */
	IXUSR  = log2(_S_IXUSR), /* X for owner */

	IRGRP  = log2(_S_IRGRP), /* R for group */
	IWGRP  = log2(_S_IWGRP), /* W for group */
	IXGRP  = log2(_S_IXGRP), /* X for group */

	IROTH  = log2(_S_IROTH), /* R for other */
	IWOTH  = log2(_S_IWOTH), /* W for other */
	IXOTH  = log2(_S_IXOTH), /* X for other */

	ISUID  = log2(_S_ISUID), /* Set user ID on execution */
	ISGID  = log2(_S_ISGID), /* Set group ID on execution */
	ISVXT  = log2(_S_ISVTX), /* On directories, restricted deletion flag */
}
mode_t :: bit_set[Mode_Bits; _mode_t]
#assert(size_of(mode_t) == size_of(_mode_t))

// NOTE: making these `.IFREG in m` would probably be fine too,
// but implementations make this an exclusive check so lets stick to it.

_S_IFMT :: mode_t{ .IFBLK, .IFCHR, .IFIFO, .IFREG, .IFDIR, .IFLNK, .IFSOCK }

// Test for a block special file.
S_ISBLK :: #force_inline proc "contextless" (m: mode_t) -> bool {
	return (m & _S_IFMT) == { .IFBLK }
}

// Test for a character special file.
S_ISCHR :: #force_inline proc "contextless" (m: mode_t) -> bool {
	return (m & _S_IFMT) == { .IFCHR }
}

// Test for a pipe or FIFO special file.
S_ISFIFO :: #force_inline proc "contextless" (m: mode_t) -> bool {
	return (m & _S_IFMT) == { .IFIFO }
}

// Test for a regular file.
S_ISREG :: #force_inline proc "contextless" (m: mode_t) -> bool {
	return (m & _S_IFMT) == { .IFREG }
}

// Test for a directory.
S_ISDIR :: #force_inline proc "contextless" (m: mode_t) -> bool {
	return (m & _S_IFMT) == { .IFDIR }
}

// Test for a symbolic link.
S_ISLNK :: #force_inline proc "contextless" (m: mode_t) -> bool {
	return (m & _S_IFMT) == { .IFLNK }
}

// Test for a socket.
S_ISSOCK :: #force_inline proc "contextless" (m: mode_t) -> bool {
	return (m & _S_IFMT) == { .IFSOCK }
}

// Test for a message queue.
S_TYPEISMQ :: #force_inline proc "contextless" (m: mode_t) -> bool {
	return _S_TYPEISMQ(m)
}

// Test for a semaphore.
S_TYPEISSEM :: #force_inline proc "contextless" (m: mode_t) -> bool {
	return _S_TYPEISSEM(m)
}

// Test for a shared memory object.
S_TYPEISSHM :: #force_inline proc "contextless" (m: mode_t) -> bool {
	return _S_TYPEISSHM(m)
}

// Test macro for a typed memory object.
S_TYPEISTMO :: #force_inline proc "contextless" (m: mode_t) -> bool {
	return _S_TYPEISTMO(m)
}

_S_IRWXU  :: 0o000700
_S_IRUSR  :: 0o000400
_S_IWUSR  :: 0o000200
_S_IXUSR  :: 0o000100

_S_IRWXG  :: 0o000070
_S_IRGRP  :: 0o000040
_S_IWGRP  :: 0o000020
_S_IXGRP  :: 0o000010

_S_IRWXO  :: 0o000007
_S_IROTH  :: 0o000004
_S_IWOTH  :: 0o000002
_S_IXOTH  :: 0o000001

_S_ISUID  :: 0o004000
_S_ISGID  :: 0o002000
_S_ISVTX  :: 0o001000

when ODIN_OS == .NetBSD {
	@(private) LSTAT  :: "__stat50"
	@(private) LFSTAT :: "__fstat50"
	@(private) LLSTAT :: "__lstat50"
	@(private) LMKNOD :: "__mknod50"
} else {
	@(private) LSTAT  :: "stat"  + INODE_SUFFIX
	@(private) LFSTAT :: "fstat" + INODE_SUFFIX
	@(private) LLSTAT :: "lstat" + INODE_SUFFIX
	@(private) LMKNOD :: "mknod"
}

when ODIN_OS == .Darwin {

	dev_t      :: distinct c.int32_t
	nlink_t    :: distinct c.uint16_t
	_mode_t    :: distinct c.uint16_t
	blkcnt_t   :: distinct c.int64_t
	blksize_t  :: distinct c.int32_t
	ino_t      :: distinct c.uint64_t

	stat_t :: struct {
		st_dev:           dev_t,        /* [XSI] ID of device containing file */
		st_mode:          mode_t,       /* [XSI] mode of file */
		st_nlink:         nlink_t,      /* [XSI] number of hard links */
		st_ino:           ino_t,        /* [XSI] file serial number */
		st_uid:           uid_t,        /* [XSI] user ID of the file */
		st_gid:           gid_t,        /* [XSI] group ID of the file */
		st_rdev:          dev_t,        /* [XSI] device ID */
		st_atim:          timespec,     /* [XSI] time of last access */
		st_mtim:          timespec,     /* [XSI] time of last data modification */
		st_ctim:          timespec,     /* [XSI] time of last status change */
		st_birthtimespec: timespec,     /* time of file creation(birth) */
		st_size:          off_t,        /* [XSI] file size, in bytes */
		st_blocks:        blkcnt_t,     /* [XSI] blocks allocated for file */
		st_blksize:       blksize_t,    /* [XSI] optimal blocksize for I/O */
		st_flags:         c.uint32_t,   /* user defined flags for file */
		st_gen:           c.uint32_t,   /* file generation number */
		st_lspare:        c.int32_t,    /* RESERVED */
		st_qspare:        [2]c.int64_t, /* RESERVED */
	}

	S_IFBLK  :: 0o060000
	S_IFCHR  :: 0o020000
	S_IFIFO  :: 0o010000
	S_IFREG  :: 0o100000
	S_IFDIR  :: 0o040000
	S_IFLNK  :: 0o120000
	S_IFSOCK :: 0o140000

	__S_IFMT :: 0o170000

	_S_TYPEISMQ :: #force_inline proc "contextless" (m: mode_t) -> bool {
		return false
	}

	_S_TYPEISSEM :: #force_inline proc "contextless" (m: mode_t) -> bool {
		return false
	}

	_S_TYPEISSHM :: #force_inline proc "contextless" (m: mode_t) -> bool {
		return false
	}

	_S_TYPEISTMO :: #force_inline proc "contextless" (m: mode_t) -> bool {
		return false
	}

	UTIME_NOW  :: -1
	UTIME_OMIT :: -2

} else when ODIN_OS == .FreeBSD {

	dev_t      :: distinct c.uint64_t
	nlink_t    :: distinct c.uint64_t
	_mode_t    :: distinct c.uint16_t
	blkcnt_t   :: distinct c.int64_t
	blksize_t  :: distinct c.int32_t
	ino_t      :: distinct c.uint64_t

	when ODIN_ARCH == .i386 {
		stat_t :: struct {
			st_dev:           dev_t,        /* [XSI] ID of device containing file */
			st_ino:           ino_t,        /* [XSI] file serial number */
			st_nlink:         nlink_t,      /* [XSI] number of hard links */
			st_mode:          mode_t,       /* [XSI] mode of file */
			st_padding0:      c.int16_t,
			st_uid:           uid_t,        /* [XSI] user ID of the file */
			st_gid:           gid_t,        /* [XSI] group ID of the file */
			st_padding1:      c.int32_t,
			st_rdev:          dev_t,        /* [XSI] device ID */
			st_atim_ext:      c.int32_t,
			st_atim:          timespec,     /* [XSI] time of last access */
			st_mtim_ext:      c.int32_t,
			st_mtim:          timespec,     /* [XSI] time of last data modification */
			st_ctim_ext:      c.int32_t,
			st_ctim:          timespec,     /* [XSI] time of last status change */
			st_birthtimespec: timespec,     /* time of file creation(birth) */
			st_size:          off_t,        /* [XSI] file size, in bytes */
			st_blocks:        blkcnt_t,     /* [XSI] blocks allocated for file */
			st_blksize:       blksize_t,    /* [XSI] optimal blocksize for I/O */
			st_flags:         c.uint32_t,   /* user defined flags for file */
			st_gen:           c.uint64_t,
			st_spare:         [10]c.uint64_t,
		}
	} else {
		stat_t :: struct {
			st_dev:           dev_t,        /* [XSI] ID of device containing file */
			st_ino:           ino_t,        /* [XSI] file serial number */
			st_nlink:         nlink_t,      /* [XSI] number of hard links */
			st_mode:          mode_t,       /* [XSI] mode of file */
			st_padding0:      c.int16_t,
			st_uid:           uid_t,        /* [XSI] user ID of the file */
			st_gid:           gid_t,        /* [XSI] group ID of the file */
			st_padding1:      c.int32_t,
			st_rdev:          dev_t,        /* [XSI] device ID */
			st_atim:          timespec,     /* [XSI] time of last access */
			st_mtim:          timespec,     /* [XSI] time of last data modification */
			st_ctim:          timespec,     /* [XSI] time of last status change */
			st_birthtimespec: timespec,     /* time of file creation(birth) */
			st_size:          off_t,        /* [XSI] file size, in bytes */
			st_blocks:        blkcnt_t,     /* [XSI] blocks allocated for file */
			st_blksize:       blksize_t,    /* [XSI] optimal blocksize for I/O */
			st_flags:         c.uint32_t,   /* user defined flags for file */
			st_gen:           c.uint64_t,
			st_spare:         [10]c.uint64_t,
		}
	}

	S_IFBLK  :: 0o060000
	S_IFCHR  :: 0o020000
	S_IFIFO  :: 0o010000
	S_IFREG  :: 0o100000
	S_IFDIR  :: 0o040000
	S_IFLNK  :: 0o120000
	S_IFSOCK :: 0o140000

	__S_IFMT :: 0o170000

	_S_TYPEISMQ :: #force_inline proc "contextless" (m: mode_t) -> bool {
		return false
	}

	_S_TYPEISSEM :: #force_inline proc "contextless" (m: mode_t) -> bool {
		return false
	}

	_S_TYPEISSHM :: #force_inline proc "contextless" (m: mode_t) -> bool {
		return false
	}

	_S_TYPEISTMO :: #force_inline proc "contextless" (m: mode_t) -> bool {
		return false
	}

	UTIME_NOW  :: -1
	UTIME_OMIT :: -2

} else when ODIN_OS == .NetBSD {

	dev_t      :: distinct c.uint64_t
	nlink_t    :: distinct c.uint32_t
	_mode_t    :: distinct c.uint32_t
	blkcnt_t   :: distinct c.int64_t
	blksize_t  :: distinct c.int32_t
	ino_t      :: distinct c.uint64_t

	stat_t :: struct {
		st_dev:           dev_t,        /* [XSI] ID of device containing file */
		st_mode:          mode_t,       /* [XSI] mode of file */
		st_ino:           ino_t,        /* [XSI] file serial number */
		st_nlink:         nlink_t,      /* [XSI] number of hard links */
		st_uid:           uid_t,        /* [XSI] user ID of the file */
		st_gid:           gid_t,        /* [XSI] group ID of the file */
		st_rdev:          dev_t,        /* [XSI] device ID */
		st_atim:          timespec,     /* [XSI] time of last access */
		st_mtim:          timespec,     /* [XSI] time of last data modification */
		st_ctim:          timespec,     /* [XSI] time of last status change */
		st_birthtimespec: timespec,     /* time of file creation(birth) */
		st_size:          off_t,        /* [XSI] file size, in bytes */
		st_blocks:        blkcnt_t,     /* [XSI] blocks allocated for file */
		st_blksize:       blksize_t,    /* [XSI] optimal blocksize for I/O */
		st_flags:         c.uint32_t,   /* user defined flags for file */
		st_gen:           c.uint64_t,
		st_spare:         [2]c.uint32_t,
	}

	S_IFBLK  :: 0o060000
	S_IFCHR  :: 0o020000
	S_IFIFO  :: 0o010000
	S_IFREG  :: 0o100000
	S_IFDIR  :: 0o040000
	S_IFLNK  :: 0o120000
	S_IFSOCK :: 0o140000

	__S_IFMT :: 0o170000

	_S_TYPEISMQ :: #force_inline proc "contextless" (m: mode_t) -> bool {
		return false
	}

	_S_TYPEISSEM :: #force_inline proc "contextless" (m: mode_t) -> bool {
		return false
	}

	_S_TYPEISSHM :: #force_inline proc "contextless" (m: mode_t) -> bool {
		return false
	}

	_S_TYPEISTMO :: #force_inline proc "contextless" (m: mode_t) -> bool {
		return false
	}

	UTIME_NOW  :: (1 << 30) - 1
	UTIME_OMIT :: (1 << 30) - 2

} else when ODIN_OS == .OpenBSD {

	dev_t      :: distinct c.int32_t
	nlink_t    :: distinct c.uint32_t
	_mode_t    :: distinct c.uint32_t
	blkcnt_t   :: distinct c.int64_t
	blksize_t  :: distinct c.int32_t
	ino_t      :: distinct c.uint64_t

	stat_t :: struct {
		st_mode:          mode_t,       /* [XSI] mode of file */
		st_dev:           dev_t,        /* [XSI] ID of device containing file */
		st_ino:           ino_t,        /* [XSI] file serial number */
		st_nlink:         nlink_t,      /* [XSI] number of hard links */
		st_uid:           uid_t,        /* [XSI] user ID of the file */
		st_gid:           gid_t,        /* [XSI] group ID of the file */
		st_rdev:          dev_t,        /* [XSI] device ID */
		st_atim:          timespec,     /* [XSI] time of last access */
		st_mtim:          timespec,     /* [XSI] time of last data modification */
		st_ctim:          timespec,     /* [XSI] time of last status change */
		st_size:          off_t,        /* [XSI] file size, in bytes */
		st_blocks:        blkcnt_t,     /* [XSI] blocks allocated for file */
		st_blksize:       blksize_t,    /* [XSI] optimal blocksize for I/O */
		st_flags:         c.uint32_t,   /* user defined flags for file */
		st_gen:           c.int32_t,
		st_birthtimespec: timespec,
	}

	S_IFBLK  :: 0o060000
	S_IFCHR  :: 0o020000
	S_IFIFO  :: 0o010000
	S_IFREG  :: 0o100000
	S_IFDIR  :: 0o040000
	S_IFLNK  :: 0o120000
	S_IFSOCK :: 0o140000

	__S_IFMT :: 0o170000

	_S_TYPEISMQ :: #force_inline proc "contextless" (m: mode_t) -> bool {
		return false
	}

	_S_TYPEISSEM :: #force_inline proc "contextless" (m: mode_t) -> bool {
		return false
	}

	_S_TYPEISSHM :: #force_inline proc "contextless" (m: mode_t) -> bool {
		return false
	}

	_S_TYPEISTMO :: #force_inline proc "contextless" (m: mode_t) -> bool {
		return false
	}

	UTIME_NOW  :: -2
	UTIME_OMIT :: -1

} else {
	#panic("posix is unimplemented for the current target")
}
