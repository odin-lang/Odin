#+build windows
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

import     "core:reflect"
import win "core:sys/windows"

_last_platform_error :: proc() -> i32 {
	return i32(win.WSAGetLastError())
}

_last_platform_error_string :: proc() -> string {
	description, _ := reflect.enum_name_from_value(win.System_Error(win.WSAGetLastError()))
	return description
}

_set_last_platform_error :: proc(err: i32) {
	win.WSASetLastError(err)
}

_create_socket_error :: proc() -> Create_Socket_Error {
	#partial switch win.System_Error(win.WSAGetLastError()) {
	case .WSANOTINITIALISED, .WSAENETDOWN, .WSAEINVALIDPROVIDER, .WSAEINVALIDPROCTABLE, .WSAEPROVIDERFAILEDINIT:
		return .Network_Unreachable
	case .WSAEAFNOSUPPORT, .WSAEINPROGRESS, .WSAEINVAL, .WSAEPROTOTYPE, .WSAESOCKTNOSUPPORT:
		return .Invalid_Argument
	case .WSAEMFILE, .WSAENOBUFS, .WSAEPROTONOSUPPORT:
		return .Insufficient_Resources
	case:
		return .Unknown
	}
}

_dial_error :: proc() -> Dial_Error {
	#partial switch win.System_Error(win.WSAGetLastError()) {
	case .WSANOTINITIALISED, .WSAENETDOWN:
		return .Network_Unreachable
	case .WSAEADDRINUSE:
		return .Address_In_Use
	case .WSAEINTR:
		return .Interrupted
	case .WSAEWOULDBLOCK:
		return .Would_Block
	case .WSAEALREADY:
		return .Already_Connecting
	case .WSAEADDRNOTAVAIL, .WSAEAFNOSUPPORT, .WSAEFAULT, .WSAENOTSOCK, .WSAEINPROGRESS, .WSAEINVAL:
		return .Invalid_Argument
	case .WSAECONNREFUSED:
		return .Refused
	case .WSAEISCONN:
		return .Already_Connected
	case .WSAEHOSTUNREACH:
		return .Host_Unreachable
	case .WSAENOBUFS:
		return .Insufficient_Resources
	case .WSAETIMEDOUT:
		return .Timeout
	case .WSAEACCES:
		return .Broadcast_Not_Supported
	case:
		return .Unknown
	}
}

_bind_error :: proc() -> Bind_Error {
	#partial switch win.System_Error(win.WSAGetLastError()) {
	case .WSANOTINITIALISED, .WSAENETDOWN:
		return .Network_Unreachable
	case .WSAEADDRINUSE:
		return .Address_In_Use
	case .WSAEADDRNOTAVAIL, .WSAEFAULT, .WSAEINPROGRESS, .WSAEACCES, .WSAEINVAL, .WSAENOTSOCK:
		return .Invalid_Argument
	case:
		return .Unknown
	}
}

_listen_error :: proc() -> Listen_Error {
	#partial switch win.System_Error(win.WSAGetLastError()) {
	case .WSANOTINITIALISED, .WSAENETDOWN:
		return .Network_Unreachable
	case .WSAEMFILE, .WSAENOBUFS:
		return .Insufficient_Resources
	case .WSAEADDRINUSE:
		return .Address_In_Use
	case .WSAEINPROGRESS, .WSAENOTSOCK:
		return .Invalid_Argument
	case .WSAEISCONN:
		return .Already_Connected
	case .WSAEOPNOTSUPP, .WSAEINVAL:
		return .Unsupported_Socket
	case:
		return .Unknown
	}
}

_accept_error :: proc() -> Accept_Error {
	#partial switch win.System_Error(win.WSAGetLastError()) {
	case .WSANOTINITIALISED, .WSAENETDOWN:
		return .Network_Unreachable
	case .WSAEMFILE, .WSAENOBUFS:
		return .Insufficient_Resources
	case .WSAECONNRESET:
		return .Aborted
	case .WSAEFAULT, .WSAEINPROGRESS, .WSAENOTSOCK:
		return .Invalid_Argument
	case .WSAEINTR:
		return .Interrupted
	case .WSAEINVAL:
		return .Not_Listening
	case .WSAEWOULDBLOCK:
		return .Would_Block
	case .WSAEOPNOTSUPP:
		return .Unsupported_Socket
	case:
		return .Unknown
	}
}

_tcp_recv_error :: proc() -> TCP_Recv_Error {
	#partial switch win.System_Error(win.WSAGetLastError()) {
	case .WSANOTINITIALISED, .WSAENETDOWN:
		return .Network_Unreachable
	case .WSAEFAULT, .WSAEINPROGRESS, .WSAENOTSOCK, .WSAEMSGSIZE, .WSAEINVAL, .WSAEOPNOTSUPP:
		return .Invalid_Argument
	case .WSAENOTCONN:
		return .Not_Connected
	case .WSAEINTR:
		return .Interrupted
	case .WSAENETRESET, .WSAESHUTDOWN, .WSAECONNABORTED, .WSAECONNRESET:
		return .Connection_Closed
	case .WSAEWOULDBLOCK:
		return .Would_Block
	case .WSAETIMEDOUT:
		return .Timeout
	case:
		return .Unknown
	}
}

