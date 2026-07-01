// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ppc

import "core:rexcode/isa"

// =============================================================================
// PowerPC ENCODING FUNDAMENTALS
// =============================================================================
//
// PowerPC base instructions are 4 bytes; Power ISA 3.1 added 8-byte prefixed
// instructions (a 4-byte prefix word followed by a 4-byte suffix word). We
// model this as a variable-length ISA (length is 4 or 8). Endianness is a
// per-decode parameter: traditional BE for big-endian PPC systems, LE for
// ppc64le Linux.
//
// PowerPC documentation numbers bits MSB-first (bit 0 = MSB, bit 31 = LSB).
// This codebase, like every other arch in rexcode, uses LSB-first (bit 0 =
// LSB). To convert: LSB_bit = 31 - MSB_bit. Field positions in the comments
// below are given in BOTH conventions; the actual encoder/decoder operates on
// LSB-first bit positions.
//
// Standard fields (LSB-first / "MSB-first" name):
//
//   Primary opcode     bits 26-31    "0-5"     (6 bits, 64 buckets)
//   RT/RS/FRT/FRS/BF   bits 21-25    "6-10"    (destination / source 1)
//   RA/FRA             bits 16-20    "11-15"   (source 2 / base)
//   RB/FRB             bits 11-15    "16-20"   (source 3)
//   RC/FRC             bits  6-10    "21-25"   (source 4 / A-form mult)
//   D (signed 16)      bits  0-15    "16-31"   (D-form displacement)
//   SI/UI              bits  0-15    "16-31"   (immediate)
//   LI (B-form 24)     bits  2-25    "6-29"    (signed, scaled by 4)
//   BD (BC-form 14)    bits  2-15    "16-29"   (signed, scaled by 4)
//   AA / LK            bit  1 / 0    "30 / 31" (absolute / link flag)
//   Rc (record bit)    bit  0        "31"      (updates CR0; "." suffix)
//   OE (overflow)      bit  10       "21"      (XO-form OE: o-suffix)
//   XO (X-form 10b)    bits  1-10    "21-30"
//   XO (XO-form 9b)    bits  1-9     "22-30"
//   XO (XL-form 10b)   bits  1-10    "21-30"   (cr-based branch helpers)
//   SH (M-form)        bits 11-15    "16-20"   (shift amount)
//   MB / ME            bits  6-10/11-15 "21-25/26-30" (mask begin/end)
//   BO / BI            bits 21-25/16-20 "6-10/11-15"  (branch op / cr bit)
//
// Form-by-form summary (see Power ISA Book I §1.7):
//
//   I-form    branch  (b, bl, ba, bla)              -- primary + LI + AA + LK
//   B-form    cbranch (bc, bca, bcl, bcla)          -- + BO + BI + BD + AA + LK
//   D-form    imm     (addi, lwz, ori, ...)         -- primary + RT + RA + SI
//   DS-form   ld/std  (ld, lwa, std, ...)           -- + 14-bit DS + XO
//   DQ-form   lq/stq, prefixed                       -- + 12-bit DQ + XO
//   X-form    reg     (and, cmpw, lwzx, ...)        -- + RT + RA + RB + XO + Rc
//   XL-form   cr      (bclr, mtcrf, isync, ...)     -- + BT + BA + BB + XO + LK
//   XFX-form  spr     (mfspr, mtspr, mftb)          -- + RT + SPR + XO
//   XFL-form  fpscr   (mtfsf, mtfsfi)               -- + flags + FRB + XO + Rc
//   XO-form   ow-arith (add, subf, mulld, ...)      -- + RT + RA + RB + OE + XO + Rc
//   XS-form   sradi   (sradi, sradic)               -- + RS + RA + sh + XO + sh + Rc
//   A-form    fma     (fmadd, fmsub, fmul)          -- + FRT + FRA + FRB + FRC + XO + Rc
//   M-form    rotate  (rlwinm, rlwimi, rlwnm)       -- + RS + RA + RB/SH + MB + ME + Rc
//   MD-form   rotate  (rldicl, rldicr, ...)         -- + RS + RA + sh + MB + XO + sh + Rc
//   MDS-form  rotate  (rldcl, rldcr)                -- + RS + RA + RB + MB + XO + Rc
//   VA-form   altivec (vmsumshs, vmaddfp, ...)      -- + VRT + VRA + VRB + VRC + XO
//   VC-form   altivec (vcmpequb, vcmpgefp, ...)     -- + VRT + VRA + VRB + Rc + XO
//   VX-form   altivec (vand, vaddubm, ...)          -- + VRT + VRA + VRB + XO
//   XX1-form  vsx ld/st (lxvd2x, ...)               -- + XT + RA + RB + XO + TX
//   XX2-form  vsx 2-op  (xscvspdpn, ...)            -- + XT + XB + XO + BX + TX
//   XX3-form  vsx 3-op  (xsmaddasp, ...)            -- + XT + XA + XB + XO + AX + BX + TX
//   XX4-form  vsx 4-op  (xxsel)                     -- + XT + XA + XB + XC + XO + CX + AX + BX + TX
//   MLS / MMIRR / 8RR / 8LS  prefixed (ISA 3.1)     -- 8-byte (4 prefix + 4 suffix)

