package compress_ppmd

import "base:runtime"

// PPMd var.I rev.1 by Dmitry Shkarin, after 7-Zip's `C/Ppmd8.c`. `Properties.variant = .I`.
// Used by ZIP as method 98: its own carryless range coder, the 2-byte `wPPMd` header (order, memory
// size in MiB and restore method) and an end marker.
// When its memory runs out it restarts, cuts off or freezes the model, as the restore method says.

@(private)
i_init :: proc(p: ^Model_I, props: Properties, allocator: runtime.Allocator) -> (err: Error) {
	sub_allocator_init(&p.sub_alloc, props.mem_size, allocator) or_return
	ns2bs_init(&p.ns2bs_indx)
	for i in 0..<5 {
		p.ns2indx[i] = u8(i)
	}
	m, k := u32(5), u32(1)
	for i in 5..<260 {
		p.ns2indx[i] = u8(m)
		k -= 1
		if k == 0 {
			m += 1
			k = m - 4
		}
	}
	p.max_order      = u32(props.order)
	p.restore_method = u32(props.restore)
	i_restart_model(p)
	return nil
}

@(private)
i_ctx :: #force_inline proc "contextless" (p: ^Model_I, r: u32) -> ^Context_I {
	return (^Context_I)(ptr_at(&p.sub_alloc, r))
}

@(private)
i_stats :: #force_inline proc "contextless" (p: ^Model_I, c: ^Context_I) -> [^]State {
	return ([^]State)(ptr_at(&p.sub_alloc, c.stats))
}

@(private)
i_suffix :: #force_inline proc "contextless" (p: ^Model_I, c: ^Context_I) -> ^Context_I {
	return (^Context_I)(ptr_at(&p.sub_alloc, c.suffix))
}

@(private)
i_one_state :: #force_inline proc "contextless" (c: ^Context_I) -> ^State {
	return (^State)(uintptr(c) + 2)
}

@(private)
i_insert_node :: #force_inline proc "contextless" (p: ^Model_I, node: rawptr, indx: u32) #no_bounds_check {
	n := (^Node_I)(node)
	n.stamp = EMPTY_NODE_I
	n.next  = p.sub_alloc.free_list[indx]
	n.nu    = i2u(&p.sub_alloc, indx)
	p.sub_alloc.free_list[indx] = ref_of(&p.sub_alloc, node)
	p.stamps[indx] += 1
}

@(private)
i_remove_node :: #force_inline proc "contextless" (p: ^Model_I, indx: u32) -> rawptr #no_bounds_check {
	node := (^Node_I)(ptr_at(&p.sub_alloc, p.sub_alloc.free_list[indx]))
	p.sub_alloc.free_list[indx] = node.next
	p.stamps[indx] -= 1
	return node
}

@(private)
i_split_block :: proc "contextless" (p: ^Model_I, ptr: rawptr, old_indx, new_indx: u32) {
	nu    := i2u(&p.sub_alloc, old_indx) - i2u(&p.sub_alloc, new_indx)
	block := forward(ptr, u2b(i2u(&p.sub_alloc, new_indx)))
	i     := u2i(&p.sub_alloc, nu)
	if i2u(&p.sub_alloc, i) != nu {
		i -= 1
		k := i2u(&p.sub_alloc, i)
		i_insert_node(p, forward(block, u2b(k)), nu - k - 1)
	}
	i_insert_node(p, block, i)
}

