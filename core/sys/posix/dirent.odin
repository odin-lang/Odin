#+build darwin, linux, freebsd, openbsd, netbsd
package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// dirent.h - format of directory entries

foreign lib {
	/*
	can be used as the comparison function for the scandir() function to sort the directory entries, d1 and d2, into alphabetical order.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/scandir.html ]]
	*/
	@(link_name=LALPHASORT)
	alphasort :: proc([^]^dirent, [^]^dirent) -> c.int ---

	/*
	Scan the directory dir, calling the function referenced by sel on each directory entry.

	Example:
		list: [^]^posix.dirent
		ret := posix.scandir(#directory, &list, nil, posix.alphasort)
		if ret < 0 {
			panic(string(posix.strerror(posix.errno())))
		}
		defer posix.free(list)

		entries := list[:ret]
		for entry in entries {
			log.info(entry)
			posix.free(entry)
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/scandir.html ]]
	*/
	@(link_name=LSCANDIR)
	scandir :: proc(
		dir:      cstring,
		sel:      ^[^]^dirent,
		filter:   proc "c" (^dirent) -> b32 = nil,
		compar:   proc "c" ([^]^dirent, [^]^dirent) -> c.int = alphasort,
	) -> c.int ---

	/*
	Close the directory stream referred to by the argument dirp.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/closedir.html ]]
	*/
	closedir :: proc(dirp: DIR) -> result ---

	/*
	Equivalent to the opendir() function except that the directory is specified by a file descriptor
	rather than by a name.
	The file offset associated with the file descriptor at the time of the call determines
	which entries are returned.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/fdopendir.html ]]
	*/
	@(link_name="fdopendir" + INODE_SUFFIX)
	fdopendir :: proc(dirp: FD) -> DIR ---

	/*
	Open a directory stream corresponding to the directory named by the dirname argument.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/fdopendir.html ]]
	*/
	@(link_name=LOPENDIR)
	opendir :: proc(path: cstring) -> DIR ---

	/*
	Returns a pointer to a structure representing the directory entry at the current position
	in the directory stream specified by the argument dirp, and position the directory stream at
	the next entry.

	Returns nil when the end is reached or an error occurred (which sets errno).

	Example:
		posix.set_errno(.NONE)
		entry := posix.readdir(dirp)
		if entry == nil {
			if errno := posix.errno(); errno != .NONE {
				panic(string(posix.strerror(errno)))
			} else {
				fmt.println("end of directory stream")
			}
		} else {
			fmt.println(entry)
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/readdir.html ]]
	*/
	@(link_name=LREADDIR)
	readdir :: proc(dirp: DIR) -> ^dirent ---

	/*
	Reset the position of the directory stream to which dirp refers to the beginning of the directory.
	It shall also cause the directory stream to refer to the current state of the corresponding directory,
	as a call to opendir() would have done. 

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/rewinddir.html ]]
	*/
	@(link_name="rewinddir" + INODE_SUFFIX)
	rewinddir :: proc(dirp: DIR) ---

	/*
	The seekdir() function shall set the position of the next readdir() operation on the directory
	stream specified by dirp to the position specified by loc.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/seekdir.html ]]
	*/
	@(link_name="seekdir" + INODE_SUFFIX)
	seekdir :: proc(dirp: DIR, loc: dir_loc) ---

	/*
	The telldir() function shall obtain the current location associated with the directory stream
	specified by dirp.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/telldir.html ]]
	*/
	@(link_name="telldir" + INODE_SUFFIX)
	telldir :: proc(dirp: DIR) -> dir_loc ---

	// deprecated.
	// readdir_r :: proc(DIR, ^dirent, ^^dirent) -> c.int ---
}

DIR :: distinct rawptr

dir_loc :: c.long

// NOTE: `d_type` is not a POSIX standard field, but all targets we support add it.
D_Type :: enum c.uint8_t {
	UNKNOWN = 0,
	FIFO    = 1,
	CHR     = 2,
	DIR     = 4,
	BLK     = 6,
	REG     = 8,
	LNK     = 10,
	SOCK    = 12,
	WHT     = 14,
}

when ODIN_OS == .NetBSD {
	@(private) LALPHASORT :: "__alphasort30"
	@(private) LSCANDIR   :: "__scandir30"
	@(private) LOPENDIR   :: "__opendir30"
	@(private) LREADDIR   :: "__readdir30"

	/*
	Return a file descriptor referring to the same directory as the dirp argument.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/dirfd.html ]]
	*/
	dirfd :: proc "c" (dirp: DIR) -> FD {
		_dirdesc :: struct {
			dd_fd: FD,

			// more stuff...
		}

		return (^_dirdesc)(dirp).dd_fd
	}

} else {
	@(private) LALPHASORT :: "alphasort" + INODE_SUFFIX
	@(private) LSCANDIR   :: "scandir"   + INODE_SUFFIX
	@(private) LOPENDIR   :: "opendir"   + INODE_SUFFIX
	@(private) LREADDIR   :: "readdir"   + INODE_SUFFIX

	foreign lib {
		/*
		Return a file descriptor referring to the same directory as the dirp argument.

		[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/dirfd.html ]]
		*/
		dirfd :: proc(dirp: DIR) -> FD ---
	}
}

when ODIN_OS == .Darwin {

	dirent :: struct {
		d_ino:     ino_t,                    /* [PSX] file number of entry */
		d_seekoff: c.uint64_t,               /* seek offset */
		d_reclen:  c.uint16_t,               /* length of this record */
		d_namelen: c.uint16_t,               /* length of string in d_name */
		d_type:    D_Type,                   /* file type  */
		d_name:    [1024]c.char `fmt:"s,0"`, /* [PSX] entry name */
	}

} else when ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD {

	dirent :: struct {
		d_ino:     ino_t,                   /* [PSX] file number of entry */
		d_off:     off_t,                   /* directory offset of the next entry */
		d_reclen:  c.uint16_t,              /* length of this record */
		d_type:    D_Type,                  /* file type  */
		d_namelen: c.uint8_t,               /* length of string in d_name */
		d_pad0:    c.uint32_t,
		d_name:    [256]c.char `fmt:"s,0"`, /* [PSX] entry name */
	}

} else when ODIN_OS == .NetBSD {

	dirent :: struct {
		d_ino:     ino_t,                   /* [PSX] file number of entry */
		d_reclen:  c.uint16_t,              /* length of this record */
		d_namelen: c.uint16_t,              /* length of string in d_name */
		d_type:    D_Type,                  /* file type  */
		d_name:    [512]c.char `fmt:"s,0"`, /* [PSX] entry name */
	}

} else when ODIN_OS == .Linux {

		dirent :: struct {
			d_ino:    u64,                     /* [PSX] file number of entry */
			d_off:    i64,                     /* directory offset of the next entry */
			d_reclen: u16,                     /* length of this record */
			d_type:   D_Type,                  /* file type  */
			d_name:   [256]c.char `fmt:"s,0"`, /* [PSX] entry name */
		}

}
