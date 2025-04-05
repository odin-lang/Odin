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

import "core:c"
import "core:sys/posix"
import "core:time"

Socket_Option :: enum c.int {
	Broadcast                 = c.int(posix.Sock_Option.BROADCAST),
	Reuse_Address             = c.int(posix.Sock_Option.REUSEADDR),
	Keep_Alive                = c.int(posix.Sock_Option.KEEPALIVE),
	Out_Of_Bounds_Data_Inline = c.int(posix.Sock_Option.OOBINLINE),
	TCP_Nodelay               = c.int(posix.TCP_NODELAY),
	Linger                    = c.int(posix.Sock_Option.LINGER),
	Receive_Buffer_Size       = c.int(posix.Sock_Option.RCVBUF),
	Send_Buffer_Size          = c.int(posix.Sock_Option.SNDBUF),
	Receive_Timeout           = c.int(posix.Sock_Option.RCVTIMEO),
	Send_Timeout              = c.int(posix.Sock_Option.SNDTIMEO),
}

Shutdown_Manner :: enum c.int {
	Receive = c.int(posix.SHUT_RD),
	Send    = c.int(posix.SHUT_WR),
	Both    = c.int(posix.SHUT_RDWR),
}

@(private)
_create_socket :: proc(family: Address_Family, protocol: Socket_Protocol) -> (socket: Any_Socket, err: Create_Socket_Error) {
	c_type: posix.Sock
	c_protocol: posix.Protocol
	c_family: posix.AF

	switch family {
	case .IP4:  c_family = .INET
	case .IP6:  c_family = .INET6
	case:
		unreachable()
	}

	switch protocol {
	case .TCP:  c_type = .STREAM; c_protocol = .TCP
	case .UDP:  c_type = .DGRAM;  c_protocol = .UDP
	case:
		unreachable()
	}

	sock := posix.socket(c_family, c_type, c_protocol)
	if sock < 0 {
		err = _create_socket_error()
		return
	}

	switch protocol {
	case .TCP:  return TCP_Socket(sock), nil
	case .UDP:  return UDP_Socket(sock), nil
	case:
		unreachable()
	}
}

@(private)
_dial_tcp_from_endpoint :: proc(endpoint: Endpoint, options := default_tcp_options) -> (skt: TCP_Socket, err: Network_Error) {
	if endpoint.port == 0 {
		return 0, .Port_Required
	}

	family := family_from_endpoint(endpoint)
	sock := create_socket(family, .TCP) or_return
	skt = sock.(TCP_Socket)

	// NOTE(tetra): This is so that if we crash while the socket is open, we can
	// bypass the cooldown period, and allow the next run of the program to
	// use the same address immediately.
	_ = set_option(skt, .Reuse_Address, true)

	sockaddr := _endpoint_to_sockaddr(endpoint)
	if posix.connect(posix.FD(skt), (^posix.sockaddr)(&sockaddr), posix.socklen_t(sockaddr.ss_len)) != .OK {
		err = _dial_error()
		close(skt)
	}

	return
}

@(private)
_bind :: proc(skt: Any_Socket, ep: Endpoint) -> (err: Bind_Error) {
	sockaddr := _endpoint_to_sockaddr(ep)
	s := any_socket_to_socket(skt)
	if posix.bind(posix.FD(s), (^posix.sockaddr)(&sockaddr), posix.socklen_t(sockaddr.ss_len)) != .OK {
		err = _bind_error()
	}

	return
}

@(private)
_listen_tcp :: proc(interface_endpoint: Endpoint, backlog := 1000) -> (skt: TCP_Socket, err: Network_Error) {
	assert(backlog > 0 && i32(backlog) < max(i32))

	family := family_from_endpoint(interface_endpoint)
	sock := create_socket(family, .TCP) or_return
	skt = sock.(TCP_Socket)
	defer if err != nil { close(skt) }

	// NOTE(tetra): This is so that if we crash while the socket is open, we can
	// bypass the cooldown period, and allow the next run of the program to
	// use the same address immediately.
	//
	_ = set_option(sock, .Reuse_Address, true)

	bind(sock, interface_endpoint) or_return

	if posix.listen(posix.FD(skt), i32(backlog)) != .OK {
		err = _listen_error()
	}

	return
}

@(private)
_bound_endpoint :: proc(sock: Any_Socket) -> (ep: Endpoint, err: Listen_Error) {
	addr: posix.sockaddr_storage
	addr_len := posix.socklen_t(size_of(addr))
	if posix.getsockname(posix.FD(any_socket_to_socket(sock)), (^posix.sockaddr)(&addr), &addr_len) != .OK {
		err = _listen_error()
		return
	}

	ep = _sockaddr_to_endpoint(&addr)
	return
}

