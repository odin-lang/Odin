//+private
//+build darwin, netbsd, freebsd, openbsd
package os2

import "base:runtime"

import "core:path/filepath"
import "core:sys/posix"
import "core:time"

internal_stat :: proc(stat: posix.stat_t, fullpath: string) -> (fi: File_Info) {
	fi.fullpath = fullpath
	fi.name = filepath.base(fi.fullpath)

	fi.inode = u128(stat.st_ino)
	fi.size = i64(stat.st_size)

	fi.mode = int(transmute(posix._mode_t)(stat.st_mode - posix.S_IFMT))

	fi.type = .Undetermined
	switch {
	case posix.S_ISBLK(stat.st_mode):
		fi.type = .Block_Device
	case posix.S_ISCHR(stat.st_mode):
		fi.type = .Character_Device
	case posix.S_ISDIR(stat.st_mode):
		fi.type = .Directory
	case posix.S_ISFIFO(stat.st_mode):
		fi.type = .Named_Pipe
	case posix.S_ISLNK(stat.st_mode):
		fi.type = .Symlink
	case posix.S_ISREG(stat.st_mode):
		fi.type = .Regular
	case posix.S_ISSOCK(stat.st_mode):
		fi.type = .Socket
	}

	fi.creation_time = timespec_time(stat.st_birthtimespec)
	fi.modification_time = timespec_time(stat.st_mtim)
	fi.access_time = timespec_time(stat.st_atim)

	timespec_time :: proc(t: posix.timespec) -> time.Time {
		return time.Time{_nsec = i64(t.tv_sec) * 1e9 + i64(t.tv_nsec)}
	}

	return
}

_fstat :: proc(f: ^File, allocator: runtime.Allocator) -> (fi: File_Info, err: Error) {
	if f == nil || f.impl == nil {
		err = .Invalid_File
		return
	}

	impl := (^File_Impl)(f.impl)

	stat: posix.stat_t
	if posix.fstat(impl.fd, &stat) != .OK {
		err = _get_platform_error()
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

	assert(!is_temp(allocator))
	TEMP_ALLOCATOR_GUARD()
	cname := temp_cstring(name) or_return

	rcname := posix.realpath(cname)
	if rcname == nil {
		err = .Invalid_Path
		return
	}
	defer posix.free(rcname)

	stat: posix.stat_t
	if posix.stat(rcname, &stat) != .OK {
		err = _get_platform_error()
		return
	}

	fullpath := clone_string(string(rcname), allocator) or_return
	return internal_stat(stat, fullpath), nil
}

_lstat :: proc(name: string, allocator: runtime.Allocator) -> (fi: File_Info, err: Error) {
	if name == "" {
		err = .Invalid_Path
		return
	}

	TEMP_ALLOCATOR_GUARD(ignore=is_temp(allocator))

	// NOTE: can't use realpath here because it tries to resolve symlinks.

	// NOTE: This might not be correct when given "/symlink/foo.txt",
	// you would want that to resolve "/symlink", but not resolve "foo.txt".

	fullpath := filepath.clean(name, temp_allocator())
	assert(len(fullpath) > 0)
	switch {
	case fullpath[0] == '/':
		// nothing.
	case fullpath == ".":
		fullpath = getwd(temp_allocator()) or_return
	case len(fullpath) > 1 && fullpath[0] == '.' && fullpath[1] == '/':
		fullpath = fullpath[2:]
		fallthrough
	case:
		fullpath = concatenate({
			getwd(temp_allocator()) or_return,
			"/",
			fullpath,
		}, temp_allocator()) or_return
	}

	stat: posix.stat_t
	if posix.lstat(temp_cstring(fullpath), &stat) != .OK {
		err = _get_platform_error()
		return
	}

	fullpath = clone_string(fullpath, allocator) or_return
	return internal_stat(stat, fullpath), nil
}

_same_file :: proc(fi1, fi2: File_Info) -> bool {
	return fi1.fullpath == fi2.fullpath
}
