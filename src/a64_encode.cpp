// arm64 machine code encoder for the forms the lowering uses. Every instruction is one
// little endian 32 bit word.

enum a64Reg : u8 {
	X0 = 0, X1, X2, X3, X4, X5, X6, X7, X8, X9, X10, X11, X12, X13, X14, X15,
	X16, X17, X18, X19, X20, X21, X22, X23, X24, X25, X26, X27, X28, X29, X30,
	XZR = 31,
	A64_SP = 31, // the same encoding as xzr, the instruction decides which
	A64_FP = 29,
	A64_LR = 30,
};

enum a64Cond : u8 {
	A64_EQ = 0x0, A64_NE = 0x1, A64_HS = 0x2, A64_LO = 0x3,
	A64_MI = 0x4, A64_PL = 0x5, A64_VS = 0x6, A64_VC = 0x7,
	A64_HI = 0x8, A64_LS = 0x9, A64_GE = 0xA, A64_LT = 0xB,
	A64_GT = 0xC, A64_LE = 0xD, A64_AL = 0xE,
};

gb_internal gb_inline void a64_emit(xbAsm *a, u32 w) {
	xb_u32(a, w);
}

gb_internal gb_inline u32 a64_sf(i32 size) {
	return size == 8 ? 1u<<31 : 0;
}

////////////////////////////////////////////////////////////////
// Moves and immediates
////////////////////////////////////////////////////////////////

// mov xd, xm
gb_internal void a64_mov(xbAsm *a, u8 rd, u8 rm) {
	a64_emit(a, 0xAA0003E0 | (cast(u32)rm << 16) | rd);
}

// mov between sp and a register: add rd, rn, #0
gb_internal void a64_mov_sp(xbAsm *a, u8 rd, u8 rn) {
	a64_emit(a, 0x91000000 | (cast(u32)rn << 5) | rd);
}

gb_internal void a64_movz(xbAsm *a, u8 rd, u16 imm, u32 hw) {
	a64_emit(a, 0xD2800000 | (hw << 21) | (cast(u32)imm << 5) | rd);
}

gb_internal void a64_movn(xbAsm *a, u8 rd, u16 imm, u32 hw) {
	a64_emit(a, 0x92800000 | (hw << 21) | (cast(u32)imm << 5) | rd);
}

gb_internal void a64_movk(xbAsm *a, u8 rd, u16 imm, u32 hw) {
	a64_emit(a, 0xF2800000 | (hw << 21) | (cast(u32)imm << 5) | rd);
}

// xd = v, with as few movz/movn/movk as the 16 bit chunks allow
gb_internal void a64_mov_imm(xbAsm *a, u8 rd, u64 v) {
	i32 zeros = 0, ones = 0;
	for (u32 i = 0; i < 4; i++) {
		u16 c = cast(u16)(v >> (16*i));
		if (c == 0) zeros++;
		if (c == 0xffff) ones++;
	}
	bool inverted = ones > zeros;
	u16 fill = inverted ? 0xffff : 0;
	bool first = true;
	for (u32 i = 0; i < 4; i++) {
		u16 c = cast(u16)(v >> (16*i));
		if (c == fill) continue;
		if (first) {
			if (inverted) a64_movn(a, rd, cast(u16)~c, i);
			else          a64_movz(a, rd, c, i);
			first = false;
		} else {
			a64_movk(a, rd, c, i);
		}
	}
	if (first) {
		if (inverted) a64_movn(a, rd, 0, 0);
		else          a64_movz(a, rd, 0, 0);
	}
}

////////////////////////////////////////////////////////////////
// Arithmetic
////////////////////////////////////////////////////////////////

enum a64AluOp : u32 {
	A64_ADD  = 0x0B000000,
	A64_SUB  = 0x4B000000,
	A64_SUBS = 0x6B000000,
	A64_AND  = 0x0A000000,
	A64_ORR  = 0x2A000000,
	A64_EOR  = 0x4A000000,
	A64_ORN  = 0x2A200000,
};

