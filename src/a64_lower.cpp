// Lowering: xb IR -> arm64 machine code.
//
// Registers come from a linear scan over intervals in the block order. A vreg that lives inside
// one block has an interval from its definition to its last use. The other vregs and the scalar
// locals whose address is never taken get one interval that covers every point where a
// liveness analysis finds them live; a local that is a debug variable keeps its register in all
// of its scope. An interval takes x0-x8, v0-v7 or v20-v31 when no call happens in it, x19-x28 or
// d8-d15 otherwise; a parameter stays in the register it arrives in or moves to a callee saved
// one. When none is free, the interval takes the register of an active one that costs less in
// memory for each position it covers, references weighted by the loops around them. The rest
// live in 8 byte stack slots. A constant with one definition is materialized at each use, or
// becomes the instruction's immediate; a frame address is computed at each use, or becomes the
// access's offset. A compare whose only use is the next branch, select or test against zero
// only sets the flags.
//
// The scratch registers are x9-x15, x16 for addresses and x17 for large offsets, and
// v16-v19 for floats.
//
// Frame (macOS requires the frame pointer):
//   [x29+16 ...]  incoming stack arguments
//   [x29+8]       saved x30
//   [x29]         saved x29
//   [x29-N ...]   callee saved pairs, where compact unwind expects them: x19 at x29-8
//   [...]         vreg slots, nearest the frame pointer where offsets are short, then locals
//   [sp ...]      outgoing stack arguments

enum : u8 {
	A64_T0 = X9,
	A64_T1 = X10,
	A64_T2 = X11,
	A64_T3 = X12,
	A64_T4 = X13,
	A64_T5 = X14,
	A64_TB = X15, // assembles odd sized loads and stores
	A64_TA = X16, // memory addresses and indirect call targets

	A64_F0 = 16,
	A64_F1 = 17,
};

// Copies and zeroing up to these sizes are inline, larger ones call the C library.
enum : i64 {
	A64_INLINE_COPY = 64,
	A64_INLINE_ZERO = 256,
};

// a64Lower::reg holds x registers as themselves and v registers as A64_VREG + n
enum : i8 {
	A64_NOREG = -1,
	A64_VREG  = 32,
};

enum : u32 { A64_LOCAL_ITEM = 0x80000000u };

struct a64Lower {
	xbProc *    p;
	xbAsm       a;
	Array<i32>  slot;     // vreg -> x29 offset (negative)
	Array<i32>  uses;     // vreg -> number of reads
	Array<i8>   reg;      // vreg -> the register holding it for its whole life, or A64_NOREG
	Array<u8>   is_const; // vreg -> defined once by an IConst, materialized at its uses
	Array<i64>  cval;
	Array<u8>   in_block; // vreg -> defined once, and only read later in the same block
	Array<u8>   clean;    // vreg -> its register holds 0 or 1
	Array<i8>   local_reg;
	Array<i32>  via;      // vreg -> the local whose register it shares, or -1
	Array<u8>   remat;    // vreg -> defined once as a frame address, computed at each use from rmem
	Array<xbMem> rmem;
	u32         pairs;    // the saved callee saved pairs, as compact unwind flags
	i32         frame_size;
	i32         max_call_stack;
	bool        sp_moves;  // an alloca moves sp, so only x29 reaches the frame
	struct Fixup { i64 at; i32 block; bool imm19; };
	Array<Fixup> fixups;
	i64         proc_start;
	i32         next_block;
	bool        far;      // conditional branches skip over a `b`, the procedure is too long for theirs
	bool        fuse;     // the current compare only sets the flags for the next instruction
	u32         flags_vreg;
	a64Cond     flags_cond;
	// what the previous instruction stored, still in a register for a load right after it
	struct Stored { bool valid; bool fp; u8 reg; i32 size; xbMem mem; bool fresh; };
	Stored stored;
};

struct a64Addr {
	u8  base;
	i64 off;
};

// The x86 operations, which have no arm64 form; the procedure goes to LLVM. On arm64,
// xbOp_Vec128 is one of a64_vec_intrinsics.
gb_internal void a64_check_proc(xbProc *p) {
	for (xbBlock *b : p->order) {
		for (xbInstr const &in : b->instrs) {
			switch (in.op) {
			case xbOp_Cpuid:
			case xbOp_Xgetbv:
			case xbOp_Valgrind:
				XB_UNSUPPORTED(p, "arm64 operation");
				break;
			}
		}
	}
}

// Whether the lowering of `in` calls something or writes x0-x8, which a vreg in those
// registers or in v0-v7/v20-v31 cannot live through.
gb_internal bool a64_clobbers(xbInstr const &in) {
	switch (in.op) {
	case xbOp_Call:
	case xbOp_Ret:
	case xbOp_Syscall:
	case xbOp_TlsAddr:
	case xbOp_MemCopyDyn:
	case xbOp_MemMoveDyn:
	case xbOp_MemSetDyn:
		return true;
	case xbOp_MemCopy:
	case xbOp_MemMove:
		return in.imm > A64_INLINE_COPY;
	case xbOp_MemZero:
		return in.imm > A64_INLINE_ZERO;
	}
	return false;
}

// Calls f(lo, hi, fp, offset) for each saved pair: lo at x29+offset+8, hi at x29+offset.
template <typename F>
gb_internal void a64_for_each_pair(u32 pairs, F const &f) {
	i32 off = 0;
	for (u32 k = 0; k < 5; k++) {
		if (pairs & (1u << k)) {
			off -= 16;
			f(cast(u8)(X19 + 2*k), cast(u8)(X20 + 2*k), false, off);
		}
	}
	for (u32 k = 0; k < 4; k++) {
		if (pairs & (0x100u << k)) {
			off -= 16;
			f(cast(u8)(8 + 2*k), cast(u8)(9 + 2*k), true, off);
		}
	}
}

