//+build freebsd
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

import "core:c"
import "core:strings"
import "core:sys/freebsd"

@(private)
_enumerate_interfaces :: proc(allocator := context.allocator) -> (interfaces: []Network_Interface, err: Network_Error) {
	// This is a simplified implementation of `getifaddrs` from the FreeBSD
	// libc using only Odin and syscalls.
	context.allocator = allocator

	mib := [6]freebsd.MIB_Identifier {
		.CTL_NET,
		cast(freebsd.MIB_Identifier)freebsd.Protocol_Family.ROUTE,
		freebsd.MIB_Identifier(0),
		freebsd.MIB_Identifier(0),
		.NET_RT_IFLISTL,
		freebsd.MIB_Identifier(0),
	}

	// Figure out how much space we need.
	needed: c.size_t = ---

	errno := freebsd.sysctl(mib[:], nil, &needed, nil, 0)
	if errno != nil {
		return nil, .Unable_To_Enumerate_Network_Interfaces
	}

	// Allocate and get the entries.
	buf, alloc_err := make([]byte, needed)
	if alloc_err != nil {
		return nil, .Unable_To_Enumerate_Network_Interfaces
	}
	defer delete(buf)

	errno = freebsd.sysctl(mib[:], &buf[0], &needed, nil, 0)
	if errno != nil {
		return nil, .Unable_To_Enumerate_Network_Interfaces
	}

	// Build the interfaces with each message.
	if_builder: [dynamic]Network_Interface
	for message_pointer: uintptr = 0; message_pointer < cast(uintptr)needed; /**/ {
		rtm := cast(^freebsd.Route_Message_Header)&buf[message_pointer]
		if rtm.version != freebsd.RTM_VERSION {
			continue
		}

		#partial switch rtm.type {
		case .IFINFO:
			ifm := cast(^freebsd.Interface_Message_Header_Len)&buf[message_pointer]
			if .IFP not_in ifm.addrs {
				// No name available.
				break
			}

			dl := cast(^freebsd.Socket_Address_Data_Link)&buf[message_pointer + cast(uintptr)ifm.len]

			if_data := cast(^freebsd.Interface_Data)&buf[message_pointer + cast(uintptr)ifm.data_off]

			// This is done this way so the different message types can
			// dynamically build a `Network_Interface`.
			resize(&if_builder, max(len(if_builder), 1 + cast(int)ifm.index))
			interface := if_builder[ifm.index]

			interface.adapter_name = strings.clone_from_bytes(dl.data[0:dl.nlen])
			interface.mtu = if_data.mtu

			switch if_data.link_state {
			case .UNKNOWN: /* Do nothing; the default value is valid. */
			case .UP:   interface.link.state |= { .Up   }
			case .DOWN: interface.link.state |= { .Down }
			}

			// TODO: Uncertain if these are equivalent:
			// interface.link.transmit_speed = if_data.baudrate
			// interface.link.receive_speed = if_data.baudrate

			if dl.type == .LOOP {
				interface.link.state |= { .Loopback }
			} else {
				interface.physical_address = physical_address_to_string(dl.data[dl.nlen:][:6])
			}

			if_builder[ifm.index] = interface

		case .NEWADDR:
			RTA_MASKS :: freebsd.Route_Address_Flags { .IFA, .NETMASK }
			ifam := cast(^freebsd.Interface_Address_Message_Header_Len)&buf[message_pointer]
			if ifam.addrs & RTA_MASKS == {} {
				break
			}

			resize(&if_builder, max(len(if_builder), 1 + cast(int)ifam.index))
			interface := if_builder[ifam.index]

			address_pointer := message_pointer + cast(uintptr)ifam.len

			lease: Lease
			address_set: bool
			for address_type in ifam.addrs {
				ptr := cast(^freebsd.Socket_Address_Basic)&buf[address_pointer]

				#partial switch address_type {
				case .IFA:
					#partial switch ptr.family {
					case .INET:
						real := cast(^freebsd.Socket_Address_Internet)ptr
						lease.address = cast(IP4_Address)real.addr.addr8
						address_set = true
					case .INET6:
						real := cast(^freebsd.Socket_Address_Internet6)ptr
						lease.address = cast(IP6_Address)real.addr.addr16
						address_set = true
					}
				case .NETMASK:
					#partial switch ptr.family {
					case .INET:
						real := cast(^freebsd.Socket_Address_Internet)ptr
						lease.netmask = cast(Netmask)cast(IP4_Address)real.addr.addr8
					case .INET6:
						real := cast(^freebsd.Socket_Address_Internet6)ptr
						lease.netmask = cast(Netmask)cast(IP6_Address)real.addr.addr16
					}
				}

				SALIGN : u8 : size_of(c.long) - 1
				address_advance: uintptr = ---
				if ptr.len > 0 {
					address_advance = cast(uintptr)((ptr.len + SALIGN) & ~SALIGN)
				} else {
					address_advance = cast(uintptr)(SALIGN + 1)
				}

				address_pointer += address_advance
			}

			if address_set {
				append(&interface.unicast, lease)
			}

			if_builder[ifam.index] = interface
		}

		message_pointer += cast(uintptr)rtm.msglen
	}

	// Remove any interfaces that were allocated but had no name.
	#no_bounds_check for i := len(if_builder) - 1; i >= 0; i -= 1 {
		if len(if_builder[i].adapter_name) == 0 {
			ordered_remove(&if_builder, i)
		}
	}

	return if_builder[:], nil
}
