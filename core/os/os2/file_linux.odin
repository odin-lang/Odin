//+private
package os2

import "core:io"
import "core:time"
import "base:runtime"
import "core:sys/linux"

_File :: struct {
	name: string,
	fd: linux.Fd,
	allocator: runtime.Allocator,
}

_stdin : File = {
	impl = {
		name = "/proc/self/fd/0",
		fd = 0,
		allocator = _file_allocator(),
	},
	stream = {
		procedure = _file_stream_proc,
	},
}
_stdout : File = {
	impl = {
		name = "/proc/self/fd/1",
		fd = 1,
		allocator = _file_allocator(),
	},
	stream = {
		procedure = _file_stream_proc,
	},
}
_stderr : File = {
	impl = {
		name = "/proc/self/fd/2",
		fd = 2,
		allocator = _file_allocator(),
	},
	stream = {
		procedure = _file_stream_proc,
	},
}

@init
_standard_stream_init :: proc() {
	// cannot define these manually because cyclic reference
	_stdin.stream.data = &_stdin
	_stdout.stream.data = &_stdout
	_stderr.stream.data = &_stderr

	stdin  = &_stdin
	stdout = &_stdout
	stderr = &_stderr
}

_file_allocator :: proc() -> runtime.Allocator {
	return heap_allocator()
}

_open :: proc(name: string, flags: File_Flags, perm: File_Mode) -> (f: ^File, err: Error) {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := temp_cstring(name) or_return

	// Just default to using O_NOCTTY because needing to open a controlling
	// terminal would be incredibly rare. This has no effect on files while
	// allowing us to open serial devices.
	sys_flags: linux.Open_Flags = {.NOCTTY}
	switch flags & O_RDONLY|O_WRONLY|O_RDWR {
	case O_RDONLY:
	case O_WRONLY: sys_flags += {.WRONLY}
	case O_RDWR:   sys_flags += {.RDWR}
	}

	if .Append in flags        { sys_flags += {.APPEND} }
	if .Create in flags        { sys_flags += {.CREAT} }
	if .Excl in flags          { sys_flags += {.EXCL} }
	if .Sync in flags          { sys_flags += {.DSYNC} }
	if .Trunc in flags         { sys_flags += {.TRUNC} }
	if .Close_On_Exec in flags { sys_flags += {.CLOEXEC} }

	fd, errno := linux.open(name_cstr, sys_flags, transmute(linux.Mode)(u32(perm)))
	if errno != .NONE {
		return nil, _get_platform_error(errno)
	}

	return _new_file(uintptr(fd), name), nil
}

_new_file :: proc(fd: uintptr, _: string = "") -> ^File {
	file := new(File, file_allocator())
	_construct_file(file, fd, "")
	return file
}

_construct_file :: proc(file: ^File, fd: uintptr, _: string = "") {
	file^ = {
		impl = {
			fd = linux.Fd(fd),
			allocator = file_allocator(),
			name = _get_full_path(file.impl.fd, file.impl.allocator),
		},
		stream = {
			data = file,
			procedure = _file_stream_proc,
		},
	}
}

_destroy :: proc(f: ^File) -> Error {
	if f == nil {
		return nil
	}
	delete(f.impl.name, f.impl.allocator)
	free(f, f.impl.allocator)
	return nil
}


_close :: proc(f: ^File) -> Error {
	if f == nil {
		return nil
	}
	errno := linux.close(f.impl.fd)
	if errno == .EBADF { // avoid possible double free
		return _get_platform_error(errno)
	}
	_destroy(f)
	return _get_platform_error(errno)
}

_fd :: proc(f: ^File) -> uintptr {
	if f == nil {
		return ~uintptr(0)
	}
	return uintptr(f.impl.fd)
}

_name :: proc(f: ^File) -> string {
	return f.impl.name if f != nil else ""
}

_seek :: proc(f: ^File, offset: i64, whence: io.Seek_From) -> (ret: i64, err: Error) {
	n, errno := linux.lseek(f.impl.fd, offset, linux.Seek_Whence(whence))
	if errno != .NONE {
		return -1, _get_platform_error(errno)
	}
	return n, nil
}

_read :: proc(f: ^File, p: []byte) -> (i64, Error) {
	if len(p) == 0 {
		return 0, nil
	}
	n, errno := linux.read(f.impl.fd, p[:])
	if errno != .NONE {
		return -1, _get_platform_error(errno)
	}
	return i64(n), n == 0 ? io.Error.EOF : nil
}

_read_at :: proc(f: ^File, p: []byte, offset: i64) -> (i64, Error) {
	if offset < 0 {
		return 0, .Invalid_Offset
	}

	n, errno := linux.pread(f.impl.fd, p[:], offset)
	if errno != .NONE {
		return -1, _get_platform_error(errno)
	}
	if n == 0 {
		return 0, .EOF
	}
	return i64(n), nil
}