@(private)
i_glue_free_blocks :: proc "contextless" (p: ^Model_I) #no_bounds_check {
	n: u32
	p.sub_alloc.glue_count = 1 << 13
	p.stamps     = {}
	if p.sub_alloc.lo_unit != p.sub_alloc.hi_unit {
		(^Node_I)(p.sub_alloc.lo_unit).stamp = 0
	}

	prev := &n
	for i in 0..<NUM_INDEXES {
		next := p.sub_alloc.free_list[i]
		p.sub_alloc.free_list[i] = 0
		for next != 0 {
			node := (^Node_I)(ptr_at(&p.sub_alloc, next))
			nu   := node.nu
			prev^ = next
			next = node.next
			if nu != 0 {
				prev = &node.next
				for {
					node2 := (^Node_I)(forward(node, u2b(nu)))
					if node2.stamp != EMPTY_NODE_I {
						break
					}
					nu += node2.nu
					node2.nu = 0
					node.nu  = nu
				}
			}
		}
	}
	prev^ = 0

	for n != 0 {
		node := (^Node_I)(ptr_at(&p.sub_alloc, n))
		nu   := node.nu
		n = node.next
		if nu == 0 {
			continue
		}
		for ; nu > 128; nu -= 128 {
			i_insert_node(p, node, NUM_INDEXES - 1)
			node = (^Node_I)(forward(node, u2b(128)))
		}
		i := u2i(&p.sub_alloc, nu)
		if i2u(&p.sub_alloc, i) != nu {
			i -= 1
			k := i2u(&p.sub_alloc, i)
			i_insert_node(p, forward(node, u2b(k)), nu - k - 1)
		}
		i_insert_node(p, node, i)
	}
}

@(private)
i_alloc_units_rare :: proc "contextless" (p: ^Model_I, indx: u32) -> rawptr #no_bounds_check {
	if p.sub_alloc.glue_count == 0 {
		i_glue_free_blocks(p)
		if p.sub_alloc.free_list[indx] != 0 {
			return i_remove_node(p, indx)
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
	block := i_remove_node(p, i)
	i_split_block(p, block, i, indx)
	return block
}

@(private)
i_alloc_units :: #force_inline proc "contextless" (p: ^Model_I, indx: u32) -> rawptr #no_bounds_check {
	if p.sub_alloc.free_list[indx] != 0 {
		return i_remove_node(p, indx)
	}
	num_bytes := u2b(i2u(&p.sub_alloc, indx))
	lo := p.sub_alloc.lo_unit
	if distance(p.sub_alloc.hi_unit, lo) >= num_bytes {
		p.sub_alloc.lo_unit = forward(lo, num_bytes)
		return lo
	}
	return i_alloc_units_rare(p, indx)
}

@(private)
i_shrink_units :: proc "contextless" (p: ^Model_I, old_ptr: rawptr, old_nu, new_nu: u32) -> rawptr {
	i0 := u2i(&p.sub_alloc, old_nu)
	i1 := u2i(&p.sub_alloc, new_nu)
	if i0 == i1 {
		return old_ptr
	}
	if p.sub_alloc.free_list[i1] != 0 {
		ptr := i_remove_node(p, i1)
		copy_units(ptr, old_ptr, new_nu)
		i_insert_node(p, old_ptr, i0)
		return ptr
	}
	i_split_block(p, old_ptr, i0, i1)
	return old_ptr
}

@(private)
i_free_units :: #force_inline proc "contextless" (p: ^Model_I, ptr: rawptr, nu: u32) {
	i_insert_node(p, ptr, u2i(&p.sub_alloc, nu))
}

@(private)
i_special_free_unit :: proc "contextless" (p: ^Model_I, ptr: rawptr) {
	if ptr != p.sub_alloc.units_start {
		i_insert_node(p, ptr, 0)
	} else {
		(^u32)(ptr)^ = EMPTY_NODE_I
		p.sub_alloc.units_start = forward(p.sub_alloc.units_start, UNIT_SIZE)
	}
}

@(private)
i_expand_text_area :: proc "contextless" (p: ^Model_I) #no_bounds_check {
	count: [NUM_INDEXES]u32
	if p.sub_alloc.lo_unit != p.sub_alloc.hi_unit {
		(^Node_I)(p.sub_alloc.lo_unit).stamp = 0
	}
	node := (^Node_I)(p.sub_alloc.units_start)
	for node.stamp == EMPTY_NODE_I {
		nu := node.nu
		node.stamp = 0
		count[u2i(&p.sub_alloc, nu)] += 1
		node = (^Node_I)(forward(node, u2b(nu)))
	}
	p.sub_alloc.units_start = ([^]u8)(node)

	for i in 0..<NUM_INDEXES {
		cnt := count[i]
		if cnt == 0 {
			continue
		}
		prev := &p.sub_alloc.free_list[i]
		n    := prev^
		p.stamps[i] -= cnt
		for {
			nd := (^Node_I)(ptr_at(&p.sub_alloc, n))
			n = nd.next
			if nd.stamp != 0 {
				prev = &nd.next
				continue
			}
			prev^ = n
			cnt -= 1
			if cnt == 0 {
				break
			}
		}
	}
}

