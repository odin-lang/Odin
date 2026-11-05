package compress_bzip2

import "base:intrinsics"
import "base:runtime"
import "core:compress"

compress :: proc{compress_to_slice, compress_to_dynamic}

compress_bound :: proc(length: int) -> int {
	if length < 0 || length > (max(int) - 600) / 101 * 100 {
		return -1
	}
	return length + length / 100 + 600
}

compress_to_slice :: proc(s: ^BZip2, output, input: []u8, level := Level.Default) -> (written: int, err: Error) {
	if s == nil || level < .Level_1 || level > .Level_9 {
		return 0, General_Error.Incompatible_Options
	}
	bound := compress_bound(len(input))
	if bound < 0 {
		return 0, BZip2_Error.Input_Too_Large
	}
	if len(output) < bound {
		return 0, General_Error.Output_Too_Short
	}
	s.nblock_max = int(level) * BZIP2_BLOCK_UNIT - 19
	return bzip2_compress(s, output, input, level), nil
}

compress_to_dynamic :: proc(output: ^[dynamic]u8, input: []u8, level := Level.Default, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	if output == nil {
		return General_Error.Incompatible_Options
	}
	bound := compress_bound(len(input))
	if bound < 0 {
		return BZip2_Error.Input_Too_Large
	}
	if bound > compress.COMPRESS_OUTPUT_ALLOCATE_MAX {
		return General_Error.Output_Too_Short
	}
	state := runtime.mem_alloc_non_zeroed(size_of(BZip2), align_of(BZip2)) or_return
	s := (^BZip2)(raw_data(state))
	defer free(s)

	non_zero_resize(output, bound) or_return
	written: int
	written, err = compress_to_slice(s, output[:], input, level)
	non_zero_resize(output, written)
	return
}

@(private)
bzip2_compress :: proc(e: ^BZip2, output, input: []u8, level: Level) -> (written: int) {
	e.out     = output
	e.out_pos = 0
	e.bits    = 0
	e.live    = 0
	e.in_ch   = 256
	e.in_len  = 0

	bzip2_put_bits(e, 8, 'B')
	bzip2_put_bits(e, 8, 'Z')
	bzip2_put_bits(e, 8, 'h')
	bzip2_put_bits(e, 8, '0' + u32(level))

	combined := u32(0)
	in_pos   := 0
	start    := 0
	for {
		e.nblock = 0
		e.in_use = {}
		for e.nblock < e.nblock_max && in_pos < len(input) {
			bzip2_add_char(e, input[in_pos])
			in_pos += 1
		}
		last := in_pos == len(input)
		if last && e.in_ch < 256 {
			bzip2_add_run(e)
			e.in_ch  = 256
			e.in_len = 0
		}

		if e.nblock > 0 {
			end := in_pos
			if e.in_ch < 256 {
				end -= e.in_len
			}
			block_crc := ~bzip2_crc(0xffff_ffff, input[start:end])
			start = end
			combined = ((combined << 1) | (combined >> 31)) ~ block_crc

			bzip2_block_sort(e)

			bzip2_put_bits(e, 24, u32(BLOCK_MAGIC >> 24))
			bzip2_put_bits(e, 24, u32(BLOCK_MAGIC & 0xff_ffff))
			bzip2_put_u32(e, block_crc)
			bzip2_put_bits(e, 1, 0)
			bzip2_put_bits(e, 24, u32(e.orig_ptr))
			bzip2_generate_mtf_values(e)
			bzip2_send_mtf_values(e)
		}

		if last {
			break
		}
	}

	bzip2_put_bits(e, 24, u32(END_MAGIC >> 24))
	bzip2_put_bits(e, 24, u32(END_MAGIC & 0xff_ffff))
	bzip2_put_u32(e, combined)
	for e.live > 0 {
		e.out[e.out_pos] = u8(e.bits >> 56)
		e.out_pos += 1
		e.bits   <<= 8
		e.live     = e.live - 8 if e.live > 8 else 0
	}
	return e.out_pos
}

@(private)
bzip2_mtfv :: #force_inline proc "contextless" (e: ^BZip2) -> []u16 {
	return ([^]u16)(&e.ptr[0])[:len(e.ptr) * 2]
}

@(private)
bzip2_put_bits :: #force_inline proc "contextless" (e: ^BZip2, n: uint, v: u32) {
	e.bits |= u64(v) << (64 - e.live - n)
	e.live += n
	if e.live >= 32 {
		intrinsics.unaligned_store((^u32be)(&e.out[e.out_pos]), u32be(e.bits >> 32))
		e.out_pos += 4
		e.bits   <<= 32
		e.live    -= 32
	}
}

@(private)
bzip2_put_u32 :: #force_inline proc "contextless" (e: ^BZip2, v: u32) {
	bzip2_put_bits(e, 16, v >> 16)
	bzip2_put_bits(e, 16, v & 0xffff)
}

