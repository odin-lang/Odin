package net

import "base:intrinsics"
import "base:runtime"
import "core:slice"
import "core:strings"

ip4_to_u32 :: proc "contextless" (address: IP4_Address) -> u32 {
	return u32(transmute(u32be)address)
}

ip4_from_u32 :: proc "contextless" (value: u32) -> IP4_Address {
	return transmute(IP4_Address)u32be(value)
}

ip6_to_u128 :: proc "contextless" (address: IP6_Address) -> u128 {
	return u128(transmute(u128be)address)
}

ip6_from_u128 :: proc "contextless" (value: u128) -> IP6_Address {
	return transmute(IP6_Address)u128be(value)
}

address_compare :: proc(a, b: Address) -> int {
	a_value, a_bits := _address_value(a)
	b_value, b_bits := _address_value(b)
	switch {
	case a_bits  < b_bits:  return -1
	case a_bits  > b_bits:  return  1
	case a_value < b_value: return -1
	case a_value > b_value: return  1
	}
	return 0
}

address_next :: proc(address: Address) -> (next: Address, ok: bool) {
	value, bits := _address_value(address)
	if bits == 0 || value == _all_ones(bits) {
		return
	}
	return _address_from_value(value + 1, bits), true
}

address_prev :: proc(address: Address) -> (prev: Address, ok: bool) {
	value, bits := _address_value(address)
	if bits == 0 || value == 0 {
		return
	}
	return _address_from_value(value - 1, bits), true
}

parse_prefix :: proc(prefix_string: string, strict := false) -> (prefix: Prefix, ok: bool) {
	if strings.contains_rune(prefix_string, ':') {
		return parse_ip6_prefix(prefix_string, strict)
	}
	return parse_ip4_prefix(prefix_string, strict)
}

parse_ip4_prefix :: proc(prefix_string: string, strict := false) -> (prefix: IP4_Prefix, ok: bool) {
	address_string, length := _split_prefix_length(prefix_string, 32) or_return
	if strings.count(address_string, ".") != 3 || strings.contains_any(address_string, ":[]") {
		return
	}
	address := parse_ip4_address(address_string) or_return
	prefix = IP4_Prefix{address, length}
	if strict && !prefix_is_canonical(prefix) {
		return {}, false
	}
	return prefix, true
}

parse_ip6_prefix :: proc(prefix_string: string, strict := false) -> (prefix: IP6_Prefix, ok: bool) {
	address_string, length := _split_prefix_length(prefix_string, 128) or_return
	if strings.contains_any(address_string, "[]%") {
		return
	}
	address := parse_ip6_address(address_string) or_return
	prefix = IP6_Prefix{address, length}
	if strict && !prefix_is_canonical(prefix) {
		return {}, false
	}
	return prefix, true
}

parse_range :: proc(range_string: string) -> (range: Address_Range, ok: bool) {
	dash := strings.index_byte(range_string, '-')
	if dash < 0 {
		return
	}
	first_string := range_string[:dash]
	last_string  := range_string[dash + 1:]
	if strings.contains_any(range_string, "[]%/") {
		return
	}
	if strings.contains_rune(range_string, ':') {
		first := parse_ip6_address(first_string) or_return
		last  := parse_ip6_address(last_string)  or_return
		return range_make(first, last)
	}
	if strings.count(first_string, ".") != 3 || strings.count(last_string, ".") != 3 {
		return
	}
	first := parse_ip4_address(first_string) or_return
	last  := parse_ip4_address(last_string)  or_return
	return range_make(first, last)
}

prefix_to_string_allocator :: proc(prefix: Prefix, allocator := context.temp_allocator) -> string {
	b := strings.builder_make(allocator)
	return prefix_to_string_builder(prefix, &b)
}

