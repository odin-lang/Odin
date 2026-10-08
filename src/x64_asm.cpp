// Inline `asm` templates, x86-64 SysV (Linux) only.
//
// A call becomes one xbOp_Asm. The template's operands get fixed registers here,
// every instruction is encoded from the encoding form the checker picked, and the
// lowering only moves the inputs into those registers, copies the bytes and
// stores the outputs. All vregs live in stack slots, so every register except
// rsp, rbp and the callee saved ones (which are saved around the bytes) is free.
//
// Each operand gets a register of its own (tied pairs share one), so an output
// never overlaps an input or a scratch. Anything that cannot be encoded leaves
// the procedure to LLVM.

enum xbAsmOpndKind : u8 {
	xbAsmOpnd_None,
	xbAsmOpnd_Reg,
	xbAsmOpnd_Mem,
	xbAsmOpnd_Imm,
	xbAsmOpnd_Label,
};

struct xbAsmOpnd {
	xbAsmOpndKind kind;
	u16 cls;   // Asm_amd64::REG_CLASS_* of a register
	u8  hw;    // register number
	i8  base;  // memory: base register, -1 if none
	i8  index; // memory: index register, -1 if none
	u8  scale;
	u8  seg;   // memory: segment override prefix byte, 0 if none
	bool rip;  // memory: relative to the label `imm`, plus disp
	i32 disp;
	i64 imm;   // the immediate, or the label index
};

gb_internal bool xb_asm_target_ok(void) {
	return build_context.metrics.arch == TargetArch_amd64 && build_context.metrics.os == TargetOs_linux;
}

gb_internal char const *xb_asm_reason(char const *what, String name) {
	isize n = gb_strlen(what) + name.len + 2;
	char *s = cast(char *)gb_alloc(permanent_allocator(), n);
	gb_snprintf(s, n, "%s %.*s", what, LIT(name));
	return s;
}

// The register class an operand slot gives a template parameter.
gb_internal u16 xb_asm_slot_class(Asm_amd64::OperandType t) {
	switch (t) {
	case Asm_amd64::OP_R8:  case Asm_amd64::OP_RM8:  return Asm_amd64::REG_CLASS_GPR8;
	case Asm_amd64::OP_R16: case Asm_amd64::OP_RM16: return Asm_amd64::REG_CLASS_GPR16;
	case Asm_amd64::OP_R32: case Asm_amd64::OP_RM32: return Asm_amd64::REG_CLASS_GPR32;
	case Asm_amd64::OP_R64: case Asm_amd64::OP_RM64: return Asm_amd64::REG_CLASS_GPR64;
	case Asm_amd64::OP_XMM:
	case Asm_amd64::OP_XMM_M32:
	case Asm_amd64::OP_XMM_M64:
	case Asm_amd64::OP_XMM_M128:
		return Asm_amd64::REG_CLASS_XMM;
	case Asm_amd64::OP_YMM:
	case Asm_amd64::OP_YMM_M256:
		return Asm_amd64::REG_CLASS_YMM;
	case Asm_amd64::OP_ZMM:
	case Asm_amd64::OP_ZMM_M512:
		return Asm_amd64::REG_CLASS_ZMM;
	}
	return 0;
}

gb_internal bool xb_asm_is_gpr_class(u16 cls) {
	return cls == Asm_amd64::REG_CLASS_GPR64 || cls == Asm_amd64::REG_CLASS_GPR32 ||
	       cls == Asm_amd64::REG_CLASS_GPR16 || cls == Asm_amd64::REG_CLASS_GPR8;
}

gb_internal bool xb_asm_lookup_reg(String name, u16 *cls, u8 *hw) {
	Asm_amd64::Register r = g_asm_amd64.register_lookup(name);
	if (r == Asm_amd64::REG_INVALID || r == Asm_amd64::REG_RIP) return false;
	u16 code = Asm_amd64::register_codes[r];
	*cls = code & 0xFF00;
	*hw = cast(u8)(code & 0xFF);
	return true;
}

// The memory size an EVEX disp8 is scaled by, 0 to use a disp32: the whole operand, as
// no broadcast can be written, except for an element at a time.
gb_internal i32 xb_asm_evex_disp_scale(Asm_amd64::Encoding const &form, Asm_amd64::OperandType t) {
	using A = Asm_amd64;
	switch (form.mnemonic) {
	case A::M_VPCOMPRESSD: case A::M_VPCOMPRESSQ: case A::M_VCOMPRESSPS: case A::M_VCOMPRESSPD:
	case A::M_VPEXPANDD:   case A::M_VPEXPANDQ:   case A::M_VEXPANDPS:   case A::M_VEXPANDPD:
		return ((form.flags >> 6) & 3) == 2 ? 8 : 4;
	case A::M_VPMOVQB: case A::M_VPMOVSQB: case A::M_VPMOVUSQB:
		// the 128-bit form stores two bytes, not the m32 the table says
		if (((form.flags >> 8) & 3) == 1) return 2;
		break;
	}
	switch (t) {
	case A::OP_M8:   return 1;
	case A::OP_M16:  return 2;
	case A::OP_M32:  case A::OP_XMM_M32:  return 4;
	case A::OP_M64:  case A::OP_XMM_M64:  return 8;
	case A::OP_M128: case A::OP_XMM_M128: return 16;
	case A::OP_M256: case A::OP_YMM_M256: return 32;
	case A::OP_M512: case A::OP_ZMM_M512: return 64;
	}
	return 0;
}

