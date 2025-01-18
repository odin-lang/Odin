#+private
package os2

import "base:runtime"

import "core:io"
import "core:sys/wasm/wasi"
import "core:time"

// NOTE: Don't know if there is a max in wasi.
MAX_RW :: 1 << 30

File_Impl :: struct {
	file:      File,
	name:      string,
	fd:        wasi.fd_t,
	allocator: runtime.Allocator,
}

// WASI works with "preopened" directories, the environment retrieves directories
// (for example with `wasmtime --dir=. module.wasm`) and those given directories
// are the only ones accessible by the application.
//
// So in order to facilitate the `os` API (absolute paths etc.) we keep a list
// of the given directories and match them when needed (notably `os.open`).
Preopen :: struct {
	fd:     wasi.fd_t,
	prefix: string,
}
preopens: []Preopen

@(init)
init_std_files :: proc() {
	new_std :: proc(impl: ^File_Impl, fd: wasi.fd_t, name: string) -> ^File {
		impl.file.impl = impl
		impl.allocator = runtime.nil_allocator()
		impl.fd = fd
		impl.name  = string(name)
		impl.file.stream = {
			data = impl,
			procedure = _file_stream_proc,
		}
		impl.file.fstat = _fstat
		return &impl.file
	}

	@(static) files: [3]File_Impl
	stdin  = new_std(&files[0], 0, "/dev/stdin")
	stdout = new_std(&files[1], 1, "/dev/stdout")
	stderr = new_std(&files[2], 2, "/dev/stderr")
}

@(init)
init_preopens :: proc() {
	strip_prefixes :: proc(path: string) -> string {
		path := path
		loop: for len(path) > 0 {
			switch {
			case path[0] == '/':
				path = path[1:]
			case len(path) > 2  && path[0] == '.' && path[1] == '/':
				path = path[2:]
			case len(path) == 1 && path[0] == '.':
				path = path[1:]
			case:
				break loop
			}
		}
		return path
	}

	n: int
	n_loop: for fd := wasi.fd_t(3); ; fd += 1 {
		_, err := wasi.fd_prestat_get(fd)
		#partial switch err {
		case .BADF:    break n_loop
		case .SUCCESS: n += 1
		case:
			print_error(stderr, _get_platform_error(err), "unexpected error from wasi_prestat_get")
			break n_loop
		}
	}

	alloc_err: runtime.Allocator_Error
	preopens, alloc_err = make([]Preopen, n, file_allocator())
	if alloc_err != nil {
		print_error(stderr, alloc_err, "could not allocate memory for wasi preopens")
		return
	}

	loop: for &preopen, i in preopens {
		fd := wasi.fd_t(3 + i)

		desc, err := wasi.fd_prestat_get(fd)
		assert(err == .SUCCESS)

		switch desc.tag {
		case .DIR:
			buf: []byte
			buf, alloc_err = make([]byte, desc.dir.pr_name_len, file_allocator())
			if alloc_err != nil {
				print_error(stderr, alloc_err, "could not allocate memory for wasi preopen dir name")
				continue loop
			}

			if err = wasi.fd_prestat_dir_name(fd, buf); err != .SUCCESS {
				print_error(stderr, _get_platform_error(err), "could not get filesystem preopen dir name")
				continue loop
			}

			preopen.fd = fd
			preopen.prefix = strip_prefixes(string(buf))
		}
	}
}

@(require_results)
match_preopen :: proc(path: string) -> (wasi.fd_t, string, bool) {
	@(require_results)
	prefix_matches :: proc(prefix, path: string) -> bool {
		// Empty is valid for any relative path.
		if len(prefix) == 0 && len(path) > 0 && path[0] != '/' {
			return true
		}

		if len(path) < len(prefix) {
			return false
		}

		if path[:len(prefix)] != prefix {
			return false
		}

		// Only match on full components.
		i := len(prefix)
		for i > 0 && prefix[i-1] == '/' {
			i -= 1
		}
		return path[i] == '/'
	}

	path := path
	if path == "" {
		return 0, "", false
	}

	for len(path) > 0 && path[0] == '/' {
		path = path[1:]
	}

	match: Preopen
	#reverse for preopen in preopens {
		if (match.fd == 0 || len(preopen.prefix) > len(match.prefix)) && prefix_matches(preopen.prefix, path) {
			match = preopen
		}
	}

	if match.fd == 0 {
		return 0, "", false
	}

	relative := path[len(match.prefix):]
	for len(relative) > 0 && relative[0] == '/' {
		relative = relative[1:]
	}

	if len(relative) == 0 {
		relative = "."
	}

	return match.fd, relative, true
}