gb_internal void a64_lower_layout(a64Lower *L) {
	xbProc *p = L->p;
	isize vreg_count = p->vregs.count;

	// Promotable scalar locals get live intervals like the vregs, a parameter's starting in the
	// register it arrives in
	L->local_reg = array_make<i8>(heap_allocator(), p->locals.count);
	for (isize i = 0; i < p->locals.count; i++) L->local_reg[i] = A64_NOREG;
	Array<i32> ranked = {};
	xb_rank_promotable_locals(p, 16, 1, 0, &ranked, true, true);
	defer (array_free(&ranked));
	auto arrive = array_make<i8>(heap_allocator(), p->locals.count); // a parameter's register
	defer (array_free(&arrive));
	for (isize i = 0; i < p->locals.count; i++) arrive[i] = A64_NOREG;
	auto is_param = array_make<bool>(heap_allocator(), p->locals.count);
	defer (array_free(&is_param));
	for (xbParamIn const &in : p->params_in) {
		if (in.dst.kind != xbMem_Local) continue;
		is_param[in.dst.base] = true;
		if (in.loc == xbLoc_Gpr) arrive[in.dst.base] = cast(i8)in.reg;
	}

	auto block = array_make<i32>(heap_allocator(), vreg_count);
	auto defs = array_make<i32>(heap_allocator(), vreg_count);
	auto def_pos = array_make<i32>(heap_allocator(), vreg_count);
	auto first_use = array_make<i32>(heap_allocator(), vreg_count);
	auto last_use = array_make<i32>(heap_allocator(), vreg_count);
	auto multi = array_make<bool>(heap_allocator(), vreg_count);
	auto def_block = array_make<i32>(heap_allocator(), vreg_count);
	auto cross = array_make<bool>(heap_allocator(), vreg_count);
	auto clobbers = array_make<i32>(heap_allocator(), 0, 256); // prefix counts of a64_clobbers
	auto want = array_make<i8>(heap_allocator(), vreg_count);  // the argument register a call reads it from
	defer (array_free(&block));
	defer (array_free(&defs));
	defer (array_free(&def_pos));
	defer (array_free(&first_use));
	defer (array_free(&last_use));
	defer (array_free(&multi));
	defer (array_free(&def_block));
	defer (array_free(&cross));
	defer (array_free(&clobbers));
	defer (array_free(&want));
	for (isize i = 0; i < vreg_count; i++) {
		block[i] = -1;
		def_pos[i] = -1;
		first_use[i] = -1;
		last_use[i] = -1;
		def_block[i] = -1;
		want[i] = A64_NOREG;
	}
	auto note_want = [&](u32 v, i32 r) {
		if (v == 0) return;
		want[v] = want[v] == A64_NOREG || want[v] == r ? cast(i8)r : cast(i8)-2;
	};

	L->uses = array_make<i32>(heap_allocator(), vreg_count);
	L->reg = array_make<i8>(heap_allocator(), vreg_count);
	L->is_const = array_make<u8>(heap_allocator(), vreg_count);
	L->cval = array_make<i64>(heap_allocator(), vreg_count);
	L->in_block = array_make<u8>(heap_allocator(), vreg_count);
	L->clean = array_make<u8>(heap_allocator(), vreg_count);
	L->via = array_make<i32>(heap_allocator(), vreg_count);
	L->remat = array_make<u8>(heap_allocator(), vreg_count);
	L->rmem = array_make<xbMem>(heap_allocator(), vreg_count);
	for (isize i = 0; i < vreg_count; i++) {
		L->reg[i] = A64_NOREG;
		L->via[i] = -1;
	}

	// a reference costs 8 times more for each loop around it; a loop is a jump back to or
	// before its block
	auto bweight = array_make<i64>(heap_allocator(), p->blocks.count);
	auto vweight = array_make<i64>(heap_allocator(), vreg_count);
	defer (array_free(&bweight));
	defer (array_free(&vweight));
	{
		isize bc = p->order.count;
		auto pos = array_make<isize>(heap_allocator(), p->blocks.count);
		auto depth = array_make<i32>(heap_allocator(), bc);
		defer (array_free(&pos));
		defer (array_free(&depth));
		for (isize i = 0; i < bc; i++) pos[p->order[i]->index] = i;
		for (isize i = 0; i < bc; i++) {
			for (xbInstr const &in : p->order[i]->instrs) {
				i32 targets[2] = {-1, -1};
				if (in.op == xbOp_Jump) targets[0] = cast(i32)in.imm;
				if (in.op == xbOp_Branch) { targets[0] = cast(i32)in.imm; targets[1] = cast(i32)in.c; }
				for (i32 t : targets) {
					if (t < 0 || !p->blocks[t]->placed || pos[t] > i) continue;
					for (isize k = pos[t]; k <= i; k++) depth[k]++;
				}
			}
		}
		for (isize i = 0; i < bc; i++) bweight[p->order[i]->index] = 1ll << (3*gb_min(depth[i], 6));
	}

	i32 linear = 0;
	L->max_call_stack = 0;
	array_add(&clobbers, 0);
	for (xbBlock *b : p->order) {
		for (xbInstr const &in : b->instrs) {
			xb_for_each_vreg(p, in, [&](u32 v, bool is_def) {
				if (v == 0) return;
				vweight[v] += bweight[b->index];
				if (block[v] < 0) {
					block[v] = b->index;
				} else if (block[v] != b->index) {
					multi[v] = true;
				}
				if (is_def) {
					if (defs[v]++ == 0) def_pos[v] = linear;
					def_block[v] = b->index;
					if (in.op == xbOp_IConst && xb_type_is_int(p->vregs[v])) {
						L->is_const[v] = true;
						L->cval[v] = in.imm;
					}
					if (in.op == xbOp_Lea && ((in.mem.kind == xbMem_Local && p->locals[in.mem.base].over_align <= 16) || in.mem.kind == xbMem_Incoming)) {
						L->remat[v] = true;
						L->rmem[v] = in.mem;
					}
					if ((in.op == xbOp_ICmp || in.op == xbOp_FCmp) || (in.op == xbOp_Load && in.type == xbType_I8)) {
						L->clean[v] = true;
					}
				} else {
					L->uses[v]++;
					if (first_use[v] < 0) first_use[v] = linear;
					last_use[v] = linear;
					if (def_block[v] != b->index) cross[v] = true;
				}
			});
			if (in.op == xbOp_Call) {
				L->max_call_stack = gb_max(L->max_call_stack, p->calls[cast(isize)in.imm].stack_size);
			}
			if (in.op == xbOp_Alloca) L->sp_moves = true;
			switch (in.op) {
			case xbOp_Call:
			case xbOp_Ret:
			case xbOp_Syscall:
				for (xbCallArg const &arg : p->calls[cast(isize)in.imm].args) {
					if (arg.kind == xbCallArg_Gpr && arg.reg <= X8) note_want(arg.vreg, arg.reg);
					if (arg.kind == xbCallArg_Xmm && arg.reg < 8)   note_want(arg.vreg, A64_VREG + arg.reg);
				}
				break;
			case xbOp_MemCopyDyn:
			case xbOp_MemMoveDyn:
			case xbOp_MemSetDyn:
				note_want(in.a, X0);
				note_want(in.b, X1);
				note_want(in.c, X2);
				break;
			}
			array_add(&clobbers, clobbers[linear] + (a64_clobbers(in) ? 1 : 0));
			linear++;
		}
	}
	for (isize v = 1; v < vreg_count; v++) {
		if (defs[v] != 1) {
			L->is_const[v] = false;
			L->clean[v] = false;
			L->remat[v] = false;
		}
		L->in_block[v] = defs[v] == 1 && !multi[v] && (first_use[v] < 0 || first_use[v] > def_pos[v]);
	}

	// The other int and float vregs get one interval in the block order that covers every point
	// where a liveness analysis finds them live.
	isize bc = p->order.count;
	auto gid = array_make<i32>(heap_allocator(), vreg_count);
	defer (array_free(&gid));
	// an item is a vreg, or a local with A64_LOCAL_ITEM set
	auto gvreg = array_make<u32>(heap_allocator(), 0, 64);
	defer (array_free(&gvreg));
	auto lgid = array_make<i32>(heap_allocator(), p->locals.count);
	auto lweight = array_make<i64>(heap_allocator(), p->locals.count);
	defer (array_free(&lgid));
	defer (array_free(&lweight));
	for (isize i = 0; i < p->locals.count; i++) lgid[i] = -1;
	for (int pass = 0; pass < 2; pass++) {
		for (i32 l : ranked) {
			if (is_param[l] != (pass == 0)) continue;
			lgid[l] = cast(i32)gvreg.count;
			array_add(&gvreg, A64_LOCAL_ITEM | cast(u32)l);
		}
	}
	for (isize v = 1; v < vreg_count; v++) {
		gid[v] = -1;
		xbType t = p->vregs[v];
		if (L->in_block[v] || defs[v] == 0 || L->is_const[v] || L->remat[v] || (!xb_type_is_int(t) && !xb_type_is_float(t))) continue;
		gid[v] = cast(i32)gvreg.count;
		array_add(&gvreg, cast(u32)v);
	}
	isize gn = gvreg.count;
	auto glo = array_make<i32>(heap_allocator(), gn);
	auto ghi = array_make<i32>(heap_allocator(), gn);
	auto glo_def = array_make<bool>(heap_allocator(), gn); // the interval starts where an instruction writes it
	auto gstart = array_make<i32>(heap_allocator(), 0, gn); // global ids by the start of their interval
	defer (array_free(&glo));
	defer (array_free(&ghi));
	defer (array_free(&glo_def));
	defer (array_free(&gstart));
	if (gn > 0 && bc > 0) {
		auto bstart   = array_make<i32>(heap_allocator(), bc);
		auto bend     = array_make<i32>(heap_allocator(), bc);
		auto succ     = array_make<i32>(heap_allocator(), 2*bc);
		auto opos     = array_make<i32>(heap_allocator(), p->blocks.count);
		defer (array_free(&bstart));
		defer (array_free(&bend));
		defer (array_free(&succ));
		defer (array_free(&opos));
		// per block, whether an item is read there before it is written (gen) or is written (kill)
		struct Event { i32 id; i32 block; bool kill; };
		auto events = array_make<Event>(heap_allocator(), 0, 4*gn);
		auto ev_block = array_make<i32>(heap_allocator(), gn); // the block of the item's last event
		auto ev_state = array_make<u8>(heap_allocator(), gn);  // 1: gen noted, 2: killed
		defer (array_free(&events));
		defer (array_free(&ev_block));
		defer (array_free(&ev_state));
		for (isize i = 0; i < gn; i++) {
			glo[i] = INT32_MAX;
			ghi[i] = -1;
			ev_block[i] = -1;
		}
		for (isize bi = 0; bi < bc; bi++) opos[p->order[bi]->index] = cast(i32)bi;
		for (xbParamIn const &in : p->params_in) {
			if (in.dst.kind != xbMem_Local || lgid[in.dst.base] < 0) continue;
			i32 id = lgid[in.dst.base];
			glo[id] = 0;
			ghi[id] = 0;
		}

		// the positions each debug scope covers
		isize sn = p->debug_scope_parent.count;
		auto smin = array_make<i32>(heap_allocator(), sn);
		auto smax = array_make<i32>(heap_allocator(), sn);
		defer (array_free(&smin));
		defer (array_free(&smax));
		for (isize i = 0; i < sn; i++) {
			smin[i] = INT32_MAX;
			smax[i] = -1;
		}

		linear = 0;
		for (isize bi = 0; bi < bc; bi++) {
			xbBlock *b = p->order[bi];
			i32 scope = b->debug_scope;
			succ[2*bi] = succ[2*bi+1] = -1;
			bstart[bi] = linear;
			for (xbInstr const &in : b->instrs) {
				if (in.op == xbOp_Scope) scope = cast(i32)in.imm;
				if (scope >= 0 && scope < sn) {
					smin[scope] = gb_min(smin[scope], linear);
					smax[scope] = gb_max(smax[scope], linear);
				}
				auto note = [&](i32 id, bool is_def) {
					if (gvreg[id] & A64_LOCAL_ITEM) lweight[gvreg[id] & ~A64_LOCAL_ITEM] += bweight[b->index];
					if (ev_block[id] != bi) {
						ev_block[id] = cast(i32)bi;
						ev_state[id] = 0;
					}
					if (is_def) {
						if (!(ev_state[id] & 2)) {
							Event e = {id, cast(i32)bi, true};
							array_add(&events, e);
						}
						ev_state[id] |= 2;
					} else if (ev_state[id] == 0) {
						Event e = {id, cast(i32)bi, false};
						array_add(&events, e);
						ev_state[id] = 1;
					}
					if (linear < glo[id]) {
						glo[id] = linear;
						glo_def[id] = is_def;
					} else if (linear == glo[id] && !is_def) {
						glo_def[id] = false;
					}
					if (linear > ghi[id]) ghi[id] = linear;
				};
				bool local = (in.op == xbOp_Load || in.op == xbOp_Store) && in.mem.kind == xbMem_Local && lgid[in.mem.base] >= 0;
				if (local && in.op == xbOp_Load) note(lgid[in.mem.base], false);
				xbCall const *call = nullptr;
				if (in.op == xbOp_Call || in.op == xbOp_Ret || in.op == xbOp_Syscall) call = &p->calls[cast(isize)in.imm];
				if (call) {
					for (xbCallArg const &arg : call->args) {
						if (arg.kind == xbCallArg_GprMem && arg.mem.kind == xbMem_Local && lgid[arg.mem.base] >= 0) note(lgid[arg.mem.base], false);
					}
				}
				// an instruction names the vregs it reads before the ones it writes
				xb_for_each_vreg(p, in, [&](u32 v, bool is_def) {
					if (v != 0 && gid[v] >= 0) note(gid[v], is_def);
				});
				if (local && in.op == xbOp_Store) note(lgid[in.mem.base], true);
				if (call) {
					for (xbCallRet const &r : call->rets) {
						if (r.dst.kind == xbMem_Local && lgid[r.dst.base] >= 0) note(lgid[r.dst.base], true);
					}
				}
				if (in.op == xbOp_Jump) {
					succ[2*bi] = cast(i32)in.imm;
				} else if (in.op == xbOp_Branch) {
					succ[2*bi] = cast(i32)in.imm;
					succ[2*bi+1] = cast(i32)in.c;
				}
				linear++;
			}
			bend[bi] = linear - 1;
			for (isize s = 2*bi; s < 2*bi+2; s++) {
				if (succ[s] >= 0) succ[s] = p->blocks[succ[s]]->placed ? opos[succ[s]] : -1;
			}
		}

		// Each item is live into the blocks that read it first, and from there back through the
		// predecessors until the blocks that write it.
		auto pred_start = array_make<i32>(heap_allocator(), bc+1);
		auto preds      = array_make<i32>(heap_allocator(), 2*bc);
		defer (array_free(&pred_start));
		defer (array_free(&preds));
		for (isize s = 0; s < 2*bc; s++) if (succ[s] >= 0) pred_start[succ[s]+1]++;
		for (isize i = 0; i < bc; i++) pred_start[i+1] += pred_start[i];
		{
			auto fill = array_make<i32>(heap_allocator(), bc);
			defer (array_free(&fill));
			for (isize s = 0; s < 2*bc; s++) {
				if (succ[s] >= 0) preds[pred_start[succ[s]] + fill[succ[s]]++] = cast(i32)(s/2);
			}
		}
		auto ev_start = array_make<i32>(heap_allocator(), gn+1);
		auto by_id    = array_make<i32>(heap_allocator(), events.count);
		defer (array_free(&ev_start));
		defer (array_free(&by_id));
		for (Event const &e : events) ev_start[e.id+1]++;
		for (isize i = 0; i < gn; i++) ev_start[i+1] += ev_start[i];
		{
			auto fill = array_make<i32>(heap_allocator(), gn);
			defer (array_free(&fill));
			for (isize i = 0; i < events.count; i++) by_id[ev_start[events[i].id] + fill[events[i].id]++] = cast(i32)i;
		}
		// marks hold id+1 for the item being walked
		auto kill_mark = array_make<i32>(heap_allocator(), bc);
		auto in_mark   = array_make<i32>(heap_allocator(), bc);
		auto out_mark  = array_make<i32>(heap_allocator(), bc);
		auto stack     = array_make<i32>(heap_allocator(), 0, 64);
		defer (array_free(&kill_mark));
		defer (array_free(&in_mark));
		defer (array_free(&out_mark));
		defer (array_free(&stack));
		for (i32 id = 0; id < gn; id++) {
			i32 mark = id + 1;
			stack.count = 0;
			for (i32 k = ev_start[id]; k < ev_start[id+1]; k++) {
				Event const &e = events[by_id[k]];
				if (e.kill) kill_mark[e.block] = mark;
				else        array_add(&stack, e.block);
			}
			for (i32 bi : stack) in_mark[bi] = mark;
			while (stack.count > 0) {
				i32 bi = array_pop(&stack);
				if (bstart[bi] <= glo[id]) {
					glo[id] = bstart[bi];
					glo_def[id] = false;
				}
				for (i32 k = pred_start[bi]; k < pred_start[bi+1]; k++) {
					i32 pb = preds[k];
					if (out_mark[pb] != mark) {
						out_mark[pb] = mark;
						ghi[id] = gb_max(ghi[id], bend[pb]);
					}
					if (kill_mark[pb] != mark && in_mark[pb] != mark) {
						in_mark[pb] = mark;
						array_add(&stack, pb);
					}
				}
			}
		}
		// Copies between a promoted local and a vreg in one block. A load's vreg reads the local's
		// register while nothing writes the local. A vreg whose only use is a store to the local is
		// computed right in its register, when nothing reads or writes the local in between.
		auto alias_end = array_make<i32>(heap_allocator(), p->locals.count); // last read through an alias
		defer (array_free(&alias_end));
		for (isize i = 0; i < p->locals.count; i++) alias_end[i] = -1;
		auto local_of = [&](xbMem const &m) -> i32 {
			return m.kind == xbMem_Local && lgid[m.base] >= 0 ? cast(i32)m.base : -1;
		};
		auto writes = [&](xbInstr const &n, i32 l) -> bool {
			if (n.op == xbOp_Store) return local_of(n.mem) == l;
			if (n.op == xbOp_Call) {
				for (xbCallRet const &r : p->calls[cast(isize)n.imm].rets) if (local_of(r.dst) == l) return true;
			}
			return false;
		};
		auto reads = [&](xbInstr const &n, i32 l) -> bool {
			if (n.op == xbOp_Load) return local_of(n.mem) == l;
			if (n.op == xbOp_Call || n.op == xbOp_Ret || n.op == xbOp_Syscall) {
				for (xbCallArg const &arg : p->calls[cast(isize)n.imm].args) {
					if (arg.kind == xbCallArg_GprMem && local_of(arg.mem) == l) return true;
				}
			}
			return false;
		};
		for (isize bi = 0; bi < bc; bi++) {
			xbBlock *b = p->order[bi];
			for (isize i = 0; i < b->instrs.count; i++) {
				xbInstr const &in = b->instrs[i];
				i32 pos = bstart[bi] + cast(i32)i;
				if (in.op == xbOp_Load) {
					i32 l = local_of(in.mem);
					u32 v = in.dst;
					if (l < 0 || v == 0 || !L->in_block[v] || L->uses[v] == 0 || last_use[v] - pos > 256) continue;
					bool ok = true;
					for (isize j = i+1; ok && j <= i + (last_use[v] - pos); j++) ok = !writes(b->instrs[j], l);
					if (!ok) continue;
					L->via[v] = l;
					alias_end[l] = gb_max(alias_end[l], last_use[v]);
					ghi[lgid[l]] = gb_max(ghi[lgid[l]], last_use[v]);
				} else if (in.op == xbOp_Store) {
					i32 l = local_of(in.mem);
					u32 v = in.a;
					if (l < 0 || v == 0 || !L->in_block[v] || L->uses[v] != 1 || L->is_const[v] || L->remat[v] || L->via[v] >= 0 ||
					    !xb_type_is_int(p->vregs[v]) || pos - def_pos[v] > 256 || alias_end[l] >= def_pos[v]) continue;
					isize d = def_pos[v] - bstart[bi];
					bool ok = true;
					for (isize j = d; ok && j < i; j++) ok = !reads(b->instrs[j], l) && (j == d || !writes(b->instrs[j], l));
					if (!ok) continue;
					L->via[v] = l;
					i32 id = lgid[l];
					if (def_pos[v] < glo[id]) {
						glo[id] = def_pos[v];
						glo_def[id] = true;
					}
				}
			}
		}

		// A debug variable keeps its register in all of its scope, the code where a debugger shows
		// it. Scopes are made after their parents.
		for (isize i = sn-1; i > 0; i--) {
			i32 up = p->debug_scope_parent[i];
			if (up < 0 || smax[i] < 0) continue;
			smin[up] = gb_min(smin[up], smin[i]);
			smax[up] = gb_max(smax[up], smax[i]);
		}
		for (xbDebugVar const &v : p->debug_vars) {
			if (v.local < 0 || lgid[v.local] < 0 || v.scope < 0 || v.scope >= sn || smax[v.scope] < 0) continue;
			i32 id = lgid[v.local];
			if (smin[v.scope] <= glo[id]) {
				glo[id] = smin[v.scope];
				glo_def[id] = false;
			}
			ghi[id] = gb_max(ghi[id], smax[v.scope]);
		}

		// ordered by start, a counting sort
		auto first = array_make<i32>(heap_allocator(), linear+1);
		defer (array_free(&first));
		for (isize i = 0; i < gn; i++) {
			if (ghi[i] >= 0) first[glo[i]+1]++;
		}
		for (i32 i = 0; i < linear; i++) first[i+1] += first[i];
		array_resize(&gstart, first[linear]);
		for (isize i = 0; i < gn; i++) {
			if (ghi[i] >= 0) gstart[first[glo[i]]++] = cast(i32)i;
		}
	}

	// registers for the vregs, first come first served
	u32 const caller_x = 0x1ff;                       // x0-x8
	u32 const callee_x = 0x1ff80000;                  // x19-x28
	u32 const caller_v = 0xfff000ff;                  // v0-v7, v20-v31
	u32 const callee_v = 0x0000ff00;                  // v8-v15
	u32 free_x = caller_x | callee_x;
	u32 free_v = caller_v | callee_v;
	u32 used_x = 0, used_v = 0;
	// the vregs and locals holding a register, listed under the position after their last
	struct Active { u32 v; i32 next; bool dead; i32 len; };
	auto active = array_make<Active>(heap_allocator(), 0, 64);
	// the active entry holding each x register, and each v register at 32 + n
	i32 owner[64];
	for (i32 &o : owner) o = -1;
	// a local whose register a vreg shares keeps it
	auto shared = array_make<bool>(heap_allocator(), p->locals.count);
	defer (array_free(&shared));
	auto weight_of = [&](u32 v) -> i64 {
		return (v & A64_LOCAL_ITEM) ? lweight[v & ~A64_LOCAL_ITEM] : vweight[v];
	};
	auto expire = array_make<i32>(heap_allocator(), clobbers.count + 1);
	defer (array_free(&active));
	defer (array_free(&expire));
	for (i32 &e : expire) e = -1;
	// gives v a register for [now, end] if one is free, a callee saved one when `calls`
	auto take = [&](u32 v, i32 end, bool calls) {
		bool is_local = (v & A64_LOCAL_ITEM) != 0;
		i32 l = cast(i32)(v & ~A64_LOCAL_ITEM);
		bool fp = !is_local && xb_type_is_float(p->vregs[v]);
		u32 *free = fp ? &free_v : &free_x;
		u32 pool = fp ? (calls ? callee_v : caller_v | callee_v)
		              : (calls ? callee_x : caller_x | callee_x);
		if (is_local && is_param[l]) {
			// the prologue moves a parameter into a register no other parameter arrives in
			pool = callee_x;
			i8 w = arrive[l];
			if (w >= 0 && !calls && (*free & (1u << w))) pool = 1u << w;
		}
		u32 avail = *free & pool;
		if (avail == 0) {
			// the register of the active item that costs least in memory for each position it
			// covers, when that is less than v's
			i64 w = weight_of(v);
			i64 wl = end - linear + 1;
			i32 best = -1;
			for (u32 r = 0; r < 32; r++) {
				if (!(pool & (1u << r))) continue;
				i32 k = owner[(fp ? 32 : 0) + r];
				if (k < 0) continue;
				u32 y = active[k].v;
				if ((y & A64_LOCAL_ITEM) && shared[y & ~A64_LOCAL_ITEM]) continue;
				i64 wy = weight_of(y);
				i64 ly = active[k].len;
				if (wy*wl < w*ly) { w = wy; wl = ly; best = k; }
			}
			if (best >= 0) {
				u32 y = active[best].v;
				i8 r = (y & A64_LOCAL_ITEM) ? L->local_reg[y & ~A64_LOCAL_ITEM] : L->reg[y];
				if (y & A64_LOCAL_ITEM) L->local_reg[y & ~A64_LOCAL_ITEM] = A64_NOREG;
				else                    L->reg[y] = A64_NOREG;
				active[best].dead = true;
				owner[r] = -1;
				*free |= 1u << (r >= A64_VREG ? r - A64_VREG : r);
				avail = *free & pool;
			}
		}
		if (avail == 0) return;
		// the caller saved ones first, they cost no save; from the top, where calls
		// want the fewest arguments
		u32 caller = avail & (fp ? caller_v : caller_x);
		u32 r = 0;
		if (caller) {
			r = 31;
			while ((caller & (1u << r)) == 0) r--;
		} else {
			while ((avail & (1u << r)) == 0) r++;
		}
		*free &= ~(1u << r);
		if (fp) {
			used_v |= 1u << r;
			L->reg[v] = cast(i8)(A64_VREG + r);
		} else if (is_local) {
			used_x |= 1u << r;
			L->local_reg[l] = cast(i8)r;
		} else {
			used_x |= 1u << r;
			L->reg[v] = cast(i8)r;
		}
		owner[(fp ? 32 : 0) + r] = cast(i32)active.count;
		Active act = {v, expire[end+1], false, end - linear + 1};
		expire[end+1] = cast(i32)active.count;
		array_add(&active, act);
	};
	isize gs = 0;
	linear = 0;
	for (xbBlock *b : p->order) {
		for (xbInstr const &in : b->instrs) {
			for (i32 k = expire[linear]; k >= 0; k = active[k].next) {
				if (active[k].dead) continue;
				u32 v = active[k].v;
				i8 r = (v & A64_LOCAL_ITEM) ? L->local_reg[v & ~A64_LOCAL_ITEM] : L->reg[v];
				owner[r] = -1;
				if (r >= A64_VREG) free_v |= 1u << (r - A64_VREG);
				else               free_x |= 1u << r;
			}
			while (gs < gstart.count && glo[gstart[gs]] == linear) {
				i32 id = gstart[gs++];
				// a call that defines v writes it afterwards
				take(gvreg[id], ghi[id], clobbers[ghi[id]+1] - clobbers[linear + (glo_def[id] ? 1 : 0)] > 0);
			}
			xb_for_each_vreg(p, in, [&](u32 v, bool is_def) {
				if (v == 0 || !is_def || !L->in_block[v] || L->is_const[v] || L->remat[v] || L->reg[v] != A64_NOREG) return;
				xbType t = p->vregs[v];
				if (!xb_type_is_int(t) && !xb_type_is_float(t)) return;
				if (L->via[v] >= 0 && L->local_reg[L->via[v]] >= 0) {
					L->reg[v] = L->local_reg[L->via[v]];
					shared[L->via[v]] = true;
					return;
				}
				i32 end = last_use[v] >= 0 ? last_use[v] : linear;
				// read only as an argument, before that call: right in the argument register
				i8 w = want[v];
				if (w >= 0 && L->uses[v] == 1 && clobbers[end] - clobbers[linear+1] == 0 &&
				    (w >= A64_VREG) == xb_type_is_float(t)) {
					u32 *free = xb_type_is_float(t) ? &free_v : &free_x;
					u32 bit = 1u << (w >= A64_VREG ? w - A64_VREG : w);
					if (*free & bit) {
						*free &= ~bit;
						L->reg[v] = w;
						owner[w] = cast(i32)active.count;
						Active act = {v, expire[end+1]};
						expire[end+1] = cast(i32)active.count;
						array_add(&active, act);
						return;
					}
				}
				take(v, end, clobbers[end+1] - clobbers[linear+1] > 0);
			});
			linear++;
		}
	}

	L->pairs = 0;
	for (u32 k = 0; k < 5; k++) {
		if (used_x & (3u << (X19 + 2*k))) L->pairs |= 1u << k;
	}
	for (u32 k = 0; k < 4; k++) {
		if (used_v & (3u << (8 + 2*k))) L->pairs |= 0x100u << k;
	}
	i32 cur = 0;
	a64_for_each_pair(L->pairs, [&](u8, u8, bool, i32 off) { cur = -off; });

	// the other vregs used only in the block that defines them share slots
	L->slot = array_make<i32>(heap_allocator(), vreg_count);
	auto free_slots = array_make<i32>(heap_allocator(), 0, 64);
	defer (array_free(&free_slots));
	auto to_free = array_make<u32>(heap_allocator(), 0, 8);
	defer (array_free(&to_free));
	linear = 0;
	for (xbBlock *b : p->order) {
		for (xbInstr const &in : b->instrs) {
			to_free.count = 0;
			xb_for_each_vreg(p, in, [&](u32 v, bool is_def) {
				if (v == 0 || L->reg[v] != A64_NOREG || L->is_const[v] || L->remat[v]) return;
				if (is_def) {
					i32 s = 0;
					if (!cross[v] && free_slots.count > 0) {
						s = array_pop(&free_slots);
					} else {
						cur += 8;
						s = -cur;
					}
					L->slot[v] = s;
					if (!cross[v] && last_use[v] < linear) {
						array_add(&to_free, v); // never used
					}
				} else if (!cross[v] && last_use[v] == linear) {
					array_add(&to_free, v);
				}
			});
			for (isize i = 0; i < to_free.count; i++) {
				// a vreg may appear twice in one instruction
				bool dup = false;
				for (isize j = 0; j < i; j++) if (to_free[j] == to_free[i]) { dup = true; break; }
				if (!dup) array_add(&free_slots, L->slot[to_free[i]]);
			}
			linear++;
		}
	}

	for (xbLocal &l : p->locals) {
		if (l.over_align > 16) {
			// the frame is only 16 byte aligned, the prologue picks an aligned spot in the raw area
			cur = cast(i32)xb_lt_align_formula(cur + l.size + l.over_align - 16, 16);
			l.raw_offset = -cur;
			cur = cast(i32)xb_lt_align_formula(cur + 8, 8);
			l.frame_offset = -cur;
			continue;
		}
		cur = cast(i32)xb_lt_align_formula(cur + l.size, l.align);
		l.frame_offset = -cur;
	}

	L->frame_size = cast(i32)xb_lt_align_formula(cur, 16) + cast(i32)xb_lt_align_formula(L->max_call_stack, 16);
}