enum a64Shift : u32 {
	A64_LSL = 0,
	A64_LSR = 1,
	A64_ASR = 2,
};

// rd = rn op (rm shift amount), 64 bit; register 31 is xzr
gb_internal void a64_alu(xbAsm *a, a64AluOp op, u8 rd, u8 rn, u8 rm, a64Shift shift=A64_LSL, u32 amount=0) {
	a64_emit(a, (1u<<31) | op | (cast(u32)shift << 22) | (cast(u32)rm << 16) | (amount << 10) | (cast(u32)rn << 5) | rd);
}

// The N:immr:imms fields that encode v as a 64 bit logical immediate, or -1. Such an immediate
// is a run of ones, rotated, repeated in elements of 2 to 64 bits.
gb_internal i32 a64_logical_imm(u64 v) {
	if (v == 0 || v == ~0ull) return -1;
	u32 size = 64;
	while (size > 2) {
		u32 half = size / 2;
		u64 mask = (1ull << half) - 1;
		if ((v & mask) != ((v >> half) & mask)) break;
		size = half;
	}
	u64 emask = size == 64 ? ~0ull : (1ull << size) - 1;
	u64 e = v & emask;
	// rotate right until the ones start at bit 0 and end before a zero at the top
	u32 rot = 0;
	auto ror = [&](u64 x, u32 r) -> u64 {
		if (r == 0) return x;
		return ((x >> r) | (x << (size - r))) & emask;
	};
	while (rot < size) {
		u64 x = ror(e, rot);
		if ((x & 1) && !(x >> (size - 1) & 1)) {
			u32 ones = 0;
			while (ones < size && (x >> ones & 1)) ones++;
			if ((x >> ones) != 0) return -1; // not one run
			u32 immr = (size - rot) % size;
			u32 imms = ((~(size*2 - 1) & 0x3f) | (ones - 1)) & 0x3f;
			u32 n = size == 64 ? 1 : 0;
			return cast(i32)((n << 12) | (immr << 6) | imms);
		}
		rot++;
	}
	return -1;
}

// rd = rn op #imm, 64 bit, with `enc` from a64_logical_imm
gb_internal void a64_logical_imm_op(xbAsm *a, a64AluOp op, u8 rd, u8 rn, i32 enc) {
	u32 opc = op == A64_AND ? 0x92000000u : op == A64_ORR ? 0xB2000000u : 0xD2000000u;
	a64_emit(a, opc | (cast(u32)enc << 10) | (cast(u32)rn << 5) | rd);
}

// cmp xn, xm
gb_internal void a64_cmp(xbAsm *a, u8 rn, u8 rm) {
	a64_alu(a, A64_SUBS, XZR, rn, rm);
}

// cmp wn, #imm12
gb_internal void a64_cmp_imm32(xbAsm *a, u8 rn, u32 imm) {
	GB_ASSERT(imm < 4096);
	a64_emit(a, 0x7100001F | (imm << 10) | (cast(u32)rn << 5));
}

// rd = rn + imm, where rn and rd may be sp. Large values go through x17.
gb_internal void a64_add_imm(xbAsm *a, u8 rd, u8 rn, i64 imm) {
	if (imm >= 0 && imm < 4096) {
		a64_emit(a, 0x91000000 | (cast(u32)imm << 10) | (cast(u32)rn << 5) | rd);
	} else if (imm < 0 && -imm < 4096) {
		a64_emit(a, 0xD1000000 | (cast(u32)(-imm) << 10) | (cast(u32)rn << 5) | rd);
	} else if (imm > 0 && imm < (1<<24) && (imm & 0xfff) == 0) {
		a64_emit(a, 0x91400000 | (cast(u32)(imm >> 12) << 10) | (cast(u32)rn << 5) | rd);
	} else if (imm < 0 && -imm < (1<<24) && (-imm & 0xfff) == 0) {
		a64_emit(a, 0xD1400000 | (cast(u32)((-imm) >> 12) << 10) | (cast(u32)rn << 5) | rd);
	} else {
		GB_ASSERT(rd != X17 && rn != X17);
		a64_mov_imm(a, X17, cast(u64)imm);
		// add rd, rn, x17, uxtx: the extended register form takes sp
		a64_emit(a, 0x8B206000 | (cast(u32)X17 << 16) | (cast(u32)rn << 5) | rd);
	}
}