prefix_to_string_builder :: proc(prefix: Prefix, b: ^strings.Builder) -> string {
	switch v in prefix {
	case IP4_Prefix:
		address_to_string_builder(v.address, b)
		strings.write_byte(b, '/')
		strings.write_uint(b, uint(v.length))
	case IP6_Prefix:
		address_to_string_builder(v.address, b)
		strings.write_byte(b, '/')
		strings.write_uint(b, uint(v.length))
	}
	return strings.to_string(b^)
}

prefix_to_string :: proc{prefix_to_string_allocator, prefix_to_string_builder}

range_to_string_allocator :: proc(range: Address_Range, allocator := context.temp_allocator) -> string {
	b := strings.builder_make(allocator)
	return range_to_string_builder(range, &b)
}

range_to_string_builder :: proc(range: Address_Range, b: ^strings.Builder) -> string {
	switch v in range {
	case IP4_Range:
		address_to_string_builder(v.first, b)
		strings.write_byte(b, '-')
		address_to_string_builder(v.last, b)
	case IP6_Range:
		address_to_string_builder(v.first, b)
		strings.write_byte(b, '-')
		address_to_string_builder(v.last, b)
	}
	return strings.to_string(b^)
}

range_to_string :: proc{range_to_string_allocator, range_to_string_builder}

prefix_masked :: proc(prefix: Prefix) -> Prefix {
	first, _, length, bits, ok := _prefix_span(prefix)
	if !ok {
		return nil
	}
	return _prefix_from_value(first, length, bits)
}

prefix_is_canonical :: proc(prefix: Prefix) -> bool {
	value, length, bits, ok := _prefix_value(prefix)
	return ok && value & _host_mask(length, bits) == 0
}

prefix_from_address :: proc(address: Address, length: int) -> (prefix: Prefix, ok: bool) {
	value, bits := _address_value(address)
	if bits == 0 || length < 0 || length > int(bits) {
		return
	}
	return _prefix_from_value(value, u8(length), bits), true
}

prefix_from_lease :: proc(lease: Lease) -> (prefix: Prefix, ok: bool) {
	_, address_bits := _address_value(lease.address)
	_, netmask_bits := _address_value(Address(lease.netmask))
	if address_bits == 0 || address_bits != netmask_bits {
		return
	}
	length := length_from_netmask(lease.netmask) or_return
	return prefix_from_address(lease.address, length)
}

netmask_from_length :: proc(family: Address_Family, length: int) -> (netmask: Netmask, ok: bool) {
	bits := _family_bits(family)
	if bits == 0 || length < 0 || length > int(bits) {
		return
	}
	return Netmask(_address_from_value(_network_mask(u8(length), bits), bits)), true
}

hostmask_from_length :: proc(family: Address_Family, length: int) -> (hostmask: Address, ok: bool) {
	bits := _family_bits(family)
	if bits == 0 || length < 0 || length > int(bits) {
		return
	}
	return _address_from_value(_host_mask(u8(length), bits), bits), true
}

length_from_netmask :: proc(netmask: Netmask) -> (length: int, ok: bool) {
	value, bits := _address_value(Address(netmask))
	if bits == 0 {
		return
	}
	host := ~value & _all_ones(bits)
	if host & (host + 1) != 0 {
		return
	}
	return int(bits) - int(intrinsics.count_ones(host)), true
}

prefix_netmask :: proc(prefix: Prefix) -> Netmask {
	_, length, bits, ok := _prefix_value(prefix)
	if !ok {
		return nil
	}
	return Netmask(_address_from_value(_network_mask(length, bits), bits))
}

prefix_hostmask :: proc(prefix: Prefix) -> Address {
	_, length, bits, ok := _prefix_value(prefix)
	if !ok {
		return nil
	}
	return _address_from_value(_host_mask(length, bits), bits)
}

network_address :: proc(prefix: Prefix) -> Address {
	first, _, _, bits, ok := _prefix_span(prefix)
	if !ok {
		return nil
	}
	return _address_from_value(first, bits)
}

last_address :: proc(prefix: Prefix) -> Address {
	_, last, _, bits, ok := _prefix_span(prefix)
	if !ok {
		return nil
	}
	return _address_from_value(last, bits)
}