// Encodes one instruction of `form`; `ops` are its explicit operands in source order.
// A label operand, or a label relative memory operand, gets its rel32 at `*rel_at`
// (holding the memory operand's displacement). Returns why it failed, or nullptr.
gb_internal char const *xb_asm_encode(Asm_amd64::Encoding const &form, xbAsmOpnd const *ops, isize op_count, u8 *out, i32 *len_, i32 *rel_at_) {
	using A = Asm_amd64;
	u32 fl = form.flags;
	u32 esc      = fl & 3;
	u32 mprefix  = (fl >> 2) & 3;
	u32 vex_type = (fl >> 4) & 3;
	u32 vex_w    = (fl >> 6) & 3;
	u32 vex_l    = (fl >> 8) & 3;
	bool force_w   = ((fl >> 11) & 1) != 0;
	bool opsize_16 = ((fl >> 12) & 1) != 0;
	bool no_rex    = ((fl >> 13) & 1) != 0;
	bool reg_ext   = ((fl >> 16) & 1) != 0;
	bool only_32   = ((fl >> 17) & 1) != 0;
	u32 addr_size  = (fl >> 18) & 3;
	if (only_32) return "32-bit only form";
	if (vex_type == 3) return "xop form";
	switch (form.mnemonic) {
	case A::M_VGATHERDPS:  case A::M_VGATHERDPD:  case A::M_VGATHERQPS:  case A::M_VGATHERQPD:
	case A::M_VPGATHERDD:  case A::M_VPGATHERDQ:  case A::M_VPGATHERQD:  case A::M_VPGATHERQQ:
	case A::M_VPSCATTERDD: case A::M_VPSCATTERDQ: case A::M_VPSCATTERQD: case A::M_VPSCATTERQQ:
	case A::M_VSCATTERDPS: case A::M_VSCATTERDPD: case A::M_VSCATTERQPS: case A::M_VSCATTERQPD:
		// a vector index (and a mask, for the EVEX ones) the operands cannot spell
		return "vsib form";
	}
	bool evex = vex_type == 2;
	*rel_at_ = -1;

	xbAsmOpnd const *slot[4] = {};
	for (isize i = 0; i < op_count; i++) {
		int s = g_asm_amd64.form_explicit_slot(form, cast(int)i);
		if (s < 0) return "operand slot";
		slot[s] = &ops[i];
	}
	i32 mr = -1, rg = -1, opr = -1, vv = -1;
	bool has_seg_slot = false;
	for (i32 s = 0; s < 4 && form.ops[s] != A::OP_NONE; s++) {
		xbAsmOpnd const *o = slot[s];
		if (form.ops[s] == A::OP_SREG) has_seg_slot = true;
		switch (form.enc[s]) {
		case A::ENC_MR:
			if (o == nullptr || (o->kind != xbAsmOpnd_Reg && o->kind != xbAsmOpnd_Mem)) return "r/m operand";
			mr = s;
			break;
		case A::ENC_REG:
		case A::ENC_OP_R:
		case A::ENC_VVVV:
		case A::ENC_IS4:
			if (o == nullptr || o->kind != xbAsmOpnd_Reg) return "register operand";
			if (form.enc[s] == A::ENC_REG)  rg = s;
			if (form.enc[s] == A::ENC_OP_R) opr = s;
			if (form.enc[s] == A::ENC_VVVV) vv = s;
			break;
		case A::ENC_IB:
		case A::ENC_IW:
		case A::ENC_ID:
		case A::ENC_IQ:
			if (o == nullptr || (o->kind != xbAsmOpnd_Imm && o->kind != xbAsmOpnd_Label)) return "immediate operand";
			if (o->kind == xbAsmOpnd_Label && form.enc[s] != A::ENC_IB && form.enc[s] != A::ENC_ID) return "label operand";
			break;
		case A::ENC_IMPL:
			// push/pop fs/gs: the opcode names the segment
			if (o != nullptr && form.ops[s] == A::OP_SREG) {
				u8 want = (form.opcode & 0x08) ? 5 : 4;
				if (o->kind != xbAsmOpnd_Reg || o->hw != want) return "segment operand";
			}
			break;
		case A::ENC_AAA:
			return "opmask operand";
		default:
			if (o != nullptr) return "unencoded operand";
			break;
		}
		if (o != nullptr && o->kind == xbAsmOpnd_Reg) {
			if (o->hw >= 16 && !evex) return "register above 15";
			if (o->cls == A::REG_CLASS_BND) return "register class";
		}
	}

	i32 n = 0;
	auto emit = [&](u8 b) { out[n++] = b; };
	auto emit32 = [&](u32 v) { for (i32 k = 0; k < 4; k++) emit(cast(u8)(v >> (8*k))); };

	for (i32 s = 0; s < 4; s++) {
		if (slot[s] && slot[s]->kind == xbAsmOpnd_Mem && slot[s]->seg) emit(slot[s]->seg);
	}
	if (addr_size == 1) return "16-bit address size";
	if (addr_size == 2) emit(0x67);

	if (evex) {
		if (esc == 0 || opr >= 0) return "evex form";
		// registers 16..31 take R' (reg), X (r/m) and V' (vvvv)
		u8 r = 1, r2 = 1, x = 1, b = 1, vvvv = 0xF, v2 = 1;
		if (rg >= 0) {
			r  = (slot[rg]->hw & 8)  ? 0 : 1;
			r2 = (slot[rg]->hw & 16) ? 0 : 1;
		}
		if (mr >= 0) {
			xbAsmOpnd const *o = slot[mr];
			if (o->kind == xbAsmOpnd_Reg && (o->hw & 8))  b = 0;
			if (o->kind == xbAsmOpnd_Reg && (o->hw & 16)) x = 0;
			if (o->kind == xbAsmOpnd_Mem && o->base >= 0 && (o->base & 8)) b = 0;
			if (o->kind == xbAsmOpnd_Mem && o->index >= 0 && (o->index & 8)) x = 0;
		}
		if (vv >= 0) {
			vvvv = cast(u8)(~slot[vv]->hw & 0xF);
			v2 = (slot[vv]->hw & 16) ? 0 : 1;
		}
		u8 ll = vex_l == 3 ? 2 : vex_l == 2 ? 1 : 0;
		u8 w = vex_w == 2 ? 1 : 0;
		emit(0x62);
		emit(cast(u8)((r << 7) | (x << 6) | (b << 5) | (r2 << 4) | esc));
		emit(cast(u8)((w << 7) | (vvvv << 3) | 0x04 | mprefix));
		emit(cast(u8)((ll << 5) | (v2 << 3)));
	} else if (vex_type == 1) {
		if (esc == 0 || opr >= 0) return "vex form";
		if (vex_l == 3) return "512-bit form";
		u8 r = 1, x = 1, b = 1, vvvv = 0xF;
		if (rg >= 0 && (slot[rg]->hw & 8)) r = 0;
		if (mr >= 0) {
			xbAsmOpnd const *o = slot[mr];
			if (o->kind == xbAsmOpnd_Reg && (o->hw & 8)) b = 0;
			if (o->kind == xbAsmOpnd_Mem && o->base >= 0 && (o->base & 8)) b = 0;
			if (o->kind == xbAsmOpnd_Mem && o->index >= 0 && (o->index & 8)) x = 0;
		}
		if (vv >= 0) vvvv = cast(u8)(~slot[vv]->hw & 0xF);
		u8 l = vex_l == 2 ? 1 : 0;
		u8 w = vex_w == 2 ? 1 : 0;
		u8 pp = cast(u8)mprefix;
		if (x && b && !w && esc == 1) {
			emit(0xC5);
			emit(cast(u8)((r << 7) | (vvvv << 3) | (l << 2) | pp));
		} else {
			emit(0xC4);
			emit(cast(u8)((r << 7) | (x << 6) | (b << 5) | esc));
			emit(cast(u8)((w << 7) | (vvvv << 3) | (l << 2) | pp));
		}
	} else {
		if (vv >= 0) return "vvvv operand without vex";
		// operand size from the form: a 16-bit slot. Widening moves and segment moves size by their destination only
		bool needs_66 = opsize_16;
		bool dst_only = form.mnemonic == A::M_MOVSX || form.mnemonic == A::M_MOVZX || has_seg_slot;
		for (i32 s = 0; s < 4 && form.ops[s] != A::OP_NONE; s++) {
			A::OperandType t = form.ops[s];
			if (t != A::OP_R16 && t != A::OP_RM16 && t != A::OP_AX_IMPL) continue;
			if (dst_only && s != 0) continue;
			needs_66 = true;
		}
		needs_66 = needs_66 && mprefix != 1 && form.ext < 0xC0;
		if (needs_66) emit(0x66);
		static u8 const mand[4] = {0, 0x66, 0xF3, 0xF2};
		if (mprefix != 0) emit(mand[mprefix]);

		u8 rex = force_w ? 0x48 : 0;
		if (rg >= 0 && (slot[rg]->hw & 8)) rex |= 0x44;
		if (mr >= 0) {
			xbAsmOpnd const *o = slot[mr];
			if (o->kind == xbAsmOpnd_Reg && (o->hw & 8)) rex |= 0x41;
			if (o->kind == xbAsmOpnd_Mem && o->base >= 0 && (o->base & 8)) rex |= 0x41;
			if (o->kind == xbAsmOpnd_Mem && o->index >= 0 && (o->index & 8)) rex |= 0x42;
		}
		if (opr >= 0 && (slot[opr]->hw & 8)) rex |= 0x41;
		bool spl = false, high = false;
		for (i32 s = 0; s < 4; s++) {
			xbAsmOpnd const *o = slot[s];
			if (o == nullptr || o->kind != xbAsmOpnd_Reg) continue;
			if (o->cls == A::REG_CLASS_GPR8 && o->hw >= 4 && o->hw < 8) spl = true;
			if (o->cls == A::REG_CLASS_GPR8H) high = true;
		}
		if (spl && rex == 0) rex = 0x40;
		if (rex != 0 && (high || no_rex)) return "high byte register with rex";
		if (rex != 0) emit(rex);
		switch (esc) {
		case 1: emit(0x0F); break;
		case 2: emit(0x0F); emit(0x38); break;
		case 3: emit(0x0F); emit(0x3A); break;
		}
	}

	// x87 fixed ModR/M forms put the +i register in the rm field
	bool x87_fixed = form.opcode >= 0xD8 && form.opcode <= 0xDF && form.ext >= 0xC0;
	u8 opr_index = opr >= 0 ? (slot[opr]->hw & 7) : 0;
	emit(cast(u8)(form.opcode + ((opr >= 0 && !x87_fixed) ? opr_index : 0)));

	if (mr >= 0 || rg >= 0) {
		if (mr < 0) return "modrm without r/m operand";
		u8 reg_field = reg_ext ? (form.ext & 7) : (rg >= 0 ? (slot[rg]->hw & 7) : 0);
		xbAsmOpnd const *o = slot[mr];
		if (o->kind == xbAsmOpnd_Reg) {
			emit(cast(u8)(0xC0 | (reg_field << 3) | (o->hw & 7)));
		} else if (o->rip) {
			emit(cast(u8)(0x05 | (reg_field << 3)));
			*rel_at_ = n;
			emit32(cast(u32)o->disp);
		} else if (o->base < 0 && o->index < 0) {
			emit(cast(u8)(0x04 | (reg_field << 3)));
			emit(0x25);
			emit32(cast(u32)o->disp);
		} else {
			bool has_base = o->base >= 0;
			u8 base = has_base ? (o->base & 7) : 5;
			bool need_sib = o->index >= 0 || base == 4;
			i32 disp = o->disp;
			// EVEX scales a disp8 by the memory size
			i32 scale8 = evex ? xb_asm_evex_disp_scale(form, form.ops[mr]) : 1;
			i32 disp8 = scale8 != 0 ? disp / scale8 : 0;
			bool fits8 = disp == 0 || (scale8 != 0 && disp % scale8 == 0 && disp8 >= -128 && disp8 <= 127);
			u8 mod = 0;
			i32 dsize = 0;
			if (!has_base) {
				mod = 0; dsize = 4;
			} else if (disp == 0 && base != 5) {
				mod = 0; dsize = 0;
			} else if (fits8) {
				mod = 1; dsize = 1;
			} else {
				mod = 2; dsize = 4;
			}
			if (need_sib) {
				u8 ss = o->scale == 8 ? 3 : o->scale == 4 ? 2 : o->scale == 2 ? 1 : 0;
				u8 idx = o->index >= 0 ? (o->index & 7) : 4;
				emit(cast(u8)((mod << 6) | (reg_field << 3) | 4));
				emit(cast(u8)((ss << 6) | (idx << 3) | base));
			} else {
				emit(cast(u8)((mod << 6) | (reg_field << 3) | base));
			}
			if (dsize == 1) emit(cast(u8)cast(i8)disp8);
			if (dsize == 4) emit32(cast(u32)disp);
		}
	} else if (form.ext >= 0xC0 && (esc != 0 || (form.opcode >= 0xD8 && form.opcode <= 0xDF))) {
		u8 m = form.ext;
		if (x87_fixed && opr >= 0) m = cast(u8)((m & 0xF8) | opr_index);
		emit(m);
	}

	for (i32 s = 0; s < 4 && form.ops[s] != A::OP_NONE; s++) {
		xbAsmOpnd const *o = slot[s];
		i32 size = 0;
		switch (form.enc[s]) {
		case A::ENC_IB: size = 1; break;
		case A::ENC_IW: size = 2; break;
		case A::ENC_ID: size = 4; break;
		case A::ENC_IQ: size = 8; break;
		case A::ENC_IS4: emit(cast(u8)(o->hw << 4)); continue;
		default: continue;
		}
		if (o->kind == xbAsmOpnd_Label) {
			*rel_at_ = n;
			for (i32 k = 0; k < size; k++) emit(0);
		} else {
			u64 v = cast(u64)o->imm;
			for (i32 k = 0; k < size; k++) emit(cast(u8)(v >> (8*k)));
		}
	}
	if (n > 15) return "instruction too long";
	*len_ = n;
	return nullptr;
}

