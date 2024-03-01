package net
// +build darwin

/*
	Package net implements cross-platform Berkeley Sockets, DNS resolution and associated procedures.
	For other protocols and their features, see subdirectories of this package.
*/

/*
	Copyright 2022 Tetralux        <tetraluxonpc@gmail.com>
	Copyright 2022 Colin Davidson  <colrdavidson@gmail.com>
	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Tetralux:        Initial implementation
		Colin Davidson:  Linux platform code, OSX platform code, Odin-native DNS resolver
		Jeroen van Rijn: Cross platform unification, code style, documentation
*/

import "core:c"
import "core:os"
import "core:time"

Socket_Option :: enum c.int {
	Broadcast                 = c.int(os.SO_BROADCAST),
	Reuse_Address             = c.int(os.SO_REUSEADDR),
	Keep_Alive                = c.int(os.SO_KEEPALIVE),
	Out_Of_Bounds_Data_Inline = c.int(os.SO_OOBINLINE),
	TCP_Nodelay               = c.int(os.TCP_NODELAY),
	Linger                    = c.int(os.SO_LINGER),
	Receive_Buffer_Size       = c.int(os.SO_RCVBUF),
	Send_Buffer_Size          = c.int(os.SO_SNDBUF),
	Receive_Timeout           = c.int(os.SO_RCVTIMEO),
	Send_Timeout              = c.int(os.SO_SNDTIMEO),
}

