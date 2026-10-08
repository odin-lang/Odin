// Lowering: xb IR -> arm64 machine code.
//
// Like the x64 lowering, every vreg lives in an 8 byte stack slot, and every instruction
// loads its operands into scratch registers, computes, and stores the result back.
// The scratch registers are x9-x15, x16 for addresses and x17 for large offsets, and
// v16-v19 for floats. Nothing callee saved is touched, so the prologue saves only the
// frame record.
//
// Frame (macOS requires the frame pointer):
//   [x29+16 ...]  incoming stack arguments
//   [x29+8]       saved x30
//   [x29]         saved x29
//   [x29-N ...]   vreg slots, nearest the frame pointer where offsets are short, then locals
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

struct a64Lower {
	xbProc *    p;
	xbAsm       a;
	Array<i32>  slot;   // vreg -> x29 offset (negative)
	Array<i32>  uses;   // vreg -> number of reads
	i32         frame_size;
	i32         max_call_stack;
	struct Fixup { i64 at; i32 block; };
	Array<Fixup> fixups;
	i64         proc_start;
	i32         next_block;
};

struct a64Addr {
	u8  base;
	i64 off;
};

// The x86 operations, which have no arm64 form; the procedure goes to LLVM.
gb_internal void a64_check_proc(xbProc *p) {
	for (xbBlock *b : p->order) {
		for (xbInstr const &in : b->instrs) {
			switch (in.op) {
			case xbOp_Cpuid:
			case xbOp_Xgetbv:
			case xbOp_Vec128:
			case xbOp_Valgrind:
				XB_UNSUPPORTED(p, "arm64 operation");
				break;
			}
		}
	}
}

