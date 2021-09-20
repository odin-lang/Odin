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


Socket_Error :: union {
	Dial_Error,
	Listen_Error,
	Send_Error,
	Recv_Error,
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
	Not_A_Socket = win.WSAENOTSOCK,
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

	sockaddr, addrsize := to_socket_address(family, addr, port)
	res := win.connect(sock, (^win.SOCKADDR)(&sockaddr), addrsize)
	if res < 0 {
		err = Dial_Error(win.WSAGetLastError())
		return
	}

	return Socket(sock), .Ok
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

	return Socket(sock), .Ok
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