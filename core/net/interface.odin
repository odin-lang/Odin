// +build windows, linux, darwin, freebsd
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

MAX_INTERFACE_ENUMERATION_TRIES :: 3

/*
	`enumerate_interfaces` retrieves a list of network interfaces with their associated properties.
*/
enumerate_interfaces :: proc(allocator := context.allocator) -> (interfaces: []Network_Interface, err: Network_Error) {
	return _enumerate_interfaces(allocator)
}

/*
	`destroy_interfaces` cleans up a list of network interfaces retrieved by e.g. `enumerate_interfaces`.
*/
destroy_interfaces :: proc(interfaces: []Network_Interface, allocator := context.allocator) {
	context.allocator = allocator

	for i in interfaces {
		delete(i.adapter_name)
		delete(i.friendly_name)
		delete(i.description)
		delete(i.dns_suffix)

		delete(i.physical_address)

		delete(i.unicast)
		delete(i.multicast)
		delete(i.anycast)
		delete(i.gateways)
	}
	delete(interfaces, allocator)
}

/*
	Turns a slice of bytes (from e.g. `get_adapters_addresses`) into a "XX:XX:XX:..." string.
*/
physical_address_to_string :: proc(phy_addr: []u8, allocator := context.allocator) -> (phy_string: string) {
	context.allocator = allocator

	MAC_HEX := "0123456789ABCDEF"

	if len(phy_addr) == 0 {
		return ""
	}

	buf: strings.Builder

	for b, i in phy_addr {
		if i > 0 {
			strings.write_rune(&buf, ':')
		}

		hi := rune(MAC_HEX[b >> 4])
		lo := rune(MAC_HEX[b & 15])
		strings.write_rune(&buf, hi)
		strings.write_rune(&buf, lo)
	}
	return strings.to_string(buf)
}
