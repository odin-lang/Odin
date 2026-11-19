package compress_lzma

import "base:intrinsics"
import "core:compress"

decompress        :: proc{decompress_from_bytes, decompress_from_context}
decompress_raw    :: proc{decompress_raw_from_bytes, decompress_raw_from_context}
decompress_lzma2  :: proc{decompress_lzma2_from_bytes, decompress_lzma2_from_context}

decompress_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return decompress_from_context(&ctx, expected_output_size, options, allocator)
}

decompress_from_context :: proc(z: ^compress.Context, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	if z.output == nil {
		return General_Error.Incompatible_Options
	}
	check_options(options) or_return
	max_output_size := compress.output_limit(options)
	if expected_output_size > max_output_size {
		return General_Error.Output_Too_Short
	}
	total_in := progress_total_in(z, options)
	header: [HEADER_SIZE]u8
	if compress.read_slice(z, header[:]) != nil {
		return General_Error.Stream_Too_Short
	}
	props := decode_properties(header[:PROPERTIES_SIZE]) or_return
	size  := u64(0)
	for i in 0..<8 {
		size |= u64(header[PROPERTIES_SIZE + i]) << (8 * uint(i))
	}

	declared := -1
	if size != UNKNOWN_SIZE {
		if expected_output_size >= 0 && u64(expected_output_size) != size {
			return General_Error.Size_Mismatch
		}
		if size > u64(max_output_size) {
			return General_Error.Output_Too_Short
		}
		declared = int(size)
	} else if expected_output_size >= 0 {
		declared = expected_output_size
	}
	return decompress_lzma(z, props, declared, options, total_in, HEADER_SIZE)
}

decompress_raw_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, props: Properties, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return decompress_raw_from_context(&ctx, props, expected_output_size, options, allocator)
}

decompress_raw_from_context :: proc(z: ^compress.Context, props: Properties, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	if z.output == nil {
		return General_Error.Incompatible_Options
	}
	check_options(options) or_return
	if !valid_properties(props) {
		return LZMA_Error.Invalid_Properties
	}
	expected := compress.declared_size(expected_output_size)
	if expected > compress.output_limit(options) {
		return General_Error.Output_Too_Short
	}
	return decompress_lzma(z, props, expected, options, progress_total_in(z, options), 0)
}

decompress_lzma2_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, dict_size: u32, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return decompress_lzma2_from_context(&ctx, dict_size, expected_output_size, options, allocator)
}

decompress_lzma2_from_context :: proc(z: ^compress.Context, dict_size: u32, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	if z.output == nil {
		return General_Error.Incompatible_Options
	}
	check_options(options) or_return
	expected := compress.declared_size(expected_output_size)
	if expected > compress.output_limit(options) {
		return General_Error.Output_Too_Short
	}
	if probs_memory(LZMA2_LCLP_MAX) > compress.memory_limit(options) {
		return General_Error.Memory_Limit_Exceeded
	}
	total_in := progress_total_in(z, options)

	d: Decoder
	decoder_init(&d, Properties{lc = LZMA2_LCLP_MAX, dict_size = dict_size}) or_return
	defer delete(d.probs)

	o := output_begin(z, expected, compress.output_limit(options))
	defer output_end(z, &o)
	p: Output_Progress
	o.progress = progress_begin(&p, options, total_in, 0, expected, 0)
	lzma2_run(&d, z, &o, expected) or_return
	return progress_finish(&d, &o)
}

lzma2_decoder_init :: proc(dec: ^LZMA2_Decoder, allocator := context.allocator) {
	dec^ = {allocator = allocator}
}

lzma2_decoder_destroy :: proc(dec: ^LZMA2_Decoder) {
	delete(dec.probs, dec.allocator)
	dec^ = {}
}

