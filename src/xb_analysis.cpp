// Analyses of a procedure's xb IR that the x86-64 and arm64 lowerings share.

template <typename F>
gb_internal void xb_for_each_vreg(xbProc *p, xbInstr const &in, F const &f) {
	// f(vreg, is_def)
	auto use_mem = [&](xbMem const &m) {
		if (m.kind == xbMem_Reg) f(m.base, false);
	};
	switch (in.op) {
	case xbOp_Nop:
	case xbOp_Loc:
	case xbOp_Scope:
	case xbOp_Jump:
	case xbOp_Unreachable:
	case xbOp_Trap:
	case xbOp_DebugTrap:
	case xbOp_AtomicFence:
	case xbOp_CpuRelax:
		break;
	case xbOp_IConst:
	case xbOp_FConst:
	case xbOp_ReadCycleCounter:
	case xbOp_StackPointer:
	case xbOp_FrameAddress:
	case xbOp_ReturnAddress:
		f(in.dst, true);
		break;
	case xbOp_Lea:
	case xbOp_Load:
	case xbOp_AtomicLoad:
		use_mem(in.mem);
		f(in.dst, true);
		break;
	case xbOp_Store:
	case xbOp_AtomicStore:
		f(in.a, false);
		use_mem(in.mem);
		break;
	case xbOp_MemZero:
	case xbOp_Prefetch:
		use_mem(in.mem);
		break;
	case xbOp_MemCopy:
	case xbOp_MemMove:
		f(in.a, false);
		f(in.b, false);
		break;
	case xbOp_MemCopyDyn:
	case xbOp_MemMoveDyn:
	case xbOp_MemSetDyn:
		f(in.a, false);
		f(in.b, false);
		f(in.c, false);
		break;
	case xbOp_Select:
	case xbOp_Fma:
		f(in.a, false);
		f(in.b, false);
		f(in.c, false);
		f(in.dst, true);
		break;
	case xbOp_Branch:
		f(in.a, false);
		break;
	case xbOp_AtomicRmw:
		f(in.a, false);
		use_mem(in.mem);
		f(in.dst, true);
		break;
	case xbOp_AtomicCas:
		f(in.a, false);
		f(in.b, false);
		use_mem(in.mem);
		f(in.dst, true);
		f(in.c, true);
		break;
	case xbOp_Cpuid:
	case xbOp_Xgetbv:
		f(in.a, false);
		f(in.b, false);
		use_mem(in.mem);
		break;
	case xbOp_Vec128:
		if (in.a) f(in.a, false);
		if (in.b) f(in.b, false);
		if (in.c) f(in.c, false);
		use_mem(in.mem);
		break;
	case xbOp_Valgrind:
		f(in.a, false);
		f(in.b, false);
		f(in.dst, true);
		break;
	case xbOp_TlsAddr:
		f(in.dst, true);
		break;
	case xbOp_Alloca:
		f(in.a, false);
		f(in.dst, true);
		break;
	case xbOp_MulOvf:
		f(in.a, false);
		f(in.b, false);
		f(in.dst, true);
		f(in.c, true);
		break;
	case xbOp_Asm: {
		xbAsmBlock const &blk = p->asms[cast(isize)in.imm];
		for (xbAsmIo const &io : blk.inputs) f(io.vreg, false);
		for (xbAsmIo const &io : blk.outputs) f(io.vreg, io.kind != xbAsmIo_XmmMem);
		break;
	}
	case xbOp_Call:
	case xbOp_Ret:
	case xbOp_Syscall: {
		xbCall const &c = p->calls[cast(isize)in.imm];
		if (c.target_vreg) f(c.target_vreg, false);
		for (xbCallArg const &arg : c.args) {
			switch (arg.kind) {
			case xbCallArg_Gpr:
			case xbCallArg_Xmm:
			case xbCallArg_Stack:
				f(arg.vreg, false);
				break;
			default:
				use_mem(arg.mem);
				break;
			}
		}
		for (xbCallRet const &r : c.rets) {
			use_mem(r.dst);
		}
		if (in.op == xbOp_Syscall) f(c.result_vreg, true);
		break;
	}
	default:
		// unary and binary ops
		f(in.a, false);
		if (in.op >= xbOp_Add && in.op <= xbOp_FDiv) f(in.b, false);
		if (in.op == xbOp_MulHiU) f(in.b, false);
		if (in.op == xbOp_ICmp || in.op == xbOp_FCmp) f(in.b, false);
		f(in.dst, true);
		break;
	}
}

// Whether the op only computes its result, so it can be skipped when nothing reads it.
// Loads and divisions stay, they can fault.
gb_internal bool xb_op_is_pure(xbOp op) {
	switch (op) {
	case xbOp_IConst:
	case xbOp_FConst:
	case xbOp_Lea:
	case xbOp_Copy:
	case xbOp_Add:
	case xbOp_Sub:
	case xbOp_Mul:
	case xbOp_And:
	case xbOp_Or:
	case xbOp_Xor:
	case xbOp_Shl:
	case xbOp_LShr:
	case xbOp_AShr:
	case xbOp_FAdd:
	case xbOp_FSub:
	case xbOp_FMul:
	case xbOp_FDiv:
	case xbOp_Neg:
	case xbOp_Not:
	case xbOp_FNeg:
	case xbOp_ICmp:
	case xbOp_FCmp:
	case xbOp_Zext:
	case xbOp_Sext:
	case xbOp_Trunc:
	case xbOp_SIToF:
	case xbOp_UIToF:
	case xbOp_FToSI:
	case xbOp_FToUI:
	case xbOp_FExt:
	case xbOp_FTrunc:
	case xbOp_Bitcast:
	case xbOp_Select:
	case xbOp_Fma:
		return true;
	}
	return false;
}

