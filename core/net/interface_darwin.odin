#+build darwin
package net

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
*/

import "core:strings"
import "core:sys/posix"

foreign import lib "system:System.framework"

@(private)
_enumerate_interfaces :: proc(allocator := context.allocator) -> (interfaces: []Network_Interface, err: Interfaces_Error) {
	context.allocator = allocator

	head: ^ifaddrs
	if getifaddrs(&head) != .OK {
		return {}, .Unable_To_Enumerate_Network_Interfaces
	}
	defer freeifaddrs(head)

	ifaces: map[string]Network_Interface
	defer delete(ifaces)

	for ifaddr := head; ifaddr != nil; ifaddr = ifaddr.next {
		adapter_name := string(ifaddr.name)

		key_ptr, iface, inserted, mem_err := map_entry(&ifaces, adapter_name)
		if mem_err == nil && inserted {
			key_ptr^, mem_err = strings.clone(adapter_name)
			iface.adapter_name = key_ptr^
		}
		if mem_err != nil {
			return {}, .Allocation_Failure
		}

		address: Address
		netmask: Netmask

		if ifaddr.addr != nil {
			#partial switch ifaddr.addr.sa_family {
			case .INET, .INET6:
				address = _sockaddr_basic_to_endpoint(ifaddr.addr).address
			}
		}

		if ifaddr.netmask != nil {
			#partial switch ifaddr.netmask.sa_family {
			case .INET, .INET6:
				netmask = Netmask(_sockaddr_basic_to_endpoint(ifaddr.netmask).address)
			}
		}

		if ifaddr.dstaddr != nil && .BROADCAST in ifaddr.flags {
			#partial switch ifaddr.dstaddr.sa_family {
			case .INET, .INET6:
				broadcast := _sockaddr_basic_to_endpoint(ifaddr.dstaddr).address
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

	interfaces = make([]Network_Interface, len(ifaces))
	i: int
	for _, iface in ifaces {
		interfaces[i] = iface
		i += 1
	}
	return interfaces, nil
}

@(private)
IF_Flag :: enum u32 {
	UP,
	BROADCAST,
	DEBUG,
	LOOPBACK,
	POINTTOPOINT,
	NOTRAILERS,
	RUNNING,
	NOARP,
	PROMISC,
	ALLMULTI,
	OACTIVE,
	SIMPLEX,
	LINK0,
	LINK1,
	LINK2,
	MULTICAST,
}

@(private)
IF_Flags :: bit_set[IF_Flag; u32]

@(private)
ifaddrs :: struct {
	next:    ^ifaddrs,
	name:    cstring,
	flags:   IF_Flags,
	addr:    ^posix.sockaddr,
	netmask: ^posix.sockaddr,
	dstaddr: ^posix.sockaddr,
	data:    rawptr,
}

@(private)
foreign lib {
	getifaddrs  :: proc(ifap: ^^ifaddrs) -> posix.result ---
	freeifaddrs :: proc(ifp: ^ifaddrs) ---
}
