package compress_deflate

import "base:intrinsics"
import "core:compress"
import "core:hash"

deflate_raw  :: proc{deflate_raw_to_slice,  deflate_raw_to_dynamic}
deflate_zlib :: proc{deflate_zlib_to_slice, deflate_zlib_to_dynamic}
deflate_gzip :: proc{deflate_gzip_to_slice, deflate_gzip_to_dynamic}

deflate_bound :: proc(len: int) -> int {
	if len < 0 || len > DEFLATE_INPUT_MAX {
		return -1
	}
	raw_per_block := int(deflate_round_up_divide(DEFLATE_BLOCK_MAX, DEFLATE_RAW_BLOCK_SIZE))
	blocks        := max((len + DEFLATE_BLOCK_MAX - 1) / DEFLATE_BLOCK_MAX, 1)
	return len + blocks * (5 * raw_per_block + 8) + 2 + 4 + 16
}

deflate_gzip_bound :: proc(len: int) -> int {
	bound := deflate_bound(len)
	if bound < 0 {
		return -1
	}
	return bound + size_of(Gzip_Header) + size_of(Gzip_Trailer)
}

deflate_raw_to_dynamic :: proc(output: ^[dynamic]u8, input: []u8, level := Deflate_Level.Default, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	return deflate_to_dynamic(output, input, level, deflate_bound(len(input)), deflate_raw_to_slice)
}

deflate_zlib_to_dynamic :: proc(output: ^[dynamic]u8, input: []u8, level := Deflate_Level.Default, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	return deflate_to_dynamic(output, input, level, deflate_bound(len(input)), deflate_zlib_to_slice)
}

deflate_gzip_to_dynamic :: proc(output: ^[dynamic]u8, input: []u8, level := Deflate_Level.Default, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	return deflate_to_dynamic(output, input, level, deflate_gzip_bound(len(input)), deflate_gzip_to_slice)
}

deflate_raw_to_slice :: proc(s: ^Deflate, output, input: []u8, level := Deflate_Level.Default) -> (written: int, err: Error) {
	deflate_check_arguments(s, len(output), deflate_bound(len(input))) or_return
	s.bit_buffer   = 0
	s.bit_count = 0
	return deflate_compress(s, output, input, level), nil
}

deflate_zlib_to_slice :: proc(s: ^Deflate, output, input: []u8, level := Deflate_Level.Default) -> (written: int, err: Error) {
	deflate_check_arguments(s, len(output), deflate_bound(len(input))) or_return
	p: i32 = 0
	a: u32 = 0
	q := output

	s.bit_buffer = 0
	s.bit_count = 0
	deflate_put_bits(&q, s, 0x78, 8) // deflate, 32k window
	deflate_put_bits(&q, s, 0x01, 8) // fast compression
	q = q[deflate_compress(s, q, input, level):]

	// append adler checksum
	a = hash.adler32(input)
	for p = 0; p < 4; p += 1 {
		deflate_put_bits(&q, s, i32((a >> 24) & 0xFF), 8)
		a <<= 8
	}
	return len(output) - len(q), nil
}

deflate_gzip_to_slice :: proc(s: ^Deflate, output, input: []u8, level := Deflate_Level.Default) -> (written: int, err: Error) {
	deflate_check_arguments(s, len(output), deflate_gzip_bound(len(input))) or_return

	header := Gzip_Header{
		magic              = .GZIP,
		compression_method = .DEFLATE,
		os                 = .Unknown,
	}
	#partial switch clamp(level, Deflate_Level.Stored, Deflate_Level.Best) {
	case .Fastest:            header.xfl = .Fastest_Compression
	case .Level_9, .Level_10: header.xfl = .Maximum_Compression
	}
	intrinsics.unaligned_store((^Gzip_Header)(raw_data(output)), header)
	q := output[size_of(Gzip_Header):]

	s.bit_buffer = 0
	s.bit_count  = 0
	q = q[deflate_compress(s, q, input, level):]

	trailer := Gzip_Trailer{
		crc32 = u32le(hash.crc32(input)),
		size  = u32le(u32(len(input))),
	}
	intrinsics.unaligned_store((^Gzip_Trailer)(raw_data(q)), trailer)
	q = q[size_of(Gzip_Trailer):]
	return len(output) - len(q), nil
}

@(private)
deflate_count_max :: proc(n: u32) -> u32 #no_bounds_check {
	return ((n + 3) / 4 + 3) &~ 3
}

@(private)
deflate_next_power_of_two :: proc(n: i32) -> i32 #no_bounds_check {
	return i32(1) << (log2(u32(n - 1)) + 1)
}

@(private)
deflate_load_u32 :: proc(b: []u8) -> u32 #no_bounds_check {
	return intrinsics.unaligned_load((^u32)(raw_data(b)))
}

@(private)
deflate_load_u64 :: proc(b: []u8) -> u64 #no_bounds_check {
	return intrinsics.unaligned_load((^u64)(raw_data(b)))
}

@(private)
deflate_first_difference :: proc(x: u64) -> i32 #no_bounds_check {
	when ODIN_ENDIAN == .Little {
		return i32(intrinsics.count_trailing_zeros(x) >> 3)
	} else {
		return i32(intrinsics.count_leading_zeros(x) >> 3)
	}
}

@(private)
deflate_hash32 :: proc(b: []u8) -> u32 #no_bounds_check {
	n := deflate_load_u32(b)
	return (n * 0x9E377989) >> (32 - DEFLATE_HASH_BITS)
}