////////////////////////////////////////////////////////////////
// Operands
////////////////////////////////////////////////////////////////

// The frame at x29+off for an access of `size` bytes, 0 when not known. Far below x29,
// sp reaches it with a short scaled offset instead.
gb_internal a64Addr a64_frame(a64Lower *L, i64 off, i32 size) {
	a64Addr r = {A64_FP, off};
	if (off >= -256 || L->sp_moves) return r;
	i64 s = L->frame_size + off;
	if (s >= 0 && (size == 0 || (s % size == 0 && s / size < 4096))) {
		r.base = A64_SP;
		r.off = s;
	}
	return r;
}

// v's value of `size` bytes extended as `ext` asks
gb_internal i64 a64_ext_value(i64 v, i32 size, xbExtKind ext) {
	if (size >= 8 || ext == xbExt_None) return v;
	u64 mask = (1ull << (8*size)) - 1;
	u64 u = cast(u64)v & mask;
	if (ext == xbExt_Sign && (u >> (8*size - 1))) u |= ~mask;
	return cast(i64)u;
}

gb_internal bool a64_is_const(a64Lower *L, u32 v, i64 *value) {
	if (v == 0 || !L->is_const[v]) return false;
	*value = L->cval[v];
	return true;
}

gb_internal a64Addr a64_mem(a64Lower *L, xbMem const &m, u8 scratch=A64_TA);