_write :: proc(f: ^File, p: []byte) -> (i64, Error) {
	if len(p) == 0 {
		return 0, nil
	}
	n, errno := linux.write(f.impl.fd, p[:])
	if errno != .NONE {
		return -1, _get_platform_error(errno)
	}
	return i64(n), nil
}

_write_at :: proc(f: ^File, p: []byte, offset: i64) -> (i64, Error) {
	if offset < 0 {
		return 0, .Invalid_Offset
	}

	n, errno := linux.pwrite(f.impl.fd, p[:], offset)
	if errno != .NONE {
		return -1, _get_platform_error(errno)
	}
	return i64(n), nil
}

_file_size :: proc(f: ^File) -> (n: i64, err: Error) {
	s: linux.Stat = ---
	errno := linux.fstat(f.impl.fd, &s)
	if errno != .NONE {
		return -1, _get_platform_error(errno)
	}
	return i64(s.size), nil
}

_sync :: proc(f: ^File) -> Error {
	return _get_platform_error(linux.fsync(f.impl.fd))
}

_flush :: proc(f: ^File) -> Error {
	return _get_platform_error(linux.fsync(f.impl.fd))
}

_truncate :: proc(f: ^File, size: i64) -> Error {
	return _get_platform_error(linux.ftruncate(f.impl.fd, size))
}

_remove :: proc(name: string) -> Error {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := temp_cstring(name) or_return

	fd, errno := linux.open(name_cstr, {.NOFOLLOW})
	#partial switch (errno) {
	case .ELOOP: /* symlink */
	case .NONE:
		defer linux.close(fd)
		if _is_dir_fd(fd) {
			return _get_platform_error(linux.rmdir(name_cstr))
		}
	case:
		return _get_platform_error(errno)
	}

	return _get_platform_error(linux.unlink(name_cstr))
}

_rename :: proc(old_name, new_name: string) -> Error {
	TEMP_ALLOCATOR_GUARD()
	old_name_cstr := temp_cstring(old_name) or_return
	new_name_cstr := temp_cstring(new_name) or_return

	return _get_platform_error(linux.rename(old_name_cstr, new_name_cstr))
}

_link :: proc(old_name, new_name: string) -> Error {
	TEMP_ALLOCATOR_GUARD()
	old_name_cstr := temp_cstring(old_name) or_return
	new_name_cstr := temp_cstring(new_name) or_return

	return _get_platform_error(linux.link(old_name_cstr, new_name_cstr))
}

_symlink :: proc(old_name, new_name: string) -> Error {
	TEMP_ALLOCATOR_GUARD()
	old_name_cstr := temp_cstring(old_name) or_return
	new_name_cstr := temp_cstring(new_name) or_return
	return _get_platform_error(linux.symlink(old_name_cstr, new_name_cstr))
}

_read_link_cstr :: proc(name_cstr: cstring, allocator: runtime.Allocator) -> (string, Error) {
	bufsz : uint = 256
	buf := make([]byte, bufsz, allocator)
	for {
		sz, errno := linux.readlink(name_cstr, buf[:])
		if errno != .NONE {
			delete(buf, allocator)
			return "", _get_platform_error(errno)
		} else if sz == int(bufsz) {
			bufsz *= 2
			delete(buf, allocator)
			buf = make([]byte, bufsz, allocator)
		} else {
			return string(buf[:sz]), nil
		}
	}
}

_read_link :: proc(name: string, allocator: runtime.Allocator) -> (s: string, e: Error) {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := temp_cstring(name) or_return
	return _read_link_cstr(name_cstr, allocator)
}

_chdir :: proc(name: string) -> Error {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := temp_cstring(name) or_return
	return _get_platform_error(linux.chdir(name_cstr))
}

_fchdir :: proc(f: ^File) -> Error {
	return _get_platform_error(linux.fchdir(f.impl.fd))
}

_chmod :: proc(name: string, mode: File_Mode) -> Error {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := temp_cstring(name) or_return
	return _get_platform_error(linux.chmod(name_cstr, transmute(linux.Mode)(u32(mode))))
}

_fchmod :: proc(f: ^File, mode: File_Mode) -> Error {
	return _get_platform_error(linux.fchmod(f.impl.fd, transmute(linux.Mode)(u32(mode))))
}

// NOTE: will throw error without super user priviledges
_chown :: proc(name: string, uid, gid: int) -> Error {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := temp_cstring(name) or_return
	return _get_platform_error(linux.chown(name_cstr, linux.Uid(uid), linux.Gid(gid)))
}

// NOTE: will throw error without super user priviledges
_lchown :: proc(name: string, uid, gid: int) -> Error {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := temp_cstring(name) or_return
	return _get_platform_error(linux.lchown(name_cstr, linux.Uid(uid), linux.Gid(gid)))
}

// NOTE: will throw error without super user priviledges
_fchown :: proc(f: ^File, uid, gid: int) -> Error {
	return _get_platform_error(linux.fchown(f.impl.fd, linux.Uid(uid), linux.Gid(gid)))
}