@(private)
deflate_hash24 :: proc(b: []u8) -> u32 #no_bounds_check {
	n := u32(b[0]) | u32(b[1]) << 8 | u32(b[2]) << 16
	return (n * 0x9E377989) >> (32 - DEFLATE_HASH3_BITS)
}

@(private)
deflate_put_bits :: proc(destination: ^[]u8, s: ^Deflate, code: i32, bit_count: i32) #no_bounds_check {
	s.bit_buffer |= (code << u32(s.bit_count))
	s.bit_count += bit_count
	for s.bit_count >= 8 {
		destination[0] = u8(s.bit_buffer & 0xFF)
		s.bit_buffer >>= 8
		s.bit_count -= 8
		destination^ = destination[1:]
	}
}

@(private)
deflate_heap_sift_down :: proc(heap: []u32, len: u32, node: u32) #no_bounds_check {
	c: u32
	p := node
	v := heap[node]
	for {
		c = (p << 1) + 1
		if !(c < len) { break }
		if c + 1 < len && heap[c + 1] > heap[c] { c += 1 }
		if v >= heap[c] { break }
		heap[p] = heap[c]
		p = c
	}
	heap[p] = v
}

@(private)
deflate_heap_array :: proc(heap: []u32, len: u32) #no_bounds_check {
	for node := len >> 1; node >= 1; node -= 1 {
		deflate_heap_sift_down(heap, len, node - 1)
	}
}

@(private)
deflate_heap_sort :: proc(heap: []u32) #no_bounds_check {
	n := u32(len(heap))
	deflate_heap_array(heap, n) // the heap is 0-based (the C original does `A--`)
	for n >= 2 {
		n -= 1
		swap := heap[n]
		heap[n] = heap[0]
		heap[0] = swap
		deflate_heap_sift_down(heap, n, 0)
	}
}

@(private)
deflate_sort_symbols :: proc(frequencies: []u32, lengths: []u8, sorted_symbols: []u32) -> u32 #no_bounds_check {
	symbol_count := u32(len(frequencies))
	counts: [DEFLATE_COUNT_MAX]u32
	count_max := deflate_count_max(symbol_count)
	used_symbols: u32 = 0
	symbol, i: u32
	for symbol = 0; symbol < symbol_count; symbol += 1 {
		counts[frequencies[symbol] if frequencies[symbol] < count_max - 1 else count_max - 1] += 1
	}
	for i = 1; i < count_max; i += 1 {
		count := counts[i]
		counts[i] = used_symbols
		used_symbols += count
	}
	for symbol = 0; symbol < symbol_count; symbol += 1 {
		frequency := frequencies[symbol]
		if frequency != 0 {
			index := frequency if frequency < count_max - 1 else count_max - 1
			sorted_symbols[counts[index]] = symbol | (frequency << DEFLATE_SYMBOL_BITS)
			counts[index] += 1
		} else {
			lengths[symbol] = 0
		}
	}
	deflate_heap_sort(sorted_symbols[counts[count_max - 2]:counts[count_max - 1]])
	return used_symbols
}

@(private)
deflate_build_tree :: proc(items: []u32) #no_bounds_check {
	symbol_count := u32(len(items))
	i, b, e: u32
	for {
		m, n, frequency_sum: u32
		if i != symbol_count && (b == e || (items[i] >> DEFLATE_SYMBOL_BITS) <= (items[b] >> DEFLATE_SYMBOL_BITS)) {
			m = i
			i += 1
		} else {
			m = b
			b += 1
		}
		if i != symbol_count && (b == e || (items[i] >> DEFLATE_SYMBOL_BITS) <= (items[b] >> DEFLATE_SYMBOL_BITS)) {
			n = i
			i += 1
		} else {
			n = b
			b += 1
		}

		frequency_sum = (items[m] &~ DEFLATE_SYMBOL_MASK) + (items[n] &~ DEFLATE_SYMBOL_MASK)
		items[m] = (items[m] & DEFLATE_SYMBOL_MASK) | (e << DEFLATE_SYMBOL_BITS)
		items[n] = (items[n] & DEFLATE_SYMBOL_MASK) | (e << DEFLATE_SYMBOL_BITS)
		items[e] = (items[e] & DEFLATE_SYMBOL_MASK) | frequency_sum
		e += 1
		if !(symbol_count - e > 1) { break }
	}
}

@(private)
deflate_generate_length_counts :: proc(items: []u32, root: u32, length_counts: []u32, max_code_length: u32) #no_bounds_check {
	n: i32
	i: u32
	for i = 0; i <= max_code_length; i += 1 {
		length_counts[i] = 0
	}
	length_counts[1] = 2

	items[root] &= DEFLATE_SYMBOL_MASK
	for n = i32(root) - 1; n >= 0; n -= 1 {
		p := items[n] >> DEFLATE_SYMBOL_BITS
		pdepth := items[p] >> DEFLATE_SYMBOL_BITS
		depth := pdepth + 1
		len := depth

		items[n] = (items[n] & DEFLATE_SYMBOL_MASK) | (depth << DEFLATE_SYMBOL_BITS)
		if len >= max_code_length {
			len = max_code_length
			for { // do len--; while (!len_cnt[len]);
				len -= 1
				if length_counts[len] != 0 { break }
			}
		}
		length_counts[len] -= 1
		length_counts[len + 1] += 2
	}
}

