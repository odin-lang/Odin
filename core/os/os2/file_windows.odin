//+private
package os2

import "core:io"
import "core:time"

_create :: proc(name: string) -> (Handle, Error) {
	return 0, nil
}

_open :: proc(name: string) -> (Handle, Error) {
	return 0, nil
}

_open_file :: proc(name: string, flags: File_Flags, perm: File_Mode) -> (Handle, Error) {
	return 0, nil
}

_close :: proc(fd: Handle) -> Error {
	return nil
}

_name :: proc(fd: Handle, allocator := context.allocator) -> string {
	return ""
}

_seek :: proc(fd: Handle, offset: i64, whence: Seek_From) -> (ret: i64, err: Error) {
	return
}

_read :: proc(fd: Handle, p: []byte) -> (n: int, err: Error) {
	return
}

_read_at :: proc(fd: Handle, p: []byte, offset: i64) -> (n: int, err: Error) {
	return
}

_read_from :: proc(fd: Handle, r: io.Reader) -> (n: i64, err: Error) {
	return
}

_write :: proc(fd: Handle, p: []byte) -> (n: int, err: Error) {
	return
}

_write_at :: proc(fd: Handle, p: []byte, offset: i64) -> (n: int, err: Error) {
	return
}

_write_to :: proc(fd: Handle, w: io.Writer) -> (n: i64, err: Error) {
	return
}

_file_size :: proc(fd: Handle) -> (n: i64, err: Error) {
	return
}


_sync :: proc(fd: Handle) -> Error {
	return nil
}

_flush :: proc(fd: Handle) -> Error {
	return nil
}

_truncate :: proc(fd: Handle, size: i64) -> Maybe(Path_Error) {
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


_chdir :: proc(fd: Handle) -> Error {
	return nil
}

_chmod :: proc(fd: Handle, mode: File_Mode) -> Error {
	return nil
}

_chown :: proc(fd: Handle, uid, gid: int) -> Error {
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