decompress_lzma2_append :: proc(dec: ^LZMA2_Decoder, output: ^[dynamic]u8, input: []u8, dict_size: u32, expected_output_size := -1, options: compress.Options = {}) -> (consumed: int, err: Error) {
	check_options(options) or_return
	max_output_size := compress.output_limit(options)
	start := len(output)
	if start > max_output_size {
		return 0, General_Error.Output_Too_Short
	}
	expected_size := compress.declared_size(expected_output_size)
	if expected_size > max_output_size - start {
		return 0, General_Error.Output_Too_Short
	}
	if dec.probs == nil {
		if probs_memory(LZMA2_LCLP_MAX) > compress.memory_limit(options) {
			return 0, General_Error.Memory_Limit_Exceeded
		}
		dec.probs = make([]u16, NUM_BASE_PROBS + int(LITERAL_CODER_SIZE) << uint(LZMA2_LCLP_MAX), dec.allocator) or_return
	}
	d := Decoder{
		probs     = dec.probs,
		props     = Properties{lc = LZMA2_LCLP_MAX},
		dict_size = max(dict_size, DICT_SIZE_MIN),
	}

	data := input
	ctx  := compress.init_context_from_slice(&data, output=output)
	o    := Output{buf = output, written = start, limit = max_output_size, end = max_output_size}
	bound := -1
	if len(input) < max(int) / compress.LZMA_EXPANSION_MAX {
		bound = len(input) * compress.LZMA_EXPANSION_MAX
	}
	reserve := min(compress.output_reservation(expected_size, bound, len(input)), max_output_size - start)
	if start + reserve > len(output) {
		if non_zero_resize(output, start + reserve) != nil {
			non_zero_resize(output, start)
		}
	}
	size := start + expected_size if expected_size >= 0 else -1
	p: Output_Progress
	o.progress = progress_begin(&p, options, i64(len(input)), 0, size, start)
	err = lzma2_run(&d, &ctx, &o, size)
	if err == nil {
		err = progress_finish(&d, &o)
	}
	non_zero_resize(output, o.written)
	return len(input) - len(ctx.window), err
}

@(private)
Decoder :: struct {
	probs:      []u16,
	props:      Properties,
	dict_size:  u32,
	range_:     u32,
	code:       u32,
	state:      u32,
	reps:       [4]u32,
	remain:     u32,
	processed:  u32,
	check_dict: u32,
	consumed:   i64,
}

@(private)
Rc :: struct {
	range_:  u32,
	code:    u32,
	src:     [^]u8,
	pos:     int,
	end:     int,
	overrun: bool,
}

@(private)
Output :: struct {
	buf:      ^[dynamic]u8,
	written:  int,
	limit:    int,
	base:     int,
	end:      int,
	progress: ^Output_Progress,
}

@(private)
LZMA2_Chunk :: enum u8 {
	None,
	Copy,
	LZMA,
}

@(private)
LZMA2_State :: struct {
	need_init: u8,
	chunk:     LZMA2_Chunk,
	chunk_end: int,
	packed:    int,
	done:      bool,
}

@(private)
decompress_lzma :: proc(z: ^compress.Context, props: Properties, size: int, options: compress.Options, total_in, base_in: i64) -> (err: Error) {
	if probs_memory(int(props.lc) + int(props.lp)) > compress.memory_limit(options) {
		return General_Error.Memory_Limit_Exceeded
	}
	d: Decoder
	o := output_begin(z, size, compress.output_limit(options))
	defer output_end(z, &o)
	p: Output_Progress
	o.progress = progress_begin(&p, options, total_in, base_in, size, 0)

	rc_init(&d, z) or_return
	decoder_init(&d, props, int(props.lc) + int(props.lp)) or_return
	defer delete(d.probs)
	decoder_reset_state(&d)

	target := size if size >= 0 else o.end
	packed := -1
	eos    := decode_segment(&d, z, &o, target, &packed) or_return
	lzma_finish(&d, z, &o, size, eos) or_return
	return progress_finish(&d, &o)
}

@(private)
probs_memory :: #force_inline proc "contextless" (lc_lp: int) -> (size: int) {
	return (NUM_BASE_PROBS + LITERAL_CODER_SIZE << uint(lc_lp)) * size_of(u16)
}

@(private)
progress_total_in :: proc(z: ^compress.Context, options: compress.Options) -> (total_in: i64) {
	if options.progress == nil {
		return -1
	}
	return i64(compress.input_size(z))
}

@(private)
progress_begin :: proc "contextless" (p: ^Output_Progress, options: compress.Options, total_in, base_in: i64, total_out, start: int) -> (progress: ^Output_Progress) {
	if options.progress == nil {
		return nil
	}
	interval := compress.progress_interval(options)
	p^ = {options = options, base_in = base_in, total_in = total_in, total_out = i64(total_out), interval = interval, mark = max(int)}
	if interval <= max(int) - start {
		p.mark = (start / interval + 1) * interval
	}
	return p
}

