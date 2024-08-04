package os

import "base:intrinsics"
import "base:runtime"
import "core:io"

Platform_Error :: _Platform_Error
#assert(size_of(Platform_Error) <= 4)
#assert(intrinsics.type_has_nil(Platform_Error))

General_Error :: enum u32 {
	None,

	Permission_Denied,
	Exist,
	Not_Exist,
	Closed,

	Timeout,

	Broken_Pipe,

	// Indicates that an attempt to retrieve a file's size was made, but the
	// file doesn't have a size.
	No_Size,

	Invalid_File,
	Invalid_Dir,
	Invalid_Path,
	Invalid_Callback,

	Pattern_Has_Separator,

	Unsupported,

	File_Is_Pipe,
	Not_Dir,
}


Errno :: Error // alias for legacy use

Error :: union #shared_nil {
	General_Error,
	io.Error,
	runtime.Allocator_Error,
	Platform_Error,
}
#assert(size_of(Error) == 8)

ERROR_NONE :: Error{}

ERROR_EOF :: io.Error.EOF

@(require_results)
is_platform_error :: proc "contextless" (ferr: Error) -> (err: i32, ok: bool) {
	v := ferr.(Platform_Error) or_else {}
	return i32(v), i32(v) != 0
}

@(require_results)
error_string :: proc "contextless" (ferr: Error) -> string {
	if ferr == nil {
		return ""
	}
	switch e in ferr {
	case General_Error:
		switch e {
		case .None: return ""
		case .Permission_Denied: return "permission denied"
		case .Exist:             return "file already exists"
		case .Not_Exist:         return "file does not exist"
		case .Closed:            return "file already closed"
		case .Timeout:           return "i/o timeout"
		case .Broken_Pipe:       return "Broken pipe"
		case .No_Size:           return "file has no definite size"
		case .Invalid_File:      return "invalid file"
		case .Invalid_Dir:       return "invalid directory"
		case .Invalid_Path:      return "invalid path"
		case .Invalid_Callback:  return "invalid callback"
		case .Unsupported:       return "unsupported"
		case .Pattern_Has_Separator: return "pattern has separator"
		case .File_Is_Pipe:      return "file is pipe"
		case .Not_Dir:           return "file is not directory"
		}
	case io.Error:
		switch e {
		case .None: return ""
		case .EOF:               return "eof"
		case .Unexpected_EOF:    return "unexpected eof"
		case .Short_Write:       return "short write"
		case .Invalid_Write:     return "invalid write result"
		case .Short_Buffer:      return "short buffer"
		case .No_Progress:       return "multiple read calls return no data or error"
		case .Invalid_Whence:    return "invalid whence"
		case .Invalid_Offset:    return "invalid offset"
		case .Invalid_Unread:    return "invalid unread"
		case .Negative_Read:     return "negative read"
		case .Negative_Write:    return "negative write"
		case .Negative_Count:    return "negative count"
		case .Buffer_Full:       return "buffer full"
		case .Unknown, .Empty: //
		}
	case runtime.Allocator_Error:
		switch e {
		case .None:                 return ""
		case .Out_Of_Memory:        return "out of memory"
		case .Invalid_Pointer:      return "invalid allocator pointer"
		case .Invalid_Argument:     return "invalid allocator argument"
		case .Mode_Not_Implemented: return "allocator mode not implemented"
		}
	case Platform_Error:
		return _error_string(e)
	}

	return "unknown error"
}

print_error :: proc(f: Handle, ferr: Error, msg: string) -> (n: int, err: Error) {
	err_str := error_string(ferr)

	// msg + ": " + err_str + '\n'
	length := len(msg) + 2 + len(err_str) + 1
	buf_ := intrinsics.alloca(length, 1)
	buf := buf_[:length]

	copy(buf, msg)
	buf[len(msg)] = ':'
	buf[len(msg) + 1] = ' '
	copy(buf[len(msg) + 2:], err_str)
	buf[length - 1] = '\n'
	return write(f, buf)
}


