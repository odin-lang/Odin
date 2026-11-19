package compress_ppmd

import "base:runtime"
import "core:compress"
import "core:io"

decompress :: proc{decompress_from_bytes, decompress_from_context}

decompress_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, props: Properties, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return decompress_from_context(&ctx, props, expected_output_size, options, allocator)
}

decompress_from_context :: proc(z: ^compress.Context, props: Properties, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	max_output_size := compress.output_limit(options)
	if z.output == nil || max_output_size < 0 || options.max_memory < 0 || options.progress_interval < 0 {
		return General_Error.Incompatible_Options
	}
	check_properties(props) or_return
	if u64(props.mem_size) > u64(min(compress.memory_limit(options), MEMORY_MAX)) {
		return General_Error.Memory_Limit_Exceeded
	}
	expected := compress.declared_size(expected_output_size)
	if expected > max_output_size {
		return General_Error.Output_Too_Short
	}

	total_in := i64(compress.input_size(z)) if options.progress != nil else -1
	o := output_begin(z, expected, max_output_size)
	defer output_end(z, &o)
	d := Decoder{input = {buf = z.window, z = z}, size = i64(expected), limit = i64(max_output_size)}
	defer z.window = z.window[min(d.input.pos, len(z.window)):]

	switch props.variant {
	case .H:
		m: Model_H
		h_init(&m, props, allocator) or_return
		defer sub_allocator_destroy(&m.sub_alloc, allocator)
		d.model_h = &m
		return decode_to_output(&d, &o, options, total_in)
	case .I:
		m: Model_I
		i_init(&m, props, allocator) or_return
		defer sub_allocator_destroy(&m.sub_alloc, allocator)
		d.model_i = &m
		return decode_to_output(&d, &o, options, total_in)
	}
	return PPMd_Error.Invalid_Properties
}

decompress_to_writer :: proc(w: io.Writer, z: ^compress.Context, props: Properties, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	r: Reader
	defer reader_destroy(&r)
	defer decoder_sync(&r.decoder)
	stream_init(&r, z, props, expected_output_size, options, allocator, true) or_return
	for !r.decoder.done {
		n, fill_err := decoder_fill(&r.decoder, r.window)
		if n > 0 {
			if _, write_err := io.write_full(w, r.window[:n]); write_err != nil {
				return write_err
			}
		}
		if fill_err != nil {
			return fill_err
		}
		reader_progress(&r) or_return
	}
	return nil
}

reader_init :: proc(r: ^Reader, z: ^compress.Context, props: Properties, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	err   = stream_init(r, z, props, expected_output_size, options, allocator, false)
	r.err = err
	return
}

reader_read :: proc(r: ^Reader, p: []u8) -> (n: int, err: Error) {
	if len(p) > 0 && r.err == nil && !r.decoder.done {
		n, r.err = decoder_fill(&r.decoder, p)
		decoder_sync(&r.decoder)
		if r.err == nil && (n > 0 || r.decoder.done) {
			r.err = reader_progress(r)
		}
	}
	if n > 0 {
		return n, nil
	}
	if r.err != nil {
		return 0, r.err
	}
	if len(p) > 0 && r.decoder.done {
		return 0, io.Error.EOF
	}
	return 0, nil
}

reader_to_stream :: proc(r: ^Reader) -> (s: io.Stream) {
	s.data      = r
	s.procedure = reader_stream_proc
	return
}

reader_destroy :: proc(r: ^Reader) {
	d := &r.decoder
	if d.model_h != nil {
		sub_allocator_destroy(&d.model_h.sub_alloc, r.allocator)
		free(d.model_h, r.allocator)
	}
	if d.model_i != nil {
		sub_allocator_destroy(&d.model_i.sub_alloc, r.allocator)
		free(d.model_i, r.allocator)
	}
	if r.owns_window {
		delete(r.window, r.allocator)
	}
	d.model_h     = nil
	d.model_i     = nil
	r.window      = nil
	r.owns_window = false
}

