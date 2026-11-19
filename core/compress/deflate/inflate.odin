package compress_deflate

import "base:builtin"
import "base:intrinsics"
import "core:compress"
import "core:hash"
import "core:io"
import "core:simd"

decompress_raw  :: proc{decompress_raw_from_context, decompress_raw_from_bytes}
decompress_zlib :: proc{decompress_zlib_from_context, decompress_zlib_from_bytes}

decompress_raw_from_context :: proc(z: ^compress.Context, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	p: Inflate_Progress
	inflate_progress_init(&p, z, expected_output_size, options) or_return
	output := inflate_to_buffer(z, expected_output_size, &p, D64 = false) or_return
	if expected := compress.declared_size(expected_output_size); expected >= 0 && len(output) != expected {
		return General_Error.Size_Mismatch
	}
	return inflate_progress_step(&p, p.bytes_in, i64(len(output)))
}

decompress_zlib_from_context :: proc(z: ^compress.Context, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	p: Inflate_Progress
	inflate_progress_init(&p, z, expected_output_size, options) or_return

	inflate_zlib_header(z) or_return
	p.bytes_in = ZLIB_HEADER_SIZE

	digest := u32(1)
	output := inflate_to_buffer(z, expected_output_size, &p, checksum = .Adler32, digest = &digest, D64 = false) or_return

	adler, adler_err := compress.read_data(z, u32be)
	if adler_err != nil {
		return General_Error.Stream_Too_Short
	}
	p.bytes_in += size_of(u32be)
	if digest != u32(adler) {
		return General_Error.Checksum_Failed
	}
	if expected := compress.declared_size(expected_output_size); expected >= 0 && len(output) != expected {
		return General_Error.Size_Mismatch
	}
	return inflate_progress_step(&p, p.bytes_in, i64(len(output)))
}

decompress_raw_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return decompress_raw_from_context(&ctx, expected_output_size, options, allocator)
}

decompress_zlib_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return decompress_zlib_from_context(&ctx, expected_output_size, options, allocator)
}

decompress_raw_to_writer :: proc(w: io.Writer, z: ^compress.Context, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	return inflate_stream_to_writer(w, z, .Raw, expected_output_size, options, allocator)
}

decompress_zlib_to_writer :: proc(w: io.Writer, z: ^compress.Context, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	return inflate_stream_to_writer(w, z, .Zlib, expected_output_size, options, allocator)
}

reader_init :: proc(r: ^Reader, z: ^compress.Context, format: Format, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	err   = inflate_stream_init(r, z, format, expected_output_size, options, allocator)
	r.err = err
	return
}

reader_read :: proc(r: ^Reader, p: []u8) -> (n: int, err: Error) {
	was_done := r.done
	for n < len(p) {
		if r.flushed < r.written {
			copied   := copy(p[n:], r.window[r.flushed:r.written])
			r.flushed += copied
			n         += copied
		} else if r.done || r.err != nil {
			break
		} else {
			r.err = inflate_stream_fill(r)
		}
	}
	if (n > 0 || (r.done && !was_done)) && r.err == nil {
		if r.err = inflate_reader_progress(r); r.err != nil {
			r.flushed = r.written
		}
	}
	if n > 0 || r.flushed < r.written {
		return n, nil
	}
	if r.err != nil {
		return 0, r.err
	}
	if len(p) > 0 && r.done {
		return 0, io.Error.EOF
	}
	return 0, nil
}

reader_to_stream :: proc(r: ^Reader) -> (s: io.Stream) {
	s.data      = r
	s.procedure = inflate_reader_stream_proc
	return
}

reader_destroy :: proc(r: ^Reader) {
	if r.owns_window {
		delete(r.window, r.allocator)
	}
	r.window      = nil
	r.written     = 0
	r.flushed     = 0
	r.owns_window = false
}

@(private)
inflate_load_u64 :: proc(p: [^]u8) -> u64 #no_bounds_check {
	return intrinsics.unaligned_load((^u64)(p))
}

@(private)
inflate_copy64 :: proc(destination, source: ^[^]u8) #no_bounds_check {
	n := intrinsics.unaligned_load((^u64)(source^))
	intrinsics.unaligned_store((^u64)(destination^), n)
	destination^ = destination[8:]
	source^ = source[8:]
}

@(private)
inflate_load_u8x16 :: proc(p: [^]u8) -> simd.u8x16 #no_bounds_check {
	return intrinsics.unaligned_load((^simd.u8x16)(p))
}

@(private)
inflate_store_u8x16 :: proc(d: [^]u8, v: simd.u8x16) #no_bounds_check {
	intrinsics.unaligned_store((^simd.u8x16)(d), v)
}

@(private)
inflate_splat_u8x16 :: proc(c: u8) -> simd.u8x16 #no_bounds_check {
	return simd.u8x16(c)
}

@(private)
inflate_write128 :: proc(destination: [^]u8, w: simd.u8x16) -> [^]u8 #no_bounds_check {
	inflate_store_u8x16(destination, w)
	return destination[16:]
}

@(private)
inflate_copy128 :: proc(destination, source: ^[^]u8) #no_bounds_check {
	n := inflate_load_u8x16(source^)
	inflate_store_u8x16(destination^, n)
	destination^ = destination[16:]
	source^ = source[16:]
}