struct xbAsmBuild {
	xbProc *p;
	Entity *tmpl;
	Array<AsmTemplateEntityDecl> *decls;
	Slice<i8>   reg;     // per decl: its register, -1 if none
	Slice<bool> is_vec;  // per decl: an xmm/ymm/zmm register
	Slice<bool> high;    // per decl: ah, ch, dh or bh, `reg` being 4..7
	Slice<i64>  imm;     // per decl: immediate value
	Array<String> labels;
	Array<u8>   pool;
	Array<xbAsmItem> items;
	i32         align;
	bool        writes_rbp;
};

gb_internal i32 xb_asm_decl_index(xbAsmBuild *b, Entity *e) {
	for_array(i, *b->decls) {
		if ((*b->decls)[i].entity == e) return cast(i32)i;
	}
	return -1;
}

gb_internal i32 xb_asm_label_index(xbAsmBuild *b, Ast *name) {
	String s = name->Ident.token.string;
	for_array(i, b->labels) {
		if (b->labels[i] == s) return cast(i32)i;
	}
	return -1;
}

// The value of a constant operand, or of a $ immediate parameter.
gb_internal bool xb_asm_const(xbAsmBuild *b, Ast *op, i64 *v) {
	if (op->tav.mode == Addressing_Constant) {
		ExactValue ev = exact_value_to_integer(op->tav.value);
		if (ev.kind != ExactValue_Integer) return false;
		*v = exact_value_to_i64(ev);
		return true;
	}
	if (op->kind == Ast_Ident) {
		i32 di = xb_asm_decl_index(b, entity_of_node(op));
		if (di >= 0 && (*b->decls)[di].kind == AsmTemplateEntityDecl_Immediate) {
			*v = b->imm[di];
			return true;
		}
	}
	return false;
}

// A base or index register of a memory operand.
gb_internal bool xb_asm_addr_reg(xbAsmBuild *b, Ast *op, i8 *out) {
	if (op->kind == Ast_AsmRegister) {
		u16 cls = 0; u8 hw = 0;
		if (!xb_asm_lookup_reg(op->AsmRegister.name.string, &cls, &hw)) return false;
		if (cls != Asm_amd64::REG_CLASS_GPR64) return false;
		*out = cast(i8)hw;
		return true;
	}
	if (op->kind == Ast_Ident) {
		i32 di = xb_asm_decl_index(b, entity_of_node(op));
		if (di < 0 || b->reg[di] < 0 || b->is_vec[di]) return false;
		AsmTemplateEntityDecl const &d = (*b->decls)[di];
		i64 bits = d.view_of >= 0 ? d.view_bits : 8*type_size_of(d.entity->type);
		if (bits != 64) return false;
		*out = b->reg[di];
		return true;
	}
	return false;
}

