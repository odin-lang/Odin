package nbio

import "base:intrinsics"

import "core:reflect"

Error :: intrinsics.type_merge(
	Network_Error,
	union #shared_nil {
		General_Error,
		FS_Error,
	},
)
#assert(size_of(Error) == 8)

// Errors regarding general usage of the event loop.
General_Error :: enum i32 {
	None,

	Allocation_Failed = i32(PLATFORM_ERR_ALLOCATION_FAILED),
	Unsupported       = i32(PLATFORM_ERR_UNSUPPORTED),
}

// Errors gotten from file system operations.
FS_Error :: enum i32 {
	None,
	Unsupported        = i32(PLATFORM_ERR_UNSUPPORTED),
	Allocation_Failed  = i32(PLATFORM_ERR_ALLOCATION_FAILED),
	Timeout            = i32(PLATFORM_ERR_TIMEOUT),
	Invalid_Argument   = i32(PLATFORM_ERR_INVALID_ARGUMENT),
	Permission_Denied  = i32(PLATFORM_ERR_PERMISSION_DENIED),
	EOF                = i32(PLATFORM_ERR_EOF),
	Exists             = i32(PLATFORM_ERR_EXISTS),
	Not_Found          = i32(PLATFORM_ERR_NOT_FOUND),
}

Platform_Error :: _Platform_Error

error_string :: proc(err: Error) -> string {
	err := err
	variant := any{
		id   = reflect.union_variant_typeid(err),
		data = &err,
	}
	str := reflect.enum_string(variant)

	if str == "" {
		#partial switch uerr in err {
		case FS_Error:
			str, _ = reflect.enum_name_from_value(Platform_Error(uerr))
		case General_Error:
			str, _ = reflect.enum_name_from_value(Platform_Error(uerr))
		}
	}
	if str == "" {
		str = "Unknown"
	}

	return str
}

error_string_recv :: proc(recv_err: Recv_Error) -> string {
	switch err in recv_err {
	case TCP_Recv_Error: return error_string(err)
	case UDP_Recv_Error: return error_string(err)
	case:                return "Unknown"
	}
}

error_string_send :: proc(send_err: Send_Error) -> string {
	switch err in send_err {
	case TCP_Send_Error: return error_string(err)
	case UDP_Send_Error: return error_string(err)
	case:                return "Unknown"
	}
}

error_string_sendfile :: proc(send_err: Send_File_Error) -> string {
	switch err in send_err {
	case TCP_Send_Error: return error_string(err)
	case FS_Error:       return error_string(err)
	case:                return "Unknown"
	}
}