_open :: proc(name: string, flags: File_Flags, perm: int) -> (f: ^File, err: Error) {
	dir_fd, relative, ok := match_preopen(name)
	if !ok {
		return nil, .Invalid_Path
	}

	oflags: wasi.oflags_t
	if .Create in flags { oflags += {.CREATE} }
	if .Excl   in flags { oflags += {.EXCL} }
	if .Trunc  in flags { oflags += {.TRUNC} }

	fdflags: wasi.fdflags_t
	if .Append in flags { fdflags += {.APPEND} }
	if .Sync   in flags { fdflags += {.SYNC} }

	// NOTE: rights are adjusted to what this package's functions might want to call.
	rights: wasi.rights_t
	if .Read  in flags { rights += {.FD_READ, .FD_FILESTAT_GET, .PATH_FILESTAT_GET} }
	if .Write in flags { rights += {.FD_WRITE, .FD_SYNC, .FD_FILESTAT_SET_SIZE, .FD_FILESTAT_SET_TIMES, .FD_SEEK} }

	fd, fderr := wasi.path_open(dir_fd, {.SYMLINK_FOLLOW}, relative, oflags, rights, {}, fdflags)
	if fderr != nil {
		err = _get_platform_error(fderr)
		return
	}

	return _new_file(uintptr(fd), name, file_allocator())
}

_new_file :: proc(handle: uintptr, name: string, allocator: runtime.Allocator) -> (f: ^File, err: Error) {
	if name == "" {
		err = .Invalid_Path
		return
	}

	impl := new(File_Impl, allocator) or_return
	defer if err != nil { free(impl, allocator) }

	impl.allocator = allocator
	// NOTE: wasi doesn't really do full paths afact.
	impl.name = clone_string(name, allocator) or_return
	impl.fd = wasi.fd_t(handle)
	impl.file.impl = impl
	impl.file.stream = {
		data = impl,
		procedure = _file_stream_proc,
	}
	impl.file.fstat = _fstat

	return &impl.file, nil
}

_close :: proc(f: ^File_Impl) -> (err: Error) {
	if errno := wasi.fd_close(f.fd); errno != nil {
		err = _get_platform_error(errno)
	}

	delete(f.name, f.allocator)
	free(f, f.allocator)
	return
}

_fd :: proc(f: ^File) -> uintptr {
	return uintptr(__fd(f))
}

__fd :: proc(f: ^File) -> wasi.fd_t {
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
	return _get_platform_error(wasi.fd_sync(__fd(f)))
}

_truncate :: proc(f: ^File, size: i64) -> Error {
	return _get_platform_error(wasi.fd_filestat_set_size(__fd(f), wasi.filesize_t(size)))
}

_remove :: proc(name: string) -> Error {
	dir_fd, relative, ok := match_preopen(name)
	if !ok {
		return .Invalid_Path
	}

	err := wasi.path_remove_directory(dir_fd, relative)
	if err == .NOTDIR {
		err = wasi.path_unlink_file(dir_fd, relative)
	}

	return _get_platform_error(err)
}

_rename :: proc(old_path, new_path: string) -> Error {
	src_dir_fd, src_relative, src_ok := match_preopen(old_path)
	if !src_ok {
		return .Invalid_Path
	}

	new_dir_fd, new_relative, new_ok := match_preopen(new_path)
	if !new_ok {
		return .Invalid_Path
	}

	return _get_platform_error(wasi.path_rename(src_dir_fd, src_relative, new_dir_fd, new_relative))
}

_link :: proc(old_name, new_name: string) -> Error {
	src_dir_fd, src_relative, src_ok := match_preopen(old_name)
	if !src_ok {
		return .Invalid_Path
	}

	new_dir_fd, new_relative, new_ok := match_preopen(new_name)
	if !new_ok {
		return .Invalid_Path
	}

	return _get_platform_error(wasi.path_link(src_dir_fd, {.SYMLINK_FOLLOW}, src_relative, new_dir_fd, new_relative))
}

_symlink :: proc(old_name, new_name: string) -> Error {
	src_dir_fd, src_relative, src_ok := match_preopen(old_name)
	if !src_ok {
		return .Invalid_Path
	}

	new_dir_fd, new_relative, new_ok := match_preopen(new_name)
	if !new_ok {
		return .Invalid_Path
	}

	if src_dir_fd != new_dir_fd {
		return .Invalid_Path
	}

	return _get_platform_error(wasi.path_symlink(src_relative, src_dir_fd, new_relative))
}

