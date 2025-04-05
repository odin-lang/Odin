#+build darwin
package net

/*
	Package net implements cross-platform Berkeley Sockets, DNS resolution and associated procedures.
	For other protocols and their features, see subdirectories of this package.
*/

/*
	Copyright 2022 Tetralux        <tetraluxonpc@gmail.com>
	Copyright 2022 Colin Davidson  <colrdavidson@gmail.com>
	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Copyright 2024 Feoramund       <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Tetralux:        Initial implementation
		Colin Davidson:  Linux platform code, OSX platform code, Odin-native DNS resolver
		Jeroen van Rijn: Cross platform unification, code style, documentation
		Feoramund:       FreeBSD platform code
*/

import "core:reflect"
import "core:sys/posix"

_last_platform_error :: proc() -> i32 {
	return i32(posix.errno())
}

_last_platform_error_string :: proc() -> string {
	description, _ := reflect.enum_name_from_value(posix.errno())
	return description
}

_set_last_platform_error :: proc(err: i32) {
	posix.errno(posix.Errno(err))
}

_create_socket_error :: proc() -> Create_Socket_Error {
	#partial switch posix.errno() {
	case .EMFILE, .ENOBUFS, .ENOMEM, .EPROTONOSUPPORT, .EISCONN, .ENFILE:
		return .Insufficient_Resources
	case .EAFNOSUPPORT, .EPROTOTYPE:
		return .Invalid_Argument
	case .EACCES:
		return .Insufficient_Permissions
	case:
		return .Unknown
	}
}

_dial_error :: proc() -> Dial_Error {
	#partial switch posix.errno() {
	case .ENOBUFS:
		return .Insufficient_Resources
	case .EAFNOSUPPORT, .EBADF, .EFAULT, .EINVAL, .ENOTSOCK, .EPROTOTYPE, .EADDRNOTAVAIL:
		return .Invalid_Argument
	case .EISCONN:
		return .Already_Connected
	case .EALREADY:
		return .Already_Connecting
	case .EADDRINUSE:
		return .Address_In_Use
	case .ENETDOWN:
		return .Network_Unreachable
	case .EHOSTUNREACH:
		return .Host_Unreachable
	case .ECONNREFUSED:
		return .Refused
	case .ECONNRESET:
		return .Reset
	case .ETIMEDOUT:
		return .Timeout
	case .EINPROGRESS:
		return .Would_Block
	case .EINTR:
		return .Interrupted
	case .EACCES:
		return .Broadcast_Not_Supported
	case:
		return .Unknown
	}
}

_bind_error :: proc() -> Bind_Error {
	#partial switch posix.errno() {
	case .EADDRNOTAVAIL, .EAFNOSUPPORT, .EBADF, .EDESTADDRREQ, .EFAULT, .ENOTSOCK, .EOPNOTSUPP:
		return .Invalid_Argument
	case .EINVAL:
		return .Already_Bound
	case .EACCES:
		return .Insufficient_Permissions_For_Address
	case .EADDRINUSE:
		return .Address_In_Use
	case:
		return .Unknown
	}
}

_listen_error :: proc() -> Listen_Error {
	#partial switch posix.errno() {
	case .EBADF, .ENOTSOCK:
		return .Invalid_Argument
	case .EDESTADDRREQ, .EOPNOTSUPP:
		return .Unsupported_Socket
	case .EINVAL:
		return .Already_Connected
	case:
		return .Unknown
	}
}

_accept_error :: proc() -> Accept_Error {
	#partial switch posix.errno() {
	case .EMFILE, .ENFILE, .ENOMEM:
		return .Insufficient_Resources
	case .EBADF, .ENOTSOCK, .EFAULT:
		return .Invalid_Argument
	case .EOPNOTSUPP:
		return .Unsupported_Socket
	case .ECONNABORTED:
		return .Aborted
	case .EWOULDBLOCK:
		return .Would_Block
	case .EINTR:
		return .Interrupted
	case:
		return .Unknown
	}
}

