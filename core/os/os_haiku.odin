package os

foreign import lib "system:c"

import "base:runtime"
import "core:c"
import "core:c/libc"
import "core:strings"
import "core:sys/haiku"
import "core:sys/posix"

Handle    :: i32
Pid       :: i32
File_Time :: i64
_Platform_Error :: haiku.Errno

MAX_PATH :: haiku.PATH_MAX

ENOSYS :: _Platform_Error(haiku.Errno.ENOSYS)

INVALID_HANDLE :: ~Handle(0)

stdin:  Handle = 0
stdout: Handle = 1
stderr: Handle = 2

pid_t     :: haiku.pid_t
off_t     :: haiku.off_t
dev_t     :: haiku.dev_t
ino_t     :: haiku.ino_t
mode_t    :: haiku.mode_t
nlink_t   :: haiku.nlink_t
uid_t     :: haiku.uid_t
gid_t     :: haiku.gid_t
blksize_t :: haiku.blksize_t
blkcnt_t  :: haiku.blkcnt_t
time_t    :: haiku.time_t


Unix_File_Time :: struct {
	seconds:     time_t,
	nanoseconds: c.long,
}

OS_Stat :: struct {
	device_id: dev_t,		// device ID that this file resides on
	serial: ino_t,			// this file's serial inode ID
	mode: mode_t,			// file mode (rwx for user, group, etc)
	nlink: nlink_t,			// number of hard links to this file
	uid: uid_t,			// user ID of the file's owner
	gid: gid_t,			// group ID of the file's group
	size: off_t,			// file size, in bytes
	rdev: dev_t,			// device type (not used)
	block_size:	blksize_t,	// optimal blocksize for I/O
	
	last_access: Unix_File_Time,	// time of last access
	modified: Unix_File_Time,	// time of last data modification
	status_change: Unix_File_Time,	// time of last file status change
	birthtime:	Unix_File_Time,	// time of file creation

	type: u32,                      // attribute/index type

	blocks: blkcnt_t,		// blocks allocated for file
}

/* file access modes for open() */
O_RDONLY         :: 0x0000		/* read only */
O_WRONLY         :: 0x0001		/* write only */
O_RDWR           :: 0x0002		/* read and write */
O_ACCMODE        :: 0x0003		/* mask to get the access modes above */
O_RWMASK         :: O_ACCMODE

/* flags for open() */
O_EXCL           :: 0x0100		/* exclusive creat */
O_CREATE         :: 0x0200		/* create and open file */
O_TRUNC          :: 0x0400		/* open with truncation */
O_NOCTTY         :: 0x1000		/* don't make tty the controlling tty */
O_NOTRAVERSE     :: 0x2000		/* do not traverse leaf link */

// File type
S_IFMT   :: 0o170000 // Type of file mask
S_IFIFO  :: 0o010000 // Named pipe (fifo)
S_IFCHR  :: 0o020000 // Character special
S_IFDIR  :: 0o040000 // Directory
S_IFBLK  :: 0o060000 // Block special
S_IFREG  :: 0o100000 // Regular
S_IFLNK  :: 0o120000 // Symbolic link
S_IFSOCK :: 0o140000 // Socket
S_ISVTX  :: 0o001000 // Save swapped text even after use

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
S_ISTXT :: 0o1000 // Sticky bit

S_ISLNK  :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFLNK  }
S_ISREG  :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFREG  }
S_ISDIR  :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFDIR  }
S_ISCHR  :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFCHR  }
S_ISBLK  :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFBLK  }
S_ISFIFO :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFIFO  }
S_ISSOCK :: #force_inline proc(m: u32) -> bool { return (m & S_IFMT) == S_IFSOCK }

__error :: libc.errno
_unix_open :: posix.open

