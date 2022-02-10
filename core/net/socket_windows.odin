package net

import "core:c"
import win "core:sys/windows"

import "core:fmt"


Socket :: distinct win.SOCKET

Socket_IP_Family :: enum c.int {
	V4 = win.AF_INET,
	V6 = win.AF_INET6,
}



Create_Socket_Error :: enum c.int {
	Offline = win.WSAENETDOWN,
	Family_Not_Supported_For_This_Socket = win.WSAEAFNOSUPPORT,
	No_Socket_Descriptors_Available = win.WSAEMFILE,
	No_Buffer_Space_Available = win.WSAENOBUFS,
	Protocol_Unsupported_By_System = win.WSAEPROTONOSUPPORT,
	Wrong_Protocol_For_Socket = win.WSAEPROTOTYPE,
	Family_And_Socket_Type_Mismatch = win.WSAESOCKTNOSUPPORT,
}

create_socket :: proc(family: Socket_IP_Family, protocol: Socket_Protocol) -> (socket: Any_Socket, err: Create_Socket_Error) {
	win.ensure_winsock_initialized()

	c_type, c_protocol, c_family: c.int

	switch family {
	case .V4:  c_family = win.AF_INET
	case .V6:  c_family = win.AF_INET6
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



Dial_Error :: union {
	Specific_Dial_Error,
	Create_Socket_Error,
}

Specific_Dial_Error :: enum c.int {
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

dial_tcp :: proc(addr: Address, port: int) -> (skt: Tcp_Socket, err: Dial_Error) {
	family := family_from_address(addr)
	sock := create_socket(family, .Tcp) or_return
	skt = sock.(Tcp_Socket)

	// NOTE(tetra): This is so that if we crash while the socket is open, we can
	// bypass the cooldown period, and allow the next run of the program to
	// use the same address, for the same socket immediately.
	_ = set_option(skt, .Reuse_Address, true)

	sockaddr, addrsize := address_to_sockaddr(addr, port)
	res := win.connect(win.SOCKET(skt), (^win.SOCKADDR)(&sockaddr), addrsize)
	if res < 0 {
		err = Specific_Dial_Error(win.WSAGetLastError())
		return
	}

	return
}



Make_Unbound_Udp_Socket_Error :: union {
	Create_Socket_Error,
}

// This type of socket becomes bound when you try to send data.
// This is likely what you want if you only want to send data unsolicited.
//
// This is like a client TCP socket, except that it can send data to any remote endpoint without needing to establish a connection first.
make_unbound_udp_socket :: proc(family: Socket_IP_Family) -> (skt: Udp_Socket, err: Make_Unbound_Udp_Socket_Error) {
	sock := create_socket(family, .Udp) or_return
	skt = sock.(Udp_Socket)
	return
}


Make_Bound_Udp_Socket_Error :: union {
	Make_Unbound_Udp_Socket_Error,
	Bind_Socket_Error,
}
Bind_Socket_Error :: enum c.int {
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

// This type of socket is bound immediately, which enables it to receive data on the port.
// Since it's UDP, it's also able to send data without receiving any first.
//
// This is like a listening TCP socket, except that data packets can be sent and received without needing to establish a connection first.
//
// The bound_address is the address of the network interface that you want to use, or a loopback address if you don't care which to use.
make_bound_udp_socket :: proc(bound_address: Address, port: int) -> (skt: Udp_Socket, err: Make_Bound_Udp_Socket_Error) {
	skt = make_unbound_udp_socket(family_from_address(bound_address)) or_return

	sockaddr, addrsize := address_to_sockaddr(bound_address, port)
	res := win.bind(win.SOCKET(skt), (^win.SOCKADDR)(&sockaddr), addrsize)
	if res < 0 {
		err = Bind_Socket_Error(win.WSAGetLastError())
		return
	}

	return
}



Listen_Error :: union {
	Specific_Listen_Error,
	Create_Socket_Error,
}

Specific_Listen_Error :: enum c.int {
	Address_In_Use = win.WSAEADDRINUSE,
	Already_Connected = win.WSAEISCONN,
	No_Socket_Descriptors_Available = win.WSAEMFILE,
	No_Buffer_Space_Available = win.WSAENOBUFS,
	Nonlocal_Address = win.WSAEADDRNOTAVAIL,
	Not_Socket = win.WSAENOTSOCK,
	Listening_Not_Supported_For_This_Socket = win.WSAEOPNOTSUPP,
}

listen_tcp :: proc(local_addr: Address, port: int, backlog := 1000) -> (skt: Tcp_Socket, err: Listen_Error) {
	assert(backlog > 0 && i32(backlog) < max(i32))

	family := family_from_address(local_addr)
	sock := create_socket(family, .Tcp) or_return
	skt = sock.(Tcp_Socket)
	defer if err != nil do close(skt)

	_ = set_option(skt, .Exclusive_Addr_Use, true)

	sockaddr, addrsize := address_to_sockaddr(local_addr, port)
	res := win.bind(win.SOCKET(skt), cast(^win.SOCKADDR) &sockaddr, addrsize)
	if res == win.SOCKET_ERROR {
		err = Specific_Listen_Error(win.WSAGetLastError())
		return
	}

	res = win.listen(win.SOCKET(skt), i32(backlog))
	if res == win.SOCKET_ERROR {
		err = Specific_Listen_Error(win.WSAGetLastError())
		return
	}

	return
}



Accept_Error :: enum c.int {
	Ok = 0,
	Reset = win.WSAECONNRESET,
	Not_Listening = win.WSAEINVAL,
	No_Socket_Descriptors_Available_For_Client_Socket = win.WSAEMFILE,
	No_Buffer_Space_Available = win.WSAENOBUFS,
	Not_Socket = win.WSAENOTSOCK,
	Not_Connection_Oriented_Socket = win.WSAEOPNOTSUPP,
	Would_Block = win.WSAEWOULDBLOCK, // TODO: we may need special handling for this; maybe make a socket a struct with metadata?
}

accept_tcp :: proc(sock: Tcp_Socket) -> (client: Tcp_Socket, source: Endpoint, err: Accept_Error) {
	sockaddr: win.SOCKADDR_STORAGE_LH
	sockaddrlen := c.int(size_of(sockaddr))
	client_sock := win.accept(win.SOCKET(sock), cast(^win.SOCKADDR) &sockaddr, &sockaddrlen)
	if int(client_sock) == win.SOCKET_ERROR {
		err = Accept_Error(win.WSAGetLastError())
		return
	}
	client = Tcp_Socket(client_sock)

	source_address: Address
	port: int
	switch sockaddrlen {
	case size_of(win.sockaddr_in):
		p := cast(^win.sockaddr_in) &sockaddr
		source_address = transmute(Ipv4_Address) p.sin_addr.s_addr
		port = int(p.sin_port)
	case size_of(win.sockaddr_in6):
		p := cast(^win.sockaddr_in6) &sockaddr
		source_address = transmute(Ipv6_Address) p.sin6_addr.s6_addr
		port = int(p.sin6_port)
	case:
		unreachable()
	}

	source = { source_address, port }
	return
}



close :: proc(skt: Any_Socket) {
	s := any_socket_to_socket(skt)
	win.closesocket(win.SOCKET(s))
}



Tcp_Recv_Error :: enum c.int {
	Ok = 0,
	Shutdown = win.WSAESHUTDOWN,
	Not_Connected = win.WSAENOTCONN,
	Connection_Broken = win.WSAENETRESET,
	Not_Socket = win.WSAENOTSOCK,
	Aborted = win.WSAECONNABORTED,
	Reset = win.WSAECONNRESET, // Gracefully shutdown
	Offline = win.WSAENETDOWN,
	Host_Unreachable = win.WSAEHOSTUNREACH,
	Interrupted = win.WSAEINTR,
	Timeout = win.WSAETIMEDOUT,
}

recv_tcp :: proc(skt: Tcp_Socket, buf: []byte) -> (bytes_read: int, err: Tcp_Recv_Error) {
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
	Ok = 0,
	Truncated = win.WSAEMSGSIZE,
	Reset = win.WSAECONNRESET,
	Not_Socket = win.WSAENOTSOCK,
	Socket_Not_Bound = win.WSAEINVAL, // .. or unknown flag specified; or MSG_OOB specified with SO_OOBINLINE enabled
}

recv_udp :: proc(skt: Udp_Socket, buf: []byte) -> (bytes_read: int, remote_endpoint: Endpoint, err: Udp_Recv_Error) {
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



Tcp_Send_Error :: enum c.int {
	Aborted = win.WSAECONNABORTED,
	Not_Connected = win.WSAENOTCONN,
	Shutdown = win.WSAESHUTDOWN,
	Reset = win.WSAECONNRESET,
	No_Buffer_Space_Available = win.WSAENOBUFS,
	Offline = win.WSAENETDOWN,
	Host_Unreachable = win.WSAEHOSTUNREACH,
	Interrupted = win.WSAEINTR,
	Timeout = win.WSAETIMEDOUT,
}

// Repeatedly sends data until the entire buffer is sent.
// If a send fails before all data is sent, returns the amount
// sent up to that point.
send_tcp :: proc(skt: Tcp_Socket, buf: []byte) -> (bytes_written: int, err: Tcp_Send_Error) {
	for bytes_written < len(buf) {
		limit := min(1<<31, len(buf) - bytes_written)
		res := win.send(win.SOCKET(skt), raw_data(buf), c.int(limit), 0)
		if res < 0 {
			err = Tcp_Send_Error(win.WSAGetLastError())
			return
		}
		bytes_written += int(res)
	}
	return
}

Udp_Send_Error :: enum c.int {
	Truncated = win.WSAEMSGSIZE,
}

send_udp :: proc(skt: Udp_Socket, buf: []byte, to: Endpoint) -> (bytes_written: int, err: Udp_Send_Error) {
	toaddr, toaddrsize := address_to_sockaddr(to.address, to.port)
	for bytes_written < len(buf) {
		limit := min(1<<31, len(buf) - bytes_written)
		res := win.sendto(win.SOCKET(skt), raw_data(buf), c.int(limit), 0, cast(^win.SOCKADDR) &toaddr, toaddrsize)
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
	Ok = 0,
	Aborted = win.WSAECONNABORTED,
	Reset = win.WSAECONNRESET,
	Offline = win.WSAENETDOWN,
	Not_Connected = win.WSAENOTCONN,
	Not_Socket = win.WSAENOTSOCK,
	Invalid_Manner = win.WSAEINVAL,
}

shutdown :: proc(skt: Any_Socket, manner: Shutdown_Manner) -> (err: Shutdown_Error) {
	s := any_socket_to_socket(skt)
	res := win.shutdown(win.SOCKET(s), c.int(manner))
	if res < 0 {
		return Shutdown_Error(win.WSAGetLastError())
	}
	return
}




Socket_Option :: enum c.int {
	// value: win.BOOL
	Reuse_Address = win.SO_REUSEADDR,
	Exclusive_Addr_Use = win.SO_EXCLUSIVEADDRUSE,
	Keep_Alive = win.SO_KEEPALIVE,
	Conditional_Accept = win.SO_CONDITIONAL_ACCEPT,
	Dont_Linger = win.SO_DONTLINGER,
	Out_Of_Bounds_Data_Inline = win.SO_OOBINLINE,
	Tcp_Nodelay = win.TCP_NODELAY,

	// value: win.LINGER
	Linger = win.SO_LINGER,

	// value: win.DWORD
	Receive_Buffer_Size = win.SO_RCVBUF,
	Send_Buffer_Size = win.SO_SNDBUF,
	Receive_Timeout = win.SO_RCVTIMEO,
	Send_Timeout = win.SO_SNDTIMEO,
}

Socket_Option_Error :: enum c.int {
	Ok = 0,

	Incorrect_Type,
	Unknown_Option,

	Offline = win.WSAENETDOWN,
	Timeout_When_Keepalive_Set = win.WSAENETRESET,
	Invalid_Option_For_Socket = win.WSAENOPROTOOPT,
	Reset_When_Keepalive_Set = win.WSAENOTCONN,
	Not_Socket = win.WSAENOTSOCK,
}

// Socket must be bound.
set_option :: proc(s: Any_Socket, option: Socket_Option, value: any) -> Socket_Option_Error {
	level := win.SOL_SOCKET
	if option == .Tcp_Nodelay do level = win.IPPROTO_TCP


	switch option {
	case
		.Reuse_Address,
		.Exclusive_Addr_Use,
		.Keep_Alive,
		.Conditional_Accept,
		.Dont_Linger,
		.Out_Of_Bounds_Data_Inline,
		.Tcp_Nodelay:
			switch in value {
			case bool:
				// okay
			case:
				return .Incorrect_Type
			}
	case
		.Receive_Buffer_Size,
		.Send_Buffer_Size,
		.Receive_Timeout,
		.Send_Timeout:
			switch in value {
			case win.DWORD:
				// okay
			case:
				return .Incorrect_Type
			}
	case .Linger:
		switch in value {
		case win.LINGER:
			// okay
		case:
			return .Incorrect_Type
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