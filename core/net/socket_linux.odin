#+build linux
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
		flysand:         Move dependency from core:os to core:sys/linux
		Feoramund:       FreeBSD platform code
*/

import "core:c"
import "core:time"
import "core:sys/linux"

Socket_Option :: enum c.int {
	Reuse_Address             = c.int(linux.Socket_Option.REUSEADDR),
	Keep_Alive                = c.int(linux.Socket_Option.KEEPALIVE),
	Out_Of_Bounds_Data_Inline = c.int(linux.Socket_Option.OOBINLINE),
	TCP_Nodelay               = c.int(linux.Socket_TCP_Option.NODELAY),
	Linger                    = c.int(linux.Socket_Option.LINGER),
	Receive_Buffer_Size       = c.int(linux.Socket_Option.RCVBUF),
	Send_Buffer_Size          = c.int(linux.Socket_Option.SNDBUF),
	Receive_Timeout           = c.int(linux.Socket_Option.RCVTIMEO),
	Send_Timeout              = c.int(linux.Socket_Option.SNDTIMEO),
	Broadcast                 = c.int(linux.Socket_Option.BROADCAST),
}

Shutdown_Manner :: enum c.int {
	Receive = c.int(linux.Shutdown_How.RD),
	Send    = c.int(linux.Shutdown_How.WR),
	Both    = c.int(linux.Shutdown_How.RDWR),
}

// Wrappers and unwrappers for system-native types

@(private="file")
_unwrap_os_socket :: proc "contextless" (sock: Any_Socket) -> linux.Fd {
	return linux.Fd(any_socket_to_socket(sock))
}

@(private="file")
_wrap_os_socket :: proc "contextless" (sock: linux.Fd, protocol: Socket_Protocol) -> Any_Socket {
	switch protocol {
	case .TCP:  return TCP_Socket(Socket(sock))
	case .UDP:  return UDP_Socket(Socket(sock))
	case:
		unreachable()
	}
}

@(private="file")
_unwrap_os_family :: proc "contextless" (family: Address_Family) -> linux.Address_Family {
	switch family {
	case .IP4:  return .INET
	case .IP6:  return .INET6
	case:
		unreachable()
	}
}

@(private="file")
_unwrap_os_proto_socktype :: proc "contextless" (protocol: Socket_Protocol) -> (linux.Protocol, linux.Socket_Type) {
	switch protocol {
	case .TCP:  return .TCP, .STREAM
	case .UDP:  return .UDP, .DGRAM
	case:
		unreachable()
	}
}

@(private="file")
_unwrap_os_addr :: proc "contextless" (endpoint: Endpoint) -> linux.Sock_Addr_Any {
	switch address in endpoint.address {
	case IP4_Address:
		return {
			ipv4 = {
				sin_family = .INET,
				sin_port = u16be(endpoint.port),
				sin_addr = ([4]u8)(endpoint.address.(IP4_Address)),
			},
		}
	case IP6_Address:
		return {
			ipv6 = {
				sin6_port = u16be(endpoint.port),
				sin6_addr = transmute([16]u8)endpoint.address.(IP6_Address),
				sin6_family = .INET6,
			},
		}
	case:
		unreachable()
	}
}

@(private="file")
_wrap_os_addr :: proc "contextless" (addr: linux.Sock_Addr_Any) -> Endpoint {
	#partial switch addr.family {
	case .INET:
		return {
			address = cast(IP4_Address) addr.sin_addr,
			port = cast(int) addr.sin_port,
		}
	case .INET6:
		return {
			port = cast(int) addr.sin6_port,
			address = transmute(IP6_Address) addr.sin6_addr,
		}
	case:
		unreachable()
	}
}

_create_socket :: proc(family: Address_Family, protocol: Socket_Protocol) -> (Any_Socket, Create_Socket_Error) {
	family := _unwrap_os_family(family)
	proto, socktype := _unwrap_os_proto_socktype(protocol)
	sock, errno := linux.socket(family, socktype, {.CLOEXEC}, proto)
	if errno != .NONE {
		return {}, _create_socket_error(errno)
	}
	return _wrap_os_socket(sock, protocol), nil
}

@(private)
_dial_tcp_from_endpoint :: proc(endpoint: Endpoint, options := default_tcp_options) -> (TCP_Socket, Network_Error) {
	errno: linux.Errno
	if endpoint.port == 0 {
		return 0, .Port_Required
	}
	// Create new TCP socket
	os_sock: linux.Fd
	os_sock, errno = linux.socket(_unwrap_os_family(family_from_endpoint(endpoint)), .STREAM, {.CLOEXEC}, .TCP)
	if errno != .NONE {
		// TODO(flysand): should return invalid file descriptor here casted as TCP_Socket
		return {}, _create_socket_error(errno)
	}
	// NOTE(tetra): This is so that if we crash while the socket is open, we can
	// bypass the cooldown period, and allow the next run of the program to
	// use the same address immediately.
	reuse_addr: b32 = true
	_ = linux.setsockopt(os_sock, linux.SOL_SOCKET, linux.Socket_Option.REUSEADDR, &reuse_addr)
	addr := _unwrap_os_addr(endpoint)
	errno = linux.connect(linux.Fd(os_sock), &addr)
	if errno != .NONE {
		close(cast(TCP_Socket) os_sock)
		return {}, _dial_error(errno)
	}
	// NOTE(tetra): Not vital to succeed; error ignored
	no_delay: b32 = cast(b32) options.no_delay
	_ = linux.setsockopt(os_sock, linux.SOL_TCP, linux.Socket_TCP_Option.NODELAY, &no_delay)
	return cast(TCP_Socket) os_sock, nil
}

