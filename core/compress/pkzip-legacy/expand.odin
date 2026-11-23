package compress_pkzip_legacy

import "core:compress"

expand :: proc{expand_from_bytes, expand_from_context}

expand_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, factor: int, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return expand_from_context(&ctx, factor, expected_output_size, options, allocator)
}

expand_from_context :: proc(z: ^compress.Context, factor: int, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	if z.output == nil || factor < 1 || factor > 4 {
		return General_Error.Incompatible_Options
	}

	expected := output_limit(z, expected_output_size, options, compress.REDUCE_EXPANSION_MAX, 0) or_return
	if expected == 0 {
		return nil
	}

	start := len(z.output)
	defer z.bytes_written = i64(len(z.output) - start)

	p: Output_Progress
	progress_begin(&p, z, expected, options)

	e: Expand
	expand_read_followers(z, &p.pulled, &e) or_return

	length_bits   := uint(8 - factor)
	length_max    := 1 << length_bits - 1
	distance_mask := 1 << uint(factor) - 1

	state  := Expand_State.Literal
	last   := 0
	v      := 0
	length := 0

	b := Bits{z.code_buffer, z.num_bits}
	defer {
		z.code_buffer = b.buffer
		z.num_bits    = b.count
	}

	o := out_load(z)
	defer out_store(z, &o)

	for o.at - start < expected {
		if o.at - start >= p.mark {
			progress_report(&p, z, o.at - start, b.count) or_return
		}
		symbol, available := expand_symbol_bits(z, &p.pulled, &b, &e, last) or_return
		if !available {
			break
		}

		switch state {
		case .Literal:
			if symbol == REDUCE_DLE {
				state = .DLE
			} else {
				out_literal(z, &o, start, expected, u8(symbol)) or_return
			}
		case .DLE:
			if symbol == 0 {
				out_literal(z, &o, start, expected, REDUCE_DLE) or_return
				state = .Literal
			} else {
				v      = symbol
				length = v & length_max
				state  = .Length if length == length_max else .Distance
			}
		case .Length:
			length += symbol
			state   = .Distance
		case .Distance:
			distance := (v >> length_bits & distance_mask) << 8 + symbol + 1
			out_match(z, &o, start, expected, distance, length + REDUCE_MIN_MATCH) or_return
			state = .Literal
		}
		last = symbol
	}

	if o.at - start != expected {
		return General_Error.Stream_Too_Short
	}
	if o.at - start >= p.mark {
		return progress_report(&p, z, o.at - start, b.count)
	}
	return nil
}

@(private)
expand_read_followers :: proc(z: ^compress.Context, pulled: ^i64, e: ^Expand) -> (err: Error) {
	for i := 255; i >= 0; i -= 1 {
		count := read_bits_required(z, pulled, 6) or_return
		if count > REDUCE_MAX_FOLLOWERS {
			return PKZIP_Legacy_Error.Invalid_Follower_Set
		}
		e.counts[i] = u8(count)
		bits := 1
		for 1 << uint(bits) < count {
			bits += 1
		}
		e.index_bits[i] = u8(bits)
		for j in 0..<count {
			e.followers[i][j] = u8(read_bits_required(z, pulled, 8) or_return)
		}
	}
	return nil
}

@(private)
expand_symbol :: #force_inline proc(z: ^compress.Context, pulled: ^i64, e: ^Expand, last: int) -> (symbol: int, available: bool, err: Error) #no_bounds_check {
	if z.num_bits < 9 {
		refill_bits(z, pulled) or_return
		if z.num_bits < 9 {
			return expand_symbol_slow(z, pulled, e, last)
		}
	}

	count := int(e.counts[last])
	if count > 0 {
		if z.code_buffer & 1 == 0 {
			bits  := uint(e.index_bits[last])
			index := int(z.code_buffer >> 1 & (u64(1) << bits - 1))
			z.code_buffer >>= bits + 1
			z.num_bits     -= u64(bits + 1)
			if index >= count {
				return 0, false, PKZIP_Legacy_Error.Invalid_Follower_Index
			}
			return int(e.followers[last][index]), true, nil
		}
		z.code_buffer >>= 1
		z.num_bits     -= 1
	}
	symbol = int(z.code_buffer & 0xff)
	z.code_buffer >>= 8
	z.num_bits     -= 8
	return symbol, true, nil
}

@(private)
expand_symbol_bits :: #force_inline proc(z: ^compress.Context, pulled: ^i64, b: ^Bits, e: ^Expand, last: int) -> (symbol: int, available: bool, err: Error) #no_bounds_check {
	if b.count < 9 {
		bits_refill(z, pulled, b) or_return
		if b.count < 9 {
			z.code_buffer = b.buffer
			z.num_bits    = b.count
			symbol, available, err = expand_symbol_slow(z, pulled, e, last)
			b.buffer = z.code_buffer
			b.count  = z.num_bits
			return
		}
	}

	count := int(e.counts[last])
	if count > 0 {
		if b.buffer & 1 == 0 {
			bits  := uint(e.index_bits[last])
			index := int(b.buffer >> 1 & (u64(1) << bits - 1))
			b.buffer >>= bits + 1
			b.count   -= u64(bits + 1)
			if index >= count {
				return 0, false, PKZIP_Legacy_Error.Invalid_Follower_Index
			}
			return int(e.followers[last][index]), true, nil
		}
		b.buffer >>= 1
		b.count   -= 1
	}
	symbol = int(b.buffer & 0xff)
	b.buffer >>= 8
	b.count   -= 8
	return symbol, true, nil
}

@(private)
expand_symbol_slow :: proc(z: ^compress.Context, pulled: ^i64, e: ^Expand, last: int) -> (symbol: int, available: bool, err: Error) #no_bounds_check {
	count := int(e.counts[last])
	if count > 0 {
		literal: int
		literal, available = read_bits(z, pulled, 1) or_return
		if !available {
			return
		}
		if literal == 0 {
			index: int
			index, available = read_bits(z, pulled, uint(e.index_bits[last])) or_return
			if !available {
				return
			}
			if index >= count {
				return 0, false, PKZIP_Legacy_Error.Invalid_Follower_Index
			}
			return int(e.followers[last][index]), true, nil
		}
	}
	return read_bits(z, pulled, 8)
}
