package compress_ppmd

import "base:runtime"
import "core:compress"

decompress :: proc{decompress_from_bytes, decompress_from_context}

decompress_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, props: Properties, expected_output_size := -1, max_output_size := compress.COMPRESS_OUTPUT_ALLOCATE_MAX, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return decompress_from_context(&ctx, props, expected_output_size, max_output_size, allocator)
}

decompress_from_context :: proc(z: ^compress.Context, props: Properties, expected_output_size := -1, max_output_size := compress.COMPRESS_OUTPUT_ALLOCATE_MAX, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	if z.output == nil || max_output_size < 0 {
		return General_Error.Incompatible_Options
	}
	if !valid_properties(props) {
		return PPMd_Error.Invalid_Properties
	}
	expected := expected_output_size
	if expected < 0 && z.size_unpacked >= 0 && z.size_unpacked <= i64(max(int)) {
		expected = int(z.size_unpacked)
	}
	if expected > max_output_size {
		return General_Error.Output_Too_Short
	}

	o := output_begin(z, expected, max_output_size)
	defer output_end(z, &o)
	r := Reader{buf = z.window, z = z}
	defer z.window = z.window[min(r.pos, len(z.window)):]

	switch props.variant {
	case .H:
		m: Model_H
		h_init(&m, props, allocator) or_return
		defer sub_allocator_destroy(&m.sub_alloc, allocator)
		return h_decode(&m, &r, &o, expected)
	case .I:
		m: Model_I
		i_init(&m, props, allocator) or_return
		defer sub_allocator_destroy(&m.sub_alloc, allocator)
		return i_decode(&m, &r, &o, expected)
	}
	return PPMd_Error.Invalid_Properties
}

@(private)
Output :: struct {
	buf:     ^[dynamic]u8,
	written: int,
	limit:   int,
}

@(private)
output_begin :: proc(z: ^compress.Context, declared, max_output_size: int) -> (o: Output) {
	o.buf   = z.output
	o.limit = declared if declared >= 0 else max_output_size
	reservation := min(compress.output_reservation(declared, -1, compress.input_size(z)), o.limit)
	if non_zero_resize(o.buf, reservation) != nil {
		non_zero_resize(o.buf, 0)
	}
	return
}

@(private)
output_end :: proc(z: ^compress.Context, o: ^Output) {
	non_zero_resize(o.buf, o.written)
	z.bytes_written = i64(o.written)
}

@(private)
output_grow :: proc(o: ^Output) -> (err: Error) {
	if o.written >= o.limit {
		return General_Error.Output_Too_Short
	}
	non_zero_resize(o.buf, compress.output_grow_capacity(len(o.buf^), o.written + 1, o.limit)) or_return
	return nil
}

@(private)
reader_byte :: #force_inline proc(r: ^Reader) -> u8 #no_bounds_check {
	if r.pos < len(r.buf) {
		b := r.buf[r.pos]
		r.pos += 1
		return b
	}
	return reader_refill(r)
}

@(private)
reader_refill :: proc(r: ^Reader) -> u8 {
	if r.overrun {
		return 0
	}
	r.z.window = r.z.window[r.pos:]
	r.buf = nil
	r.pos = 0
	if compress.refill_window(r.z, 1) != nil || len(r.z.window) == 0 {
		r.overrun = true
		return 0
	}
	r.buf = r.z.window
	r.pos = 1
	return r.buf[0]
}

@(private)
decode_one :: #force_inline proc(m: ^$M, rc: ^$R, r: ^Reader) -> int {
	when M == Model_H {
		return h_decode_symbol(m, rc, r)
	} else {
		return i_decode_symbol(m, rc, r)
	}
}

@(private)
decode_loop :: proc(m: ^$M, rc: ^$R, r: ^Reader, o: ^Output, size: int) -> (sym: int, err: Error) #no_bounds_check {
	target := size if size >= 0 else o.limit
	out    := raw_data(o.buf^)
	avail  := min(len(o.buf^), target)
	for o.written < target {
		if o.written >= avail {
			output_grow(o) or_return
			out   = raw_data(o.buf^)
			avail = min(len(o.buf^), target)
		}
		sym = decode_one(m, rc, r)
		if sym < 0 {
			return sym, nil
		}
		if r.overrun {
			return sym, General_Error.Stream_Too_Short
		}
		out[o.written] = u8(sym)
		o.written += 1
	}
	if size < 0 {
		sym = decode_one(m, rc, r)
		if sym >= 0 {
			return sym, General_Error.Output_Too_Short
		}
		return sym, nil
	}
	return 0, nil
}

