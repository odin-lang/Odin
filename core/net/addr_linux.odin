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
	Package net implements cross-platform Berkeley Sockets, DNS resolution and associated procedures.
	For other protocols and their features, see subdirectories of this package.
*/
package net

import "core:os"

// Returns an Address for each interface that can be bound to.
get_network_interfaces :: proc() -> []Address {
	// TODO
	return nil
}

@private
endpoint_to_sockaddr :: proc(ep: Endpoint) -> (sockaddr: os.SOCKADDR_STORAGE_LH) {
	switch a in ep.Address {
	case IPv4_Address:
		(^os.sockaddr_in)(&sockaddr)^ = os.sockaddr_in {
			sin_port = u16be(ep.port),
			sin_addr = transmute(os.in_addr) a,
			sin_family = u16(os.AF_INET),
		}
		return
	case IPv6_Address:
		(^os.sockaddr_in6)(&sockaddr)^ = os.sockaddr_in6 {
			sin6_port = u16be(ep.port),
			sin6_addr = transmute(os.in6_addr) a,
			sin6_family = u16(os.AF_INET6),
		}
		return
	}
	unreachable()
}

@private
sockaddr_to_endpoint :: proc(native_addr: ^os.SOCKADDR_STORAGE_LH) -> (ep: Endpoint) {
	switch native_addr.ss_family {
	case u16(os.AF_INET):
		addr := cast(^os.sockaddr_in) native_addr
		port := int(addr.sin_port)
		ep = Endpoint {
			Address = IPv4_Address(transmute([4]byte) addr.sin_addr),
			port = port,
		}
	case u16(os.AF_INET6):
		addr := cast(^os.sockaddr_in6) native_addr
		port := int(addr.sin6_port)
		ep = Endpoint {
			Address = IPv6_Address(transmute([8]u16be) addr.sin6_addr),
			port = port,
		}
	case:
		panic("native_addr is neither IPv4 or IPv6 Address")
	}
	return
}