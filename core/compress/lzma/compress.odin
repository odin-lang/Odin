package compress_lzma

import "base:intrinsics"
import "base:runtime"
import "core:compress"

compress       :: proc{compress_to_slice, compress_to_dynamic}
compress_raw   :: proc{compress_raw_to_slice, compress_raw_to_dynamic}
compress_lzma2 :: proc{compress_lzma2_to_slice, compress_lzma2_to_dynamic}

compress_bound :: proc(length: int) -> int {
	if length < 0 || length > (max(int) - HEADER_SIZE - COMPRESS_BOUND_SLACK) / 2 {
		return -1
	}
	return HEADER_SIZE + length * 2 + COMPRESS_BOUND_SLACK
}

compress_lzma2_bound :: proc(length: int) -> int {
	if length < 0 || length > max(int) - length / 4096 - COMPRESS_BOUND_SLACK {
		return -1
	}
	return length + length / 4096 + COMPRESS_BOUND_SLACK
}

level_options :: proc(level := Level.Default) -> (options: Options) {
	l := clamp(int(level), int(Level.Level_0), int(Level.Level_9))
	options.lc           = DEFAULT_PROPERTIES.lc
	options.lp           = DEFAULT_PROPERTIES.lp
	options.pb           = DEFAULT_PROPERTIES.pb
	options.dict_size    = u32(1) << LEVEL_DICT_POW2[l]
	options.fast         = l <= 3
	options.nice_len     = LEVEL_NICE_LEN[l]
	options.depth        = LEVEL_DEPTH[l]
	options.match_finder = .HC4 if l <= 3 else .BT4
	return
}

compress_to_slice :: proc(output, input: []u8, level := Level.Default, allocator := context.allocator) -> (written: int, err: Error) {
	if len(output) < HEADER_SIZE {
		return 0, General_Error.Output_Too_Short
	}
	n, props := compress_raw_to_slice(output[HEADER_SIZE:], input, level_options(level), allocator) or_return
	write_header(output, props, len(input))
	return n + HEADER_SIZE, nil
}

compress_to_dynamic :: proc(output: ^[dynamic]u8, input: []u8, level := Level.Default, allocator := context.allocator) -> (err: Error) {
	if output == nil {
		return General_Error.Incompatible_Options
	}
	props := encode_to_dynamic(output, input, level_options(level), HEADER_SIZE, false, allocator) or_return
	write_header(output[:], props, len(input))
	return nil
}

compress_raw_to_slice :: proc(output, input: []u8, options: Options, allocator := context.allocator) -> (written: int, props: Properties, err: Error) {
	opts := normalize_options(options, len(input), false) or_return
	rc   := Range_Encoder{buf = raw_data(output), cap = len(output), limit = len(output)}
	written = encode_lzma(&rc, input, opts, allocator) or_return
	return written, options_properties(opts), nil
}

compress_raw_to_dynamic :: proc(output: ^[dynamic]u8, input: []u8, options: Options, allocator := context.allocator) -> (props: Properties, err: Error) {
	if output == nil {
		return {}, General_Error.Incompatible_Options
	}
	return encode_to_dynamic(output, input, options, 0, false, allocator)
}

compress_lzma2_to_slice :: proc(output, input: []u8, options: Options, allocator := context.allocator) -> (written: int, props: Properties, err: Error) {
	opts := normalize_options(options, len(input), true) or_return
	rc   := Range_Encoder{buf = raw_data(output), cap = len(output), limit = len(output)}
	written = encode_lzma2(&rc, input, opts, allocator) or_return
	return written, options_properties(opts), nil
}

compress_lzma2_to_dynamic :: proc(output: ^[dynamic]u8, input: []u8, options: Options, allocator := context.allocator) -> (props: Properties, err: Error) {
	if output == nil {
		return {}, General_Error.Incompatible_Options
	}
	return encode_to_dynamic(output, input, options, 0, true, allocator)
}

@(private)
write_header :: proc "contextless" (output: []u8, props: Properties, size: int) {
	header := encode_properties(props)
	copy(output, header[:])
	for i in 0..<8 {
		output[PROPERTIES_SIZE + i] = u8(u64(size) >> (8 * uint(i)))
	}
}

@(private)
options_properties :: proc "contextless" (options: Options) -> (props: Properties) {
	props.lc = options.lc
	props.lp = options.lp
	props.pb = options.pb
	props.dict_size, _ = lzma2_dict_size(lzma2_dict_prop(options.dict_size))
	return
}

@(private)
encode_to_dynamic :: proc(output: ^[dynamic]u8, input: []u8, options: Options, prefix: int, lzma2: bool, allocator: runtime.Allocator) -> (props: Properties, err: Error) {
	context.allocator = allocator
	opts  := normalize_options(options, len(input), lzma2) or_return
	bound := compress_lzma2_bound(len(input)) if lzma2 else compress_bound(len(input))
	if bound < 0 {
		return {}, LZMA_Error.Input_Too_Large
	}
	limit := compress.COMPRESS_OUTPUT_ALLOCATE_MAX
	if prefix > limit {
		return {}, General_Error.Output_Too_Short
	}
	reservation := min(compress.output_reservation(compress_lzma2_bound(len(input)), bound, len(input)) + prefix, limit)
	non_zero_resize(output, reservation) or_return

	rc := Range_Encoder{start = prefix, pos = prefix, buf = raw_data(output^), cap = len(output^), grow = output, limit = limit}
	written: int
	if lzma2 {
		written, err = encode_lzma2(&rc, input, opts, allocator)
	} else {
		written, err = encode_lzma(&rc, input, opts, allocator)
	}
	if err != nil {
		non_zero_resize(output, 0)
		return
	}
	non_zero_resize(output, prefix + written)
	return options_properties(opts), nil
}

@(private)
normalize_options :: proc "contextless" (options: Options, input_size: int, lzma2: bool) -> (opts: Options, err: Error) {
	opts = options
	if opts.lc > LC_MAX || opts.lp > LP_MAX || opts.pb > PB_MAX || opts.match_finder > .BT5 {
		return {}, LZMA_Error.Invalid_Properties
	}
	if lzma2 && opts.lc + opts.lp > LZMA2_LCLP_MAX {
		return {}, LZMA_Error.Invalid_Properties
	}
	if input_size >= 0 && u64(opts.dict_size) > u64(input_size) {
		opts.dict_size = min(opts.dict_size, max(u32(input_size), DICT_SIZE_MIN))
	}
	opts.dict_size = clamp(opts.dict_size, DICT_SIZE_MIN, MAX_HISTORY_SIZE)
	opts.nice_len  = clamp(opts.nice_len, NICE_LEN_MIN, MATCH_MAX_LEN)
	if opts.depth == 0 {
		opts.depth = (16 + (opts.nice_len >> 1)) >> (0 if opts.match_finder >= .BT2 else 1)
	}
	if lzma2 {
		opts.end_marker = false
	}
	return
}

@(private)
encoder_create :: proc(e: ^Encoder, opts: Options, input: []u8, lzma2: bool) -> (err: Error) {
	e.dict_size      = opts.dict_size
	e.num_fast_bytes = opts.nice_len
	e.lc             = u32(opts.lc)
	e.lp             = u32(opts.lp)
	e.pb             = u32(opts.pb)
	e.fast_mode      = opts.fast
	e.write_end_mark = opts.end_marker
	e.input          = input

	i := u32(END_POS_MODEL_INDEX / 2)
	for ; i < DIC_LOG_SIZE_MAX; i += 1 {
		if e.dict_size <= u32(1) << i {
			break
		}
	}
	e.dist_table_size = i * 2
	e.finished        = false
	e.now_pos64       = 0
	e.need_init       = true

	lit_count := LITERAL_CODER_SIZE << (e.lc + e.lp)
	e.lit_probs = make([]u16, lit_count) or_return
	if lzma2 {
		e.saved_lit_probs = make([]u16, lit_count) or_return
	}

	dict := e.dict_size
	if dict == 2 << 30 || dict == 3 << 30 {
		dict -= 1
	}
	mf_create(&e.mf, opts.match_finder, dict, e.num_fast_bytes, MATCH_MAX_LEN + 1, opts.depth, u64(len(input))) or_return

	init_price_tables(e)
	encoder_init(e)
	encoder_init_prices(e)
	return nil
}

@(private)
encoder_destroy :: proc(e: ^Encoder) {
	mf_destroy(&e.mf)
	delete(e.lit_probs)
	delete(e.saved_lit_probs)
}

@(private)
init_price_tables :: proc "contextless" (e: ^Encoder) {
	for i in u32(0)..<BIT_MODEL_TOTAL >> NUM_MOVE_REDUCING_BITS {
		w := (i << NUM_MOVE_REDUCING_BITS) + (1 << (NUM_MOVE_REDUCING_BITS - 1))
		bit_count := u32(0)
		for _ in 0..<NUM_BIT_PRICE_SHIFT_BITS {
			w = w * w
			bit_count <<= 1
			for w >= 1 << 16 {
				w >>= 1
				bit_count += 1
			}
		}
		e.prob_prices[i] = (NUM_BIT_MODEL_TOTAL_BITS << NUM_BIT_PRICE_SHIFT_BITS) - 15 - bit_count
	}
}

@(private)
encoder_init :: proc(e: ^Encoder) #no_bounds_check {
	e.state = 0
	e.reps  = {1, 1, 1, 1}
	re_reset(&e.rc)
	for &p in e.pos_align_encoder {
		p = PROB_INIT
	}
	for s in 0..<NUM_STATES {
		for j in 0..<NUM_POS_STATES_MAX {
			e.is_match[s][j]     = PROB_INIT
			e.is_rep0_long[s][j] = PROB_INIT
		}
		e.is_rep[s]    = PROB_INIT
		e.is_rep_g0[s] = PROB_INIT
		e.is_rep_g1[s] = PROB_INIT
		e.is_rep_g2[s] = PROB_INIT
	}
	for s in 0..<NUM_LEN_TO_POS_STATES {
		for &p in e.pos_slot_encoder[s] {
			p = PROB_INIT
		}
	}
	for &p in e.pos_encoders {
		p = PROB_INIT
	}
	for &p in e.lit_probs {
		p = PROB_INIT
	}
	len_enc_init(&e.len_probs)
	len_enc_init(&e.rep_len_probs)
	e.opt_end = 0
	e.opt_cur = 0
	for &o in e.opt {
		o.price = INFINITY_PRICE
	}
	e.additional_offset = 0
	e.pb_mask = (u32(1) << e.pb) - 1
	e.lp_mask = (u32(0x100) << e.lp) - (u32(0x100) >> e.lc)
}