foreign lib {
	@(link_name="fork")           _unix_fork           :: proc() -> pid_t ---
	@(link_name="getthrid")       _unix_getthrid       :: proc() -> int ---

	@(link_name="close")          _unix_close          :: proc(fd: Handle) -> c.int ---
	@(link_name="read")           _unix_read           :: proc(fd: Handle, buf: rawptr, size: c.size_t) -> c.ssize_t ---
	@(link_name="pread")          _unix_pread          :: proc(fd: Handle, buf: rawptr, size: c.size_t, offset: i64) -> c.ssize_t ---
	@(link_name="write")          _unix_write          :: proc(fd: Handle, buf: rawptr, size: c.size_t) -> c.ssize_t ---
	@(link_name="pwrite")         _unix_pwrite         :: proc(fd: Handle, buf: rawptr, size: c.size_t, offset: i64) -> c.ssize_t ---
	@(link_name="lseek")          _unix_seek           :: proc(fd: Handle, offset: off_t, whence: c.int) -> off_t ---
	@(link_name="stat")           _unix_stat           :: proc(path: cstring, sb: ^OS_Stat) -> c.int ---
	@(link_name="fstat")          _unix_fstat          :: proc(fd: Handle, sb: ^OS_Stat) -> c.int ---
	@(link_name="lstat")          _unix_lstat          :: proc(path: cstring, sb: ^OS_Stat) -> c.int ---
	@(link_name="readlink")       _unix_readlink       :: proc(path: cstring, buf: ^byte, bufsiz: c.size_t) -> c.ssize_t ---
	@(link_name="access")         _unix_access         :: proc(path: cstring, mask: c.int) -> c.int ---
	@(link_name="getcwd")         _unix_getcwd         :: proc(buf: cstring, len: c.size_t) -> cstring ---
	@(link_name="chdir")          _unix_chdir          :: proc(path: cstring) -> c.int ---
	@(link_name="rename")         _unix_rename         :: proc(old, new: cstring) -> c.int ---
	@(link_name="unlink")         _unix_unlink         :: proc(path: cstring) -> c.int ---
	@(link_name="rmdir")          _unix_rmdir          :: proc(path: cstring) -> c.int ---
	@(link_name="mkdir")          _unix_mkdir          :: proc(path: cstring, mode: mode_t) -> c.int ---
	@(link_name="fsync")          _unix_fsync          :: proc(fd: Handle) -> c.int ---

	@(link_name="getpagesize")    _unix_getpagesize    :: proc() -> c.int ---
	@(link_name="sysconf")        _sysconf             :: proc(name: c.int) -> c.long ---
	@(link_name="fdopendir")      _unix_fdopendir      :: proc(fd: Handle) -> Dir ---
	@(link_name="closedir")       _unix_closedir       :: proc(dirp: Dir) -> c.int ---
	@(link_name="rewinddir")      _unix_rewinddir      :: proc(dirp: Dir) ---
	@(link_name="readdir_r")      _unix_readdir_r      :: proc(dirp: Dir, entry: ^Dirent, result: ^^Dirent) -> c.int ---
	@(link_name="dup")            _unix_dup            :: proc(fd: Handle) -> Handle ---

	@(link_name="malloc")         _unix_malloc         :: proc(size: c.size_t) -> rawptr ---
	@(link_name="calloc")         _unix_calloc         :: proc(num, size: c.size_t) -> rawptr ---
	@(link_name="free")           _unix_free           :: proc(ptr: rawptr) ---
	@(link_name="realloc")        _unix_realloc        :: proc(ptr: rawptr, size: c.size_t) -> rawptr ---

	@(link_name="getenv")         _unix_getenv         :: proc(cstring) -> cstring ---
	@(link_name="realpath")       _unix_realpath       :: proc(path: cstring, resolved_path: [^]byte = nil) -> cstring ---

	@(link_name="exit")           _unix_exit           :: proc(status: c.int) -> ! ---

	@(link_name="dlopen")         _unix_dlopen         :: proc(filename: cstring, flags: c.int) -> rawptr ---
	@(link_name="dlsym")          _unix_dlsym          :: proc(handle: rawptr, symbol: cstring) -> rawptr ---
	@(link_name="dlclose")        _unix_dlclose        :: proc(handle: rawptr) -> c.int ---
	@(link_name="dlerror")        _unix_dlerror        :: proc() -> cstring ---
}

MAXNAMLEN :: haiku.NAME_MAX

Dirent :: struct {
	dev:      dev_t,
	pdef:     dev_t,
	ino:      ino_t,
	pino:     ino_t,
	reclen:   u16,
	name:     [MAXNAMLEN + 1]byte, // name
}

