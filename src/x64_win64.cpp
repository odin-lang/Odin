// Windows x64: the Win64 calling convention, matching lbAbiAmd64Win64 and LLVM's
// CC_X86_Win64_C, and the Windows prologue and epilogue.
//
// Every argument takes one slot: the first four go in rcx, rdx, r8, r9 or
// xmm0-xmm3 by position, the rest on the stack above a 32 byte shadow area the
// caller always reserves. Aggregates of 1, 2, 4 or 8 bytes travel as integers,
// all others by pointer.
//
// Frame:
//   [rbp+incoming_base ...]  incoming stack arguments (the shadow area first)
//   [...]                    saved rbp, rsi, rdi, promoted registers (pushed), pad
//   [rbp ...]                saved xmm registers
//   [rbp-N ...]              locals and vreg slots
//   [rsp ...]                outgoing arguments, the shadow area first
// rbp is set after the pushes and the xmm save area, so the unwinder finds every
// saved register from it even after an alloca moved rsp.

gb_internal bool xb_is_win64(void) {
	return build_context.metrics.os == TargetOs_windows;
}

gb_global u8 const xb_win64_int_regs[4] = {RCX, RDX, R8, R9};

struct xbWin64Class {
	xbArgKind  kind;
	xbAbiPiece piece;
	bool       copy;
	bool       unsupported;
	i32        parts;     // Indirect vector: pointers passed, one per legal vector part
	i32        part_size;
};

// The widest vector LLVM keeps whole for an element size; wider ones are split into parts.
gb_internal i32 xb_win64_legal_vector_size(i64 elem_size) {
	if (check_target_feature_is_enabled(str_lit("avx512f"), nullptr) &&
	    (elem_size >= 4 || check_target_feature_is_enabled(str_lit("avx512bw"), nullptr))) {
		return 64;
	}
	if (check_target_feature_is_enabled(str_lit("avx"), nullptr)) {
		return 32;
	}
	return 16;
}

gb_internal xbType xb_win64_int_type(i64 size) {
	if (size <= 1) return xbType_I8;
	if (size <= 2) return xbType_I16;
	if (size <= 4) return xbType_I32;
	return xbType_I64;
}

gb_internal xbWin64Class xb_win64_classify(xbLType *lt, bool is_return) {
	xbWin64Class c = {};
	c.kind = xbArg_Direct;
	auto set = [&](xbType t, i32 size, xbLocKind loc) {
		c.piece.type = t;
		c.piece.size = size;
		c.piece.loc = loc;
	};
	switch (lt->kind) {
	case xbLT_Void:
		c.kind = xbArg_Ignore;
		break;
	case xbLT_Struct:
	case xbLT_Array:
		switch (lt->size) {
		case 1: case 2: case 4: case 8:
			set(xb_win64_int_type(lt->size), cast(i32)lt->size, xbLoc_Gpr);
			break;
		default:
			c.kind = xbArg_Indirect;
			break;
		}
		break;
	case xbLT_Vector: {
		// what LLVM's type legalization does with the vector lbAbi386::non_struct leaves alone
		xbLType *elem = lt->elem;
		if (!is_return && lt->size == 8 && elem->kind == xbLT_Int) {
			set(xbType_I64, 8, xbLoc_Gpr);
		} else if (lt->count == 1 && elem->kind != xbLT_Half) {
			// a single element vector is scalarized
			c = xb_win64_classify(elem, is_return);
		} else if (is_return) {
			// widened or split into xmm0-xmm3, the caller decides how many it can take
			if (lt->size > 16) {
				c.kind = xbArg_Indirect;
			} else {
				set(lt->size == 16 ? xbType_V128 : lt->size == 8 ? xbType_F64 : xbType_F32, cast(i32)lt->size, xbLoc_Xmm);
			}
		} else {
			// widened to a legal vector or split into legal parts, each passed by pointer to an aligned copy
			i32 legal = xb_win64_legal_vector_size(elem->size);
			c.kind = xbArg_Indirect;
			c.copy = true;
			c.part_size = cast(i32)gb_min(lt->size, cast(i64)legal);
			c.part_size = gb_max(c.part_size, 16);
			c.parts = cast(i32)((lt->size + c.part_size - 1) / c.part_size);
		}
		break;
	}
	case xbLT_Int:
		if (lt->bits <= 64) {
			set(xb_win64_int_type(lt->size), cast(i32)lt->size, xbLoc_Gpr);
			if (lt->bits == 1) c.piece.ext = xbExt_Zero;
		} else if (is_return) {
			// an i128 comes back as <2 x i64> in xmm0
			set(xbType_V128, 16, xbLoc_Xmm);
		} else {
			c.kind = xbArg_Indirect;
		}
		break;
	case xbLT_Half:   set(xbType_F32, 2, xbLoc_Xmm); break;
	case xbLT_Float:  set(xbType_F32, 4, xbLoc_Xmm); break;
	case xbLT_Double: set(xbType_F64, 8, xbLoc_Xmm); break;
	case xbLT_Ptr:    set(xbType_I64, 8, xbLoc_Gpr); break;
	}
	return c;
}