@(private)
inflate_refill :: #force_inline proc(s: ^Inflate, written: int, $STREAM: bool) -> (overrun: bool) #no_bounds_check {
	if intrinsics.expect(len(s.input) - s.position >= 8, true) {
		s.bit_buffer |= inflate_load_u64(raw_data(s.input)[s.position:]) << u64(s.bit_count & 63)
		s.position += int((63 - s.bit_count) >> 3)
		s.bit_count |= 56 // bitcount in range [56,63]
		return false
	}
	when STREAM {
		s.input, s.position, s.bit_buffer, s.bit_count, s.eof, s.base = inflate_refill_stream(s.ctx, s.input, s.position, s.bit_buffer, s.bit_count, s.eof, s.base)
	} else {
		for s.bit_count < 56 {
			b: u64 = 0
			if s.position < len(s.input) {
				b = u64(s.input[s.position])
			}
			s.bit_buffer |= b << u64(s.bit_count)
			s.position += 1
			s.bit_count += 8
		}
	}
	overrun = inflate_overrun(s)
	if !overrun {
		s.checkpoint = written
	}
	return
}

@(private, cold)
inflate_refill_stream :: #force_no_inline proc(ctx: ^compress.Context, input: []u8, position: int, bit_buffer: u64, bit_count: i32, eof: bool, base: i64) -> (new_input: []u8, new_position: int, new_bit_buffer: u64, new_bit_count: i32, new_eof: bool, new_base: i64) #no_bounds_check {
	new_input, new_position, new_bit_buffer, new_bit_count, new_eof, new_base = input, position, bit_buffer, bit_count, eof, base
	if !new_eof {
		new_input, new_position, new_eof, new_base = inflate_fill(ctx, new_input, new_position, new_eof, 8, new_base)
		if len(new_input) - new_position >= 8 {
			new_bit_buffer |= inflate_load_u64(raw_data(new_input)[new_position:]) << u64(new_bit_count)
			new_position   += int((63 - new_bit_count) >> 3)
			new_bit_count  |= 56
			return
		}
	}
	for new_bit_count < 56 {
		b: u64 = 0
		if new_position < len(new_input) {
			b = u64(new_input[new_position])
		}
		new_bit_buffer |= b << u64(new_bit_count)
		new_position   += 1
		new_bit_count  += 8
	}
	return
}

@(private)
inflate_fill :: proc(ctx: ^compress.Context, input: []u8, position: int, eof: bool, need: int, base: i64) -> (new_input: []u8, new_position: int, new_eof: bool, new_base: i64) #no_bounds_check {
	if eof || position > len(input) {
		return input, position, true, base
	}
	ctx.window = input[position:]
	refill_error := compress.refill_window(ctx, need)
	return ctx.window, 0, refill_error != nil, base + i64(position)
}

@(private)
inflate_rewind :: proc(ctx: ^compress.Context, input: []u8, position: int, base: i64) -> (new_input: []u8, new_position: int, new_base: i64) #no_bounds_check {
	if position >= 0 {
		return input, position, base
	}
	ctx.window = input
	if !compress.rewind(ctx, -position) {
		return input, 0, base
	}
	return ctx.window, 0, base + i64(position)
}

@(private)
inflate_overrun :: proc(s: ^Inflate) -> bool #no_bounds_check {
	return (s.position - len(s.input)) * 8 > int(s.bit_count)
}

@(private)
inflate_peek :: proc(s: ^Inflate, count: i32) -> i32 #no_bounds_check {
	assert(count >= 0 && count <= 56)
	assert(count <= s.bit_count)
	return i32(s.bit_buffer & ((u64(1) << u64(count)) - 1))
}

@(private)
inflate_consume :: proc(s: ^Inflate, count: i32) #no_bounds_check {
	assert(count <= s.bit_count)
	s.bit_buffer >>= u64(count)
	s.bit_count -= count
}

@(private)
inflate_get_no_refill :: proc(s: ^Inflate, count: i32) -> i32 #no_bounds_check {
	result := inflate_peek(s, count)
	inflate_consume(s, count)
	return result
}

@(private)
inflate_get :: #force_inline proc(s: ^Inflate, written: int, count: i32, $STREAM: bool) -> i32 #no_bounds_check {
	inflate_refill(s, written, STREAM)
	return inflate_get_no_refill(s, count)
}

@(private)
inflate_build_table :: proc(builder: ^Inflate_Table_Builder, table: []u32, table_bits: i32, counts: []i32, $kind: Inflate_Table_Kind) -> i32 {
	table_end: i32 = 0
	for {
		builder.count = counts[builder.length]
		if builder.count != 0 { break }
		builder.length += 1
	}
	table_end = i32(1) << u32(builder.length)
	for builder.length <= table_bits {
		for { // do {...} while (--gen->cnt);
			table[builder.word] = inflate_symbol_entry(kind, i32(builder.sorted[0])) + u32(builder.length) * 0x101
			builder.sorted = builder.sorted[1:]
			if builder.word == table_end - 1 {
				for ; builder.length < table_bits; builder.length += 1 {
					copy(table[table_end:][:table_end], table[:table_end])
					table_end <<= 1
				}
				return 1
			}
			when ODIN_ARCH == .arm64 {
				builder.code += u32(0x80000000) >> u32(builder.length - 1)
				builder.word  = i32(intrinsics.reverse_bits(builder.code))
			} else {
				bit := u32(1) << log2(u32(builder.word ~ (table_end - 1)))
				builder.word &= i32(bit) - 1
				builder.word |= i32(bit)
			}
			builder.count -= 1
			if builder.count == 0 { break }
		}
		for { // do {...} while (!(gen->cnt = cnt[gen->len]));
			builder.length += 1
			if builder.length <= table_bits {
				copy(table[table_end:][:table_end], table[:table_end])
				table_end <<= 1
			}
			builder.count = counts[builder.length]
			if builder.count != 0 { break }
		}
	}
	return 0
}

