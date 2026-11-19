package compress_bzip2

import "base:intrinsics"
import "base:runtime"
import "core:compress"
import "core:io"

decompress :: proc{decompress_from_bytes, decompress_from_context}

decompress_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return decompress_from_context(&ctx, expected_output_size, options, allocator)
}

decompress_from_context :: proc(z: ^compress.Context, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	max_output_size := compress.output_limit(options)
	if z.output == nil || max_output_size < 0 || options.progress_interval < 0 {
		return General_Error.Incompatible_Options
	}

	expected := compress.declared_size(expected_output_size)
	limit    := max_output_size
	if expected >= 0 {
		if expected > limit {
			return General_Error.Output_Too_Short
		}
		limit = expected
	}

	memory := compress.is_memory_context(z)
	br     := BZip2_Bit_Reader{data = z.window}
	if !memory {
		br.z = z
	}

	input_size := len(z.window) if memory else compress.input_size(z)
	non_zero_reserve(z.output, min(compress.output_reservation(expected, bzip2_decompress_bound(input_size) if input_size >= 0 else -1, input_size), limit)) or_return

	total_out := i64(expected)
	interval  := compress.progress_interval(options)
	mark      := max(int)
	if options.progress != nil {
		mark = interval
	}

	written := 0
	defer {
		non_zero_resize(z.output, written)
		z.bytes_written = i64(written)
		z.window = br.data[min(br.pos, len(br.data)):]
	}

	tts:     [BZIP2_INTERLEAVE][]u32
	scratch: [BZIP2_INTERLEAVE][]u8
	defer for k in 0..<BZIP2_INTERLEAVE {
		delete(tts[k])
		delete(scratch[k])
	}
	pending: [BZIP2_INTERLEAVE]BZip2_Pending = ---
	d: BZip2_Decoder = ---

	stream_loop: for streams := 0; ; streams += 1 {
		nblock_max, at_end := bzip2_stream_header(&br, streams) or_return
		if at_end {
			break stream_loop
		}

		combined: u32
		np := 0
		block_err: Error
		for {
			if written >= mark {
				compress.report_progress(options, bzip2_bytes_in(&br), i64(written), i64(input_size), total_out) or_return
				mark = written + interval if interval < max(int) - written else max(int)
			}
			magic := u64(bzip2_bits(&br, 24)) << 24
			magic |= u64(bzip2_bits(&br, 24))
			stored_crc := bzip2_bits(&br, 32)
			if block_err = bzip2_check_overrun(&br); block_err != nil {
				break
			}
			if magic == END_MAGIC {
				written, err = bzip2_flush(z.output, written, limit, tts[:], scratch[:], pending[:np], &combined)
				if err != nil {
					break stream_loop
				}
				if stored_crc != combined {
					return BZip2_Error.Stream_Checksum_Failed
				}
				if written >= mark {
					compress.report_progress(options, bzip2_bytes_in(&br), i64(written), i64(input_size), total_out) or_return
					mark = written + interval if interval < max(int) - written else max(int)
				}
				break
			}
			if magic != BLOCK_MAGIC {
				block_err = BZip2_Error.Invalid_Block_Magic
				break
			}

			if len(tts[np]) < nblock_max {
				delete(tts[np])
				tts[np] = nil
				tts[np], block_err = non_zero_make([]u32, nblock_max)
				if block_err != nil {
					break
				}
			}
			nblock, orig_ptr: int
			randomised: bool
			nblock, orig_ptr, randomised, block_err = bzip2_decode_block(&d, &br, tts[np][:nblock_max])
			if block_err != nil {
				break
			}
			if randomised {
				written, err = bzip2_flush(z.output, written, limit, tts[:], scratch[:], pending[:np], &combined)
				if err != nil {
					break stream_loop
				}
				start := written
				written, err = bzip2_emit_block(z.output, written, limit, tts[np][:nblock], orig_ptr, true)
				if err != nil {
					break stream_loop
				}
				block_crc := ~bzip2_crc(0xffff_ffff, z.output[start:written])
				if block_crc != stored_crc {
					return BZip2_Error.Block_Checksum_Failed
				}
				combined = ((combined << 1) | (combined >> 31)) ~ block_crc
				np = 0
				continue
			}
			pending[np] = {nblock, orig_ptr, stored_crc}
			np += 1
			if np == BZIP2_INTERLEAVE {
				written, err = bzip2_flush(z.output, written, limit, tts[:], scratch[:], pending[:np], &combined)
				if err != nil {
					break stream_loop
				}
				np = 0
			}
		}
		if block_err != nil {
			written, err = bzip2_flush(z.output, written, limit, tts[:], scratch[:], pending[:np], &combined)
			if err != nil {
				break stream_loop
			}
			return block_err
		}
		bzip2_stream_end(z, &br) or_return
	}
	if expected >= 0 && (err == General_Error.Output_Too_Short || (err == nil && written != expected)) {
		return General_Error.Size_Mismatch
	}
	return
}

