package os2

import "core:io"
import "core:time"
import "base:runtime"

/*
	Type representing a file handle.

	This struct represents an OS-specific file-handle, which can be one of
	the following:
	- File
	- Directory
	- Pipe
	- Named pipe
	- Block Device
	- Character device
	- Symlink
	- Socket

	See `File_Type` enum for more information on file types.
*/
File :: struct {
	impl:   rawptr,
	stream: io.Stream,
	fstat:  Fstat_Callback,
}

/*
	Type representing the type of a file handle.

	**Note(windows)**: Socket handles can not be distinguished from
	files, as they are just a normal file handle that is being treated by
	a special driver. Windows also makes no distinction between block and
	character devices.
*/
File_Type :: enum {
	// The type of a file could not be determined for the current platform.
	Undetermined,
	// Represents a regular file.
	Regular,
	// Represents a directory.
	Directory,
	// Represents a symbolic link.
	Symlink,
	// Represents a named pipe (FIFO).
	Named_Pipe,
	// Represents a socket.
	// **Note(windows)**: Not returned on windows
	Socket,
	// Represents a block device.
	// **Note(windows)**: On windows represents all devices.
	Block_Device,
	// Represents a character device.
	// **Note(windows)**: Not returned on windows
	Character_Device,
}

File_Flags :: distinct bit_set[File_Flag; uint]
File_Flag :: enum {
	Read,
	Write,
	Append,
	Create,
	Excl,
	Sync,
	Trunc,
	Sparse,
	Inheritable,

	Unbuffered_IO,
}

O_RDONLY  :: File_Flags{.Read}
O_WRONLY  :: File_Flags{.Write}
O_RDWR    :: File_Flags{.Read, .Write}
O_APPEND  :: File_Flags{.Append}
O_CREATE  :: File_Flags{.Create}
O_EXCL    :: File_Flags{.Excl}
O_SYNC    :: File_Flags{.Sync}
O_TRUNC   :: File_Flags{.Trunc}
O_SPARSE  :: File_Flags{.Sparse}

/*
	If specified, the file handle is inherited upon the creation of a child
	process. By default all handles are created non-inheritable.

	**Note**: The standard file handles (stderr, stdout and stdin) are always
	initialized as inheritable.
*/
O_INHERITABLE :: File_Flags{.Inheritable}

stdin:  ^File = nil // OS-Specific
stdout: ^File = nil // OS-Specific
stderr: ^File = nil // OS-Specific

@(require_results)
create :: proc(name: string) -> (^File, Error) {
	return open(name, {.Read, .Write, .Create}, 0o777)
}

@(require_results)
open :: proc(name: string, flags := File_Flags{.Read}, perm := 0o777) -> (^File, Error) {
	return _open(name, flags, perm)
}

// @(require_results)
// open_buffered :: proc(name: string, buffer_size: uint, flags := File_Flags{.Read}, perm := 0o777) -> (^File, Error) {
// 	if buffer_size == 0 {
// 		return _open(name, flags, perm)
// 	}
// 	return _open_buffered(name, buffer_size, flags, perm)
// }


@(require_results)
new_file :: proc(handle: uintptr, name: string) -> ^File {
	file, err := _new_file(handle, name, file_allocator())
	if err != nil {
		panic(error_string(err))
	}
	return file
}

@(require_results)
clone :: proc(f: ^File) -> (^File, Error) {
	return _clone(f)
}

@(require_results)
fd :: proc(f: ^File) -> uintptr {
	return _fd(f)
}

@(require_results)
name :: proc(f: ^File) -> string {
	return _name(f)
}

/*
	Close a file and its stream.

	Any further use of the file or its stream should be considered to be in the
	same class of bugs as a use-after-free.
*/
close :: proc(f: ^File) -> Error {
	if f != nil {
		return io.close(f.stream)
	}
	return nil
}

seek :: proc(f: ^File, offset: i64, whence: io.Seek_From) -> (ret: i64, err: Error) {
	if f != nil {
		return io.seek(f.stream, offset, whence)
	}
	return 0, .Invalid_File
}

