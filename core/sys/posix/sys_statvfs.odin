#+build linux, darwin, netbsd, openbsd, freebsd
package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// sys/statvfs.h - VFS File System information structure

foreign lib {

	/*
	Obtains information about the file system containing the fildes.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/statvfs.html ]]
	*/
	@(link_name=LFSTATVFS)
	fstatvfs :: proc(fildes: FD, buf: ^statvfs_t) -> result ---

	/*
	Obtains information about the file system containing the file named by path.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/statvfs.html ]]
	*/
	@(link_name=LSTATVFS)
	statvfs :: proc(path: cstring, buf: ^statvfs_t) -> result ---
}

VFS_Flag_Bits :: enum c.ulong {
	// Read-only file system.
	RDONLY = log2(ST_RDONLY),
	// Does not support the semantics of the ST_ISUID and ST_ISGID file mode bits.
	NOSUID = log2(ST_NOSUID),
}
VFS_Flags :: bit_set[VFS_Flag_Bits; c.ulong]

when ODIN_OS == .NetBSD {
	@(private) LFSTATVFS :: "__fstatvfs90"
	@(private) LSTATVFS  :: "__statvfs90"
} else {
	@(private) LFSTATVFS :: "fstatvfs"
	@(private) LSTATVFS  :: "statvfs"
}

when ODIN_OS == .Darwin || ODIN_OS == .OpenBSD {
	
	fsblkcnt_t :: distinct c.uint

	statvfs_t :: struct {
		f_bsize:   c.ulong,    /* [PSX] file system block size */
		f_frsize:  c.ulong,    /* [PSX] fundamental file system block size */
		f_blocks:  fsblkcnt_t, /* [PSX] total number of blocks on file system in units of f_frsize */
		f_bfree:   fsblkcnt_t, /* [PSX] total number of free blocks */
		f_bavail:  fsblkcnt_t, /* [PSX] number of free blocks available to non-privileged process */
		f_files:   fsblkcnt_t, /* [PSX] total number of file serial numbers */
		f_ffree:   fsblkcnt_t, /* [PSX] total number of free file serial numbers */
		f_favail:  fsblkcnt_t, /* [PSX] number of file serial numbers available to non-privileged process */
		f_fsid:    c.ulong,    /* [PSX] file system ID */
		f_flag:    VFS_Flags,  /* [PSX] bit mask of f_flag values */
		f_namemax: c.ulong,    /* [PSX] maximum filename length */
	}

	ST_RDONLY :: 0x00000001
	ST_NOSUID :: 0x00000002

} else when ODIN_OS == .FreeBSD {
	
	fsblkcnt_t :: distinct c.uint64_t

	statvfs_t :: struct {
		f_bavail:  fsblkcnt_t, /* [PSX] number of free blocks available to non-privileged process */
		f_bfree:   fsblkcnt_t, /* [PSX] total number of free blocks */
		f_blocks:  fsblkcnt_t, /* [PSX] total number of blocks on file system in units of f_frsize */
		f_favail:  fsblkcnt_t, /* [PSX] number of file serial numbers available to non-privileged process */
		f_ffree:   fsblkcnt_t, /* [PSX] total number of free file serial numbers */
		f_files:   fsblkcnt_t, /* [PSX] total number of file serial numbers */
		f_bsize:   c.ulong,    /* [PSX] file system block size */
		f_flag:    VFS_Flags,  /* [PSX] bit mask of f_flag values */
		f_frsize:  c.ulong,    /* [PSX] fundamental file system block size */
		f_fsid:    c.ulong,    /* [PSX] file system ID */
		f_namemax: c.ulong,    /* [PSX] maximum filename length */
	}

	ST_RDONLY :: 0x00000001
	ST_NOSUID :: 0x00000002

} else when ODIN_OS == .NetBSD {
	
	fsblkcnt_t :: distinct c.uint64_t

	@(private)
	_VFS_NAMELEN :: 1024

	@(private)
	fsid_t :: struct {
		__fsid_val: [2]c.int,
	}

	statvfs_t :: struct {
		f_flag:         VFS_Flags,  /* [PSX] bit mask of f_flag values */
		f_bsize:        c.ulong,    /* [PSX] file system block size */
		f_frsize:       c.ulong,    /* [PSX] fundamental file system block size */
		f_iosize:       c.ulong,
		f_blocks:       fsblkcnt_t, /* [PSX] total number of blocks on file system in units of f_frsize */
		f_bfree:        fsblkcnt_t, /* [PSX] total number of free blocks */
		f_bavail:       fsblkcnt_t, /* [PSX] number of free blocks available to non-privileged process */
		f_bresvd:       fsblkcnt_t,
		f_files:        fsblkcnt_t, /* [PSX] total number of file serial numbers */
		f_ffree:        fsblkcnt_t, /* [PSX] total number of free file serial numbers */
		f_favail:       fsblkcnt_t, /* [PSX] number of file serial numbers available to non-privileged process */
		f_fresvd:       fsblkcnt_t,
		f_syncreads:    c.uint64_t,
		f_syncwrites:   c.uint64_t,
		f_asyncreads:   c.uint64_t,
		f_asyncwrites:  c.uint64_t,
		f_fsidx:        fsid_t,
		f_fsid:         c.ulong,    /* [PSX] file system ID */
		f_namemax:      c.ulong,    /* [PSX] maximum filename length */
		f_owner:        uid_t,
		f_spare:        [4]c.uint64_t,
		f_fstypename:   [_VFS_NAMELEN]c.char `fmt:"s,0"`,
		f_mntonname:    [_VFS_NAMELEN]c.char `fmt:"s,0"`,
		f_mntfromname:  [_VFS_NAMELEN]c.char `fmt:"s,0"`,
		f_mntfromlabel: [_VFS_NAMELEN]c.char `fmt:"s,0"`,
	}

	ST_RDONLY :: 0x00000001
	ST_NOSUID :: 0x00000008

} else when ODIN_OS == .Linux {

	fsblkcnt_t :: distinct c.uint64_t

	statvfs_t :: struct {
		f_bsize:    c.ulong,    /* [PSX] file system block size */
		f_frsize:   c.ulong,    /* [PSX] fundamental file system block size */
		f_blocks:   fsblkcnt_t, /* [PSX] total number of blocks on file system in units of f_frsize */
		f_bfree:    fsblkcnt_t, /* [PSX] total number of free blocks */
		f_bavail:   fsblkcnt_t, /* [PSX] number of free blocks available to non-privileged process */
		f_files:    fsblkcnt_t, /* [PSX] total number of file serial numbers */
		f_ffree:    fsblkcnt_t, /* [PSX] total number of free file serial numbers */
		f_favail:   fsblkcnt_t, /* [PSX] number of file serial numbers available to non-privileged process */
		f_fsid:     c.ulong,    /* [PSX] file system ID */
		_:          [2*size_of(c.int)-size_of(c.long)]byte,
		f_flag:     VFS_Flags,  /* [PSX] bit mask of f_flag values */
		f_namemax:  c.ulong,    /* [PSX] maximum filename length */
		f_type:     c.uint,
		__reserved: [5]c.int,
	}

	ST_RDONLY :: 0x00000001
	ST_NOSUID :: 0x00000002
}