broadcast_address :: proc(prefix: Prefix) -> (broadcast: IP4_Address, ok: bool) {
	_, last, length, bits, span_ok := _prefix_span(prefix)
	if !span_ok || bits != 32 || length > 30 {
		return
	}
	return ip4_from_u32(u32(last)), true
}

is_directed_broadcast :: proc(prefix: Prefix, address: Address) -> bool {
	broadcast, ok := broadcast_address(prefix)
	v, is_ip4 := address.(IP4_Address)
	return ok && is_ip4 && v == broadcast
}

first_host :: proc(prefix: Prefix, include_anycast := false) -> Address {
	first, _, length, bits, ok := _prefix_span(prefix)
	if !ok {
		return nil
	}
	if (bits == 32 && length <= 30) || (bits == 128 && length <= 126 && !include_anycast) {
		first += 1
	}
	return _address_from_value(first, bits)
}

last_host :: proc(prefix: Prefix) -> Address {
	_, last, length, bits, ok := _prefix_span(prefix)
	if !ok {
		return nil
	}
	if bits == 32 && length <= 30 {
		last -= 1
	}
	return _address_from_value(last, bits)
}

address_count :: proc(prefix: Prefix) -> (count: u128, ok: bool) {
	_, length, bits, prefix_ok := _prefix_value(prefix)
	if !prefix_ok || bits - length == 128 {
		return
	}
	return u128(1) << (bits - length), true
}

host_count :: proc(prefix: Prefix, include_anycast := false) -> (count: u128, ok: bool) {
	_, length, bits, prefix_ok := _prefix_value(prefix)
	if !prefix_ok {
		return
	}
	host_bits := bits - length
	switch {
	case bits == 32 && length <= 30:
		return (u128(1) << host_bits) - 2, true
	case bits == 128 && length <= 126 && !include_anycast:
		return _host_mask(length, bits), true
	case host_bits == 128:
		return
	}
	return u128(1) << host_bits, true
}

prefix_contains :: proc(prefix: Prefix, address: Address) -> bool {
	first, last, _, bits, ok := _prefix_span(prefix)
	value, address_bits := _address_value(address)
	return ok && bits == address_bits && value >= first && value <= last
}

prefix_contains_prefix :: proc(outer, inner: Prefix) -> bool {
	outer_first, outer_last, _, outer_bits, outer_ok := _prefix_span(outer)
	inner_first, inner_last, _, inner_bits, inner_ok := _prefix_span(inner)
	return outer_ok && inner_ok && outer_bits == inner_bits && inner_first >= outer_first && inner_last <= outer_last
}

prefixes_overlap :: proc(a, b: Prefix) -> bool {
	a_first, a_last, _, a_bits, a_ok := _prefix_span(a)
	b_first, b_last, _, b_bits, b_ok := _prefix_span(b)
	return a_ok && b_ok && a_bits == b_bits && a_first <= b_last && b_first <= a_last
}

range_make :: proc(first, last: Address) -> (range: Address_Range, ok: bool) {
	first_value, first_bits := _address_value(first)
	last_value,  last_bits  := _address_value(last)
	if first_bits == 0 || first_bits != last_bits || first_value > last_value {
		return
	}
	return _range_from_values(first_value, last_value, first_bits), true
}

prefix_to_range :: proc(prefix: Prefix) -> Address_Range {
	first, last, _, bits, ok := _prefix_span(prefix)
	if !ok {
		return nil
	}
	return _range_from_values(first, last, bits)
}

range_contains :: proc(range: Address_Range, address: Address) -> bool {
	first, last, bits, ok := _range_span(range)
	value, address_bits := _address_value(address)
	return ok && bits == address_bits && value >= first && value <= last
}

ranges_overlap :: proc(a, b: Address_Range) -> bool {
	a_first, a_last, a_bits, a_ok := _range_span(a)
	b_first, b_last, b_bits, b_ok := _range_span(b)
	return a_ok && b_ok && a_bits == b_bits && a_first <= b_last && b_first <= a_last
}

