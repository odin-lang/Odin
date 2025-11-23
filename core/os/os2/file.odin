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

// Represents the file flags for a file handle
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

Permissions :: distinct bit_set[Permission_Flag; u32]
Permission_Flag :: enum u32 {
	Execute_Other = 0,
	Write_Other   = 1,
	Read_Other    = 2,

	Execute_Group = 3,
	Write_Group   = 4,
	Read_Group    = 5,

	Execute_User  = 6,
	Write_User    = 7,
	Read_User     = 8,
}

Permissions_Execute_All :: Permissions{.Execute_User, .Execute_Group, .Execute_Other}
Permissions_Write_All   :: Permissions{.Write_User,   .Write_Group,   .Write_Other}
Permissions_Read_All    :: Permissions{.Read_User,    .Read_Group,    .Read_Other}

Permissions_Read_Write_All :: Permissions_Read_All + Permissions_Write_All

Permissions_All :: Permissions_Read_All + Permissions_Write_All + Permissions_Execute_All

Permissions_Default_File      :: Permissions_Read_All + Permissions_Write_All
Permissions_Default_Directory :: Permissions_Read_All + Permissions_Write_All + Permissions_Execute_All
Permissions_Default           :: Permissions_Default_Directory

perm :: proc{
	perm_number,
}

/*
	`perm_number` converts an integer value `perm` to the bit set `Permissions`
*/
@(require_results)
perm_number :: proc "contextless" (perm: int) -> Permissions {
	return transmute(Permissions)u32(perm & 0o777)
}



// `stdin` is an open file pointing to the standard input file stream
stdin:  ^File = nil // OS-Specific

// `stdout` is an open file pointing to the standard output file stream
stdout: ^File = nil // OS-Specific

// `stderr` is an open file pointing to the standard error file stream
stderr: ^File = nil // OS-Specific

/*
	`create` creates or truncates a named file `name`.
	If the file already exists, it is truncated.
	If the file does not exist, it is created with the `Permissions_Default_File` permissions.
	If successful, a `^File` is return which can be used for I/O.
	And error is returned if any is encountered.
*/
@(require_results)
create :: proc(name: string) -> (^File, Error) {
	return open(name, {.Read, .Write, .Create, .Trunc}, Permissions_Default_File)
}

/*
	`open` is a generalized open call, which defaults to opening for reading.
	If the file does not exist, and the `{.Create}` flag is passed, it is created with the permissions `perm`,
	and please note that the containing directory must exist otherwise and an error will be returned.
	If successful, a `^File` is return which can be used for I/O.
	And error is returned if any is encountered.
*/
@(require_results)
open :: proc(name: string, flags := File_Flags{.Read}, perm := Permissions_Default) -> (^File, Error) {
	return _open(name, flags, perm)
}

// @(require_results)
// open_buffered :: proc(name: string, buffer_size: uint, flags := File_Flags{.Read}, perm := 0o777) -> (^File, Error) {
// 	if buffer_size == 0 {
// 		return _open(name, flags, perm)
// 	}
// 	return _open_buffered(name, buffer_size, flags, perm)
// }

/*
	`new_file` returns a new `^File` with the given file descriptor `handle` and `name`.
	The return value will only be `nil` IF the `handle` is not a valid file descriptor.
*/
@(require_results)
new_file :: proc(handle: uintptr, name: string) -> ^File {
	file, err := _new_file(handle, name, file_allocator())
	if err != nil {
		panic(error_string(err))
	}
	return file
}

/*
	`clone` returns a new `^File` based on the passed file `f` with the same underlying file descriptor.
*/
@(require_results)
clone :: proc(f: ^File) -> (^File, Error) {
	return _clone(f)
}

/*
	`fd` returns the file descriptor of the file `f` passed. If the file is not valid, an invalid handle will be returned.
*/
@(require_results)
fd :: proc(f: ^File) -> uintptr {
	return _fd(f)
}

/*
	`name` returns the name of the file. The lifetime of this string lasts as long as the file handle itself.
*/
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

