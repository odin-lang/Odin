//+private
package os2

import "core:strings"
import "core:io"
import "core:sys/unix"
import "core:time"

_create :: proc(name: string) -> (Handle, Error) {
    fd := unix.open(name, O_CREATE, 0);
    return transmute(Handle)fd, _unix_errno(fd);
}

_open :: proc(name: string) -> (Handle, Error) {
    fd := unix.open(name, O_RDONLY, 0);
    return transmute(Handle)fd, _unix_errno(fd);
}

_open_file :: proc(name: string, flag: int, perm: File_Mode) -> (Handle, Error) {
    // TODO(rytc): Do checking of file_mode?
    fd := unix.open(name, flag, transmute(u32)perm);
    return transmute(Handle)fd, _unix_errno(fd);
}

_close :: proc(fd: Handle) -> Error {
    result := unix.close(transmute(int)fd);
    return _unix_errno(result);
}

// NOTE(rytc): temporary stub
_name :: proc(fd: Handle) -> string {
    return "";
}

_seek :: proc(fd: Handle, offset: i64, whence: Seek_From) -> (ret: i64, err: Error) {
    // TOOD(rytc): Do checking of whence?
    result := unix.lseek(transmute(int)fd, offset, transmute(uint)whence);
    return result, _unix_errno(int(result));
}

_read :: proc(fd: Handle, p: []byte) -> (n: int, err: Error) {
    result := unix.read(transmute(int)fd, p);
    return result, _unix_errno(result);
}

_read_at :: proc(fd: Handle, p: []byte, offset: i64) -> (n: int, err: Error) {
    off,err_seek := _seek(fd, offset, Seek_From.Start);

    if err_seek != Error.None {
        return 0, err_seek;
    }

    read_bytes,err_read := _read(fd, p);
    return read_bytes, err_read;
}

// TODO(rytc): temporary stub
_read_from :: proc(fd: Handle, r: io.Reader) -> (n: i64, err: Error) {
    return 0, Error.Invalid_Argument;
}

_write :: proc(fd: Handle, p: []byte) -> (n: int, err: Error) {
    result := unix.write(transmute(int)fd, p);
    return result, _unix_errno(result);
}

_write_at :: proc(fd: Handle, p: []byte, offset: i64) -> (n: int, err: Error) {
    off,err_seek := _seek(fd, offset, Seek_From.Start);

    if err_seek != Error.None {
        return 0, err_seek;
    }

    n,err = _write(fd, p);
    return n,err;
}

_write_to :: proc(fd: Handle, w: io.Writer) -> (n: i64, err: Error) {
    return 0,Error.Invalid_Argument;
}

_file_size :: proc(fd: Handle) -> (n: i64, err: Error) {
    return 0,Error.Invalid_Argument;
}

_sync :: proc(fd: Handle) -> Error {
    err := unix.fsync(transmute(int)fd);
    return _unix_errno(err);
}

_flush :: proc(fd: Handle) -> Error {
    return _sync(fd);
}

_truncate :: proc(fd: Handle, size: i64) -> Maybe(Path_Error) {
	return nil;
}

_remove :: proc(name: string) -> Maybe(Path_Error) {
	return nil;
}

_rename :: proc(old_path, new_path: string) -> Maybe(Path_Error) {
	return nil;
}

_link :: proc(old_name, new_name: string) -> Maybe(Link_Error) {
	return nil;
}

_symlink :: proc(old_name, new_name: string) -> Maybe(Link_Error) {
	return nil; 
}

_read_link :: proc(name: string) -> (string, Maybe(Path_Error)) {
	return "",nil;
}

_chdir :: proc(fd: Handle) -> Error {
	return Error.Invalid_Argument;
}

_chmod :: proc(fd: Handle, mode: File_Mode) -> Error {
	return Error.Invalid_Argument;
}

_chown :: proc(fd: Handle, uid, gid: int) -> Error {
	return Error.Invalid_Argument; 
}

_lchown :: proc(name: string, uid, gid: int) -> Error {
	return Error.Invalid_Argument; 
}

_chtimes :: proc(name: string, atime, mtime: time.Time) -> Maybe(Path_Error) {
	return nil;
}

_exists :: proc(path: string) -> bool {
	return false;
}

_is_file :: proc(path: string) -> bool {
	return false;
}

_is_dir :: proc(path: string) -> bool {
	return false;
}