_chtimes :: proc(name: string, atime, mtime: time.Time) -> Error {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := temp_cstring(name) or_return
	times := [2]linux.Time_Spec {
		{
			uint(atime._nsec) / uint(time.Second),
			uint(atime._nsec) % uint(time.Second),
		},
		{
			uint(mtime._nsec) / uint(time.Second),
			uint(mtime._nsec) % uint(time.Second),
		},
	}
	return _get_platform_error(linux.utimensat(linux.AT_FDCWD, name_cstr, &times[0], nil))
}

_fchtimes :: proc(f: ^File, atime, mtime: time.Time) -> Error {
	times := [2]linux.Time_Spec {
		{
			uint(atime._nsec) / uint(time.Second),
			uint(atime._nsec) % uint(time.Second),
		},
		{
			uint(mtime._nsec) / uint(time.Second),
			uint(mtime._nsec) % uint(time.Second),
		},
	}
	return _get_platform_error(linux.utimensat(f.impl.fd, nil, &times[0], nil))
}

_exists :: proc(name: string) -> bool {
	TEMP_ALLOCATOR_GUARD()
	name_cstr, _ := temp_cstring(name)
	res, errno := linux.access(name_cstr, linux.F_OK)
	return !res && errno == .NONE
}

_is_file :: proc(name: string) -> bool {
	TEMP_ALLOCATOR_GUARD()
	name_cstr, _ := temp_cstring(name)
	s: linux.Stat
	if linux.stat(name_cstr, &s) != .NONE {
		return false
	}
	return linux.S_ISREG(s.mode)
}

_is_file_fd :: proc(fd: linux.Fd) -> bool {
	s: linux.Stat
	if linux.fstat(fd, &s) != .NONE {
		return false
	}
	return linux.S_ISREG(s.mode)
}

_is_dir :: proc(name: string) -> bool {
	TEMP_ALLOCATOR_GUARD()
	name_cstr, _ := temp_cstring(name)
	s: linux.Stat
	if linux.stat(name_cstr, &s) != .NONE {
		return false
	}
	return linux.S_ISDIR(s.mode)
}

_is_dir_fd :: proc(fd: linux.Fd) -> bool {
	s: linux.Stat
	if linux.fstat(fd, &s) != .NONE {
		return false
	}
	return linux.S_ISDIR(s.mode)
}

/* Certain files in the Linux file system are not actual
 * files (e.g. everything in /proc/). Therefore, the
 * read_entire_file procs fail to actually read anything
 * since these "files" stat to a size of 0.  Here, we just
 * read until there is nothing left.
 */
_read_entire_pseudo_file :: proc { _read_entire_pseudo_file_string, _read_entire_pseudo_file_cstring }

_read_entire_pseudo_file_string :: proc(name: string, allocator: runtime.Allocator) -> (b: []u8, e: Error) {
	name_cstr := clone_to_cstring(name, allocator) or_return
	defer delete(name, allocator)
	return _read_entire_pseudo_file_cstring(name_cstr, allocator)
}

_read_entire_pseudo_file_cstring :: proc(name: cstring, allocator: runtime.Allocator) -> ([]u8, Error) {
	fd, errno := linux.open(name, {})
	if errno != .NONE {
		return nil, _get_platform_error(errno)
	}
	defer linux.close(fd)

	BUF_SIZE_STEP :: 128
	contents := make([dynamic]u8, 0, BUF_SIZE_STEP, allocator)

	n: int
	i: int
	for {
		resize(&contents, i + BUF_SIZE_STEP)
		n, errno = linux.read(fd, contents[i:i+BUF_SIZE_STEP])
		if errno != .NONE {
			delete(contents)
			return nil, _get_platform_error(errno)
		}
		if n < BUF_SIZE_STEP {
			break
		}
		i += BUF_SIZE_STEP
	}

	resize(&contents, i + n)

	return contents[:], nil
}

@(private="package")
_file_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	f := (^File)(stream_data)
	ferr: Error
	switch mode {
	case .Read:
		n, ferr = _read(f, p)
		err = error_to_io_error(ferr)
		return
	case .Read_At:
		n, ferr = _read_at(f, p, offset)
		err = error_to_io_error(ferr)
		return
	case .Write:
		n, ferr = _write(f, p)
		err = error_to_io_error(ferr)
		return
	case .Write_At:
		n, ferr = _write_at(f, p, offset)
		err = error_to_io_error(ferr)
		return
	case .Seek:
		n, ferr = _seek(f, offset, whence)
		err = error_to_io_error(ferr)
		return
	case .Size:
		n, ferr = _file_size(f)
		err = error_to_io_error(ferr)
		return
	case .Flush:
		ferr = _flush(f)
		err = error_to_io_error(ferr)
		return
	case .Close, .Destroy:
		ferr = _close(f)
		err = error_to_io_error(ferr)
		return
	case .Query:
		return io.query_utility({.Read, .Read_At, .Write, .Write_At, .Seek, .Size, .Flush, .Close, .Destroy, .Query})
	}
	return 0, .Empty
}