gb_internal bool a64_addsub_imm_ok(i64 v) {
	if (v == INT64_MIN) return false;
	u64 m = cast(u64)(v < 0 ? -v : v);
	return m < 4096 || ((m & 0xfff) == 0 && m < (1u<<24));
}

// rd = rn + v, or rn - v when `sub`; `flags` sets the flags, with rd 31 as xzr (cmp, cmn).
// Otherwise register 31 is sp. A negative v flips the operation.
gb_internal void a64_addsub_imm(xbAsm *a, bool sub, bool flags, u8 rd, u8 rn, i64 v) {
	GB_ASSERT(a64_addsub_imm_ok(v));
	if (v < 0) {
		sub = !sub;
		v = -v;
	}
	u32 w = (sub ? 0xD1000000 : 0x91000000) | (flags ? 1u<<29 : 0);
	if (v >= 4096) {
		w |= 1u<<22;
		v >>= 12;
	}
	a64_emit(a, w | (cast(u32)v << 10) | (cast(u32)rn << 5) | rd);
}

// xd = xn * xm
gb_internal void a64_mul(xbAsm *a, u8 rd, u8 rn, u8 rm) {
	a64_emit(a, 0x9B007C00 | (cast(u32)rm << 16) | (cast(u32)rn << 5) | rd);
}

// xd = xa - xn * xm
gb_internal void a64_msub(xbAsm *a, u8 rd, u8 rn, u8 rm, u8 ra) {
	a64_emit(a, 0x9B008000 | (cast(u32)rm << 16) | (cast(u32)ra << 10) | (cast(u32)rn << 5) | rd);
}

gb_internal void a64_umulh(xbAsm *a, u8 rd, u8 rn, u8 rm) {
	a64_emit(a, 0x9BC07C00 | (cast(u32)rm << 16) | (cast(u32)rn << 5) | rd);
}

gb_internal void a64_smulh(xbAsm *a, u8 rd, u8 rn, u8 rm) {
	a64_emit(a, 0x9B407C00 | (cast(u32)rm << 16) | (cast(u32)rn << 5) | rd);
}

gb_internal void a64_div(xbAsm *a, bool is_signed, u8 rd, u8 rn, u8 rm) {
	a64_emit(a, (is_signed ? 0x9AC00C00 : 0x9AC00800) | (cast(u32)rm << 16) | (cast(u32)rn << 5) | rd);
}

// lslv, lsrv, asrv; a 32 bit shift masks the count by 31 like x86
gb_internal void a64_shiftv(xbAsm *a, a64Shift kind, i32 size, u8 rd, u8 rn, u8 rm) {
	u32 op = kind == A64_LSL ? 0x1AC02000 : kind == A64_LSR ? 0x1AC02400 : 0x1AC02800;
	a64_emit(a, a64_sf(size) | op | (cast(u32)rm << 16) | (cast(u32)rn << 5) | rd);
}

// ubfm/sbfm, 64 bit
gb_internal void a64_bfm(xbAsm *a, bool is_signed, u8 rd, u8 rn, u32 immr, u32 imms) {
	a64_emit(a, (is_signed ? 0x93400000 : 0xD3400000) | (immr << 16) | (imms << 10) | (cast(u32)rn << 5) | rd);
}

gb_internal void a64_lsl_imm(xbAsm *a, u8 rd, u8 rn, u32 sh) {
	a64_bfm(a, false, rd, rn, (64 - sh) & 63, 63 - sh);
}

gb_internal void a64_lsr_imm(xbAsm *a, u8 rd, u8 rn, u32 sh) {
	a64_bfm(a, false, rd, rn, sh, 63);
}