@(private)
_bind :: proc(sock: Any_Socket, endpoint: Endpoint) -> (Bind_Error) {
	addr := _unwrap_os_addr(endpoint)
	errno := linux.bind(_unwrap_os_socket(sock), &addr)
	if errno != .NONE {
		return _bind_error(errno)
	}
	return nil
}

@(private)
_listen_tcp :: proc(endpoint: Endpoint, backlog := 1000) -> (socket: TCP_Socket, err: Network_Error) {
	errno: linux.Errno
	assert(backlog > 0 && i32(backlog) < max(i32))

	// Figure out the address family and address of the endpoint
	ep_family := _unwrap_os_family(family_from_endpoint(endpoint))
	ep_address := _unwrap_os_addr(endpoint)

	// Create TCP socket
	os_sock: linux.Fd
	os_sock, errno = linux.socket(ep_family, .STREAM, {.CLOEXEC}, .TCP)
	if errno != .NONE {
		err = _create_socket_error(errno)
		return
	}
	socket = cast(TCP_Socket)os_sock
	defer if err != nil { close(socket) }

	// NOTE(tetra): This is so that if we crash while the socket is open, we can
	// bypass the cooldown period, and allow the next run of the program to
	// use the same address immediately.
	//
	// TODO(tetra, 2022-02-15): Confirm that this doesn't mean other processes can hijack the address!
	do_reuse_addr: b32 = true
	if errno = linux.setsockopt(os_sock, linux.SOL_SOCKET, linux.Socket_Option.REUSEADDR, &do_reuse_addr); errno != .NONE {
		err = _listen_error(errno)
		return
	}

	// Bind the socket to endpoint address
	if errno = linux.bind(os_sock, &ep_address); errno != .NONE {
		err = _bind_error(errno)
		return
	}

	// Listen on bound socket
	if errno = linux.listen(os_sock, cast(i32) backlog); errno != .NONE {
		err = _listen_error(errno)
	}

	return
}

@(private)
_bound_endpoint :: proc(sock: Any_Socket) -> (ep: Endpoint, err: Listen_Error) {
	addr: linux.Sock_Addr_Any
	errno := linux.getsockname(_unwrap_os_socket(sock), &addr)
	if errno != .NONE {
		err = _listen_error(errno)
		return
	}

	ep = _wrap_os_addr(addr)
	return
}

@(private)
_accept_tcp :: proc(sock: TCP_Socket, options := default_tcp_options) -> (tcp_client: TCP_Socket, endpoint: Endpoint, err: Accept_Error) {
	addr: linux.Sock_Addr_Any
	client_sock, errno := linux.accept(linux.Fd(sock), &addr)
	if errno != .NONE {
		return {}, {}, _accept_error(errno)
	}
	// NOTE(tetra): Not vital to succeed; error ignored
	val: b32 = cast(b32) options.no_delay
	_ = linux.setsockopt(client_sock, linux.SOL_TCP, linux.Socket_TCP_Option.NODELAY, &val)
	return TCP_Socket(client_sock), _wrap_os_addr(addr), nil
}

@(private)
_close :: proc(sock: Any_Socket) {
	linux.close(_unwrap_os_socket(sock))
}

@(private)
_recv_tcp :: proc(tcp_sock: TCP_Socket, buf: []byte) -> (int, TCP_Recv_Error) {
	if len(buf) <= 0 {
		return 0, nil
	}
	bytes_read, errno := linux.recv(linux.Fd(tcp_sock), buf, {})
	if errno != .NONE {
		return 0, _tcp_recv_error(errno)
	}
	return int(bytes_read), nil
}

@(private)
_recv_udp :: proc(udp_sock: UDP_Socket, buf: []byte) -> (int, Endpoint, UDP_Recv_Error) {
	if len(buf) <= 0 {
		// NOTE(flysand): It was returning no error, I didn't change anything
		return 0, {}, {}
	}
	// NOTE(tetra): On Linux, if the buffer is too small to fit the entire datagram payload, the rest is silently discarded,
	// and no error is returned.
	// However, if you pass MSG_TRUNC here, 'res' will be the size of the incoming message, rather than how much was read.
	// We can use this fact to detect this condition and return .Buffer_Too_Small.
	from_addr: linux.Sock_Addr_Any
	bytes_read, errno := linux.recvfrom(linux.Fd(udp_sock), buf, {.TRUNC}, &from_addr)
	if errno != .NONE {
		return 0, {}, _udp_recv_error(errno)
	}
	if bytes_read > len(buf) {
		// NOTE(tetra): The buffer has been filled, with a partial message.
		return len(buf), {}, .Excess_Truncated
	}
	return bytes_read, _wrap_os_addr(from_addr), nil
}

