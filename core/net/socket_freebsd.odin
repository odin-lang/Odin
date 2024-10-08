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

import "core:c"
import "core:sys/freebsd"
import "core:time"

Fd :: freebsd.Fd

Socket_Option :: enum c.int {
	// TODO: Test and implement more socket options.
	// DEBUG
	Reuse_Address             = cast(c.int)freebsd.Socket_Option.REUSEADDR,
	Keep_Alive                = cast(c.int)freebsd.Socket_Option.KEEPALIVE,
	// DONTROUTE
	Broadcast                 = cast(c.int)freebsd.Socket_Option.BROADCAST,
	Use_Loopback              = cast(c.int)freebsd.Socket_Option.USELOOPBACK,
	Linger                    = cast(c.int)freebsd.Socket_Option.LINGER,
	Out_Of_Bounds_Data_Inline = cast(c.int)freebsd.Socket_Option.OOBINLINE,
	Reuse_Port                = cast(c.int)freebsd.Socket_Option.REUSEPORT,
	// TIMESTAMP
	No_SIGPIPE_From_EPIPE     = cast(c.int)freebsd.Socket_Option.NOSIGPIPE,
	// ACCEPTFILTER
	// BINTIME
	// NO_OFFLOAD
	// NO_DDP
	Reuse_Port_Load_Balancing = cast(c.int)freebsd.Socket_Option.REUSEPORT_LB,
	// RERROR

	Send_Buffer_Size          = cast(c.int)freebsd.Socket_Option.SNDBUF,
	Receive_Buffer_Size       = cast(c.int)freebsd.Socket_Option.RCVBUF,
	// SNDLOWAT
	// RCVLOWAT
	Send_Timeout              = cast(c.int)freebsd.Socket_Option.SNDTIMEO,
	Receive_Timeout           = cast(c.int)freebsd.Socket_Option.RCVTIMEO,
}

@(private)
_create_socket :: proc(family: Address_Family, protocol: Socket_Protocol) -> (socket: Any_Socket, err: Network_Error) {
	sys_family:      freebsd.Protocol_Family = ---
	sys_protocol:    freebsd.Protocol        = ---
	sys_socket_type: freebsd.Socket_Type     = ---

	switch family {
	case .IP4: sys_family = .INET
	case .IP6: sys_family = .INET6
	}

	switch protocol {
	case .TCP: sys_protocol = .TCP; sys_socket_type = .STREAM
	case .UDP: sys_protocol = .UDP; sys_socket_type = .DGRAM
	}

	new_socket, errno := freebsd.socket(sys_family, sys_socket_type, sys_protocol)
	if errno != nil {
		err = cast(Create_Socket_Error)errno
		return
	}

	// NOTE(Feoramund): By default, FreeBSD will generate SIGPIPE if an EPIPE
	// error is raised during the writing of a socket that may be closed.
	// This behavior is unlikely to be expected by general users.
	//
	// There are two workarounds. One is to apply the .NOSIGNAL flag when using
	// the `sendto` syscall. However, that would prevent users of this library
	// from re-enabling the SIGPIPE-raising functionality, if they really
	// wanted it.
	//
	// So I have disabled it here with this socket option for all sockets.
	truth: b32 = true
	errno = freebsd.setsockopt(new_socket, .SOCKET, .NOSIGPIPE, &truth, size_of(truth))
	if errno != nil {
		err = cast(Socket_Option_Error)errno
		return
	}

	switch protocol {
	case .TCP: return cast(TCP_Socket)new_socket, nil
	case .UDP: return cast(UDP_Socket)new_socket, nil
	}

	return
}

@(private)
_dial_tcp_from_endpoint :: proc(endpoint: Endpoint, options := default_tcp_options) -> (socket: TCP_Socket, err: Network_Error) {
	if endpoint.port == 0 {
		return 0, .Port_Required
	}

	family := family_from_endpoint(endpoint)
	new_socket := create_socket(family, .TCP) or_return
	socket = new_socket.(TCP_Socket)

	sockaddr := _endpoint_to_sockaddr(endpoint)
	errno := freebsd.connect(cast(Fd)socket, &sockaddr, cast(freebsd.socklen_t)sockaddr.len)
	if errno != nil {
		close(socket)
		return {}, cast(Dial_Error)errno
	}

	return
}

@(private)
_bind :: proc(socket: Any_Socket, ep: Endpoint) -> (err: Network_Error) {
	sockaddr := _endpoint_to_sockaddr(ep)
	real_socket := any_socket_to_socket(socket)
	errno := freebsd.bind(cast(Fd)real_socket, &sockaddr, cast(freebsd.socklen_t)sockaddr.len)
	if errno != nil {
		err = cast(Bind_Error)errno
	}
	return
}