@(private)
bzip2_add_run :: proc "contextless" (e: ^BZip2) {
	ch := u8(e.in_ch)
	e.in_use[ch] = true
	switch e.in_len {
	case 1:
		e.block[e.nblock] = ch
		e.nblock += 1
	case 2:
		e.block[e.nblock]     = ch
		e.block[e.nblock + 1] = ch
		e.nblock += 2
	case 3:
		e.block[e.nblock]     = ch
		e.block[e.nblock + 1] = ch
		e.block[e.nblock + 2] = ch
		e.nblock += 3
	case:
		e.in_use[e.in_len - 4] = true
		e.block[e.nblock]     = ch
		e.block[e.nblock + 1] = ch
		e.block[e.nblock + 2] = ch
		e.block[e.nblock + 3] = ch
		e.block[e.nblock + 4] = u8(e.in_len - 4)
		e.nblock += 5
	}
}

@(private)
bzip2_add_char :: #force_inline proc "contextless" (e: ^BZip2, c: u8) {
	ch := u32(c)
	if ch != e.in_ch && e.in_len == 1 {
		e.in_use[e.in_ch] = true
		e.block[e.nblock] = u8(e.in_ch)
		e.nblock += 1
		e.in_ch   = ch
	} else if ch != e.in_ch || e.in_len == 255 {
		if e.in_ch < 256 {
			bzip2_add_run(e)
		}
		e.in_ch  = ch
		e.in_len = 1
	} else {
		e.in_len += 1
	}
}

@(private)
bzip2_block_sort :: proc(e: ^BZip2) {
	nblock := e.nblock
	if nblock < 10000 {
		bzip2_fallback_sort(e.ptr[:], e.work[:], e.ftab[:], e.block[:], nblock)
	} else {
		budget := nblock * ((BZIP2_WORK_FACTOR - 1) / 3)
		bzip2_main_sort(e.ptr[:], e.block[:], ([^]u16)(&e.work[0])[:len(e.work) * 2], e.ftab[:], nblock, &budget)
		if budget < 0 {
			bzip2_fallback_sort(e.ptr[:], e.work[:], e.ftab[:], e.block[:], nblock)
		}
	}

	e.orig_ptr = -1
	for i in 0..<nblock {
		if e.ptr[i] == 0 {
			e.orig_ptr = i
			break
		}
	}
	assert(e.orig_ptr != -1)
}

@(private)
bzip2_fallback_simple_sort :: proc "contextless" (fmap, eclass: []u32, lo, hi: int) {
	if lo == hi {
		return
	}
	if hi - lo > 3 {
		for i := hi - 4; i >= lo; i -= 1 {
			tmp    := fmap[i]
			ec_tmp := eclass[tmp]
			j := i + 4
			for ; j <= hi && ec_tmp > eclass[fmap[j]]; j += 4 {
				fmap[j - 4] = fmap[j]
			}
			fmap[j - 4] = tmp
		}
	}
	for i := hi - 1; i >= lo; i -= 1 {
		tmp    := fmap[i]
		ec_tmp := eclass[tmp]
		j := i + 1
		for ; j <= hi && ec_tmp > eclass[fmap[j]]; j += 1 {
			fmap[j - 1] = fmap[j]
		}
		fmap[j - 1] = tmp
	}
}

@(private)
bzip2_fallback_qsort3 :: proc "contextless" (fmap, eclass: []u32, lo_st, hi_st: int) {
	FALLBACK_QSORT_SMALL_THRESH :: 10
	FALLBACK_QSORT_STACK_SIZE   :: 100

	stack_lo: [FALLBACK_QSORT_STACK_SIZE]int = ---
	stack_hi: [FALLBACK_QSORT_STACK_SIZE]int = ---
	r  := u32(0)
	sp := 0
	stack_lo[sp] = lo_st
	stack_hi[sp] = hi_st
	sp += 1

	for sp > 0 {
		sp -= 1
		lo := stack_lo[sp]
		hi := stack_hi[sp]
		if hi - lo < FALLBACK_QSORT_SMALL_THRESH {
			bzip2_fallback_simple_sort(fmap, eclass, lo, hi)
			continue
		}

		r = ((r * 7621) + 1) % 32768
		med: u32
		switch r % 3 {
		case 0: med = eclass[fmap[lo]]
		case 1: med = eclass[fmap[(lo + hi) >> 1]]
		case:   med = eclass[fmap[hi]]
		}

		un_lo, lt_lo := lo, lo
		un_hi, gt_hi := hi, hi
		for {
			for un_lo <= un_hi {
				n := i64(eclass[fmap[un_lo]]) - i64(med)
				if n == 0 {
					fmap[un_lo], fmap[lt_lo] = fmap[lt_lo], fmap[un_lo]
					lt_lo += 1
					un_lo += 1
					continue
				}
				if n > 0 {
					break
				}
				un_lo += 1
			}
			for un_lo <= un_hi {
				n := i64(eclass[fmap[un_hi]]) - i64(med)
				if n == 0 {
					fmap[un_hi], fmap[gt_hi] = fmap[gt_hi], fmap[un_hi]
					gt_hi -= 1
					un_hi -= 1
					continue
				}
				if n < 0 {
					break
				}
				un_hi -= 1
			}
			if un_lo > un_hi {
				break
			}
			fmap[un_lo], fmap[un_hi] = fmap[un_hi], fmap[un_lo]
			un_lo += 1
			un_hi -= 1
		}

		if gt_hi < lt_lo {
			continue
		}

		n := min(lt_lo - lo, un_lo - lt_lo)
		bzip2_vswap(fmap, lo, un_lo - n, n)
		m := min(hi - gt_hi, gt_hi - un_hi)
		bzip2_vswap(fmap, un_lo, hi - m + 1, m)

		n = lo + un_lo - lt_lo - 1
		m = hi - (gt_hi - un_hi) + 1

		if n - lo > hi - m {
			stack_lo[sp], stack_hi[sp] = lo, n
			sp += 1
			stack_lo[sp], stack_hi[sp] = m, hi
			sp += 1
		} else {
			stack_lo[sp], stack_hi[sp] = m, hi
			sp += 1
			stack_lo[sp], stack_hi[sp] = lo, n
			sp += 1
		}
	}
}