@(private)
progress_report :: proc(d: ^Decoder, o: ^Output) -> (err: Error) {
	p   := o.progress
	pos := o.base + o.written
	p.mark = pos + p.interval if p.interval <= max(int) - pos else max(int)
	return compress.report_progress(p.options, p.base_in + d.consumed, i64(pos), p.total_in, p.total_out)
}

@(private)
progress_finish :: proc(d: ^Decoder, o: ^Output) -> (err: Error) {
	if o.progress != nil && o.base + o.written >= o.progress.mark {
		return progress_report(d, o)
	}
	return nil
}

@(private)
lzma_finish :: proc(d: ^Decoder, z: ^compress.Context, o: ^Output, size: int, eos: bool) -> (err: Error) {
	if eos {
		if d.code != 0 {
			return LZMA_Error.Corrupt_Range_Coder
		}
		if size >= 0 && o.base + o.written != size {
			return General_Error.Size_Mismatch
		}
		return nil
	}
	overflow := Error(General_Error.Size_Mismatch) if size >= 0 else Error(General_Error.Output_Too_Short)
	if d.remain != 0 {
		return overflow
	}
	if (size >= 0 && d.code == 0) || decode_end_marker(d, z) {
		return nil
	}
	return overflow
}

@(private)
lzma2_run :: proc(d: ^Decoder, z: ^compress.Context, o: ^Output, size: int) -> (err: Error) {
	s := LZMA2_State{need_init = LZMA2_CONTROL_RESET_DICT}
	lzma2_fill(d, z, o, &s, size) or_return
	if !s.done {
		return General_Error.Size_Mismatch if size >= 0 else General_Error.Output_Too_Short
	}
	return nil
}

@(private)
lzma2_fill :: proc(d: ^Decoder, z: ^compress.Context, o: ^Output, s: ^LZMA2_State, size: int) -> (err: Error) {
	target   := size if size >= 0 else o.end
	overflow := Error(General_Error.Size_Mismatch) if size >= 0 else Error(General_Error.Output_Too_Short)
	for !s.done {
		switch s.chunk {
		case .Copy:
			for o.base + o.written < s.chunk_end {
				if o.written >= o.limit {
					return nil
				}
				if o.progress != nil && o.base + o.written >= o.progress.mark {
					progress_report(d, o) or_return
				}
				n := min(s.chunk_end - o.base - o.written, o.limit - o.written)
				if o.progress != nil {
					n = min(n, o.progress.mark - o.base - o.written)
				}
				output_ensure(o, o.written + n) or_return
				if compress.read_slice(z, o.buf^[o.written:][:n]) != nil {
					return General_Error.Stream_Too_Short
				}
				d.consumed += i64(n)
				if d.check_dict == 0 && d.dict_size - d.processed <= u32(n) {
					d.check_dict = d.dict_size
				}
				d.processed += u32(n)
				o.written   += n
			}
			s.chunk = .None
		case .LZMA:
			eos := decode_segment(d, z, o, s.chunk_end, &s.packed) or_return
			if !eos && o.base + o.written < s.chunk_end && o.written >= o.limit {
				return nil
			}
			if eos || o.base + o.written != s.chunk_end || d.remain != 0 || d.code != 0 || s.packed != 0 {
				return LZMA_Error.Invalid_Chunk
			}
			s.chunk = .None
		case .None:
			control, control_err := compress.read_u8(z)
			if control_err != nil {
				return General_Error.Stream_Too_Short
			}
			d.consumed += 1
			if control == 0 {
				if size >= 0 && o.base + o.written != size {
					return General_Error.Size_Mismatch
				}
				s.done = true
				break
			}
			current := o.base + o.written

			if control < LZMA2_CONTROL_LZMA {
				if control == LZMA2_CONTROL_COPY_RESET_DICT {
					s.need_init = LZMA2_CONTROL_SET_PROPS
				} else if control > LZMA2_CONTROL_COPY || s.need_init == LZMA2_CONTROL_RESET_DICT {
					return LZMA_Error.Invalid_Chunk
				}
				header: [2]u8
				if compress.read_slice(z, header[:]) != nil {
					return General_Error.Stream_Too_Short
				}
				d.consumed += 2
				n := (int(header[0]) << 8 | int(header[1])) + 1
				if control == LZMA2_CONTROL_COPY_RESET_DICT {
					d.processed  = 0
					d.check_dict = 0
				}
				if n > target - current {
					return overflow
				}
				s.chunk     = .Copy
				s.chunk_end = current + n
				continue
			}

			if control < s.need_init {
				return LZMA_Error.Invalid_Chunk
			}
			s.need_init = 0
			header: [4]u8
			if compress.read_slice(z, header[:]) != nil {
				return General_Error.Stream_Too_Short
			}
			d.consumed += 4
			unpacked := (int(control & 0x1F) << 16 | int(header[0]) << 8 | int(header[1])) + 1
			packed   := (int(header[2]) << 8 | int(header[3])) + 1
			if control >= LZMA2_CONTROL_SET_PROPS {
				b, b_err := compress.read_u8(z)
				if b_err != nil {
					return General_Error.Stream_Too_Short
				}
				d.consumed += 1
				if b >= 9 * 5 * 5 {
					return LZMA_Error.Invalid_Properties
				}
				lc := b % 9
				b  /= 9
				lp := b % 5
				if lc + lp > LZMA2_LCLP_MAX {
					return LZMA_Error.Invalid_Properties
				}
				d.props.lc = lc
				d.props.lp = lp
				d.props.pb = b / 5
			}
			if control >= LZMA2_CONTROL_RESET_DICT {
				d.processed  = 0
				d.check_dict = 0
			}
			if control >= LZMA2_CONTROL_RESET_STATE {
				decoder_reset_state(d)
			}
			if unpacked > target - current {
				return overflow
			}
			if packed < RC_INIT_SIZE {
				return LZMA_Error.Invalid_Chunk
			}
			rc_init(d, z) or_return
			s.packed    = packed - RC_INIT_SIZE
			s.chunk     = .LZMA
			s.chunk_end = current + unpacked
		}
	}
	return nil
}

