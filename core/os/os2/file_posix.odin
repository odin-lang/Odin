#+private
#+build darwin, netbsd, freebsd, openbsd
package os2

import "base:runtime"

import "core:io"
import "core:c"
import "core:time"
import "core:sys/posix"

// Most implementations will EINVAL at some point when doing big writes.
// In practice a read/write call would probably never read/write these big buffers all at once,
// which is why the number of bytes is returned and why there are procs that will call this in a
// loop for you.
// We set a max of 1GB to keep alignment and to be safe.
MAX_RW :: 1 << 30

File_Impl :: struct {
	file:  File,
	name:  string,
	cname: cstring,
	fd:    posix.FD,
	allocator: runtime.Allocator,
}

@(init)
init_std_files :: proc() {
	new_std :: proc(impl: ^File_Impl, fd: posix.FD, name: cstring) -> ^File {
		impl.file.impl = impl
		impl.fd = fd
		impl.allocator = runtime.nil_allocator()
		impl.cname = name
		impl.name  = string(name)
		impl.file.stream = {
			data = impl,
			procedure = _file_stream_proc,
		}
		impl.file.fstat = _fstat
		return &impl.file
	}

	@(static) files: [3]File_Impl
	stdin  = new_std(&files[0], posix.STDIN_FILENO,  "/dev/stdin")
	stdout = new_std(&files[1], posix.STDOUT_FILENO, "/dev/stdout")
	stderr = new_std(&files[2], posix.STDERR_FILENO, "/dev/stderr")
}

_open :: proc(name: string, flags: File_Flags, perm: int) -> (f: ^File, err: Error) {
	if name == "" {
		err = .Invalid_Path
		return
	}

	sys_flags := posix.O_Flags{.NOCTTY, .CLOEXEC}
	
	if .Write in flags {
		if .Read in flags {
			sys_flags += {.RDWR}
		} else {
			sys_flags += {.WRONLY}
		}
	}

	if .Append      in flags { sys_flags += {.APPEND} }
	if .Create      in flags { sys_flags += {.CREAT} }
	if .Excl        in flags { sys_flags += {.EXCL} }
	if .Sync        in flags { sys_flags += {.DSYNC} }
	if .Trunc       in flags { sys_flags += {.TRUNC} }
	if .Inheritable in flags { sys_flags -= {.CLOEXEC} }

	TEMP_ALLOCATOR_GUARD()
	cname := temp_cstring(name)

	fd := posix.open(cname, sys_flags, transmute(posix.mode_t)posix._mode_t(perm))
	if fd < 0 {
		err = _get_platform_error()
		return
	}

	return _new_file(uintptr(fd), name, file_allocator())
}

_new_file :: proc(handle: uintptr, name: string, allocator: runtime.Allocator) -> (f: ^File, err: Error) {
	if name == "" {
		err = .Invalid_Path
		return
	} else if handle == ~uintptr(0) {
		err = .Invalid_File
		return
	}

	crname := _posix_absolute_path(posix.FD(handle), name, allocator) or_return
	rname  := string(crname)

	f = __new_file(posix.FD(handle), allocator)
	impl := (^File_Impl)(f.impl)
	impl.name  = rname
	impl.cname = crname

	return f, nil
}

__new_file :: proc(handle: posix.FD, allocator: runtime.Allocator) -> ^File {
	impl := new(File_Impl, allocator)
	impl.file.impl = impl
	impl.fd = posix.FD(handle)
	impl.allocator = allocator
	impl.file.stream = {
		data = impl,
		procedure = _file_stream_proc,
	}
	impl.file.fstat = _fstat
	return &impl.file
}

_clone :: proc(f: ^File) -> (clone: ^File, err: Error) {
	if f == nil || f.impl == nil {
		err = .Invalid_Pointer
		return
	}

	impl := (^File_Impl)(f.impl)

	fd := posix.dup(impl.fd)
	if fd <= 0 {
		err = _get_platform_error()
		return
	}
	defer if err != nil { posix.close(fd) }

	clone = __new_file(fd, file_allocator())	
	clone_impl := (^File_Impl)(clone.impl)
	clone_impl.cname = clone_to_cstring(impl.name, file_allocator()) or_return
	clone_impl.name  = string(clone_impl.cname)

	return
}

_close :: proc(f: ^File_Impl) -> (err: Error) {
	if f == nil { return nil }

	if posix.close(f.fd) != .OK {
		err = _get_platform_error()
	}

	allocator := f.allocator

	delete(f.cname, allocator)
	free(f, allocator)
	return
}