@(private)
bzip2_vswap :: #force_inline proc "contextless" (p: []u32, p1, p2, n: int) {
	for i in 0..<n {
		p[p1 + i], p[p2 + i] = p[p2 + i], p[p1 + i]
	}
}

@(private)
bzip2_fallback_sort :: proc "contextless" (fmap, eclass, bhtab: []u32, block: []u8, nblock: int) {
	set_bh   :: #force_inline proc "contextless" (b: []u32, z: int) { b[z >> 5] |= u32(1) << uint(z & 31) }
	clear_bh :: #force_inline proc "contextless" (b: []u32, z: int) { b[z >> 5] &~= u32(1) << uint(z & 31) }
	isset_bh :: #force_inline proc "contextless" (b: []u32, z: int) -> bool { return b[z >> 5] & (u32(1) << uint(z & 31)) != 0 }

	ftab: [257]int
	for i in 0..<nblock {
		ftab[block[i]] += 1
	}
	for i in 1..<257 {
		ftab[i] += ftab[i - 1]
	}
	for i in 0..<nblock {
		j := int(block[i])
		k := ftab[j] - 1
		ftab[j] = k
		fmap[k] = u32(i)
	}

	n_bhtab := 2 + nblock / 32
	for i in 0..<n_bhtab {
		bhtab[i] = 0
	}
	for i in 0..<256 {
		set_bh(bhtab, ftab[i])
	}
	for i in 0..<32 {
		set_bh(bhtab, nblock + 2 * i)
		clear_bh(bhtab, nblock + 2 * i + 1)
	}

	h := 1
	for {
		j := 0
		for i in 0..<nblock {
			if isset_bh(bhtab, i) {
				j = i
			}
			k := int(fmap[i]) - h
			if k < 0 {
				k += nblock
			}
			eclass[k] = u32(j)
		}

		n_not_done := 0
		r := -1
		for {
			k := r + 1
			for isset_bh(bhtab, k) && k & 31 != 0 {
				k += 1
			}
			if isset_bh(bhtab, k) {
				for bhtab[k >> 5] == 0xffff_ffff {
					k += 32
				}
				for isset_bh(bhtab, k) {
					k += 1
				}
			}
			l := k - 1
			if l >= nblock {
				break
			}
			for !isset_bh(bhtab, k) && k & 31 != 0 {
				k += 1
			}
			if !isset_bh(bhtab, k) {
				for bhtab[k >> 5] == 0 {
					k += 32
				}
				for !isset_bh(bhtab, k) {
					k += 1
				}
			}
			r = k - 1
			if r >= nblock {
				break
			}
			if r > l {
				n_not_done += r - l + 1
				bzip2_fallback_qsort3(fmap, eclass, l, r)
				cc := i64(-1)
				for i in l..=r {
					cc1 := i64(eclass[fmap[i]])
					if cc != cc1 {
						set_bh(bhtab, i)
						cc = cc1
					}
				}
			}
		}

		h *= 2
		if h > nblock || n_not_done == 0 {
			break
		}
	}
}