decompress_to_writer :: proc(w: io.Writer, z: ^compress.Context, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	r: Reader
	defer reader_destroy(&r)
	bzip2_stream_init(&r, z, expected_output_size, options, allocator) or_return
	for !r.done {
		fill_err := bzip2_stream_fill(&r)
		produced := r.written > r.flushed
		if produced {
			_, write_err := io.write_full(w, r.window[r.flushed:r.written])
			if write_err != nil {
				return write_err
			}
			r.flushed = r.written
		}
		if fill_err != nil {
			return fill_err
		}
		if produced || r.done {
			bzip2_reader_progress(&r) or_return
		}
	}
	return nil
}

reader_init :: proc(r: ^Reader, z: ^compress.Context, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	err   = bzip2_stream_init(r, z, expected_output_size, options, allocator)
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
			r.err = bzip2_stream_fill(r)
		}
	}
	if (n > 0 || (r.done && !was_done)) && r.err == nil {
		if r.err = bzip2_reader_progress(r); r.err != nil {
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
	s.procedure = bzip2_reader_stream_proc
	return
}

reader_destroy :: proc(r: ^Reader) {
	if r.owns_window {
		delete(r.window, r.allocator)
	}
	for k in 0..<BZIP2_INTERLEAVE {
		delete(r.tts[k], r.allocator)
		delete(r.scratch[k], r.allocator)
		r.tts[k]     = nil
		r.scratch[k] = nil
	}
	free(r.decoder, r.allocator)
	r.decoder     = nil
	r.window      = nil
	r.written     = 0
	r.flushed     = 0
	r.owns_window = false
}

@(private)
bzip2_stream_header :: proc(br: ^BZip2_Bit_Reader, streams: int) -> (nblock_max: int, at_end: bool, err: Error) {
	if br.z != nil && !br.eof && len(br.data) - br.pos < 4 {
		bzip2_fill(br, 4)
	}
	header := br.data[br.pos:]
	if len(header) < 4 || header[0] != 'B' || header[1] != 'Z' || header[2] != 'h' || header[3] < '1' || header[3] > '9' {
		if streams > 0 {
			return 0, true, nil
		}
		if len(header) < 4 {
			return 0, false, General_Error.Stream_Too_Short
		}
		return 0, false, BZip2_Error.Invalid_Magic
	}
	br.pos  += 4
	br.bits  = 0
	br.count = 0
	return int(header[3] - '0') * BZIP2_BLOCK_UNIT, false, nil
}

@(private)
bzip2_stream_end :: proc(z: ^compress.Context, br: ^BZip2_Bit_Reader) -> (err: Error) {
	next := br.pos - int(br.count / 8)
	br.bits  = 0
	br.count = 0
	if next < 0 {
		z.window = br.data
		if !compress.rewind(z, -next) {
			return General_Error.Stream_Too_Short
		}
		br.data      = z.window
		br.consumed += i64(next)
		next         = 0
	}
	br.pos = next
	return nil
}

@(private)
bzip2_decompress_bound :: proc "contextless" (input_size: int) -> int {
	payload := max(input_size - BZIP2_STREAM_OVERHEAD, 0)
	if payload > max(int) / compress.BZIP2_EXPANSION_MAX {
		return max(int)
	}
	return compress.BZIP2_EXPANSION_MAX * payload
}

@(private)
bzip2_refill :: #force_inline proc(br: ^BZip2_Bit_Reader) #no_bounds_check {
	if br.pos + 8 <= len(br.data) {
		v := u64(intrinsics.unaligned_load((^u64be)(&br.data[br.pos])))
		br.bits  |= v >> br.count
		br.pos   += int((63 - br.count) >> 3)
		br.count |= 56
		return
	}
	bzip2_refill_slow(br)
}

@(private)
bzip2_refill_slow :: proc(br: ^BZip2_Bit_Reader) #no_bounds_check {
	if br.z != nil && !br.eof && br.pos <= len(br.data) {
		bzip2_fill(br, 8)
		if br.pos + 8 <= len(br.data) {
			bzip2_refill(br)
			return
		}
	}
	for br.count <= 56 {
		b := u64(0)
		if br.pos < len(br.data) {
			b = u64(br.data[br.pos])
		}
		br.bits  |= b << (56 - br.count)
		br.pos   += 1
		br.count += 8
	}
}

