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

import "core:strconv"
import "core:strings"
import "core:fmt"

/*
	Expects an IPv4 address with no leading or trailing whitespace:
	- a.b.c.d
	- a.b.c.d:port
	- [a.b.c.d]:port

	If the IP address is bracketed, the port must be present and valid (though it will be ignored):
	- [a.b.c.d] will be treated as a parsing failure.

	The port, if present, is required to be a base 10 number in the range 0-65535, inclusive.

	If `allow_non_decimal` is false, `aton` is told each component must be decimal and max 255.
*/
parse_ip4_address :: proc(address_and_maybe_port: string, allow_non_decimal := false) -> (addr: IP4_Address, ok: bool) {
	res := aton(address_and_maybe_port, .IP4, !allow_non_decimal) or_return
	return res.?
}

/*
	Parses an IP address in "non-decimal" `inet_aton` form.

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
aton :: proc(address_and_maybe_port: string, family: Address_Family, allow_decimal_only := false) -> (addr: Address, ok: bool) {
	switch family {
	case .IP4:
		// There is no valid address shorter than `0.0.0.0`.
		if len(address_and_maybe_port) < 7 {
			return {}, false
		}

		address, _ := split_port(address_and_maybe_port) or_return // This call doesn't allocate

		buf: [4]u64 = {}
		i := 0

		max_value := u64(max(u32))
		bases     := DEFAULT_DIGIT_BASES

		if allow_decimal_only {
			max_value = 255
			bases     = {.Dec}
		}

		for len(address) > 0 {
			if i == 4 {
				return {}, false
			}

			// Decimal-only addresses may not have a leading zero.
			if allow_decimal_only && len(address) > 1 && address[0] == '0' && address[1] != '.' {
				return
			}

			number, consumed, number_ok := parse_ip_component(address, max_value, bases)
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

		// Distribute parts.
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
		for v, j in buf {
			if v > 255 { return {}, false }
			a[j] = u8(v)
		}
		return IP4_Address(a), true

	case .IP6:
		return parse_ip6_address(address_and_maybe_port)

	case:
		return nil, false
	}
}

/*
	The minimum length of a valid IPv6 address string is 2, e.g. `::`

	The maximum length of a valid IPv6 address string is 45, when it embeds an IPv4,
	e.g. `0000:0000:0000:0000:0000:ffff:255.255.255.255`

	An IPv6 address must contain at least 3 pieces, e.g. `::`,
	and at most 9 (using `::` for a trailing or leading 0)
*/
IPv6_MIN_STRING_LENGTH :: 2
IPv6_MAX_STRING_LENGTH :: 45
IPv6_MIN_COLONS        :: 2
IPv6_PIECE_COUNT       :: 8

