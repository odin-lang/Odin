//+build windows
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

import sys     "core:sys/windows"
import win32   "core:sys/win32"
import strings "core:strings"

MAX_INTERFACE_ENUMERATION_TRIES :: 3

/*
	`enumerate_interfaces` retrieves a list of network interfaces with their associated properties.
*/
enumerate_interfaces :: proc(allocator := context.allocator) -> (interfaces: []Network_Interface, err: Network_Error) {
	context.allocator = allocator

 	buf:      []u8
 	defer delete(buf)
 	buf_size: u32

 	res: u32

 	gaa: for _ in 1..=MAX_INTERFACE_ENUMERATION_TRIES {
 	 	res = sys.get_adapters_addresses(
 			.Unspecified, // Return both IPv4 and IPv6 adapters.
			sys.GAA_Flags{
				.Include_Prefix,               // (XP SP1+) Return a list of IP address prefixes on this adapter. When this flag is set, IP address prefixes are returned for both IPv6 and IPv4 addresses.
				.Include_Gateways,             // (Vista+) Return the addresses of default gateways.
				.Include_Tunnel_Binding_Order, // (Vista+) Return the adapter addresses sorted in tunnel binding order.
			},
 			nil,          // Reserved
 			(^sys.IP_Adapter_Addresses)(raw_data(buf)),
 			&buf_size,
 		)

 	 	switch res {
 	 	case 111: // ERROR_BUFFER_OVERFLOW:
 	 		delete(buf)
 	 		buf = make([]u8, buf_size)
 	 	case 0:
 	 		break gaa
 	 	case:
 	 		return {}, Platform_Error(res)
 	 	}
 	}

 	if res != 0 {
 		return {}, .Unable_To_Enumerate_Network_Interfaces
 	}

 	_interfaces := make([dynamic]Network_Interface, 0, allocator)

 	for adapter := (^sys.IP_Adapter_Addresses)(raw_data(buf)); adapter != nil; adapter = adapter.Next {
		interface := Network_Interface{
			adapter_name  = strings.clone(string(adapter.AdapterName)),
 			friendly_name = wstring_to_string(adapter.FriendlyName),
 			description   = wstring_to_string(adapter.Description),
 			dns_suffix    = wstring_to_string(adapter.DnsSuffix),

 			mtu  = adapter.MTU,

 			link = {
				transmit_speed = adapter.TransmitLinkSpeed,
				receive_speed  = adapter.ReceiveLinkSpeed,
 			},
 		}

 		if adapter.PhysicalAddressLength > 0 && adapter.PhysicalAddressLength <= len(adapter.PhysicalAddress) {
 			interface.physical_address = physical_address_to_string(adapter.PhysicalAddress[:adapter.PhysicalAddressLength])
 		}

 		unicast: [dynamic]Lease
 		for u_addr := (^sys.IP_ADAPTER_UNICAST_ADDRESS_LH)(adapter.FirstUnicastAddress); u_addr != nil; u_addr = u_addr.Next {
 			win_addr := parse_socket_address(u_addr.Address)

 			lease := Lease{
 				address = win_addr,
 				origin  = {
 					prefix = Prefix_Origin(u_addr.PrefixOrigin),
 					suffix = Suffix_Origin(u_addr.SuffixOrigin),
 				},
 				lifetime = {
 					valid     = u_addr.ValidLifetime,
 					preferred = u_addr.PreferredLifetime,
 					lease     = u_addr.LeaseLifetime,
 				},
 				address_duplication = Address_Duplication(u_addr.DadState),
 			}
 			append(&unicast, lease)
 		}
		interface.unicast = unicast[:]

 		anycast: [dynamic]Endpoint
 		for a_addr := (^sys.IP_ADAPTER_ANYCAST_ADDRESS_XP)(adapter.FirstAnycastAddress); a_addr != nil; a_addr = a_addr.Next {
 			ep := parse_socket_address(a_addr.Address)
 			append(&anycast, ep)
 		}
		interface.anycast = anycast[:]

 		multicast: [dynamic]Endpoint
 		for m_addr := (^sys.IP_ADAPTER_MULTICAST_ADDRESS_XP)(adapter.FirstMulticastAddress); m_addr != nil; m_addr = m_addr.Next {
 			ep := parse_socket_address(m_addr.Address)
 			append(&multicast, ep)
 		}
		interface.multicast = multicast[:]

 		gateways: [dynamic]Endpoint
 		for g_addr := (^sys.IP_ADAPTER_GATEWAY_ADDRESS_LH)(adapter.FirstGatewayAddress); g_addr != nil; g_addr = g_addr.Next {
 			ep := parse_socket_address(g_addr.Address)
 			append(&gateways, ep)
 		}
		interface.gateways = gateways[:]

		interface.dhcp_v4 = parse_socket_address(adapter.Dhcpv4Server)
		interface.dhcp_v6 = parse_socket_address(adapter.Dhcpv6Server)


 		switch adapter.OperStatus {
 		case .Up:             interface.link.state = .Up
 		case .Down:           interface.link.state = .Down
 		case .Testing:        interface.link.state = .Testing
 		case .Dormant:        interface.link.state = .Dormant
 		case .NotPresent:     interface.link.state = .Not_Present
 		case .LowerLayerDown: interface.link.state = .Lower_Layer_Down
 		case .Unknown:        fallthrough
 		case:                 interface.link.state = .Unknown
 		}

 		interface.tunnel_type = Tunnel_Type(adapter.TunnelType)

 		append(&_interfaces, interface)
 	}

	return _interfaces[:], {}
}

/*
	Takes a UTF-16 Wstring and clones it.
*/
wstring_to_string :: proc(s: ^u16, max_size := 256, allocator := context.allocator) -> (res: string) {
	temp := win32.wstring_to_utf8((win32.Wstring)(s), max_size, context.temp_allocator)
	return strings.clone(temp[:len(temp)], allocator)
}

/*
	Interpret SOCKET_ADDRESS as an Address
*/
parse_socket_address :: proc(addr_in: sys.SOCKET_ADDRESS) -> (addr: Endpoint) {
	if addr_in.lpSockaddr == nil {
		return // Empty or invalid address type
	}

	sock := addr_in.lpSockaddr^

	switch sock.sa_family {
	case u16(sys.AF_INET):
		win_addr := cast(^sys.sockaddr_in)addr_in.lpSockaddr
		port     := int(win_addr.sin_port)
		return Endpoint {
			address = IP4_Address(transmute([4]byte)win_addr.sin_addr),
			port    = port,
		}

	case u16(sys.AF_INET6):
		win_addr := cast(^sys.sockaddr_in6)addr_in.lpSockaddr
		port     := int(win_addr.sin6_port)
		return Endpoint {
			address = IP6_Address(transmute([8]u16be)win_addr.sin6_addr),
			port = port,
		}


	case: return // Empty or invalid address type
	}
	unreachable()
}