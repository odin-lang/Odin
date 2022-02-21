package os2

import "core:io"
import "core:time"

Handle :: distinct uintptr

Seek_From :: enum {
	Start   = 0, // seek relative to the origin of the file
	Current = 1, // seek relative to the current offset
	End     = 2, // seek relative to the end
}

File_Mode :: distinct u32
File_Mode_Dir         :: File_Mode(1<<16)
File_Mode_Named_Pipe  :: File_Mode(1<<17)
File_Mode_Device      :: File_Mode(1<<18)
File_Mode_Char_Device :: File_Mode(1<<19)
File_Mode_Sym_Link    :: File_Mode(1<<20)


File_Flag :: enum u32 {
	Read   = 0,
	Write  = 1,
	Append = 2,
	Create = 3,
	Excl   = 4,
	Sync   = 5,
	Trunc  = 6,
}
File_Flags :: distinct bit_set[File_Flag; u32]

O_RDONLY :: File_Flags{.Read}
O_WRONLY :: File_Flags{.Write}
O_RDWR   :: File_Flags{.Read, .Write}
O_APPEND :: File_Flags{.Append}
O_CREATE :: File_Flags{.Create}
O_EXCL   :: File_Flags{.Excl}
O_SYNC   :: File_Flags{.Sync}
O_TRUNC  :: File_Flags{.Trunc}



stdin:  Handle = 0 // OS-Specific
stdout: Handle = 1 // OS-Specific
stderr: Handle = 2 // OS-Specific


create :: proc(name: string) -> (Handle, Error) {
	return _create(name)
}

open :: proc(name: string) -> (Handle, Error) {
	return _open(name)
}

open_file :: proc(name: string, flags: File_Flags, perm: File_Mode) -> (Handle, Error) {
	return _open_file(name, flags, perm)
}

close :: proc(fd: Handle) -> Error {
	return _close(fd)
}

name :: proc(fd: Handle, allocator := context.allocator) -> string {
	return _name(fd)
}

seek :: proc(fd: Handle, offset: i64, whence: Seek_From) -> (ret: i64, err: Error) {
	return _seek(fd, offset, whence)
}

read :: proc(fd: Handle, p: []byte) -> (n: int, err: Error) {
	return _read(fd, p)
}

read_at :: proc(fd: Handle, p: []byte, offset: i64) -> (n: int, err: Error) {
	return _read_at(fd, p, offset)
}

read_from :: proc(fd: Handle, r: io.Reader) -> (n: i64, err: Error) {
	return _read_from(fd, r)
}

write :: proc(fd: Handle, p: []byte) -> (n: int, err: Error) {
	return _write(fd, p)
}

write_at :: proc(fd: Handle, p: []byte, offset: i64) -> (n: int, err: Error) {
	return _write_at(fd, p, offset)
}

write_to :: proc(fd: Handle, w: io.Writer) -> (n: i64, err: Error) {
	return _write_to(fd, w)
}

file_size :: proc(fd: Handle) -> (n: i64, err: Error) {
	return _file_size(fd)
}


sync :: proc(fd: Handle) -> Error {
	return _sync(fd)
}

flush :: proc(fd: Handle) -> Error {
	return _flush(fd)
}

truncate :: proc(fd: Handle, size: i64) -> Maybe(Path_Error) {
	return _truncate(fd, size)
}

remove :: proc(name: string) -> Maybe(Path_Error) {
	return _remove(name)
}

rename :: proc(old_path, new_path: string) -> Maybe(Path_Error) {
	return _rename(old_path, new_path)
}


link :: proc(old_name, new_name: string) -> Maybe(Link_Error) {
	return _link(old_name, new_name)
}

symlink :: proc(old_name, new_name: string) -> Maybe(Link_Error) {
	return _symlink(old_name, new_name)
}

read_link :: proc(name: string) -> (string, Maybe(Path_Error)) {
	return _read_link(name)
}


chdir :: proc(fd: Handle) -> Error {
	return _chdir(fd)
}

chmod :: proc(fd: Handle, mode: File_Mode) -> Error {
	return _chmod(fd, mode)
}

chown :: proc(fd: Handle, uid, gid: int) -> Error {
	return _chown(fd, uid, gid)
}


lchown :: proc(name: string, uid, gid: int) -> Error {
	return _lchown(name, uid, gid)
}


chtimes :: proc(name: string, atime, mtime: time.Time) -> Maybe(Path_Error) {
	return _chtimes(name, atime, mtime)
}

exists :: proc(path: string) -> bool {
	return _exists(path)
}

is_file :: proc(path: string) -> bool {
	return _is_file(path)
}

is_dir :: proc(path: string) -> bool {
	return _is_dir(path)
}

