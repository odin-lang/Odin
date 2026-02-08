package unix

import "core:c"
foreign import libc "system:c"

// Get filesystem descriptor file entry

// Structure describing a mount table entry
Mntent :: struct {
	fsname:       cstring,
	dir:          cstring,
	type:         cstring,
	opts:         cstring,
	freq, passno: int,
}

@(default_calling_convention="c")
foreign libc {
	setmntent   :: proc(file: cstring, mode: cstring) -> c.FILE ---
	getmntent   :: proc(stream: c.FILE) -> ^Mntent ---
	addmntent   :: proc(stream: c.FILE, mnt: ^Mntent) -> int ---
	endmntent   :: proc(stream: c.FILE) -> int ---
	hasmntopt   :: proc(mnt: ^Mntent, opt: cstring) -> cstring ---
}