@(private)
encoder_init_prices :: proc(e: ^Encoder) {
	if !e.fast_mode {
		fill_distances_prices(e)
		fill_align_prices(e)
	}
	e.len_enc.table_size     = e.num_fast_bytes + 1 - MATCH_MIN_LEN
	e.rep_len_enc.table_size = e.len_enc.table_size
	e.rep_len_enc_counter    = REP_LEN_COUNT
	len_price_update_tables(e, &e.len_enc, u32(1) << e.pb, &e.len_probs)
	len_price_update_tables(e, &e.rep_len_enc, u32(1) << e.pb, &e.rep_len_probs)
}

@(private)
len_enc_init :: proc "contextless" (p: ^Len_Enc) {
	for &x in p.low {
		x = PROB_INIT
	}
	for &x in p.high {
		x = PROB_INIT
	}
}

@(private)
re_reset :: proc "contextless" (rc: ^Range_Encoder) {
	rc.range_     = 0xFFFF_FFFF
	rc.cache      = 0
	rc.low        = 0
	rc.cache_size = 0
	rc.start      = rc.pos
}

@(private)
re_processed :: #force_inline proc "contextless" (rc: ^Range_Encoder) -> int {
	return rc.pos - rc.start + int(rc.cache_size)
}

@(private)
re_reserve :: proc(rc: ^Range_Encoder, need: int) -> bool {
	if need <= rc.cap {
		return true
	}
	if rc.grow == nil || rc.grow_err != nil || need > rc.limit {
		return false
	}
	capacity := compress.output_grow_capacity(rc.cap, need, rc.limit)
	if err := non_zero_resize(rc.grow, capacity); err != nil {
		rc.grow_err = err
		return false
	}
	rc.buf = raw_data(rc.grow^)
	rc.cap = len(rc.grow^)
	return true
}

@(private)
re_write_byte :: #force_inline proc(rc: ^Range_Encoder, b: u8) #no_bounds_check {
	if rc.pos < rc.cap || re_reserve(rc, rc.pos + 1) {
		rc.buf[rc.pos] = b
	}
	rc.pos += 1
}

@(private)
re_shift_low :: proc(rc: ^Range_Encoder) {
	low  := u32(rc.low)
	high := u32(rc.low >> 32)
	rc.low = u64(low << 8)
	if low < 0xFF00_0000 || high != 0 {
		re_write_byte(rc, u8(rc.cache + high))
		rc.cache = low >> 24
		if rc.cache_size == 0 {
			return
		}
		high += 0xFF
		for {
			re_write_byte(rc, u8(high))
			rc.cache_size -= 1
			if rc.cache_size == 0 {
				return
			}
		}
	}
	rc.cache_size += 1
}

@(private)
re_flush_data :: proc(rc: ^Range_Encoder) {
	for _ in 0..<5 {
		re_shift_low(rc)
	}
}

@(private)
re_norm :: #force_inline proc(rc: ^Range_Encoder) {
	if rc.range_ < TOP_VALUE {
		rc.range_ <<= 8
		re_shift_low(rc)
	}
}

@(private)
re_bit :: #force_inline proc(rc: ^Range_Encoder, prob: ^u16, bit: u32) {
	ttt   := u32(prob^)
	bound := (rc.range_ >> NUM_BIT_MODEL_TOTAL_BITS) * ttt
	if bit == 0 {
		rc.range_ = bound
		ttt += (BIT_MODEL_TOTAL - ttt) >> NUM_MOVE_BITS
	} else {
		rc.low    += u64(bound)
		rc.range_ -= bound
		ttt -= ttt >> NUM_MOVE_BITS
	}
	prob^ = u16(ttt)
	re_norm(rc)
}

@(private)
lit_encode :: proc(rc: ^Range_Encoder, probs: [^]u16, sym: u32) #no_bounds_check {
	sym := sym
	sym |= 0x100
	for {
		prob := &probs[sym >> 8]
		bit  := (sym >> 7) & 1
		sym <<= 1
		re_bit(rc, prob, bit)
		if sym >= 0x10000 {
			break
		}
	}
}

@(private)
lit_encode_matched :: proc(rc: ^Range_Encoder, probs: [^]u16, sym, match_byte: u32) #no_bounds_check {
	sym        := sym
	sym |= 0x100
	match_byte := match_byte
	offs       := u32(0x100)
	for {
		match_byte <<= 1
		prob := &probs[offs + (match_byte & offs) + (sym >> 8)]
		bit  := (sym >> 7) & 1
		sym <<= 1
		offs &= ~(match_byte ~ sym)
		re_bit(rc, prob, bit)
		if sym >= 0x10000 {
			break
		}
	}
}

@(private)
re_tree_reverse :: proc(rc: ^Range_Encoder, probs: [^]u16, num_bits, sym: u32) #no_bounds_check {
	sym := sym
	m   := u32(1)
	for _ in 0..<num_bits {
		bit := sym & 1
		sym >>= 1
		re_bit(rc, &probs[m], bit)
		m = (m << 1) | bit
	}
}

@(private)
len_encode :: proc(p: ^Len_Enc, rc: ^Range_Encoder, sym, pos_state: u32) #no_bounds_check {
	sym   := sym
	probs := raw_data(p.low[:])
	if sym >= LEN_NUM_LOW_SYMBOLS {
		re_bit(rc, &probs[0], 1)
		probs = probs[LEN_NUM_LOW_SYMBOLS:]
		if sym >= LEN_NUM_LOW_SYMBOLS * 2 {
			re_bit(rc, &probs[0], 1)
			lit_encode(rc, raw_data(p.high[:]), sym - LEN_NUM_LOW_SYMBOLS * 2)
			return
		}
		sym -= LEN_NUM_LOW_SYMBOLS
	}
	re_bit(rc, &probs[0], 0)
	probs = probs[pos_state << (1 + LEN_NUM_LOW_BITS):]
	bit := sym >> 2
	re_bit(rc, &probs[1], bit)
	m := (u32(1) << 1) + bit
	bit = (sym >> 1) & 1
	re_bit(rc, &probs[m], bit)
	m = (m << 1) + bit
	bit = sym & 1
	re_bit(rc, &probs[m], bit)
}

@(private)
price_bit :: #force_inline proc "contextless" (e: ^Encoder, prob: u16, bit: u32) -> u32 #no_bounds_check {
	return e.prob_prices[(u32(prob) ~ ((0 - bit) & (BIT_MODEL_TOTAL - 1))) >> NUM_MOVE_REDUCING_BITS]
}

@(private)
price_0 :: #force_inline proc "contextless" (e: ^Encoder, prob: u16) -> u32 #no_bounds_check {
	return e.prob_prices[u32(prob) >> NUM_MOVE_REDUCING_BITS]
}

@(private)
price_1 :: #force_inline proc "contextless" (e: ^Encoder, prob: u16) -> u32 #no_bounds_check {
	return e.prob_prices[(u32(prob) ~ (BIT_MODEL_TOTAL - 1)) >> NUM_MOVE_REDUCING_BITS]
}

@(private)
lit_price :: #force_inline proc "contextless" (e: ^Encoder, probs: [^]u16, sym: u32) -> (price: u32) #no_bounds_check {
	sym := sym
	sym |= 0x100
	for {
		bit := sym & 1
		sym >>= 1
		price += price_bit(e, probs[sym], bit)
		if sym < 2 {
			break
		}
	}
	return
}

@(private)
lit_matched_price :: #force_inline proc "contextless" (e: ^Encoder, probs: [^]u16, sym, match_byte: u32) -> (price: u32) #no_bounds_check {
	sym        := sym
	sym |= 0x100
	match_byte := match_byte
	offs       := u32(0x100)
	for {
		match_byte <<= 1
		price += price_bit(e, probs[offs + (match_byte & offs) + (sym >> 8)], (sym >> 7) & 1)
		sym <<= 1
		offs &= ~(match_byte ~ sym)
		if sym >= 0x10000 {
			break
		}
	}
	return
}

@(private)
set_prices_3 :: #force_inline proc "contextless" (e: ^Encoder, probs: [^]u16, start_price: u32, prices: [^]u32) #no_bounds_check {
	for i := u32(0); i < 8; i += 2 {
		price := start_price
		price += price_bit(e, probs[1], i >> 2)
		price += price_bit(e, probs[2 + (i >> 2)], (i >> 1) & 1)
		prob := probs[4 + (i >> 1)]
		prices[i]     = price + price_0(e, prob)
		prices[i + 1] = price + price_1(e, prob)
	}
}