@(private)
_create_socket :: proc(family: Address_Family, protocol: Socket_Protocol) -> (socket: Any_Socket, err: Network_Error) {
	c_type, c_protocol, c_family: int

	switch family {
	case .IP4:  c_family = os.AF_INET
	case .IP6:  c_family = os.AF_INET6
	case:
		unreachable()
	}

	switch protocol {
	case .TCP:  c_type = os.SOCK_STREAM; c_protocol = os.IPPROTO_TCP
	case .UDP:  c_type = os.SOCK_DGRAM;  c_protocol = os.IPPROTO_UDP
	case:
		unreachable()
	}

	sock, ok := os.socket(c_family, c_type, c_protocol)
	if ok != os.ERROR_NONE {
		err = Create_Socket_Error(ok)
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
	res := os.connect(os.Socket(skt), (^os.SOCKADDR)(&sockaddr), i32(sockaddr.len))
	if res != os.ERROR_NONE {
		err = Dial_Error(res)
		return
	}

	return
}

// On Darwin, any port below 1024 is 'privileged' - which means that you need root access in order to use it.
MAX_PRIVILEGED_PORT :: 1023

@(private)
_bind :: proc(skt: Any_Socket, ep: Endpoint) -> (err: Network_Error) {
	sockaddr := _endpoint_to_sockaddr(ep)
	s := any_socket_to_socket(skt)
	res := os.bind(os.Socket(s), (^os.SOCKADDR)(&sockaddr), i32(sockaddr.len))
	if res != os.ERROR_NONE {
		if res == os.EACCES && ep.port <= MAX_PRIVILEGED_PORT {
			err = .Privileged_Port_Without_Root
		} else {
			err = Bind_Error(res)
		}
	}
	return
}

@(private)
_listen_tcp :: proc(interface_endpoint: Endpoint, backlog := 1000) -> (skt: TCP_Socket, err: Network_Error) {
	assert(backlog > 0 && i32(backlog) < max(i32))

	family := family_from_endpoint(interface_endpoint)
	sock := create_socket(family, .TCP) or_return
	skt = sock.(TCP_Socket)

	// NOTE(tetra): This is so that if we crash while the socket is open, we can
	// bypass the cooldown period, and allow the next run of the program to
	// use the same address immediately.
	//
	// TODO(tetra, 2022-02-15): Confirm that this doesn't mean other processes can hijack the address!
	set_option(sock, .Reuse_Address, true) or_return

	bind(sock, interface_endpoint) or_return

	res := os.listen(os.Socket(skt), backlog)
	if res != os.ERROR_NONE {
		err = Listen_Error(res)
		return
	}

	return
}

@(private)
_accept_tcp :: proc(sock: TCP_Socket, options := default_tcp_options) -> (client: TCP_Socket, source: Endpoint, err: Network_Error) {
	sockaddr: os.SOCKADDR_STORAGE_LH
	sockaddrlen := c.int(size_of(sockaddr))

	client_sock, ok := os.accept(os.Socket(sock), cast(^os.SOCKADDR) &sockaddr, &sockaddrlen)
	if ok != os.ERROR_NONE {
		err = Accept_Error(ok)
		return
	}
	client = TCP_Socket(client_sock)
	source = _sockaddr_to_endpoint(&sockaddr)
	return
}

@(private)
_close :: proc(skt: Any_Socket) {
	s := any_socket_to_socket(skt)
	os.close(os.Handle(os.Socket(s)))
}

@(private)
_recv_tcp :: proc(skt: TCP_Socket, buf: []byte) -> (bytes_read: int, err: Network_Error) {
	if len(buf) <= 0 {
		return
	}
	res, ok := os.recv(os.Socket(skt), buf, 0)
	if ok != os.ERROR_NONE {
		err = TCP_Recv_Error(ok)
		return
	}
	return int(res), nil
}

@(private)
_recv_udp :: proc(skt: UDP_Socket, buf: []byte) -> (bytes_read: int, remote_endpoint: Endpoint, err: Network_Error) {
	if len(buf) <= 0 {
		return
	}

	from: os.SOCKADDR_STORAGE_LH
	fromsize := c.int(size_of(from))
	res, ok := os.recvfrom(os.Socket(skt), buf, 0, cast(^os.SOCKADDR) &from, &fromsize)
	if ok != os.ERROR_NONE {
		err = UDP_Recv_Error(ok)
		return
	}

	bytes_read = int(res)
	remote_endpoint = _sockaddr_to_endpoint(&from)
	return
}

@(private)
_send_tcp :: proc(skt: TCP_Socket, buf: []byte) -> (bytes_written: int, err: Network_Error) {
	for bytes_written < len(buf) {
		limit := min(int(max(i32)), len(buf) - bytes_written)
		remaining := buf[bytes_written:][:limit]
		res, ok := os.send(os.Socket(skt), remaining, 0)
		if ok != os.ERROR_NONE {
			err = TCP_Send_Error(ok)
			return
		}
		bytes_written += int(res)
	}
	return
}

@(private)
_send_udp :: proc(skt: UDP_Socket, buf: []byte, to: Endpoint) -> (bytes_written: int, err: Network_Error) {
	toaddr := _endpoint_to_sockaddr(to)
	for bytes_written < len(buf) {
		limit := min(1<<31, len(buf) - bytes_written)
		remaining := buf[bytes_written:][:limit]
		res, ok := os.sendto(os.Socket(skt), remaining, 0, cast(^os.SOCKADDR)&toaddr, i32(toaddr.len))
		if ok != os.ERROR_NONE {
			err = UDP_Send_Error(ok)
			return
		}
		bytes_written += int(res)
	}
	return
}

@(private)
_shutdown :: proc(skt: Any_Socket, manner: Shutdown_Manner) -> (err: Network_Error) {
	s := any_socket_to_socket(skt)
	res := os.shutdown(os.Socket(s), int(manner))
	if res != os.ERROR_NONE {
		return Shutdown_Error(res)
	}
	return
}

@(private)
_set_option :: proc(s: Any_Socket, option: Socket_Option, value: any, loc := #caller_location) -> Network_Error {
	level := os.SOL_SOCKET if option != .TCP_Nodelay else os.IPPROTO_TCP

	// NOTE(tetra, 2022-02-15): On Linux, you cannot merely give a single byte for a bool;
	//  it _has_ to be a b32.
	//  I haven't tested if you can give more than that.
	bool_value: b32
	int_value: i32
	timeval_value: os.Timeval

	ptr: rawptr
	len: os.socklen_t

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
			t, ok := value.(time.Duration)
			if !ok do panic("set_option() value must be a time.Duration here", loc)

			micros := i64(time.duration_microseconds(t))
			timeval_value.microseconds = int(micros % 1e6)
			timeval_value.seconds = (micros - i64(timeval_value.microseconds)) / 1e6

			ptr = &timeval_value
			len = size_of(timeval_value)
	case
		.Receive_Buffer_Size,
		.Send_Buffer_Size:
			// TODO: check for out of range values and return .Value_Out_Of_Range?
			switch i in value {
			case i8, u8:   i2 := i; int_value = os.socklen_t((^u8)(&i2)^)
			case i16, u16: i2 := i; int_value = os.socklen_t((^u16)(&i2)^)
			case i32, u32: i2 := i; int_value = os.socklen_t((^u32)(&i2)^)
			case i64, u64: i2 := i; int_value = os.socklen_t((^u64)(&i2)^)
			case i128, u128: i2 := i; int_value = os.socklen_t((^u128)(&i2)^)
			case int, uint: i2 := i; int_value = os.socklen_t((^uint)(&i2)^)
			case:
				panic("set_option() value must be an integer here", loc)
			}
			ptr = &int_value
			len = size_of(int_value)
	}

	skt := any_socket_to_socket(s)
	res := os.setsockopt(os.Socket(skt), int(level), int(option), ptr, len)
	if res != os.ERROR_NONE {
		return Socket_Option_Error(res)
	}

	return nil
}

