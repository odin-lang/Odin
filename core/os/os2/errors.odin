package os2

import "core:io"
import "core:runtime"

General_Error :: enum u32 {
	None,

	Permission_Denied,
	Exist,
	Not_Exist,
	Closed,

	Timeout,

	Invalid_File,
	Invalid_Dir,
	Invalid_Path,

	Unsupported,
}

Platform_Error :: enum i32 {None=0}

Error :: union #shared_nil {
	General_Error,
	io.Error,
	runtime.Allocator_Error,
	Platform_Error,
}
#assert(size_of(Error) == size_of(u64))



is_platform_error :: proc(ferr: Error) -> (err: i32, ok: bool) {
	v := ferr.(Platform_Error) or_else {}
	return i32(v), i32(v) != 0
}


error_string :: proc(ferr: Error) -> string {
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
		case .Invalid_File:      return "invalid file"
		case .Invalid_Dir:       return "invalid directory"
		case .Invalid_Path:      return "invalid path"
		case .Unsupported:       return "unsupported"
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
		return _error_string(i32(e))
	}

	return "unknown error"
}
