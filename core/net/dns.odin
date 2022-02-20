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

import "core:mem"

/*
	Resolves a hostname to exactly one IPv4 and IPv6 address.
	It's then up to you which one you use.
	Note that which address you pass to `dial` determines the type of the socket you get.
  
	Returns `ok = false` if the host name could not be resolved to any addresses.
  
  
	If hostname is actually a string representation of an IP address, this function
	just parses that address and returns it.
	This allows you to pass a generic endpoint string (i.e: hostname or address) to this function end reliably get
	back the endpoint's IP address.
	e.g:
	```
		// Maybe you got this from a config file, so you
	// don't know if it's a hostname or address.
	ep_string := "localhost:9000";
  
	addr_or_host, port, split_ok := net.split_port(ep_string);
	assert(split_ok);
	port = (port == 0) ? 9000 : port; // returns zero if no port in the string.
  
	// Resolving an address just returns the address.
	addr4, addr6, resolve_ok := net.resolve(addr_or_host);
	if !resolve_ok {
		printf("error: cannot resolve %v\n", addr_or_host);
		return;
	}
	addr := addr4 != nil ? addr4 : addr6; // preferring IPv4.
	assert(addr != nil); // If resolve_ok, we'll have at least one address.
	```
*/

resolve :: proc(hostname: string, addr_types: bit_set[Addr_Type] = {.IPv4, .IPv6}) -> (addr4, addr6: Address, ok: bool) {
	if addr := parse_address(hostname); addr != nil {
		switch a in addr {
		case IPv4_Address: addr4 = addr
		case IPv6_Address: addr6 = addr
		}
		ok = true
		return
	}

	//
	// DEBUG: Why is 1024 bytes not enough when the entire map in get_dns_records is only 256 bytes?
	//

	// NOTE(tetra): We might not have used temporary storage yet,
	// and get_dns_records uses it by default.
	// Rather than require the user initialize it manually first,
	// we just use a stack-arena here instead.
	// We can do this because the addresses we return are returned by value,
	// so we don't return data from within this arena.
	buf: [4096]byte
	arena: mem.Arena
	mem.init_arena(&arena, buf[:])
	allocator := mem.arena_allocator(&arena)

	if .IPv4 in addr_types {
		recs, rec_ok := get_dns_records(hostname, .IPv4, allocator)
		if !rec_ok do return
		if len(recs) > 0 {
			addr4 = cast(IPv4_Address) recs[0].(DNS_Record_IPv4) // address is copied
		}
	}

	if .IPv6 in addr_types {
		recs, rec_ok := get_dns_records(hostname, .IPv6, allocator)
		if !rec_ok do return
		if len(recs) > 0 {
			addr6 = cast(IPv6_Address) recs[0].(DNS_Record_IPv6) // address is copied
		}
	}

	ok = addr4 != nil || addr6 != nil
	return
}