Error            :: isa.Error
Error_Code       :: isa.Error_Code
Label_Definition :: isa.Label_Definition
LABEL_UNDEFINED  :: isa.LABEL_UNDEFINED
Label_Map        :: isa.Label_Map

// Execution mode. PPC32 chips ignore the high half of 64-bit GPRs and lack
// 64-bit instructions (ld/std/mulld/rldicl/etc.). PPC64 implies PPC32.
Mode :: enum u8 {
	PPC32 = 0,
	PPC64 = 1,
}

// Instruction storage endianness. Power was big-endian historically; ppc64le
// (POWER8+ Linux) stores instructions LE.
Endianness :: enum u8 {
	BIG    = 0,
	LITTLE = 1,
}

// Architectural extension this entry needs. Used for filtering and decode
// disambiguation (some entries collide unless the right feature is enabled).
Feature :: enum u8 {
	BASE,         // POWER ISA Book I/II base 32-bit
	P64,          // 64-bit only ops (ld/std/mulld/rldicl-family)
	FP,           // floating-point unit (Book I §4 FPU)
	FP_R,         // FP rounding-mode-related (FRSP, FCTID, ...)
	ALTIVEC,      // AltiVec / VMX (vector unit, 128-bit V regs)
	VSX,          // Vector-Scalar Extension (POWER7; 64 vs regs)
	VSX_P9,       // VSX additions in POWER9 (ISA 3.0)
	VSX_P10,      // VSX additions in POWER10 (ISA 3.1)
	POWER8,       // POWER8 additions (ISA 2.07)
	POWER9,       // POWER9 additions (ISA 3.0)
	POWER10,      // POWER10 additions (ISA 3.1 incl prefixed ops)
	DFP,          // Decimal Floating-Point
	HTM,          // Hardware Transactional Memory
	CACHE,        // cache-management (dcb*, icbi, ...)
	HV,           // hypervisor-only
	SUPV,         // supervisor (kernel) — mfmsr/mtmsr/rfi/...
	BOOKE,        // Book E embedded variant (rare in modern table; keep slot)
	SPE,          // Signal-Processing Engine (Freescale e500/e500v2 — evX/efs/efd/evmX)
	PS,           // Paired Singles (Gekko/Broadway — GameCube/Wii)
	VMX128,       // VMX128 (Xenon — Xbox 360 vector ext with 128 VR registers)
}

Encoding_Flags :: bit_field u16 {
	branch:      bool | 1,  // unconditional control transfer (b, bl, blr)
	cond_branch: bool | 1,  // conditional branch (bc, bclr, bcctr)
	writes_lr:   bool | 1,  // LK=1 — link register updated
	sets_cr0:    bool | 1,  // Rc=1 — "." suffix; CR0 written from result
	sets_cr1:    bool | 1,  // FP Rc=1 — "." suffix; CR1 written from FPSCR
	abs_branch:  bool | 1,  // AA=1 — absolute branch target (rare)
	has_oe:      bool | 1,  // OE=1 — XO-form overflow flag ("o" suffix)
	prefixed:    bool | 1,  // 8-byte prefixed instruction (Power ISA 3.1)
	vle:         bool | 1,  // PowerPC VLE (Variable Length Encoding) entry
	vle_short:   bool | 1,  // VLE 16-bit short instruction (se_*)
	_:           u16  | 6,
}