gb_internal char const *xb_asm_mem_opnd(xbAsmBuild *b, AstAsmMemoryOperand *m, xbAsmOpnd *o) {
	o->kind = xbAsmOpnd_Mem;
	o->base = -1;
	o->index = -1;
	o->scale = 1;
	// the checker only allows #pre and #post on arm64
	if (m->kind != AsmMemoryOperand_Default) return "asm pre/post memory operand";
	auto const &cl = m->classify;
	i64 disp = cl.has_disp_const ? cl.disp_total : 0;
	for (Ast *t : m->terms) {
		// a $ immediate displacement is not in the classification
		if (t->kind == Ast_AsmMemoryTerm && t->AsmMemoryTerm.scale == nullptr && t->AsmMemoryTerm.operand->kind == Ast_Ident) {
			i32 di = xb_asm_decl_index(b, entity_of_node(t->AsmMemoryTerm.operand));
			if (di >= 0 && (*b->decls)[di].kind == AsmTemplateEntityDecl_Immediate) {
				disp += t->AsmMemoryTerm.op.kind == Token_Sub ? -b->imm[di] : b->imm[di];
			}
		}
	}
	if (disp < -0x80000000ll || disp > 0x7fffffffll) return "asm memory displacement";
	o->disp = cast(i32)disp;
	if (cl.label != nullptr) {
		// a label is always relative to rip, the checker allows no registers with it
		if (cl.label->kind != Ast_AsmLabelDecl || cl.base != nullptr || cl.index != nullptr) return "asm label memory operand";
		i32 li = xb_asm_label_index(b, cl.label->AsmLabelDecl.name);
		if (li < 0) return "asm label";
		o->rip = true;
		o->imm = li;
	}
	if (m->segment_override != nullptr) {
		u16 cls = 0; u8 hw = 0;
		if (m->segment_override->kind != Ast_AsmRegister ||
		    !xb_asm_lookup_reg(m->segment_override->AsmRegister.name.string, &cls, &hw) ||
		    cls != Asm_amd64::REG_CLASS_SEG || hw > 5) {
			return "asm segment override";
		}
		static u8 const seg_prefix[6] = {0x26, 0x2E, 0x36, 0x3E, 0x64, 0x65};
		o->seg = seg_prefix[hw];
	}
	if (cl.base != nullptr && !xb_asm_addr_reg(b, cl.base, &o->base)) return "asm memory base";
	if (cl.index != nullptr) {
		if (!xb_asm_addr_reg(b, cl.index, &o->index) || o->index == RSP) return "asm memory index";
		if (cl.scale != nullptr) {
			i64 s = 0;
			if (!xb_asm_const(b, cl.scale, &s)) return "asm memory scale";
			if (cl.scale_op.kind != Token_Mul) {
				if (s < 0 || s > 3) return "asm memory scale";
				s = 1ll << s;
			}
			if (s != 1 && s != 2 && s != 4 && s != 8) return "asm memory scale";
			o->scale = cast(u8)s;
		}
	}
	return nullptr;
}

// Converts the operands of one instruction, `label_k` gets the label operand's index.
gb_internal char const *xb_asm_opnds(xbAsmBuild *b, AstAsmInstruction *in, Asm_amd64::Encoding const &form, xbAsmOpnd *ops, i32 *label_k) {
	*label_k = -1;
	for_array(k, in->operands) {
		Ast *op = in->operands[k];
		xbAsmOpnd *o = &ops[k];
		*o = {};
		int s = g_asm_amd64.form_explicit_slot(form, cast(int)k);
		if (s < 0) return "asm operand slot";
		Asm_amd64::OperandType t = form.ops[s];
		i64 v = 0;
		if (op->kind != Ast_AsmMemoryOperand && op->kind != Ast_AsmLabelDecl && xb_asm_const(b, op, &v)) {
			o->kind = xbAsmOpnd_Imm;
			o->imm = v;
			continue;
		}
		switch (op->kind) {
		case Ast_Ident: {
			i32 di = xb_asm_decl_index(b, entity_of_node(op));
			if (di < 0 || b->reg[di] < 0) return "asm operand";
			u16 cls = xb_asm_slot_class(t);
			if (cls == 0) return "asm operand slot";
			if (xb_asm_is_gpr_class(cls) == b->is_vec[di]) return "asm operand class";
			if (b->high[di]) {
				if (cls != Asm_amd64::REG_CLASS_GPR8) return "asm operand class";
				cls = Asm_amd64::REG_CLASS_GPR8H;
			}
			o->kind = xbAsmOpnd_Reg;
			o->cls = cls;
			o->hw = cast(u8)b->reg[di];
			break;
		}
		case Ast_AsmRegister: {
			u16 cls = 0; u8 hw = 0;
			if (!xb_asm_lookup_reg(op->AsmRegister.name.string, &cls, &hw)) return "asm register";
			o->kind = xbAsmOpnd_Reg;
			o->cls = cls;
			o->hw = hw;
			break;
		}
		case Ast_AsmMemoryOperand: {
			char const *why = xb_asm_mem_opnd(b, &op->AsmMemoryOperand, o);
			if (why) return why;
			break;
		}
		case Ast_AsmLabelDecl: {
			if (t != Asm_amd64::OP_REL8 && t != Asm_amd64::OP_REL32) return "asm label operand";
			i32 li = xb_asm_label_index(b, op->AsmLabelDecl.name);
			if (li < 0) return "asm label";
			o->kind = xbAsmOpnd_Label;
			o->imm = li;
			*label_k = cast(i32)k;
			break;
		}
		default:
			return "asm operand";
		}
	}
	return nullptr;
}

// The checker may pick an i386 only form (inc r16 is 0x40+r there, a REX prefix
// here). The same operands then fit the r/m form of the same width.
gb_internal Asm_amd64::Encoding const &xb_asm_long_mode_form(Slice<Asm_amd64::Encoding> forms, i32 index) {
	using A = Asm_amd64;
	A::Encoding const &form = forms[index];
	if (((form.flags >> 17) & 1) == 0) return form;
	auto as_rm = [](A::OperandType t) -> A::OperandType {
		switch (t) {
		case A::OP_R8:  return A::OP_RM8;
		case A::OP_R16: return A::OP_RM16;
		case A::OP_R32: return A::OP_RM32;
		case A::OP_R64: return A::OP_RM64;
		}
		return t;
	};
	for (A::Encoding const &f : forms) {
		if (((f.flags >> 17) & 1) != 0 || f.explicit_count() != form.explicit_count()) continue;
		bool ok = true;
		for (int k = 0; k < form.explicit_count(); k++) {
			int sa = g_asm_amd64.form_explicit_slot(form, k);
			int sb = g_asm_amd64.form_explicit_slot(f, k);
			if (sa < 0 || sb < 0 || as_rm(form.ops[sa]) != as_rm(f.ops[sb])) ok = false;
		}
		if (ok) return f;
	}
	return form;
}

gb_internal void xb_asm_add_bytes(xbAsmBuild *b, u8 const *data, i32 n) {
	xbAsmItem it = {};
	it.kind = xbAsmItem::Bytes;
	it.start = cast(i32)b->pool.count;
	it.len = n;
	array_add_elems(&b->pool, data, n);
	array_add(&b->items, it);
}