@(private)
deflate_generate_codes :: proc(items: []u32, lengths: []u8, length_counts: []u32, max_code_word_length: u32) #no_bounds_check {
	symbol_count := u32(len(lengths))
	i, symbol, len: u32
	next_code: [DEFLATE_CODE_LENGTH_MAX + 1]u32
	for i, len = 0, max_code_word_length; len >= 1; len -= 1 {
		count := length_counts[len]
		for count != 0 { // while (cnt--)
			count -= 1
			lengths[items[i] & DEFLATE_SYMBOL_MASK] = u8(len)
			i += 1
		}
	}
	next_code[0] = 0
	next_code[1] = 0
	for len = 2; len <= max_code_word_length; len += 1 {
		next_code[len] = (next_code[len - 1] + length_counts[len - 1]) << 1
	}
	for symbol = 0; symbol < symbol_count; symbol += 1 {
		items[symbol] = next_code[lengths[symbol]]
		next_code[lengths[symbol]] += 1
	}
}

@(private)
deflate_reverse_bits :: proc(c: u32, n: u8) -> u32 #no_bounds_check {
	c := c
	c = ((c & 0x5555) << 1) | ((c & 0xAAAA) >> 1)
	c = ((c & 0x3333) << 2) | ((c & 0xCCCC) >> 2)
	c = ((c & 0x0F0F) << 4) | ((c & 0xF0F0) >> 4)
	c = ((c & 0x00FF) << 8) | ((c & 0xFF00) >> 8)
	return c >> (16 - u32(n))
}

@(private)
deflate_huffman :: proc(lengths: []u8, codes: []u32, frequencies: []u32, max_code_length: u32) #no_bounds_check {
	c: u32
	symbol_count := u32(len(frequencies))
	items := codes
	length_counts: [DEFLATE_CODE_LENGTH_MAX + 1]u32
	used_symbols := deflate_sort_symbols(frequencies, lengths, items)
	if used_symbols == 0 { return }
	if used_symbols == 1 {
		s := items[0] & DEFLATE_SYMBOL_MASK
		i := s if s != 0 else 1
		codes[0] = 0
		lengths[0] = 1
		codes[i] = 1
		lengths[i] = 1
		return
	}
	deflate_build_tree(items[:used_symbols])
	deflate_generate_length_counts(items, used_symbols - 2, length_counts[:], max_code_length)
	deflate_generate_codes(items, lengths[:symbol_count], length_counts[:], max_code_length)
	for c = 0; c < symbol_count; c += 1 {
		codes[c] = deflate_reverse_bits(codes[c], lengths[c])
	}
}

@(private)
deflate_precode :: proc(count: ^Deflate_Symbol_Count, frequencies: []u32, items: []u32, literal_lengths, distance_lengths: []u8) #no_bounds_check {
	at := items
	run_start: u32 = 0

	total: u32 = 0
	lengths: [DEFLATE_LITERAL_SYMBOLS + DEFLATE_DISTANCE_SYMBOLS]u8
	for count.literals = DEFLATE_LITERAL_SYMBOLS; count.literals > 257; count.literals -= 1 {
		if literal_lengths[count.literals - 1] != 0 { break }
	}
	for count.distances = DEFLATE_DISTANCE_SYMBOLS; count.distances > 1; count.distances -= 1 {
		if distance_lengths[count.distances - 1] != 0 { break }
	}

	total = u32(count.literals + count.distances)
	copy(lengths[:], literal_lengths[:count.literals])
	copy(lengths[count.literals:], distance_lengths[:count.distances])
	for {
		len := u32(lengths[run_start])
		run_end := run_start
		for {
			run_end += 1
			if !(run_end != total && len == u32(lengths[run_end])) { break }
		}
		if len == 0 {
			for (run_end - run_start) >= 11 {
				n := (run_end - run_start) - 11
				extra_bits := n if n < 0x7f else 0x7f
				frequencies[18] += 1
				at[0] = 18 | (extra_bits << 5)
				at = at[1:]
				run_start += 11 + extra_bits
			}
			if (run_end - run_start) >= 3 {
				n := (run_end - run_start) - 3
				extra_bits := n if n < 0x7 else 0x7
				frequencies[17] += 1
				at[0] = 17 | (extra_bits << 5)
				at = at[1:]
				run_start += 3 + extra_bits
			}
		} else if (run_end - run_start) >= 4 {
			frequencies[len] += 1
			at[0] = len
			at = at[1:]
			run_start += 1
			for {
				extra_bits := (run_end - run_start) - 3
				extra_bits = extra_bits if extra_bits < 0x03 else 0x03
				at[0] = 16 | (extra_bits << 5)
				at = at[1:]
				run_start += 3 + extra_bits
				frequencies[16] += 1
				if !((run_end - run_start) >= 3) { break }
			}
		}
		for run_start != run_end {
			frequencies[len] += 1
			at[0] = len
			at = at[1:]
			run_start += 1
		}
		if run_start == total { break }
	}
	count.items = i32(len(items) - len(at))
}

@(private)
deflate_match_codes :: proc(match_codes: ^Deflate_Match_Codes, distance: i32, len: i32) #no_bounds_check {
	assert(len <= 258)
	assert(distance <= 32768)
	match_codes.length_slot = i32(DEFLATE_LENGTH_SLOT[len])
	match_codes.length_code = 257 + match_codes.length_slot
	assert(match_codes.length_code <= 285)

	match_codes.distance_extra = i32(log2(u32(deflate_next_power_of_two(distance) >> 2)))
	match_codes.distance_code = (((match_codes.distance_extra + 1) << 1) + (1 if distance > i32(DEFLATE_DISTANCE_EXTRA_MAX[match_codes.distance_extra]) else 0)) if match_codes.distance_extra != 0 else distance - 1
}