@(private)
i_restart_model :: proc "contextless" (p: ^Model_I) #no_bounds_check {
	p.sub_alloc.free_list   = {}
	p.stamps      = {}
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
	mc := (^Context_I)(p.sub_alloc.hi_unit)
	s  := ([^]State)(p.sub_alloc.lo_unit)
	p.sub_alloc.lo_unit     = forward(p.sub_alloc.lo_unit, u2b(256 / 2))
	p.max_context = mc
	p.min_context = mc
	p.found_state = &s[0]

	mc.flags     = 0
	mc.num_stats = 256 - 1
	mc.summ_freq = 256 + 1
	mc.stats     = ref_of(&p.sub_alloc, s)
	mc.suffix    = 0
	for i in 0..<256 {
		s[i] = State{symbol = u8(i), freq = 1}
	}

	i := 0
	for m in 0..<25 {
		for int(p.ns2indx[i]) == m {
			i += 1
		}
		for k in 0..<8 {
			val := u16(BIN_SCALE - u32(INIT_BIN_ESC[k]) / u32(i + 1))
			for r := 0; r < 64; r += 8 {
				p.bin_summ[m][k + r] = val
			}
		}
	}
	i = 0
	for m in 0..<24 {
		for int(p.ns2indx[i + 3]) == m + 3 {
			i += 1
		}
		summ := u16((2 * i + 5) << (PERIOD_BITS - 4))
		for k in 0..<32 {
			p.see[m][k] = See{summ = summ, shift = PERIOD_BITS - 4, count = 7}
		}
	}
	p.dummy_see = See{summ = 0, shift = PERIOD_BITS, count = 64}
}

@(private)
i_refresh :: proc "contextless" (p: ^Model_I, ctx: ^Context_I, old_nu: u32, scale: u32) #no_bounds_check {
	i := u32(ctx.num_stats)
	s := ([^]State)(i_shrink_units(p, i_stats(p, ctx), old_nu, (i + 2) >> 1))
	ctx.stats = ref_of(&p.sub_alloc, s)

	sc    := scale | u32(u32(ctx.summ_freq) >= 1 << 15)
	flags := hi_bits_prepare(s[0].symbol)
	freq  := u32(s[0].freq)
	esc_freq := u32(ctx.summ_freq) - freq
	freq = (freq + sc) >> sc
	sum_freq := freq
	s[0].freq = u8(freq)

	k := 0
	for {
		k += 1
		freq = u32(s[k].freq)
		esc_freq -= freq
		freq = (freq + sc) >> sc
		sum_freq += freq
		s[k].freq = u8(freq)
		flags |= hi_bits_prepare(s[k].symbol)
		i -= 1
		if i == 0 {
			break
		}
	}
	ctx.summ_freq = u16(sum_freq + ((esc_freq + sc) >> sc))
	ctx.flags     = u8((u32(ctx.flags) & (FLAG_PREV_HIGH + FLAG_RESCALED * sc)) + ((flags >> (8 - 3)) & (1 << 3)))
}

@(private)
i_to_one_state :: #force_inline proc "contextless" (ctx: ^Context_I, s: ^State) {
	sym := s.symbol
	ctx.flags = u8((u32(ctx.flags) & FLAG_PREV_HIGH) + hi_bits_flag_3(sym))
	one := i_one_state(ctx)
	one.symbol      = sym
	one.freq        = u8((u32(s.freq) + 11) >> 3)
	one.successor_0 = s.successor_0
	one.successor_1 = s.successor_1
}

