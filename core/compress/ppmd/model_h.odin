package compress_ppmd

import "base:runtime"

// PPMd var.H by Dmitry Shkarin, after the LZMA SDK's `Ppmd7.c`. `Properties.variant = .H`.
// Used by 7z as method `03 04 01`: 7z's range coder, 5 bytes of coder properties (order, then the
// memory size as a little-endian u32) and no end marker, so the decoder stops at the unpacked size.
// It has no restore method; the model restarts whenever its memory runs out.

@(private)
h_init :: proc(p: ^Model_H, props: Properties, allocator: runtime.Allocator) -> (err: Error) {
	sub_allocator_init(&p.sub_alloc, props.mem_size, allocator) or_return
	ns2bs_init(&p.ns2bs_indx)
	for i in 0..<3 {
		p.ns2indx[i] = u8(i)
	}
	m, k := u32(3), u32(1)
	for i in 3..<256 {
		p.ns2indx[i] = u8(m)
		k -= 1
		if k == 0 {
			m += 1
			k = m - 2
		}
	}
	p.max_order = u32(props.order)
	h_restart_model(p)
	return nil
}

@(private)
h_ctx :: #force_inline proc "contextless" (p: ^Model_H, r: u32) -> ^Context_H {
	return (^Context_H)(ptr_at(&p.sub_alloc, r))
}

@(private)
h_stats :: #force_inline proc "contextless" (p: ^Model_H, c: ^Context_H) -> [^]State {
	return ([^]State)(ptr_at(&p.sub_alloc, c.stats))
}

@(private)
h_suffix :: #force_inline proc "contextless" (p: ^Model_H, c: ^Context_H) -> ^Context_H {
	return (^Context_H)(ptr_at(&p.sub_alloc, c.suffix))
}

@(private)
h_one_state :: #force_inline proc "contextless" (c: ^Context_H) -> ^State {
	return (^State)(uintptr(c) + 2)
}

@(private)
h_insert_node :: #force_inline proc "contextless" (p: ^Model_H, node: rawptr, indx: u32) #no_bounds_check {
	(^u32)(node)^ = p.sub_alloc.free_list[indx]
	p.sub_alloc.free_list[indx] = ref_of(&p.sub_alloc, node)
}

@(private)
h_remove_node :: #force_inline proc "contextless" (p: ^Model_H, indx: u32) -> rawptr #no_bounds_check {
	node := (^u32)(ptr_at(&p.sub_alloc, p.sub_alloc.free_list[indx]))
	p.sub_alloc.free_list[indx] = node^
	return node
}

@(private)
h_split_block :: proc "contextless" (p: ^Model_H, ptr: rawptr, old_indx, new_indx: u32) {
	nu    := i2u(&p.sub_alloc, old_indx) - i2u(&p.sub_alloc, new_indx)
	block := forward(ptr, u2b(i2u(&p.sub_alloc, new_indx)))
	i     := u2i(&p.sub_alloc, nu)
	if i2u(&p.sub_alloc, i) != nu {
		i -= 1
		k := i2u(&p.sub_alloc, i)
		h_insert_node(p, forward(block, u2b(k)), nu - k - 1)
	}
	h_insert_node(p, block, i)
}

@(private)
h_glue_free_blocks :: proc "contextless" (p: ^Model_H) #no_bounds_check {
	n: u32
	p.sub_alloc.glue_count = 255
	if p.sub_alloc.lo_unit != p.sub_alloc.hi_unit {
		(^Node_H)(p.sub_alloc.lo_unit).stamp = 1
	}
	for i in 0..<u32(NUM_INDEXES) {
		nu   := u16(i2u(&p.sub_alloc, i))
		next := p.sub_alloc.free_list[i]
		p.sub_alloc.free_list[i] = 0
		for next != 0 {
			un  := (^Node_H)(ptr_at(&p.sub_alloc, next))
			tmp := next
			next = (^u32)(un)^
			un.stamp = EMPTY_NODE_H
			un.nu    = nu
			un.next  = n
			n = tmp
		}
	}

	head := n
	prev := &head
	for n != 0 {
		node := (^Node_H)(ptr_at(&p.sub_alloc, n))
		nu   := u32(node.nu)
		n = node.next
		if nu == 0 {
			prev^ = n
			continue
		}
		prev = &node.next
		for {
			node2 := (^Node_H)(forward(node, u2b(nu)))
			nu += u32(node2.nu)
			if node2.stamp != EMPTY_NODE_H || nu >= 0x10000 {
				break
			}
			node.nu  = u16(nu)
			node2.nu = 0
		}
	}

	for n = head; n != 0; {
		node := (^Node_H)(ptr_at(&p.sub_alloc, n))
		nu   := u32(node.nu)
		n = node.next
		if nu == 0 {
			continue
		}
		for ; nu > 128; nu -= 128 {
			h_insert_node(p, node, NUM_INDEXES - 1)
			node = (^Node_H)(forward(node, u2b(128)))
		}
		i := u2i(&p.sub_alloc, nu)
		if i2u(&p.sub_alloc, i) != nu {
			i -= 1
			k := i2u(&p.sub_alloc, i)
			h_insert_node(p, forward(node, u2b(k)), nu - k - 1)
		}
		h_insert_node(p, node, i)
	}
}