range_to_prefixes :: proc(range: Address_Range, allocator := context.allocator) -> (prefixes: []Prefix, err: runtime.Allocator_Error) {
	first, last, bits, ok := _range_span(range)
	if !ok {
		return nil, .Invalid_Argument
	}
	buffer: [MAX_RANGE_PREFIXES]Prefix
	count := _range_prefixes(first, last, bits, &buffer)
	return slice.clone(buffer[:count], allocator)
}

prefixes_to_ranges :: proc(prefixes: []Prefix, allocator := context.allocator) -> (ranges: []Address_Range, err: runtime.Allocator_Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)
	spans := _merged_spans(prefixes, context.temp_allocator) or_return
	ranges = make([]Address_Range, len(spans), allocator) or_return
	for span, i in spans {
		ranges[i] = _range_from_values(span.first, span.last, span.bits)
	}
	return ranges, nil
}

aggregate_prefixes :: proc(prefixes: []Prefix, allocator := context.allocator) -> (aggregated: []Prefix, err: runtime.Allocator_Error) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)
	spans := _merged_spans(prefixes, context.temp_allocator) or_return
	result := make([dynamic]Prefix, 0, len(spans), context.temp_allocator) or_return
	buffer: [MAX_RANGE_PREFIXES]Prefix
	for span in spans {
		count := _range_prefixes(span.first, span.last, span.bits, &buffer)
		append(&result, ..buffer[:count]) or_return
	}
	return slice.clone(result[:], allocator)
}

summarize_prefixes :: proc(prefixes: []Prefix) -> (summary: Prefix, ok: bool) {
	if len(prefixes) == 0 {
		return
	}
	summary = prefix_masked(prefixes[0])
	if summary == nil {
		return
	}
	for prefix in prefixes[1:] {
		summary = common_supernet(summary, prefix) or_return
	}
	return summary, true
}

common_supernet :: proc(a, b: Prefix) -> (supernet: Prefix, ok: bool) {
	a_value, a_length, a_bits, a_ok := _prefix_value(a)
	b_value, b_length, b_bits, b_ok := _prefix_value(b)
	if !a_ok || !b_ok || a_bits != b_bits {
		return
	}
	differing := (a_value ~ b_value) & _all_ones(a_bits)
	common    := u8(intrinsics.count_leading_zeros(differing)) - (128 - a_bits)
	length    := min(a_length, b_length, common)
	return _prefix_from_value(a_value & _network_mask(length, a_bits), length, a_bits), true
}

prefix_exclude :: proc(prefix, hole: Prefix, allocator := context.allocator) -> (remainder: []Prefix, err: runtime.Allocator_Error) {
	first, last, length, bits, ok := _prefix_span(prefix)
	if !ok {
		return nil, .Invalid_Argument
	}
	hole_first, hole_last, hole_length, hole_bits, hole_ok := _prefix_span(hole)

	buffer: [128]Prefix
	count := 0
	switch {
	case !hole_ok || hole_bits != bits || hole_last < first || hole_first > last:
		buffer[0] = _prefix_from_value(first, length, bits)
		count = 1
	case hole_first <= first && hole_last >= last:
		count = 0
	case:
		current := first
		for current_length := length + 1; current_length <= hole_length; current_length += 1 {
			upper := current | (u128(1) << (bits - current_length))
			if hole_first >= upper {
				buffer[count] = _prefix_from_value(current, current_length, bits)
				current = upper
			} else {
				buffer[count] = _prefix_from_value(upper, current_length, bits)
			}
			count += 1
		}
	}
	slice.sort_by(buffer[:count], _prefix_less)
	return slice.clone(buffer[:count], allocator)
}

prefix_supernet :: proc(prefix: Prefix, length: int) -> (supernet: Prefix, ok: bool) {
	value, current, bits, prefix_ok := _prefix_value(prefix)
	if !prefix_ok || length < 0 || length > int(current) {
		return
	}
	return _prefix_from_value(value & _network_mask(u8(length), bits), u8(length), bits), true
}