@(private)
len_price_update_tables :: proc "contextless" (e: ^Encoder, p: ^Len_Price_Enc, num_pos_states: u32, enc: ^Len_Enc) #no_bounds_check {
	b: u32
	{
		prob := enc.low[0]
		b     = price_1(e, prob)
		a    := price_0(e, prob)
		c    := b + price_0(e, enc.low[LEN_NUM_LOW_SYMBOLS])
		for pos_state in 0..<num_pos_states {
			prices := raw_data(p.prices[pos_state][:])
			probs  := raw_data(enc.low[pos_state << (1 + LEN_NUM_LOW_BITS):])
			set_prices_3(e, probs, a, prices)
			set_prices_3(e, probs[LEN_NUM_LOW_SYMBOLS:], c, prices[LEN_NUM_LOW_SYMBOLS:])
		}
	}
	i := p.table_size
	if i > LEN_NUM_LOW_SYMBOLS * 2 {
		probs  := raw_data(enc.high[:])
		prices := raw_data(p.prices[0][LEN_NUM_LOW_SYMBOLS * 2:])
		i -= LEN_NUM_LOW_SYMBOLS * 2 - 1
		i >>= 1
		b += price_1(e, enc.low[LEN_NUM_LOW_SYMBOLS])
		for {
			i -= 1
			sym   := i + (1 << (LEN_NUM_HIGH_BITS - 1))
			price := b
			for {
				bit := sym & 1
				sym >>= 1
				price += price_bit(e, probs[sym], bit)
				if sym < 2 {
					break
				}
			}
			prob := probs[i + (1 << (LEN_NUM_HIGH_BITS - 1))]
			prices[i * 2]     = price + price_0(e, prob)
			prices[i * 2 + 1] = price + price_1(e, prob)
			if i == 0 {
				break
			}
		}
		num := int(p.table_size) - LEN_NUM_LOW_SYMBOLS * 2
		for pos_state in 1..<num_pos_states {
			intrinsics.mem_copy_non_overlapping(&p.prices[pos_state][LEN_NUM_LOW_SYMBOLS * 2], &p.prices[0][LEN_NUM_LOW_SYMBOLS * 2], num * size_of(u32))
		}
	}
}

@(private)
pos_slot_bsr :: #force_inline proc "contextless" (pos: u32) -> u32 {
	zz := 30 - u32(intrinsics.count_leading_zeros(pos))
	return (zz + zz) + (pos >> zz)
}

@(private)
pos_slot :: #force_inline proc "contextless" (pos: u32) -> u32 {
	if pos < 2 {
		return pos
	}
	return pos_slot_bsr(pos)
}

@(private)
fill_align_prices :: proc "contextless" (e: ^Encoder) #no_bounds_check {
	probs := &e.pos_align_encoder
	for i in u32(0)..<ALIGN_TABLE_SIZE / 2 {
		price := u32(0)
		sym   := i
		m     := u32(1)
		bit   := sym & 1
		sym >>= 1
		price += price_bit(e, probs[m], bit)
		m = (m << 1) + bit
		bit = sym & 1
		sym >>= 1
		price += price_bit(e, probs[m], bit)
		m = (m << 1) + bit
		bit = sym & 1
		price += price_bit(e, probs[m], bit)
		m = (m << 1) + bit
		prob := probs[m]
		e.align_prices[i]     = price + price_0(e, prob)
		e.align_prices[i + 8] = price + price_1(e, prob)
	}
}

@(private)
fill_distances_prices :: proc "contextless" (e: ^Encoder) #no_bounds_check {
	temp_prices: [NUM_FULL_DISTANCES]u32
	e.match_price_count = 0
	for i in u32(START_POS_MODEL_INDEX / 2)..<NUM_FULL_DISTANCES / 2 {
		slot        := pos_slot_bsr(i)
		footer_bits := (slot >> 1) - 1
		base        := (2 | (slot & 1)) << footer_bits
		probs       := raw_data(e.pos_encoders[base * 2:])
		price       := u32(0)
		m           := u32(1)
		sym         := i
		offset      := u32(1) << footer_bits
		base += i
		for _ in 0..<footer_bits {
			bit := sym & 1
			sym >>= 1
			price += price_bit(e, probs[m], bit)
			m = (m << 1) + bit
		}
		prob := probs[m]
		temp_prices[base]          = price + price_0(e, prob)
		temp_prices[base + offset] = price + price_1(e, prob)
	}

	for lps in 0..<NUM_LEN_TO_POS_STATES {
		dist_table_size2 := (e.dist_table_size + 1) >> 1
		pos_slot_prices  := &e.pos_slot_prices[lps]
		probs            := &e.pos_slot_encoder[lps]
		for slot in u32(0)..<dist_table_size2 {
			sym := slot + (1 << (NUM_POS_SLOT_BITS - 1))
			bit := sym & 1
			sym >>= 1
			price := price_bit(e, probs[sym], bit)
			for _ in 0..<4 {
				bit = sym & 1
				sym >>= 1
				price += price_bit(e, probs[sym], bit)
			}
			prob := probs[slot + (1 << (NUM_POS_SLOT_BITS - 1))]
			pos_slot_prices[slot * 2]     = price + price_0(e, prob)
			pos_slot_prices[slot * 2 + 1] = price + price_1(e, prob)
		}
		delta := u32((END_POS_MODEL_INDEX / 2 - 1) - NUM_ALIGN_BITS) << NUM_BIT_PRICE_SHIFT_BITS
		for slot in u32(END_POS_MODEL_INDEX / 2)..<dist_table_size2 {
			pos_slot_prices[slot * 2]     += delta
			pos_slot_prices[slot * 2 + 1] += delta
			delta += u32(1) << NUM_BIT_PRICE_SHIFT_BITS
		}
		dp := &e.distances_prices[lps]
		dp[0] = pos_slot_prices[0]
		dp[1] = pos_slot_prices[1]
		dp[2] = pos_slot_prices[2]
		dp[3] = pos_slot_prices[3]
		for i := u32(4); i < NUM_FULL_DISTANCES; i += 2 {
			slot_price := pos_slot_prices[pos_slot_bsr(i)]
			dp[i]     = slot_price + temp_prices[i]
			dp[i + 1] = slot_price + temp_prices[i + 1]
		}
	}
}

@(private)
move_pos :: #force_inline proc(e: ^Encoder, num: u32) {
	e.additional_offset += num
	mf_skip(&e.mf, num)
}

@(private)
read_match_distances :: proc(e: ^Encoder) -> (length, num_pairs: u32) #no_bounds_check {
	e.additional_offset += 1
	e.num_avail = mf_avail(&e.mf)
	num_pairs = mf_get_matches(&e.mf, &e.matches[0])
	if num_pairs == 0 {
		return 0, 0
	}
	length = e.matches[num_pairs - 2]
	if length != e.num_fast_bytes {
		return
	}
	num_avail := min(e.num_avail, MATCH_MAX_LEN)
	p1  := e.mf.buffer[-1:]
	p2  := length
	dif := -1 - int(e.matches[num_pairs - 1])
	for p2 != num_avail && p1[p2] == p1[int(p2) + dif] {
		p2 += 1
	}
	return p2, num_pairs
}

@(private)
lit_probs_at :: #force_inline proc "contextless" (e: ^Encoder, pos: u32, prev_byte: u8) -> [^]u16 #no_bounds_check {
	return raw_data(e.lit_probs[3 * ((((pos << 8) + u32(prev_byte)) & e.lp_mask) << e.lc):])
}

@(private)
price_short_rep :: #force_inline proc "contextless" (e: ^Encoder, state, pos_state: u32) -> u32 #no_bounds_check {
	return price_0(e, e.is_rep_g0[state]) + price_0(e, e.is_rep0_long[state][pos_state])
}

@(private)
price_rep_0 :: #force_inline proc "contextless" (e: ^Encoder, state, pos_state: u32) -> u32 #no_bounds_check {
	return price_1(e, e.is_match[state][pos_state]) + price_1(e, e.is_rep0_long[state][pos_state]) + price_1(e, e.is_rep[state]) + price_0(e, e.is_rep_g0[state])
}

@(private)
price_pure_rep :: #force_inline proc "contextless" (e: ^Encoder, rep_index, state, pos_state: u32) -> (price: u32) #no_bounds_check {
	prob := e.is_rep_g0[state]
	if rep_index == 0 {
		price  = price_0(e, prob)
		price += price_1(e, e.is_rep0_long[state][pos_state])
	} else {
		price = price_1(e, prob)
		prob  = e.is_rep_g1[state]
		if rep_index == 1 {
			price += price_0(e, prob)
		} else {
			price += price_1(e, prob)
			price += price_bit(e, e.is_rep_g2[state], rep_index - 2)
		}
	}
	return
}

@(private)
price_len :: #force_inline proc "contextless" (p: ^Len_Price_Enc, pos_state, length: u32) -> u32 #no_bounds_check {
	return p.prices[pos_state][length - MATCH_MIN_LEN]
}

@(private)
backward :: proc "contextless" (e: ^Encoder, cur: u32) -> u32 #no_bounds_check {
	cur := cur
	wr  := cur + 1
	e.opt_end = wr
	for {
		dist  := e.opt[cur].dist
		l     := e.opt[cur].len
		extra := u32(e.opt[cur].extra)
		cur -= l
		if extra != 0 {
			wr -= 1
			e.opt[wr].len = l
			cur -= extra
			l = extra
			if extra == 1 {
				e.opt[wr].dist = dist
				dist = MARK_LIT
			} else {
				e.opt[wr].dist = 0
				l -= 1
				wr -= 1
				e.opt[wr].dist = MARK_LIT
				e.opt[wr].len  = 1
			}
		}
		if cur == 0 {
			e.back_res = dist
			e.opt_cur  = wr
			return l
		}
		wr -= 1
		e.opt[wr].dist = dist
		e.opt[wr].len  = l
	}
}