gb_internal void a64_lower_layout(a64Lower *L) {
	xbProc *p = L->p;
	isize vreg_count = p->vregs.count;
	auto def_block = array_make<i32>(heap_allocator(), vreg_count);
	auto last_use = array_make<i32>(heap_allocator(), vreg_count);
	auto cross = array_make<bool>(heap_allocator(), vreg_count);
	defer (array_free(&def_block));
	defer (array_free(&last_use));
	defer (array_free(&cross));
	for (isize i = 0; i < vreg_count; i++) {
		def_block[i] = -1;
		last_use[i] = -1;
	}

	L->uses = array_make<i32>(heap_allocator(), vreg_count);
	i32 linear = 0;
	L->max_call_stack = 0;
	for (xbBlock *b : p->order) {
		for (xbInstr const &in : b->instrs) {
			xb_for_each_vreg(p, in, [&](u32 v, bool is_def) {
				if (v == 0) return;
				if (is_def) {
					def_block[v] = b->index;
				} else {
					L->uses[v]++;
					if (def_block[v] != b->index) cross[v] = true;
					last_use[v] = linear;
				}
			});
			if (in.op == xbOp_Call) {
				L->max_call_stack = gb_max(L->max_call_stack, p->calls[cast(isize)in.imm].stack_size);
			}
			linear++;
		}
	}

	// vregs used only in the block that defines them share slots
	i32 cur = 0;
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
				if (v == 0) return;
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
			for (u32 v : to_free) {
				// a vreg may appear twice in one instruction
				bool dup = false;
				for (i32 s : free_slots) if (s == L->slot[v]) { dup = true; break; }
				if (!dup) array_add(&free_slots, L->slot[v]);
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

gb_internal void a64_get(a64Lower *L, u8 reg, u32 v, i32 size, xbExtKind ext) {
	GB_ASSERT(v != 0);
	a64_ldr(&L->a, size, ext == xbExt_Sign, reg, A64_FP, L->slot[v]);
}

gb_internal void a64_put(a64Lower *L, u32 v, u8 reg) {
	GB_ASSERT(v != 0);
	a64_str(&L->a, 8, reg, A64_FP, L->slot[v]);
}

gb_internal void a64_getf(a64Lower *L, u8 vr, u32 v, i32 size) {
	GB_ASSERT(v != 0);
	a64_ldr_fp(&L->a, size, vr, A64_FP, L->slot[v]);
}

gb_internal void a64_putf(a64Lower *L, u32 v, u8 vr, i32 size) {
	GB_ASSERT(v != 0);
	a64_str_fp(&L->a, size, vr, A64_FP, L->slot[v]);
}

// A base register and offset for an IR memory reference. May clobber `scratch` and x17.
gb_internal a64Addr a64_mem(a64Lower *L, xbMem const &m, u8 scratch=A64_TA) {
	xbAsm *a = &L->a;
	a64Addr r = {};
	switch (m.kind) {
	case xbMem_Local: {
		xbLocal const &l = L->p->locals[m.base];
		if (l.over_align > 16) {
			a64_ldr(a, 8, false, scratch, A64_FP, l.frame_offset);
			r.base = scratch;
			r.off = m.offset;
			return r;
		}
		r.base = A64_FP;
		r.off = l.frame_offset + m.offset;
		return r;
	}
	case xbMem_Incoming:
		r.base = A64_FP;
		r.off = 16 + m.offset;
		return r;
	case xbMem_Reg:
		a64_get(L, scratch, m.base, 8, xbExt_None);
		r.base = scratch;
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

gb_internal void a64_lower_call(a64Lower *L, xbCall const &c, bool is_ret) {
	xbAsm *a = &L->a;
	// stack arguments first, the argument registers are not touched yet
	for (xbCallArg const &arg : c.args) {
		switch (arg.kind) {
		case xbCallArg_Stack: {
			xbType t = arg.type;
			if (xb_type_is_float(t)) {
				a64_getf(L, A64_F0, arg.vreg, xb_type_size(t));
				a64_str_fp(a, xb_type_size(t), A64_F0, A64_SP, arg.stack_offset);
			} else {
				a64_get(L, A64_T0, arg.vreg, xb_type_size(t), arg.ext == xbExt_Sign ? xbExt_Sign : xbExt_Zero);
				a64_str(a, a64_slot_size(arg.size), A64_T0, A64_SP, arg.stack_offset);
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
			a64Addr src = a64_mem(L, arg.mem);
			xbExtKind ext = arg.ext;
			if (arg.size < 4 && ext == xbExt_None) ext = xbExt_Zero;
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
		a64_get(L, A64_TA, c.target_vreg, 8, xbExt_None);
		a64_blr(a, A64_TA);
	}
	for (xbCallRet const &r : c.rets) {
		a64Addr dst = a64_mem(L, r.dst);
		if (r.loc == xbLoc_Gpr) {
			a64_store_bytes(L, dst, r.reg, r.size);
		} else {
			a64_str_fp(a, r.size, r.reg, dst.base, dst.off);
		}
	}
}

// memmove(x0, x1, x2) or memset(x0, w1, x2), from the C library like LLVM's lowering
gb_internal void a64_call_libc(a64Lower *L, char const *name) {
	a64_bl_sym(&L->a, a64_libc_sym(L->p->m, name));
}

gb_internal void a64_epilogue(a64Lower *L) {
	xbAsm *a = &L->a;
	a64_mov_sp(a, A64_SP, A64_FP);
	a64_emit(a, 0xA8C17BFD); // ldp x29, x30, [sp], #16
	a64_ret(a);
}

// Jumps to `block`, patched once every block is placed.
gb_internal void a64_jump(a64Lower *L, i32 block) {
	a64Lower::Fixup f = {a64_b(&L->a), block};
	array_add(&L->fixups, f);
}

////////////////////////////////////////////////////////////////
// Instructions
////////////////////////////////////////////////////////////////

gb_internal void a64_lower_instr(a64Lower *L, xbInstr const &in) {
	xbAsm *a = &L->a;
	xbProc *p = L->p;
	i32 size = xb_type_size(in.type);
	switch (in.op) {
	case xbOp_Nop:
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
	case xbOp_FConst:
		a64_mov_imm(a, A64_T0, cast(u64)in.imm);
		a64_put(L, in.dst, A64_T0);
		break;
	case xbOp_Lea: {
		a64Addr m = a64_mem(L, in.mem);
		a64_add_imm(a, A64_T0, m.base, m.off);
		a64_put(L, in.dst, A64_T0);
		break;
	}
	case xbOp_Load: {
		a64Addr m = a64_mem(L, in.mem);
		if (xb_type_is_float(in.type)) {
			a64_ldr_fp(a, size, A64_F0, m.base, m.off);
			a64_putf(L, in.dst, A64_F0, size);
		} else {
			a64_ldr(a, size, false, A64_T0, m.base, m.off);
			a64_put(L, in.dst, A64_T0);
		}
		break;
	}
	case xbOp_Store: {
		// the value first, the address may need x16 and x17
		if (xb_type_is_float(in.type)) {
			a64_getf(L, A64_F0, in.a, size);
			a64Addr m = a64_mem(L, in.mem);
			a64_str_fp(a, size, A64_F0, m.base, m.off);
		} else {
			a64_get(L, A64_T0, in.a, size, xbExt_None);
			a64Addr m = a64_mem(L, in.mem);
			a64_str(a, size, A64_T0, m.base, m.off);
		}
		break;
	}
	case xbOp_Copy:
	case xbOp_Trunc:
	case xbOp_Bitcast:
		a64_get(L, A64_T0, in.a, 8, xbExt_None);
		a64_put(L, in.dst, A64_T0);
		break;

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
		a64_get(L, A64_T0, in.a, size, xbExt_None);
		a64_get(L, A64_T1, in.b, size, xbExt_None);
		a64_alu(a, op, A64_T0, A64_T0, A64_T1);
		a64_put(L, in.dst, A64_T0);
		break;
	}
	case xbOp_Mul:
		a64_get(L, A64_T0, in.a, size, xbExt_None);
		a64_get(L, A64_T1, in.b, size, xbExt_None);
		a64_mul(a, A64_T0, A64_T0, A64_T1);
		a64_put(L, in.dst, A64_T0);
		break;
	case xbOp_SDiv:
	case xbOp_SRem:
	case xbOp_UDiv:
	case xbOp_URem: {
		bool sgn = in.op == xbOp_SDiv || in.op == xbOp_SRem;
		xbExtKind ext = sgn ? xbExt_Sign : xbExt_Zero;
		a64_get(L, A64_T0, in.a, size, ext);
		a64_get(L, A64_T1, in.b, size, ext);
		a64_div(a, sgn, A64_T2, A64_T0, A64_T1);
		if (in.op == xbOp_SRem || in.op == xbOp_URem) {
			a64_msub(a, A64_T2, A64_T2, A64_T1, A64_T0);
		}
		a64_put(L, in.dst, A64_T2);
		break;
	}
	case xbOp_Shl:
	case xbOp_LShr:
	case xbOp_AShr: {
		a64Shift kind = in.op == xbOp_Shl ? A64_LSL : in.op == xbOp_LShr ? A64_LSR : A64_ASR;
		a64_get(L, A64_T0, in.a, size, in.op == xbOp_AShr ? xbExt_Sign : xbExt_Zero);
		a64_get(L, A64_T1, in.b, 8, xbExt_None);
		// like x86: narrow values shift as 32 bits, and the count is masked
		a64_shiftv(a, kind, size == 8 ? 8 : 4, A64_T0, A64_T0, A64_T1);
		a64_put(L, in.dst, A64_T0);
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
		a64_getf(L, A64_F0, in.a, size);
		a64_getf(L, A64_F1, in.b, size);
		a64_fop(a, op, size, A64_F0, A64_F0, A64_F1);
		a64_putf(L, in.dst, A64_F0, size);
		break;
	}
	case xbOp_Sqrt:
		a64_getf(L, A64_F0, in.a, size);
		a64_fsqrt(a, size, A64_F0, A64_F0);
		a64_putf(L, in.dst, A64_F0, size);
		break;
	case xbOp_FNeg:
		a64_getf(L, A64_F0, in.a, size);
		a64_fneg(a, size, A64_F0, A64_F0);
		a64_putf(L, in.dst, A64_F0, size);
		break;
	case xbOp_Neg:
	case xbOp_Not:
		a64_get(L, A64_T0, in.a, size, xbExt_None);
		a64_alu(a, in.op == xbOp_Neg ? A64_SUB : A64_ORN, A64_T0, XZR, A64_T0);
		a64_put(L, in.dst, A64_T0);
		break;
	case xbOp_ICmp: {
		xbCond c = cast(xbCond)in.aux;
		xbExtKind ext = a64_cond_is_signed(c) ? xbExt_Sign : xbExt_Zero;
		a64_get(L, A64_T0, in.a, size, ext);
		a64_get(L, A64_T1, in.b, size, ext);
		a64_cmp(a, A64_T0, A64_T1);
		a64_cset(a, A64_T0, a64_cond_for(c));
		a64_put(L, in.dst, A64_T0);
		break;
	}
	case xbOp_FCmp: {
		xbCond c = cast(xbCond)in.aux;
		a64_getf(L, A64_F0, in.a, size);
		a64_getf(L, A64_F1, in.b, size);
		a64_fcmp(a, size, A64_F0, A64_F1);
		a64_cset(a, A64_T0, a64_cond_for(c));
		a64_put(L, in.dst, A64_T0);
		break;
	}
	case xbOp_Zext:
	case xbOp_Sext: {
		xbType src = cast(xbType)in.aux;
		a64_get(L, A64_T0, in.a, xb_type_size(src), in.op == xbOp_Sext ? xbExt_Sign : xbExt_Zero);
		a64_put(L, in.dst, A64_T0);
		break;
	}
	case xbOp_SIToF:
	case xbOp_UIToF: {
		bool sgn = in.op == xbOp_SIToF;
		xbType src = cast(xbType)in.aux;
		a64_get(L, A64_T0, in.a, xb_type_size(src), sgn ? xbExt_Sign : xbExt_Zero);
		a64_cvtf(a, sgn, size, A64_F0, A64_T0);
		a64_putf(L, in.dst, A64_F0, size);
		break;
	}
	case xbOp_FToSI:
	case xbOp_FToUI: {
		xbType src = cast(xbType)in.aux;
		i32 fs = xb_type_size(src);
		a64_getf(L, A64_F0, in.a, fs);
		a64_fcvtz(a, in.op == xbOp_FToSI, fs, A64_T0, A64_F0);
		a64_put(L, in.dst, A64_T0);
		break;
	}
	case xbOp_FExt:
		a64_getf(L, A64_F0, in.a, 4);
		a64_fcvt(a, 8, 4, A64_F0, A64_F0);
		a64_putf(L, in.dst, A64_F0, 8);
		break;
	case xbOp_FTrunc:
		a64_getf(L, A64_F0, in.a, 8);
		a64_fcvt(a, 4, 8, A64_F0, A64_F0);
		a64_putf(L, in.dst, A64_F0, 4);
		break;
	case xbOp_FToHalf: {
		i32 fs = xb_type_size(cast(xbType)in.aux);
		a64_getf(L, A64_F0, in.a, fs);
		a64_fcvt(a, 2, fs, A64_F0, A64_F0);
		a64_putf(L, in.dst, A64_F0, 2);
		break;
	}
	case xbOp_HalfToF:
		a64_getf(L, A64_F0, in.a, 2);
		a64_fcvt(a, 4, 2, A64_F0, A64_F0);
		a64_putf(L, in.dst, A64_F0, 4);
		break;
	case xbOp_Select:
		a64_get(L, A64_T0, in.a, 1, xbExt_Zero);
		a64_get(L, A64_T1, in.b, 8, xbExt_None);
		a64_get(L, A64_T2, in.c, 8, xbExt_None);
		a64_cmp_imm32(a, A64_T0, 0);
		a64_csel(a, A64_T1, A64_T1, A64_T2, A64_NE);
		a64_put(L, in.dst, A64_T1);
		break;

	case xbOp_MemCopy:
	case xbOp_MemMove: {
		i64 n = in.imm;
		a64_get(L, A64_T3, in.a, 8, xbExt_None);
		a64_get(L, A64_T4, in.b, 8, xbExt_None);
		if (n <= 64) {
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
				if (chunks[i].fp) a64_ldr_fp(a, 16, chunks[i].reg, A64_T4, chunks[i].off);
				else              a64_ldr(a, chunks[i].size, false, chunks[i].reg, A64_T4, chunks[i].off);
			}
			for (i32 i = 0; i < count; i++) {
				if (chunks[i].fp) a64_str_fp(a, 16, chunks[i].reg, A64_T3, chunks[i].off);
				else              a64_str(a, chunks[i].size, chunks[i].reg, A64_T3, chunks[i].off);
			}
		} else {
			a64_mov(a, X0, A64_T3);
			a64_mov(a, X1, A64_T4);
			a64_mov_imm(a, X2, cast(u64)n);
			a64_call_libc(L, "memmove");
		}
		break;
	}
	case xbOp_MemZero: {
		i64 n = in.imm;
		a64Addr m = a64_mem(L, in.mem);
		if (n <= 256) {
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
		a64_get(L, A64_T0, in.a, 1, xbExt_Zero);
		// cbz/cbnz only skip one instruction, so no procedure is too long for them
		if (t == L->next_block) {
			a64_cb_skip(a, true, A64_T0);
			a64_jump(L, f);
		} else if (f == L->next_block) {
			a64_cb_skip(a, false, A64_T0);
			a64_jump(L, t);
		} else {
			a64_cb_skip(a, false, A64_T0);
			a64_jump(L, t);
			a64_jump(L, f);
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
	case xbOp_ReadCycleCounter:
		a64_emit(a, 0xD53BE040 | A64_T0); // mrs x9, cntvct_el0
		a64_put(L, in.dst, A64_T0);
		break;
	case xbOp_StackPointer:
		a64_mov_sp(a, A64_T0, A64_SP);
		a64_put(L, in.dst, A64_T0);
		break;
	case xbOp_FrameAddress:
		a64_put(L, in.dst, A64_FP);
		break;
	case xbOp_ReturnAddress:
		if (in.imm) {
			a64_add_imm(a, A64_T0, A64_FP, 8);
		} else {
			a64_ldr(a, 8, false, A64_T0, A64_FP, 8);
		}
		a64_put(L, in.dst, A64_T0);
		break;
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
		a64_add_imm(a, A64_T0, A64_SP, args_area);
		a64_get(L, A64_T1, in.a, 8, xbExt_None);
		a64_alu(a, A64_SUB, A64_T0, A64_T0, A64_T1);
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
		a64_ldar(a, size, A64_T0, A64_TA);
		a64_put(L, in.dst, A64_T0);
		break;
	}
	case xbOp_AtomicStore: {
		a64_get(L, A64_T0, in.a, size, xbExt_None);
		a64Addr m = a64_mem(L, in.mem);
		a64_add_imm(a, A64_TA, m.base, m.off);
		a64_stlr(a, size, A64_T0, A64_TA);
		break;
	}
	case xbOp_AtomicRmw: {
		xbRmwOp op = cast(xbRmwOp)in.aux;
		a64_get(L, A64_T1, in.a, size, xbExt_Zero);
		a64Addr m = a64_mem(L, in.mem);
		a64_add_imm(a, A64_TA, m.base, m.off);
		switch (op) {
		case xbRmw_Xchg: a64_lse(a, A64_SWP, size, A64_T1, A64_T0, A64_TA); break;
		case xbRmw_Add:  a64_lse(a, A64_LDADD, size, A64_T1, A64_T0, A64_TA); break;
		case xbRmw_Or:   a64_lse(a, A64_LDSET, size, A64_T1, A64_T0, A64_TA); break;
		case xbRmw_Xor:  a64_lse(a, A64_LDEOR, size, A64_T1, A64_T0, A64_TA); break;
		case xbRmw_Sub:
			a64_alu(a, A64_SUB, A64_T1, XZR, A64_T1);
			a64_lse(a, A64_LDADD, size, A64_T1, A64_T0, A64_TA);
			break;
		case xbRmw_And:
			a64_alu(a, A64_ORN, A64_T1, XZR, A64_T1);
			a64_lse(a, A64_LDCLR, size, A64_T1, A64_T0, A64_TA);
			break;
		case xbRmw_Nand: {
			// no instruction for it: a compare and swap loop
			a64_ldr(a, size, false, A64_T0, A64_TA, 0);
			i64 loop = xb_pos(a);
			a64_mov(a, A64_T2, A64_T0);
			a64_alu(a, A64_AND, A64_T3, A64_T0, A64_T1);
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
		a64_get(L, A64_T0, in.a, size, xbExt_Zero);
		a64_get(L, A64_T1, in.b, size, xbExt_Zero);
		a64Addr m = a64_mem(L, in.mem);
		a64_add_imm(a, A64_TA, m.base, m.off);
		a64_mov(a, A64_T2, A64_T0);
		a64_casal(a, size, A64_T2, A64_T1, A64_TA);
		a64_cmp(a, A64_T2, A64_T0);
		a64_cset(a, A64_T0, A64_EQ);
		a64_put(L, in.dst, A64_T2);
		a64_put(L, in.c, A64_T0);
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
	case xbOp_MulHiU:
		a64_get(L, A64_T0, in.a, 8, xbExt_None);
		a64_get(L, A64_T1, in.b, 8, xbExt_None);
		a64_umulh(a, A64_T0, A64_T0, A64_T1);
		a64_put(L, in.dst, A64_T0);
		break;
	case xbOp_MulOvf: {
		bool sgn = in.aux != 0;
		GB_ASSERT(size == 4 || size == 8);
		xbExtKind ext = sgn ? xbExt_Sign : xbExt_Zero;
		a64_get(L, A64_T0, in.a, size, ext);
		a64_get(L, A64_T1, in.b, size, ext);
		a64_mul(a, A64_T2, A64_T0, A64_T1);
		if (size == 8) {
			if (sgn) {
				a64_smulh(a, A64_T3, A64_T0, A64_T1);
				a64_alu(a, A64_SUBS, XZR, A64_T3, A64_T2, A64_ASR, 63);
			} else {
				a64_umulh(a, A64_T3, A64_T0, A64_T1);
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
		a64_cset(a, A64_T0, A64_NE);
		a64_put(L, in.dst, A64_T2);
		a64_put(L, in.c, A64_T0);
		break;
	}
	case xbOp_Bswap:
		a64_get(L, A64_T0, in.a, size, xbExt_Zero);
		if (size > 1) a64_rev(a, size, A64_T0, A64_T0);
		a64_put(L, in.dst, A64_T0);
		break;
	case xbOp_Popcount:
		a64_get(L, A64_T0, in.a, size, xbExt_Zero);
		a64_fmov_to_fp(a, A64_F0, A64_T0);
		a64_cnt8b(a, A64_F0, A64_F0);
		a64_addv8b(a, A64_F0, A64_F0);
		a64_fmov_from_fp(a, A64_T0, A64_F0);
		a64_put(L, in.dst, A64_T0);
		break;
	case xbOp_Ctz:
		a64_get(L, A64_T0, in.a, size, xbExt_Zero);
		if (size < 8) {
			// a bit just above the value makes zero count as the width
			a64_mov_imm(a, A64_T1, 1ull << (8*size));
			a64_alu(a, A64_ORR, A64_T0, A64_T0, A64_T1);
		}
		a64_rbit(a, A64_T0, A64_T0);
		a64_clz(a, A64_T0, A64_T0);
		a64_put(L, in.dst, A64_T0);
		break;
	case xbOp_Clz:
		a64_get(L, A64_T0, in.a, size, xbExt_Zero);
		a64_clz(a, A64_T0, A64_T0);
		if (size < 8) a64_add_imm(a, A64_T0, A64_T0, -(64 - 8*size));
		a64_put(L, in.dst, A64_T0);
		break;
	default:
		GB_PANIC("a64: cannot lower op %d", in.op);
	}
}

////////////////////////////////////////////////////////////////
// Procedures
////////////////////////////////////////////////////////////////

gb_internal void a64_lower_proc(xbProc *p) {
	xbModule *m = p->m;
	a64Lower L = {};
	L.p = p;
	L.a.m = m;
	L.a.code = &m->sections[xbSection_Text];
	L.fixups = array_make<a64Lower::Fixup>(heap_allocator(), 0, 64);
	defer (array_free(&L.fixups));
	defer (array_free(&L.slot));
	defer (array_free(&L.uses));

	a64_lower_layout(&L);

	xbAsm *a = &L.a;
	L.proc_start = xb_pos(a);

	xbSymbol *sym = &m->symbols[p->sym];
	sym->section = xbSection_Text;
	sym->offset = L.proc_start;
	sym->flags |= xbSymbolFlag_Func;

	xbProcDebug dbg = {};
	dbg.name = p->entity ? p->entity->token.string : p->name;
	dbg.link_name = p->name;
	dbg.sym = p->sym;
	dbg.start = L.proc_start;
	dbg.file_id = p->file_id;
	dbg.line = p->entity ? p->entity->token.pos.line : 0;
	dbg.line_entry_start = cast(i32)m->lines.count;
	dbg.type = p->type;
	dbg.saved_regs = array_make<xbProcDebug::SavedReg>(heap_allocator(), 0, 0);

	// prologue
	a64_emit(a, 0xA9BF7BFD); // stp x29, x30, [sp, #-16]!
	a64_mov_sp(a, A64_FP, A64_SP);
	if (L.frame_size > 0) {
		a64_add_imm(a, A64_SP, A64_SP, -L.frame_size);
	}
	dbg.saved_at = cast(i32)(xb_pos(a) - L.proc_start);
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

	// unread pure values emit nothing
	auto skipped = [&](xbInstr const &n) -> bool {
		return n.dst != 0 && L.uses[n.dst] == 0 && xb_op_is_pure(n.op);
	};

	// cold blocks go last, so the hot path falls through
	auto order = array_make<xbBlock *>(heap_allocator(), 0, p->order.count);
	defer (array_free(&order));
	for (xbBlock *b : p->order) if (!b->cold) array_add(&order, b);
	for (xbBlock *b : p->order) if (b->cold)  array_add(&order, b);

	for (isize bi = 0; bi < order.count; bi++) {
		xbBlock *b = order[bi];
		i32 next_block = bi+1 < order.count ? order[bi+1]->index : -1;
		b->code_offset = cast(i32)xb_pos(a);
		for (isize i = 0; i < b->instrs.count; i++) {
			xbInstr const &in = b->instrs[i];
			// a jump to the next block is a fallthrough
			if (in.op == xbOp_Jump && i+1 == b->instrs.count && cast(i32)in.imm == next_block) {
				continue;
			}
			if (skipped(in)) continue;
			L.next_block = i+1 == b->instrs.count ? next_block : -1;
			a64_lower_instr(&L, in);
		}
	}
	for (auto const &f : L.fixups) {
		xbBlock *target = p->blocks[f.block];
		GB_ASSERT_MSG(target->placed, "jump to an unplaced block in %.*s", LIT(p->name));
		a64_patch_b(a, f.at, target->code_offset);
	}

	dbg.end = xb_pos(a);
	dbg.line_entry_count = cast(i32)(m->lines.count - dbg.line_entry_start);
	sym->size = dbg.end - dbg.start;

	// debug variables, now that frame offsets are known
	dbg.vars = array_make<xbDebugVar>(heap_allocator(), 0, p->debug_vars.count);
	for (xbDebugVar v : p->debug_vars) {
		if (v.local >= 0) {
			xbLocal const &l = p->locals[v.local];
			if (l.over_align > 16) {
				// the slot holds the variable's address
				if (v.by_ref || v.frame_offset_fixup != 0) continue;
				v.by_ref = true;
			}
			v.frame_offset_fixup += l.frame_offset;
		}
		array_add(&dbg.vars, v);
	}
	array_add(&m->proc_debug, dbg);
}
