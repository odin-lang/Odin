package compress_ppmd

import "base:runtime"
import "core:compress"
import "core:io"

compress :: proc{compress_to_slice, compress_to_dynamic}

compress_to_slice :: proc(output, input: []u8, props: Properties, end_marker := false, options: compress.Options = {}, allocator := context.allocator) -> (written: int, err: Error) {
	limit := len(output)
	if options.max_output_size > 0 {
		limit = min(limit, options.max_output_size)
	}
	w := Sink{buf = raw_data(output), cap = limit, limit = limit}
	encode(&w, input, props, end_marker, options, allocator) or_return
	return w.pos, nil
}

compress_to_dynamic :: proc(output: ^[dynamic]u8, input: []u8, props: Properties, end_marker := false, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	if output == nil || options.max_output_size < 0 {
		return General_Error.Incompatible_Options
	}
	context.allocator = allocator
	limit       := compress.output_limit(options)
	reservation := min(compress.output_reservation(len(input) / 2 + 64, -1, len(input)), limit)
	non_zero_resize(output, reservation) or_return

	w := Sink{buf = raw_data(output^), cap = len(output^), grow = output, limit = limit}
	if err = encode(&w, input, props, end_marker, options, allocator); err != nil {
		non_zero_resize(output, 0)
		return
	}
	non_zero_resize(output, w.pos)
	return nil
}

writer_init :: proc(pw: ^Writer, w: io.Writer, props: Properties, end_marker := false, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	pw^ = {}
	pw.allocator  = allocator
	pw.options    = options
	pw.end_marker = end_marker
	defer pw.err = err

	if options.max_output_size < 0 || options.max_memory < 0 || options.chunk_size < 0 || options.progress_interval < 0 {
		return General_Error.Incompatible_Options
	}
	if options.buffer != nil && len(options.buffer) == 0 {
		return General_Error.Incompatible_Options
	}
	check_properties(props) or_return
	window := 0
	if options.buffer == nil {
		window = options.chunk_size if options.chunk_size > 0 else CHUNK_SIZE
	}
	if u64(props.mem_size) > u64(MEMORY_MAX) || u64(props.mem_size) + u64(window) > u64(compress.memory_limit(options)) {
		return General_Error.Memory_Limit_Exceeded
	}
	if options.buffer != nil {
		pw.window = options.buffer
	} else {
		pw.window      = non_zero_make([]u8, window, allocator) or_return
		pw.owns_window = true
	}
	pw.sink = Sink{buf = raw_data(pw.window), cap = len(pw.window), limit = len(pw.window), stream = w}

	switch props.variant {
	case .H:
		pw.model_h = new(Model_H, allocator) or_return
		h_init(pw.model_h, props, allocator) or_return
		pw.rc_h = Encoder_H{range_ = 0xFFFF_FFFF, cache_size = 1}
	case .I:
		pw.model_i = new(Model_I, allocator) or_return
		i_init(pw.model_i, props, allocator) or_return
		pw.rc_i = Coder_I{range_ = 0xFFFF_FFFF}
	}
	return nil
}

writer_write :: proc(pw: ^Writer, p: []u8) -> (n: int, err: Error) {
	if pw.err != nil {
		return 0, pw.err
	}
	if pw.finished {
		return 0, io.Error.Closed
	}
	defer pw.err = err
	for n < len(p) {
		done: int
		if pw.model_h != nil {
			done = encode_input(pw.model_h, &pw.rc_h, &pw.sink, p[n:])
		} else {
			done = encode_input(pw.model_i, &pw.rc_i, &pw.sink, p[n:])
		}
		n           += done
		pw.total_in += i64(done)
		if pw.sink.stop {
			pw.sink.stop = false
			if pw.sink.err != nil {
				return n, pw.sink.err
			}
			writer_progress(pw) or_return
		}
	}
	return n, nil
}

writer_finish :: proc(pw: ^Writer) -> (err: Error) {
	if pw.err != nil {
		return pw.err
	}
	if pw.finished {
		return nil
	}
	defer pw.err = err
	w := &pw.sink
	if pw.model_h != nil {
		encode_end(pw.model_h, &pw.rc_h, w, pw.end_marker)
	} else {
		encode_end(pw.model_i, &pw.rc_i, w, pw.end_marker)
	}
	w.stop = false
	if w.err != nil {
		return w.err
	}
	if w.pos > 0 {
		if _, write_err := io.write_full(w.stream, w.buf[:w.pos]); write_err != nil {
			return write_err
		}
		w.flushed += i64(w.pos)
		w.pos      = 0
	}
	pw.finished = true
	return writer_progress(pw)
}

writer_to_stream :: proc(pw: ^Writer) -> (s: io.Stream) {
	s.data      = pw
	s.procedure = writer_stream_proc
	return
}

writer_destroy :: proc(pw: ^Writer) {
	if pw.model_h != nil {
		sub_allocator_destroy(&pw.model_h.sub_alloc, pw.allocator)
		free(pw.model_h, pw.allocator)
	}
	if pw.model_i != nil {
		sub_allocator_destroy(&pw.model_i.sub_alloc, pw.allocator)
		free(pw.model_i, pw.allocator)
	}
	if pw.owns_window {
		delete(pw.window, pw.allocator)
	}
	pw.model_h     = nil
	pw.model_i     = nil
	pw.window      = nil
	pw.sink        = {}
	pw.owns_window = false
}

@(private)
writer_progress :: proc(pw: ^Writer) -> (err: Error) {
	return compress.report_progress(pw.options, pw.total_in, pw.sink.flushed, -1, -1)
}