// lsl, lsr or asr by a constant. A 64 bit shift masks it by 63; anything narrower
// shifts as 32 bits and masks it by 31, like the variable forms.
gb_internal void a64_shift_imm(xbAsm *a, a64Shift kind, i32 size, u8 rd, u8 rn, u32 sh) {
	if (size == 8) {
		sh &= 63;
		switch (kind) {
		case A64_LSL: a64_bfm(a, false, rd, rn, (64 - sh) & 63, 63 - sh); break;
		case A64_LSR: a64_bfm(a, false, rd, rn, sh, 63); break;
		case A64_ASR: a64_bfm(a, true, rd, rn, sh, 63); break;
		}
		return;
	}
	sh &= 31;
	u32 immr = kind == A64_LSL ? (32 - sh) & 31 : sh;
	u32 imms = kind == A64_LSL ? 31 - sh : 31;
	a64_emit(a, (kind == A64_ASR ? 0x13000000 : 0x53000000) | (immr << 16) | (imms << 10) | (cast(u32)rn << 5) | rd);
}

// tst wn, #0xff: NE when the low byte is not zero
gb_internal void a64_tst_byte(xbAsm *a, u8 rn) {
	a64_emit(a, 0x72001C1F | (cast(u32)rn << 5));
}

// sign or zero extends the low `size` bytes of xn into xd
gb_internal void a64_extend(xbAsm *a, bool is_signed, i32 size, u8 rd, u8 rn) {
	if (size >= 8) {
		if (rd != rn) a64_mov(a, rd, rn);
		return;
	}
	a64_bfm(a, is_signed, rd, rn, 0, cast(u32)(8*size - 1));
}

// xd = cond ? 1 : 0
gb_internal void a64_cset(xbAsm *a, u8 rd, a64Cond c) {
	a64_emit(a, 0x9A9F07E0 | (cast(u32)(c ^ 1) << 12) | rd);
}

// xd = cond ? xn : xm
gb_internal void a64_csel(xbAsm *a, u8 rd, u8 rn, u8 rm, a64Cond c) {
	a64_emit(a, 0x9A800000 | (cast(u32)rm << 16) | (cast(u32)c << 12) | (cast(u32)rn << 5) | rd);
}

gb_internal void a64_clz(xbAsm *a, u8 rd, u8 rn) {
	a64_emit(a, 0xDAC01000 | (cast(u32)rn << 5) | rd);
}

gb_internal void a64_rbit(xbAsm *a, u8 rd, u8 rn) {
	a64_emit(a, 0xDAC00000 | (cast(u32)rn << 5) | rd);
}

// byte swap of the low `size` bytes, the rest are zero
gb_internal void a64_rev(xbAsm *a, i32 size, u8 rd, u8 rn) {
	switch (size) {
	case 2: a64_emit(a, 0x5AC00400 | (cast(u32)rn << 5) | rd); break; // rev16 w
	case 4: a64_emit(a, 0x5AC00800 | (cast(u32)rn << 5) | rd); break; // rev w
	case 8: a64_emit(a, 0xDAC00C00 | (cast(u32)rn << 5) | rd); break; // rev x
	default: GB_PANIC("a64: bad rev size");
	}
}

////////////////////////////////////////////////////////////////
// Loads and stores
////////////////////////////////////////////////////////////////

enum a64MemOp : u8 {
	A64_STR,
	A64_LDR,   // zero extends
	A64_LDRS,  // sign extends to 64 bits
};

gb_internal u32 a64_size_log2(i32 size) {
	switch (size) {
	case 1:  return 0;
	case 2:  return 1;
	case 4:  return 2;
	case 8:  return 3;
	case 16: return 4;
	}
	GB_PANIC("a64: bad access size %d", size);
	return 0;
}