@(private)
inflate_build_sub_table :: proc(builder: ^Inflate_Table_Builder, table: []u32, table_bits: i32, counts: []i32, $kind: Inflate_Table_Kind) {
	sub_bits:   i32 = 0
	sub_start:  i32 = 0
	sub_prefix: i32 = -1
	table_end:  i32 = i32(1) << u32(table_bits)
	for {
		entry: u32
		stride, i: i32
		// start new sub-table
		if (builder.word & ((i32(1) << u32(table_bits)) - 1)) != sub_prefix {
			used: i32 = 0
			sub_prefix = builder.word & ((i32(1) << u32(table_bits)) - 1)
			sub_start = table_end
			sub_bits = builder.length - table_bits
			used = builder.count
			for used < (i32(1) << u32(sub_bits)) {
				sub_bits += 1
				used = (used << 1) + counts[table_bits + sub_bits]
			}
			table_end = sub_start + (i32(1) << u32(sub_bits))
			table[sub_prefix] = INFLATE_ENTRY_EXCEPTIONAL | INFLATE_ENTRY_SUBTABLE | (u32(sub_start) << 16) | (u32(sub_bits) << 8) | u32(table_bits)
		}
		// fill sub-table
		entry = inflate_symbol_entry(kind, i32(builder.sorted[0])) + u32(builder.length - table_bits) * 0x101
		builder.sorted = builder.sorted[1:]
		i = sub_start + (builder.word >> u32(table_bits))
		stride = i32(1) << u32(builder.length - table_bits)
		for { // do {...} while (i < tbl_end);
			table[i] = entry
			i += stride
			if i >= table_end { break }
		}
		if builder.word == (i32(1) << u32(builder.length)) - 1 {
			return
		}
		when ODIN_ARCH == .arm64 {
			builder.code += u32(0x80000000) >> u32(builder.length - 1)
			builder.word  = i32(intrinsics.reverse_bits(builder.code))
		} else {
			bit := i32(1) << log2(u32(builder.word ~ ((i32(1) << u32(builder.length)) - 1)))
			builder.word &= bit - 1
			builder.word |= bit
		}
		builder.count -= 1
		for builder.count == 0 {
			builder.length += 1
			builder.count = counts[builder.length]
		}
	}
}

@(private)
inflate_count_lengths :: #force_inline proc(counts: ^[16]i32, lengths: []u8) #no_bounds_check {
	assert(len(lengths) <= 2 * 255)
	a, b: simd.u8x16
	p := raw_data(lengths)
	n := len(lengths)
	i := 0
	for ; i + 2 <= n; i += 2 {
		a += intrinsics.unaligned_load((^simd.u8x16)(&INFLATE_ONE_HOT[16 - int(p[i])]))
		b += intrinsics.unaligned_load((^simd.u8x16)(&INFLATE_ONE_HOT[16 - int(p[i + 1])]))
	}
	if i < n {
		a += intrinsics.unaligned_load((^simd.u8x16)(&INFLATE_ONE_HOT[16 - int(p[i])]))
	}
	intrinsics.unaligned_store((^#simd[16]i32)(counts), cast(#simd[16]i32)a + cast(#simd[16]i32)b)
}

@(private)
inflate_build :: proc(table: []u32, lengths: []u8, table_bits, maxlen, bad_symbol: i32, $kind: Inflate_Table_Kind) -> bool {
	i, used: i32
	sorted:    [288]i16 = ---
	counts:  [16]i32
	offsets: [16]i32
	builder: Inflate_Table_Builder
	builder.length = 1
	symbol_count := i32(len(lengths))

	inflate_count_lengths(&counts, lengths)
	offsets[1] = counts[0]
	for i = 1; i < maxlen; i += 1 {
		offsets[i + 1] = offsets[i] + counts[i]
		used = (used << 1) + counts[i]
	}
	used = (used << 1) + counts[i]
	for i = 0; i < symbol_count; i += 1 {
		sorted[offsets[lengths[i]]] = i16(i)
		offsets[lengths[i]] += 1
	}
	builder.sorted = sorted[offsets[0]:]

	if used > (i32(1) << u32(maxlen)) {
		return false
	}
	if used < (i32(1) << u32(maxlen)) {
		if bad_symbol < 0 {
			return false
		}
		if used != 0 && !(counts[1] == 1 && used == i32(1) << u32(maxlen - 1)) {
			return false
		}
		only := bad_symbol
		if used != 0 {
			only = i32(builder.sorted[0])
		}
		for i = 0; i < (i32(1) << u32(table_bits)); i += 1 {
			symbol := only if i & 1 == 0 else bad_symbol
			table[i] = inflate_symbol_entry(kind, symbol) + 0x101
		}
		return true
	}
	if inflate_build_table(&builder, table, table_bits, counts[:], kind) == 0 {
		inflate_build_sub_table(&builder, table, table_bits, counts[:], kind)
	}
	return true
}

@(private)
inflate_symbol_entry :: #force_inline proc($kind: Inflate_Table_Kind, symbol: i32) -> u32 {
	switch kind {
	case .Precode:
		return u32(symbol) << 16
	case .Literal, .Literal64:
		switch {
		case symbol < 256:  return INFLATE_ENTRY_LITERAL | (u32(symbol) << 16)
		case symbol == 256: return INFLATE_ENTRY_EXCEPTIONAL | INFLATE_ENTRY_END
		case symbol >= 286: return INFLATE_ENTRY_EXCEPTIONAL
		}
		slot := symbol - 257
		if kind == .Literal64 {
			if DEFLATE64_LENGTH_EXTRA_BITS[slot] > 5 {
				return INFLATE_ENTRY_EXCEPTIONAL | INFLATE_ENTRY_LONG | (u32(DEFLATE64_LENGTH_BASE[slot]) << 16)
			}
			return (u32(DEFLATE64_LENGTH_BASE[slot]) << 16) | u32(DEFLATE64_LENGTH_EXTRA_BITS[slot])
		}
		return (u32(DEFLATE_LENGTH_BASE[slot]) << 16) | u32(DEFLATE_LENGTH_EXTRA_BITS[slot])
	case .Distance, .Distance64:
		if symbol >= (32 if kind == .Distance64 else 30) {
			return INFLATE_ENTRY_EXCEPTIONAL
		}
		return (u32(DEFLATE_DISTANCE_BASE[symbol]) << 16) | u32(DEFLATE_DISTANCE_EXTRA_BITS[symbol])
	}
	return INFLATE_ENTRY_EXCEPTIONAL
}

