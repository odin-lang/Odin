package os2

import "core:io"
import "core:time"

File :: struct {
	impl: _File,
}

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


O_RDONLY :: int( 0)
O_WRONLY :: int( 1)
O_RDWR   :: int( 2)
O_APPEND :: int( 4)
O_CREATE :: int( 8)
O_EXCL   :: int(16)
O_SYNC   :: int(32)
O_TRUNC  :: int(64)



stdin:  ^File = nil // OS-Specific
stdout: ^File = nil // OS-Specific
stderr: ^File = nil // OS-Specific


create :: proc(name: string) -> (^File, Error) {
	return _create(name)
}

open :: proc(name: string) -> (^File, Error) {
	return _open(name)
}

open_file :: proc(name: string, flag: int, perm: File_Mode) -> (^File, Error) {
	return _open_file(name, flag, perm)
}

new_file :: proc(handle: uintptr, name: string) -> ^File {
	return _new_file(handle, name)
}


close :: proc(f: ^File) -> Error {
	return _close(f)
}

name :: proc(f: ^File, allocator := context.allocator) -> string {
	return _name(f)
}

seek :: proc(f: ^File, offset: i64, whence: Seek_From) -> (ret: i64, err: Error) {
	return _seek(f, offset, whence)
}

read :: proc(f: ^File, p: []byte) -> (n: int, err: Error) {
	return _read(f, p)
}

read_at :: proc(f: ^File, p: []byte, offset: i64) -> (n: int, err: Error) {
	return _read_at(f, p, offset)
}

read_from :: proc(f: ^File, r: io.Reader) -> (n: i64, err: Error) {
	return _read_from(f, r)
}

write :: proc(f: ^File, p: []byte) -> (n: int, err: Error) {
	return _write(f, p)
}

write_at :: proc(f: ^File, p: []byte, offset: i64) -> (n: int, err: Error) {
	return _write_at(f, p, offset)
}

write_to :: proc(f: ^File, w: io.Writer) -> (n: i64, err: Error) {
	return _write_to(f, w)
}

file_size :: proc(f: ^File) -> (n: i64, err: Error) {
	return _file_size(f)
}


sync :: proc(f: ^File) -> Error {
	return _sync(f)
}

flush :: proc(f: ^File) -> Error {
	return _flush(f)
}

truncate :: proc(f: ^File, size: i64) -> Maybe(Path_Error) {
	return _truncate(f, size)
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


chdir :: proc(f: ^File) -> Error {
	return _chdir(f)
}

chmod :: proc(f: ^File, mode: File_Mode) -> Error {
	return _chmod(f, mode)
}

chown :: proc(f: ^File, uid, gid: int) -> Error {
	return _chown(f, uid, gid)
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