@(private)
writer_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	pw := (^Writer)(stream_data)
	#partial switch mode {
	case .Write:
		written, write_err := writer_write(pw, p)
		n = i64(written)
		if write_err != nil {
			io_err, is_io := write_err.(io.Error)
			err = io_err if is_io else .Unknown
		}
		return
	case .Close:
		if finish_err := writer_finish(pw); finish_err != nil {
			io_err, is_io := finish_err.(io.Error)
			err = io_err if is_io else .Unknown
		}
		return
	case .Destroy:
		writer_destroy(pw)
		return 0, nil
	case .Query:
		return io.query_utility({.Write, .Close, .Destroy, .Query})
	}
	return 0, .Unsupported
}

@(private)
encode :: proc(w: ^Sink, input: []u8, props: Properties, end_marker: bool, options: compress.Options, allocator: runtime.Allocator) -> (err: Error) {
	if options.max_output_size < 0 || options.max_memory < 0 || options.progress_interval < 0 {
		return General_Error.Incompatible_Options
	}
	check_properties(props) or_return
	if u64(props.mem_size) > u64(min(compress.memory_limit(options), MEMORY_MAX)) {
		return General_Error.Memory_Limit_Exceeded
	}
	switch props.variant {
	case .H:
		m: Model_H
		h_init(&m, props, allocator) or_return
		defer sub_allocator_destroy(&m.sub_alloc, allocator)
		rc := Encoder_H{range_ = 0xFFFF_FFFF, cache_size = 1}
		encode_all(&m, &rc, w, input, end_marker, options) or_return
	case .I:
		m: Model_I
		i_init(&m, props, allocator) or_return
		defer sub_allocator_destroy(&m.sub_alloc, allocator)
		rc := Coder_I{range_ = 0xFFFF_FFFF}
		encode_all(&m, &rc, w, input, end_marker, options) or_return
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
encode_all :: proc(m: ^$M, rc: ^$R, w: ^Sink, input: []u8, end_marker: bool, options: compress.Options) -> (err: Error) {
	step := len(input)
	if options.progress != nil {
		step = min(step, compress.progress_interval(options))
	}
	done := 0
	for done < len(input) {
		done += encode_input(m, rc, w, input[done:][:min(step, len(input) - done)])
		if w.stop {
			return nil
		}
		compress.report_progress(options, i64(done), i64(w.pos), i64(len(input)), -1) or_return
	}
	encode_end(m, rc, w, end_marker)
	return nil
}

@(private)
encode_input :: proc(m: ^$M, rc: ^$R, w: ^Sink, input: []u8) -> (n: int) {
	r := rc^
	defer rc^ = r
	for b, i in input {
		when M == Model_H {
			#force_inline h_encode_symbol(m, &r, w, int(b))
		} else {
			#force_inline i_encode_symbol(m, &r, w, int(b))
		}
		if w.stop {
			return i + 1
		}
	}
	return len(input)
}

@(private)
encode_end :: proc(m: ^$M, rc: ^$R, w: ^Sink, end_marker: bool) {
	when M == Model_H {
		if end_marker {
			h_encode_symbol(m, rc, w, SYM_END)
		}
		for _ in 0..<5 {
			h_shift_low(rc, w)
		}
	} else {
		if end_marker {
			i_encode_symbol(m, rc, w, SYM_END)
		}
		for _ in 0..<4 {
			sink_byte(w, u8(rc.low >> 24))
			rc.low <<= 8
		}
	}
}

@(private)
sink_byte :: #force_inline proc(w: ^Sink, b: u8) #no_bounds_check {
	if w.pos < w.cap || sink_grow(w) {
		w.buf[w.pos] = b
		w.pos += 1
	}
}

@(private)
sink_grow :: proc(w: ^Sink) -> bool {
	if w.stream.procedure != nil {
		if w.err != nil {
			return false
		}
		if _, err := io.write_full(w.stream, w.buf[:w.pos]); err != nil {
			w.err  = err
			w.stop = true
			return false
		}
		w.flushed += i64(w.pos)
		w.pos      = 0
		w.stop     = true
		return w.cap > 0
	}
	if w.grow == nil || w.full || w.pos >= w.limit {
		w.full = true
		w.stop = true
		return false
	}
	capacity := compress.output_grow_capacity(w.cap, w.pos + 1, w.limit)
	if err := non_zero_resize(w.grow, capacity); err != nil {
		w.err  = err
		w.full = true
		w.stop = true
		return false
	}
	w.buf = raw_data(w.grow^)
	w.cap = len(w.grow^)
	return true
}

@(private)
h_shift_low :: proc(rc: ^Encoder_H, w: ^Sink) {
	if u32(rc.low) < 0xFF00_0000 || rc.low >> 32 != 0 {
		temp := rc.cache
		for {
			sink_byte(w, temp + u8(rc.low >> 32))
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
h_enc_norm_1 :: #force_inline proc(rc: ^Encoder_H, w: ^Sink) {
	if rc.range_ < TOP_7Z {
		rc.range_ <<= 8
		h_shift_low(rc, w)
	}
}

@(private)
h_enc_norm :: #force_inline proc(rc: ^Encoder_H, w: ^Sink) {
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
h_encode_symbol :: proc(p: ^Model_H, rc: ^Encoder_H, w: ^Sink, symbol: int) #no_bounds_check {
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
i_enc_norm :: #force_inline proc(rc: ^Coder_I, w: ^Sink) {
	for {
		if (rc.low ~ (rc.low + rc.range_)) >= TOP_I {
			if rc.range_ >= BOT_I {
				break
			}
			rc.range_ = (0 - rc.low) & (BOT_I - 1)
		}
		sink_byte(w, u8(rc.low >> 24))
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
i_encode_symbol :: proc(p: ^Model_I, rc: ^Coder_I, w: ^Sink, symbol: int) #no_bounds_check {
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
