package rexcode_arm64

import "../isa"

// =============================================================================
// AArch64 ENCODING FUNDAMENTALS
// =============================================================================
//
// All A64 instructions are exactly 4 bytes, little-endian when stored to
// memory. The top-level encoding class lives at bits[28:25] (`op0`) and
// the ARM ARM divides the ISA into eight families from there. We follow
// the (bits, mask) model -- `bits` carries the fully static field
// pattern, `mask` flags which bits are static. Operand-driven bits land
// in the zero positions and are ORed in by the encoder.
//
// Standard field positions (bits 0-31, low bit first):
//
//   Rd        0-4     destination register
//   Rt        0-4     load/store destination
//   Rn        5-9     first source / base register
//   Ra        10-14   third source (MADD/MSUB)
//   Rt2       10-14   second load/store register (LDP/STP)
//   Rm        16-20   second source
//   imm12     10-21   12-bit unsigned (ADD/SUB imm, LDR/STR offset scaled)
//   imm6      10-15   shift amount (data-proc shifted register)
//   imm9      12-20   9-bit signed (LDUR/STUR; pre/post-index disp)
//   imm16     5-20    16-bit (MOVZ/MOVN/MOVK)
//   imm19     5-23    19-bit signed (B.cond, CBZ, LDR literal)
//   imm26     0-25    26-bit signed (B, BL)
//   imm14     5-18    14-bit signed (TBZ/TBNZ)
//   cond      0-3     condition code (B.cond)
//   sh        22      LSL #12 flag (ADD/SUB imm)
//   hw        21-22   MOVZ/MOVN/MOVK shift amount (0/16/32/48)
//   shift     22-23   shift type for data-proc shifted register
//   option    13-15   extend type (data-proc extended register, LDR/STR EXT)
//   imm3      10-12   extend amount

Result           :: isa.Result
Error            :: isa.Error
Error_Code       :: isa.Error_Code
Label_Definition :: isa.Label_Definition
LABEL_UNDEFINED  :: isa.LABEL_UNDEFINED
Label_Map        :: isa.Label_Map

// Architectural feature this entry requires (for filtering and tagging
// at decode/print time).
Feature :: enum u8 {
	BASE,         // AArch64 base integer ISA
	FP,           // scalar FP (FPSCR-using; FADD/FCMP/FCVT/etc.)
	NEON,         // Advanced SIMD vector ops
	CRYPTO,       // AES, SHA1, SHA2, SHA3, SM3, SM4
	CRC32,        // CRC32B/H/W/X + CRC32CB/H/W/X
	LSE,          // Large System Extensions (atomic LDADD/LDCLR/...)
	LSE2,         // single-copy-atomicity load/store
	FP16,         // half-precision FP arithmetic
	BF16,         // BFloat16
	DOT,          // SDOT/UDOT integer dot product
	PAC,          // Pointer Authentication
	BTI,          // Branch Target Indicator
	MTE,          // Memory Tagging
	SVE,          // Scalable Vector Extension
	SVE2,
	SME,          // Scalable Matrix Extension
	AMX,          // Apple Matrix Extension (undocumented A13+/M1+ coprocessor)
}

// Endianness for storing 32-bit instructions to []u8. ARM defaults to
// little-endian instruction storage on every modern platform; BE-8 mode
// stores data BE but instructions LE; BE-32 (legacy) is rare on AArch64
// and unsupported in mainstream toolchains.
Endianness :: enum u8 {
	LITTLE = 0,
	BIG    = 1,
}

Encoding_Flags :: bit_field u8 {
	branch:      bool | 1,   // unconditional change of control flow
	cond_branch: bool | 1,   // PC-relative conditional
	writes_pc:   bool | 1,   // any PC mutation (RET/BR/BLR/etc.)
	sets_flags:  bool | 1,   // updates NZCV (ADDS/SUBS/ANDS/CMP/CMN/TST/CCMP)
	is_64:       bool | 1,   // 64-bit variant (SF=1 for data-proc)
	_:           u8   | 3,
}

