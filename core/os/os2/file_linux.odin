#+private
package os2

import "base:runtime"
import "core:io"
import "core:time"
import "core:sync"
import "core:sys/linux"

// Most implementations will EINVAL at some point when doing big writes.
// In practice a read/write call would probably never read/write these big buffers all at once,
// which is why the number of bytes is returned and why there are procs that will call this in a
// loop for you.
// We set a max of 1GB to keep alignment and to be safe.
MAX_RW :: 1 << 30

File_Impl :: struct {
	file: File,
	name: string,
	fd: linux.Fd,
	allocator: runtime.Allocator,

	buffer:   []byte,
	rw_mutex: sync.RW_Mutex, // read write calls
	p_mutex:  sync.Mutex, // pread pwrite calls
}

_stdin := File{
	stream = {
		procedure = _file_stream_proc,
	},
	fstat = _fstat,
}
_stdout := File{
	stream = {
		procedure = _file_stream_proc,
	},
	fstat = _fstat,
}
_stderr := File{
	stream = {
		procedure = _file_stream_proc,
	},
	fstat = _fstat,
}

@init
_standard_stream_init :: proc() {
	new_std :: proc(impl: ^File_Impl, fd: linux.Fd, name: string) -> ^File {
		impl.file.impl = impl
		impl.fd = linux.Fd(fd)
		impl.allocator = runtime.nil_allocator()
		impl.name = name
		impl.file.stream = {
			data = impl,
			procedure = _file_stream_proc,
		}
		impl.file.fstat = _fstat
		return &impl.file
	}

	@(static) files: [3]File_Impl
	stdin  = new_std(&files[0], 0, "/proc/self/fd/0")
	stdout = new_std(&files[1], 1, "/proc/self/fd/1")
	stderr = new_std(&files[2], 2, "/proc/self/fd/2")
}

_open :: proc(name: string, flags: File_Flags, perm: int) -> (f: ^File, err: Error) {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := temp_cstring(name) or_return

	// Just default to using O_NOCTTY because needing to open a controlling
	// terminal would be incredibly rare. This has no effect on files while
	// allowing us to open serial devices.
	sys_flags: linux.Open_Flags = {.NOCTTY, .CLOEXEC}
	when size_of(rawptr) == 4 {
		sys_flags += {.LARGEFILE}
	}
	switch flags & (O_RDONLY|O_WRONLY|O_RDWR) {
	case O_RDONLY:
	case O_WRONLY: sys_flags += {.WRONLY}
	case O_RDWR:   sys_flags += {.RDWR}
	}
	if .Append in flags        { sys_flags += {.APPEND} }
	if .Create in flags        { sys_flags += {.CREAT} }
	if .Excl in flags          { sys_flags += {.EXCL} }
	if .Sync in flags          { sys_flags += {.DSYNC} }
	if .Trunc in flags         { sys_flags += {.TRUNC} }
	if .Inheritable in flags   { sys_flags -= {.CLOEXEC} }

	fd, errno := linux.open(name_cstr, sys_flags, transmute(linux.Mode)u32(perm))
	if errno != .NONE {
		return nil, _get_platform_error(errno)
	}

	return _new_file(uintptr(fd), name, file_allocator())
}

_new_file :: proc(fd: uintptr, _: string, allocator: runtime.Allocator) -> (f: ^File, err: Error) {
	impl := new(File_Impl, allocator) or_return
	defer if err != nil {
		free(impl, allocator)
	}
	impl.file.impl = impl
	impl.fd = linux.Fd(fd)
	impl.allocator = allocator
	impl.name = _get_full_path(impl.fd, impl.allocator) or_return
	impl.file.stream = {
		data = impl,
		procedure = _file_stream_proc,
	}
	impl.file.fstat = _fstat
	return &impl.file, nil
}

_clone :: proc(f: ^File) -> (clone: ^File, err: Error) {
	if f == nil || f.impl == nil {
		return
	}

	fd := (^File_Impl)(f.impl).fd

	clonefd, errno := linux.dup(fd)
	if errno != nil {
		err = _get_platform_error(errno)
		return
	}
	defer if err != nil { linux.close(clonefd) }

	return _new_file(uintptr(clonefd), "", file_allocator())
}


@(require_results)
_open_buffered :: proc(name: string, buffer_size: uint, flags := File_Flags{.Read}, perm := 0o777) -> (f: ^File, err: Error) {
	assert(buffer_size > 0)
	f, err = _open(name, flags, perm)
	if f != nil && err == nil {
		impl := (^File_Impl)(f.impl)
		impl.buffer = make([]byte, buffer_size, file_allocator())
		f.stream.procedure = _file_stream_buffered_proc
	}
	return
}

_destroy :: proc(f: ^File_Impl) -> Error {
	if f == nil {
		return nil
	}
	a := f.allocator
	err0 := delete(f.name, a)
	err1 := delete(f.buffer, a)
	err2 := free(f, a)
	err0 or_return
	err1 or_return
	err2 or_return
	return nil
}


_close :: proc(f: ^File_Impl) -> Error {
	if f == nil{
		return nil
	}
	errno := linux.close(f.fd)
	if errno == .EBADF { // avoid possible double free
		return _get_platform_error(errno)
	}
	_destroy(f)
	return _get_platform_error(errno)
}

_fd :: proc(f: ^File) -> uintptr {
	if f == nil || f.impl == nil {
		return ~uintptr(0)
	}
	impl := (^File_Impl)(f.impl)
	return uintptr(impl.fd)
}

