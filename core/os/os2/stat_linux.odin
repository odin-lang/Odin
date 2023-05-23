//+private
package os2

import "core:time"
import "core:runtime"
import "core:strings"
import "core:sys/unix"
import "core:path/filepath"

_fstat :: proc(f: ^File, allocator: runtime.Allocator) -> (File_Info, Error) {
	return _fstat_internal(f.impl.fd, allocator)
}

_fstat_internal :: proc(fd: int, allocator: runtime.Allocator) -> (File_Info, Error) {
	s: unix.Stat
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
		is_dir = unix.S_ISDIR(s.mode),
		modification_time = time.Time {s.modified.seconds},
		access_time = time.Time {s.last_access.seconds},
		creation_time = time.Time{0}, // regular stat does not provide this
	}

	fi.name = filepath.base(fi.fullpath)
	return fi, nil
}

// NOTE: _stat and _lstat are using _fstat to avoid a race condition when populating fullpath
_stat :: proc(name: string, allocator: runtime.Allocator) -> (File_Info, Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	name_cstr := strings.clone_to_cstring(name, context.temp_allocator)

	fd := unix.sys_open(name_cstr, unix.O_RDONLY)
	if fd < 0 {
		return {}, _get_platform_error(fd)
	}
	defer unix.sys_close(fd)
	return _fstat_internal(fd, allocator)
}

_lstat :: proc(name: string, allocator: runtime.Allocator) -> (File_Info, Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	name_cstr := strings.clone_to_cstring(name, context.temp_allocator)

	fd := unix.sys_open(name_cstr, unix.O_RDONLY | unix.O_PATH | unix.O_NOFOLLOW)
	if fd < 0 {
		return {}, _get_platform_error(fd)
	}
	defer unix.sys_close(fd)
	return _fstat_internal(fd, allocator)
}

_same_file :: proc(fi1, fi2: File_Info) -> bool {
	return fi1.fullpath == fi2.fullpath
}
