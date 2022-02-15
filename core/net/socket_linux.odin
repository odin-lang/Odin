package net

import "core:c"
import "core:os"

import "core:fmt"


Socket :: distinct os.Socket

General_Error :: enum {
}

Network_Error :: union {
	General_Error,
	Create_Socket_Error,
	Dial_Error,
	Listen_Error,
	Accept_Error,
	Bind_Error,
	Tcp_Send_Error,
	Udp_Send_Error,
	Tcp_Recv_Error,
	Udp_Recv_Error,
	Shutdown_Error,
	Socket_Option_Error,
}


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
	case .Tcp:  c_type = os.SOCK_STREAM; c_protocol = os.IPPROTO_TCP
	case .Udp:  c_type = os.SOCK_DGRAM;  c_protocol = os.IPPROTO_UDP
	case:
		unreachable()
	}

	sock, ok := os.socket(c_family, c_type, c_protocol)
	if ok != os.ERROR_NONE {
		err = Create_Socket_Error(ok)
		return
	}

	switch protocol {
	case .Tcp:  return Tcp_Socket(sock), nil
	case .Udp:  return Udp_Socket(sock), nil
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

dial_tcp :: proc(addr: Address, port: int) -> (skt: Tcp_Socket, err: Network_Error) {
	family := family_from_address(addr)
	sock := create_socket(family, .Tcp) or_return
	skt = sock.(Tcp_Socket)

	// NOTE(tetra): This is so that if we crash while the socket is open, we can
	// bypass the cooldown period, and allow the next run of the program to
	// use the same address immediately.
	_ = set_option(skt, .Reuse_Address, true)

	sockaddr := endpoint_to_sockaddr({addr, port})
	res := os.connect(os.Socket(skt), (^os.SOCKADDR)(&sockaddr), size_of(sockaddr))
	if res != os.ERROR_NONE {
		err = Dial_Error(res)
		return
	}

	return
}


Bind_Error :: enum c.int {
	// Another application is currently bound to this endpoint.
	Address_In_Use = c.int(os.EADDRINUSE),
	// The address is not a local address on this machine.
	Given_Nonlocal_Address = c.int(os.EADDRNOTAVAIL),
	// To bind a UDP socket to the broadcast address, the appropriate socket option must be set.
	Broadcast_Disabled = c.int(os.EACCES),
	// The address family of the address does not match that of the socket.
	Address_Family_Mismatch = c.int(os.EFAULT),
	// The socket is already bound to an address.
	Already_Bound = c.int(os.EINVAL),
	// There are not enough ephemeral ports available.
	No_Ports_Available = c.int(os.ENOBUFS),
}

bind :: proc(skt: Any_Socket, ep: Endpoint) -> (err: Network_Error) {
	sockaddr := endpoint_to_sockaddr(ep)
	s := any_socket_to_socket(skt)
	res := os.bind(os.Socket(s), (^os.SOCKADDR)(&sockaddr), size_of(sockaddr))
	if res != os.ERROR_NONE {
		err = Bind_Error(res)
	}
	return
}


// This type of socket becomes bound when you try to send data.
// This is likely what you want if you want to send data unsolicited.
//
// This is like a client TCP socket, except that it can send data to any remote endpoint without needing to establish a connection first.
make_unbound_udp_socket :: proc(family: Address_Family) -> (skt: Udp_Socket, err: Network_Error) {
	sock := create_socket(family, .Udp) or_return
	skt = sock.(Udp_Socket)
	return
}

// This type of socket is bound immediately, which enables it to receive data on the port.
// Since it's UDP, it's also able to send data without receiving any first.
//
// This is like a listening TCP socket, except that data packets can be sent and received without needing to establish a connection first.
//
// The bound_address is the address of the network interface that you want to use, or a loopback address if you don't care which to use.
make_bound_udp_socket :: proc(bound_address: Address, port: int) -> (skt: Udp_Socket, err: Network_Error) {
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

listen_tcp :: proc(local_addr: Address, port: int, backlog := 1000) -> (skt: Tcp_Socket, err: Network_Error) {
	assert(backlog > 0 && i32(backlog) < max(i32))

	family := family_from_address(local_addr)
	sock := create_socket(family, .Tcp) or_return
	skt = sock.(Tcp_Socket)

	bind(sock, {local_addr, port}) or_return

	res := os.listen(os.Socket(skt), backlog)
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

accept_tcp :: proc(sock: Tcp_Socket) -> (client: Tcp_Socket, source: Endpoint, err: Network_Error) {
	sockaddr: os.SOCKADDR_STORAGE_LH
	sockaddrlen := c.int(size_of(sockaddr))

	client_sock, ok := os.accept(os.Socket(sock), cast(^os.SOCKADDR) &sockaddr, &sockaddrlen)
	if ok != os.ERROR_NONE {
		err = Accept_Error(ok)
		return
	}
	client = Tcp_Socket(client_sock)
	source = sockaddr_to_endpoint(&sockaddr)
	return
}



close :: proc(skt: Any_Socket) {
	s := any_socket_to_socket(skt)
	os.close(os.Handle(os.Socket(s)))
}



Tcp_Recv_Error :: enum c.int {
	Shutdown = c.int(os.ESHUTDOWN),
	Not_Connected = c.int(os.ENOTCONN),
	Connection_Broken = c.int(os.ENETRESET),
	Not_Socket = c.int(os.ENOTSOCK),
	Aborted = c.int(os.ECONNABORTED),
	Reset = c.int(os.ECONNRESET), // Gracefully shutdown
	Offline = c.int(os.ENETDOWN),
	Host_Unreachable = c.int(os.EHOSTUNREACH),
	Interrupted = c.int(os.EINTR),
	Timeout = c.int(os.ETIMEDOUT),
}

recv_tcp :: proc(skt: Tcp_Socket, buf: []byte) -> (bytes_read: int, err: Network_Error) {
	if len(buf) <= 0 {
		return
	}
	res, ok := os.recv(os.Socket(skt), buf, 0)
	if ok != os.ERROR_NONE {
		err = Tcp_Recv_Error(ok)
		return
	}
	return int(res), nil
}

Udp_Recv_Error :: enum c.int {
	Truncated = c.int(os.EMSGSIZE),
	Reset = c.int(os.ECONNRESET),
	Not_Socket = c.int(os.ENOTSOCK),
	Socket_Not_Bound = c.int(os.EINVAL), // .. or unknown flag specified; or MSG_OOB specified with SO_OOBINLINE enabled
}

recv_udp :: proc(skt: Udp_Socket, buf: []byte) -> (bytes_read: int, remote_endpoint: Endpoint, err: Network_Error) {
	if len(buf) <= 0 {
		return
	}

	from: os.SOCKADDR_STORAGE_LH
	fromsize := c.int(size_of(from))
	res, ok := os.recvfrom(os.Socket(skt), buf, 0, cast(^os.SOCKADDR) &from, &fromsize)
	if ok != os.ERROR_NONE {
		err = Udp_Recv_Error(ok)
		return
	}

	bytes_read = int(res)
	remote_endpoint = sockaddr_to_endpoint(&from)
	return
}

recv :: proc{recv_tcp, recv_udp}



Tcp_Send_Error :: enum c.int {
	Aborted = c.int(os.ECONNABORTED),
	Not_Connected = c.int(os.ENOTCONN),
	Shutdown = c.int(os.ESHUTDOWN),
	Reset = c.int(os.ECONNRESET),
	No_Buffer_Space_Available = c.int(os.ENOBUFS),
	Offline = c.int(os.ENETDOWN),
	Host_Unreachable = c.int(os.EHOSTUNREACH),
	Interrupted = c.int(os.EINTR),
	Timeout = c.int(os.ETIMEDOUT),
}

// Repeatedly sends data until the entire buffer is sent.
// If a send fails before all data is sent, returns the amount
// sent up to that point.
send_tcp :: proc(skt: Tcp_Socket, buf: []byte) -> (bytes_written: int, err: Network_Error) {
	for bytes_written < len(buf) {
		limit := min(1<<31, len(buf) - bytes_written)
		remaining := buf[bytes_written:][:limit]
		res, ok := os.send(os.Socket(skt), remaining, 0)
		if ok != os.ERROR_NONE {
			err = Tcp_Send_Error(ok)
			return
		}
		bytes_written += int(res)
	}
	return
}

Udp_Send_Error :: enum c.int {
	Truncated = c.int(os.EMSGSIZE),
}

send_udp :: proc(skt: Udp_Socket, buf: []byte, to: Endpoint) -> (bytes_written: int, err: Network_Error) {
	toaddr := endpoint_to_sockaddr(to)
	for bytes_written < len(buf) {
		limit := min(1<<31, len(buf) - bytes_written)
		remaining := buf[bytes_written:][:limit]
		res, ok := os.sendto(os.Socket(skt), remaining, 0, cast(^os.SOCKADDR) &toaddr, size_of(toaddr))
		if ok != os.ERROR_NONE {
			err = Udp_Send_Error(ok)
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
	res := os.shutdown(os.Socket(s), int(manner))
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
	Receive_Timeout = c.int(os.SO_RCVTIMEO_NEW),
	Send_Timeout = c.int(os.SO_SNDTIMEO_NEW),
}

Socket_Option_Error :: enum c.int {
	Incorrect_Value_Type,
	Unknown_Option,

	Offline = c.int(os.ENETDOWN),
	Timeout_When_Keepalive_Set = c.int(os.ENETRESET),
	Invalid_Option_For_Socket = c.int(os.ENOPROTOOPT),
	Reset_When_Keepalive_Set = c.int(os.ENOTCONN),
	Not_Socket = c.int(os.ENOTSOCK),
}

// Socket must be bound.
set_option :: proc(s: Any_Socket, option: Socket_Option, value: any) -> Network_Error {
	level := os.SOL_SOCKET if option != .Tcp_Nodelay else os.IPPROTO_TCP

	switch option {
	case
		.Reuse_Address,
		.Keep_Alive,
		.Out_Of_Bounds_Data_Inline,
		.Tcp_Nodelay:
			switch in value {
			case bool:
				// okay
			case:
				return .Incorrect_Value_Type
			}
	case
		.Receive_Buffer_Size,
		.Send_Buffer_Size,
		.Receive_Timeout,
		.Send_Timeout:
			switch in value {
			case os.Timeval:
				// okay
			case:
				return .Incorrect_Value_Type
			}
	case .Linger:
		switch in value {
		case os.Linger:
			// okay
		case:
			return .Incorrect_Value_Type
		}
	case:
		return .Unknown_Option
	}


	ptr := value.data
	len := c.int(type_info_of(value.id).size)

	skt := any_socket_to_socket(s)
	res := os.setsockopt(os.Socket(skt), int(level), int(option), ptr, len)
	if res != os.ERROR_NONE {
		return Socket_Option_Error(res)
	}

	return nil
}