@(private)
inflate_entry :: #force_inline proc(s: ^Inflate, table: []u32, $BITS: u64) -> (entry: u32) #no_bounds_check {
	entry = table[s.bit_buffer & ((1 << BITS) - 1)]
	if intrinsics.expect(entry & INFLATE_ENTRY_SUBTABLE != 0, false) {
		// sub-table lookup
		entry = inflate_sub_entry(s, table, entry, BITS)
	}
	return
}

@(private)
inflate_sub_entry :: #force_inline proc(s: ^Inflate, table: []u32, entry: u32, $BITS: u64) -> u32 #no_bounds_check {
	s.bit_buffer >>= BITS
	s.bit_count  -= i32(BITS)
	return table[u64(entry >> 16) + (s.bit_buffer & ((u64(1) << u64((entry >> 8) & 0xf)) - 1))]
}

@(private)
inflate_refill_entry :: #force_inline proc(s: ^Inflate, written: int, table: []u32, $BITS: u64, $STREAM: bool) -> (entry: u32, overrun: bool) #no_bounds_check {
	if intrinsics.expect(s.bit_count >= i32(BITS), true) {
		entry = table[s.bit_buffer & ((1 << BITS) - 1)]
		if inflate_refill(s, written, STREAM) { return entry, true }
	} else {
		if inflate_refill(s, written, STREAM) { return 0, true }
		entry = table[s.bit_buffer & ((1 << BITS) - 1)]
	}
	if intrinsics.expect(entry & INFLATE_ENTRY_SUBTABLE != 0, false) {
		entry = inflate_sub_entry(s, table, entry, BITS)
	}
	return
}

@(private)
inflate_refill_fast :: #force_inline proc(s: ^Inflate, written: int, $STREAM: bool) -> (overrun: bool) #no_bounds_check {
	if intrinsics.expect(len(s.input) - s.position >= 8, true) {
		s.bit_buffer |= inflate_load_u64(raw_data(s.input)[s.position:]) << u64(s.bit_count & 63)
		s.position += int((~s.bit_count & 63) >> 3)
		s.bit_count |= 56
		return false
	}
	s.bit_count &= 63
	return inflate_refill(s, written, STREAM)
}

@(private)
inflate_refill_entry_fast :: #force_inline proc(s: ^Inflate, written: int, table: []u32, $BITS: u64, $STREAM: bool) -> (entry: u32, overrun: bool) #no_bounds_check {
	if intrinsics.expect((s.bit_count & 63) >= i32(BITS), true) {
		entry = table[s.bit_buffer & ((1 << BITS) - 1)]
		if inflate_refill_fast(s, written, STREAM) { return entry, true }
	} else {
		if inflate_refill_fast(s, written, STREAM) { return 0, true }
		entry = table[s.bit_buffer & ((1 << BITS) - 1)]
	}
	if intrinsics.expect(entry & INFLATE_ENTRY_SUBTABLE != 0, false) {
		entry = inflate_sub_entry(s, table, entry, BITS)
	}
	return
}

@(private)
inflate_skip_fast :: #force_inline proc(s: ^Inflate, entry: u32) #no_bounds_check {
	s.bit_buffer >>= u64(entry & 63)
	s.bit_count  -= i32(entry)
}

@(private)
inflate_take_fast :: #force_inline proc(s: ^Inflate, entry: u32) -> (value: int) #no_bounds_check {
	bits  := s.bit_buffer
	count := u64(entry & 63)
	s.bit_buffer >>= count
	s.bit_count  -= i32(entry)
	return int(entry >> 16) + int((bits & ((u64(1) << count) - 1)) >> u64((entry >> 8) & 0xf))
}

@(private)
inflate_skip :: #force_inline proc(s: ^Inflate, entry: u32) #no_bounds_check {
	s.bit_buffer >>= u64(entry & 63)
	s.bit_count  -= i32(entry & 63)
}

@(private)
inflate_skip_code :: #force_inline proc(s: ^Inflate, entry: u32) #no_bounds_check {
	count := u64((entry >> 8) & 0xf)
	s.bit_buffer >>= count
	s.bit_count  -= i32(count)
}

@(private)
inflate_take_extra :: #force_inline proc(s: ^Inflate, entry: u32) -> (value: int) #no_bounds_check {
	bits  := s.bit_buffer
	count := u64((entry & 63) - ((entry >> 8) & 0xf))
	s.bit_buffer >>= count
	s.bit_count  -= i32(count)
	return int(entry >> 16) + int(bits & ((u64(1) << count) - 1))
}

@(private)
inflate_take :: #force_inline proc(s: ^Inflate, entry: u32) -> (value: int) #no_bounds_check {
	bits  := s.bit_buffer
	count := u64(entry & 63)
	s.bit_buffer >>= count
	s.bit_count  -= i32(count)
	return int(entry >> 16) + int((bits & ((u64(1) << count) - 1)) >> u64((entry >> 8) & 0xf))
}