// One load or store of `size` bytes at [rn + off]. Falls back to a register offset in x17.
gb_internal void a64_ldst_raw(xbAsm *a, bool fp, a64MemOp op, i32 size, u8 rt, u8 rn, i64 off) {
	u32 lg = a64_size_log2(size);
	u32 sz = 0, opc = 0, v = 0;
	if (fp) {
		v = 1u << 26;
		if (size == 16) {
			sz = 0;
			opc = op == A64_STR ? 2 : 3;
		} else {
			sz = lg;
			opc = op == A64_STR ? 0 : 1;
		}
	} else {
		sz = lg;
		switch (op) {
		case A64_STR:  opc = 0; break;
		case A64_LDR:  opc = 1; break;
		case A64_LDRS: opc = size == 8 ? 1 : 2; break;
		}
	}
	u32 base = (sz << 30) | v | (opc << 22) | (cast(u32)rn << 5) | rt;
	if (off >= 0 && (off % size) == 0 && (off / size) < 4096) {
		a64_emit(a, 0x39000000 | base | (cast(u32)(off / size) << 10));
	} else if (off >= -256 && off < 256) {
		a64_emit(a, 0x38000000 | base | ((cast(u32)off & 0x1ff) << 12));
	} else {
		// rt names a v register for fp, which x17 cannot clash with
		GB_ASSERT(rn != X17 && (fp || rt != X17));
		a64_mov_imm(a, X17, cast(u64)off);
		a64_emit(a, 0x38206800 | base | (cast(u32)X17 << 16));
	}
}

gb_internal void a64_ldr(xbAsm *a, i32 size, bool is_signed, u8 rt, u8 rn, i64 off) {
	a64_ldst_raw(a, false, is_signed ? A64_LDRS : A64_LDR, size, rt, rn, off);
}

gb_internal void a64_str(xbAsm *a, i32 size, u8 rt, u8 rn, i64 off) {
	a64_ldst_raw(a, false, A64_STR, size, rt, rn, off);
}

gb_internal void a64_ldr_fp(xbAsm *a, i32 size, u8 vt, u8 rn, i64 off) {
	a64_ldst_raw(a, true, A64_LDR, size, vt, rn, off);
}

gb_internal void a64_str_fp(xbAsm *a, i32 size, u8 vt, u8 rn, i64 off) {
	a64_ldst_raw(a, true, A64_STR, size, vt, rn, off);
}

// stp or ldp of two x registers, or two d registers when `fp`, at [xn + off]
gb_internal void a64_pair(xbAsm *a, bool fp, bool load, u8 rt1, u8 rt2, u8 rn, i32 off) {
	GB_ASSERT(off % 8 == 0 && off >= -512 && off <= 504);
	u32 w = (fp ? 0x6D000000 : 0xA9000000) | (load ? 1u<<22 : 0);
	a64_emit(a, w | ((cast(u32)(off / 8) & 0x7f) << 15) | (cast(u32)rt2 << 10) | (cast(u32)rn << 5) | rt1);
}

////////////////////////////////////////////////////////////////
// Floating point
////////////////////////////////////////////////////////////////

// the ftype field: 0 single, 1 double, 3 half
gb_internal u32 a64_ftype(i32 size) {
	return size == 8 ? 1 : size == 4 ? 0 : 3;
}

enum a64FOp : u32 {
	A64_FMUL = 0x1E200800,
	A64_FDIV = 0x1E201800,
	A64_FADD = 0x1E202800,
	A64_FSUB = 0x1E203800,
};

gb_internal void a64_fop(xbAsm *a, a64FOp op, i32 size, u8 vd, u8 vn, u8 vm) {
	a64_emit(a, op | (a64_ftype(size) << 22) | (cast(u32)vm << 16) | (cast(u32)vn << 5) | vd);
}

gb_internal void a64_fsqrt(xbAsm *a, i32 size, u8 vd, u8 vn) {
	a64_emit(a, 0x1E21C000 | (a64_ftype(size) << 22) | (cast(u32)vn << 5) | vd);
}

gb_internal void a64_fneg(xbAsm *a, i32 size, u8 vd, u8 vn) {
	a64_emit(a, 0x1E214000 | (a64_ftype(size) << 22) | (cast(u32)vn << 5) | vd);
}

