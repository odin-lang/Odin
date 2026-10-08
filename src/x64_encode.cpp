// x86-64 machine code encoder for the forms the lowering uses.

enum xbReg : u8 {
	RAX, RCX, RDX, RBX, RSP, RBP, RSI, RDI,
	R8,  R9,  R10, R11, R12, R13, R14, R15,
	XB_RIP = 0xff,
};

enum xbCC : u8 {
	CC_O  = 0x0, CC_NO = 0x1, CC_B  = 0x2, CC_AE = 0x3,
	CC_E  = 0x4, CC_NE = 0x5, CC_BE = 0x6, CC_A  = 0x7,
	CC_S  = 0x8, CC_NS = 0x9, CC_P  = 0xA, CC_NP = 0xB,
	CC_L  = 0xC, CC_GE = 0xD, CC_LE = 0xE, CC_G  = 0xF,
};

// A machine operand: a register or a memory reference.
struct xbOpnd {
	bool is_mem;
	u8   reg;    // register, or memory base (XB_RIP for rip-relative)
	i32  disp;
	i32  sym;    // rip-relative symbol, -1 if none
	xbRelocKind reloc;
};

gb_internal gb_inline xbOpnd xb_r(u8 reg) {
	xbOpnd o = {};
	o.reg = reg;
	o.sym = -1;
	return o;
}

gb_internal gb_inline xbOpnd xb_m(u8 base, i32 disp) {
	xbOpnd o = {};
	o.is_mem = true;
	o.reg = base;
	o.disp = disp;
	o.sym = -1;
	return o;
}

gb_internal gb_inline xbOpnd xb_m_sym(i32 sym, i32 addend, xbRelocKind reloc=xbReloc_PC32) {
	xbOpnd o = {};
	o.is_mem = true;
	o.reg = XB_RIP;
	o.disp = addend;
	o.sym = sym;
	o.reloc = reloc;
	return o;
}

struct xbAsm {
	xbModule *m;
	Array<u8> *code;
};

gb_internal gb_inline i64 xb_pos(xbAsm *a) {
	return a->code->count;
}

gb_internal gb_inline void xb_b(xbAsm *a, u8 b) {
	array_add(a->code, b);
}

gb_internal void xb_bytes(xbAsm *a, void const *data, isize n) {
	array_add_elems(a->code, cast(u8 const *)data, n);
}

gb_internal void xb_u16(xbAsm *a, u16 v) { xb_bytes(a, &v, 2); }
gb_internal void xb_u32(xbAsm *a, u32 v) { xb_bytes(a, &v, 4); }
gb_internal void xb_u64(xbAsm *a, u64 v) { xb_bytes(a, &v, 8); }

gb_internal void xb_patch_u32(xbAsm *a, i64 at, u32 v) {
	gb_memmove(a->code->data + at, &v, 4);
}

gb_internal void xb_add_reloc(xbModule *m, xbSection section, xbRelocKind kind, i64 offset, i32 sym, i64 addend) {
	xbReloc r = {};
	r.section = section;
	r.kind = kind;
	r.offset = offset;
	r.sym = sym;
	r.addend = addend;
	array_add(&m->relocs, r);
}

enum : u32 {
	XB_W      = 1<<0, // REX.W
	XB_BYTE   = 1<<1, // 8-bit operation on a gpr (needs REX for sil/dil/spl/bpl)
	XB_P66    = 1<<2,
	XB_PF2    = 1<<3,
	XB_PF3    = 1<<4,
	XB_LOCK   = 1<<5,
	XB_0F     = 1<<6,
	XB_0F38   = 1<<7,
	XB_0F3A   = 1<<8,
};

// modrm [sib] [disp]. EVEX scales an 8-bit displacement by `disp8_scale`.
gb_internal void xb_enc_modrm(xbAsm *a, u8 reg, xbOpnd rm, i32 imm_size, i32 disp8_scale=1) {
	u8 r = reg & 7;
	if (!rm.is_mem) {
		xb_b(a, cast(u8)(0xC0 | (r<<3) | (rm.reg & 7)));
		return;
	}
	if (rm.reg == XB_RIP) {
		xb_b(a, cast(u8)(0x00 | (r<<3) | 5));
		i64 at = xb_pos(a);
		xb_u32(a, 0);
		GB_ASSERT(rm.sym >= 0);
		// rip points past the immediate when there is one
		xb_add_reloc(a->m, xbSection_Text, rm.reloc, at, rm.sym, cast(i64)rm.disp - 4 - imm_size);
		return;
	}
	u8 base = rm.reg & 7;
	i32 disp = rm.disp;
	u8 mod = 0;
	if (disp == 0 && base != 5) {
		mod = 0;
	} else if (disp % disp8_scale == 0 && disp/disp8_scale >= -128 && disp/disp8_scale <= 127) {
		mod = 1;
	} else {
		mod = 2;
	}
	if (base == 4) {
		xb_b(a, cast(u8)((mod<<6) | (r<<3) | 4));
		xb_b(a, 0x24);
	} else {
		xb_b(a, cast(u8)((mod<<6) | (r<<3) | base));
	}
	if (mod == 1) {
		xb_b(a, cast(u8)cast(i8)(disp/disp8_scale));
	} else if (mod == 2) {
		xb_u32(a, cast(u32)disp);
	}
}

