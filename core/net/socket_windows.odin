package net

import "core:mem"
import "core:c"
import "core:os"
import win "core:sys/windows"

import "core:fmt"

Socket :: distinct win.SOCKET

Socket_Protocol :: enum {
	Tcp,
	Udp,
}


Dial_Error :: enum c.int {
	Ok = 0,
	Offline = win.WSAENETDOWN,
	Address_In_Use = win.WSAEADDRINUSE,
	In_Progress = win.WSAEALREADY,
	Invalid_Address = win.WSAEADDRNOTAVAIL,
	Family_Not_Supported_For_This_Socket = win.WSAEAFNOSUPPORT,
	Refused = win.WSAECONNREFUSED,
	Is_Listening_Socket = win.WSAEINVAL,
	Already_Connected = win.WSAEISCONN,
	Network_Unreachable = win.WSAENETUNREACH,
	Host_Unreachable = win.WSAEHOSTUNREACH,
	No_Buffer_Space_Available = win.WSAENOBUFS,
	Not_Socket = win.WSAENOTSOCK,
	Timeout = win.WSAETIMEDOUT,
	Would_Block = win.WSAEWOULDBLOCK,
}

dial :: proc(addr: Address, port: int, protocol: Socket_Protocol) -> (skt: Socket, err: Dial_Error) {
	win.ensure_winsock_initialized()

	family: c.int
	switch in addr {
	case Ipv4_Address:  family = win.AF_INET
	case Ipv6_Address:  family = win.AF_INET6
	}

	typ, proto: c.int
	switch protocol {
	case .Tcp:  typ = win.SOCK_STREAM; proto = win.IPPROTO_TCP
	case .Udp:  typ = win.SOCK_DGRAM;  proto = win.IPPROTO_UDP
	}

	sock := win.socket(family, typ, proto)
	if sock == win.INVALID_SOCKET {
		err = Dial_Error(win.WSAGetLastError())
		return
	}
	skt = Socket(sock)
	defer if err != nil do close(skt)

	_ = set_option(skt, .Reuse_Address, true)

	sockaddr, addrsize := to_socket_address(family, addr, port)
	res := win.connect(sock, (^win.SOCKADDR)(&sockaddr), addrsize)
	if res < 0 {
		err = Dial_Error(win.WSAGetLastError())
		return
	}

	return
}



Listen_Error :: enum c.int {
	Ok = 0,
	Offline = win.WSAENETDOWN,
	Broadcast_Not_Set = win.WSAEACCES,
	Address_In_Use = win.WSAEADDRINUSE,
	Nonlocal_Address = win.WSAEADDRNOTAVAIL,
	No_Buffer_Space_Available = win.WSAENOBUFS,
	Not_Socket = win.WSAENOTSOCK,
}

// NOTE(tetra): This is so that if we crash while the socket is open, we can
// bypass the cooldown period, and allow the next run of the program to
// use the same address, for the same socket immediately.
// set_option(sock, .Reuse_Address);
listen :: proc(local_addr: Address, port: int, backlog := 1000) -> (skt: Socket, err: Listen_Error) {
	win.ensure_winsock_initialized()

	family: c.int
	switch in local_addr {
	case Ipv4_Address:  family = win.AF_INET
	case Ipv6_Address:  family = win.AF_INET6
	}

	typ := win.SOCK_STREAM
	proto := win.IPPROTO_TCP
	sock := win.socket(family, typ, proto)
	if sock == win.INVALID_SOCKET {
		err = Listen_Error(win.WSAGetLastError())
		return
	}
	skt = Socket(sock)
	defer if err != nil do close(skt)

	_ = set_option(skt, .Exclusive_Addr_Use, true)

	sockaddr, addrsize := to_socket_address(family, local_addr, port)
	res := win.bind(sock, cast(^win.SOCKADDR) &sockaddr, addrsize)
	if res == win.SOCKET_ERROR {
		err = Listen_Error(win.WSAGetLastError())
		return
	}

	res = win.listen(sock, i32(backlog))
	if res == win.SOCKET_ERROR {
		err = Listen_Error(win.WSAGetLastError())
		return
	}

	return
}


