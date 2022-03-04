//+private
package os2

import "core:fmt"
import "core:strings"
import "core:sys/unix"
import "core:path/filepath"

_Path_Separator      :: '/'
_Path_List_Separator :: ':'

_is_path_separator :: proc(c: byte) -> bool {
	return c == '/'
}

_mkdir :: proc(path: string, perm: File_Mode) -> Error {
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)
	//TODO file_mode
	return _ok_or_error(unix.sys_mkdir(path_cstr))
}

_mkdir_all :: proc(path: string, perm: File_Mode) -> Error {
	_mkdir_all_stat :: proc(path: string, s: ^OS_Stat, perm: File_Mode) -> Error {
		if len(path) == 0 {
			return nil
		}
	
		path := path[len(path)-1] == '/' ? path[:len(path)-1] : path
		dir, _ := filepath.split(path)

		if len(dir) == 0 {
			return _mkdir(path, perm)
		}

		dir_cstr := strings.clone_to_cstring(dir, context.temp_allocator)
		errno := int(unix.get_errno(unix.sys_stat(dir_cstr, s)))
		switch errno {
		case 0:
			if !S_ISDIR(s.mode) {
				return .Exist
			}
			return _mkdir(path, perm)
		case ENOENT:
			_mkdir_all_stat(dir, s, perm) or_return
			return _mkdir(path, perm)
		case:
			return _get_platform_error(errno)
		}
		unreachable()
	}
	// OS_Stat is fat. Make one and re-use it.
	s: OS_Stat = ---
	return _mkdir_all_stat(path, &s, perm)
}

_remove_all :: proc(path: string) -> Error {
	// TODO
	return nil
}

_getwd :: proc(allocator := context.allocator) -> (dir: string, err: Error) {
	// NOTE(tetra): I would use PATH_MAX here, but I was not able to find
	// an authoritative value for it across all systems.
	// The largest value I could find was 4096, so might as well use the page size.
	// NOTE(jason): Avoiding libc, so just use 4096 directly
	PATH_MAX :: 4096
	buf := make([dynamic]u8, PATH_MAX, allocator)
	for {
		#no_bounds_check res := unix.sys_getcwd(&buf[0], uint(len(buf)))

		if res >= 0 {
			return strings.string_from_nul_terminated_ptr(&buf[0], len(buf)), nil
		}
		if errno := int(unix.get_errno(res)); errno != ERANGE {
			return "", _get_platform_error(errno)
		}
		resize(&buf, len(buf)+PATH_MAX)
	}
	unreachable()
}

_setwd :: proc(dir: string) -> (err: Error) {
	dir_cstr := strings.clone_to_cstring(dir, context.temp_allocator)
	return _ok_or_error(unix.sys_chdir(dir_cstr))
}