// An x register holding v: its own, or `scratch` loaded with it. Narrow values come
// extended as `ext` asks; with xbExt_None only the low `size` bytes mean anything.
gb_internal u8 a64_src(a64Lower *L, u32 v, u8 scratch, i32 size, xbExtKind ext) {
	GB_ASSERT(v != 0);
	xbAsm *a = &L->a;
	bool extend = size < 8 && ext != xbExt_None;
	if (L->is_const[v]) {
		a64_mov_imm(a, scratch, cast(u64)a64_ext_value(L->cval[v], size, ext));
		return scratch;
	}
	if (L->remat[v]) {
		a64Addr m = a64_mem(L, L->rmem[v], scratch);
		a64_add_imm(a, scratch, m.base, m.off);
		return scratch;
	}
	i8 r = L->reg[v];
	if (r >= A64_VREG) {
		a64_fmov_from_fp(a, scratch, cast(u8)(r - A64_VREG));
		if (extend) a64_extend(a, ext == xbExt_Sign, size, scratch, scratch);
		return scratch;
	}
	if (r != A64_NOREG) {
		if (!extend) return cast(u8)r;
		a64_extend(a, ext == xbExt_Sign, size, scratch, cast(u8)r);
		return scratch;
	}
	a64Addr f = a64_frame(L, L->slot[v], size);
	a64_ldr(a, size, ext == xbExt_Sign, scratch, f.base, f.off);
	return scratch;
}

// Like a64_src, into exactly `reg`.
gb_internal void a64_get(a64Lower *L, u8 reg, u32 v, i32 size, xbExtKind ext) {
	u8 r = a64_src(L, v, reg, size, ext);
	if (r != reg) a64_mov(&L->a, reg, r);
}

// A v register holding v's `size` byte float: its own, or `scratch` loaded with it.
gb_internal u8 a64_srcf(a64Lower *L, u32 v, u8 scratch, i32 size) {
	GB_ASSERT(v != 0);
	xbAsm *a = &L->a;
	if (L->is_const[v]) {
		a64_mov_imm(a, X17, cast(u64)L->cval[v]);
		a64_fmov_to_fp(a, scratch, X17);
		return scratch;
	}
	i8 r = L->reg[v];
	if (r >= A64_VREG) return cast(u8)(r - A64_VREG);
	if (r != A64_NOREG) {
		a64_fmov_to_fp(a, scratch, cast(u8)r);
		return scratch;
	}
	a64Addr f = a64_frame(L, L->slot[v], size);
	a64_ldr_fp(a, size, scratch, f.base, f.off);
	return scratch;
}

gb_internal void a64_getf(a64Lower *L, u8 vr, u32 v, i32 size) {
	u8 r = a64_srcf(L, v, vr, size);
	if (r != vr) a64_fmov_reg(&L->a, vr, r);
}

// The x register to compute v into: its own, or `scratch`. a64_put finishes the definition.
gb_internal u8 a64_dst(a64Lower *L, u32 v, u8 scratch) {
	i8 r = L->reg[v];
	return r != A64_NOREG && r < A64_VREG ? cast(u8)r : scratch;
}

gb_internal u8 a64_dstf(a64Lower *L, u32 v, u8 scratch) {
	i8 r = L->reg[v];
	return r >= A64_VREG ? cast(u8)(r - A64_VREG) : scratch;
}

// Defines v from the x register `reg`.
gb_internal void a64_put(a64Lower *L, u32 v, u8 reg) {
	GB_ASSERT(v != 0 && !L->is_const[v]);
	xbAsm *a = &L->a;
	i8 r = L->reg[v];
	if (r >= A64_VREG) {
		a64_fmov_to_fp(a, cast(u8)(r - A64_VREG), reg);
	} else if (r != A64_NOREG) {
		if (r != reg) a64_mov(a, cast(u8)r, reg);
	} else {
		a64Addr f = a64_frame(L, L->slot[v], 8);
		a64_str(a, 8, reg, f.base, f.off);
	}
}

// Defines v from the `size` byte float in the v register `vr`.
gb_internal void a64_putf(a64Lower *L, u32 v, u8 vr, i32 size) {
	GB_ASSERT(v != 0 && !L->is_const[v]);
	xbAsm *a = &L->a;
	i8 r = L->reg[v];
	if (r >= A64_VREG) {
		if (r - A64_VREG != vr) a64_fmov_reg(a, cast(u8)(r - A64_VREG), vr);
	} else if (r != A64_NOREG) {
		a64_fmov_from_fp(a, cast(u8)r, vr);
	} else {
		a64Addr f = a64_frame(L, L->slot[v], size);
		a64_str_fp(a, size, vr, f.base, f.off);
	}
}

// A base register and offset for an IR memory reference. May clobber `scratch` and x17.
gb_internal a64Addr a64_mem(a64Lower *L, xbMem const &m, u8 scratch) {
	xbAsm *a = &L->a;
	a64Addr r = {};
	switch (m.kind) {
	case xbMem_Local: {
		GB_ASSERT(L->local_reg[m.base] < 0);
		xbLocal const &l = L->p->locals[m.base];
		if (l.over_align > 16) {
			a64Addr f = a64_frame(L, l.frame_offset, 8);
			a64_ldr(a, 8, false, scratch, f.base, f.off);
			r.base = scratch;
			r.off = m.offset;
			return r;
		}
		return a64_frame(L, l.frame_offset + m.offset, 0);
	}
	case xbMem_Incoming:
		r.base = A64_FP;
		r.off = 16 + m.offset;
		return r;
	case xbMem_Reg:
		if (L->remat[m.base]) {
			// the frame address folds into the access
			xbMem f = L->rmem[m.base];
			f.offset += m.offset;
			return a64_mem(L, f, scratch);
		}
		r.base = a64_src(L, m.base, scratch, 8, xbExt_None);
		r.off = m.offset;
		return r;
	case xbMem_Sym: {
		i32 sym = cast(i32)m.base;
		xbSymbol *s = &L->p->m->symbols[sym];
		GB_ASSERT_MSG((s->flags & xbSymbolFlag_TLS) == 0, "a64: thread local %.*s is reached through xbOp_TlsAddr", LIT(s->name));
		if ((s->flags & xbSymbolFlag_Foreign) && s->section == xbSection_Undef) {
			// it may live in a dylib
			a64_adrp(a, scratch, sym, xbReloc_A64_GotPage21);
			a64_ldr_pageoff(a, scratch, scratch, sym, xbReloc_A64_GotPageOff12);
		} else {
			a64_adrp(a, scratch, sym, xbReloc_A64_Page21);
			a64_add_pageoff(a, scratch, scratch, sym);
		}
		r.base = scratch;
		r.off = m.offset;
		return r;
	}
	}
	GB_PANIC("a64: bad mem");
	return r;
}

// Loads `size` (1..8) bytes into xt, zero extended unless `ext` asks for a sign extension.
gb_internal void a64_load_bytes(a64Lower *L, u8 rt, a64Addr m, i32 size, xbExtKind ext) {
	xbAsm *a = &L->a;
	switch (size) {
	case 1: case 2: case 4: case 8:
		a64_ldr(a, size, ext == xbExt_Sign, rt, m.base, m.off);
		return;
	}
	GB_ASSERT(rt != A64_TB && m.base != A64_TB);
	i32 lo = size > 4 ? 4 : 2;
	a64_ldr(a, lo, false, rt, m.base, m.off);
	i32 at = lo;
	while (at < size) {
		i32 c = size - at >= 2 ? 2 : 1;
		a64_ldr(a, c, false, A64_TB, m.base, m.off + at);
		a64_alu(a, A64_ORR, rt, rt, A64_TB, A64_LSL, cast(u32)(8*at));
		at += c;
	}
}

// Stores the low `size` (1..8) bytes of xt; xt is left as it was.
gb_internal void a64_store_bytes(a64Lower *L, a64Addr m, u8 rt, i32 size) {
	xbAsm *a = &L->a;
	switch (size) {
	case 1: case 2: case 4: case 8:
		a64_str(a, size, rt, m.base, m.off);
		return;
	}
	GB_ASSERT(m.base != A64_TB);
	a64_mov(a, A64_TB, rt);
	i32 at = 0;
	while (at < size) {
		i32 rem = size - at;
		i32 c = rem >= 4 ? 4 : rem >= 2 ? 2 : 1;
		a64_str(a, c, A64_TB, m.base, m.off + at);
		a64_lsr_imm(a, A64_TB, A64_TB, cast(u32)(8*c));
		at += c;
	}
}

gb_internal a64Cond a64_cond_for(xbCond c) {
	switch (c) {
	case xbCond_EQ:  return A64_EQ;
	case xbCond_NE:  return A64_NE;
	case xbCond_SLT: return A64_LT;
	case xbCond_SLE: return A64_LE;
	case xbCond_SGT: return A64_GT;
	case xbCond_SGE: return A64_GE;
	case xbCond_ULT: return A64_LO;
	case xbCond_ULE: return A64_LS;
	case xbCond_UGT: return A64_HI;
	case xbCond_UGE: return A64_HS;
	// after fcmp an unordered result sets C and V, which every one of these rejects but NE
	case xbCond_FEQ: return A64_EQ;
	case xbCond_FNE: return A64_NE;
	case xbCond_FLT: return A64_MI;
	case xbCond_FLE: return A64_LS;
	case xbCond_FGT: return A64_GT;
	case xbCond_FGE: return A64_GE;
	}
	GB_PANIC("a64: bad cond");
	return A64_EQ;
}

// The exact negation, also for an unordered float compare.
gb_internal a64Cond a64_invert(a64Cond c) {
	return cast(a64Cond)(c ^ 1);
}