parse_ip6_address :: proc(address_and_maybe_port: string) -> (addr: IP6_Address, ok: bool) {
	// If we have an IPv6 address of the form [IP]:Port, first get us just the IP.
	address, _ := split_port(address_and_maybe_port) or_return

	// Early bailouts based on length and number of pieces.
	if len(address) < IPv6_MIN_STRING_LENGTH || len(address) > IPv6_MAX_STRING_LENGTH { return }

	/*
		Do a pre-pass on the string that checks how many `:` and `.` we have,
		if they're in the right order, and if the things between them are digits as expected.

		It's not strictly necessary considering we could use `strings.split`,
		but this way we can avoid using an allocator and return earlier on bogus input. Win-win.
	*/
	colon_count  := 0
	dot_count    := 0

	pieces_temp:  [IPv6_PIECE_COUNT + 1]string

	piece_start := 0
	piece_end   := 0

	for ch, i in address {
		switch ch {
		case '0'..='9', 'a'..='f', 'A'..='F':
			piece_end += 1

		case ':':
			// If we see a `:` after a `.`, it means an IPv4 part was sandwiched between IPv6, instead of it being the tail: invalid.
			if dot_count > 0 { return }

			pieces_temp[colon_count] = address[piece_start:piece_end]

			colon_count += 1
			if colon_count > IPv6_PIECE_COUNT { return }

			// If there's anything left, put it in the next piece.
			piece_start = i + 1
			piece_end   = piece_start

		case '.':
			// IPv4 address is treated as one piece. No need to update `piece_*`.
			dot_count += 1

		case: // Invalid character, return early
			return
		}
	}

	if colon_count < IPv6_MIN_COLONS { return }

	// Assign the last piece string.
	pieces_temp[colon_count] = address[piece_start:]

	// `pieces` now holds the same output as it would if had used `strings.split`.
	pieces := pieces_temp[:colon_count + 1]

	// Check if we have what looks like an embedded IPv4 address.
	ipv4:      IP4_Address
	have_ipv4: bool

	if dot_count > 0 {
		/*
			If we have an IPv4 address accounting for the last 32 bits,
			this means we can have at most 6 IPv6 pieces, like so: `x:x:X:x:x:x:d.d.d.d`

			Or, put differently: 6 pieces IPv6 (5 colons), a colon, 1 piece IPv4 (3 dots),
			for a total of 6 colons and 3 dots.
		*/
		if dot_count != 3 || colon_count > 6 { return }

		/*
			Try to parse IPv4 address.
			If successful, we have our least significant 32 bits.
			If not, it invalidates the whole address and we can bail.
		*/
		ipv4, have_ipv4 = parse_ip4_address(pieces_temp[colon_count])
		if !have_ipv4 { return }
	}

	// Check for `::` being used more than once, and save the skip.
	zero_skip := -1
	for i in 1..<colon_count {
		if pieces[i] == "" {
			// Return if skip has already been set.
			if zero_skip != -1 { return }
			zero_skip = i
		}
	}

	/*
		Now check if we have the necessary number pieces, accounting for any `::`,
		and how many were skipped by it if applicable.
	*/
	before_skip := 0
	after_skip  := 0
	num_skipped := 0

	if zero_skip != -1 {
		before_skip = zero_skip
		after_skip  = colon_count - zero_skip

		// An IPv4 "piece" accounts for 2 IPv6 pieces we haven't added to the pieces slice, so add 1.
		if have_ipv4 {
			after_skip += 1
		}

		// Adjust for leading `::`.
		if pieces[0] == "" {
			before_skip -= 1
			// Leading `:` can only be part of `::`.
			if before_skip > 0 { return }
		}

		// Adjust for trailing `::`.
		if pieces[colon_count] == "" {
			after_skip -= 1
			// Trailing `:` can only be part of `::`.
			if after_skip > 0 { return }
		}

		/*
			Calculate how many zero pieces we skipped.
			It should be at least one, considering we encountered a `::`.
		*/
		num_skipped = IPv6_PIECE_COUNT - before_skip - after_skip
		if num_skipped < 1 { return }

	} else {
		/*
			No zero skip means everything is part of "before the skip".
			An IPv4 "piece" accounts for 2 IPv6 pieces we haven't added to the pieces slice, so add 1.
		*/
		piece_count := colon_count + 1
		if have_ipv4 {
			piece_count += 1
		}

		// Do we have the complete set?
		if piece_count != IPv6_PIECE_COUNT { return }

		// Validate leading and trailing empty parts, as they can only be part of a `::`.
		if pieces[0] == "" || pieces[colon_count] == "" { return }


		before_skip = piece_count
		after_skip  = 0
		num_skipped = 0
	}

	// Now try to parse the pieces into a 8 16-bit pieces.
	piece_values: [IPv6_PIECE_COUNT]u16be

	idx     := 0
	val_idx := 0

	for _ in 0..<before_skip {
		/*
			An empty piece is the default zero. Otherwise, try to parse as an IPv6 hex piece.
			If we have an IPv4 address, stop on the penultimate index.
		*/
		if have_ipv4 && val_idx == 6 {
			break
		}

		piece := pieces[idx]

		// An IPv6 piece can at most contain 4 hex digits.
		if len(piece) > 4 { return }

		if piece != "" {
			val, _ := parse_ip_component(piece, 65535, {.IPv6}) or_return
			piece_values[val_idx] = u16be(val)
		}

		idx     += 1
		val_idx += 1
	}

	if before_skip == 0 {
		idx += 1
	}

	if num_skipped > 0 {
		idx     += 1
		val_idx += num_skipped
	}

	if after_skip > 0 {
		for _ in 0..<after_skip {
			/*
				An empty piece is the default zero. Otherwise, try to parse as an IPv6 hex piece.
				If we have an IPv4 address, stop on the penultimate index.
			*/
			if have_ipv4 && val_idx == 6 {
				break
			}

			piece := pieces[idx]

			// An IPv6 piece can contain at most 4 hex digits.
			if len(piece) > 4 { return }

			if piece != "" {
				val, _ := parse_ip_component(piece, 65535, {.IPv6}) or_return
				piece_values[val_idx] = u16be(val)
			}

			idx     += 1
			val_idx += 1
		}
	}

	// Distribute IPv4 address into last two pieces, if applicable.
	if have_ipv4 {
		val := u16(ipv4[0]) << 8
		val |= u16(ipv4[1])
		piece_values[6] = u16be(val)

		val  = u16(ipv4[2]) << 8
		val |= u16(ipv4[3])
		piece_values[7] = u16be(val)
	}
	return IP6_Address(piece_values), true
}