subnet_count :: proc(prefix: Prefix, length: int) -> (count: u128, ok: bool) {
	_, current, bits, prefix_ok := _prefix_value(prefix)
	if !prefix_ok || length < int(current) || length > int(bits) {
		return
	}
	difference := u8(length) - current
	if difference == 128 {
		return
	}
	return u128(1) << difference, true
}

subnet_nth :: proc(prefix: Prefix, length: int, n: u128) -> (subnet: Prefix, ok: bool) {
	value, current, bits, prefix_ok := _prefix_value(prefix)
	if !prefix_ok || length < int(current) || length > int(bits) {
		return
	}
	difference := u8(length) - current
	if difference < 128 && n >= u128(1) << difference {
		return
	}
	host_bits := bits - u8(length)
	offset    := host_bits == 128 ? 0 : n << host_bits
	return _prefix_from_value((value & _network_mask(current, bits)) | offset, u8(length), bits), true
}

prefix_next :: proc(prefix: Prefix) -> (next: Prefix, ok: bool) {
	_, last, length, bits, prefix_ok := _prefix_span(prefix)
	if !prefix_ok || last == _all_ones(bits) {
		return
	}
	return _prefix_from_value(last + 1, length, bits), true
}

prefix_prev :: proc(prefix: Prefix) -> (prev: Prefix, ok: bool) {
	first, _, length, bits, prefix_ok := _prefix_span(prefix)
	if !prefix_ok || first == 0 {
		return
	}
	return _prefix_from_value((first - 1) & _network_mask(length, bits), length, bits), true
}

split_prefix :: proc(prefix: Prefix, length: int, allocator := context.allocator) -> (subnets: []Prefix, err: runtime.Allocator_Error) {
	count, ok := subnet_count(prefix, length)
	if !ok || count > u128(max(int) / size_of(Prefix)) {
		return nil, .Invalid_Argument
	}
	subnets = make([]Prefix, int(count), allocator) or_return
	for &subnet, i in subnets {
		subnet, _ = subnet_nth(prefix, length, u128(i))
	}
	return subnets, nil
}

@(private)
_Span :: struct {
	first: u128,
	last:  u128,
	bits:  u8,
}

@(private)
_family_bits :: proc(family: Address_Family) -> u8 {
	switch family {
	case .IP4: return 32
	case .IP6: return 128
	}
	return 0
}

@(private)
_all_ones :: proc(bits: u8) -> u128 {
	return max(u128) >> (128 - bits)
}

@(private)
_host_mask :: proc(length, bits: u8) -> u128 {
	if length >= bits {
		return 0
	}
	return _all_ones(bits) >> length
}

@(private)
_network_mask :: proc(length, bits: u8) -> u128 {
	return _all_ones(bits) &~ _host_mask(length, bits)
}

@(private)
_address_value :: proc(address: Address) -> (value: u128, bits: u8) {
	switch v in address {
	case IP4_Address: return u128(ip4_to_u32(v)), 32
	case IP6_Address: return ip6_to_u128(v), 128
	}
	return 0, 0
}

@(private)
_address_from_value :: proc(value: u128, bits: u8) -> Address {
	if bits == 32 {
		return ip4_from_u32(u32(value))
	}
	return ip6_from_u128(value)
}

@(private)
_prefix_value :: proc(prefix: Prefix) -> (value: u128, length: u8, bits: u8, ok: bool) {
	switch v in prefix {
	case IP4_Prefix:
		if v.length > 32 {
			return
		}
		return u128(ip4_to_u32(v.address)), v.length, 32, true
	case IP6_Prefix:
		if v.length > 128 {
			return
		}
		return ip6_to_u128(v.address), v.length, 128, true
	}
	return
}

