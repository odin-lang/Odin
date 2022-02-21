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
#assert(size_of(Error) == size_of(u64))

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
		context.allocator = error_allocator()
		delete(err.op)
		delete(err.path)
	}
}

link_error_delete :: proc(lerr: Maybe(Link_Error)) {
	if err, ok := lerr.?; ok {
		context.allocator = error_allocator()
		delete(err.op)
		delete(err.old)
		delete(err.new)
	}
}



is_platform_error :: proc(ferr: Error) -> (err: i32, ok: bool) {
	v := ferr.(Platform_Error) or_else {}
	return v.err, v.err != 0
}


error_string :: proc(ferr: Error) -> string {
	@static general_error_strings := [General_Error]string{
		.Invalid_Argument  = "invalid argument",
		.Permission_Denied = "permission denied",
		.Exist             = "file already exists",
		.Not_Exist         = "file does not exist",
		.Closed            = "file already closed",
		.Timeout           = "i/o timeout",
	}

	@static io_error_strings := [io.Error]string{
		.None           = "",
		.EOF            = "eof",
		.Unexpected_EOF = "unexpected eof",
		.Short_Write    = "short write",
		.Invalid_Write  = "invalid write result",
		.Short_Buffer   = "short buffer",
		.No_Progress    = "multiple read calls return no data or error",
		.Invalid_Whence = "invalid whence",
		.Invalid_Offset = "invalid offset",
		.Invalid_Unread = "invalid unread",
		.Negative_Read  = "negative read",
		.Negative_Write = "negative write",
		.Negative_Count = "negative count",
		.Buffer_Full    = "buffer full",
		.Unknown        = "unknown i/o error",
		.Empty          = "empty i/o error",
	}
	if ferr == nil {
		return ""
	}

	switch err in ferr {
	case General_Error:  return general_error_strings[err]
	case io.Error:       return io_error_strings[err]
	case Platform_Error: return _error_string(err.err)
	}

	return "unknown error"
}