@(private)
bzip2_main_gtu :: #force_inline proc "contextless" (i1, i2: int, block: []u8, quadrant: []u16, nblock: int, budget: ^int) -> bool #no_bounds_check {
	i1, i2 := i1, i2
	b := raw_data(block)
	q := raw_data(quadrant)

	x := intrinsics.unaligned_load((^u64le)(&b[i1])) ~ intrinsics.unaligned_load((^u64le)(&b[i2]))
	if x != 0 {
		n := int(intrinsics.count_trailing_zeros(x)) >> 3
		return b[i1 + n] > b[i2 + n]
	}
	y := intrinsics.unaligned_load((^u32le)(&b[i1 + 8])) ~ intrinsics.unaligned_load((^u32le)(&b[i2 + 8]))
	if y != 0 {
		n := 8 + int(intrinsics.count_trailing_zeros(y)) >> 3
		return b[i1 + n] > b[i2 + n]
	}
	i1 += 12
	i2 += 12

	k := nblock + 8
	for {
		bx := intrinsics.unaligned_load((^u64le)(&b[i1])) ~ intrinsics.unaligned_load((^u64le)(&b[i2]))
		q0 := intrinsics.unaligned_load((^u64le)(&q[i1]))     ~ intrinsics.unaligned_load((^u64le)(&q[i2]))
		q1 := intrinsics.unaligned_load((^u64le)(&q[i1 + 4])) ~ intrinsics.unaligned_load((^u64le)(&q[i2 + 4]))
		if bx | q0 | q1 != 0 {
			nb := int(intrinsics.count_trailing_zeros(bx)) >> 3
			nq := int(intrinsics.count_trailing_zeros(q0)) >> 4 if q0 != 0 else 4 + int(intrinsics.count_trailing_zeros(q1)) >> 4
			if nb <= nq {
				return b[i1 + nb] > b[i2 + nb]
			}
			return q[i1 + nq] > q[i2 + nq]
		}
		i1 += 8
		i2 += 8
		if i1 >= nblock {
			i1 -= nblock
		}
		if i2 >= nblock {
			i2 -= nblock
		}
		k -= 8
		budget^ -= 1
		if k < 0 {
			break
		}
	}
	return false
}

@(private, rodata)
BZIP2_INCS := [14]int{1, 4, 13, 40, 121, 364, 1093, 3280, 9841, 29524, 88573, 265720, 797161, 2391484}

@(private)
bzip2_main_simple_sort :: proc "contextless" (ptr: []u32, block: []u8, quadrant: []u16, nblock, lo, hi, d: int, budget: ^int) {
	big_n := hi - lo + 1
	if big_n < 2 {
		return
	}
	hp := 0
	for BZIP2_INCS[hp] < big_n {
		hp += 1
	}
	hp -= 1

	for ; hp >= 0; hp -= 1 {
		h := BZIP2_INCS[hp]
		i := lo + h
		outer: for {
			for _ in 0..<3 {
				if i > hi {
					break outer
				}
				v := ptr[i]
				j := i
				for bzip2_main_gtu(int(ptr[j - h]) + d, int(v) + d, block, quadrant, nblock, budget) {
					ptr[j] = ptr[j - h]
					j -= h
					if j <= lo + h - 1 {
						break
					}
				}
				ptr[j] = v
				i += 1
			}
			if budget^ < 0 {
				return
			}
		}
	}
}

@(private)
bzip2_mmed3 :: #force_inline proc "contextless" (a, b, c: u8) -> u8 {
	a, b := a, b
	if a > b {
		a, b = b, a
	}
	if b > c {
		b = c
		if a > b {
			b = a
		}
	}
	return b
}

