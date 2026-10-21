// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm32

import "core:rexcode/isa"

// =============================================================================
// AArch32 ENCODING FUNDAMENTALS
// =============================================================================
//
// AArch32 has two distinct instruction sets:
//
//   * A32 (also called "ARM"): fixed 32-bit instructions, condition code in
//     bits 31-28 unless the top nibble is 1111 (unconditional). Stored LE.
//
//   * T32 (Thumb / Thumb-2): variable-length, 16-bit or 32-bit. The first
//     halfword's top 5 bits (`bits[15:11]`) determine length:
//       - 11101, 11110, 11111 -> 32-bit Thumb (Thumb-2)
//       - everything else     -> 16-bit Thumb-1
//     The 32-bit form is stored as two 16-bit halfwords in memory order
//     (low halfword first). We pack this into u32 `bits` as
//     `low_halfword | (high_halfword << 16)`.
//
// Each `Encoding` entry carries a `Mode` tag selecting A32 vs T32 so the
// matcher / encoder can dispatch correctly. Some mnemonics have entries in
// both modes; the encoder picks based on the active Mode of the encode call.
//
// Field positions (A32, bit 31 down to 0):
//
//   cond     31-28   condition code (NV=1111 means unconditional class)
//   I        25      data-proc: immediate vs register operand2
//   S        20      sets flags
//   Rn       19-16   first source register
//   Rd       15-12   destination
//   Rs       11-8    register-shifted-register: shift amount in Rs
//   Rm       3-0     second source
//   shift_imm 11-7   immediate shift amount
//   shift_t  6-5     shift type (LSL/LSR/ASR/ROR; RRX as ROR #0)
//   rotate   11-8    rotate for modified-immediate
//   imm8     7-0     8-bit immediate value
//   imm12    11-0    12-bit immediate (LDR/STR offset)
//   imm24    23-0    24-bit signed branch target (B/BL/SVC)
//
// Field positions (Thumb-2 32-bit, bit 31 down to 0):
//
//   Two halfwords stored in memory order; we encode as
//     bits = halfword_low | (halfword_high << 16)
//   so bit  15 of `bits` is bit 15 of the FIRST halfword, and
//      bit 31 of `bits` is bit 15 of the SECOND halfword.
//
// All operand-driven fields live in the zeros of `mask`; the encoder ORs
// them in. The matcher tests `(word & mask) == bits`.

Error            :: isa.Error
Error_Code       :: isa.Error_Code
Label_Definition :: isa.Label_Definition
Label_Offset     :: isa.Label_Offset
Label_Names      :: isa.Label_Names
LABEL_UNDEFINED  :: isa.LABEL_UNDEFINED
Label_Map        :: isa.Label_Map

// ---- Mode -------------------------------------------------------------------

Mode :: enum u8 {
	A32 = 0,            // 32-bit ARM
	T32 = 1,            // Thumb (16-bit or 32-bit T2)
}

// ---- Profile ----------------------------------------------------------------

// Which architecture profile a Thumb stream was written for. The application
// (and real-time) profile and the microcontroller profile disagree about part
// of the 32-bit Thumb encoding space: M-profile Vector Extension instructions
// sit in words that are Advanced SIMD on an A-profile core, and the ARMv8.1-M
// additions (conditional select, the low-overhead loops) reuse should-be-zero
// bits of older instructions. The decoder can only pick one reading.
Profile :: enum u8 {
	A_PROFILE,    // A and R profiles: Advanced SIMD, crypto, banked registers
	M_PROFILE,    // M profile: MVE, v8-M security, v8.1-M loops and selects
}

// The coprocessors, of 0 to 7, a v8-M core gives to the Custom Datapath
// Extension. Their space then holds CDE's instructions instead of the generic
// coprocessor ones. Which coprocessors a core configures that way is nowhere
// in the code, so a caller decoding for one has to say.
CDE_Coprocessors :: bit_set[0 ..= 7; u8]

// Whether a form belongs to a profile. Most do to both.
@(require_results)
feature_in_profile :: #force_inline proc "contextless" (feature: Feature, profile: Profile) -> bool {
	switch feature {
	case .BASE, .THUMB, .V5T, .V5TE:
		return true
	case .V5TEJ:
		return profile == .A_PROFILE
	case .V6, .V6K, .V6T2, .V7:
		return true
	case .V7VE:
		return profile == .A_PROFILE
	case .V8, .DIV, .VFPV2, .VFPV3, .VFPV4, .HALF_FP:
		return true
	case .NEON, .NEON_HALF_FP, .CRYPTO:
		return profile == .A_PROFILE
	case .CRC32:
		return true
	case .DOT, .BF16, .FCMA, .FHM:
		return profile == .A_PROFILE
	case .V8M, .V8M_SE, .V81M, .MVE_INT, .MVE_FP, .CDE:
		return profile == .M_PROFILE
	}
	return false
}

// VFP and NEON instructions have a regular A32<->T32 transformation:
//   A32 form: top 4 bits of the 32-bit word are `cond` (1110=AL/uncond, 1111=NV).
//   T32 form: top 4 bits are 1110 1111 / 1110 1110 (Thumb-2 32-bit class). The
//   only difference between A32 and T32 NEON/VFP encodings is bit 28:
//
//     A32 NEON unconditional class: top byte = 0xF2 (U=0) or 0xF3 (U=1)
//     T32 NEON unconditional class: top byte = 0xEF (U=0) or 0xFF (U=1)
//
//     A32 VFP: cond field at bits 31:28 (operand-driven)
//     T32 VFP: bits 31:28 are fixed 1110 1110 = 0xEE
//
// Rather than duplicating every NEON/VFP entry with a Mode=.T32 variant, the
// encoder/decoder handle the mode-dispatch via this helper: in T32 mode, the
// matcher clears bit 28 of the input word before lookup, and the encoder
// clears bit 28 of `bits` before emitting. The single set of A32-mode entries
// in ENCODING_TABLE thus covers both ISAs.