// Encodes [prefixes] [REX] opcode modrm [sib] [disp]. `imm_size` is the number of
// immediate bytes the caller writes afterwards, needed for rip-relative addends.
gb_internal void xb_enc(xbAsm *a, u32 flags, u8 opcode, u8 reg, xbOpnd rm, i32 imm_size=0) {
	if (flags & XB_LOCK) xb_b(a, 0xF0);
	if (flags & XB_P66)  xb_b(a, 0x66);
	if (flags & XB_PF2)  xb_b(a, 0xF2);
	if (flags & XB_PF3)  xb_b(a, 0xF3);

	u8 rex = 0x40;
	if (flags & XB_W) rex |= 0x08;
	if (reg & 8)      rex |= 0x04;
	if (rm.is_mem) {
		if (rm.reg != XB_RIP && (rm.reg & 8)) rex |= 0x01;
	} else {
		if (rm.reg & 8) rex |= 0x01;
	}
	bool need_rex = rex != 0x40;
	if (flags & XB_BYTE) {
		// spl, bpl, sil, dil are only reachable with a REX prefix
		if ((reg >= 4 && reg < 8) || (!rm.is_mem && rm.reg >= 4 && rm.reg < 8)) {
			need_rex = true;
		}
	}
	if (need_rex) xb_b(a, rex);

	if (flags & XB_0F)   xb_b(a, 0x0F);
	if (flags & XB_0F38) { xb_b(a, 0x0F); xb_b(a, 0x38); }
	if (flags & XB_0F3A) { xb_b(a, 0x0F); xb_b(a, 0x3A); }
	xb_b(a, opcode);
	xb_enc_modrm(a, reg, rm, imm_size);
}

// vmovups between ymm (VEX.256) or zmm (EVEX.512) and memory
gb_internal void xb_vmovups_wide(xbAsm *a, i32 size, bool load, u8 x, xbOpnd m) {
	GB_ASSERT(m.is_mem && x < 16);
	u8 not_r = (x & 8) ? 0 : 0x80;
	u8 not_b = (m.reg != XB_RIP && (m.reg & 8)) ? 0 : 0x20;
	if (size == 32) {
		xb_b(a, 0xC4);
		xb_b(a, cast(u8)(not_r | 0x40 | not_b | 0x01)); // ~R ~X ~B, map 0F
		xb_b(a, 0x7C);                                   // W0, no vvvv, L=256, no prefix
		xb_b(a, load ? 0x10 : 0x11);
		xb_enc_modrm(a, x, m, 0);
	} else {
		GB_ASSERT(size == 64);
		xb_b(a, 0x62);
		xb_b(a, cast(u8)(not_r | 0x40 | not_b | 0x10 | 0x01)); // ~R ~X ~B ~R', map 0F
		xb_b(a, 0x7C);                                          // W0, no vvvv, no prefix
		xb_b(a, 0x48);                                          // L'L=512, ~V'
		xb_b(a, load ? 0x10 : 0x11);
		xb_enc_modrm(a, x, m, 0, 64);
	}
}

gb_internal u32 xb_size_flags(i32 size) {
	switch (size) {
	case 1: return XB_BYTE;
	case 2: return XB_P66;
	case 4: return 0;
	case 8: return XB_W;
	}
	GB_PANIC("invalid operand size %d", size);
	return 0;
}

// mov reg, rm
gb_internal void xb_mov_r_rm(xbAsm *a, i32 size, u8 reg, xbOpnd rm) {
	xb_enc(a, xb_size_flags(size), size == 1 ? 0x8A : 0x8B, reg, rm);
}
// mov rm, reg
gb_internal void xb_mov_rm_r(xbAsm *a, i32 size, xbOpnd rm, u8 reg) {
	xb_enc(a, xb_size_flags(size), size == 1 ? 0x88 : 0x89, reg, rm);
}

gb_internal void xb_mov_r_imm(xbAsm *a, u8 reg, u64 imm) {
	if (imm <= 0xffffffffull) {
		// mov r32, imm32 zero extends
		if (reg & 8) xb_b(a, 0x41);
		xb_b(a, cast(u8)(0xB8 + (reg & 7)));
		xb_u32(a, cast(u32)imm);
	} else if (cast(i64)imm >= -0x80000000ll && cast(i64)imm < 0) {
		// mov r/m64, simm32
		xb_enc(a, XB_W, 0xC7, 0, xb_r(reg));
		xb_u32(a, cast(u32)imm);
	} else {
		xb_b(a, cast(u8)(0x48 | ((reg & 8) ? 1 : 0)));
		xb_b(a, cast(u8)(0xB8 + (reg & 7)));
		xb_u64(a, imm);
	}
}

// Loads `size` bytes from rm into a 64-bit register, zero or sign extending.
gb_internal void xb_load_ext(xbAsm *a, i32 size, bool is_signed, u8 reg, xbOpnd rm) {
	switch (size) {
	case 1:
		if (is_signed) xb_enc(a, XB_W|XB_0F, 0xBE, reg, rm);
		else           xb_enc(a, XB_0F,      0xB6, reg, rm);
		break;
	case 2:
		if (is_signed) xb_enc(a, XB_W|XB_0F, 0xBF, reg, rm);
		else           xb_enc(a, XB_0F,      0xB7, reg, rm);
		break;
	case 4:
		if (is_signed) xb_enc(a, XB_W, 0x63, reg, rm);
		else           xb_enc(a, 0,    0x8B, reg, rm);
		break;
	case 8:
		xb_enc(a, XB_W, 0x8B, reg, rm);
		break;
	default:
		GB_PANIC("invalid load size %d", size);
	}
}