@(private)
get_optimum :: proc(e: ^Encoder, position: u32) -> u32 #no_bounds_check {
	position := position
	last, cur: u32
	reps:     [NUM_REPS]u32
	rep_lens: [NUM_REPS]u32
	matches := &e.matches

	{
		num_pairs, main_len: u32
		e.opt_cur = 0
		e.opt_end = 0
		if e.additional_offset == 0 {
			main_len, num_pairs = read_match_distances(e)
		} else {
			main_len  = e.longest_match_len
			num_pairs = e.num_pairs
		}
		num_avail := e.num_avail
		if num_avail < 2 {
			e.back_res = MARK_LIT
			return 1
		}
		num_avail = min(num_avail, MATCH_MAX_LEN)

		data := e.mf.buffer[-1:]
		rep_max_index := u32(0)
		for i in u32(0)..<NUM_REPS {
			reps[i] = e.reps[i]
			data2 := data[-int(reps[i]):]
			if data[0] != data2[0] || data[1] != data2[1] {
				rep_lens[i] = 0
				continue
			}
			l := u32(2)
			for l < num_avail && data[l] == data2[l] {
				l += 1
			}
			rep_lens[i] = l
			if l > rep_lens[rep_max_index] {
				rep_max_index = i
			}
			if l == MATCH_MAX_LEN {
				break
			}
		}

		if rep_lens[rep_max_index] >= e.num_fast_bytes {
			e.back_res = rep_max_index
			l := rep_lens[rep_max_index]
			move_pos(e, l - 1)
			return l
		}

		if main_len >= e.num_fast_bytes {
			e.back_res = matches[num_pairs - 1] + NUM_REPS
			move_pos(e, main_len - 1)
			return main_len
		}

		cur_byte   := data[0]
		match_byte := data[-int(reps[0])]

		last = rep_lens[rep_max_index]
		if last <= main_len {
			last = main_len
		}

		if last < 2 && cur_byte != match_byte {
			e.back_res = MARK_LIT
			return 1
		}

		e.opt[0].state = u16(e.state)
		pos_state := position & e.pb_mask

		{
			probs := lit_probs_at(e, position, data[-1])
			lp: u32
			if e.state >= NUM_LIT_STATES {
				lp = lit_matched_price(e, probs, u32(cur_byte), u32(match_byte))
			} else {
				lp = lit_price(e, probs, u32(cur_byte))
			}
			e.opt[1].price = price_0(e, e.is_match[e.state][pos_state]) + lp
		}
		e.opt[1].dist  = MARK_LIT
		e.opt[1].extra = 0

		match_price     := price_1(e, e.is_match[e.state][pos_state])
		rep_match_price := match_price + price_1(e, e.is_rep[e.state])

		if match_byte == cur_byte && rep_lens[0] == 0 {
			short_rep_price := rep_match_price + price_short_rep(e, e.state, pos_state)
			if short_rep_price < e.opt[1].price {
				e.opt[1].price = short_rep_price
				e.opt[1].dist  = 0
				e.opt[1].extra = 0
			}
			if last < 2 {
				e.back_res = e.opt[1].dist
				return 1
			}
		}

		e.opt[1].len     = 1
		e.opt[0].reps[0] = reps[0]
		e.opt[0].reps[1] = reps[1]
		e.opt[0].reps[2] = reps[2]
		e.opt[0].reps[3] = reps[3]

		for i in u32(0)..<NUM_REPS {
			rep_len := rep_lens[i]
			if rep_len < 2 {
				continue
			}
			price := rep_match_price + price_pure_rep(e, i, e.state, pos_state)
			for {
				price2 := price + price_len(&e.rep_len_enc, pos_state, rep_len)
				opt    := &e.opt[rep_len]
				if price2 < opt.price {
					opt.price = price2
					opt.len   = rep_len
					opt.dist  = i
					opt.extra = 0
				}
				rep_len -= 1
				if rep_len < 2 {
					break
				}
			}
		}

		{
			l := rep_lens[0] + 1
			if l <= main_len {
				offs := u32(0)
				normal_match_price := match_price + price_0(e, e.is_rep[e.state])
				if l < 2 {
					l = 2
				} else {
					for l > matches[offs] {
						offs += 2
					}
				}
				for ; ; l += 1 {
					dist  := matches[offs + 1]
					price := normal_match_price + price_len(&e.len_enc, pos_state, l)
					len_to_pos_state := l - 2 if l < NUM_LEN_TO_POS_STATES + 1 else NUM_LEN_TO_POS_STATES - 1
					if dist < NUM_FULL_DISTANCES {
						price += e.distances_prices[len_to_pos_state][dist & (NUM_FULL_DISTANCES - 1)]
					} else {
						slot := pos_slot_bsr(dist)
						price += e.align_prices[dist & ALIGN_MASK]
						price += e.pos_slot_prices[len_to_pos_state][slot]
					}
					opt := &e.opt[l]
					if price < opt.price {
						opt.price = price
						opt.len   = l
						opt.dist  = dist + NUM_REPS
						opt.extra = 0
					}
					if l == matches[offs] {
						offs += 2
						if offs == num_pairs {
							break
						}
					}
				}
			}
		}
		cur = 0
	}

	for {
		cur += 1
		if cur == last {
			break
		}

		if cur >= NUM_OPTS - 64 {
			price := e.opt[cur].price
			best  := cur
			for j := cur + 1; j <= last; j += 1 {
				price2 := e.opt[j].price
				if price >= price2 {
					price = price2
					best  = j
				}
			}
			delta := best - cur
			if delta != 0 {
				move_pos(e, delta)
			}
			cur = best
			break
		}

		new_len, num_pairs := read_match_distances(e)
		if new_len >= e.num_fast_bytes {
			e.num_pairs         = num_pairs
			e.longest_match_len = new_len
			break
		}

		cur_opt := &e.opt[cur]
		position += 1

		prev := cur - cur_opt.len
		state: u32
		if cur_opt.len == 1 {
			state = u32(e.opt[prev].state)
			if cur_opt.dist == 0 {
				state = u32(SHORT_REP_NEXT_STATES[state])
			} else {
				state = u32(LITERAL_NEXT_STATES[state])
			}
		} else {
			dist := cur_opt.dist
			if cur_opt.extra != 0 {
				prev -= u32(cur_opt.extra)
				state = STATE_REP_AFTER_LIT
				if cur_opt.extra == 1 {
					state = STATE_REP_AFTER_LIT if dist < NUM_REPS else STATE_MATCH_AFTER_LIT
				}
			} else {
				state = u32(e.opt[prev].state)
				if dist < NUM_REPS {
					state = u32(REP_NEXT_STATES[state])
				} else {
					state = u32(MATCH_NEXT_STATES[state])
				}
			}
			prev_opt := &e.opt[prev]
			b0 := prev_opt.reps[0]
			if dist < NUM_REPS {
				if dist == 0 {
					reps[0] = b0
					reps[1] = prev_opt.reps[1]
					reps[2] = prev_opt.reps[2]
					reps[3] = prev_opt.reps[3]
				} else {
					reps[1] = b0
					b0 = prev_opt.reps[1]
					if dist == 1 {
						reps[0] = b0
						reps[2] = prev_opt.reps[2]
						reps[3] = prev_opt.reps[3]
					} else {
						reps[2] = b0
						reps[0] = prev_opt.reps[dist]
						reps[3] = prev_opt.reps[dist ~ 1]
					}
				}
			} else {
				reps[0] = dist - NUM_REPS + 1
				reps[1] = b0
				reps[2] = prev_opt.reps[1]
				reps[3] = prev_opt.reps[2]
			}
		}
		cur_opt.state   = u16(state)
		cur_opt.reps[0] = reps[0]
		cur_opt.reps[1] = reps[1]
		cur_opt.reps[2] = reps[2]
		cur_opt.reps[3] = reps[3]

		data       := e.mf.buffer[-1:]
		cur_byte   := data[0]
		match_byte := data[-int(reps[0])]
		pos_state  := position & e.pb_mask

		lit_price_: u32
		match_price: u32
		{
			cur_price := cur_opt.price
			prob      := e.is_match[state][pos_state]
			match_price = cur_price + price_1(e, prob)
			lit_price_  = cur_price + price_0(e, prob)
		}

		next_opt    := &e.opt[cur + 1]
		next_is_lit := false

		if (next_opt.price < INFINITY_PRICE && match_byte == cur_byte) || lit_price_ > next_opt.price {
			lit_price_ = 0
		} else {
			probs := lit_probs_at(e, position, data[-1])
			if state >= NUM_LIT_STATES {
				lit_price_ += lit_matched_price(e, probs, u32(cur_byte), u32(match_byte))
			} else {
				lit_price_ += lit_price(e, probs, u32(cur_byte))
			}
			if lit_price_ < next_opt.price {
				next_opt.price = lit_price_
				next_opt.len   = 1
				next_opt.dist  = MARK_LIT
				next_opt.extra = 0
				next_is_lit    = true
			}
		}

		rep_match_price := match_price + price_1(e, e.is_rep[state])

		num_avail_full := e.num_avail
		{
			temp := NUM_OPTS - 1 - cur
			if num_avail_full > temp {
				num_avail_full = temp
			}
		}

		if state < NUM_LIT_STATES && match_byte == cur_byte && rep_match_price < next_opt.price {
			if next_opt.len < 2 || next_opt.dist != 0 {
				short_rep_price := rep_match_price + price_short_rep(e, state, pos_state)
				if short_rep_price < next_opt.price {
					next_opt.price = short_rep_price
					next_opt.len   = 1
					next_opt.dist  = 0
					next_opt.extra = 0
					next_is_lit    = false
				}
			}
		}

		if num_avail_full < 2 {
			continue
		}
		num_avail := num_avail_full if num_avail_full <= e.num_fast_bytes else e.num_fast_bytes

		if !next_is_lit && lit_price_ != 0 && match_byte != cur_byte && num_avail_full > 2 {
			data2 := data[-int(reps[0]):]
			if data[1] == data2[1] && data[2] == data2[2] {
				limit := e.num_fast_bytes + 1
				if limit > num_avail_full {
					limit = num_avail_full
				}
				l := u32(3)
				for l < limit && data[l] == data2[l] {
					l += 1
				}
				state2     := u32(LITERAL_NEXT_STATES[state])
				pos_state2 := (position + 1) & e.pb_mask
				price      := lit_price_ + price_rep_0(e, state2, pos_state2)
				offset     := cur + l
				if last < offset {
					last = offset
				}
				l -= 1
				price2 := price + price_len(&e.rep_len_enc, pos_state2, l)
				opt    := &e.opt[offset]
				if price2 < opt.price {
					opt.price = price2
					opt.len   = l
					opt.dist  = 0
					opt.extra = 1
				}
			}
		}

		start_len := u32(2)
		for rep_index in u32(0)..<NUM_REPS {
			data2 := data[-int(reps[rep_index]):]
			if data[0] != data2[0] || data[1] != data2[1] {
				continue
			}
			l := u32(2)
			for l < num_avail && data[l] == data2[l] {
				l += 1
			}
			{
				offset := cur + l
				if last < offset {
					last = offset
				}
			}
			price: u32
			{
				len2 := l
				price = rep_match_price + price_pure_rep(e, rep_index, state, pos_state)
				for {
					price2 := price + price_len(&e.rep_len_enc, pos_state, len2)
					opt    := &e.opt[cur + len2]
					if price2 < opt.price {
						opt.price = price2
						opt.len   = len2
						opt.dist  = rep_index
						opt.extra = 0
					}
					len2 -= 1
					if len2 < 2 {
						break
					}
				}
			}

			if rep_index == 0 {
				start_len = l + 1
			}

			{
				len2  := l + 1
				limit := len2 + e.num_fast_bytes
				if limit > num_avail_full {
					limit = num_avail_full
				}
				len2 += 2
				if len2 <= limit && data[len2 - 2] == data2[len2 - 2] && data[len2 - 1] == data2[len2 - 1] {
					state2     := u32(REP_NEXT_STATES[state])
					pos_state2 := (position + l) & e.pb_mask
					price += price_len(&e.rep_len_enc, pos_state, l) + price_0(e, e.is_match[state2][pos_state2]) + lit_matched_price(e, lit_probs_at(e, position + l, data[l - 1]), u32(data[l]), u32(data2[l]))
					state2     = STATE_LIT_AFTER_REP
					pos_state2 = (pos_state2 + 1) & e.pb_mask
					price += price_rep_0(e, state2, pos_state2)
					for len2 < limit && data[len2] == data2[len2] {
						len2 += 1
					}
					len2 -= l
					offset := cur + l + len2
					if last < offset {
						last = offset
					}
					len2 -= 1
					price2 := price + price_len(&e.rep_len_enc, pos_state2, len2)
					opt    := &e.opt[offset]
					if price2 < opt.price {
						opt.price = price2
						opt.len   = len2
						opt.extra = u16(l + 1)
						opt.dist  = rep_index
					}
				}
			}
		}

		if new_len > num_avail {
			new_len = num_avail
			num_pairs = 0
			for new_len > matches[num_pairs] {
				num_pairs += 2
			}
			matches[num_pairs] = new_len
			num_pairs += 2
		}

		if new_len >= start_len {
			normal_match_price := match_price + price_0(e, e.is_rep[state])
			{
				offset := cur + new_len
				if last < offset {
					last = offset
				}
			}
			offs := u32(0)
			for start_len > matches[offs] {
				offs += 2
			}
			dist := matches[offs + 1]
			slot := pos_slot_bsr(dist)
			for l := start_len; ; l += 1 {
				price := normal_match_price + price_len(&e.len_enc, pos_state, l)
				{
					len_norm := l - 2
					len_norm = len_norm if len_norm < NUM_LEN_TO_POS_STATES - 1 else NUM_LEN_TO_POS_STATES - 1
					if dist < NUM_FULL_DISTANCES {
						price += e.distances_prices[len_norm][dist & (NUM_FULL_DISTANCES - 1)]
					} else {
						price += e.pos_slot_prices[len_norm][slot] + e.align_prices[dist & ALIGN_MASK]
					}
					opt := &e.opt[cur + l]
					if price < opt.price {
						opt.price = price
						opt.len   = l
						opt.dist  = dist + NUM_REPS
						opt.extra = 0
					}
				}

				if l == matches[offs] {
					data2 := data[-int(dist) - 1:]
					len2  := l + 1
					limit := len2 + e.num_fast_bytes
					if limit > num_avail_full {
						limit = num_avail_full
					}
					len2 += 2
					if len2 <= limit && data[len2 - 2] == data2[len2 - 2] && data[len2 - 1] == data2[len2 - 1] {
						for len2 < limit && data[len2] == data2[len2] {
							len2 += 1
						}
						len2 -= l
						state2     := u32(MATCH_NEXT_STATES[state])
						pos_state2 := (position + l) & e.pb_mask
						price += price_0(e, e.is_match[state2][pos_state2])
						price += lit_matched_price(e, lit_probs_at(e, position + l, data[l - 1]), u32(data[l]), u32(data2[l]))
						state2     = STATE_LIT_AFTER_MATCH
						pos_state2 = (pos_state2 + 1) & e.pb_mask
						price += price_rep_0(e, state2, pos_state2)
						offset := cur + l + len2
						if last < offset {
							last = offset
						}
						len2 -= 1
						price2 := price + price_len(&e.rep_len_enc, pos_state2, len2)
						opt    := &e.opt[offset]
						if price2 < opt.price {
							opt.price = price2
							opt.len   = len2
							opt.extra = u16(l + 1)
							opt.dist  = dist + NUM_REPS
						}
					}
					offs += 2
					if offs == num_pairs {
						break
					}
					dist = matches[offs + 1]
					slot = pos_slot_bsr(dist)
				}
			}
		}
	}

	for {
		e.opt[last].price = INFINITY_PRICE
		last -= 1
		if last == 0 {
			break
		}
	}
	return backward(e, cur)
}