@(private)
deflate_block_type :: proc(frequencies: ^Deflate_Frequency, lengths: ^Deflate_Lengths, block_length: i32, precode_count: i32, precode_frequencies: []u32, precode_lengths: []u8) -> Deflate_Block_Type #no_bounds_check {
	dynamic_cost, stored_cost, fixed_cost := deflate_block_costs(frequencies, lengths, block_length, precode_count, precode_frequencies, precode_lengths)
	when !SMALL_INPUT_OPTIMIZATION {
		_ = fixed_cost
	} else {
		if fixed_cost < dynamic_cost {
			return .Fixed if fixed_cost < stored_cost else .Stored
		}
	}
	return .Dynamic if dynamic_cost < stored_cost else .Stored
}

@(private)
deflate_block_costs :: proc(frequencies: ^Deflate_Frequency, lengths: ^Deflate_Lengths, block_length: i32, precode_count: i32, precode_frequencies: []u32, precode_lengths: []u8) -> (dynamic_cost, stored_cost, fixed_cost: i32) #no_bounds_check {
	symbol: i32 = 0

	dynamic_cost += 5 + 5 + 4 + (3 * precode_count)
	for symbol = 0; symbol < DEFLATE_PRECODE_SYMBOLS; symbol += 1 {
		dynamic_cost += i32(precode_frequencies[symbol] * u32(i32(DEFLATE_PRECODE_EXTRA_BITS[symbol]) + i32(precode_lengths[symbol])))
	}
	for symbol = 0; symbol < 256; symbol += 1 {
		dynamic_cost += i32(frequencies.literal[symbol] * u32(lengths.literal[symbol]))
	}
	dynamic_cost += i32(lengths.literal[DEFLATE_END_OF_BLOCK])
	for symbol = 257; symbol < 286; symbol += 1 {
		dynamic_cost += i32(frequencies.literal[symbol] * u32(i32(DEFLATE_LENGTH_EXTRA_BITS[symbol - 257]) + i32(lengths.literal[symbol])))
	}
	for symbol = 0; symbol < 30; symbol += 1 {
		dynamic_cost += i32(frequencies.distance[symbol] * u32(i32(DEFLATE_DISTANCE_EXTRA_BITS[symbol]) + i32(lengths.distance[symbol])))
	}

	stored_cost += 8 * (5 * deflate_round_up_divide(block_length, DEFLATE_RAW_BLOCK_SIZE) + block_length + 1 + 2)

	when SMALL_INPUT_OPTIMIZATION {
		fixed_cost = i32(DEFLATE_FIXED_LITERAL_LENGTH[DEFLATE_END_OF_BLOCK])
		for symbol = 0; symbol < 256; symbol += 1 {
			fixed_cost += i32(frequencies.literal[symbol] * u32(DEFLATE_FIXED_LITERAL_LENGTH[symbol]))
		}
		for symbol = 257; symbol < 286; symbol += 1 {
			fixed_cost += i32(frequencies.literal[symbol] * u32(i32(DEFLATE_LENGTH_EXTRA_BITS[symbol - 257]) + i32(DEFLATE_FIXED_LITERAL_LENGTH[symbol])))
		}
		for symbol = 0; symbol < 30; symbol += 1 {
			fixed_cost += i32(frequencies.distance[symbol] * u32(i32(DEFLATE_DISTANCE_EXTRA_BITS[symbol]) + 5))
		}
	} else {
		fixed_cost = max(i32)
	}
	return
}

@(private)
deflate_put_u16 :: proc(destination: ^[]u8, x: u16) #no_bounds_check {
	destination[0] = u8(x & 0xff)
	destination[1] = u8(x >> 8)
	destination^ = destination[2:]
}

@(private)
deflate_match :: proc(destination: ^[]u8, s: ^Deflate, distance: i32, len: i32) #no_bounds_check {
	match_codes: Deflate_Match_Codes
	deflate_match_codes(&match_codes, distance, len)
	deflate_put_bits(destination, s, i32(s.codes.words.literal[match_codes.length_code]), i32(s.codes.lengths.literal[match_codes.length_code]))
	deflate_put_bits(destination, s, len - i32(DEFLATE_LENGTH_BASE[match_codes.length_slot]), i32(DEFLATE_LENGTH_EXTRA_BITS[match_codes.length_slot]))
	deflate_put_bits(destination, s, i32(s.codes.words.distance[match_codes.distance_code]), i32(s.codes.lengths.distance[match_codes.distance_code]))
	deflate_put_bits(destination, s, distance - i32(DEFLATE_DISTANCE_BASE[match_codes.distance_code]), match_codes.distance_extra)
}

@(private)
deflate_store :: proc(destination: ^[]u8, s: ^Deflate, is_last: bool, input: []u8, block_begin: i32, block_end: i32) #no_bounds_check {
	block_length := block_end - block_begin
	n := max(deflate_round_up_divide(block_length, DEFLATE_RAW_BLOCK_SIZE), 1)
	for i: i32 = 0; i < n; i += 1 {
		is_final := is_last && (i + 1 == n)
		amount := block_length if block_length < DEFLATE_RAW_BLOCK_SIZE else DEFLATE_RAW_BLOCK_SIZE
		deflate_put_bits(destination, s, 1 if is_final else 0, 1) // block
		deflate_put_bits(destination, s, 0x00, 2) // stored block
		if s.bit_count != 0 {
			deflate_put_bits(destination, s, 0x00, 8 - s.bit_count)
		}
		assert(s.bit_count == 0)
		deflate_put_u16(destination, u16(amount))
		deflate_put_u16(destination, ~u16(amount))
		copy(destination^, input[block_begin + i * DEFLATE_RAW_BLOCK_SIZE:][:amount])
		destination^ = destination[amount:]
		block_length -= amount
	}
}