@(private)
bzip2_fill :: proc(br: ^BZip2_Bit_Reader, need: int) {
	br.consumed += i64(br.pos)
	br.z.window  = br.data[br.pos:]
	if compress.refill_window(br.z, need) != nil {
		br.eof = true
	}
	br.data = br.z.window
	br.pos  = 0
}

@(private)
bzip2_bits :: #force_inline proc (br: ^BZip2_Bit_Reader, n: uint) -> u32 {
	if br.count < n {
		bzip2_refill(br)
	}
	v := u32(br.bits >> (64 - n))
	br.bits  <<= n
	br.count  -= n
	return v
}

@(private)
bzip2_bytes_in :: proc "contextless" (br: ^BZip2_Bit_Reader) -> (n: i64) {
	return br.consumed + i64(min(br.pos - int(br.count >> 3), len(br.data)))
}

@(private)
bzip2_reader_progress :: proc(r: ^Reader) -> (err: Error) {
	return compress.report_progress(r.options, bzip2_bytes_in(&r.br), r.total - i64(r.written - r.flushed), r.total_in, r.total_out)
}

@(private)
bzip2_check_overrun :: proc "contextless" (br: ^BZip2_Bit_Reader) -> Error {
	if br.pos * 8 - int(br.count) > len(br.data) * 8 {
		return General_Error.Stream_Too_Short
	}
	return nil
}

@(private)
bzip2_build_table :: proc "contextless" (h: ^BZip2_Huffman, lengths: []u8) -> Error #no_bounds_check {
	count:  [BZIP2_MAX_CODE_LEN + 1]u32
	offset: [BZIP2_MAX_CODE_LEN + 2]u32 = ---
	offset[1] = 0
	for l in lengths {
		count[l] += 1
	}

	left := i32(1)
	for l in 1..=BZIP2_MAX_CODE_LEN {
		left <<= 1
		left  -= i32(count[l])
		if left < 0 {
			return BZip2_Error.Invalid_Huffman_Code
		}
	}

	for l in 1..=BZIP2_MAX_CODE_LEN {
		offset[l + 1] = offset[l] + count[l]
	}
	next := offset
	for l, sym in lengths {
		h.symbols[next[l]] = u16(sym)
		next[l] += 1
	}

	h.fast = {}
	code := u32(0)
	for l in 1..=BZIP2_MAX_CODE_LEN {
		h.limit[l] = code + count[l]
		h.delta[l] = i32(offset[l]) - i32(code)
		if l <= BZIP2_FAST_BITS {
			fill := u32(1) << uint(BZIP2_FAST_BITS - l)
			for k in 0..<count[l] {
				entry := h.symbols[offset[l] + k] << 5 | u16(l)
				first := (code + k) << uint(BZIP2_FAST_BITS - l)
				for f in first..<first + fill {
					h.fast[f] = entry
				}
			}
		}
		code = (code + count[l]) << 1
	}
	return nil
}

@(private)
bzip2_decode_symbol :: #force_inline proc (br: ^BZip2_Bit_Reader, h: ^BZip2_Huffman) -> (sym: u32, ok: bool) #no_bounds_check {
	if br.count < BZIP2_MAX_CODE_LEN {
		bzip2_refill(br)
	}
	entry := h.fast[br.bits >> (64 - BZIP2_FAST_BITS)]
	if entry != 0 {
		n := uint(entry & 31)
		br.bits  <<= n
		br.count  -= n
		return u32(entry >> 5), true
	}
	for l in uint(BZIP2_FAST_BITS + 1)..=BZIP2_MAX_CODE_LEN {
		code := u32(br.bits >> (64 - l))
		if code < h.limit[l] {
			br.bits  <<= l
			br.count  -= l
			return u32(h.symbols[i32(code) + h.delta[l]]), true
		}
	}
	return 0, false
}