@(private)
inflate_decode :: proc(s: ^Inflate, table: []u32, $BITS: u64) -> i32 #no_bounds_check {
	entry := inflate_entry(s, table, BITS)
	inflate_skip(s, entry)
	return i32(entry >> 16)
}

@(private)
inflate_grow :: proc(grow: ^[dynamic]u8, start, need, limit: int) -> (output: []u8, err: Error) #no_bounds_check {
	if grow == nil || need > limit {
		return nil, General_Error.Output_Too_Short
	}
	non_zero_resize(grow, start + compress.output_grow_capacity(len(grow) - start, need, limit)) or_return
	return grow[start:], nil
}

@(private)
inflate_copy_match :: #force_inline proc(destination, source, out: [^]u8, distance: i32) #no_bounds_check {
	destination, source := destination, source
	if distance >= 16 {
		// SIMD copy match
		inflate_copy128(&destination, &source)
		inflate_copy128(&destination, &source)
		for {
			inflate_copy128(&destination, &source)
			if !(uintptr(destination) < uintptr(out)) { break }
		}
	} else if distance >= 8 {
		// Word copy match
		inflate_copy64(&destination, &source)
		inflate_copy64(&destination, &source)
		for {
			inflate_copy64(&destination, &source)
			if !(uintptr(destination) < uintptr(out)) { break }
		}
	} else if distance == 1 {
		// RLE match copying
		w := inflate_splat_u8x16(source[0])
		destination = inflate_write128(destination, w)
		destination = inflate_write128(destination, w)
		for {
			destination = inflate_write128(destination, w)
			if !(uintptr(destination) < uintptr(out)) { break }
		}
	} else {
		// Distances 2-7 replicate an 8-byte pattern instead of copying bytes
		pattern := u64(intrinsics.unaligned_load((^u64le)(source)))
		shift   := u64(distance) << 3
		pattern &= (u64(1) << shift) - 1
		pattern |= pattern << shift
		pattern |= pattern << (shift << 1)
		pattern |= pattern << (shift << 2)
		stride  := int(INFLATE_PATTERN_STRIDE[distance])
		for {
			intrinsics.unaligned_store((^u64le)(destination), u64le(pattern))
			destination = destination[stride:]
			if !(uintptr(destination) < uintptr(out)) { break }
		}
	}
}

@(private)
inflate_copy_match_checked :: proc(output: []u8, capacity: int, grow: ^[dynamic]u8, start, limit, written, match_end: int, distance: i32) -> (new_output: []u8, new_capacity: int, err: Error) #no_bounds_check {
	new_output, new_capacity = output, capacity
	if match_end > new_capacity {
		new_output   = inflate_grow(grow, start, match_end, limit) or_return
		new_capacity = len(new_output)
	}
	destination := raw_data(new_output)[written:]
	source      := raw_data(new_output)[written - int(distance):]
	out         := raw_data(new_output)[match_end:]
	if new_capacity - match_end >= INFLATE_COPY_MARGIN {
		inflate_copy_match(destination, source, out, distance)
		return
	}
	for {
		destination[0] = source[0]; destination = destination[1:]; source = source[1:]
		if !(uintptr(destination) < uintptr(out)) { break }
	}
	return
}

@(private)
inflate_decoder_init :: proc(d: ^Inflate_Decoder, ctx: ^compress.Context) {
	d.s            = {input = ctx.window, eof = compress.is_memory_context(ctx), ctx = ctx}
	d.stored       = 0
	d.last         = 0
	d.state        = .Header
	d.fixed_loaded = false
}