@(private)
change_pair :: #force_inline proc "contextless" (small_dist, big_dist: u32) -> bool {
	return (big_dist >> 7) > small_dist
}

@(private)
get_optimum_fast :: proc(e: ^Encoder) -> u32 #no_bounds_check {
	main_len, num_pairs: u32
	if e.additional_offset == 0 {
		main_len, num_pairs = read_match_distances(e)
	} else {
		main_len  = e.longest_match_len
		num_pairs = e.num_pairs
	}
	num_avail := e.num_avail
	e.back_res = MARK_LIT
	if num_avail < 2 {
		return 1
	}
	num_avail = min(num_avail, MATCH_MAX_LEN)
	data := e.mf.buffer[-1:]
	rep_len, rep_index: u32
	for i in u32(0)..<NUM_REPS {
		data2 := data[-int(e.reps[i]):]
		if data[0] != data2[0] || data[1] != data2[1] {
			continue
		}
		l := u32(2)
		for l < num_avail && data[l] == data2[l] {
			l += 1
		}
		if l >= e.num_fast_bytes {
			e.back_res = i
			move_pos(e, l - 1)
			return l
		}
		if l > rep_len {
			rep_index = i
			rep_len   = l
		}
	}

	if main_len >= e.num_fast_bytes {
		e.back_res = e.matches[num_pairs - 1] + NUM_REPS
		move_pos(e, main_len - 1)
		return main_len
	}

	main_dist := u32(0)
	if main_len >= 2 {
		main_dist = e.matches[num_pairs - 1]
		for num_pairs > 2 {
			if main_len != e.matches[num_pairs - 4] + 1 {
				break
			}
			dist2 := e.matches[num_pairs - 3]
			if !change_pair(dist2, main_dist) {
				break
			}
			num_pairs -= 2
			main_len  -= 1
			main_dist  = dist2
		}
		if main_len == 2 && main_dist >= 0x80 {
			main_len = 1
		}
	}

	if rep_len >= 2 {
		if rep_len + 1 >= main_len || (rep_len + 2 >= main_len && main_dist >= 1 << 9) || (rep_len + 3 >= main_len && main_dist >= 1 << 15) {
			e.back_res = rep_index
			move_pos(e, rep_len - 1)
			return rep_len
		}
	}

	if main_len < 2 || num_avail <= 2 {
		return 1
	}

	{
		len1, pairs1 := read_match_distances(e)
		e.num_pairs         = pairs1
		e.longest_match_len = len1
		if len1 >= 2 {
			new_dist := e.matches[pairs1 - 1]
			if (len1 >= main_len && new_dist < main_dist) || (len1 == main_len + 1 && !change_pair(main_dist, new_dist)) || len1 > main_len + 1 || (len1 + 1 >= main_len && main_len >= 3 && change_pair(new_dist, main_dist)) {
				return 1
			}
		}
	}

	data = e.mf.buffer[-1:]
	for i in u32(0)..<NUM_REPS {
		data2 := data[-int(e.reps[i]):]
		if data[0] != data2[0] || data[1] != data2[1] {
			continue
		}
		limit := main_len - 1
		for l := u32(2); ; l += 1 {
			if l >= limit {
				return 1
			}
			if data[l] != data2[l] {
				break
			}
		}
	}

	e.back_res = main_dist + NUM_REPS
	if main_len != 2 {
		move_pos(e, main_len - 2)
	}
	return main_len
}

@(private)
write_end_marker :: proc(e: ^Encoder, pos_state: u32) #no_bounds_check {
	rc := &e.rc
	re_bit(rc, &e.is_match[e.state][pos_state], 1)
	re_bit(rc, &e.is_rep[e.state], 0)
	e.state = u32(MATCH_NEXT_STATES[e.state])
	len_encode(&e.len_probs, rc, 0, pos_state)
	{
		probs := &e.pos_slot_encoder[0]
		m := u32(1)
		for m < 1 << NUM_POS_SLOT_BITS {
			re_bit(rc, &probs[m], 1)
			m = (m << 1) + 1
		}
	}
	for _ in 0..<30 - NUM_ALIGN_BITS {
		rc.range_ >>= 1
		rc.low += u64(rc.range_)
		re_norm(rc)
	}
	{
		m := u32(1)
		for m < ALIGN_TABLE_SIZE {
			re_bit(rc, &e.pos_align_encoder[m], 1)
			m = (m << 1) + 1
		}
	}
}

@(private)
flush :: proc(e: ^Encoder, now_pos: u32) {
	e.finished = true
	if e.write_end_mark {
		write_end_marker(e, now_pos & e.pb_mask)
	}
	re_flush_data(&e.rc)
}

