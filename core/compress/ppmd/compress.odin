package compress_ppmd

import "base:runtime"
import "core:compress"

compress :: proc{compress_to_slice, compress_to_dynamic}

compress_to_slice :: proc(output, input: []u8, props: Properties, end_marker := false, allocator := context.allocator) -> (written: int, err: Error) {
	w := Writer{buf = raw_data(output), cap = len(output), limit = len(output)}
	encode(&w, input, props, end_marker, allocator) or_return
	return w.pos, nil
}

compress_to_dynamic :: proc(output: ^[dynamic]u8, input: []u8, props: Properties, end_marker := false, allocator := context.allocator) -> (err: Error) {
	if output == nil {
		return General_Error.Incompatible_Options
	}
	context.allocator = allocator
	limit       := compress.COMPRESS_OUTPUT_ALLOCATE_MAX
	reservation := min(compress.output_reservation(len(input) / 2 + 64, -1, len(input)), limit)
	non_zero_resize(output, reservation) or_return

	w := Writer{buf = raw_data(output^), cap = len(output^), grow = output, limit = limit}
	if err = encode(&w, input, props, end_marker, allocator); err != nil {
		non_zero_resize(output, 0)
		return
	}
	non_zero_resize(output, w.pos)
	return nil
}

@(private)
encode :: proc(w: ^Writer, input: []u8, props: Properties, end_marker: bool, allocator: runtime.Allocator) -> (err: Error) {
	if !valid_properties(props) {
		return PPMd_Error.Invalid_Properties
	}
	switch props.variant {
	case .H:
		m: Model_H
		h_init(&m, props, allocator) or_return
		defer sub_allocator_destroy(&m.sub_alloc, allocator)
		rc := Encoder_H{range_ = 0xFFFF_FFFF, cache_size = 1}
		for b in input {
			#force_inline h_encode_symbol(&m, &rc, w, int(b))
			if w.full {
				break
			}
		}
		if end_marker {
			h_encode_symbol(&m, &rc, w, SYM_END)
		}
		for _ in 0..<5 {
			h_shift_low(&rc, w)
		}
	case .I:
		m: Model_I
		i_init(&m, props, allocator) or_return
		defer sub_allocator_destroy(&m.sub_alloc, allocator)
		rc := Coder_I{range_ = 0xFFFF_FFFF}
		for b in input {
			#force_inline i_encode_symbol(&m, &rc, w, int(b))
			if w.full {
				break
			}
		}
		if end_marker {
			i_encode_symbol(&m, &rc, w, SYM_END)
		}
		for _ in 0..<4 {
			writer_byte(w, u8(rc.low >> 24))
			rc.low <<= 8
		}
	}
	if w.err != nil {
		return w.err
	}
	if w.full {
		return General_Error.Output_Too_Short
	}
	return nil
}

@(private)
writer_byte :: #force_inline proc(w: ^Writer, b: u8) #no_bounds_check {
	if w.pos < w.cap || writer_grow(w) {
		w.buf[w.pos] = b
		w.pos += 1
	}
}

@(private)
writer_grow :: proc(w: ^Writer) -> bool {
	if w.grow == nil || w.full || w.pos >= w.limit {
		w.full = true
		return false
	}
	capacity := compress.output_grow_capacity(w.cap, w.pos + 1, w.limit)
	if err := non_zero_resize(w.grow, capacity); err != nil {
		w.err  = err
		w.full = true
		return false
	}
	w.buf = raw_data(w.grow^)
	w.cap = len(w.grow^)
	return true
}

@(private)
h_shift_low :: proc(rc: ^Encoder_H, w: ^Writer) {
	if u32(rc.low) < 0xFF00_0000 || rc.low >> 32 != 0 {
		temp := rc.cache
		for {
			writer_byte(w, temp + u8(rc.low >> 32))
			temp = 0xFF
			rc.cache_size -= 1
			if rc.cache_size == 0 {
				break
			}
		}
		rc.cache = u8(u32(rc.low) >> 24)
	}
	rc.cache_size += 1
	rc.low = u64(u32(rc.low) << 8)
}