@(private)
bzip2_decode_block :: proc(d: ^BZip2_Decoder, br: ^BZip2_Bit_Reader, tt: []u32) -> (nblock, orig_ptr: int, randomised: bool, err: Error) {
	randomised = bzip2_bits(br, 1) == 1
	orig_ptr   = int(bzip2_bits(br, 24))

	n_in_use := 0
	used     := bzip2_bits(br, 16)
	for i in 0..<16 {
		if used & (0x8000 >> uint(i)) == 0 {
			continue
		}
		bitmap := bzip2_bits(br, 16)
		for j in 0..<16 {
			if bitmap & (0x8000 >> uint(j)) != 0 {
				d.mtf[n_in_use] = u8(i * 16 + j)
				n_in_use += 1
			}
		}
	}
	if n_in_use == 0 {
		return 0, 0, false, BZip2_Error.No_Symbols_In_Use
	}
	alpha_size := n_in_use + 2

	n_groups := int(bzip2_bits(br, 3))
	if n_groups < BZIP2_MIN_GROUPS || n_groups > BZIP2_MAX_GROUPS {
		return 0, 0, false, BZip2_Error.Invalid_Group_Count
	}
	n_selectors := int(bzip2_bits(br, 15))
	if n_selectors < 1 {
		return 0, 0, false, BZip2_Error.Invalid_Selector_Count
	}

	group_mtf := [BZIP2_MAX_GROUPS]u8{0, 1, 2, 3, 4, 5}
	for i in 0..<n_selectors {
		j := 0
		for bzip2_bits(br, 1) == 1 {
			j += 1
			if j >= n_groups {
				return 0, 0, false, BZip2_Error.Invalid_Selector
			}
		}
		if i < BZIP2_MAX_SELECTORS {
			v := group_mtf[j]
			for k := j; k > 0; k -= 1 {
				group_mtf[k] = group_mtf[k - 1]
			}
			group_mtf[0]   = v
			d.selectors[i] = v
		}
	}
	n_selectors = min(n_selectors, BZIP2_MAX_SELECTORS)
	bzip2_check_overrun(br) or_return

	for t in 0..<n_groups {
		curr := int(bzip2_bits(br, 5))
		for s in 0..<alpha_size {
			for {
				if curr < 1 || curr > BZIP2_MAX_CODE_LEN {
					return 0, 0, false, BZip2_Error.Invalid_Code_Length
				}
				if bzip2_bits(br, 1) == 0 {
					break
				}
				if bzip2_bits(br, 1) == 0 {
					curr += 1
				} else {
					curr -= 1
				}
			}
			d.lengths[s] = u8(curr)
		}
		bzip2_build_table(&d.tables[t], d.lengths[:alpha_size]) or_return
	}
	bzip2_check_overrun(br) or_return

	d.counts = {}
	eob        := u32(alpha_size - 1)
	nblock_max := len(tt)
	group_no   := -1
	group_pos  := 0
	table: ^BZip2_Huffman

	next_symbol :: #force_inline proc (d: ^BZip2_Decoder, br: ^BZip2_Bit_Reader, table: ^^BZip2_Huffman, group_no, group_pos: ^int, n_selectors: int) -> (sym: u32, err: Error) {
		if group_pos^ == 0 {
			group_no^ += 1
			if group_no^ >= n_selectors {
				return 0, BZip2_Error.Selectors_Exhausted
			}
			group_pos^ = BZIP2_GROUP_SIZE
			table^     = &d.tables[d.selectors[group_no^]]
		}
		group_pos^ -= 1
		ok: bool
		sym, ok = bzip2_decode_symbol(br, table^)
		if !ok {
			return 0, BZip2_Error.Invalid_Huffman_Code
		}
		return sym, nil
	}
	sym := next_symbol(d, br, &table, &group_no, &group_pos, n_selectors) or_return
	for sym != eob {
		if sym <= BZIP2_RUNB {
			run := 0
			n   := 1
			for sym <= BZIP2_RUNB {
				if n >= BZIP2_RUN_MAX {
					return 0, 0, false, BZip2_Error.Run_Too_Long
				}
				run += int(sym + 1) * n
				n  <<= 1
				sym = next_symbol(d, br, &table, &group_no, &group_pos, n_selectors) or_return
			}
			if run > nblock_max - nblock {
				return 0, 0, false, BZip2_Error.Block_Too_Large
			}
			uc := d.mtf[0]
			d.counts[uc] += u32(run)
			for &v in tt[nblock:nblock + run] {
				v = u32(uc)
			}
			nblock += run
			continue
		}

		if nblock >= nblock_max {
			return 0, 0, false, BZip2_Error.Block_Too_Large
		}
		nn := int(sym - 1)
		uc := d.mtf[nn]
		for k := nn; k > 0; k -= 1 {
			d.mtf[k] = d.mtf[k - 1]
		}
		d.mtf[0] = uc
		d.counts[uc] += 1
		tt[nblock]    = u32(uc)
		nblock       += 1
		sym = next_symbol(d, br, &table, &group_no, &group_pos, n_selectors) or_return
	}
	bzip2_check_overrun(br) or_return

	if orig_ptr >= nblock {
		return 0, 0, false, BZip2_Error.Invalid_Original_Pointer
	}

	cftab: [256]u32 = ---
	sum := u32(0)
	for c in 0..<256 {
		cftab[c] = sum
		sum     += d.counts[c]
	}
	for i in 0..<nblock {
		uc := tt[i] & 0xff
		tt[cftab[uc]] |= u32(i) << 8
		cftab[uc] += 1
	}
	return
}

