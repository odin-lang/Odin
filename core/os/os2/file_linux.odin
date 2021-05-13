package os2

import "core:strings"
import "core:io"

_create :: proc(name: string) -> (Handle, Error) {
    fd := _unix_open(name, O_CREATE, 0);
    return transmute(Handle)fd, _unix_errno(fd);
}

_open :: proc(name: string) -> (Handle, Error) {
    fd := _unix_open(name, O_RDONLY, 0);
    return transmute(Handle)fd, _unix_errno(fd);
}

_open_file :: proc(name: string, flag: int, perm: File_Mode) -> (Handle, Error) {
    fd := _unix_open(name, flag, perm);
    return transmute(Handle)fd, _unix_errno(fd);
}

_close :: proc(fd: Handle) -> Error {
    result := _unix_close(fd);
    return _unix_errno(result);
}

// NOTE(rytc): stub
_name :: proc(fd: Handle) -> string {
    return "";
}

_seek :: proc(fd: Handle, offset: i64, whence: Seek_From) -> (ret: i64, err: Error) {
    result := _unix_lseek(fd, offset, whence);
    return result, _unix_errno(int(result));
}

_read :: proc(fd: Handle, p: []byte) -> (n: int, err: Error) {
    result := _unix_read(fd, p);
    return result, _unix_errno(result);
}

_read_at :: proc(fd: Handle, p: []byte, offset: i64) -> (n: int, err: Error) {
    off,err_seek := _seek(fd, offset, Seek_From.Start);

    if err_seek != Error.None {
        return 0, err_seek;
    }

    n,err_read = _read(fd, p);
    return n,err_read;
}

// NOTE(rytc): temporary stub
_read_from :: proc(fd: Handle, r: io.Reader) -> (n: i64, err: Error) {
    return 0, Error.Invalid_Argument;
}

_write :: proc(fd: Handle, p: []byte) -> (n: i64, err: Error) {
    result := _unix_write(fd, p);
    return result, _unix_errno(result);
}

_write_at :: proc(fd: Handle, p: []byte, offset: i64) -> (n: int, err: Error) {
    off,err_seek := _seek(fd, offset, Seek_From.Start);

    if err_seek != Error.None {
        return 0, err_seek;
    }

    n,err_write = _write(fd, p);
    return n, err_write;
}

// NOTE(rytc): temporary stub
_write_to :: proc(fd: Handle, w: io.Writer) -> (n: i64, err: Error) {
    return 0,Error.Invalid_Argument;
}

// NOTE(rytc): temporary stub
_file_size :: proc(fd: Handle) -> (n: i64, err: Error) {
    return 0,Error.Invalid_Handle;
}

_sync :: proc(fd: Handle) -> Error {
    err := _unix_fsync(fd);
    return _unix_errno(err);
}

_flush :: proc(fd: Handle) -> Error {
    return _sync(fd);
}

@private
_unix_open :: proc(name: string, flags: int, mode: File_Mode) -> int {
    @static syscall_open :i32 =  2;

    result := asm(i32, ^u8, int, File_Mode) -> int {
        "movl $0,%eax\nsyscall",
        "={eax},{eax}{ebx}{ecx}{edx}",
    }(syscall_open, strings.ptr_from_string(name), flags, mode);

    return result;
}

@private
_unix_close :: proc(fd: Handle) -> int {
    @static syscall_close :i32 =  3;

    result := asm(i32, i32) -> int {
        "movl $0,%eax\nsyscall",
        "={eax},{eax}{ebx}",
    }(syscall_close, fd);

    return result;
}

@private
_unix_lseek :: proc(fd: Handle, offset: i64, whence: Seek_From) -> i64 {
    @static syscall_lseek :i32 =  8;

    result := asm(i32, i64, i32) -> i64 {
        "movl $0,%eax\nsyscall",
        "={eax},{eax}{ebx}{ecx}{edx}",
    }(syscall_lseek, fd, offset, wence);

    return result;
}

@private
_unix_read :: proc(fd: Handle, p: []byte) -> int {
    @static syscall_read :i32=  8;

    result := asm(i32, i32, uintptr, i32) -> int {
        "movl $0,%eax\nsyscall",
        "={eax},{eax}{ebx}{ecx}{edx}",
    }(syscall_read, fd, &p[0], length(p));

    return result;
}

@private
_unix_write :: proc(fd: Handle, p: []byte) -> int {
    @static syscall_write :i32= 1;
    
    result := asm(i32, i32, uintptr, i32) -> int {
        "movl $0,%eax\nsyscall",
        "={eax},{eax}{ebx}{ecx}{edx}",
    }(syscall_write, fd, &p[0], length(p));

    return result;
}

@private
_unix_fsync :: proc(fd: Handle) -> int {
    @static syscall_fsync :i32= 74; 
    
    result := asm(i32, i32) -> int {
        "movl $0,%eax\nsyscall",
        "={eax},{eax}{ebx}",
    }(syscall_fsync, fd);

    return result;
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

    errno := -fd;

    switch errno { 
        case Errno.EACCES: fallthrough;
        case Errno.EPERM:
            return Error.Permission_Denied;
        case Errno.ENOENT:
            return Error.Not_Exist;
        case Errno.ELOOP: fallthrough;
        case Errno.EINVAL: 
            return Error.Invalid_Argument;
        case Errno.EBUSY:
            return Error.Timeout;
    }

    return Error.Invalid_Argument;
}
