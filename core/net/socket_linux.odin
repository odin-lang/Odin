package net
// +build linux

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

Platform_Socket :: os.Socket

create_socket :: proc(family: Address_Family, protocol: Socket_Protocol) -> (socket: Any_Socket, err: Network_Error) {
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

dial_tcp_from_endpoint :: proc(endpoint: Endpoint, options := default_tcp_options) -> (skt: TCP_Socket, err: Network_Error) {
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
	res := os.connect(Platform_Socket(skt), (^os.SOCKADDR)(&sockaddr), size_of(sockaddr))
	if res != os.ERROR_NONE {
		err = Dial_Error(res)
		return
	}

	if options.no_delay {
		_ = set_option(sock, .TCP_Nodelay, true) // NOTE(tetra): Not vital to succeed; error ignored
	}

	return
}


bind :: proc(skt: Any_Socket, ep: Endpoint) -> (err: Network_Error) {
	sockaddr := _endpoint_to_sockaddr(ep)
	s := any_socket_to_socket(skt)
	res := os.bind(Platform_Socket(s), (^os.SOCKADDR)(&sockaddr), size_of(sockaddr))
	if res != os.ERROR_NONE {
		err = Bind_Error(res)
	}
	return
}

listen_tcp :: proc(interface_endpoint: Endpoint, backlog := 1000) -> (skt: TCP_Socket, err: Network_Error) {
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

	res := os.listen(Platform_Socket(skt), backlog)
	if res != os.ERROR_NONE {
		err = Listen_Error(res)
		return
	}

	return
}

accept_tcp :: proc(sock: TCP_Socket, options := default_tcp_options) -> (client: TCP_Socket, source: Endpoint, err: Network_Error) {
	sockaddr: os.SOCKADDR_STORAGE_LH
	sockaddrlen := c.int(size_of(sockaddr))

	client_sock, ok := os.accept(Platform_Socket(sock), cast(^os.SOCKADDR) &sockaddr, &sockaddrlen)
	if ok != os.ERROR_NONE {
		err = Accept_Error(ok)
		return
	}
	client = TCP_Socket(client_sock)
	source = _sockaddr_storage_to_endpoint(&sockaddr)
	if options.no_delay {
		_ = set_option(client, .TCP_Nodelay, true) // NOTE(tetra): Not vital to succeed; error ignored
	}
	return
}



close :: proc(skt: Any_Socket) {
	s := any_socket_to_socket(skt)
	os.close(os.Handle(Platform_Socket(s)))
}

recv_tcp :: proc(skt: TCP_Socket, buf: []byte) -> (bytes_read: int, err: Network_Error) {
	if len(buf) <= 0 {
		return
	}
	res, ok := os.recv(Platform_Socket(skt), buf, 0)
	if ok != os.ERROR_NONE {
		err = TCP_Recv_Error(ok)
		return
	}
	return int(res), nil
}

recv_udp :: proc(skt: UDP_Socket, buf: []byte) -> (bytes_read: int, remote_endpoint: Endpoint, err: Network_Error) {
	if len(buf) <= 0 {
		return
	}

	from: os.SOCKADDR_STORAGE_LH = ---
	fromsize := c.int(size_of(from))

	// NOTE(tetra): On Linux, if the buffer is too small to fit the entire datagram payload, the rest is silently discarded,
	// and no error is returned.
	// However, if you pass MSG_TRUNC here, 'res' will be the size of the incoming message, rather than how much was read.
	// We can use this fact to detect this condition and return .Buffer_Too_Small.
	res, ok := os.recvfrom(Platform_Socket(skt), buf, os.MSG_TRUNC, cast(^os.SOCKADDR) &from, &fromsize)
	if ok != os.ERROR_NONE {
		err = UDP_Recv_Error(ok)
		return
	}

	bytes_read = int(res)
	remote_endpoint = _sockaddr_storage_to_endpoint(&from)

	if bytes_read > len(buf) {
		// NOTE(tetra): The buffer has been filled, with a partial message.
		bytes_read = len(buf)
		err = .Buffer_Too_Small
	}

	return
}

recv :: proc{recv_tcp, recv_udp}


// Repeatedly sends data until the entire buffer is sent.
// If a send fails before all data is sent, returns the amount
// sent up to that point.
send_tcp :: proc(skt: TCP_Socket, buf: []byte) -> (bytes_written: int, err: Network_Error) {
	for bytes_written < len(buf) {
		limit := min(int(max(i32)), len(buf) - bytes_written)
		remaining := buf[bytes_written:][:limit]
		res, ok := os.send(Platform_Socket(skt), remaining, 0)
		if ok != os.ERROR_NONE {
			err = TCP_Send_Error(ok)
			return
		}
		bytes_written += int(res)
	}
	return
}

// Sends a single UDP datagram packet.
//
// Datagrams are limited in size; attempting to send more than this limit at once will result in a Message_Too_Long error.
// UDP packets are not guarenteed to be received in order.
send_udp :: proc(skt: UDP_Socket, buf: []byte, to: Endpoint) -> (bytes_written: int, err: Network_Error) {
	toaddr := _endpoint_to_sockaddr(to)
	res, os_err := os.sendto(Platform_Socket(skt), buf, 0, cast(^os.SOCKADDR) &toaddr, size_of(toaddr))
	if os_err != os.ERROR_NONE {
		err = UDP_Send_Error(os_err)
		return
	}
	bytes_written = int(res)
	return
}

send :: proc{send_tcp, send_udp}

Shutdown_Manner :: enum c.int {
	Receive = c.int(os.SHUT_RD),
	Send    = c.int(os.SHUT_WR),
	Both    = c.int(os.SHUT_RDWR),
}

shutdown :: proc(skt: Any_Socket, manner: Shutdown_Manner) -> (err: Network_Error) {
	s := any_socket_to_socket(skt)
	res := os.shutdown(Platform_Socket(s), int(manner))
	if res != os.ERROR_NONE {
		return Shutdown_Error(res)
	}
	return
}

Socket_Option :: enum c.int {
	Reuse_Address             = c.int(os.SO_REUSEADDR),
	Keep_Alive                = c.int(os.SO_KEEPALIVE),
	Out_Of_Bounds_Data_Inline = c.int(os.SO_OOBINLINE),
	TCP_Nodelay               = c.int(os.TCP_NODELAY),
	Linger                    = c.int(os.SO_LINGER),
	Receive_Buffer_Size       = c.int(os.SO_RCVBUF),
	Send_Buffer_Size          = c.int(os.SO_SNDBUF),
	Receive_Timeout           = c.int(os.SO_RCVTIMEO_NEW),
	Send_Timeout              = c.int(os.SO_SNDTIMEO_NEW),
}

set_option :: proc(s: Any_Socket, option: Socket_Option, value: any, loc := #caller_location) -> Network_Error {
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

			nanos := time.duration_nanoseconds(t)
			timeval_value.nanoseconds = int(nanos % 1e9)
			timeval_value.seconds = (nanos - i64(timeval_value.nanoseconds)) / 1e9

			ptr = &timeval_value
			len = size_of(timeval_value)
	case
		.Receive_Buffer_Size,
		.Send_Buffer_Size:
			// TODO: check for out of range values and return .Value_Out_Of_Range?
			switch i in value {
			case   i8,   u8: i2 := i; int_value = os.socklen_t((^u8)(&i2)^)
			case  i16,  u16: i2 := i; int_value = os.socklen_t((^u16)(&i2)^)
			case  i32,  u32: i2 := i; int_value = os.socklen_t((^u32)(&i2)^)
			case  i64,  u64: i2 := i; int_value = os.socklen_t((^u64)(&i2)^)
			case i128, u128: i2 := i; int_value = os.socklen_t((^u128)(&i2)^)
			case  int, uint: i2 := i; int_value = os.socklen_t((^uint)(&i2)^)
			case:
				panic("set_option() value must be an integer here", loc)
			}
			ptr = &int_value
			len = size_of(int_value)
	}

	skt := any_socket_to_socket(s)
	res := os.setsockopt(Platform_Socket(skt), int(level), int(option), ptr, len)
	if res != os.ERROR_NONE {
		return Socket_Option_Error(res)
	}

	return nil
}

@(private)
_endpoint_to_sockaddr :: proc(ep: Endpoint) -> (sockaddr: os.SOCKADDR_STORAGE_LH) {
	switch a in ep.address {
	case IP4_Address:
		(^os.sockaddr_in)(&sockaddr)^ = os.sockaddr_in {
			sin_port = u16be(ep.port),
			sin_addr = transmute(os.in_addr) a,
			sin_family = u16(os.AF_INET),
		}
		return
	case IP6_Address:
		(^os.sockaddr_in6)(&sockaddr)^ = os.sockaddr_in6 {
			sin6_port = u16be(ep.port),
			sin6_addr = transmute(os.in6_addr) a,
			sin6_family = u16(os.AF_INET6),
		}
		return
	}
	unreachable()
}

@(private)
_sockaddr_storage_to_endpoint :: proc(native_addr: ^os.SOCKADDR_STORAGE_LH) -> (ep: Endpoint) {
	switch native_addr.ss_family {
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

@(private)
_sockaddr_basic_to_endpoint :: proc(native_addr: ^os.SOCKADDR) -> (ep: Endpoint) {
	switch native_addr.sa_family {
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