@(private)
stream_init :: proc(r: ^Reader, z: ^compress.Context, props: Properties, expected_output_size: int, options: compress.Options, allocator: runtime.Allocator, chunked: bool) -> (err: Error) {
	r^ = {}
	r.allocator = allocator
	r.options   = options
	r.total_in  = -1
	d := &r.decoder
	d.input = Input{buf = z.window, z = z}
	d.size  = -1
	d.limit = max(i64)

	if options.max_output_size < 0 || options.max_memory < 0 || options.chunk_size < 0 || options.progress_interval < 0 {
		return General_Error.Incompatible_Options
	}
	if chunked && options.buffer != nil && len(options.buffer) == 0 {
		return General_Error.Incompatible_Options
	}
	check_properties(props) or_return
	expected := i64(compress.declared_size(expected_output_size))
	if options.max_output_size > 0 {
		d.limit = i64(options.max_output_size)
	}
	if expected >= 0 {
		if expected > d.limit {
			return General_Error.Output_Too_Short
		}
		d.size = expected
	}

	window := 0
	if chunked && options.buffer == nil {
		window = options.chunk_size if options.chunk_size > 0 else CHUNK_SIZE
		if d.size > 0 && d.size < i64(window) {
			window = int(d.size)
		}
	}
	if u64(props.mem_size) > u64(MEMORY_MAX) || u64(props.mem_size) + u64(window) > u64(compress.memory_limit(options)) {
		return General_Error.Memory_Limit_Exceeded
	}
	if chunked {
		if options.buffer != nil {
			r.window = options.buffer
		} else {
			r.window      = non_zero_make([]u8, max(window, 1), allocator) or_return
			r.owns_window = true
		}
	}

	switch props.variant {
	case .H:
		d.model_h = new(Model_H, allocator) or_return
		h_init(d.model_h, props, allocator) or_return
	case .I:
		d.model_i = new(Model_I, allocator) or_return
		i_init(d.model_i, props, allocator) or_return
	}
	if options.progress != nil {
		r.total_in = i64(compress.input_size(z))
	}
	return decoder_start(d)
}

@(private)
reader_progress :: proc(r: ^Reader) -> (err: Error) {
	d := &r.decoder
	return compress.report_progress(r.options, d.input.consumed + i64(d.input.pos), d.written, r.total_in, d.size)
}

@(private)
reader_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
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
	return non_zero_resize(o.buf, compress.output_grow_capacity(len(o.buf^), o.written + 1, o.limit))
}

@(private)
decode_to_output :: proc(d: ^Decoder, o: ^Output, options: compress.Options, total_in: i64) -> (err: Error) {
	decoder_start(d) or_return
	target   := d.size if d.size >= 0 else d.limit
	interval := compress.progress_interval(options)
	mark     := max(int)
	if options.progress != nil {
		mark = interval if interval < max(int) else max(int)
	}
	for !d.done {
		if o.written >= len(o.buf^) && i64(o.written) < target {
			output_grow(o) or_return
		}
		n, fill_err := decoder_fill(d, o.buf[o.written:min(len(o.buf^), mark)])
		o.written += n
		if fill_err != nil {
			return fill_err
		}
		if o.written >= mark {
			compress.report_progress(options, d.input.consumed + i64(d.input.pos), i64(o.written), total_in, d.size) or_return
			mark = o.written + interval if interval < max(int) - o.written else max(int)
		}
	}
	return nil
}

@(private)
input_byte :: #force_inline proc(r: ^Input) -> u8 #no_bounds_check {
	if r.pos < len(r.buf) {
		b := r.buf[r.pos]
		r.pos += 1
		return b
	}
	return input_refill(r)
}

@(private)
input_refill :: proc(r: ^Input) -> u8 {
	if r.overrun {
		return 0
	}
	r.consumed += i64(r.pos)
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
decoder_sync :: proc(d: ^Decoder) {
	r := &d.input
	if r.z == nil {
		return
	}
	pos := min(r.pos, len(r.z.window))
	r.consumed += i64(pos)
	r.z.window = r.z.window[pos:]
	r.z.bytes_written = d.written
	r.buf = r.z.window
	r.pos = 0
}

@(private)
decode_one :: #force_inline proc(m: ^$M, rc: ^$R, r: ^Input) -> int {
	when M == Model_H {
		return h_decode_symbol(m, rc, r)
	} else {
		return i_decode_symbol(m, rc, r)
	}
}