@(private)
finish :: proc(sym: int, size, written: int, overrun: bool, code_zero: bool) -> (err: Error) {
	if overrun {
		return General_Error.Stream_Too_Short
	}
	if sym == SYM_ERROR {
		return PPMd_Error.Corrupt_Data
	}
	if sym == SYM_END && size >= 0 && written != size {
		return PPMd_Error.Unexpected_End_Marker
	}
	if !code_zero {
		return PPMd_Error.Corrupt_Data
	}
	return nil
}

@(private)
h_decode :: proc(m: ^Model_H, r: ^Reader, o: ^Output, size: int) -> (err: Error) {
	rc: Decoder_H
	if reader_byte(r) != 0 {
		return General_Error.Stream_Too_Short if r.overrun else PPMd_Error.Corrupt_Data
	}
	for _ in 0..<4 {
		rc.code = rc.code << 8 | u32(reader_byte(r))
	}
	rc.range_ = 0xFFFF_FFFF
	if r.overrun {
		return General_Error.Stream_Too_Short
	}
	if rc.code == 0xFFFF_FFFF {
		return PPMd_Error.Corrupt_Data
	}
	sym := decode_loop(m, &rc, r, o, size) or_return
	if sym >= 0 && rc.code != 0 {
		sym = h_decode_symbol(m, &rc, r)
		if sym != SYM_END {
			return PPMd_Error.Corrupt_Data if !r.overrun else General_Error.Stream_Too_Short
		}
	}
	return finish(sym, size, o.written, r.overrun, rc.code == 0)
}

@(private)
i_decode :: proc(m: ^Model_I, r: ^Reader, o: ^Output, size: int) -> (err: Error) {
	rc: Coder_I
	for _ in 0..<4 {
		rc.code = rc.code << 8 | u32(reader_byte(r))
	}
	rc.range_ = 0xFFFF_FFFF
	if r.overrun {
		return General_Error.Stream_Too_Short
	}
	if rc.code == 0xFFFF_FFFF {
		return PPMd_Error.Corrupt_Data
	}
	sym := decode_loop(m, &rc, r, o, size) or_return
	if sym >= 0 && rc.code != 0 {
		sym = i_decode_symbol(m, &rc, r)
		if sym != SYM_END {
			return PPMd_Error.Corrupt_Data if !r.overrun else General_Error.Stream_Too_Short
		}
	}
	return finish(sym, size, o.written, r.overrun, rc.code == 0)
}

@(private)
h_rc_norm_1 :: #force_inline proc(rc: ^Decoder_H, r: ^Reader) {
	if rc.range_ < TOP_7Z {
		rc.code    = rc.code << 8 | u32(reader_byte(r))
		rc.range_ <<= 8
	}
}

@(private)
h_rc_norm :: #force_inline proc(rc: ^Decoder_H, r: ^Reader) {
	if rc.range_ < TOP_7Z {
		rc.code    = rc.code << 8 | u32(reader_byte(r))
		rc.range_ <<= 8
		if rc.range_ < TOP_7Z {
			rc.code    = rc.code << 8 | u32(reader_byte(r))
			rc.range_ <<= 8
		}
	}
}

@(private)
h_rc_decode :: #force_inline proc "contextless" (rc: ^Decoder_H, start, size: u32) {
	rc.code   -= start * rc.range_
	rc.range_ *= size
}

