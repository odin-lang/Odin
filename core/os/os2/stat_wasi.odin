#+private
package os2

import "base:runtime"

import "core:sys/wasm/wasi"
import "core:time"

internal_stat :: proc(stat: wasi.filestat_t, fullpath: string) -> (fi: File_Info) {
	fi.fullpath = fullpath
	_, fi.name = split_path(fi.fullpath)

	fi.inode = u128(stat.ino)
	fi.size  = i64(stat.size)

	switch stat.filetype {
	case .BLOCK_DEVICE:                 fi.type = .Block_Device
	case .CHARACTER_DEVICE:             fi.type = .Character_Device
	case .DIRECTORY:                    fi.type = .Directory
	case .REGULAR_FILE:                 fi.type = .Regular
	case .SOCKET_DGRAM, .SOCKET_STREAM: fi.type = .Socket
	case .SYMBOLIC_LINK:                fi.type = .Symlink
	case .UNKNOWN:                      fi.type = .Undetermined
	case:                               fi.type = .Undetermined
	}

	fi.creation_time     = time.Time{_nsec=i64(stat.ctim)}
	fi.modification_time = time.Time{_nsec=i64(stat.mtim)}
	fi.access_time       = time.Time{_nsec=i64(stat.atim)}

	return
}

_fstat :: proc(f: ^File, allocator: runtime.Allocator) -> (fi: File_Info, err: Error) {
	if f == nil || f.impl == nil {
		err = .Invalid_File
		return
	}

	impl := (^File_Impl)(f.impl)

	stat, _err := wasi.fd_filestat_get(__fd(f))
	if _err != nil {
		err = _get_platform_error(_err)
		return
	}

	fullpath := clone_string(impl.name, allocator) or_return
	return internal_stat(stat, fullpath), nil
}

_stat :: proc(name: string, allocator: runtime.Allocator) -> (fi: File_Info, err: Error) {
	if name == "" {
		err = .Invalid_Path
		return
	}

	dir_fd, relative, ok := match_preopen(name)
	if !ok {
		err = .Invalid_Path
		return
	}

	stat, _err := wasi.path_filestat_get(dir_fd, {.SYMLINK_FOLLOW}, relative)
	if _err != nil {
		err = _get_platform_error(_err)
		return
	}

	// NOTE: wasi doesn't really do full paths afact.
	fullpath := clone_string(name, allocator) or_return
	return internal_stat(stat, fullpath), nil
}

_lstat :: proc(name: string, allocator: runtime.Allocator) -> (fi: File_Info, err: Error) {
	if name == "" {
		err = .Invalid_Path
		return
	}

	dir_fd, relative, ok := match_preopen(name)
	if !ok {
		err = .Invalid_Path
		return
	}

	stat, _err := wasi.path_filestat_get(dir_fd, {}, relative)
	if _err != nil {
		err = _get_platform_error(_err)
		return
	}

	// NOTE: wasi doesn't really do full paths afact.
	fullpath := clone_string(name, allocator) or_return
	return internal_stat(stat, fullpath), nil
}

_same_file :: proc(fi1, fi2: File_Info) -> bool {
	return fi1.fullpath == fi2.fullpath
}