_fd :: proc(f: ^File) -> uintptr {
	return uintptr(__fd(f))
}

__fd :: proc(f: ^File) -> posix.FD {
	if f != nil && f.impl != nil {
		return (^File_Impl)(f.impl).fd
	}
	return -1
}

_name :: proc(f: ^File) -> string {
	if f != nil && f.impl != nil {
		return (^File_Impl)(f.impl).name
	}
	return ""
}

_sync :: proc(f: ^File) -> Error {
	if posix.fsync(__fd(f)) != .OK {
		return _get_platform_error()
	}
	return nil
}

_truncate :: proc(f: ^File, size: i64) -> Error {
	if posix.ftruncate(__fd(f), posix.off_t(size)) != .OK {
		return _get_platform_error()
	}
	return nil
}

_remove :: proc(name: string) -> Error {
	TEMP_ALLOCATOR_GUARD()
	cname := temp_cstring(name)
	if posix.remove(cname) != 0 {
		return _get_platform_error()
	}
	return nil
}

_rename :: proc(old_path, new_path: string) -> Error {
	TEMP_ALLOCATOR_GUARD()
	cold := temp_cstring(old_path)
	cnew := temp_cstring(new_path)
	if posix.rename(cold, cnew) != 0 {
		return _get_platform_error()
	}
	return nil
}

_link :: proc(old_name, new_name: string) -> Error {
	TEMP_ALLOCATOR_GUARD()
	cold := temp_cstring(old_name)
	cnew := temp_cstring(new_name)
	if posix.link(cold, cnew) != .OK {
		return _get_platform_error()
	}
	return nil
}

_symlink :: proc(old_name, new_name: string) -> Error {
	TEMP_ALLOCATOR_GUARD()
	cold := temp_cstring(old_name)
	cnew := temp_cstring(new_name)
	if posix.symlink(cold, cnew) != .OK {
		return _get_platform_error()
	}
	return nil
}

_read_link :: proc(name: string, allocator: runtime.Allocator) -> (s: string, err: Error) {
	TEMP_ALLOCATOR_GUARD()
	cname := temp_cstring(name)

	buf: [dynamic]byte
	buf.allocator = allocator
	defer if err != nil { delete(buf) }

	// Loop this because the file might've grown between lstat() and readlink().
	for {
		stat: posix.stat_t
		if posix.lstat(cname, &stat) != .OK {
			err = _get_platform_error()
			return
		}

		bufsiz := int(stat.st_size + 1 if stat.st_size > 0 else posix.PATH_MAX)

		if bufsiz == len(buf) {
			bufsiz *= 2
		}

		// Overflow.
		if bufsiz <= 0 {
			err = Platform_Error(posix.Errno.E2BIG)
			return
		}

		resize(&buf, bufsiz) or_return

		size := posix.readlink(cname, raw_data(buf), uint(bufsiz))
		if size < 0 {
			err = _get_platform_error()
			return
		}

		// File has probably grown between lstat() and readlink().
		if size == bufsiz {
			continue
		}

		s = string(buf[:size])
		return
	}
}

_chdir :: proc(name: string) -> Error {
	TEMP_ALLOCATOR_GUARD()
	cname := temp_cstring(name)
	if posix.chdir(cname) != .OK {
		return _get_platform_error()
	}
	return nil
}

_fchdir :: proc(f: ^File) -> Error {
	if posix.fchdir(__fd(f)) != .OK {
		return _get_platform_error()
	}
	return nil
}

_fchmod :: proc(f: ^File, mode: int) -> Error {
	if posix.fchmod(__fd(f), transmute(posix.mode_t)posix._mode_t(mode)) != .OK {
		return _get_platform_error()
	}
	return nil
}

_chmod :: proc(name: string, mode: int) -> Error {
	TEMP_ALLOCATOR_GUARD()
	cname := temp_cstring(name)
	if posix.chmod(cname, transmute(posix.mode_t)posix._mode_t(mode)) != .OK {
		return _get_platform_error()
	}
	return nil
}

_fchown :: proc(f: ^File, uid, gid: int) -> Error {
	if posix.fchown(__fd(f), posix.uid_t(uid), posix.gid_t(gid)) != .OK {
		return _get_platform_error()
	}
	return nil
}

_chown :: proc(name: string, uid, gid: int) -> Error {
	TEMP_ALLOCATOR_GUARD()
	cname := temp_cstring(name)
	if posix.chown(cname, posix.uid_t(uid), posix.gid_t(gid)) != .OK {
		return _get_platform_error()
	}
	return nil
}