// `count` bytes of nops, the same ones the LLVM assembler pads with.
gb_internal void xb_asm_nops(Array<u8> *out, i64 count) {
	static u8 const nops[10][10] = {
		{0x90},
		{0x66, 0x90},
		{0x0F, 0x1F, 0x00},
		{0x0F, 0x1F, 0x40, 0x00},
		{0x0F, 0x1F, 0x44, 0x00, 0x00},
		{0x66, 0x0F, 0x1F, 0x44, 0x00, 0x00},
		{0x0F, 0x1F, 0x80, 0x00, 0x00, 0x00, 0x00},
		{0x0F, 0x1F, 0x84, 0x00, 0x00, 0x00, 0x00, 0x00},
		{0x66, 0x0F, 0x1F, 0x84, 0x00, 0x00, 0x00, 0x00, 0x00},
		{0x66, 0x2E, 0x0F, 0x1F, 0x84, 0x00, 0x00, 0x00, 0x00, 0x00},
	};
	while (count > 0) {
		// up to 15 bytes each, the ones past 10 as 0x66 prefixes
		i64 n = gb_min(count, 15);
		for (i64 k = 10; k < n; k++) array_add(out, cast(u8)0x66);
		i64 rest = gb_min(n, 10);
		array_add_elems(out, nops[rest-1], rest);
		count -= n;
	}
}

gb_internal void xb_asm_encode_body(xbAsmBuild *b) {
	xbProc *p = b->p;
	AstAsmTemplate *at = &b->tmpl->AsmTemplate.node->AsmTemplate;
	for (Ast *node : at->instructions) {
		if (node->kind == Ast_AsmLabelDecl) {
			array_add(&b->labels, node->AsmLabelDecl.name->Ident.token.string);
		}
	}
	for (Ast *node : at->instructions) {
		switch (node->kind) {
		case Ast_AsmLabelDecl: {
			xbAsmItem it = {};
			it.kind = xbAsmItem::Label;
			it.label = xb_asm_label_index(b, node->AsmLabelDecl.name);
			array_add(&b->items, it);
			break;
		}
		case Ast_AsmDirective: {
			AstAsmDirective *dir = &node->AsmDirective;
			String name = dir->name.string;
			if (name == "byte") {
				for (Ast *op : dir->operands) {
					ExactValue ev = exact_value_to_integer(op->tav.value);
					if (ev.kind != ExactValue_Integer) XB_UNSUPPORTED(p, "asm directive byte");
					u8 v = cast(u8)exact_value_to_i64(ev);
					xb_asm_add_bytes(b, &v, 1);
				}
			} else if ((name == "skip" || name == "nop" || name == "align") && dir->operands.count == 1) {
				ExactValue ev = exact_value_to_integer(dir->operands[0]->tav.value);
				if (ev.kind != ExactValue_Integer) XB_UNSUPPORTED(p, xb_asm_reason("asm directive", name));
				i64 count = exact_value_to_i64(ev);
				if (count < 0 || count > 4096) XB_UNSUPPORTED(p, xb_asm_reason("asm directive", name));
				if (name == "align") {
					// the padding depends on where the code lands, the layout works it out
					i32 align = count > 1 ? 1 << floor_log2(cast(u64)count) : 1;
					if (align == 1) break;
					xbAsmItem it = {};
					it.kind = xbAsmItem::Align;
					it.label = align;
					array_add(&b->items, it);
					b->align = gb_max(b->align, align);
					break;
				}
				auto fill = array_make<u8>(xb_allocator(), 0, count);
				if (name == "nop") {
					xb_asm_nops(&fill, count);
				} else {
					for (i64 k = 0; k < count; k++) array_add(&fill, cast(u8)0);
				}
				xb_asm_add_bytes(b, fill.data, cast(i32)fill.count);
			} else {
				XB_UNSUPPORTED(p, xb_asm_reason("asm directive", name));
			}
			break;
		}
		case Ast_AsmInstruction: {
			AstAsmInstruction *in = &node->AsmInstruction;
			String name = in->name->Ident.token.string;
			if (in->mnemonic == 0) {
				u8 byte = 0;
				switch (g_asm_amd64.prefix_lookup(name)) {
				case Asm_amd64::PREFIX_ES:    byte = 0x26; break;
				case Asm_amd64::PREFIX_CS:    byte = 0x2E; break;
				case Asm_amd64::PREFIX_SS:    byte = 0x36; break;
				case Asm_amd64::PREFIX_DS:    byte = 0x3E; break;
				case Asm_amd64::PREFIX_FS:    byte = 0x64; break;
				case Asm_amd64::PREFIX_GS:    byte = 0x65; break;
				case Asm_amd64::PREFIX_LOCK:  byte = 0xF0; break;
				case Asm_amd64::PREFIX_REPNE: byte = 0xF2; break;
				case Asm_amd64::PREFIX_REP:   byte = 0xF3; break;
				}
				if (byte == 0 || in->operands.count != 0) XB_UNSUPPORTED(p, xb_asm_reason("asm prefix", name));
				xb_asm_add_bytes(b, &byte, 1);
				break;
			}
			auto forms = g_asm_amd64.encoding_forms(in->mnemonic);
			if (in->valid_form_index < 0 || in->valid_form_index >= forms.count || in->operands.count > 4) {
				XB_UNSUPPORTED(p, xb_asm_reason("asm instruction", name));
			}
			Asm_amd64::Encoding const &form = xb_asm_long_mode_form(forms, in->valid_form_index);
			xbAsmOpnd ops[4] = {};
			i32 label_k = -1;
			char const *why = xb_asm_opnds(b, in, form, ops, &label_k);
			if (why) XB_UNSUPPORTED(p, why);

			u8 code[32] = {};
			i32 len = 0, rel_at = -1;
			if (label_k < 0) {
				why = xb_asm_encode(form, ops, in->operands.count, code, &len, &rel_at);
				if (why) XB_UNSUPPORTED(p, xb_asm_reason("asm instruction", name));
				if (rel_at < 0) {
					xb_asm_add_bytes(b, code, len);
					break;
				}
				// a label relative memory operand
				xbAsmItem it = {};
				it.kind = xbAsmItem::Branch;
				it.is_long = true;
				for (xbAsmOpnd const &o : ops) {
					if (o.kind == xbAsmOpnd_Mem && o.rip) it.label = cast(i32)o.imm;
				}
				it.long_start = cast(i32)b->pool.count; it.long_len = len; it.long_rel_at = rel_at;
				array_add_elems(&b->pool, code, len);
				array_add(&b->items, it);
				break;
			}

			// a branch: its short and near forms
			xbAsmItem it = {};
			it.kind = xbAsmItem::Branch;
			it.label = cast(i32)ops[label_k].imm;
			for_array(fi, forms) {
				Asm_amd64::Encoding const &f = forms[fi];
				int slot = g_asm_amd64.form_explicit_slot(f, label_k);
				if (f.explicit_count() != in->operands.count || slot < 0) continue;
				Asm_amd64::OperandType t = f.ops[slot];
				bool is_short = t == Asm_amd64::OP_REL8;
				if (!is_short && t != Asm_amd64::OP_REL32) continue;
				if ((is_short ? it.len : it.long_len) != 0) continue;
				if (in->operands.count != 1 && cast(i32)fi != in->valid_form_index) continue;
				why = xb_asm_encode(f, ops, in->operands.count, code, &len, &rel_at);
				if (why || rel_at < 0) continue;
				if (is_short) {
					it.start = cast(i32)b->pool.count; it.len = len; it.rel_at = rel_at;
				} else {
					it.long_start = cast(i32)b->pool.count; it.long_len = len; it.long_rel_at = rel_at;
				}
				array_add_elems(&b->pool, code, len);
			}
			if (it.len == 0 && it.long_len == 0) XB_UNSUPPORTED(p, xb_asm_reason("asm instruction", name));
			it.is_long = it.len == 0;
			array_add(&b->items, it);
			break;
		}
		default:
			XB_UNSUPPORTED(p, "asm statement");
		}
	}
}