@(private)
deflate_put_sequences :: proc(destination: ^[]u8, s: ^Deflate, input: []u8, sequences: []Deflate_Sequence) #no_bounds_check {
	// block sequences
	q := destination^
	for sequence in sequences {
		if sequence.distance >= 0 {
			for j: i32 = 0; j < sequence.length; j += 1 {
				c := input[sequence.distance + j]
				deflate_put_bits(&q, s, i32(s.codes.words.literal[c]), i32(s.codes.lengths.literal[c]))
			}
		} else {
			deflate_match(&q, s, -sequence.distance, sequence.length)
		}
	}
	deflate_put_bits(&q, s, i32(s.codes.words.literal[DEFLATE_END_OF_BLOCK]), i32(s.codes.lengths.literal[DEFLATE_END_OF_BLOCK]))
	destination^ = q
}

@(private)
deflate_precode_count :: proc(lengths: []u8) -> (precode_count: i32) #no_bounds_check {
	for precode_count = DEFLATE_PRECODE_SYMBOLS; precode_count > 4; precode_count -= 1 {
		if lengths[DEFLATE_PRECODE_ORDER[precode_count - 1]] != 0 {
			break
		}
	}
	return
}

@(private)
deflate_flush :: proc(destination: ^[]u8, s: ^Deflate, is_last: bool, input: []u8, block_begin: i32, block_end: i32, sequences: []Deflate_Sequence) #no_bounds_check {
	block_length := block_end - block_begin
	i, precode_count: i32
	symbol_count: Deflate_Symbol_Count
	codes:       [DEFLATE_PRECODE_SYMBOLS]u32
	lengths:     [DEFLATE_PRECODE_SYMBOLS]u8
	frequencies: [DEFLATE_PRECODE_SYMBOLS]u32
	items:       [DEFLATE_LITERAL_SYMBOLS + DEFLATE_DISTANCE_SYMBOLS]u32

	// calculate huffman codes
	s.frequencies.literal[DEFLATE_END_OF_BLOCK] += 1
	deflate_huffman(s.codes.lengths.literal[:], s.codes.words.literal[:], s.frequencies.literal[:], DEFLATE_LITERAL_MAX_CODE_LENGTH)
	deflate_huffman(s.codes.lengths.distance[:], s.codes.words.distance[:], s.frequencies.distance[:], DEFLATE_DISTANCE_MAX_CODE_LENGTH)
	deflate_precode(&symbol_count, frequencies[:], items[:], s.codes.lengths.literal[:], s.codes.lengths.distance[:])
	deflate_huffman(lengths[:], codes[:], frequencies[:], DEFLATE_PRECODE_MAX_CODE_LENGTH)
	precode_count = deflate_precode_count(lengths[:])
	// write block
	switch deflate_block_type(&s.frequencies, &s.codes.lengths, block_length, precode_count, frequencies[:], lengths[:]) {
	case .Stored:
		deflate_store(destination, s, is_last, input, block_begin, block_end)
	case .Dynamic:
		// dynamic huffman block
		deflate_put_bits(destination, s, 1 if is_last else 0, 1) // block
		deflate_put_bits(destination, s, 0x02, 2) // dynamic huffman
		deflate_put_bits(destination, s, symbol_count.literals - 257, 5)
		deflate_put_bits(destination, s, symbol_count.distances - 1, 5)
		deflate_put_bits(destination, s, precode_count - 4, 4)
		for i = 0; i < precode_count; i += 1 {
			deflate_put_bits(destination, s, i32(lengths[DEFLATE_PRECODE_ORDER[i]]), 3)
		}
		for i = 0; i < symbol_count.items; i += 1 {
			symbol := items[i] & 0x1F
			deflate_put_bits(destination, s, i32(codes[symbol]), i32(lengths[symbol]))
			if symbol < 16 { continue }
			if symbol == 16 {
				deflate_put_bits(destination, s, i32(items[i] >> 5), 2)
			} else if symbol == 17 {
				deflate_put_bits(destination, s, i32(items[i] >> 5), 3)
			} else {
				deflate_put_bits(destination, s, i32(items[i] >> 5), 7)
			}
		}
		deflate_put_sequences(destination, s, input, sequences)
	case .Fixed:
		when SMALL_INPUT_OPTIMIZATION {
			for symbol in 0..<DEFLATE_LITERAL_SYMBOLS {
				s.codes.words.literal[symbol] = u32(DEFLATE_FIXED_LITERAL_CODE[symbol])
				s.codes.lengths.literal[symbol]  = DEFLATE_FIXED_LITERAL_LENGTH[symbol]
			}
			for symbol in 0..<DEFLATE_DISTANCE_SYMBOLS {
				s.codes.words.distance[symbol] = u32(DEFLATE_FIXED_DISTANCE_CODE[symbol])
				s.codes.lengths.distance[symbol]  = 5
			}
			deflate_put_bits(destination, s, 1 if is_last else 0, 1) // block
			deflate_put_bits(destination, s, 0x01, 2)
			deflate_put_sequences(destination, s, input, sequences)
		}
	}
	s.frequencies = {}
	s.sequence_count = 0
}

