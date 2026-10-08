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
		f(in.a, false);
		f(in.b, false);
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
// every access is a plain whole-value int load or store, so nothing can see its memory.
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

gb_internal void xb_rank_promotable_locals(xbProc *p, i32 loop_weight, i32 other_weight, i32 min_weight, Array<i32> *ranked, bool call_mem=false, bool by_ref_reg=false) {
	*ranked = array_make<i32>(heap_allocator(), 0, 8);
	isize n = p->locals.count;
	if (n == 0) return;

	auto ok = array_make<bool>(heap_allocator(), n);
	auto weight = array_make<i32>(heap_allocator(), n);
	defer (array_free(&ok));
	defer (array_free(&weight));
	for (isize i = 0; i < n; i++) {
		xbLocal const &l = p->locals[i];
		ok[i] = l.over_align <= 16 && (l.size == 1 || l.size == 2 || l.size == 4 || l.size == 8);
	}
	auto bad = [&](xbMem const &m) {
		if (m.kind == xbMem_Local) ok[m.base] = false;
	};

	// a block is in a loop when a later block jumps back to or before it
	isize bc = p->order.count;
	auto pos = array_make<isize>(heap_allocator(), p->blocks.count);
	auto in_loop = array_make<bool>(heap_allocator(), bc);
	defer (array_free(&pos));
	defer (array_free(&in_loop));
	for (isize i = 0; i < bc; i++) pos[p->order[i]->index] = i;
	for (isize i = 0; i < bc; i++) {
		for (xbInstr const &in : p->order[i]->instrs) {
			i32 targets[2] = {-1, -1};
			if (in.op == xbOp_Jump) targets[0] = cast(i32)in.imm;
			if (in.op == xbOp_Branch) { targets[0] = cast(i32)in.imm; targets[1] = cast(i32)in.c; }
			for (i32 t : targets) {
				if (t < 0 || !p->blocks[t]->placed) continue;
				for (isize k = pos[t]; k <= i && pos[t] <= i; k++) in_loop[k] = true;
			}
		}
	}

	for (isize bi = 0; bi < bc; bi++) {
		for (xbInstr const &in : p->order[bi]->instrs) {
			switch (in.op) {
			case xbOp_Load:
			case xbOp_Store: {
				if (in.mem.kind != xbMem_Local) break;
				xbLocal const &l = p->locals[in.mem.base];
				bool plain = in.mem.offset == 0 && xb_type_is_int(in.type) && xb_type_size(in.type) == l.size &&
				             !(in.flags & xbInstrFlag_Volatile);
				if (!plain) ok[in.mem.base] = false;
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
						weight[arg.mem.base] += in_loop[bi] ? loop_weight : other_weight;
						continue;
					}
					bad(arg.mem);
				}
				for (xbCallRet const &r : c.rets) {
					if (call_mem && in.op == xbOp_Call && c.rets.count == 1 && r.loc == xbLoc_Gpr && xb_call_mem_is_local(p, r.dst, r.size)) {
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
		bool plain = (in.loc == xbLoc_Gpr || (in.loc == xbLoc_Stack && in.type != xbType_V128)) &&
		             in.dst.offset == 0 && in.size == p->locals[in.dst.base].size;
		if (!plain) ok[in.dst.base] = false;
	}
	for (xbDebugVar const &v : p->debug_vars) {
		if (v.local >= 0 && v.by_ref && !(by_ref_reg && v.frame_offset_fixup == 0)) ok[v.local] = false;
	}

	auto order = array_make<xbRankedLocal>(heap_allocator(), 0, n);
	defer (array_free(&order));
	for (isize i = 0; i < n; i++) {
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
	auto uses = array_make<i32>(heap_allocator(), vn);
	auto def_at = array_make<At>(heap_allocator(), vn);
	auto keep = array_make<bool>(heap_allocator(), ln);  // a debug variable's local
	auto reads = array_make<i32>(heap_allocator(), ln);  // the instructions that may read the local
	auto stores = array_make<At>(heap_allocator(), 0, 64); // stores to locals that may be dead
	auto has_store = array_make<bool>(heap_allocator(), bc);
	auto work = array_make<u32>(heap_allocator(), 0, 64);
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
	auto covered = array_make<Cover>(heap_allocator(), 0, 16);
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