gb_internal void xb_lea(xbAsm *a, u8 reg, xbOpnd m) {
	GB_ASSERT(m.is_mem);
	xb_enc(a, XB_W, 0x8D, reg, m);
}

enum xbAluOp : u8 {
	ALU_ADD = 0, ALU_OR = 1, ALU_ADC = 2, ALU_SBB = 3, ALU_AND = 4, ALU_SUB = 5, ALU_XOR = 6, ALU_CMP = 7,
};

// alu reg, rm
gb_internal void xb_alu_r_rm(xbAsm *a, xbAluOp op, i32 size, u8 reg, xbOpnd rm) {
	u8 opc = cast(u8)((op<<3) | (size == 1 ? 0x02 : 0x03));
	xb_enc(a, xb_size_flags(size), opc, reg, rm);
}

// alu rm, imm32 (sign extended)
gb_internal void xb_alu_rm_imm(xbAsm *a, xbAluOp op, i32 size, xbOpnd rm, i32 imm) {
	if (size == 1) {
		xb_enc(a, XB_BYTE, 0x80, op, rm, 1);
		xb_b(a, cast(u8)imm);
	} else if (imm >= -128 && imm <= 127) {
		xb_enc(a, xb_size_flags(size), 0x83, op, rm, 1);
		xb_b(a, cast(u8)cast(i8)imm);
	} else if (size == 2) {
		xb_enc(a, xb_size_flags(size), 0x81, op, rm, 2);
		xb_u16(a, cast(u16)imm);
	} else {
		xb_enc(a, xb_size_flags(size), 0x81, op, rm, 4);
		xb_u32(a, cast(u32)imm);
	}
}

gb_internal void xb_test_rm_r(xbAsm *a, i32 size, xbOpnd rm, u8 reg) {
	xb_enc(a, xb_size_flags(size), size == 1 ? 0x84 : 0x85, reg, rm);
}

gb_internal void xb_imul_r_rm(xbAsm *a, i32 size, u8 reg, xbOpnd rm) {
	GB_ASSERT(size >= 2);
	xb_enc(a, xb_size_flags(size)|XB_0F, 0xAF, reg, rm);
}

// group 3: F7 /n -- 2 not, 3 neg, 4 mul, 5 imul, 6 div, 7 idiv
gb_internal void xb_grp3(xbAsm *a, u8 n, i32 size, xbOpnd rm) {
	xb_enc(a, xb_size_flags(size), size == 1 ? 0xF6 : 0xF7, n, rm);
}

// shifts by cl: D3 /n -- 4 shl, 5 shr, 7 sar, 0 rol, 1 ror
gb_internal void xb_shift_cl(xbAsm *a, u8 n, i32 size, xbOpnd rm) {
	xb_enc(a, xb_size_flags(size), size == 1 ? 0xD2 : 0xD3, n, rm);
}

gb_internal void xb_shift_imm(xbAsm *a, u8 n, i32 size, xbOpnd rm, u8 imm) {
	xb_enc(a, xb_size_flags(size), size == 1 ? 0xC0 : 0xC1, n, rm, 1);
	xb_b(a, imm);
}

gb_internal void xb_setcc(xbAsm *a, xbCC cc, u8 reg) {
	xb_enc(a, XB_BYTE|XB_0F, cast(u8)(0x90 + cc), 0, xb_r(reg));
}

gb_internal void xb_cmov(xbAsm *a, xbCC cc, i32 size, u8 reg, xbOpnd rm) {
	if (size < 4) size = 4;
	xb_enc(a, xb_size_flags(size)|XB_0F, cast(u8)(0x40 + cc), reg, rm);
}

// sign-extends rax into rdx for division
gb_internal void xb_sign_extend_rdx(xbAsm *a, i32 size) {
	switch (size) {
	case 2: xb_b(a, 0x66); xb_b(a, 0x99); break;
	case 4: xb_b(a, 0x99); break;
	case 8: xb_b(a, 0x48); xb_b(a, 0x99); break;
	default: GB_PANIC("bad size");
	}
}

gb_internal i64 xb_jmp32(xbAsm *a) {
	xb_b(a, 0xE9);
	i64 at = xb_pos(a);
	xb_u32(a, 0);
	return at;
}

gb_internal i64 xb_jcc32(xbAsm *a, xbCC cc) {
	xb_b(a, 0x0F);
	xb_b(a, cast(u8)(0x80 + cc));
	i64 at = xb_pos(a);
	xb_u32(a, 0);
	return at;
}

gb_internal void xb_patch_rel32(xbAsm *a, i64 at, i64 target) {
	i64 rel = target - (at + 4);
	xb_patch_u32(a, at, cast(u32)cast(i32)rel);
}

gb_internal void xb_call_sym(xbAsm *a, i32 sym) {
	xb_b(a, 0xE8);
	i64 at = xb_pos(a);
	xb_u32(a, 0);
	xb_add_reloc(a->m, xbSection_Text, xbReloc_PLT32, at, sym, -4);
}

