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

/*
	Package net implements cross-platform Berkeley Sockets, DNS resolution and associated procedures.
	For other protocols and their features, see subdirectories of this package.
*/
package net

import "core:c"
import "core:os"
import "core:time"

import "core:fmt"


Socket :: os.Socket

Create_Socket_Error :: enum c.int {
	Family_Not_Supported_For_This_Socket = c.int(os.EAFNOSUPPORT),
	No_Socket_Descriptors_Available = c.int(os.EMFILE),
	No_Buffer_Space_Available = c.int(os.ENOBUFS),
	No_Memory_Available_Available = c.int(os.ENOMEM),
	Protocol_Unsupported_By_System = c.int(os.EPROTONOSUPPORT),
	Wrong_Protocol_For_Socket = c.int(os.EPROTONOSUPPORT),
	Family_And_Socket_Type_Mismatch = c.int(os.EPROTONOSUPPORT),
}

create_socket :: proc(family: Address_Family, protocol: Socket_Protocol) -> (socket: Any_Socket, err: Network_Error) {
	c_type, c_protocol, c_family: int

	switch family {
	case .IPv4:  c_family = os.AF_INET
	case .IPv6:  c_family = os.AF_INET6
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


Dial_Error :: enum c.int {
	Address_In_Use = c.int(os.EADDRINUSE),
	In_Progress = c.int(os.EINPROGRESS),
	Cannot_Use_Any_Address = c.int(os.EADDRNOTAVAIL),
	Wrong_Family_For_Socket = c.int(os.EAFNOSUPPORT),
	Refused = c.int(os.ECONNREFUSED),
	Is_Listening_Socket = c.int(os.EACCES),
	Already_Connected = c.int(os.EISCONN),
	Network_Unreachable = c.int(os.ENETUNREACH), // Device is offline
	Host_Unreachable = c.int(os.EHOSTUNREACH), // Remote host cannot be reached
	No_Buffer_Space_Available = c.int(os.ENOBUFS),
	Not_Socket = c.int(os.ENOTSOCK),
	Timeout = c.int(os.ETIMEDOUT),
	Would_Block = c.int(os.EWOULDBLOCK), // TODO: we may need special handling for this; maybe make a socket a struct with metadata?
}

dial_tcp :: proc(addr: Address, port: int) -> (skt: TCP_Socket, err: Network_Error) {
	family := family_from_address(addr)
	sock := create_socket(family, .TCP) or_return
	skt = sock.(TCP_Socket)

	// NOTE(tetra): This is so that if we crash while the socket is open, we can
	// bypass the cooldown period, and allow the next run of the program to
	// use the same Address immediately.
	_ = set_option(skt, .Reuse_Address, true)

	sockaddr := endpoint_to_sockaddr({addr, port})
	res := os.connect(Platform_Socket(skt), (^os.SOCKADDR)(&sockaddr), i32(sockaddr.len))
	if res != os.ERROR_NONE {
		err = Dial_Error(res)
		return
	}

	return
}


Bind_Error :: enum c.int {
	// Another application is currently bound to this endpoint.
	Address_In_Use = c.int(os.EADDRINUSE),
	// The Address is not a local Address on this machine.
	Given_Nonlocal_Address = c.int(os.EADDRNOTAVAIL),
	// To bind a UDP socket to the broadcast Address, the appropriate socket option must be set.
	Broadcast_Disabled = c.int(os.EACCES),
	// The Address family of the Address does not match that of the socket.
	Address_Family_Mismatch = c.int(os.EFAULT),
	// The socket is already bound to an Address.
	Already_Bound = c.int(os.EINVAL),
	// There are not enough ephemeral ports available.
	No_Ports_Available = c.int(os.ENOBUFS),
}

bind :: proc(skt: Any_Socket, ep: Endpoint) -> (err: Network_Error) {
	sockaddr := endpoint_to_sockaddr(ep)
	s := any_socket_to_socket(skt)
	res := os.bind(Platform_Socket(s), (^os.SOCKADDR)(&sockaddr), i32(sockaddr.len))
	if res != os.ERROR_NONE {
		err = Bind_Error(res)
	}
	return
}


// This type of socket becomes bound when you try to send data.
// This is likely what you want if you want to send data unsolicited.
//
// This is like a client TCP socket, except that it can send data to any remote endpoint without needing to establish a connection first.
make_unbound_udp_socket :: proc(family: Address_Family) -> (skt: UDP_Socket, err: Network_Error) {
	sock := create_socket(family, .UDP) or_return
	skt = sock.(UDP_Socket)
	return
}

// This type of socket is bound immediately, which enables it to receive data on the port.
// Since it's UDP, it's also able to send data without receiving any first.
//
// This is like a listening TCP socket, except that data packets can be sent and received without needing to establish a connection first.
//
// The bound_address is the Address of the network interface that you want to use, or a loopback Address if you don't care which to use.
make_bound_udp_socket :: proc(bound_address: Address, port: int) -> (skt: UDP_Socket, err: Network_Error) {
	skt = make_unbound_udp_socket(family_from_address(bound_address)) or_return
	bind(skt, {bound_address, port}) or_return
	return
}



Listen_Error :: enum c.int {
	Address_In_Use = c.int(os.EADDRINUSE),
	Already_Connected = c.int(os.EISCONN),
	No_Socket_Descriptors_Available = c.int(os.EMFILE),
	No_Buffer_Space_Available = c.int(os.ENOBUFS),
	Nonlocal_Address = c.int(os.EADDRNOTAVAIL),
	Not_Socket = c.int(os.ENOTSOCK),
	Listening_Not_Supported_For_This_Socket = c.int(os.EOPNOTSUPP),
}

listen_tcp :: proc(local_addr: Address, port: int, backlog := 1000) -> (skt: TCP_Socket, err: Network_Error) {
	assert(backlog > 0 && i32(backlog) < max(i32))

	family := family_from_address(local_addr)
	sock := create_socket(family, .TCP) or_return
	skt = sock.(TCP_Socket)

	// NOTE(tetra): This is so that if we crash while the socket is open, we can
	// bypass the cooldown period, and allow the next run of the program to
	// use the same Address immediately.
	//
	// TODO(tetra, 2022-02-15): Confirm that this doesn't mean other processes can hijack the Address!
	set_option(sock, .Reuse_Address, true) or_return

	bind(sock, {local_addr, port}) or_return

	res := os.listen(Platform_Socket(skt), backlog)
	if res != os.ERROR_NONE {
		err = Listen_Error(res)
		return
	}

	return
}



Accept_Error :: enum c.int {
	Reset = c.int(os.ECONNRESET),
	Not_Listening = c.int(os.EINVAL),
	No_Socket_Descriptors_Available_For_Client_Socket = c.int(os.EMFILE),
	No_Buffer_Space_Available = c.int(os.ENOBUFS),
	Not_Socket = c.int(os.ENOTSOCK),
	Not_Connection_Oriented_Socket = c.int(os.EOPNOTSUPP),
	Would_Block = c.int(os.EWOULDBLOCK), // TODO: we may need special handling for this; maybe make a socket a struct with metadata?
}

accept_tcp :: proc(sock: TCP_Socket) -> (client: TCP_Socket, source: Endpoint, err: Network_Error) {
	sockaddr: os.SOCKADDR_STORAGE_LH
	sockaddrlen := c.int(size_of(sockaddr))

	client_sock, ok := os.accept(Platform_Socket(sock), cast(^os.SOCKADDR) &sockaddr, &sockaddrlen)
	if ok != os.ERROR_NONE {
		err = Accept_Error(ok)
		return
	}
	client = TCP_Socket(client_sock)
	source = sockaddr_to_endpoint(&sockaddr)
	return
}



close :: proc(skt: Any_Socket) {
	s := any_socket_to_socket(skt)
	os.close(os.Handle(Platform_Socket(s)))
}



TCP_Recv_Error :: enum c.int {
	Shutdown = c.int(os.ESHUTDOWN),
	Not_Connected = c.int(os.ENOTCONN),
	Connection_Broken = c.int(os.ENETRESET),
	Not_Socket = c.int(os.ENOTSOCK),
	Aborted = c.int(os.ECONNABORTED),
	Reset = c.int(os.ECONNRESET), // Gracefully shutdown
	Offline = c.int(os.ENETDOWN),
	Host_Unreachable = c.int(os.EHOSTUNREACH),
	Interrupted = c.int(os.EINTR),
	Timeout = c.int(os.EWOULDBLOCK), // NOTE: No, really. Presumably this means something different for nonblocking sockets...
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

UDP_Recv_Error :: enum c.int {
	// The buffer is too small to fit the entire message, and the message was truncated.
	Truncated = c.int(os.EMSGSIZE),
	// The so-called socket is not an open socket.
	Not_Socket = c.int(os.ENOTSOCK),
	// The so-called socket is, in fact, not even a valid descriptor.
	Not_Descriptor = c.int(os.EBADF),
	// The buffer did not point to a valid location in memory.
	Bad_Buffer = c.int(os.EFAULT),
	// A signal occurred before any data was transmitted.
	// See signal(7).
	Interrupted = c.int(os.EINTR),
	// The send timeout duration passed before all data was sent.
	// See Socket_Option.Send_Timeout.
	Timeout = c.int(os.EWOULDBLOCK), // NOTE: No, really. Presumably this means something different for nonblocking sockets...
	// The socket must be bound for this operation, but isn't.
	Socket_Not_Bound = c.int(os.EINVAL),
}

recv_udp :: proc(skt: UDP_Socket, buf: []byte) -> (bytes_read: int, remote_endpoint: Endpoint, err: Network_Error) {
	if len(buf) <= 0 {
		return
	}

	from: os.SOCKADDR_STORAGE_LH
	fromsize := c.int(size_of(from))
	res, ok := os.recvfrom(Platform_Socket(skt), buf, 0, cast(^os.SOCKADDR) &from, &fromsize)
	if ok != os.ERROR_NONE {
		err = UDP_Recv_Error(ok)
		return
	}

	bytes_read = int(res)
	remote_endpoint = sockaddr_to_endpoint(&from)
	return
}

recv :: proc{recv_tcp, recv_udp}



// TODO
TCP_Send_Error :: enum c.int {
	Aborted = c.int(os.ECONNABORTED), // TODO: merge with Connection_Broken?
	Connection_Broken = c.int(os.ECONNRESET),
	Not_Connected = c.int(os.ENOTCONN),
	Shutdown = c.int(os.ESHUTDOWN),
	// The send queue was full.
	// This is usually a transient issue.
	//
	// This also shouldn't normally happen on Linux, as data is dropped if it
	// doesn't fit in the send queue.
	No_Buffer_Space_Available = c.int(os.ENOBUFS),
	Offline = c.int(os.ENETDOWN),
	Host_Unreachable = c.int(os.EHOSTUNREACH),
	// A signal occurred before any data was transmitted.
	// See signal(7).
	Interrupted = c.int(os.EINTR),
	// The send timeout duration passed before all data was sent.
	// See Socket_Option.Send_Timeout.
	Timeout = c.int(os.EWOULDBLOCK), // NOTE: No, really. Presumably this means something different for nonblocking sockets...
}

// Repeatedly sends data until the entire buffer is sent.
// If a send fails before all data is sent, returns the amount
// sent up to that point.
send_tcp :: proc(skt: TCP_Socket, buf: []byte) -> (bytes_written: int, err: Network_Error) {
	for bytes_written < len(buf) {
		limit := min(1<<31, len(buf) - bytes_written)
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

// TODO
UDP_Send_Error :: enum c.int {
	// The message is too big. No data was sent.
	Truncated = c.int(os.EMSGSIZE),
	// TODO: not sure what the exact circumstances for this is yet
	Network_Unreachable = c.int(os.ENETUNREACH),
	// There are no more emphemeral outbound ports available to bind the socket to, in order to send.
	No_Outbound_Ports_Available = c.int(os.EAGAIN),
	// The send timeout duration passed before all data was sent.
	// See Socket_Option.Send_Timeout.
	Timeout = c.int(os.EWOULDBLOCK), // NOTE: No, really. Presumably this means something different for nonblocking sockets...
	// The so-called socket is not an open socket.
	Not_Socket = c.int(os.ENOTSOCK),
	// The so-called socket is, in fact, not even a valid descriptor.
	Not_Descriptor = c.int(os.EBADF),
	// The buffer did not point to a valid location in memory.
	Bad_Buffer = c.int(os.EFAULT),
	// A signal occurred before any data was transmitted.
	// See signal(7).
	Interrupted = c.int(os.EINTR),
	// The send queue was full.
	// This is usually a transient issue.
	//
	// This also shouldn't normally happen on Linux, as data is dropped if it
	// doesn't fit in the send queue.
	No_Buffer_Space_Available = c.int(os.ENOBUFS),
	// No memory was available to properly manage the send queue.
	No_Memory_Available = c.int(os.ENOMEM),
}

send_udp :: proc(skt: UDP_Socket, buf: []byte, to: Endpoint) -> (bytes_written: int, err: Network_Error) {
	toaddr := endpoint_to_sockaddr(to)
	for bytes_written < len(buf) {
		limit := min(1<<31, len(buf) - bytes_written)
		remaining := buf[bytes_written:][:limit]
		res, ok := os.sendto(Platform_Socket(skt), remaining, 0, cast(^os.SOCKADDR)&toaddr, i32(toaddr.len))
		if ok != os.ERROR_NONE {
			err = UDP_Send_Error(ok)
			return
		}
		bytes_written += int(res)
	}
	return
}

send :: proc{send_tcp, send_udp}




Shutdown_Manner :: enum c.int {
	Receive = c.int(os.SHUT_RD),
	Send = c.int(os.SHUT_WR),
	Both = c.int(os.SHUT_RDWR),
}

Shutdown_Error :: enum c.int {
	Aborted = c.int(os.ECONNABORTED),
	Reset = c.int(os.ECONNRESET),
	Offline = c.int(os.ENETDOWN),
	Not_Connected = c.int(os.ENOTCONN),
	Not_Socket = c.int(os.ENOTSOCK),
	Invalid_Manner = c.int(os.EINVAL),
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
	Reuse_Address = c.int(os.SO_REUSEADDR),
	Keep_Alive = c.int(os.SO_KEEPALIVE),
	Out_Of_Bounds_Data_Inline = c.int(os.SO_OOBINLINE),
	Tcp_Nodelay = c.int(os.TCP_NODELAY),

	Linger = c.int(os.SO_LINGER),

	Receive_Buffer_Size = c.int(os.SO_RCVBUF),
	Send_Buffer_Size = c.int(os.SO_SNDBUF),
	Receive_Timeout = c.int(os.SO_RCVTIMEO),
	Send_Timeout = c.int(os.SO_SNDTIMEO),
}

Socket_Option_Error :: enum c.int {
	Offline = c.int(os.ENETDOWN),
	Timeout_When_Keepalive_Set = c.int(os.ENETRESET),
	Invalid_Option_For_Socket = c.int(os.ENOPROTOOPT),
	Reset_When_Keepalive_Set = c.int(os.ENOTCONN),
	Not_Socket = c.int(os.ENOTSOCK),
}

set_option :: proc(s: Any_Socket, option: Socket_Option, value: any, loc := #caller_location) -> Network_Error {
	level := os.SOL_SOCKET if option != .Tcp_Nodelay else os.IPPROTO_TCP

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
		.Tcp_Nodelay:
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
	res := os.setsockopt(Platform_Socket(skt), int(level), int(option), ptr, len)
	if res != os.ERROR_NONE {
		return Socket_Option_Error(res)
	}

	return nil
}