_name :: proc(f: ^File) -> string {
	return (^File_Impl)(f.impl).name if f != nil && f.impl != nil else ""
}

_seek :: proc(f: ^File_Impl, offset: i64, whence: io.Seek_From) -> (ret: i64, err: Error) {
	// We have to handle this here, because Linux returns EINVAL for both
	// invalid offsets and invalid whences.
	switch whence {
	case .Start, .Current, .End:
		break
	case:
		return 0, .Invalid_Whence
	}
	n, errno := linux.lseek(f.fd, offset, linux.Seek_Whence(whence))
	#partial switch errno {
	case .EINVAL:
		return 0, .Invalid_Offset
	case .NONE:
		return n, nil
	case:
		return -1, _get_platform_error(errno)
	}
}

_read :: proc(f: ^File_Impl, p: []byte) -> (i64, Error) {
	if len(p) <= 0 {
		return 0, nil
	}

	n, errno := linux.read(f.fd, p[:min(len(p), MAX_RW)])
	if errno != .NONE {
		return -1, _get_platform_error(errno)
	}
	return i64(n), io.Error.EOF if n == 0 else nil
}

_read_at :: proc(f: ^File_Impl, p: []byte, offset: i64) -> (i64, Error) {
	if len(p) <= 0 {
		return 0, nil
	}
	if offset < 0 {
		return 0, .Invalid_Offset
	}
	n, errno := linux.pread(f.fd, p[:min(len(p), MAX_RW)], offset)
	if errno != .NONE {
		return -1, _get_platform_error(errno)
	}
	if n == 0 {
		return 0, .EOF
	}
	return i64(n), nil
}

_write :: proc(f: ^File_Impl, p: []byte) -> (nt: i64, err: Error) {
	p := p
	for len(p) > 0 {
		n, errno := linux.write(f.fd, p[:min(len(p), MAX_RW)])
		if errno != .NONE {
			err = _get_platform_error(errno)
			return
		}

		p = p[n:]
		nt += i64(n)
	}

	return
}

_write_at :: proc(f: ^File_Impl, p: []byte, offset: i64) -> (nt: i64, err: Error) {
	if offset < 0 {
		return 0, .Invalid_Offset
	}

	p := p
	offset := offset
	for len(p) > 0 {
		n, errno := linux.pwrite(f.fd, p[:min(len(p), MAX_RW)], offset)
		if errno != .NONE {
			err = _get_platform_error(errno)
			return
		}

		p = p[n:]
		nt += i64(n)
		offset += i64(n)
	}

	return
}

_file_size :: proc(f: ^File_Impl) -> (n: i64, err: Error) {
	// TODO: Identify 0-sized "pseudo" files and return No_Size. This would
	//       eliminate the need for the _read_entire_pseudo_file procs.
	s: linux.Stat = ---
	errno := linux.fstat(f.fd, &s)
	if errno != .NONE {
		return -1, _get_platform_error(errno)
	}

	if s.mode & linux.S_IFMT == linux.S_IFREG {
		return i64(s.size), nil
	}
	return 0, .No_Size
}

_sync :: proc(f: ^File) -> Error {
	impl := (^File_Impl)(f.impl)
	return _get_platform_error(linux.fsync(impl.fd))
}

_flush :: proc(f: ^File_Impl) -> Error {
	return _get_platform_error(linux.fsync(f.fd))
}

_truncate :: proc(f: ^File, size: i64) -> Error {
	impl := (^File_Impl)(f.impl)
	return _get_platform_error(linux.ftruncate(impl.fd, size))
}

_remove :: proc(name: string) -> Error {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := temp_cstring(name) or_return

	if fd, errno := linux.open(name_cstr, _OPENDIR_FLAGS + {.NOFOLLOW}); errno == .NONE {
		linux.close(fd)
		return _get_platform_error(linux.rmdir(name_cstr))
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
	impl := (^File_Impl)(f.impl)
	return _get_platform_error(linux.fchdir(impl.fd))
}

_chmod :: proc(name: string, mode: int) -> Error {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := temp_cstring(name) or_return
	return _get_platform_error(linux.chmod(name_cstr, transmute(linux.Mode)(u32(mode))))
}

_fchmod :: proc(f: ^File, mode: int) -> Error {
	impl := (^File_Impl)(f.impl)
	return _get_platform_error(linux.fchmod(impl.fd, transmute(linux.Mode)(u32(mode))))
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
	impl := (^File_Impl)(f.impl)
	return _get_platform_error(linux.fchown(impl.fd, linux.Uid(uid), linux.Gid(gid)))
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
	impl := (^File_Impl)(f.impl)
	return _get_platform_error(linux.utimensat(impl.fd, nil, &times[0], nil))
}

_exists :: proc(name: string) -> bool {
	TEMP_ALLOCATOR_GUARD()
	name_cstr, _ := temp_cstring(name)
	return linux.access(name_cstr, linux.F_OK) == .NONE
}

/* For reading Linux system files that stat to size 0 */
_read_entire_pseudo_file :: proc { _read_entire_pseudo_file_string, _read_entire_pseudo_file_cstring }

_read_entire_pseudo_file_string :: proc(name: string, allocator: runtime.Allocator) -> (b: []u8, e: Error) {
	TEMP_ALLOCATOR_GUARD()
	name_cstr := clone_to_cstring(name, temp_allocator()) or_return
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
	f := (^File_Impl)(stream_data)
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


@(private="package")
_file_stream_buffered_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	f := (^File_Impl)(stream_data)
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