gb_internal void xb_call_rm(xbAsm *a, xbOpnd rm) {
	xb_enc(a, 0, 0xFF, 2, rm);
}

gb_internal void xb_push(xbAsm *a, u8 reg) {
	if (reg & 8) xb_b(a, 0x41);
	xb_b(a, cast(u8)(0x50 + (reg & 7)));
}

gb_internal void xb_pop(xbAsm *a, u8 reg) {
	if (reg & 8) xb_b(a, 0x41);
	xb_b(a, cast(u8)(0x58 + (reg & 7)));
}

gb_internal void xb_ret(xbAsm *a)  { xb_b(a, 0xC3); }
gb_internal void xb_leave(xbAsm *a) { xb_b(a, 0xC9); }
gb_internal void xb_ud2(xbAsm *a)  { xb_b(a, 0x0F); xb_b(a, 0x0B); }
gb_internal void xb_int3(xbAsm *a) { xb_b(a, 0xCC); }
gb_internal void xb_rep_movsb(xbAsm *a) { xb_b(a, 0xF3); xb_b(a, 0xA4); }
gb_internal void xb_rep_stosb(xbAsm *a) { xb_b(a, 0xF3); xb_b(a, 0xAA); }
gb_internal void xb_mfence(xbAsm *a) { xb_b(a, 0x0F); xb_b(a, 0xAE); xb_b(a, 0xF0); }
gb_internal void xb_pause(xbAsm *a) { xb_b(a, 0xF3); xb_b(a, 0x90); }
gb_internal void xb_rdtsc(xbAsm *a) { xb_b(a, 0x0F); xb_b(a, 0x31); }
gb_internal void xb_syscall(xbAsm *a) { xb_b(a, 0x0F); xb_b(a, 0x05); }
gb_internal void xb_std(xbAsm *a) { xb_b(a, 0xFD); }
gb_internal void xb_cld(xbAsm *a) { xb_b(a, 0xFC); }

// SSE

// movss/movsd xmm, m  (or xmm, xmm)
gb_internal void xb_movs_x_rm(xbAsm *a, i32 size, u8 xmm, xbOpnd rm) {
	xb_enc(a, (size == 4 ? XB_PF3 : XB_PF2)|XB_0F, 0x10, xmm, rm);
}
// movss/movsd m, xmm
gb_internal void xb_movs_rm_x(xbAsm *a, i32 size, xbOpnd rm, u8 xmm) {
	xb_enc(a, (size == 4 ? XB_PF3 : XB_PF2)|XB_0F, 0x11, xmm, rm);
}
gb_internal void xb_movups_x_m(xbAsm *a, u8 xmm, xbOpnd m) {
	xb_enc(a, XB_0F, 0x10, xmm, m);
}
gb_internal void xb_movups_m_x(xbAsm *a, xbOpnd m, u8 xmm) {
	xb_enc(a, XB_0F, 0x11, xmm, m);
}
// vfmadd213ss/sd xmm, xmm_v, xmm/m: xmm = xmm_v*xmm + rm
gb_internal void xb_vfmadd213_s(xbAsm *a, i32 size, u8 xmm, u8 xmm_v, xbOpnd rm) {
	u8 not_r = (xmm & 8) ? 0 : 0x80;
	u8 not_b = (rm.reg != XB_RIP && (rm.reg & 8)) ? 0 : 0x20;
	xb_b(a, 0xC4);
	xb_b(a, cast(u8)(not_r | 0x40 | not_b | 0x02));                       // ~R ~X ~B, map 0F38
	xb_b(a, cast(u8)((size == 8 ? 0x80 : 0) | ((~xmm_v & 15) << 3) | 0x01)); // W, ~vvvv, LIG, 66
	xb_b(a, 0xA9);
	xb_enc_modrm(a, xmm, rm, 0);
}
// movd/movq xmm, r/m32/64
gb_internal void xb_movd_x_rm(xbAsm *a, i32 size, u8 xmm, xbOpnd rm) {
	xb_enc(a, XB_P66|XB_0F|(size == 8 ? XB_W : 0), 0x6E, xmm, rm);
}
// movd/movq r/m32/64, xmm
gb_internal void xb_movd_rm_x(xbAsm *a, i32 size, xbOpnd rm, u8 xmm) {
	xb_enc(a, XB_P66|XB_0F|(size == 8 ? XB_W : 0), 0x7E, xmm, rm);
}

enum xbSseOp : u8 {
	SSE_SQRT = 0x51,
	SSE_AND  = 0x54,
	SSE_XOR  = 0x57,
	SSE_ADD  = 0x58,
	SSE_MUL  = 0x59,
	SSE_CVT  = 0x5A, // ss<->sd
	SSE_SUB  = 0x5C,
	SSE_MIN  = 0x5D,
	SSE_DIV  = 0x5E,
	SSE_MAX  = 0x5F,
};

// scalar op: addss/addsd xmm, xmm/m
gb_internal void xb_sse_scalar(xbAsm *a, xbSseOp op, i32 size, u8 xmm, xbOpnd rm) {
	xb_enc(a, (size == 4 ? XB_PF3 : XB_PF2)|XB_0F, op, xmm, rm);
}