@(private)
i_cut_off :: proc "contextless" (p: ^Model_I, ctx: ^Context_I, order: u32) -> u32 #no_bounds_check {
	ns := int(ctx.num_stats)
	if ns == 0 {
		s := i_one_state(ctx)
		successor := get_successor(s)
		if uintptr(ptr_at(&p.sub_alloc, successor)) >= uintptr(p.sub_alloc.units_start) {
			if order < p.max_order {
				successor = i_cut_off(p, i_ctx(p, successor), order + 1)
			} else {
				successor = 0
			}
			set_successor(s, successor)
			if successor != 0 || order <= 9 {
				return ref_of(&p.sub_alloc, ctx)
			}
		}
		i_special_free_unit(p, ctx)
		return 0
	}

	nu    := (u32(ns) + 2) >> 1
	indx  := u2i(&p.sub_alloc, nu)
	stats := i_stats(p, ctx)
	if distance(stats, p.sub_alloc.units_start) <= 1 << 14 && ctx.stats <= p.sub_alloc.free_list[indx] {
		ptr := i_remove_node(p, indx)
		ctx.stats = ref_of(&p.sub_alloc, ptr)
		copy_units(ptr, stats, nu)
		if rawptr(stats) != p.sub_alloc.units_start {
			i_insert_node(p, stats, indx)
		} else {
			p.sub_alloc.units_start = forward(p.sub_alloc.units_start, u2b(i2u(&p.sub_alloc, indx)))
		}
		stats = ([^]State)(ptr)
	}

	for k := ns; k >= 0; k -= 1 {
		s := &stats[k]
		successor := get_successor(s)
		if uintptr(ptr_at(&p.sub_alloc, successor)) < uintptr(p.sub_alloc.units_start) {
			s2 := &stats[ns]
			ns -= 1
			if order != 0 {
				if s != s2 {
					s^ = s2^
				}
			} else {
				swap_states(s, s2)
				set_successor(s2, 0)
			}
		} else if order < p.max_order {
			set_successor(s, i_cut_off(p, i_ctx(p, successor), order + 1))
		} else {
			set_successor(s, 0)
		}
	}

	if ns != int(ctx.num_stats) && order != 0 {
		if ns < 0 {
			i_free_units(p, stats, nu)
			i_special_free_unit(p, ctx)
			return 0
		}
		ctx.num_stats = u8(ns)
		if ns == 0 {
			i_to_one_state(ctx, &stats[0])
			i_free_units(p, stats, nu)
		} else {
			i_refresh(p, ctx, nu, u32(u32(ctx.summ_freq) > 16 * u32(ns)))
		}
	}
	return ref_of(&p.sub_alloc, ctx)
}

@(private)
i_remove_bin_contexts :: proc "contextless" (p: ^Model_I, ctx: ^Context_I, order: u32) -> u32 #no_bounds_check {
	if ctx.num_stats == 0 {
		s := i_one_state(ctx)
		successor := get_successor(s)
		if uintptr(ptr_at(&p.sub_alloc, successor)) >= uintptr(p.sub_alloc.units_start) && order < p.max_order {
			successor = i_remove_bin_contexts(p, i_ctx(p, successor), order + 1)
		} else {
			successor = 0
		}
		set_successor(s, successor)
		suffix := i_suffix(p, ctx)
		if successor == 0 && (suffix.num_stats == 0 || suffix.flags == 0xFF) {
			i_free_units(p, ctx, 1)
			return 0
		}
	} else {
		for k := int(ctx.num_stats); k >= 0; k -= 1 {
			s := &i_stats(p, ctx)[k]
			successor := get_successor(s)
			if uintptr(ptr_at(&p.sub_alloc, successor)) >= uintptr(p.sub_alloc.units_start) && order < p.max_order {
				set_successor(s, i_remove_bin_contexts(p, i_ctx(p, successor), order + 1))
			} else {
				set_successor(s, 0)
			}
		}
	}
	return ref_of(&p.sub_alloc, ctx)
}

@(private)
i_used_memory :: proc "contextless" (p: ^Model_I) -> u32 #no_bounds_check {
	v: u32
	for i in 0..<u32(NUM_INDEXES) {
		v += p.stamps[i] * i2u(&p.sub_alloc, i)
	}
	return p.sub_alloc.size - distance(p.sub_alloc.hi_unit, p.sub_alloc.lo_unit) - distance(p.sub_alloc.units_start, p.sub_alloc.text) - u2b(v)
}