/*
	seek sets the offsets for the next read or write on a file to a specified `offset`,
	according to what `whence` is set.
	`.Start` is relative to the origin of the file.
	`.Current` is relative to the current offset.
	`.End` is relative to the end.
	It returns the new offset and an error, if any is encountered.
	Prefer `read_at` or `write_at` if the offset does not want to be changed.

*/
seek :: proc(f: ^File, offset: i64, whence: io.Seek_From) -> (ret: i64, err: Error) {
	if f != nil {
		return io.seek(f.stream, offset, whence)
	}
	return 0, .Invalid_File
}

/*
	`read` reads up to len(p) bytes from the file `f`, and then stores them in `p`.
	It returns the number of bytes read and an error, if any is encountered.
	At the end of a file, it returns `0, io.EOF`.
*/
read :: proc(f: ^File, p: []byte) -> (n: int, err: Error) {
	if f != nil {
		return io.read(f.stream, p)
	}
	return 0, .Invalid_File
}

/*
	`read_at` reads up to len(p) bytes from the file `f` at the byte offset `offset`, and then stores them in `p`.
	It returns the number of bytes read and an error, if any is encountered.
	`read_at` always returns a non-nil error when `n < len(p)`.
	At the end of a file, the error is `io.EOF`.
*/
read_at :: proc(f: ^File, p: []byte, offset: i64) -> (n: int, err: Error) {
	if f != nil {
		return io.read_at(f.stream, p, offset)
	}
	return 0, .Invalid_File
}

/*
	`write` writes `len(p)` bytes from `p` to the file `f`. It returns the number of bytes written to
	and an error, if any is encountered.
	`write` returns a non-nil error when `n != len(p)`.
*/
write :: proc(f: ^File, p: []byte) -> (n: int, err: Error) {
	if f != nil {
		return io.write(f.stream, p)
	}
	return 0, .Invalid_File
}

/*
	`write_at` writes `len(p)` bytes from `p` to the file `f` starting at byte offset `offset`.
	It returns the number of bytes written to and an error, if any is encountered.
	`write_at` returns a non-nil error when `n != len(p)`.
*/
write_at :: proc(f: ^File, p: []byte, offset: i64) -> (n: int, err: Error) {
	if f != nil {
		return io.write_at(f.stream, p, offset)
	}
	return 0, .Invalid_File
}

/*
	`file_size` returns the length of the file `f` in bytes and an error, if any is encountered.
*/
file_size :: proc(f: ^File) -> (n: i64, err: Error) {
	if f != nil {
		return io.size(f.stream)
	}
	return 0, .Invalid_File
}

/*
	`flush` flushes a file `f`
*/
flush :: proc(f: ^File) -> Error {
	if f != nil {
		return io.flush(f.stream)
	}
	return nil
}

/*
	`sync` commits the current contents of the file `f` to stable storage.
	This usually means flushing the file system's in-memory copy to disk.
*/
sync :: proc(f: ^File) -> Error {
	return _sync(f)
}

/*
	`truncate` changes the size of the file `f` to `size` in bytes.
	This can be used to shorten or lengthen a file.
	It does not change the "offset" of the file.
*/
truncate :: proc(f: ^File, size: i64) -> Error {
	return _truncate(f, size)
}

/*
	`remove` removes a named file or (empty) directory.
*/
remove :: proc(name: string) -> Error {
	return _remove(name)
}

/*
	`rename`  renames (moves) `old_path` to `new_path`.
*/
rename :: proc(old_path, new_path: string) -> Error {
	return _rename(old_path, new_path)
}

/*
	`link` creates a `new_name` as a hard link to the `old_name` file.
*/
link :: proc(old_name, new_name: string) -> Error {
	return _link(old_name, new_name)
}

/*
	`symlink` creates a `new_name` as a symbolic link to the `old_name` file.
*/
symlink :: proc(old_name, new_name: string) -> Error {
	return _symlink(old_name, new_name)
}

/*
	`read_link` returns the destinction of the named symbolic link `name`.
*/
read_link :: proc(name: string, allocator: runtime.Allocator) -> (string, Error) {
	return _read_link(name,allocator)
}


chdir :: change_directory

/*
	Changes the current working directory to the named directory.
*/
change_directory :: proc(name: string) -> Error {
	return _chdir(name)
}

