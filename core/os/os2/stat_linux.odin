//+private
package os2

import "core:time"
import "base:runtime"
import "core:sys/unix"
import "core:path/filepath"

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

@private
Unix_File_Time :: struct {
	seconds:     i64,
	nanoseconds: i64,
}

@private
_Stat :: struct {
	device_id:     u64, // ID of device containing file
	serial:        u64, // File serial number
	nlink:         u64, // Number of hard links
	mode:          u32, // Mode of the file
	uid:           u32, // User ID of the file's owner
	gid:           u32, // Group ID of the file's group
	_padding:      i32, // 32 bits of padding
	rdev:          u64, // Device ID, if device
	size:          i64, // Size of the file, in bytes
	block_size:    i64, // Optimal bllocksize for I/O
	blocks:        i64, // Number of 512-byte blocks allocated

	last_access:   Unix_File_Time, // Time of last access
	modified:      Unix_File_Time, // Time of last modification
	status_change: Unix_File_Time, // Time of last status change

	_reserve1,
	_reserve2,
	_reserve3:     i64,
}


_fstat :: proc(f: ^File, allocator: runtime.Allocator) -> (File_Info, Error) {
	return _fstat_internal(f.impl.fd, allocator)
}

_fstat_internal :: proc(fd: int, allocator: runtime.Allocator) -> (File_Info, Error) {
	s: _Stat
	result := unix.sys_fstat(fd, &s)
	if result < 0 {
		return {}, _get_platform_error(result)
	}

	// TODO: As of Linux 4.11, the new statx syscall can retrieve creation_time
	fi := File_Info {
		fullpath = _get_full_path(fd, allocator),
		name = "",
		size = s.size,
		mode = 0,
		is_directory = S_ISDIR(s.mode),
		modification_time = time.Time {s.modified.seconds},
		access_time = time.Time {s.last_access.seconds},
		creation_time = time.Time{0}, // regular stat does not provide this
	}

	fi.name = filepath.base(fi.fullpath)
	return fi, nil
}

// NOTE: _stat and _lstat are using _fstat to avoid a race condition when populating fullpath
_stat :: proc(name: string, allocator: runtime.Allocator) -> (fi: File_Info, err: Error) {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := temp_cstring(name) or_return

	fd := unix.sys_open(name_cstr, _O_RDONLY)
	if fd < 0 {
		return {}, _get_platform_error(fd)
	}
	defer unix.sys_close(fd)
	return _fstat_internal(fd, allocator)
}

_lstat :: proc(name: string, allocator: runtime.Allocator) -> (fi: File_Info, err: Error) {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := temp_cstring(name) or_return

	fd := unix.sys_open(name_cstr, _O_RDONLY | _O_PATH | _O_NOFOLLOW)
	if fd < 0 {
		return {}, _get_platform_error(fd)
	}
	defer unix.sys_close(fd)
	return _fstat_internal(fd, allocator)
}

_same_file :: proc(fi1, fi2: File_Info) -> bool {
	return fi1.fullpath == fi2.fullpath
}