@(private)
decoder_init :: proc(d: ^Decoder, props: Properties, lc_lp := LZMA2_LCLP_MAX) -> (err: Error) {
	d.props      = props
	d.dict_size  = max(props.dict_size, DICT_SIZE_MIN)
	d.probs      = make([]u16, NUM_BASE_PROBS + int(LITERAL_CODER_SIZE) << uint(lc_lp)) or_return
	d.processed  = 0
	d.check_dict = 0
	d.remain     = 0
	return nil
}

@(private)
decoder_reset_state :: proc(d: ^Decoder) {
	n := num_probs(d.props.lc, d.props.lp)
	for &p in d.probs[:n] {
		p = PROB_INIT
	}
	d.reps   = {1, 1, 1, 1}
	d.state  = 0
	d.remain = 0
}

@(private)
rc_init :: proc(d: ^Decoder, z: ^compress.Context) -> (err: Error) {
	buf: [RC_INIT_SIZE]u8
	if compress.read_slice(z, buf[:]) != nil {
		return General_Error.Stream_Too_Short
	}
	d.consumed += RC_INIT_SIZE
	if buf[0] != 0 {
		return LZMA_Error.Corrupt_Range_Coder
	}
	d.code   = u32(buf[1]) << 24 | u32(buf[2]) << 16 | u32(buf[3]) << 8 | u32(buf[4])
	d.range_ = 0xFFFF_FFFF
	if d.check_dict == 0 && d.processed == 0 && d.code >= BAD_REP_CODE {
		return LZMA_Error.Corrupt_Range_Coder
	}
	return nil
}

@(private)
output_begin :: proc(z: ^compress.Context, declared, max_output_size: int) -> (o: Output) {
	o.buf     = z.output
	o.written = 0
	o.limit   = declared if declared >= 0 else max_output_size
	o.end     = o.limit

	input_size := compress.input_size(z)
	bound      := -1
	if input_size >= 0 && input_size < max(int) / compress.LZMA_EXPANSION_MAX {
		bound = input_size * compress.LZMA_EXPANSION_MAX
	}
	reservation := min(compress.output_reservation(declared, bound, input_size), o.limit)
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
output_ensure :: #force_inline proc(o: ^Output, need: int) -> (err: Error) {
	if need <= len(o.buf^) {
		return nil
	}
	return non_zero_resize(o.buf, compress.output_grow_capacity(len(o.buf^), need, o.limit))
}