Dir :: distinct rawptr // DIR*

@(require_results)
is_path_separator :: proc(r: rune) -> bool {
	return r == '/'
}

@(require_results, no_instrumentation)
get_last_error :: proc "contextless" () -> Error {
	return Platform_Error(__error()^)
}

@(require_results)
fork :: proc() -> (Pid, Error) {
	pid := _unix_fork()
	if pid == -1 {
		return Pid(-1), get_last_error()
	}
	return Pid(pid), nil
}

@(require_results)
open :: proc(path: string, flags: int = O_RDONLY, mode: int = 0) -> (Handle, Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	handle := cast(Handle)_unix_open(cstr, transmute(posix.O_Flags)i32(flags), transmute(posix.mode_t)i32(mode))
	if handle == -1 {
		return INVALID_HANDLE, get_last_error()
	}
	return handle, nil
}

close :: proc(fd: Handle) -> Error {
	result := _unix_close(fd)
	if result == -1 {
		return get_last_error()
	}
	return nil
}

flush :: proc(fd: Handle) -> Error {
	result := _unix_fsync(fd)
	if result == -1 {
		return get_last_error()
	}
	return nil
}

// In practice a read/write call would probably never read/write these big buffers all at once,
// which is why the number of bytes is returned and why there are procs that will call this in a
// loop for you.
// We set a max of 1GB to keep alignment and to be safe.
@(private)
MAX_RW :: 1 << 30

read :: proc(fd: Handle, data: []byte) -> (int, Error) {
	to_read    := min(c.size_t(len(data)), MAX_RW)
	bytes_read := _unix_read(fd, &data[0], to_read)
	if bytes_read == -1 {
		return -1, get_last_error()
	}
	return int(bytes_read), nil
}

write :: proc(fd: Handle, data: []byte) -> (int, Error) {
	if len(data) == 0 {
		return 0, nil
	}

	to_write      := min(c.size_t(len(data)), MAX_RW)
	bytes_written := _unix_write(fd, &data[0], to_write)
	if bytes_written == -1 {
		return -1, get_last_error()
	}
	return int(bytes_written), nil
}

read_at :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Error) {
	if len(data) == 0 {
		return 0, nil
	}

	to_read := min(uint(len(data)), MAX_RW)

	bytes_read := _unix_pread(fd, raw_data(data), to_read, offset)
	if bytes_read < 0 {
		return -1, get_last_error()
	}
	return bytes_read, nil
}

write_at :: proc(fd: Handle, data: []byte, offset: i64) -> (n: int, err: Error) {
	if len(data) == 0 {
		return 0, nil
	}

	to_write := min(uint(len(data)), MAX_RW)

	bytes_written := _unix_pwrite(fd, raw_data(data), to_write, offset)
	if bytes_written < 0 {
		return -1, get_last_error()
	}
	return bytes_written, nil
}

seek :: proc(fd: Handle, offset: i64, whence: int) -> (i64, Error) {
	switch whence {
	case SEEK_SET, SEEK_CUR, SEEK_END:
		break
	case:
		return 0, .Invalid_Whence
	}
	res := _unix_seek(fd, offset, c.int(whence))
	if res == -1 {
		errno := get_last_error()
		switch errno {
		case .BAD_VALUE:
			return 0, .Invalid_Offset
		}
		return 0, errno
	}
	return res, nil
}

@(require_results)
file_size :: proc(fd: Handle) -> (i64, Error) {
	s, err := _fstat(fd)
	if err != nil {
		return -1, err
	}
	return s.size, nil
}

// "Argv" arguments converted to Odin strings
args := _alloc_command_line_arguments()

@(require_results)
_alloc_command_line_arguments :: proc() -> []string {
	res := make([]string, len(runtime.args__))
	for arg, i in runtime.args__ {
		res[i] = string(arg)
	}
	return res
}

@(private, require_results)
_stat :: proc(path: string) -> (OS_Stat, Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)

	// deliberately uninitialized
	s: OS_Stat = ---
	res := _unix_stat(cstr, &s)
	if res == -1 {
		return s, get_last_error()
	}
	return s, nil
}