@(private)
_prefix_from_value :: proc(value: u128, length, bits: u8) -> Prefix {
	if bits == 32 {
		return IP4_Prefix{ip4_from_u32(u32(value)), length}
	}
	return IP6_Prefix{ip6_from_u128(value), length}
}

@(private)
_prefix_span :: proc(prefix: Prefix) -> (first, last: u128, length, bits: u8, ok: bool) {
	value: u128
	value, length, bits, ok = _prefix_value(prefix)
	if !ok {
		return
	}
	first = value & _network_mask(length, bits)
	last  = first | _host_mask(length, bits)
	return
}

@(private)
_range_span :: proc(range: Address_Range) -> (first, last: u128, bits: u8, ok: bool) {
	switch v in range {
	case IP4_Range:
		first, last, bits = u128(ip4_to_u32(v.first)), u128(ip4_to_u32(v.last)), 32
	case IP6_Range:
		first, last, bits = ip6_to_u128(v.first), ip6_to_u128(v.last), 128
	case:
		return
	}
	return first, last, bits, first <= last
}

@(private)
_range_from_values :: proc(first, last: u128, bits: u8) -> Address_Range {
	if bits == 32 {
		return IP4_Range{ip4_from_u32(u32(first)), ip4_from_u32(u32(last))}
	}
	return IP6_Range{ip6_from_u128(first), ip6_from_u128(last)}
}

@(private)
_range_prefixes :: proc(first, last: u128, bits: u8, buffer: ^[MAX_RANGE_PREFIXES]Prefix) -> (count: int) {
	start := first
	for {
		host_bits := u8(min(intrinsics.count_trailing_zeros(start), u128(bits)))
		for host_bits > 0 && (start | _host_mask(bits - host_bits, bits)) > last {
			host_bits -= 1
		}
		block_last := start | _host_mask(bits - host_bits, bits)
		buffer[count] = _prefix_from_value(start, bits - host_bits, bits)
		count += 1
		if block_last >= last {
			return
		}
		start = block_last + 1
	}
}

@(private)
_merged_spans :: proc(prefixes: []Prefix, allocator: runtime.Allocator) -> (spans: []_Span, err: runtime.Allocator_Error) {
	spans = make([]_Span, len(prefixes), allocator) or_return
	count := 0
	for prefix in prefixes {
		first, last, _, bits, ok := _prefix_span(prefix)
		if ok {
			spans[count] = {first, last, bits}
			count += 1
		}
	}
	slice.sort_by(spans[:count], proc(a, b: _Span) -> bool {
		if a.bits != b.bits {
			return a.bits < b.bits
		}
		return a.first < b.first
	})

	merged := 0
	for span in spans[:count] {
		if merged > 0 {
			top := &spans[merged - 1]
			if top.bits == span.bits && (top.last == _all_ones(top.bits) || span.first <= top.last + 1) {
				top.last = max(top.last, span.last)
				continue
			}
		}
		spans[merged] = span
		merged += 1
	}
	return spans[:merged], nil
}

@(private)
_prefix_less :: proc(a, b: Prefix) -> bool {
	a_value, a_length, a_bits, _ := _prefix_value(a)
	b_value, b_length, b_bits, _ := _prefix_value(b)
	if a_bits != b_bits {
		return a_bits < b_bits
	}
	if a_value != b_value {
		return a_value < b_value
	}
	return a_length < b_length
}

@(private)
_split_prefix_length :: proc(prefix_string: string, max_length: int) -> (address_string: string, length: u8, ok: bool) {
	slash := strings.last_index_byte(prefix_string, '/')
	if slash < 0 {
		return
	}
	digits := prefix_string[slash + 1:]
	if len(digits) == 0 || len(digits) > 3 || (len(digits) > 1 && digits[0] == '0') {
		return
	}
	value := 0
	for c in transmute([]u8)digits {
		if c < '0' || c > '9' {
			return
		}
		value = value * 10 + int(c - '0')
	}
	if value > max_length {
		return
	}
	return prefix_string[:slash], u8(value), true
}
