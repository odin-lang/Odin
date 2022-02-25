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
	Parses an IP address in non-decimal `inet_aton` form.

	e.g."00377.0x0ff.65534" = 255.255.255.254
		00377 = 255 in octal
		0x0ff = 255 in hexadecimal
		This leaves 16 bits worth of address
		.65534 then accounts for the last two digits

	For the address part the allowed forms are:
		a.b.c.d - where each part represents a byte
		a.b.c   - where `a` & `b` represent a byte and `c` a u16
		a.b     - where `a` represents a byte and `b` supplies the trailing 24 bits
		a       - where `a` gives the entire 32-bit value

	The port, if present, is required to be a base 10 number in the range 0-65535, inclusive.
*/
aton :: proc(address_and_maybe_port: string, family: Address_Family) -> (addr: Address, ok: bool) {
	switch family {
	case .IP4:
		/*
			There is no valid address shorter than `0.0.0.0`.
		*/
		if len(address_and_maybe_port) < 7 {
			return {}, false
		}

		address, _ := split_port(address_and_maybe_port) or_return // This call doesn't allocate

		buf: [4]u64 = {}
		i := 0

		for len(address) > 0 {
			if i == 4 {
				return {}, false
			}

			number, consumed, number_ok := parse_ip_component(address)
			if !number_ok || consumed == 0 {
				return {}, false
			}

			buf[i] = number

			address = address[consumed:]

			if len(address) > 0 && address[0] == '.' {
				address = address[1:]
			}
			i += 1
		}

		/*
			Distribute parts.
		*/
		switch i {
		case 1:
			buf[1] = buf[0] & 0xffffff
			buf[0] >>= 24
			fallthrough
		case 2:
			buf[2] = buf[1] & 0xffff
			buf[1] >>= 16
			fallthrough
		case 3:
			buf[3] = buf[2] & 0xff
			buf[2] >>= 8
		}

		a: [4]u8 = ---
		for v, i in buf {
			if v > 255 { return {}, false }
			a[i] = u8(v)
		}
		return IP4_Address(a), true

	case .IP6:
		return parse_ip6_address(address_and_maybe_port)

	case:
		return nil, false
	}
}

Digit_Parse_Base :: enum u8 {
	Dec = 0,
	Oct = 1,
	Hex = 2,
}
Digit_Parse_Bases :: bit_set[Digit_Parse_Base; u8]

DEFAULT_DIGIT_BASES :: Digit_Parse_Bases{.Dec, .Oct, .Hex}

/*
	Parses a single unsigned number in requested `bases` from `input`.
	`max_value` represents the maximum allowed value for this number.

	Returns the `value`, the `bytes_consumed` so far, and `ok` to signal success or failure.

	An out-of-range or invalid number will return the accumulated value so far (which can be out of range),
	the number of bytes consumed leading up the error, and `ok = false`.

	When `.` or `:` are encountered, they'll be considered valid separators and will stop parsing,
	returning the valid number leading up to it.

	Other non-digit characters are treated as an error.

	Octal numbers are expected to have a leading zero, with no 'o' format specifier.
	Hexadecimal numbers are expected to be preceded by '0x' or '0X'.
	Numbers will otherwise be considered to be in base 10.
*/
parse_ip_component :: proc(input: string, max_value := u64(max(u32)), bases := DEFAULT_DIGIT_BASES) -> (value: u64, bytes_consumed: int, ok: bool) {
	/*
		Default to base 10
	*/
	base         := u64(10)
	input        := input

	/*
		We keep track of the number of prefix bytes and digit bytes separately.
		This way if a prefix is consumed and we encounter a separator or the end of the string,
		the number is only considered valid if at least 1 digit byte has been consumed and the value is within range.
	*/
	prefix_bytes := 0
	digit_bytes  := 0

	/*
		Scan for and consume prefix, if applicable.
	*/
	if len(input) >= 2 && input[0] == '0' {
		if .Hex in bases && (input[1] == 'x' || input[1] == 'X') {
			base         = 16
			input        = input[2:]
			prefix_bytes = 2
		}
		if prefix_bytes == 0 && .Oct in bases {
			base         = 8
			input        = input[1:]
			prefix_bytes = 1
		}
	}

	parse_loop: for ch in input {
		switch ch {
		case '0'..'7':
			digit_bytes += 1
			value = value * base + u64(ch - '0')

		case '8'..'9':
			digit_bytes += 1

			if base == 8 {
				/*
					Out of range for octal numbers.
				*/
				return value, digit_bytes + prefix_bytes, false
			}
			value = value * base + u64(ch - '0')

		case 'a'..'f':
			digit_bytes += 1

			if base == 8 || base == 10 {
				/*
					Out of range for octal and decimal numbers.
				*/
				return value, digit_bytes + prefix_bytes, false
			}
			value = value * base + (u64(ch - 'a') + 10)

		case 'A'..'F':
			digit_bytes += 1

			if base == 8 || base == 10 {
				/*
					Out of range for octal and decimal numbers.
				*/
				return value, digit_bytes + prefix_bytes, false
			}
			value = value * base + (u64(ch - 'A') + 10)

		case '.', ':':
			/*
				Number separator. Return early.
				We don't need to check if the number is in range.
				We do that each time through the loop.
			*/
			break parse_loop

		case:
			/*
				Invalid character encountered.
			*/
			return value, digit_bytes + prefix_bytes, false
		}

		if value > max_value {
			/*
				Out-of-range number.
			*/
			return value, digit_bytes + prefix_bytes, false
		}
	}

	/*
		If we consumed at least 1 digit byte, `value` *should* continue a valid number in an appropriate base in the allowable range.
	*/
	return value, digit_bytes + prefix_bytes, digit_bytes >= 1
}