@(private)
write_remaining :: proc(d: ^Decoder, o: ^Output, limit: int) -> (err: Error) #no_bounds_check {
	if d.remain == 0 || o.written >= limit {
		return nil
	}
	n := min(int(d.remain), limit - o.written)
	output_ensure(o, o.written + n) or_return
	if d.check_dict == 0 && d.dict_size - d.processed <= u32(n) {
		d.check_dict = d.dict_size
	}
	d.processed += u32(n)
	d.remain    -= u32(n)
	out := raw_data(o.buf^)
	src := o.written - int(d.reps[0])
	for k in 0..<n {
		out[o.written + k] = out[src + k]
	}
	o.written += n
	return nil
}

@(private)
decode_segment :: proc(d: ^Decoder, z: ^compress.Context, o: ^Output, limit: int, packed: ^int) -> (eos: bool, err: Error) {
	memory := compress.is_memory_context(z)
	for {
		phys := limit - o.base
		stop := min(phys, o.limit)
		if o.progress != nil {
			stop = min(stop, o.progress.mark - o.base)
		}
		write_remaining(d, o, stop) or_return
		if o.written >= phys || o.written >= o.limit {
			return false, nil
		}
		if o.progress != nil && o.base + o.written >= o.progress.mark {
			progress_report(d, o) or_return
			continue
		}
		output_ensure(o, o.written + 1) or_return
		cur_limit := min(len(o.buf^), phys)
		if o.progress != nil {
			cur_limit = min(cur_limit, o.progress.mark - o.base)
		}
		if d.check_dict == 0 {
			rem := uint(d.dict_size - d.processed)
			if uint(cur_limit - o.written) > rem {
				cur_limit = o.written + int(rem)
			}
		}

		avail := z.window
		if packed^ >= 0 && len(avail) > packed^ {
			avail = avail[:packed^]
		}
		if len(avail) <= REQUIRED_INPUT_MAX && !memory && (packed^ < 0 || len(avail) < packed^) {
			need := REQUIRED_INPUT_MAX + 1
			if packed^ >= 0 {
				need = min(need, packed^)
			}
			compress.refill_window(z, need)
			avail = z.window
			if packed^ >= 0 && len(avail) > packed^ {
				avail = avail[:packed^]
			}
		}

		rc := Rc{range_ = d.range_, code = d.code, src = raw_data(avail), end = len(avail)}
		if len(avail) > REQUIRED_INPUT_MAX {
			eos, err = decode_real(d, &rc, o, cur_limit, len(avail) - REQUIRED_INPUT_MAX, false)
		} else {
			eos, err = decode_real(d, &rc, o, cur_limit, len(avail), true)
		}
		d.range_ = rc.range_
		d.code   = rc.code
		consumed := min(rc.pos, len(avail))
		z.window  = z.window[consumed:]
		d.consumed += i64(consumed)
		if packed^ >= 0 {
			packed^ -= consumed
		}
		if d.check_dict == 0 && d.processed >= d.dict_size {
			d.check_dict = d.dict_size
		}
		if rc.overrun {
			return false, General_Error.Stream_Too_Short
		}
		if err != nil || eos {
			return
		}
	}
}

@(private)
rc_normalize :: #force_inline proc "contextless" (rc: ^Rc, $CHECKED: bool) #no_bounds_check {
	if rc.range_ < TOP_VALUE {
		rc.range_ <<= 8
		when CHECKED {
			b := u32(0)
			if rc.pos < rc.end {
				b = u32(rc.src[rc.pos])
			} else {
				rc.overrun = true
			}
			rc.code = (rc.code << 8) | b
		} else {
			rc.code = (rc.code << 8) | u32(rc.src[rc.pos])
		}
		rc.pos += 1
	}
}