gb_internal void a64_fcmp(xbAsm *a, i32 size, u8 vn, u8 vm) {
	a64_emit(a, 0x1E202000 | (a64_ftype(size) << 22) | (cast(u32)vm << 16) | (cast(u32)vn << 5));
}

// float of `to` size from float of `from` size
gb_internal void a64_fcvt(xbAsm *a, i32 to, i32 from, u8 vd, u8 vn) {
	a64_emit(a, 0x1E224000 | (a64_ftype(from) << 22) | (a64_ftype(to) << 15) | (cast(u32)vn << 5) | vd);
}

// float from the 64 bit integer xn
gb_internal void a64_cvtf(xbAsm *a, bool is_signed, i32 fsize, u8 vd, u8 xn) {
	a64_emit(a, (is_signed ? 0x9E220000 : 0x9E230000) | (a64_ftype(fsize) << 22) | (cast(u32)xn << 5) | vd);
}

// 64 bit integer from a float, rounding toward zero
gb_internal void a64_fcvtz(xbAsm *a, bool is_signed, i32 fsize, u8 xd, u8 vn) {
	a64_emit(a, (is_signed ? 0x9E380000 : 0x9E390000) | (a64_ftype(fsize) << 22) | (cast(u32)vn << 5) | xd);
}

// fmov dd, xn
gb_internal void a64_fmov_to_fp(xbAsm *a, u8 vd, u8 xn) {
	a64_emit(a, 0x9E670000 | (cast(u32)xn << 5) | vd);
}

// fmov xd, dn
gb_internal void a64_fmov_from_fp(xbAsm *a, u8 xd, u8 vn) {
	a64_emit(a, 0x9E660000 | (cast(u32)vn << 5) | xd);
}

// fmov dd, dn: the low 64 bits, which hold any scalar
gb_internal void a64_fmov_reg(xbAsm *a, u8 vd, u8 vn) {
	a64_emit(a, 0x1E604000 | (cast(u32)vn << 5) | vd);
}

// fcsel dd, dn, dm, cond
gb_internal void a64_fcsel(xbAsm *a, u8 vd, u8 vn, u8 vm, a64Cond c) {
	a64_emit(a, 0x1E600C00 | (cast(u32)vm << 16) | (cast(u32)c << 12) | (cast(u32)vn << 5) | vd);
}

// cnt vd.8b, vn.8b
gb_internal void a64_cnt8b(xbAsm *a, u8 vd, u8 vn) {
	a64_emit(a, 0x0E205800 | (cast(u32)vn << 5) | vd);
}

// addv bd, vn.8b
gb_internal void a64_addv8b(xbAsm *a, u8 vd, u8 vn) {
	a64_emit(a, 0x0E31B800 | (cast(u32)vn << 5) | vd);
}

// The crypto instructions behind LLVM's intrinsics, on whole q registers. The first operand
// is also the result (vd), the others are vn and vm; a unary one reads vn and writes vd.
struct a64VecIntrinsic {
	char const *name;
	u32  opcode;
	u8   args;
	bool unary;
};

gb_global a64VecIntrinsic const a64_vec_intrinsics[] = {
	{"llvm.aarch64.crypto.aese",      0x4E284800, 2},
	{"llvm.aarch64.crypto.aesd",      0x4E285800, 2},
	{"llvm.aarch64.crypto.aesmc",     0x4E286800, 1, true},
	{"llvm.aarch64.crypto.aesimc",    0x4E287800, 1, true},
	{"llvm.aarch64.crypto.sha1c",     0x5E000000, 3},
	{"llvm.aarch64.crypto.sha1p",     0x5E001000, 3},
	{"llvm.aarch64.crypto.sha1m",     0x5E002000, 3},
	{"llvm.aarch64.crypto.sha1h",     0x5E280800, 1, true},
	{"llvm.aarch64.crypto.sha1su0",   0x5E003000, 3},
	{"llvm.aarch64.crypto.sha1su1",   0x5E281800, 2},
	{"llvm.aarch64.crypto.sha256h",   0x5E004000, 3},
	{"llvm.aarch64.crypto.sha256h2",  0x5E005000, 3},
	{"llvm.aarch64.crypto.sha256su0", 0x5E282800, 2},
	{"llvm.aarch64.crypto.sha256su1", 0x5E006000, 3},
	{"llvm.aarch64.crypto.sha512h",   0xCE608000, 3},
	{"llvm.aarch64.crypto.sha512h2",  0xCE608400, 3},
	{"llvm.aarch64.crypto.sha512su0", 0xCEC08000, 2},
	{"llvm.aarch64.crypto.sha512su1", 0xCE608800, 3},
};