chmod :: change_mode

/*
	Changes the mode/permissions of the named file to `mode`.
	If the file is a symbolic link, it changes the mode of the link's target.

	On Windows, only `{.Write_User}` of `mode` is used, and controls whether or not
	the file has a read-only attribute. Use `{.Read_User}` for a read-only file and
	`{.Read_User, .Write_User}` for a readable & writable file.
*/
change_mode :: proc(name: string, mode: Permissions) -> Error {
	return _chmod(name, mode)
}

chown :: change_owner

/*
	Changes the numeric `uid` and `gid` of a named file. If the file is a symbolic link,
	it changes the `uid` and `gid` of the link's target.

	On Windows, it always returns an error.
*/
change_owner :: proc(name: string, uid, gid: int) -> Error {
	return _chown(name, uid, gid)
}

fchdir :: fchange_directory

/*
	Changes the current working directory to the file, which must be a directory.
*/
fchange_directory :: proc(f: ^File) -> Error {
	return _fchdir(f)
}

fchmod :: fchange_mode

/*
	Changes the current `mode` permissions of the file `f`.
*/
fchange_mode :: proc(f: ^File, mode: Permissions) -> Error {
	return _fchmod(f, mode)
}

fchown :: fchange_owner

/*
	Changes the numeric `uid` and `gid` of the file `f`. If the file is a symbolic link,
	it changes the `uid` and `gid` of the link's target.

	On Windows, it always returns an error.
*/
fchange_owner :: proc(f: ^File, uid, gid: int) -> Error {
	return _fchown(f, uid, gid)
}


lchown :: change_owner_do_not_follow_links

/*
	Changes the numeric `uid` and `gid` of the file `f`. If the file is a symbolic link,
	it changes the `uid` and `gid` of the lin itself.

	On Windows, it always returns an error.
*/
change_owner_do_not_follow_links :: proc(name: string, uid, gid: int) -> Error {
	return _lchown(name, uid, gid)
}

chtimes :: change_times

/*
	Changes the access `atime` and modification `mtime` times of a named file.
*/
change_times :: proc(name: string, atime, mtime: time.Time) -> Error {
	return _chtimes(name, atime, mtime)
}

fchtimes :: fchange_times

/*
	Changes the access `atime` and modification `mtime` times of the file `f`.
*/
fchange_times :: proc(f: ^File, atime, mtime: time.Time) -> Error {
	return _fchtimes(f, atime, mtime)
}

/*
	`exists` returns whether or not a named file exists.
*/
@(require_results)
exists :: proc(path: string) -> bool {
	return _exists(path)
}

/*
	`is_file` returns whether or not the type of a named file is a `File_Type.Regular` file.
*/
@(require_results)
is_file :: proc(path: string) -> bool {
	temp_allocator := TEMP_ALLOCATOR_GUARD({})
	fi, err := stat(path, temp_allocator)
	if err != nil {
		return false
	}
	return fi.type == .Regular
}

is_dir :: is_directory

/*
	Returns whether or not the type of a named file is a `File_Type.Directory` file.
*/
@(require_results)
is_directory :: proc(path: string) -> bool {
	temp_allocator := TEMP_ALLOCATOR_GUARD({})
	fi, err := stat(path, temp_allocator)
	if err != nil {
		return false
	}
	return fi.type == .Directory
}

/*
	`copy_file` copies a file from `src_path` to `dst_path` and returns an error if any was encountered.
*/
copy_file :: proc(dst_path, src_path: string) -> Error {
	when #defined(_copy_file_native) {
		return _copy_file_native(dst_path, src_path)
	} else {
		return _copy_file(dst_path, src_path)
	}
}

@(private)
_copy_file :: proc(dst_path, src_path: string) -> Error {
	src := open(src_path) or_return
	defer close(src)

	info := fstat(src, file_allocator()) or_return
	defer file_info_delete(info, file_allocator())
	if info.type == .Directory {
		return .Invalid_File
	}

	dst := open(dst_path, {.Read, .Write, .Create, .Trunc}, info.mode & Permissions_All) or_return
	defer close(dst)

	_, err := io.copy(to_writer(dst), to_reader(src))
	return err
}