_udp_recv_error :: proc() -> UDP_Recv_Error {
	#partial switch win.System_Error(win.WSAGetLastError()) {
	case .WSANOTINITIALISED, .WSAENETDOWN:
		return .Network_Unreachable
	case .WSAEFAULT, .WSAEINPROGRESS, .WSAEINVAL, .WSAEISCONN, .WSAENOTSOCK, .WSAEOPNOTSUPP, .WSAEMSGSIZE:
		return .Invalid_Argument
	case .WSAEINTR:
		return .Interrupted
	case .WSAENETRESET, .WSAESHUTDOWN, .WSAECONNRESET:
		return .Connection_Refused
	case .WSAEWOULDBLOCK:
		return .Would_Block
	case .WSAETIMEDOUT:
		return .Timeout
	case:
		return .Unknown
	}
}

_tcp_send_error :: proc() -> TCP_Send_Error {
	#partial switch win.System_Error(win.WSAGetLastError()) {
	case .WSANOTINITIALISED, .WSAENETDOWN:
		return .Network_Unreachable
	case .WSAENOBUFS:
		return .Insufficient_Resources
	case .WSAEACCES, .WSAEINPROGRESS, .WSAEFAULT, .WSAENOTSOCK, .WSAEOPNOTSUPP, .WSAEMSGSIZE, .WSAEINVAL:
		return .Invalid_Argument
	case .WSAEINTR:
		return .Interrupted
	case .WSAENETRESET, .WSAESHUTDOWN, .WSAECONNABORTED, .WSAECONNRESET:
		return .Connection_Closed
	case .WSAENOTCONN:
		return .Not_Connected
	case .WSAEWOULDBLOCK:
		return .Would_Block
	case .WSAETIMEDOUT:
		return .Timeout
	case .WSAEHOSTUNREACH:
		return .Host_Unreachable
	case:
		return .Unknown
	}
}

_udp_send_error :: proc() -> UDP_Send_Error {
	#partial switch win.System_Error(win.WSAGetLastError()) {
	case .WSANOTINITIALISED, .WSAENETDOWN, .WSAENETUNREACH:
		return .Network_Unreachable
	case .WSAENOBUFS:
		return .Insufficient_Resources
	case .WSAEACCES, .WSAEINVAL, .WSAEINPROGRESS, .WSAEFAULT, .WSAENOTCONN, .WSAENOTSOCK, .WSAEOPNOTSUPP, .WSAEADDRNOTAVAIL, .WSAEAFNOSUPPORT, .WSAEDESTADDRREQ:
		return .Invalid_Argument
	case .WSAEINTR:
		return .Interrupted
	case .WSAENETRESET, .WSAESHUTDOWN, .WSAECONNRESET:
		return .Connection_Refused
	case .WSAEWOULDBLOCK:
		return .Would_Block
	case .WSAETIMEDOUT:
		return .Timeout
	case:
		return .Unknown
	}
}

_shutdown_error :: proc() -> Shutdown_Error {
	#partial switch win.System_Error(win.WSAGetLastError()) {
	case .WSAENETDOWN, .WSANOTINITIALISED:
		return .Network_Unreachable
	case .WSAECONNABORTED, .WSAECONNRESET:
		return .Connection_Closed
	case .WSAEINPROGRESS, .WSAEINVAL, .WSAENOTCONN, .WSAENOTSOCK:
		return .Invalid_Argument
	case:
		return .Unknown
	}
}

_socket_option_error :: proc() -> Socket_Option_Error {
	#partial switch win.System_Error(win.WSAGetLastError()) {
	case .WSAENETDOWN, .WSANOTINITIALISED:
		return .Network_Unreachable
	case .WSAEFAULT, .WSAEINVAL:
		return .Invalid_Value
	case .WSAENETRESET, .WSAENOTCONN, .WSAENOTSOCK:
		return .Invalid_Socket
	case .WSAENOPROTOOPT:
		return .Invalid_Option
	case:
		return .Unknown
	}
}

_set_blocking_error :: proc() -> Set_Blocking_Error {
	#partial switch win.System_Error(win.WSAGetLastError()) {
	case .WSAENETDOWN, .WSANOTINITIALISED:
		return .Network_Unreachable
	case .WSAEINPROGRESS, .WSAENOTSOCK, .WSAEFAULT:
		return .Invalid_Argument
	case:
		return .Unknown
	}
}
