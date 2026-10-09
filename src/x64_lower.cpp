// Lowering: xb IR -> x86-64 machine code.
//
// Registers come from xb_alloc_regs (xb_analysis.cpp). An interval takes rsi, rdi, r8, r9 or
// xmm4-xmm15 when no call happens in it, rbx or r12-r15 otherwise. On Win64 rsi, rdi and
// xmm6-xmm15 are callee saved too, a float interval with a call in it takes one of the latter.
// The rest live in 8 byte stack slots. A constant with one definition is materialized at each
// use, or becomes the instruction's immediate. A compare whose only use is the next branch,
// select or test against zero only sets the flags.
//
// The scratch registers are rax, rcx, rdx, r10 and r11 (r11 for addresses), and xmm0-xmm3.
// Copies and sets of a size known at run time call small helpers that only write scratch registers.
//
// Frame:
//   [rbp+16 ...]  incoming stack arguments
//   [rbp+8]       return address
//   [rbp]         saved rbp
//   [rbp-N ...]   saved callee saved registers, vreg slots, then locals
//   [rsp ...]     outgoing stack arguments
// Win64 pushes its callee saved registers above rbp instead, see x64_win64.cpp.

enum : u8 {
	X64_F0 = 0, // float scratch registers
	X64_F1 = 1,
	X64_F2 = 2,
	X64_F3 = 3,
};

// Fixed size copies up to this size are inline loads and stores.
enum : i64 { X64_INLINE_COPY = 64 };

struct xbLower {
	xbProc *    p;
	xbLowerOut *out;
	xbAsm       a;
	Array<i32>  slot;     // vreg -> rbp offset (negative), when it has no register
	Array<i32>  uses;     // vreg -> number of reads
	Array<i8>   reg;      // vreg -> the register holding it for its whole life, or XB_NOREG
	Array<u8>   is_const; // vreg -> defined once by an IConst, materialized at its uses
	Array<i64>  cval;
	Array<u8>   in_block; // vreg -> defined once, and only read later in the same block
	Array<i8>   local_reg;
	Array<u8>   remat;    // vreg -> defined once as a frame address, computed at each use from rmem
	Array<xbMem> rmem;
	u32         used_x;   // the gprs xb_alloc_regs handed out
	i32         frame_size;
	i32         max_call_stack;
	struct Fixup { i64 at; i32 block; };
	Array<Fixup> fixups;
	i64         proc_start;

	u8          saved[8];      // callee saved gprs the prologue saves, beyond rbp and Win64's rsi and rdi
	i32         saved_count;
	i32         save_offset[8]; // SysV: their rbp offsets
	i32         incoming_base;  // rbp offset of the incoming stack arguments
	u8          saved_v[10];    // Win64: callee saved xmm registers the prologue saves
	i32         saved_v_count;
	i32         win_area;       // Win64: bytes between rbp and the pushes, the pad and the xmm saves

	i32         next_block;  // the block placed right after the current branch, or -1
	bool        fuse;        // the current compare only sets the flags for the next instruction
	u32         flags_vreg;  // the compare result the flags hold
	xbCC        flags_cc;
	// what the previous instruction stored, still in a register for a load right after it
	struct Stored { bool valid; bool fp; u8 reg; i32 size; xbMem mem; bool fresh; };
	Stored      stored;
};

// The hardware number of a gpr to its DWARF number.
gb_internal u8 x64_dwarf_reg(u8 r) {
	static u8 const map[16] = {0, 2, 1, 3, 7, 6, 4, 5, 8, 9, 10, 11, 12, 13, 14, 15};
	return map[r & 15];
}

// Whether the lowering of `in` calls something or writes registers that intervals take.
gb_internal bool x64_clobbers(xbInstr const &in) {
	switch (in.op) {
	case xbOp_Call:
	case xbOp_Ret:
	case xbOp_Syscall:
	case xbOp_TlsAddr:
	case xbOp_Asm:
		return true;
	}
	return false;
}

struct x64RegTarget {
	u32 caller_x, caller_v;
	bool clobbers(xbInstr const &in) const { return x64_clobbers(in); }
	template <typename F>
	void wants(xbProc *p, xbInstr const &in, F const &note) const {
		if (in.op != xbOp_Call && in.op != xbOp_Syscall) return;
		for (xbCallArg const &arg : p->calls[cast(isize)in.imm].args) {
			if (arg.kind == xbCallArg_Gpr && (caller_x & (1u << arg.reg))) note(arg.vreg, arg.reg);
			if (arg.kind == xbCallArg_Xmm && (caller_v & (1u << arg.reg)) && xb_type_is_float(arg.type)) note(arg.vreg, XB_FREG + arg.reg);
		}
	}
	// an asm template's operands move between fixed registers and their slots
	template <typename F>
	void pins(xbProc *p, xbInstr const &in, F const &pin) const {
		if (in.op != xbOp_Asm) return;
		xbAsmBlock const &blk = p->asms[cast(isize)in.imm];
		for (xbAsmIo const &io : blk.inputs) pin(io.vreg);
		for (xbAsmIo const &io : blk.outputs) pin(io.vreg);
	}
};

