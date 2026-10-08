// Lowering: xb IR -> x86-64 machine code.
//
// Every vreg lives in an 8-byte stack slot. Short-lived vregs (used only in the
// block that defines them) share slots. Instructions load their operands into
// scratch registers, compute, and store the result back.
//
// Frame:
//   [rbp+16 ...]  incoming stack arguments
//   [rbp+8]       return address
//   [rbp]         saved rbp
//   [rbp-N ...]   locals and vreg slots
//   [rsp ...]     outgoing stack arguments

struct xbLower {
	xbProc *    p;
	xbAsm       a;
	Array<i32>  slot;        // vreg -> rbp offset (negative)
	i32         frame_size;
	i32         max_call_stack;
	struct Fixup { i64 at; i32 block; };
	Array<Fixup> fixups;
	i64         proc_start;
};

template <typename F>
gb_internal void xb_for_each_vreg(xbProc *p, xbInstr const &in, F const &f) {
	// f(vreg, is_def)
	auto use_mem = [&](xbMem const &m) {
		if (m.kind == xbMem_Reg) f(m.base, false);
	};
	switch (in.op) {
	case xbOp_Nop:
	case xbOp_Loc:
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
	case xbOp_MulOvf:
		f(in.a, false);
		f(in.b, false);
		f(in.dst, true);
		f(in.c, true);
		break;
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
		if (in.op == xbOp_ICmp || in.op == xbOp_FCmp) f(in.b, false);
		f(in.dst, true);
		break;
	}
}