_read_link :: proc(name: string, allocator: runtime.Allocator) -> (s: string, err: Error) {
	dir_fd, relative, ok := match_preopen(name)
	if !ok {
		return "", .Invalid_Path
	}

	n, _err := wasi.path_readlink(dir_fd, relative, nil)
	if _err != nil {
		err = _get_platform_error(_err)
		return
	}

	buf := make([]byte, n, allocator) or_return

	_, _err = wasi.path_readlink(dir_fd, relative, buf)
	s = string(buf)
	err = _get_platform_error(_err)
	return
}

_chdir :: proc(name: string) -> Error {
	return .Unsupported
}

_fchdir :: proc(f: ^File) -> Error {
	return .Unsupported
}

_fchmod :: proc(f: ^File, mode: int) -> Error {
	return .Unsupported
}

_chmod :: proc(name: string, mode: int) -> Error {
	return .Unsupported
}

_fchown :: proc(f: ^File, uid, gid: int) -> Error {
	return .Unsupported
}

_chown :: proc(name: string, uid, gid: int) -> Error {
	return .Unsupported
}

_lchown :: proc(name: string, uid, gid: int) -> Error {
	return .Unsupported
}

_chtimes :: proc(name: string, atime, mtime: time.Time) -> Error {
	dir_fd, relative, ok := match_preopen(name)
	if !ok {
		return .Invalid_Path
	}

	_atime := wasi.timestamp_t(atime._nsec)
	_mtime := wasi.timestamp_t(mtime._nsec)

	return _get_platform_error(wasi.path_filestat_set_times(dir_fd, {.SYMLINK_FOLLOW}, relative, _atime, _mtime, {.MTIM, .ATIM}))
}

_fchtimes :: proc(f: ^File, atime, mtime: time.Time) -> Error {
	_atime := wasi.timestamp_t(atime._nsec)
	_mtime := wasi.timestamp_t(mtime._nsec)

	return _get_platform_error(wasi.fd_filestat_set_times(__fd(f), _atime, _mtime, {.ATIM, .MTIM}))
}

_exists :: proc(path: string) -> bool {
	dir_fd, relative, ok := match_preopen(path)
	if !ok {
		return false
	}

	_, err := wasi.path_filestat_get(dir_fd, {.SYMLINK_FOLLOW}, relative)
	if err != nil {
		return false
	}

	return true
}

_file_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	f  := (^File_Impl)(stream_data)
	fd := f.fd

	switch mode {
	case .Read:
		if len(p) <= 0 {
			return
		}

		to_read := min(len(p), MAX_RW)
		_n, _err := wasi.fd_read(fd, {p[:to_read]})
		n = i64(_n)

		if _err != nil {
			err = .Unknown
		} else if n == 0 {
			err = .EOF
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

		to_read := min(len(p), MAX_RW)
		_n, _err := wasi.fd_pread(fd, {p[:to_read]}, wasi.filesize_t(offset))
		n = i64(_n)

		if _err != nil {
			err = .Unknown
		} else if n == 0 {
			err = .EOF
		}

		return

	case .Write:
		p := p
		for len(p) > 0 {
			to_write := min(len(p), MAX_RW)
			_n, _err := wasi.fd_write(fd, {p[:to_write]})
			if _err != nil {
				err = .Unknown
				return
			}
			p = p[_n:]
			n += i64(_n)
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
			to_write := min(len(p), MAX_RW)
			_n, _err := wasi.fd_pwrite(fd, {p[:to_write]}, wasi.filesize_t(offset))
			if _err != nil {
				err = .Unknown
				return
			}

			p = p[_n:]
			n += i64(_n)
			offset += i64(_n)
		}
		return

	case .Seek:
		#assert(int(wasi.whence_t.SET) == int(io.Seek_From.Start))
		#assert(int(wasi.whence_t.CUR) == int(io.Seek_From.Current))
		#assert(int(wasi.whence_t.END) == int(io.Seek_From.End))

		switch whence {
		case .Start, .Current, .End:
			break
		case:
			err = .Invalid_Whence
			return
		}

		_n, _err := wasi.fd_seek(fd, wasi.filedelta_t(offset), wasi.whence_t(whence))
		#partial switch _err {
		case .INVAL:
			err = .Invalid_Offset
		case:
			err = .Unknown
		case .SUCCESS:
			n = i64(_n)
		}
		return

	case .Size:
		stat, _err := wasi.fd_filestat_get(fd)
		if _err != nil {
			err = .Unknown
			return
		}

		n = i64(stat.size)
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