gb_internal bool a64_cond_is_signed(xbCond c) {
	return c == xbCond_SLT || c == xbCond_SLE || c == xbCond_SGT || c == xbCond_SGE;
}

gb_internal i32 a64_libc_sym(xbModule *m, char const *name) {
	i32 sym = xb_symbol(m, make_string_c(name));
	m->symbols[sym].flags |= xbSymbolFlag_Func | xbSymbolFlag_Foreign;
	return sym;
}

////////////////////////////////////////////////////////////////
// Calls
////////////////////////////////////////////////////////////////

// No vreg lives in x0-x8 or v0-v7 here, so arguments go straight into their registers.
gb_internal void a64_lower_call(a64Lower *L, xbCall const &c, bool is_ret) {
	xbAsm *a = &L->a;
	// stack arguments first, the argument registers are not touched yet
	for (xbCallArg const &arg : c.args) {
		switch (arg.kind) {
		case xbCallArg_Stack: {
			xbType t = arg.type;
			if (xb_type_is_float(t)) {
				u8 r = a64_srcf(L, arg.vreg, A64_F0, xb_type_size(t));
				a64_str_fp(a, xb_type_size(t), r, A64_SP, arg.stack_offset);
			} else {
				u8 r = a64_src(L, arg.vreg, A64_T0, xb_type_size(t), arg.ext == xbExt_Sign ? xbExt_Sign : xbExt_Zero);
				a64_str(a, a64_slot_size(arg.size), r, A64_SP, arg.stack_offset);
			}
			break;
		}
		case xbCallArg_StackMem: {
			a64Addr src = a64_mem(L, arg.mem);
			if (arg.size == 16) {
				a64_ldr_fp(a, 16, A64_F0, src.base, src.off);
				a64_str_fp(a, 16, A64_F0, A64_SP, arg.stack_offset);
			} else {
				GB_ASSERT_MSG(arg.size <= 8, "a64: stack argument of %d bytes", arg.size);
				a64_load_bytes(L, A64_T0, src, arg.size, arg.ext);
				a64_str(a, a64_slot_size(arg.size), A64_T0, A64_SP, arg.stack_offset);
			}
			break;
		}
		}
	}
	for (xbCallArg const &arg : c.args) {
		switch (arg.kind) {
		case xbCallArg_Gpr: {
			i32 size = xb_type_size(arg.type);
			xbExtKind ext = arg.ext;
			if (size < 4 && ext == xbExt_None) ext = xbExt_Zero;
			a64_get(L, arg.reg, arg.vreg, size, ext);
			break;
		}
		case xbCallArg_Xmm:
			a64_getf(L, arg.reg, arg.vreg, xb_type_size(arg.type));
			break;
		case xbCallArg_GprMem: {
			xbExtKind ext = arg.ext;
			if (arg.size < 4 && ext == xbExt_None) ext = xbExt_Zero;
			if (arg.mem.kind == xbMem_Local && L->local_reg[arg.mem.base] >= 0) {
				// the register is callee saved, the call is in its interval
				a64_extend(a, ext == xbExt_Sign, arg.size, arg.reg, cast(u8)L->local_reg[arg.mem.base]);
				break;
			}
			a64Addr src = a64_mem(L, arg.mem);
			a64_load_bytes(L, arg.reg, src, arg.size, ext);
			break;
		}
		case xbCallArg_XmmMem: {
			a64Addr src = a64_mem(L, arg.mem);
			a64_ldr_fp(a, arg.size, arg.reg, src.base, src.off);
			break;
		}
		}
	}
	if (is_ret) {
		return;
	}
	if (c.target_sym >= 0) {
		a64_bl_sym(a, c.target_sym);
	} else {
		a64_blr(a, a64_src(L, c.target_vreg, A64_TA, 8, xbExt_None));
	}
	for (xbCallRet const &r : c.rets) {
		if (r.dst.kind == xbMem_Local && L->local_reg[r.dst.base] >= 0) {
			a64_extend(a, false, r.size, cast(u8)L->local_reg[r.dst.base], r.reg);
			return;
		}
		a64Addr dst = a64_mem(L, r.dst);
		if (r.loc == xbLoc_Gpr) {
			a64_store_bytes(L, dst, r.reg, r.size);
		} else {
			a64_str_fp(a, r.size, r.reg, dst.base, dst.off);
		}
	}
	if (c.rets.count == 1) {
		xbCallRet const &r = c.rets[0];
		a64Lower::Stored st = {true, r.loc != xbLoc_Gpr, r.reg, r.size, r.dst, true};
		L->stored = st;
	}
}

// memmove(x0, x1, x2) or memset(x0, w1, x2), from the C library like LLVM's lowering
gb_internal void a64_call_libc(a64Lower *L, char const *name) {
	a64_bl_sym(&L->a, a64_libc_sym(L->p->m, name));
}

gb_internal void a64_epilogue(a64Lower *L) {
	xbAsm *a = &L->a;
	a64_for_each_pair(L->pairs, [&](u8 lo, u8 hi, bool fp, i32 off) {
		a64_pair(a, fp, true, hi, lo, A64_FP, off);
	});
	a64_mov_sp(a, A64_SP, A64_FP);
	a64_emit(a, 0xA8C17BFD); // ldp x29, x30, [sp], #16
	a64_ret(a);
}

// Jumps to `block`, patched once every block is placed.
gb_internal void a64_jump(a64Lower *L, i32 block) {
	a64Lower::Fixup f = {a64_b(&L->a), block, false};
	array_add(&L->fixups, f);
}

// Goes to `t` when the condition holds, else to `f`. The condition is `c` on the flags,
// or with `test` >= 0, whether that register is not zero.
gb_internal void a64_branch(a64Lower *L, a64Cond c, i32 test, i32 t, i32 f) {
	xbAsm *a = &L->a;
	auto jump_if = [&](bool when, i32 block) {
		i64 at = test >= 0 ? a64_cb(a, when, cast(u8)test) : a64_bcond(a, when ? c : a64_invert(c));
		a64Lower::Fixup fx = {at, block, true};
		array_add(&L->fixups, fx);
	};
	auto skip_if = [&](bool when) {
		if (test >= 0) a64_cb_skip(a, when, cast(u8)test);
		else           a64_bcond_skip(a, when ? c : a64_invert(c));
	};
	if (L->far) {
		// cbz/cbnz and b.cond only skip one instruction, so no procedure is too long for them
		if (t == L->next_block) {
			skip_if(true);
			a64_jump(L, f);
		} else {
			skip_if(false);
			a64_jump(L, t);
			if (f != L->next_block) a64_jump(L, f);
		}
		return;
	}
	if (f == L->next_block) {
		jump_if(true, t);
	} else if (t == L->next_block) {
		jump_if(false, f);
	} else {
		jump_if(true, t);
		a64_jump(L, f);
	}
}

// Sets the flags or picks a register so that a64_branch can test the bool v.
gb_internal i32 a64_test_bool(a64Lower *L, u32 v) {
	i8 r = L->reg[v];
	if (r != A64_NOREG && r < A64_VREG) {
		if (L->clean[v]) return r;
		a64_tst_byte(&L->a, cast(u8)r);
		return -1;
	}
	return a64_src(L, v, A64_T0, 1, xbExt_Zero);
}

////////////////////////////////////////////////////////////////
// Instructions
////////////////////////////////////////////////////////////////

// Ends a compare: the flags hold `c`, kept for the next instruction or put in dst.
gb_internal void a64_compare_result(a64Lower *L, xbInstr const &in, a64Cond c) {
	if (L->fuse) {
		L->flags_vreg = in.dst;
		L->flags_cond = c;
		return;
	}
	u8 d = a64_dst(L, in.dst, A64_T0);
	a64_cset(&L->a, d, c);
	a64_put(L, in.dst, d);
}

// A logical immediate for k as a `size` byte operand, whose higher bytes mean nothing: k
// itself, zero extended, or repeated across the register.
gb_internal i32 a64_logical_imm_any(u64 k, i32 size) {
	i32 enc = a64_logical_imm(k);
	if (enc >= 0 || size >= 8) return enc;
	u64 low = k & ((1ull << (8*size)) - 1);
	enc = a64_logical_imm(low);
	if (enc >= 0) return enc;
	u64 rep = low;
	for (i32 w = 8*size; w < 64; w *= 2) rep |= rep << w;
	return a64_logical_imm(rep);
}