gb_internal void xb_lower_layout(xbLower *L) {
	xbProc *p = L->p;
	i32 cur = 0;
	for (xbLocal &l : p->locals) {
		cur = cast(i32)xb_lt_align_formula(cur + l.size, l.align);
		l.frame_offset = -cur;
	}

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

	i32 linear = 0;
	L->max_call_stack = 0;
	for (xbBlock *b : p->order) {
		for (xbInstr const &in : b->instrs) {
			xb_for_each_vreg(p, in, [&](u32 v, bool is_def) {
				if (v == 0) return;
				if (is_def) {
					def_block[v] = b->index;
				} else {
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
						cur = cast(i32)xb_lt_align_formula(cur, 8);
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

	i32 total = cast(i32)xb_lt_align_formula(cur, 16) + cast(i32)xb_lt_align_formula(L->max_call_stack, 16);
	L->frame_size = total;
}

gb_internal xbOpnd xb_slot(xbLower *L, u32 v) {
	GB_ASSERT(v != 0);
	return xb_m(RBP, L->slot[v]);
}

// A machine memory operand for an IR memory reference. May clobber `scratch`.
gb_internal xbOpnd xb_mem_opnd(xbLower *L, xbMem const &m, u8 scratch=R11) {
	xbAsm *a = &L->a;
	switch (m.kind) {
	case xbMem_Local:
		return xb_m(RBP, L->p->locals[m.base].frame_offset + m.offset);
	case xbMem_Incoming:
		return xb_m(RBP, 16 + m.offset);
	case xbMem_Reg:
		xb_mov_r_rm(a, 8, scratch, xb_slot(L, m.base));
		return xb_m(scratch, m.offset);
	case xbMem_Sym: {
		xbSymbol *s = &L->p->m->symbols[m.base];
		if (s->flags & xbSymbolFlag_TLS) {
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
			return xb_m(scratch, m.offset);
		}
		if ((s->flags & xbSymbolFlag_Foreign) && s->section == xbSection_Undef) {
			// mov scratch, [rip + sym@GOTPCREL]
			xb_enc(a, XB_W, 0x8B, scratch, xb_m_sym(cast(i32)m.base, 0, xbReloc_REX_GOTPCRELX));
			return xb_m(scratch, m.offset);
		}
		return xb_m_sym(cast(i32)m.base, m.offset);
	}
	}
	GB_PANIC("bad mem");
	return {};
}

gb_internal void xb_load_gpr(xbLower *L, u8 reg, u32 v, i32 size, xbExtKind ext) {
	xbOpnd s = xb_slot(L, v);
	if (size >= 4) {
		xb_mov_r_rm(&L->a, size, reg, s);
	} else {
		xb_load_ext(&L->a, size, ext == xbExt_Sign, reg, s);
	}
}

gb_internal void xb_store_gpr(xbLower *L, u32 v, u8 reg, i32 size) {
	xb_mov_rm_r(&L->a, size, xb_slot(L, v), reg);
}

gb_internal void xb_load_xmm(xbLower *L, u8 x, xbOpnd m, i32 size) {
	xbAsm *a = &L->a;
	switch (size) {
	case 2:
		xb_load_ext(a, 2, false, R10, m);
		xb_movd_x_rm(a, 4, x, xb_r(R10));
		break;
	case 4: xb_movs_x_rm(a, 4, x, m); break;
	case 8: xb_movs_x_rm(a, 8, x, m); break;
	case 16: xb_movups_x_m(a, x, m); break;
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
	case 8: xb_movs_rm_x(a, 8, m, x); break;
	case 16: xb_movups_m_x(a, m, x); break;
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

// Copies `size` bytes from [rsi] to [rdi], allowing overlap.
gb_internal void xb_emit_copy_rsi_rdi(xbLower *L, i64 size) {
	xbAsm *a = &L->a;
	if (size <= 32) {
		// load everything, then store everything: overlap safe
		u8 regs[7] = {RAX, RCX, RDX, R8, R9, R10, R11};
		struct Chunk { i32 size; i64 off; };
		Chunk chunks[8] = {};
		i32 n = 0;
		i64 off = 0;
		while (off < size) {
			i64 rem = size - off;
			i32 c = rem >= 8 ? 8 : rem >= 4 ? 4 : rem >= 2 ? 2 : 1;
			chunks[n].size = c;
			chunks[n].off = off;
			n++;
			off += c;
		}
		GB_ASSERT(n <= 7);
		for (i32 i = 0; i < n; i++) {
			xb_load_ext(a, chunks[i].size, false, regs[i], xb_m(RSI, cast(i32)chunks[i].off));
		}
		for (i32 i = 0; i < n; i++) {
			xb_mov_rm_r(a, chunks[i].size, xb_m(RDI, cast(i32)chunks[i].off), regs[i]);
		}
		return;
	}
	// memmove with rep movsb, backwards if the destination is above the source
	xb_mov_r_imm(a, RCX, cast(u64)size);
	xb_alu_r_rm(a, ALU_CMP, 8, RDI, xb_r(RSI));
	i64 j_fwd = xb_jcc32(a, CC_BE);
	xb_lea(a, RAX, xb_m(RSI, 0));
	xb_alu_r_rm(a, ALU_ADD, 8, RAX, xb_r(RCX));
	xb_alu_r_rm(a, ALU_CMP, 8, RDI, xb_r(RAX));
	i64 j_fwd2 = xb_jcc32(a, CC_AE);
	// backwards
	xb_lea(a, RSI, xb_m(RSI, cast(i32)size-1));
	xb_lea(a, RDI, xb_m(RDI, cast(i32)size-1));
	xb_std(a);
	xb_rep_movsb(a);
	xb_cld(a);
	i64 j_done = xb_jmp32(a);
	xb_patch_rel32(a, j_fwd, xb_pos(a));
	xb_patch_rel32(a, j_fwd2, xb_pos(a));
	xb_rep_movsb(a);
	xb_patch_rel32(a, j_done, xb_pos(a));
}

gb_internal void xb_lower_call(xbLower *L, xbCall const &c, bool is_ret) {
	xbAsm *a = &L->a;
	// stack arguments first, the argument registers are free to use as scratch
	for (xbCallArg const &arg : c.args) {
		switch (arg.kind) {
		case xbCallArg_Stack: {
			xbType t = arg.type;
			if (xb_type_is_float(t)) {
				xb_movs_x_rm(a, xb_type_size(t), 0, xb_slot(L, arg.vreg));
				xb_movs_rm_x(a, xb_type_size(t), xb_m(RSP, arg.stack_offset), 0);
			} else {
				xb_load_gpr(L, RAX, arg.vreg, xb_type_size(t), arg.ext == xbExt_Sign ? xbExt_Sign : xbExt_Zero);
				xb_mov_rm_r(a, 8, xb_m(RSP, arg.stack_offset), RAX);
			}
			break;
		}
		case xbCallArg_StackMem: {
			xbOpnd src = xb_mem_opnd(L, arg.mem, R11);
			if (arg.type == xbType_None || arg.size > 8) {
				// a by-value copy
				xb_lea(a, RSI, src);
				xb_lea(a, RDI, xb_m(RSP, arg.stack_offset));
				xb_emit_copy_rsi_rdi(L, arg.size);
			} else if (arg.type == xbType_V128) {
				xb_movups_x_m(a, 0, src);
				xb_movups_m_x(a, xb_m(RSP, arg.stack_offset), 0);
			} else {
				if (src.reg == XB_RIP) {
					xb_lea(a, R11, src);
					src = xb_m(R11, 0);
				}
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
			xb_load_gpr(L, arg.reg, arg.vreg, size, ext);
			break;
		}
		case xbCallArg_Xmm:
			xb_load_xmm(L, arg.reg, xb_slot(L, arg.vreg), xb_type_size(arg.type));
			break;
		case xbCallArg_GprMem: {
			xbOpnd src = xb_mem_opnd(L, arg.mem, R11);
			if (src.reg == XB_RIP && (arg.size != 1 && arg.size != 2 && arg.size != 4 && arg.size != 8)) {
				xb_lea(a, R11, src);
				src = xb_m(R11, 0);
			}
			xbExtKind ext = arg.ext;
			if (arg.size < 4 && ext == xbExt_None) ext = xbExt_Zero;
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
		xb_mov_r_rm(a, 8, R11, xb_slot(L, c.target_vreg));
		xb_call_rm(a, xb_r(R11));
	}
	for (xbCallRet const &r : c.rets) {
		if (r.loc == xbLoc_Gpr) {
			xbOpnd dst = xb_mem_opnd(L, r.dst, R11);
			if (dst.reg == XB_RIP) {
				xb_lea(a, R11, dst);
				dst = xb_m(R11, 0);
			}
			xb_mov_r_rm(a, 8, R10, xb_r(r.reg));
			xb_store_bytes_gpr(L, dst, R10, r.size);
		} else {
			xbOpnd dst = xb_mem_opnd(L, r.dst, R11);
			xb_store_xmm(L, dst, r.reg, r.size);
		}
	}
}

gb_internal void xb_lower_instr(xbLower *L, xbInstr const &in) {
	xbAsm *a = &L->a;
	xbProc *p = L->p;
	i32 size = xb_type_size(in.type);
	switch (in.op) {
	case xbOp_Nop:
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
		i64 v = in.imm;
		if (v >= -0x80000000ll && v <= 0x7fffffffll) {
			// mov qword [slot], simm32
			xb_enc(a, XB_W, 0xC7, 0, xb_slot(L, in.dst), 4);
			xb_u32(a, cast(u32)cast(i32)v);
		} else {
			xb_mov_r_imm(a, RAX, cast(u64)v);
			xb_store_gpr(L, in.dst, RAX, 8);
		}
		break;
	}
	case xbOp_Lea: {
		xbOpnd m = xb_mem_opnd(L, in.mem, R11);
		xb_lea(a, RAX, m);
		xb_store_gpr(L, in.dst, RAX, 8);
		break;
	}
	case xbOp_Load:
	case xbOp_AtomicLoad: {
		xbOpnd m = xb_mem_opnd(L, in.mem, R11);
		if (xb_type_is_float(in.type)) {
			xb_movs_x_rm(a, size, 0, m);
			xb_movs_rm_x(a, size, xb_slot(L, in.dst), 0);
		} else {
			xb_load_ext(a, size, false, RAX, m);
			xb_store_gpr(L, in.dst, RAX, 8);
		}
		break;
	}
	case xbOp_Store: {
		if (xb_type_is_float(in.type)) {
			xb_movs_x_rm(a, size, 0, xb_slot(L, in.a));
			xbOpnd m = xb_mem_opnd(L, in.mem, R11);
			xb_movs_rm_x(a, size, m, 0);
		} else {
			xb_mov_r_rm(a, size, RAX, xb_slot(L, in.a));
			xbOpnd m = xb_mem_opnd(L, in.mem, R11);
			xb_mov_rm_r(a, size, m, RAX);
		}
		break;
	}
	case xbOp_AtomicStore: {
		xb_mov_r_rm(a, size, RAX, xb_slot(L, in.a));
		xbOpnd m = xb_mem_opnd(L, in.mem, R11);
		// xchg is a full barrier
		xb_enc(a, xb_size_flags(size), size == 1 ? 0x86 : 0x87, RAX, m);
		break;
	}
	case xbOp_Copy:
		xb_mov_r_rm(a, 8, RAX, xb_slot(L, in.a));
		xb_store_gpr(L, in.dst, RAX, 8);
		break;

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
		xb_mov_r_rm(a, size, RAX, xb_slot(L, in.a));
		xb_alu_r_rm(a, op, size, RAX, xb_slot(L, in.b));
		xb_store_gpr(L, in.dst, RAX, size);
		break;
	}
	case xbOp_Mul: {
		i32 s = gb_max(size, 4);
		xb_load_gpr(L, RAX, in.a, size, xbExt_Zero);
		xb_load_gpr(L, RCX, in.b, size, xbExt_Zero);
		xb_imul_r_rm(a, s, RAX, xb_r(RCX));
		xb_store_gpr(L, in.dst, RAX, size);
		break;
	}
	case xbOp_SDiv:
	case xbOp_SRem:
	case xbOp_UDiv:
	case xbOp_URem: {
		bool sgn = in.op == xbOp_SDiv || in.op == xbOp_SRem;
		i32 s = gb_max(size, 4);
		xb_load_gpr(L, RAX, in.a, size, sgn ? xbExt_Sign : xbExt_Zero);
		xb_load_gpr(L, RCX, in.b, size, sgn ? xbExt_Sign : xbExt_Zero);
		if (sgn) {
			xb_sign_extend_rdx(a, s);
			xb_grp3(a, 7, s, xb_r(RCX));
		} else {
			xb_alu_r_rm(a, ALU_XOR, 4, RDX, xb_r(RDX));
			xb_grp3(a, 6, s, xb_r(RCX));
		}
		bool rem = in.op == xbOp_SRem || in.op == xbOp_URem;
		xb_store_gpr(L, in.dst, rem ? RDX : RAX, size);
		break;
	}
	case xbOp_Shl:
	case xbOp_LShr:
	case xbOp_AShr: {
		i32 s = gb_max(size, 4);
		xb_load_gpr(L, RAX, in.a, size, in.op == xbOp_AShr ? xbExt_Sign : xbExt_Zero);
		xb_mov_r_rm(a, 4, RCX, xb_slot(L, in.b));
		u8 n = in.op == xbOp_Shl ? 4 : (in.op == xbOp_LShr ? 5 : 7);
		xb_shift_cl(a, n, s, xb_r(RAX));
		xb_store_gpr(L, in.dst, RAX, size);
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
		xb_movs_x_rm(a, size, 0, xb_slot(L, in.a));
		xb_sse_scalar(a, op, size, 0, xb_slot(L, in.b));
		xb_movs_rm_x(a, size, xb_slot(L, in.dst), 0);
		break;
	}
	case xbOp_Sqrt:
		xb_sse_scalar(a, SSE_SQRT, size, 0, xb_slot(L, in.a));
		xb_movs_rm_x(a, size, xb_slot(L, in.dst), 0);
		break;
	case xbOp_Neg:
	case xbOp_Not:
		xb_mov_r_rm(a, size, RAX, xb_slot(L, in.a));
		xb_grp3(a, in.op == xbOp_Neg ? 3 : 2, size, xb_r(RAX));
		xb_store_gpr(L, in.dst, RAX, size);
		break;
	case xbOp_FNeg:
		if (size == 4) {
			xb_mov_r_rm(a, 4, RAX, xb_slot(L, in.a));
			xb_alu_rm_imm(a, ALU_XOR, 4, xb_r(RAX), cast(i32)0x80000000u);
			xb_store_gpr(L, in.dst, RAX, 4);
		} else {
			xb_mov_r_rm(a, 8, RAX, xb_slot(L, in.a));
			xb_mov_r_imm(a, RCX, 0x8000000000000000ull);
			xb_alu_r_rm(a, ALU_XOR, 8, RAX, xb_r(RCX));
			xb_store_gpr(L, in.dst, RAX, 8);
		}
		break;
	case xbOp_ICmp: {
		xbCond c = cast(xbCond)in.aux;
		xb_mov_r_rm(a, size, RAX, xb_slot(L, in.a));
		xb_alu_r_rm(a, ALU_CMP, size, RAX, xb_slot(L, in.b));
		xb_setcc(a, xb_cc_for(c), RAX);
		xb_load_ext(a, 1, false, RAX, xb_r(RAX));
		xb_store_gpr(L, in.dst, RAX, 1);
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
		xb_movs_x_rm(a, size, 0, xb_slot(L, x));
		xb_ucomis(a, size, 0, xb_slot(L, y));
		switch (c) {
		case xbCond_FEQ:
			xb_setcc(a, CC_E, RAX);
			xb_setcc(a, CC_NP, RCX);
			xb_alu_r_rm(a, ALU_AND, 1, RAX, xb_r(RCX));
			break;
		case xbCond_FNE:
			xb_setcc(a, CC_NE, RAX);
			xb_setcc(a, CC_P, RCX);
			xb_alu_r_rm(a, ALU_OR, 1, RAX, xb_r(RCX));
			break;
		case xbCond_FGT:
		case xbCond_FLT:
			xb_setcc(a, CC_A, RAX);
			break;
		case xbCond_FGE:
		case xbCond_FLE:
			xb_setcc(a, CC_AE, RAX);
			break;
		default:
			GB_PANIC("bad float cond");
		}
		xb_load_ext(a, 1, false, RAX, xb_r(RAX));
		xb_store_gpr(L, in.dst, RAX, 1);
		break;
	}
	case xbOp_Zext:
	case xbOp_Sext: {
		xbType src = cast(xbType)in.aux;
		xb_load_gpr(L, RAX, in.a, xb_type_size(src), in.op == xbOp_Sext ? xbExt_Sign : xbExt_Zero);
		if (xb_type_size(src) == 4 && in.op == xbOp_Sext) {
			xb_load_ext(a, 4, true, RAX, xb_slot(L, in.a));
		}
		xb_store_gpr(L, in.dst, RAX, 8);
		break;
	}
	case xbOp_Trunc:
	case xbOp_Bitcast:
		xb_mov_r_rm(a, 8, RAX, xb_slot(L, in.a));
		xb_store_gpr(L, in.dst, RAX, 8);
		break;
	case xbOp_SIToF: {
		xbType src = cast(xbType)in.aux;
		i32 ss = xb_type_size(src);
		xb_load_gpr(L, RAX, in.a, ss, xbExt_Sign);
		if (ss == 4) xb_load_ext(a, 4, true, RAX, xb_slot(L, in.a));
		xb_cvtsi2f(a, size, 8, 0, xb_r(RAX));
		xb_movs_rm_x(a, size, xb_slot(L, in.dst), 0);
		break;
	}
	case xbOp_UIToF: {
		xbType src = cast(xbType)in.aux;
		i32 ss = xb_type_size(src);
		xb_load_gpr(L, RAX, in.a, ss, xbExt_Zero);
		if (ss < 8) {
			xb_cvtsi2f(a, size, 8, 0, xb_r(RAX));
		} else {
			xb_test_rm_r(a, 8, xb_r(RAX), RAX);
			i64 j_neg = xb_jcc32(a, CC_S);
			xb_cvtsi2f(a, size, 8, 0, xb_r(RAX));
			i64 j_done = xb_jmp32(a);
			xb_patch_rel32(a, j_neg, xb_pos(a));
			xb_mov_r_rm(a, 8, RCX, xb_r(RAX));
			xb_shift_imm(a, 5, 8, xb_r(RCX), 1);
			xb_alu_rm_imm(a, ALU_AND, 4, xb_r(RAX), 1);
			xb_alu_r_rm(a, ALU_OR, 8, RCX, xb_r(RAX));
			xb_cvtsi2f(a, size, 8, 0, xb_r(RCX));
			xb_sse_scalar(a, SSE_ADD, size, 0, xb_r(0));
			xb_patch_rel32(a, j_done, xb_pos(a));
		}
		xb_movs_rm_x(a, size, xb_slot(L, in.dst), 0);
		break;
	}
	case xbOp_FToSI: {
		xbType src = cast(xbType)in.aux;
		xb_cvttf2si(a, xb_type_size(src), size >= 8 ? 8 : 4, RAX, xb_slot(L, in.a));
		xb_store_gpr(L, in.dst, RAX, 8);
		break;
	}
	case xbOp_FToUI: {
		xbType src = cast(xbType)in.aux;
		i32 fs = xb_type_size(src);
		xb_movs_x_rm(a, fs, 0, xb_slot(L, in.a));
		// 2^63 as a float of the source size
		if (fs == 4) {
			xb_mov_r_imm(a, RAX, 0x5f000000ull);
			xb_movd_x_rm(a, 4, 1, xb_r(RAX));
		} else {
			xb_mov_r_imm(a, RAX, 0x43e0000000000000ull);
			xb_movd_x_rm(a, 8, 1, xb_r(RAX));
		}
		xb_ucomis(a, fs, 0, xb_r(1));
		i64 j_big = xb_jcc32(a, CC_AE);
		xb_cvttf2si(a, fs, 8, RAX, xb_r(0));
		i64 j_done = xb_jmp32(a);
		xb_patch_rel32(a, j_big, xb_pos(a));
		xb_sse_scalar(a, SSE_SUB, fs, 0, xb_r(1));
		xb_cvttf2si(a, fs, 8, RAX, xb_r(0));
		xb_mov_r_imm(a, RCX, 0x8000000000000000ull);
		xb_alu_r_rm(a, ALU_XOR, 8, RAX, xb_r(RCX));
		xb_patch_rel32(a, j_done, xb_pos(a));
		xb_store_gpr(L, in.dst, RAX, 8);
		break;
	}
	case xbOp_FExt:
		xb_sse_scalar(a, SSE_CVT, 4, 0, xb_slot(L, in.a)); // cvtss2sd
		xb_movs_rm_x(a, 8, xb_slot(L, in.dst), 0);
		break;
	case xbOp_FTrunc:
		xb_sse_scalar(a, SSE_CVT, 8, 0, xb_slot(L, in.a)); // cvtsd2ss
		xb_movs_rm_x(a, 4, xb_slot(L, in.dst), 0);
		break;
	case xbOp_Select:
		xb_mov_r_rm(a, 8, RAX, xb_slot(L, in.c));
		xb_alu_rm_imm(a, ALU_CMP, 1, xb_slot(L, in.a), 0);
		xb_cmov(a, CC_NE, 8, RAX, xb_slot(L, in.b));
		xb_store_gpr(L, in.dst, RAX, 8);
		break;
	case xbOp_MemCopy:
	case xbOp_MemMove:
		xb_mov_r_rm(a, 8, RDI, xb_slot(L, in.a));
		xb_mov_r_rm(a, 8, RSI, xb_slot(L, in.b));
		xb_emit_copy_rsi_rdi(L, in.imm);
		break;
	case xbOp_MemZero: {
		xbOpnd m = xb_mem_opnd(L, in.mem, R11);
		i64 n = in.imm;
		if (m.reg == XB_RIP || n > 64) {
			xb_lea(a, RDI, m);
			xb_alu_r_rm(a, ALU_XOR, 4, RAX, xb_r(RAX));
			xb_mov_r_imm(a, RCX, cast(u64)n);
			xb_rep_stosb(a);
		} else {
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
		}
		break;
	}
	case xbOp_MemCopyDyn:
	case xbOp_MemMoveDyn: {
		xb_mov_r_rm(a, 8, RDI, xb_slot(L, in.a));
		xb_mov_r_rm(a, 8, RSI, xb_slot(L, in.b));
		xb_mov_r_rm(a, 8, RCX, xb_slot(L, in.c));
		// backwards when the destination is inside the source range
		xb_alu_r_rm(a, ALU_CMP, 8, RDI, xb_r(RSI));
		i64 j_fwd = xb_jcc32(a, CC_BE);
		xb_lea(a, RAX, xb_m(RSI, 0));
		xb_alu_r_rm(a, ALU_ADD, 8, RAX, xb_r(RCX));
		xb_alu_r_rm(a, ALU_CMP, 8, RDI, xb_r(RAX));
		i64 j_fwd2 = xb_jcc32(a, CC_AE);
		xb_lea(a, RSI, xb_m(RSI, -1));
		xb_alu_r_rm(a, ALU_ADD, 8, RSI, xb_r(RCX));
		xb_lea(a, RDI, xb_m(RDI, -1));
		xb_alu_r_rm(a, ALU_ADD, 8, RDI, xb_r(RCX));
		xb_std(a);
		xb_rep_movsb(a);
		xb_cld(a);
		i64 j_done = xb_jmp32(a);
		xb_patch_rel32(a, j_fwd, xb_pos(a));
		xb_patch_rel32(a, j_fwd2, xb_pos(a));
		xb_rep_movsb(a);
		xb_patch_rel32(a, j_done, xb_pos(a));
		break;
	}
	case xbOp_MemSetDyn:
		xb_mov_r_rm(a, 8, RDI, xb_slot(L, in.a));
		xb_mov_r_rm(a, 1, RAX, xb_slot(L, in.b));
		xb_mov_r_rm(a, 8, RCX, xb_slot(L, in.c));
		xb_rep_stosb(a);
		break;
	case xbOp_Call:
		xb_lower_call(L, p->calls[cast(isize)in.imm], false);
		break;
	case xbOp_Jump: {
		xb_b(a, 0xE9);
		xbLower::Fixup f = {xb_pos(a), cast(i32)in.imm};
		xb_u32(a, 0);
		array_add(&L->fixups, f);
		break;
	}
	case xbOp_Branch: {
		xb_alu_rm_imm(a, ALU_CMP, 1, xb_slot(L, in.a), 0);
		i64 at = xb_jcc32(a, CC_NE);
		xbLower::Fixup f1 = {at, cast(i32)in.imm};
		array_add(&L->fixups, f1);
		xb_b(a, 0xE9);
		xbLower::Fixup f2 = {xb_pos(a), cast(i32)in.c};
		xb_u32(a, 0);
		array_add(&L->fixups, f2);
		break;
	}
	case xbOp_Ret:
		xb_lower_call(L, p->calls[cast(isize)in.imm], true);
		xb_leave(a);
		xb_ret(a);
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
		xb_store_gpr(L, in.dst, RAX, 8);
		break;
	case xbOp_StackPointer:
		xb_mov_r_rm(a, 8, RAX, xb_r(RSP));
		xb_store_gpr(L, in.dst, RAX, 8);
		break;
	case xbOp_FrameAddress:
		xb_mov_r_rm(a, 8, RAX, xb_r(RBP));
		xb_store_gpr(L, in.dst, RAX, 8);
		break;
	case xbOp_ReturnAddress:
		xb_mov_r_rm(a, 8, RAX, xb_m(RBP, 8));
		xb_store_gpr(L, in.dst, RAX, 8);
		break;
	case xbOp_AtomicRmw: {
		xbRmwOp op = cast(xbRmwOp)in.aux;
		xb_mov_r_rm(a, size, RCX, xb_slot(L, in.a));
		xbOpnd m = xb_mem_opnd(L, in.mem, R11);
		if (m.reg == XB_RIP) {
			xb_lea(a, R11, m);
			m = xb_m(R11, 0);
		}
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
		xb_store_gpr(L, in.dst, RAX, 8);
		break;
	}
	case xbOp_AtomicCas: {
		xb_mov_r_rm(a, size, RAX, xb_slot(L, in.a));
		xb_mov_r_rm(a, size, RCX, xb_slot(L, in.b));
		xbOpnd m = xb_mem_opnd(L, in.mem, R11);
		xb_enc(a, xb_size_flags(size)|XB_LOCK|XB_0F, size == 1 ? 0xB0 : 0xB1, RCX, m);
		xb_setcc(a, CC_E, RDX);
		xb_store_gpr(L, in.dst, RAX, 8);
		xb_mov_rm_r(a, 1, xb_slot(L, in.c), RDX);
		break;
	}
	case xbOp_MulHiU:
		xb_mov_r_rm(a, 8, RAX, xb_slot(L, in.a));
		xb_grp3(a, 4, 8, xb_slot(L, in.b)); // mul: rdx:rax
		xb_store_gpr(L, in.dst, RDX, 8);
		break;
	case xbOp_MulOvf: {
		bool sgn = in.aux != 0;
		GB_ASSERT(size >= 4);
		xb_mov_r_rm(a, size, RAX, xb_slot(L, in.a));
		if (sgn) {
			xb_imul_r_rm(a, size, RAX, xb_slot(L, in.b));
			xb_setcc(a, CC_O, RCX);
		} else {
			xb_grp3(a, 4, size, xb_slot(L, in.b)); // mul: rdx:rax
			xb_setcc(a, CC_B, RCX);
		}
		xb_store_gpr(L, in.dst, RAX, size);
		xb_mov_rm_r(a, 1, xb_slot(L, in.c), RCX);
		break;
	}
	case xbOp_Syscall: {
		xbCall const &c = p->calls[cast(isize)in.imm];
		xb_lower_call(L, c, true);
		xb_syscall(a);
		xb_store_gpr(L, c.result_vreg, RAX, 8);
		break;
	}
	case xbOp_Bswap:
		xb_mov_r_rm(a, size, RAX, xb_slot(L, in.a));
		if (size == 2) {
			xb_shift_imm(a, 0, 2, xb_r(RAX), 8); // rol ax, 8
		} else {
			xb_bswap(a, size, RAX);
		}
		xb_store_gpr(L, in.dst, RAX, size);
		break;
	case xbOp_Popcount:
		// SWAR popcount, no POPCNT needed
		xb_load_gpr(L, RAX, in.a, size, xbExt_Zero);
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
		xb_store_gpr(L, in.dst, RAX, 8);
		break;
	case xbOp_Ctz:
	case xbOp_Clz: {
		// bsf/bsr leave the destination undefined for zero, so handle zero first
		xb_load_gpr(L, RCX, in.a, size, xbExt_Zero);
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
		xb_store_gpr(L, in.dst, RAX, 8);
		break;
	}
	default:
		GB_PANIC("xb: cannot lower op %d", in.op);
	}
}

gb_internal void xb_lower_proc(xbProc *p) {
	xbModule *m = p->m;
	xbLower L = {};
	L.p = p;
	L.a.m = m;
	L.a.code = &m->sections[xbSection_Text];
	L.fixups = array_make<xbLower::Fixup>(heap_allocator(), 0, 64);
	defer (array_free(&L.fixups));
	defer (array_free(&L.slot));

	xb_lower_layout(&L);

	xbAsm *a = &L.a;
	// 16 byte aligned procedure starts
	while (a->code->count % 16 != 0) {
		xb_b(a, 0xCC);
	}
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

	// prologue
	xb_push(a, RBP);
	xb_mov_rm_r(a, 8, xb_r(RBP), RSP);
	if (L.frame_size > 0) {
		xb_enc(a, XB_W, 0x81, 5, xb_r(RSP), 4); // sub rsp, imm32
		xb_u32(a, cast(u32)L.frame_size);
	}
	for (xbParamIn const &in : p->params_in) {
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
				xb_movups_x_m(a, 15, xb_m(RBP, 16 + in.stack_offset));
				xb_movups_m_x(a, dst, 15);
			} else {
				xb_mov_r_rm(a, 8, RAX, xb_m(RBP, 16 + in.stack_offset));
				xb_store_bytes_gpr(&L, dst, RAX, in.size);
			}
			break;
		}
	}

	for (xbBlock *b : p->order) {
		b->code_offset = cast(i32)xb_pos(a);
		for (isize i = 0; i < b->instrs.count; i++) {
			xbInstr const &in = b->instrs[i];
			// a jump to the next block is a fallthrough
			if (in.op == xbOp_Jump && i+1 == b->instrs.count) {
				isize bi = 0;
				for (; bi < p->order.count; bi++) if (p->order[bi] == b) break;
				if (bi+1 < p->order.count && p->order[bi+1]->index == cast(i32)in.imm) {
					continue;
				}
			}
			xb_lower_instr(&L, in);
		}
	}
	for (auto const &f : L.fixups) {
		xbBlock *target = p->blocks[f.block];
		GB_ASSERT_MSG(target->placed, "jump to an unplaced block in %.*s", LIT(p->name));
		xb_patch_rel32(a, f.at, target->code_offset);
	}

	dbg.end = xb_pos(a);
	dbg.line_entry_count = cast(i32)(m->lines.count - dbg.line_entry_start);
	sym->size = dbg.end - dbg.start;

	// debug variables, now that frame offsets are known
	dbg.vars = array_make<xbDebugVar>(heap_allocator(), 0, p->debug_vars.count);
	for (xbDebugVar v : p->debug_vars) {
		if (v.local >= 0) {
			v.frame_offset_fixup += p->locals[v.local].frame_offset;
		}
		array_add(&dbg.vars, v);
	}
	array_add(&m->proc_debug, dbg);
}