@(private)
bzip2_emit_block :: proc(output: ^[dynamic]u8, written, limit: int, tt: []u32, orig_ptr: int, $RANDOMISED: bool) -> (new_written: int, err: Error) {
	pos  := written
	t    := tt[orig_ptr] >> 8
	prev := u32(256)
	run  := 0

	when RANDOMISED {
		r_to_go := 0
		r_pos   := 0
	}

	for i := 0; i < len(tt); {
		t = tt[t]
		c := t & 0xff
		t >>= 8
		i  += 1
		when RANDOMISED {
			if r_to_go == 0 {
				r_to_go = int(BZIP2_RAND_TABLE[r_pos])
				r_pos   = (r_pos + 1) & 511
			}
			r_to_go -= 1
			if r_to_go == 1 {
				c ~= 1
			}
		}

		if pos >= len(output) {
			if err = bzip2_grow(output, pos + 1, limit); err != nil {
				return pos, err
			}
		}
		output[pos] = u8(c)
		pos += 1

		if c != prev {
			prev = c
			run  = 1
			continue
		}
		run += 1
		if run < 4 {
			continue
		}
		if i == len(tt) {
			break
		}

		t = tt[t]
		n := int(t & 0xff)
		t >>= 8
		i  += 1
		when RANDOMISED {
			if r_to_go == 0 {
				r_to_go = int(BZIP2_RAND_TABLE[r_pos])
				r_pos   = (r_pos + 1) & 511
			}
			r_to_go -= 1
			if r_to_go == 1 {
				n ~= 1
			}
		}

		if pos + n > len(output) {
			if err = bzip2_grow(output, pos + n, limit); err != nil {
				return bzip2_overflow(output, pos, limit, u8(prev), err)
			}
		}
		for &b in output[pos:pos + n] {
			b = u8(prev)
		}
		pos += n
		prev = 256
		run  = 0
	}
	return pos, nil
}

@(private)
bzip2_flush :: proc(output: ^[dynamic]u8, written, limit: int, tts: [][]u32, scratch: [][]u8, pend: []BZip2_Pending, combined: ^u32) -> (new_written: int, err: Error) {
	pos := written
	switch len(pend) {
	case 0:
		return pos, nil
	case 1:
		if pos, err = bzip2_emit_block(output, pos, limit, tts[0][:pend[0].nblock], pend[0].orig_ptr, false); err != nil {
			return pos, err
		}
		block_crc := ~bzip2_crc(0xffff_ffff, output[written:pos])
		if block_crc != pend[0].crc {
			return pos, BZip2_Error.Block_Checksum_Failed
		}
		combined^ = ((combined^ << 1) | (combined^ >> 31)) ~ block_crc
		return pos, nil
	}

	for p, k in pend {
		if len(scratch[k]) < p.nblock {
			delete(scratch[k])
			scratch[k] = nil
			if scratch[k], err = non_zero_make([]u8, len(tts[k])); err != nil {
				return pos, err
			}
		}
	}
	switch len(pend) {
	case 2: bzip2_walk(tts, scratch, pend, 2)
	case 3: bzip2_walk(tts, scratch, pend, 3)
	case 4: bzip2_walk(tts, scratch, pend, 4)
	}
	#assert(BZIP2_INTERLEAVE == 4)

	for p, k in pend {
		start := pos
		if pos, err = bzip2_unrle(output, pos, limit, scratch[k][:p.nblock]); err != nil {
			return pos, err
		}
		block_crc := ~bzip2_crc(0xffff_ffff, output[start:pos])
		if block_crc != p.crc {
			return pos, BZip2_Error.Block_Checksum_Failed
		}
		combined^ = ((combined^ << 1) | (combined^ >> 31)) ~ block_crc
	}
	return pos, nil
}