@(private)
h_enc_norm_1 :: #force_inline proc(rc: ^Encoder_H, w: ^Writer) {
	if rc.range_ < TOP_7Z {
		rc.range_ <<= 8
		h_shift_low(rc, w)
	}
}

@(private)
h_enc_norm :: #force_inline proc(rc: ^Encoder_H, w: ^Writer) {
	if rc.range_ < TOP_7Z {
		rc.range_ <<= 8
		h_shift_low(rc, w)
		if rc.range_ < TOP_7Z {
			rc.range_ <<= 8
			h_shift_low(rc, w)
		}
	}
}

@(private)
h_rc_encode :: #force_inline proc "contextless" (rc: ^Encoder_H, start, size: u32) {
	rc.low    += u64(start * rc.range_)
	rc.range_ *= size
}

@(private)
h_encode_symbol :: proc(p: ^Model_H, rc: ^Encoder_H, w: ^Writer, symbol: int) #no_bounds_check {
	char_mask: [256]u8 = ---
	mc := p.min_context
	if mc.num_stats != 1 {
		s := h_stats(p, mc)
		rc.range_ /= u32(mc.summ_freq)
		if int(s[0].symbol) == symbol {
			h_rc_encode(rc, 0, u32(s[0].freq))
			h_enc_norm(rc, w)
			p.found_state = &s[0]
			h_update1_0(p)
			return
		}
		p.prev_success = 0
		sum := u32(s[0].freq)
		n   := int(mc.num_stats)
		for k in 1..<n {
			if int(s[k].symbol) == symbol {
				h_rc_encode(rc, sum, u32(s[k].freq))
				h_enc_norm(rc, w)
				p.found_state = &s[k]
				h_update1(p)
				return
			}
			sum += u32(s[k].freq)
		}
		h_rc_encode(rc, sum, u32(mc.summ_freq) - sum)
		p.hi_bits_flag = hi_bits_flag_3(p.found_state.symbol)
		runtime.memset(&char_mask, 0xFF, 256)
		h_mask_all(&char_mask, s, u32(n))
	} else {
		prob  := h_bin_summ(p)
		s     := h_one_state(mc)
		pr    := u32(prob^)
		bound := (rc.range_ >> 14) * pr
		pr -= get_mean(pr)
		if int(s.symbol) == symbol {
			prob^ = u16(pr + (1 << INT_BITS))
			rc.range_ = bound
			h_enc_norm_1(rc, w)
			h_update_bin(p, s)
			return
		}
		prob^ = u16(pr)
		p.init_esc = u32(EXP_ESCAPE[pr >> 10])
		rc.low    += u64(bound)
		rc.range_ -= bound
		runtime.memset(&char_mask, 0xFF, 256)
		char_mask[s.symbol] = 0
		p.prev_success = 0
	}

	for {
		h_enc_norm(rc, w)
		mc = p.min_context
		num_masked := u32(mc.num_stats)
		for {
			p.order_fall += 1
			if mc.suffix == 0 {
				return
			}
			mc = h_ctx(p, mc.suffix)
			if u32(mc.num_stats) != num_masked {
				break
			}
		}
		p.min_context = mc
		see, esc_freq := h_make_esc_freq(p, num_masked)
		s   := h_stats(p, mc)
		n   := int(mc.num_stats)
		sum := u32(0)
		for k in 0..<n {
			cur := s[k].symbol
			if int(cur) == symbol {
				low  := sum
				freq := u32(s[k].freq)
				see_update(see)
				p.found_state = &s[k]
				sum += esc_freq
				for j in k..<n {
					sum += u32(s[j].freq) & u32(char_mask[s[j].symbol])
				}
				rc.range_ /= sum
				h_rc_encode(rc, low, freq)
				h_enc_norm(rc, w)
				h_update2(p)
				return
			}
			sum += u32(s[k].freq) & u32(char_mask[cur])
		}
		total := sum + esc_freq
		see.summ = u16(u32(see.summ) + total)
		rc.range_ /= total
		h_rc_encode(rc, sum, esc_freq)
		h_mask_all(&char_mask, s, u32(n))
	}
}

