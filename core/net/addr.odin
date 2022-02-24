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

import "core:strconv"
import "core:strings"
import "core:fmt"
import "core:mem"

/*
	Aliases for convenience to those used to their C equivalents:
	- inet_ntop
	- inet_pton
*/
ntop :: address_to_string
pton :: parse_address

parse_ip4_address :: proc(address_and_maybe_port: string) -> (addr: IP4_Address, ok: bool) {
	buf: [1024]byte
	arena: mem.Arena
	mem.init_arena(&arena, buf[:])
	context.allocator = mem.arena_allocator(&arena)

	addr_str, _, split_ok := split_port(address_and_maybe_port)
	if !split_ok do return

	parts := strings.split(addr_str, ".")
	if len(parts) != 4 do return

	#assert(len(addr) == 4)

	n: uint
	for part, i in parts {
		if part == "" do return // NOTE(tetra): All elements required.
		if strings.contains(part, ":") do return
		n, ok = strconv.parse_uint(part, 10)
		if !ok do return // NOTE(tetra): Not all of it was an integer.
		if n > uint(max(u8)) do return
		addr[i] = byte(n)
	}

	ok = true
	return
}

// TODO(tetra): Scopeid?
parse_ip6_address :: proc(address_and_maybe_port: string) -> (addr: IP6_Address, ok: bool) {
	// Rule 1: If the high-byte of any block is zero, it can be omitted. (00XX => XX)
	// Rule 2: Two or more all-zero blocks in a row can be replaced with '::' (FF00:0000:0000:XXXX => FF00::XXXX)
	//         but this can only happen _once_.

	buf: [1024]byte
	arena: mem.Arena
	mem.init_arena(&arena, buf[:])
	context.allocator = mem.arena_allocator(&arena)

	addr_str, _, split_ok := split_port(address_and_maybe_port)
	if !split_ok do return

	parts := strings.split(addr_str, ":")
	if len(parts) < 3 do return
	double_colon := false
	outer: for part, i in parts {
		switch len(part) {
		case 3: return
		case 0:
			parts = parts[i:]
			double_colon = true
			break outer
		}
		n, ok := strconv.parse_uint(part, 16)
		if !ok do return // NOTE(tetra): Not all of this part was digits.
		if n > uint(max(u16)) do return
		addr[i] = u16be(u16(n))
	}

	n: uint
	if double_colon {
		loop: for _, i in parts {
			part := parts[len(parts)-1-i]
			switch len(part) {
			case 3: return
			case 0: break loop // NOTE(tetra): Zero means '::' - only one of these is allowed.
			}
			n, ok = strconv.parse_uint(part, 16)
			if !ok do return // NOTE(tetra): Not all of this part was digits.
			if n > uint(max(u16)) do return
			addr[len(addr)-1-i] = u16be(u16(n))
		}
	}
	ok = true
	return
}

parse_address :: proc(address_and_maybe_port: string) -> Address {
	addr6, ok6 := parse_ip6_address(address_and_maybe_port)
	if ok6 do return addr6
	addr4, ok4 := parse_ip4_address(address_and_maybe_port)
	if ok4 do return addr4
	return nil
}

parse_endpoint :: proc(endpoint_str: string) -> (ep: Endpoint, ok: bool) {
	addr_str, port, split_ok := split_port(endpoint_str)
	if !split_ok do return

	addr := parse_address(addr_str)
	if addr == nil do return

	ep = Endpoint { address = addr, port = port }
	ok = true
	return
}

Host :: struct {
	hostname: string,
	port:     int,
}
Host_Or_Endpoint :: union {
	Host,
	Endpoint,
}
Parse_Endpoint_Error :: enum {
	Bad_Port = 1,
	Bad_Address,
	Bad_Hostname,
}

// Takes a string consisting of a hostname or IP address, and an optional port,
// and return the component parts in a useful form.
parse_hostname_or_endpoint :: proc(endpoint_str: string) -> (target: Host_Or_Endpoint, err: Network_Error) {
	host, port, port_ok := split_port(endpoint_str)
	if !port_ok {
		return nil, .Bad_Port
	}
	if addr := parse_address(host); addr != nil {
		return Endpoint{addr, port}, nil
	}
	if !validate_hostname(host) {
		return nil, .Bad_Hostname
	}
	return Host{host, port}, nil
}