@(private)
code_one_block :: proc(e: ^Encoder, max_pack_size, max_unpack_size: u32) #no_bounds_check {
	if e.need_init {
		mf_init(&e.mf, e.input)
		e.need_init = false
	}
	if e.finished {
		return
	}
	now_pos32   := u32(e.now_pos64)
	start_pos32 := now_pos32
	rc          := &e.rc

	if e.now_pos64 == 0 {
		if mf_avail(&e.mf) == 0 {
			flush(e, now_pos32)
			return
		}
		read_match_distances(e)
		re_bit(rc, &e.is_match[0][0], 0)
		cur_byte := e.mf.buffer[-int(e.additional_offset)]
		lit_encode(rc, raw_data(e.lit_probs), u32(cur_byte))
		e.additional_offset -= 1
		now_pos32 += 1
	}

	if mf_avail(&e.mf) != 0 {
		for {
			l: u32
			if e.fast_mode {
				l = get_optimum_fast(e)
			} else {
				oci := e.opt_cur
				if e.opt_end == oci {
					l = get_optimum(e, now_pos32)
				} else {
					opt := &e.opt[oci]
					l          = opt.len
					e.back_res = opt.dist
					e.opt_cur  = oci + 1
				}
			}

			pos_state := now_pos32 & e.pb_mask
			dist      := e.back_res

			if dist == MARK_LIT {
				re_bit(rc, &e.is_match[e.state][pos_state], 0)
				data  := e.mf.buffer[-int(e.additional_offset):]
				probs := lit_probs_at(e, now_pos32, data[-1])
				cur_byte := data[0]
				state    := e.state
				e.state = u32(LITERAL_NEXT_STATES[state])
				if state < NUM_LIT_STATES {
					lit_encode(rc, probs, u32(cur_byte))
				} else {
					lit_encode_matched(rc, probs, u32(cur_byte), u32(data[-int(e.reps[0])]))
				}
			} else {
				re_bit(rc, &e.is_match[e.state][pos_state], 1)
				if dist < NUM_REPS {
					re_bit(rc, &e.is_rep[e.state], 1)
					if dist == 0 {
						re_bit(rc, &e.is_rep_g0[e.state], 0)
						if l != 1 {
							re_bit(rc, &e.is_rep0_long[e.state][pos_state], 1)
						} else {
							re_bit(rc, &e.is_rep0_long[e.state][pos_state], 0)
							e.state = u32(SHORT_REP_NEXT_STATES[e.state])
						}
					} else {
						re_bit(rc, &e.is_rep_g0[e.state], 1)
						if dist == 1 {
							re_bit(rc, &e.is_rep_g1[e.state], 0)
							dist = e.reps[1]
						} else {
							re_bit(rc, &e.is_rep_g1[e.state], 1)
							if dist == 2 {
								re_bit(rc, &e.is_rep_g2[e.state], 0)
								dist = e.reps[2]
							} else {
								re_bit(rc, &e.is_rep_g2[e.state], 1)
								dist = e.reps[3]
								e.reps[3] = e.reps[2]
							}
							e.reps[2] = e.reps[1]
						}
						e.reps[1] = e.reps[0]
						e.reps[0] = dist
					}
					if l != 1 {
						len_encode(&e.rep_len_probs, rc, l - MATCH_MIN_LEN, pos_state)
						e.rep_len_enc_counter -= 1
						e.state = u32(REP_NEXT_STATES[e.state])
					}
				} else {
					re_bit(rc, &e.is_rep[e.state], 0)
					e.state = u32(MATCH_NEXT_STATES[e.state])
					len_encode(&e.len_probs, rc, l - MATCH_MIN_LEN, pos_state)
					dist -= NUM_REPS
					e.reps[3] = e.reps[2]
					e.reps[2] = e.reps[1]
					e.reps[1] = e.reps[0]
					e.reps[0] = dist + 1
					e.match_price_count += 1
					slot := pos_slot(dist)
					{
						sym   := slot + (1 << NUM_POS_SLOT_BITS)
						probs := &e.pos_slot_encoder[l - 2 if l < NUM_LEN_TO_POS_STATES + 1 else NUM_LEN_TO_POS_STATES - 1]
						for {
							prob := &probs[sym >> NUM_POS_SLOT_BITS]
							bit  := (sym >> (NUM_POS_SLOT_BITS - 1)) & 1
							sym <<= 1
							re_bit(rc, prob, bit)
							if sym >= 1 << (NUM_POS_SLOT_BITS * 2) {
								break
							}
						}
					}
					if dist >= START_POS_MODEL_INDEX {
						footer_bits := (slot >> 1) - 1
						if dist < NUM_FULL_DISTANCES {
							base := (2 | (slot & 1)) << footer_bits
							re_tree_reverse(rc, raw_data(e.pos_encoders[base:]), footer_bits, dist)
						} else {
							pos2 := (dist | 0xF) << (32 - footer_bits)
							for {
								rc.range_ >>= 1
								rc.low += u64(rc.range_ & (0 - (pos2 >> 31)))
								pos2 += pos2
								re_norm(rc)
								if pos2 == 0xF000_0000 {
									break
								}
							}
							m   := u32(1)
							bit := dist & 1
							dist >>= 1
							re_bit(rc, &e.pos_align_encoder[m], bit)
							m = (m << 1) + bit
							bit = dist & 1
							dist >>= 1
							re_bit(rc, &e.pos_align_encoder[m], bit)
							m = (m << 1) + bit
							bit = dist & 1
							dist >>= 1
							re_bit(rc, &e.pos_align_encoder[m], bit)
							m = (m << 1) + bit
							bit = dist & 1
							re_bit(rc, &e.pos_align_encoder[m], bit)
						}
					}
				}
			}

			now_pos32 += l
			e.additional_offset -= l

			if e.additional_offset == 0 {
				if !e.fast_mode {
					if e.match_price_count >= 64 {
						fill_align_prices(e)
						fill_distances_prices(e)
						len_price_update_tables(e, &e.len_enc, u32(1) << e.pb, &e.len_probs)
					}
					if e.rep_len_enc_counter <= 0 {
						e.rep_len_enc_counter = REP_LEN_COUNT
						len_price_update_tables(e, &e.rep_len_enc, u32(1) << e.pb, &e.rep_len_probs)
					}
				}
				if mf_avail(&e.mf) == 0 {
					break
				}
				processed := now_pos32 - start_pos32
				if max_pack_size != 0 {
					if processed + NUM_OPTS + 300 >= max_unpack_size || re_processed(rc) + PACK_RESERVE >= int(max_pack_size) {
						break
					}
				}
			}
		}
	}

	e.now_pos64 += u64(now_pos32 - start_pos32)
	flush(e, now_pos32)
}

@(private)
encode_lzma :: proc(rc: ^Range_Encoder, input: []u8, opts: Options, allocator: runtime.Allocator) -> (written: int, err: Error) {
	context.allocator = allocator
	e := new(Encoder) or_return
	defer free(e)
	defer encoder_destroy(e)
	e.rc = rc^
	encoder_create(e, opts, input, false) or_return

	code_one_block(e, 0, 0)
	rc^ = e.rc

	if rc.grow_err != nil {
		return 0, rc.grow_err
	}
	written = rc.pos - rc.start
	if rc.pos > rc.cap {
		return written, General_Error.Output_Too_Short
	}
	if e.now_pos64 != u64(len(input)) {
		return written, General_Error.Output_Too_Short
	}
	return
}

@(private)
encode_lzma2 :: proc(rc: ^Range_Encoder, input: []u8, opts: Options, allocator: runtime.Allocator) -> (written: int, err: Error) #no_bounds_check {
	context.allocator = allocator
	e := new(Encoder) or_return
	defer free(e)
	defer encoder_destroy(e)
	e.rc = rc^
	encoder_create(e, opts, input, true) or_return
	defer rc^ = e.rc

	out             := &e.rc
	out_start       := out.pos
	props_byte      := (opts.pb * 5 + opts.lp) * 9 + opts.lc
	need_init_state := true
	need_init_prop  := true
	src_pos         := 0

	for src_pos < len(input) {
		chunk_start := out.pos
		header_size := 6 if need_init_prop else 5
		if out.limit - chunk_start < header_size {
			return chunk_start - out_start, General_Error.Output_Too_Short
		}

		e.saved = e.probs
		copy(e.saved_lit_probs, e.lit_probs)
		e.write_end_mark = false
		e.finished       = false
		out.pos          = chunk_start + header_size
		if need_init_state {
			encoder_init(e)
		}
		encoder_init_prices(e)
		re_reset(out)

		now_pos := e.now_pos64
		code_one_block(e, LZMA2_PACK_CHUNK_MAX, LZMA2_UNPACK_CHUNK_MAX)
		if out.grow_err != nil {
			return 0, out.grow_err
		}
		unpack_size := int(e.now_pos64 - now_pos)
		pack_size   := out.pos - (chunk_start + header_size)
		if unpack_size == 0 {
			out.pos = chunk_start
			break
		}

		if out.pos > out.cap || pack_size + 2 >= unpack_size || pack_size > LZMA2_PACK_CHUNK_MAX {
			dest := chunk_start
			src  := e.mf.buffer[-int(e.additional_offset) - unpack_size:]
			left := unpack_size
			for left > 0 {
				u := min(left, LZMA2_COPY_CHUNK_MAX)
				if out.limit - dest < u + 3 || !re_reserve(out, dest + u + 3) {
					out.pos = dest
					if out.grow_err != nil {
						return 0, out.grow_err
					}
					return dest - out_start, General_Error.Output_Too_Short
				}
				out.buf[dest]     = LZMA2_CONTROL_COPY_RESET_DICT if src_pos == 0 else LZMA2_CONTROL_COPY
				out.buf[dest + 1] = u8((u - 1) >> 8)
				out.buf[dest + 2] = u8(u - 1)
				intrinsics.mem_copy_non_overlapping(&out.buf[dest + 3], src, u)
				src      = src[u:]
				left    -= u
				dest    += 3 + u
				src_pos += u
			}
			out.pos = dest
			e.probs = e.saved
			copy(e.lit_probs, e.saved_lit_probs)
			continue
		}

		mode := u32(0)
		if src_pos == 0 {
			mode = 3
		} else if need_init_state {
			mode = 2 if need_init_prop else 1
		}
		u  := u32(unpack_size - 1)
		pm := u32(pack_size - 1)
		out.buf[chunk_start]     = u8(LZMA2_CONTROL_LZMA | (mode << 5) | ((u >> 16) & 0x1F))
		out.buf[chunk_start + 1] = u8(u >> 8)
		out.buf[chunk_start + 2] = u8(u)
		out.buf[chunk_start + 3] = u8(pm >> 8)
		out.buf[chunk_start + 4] = u8(pm)
		if need_init_prop {
			out.buf[chunk_start + 5] = props_byte
		}
		need_init_prop  = false
		need_init_state = false
		src_pos += unpack_size
	}

	if src_pos != len(input) {
		return out.pos - out_start, General_Error.Output_Too_Short
	}
	if out.pos >= out.limit || !re_reserve(out, out.pos + 1) {
		if out.grow_err != nil {
			return 0, out.grow_err
		}
		return out.pos - out_start, General_Error.Output_Too_Short
	}
	out.buf[out.pos] = 0
	out.pos += 1
	return out.pos - out_start, nil
}

