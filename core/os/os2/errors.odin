package os2

import "core:io"

General_Error :: enum u32 {
	Invalid_Argument,

	Permission_Denied,
	Exist,
	Not_Exist,
	Closed,

	Timeout,
}

Platform_Error :: struct {
	err: i32,
}

Error :: union {
	General_Error,
	io.Error,
	Platform_Error,
}
#assert(size_of(Error) == size_of(u64));

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
	v: Platform_Error;
	if v, ok = ferr.(Platform_Error); ok {
		err = v.err;
	}
	return;
}


error_string :: proc(ferr: Error) -> string {
	switch ferr {
	case nil:                return "";
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