@(private)
_listen_tcp :: proc(interface_endpoint: Endpoint, backlog := 1000) -> (socket: TCP_Socket, err: Network_Error) {
	family := family_from_endpoint(interface_endpoint)
	new_socket := create_socket(family, .TCP) or_return
	socket = new_socket.(TCP_Socket)
	defer if err != nil { close(socket) }

	bind(socket, interface_endpoint) or_return

	errno := freebsd.listen(cast(Fd)socket, backlog)
	if errno != nil {
		err = cast(Listen_Error)errno
		return
	}

	return
}

@(private)
_bound_endpoint :: proc(sock: Any_Socket) -> (ep: Endpoint, err: Network_Error) {
	sockaddr: freebsd.Socket_Address_Storage

	errno := freebsd.getsockname(cast(Fd)any_socket_to_socket(sock), &sockaddr)
	if errno != nil {
		err = cast(Listen_Error)errno
		return
	}

	ep = _sockaddr_to_endpoint(&sockaddr)
	return
}

@(private)
_accept_tcp :: proc(sock: TCP_Socket, options := default_tcp_options) -> (client: TCP_Socket, source: Endpoint, err: Network_Error) {
	sockaddr: freebsd.Socket_Address_Storage

	result, errno := freebsd.accept(cast(Fd)sock, &sockaddr)
	if errno != nil {
		err = cast(Accept_Error)errno
		return
	}

	client = cast(TCP_Socket)result
	source = _sockaddr_to_endpoint(&sockaddr)
	return
}

@(private)
_close :: proc(socket: Any_Socket) {
	real_socket := cast(Fd)any_socket_to_socket(socket)
	// TODO: This returns an error number, but the `core:net` interface does not handle it.
	_ = freebsd.close(real_socket)
}

@(private)
_recv_tcp :: proc(socket: TCP_Socket, buf: []byte) -> (bytes_read: int, err: Network_Error) {
	if len(buf) == 0 {
		return
	}
	result, errno := freebsd.recv(cast(Fd)socket, buf, .NONE)
	if errno != nil {
		err = cast(TCP_Recv_Error)errno
		return
	}
	return result, nil
}

@(private)
_recv_udp :: proc(socket: UDP_Socket, buf: []byte) -> (bytes_read: int, remote_endpoint: Endpoint, err: Network_Error) {
	if len(buf) == 0 {
		return
	}
	from: freebsd.Socket_Address_Storage

	result, errno := freebsd.recvfrom(cast(Fd)socket, buf, .NONE, &from)
	if errno != nil {
		err = cast(UDP_Recv_Error)errno
		return
	}
	return result, _sockaddr_to_endpoint(&from), nil
}

@(private)
_send_tcp :: proc(socket: TCP_Socket, buf: []byte) -> (bytes_written: int, err: Network_Error) {
	for bytes_written < len(buf) {
		limit := min(int(max(i32)), len(buf) - bytes_written)
		remaining := buf[bytes_written:][:limit]

		result, errno := freebsd.send(cast(Fd)socket, remaining, .NONE)
		if errno != nil {
			err = cast(TCP_Send_Error)errno
			return
		}
		bytes_written += result
	}
	return
}

@(private)
_send_udp :: proc(socket: UDP_Socket, buf: []byte, to: Endpoint) -> (bytes_written: int, err: Network_Error) {
	toaddr := _endpoint_to_sockaddr(to)
	for bytes_written < len(buf) {
		limit := min(int(max(i32)), len(buf) - bytes_written)
		remaining := buf[bytes_written:][:limit]

		result, errno := freebsd.sendto(cast(Fd)socket, remaining, .NONE, &toaddr)
		if errno != nil {
			err = cast(UDP_Send_Error)errno
			return
		}
		bytes_written += result
	}
	return
}

@(private)
_shutdown :: proc(socket: Any_Socket, manner: Shutdown_Manner) -> (err: Network_Error) {
	real_socket := cast(Fd)any_socket_to_socket(socket)
	errno := freebsd.shutdown(real_socket, cast(freebsd.Shutdown_Method)manner)
	if errno != nil {
		return cast(Shutdown_Error)errno
	}
	return
}