@(private)
rc_bit :: #force_inline proc "contextless" (rc: ^Rc, p: ^u16, $CHECKED: bool) -> (bit: u32) #no_bounds_check {
	rc_normalize(rc, CHECKED)
	ttt   := u32(p^)
	bound := (rc.range_ >> NUM_BIT_MODEL_TOTAL_BITS) * ttt
	if rc.code < bound {
		rc.range_ = bound
		p^ = u16(ttt + ((BIT_MODEL_TOTAL - ttt) >> NUM_MOVE_BITS))
		return 0
	}
	rc.range_ -= bound
	rc.code   -= bound
	p^ = u16(ttt - (ttt >> NUM_MOVE_BITS))
	return 1
}

@(private)
LZMA_PROB_ONE_TARGET :: (1 << NUM_MOVE_BITS) - 1

@(private)
rc_bit_select :: #force_inline proc "contextless" (rc: ^Rc, p: ^u16, $CHECKED: bool) -> (bit: u32) #no_bounds_check {
	rc_normalize(rc, CHECKED)
	ttt   := u32(p^)
	bound := (rc.range_ >> NUM_BIT_MODEL_TOTAL_BITS) * ttt
	one   := rc.code >= bound
	rc.range_ = rc.range_ - bound if one else bound
	rc.code   = rc.code - bound if one else rc.code
	target   := i32(LZMA_PROB_ONE_TARGET) if one else i32(BIT_MODEL_TOTAL)
	p^ = u16(i32(ttt) + ((target - i32(ttt)) >> NUM_MOVE_BITS))
	return u32(one)
}

@(private)
rc_literal :: #force_inline proc "contextless" (rc: ^Rc, prob: [^]u16, $CHECKED: bool) -> (symbol: u32) #no_bounds_check {
	symbol   = 1
	current := u32(prob[1])
	for _ in 0..<8 {
		next  := symbol << 1
		zero  := u32(prob[next])
		one_p := u32(prob[next + 1])
		rc_normalize(rc, CHECKED)
		bound := (rc.range_ >> NUM_BIT_MODEL_TOTAL_BITS) * current
		one   := rc.code >= bound
		rc.range_ = rc.range_ - bound if one else bound
		rc.code   = rc.code - bound if one else rc.code
		target   := i32(LZMA_PROB_ONE_TARGET) if one else i32(BIT_MODEL_TOTAL)
		prob[symbol] = u16(i32(current) + ((target - i32(current)) >> NUM_MOVE_BITS))
		symbol  = next + u32(one)
		current = one_p if one else zero
	}
	return symbol
}

@(private)
rc_tree :: #force_inline proc "contextless" (rc: ^Rc, probs: [^]u16, $BITS: u32, $CHECKED: bool) -> (symbol: u32) #no_bounds_check {
	symbol   = 1
	current := u32(probs[1])
	for _ in 0..<BITS - 1 {
		next  := symbol << 1
		zero  := u32(probs[next])
		one_p := u32(probs[next + 1])
		rc_normalize(rc, CHECKED)
		bound := (rc.range_ >> NUM_BIT_MODEL_TOTAL_BITS) * current
		one   := rc.code >= bound
		rc.range_ = rc.range_ - bound if one else bound
		rc.code   = rc.code - bound if one else rc.code
		target   := i32(LZMA_PROB_ONE_TARGET) if one else i32(BIT_MODEL_TOTAL)
		probs[symbol] = u16(i32(current) + ((target - i32(current)) >> NUM_MOVE_BITS))
		symbol  = next + u32(one)
		current = one_p if one else zero
	}
	rc_normalize(rc, CHECKED)
	bound := (rc.range_ >> NUM_BIT_MODEL_TOTAL_BITS) * current
	one   := rc.code >= bound
	rc.range_ = rc.range_ - bound if one else bound
	rc.code   = rc.code - bound if one else rc.code
	target   := i32(LZMA_PROB_ONE_TARGET) if one else i32(BIT_MODEL_TOTAL)
	probs[symbol] = u16(i32(current) + ((target - i32(current)) >> NUM_MOVE_BITS))
	return (symbol << 1) + u32(one) - (1 << BITS)
}

