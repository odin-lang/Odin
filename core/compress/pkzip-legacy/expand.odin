package compress_pkzip_legacy

import "core:compress"

expand :: proc{expand_from_bytes, expand_from_context}

expand_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, factor: int, expected_output_size := -1, max_output_size := compress.COMPRESS_OUTPUT_ALLOCATE_MAX, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return expand_from_context(&ctx, factor, expected_output_size, max_output_size, allocator)
}

expand_from_context :: proc(z: ^compress.Context, factor: int, expected_output_size := -1, max_output_size := compress.COMPRESS_OUTPUT_ALLOCATE_MAX, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	if z.output == nil || factor < 1 || factor > 4 {
		return General_Error.Incompatible_Options
	}

	expected := output_limit(z, expected_output_size, max_output_size, REDUCE_EXPANSION_MAX) or_return
	if expected == 0 {
		return nil
	}

	start := len(z.output)
	defer z.bytes_written = i64(len(z.output) - start)

	e: Expand
	for i := 255; i >= 0; i -= 1 {
		count := read_bits_required(z, 6) or_return
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
			e.followers[i][j] = u8(read_bits_required(z, 8) or_return)
		}
	}

	length_bits   := uint(8 - factor)
	length_max    := 1 << length_bits - 1
	distance_mask := 1 << uint(factor) - 1

	state  := Expand_State.Literal
	last   := 0
	v      := 0
	length := 0
	for len(z.output) - start < expected {
		symbol, available := expand_symbol(z, &e, last) or_return
		if !available {
			break
		}

		switch state {
		case .Literal:
			if symbol == REDUCE_DLE {
				state = .DLE
			} else {
				write_literal(z, start, expected, u8(symbol)) or_return
			}
		case .DLE:
			if symbol == 0 {
				write_literal(z, start, expected, REDUCE_DLE) or_return
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
			write_match(z, start, expected, distance, length + REDUCE_MIN_MATCH) or_return
			state = .Literal
		}
		last = symbol
	}

	if len(z.output) - start != expected {
		return General_Error.Stream_Too_Short
	}
	return nil
}

@(private)
expand_symbol :: #force_inline proc(z: ^compress.Context, e: ^Expand, last: int) -> (symbol: int, available: bool, err: Error) #no_bounds_check {
	if z.num_bits < 9 {
		refill_bits(z) or_return
		if z.num_bits < 9 {
			return expand_symbol_slow(z, e, last)
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
expand_symbol_slow :: proc(z: ^compress.Context, e: ^Expand, last: int) -> (symbol: int, available: bool, err: Error) #no_bounds_check {
	count := int(e.counts[last])
	if count > 0 {
		literal: int
		literal, available = read_bits(z, 1) or_return
		if !available {
			return
		}
		if literal == 0 {
			index: int
			index, available = read_bits(z, uint(e.index_bits[last])) or_return
			if !available {
				return
			}
			if index >= count {
				return 0, false, PKZIP_Legacy_Error.Invalid_Follower_Index
			}
			return int(e.followers[last][index]), true, nil
		}
	}
	return read_bits(z, 8)
}