@(private)
h_alloc_units_rare :: proc "contextless" (p: ^Model_H, indx: u32) -> rawptr #no_bounds_check {
	if p.sub_alloc.glue_count == 0 {
		h_glue_free_blocks(p)
		if p.sub_alloc.free_list[indx] != 0 {
			return h_remove_node(p, indx)
		}
	}
	i := indx
	for {
		i += 1
		if i == NUM_INDEXES {
			num_bytes := u2b(i2u(&p.sub_alloc, indx))
			us := p.sub_alloc.units_start
			p.sub_alloc.glue_count -= 1
			if distance(us, p.sub_alloc.text) > num_bytes {
				p.sub_alloc.units_start = backward(us, num_bytes)
				return p.sub_alloc.units_start
			}
			return nil
		}
		if p.sub_alloc.free_list[i] != 0 {
			break
		}
	}
	block := h_remove_node(p, i)
	h_split_block(p, block, i, indx)
	return block
}

@(private)
h_alloc_units :: #force_inline proc "contextless" (p: ^Model_H, indx: u32) -> rawptr #no_bounds_check {
	if p.sub_alloc.free_list[indx] != 0 {
		return h_remove_node(p, indx)
	}
	num_bytes := u2b(i2u(&p.sub_alloc, indx))
	lo := p.sub_alloc.lo_unit
	if distance(p.sub_alloc.hi_unit, lo) >= num_bytes {
		p.sub_alloc.lo_unit = forward(lo, num_bytes)
		return lo
	}
	return h_alloc_units_rare(p, indx)
}

@(private)
h_restart_model :: proc "contextless" (p: ^Model_H) #no_bounds_check {
	p.sub_alloc.free_list   = {}
	p.sub_alloc.text        = forward(p.sub_alloc.base, p.sub_alloc.align_offset)
	p.sub_alloc.hi_unit     = forward(p.sub_alloc.text, p.sub_alloc.size)
	p.sub_alloc.lo_unit     = backward(p.sub_alloc.hi_unit, p.sub_alloc.size / 8 / UNIT_SIZE * 7 * UNIT_SIZE)
	p.sub_alloc.units_start = p.sub_alloc.lo_unit
	p.sub_alloc.glue_count  = 0

	p.order_fall   = p.max_order
	p.init_rl      = -i32(min(p.max_order, 12)) - 1
	p.run_length   = p.init_rl
	p.prev_success = 0

	p.sub_alloc.hi_unit = backward(p.sub_alloc.hi_unit, UNIT_SIZE)
	mc := (^Context_H)(p.sub_alloc.hi_unit)
	s  := ([^]State)(p.sub_alloc.lo_unit)
	p.sub_alloc.lo_unit     = forward(p.sub_alloc.lo_unit, u2b(256 / 2))
	p.max_context = mc
	p.min_context = mc
	p.found_state = &s[0]

	mc.num_stats = 256
	mc.summ_freq = 256 + 1
	mc.stats     = ref_of(&p.sub_alloc, s)
	mc.suffix    = 0
	for i in 0..<256 {
		s[i] = State{symbol = u8(i), freq = 1}
	}

	for i in 0..<128 {
		for k in 0..<8 {
			val := u16(BIN_SCALE - u32(INIT_BIN_ESC[k]) / u32(i + 2))
			for m := 0; m < 64; m += 8 {
				p.bin_summ[i][k + m] = val
			}
		}
	}
	for i in 0..<25 {
		summ := u16((5 * i + 10) << (PERIOD_BITS - 4))
		for k in 0..<16 {
			p.see[i][k] = See{summ = summ, shift = PERIOD_BITS - 4, count = 4}
		}
	}
	p.dummy_see = See{summ = 0, shift = PERIOD_BITS, count = 64}
}

