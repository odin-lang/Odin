package net

import "core:mem"
import "core:c"
import "core:os"
import win "core:sys/windows"

import "core:fmt"

Socket :: distinct win.SOCKET;

Socket_Type :: enum {
	Tcp,
	Udp,
	Bluetooth, // TODO
}

// NOTE: Must contain all of the other error's values.
// TODO: A better way to handle this?
Socket_Error :: enum {
	Ok,
}

Dial_Error :: enum i32 {
	Ok,
	Address_Not_Available = win.WSAEADDRNOTAVAIL,
	Refused = win.WSAECONNREFUSED,
}

dial :: proc(addr: Address, port: int, type: Socket_Type) -> (Socket, Dial_Error) {
	win.ensure_winsock_initialized();

	family: c.int;
	if type == .Tcp || type == .Udp {
		switch in addr {
		case Ipv4_Address:  family = win.AF_INET;
		case Ipv6_Address:  family = win.AF_INET6;
		}
	} else {
		family = win.AF_BTH;
	}
	typ, proto: c.int;
	switch type {
	case .Tcp:        typ = win.SOCK_STREAM; proto = win.IPPROTO_TCP;
	case .Udp:        typ = win.SOCK_DGRAM;  proto = win.IPPROTO_UDP;
	case .Bluetooth:  typ = win.SOCK_STREAM; proto = win.BTHPROTO_RFCOMM;
	}
	sock := win.socket(family, typ, proto);
	if sock == win.INVALID_SOCKET {
		return {}, Dial_Error(win.WSAGetLastError());
	}

	sockaddr, addrsize := to_socket_address(family, addr, port); // FIXME: Why does this fail?
	res := win.connect(sock, (^win.SOCKADDR)(&sockaddr), addrsize);
	if res < 0 {
		return {}, Dial_Error(win.WSAGetLastError());
	}

	return Socket(sock), .Ok;
}

// TODO: put this in listen() when we make it:
// NOTE(tetra): This is so that if we crash while the socket is open, we can
// bypass the cooldown period, and allow the next run of the program to
// use the same address, for the same socket immediately.
// set_option(sock, .Reuse_Address);

close :: proc(s: Socket) {
	win.closesocket(win.SOCKET(s));
}

// TODO: audit these errors; consider if they can be cleaned up further
// same for Send_Error
Recv_Error :: enum i32 {
	Ok,
	Shutdown = win.WSAESHUTDOWN,
	Aborted = win.WSAECONNABORTED,
	Reset = win.WSAECONNRESET,
	Truncated = win.WSAEMSGSIZE, // Only for UDP sockets
	Offline = win.WSAENETDOWN,
	Unreachable = win.WSAEHOSTUNREACH,
	Interrupted = win.WSAEINTR,
	Timeout = win.WSAETIMEDOUT,
}

recv :: proc(s: Socket, buf: []byte) -> (bytes_read: int, err: Recv_Error) {
	res := win.recv(win.SOCKET(s), &buf[0], c.int(len(buf)), 0);
	if res < 0 {
		err = Recv_Error(win.WSAGetLastError());
	}
	bytes_read = int(res);
	return;
}

Send_Error :: enum i32 {
	Ok,
	Aborted = win.WSAECONNABORTED,
	Not_Connected = win.WSAENOTCONN,
	Shutdown = win.WSAESHUTDOWN,
	Truncated = win.WSAEMSGSIZE, // Only for UDP sockets
	Reset = win.WSAECONNRESET,
	Out_Of_Resources = win.WSAENOBUFS,
	Offline = win.WSAENETDOWN,
	Unreachable = win.WSAEHOSTUNREACH,
	Interrupted = win.WSAEINTR,
	Timeout = win.WSAETIMEDOUT,
}

// Repeatedly sends data until the entire buffer is sent.
// If a send fails before all data is sent, returns the amount
// sent up to that point.
send :: proc(s: Socket, buf: []byte) -> (bytes_written: int, err: Send_Error) {
	for bytes_written < len(buf) {
		limit := min(1<<31, len(buf) - bytes_written);
		res := win.send(win.SOCKET(s), &buf[0], c.int(limit), 0);
		if res < 0 {
			err = Send_Error(win.WSAGetLastError());
			return;
		}
		bytes_written += int(res);
	}
	return;
}
