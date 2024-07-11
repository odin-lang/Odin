package net
//+build darwin

/*
	Package net implements cross-platform Berkeley Sockets, DNS resolution and associated procedures.
	For other protocols and their features, see subdirectories of this package.
*/

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

import "core:os"
import "core:strings"

@(private)
_enumerate_interfaces :: proc(allocator := context.allocator) -> (interfaces: []Network_Interface, err: Network_Error) {
	context.allocator = allocator

	head: ^os.ifaddrs

	if res := os._getifaddrs(&head); res < 0 {
		return {}, .Unable_To_Enumerate_Network_Interfaces
	}

	/*
		Unlike Windows, *nix regrettably doesn't return all it knows about an interface in one big struct.
		We're going to have to iterate over a list and coalesce information as we go.
	*/
	ifaces: map[string]^Network_Interface
	defer delete(ifaces)

	for ifaddr := head; ifaddr != nil; ifaddr = ifaddr.next {
		adapter_name := string(ifaddr.name)

		/*
			Check if we have seen this interface name before so we can reuse the `Network_Interface`.
			Else, create a new one.
		*/
		if adapter_name not_in ifaces {
			ifaces[adapter_name] = new(Network_Interface)
			ifaces[adapter_name].adapter_name = strings.clone(adapter_name)
		}
		iface := ifaces[adapter_name]

		address: Address
		netmask: Netmask

		if ifaddr.address != nil {
			switch int(ifaddr.address.family) {
			case os.AF_INET, os.AF_INET6:
				address = _sockaddr_basic_to_endpoint(ifaddr.address).address
			}
		}

		if ifaddr.netmask != nil {
			switch int(ifaddr.netmask.family) {
			case os.AF_INET, os.AF_INET6:
				netmask = Netmask(_sockaddr_basic_to_endpoint(ifaddr.netmask).address)
			}
		}

		if ifaddr.broadcast_or_dest != nil && .BROADCAST in ifaddr.flags {
			switch int(ifaddr.broadcast_or_dest.family) {
			case os.AF_INET, os.AF_INET6:
				broadcast := _sockaddr_basic_to_endpoint(ifaddr.broadcast_or_dest).address
				append(&iface.multicast, broadcast)
			}
		}

		if address != nil {
			lease := Lease{
				address = address,
				netmask = netmask,
			}
			append(&iface.unicast, lease)
		}

		/*
			TODO: Refine this based on the type of adapter.
		*/
		state := Link_State{}

		if .UP in ifaddr.flags {
			state += {.Up}
		}

		/*if .DORMANT in ifaddr.flags {
			state |= {.Dormant}
		}*/

		if .LOOPBACK in ifaddr.flags {
			state += {.Loopback}
		}
		iface.link.state = state
	}

	/*
		Free the OS structures.
	*/
	os._freeifaddrs(head)

	/*
		Turn the map into a slice to return.
	*/
	_interfaces := make([dynamic]Network_Interface, 0, allocator)
	for _, iface in ifaces {
		append(&_interfaces, iface^)
		free(iface)
	}
	return _interfaces[:], {}
}