@(private)
h_create_successors :: proc "contextless" (p: ^Model_H) -> ^Context_H {
	c         := p.min_context
	up_branch := get_successor(p.found_state)
	ps: [H_ORDER_MAX + 1]^State
	num_ps := 0
	if p.order_fall != 0 {
		ps[num_ps] = p.found_state
		num_ps += 1
	}

	for c.suffix != 0 {
		c = h_suffix(p, c)
		s: ^State
		if c.num_stats != 1 {
			sym := p.found_state.symbol
			s = &h_stats(p, c)[0]
			for s.symbol != sym {
				s = state_at(s, 1)
			}
		} else {
			s = h_one_state(c)
		}
		successor := get_successor(s)
		if successor != up_branch {
			c = h_ctx(p, successor)
			if num_ps == 0 {
				return c
			}
			break
		}
		ps[num_ps] = s
		num_ps += 1
	}

	new_sym := p.sub_alloc.base[up_branch]
	up_branch += 1
	new_freq: u8
	if c.num_stats == 1 {
		new_freq = h_one_state(c).freq
	} else {
		s := &h_stats(p, c)[0]
		for s.symbol != new_sym {
			s = state_at(s, 1)
		}
		cf := u32(s.freq) - 1
		s0 := u32(c.summ_freq) - u32(c.num_stats) - cf
		if 2 * cf <= s0 {
			new_freq = u8(1 + u32(5 * cf > s0))
		} else {
			new_freq = u8(1 + (2 * cf + s0 - 1) / (2 * s0) + 1)
		}
	}

	for {
		c1: ^Context_H
		if p.sub_alloc.hi_unit != p.sub_alloc.lo_unit {
			p.sub_alloc.hi_unit = backward(p.sub_alloc.hi_unit, UNIT_SIZE)
			c1 = (^Context_H)(p.sub_alloc.hi_unit)
		} else if p.sub_alloc.free_list[0] != 0 {
			c1 = (^Context_H)(h_remove_node(p, 0))
		} else {
			c1 = (^Context_H)(h_alloc_units_rare(p, 0))
			if c1 == nil {
				return nil
			}
		}
		c1.num_stats = 1
		one := h_one_state(c1)
		one.symbol = new_sym
		one.freq   = new_freq
		set_successor(one, up_branch)
		c1.suffix = ref_of(&p.sub_alloc, c)
		num_ps -= 1
		set_successor(ps[num_ps], ref_of(&p.sub_alloc, c1))
		c = c1
		if num_ps == 0 {
			break
		}
	}
	return c
}