@(private)
inflate_decompress :: proc(d: ^Inflate_Decoder, output: []u8, grow: ^[dynamic]u8, start, limit, from, high_water: int, checksum: Inflate_Checksum, digest: ^u32, $STREAM, $D64, $WINDOWED: bool) -> (written: int, err: Error) #no_bounds_check {
	DISTANCE_SYMBOLS :: 32 when D64 else 30
	BAD_DISTANCE     :: INFLATE64_BAD_DISTANCE when D64 else INFLATE_BAD_DISTANCE
	LITERAL_KIND     :: Inflate_Table_Kind.Literal64 when D64 else Inflate_Table_Kind.Literal
	DISTANCE_KIND    :: Inflate_Table_Kind.Distance64 when D64 else Inflate_Table_Kind.Distance

	output   := output
	capacity := len(output)
	written   = from
	checked  := from

	s            := d.s
	s.checkpoint  = from
	state        := d.state
	last         := d.last
	stored       := d.stored
	fixed_loaded := d.fixed_loaded
	literals     := &d.literals
	distances    := &d.distances

	defer {
		s.bit_count &= 63
		when WINDOWED {
			d.s, d.state, d.last, d.stored, d.fixed_loaded = s, state, last, stored, fixed_loaded
			finished := err != nil || state == .Done
		} else {
			d.s = s
			finished := true
		}
		if finished {
			ctx := s.ctx
			input, consumed, _ := inflate_rewind(ctx, s.input, s.position - int(s.bit_count >> 3), s.base)
			ctx.window      = input[min(consumed, len(input)):]
			ctx.code_buffer = 0
			ctx.num_bits    = 0
		}
	}
	defer if err == nil {
		inflate_update_checksum(checksum, digest, output[checked:written])
	}

	for {
		switch state {
		case .Header:
			inflate_update_checksum(checksum, digest, output[checked:written])
			checked = written
			when !WINDOWED {
				if written >= d.mark {
					inflate_progress_block(d, inflate_consumed(&s), written) or_return
				}
			}
			// block header
			type: i32 = 0
			if inflate_refill(&s, written, STREAM) { return written, General_Error.Stream_Too_Short }
			last = inflate_get_no_refill(&s, 1)
			type = inflate_get_no_refill(&s, 2)

			switch type {
			case 0x00: state = .Stored
			case 0x01: state = .Fixed
			case 0x02: state = .Dynamic
			case:      return written, Deflate_Error.BType_3
			}

		case .Stored:
			// uncompressed block
			len, inverted_length: u32
			inflate_get_no_refill(&s, s.bit_count & 7)
			len             = u32(u16(inflate_get_no_refill(&s, 16)))
			inverted_length = u32(u16(inflate_get_no_refill(&s, 16)))
			s.position -= int(s.bit_count / 8)
			s.bit_buffer = 0
			s.bit_count = 0
			when STREAM {
				s.input, s.position, s.base = inflate_rewind(s.ctx, s.input, s.position, s.base)
			}

			if u16(len) != u16(~inverted_length) {
				return written, Deflate_Error.Len_Nlen_Mismatch
			}
			if s.position > builtin.len(s.input) {
				return written, General_Error.Stream_Too_Short
			}
			stored = int(len)
			state  = .Copy

		case .Copy:
			when STREAM {
				for stored > 0 {
					when WINDOWED {
						if written >= high_water { return written, nil }
					}
					if s.position == builtin.len(s.input) {
						s.input, s.position, s.eof, s.base = inflate_fill(s.ctx, s.input, s.position, s.eof, 1, s.base)
						if s.position == builtin.len(s.input) {
							return written, General_Error.Stream_Too_Short
						}
					}
					n := min(stored, builtin.len(s.input) - s.position)
					when WINDOWED {
						n = min(n, high_water - written)
					}
					if n > capacity - written {
						output   = inflate_grow(grow, start, written + n, limit) or_return
						capacity = builtin.len(output)
					}
					copy(output[written:], s.input[s.position:][:n])
					s.position += n
					written    += n
					stored     -= n
				}
			} else when WINDOWED {
				for stored > 0 {
					if written >= high_water { return written, nil }
					if s.position == builtin.len(s.input) { return written, General_Error.Stream_Too_Short }
					n := min(stored, high_water - written, builtin.len(s.input) - s.position)
					if n > capacity - written {
						output   = inflate_grow(grow, start, written + n, limit) or_return
						capacity = builtin.len(output)
					}
					copy(output[written:], s.input[s.position:][:n])
					s.position += n
					written    += n
					stored     -= n
				}
			} else {
				n := min(stored, builtin.len(s.input) - s.position)
				if n > capacity - written {
					output   = inflate_grow(grow, start, written + n, limit) or_return
					capacity = builtin.len(output)
				}
				copy(output[written:], s.input[s.position:][:n])
				s.position += n
				written    += n
				stored     -= n
				if stored > 0 { return written, General_Error.Stream_Too_Short }
			}
			if last != 0 {
				state = .Done
				return written, nil
			}
			state = .Header

		case .Fixed:
			// fixed huffman codes
			if !fixed_loaded {
				when D64 {
					intrinsics.mem_copy_non_overlapping(literals, &INFLATE64_FIXED_LITERAL_ENTRIES, size_of(INFLATE64_FIXED_LITERAL_ENTRIES))
					intrinsics.mem_copy_non_overlapping(distances, &INFLATE64_FIXED_DISTANCE_ENTRIES, size_of(INFLATE64_FIXED_DISTANCE_ENTRIES))
				} else {
					intrinsics.mem_copy_non_overlapping(literals, &INFLATE_FIXED_LITERAL_ENTRIES, size_of(INFLATE_FIXED_LITERAL_ENTRIES))
					intrinsics.mem_copy_non_overlapping(distances, &INFLATE_FIXED_DISTANCE_ENTRIES, size_of(INFLATE_FIXED_DISTANCE_ENTRIES))
				}
				fixed_loaded = true
			}
			state = .Block

		case .Dynamic:
			// dynamic huffman codes
			n, i: i32
			precode_table:   [INFLATE_PRECODE_TABLE_SIZE]u32 = ---
			precode_lengths: [19]u8
			lengths:         [288 + 32]u8 = ---

			inflate_refill(&s, written, STREAM)
			{
				literal_count  := 257 + inflate_get_no_refill(&s, 5)
				distance_count := 1 + inflate_get_no_refill(&s, 5)
				precode_count  := 4 + inflate_get_no_refill(&s, 4)
				if literal_count > 286 || distance_count > DISTANCE_SYMBOLS {
					return written, Deflate_Error.Huffman_Bad_Sizes
				}
				for n = 0; n < precode_count; n += 1 {
					precode_lengths[DEFLATE_PRECODE_ORDER[n]] = u8(inflate_get(&s, written, 3, STREAM))
				}
				if !inflate_build(precode_table[:], precode_lengths[:], 7, 7, -1, .Precode) {
					return written, Deflate_Error.Huffman_Bad_Code_Lengths
				}

				// decode code lengths
				for n = 0; n < literal_count + distance_count; {
					symbol: i32 = 0
					inflate_refill(&s, written, STREAM)
					symbol = inflate_decode(&s, precode_table[:], 7)
					switch symbol {
					case 16:
						i = 3 + inflate_get(&s, written, 2, STREAM)
						if n == 0 || n + i > literal_count + distance_count { return written, Deflate_Error.Huffman_Bad_Code_Lengths }
						for ; i != 0; i, n = i - 1, n + 1 { lengths[n] = lengths[n - 1] }
					case 17:
						i = 3 + inflate_get(&s, written, 3, STREAM)
						if n + i > literal_count + distance_count { return written, Deflate_Error.Huffman_Bad_Code_Lengths }
						for ; i != 0; i, n = i - 1, n + 1 { lengths[n] = 0 }
					case 18:
						i = 11 + inflate_get(&s, written, 7, STREAM)
						if n + i > literal_count + distance_count { return written, Deflate_Error.Huffman_Bad_Code_Lengths }
						for ; i != 0; i, n = i - 1, n + 1 { lengths[n] = 0 }
					case:
						lengths[n] = u8(symbol)
						n += 1
					}
				}
				// build lit/dist tables
				if lengths[256] == 0 {
					return written, Deflate_Error.Huffman_Bad_Code_Lengths
				}
				if !inflate_build(literals[:], lengths[:literal_count], 10, 15, INFLATE_BAD_LITERAL, LITERAL_KIND) {
					return written, Deflate_Error.Huffman_Bad_Code_Lengths
				}
				if !inflate_build(distances[:], lengths[literal_count:][:distance_count], 8, 15, BAD_DISTANCE, DISTANCE_KIND) {
					return written, Deflate_Error.Huffman_Bad_Code_Lengths
				}
				fixed_loaded = false
				state = .Block
			}

		case .Block:
			// decompress block
			block_loop: for {
				when WINDOWED {
					fast_end := min(capacity, high_water) - INFLATE_FAST_MARGIN
				} else {
					fast_end := capacity - INFLATE_FAST_MARGIN
				}
				for written <= fast_end {
					entry, overrun := inflate_refill_entry_fast(&s, written, literals[:], 10, STREAM)
					if overrun { return written, General_Error.Stream_Too_Short }
					length: int
					if i32(entry) < 0 {
						inflate_skip_fast(&s, entry)
						output[written] = u8(entry >> 16)
						written += 1
						entry = inflate_entry(&s, literals[:], 10)
						if i32(entry) < 0 {
							inflate_skip_fast(&s, entry)
							output[written] = u8(entry >> 16)
							written += 1
							entry = inflate_entry(&s, literals[:], 10)
							if i32(entry) < 0 {
								inflate_skip_fast(&s, entry)
								output[written] = u8(entry >> 16)
								written += 1
								continue
							}
						}
						inflate_skip_code(&s, entry)
						if inflate_refill_fast(&s, written, STREAM) { return written, General_Error.Stream_Too_Short }
						if entry & INFLATE_ENTRY_EXCEPTIONAL == 0 {
							length = inflate_take_extra(&s, entry)
						}
					} else if entry & INFLATE_ENTRY_EXCEPTIONAL == 0 {
						length = inflate_take_fast(&s, entry)
					} else {
						inflate_skip_fast(&s, entry)
					}
					if intrinsics.expect(entry & INFLATE_ENTRY_EXCEPTIONAL != 0, false) {
						s.bit_count &= 63
						if entry & INFLATE_ENTRY_END != 0 {
							if last != 0 {
								if inflate_overrun(&s) { return written, General_Error.Stream_Too_Short }
								state = .Done
								return written, nil
							}
							state = .Header
							break block_loop
						}
						when D64 {
							if entry & INFLATE_ENTRY_LONG == 0 { return written, Deflate_Error.Bad_Huffman_Code }
							length = int(entry >> 16) + int(inflate_get_no_refill(&s, 16))
							if inflate_refill(&s, written, STREAM) { return written, General_Error.Stream_Too_Short }
						} else {
							return written, Deflate_Error.Bad_Huffman_Code
						}
					}
					distance_entry := inflate_entry(&s, distances[:], 8)
					if intrinsics.expect(distance_entry & INFLATE_ENTRY_EXCEPTIONAL != 0, false) {
						inflate_skip(&s, distance_entry)
						return written, Deflate_Error.Bad_Huffman_Code
					}
					distance := inflate_take_fast(&s, distance_entry)
					if intrinsics.expect(distance > written, false) { return written, Deflate_Error.Bad_Distance }
					match_end := written + length
					when D64 {
						if intrinsics.expect(length > DEFLATE_MATCH_MAX, false) {
							output, capacity = inflate_copy_match_checked(output, capacity, grow, start, limit, written, match_end, i32(distance)) or_return
							written = match_end
							continue
						}
					}
					inflate_copy_match(raw_data(output)[written:], raw_data(output)[written - distance:], raw_data(output)[match_end:], i32(distance))
					written = match_end
				}
				s.bit_count &= 63

				when WINDOWED {
					if written >= high_water { return written, nil }
				}
				if inflate_refill(&s, written, STREAM) { return written, General_Error.Stream_Too_Short }
				entry := inflate_entry(&s, literals[:], 10)
				length: int
				if i32(entry) < 0 {
					// literal
					inflate_skip(&s, entry)
					if intrinsics.expect(written >= capacity, false) {
						output   = inflate_grow(grow, start, written + 1, limit) or_return
						capacity = builtin.len(output)
					}
					output[written] = u8(entry >> 16)
					written += 1
					entry = inflate_entry(&s, literals[:], 10)
					if i32(entry) < 0 {
						inflate_skip(&s, entry)
						if intrinsics.expect(written >= capacity, false) {
							output   = inflate_grow(grow, start, written + 1, limit) or_return
							capacity = builtin.len(output)
						}
						output[written] = u8(entry >> 16)
						written += 1
						continue block_loop
					}
					inflate_skip_code(&s, entry)
					if inflate_refill(&s, written, STREAM) { return written, General_Error.Stream_Too_Short }
					if entry & INFLATE_ENTRY_EXCEPTIONAL == 0 {
						length = inflate_take_extra(&s, entry)
					}
				} else if entry & INFLATE_ENTRY_EXCEPTIONAL == 0 {
					length = inflate_take(&s, entry)
				} else {
					inflate_skip(&s, entry)
				}
				if intrinsics.expect(entry & INFLATE_ENTRY_EXCEPTIONAL != 0, false) {
					// end of block
					if entry & INFLATE_ENTRY_END != 0 {
						if last != 0 {
							if inflate_overrun(&s) { return written, General_Error.Stream_Too_Short }
							state = .Done
							return written, nil
						}
						state = .Header
						break block_loop
					}
					when D64 {
						if entry & INFLATE_ENTRY_LONG == 0 { return written, Deflate_Error.Bad_Huffman_Code }
						length = int(entry >> 16) + int(inflate_get_no_refill(&s, 16))
						if inflate_refill(&s, written, STREAM) { return written, General_Error.Stream_Too_Short }
					} else {
						// length codes 286 and 287 must not appear in compressed data
						return written, Deflate_Error.Bad_Huffman_Code
					}
				}
				// match
				{
					distance_entry := inflate_entry(&s, distances[:], 8)
					if intrinsics.expect(distance_entry & INFLATE_ENTRY_EXCEPTIONAL != 0, false) {
						inflate_skip(&s, distance_entry)
						return written, Deflate_Error.Bad_Huffman_Code
					}
					distance := inflate_take(&s, distance_entry)
					if intrinsics.expect(distance > written, false) { return written, Deflate_Error.Bad_Distance }
					match_end := written + length
					if intrinsics.expect(match_end > capacity, false) {
						output   = inflate_grow(grow, start, match_end, limit) or_return
						capacity = builtin.len(output)
					}
					destination := raw_data(output)[written:]
					source      := raw_data(output)[written - distance:]
					out         := raw_data(output)[match_end:]
					written = match_end

					if intrinsics.expect(capacity - match_end >= 16 * 3, true) {
						inflate_copy_match(destination, source, out, i32(distance))
					} else {
						destination[0] = source[0]; destination = destination[1:]; source = source[1:]
						destination[0] = source[0]; destination = destination[1:]; source = source[1:]
						for {
							destination[0] = source[0]; destination = destination[1:]; source = source[1:]
							if !(uintptr(destination) < uintptr(out)) { break }
						}
					}
				}
			}

		case .Done:
			return written, nil
		}
	}
	return written, nil
}