Accept_Error :: enum c.int {
	Ok = 0,
	Reset = win.WSAECONNRESET,
	Not_Listening = win.WSAEINVAL,
	No_Socket_Descriptors_Available = win.WSAEMFILE,
	Offline = win.WSAENETDOWN,
	No_Buffer_Space_Available = win.WSAENOBUFS,
	Not_Socket = win.WSAENOTSOCK,
	Not_Connnectable_Socket = win.WSAEOPNOTSUPP,
	Would_Block = win.WSAEWOULDBLOCK,
}

accept :: proc(sock: Socket) -> (client: Socket, source: Endpoint, err: Accept_Error) {
	sockaddr: win.SOCKADDR_STORAGE_LH
	sockaddrlen := c.int(size_of(sockaddr))
	client_sock := win.accept(win.SOCKET(sock), cast(^win.SOCKADDR) &sockaddr, &sockaddrlen)
	if int(client_sock) == win.SOCKET_ERROR {
		err = Accept_Error(win.WSAGetLastError())
		return
	}
	client = Socket(client_sock)

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
	err = .Ok
	return
}


close :: proc(s: Socket) {
	win.closesocket(win.SOCKET(s))
}



// TODO: audit these errors; consider if they can be cleaned up further
// same for Send_Error
Recv_Error :: enum c.int {
	Ok = 0,
	Shutdown = win.WSAESHUTDOWN,
	Not_Connected = win.WSAENOTCONN,
	Aborted = win.WSAECONNABORTED,
	Reset = win.WSAECONNRESET,
	Truncated = win.WSAEMSGSIZE, // Only for UDP sockets
	Offline = win.WSAENETDOWN,
	Host_Unreachable = win.WSAEHOSTUNREACH,
	Interrupted = win.WSAEINTR,
	Timeout = win.WSAETIMEDOUT,
}

recv :: proc(s: Socket, buf: []byte) -> (bytes_read: int, err: Recv_Error) {
	res := win.recv(win.SOCKET(s), &buf[0], c.int(len(buf)), 0)
	if res < 0 {
		err = Recv_Error(win.WSAGetLastError())
		return
	}
	return int(res), .Ok
}

Send_Error :: enum c.int {
	Ok = 0,
	Aborted = win.WSAECONNABORTED,
	Not_Connected = win.WSAENOTCONN,
	Shutdown = win.WSAESHUTDOWN,
	Truncated = win.WSAEMSGSIZE, // Only for UDP sockets
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
send :: proc(s: Socket, buf: []byte) -> (bytes_written: int, err: Send_Error) {
	for bytes_written < len(buf) {
		limit := min(1<<31, len(buf) - bytes_written)
		res := win.send(win.SOCKET(s), &buf[0], c.int(limit), 0)
		if res < 0 {
			err = Send_Error(win.WSAGetLastError())
			return
		}
		bytes_written += int(res)
	}
	return
}



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

shutdown :: proc(s: Socket, manner: Shutdown_Manner) -> (err: Shutdown_Error) {
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
	Keep_Alive_Timeout = win.WSAENETRESET,
	Invalid_Option = win.WSAENOPROTOOPT,
	Not_Connected = win.WSAENOTCONN,
	Not_Socket = win.WSAENOTSOCK,
}

set_option :: proc(s: Socket, option: Socket_Option, value: any) -> Socket_Option_Error {
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
			case i8, i16, i32, i64, i128, int, u8, u16, u32, u64, u128, uint:
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

	res := win.setsockopt(win.SOCKET(s), c.int(level), c.int(option), ptr, len)
	if res < 0 {
		return Socket_Option_Error(win.WSAGetLastError())
	}

	return .Ok
}