@(private)
bzip2_main_qsort3 :: proc "contextless" (ptr: []u32, block: []u8, quadrant: []u16, nblock, lo_st, hi_st, d_st: int, budget: ^int) {
	MAIN_QSORT_SMALL_THRESH :: 20
	MAIN_QSORT_DEPTH_THRESH :: BZIP2_N_RADIX + BZIP2_N_QSORT
	MAIN_QSORT_STACK_SIZE   :: 100

	stack_lo: [MAIN_QSORT_STACK_SIZE]int = ---
	stack_hi: [MAIN_QSORT_STACK_SIZE]int = ---
	stack_d:  [MAIN_QSORT_STACK_SIZE]int = ---
	next_lo:  [3]int = ---
	next_hi:  [3]int = ---
	next_d:   [3]int = ---

	sp := 0
	stack_lo[sp], stack_hi[sp], stack_d[sp] = lo_st, hi_st, d_st
	sp += 1

	for sp > 0 {
		sp -= 1
		lo, hi, d := stack_lo[sp], stack_hi[sp], stack_d[sp]

		if hi - lo < MAIN_QSORT_SMALL_THRESH || d > MAIN_QSORT_DEPTH_THRESH {
			bzip2_main_simple_sort(ptr, block, quadrant, nblock, lo, hi, d, budget)
			if budget^ < 0 {
				return
			}
			continue
		}

		med := int(bzip2_mmed3(block[int(ptr[lo]) + d], block[int(ptr[hi]) + d], block[int(ptr[(lo + hi) >> 1]) + d]))

		un_lo, lt_lo := lo, lo
		un_hi, gt_hi := hi, hi
		for {
			for un_lo <= un_hi {
				n := int(block[int(ptr[un_lo]) + d]) - med
				if n == 0 {
					ptr[un_lo], ptr[lt_lo] = ptr[lt_lo], ptr[un_lo]
					lt_lo += 1
					un_lo += 1
					continue
				}
				if n > 0 {
					break
				}
				un_lo += 1
			}
			for un_lo <= un_hi {
				n := int(block[int(ptr[un_hi]) + d]) - med
				if n == 0 {
					ptr[un_hi], ptr[gt_hi] = ptr[gt_hi], ptr[un_hi]
					gt_hi -= 1
					un_hi -= 1
					continue
				}
				if n < 0 {
					break
				}
				un_hi -= 1
			}
			if un_lo > un_hi {
				break
			}
			ptr[un_lo], ptr[un_hi] = ptr[un_hi], ptr[un_lo]
			un_lo += 1
			un_hi -= 1
		}

		if gt_hi < lt_lo {
			stack_lo[sp], stack_hi[sp], stack_d[sp] = lo, hi, d + 1
			sp += 1
			continue
		}

		n := min(lt_lo - lo, un_lo - lt_lo)
		bzip2_vswap(ptr, lo, un_lo - n, n)
		m := min(hi - gt_hi, gt_hi - un_hi)
		bzip2_vswap(ptr, un_lo, hi - m + 1, m)

		n = lo + un_lo - lt_lo - 1
		m = hi - (gt_hi - un_hi) + 1

		next_lo[0], next_hi[0], next_d[0] = lo,    n,     d
		next_lo[1], next_hi[1], next_d[1] = m,     hi,    d
		next_lo[2], next_hi[2], next_d[2] = n + 1, m - 1, d + 1

		if next_hi[0] - next_lo[0] < next_hi[1] - next_lo[1] {
			next_lo[0], next_lo[1] = next_lo[1], next_lo[0]
			next_hi[0], next_hi[1] = next_hi[1], next_hi[0]
			next_d[0],  next_d[1]  = next_d[1],  next_d[0]
		}
		if next_hi[1] - next_lo[1] < next_hi[2] - next_lo[2] {
			next_lo[1], next_lo[2] = next_lo[2], next_lo[1]
			next_hi[1], next_hi[2] = next_hi[2], next_hi[1]
			next_d[1],  next_d[2]  = next_d[2],  next_d[1]
		}
		if next_hi[0] - next_lo[0] < next_hi[1] - next_lo[1] {
			next_lo[0], next_lo[1] = next_lo[1], next_lo[0]
			next_hi[0], next_hi[1] = next_hi[1], next_hi[0]
			next_d[0],  next_d[1]  = next_d[1],  next_d[0]
		}

		for i in 0..<3 {
			stack_lo[sp], stack_hi[sp], stack_d[sp] = next_lo[i], next_hi[i], next_d[i]
			sp += 1
		}
	}
}