// The scalar locals that can live in a register, heaviest first. A local qualifies when
// every access is a plain whole-value load or store, all int or all float, so nothing can see
// its memory. `is_float` tells which locals hold a float.
// Each access weighs `loop_weight` inside a loop and `other_weight` elsewhere, and a
// local needs more than `min_weight`.
struct xbRankedLocal { i32 weight; i32 index; };

// heavier first, then in order
gb_internal GB_COMPARE_PROC(xb_ranked_local_cmp) {
	xbRankedLocal const *x = cast(xbRankedLocal const *)a;
	xbRankedLocal const *y = cast(xbRankedLocal const *)b;
	if (x->weight != y->weight) return x->weight > y->weight ? -1 : 1;
	return x->index < y->index ? -1 : x->index > y->index;
}

// With `call_mem`, a call may read a local as a whole register argument, and a call with one
// result may write it to one. With `by_ref_reg`, a local can hold a debug variable's address.
gb_internal bool xb_call_mem_is_local(xbProc *p, xbMem const &m, i32 size) {
	return m.kind == xbMem_Local && m.offset == 0 && p->locals[m.base].size == size;
}

// Per block in p->order, whether it is in a loop: a later block jumps back to or before it.
gb_internal void xb_blocks_in_loops(xbProc *p, Array<bool> *in_loop) {
	isize bc = p->order.count;
	*in_loop = array_make<bool>(xb_allocator(), bc);
	auto pos = array_make<isize>(xb_allocator(), p->blocks.count);
	// the loops starting at each block minus those ending before it, summed up below
	auto diff = array_make<i32>(xb_allocator(), bc + 1);
	defer (array_free(&pos));
	defer (array_free(&diff));
	for (isize i = 0; i < bc; i++) pos[p->order[i]->index] = i;
	for (isize i = 0; i < bc; i++) {
		for (xbInstr const &in : p->order[i]->instrs) {
			i32 targets[2] = {-1, -1};
			if (in.op == xbOp_Jump) targets[0] = cast(i32)in.imm;
			if (in.op == xbOp_Branch) { targets[0] = cast(i32)in.imm; targets[1] = cast(i32)in.c; }
			for (i32 t : targets) {
				if (t < 0 || !p->blocks[t]->placed || pos[t] > i) continue;
				diff[pos[t]] += 1;
				diff[i+1] -= 1;
			}
		}
	}
	i32 loops = 0;
	for (isize i = 0; i < bc; i++) {
		loops += diff[i];
		(*in_loop)[i] = loops > 0;
	}
}

gb_internal void xb_rank_promotable_locals(xbProc *p, i32 loop_weight, i32 other_weight, i32 min_weight, Array<i32> *ranked, Array<bool> *is_float, bool call_mem=false, bool by_ref_reg=false) {
	*ranked = array_make<i32>(xb_allocator(), 0, 8);
	isize n = p->locals.count;
	*is_float = array_make<bool>(xb_allocator(), n);
	if (n == 0) return;

	auto ok = array_make<bool>(xb_allocator(), n);
	auto weight = array_make<i32>(xb_allocator(), n);
	auto kind = array_make<u8>(xb_allocator(), n); // 1: read and written as an int, 2: as a float
	defer (array_free(&ok));
	defer (array_free(&weight));
	defer (array_free(&kind));
	for (isize i = 0; i < n; i++) {
		xbLocal const &l = p->locals[i];
		ok[i] = l.over_align <= 16 && (l.size == 1 || l.size == 2 || l.size == 4 || l.size == 8);
	}
	auto bad = [&](xbMem const &m) {
		if (m.kind == xbMem_Local) ok[m.base] = false;
	};
	auto access = [&](i32 l, bool fp) {
		u8 k = fp ? 2 : 1;
		if (kind[l] != 0 && kind[l] != k) ok[l] = false;
		kind[l] = k;
	};

	isize bc = p->order.count;
	Array<bool> in_loop = {};
	xb_blocks_in_loops(p, &in_loop);
	defer (array_free(&in_loop));

	for (isize bi = 0; bi < bc; bi++) {
		for (xbInstr const &in : p->order[bi]->instrs) {
			switch (in.op) {
			case xbOp_Load:
			case xbOp_Store: {
				if (in.mem.kind != xbMem_Local) break;
				xbLocal const &l = p->locals[in.mem.base];
				bool fp = xb_type_is_float(in.type);
				bool plain = in.mem.offset == 0 && (xb_type_is_int(in.type) || (fp && l.size >= 4)) && xb_type_size(in.type) == l.size &&
				             !(in.flags & xbInstrFlag_Volatile);
				if (!plain) ok[in.mem.base] = false;
				access(in.mem.base, fp);
				weight[in.mem.base] += in_loop[bi] ? loop_weight : other_weight;
				break;
			}
			case xbOp_Lea:
			case xbOp_AtomicLoad:
			case xbOp_AtomicStore:
			case xbOp_MemZero:
			case xbOp_Prefetch:
			case xbOp_AtomicRmw:
			case xbOp_AtomicCas:
			case xbOp_Cpuid:
			case xbOp_Xgetbv:
			case xbOp_Vec128:
				bad(in.mem);
				break;
			case xbOp_Call:
			case xbOp_Ret:
			case xbOp_Syscall: {
				xbCall const &c = p->calls[cast(isize)in.imm];
				for (xbCallArg const &arg : c.args) {
					if (arg.kind == xbCallArg_Gpr || arg.kind == xbCallArg_Xmm || arg.kind == xbCallArg_Stack) continue;
					if (call_mem && arg.kind == xbCallArg_GprMem && xb_call_mem_is_local(p, arg.mem, arg.size)) {
						access(arg.mem.base, false);
						weight[arg.mem.base] += in_loop[bi] ? loop_weight : other_weight;
						continue;
					}
					bad(arg.mem);
				}
				for (xbCallRet const &r : c.rets) {
					if (call_mem && in.op == xbOp_Call && c.rets.count == 1 && r.loc == xbLoc_Gpr && xb_call_mem_is_local(p, r.dst, r.size)) {
						access(r.dst.base, false);
						weight[r.dst.base] += in_loop[bi] ? loop_weight : other_weight;
						continue;
					}
					bad(r.dst);
				}
				break;
			}
			}
		}
	}
	for (xbParamIn const &in : p->params_in) {
		if (in.dst.kind != xbMem_Local) continue;
		bool fp = in.loc == xbLoc_Xmm || (in.loc == xbLoc_Stack && xb_type_is_float(in.type));
		bool plain = (in.loc == xbLoc_Gpr || in.loc == xbLoc_Xmm || (in.loc == xbLoc_Stack && in.type != xbType_V128)) &&
		             in.dst.offset == 0 && in.size == p->locals[in.dst.base].size && (!fp || in.size >= 4);
		if (!plain) ok[in.dst.base] = false;
		access(in.dst.base, fp);
	}
	for (xbDebugVar const &v : p->debug_vars) {
		if (v.local >= 0 && v.by_ref && !(by_ref_reg && v.frame_offset_fixup == 0)) ok[v.local] = false;
	}

	auto order = array_make<xbRankedLocal>(xb_allocator(), 0, n);
	defer (array_free(&order));
	for (isize i = 0; i < n; i++) {
		(*is_float)[i] = kind[i] == 2;
		if (!ok[i] || weight[i] <= min_weight) continue;
		xbRankedLocal r = {weight[i], cast(i32)i};
		array_add(&order, r);
	}
	gb_sort_array(order.data, order.count, xb_ranked_local_cmp);
	for (xbRankedLocal const &r : order) array_add(ranked, r.index);
}