@(private)
bzip2_walk :: proc "contextless" (tts: [][]u32, scratch: [][]u8, pend: []BZip2_Pending, $K: int) #no_bounds_check {
	tt: [K][^]u32 = ---
	s:  [K][^]u8  = ---
	t:  [K]u32    = ---
	n := max(int)
	#unroll for k in 0..<K {
		tt[k] = raw_data(tts[k])
		s[k]  = raw_data(scratch[k])
		t[k]  = tt[k][pend[k].orig_ptr] >> 8
		n     = min(n, pend[k].nblock)
	}
	for i in 0..<n {
		#unroll for k in 0..<K {
			t[k]    = tt[k][t[k]]
			s[k][i] = u8(t[k])
			t[k]  >>= 8
		}
	}
	#unroll for k in 0..<K {
		for i in n..<pend[k].nblock {
			t[k]    = tt[k][t[k]]
			s[k][i] = u8(t[k])
			t[k]  >>= 8
		}
	}
}

@(private)
bzip2_unrle :: proc(output: ^[dynamic]u8, written, limit: int, s: []u8) -> (new_written: int, err: Error) #no_bounds_check {
	pos := written
	if pos + len(s) > len(output) {
		if err = bzip2_grow(output, min(pos + len(s), limit), limit); err != nil {
			return pos, err
		}
	}
	i := 0
	for i < len(s) {
		c := s[i]
		if i + 3 < len(s) && s[i + 1] == c && s[i + 2] == c && s[i + 3] == c {
			n := 4
			if i + 4 < len(s) {
				n += int(s[i + 4])
			}
			if pos + n > len(output) {
				if err = bzip2_grow(output, pos + n, limit); err != nil {
					return bzip2_overflow(output, pos, limit, c, err)
				}
			}
			for &b in output[pos:pos + n] {
				b = c
			}
			pos += n
			i   += 5
			continue
		}
		if pos >= len(output) {
			if err = bzip2_grow(output, pos + 1, limit); err != nil {
				return pos, err
			}
		}
		output[pos] = c
		pos += 1
		i   += 1
	}
	return pos, nil
}

@(private)
bzip2_overflow :: proc(output: ^[dynamic]u8, pos, limit: int, c: u8, grow_err: Error) -> (new_written: int, err: Error) {
	if grow_err != General_Error.Output_Too_Short || pos >= limit {
		return pos, grow_err
	}
	if err = bzip2_grow(output, limit, limit); err != nil {
		return pos, err
	}
	for &b in output[pos:limit] {
		b = c
	}
	return limit, grow_err
}

@(private)
bzip2_grow :: proc(output: ^[dynamic]u8, need, limit: int) -> (err: Error) {
	if need > limit {
		return General_Error.Output_Too_Short
	}
	if need > cap(output) {
		non_zero_reserve(output, compress.output_grow_capacity(cap(output), need, limit)) or_return
	}
	return non_zero_resize(output, cap(output))
}

@(private)
bzip2_crc :: proc "contextless" (crc: u32, data: []u8) -> u32 #no_bounds_check {
	crc := crc
	p   := data
	for len(p) >= 8 {
		a := crc ~ u32(intrinsics.unaligned_load((^u32be)(&p[0])))
		b := u32(intrinsics.unaligned_load((^u32be)(&p[4])))
		crc = BZIP2_CRC_TABLE[7][a >> 24] ~ BZIP2_CRC_TABLE[6][(a >> 16) & 0xff] ~ BZIP2_CRC_TABLE[5][(a >> 8) & 0xff] ~ BZIP2_CRC_TABLE[4][a & 0xff] ~
		      BZIP2_CRC_TABLE[3][b >> 24] ~ BZIP2_CRC_TABLE[2][(b >> 16) & 0xff] ~ BZIP2_CRC_TABLE[1][(b >> 8) & 0xff] ~ BZIP2_CRC_TABLE[0][b & 0xff]
		p = p[8:]
	}
	for b in p {
		crc = (crc << 8) ~ BZIP2_CRC_TABLE[0][(crc >> 24) ~ u32(b)]
	}
	return crc
}

