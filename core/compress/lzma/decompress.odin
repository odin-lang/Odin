package compress_lzma

import "base:intrinsics"
import "core:compress"

decompress        :: proc{decompress_from_bytes, decompress_from_context}
decompress_raw    :: proc{decompress_raw_from_bytes, decompress_raw_from_context}
decompress_lzma2  :: proc{decompress_lzma2_from_bytes, decompress_lzma2_from_context}

decompress_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, expected_output_size := -1, max_output_size := compress.COMPRESS_OUTPUT_ALLOCATE_MAX, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return decompress_from_context(&ctx, expected_output_size, max_output_size, allocator)
}

decompress_from_context :: proc(z: ^compress.Context, expected_output_size := -1, max_output_size := compress.COMPRESS_OUTPUT_ALLOCATE_MAX, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	if z.output == nil || max_output_size < 0 {
		return General_Error.Incompatible_Options
	}
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
		if size > u64(max_output_size) {
			return General_Error.Output_Too_Short
		}
		declared = int(size)
		if expected_output_size >= 0 && expected_output_size != declared {
			return LZMA_Error.Size_Mismatch
		}
	} else if expected_output_size >= 0 {
		declared = expected_output_size
	}
	return decompress_lzma(z, props, declared, size != UNKNOWN_SIZE, max_output_size)
}

decompress_raw_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, props: Properties, expected_output_size := -1, max_output_size := compress.COMPRESS_OUTPUT_ALLOCATE_MAX, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return decompress_raw_from_context(&ctx, props, expected_output_size, max_output_size, allocator)
}

decompress_raw_from_context :: proc(z: ^compress.Context, props: Properties, expected_output_size := -1, max_output_size := compress.COMPRESS_OUTPUT_ALLOCATE_MAX, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	if z.output == nil || max_output_size < 0 {
		return General_Error.Incompatible_Options
	}
	if !valid_properties(props) {
		return LZMA_Error.Invalid_Properties
	}
	expected := expected_output_size
	if expected < 0 && z.size_unpacked >= 0 && z.size_unpacked <= i64(max(int)) {
		expected = int(z.size_unpacked)
	}
	if expected > max_output_size {
		return General_Error.Output_Too_Short
	}
	return decompress_lzma(z, props, expected, false, max_output_size)
}

decompress_lzma2_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, dict_size: u32, expected_output_size := -1, max_output_size := compress.COMPRESS_OUTPUT_ALLOCATE_MAX, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return decompress_lzma2_from_context(&ctx, dict_size, expected_output_size, max_output_size, allocator)
}

decompress_lzma2_from_context :: proc(z: ^compress.Context, dict_size: u32, expected_output_size := -1, max_output_size := compress.COMPRESS_OUTPUT_ALLOCATE_MAX, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	if z.output == nil || max_output_size < 0 {
		return General_Error.Incompatible_Options
	}
	expected := expected_output_size
	if expected < 0 && z.size_unpacked >= 0 && z.size_unpacked <= i64(max(int)) {
		expected = int(z.size_unpacked)
	}
	if expected > max_output_size {
		return General_Error.Output_Too_Short
	}

	d: Decoder
	decoder_init(&d, Properties{lc = LZMA2_LCLP_MAX, dict_size = dict_size}) or_return
	defer delete(d.probs)

	o := output_begin(z, expected, max_output_size)
	defer output_end(z, &o)
	return decode_lzma2_body(&d, z, &o, expected)
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
	buf:     ^[dynamic]u8,
	written: int,
	limit:   int,
}

@(private)
decompress_lzma :: proc(z: ^compress.Context, props: Properties, size: int, from_format: bool, max_output_size: int) -> (err: Error) {
	d: Decoder
	decoder_init(&d, props, int(props.lc) + int(props.lp)) or_return
	defer delete(d.probs)

	o := output_begin(z, size, max_output_size)
	defer output_end(z, &o)

	decoder_reset_state(&d)
	rc_init(&d, z) or_return

	target := size if size >= 0 else o.limit
	packed := -1
	eos    := decode_segment(&d, z, &o, target, &packed) or_return
	if eos {
		if d.code != 0 {
			return LZMA_Error.Corrupt_Range_Coder
		}
		if size >= 0 && o.written != size {
			return LZMA_Error.Unexpected_End_Marker
		}
		return nil
	}
	overflow: Error = General_Error.Output_Too_Short
	if from_format {
		overflow = LZMA_Error.Size_Mismatch
	}
	if d.remain != 0 {
		return overflow
	}
	if (size >= 0 && d.code == 0) || decode_end_marker(&d, z) {
		return nil
	}
	return overflow
}