// What the user passes in (high-level operand type).
Operand_Type :: enum u8 {
	NONE,

	// ---- Integer registers ----
	GPR,           // r0..r31
	GPR_OR_ZERO,   // r0..r31 where r0 is interpreted as literal 0 (RA in
				   // certain addressing forms — addi/lwz/etc.)

	// ---- Floating-point ----
	FPR,           // f0..f31 (scalar FP)

	// ---- AltiVec vector ----
	VR,            // v0..v31 (128-bit AltiVec)

	// ---- VSX scalar / vector (64 regs) ----
	VSR,           // vs0..vs63 (unified — vs0..31 alias FPRs, vs32..63 alias VRs)

	// ---- VMX128 (Xbox 360 Xenon — 128 vector regs) ----
	VR128,         // vr0..vr127

	// ---- Condition register ----
	CR_FIELD,      // cr0..cr7 (3-bit field selector)
	CR_BIT,        // single bit within CR (5-bit; for mt/mfcr forms)

	// ---- Special-purpose register ----
	SPR,           // 10-bit SPR number (split as two 5-bit halves on wire)

	// ---- Immediates ----
	IMM,           // generic — width determined by Operand_Encoding
	SIMM,          // signed immediate (D-form, addi-style)
	UIMM,          // unsigned immediate (ori, andi, ...)

	// ---- PC-relative (label-resolving) ----
	REL,           // signed PC-relative branch displacement

	// ---- Memory ----
	MEM,           // memory operand (D-form, DS-form, X-form indexed)

	// ---- Branch helpers ----
	BO,            // 5-bit branch operation (bc family)
	BH,            // 2-bit branch hint (bcctr, bclr)
}

// Bit-level positions on the 32-bit instruction word (LSB-first).
Operand_Encoding :: enum u8 {
	NONE,
	IMPL,

	// ---- Register slot fields ----
	RT,            // bits 21-25  (destination)
	RA,            // bits 16-20  (source 2 / base / Rd in MD-form)
	RB,            // bits 11-15  (source 3 / Rb)
	RC,            // bits  6-10  (A-form 4th source)
	RS,            // bits 21-25  (alias of RT used in store/X-form)

	// ---- Floating-point ----
	FRT,           // bits 21-25
	FRA,           // bits 16-20
	FRB,           // bits 11-15
	FRC,           // bits  6-10

	// ---- AltiVec vector ----
	VRT,           // bits 21-25
	VRA,           // bits 16-20
	VRB,           // bits 11-15
	VRC,           // bits  6-10

	// ---- VSX (split 5+1 bit register fields) ----
	XT,            // VSX dest:  bits 21-25 are XT[4:0], bit  0 is XT[5] (TX)
	XA,            // VSX src1:  bits 16-20 are XA[4:0], bit  2 is XA[5] (AX)
	XB,            // VSX src2:  bits 11-15 are XB[4:0], bit  1 is XB[5] (BX)
	XC,            // VSX 4-op:  bits  6-10 are XC[4:0], bit  3 is XC[5] (CX)

	// ---- VMX128 (Xbox 360 Xenon — split 7-bit register fields) ----
	// VMX128 extends the AltiVec 32-register file to 128 registers, encoding
	// the extra 2 bits in scattered positions per the VMX128 ISA leak. The
	// exact bit placement varies by form — these are the most common splits
	// used in xenia's disassembler (vaddfp128 / vsubfp128 / vor128 etc.).
	VRT128,        // 7-bit: low 5 at bits 21-25, high 2 at bits 5-6 (.h[1:0])
	VRA128,        // 7-bit: low 5 at bits 16-20, high 1 at bit  6, plus bit 3
	VRB128,        // 7-bit: low 5 at bits 11-15, high 2 at bits 2-3
	VRC128,        // 7-bit: low 3 at bits  6-8,  high 2 at bits 9-10

	// ---- Condition register fields ----
	BF,            // bits 23-25  (CR field, 3-bit, for cmp etc.)
	BFA,           // bits 18-20  (source CR field, 3-bit)
	BT,            // bits 21-25  (CR bit destination, 5-bit; XL-form)
	BA,            // bits 16-20  (CR bit source 1, 5-bit)
	BB,            // bits 11-15  (CR bit source 2, 5-bit)
	BO_FIELD,      // bits 21-25  (branch op, 5-bit)
	BI_FIELD,      // bits 16-20  (CR bit tested, 5-bit)
	BH_FIELD,      // bits 11-12  (branch hint, 2-bit; bclr/bcctr)

	// ---- SPR (10-bit split into two 5-bit halves at 11-15 and 16-20) ----
	SPR_FIELD,     // SPR encoded with halves swapped per PPC convention

	// ---- Immediates (positional) ----
	D16,           // bits  0-15  (D-form, signed 16)
	UI16,          // bits  0-15  (D-form, unsigned 16: ori/andi/oris/andis)
	DS14,          // bits  2-15  (DS-form, signed; scaled by 4)
	DQ12,          // bits  4-15  (DQ-form, signed; scaled by 16)
	SH5,           // bits 11-15  (M-form shift amount)
	SH6,           // bits 11-15 + bit 1 (MD/MDS-form shift, 6-bit split)
	MB5,           // bits  6-10  (M-form mask begin)
	ME5,           // bits  1-5   (M-form mask end)
	MB6,           // bits  5-10  (MD/MDS-form 6-bit mask begin/end)
	SIMM_5,        // bits 16-20  (AltiVec UIM5 / vspltisb-style signed)
	UIMM_5,        // bits 16-20  (AltiVec UIM5 unsigned)
	UIMM_4,        // bits 16-19  (AltiVec UIM4)
	UIMM_2,        // bits 16-17  (AltiVec UIM2)
	FXM,           // bits 12-19  (mtcrf field mask, 8 bits)
	L_FIELD,       // bit  21     (cmp L bit: 0=32-bit, 1=64-bit)
	TO_FIELD,      // bits 21-25  (tw/twi/td/tdi trap condition)
	NB_FIELD,      // bits 11-15  (lswi/stswi byte count)
	SR_FIELD,      // bits 16-19  (mfsr/mtsr segment register)
	CRM,           // bits 12-19  (mfcr/mtcr field mask)
	DCMX,          // bits 16-22  (VSX DCMX immediate)

	// ---- PC-relative ----
	BRANCH_LI,     // bits  2-25  (I-form, 24-bit signed << 2)
	BRANCH_BD,     // bits  2-15  (B-form, 14-bit signed << 2)
	AA_FLAG,       // bit  1      (absolute branch flag, 1 bit)
	LK_FLAG,       // bit  0      (link bit, 1 bit)
	RC_FLAG,       // bit  0      (record bit, 1 bit) — co-located with LK
	OE_FLAG,       // bit 10      (overflow-enable XO-form)

	// ---- Memory addressing composites ----
	OFFSET_BASE_D,    // [RA, #D16]        D-form
	OFFSET_BASE_DS,   // [RA, #DS14*4]     DS-form
	OFFSET_BASE_DQ,   // [RA, #DQ12*16]    DQ-form
	OFFSET_BASE_X,    // [RA, RB]          X-form indexed
	OFFSET_VSX_X,     // [RA, RB] for VSX  (uses RB encoding at 11-15)

	// ---- Prefixed (8-byte) instruction immediates ----
	// The Power ISA 3.1 prefix carries an additional 18 bits of immediate
	// (R: bit 20 + IMM18: bits 0-17 of the prefix word) appended above the
	// suffix's 16-bit field.
	PFX_IMM34_SI,     // signed 34-bit immediate, prefix R=0 (PLI, PADDI)
	PFX_IMM34_REL,    // 34-bit pc-relative when prefix R=1
	PFX_OFFSET_BASE,  // prefixed memory operand: 34-bit signed offset + RA

	// ---- Miscellaneous fields ----
	EH_FIELD,        // bit 0 of lwarx/ldarx: external hint
	L_LFIELD,        // bit 10 of mtmsr / sync (variant selector)
	LEV_FIELD,       // bits 20-26 of sc (level)
	PS_FIELD,        // bit 15 of mtmsr (problem state)
	SXL_FIELD,       // bit 15 of rfi (rfi64 variant)
}