@(private)
h_update_model :: proc "contextless" (p: ^Model_H) #no_bounds_check {
	fs := p.found_state
	if u32(fs.freq) < MAX_FREQ / 4 && p.min_context.suffix != 0 {
		c := h_suffix(p, p.min_context)
		if c.num_stats == 1 {
			s := h_one_state(c)
			if s.freq < 32 {
				s.freq += 1
			}
		} else {
			s   := &h_stats(p, c)[0]
			sym := fs.symbol
			if s.symbol != sym {
				for {
					s = state_at(s, 1)
					if s.symbol == sym {
						break
					}
				}
				prev := state_at(s, -1)
				if s.freq >= prev.freq {
					swap_states(s, prev)
					s = prev
				}
			}
			if u32(s.freq) < MAX_FREQ - 9 {
				s.freq += 2
				c.summ_freq += 2
			}
		}
	}

	if p.order_fall == 0 {
		mc := h_create_successors(p)
		p.max_context = mc
		p.min_context = mc
		if mc == nil {
			h_restart_model(p)
			return
		}
		set_successor(p.found_state, ref_of(&p.sub_alloc, mc))
		return
	}

	p.sub_alloc.text[0] = fs.symbol
	p.sub_alloc.text = forward(p.sub_alloc.text, 1)
	if uintptr(p.sub_alloc.text) >= uintptr(p.sub_alloc.units_start) {
		h_restart_model(p)
		return
	}
	max_successor := ref_of(&p.sub_alloc, p.sub_alloc.text)
	min_successor := get_successor(fs)

	if min_successor != 0 {
		if min_successor <= max_successor {
			cs := h_create_successors(p)
			if cs == nil {
				h_restart_model(p)
				return
			}
			min_successor = ref_of(&p.sub_alloc, cs)
		}
		p.order_fall -= 1
		if p.order_fall == 0 {
			max_successor = min_successor
			if p.max_context != p.min_context {
				p.sub_alloc.text = backward(p.sub_alloc.text, 1)
			}
		}
	} else {
		set_successor(fs, max_successor)
		min_successor = ref_of(&p.sub_alloc, p.min_context)
	}

	mc := p.min_context
	c  := p.max_context
	p.max_context = h_ctx(p, min_successor)
	p.min_context = p.max_context
	if c == mc {
		return
	}

	ns := u32(mc.num_stats)
	s0 := u32(mc.summ_freq) - ns - (u32(fs.freq) - 1)
	for {
		ns1 := u32(c.num_stats)
		sum: u32
		if ns1 != 1 {
			if ns1 & 1 == 0 {
				old_nu := ns1 >> 1
				i      := u2i(&p.sub_alloc, old_nu)
				if i != u2i(&p.sub_alloc, old_nu + 1) {
					ptr := h_alloc_units(p, i + 1)
					if ptr == nil {
						h_restart_model(p)
						return
					}
					old_ptr := h_stats(p, c)
					copy_units(ptr, old_ptr, old_nu)
					h_insert_node(p, old_ptr, i)
					c.stats = ref_of(&p.sub_alloc, ptr)
				}
			}
			sum = u32(c.summ_freq)
			sum += u32(2 * ns1 < ns) + 2 * (u32(4 * ns1 <= ns) & u32(sum <= 8 * ns1))
		} else {
			s := (^State)(h_alloc_units(p, 0))
			if s == nil {
				h_restart_model(p)
				return
			}
			one  := h_one_state(c)
			freq := u32(one.freq)
			s^ = one^
			c.stats = ref_of(&p.sub_alloc, s)
			if freq < MAX_FREQ / 4 - 1 {
				freq <<= 1
			} else {
				freq = MAX_FREQ - 4
			}
			s.freq = u8(freq)
			sum = freq + p.init_esc + u32(ns > 3)
		}

		s  := &h_stats(p, c)[ns1]
		cf := 2 * (sum + 6) * u32(fs.freq)
		sf := s0 + sum
		s.symbol    = fs.symbol
		c.num_stats = u16(ns1 + 1)
		set_successor(s, max_successor)
		if cf < 6 * sf {
			cf = 1 + u32(cf > sf) + u32(cf >= 4 * sf)
			sum += 3
		} else {
			cf = 4 + u32(cf >= 9 * sf) + u32(cf >= 12 * sf) + u32(cf >= 15 * sf)
			sum += cf
		}
		c.summ_freq = u16(sum)
		s.freq      = u8(cf)

		c = h_suffix(p, c)
		if c == mc {
			break
		}
	}
}

@(private)
h_rescale :: proc "contextless" (p: ^Model_H) #no_bounds_check {
	mc    := p.min_context
	stats := h_stats(p, mc)
	si    := state_index(p.found_state, &stats[0])
	if si != 0 {
		tmp := stats[si]
		for ; si != 0; si -= 1 {
			stats[si] = stats[si - 1]
		}
		stats[0] = tmp
	}

	sum_freq := u32(stats[0].freq)
	esc_freq := u32(mc.summ_freq) - sum_freq
	adder    := u32(p.order_fall != 0)
	sum_freq = (sum_freq + 4 + adder) >> 1
	i := u32(mc.num_stats) - 1
	stats[0].freq = u8(sum_freq)

	k := 0
	for {
		k += 1
		freq := u32(stats[k].freq)
		esc_freq -= freq
		freq = (freq + adder) >> 1
		sum_freq += freq
		stats[k].freq = u8(freq)
		if freq > u32(stats[k - 1].freq) {
			tmp := stats[k]
			j   := k
			for {
				stats[j] = stats[j - 1]
				j -= 1
				if j == 0 || freq <= u32(stats[j - 1].freq) {
					break
				}
			}
			stats[j] = tmp
		}
		i -= 1
		if i == 0 {
			break
		}
	}

	if stats[k].freq == 0 {
		i = 0
		for {
			i += 1
			k -= 1
			if stats[k].freq != 0 {
				break
			}
		}
		esc_freq += i
		num_stats     := u32(mc.num_stats)
		num_stats_new := num_stats - i
		mc.num_stats = u16(num_stats_new)
		n0 := (num_stats + 1) >> 1

		if num_stats_new == 1 {
			freq := u32(stats[0].freq)
			for {
				esc_freq >>= 1
				freq = (freq + 1) >> 1
				if esc_freq <= 1 {
					break
				}
			}
			one := h_one_state(mc)
			one^ = stats[0]
			one.freq = u8(freq)
			p.found_state = one
			h_insert_node(p, stats, u2i(&p.sub_alloc, n0))
			return
		}

		n1 := (num_stats_new + 1) >> 1
		if n0 != n1 {
			i0 := u2i(&p.sub_alloc, n0)
			i1 := u2i(&p.sub_alloc, n1)
			if i0 != i1 {
				if p.sub_alloc.free_list[i1] != 0 {
					ptr := h_remove_node(p, i1)
					mc.stats = ref_of(&p.sub_alloc, ptr)
					copy_units(ptr, stats, n1)
					h_insert_node(p, stats, i0)
				} else {
					h_split_block(p, stats, i0, i1)
				}
			}
		}
	}
	mc.summ_freq  = u16(sum_freq + esc_freq - (esc_freq >> 1))
	p.found_state = &h_stats(p, mc)[0]
}