// Hands out the positional slots.
struct xbWin64Assigner {
	i32 slot;
};

gb_internal void xb_win64_place(xbWin64Assigner *s, xbAbiPiece *p) {
	if (s->slot < 4) {
		p->reg = p->loc == xbLoc_Xmm ? cast(u8)s->slot : xb_win64_int_regs[s->slot];
	} else {
		p->loc = xbLoc_Stack;
		p->stack_offset = 32 + 8*(s->slot - 4);
	}
	s->slot += 1;
}

gb_internal void xb_win64_add_pointer_arg(xbAbiFunc *f, xbWin64Assigner *s, xbAbiArg *arg) {
	xbAbiPiece p = {};
	p.type = xbType_I64;
	p.size = 8;
	p.loc = xbLoc_Gpr;
	xb_win64_place(s, &p);
	arg->piece_index = cast(i32)f->pieces.count;
	arg->piece_count = 1;
	array_add(&f->pieces, p);
}

gb_internal xbAbiFunc *xb_abi_compute_win64(Type *proc_type, char const **reason) {
	Type *pt = base_type(proc_type);
	ProcCallingConvention cc = pt->Proc.calling_convention;
	switch (cc) {
	case ProcCC_Odin:
	case ProcCC_Contextless:
	case ProcCC_CDecl:
	case ProcCC_StdCall:
	case ProcCC_FastCall:
	case ProcCC_Win64:
		break;
	default:
		*reason = "calling convention";
		return nullptr;
	}

	xbAbiFunc *f = permanent_alloc_item<xbAbiFunc>();
	f->cc = cc;
	f->c_vararg = pt->Proc.c_vararg;
	f->is_odin_cc = cc == ProcCC_Odin;
	f->pieces = array_make<xbAbiPiece>(permanent_allocator(), 0, 8);
	f->params = array_make<xbAbiArg>(permanent_allocator(), 0, pt->Proc.param_count);
	f->split_ret_ptrs = array_make<xbAbiArg>(permanent_allocator(), 0, 0);

	// results
	xbWin64Class ret = {};
	ret.kind = xbArg_Ignore;
	i32 ret_parts = 0;
	if (pt->Proc.result_count != 0) {
		Type *single_ret = reduce_tuple_to_single_type(pt->Proc.results);
		if (is_type_proc(single_ret)) {
			single_ret = t_rawptr;
		}
		xbLType *lt = xb_ltype(single_ret);
		bool is_aggregate = lt->kind == xbLT_Struct || lt->kind == xbLT_Array;
		bool fits_reg = lt->size == 1 || lt->size == 2 || lt->size == 4 || lt->size == 8;
		Type *ret_type = single_ret;
		if (is_type_tuple(single_ret) && is_calling_convention_odin(cc) && is_aggregate && !fits_reg) {
			// all but the last result are returned through pointers appended to the params
			f->split_returns = true;
			auto const &vars = single_ret->Tuple.variables;
			for (isize i = 0; i < vars.count-1; i++) {
				xbAbiArg a = {};
				a.kind = xbArg_Indirect;
				a.type = vars[i]->type;
				array_add(&f->split_ret_ptrs, a);
			}
			ret_type = vars[vars.count-1]->type;
			lt = xb_ltype(ret_type);
		} else if (is_type_boolean(single_ret) && is_calling_convention_none(cc) && type_size_of(single_ret) <= 1) {
			lt = xb_lt_int(1);
		}
		ret = xb_win64_classify(lt, true);
		if (ret.unsupported) {
			*reason = "win64 abi return";
			return nullptr;
		}
		if (lt->kind == xbLT_Vector && lt->size > 16) {
			if (xb_x86_vector_width() > 16) {
				// with AVX, LLVM returns a wide vector in ymm/zmm registers, which this backend does not use
				*reason = "avx vector return";
				return nullptr;
			}
			// split into 16 byte parts in xmm0-xmm3, or demoted to sret when more
			ret_parts = cast(i32)(lt->size / 16);
			if (ret_parts <= 4) {
				ret.kind = xbArg_Direct;
			}
		}
		f->ret_type = ret_type;
		f->ret.type = ret_type;
	}

	xbWin64Assigner s = {};
	f->ret.kind = ret.kind;
	if (ret.kind == xbArg_Indirect) {
		f->has_sret = true;
		f->sret.kind = xbArg_Indirect;
		f->sret.type = f->ret_type;
		xb_win64_add_pointer_arg(f, &s, &f->sret);
	}

	if (pt->Proc.param_count != 0) {
		for (Entity *e : pt->Proc.params->Tuple.variables) {
			if (e->kind != Entity_Variable) continue;
			if (e->flags & EntityFlag_CVarArg) continue;
			Type *e_type = reduce_tuple_to_single_type(e->type);
			xbLType *lt = xb_abi_param_ltype(e, e_type);
			xbWin64Class c = xb_win64_classify(lt, false);
			if (e->flags & EntityFlag_ByPtr) {
				c.kind = xbArg_Indirect;
				c.unsupported = false;
			}
			if (c.unsupported) {
				*reason = "win64 abi param";
				return nullptr;
			}
			xbAbiArg arg = {};
			arg.kind = c.kind;
			arg.type = e->type;
			arg.copy = c.copy;
			switch (c.kind) {
			case xbArg_Ignore:
				break;
			case xbArg_Indirect:
				xb_win64_add_pointer_arg(f, &s, &arg);
				if (c.parts > 0 && !(e->flags & EntityFlag_ByPtr)) {
					arg.copy_part = c.part_size;
					for (i32 i = 1; i < c.parts; i++) {
						xbAbiPiece p = f->pieces[arg.piece_index];
						xb_win64_place(&s, &p);
						array_add(&f->pieces, p);
					}
					arg.piece_count = c.parts;
				}
				break;
			case xbArg_Direct:
				arg.piece_index = cast(i32)f->pieces.count;
				arg.piece_count = 1;
				xb_win64_place(&s, &c.piece);
				array_add(&f->pieces, c.piece);
				break;
			default:
				*reason = "win64 abi param";
				return nullptr;
			}
			array_add(&f->params, arg);
		}
	}
	for (xbAbiArg &a : f->split_ret_ptrs) {
		xb_win64_add_pointer_arg(f, &s, &a);
	}
	if (f->is_odin_cc) {
		f->context.kind = xbArg_Indirect;
		f->context.type = t_context;
		xb_win64_add_pointer_arg(f, &s, &f->context);
	}
	f->gpr_count = s.slot;
	f->xmm_count = s.slot;
	f->stack_size = 32 + 8*gb_max(s.slot - 4, 0);

	if (ret.kind == xbArg_Direct && ret_parts > 0) {
		f->ret.piece_index = cast(i32)f->pieces.count;
		f->ret.piece_count = ret_parts;
		for (i32 i = 0; i < ret_parts; i++) {
			xbAbiPiece p = {};
			p.type = xbType_V128;
			p.size = 16;
			p.src_offset = 16*i;
			p.loc = xbLoc_Xmm;
			p.reg = cast(u8)i;
			array_add(&f->pieces, p);
		}
	} else if (ret.kind == xbArg_Direct) {
		xbAbiPiece p = ret.piece;
		p.reg = p.loc == xbLoc_Gpr ? cast(u8)RAX : cast(u8)0;
		f->ret.piece_index = cast(i32)f->pieces.count;
		f->ret.piece_count = 1;
		array_add(&f->pieces, p);
	}
	return f;
}