@(private)
decode_len :: #force_inline proc "contextless" (rc: ^Rc, probs: [^]u16, pos_state: u32, $CHECKED: bool) -> (length: u32) #no_bounds_check {
	if rc_bit(rc, &probs[LEN_CHOICE], CHECKED) == 0 {
		return rc_tree(rc, probs[LEN_LOW + pos_state:], LEN_NUM_LOW_BITS, CHECKED)
	}
	if rc_bit(rc, &probs[LEN_CHOICE2], CHECKED) == 0 {
		return rc_tree(rc, probs[LEN_LOW + pos_state + LEN_NUM_LOW_SYMBOLS:], LEN_NUM_LOW_BITS, CHECKED) + LEN_NUM_LOW_SYMBOLS
	}
	return rc_tree(rc, probs[LEN_HIGH:], LEN_NUM_HIGH_BITS, CHECKED) + LEN_NUM_LOW_SYMBOLS * 2
}

@(private)
decode_distance :: #force_inline proc "contextless" (rc: ^Rc, probs: [^]u16, length: u32, $CHECKED: bool) -> (distance: u32) #no_bounds_check {
	len_state := min(length, NUM_LEN_TO_POS_STATES - 1)
	distance   = rc_tree(rc, probs[POS_SLOT + (len_state << NUM_POS_SLOT_BITS):], NUM_POS_SLOT_BITS, CHECKED)
	if distance < START_POS_MODEL_INDEX {
		return
	}
	pos_slot   := distance
	num_direct := (distance >> 1) - 1
	distance    = 2 | (distance & 1)
	if pos_slot < END_POS_MODEL_INDEX {
		distance <<= num_direct
		spec := probs[SPEC_POS:]
		m    := u32(1)
		distance += 1
		for _ in 0..<num_direct {
			b := rc_bit_select(rc, &spec[distance], CHECKED)
			distance += m + (m & (0 - b))
			m        += m
		}
		return distance - m
	}
	for _ in 0..<num_direct - NUM_ALIGN_BITS {
		rc_normalize(rc, CHECKED)
		rc.range_ >>= 1
		rc.code    -= rc.range_
		t := 0 - (rc.code >> 31)
		distance    = (distance << 1) + (t + 1)
		rc.code    += rc.range_ & t
	}
	align := probs[ALIGN:]
	i     := u32(1)
	i += 1 + rc_bit_select(rc, &align[i], CHECKED)
	i += 2 + 2 * rc_bit_select(rc, &align[i], CHECKED)
	i += 4 + 4 * rc_bit_select(rc, &align[i], CHECKED)
	i -= 8 & (rc_bit_select(rc, &align[i], CHECKED) - 1)
	return (distance << NUM_ALIGN_BITS) | i
}