@(private)
h_make_esc_freq :: #force_inline proc "contextless" (p: ^Model_H, num_masked: u32) -> (see: ^See, esc_freq: u32) #no_bounds_check {
	mc        := p.min_context
	num_stats := u32(mc.num_stats)
	if num_stats == 256 {
		return &p.dummy_see, 1
	}
	non_masked := num_stats - num_masked
	idx := u32(non_masked < u32(h_suffix(p, mc).num_stats) - num_stats) +
	       2 * u32(u32(mc.summ_freq) < 11 * num_stats) +
	       4 * u32(num_masked > non_masked) +
	       p.hi_bits_flag
	see = &p.see[p.ns2indx[non_masked - 1]][idx]
	return see, see_escape(see)
}

@(private)
h_next_context :: #force_inline proc "contextless" (p: ^Model_H) {
	c := h_ctx(p, get_successor(p.found_state))
	if p.order_fall == 0 && uintptr(c) > uintptr(p.sub_alloc.text) {
		p.max_context = c
		p.min_context = c
	} else {
		h_update_model(p)
	}
}

@(private)
h_update1 :: #force_inline proc "contextless" (p: ^Model_H) {
	s    := p.found_state
	freq := u32(s.freq) + 4
	p.min_context.summ_freq += 4
	s.freq = u8(freq)
	prev := state_at(s, -1)
	if freq > u32(prev.freq) {
		swap_states(s, prev)
		p.found_state = prev
		if freq > MAX_FREQ {
			h_rescale(p)
		}
	}
	h_next_context(p)
}

@(private)
h_update1_0 :: #force_inline proc "contextless" (p: ^Model_H) {
	s    := p.found_state
	mc   := p.min_context
	freq := u32(s.freq)
	summ := u32(mc.summ_freq)
	p.prev_success = u32(2 * freq > summ)
	p.run_length  += i32(p.prev_success)
	mc.summ_freq = u16(summ + 4)
	freq += 4
	s.freq = u8(freq)
	if freq > MAX_FREQ {
		h_rescale(p)
	}
	h_next_context(p)
}

@(private)
h_update2 :: #force_inline proc "contextless" (p: ^Model_H) {
	s    := p.found_state
	freq := u32(s.freq) + 4
	p.run_length = p.init_rl
	p.min_context.summ_freq += 4
	s.freq = u8(freq)
	if freq > MAX_FREQ {
		h_rescale(p)
	}
	h_update_model(p)
}

@(private)
h_update_bin :: #force_inline proc "contextless" (p: ^Model_H, s: ^State) {
	freq := u32(s.freq)
	c    := h_ctx(p, get_successor(s))
	p.found_state  = s
	p.prev_success = 1
	p.run_length  += 1
	s.freq = u8(freq + u32(freq < 128))
	if p.order_fall == 0 && uintptr(c) > uintptr(p.sub_alloc.text) {
		p.max_context = c
		p.min_context = c
	} else {
		h_update_model(p)
	}
}

@(private)
h_bin_summ :: #force_inline proc "contextless" (p: ^Model_H) -> ^u16 #no_bounds_check {
	mc  := p.min_context
	one := h_one_state(mc)
	p.hi_bits_flag = hi_bits_flag_3(p.found_state.symbol)
	col := p.prev_success +
	       (u32(p.run_length >> 26) & 0x20) +
	       u32(p.ns2bs_indx[u32(h_suffix(p, mc).num_stats) - 1]) +
	       hi_bits_flag_4(one.symbol) +
	       p.hi_bits_flag
	return &p.bin_summ[u32(one.freq) - 1][col]
}

@(private)
h_mask_all :: #force_inline proc "contextless" (char_mask: ^[256]u8, stats: [^]State, n: u32) #no_bounds_check {
	for i in 0..<n {
		char_mask[stats[i].symbol] = 0
	}
}