@(private)
_set_blocking :: proc(socket: Any_Socket, should_block: bool) -> (err: Network_Error) {
	socket := any_socket_to_socket(socket)

	flags, getfl_err := os.fcntl(int(socket), os.F_GETFL, 0)
	if getfl_err != os.ERROR_NONE {
		return Set_Blocking_Error(getfl_err)
	}

	if should_block {
		flags &= ~int(os.O_NONBLOCK)
	} else {
		flags |= int(os.O_NONBLOCK)
	}

	_, setfl_err := os.fcntl(int(socket), os.F_SETFL, flags)
	if setfl_err != os.ERROR_NONE {
		return Set_Blocking_Error(setfl_err)
	}

	return nil
}

@private
_endpoint_to_sockaddr :: proc(ep: Endpoint) -> (sockaddr: os.SOCKADDR_STORAGE_LH) {
	switch a in ep.address {
	case IP4_Address:
		(^os.sockaddr_in)(&sockaddr)^ = os.sockaddr_in {
			sin_port = u16be(ep.port),
			sin_addr = transmute(os.in_addr) a,
			sin_family = u8(os.AF_INET),
			sin_len = size_of(os.sockaddr_in),
		}
		return
	case IP6_Address:
		(^os.sockaddr_in6)(&sockaddr)^ = os.sockaddr_in6 {
			sin6_port = u16be(ep.port),
			sin6_addr = transmute(os.in6_addr) a,
			sin6_family = u8(os.AF_INET6),
			sin6_len = size_of(os.sockaddr_in6),
		}
		return
	}
	unreachable()
}

@private
_sockaddr_to_endpoint :: proc(native_addr: ^os.SOCKADDR_STORAGE_LH) -> (ep: Endpoint) {
	switch native_addr.family {
	case u8(os.AF_INET):
		addr := cast(^os.sockaddr_in) native_addr
		port := int(addr.sin_port)
		ep = Endpoint {
			address = IP4_Address(transmute([4]byte) addr.sin_addr),
			port = port,
		}
	case u8(os.AF_INET6):
		addr := cast(^os.sockaddr_in6) native_addr
		port := int(addr.sin6_port)
		ep = Endpoint {
			address = IP6_Address(transmute([8]u16be) addr.sin6_addr),
			port = port,
		}
	case:
		panic("native_addr is neither IP4 or IP6 address")
	}
	return
}

@(private)
_sockaddr_basic_to_endpoint :: proc(native_addr: ^os.SOCKADDR) -> (ep: Endpoint) {
	switch u16(native_addr.family) {
	case u16(os.AF_INET):
		addr := cast(^os.sockaddr_in) native_addr
		port := int(addr.sin_port)
		ep = Endpoint {
			address = IP4_Address(transmute([4]byte) addr.sin_addr),
			port = port,
		}
	case u16(os.AF_INET6):
		addr := cast(^os.sockaddr_in6) native_addr
		port := int(addr.sin6_port)
		ep = Endpoint {
			address = IP6_Address(transmute([8]u16be) addr.sin6_addr),
			port = port,
		}
	case:
		panic("native_addr is neither IP4 or IP6 address")
	}
	return
}