is_neon_or_vfp_opcode :: #force_inline proc "contextless" (bits: u32) -> bool {
	// NEON unconditional class: bits[27:25] = 100 with cond=1111
	// VFP coprocessor 10/11: bits[27:24] = 1110 (coproc class) AND
	//   bits[11:8] in {1010, 1011}
	top := (bits >> 24) & 0xFF
	if top == 0xF2 || top == 0xF3 { return true }  // NEON A32
	// VFP coprocessor classes — bits[27:24] = 1110 (= 0xE_) and coproc 10/11
	if (top & 0xF0) == 0xE0 {
		cp := (bits >> 8) & 0xF
		if cp == 0xA || cp == 0xB { return true }
	}
	return false
}

// Advanced SIMD data processing in Thumb: 111U 1111. The U bit sits at 24 in
// A32 and at 28 here, and an operand field that reaches it (the `a` of a
// modified immediate) has to be read and written there.
@(require_results)
is_thumb_simd :: #force_inline proc "contextless" (bits: u32) -> bool {
	return bits & 0xEF00_0000 == 0xEF00_0000
}

// The A32 layout of a Thumb Advanced SIMD word, for the operand unpackers.
@(require_results)
thumb_simd_as_a32 :: #force_inline proc "contextless" (word: u32) -> u32 {
	return (word & 0x00FF_FFFF) | 0xF200_0000 | ((word >> 28) & 1) << 24
}

// Transform an A32 NEON/VFP encoding word to its T32 equivalent (or vice
// versa) by toggling bit 28.
a32_t32_neon_swap :: #force_inline proc "contextless" (bits: u32) -> u32 {
	return bits ~ (1 << 28)
}

// ---- Architectural feature flag --------------------------------------------

Feature :: enum u8 {
	BASE,           // ARMv4 base ISA (works on every ARM core including ARM7TDMI / GBA)
	THUMB,          // Thumb-1 (ARMv4T+)
	V5T,            // ARMv5T additions (BLX, CLZ, BKPT)
	V5TE,           // ARMv5TE DSP extensions (SMLAxy / SMULxy / etc.)
	V5TEJ,          // ARMv5TEJ (BXJ; Jazelle support)
	V6,             // ARMv6 SIMD-on-GPR + REV/SXTB/etc.
	V6K,            // ARMv6K (CLREX, multiprocessing hints)
	V6T2,           // ARMv6T2 (Thumb-2, MOVW/MOVT, bitfield)
	V7,             // ARMv7-A/R base (DMB/DSB/ISB, LDREX/STREX full set)
	V7VE,           // ARMv7-A Virtualisation Extensions (HVC, ERET)
	V8,             // ARMv8-A AArch32 (HLT, SEVL, MVN nzcvqg)
	DIV,            // SDIV/UDIV (ARMv7-A optional, ARMv7-R/M mandatory)
	VFPV2,          // VFP version 2 (double-precision FP)
	VFPV3,          // VFP version 3 (D32, VCVTB/T half-prec)
	VFPV4,          // VFP version 4 (VFMA family)
	HALF_FP,        // FP16 storage support
	NEON,           // Advanced SIMD
	NEON_HALF_FP,   // FP16 NEON arithmetic
	CRYPTO,         // ARMv8 crypto (AES + SHA1 + SHA2)
	CRC32,          // ARMv8 CRC32B/H/W + CRC32CB/H/W
	DOT,            // ARMv8.2 dot product (VSDOT/VUDOT)
	BF16,           // ARMv8.6 BFloat16
	FCMA,           // ARMv8.3 complex number (VCMLA/VCADD)
	FHM,            // ARMv8.2 FP16 multiply-acc-long

	// ---- M-profile ARMv8-M extensions ----
	V8M,            // ARMv8-M baseline (Cortex-M23, M33, M55, M85)
	V8M_SE,         // ARMv8-M Security Extensions (TT/TTT/TTA/TTAT)
	V81M,           // ARMv8.1-M mainline (low-overhead loops, MVE)
	MVE_INT,        // M-profile Vector Extension (Helium) integer (Cortex-M55+)
	MVE_FP,         // M-profile Vector Extension floating-point
	CDE,            // Custom Datapath Extension (Cortex-M33+)
}

// ---- Encoding flags --------------------------------------------------------

Encoding_Flags :: bit_field u16 {
	sets_flags:  bool | 1,   // sets APSR.NZCV (S=1)
	cond_in_28:  bool | 1,   // INFORMATIONAL. A32 cond field at bits 31:28 is
							 // operand-supplied. The encoder/decoder don't rely
							 // on this flag — they use mask-based detection:
							 // (mask >> 28) == 0 ⇒ cond is variable. Many
							 // table entries leave this `false` to match the
							 // bit_field default; the structural mask test is
							 // the source of truth.
	branch:      bool | 1,
	cond_branch: bool | 1,
	writes_pc:   bool | 1,
	thumb32:     bool | 1,   // T32 32-bit form (vs 16-bit). Ignored for A32.
	deprecated:  bool | 1,
	// VSEL and friends are unconditional words that still name a condition,
	// in bits 21:20 rather than 31:28, and spell it on the mnemonic.
	cond_in_21:  bool | 1,
	// Most 16-bit Thumb data processing sets the flags outside an IT block
	// and leaves them alone inside one -- the same bits are `adds` in one
	// place and `add` in the other. Whether the S is there depends on where
	// the instruction sits, not on the word.
	flags_outside_it: bool | 1,
	// A Thumb conditional branch is the one Thumb instruction that carries its
	// own condition: bits 11:8 of the 16-bit form, 25:22 of the 32-bit one.
	// Everything else takes its condition from an IT block.
	thumb_condition:  bool | 1,
	// Decode tries this form before any more specific one that also matches.
	// The literal loads need it: Rn = PC makes a load PC-relative whatever
	// the rest of the word says, but their masks are no more specific than
	// the immediate and register forms they displace.
	preferred:        bool | 1,
	// Not part of the M profile, though its feature is: HLT, SETEND, SETPAN,
	// SEVL, the 32-bit CPS, SRS and RFE, SMC, and the generic coprocessor
	// instructions, whose coprocessor space M-profile cores give to CDE.
	a_profile_only:   bool | 1,
	// An assembler's spelling of another form's word -- `vcle d0, d1, d2` is
	// `vcge d0, d2, d1`. The encoder takes it; the decoder gives the other.
	encode_only:      bool | 1,
	_:                u8   | 3,
}