@(private)
deflate_add_sequence :: proc(s: ^Deflate, distance: i32, length: i32) #no_bounds_check {
	assert(s.sequence_count + 2 < DEFLATE_SEQUENCE_SIZE)
	s.sequences[s.sequence_count].distance = distance
	s.sequences[s.sequence_count].length = length
	s.sequence_count += 1
}

@(private)
deflate_register_match :: proc(s: ^Deflate, distance: i32, length: i32) #no_bounds_check {
	match_codes: Deflate_Match_Codes
	deflate_match_codes(&match_codes, distance, length)

	assert(match_codes.length_code < DEFLATE_LITERAL_SYMBOLS)
	assert(match_codes.distance_code < DEFLATE_DISTANCE_SYMBOLS)

	s.frequencies.literal[match_codes.length_code] += 1
	s.frequencies.distance[match_codes.distance_code] += 1
}

@(private)
deflate_block_cost :: proc(frequencies: ^Deflate_Frequency, block_length: i32) -> i32 #no_bounds_check {
	block_frequencies := frequencies^
	block_frequencies.literal[DEFLATE_END_OF_BLOCK] += 1

	codes:               Deflate_Codes
	symbol_count:        Deflate_Symbol_Count
	precode_codes:       [DEFLATE_PRECODE_SYMBOLS]u32
	precode_lengths:     [DEFLATE_PRECODE_SYMBOLS]u8
	precode_frequencies: [DEFLATE_PRECODE_SYMBOLS]u32
	items:               [DEFLATE_LITERAL_SYMBOLS + DEFLATE_DISTANCE_SYMBOLS]u32

	deflate_huffman(codes.lengths.literal[:], codes.words.literal[:], block_frequencies.literal[:], DEFLATE_LITERAL_MAX_CODE_LENGTH)
	deflate_huffman(codes.lengths.distance[:], codes.words.distance[:], block_frequencies.distance[:], DEFLATE_DISTANCE_MAX_CODE_LENGTH)
	deflate_precode(&symbol_count, precode_frequencies[:], items[:], codes.lengths.literal[:], codes.lengths.distance[:])
	deflate_huffman(precode_lengths[:], precode_codes[:], precode_frequencies[:], DEFLATE_PRECODE_MAX_CODE_LENGTH)
	precode_count := deflate_precode_count(precode_lengths[:])

	dynamic_cost, stored_cost, fixed_cost := deflate_block_costs(&block_frequencies, &codes.lengths, block_length, precode_count, precode_frequencies[:], precode_lengths[:])
	return 3 + min(dynamic_cost, stored_cost, fixed_cost)
}

@(private)
deflate_count_sequence :: proc(frequencies: ^Deflate_Frequency, input: []u8, sequence: Deflate_Sequence) #no_bounds_check {
	if sequence.distance >= 0 {
		for c in input[sequence.distance:][:sequence.length] {
			frequencies.literal[c] += 1
		}
	} else {
		match_codes: Deflate_Match_Codes
		deflate_match_codes(&match_codes, -sequence.distance, sequence.length)
		frequencies.literal[match_codes.length_code] += 1
		frequencies.distance[match_codes.distance_code] += 1
	}
}

@(private)
deflate_frequency_range :: proc(range: ^Deflate_Frequency, from, to: ^Deflate_Frequency) #no_bounds_check {
	for c in 0..<DEFLATE_LITERAL_SYMBOLS {
		range.literal[c] = to.literal[c] - from.literal[c]
	}
	for c in 0..<DEFLATE_DISTANCE_SYMBOLS {
		range.distance[c] = to.distance[c] - from.distance[c]
	}
}

@(private)
deflate_flush_split :: proc(destination: ^[]u8, s: ^Deflate, is_last: bool, input: []u8, block_begin: i32, block_end: i32) #no_bounds_check {
	sequences    := s.sequences[:s.sequence_count]
	block_length := block_end - block_begin

	boundaries: [DEFLATE_SPLIT_SEGMENTS + 1]i32
	positions:  [DEFLATE_SPLIT_SEGMENTS + 1]i32
	prefix:     [DEFLATE_SPLIT_SEGMENTS + 1]Deflate_Frequency
	segments := 0

	positions[0] = block_begin
	position := block_begin
	for sequence, index in sequences {
		target := block_begin + i32(i64(block_length) * i64(segments + 1) / DEFLATE_SPLIT_SEGMENTS)
		if position >= target && segments + 1 < DEFLATE_SPLIT_SEGMENTS {
			segments += 1
			boundaries[segments] = i32(index)
			positions[segments]  = position
			prefix[segments + 1] = prefix[segments]
		}
		deflate_count_sequence(&prefix[segments + 1], input, sequence)
		position += sequence.length
	}
	segments += 1
	boundaries[segments] = i32(len(sequences))
	positions[segments]  = block_end

	best:     [DEFLATE_SPLIT_SEGMENTS + 1]i64
	previous: [DEFLATE_SPLIT_SEGMENTS + 1]int
	range:    Deflate_Frequency
	for j in 1..=segments {
		best[j] = max(i64)
		for i in 0..<j {
			deflate_frequency_range(&range, &prefix[i], &prefix[j])
			cost := best[i] + i64(deflate_block_cost(&range, positions[j] - positions[i]))
			if cost < best[j] {
				best[j]     = cost
				previous[j] = i
			}
		}
	}

	cuts: [DEFLATE_SPLIT_SEGMENTS + 1]int
	cut_count := 0
	for j := segments; j > 0; j = previous[j] {
		cuts[cut_count] = j
		cut_count += 1
	}
	from := 0
	for c := cut_count - 1; c >= 0; c -= 1 {
		to := cuts[c]
		deflate_frequency_range(&s.frequencies, &prefix[from], &prefix[to])
		deflate_flush(destination, s, is_last && c == 0, input, positions[from], positions[to], sequences[boundaries[from]:boundaries[to]])
		from = to
	}
}