@(private)
decoder_start :: proc(d: ^Decoder) -> (err: Error) {
	r := &d.input
	if d.model_h != nil {
		if input_byte(r) != 0 {
			return General_Error.Stream_Too_Short if r.overrun else PPMd_Error.Corrupt_Data
		}
		return rc_start(r, &d.rc_h)
	}
	return rc_start(r, &d.rc_i)
}

@(private)
rc_start :: proc(r: ^Input, rc: ^$R) -> (err: Error) {
	for _ in 0..<4 {
		rc.code = rc.code << 8 | u32(input_byte(r))
	}
	rc.range_ = 0xFFFF_FFFF
	if r.overrun {
		return General_Error.Stream_Too_Short
	}
	if rc.code == 0xFFFF_FFFF {
		return PPMd_Error.Corrupt_Data
	}
	return nil
}

@(private)
decoder_fill :: proc(d: ^Decoder, out: []u8) -> (n: int, err: Error) {
	if d.model_h != nil {
		return decode_into(d, d.model_h, &d.rc_h, out)
	}
	return decode_into(d, d.model_i, &d.rc_i, out)
}

@(private)
decode_into :: proc(d: ^Decoder, m: ^$M, rc: ^$R, out: []u8) -> (n: int, err: Error) #no_bounds_check {
	if d.done {
		return 0, nil
	}
	r    := &d.input
	left := (d.size if d.size >= 0 else d.limit) - d.written
	room := int(min(i64(len(out)), left))
	dst  := raw_data(out)
	for n < room {
		sym := decode_one(m, rc, r)
		if sym < 0 {
			d.written += i64(n)
			return n, decode_end(d, m, rc, sym)
		}
		if r.overrun {
			d.written += i64(n)
			d.done = true
			return n, General_Error.Stream_Too_Short
		}
		dst[n] = u8(sym)
		n += 1
	}
	d.written += i64(n)
	if i64(n) == left {
		return n, decode_end(d, m, rc, 0)
	}
	return n, nil
}

@(private)
decode_end :: proc(d: ^Decoder, m: ^$M, rc: ^$R, sym: int) -> (err: Error) {
	d.done = true
	r   := &d.input
	sym := sym
	if sym >= 0 && d.size < 0 {
		sym = decode_one(m, rc, r)
		if sym >= 0 {
			return General_Error.Output_Too_Short
		}
	}
	if sym >= 0 && rc.code != 0 {
		sym = decode_one(m, rc, r)
		if sym != SYM_END {
			if r.overrun {
				return General_Error.Stream_Too_Short
			}
			return General_Error.Size_Mismatch if sym >= 0 else PPMd_Error.Corrupt_Data
		}
	}
	if r.overrun {
		return General_Error.Stream_Too_Short
	}
	if sym == SYM_ERROR {
		return PPMd_Error.Corrupt_Data
	}
	if sym == SYM_END && d.size >= 0 && d.written != d.size {
		return General_Error.Size_Mismatch
	}
	if rc.code != 0 {
		return PPMd_Error.Corrupt_Data
	}
	return nil
}

@(private)
h_rc_norm_1 :: #force_inline proc(rc: ^Decoder_H, r: ^Input) {
	if rc.range_ < TOP_7Z {
		rc.code    = rc.code << 8 | u32(input_byte(r))
		rc.range_ <<= 8
	}
}

@(private)
h_rc_norm :: #force_inline proc(rc: ^Decoder_H, r: ^Input) {
	if rc.range_ < TOP_7Z {
		rc.code    = rc.code << 8 | u32(input_byte(r))
		rc.range_ <<= 8
		if rc.range_ < TOP_7Z {
			rc.code    = rc.code << 8 | u32(input_byte(r))
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
h_decode_symbol :: proc(p: ^Model_H, rc: ^Decoder_H, r: ^Input) -> int #no_bounds_check {
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
i_rc_norm :: #force_inline proc(rc: ^Coder_I, r: ^Input) {
	for {
		if (rc.low ~ (rc.low + rc.range_)) >= TOP_I {
			if rc.range_ >= BOT_I {
				break
			}
			rc.range_ = (0 - rc.low) & (BOT_I - 1)
		}
		rc.code    = rc.code << 8 | u32(input_byte(r))
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
i_decode_symbol :: proc(p: ^Model_I, rc: ^Coder_I, r: ^Input) -> int #no_bounds_check {
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