@(private, require_results)
_lstat :: proc(path: string) -> (OS_Stat, Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)

	// deliberately uninitialized
	s: OS_Stat = ---
	res := _unix_lstat(cstr, &s)
	if res == -1 {
		return s, get_last_error()
	}
	return s, nil
}

@(private, require_results)
_fstat :: proc(fd: Handle) -> (OS_Stat, Error) {
	// deliberately uninitialized
	s: OS_Stat = ---
	res := _unix_fstat(fd, &s)
	if res == -1 {
		return s, get_last_error()
	}
	return s, nil
}

@(private)
_fdopendir :: proc(fd: Handle) -> (Dir, Error) {
	dirp := _unix_fdopendir(fd)
	if dirp == cast(Dir)nil {
		return nil, get_last_error()
	}
	return dirp, nil
}

@(private)
_closedir :: proc(dirp: Dir) -> Error {
	rc := _unix_closedir(dirp)
	if rc != 0 {
		return get_last_error()
	}
	return nil
}

@(private)
_rewinddir :: proc(dirp: Dir) {
	_unix_rewinddir(dirp)
}

@(private, require_results)
_readdir :: proc(dirp: Dir) -> (entry: Dirent, err: Error, end_of_stream: bool) {
	result: ^Dirent
	rc := _unix_readdir_r(dirp, &entry, &result)

	if rc != 0 {
		err = get_last_error()
		return
	}

	if result == nil {
		end_of_stream = true
		return
	}

	return
}

@(private, require_results)
_readlink :: proc(path: string) -> (string, Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == context.allocator)
	path_cstr := strings.clone_to_cstring(path, context.temp_allocator)

	bufsz : uint = MAX_PATH
	buf := make([]byte, MAX_PATH)
	for {
		rc := _unix_readlink(path_cstr, &(buf[0]), bufsz)
		if rc == -1 {
			delete(buf)
			return "", get_last_error()
		} else if rc == int(bufsz) {
			bufsz += MAX_PATH
			delete(buf)
			buf = make([]byte, bufsz)
		} else {
			return strings.string_from_ptr(&buf[0], rc), nil
		}	
	}
}

@(require_results)
absolute_path_from_handle :: proc(fd: Handle) -> (string, Error) {
	return "", Error(ENOSYS)
}

@(require_results)
absolute_path_from_relative :: proc(rel: string, allocator := context.allocator) -> (path: string, err: Error) {
	rel := rel
	if rel == "" {
		rel = "."
	}

	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == context.allocator)
	rel_cstr := strings.clone_to_cstring(rel, context.temp_allocator)

	path_ptr := _unix_realpath(rel_cstr, nil)
	if path_ptr == nil {
		return "", get_last_error()
	}
	defer _unix_free(rawptr(path_ptr))

	path_cstr := cstring(path_ptr)
	return strings.clone(string(path_cstr), allocator)
}

access :: proc(path: string, mask: int) -> (bool, Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	cstr := strings.clone_to_cstring(path, context.temp_allocator)
	res := _unix_access(cstr, c.int(mask))
	if res == -1 {
		return false, get_last_error()
	}
	return true, nil
}

@(require_results)
lookup_env :: proc(key: string, allocator := context.allocator) -> (value: string, found: bool) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = context.temp_allocator == allocator)
	path_str := strings.clone_to_cstring(key, context.temp_allocator)
	cstr := _unix_getenv(path_str)
	if cstr == nil {
		return "", false
	}
	return strings.clone(string(cstr), allocator), true
}

@(require_results)
get_env :: proc(key: string, allocator := context.allocator) -> (value: string) {
	value, _ = lookup_env(key, allocator)
	return
}

@(private, require_results)
_processor_core_count :: proc() -> int {
	info: haiku.system_info
	haiku.get_system_info(&info)
	return int(info.cpu_count)
}

exit :: proc "contextless" (code: int) -> ! {
	runtime._cleanup_runtime_contextless()
	_unix_exit(i32(code))
}

@(require_results)
current_thread_id :: proc "contextless" () -> int {
	return int(haiku.find_thread(nil))
}

@(private, require_results)
_dup :: proc(fd: Handle) -> (Handle, Error) {
	dup := _unix_dup(fd)
	if dup == -1 {
		return INVALID_HANDLE, get_last_error()
	}
	return dup, nil
}
