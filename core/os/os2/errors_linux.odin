package os2

// TODO(rytc): temporary stub
_error_string :: proc(errno: i32) -> string {
    return "";
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

_unix_errno :: proc(fd: int) -> (err: Error) {
    if fd >= 0 {
        err = Platform_Error{0};
        return;
    }

    errno := Errno(-fd);
     
    #partial switch errno { 
        case Errno.EACCES: fallthrough;
        case Errno.EPERM:
            err = General_Error.Permission_Denied;
        case Errno.ENOENT:
            err = General_Error.Not_Exist;
        case Errno.EINVAL: 
            err = General_Error.Invalid_Argument;
        case:
            err = Platform_Error{0};
    }

    return err;
}
