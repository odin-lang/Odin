package net

import "core:strconv"
import "core:strings"
import "core:fmt"
import "core:mem"

 // TODO(tetra): Bluetooth addresses not currently supported!
Ipv4_Address :: distinct [4]u8;
Ipv6_Address :: distinct [8]u16be;
Address :: union {Ipv4_Address, Ipv6_Address};

Addr_Type :: enum {
	Ipv4,
	Ipv6,
}

@static Ipv4_Loopback := Ipv4_Address{127, 0, 0, 1};
@static Ipv6_Loopback := Ipv6_Address{0, 0, 0, 0, 0, 0, 0, 1};

@static Ipv4_Any := Ipv4_Address{};
@static Ipv6_Any := Ipv6_Address{};

parse_ipv4_addr :: proc(address_and_maybe_port: string) -> (addr: Ipv4_Address, ok: bool) {
	buf: [1024]byte;
	arena: mem.Arena;
	mem.init_arena(&arena, buf[:]);
	context.allocator = mem.arena_allocator(&arena);

	addr_str, _, split_ok := split_port(address_and_maybe_port);
	if !split_ok do return;

	parts := strings.split(addr_str, ".");
	if len(parts) != 4 do return;

	#assert(len(addr) == 4);

	for part, i in parts {
		if part == "" do return; // NOTE(tetra): All elements required.
		if strings.contains(part, ":") do return;
		n, ok := strconv.parse_uint(part, 10);
		if !ok do return; // NOTE(tetra): Not all of it was an integer.
		if n < 0 || n > uint(max(u8)) do return;
		addr[i] = byte(n);
	}

	ok = true;
	return;
}

// TODO(tetra): Scopeid?
parse_ipv6_addr :: proc(address_and_maybe_port: string) -> (addr: Ipv6_Address, ok: bool) {
	// Rule 1: If the high-byte of any block is zero, it can be omitted. (00XX => XX)
	// Rule 2: Two or more all-zero blocks in a row can be replaced with '::' (FF00:0000:0000:XXXX => FF00::XXXX)
	//         but this can only happen _once_.

	buf: [1024]byte;
	arena: mem.Arena;
	mem.init_arena(&arena, buf[:]);
	context.allocator = mem.arena_allocator(&arena);

	addr_str, _, split_ok := split_port(address_and_maybe_port);
	if !split_ok do return;

	parts := strings.split(addr_str, ":");
	if len(parts) < 3 do return;

	double_colon := false;
	outer: for part, i in parts {
		switch len(part) {
		case 3: return;
		case 0:
			parts = parts[i:];
			double_colon = true;
			break outer;
		}
		n, ok := strconv.parse_uint(part, 16);
		if !ok do return; // NOTE(tetra): Not all of this part was digits.
		n16 := u16(n);
		if n16 >= max(u16) do return;
		addr[i] = u16be(n16);
	}

	if double_colon {
		loop: for _, i in parts {
			part := parts[len(parts)-1-i];
			switch len(part) {
			case 3: return;
			case 0: break loop; // NOTE(tetra): Zero means '::' - only one of these is allowed.
			}
			n, ok := strconv.parse_uint(part, 16);
			if !ok do return; // NOTE(tetra): Not all of this part was digits.
			n16 := u16(n);
			if n16 >= max(u16) do return;
			addr[len(addr)-1-i] = u16be(n16);
		}
	}
	ok = true;
	return;
}

parse_addr :: proc(address_and_maybe_port: string) -> Address {
	addr6, ok6 := parse_ipv6_addr(address_and_maybe_port);
	if ok6 do return addr6;
	addr4, ok4 := parse_ipv4_addr(address_and_maybe_port);
	if ok4 do return addr4;
	return nil;
}



Endpoint :: struct {
	addr: Address,
	port: int,
}

