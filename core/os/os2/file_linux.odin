//+private
package os2

import "core:strings"
import "core:io"
import "core:sys/unix"

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

// TODO(rytc): temporary stub
_write_to :: proc(fd: Handle, w: io.Writer) -> (n: i64, err: Error) {
    return 0,Error.Invalid_Argument;
}

// TODO(rytc): temporary stub
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

@private
Errno :: enum i32 {
    EPERM   = 1,
    ENOENT  = 2,
    ESRCH   = 3,
    EINTR   = 4,
    EIO     = 5,
    ENXIO   = 6,
    EBADF   = 9,
    EAGAIN  = 11,
    ENOMEM  = 12,
    EACCES  = 13,
    EFAULT  = 14,
    EEXIST  = 17,
    ENODEV  = 19,
    ENOTDIR = 20,
    EISDIR  = 21,
    EINVAL  = 22,
    ENFILE  = 23,
    EMFILE  = 24,
    ETXTBSY = 26,
    EFBIG   = 27,
    ENOSPC  = 28,
    ESPIPE  = 29,
    EROFS   = 30,
    EPIPE   = 32,
}

@private
_unix_errno :: proc(fd: int) -> Error {
    if fd >= 0 do return Error.None;

    errno := Errno(-fd);

    #partial switch errno { 
        case Errno.EACCES: fallthrough;
        case Errno.EPERM:
            return Error.Permission_Denied;
        case Errno.ENOENT:
            return Error.Not_Exist;
        case Errno.EINVAL: 
            return Error.Invalid_Argument;
        //case Errno.EBUSY:
        //  return Error.Timeout;
    }

    return Error.Invalid_Argument;
}