// Lays the items out at code offset `start`, growing short branches that cannot reach.
// A negative start pads every #align fully, more than any start needs, so a layout that
// fits then fits anywhere. Returns false when a branch has no rel32 form to grow into.
gb_internal bool xb_asm_layout(Slice<xbAsmItem> items, Slice<u8> pool, i32 label_count, i64 start, Array<u8> *code) {
	auto label_off = slice_make<i32>(xb_allocator(), label_count);
	auto offset    = slice_make<i32>(xb_allocator(), items.count);
	auto is_long   = slice_make<bool>(xb_allocator(), items.count);
	for_array(i, items) is_long[i] = items[i].is_long;
	auto pad = [&](isize i, i32 off) -> i32 {
		i32 align = items[i].label;
		if (start < 0) return align - 1;
		return cast(i32)((align - (start + off) % align) % align);
	};
	for (;;) {
		i32 off = 0;
		for_array(i, items) {
			xbAsmItem const &it = items[i];
			offset[i] = off;
			switch (it.kind) {
			case xbAsmItem::Label:  label_off[it.label] = off; break;
			case xbAsmItem::Bytes:  off += it.len; break;
			case xbAsmItem::Align:  off += pad(i, off); break;
			case xbAsmItem::Branch: off += is_long[i] ? it.long_len : it.len; break;
			}
		}
		bool changed = false;
		for_array(i, items) {
			xbAsmItem const &it = items[i];
			if (it.kind != xbAsmItem::Branch || is_long[i]) continue;
			i32 d = label_off[it.label] - (offset[i] + it.len);
			if (d < -128 || d > 127) {
				if (it.long_len == 0) return false;
				is_long[i] = true;
				changed = true;
			}
		}
		if (!changed) break;
	}
	if (code == nullptr) return true;
	for_array(i, items) {
		xbAsmItem const &it = items[i];
		if (it.kind == xbAsmItem::Bytes) {
			array_add_elems(code, pool.data + it.start, it.len);
		} else if (it.kind == xbAsmItem::Align) {
			xb_asm_nops(code, pad(i, offset[i]));
		} else if (it.kind == xbAsmItem::Branch) {
			i32 at     = cast(i32)code->count;
			i32 from   = is_long[i] ? it.long_start  : it.start;
			i32 len    = is_long[i] ? it.long_len    : it.len;
			i32 rel_at = is_long[i] ? it.long_rel_at : it.rel_at;
			array_add_elems(code, pool.data + from, len);
			i32 d = label_off[it.label] - (offset[i] + len);
			if (is_long[i]) {
				// a memory operand's displacement is already there
				i32 v = 0;
				gb_memmove(&v, code->data + at + rel_at, 4);
				v += d;
				gb_memmove(code->data + at + rel_at, &v, 4);
			} else {
				code->data[at + rel_at] = cast(u8)cast(i8)d;
			}
		}
	}
	return true;
}

gb_internal u16 xb_asm_clobber_bits_to_gprs(u16 bits) {
	using A = Asm_amd64;
	u16 m = 0;
	if (bits & A::ClobberReg_RAX) m |= 1<<RAX;
	if (bits & A::ClobberReg_RBX) m |= 1<<RBX;
	if (bits & A::ClobberReg_RCX) m |= 1<<RCX;
	if (bits & A::ClobberReg_RDX) m |= 1<<RDX;
	if (bits & A::ClobberReg_RSI) m |= 1<<RSI;
	if (bits & A::ClobberReg_RDI) m |= 1<<RDI;
	if (bits & A::ClobberReg_RSP) m |= 1<<RSP;
	if (bits & A::ClobberReg_RBP) m |= 1<<RBP;
	if (bits & A::ClobberReg_R11) m |= 1<<R11;
	return m;
}

// Every register the template names, clobbers or uses implicitly, so none of them
// is handed to an operand. Writing rbp has it saved around the template; rsp is the
// template's own business, everything around it is addressed from rbp.
gb_internal void xb_asm_fixed_regs(xbAsmBuild *b, u16 *gprs, u16 *xmms) {
	xbProc *p = b->p;
	auto mark = [&](String name, bool written) {
		u16 cls = 0; u8 hw = 0;
		if (!xb_asm_lookup_reg(name, &cls, &hw)) XB_UNSUPPORTED(p, xb_asm_reason("asm register", name));
		if (cls == Asm_amd64::REG_CLASS_GPR8H) {
			cls = Asm_amd64::REG_CLASS_GPR8;
			hw -= 4;
		}
		if (xb_asm_is_gpr_class(cls)) {
			if (written && hw == RBP) b->writes_rbp = true;
			*gprs |= cast(u16)(1u << hw);
		} else if (cls == Asm_amd64::REG_CLASS_XMM || cls == Asm_amd64::REG_CLASS_YMM || cls == Asm_amd64::REG_CLASS_ZMM) {
			// 16..31 are never handed out, and no vector register is callee saved
			if (hw < 16) *xmms |= cast(u16)(1u << hw);
		}
	};
	// the registers named inside an operand
	auto walk = [&](Ast *op, bool written, auto &walk_ref) -> void {
		if (op == nullptr) return;
		switch (op->kind) {
		case Ast_AsmRegister:
			mark(op->AsmRegister.name.string, written);
			break;
		case Ast_AsmMemoryOperand:
			walk_ref(op->AsmMemoryOperand.segment_override, false, walk_ref);
			for (Ast *t : op->AsmMemoryOperand.terms) {
				if (t->kind != Ast_AsmMemoryTerm) continue;
				walk_ref(t->AsmMemoryTerm.operand, false, walk_ref);
				walk_ref(t->AsmMemoryTerm.scale, false, walk_ref);
			}
			break;
		case Ast_IndexExpr:
		case Ast_BinaryExpr:
		case Ast_AsmRegisterGroup:
			XB_UNSUPPORTED(p, "asm operand");
		}
	};

	AstAsmTemplate *at = &b->tmpl->AsmTemplate.node->AsmTemplate;
	for (Ast *node : at->instructions) {
		if (node->kind != Ast_AsmInstruction) continue;
		AstAsmInstruction *in = &node->AsmInstruction;
		if (in->mnemonic == 0) continue;
		auto forms = g_asm_amd64.encoding_forms(in->mnemonic);
		auto clobbers = g_asm_amd64.clobber_forms(in->mnemonic);
		if (in->valid_form_index < 0 || in->valid_form_index >= forms.count) {
			XB_UNSUPPORTED(p, xb_asm_reason("asm instruction", in->name->Ident.token.string));
		}
		Asm_amd64::Encoding const &form = forms[in->valid_form_index];
		Asm_amd64::Clobber const &cl = clobbers[in->valid_form_index];
		for_array(k, in->operands) {
			int s = g_asm_amd64.form_explicit_slot(form, cast(int)k);
			bool written = s >= 0 && (cast(u16)cl.written & (1u << s)) != 0;
			walk(in->operands[k], written, walk);
		}
		u16 implicit = cast(u16)cl.implicit_rd | cast(u16)cl.implicit_wr;
		if (cast(u16)cl.implicit_wr & Asm_amd64::ClobberReg_RBP) b->writes_rbp = true;
		*gprs |= xb_asm_clobber_bits_to_gprs(implicit);
		if (implicit & Asm_amd64::ClobberReg_XMM0) *xmms |= 1;
	}
	for (String const &name : b->tmpl->AsmTemplate.clobber_registers_set) {
		// the checker adds "<reg>" for a register outside its clobber names, next to the register itself
		if (name == "<reg>") continue;
		mark(name, true);
	}
	for (AsmTemplateEntityDecl const &d : *b->decls) {
		if (d.pin.len == 0 || d.pin_flag.len != 0) continue;
		u16 cls = 0; u8 hw = 0;
		// an operand cannot live in the registers that hold the frame
		if (xb_asm_lookup_reg(d.pin, &cls, &hw) && xb_asm_is_gpr_class(cls) && (hw == RSP || hw == RBP)) {
			XB_UNSUPPORTED(p, "asm operand pinned to rsp or rbp");
		}
		mark(d.pin, true);
	}
}