@(private)
deflate_find_match :: #force_inline proc(m: ^Deflate_Match, s: ^Deflate, chain_length: i32, max_match: i32, input: []u8, p: i32, $WIDE: bool) #no_bounds_check {
	chain_length := chain_length
	e := i32(len(input))
	i := i32(s.hash_head[deflate_hash32(input[p:])])
	limit: i32 = DEFLATE_NO_POSITION if (p - DEFLATE_WINDOW_SIZE) < DEFLATE_NO_POSITION else (p - DEFLATE_WINDOW_SIZE)

	assert(p < e)
	assert(p + max_match <= e)
	for i > limit {
		assert(i + m.length < e)
		assert(p + m.length < e)
		assert(i + DEFLATE_MATCH_MIN < e)
		assert(p + DEFLATE_MATCH_MIN < e)

		if input[i + m.length] == input[p + m.length] &&
		   (deflate_load_u32(input[i:]) == deflate_load_u32(input[p:])) {
			n: i32 = DEFLATE_MATCH_MIN
			when WIDE {
				for n + 8 <= max_match {
					x := deflate_load_u64(input[i + n:]) ~ deflate_load_u64(input[p + n:])
					if x != 0 {
						n += deflate_first_difference(x)
						break
					}
					n += 8
				}
			}
			for n < max_match && input[i + n] == input[p + n] {
				assert(i + n < e)
				assert(p + n < e)
				n += 1
			}
			if n > m.length {
				m.length = n
				m.distance = p - i
				if n == max_match {
					break
				}
			}
		}
		chain_length -= 1
		if chain_length == 0 { break }
		i = s.hash_chain[i & DEFLATE_WINDOW_MASK]
	}
}

@(private)
deflate_find_match3 :: proc(m: ^Deflate_Match, s: ^Deflate, max_match: i32, input: []u8, p: i32) #no_bounds_check {
	i := s.hash3_head[deflate_hash24(input[p:])]
	if i <= DEFLATE_NO_POSITION || p - i > DEFLATE_MATCH3_DISTANCE {
		return
	}
	n: i32 = 0
	for n < max_match && input[i + n] == input[p + n] {
		n += 1
	}
	if n < DEFLATE_MATCH3_MIN || n <= m.length {
		return
	}
	if n == DEFLATE_MATCH3_MIN {
		code_cost :: proc(length: u8) -> i32 {
			return i32(length) if length != 0 else 12
		}
		match_codes: Deflate_Match_Codes
		deflate_match_codes(&match_codes, p - i, n)
		match_cost := code_cost(s.codes.lengths.literal[match_codes.length_code]) + code_cost(s.codes.lengths.distance[match_codes.distance_code]) + match_codes.distance_extra
		literal_cost := code_cost(s.codes.lengths.literal[input[p]]) + code_cost(s.codes.lengths.literal[input[p + 1]]) + code_cost(s.codes.lengths.literal[input[p + 2]])
		if match_cost + DEFLATE_MATCH3_MARGIN >= literal_cost {
			return
		}
	}
	m.length   = n
	m.distance = p - i
}

@(private)
deflate_compress :: proc(s: ^Deflate, output: []u8, input: []u8, requested_level: Deflate_Level) -> int #no_bounds_check {
	level := clamp(requested_level, Deflate_Level.Stored, Deflate_Level.Best)
	if level == .Level_10 {
		return deflate_compress_level(s, output, input, level, true)
	}
	return deflate_compress_level(s, output, input, level, false)
}