@(private)
i_enc_norm :: #force_inline proc(rc: ^Coder_I, w: ^Writer) {
	for {
		if (rc.low ~ (rc.low + rc.range_)) >= TOP_I {
			if rc.range_ >= BOT_I {
				break
			}
			rc.range_ = (0 - rc.low) & (BOT_I - 1)
		}
		writer_byte(w, u8(rc.low >> 24))
		rc.range_ <<= 8
		rc.low    <<= 8
	}
}

@(private)
i_rc_encode :: #force_inline proc "contextless" (rc: ^Coder_I, start, size, total: u32) {
	rc.range_ /= total
	rc.low    += start * rc.range_
	rc.range_ *= size
}

@(private)
i_encode_symbol :: proc(p: ^Model_I, rc: ^Coder_I, w: ^Writer, symbol: int) #no_bounds_check {
	char_mask: [256]u8 = ---
	mc := p.min_context
	if mc.num_stats != 0 {
		s         := i_stats(p, mc)
		summ_freq := min(u32(mc.summ_freq), rc.range_)
		if int(s[0].symbol) == symbol {
			i_rc_encode(rc, 0, u32(s[0].freq), summ_freq)
			i_enc_norm(rc, w)
			p.found_state = &s[0]
			i_update1_0(p)
			return
		}
		p.prev_success = 0
		sum := u32(s[0].freq)
		n   := int(mc.num_stats) + 1
		for k in 1..<n {
			if int(s[k].symbol) == symbol {
				i_rc_encode(rc, sum, u32(s[k].freq), summ_freq)
				i_enc_norm(rc, w)
				p.found_state = &s[k]
				i_update1(p)
				return
			}
			sum += u32(s[k].freq)
		}
		i_rc_encode(rc, sum, summ_freq - sum, summ_freq)
		runtime.memset(&char_mask, 0xFF, 256)
		h_mask_all(&char_mask, s, u32(n))
	} else {
		prob  := i_bin_summ(p)
		s     := i_one_state(mc)
		pr    := u32(prob^)
		bound := (rc.range_ >> 14) * pr
		pr -= get_mean(pr)
		if int(s.symbol) == symbol {
			prob^ = u16(pr + (1 << INT_BITS))
			rc.range_ = bound
			i_enc_norm(rc, w)
			i_update_bin(p, s)
			return
		}
		prob^ = u16(pr)
		p.init_esc = u32(EXP_ESCAPE[pr >> 10])
		rc.low    += bound
		rc.range_  = (rc.range_ & ~u32(BIN_SCALE - 1)) - bound
		runtime.memset(&char_mask, 0xFF, 256)
		char_mask[s.symbol] = 0
		p.prev_success = 0
	}

	for {
		i_enc_norm(rc, w)
		mc = p.min_context
		num_masked := u32(mc.num_stats)
		for {
			p.order_fall += 1
			if mc.suffix == 0 {
				return
			}
			mc = i_ctx(p, mc.suffix)
			if u32(mc.num_stats) != num_masked {
				break
			}
		}
		p.min_context = mc
		see, esc_freq := i_make_esc_freq(p, num_masked)
		s   := i_stats(p, mc)
		n   := int(mc.num_stats) + 1
		sum := u32(0)
		for k in 0..<n {
			cur := s[k].symbol
			if int(cur) == symbol {
				low  := sum
				freq := u32(s[k].freq)
				see_update(see)
				p.found_state = &s[k]
				sum += esc_freq
				for j in k..<n {
					sum += u32(s[j].freq) & u32(char_mask[s[j].symbol])
				}
				sum = min(sum, rc.range_)
				i_rc_encode(rc, low, freq, sum)
				i_enc_norm(rc, w)
				i_update2(p)
				return
			}
			sum += u32(s[k].freq) & u32(char_mask[cur])
		}
		total := sum + esc_freq
		see.summ = u16(u32(see.summ) + total)
		total = min(total, rc.range_)
		i_rc_encode(rc, sum, total - sum, total)
		h_mask_all(&char_mask, s, u32(n))
	}
}