@(private)
bzip2_main_sort :: proc "contextless" (ptr: []u32, block: []u8, quadrant: []u16, ftab: []u32, nblock: int, budget: ^int) {
	SETMASK   :: u32(1) << 21
	CLEARMASK :: ~SETMASK

	running_order: [256]int = ---
	big_done:      [256]bool = ---
	copy_start:    [256]int = ---
	copy_end:      [256]int = ---

	for i in 0..=65536 {
		ftab[i] = 0
	}
	j := int(block[0]) << 8
	for i := nblock - 1; i >= 0; i -= 1 {
		quadrant[i] = 0
		j = (j >> 8) | (int(block[i]) << 8)
		ftab[j] += 1
	}

	for i in 0..<BZIP2_N_OVERSHOOT {
		block[nblock + i]    = block[i]
		quadrant[nblock + i] = 0
	}

	for i in 1..=65536 {
		ftab[i] += ftab[i - 1]
	}

	s := u16(block[0]) << 8
	for i := nblock - 1; i >= 0; i -= 1 {
		s = (s >> 8) | (u16(block[i]) << 8)
		k := ftab[s] - 1
		ftab[s] = k
		ptr[k]  = u32(i)
	}

	big_freq :: #force_inline proc "contextless" (ftab: []u32, b: int) -> u32 {
		return ftab[(b + 1) << 8] - ftab[b << 8]
	}

	for i in 0..<256 {
		big_done[i]      = false
		running_order[i] = i
	}
	{
		h := 1
		for {
			h = 3 * h + 1
			if h > 256 {
				break
			}
		}
		for {
			h = h / 3
			for i in h..=255 {
				vv := running_order[i]
				jj := i
				for big_freq(ftab, running_order[jj - h]) > big_freq(ftab, vv) {
					running_order[jj] = running_order[jj - h]
					jj -= h
					if jj <= h - 1 {
						break
					}
				}
				running_order[jj] = vv
			}
			if h == 1 {
				break
			}
		}
	}

	for i in 0..=255 {
		ss := running_order[i]

		for jj in 0..=255 {
			if jj != ss {
				sb := (ss << 8) + jj
				if ftab[sb] & SETMASK == 0 {
					lo := int(ftab[sb] & CLEARMASK)
					hi := int(ftab[sb + 1] & CLEARMASK) - 1
					if hi > lo {
						bzip2_main_qsort3(ptr, block, quadrant, nblock, lo, hi, BZIP2_N_RADIX, budget)
						if budget^ < 0 {
							return
						}
					}
				}
				ftab[sb] |= SETMASK
			}
		}

		for jj in 0..=255 {
			copy_start[jj] = int(ftab[(jj << 8) + ss] & CLEARMASK)
			copy_end[jj]   = int(ftab[(jj << 8) + ss + 1] & CLEARMASK) - 1
		}
		for jj := int(ftab[ss << 8] & CLEARMASK); jj < copy_start[ss]; jj += 1 {
			k := int(ptr[jj]) - 1
			if k < 0 {
				k += nblock
			}
			c1 := block[k]
			if !big_done[c1] {
				ptr[copy_start[c1]] = u32(k)
				copy_start[c1] += 1
			}
		}
		for jj := int(ftab[(ss + 1) << 8] & CLEARMASK) - 1; jj > copy_end[ss]; jj -= 1 {
			k := int(ptr[jj]) - 1
			if k < 0 {
				k += nblock
			}
			c1 := block[k]
			if !big_done[c1] {
				ptr[copy_end[c1]] = u32(k)
				copy_end[c1] -= 1
			}
		}

		for jj in 0..=255 {
			ftab[(jj << 8) + ss] |= SETMASK
		}

		big_done[ss] = true
		if i < 255 {
			bb_start := int(ftab[ss << 8] & CLEARMASK)
			bb_size  := int(ftab[(ss + 1) << 8] & CLEARMASK) - bb_start
			shifts   := uint(0)
			for (bb_size >> shifts) > 65534 {
				shifts += 1
			}
			for jj := bb_size - 1; jj >= 0; jj -= 1 {
				a2update := int(ptr[bb_start + jj])
				q_val    := u16(jj >> shifts)
				quadrant[a2update] = q_val
				if a2update < BZIP2_N_OVERSHOOT {
					quadrant[a2update + nblock] = q_val
				}
			}
		}
	}
}

@(private)
bzip2_generate_mtf_values :: proc "contextless" (e: ^BZip2) {
	e.n_in_use = 0
	for i in 0..<256 {
		if e.in_use[i] {
			e.unseq_to_seq[i] = u8(e.n_in_use)
			e.n_in_use += 1
		}
	}

	eob := e.n_in_use + 1
	for i in 0..=eob {
		e.mtf_freq[i] = 0
	}

	yy: [256]u8 = ---
	for i in 0..<e.n_in_use {
		yy[i] = u8(i)
	}

	wr    := 0
	z_pend := 0
	flush_runs :: #force_inline proc "contextless" (e: ^BZip2, z_pend: int, wr: ^int) {
		z := z_pend - 1
		for {
			if z & 1 != 0 {
				bzip2_mtfv(e)[wr^] = BZIP2_RUNB
				e.mtf_freq[BZIP2_RUNB] += 1
			} else {
				bzip2_mtfv(e)[wr^] = BZIP2_RUNA
				e.mtf_freq[BZIP2_RUNA] += 1
			}
			wr^ += 1
			if z < 2 {
				break
			}
			z = (z - 2) / 2
		}
	}

	nblock := e.nblock
	for i in 0..<nblock {
		j := int(e.ptr[i]) - 1
		if j < 0 {
			j += nblock
		}
		ll_i := e.unseq_to_seq[e.block[j]]
		if yy[0] == ll_i {
			z_pend += 1
			continue
		}
		if z_pend > 0 {
			flush_runs(e, z_pend, &wr)
			z_pend = 0
		}
		rtmp := yy[1]
		yy[1] = yy[0]
		k := 1
		for ll_i != rtmp {
			k += 1
			rtmp2 := rtmp
			rtmp   = yy[k]
			yy[k]  = rtmp2
		}
		yy[0] = rtmp
		bzip2_mtfv(e)[wr] = u16(k + 1)
		wr += 1
		e.mtf_freq[k + 1] += 1
	}
	if z_pend > 0 {
		flush_runs(e, z_pend, &wr)
	}

	bzip2_mtfv(e)[wr] = u16(eob)
	wr += 1
	e.mtf_freq[eob] += 1
	e.n_mtf = wr
}