// Removes what the builder leaves unused: pure values and frame loads that nothing reads,
// stores to frame locals that nothing reads, and stores that a later store in the same block
// overwrites before anything can read them. A debugger may look at a debug variable's local at
// any time, so its stores stay.
gb_internal void xb_cleanup_proc(xbProc *p) {
	isize vn = p->vregs.count;
	isize ln = p->locals.count;
	isize bc = p->order.count;
	struct At { i32 block; i32 instr; };
	auto uses = array_make<i32>(xb_allocator(), vn);
	auto def_at = array_make<At>(xb_allocator(), vn);
	auto keep = array_make<bool>(xb_allocator(), ln);  // a debug variable's local
	auto reads = array_make<i32>(xb_allocator(), ln);  // the instructions that may read the local
	auto stores = array_make<At>(xb_allocator(), 0, 64); // stores to locals that may be dead
	auto has_store = array_make<bool>(xb_allocator(), bc);
	auto work = array_make<u32>(xb_allocator(), 0, 64);
	defer (array_free(&uses));
	defer (array_free(&def_at));
	defer (array_free(&keep));
	defer (array_free(&reads));
	defer (array_free(&stores));
	defer (array_free(&has_store));
	defer (array_free(&work));
	for (xbDebugVar const &v : p->debug_vars) {
		if (v.local >= 0) keep[v.local] = true;
	}
	auto local_of = [&](xbMem const &m) -> i32 {
		return m.kind == xbMem_Local ? cast(i32)m.base : -1;
	};
	for (isize bi = 0; bi < bc; bi++) {
		xbBlock *b = p->order[bi];
		for (isize ii = 0; ii < b->instrs.count; ii++) {
			xbInstr const &in = b->instrs[ii];
			if (in.op == xbOp_Asm) return; // its memory operands are not followed
			xb_for_each_vreg(p, in, [&](u32 v, bool is_def) {
				if (v == 0) return;
				if (is_def) {
					At at = {cast(i32)bi, cast(i32)ii};
					def_at[v] = at;
				} else {
					uses[v]++;
				}
			});
			switch (in.op) {
			case xbOp_Store:
			case xbOp_MemZero: {
				i32 l = local_of(in.mem);
				if (l >= 0 && !keep[l] && !(in.flags & xbInstrFlag_Volatile)) {
					At at = {cast(i32)bi, cast(i32)ii};
					array_add(&stores, at);
					has_store[bi] = true;
				}
				break;
			}
			case xbOp_Call:
			case xbOp_Ret:
			case xbOp_Syscall:
				for (xbCallArg const &arg : p->calls[cast(isize)in.imm].args) {
					if (arg.kind != xbCallArg_Gpr && arg.kind != xbCallArg_Xmm && arg.kind != xbCallArg_Stack) {
						i32 l = local_of(arg.mem);
						if (l >= 0) reads[l]++;
					}
				}
				break;
			default: {
				i32 l = local_of(in.mem);
				if (l >= 0) reads[l]++;
				break;
			}
			}
		}
	}

	auto kill = [&](xbInstr *in) {
		xb_for_each_vreg(p, *in, [&](u32 v, bool is_def) {
			if (v != 0 && !is_def && --uses[v] == 0) array_add(&work, v);
		});
		if (in->op == xbOp_Load) {
			i32 l = local_of(in->mem);
			if (l >= 0) reads[l]--;
		}
		*in = xb_instr(xbOp_Nop);
	};
	auto dead_value = [&](xbInstr const &in) -> bool {
		if (in.dst == 0 || uses[in.dst] != 0) return false;
		if (xb_op_is_pure(in.op)) return true;
		return in.op == xbOp_Load && (in.mem.kind == xbMem_Local || in.mem.kind == xbMem_Incoming) &&
		       !(in.flags & xbInstrFlag_Volatile);
	};
	auto drain = [&]() {
		while (work.count > 0) {
			u32 v = array_pop(&work);
			At at = def_at[v];
			xbInstr *in = &p->order[at.block]->instrs[at.instr];
			if (in->dst == v && dead_value(*in)) kill(in);
		}
	};
	for (u32 v = 1; v < vn; v++) {
		if (uses[v] == 0) array_add(&work, v);
	}
	drain();

	// the locals that nothing reads any more
	for (At at : stores) {
		xbInstr *in = &p->order[at.block]->instrs[at.instr];
		if (in->op != xbOp_Store && in->op != xbOp_MemZero) continue;
		if (reads[local_of(in->mem)] == 0) kill(in);
	}
	drain();

	// Stores that a later one in the block overwrites first. Going back, `covered` holds the
	// bytes the stores after this point write, below offset 64, of the locals nothing read since.
	struct Cover { i32 local; u64 bytes; };
	auto covered = array_make<Cover>(xb_allocator(), 0, 16);
	defer (array_free(&covered));
	for (isize bi = 0; bi < bc; bi++) {
		if (!has_store[bi]) continue;
		xbBlock *b = p->order[bi];
		covered.count = 0;
		for (isize ii = b->instrs.count-1; ii >= 0; ii--) {
			xbInstr &in = b->instrs[ii];
			switch (in.op) {
			case xbOp_Nop:
			case xbOp_Loc:
			case xbOp_Scope:
			case xbOp_Jump:
			case xbOp_Branch:
			case xbOp_Lea:
				continue;
			case xbOp_Store:
			case xbOp_MemZero: {
				i32 l = local_of(in.mem);
				i64 size = in.op == xbOp_Store ? xb_type_size(in.type) : in.imm;
				if (l < 0 || keep[l] || (in.flags & xbInstrFlag_Volatile) || in.mem.offset < 0 || in.mem.offset + size > 64) continue;
				u64 bytes = (size >= 64 ? ~0ull : ((1ull << size) - 1)) << in.mem.offset;
				isize k = 0;
				while (k < covered.count && covered[k].local != l) k++;
				if (k == covered.count) {
					Cover c = {l, 0};
					array_add(&covered, c);
				}
				if ((covered[k].bytes & bytes) == bytes) {
					kill(&in);
				} else {
					covered[k].bytes |= bytes;
				}
				continue;
			}
			case xbOp_Load: {
				i32 l = local_of(in.mem);
				if (l >= 0) {
					for (isize k = 0; k < covered.count; k++) {
						if (covered[k].local == l) covered[k].bytes = 0;
					}
					continue;
				}
				covered.count = 0; // through a pointer, it may read any local whose address is known
				continue;
			}
			}
			if (xb_op_is_pure(in.op)) continue;
			covered.count = 0;
		}
	}
	drain();
}

