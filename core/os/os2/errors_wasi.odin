#+private
package os2

import "base:runtime"

import "core:slice"
import "core:sys/wasm/wasi"

_Platform_Error :: wasi.errno_t

_error_string :: proc(errno: i32) -> string {
	e := wasi.errno_t(errno)
	if e == .NONE {
		return ""
	}

	err := runtime.Type_Info_Enum_Value(e)

	ti := &runtime.type_info_base(type_info_of(wasi.errno_t)).variant.(runtime.Type_Info_Enum)
	if idx, ok := slice.binary_search(ti.values, err); ok {
		return ti.names[idx]
	}
	return "<unknown platform error>"
}

_get_platform_error :: proc(errno: wasi.errno_t) -> Error {
	#partial switch errno {
	case .PERM:
		return .Permission_Denied
	case .EXIST:
		return .Exist
	case .NOENT:
		return .Not_Exist
	case .TIMEDOUT:
		return .Timeout
	case .PIPE:
		return .Broken_Pipe
	case .BADF:
		return .Invalid_File
	case .NOMEM:
		return .Out_Of_Memory
	case .NOSYS:
		return .Unsupported
	case:
		return Platform_Error(errno)
	}
}