@(private)
_accept_tcp :: proc(sock: TCP_Socket, options := default_tcp_options) -> (client: TCP_Socket, source: Endpoint, err: Accept_Error) {
	addr: posix.sockaddr_storage
	addr_len := posix.socklen_t(size_of(addr))
	client_sock := posix.accept(posix.FD(sock), (^posix.sockaddr)(&addr), &addr_len)
	if client_sock < 0 {
		err = _accept_error()
		return
	}

	client = TCP_Socket(client_sock)
	source = _sockaddr_to_endpoint(&addr)
	return
}

@(private)
_close :: proc(skt: Any_Socket) {
	s := any_socket_to_socket(skt)
	posix.close(posix.FD(s))
}

@(private)
_recv_tcp :: proc(skt: TCP_Socket, buf: []byte) -> (bytes_read: int, err: TCP_Recv_Error) {
	if len(buf) <= 0 {
		return
	}

	res := posix.recv(posix.FD(skt), raw_data(buf), len(buf), {})
	if res < 0 {
		err = _tcp_recv_error()
		return
	}

	return int(res), nil
}

@(private)
_recv_udp :: proc(skt: UDP_Socket, buf: []byte) -> (bytes_read: int, remote_endpoint: Endpoint, err: UDP_Recv_Error) {
	if len(buf) <= 0 {
		return
	}

	from: posix.sockaddr_storage
	fromsize := posix.socklen_t(size_of(from))
	res := posix.recvfrom(posix.FD(skt), raw_data(buf), len(buf), {}, (^posix.sockaddr)(&from), &fromsize)
	if res < 0 {
		err = _udp_recv_error()
		return
	}

	bytes_read = int(res)
	remote_endpoint = _sockaddr_to_endpoint(&from)
	return
}

@(private)
_send_tcp :: proc(skt: TCP_Socket, buf: []byte) -> (bytes_written: int, err: TCP_Send_Error) {
	for bytes_written < len(buf) {
		limit := min(int(max(i32)), len(buf) - bytes_written)
		remaining := buf[bytes_written:][:limit]
		res := posix.send(posix.FD(skt), raw_data(remaining), len(remaining), {.NOSIGNAL})
		if res < 0 {
			err = _tcp_send_error()
			return
		}

		bytes_written += int(res)
	}
	return
}

@(private)
_send_udp :: proc(skt: UDP_Socket, buf: []byte, to: Endpoint) -> (bytes_written: int, err: UDP_Send_Error) {
	toaddr := _endpoint_to_sockaddr(to)
	for bytes_written < len(buf) {
		limit := min(1<<31, len(buf) - bytes_written)
		remaining := buf[bytes_written:][:limit]
		res := posix.sendto(posix.FD(skt), raw_data(remaining), len(remaining), {.NOSIGNAL}, (^posix.sockaddr)(&toaddr), posix.socklen_t(toaddr.ss_len))
		if res < 0 {
			err = _udp_send_error()
			return
		}

		bytes_written += int(res)
	}
	return
}

@(private)
_shutdown :: proc(skt: Any_Socket, manner: Shutdown_Manner) -> (err: Shutdown_Error) {
	s := any_socket_to_socket(skt)
	if posix.shutdown(posix.FD(s), posix.Shut(manner)) != .OK {
		err = _shutdown_error()
	}
	return
}