// Gives every operand a register: its pin, or a free one. Tied inputs share their
// output's, width views their source's.
gb_internal void xb_asm_assign_regs(xbAsmBuild *b, u16 *gprs_used) {
	xbProc *p = b->p;
	u16 gprs = 0, xmms = 0;
	xb_asm_fixed_regs(b, &gprs, &xmms);
	u16 used = gprs;
	gprs |= (1u << RSP) | (1u << RBP);

	static u8 const gpr_order[] = {RAX, RCX, RDX, RSI, RDI, R8, R9, R10, R11, RBX, R12, R13, R14, R15};
	auto &decls = *b->decls;
	for_array(i, decls) {
		AsmTemplateEntityDecl const &d = decls[i];
		b->reg[i] = -1;
		if (d.view_of >= 0 || d.kind == AsmTemplateEntityDecl_Immediate || d.pin_flag.len != 0) continue;
		if (d.param_group == AsmTemplateEntityDeclParamGroup_Input && d.tie >= 0) continue;
		if (d.param_group == AsmTemplateEntityDeclParamGroup_Scratch && d.kind == AsmTemplateEntityDecl_Memory) continue;

		i64 size = type_size_of(d.entity->type);
		if (d.pin.len != 0) {
			u16 cls = 0; u8 hw = 0;
			xb_asm_lookup_reg(d.pin, &cls, &hw);
			b->high[i] = cls == Asm_amd64::REG_CLASS_GPR8H;
			b->is_vec[i] = !xb_asm_is_gpr_class(cls) && !b->high[i];
			b->reg[i] = cast(i8)hw;
		} else if (d.reg_class == AsmRegClass_Integer) {
			for (u8 r : gpr_order) {
				if (gprs & (1u << r)) continue;
				gprs |= cast(u16)(1u << r);
				used |= cast(u16)(1u << r);
				b->reg[i] = cast(i8)r;
				break;
			}
			if (b->reg[i] < 0) XB_UNSUPPORTED(p, "asm out of registers");
		} else if (d.reg_class == AsmRegClass_Float || d.reg_class == AsmRegClass_Vector) {
			for (u8 r = 0; r < 16; r++) {
				if (xmms & (1u << r)) continue;
				xmms |= cast(u16)(1u << r);
				b->reg[i] = cast(i8)r;
				break;
			}
			if (b->reg[i] < 0) XB_UNSUPPORTED(p, "asm out of registers");
			b->is_vec[i] = true;
		} else {
			XB_UNSUPPORTED(p, "asm register class");
		}
		if (b->is_vec[i] ? size > 64 : size > (b->high[i] ? 1 : 8)) XB_UNSUPPORTED(p, "asm operand size");
	}
	// views and tied inputs follow their source to the register it got
	for_array(i, decls) {
		i32 r = cast(i32)i;
		for (;;) {
			AsmTemplateEntityDecl const &d = decls[r];
			if (d.view_of >= 0) {
				r = d.view_of;
			} else if (d.param_group == AsmTemplateEntityDeclParamGroup_Input && d.tie >= 0) {
				r = d.tie;
			} else {
				break;
			}
		}
		b->reg[i] = b->reg[r];
		b->is_vec[i] = b->is_vec[r];
		b->high[i] = b->high[r];
		// a width view of ah is not a register
		if (b->high[i] && r != i && decls[i].view_of >= 0) XB_UNSUPPORTED(p, "asm high byte view");
	}
	*gprs_used = used;
}

gb_internal bool xb_asm_imm_arg(Ast *arg, Type *t, i64 *out) {
	TypeAndValue tv = type_and_value_of_expr(arg);
	if (tv.mode != Addressing_Constant) return false;
	ExactValue ev = tv.value;
	Type *ct = core_type(t);
	if (is_type_float(ct)) {
		f64 f = exact_value_to_f64(ev);
		switch (type_size_of(ct)) {
		case 4: { f32 g = cast(f32)f; u32 bits = 0; gb_memmove(&bits, &g, 4); *out = bits; return true; }
		case 8: { u64 bits = 0; gb_memmove(&bits, &f, 8); *out = cast(i64)bits; return true; }
		}
		return false;
	}
	if (ev.kind == ExactValue_Bool) {
		*out = ev.value_bool ? 1 : 0;
		return true;
	}
	if (ev.kind == ExactValue_Pointer) {
		*out = cast(i64)ev.value_pointer;
		return true;
	}
	ev = exact_value_to_integer(ev);
	if (ev.kind != ExactValue_Integer) return false;
	*out = exact_value_to_i64(ev);
	return true;
}