// One instruction-encoding form within a mnemonic.
//
// For prefixed (8-byte) Power ISA 3.1 instructions, `bits` holds the SUFFIX
// word and `mask` covers only the suffix's fixed bits. The PREFIX word is
// looked up in `PREFIX_BITS_TABLE[mnemonic]` (see `encoding_table.odin`).
// `flags.prefixed=true` is the signal to consult that table.
Encoding :: struct #packed {
	mnemonic: Mnemonic,             // 2
	ops:      [4]Operand_Type,      // 4
	enc:      [4]Operand_Encoding,  // 4
	bits:     u32,                  // 4 -- static field pattern
	mask:     u32,                  // 4 -- which bits are static
	feature:  Feature,              // 1
	mode:     Mode,                 // 1
	flags:    Encoding_Flags,       // 2
}
#assert(size_of(Encoding) == 22)

// Per-instruction length (4 or 8). For non-prefixed instructions returns 4.
inst_size_from_bits :: #force_inline proc "contextless" (bits: u32) -> u8 {
	// Prefixed instructions have primary opcode 1 (bits 26..31 of the
	// *prefix* word) — i.e. high 6 bits of `bits` are 0b000001 = 0x04 in
	// the top byte. When the encoder packs prefixed words it places the
	// prefix in the high 32 bits, so just looking at the top of the u32
	// suffices for this helper at table-build time.
	if (bits >> 26) == 0x01 { return 8 }
	return 4
}