////////////////////////////////////////////////////////////////
// Register allocation
////////////////////////////////////////////////////////////////

// Registers come from a linear scan over intervals in the block order. A vreg that lives inside
// one block has an interval from its definition to its last use. The other vregs and the scalar
// locals whose address is never taken get one interval that covers every point where a
// liveness analysis finds them live; a local that is a debug variable keeps its register in all
// of its scope. An interval takes a caller saved register when no clobbering instruction (a
// call) happens in it, a callee saved one otherwise; a parameter stays in the register it
// arrives in or moves to a callee saved one. A constant with one definition gets no register,
// the lowering materializes it at each use.

// xbRegAlloc::reg holds general registers as themselves and float registers as XB_FREG + n
enum : i8 {
	XB_NOREG = -1,
	XB_FREG  = 32,
};

enum : u32 { XB_LOCAL_ITEM = 0x80000000u };

// The registers an interval may take, bit n for register n
struct xbRegPools {
	u32  caller_x, callee_x; // general registers
	u32  caller_v, callee_v; // float registers
	i64  callee_weight;      // an interval lighter than this takes a callee saved register only when one is already saved
};

// What xb_alloc_regs finds about a vreg in its first pass over the instructions.
struct xbVregFacts {
	i64  weight;    // its spill cost: its references, each more for the loops around it
	i32  block;     // the first block it appears in, or -1
	i32  defs;      // the instructions writing it
	i32  def_pos;   // the position of the first, or -1
	i32  first_use; // the positions of the first and last read, or -1
	i32  last_use;
	i32  def_block; // the block of the latest write so far, or -1
	i8   want;      // the argument register a call reads it from, XB_NOREG, or -2 for several
	bool multi;     // it appears in more than one block
	bool pinned;    // it must stay in its slot
	bool cross;     // a read is in another block than the latest write before it
};

struct xbRegAlloc {
	Array<xbVregFacts> facts;
	Array<i32> uses;      // vreg -> number of reads
	Array<i8>  reg;       // vreg -> the register holding it for its whole life, or XB_NOREG
	Array<u8>  is_const;  // vreg -> defined once by an int IConst, materialized at its uses
	Array<i64> cval;
	Array<u8>  in_block;  // vreg -> defined once, and only read later in the same block
	Array<u8>  clean;     // vreg -> its register holds 0 or 1
	Array<i8>  local_reg; // local -> the register holding it, or XB_NOREG
	Array<i32> via;       // vreg -> the local whose register it shares, or -1
	Array<u8>  remat;     // vreg -> defined once as a frame address, computed at each use from rmem
	Array<xbMem> rmem;
	Array<i32> slot;      // vreg -> frame offset of its 8 byte slot, when it has no register
	u32        used_x, used_v; // every register handed out
	i32        max_call_stack;
	bool       sp_moves;  // an alloca moves the stack pointer
};

