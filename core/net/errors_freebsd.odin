#+build freebsd
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
import "core:sys/freebsd"

@(private="file", thread_local)
_last_error: freebsd.Errno

_last_platform_error :: proc() -> i32 {
	return i32(_last_error)
}

_last_platform_error_string :: proc() -> string {
	description, _ := reflect.enum_name_from_value(_last_error)
	return description
}

_set_last_platform_error :: proc(err: i32) {
	_last_error = freebsd.Errno(err)
}

_create_socket_error :: proc(errno: freebsd.Errno) -> Create_Socket_Error {
	assert(errno != nil)
	_last_error = errno

	#partial switch errno {
	case .EMFILE, .ENFILE, .ENOBUFS, .EPROTONOSUPPORT:
		return .Insufficient_Resources
	case .EAFNOSUPPORT, .EPROTOTYPE:
		return .Invalid_Argument
	case .EACCES, .EPERM:
		return .Insufficient_Permissions
	case:
		return .Unknown
	}
}

_dial_error :: proc(errno: freebsd.Errno) -> Dial_Error {
	assert(errno != nil)
	_last_error = errno

	#partial switch errno {
	case .EBADF, .EINVAL, .ENOTSOCK, .EADDRNOTAVAIL, .EAFNOSUPPORT, .EFAULT, .EAGAIN:
		return .Invalid_Argument
	case .EISCONN:
		return .Already_Connected
	case .EALREADY:
		return .Already_Connecting
	case .EADDRINUSE:
		return .Address_In_Use
	case .ENETUNREACH:
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

_bind_error :: proc(errno: freebsd.Errno) -> Bind_Error {
	assert(errno != nil)
	_last_error = errno

	#partial switch errno {
	case .EAGAIN, .ENOTSOCK, .EADDRNOTAVAIL, .EAFNOSUPPORT, .EFAULT:
		return .Insufficient_Resources
	case .EBADF:
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

_listen_error :: proc(errno: freebsd.Errno) -> Listen_Error {
	assert(errno != nil)
	_last_error = errno

	#partial switch errno {
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

_accept_error :: proc(errno: freebsd.Errno) -> Accept_Error {
	assert(errno != nil)
	_last_error = errno

	#partial switch errno {
	case .EMFILE, .ENFILE:
		return .Insufficient_Resources
	case .EBADF, .ENOTSOCK, .EFAULT:
		return .Invalid_Argument
	case .EINVAL:
		return .Not_Listening
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

_tcp_recv_error :: proc(errno: freebsd.Errno) -> TCP_Recv_Error {
	assert(errno != nil)
	_last_error = errno

	#partial switch errno {
	case .EBADF, .ENOTSOCK, .EFAULT:
		return .Invalid_Argument
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

_udp_recv_error :: proc(errno: freebsd.Errno) -> UDP_Recv_Error {
	assert(errno != nil)
	_last_error = errno

	#partial switch errno {
	case .EBADF, .ENOTSOCK, .EFAULT:
		return .Invalid_Argument
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

_tcp_send_error :: proc(errno: freebsd.Errno) -> TCP_Send_Error {
	assert(errno != nil)
	_last_error = errno

	#partial switch errno {
	case .EBADF, .EACCES, .ENOTSOCK, .EFAULT, .EMSGSIZE:
		return .Invalid_Argument
	case .ENOBUFS:
		return .Insufficient_Resources
	case .ECONNRESET, .EPIPE:
		return .Connection_Closed
	case .ENOTCONN:
		return .Not_Connected
	case .EHOSTUNREACH:
		return .Host_Unreachable
	case .EHOSTDOWN:
		return .Host_Unreachable
	case .ENETDOWN:
		return .Network_Unreachable
	case .EAGAIN:
		return .Would_Block
	case .EINTR:
		return .Interrupted
	case:
		return .Unknown
	}
}

_udp_send_error :: proc(errno: freebsd.Errno) -> UDP_Send_Error {
	assert(errno != nil)
	_last_error = errno

	#partial switch errno {
	case .EBADF, .EACCES, .ENOTSOCK, .EFAULT, .EMSGSIZE:
		return .Invalid_Argument
	case .ENOBUFS:
		return .Insufficient_Resources
	case .ECONNRESET, .EPIPE:
		return .Connection_Refused
	case .EHOSTUNREACH:
		return .Host_Unreachable
	case .EHOSTDOWN:
		return .Host_Unreachable
	case .ENETDOWN:
		return .Network_Unreachable
	case .EAGAIN:
		return .Would_Block
	case .EINTR:
		return .Interrupted
	case:
		return .Unknown
	}
}

_shutdown_error :: proc(errno: freebsd.Errno) -> Shutdown_Error {
	assert(errno != nil)
	_last_error = errno

	#partial switch errno {
	case .EBADF, .EINVAL, .ENOTSOCK, .ENOTCONN:
		return .Invalid_Argument
	case:
		return .Unknown
	}
}

_socket_option_error :: proc(errno: freebsd.Errno) -> Socket_Option_Error {
	assert(errno != nil)
	_last_error = errno

	#partial switch errno {
	case .ENOMEM, .ENOBUFS:
		return .Insufficient_Resources
	case .EBADF, .ENOTSOCK:
		return .Invalid_Socket
	case .ENOPROTOOPT:
		return .Invalid_Option
	case .EINVAL, .EFAULT:
		return .Invalid_Value
	case:
		return .Unknown
	}
}

_set_blocking_error :: proc(errno: freebsd.Errno) -> Set_Blocking_Error {
	assert(errno != nil)
	_last_error = errno

	#partial switch errno {
	case .EBADF, .ENOTTY:
		return .Invalid_Argument
	case:
		return .Unknown
	}
}
