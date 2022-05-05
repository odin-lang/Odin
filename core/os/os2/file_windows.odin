//+private
package os2

import "core:io"
import "core:time"

_File :: struct {
	fd:   rawptr,
	name: string,
}

_create :: proc(name: string) -> (^File, Error) {
	return nil, nil
}

_open :: proc(name: string) -> (^File, Error) {
	return nil, nil
}

_open_file :: proc(name: string, flag: int, perm: File_Mode) -> (^File, Error) {
	return nil, nil
}

_new_file :: proc(handle: uintptr, name: string) -> ^File {
	return nil
}

_close :: proc(f: ^File) -> Error {
	return nil
}

_name :: proc(f: ^File, allocator := context.allocator) -> string {
	return ""
}

_seek :: proc(f: ^File, offset: i64, whence: Seek_From) -> (ret: i64, err: Error) {
	return
}

_read :: proc(f: ^File, p: []byte) -> (n: int, err: Error) {
	return
}

_read_at :: proc(f: ^File, p: []byte, offset: i64) -> (n: int, err: Error) {
	return
}

_read_from :: proc(f: ^File, r: io.Reader) -> (n: i64, err: Error) {
	return
}

_write :: proc(f: ^File, p: []byte) -> (n: int, err: Error) {
	return
}

_write_at :: proc(f: ^File, p: []byte, offset: i64) -> (n: int, err: Error) {
	return
}

_write_to :: proc(f: ^File, w: io.Writer) -> (n: i64, err: Error) {
	return
}

_file_size :: proc(f: ^File) -> (n: i64, err: Error) {
	return
}


_sync :: proc(f: ^File) -> Error {
	return nil
}

_flush :: proc(f: ^File) -> Error {
	return nil
}

_truncate :: proc(f: ^File, size: i64) -> Maybe(Path_Error) {
	return nil
}

_remove :: proc(name: string) -> Maybe(Path_Error) {
	return nil
}

_rename :: proc(old_path, new_path: string) -> Maybe(Path_Error) {
	return nil
}


_link :: proc(old_name, new_name: string) -> Maybe(Link_Error) {
	return nil
}

_symlink :: proc(old_name, new_name: string) -> Maybe(Link_Error) {
	return nil
}

_read_link :: proc(name: string) -> (string, Maybe(Path_Error)) {
	return "", nil
}


_chdir :: proc(f: ^File) -> Error {
	return nil
}

_chmod :: proc(f: ^File, mode: File_Mode) -> Error {
	return nil
}

_chown :: proc(f: ^File, uid, gid: int) -> Error {
	return nil
}


_lchown :: proc(name: string, uid, gid: int) -> Error {
	return nil
}


_chtimes :: proc(name: string, atime, mtime: time.Time) -> Maybe(Path_Error) {
	return nil
}


_exists :: proc(path: string) -> bool {
	return false
}

_is_file :: proc(path: string) -> bool {
	return false
}

_is_dir :: proc(path: string) -> bool {
	return false
}


_path_error_delete :: proc(perr: Maybe(Path_Error)) {

}

_link_error_delete :: proc(lerr: Maybe(Link_Error)) {

}