@(private)
h_decode_symbol :: proc(p: ^Model_H, rc: ^Decoder_H, r: ^Reader) -> int #no_bounds_check {
	char_mask: [256]u8 = ---
	mc := p.min_context
	if mc.num_stats != 1 {
		s         := h_stats(p, mc)
		summ_freq := u32(mc.summ_freq)
		rc.range_ /= summ_freq
		count  := rc.code / rc.range_
		hi_cnt := count
		count -= u32(s[0].freq)
		if i32(count) < 0 {
			h_rc_decode(rc, 0, u32(s[0].freq))
			h_rc_norm(rc, r)
			p.found_state = &s[0]
			sym := s[0].symbol
			h_update1_0(p)
			return int(sym)
		}
		p.prev_success = 0
		n := int(mc.num_stats)
		k := 1
		for ; k < n; k += 1 {
			count -= u32(s[k].freq)
			if i32(count) < 0 {
				h_rc_decode(rc, (hi_cnt - count) - u32(s[k].freq), u32(s[k].freq))
				h_rc_norm(rc, r)
				p.found_state = &s[k]
				sym := s[k].symbol
				h_update1(p)
				return int(sym)
			}
		}
		if hi_cnt >= summ_freq {
			return SYM_ERROR
		}
		hi_cnt -= count
		h_rc_decode(rc, hi_cnt, summ_freq - hi_cnt)
		p.hi_bits_flag = hi_bits_flag_3(p.found_state.symbol)
		runtime.memset(&char_mask, 0xFF, 256)
		h_mask_all(&char_mask, s, u32(n))
	} else {
		s    := h_one_state(mc)
		prob := h_bin_summ(p)
		pr   := u32(prob^)
		size0 := (rc.range_ >> 14) * pr
		pr -= get_mean(pr)
		if rc.code < size0 {
			prob^ = u16(pr + (1 << INT_BITS))
			rc.range_ = size0
			h_rc_norm_1(rc, r)
			sym := s.symbol
			h_update_bin(p, s)
			return int(sym)
		}
		prob^ = u16(pr)
		p.init_esc = u32(EXP_ESCAPE[pr >> 10])
		rc.code   -= size0
		rc.range_ -= size0
		runtime.memset(&char_mask, 0xFF, 256)
		char_mask[s.symbol] = 0
		p.prev_success = 0
	}

	for {
		h_rc_norm(rc, r)
		mc = p.min_context
		num_masked := u32(mc.num_stats)
		for {
			p.order_fall += 1
			if mc.suffix == 0 {
				return SYM_END
			}
			mc = h_ctx(p, mc.suffix)
			if u32(mc.num_stats) != num_masked {
				break
			}
		}
		s := h_stats(p, mc)
		n := int(mc.num_stats)
		hi_cnt: u32
		for k in 0..<n {
			hi_cnt += u32(s[k].freq) & u32(char_mask[s[k].symbol])
		}
		p.min_context = mc
		see, freq_sum := h_make_esc_freq(p, num_masked)
		freq_sum += hi_cnt
		rc.range_ /= freq_sum
		count := rc.code / rc.range_

		if count < hi_cnt {
			hi_cnt = count
			k := 0
			for {
				count -= u32(s[k].freq) & u32(char_mask[s[k].symbol])
				k += 1
				if i32(count) < 0 {
					break
				}
			}
			k -= 1
			h_rc_decode(rc, (hi_cnt - count) - u32(s[k].freq), u32(s[k].freq))
			h_rc_norm(rc, r)
			see_update(see)
			p.found_state = &s[k]
			sym := s[k].symbol
			h_update2(p)
			return int(sym)
		}
		if count >= freq_sum {
			return SYM_ERROR
		}
		h_rc_decode(rc, hi_cnt, freq_sum - hi_cnt)
		see.summ = u16(u32(see.summ) + freq_sum)
		h_mask_all(&char_mask, s, u32(n))
	}
}

@(private)
i_rc_norm :: #force_inline proc(rc: ^Coder_I, r: ^Reader) {
	for {
		if (rc.low ~ (rc.low + rc.range_)) >= TOP_I {
			if rc.range_ >= BOT_I {
				break
			}
			rc.range_ = (0 - rc.low) & (BOT_I - 1)
		}
		rc.code    = rc.code << 8 | u32(reader_byte(r))
		rc.range_ <<= 8
		rc.low    <<= 8
	}
}