// xbOp_Vec128 keeps the index in its u8 aux
static_assert(gb_count_of(a64_vec_intrinsics) <= 256, "");

gb_internal i32 a64_vec_intrinsic_index(String name, isize *args) {
	for (isize i = 0; i < gb_count_of(a64_vec_intrinsics); i++) {
		if (name == make_string_c(a64_vec_intrinsics[i].name)) {
			*args = a64_vec_intrinsics[i].args;
			return cast(i32)i;
		}
	}
	return -1;
}

// the intrinsic on v16 (vd), v17 (vn) and v18 (vm)
gb_internal void a64_vec_intrinsic(xbAsm *a, i32 index) {
	a64VecIntrinsic const &e = a64_vec_intrinsics[index];
	u32 n = e.unary ? 16 : 17;
	u32 m = e.args == 3 ? 18u << 16 : 0;
	a64_emit(a, e.opcode | m | (n << 5) | 16);
}

////////////////////////////////////////////////////////////////
// Control flow and system
////////////////////////////////////////////////////////////////

// b, with the offset patched in later; returns where
gb_internal i64 a64_b(xbAsm *a) {
	i64 at = xb_pos(a);
	a64_emit(a, 0x14000000);
	return at;
}

gb_internal void a64_patch_b(xbAsm *a, i64 at, i64 target) {
	i64 delta = (target - at) / 4;
	GB_ASSERT(delta >= -(1ll<<25) && delta < (1ll<<25));
	u32 w = 0x14000000 | (cast(u32)delta & 0x3ffffff);
	xb_patch_u32(a, at, w);
}

// cbz/cbnz wt over the next instruction
gb_internal void a64_cb_skip(xbAsm *a, bool nonzero, u8 rt) {
	a64_emit(a, (nonzero ? 0x35000000 : 0x34000000) | (2u << 5) | rt);
}

// b.cond over the next instruction
gb_internal void a64_bcond_skip(xbAsm *a, a64Cond c) {
	a64_emit(a, 0x54000000 | (2u << 5) | c);
}

// b.cond, or cbz/cbnz wt, with the offset patched in later; returns where
gb_internal i64 a64_bcond(xbAsm *a, a64Cond c) {
	i64 at = xb_pos(a);
	a64_emit(a, 0x54000000 | c);
	return at;
}

gb_internal i64 a64_cb(xbAsm *a, bool nonzero, u8 rt) {
	i64 at = xb_pos(a);
	a64_emit(a, (nonzero ? 0x35000000 : 0x34000000) | rt);
	return at;
}

// Patches the 19 bit offset of a b.cond or cbz/cbnz; false when the target is out of range.
gb_internal bool a64_patch_imm19(xbAsm *a, i64 at, i64 target) {
	i64 delta = (target - at) / 4;
	if (delta < -(1ll<<18) || delta >= (1ll<<18)) return false;
	u32 w = 0;
	gb_memmove(&w, a->code->data + at, 4);
	w = (w & ~(0x7ffffu << 5)) | ((cast(u32)delta & 0x7ffff) << 5);
	xb_patch_u32(a, at, w);
	return true;
}

