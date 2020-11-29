package net

import "core:c"
import win "core:sys/windows"


// Returns an address for each interface that can be bound to.
get_network_interfaces :: proc() -> []Address {
	// TODO
	return nil;
}

@private
to_socket_address :: proc(family: c.int, addr: Address, port: int) -> (socket_addr: win.SOCKADDR, addr_size: c.int) {
	switch a in addr {
	case Ipv4_Address:
		sockaddr := cast(^win.sockaddr_in) &socket_addr;
		sockaddr.sin_port = u16be(win.USHORT(port));
		sockaddr.sin_addr = transmute(win.in_addr) a;
		sockaddr.sin_family = u16(family);
		addr_size = size_of(win.sockaddr_in);
	case Ipv6_Address:
		sockaddr := cast(^win.sockaddr_in6) &socket_addr;
		sockaddr.sin6_port = u16be(win.USHORT(port));
		sockaddr.sin6_addr = transmute(win.in6_addr) a;
		sockaddr.sin6_family = u16(family);
		addr_size = size_of(win.sockaddr_in6);
	}
	return;
}

@private
to_canonical_endpoint :: proc(native_addr: win.SOCKADDR, auto_cast addr_size: int) -> (ep: Endpoint) {
	switch addr_size {
	case size_of(win.sockaddr_in):
		addr := transmute(win.sockaddr_in) native_addr;
		port := int(addr.sin_port);
		ep = Endpoint {
			addr = Ipv4_Address(transmute([4]byte) addr.sin_addr),
			port = port,
		};
	case size_of(win.sockaddr_in6):
		na := native_addr;
		addr := cast(^win.sockaddr_in6) &na;
		port := int(addr.sin6_port);
		ep = Endpoint {
			addr = Ipv6_Address(transmute([8]u16be) addr.sin6_addr),
			port = port,
		};
	case:
		panic("addr_size must be size_of(sockaddr_in) or size_of(sockaddr_in6)");
	}
	return;
}