@(private)
i_rc_decode :: #force_inline proc "contextless" (rc: ^Coder_I, start, size: u32) {
	st := start * rc.range_
	rc.low    += st
	rc.code   -= st
	rc.range_ *= size
}

@(private)
i_decode_symbol :: proc(p: ^Model_I, rc: ^Coder_I, r: ^Reader) -> int #no_bounds_check {
	char_mask: [256]u8 = ---
	mc := p.min_context
	if mc.num_stats != 0 {
		s         := i_stats(p, mc)
		summ_freq := min(u32(mc.summ_freq), rc.range_)
		rc.range_ /= summ_freq
		count  := rc.code / rc.range_
		hi_cnt := count
		count -= u32(s[0].freq)
		if i32(count) < 0 {
			i_rc_decode(rc, 0, u32(s[0].freq))
			i_rc_norm(rc, r)
			p.found_state = &s[0]
			sym := s[0].symbol
			i_update1_0(p)
			return int(sym)
		}
		p.prev_success = 0
		n := int(mc.num_stats) + 1
		k := 1
		for ; k < n; k += 1 {
			count -= u32(s[k].freq)
			if i32(count) < 0 {
				i_rc_decode(rc, (hi_cnt - count) - u32(s[k].freq), u32(s[k].freq))
				i_rc_norm(rc, r)
				p.found_state = &s[k]
				sym := s[k].symbol
				i_update1(p)
				return int(sym)
			}
		}
		if hi_cnt >= summ_freq {
			return SYM_ERROR
		}
		hi_cnt -= count
		i_rc_decode(rc, hi_cnt, summ_freq - hi_cnt)
		runtime.memset(&char_mask, 0xFF, 256)
		h_mask_all(&char_mask, s, u32(n))
	} else {
		s    := i_one_state(mc)
		prob := i_bin_summ(p)
		pr   := u32(prob^)
		size0 := (rc.range_ >> 14) * pr
		pr -= get_mean(pr)
		if rc.code < size0 {
			prob^ = u16(pr + (1 << INT_BITS))
			rc.range_ = size0
			i_rc_norm(rc, r)
			sym := s.symbol
			i_update_bin(p, s)
			return int(sym)
		}
		prob^ = u16(pr)
		p.init_esc = u32(EXP_ESCAPE[pr >> 10])
		rc.low    += size0
		rc.code   -= size0
		rc.range_  = (rc.range_ & ~u32(BIN_SCALE - 1)) - size0
		runtime.memset(&char_mask, 0xFF, 256)
		char_mask[s.symbol] = 0
		p.prev_success = 0
	}

	for {
		i_rc_norm(rc, r)
		mc = p.min_context
		num_masked := u32(mc.num_stats)
		for {
			p.order_fall += 1
			if mc.suffix == 0 {
				return SYM_END
			}
			mc = i_ctx(p, mc.suffix)
			if u32(mc.num_stats) != num_masked {
				break
			}
		}
		s := i_stats(p, mc)
		n := int(mc.num_stats) + 1
		hi_cnt: u32
		for k in 0..<n {
			hi_cnt += u32(s[k].freq) & u32(char_mask[s[k].symbol])
		}
		p.min_context = mc
		see, freq_sum := i_make_esc_freq(p, num_masked)
		freq_sum += hi_cnt
		freq_sum2 := min(freq_sum, rc.range_)
		rc.range_ /= freq_sum2
		count := rc.code / rc.range_

		if count < hi_cnt {
			hi_cnt = count
			k := 0
			for {
				count -= u32(s[k].freq) & u32(char_mask[s[k].symbol])
				k += 1
				if i32(count) < 0 {
					break
				}
			}
			k -= 1
			i_rc_decode(rc, (hi_cnt - count) - u32(s[k].freq), u32(s[k].freq))
			i_rc_norm(rc, r)
			see_update(see)
			p.found_state = &s[k]
			sym := s[k].symbol
			i_update2(p)
			return int(sym)
		}
		if count >= freq_sum2 {
			return SYM_ERROR
		}
		i_rc_decode(rc, hi_cnt, freq_sum2 - hi_cnt)
		see.summ = u16(u32(see.summ) + freq_sum)
		h_mask_all(&char_mask, s, u32(n))
	}
}