gb_internal void a64_lower_instr(a64Lower *L, xbInstr const &in) {
	xbAsm *a = &L->a;
	xbProc *p = L->p;
	i32 size = xb_type_size(in.type);
	i64 k = 0;
	switch (in.op) {
	case xbOp_Nop:
		if (in.imm == 1) a64_emit(a, 0xD503201F);
		break;
	case xbOp_Scope:
		break;
	case xbOp_Loc: {
		xbLineEntry e = {};
		e.code_offset = cast(i32)(xb_pos(a) - L->proc_start);
		e.file_id = cast(i32)in.a;
		e.line = cast(i32)in.imm;
		e.column = cast(i32)in.b;
		array_add(&p->m->lines, e);
		break;
	}
	case xbOp_IConst:
	case xbOp_FConst: {
		u8 d = a64_dst(L, in.dst, A64_T0);
		a64_mov_imm(a, d, cast(u64)in.imm);
		a64_put(L, in.dst, d);
		break;
	}
	case xbOp_Lea: {
		if (L->remat[in.dst]) break;
		u8 d = a64_dst(L, in.dst, A64_T0);
		// a symbol's address goes right into d
		a64Addr m = a64_mem(L, in.mem, d);
		if (m.base != d || m.off != 0) a64_add_imm(a, d, m.base, m.off);
		a64_put(L, in.dst, d);
		break;
	}
	case xbOp_Load: {
		if (in.mem.kind == xbMem_Local && L->local_reg[in.mem.base] >= 0) {
			a64_put(L, in.dst, cast(u8)L->local_reg[in.mem.base]);
			break;
		}
		a64Lower::Stored const &st = L->stored;
		if (st.valid && st.mem.kind == in.mem.kind && st.mem.base == in.mem.base && st.mem.offset == in.mem.offset &&
		    st.size == size && st.fp == xb_type_is_float(in.type) && !(in.flags & xbInstrFlag_Volatile)) {
			if (st.fp) {
				a64_putf(L, in.dst, st.reg, size);
			} else {
				u8 d = a64_dst(L, in.dst, A64_T0);
				a64_extend(a, false, size, d, st.reg);
				a64_put(L, in.dst, d);
			}
			break;
		}
		a64Addr m = a64_mem(L, in.mem);
		if (xb_type_is_float(in.type)) {
			u8 d = a64_dstf(L, in.dst, A64_F0);
			a64_ldr_fp(a, size, d, m.base, m.off);
			a64_putf(L, in.dst, d, size);
		} else {
			u8 d = a64_dst(L, in.dst, A64_T0);
			a64_ldr(a, size, false, d, m.base, m.off);
			a64_put(L, in.dst, d);
		}
		break;
	}
	case xbOp_Store: {
		if (in.mem.kind == xbMem_Local && L->local_reg[in.mem.base] >= 0) {
			// zero extended, as a load from memory would give it back
			u8 lr = cast(u8)L->local_reg[in.mem.base];
			u8 r = a64_src(L, in.a, lr, size, xbExt_Zero);
			if (r != lr) a64_mov(a, lr, r);
			break;
		}
		// the value first, the address may need x16 and x17
		a64Lower::Stored st = {true, xb_type_is_float(in.type), 0, size, in.mem, true};
		if (st.fp) {
			st.reg = a64_srcf(L, in.a, A64_F0, size);
			a64Addr m = a64_mem(L, in.mem);
			a64_str_fp(a, size, st.reg, m.base, m.off);
		} else {
			st.reg = XZR;
			if (!a64_is_const(L, in.a, &k) || a64_ext_value(k, size, xbExt_Zero) != 0) {
				st.reg = a64_src(L, in.a, A64_T0, size, xbExt_None);
			}
			a64Addr m = a64_mem(L, in.mem);
			a64_str(a, size, st.reg, m.base, m.off);
		}
		if (!(in.flags & xbInstrFlag_Volatile)) L->stored = st;
		break;
	}
	case xbOp_Copy:
	case xbOp_Trunc:
	case xbOp_Bitcast: {
		i8 rs = L->reg[in.a];
		i8 rd = L->reg[in.dst];
		if (!L->is_const[in.a] && rs >= A64_VREG && rd >= A64_VREG) {
			if (rs != rd) a64_fmov_reg(a, cast(u8)(rd - A64_VREG), cast(u8)(rs - A64_VREG));
			break;
		}
		u8 d = a64_dst(L, in.dst, A64_T0);
		a64_put(L, in.dst, a64_src(L, in.a, d, 8, xbExt_None));
		break;
	}

	case xbOp_Add:
	case xbOp_Sub:
	case xbOp_And:
	case xbOp_Or:
	case xbOp_Xor: {
		a64AluOp op = A64_ADD;
		switch (in.op) {
		case xbOp_Add: op = A64_ADD; break;
		case xbOp_Sub: op = A64_SUB; break;
		case xbOp_And: op = A64_AND; break;
		case xbOp_Or:  op = A64_ORR; break;
		case xbOp_Xor: op = A64_EOR; break;
		}
		u32 x = in.a, y = in.b;
		if (in.op != xbOp_Sub && L->is_const[x] && !L->is_const[y]) {
			u32 t = x; x = y; y = t;
		}
		u8 d = a64_dst(L, in.dst, A64_T0);
		u8 ra = a64_src(L, x, A64_T0, size, xbExt_None);
		i32 enc = -1;
		if ((in.op == xbOp_Add || in.op == xbOp_Sub) && a64_is_const(L, y, &k) && a64_addsub_imm_ok(k)) {
			a64_addsub_imm(a, in.op == xbOp_Sub, false, d, ra, k);
		} else if (in.op != xbOp_Add && in.op != xbOp_Sub && a64_is_const(L, y, &k) && (enc = a64_logical_imm_any(cast(u64)k, size)) >= 0) {
			a64_logical_imm_op(a, op, d, ra, enc);
		} else {
			a64_alu(a, op, d, ra, a64_src(L, y, A64_T1, size, xbExt_None));
		}
		a64_put(L, in.dst, d);
		break;
	}
	case xbOp_Mul: {
		u8 ra = a64_src(L, in.a, A64_T0, size, xbExt_None);
		u8 rb = a64_src(L, in.b, A64_T1, size, xbExt_None);
		u8 d = a64_dst(L, in.dst, A64_T0);
		a64_mul(a, d, ra, rb);
		a64_put(L, in.dst, d);
		break;
	}
	case xbOp_SDiv:
	case xbOp_SRem:
	case xbOp_UDiv:
	case xbOp_URem: {
		bool sgn = in.op == xbOp_SDiv || in.op == xbOp_SRem;
		xbExtKind ext = sgn ? xbExt_Sign : xbExt_Zero;
		u8 ra = a64_src(L, in.a, A64_T0, size, ext);
		u8 rb = a64_src(L, in.b, A64_T1, size, ext);
		u8 d = a64_dst(L, in.dst, A64_T2);
		if (in.op == xbOp_SRem || in.op == xbOp_URem) {
			a64_div(a, sgn, A64_T2, ra, rb);
			a64_msub(a, d, A64_T2, rb, ra);
		} else {
			a64_div(a, sgn, d, ra, rb);
		}
		a64_put(L, in.dst, d);
		break;
	}
	case xbOp_Shl:
	case xbOp_LShr:
	case xbOp_AShr: {
		a64Shift kind = in.op == xbOp_Shl ? A64_LSL : in.op == xbOp_LShr ? A64_LSR : A64_ASR;
		u8 ra = a64_src(L, in.a, A64_T0, size, in.op == xbOp_AShr ? xbExt_Sign : xbExt_Zero);
		u8 d = a64_dst(L, in.dst, A64_T0);
		// like x86: narrow values shift as 32 bits, and the count is masked
		if (a64_is_const(L, in.b, &k)) {
			a64_shift_imm(a, kind, size == 8 ? 8 : 4, d, ra, cast(u32)k);
		} else {
			a64_shiftv(a, kind, size == 8 ? 8 : 4, d, ra, a64_src(L, in.b, A64_T1, 8, xbExt_None));
		}
		a64_put(L, in.dst, d);
		break;
	}
	case xbOp_FAdd:
	case xbOp_FSub:
	case xbOp_FMul:
	case xbOp_FDiv: {
		a64FOp op = A64_FADD;
		switch (in.op) {
		case xbOp_FAdd: op = A64_FADD; break;
		case xbOp_FSub: op = A64_FSUB; break;
		case xbOp_FMul: op = A64_FMUL; break;
		case xbOp_FDiv: op = A64_FDIV; break;
		}
		u8 ra = a64_srcf(L, in.a, A64_F0, size);
		u8 rb = a64_srcf(L, in.b, A64_F1, size);
		u8 d = a64_dstf(L, in.dst, A64_F0);
		a64_fop(a, op, size, d, ra, rb);
		a64_putf(L, in.dst, d, size);
		break;
	}
	case xbOp_Sqrt:
	case xbOp_FNeg: {
		u8 r = a64_srcf(L, in.a, A64_F0, size);
		u8 d = a64_dstf(L, in.dst, A64_F0);
		if (in.op == xbOp_Sqrt) a64_fsqrt(a, size, d, r);
		else                    a64_fneg(a, size, d, r);
		a64_putf(L, in.dst, d, size);
		break;
	}
	case xbOp_Neg:
	case xbOp_Not: {
		u8 r = a64_src(L, in.a, A64_T0, size, xbExt_None);
		u8 d = a64_dst(L, in.dst, A64_T0);
		a64_alu(a, in.op == xbOp_Neg ? A64_SUB : A64_ORN, d, XZR, r);
		a64_put(L, in.dst, d);
		break;
	}
	case xbOp_ICmp: {
		xbCond c = cast(xbCond)in.aux;
		if (in.a == L->flags_vreg) {
			// a test against zero of the compare that set the flags
			GB_ASSERT(c == xbCond_EQ || c == xbCond_NE);
			a64Cond cc = c == xbCond_NE ? L->flags_cond : a64_invert(L->flags_cond);
			L->flags_vreg = 0;
			a64_compare_result(L, in, cc);
			break;
		}
		xbExtKind ext = a64_cond_is_signed(c) ? xbExt_Sign : xbExt_Zero;
		u8 ra = a64_src(L, in.a, A64_T0, size, ext);
		if (a64_is_const(L, in.b, &k) && a64_addsub_imm_ok(a64_ext_value(k, size, ext))) {
			a64_addsub_imm(a, true, true, XZR, ra, a64_ext_value(k, size, ext));
		} else {
			a64_cmp(a, ra, a64_src(L, in.b, A64_T1, size, ext));
		}
		a64_compare_result(L, in, a64_cond_for(c));
		break;
	}
	case xbOp_FCmp: {
		u8 ra = a64_srcf(L, in.a, A64_F0, size);
		u8 rb = a64_srcf(L, in.b, A64_F1, size);
		a64_fcmp(a, size, ra, rb);
		a64_compare_result(L, in, a64_cond_for(cast(xbCond)in.aux));
		break;
	}
	case xbOp_Zext:
	case xbOp_Sext: {
		xbType src = cast(xbType)in.aux;
		u8 d = a64_dst(L, in.dst, A64_T0);
		a64_put(L, in.dst, a64_src(L, in.a, d, xb_type_size(src), in.op == xbOp_Sext ? xbExt_Sign : xbExt_Zero));
		break;
	}
	case xbOp_SIToF:
	case xbOp_UIToF: {
		bool sgn = in.op == xbOp_SIToF;
		xbType src = cast(xbType)in.aux;
		u8 r = a64_src(L, in.a, A64_T0, xb_type_size(src), sgn ? xbExt_Sign : xbExt_Zero);
		u8 d = a64_dstf(L, in.dst, A64_F0);
		a64_cvtf(a, sgn, size, d, r);
		a64_putf(L, in.dst, d, size);
		break;
	}
	case xbOp_FToSI:
	case xbOp_FToUI: {
		i32 fs = xb_type_size(cast(xbType)in.aux);
		u8 r = a64_srcf(L, in.a, A64_F0, fs);
		u8 d = a64_dst(L, in.dst, A64_T0);
		a64_fcvtz(a, in.op == xbOp_FToSI, fs, d, r);
		a64_put(L, in.dst, d);
		break;
	}
	case xbOp_FExt:
	case xbOp_FTrunc:
	case xbOp_FToHalf:
	case xbOp_HalfToF: {
		i32 from = 0, to = 0;
		switch (in.op) {
		case xbOp_FExt:    from = 4; to = 8; break;
		case xbOp_FTrunc:  from = 8; to = 4; break;
		case xbOp_FToHalf: from = xb_type_size(cast(xbType)in.aux); to = 2; break;
		case xbOp_HalfToF: from = 2; to = 4; break;
		}
		u8 r = a64_srcf(L, in.a, A64_F0, from);
		u8 d = a64_dstf(L, in.dst, A64_F0);
		a64_fcvt(a, to, from, d, r);
		a64_putf(L, in.dst, d, to);
		break;
	}
	case xbOp_Select: {
		a64Cond cc = A64_NE;
		if (in.a == L->flags_vreg) {
			cc = L->flags_cond;
			L->flags_vreg = 0;
		} else {
			i32 test = a64_test_bool(L, in.a);
			if (test >= 0) a64_cmp_imm32(a, cast(u8)test, 0);
		}
		// nothing below changes the flags
		if (xb_type_is_float(in.type)) {
			u8 rb = a64_srcf(L, in.b, A64_F0, size);
			u8 rc = a64_srcf(L, in.c, A64_F1, size);
			u8 d = a64_dstf(L, in.dst, A64_F0);
			a64_fcsel(a, d, rb, rc, cc);
			a64_putf(L, in.dst, d, size);
		} else {
			u8 rb = a64_src(L, in.b, A64_T1, 8, xbExt_None);
			u8 rc = a64_src(L, in.c, A64_T2, 8, xbExt_None);
			u8 d = a64_dst(L, in.dst, A64_T1);
			a64_csel(a, d, rb, rc, cc);
			a64_put(L, in.dst, d);
		}
		break;
	}

	case xbOp_MemCopy:
	case xbOp_MemMove: {
		i64 n = in.imm;
		u8 dst = a64_src(L, in.a, A64_T3, 8, xbExt_None);
		u8 src = a64_src(L, in.b, A64_T4, 8, xbExt_None);
		if (n <= A64_INLINE_COPY) {
			// load everything, then store everything: overlap safe
			struct Chunk { i32 size; i64 off; u8 reg; bool fp; };
			Chunk chunks[8] = {};
			u8 const gprs[4] = {A64_T0, A64_T1, A64_T2, A64_T5};
			i32 count = 0, nq = 0, ng = 0;
			for (i64 off = 0; off < n;) {
				i64 rem = n - off;
				i32 c = rem >= 16 ? 16 : rem >= 8 ? 8 : rem >= 4 ? 4 : rem >= 2 ? 2 : 1;
				Chunk ch = {c, off, 0, c == 16};
				ch.reg = ch.fp ? cast(u8)(A64_F0 + nq++) : gprs[ng++];
				chunks[count++] = ch;
				off += c;
			}
			for (i32 i = 0; i < count; i++) {
				if (chunks[i].fp) a64_ldr_fp(a, 16, chunks[i].reg, src, chunks[i].off);
				else              a64_ldr(a, chunks[i].size, false, chunks[i].reg, src, chunks[i].off);
			}
			for (i32 i = 0; i < count; i++) {
				if (chunks[i].fp) a64_str_fp(a, 16, chunks[i].reg, dst, chunks[i].off);
				else              a64_str(a, chunks[i].size, chunks[i].reg, dst, chunks[i].off);
			}
		} else {
			a64_mov(a, X0, dst);
			a64_mov(a, X1, src);
			a64_mov_imm(a, X2, cast(u64)n);
			a64_call_libc(L, "memmove");
		}
		break;
	}
	case xbOp_MemZero: {
		i64 n = in.imm;
		a64Addr m = a64_mem(L, in.mem);
		if (n <= A64_INLINE_ZERO) {
			for (i64 off = 0; off < n;) {
				i64 rem = n - off;
				i32 c = rem >= 8 ? 8 : rem >= 4 ? 4 : rem >= 2 ? 2 : 1;
				a64_str(a, c, XZR, m.base, m.off + off);
				off += c;
			}
		} else {
			a64_add_imm(a, X0, m.base, m.off);
			a64_mov_imm(a, X1, 0);
			a64_mov_imm(a, X2, cast(u64)n);
			a64_call_libc(L, "memset");
		}
		break;
	}
	case xbOp_MemCopyDyn:
	case xbOp_MemMoveDyn:
		a64_get(L, X0, in.a, 8, xbExt_None);
		a64_get(L, X1, in.b, 8, xbExt_None);
		a64_get(L, X2, in.c, 8, xbExt_None);
		a64_call_libc(L, "memmove");
		break;
	case xbOp_MemSetDyn:
		a64_get(L, X0, in.a, 8, xbExt_None);
		a64_get(L, X1, in.b, 1, xbExt_Zero);
		a64_get(L, X2, in.c, 8, xbExt_None);
		a64_call_libc(L, "memset");
		break;

	case xbOp_Call:
		a64_lower_call(L, p->calls[cast(isize)in.imm], false);
		break;
	case xbOp_Jump:
		a64_jump(L, cast(i32)in.imm);
		break;
	case xbOp_Branch: {
		i32 t = cast(i32)in.imm;
		i32 f = cast(i32)in.c;
		if (in.a == L->flags_vreg) {
			L->flags_vreg = 0;
			a64_branch(L, L->flags_cond, -1, t, f);
		} else if (a64_is_const(L, in.a, &k)) {
			a64_jump(L, (k & 0xff) ? t : f);
		} else {
			a64_branch(L, A64_NE, a64_test_bool(L, in.a), t, f);
		}
		break;
	}
	case xbOp_Ret:
		a64_lower_call(L, p->calls[cast(isize)in.imm], true);
		a64_epilogue(L);
		break;
	case xbOp_Unreachable:
	case xbOp_Trap:
		a64_brk(a, 1);
		break;
	case xbOp_DebugTrap:
		a64_brk(a, 0xf000);
		break;
	case xbOp_CpuRelax:
		a64_emit(a, 0xD503203F); // yield
		break;
	case xbOp_Prefetch:
		break;
	case xbOp_ReadCycleCounter: {
		u8 d = a64_dst(L, in.dst, A64_T0);
		if (in.imm) {
			a64_emit(a, 0xD53BE000 | d); // mrs xd, cntfrq_el0
		} else {
			a64_emit(a, 0xD53BE040 | d); // mrs xd, cntvct_el0
		}
		a64_put(L, in.dst, d);
		break;
	}
	case xbOp_Vec128: {
		a64_ldr_fp(a, 16, 16, a64_src(L, in.a, A64_TA, 8, xbExt_None), 0);
		a64_ldr_fp(a, 16, 17, a64_src(L, in.b, A64_TA, 8, xbExt_None), 0);
		if (in.c) a64_ldr_fp(a, 16, 18, a64_src(L, in.c, A64_TA, 8, xbExt_None), 0);
		a64_vec_intrinsic(a, in.aux);
		a64Addr m = a64_mem(L, in.mem);
		a64_str_fp(a, 16, 16, m.base, m.off);
		break;
	}
	case xbOp_StackPointer: {
		u8 d = a64_dst(L, in.dst, A64_T0);
		a64_mov_sp(a, d, A64_SP);
		a64_put(L, in.dst, d);
		break;
	}
	case xbOp_FrameAddress:
		a64_put(L, in.dst, A64_FP);
		break;
	case xbOp_ReturnAddress: {
		u8 d = a64_dst(L, in.dst, A64_T0);
		if (in.imm) {
			a64_add_imm(a, d, A64_FP, 8);
		} else {
			a64_ldr(a, 8, false, d, A64_FP, 8);
		}
		a64_put(L, in.dst, d);
		break;
	}
	case xbOp_TlsAddr: {
		// the variable's descriptor holds a function that returns its address in x0
		i32 sym = cast(i32)in.imm;
		a64_adrp(a, X0, sym, xbReloc_A64_TlvPage21);
		a64_ldr_pageoff(a, X0, X0, sym, xbReloc_A64_TlvPageOff12);
		a64_ldr(a, 8, false, A64_TA, X0, 0);
		a64_blr(a, A64_TA);
		a64_put(L, in.dst, X0);
		break;
	}
	case xbOp_Alloca: {
		// the block goes above the outgoing argument area, which moves down with sp
		i32 args_area = cast(i32)xb_lt_align_formula(L->max_call_stack, 16);
		u32 shift = 0;
		while ((cast(i64)1 << shift) < in.imm) shift++;
		u8 n = a64_src(L, in.a, A64_T1, 8, xbExt_None);
		a64_add_imm(a, A64_T0, A64_SP, args_area);
		a64_alu(a, A64_SUB, A64_T0, A64_T0, n);
		a64_lsr_imm(a, A64_T0, A64_T0, shift);
		a64_lsl_imm(a, A64_T0, A64_T0, shift);
		a64_add_imm(a, A64_SP, A64_T0, -args_area);
		a64_put(L, in.dst, A64_T0);
		break;
	}
	case xbOp_AtomicFence:
		a64_dmb_ish(a);
		break;
	case xbOp_AtomicLoad: {
		a64Addr m = a64_mem(L, in.mem);
		a64_add_imm(a, A64_TA, m.base, m.off);
		u8 d = a64_dst(L, in.dst, A64_T0);
		a64_ldar(a, size, d, A64_TA);
		a64_put(L, in.dst, d);
		break;
	}
	case xbOp_AtomicStore: {
		u8 r = a64_src(L, in.a, A64_T0, size, xbExt_None);
		a64Addr m = a64_mem(L, in.mem);
		a64_add_imm(a, A64_TA, m.base, m.off);
		a64_stlr(a, size, r, A64_TA);
		break;
	}
	case xbOp_AtomicRmw: {
		xbRmwOp op = cast(xbRmwOp)in.aux;
		u8 rv = a64_src(L, in.a, A64_T1, size, xbExt_Zero);
		a64Addr m = a64_mem(L, in.mem);
		a64_add_imm(a, A64_TA, m.base, m.off);
		switch (op) {
		case xbRmw_Xchg: a64_lse(a, A64_SWP, size, rv, A64_T0, A64_TA); break;
		case xbRmw_Add:  a64_lse(a, A64_LDADD, size, rv, A64_T0, A64_TA); break;
		case xbRmw_Or:   a64_lse(a, A64_LDSET, size, rv, A64_T0, A64_TA); break;
		case xbRmw_Xor:  a64_lse(a, A64_LDEOR, size, rv, A64_T0, A64_TA); break;
		case xbRmw_Sub:
			a64_alu(a, A64_SUB, A64_T1, XZR, rv);
			a64_lse(a, A64_LDADD, size, A64_T1, A64_T0, A64_TA);
			break;
		case xbRmw_And:
			a64_alu(a, A64_ORN, A64_T1, XZR, rv);
			a64_lse(a, A64_LDCLR, size, A64_T1, A64_T0, A64_TA);
			break;
		case xbRmw_Nand: {
			// no instruction for it: a compare and swap loop
			a64_ldr(a, size, false, A64_T0, A64_TA, 0);
			i64 loop = xb_pos(a);
			a64_mov(a, A64_T2, A64_T0);
			a64_alu(a, A64_AND, A64_T3, A64_T0, rv);
			a64_alu(a, A64_ORN, A64_T3, XZR, A64_T3);
			a64_casal(a, size, A64_T2, A64_T3, A64_TA);
			a64_cmp(a, A64_T2, A64_T0);
			a64_mov(a, A64_T0, A64_T2);
			a64_bcond_to(a, A64_NE, loop);
			break;
		}
		}
		a64_put(L, in.dst, A64_T0);
		break;
	}
	case xbOp_AtomicCas: {
		u8 expected = a64_src(L, in.a, A64_T0, size, xbExt_Zero);
		u8 desired = a64_src(L, in.b, A64_T1, size, xbExt_Zero);
		a64Addr m = a64_mem(L, in.mem);
		a64_add_imm(a, A64_TA, m.base, m.off);
		a64_mov(a, A64_T2, expected);
		a64_casal(a, size, A64_T2, desired, A64_TA);
		a64_cmp(a, A64_T2, expected);
		a64_cset(a, A64_T3, A64_EQ);
		a64_put(L, in.dst, A64_T2);
		a64_put(L, in.c, A64_T3);
		break;
	}
	case xbOp_Syscall: {
		// Darwin: the number in x16, the arguments in x0-x5, the result in x0
		xbCall const &c = p->calls[cast(isize)in.imm];
		a64_lower_call(L, c, true);
		a64_emit(a, 0xD4001001); // svc #0x80
		a64_put(L, c.result_vreg, X0);
		break;
	}
	case xbOp_MulHiU: {
		u8 ra = a64_src(L, in.a, A64_T0, 8, xbExt_None);
		u8 rb = a64_src(L, in.b, A64_T1, 8, xbExt_None);
		u8 d = a64_dst(L, in.dst, A64_T0);
		a64_umulh(a, d, ra, rb);
		a64_put(L, in.dst, d);
		break;
	}
	case xbOp_MulOvf: {
		bool sgn = in.aux != 0;
		GB_ASSERT(size == 4 || size == 8);
		xbExtKind ext = sgn ? xbExt_Sign : xbExt_Zero;
		u8 ra = a64_src(L, in.a, A64_T0, size, ext);
		u8 rb = a64_src(L, in.b, A64_T1, size, ext);
		a64_mul(a, A64_T2, ra, rb);
		if (size == 8) {
			if (sgn) {
				a64_smulh(a, A64_T3, ra, rb);
				a64_alu(a, A64_SUBS, XZR, A64_T3, A64_T2, A64_ASR, 63);
			} else {
				a64_umulh(a, A64_T3, ra, rb);
				a64_cmp(a, A64_T3, XZR);
			}
		} else {
			// the 64 bit product of the extended values is exact
			if (sgn) {
				a64_extend(a, true, 4, A64_T3, A64_T2);
				a64_cmp(a, A64_T2, A64_T3);
			} else {
				a64_lsr_imm(a, A64_T3, A64_T2, 32);
				a64_cmp(a, A64_T3, XZR);
			}
		}
		a64_cset(a, A64_T3, A64_NE);
		a64_put(L, in.dst, A64_T2);
		a64_put(L, in.c, A64_T3);
		break;
	}
	case xbOp_Bswap: {
		u8 r = a64_src(L, in.a, A64_T0, size, xbExt_Zero);
		u8 d = a64_dst(L, in.dst, A64_T0);
		if (size > 1) a64_rev(a, size, d, r);
		else if (d != r) a64_mov(a, d, r);
		a64_put(L, in.dst, d);
		break;
	}
	case xbOp_Popcount: {
		u8 r = a64_src(L, in.a, A64_T0, size, xbExt_Zero);
		a64_fmov_to_fp(a, A64_F0, r);
		a64_cnt8b(a, A64_F0, A64_F0);
		a64_addv8b(a, A64_F0, A64_F0);
		u8 d = a64_dst(L, in.dst, A64_T0);
		a64_fmov_from_fp(a, d, A64_F0);
		a64_put(L, in.dst, d);
		break;
	}
	case xbOp_Ctz: {
		u8 r = a64_src(L, in.a, A64_T0, size, xbExt_Zero);
		if (size < 8) {
			// a bit just above the value makes zero count as the width
			a64_mov_imm(a, A64_T1, 1ull << (8*size));
			a64_alu(a, A64_ORR, A64_T0, r, A64_T1);
			r = A64_T0;
		}
		a64_rbit(a, A64_T0, r);
		u8 d = a64_dst(L, in.dst, A64_T0);
		a64_clz(a, d, A64_T0);
		a64_put(L, in.dst, d);
		break;
	}
	case xbOp_Clz: {
		u8 r = a64_src(L, in.a, A64_T0, size, xbExt_Zero);
		u8 d = a64_dst(L, in.dst, A64_T0);
		a64_clz(a, d, r);
		if (size < 8) a64_add_imm(a, d, d, -(64 - 8*size));
		a64_put(L, in.dst, d);
		break;
	}
	default:
		GB_PANIC("a64: cannot lower op %d", in.op);
	}
}

