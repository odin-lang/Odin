package net
//+build linux

/*
	Package net implements cross-platform Berkeley Sockets, DNS resolution and associated procedures.
	For other protocols and their features, see subdirectories of this package.
*/

/*
	Copyright 2022 Tetralux        <tetraluxonpc@gmail.com>
	Copyright 2022 Colin Davidson  <colrdavidson@gmail.com>
	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Copyright 2024 Feoramund       <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Tetralux:        Initial implementation
		Colin Davidson:  Linux platform code, OSX platform code, Odin-native DNS resolver
		Jeroen van Rijn: Cross platform unification, code style, documentation
		Feoramund:       FreeBSD platform code

	This file uses `getifaddrs` libc call to enumerate interfaces.
	TODO: When we have raw sockets, split off into its own file for Linux so we can use the NETLINK protocol and bypass libc.
*/

//import "core:strings"


// TODO(flysand): regression
// NOTE(flysand): https://man7.org/linux/man-pages/man7/netlink.7.html
// apparently musl libc uses this to enumerate network interfaces
@(private)
_enumerate_interfaces :: proc(allocator := context.allocator) -> (interfaces: []Network_Interface, err: Network_Error) {
	context.allocator = allocator

	// head: ^os.ifaddrs

	// if res := os._getifaddrs(&head); res < 0 {
	// 	return {}, .Unable_To_Enumerate_Network_Interfaces
	// }

	// /*
	// 	Unlike Windows, *nix regrettably doesn't return all it knows about an interface in one big struct.
	// 	We're going to have to iterate over a list and coalesce information as we go.
	// */
	// ifaces: map[string]^Network_Interface
	// defer delete(ifaces)

	// for ifaddr := head; ifaddr != nil; ifaddr = ifaddr.next {
	// 	adapter_name := string(ifaddr.name)

	// 	/*
	// 		Check if we have seen this interface name before so we can reuse the `Network_Interface`.
	// 		Else, create a new one.
	// 	*/
	// 	if adapter_name not_in ifaces {
	// 		ifaces[adapter_name] = new(Network_Interface)
	// 		ifaces[adapter_name].adapter_name = strings.clone(adapter_name)
	// 	}
	// 	iface := ifaces[adapter_name]

	// 	address: Address
	// 	netmask: Netmask

	// 	if ifaddr.address != nil {
	// 		switch int(ifaddr.address.sa_family) {
	// 		case os.AF_INET, os.AF_INET6:
	// 			address = _sockaddr_basic_to_endpoint(ifaddr.address).address

	// 		case os.AF_PACKET:
	// 			/*
	// 				For some obscure reason the 64-bit `getifaddrs` call returns a pointer to a
	// 				32-bit `RTNL_LINK_STATS` structure, which of course means that tx/rx byte count
	// 				is truncated beyond usefulness.

	// 				We're not going to retrieve stats now. Instead this serves as a reminder to use
	// 				the NETLINK protocol for this purpose.

	// 				But in case you were curious:
	// 					stats := transmute(^os.rtnl_link_stats)ifaddr.data
	// 					fmt.println(stats)
	// 			*/
	// 		case:
	// 		}
	// 	}

	// 	if ifaddr.netmask != nil {
	// 		switch int(ifaddr.netmask.sa_family) {
	// 		case os.AF_INET, os.AF_INET6:
	// 		 	netmask = Netmask(_sockaddr_basic_to_endpoint(ifaddr.netmask).address)
	// 		case:
	// 		}
	// 	}

	// 	if ifaddr.broadcast_or_dest != nil && .BROADCAST in ifaddr.flags {
	// 		switch int(ifaddr.broadcast_or_dest.sa_family) {
	// 		case os.AF_INET, os.AF_INET6:
	// 		 	broadcast := _sockaddr_basic_to_endpoint(ifaddr.broadcast_or_dest).address
	// 		 	append(&iface.multicast, broadcast)
	// 		case:
	// 		}
	// 	}

	// 	if address != nil {
	// 		lease := Lease{
	// 			address = address,
	// 			netmask = netmask,
	// 		}
	// 		append(&iface.unicast, lease)
	// 	}

	// 	/*
	// 		TODO: Refine this based on the type of adapter.
	// 	*/
 	// 	state := Link_State{}

 	// 	if .UP in ifaddr.flags {
 	// 		state |= {.Up}
 	// 	}

 	// 	if .DORMANT in ifaddr.flags {
 	// 		state |= {.Dormant}
 	// 	}

 	// 	if .LOOPBACK in ifaddr.flags {
 	// 		state |= {.Loopback}
 	// 	}
	// 	iface.link.state = state
	// }

	// /*
	// 	Free the OS structures.
	// */
	// os._freeifaddrs(head)

	// /*
	// 	Turn the map into a slice to return.
	// */
	// _interfaces := make([dynamic]Network_Interface, 0, allocator)
	// for _, iface in ifaces {
	// 	append(&_interfaces, iface^)
	// 	free(iface)
	// }
	// return _interfaces[:], {}
	return nil, {}
}