/*
	Expects an IPv4 address with no leading or trailing whitespace:
	- a.b.c.d
	- a.b.c.d:port
	- [a.b.c.d]:port

	If the IP address is bracketed, the port must be present and valid (though it will be ignored):
	- [a.b.c.d] will be treated as a parsing failure.

	The port, if present, is required to be a base 10 number in the range 0-65535, inclusive.

	If `non_decimal_address` is true, `aton` is called.
*/
parse_ip4_address :: proc(address_and_maybe_port: string, non_decimal_address := false) -> (addr: IP4_Address, ok: bool) {
	if non_decimal_address {
		res, res_ok := aton(address_and_maybe_port, .IP4)
		if ip4, ip4_ok := res.(IP4_Address); ip4_ok {
			return ip4, res_ok
		}
		return {}, false
	}

	/*
		There is no valid address shorter than `0.0.0.0`.
	*/
	if len(address_and_maybe_port) < 7 {
		return {}, false
	}

	address, _ := split_port(address_and_maybe_port) or_return // This call doesn't allocate

	// base 64 so this works on 32-bit platforms as well.
	parts: [4]u64
	part := 0

	is_leading_digit := true

	for ch in address {
		switch ch {
		case '0':
			parts[part] = parts[part] * 10
			is_leading_digit = false

		case '1'..'9':
			parts[part] = parts[part] * 10 + u64(ch - '0')
			is_leading_digit = false

		case '.':
			if is_leading_digit {
				// We're expecting a digit, not a dot
				return {}, false
			}

			part += 1
			if part > 3 {
				// Can't have an IPv4 address with 4 dots.
				return {}, false
			}

			is_leading_digit = true

		case:
			return {}, false
		}

		if parts[part] > 255 {
			return {}, false
		}
	}

	/*
		Can't end expecting a leading digit.
	*/
	if is_leading_digit {
		return {}, false
	}

	// fmt.printf("Input: %v, Parsed: %v\n", address_and_maybe_port, parts)
	return {u8(parts[0]), u8(parts[1]), u8(parts[2]), u8(parts[3])}, true
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

/*
	Try parsing as an IPv6 address.
	If it's determined not to be, try as an IPv4 address, optionally in non-decimal format.
*/
parse_address :: proc(address_and_maybe_port: string, non_decimal_address := false) -> Address {
	addr6, ok6 := parse_ip6_address(address_and_maybe_port)
	if ok6 do return addr6
	addr4, ok4 := parse_ip4_address(address_and_maybe_port, non_decimal_address)
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

		if port > 65535 {
			ok = false
		}
		return
	}

	if n := strings.count(endpoint_str, ":"); n == 1 {
		// IP4 addr_or_host:port
		i := strings.last_index(endpoint_str, ":")
		assert(i != -1)

		addr_or_host = endpoint_str[:i]
		port, ok = strconv.parse_int(endpoint_str[i+1:], 10)

		if port > 65535 {
			ok = false
		}
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


/*
	Returns a temporarily-allocated string representation of the address.

	See RFC 5952 section 4 for IPv6 representation recommendations.
*/
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