////////////////////////////////////////////////////////////////
// Procedures
////////////////////////////////////////////////////////////////

// Whether `in` is a compare whose result only feeds the next instruction `n` through the flags.
gb_internal bool a64_can_fuse(a64Lower *L, xbInstr const &in, xbInstr const &n) {
	if (in.op != xbOp_ICmp && in.op != xbOp_FCmp) return false;
	u32 v = in.dst;
	if (v == 0 || L->uses[v] != 1 || !L->in_block[v]) return false;
	switch (n.op) {
	case xbOp_Branch:
	case xbOp_Select:
		return n.a == v;
	case xbOp_ICmp: {
		i64 k = 0;
		xbCond c = cast(xbCond)n.aux;
		return n.a == v && (c == xbCond_EQ || c == xbCond_NE) &&
		       a64_is_const(L, n.b, &k) && a64_ext_value(k, xb_type_size(n.type), xbExt_Zero) == 0;
	}
	}
	return false;
}

// Lowers p, or returns false when a conditional branch cannot reach its target unless `far`.
gb_internal bool a64_lower_proc_with(xbProc *p, bool far) {
	xbModule *m = p->m;
	a64Lower L = {};
	L.p = p;
	L.far = far;
	L.a.m = m;
	L.a.code = &m->sections[xbSection_Text];
	L.fixups = array_make<a64Lower::Fixup>(heap_allocator(), 0, 64);
	defer (array_free(&L.fixups));
	defer (array_free(&L.slot));
	defer (array_free(&L.uses));
	defer (array_free(&L.reg));
	defer (array_free(&L.is_const));
	defer (array_free(&L.cval));
	defer (array_free(&L.in_block));
	defer (array_free(&L.clean));
	defer (array_free(&L.local_reg));
	defer (array_free(&L.via));
	defer (array_free(&L.remat));
	defer (array_free(&L.rmem));

	a64_lower_layout(&L);

	xbAsm *a = &L.a;
	// 16 byte aligned procedure starts, like LLVM's
	while (a->code->count % 16 != 0) {
		a64_emit(a, 0xD4200020); // brk #1
	}
	L.proc_start = xb_pos(a);

	xbSymbol *sym = &m->symbols[p->sym];
	sym->section = xbSection_Text;
	sym->offset = L.proc_start;
	sym->flags |= xbSymbolFlag_Func;

	i32 line_entry_start = cast(i32)m->lines.count;

	// prologue
	a64_emit(a, 0xA9BF7BFD); // stp x29, x30, [sp, #-16]!
	a64_mov_sp(a, A64_FP, A64_SP);
	if (L.frame_size > 0) {
		a64_add_imm(a, A64_SP, A64_SP, -L.frame_size);
	}
	a64_for_each_pair(L.pairs, [&](u8 lo, u8 hi, bool fp, i32 off) {
		a64_pair(a, fp, false, hi, lo, A64_FP, off);
	});
	i32 saved_at = cast(i32)(xb_pos(a) - L.proc_start);
	for (xbLocal const &l : p->locals) {
		if (l.over_align <= 16) continue;
		u32 shift = 0;
		while ((cast(i64)1 << shift) < l.over_align) shift++;
		a64_add_imm(a, A64_TA, A64_FP, l.raw_offset + l.over_align - 1);
		a64_lsr_imm(a, A64_TA, A64_TA, shift);
		a64_lsl_imm(a, A64_TA, A64_TA, shift);
		a64_str(a, 8, A64_TA, A64_FP, l.frame_offset);
	}
	for (xbParamIn const &in : p->params_in) {
		if (in.dst.kind == xbMem_Local && L.local_reg[in.dst.base] >= 0) continue;
		a64Addr dst = a64_mem(&L, in.dst);
		switch (in.loc) {
		case xbLoc_Gpr:
			a64_store_bytes(&L, dst, in.reg, in.size);
			break;
		case xbLoc_Xmm:
			a64_str_fp(a, in.size, in.reg, dst.base, dst.off);
			break;
		case xbLoc_Stack: {
			a64Addr src = {A64_FP, 16 + in.stack_offset};
			if (in.size == 16) {
				a64_ldr_fp(a, 16, A64_F0, src.base, src.off);
				a64_str_fp(a, 16, A64_F0, dst.base, dst.off);
			} else {
				a64_load_bytes(&L, A64_T0, src, in.size, xbExt_None);
				a64_store_bytes(&L, dst, A64_T0, in.size);
			}
			break;
		}
		}
	}
	// the promoted ones stay in the register they arrive in or move to a callee saved one
	for (xbParamIn const &in : p->params_in) {
		if (in.dst.kind != xbMem_Local || L.local_reg[in.dst.base] < 0) continue;
		u8 lr = cast(u8)L.local_reg[in.dst.base];
		if (in.loc == xbLoc_Gpr) {
			a64_extend(a, false, in.size, lr, in.reg);
		} else {
			GB_ASSERT(in.loc == xbLoc_Stack);
			a64_ldr(a, in.size, false, lr, A64_FP, 16 + in.stack_offset);
		}
	}

	// constants materialized at their uses and unread pure values emit nothing
	auto skipped = [&](xbInstr const &n) -> bool {
		if (n.op == xbOp_IConst && n.dst != 0 && L.is_const[n.dst]) return true;
		return n.dst != 0 && L.uses[n.dst] == 0 && xb_op_is_pure(n.op);
	};
	// the next instruction that emits code
	auto next_code = [&](xbBlock *b, isize i) -> isize {
		for (isize j = i+1; j < b->instrs.count; j++) {
			xbInstr const &n = b->instrs[j];
			if (n.op == xbOp_Loc || n.op == xbOp_Scope || n.op == xbOp_Nop || skipped(n)) continue;
			return j;
		}
		return -1;
	};

	// cold blocks go last, so the hot path falls through
	auto order = array_make<xbBlock *>(heap_allocator(), 0, p->order.count);
	defer (array_free(&order));
	for (xbBlock *b : p->order) if (!b->cold) array_add(&order, b);
	for (xbBlock *b : p->order) if (b->cold)  array_add(&order, b);

	auto scope_marks = array_make<xbScopeMark>(heap_allocator(), 0, 16);
	for (isize bi = 0; bi < order.count; bi++) {
		xbBlock *b = order[bi];
		i32 next_block = bi+1 < order.count ? order[bi+1]->index : -1;
		b->code_offset = cast(i32)xb_pos(a);
		xbScopeMark mark = {cast(i32)(xb_pos(a) - L.proc_start), b->debug_scope, b->cold};
		array_add(&scope_marks, mark);
		for (isize i = 0; i < b->instrs.count; i++) {
			xbInstr const &in = b->instrs[i];
			if (in.op == xbOp_Scope) {
				xbScopeMark mark = {cast(i32)(xb_pos(a) - L.proc_start), cast(i32)in.imm, b->cold};
				array_add(&scope_marks, mark);
				continue;
			}
			// a jump to the next block is a fallthrough
			if (in.op == xbOp_Jump && i+1 == b->instrs.count && cast(i32)in.imm == next_block) {
				continue;
			}
			if (skipped(in)) continue;
			if (in.op == xbOp_Loc || in.op == xbOp_Nop) {
				a64_lower_instr(&L, in);
				continue;
			}
			L.next_block = i+1 == b->instrs.count ? next_block : -1;
			L.fuse = false;
			if (in.op == xbOp_ICmp || in.op == xbOp_FCmp) {
				isize j = next_code(b, i);
				L.fuse = j >= 0 && a64_can_fuse(&L, in, b->instrs[j]);
			}
			u32 flags = L.flags_vreg;
			// only the instruction right after a store sees it
			L.stored.valid = L.stored.fresh;
			L.stored.fresh = false;
			a64_lower_instr(&L, in);
			GB_ASSERT_MSG(flags == 0 || L.flags_vreg != flags, "a64: op %d did not read the flags", in.op);
		}
		L.stored = {};
		GB_ASSERT(L.flags_vreg == 0);
	}
	for (auto const &f : L.fixups) {
		xbBlock *target = p->blocks[f.block];
		GB_ASSERT_MSG(target->placed, "jump to an unplaced block in %.*s", LIT(p->name));
		if (!f.imm19) {
			a64_patch_b(a, f.at, target->code_offset);
		} else if (!a64_patch_imm19(a, f.at, target->code_offset)) {
			array_free(&scope_marks);
			return false;
		}
	}

	xbProcDebug dbg = {};
	dbg.name = p->entity ? p->entity->token.string : p->name;
	dbg.link_name = p->name;
	dbg.sym = p->sym;
	dbg.start = L.proc_start;
	dbg.end = xb_pos(a);
	dbg.file_id = p->file_id;
	dbg.line = p->entity ? p->entity->token.pos.line : 0;
	dbg.line_entry_start = line_entry_start;
	dbg.line_entry_count = cast(i32)(m->lines.count - line_entry_start);
	dbg.type = p->type;
	dbg.saved_at = saved_at;
	dbg.scope_marks = scope_marks;
	sym->size = dbg.end - dbg.start;

	// dwarf numbers x19-x28 as themselves and d8-d15 as 72-79
	dbg.saved_regs = array_make<xbProcDebug::SavedReg>(heap_allocator(), 0, 0);
	a64_for_each_pair(L.pairs, [&](u8 lo, u8 hi, bool fp, i32 off) {
		xbProcDebug::SavedReg r_lo = {(fp ? 64 : 0) + lo, off + 8};
		xbProcDebug::SavedReg r_hi = {(fp ? 64 : 0) + hi, off};
		array_add(&dbg.saved_regs, r_lo);
		array_add(&dbg.saved_regs, r_hi);
	});

	// debug variables, now that frame offsets are known
	dbg.vars = array_make<xbDebugVar>(heap_allocator(), 0, p->debug_vars.count);
	dbg.scope_parent = array_make<i32>(heap_allocator(), 0, p->debug_scope_parent.count);
	array_add_elems(&dbg.scope_parent, p->debug_scope_parent.data, p->debug_scope_parent.count);
	dbg.inline_sites = array_make<xbInlineSite>(heap_allocator(), 0, p->inline_sites.count);
	array_add_elems(&dbg.inline_sites, p->inline_sites.data, p->inline_sites.count);
	for (xbDebugVar v : p->debug_vars) {
		if (v.local >= 0) {
			xbLocal const &l = p->locals[v.local];
			if (l.over_align > 16) {
				// the slot holds the variable's address
				if (v.by_ref || v.frame_offset_fixup != 0) continue;
				v.by_ref = true;
			}
			v.frame_offset_fixup += l.frame_offset;
			if (L.local_reg[v.local] >= 0) {
				v.in_reg = true;
				v.dwarf_reg = L.local_reg[v.local];
			}
		}
		array_add(&dbg.vars, v);
	}
	array_add(&m->proc_debug, dbg);
	return true;
}

gb_internal void a64_lower_proc(xbProc *p) {
	xbModule *m = p->m;
	isize text = m->sections[xbSection_Text].count;
	isize relocs = m->relocs.count;
	isize lines = m->lines.count;
	if (a64_lower_proc_with(p, false)) {
		return;
	}
	// a conditional branch is out of range: start over with ones that reach anywhere
	m->sections[xbSection_Text].count = text;
	m->relocs.count = relocs;
	m->lines.count = lines;
	bool ok = a64_lower_proc_with(p, true);
	GB_ASSERT(ok);
}