@(private)
bzip2_make_code_lengths :: proc "contextless" (lengths: []u8, freq: []i32, alpha_size, max_len: int) {
	heap:   [BZIP2_MAX_ALPHA_SIZE + 2]int = ---
	weight: [BZIP2_MAX_ALPHA_SIZE * 2]int = ---
	parent: [BZIP2_MAX_ALPHA_SIZE * 2]int = ---

	for i in 0..<alpha_size {
		weight[i + 1] = (1 if freq[i] == 0 else int(freq[i])) << 8
	}

	for {
		n_nodes := alpha_size
		n_heap  := 0
		heap[0]   = 0
		weight[0] = 0
		parent[0] = -2

		for i in 1..=alpha_size {
			parent[i] = -1
			n_heap += 1
			heap[n_heap] = i
			zz  := n_heap
			tmp := heap[zz]
			for weight[tmp] < weight[heap[zz >> 1]] {
				heap[zz] = heap[zz >> 1]
				zz >>= 1
			}
			heap[zz] = tmp
		}

		for n_heap > 1 {
			n1 := heap[1]
			heap[1] = heap[n_heap]
			n_heap -= 1
			bzip2_downheap(heap[:], weight[:], n_heap)
			n2 := heap[1]
			heap[1] = heap[n_heap]
			n_heap -= 1
			bzip2_downheap(heap[:], weight[:], n_heap)

			n_nodes += 1
			parent[n1] = n_nodes
			parent[n2] = n_nodes
			w1, w2 := weight[n1], weight[n2]
			weight[n_nodes] = ((w1 & ~int(0xff)) + (w2 & ~int(0xff))) | (1 + max(w1 & 0xff, w2 & 0xff))
			parent[n_nodes] = -1

			n_heap += 1
			heap[n_heap] = n_nodes
			zz  := n_heap
			tmp := heap[zz]
			for weight[tmp] < weight[heap[zz >> 1]] {
				heap[zz] = heap[zz >> 1]
				zz >>= 1
			}
			heap[zz] = tmp
		}

		too_long := false
		for i in 1..=alpha_size {
			j := 0
			k := i
			for parent[k] >= 0 {
				k = parent[k]
				j += 1
			}
			lengths[i - 1] = u8(j)
			if j > max_len {
				too_long = true
			}
		}
		if !too_long {
			break
		}

		for i in 1..=alpha_size {
			j := weight[i] >> 8
			j  = 1 + (j / 2)
			weight[i] = j << 8
		}
	}
}

@(private)
bzip2_downheap :: #force_inline proc "contextless" (heap, weight: []int, n_heap: int) {
	zz  := 1
	tmp := heap[zz]
	for {
		yy := zz << 1
		if yy > n_heap {
			break
		}
		if yy < n_heap && weight[heap[yy + 1]] < weight[heap[yy]] {
			yy += 1
		}
		if weight[tmp] < weight[heap[yy]] {
			break
		}
		heap[zz] = heap[yy]
		zz = yy
	}
	heap[zz] = tmp
}