gb_internal void xb_xorps(xbAsm *a, u8 x, u8 y) {
	xb_enc(a, XB_0F, 0x57, x, xb_r(y));
}

gb_internal void xb_ucomis(xbAsm *a, i32 size, u8 xmm, xbOpnd rm) {
	xb_enc(a, (size == 8 ? XB_P66 : 0)|XB_0F, 0x2E, xmm, rm);
}

// cvtsi2ss/sd xmm, r/m32/64
gb_internal void xb_cvtsi2f(xbAsm *a, i32 fsize, i32 isize, u8 xmm, xbOpnd rm) {
	xb_enc(a, (fsize == 4 ? XB_PF3 : XB_PF2)|XB_0F|(isize == 8 ? XB_W : 0), 0x2A, xmm, rm);
}

// cvttss/sd2si r32/64, xmm/m
gb_internal void xb_cvttf2si(xbAsm *a, i32 fsize, i32 isize, u8 reg, xbOpnd rm) {
	xb_enc(a, (fsize == 4 ? XB_PF3 : XB_PF2)|XB_0F|(isize == 8 ? XB_W : 0), 0x2C, reg, rm);
}

gb_internal void xb_bswap(xbAsm *a, i32 size, u8 reg) {
	u8 rex = 0x40;
	if (size == 8) rex |= 0x08;
	if (reg & 8)   rex |= 0x01;
	if (rex != 0x40) xb_b(a, rex);
	xb_b(a, 0x0F);
	xb_b(a, cast(u8)(0xC8 + (reg & 7)));
}

// How an x86 vector intrinsic maps onto its 128-bit SSE instruction
enum xbVecForm : u8 {
	xbVecForm_Binary,   // op xmm1(a), xmm2(b)
	xbVecForm_Unary,    // op xmm1(a), xmm2(a): the scalar forms keep the upper lanes of a
	xbVecForm_Xmm0,     // op xmm1(a), xmm2(b), with c implicitly in xmm0
	xbVecForm_ShiftImm, // op /ext xmm1(a), imm8
	xbVecForm_ToGpr,    // op eax, xmm1(a): the result is a scalar
	xbVecForm_Flags,    // op xmm1(a), xmm2(b): the result is the condition in ext
};

// ext of xbVecForm_Flags: an xbCC, possibly combined with the parity flag
enum : u8 {
	xbVecCond_AndNP = 0x10, // and not unordered
	xbVecCond_OrP   = 0x20, // or unordered
	xbVecCond_Swap  = 0x40, // compares b with a
};

struct xbVecIntrinsic {
	char const *name;
	u32 flags;
	u8  opcode;
	xbVecForm form;
	u8  ext;  // the modrm reg field of xbVecForm_ShiftImm, the condition of xbVecForm_Flags
	bool imm; // the last argument is a constant imm8
};

