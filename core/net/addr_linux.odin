package net

import "core:os"

// Returns an address for each interface that can be bound to.
get_network_interfaces :: proc() -> []Address {
	// TODO
	return nil
}

@private
address_to_sockaddr :: proc(addr: Address, port: int) -> (sockaddr: union{os.sockaddr_in, os.sockaddr_in6}, addrsize: int) {
	switch a in addr {
	case Ipv4_Address:
		return os.sockaddr_in {
			sin_port = u16be(port),
			sin_addr = transmute(os.in_addr) a,
			sin_family = u16(os.AF_INET),
		}, size_of(os.sockaddr_in)
	case Ipv6_Address:
		return os.sockaddr_in6 {
			sin6_port = u16be(port),
			sin6_addr = transmute(os.in6_addr) a,
			sin6_family = u16(os.AF_INET6),
		}, size_of(os.sockaddr_in6)
	}
	unreachable()
}

@private
sockaddr_to_endpoint :: proc(native_addr: ^os.SOCKADDR_STORAGE_LH, auto_cast addr_size: int) -> (ep: Endpoint) {
	switch addr_size {
	case size_of(os.sockaddr_in):
		addr := cast(^os.sockaddr_in) native_addr
		port := int(addr.sin_port)
		ep = Endpoint {
			address = Ipv4_Address(transmute([4]byte) addr.sin_addr),
			port = port,
		}
	case size_of(os.sockaddr_in6):
		addr := cast(^os.sockaddr_in6) native_addr
		port := int(addr.sin6_port)
		ep = Endpoint {
			address = Ipv6_Address(transmute([8]u16be) addr.sin6_addr),
			port = port,
		}
	case:
		panic("addr_size must be size_of(sockaddr_in) or size_of(sockaddr_in6)")
	}
	return
}