// What the user passes in. Most operand types describe a register class
// or a specific immediate width that the matcher cares about.
Operand_Type :: enum u8 {
	NONE,

	// ---- Integer registers ----
	W_REG,         // W0..W30 or WZR (hw=31 means ZR)
	X_REG,         // X0..X30 or XZR
	WSP_REG,       // W0..W30 or WSP (hw=31 means stack pointer)
	XSP_REG,       // X0..X30 or SP
	W_SHIFTED,     // W reg + shift type + 5-bit amount
	X_SHIFTED,     // X reg + shift type + 6-bit amount
	W_EXTENDED,    // W reg + extend + 3-bit amount
	X_EXTENDED,    // X reg + extend + 3-bit amount

	// ---- SIMD/FP scalar register views ----
	B_REG, H_REG, S_REG, D_REG, Q_REG,

	// ---- Vector register (NEON full V) ----
	V_REG,
	// NEON vector with explicit arrangement
	V_8B, V_16B, V_4H, V_8H, V_2S, V_4S, V_1D, V_2D,
	V_4H_FP16, V_8H_FP16,    // FP16 vector forms
	// Element-indexed vector (V0.B[i] / .H[i] / .S[i] / .D[i])
	V_ELEM_B, V_ELEM_H, V_ELEM_S, V_ELEM_D,

	// ---- SVE register operands ----
	Z_REG_B, Z_REG_H, Z_REG_S, Z_REG_D,
	P_REG,                                // P0..P15 (predicate)
	P_REG_MERGE, P_REG_ZERO,              // predicated execution modes
	P_REG_GOV,                            // governing predicate slot (3-bit P0..P7)

	// ---- SME register operands ----
	ZA_TILE_B, ZA_TILE_H, ZA_TILE_S, ZA_TILE_D, ZA_TILE_Q,  // ZA tile by element size
	SME_PATTERN,                          // SME pattern/tile-list mask selector
	SVE_PATTERN,                          // SVE predicate pattern (POW2, VL1.., ALL)

	// ---- SME tile-slice operand (packed immediate descriptor) ----
	//   bits  3:0 = imm offset within tile (range varies by element size)
	//   bit  4    = direction (0=H, 1=V)
	//   bits 6:5  = Ws index (Ws is W12 + this, range 0..3)
	//   bits 10:7 = tile number (relevant bits per element size)
	SME_SLICE_B, SME_SLICE_H, SME_SLICE_W, SME_SLICE_D, SME_SLICE_Q,

	// ---- Misc new operand-type aliases ----
	FCMLA_ROT,         // 2-bit complex rotation index (0/90/180/270 deg) at bits 13:12
	FCADD_ROT,         // 1-bit complex rotation index (0=90, 1=270 deg) at bit 12
	SVE_PRFOP,         // 4-bit SVE prefetch op selector at bits 3:0
	LDRAA_IMM10,       // signed 10-bit imm10 scaled by 8 (LDRAA / LDRAB)
	LSL_SHIFT_W,       // shift amount 0..31 for LSL Wd, Wn, #imm (32-bit)
	LSL_SHIFT_X,       // shift amount 0..63 for LSL Xd, Xn, #imm (64-bit)
	ROR_SHIFT,         // shift amount for ROR (alias of EXTR), goes to imms
	Z_PAIR,            // SME2 vector pair {Zn, Zn+1} — register number must be even
	Z_QUAD,            // SME2 vector quad {Zn, Zn+1, Zn+2, Zn+3} — number multiple of 4

	// ---- Immediates ----
	IMM_12,        // 12-bit unsigned (ADD/SUB imm; carries optional LSL #12 in size byte)
	IMM_16,        // 16-bit unsigned (MOVZ/MOVN/MOVK)
	IMM_8,         // 8-bit unsigned (NEON MOVI, BTI/CRC32 immediate-like)
	IMM_6,         // 6-bit unsigned (data-proc shift amount)
	IMM_5,         // 5-bit unsigned (TBZ/TBNZ bit position; FP rounding lane)
	IMM_3,         // 3-bit (shift amount for EXTEND, NZCV, system register field)
	IMM_4,         // 4-bit (HINT, DMB/DSB barrier types, NZCV flags)
	IMM_2,         // 2-bit (FP rounding mode / NEON cmode bits 14:13 etc.)
	NZCV_IMM,      // 4-bit NZCV for CCMP/CCMN immediate forms
	SYS_REG,       // 16-bit system register encoding (MSR/MRS)
	HW_SHIFT,      // 2-bit LSL hw (0/16/32/48) for MOV-immediate
	BITMASK_IMM,   // Logical immediate (bitmask-encoded N:imms:immr)
	LSE_SIZE,      // 2-bit size selector for LSE atomics (00=B 01=H 10=W 11=X)

	// ---- PC-relative ----
	REL_26,        // B / BL (signed 26-bit << 2)
	REL_19,        // B.cond / CBZ / CBNZ / LDR literal (signed 19-bit << 2)
	REL_14,        // TBZ / TBNZ (signed 14-bit << 2)
	REL_PG21,      // ADR / ADRP (signed 21-bit; ADRP scales by 4096)

	// ---- Memory ----
	MEM,           // memory operand with addressing mode

	// ---- Condition code ----
	COND,
}