read :: proc(f: ^File, p: []byte) -> (n: int, err: Error) {
	if f != nil {
		return io.read(f.stream, p)
	}
	return 0, .Invalid_File
}

read_at :: proc(f: ^File, p: []byte, offset: i64) -> (n: int, err: Error) {
	if f != nil {
		return io.read_at(f.stream, p, offset)
	}
	return 0, .Invalid_File
}

write :: proc(f: ^File, p: []byte) -> (n: int, err: Error) {
	if f != nil {
		return io.write(f.stream, p)
	}
	return 0, .Invalid_File
}

write_at :: proc(f: ^File, p: []byte, offset: i64) -> (n: int, err: Error) {
	if f != nil {
		return io.write_at(f.stream, p, offset)
	}
	return 0, .Invalid_File
}

file_size :: proc(f: ^File) -> (n: i64, err: Error) {
	if f != nil {
		return io.size(f.stream)
	}
	return 0, .Invalid_File
}

flush :: proc(f: ^File) -> Error {
	if f != nil {
		return io.flush(f.stream)
	}
	return nil
}

sync :: proc(f: ^File) -> Error {
	return _sync(f)
}

truncate :: proc(f: ^File, size: i64) -> Error {
	return _truncate(f, size)
}

remove :: proc(name: string) -> Error {
	return _remove(name)
}

rename :: proc(old_path, new_path: string) -> Error {
	return _rename(old_path, new_path)
}


link :: proc(old_name, new_name: string) -> Error {
	return _link(old_name, new_name)
}

symlink :: proc(old_name, new_name: string) -> Error {
	return _symlink(old_name, new_name)
}

read_link :: proc(name: string, allocator: runtime.Allocator) -> (string, Error) {
	return _read_link(name,allocator)
}


chdir :: change_directory

change_directory :: proc(name: string) -> Error {
	return _chdir(name)
}

chmod :: change_mode

change_mode :: proc(name: string, mode: int) -> Error {
	return _chmod(name, mode)
}

chown :: change_owner

change_owner :: proc(name: string, uid, gid: int) -> Error {
	return _chown(name, uid, gid)
}

fchdir :: fchange_directory

fchange_directory :: proc(f: ^File) -> Error {
	return _fchdir(f)
}

fchmod :: fchange_mode

fchange_mode :: proc(f: ^File, mode: int) -> Error {
	return _fchmod(f, mode)
}

fchown :: fchange_owner

fchange_owner :: proc(f: ^File, uid, gid: int) -> Error {
	return _fchown(f, uid, gid)
}


lchown :: change_owner_do_not_follow_links

change_owner_do_not_follow_links :: proc(name: string, uid, gid: int) -> Error {
	return _lchown(name, uid, gid)
}

chtimes :: change_times

change_times :: proc(name: string, atime, mtime: time.Time) -> Error {
	return _chtimes(name, atime, mtime)
}

fchtimes :: fchange_times

fchange_times :: proc(f: ^File, atime, mtime: time.Time) -> Error {
	return _fchtimes(f, atime, mtime)
}

@(require_results)
exists :: proc(path: string) -> bool {
	return _exists(path)
}

@(require_results)
is_file :: proc(path: string) -> bool {
	TEMP_ALLOCATOR_GUARD()
	fi, err := stat(path, temp_allocator())
	if err != nil {
		return false
	}
	return fi.type == .Regular
}

is_dir :: is_directory

@(require_results)
is_directory :: proc(path: string) -> bool {
	TEMP_ALLOCATOR_GUARD()
	fi, err := stat(path, temp_allocator())
	if err != nil {
		return false
	}
	return fi.type == .Directory
}


copy_file :: proc(dst_path, src_path: string) -> Error {
	src := open(src_path) or_return
	defer close(src)

	info := fstat(src, file_allocator()) or_return
	defer file_info_delete(info, file_allocator())
	if info.type == .Directory {
		return .Invalid_File
	}

	dst := open(dst_path, {.Read, .Write, .Create, .Trunc}, info.mode & 0o777) or_return
	defer close(dst)

	_, err := io.copy(to_writer(dst), to_reader(src))
	return err
}