// ---- Operand types ----------------------------------------------------------
//
// What the user passes in. Most operand types describe a register class plus
// an addressing/shape modifier; the matcher uses this to dispatch.

Operand_Type :: enum u8 {
	NONE,

	// ---- Integer registers ----
	GPR,                  // R0..R15 (or SP/LR/PC by alias)
	GPR_NOPC,             // R0..R14 (PC disallowed by spec)
	GPR_NOSP,             // R0..R14 except SP
	GPR_LOW,              // R0..R7 (Thumb-1 low-reg encoding)
	GPR_SHIFTED,          // Rm + shift type + immediate shift amount
	GPR_RSR,              // Rm + shift type + Rs register-shifted-register
	GPR_LIST,             // Register list (LDM/STM/PUSH/POP); bitmask 16 GPRs
	GPR_ZR,               // R0..R14, or ZR where the field holds 1111 (v8.1-M CSEL)

	// ---- Floating point / SIMD ----
	SPR,                  // S0..S31
	DPR,                  // D0..D31
	QPR,                  // Q0..Q15
	SPR_LIST,             // VLDM/VSTM/VPUSH/VPOP list of S regs
	DPR_LIST,             // VLDM/VSTM list of D regs
	SPR_ELEM,             // S<n> with no extra shape info
	DPR_ELEM,             // D<n>[lane] for scalar-FP-in-SIMD operations
	QPR_ELEM,             // Q<n>[lane]

	// ---- Immediates ----
	IMM,                  // generic immediate (sized per encoding)
	IMM_MOD,              // A32 modified-immediate (8-bit + 4-bit rotate)
	IMM_T32_MOD,          // Thumb-2 modified-immediate (similar but distinct encoding)
	IMM16_LO_HI,          // MOVW/MOVT 16-bit immediate split into imm4 + imm12
	IMM12,                // unsigned 12-bit (LDR/STR offset)
	IMM5,                 // 5-bit (shift_imm, BFC/BFI lsb)
	IMM5_W,               // 5-bit field width (BFC/BFI/SBFX/UBFX)
	IMM4,                 // 4-bit (rotate, ext rotation amount)
	IMM4_SAT,             // SSAT/USAT saturation amount
	IMM8,                 // 8-bit (NEON VMOV, ConstantPool index, etc.)
	IMM3,                 // 3-bit Thumb register-encoded immediate
	IMM_HINT,             // hint number (DBG, HINT)
	IMM_BARRIER,          // DMB/DSB/ISB barrier type
	IMM_ENDIAN,           // 1-bit BE/LE for SETEND
	IMM_IFLAGS,           // CPS iflags + mode
	IMM_BANKED,           // banked register selector (MSR/MRS banked)
	IMM_SYSM,             // 7-bit SYSm field
	IMM_COPROC,           // coprocessor number 0..15
	IMM_COPROC_OP,        // coprocessor opcode (CDP / MCR / MRC: opcode1/2 fields)
	NEON_IMM,             // NEON modified-immediate (with cmode + abcdefgh)

	// ---- PC-relative ----
	REL24,                // A32 B / BL (signed 24-bit << 2)
	REL24_T32,            // T32 B unconditional (J1/J2 + imm10 + imm11)
	REL20,                // T32 B<cond> (signed 20-bit equivalent)
	REL11,                // T16 B<cond>
	REL8,                 // T16 conditional branch (signed 8-bit)
	REL_LDR_LITERAL,      // PC-relative literal load offset
	REL_BF,               // ARMv8.1-M Branch Future label (bf-point / branch target)

	// ---- Condition code ----
	COND,                 // 4-bit cond field (for IT block / B<cond> / etc.)

	// ---- Memory ----
	MEM,                  // memory operand; addressing mode in operand payload

	// ---- Coprocessor ----
	COPROC_REG,           // CRn / CRm (coprocessor register identifier)
	COPROC_NUM,           // pX (coprocessor number 0..15)

	// ---- Misc ----
	PSR_FIELD,            // APSR/CPSR field selector (_nzcvq, _g, _nzcvqg, _s, _x, _c)

	// ---- ARMv8-M / MVE / CDE operand classes ----
	VPR,                  // VPR predicate register (single; bit-wise predicate state)
	QPR_MVE,              // MVE Q-register (Q0..Q7; 3-bit index; bit 22 = 0 always)
	QPR_MVE_LIST,         // MVE multi-Q list (e.g. VLD2x2 etc.)
	MVE_VPT_MASK,         // VPT block mask (4-bit then/else pattern)
	MVE_VCTP_SIZE,        // 2-bit element-size selector for VCTP (B/H/W/D)
	MVE_LOOP_TGT,         // low-overhead-loop branch target (WLS/LE/DLS imm)
}

// ---- Operand encodings (where the bits land) -------------------------------