@(private)
i_restore_model :: proc "contextless" (p: ^Model_I, ctx_error: ^Context_I, f_successor: ^Context_I) {
	p.sub_alloc.text = forward(p.sub_alloc.base, p.sub_alloc.align_offset)

	c := p.max_context
	for ; c != ctx_error; c = i_suffix(p, c) {
		c.num_stats -= 1
		if c.num_stats == 0 {
			s := &i_stats(p, c)[0]
			i_to_one_state(c, s)
			i_special_free_unit(p, s)
		} else {
			i_refresh(p, c, (u32(c.num_stats) + 3) >> 1, 0)
		}
	}
	for ; c != p.min_context; c = i_suffix(p, c) {
		if c.num_stats == 0 {
			one := i_one_state(c)
			one.freq = u8((u32(one.freq) + 1) >> 1)
		} else {
			c.summ_freq += 4
			if u32(c.summ_freq) > 128 + 4 * u32(c.num_stats) {
				i_refresh(p, c, (u32(c.num_stats) + 2) >> 1, 1)
			}
		}
	}

	if p.restore_method > RESTORE_FREEZE {
		if f_successor == nil || uintptr(f_successor) < uintptr(p.sub_alloc.units_start) {
			i_restart_model(p)
		} else {
			p.max_context = f_successor
			p.sub_alloc.glue_count += u32(p.stamps[1] & 1 == 0)
		}
	} else if p.restore_method == RESTORE_FREEZE {
		for p.max_context.suffix != 0 {
			p.max_context = i_suffix(p, p.max_context)
		}
		i_remove_bin_contexts(p, p.max_context, 0)
		p.restore_method = RESTORE_FREEZE + 1
		p.sub_alloc.glue_count     = 0
		p.order_fall     = p.max_order
	} else if p.restore_method == u32(Restore_Method.Restart) || i_used_memory(p) < p.sub_alloc.size >> 1 {
		i_restart_model(p)
	} else {
		for p.max_context.suffix != 0 {
			p.max_context = i_suffix(p, p.max_context)
		}
		for {
			i_cut_off(p, p.max_context, 0)
			i_expand_text_area(p)
			if i_used_memory(p) <= 3 * (p.sub_alloc.size >> 2) {
				break
			}
		}
		p.sub_alloc.glue_count = 0
		p.order_fall = p.max_order
	}
	p.min_context = p.max_context
}

