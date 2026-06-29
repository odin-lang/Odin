#+private
package os

import "core:time"
import "base:runtime"
import "core:sys/linux"

_fstat :: proc(f: ^File, allocator: runtime.Allocator) -> (File_Info, Error) {
	impl := (^File_Impl)(f.impl)
	return _fstat_internal(impl.fd, allocator)
}

_fstat_internal :: proc(fd: linux.Fd, allocator: runtime.Allocator) -> (fi: File_Info, err: Error) {
	s: linux.Statx
	errno := linux.statx(fd, "", {.EMPTY_PATH}, {.TYPE, .MODE, .ATIME, .MTIME, .CTIME, .INO, .SIZE}, &s)
	if errno != .NONE {
		return {}, _get_platform_error(errno)
	}
	type := File_Type.Regular
	switch s.mode & linux.S_IFMT {
	case linux.S_IFBLK:  type = .Block_Device
	case linux.S_IFCHR:  type = .Character_Device
	case linux.S_IFDIR:  type = .Directory
	case linux.S_IFIFO:  type = .Named_Pipe
	case linux.S_IFLNK:  type = .Symlink
	case linux.S_IFREG:  type = .Regular
	case linux.S_IFSOCK: type = .Socket
	}
	mode := transmute(Permissions)(0o7777 & transmute(u32)s.mode)

	fi = File_Info {
		fullpath          = _get_full_path(fd, allocator) or_return,
		name              = "",
		inode             = u128(u64(s.ino)),
		size              = i64(s.size),
		mode              = mode,
		type              = type,
		modification_time = time.Time {i64(s.mtime.sec) * i64(time.Second) + i64(s.mtime.nsec)},
		access_time       = time.Time {i64(s.atime.sec) * i64(time.Second) + i64(s.atime.nsec)},
		creation_time     = time.Time {i64(s.btime.sec) * i64(time.Second) + i64(s.btime.nsec)},
	}
	fi.creation_time = fi.modification_time
	_, fi.name = split_path(fi.fullpath)
	return
}

// NOTE: _stat and _lstat are using _fstat to avoid a race condition when populating fullpath
_stat :: proc(name: string, allocator: runtime.Allocator) -> (fi: File_Info, err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })
	name_cstr := clone_to_cstring(name, temp_allocator) or_return

	fd, errno := linux.open(name_cstr, {})
	if errno != .NONE {
		return {}, _get_platform_error(errno)
	}
	defer linux.close(fd)
	return _fstat_internal(fd, allocator)
}

_lstat :: proc(name: string, allocator: runtime.Allocator) -> (fi: File_Info, err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({ allocator })
	name_cstr := clone_to_cstring(name, temp_allocator) or_return

	fd, errno := linux.open(name_cstr, {.PATH, .NOFOLLOW})
	if errno != .NONE {
		return {}, _get_platform_error(errno)
	}
	defer linux.close(fd)
	return _fstat_internal(fd, allocator)
}

_same_file :: proc(fi1, fi2: File_Info) -> bool {
	return fi1.fullpath == fi2.fullpath
}

_is_reserved_name :: proc(path: string) -> bool {
	return false
}