Operand_Encoding :: enum u8 {
	NONE,
	IMPL,                  // implicit operand (no bits emitted)

	// ---- A32 GPR slots ----
	RD,                    // bits 15-12 (data-proc dest)
	RN_A32,                // bits 19-16
	RM_A32,                // bits 3-0
	RS_A32,                // bits 11-8  (register-shifted-register shift amount)
	RT_A32,                // bits 15-12 (load/store target = RD slot)
	RT2_A32,               // bits 15-12 + 1 (LDRD/STRD even-odd pair, implicit)
	RDLO_A32,              // bits 15-12 (UMULL/SMULL low result)
	RDHI_A32,              // bits 19-16 (UMULL/SMULL high result)

	// ---- T32 (Thumb-2 32-bit) slots ----
	RD_T32,                // bits 11-8 of second halfword (high half of u32)
	RN_T32,                // bits 19-16 of first halfword (low 4 bits of byte at offset 2)
	RM_T32,                // bits 3-0 of second halfword
	RT_T32,                // load/store target
	RT2_T32,               // second load/store register
	RA_T32,                // accumulator (MLA/MLS)

	// ---- T16 slots ----
	RD_T16_LO,             // bits 2-0 of halfword (low 3 bits)
	RM_T16_LO,             // bits 5-3
	RN_T16_LO,             // bits 5-3 (alias)
	RD_T16_HI,             // hi-reg form: rd[3] at bit 7, rd[2:0] at bits 2-0
	RM_T16_HI,             // rm at bits 6-3 (4-bit hi-reg)
	RM_T16_8_6,            // bits 8-6: the third register of ADD/SUB, the index of [Rn, Rm]
	RD_T16_10_8,           // bits 10-8: Rd/Rt/Rn of the forms with an 8-bit immediate below
	// MULS names its destination twice -- `muls r0, r1, r0` -- and one field
	// holds it. The second mention encodes nothing and decodes as the first.
	RD_T16_LO_AGAIN,
	RD_T16_HI_AGAIN,       // the same, for `add r0, sp, r0`

	// ---- T16 immediates ----
	IMM3_T16,              // bits 8-6 (ADD/SUB Rd, Rn, #imm3)
	IMM8_T16,              // bits 7-0
	IMM5_T16_SHIFT,        // bits 10-6, LSL #0..31
	IMM5_T16_SHIFT_32,     // bits 10-6, LSR/ASR #1..32: a zero field is 32
	IMM7_T16_SCALED4,      // bits 6-0 counting words (ADD/SUB SP, SP, #imm)
	IMM8_T16_SCALED4,      // bits 7-0 counting words (ADD Rd, SP, #imm)
	IMM6_T16,              // bits 5-0 (HLT)
	IMM4_T16_HINT,         // bits 7-4 (HINT #imm, the hints without a name)
	IT_FIRSTCOND,          // bits 7-4: the condition an IT block starts with
	IT_MASK_FIELD,         // bits 3-0: the then/else pattern and the block's length
	SETEND_ENDIAN_T16,     // LE or BE, by bit 3
	SETPAN_IMM_T16,        // bit 3
	CPS_IFLAGS_T16,        // A, I and F at bits 2-0

	// ---- T16 memory, lists and PC-relative ----
	MEM_T16_IMM5_W,        // [Rn, #imm5 * 4]: Rn at 5-3, imm5 at 10-6
	MEM_T16_IMM5_B,        // [Rn, #imm5]
	MEM_T16_IMM5_H,        // [Rn, #imm5 * 2]
	MEM_T16_REG,           // [Rn, Rm]: Rn at 5-3, Rm at 8-6
	MEM_T16_SP_IMM8,       // [SP, #imm8 * 4]
	MEM_T16_LITERAL,       // PC-relative load: Align(PC, 4) + imm8 * 4
	REL_T16_ADR,           // ADR: Align(PC, 4) + imm8 * 4
	T16_REG_LIST,          // bits 7-0: R0..R7
	T16_REG_LIST_LR,       // bits 7-0, and LR by bit 8 (PUSH)
	T16_REG_LIST_PC,       // bits 7-0, and PC by bit 8 (POP)

	// ---- T32 (packed first_halfword << 16 | second) ----
	RM_T32_ROTATED,        // Rm at 3-0, rotated right by 8 * bits 5-4 (the extends)
	RM_A32_ROTATED,        // the same in A32, with the rotation at bits 11-10
	RM_T32_TWICE,          // Rm at 3-0 and again at 19-16 (REV, RBIT, CLZ)
	RN_T32_SAT,            // SSAT/USAT's Rn at 19-16, LSL or ASR (bit 21) by imm3:imm2
	T32_IMM12,             // i:imm3:imm8, as is (ADDW, SUBW)
	T32_IMM16,             // imm4:i:imm3:imm8 (MOVW, MOVT)
	T32_IMM_SHIFT,         // imm3:imm2, LSL/ROR #0..31
	T32_IMM_SHIFT_32,      // imm3:imm2, LSR/ASR #1..32: a zero field is 32
	SAT16_IMM4_T32,        // SSAT16's width, bits 3-0, less one
	SAT16_IMM4_U_T32,      // USAT16's width, bits 3-0
	BFI_MSB_T32,           // BFI/BFC's top bit, bits 4-0
	BFX_WIDTH_T32,         // SBFX/UBFX's width, bits 4-0, less one
	IMM4_IMM12,            // imm4 at 19-16 and imm12 at 11-0 (A32 MOVW/MOVT, Thumb HVC/UDF.W)
	IMM12_IMM4,            // imm12 at 19-8 and imm4 at 3-0 (A32 BKPT, HVC, UDF, HLT)
	CPS_IFLAGS_A32,        // A, I and F at bits 8-6
	SETPAN_IMM_A32,        // bit 9
	RM_PAIR_NEXT,          // the register after the one at 3-0: no bits (STREXD's Rt2)
	BRANCH_BLX_A32,        // BLX to Thumb: imm24 words and H, a halfword, at bit 24
	NEON_VEXT_IMM4,        // VEXT's byte index, bits 11-8
	A32_REG_LIST_USER,     // an LDM/STM list written with `^`: the user registers, or exception return
	MEM_REG_SHIFTED,       // [Rn, +/-Rm{, shift}]: Rm 3-0, shift imm5 at 11-7 and type 6-5, U 23
	MEM_REG_SHIFTED_PRE,   // [Rn, +/-Rm{, shift}]!
	MEM_REG_SHIFTED_POST,  // [Rn], +/-Rm{, shift}
	MEM_REG_PRE,           // [Rn, +/-Rm]! (halfword and dual: no shift)
	MEM_REG_POST,          // [Rn], +/-Rm
	T32_IMM4_SMC,          // bits 19-16
	T32_IMM8,              // bits 7-0 (SUBS PC, LR)
	CPS_IFLAGS_T32,        // A, I and F at bits 7-5
	CPS_MODE_T32,          // bits 4-0
	MRS_SPEC_REG_T32,      // APSR or SPSR, by bit 20
	MSR_FIELDS_T32,        // APSR/CPSR/SPSR and its fields: R at bit 20, mask at 11-8
	SYSM_T32,              // an M-profile special register, SYSm at 7-0
	MSR_SYSM_T32,          // the same, with MSR's APSR fields at 11-10
	MEM_T32_IMM12,         // [Rn, #imm12]
	MEM_T32_IMM8_NEG,      // [Rn, #-imm8]
	MEM_T32_IMM8_PRE,      // [Rn, #+/-imm8]!     U at bit 9
	MEM_T32_IMM8_POST,     // [Rn], #+/-imm8      U at bit 9
	MEM_T32_IMM8_POS,      // [Rn, #imm8]         (the unprivileged loads and stores)
	MEM_T32_REG,           // [Rn, Rm{, lsl #imm2}], imm2 at 5-4
	MEM_T32_LITERAL,       // Align(PC, 4) +/- imm12, U at bit 23
	MEM_T32_LITERAL_DUAL,  // Align(PC, 4) +/- imm8 * 4, U at bit 23 (LDRD)
	MEM_T32_EXCLUSIVE,     // [Rn, #imm8 * 4] (LDREX, STREX)
	MEM_T32_TABLE_B,       // [Rn, Rm] (TBB)
	MEM_T32_TABLE_H,       // [Rn, Rm, lsl #1] (TBH)
	RD_T32_STATUS,         // the status result of a store-exclusive, bits 3-0
	T32_REG_LIST,          // bits 15-0
	REL_T32_ADR_ADD,       // ADR: Align(PC, 4) + i:imm3:imm8
	REL_T32_ADR_SUB,       // ADR: Align(PC, 4) - i:imm3:imm8
	BRANCH_BLX_T32,        // BLX to A32: Align(PC, 4) + S:I1:I2:imm10H:imm10L:00
	RN_T32_ZR,             // Rn at 19-16, where 1111 is ZR (CSEL and friends)
	RM_T32_ZR,             // Rm at 3-0, where 1111 is ZR
	COND_T32_FCOND,        // a condition at 7-4, written as one (CSEL and friends)
	BANKED_MRS_T32,        // a banked register: R at 20, m1 at 19-16, m at 4
	BANKED_MSR_T32,        // the same with m1 at 11-8
	LOB_FORWARD,           // WLS: PC + imml:immh:'0' -- imml at 10-1, immh at 11
	LOB_BACKWARD,          // LE: PC - imml:immh:'0'

	// ---- Modified immediate ----
	A32_IMM_MOD,           // bits 11-0 carry rotate(11:8) + value(7:0)
	T32_IMM_MOD,           // Thumb-2 modified-imm in i:imm3:imm8 (bits 26, 14-12, 7-0)

	// ---- Immediate field placements (A32) ----
	A32_IMM_SHIFT,         // bits 11-7 (data-proc shift_imm)
	A32_IMM_SHIFT_32,      // same field, but a zero means 32 (LSR/ASR)
	A32_IMM24,             // bits 23-0 (B/BL/SVC)
	A32_IMM4,              // bits 3-0 in modified-imm rotate or SAT amount
	A32_REG_LIST,          // bits 15-0 (LDM/STM/PUSH/POP bitmask of R0..R15)

	// ---- VFP / NEON register fields ----
	VD_S,                  // S<reg>: Vd<4:1>=bits 15-12, D=bit 22; combined 5-bit reg
	VN_S,                  // S<reg>: Vn<4:1>=bits 19-16, N=bit 7
	VM_S,                  // S<reg>: Vm<4:1>=bits 3-0,  M=bit 5
	VD_D,                  // D<reg>: D=bit 22, Vd<3:0>=bits 15-12
	VN_D,                  // D<reg>: N=bit 7,  Vn<3:0>=bits 19-16
	VM_D,                  // D<reg>: M=bit 5,  Vm<3:0>=bits 3-0
	VD_Q,                  // Q<reg>: D=bit 22, Vd<3:0>=bits 15-12 (must be even)
	VN_Q,                  // Q<reg>: N=bit 7,  Vn<3:0>=bits 19-16 (must be even)
	VM_Q,                  // Q<reg>: M=bit 5,  Vm<3:0>=bits 3-0 (must be even)
	// VMOV (core register to scalar) destination Dd[lane]: Dd at bits 19:16 +
	// bit 7; the lane bits depend on element size:
	//   .8  lane[2:0] = bit22 : bit21 : bit5     .16 lane[1:0] = bit21 : bit6
	//   .32 lane[0]   = bit21
	VMOV_LANE_8,
	VMOV_LANE_16,
	VMOV_LANE_32,
	// MVE complex-op rotation immediate (user passes degrees):
	//   MVE_ROT_HCADD: #90/#270 -> bit 12;  MVE_ROT_CMLA: #0/90/180/270 -> bits 24:23
	MVE_ROT_HCADD,
	MVE_ROT_CMLA,
	// MVE 3-bit Q registers (Q0..Q7): Qn at bits 19:17, Qm at bits 3:1.
	VN_Q_MVE,
	VM_Q_MVE,
	VFP_IMM8,
	VM_S_PLUS1,            // the second S register of a consecutive pair
	DBG_OPTION,            // DBG's option, bits 3:0 -- not the wider hint field
	MRS_SPEC_REG,          // APSR or SPSR, by the R bit
	VFP_SPEC_REG,          // VMRS/VMSR system register, bits 19:16
	SETEND_ENDIAN,         // LE or BE, by the E bit
	IMPL_SP,               // an SP the syntax names but no field encodes
	IMPL_PC,               // the same, for PC (SUBS PC, LR, #imm)
	IMPL_LR,               // the same, for LR
	IMPL_R12,              // the same, for R12 (PAC, AUT)
	MODE_IMM5,             // processor mode, bits 4:0 (SRS)
	RN_A32_WB,             // base register whose writeback rides in bit 21
	NEON_LANE_VN_32,       // Vn:N with the 32-bit lane index in bit 21              // VFP immediate (VMOV.F32/F64 #imm)
	NEON_IMM8_ABCDEFGH,    // bits 18-16 (abc) + bits 3-0 (defgh)

	// ---- VFP / NEON list ----
	VFP_S_LIST,            // VLDM/VSTM single-prec list (8-bit count, start in Vd_S)
	VFP_D_LIST,            // VLDM/VSTM double-prec list (8-bit count, start in Vd_D)
	VFP_DX_LIST,           // FLDMX/FSTMX: the same, with an odd count one past the list
	VD_S_AGAIN,            // the fixed-point VCVTs name Sd twice and encode it once
	VD_D_AGAIN,            // the same for Dd
	RT_OR_APSR_NZCV,       // Rt at 15-12, where 1111 is APSR_nzcv (VMRS, MRC, CDE)
	RN_OR_APSR_NZCV,       // the same at 19-16 (CDE)
	RM_OR_APSR_NZCV,       // the same at 3-0 (CDE)

	// VTBL/VTBX read their table from a run of one to four D registers
	// starting at Vn, the length less one in bits 9-8.
	NEON_VN_TABLE,

	// NEON "by scalar": the multiplier is one lane of a low D register, and
	// the register number and the lane number share one four-bit field. How
	// they share it depends on the element size -- 16-bit takes Vm from bits
	// 2:0, so D0..D7, and the lane from M:bit3; 32-bit takes Vm from bits
	// 3:0, so D0..D15, and the lane from M alone.
	NEON_VM_SCALAR_16, NEON_VM_SCALAR_32,
	// The same for the two that take Dm whole: VCMLA.F32 by element, whose
	// lane can only be 0, and VFMAL's D form, whose scalar is a lane of S0-S15
	// -- Sm at 2:0 and M, the lane at bit 3.
	NEON_VM_D_LANE0,
	NEON_VM_S_SCALAR,
	// VDUP from a lane packs the element size and the lane index into one
	// four-bit field: `xxx1` is a byte lane, `xx10` a halfword, `x100` a
	// word, and the bits above the marker are the index.
	NEON_VDUP_LANE,
	// The element and structure loads and stores. How many registers the list
	// holds, how they are spaced, which lane and what alignment the address
	// names are each spread across bits that mean different things by class,
	// element count and size; they are read from the whole word (simd.odin),
	// and the encoder reads them from the form's.
	NEON_MULTIPLE_LIST,    // {d0, d1}: several structures to whole registers
	NEON_LANE_LIST,        // {d0[1], d1[1]}: one structure to a lane
	NEON_ALL_LANES_LIST,   // {d0[], d1[]}: one structure to every lane
	NEON_ADDRESS,          // [Rn:align], with Rm the writeback

	// ---- Memory addressing composites ----
	MEM_IMM12_OFFSET,      // [Rn, #±imm12]
	// The halfword and dual load/stores split their 8-bit offset around the
	// opcode at bits 7:4, so they cannot use the 12-bit forms below.
	// LDRD/STRD name a register pair, and the second is always the first plus
	// one, so it occupies no bits of its own.
	RT_PAIR_NEXT,          // the register after the one at 15-12: no bits (LDRD's Rt2)
	MEM_IMM8_PRE_INDEX,
	MEM_IMM8_POST_INDEX,
	MEM_IMM8_OFFSET,
	MEM_IMM8_SCALED4,      // VFP load/store: imm8 in words, U at bit 23
	MEM_IMM8_SCALED4_PRE,  // same, pre-indexed
	MEM_IMM8_SCALED4_POST, // same, post-indexed
	MEM_IMM8_SCALED2,      // the half-precision VLDR/VSTR: imm8 in halfwords       // [Rn, #±imm8] (LDRH/STRH/LDRSB/STRD)
	MEM_REG_OFFSET,        // [Rn, ±Rm{, shift}]
	MEM_PRE_INDEX,         // [Rn, #imm]! / [Rn, ±Rm]!
	MEM_POST_INDEX,        // [Rn], #imm / [Rn], ±Rm

	// ---- Coprocessor ----
	COPROC_NUM_FIELD,      // bits 11-8 in CDP/LDC/STC (cp_num)
	COPROC_CRD_FIELD,      // bits 15-12 -- the destination, which is not CRn
	COPROC_OPC1_MCR,       // bits 23-21 (MCR/MRC opc1, three bits not four)
	COPROC_OPC1_FIELD,     // bits 23-20 (CDP opc1)
	COPROC_OPC2_FIELD,     // bits 7-5  (CDP / MCR / MRC opc2)
	COPROC_CRN_FIELD,      // bits 19-16
	COPROC_CRM_FIELD,      // bits 3-0
	COPROC_OPC_MCRR,       // bits 7-4 (MCRR/MRRC 4-bit opcode)
	COPROC_OPTION,         // bits 7-0, LDC/STC's `{option}` where an offset would be

	// ---- Branch fields ----
	BRANCH_24,             // A32 imm24 at bits 23-0 (scaled ×4, ±32MB)
	BRANCH_24_T32,         // T32 unconditional: S/J1/J2 + imm10 + imm11 (scaled ×2)
	BRANCH_20_T32,         // T32 conditional: S + cond + imm6 + J1 + J2 + imm11
	BRANCH_11_T16,         // T16 unconditional (imm11, scaled ×2, ±2KB)
	BRANCH_8_T16,          // T16 conditional (cond + imm8, scaled ×2, ±256B)
	BRANCH_CBZ,            // T16 CBZ/CBNZ (i + imm5 + Rn, scaled ×2)
	// ARMv8.1-M Branch Future fields (T32):
	BF_BOFF,               // bf-point offset: imm4 at hw0[10:7], (label-PC-4)/2
	BF_BLOC,               // branch target: J at hw1[11] + imm10 at hw1[10:1]
	BF_RM,                 // BFLX/BFX register target at hw0[3:0]
	BFCSEL_COND,           // BFCSEL condition at hw0[5:2]

	// ---- Misc ----
	PSR_FIELD_MASK,        // APSR fields_mask at bits 19-16 (MSR)
	BARRIER_TYPE,          // bits 3-0 for DMB/DSB/ISB
	HINT_FIELD,            // hint imm

	// ---- Saturate ----
	VFP_FBITS,             // VCVT fixed-point fraction bits: width - (imm4:i)
	// VSHLL's widest form shifts by exactly the element size, which no field
	// carries: it is 8 << the size field, bits 19-18.
	NEON_SHLL,
	// Complex-arithmetic rotations, named in degrees. VCADD has two, in bit
	// 24; VCMLA has four, in bits 21:20.
	// VCMLA names its rotation twice over: the by-element forms put it in
	// bits 21:20, the vector forms in 24:23.
	NEON_ROT_2, NEON_ROT_4, NEON_ROT_4_HI,
	SAT_IMM5,              // bits 20-16: SSAT/SSAT16 saturate-to width, less one
	SAT_IMM5_T32,          // Thumb-2 signed saturate amount, less one
	SAT_IMM5_U,            // bits 20-16: USAT/USAT16 width, which is not biased
	SAT_IMM5_U_T32,        // Thumb-2 unsigned saturate amount

	// ---- BFC/BFI/SBFX/UBFX ----
	// SBFX/UBFX hold the width less one, where BFI/BFC hold the top bit's
	// position and the width is msb - lsb + 1.
	BFX_WIDTH,
	BFI_MSB,               // bits 20-16 (msb position)
	BFI_LSB,               // bits 11-7  (lsb position; also shift_imm slot)
	BFI_LSB_T32,           // Thumb-2 BFI lsb (different layout)

	// ---- Shift by immediate ----
	// L:imm6 (bits 7, 21-16) holds the element size as its leading one and
	// the shift below it: a right shift is twice the size less L:imm6, a left
	// shift L:imm6 less the size. The fixed-point VCVT's #fbits is 64 - imm6.
	NEON_SHIFT_RIGHT,
	NEON_SHIFT_LEFT,
	NEON_FBITS,
	NEON_SHIFT_IMM6,       // MVE's: the 6-bit amount at bits 21:16, as it stands

	// ---- ARMv8-M / MVE / CDE ----
	QD_MVE,                // MVE Qd: bit 22 fixed 0, bits 15:13 = Qd[2:0]
	QN_MVE,                // MVE Qn: bit 7, bits 19:17 = Qn[2:0]
	QM_MVE,                // MVE Qm: bit 5, bits 3:1 = Qm[2:0]
	MVE_RDA_EVEN,          // an even accumulator, Rda / 2 at bits 15:13 (VADDV, VMLADAV)
	MVE_RDALO,             // a long accumulator's low half, RdaLo / 2 at bits 15:13
	MVE_RDAHI,             // its high half, RdaHi / 2 at bits 22:20 (RdaHi is odd)
	MVE_VPT_MASK_FIELD,    // VPT mask in bits 3:0 of second halfword
	MVE_RN_EVEN,           // an even GPR, Rn / 2 at bits 19:17 (VIDUP's offset)
	MVE_RM_ODD,            // an odd GPR, Rm / 2 at bits 3:1 (VIWDUP's wrap)
	MVE_DUP_IMM,           // 1, 2, 4 or 8, as its log2 in bits 7 and 0
	CDE_COPROC_FIELD,      // CDE p<n>, bits 10-8 (bit 11 is 0: CDE has coprocessors 0-7)
	// CDE immediates, scattered around the register fields. The vector forms
	// on Q registers (bit 6 set) have one bit more, at 24, where the S and D
	// forms say which of the two they are.
	CDE_IMM_CX1,           // imm13: 5-0, then 7, then 21-16
	CDE_IMM_CX2,           // imm9: 5-0, then 7, then 21-20
	CDE_IMM_CX3,           // imm6: 5-4, then 7, then 22-20
	CDE_IMM_VCX1,          // imm11: 5-0, then 7, then 19-16 (imm12: then 24)
	CDE_IMM_VCX2,          // imm6: 4, then 7, then 19-16 (imm7: then 24)
	CDE_IMM_VCX3,          // imm3: 4, then 21-20 (imm4: then 24)
}