@(private)
bzip2_stream_init :: proc(r: ^Reader, z: ^compress.Context, expected_output_size: int, options: compress.Options, allocator: runtime.Allocator) -> (err: Error) {
	r^ = {}
	r.z          = z
	r.allocator  = allocator
	r.limit      = -1
	r.crc        = 0xffff_ffff
	r.memory_max = compress.memory_limit(options)
	r.options    = options
	r.total_in   = -1
	r.total_out  = -1
	r.br         = BZip2_Bit_Reader{data = z.window}
	if !compress.is_memory_context(z) {
		r.br.z = z
	}

	if options.max_output_size < 0 || options.max_memory < 0 || options.chunk_size < 0 || options.progress_interval < 0 {
		return General_Error.Incompatible_Options
	}
	expected := i64(compress.declared_size(expected_output_size))
	r.total_out = expected
	if options.progress != nil {
		r.total_in = i64(compress.input_size(z))
	}
	if options.max_output_size > 0 {
		r.limit = i64(options.max_output_size)
	}
	if expected >= 0 {
		if r.limit >= 0 && expected > r.limit {
			return General_Error.Output_Too_Short
		}
		r.limit = expected
	}

	if options.buffer != nil {
		if len(options.buffer) == 0 {
			return General_Error.Incompatible_Options
		}
		r.window = options.buffer
	} else {
		size := options.chunk_size if options.chunk_size > 0 else CHUNK_SIZE
		if r.limit >= 0 && r.limit < i64(size) {
			size = int(r.limit)
		}
		if size > r.memory_max - size_of(BZip2_Decoder) {
			return General_Error.Memory_Limit_Exceeded
		}
		r.window      = non_zero_make([]u8, size, allocator) or_return
		r.owns_window = true
	}
	r.decoder = new(BZip2_Decoder, allocator) or_return
	return nil
}

@(private)
bzip2_stream_reserve :: proc(r: ^Reader, nblock_max: int) -> (err: Error) {
	fixed := size_of(BZip2_Decoder) + (len(r.window) if r.owns_window else 0)
	if fixed + 5 * nblock_max > r.memory_max {
		return General_Error.Memory_Limit_Exceeded
	}
	k := BZIP2_INTERLEAVE
	for k > 1 && fixed + k * 5 * nblock_max > r.memory_max {
		k -= 1
	}
	for j in k..<BZIP2_INTERLEAVE {
		delete(r.tts[j], r.allocator)
		delete(r.scratch[j], r.allocator)
		r.tts[j]     = nil
		r.scratch[j] = nil
	}
	r.interleave = k
	r.nblock_max = nblock_max
	return nil
}

@(private)
bzip2_stream_walk :: proc(r: ^Reader) -> (err: Error) {
	for k in 0..<r.count {
		if len(r.scratch[k]) < r.pending[k].nblock {
			delete(r.scratch[k], r.allocator)
			r.scratch[k] = nil
			r.scratch[k] = non_zero_make([]u8, len(r.tts[k]), r.allocator) or_return
		}
	}
	n := r.count - 1 if r.randomised else r.count
	switch n {
	case 1: bzip2_walk(r.tts[:], r.scratch[:], r.pending[:1], 1)
	case 2: bzip2_walk(r.tts[:], r.scratch[:], r.pending[:2], 2)
	case 3: bzip2_walk(r.tts[:], r.scratch[:], r.pending[:3], 3)
	case 4: bzip2_walk(r.tts[:], r.scratch[:], r.pending[:4], 4)
	}
	if r.randomised {
		p := r.pending[n]
		bzip2_walk_randomised(r.tts[n], r.scratch[n], p.nblock, p.orig_ptr)
	}
	return nil
}

@(private)
bzip2_walk_randomised :: proc "contextless" (tt: []u32, s: []u8, nblock, orig_ptr: int) #no_bounds_check {
	t       := tt[orig_ptr] >> 8
	r_to_go := 0
	r_pos   := 0
	for i in 0..<nblock {
		t = tt[t]
		c := u8(t)
		t >>= 8
		if r_to_go == 0 {
			r_to_go = int(BZIP2_RAND_TABLE[r_pos])
			r_pos   = (r_pos + 1) & 511
		}
		r_to_go -= 1
		if r_to_go == 1 {
			c ~= 1
		}
		s[i] = c
	}
}

@(private)
bzip2_unrle_window :: proc(r: ^Reader, s: []u8, capacity: int) -> (finished: bool) #no_bounds_check {
	out := r.window
	pos := r.written
	if r.run > 0 {
		k := min(r.run, capacity - pos)
		for &b in out[pos:pos + k] {
			b = r.run_byte
		}
		pos   += k
		r.run -= k
		if r.run > 0 {
			r.written = pos
			return false
		}
	}
	i := r.emit_pos
	for i < len(s) {
		c := s[i]
		if i + 3 < len(s) && s[i + 1] == c && s[i + 2] == c && s[i + 3] == c {
			n := 4
			if i + 4 < len(s) {
				n += int(s[i + 4])
			}
			i += 5
			k := min(n, capacity - pos)
			for &b in out[pos:pos + k] {
				b = c
			}
			pos += k
			if k < n {
				r.run      = n - k
				r.run_byte = c
				r.emit_pos = i
				r.written  = pos
				return false
			}
			continue
		}
		if pos >= capacity {
			r.emit_pos = i
			r.written  = pos
			return false
		}
		out[pos] = c
		pos += 1
		i   += 1
	}
	r.emit_pos = i
	r.written  = pos
	return true
}