@(private)
decode_lzma2_body :: proc(d: ^Decoder, z: ^compress.Context, o: ^Output, size: int) -> (err: Error) {
	target    := size if size >= 0 else o.limit
	overflow  := Error(General_Error.Output_Too_Short)
	need_init := u8(LZMA2_CONTROL_RESET_DICT)
	for {
		control, control_err := compress.read_u8(z)
		if control_err != nil {
			return General_Error.Stream_Too_Short
		}
		if control == 0 {
			break
		}

		if control < LZMA2_CONTROL_LZMA {
			if control == LZMA2_CONTROL_COPY_RESET_DICT {
				need_init = LZMA2_CONTROL_SET_PROPS
			} else if control > LZMA2_CONTROL_COPY || need_init == LZMA2_CONTROL_RESET_DICT {
				return LZMA_Error.Invalid_Chunk
			}
			header: [2]u8
			if compress.read_slice(z, header[:]) != nil {
				return General_Error.Stream_Too_Short
			}
			n := (int(header[0]) << 8 | int(header[1])) + 1
			if control == LZMA2_CONTROL_COPY_RESET_DICT {
				d.processed  = 0
				d.check_dict = 0
			}
			if n > target - o.written {
				return overflow
			}
			output_ensure(o, o.written + n) or_return
			if compress.read_slice(z, o.buf^[o.written:][:n]) != nil {
				return General_Error.Stream_Too_Short
			}
			if d.check_dict == 0 && d.dict_size - d.processed <= u32(n) {
				d.check_dict = d.dict_size
			}
			d.processed += u32(n)
			o.written   += n
			continue
		}

		if control < need_init {
			return LZMA_Error.Invalid_Chunk
		}
		need_init = 0
		header: [4]u8
		if compress.read_slice(z, header[:]) != nil {
			return General_Error.Stream_Too_Short
		}
		unpacked := (int(control & 0x1F) << 16 | int(header[0]) << 8 | int(header[1])) + 1
		packed   := (int(header[2]) << 8 | int(header[3])) + 1
		if control >= LZMA2_CONTROL_SET_PROPS {
			b, b_err := compress.read_u8(z)
			if b_err != nil {
				return General_Error.Stream_Too_Short
			}
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
		if unpacked > target - o.written {
			return overflow
		}
		if packed < RC_INIT_SIZE {
			return LZMA_Error.Invalid_Chunk
		}
		rc_init(d, z) or_return
		packed -= RC_INIT_SIZE

		chunk_end := o.written + unpacked
		eos := decode_segment(d, z, o, chunk_end, &packed) or_return
		if eos || o.written != chunk_end || d.remain != 0 || d.code != 0 || packed != 0 {
			return LZMA_Error.Invalid_Chunk
		}
	}
	if size >= 0 && o.written != size {
		return LZMA_Error.Size_Mismatch
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
	non_zero_resize(o.buf, compress.output_grow_capacity(len(o.buf^), need, o.limit)) or_return
	return nil
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
		write_remaining(d, o, limit) or_return
		if o.written >= limit {
			return false, nil
		}
		output_ensure(o, o.written + 1) or_return
		cur_limit := min(len(o.buf^), limit)
		if d.check_dict == 0 {
			rem := int(d.dict_size - d.processed)
			if cur_limit - o.written > rem {
				cur_limit = o.written + rem
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
rc_tree :: #force_inline proc "contextless" (rc: ^Rc, probs: [^]u16, $BITS: u32, $CHECKED: bool) -> (symbol: u32) #no_bounds_check {
	symbol = 1
	for _ in 0..<BITS {
		symbol = (symbol << 1) | rc_bit(rc, &probs[symbol], CHECKED)
	}
	return symbol - (1 << BITS)
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
			if rc_bit(rc, &spec[distance], CHECKED) == 0 {
				distance += m
				m        += m
			} else {
				m        += m
				distance += m
			}
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
	i += 1 if rc_bit(rc, &align[i], CHECKED) == 0 else 2
	i += 2 if rc_bit(rc, &align[i], CHECKED) == 0 else 4
	i += 4 if rc_bit(rc, &align[i], CHECKED) == 0 else 8
	if rc_bit(rc, &align[i], CHECKED) == 0 {
		i -= 8
	}
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
				for _ in 0..<8 {
					symbol = (symbol << 1) | rc_bit(&rc, &prob[symbol], CHECKED)
				}
			} else {
				match_byte := u32(out[pos - int(rep0)])
				offs       := u32(0x100)
				state      -= 3 if state < 10 else 6
				for _ in 0..<8 {
					match_byte <<= 1
					bit  := offs
					offs &= match_byte
					b    := rc_bit(&rc, &prob[offs + bit + symbol], CHECKED)
					symbol = (symbol << 1) | b
					if b == 0 {
						offs ~= bit
					}
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
	return true
}