@(private)
_set_option :: proc(s: Any_Socket, option: Socket_Option, value: any, loc := #caller_location) -> Socket_Option_Error {
	level := posix.SOL_SOCKET if option != .TCP_Nodelay else posix.IPPROTO_TCP

	// NOTE(tetra, 2022-02-15): On Linux, you cannot merely give a single byte for a bool;
	//  it _has_ to be a b32.
	//  I haven't tested if you can give more than that.
	bool_value: b32
	int_value: posix.socklen_t
	timeval_value: posix.timeval

	ptr: rawptr
	len: posix.socklen_t

	switch option {
	case
		.Broadcast,
		.Reuse_Address,
		.Keep_Alive,
		.Out_Of_Bounds_Data_Inline,
		.TCP_Nodelay:
		// TODO: verify whether these are options or not on Linux
		// .Broadcast,
		// .Conditional_Accept,
		// .Dont_Linger:
			switch x in value {
			case bool, b8:
				x2 := x
				bool_value = b32((^bool)(&x2)^)
			case b16:
				bool_value = b32(x)
			case b32:
				bool_value = b32(x)
			case b64:
				bool_value = b32(x)
			case:
				panic("set_option() value must be a boolean here", loc)
			}
			ptr = &bool_value
			len = size_of(bool_value)
	case
		.Linger,
		.Send_Timeout,
		.Receive_Timeout:
			t := value.(time.Duration) or_else panic("set_option() value must be a time.Duration here", loc)

			micros := i64(time.duration_microseconds(t))
			timeval_value.tv_usec = posix.suseconds_t(micros % 1e6)
			timeval_value.tv_sec  = posix.time_t(micros - i64(timeval_value.tv_usec)) / 1e6

			ptr = &timeval_value
			len = size_of(timeval_value)
	case
		.Receive_Buffer_Size,
		.Send_Buffer_Size:
			// TODO: check for out of range values and return .Value_Out_Of_Range?
			switch i in value {
			case i8, u8:   i2 := i; int_value = posix.socklen_t((^u8)(&i2)^)
			case i16, u16: i2 := i; int_value = posix.socklen_t((^u16)(&i2)^)
			case i32, u32: i2 := i; int_value = posix.socklen_t((^u32)(&i2)^)
			case i64, u64: i2 := i; int_value = posix.socklen_t((^u64)(&i2)^)
			case i128, u128: i2 := i; int_value = posix.socklen_t((^u128)(&i2)^)
			case int, uint: i2 := i; int_value = posix.socklen_t((^uint)(&i2)^)
			case:
				panic("set_option() value must be an integer here", loc)
			}
			ptr = &int_value
			len = size_of(int_value)
	}

	skt := any_socket_to_socket(s)
	if posix.setsockopt(posix.FD(skt), i32(level), posix.Sock_Option(option), ptr, len) != .OK {
		return _socket_option_error()
	}

	return nil
}

@(private)
_set_blocking :: proc(socket: Any_Socket, should_block: bool) -> (err: Set_Blocking_Error) {
	socket := any_socket_to_socket(socket)

	flags_ := posix.fcntl(posix.FD(socket), .GETFL, 0)
	if flags_ < 0 {
		return _set_blocking_error()
	}
	flags := transmute(posix.O_Flags)flags_

	if should_block {
		flags -= {.NONBLOCK}
	} else {
		flags += {.NONBLOCK}
	}

	if posix.fcntl(posix.FD(socket), .SETFL, flags) < 0 {
		return _set_blocking_error()
	}

	return nil
}

@private
_endpoint_to_sockaddr :: proc(ep: Endpoint) -> (sockaddr: posix.sockaddr_storage) {
	switch a in ep.address {
	case IP4_Address:
		(^posix.sockaddr_in)(&sockaddr)^ = posix.sockaddr_in {
			sin_port = u16be(ep.port),
			sin_addr = transmute(posix.in_addr)a,
			sin_family = .INET,
			sin_len = size_of(posix.sockaddr_in),
		}
		return
	case IP6_Address:
		(^posix.sockaddr_in6)(&sockaddr)^ = posix.sockaddr_in6 {
			sin6_port = u16be(ep.port),
			sin6_addr = transmute(posix.in6_addr)a,
			sin6_family = .INET6,
			sin6_len = size_of(posix.sockaddr_in6),
		}
		return
	}
	unreachable()
}

@private
_sockaddr_to_endpoint :: proc(native_addr: ^posix.sockaddr_storage) -> (ep: Endpoint) {
	#partial switch native_addr.ss_family {
	case .INET:
		addr := cast(^posix.sockaddr_in)native_addr
		port := int(addr.sin_port)
		ep = Endpoint {
			address = IP4_Address(transmute([4]byte)addr.sin_addr),
			port    = port,
		}
	case .INET6:
		addr := cast(^posix.sockaddr_in6)native_addr
		port := int(addr.sin6_port)
		ep = Endpoint {
			address = IP6_Address(transmute([8]u16be)addr.sin6_addr),
			port    = port,
		}
	case:
		panic("native_addr is neither IP4 or IP6 address")
	}
	return
}

@(private)
_sockaddr_basic_to_endpoint :: proc(native_addr: ^posix.sockaddr) -> (ep: Endpoint) {
	#partial switch native_addr.sa_family {
	case .INET:
		addr := cast(^posix.sockaddr_in)native_addr
		port := int(addr.sin_port)
		ep = Endpoint {
			address = IP4_Address(transmute([4]byte)addr.sin_addr),
			port    = port,
		}
	case .INET6:
		addr := cast(^posix.sockaddr_in6)native_addr
		port := int(addr.sin6_port)
		ep = Endpoint {
			address = IP6_Address(transmute([8]u16be)addr.sin6_addr),
			port    = port,
		}
	case:
		panic("native_addr is neither IP4 or IP6 address")
	}
	return
}