@(private)
mf_create :: proc(mf: ^Match_Finder, kind: Match_Finder_Kind, history_size, match_max_len, keep_after, cut_value: u32, expected_size: u64) -> (err: Error) {
	mf.kind           = kind
	mf.bt_mode        = kind >= .BT2
	mf.num_hash_bytes = MF_HASH_BYTES[kind]
	mf.cut_value      = cut_value

	keep_after := keep_after
	keep_after += match_max_len
	if keep_after < mf.num_hash_bytes {
		keep_after = mf.num_hash_bytes
	}
	mf.keep_size_after = keep_after

	hs     := mf_hash_mask(mf, history_size)
	hs_cur := hs
	if expected_size < u64(history_size) {
		hs_cur = mf_hash_mask(mf, u32(expected_size))
		if hs_cur >= hs {
			hs_cur = hs
		}
	}
	mf.hash_mask = hs_cur

	fixed := u32(0)
	if mf.num_hash_bytes > 2 {
		fixed += MF_HASH2_SIZE
	}
	if mf.num_hash_bytes > 3 {
		fixed += MF_HASH3_SIZE
	}
	mf.fixed_hash_size = fixed
	mf.match_max_len   = match_max_len
	mf.history_size    = history_size
	mf.cyclic_size     = history_size + 1

	hash_size_sum := u64(hs) + 1 + u64(fixed)
	num_sons      := u64(mf.cyclic_size)
	if mf.bt_mode {
		num_sons <<= 1
	}
	total := (hash_size_sum + num_sons + 15) &~ u64(15)
	if total > u64(max(int) / size_of(u32)) {
		return runtime.Allocator_Error.Out_Of_Memory
	}
	data := runtime.mem_alloc_non_zeroed(int(total) * size_of(u32)) or_return
	mf.refs = ([^]u32)(raw_data(data))[:total]
	mf.hash = raw_data(mf.refs)
	mf.son  = mf.hash[hash_size_sum:]

	for i in 0..<256 {
		r := u32(i)
		for _ in 0..<8 {
			r = (r >> 1) ~ (MF_CRC_POLY & (0 - (r & 1)))
		}
		mf.crc[i] = r
	}
	return nil
}

@(private)
mf_destroy :: proc(mf: ^Match_Finder) {
	delete(mf.refs)
	mf.refs = nil
}

@(private)
mf_hash_mask :: proc "contextless" (mf: ^Match_Finder, hs: u32) -> u32 {
	if mf.num_hash_bytes == 2 {
		return (1 << 16) - 1
	}
	hs := hs
	if hs != 0 {
		hs -= 1
	}
	hs |= hs >> 1
	hs |= hs >> 2
	hs |= hs >> 4
	hs |= hs >> 8
	hs >>= 1
	if hs >= 1 << 24 {
		if mf.num_hash_bytes == 3 {
			hs = (1 << 24) - 1
		} else {
			hs >>= 1
		}
	}
	hs |= (1 << 16) - 1
	if mf.num_hash_bytes >= 5 {
		hs |= (256 << MF_CRC_SHIFT_2) - 1
	}
	return hs
}

@(private)
mf_init :: proc(mf: ^Match_Finder, input: []u8) #no_bounds_check {
	for i in 0..<int(mf.hash_mask) + 1 + int(mf.fixed_hash_size) {
		mf.hash[i] = MF_EMPTY_HASH
	}
	mf.buffer     = raw_data(input)
	mf.direct_rem = len(input)
	mf.pos        = 1
	mf.stream_pos = 1
	mf.stream_end = false
	mf_read_block(mf)
	mf.cyclic_pos = mf.pos
	mf_set_limits(mf)
}

@(private)
mf_avail :: #force_inline proc "contextless" (mf: ^Match_Finder) -> u32 {
	return mf.stream_pos - mf.pos
}

@(private)
mf_read_block :: proc "contextless" (mf: ^Match_Finder) {
	if mf.stream_end {
		return
	}
	cur := 0xFFFF_FFFF - mf_avail(mf)
	if u64(cur) > u64(mf.direct_rem) {
		cur = u32(mf.direct_rem)
	}
	mf.stream_pos += cur
	mf.direct_rem -= int(cur)
	if mf.direct_rem == 0 {
		mf.stream_end = true
	}
}

@(private)
mf_set_limits :: proc "contextless" (mf: ^Match_Finder) {
	n := MF_MAX_VAL_FOR_NORMALIZE - mf.pos
	if n == 0 {
		n = 0xFFFF_FFFF
	}
	k := mf.cyclic_size - mf.cyclic_pos
	if k < n {
		n = k
	}
	k = mf_avail(mf)
	mm := mf.match_max_len
	if k > mf.keep_size_after {
		k -= mf.keep_size_after
	} else if k >= mm {
		k -= mm
		k += 1
	} else {
		mm = k
		if k != 0 {
			k = 1
		}
	}
	mf.len_limit = mm
	if k < n {
		n = k
	}
	mf.pos_limit = mf.pos + n
}

@(private)
mf_normalize :: proc "contextless" (sub: u32, items: [^]u32, count: int) #no_bounds_check {
	for i in 0..<count {
		items[i] = max(items[i], sub) - sub
	}
}

@(private)
mf_check_limits :: proc "contextless" (mf: ^Match_Finder) {
	if mf.keep_size_after == mf_avail(mf) {
		mf_read_block(mf)
	}
	if mf.pos == MF_MAX_VAL_FOR_NORMALIZE && mf_avail(mf) >= mf.num_hash_bytes {
		sub := mf.pos - mf.history_size - 1
		mf.pos        -= sub
		mf.stream_pos -= sub
		mf_normalize(sub, mf.hash, int(mf.hash_mask) + 1 + int(mf.fixed_hash_size))
		num_sons := int(mf.cyclic_size)
		if mf.bt_mode {
			num_sons <<= 1
		}
		mf_normalize(sub, mf.son, num_sons)
	}
	if mf.cyclic_pos == mf.cyclic_size {
		mf.cyclic_pos = 0
	}
	mf_set_limits(mf)
}

@(private)
mf_move_pos :: #force_inline proc "contextless" (mf: ^Match_Finder) {
	mf.cyclic_pos += 1
	mf.buffer      = mf.buffer[1:]
	mf.pos        += 1
	if mf.pos == mf.pos_limit {
		mf_check_limits(mf)
	}
}

@(private)
hc_get_matches_spec :: #force_inline proc "contextless" (len_limit, cur_match, pos: u32, cur: [^]u8, son: [^]u32, cyclic_pos, cyclic_size, cut_value: u32, d: [^]u32, max_len: u32) -> [^]u32 #no_bounds_check {
	cur_match := cur_match
	cut_value := cut_value
	max_len   := max_len
	d         := d
	son[cyclic_pos] = cur_match
	for {
		if cur_match == 0 {
			break
		}
		delta := pos - cur_match
		if delta >= cyclic_size {
			break
		}
		cur_match = son[cyclic_pos - delta + (cyclic_size if cyclic_pos < delta else 0)]
		diff := -int(delta)
		if cur[max_len] == cur[int(max_len) + diff] {
			c := 0
			for cur[c] == cur[c + diff] {
				c += 1
				if c == int(len_limit) {
					d[0] = len_limit
					d[1] = delta - 1
					return d[2:]
				}
			}
			if max_len < u32(c) {
				max_len = u32(c)
				d[0] = u32(c)
				d[1] = delta - 1
				d = d[2:]
			}
		}
		cut_value -= 1
		if cut_value == 0 {
			break
		}
	}
	return d
}

@(private)
bt_get_matches_spec :: #force_inline proc "contextless" (len_limit, cur_match, pos: u32, cur: [^]u8, son: [^]u32, cyclic_pos, cyclic_size, cut_value: u32, d: [^]u32, max_len: u32) -> [^]u32 #no_bounds_check {
	cur_match := cur_match
	cut_value := cut_value
	max_len   := max_len
	d         := d
	ptr0 := &son[(cyclic_pos << 1) + 1]
	ptr1 := &son[cyclic_pos << 1]
	len0, len1: u32

	cm_check := pos - cyclic_size
	if pos < cyclic_size {
		cm_check = 0
	}
	if cm_check < cur_match {
		for {
			delta := pos - cur_match
			pair  := son[(cyclic_pos - delta + (cyclic_size if cyclic_pos < delta else 0)) << 1:]
			pb    := cur[-int(delta):]
			l     := min(len0, len1)
			pair0 := pair[0]
			if pb[l] == cur[l] {
				l += 1
				if l != len_limit && pb[l] == cur[l] {
					for {
						l += 1
						if l == len_limit || pb[l] != cur[l] {
							break
						}
					}
				}
				if max_len < l {
					max_len = l
					d[0] = l
					d[1] = delta - 1
					d = d[2:]
					if l == len_limit {
						ptr1^ = pair0
						ptr0^ = pair[1]
						return d
					}
				}
			}
			if pb[l] < cur[l] {
				ptr1^     = cur_match
				cur_match = pair[1]
				ptr1      = &pair[1]
				len1      = l
			} else {
				ptr0^     = cur_match
				cur_match = pair[0]
				ptr0      = &pair[0]
				len0      = l
			}
			cut_value -= 1
			if cut_value == 0 || cm_check >= cur_match {
				break
			}
		}
	}
	ptr0^ = MF_EMPTY_HASH
	ptr1^ = MF_EMPTY_HASH
	return d
}

