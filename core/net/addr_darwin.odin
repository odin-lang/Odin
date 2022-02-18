/*
	Copyright 2022 Tetralux        <tetraluxonpc@gmail.com>
	Copyright 2022 Colin Davidson  <colrdavidson@gmail.com>
	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Tetralux:        Initial implementation
		Colin Davidson:  Linux platform code, OSX platform code, Odin-native DNS resolver
		Jeroen van Rijn: Cross platform unification, code style, documentation
*/

/*
	package net implements cross-platform Berkeley Sockets and associated procedures.
*/
package net

import "core:os"

// Returns an address for each interface that can be bound to.
get_network_interfaces :: proc() -> []Address {
	// TODO
	return nil
}

@private
endpoint_to_sockaddr :: proc(ep: Endpoint) -> (sockaddr: os.SOCKADDR_STORAGE_LH) {
	switch a in ep.address {
	case Ipv4_Address:
		(^os.sockaddr_in)(&sockaddr)^ = os.sockaddr_in {
			sin_port = u16be(ep.port),
			sin_addr = transmute(os.in_addr) a,
			sin_family = u8(os.AF_INET),
			sin_len = size_of(os.sockaddr_in),
		}
		return
	case Ipv6_Address:
		(^os.sockaddr_in6)(&sockaddr)^ = os.sockaddr_in6 {
			sin6_port = u16be(ep.port),
			sin6_addr = transmute(os.in6_addr) a,
			sin6_family = u8(os.AF_INET6),
			sin6_len = size_of(os.sockaddr_in6),
		}
		return
	}
	unreachable()
}

@private
sockaddr_to_endpoint :: proc(native_addr: ^os.SOCKADDR_STORAGE_LH) -> (ep: Endpoint) {
	switch native_addr.family {
	case u8(os.AF_INET):
		addr := cast(^os.sockaddr_in) native_addr
		port := int(addr.sin_port)
		ep = Endpoint {
			address = Ipv4_Address(transmute([4]byte) addr.sin_addr),
			port = port,
		}
	case u8(os.AF_INET6):
		addr := cast(^os.sockaddr_in6) native_addr
		port := int(addr.sin6_port)
		ep = Endpoint {
			address = Ipv6_Address(transmute([8]u16be) addr.sin6_addr),
			port = port,
		}
	case:
		panic("native_addr is neither IPv4 or IPv6 address")
	}
	return
}
