//+build linux, darwin, !windows
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

/*
	This file uses `getifaddrs` libc call to enumerate interfaces.

	TODO: When we have raw sockets, split off into its own file for Linux so we can use the NETLINK protocol and bypass libc.
*/

import "core:c"
import "core:os"
import "core:fmt"
import "core:strings"

foreign import libc "system:c"

SIOCGIFFLAG :: enum c.int {
	UP             = 0,  /* Interface is up.  */
	BROADCAST      = 1,  /* Broadcast address valid.  */
	DEBUG          = 2,  /* Turn on debugging.  */
	LOOPBACK       = 3,  /* Is a loopback net.  */
	POINT_TO_POINT = 4,  /* Interface is point-to-point link.  */
	NO_TRAILERS    = 5,  /* Avoid use of trailers.  */
	RUNNING        = 6,  /* Resources allocated.  */
	NOARP          = 7,  /* No address resolution protocol.  */
	PROMISC        = 8,  /* Receive all packets.  */
	ALL_MULTI      = 9,  /* Receive all multicast packets.  */
	MASTER         = 10, /* Master of a load balancer.  */
	SLAVE          = 11, /* Slave of a load balancer.  */
	MULTICAST      = 12, /* Supports multicast.  */
	PORTSEL        = 13, /* Can set media type.  */
	AUTOMEDIA      = 14, /* Auto media select active.  */
	DYNAMIC        = 15, /* Dialup device with changing addresses.  */
        LOWER_UP       = 16,
        DORMANT        = 17,
        ECHO           = 18,

}
SIOCGIFFLAGS :: bit_set[SIOCGIFFLAG; c.int]

ifaddrs :: struct #packed {
	next:              ^ifaddrs,
	name:              cstring,
	flags:             SIOCGIFFLAGS,
	address:           ^os.SOCKADDR,
	netmask:           ^os.SOCKADDR,
	broadcast_or_dest: ^os.SOCKADDR,  // Broadcast or Point-to-Point address
	data:              rawptr,        // Address-specific data.

}

foreign libc {
	getifaddrs  :: proc "c" (ifap: ^^ifaddrs) -> (c.int) ---
	freeifaddrs :: proc "c" (ifa: ^ifaddrs) ---
}



/*
	`enumerate_interfaces` retrieves a list of network interfaces with their associated properties.
*/
enumerate_interfaces :: proc(allocator := context.allocator) -> (interfaces: []Network_Interface, err: Network_Error) {
	context.allocator = allocator

	head: ^ifaddrs

	if res := getifaddrs(&head); res < 0 {
		return {}, .Unable_To_Enumerate_Network_Interfaces
	}

	/*
		Unlike Windows, *nix regrettably doesn't return all it knows about an interface in one big struct.
		We're going to have to iterate over a list and coalesce information as we go.
	*/

	ifaces: map[string]^Network_Interface
	defer delete(ifaces)

	for ifaddr := head; ifaddr.next != nil; ifaddr = ifaddr.next {
		adapter_name := string(ifaddr.name)
		fmt.printf("IF: %v\n", adapter_name)

		/*
			Check if we have seen this interface name before so we can reuse the `Network_Interface`.
			Else, create a new one.
		*/
		if adapter_name not_in ifaces {
			ifaces[adapter_name] = new(Network_Interface)
			ifaces[adapter_name].adapter_name = strings.clone(adapter_name)
		}
		iface := ifaces[adapter_name]



	}

	/*
		Free the OS structures.
	*/
	freeifaddrs(head)

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