@(private)
inflate_update_checksum :: #force_inline proc(checksum: Inflate_Checksum, digest: ^u32, data: []u8) #no_bounds_check {
	switch checksum {
	case .None:
	case .Adler32: digest^ = hash.adler32(data, digest^)
	case .CRC32:   digest^ = hash.crc32(data, digest^)
	}
}

@(private)
inflate_initial_size :: proc(size_hint, input_size: int, expansion_max := compress.DEFLATE_EXPANSION_MAX) -> (size: int) #no_bounds_check {
	bound := -1
	if input_size >= 0 && input_size < max(int) / expansion_max {
		bound = expansion_max * input_size
	}
	return max(compress.output_reservation(size_hint, bound, input_size), INFLATE_INITIAL_SIZE_MIN)
}

@(private)
inflate_to_buffer :: proc(z: ^compress.Context, expected_output_size: int, p: ^Inflate_Progress, start := 0, size_hint := -1, checksum := Inflate_Checksum.None, digest: ^u32 = nil, $D64: bool) -> (output: []u8, err: Error) #no_bounds_check {
	if z.output == nil {
		return nil, General_Error.Incompatible_Options
	}
	expected := compress.declared_size(expected_output_size)

	limit := compress.output_limit(p.options)
	hint  := size_hint - start if size_hint > start else -1
	if expected >= 0 {
		if expected > limit {
			return nil, General_Error.Output_Too_Short
		}
		limit = expected
		hint  = expected - start
	}
	limit -= start
	if limit < 0 {
		return nil, General_Error.Output_Too_Short
	}

	input_size := compress.input_size(z)

	buffer := z.output
	non_zero_resize(buffer, start + min(inflate_initial_size(hint, input_size, compress.DEFLATE64_EXPANSION_MAX if D64 else compress.DEFLATE_EXPANSION_MAX), limit)) or_return

	d: Inflate_Decoder
	inflate_decoder_init(&d, z)
	p.start    = i64(start)
	d.progress = p
	d.mark     = inflate_progress_mark(p)
	written: int
	if compress.is_memory_context(z) {
		written, err = inflate_decompress(&d, buffer[start:], buffer, start, limit, 0, 0, checksum, digest, false, D64, false)
	} else {
		written, err = inflate_decompress(&d, buffer[start:], buffer, start, limit, 0, 0, checksum, digest, true, D64, false)
	}
	p.bytes_in += inflate_consumed(&d.s)
	if err != nil && inflate_overrun(&d.s) {
		err     = General_Error.Stream_Too_Short
		written = min(written, d.s.checkpoint)
	}
	if err == General_Error.Output_Too_Short && expected >= 0 {
		err = General_Error.Size_Mismatch
	}
	non_zero_resize(buffer, start + written)
	z.bytes_written = i64(start + written)
	return buffer[:start + written], err
}

@(private)
inflate_reader_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	r := (^Reader)(stream_data)
	#partial switch mode {
	case .Read:
		read, read_err := reader_read(r, p)
		n = i64(read)
		if read_err != nil {
			io_err, is_io := read_err.(io.Error)
			err = io_err if is_io else .Unknown
		}
		return
	case .Destroy:
		reader_destroy(r)
		return 0, nil
	case .Query:
		return io.query_utility({.Read, .Destroy, .Query})
	}
	return 0, .Unsupported
}