@(private)
decode_real :: proc(d: ^Decoder, rc_ptr: ^Rc, o: ^Output, limit, safe: int, $CHECKED: bool) -> (eos: bool, err: Error) #no_bounds_check {
	rc        := rc_ptr^
	probs     := raw_data(d.probs)
	out       := raw_data(o.buf^)
	capacity  := len(o.buf^)
	state     := d.state
	rep0      := d.reps[0]
	rep1      := d.reps[1]
	rep2      := d.reps[2]
	rep3      := d.reps[3]
	pb_mask   := (u32(1) << d.props.pb) - 1
	lc        := u32(d.props.lc)
	lp_mask   := (u32(0x100) << d.props.lp) - (u32(0x100) >> lc)
	processed := d.processed
	check     := d.check_dict
	pos       := o.written
	length    := u32(0)

	for pos < limit {
		when CHECKED {
			if rc.overrun {
				break
			}
		} else {
			if rc.pos >= safe {
				break
			}
		}

		pos_state := (processed & pb_mask) << 4
		if rc_bit(&rc, &probs[IS_MATCH + pos_state + state], CHECKED) == 0 {
			prob := probs[LITERAL:]
			if processed != 0 || check != 0 {
				prob = prob[3 * ((((processed << 8) + u32(out[pos - 1])) & lp_mask) << lc):]
			}
			processed += 1
			symbol := u32(1)
			if state < NUM_LIT_STATES {
				state -= state if state < 4 else 3
				symbol = rc_literal(&rc, prob, CHECKED)
			} else {
				m     := u32(out[pos - int(rep0)]) << 1
				offs  := u32(0x100)
				index := (offs & m) + offs + 1
				state -= 3 if state < 10 else 6
				for _ in 0..<8 {
					m2 := m << 1
					om := offs & m
					o0 := offs ~ om
					s0 := symbol << 1
					i0 := (o0 & m2) + o0 + s0
					i1 := (om & m2) + om + s0 + 1
					b  := rc_bit_select(&rc, &prob[index], CHECKED)
					symbol = s0 + b
					offs   = om if b != 0 else o0
					index  = i1 if b != 0 else i0
					m      = m2
				}
			}
			out[pos] = u8(symbol)
			pos += 1
			continue
		}

		len_probs: [^]u16
		if rc_bit(&rc, &probs[IS_REP + state], CHECKED) == 0 {
			state    += NUM_STATES
			len_probs = probs[LEN_CODER:]
		} else {
			if rc_bit(&rc, &probs[IS_REP_G0 + state], CHECKED) == 0 {
				if rc_bit(&rc, &probs[IS_REP0_LONG + pos_state + state], CHECKED) == 0 {
					out[pos]   = out[pos - int(rep0)]
					pos       += 1
					processed += 1
					state      = 9 if state < NUM_LIT_STATES else 11
					continue
				}
			} else {
				distance: u32
				if rc_bit(&rc, &probs[IS_REP_G1 + state], CHECKED) == 0 {
					distance = rep1
				} else {
					if rc_bit(&rc, &probs[IS_REP_G2 + state], CHECKED) == 0 {
						distance = rep2
					} else {
						distance = rep3
						rep3     = rep2
					}
					rep2 = rep1
				}
				rep1 = rep0
				rep0 = distance
			}
			state     = 8 if state < NUM_LIT_STATES else 11
			len_probs = probs[REP_LEN_CODER:]
		}

		length = decode_len(&rc, len_probs, pos_state, CHECKED)

		if state >= NUM_STATES {
			distance := decode_distance(&rc, probs, length, CHECKED)
			if distance == 0xFFFF_FFFF {
				length = 0
				state -= NUM_STATES
				eos    = true
				break
			}
			rep3  = rep2
			rep2  = rep1
			rep1  = rep0
			rep0  = distance + 1
			state = NUM_LIT_STATES if state < NUM_STATES + NUM_LIT_STATES else NUM_LIT_STATES + 3
			if distance >= (processed if check == 0 else check) {
				err = LZMA_Error.Invalid_Distance
				break
			}
		}

		length += MATCH_MIN_LEN
		cur    := min(int(length), limit - pos)
		src    := pos - int(rep0)
		processed += u32(cur)
		length    -= u32(cur)
		if rep0 >= 8 && pos + cur + 8 <= capacity {
			for k := 0; k < cur; k += 8 {
				intrinsics.unaligned_store((^u64)(&out[pos + k]), intrinsics.unaligned_load((^u64)(&out[src + k])))
			}
		} else {
			for k in 0..<cur {
				out[pos + k] = out[src + k]
			}
		}
		pos += cur
	}

	rc_normalize(&rc, CHECKED)
	rc_ptr^     = rc
	d.state     = state
	d.reps      = {rep0, rep1, rep2, rep3}
	d.processed = processed
	d.remain    = length
	o.written   = pos
	return
}

@(private)
decode_end_marker :: proc(d: ^Decoder, z: ^compress.Context) -> (ok: bool) {
	if !compress.is_memory_context(z) {
		compress.refill_window(z, REQUIRED_INPUT_MAX)
	}
	rc        := Rc{range_ = d.range_, code = d.code, src = raw_data(z.window), end = len(z.window)}
	probs     := raw_data(d.probs)
	pos_state := (d.processed & ((u32(1) << d.props.pb) - 1)) << 4
	state     := d.state
	if rc_bit(&rc, &probs[IS_MATCH + pos_state + state], true) == 0 {
		return false
	}
	if rc_bit(&rc, &probs[IS_REP + state], true) != 0 {
		return false
	}
	length   := decode_len(&rc, probs[LEN_CODER:], pos_state, true)
	distance := decode_distance(&rc, probs, length, true)
	rc_normalize(&rc, true)
	if rc.overrun || distance != 0xFFFF_FFFF || rc.code != 0 {
		return false
	}
	z.window = z.window[rc.pos:]
	d.consumed += i64(rc.pos)
	return true
}