_tcp_recv_error :: proc() -> TCP_Recv_Error {
	#partial switch posix.errno() {
	case .EBADF, .EFAULT, .EINVAL, .ENOTSOCK, .EOPNOTSUPP:
		return .Invalid_Argument
	case .ENOBUFS:
		return .Insufficient_Resources
	case .ENOTCONN:
		return .Not_Connected
	case .ECONNRESET:
		return .Connection_Closed
	case .ETIMEDOUT:
		return .Timeout
	case .EAGAIN:
		return .Would_Block
	case .EINTR:
		return .Interrupted
	case:
		return .Unknown
	}
}

_udp_recv_error :: proc() -> UDP_Recv_Error {
	#partial switch posix.errno() {
	case .EBADF, .EFAULT, .EINVAL, .ENOTSOCK, .EOPNOTSUPP, .EMSGSIZE:
		return .Invalid_Argument
	case .ENOBUFS, .ENOMEM:
		return .Insufficient_Resources
	case .ECONNRESET, .ENOTCONN:
		return .Connection_Refused
	case .ETIMEDOUT:
		return .Timeout
	case .EAGAIN:
		return .Would_Block
	case .EINTR:
		return .Interrupted
	case:
		return .Unknown
	}
}

_tcp_send_error :: proc() -> TCP_Send_Error {
	#partial switch posix.errno() {
	case .EACCES, .EBADF, .EFAULT, .EMSGSIZE, .ENOTSOCK, .EOPNOTSUPP:
		return .Invalid_Argument
	case .ENOBUFS:
		return .Insufficient_Resources
	case .ECONNRESET, .EPIPE:
		return .Connection_Closed
	case .ENOTCONN:
		return .Not_Connected
	case .EHOSTUNREACH:
		return .Host_Unreachable
	case .ENETDOWN, .ENETUNREACH:
		return .Network_Unreachable
	case .ETIMEDOUT:
		return .Timeout
	case .EAGAIN:
		return .Would_Block
	case .EINTR:
		return .Interrupted
	case:
		return .Unknown
	}
}

_udp_send_error :: proc() -> UDP_Send_Error {
	#partial switch posix.errno() {
	case .EACCES, .EBADF, .EFAULT, .EMSGSIZE, .ENOTSOCK, .EOPNOTSUPP, .EAFNOSUPPORT, .EDESTADDRREQ:
		return .Invalid_Argument
	case .ENOBUFS, .ENOMEM:
		return .Insufficient_Resources
	case .ECONNRESET, .EPIPE:
		return .Connection_Refused
	case .EHOSTUNREACH:
		return .Host_Unreachable
	case .ENETDOWN, .ENETUNREACH:
		return .Network_Unreachable
	case .ETIMEDOUT:
		return .Timeout
	case .EAGAIN:
		return .Would_Block
	case .EINTR:
		return .Interrupted
	case:
		return .Unknown
	}
}

_shutdown_error :: proc() -> Shutdown_Error {
	#partial switch posix.errno() {
	case .EBADF, .EINVAL, .ENOTSOCK, .ENOTCONN:
		return .Invalid_Argument
	case:
		return .Unknown
	}
}

_socket_option_error :: proc() -> Socket_Option_Error {
	#partial switch posix.errno() {
	case .ENOBUFS:
		return .Insufficient_Resources
	case .EBADF, .ENOTSOCK, .EISCONN:
		return .Invalid_Socket
	case .EINVAL, .ENOPROTOOPT:
		return .Invalid_Option
	case .EFAULT, .EDOM:
		return .Invalid_Value
	case:
		return .Unknown
	}
}

_set_blocking_error :: proc() -> Set_Blocking_Error {
	#partial switch posix.errno() {
	case .EBADF:
		return .Invalid_Argument
	case:
		return .Unknown
	}
}