@(private)
bzip2_stream_fill :: proc(r: ^Reader) -> (err: Error) {
	defer {
		r.z.bytes_written = r.total
		if err != nil || r.state == .Done {
			r.z.window = r.br.data[min(r.br.pos, len(r.br.data)):]
		}
	}
	if r.flushed == r.written {
		r.written = 0
		r.flushed = 0
	}
	for {
		switch r.state {
		case .Done:
			r.done = true
			if r.total_out >= 0 && r.total != r.total_out {
				return General_Error.Size_Mismatch
			}
			return nil

		case .Header:
			nblock_max, at_end := bzip2_stream_header(&r.br, r.streams) or_return
			if at_end {
				r.state = .Done
				continue
			}
			bzip2_stream_reserve(r, nblock_max) or_return
			r.combined = 0
			r.count    = 0
			r.state    = .Block

		case .Block:
			block_err: Error
			magic := u64(bzip2_bits(&r.br, 24)) << 24
			magic |= u64(bzip2_bits(&r.br, 24))
			stored_crc := bzip2_bits(&r.br, 32)
			block: if block_err = bzip2_check_overrun(&r.br); block_err == nil {
				if magic == END_MAGIC {
					r.stream_crc = stored_crc
					r.after      = .Trailer
					r.state      = .Emit if r.count > 0 else .Trailer
					break block
				}
				if magic != BLOCK_MAGIC {
					block_err = BZip2_Error.Invalid_Block_Magic
					break block
				}
				if len(r.tts[r.count]) < r.nblock_max {
					delete(r.tts[r.count], r.allocator)
					r.tts[r.count] = nil
					if r.tts[r.count], block_err = non_zero_make([]u32, r.nblock_max, r.allocator); block_err != nil {
						break block
					}
				}
				nblock, orig_ptr: int
				randomised: bool
				nblock, orig_ptr, randomised, block_err = bzip2_decode_block(r.decoder, &r.br, r.tts[r.count][:r.nblock_max])
				if block_err != nil {
					break block
				}
				r.pending[r.count] = {nblock, orig_ptr, stored_crc}
				r.count     += 1
				r.randomised = randomised
				if randomised || r.count == r.interleave {
					r.after = .Block
					r.state = .Emit
				}
			}
			if block_err != nil {
				if r.count == 0 {
					return block_err
				}
				r.randomised = false
				r.deferred   = block_err
				r.state      = .Emit
			}

		case .Emit:
			if !r.walked {
				bzip2_stream_walk(r) or_return
				r.walked = true
			}
			for r.emit < r.count {
				capacity := len(r.window)
				if r.limit >= 0 && r.limit - r.total < i64(capacity - r.written) {
					capacity = r.written + int(r.limit - r.total)
				}
				start    := r.written
				finished := bzip2_unrle_window(r, r.scratch[r.emit][:r.pending[r.emit].nblock], capacity)
				r.crc    = bzip2_crc(r.crc, r.window[start:r.written])
				r.total += i64(r.written - start)
				if !finished {
					if r.limit >= 0 && r.total >= r.limit {
						return General_Error.Size_Mismatch if r.total_out >= 0 else General_Error.Output_Too_Short
					}
					return nil
				}
				block_crc := ~r.crc
				if block_crc != r.pending[r.emit].crc {
					return BZip2_Error.Block_Checksum_Failed
				}
				r.combined = ((r.combined << 1) | (r.combined >> 31)) ~ block_crc
				r.emit    += 1
				r.emit_pos = 0
				r.run      = 0
				r.crc      = 0xffff_ffff
			}
			r.count  = 0
			r.emit   = 0
			r.walked = false
			if r.deferred != nil {
				err        = r.deferred
				r.deferred = nil
				return err
			}
			r.state = r.after

		case .Trailer:
			if r.stream_crc != r.combined {
				return BZip2_Error.Stream_Checksum_Failed
			}
			bzip2_stream_end(r.z, &r.br) or_return
			r.streams += 1
			r.state    = .Header
		}
	}
}

@(private)
bzip2_reader_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
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