// b.cond to an already known position
gb_internal void a64_bcond_to(xbAsm *a, a64Cond c, i64 target) {
	i64 delta = (target - xb_pos(a)) / 4;
	GB_ASSERT(delta >= -(1ll<<18) && delta < (1ll<<18));
	a64_emit(a, 0x54000000 | ((cast(u32)delta & 0x7ffff) << 5) | c);
}

gb_internal void a64_bl_sym(xbAsm *a, i32 sym) {
	xb_add_reloc(a->m, xbSection_Text, xbReloc_A64_Branch26, xb_pos(a), sym, 0);
	a64_emit(a, 0x94000000);
}

gb_internal void a64_blr(xbAsm *a, u8 rn) {
	a64_emit(a, 0xD63F0000 | (cast(u32)rn << 5));
}

gb_internal void a64_ret(xbAsm *a) {
	a64_emit(a, 0xD65F03C0);
}

gb_internal void a64_brk(xbAsm *a, u16 imm) {
	a64_emit(a, 0xD4200000 | (cast(u32)imm << 5));
}

////////////////////////////////////////////////////////////////
// Atomics, all sequentially consistent; every Apple cpu has the LSE instructions
////////////////////////////////////////////////////////////////

// ldar: load-acquire of `size` bytes at [xn], zero extended
gb_internal void a64_ldar(xbAsm *a, i32 size, u8 rt, u8 rn) {
	a64_emit(a, 0x08DFFC00 | (a64_size_log2(size) << 30) | (cast(u32)rn << 5) | rt);
}

// stlr: store-release of the low `size` bytes of xt at [xn]
gb_internal void a64_stlr(xbAsm *a, i32 size, u8 rt, u8 rn) {
	a64_emit(a, 0x089FFC00 | (a64_size_log2(size) << 30) | (cast(u32)rn << 5) | rt);
}

enum a64LseOp : u32 {
	A64_LDADD = 0x0000,
	A64_LDCLR = 0x1000, // [xn] &= ~xs
	A64_LDEOR = 0x2000,
	A64_LDSET = 0x3000, // [xn] |= xs
	A64_SWP   = 0x8000,
};

// xt = old [xn]; [xn] = old op xs, with acquire and release
gb_internal void a64_lse(xbAsm *a, a64LseOp op, i32 size, u8 rs, u8 rt, u8 rn) {
	a64_emit(a, 0x38E00000 | op | (a64_size_log2(size) << 30) | (cast(u32)rs << 16) | (cast(u32)rn << 5) | rt);
}

// casal: if [xn] == xs { [xn] = xt }; xs = old [xn]
gb_internal void a64_casal(xbAsm *a, i32 size, u8 rs, u8 rt, u8 rn) {
	a64_emit(a, 0x08E0FC00 | (a64_size_log2(size) << 30) | (cast(u32)rs << 16) | (cast(u32)rn << 5) | rt);
}

gb_internal void a64_dmb_ish(xbAsm *a) {
	a64_emit(a, 0xD5033BBF);
}

// xd = the page of `sym`, the low 12 bits come from the following instruction
gb_internal void a64_adrp(xbAsm *a, u8 rd, i32 sym, xbRelocKind kind) {
	xb_add_reloc(a->m, xbSection_Text, kind, xb_pos(a), sym, 0);
	a64_emit(a, 0x90000000 | rd);
}

// add xd, xn, sym@PAGEOFF
gb_internal void a64_add_pageoff(xbAsm *a, u8 rd, u8 rn, i32 sym) {
	xb_add_reloc(a->m, xbSection_Text, xbReloc_A64_PageOff12, xb_pos(a), sym, 0);
	a64_emit(a, 0x91000000 | (cast(u32)rn << 5) | rd);
}

// ldr xd, [xn, sym@GOTPAGEOFF] or sym@TLVPPAGEOFF
gb_internal void a64_ldr_pageoff(xbAsm *a, u8 rd, u8 rn, i32 sym, xbRelocKind kind) {
	xb_add_reloc(a->m, xbSection_Text, kind, xb_pos(a), sym, 0);
	a64_emit(a, 0xF9400000 | (cast(u32)rn << 5) | rd);
}