// The C varargs of a call, after the fixed arguments. Returns the stack size of the call.
gb_internal i32 xb_win64_varargs(xbProc *p, xbAbiFunc *abi, Array<xbCallArg> *call_args, Slice<xbValue> args, isize arg_index) {
	i32 slot = abi->gpr_count;
	for (; arg_index < args.count; arg_index++) {
		xbValue v = args[arg_index];
		xbType st = xb_scalar_type(v.type);
		if (st == xbType_None) XB_UNSUPPORTED(p, "aggregate c vararg");
		xbCallArg a = {};
		a.type = st;
		a.size = xb_type_size(st);
		a.vreg = xb_value_to_reg(p, v);
		if (xb_type_is_int(st) && xb_type_size(st) < 4) {
			a.ext = xb_type_is_signed(v.type) ? xbExt_Sign : xbExt_Zero;
		}
		if (xb_type_is_float(st) && st == xbType_F32) {
			a.vreg = xb_convop(p, xbOp_FExt, xbType_F64, xbType_F32, a.vreg);
			a.type = xbType_F64;
			a.size = 8;
		}
		if (slot < 4) {
			if (xb_type_is_float(a.type)) {
				a.kind = xbCallArg_Xmm;
				a.reg = cast(u8)slot;
			} else {
				a.kind = xbCallArg_Gpr;
				a.reg = xb_win64_int_regs[slot];
			}
		} else {
			a.kind = xbCallArg_Stack;
			a.stack_offset = 32 + 8*(slot - 4);
		}
		slot += 1;
		array_add(call_args, a);
	}
	// a variadic callee may read a float from either register file
	isize n = call_args->count;
	for (isize i = 0; i < n; i++) {
		xbCallArg a = (*call_args)[i];
		if (a.kind != xbCallArg_Xmm && a.kind != xbCallArg_XmmMem) continue;
		if (a.reg >= 4) continue;
		a.kind = a.kind == xbCallArg_Xmm ? xbCallArg_Gpr : xbCallArg_GprMem;
		a.reg = xb_win64_int_regs[a.reg];
		if (a.kind == xbCallArg_Gpr) {
			a.type = a.type == xbType_F64 ? xbType_I64 : xbType_I32;
		}
		a.ext = xbExt_None;
		array_add(call_args, a);
	}
	return 32 + 8*gb_max(slot - 4, 0);
}

