package os2

Platform_Error_Min_Bits :: 32;

Error :: enum u64 {
	None = 0,

	// General Errors
	Invalid_Argument,

	Permission_Denied,
	Exist,
	Not_Exist,
	Closed,

	// Timeout Errors
	Timeout,

	// I/O Errors
	// EOF is the error returned by `read` when no more input is available
	EOF,

	// Unexpected_EOF means that EOF was encountered in the middle of reading a fixed-sized block of data
	Unexpected_EOF,

	// Short_Write means that a write accepted fewer bytes than requested but failed to return an explicit error
	Short_Write,

	// Invalid_Write means that a write returned an impossible count
	Invalid_Write,

	// Short_Buffer means that a read required a longer buffer than was provided
	Short_Buffer,

	// No_Progress is returned by some implementations of `io.Reader` when many calls
	// to `read` have failed to return any data or error.
	// This is usually a signed of a broken `io.Reader` implementation
	No_Progress,

	Invalid_Whence,
	Invalid_Offset,
	Invalid_Unread,

	Negative_Read,
	Negative_Write,
	Negative_Count,
	Buffer_Full,

	// Platform Specific Errors
	Platform_Minimum = 1<<Platform_Error_Min_Bits,
}

Path_Error :: struct {
	op:   string,
	path: string,
	err:  Error,
}

Link_Error :: struct {
	op:  string,
	old: string,
	new: string,
	err: Error,
}

path_error_delete :: proc(perr: Maybe(Path_Error)) {
	if err, ok := perr.?; ok {
		context.allocator = error_allocator();
		delete(err.op);
		delete(err.path);
	}
}

link_error_delete :: proc(lerr: Maybe(Link_Error)) {
	if err, ok := lerr.?; ok {
		context.allocator = error_allocator();
		delete(err.op);
		delete(err.old);
		delete(err.new);
	}
}



is_platform_error :: proc(ferr: Error) -> (err: i32, ok: bool) {
	if ferr >= .Platform_Minimum {
		err = i32(u64(ferr)>>Platform_Error_Min_Bits);
		ok = true;
	}
	return;
}

error_from_platform_error :: proc(errno: i32) -> Error {
	return Error(u64(errno) << Platform_Error_Min_Bits);
}

error_string :: proc(ferr: Error) -> string {
	#partial switch ferr {
	case .None:              return "";
	case .Invalid_Argument:  return "invalid argument";
	case .Permission_Denied: return "permission denied";
	case .Exist:             return "file already exists";
	case .Not_Exist:         return "file does not exist";
	case .Closed:            return "file already closed";
	case .Timeout:           return "i/o timeout";
	case .EOF:               return "eof";
	case .Unexpected_EOF:    return "unexpected eof";
	case .Short_Write:       return "short write";
	case .Invalid_Write:     return "invalid write result";
	case .Short_Buffer:      return "short buffer";
	case .No_Progress:       return "multiple read calls return no data or error";
	case .Invalid_Whence:    return "invalid whence";
	case .Invalid_Offset:    return "invalid offset";
	case .Invalid_Unread:    return "invalid unread";
	case .Negative_Read:     return "negative read";
	case .Negative_Write:    return "negative write";
	case .Negative_Count:    return "negative count";
	case .Buffer_Full:       return "buffer full";
	}

	if errno, ok := is_platform_error(ferr); ok {
		return _error_string(errno);
	}

	return "unknown error";
}