@(private)
bzip2_send_mtf_values :: proc "contextless" (e: ^BZip2) {
	alpha_size := e.n_in_use + 2
	for t in 0..<BZIP2_MAX_GROUPS {
		for v in 0..<alpha_size {
			e.lengths[t][v] = BZIP2_GREATER_ICOST
		}
	}

	n_mtf := e.n_mtf
	n_groups: int
	switch {
	case n_mtf < 200:  n_groups = 2
	case n_mtf < 600:  n_groups = 3
	case n_mtf < 1200: n_groups = 4
	case n_mtf < 2400: n_groups = 5
	case:              n_groups = 6
	}

	{
		n_part := n_groups
		rem_f  := n_mtf
		gs     := 0
		for n_part > 0 {
			t_freq := rem_f / n_part
			ge     := gs - 1
			a_freq := 0
			for a_freq < t_freq && ge < alpha_size - 1 {
				ge += 1
				a_freq += int(e.mtf_freq[ge])
			}
			if ge > gs && n_part != n_groups && n_part != 1 && (n_groups - n_part) % 2 == 1 {
				a_freq -= int(e.mtf_freq[ge])
				ge -= 1
			}
			for v in 0..<alpha_size {
				e.lengths[n_part - 1][v] = BZIP2_LESSER_ICOST if v >= gs && v <= ge else BZIP2_GREATER_ICOST
			}
			n_part -= 1
			gs      = ge + 1
			rem_f  -= a_freq
		}
	}

	mtfv := bzip2_mtfv(e)
	n_selectors := 0
	cost: [BZIP2_MAX_GROUPS]u16 = ---
	for _ in 0..<BZIP2_N_ITERS {
		for t in 0..<n_groups {
			for v in 0..<alpha_size {
				e.rfreq[t][v] = 0
			}
		}
		if n_groups == 6 {
			for v in 0..<alpha_size {
				e.len_pack[v][0] = u32(e.lengths[1][v]) << 16 | u32(e.lengths[0][v])
				e.len_pack[v][1] = u32(e.lengths[3][v]) << 16 | u32(e.lengths[2][v])
				e.len_pack[v][2] = u32(e.lengths[5][v]) << 16 | u32(e.lengths[4][v])
			}
		}

		n_selectors = 0
		for gs := 0; gs < n_mtf; gs += BZIP2_GROUP_SIZE {
			ge := min(gs + BZIP2_GROUP_SIZE - 1, n_mtf - 1)

			if n_groups == 6 && ge - gs + 1 == BZIP2_GROUP_SIZE {
				cost01, cost23, cost45: u32
				for i in gs..=ge {
					icv := mtfv[i]
					cost01 += e.len_pack[icv][0]
					cost23 += e.len_pack[icv][1]
					cost45 += e.len_pack[icv][2]
				}
				cost[0] = u16(cost01 & 0xffff)
				cost[1] = u16(cost01 >> 16)
				cost[2] = u16(cost23 & 0xffff)
				cost[3] = u16(cost23 >> 16)
				cost[4] = u16(cost45 & 0xffff)
				cost[5] = u16(cost45 >> 16)
			} else {
				cost = {}
				for i in gs..=ge {
					icv := mtfv[i]
					for t in 0..<n_groups {
						cost[t] += u16(e.lengths[t][icv])
					}
				}
			}

			bc := 999999999
			bt := -1
			for t in 0..<n_groups {
				if int(cost[t]) < bc {
					bc = int(cost[t])
					bt = t
				}
			}
			e.selector[n_selectors] = u8(bt)
			n_selectors += 1

			for i in gs..=ge {
				e.rfreq[bt][mtfv[i]] += 1
			}
		}

		for t in 0..<n_groups {
			bzip2_make_code_lengths(e.lengths[t][:], e.rfreq[t][:], alpha_size, BZIP2_ENCODE_MAX_LEN)
		}
	}

	{
		pos: [BZIP2_MAX_GROUPS]u8 = ---
		for i in 0..<n_groups {
			pos[i] = u8(i)
		}
		for i in 0..<n_selectors {
			ll_i := e.selector[i]
			j    := 0
			tmp  := pos[j]
			for ll_i != tmp {
				j += 1
				tmp2 := tmp
				tmp    = pos[j]
				pos[j] = tmp2
			}
			pos[0] = tmp
			e.selector_mtf[i] = u8(j)
		}
	}

	for t in 0..<n_groups {
		min_len := 32
		max_len := 0
		for i in 0..<alpha_size {
			l := int(e.lengths[t][i])
			max_len = max(max_len, l)
			min_len = min(min_len, l)
		}
		vec := u32(0)
		for n in min_len..=max_len {
			for i in 0..<alpha_size {
				if int(e.lengths[t][i]) == n {
					e.codes[t][i] = vec
					vec += 1
				}
			}
			vec <<= 1
		}
	}

	{
		in_use16: [16]bool
		for i in 0..<16 {
			for j in 0..<16 {
				if e.in_use[i * 16 + j] {
					in_use16[i] = true
				}
			}
		}
		for i in 0..<16 {
			bzip2_put_bits(e, 1, 1 if in_use16[i] else 0)
		}
		for i in 0..<16 {
			if in_use16[i] {
				for j in 0..<16 {
					bzip2_put_bits(e, 1, 1 if e.in_use[i * 16 + j] else 0)
				}
			}
		}
	}

	bzip2_put_bits(e, 3, u32(n_groups))
	bzip2_put_bits(e, 15, u32(n_selectors))
	for i in 0..<n_selectors {
		for _ in 0..<e.selector_mtf[i] {
			bzip2_put_bits(e, 1, 1)
		}
		bzip2_put_bits(e, 1, 0)
	}

	for t in 0..<n_groups {
		curr := int(e.lengths[t][0])
		bzip2_put_bits(e, 5, u32(curr))
		for i in 0..<alpha_size {
			for curr < int(e.lengths[t][i]) {
				bzip2_put_bits(e, 2, 2)
				curr += 1
			}
			for curr > int(e.lengths[t][i]) {
				bzip2_put_bits(e, 2, 3)
				curr -= 1
			}
			bzip2_put_bits(e, 1, 0)
		}
	}

	sel_ctr := 0
	for gs := 0; gs < n_mtf; gs += BZIP2_GROUP_SIZE {
		ge := min(gs + BZIP2_GROUP_SIZE - 1, n_mtf - 1)
		sel := e.selector[sel_ctr]
		for i in gs..=ge {
			v := mtfv[i]
			bzip2_put_bits(e, uint(e.lengths[sel][v]), e.codes[sel][v])
		}
		sel_ctr += 1
	}
}