// Takes an endpoint string and returns its parts.
// Returns ok=false if port is not a number.
split_port :: proc(endpoint_str: string) -> (addr_or_host: string, port: int, ok: bool) {
	// IP6 [addr_or_host]:port
	if i := strings.last_index(endpoint_str, "]:"); i != -1 {
		addr_or_host = endpoint_str[1:i]
		port, ok = strconv.parse_int(endpoint_str[i+2:], 10)
		return
	}

	if n := strings.count(endpoint_str, ":"); n == 1 {
		// IP4 addr_or_host:port
		i := strings.last_index(endpoint_str, ":")
		assert(i != -1)

		addr_or_host = endpoint_str[:i]
		port, ok = strconv.parse_int(endpoint_str[i+1:], 10)
		return
	} else if n > 1 {
		// IP6 address without port
	}

	// No port
	addr_or_host = endpoint_str
	port = 0
	ok = true
	return
}

// Joins an address or hostname with a port.
join_port :: proc(address_or_host: string, port: int, allocator := context.allocator) -> string {
	addr_or_host, _, ok := split_port(address_or_host)
	if !ok do return addr_or_host

	b := strings.make_builder(allocator)

	addr := parse_address(addr_or_host)
	if addr == nil {
		// hostname
		fmt.sbprintf(&b, "%v:%v", addr_or_host, port)
	} else {
		switch in addr {
		case IP4_Address:
			fmt.sbprintf(&b, "%v:%v", address_to_string(addr), port)
		case IP6_Address:
			fmt.sbprintf(&b, "[%v]:%v", address_to_string(addr), port)
		}
	}
	return strings.to_string(b)
}



// TODO(tetra): Do we need this?
map_to_ip6 :: proc(addr: Address) -> Address {
	if addr6, ok := addr.(IP6_Address); ok {
		return addr6
	}
	addr4 := addr.(IP4_Address)
	addr4_u16 := transmute([2]u16be) addr4
	addr6: IP6_Address
	addr6[4] = 0xffff
	copy(addr6[5:], addr4_u16[:])
	return addr6
}


// Returns a temporarily-allocated string representation of the address.
address_to_string :: proc(addr: Address, allocator := context.temp_allocator) -> string {
	b := strings.make_builder(allocator)
	switch v in addr {
	case IP4_Address:
		fmt.sbprintf(&b, "%v.%v.%v.%v", v[0], v[1], v[2], v[3])
	case IP6_Address:
		// fmt.printf("Converting: %v\n", v)
		i := 0
		seen_double_colon := false
		for i < len(v) {
			if !seen_double_colon && v[i] == 0 && i < len(v) - 1 && v[i+1] == 0 {
				seen_double_colon = true
				for i < len(v) && v[i] == 0 {
					i += 1
				}
				fmt.sbprintf(&b, "::")
			} else if i > 0 {
				fmt.sbprint(&b, ":")
			}

			if i < len(v) {
				fmt.sbprintf(&b, "%x", v[i])
				i += 1
			}
		}
		if !seen_double_colon && v[7] == 0 {
			// turn single trailing zero into ::
			b.buf[len(b.buf) - 1] = ':'
		}
	}

	return strings.to_string(b)
}

// Returns a temporarily-allocated string representation of the endpoint.
// If there's a port, uses the `[address]:port` format.
endpoint_to_string :: proc(ep: Endpoint, allocator := context.temp_allocator) -> string {
	if ep.port == 0 {
		return address_to_string(ep.address, allocator)
	} else {
		s := address_to_string(ep.address, context.temp_allocator)
		b := strings.make_builder(allocator)
		switch a in ep.address {
		case IP4_Address:  fmt.sbprintf(&b, "%v:%v",   s, ep.port)
		case IP6_Address:  fmt.sbprintf(&b, "[%v]:%v", s, ep.port)
		}
		return strings.to_string(b)
	}
}

to_string :: proc{address_to_string, endpoint_to_string}


family_from_address :: proc(addr: Address) -> Address_Family {
	switch in addr {
	case IP4_Address: return .IP4
	case IP6_Address: return .IP6
	case:
		unreachable()
	}
}
family_from_endpoint :: proc(ep: Endpoint) -> Address_Family {
	return family_from_address(ep.address)
}