parse_endpoint :: proc(address: string) -> (ep: Endpoint, ok: bool) {
	addr_str, port, split_ok := split_port(address);
	if !split_ok do return;

	addr := parse_addr(addr_str);
	if addr == nil do return;

	ep = Endpoint { addr = addr, port = port };
	ok = true;
	return;
}


// Takes an endpoint string and returns its parts.
// Returns ok=false if port is not a number.
split_port :: proc(endpoint_str: string) -> (addr_or_host: string, port: int, ok: bool) {
	// Ipv6 [addr_or_host]:port
	if i := strings.last_index(endpoint_str, "]:"); i != -1 {
		addr_or_host = endpoint_str[1:i];
		port, ok = strconv.parse_int(endpoint_str[i+2:], 10);
		return;
	}

	// Ipv4 addr_or_host:port
	if n := strings.count(endpoint_str, ":"); n == 1 {
		i := strings.last_index(endpoint_str, ":");
		assert(i != -1);

		addr_or_host = endpoint_str[:i];
		port, ok = strconv.parse_int(endpoint_str[i+1:], 10);
		return;
	} else if n > 1 {
		return;
	}

	// No port
	addr_or_host = endpoint_str;
	port = 0;
	ok = true;
	return;
}

// Joins an address or hostname with a port.
join_port :: proc(address_or_host: string, port: int, allocator := context.allocator) -> string {
	addr_or_host, _, ok := split_port(address_or_host);
	if !ok do return addr_or_host;

	b := strings.make_builder(allocator);

	addr := parse_addr(addr_or_host);
	if addr == nil {
		// hostname
		fmt.sbprintf(&b, "%v:%v", addr_or_host, port);
	} else {
		switch in addr {
		case Ipv4_Address:
			fmt.sbprintf(&b, "%v:%v", addr_to_string(addr), port);
		case Ipv6_Address:
			fmt.sbprintf(&b, "[%v]:%v", addr_to_string(addr), port);
		}
	}
	return strings.to_string(b);
}



// TODO(tetra): Do we need this?
map_to_ipv6 :: proc(addr: Address) -> Address {
	if addr6, ok := addr.(Ipv6_Address); ok {
		return addr6;
	}
	addr4 := addr.(Ipv4_Address);
	addr4_u16 := transmute([2]u16be) addr4;
	addr6: Ipv6_Address;
	addr6[4] = 0xffff;
	copy(addr6[5:], addr4_u16[:]);
	return addr6;
}


// Returns a temporarily-allocated string representation of the address.
addr_to_string :: proc(addr: Address, allocator := context.temp_allocator) -> string {
	b := strings.make_builder(allocator);
	switch v in addr {
	case Ipv4_Address:
		fmt.sbprintf(&b, "%v.%v.%v.%v", v[0], v[1], v[2], v[3]);
	case Ipv6_Address:
		i := 0;
		seen_double_colon := false;
		for i < len(v) {
			if !seen_double_colon && v[i] == 0 && v[i+1] == 0 {
				seen_double_colon = true;
				for i < len(v) && v[i] == 0 {
					i += 1;
				}
				fmt.sbprintf(&b, "::");
				break; // TODO: do we need this?
			} else if i > 0 {
				fmt.sbprint(&b, ":");
			}

			fmt.sbprintf(&b, "%x", v[i]);
			i += 1;
		}
	}

	return strings.to_string(b);
}

// Returns a temporarily-allocated string representation of the endpoint.
// If there's a port, uses the `[addr]:port` format.
endpoint_to_string :: proc(ep: Endpoint, allocator := context.temp_allocator) -> (s: string) {
	s = addr_to_string(ep.addr, allocator);
	if ep.port != 0 {
		b := strings.make_builder(allocator);
		switch a in ep.addr {
		case Ipv4_Address:  fmt.sbprintf(&b, "%v:%v",   s, ep.port);
		case Ipv6_Address:  fmt.sbprintf(&b, "[%v]:%v", s, ep.port);
		}
		s = strings.to_string(b);
	}
	return;
}

to_string :: proc{addr_to_string, endpoint_to_string};