_lchown :: proc(name: string, uid, gid: int) -> Error {
	TEMP_ALLOCATOR_GUARD()
	cname := temp_cstring(name)
	if posix.lchown(cname, posix.uid_t(uid), posix.gid_t(gid)) != .OK {
		return _get_platform_error()
	}
	return nil
}

_chtimes :: proc(name: string, atime, mtime: time.Time) -> Error {
	times := [2]posix.timeval{
		{
			tv_sec  = posix.time_t(atime._nsec/1e9),           /* seconds */
			tv_usec = posix.suseconds_t(atime._nsec%1e9/1000), /* microseconds */
		},
		{
			tv_sec  = posix.time_t(mtime._nsec/1e9),           /* seconds */
			tv_usec = posix.suseconds_t(mtime._nsec%1e9/1000), /* microseconds */
		},
	}

	TEMP_ALLOCATOR_GUARD()
	cname := temp_cstring(name)

	if posix.utimes(cname, &times) != .OK {
		return _get_platform_error()
	}
	return nil
}

_fchtimes :: proc(f: ^File, atime, mtime: time.Time) -> Error {
	times := [2]posix.timespec{
		{
			tv_sec  = posix.time_t(atime._nsec/1e9), /* seconds */
			tv_nsec = c.long(atime._nsec%1e9),       /* nanoseconds */
		},
		{
			tv_sec  = posix.time_t(mtime._nsec/1e9), /* seconds */
			tv_nsec = c.long(mtime._nsec%1e9),       /* nanoseconds */
		},
	}

	if posix.futimens(__fd(f), &times) != .OK {
		return _get_platform_error()
	}
	return nil
}

_exists :: proc(path: string) -> bool {
	TEMP_ALLOCATOR_GUARD()
	cpath := temp_cstring(path)
	return posix.access(cpath) == .OK
}

_file_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	f  := (^File_Impl)(stream_data)
	fd := f.fd

	switch mode {
	case .Read:
		if len(p) <= 0 {
			return
		}

		to_read := uint(min(len(p), MAX_RW))
		n = i64(posix.read(fd, raw_data(p), to_read))
		switch {
		case n == 0:
			err = .EOF
		case n < 0:
			err = .Unknown
		}
		return

	case .Read_At:
		if len(p) <= 0 {
			return
		}

		if offset < 0 {
			err = .Invalid_Offset
			return
		}

		to_read := uint(min(len(p), MAX_RW))
		n = i64(posix.pread(fd, raw_data(p), to_read, posix.off_t(offset)))
		switch {
		case n == 0:
			err = .EOF
		case n < 0:
			err = .Unknown
		}
		return

	case .Write:
		p := p
		for len(p) > 0 {
			to_write := uint(min(len(p), MAX_RW))
			if _n := i64(posix.write(fd, raw_data(p), to_write)); _n <= 0 {
				err = .Unknown
				return
			} else {
				p = p[_n:]
				n += _n
			}
		}
		return

	case .Write_At:
		p := p
		offset := offset

		if offset < 0 {
			err = .Invalid_Offset
			return
		}

		for len(p) > 0 {
			to_write := uint(min(len(p), MAX_RW))
			if _n := i64(posix.pwrite(fd, raw_data(p), to_write, posix.off_t(offset))); _n <= 0 {
				err = .Unknown
				return
			} else {
				p = p[_n:]
				n += _n
				offset += _n
			}
		}
		return

	case .Seek:
		#assert(int(posix.Whence.SET) == int(io.Seek_From.Start))
		#assert(int(posix.Whence.CUR) == int(io.Seek_From.Current))
		#assert(int(posix.Whence.END) == int(io.Seek_From.End))

		switch whence {
		case .Start, .Current, .End:
			break
		case:
			err = .Invalid_Whence
			return
		}

		n = i64(posix.lseek(fd, posix.off_t(offset), posix.Whence(whence)))
		if n < 0 {
			#partial switch posix.get_errno() {
			case .EINVAL:
				err = .Invalid_Offset
			case:
				err = .Unknown
			}
		}
		return

	case .Size:
		stat: posix.stat_t
		if posix.fstat(fd, &stat) != .OK {
			err = .Unknown
			return
		}

		n = i64(stat.st_size)
		return

	case .Flush:
		ferr := _sync(&f.file)
		err   = error_to_io_error(ferr)
		return

	case .Close, .Destroy:
		ferr := _close(f)
		err   = error_to_io_error(ferr)
		return

	case .Query:
		return io.query_utility({.Read, .Read_At, .Write, .Write_At, .Seek, .Size, .Flush, .Close, .Destroy, .Query})

	case:
		return 0, .Empty
	}
}