// ---- Encoding struct -------------------------------------------------------

// The data type an A32 mnemonic carries as a suffix: `vadd.i32`, `vcvt.s32.f32`,
// `vstrb.8`. Unlike A64 -- where the arrangement belongs to each operand
// (`add v0.4s, v1.4s, v2.4s`) -- in A32 it belongs to the INSTRUCTION, which is
// why it lives here and on Instruction rather than on Operand.
//
// It is not decoration: NEON reuses one operand shape across every element
// width, so `vadd.i8` and `vadd.f32` are both DPR,DPR,DPR and the type is the
// only thing that separates their encodings. Without it the encoder can only
// ever reach the first form of each shape.
Data_Type :: enum u8 {
	NONE,
	S8, S16, S32, S64,     // signed integer
	U8, U16, U32, U64,     // unsigned integer
	I8, I16, I32, I64,     // sign-agnostic integer
	F16, F32, F64,         // floating point
	P8, P16, P64,          // polynomial
	BF16,                  // bfloat16
	SZ8, SZ16, SZ32, SZ64, // bare element size (`vmov.32`, `vstrb.8`)
}

// Two slots because the convert family names both ends: `vcvt.s32.f32`.
// Everything else leaves dt[1] as .NONE.
Data_Types :: [2]Data_Type