gb_global xbVecIntrinsic const xb_vec_intrinsics[] = {
	{"llvm.x86.ssse3.pshuf.b.128",   XB_P66|XB_0F38, 0x00, xbVecForm_Binary},
	{"llvm.x86.sha1msg1",            XB_0F38,        0xC9, xbVecForm_Binary},
	{"llvm.x86.sha1msg2",            XB_0F38,        0xCA, xbVecForm_Binary},
	{"llvm.x86.sha1nexte",           XB_0F38,        0xC8, xbVecForm_Binary},
	{"llvm.x86.sha1rnds4",           XB_0F3A,        0xCC, xbVecForm_Binary, 0, true},
	{"llvm.x86.sha256msg1",          XB_0F38,        0xCC, xbVecForm_Binary},
	{"llvm.x86.sha256msg2",          XB_0F38,        0xCD, xbVecForm_Binary},
	{"llvm.x86.sha256rnds2",         XB_0F38,        0xCB, xbVecForm_Xmm0},

	{"llvm.x86.aesni.aesenc",          XB_P66|XB_0F38, 0xDC, xbVecForm_Binary},
	{"llvm.x86.aesni.aesenclast",      XB_P66|XB_0F38, 0xDD, xbVecForm_Binary},
	{"llvm.x86.aesni.aesdec",          XB_P66|XB_0F38, 0xDE, xbVecForm_Binary},
	{"llvm.x86.aesni.aesdeclast",      XB_P66|XB_0F38, 0xDF, xbVecForm_Binary},
	{"llvm.x86.aesni.aesimc",          XB_P66|XB_0F38, 0xDB, xbVecForm_Unary},
	{"llvm.x86.aesni.aeskeygenassist", XB_P66|XB_0F3A, 0xDF, xbVecForm_Unary, 0, true},
	{"llvm.x86.pclmulqdq",             XB_P66|XB_0F3A, 0x44, xbVecForm_Binary, 0, true},

	{"llvm.x86.sse.max.ss",   XB_PF3|XB_0F, 0x5F, xbVecForm_Binary},
	{"llvm.x86.sse.max.ps",   XB_0F,        0x5F, xbVecForm_Binary},
	{"llvm.x86.sse.min.ss",   XB_PF3|XB_0F, 0x5D, xbVecForm_Binary},
	{"llvm.x86.sse.min.ps",   XB_0F,        0x5D, xbVecForm_Binary},
	{"llvm.x86.sse.rcp.ss",   XB_PF3|XB_0F, 0x53, xbVecForm_Unary},
	{"llvm.x86.sse.rcp.ps",   XB_0F,        0x53, xbVecForm_Unary},
	{"llvm.x86.sse.rsqrt.ss", XB_PF3|XB_0F, 0x52, xbVecForm_Unary},
	{"llvm.x86.sse.rsqrt.ps", XB_0F,        0x52, xbVecForm_Unary},
	{"llvm.x86.sse.cmp.ss",   XB_PF3|XB_0F, 0xC2, xbVecForm_Binary, 0, true},
	{"llvm.x86.sse.cmp.ps",   XB_0F,        0xC2, xbVecForm_Binary, 0, true},

	{"llvm.x86.sse2.pavg.b",        XB_P66|XB_0F, 0xE0, xbVecForm_Binary},
	{"llvm.x86.sse2.pavg.w",        XB_P66|XB_0F, 0xE3, xbVecForm_Binary},
	{"llvm.x86.sse2.pmadd.wd",      XB_P66|XB_0F, 0xF5, xbVecForm_Binary},
	{"llvm.x86.sse2.pmulh.w",       XB_P66|XB_0F, 0xE5, xbVecForm_Binary},
	{"llvm.x86.sse2.pmulhu.w",      XB_P66|XB_0F, 0xE4, xbVecForm_Binary},
	{"llvm.x86.sse2.psad.bw",       XB_P66|XB_0F, 0xF6, xbVecForm_Binary},
	{"llvm.x86.sse2.psll.w",        XB_P66|XB_0F, 0xF1, xbVecForm_Binary},
	{"llvm.x86.sse2.psll.d",        XB_P66|XB_0F, 0xF2, xbVecForm_Binary},
	{"llvm.x86.sse2.psll.q",        XB_P66|XB_0F, 0xF3, xbVecForm_Binary},
	{"llvm.x86.sse2.psrl.w",        XB_P66|XB_0F, 0xD1, xbVecForm_Binary},
	{"llvm.x86.sse2.psrl.d",        XB_P66|XB_0F, 0xD2, xbVecForm_Binary},
	{"llvm.x86.sse2.psrl.q",        XB_P66|XB_0F, 0xD3, xbVecForm_Binary},
	{"llvm.x86.sse2.psra.w",        XB_P66|XB_0F, 0xE1, xbVecForm_Binary},
	{"llvm.x86.sse2.psra.d",        XB_P66|XB_0F, 0xE2, xbVecForm_Binary},
	{"llvm.x86.sse2.pslli.w",       XB_P66|XB_0F, 0x71, xbVecForm_ShiftImm, 6, true},
	{"llvm.x86.sse2.pslli.d",       XB_P66|XB_0F, 0x72, xbVecForm_ShiftImm, 6, true},
	{"llvm.x86.sse2.pslli.q",       XB_P66|XB_0F, 0x73, xbVecForm_ShiftImm, 6, true},
	{"llvm.x86.sse2.psrli.w",       XB_P66|XB_0F, 0x71, xbVecForm_ShiftImm, 2, true},
	{"llvm.x86.sse2.psrli.d",       XB_P66|XB_0F, 0x72, xbVecForm_ShiftImm, 2, true},
	{"llvm.x86.sse2.psrli.q",       XB_P66|XB_0F, 0x73, xbVecForm_ShiftImm, 2, true},
	{"llvm.x86.sse2.psrai.w",       XB_P66|XB_0F, 0x71, xbVecForm_ShiftImm, 4, true},
	{"llvm.x86.sse2.psrai.d",       XB_P66|XB_0F, 0x72, xbVecForm_ShiftImm, 4, true},
	{"llvm.x86.sse2.cvtps2dq",      XB_P66|XB_0F, 0x5B, xbVecForm_Unary},
	{"llvm.x86.sse2.cvttps2dq",     XB_PF3|XB_0F, 0x5B, xbVecForm_Unary},
	{"llvm.x86.sse2.cvtpd2ps",      XB_P66|XB_0F, 0x5A, xbVecForm_Unary},
	{"llvm.x86.sse2.cvtpd2dq",      XB_PF2|XB_0F, 0xE6, xbVecForm_Unary},
	{"llvm.x86.sse2.cvttpd2dq",     XB_P66|XB_0F, 0xE6, xbVecForm_Unary},
	{"llvm.x86.sse2.packsswb.128",  XB_P66|XB_0F, 0x63, xbVecForm_Binary},
	{"llvm.x86.sse2.packssdw.128",  XB_P66|XB_0F, 0x6B, xbVecForm_Binary},
	{"llvm.x86.sse2.packuswb.128",  XB_P66|XB_0F, 0x67, xbVecForm_Binary},
	{"llvm.x86.sse2.max.sd",        XB_PF2|XB_0F, 0x5F, xbVecForm_Binary},
	{"llvm.x86.sse2.max.pd",        XB_P66|XB_0F, 0x5F, xbVecForm_Binary},
	{"llvm.x86.sse2.min.sd",        XB_PF2|XB_0F, 0x5D, xbVecForm_Binary},
	{"llvm.x86.sse2.min.pd",        XB_P66|XB_0F, 0x5D, xbVecForm_Binary},
	{"llvm.x86.sse2.cmp.sd",        XB_PF2|XB_0F, 0xC2, xbVecForm_Binary, 0, true},
	{"llvm.x86.sse2.cmp.pd",        XB_P66|XB_0F, 0xC2, xbVecForm_Binary, 0, true},

	{"llvm.x86.sse3.addsub.ps", XB_PF2|XB_0F, 0xD0, xbVecForm_Binary},
	{"llvm.x86.sse3.addsub.pd", XB_P66|XB_0F, 0xD0, xbVecForm_Binary},
	{"llvm.x86.sse3.hadd.ps",   XB_PF2|XB_0F, 0x7C, xbVecForm_Binary},
	{"llvm.x86.sse3.hadd.pd",   XB_P66|XB_0F, 0x7C, xbVecForm_Binary},
	{"llvm.x86.sse3.hsub.ps",   XB_PF2|XB_0F, 0x7D, xbVecForm_Binary},
	{"llvm.x86.sse3.hsub.pd",   XB_P66|XB_0F, 0x7D, xbVecForm_Binary},

	{"llvm.x86.ssse3.phadd.w.128",     XB_P66|XB_0F38, 0x01, xbVecForm_Binary},
	{"llvm.x86.ssse3.phadd.d.128",     XB_P66|XB_0F38, 0x02, xbVecForm_Binary},
	{"llvm.x86.ssse3.phadd.sw.128",    XB_P66|XB_0F38, 0x03, xbVecForm_Binary},
	{"llvm.x86.ssse3.pmadd.ub.sw.128", XB_P66|XB_0F38, 0x04, xbVecForm_Binary},
	{"llvm.x86.ssse3.phsub.w.128",     XB_P66|XB_0F38, 0x05, xbVecForm_Binary},
	{"llvm.x86.ssse3.phsub.d.128",     XB_P66|XB_0F38, 0x06, xbVecForm_Binary},
	{"llvm.x86.ssse3.phsub.sw.128",    XB_P66|XB_0F38, 0x07, xbVecForm_Binary},
	{"llvm.x86.ssse3.psign.b.128",     XB_P66|XB_0F38, 0x08, xbVecForm_Binary},
	{"llvm.x86.ssse3.psign.w.128",     XB_P66|XB_0F38, 0x09, xbVecForm_Binary},
	{"llvm.x86.ssse3.psign.d.128",     XB_P66|XB_0F38, 0x0A, xbVecForm_Binary},
	{"llvm.x86.ssse3.pmul.hr.sw.128",  XB_P66|XB_0F38, 0x0B, xbVecForm_Binary},

	{"llvm.x86.sse41.pblendvb",   XB_P66|XB_0F38, 0x10, xbVecForm_Xmm0},
	{"llvm.x86.sse41.blendvps",   XB_P66|XB_0F38, 0x14, xbVecForm_Xmm0},
	{"llvm.x86.sse41.blendvpd",   XB_P66|XB_0F38, 0x15, xbVecForm_Xmm0},
	{"llvm.x86.sse41.packusdw",   XB_P66|XB_0F38, 0x2B, xbVecForm_Binary},
	{"llvm.x86.sse41.phminposuw", XB_P66|XB_0F38, 0x41, xbVecForm_Unary},
	{"llvm.x86.sse41.round.ps",   XB_P66|XB_0F3A, 0x08, xbVecForm_Unary,  0, true},
	{"llvm.x86.sse41.round.pd",   XB_P66|XB_0F3A, 0x09, xbVecForm_Unary,  0, true},
	{"llvm.x86.sse41.round.ss",   XB_P66|XB_0F3A, 0x0A, xbVecForm_Binary, 0, true},
	{"llvm.x86.sse41.round.sd",   XB_P66|XB_0F3A, 0x0B, xbVecForm_Binary, 0, true},
	{"llvm.x86.sse41.insertps",   XB_P66|XB_0F3A, 0x21, xbVecForm_Binary, 0, true},
	{"llvm.x86.sse41.dpps",       XB_P66|XB_0F3A, 0x40, xbVecForm_Binary, 0, true},
	{"llvm.x86.sse41.dppd",       XB_P66|XB_0F3A, 0x41, xbVecForm_Binary, 0, true},
	{"llvm.x86.sse41.mpsadbw",    XB_P66|XB_0F3A, 0x42, xbVecForm_Binary, 0, true},

	{"llvm.x86.sse.movmsk.ps",       XB_0F,              0x50, xbVecForm_ToGpr},
	{"llvm.x86.sse2.movmsk.pd",      XB_P66|XB_0F,       0x50, xbVecForm_ToGpr},
	{"llvm.x86.sse2.pmovmskb.128",   XB_P66|XB_0F,       0xD7, xbVecForm_ToGpr},
	{"llvm.x86.sse.cvtss2si",        XB_PF3|XB_0F,       0x2D, xbVecForm_ToGpr},
	{"llvm.x86.sse.cvttss2si",       XB_PF3|XB_0F,       0x2C, xbVecForm_ToGpr},
	{"llvm.x86.sse.cvtss2si64",      XB_PF3|XB_0F|XB_W,  0x2D, xbVecForm_ToGpr},
	{"llvm.x86.sse.cvttss2si64",     XB_PF3|XB_0F|XB_W,  0x2C, xbVecForm_ToGpr},
	{"llvm.x86.sse2.cvtsd2si",       XB_PF2|XB_0F,       0x2D, xbVecForm_ToGpr},
	{"llvm.x86.sse2.cvttsd2si",      XB_PF2|XB_0F,       0x2C, xbVecForm_ToGpr},
	{"llvm.x86.sse2.cvtsd2si64",     XB_PF2|XB_0F|XB_W,  0x2D, xbVecForm_ToGpr},
	{"llvm.x86.sse2.cvttsd2si64",    XB_PF2|XB_0F|XB_W,  0x2C, xbVecForm_ToGpr},

	// the conditions LLVM's X86 lowering picks for each predicate
	{"llvm.x86.sse.comieq.ss",    XB_0F,        0x2F, xbVecForm_Flags, CC_E|xbVecCond_AndNP},
	{"llvm.x86.sse.comineq.ss",   XB_0F,        0x2F, xbVecForm_Flags, CC_NE|xbVecCond_OrP},
	{"llvm.x86.sse.comigt.ss",    XB_0F,        0x2F, xbVecForm_Flags, CC_A},
	{"llvm.x86.sse.comige.ss",    XB_0F,        0x2F, xbVecForm_Flags, CC_AE},
	{"llvm.x86.sse.comilt.ss",    XB_0F,        0x2F, xbVecForm_Flags, CC_A|xbVecCond_Swap},
	{"llvm.x86.sse.comile.ss",    XB_0F,        0x2F, xbVecForm_Flags, CC_AE|xbVecCond_Swap},
	{"llvm.x86.sse.ucomieq.ss",   XB_0F,        0x2E, xbVecForm_Flags, CC_E|xbVecCond_AndNP},
	{"llvm.x86.sse.ucomineq.ss",  XB_0F,        0x2E, xbVecForm_Flags, CC_NE|xbVecCond_OrP},
	{"llvm.x86.sse.ucomigt.ss",   XB_0F,        0x2E, xbVecForm_Flags, CC_A},
	{"llvm.x86.sse.ucomige.ss",   XB_0F,        0x2E, xbVecForm_Flags, CC_AE},
	{"llvm.x86.sse.ucomilt.ss",   XB_0F,        0x2E, xbVecForm_Flags, CC_A|xbVecCond_Swap},
	{"llvm.x86.sse.ucomile.ss",   XB_0F,        0x2E, xbVecForm_Flags, CC_AE|xbVecCond_Swap},
	{"llvm.x86.sse2.comieq.sd",   XB_P66|XB_0F, 0x2F, xbVecForm_Flags, CC_E|xbVecCond_AndNP},
	{"llvm.x86.sse2.comineq.sd",  XB_P66|XB_0F, 0x2F, xbVecForm_Flags, CC_NE|xbVecCond_OrP},
	{"llvm.x86.sse2.comigt.sd",   XB_P66|XB_0F, 0x2F, xbVecForm_Flags, CC_A},
	{"llvm.x86.sse2.comige.sd",   XB_P66|XB_0F, 0x2F, xbVecForm_Flags, CC_AE},
	{"llvm.x86.sse2.comilt.sd",   XB_P66|XB_0F, 0x2F, xbVecForm_Flags, CC_A|xbVecCond_Swap},
	{"llvm.x86.sse2.comile.sd",   XB_P66|XB_0F, 0x2F, xbVecForm_Flags, CC_AE|xbVecCond_Swap},
	{"llvm.x86.sse2.ucomieq.sd",  XB_P66|XB_0F, 0x2E, xbVecForm_Flags, CC_E|xbVecCond_AndNP},
	{"llvm.x86.sse2.ucomineq.sd", XB_P66|XB_0F, 0x2E, xbVecForm_Flags, CC_NE|xbVecCond_OrP},
	{"llvm.x86.sse2.ucomigt.sd",  XB_P66|XB_0F, 0x2E, xbVecForm_Flags, CC_A},
	{"llvm.x86.sse2.ucomige.sd",  XB_P66|XB_0F, 0x2E, xbVecForm_Flags, CC_AE},
	{"llvm.x86.sse2.ucomilt.sd",  XB_P66|XB_0F, 0x2E, xbVecForm_Flags, CC_A|xbVecCond_Swap},
	{"llvm.x86.sse2.ucomile.sd",  XB_P66|XB_0F, 0x2E, xbVecForm_Flags, CC_AE|xbVecCond_Swap},
	{"llvm.x86.sse41.ptestz",     XB_P66|XB_0F38, 0x17, xbVecForm_Flags, CC_E},
	{"llvm.x86.sse41.ptestc",     XB_P66|XB_0F38, 0x17, xbVecForm_Flags, CC_B},
	{"llvm.x86.sse41.ptestnzc",   XB_P66|XB_0F38, 0x17, xbVecForm_Flags, CC_A},
};

// xbOp_Vec128 keeps the index in its u8 aux
static_assert(gb_count_of(xb_vec_intrinsics) <= 256, "");

gb_internal i32 xb_vec_intrinsic_index(String name) {
	for (isize i = 0; i < gb_count_of(xb_vec_intrinsics); i++) {
		if (name == make_string_c(xb_vec_intrinsics[i].name)) {
			return cast(i32)i;
		}
	}
	return -1;
}
