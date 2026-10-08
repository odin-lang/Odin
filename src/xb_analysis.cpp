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
		return true;
	}
	return false;
}

// The scalar locals that can live in a register, heaviest first. A local qualifies when
// every access is a plain whole-value int load or store, so nothing can see its memory.
// Each access weighs `loop_weight` inside a loop and `other_weight` elsewhere, and a
// local needs more than `min_weight`.
gb_internal void xb_rank_promotable_locals(xbProc *p, i32 loop_weight, i32 other_weight, i32 min_weight, Array<i32> *ranked) {
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
					if (arg.kind != xbCallArg_Gpr && arg.kind != xbCallArg_Xmm && arg.kind != xbCallArg_Stack) bad(arg.mem);
				}
				for (xbCallRet const &r : c.rets) bad(r.dst);
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
		if (v.local >= 0 && v.by_ref) ok[v.local] = false;
	}

	for (;;) {
		isize best = -1;
		for (isize i = 0; i < n; i++) {
			if (ok[i] && weight[i] > min_weight && (best < 0 || weight[i] > weight[best])) best = i;
		}
		if (best < 0) break;
		array_add(ranked, cast(i32)best);
		ok[best] = false;
	}
}
