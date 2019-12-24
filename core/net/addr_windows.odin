package net

import "core:strconv"
import "core:strings"
import "core:mem"

import "core:sys/win32"


// Returns an address for each interface that can be bound to.
get_network_interfaces :: proc() -> []Address {
	return nil;
}

@private
to_socket_address :: proc(addr: Address, port: int) -> (socket_addr: win32.Socket_Address, addr_size: i32) {
	switch a in addr {
	case Ipv4_Address:
		socket_addr = win32.make_sockaddr(win32.AF_INET,  transmute(win32.in_addr)  a, u16(port));
		addr_size = size_of(socket_addr.ipv4);
	case Ipv6_Address:
		socket_addr = win32.make_sockaddr(win32.AF_INET6, transmute(win32.in6_addr) a, u16(port));
		addr_size = size_of(socket_addr.ipv6);
	}
	return;
}

@private
to_canonical_endpoint :: proc(native_addr: win32.Socket_Address, auto_cast addr_size: int) -> (ep: Endpoint) {
	switch addr_size {
	case size_of(win32.sockaddr_in):
		port := int(native_addr.ipv4.port);
		ep = Endpoint {
			addr = Ipv4_Address(native_addr.ipv4.addr),
			port = port,
		};
	case size_of(win32.sockaddr_in6):
		port := int(native_addr.ipv6.port);
		ep = Endpoint {
			addr = Ipv6_Address(transmute([8]u16be) native_addr.ipv6.addr),
			port = port,
		};
	case:
		panic("addr_size must be size_of(sockaddr_in) or size_of(sockaddr_in6)");
	}
	return;
}