// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm32

import "../isa"

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

Result           :: isa.Result
Error            :: isa.Error
Error_Code       :: isa.Error_Code
Label_Definition :: isa.Label_Definition
LABEL_UNDEFINED  :: isa.LABEL_UNDEFINED
Label_Map        :: isa.Label_Map

// ---- Mode -------------------------------------------------------------------

Mode :: enum u8 {
	A32 = 0,            // 32-bit ARM
	T32 = 1,            // Thumb (16-bit or 32-bit T2)
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

Encoding_Flags :: bit_field u8 {
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
	_:           u8   | 1,
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
	CDE_COPROC,           // CDE coprocessor number 0..7
	CDE_IMM,              // CDE immediate (varies per CX1/CX2/CX3 form)
	CDE_VFP_REG,          // CDE VCX1/2/3 destination S/D-reg
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
	RA_A32,                // bits 15-12 (MLA, MLS accumulator)
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

	// ---- Modified immediate ----
	A32_IMM_MOD,           // bits 11-0 carry rotate(11:8) + value(7:0)
	T32_IMM_MOD,           // Thumb-2 modified-imm in i:imm3:imm8 (bits 26, 14-12, 7-0)
	A32_IMM12_ROT,         // identical to A32_IMM_MOD; alternate name for clarity

	// ---- Immediate field placements (A32) ----
	A32_IMM12,             // bits 11-0 (LDR/STR offset)
	A32_IMM_SHIFT,         // bits 11-7 (data-proc shift_imm)
	A32_SHIFT_TYPE,        // bits 6-5
	A32_RS_SHIFT,          // bits 11-8 (RSR uses Rs register)
	A32_IMM24,             // bits 23-0 (B/BL/SVC)
	A32_IMM4,              // bits 3-0 in modified-imm rotate or SAT amount
	A32_IMM4_ROTATE,       // bits 11-8 (rotation in some forms)
	A32_IMM5_LSB,          // bits 11-7 (BFC/BFI/UBFX lsb)
	A32_IMM5_W,            // bits 20-16 (BFC/BFI msb -- width = msb - lsb + 1)
	A32_COND_FIELD,        // bits 31-28
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
	// NEON by-element scalar Dm[lane] (VQDMULH/VQRDMULH-by-scalar):
	//   .16: Dm in D0..D7 at bits 2:0, lane = bit5:bit3
	//   .32: Dm in D0..D15 at bits 3:0, lane = bit5
	NEON_VM_SCALAR16,
	NEON_VM_SCALAR32,
	// VMOV (core register to scalar) destination Dd[lane]: Dd at bits 19:16 +
	// bit 7; the lane bits depend on element size:
	//   .8  lane[2:0] = bit22 : bit21 : bit5     .16 lane[1:0] = bit21 : bit6
	//   .32 lane[0]   = bit21
	VMOV_LANE_8,
	VMOV_LANE_16,
	VMOV_LANE_32,
	VFP_IMM8,              // VFP immediate (VMOV.F32/F64 #imm)
	NEON_IMM8_ABCDEFGH,    // bits 18-16 (abc) + bits 3-0 (defgh)
	NEON_CMODE,            // bits 11-8 (cmode for VMOV/VMVN immediate)
	NEON_OP_BIT,           // bit 5 (op for VMOV immediate variant)

	// ---- VFP / NEON list ----
	VFP_S_LIST,            // VLDM/VSTM single-prec list (8-bit count, start in Vd_S)
	VFP_D_LIST,            // VLDM/VSTM double-prec list (8-bit count, start in Vd_D)

	// ---- Memory addressing composites ----
	MEM_IMM12_OFFSET,      // [Rn, #±imm12]
	MEM_IMM8_OFFSET,       // [Rn, #±imm8] (LDRH/STRH/LDRSB/STRD)
	MEM_REG_OFFSET,        // [Rn, ±Rm{, shift}]
	MEM_PRE_INDEX,         // [Rn, #imm]! / [Rn, ±Rm]!
	MEM_POST_INDEX,        // [Rn], #imm / [Rn], ±Rm
	MEM_LITERAL,           // [PC, #imm]  (LDR literal)
	MEM_DOUBLEREG,         // [Rn, Rm] for LDRD/STRD register offset

	// ---- Coprocessor ----
	COPROC_NUM_FIELD,      // bits 11-8 in CDP/LDC/STC (cp_num)
	COPROC_OPC1_FIELD,     // bits 23-20 (CDP / MCR / MRC opc1)
	COPROC_OPC2_FIELD,     // bits 7-5  (MCR/MRC opc2)
	COPROC_CRN_FIELD,      // bits 19-16
	COPROC_CRM_FIELD,      // bits 3-0
	COPROC_OPC_MCRR,       // bits 7-4 (MCRR/MRRC 4-bit opcode)

	// ---- Branch fields ----
	BRANCH_24,             // A32 imm24 at bits 23-0 (scaled ×4, ±32MB)
	BRANCH_24_T32,         // T32 unconditional: S/J1/J2 + imm10 + imm11 (scaled ×2)
	BRANCH_20_T32,         // T32 conditional: S + cond + imm6 + J1 + J2 + imm11
	BRANCH_11_T16,         // T16 unconditional (imm11, scaled ×2, ±2KB)
	BRANCH_8_T16,          // T16 conditional (cond + imm8, scaled ×2, ±256B)
	BRANCH_CBZ,            // T16 CBZ/CBNZ (i + imm5 + Rn, scaled ×2)

	// ---- Misc ----
	PSR_FIELD_MASK,        // APSR fields_mask at bits 19-16 (MSR)
	SYSM_FIELD,            // SYSm at bits 7-0 (MRS_BANKED)
	BARRIER_TYPE,          // bits 3-0 for DMB/DSB/ISB
	IT_MASK,               // bits 7-0 for IT block (mask + cond)
	CPS_IFLAGS,            // imod + iflags + mode for CPS
	HINT_FIELD,            // hint imm

	// ---- Saturate ----
	SAT_IMM5,              // bits 20-16: SSAT/USAT saturate-to width
	SAT_IMM5_T32,          // Thumb-2 saturate amount

	// ---- BFC/BFI/SBFX/UBFX ----
	BFI_MSB,               // bits 20-16 (msb position)
	BFI_LSB,               // bits 11-7  (lsb position; also shift_imm slot)
	BFI_LSB_T32,           // Thumb-2 BFI lsb (different layout)

	// ---- NEON shift-immediate (imm6 in bits 21:16, with element-size hint
	//      in bit 22 = L bit for 64-bit shifts) ----
	NEON_SHIFT_IMM6,       // 6-bit shift amount at bits 21:16 (NEON VSHR/VSRA/...)
	NEON_SHIFT_IMM3,       // 3-bit shift at bits 18:16 (.I8 form, top 3 bits zero)

	// ---- ARMv8-M / MVE / CDE ----
	QD_MVE,                // MVE Qd: bit 22 fixed 0, bits 15:13 = Qd[2:0]
	QN_MVE,                // MVE Qn: bit 7, bits 19:17 = Qn[2:0]
	QM_MVE,                // MVE Qm: bit 5, bits 3:1 = Qm[2:0]
	MVE_SIZE_FIELD,        // 2-bit size in bits 21:20 (B/H/W/D)
	MVE_VPT_MASK_FIELD,    // VPT mask in bits 3:0 of second halfword
	MVE_LOOP_IMM,          // low-overhead-loop immediate
	CDE_COPROC_FIELD,      // CDE p<n> coprocessor selector (bits 11:8)
	CDE_IMM_FIELD,         // CDE immediate (variable layout)
	CDE_ACC_FIELD,         // CDE accumulator bit (distinguishes CX1/CX1A)
	V8M_TT_AT_BITS,        // TT/TTA/TTT/TTAT A and T bit field at bits 7:6
}

// ---- Encoding struct -------------------------------------------------------

Encoding :: struct #packed {
	mnemonic: Mnemonic,            // 2
	ops:      [4]Operand_Type,     // 4
	enc:      [4]Operand_Encoding, // 4
	bits:     u32,                 // 4 -- static field pattern
	mask:     u32,                 // 4 -- which bits are static
	feature:  Feature,             // 1
	mode:     Mode,                // 1
	flags:    Encoding_Flags,      // 1
}
#assert(size_of(Encoding) == 21)

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
