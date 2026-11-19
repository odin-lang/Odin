package compress_pkzip_legacy

import "core:compress"

explode :: proc{explode_from_bytes, explode_from_context}

explode_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, implode_options: Implode_Options, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return explode_from_context(&ctx, implode_options, expected_output_size, options, allocator)
}

explode_from_context :: proc(z: ^compress.Context, implode_options: Implode_Options, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	if z.output == nil {
		return General_Error.Incompatible_Options
	}

	expected := output_limit(z, expected_output_size, options, compress.IMPLODE_EXPANSION_MAX, 0) or_return
	if expected == 0 {
		return nil
	}

	start := len(z.output)
	defer z.bytes_written = i64(len(z.output) - start)

	p: Output_Progress
	progress_begin(&p, z, expected, options)

	literal_tree := .Literal_Tree in implode_options
	literals, lengths, distances: Implode_Tree
	if literal_tree {
		explode_read_tree(z, &p.pulled, &literals, IMPLODE_LITERAL_SYMBOLS) or_return
	}
	explode_read_tree(z, &p.pulled, &lengths,   IMPLODE_LENGTH_SYMBOLS)   or_return
	explode_read_tree(z, &p.pulled, &distances, IMPLODE_DISTANCE_SYMBOLS) or_return

	distance_bits := uint(7 if .Large_Window in implode_options else 6)
	min_match     := 3 if literal_tree else 2

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
		flag, available := bits_read(z, &p.pulled, &b, 1) or_return
		if !available {
			break
		}

		if flag == 1 {
			symbol: int
			if literal_tree {
				symbol, available = explode_decode_bits(z, &p.pulled, &b, &literals) or_return
			} else {
				symbol, available = bits_read(z, &p.pulled, &b, 8) or_return
			}
			if !available {
				break
			}
			out_literal(z, &o, start, expected, u8(symbol)) or_return
			continue
		}

		low, high, length, extra: int
		low, available = bits_read(z, &p.pulled, &b, distance_bits) or_return
		if !available {
			break
		}
		high, available = explode_decode_bits(z, &p.pulled, &b, &distances) or_return
		if !available {
			break
		}
		length, available = explode_decode_bits(z, &p.pulled, &b, &lengths) or_return
		if !available {
			break
		}
		if length == IMPLODE_EXTRA_LENGTH {
			extra, available = bits_read(z, &p.pulled, &b, 8) or_return
			if !available {
				break
			}
		}
		distance := high << distance_bits + low + 1
		out_match(z, &o, start, expected, distance, length + extra + min_match) or_return
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
explode_read_tree :: proc(z: ^compress.Context, pulled: ^i64, t: ^Implode_Tree, symbol_count: int) -> (err: Error) #no_bounds_check {
	lengths: [IMPLODE_LITERAL_SYMBOLS]u8

	entries := read_bits_required(z, pulled, 8) or_return
	entries += 1
	k := 0
	for _ in 0..<entries {
		b    := read_bits_required(z, pulled, 8) or_return
		bits := b & 0x0f + 1
		run  := int(b >> 4) + 1
		if k + run > symbol_count {
			return PKZIP_Legacy_Error.Invalid_Tree
		}
		for _ in 0..<run {
			lengths[k] = u8(bits)
			k += 1
		}
	}
	if k != symbol_count {
		return PKZIP_Legacy_Error.Invalid_Tree
	}

	for length in lengths[:symbol_count] {
		t.count[length] += 1
	}

	index := 0
	code  := 0
	for length := IMPLODE_MAX_CODE_LENGTH; length >= 1; length -= 1 {
		t.offset[length] = index
		t.first[length]  = code >> uint(IMPLODE_MAX_CODE_LENGTH - length)
		code += t.count[length] << uint(IMPLODE_MAX_CODE_LENGTH - length)
		for symbol := symbol_count - 1; symbol >= 0; symbol -= 1 {
			if int(lengths[symbol]) == length {
				t.symbols[index] = u8(symbol)
				index += 1
			}
		}
	}
	if code != 1 << IMPLODE_MAX_CODE_LENGTH {
		return PKZIP_Legacy_Error.Invalid_Tree
	}

	for length := IMPLODE_PRIMARY_BITS; length >= 1; length -= 1 {
		for i in 0..<t.count[length] {
			value    := t.first[length] + i
			reversed := 0
			for bit in 0..<length {
				reversed |= (value >> uint(bit) & 1) << uint(length - 1 - bit)
			}
			entry := u16(t.symbols[t.offset[length] + i]) | u16(length) << 8
			for fill := reversed; fill < 1 << IMPLODE_PRIMARY_BITS; fill += 1 << uint(length) {
				t.table[fill] = entry
			}
		}
	}
	return nil
}

@(private)
explode_decode :: #force_inline proc(z: ^compress.Context, pulled: ^i64, t: ^Implode_Tree) -> (symbol: int, available: bool, err: Error) #no_bounds_check {
	if z.num_bits < IMPLODE_MAX_CODE_LENGTH {
		refill_bits(z, pulled) or_return
	}
	entry  := t.table[z.code_buffer & (1 << IMPLODE_PRIMARY_BITS - 1)]
	length := u64(entry >> 8)
	if length == 0 {
		return explode_decode_slow(z, t)
	}
	if length > z.num_bits {
		return 0, false, nil
	}
	z.code_buffer >>= length
	z.num_bits     -= length
	return int(entry & 0xff), true, nil
}

@(private)
explode_decode_bits :: #force_inline proc(z: ^compress.Context, pulled: ^i64, b: ^Bits, t: ^Implode_Tree) -> (symbol: int, available: bool, err: Error) #no_bounds_check {
	if b.count < IMPLODE_MAX_CODE_LENGTH {
		bits_refill(z, pulled, b) or_return
	}
	entry  := t.table[b.buffer & (1 << IMPLODE_PRIMARY_BITS - 1)]
	length := u64(entry >> 8)
	if length == 0 {
		z.code_buffer = b.buffer
		z.num_bits    = b.count
		symbol, available, err = explode_decode_slow(z, t)
		b.buffer = z.code_buffer
		b.count  = z.num_bits
		return
	}
	if length > b.count {
		return 0, false, nil
	}
	b.buffer >>= length
	b.count   -= length
	return int(entry & 0xff), true, nil
}

@(private)
explode_decode_slow :: proc(z: ^compress.Context, t: ^Implode_Tree) -> (symbol: int, available: bool, err: Error) #no_bounds_check {
	code := 0
	for length in 1..=IMPLODE_MAX_CODE_LENGTH {
		if u64(length) > z.num_bits {
			return 0, false, nil
		}
		code = code << 1 | int(z.code_buffer >> uint(length - 1) & 1)
		i := code - t.first[length]
		if i >= 0 && i < t.count[length] {
			z.code_buffer >>= uint(length)
			z.num_bits     -= u64(length)
			return int(t.symbols[t.offset[length] + i]), true, nil
		}
	}
	return 0, false, PKZIP_Legacy_Error.Invalid_Code
}