@(require_results, private)
_error_string :: proc "contextless" (e: Platform_Error) -> string where intrinsics.type_is_enum(Platform_Error) {
	if e == nil {
		return ""
	}

	when ODIN_OS == .Darwin {
		if s := string(_darwin_string_error(i32(e))); s != "" {
			return s
		}
	}

	when ODIN_OS != .Linux {
		@(require_results)
		binary_search :: proc "contextless" (array: $A/[]$T, key: T) -> (index: int, found: bool) #no_bounds_check {
			n := len(array)
			left, right := 0, n
			for left < right {
				mid := int(uint(left+right) >> 1)
				if array[mid] < key {
					left = mid+1
				} else {
					// equal or greater
					right = mid
				}
			}
			return left, left < n && array[left] == key
		}

		err := runtime.Type_Info_Enum_Value(e)

		ti := &runtime.type_info_base(type_info_of(Platform_Error)).variant.(runtime.Type_Info_Enum)
		if idx, ok := binary_search(ti.values, err); ok {
			return ti.names[idx]
		}
	} else {
		@(rodata, static)
		pe_strings := [Platform_Error]string{
			.NONE            = "",
			.EPERM           = "Operation not permitted",
			.ENOENT          = "No such file or directory",
			.ESRCH           = "No such process",
			.EINTR           = "Interrupted system call",
			.EIO             = "Input/output error",
			.ENXIO           = "No such device or address",
			.E2BIG           = "Argument list too long",
			.ENOEXEC         = "Exec format error",
			.EBADF           = "Bad file descriptor",
			.ECHILD          = "No child processes",
			.EAGAIN          = "Resource temporarily unavailable",
			.ENOMEM          = "Cannot allocate memory",
			.EACCES          = "Permission denied",
			.EFAULT          = "Bad address",
			.ENOTBLK         = "Block device required",
			.EBUSY           = "Device or resource busy",
			.EEXIST          = "File exists",
			.EXDEV           = "Invalid cross-device link",
			.ENODEV          = "No such device",
			.ENOTDIR         = "Not a directory",
			.EISDIR          = "Is a directory",
			.EINVAL          = "Invalid argument",
			.ENFILE          = "Too many open files in system",
			.EMFILE          = "Too many open files",
			.ENOTTY          = "Inappropriate ioctl for device",
			.ETXTBSY         = "Text file busy",
			.EFBIG           = "File too large",
			.ENOSPC          = "No space left on device",
			.ESPIPE          = "Illegal seek",
			.EROFS           = "Read-only file system",
			.EMLINK          = "Too many links",
			.EPIPE           = "Broken pipe",
			.EDOM            = "Numerical argument out of domain",
			.ERANGE          = "Numerical result out of range",
			.EDEADLK         = "Resource deadlock avoided",
			.ENAMETOOLONG    = "File name too long",
			.ENOLCK          = "No locks available",
			.ENOSYS          = "Function not implemented",
			.ENOTEMPTY       = "Directory not empty",
			.ELOOP           = "Too many levels of symbolic links",
			.EUNKNOWN_41     = "Unknown Error (41)",
			.ENOMSG          = "No message of desired type",
			.EIDRM           = "Identifier removed",
			.ECHRNG          = "Channel number out of range",
			.EL2NSYNC        = "Level 2 not synchronized",
			.EL3HLT          = "Level 3 halted",
			.EL3RST          = "Level 3 reset",
			.ELNRNG          = "Link number out of range",
			.EUNATCH         = "Protocol driver not attached",
			.ENOCSI          = "No CSI structure available",
			.EL2HLT          = "Level 2 halted",
			.EBADE           = "Invalid exchange",
			.EBADR           = "Invalid request descriptor",
			.EXFULL          = "Exchange full",
			.ENOANO          = "No anode",
			.EBADRQC         = "Invalid request code",
			.EBADSLT         = "Invalid slot",
			.EUNKNOWN_58     = "Unknown Error (58)",
			.EBFONT          = "Bad font file format",
			.ENOSTR          = "Device not a stream",
			.ENODATA         = "No data available",
			.ETIME           = "Timer expired",
			.ENOSR           = "Out of streams resources",
			.ENONET          = "Machine is not on the network",
			.ENOPKG          = "Package not installed",
			.EREMOTE         = "Object is remote",
			.ENOLINK         = "Link has been severed",
			.EADV            = "Advertise error",
			.ESRMNT          = "Srmount error",
			.ECOMM           = "Communication error on send",
			.EPROTO          = "Protocol error",
			.EMULTIHOP       = "Multihop attempted",
			.EDOTDOT         = "RFS specific error",
			.EBADMSG         = "Bad message",
			.EOVERFLOW       = "Value too large for defined data type",
			.ENOTUNIQ        = "Name not unique on network",
			.EBADFD          = "File descriptor in bad state",
			.EREMCHG         = "Remote address changed",
			.ELIBACC         = "Can not access a needed shared library",
			.ELIBBAD         = "Accessing a corrupted shared library",
			.ELIBSCN         = ".lib section in a.out corrupted",
			.ELIBMAX         = "Attempting to link in too many shared libraries",
			.ELIBEXEC        = "Cannot exec a shared library directly",
			.EILSEQ          = "Invalid or incomplete multibyte or wide character",
			.ERESTART        = "Interrupted system call should be restarted",
			.ESTRPIPE        = "Streams pipe error",
			.EUSERS          = "Too many users",
			.ENOTSOCK        = "Socket operation on non-socket",
			.EDESTADDRREQ    = "Destination address required",
			.EMSGSIZE        = "Message too long",
			.EPROTOTYPE      = "Protocol wrong type for socket",
			.ENOPROTOOPT     = "Protocol not available",
			.EPROTONOSUPPORT = "Protocol not supported",
			.ESOCKTNOSUPPORT = "Socket type not supported",
			.EOPNOTSUPP      = "Operation not supported",
			.EPFNOSUPPORT    = "Protocol family not supported",
			.EAFNOSUPPORT    = "Address family not supported by protocol",
			.EADDRINUSE      = "Address already in use",
			.EADDRNOTAVAIL   = "Cannot assign requested address",
			.ENETDOWN        = "Network is down",
			.ENETUNREACH     = "Network is unreachable",
			.ENETRESET       = "Network dropped connection on reset",
			.ECONNABORTED    = "Software caused connection abort",
			.ECONNRESET      = "Connection reset by peer",
			.ENOBUFS         = "No buffer space available",
			.EISCONN         = "Transport endpoint is already connected",
			.ENOTCONN        = "Transport endpoint is not connected",
			.ESHUTDOWN       = "Cannot send after transport endpoint shutdown",
			.ETOOMANYREFS    = "Too many references: cannot splice",
			.ETIMEDOUT       = "Connection timed out",
			.ECONNREFUSED    = "Connection refused",
			.EHOSTDOWN       = "Host is down",
			.EHOSTUNREACH    = "No route to host",
			.EALREADY        = "Operation already in progress",
			.EINPROGRESS     = "Operation now in progress",
			.ESTALE          = "Stale file handle",
			.EUCLEAN         = "Structure needs cleaning",
			.ENOTNAM         = "Not a XENIX named type file",
			.ENAVAIL         = "No XENIX semaphores available",
			.EISNAM          = "Is a named type file",
			.EREMOTEIO       = "Remote I/O error",
			.EDQUOT          = "Disk quota exceeded",
			.ENOMEDIUM       = "No medium found",
			.EMEDIUMTYPE     = "Wrong medium type",
			.ECANCELED       = "Operation canceled",
			.ENOKEY          = "Required key not available",
			.EKEYEXPIRED     = "Key has expired",
			.EKEYREVOKED     = "Key has been revoked",
			.EKEYREJECTED    = "Key was rejected by service",
			.EOWNERDEAD      = "Owner died",
			.ENOTRECOVERABLE = "State not recoverable",
			.ERFKILL         = "Operation not possible due to RF-kill",
			.EHWPOISON       = "Memory page has hardware error",
		}
		if Platform_Error.NONE <= e && e <= max(Platform_Error) {
			return pe_strings[e]
		}
	}
	return "<unknown platform error>"
}

@(private, require_results)
error_to_io_error :: proc(ferr: Error) -> io.Error {
	if ferr == nil {
		return .None
	}
	return ferr.(io.Error) or_else .Unknown
}