gb_internal void xb_reg_alloc_free(xbRegAlloc *R) {
	array_free(&R->uses);
	array_free(&R->reg);
	array_free(&R->is_const);
	array_free(&R->cval);
	array_free(&R->in_block);
	array_free(&R->clean);
	array_free(&R->local_reg);
	array_free(&R->via);
	array_free(&R->remat);
	array_free(&R->rmem);
	array_free(&R->slot);
	array_free(&R->facts);
}

// Gives registers to the vregs and promotable locals of p. The target tells:
//   clobbers(in):         whether `in` calls something or writes caller saved registers
//   wants(p, in, note):   note(vreg, reg) for each argument `in` reads in a fixed register
//   pins(p, in, pin):     pin(vreg) for each vreg that must stay in its slot
template <typename Target>
gb_internal void xb_alloc_regs(xbProc *p, xbRegAlloc *R, xbRegPools const &pools, Target const &target) {
	isize vreg_count = p->vregs.count;

	// Promotable scalar locals get live intervals like the vregs, a parameter's starting in the
	// register it arrives in
	R->local_reg = array_make<i8>(xb_allocator(), p->locals.count);
	for (isize i = 0; i < p->locals.count; i++) R->local_reg[i] = XB_NOREG;
	Array<i32> ranked = {};
	Array<bool> local_fp = {};
	xb_rank_promotable_locals(p, 16, 1, 0, &ranked, &local_fp, true, true);
	defer (array_free(&ranked));
	defer (array_free(&local_fp));
	auto arrive = array_make<i8>(xb_allocator(), p->locals.count); // a parameter's register
	defer (array_free(&arrive));
	for (isize i = 0; i < p->locals.count; i++) arrive[i] = XB_NOREG;
	auto is_param = array_make<bool>(xb_allocator(), p->locals.count);
	defer (array_free(&is_param));
	u32 arrive_v = 0; // the float registers parameters arrive in
	for (xbParamIn const &in : p->params_in) {
		if (in.loc == xbLoc_Xmm) arrive_v |= 1u << in.reg;
		if (in.dst.kind != xbMem_Local) continue;
		is_param[in.dst.base] = true;
		if (in.loc == xbLoc_Gpr || in.loc == xbLoc_Xmm) arrive[in.dst.base] = cast(i8)in.reg;
	}

	// one struct per vreg: the passes over the instructions touch all of it at once
	R->facts = array_make<xbVregFacts>(xb_allocator(), vreg_count);
	auto &fx = R->facts;
	auto clobbers = array_make<i32>(xb_allocator(), 0, 256); // prefix counts of target.clobbers
	defer (array_free(&clobbers));
	for (xbVregFacts &x : fx) {
		x.block = -1;
		x.def_pos = -1;
		x.first_use = -1;
		x.last_use = -1;
		x.def_block = -1;
		x.want = XB_NOREG;
	}
	auto note_want = [&](u32 v, i32 r) {
		if (v == 0) return;
		fx[v].want = fx[v].want == XB_NOREG || fx[v].want == r ? cast(i8)r : cast(i8)-2;
	};
	auto pin = [&](u32 v) {
		if (v != 0) fx[v].pinned = true;
	};

	R->uses = array_make<i32>(xb_allocator(), vreg_count);
	R->reg = array_make<i8>(xb_allocator(), vreg_count);
	R->is_const = array_make<u8>(xb_allocator(), vreg_count);
	R->cval = array_make<i64>(xb_allocator(), vreg_count);
	R->in_block = array_make<u8>(xb_allocator(), vreg_count);
	R->clean = array_make<u8>(xb_allocator(), vreg_count);
	R->via = array_make<i32>(xb_allocator(), vreg_count);
	R->remat = array_make<u8>(xb_allocator(), vreg_count);
	R->rmem = array_make<xbMem>(xb_allocator(), vreg_count);
	for (isize i = 0; i < vreg_count; i++) {
		R->reg[i] = XB_NOREG;
		R->via[i] = -1;
	}

	// The spill cost of an item: its references, each 8 times more for each loop around it;
	// a loop is a jump back to or before its block
	auto bweight = array_make<i64>(xb_allocator(), p->blocks.count);
	defer (array_free(&bweight));
	{
		isize bc = p->order.count;
		auto pos = array_make<isize>(xb_allocator(), p->blocks.count);
		auto depth = array_make<i32>(xb_allocator(), bc + 1); // as differences first, see below
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
					depth[pos[t]] += 1;
					depth[i+1] -= 1;
				}
			}
		}
		for (isize i = 1; i < bc; i++) depth[i] += depth[i-1];
		for (isize i = 0; i < bc; i++) bweight[p->order[i]->index] = 1ll << (3*gb_min(depth[i], 6));
	}

	i32 linear = 0;
	R->max_call_stack = 0;
	R->sp_moves = false;
	array_add(&clobbers, 0);
	for (isize bi = 0; bi < p->order.count; bi++) {
		xbBlock *b = p->order[bi];
		for (xbInstr const &in : b->instrs) {
			xb_for_each_vreg(p, in, [&](u32 v, bool is_def) {
				if (v == 0) return;
				fx[v].weight += bweight[b->index];
				if (fx[v].block < 0) {
					fx[v].block = b->index;
				} else if (fx[v].block != b->index) {
					fx[v].multi = true;
				}
				if (is_def) {
					if (fx[v].defs++ == 0) fx[v].def_pos = linear;
					fx[v].def_block = b->index;
					if (in.op == xbOp_IConst && xb_type_is_int(p->vregs[v])) {
						R->is_const[v] = true;
						R->cval[v] = in.imm;
					}
					if (in.op == xbOp_Lea && ((in.mem.kind == xbMem_Local && p->locals[in.mem.base].over_align <= 16) || in.mem.kind == xbMem_Incoming)) {
						R->remat[v] = true;
						R->rmem[v] = in.mem;
					}
					if ((in.op == xbOp_ICmp || in.op == xbOp_FCmp) || (in.op == xbOp_Load && in.type == xbType_I8)) {
						R->clean[v] = true;
					}
				} else {
					R->uses[v]++;
					if (fx[v].first_use < 0) fx[v].first_use = linear;
					fx[v].last_use = linear;
					if (fx[v].def_block != b->index) fx[v].cross = true;
				}
			});
			if (in.op == xbOp_Call) {
				R->max_call_stack = gb_max(R->max_call_stack, p->calls[cast(isize)in.imm].stack_size);
			}
			if (in.op == xbOp_Alloca) R->sp_moves = true;
			target.wants(p, in, note_want);
			target.pins(p, in, pin);
			array_add(&clobbers, clobbers[linear] + (target.clobbers(in) ? 1 : 0));
			linear++;
		}
	}
	for (isize v = 1; v < vreg_count; v++) {
		if (fx[v].defs != 1) {
			R->is_const[v] = false;
			R->clean[v] = false;
			R->remat[v] = false;
		}
		R->in_block[v] = fx[v].defs == 1 && !fx[v].multi && (fx[v].first_use < 0 || fx[v].first_use > fx[v].def_pos);
	}

	// The other int and float vregs get one interval in the block order that covers every point
	// where a liveness analysis finds them live.
	isize bc = p->order.count;
	auto gid = array_make<i32>(xb_allocator(), vreg_count);
	defer (array_free(&gid));
	// an item is a vreg, or a local with XB_LOCAL_ITEM set
	auto gvreg = array_make<u32>(xb_allocator(), 0, 64);
	defer (array_free(&gvreg));
	auto lgid = array_make<i32>(xb_allocator(), p->locals.count);
	auto lweight = array_make<i64>(xb_allocator(), p->locals.count);
	defer (array_free(&lgid));
	defer (array_free(&lweight));
	for (isize i = 0; i < p->locals.count; i++) lgid[i] = -1;
	for (int pass = 0; pass < 2; pass++) {
		for (i32 l : ranked) {
			if (is_param[l] != (pass == 0)) continue;
			lgid[l] = cast(i32)gvreg.count;
			array_add(&gvreg, XB_LOCAL_ITEM | cast(u32)l);
		}
	}
	for (isize v = 1; v < vreg_count; v++) {
		gid[v] = -1;
		xbType t = p->vregs[v];
		if (R->in_block[v] || fx[v].defs == 0 || R->is_const[v] || R->remat[v] || fx[v].pinned || (!xb_type_is_int(t) && !xb_type_is_float(t))) continue;
		gid[v] = cast(i32)gvreg.count;
		array_add(&gvreg, cast(u32)v);
	}
	isize gn = gvreg.count;
	auto glo = array_make<i32>(xb_allocator(), gn);
	auto ghi = array_make<i32>(xb_allocator(), gn);
	auto glo_def = array_make<bool>(xb_allocator(), gn); // the interval starts where an instruction writes it
	auto gstart = array_make<i32>(xb_allocator(), 0, gn); // global ids by the start of their interval
	defer (array_free(&glo));
	defer (array_free(&ghi));
	defer (array_free(&glo_def));
	defer (array_free(&gstart));
	if (gn > 0 && bc > 0) {
		auto bstart   = array_make<i32>(xb_allocator(), bc);
		auto bend     = array_make<i32>(xb_allocator(), bc);
		auto succ     = array_make<i32>(xb_allocator(), 2*bc);
		auto opos     = array_make<i32>(xb_allocator(), p->blocks.count);
		defer (array_free(&bstart));
		defer (array_free(&bend));
		defer (array_free(&succ));
		defer (array_free(&opos));
		// per block, whether an item is read there before it is written (gen) or is written (kill)
		struct Event { i32 id; i32 block; bool kill; };
		auto events = array_make<Event>(xb_allocator(), 0, 4*gn);
		auto ev_block = array_make<i32>(xb_allocator(), gn); // the block of the item's last event
		auto ev_state = array_make<u8>(xb_allocator(), gn);  // 1: gen noted, 2: killed
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
		auto smin = array_make<i32>(xb_allocator(), sn);
		auto smax = array_make<i32>(xb_allocator(), sn);
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
					if (gvreg[id] & XB_LOCAL_ITEM) lweight[gvreg[id] & ~XB_LOCAL_ITEM] += bweight[b->index];
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
		auto pred_start = array_make<i32>(xb_allocator(), bc+1);
		auto preds      = array_make<i32>(xb_allocator(), 2*bc);
		defer (array_free(&pred_start));
		defer (array_free(&preds));
		for (isize s = 0; s < 2*bc; s++) if (succ[s] >= 0) pred_start[succ[s]+1]++;
		for (isize i = 0; i < bc; i++) pred_start[i+1] += pred_start[i];
		{
			auto fill = array_make<i32>(xb_allocator(), bc);
			defer (array_free(&fill));
			for (isize s = 0; s < 2*bc; s++) {
				if (succ[s] >= 0) preds[pred_start[succ[s]] + fill[succ[s]]++] = cast(i32)(s/2);
			}
		}
		auto ev_start = array_make<i32>(xb_allocator(), gn+1);
		auto by_id    = array_make<i32>(xb_allocator(), events.count);
		defer (array_free(&ev_start));
		defer (array_free(&by_id));
		for (Event const &e : events) ev_start[e.id+1]++;
		for (isize i = 0; i < gn; i++) ev_start[i+1] += ev_start[i];
		{
			auto fill = array_make<i32>(xb_allocator(), gn);
			defer (array_free(&fill));
			for (isize i = 0; i < events.count; i++) by_id[ev_start[events[i].id] + fill[events[i].id]++] = cast(i32)i;
		}
		// marks hold id+1 for the item being walked
		auto kill_mark = array_make<i32>(xb_allocator(), bc);
		auto in_mark   = array_make<i32>(xb_allocator(), bc);
		auto out_mark  = array_make<i32>(xb_allocator(), bc);
		auto stack     = array_make<i32>(xb_allocator(), 0, 64);
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
		auto alias_end = array_make<i32>(xb_allocator(), p->locals.count); // last read through an alias
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
					if (l < 0 || v == 0 || !R->in_block[v] || fx[v].pinned || R->uses[v] == 0 || fx[v].last_use - pos > 256 ||
					    xb_type_is_float(p->vregs[v]) != local_fp[l]) continue;
					bool ok = true;
					for (isize j = i+1; ok && j <= i + (fx[v].last_use - pos); j++) ok = !writes(b->instrs[j], l);
					if (!ok) continue;
					R->via[v] = l;
					alias_end[l] = gb_max(alias_end[l], fx[v].last_use);
					ghi[lgid[l]] = gb_max(ghi[lgid[l]], fx[v].last_use);
				} else if (in.op == xbOp_Store) {
					i32 l = local_of(in.mem);
					u32 v = in.a;
					if (l < 0 || v == 0 || !R->in_block[v] || fx[v].pinned || R->uses[v] != 1 || R->is_const[v] || R->remat[v] || R->via[v] >= 0 ||
					    !(local_fp[l] ? xb_type_is_float(p->vregs[v]) : xb_type_is_int(p->vregs[v])) || pos - fx[v].def_pos > 256 || alias_end[l] >= fx[v].def_pos) continue;
					isize d = fx[v].def_pos - bstart[bi];
					bool ok = true;
					for (isize j = d; ok && j < i; j++) ok = !reads(b->instrs[j], l) && (j == d || !writes(b->instrs[j], l));
					if (!ok) continue;
					R->via[v] = l;
					i32 id = lgid[l];
					if (fx[v].def_pos < glo[id]) {
						glo[id] = fx[v].def_pos;
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
		auto first = array_make<i32>(xb_allocator(), linear+1);
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

	// registers for the vregs, first come first served. When none is free, an interval takes the
	// register of an active one that costs less in memory for each position it covers; the loser
	// lives in its slot all its life.
	u32 free_x = pools.caller_x | pools.callee_x;
	u32 free_v = pools.caller_v | pools.callee_v;
	R->used_x = 0;
	R->used_v = 0;
	// the vregs and locals holding a register, listed under the position after their last
	struct Active { u32 v; i32 next; bool dead; i32 len; };
	auto active = array_make<Active>(xb_allocator(), 0, 64);
	// the active entry holding each general register, and each float register at XB_FREG + n
	i32 owner[64];
	for (i32 &o : owner) o = -1;
	// a local whose register a vreg shares keeps it
	auto shared = array_make<bool>(xb_allocator(), p->locals.count);
	defer (array_free(&shared));
	auto weight_of = [&](u32 v) -> i64 {
		return (v & XB_LOCAL_ITEM) ? lweight[v & ~XB_LOCAL_ITEM] : fx[v].weight;
	};
	auto expire = array_make<i32>(xb_allocator(), clobbers.count + 1);
	defer (array_free(&active));
	defer (array_free(&expire));
	for (i32 &e : expire) e = -1;
	// gives v a register for [now, end] if one is free, a callee saved one when `calls`
	auto take = [&](u32 v, i32 end, bool calls) {
		bool is_local = (v & XB_LOCAL_ITEM) != 0;
		i32 l = cast(i32)(v & ~XB_LOCAL_ITEM);
		bool fp = is_local ? local_fp[l] : xb_type_is_float(p->vregs[v]);
		u32 *free = fp ? &free_v : &free_x;
		u32 pool = fp ? (calls ? pools.callee_v : pools.caller_v | pools.callee_v)
		              : (calls ? pools.callee_x : pools.caller_x | pools.callee_x);
		if (is_local && is_param[l]) {
			// the prologue moves a parameter into a register no other parameter arrives in
			pool = fp ? pool & ~arrive_v : pools.callee_x;
			i8 w = arrive[l];
			if (w >= 0 && !calls && (*free & (1u << w))) pool = 1u << w;
		}
		if (calls && weight_of(v) + (is_local && is_param[l] ? 1 : 0) < pools.callee_weight) {
			// saving a callee saved register costs about what a few slot accesses do; a
			// parameter's slot also costs the prologue's store
			pool &= fp ? R->used_v : R->used_x;
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
				i32 k = owner[(fp ? XB_FREG : 0) + r];
				if (k < 0) continue;
				u32 y = active[k].v;
				if ((y & XB_LOCAL_ITEM) && shared[y & ~XB_LOCAL_ITEM]) continue;
				i64 wy = weight_of(y);
				i64 ly = active[k].len;
				if (wy*wl < w*ly) { w = wy; wl = ly; best = k; }
			}
			if (best >= 0) {
				u32 y = active[best].v;
				i8 r = (y & XB_LOCAL_ITEM) ? R->local_reg[y & ~XB_LOCAL_ITEM] : R->reg[y];
				if (y & XB_LOCAL_ITEM) R->local_reg[y & ~XB_LOCAL_ITEM] = XB_NOREG;
				else                   R->reg[y] = XB_NOREG;
				active[best].dead = true;
				owner[r] = -1;
				*free |= 1u << (r >= XB_FREG ? r - XB_FREG : r);
				avail = *free & pool;
			}
		}
		if (avail == 0) return;
		// the caller saved ones first, they cost no save; from the top, where calls
		// want the fewest arguments
		u32 caller = avail & (fp ? pools.caller_v : pools.caller_x);
		u32 r = 0;
		if (caller) {
			r = 31;
			while ((caller & (1u << r)) == 0) r--;
		} else {
			while ((avail & (1u << r)) == 0) r++;
		}
		*free &= ~(1u << r);
		if (fp && is_local) {
			R->used_v |= 1u << r;
			R->local_reg[l] = cast(i8)(XB_FREG + r);
		} else if (fp) {
			R->used_v |= 1u << r;
			R->reg[v] = cast(i8)(XB_FREG + r);
		} else if (is_local) {
			R->used_x |= 1u << r;
			R->local_reg[l] = cast(i8)r;
		} else {
			R->used_x |= 1u << r;
			R->reg[v] = cast(i8)r;
		}
		owner[(fp ? XB_FREG : 0) + r] = cast(i32)active.count;
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
				i8 r = (v & XB_LOCAL_ITEM) ? R->local_reg[v & ~XB_LOCAL_ITEM] : R->reg[v];
				owner[r] = -1;
				if (r >= XB_FREG) free_v |= 1u << (r - XB_FREG);
				else              free_x |= 1u << r;
			}
			while (gs < gstart.count && glo[gstart[gs]] == linear) {
				i32 id = gstart[gs++];
				// a call that defines v writes it afterwards
				take(gvreg[id], ghi[id], clobbers[ghi[id]+1] - clobbers[linear + (glo_def[id] ? 1 : 0)] > 0);
			}
			xb_for_each_vreg(p, in, [&](u32 v, bool is_def) {
				if (v == 0 || !is_def || !R->in_block[v] || R->is_const[v] || R->remat[v] || fx[v].pinned || R->reg[v] != XB_NOREG) return;
				xbType t = p->vregs[v];
				if (!xb_type_is_int(t) && !xb_type_is_float(t)) return;
				if (R->via[v] >= 0 && R->local_reg[R->via[v]] >= 0) {
					R->reg[v] = R->local_reg[R->via[v]];
					shared[R->via[v]] = true;
					return;
				}
				i32 end = fx[v].last_use >= 0 ? fx[v].last_use : linear;
				// read only as an argument, before that call: right in the argument register
				i8 w = fx[v].want;
				if (w >= 0 && R->uses[v] == 1 && clobbers[end] - clobbers[linear+1] == 0 &&
				    (w >= XB_FREG) == xb_type_is_float(t)) {
					u32 *free = xb_type_is_float(t) ? &free_v : &free_x;
					u32 bit = 1u << (w >= XB_FREG ? w - XB_FREG : w);
					if (*free & bit) {
						*free &= ~bit;
						R->reg[v] = w;
						if (w >= XB_FREG) R->used_v |= bit;
						else              R->used_x |= bit;
						owner[w] = cast(i32)active.count;
						Active act = {v, expire[end+1], false, 0};
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

	// the other vregs used only in the block that defines them share slots, given by xb_alloc_slots
	R->slot = array_make<i32>(xb_allocator(), vreg_count);
}

// Frame slots for the vregs without a register, below `*cur` bytes under the frame pointer,
// which grows by what they take.
gb_internal void xb_alloc_slots(xbProc *p, xbRegAlloc *R, i32 *cur) {
	// the reads xb_alloc_regs found; nothing changed the IR since
	auto const &fx = R->facts;
	i32 linear = 0;

	auto free_slots = array_make<i32>(xb_allocator(), 0, 64);
	defer (array_free(&free_slots));
	auto to_free = array_make<u32>(xb_allocator(), 0, 8);
	defer (array_free(&to_free));
	linear = 0;
	for (xbBlock *b : p->order) {
		for (xbInstr const &in : b->instrs) {
			to_free.count = 0;
			xb_for_each_vreg(p, in, [&](u32 v, bool is_def) {
				if (v == 0 || R->reg[v] != XB_NOREG || R->is_const[v] || R->remat[v]) return;
				if (is_def) {
					i32 s = 0;
					if (!fx[v].cross && free_slots.count > 0) {
						s = array_pop(&free_slots);
					} else {
						*cur += 8;
						s = -*cur;
					}
					R->slot[v] = s;
					if (!fx[v].cross && fx[v].last_use < linear) {
						array_add(&to_free, v); // never used
					}
				} else if (!fx[v].cross && fx[v].last_use == linear) {
					array_add(&to_free, v);
				}
			});
			for (isize i = 0; i < to_free.count; i++) {
				// a vreg may appear twice in one instruction
				bool dup = false;
				for (isize j = 0; j < i; j++) if (to_free[j] == to_free[i]) { dup = true; break; }
				if (!dup) array_add(&free_slots, R->slot[to_free[i]]);
			}
			linear++;
		}
	}
}