@(private)
bt_skip_matches_spec :: #force_inline proc "contextless" (len_limit, cur_match, pos: u32, cur: [^]u8, son: [^]u32, cyclic_pos, cyclic_size, cut_value: u32) #no_bounds_check {
	cur_match := cur_match
	cut_value := cut_value
	ptr0 := &son[(cyclic_pos << 1) + 1]
	ptr1 := &son[cyclic_pos << 1]
	len0, len1: u32

	cm_check := pos - cyclic_size
	if pos < cyclic_size {
		cm_check = 0
	}
	if cm_check < cur_match {
		for {
			delta := pos - cur_match
			pair  := son[(cyclic_pos - delta + (cyclic_size if cyclic_pos < delta else 0)) << 1:]
			pb    := cur[-int(delta):]
			l     := min(len0, len1)
			if pb[l] == cur[l] {
				for {
					l += 1
					if l == len_limit || pb[l] != cur[l] {
						break
					}
				}
				if l == len_limit {
					ptr1^ = pair[0]
					ptr0^ = pair[1]
					return
				}
			}
			if pb[l] < cur[l] {
				ptr1^     = cur_match
				cur_match = pair[1]
				ptr1      = &pair[1]
				len1      = l
			} else {
				ptr0^     = cur_match
				cur_match = pair[0]
				ptr0      = &pair[0]
				len0      = l
			}
			cut_value -= 1
			if cut_value == 0 || cm_check >= cur_match {
				break
			}
		}
	}
	ptr0^ = MF_EMPTY_HASH
	ptr1^ = MF_EMPTY_HASH
}

@(private)
mf_update_max_len :: #force_inline proc "contextless" (cur: [^]u8, d2, max_len, len_limit: u32) -> u32 #no_bounds_check {
	c    := max_len
	diff := -int(d2)
	for c != len_limit && cur[int(c) + diff] == cur[c] {
		c += 1
	}
	return c
}

@(private)
mf_get_matches :: proc "contextless" (mf: ^Match_Finder, distances: [^]u32) -> (count: u32) #no_bounds_check {
	d := distances
	len_limit := mf.len_limit
	if len_limit < mf.num_hash_bytes {
		mf_move_pos(mf)
		return 0
	}
	cur  := mf.buffer
	pos  := mf.pos
	hash := mf.hash
	cur_match: u32
	max_len:   u32

	switch mf.kind {
	case .BT2:
		hv := u32(cur[0]) | u32(cur[1]) << 8
		cur_match = hash[hv]
		hash[hv]  = pos
		max_len   = 1

	case .BT3:
		temp := mf.crc[cur[0]] ~ u32(cur[1])
		h2   := temp & (MF_HASH2_SIZE - 1)
		hv   := (temp ~ (u32(cur[2]) << 8)) & mf.hash_mask
		d2   := pos - hash[h2]
		cur_match = hash[MF_FIX3_HASH_SIZE + hv]
		hash[h2] = pos
		hash[MF_FIX3_HASH_SIZE + hv] = pos
		mmm := min(mf.cyclic_size, pos)
		max_len = 2
		if d2 < mmm && cur[-int(d2)] == cur[0] {
			max_len = mf_update_max_len(cur, d2, max_len, len_limit)
			d[0] = max_len
			d[1] = d2 - 1
			d = d[2:]
			if max_len == len_limit {
				bt_skip_matches_spec(len_limit, cur_match, pos, cur, mf.son, mf.cyclic_pos, mf.cyclic_size, mf.cut_value)
				mf_move_pos(mf)
				return u32(uintptr(d) - uintptr(distances)) / size_of(u32)
			}
		}

	case .BT4, .HC4, .BT5, .HC5:
		temp := mf.crc[cur[0]] ~ u32(cur[1])
		h2   := temp & (MF_HASH2_SIZE - 1)
		temp ~= u32(cur[2]) << 8
		h3   := temp & (MF_HASH3_SIZE - 1)
		hv: u32
		five := mf.kind == .BT5 || mf.kind == .HC5
		if five {
			temp ~= mf.crc[cur[3]] << MF_CRC_SHIFT_1
			hv = (temp ~ (mf.crc[cur[4]] << MF_CRC_SHIFT_2)) & mf.hash_mask
		} else {
			hv = (temp ~ (mf.crc[cur[3]] << MF_CRC_SHIFT_1)) & mf.hash_mask
		}
		d2 := pos - hash[h2]
		d3 := pos - hash[MF_FIX3_HASH_SIZE + h3]
		cur_match = hash[MF_FIX4_HASH_SIZE + hv]
		hash[h2] = pos
		hash[MF_FIX3_HASH_SIZE + h3] = pos
		hash[MF_FIX4_HASH_SIZE + hv] = pos
		mmm := min(mf.cyclic_size, pos)
		max_len = 4 if five else 3

		search: for {
			if d2 < mmm && cur[-int(d2)] == cur[0] {
				d[0] = 2
				d[1] = d2 - 1
				d = d[2:]
				if cur[2 - int(d2)] == cur[2] {
				} else if d3 < mmm && cur[-int(d3)] == cur[0] {
					d2 = d3
					d[1] = d3 - 1
					d = d[2:]
				} else {
					break search
				}
			} else if d3 < mmm && cur[-int(d3)] == cur[0] {
				d2 = d3
				d[1] = d3 - 1
				d = d[2:]
			} else {
				break search
			}
			if five {
				d[-2] = 3
				if cur[3 - int(d2)] != cur[3] {
					break search
				}
			}
			max_len = mf_update_max_len(cur, d2, max_len, len_limit)
			d[-2] = max_len
			if max_len == len_limit {
				if mf.bt_mode {
					bt_skip_matches_spec(len_limit, cur_match, pos, cur, mf.son, mf.cyclic_pos, mf.cyclic_size, mf.cut_value)
				} else {
					mf.son[mf.cyclic_pos] = cur_match
				}
				mf_move_pos(mf)
				return u32(uintptr(d) - uintptr(distances)) / size_of(u32)
			}
			break search
		}
	}

	if mf.bt_mode {
		d = bt_get_matches_spec(len_limit, cur_match, pos, cur, mf.son, mf.cyclic_pos, mf.cyclic_size, mf.cut_value, d, max_len)
	} else {
		d = hc_get_matches_spec(len_limit, cur_match, pos, cur, mf.son, mf.cyclic_pos, mf.cyclic_size, mf.cut_value, d, max_len)
	}
	mf_move_pos(mf)
	return u32(uintptr(d) - uintptr(distances)) / size_of(u32)
}

@(private)
mf_skip :: proc "contextless" (mf: ^Match_Finder, num: u32) #no_bounds_check {
	num := num
	if !mf.bt_mode {
		five := mf.kind == .HC5
		for num != 0 {
			if mf.len_limit < mf.num_hash_bytes {
				mf_move_pos(mf)
				num -= 1
				continue
			}
			pos  := mf.pos
			num2 := num
			rem  := mf.pos_limit - pos
			if num2 >= rem {
				num2 = rem
			}
			num -= num2
			son := mf.son[mf.cyclic_pos:]
			mf.cyclic_pos += num2
			cur  := mf.buffer
			hash := mf.hash
			for {
				temp := mf.crc[cur[0]] ~ u32(cur[1])
				h2   := temp & (MF_HASH2_SIZE - 1)
				temp ~= u32(cur[2]) << 8
				h3   := temp & (MF_HASH3_SIZE - 1)
				hv: u32
				if five {
					temp ~= mf.crc[cur[3]] << MF_CRC_SHIFT_1
					hv = (temp ~ (mf.crc[cur[4]] << MF_CRC_SHIFT_2)) & mf.hash_mask
				} else {
					hv = (temp ~ (mf.crc[cur[3]] << MF_CRC_SHIFT_1)) & mf.hash_mask
				}
				cur_match := hash[MF_FIX4_HASH_SIZE + hv]
				hash[h2] = pos
				hash[MF_FIX3_HASH_SIZE + h3] = pos
				hash[MF_FIX4_HASH_SIZE + hv] = pos
				cur = cur[1:]
				pos += 1
				son[0] = cur_match
				son = son[1:]
				num2 -= 1
				if num2 == 0 {
					break
				}
			}
			mf.buffer = cur
			mf.pos    = pos
			if pos == mf.pos_limit {
				mf_check_limits(mf)
			}
		}
		return
	}

	for {
		if mf.len_limit >= mf.num_hash_bytes {
			cur  := mf.buffer
			pos  := mf.pos
			hash := mf.hash
			cur_match: u32
			switch mf.kind {
			case .BT2:
				hv := u32(cur[0]) | u32(cur[1]) << 8
				cur_match = hash[hv]
				hash[hv]  = pos
			case .BT3:
				temp := mf.crc[cur[0]] ~ u32(cur[1])
				h2   := temp & (MF_HASH2_SIZE - 1)
				hv   := (temp ~ (u32(cur[2]) << 8)) & mf.hash_mask
				cur_match = hash[MF_FIX3_HASH_SIZE + hv]
				hash[h2] = pos
				hash[MF_FIX3_HASH_SIZE + hv] = pos
			case .BT4, .BT5, .HC4, .HC5:
				temp := mf.crc[cur[0]] ~ u32(cur[1])
				h2   := temp & (MF_HASH2_SIZE - 1)
				temp ~= u32(cur[2]) << 8
				h3   := temp & (MF_HASH3_SIZE - 1)
				hv: u32
				if mf.kind == .BT5 {
					temp ~= mf.crc[cur[3]] << MF_CRC_SHIFT_1
					hv = (temp ~ (mf.crc[cur[4]] << MF_CRC_SHIFT_2)) & mf.hash_mask
				} else {
					hv = (temp ~ (mf.crc[cur[3]] << MF_CRC_SHIFT_1)) & mf.hash_mask
				}
				cur_match = hash[MF_FIX4_HASH_SIZE + hv]
				hash[h2] = pos
				hash[MF_FIX3_HASH_SIZE + h3] = pos
				hash[MF_FIX4_HASH_SIZE + hv] = pos
			}
			bt_skip_matches_spec(mf.len_limit, cur_match, pos, cur, mf.son, mf.cyclic_pos, mf.cyclic_size, mf.cut_value)
		}
		mf_move_pos(mf)
		num -= 1
		if num == 0 {
			break
		}
	}
}