/*
	Try parsing as an IPv6 address.
	If it's determined not to be, try as an IPv4 address, optionally in non-decimal format.
*/
parse_address :: proc(address_and_maybe_port: string, non_decimal_address := false) -> Address {
	if addr6, ok6 := parse_ip6_address(address_and_maybe_port); ok6 {
		return addr6
	}
	if addr4, ok4 := parse_ip4_address(address_and_maybe_port, non_decimal_address); ok4 {
		return addr4
	}
	return nil
}

parse_endpoint :: proc(endpoint_str: string) -> (ep: Endpoint, ok: bool) {
	if addr_str, port, split_ok := split_port(endpoint_str); split_ok {
		if addr := parse_address(addr_str); addr != nil {
			return Endpoint { address = addr, port = port }, true
		}
	}
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

// Takes a string consisting of a hostname or IP address, and an optional port,
// and return the component parts in a useful form.
parse_hostname_or_endpoint :: proc(endpoint_str: string) -> (target: Host_Or_Endpoint, err: Parse_Endpoint_Error) {
	host, port, port_ok := split_port(endpoint_str)
	if !port_ok {
		return nil, .Bad_Port
	}
	if addr := parse_address(host); addr != nil {
		return Endpoint{addr, port}, .None
	}
	if !validate_hostname(host) {
		return nil, .Bad_Hostname
	}
	return Host{host, port}, .None
}


// Takes an endpoint string and returns its parts.
// Returns ok=false if port is not a number.
split_port :: proc(endpoint_str: string) -> (addr_or_host: string, port: int, ok: bool) {
	// IP6 [addr_or_host]:port
	if i := strings.last_index(endpoint_str, "]:"); i >= 0 {
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
	if !ok {
		return addr_or_host
	}

	b := strings.builder_make(allocator)

	addr := parse_address(addr_or_host)
	if addr == nil {
		// hostname
		fmt.sbprintf(&b, "%v:%v", addr_or_host, port)
	} else {
		switch _ in addr {
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
	b := strings.builder_make(allocator)
	switch v in addr {
	case IP4_Address:
		fmt.sbprintf(&b, "%v.%v.%v.%v", v[0], v[1], v[2], v[3])
	case IP6_Address:
		// First find the longest run of zeroes.
		Zero_Run :: struct {
			start: int,
			end:   int,
		}

		/*
			We're dealing with 0-based indices, appropriately enough for runs of zeroes.
			Still, it means we need to initialize runs with some value outside of the possible range.
		*/
		run  := Zero_Run{-1, -1}
		best := Zero_Run{-1, -1}


		last := u16be(1)
		for val, i in v {
			/*
				If we encounter adjacent zeroes, then start a new run if not already in one.
				Also remember the rightmost index regardless, because it'll be the new
				frontier of both new and existing runs.
			*/
			if last == 0 && val == 0 {
				run.end = i
				if run.start == -1 {
					run.start = i - 1
				}
			}

			/*
				If we're in a run check if its length is better than the best recorded so far.
				If so, update the best run's start and end.
			*/
			if run.start != -1 {
				length_to_beat := best.end - best.start
				length         := run.end  - run.start

				if length > length_to_beat {
					best = run
				}
			}

			// If we were in a run, this is where we reset it.
			if val != 0 {
				run = {-1, -1}
			}

			last = val
		}

		for val, i in v {
			if best.start == i || best.end == i {
				// For the left and right side of the best zero run, print a `:`.
				fmt.sbprint(&b, ":")
			} else if i < best.start {
				/*
					If we haven't made it to the best run yet, print the digit.
					Make sure we only print a `:` after the digit if it's not
					immediately followed by the run's own leftmost `:`.
				*/
				fmt.sbprintf(&b, "%x", val)
				if i < best.start - 1 {
					fmt.sbprintf(&b, ":")
				}
			} else if i > best.end {
				/*
					If there are any digits after the zero run, print them.
					But don't print the `:` at the end of the IP number.
				*/
				fmt.sbprintf(&b, "%x", val)
				if i != 7 {
					fmt.sbprintf(&b, ":")
				}
			}
		}
	}
	return strings.to_string(b)
}

// Returns a temporarily-allocated string representation of the endpoint.
// If there's a port, uses the `ip4address:port` or `[ip6address]:port` format, respectively.
endpoint_to_string :: proc(ep: Endpoint, allocator := context.temp_allocator) -> string {
	if ep.port == 0 {
		return address_to_string(ep.address, allocator)
	} else {
		s := address_to_string(ep.address, context.temp_allocator)
		b := strings.builder_make(allocator)
		switch a in ep.address {
		case IP4_Address:  fmt.sbprintf(&b, "%v:%v",   s, ep.port)
		case IP6_Address:  fmt.sbprintf(&b, "[%v]:%v", s, ep.port)
		}
		return strings.to_string(b)
	}
}

to_string :: proc{address_to_string, endpoint_to_string}


family_from_address :: proc(addr: Address) -> Address_Family {
	switch _ in addr {
	case IP4_Address: return .IP4
	case IP6_Address: return .IP6
	case:
		unreachable()
	}
}
family_from_endpoint :: proc(ep: Endpoint) -> Address_Family {
	return family_from_address(ep.address)
}


Digit_Parse_Base :: enum u8 {
	Dec  = 0, // No prefix
	Oct  = 1, // Leading zero
	Hex  = 2, // 0x prefix
	IPv6 = 3, // Unprefixed IPv6 piece hex. Can't be used with other bases.
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
	// Default to base 10
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
		IPv6 hex bytes are unprefixed and can't be disambiguated from octal or hex unless the digit is out of range.
		If we got the `.IPv6` option, skip prefix scanning and other flags aren't also used.
	*/
	if .IPv6 in bases {
		if bases != {.IPv6} { return } // Must be used on its own.
		base = 16
	} else {
		// Scan for and consume prefix, if applicable.
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
	}

	parse_loop: for ch in input {
		switch ch {
		case '0'..='7':
			digit_bytes += 1
			value = value * base + u64(ch - '0')

		case '8'..='9':
			digit_bytes += 1

			if base == 8 {
				// Out of range for octal numbers.
				return value, digit_bytes + prefix_bytes, false
			}
			value = value * base + u64(ch - '0')

		case 'a'..='f':
			digit_bytes += 1

			if base == 8 || base == 10 {
				// Out of range for octal and decimal numbers.
				return value, digit_bytes + prefix_bytes, false
			}
			value = value * base + (u64(ch - 'a') + 10)

		case 'A'..='F':
			digit_bytes += 1

			if base == 8 || base == 10 {
				// Out of range for octal and decimal numbers.
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
			// Invalid character encountered.
			return value, digit_bytes + prefix_bytes, false
		}

		if value > max_value {
			// Out-of-range number.
			return value, digit_bytes + prefix_bytes, false
		}
	}

	// If we consumed at least 1 digit byte, `value` *should* continue a valid number in an appropriate base in the allowable range.
	return value, digit_bytes + prefix_bytes, digit_bytes >= 1
}

// Returns an address for each interface that can be bound to.
get_network_interfaces :: proc() -> []Address {
	// TODO: Implement using `enumerate_interfaces` and returning only the addresses of active interfaces.
	return nil
}