@(private)
_set_option :: proc(socket: Any_Socket, option: Socket_Option, value: any, loc := #caller_location) -> Network_Error {
	// NOTE(Feoramund): I found that FreeBSD, like Linux, requires at least 32
	// bits for a boolean socket option value. Nothing less will work.
	bool_value: b32
	// TODO: Assuming no larger than i32, but the system may accept i64.
	int_value: i32
	timeval_value: freebsd.timeval

	ptr: rawptr
	len: freebsd.socklen_t

	switch option {
	case
		.Reuse_Address,
		.Keep_Alive,
		.Broadcast,
		.Use_Loopback,
		.Out_Of_Bounds_Data_Inline,
		.Reuse_Port,
		.No_SIGPIPE_From_EPIPE,
		.Reuse_Port_Load_Balancing:
			switch real in value {
			case bool: bool_value = cast(b32)real
			case b8:   bool_value = cast(b32)real
			case b16:  bool_value = cast(b32)real
			case b32:  bool_value = real
			case b64:  bool_value = cast(b32)real
			case:
				panic("set_option() value must be a boolean here", loc)
			}
			ptr = &bool_value
			len = size_of(bool_value)
	case
		.Linger,
		.Send_Timeout,
		.Receive_Timeout:
			t, ok := value.(time.Duration)
			if !ok {
				panic("set_option() value must be a time.Duration here", loc)
			}

			micros := cast(freebsd.time_t)time.duration_microseconds(t)
			timeval_value.usec = cast(freebsd.suseconds_t)micros % 1e6
			timeval_value.sec = (micros - cast(freebsd.time_t)timeval_value.usec) / 1e6

			ptr = &timeval_value
			len = size_of(timeval_value)
	case
		.Receive_Buffer_Size,
		.Send_Buffer_Size:
			switch real in value {
			case   i8: int_value = cast(i32)real
			case   u8: int_value = cast(i32)real
			case  i16: int_value = cast(i32)real
			case  u16: int_value = cast(i32)real
			case  i32: int_value = real
			case  u32:
				if real > u32(max(i32)) { return .Value_Out_Of_Range }
				int_value = cast(i32)real
			case  i64:
				if real > i64(max(i32)) || real < i64(min(i32)) { return .Value_Out_Of_Range }
				int_value = cast(i32)real
			case  u64:
				if real > u64(max(i32)) { return .Value_Out_Of_Range }
				int_value = cast(i32)real
			case i128:
				if real > i128(max(i32)) || real < i128(min(i32)) { return .Value_Out_Of_Range }
				int_value = cast(i32)real
			case u128:
				if real > u128(max(i32)) { return .Value_Out_Of_Range }
				int_value = cast(i32)real
			case  int:
				if real > int(max(i32)) || real < int(min(i32)) { return .Value_Out_Of_Range }
				int_value = cast(i32)real
			case uint:
				if real > uint(max(i32)) { return .Value_Out_Of_Range }
				int_value = cast(i32)real
			case:
				panic("set_option() value must be an integer here", loc)
			}
			ptr = &int_value
			len = size_of(int_value)
	case:
		unimplemented("set_option() option not yet implemented", loc)
	}

	real_socket := any_socket_to_socket(socket)
	errno := freebsd.setsockopt(cast(Fd)real_socket, .SOCKET, cast(freebsd.Socket_Option)option, ptr, len)
	if errno != nil {
		return cast(Socket_Option_Error)errno
	}

	return nil
}

@(private)
_set_blocking :: proc(socket: Any_Socket, should_block: bool) -> (err: Network_Error) {
	real_socket := any_socket_to_socket(socket)

	flags, errno := freebsd.fcntl_getfl(cast(freebsd.Fd)real_socket)
	if errno != nil {
		return cast(Set_Blocking_Error)errno
	}

	if should_block {
		flags &= ~{ .NONBLOCK }
	} else {
		flags |= { .NONBLOCK }
	}

	errno = freebsd.fcntl_setfl(cast(freebsd.Fd)real_socket, flags)
	if errno != nil {
		return cast(Set_Blocking_Error)errno
	}

	return
}

@(private)
_endpoint_to_sockaddr :: proc(ep: Endpoint) -> (sockaddr: freebsd.Socket_Address_Storage) {
	switch addr in ep.address {
	case IP4_Address:
		(cast(^freebsd.Socket_Address_Internet)(&sockaddr))^ = {
			len = size_of(freebsd.Socket_Address_Internet),
			family = .INET,
			port = cast(freebsd.in_port_t)ep.port,
			addr = transmute(freebsd.IP4_Address)addr,
		}
	case IP6_Address:
		(cast(^freebsd.Socket_Address_Internet6)(&sockaddr))^ = {
			len = size_of(freebsd.Socket_Address_Internet),
			family = .INET6,
			port = cast(freebsd.in_port_t)ep.port,
			addr = transmute(freebsd.IP6_Address)addr,
		}
	}
	return
}

@(private)
_sockaddr_to_endpoint :: proc(native_addr: ^freebsd.Socket_Address_Storage) -> (ep: Endpoint) {
	#partial switch native_addr.family {
	case .INET:
		addr := cast(^freebsd.Socket_Address_Internet)native_addr
		ep = {
			address = cast(IP4_Address)addr.addr.addr8,
			port = cast(int)addr.port,
		}
	case .INET6:
		addr := cast(^freebsd.Socket_Address_Internet6)native_addr
		ep = {
			address = cast(IP6_Address)addr.addr.addr16,
			port = cast(int)addr.port,
		}
	case:
		panic("native_addr is neither an IP4 or IP6 address")
	}
	return
}
