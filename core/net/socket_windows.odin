package net

import "core:mem"
import "core:c"
import "core:os"
import win "core:sys/windows"

import "core:fmt"

Socket :: distinct win.SOCKET;

Socket_Type :: enum {
	Stream,
	Datagram,
	Bluetooth, // TESTME
}

dial :: proc(addr: Address, port: int, type: Socket_Type) -> (Socket, os.Errno) {
	win.ensure_winsock_initialized();

	family: c.int;
	if type == .Stream || type == .Datagram {
		switch in addr {
		case Ipv4_Address:  family = win.AF_INET;
		case Ipv6_Address:  family = win.AF_INET6;
		}
	} else {
		family = win.AF_BTH;
	}
	typ, proto: c.int;
	switch type {
	case .Stream:     typ = win.SOCK_STREAM; proto = win.IPPROTO_TCP;
	case .Datagram:   typ = win.SOCK_DGRAM;  proto = win.IPPROTO_UDP;
	case .Bluetooth:  typ = win.SOCK_STREAM; proto = win.BTHPROTO_RFCOMM;
	}
	sock := win.socket(family, typ, proto);
	if sock == win.INVALID_SOCKET {
		return {}, os.Errno(win.WSAGetLastError());
	}

	sockaddr, addrsz := to_socket_address(family, addr, port);
	res := win.connect(sock, (^win.SOCKADDR)(&sockaddr), addrsz);
	if res < 0 {
		return {}, os.Errno(win.WSAGetLastError());
	}

	return Socket(sock), os.ERROR_NONE;
}

close :: proc(s: Socket) {
	win.closesocket(win.SOCKET(s));
}

recv :: proc(s: Socket, buf: []byte) -> (bytes_read: int, err: os.Errno) {
	res := win.recv(win.SOCKET(s), &buf[0], c.int(len(buf)), 0);
	if res < 0 {
		err = os.Errno(win.WSAGetLastError());
	}
	bytes_read = int(res);
	return;
}

send :: proc(s: Socket, buf: []byte) -> (int, os.Errno) {
	sent := 0;
	for sent < len(buf) {
		limit := min(1<<31, len(buf) - sent);
		res := win.send(win.SOCKET(s), &buf[0], c.int(limit), 0);
		if res < 0 {
			return sent, os.Errno(win.WSAGetLastError());
		}
		sent += int(res);
	}
	return sent, os.ERROR_NONE;
}
