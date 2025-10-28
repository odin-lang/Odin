#+build js wasm32, js wasm64p32
#+private
package os2

import "base:runtime"

import "core:io"
import "core:time"

File_Impl :: distinct rawptr

_open :: proc(name: string, flags: File_Flags, perm: int) -> (f: ^File, err: Error) {
	return nil, .Unsupported
}

_new_file :: proc(handle: uintptr, name: string, allocator: runtime.Allocator) -> (f: ^File, err: Error) {
	return nil, .Unsupported
}

_clone :: proc(f: ^File) -> (clone: ^File, err: Error) {
	return nil, .Unsupported
}

_close :: proc(f: ^File_Impl) -> (err: Error) {
	return .Unsupported
}

_fd :: proc(f: ^File) -> uintptr {
	return 0
}

_is_tty :: proc "contextless" (f: ^File) -> bool {
	return true
}

_name :: proc(f: ^File) -> string {
	return ""
}

_sync :: proc(f: ^File) -> Error {
	return .Unsupported
}

_truncate :: proc(f: ^File, size: i64) -> Error {
	return .Unsupported
}

_remove :: proc(name: string) -> Error {
	return .Unsupported
}

_rename :: proc(old_path, new_path: string) -> Error {
	return .Unsupported
}

_link :: proc(old_name, new_name: string) -> Error {
	return .Unsupported
}

_symlink :: proc(old_name, new_name: string) -> Error {
	return .Unsupported
}

_read_link :: proc(name: string, allocator: runtime.Allocator) -> (s: string, err: Error) {
	return "", .Unsupported
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
	return .Unsupported
}

_fchtimes :: proc(f: ^File, atime, mtime: time.Time) -> Error {
	return .Unsupported
}

_exists :: proc(path: string) -> bool {
	return false
}

_file_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	return 0, .Empty
}