Encoding :: struct #packed {
	mnemonic: Mnemonic,            // 2
	ops:      [6]Operand_Type,     // 6
	enc:      [6]Operand_Encoding, // 6
	bits:     u32,                 // 4 -- static field pattern
	mask:     u32,                 // 4 -- which bits are static
	feature:  Feature,             // 1
	mode:     Mode,                // 1
	flags:    Encoding_Flags,      // 2
	dt:       Data_Types,          // 2
}
#assert(size_of(Encoding) == 28)

// ---- Length introspection --------------------------------------------------
//
// For an entry's `bits` field, returns the on-the-wire instruction length:
//   - 4 bytes for A32 entries
//   - 4 bytes for T32 Thumb-2 entries (first halfword bits[15:11] in {11101,
//     11110, 11111}; the first halfword in memory is stored in bits[31:16]
//     of our u32 packing — see encoder.odin's halfword writeout order)
//   - 2 bytes for T16 Thumb-1 entries (low halfword)
//
// T32 32-bit entries pack `bits = (first_halfword << 16) | second_halfword`.
// T16 entries leave the high halfword zero and store the 16-bit instruction
// in bits[15:0].

inst_size_from_bits :: #force_inline proc "contextless" (bits: u32, mode: Mode) -> u8 {
	if mode == .A32 { return 4 }
	// For T32, check the top 5 bits of the FIRST halfword (= bits[31:27] of u32
	// when packed as (first << 16) | second). If the high halfword is zero
	// we have a T16 16-bit form; otherwise we test the size identifier.
	if (bits >> 16) == 0 { return 2 }
	hw := (bits >> 27) & 0x1F
	return hw >= 0x1D ? 4 : 2
}