@(private)
deflate_compress_level :: proc(s: ^Deflate, output: []u8, input: []u8, level: Deflate_Level, $BEST: bool) -> int #no_bounds_check {
	q := output
	total := len(input)
	s.sequence_count = 0
	s.frequencies = {}
	if level == .Stored {
		base := 0
		for {
			length  := min(total - base, DEFLATE_SLIDE_SIZE)
			is_last := base + length == total
			deflate_store(&q, s, is_last, input[base:][:length], 0, i32(length))
			base += length
			if is_last { break }
		}
		return len(output) - len(q)
	}
	base   := 0
	window := input[:min(total, DEFLATE_SLIDE_SIZE + DEFLATE_BLOCK_MAX)]
	input_length := i32(len(window))
	max_chain: i32 = (1 << u32(level)) if level < .Level_9 else (1 << 12) if level == .Level_9 else (1 << 13)
	match_min: i32 = DEFLATE_MATCH3_MIN if BEST else DEFLATE_MATCH_MIN
	n, i, literal_run: i32
	for n = 0; n < DEFLATE_HASH_SIZE; n += 1 {
		s.hash_head[n] = DEFLATE_NO_POSITION
	}
	if BEST {
		for n = 0; n < DEFLATE_HASH3_SIZE; n += 1 {
			s.hash3_head[n] = DEFLATE_NO_POSITION
		}
		s.codes.lengths.literal = DEFLATE_FIXED_LITERAL_LENGTH
		for &length in s.codes.lengths.distance {
			length = 5
		}
	}
	for { // do {...} while (i < in_len);
		if i >= DEFLATE_SLIDE_SIZE {
			delta := (i - DEFLATE_WINDOW_SIZE) &~ DEFLATE_WINDOW_MASK
			deflate_slide(s, delta, BEST)
			base += int(delta)
			i    -= delta
			window       = input[base:][:min(total - base, DEFLATE_SLIDE_SIZE + DEFLATE_BLOCK_MAX)]
			input_length = i32(len(window))
		}
		block_begin := i
		block_end := (i + DEFLATE_BLOCK_MAX) if (i + DEFLATE_BLOCK_MAX) < input_length else input_length
		is_last   := base + int(block_end) == total
		next: Deflate_Match
		have_next := false
		for i < block_end {
			m: Deflate_Match
			left := block_end - i
			max_match: i32 = DEFLATE_MATCH_MAX if left > DEFLATE_MATCH_MAX else left
			nice_match: i32 = i32(DEFLATE_LEVEL_NICE[level]) if i32(DEFLATE_LEVEL_NICE[level]) < max_match else max_match
			run, step, advance: i32 = 1, 1, 0
			if have_next {
				m = next
				have_next = false
			} else if max_match > DEFLATE_MATCH_MIN {
				if level >= DEFLATE_LEVEL_LAZY {
					deflate_find_match(&m, s, max_chain, max_match, window, i, true)
				} else {
					deflate_find_match(&m, s, max_chain, max_match, window, i, false)
				}
				if BEST && m.length < DEFLATE_MATCH_MIN {
					deflate_find_match3(&m, s, max_match, window, i)
				}
			}
			next_max: i32 = DEFLATE_MATCH_MAX if left - 1 > DEFLATE_MATCH_MAX else left - 1
			if level >= DEFLATE_LEVEL_LAZY && m.length >= match_min && m.length + 1 < nice_match && next_max > DEFLATE_MATCH_MIN {
				lazy_chain := max_chain
				if level >= .Level_9 && m.length >= DEFLATE_GOOD_MATCH {
					lazy_chain >>= 2
				}
				next = {}
				deflate_find_match(&next, s, lazy_chain, next_max, window, i + 1, true)
				if next.length > m.length {
					have_next = true
					m.length = 0
				}
			}
			if m.length >= match_min {
				if literal_run != 0 {
					deflate_add_sequence(s, i - literal_run, literal_run)
					literal_run = 0
				}
				deflate_add_sequence(s, -m.distance, m.length)
				deflate_register_match(s, m.distance, m.length)
				if level < .Level_3 && m.length >= nice_match {
					step = m.length
				} else {
					run = m.length
				}
			} else {
				s.frequencies.literal[window[i]] += 1
				literal_run += 1
			}
			advance = run * step
			if BEST && input_length - (i + advance) > DEFLATE_MATCH_MIN {
				for run > 0 {
					run -= 1
					h := deflate_hash32(window[i:])
					s.hash_chain[i & DEFLATE_WINDOW_MASK] = s.hash_head[h]
					s.hash_head[h] = i
					s.hash3_head[deflate_hash24(window[i:])] = i
					i += step
					assert(i <= block_end)
				}
			} else if input_length - (i + advance) > DEFLATE_MATCH_MIN {
				for run > 0 { // while (run-- > 0)
					run -= 1
					h := deflate_hash32(window[i:])
					s.hash_chain[i & DEFLATE_WINDOW_MASK] = s.hash_head[h]
					s.hash_head[h] = i
					i += step
					assert(i <= block_end)
				}
			} else {
				i += advance
				assert(i <= block_end)
			}
		}
		if literal_run != 0 {
			deflate_add_sequence(s, i - literal_run, literal_run)
			literal_run = 0
		}
		if BEST {
			deflate_flush_split(&q, s, is_last, window, block_begin, block_end)
		} else {
			deflate_flush(&q, s, is_last, window, block_begin, block_end, s.sequences[:s.sequence_count])
		}
		if is_last { break }
	}
	if s.bit_count != 0 {
		deflate_put_bits(&q, s, 0x00, 8 - s.bit_count)
	}
	assert(s.bit_count == 0)
	return len(output) - len(q)
}

@(private)
deflate_slide :: proc(s: ^Deflate, delta: i32, $BEST: bool) #no_bounds_check {
	for &position in s.hash_head {
		position = position - delta if position >= delta else DEFLATE_NO_POSITION
	}
	for &position in s.hash_chain {
		position = position - delta if position >= delta else DEFLATE_NO_POSITION
	}
	when BEST {
		for &position in s.hash3_head {
			position = position - delta if position >= delta else DEFLATE_NO_POSITION
		}
	}
}

@(private)
deflate_check_arguments ::proc(s: ^Deflate, output_size, bound: int) -> Error #no_bounds_check {
	if bound < 0 || s == nil {
		return General_Error.Incompatible_Options
	}
	if output_size < bound {
		return General_Error.Output_Too_Short
	}
	return nil
}

@(private)
deflate_to_dynamic :: proc(output: ^[dynamic]u8, input: []u8, level: Deflate_Level, bound: int, compressor: Deflate_To_Slice) -> (err: Error) #no_bounds_check {
	if output == nil || bound < 0 {
		return General_Error.Incompatible_Options
	}
	if bound > compress.COMPRESS_OUTPUT_ALLOCATE_MAX {
		return General_Error.Output_Too_Short
	}
	s := new(Deflate) or_return
	defer free(s)

	non_zero_resize(output, bound) or_return

	written: int
	written, err = compressor(s, output[:], input, level)
	non_zero_resize(output, written)
	return
}