////////////////////////////////////////////////////////////////
// Prologue and epilogue
////////////////////////////////////////////////////////////////

gb_internal void xb_win64_prologue(xbLower *L, xbProcDebug *dbg) {
	xbAsm *a = &L->a;
	i64 start = L->proc_start;
	auto here = [&]() -> u8 {
		i64 off = xb_pos(a) - start;
		GB_ASSERT(off < 256);
		return cast(u8)off;
	};

	u8 pushes[8] = {};
	i32 n = 0;
	pushes[n++] = RSI;
	pushes[n++] = RDI;
	for (i32 i = 0; i < L->saved_count; i++) {
		pushes[n++] = L->saved[i];
	}
	bool pad = (n % 2) != 0;
	i32 area = (pad ? 8 : 0) + 16*L->saved_v_count;
	i64 total = 8*(1 + n) + area + L->frame_size;

	if (total >= 4096) {
		// touch every page from the top down before rsp moves past it, like __chkstk
		// mov r10d, pages; mov r11, rsp; 1: sub r11, 4096; test [r11], r11; dec r10d; jnz 1b
		xb_mov_r_imm(a, R10, cast(u64)(total / 4096));
		xb_mov_r_rm(a, 8, R11, xb_r(RSP));
		i64 loop = xb_pos(a);
		xb_alu_rm_imm(a, ALU_SUB, 8, xb_r(R11), 4096);
		xb_test_rm_r(a, 8, xb_m(R11, 0), R11);
		xb_alu_rm_imm(a, ALU_SUB, 4, xb_r(R10), 1);
		i64 j = xb_jcc32(a, CC_NE);
		xb_patch_rel32(a, j, loop);
	}

	xb_push(a, RBP);
	dbg->win_push_reg[0] = RBP;
	dbg->win_push_at[0] = here();
	dbg->win_push_count = 1;
	for (i32 i = 0; i < n; i++) {
		xb_push(a, pushes[i]);
		dbg->win_push_reg[dbg->win_push_count] = pushes[i];
		dbg->win_push_at[dbg->win_push_count] = here();
		dbg->win_push_count += 1;
	}
	dbg->win_pad_at = 0;
	dbg->win_pad_size = area;
	if (area > 0) {
		xb_alu_rm_imm(a, ALU_SUB, 8, xb_r(RSP), area);
		dbg->win_pad_at = here();
	}
	xb_mov_rm_r(a, 8, xb_r(RBP), RSP);
	dbg->win_setfp_at = here();
	dbg->win_alloc_at = 0;
	dbg->win_alloc_size = L->frame_size;
	if (L->frame_size > 0) {
		xb_enc(a, XB_W, 0x81, 5, xb_r(RSP), 4); // sub rsp, imm32
		xb_u32(a, cast(u32)L->frame_size);
		dbg->win_alloc_at = here();
	}
	// rbp is 16 byte aligned
	dbg->win_xmm_count = L->saved_v_count;
	for (i32 i = 0; i < L->saved_v_count; i++) {
		xb_enc(a, XB_0F, 0x29, L->saved_v[i], xb_m(RBP, 16*i)); // movaps [rbp + 16*i], xmm
		dbg->win_xmm_reg[i] = L->saved_v[i];
		dbg->win_xmm_at[i] = here();
	}
	L->win_area = area;
	L->incoming_base = 16 + 8*n + area;
}