// ---- Standard field masks (A32) --------------------------------------------

MASK_COND        :: u32(0xF0000000)         // bits 31-28
MASK_OPCODE_HI   :: u32(0x0FE00000)         // bits 27-25 (selects encoding class) + 24-21 (op)
MASK_S_FLAG      :: u32(0x00100000)         // bit 20
MASK_RN_A32      :: u32(0x000F0000)         // bits 19-16
MASK_RD_A32      :: u32(0x0000F000)         // bits 15-12
MASK_RM_A32      :: u32(0x0000000F)         // bits 3-0
MASK_RS_A32      :: u32(0x00000F00)         // bits 11-8
MASK_SHIFT_IMM   :: u32(0x00000F80)         // bits 11-7
MASK_SHIFT_TYPE  :: u32(0x00000060)         // bits 6-5
MASK_IMM12       :: u32(0x00000FFF)         // bits 11-0
MASK_IMM24       :: u32(0x00FFFFFF)         // bits 23-0
MASK_RLIST       :: u32(0x0000FFFF)         // bits 15-0

// Condition code constants (cond field values).
COND_EQ :: u32(0x0); COND_NE :: u32(0x1)
COND_CS :: u32(0x2); COND_CC :: u32(0x3)
COND_MI :: u32(0x4); COND_PL :: u32(0x5)
COND_VS :: u32(0x6); COND_VC :: u32(0x7)
COND_HI :: u32(0x8); COND_LS :: u32(0x9)
COND_GE :: u32(0xA); COND_LT :: u32(0xB)
COND_GT :: u32(0xC); COND_LE :: u32(0xD)
COND_AL :: u32(0xE); COND_NV :: u32(0xF)  // NV is "always" in encoding (also marks unconditional class)

// Shift type field values (A32 bits 6-5).
SHIFT_LSL :: u32(0)
SHIFT_LSR :: u32(1)
SHIFT_ASR :: u32(2)
SHIFT_ROR :: u32(3)
SHIFT_RRX :: u32(3)   // encoded as ROR #0

// Convenience: build an Encoding_Flags with named fields.
encoding_flags :: #force_inline proc "contextless" (
	sets_flags:    bool = false,
	cond_in_28:  bool = true,    // default: conditional execution allowed (A32)
	branch:      bool = false,
	cond_branch: bool = false,
	writes_pc:   bool = false,
	thumb32:     bool = false,
	deprecated:  bool = false,
) -> Encoding_Flags {
	return Encoding_Flags{
		sets_flags = sets_flags, cond_in_28 = cond_in_28,
		branch = branch, cond_branch = cond_branch,
		writes_pc = writes_pc, thumb32 = thumb32,
		deprecated = deprecated,
	}
}