gb_internal xbValue xb_build_asm_call(xbProc *p, Entity *e, AstCallExpr *ce) {
	if (!xb_asm_target_ok()) XB_UNSUPPORTED(p, "asm template call");
	GB_ASSERT(e->kind == Entity_AsmTemplate);
	Type *pt = base_type(e->type);
	GB_ASSERT(pt->kind == Type_Proc);

	xbAsmBuild b = {};
	b.p = p;
	b.tmpl = e;
	b.decls = &e->AsmTemplate.decls;
	isize nd = b.decls->count;
	b.reg    = slice_make<i8>(xb_allocator(), nd);
	b.is_vec = slice_make<bool>(xb_allocator(), nd);
	b.high   = slice_make<bool>(xb_allocator(), nd);
	b.imm    = slice_make<i64>(xb_allocator(), nd);
	b.labels = array_make<String>(xb_allocator(), 0, 4);
	b.pool   = array_make<u8>(xb_allocator(), 0, 64);
	b.items  = array_make<xbAsmItem>(xb_allocator(), 0, 16);

	// the arguments, in parameter order
	isize param_count = pt->Proc.param_count;
	auto arg_asts = slice_make<Ast *>(xb_allocator(), param_count);
	auto arg_vals = slice_make<xbValue>(xb_allocator(), param_count);
	if (ce->split_args == nullptr || ce->split_args->positional.count > param_count) XB_UNSUPPORTED(p, "asm call arguments");
	for_array(i, ce->split_args->positional) arg_asts[i] = ce->split_args->positional[i];
	for (Ast *arg : ce->split_args->named) {
		ast_node(fv, FieldValue, arg);
		isize i = lookup_procedure_parameter(&pt->Proc, fv->field->Ident.token.string);
		if (i < 0) XB_UNSUPPORTED(p, "asm call arguments");
		arg_asts[i] = fv->value;
	}
	auto param_decl = slice_make<i32>(xb_allocator(), param_count);
	for (isize i = 0; i < param_count; i++) param_decl[i] = -1;
	for_array(di, *b.decls) {
		i32 pi = (*b.decls)[di].param_index;
		if ((*b.decls)[di].param_group == AsmTemplateEntityDeclParamGroup_Input && pi >= 0 && pi < param_count) param_decl[pi] = cast(i32)di;
	}
	auto build_arg = [&](isize i) {
		Ast *arg = arg_asts[i];
		Type *t = pt->Proc.params->Tuple.variables[i]->type;
		i32 di = param_decl[i];
		if (di >= 0 && (*b.decls)[di].kind == AsmTemplateEntityDecl_Immediate) {
			if (!xb_asm_imm_arg(arg, t, &b.imm[di])) XB_UNSUPPORTED(p, "asm immediate argument");
			return;
		}
		xbValue v = xb_build_expr(p, arg);
		if (v.type != nullptr && is_type_tuple(v.type)) XB_UNSUPPORTED(p, "asm call arguments");
		arg_vals[i] = xb_emit_conv(p, v, t);
	};
	for (isize i = 0; i < param_count; i++) {
		if (arg_asts[i] == nullptr) XB_UNSUPPORTED(p, "asm default argument");
	}
	for_array(i, ce->split_args->positional) build_arg(i);
	for (Ast *arg : ce->split_args->named) {
		ast_node(fv, FieldValue, arg);
		build_arg(lookup_procedure_parameter(&pt->Proc, fv->field->Ident.token.string));
	}

	u16 gprs_used = 0;
	xb_asm_assign_regs(&b, &gprs_used);
	xb_asm_encode_body(&b);
	Slice<xbAsmItem> items = slice_from_array(b.items);
	Slice<u8> pool = slice_from_array(b.pool);
	if (!xb_asm_layout(items, pool, cast(i32)b.labels.count, -1, nullptr)) XB_UNSUPPORTED(p, "asm short branch out of range");

	Type *results = pt->Proc.results;
	isize result_count = results ? results->Tuple.variables.count : 0;
	auto result_vals = slice_make<xbValue>(xb_allocator(), result_count);
	auto inputs  = array_make<xbAsmIo>(xb_allocator(), 0, nd);
	auto outputs = array_make<xbAsmIo>(xb_allocator(), 0, nd);
	auto &decls = *b.decls;
	for_array(i, decls) {
		AsmTemplateEntityDecl const &d = decls[i];
		if (d.view_of >= 0) continue;
		xbAsmIo io = {};
		io.reg = cast(u8)b.reg[i];
		if (d.param_group == AsmTemplateEntityDeclParamGroup_Input) {
			if (d.kind == AsmTemplateEntityDecl_Immediate || d.no_init) continue;
			Type *t = pt->Proc.params->Tuple.variables[d.param_index]->type;
			xbValue v = arg_vals[d.param_index];
			xbType st = xb_scalar_type(t);
			i64 size = type_size_of(t);
			if (!b.is_vec[i]) {
				if (st == xbType_None || xb_type_is_float(st)) XB_UNSUPPORTED(p, "asm operand type");
				io.kind = b.high[i] ? xbAsmIo_Gpr8H : xbAsmIo_Gpr;
				io.size = cast(u8)xb_type_size(st);
				io.sign = xb_type_is_signed(t);
				io.vreg = xb_value_to_reg(p, v);
			} else if (xb_type_is_float(st)) {
				io.kind = xbAsmIo_Xmm;
				io.size = cast(u8)xb_type_size(st);
				io.vreg = xb_value_to_reg(p, v);
			} else {
				if (size != 2 && size != 4 && size != 8 && size != 16 && size != 32 && size != 64) XB_UNSUPPORTED(p, "asm operand type");
				io.kind = xbAsmIo_XmmMem;
				io.size = cast(u8)size;
				io.vreg = xb_lea(p, xb_value_to_mem(p, v));
			}
			array_add(&inputs, io);
		} else if (d.param_group == AsmTemplateEntityDeclParamGroup_Output) {
			Type *t = results->Tuple.variables[d.result_index]->type;
			xbType st = xb_scalar_type(t);
			i64 size = type_size_of(t);
			xbValue v = {};
			if (d.pin_flag.len != 0) {
				String f = d.pin_flag;
				xbCC cc = CC_E;
				if      (f == "c") cc = CC_B;
				else if (f == "p") cc = CC_P;
				else if (f == "z") cc = CC_E;
				else if (f == "s") cc = CC_S;
				else if (f == "o") cc = CC_O;
				else XB_UNSUPPORTED(p, xb_asm_reason("asm flag output", f));
				if (st == xbType_None || xb_type_is_float(st)) XB_UNSUPPORTED(p, "asm operand type");
				io.kind = xbAsmIo_Flag;
				io.reg = cc;
				io.size = cast(u8)xb_type_size(st);
				io.vreg = xb_new_vreg(p, st);
				v = xb_value_reg(t, io.vreg);
			} else if (!b.is_vec[i]) {
				if (st == xbType_None || xb_type_is_float(st)) XB_UNSUPPORTED(p, "asm operand type");
				io.kind = b.high[i] ? xbAsmIo_Gpr8H : xbAsmIo_Gpr;
				io.size = cast(u8)xb_type_size(st);
				io.vreg = xb_new_vreg(p, st);
				v = xb_value_reg(t, io.vreg);
			} else if (xb_type_is_float(st)) {
				io.kind = xbAsmIo_Xmm;
				io.size = cast(u8)xb_type_size(st);
				io.vreg = xb_new_vreg(p, st);
				v = xb_value_reg(t, io.vreg);
			} else {
				if (size != 2 && size != 4 && size != 8 && size != 16 && size != 32 && size != 64) XB_UNSUPPORTED(p, "asm operand type");
				xbMem m = xb_add_local(p, t, false);
				io.kind = xbAsmIo_XmmMem;
				io.size = cast(u8)size;
				io.vreg = xb_lea(p, m);
				v = xb_value_mem(t, m);
			}
			array_add(&outputs, io);
			result_vals[d.result_index] = v;
		}
	}

	xbAsmBlock blk = {};
	blk.items = items;
	blk.pool = pool;
	blk.label_count = cast(i32)b.labels.count;
	blk.align = b.align;
	blk.inputs = slice_from_array(inputs);
	blk.outputs = slice_from_array(outputs);
	u16 callee_saved = (1u << RBX) | (1u << R12) | (1u << R13) | (1u << R14) | (1u << R15);
	blk.save_regs = gprs_used & callee_saved;
	blk.save_local = -1;
	if (blk.save_regs != 0) {
		blk.save_local = xb_add_local_raw(p, 8*gb_count_set_bits(blk.save_regs), 8);
	}
	blk.rbp_local = b.writes_rbp ? xb_add_local_raw(p, 8, 8) : -1;
	array_add(&p->asms, blk);
	xbInstr in = xb_instr(xbOp_Asm);
	in.imm = p->asms.count-1;
	xb_emit(p, in);

	if (result_count == 0) {
		xbValue none = {};
		return none;
	}
	if (result_count == 1) {
		return result_vals[0];
	}
	xbMem m = xb_add_local(p, results, false);
	for (isize i = 0; i < result_count; i++) {
		Type *ft = nullptr;
		i64 off = type_offset_of(results, cast(i32)i, &ft);
		xb_store_value(p, xb_mem_offset(m, off), result_vals[i]);
	}
	return xb_load_value(p, results, m);
}