// Where each operand's bits land in the 32-bit word.
Operand_Encoding :: enum u8 {
	NONE,
	IMPL,             // implicit; no bits emitted

	// ---- Register slots (5-bit hw fields) ----
	RD,               // bits 0-4
	RT,               // bits 0-4 (alias of RD used in loads)
	RN,               // bits 5-9
	RT2,              // bits 10-14
	RA,               // bits 10-14 (alias of RT2 used in MADD/MSUB)
	RM,               // bits 16-20

	// ---- Immediates ----
	IMM12,            // bits 10-21
	IMM16,            // bits 5-20
	IMM6,             // bits 10-15  (shift amount; SHAMT)
	IMM9,             // bits 12-20  (signed 9-bit; LDUR/pre/post)
	IMM_HW,           // bits 21-22  (MOVZ/MOVN/MOVK hw field; value is shift/16)
	IMM_SH12,         // bit  22     (ADD/SUB imm: LSL #12 flag)
	SHIFT_TYPE,       // bits 22-23  (LSL/LSR/ASR/ROR for shifted-register)
	EXT_OPT,          // bits 13-15  (extend type for extended-register)
	EXT_IMM3,         // bits 10-12  (extend amount)
	COND_HI,          // bits 12-15  (CSEL/CSINC/CSINV/CSNEG, FCSEL, CCMP)
	COND_LO,          // bits  0-3   (B.cond)
	NZCV_FIELD,       // bits  0-3   (CCMP/CCMN immediate NZCV)
	SYS_FIELD,        // bits 5-19   (MRS/MSR: op0/op1/CRn/CRm/op2)
	HINT_FIELD,       // bits 5-11   (HINT type)
	BARRIER_FIELD,    // bits 8-11   (DMB/DSB/ISB barrier type)

	// ---- Memory operand composites ----
	OFFSET_BASE_U12,  // [Xn, #imm * size] with imm12 scaled by data size
	OFFSET_BASE_S9,   // [Xn, #imm] signed-9 unscaled (LDUR/STUR)
	OFFSET_BASE_PRE,  // [Xn, #imm]!   signed-9 pre-index
	OFFSET_BASE_POST, // [Xn], #imm    signed-9 post-index
	OFFSET_BASE_A,    // [Xn]          no displacement (exclusives, acquire/release, LSE)
	OFFSET_REG,       // [Xn, Rm{, LSL #s}] register offset
	OFFSET_EXT,       // [Xn, Wm, SXTW|UXTW|SXTX #s]

	// ---- PC-relative ----
	BRANCH_26,        // B / BL  (operand-driven 26-bit field, scaled ×4)
	BRANCH_19,        // B.cond / CBZ / LDR literal
	BRANCH_14,        // TBZ / TBNZ
	BRANCH_PG21,      // ADR / ADRP: imm21 split as immlo[29-30] + immhi[5-23]

	// ---- TBZ/TBNZ bit position (split field b5 + b40) ----
	TBZ_BIT,          // b5 at bit 31, b40 at bits 19-23

	// ---- NEON / SIMD specific ---------------------------------------------
	VD, VN, VM,           // 5-bit V regs at bits 0-4 / 5-9 / 16-20 (alias of RD/RN/RM)
	VA,                   // R4-type 3rd source (FMLA-ish) at bits 10-14
	NEON_IMM8_FMOV,       // 8-bit imm split (abc at 18-16, defgh at 9-5)
	NEON_INDEX_H,         // 2-bit H lane index
	NEON_INDEX_S,         // S lane index
	NEON_INDEX_D,         // D lane index

	// ---- LSE atomics ------------------------------------------------------
	ATOMIC_RS,            // Rs (source / compare) at bits 16-20
	ATOMIC_RT,            // Rt (target) at bits 0-4
	ATOMIC_RN,            // Rn (address) at bits 5-9

	// ---- Bitmask logical immediate (N:imms:immr at bits 22 / 15:10 / 21:16) ----
	BITMASK_FIELD,

	// ---- Predicate (SVE) --------------------------------------------------
	PD, PN, PM,           // P-reg positions (bits 0-3 / 5-8 / 16-19 in many SVE forms)
	PG,                   // governing predicate (3-bit at bits 10-12)
	PG4,                  // governing predicate (4-bit at bits 10-13, e.g. predicate logical)
	PM3,                  // 3-bit Pm at bits 15:13 (SME outer products / a few SVE forms)

	// ---- SVE immediates ---------------------------------------------------
	SVE_IMM8,             // signed 8-bit at bits 12-5 (DUP/CPY/ADD imm)
	SVE_IMM5,             // 5-bit at bits 20-16 (INDEX imm, etc.)
	SVE_SHIFT_TSZ_IMM,    // tsz:imm3 at bits 22:16, encodes element-size + shift amount
	SVE_PATTERN,          // 5-bit pattern (POW2/VL1.../ALL) at bits 9-5 (PTRUE)

	// ---- SVE memory operands ---------------------------------------------
	SVE_OFFSET_BASE_SS,   // [Xn, Xm, LSL #s] -- scalar+scalar contiguous
	SVE_OFFSET_BASE_SI,   // [Xn, #imm, MUL VL] -- scalar+imm (signed 4-bit times VL)
	SVE_OFFSET_BASE_VEC,  // [Xn, Zm.S/D, UXTW|SXTW|LSL #s] -- scalar base + vec offset
	SVE_OFFSET_VEC_BASE,  // [Zn.S/D, #imm5] -- vector base + scalar imm

	// ---- SVE indexed lane field (FMLA Zda.T, Zn.T, Zm.T[i]) -----------
	SVE_FMLA_IDX_H,       // .H index: i3 split as (bit 22, bits 20:19), Zm@18:16
	SVE_FMLA_IDX_S,       // .S index: i2 at bits 20:19, Zm@18:16
	SVE_FMLA_IDX_D,       // .D index: i1 at bit 20, Zm@19:16

	// ---- SME ZA tile + slice fields --------------------------------------
	ZA_TILE_NUM_B,        // single-tile (ZA0.B): no field (implicit)
	ZA_TILE_NUM_H,        // tile number bit at bit 22 (ZA0.H..ZA1.H)
	ZA_TILE_NUM_S,        // tile number bits 23:22 (ZA0.S..ZA3.S)
	ZA_TILE_NUM_D,        // tile number bits 23:21 (ZA0.D..ZA7.D)
	SME_PATTERN_FIELD,    // 5-bit SME pattern (for ZERO list / SMSTART/SMSTOP)

	// ---- SME tile-slice descriptor field (LD1B/LD1H/LD1W/LD1D/LD1Q) ------
	//
	// User passes a packed immediate carrying the full slice descriptor:
	//   bits  3:0  = imm offset within tile (0..15 for .B, 0..7 for .H, ...)
	//   bit  4     = direction (0=H, 1=V)
	//   bits  6:5  = Ws index (Ws is W12+this, range 0..3)
	//   bits 10:7  = tile number (only the low bits relevant per element size)
	//
	// The encoder unpacks and places the bits per element-size layout.
	SME_SLICE_B,          // byte tile (single tile, imm 0..15)
	SME_SLICE_H,          // half tile (2 tiles, imm 0..7)
	SME_SLICE_W,          // word tile (4 tiles, imm 0..3)
	SME_SLICE_D,          // double tile (8 tiles, imm 0..1)
	SME_SLICE_Q,          // quad tile (16 tiles, imm 0)

	// ---- Misc new operand-encoding values (batch 3) ----
	ENC_FCMLA_ROT,     // 2-bit rotation at bits 13:12 (FCMLA)
	ENC_FCADD_ROT,     // 1-bit rotation at bit 12 (FCADD)
	ENC_SVE_PRFOP,     // 4-bit prefetch op at bits 3:0 (SVE PRFB/H/W/D)
	ENC_LDRAA_IMM10,   // signed 10-bit imm10 at bits 21:12, scaled by 8 (LDRAA/B)

	// ---- Batch 5 composite-packed encodings ----
	//
	// LSL_IMM Wd, Wn, #imm = UBFM Wd, Wn, #(-imm % 32), #(31-imm).
	// The single user-passed shift amount drives BOTH immr (21:16) and
	// imms (15:10). Width 32 (W) vs 64 (X) selects the modulus and N bit.
	ENC_LSL_IMM_W,     // W-form: immr = (-imm) & 31, imms = 31 - imm
	ENC_LSL_IMM_X,     // X-form: immr = (-imm) & 63, imms = 63 - imm

	// ROR_IMM Rd, Rn, #imm = EXTR Rd, Rn, Rn, #imm. The Rn register is
	// packed at BOTH the Rn slot (9:5) AND the Rm slot (20:16). The shift
	// amount goes to imms (15:10).
	ENC_DUAL_RN_RM,    // packs op.reg at both bits 9:5 AND bits 20:16
	ENC_ROR_SHIFT,     // 6-bit shift amount at bits 15:10 (imms slot)

	// SME2 multi-vector lists at the Vd/Vn/Vm slots. The user passes the
	// first register of the list; the matcher validates alignment.
	// Encoding just packs the first register's hardware number into the
	// standard slot (the implicit pair/quad is encoded by mnemonic).
	ENC_Z_PAIR_VD, ENC_Z_PAIR_VN, ENC_Z_PAIR_VM,
	ENC_Z_QUAD_VD, ENC_Z_QUAD_VN, ENC_Z_QUAD_VM,
}

Encoding :: struct #packed {
	mnemonic: Mnemonic,             // 2
	ops:      [4]Operand_Type,      // 4
	enc:      [4]Operand_Encoding,  // 4
	bits:     u32,                  // 4 -- static field pattern
	mask:     u32,                  // 4 -- which bits are static
	feature:  Feature,              // 1
	flags:    Encoding_Flags,       // 1
}
#assert(size_of(Encoding) == 20)
