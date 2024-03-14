package os2

import "core:io"
import "core:time"
import "base:runtime"

File :: struct {
	impl: _File,
	stream: io.Stream,
}

File_Mode :: distinct u32
File_Mode_Dir         :: File_Mode(1<<16)
File_Mode_Named_Pipe  :: File_Mode(1<<17)
File_Mode_Device      :: File_Mode(1<<18)
File_Mode_Char_Device :: File_Mode(1<<19)
File_Mode_Sym_Link    :: File_Mode(1<<20)

File_Mode_Perm :: File_Mode(0o777) // Unix permision bits

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
	Close_On_Exec,

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
O_CLOEXEC :: File_Flags{.Close_On_Exec}



stdin:  ^File = nil // OS-Specific
stdout: ^File = nil // OS-Specific
stderr: ^File = nil // OS-Specific


create :: proc(name: string) -> (^File, Error) {
	return open(name, {.Read, .Write, .Create}, File_Mode(0o777))
}

open :: proc(name: string, flags := File_Flags{.Read}, perm := File_Mode(0o777)) -> (^File, Error) {
	return _open(name, flags, perm)
}

new_file :: proc(handle: uintptr, name: string) -> ^File {
	return _new_file(handle, name)
}

fd :: proc(f: ^File) -> uintptr {
	return _fd(f)
}

name :: proc(f: ^File) -> string {
	return _name(f)
}

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
change_mode :: proc(name: string, mode: File_Mode) -> Error {
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
fchange_mode :: proc(f: ^File, mode: File_Mode) -> Error {
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

exists :: proc(path: string) -> bool {
	return _exists(path)
}

is_file :: proc(path: string) -> bool {
	return _is_file(path)
}

is_dir :: is_directory
is_directory :: proc(path: string) -> bool {
	return _is_dir(path)
}


copy_file :: proc(dst_path, src_path: string) -> Error {
	src := open(src_path) or_return
	defer close(src)

	info := fstat(src, _file_allocator()) or_return
	defer file_info_delete(info, _file_allocator())
	if info.is_directory {
		return .Invalid_File
	}

	dst := open(dst_path, {.Read, .Write, .Create, .Trunc}, info.mode & File_Mode_Perm) or_return
	defer close(dst)

	_, err := io.copy(to_writer(dst), to_reader(src))
	return err
}