@(private)
i_create_successors :: proc "contextless" (p: ^Model_I, skip: bool, s1: ^State, c: ^Context_I) -> ^Context_I {
	c  := c
	s1 := s1
	up_branch := get_successor(p.found_state)
	ps: [I_ORDER_MAX + 2]^State
	num_ps := 0
	if !skip {
		ps[num_ps] = p.found_state
		num_ps += 1
	}

	for c.suffix != 0 {
		c = i_suffix(p, c)
		s: ^State
		if s1 != nil {
			s  = s1
			s1 = nil
		} else if c.num_stats != 0 {
			sym := p.found_state.symbol
			s = &i_stats(p, c)[0]
			for s.symbol != sym {
				s = state_at(s, 1)
			}
			if u32(s.freq) < MAX_FREQ - 9 {
				s.freq += 1
				c.summ_freq += 1
			}
		} else {
			temp := u32(i_suffix(p, c).num_stats == 0)
			s = i_one_state(c)
			s.freq = u8(u32(s.freq) + (temp & u32(s.freq < 24)))
		}
		successor := get_successor(s)
		if successor != up_branch {
			c = i_ctx(p, successor)
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
	flags := u8(hi_bits_flag_4(p.found_state.symbol) + hi_bits_flag_3(new_sym))
	new_freq: u8
	if c.num_stats == 0 {
		new_freq = i_one_state(c).freq
	} else {
		s := &i_stats(p, c)[0]
		for s.symbol != new_sym {
			s = state_at(s, 1)
		}
		cf := u32(s.freq) - 1
		s0 := u32(c.summ_freq) - u32(c.num_stats) - cf
		if 2 * cf <= s0 {
			new_freq = u8(1 + u32(5 * cf > s0))
		} else {
			new_freq = u8(1 + (cf + 2 * s0 - 3) / s0)
		}
	}

	for {
		c1: ^Context_I
		if p.sub_alloc.hi_unit != p.sub_alloc.lo_unit {
			p.sub_alloc.hi_unit = backward(p.sub_alloc.hi_unit, UNIT_SIZE)
			c1 = (^Context_I)(p.sub_alloc.hi_unit)
		} else if p.sub_alloc.free_list[0] != 0 {
			c1 = (^Context_I)(i_remove_node(p, 0))
		} else {
			c1 = (^Context_I)(i_alloc_units_rare(p, 0))
			if c1 == nil {
				return nil
			}
		}
		c1.flags     = flags
		c1.num_stats = 0
		one := i_one_state(c1)
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
i_reduce_order :: proc "contextless" (p: ^Model_I, s1: ^State, c: ^Context_I) -> ^Context_I {
	c  := c
	s1 := s1
	s: ^State
	c1        := c
	up_branch := ref_of(&p.sub_alloc, p.sub_alloc.text)
	ps: [I_ORDER_MAX + 2]^State
	ps[0] = p.found_state
	num_ps := 1

	set_successor(p.found_state, up_branch)
	p.order_fall += 1

	for {
		if s1 != nil {
			c  = i_suffix(p, c)
			s  = s1
			s1 = nil
		} else {
			if c.suffix == 0 {
				if p.restore_method > RESTORE_FREEZE {
					for num_ps > 0 {
						num_ps -= 1
						set_successor(ps[num_ps], ref_of(&p.sub_alloc, c))
					}
					p.sub_alloc.text       = forward(p.sub_alloc.base, p.sub_alloc.align_offset + 1)
					p.order_fall = 1
				}
				return c
			}
			c = i_suffix(p, c)
			if c.num_stats != 0 {
				sym := p.found_state.symbol
				s = &i_stats(p, c)[0]
				for s.symbol != sym {
					s = state_at(s, 1)
				}
				if u32(s.freq) < MAX_FREQ - 9 {
					s.freq += 2
					c.summ_freq += 2
				}
			} else {
				s = i_one_state(c)
				s.freq = u8(u32(s.freq) + u32(s.freq < 32))
			}
		}
		if get_successor(s) != 0 {
			break
		}
		ps[num_ps] = s
		num_ps += 1
		set_successor(s, up_branch)
		p.order_fall += 1
	}

	if p.restore_method > RESTORE_FREEZE {
		c = i_ctx(p, get_successor(s))
		for num_ps > 0 {
			num_ps -= 1
			set_successor(ps[num_ps], ref_of(&p.sub_alloc, c))
		}
		p.sub_alloc.text       = forward(p.sub_alloc.base, p.sub_alloc.align_offset + 1)
		p.order_fall = 1
		return c
	} else if get_successor(s) <= up_branch {
		s2 := p.found_state
		p.found_state = s
		successor := i_create_successors(p, false, nil, c)
		set_successor(s, 0 if successor == nil else ref_of(&p.sub_alloc, successor))
		p.found_state = s2
	}

	successor := get_successor(s)
	if p.order_fall == 1 && c1 == p.max_context {
		set_successor(p.found_state, successor)
		p.sub_alloc.text = backward(p.sub_alloc.text, 1)
	}
	if successor == 0 {
		return nil
	}
	return i_ctx(p, successor)
}

@(private)
i_update_model :: proc "contextless" (p: ^Model_I) #no_bounds_check {
	fs            := p.found_state
	min_successor := get_successor(fs)
	f_freq        := u32(fs.freq)
	f_symbol      := fs.symbol
	s: ^State

	if u32(fs.freq) < MAX_FREQ / 4 && p.min_context.suffix != 0 {
		c := i_suffix(p, p.min_context)
		if c.num_stats == 0 {
			s = i_one_state(c)
			if s.freq < 32 {
				s.freq += 1
			}
		} else {
			sym := fs.symbol
			s = &i_stats(p, c)[0]
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

	c := p.max_context
	if p.order_fall == 0 && min_successor != 0 {
		cs := i_create_successors(p, true, s, p.min_context)
		if cs == nil {
			set_successor(p.found_state, 0)
			i_restore_model(p, c, i_ctx(p, min_successor))
			return
		}
		set_successor(p.found_state, ref_of(&p.sub_alloc, cs))
		p.min_context = cs
		p.max_context = cs
		return
	}

	p.sub_alloc.text[0] = fs.symbol
	p.sub_alloc.text = forward(p.sub_alloc.text, 1)
	if uintptr(p.sub_alloc.text) >= uintptr(p.sub_alloc.units_start) {
		i_restore_model(p, c, i_ctx(p, min_successor))
		return
	}
	max_successor := ref_of(&p.sub_alloc, p.sub_alloc.text)

	if min_successor == 0 {
		cs := i_reduce_order(p, s, p.min_context)
		if cs == nil {
			i_restore_model(p, c, nil)
			return
		}
		min_successor = ref_of(&p.sub_alloc, cs)
	} else if uintptr(ptr_at(&p.sub_alloc, min_successor)) < uintptr(p.sub_alloc.units_start) {
		cs := i_create_successors(p, false, s, p.min_context)
		if cs == nil {
			i_restore_model(p, c, nil)
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
	} else if p.restore_method > RESTORE_FREEZE {
		max_successor = min_successor
		p.sub_alloc.text        = forward(p.sub_alloc.base, p.sub_alloc.align_offset)
		p.order_fall  = 0
	}

	flag := u8(hi_bits_flag_3(f_symbol))
	ns   := u32(p.min_context.num_stats)
	s0   := u32(p.min_context.summ_freq) - ns - f_freq

	for ; c != p.min_context; c = i_suffix(p, c) {
		ns1 := u32(c.num_stats)
		sum: u32
		if ns1 != 0 {
			if ns1 & 1 != 0 {
				old_nu := (ns1 + 1) >> 1
				i      := u2i(&p.sub_alloc, old_nu)
				if i != u2i(&p.sub_alloc, old_nu + 1) {
					ptr := i_alloc_units(p, i + 1)
					if ptr == nil {
						i_restore_model(p, c, i_ctx(p, min_successor))
						return
					}
					old_ptr := i_stats(p, c)
					copy_units(ptr, old_ptr, old_nu)
					i_insert_node(p, old_ptr, i)
					c.stats = ref_of(&p.sub_alloc, ptr)
				}
			}
			sum = u32(c.summ_freq)
			sum += u32(3 * ns1 + 1 < ns)
		} else {
			one_copy := (^State)(i_alloc_units(p, 0))
			if one_copy == nil {
				i_restore_model(p, c, i_ctx(p, min_successor))
				return
			}
			one  := i_one_state(c)
			freq := u32(one.freq)
			one_copy^ = one^
			c.stats = ref_of(&p.sub_alloc, one_copy)
			if freq < MAX_FREQ / 4 - 1 {
				freq <<= 1
			} else {
				freq = MAX_FREQ - 4
			}
			one_copy.freq = u8(freq)
			sum = freq + p.init_esc + u32(ns > 2)
		}

		st := &i_stats(p, c)[ns1 + 1]
		cf := 2 * (sum + 6) * f_freq
		sf := s0 + sum
		st.symbol   = f_symbol
		c.num_stats = u8(ns1 + 1)
		set_successor(st, max_successor)
		c.flags |= flag
		if cf < 6 * sf {
			cf = 1 + u32(cf > sf) + u32(cf >= 4 * sf)
			sum += 4
		} else {
			cf = 4 + u32(cf > 9 * sf) + u32(cf > 12 * sf) + u32(cf > 15 * sf)
			sum += cf
		}
		c.summ_freq = u16(sum)
		st.freq     = u8(cf)
	}
	p.max_context = i_ctx(p, min_successor)
	p.min_context = p.max_context
}

@(private)
i_rescale :: proc "contextless" (p: ^Model_I) #no_bounds_check {
	mc    := p.min_context
	stats := i_stats(p, mc)
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
	adder    := u32(p.order_fall != 0) | u32(p.restore_method > RESTORE_FREEZE)
	sum_freq = (sum_freq + 4 + adder) >> 1
	i := u32(mc.num_stats)
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
		mc.num_stats = u8(num_stats_new)
		n0 := (num_stats + 2) >> 1

		if num_stats_new == 0 {
			freq := (2 * u32(stats[0].freq) + esc_freq - 1) / esc_freq
			if freq > MAX_FREQ / 3 {
				freq = MAX_FREQ / 3
			}
			mc.flags = u8((u32(mc.flags) & FLAG_PREV_HIGH) + hi_bits_flag_3(stats[0].symbol))
			one := i_one_state(mc)
			one^ = stats[0]
			one.freq = u8(freq)
			p.found_state = one
			i_insert_node(p, stats, u2i(&p.sub_alloc, n0))
			return
		}

		n1 := (num_stats_new + 2) >> 1
		if n0 != n1 {
			mc.stats = ref_of(&p.sub_alloc, i_shrink_units(p, stats, n0, n1))
		}
	}
	mc.summ_freq  = u16(sum_freq + esc_freq - (esc_freq >> 1))
	mc.flags     |= FLAG_RESCALED
	p.found_state = &i_stats(p, mc)[0]
}

@(private)
i_make_esc_freq :: #force_inline proc "contextless" (p: ^Model_I, num_masked: u32) -> (see: ^See, esc_freq: u32) #no_bounds_check {
	mc        := p.min_context
	num_stats := u32(mc.num_stats)
	if num_stats == 0xFF {
		return &p.dummy_see, 1
	}
	idx := u32(u32(mc.summ_freq) > 11 * (num_stats + 1)) +
	       2 * u32(2 * num_stats < u32(i_suffix(p, mc).num_stats) + num_masked) +
	       u32(mc.flags)
	see = &p.see[u32(p.ns2indx[num_stats + 2]) - 3][idx]
	return see, see_escape(see)
}

@(private)
i_next_context :: #force_inline proc "contextless" (p: ^Model_I) {
	c := i_ctx(p, get_successor(p.found_state))
	if p.order_fall == 0 && uintptr(c) >= uintptr(p.sub_alloc.units_start) {
		p.max_context = c
		p.min_context = c
	} else {
		i_update_model(p)
	}
}

@(private)
i_update1 :: #force_inline proc "contextless" (p: ^Model_I) {
	s    := p.found_state
	freq := u32(s.freq) + 4
	p.min_context.summ_freq += 4
	s.freq = u8(freq)
	prev := state_at(s, -1)
	if freq > u32(prev.freq) {
		swap_states(s, prev)
		p.found_state = prev
		if freq > MAX_FREQ {
			i_rescale(p)
		}
	}
	i_next_context(p)
}

@(private)
i_update1_0 :: #force_inline proc "contextless" (p: ^Model_I) {
	s    := p.found_state
	mc   := p.min_context
	freq := u32(s.freq)
	summ := u32(mc.summ_freq)
	p.prev_success = u32(2 * freq >= summ)
	p.run_length  += i32(p.prev_success)
	mc.summ_freq = u16(summ + 4)
	freq += 4
	s.freq = u8(freq)
	if freq > MAX_FREQ {
		i_rescale(p)
	}
	i_next_context(p)
}