@(private)
_send_tcp :: proc(tcp_sock: TCP_Socket, buf: []byte) -> (int, TCP_Send_Error) {
	total_written := 0
	for total_written < len(buf) {
		limit := min(int(max(i32)), len(buf) - total_written)
		remaining := buf[total_written:][:limit]
		res, errno := linux.send(linux.Fd(tcp_sock), remaining, {.NOSIGNAL})
		if errno != .NONE {
			return total_written, _tcp_send_error(errno)
		}
		total_written += int(res)
	}
	return total_written, nil
}

@(private)
_send_udp :: proc(udp_sock: UDP_Socket, buf: []byte, to: Endpoint) -> (int, UDP_Send_Error) {
	to_addr := _unwrap_os_addr(to)
	bytes_written, errno := linux.sendto(linux.Fd(udp_sock), buf, {}, &to_addr)
	if errno != .NONE {
		return bytes_written, _udp_send_error(errno)
	}
	return int(bytes_written), nil
}

@(private)
_shutdown :: proc(sock: Any_Socket, manner: Shutdown_Manner) -> (err: Shutdown_Error) {
	os_sock := _unwrap_os_socket(sock)
	errno := linux.shutdown(os_sock, cast(linux.Shutdown_How) manner)
	if errno != .NONE {
		return _shutdown_error(errno)
	}
	return nil
}

// TODO(flysand): Figure out what we want to do with this on core:sys/ level.
@(private)
_set_option :: proc(sock: Any_Socket, option: Socket_Option, value: any, loc := #caller_location) -> Socket_Option_Error {
	level: int
	if option == .TCP_Nodelay {
		level = int(linux.SOL_TCP)
	} else {
		level = int(linux.SOL_SOCKET)
	}
	os_sock := _unwrap_os_socket(sock)
	// NOTE(tetra, 2022-02-15): On Linux, you cannot merely give a single byte for a bool;
	//  it _has_ to be a b32.
	//  I haven't tested if you can give more than that. <-- (flysand) probably not, posix explicitly specifies an int
	bool_value: b32
	int_value: i32
	timeval_value: linux.Time_Val
	errno: linux.Errno
	switch option {
	case
		.Reuse_Address,
		.Keep_Alive,
		.Out_Of_Bounds_Data_Inline,
		.TCP_Nodelay,
		.Broadcast:
		// TODO: verify whether these are options or not on Linux
		// .Broadcast, <-- yes
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
			errno = linux.setsockopt(os_sock, level, int(option), &bool_value)
	case
		.Linger,
		.Send_Timeout,
		.Receive_Timeout:
			t, ok := value.(time.Duration)
			if !ok {
				panic("set_option() value must be a time.Duration here", loc)
			}

			micros := cast(i64) (time.duration_microseconds(t))
			timeval_value.microseconds = cast(int) (micros % 1e6)
			timeval_value.seconds = cast(int) ((micros - i64(timeval_value.microseconds)) / 1e6)
			errno = linux.setsockopt(os_sock, level, int(option), &timeval_value)
	case
		.Receive_Buffer_Size,
		.Send_Buffer_Size:
			// TODO: check for out of range values and return .Value_Out_Of_Range?
			switch i in value {
			case   i8,   u8: i2 := i; int_value = i32((^u8)(&i2)^)
			case  i16,  u16: i2 := i; int_value = i32((^u16)(&i2)^)
			case  i32,  u32: i2 := i; int_value = i32((^u32)(&i2)^)
			case  i64,  u64: i2 := i; int_value = i32((^u64)(&i2)^)
			case i128, u128: i2 := i; int_value = i32((^u128)(&i2)^)
			case  int, uint: i2 := i; int_value = i32((^uint)(&i2)^)
			case:
				panic("set_option() value must be an integer here", loc)
			}
			errno = linux.setsockopt(os_sock, level, int(option), &int_value)
	}
	if errno != .NONE {
		return _socket_option_error(errno)
	}
	return nil
}

@(private)
_set_blocking :: proc(sock: Any_Socket, should_block: bool) -> (err: Set_Blocking_Error) {
	errno: linux.Errno
	flags: linux.Open_Flags
	os_sock := _unwrap_os_socket(sock)
	flags, errno = linux.fcntl(os_sock, linux.F_GETFL)
	if errno != .NONE {
		return _set_blocking_error(errno)
	}
	if should_block {
		flags -= {.NONBLOCK}
	} else {
		flags += {.NONBLOCK}
	}
	errno = linux.fcntl(os_sock, linux.F_SETFL, flags)
	if errno != .NONE {
		return _set_blocking_error(errno)
	}
	return nil
}
