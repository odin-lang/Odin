package net

import "core:c"
import win "core:sys/windows"

import "core:fmt"


Socket :: distinct win.SOCKET

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
	Network_Subsystem_Failure = win.WSAENETDOWN,
	Family_Not_Supported_For_This_Socket = win.WSAEAFNOSUPPORT,
	No_Socket_Descriptors_Available = win.WSAEMFILE,
	No_Buffer_Space_Available = win.WSAENOBUFS,
	Protocol_Unsupported_By_System = win.WSAEPROTONOSUPPORT,
	Wrong_Protocol_For_Socket = win.WSAEPROTOTYPE,
	Family_And_Socket_Type_Mismatch = win.WSAESOCKTNOSUPPORT,
}

@(init, private)
ensure_winsock_initialized :: proc() {
	win.ensure_winsock_initialized()
}

create_socket :: proc(family: Address_Family, protocol: Socket_Protocol) -> (socket: Any_Socket, err: Network_Error) {
	c_type, c_protocol, c_family: c.int

	switch family {
	case .IPv4:  c_family = win.AF_INET
	case .IPv6:  c_family = win.AF_INET6
	case:
		unreachable()
	}

	switch protocol {
	case .Tcp:  c_type = win.SOCK_STREAM; c_protocol = win.IPPROTO_TCP
	case .Udp:  c_type = win.SOCK_DGRAM;  c_protocol = win.IPPROTO_UDP
	case:
		unreachable()
	}

	sock := win.socket(c_family, c_type, c_protocol)
	if sock == win.INVALID_SOCKET {
		err = Create_Socket_Error(win.WSAGetLastError())
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
	Address_In_Use = win.WSAEADDRINUSE,
	In_Progress = win.WSAEALREADY,
	Cannot_Use_Any_Address = win.WSAEADDRNOTAVAIL,
	Wrong_Family_For_Socket = win.WSAEAFNOSUPPORT,
	Refused = win.WSAECONNREFUSED,
	Is_Listening_Socket = win.WSAEINVAL,
	Already_Connected = win.WSAEISCONN,
	Network_Unreachable = win.WSAENETUNREACH, // Device is offline
	Host_Unreachable = win.WSAEHOSTUNREACH, // Remote host cannot be reached
	No_Buffer_Space_Available = win.WSAENOBUFS,
	Not_Socket = win.WSAENOTSOCK,
	Timeout = win.WSAETIMEDOUT,
	Would_Block = win.WSAEWOULDBLOCK, // TODO: we may need special handling for this; maybe make a socket a struct with metadata?
}

dial_tcp :: proc(addr: Address, port: int) -> (skt: Tcp_Socket, err: Network_Error) {
	family := family_from_address(addr)
	sock := create_socket(family, .Tcp) or_return
	skt = sock.(Tcp_Socket)

	// NOTE(tetra): This is so that if we crash while the socket is open, we can
	// bypass the cooldown period, and allow the next run of the program to
	// use the same address immediately.
	_ = set_option(skt, .Reuse_Address, true)

	sockaddr, addrsize := address_to_sockaddr(addr, port)
	res := win.connect(win.SOCKET(skt), (^win.SOCKADDR)(&sockaddr), addrsize)
	if res < 0 {
		err = Dial_Error(win.WSAGetLastError())
		return
	}

	return
}

Bind_Error :: enum c.int {
	// Another application is currently bound to this endpoint.
	Address_In_Use = win.WSAEADDRINUSE,
	// The address is not a local address on this machine.
	Given_Nonlocal_Address = win.WSAEADDRNOTAVAIL,
	// To bind a UDP socket to the broadcast address, the appropriate socket option must be set.
	Broadcast_Disabled = win.WSAEACCES,
	// The address family of the address does not match that of the socket.
	Address_Family_Mismatch = win.WSAEFAULT,
	// The socket is already bound to an address.
	Already_Bound = win.WSAEINVAL,
	// There are not enough ephemeral ports available.
	No_Ports_Available = win.WSAENOBUFS,
}

bind :: proc(skt: Any_Socket, ep: Endpoint) -> (err: Network_Error) {
	sockaddr, addrsize := address_to_sockaddr(ep.address, ep.port)
	s := any_socket_to_socket(skt)
	res := win.bind(win.SOCKET(s), (^win.SOCKADDR)(&sockaddr), addrsize)
	if res < 0 {
		err = Bind_Error(win.WSAGetLastError())
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
	Address_In_Use = win.WSAEADDRINUSE,
	Already_Connected = win.WSAEISCONN,
	No_Socket_Descriptors_Available = win.WSAEMFILE,
	No_Buffer_Space_Available = win.WSAENOBUFS,
	Nonlocal_Address = win.WSAEADDRNOTAVAIL,
	Not_Socket = win.WSAENOTSOCK,
	Listening_Not_Supported_For_This_Socket = win.WSAEOPNOTSUPP,
}

listen_tcp :: proc(local_addr: Address, port: int, backlog := 1000) -> (skt: Tcp_Socket, err: Network_Error) {
	assert(backlog > 0 && i32(backlog) < max(i32))

	family := family_from_address(local_addr)
	sock := create_socket(family, .Tcp) or_return
	skt = sock.(Tcp_Socket)

	// NOTE(tetra): While I'm not 100% clear on it, my understanding is that this will
	// prevent hijacking of the server's endpoint by other applications.
	set_option(skt, .Exclusive_Addr_Use, true) or_return

	bind(sock, {local_addr, port}) or_return

	res := win.listen(win.SOCKET(skt), i32(backlog))
	if res == win.SOCKET_ERROR {
		err = Listen_Error(win.WSAGetLastError())
		return
	}

	return
}



Accept_Error :: enum c.int {
	Reset = win.WSAECONNRESET,
	Not_Listening = win.WSAEINVAL,
	No_Socket_Descriptors_Available_For_Client_Socket = win.WSAEMFILE,
	No_Buffer_Space_Available = win.WSAENOBUFS,
	Not_Socket = win.WSAENOTSOCK,
	Not_Connection_Oriented_Socket = win.WSAEOPNOTSUPP,
	Would_Block = win.WSAEWOULDBLOCK, // TODO: we may need special handling for this; maybe make a socket a struct with metadata?
}

accept_tcp :: proc(sock: Tcp_Socket) -> (client: Tcp_Socket, source: Endpoint, err: Network_Error) {
	sockaddr: win.SOCKADDR_STORAGE_LH
	sockaddrlen := c.int(size_of(sockaddr))
	client_sock := win.accept(win.SOCKET(sock), cast(^win.SOCKADDR) &sockaddr, &sockaddrlen)
	if int(client_sock) == win.SOCKET_ERROR {
		err = Accept_Error(win.WSAGetLastError())
		return
	}
	client = Tcp_Socket(client_sock)
	source = sockaddr_to_endpoint(&sockaddr, sockaddrlen)
	return
}



close :: proc(skt: Any_Socket) {
	s := any_socket_to_socket(skt)
	win.closesocket(win.SOCKET(s))
}



Tcp_Recv_Error :: enum c.int {
	Network_Subsystem_Failure = win.WSAENETDOWN,
	Not_Connected = win.WSAENOTCONN,
	Bad_Buffer = win.WSAEFAULT,
	Keepalive_Failure = win.WSAENETRESET,
	Not_Socket = win.WSAENOTSOCK,
	Shutdown = win.WSAESHUTDOWN,
	Would_Block = win.WSAEWOULDBLOCK,
	Aborted = win.WSAECONNABORTED, // TODO: not functionally different from Reset; merge?
	Timeout = win.WSAETIMEDOUT,
	Reset = win.WSAECONNRESET, // Gracefully shutdown
	Host_Unreachable = win.WSAEHOSTUNREACH, // TODO: verify can actually happen
}

recv_tcp :: proc(skt: Tcp_Socket, buf: []byte) -> (bytes_read: int, err: Network_Error) {
	if len(buf) <= 0 {
		return
	}
	res := win.recv(win.SOCKET(skt), raw_data(buf), c.int(len(buf)), 0)
	if res < 0 {
		err = Tcp_Recv_Error(win.WSAGetLastError())
		return
	}
	return int(res), nil
}

Udp_Recv_Error :: enum c.int {
	Network_Subsystem_Failure = win.WSAENETDOWN,
	Aborted = win.WSAECONNABORTED, // TODO: not functionally different from Reset; merge?
	// UDP packets are limited in size, and the length of the incoming message exceeded it.
	Truncated = win.WSAEMSGSIZE,
	// The machine at the remote endpoint doesn't have the given port open to receiving UDP data.
	Remote_Not_Listening = win.WSAECONNRESET,
	Shutdown = win.WSAESHUTDOWN,
	// A broadcast address was specified, but the .Broadcast socket option isn't set.
	Broadcast_Disabled = win.WSAEACCES,
	Bad_Buffer = win.WSAEFAULT,
	No_Buffer_Space_Available = win.WSAENOBUFS,
	// The socket is not valid socket handle.
	Not_Socket = win.WSAENOTSOCK,
	Would_Block = win.WSAEWOULDBLOCK,
	// The remote host cannot be reached from this host at this time.
	Host_Unreachable = win.WSAEHOSTUNREACH,
	// The network cannot be reached from this host at this time.
	Offline = win.WSAENETUNREACH,
	Timeout = win.WSAETIMEDOUT,
	// The socket isn't bound; an unknown flag specified; or MSG_OOB specified with SO_OOBINLINE enabled.
	Incorrectly_Configured = win.WSAEINVAL, // TODO: can this actually happen?
	// The message took more hops than was allowed (the Time To Live) to reach the remote endpoint.
	TTL_Expired = win.WSAENETRESET,
}

recv_udp :: proc(skt: Udp_Socket, buf: []byte) -> (bytes_read: int, remote_endpoint: Endpoint, err: Network_Error) {
	if len(buf) <= 0 {
		return
	}

	from: win.SOCKADDR_STORAGE_LH
	fromsize := c.int(size_of(from))
	res := win.recvfrom(win.SOCKET(skt), raw_data(buf), c.int(len(buf)), 0, cast(^win.SOCKADDR) &from, &fromsize)
	if res < 0 {
		err = Udp_Recv_Error(win.WSAGetLastError())
		return
	}

	bytes_read = int(res)
	remote_endpoint = sockaddr_to_endpoint(&from, fromsize)
	return
}

recv :: proc{recv_tcp, recv_udp}


//
// TODO: consider merging some errors to make handling them easier
// TODO: verify once more what errors to actually expose
//

Tcp_Send_Error :: enum c.int {
	Aborted = win.WSAECONNABORTED, // TODO: not functionally different from Reset; merge?
	Not_Connected = win.WSAENOTCONN,
	Shutdown = win.WSAESHUTDOWN,
	Reset = win.WSAECONNRESET,
	No_Buffer_Space_Available = win.WSAENOBUFS,
	Network_Subsystem_Failure = win.WSAENETDOWN,
	Host_Unreachable = win.WSAEHOSTUNREACH,
	Offline = win.WSAENETUNREACH, // TODO: verify possible, as not mentioned in docs
	Timeout = win.WSAETIMEDOUT,
	// A broadcast address was specified, but the .Broadcast socket option isn't set.
	Broadcast_Disabled = win.WSAEACCES,
	Bad_Buffer = win.WSAEFAULT,
	// Connection is broken due to keepalive activity detecting a failure during the operation.
	Keepalive_Failure = win.WSAENETRESET, // TODO: not functionally different from Reset; merge?
}

// Repeatedly sends data until the entire buffer is sent.
// If a send fails before all data is sent, returns the amount
// sent up to that point.
send_tcp :: proc(skt: Tcp_Socket, buf: []byte) -> (bytes_written: int, err: Network_Error) {
	for bytes_written < len(buf) {
		limit := min(1<<31, len(buf) - bytes_written)
		remaining := buf[bytes_written:]
		res := win.send(win.SOCKET(skt), raw_data(remaining), c.int(limit), 0)
		if res < 0 {
			err = Tcp_Send_Error(win.WSAGetLastError())
			return
		}
		bytes_written += int(res)
	}
	return
}

Udp_Send_Error :: enum c.int {
	Network_Subsystem_Failure = win.WSAENETDOWN,
	Aborted = win.WSAECONNABORTED, // TODO: not functionally different from Reset; merge?
	// UDP packets are limited in size, and len(buf) exceeded it.
	Message_Too_Long = win.WSAEMSGSIZE,
	// The machine at the remote endpoint doesn't have the given port open to receiving UDP data.
	Remote_Not_Listening = win.WSAECONNRESET,
	Shutdown = win.WSAESHUTDOWN,
	// A broadcast address was specified, but the .Broadcast socket option isn't set.
	Broadcast_Disabled = win.WSAEACCES,
	Bad_Buffer = win.WSAEFAULT,
	// Connection is broken due to keepalive activity detecting a failure during the operation.
	Keepalive_Failure = win.WSAENETRESET, // TODO: not functionally different from Reset; merge?
	No_Buffer_Space_Available = win.WSAENOBUFS,
	// The socket is not valid socket handle.
	Not_Socket = win.WSAENOTSOCK,
	// This socket is unidirectional and cannot be used to send any data.
	// TODO: verify possible; decide whether to keep if not
	Receive_Only = win.WSAEOPNOTSUPP,
	Would_Block = win.WSAEWOULDBLOCK,
	// The remote host cannot be reached from this host at this time.
	Host_Unreachable = win.WSAEHOSTUNREACH,
	// Attempt to send to the Any address.
	Cannot_Use_Any_Address = win.WSAEADDRNOTAVAIL,
	// The address is of an incorrect address family for this socket.
	Family_Not_Supported_For_This_Socket = win.WSAEAFNOSUPPORT,
	// The network cannot be reached from this host at this time.
	Offline = win.WSAENETUNREACH,
	Timeout = win.WSAETIMEDOUT,
}

send_udp :: proc(skt: Udp_Socket, buf: []byte, to: Endpoint) -> (bytes_written: int, err: Network_Error) {
	toaddr, toaddrsize := address_to_sockaddr(to.address, to.port)
	for bytes_written < len(buf) {
		limit := min(1<<31, len(buf) - bytes_written)
		remaining := buf[bytes_written:]
		res := win.sendto(win.SOCKET(skt), raw_data(remaining), c.int(limit), 0, cast(^win.SOCKADDR) &toaddr, toaddrsize)
		if res < 0 {
			err = Udp_Send_Error(win.WSAGetLastError())
			return
		}
		bytes_written += int(res)
	}
	return
}

send :: proc{send_tcp, send_udp}




Shutdown_Manner :: enum c.int {
	Receive = win.SD_RECEIVE,
	Send = win.SD_SEND,
	Both = win.SD_BOTH,
}

Shutdown_Error :: enum c.int {
	Aborted = win.WSAECONNABORTED,
	Reset = win.WSAECONNRESET,
	Offline = win.WSAENETDOWN,
	Not_Connected = win.WSAENOTCONN,
	Not_Socket = win.WSAENOTSOCK,
	Invalid_Manner = win.WSAEINVAL,
}

shutdown :: proc(skt: Any_Socket, manner: Shutdown_Manner) -> (err: Network_Error) {
	s := any_socket_to_socket(skt)
	res := win.shutdown(win.SOCKET(s), c.int(manner))
	if res < 0 {
		return Shutdown_Error(win.WSAGetLastError())
	}
	return
}




Socket_Option :: enum c.int {
	// bool: Whether the address that this socket is bound to can be reused by other sockets.
	//       This allows you to bypass the cooldown period if a program dies while the socket is bound.
	Reuse_Address = win.SO_REUSEADDR,
	// bool: Whether other programs will be inhibited from binding the same endpoint as this socket.
	Exclusive_Addr_Use = win.SO_EXCLUSIVEADDRUSE,
	// bool: When true, keepalive packets will be automatically be sent for this connection.
	// TODO: verify this understanding
	Keep_Alive = win.SO_KEEPALIVE,
	// bool: When true, client connections will immediately be sent a TCP/IP RST response, rather than
	//       being accepted.
	Conditional_Accept = win.SO_CONDITIONAL_ACCEPT,
	// bool: If true, when the socket is closed, but data is still waiting to be sent, discard that data.
	Dont_Linger = win.SO_DONTLINGER,
	// bool: When true, 'out-of-band' data sent over the socket will be read by a normal net.recv() call,
	//       the same as normal 'in-band' data.
	Out_Of_Bounds_Data_Inline = win.SO_OOBINLINE,
	// bool: When true, disables send-coalescing, therefore reducing latency.
	Tcp_Nodelay = win.TCP_NODELAY,
	// win.LINGER: Customizes how long (if at all) the socket will remain open when there is some remaining data
	//             waiting to be sent, and net.close() is called.
	Linger = win.SO_LINGER,
	// win.DWORD: The size, in bytes, of the OS-managed receive-buffer for this socket.
	Receive_Buffer_Size = win.SO_RCVBUF,
	// win.DWORD: The size, in bytes, of the OS-managed send-buffer for this socket.
	Send_Buffer_Size = win.SO_SNDBUF,
	// win.DWORD: For blocking sockets, the time in milliseconds to wait for incoming data to be received, before giving up and returning .Timeout.
	//            For non-blocking sockets, ignored.
	//            Use a value of zero to potentially wait forever.
	Receive_Timeout = win.SO_RCVTIMEO,
	// win.DWORD: For blocking sockets, the time in milliseconds to wait for outgoing data to be sent, before giving up and returning .Timeout.
	//            For non-blocking sockets, ignored.
	//            Use a value of zero to potentially wait forever.
	Send_Timeout = win.SO_SNDTIMEO,
	// bool: Allow sending to, receiving from, and binding to, a broadcast address.
	Broadcast = win.SO_BROADCAST,
}

Socket_Option_Error :: enum c.int {
	// The value is not of the correct type for the given socket option.
	Incorrect_Value_Type,
	// The given socket option is unrecognised.
	Unknown_Option,

	Network_Subsystem_Failure = win.WSAENETDOWN,
	Timeout_When_Keepalive_Set = win.WSAENETRESET,
	Invalid_Option_For_Socket = win.WSAENOPROTOOPT,
	Reset_When_Keepalive_Set = win.WSAENOTCONN,
	Not_Socket = win.WSAENOTSOCK,
}

set_option :: proc(s: Any_Socket, option: Socket_Option, value: any) -> Network_Error {
	level := win.SOL_SOCKET if option != .Tcp_Nodelay else win.IPPROTO_TCP

	switch option {
	case
		.Reuse_Address,
		.Exclusive_Addr_Use,
		.Keep_Alive,
		.Conditional_Accept,
		.Dont_Linger,
		.Out_Of_Bounds_Data_Inline,
		.Tcp_Nodelay,
		.Broadcast:
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
			case int:
				// okay
			case:
				return .Incorrect_Value_Type
			}
	case .Linger:
		switch in value {
		case win.LINGER:
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
	res := win.setsockopt(win.SOCKET(skt), c.int(level), c.int(option), ptr, len)
	if res < 0 {
		return Socket_Option_Error(win.WSAGetLastError())
	}

	return nil
}