gb_internal void xb_win64_epilogue(xbLower *L) {
	xbAsm *a = &L->a;
	for (i32 i = 0; i < L->saved_v_count; i++) {
		xb_enc(a, XB_0F, 0x28, L->saved_v[i], xb_m(RBP, 16*i)); // movaps xmm, [rbp + 16*i]
	}
	// lea rsp, [rbp + area]: an epilogue form the unwinder recognizes
	xb_lea(a, RSP, xb_m(RBP, L->win_area));
	for (i32 i = L->saved_count-1; i >= 0; i--) {
		xb_pop(a, L->saved[i]);
	}
	xb_pop(a, RDI);
	xb_pop(a, RSI);
	xb_pop(a, RBP);
	xb_ret(a);
}

// A thread local: the module's TLS block from the TEB, plus the variable's offset in .tls.
gb_internal xbOpnd xb_win64_tls_opnd(xbLower *L, xbMem const &m, u8 scratch) {
	xbAsm *a = &L->a;
	i32 index = xb_lower_symbol(L->p->m, L->out, str_lit("_tls_index"), 0);
	// mov scratch32, [rip + _tls_index]
	xb_enc(a, 0, 0x8B, scratch, xb_m_sym(index, 0));
	xb_shift_imm(a, 4, 8, xb_r(scratch), 3);
	// add scratch, gs:[0x58] (ThreadLocalStoragePointer)
	xb_b(a, 0x65);
	xb_b(a, cast(u8)(0x48 | ((scratch & 8) ? 4 : 0)));
	xb_b(a, 0x03);
	xb_b(a, cast(u8)(0x04 | ((scratch & 7) << 3)));
	xb_b(a, 0x25);
	xb_u32(a, 0x58);
	xb_mov_r_rm(a, 8, scratch, xb_m(scratch, 0));
	// lea scratch, [scratch + secrel32(sym)]
	u8 r = scratch & 7;
	xb_b(a, cast(u8)(0x48 | ((scratch & 8) ? 5 : 0)));
	xb_b(a, 0x8D);
	xb_b(a, cast(u8)(0x80 | (r << 3) | r));
	if (r == 4) xb_b(a, 0x24); // sib for r12
	xb_asm_reloc(a, xbReloc_SecRel32, xb_pos(a), cast(i32)m.base, 0);
	xb_u32(a, 0);
	return xb_m(scratch, m.offset);
}

// Foreign data lives in a DLL: its address is in the import table, at __imp_<name>.
gb_internal xbOpnd xb_win64_import_opnd(xbLower *L, xbMem const &m, u8 scratch) {
	// the main thread adds symbols while this runs, so the append names it
	i32 imp = xb_lower_import_symbol(L->out, cast(i32)m.base);
	xb_enc(&L->a, XB_W, 0x8B, scratch, xb_m_sym(imp, 0));
	return xb_m(scratch, m.offset);
}
