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


	if e == nil {
		return ""
	}

	err := runtime.Type_Info_Enum_Value(e)

	ti := &runtime.type_info_base(type_info_of(Platform_Error)).variant.(runtime.Type_Info_Enum)
	if idx, ok := binary_search(ti.values, err); ok {
		return ti.names[idx]
	}
	return "<unknown platform error>"
}