gb_internal void xb_lower_layout(xbLower *L) {
	xbProc *p = L->p;
	bool win = xb_is_win64();
	u32 const rbx_r12_r15 = (1u << RBX) | (1u << R12) | (1u << R13) | (1u << R14) | (1u << R15);
	u32 const si_di = (1u << RSI) | (1u << RDI);
	u32 const r8_r9 = (1u << R8) | (1u << R9);
	xbRegPools pools = {};
	if (win) {
		pools = {r8_r9, rbx_r12_r15 | si_di, 0x0030, 0xffc0, 3};
	} else {
		pools = {r8_r9 | si_di, rbx_r12_r15, 0xfff0, 0, 3};
	}
	if (p->naked) pools = {};
	xbRegAlloc R = {};
	x64RegTarget target = {pools.caller_x, pools.caller_v};
	xb_alloc_regs(p, &R, pools, target);
	L->uses      = R.uses;
	L->reg       = R.reg;
	L->is_const  = R.is_const;
	L->cval      = R.cval;
	L->in_block  = R.in_block;
	L->local_reg = R.local_reg;
	L->remat     = R.remat;
	L->rmem      = R.rmem;
	L->used_x    = R.used_x;
	L->max_call_stack = R.max_call_stack;
	array_free(&R.clean);
	array_free(&R.via);

	// the callee saved registers in use, saved in this order
	L->saved_count = 0;
	u8 const order[5] = {RBX, R12, R13, R14, R15};
	for (u8 r : order) {
		if (R.used_x & (1u << r)) L->saved[L->saved_count++] = r;
	}
	L->saved_v_count = 0;
	if (win) {
		for (u8 r = 6; r < 16; r++) {
			if (R.used_v & (1u << r)) L->saved_v[L->saved_v_count++] = r;
		}
	}
	i32 cur = 0;
	if (!win) {
		for (i32 i = 0; i < L->saved_count; i++) {
			cur += 8;
			L->save_offset[i] = -cur;
		}
	}

	// vreg slots nearest rbp, where one byte offsets reach them
	xb_alloc_slots(p, &R, &cur);
	L->slot = R.slot;

	for (isize i = 0; i < p->locals.count; i++) {
		xbLocal &l = p->locals[i];
		if (L->local_reg[i] >= 0) {
			l.frame_offset = 0; // it lives in its register
			continue;
		}
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

// v's value of `size` bytes extended as `ext` asks
gb_internal i64 x64_ext_value(i64 v, i32 size, xbExtKind ext) {
	if (size >= 8 || ext == xbExt_None) return v;
	u64 mask = (1ull << (8*size)) - 1;
	u64 u = cast(u64)v & mask;
	if (ext == xbExt_Sign && (u >> (8*size - 1))) u |= ~mask;
	return cast(i64)u;
}

gb_internal bool x64_is_const(xbLower *L, u32 v, i64 *value) {
	if (v == 0 || !L->is_const[v]) return false;
	*value = L->cval[v];
	return true;
}

// v as the sign extended imm32 of a `size` byte operation
gb_internal bool x64_imm(xbLower *L, u32 v, i32 size, i32 *imm) {
	i64 k = 0;
	if (!x64_is_const(L, v, &k)) return false;
	if (size >= 8 && (k < -0x80000000ll || k > 0x7fffffffll)) return false;
	*imm = cast(i32)k;
	return true;
}

gb_internal xbOpnd x64_slot(xbLower *L, u32 v) {
	GB_ASSERT(v != 0 && L->reg[v] == XB_NOREG && !L->is_const[v] && !L->remat[v]);
	return xb_m(RBP, L->slot[v]);
}

// mov dst, src extended from `size` bytes as `ext` asks; xbExt_None leaves the high bytes as they come
gb_internal void x64_extend(xbAsm *a, xbExtKind ext, i32 size, u8 dst, u8 src) {
	if (size >= 8 || ext == xbExt_None) {
		if (dst != src) xb_mov_r_rm(a, 8, dst, xb_r(src));
		return;
	}
	xb_load_ext(a, size, ext == xbExt_Sign, dst, xb_r(src));
}

gb_internal void x64_movaps(xbAsm *a, u8 x, u8 y) {
	if (x != y) xb_enc(a, XB_0F, 0x28, x, xb_r(y));
}

// A machine memory operand for an IR memory reference. May clobber `scratch`.
gb_internal xbOpnd xb_mem_opnd(xbLower *L, xbMem const &m, u8 scratch=R11);

// A gpr holding v: its own, or `scratch` loaded with it. Narrow values come extended as `ext`
// asks; with xbExt_None only the low `size` bytes mean anything.
gb_internal u8 x64_src(xbLower *L, u32 v, u8 scratch, i32 size, xbExtKind ext) {
	GB_ASSERT(v != 0);
	xbAsm *a = &L->a;
	bool extend = size < 8 && ext != xbExt_None;
	i64 k = 0;
	if (x64_is_const(L, v, &k)) {
		u64 u = cast(u64)x64_ext_value(k, size, ext);
		if (!extend && size <= 4) u = cast(u32)u; // the short form
		xb_mov_r_imm(a, scratch, u);
		return scratch;
	}
	if (L->remat[v]) {
		xb_lea(a, scratch, xb_mem_opnd(L, L->rmem[v], scratch));
		return scratch;
	}
	i8 r = L->reg[v];
	if (r >= XB_FREG) {
		xb_movd_rm_x(a, 8, xb_r(scratch), cast(u8)(r - XB_FREG));
		return scratch;
	}
	if (r != XB_NOREG) {
		if (!extend) return cast(u8)r;
		x64_extend(a, ext, size, scratch, cast(u8)r);
		return scratch;
	}
	xb_load_ext(a, gb_min(size, 8), ext == xbExt_Sign, scratch, x64_slot(L, v));
	return scratch;
}

// Like x64_src, into exactly `reg`.
gb_internal void x64_get(xbLower *L, u8 reg, u32 v, i32 size, xbExtKind ext) {
	u8 r = x64_src(L, v, reg, size, ext);
	if (r != reg) xb_mov_r_rm(&L->a, 8, reg, xb_r(r));
}

// v as an operand of a `size` byte instruction: its register or slot, or `scratch` loaded with it.
gb_internal xbOpnd x64_opnd(xbLower *L, u32 v, u8 scratch, i32 size) {
	bool computed = v == 0 || L->is_const[v] || L->remat[v];
	i8 r = !computed ? L->reg[v] : XB_NOREG;
	if (!computed && r == XB_NOREG) return x64_slot(L, v);
	if (r != XB_NOREG && r < XB_FREG) return xb_r(cast(u8)r);
	return xb_r(x64_src(L, v, scratch, size, xbExt_None));
}

// An xmm register holding v's `size` byte float: its own, or `scratch` loaded with it.
gb_internal u8 x64_srcf(xbLower *L, u32 v, u8 scratch, i32 size) {
	GB_ASSERT(v != 0);
	xbAsm *a = &L->a;
	i64 k = 0;
	if (x64_is_const(L, v, &k)) {
		xb_mov_r_imm(a, R10, cast(u64)k);
		xb_movd_x_rm(a, 8, scratch, xb_r(R10));
		return scratch;
	}
	i8 r = L->reg[v];
	if (r >= XB_FREG) return cast(u8)(r - XB_FREG);
	if (r != XB_NOREG) {
		xb_movd_x_rm(a, 8, scratch, xb_r(cast(u8)r));
		return scratch;
	}
	xb_movs_x_rm(a, size == 4 ? 4 : 8, scratch, x64_slot(L, v));
	return scratch;
}

gb_internal void x64_getf(xbLower *L, u8 x, u32 v, i32 size) {
	x64_movaps(&L->a, x, x64_srcf(L, v, x, size));
}

// v as the float operand of an sse instruction: its register or slot, or `scratch` loaded with it.
gb_internal xbOpnd x64_opndf(xbLower *L, u32 v, u8 scratch, i32 size) {
	if (v != 0 && !L->is_const[v] && L->reg[v] == XB_NOREG) return x64_slot(L, v);
	return xb_r(x64_srcf(L, v, scratch, size));
}

// The gpr to compute v into: its own, or `scratch`. x64_put finishes the definition.
gb_internal u8 x64_dst(xbLower *L, u32 v, u8 scratch) {
	i8 r = L->reg[v];
	return r != XB_NOREG && r < XB_FREG ? cast(u8)r : scratch;
}

gb_internal u8 x64_dstf(xbLower *L, u32 v, u8 scratch) {
	i8 r = L->reg[v];
	return r >= XB_FREG ? cast(u8)(r - XB_FREG) : scratch;
}

// Defines v from the gpr `reg`.
gb_internal void x64_put(xbLower *L, u32 v, u8 reg) {
	GB_ASSERT(v != 0 && !L->is_const[v]);
	xbAsm *a = &L->a;
	i8 r = L->reg[v];
	if (r >= XB_FREG) {
		xb_movd_x_rm(a, 8, cast(u8)(r - XB_FREG), xb_r(reg));
	} else if (r != XB_NOREG) {
		if (r != reg) xb_mov_r_rm(a, 8, cast(u8)r, xb_r(reg));
	} else {
		xb_mov_rm_r(a, 8, x64_slot(L, v), reg);
	}
}

// Defines v from the `size` byte float in the xmm register `x`.
gb_internal void x64_putf(xbLower *L, u32 v, u8 x, i32 size) {
	GB_ASSERT(v != 0 && !L->is_const[v]);
	xbAsm *a = &L->a;
	i8 r = L->reg[v];
	if (r >= XB_FREG) {
		x64_movaps(a, cast(u8)(r - XB_FREG), x);
	} else if (r != XB_NOREG) {
		xb_movd_rm_x(a, 8, xb_r(cast(u8)r), x);
	} else {
		xb_movs_rm_x(a, size == 4 ? 4 : 8, x64_slot(L, v), x);
	}
}

// A machine memory operand for an IR memory reference. May clobber `scratch`.
gb_internal xbOpnd xb_mem_opnd(xbLower *L, xbMem const &m, u8 scratch) {
	xbAsm *a = &L->a;
	switch (m.kind) {
	case xbMem_Local: {
		GB_ASSERT(L->local_reg[m.base] < 0);
		xbLocal const &l = L->p->locals[m.base];
		if (l.over_align > 16) {
			xb_mov_r_rm(a, 8, scratch, xb_m(RBP, l.frame_offset));
			return xb_m(scratch, cast(i32)m.offset);
		}
		return xb_m(RBP, l.frame_offset + cast(i32)m.offset);
	}
	case xbMem_Incoming:
		return xb_m(RBP, L->incoming_base + cast(i32)m.offset);
	case xbMem_Reg:
		if (L->remat[m.base]) {
			// the frame address folds into the access
			xbMem f = L->rmem[m.base];
			f.offset += m.offset;
			return xb_mem_opnd(L, f, scratch);
		}
		return xb_m(x64_src(L, m.base, scratch, 8, xbExt_None), cast(i32)m.offset);
	case xbMem_Sym: {
		xbSymbol *s = &L->p->m->symbols[m.base];
		if ((s->flags & xbSymbolFlag_TLS) && xb_is_win64()) {
			return xb_win64_tls_opnd(L, m, scratch);
		}
		if ((s->flags & xbSymbolFlag_Foreign) && s->section == xbSection_Undef && xb_is_win64()) {
			if (s->flags & xbSymbolFlag_Func) return xb_m_sym(cast(i32)m.base, cast(i32)m.offset);
			return xb_win64_import_opnd(L, m, scratch);
		}
		if (s->flags & xbSymbolFlag_TLS) {
			GB_ASSERT_MSG(!xb_is_darwin(), "thread local %.*s is reached through xbOp_TlsAddr", LIT(s->name));
			// initial exec: the thread pointer plus the variable's offset from the GOT
			// mov scratch, fs:[0]
			xb_b(a, 0x64);
			xb_b(a, cast(u8)(0x48 | ((scratch & 8) ? 4 : 0)));
			xb_b(a, 0x8B);
			xb_b(a, cast(u8)(0x04 | ((scratch & 7) << 3)));
			xb_b(a, 0x25);
			xb_u32(a, 0);
			// add scratch, [rip + sym@GOTTPOFF]
			xb_enc(a, XB_W, 0x03, scratch, xb_m_sym(cast(i32)m.base, 0, xbReloc_GOTTPOFF));
			return xb_m(scratch, cast(i32)m.offset);
		}
		bool preemptible = (s->flags & xbSymbolFlag_Export) &&
		                   (build_context.build_mode == BuildMode_DynamicLibrary || build_context.reloc_mode == RelocMode_PIC);
		if (((s->flags & xbSymbolFlag_Foreign) && s->section == xbSection_Undef) || preemptible) {
			// mov scratch, [rip + sym@GOTPCREL]
			xb_enc(a, XB_W, 0x8B, scratch, xb_m_sym(cast(i32)m.base, 0, xbReloc_REX_GOTPCRELX));
			return xb_m(scratch, cast(i32)m.offset);
		}
		return xb_m_sym(cast(i32)m.base, cast(i32)m.offset);
	}
	}
	GB_PANIC("bad mem");
	return {};
}

// A memory operand that takes no rip relative form: a symbol's address goes in `scratch` first.
gb_internal xbOpnd x64_mem_base(xbLower *L, xbMem const &m, u8 scratch=R11) {
	xbOpnd o = xb_mem_opnd(L, m, scratch);
	if (o.reg == XB_RIP) {
		xb_lea(&L->a, scratch, o);
		o = xb_m(scratch, 0);
	}
	return o;
}

gb_internal void xb_load_xmm(xbLower *L, u8 x, xbOpnd m, i32 size) {
	xbAsm *a = &L->a;
	switch (size) {
	case 2:
		xb_load_ext(a, 2, false, R10, m);
		xb_movd_x_rm(a, 4, x, xb_r(R10));
		break;
	case 4: xb_movs_x_rm(a, 4, x, m); break;
	case 6: {
		// three f16s: movss the low four bytes, then pinsrw x, [m+4], 2
		xb_movs_x_rm(a, 4, x, m);
		xbOpnd m2 = m;
		m2.disp += 4;
		xb_enc(a, XB_P66|XB_0F, 0xC4, x, m2, 1);
		xb_b(a, 2);
		break;
	}
	case 8: xb_movs_x_rm(a, 8, x, m); break;
	case 16: xb_movups_x_m(a, x, m); break;
	case 32: case 64: xb_vmovups_wide(a, size, true, x, m); break;
	default:
		GB_PANIC("bad xmm load size %d", size);
	}
}

gb_internal void xb_store_xmm(xbLower *L, xbOpnd m, u8 x, i32 size) {
	xbAsm *a = &L->a;
	switch (size) {
	case 2:
		xb_movd_rm_x(a, 4, xb_r(R10), x);
		xb_mov_rm_r(a, 2, m, R10);
		break;
	case 4: xb_movs_rm_x(a, 4, m, x); break;
	case 6: {
		xb_movs_rm_x(a, 4, m, x);
		// pextrw r10d, x, 2
		xb_enc(a, XB_P66|XB_0F, 0xC5, R10, xb_r(x));
		xb_b(a, 2);
		xbOpnd m2 = m;
		m2.disp += 4;
		xb_mov_rm_r(a, 2, m2, R10);
		break;
	}
	case 8: xb_movs_rm_x(a, 8, m, x); break;
	case 16: xb_movups_m_x(a, m, x); break;
	case 32: case 64: xb_vmovups_wide(a, size, false, x, m); break;
	default:
		GB_PANIC("bad xmm store size %d", size);
	}
}

// Loads `size` (1..8) bytes from memory into a gpr, zero extended.
gb_internal void xb_load_bytes_gpr(xbLower *L, u8 reg, xbOpnd m, i32 size, xbExtKind ext) {
	xbAsm *a = &L->a;
	switch (size) {
	case 1: case 2: case 4: case 8:
		xb_load_ext(a, size, ext == xbExt_Sign, reg, m);
		return;
	}
	// odd sizes: assemble from pieces, high part first
	GB_ASSERT(m.is_mem && m.reg != XB_RIP);
	GB_ASSERT(reg != R10 && m.reg != R10);
	i32 lo = size > 4 ? 4 : 2;
	xb_load_ext(a, lo, false, reg, m);
	i32 rest = size - lo;
	xbOpnd m2 = m;
	m2.disp += lo;
	if (rest == 1 || rest == 2 || rest == 4) {
		xb_load_ext(a, rest, false, R10, m2);
	} else {
		// rest == 3: two bytes then one
		xb_load_ext(a, 2, false, R10, m2);
		xbOpnd m3 = m;
		m3.disp += lo + 2;
		xb_push(a, reg);
		xb_load_ext(a, 1, false, reg, m3);
		xb_shift_imm(a, 4, 8, xb_r(reg), 16);
		xb_alu_r_rm(a, ALU_OR, 8, R10, xb_r(reg));
		xb_pop(a, reg);
	}
	xb_shift_imm(a, 4, 8, xb_r(R10), cast(u8)(8*lo));
	xb_alu_r_rm(a, ALU_OR, 8, reg, xb_r(R10));
}

// Stores the low `size` (1..8) bytes of a gpr. Clobbers the register for odd sizes.
gb_internal void xb_store_bytes_gpr(xbLower *L, xbOpnd m, u8 reg, i32 size) {
	xbAsm *a = &L->a;
	switch (size) {
	case 1: case 2: case 4: case 8:
		xb_mov_rm_r(a, size, m, reg);
		return;
	}
	i32 off = 0;
	while (size > 0) {
		i32 chunk = size >= 4 ? 4 : (size >= 2 ? 2 : 1);
		xbOpnd mm = m;
		mm.disp += off;
		xb_mov_rm_r(a, chunk, mm, reg);
		xb_shift_imm(a, 5, 8, xb_r(reg), cast(u8)(8*chunk));
		off += chunk;
		size -= chunk;
	}
}

gb_internal xbCC xb_cc_for(xbCond c) {
	switch (c) {
	case xbCond_EQ:  return CC_E;
	case xbCond_NE:  return CC_NE;
	case xbCond_SLT: return CC_L;
	case xbCond_SLE: return CC_LE;
	case xbCond_SGT: return CC_G;
	case xbCond_SGE: return CC_GE;
	case xbCond_ULT: return CC_B;
	case xbCond_ULE: return CC_BE;
	case xbCond_UGT: return CC_A;
	case xbCond_UGE: return CC_AE;
	}
	GB_PANIC("bad cond");
	return CC_E;
}


// Copies n bytes from [src] to [dst] with xmm0-xmm3 and rax, rcx, loading everything before
// storing anything, so the ranges may overlap. n <= X64_INLINE_COPY.
gb_internal void x64_copy_small(xbLower *L, xbOpnd dst, xbOpnd src, i64 n) {
	xbAsm *a = &L->a;
	GB_ASSERT(n <= X64_INLINE_COPY && dst.reg != XB_RIP && src.reg != XB_RIP);
	struct Chunk { i32 off; i32 size; };
	Chunk chunks[4] = {};
	i32 count = 0;
	auto add = [&](i64 off, i32 size) {
		Chunk c = {cast(i32)off, size};
		chunks[count++] = c;
	};
	if (n >= 16) {
		// whole xmm chunks, the last one overlapping the one before
		for (i64 off = 0; off + 16 <= n; off += 16) add(off, 16);
		if (n % 16) add(n - 16, 16);
	} else if (n >= 8) {
		add(0, 8);
		if (n > 8) add(n - 8, 8);
	} else if (n >= 4) {
		add(0, 4);
		if (n > 4) add(n - 4, 4);
	} else if (n >= 2) {
		add(0, 2);
		if (n > 2) add(n - 2, 2);
	} else if (n == 1) {
		add(0, 1);
	}
	u8 const gprs[2] = {RAX, RCX};
	for (i32 i = 0; i < count; i++) {
		xbOpnd s = src;
		s.disp += chunks[i].off;
		if (chunks[i].size == 16) xb_movups_x_m(a, cast(u8)(X64_F0 + i), s);
		else                      xb_load_ext(a, chunks[i].size, false, gprs[i], s);
	}
	for (i32 i = 0; i < count; i++) {
		xbOpnd d = dst;
		d.disp += chunks[i].off;
		if (chunks[i].size == 16) xb_movups_m_x(a, d, cast(u8)(X64_F0 + i));
		else                      xb_mov_rm_r(a, chunks[i].size, d, gprs[i]);
	}
}

// Copies n bytes from [r11] to [r10], ranges apart. Moves both pointers and clobbers rcx, xmm0.
gb_internal void x64_copy_fwd(xbLower *L, i64 n) {
	xbAsm *a = &L->a;
	if (n <= X64_INLINE_COPY) {
		x64_copy_small(L, xb_m(R10, 0), xb_m(R11, 0), n);
		return;
	}
	// 16 bytes a round, then the last 16 bytes, overlapping
	xb_mov_r_imm(a, RCX, cast(u64)(n / 16));
	i64 loop = xb_pos(a);
	xb_movups_x_m(a, X64_F0, xb_m(R11, 0));
	xb_movups_m_x(a, xb_m(R10, 0), X64_F0);
	xb_alu_rm_imm(a, ALU_ADD, 8, xb_r(R11), 16);
	xb_alu_rm_imm(a, ALU_ADD, 8, xb_r(R10), 16);
	xb_alu_rm_imm(a, ALU_SUB, 4, xb_r(RCX), 1);
	i64 j = xb_jcc32(a, CC_NE);
	xb_patch_rel32(a, j, loop);
	if (n % 16) {
		i32 back = cast(i32)(n % 16) - 16;
		xb_movups_x_m(a, X64_F0, xb_m(R11, back));
		xb_movups_m_x(a, xb_m(R10, back), X64_F0);
	}
}

// The module's memmove(rax, rdx, rcx) and memset(rdx, al, rcx), for sizes known at run time.
// They write only the scratch registers, so the registers intervals hold live through a call.
// Sizes up to 64 take overlapping loads and stores, larger ones rep movsb or rep stosb, with
// rsi and rdi kept in r11 and r10.
gb_internal i32 x64_helper(xbModule *m, bool set) {
	i32 *at = set ? &m->x64_set_helper : &m->x64_move_helper;
	if (*at != 0) return *at - 1;
	xbAsm as = {};
	as.m = m;
	as.code = &m->sections[xbSection_Text];
	as.relocs = &m->relocs;
	xbAsm *a = &as;
	while (a->code->count % 16 != 0) xb_b(a, 0xCC);
	i64 start = xb_pos(a);
	i32 sym = xb_symbol(m, set ? str_lit("__xb_memset") : str_lit("__xb_memmove"));
	m->symbols[sym].section = xbSection_Text;
	m->symbols[sym].offset = start;
	// ELF names it for debuggers and profilers, weak in case two objects bring one
	m->symbols[sym].flags = xbSymbolFlag_Func;
	if (!xb_is_win64()) m->symbols[sym].flags |= xbSymbolFlag_Global|xbSymbolFlag_Weak|xbSymbolFlag_Hidden;
	*at = sym + 1;

	auto jcc = [&](xbCC cc) -> i64 { return xb_jcc32(a, cc); };
	auto here = [&](i64 j) { xb_patch_rel32(a, j, xb_pos(a)); };
	auto cmp_n = [&](i32 k) { xb_alu_rm_imm(a, ALU_CMP, 8, xb_r(RCX), k); };
	// r = base + n, the end of a range
	auto end_of = [&](u8 r, u8 base) {
		xb_mov_r_rm(a, 8, r, xb_r(base));
		xb_alu_r_rm(a, ALU_ADD, 8, r, xb_r(RCX));
	};
	if (!set) {
		// the first and the last `c` bytes, overlapping in the middle, for n in [c, 2c]
		auto pair = [&](i32 c, i64 *skip) {
			*skip = jcc(CC_B);
			xb_load_ext(a, c, false, R10, xb_m(RDX, 0));
			end_of(R11, RDX);
			xb_load_ext(a, c, false, R11, xb_m(R11, -c));
			end_of(RDX, RAX);
			xb_mov_rm_r(a, c, xb_m(RAX, 0), R10);
			xb_mov_rm_r(a, c, xb_m(RDX, -c), R11);
			xb_ret(a);
		};
		cmp_n(16);
		i64 j_big = jcc(CC_A);
		i64 skip = 0;
		cmp_n(8);  pair(8, &skip); here(skip);
		cmp_n(4);  pair(4, &skip); here(skip);
		cmp_n(2);  pair(2, &skip); here(skip);
		cmp_n(1);
		i64 j_none = jcc(CC_B);
		xb_load_ext(a, 1, false, R10, xb_m(RDX, 0));
		xb_mov_rm_r(a, 1, xb_m(RAX, 0), R10);
		here(j_none);
		xb_ret(a);
		here(j_big);
		cmp_n(64);
		i64 j_rep = jcc(CC_A);
		// 17..64: the first and the last 16 bytes, and the 16 after and before them when n > 32
		xb_movups_x_m(a, X64_F0, xb_m(RDX, 0));
		end_of(R11, RDX);
		xb_movups_x_m(a, X64_F3, xb_m(R11, -16));
		cmp_n(32);
		i64 j_wide = jcc(CC_A);
		end_of(R11, RAX);
		xb_movups_m_x(a, xb_m(RAX, 0), X64_F0);
		xb_movups_m_x(a, xb_m(R11, -16), X64_F3);
		xb_ret(a);
		here(j_wide);
		xb_movups_x_m(a, X64_F1, xb_m(RDX, 16));
		xb_movups_x_m(a, X64_F2, xb_m(R11, -32));
		end_of(R11, RAX);
		xb_movups_m_x(a, xb_m(RAX, 0), X64_F0);
		xb_movups_m_x(a, xb_m(RAX, 16), X64_F1);
		xb_movups_m_x(a, xb_m(R11, -32), X64_F2);
		xb_movups_m_x(a, xb_m(R11, -16), X64_F3);
		xb_ret(a);
		here(j_rep);
		xb_mov_r_rm(a, 8, R10, xb_r(RDI));
		xb_mov_r_rm(a, 8, R11, xb_r(RSI));
		xb_mov_r_rm(a, 8, RDI, xb_r(RAX));
		xb_mov_r_rm(a, 8, RSI, xb_r(RDX));
		// backwards when the destination is inside the source range
		xb_alu_r_rm(a, ALU_CMP, 8, RDI, xb_r(RSI));
		i64 j_fwd = jcc(CC_BE);
		end_of(RAX, RSI);
		xb_alu_r_rm(a, ALU_CMP, 8, RDI, xb_r(RAX));
		i64 j_fwd2 = jcc(CC_AE);
		xb_lea(a, RSI, xb_m(RSI, -1));
		xb_alu_r_rm(a, ALU_ADD, 8, RSI, xb_r(RCX));
		xb_lea(a, RDI, xb_m(RDI, -1));
		xb_alu_r_rm(a, ALU_ADD, 8, RDI, xb_r(RCX));
		xb_std(a);
		xb_rep_movsb(a);
		xb_cld(a);
		i64 j_done = xb_jmp32(a);
		here(j_fwd);
		here(j_fwd2);
		xb_rep_movsb(a);
		here(j_done);
		xb_mov_r_rm(a, 8, RDI, xb_r(R10));
		xb_mov_r_rm(a, 8, RSI, xb_r(R11));
		xb_ret(a);
	} else {
		// the byte in every byte of rax
		xb_load_ext(a, 1, false, RAX, xb_r(RAX));
		xb_mov_r_imm(a, R10, 0x0101010101010101ull);
		xb_imul_r_rm(a, 8, RAX, xb_r(R10));
		end_of(R11, RDX);
		auto pair = [&](i32 c, i64 *skip) {
			*skip = jcc(CC_B);
			xb_mov_rm_r(a, c, xb_m(RDX, 0), RAX);
			xb_mov_rm_r(a, c, xb_m(R11, -c), RAX);
			xb_ret(a);
		};
		cmp_n(16);
		i64 j_big = jcc(CC_A);
		i64 skip = 0;
		cmp_n(8);  pair(8, &skip); here(skip);
		cmp_n(4);  pair(4, &skip); here(skip);
		cmp_n(2);  pair(2, &skip); here(skip);
		cmp_n(1);
		i64 j_none = jcc(CC_B);
		xb_mov_rm_r(a, 1, xb_m(RDX, 0), RAX);
		here(j_none);
		xb_ret(a);
		here(j_big);
		cmp_n(64);
		i64 j_rep = jcc(CC_A);
		xb_movd_x_rm(a, 8, X64_F0, xb_r(RAX));
		xb_enc(a, XB_P66|XB_0F, 0x6C, X64_F0, xb_r(X64_F0)); // punpcklqdq
		xb_movups_m_x(a, xb_m(RDX, 0), X64_F0);
		xb_movups_m_x(a, xb_m(R11, -16), X64_F0);
		cmp_n(32);
		i64 j_done = jcc(CC_BE);
		xb_movups_m_x(a, xb_m(RDX, 16), X64_F0);
		xb_movups_m_x(a, xb_m(R11, -32), X64_F0);
		here(j_done);
		xb_ret(a);
		here(j_rep);
		xb_mov_r_rm(a, 8, R10, xb_r(RDI));
		xb_mov_r_rm(a, 8, RDI, xb_r(RDX));
		xb_rep_stosb(a);
		xb_mov_r_rm(a, 8, RDI, xb_r(R10));
		xb_ret(a);
	}

	// no frame, the call's cfa holds throughout; Win64 takes a function without unwind info as a leaf
	if (!xb_is_win64()) {
		xbProcDebug dbg = {};
		dbg.name = m->symbols[sym].name;
		dbg.link_name = dbg.name;
		dbg.sym = sym;
		dbg.start = start;
		dbg.end = xb_pos(a);
		dbg.file_id = -1;
		dbg.line_entry_start = cast(i32)m->lines.count;
		dbg.naked = true;
		dbg.saved_regs = array_make<xbProcDebug::SavedReg>(heap_allocator(), 0, 0);
		dbg.vars = array_make<xbDebugVar>(heap_allocator(), 0, 0);
		dbg.scope_parent = array_make<i32>(heap_allocator(), 0, 1);
		array_add(&dbg.scope_parent, -1);
		dbg.inline_sites = array_make<xbInlineSite>(heap_allocator(), 0, 0);
		dbg.scope_marks = array_make<xbScopeMark>(heap_allocator(), 0, 1);
		xbScopeMark mark = {0, 0, false};
		array_add(&dbg.scope_marks, mark);
		array_add(&m->proc_debug, dbg);
	}
	m->symbols[sym].size = xb_pos(a) - start;
	return sym;
}

// The symbol of `name`, or a pending one when it does not exist yet or lacks `flags`.
// Lowering runs on worker threads, which only read the module.
gb_internal i32 xb_lower_symbol(xbModule *m, xbLowerOut *out, String name, u32 flags, i8 helper=0) {
	i32 *found = string_map_get(&m->symbol_map, name);
	if (found && (m->symbols[*found].flags & flags) == flags) return *found;
	for (isize i = 0; i < out->pending.count; i++) {
		if (out->pending[i].name == name) return XB_PENDING_SYM + cast(i32)i;
	}
	xbPendingSym ps = {name, flags, helper};
	array_add(&out->pending, ps);
	return XB_PENDING_SYM + cast(i32)(out->pending.count-1);
}

// The helper is emitted when the procedure's code is appended, right before it.
gb_internal i32 x64_lower_helper(xbLower *L, bool set) {
	xbModule *m = L->p->m;
	i32 at = set ? m->x64_set_helper : m->x64_move_helper;
	if (at != 0) return at - 1;
	return xb_lower_symbol(m, L->out, set ? str_lit("__xb_memset") : str_lit("__xb_memmove"), 0, set ? 2 : 1);
}

////////////////////////////////////////////////////////////////
// Calls
////////////////////////////////////////////////////////////////

// No vreg lives in an argument register here but the one the argument reads, so arguments
// go straight into their registers.
gb_internal void xb_lower_call(xbLower *L, xbCall const &c, bool is_ret) {
	xbAsm *a = &L->a;
	// stack arguments first, the argument registers are free to use as scratch
	for (xbCallArg const &arg : c.args) {
		switch (arg.kind) {
		case xbCallArg_Stack: {
			xbType t = arg.type;
			if (xb_type_is_float(t)) {
				u8 r = x64_srcf(L, arg.vreg, X64_F0, xb_type_size(t));
				xb_movs_rm_x(a, xb_type_size(t), xb_m(RSP, arg.stack_offset), r);
			} else {
				u8 r = x64_src(L, arg.vreg, RAX, xb_type_size(t), arg.ext == xbExt_Sign ? xbExt_Sign : xbExt_Zero);
				xb_mov_rm_r(a, 8, xb_m(RSP, arg.stack_offset), r);
			}
			break;
		}
		case xbCallArg_StackMem: {
			if (arg.type == xbType_None || arg.size > 8) {
				// a by-value copy
				xbOpnd src = xb_mem_opnd(L, arg.mem, R11);
				xb_lea(a, R11, src);
				xb_lea(a, R10, xb_m(RSP, arg.stack_offset));
				x64_copy_fwd(L, arg.size);
			} else if (arg.type == xbType_V128) {
				xbOpnd src = xb_mem_opnd(L, arg.mem, R11);
				xb_movups_x_m(a, X64_F0, src);
				xb_movups_m_x(a, xb_m(RSP, arg.stack_offset), X64_F0);
			} else {
				xbOpnd src = x64_mem_base(L, arg.mem, R11);
				xb_load_bytes_gpr(L, RAX, src, arg.size, arg.ext);
				xb_mov_rm_r(a, 8, xb_m(RSP, arg.stack_offset), RAX);
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
			x64_get(L, arg.reg, arg.vreg, size, ext);
			break;
		}
		case xbCallArg_Xmm:
			if (xb_type_is_float(arg.type)) {
				x64_getf(L, arg.reg, arg.vreg, xb_type_size(arg.type));
			} else {
				xb_load_xmm(L, arg.reg, x64_slot(L, arg.vreg), xb_type_size(arg.type));
			}
			break;
		case xbCallArg_GprMem: {
			xbExtKind ext = arg.ext;
			if (arg.size < 4 && ext == xbExt_None) ext = xbExt_Zero;
			if (arg.mem.kind == xbMem_Local && L->local_reg[arg.mem.base] >= 0) {
				// the register is callee saved, the call is in its interval
				x64_extend(a, ext, arg.size, arg.reg, cast(u8)L->local_reg[arg.mem.base]);
				break;
			}
			xbOpnd src = xb_mem_opnd(L, arg.mem, R11);
			if (src.reg == XB_RIP && (arg.size != 1 && arg.size != 2 && arg.size != 4 && arg.size != 8)) {
				xb_lea(a, R11, src);
				src = xb_m(R11, 0);
			}
			xb_load_bytes_gpr(L, arg.reg, src, arg.size, ext);
			break;
		}
		case xbCallArg_XmmMem: {
			xbOpnd src = xb_mem_opnd(L, arg.mem, R11);
			xb_load_xmm(L, arg.reg, src, arg.size);
			break;
		}
		}
	}
	if (is_ret) {
		return;
	}
	if (c.sse_count >= 0) {
		xb_mov_r_imm(a, RAX, cast(u64)c.sse_count);
	}
	if (c.target_sym >= 0) {
		xb_call_sym(a, c.target_sym);
	} else {
		xb_call_rm(a, xb_r(x64_src(L, c.target_vreg, R11, 8, xbExt_None)));
	}
	for (xbCallRet const &r : c.rets) {
		if (r.dst.kind == xbMem_Local && L->local_reg[r.dst.base] >= 0) {
			x64_extend(a, xbExt_Zero, r.size, cast(u8)L->local_reg[r.dst.base], r.reg);
			continue;
		}
		if (r.loc == xbLoc_Gpr) {
			xbOpnd dst = x64_mem_base(L, r.dst, R11);
			xb_mov_r_rm(a, 8, R10, xb_r(r.reg));
			xb_store_bytes_gpr(L, dst, R10, r.size);
		} else {
			xbOpnd dst = xb_mem_opnd(L, r.dst, R11);
			xb_store_xmm(L, dst, r.reg, r.size);
		}
	}
	if (c.rets.count == 1 && !(c.rets[0].dst.kind == xbMem_Local && L->local_reg[c.rets[0].dst.base] >= 0)) {
		xbCallRet const &r = c.rets[0];
		xbLower::Stored st = {true, r.loc != xbLoc_Gpr, r.reg, r.size, r.dst, true};
		L->stored = st;
	}
}

// vmovups ymm/zmm <-> [rax]
gb_internal void xb_vmovups_wide_rax(xbAsm *a, i32 size, bool load, u8 x) {
	xb_vmovups_wide(a, size, load, x, xb_m(RAX, 0));
}

// The operands are pinned to their slots, so loading one register never overwrites another's input.
gb_internal void xb_lower_asm(xbLower *L, xbAsmBlock const &blk) {
	xbAsm *a = &L->a;
	i32 save_base = blk.save_local >= 0 ? L->p->locals[blk.save_local].frame_offset : 0;
	i32 k = 0;
	for (u8 r = 0; r < 16; r++) {
		if (blk.save_regs & (1u << r)) xb_mov_rm_r(a, 8, xb_m(RBP, save_base + 8*k++), r);
	}
	i32 xmm_base = blk.xmm_save_local >= 0 ? L->p->locals[blk.xmm_save_local].frame_offset : 0;
	k = 0;
	for (u8 r = 0; r < 16; r++) {
		if (blk.save_xmms & (1u << r)) xb_movups_m_x(a, xb_m(RBP, xmm_base + 16*k++), r);
	}
	if (blk.rbp_local >= 0) xb_mov_rm_r(a, 8, xb_m(RBP, L->p->locals[blk.rbp_local].frame_offset), RBP);
	// vector inputs first, they go through rax
	for (xbAsmIo const &io : blk.inputs) {
		if (io.kind != xbAsmIo_XmmMem) continue;
		x64_get(L, RAX, io.vreg, 8, xbExt_None);
		if (io.size >= 32) xb_vmovups_wide_rax(a, io.size, true, io.reg);
		else xb_load_xmm(L, io.reg, xb_m(RAX, 0), io.size);
	}
	for (xbAsmIo const &io : blk.inputs) {
		if (io.kind == xbAsmIo_Xmm) xb_load_xmm(L, io.reg, x64_slot(L, io.vreg), io.size);
	}
	for (xbAsmIo const &io : blk.inputs) {
		if (io.kind == xbAsmIo_Gpr) x64_get(L, io.reg, io.vreg, io.size, io.sign ? xbExt_Sign : xbExt_Zero);
	}
	// mov ah, [rbp + slot]: no REX, so the reg field names the high byte
	for (xbAsmIo const &io : blk.inputs) {
		if (io.kind != xbAsmIo_Gpr8H) continue;
		i64 kv = 0;
		if (x64_is_const(L, io.vreg, &kv)) {
			xb_b(a, cast(u8)(0xB0 + io.reg)); // mov ah, imm8
			xb_b(a, cast(u8)kv);
		} else {
			xb_enc(a, 0, 0x8A, io.reg, x64_slot(L, io.vreg));
		}
	}
	auto code = array_make<u8>(heap_allocator(), 0, blk.pool.count + 16);
	bool fits = xb_asm_layout(blk.items, blk.pool, blk.label_count, xb_pos(a), &code);
	GB_ASSERT(fits);
	xb_bytes(a, code.data, code.count);
	array_free(&code);
	if (blk.rbp_local >= 0) {
		// rbp is not the frame yet, rsp is back where it was
		xb_mov_r_rm(a, 8, RBP, xb_m(RSP, L->frame_size + L->p->locals[blk.rbp_local].frame_offset));
	}
	// gpr outputs first, then the flags, before anything changes them, then vectors through rax
	for (xbAsmIo const &io : blk.outputs) {
		if (io.kind == xbAsmIo_Gpr) xb_mov_rm_r(a, io.size, x64_slot(L, io.vreg), io.reg);
		if (io.kind == xbAsmIo_Gpr8H) xb_enc(a, 0, 0x88, io.reg, x64_slot(L, io.vreg));
		if (io.kind == xbAsmIo_Xmm) xb_store_xmm(L, x64_slot(L, io.vreg), io.reg, io.size);
	}
	for (xbAsmIo const &io : blk.outputs) {
		if (io.kind != xbAsmIo_Flag) continue;
		xb_setcc(a, cast(xbCC)io.reg, RAX);
		xb_load_ext(a, 1, false, RAX, xb_r(RAX));
		xb_mov_rm_r(a, io.size, x64_slot(L, io.vreg), RAX);
	}
	for (xbAsmIo const &io : blk.outputs) {
		if (io.kind != xbAsmIo_XmmMem) continue;
		x64_get(L, RAX, io.vreg, 8, xbExt_None);
		if (io.size >= 32) xb_vmovups_wide_rax(a, io.size, false, io.reg);
		else xb_store_xmm(L, xb_m(RAX, 0), io.reg, io.size);
	}
	k = 0;
	for (u8 r = 0; r < 16; r++) {
		if (blk.save_regs & (1u << r)) xb_mov_r_rm(a, 8, r, xb_m(RBP, save_base + 8*k++));
	}
	k = 0;
	for (u8 r = 0; r < 16; r++) {
		if (blk.save_xmms & (1u << r)) xb_movups_x_m(a, r, xb_m(RBP, xmm_base + 16*k++));
	}
}

gb_internal void x64_epilogue(xbLower *L) {
	xbAsm *a = &L->a;
	if (L->p->naked) {
		xb_ret(a);
		return;
	}
	if (xb_is_win64()) {
		xb_win64_epilogue(L);
		return;
	}
	for (i32 i = 0; i < L->saved_count; i++) {
		xb_mov_r_rm(a, 8, L->saved[i], xb_m(RBP, L->save_offset[i]));
	}
	xb_leave(a);
	xb_ret(a);
}

// Jumps to `block`, patched once every block is placed.
gb_internal void x64_jump(xbLower *L, i32 block) {
	xbLower::Fixup f = {xb_jmp32(&L->a), block};
	array_add(&L->fixups, f);
}

// Goes to `t` when `cc` holds, else to `f`.
gb_internal void x64_branch(xbLower *L, xbCC cc, i32 t, i32 f) {
	// x86 condition codes come in pairs that differ in the low bit
	if (t == L->next_block) {
		gb_swap(i32, t, f);
		cc = cast(xbCC)(cc ^ 1);
	}
	xbLower::Fixup f1 = {xb_jcc32(&L->a, cc), t};
	array_add(&L->fixups, f1);
	if (f != L->next_block) x64_jump(L, f);
}

// Sets the flags so that CC_NE says whether the bool v is true.
gb_internal void x64_test_bool(xbLower *L, u32 v) {
	xbAsm *a = &L->a;
	i8 r = L->reg[v];
	if (!L->is_const[v] && r == XB_NOREG) {
		xb_alu_rm_imm(a, ALU_CMP, 1, x64_slot(L, v), 0);
		return;
	}
	u8 x = x64_src(L, v, RAX, 1, xbExt_None);
	xb_test_rm_r(a, 1, xb_r(x), x);
}

// Ends a compare: the flags hold `cc`, kept for the next instruction or put in dst.
gb_internal void x64_compare_result(xbLower *L, xbInstr const &in, xbCC cc) {
	if (L->fuse) {
		L->flags_vreg = in.dst;
		L->flags_cc = cc;
		return;
	}
	u8 d = x64_dst(L, in.dst, RAX);
	xb_setcc(&L->a, cc, d);
	xb_load_ext(&L->a, 1, false, d, xb_r(d));
	x64_put(L, in.dst, d);
}

////////////////////////////////////////////////////////////////
// Instructions
////////////////////////////////////////////////////////////////

gb_internal void xb_lower_instr(xbLower *L, xbInstr const &in) {
	xbAsm *a = &L->a;
	xbProc *p = L->p;
	i32 size = xb_type_size(in.type);
	i64 k = 0;
	i32 imm = 0;
	switch (in.op) {
	case xbOp_Nop:
		if (in.imm == 1) xb_b(a, 0x90);
		break;
	case xbOp_Scope:
		break;
	case xbOp_Loc: {
		xbLineEntry e = {};
		e.code_offset = cast(i32)(xb_pos(a) - L->proc_start);
		e.file_id = cast(i32)in.a;
		e.line = cast(i32)in.imm;
		e.column = cast(i32)in.b;
		array_add(&L->out->lines, e);
		break;
	}
	case xbOp_IConst:
	case xbOp_FConst: {
		i8 r = L->reg[in.dst];
		if (r == XB_NOREG && in.imm >= -0x80000000ll && in.imm <= 0x7fffffffll) {
			// mov qword [slot], simm32
			xb_enc(a, XB_W, 0xC7, 0, x64_slot(L, in.dst), 4);
			xb_u32(a, cast(u32)cast(i32)in.imm);
			break;
		}
		u8 d = x64_dst(L, in.dst, RAX);
		xb_mov_r_imm(a, d, cast(u64)in.imm);
		x64_put(L, in.dst, d);
		break;
	}
	case xbOp_Lea: {
		if (L->remat[in.dst]) break;
		u8 d = x64_dst(L, in.dst, RAX);
		xbOpnd m = xb_mem_opnd(L, in.mem, R11);
		if (m.is_mem && m.reg != XB_RIP && m.disp == 0) {
			if (m.reg != d) xb_mov_r_rm(a, 8, d, xb_r(m.reg));
		} else {
			xb_lea(a, d, m);
		}
		x64_put(L, in.dst, d);
		break;
	}
	case xbOp_Load:
	case xbOp_AtomicLoad: {
		bool fp = xb_type_is_float(in.type);
		if (in.mem.kind == xbMem_Local && L->local_reg[in.mem.base] >= 0) {
			i8 lr = L->local_reg[in.mem.base];
			if (lr >= XB_FREG) x64_putf(L, in.dst, cast(u8)(lr - XB_FREG), size);
			else               x64_put(L, in.dst, cast(u8)lr);
			break;
		}
		xbLower::Stored const &st = L->stored;
		if (in.op == xbOp_Load && st.valid && st.mem.kind == in.mem.kind && st.mem.base == in.mem.base && st.mem.offset == in.mem.offset &&
		    st.size == size && st.fp == fp && !(in.flags & xbInstrFlag_Volatile)) {
			if (fp) {
				x64_putf(L, in.dst, st.reg, size);
			} else {
				u8 d = x64_dst(L, in.dst, RAX);
				x64_extend(a, xbExt_Zero, size, d, st.reg);
				x64_put(L, in.dst, d);
			}
			break;
		}
		xbOpnd m = xb_mem_opnd(L, in.mem, R11);
		if (fp) {
			u8 d = x64_dstf(L, in.dst, X64_F0);
			xb_movs_x_rm(a, size, d, m);
			x64_putf(L, in.dst, d, size);
		} else {
			u8 d = x64_dst(L, in.dst, RAX);
			xb_load_ext(a, size, false, d, m);
			x64_put(L, in.dst, d);
		}
		break;
	}
	case xbOp_Store: {
		if (in.mem.kind == xbMem_Local && L->local_reg[in.mem.base] >= 0) {
			i8 lr = L->local_reg[in.mem.base];
			// zero extended, as a load from memory would give it back
			if (lr >= XB_FREG) x64_getf(L, cast(u8)(lr - XB_FREG), in.a, size);
			else               x64_get(L, cast(u8)lr, in.a, size, xbExt_Zero);
			break;
		}
		xbLower::Stored st = {true, xb_type_is_float(in.type), 0, size, in.mem, true};
		if (st.fp) {
			st.reg = x64_srcf(L, in.a, X64_F0, size);
			xbOpnd m = xb_mem_opnd(L, in.mem, R11);
			xb_movs_rm_x(a, size, m, st.reg);
		} else if (x64_imm(L, in.a, size, &imm)) {
			xbOpnd m = xb_mem_opnd(L, in.mem, R11);
			// mov rm, imm, sign extended for qwords
			xb_enc(a, xb_size_flags(size), size == 1 ? 0xC6 : 0xC7, 0, m, gb_min(size, 4));
			switch (size) {
			case 1: xb_b(a, cast(u8)imm); break;
			case 2: xb_u16(a, cast(u16)imm); break;
			default: xb_u32(a, cast(u32)imm); break;
			}
			st.valid = false;
		} else {
			// the value first, the address may need r11
			st.reg = x64_src(L, in.a, RAX, size, xbExt_None);
			xbOpnd m = xb_mem_opnd(L, in.mem, R11);
			xb_mov_rm_r(a, size, m, st.reg);
		}
		if (!(in.flags & xbInstrFlag_Volatile) && st.valid) L->stored = st;
		break;
	}
	case xbOp_AtomicStore: {
		x64_get(L, RAX, in.a, size, xbExt_None);
		xbOpnd m = xb_mem_opnd(L, in.mem, R11);
		// xchg is a full barrier
		xb_enc(a, xb_size_flags(size), size == 1 ? 0x86 : 0x87, RAX, m);
		break;
	}
	case xbOp_Copy:
	case xbOp_Trunc:
	case xbOp_Bitcast: {
		bool df = xb_type_is_float(p->vregs[in.dst]);
		bool sf = xb_type_is_float(p->vregs[in.a]);
		if (df && sf) {
			i32 fs = xb_type_size(p->vregs[in.dst]);
			x64_putf(L, in.dst, x64_srcf(L, in.a, x64_dstf(L, in.dst, X64_F0), fs), fs);
			break;
		}
		u8 d = x64_dst(L, in.dst, RAX);
		x64_put(L, in.dst, x64_src(L, in.a, d, 8, xbExt_None));
		break;
	}

	case xbOp_Add:
	case xbOp_Sub:
	case xbOp_And:
	case xbOp_Or:
	case xbOp_Xor: {
		xbAluOp op = ALU_ADD;
		switch (in.op) {
		case xbOp_Add: op = ALU_ADD; break;
		case xbOp_Sub: op = ALU_SUB; break;
		case xbOp_And: op = ALU_AND; break;
		case xbOp_Or:  op = ALU_OR;  break;
		case xbOp_Xor: op = ALU_XOR; break;
		}
		// narrow values compute in 32 bits, only their low bytes mean anything
		i32 s = gb_max(size, 4);
		bool commutes = in.op != xbOp_Sub;
		u32 x = in.a, y = in.b;
		if (commutes && L->is_const[x] && !L->is_const[y]) gb_swap(u32, x, y);
		u8 d = x64_dst(L, in.dst, RAX);
		if (!L->is_const[y] && L->reg[y] == cast(i8)d) {
			if (commutes) gb_swap(u32, x, y);
			else          d = RAX;
		}
		i8 rx = L->is_const[x] ? XB_NOREG : L->reg[x];
		if ((in.op == xbOp_Add || in.op == xbOp_Sub) && rx != XB_NOREG && rx < XB_FREG && rx != cast(i8)d &&
		    x64_imm(L, y, 8, &imm) && imm != INT32_MIN) {
			// a three operand add
			xb_lea(a, d, xb_m(cast(u8)rx, in.op == xbOp_Add ? imm : -imm));
			x64_put(L, in.dst, d);
			break;
		}
		x64_get(L, d, x, s, xbExt_None);
		if (x64_imm(L, y, s, &imm)) {
			xb_alu_rm_imm(a, op, s, xb_r(d), imm);
		} else {
			xb_alu_r_rm(a, op, s, d, x64_opnd(L, y, RCX, s));
		}
		x64_put(L, in.dst, d);
		break;
	}
	case xbOp_Mul: {
		i32 s = gb_max(size, 4);
		u32 x = in.a, y = in.b;
		if (L->is_const[x] && !L->is_const[y]) gb_swap(u32, x, y);
		u8 d = x64_dst(L, in.dst, RAX);
		if (!L->is_const[y] && L->reg[y] == cast(i8)d) gb_swap(u32, x, y);
		if (x64_imm(L, y, s, &imm)) {
			// imul d, x, imm
			bool imm8 = imm >= -128 && imm <= 127;
			xb_enc(a, xb_size_flags(s), imm8 ? 0x6B : 0x69, d, x64_opnd(L, x, d, s), imm8 ? 1 : 4);
			if (imm8) xb_b(a, cast(u8)cast(i8)imm);
			else       xb_u32(a, cast(u32)imm);
		} else {
			x64_get(L, d, x, s, xbExt_None);
			xb_imul_r_rm(a, s, d, x64_opnd(L, y, RCX, s));
		}
		x64_put(L, in.dst, d);
		break;
	}
	case xbOp_SDiv:
	case xbOp_SRem:
	case xbOp_UDiv:
	case xbOp_URem: {
		bool sgn = in.op == xbOp_SDiv || in.op == xbOp_SRem;
		xbExtKind ext = sgn ? xbExt_Sign : xbExt_Zero;
		i32 s = gb_max(size, 4);
		x64_get(L, RAX, in.a, size, ext);
		u8 rb = x64_src(L, in.b, RCX, size, ext);
		if (sgn) {
			xb_sign_extend_rdx(a, s);
			xb_grp3(a, 7, s, xb_r(rb));
		} else {
			xb_alu_r_rm(a, ALU_XOR, 4, RDX, xb_r(RDX));
			xb_grp3(a, 6, s, xb_r(rb));
		}
		bool rem = in.op == xbOp_SRem || in.op == xbOp_URem;
		x64_put(L, in.dst, rem ? RDX : RAX);
		break;
	}
	case xbOp_Shl:
	case xbOp_LShr:
	case xbOp_AShr: {
		i32 s = gb_max(size, 4);
		u8 n = in.op == xbOp_Shl ? 4 : (in.op == xbOp_LShr ? 5 : 7);
		xbExtKind ext = in.op == xbOp_AShr ? xbExt_Sign : in.op == xbOp_LShr ? xbExt_Zero : xbExt_None;
		u8 d = x64_dst(L, in.dst, RAX);
		if (x64_is_const(L, in.b, &k)) {
			x64_get(L, d, in.a, size, ext);
			// the cpu masks an immediate count like it masks cl
			xb_shift_imm(a, n, s, xb_r(d), cast(u8)k);
		} else {
			x64_get(L, RCX, in.b, 8, xbExt_None);
			x64_get(L, d, in.a, size, ext);
			xb_shift_cl(a, n, s, xb_r(d));
		}
		x64_put(L, in.dst, d);
		break;
	}
	case xbOp_FAdd:
	case xbOp_FSub:
	case xbOp_FMul:
	case xbOp_FDiv: {
		xbSseOp op = SSE_ADD;
		switch (in.op) {
		case xbOp_FAdd: op = SSE_ADD; break;
		case xbOp_FSub: op = SSE_SUB; break;
		case xbOp_FMul: op = SSE_MUL; break;
		case xbOp_FDiv: op = SSE_DIV; break;
		}
		bool commutes = in.op == xbOp_FAdd || in.op == xbOp_FMul;
		u32 x = in.a, y = in.b;
		u8 d = x64_dstf(L, in.dst, X64_F0);
		if (!L->is_const[y] && L->reg[y] == cast(i8)(XB_FREG + d)) {
			if (commutes) gb_swap(u32, x, y);
			else          d = X64_F0;
		}
		x64_getf(L, d, x, size);
		xb_sse_scalar(a, op, size, d, x64_opndf(L, y, X64_F1, size));
		x64_putf(L, in.dst, d, size);
		break;
	}
	case xbOp_Sqrt: {
		u8 d = x64_dstf(L, in.dst, X64_F0);
		xb_sse_scalar(a, SSE_SQRT, size, d, x64_opndf(L, in.a, X64_F1, size));
		x64_putf(L, in.dst, d, size);
		break;
	}
	case xbOp_Fma:
		x64_getf(L, X64_F0, in.a, size);
		x64_getf(L, X64_F1, in.b, size);
		xb_vfmadd213_s(a, size, X64_F0, X64_F1, x64_opndf(L, in.c, X64_F2, size));
		x64_putf(L, in.dst, X64_F0, size);
		break;
	case xbOp_Neg:
	case xbOp_Not: {
		u8 d = x64_dst(L, in.dst, RAX);
		x64_get(L, d, in.a, size, xbExt_None);
		xb_grp3(a, in.op == xbOp_Neg ? 3 : 2, gb_max(size, 4), xb_r(d));
		x64_put(L, in.dst, d);
		break;
	}
	case xbOp_FNeg: {
		u8 d = x64_dstf(L, in.dst, X64_F0);
		x64_getf(L, d, in.a, size);
		xb_mov_r_imm(a, RAX, size == 4 ? 0x80000000ull : 0x8000000000000000ull);
		xb_movd_x_rm(a, 8, X64_F1, xb_r(RAX));
		xb_xorps(a, d, X64_F1);
		x64_putf(L, in.dst, d, size);
		break;
	}
	case xbOp_ICmp: {
		xbCond c = cast(xbCond)in.aux;
		if (in.a == L->flags_vreg) {
			// a test against zero of the compare that set the flags
			GB_ASSERT(c == xbCond_EQ || c == xbCond_NE);
			xbCC cc = c == xbCond_NE ? L->flags_cc : cast(xbCC)(L->flags_cc ^ 1);
			L->flags_vreg = 0;
			x64_compare_result(L, in, cc);
			break;
		}
		if (x64_imm(L, in.b, size, &imm)) {
			xb_alu_rm_imm(a, ALU_CMP, size, x64_opnd(L, in.a, RAX, size), imm);
		} else {
			u8 ra = x64_src(L, in.a, RAX, size, xbExt_None);
			xb_alu_r_rm(a, ALU_CMP, size, ra, x64_opnd(L, in.b, RCX, size));
		}
		x64_compare_result(L, in, xb_cc_for(c));
		break;
	}
	case xbOp_FCmp: {
		xbCond c = cast(xbCond)in.aux;
		u32 x = in.a;
		u32 y = in.b;
		if (c == xbCond_FLT || c == xbCond_FLE) {
			// a < b  <=>  b > a
			x = in.b;
			y = in.a;
		}
		u8 rx = x64_srcf(L, x, X64_F0, size);
		xb_ucomis(a, size, rx, x64_opndf(L, y, X64_F1, size));
		switch (c) {
		case xbCond_FGT:
		case xbCond_FLT:
			x64_compare_result(L, in, CC_A);
			break;
		case xbCond_FGE:
		case xbCond_FLE:
			x64_compare_result(L, in, CC_AE);
			break;
		case xbCond_FEQ:
		case xbCond_FNE: {
			GB_ASSERT(!L->fuse);
			bool eq = c == xbCond_FEQ;
			// unordered sets the parity flag
			xb_setcc(a, eq ? CC_E : CC_NE, RAX);
			xb_setcc(a, eq ? CC_NP : CC_P, RCX);
			xb_alu_r_rm(a, eq ? ALU_AND : ALU_OR, 1, RAX, xb_r(RCX));
			xb_load_ext(a, 1, false, RAX, xb_r(RAX));
			x64_put(L, in.dst, RAX);
			break;
		}
		default:
			GB_PANIC("bad float cond");
		}
		break;
	}
	case xbOp_Zext:
	case xbOp_Sext: {
		xbType src = cast(xbType)in.aux;
		u8 d = x64_dst(L, in.dst, RAX);
		x64_put(L, in.dst, x64_src(L, in.a, d, xb_type_size(src), in.op == xbOp_Sext ? xbExt_Sign : xbExt_Zero));
		break;
	}
	case xbOp_SIToF: {
		xbType src = cast(xbType)in.aux;
		u8 r = x64_src(L, in.a, RAX, xb_type_size(src), xbExt_Sign);
		u8 d = x64_dstf(L, in.dst, X64_F0);
		xb_cvtsi2f(a, size, 8, d, xb_r(r));
		x64_putf(L, in.dst, d, size);
		break;
	}
	case xbOp_UIToF: {
		xbType src = cast(xbType)in.aux;
		i32 ss = xb_type_size(src);
		u8 d = x64_dstf(L, in.dst, X64_F0);
		x64_get(L, RAX, in.a, ss, xbExt_Zero);
		if (ss < 8) {
			xb_cvtsi2f(a, size, 8, d, xb_r(RAX));
		} else {
			xb_test_rm_r(a, 8, xb_r(RAX), RAX);
			i64 j_neg = xb_jcc32(a, CC_S);
			xb_cvtsi2f(a, size, 8, d, xb_r(RAX));
			i64 j_done = xb_jmp32(a);
			xb_patch_rel32(a, j_neg, xb_pos(a));
			// halve it keeping the low bit for the rounding, convert, double
			xb_mov_r_rm(a, 8, RCX, xb_r(RAX));
			xb_shift_imm(a, 5, 8, xb_r(RCX), 1);
			xb_alu_rm_imm(a, ALU_AND, 4, xb_r(RAX), 1);
			xb_alu_r_rm(a, ALU_OR, 8, RCX, xb_r(RAX));
			xb_cvtsi2f(a, size, 8, d, xb_r(RCX));
			xb_sse_scalar(a, SSE_ADD, size, d, xb_r(d));
			xb_patch_rel32(a, j_done, xb_pos(a));
		}
		x64_putf(L, in.dst, d, size);
		break;
	}
	case xbOp_FToSI: {
		i32 fs = xb_type_size(cast(xbType)in.aux);
		u8 d = x64_dst(L, in.dst, RAX);
		xb_cvttf2si(a, fs, size >= 8 ? 8 : 4, d, x64_opndf(L, in.a, X64_F0, fs));
		x64_put(L, in.dst, d);
		break;
	}
	case xbOp_FToUI: {
		i32 fs = xb_type_size(cast(xbType)in.aux);
		x64_getf(L, X64_F0, in.a, fs);
		// 2^63 as a float of the source size
		if (fs == 4) {
			xb_mov_r_imm(a, RAX, 0x5f000000ull);
			xb_movd_x_rm(a, 4, X64_F1, xb_r(RAX));
		} else {
			xb_mov_r_imm(a, RAX, 0x43e0000000000000ull);
			xb_movd_x_rm(a, 8, X64_F1, xb_r(RAX));
		}
		xb_ucomis(a, fs, X64_F0, xb_r(X64_F1));
		i64 j_big = xb_jcc32(a, CC_AE);
		xb_cvttf2si(a, fs, 8, RAX, xb_r(X64_F0));
		i64 j_done = xb_jmp32(a);
		xb_patch_rel32(a, j_big, xb_pos(a));
		xb_sse_scalar(a, SSE_SUB, fs, X64_F0, xb_r(X64_F1));
		xb_cvttf2si(a, fs, 8, RAX, xb_r(X64_F0));
		xb_mov_r_imm(a, RCX, 0x8000000000000000ull);
		xb_alu_r_rm(a, ALU_XOR, 8, RAX, xb_r(RCX));
		xb_patch_rel32(a, j_done, xb_pos(a));
		x64_put(L, in.dst, RAX);
		break;
	}
	case xbOp_FExt:
	case xbOp_FTrunc: {
		bool ext = in.op == xbOp_FExt;
		u8 d = x64_dstf(L, in.dst, X64_F0);
		// cvtss2sd or cvtsd2ss
		xb_sse_scalar(a, SSE_CVT, ext ? 4 : 8, d, x64_opndf(L, in.a, X64_F1, ext ? 4 : 8));
		x64_putf(L, in.dst, d, ext ? 8 : 4);
		break;
	}
	case xbOp_Select: {
		xbCC cc = CC_NE;
		if (in.a == L->flags_vreg) {
			cc = L->flags_cc;
			L->flags_vreg = 0;
		} else {
			x64_test_bool(L, in.a);
		}
		// nothing below changes the flags: plain movs and cmov
		bool fp = xb_type_is_float(in.type);
		u8 d = fp ? RAX : x64_dst(L, in.dst, RAX);
		if (!L->is_const[in.b] && L->reg[in.b] == cast(i8)d) d = RAX;
		xbOpnd rb = x64_opnd(L, in.b, RCX, 8);
		x64_get(L, d, in.c, 8, xbExt_None);
		xb_cmov(a, cc, 8, d, rb);
		x64_put(L, in.dst, d);
		break;
	}

	case xbOp_MemCopy:
	case xbOp_MemMove: {
		i64 n = in.imm;
		if (n <= X64_INLINE_COPY) {
			u8 dst = x64_src(L, in.a, R10, 8, xbExt_None);
			u8 src = x64_src(L, in.b, R11, 8, xbExt_None);
			x64_copy_small(L, xb_m(dst, 0), xb_m(src, 0), n);
		} else {
			x64_get(L, RDX, in.b, 8, xbExt_None);
			x64_get(L, RAX, in.a, 8, xbExt_None);
			xb_mov_r_imm(a, RCX, cast(u64)n);
			xb_call_sym(a, x64_lower_helper(L, false));
		}
		break;
	}
	case xbOp_MemZero: {
		i64 n = in.imm;
		if (n <= 64) {
			xbOpnd m = x64_mem_base(L, in.mem, R11);
			xb_alu_r_rm(a, ALU_XOR, 4, RAX, xb_r(RAX));
			i64 off = 0;
			while (off < n) {
				i64 rem = n - off;
				i32 c = rem >= 8 ? 8 : rem >= 4 ? 4 : rem >= 2 ? 2 : 1;
				xbOpnd mm = m;
				mm.disp += cast(i32)off;
				xb_mov_rm_r(a, c, mm, RAX);
				off += c;
			}
		} else {
			xb_lea(a, RDX, xb_mem_opnd(L, in.mem, R11));
			xb_alu_r_rm(a, ALU_XOR, 4, RAX, xb_r(RAX));
			xb_mov_r_imm(a, RCX, cast(u64)n);
			xb_call_sym(a, x64_lower_helper(L, true));
		}
		break;
	}
	case xbOp_MemCopyDyn:
	case xbOp_MemMoveDyn:
		x64_get(L, RCX, in.c, 8, xbExt_None);
		x64_get(L, RDX, in.b, 8, xbExt_None);
		x64_get(L, RAX, in.a, 8, xbExt_None);
		xb_call_sym(a, x64_lower_helper(L, false));
		break;
	case xbOp_MemSetDyn:
		x64_get(L, RCX, in.c, 8, xbExt_None);
		x64_get(L, RDX, in.a, 8, xbExt_None);
		x64_get(L, RAX, in.b, 1, xbExt_None);
		xb_call_sym(a, x64_lower_helper(L, true));
		break;
	case xbOp_Call:
		xb_lower_call(L, p->calls[cast(isize)in.imm], false);
		break;
	case xbOp_Jump:
		x64_jump(L, cast(i32)in.imm);
		break;
	case xbOp_Branch: {
		i32 t = cast(i32)in.imm;
		i32 f = cast(i32)in.c;
		if (in.a == L->flags_vreg) {
			L->flags_vreg = 0;
			x64_branch(L, L->flags_cc, t, f);
		} else if (x64_is_const(L, in.a, &k)) {
			i32 to = (k & 0xff) ? t : f;
			if (to != L->next_block) x64_jump(L, to);
		} else {
			x64_test_bool(L, in.a);
			x64_branch(L, CC_NE, t, f);
		}
		break;
	}
	case xbOp_Ret:
		xb_lower_call(L, p->calls[cast(isize)in.imm], true);
		x64_epilogue(L);
		break;
	case xbOp_Unreachable:
	case xbOp_Trap:
		xb_ud2(a);
		break;
	case xbOp_DebugTrap:
		xb_int3(a);
		break;
	case xbOp_AtomicFence:
		xb_mfence(a);
		break;
	case xbOp_CpuRelax:
		xb_pause(a);
		break;
	case xbOp_ReadCycleCounter:
		xb_rdtsc(a);
		xb_shift_imm(a, 4, 8, xb_r(RDX), 32);
		xb_alu_r_rm(a, ALU_OR, 8, RAX, xb_r(RDX));
		x64_put(L, in.dst, RAX);
		break;
	case xbOp_StackPointer:
		x64_put(L, in.dst, RSP);
		break;
	case xbOp_FrameAddress:
		x64_put(L, in.dst, RBP);
		break;
	case xbOp_ReturnAddress: {
		u8 d = x64_dst(L, in.dst, RAX);
		if (in.imm) {
			xb_lea(a, d, xb_m(RBP, L->incoming_base - 8));
		} else {
			xb_mov_r_rm(a, 8, d, xb_m(RBP, L->incoming_base - 8));
		}
		x64_put(L, in.dst, d);
		break;
	}
	case xbOp_AtomicRmw: {
		xbRmwOp op = cast(xbRmwOp)in.aux;
		x64_get(L, RCX, in.a, size, xbExt_None);
		xbOpnd m = x64_mem_base(L, in.mem, R11);
		switch (op) {
		case xbRmw_Xchg:
			xb_enc(a, xb_size_flags(size), size == 1 ? 0x86 : 0x87, RCX, m);
			xb_mov_r_rm(a, 8, RAX, xb_r(RCX));
			break;
		case xbRmw_Add:
		case xbRmw_Sub:
			if (op == xbRmw_Sub) xb_grp3(a, 3, size, xb_r(RCX));
			xb_enc(a, xb_size_flags(size)|XB_LOCK|XB_0F, size == 1 ? 0xC0 : 0xC1, RCX, m);
			xb_mov_r_rm(a, 8, RAX, xb_r(RCX));
			break;
		default: {
			// cmpxchg loop
			xb_mov_r_rm(a, size, RAX, m);
			i64 loop = xb_pos(a);
			xb_mov_r_rm(a, 8, RDX, xb_r(RAX));
			switch (op) {
			case xbRmw_And:  xb_alu_r_rm(a, ALU_AND, 8, RDX, xb_r(RCX)); break;
			case xbRmw_Or:   xb_alu_r_rm(a, ALU_OR,  8, RDX, xb_r(RCX)); break;
			case xbRmw_Xor:  xb_alu_r_rm(a, ALU_XOR, 8, RDX, xb_r(RCX)); break;
			case xbRmw_Nand: xb_alu_r_rm(a, ALU_AND, 8, RDX, xb_r(RCX)); xb_grp3(a, 2, 8, xb_r(RDX)); break;
			}
			xb_enc(a, xb_size_flags(size)|XB_LOCK|XB_0F, size == 1 ? 0xB0 : 0xB1, RDX, m);
			i64 j = xb_jcc32(a, CC_NE);
			xb_patch_rel32(a, j, loop);
			break;
		}
		}
		x64_put(L, in.dst, RAX);
		break;
	}
	case xbOp_AtomicCas: {
		x64_get(L, RAX, in.a, size, xbExt_None);
		x64_get(L, RCX, in.b, size, xbExt_None);
		xbOpnd m = xb_mem_opnd(L, in.mem, R11);
		xb_enc(a, xb_size_flags(size)|XB_LOCK|XB_0F, size == 1 ? 0xB0 : 0xB1, RCX, m);
		xb_setcc(a, CC_E, RDX);
		xb_load_ext(a, 1, false, RDX, xb_r(RDX));
		x64_put(L, in.dst, RAX);
		x64_put(L, in.c, RDX);
		break;
	}
	case xbOp_Cpuid:
	case xbOp_Xgetbv: {
		bool cpuid = in.op == xbOp_Cpuid;
		// the address before cpuid writes rbx, which may hold its base
		xb_lea(a, R11, xb_mem_opnd(L, in.mem, R11));
		x64_get(L, cpuid ? RAX : RCX, in.a, 4, xbExt_None);
		if (cpuid) {
			x64_get(L, RCX, in.b, 4, xbExt_None);
			xb_mov_r_rm(a, 8, R10, xb_r(RBX)); // rbx is callee saved
			xb_b(a, 0x0F); xb_b(a, 0xA2);
		} else {
			xb_b(a, 0x0F); xb_b(a, 0x01); xb_b(a, 0xD0);
		}
		u8 const regs[4] = {RAX, cast(u8)(cpuid ? RBX : RDX), RCX, RDX};
		for (i32 i = 0; i < (cpuid ? 4 : 2); i++) {
			xb_mov_rm_r(a, 4, xb_m(R11, 4*i), regs[i]);
		}
		if (cpuid) {
			xb_mov_r_rm(a, 8, RBX, xb_r(R10));
		}
		break;
	}
	case xbOp_Vec128: {
		xbVecIntrinsic const &e = xb_vec_intrinsics[in.aux];
		u8 const xmm1 = X64_F1, xmm2 = X64_F2;
		x64_get(L, RAX, in.a, 8, xbExt_None);
		xb_movups_x_m(a, xmm1, xb_m(RAX, 0));
		if (e.form == xbVecForm_ShiftImm) {
			xb_enc(a, e.flags, e.opcode, e.ext, xb_r(xmm1), 1);
		} else if (e.form == xbVecForm_ToGpr) {
			xb_enc(a, e.flags, e.opcode, RAX, xb_r(xmm1));
			xb_mov_rm_r(a, (e.flags & XB_W) ? 8 : 4, xb_mem_opnd(L, in.mem, R11), RAX);
			break;
		} else if (e.form == xbVecForm_Flags) {
			x64_get(L, RAX, in.b, 8, xbExt_None);
			xb_movups_x_m(a, xmm2, xb_m(RAX, 0));
			bool swap = (e.ext & xbVecCond_Swap) != 0;
			xb_enc(a, e.flags, e.opcode, swap ? xmm2 : xmm1, xb_r(swap ? xmm1 : xmm2));
			xb_setcc(a, cast(xbCC)(e.ext & 0xF), RAX);
			if (e.ext & (xbVecCond_AndNP|xbVecCond_OrP)) {
				xb_setcc(a, (e.ext & xbVecCond_AndNP) ? CC_NP : CC_P, RCX);
				xb_alu_r_rm(a, (e.ext & xbVecCond_AndNP) ? ALU_AND : ALU_OR, 1, RAX, xb_r(RCX));
			}
			xb_load_ext(a, 1, false, RAX, xb_r(RAX));
			xb_mov_rm_r(a, 4, xb_mem_opnd(L, in.mem, R11), RAX);
			break;
		} else {
			x64_get(L, RAX, in.b, 8, xbExt_None);
			xb_movups_x_m(a, xmm2, xb_m(RAX, 0));
			if (e.form == xbVecForm_Xmm0) {
				x64_get(L, RAX, in.c, 8, xbExt_None);
				xb_movups_x_m(a, 0, xb_m(RAX, 0));
			}
			xb_enc(a, e.flags, e.opcode, xmm1, xb_r(xmm2), e.imm ? 1 : 0);
		}
		if (e.imm) xb_b(a, cast(u8)in.imm);
		xb_movups_m_x(a, xb_mem_opnd(L, in.mem, R11), xmm1);
		break;
	}
	case xbOp_Asm:
		xb_lower_asm(L, p->asms[cast(isize)in.imm]);
		break;
	case xbOp_TlsAddr: {
		if (xb_is_darwin()) {
			// mov rdi, [rip + sym@TLVP]; call [rdi], the descriptor's getter returns the address in rax
			xb_enc(a, XB_W, 0x8B, RDI, xb_m_sym(cast(i32)in.imm, 0, xbReloc_TLV));
			xb_call_rm(a, xb_m(RDI, 0));
			x64_put(L, in.dst, RAX);
			break;
		}
		// the exact general dynamic sequence, which the linker may rewrite into a cheaper model
		xb_b(a, 0x66);
		xb_enc(a, XB_W, 0x8D, RDI, xb_m_sym(cast(i32)in.imm, 0, xbReloc_TLSGD));
		xb_b(a, 0x66);
		xb_b(a, 0x66);
		xb_b(a, 0x48);
		xb_call_sym(a, xb_lower_symbol(L->p->m, L->out, str_lit("__tls_get_addr"), 0));
		x64_put(L, in.dst, RAX);
		break;
	}
	case xbOp_Valgrind:
		x64_get(L, RDX, in.a, 8, xbExt_None);
		x64_get(L, RAX, in.b, 8, xbExt_None);
		// the magic preamble rotates rdi by 128 bits in total, then xchg rbx, rbx
		xb_shift_imm(a, 0, 8, xb_r(RDI), 3);
		xb_shift_imm(a, 0, 8, xb_r(RDI), 13);
		xb_shift_imm(a, 0, 8, xb_r(RDI), 61);
		xb_shift_imm(a, 0, 8, xb_r(RDI), 51);
		xb_enc(a, XB_W, 0x87, RBX, xb_r(RBX));
		x64_put(L, in.dst, RDX);
		break;
	case xbOp_Alloca: {
		// the block goes above the outgoing argument area, which moves down with rsp
		i32 args_area = cast(i32)xb_lt_align_formula(L->max_call_stack, 16);
		xbOpnd n = x64_opnd(L, in.a, RAX, 8);
		xb_lea(a, RCX, xb_m(RSP, args_area));
		xb_alu_r_rm(a, ALU_SUB, 8, RCX, n);
		xb_alu_rm_imm(a, ALU_AND, 8, xb_r(RCX), -cast(i32)in.imm);
		xb_lea(a, RSP, xb_m(RCX, -args_area));
		x64_put(L, in.dst, RCX);
		break;
	}
	case xbOp_MulHiU:
		x64_get(L, RAX, in.a, 8, xbExt_None);
		xb_grp3(a, 4, 8, x64_opnd(L, in.b, RCX, 8)); // mul: rdx:rax
		x64_put(L, in.dst, RDX);
		break;
	case xbOp_MulOvf: {
		bool sgn = in.aux != 0;
		GB_ASSERT(size >= 4);
		x64_get(L, RAX, in.a, size, xbExt_None);
		xbOpnd rb = x64_opnd(L, in.b, RCX, size);
		if (sgn) {
			xb_imul_r_rm(a, size, RAX, rb);
			xb_setcc(a, CC_O, RCX);
		} else {
			xb_grp3(a, 4, size, rb); // mul: rdx:rax
			xb_setcc(a, CC_B, RCX);
		}
		xb_load_ext(a, 1, false, RCX, xb_r(RCX));
		x64_put(L, in.dst, RAX);
		x64_put(L, in.c, RCX);
		break;
	}
	case xbOp_Syscall: {
		xbCall const &c = p->calls[cast(isize)in.imm];
		xb_lower_call(L, c, true);
		xb_syscall(a);
		x64_put(L, c.result_vreg, RAX);
		break;
	}
	case xbOp_Bswap: {
		u8 d = x64_dst(L, in.dst, RAX);
		x64_get(L, d, in.a, size, xbExt_None);
		if (size == 2) {
			xb_shift_imm(a, 0, 2, xb_r(d), 8); // rol ax, 8
		} else if (size > 2) {
			xb_bswap(a, size, d);
		}
		x64_put(L, in.dst, d);
		break;
	}
	case xbOp_Popcount:
		// SWAR popcount, no POPCNT needed
		x64_get(L, RAX, in.a, size, xbExt_Zero);
		xb_mov_r_rm(a, 8, RCX, xb_r(RAX));
		xb_shift_imm(a, 5, 8, xb_r(RCX), 1);
		xb_mov_r_imm(a, RDX, 0x5555555555555555ull);
		xb_alu_r_rm(a, ALU_AND, 8, RCX, xb_r(RDX));
		xb_alu_r_rm(a, ALU_SUB, 8, RAX, xb_r(RCX));
		xb_mov_r_imm(a, RDX, 0x3333333333333333ull);
		xb_mov_r_rm(a, 8, RCX, xb_r(RAX));
		xb_alu_r_rm(a, ALU_AND, 8, RCX, xb_r(RDX));
		xb_shift_imm(a, 5, 8, xb_r(RAX), 2);
		xb_alu_r_rm(a, ALU_AND, 8, RAX, xb_r(RDX));
		xb_alu_r_rm(a, ALU_ADD, 8, RAX, xb_r(RCX));
		xb_mov_r_rm(a, 8, RCX, xb_r(RAX));
		xb_shift_imm(a, 5, 8, xb_r(RCX), 4);
		xb_alu_r_rm(a, ALU_ADD, 8, RAX, xb_r(RCX));
		xb_mov_r_imm(a, RDX, 0x0F0F0F0F0F0F0F0Full);
		xb_alu_r_rm(a, ALU_AND, 8, RAX, xb_r(RDX));
		xb_mov_r_imm(a, RDX, 0x0101010101010101ull);
		xb_imul_r_rm(a, 8, RAX, xb_r(RDX));
		xb_shift_imm(a, 5, 8, xb_r(RAX), 56);
		x64_put(L, in.dst, RAX);
		break;
	case xbOp_Ctz:
	case xbOp_Clz: {
		// bsf/bsr leave the destination undefined for zero, so handle zero first
		x64_get(L, RCX, in.a, size, xbExt_Zero);
		xb_mov_r_imm(a, RAX, cast(u64)(8*size));
		xb_test_rm_r(a, 8, xb_r(RCX), RCX);
		i64 j_zero = xb_jcc32(a, CC_E);
		if (in.op == xbOp_Ctz) {
			xb_enc(a, XB_W|XB_0F, 0xBC, RAX, xb_r(RCX)); // bsf
		} else {
			xb_enc(a, XB_W|XB_0F, 0xBD, RAX, xb_r(RCX)); // bsr
			// clz = (size*8-1) - bsr
			xb_mov_r_imm(a, RDX, cast(u64)(8*size-1));
			xb_alu_r_rm(a, ALU_SUB, 8, RDX, xb_r(RAX));
			xb_mov_r_rm(a, 8, RAX, xb_r(RDX));
		}
		xb_patch_rel32(a, j_zero, xb_pos(a));
		x64_put(L, in.dst, RAX);
		break;
	}
	default:
		GB_PANIC("xb: cannot lower op %d", in.op);
	}
}

////////////////////////////////////////////////////////////////
// Procedures
////////////////////////////////////////////////////////////////

// Whether `in` is a compare whose result only feeds the next instruction `n` through the flags.
gb_internal bool x64_can_fuse(xbLower *L, xbInstr const &in, xbInstr const &n) {
	if (in.op == xbOp_FCmp) {
		// equality needs the parity flag too
		xbCond c = cast(xbCond)in.aux;
		if (c == xbCond_FEQ || c == xbCond_FNE) return false;
	} else if (in.op != xbOp_ICmp) {
		return false;
	}
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
		       x64_is_const(L, n.b, &k) && x64_ext_value(k, xb_type_size(n.type), xbExt_Zero) == 0;
	}
	}
	return false;
}

gb_internal void x64_lower_proc(xbProc *p, xbLowerOut *out) {
	xbModule *m = p->m;
	xbLower L = {};
	L.p = p;
	L.out = out;
	L.a.m = m;
	L.a.code = &out->text;
	L.a.relocs = &out->relocs;
	L.fixups = array_make<xbLower::Fixup>(heap_allocator(), 0, 64);
	defer (array_free(&L.fixups));
	defer (array_free(&L.slot));
	defer (array_free(&L.uses));
	defer (array_free(&L.reg));
	defer (array_free(&L.is_const));
	defer (array_free(&L.cval));
	defer (array_free(&L.in_block));
	defer (array_free(&L.local_reg));
	defer (array_free(&L.remat));
	defer (array_free(&L.rmem));

	xb_lower_layout(&L);

	xbAsm *a = &L.a;
	// 16 byte aligned procedure starts, more when an asm template aligns its code
	out->align = 16;
	for (xbAsmBlock const &blk : p->asms) out->align = gb_max(out->align, cast(i64)blk.align);
	L.proc_start = xb_pos(a);

	xbProcDebug dbg = {};
	dbg.name = p->entity ? p->entity->token.string : p->name;
	dbg.link_name = p->name;
	dbg.sym = p->sym;
	dbg.start = L.proc_start;
	dbg.file_id = p->file_id;
	dbg.line = p->entity ? p->entity->token.pos.line : 0;
	dbg.line_entry_start = cast(i32)out->lines.count;
	dbg.type = p->type;
	dbg.naked = p->naked;

	// prologue
	L.incoming_base = 16;
	dbg.saved_regs = array_make<xbProcDebug::SavedReg>(heap_allocator(), 0, L.saved_count);
	dbg.scope_marks = array_make<xbScopeMark>(heap_allocator(), 0, 16);
	if (p->naked) {
		GB_ASSERT(L.saved_count == 0 && p->locals.count == 0 && p->params_in.count == 0);
	} else if (xb_is_win64()) {
		xb_win64_prologue(&L, &dbg);
	} else {
		xb_push(a, RBP);
		xb_mov_rm_r(a, 8, xb_r(RBP), RSP);
		if (L.frame_size > 0) {
			xb_enc(a, XB_W, 0x81, 5, xb_r(RSP), 4); // sub rsp, imm32
			xb_u32(a, cast(u32)L.frame_size);
		}
		for (i32 i = 0; i < L.saved_count; i++) {
			u8 r = L.saved[i];
			xb_mov_rm_r(a, 8, xb_m(RBP, L.save_offset[i]), r);
			xbProcDebug::SavedReg s = {x64_dwarf_reg(r), L.save_offset[i]};
			array_add(&dbg.saved_regs, s);
		}
	}
	dbg.saved_at = cast(i32)(xb_pos(a) - L.proc_start);
	for (xbLocal const &l : p->locals) {
		if (l.over_align <= 16) continue;
		// lea r11, [rbp + raw + align-1]; and r11, -align; mov [rbp + slot], r11
		xb_lea(a, R11, xb_m(RBP, l.raw_offset + cast(i32)l.over_align - 1));
		xb_alu_rm_imm(a, ALU_AND, 8, xb_r(R11), -cast(i32)l.over_align);
		xb_mov_rm_r(a, 8, xb_m(RBP, l.frame_offset), R11);
	}
	for (xbParamIn const &in : p->params_in) {
		if (in.dst.kind == xbMem_Local && L.local_reg[in.dst.base] >= 0) continue;
		xbOpnd dst = xb_mem_opnd(&L, in.dst, R11);
		switch (in.loc) {
		case xbLoc_Gpr:
			xb_store_bytes_gpr(&L, dst, in.reg, in.size);
			break;
		case xbLoc_Xmm:
			xb_store_xmm(&L, dst, in.reg, in.size);
			break;
		case xbLoc_Stack:
			if (in.type == xbType_V128) {
				xb_movups_x_m(a, 15, xb_m(RBP, L.incoming_base + in.stack_offset));
				xb_movups_m_x(a, dst, 15);
			} else {
				xb_mov_r_rm(a, 8, RAX, xb_m(RBP, L.incoming_base + in.stack_offset));
				xb_store_bytes_gpr(&L, dst, RAX, in.size);
			}
			break;
		}
	}
	// the promoted ones stay in the register they arrive in or move to a callee saved one
	for (xbParamIn const &in : p->params_in) {
		if (in.dst.kind != xbMem_Local || L.local_reg[in.dst.base] < 0) continue;
		i8 lr = L.local_reg[in.dst.base];
		xbOpnd src = xb_m(RBP, L.incoming_base + in.stack_offset);
		if (lr >= XB_FREG) {
			u8 x = cast(u8)(lr - XB_FREG);
			if (in.loc == xbLoc_Xmm) {
				x64_movaps(a, x, in.reg);
			} else {
				GB_ASSERT(in.loc == xbLoc_Stack);
				xb_movs_x_rm(a, in.size, x, src);
			}
		} else if (in.loc == xbLoc_Gpr) {
			x64_extend(a, xbExt_Zero, in.size, cast(u8)lr, in.reg);
		} else {
			GB_ASSERT(in.loc == xbLoc_Stack);
			xb_load_ext(a, in.size, false, cast(u8)lr, src);
		}
	}
	// like LLVM's prologue_end, on the declaration's line: a breakpoint on the procedure stops here, its parameters in place
	if (build_context.ODIN_DEBUG && dbg.line > 0 && !p->naked) {
		dbg.prologue_end = cast(i32)(xb_pos(a) - L.proc_start);
		xb_b(a, 0x90);
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

	for (isize bi = 0; bi < order.count; bi++) {
		xbBlock *b = order[bi];
		i32 next_block = bi+1 < order.count ? order[bi+1]->index : -1;
		b->code_offset = cast(i32)xb_pos(a);
		xbScopeMark mark = {cast(i32)(xb_pos(a) - L.proc_start), b->debug_scope, b->cold};
		array_add(&dbg.scope_marks, mark);
		for (isize i = 0; i < b->instrs.count; i++) {
			xbInstr const &in = b->instrs[i];
			if (in.op == xbOp_Scope) {
				xbScopeMark mark = {cast(i32)(xb_pos(a) - L.proc_start), cast(i32)in.imm, b->cold};
				array_add(&dbg.scope_marks, mark);
				continue;
			}
			// a jump to the next block is a fallthrough, but like LLVM's a block with no other code keeps it for
			// its line, except the first, which LLVM fills with the parameters' stores
			if (in.op == xbOp_Jump && i+1 == b->instrs.count && cast(i32)in.imm == next_block &&
			    !(build_context.ODIN_DEBUG && bi > 0 && xb_pos(a) == b->code_offset)) {
				continue;
			}
			if (skipped(in)) continue;
			if (in.op == xbOp_Loc || in.op == xbOp_Nop) {
				xb_lower_instr(&L, in);
				continue;
			}
			L.next_block = i+1 == b->instrs.count ? next_block : -1;
			L.fuse = false;
			if (in.op == xbOp_ICmp || in.op == xbOp_FCmp) {
				isize j = next_code(b, i);
				L.fuse = j >= 0 && x64_can_fuse(&L, in, b->instrs[j]);
			}
			u32 flags = L.flags_vreg;
			// only the instruction right after a store sees it
			L.stored.valid = L.stored.fresh;
			L.stored.fresh = false;
			xb_lower_instr(&L, in);
			GB_ASSERT_MSG(flags == 0 || L.flags_vreg != flags, "xb: op %d did not read the flags", in.op);
		}
		L.stored = {};
		GB_ASSERT(L.flags_vreg == 0);
	}
	for (auto const &f : L.fixups) {
		xbBlock *target = p->blocks[f.block];
		GB_ASSERT_MSG(target->placed, "jump to an unplaced block in %.*s", LIT(p->name));
		xb_patch_rel32(a, f.at, target->code_offset);
	}

	dbg.end = xb_pos(a);
	dbg.line_entry_count = cast(i32)(out->lines.count - dbg.line_entry_start);

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
				i8 lr = L.local_reg[v.local];
				v.dwarf_reg = lr >= XB_FREG ? cast(u8)(17 + lr - XB_FREG) : x64_dwarf_reg(cast(u8)lr); // xmm0 is 17
			}
		}
		array_add(&dbg.vars, v);
	}
	out->dbg = dbg;
}