@(private)
i_update2 :: #force_inline proc "contextless" (p: ^Model_I) {
	s    := p.found_state
	freq := u32(s.freq) + 4
	p.run_length = p.init_rl
	p.min_context.summ_freq += 4
	s.freq = u8(freq)
	if freq > MAX_FREQ {
		i_rescale(p)
	}
	i_update_model(p)
}

@(private)
i_update_bin :: #force_inline proc "contextless" (p: ^Model_I, s: ^State) {
	freq := u32(s.freq)
	c    := i_ctx(p, get_successor(s))
	p.found_state  = s
	p.prev_success = 1
	p.run_length  += 1
	s.freq = u8(freq + u32(freq < 196))
	if p.order_fall == 0 && uintptr(c) >= uintptr(p.sub_alloc.units_start) {
		p.max_context = c
		p.min_context = c
	} else {
		i_update_model(p)
	}
}

@(private)
i_bin_summ :: #force_inline proc "contextless" (p: ^Model_I) -> ^u16 #no_bounds_check {
	mc  := p.min_context
	one := i_one_state(mc)
	col := p.prev_success +
	       (u32(p.run_length >> 26) & 0x20) +
	       u32(p.ns2bs_indx[i_suffix(p, mc).num_stats]) +
	       u32(mc.flags)
	return &p.bin_summ[p.ns2indx[u32(one.freq) - 1]][col]
}
