// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm32_tablegen

// =============================================================================
// AArch32 ENCODING TABLE
// =============================================================================
//
// Comprehensive encoding catalog for AArch32 (A32 + T32 + Thumb-1 + VFP + NEON
// + ARMv8 crypto/CRC). Each entry: `{mnemonic, ops[4], enc[4], bits, mask,
// feature, mode, flags}`. The matcher tests `(word & mask) == bits`; the
// encoder OR's operand bits into the zero positions of `mask`.
//
// Layout of the file is by section:
//
//   §1  A32 data processing -- immediate / register / register-shifted-register
//   §2  A32 multiply family
//   §3  A32 saturating arithmetic + ARMv6 DSP SIMD on GPRs
//   §4  A32 extends + bit-field + REV + CLZ + RBIT + SEL + PKHBT/TB
//   §5  A32 branches + status reg + exception generation
//   §6  A32 load/store (word/byte/halfword/doubleword + LDM/STM + SWP)
//   §7  A32 exclusive monitors + acquire/release + barriers + hints
//   §8  A32 coprocessor (CDP/MCR/MRC/LDC/STC) + CRC32 + AES/SHA
//   §9  A32 VFP scalar floating point (VFPv2/v3/v4)
//   §10 Advanced SIMD: generated in simd_table.odin; here, the VFP and MVE
//       forms of the mnemonics it shares
//   §11 T16 Thumb-1 (16-bit) encodings
//   §12 T32 Thumb-2 (32-bit) encodings
//   §13 VFP / NEON Thumb-2 encodings (when distinct)
//
// Conventions:
//   * A32 conditional instructions have bits 31:28 (cond) as OPERAND-driven.
//     The static `bits` contain 0 for those positions, and `mask` doesn't lock
//     them. The encoder OR's the user-supplied cond into bits 31:28 when the
//     entry's flags.cond_in_28 is true. For UNCONDITIONAL classes (top nibble
//     1111), we set bits 31:28 = 1111 and mask locks them, and flags.cond_in_28
//     is false.
//
//   * Set-flags variants (ADDS, SUBS, ANDS, ...) are SEPARATE entries with
//     bit 20 (S) set in `bits` and locked by `mask`. The mnemonic is shared
//     with the non-flag-setting form -- the encoder picks based on the
//     `sets_flags` flag on the user's Instruction.
//
//   * For T32 32-bit (Thumb-2) entries, `bits` packs (low_halfword |
//     high_halfword << 16). E.g. a Thumb-2 encoding with low=0xF000 and
//     high=0xF800 stores as 0xF800F000.
@(rodata)
ENCODING_TABLE := #partial [Mnemonic][]Encoding{
	// =========================================================================
	// §1 -- A32 Data processing (16 ops × 3 operand-shape variants)
	// =========================================================================
	//   A32 layout:
	//     cond 00 I opcode S Rn Rd operand2(12)
	//   With:
	//     I=1  (bit 25)        immediate (rotate:imm8) in operand2
	//     I=0  bit 4=0          register + imm-shift in operand2
	//     I=0  bit 4=1, bit 7=0 register-shifted-register in operand2
	//
	//   opcode (bits 24:21):
	//     AND=0000  EOR=0001  SUB=0010  RSB=0011
	//     ADD=0100  ADC=0101  SBC=0110  RSC=0111
	//     TST=1000  TEQ=1001  CMP=1010  CMN=1011
	//     ORR=1100  MOV=1101  BIC=1110  MVN=1111
	//
	//   For TST/TEQ/CMP/CMN: S bit is implicit-1 (these only set flags).
	//   For MOV/MVN: Rn is unused (must be 0000 in encoding).
	//
	//   The mask 0x0FE00010 (immediate-shift form) locks:
	//     bits 27:21 (opcode + I + class) and bit 4 (shift-form selector).
	//   The mask 0x0FE00090 (RSR form) locks bits 4 and 7 as well.

	// ---------- ADD ----------
	.ADD = {
		// ADD imm:  cond 0010 0100 S Rn Rd imm12_mod
		{.ADD, {.GPR, .GPR, .IMM_MOD, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE}, 0x02800000, 0x0FE00000, .BASE, .A32, {}, {}},
		// ADD reg: cond 0000 0100 S Rn Rd shift_imm shift_type 0 Rm
		{.ADD, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00800000, 0x0FE00010, .BASE, .A32, {}, {}},
		// ADD rsr: cond 0000 0100 S Rn Rd Rs 0 shift_type 1 Rm
		{.ADD, {.GPR, .GPR, .GPR_RSR, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00800010, 0x0FE00090, .BASE, .A32, {}, {}},
		// ADDS variants
		{.ADD, {.GPR, .GPR, .IMM_MOD, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE}, 0x02900000, 0x0FF00000, .BASE, .A32, {sets_flags=true}, {}},
		{.ADD, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00900000, 0x0FF00010, .BASE, .A32, {sets_flags=true}, {}},
		{.ADD, {.GPR, .GPR, .GPR_RSR, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00900010, 0x0FF00090, .BASE, .A32, {sets_flags=true}, {}},
	},
	.ADC = {
		{.ADC, {.GPR, .GPR, .IMM_MOD, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE}, 0x02A00000, 0x0FE00000, .BASE, .A32, {}, {}},
		{.ADC, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00A00000, 0x0FE00010, .BASE, .A32, {}, {}},
		{.ADC, {.GPR, .GPR, .GPR_RSR, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00A00010, 0x0FE00090, .BASE, .A32, {}, {}},
		{.ADC, {.GPR, .GPR, .IMM_MOD, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE}, 0x02B00000, 0x0FF00000, .BASE, .A32, {sets_flags=true}, {}},
		{.ADC, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00B00000, 0x0FF00010, .BASE, .A32, {sets_flags=true}, {}},
		{.ADC, {.GPR, .GPR, .GPR_RSR, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00B00010, 0x0FF00090, .BASE, .A32, {sets_flags=true}, {}},
	},
	.SUB = {
		{.SUB, {.GPR, .GPR, .IMM_MOD, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE}, 0x02400000, 0x0FE00000, .BASE, .A32, {}, {}},
		{.SUB, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00400000, 0x0FE00010, .BASE, .A32, {}, {}},
		{.SUB, {.GPR, .GPR, .GPR_RSR, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00400010, 0x0FE00090, .BASE, .A32, {}, {}},
		{.SUB, {.GPR, .GPR, .IMM_MOD, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE}, 0x02500000, 0x0FF00000, .BASE, .A32, {sets_flags=true}, {}},
		{.SUB, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00500000, 0x0FF00010, .BASE, .A32, {sets_flags=true}, {}},
		{.SUB, {.GPR, .GPR, .GPR_RSR, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00500010, 0x0FF00090, .BASE, .A32, {sets_flags=true}, {}},
	},
	.SBC = {
		{.SBC, {.GPR, .GPR, .IMM_MOD, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE}, 0x02C00000, 0x0FE00000, .BASE, .A32, {}, {}},
		{.SBC, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00C00000, 0x0FE00010, .BASE, .A32, {}, {}},
		{.SBC, {.GPR, .GPR, .GPR_RSR, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00C00010, 0x0FE00090, .BASE, .A32, {}, {}},
		{.SBC, {.GPR, .GPR, .IMM_MOD, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE}, 0x02D00000, 0x0FF00000, .BASE, .A32, {sets_flags=true}, {}},
		{.SBC, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00D00000, 0x0FF00010, .BASE, .A32, {sets_flags=true}, {}},
		{.SBC, {.GPR, .GPR, .GPR_RSR, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00D00010, 0x0FF00090, .BASE, .A32, {sets_flags=true}, {}},
	},
	.RSB = {
		{.RSB, {.GPR, .GPR, .IMM_MOD, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE}, 0x02600000, 0x0FE00000, .BASE, .A32, {}, {}},
		{.RSB, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00600000, 0x0FE00010, .BASE, .A32, {}, {}},
		{.RSB, {.GPR, .GPR, .GPR_RSR, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00600010, 0x0FE00090, .BASE, .A32, {}, {}},
		{.RSB, {.GPR, .GPR, .IMM_MOD, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE}, 0x02700000, 0x0FF00000, .BASE, .A32, {sets_flags=true}, {}},
		{.RSB, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00700000, 0x0FF00010, .BASE, .A32, {sets_flags=true}, {}},
		{.RSB, {.GPR, .GPR, .GPR_RSR, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00700010, 0x0FF00090, .BASE, .A32, {sets_flags=true}, {}},
	},
	.RSC = {
		{.RSC, {.GPR, .GPR, .IMM_MOD, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE}, 0x02E00000, 0x0FE00000, .BASE, .A32, {}, {}},
		{.RSC, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00E00000, 0x0FE00010, .BASE, .A32, {}, {}},
		{.RSC, {.GPR, .GPR, .GPR_RSR, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00E00010, 0x0FE00090, .BASE, .A32, {}, {}},
		{.RSC, {.GPR, .GPR, .IMM_MOD, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE}, 0x02F00000, 0x0FF00000, .BASE, .A32, {sets_flags=true}, {}},
		{.RSC, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00F00000, 0x0FF00010, .BASE, .A32, {sets_flags=true}, {}},
		{.RSC, {.GPR, .GPR, .GPR_RSR, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00F00010, 0x0FF00090, .BASE, .A32, {sets_flags=true}, {}},
	},
	.AND = {
		{.AND, {.GPR, .GPR, .IMM_MOD, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE}, 0x02000000, 0x0FE00000, .BASE, .A32, {}, {}},
		{.AND, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00000000, 0x0FE00010, .BASE, .A32, {}, {}},
		{.AND, {.GPR, .GPR, .GPR_RSR, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00000010, 0x0FE00090, .BASE, .A32, {}, {}},
		{.AND, {.GPR, .GPR, .IMM_MOD, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE}, 0x02100000, 0x0FF00000, .BASE, .A32, {sets_flags=true}, {}},
		{.AND, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00100000, 0x0FF00010, .BASE, .A32, {sets_flags=true}, {}},
		{.AND, {.GPR, .GPR, .GPR_RSR, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00100010, 0x0FF00090, .BASE, .A32, {sets_flags=true}, {}},
	},
	.EOR = {
		{.EOR, {.GPR, .GPR, .IMM_MOD, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE}, 0x02200000, 0x0FE00000, .BASE, .A32, {}, {}},
		{.EOR, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00200000, 0x0FE00010, .BASE, .A32, {}, {}},
		{.EOR, {.GPR, .GPR, .GPR_RSR, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00200010, 0x0FE00090, .BASE, .A32, {}, {}},
		{.EOR, {.GPR, .GPR, .IMM_MOD, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE}, 0x02300000, 0x0FF00000, .BASE, .A32, {sets_flags=true}, {}},
		{.EOR, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00300000, 0x0FF00010, .BASE, .A32, {sets_flags=true}, {}},
		{.EOR, {.GPR, .GPR, .GPR_RSR, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x00300010, 0x0FF00090, .BASE, .A32, {sets_flags=true}, {}},
	},
	.ORR = {
		{.ORR, {.GPR, .GPR, .IMM_MOD, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE}, 0x03800000, 0x0FE00000, .BASE, .A32, {}, {}},
		{.ORR, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x01800000, 0x0FE00010, .BASE, .A32, {}, {}},
		{.ORR, {.GPR, .GPR, .GPR_RSR, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x01800010, 0x0FE00090, .BASE, .A32, {}, {}},
		{.ORR, {.GPR, .GPR, .IMM_MOD, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE}, 0x03900000, 0x0FF00000, .BASE, .A32, {sets_flags=true}, {}},
		{.ORR, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x01900000, 0x0FF00010, .BASE, .A32, {sets_flags=true}, {}},
		{.ORR, {.GPR, .GPR, .GPR_RSR, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x01900010, 0x0FF00090, .BASE, .A32, {sets_flags=true}, {}},
	},
	.BIC = {
		{.BIC, {.GPR, .GPR, .IMM_MOD, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE}, 0x03C00000, 0x0FE00000, .BASE, .A32, {}, {}},
		{.BIC, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x01C00000, 0x0FE00010, .BASE, .A32, {}, {}},
		{.BIC, {.GPR, .GPR, .GPR_RSR, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x01C00010, 0x0FE00090, .BASE, .A32, {}, {}},
		{.BIC, {.GPR, .GPR, .IMM_MOD, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE}, 0x03D00000, 0x0FF00000, .BASE, .A32, {sets_flags=true}, {}},
		{.BIC, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x01D00000, 0x0FF00010, .BASE, .A32, {sets_flags=true}, {}},
		{.BIC, {.GPR, .GPR, .GPR_RSR, .NONE, .NONE, .NONE},     {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x01D00010, 0x0FF00090, .BASE, .A32, {sets_flags=true}, {}},
	},

	// MOV and MVN have Rn unused (encoded as 0). The MOV-immediate form
	// additionally has ARMv6T2 MOVW (low half, no shift) and MOVT (high half).
	.MOV = {
		{.MOV, {.GPR, .IMM_MOD, .NONE, .NONE, .NONE, .NONE},     {.RD, .A32_IMM_MOD, .NONE, .NONE, .NONE, .NONE}, 0x03A00000, 0x0FEF0000, .BASE, .A32, {}, {}},
		{.MOV, {.GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x01A00000, 0x0FEF0010, .BASE, .A32, {}, {}},
		{.MOV, {.GPR, .GPR_RSR, .NONE, .NONE, .NONE, .NONE},     {.RD, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x01A00010, 0x0FEF0090, .BASE, .A32, {}, {}},
		{.MOV, {.GPR, .IMM_MOD, .NONE, .NONE, .NONE, .NONE},     {.RD, .A32_IMM_MOD, .NONE, .NONE, .NONE, .NONE}, 0x03B00000, 0x0FFF0000, .BASE, .A32, {sets_flags=true}, {}},
		{.MOV, {.GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x01B00000, 0x0FFF0010, .BASE, .A32, {sets_flags=true}, {}},
		{.MOV, {.GPR, .GPR_RSR, .NONE, .NONE, .NONE, .NONE},     {.RD, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x01B00010, 0x0FFF0090, .BASE, .A32, {sets_flags=true}, {}},
	},
	.MVN = {
		{.MVN, {.GPR, .IMM_MOD, .NONE, .NONE, .NONE, .NONE},     {.RD, .A32_IMM_MOD, .NONE, .NONE, .NONE, .NONE}, 0x03E00000, 0x0FEF0000, .BASE, .A32, {}, {}},
		{.MVN, {.GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x01E00000, 0x0FEF0010, .BASE, .A32, {}, {}},
		{.MVN, {.GPR, .GPR_RSR, .NONE, .NONE, .NONE, .NONE},     {.RD, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x01E00010, 0x0FEF0090, .BASE, .A32, {}, {}},
		{.MVN, {.GPR, .IMM_MOD, .NONE, .NONE, .NONE, .NONE},     {.RD, .A32_IMM_MOD, .NONE, .NONE, .NONE, .NONE}, 0x03F00000, 0x0FFF0000, .BASE, .A32, {sets_flags=true}, {}},
		{.MVN, {.GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x01F00000, 0x0FFF0010, .BASE, .A32, {sets_flags=true}, {}},
		{.MVN, {.GPR, .GPR_RSR, .NONE, .NONE, .NONE, .NONE},     {.RD, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x01F00010, 0x0FFF0090, .BASE, .A32, {sets_flags=true}, {}},
	},

	// MOVW / MOVT (ARMv6T2): 16-bit imm split as imm4(19:16) + imm12(11:0)
	.MOVW = {
		{.MOVW, {.GPR, .IMM16_LO_HI, .NONE, .NONE, .NONE, .NONE}, {.RD, .IMM4_IMM12, .NONE, .NONE, .NONE, .NONE}, 0x03000000, 0x0FF00000, .V6T2, .A32, {}, {}},
	},
	.MOVT = {
		{.MOVT, {.GPR, .IMM16_LO_HI, .NONE, .NONE, .NONE, .NONE}, {.RD, .IMM4_IMM12, .NONE, .NONE, .NONE, .NONE}, 0x03400000, 0x0FF00000, .V6T2, .A32, {}, {}},
	},

	// Comparison-only ops: S is implicit-1, Rd is unused (encoded as 0).
	.TST = {
		{.TST, {.GPR, .IMM_MOD, .NONE, .NONE, .NONE, .NONE},     {.RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE, .NONE}, 0x03100000, 0x0FF0F000, .BASE, .A32, {}, {}},
		{.TST, {.GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x01100000, 0x0FF0F010, .BASE, .A32, {}, {}},
		{.TST, {.GPR, .GPR_RSR, .NONE, .NONE, .NONE, .NONE},     {.RN_A32, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x01100010, 0x0FF0F090, .BASE, .A32, {}, {}},
	},
	.TEQ = {
		{.TEQ, {.GPR, .IMM_MOD, .NONE, .NONE, .NONE, .NONE},     {.RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE, .NONE}, 0x03300000, 0x0FF0F000, .BASE, .A32, {}, {}},
		{.TEQ, {.GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x01300000, 0x0FF0F010, .BASE, .A32, {}, {}},
		{.TEQ, {.GPR, .GPR_RSR, .NONE, .NONE, .NONE, .NONE},     {.RN_A32, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x01300010, 0x0FF0F090, .BASE, .A32, {}, {}},
	},
	.CMP = {
		{.CMP, {.GPR, .IMM_MOD, .NONE, .NONE, .NONE, .NONE},     {.RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE, .NONE}, 0x03500000, 0x0FF0F000, .BASE, .A32, {}, {}},
		{.CMP, {.GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x01500000, 0x0FF0F010, .BASE, .A32, {}, {}},
		{.CMP, {.GPR, .GPR_RSR, .NONE, .NONE, .NONE, .NONE},     {.RN_A32, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x01500010, 0x0FF0F090, .BASE, .A32, {}, {}},
	},
	.CMN = {
		{.CMN, {.GPR, .IMM_MOD, .NONE, .NONE, .NONE, .NONE},     {.RN_A32, .A32_IMM_MOD, .NONE, .NONE, .NONE, .NONE}, 0x03700000, 0x0FF0F000, .BASE, .A32, {}, {}},
		{.CMN, {.GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x01700000, 0x0FF0F010, .BASE, .A32, {}, {}},
		{.CMN, {.GPR, .GPR_RSR, .NONE, .NONE, .NONE, .NONE},     {.RN_A32, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x01700010, 0x0FF0F090, .BASE, .A32, {}, {}},
	},

	// =========================================================================
	// §2 -- A32 Multiply family
	// =========================================================================
	//   Encoding layout:
	//     cond 0000 00 A S Rd Rn Rs 1001 Rm     (MUL/MLA)
	//     cond 0000 1 U A S RdHi RdLo Rs 1001 Rm  (UMULL/UMLAL/SMULL/SMLAL)
	//     cond 0000 0110 Rd Ra Rm 1001 Rn       (MLS)
	//     cond 0000 0100 RdHi RdLo Rm 1001 Rn   (UMAAL)
	//
	//   The 1001 nibble at bits 7-4 is the discriminator from data-proc reg.

	.MUL = {
		{.MUL, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE, .NONE, .NONE}, 0x00000090, 0x0FE000F0, .BASE, .A32, {}, {}},
		{.MUL, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE, .NONE, .NONE}, 0x00100090, 0x0FF000F0, .BASE, .A32, {sets_flags=true}, {}},
	},
	.MLA = {
		{.MLA, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .RD, .NONE, .NONE}, 0x00200090, 0x0FE000F0, .BASE, .A32, {}, {}},
		{.MLA, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .RD, .NONE, .NONE}, 0x00300090, 0x0FF000F0, .BASE, .A32, {sets_flags=true}, {}},
	},
	.MLS = {
		{.MLS, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .RD, .NONE, .NONE}, 0x00600090, 0x0FF000F0, .V6T2, .A32, {}, {}},
	},
	.UMULL = {
		{.UMULL, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32, .NONE, .NONE}, 0x00800090, 0x0FE000F0, .BASE, .A32, {}, {}},
		{.UMULL, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32, .NONE, .NONE}, 0x00900090, 0x0FF000F0, .BASE, .A32, {sets_flags=true}, {}},
	},
	.UMLAL = {
		{.UMLAL, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32, .NONE, .NONE}, 0x00A00090, 0x0FE000F0, .BASE, .A32, {}, {}},
		{.UMLAL, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32, .NONE, .NONE}, 0x00B00090, 0x0FF000F0, .BASE, .A32, {sets_flags=true}, {}},
	},
	.SMULL = {
		{.SMULL, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32, .NONE, .NONE}, 0x00C00090, 0x0FE000F0, .BASE, .A32, {}, {}},
		{.SMULL, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32, .NONE, .NONE}, 0x00D00090, 0x0FF000F0, .BASE, .A32, {sets_flags=true}, {}},
	},
	.SMLAL = {
		{.SMLAL, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32, .NONE, .NONE}, 0x00E00090, 0x0FE000F0, .BASE, .A32, {}, {}},
		{.SMLAL, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32, .NONE, .NONE}, 0x00F00090, 0x0FF000F0, .BASE, .A32, {sets_flags=true}, {}},
	},
	// (MLA/MLS/UMULL/UMLAL/SMULL/SMLAL declared earlier in MUL block region.)
	.UMAAL = {
		{.UMAAL, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32, .NONE, .NONE}, 0x00400090, 0x0FF000F0, .V6, .A32, {}, {}},
	},

	// ARMv5TE halfword multiply (SMLAxy / SMULxy / SMLAWy / SMULWy / SMLALxy)
	// Encoding: cond 00010 op0 op1 Rd Rn Rs 1 y x 0 Rm
	//   op0/op1 distinguishes family. x/y selects top/bottom halfword of Rm/Rs.
	.SMLABB = { {.SMLABB, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .RD, .NONE, .NONE}, 0x01000080, 0x0FF000F0, .V5TE, .A32, {}, {}} },
	.SMLABT = { {.SMLABT, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .RD, .NONE, .NONE}, 0x010000C0, 0x0FF000F0, .V5TE, .A32, {}, {}} },
	.SMLATB = { {.SMLATB, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .RD, .NONE, .NONE}, 0x010000A0, 0x0FF000F0, .V5TE, .A32, {}, {}} },
	.SMLATT = { {.SMLATT, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .RD, .NONE, .NONE}, 0x010000E0, 0x0FF000F0, .V5TE, .A32, {}, {}} },
	.SMLAWB = { {.SMLAWB, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .RD, .NONE, .NONE}, 0x01200080, 0x0FF000F0, .V5TE, .A32, {}, {}} },
	.SMLAWT = { {.SMLAWT, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .RD, .NONE, .NONE}, 0x012000C0, 0x0FF000F0, .V5TE, .A32, {}, {}} },
	.SMULBB = { {.SMULBB, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE, .NONE, .NONE}, 0x01600080, 0x0FF0F0F0, .V5TE, .A32, {}, {}} },
	.SMULBT = { {.SMULBT, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE, .NONE, .NONE}, 0x016000C0, 0x0FF0F0F0, .V5TE, .A32, {}, {}} },
	.SMULTB = { {.SMULTB, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE, .NONE, .NONE}, 0x016000A0, 0x0FF0F0F0, .V5TE, .A32, {}, {}} },
	.SMULTT = { {.SMULTT, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE, .NONE, .NONE}, 0x016000E0, 0x0FF0F0F0, .V5TE, .A32, {}, {}} },
	.SMULWB = { {.SMULWB, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE, .NONE, .NONE}, 0x012000A0, 0x0FF0F0F0, .V5TE, .A32, {}, {}} },
	.SMULWT = { {.SMULWT, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE, .NONE, .NONE}, 0x012000E0, 0x0FF0F0F0, .V5TE, .A32, {}, {}} },
	.SMLALBB = { {.SMLALBB, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32, .NONE, .NONE}, 0x01400080, 0x0FF000F0, .V5TE, .A32, {}, {}} },
	.SMLALBT = { {.SMLALBT, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32, .NONE, .NONE}, 0x014000C0, 0x0FF000F0, .V5TE, .A32, {}, {}} },
	.SMLALTB = { {.SMLALTB, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32, .NONE, .NONE}, 0x014000A0, 0x0FF000F0, .V5TE, .A32, {}, {}} },
	.SMLALTT = { {.SMLALTT, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32, .NONE, .NONE}, 0x014000E0, 0x0FF000F0, .V5TE, .A32, {}, {}} },

	// ARMv6: dual multiply
	.SMUAD   = { {.SMUAD,   {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE, .NONE, .NONE}, 0x0700F010, 0x0FF0F0F0, .V6, .A32, {}, {}} },
	.SMUADX  = { {.SMUADX,  {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE, .NONE, .NONE}, 0x0700F030, 0x0FF0F0F0, .V6, .A32, {}, {}} },
	.SMUSD   = { {.SMUSD,   {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE, .NONE, .NONE}, 0x0700F050, 0x0FF0F0F0, .V6, .A32, {}, {}} },
	.SMUSDX  = { {.SMUSDX,  {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE, .NONE, .NONE}, 0x0700F070, 0x0FF0F0F0, .V6, .A32, {}, {}} },
	.SMLAD   = { {.SMLAD,   {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .RD, .NONE, .NONE}, 0x07000010, 0x0FF000F0, .V6, .A32, {}, {}} },
	.SMLADX  = { {.SMLADX,  {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .RD, .NONE, .NONE}, 0x07000030, 0x0FF000F0, .V6, .A32, {}, {}} },
	.SMLSD   = { {.SMLSD,   {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .RD, .NONE, .NONE}, 0x07000050, 0x0FF000F0, .V6, .A32, {}, {}} },
	.SMLSDX  = { {.SMLSDX,  {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .RD, .NONE, .NONE}, 0x07000070, 0x0FF000F0, .V6, .A32, {}, {}} },
	.SMLALD  = { {.SMLALD,  {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32, .NONE, .NONE}, 0x07400010, 0x0FF000F0, .V6, .A32, {}, {}} },
	.SMLALDX = { {.SMLALDX, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32, .NONE, .NONE}, 0x07400030, 0x0FF000F0, .V6, .A32, {}, {}} },
	.SMLSLD  = { {.SMLSLD,  {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32, .NONE, .NONE}, 0x07400050, 0x0FF000F0, .V6, .A32, {}, {}} },
	.SMLSLDX = { {.SMLSLDX, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32, .NONE, .NONE}, 0x07400070, 0x0FF000F0, .V6, .A32, {}, {}} },

	// Most-significant-word multiply (ARMv6)
	.SMMUL  = { {.SMMUL,  {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE, .NONE, .NONE}, 0x0750F010, 0x0FF0F0F0, .V6, .A32, {}, {}} },
	.SMMULR = { {.SMMULR, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE, .NONE, .NONE}, 0x0750F030, 0x0FF0F0F0, .V6, .A32, {}, {}} },
	.SMMLA  = { {.SMMLA,  {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .RD, .NONE, .NONE}, 0x07500010, 0x0FF000F0, .V6, .A32, {}, {}} },
	.SMMLAR = { {.SMMLAR, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .RD, .NONE, .NONE}, 0x07500030, 0x0FF000F0, .V6, .A32, {}, {}} },
	.SMMLS  = { {.SMMLS,  {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .RD, .NONE, .NONE}, 0x075000D0, 0x0FF000F0, .V6, .A32, {}, {}} },
	.SMMLSR = { {.SMMLSR, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .RD, .NONE, .NONE}, 0x075000F0, 0x0FF000F0, .V6, .A32, {}, {}} },

	// ARMv7-A optional / ARMv7-R/M: integer division
	.SDIV = {
		{.SDIV, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE, .NONE, .NONE}, 0x0710F010, 0x0FF0F0F0, .DIV, .A32, {}, {}},
	},
	.UDIV = {
		{.UDIV, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE, .NONE, .NONE}, 0x0730F010, 0x0FF0F0F0, .DIV, .A32, {}, {}},
	},

	// =========================================================================
	// §3 -- Saturating arithmetic + ARMv6 SIMD-on-GPR
	// =========================================================================

	// ARMv5TE saturating arithmetic
	.QADD = {
		{.QADD, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .RN_A32, .NONE, .NONE, .NONE}, 0x01000050, 0x0FF000F0, .V5TE, .A32, {}, {}},
	},
	.QSUB = {
		{.QSUB, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .RN_A32, .NONE, .NONE, .NONE}, 0x01200050, 0x0FF000F0, .V5TE, .A32, {}, {}},
	},
	.QDADD = {
		{.QDADD, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .RN_A32, .NONE, .NONE, .NONE}, 0x01400050, 0x0FF000F0, .V5TE, .A32, {}, {}},
	},
	.QDSUB = {
		{.QDSUB, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .RN_A32, .NONE, .NONE, .NONE}, 0x01600050, 0x0FF000F0, .V5TE, .A32, {}, {}},
	},

	// ARMv6 signed parallel arithmetic (8-bit and 16-bit lanes)
	//   cond 0110 0001 Rn Rd 1111 op Rm    -- op selects ADD/SUB/SUB16/etc.
	//   The "op" field at bits 7:4 distinguishes:
	//     0001 ADD16  0011 ASX    0101 SAX    0111 SUB16
	//     1001 ADD8   1111 SUB8
	.SADD16 = {
		{.SADD16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06100F10, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.SASX = {
		{.SASX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06100F30, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.SSAX = {
		{.SSAX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06100F50, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.SSUB16 = {
		{.SSUB16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06100F70, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.SADD8 = {
		{.SADD8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06100F90, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.SSUB8 = {
		{.SSUB8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06100FF0, 0x0FF00FF0, .V6, .A32, {}, {}},
	},

	// ARMv6 saturating parallel arithmetic (op family 0110 0010)
	// Q* (signed saturating): T32 bits 6:4 = 001
	.QADD16 = {
		{.QADD16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06200F10, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.QASX = {
		{.QASX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06200F30, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.QSAX = {
		{.QSAX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06200F50, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.QSUB16 = {
		{.QSUB16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06200F70, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.QADD8 = {
		{.QADD8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06200F90, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.QSUB8 = {
		{.QSUB8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06200FF0, 0x0FF00FF0, .V6, .A32, {}, {}},
	},

	// ARMv6 signed halving (T32 bits 6:4 = 010)
	.SHADD16 = {
		{.SHADD16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06300F10, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.SHASX = {
		{.SHASX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06300F30, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.SHSAX = {
		{.SHSAX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06300F50, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.SHSUB16 = {
		{.SHSUB16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06300F70, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.SHADD8 = {
		{.SHADD8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06300F90, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.SHSUB8 = {
		{.SHSUB8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06300FF0, 0x0FF00FF0, .V6, .A32, {}, {}},
	},

	// ARMv6 unsigned parallel arithmetic (op family 0110 0101)
	.UADD16 = {
		{.UADD16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06500F10, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.UASX = {
		{.UASX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06500F30, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.USAX = {
		{.USAX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06500F50, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.USUB16 = {
		{.USUB16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06500F70, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.UADD8 = {
		{.UADD8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06500F90, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.USUB8 = {
		{.USUB8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06500FF0, 0x0FF00FF0, .V6, .A32, {}, {}},
	},

	// ARMv6 unsigned saturating (T32 bits 6:4 = 101)
	.UQADD16 = {
		{.UQADD16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06600F10, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.UQASX = {
		{.UQASX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06600F30, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.UQSAX = {
		{.UQSAX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06600F50, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.UQSUB16 = {
		{.UQSUB16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06600F70, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.UQADD8 = {
		{.UQADD8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06600F90, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.UQSUB8 = {
		{.UQSUB8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06600FF0, 0x0FF00FF0, .V6, .A32, {}, {}},
	},

	// ARMv6 unsigned halving (T32 bits 6:4 = 110)
	.UHADD16 = {
		{.UHADD16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06700F10, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.UHASX = {
		{.UHASX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06700F30, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.UHSAX = {
		{.UHSAX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06700F50, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.UHSUB16 = {
		{.UHSUB16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06700F70, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.UHADD8 = {
		{.UHADD8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06700F90, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.UHSUB8 = {
		{.UHSUB8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06700FF0, 0x0FF00FF0, .V6, .A32, {}, {}},
	},

	// ARMv6 saturate to width
	.SSAT = {
		{.SSAT, {.GPR, .IMM4_SAT, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .SAT_IMM5, .RM_A32, .NONE, .NONE, .NONE}, 0x06A00010, 0x0FE00030, .V6, .A32, {}, {}},
	},
	.USAT = {
		{.USAT, {.GPR, .IMM4_SAT, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .SAT_IMM5_U, .RM_A32, .NONE, .NONE, .NONE}, 0x06E00010, 0x0FE00030, .V6, .A32, {}, {}},
	},
	.SSAT16 = {
		{.SSAT16, {.GPR, .IMM4_SAT, .GPR, .NONE, .NONE, .NONE}, {.RD, .SAT_IMM5, .RM_A32, .NONE, .NONE, .NONE}, 0x06A00F30, 0x0FF00FF0, .V6, .A32, {}, {}},
	},
	.USAT16 = {
		{.USAT16, {.GPR, .IMM4_SAT, .GPR, .NONE, .NONE, .NONE}, {.RD, .SAT_IMM5_U, .RM_A32, .NONE, .NONE, .NONE}, 0x06E00F30, 0x0FF00FF0, .V6, .A32, {}, {}},
	},

	// ARMv6 USAD8 / USADA8
	.USAD8  = { {.USAD8,  {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE, .NONE, .NONE}, 0x0780F010, 0x0FF0F0F0, .V6, .A32, {}, {}} },
	.USADA8 = { {.USADA8, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .RD, .NONE, .NONE},    0x07800010, 0x0FF000F0, .V6, .A32, {}, {}} },

	// =========================================================================
	// §4 -- Extends + bit-field + REV + CLZ + RBIT + SEL + PKHBT/TB
	// =========================================================================

	// PKHBT / PKHTB (pack halfword)
	//   PKHBT: cond 0110 1000 Rn Rd shift_imm 001 Rm
	//   PKHTB: cond 0110 1000 Rn Rd shift_imm 101 Rm
	.PKHBT = { {.PKHBT, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06800010, 0x0FF00070, .V6, .A32, {}, {}} },
	.PKHTB = { {.PKHTB, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06800050, 0x0FF00070, .V6, .A32, {}, {}} },

	// Sign-extend / zero-extend (with optional rotation of Rm by 0/8/16/24)
	// Encoding: cond 0110 1xx0 1111 Rd rotate 0 0 0111 Rm   -- variant 1 (no Rn)
	//           cond 0110 1xx0 Rn   Rd rotate 0 0 0111 Rm   -- variant 2 (with Rn = SXTAB/etc.)
	.SXTB = {
		{.SXTB, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD, .RM_A32_ROTATED, .NONE, .NONE, .NONE, .NONE}, 0x06AF0070, 0x0FFF03F0, .V6, .A32, {}, {}},
	},
	.SXTB16 = {
		{.SXTB16, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD, .RM_A32_ROTATED, .NONE, .NONE, .NONE, .NONE}, 0x068F0070, 0x0FFF03F0, .V6, .A32, {}, {}},
	},
	.SXTH = {
		{.SXTH, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD, .RM_A32_ROTATED, .NONE, .NONE, .NONE, .NONE}, 0x06BF0070, 0x0FFF03F0, .V6, .A32, {}, {}},
	},
	.UXTB = {
		{.UXTB, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD, .RM_A32_ROTATED, .NONE, .NONE, .NONE, .NONE}, 0x06EF0070, 0x0FFF03F0, .V6, .A32, {}, {}},
	},
	.UXTB16 = {
		{.UXTB16, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD, .RM_A32_ROTATED, .NONE, .NONE, .NONE, .NONE}, 0x06CF0070, 0x0FFF03F0, .V6, .A32, {}, {}},
	},
	.UXTH = {
		{.UXTH, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD, .RM_A32_ROTATED, .NONE, .NONE, .NONE, .NONE}, 0x06FF0070, 0x0FFF03F0, .V6, .A32, {}, {}},
	},
	.SXTAB = {
		{.SXTAB, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32_ROTATED, .NONE, .NONE, .NONE}, 0x06A00070, 0x0FF003F0, .V6, .A32, {}, {}},
	},
	.SXTAB16 = {
		{.SXTAB16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32_ROTATED, .NONE, .NONE, .NONE}, 0x06800070, 0x0FF003F0, .V6, .A32, {}, {}},
	},
	.SXTAH = {
		{.SXTAH, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32_ROTATED, .NONE, .NONE, .NONE}, 0x06B00070, 0x0FF003F0, .V6, .A32, {}, {}},
	},
	.UXTAB = {
		{.UXTAB, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32_ROTATED, .NONE, .NONE, .NONE}, 0x06E00070, 0x0FF003F0, .V6, .A32, {}, {}},
	},
	.UXTAB16 = {
		{.UXTAB16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32_ROTATED, .NONE, .NONE, .NONE}, 0x06C00070, 0x0FF003F0, .V6, .A32, {}, {}},
	},
	.UXTAH = {
		{.UXTAH, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32_ROTATED, .NONE, .NONE, .NONE}, 0x06F00070, 0x0FF003F0, .V6, .A32, {}, {}},
	},

	// Byte-reverse / count leading zeros / select / reverse bits
	.REV = {
		{.REV, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x06BF0F30, 0x0FFF0FF0, .V6, .A32, {}, {}},
	},
	.REV16 = {
		{.REV16, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x06BF0FB0, 0x0FFF0FF0, .V6, .A32, {}, {}},
	},
	.REVSH = {
		{.REVSH, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x06FF0FB0, 0x0FFF0FF0, .V6, .A32, {}, {}},
	},
	.RBIT = {
		{.RBIT, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x06FF0F30, 0x0FFF0FF0, .V6T2, .A32, {}, {}},
	},
	.CLZ = {
		{.CLZ, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x016F0F10, 0x0FFF0FF0, .V5T, .A32, {}, {}},
	},
	.SEL   = { {.SEL,   {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0x06800FB0, 0x0FF00FF0, .V6, .A32, {}, {}} },

	// Bit field operations (ARMv6T2)
	.BFC = {
		{.BFC, {.GPR, .IMM5, .IMM5_W, .NONE, .NONE, .NONE}, {.RD, .BFI_LSB, .BFI_MSB, .NONE, .NONE, .NONE}, 0x07C0001F, 0x0FE0007F, .V6T2, .A32, {}, {}},
	},
	.BFI = {
		{.BFI, {.GPR, .GPR, .IMM5, .IMM5_W, .NONE, .NONE}, {.RD, .RM_A32, .BFI_LSB, .BFI_MSB, .NONE, .NONE}, 0x07C00010, 0x0FE00070, .V6T2, .A32, {}, {}},
	},
	.SBFX = {
		{.SBFX, {.GPR, .GPR, .IMM5, .IMM5_W, .NONE, .NONE}, {.RD, .RM_A32, .BFI_LSB, .BFX_WIDTH, .NONE, .NONE}, 0x07A00050, 0x0FE00070, .V6T2, .A32, {}, {}},
	},
	.UBFX = {
		{.UBFX, {.GPR, .GPR, .IMM5, .IMM5_W, .NONE, .NONE}, {.RD, .RM_A32, .BFI_LSB, .BFX_WIDTH, .NONE, .NONE}, 0x07E00050, 0x0FE00070, .V6T2, .A32, {}, {}},
	},

	// =========================================================================
	// §5 -- Branches, status reg access, exception generation
	// =========================================================================

	// B / BL: cond 101 L imm24
	.B = {
		{.B, {.REL24, .NONE, .NONE, .NONE, .NONE, .NONE}, {.BRANCH_24, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x0A000000, 0x0F000000, .BASE, .A32, {branch=true, cond_branch=true, writes_pc=true}, {}},
	},
	.BL = {
		{.BL, {.REL24, .NONE, .NONE, .NONE, .NONE, .NONE}, {.BRANCH_24, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x0B000000, 0x0F000000, .BASE, .A32, {branch=true, cond_branch=true, writes_pc=true}, {}},
	},

	// BX / BLX (register form) -- ARMv4T+ for BX, ARMv5T+ for BLX_reg
	.BX = {
		{.BX, {.GPR, .NONE, .NONE, .NONE, .NONE, .NONE}, {.RM_A32, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x012FFF10, 0x0FFFFFF0, .BASE, .A32, {branch=true, writes_pc=true}, {}},
	},
	.BLX = {
		// BLX register: cond 0001 0010 1111 1111 1111 0011 Rm
		{.BLX, {.GPR, .NONE, .NONE, .NONE, .NONE, .NONE}, {.RM_A32, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x012FFF30, 0x0FFFFFF0, .V5T, .A32, {branch=true, writes_pc=true}, {}},
		// BLX immediate (unconditional class): 1111 101 H imm24  -- H=bit24 toggles ARM/Thumb
		{.BLX, {.REL24, .NONE, .NONE, .NONE, .NONE, .NONE}, {.BRANCH_BLX_A32, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xFA000000, 0xFE000000, .V5T, .A32, {branch=true, writes_pc=true, cond_in_28=false}, {}},
	},
	.BXJ = { {.BXJ, {.GPR, .NONE, .NONE, .NONE, .NONE, .NONE}, {.RM_A32, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x012FFF20, 0x0FFFFFF0, .V5TEJ, .A32, {branch=true, writes_pc=true, deprecated=true}, {}} },

	// SVC (was SWI): cond 1111 imm24
	.SVC = {
		{.SVC, {.IMM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.A32_IMM24, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x0F000000, 0x0F000000, .BASE, .A32, {}, {}},
	},
	// BKPT (unconditional class but uses cond=NV reserved encoding traditionally):
	//   cond 0001 0010 imm12 0111 imm4   (cond=AL only)
	.BKPT = {
		{.BKPT, {.IMM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.IMM12_IMM4, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xE1200070, 0xFFF000F0, .V5T, .A32, {cond_in_28=false}, {}},
	},
	// HVC: 0001 0100 imm12 0111 imm4
	.HVC  = { {.HVC,  {.IMM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.IMM12_IMM4, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xE1400070, 0xFFF000F0, .V7VE, .A32, {cond_in_28=false}, {}} },
	// SMC: cond 0001 0110 0000 0000 0000 0111 imm4
	.SMC  = { {.SMC,  {.IMM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.A32_IMM4, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x01600070, 0x0FFFFFF0, .V7,   .A32, {}, {}} },
	// UDF: 1111 0111 1111 imm12 1111 imm4   (permanently undefined)
	.UDF = {
		{.UDF, {.IMM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.IMM12_IMM4, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xE7F000F0, 0xFFF000F0, .BASE, .A32, {cond_in_28=false}, {}},
	},
	// HLT (ARMv8 AArch32): 0001 0000 imm12 0111 imm4
	.HLT  = { {.HLT,  {.IMM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.IMM12_IMM4, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xE1000070, 0xFFF000F0, .V8,   .A32, {cond_in_28=false}, {}} },

	// MSR / MRS (status reg access)
	.MRS = {
		{.MRS, {.GPR, .PSR_FIELD, .NONE, .NONE, .NONE, .NONE}, {.RD, .MRS_SPEC_REG, .NONE, .NONE, .NONE, .NONE}, 0x010F0000, 0x0FBF0FFF, .BASE, .A32, {}, {}},
	},
	.MSR = {
		// MSR APSR_<fields>, #imm12_mod (immediate form)
		{.MSR, {.PSR_FIELD, .IMM_MOD, .NONE, .NONE, .NONE, .NONE},  {.PSR_FIELD_MASK, .A32_IMM_MOD, .NONE, .NONE, .NONE, .NONE}, 0x0320F000, 0x0FB0F000, .BASE, .A32, {}, {}},
		// MSR APSR_<fields>, Rn (register form)
		{.MSR, {.PSR_FIELD, .GPR, .NONE, .NONE, .NONE, .NONE},      {.PSR_FIELD_MASK, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x0120F000, 0x0FB0FFF0, .BASE, .A32, {}, {}},
	},

	// CPS (change processor state, ARMv6): 1111 0001 0000 imod M iflags mode_field
	// 1111 0001 0000 imod M 0 (0000000) A I F 0 mode: IE is imod 10, ID 11;
	// M says whether the mode changes too, and with imod 00 it is all CPS does.
	.CPS = { {.CPS, {.IMM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.MODE_IMM5, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF1020000, 0xFFFFFFE0, .V6, .A32, {cond_in_28=false, a_profile_only=true}, {}} },
	.CPSIE = {
		{.CPSIE, {.IMM_IFLAGS, .NONE, .NONE, .NONE, .NONE, .NONE}, {.CPS_IFLAGS_A32, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF1080000, 0xFFFFFE3F, .V6, .A32, {cond_in_28=false}, {}},
		{.CPSIE, {.IMM_IFLAGS, .IMM, .NONE, .NONE, .NONE, .NONE}, {.CPS_IFLAGS_A32, .MODE_IMM5, .NONE, .NONE, .NONE, .NONE}, 0xF10A0000, 0xFFFFFE20, .V6, .A32, {cond_in_28=false}, {}},
	},
	.CPSID = {
		{.CPSID, {.IMM_IFLAGS, .NONE, .NONE, .NONE, .NONE, .NONE}, {.CPS_IFLAGS_A32, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF10C0000, 0xFFFFFE3F, .V6, .A32, {cond_in_28=false}, {}},
		{.CPSID, {.IMM_IFLAGS, .IMM, .NONE, .NONE, .NONE, .NONE}, {.CPS_IFLAGS_A32, .MODE_IMM5, .NONE, .NONE, .NONE, .NONE}, 0xF10E0000, 0xFFFFFE20, .V6, .A32, {cond_in_28=false}, {}},
	},

	// SETEND (deprecated in ARMv8): 1111 0001 0000 0001 0000 000E 0000 0000
	.SETEND = { {.SETEND, {.IMM_ENDIAN, .NONE, .NONE, .NONE, .NONE, .NONE}, {.SETEND_ENDIAN, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF1010000, 0xFFFFFDFF, .V6, .A32, {cond_in_28=false, deprecated=true}, {}} },

	// SETPAN (ARMv8.1): A32 = 1111 0001 0001 0000 0000 0000 imm1 0000 0000  → bit 9 = imm
	// T16:               1011 0110 0001 0 imm1 000                          → bit 3 = imm
	.SETPAN = {
		{.SETPAN, {.IMM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.SETPAN_IMM_A32, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF1100000, 0xFFFFFDFF, .V8, .A32, {cond_in_28=false}, {}},
	},

	// ---- Hint instructions (cond 0011 0010 0000 1111 0000 0000 imm8 OR encoded form)
	.NOP = {
		{.NOP, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x0320F000, 0x0FFFFFFF, .V6K, .A32, {}, {}},
	},
	.YIELD = {
		{.YIELD, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x0320F001, 0x0FFFFFFF, .V6K, .A32, {}, {}},
	},
	.WFE = {
		{.WFE, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x0320F002, 0x0FFFFFFF, .V6K, .A32, {}, {}},
	},
	.WFI = {
		{.WFI, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x0320F003, 0x0FFFFFFF, .V6K, .A32, {}, {}},
	},
	.SEV = {
		{.SEV, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x0320F004, 0x0FFFFFFF, .V6K, .A32, {}, {}},
	},
	.SEVL = { {.SEVL, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x0320F005, 0x0FFFFFFF, .V8,  .A32, {}, {}} },
	.DBG  = { {.DBG,  {.IMM_HINT, .NONE, .NONE, .NONE, .NONE, .NONE}, {.DBG_OPTION, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x0320F0F0, 0x0FFFFFF0, .V7, .A32, {}, {}} },
	.HINT = { {.HINT, {.IMM_HINT, .NONE, .NONE, .NONE, .NONE, .NONE}, {.HINT_FIELD, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x0320F000, 0x0FFFFF00, .V6K, .A32, {}, {}} },

	// Memory barriers (ARMv7): 1111 0101 0111 1111 1111 0000 type imm4
	.DMB = {
		{.DMB, {.IMM_BARRIER, .NONE, .NONE, .NONE, .NONE, .NONE}, {.BARRIER_TYPE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF57FF050, 0xFFFFFFF0, .V7, .A32, {cond_in_28=false}, {}},
	},
	.DSB = {
		{.DSB, {.IMM_BARRIER, .NONE, .NONE, .NONE, .NONE, .NONE}, {.BARRIER_TYPE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF57FF040, 0xFFFFFFF0, .V7, .A32, {cond_in_28=false}, {}},
	},
	.ISB = {
		{.ISB, {.IMM_BARRIER, .NONE, .NONE, .NONE, .NONE, .NONE}, {.BARRIER_TYPE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF57FF060, 0xFFFFFFF0, .V7, .A32, {cond_in_28=false}, {}},
	},

	// ---- HINT-family barriers (ARMv8 FEAT_RAS / FEAT_SPE / FEAT_TRF / FEAT_CSV2) ----
	// A32: cond 0011 0010 0000 1111 0000 0000 imm8 (HINT with specific imm)
	// T32: 1111 0011 1010 1111 1000 0000 imm8

	// ESB (Error Synchronization Barrier, FEAT_RAS) -- HINT #16
	.ESB = {
		{.ESB, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x0320F010, 0x0FFFFFFF, .V8, .A32, {}, {}},
	},
	// TSB CSYNC (Trace Synchronization Barrier, FEAT_TRF) -- HINT #18
	.TSB_CSYNC = {
		{.TSB_CSYNC, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xE320F012, 0xFFFFFFFF, .V8, .A32, {cond_in_28=false}, {}},
	},
	// CSDB (Consumption of Speculative Data Barrier, FEAT_CSV2) -- HINT #20
	.CSDB = {
		{.CSDB, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x0320F014, 0x0FFFFFFF, .V8, .A32, {}, {}},
	},
	// SB (Synchronization Barrier, FEAT_SB, ARMv8.5) -- dedicated barrier encoding
	// A32: 1111 0101 0111 1111 1111 0000 0111 0000 = 0xF57FF070
	// T32: 1111 0011 1011 1111 1000 1111 0111 0000 = 0xF3BF8F70
	.SB = {
		{.SB, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF57FF070, 0xFFFFFFFF, .V8, .A32, {cond_in_28=false}, {}},
	},

	// CLREX (clear exclusive monitor, ARMv6K+)
	.CLREX = {
		{.CLREX, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF57FF01F, 0xFFFFFFFF, .V6K, .A32, {cond_in_28=false}, {}},
	},

	// Preload data / instruction (PLD/PLDW/PLI)
	.PLD = {
		{.PLD, {.MEM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.MEM_IMM12_OFFSET, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF5D0F000, 0xFFF0F000, .V5T, .A32, {cond_in_28=false}, {}},
	},
	.PLDW = {
		{.PLDW, {.MEM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.MEM_IMM12_OFFSET, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF5D0F000, 0xFFF0F000, .V7, .A32, {cond_in_28=false}, {}},
	},
	.PLI = {
		{.PLI, {.MEM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.MEM_IMM12_OFFSET, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF450F000, 0xFF70F000, .V7, .A32, {cond_in_28=false}, {}},
	},

	// ERET (exception return, ARMv7VE+)
	.ERET = { {.ERET, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x0160006E, 0x0FFFFFFF, .V7VE, .A32, {writes_pc=true}, {}} },

	// =========================================================================
	// §6 -- Load / Store (single + multiple)
	// =========================================================================

	// LDR / STR (word) -- immediate offset:
	//   cond 010 P U 0 W 1/0 Rn Rt imm12     (P=pre/U=add/W=writeback/0=str/1=ldr)
	// We split into three variants per direction: imm-offset, pre-index, post-index.
	.LDR = {
		// LDR imm12 offset: P=1 W=0
		{.LDR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_IMM12_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0x05100000, 0x0F700000, .BASE, .A32, {}, {}},
		// LDR imm12 pre-index: P=1 W=1
		{.LDR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_PRE_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x05300000, 0x0F700000, .BASE, .A32, {}, {}},
		// LDR imm12 post-index: P=0 W=0
		{.LDR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x04100000, 0x0F700000, .BASE, .A32, {}, {}},
		// LDR reg offset: cond 011 P U 0 W 1 Rn Rt shift_imm shift_type 0 Rm
		{.LDR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_SHIFTED, .NONE, .NONE, .NONE, .NONE}, 0x07100000, 0x0F700010, .BASE, .A32, {}, {}},
		{.LDR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_SHIFTED_PRE, .NONE, .NONE, .NONE, .NONE}, 0x07300000, 0x0F700010, .BASE, .A32, {}, {}},
		{.LDR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_SHIFTED_POST, .NONE, .NONE, .NONE, .NONE}, 0x06100000, 0x0F700010, .BASE, .A32, {}, {}},
	},
	.STR = {
		{.STR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_IMM12_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0x05000000, 0x0F700000, .BASE, .A32, {}, {}},
		{.STR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_PRE_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x05200000, 0x0F700000, .BASE, .A32, {}, {}},
		{.STR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x04000000, 0x0F700000, .BASE, .A32, {}, {}},
		{.STR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_SHIFTED, .NONE, .NONE, .NONE, .NONE}, 0x07000000, 0x0F700010, .BASE, .A32, {}, {}},
		{.STR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_SHIFTED_PRE, .NONE, .NONE, .NONE, .NONE}, 0x07200000, 0x0F700010, .BASE, .A32, {}, {}},
		{.STR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_SHIFTED_POST, .NONE, .NONE, .NONE, .NONE}, 0x06000000, 0x0F700010, .BASE, .A32, {}, {}},
	},
	.LDRB = {
		{.LDRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_IMM12_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0x05500000, 0x0F700000, .BASE, .A32, {}, {}},
		{.LDRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_PRE_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x05700000, 0x0F700000, .BASE, .A32, {}, {}},
		{.LDRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x04500000, 0x0F700000, .BASE, .A32, {}, {}},
		{.LDRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_SHIFTED, .NONE, .NONE, .NONE, .NONE}, 0x07500000, 0x0F700010, .BASE, .A32, {}, {}},
		{.LDRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_SHIFTED_PRE, .NONE, .NONE, .NONE, .NONE}, 0x07700000, 0x0F700010, .BASE, .A32, {}, {}},
		{.LDRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_SHIFTED_POST, .NONE, .NONE, .NONE, .NONE}, 0x06500000, 0x0F700010, .BASE, .A32, {}, {}},
	},
	.STRB = {
		{.STRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_IMM12_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0x05400000, 0x0F700000, .BASE, .A32, {}, {}},
		{.STRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_PRE_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x05600000, 0x0F700000, .BASE, .A32, {}, {}},
		{.STRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x04400000, 0x0F700000, .BASE, .A32, {}, {}},
		{.STRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_SHIFTED, .NONE, .NONE, .NONE, .NONE}, 0x07400000, 0x0F700010, .BASE, .A32, {}, {}},
		{.STRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_SHIFTED_PRE, .NONE, .NONE, .NONE, .NONE}, 0x07600000, 0x0F700010, .BASE, .A32, {}, {}},
		{.STRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_SHIFTED_POST, .NONE, .NONE, .NONE, .NONE}, 0x06400000, 0x0F700010, .BASE, .A32, {}, {}},
	},

	// LDRH / STRH / LDRSB / LDRSH / LDRD / STRD: cond 000 P U I W L Rn Rt imm4H 1 op2 1 imm4L
	//   where op2 = 01 (halfword), 10 (signed byte), 11 (signed half / doubleword)
	.LDRH = {
		// LDRH imm offset (P=1 W=0): cond 000 1 U 1 0 1 Rn Rt imm4H 1011 imm4L
		{.LDRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_IMM8_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0x015000B0, 0x0F7000F0, .BASE, .A32, {}, {}},
		{.LDRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_IMM8_PRE_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x017000B0, 0x0F7000F0, .BASE, .A32, {}, {}},
		{.LDRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_IMM8_POST_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x005000B0, 0x0F7000F0, .BASE, .A32, {}, {}},
		// LDRH reg offset: cond 000 1 U 0 0 1 Rn Rt 0000 1011 Rm
		{.LDRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0x011000B0, 0x0F700FF0, .BASE, .A32, {}, {}},
		{.LDRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_PRE, .NONE, .NONE, .NONE, .NONE}, 0x013000B0, 0x0F700FF0, .BASE, .A32, {}, {}},
		{.LDRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_POST, .NONE, .NONE, .NONE, .NONE}, 0x001000B0, 0x0F700FF0, .BASE, .A32, {}, {}},
	},
	.STRH = {
		{.STRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_IMM8_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0x014000B0, 0x0F7000F0, .BASE, .A32, {}, {}},
		{.STRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_IMM8_PRE_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x016000B0, 0x0F7000F0, .BASE, .A32, {}, {}},
		{.STRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_IMM8_POST_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x004000B0, 0x0F7000F0, .BASE, .A32, {}, {}},
		{.STRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0x010000B0, 0x0F700FF0, .BASE, .A32, {}, {}},
		{.STRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_PRE, .NONE, .NONE, .NONE, .NONE}, 0x012000B0, 0x0F700FF0, .BASE, .A32, {}, {}},
		{.STRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_POST, .NONE, .NONE, .NONE, .NONE}, 0x000000B0, 0x0F700FF0, .BASE, .A32, {}, {}},
	},
	.LDRSB = {
		{.LDRSB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_IMM8_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0x015000D0, 0x0F7000F0, .BASE, .A32, {}, {}},
		{.LDRSB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_IMM8_PRE_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x017000D0, 0x0F7000F0, .BASE, .A32, {}, {}},
		{.LDRSB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_IMM8_POST_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x005000D0, 0x0F7000F0, .BASE, .A32, {}, {}},
		{.LDRSB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0x011000D0, 0x0F700FF0, .BASE, .A32, {}, {}},
		{.LDRSB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_PRE, .NONE, .NONE, .NONE, .NONE}, 0x013000D0, 0x0F700FF0, .BASE, .A32, {}, {}},
		{.LDRSB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_POST, .NONE, .NONE, .NONE, .NONE}, 0x001000D0, 0x0F700FF0, .BASE, .A32, {}, {}},
	},
	.LDRSH = {
		{.LDRSH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_IMM8_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0x015000F0, 0x0F7000F0, .BASE, .A32, {}, {}},
		{.LDRSH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_IMM8_PRE_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x017000F0, 0x0F7000F0, .BASE, .A32, {}, {}},
		{.LDRSH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_IMM8_POST_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x005000F0, 0x0F7000F0, .BASE, .A32, {}, {}},
		{.LDRSH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0x011000F0, 0x0F700FF0, .BASE, .A32, {}, {}},
		{.LDRSH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_PRE, .NONE, .NONE, .NONE, .NONE}, 0x013000F0, 0x0F700FF0, .BASE, .A32, {}, {}},
		{.LDRSH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_POST, .NONE, .NONE, .NONE, .NONE}, 0x001000F0, 0x0F700FF0, .BASE, .A32, {}, {}},
	},
	.LDRD = {
		// The pair is an even register and the one after it: bit 12 is 0.
		{.LDRD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_A32, .RT_PAIR_NEXT, .MEM_IMM8_OFFSET, .NONE, .NONE, .NONE}, 0x014000D0, 0x0F7010F0, .V5TE, .A32, {}, {}},
		{.LDRD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_A32, .RT_PAIR_NEXT, .MEM_IMM8_PRE_INDEX, .NONE, .NONE, .NONE}, 0x016000D0, 0x0F7010F0, .V5TE, .A32, {}, {}},
		{.LDRD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_A32, .RT_PAIR_NEXT, .MEM_IMM8_POST_INDEX, .NONE, .NONE, .NONE}, 0x004000D0, 0x0F7010F0, .V5TE, .A32, {}, {}},
		{.LDRD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_A32, .RT_PAIR_NEXT, .MEM_REG_OFFSET, .NONE, .NONE, .NONE}, 0x010000D0, 0x0F701FF0, .V5TE, .A32, {}, {}},
		{.LDRD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_A32, .RT_PAIR_NEXT, .MEM_REG_PRE, .NONE, .NONE, .NONE}, 0x012000D0, 0x0F701FF0, .V5TE, .A32, {}, {}},
		{.LDRD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_A32, .RT_PAIR_NEXT, .MEM_REG_POST, .NONE, .NONE, .NONE}, 0x000000D0, 0x0F701FF0, .V5TE, .A32, {}, {}},
	},
	.STRD = {
		{.STRD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_A32, .RT_PAIR_NEXT, .MEM_IMM8_OFFSET, .NONE, .NONE, .NONE}, 0x014000F0, 0x0F7010F0, .V5TE, .A32, {}, {}},
		{.STRD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_A32, .RT_PAIR_NEXT, .MEM_IMM8_PRE_INDEX, .NONE, .NONE, .NONE}, 0x016000F0, 0x0F7010F0, .V5TE, .A32, {}, {}},
		{.STRD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_A32, .RT_PAIR_NEXT, .MEM_IMM8_POST_INDEX, .NONE, .NONE, .NONE}, 0x004000F0, 0x0F7010F0, .V5TE, .A32, {}, {}},
		{.STRD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_A32, .RT_PAIR_NEXT, .MEM_REG_OFFSET, .NONE, .NONE, .NONE}, 0x010000F0, 0x0F701FF0, .V5TE, .A32, {}, {}},
		{.STRD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_A32, .RT_PAIR_NEXT, .MEM_REG_PRE, .NONE, .NONE, .NONE}, 0x012000F0, 0x0F701FF0, .V5TE, .A32, {}, {}},
		{.STRD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_A32, .RT_PAIR_NEXT, .MEM_REG_POST, .NONE, .NONE, .NONE}, 0x000000F0, 0x0F701FF0, .V5TE, .A32, {}, {}},
	},

	// Load/Store multiple (LDM/STM family). cond 100 P U S W L Rn register_list
	//   IA = P=0 U=1 ; IB = P=1 U=1 ; DA = P=0 U=0 ; DB = P=1 U=0
	//   S=1 selects user-mode register set (LDM/STM exceptional forms)
	//   W=1 writeback. L=1 load / L=0 store.
	// We encode the addressing-mode in the static bits; the encoder OR's
	// base register + register-list into Rn + register_list operand slots.
	.LDM = {
		// LDM IA (default)
		{.LDM, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0x08900000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.LDM, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0x08B00000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.LDM, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST_USER, .NONE, .NONE, .NONE, .NONE}, 0x08D00000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.LDM, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST_USER, .NONE, .NONE, .NONE, .NONE}, 0x08F00000, 0x0FF00000, .BASE, .A32, {}, {}},
	},
	.STM = {
		{.STM, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0x08800000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.STM, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0x08A00000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.STM, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST_USER, .NONE, .NONE, .NONE, .NONE}, 0x08C00000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.STM, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST_USER, .NONE, .NONE, .NONE, .NONE}, 0x08E00000, 0x0FF00000, .BASE, .A32, {}, {}},
	},

	// PUSH / POP are conventional aliases for STMDB SP! / LDMIA SP!
	.PUSH = {
		{.PUSH, {.GPR_LIST, .NONE, .NONE, .NONE, .NONE, .NONE}, {.A32_REG_LIST, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x092D0000, 0x0FFF0000, .BASE, .A32, {}, {}},
	},
	.POP = {
		{.POP,  {.GPR_LIST, .NONE, .NONE, .NONE, .NONE, .NONE}, {.A32_REG_LIST, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x08BD0000, 0x0FFF0000, .BASE, .A32, {}, {}},
	},

	// SWP / SWPB (deprecated since ARMv6)
	.SWP  = { {.SWP,  {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_A32, .RM_A32, .RN_A32, .NONE, .NONE, .NONE}, 0x01000090, 0x0FF00FF0, .BASE, .A32, {deprecated=true}, {}} },
	.SWPB = { {.SWPB, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_A32, .RM_A32, .RN_A32, .NONE, .NONE, .NONE}, 0x01400090, 0x0FF00FF0, .BASE, .A32, {deprecated=true}, {}} },

	// RFE / SRS (return-from-exception / store return state)
	// 1111 100 P U 0 W 1 Rn 0000 1010 0000 0000
	.RFEDA = {
		{.RFEDA, {.GPR, .NONE, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF8100A00, 0xFFF0FFFF, .V6, .A32, {cond_in_28=false}, {}},
		{.RFEDA, {.GPR, .NONE, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF8300A00, 0xFFF0FFFF, .V6, .A32, {cond_in_28=false}, {}},
	},
	.RFEDB = {
		{.RFEDB, {.GPR, .NONE, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF9100A00, 0xFFF0FFFF, .V6, .A32, {cond_in_28=false}, {}},
		{.RFEDB, {.GPR, .NONE, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF9300A00, 0xFFF0FFFF, .V6, .A32, {cond_in_28=false}, {}},
	},
	.RFEIA = {
		{.RFEIA, {.GPR, .NONE, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF8900A00, 0xFFF0FFFF, .V6, .A32, {cond_in_28=false}, {}},
		{.RFEIA, {.GPR, .NONE, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF8B00A00, 0xFFF0FFFF, .V6, .A32, {cond_in_28=false}, {}},
	},
	.RFEIB = {
		{.RFEIB, {.GPR, .NONE, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF9900A00, 0xFFF0FFFF, .V6, .A32, {cond_in_28=false}, {}},
		{.RFEIB, {.GPR, .NONE, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF9B00A00, 0xFFF0FFFF, .V6, .A32, {cond_in_28=false}, {}},
	},
	// 1111 100 P U 1 W 0 1101 0000 0101 000 mode4
	.SRSDA = {
		{.SRSDA, {.GPR, .IMM, .NONE, .NONE, .NONE, .NONE}, {.IMPL_SP, .MODE_IMM5, .NONE, .NONE, .NONE, .NONE}, 0xF84D0500, 0xFFFFFFE0, .V6, .A32, {cond_in_28=false}, {}},
		{.SRSDA, {.GPR, .IMM, .NONE, .NONE, .NONE, .NONE}, {.IMPL_SP, .MODE_IMM5, .NONE, .NONE, .NONE, .NONE}, 0xF86D0500, 0xFFFFFFE0, .V6, .A32, {cond_in_28=false}, {}},
	},
	.SRSDB = {
		{.SRSDB, {.GPR, .IMM, .NONE, .NONE, .NONE, .NONE}, {.IMPL_SP, .MODE_IMM5, .NONE, .NONE, .NONE, .NONE}, 0xF94D0500, 0xFFFFFFE0, .V6, .A32, {cond_in_28=false}, {}},
		{.SRSDB, {.GPR, .IMM, .NONE, .NONE, .NONE, .NONE}, {.IMPL_SP, .MODE_IMM5, .NONE, .NONE, .NONE, .NONE}, 0xF96D0500, 0xFFFFFFE0, .V6, .A32, {cond_in_28=false}, {}},
	},
	.SRSIA = {
		{.SRSIA, {.GPR, .IMM, .NONE, .NONE, .NONE, .NONE}, {.IMPL_SP, .MODE_IMM5, .NONE, .NONE, .NONE, .NONE}, 0xF8CD0500, 0xFFFFFFE0, .V6, .A32, {cond_in_28=false}, {}},
		{.SRSIA, {.GPR, .IMM, .NONE, .NONE, .NONE, .NONE}, {.IMPL_SP, .MODE_IMM5, .NONE, .NONE, .NONE, .NONE}, 0xF8ED0500, 0xFFFFFFE0, .V6, .A32, {cond_in_28=false}, {}},
	},
	.SRSIB = {
		{.SRSIB, {.GPR, .IMM, .NONE, .NONE, .NONE, .NONE}, {.IMPL_SP, .MODE_IMM5, .NONE, .NONE, .NONE, .NONE}, 0xF9CD0500, 0xFFFFFFE0, .V6, .A32, {cond_in_28=false}, {}},
		{.SRSIB, {.GPR, .IMM, .NONE, .NONE, .NONE, .NONE}, {.IMPL_SP, .MODE_IMM5, .NONE, .NONE, .NONE, .NONE}, 0xF9ED0500, 0xFFFFFFE0, .V6, .A32, {cond_in_28=false}, {}},
	},

	// =========================================================================
	// §7 -- Exclusive monitors + acquire/release
	// =========================================================================

	// LDREX family (ARMv6K+, then ARMv7 added all widths)
	.LDREX = {
		{.LDREX, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .RN_A32, .NONE, .NONE, .NONE, .NONE}, 0x01900F9F, 0x0FF00FFF, .V6K, .A32, {}, {}},
	},
	.STREX = {
		{.STREX, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .RN_A32, .NONE, .NONE, .NONE}, 0x01800F90, 0x0FF00FF0, .V6K, .A32, {}, {}},
	},
	.LDREXB = {
		{.LDREXB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .RN_A32, .NONE, .NONE, .NONE, .NONE}, 0x01D00F9F, 0x0FF00FFF, .V6K, .A32, {}, {}},
	},
	.STREXB = {
		{.STREXB, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .RN_A32, .NONE, .NONE, .NONE}, 0x01C00F90, 0x0FF00FF0, .V6K, .A32, {}, {}},
	},
	.LDREXH = {
		{.LDREXH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .RN_A32, .NONE, .NONE, .NONE, .NONE}, 0x01F00F9F, 0x0FF00FFF, .V6K, .A32, {}, {}},
	},
	.STREXH = {
		{.STREXH, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .RN_A32, .NONE, .NONE, .NONE}, 0x01E00F90, 0x0FF00FF0, .V6K, .A32, {}, {}},
	},
	.LDREXD = {
		{.LDREXD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_A32, .RT_PAIR_NEXT, .RN_A32, .NONE, .NONE, .NONE}, 0x01B00F9F, 0x0FF01FFF, .V6K, .A32, {}, {}},
	},
	.STREXD = {
		{.STREXD, {.GPR, .GPR, .GPR, .MEM, .NONE, .NONE}, {.RD, .RM_A32, .RM_PAIR_NEXT, .RN_A32, .NONE, .NONE}, 0x01A00F90, 0x0FF00FF1, .V6K, .A32, {}, {}},
	},

	// ARMv8 acquire/release (LDA/STL family, exclusive too)
	.LDA   = { {.LDA,   {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .RN_A32, .NONE, .NONE, .NONE, .NONE}, 0x01900C9F, 0x0FF00FFF, .V8, .A32, {}, {}} },
	// STL/STLB/STLH: per ARMv8 ARM, Rt is at bits 3:0 (NOT 15:12); bits 15:12 are
	// 0xF fixed. Use RM_A32 enc for Rt to place it correctly.
	.STL   = { {.STL,   {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RM_A32, .RN_A32, .NONE, .NONE, .NONE, .NONE}, 0x0180FC90, 0x0FF0FFF0, .V8, .A32, {}, {}} },
	.LDAB  = { {.LDAB,  {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .RN_A32, .NONE, .NONE, .NONE, .NONE}, 0x01D00C9F, 0x0FF00FFF, .V8, .A32, {}, {}} },
	.STLB  = { {.STLB,  {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RM_A32, .RN_A32, .NONE, .NONE, .NONE, .NONE}, 0x01C0FC90, 0x0FF0FFF0, .V8, .A32, {}, {}} },
	.LDAH  = { {.LDAH,  {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .RN_A32, .NONE, .NONE, .NONE, .NONE}, 0x01F00C9F, 0x0FF00FFF, .V8, .A32, {}, {}} },
	.STLH  = { {.STLH,  {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RM_A32, .RN_A32, .NONE, .NONE, .NONE, .NONE}, 0x01E0FC90, 0x0FF0FFF0, .V8, .A32, {}, {}} },
	.LDAEX  = { {.LDAEX,  {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .RN_A32, .NONE, .NONE, .NONE, .NONE}, 0x01900E9F, 0x0FF00FFF, .V8, .A32, {}, {}} },
	.STLEX  = { {.STLEX,  {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .RN_A32, .NONE, .NONE, .NONE},      0x01800E90, 0x0FF00FF0, .V8, .A32, {}, {}} },
	.LDAEXB = { {.LDAEXB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .RN_A32, .NONE, .NONE, .NONE, .NONE}, 0x01D00E9F, 0x0FF00FFF, .V8, .A32, {}, {}} },
	.STLEXB = { {.STLEXB, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .RN_A32, .NONE, .NONE, .NONE},      0x01C00E90, 0x0FF00FF0, .V8, .A32, {}, {}} },
	.LDAEXH = { {.LDAEXH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .RN_A32, .NONE, .NONE, .NONE, .NONE}, 0x01F00E9F, 0x0FF00FFF, .V8, .A32, {}, {}} },
	.STLEXH = { {.STLEXH, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .RN_A32, .NONE, .NONE, .NONE},      0x01E00E90, 0x0FF00FF0, .V8, .A32, {}, {}} },
	.LDAEXD = { {.LDAEXD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_A32, .RT_PAIR_NEXT, .RN_A32, .NONE, .NONE, .NONE}, 0x01B00E9F, 0x0FF01FFF, .V8, .A32, {}, {}} },
	.STLEXD = { {.STLEXD, {.GPR, .GPR, .GPR, .MEM, .NONE, .NONE}, {.RD, .RM_A32, .RM_PAIR_NEXT, .RN_A32, .NONE, .NONE},      0x01A00E90, 0x0FF00FF1, .V8, .A32, {}, {}} },

	// =========================================================================
	// §8 -- Coprocessor + CRC32 + Crypto
	// =========================================================================

	// CDP / CDP2:  cond 1110 opc1 CRn CRd cp_num opc2 0 CRm
	// Written `cdp p1, #2, c3, c4, c5, #6` -- coproc, opc1, CRd, CRn, CRm,
	// opc2. CRd is bits 15:12; CRn, at 19:16, is a different operand.
	.CDP  = { {.CDP,  {.COPROC_NUM, .IMM_COPROC_OP, .COPROC_REG, .COPROC_REG, .COPROC_REG, .IMM_COPROC_OP}, {.COPROC_NUM_FIELD, .COPROC_OPC1_FIELD, .COPROC_CRD_FIELD, .COPROC_CRN_FIELD, .COPROC_CRM_FIELD, .COPROC_OPC2_FIELD}, 0x0E000000, 0x0F000010, .BASE, .A32, {}, {}} },
	.CDP2 = { {.CDP2, {.COPROC_NUM, .IMM_COPROC_OP, .COPROC_REG, .COPROC_REG, .COPROC_REG, .IMM_COPROC_OP}, {.COPROC_NUM_FIELD, .COPROC_OPC1_FIELD, .COPROC_CRD_FIELD, .COPROC_CRN_FIELD, .COPROC_CRM_FIELD, .COPROC_OPC2_FIELD}, 0xFE000000, 0xFF000010, .V5T,  .A32, {cond_in_28=false}, {}} },
	// MCR / MCR2 / MRC / MRC2: cond 1110 opc1 L CRn Rt cp_num opc2 1 CRm
	// opc1 is three bits here, at 23:21, not the four CDP gets.
	.MCR = { {.MCR, {.COPROC_NUM, .IMM_COPROC_OP, .GPR, .COPROC_REG, .COPROC_REG, .IMM_COPROC_OP}, {.COPROC_NUM_FIELD, .COPROC_OPC1_MCR, .RT_A32, .COPROC_CRN_FIELD, .COPROC_CRM_FIELD, .COPROC_OPC2_FIELD}, 0x0E000010, 0x0F100010, .BASE, .A32, {}, {}} },
	.MCR2 = { {.MCR2, {.COPROC_NUM, .IMM_COPROC_OP, .GPR, .COPROC_REG, .COPROC_REG, .IMM_COPROC_OP}, {.COPROC_NUM_FIELD, .COPROC_OPC1_MCR, .RT_A32, .COPROC_CRN_FIELD, .COPROC_CRM_FIELD, .COPROC_OPC2_FIELD}, 0xFE000010, 0xFF100010, .V5T, .A32, {cond_in_28=false}, {}} },
	.MRC = { {.MRC, {.COPROC_NUM, .IMM_COPROC_OP, .GPR, .COPROC_REG, .COPROC_REG, .IMM_COPROC_OP}, {.COPROC_NUM_FIELD, .COPROC_OPC1_MCR, .RT_OR_APSR_NZCV, .COPROC_CRN_FIELD, .COPROC_CRM_FIELD, .COPROC_OPC2_FIELD}, 0x0E100010, 0x0F100010, .BASE, .A32, {}, {}} },
	.MRC2 = { {.MRC2, {.COPROC_NUM, .IMM_COPROC_OP, .GPR, .COPROC_REG, .COPROC_REG, .IMM_COPROC_OP}, {.COPROC_NUM_FIELD, .COPROC_OPC1_MCR, .RT_OR_APSR_NZCV, .COPROC_CRN_FIELD, .COPROC_CRM_FIELD, .COPROC_OPC2_FIELD}, 0xFE100010, 0xFF100010, .V5T, .A32, {cond_in_28=false}, {}} },
	// MCRR / MCRR2 / MRRC / MRRC2: cond 1100 010 L Rt2 Rt cp_num opc1 CRm
	.MCRR = { {.MCRR, {.COPROC_NUM, .IMM_COPROC_OP, .GPR, .GPR, .COPROC_REG, .NONE}, {.COPROC_NUM_FIELD, .COPROC_OPC_MCRR, .RT_A32, .RT2_A32, .COPROC_CRM_FIELD, .NONE}, 0x0C400000, 0x0FF00000, .V6, .A32, {}, {}} },
	.MCRR2 = { {.MCRR2, {.COPROC_NUM, .IMM_COPROC_OP, .GPR, .GPR, .COPROC_REG, .NONE}, {.COPROC_NUM_FIELD, .COPROC_OPC_MCRR, .RT_A32, .RT2_A32, .COPROC_CRM_FIELD, .NONE}, 0xFC400000, 0xFFF00000, .V6, .A32, {cond_in_28=false}, {}} },
	.MRRC = { {.MRRC, {.COPROC_NUM, .IMM_COPROC_OP, .GPR, .GPR, .COPROC_REG, .NONE}, {.COPROC_NUM_FIELD, .COPROC_OPC_MCRR, .RT_A32, .RT2_A32, .COPROC_CRM_FIELD, .NONE}, 0x0C500000, 0x0FF00000, .V6, .A32, {}, {}} },
	.MRRC2 = { {.MRRC2, {.COPROC_NUM, .IMM_COPROC_OP, .GPR, .GPR, .COPROC_REG, .NONE}, {.COPROC_NUM_FIELD, .COPROC_OPC_MCRR, .RT_A32, .RT2_A32, .COPROC_CRM_FIELD, .NONE}, 0xFC500000, 0xFFF00000, .V6, .A32, {cond_in_28=false}, {}} },
	// LDC / STC: cond 110 P U N W L Rn CRd cp_num imm8. CRd is bits 15:12;
	// bits 19:16 are the base register. The offset counts words, so the
	// eight bits reach 1020. N asks the coprocessor for the long
	// transfer, which the syntax spells as an L on the mnemonic. U is the
	// offset's sign and belongs to the memory operand, so it stays out of
	// the mask; P, N, W and L pick the form and must be in it. With P and W
	// both clear there is no offset: U must be set, and the eight bits are
	// an option for the coprocessor, `[Rn], {option}`.
	.LDC = {
		{.LDC, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4, .NONE, .NONE, .NONE}, 0x0D100000, 0x0F700000, .BASE, .A32, {}, {}},
		{.LDC, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4_PRE, .NONE, .NONE, .NONE}, 0x0D300000, 0x0F700000, .BASE, .A32, {}, {}},
		{.LDC, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4_POST, .NONE, .NONE, .NONE}, 0x0C300000, 0x0F700000, .BASE, .A32, {}, {}},
		{.LDC, {.COPROC_NUM, .COPROC_REG, .MEM, .IMM8, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .RN_A32, .COPROC_OPTION, .NONE, .NONE}, 0x0C900000, 0x0FF00000, .BASE, .A32, {}, {}},
	},
	.LDCL = {
		{.LDCL, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4, .NONE, .NONE, .NONE}, 0x0D500000, 0x0F700000, .BASE, .A32, {}, {}},
		{.LDCL, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4_PRE, .NONE, .NONE, .NONE}, 0x0D700000, 0x0F700000, .BASE, .A32, {}, {}},
		{.LDCL, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4_POST, .NONE, .NONE, .NONE}, 0x0C700000, 0x0F700000, .BASE, .A32, {}, {}},
		{.LDCL, {.COPROC_NUM, .COPROC_REG, .MEM, .IMM8, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .RN_A32, .COPROC_OPTION, .NONE, .NONE}, 0x0CD00000, 0x0FF00000, .BASE, .A32, {}, {}},
	},
	.LDC2 = {
		{.LDC2, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4, .NONE, .NONE, .NONE}, 0xFD100000, 0xFF700000, .V5T, .A32, {cond_in_28=false}, {}},
		{.LDC2, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4_PRE, .NONE, .NONE, .NONE}, 0xFD300000, 0xFF700000, .V5T, .A32, {cond_in_28=false}, {}},
		{.LDC2, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4_POST, .NONE, .NONE, .NONE}, 0xFC300000, 0xFF700000, .V5T, .A32, {cond_in_28=false}, {}},
		{.LDC2, {.COPROC_NUM, .COPROC_REG, .MEM, .IMM8, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .RN_A32, .COPROC_OPTION, .NONE, .NONE}, 0xFC900000, 0xFFF00000, .V5T, .A32, {cond_in_28=false}, {}},
	},
	.LDC2L = {
		{.LDC2L, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4, .NONE, .NONE, .NONE}, 0xFD500000, 0xFF700000, .V5T, .A32, {cond_in_28=false}, {}},
		{.LDC2L, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4_PRE, .NONE, .NONE, .NONE}, 0xFD700000, 0xFF700000, .V5T, .A32, {cond_in_28=false}, {}},
		{.LDC2L, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4_POST, .NONE, .NONE, .NONE}, 0xFC700000, 0xFF700000, .V5T, .A32, {cond_in_28=false}, {}},
		{.LDC2L, {.COPROC_NUM, .COPROC_REG, .MEM, .IMM8, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .RN_A32, .COPROC_OPTION, .NONE, .NONE}, 0xFCD00000, 0xFFF00000, .V5T, .A32, {cond_in_28=false}, {}},
	},
	.STC = {
		{.STC, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4, .NONE, .NONE, .NONE}, 0x0D000000, 0x0F700000, .BASE, .A32, {}, {}},
		{.STC, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4_PRE, .NONE, .NONE, .NONE}, 0x0D200000, 0x0F700000, .BASE, .A32, {}, {}},
		{.STC, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4_POST, .NONE, .NONE, .NONE}, 0x0C200000, 0x0F700000, .BASE, .A32, {}, {}},
		{.STC, {.COPROC_NUM, .COPROC_REG, .MEM, .IMM8, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .RN_A32, .COPROC_OPTION, .NONE, .NONE}, 0x0C800000, 0x0FF00000, .BASE, .A32, {}, {}},
	},
	.STCL = {
		{.STCL, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4, .NONE, .NONE, .NONE}, 0x0D400000, 0x0F700000, .BASE, .A32, {}, {}},
		{.STCL, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4_PRE, .NONE, .NONE, .NONE}, 0x0D600000, 0x0F700000, .BASE, .A32, {}, {}},
		{.STCL, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4_POST, .NONE, .NONE, .NONE}, 0x0C600000, 0x0F700000, .BASE, .A32, {}, {}},
		{.STCL, {.COPROC_NUM, .COPROC_REG, .MEM, .IMM8, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .RN_A32, .COPROC_OPTION, .NONE, .NONE}, 0x0CC00000, 0x0FF00000, .BASE, .A32, {}, {}},
	},
	.STC2 = {
		{.STC2, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4, .NONE, .NONE, .NONE}, 0xFD000000, 0xFF700000, .V5T, .A32, {cond_in_28=false}, {}},
		{.STC2, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4_PRE, .NONE, .NONE, .NONE}, 0xFD200000, 0xFF700000, .V5T, .A32, {cond_in_28=false}, {}},
		{.STC2, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4_POST, .NONE, .NONE, .NONE}, 0xFC200000, 0xFF700000, .V5T, .A32, {cond_in_28=false}, {}},
		{.STC2, {.COPROC_NUM, .COPROC_REG, .MEM, .IMM8, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .RN_A32, .COPROC_OPTION, .NONE, .NONE}, 0xFC800000, 0xFFF00000, .V5T, .A32, {cond_in_28=false}, {}},
	},
	.STC2L = {
		{.STC2L, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4, .NONE, .NONE, .NONE}, 0xFD400000, 0xFF700000, .V5T, .A32, {cond_in_28=false}, {}},
		{.STC2L, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4_PRE, .NONE, .NONE, .NONE}, 0xFD600000, 0xFF700000, .V5T, .A32, {cond_in_28=false}, {}},
		{.STC2L, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .MEM_IMM8_SCALED4_POST, .NONE, .NONE, .NONE}, 0xFC600000, 0xFF700000, .V5T, .A32, {cond_in_28=false}, {}},
		{.STC2L, {.COPROC_NUM, .COPROC_REG, .MEM, .IMM8, .NONE, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .RN_A32, .COPROC_OPTION, .NONE, .NONE}, 0xFCC00000, 0xFFF00000, .V5T, .A32, {cond_in_28=false}, {}},
	},

	// ARMv8 CRC32 family
	//   cond 0001 0 sz 0 Rn Rd 0000 0 0 1 0 0 Rm   sz=00 byte / 01 half / 10 word
	//   bit  9 selects CRC32 (0) vs CRC32C (1).
	.CRC32B  = { {.CRC32B,  {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0xE1000040, 0xFFF00FF0, .CRC32, .A32, {cond_in_28=false}, {}} },
	.CRC32H  = { {.CRC32H,  {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0xE1200040, 0xFFF00FF0, .CRC32, .A32, {cond_in_28=false}, {}} },
	.CRC32W  = { {.CRC32W,  {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0xE1400040, 0xFFF00FF0, .CRC32, .A32, {cond_in_28=false}, {}} },
	.CRC32CB = { {.CRC32CB, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0xE1000240, 0xFFF00FF0, .CRC32, .A32, {cond_in_28=false}, {}} },
	.CRC32CH = { {.CRC32CH, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0xE1200240, 0xFFF00FF0, .CRC32, .A32, {cond_in_28=false}, {}} },
	.CRC32CW = { {.CRC32CW, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE, .NONE, .NONE}, 0xE1400240, 0xFFF00FF0, .CRC32, .A32, {cond_in_28=false}, {}} },


	// =========================================================================
	// §9 -- VFP scalar floating point (VFPv2 / v3 / v4)
	// =========================================================================
	//
	// VFP A32 layout (3-operand FP arithmetic):
	//   cond 1110 opc1 D Vn Vd 101 sz N op M 0 Vm     (sz=0 single, sz=1 double)
	//
	//   D bit 22, N bit 7, M bit 5 are the high bits of Vd/Vn/Vm.
	//   For single-precision: low 4 bits in Vd/Vn/Vm, high bit in D/N/M.
	//   For double-precision: low 4 bits in Vd/Vn/Vm, high bit in D/N/M too
	//     (VFPv3 adds D16..D31 access through these high bits).
	//
	//   opc1 / op selects operation:
	//     VMLA  opc1=0000 op=0      VMLS  opc1=0000 op=1
	//     VNMLS opc1=0001 op=0      VNMLA opc1=0001 op=1
	//     VMUL  opc1=0010 op=0      VNMUL opc1=0010 op=1
	//     VADD  opc1=0011 op=0      VSUB  opc1=0011 op=1
	//     VDIV  opc1=1000 op=0
	//     VFMA  opc1=1010 op=0      VFMS  opc1=1010 op=1     (VFPv4)
	//     VFNMS opc1=1001 op=0      VFNMA opc1=1001 op=1     (VFPv4)
	//
	//   Masks lock bits 27:20 (opcode class) + bits 11:8 (coproc 101 sz) +
	//   bit 6 (op) + bit 4 (must-be-0). Operand bits at 22, 19:16, 15:12,
	//   7, 5, 3:0 are operand-driven.

	// ---- 3-operand FP arithmetic ----
	.VADD = {
		// VFP scalar
		{.VADD, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0E300A00, 0x0FB00F50, .VFPV2, .A32, {}, {.F32, .NONE}},
		{.VADD, {.DPR, .DPR, .DPR, .NONE, .NONE, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE, .NONE, .NONE}, 0x0E300B00, 0x0FB00F50, .VFPV2, .A32, {}, {.F64, .NONE}},
		// VFP F16 scalar (FEAT_FP16): cp=1001
		{.VADD, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0E300900, 0x0FB00F50, .HALF_FP, .A32, {}, {.F16, .NONE}},
		// MVE integer: Q-only, T32, 1110 1111 0 0 sz Qn Qd 1000 N 1 M 0 Qm
		{.VADD, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEF000840, 0xEFC10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.I8, .NONE}},
		// MVE FP: 1110 1111 0 0 sz Qn Qd 1101 N 1 M 1 Qm
		{.VADD, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEF000D40, 0xEFE10FF1, .MVE_FP,  .T32, {thumb32=true, cond_in_28=false}, {.F32, .NONE}},
		// MVE scalar Rm (Qd, Qn, Rt): per LLVM vadd.i8 q1,q2,r3 = 0xEE05_2F43 -> base 0xEE010F40
		{.VADD, {.QPR, .QPR, .GPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .RM_T32, .NONE, .NONE, .NONE}, 0xEE010F40, 0xEFC11FF0, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.I8, .NONE}},
	},
	.VSUB = {
		// VFP scalar
		{.VSUB, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0E300A40, 0x0FB00F50, .VFPV2, .A32, {}, {.F32, .NONE}},
		{.VSUB, {.DPR, .DPR, .DPR, .NONE, .NONE, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE, .NONE, .NONE}, 0x0E300B40, 0x0FB00F50, .VFPV2, .A32, {}, {.F64, .NONE}},
		// VFP F16 scalar
		{.VSUB, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0E300940, 0x0FB00F50, .HALF_FP, .A32, {}, {.F16, .NONE}},
		// MVE integer / FP / scalar
		{.VSUB, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xFF000840, 0xFFC10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.I8, .NONE}},
		{.VSUB, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEF200D40, 0xEFE10FF1, .MVE_FP,  .T32, {thumb32=true, cond_in_28=false}, {.F32, .NONE}},
		// VSUB MVE scalar: per LLVM 0xEE05_3F43 -> base 0xEE011F40
		{.VSUB, {.QPR, .QPR, .GPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .RM_T32, .NONE, .NONE, .NONE}, 0xEE011F40, 0xEFC11FF0, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.I8, .NONE}},
	},
	// (VMUL, VMLA and VMLS are further below.)
	.VDIV = {
		{.VDIV, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0E800A00, 0x0FB00F50, .VFPV2, .A32, {}, {.F32, .NONE}},
		{.VDIV, {.DPR, .DPR, .DPR, .NONE, .NONE, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE, .NONE, .NONE}, 0x0E800B00, 0x0FB00F50, .VFPV2, .A32, {}, {.F64, .NONE}},
		// VFP F16 scalar
		{.VDIV, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0E800900, 0x0FB00F50, .HALF_FP, .A32, {}, {.F16, .NONE}},
	},
	.VNMUL = {
		{.VNMUL, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0E200A40, 0x0FB00F50, .VFPV2, .A32, {}, {.F32, .NONE}},
		{.VNMUL, {.DPR, .DPR, .DPR, .NONE, .NONE, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE, .NONE, .NONE}, 0x0E200B40, 0x0FB00F50, .VFPV2, .A32, {}, {.F64, .NONE}},
	},
	.VNMLS = {
		{.VNMLS, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0E100A00, 0x0FB00F50, .VFPV2, .A32, {}, {.F32, .NONE}},
		{.VNMLS, {.DPR, .DPR, .DPR, .NONE, .NONE, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE, .NONE, .NONE}, 0x0E100B00, 0x0FB00F50, .VFPV2, .A32, {}, {.F64, .NONE}},
	},
	.VNMLA = {
		{.VNMLA, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0E100A40, 0x0FB00F50, .VFPV2, .A32, {}, {.F32, .NONE}},
		{.VNMLA, {.DPR, .DPR, .DPR, .NONE, .NONE, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE, .NONE, .NONE}, 0x0E100B40, 0x0FB00F50, .VFPV2, .A32, {}, {.F64, .NONE}},
	},
	// VFPv4 fused multiply-add
	.VFMA = {
		{.VFMA, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0EA00A00, 0x0FB00F50, .VFPV4, .A32, {}, {.F32, .NONE}},
		{.VFMA, {.DPR, .DPR, .DPR, .NONE, .NONE, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE, .NONE, .NONE}, 0x0EA00B00, 0x0FB00F50, .VFPV4, .A32, {}, {.F64, .NONE}},
		// VFP F16 scalar
		{.VFMA, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0EA00900, 0x0FB00F50, .HALF_FP, .A32, {}, {.F16, .NONE}},
		// MVE FP vector + scalar
		{.VFMA, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEF000C50, 0xEFE10FF1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}, {.F32, .NONE}},
		{.VFMA, {.QPR, .QPR, .GPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .RM_T32, .NONE, .NONE, .NONE}, 0xEE310E40, 0xEFF10FD1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}, {.F32, .NONE}},
	},
	.VFMS = {
		{.VFMS, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0EA00A40, 0x0FB00F50, .VFPV4, .A32, {}, {.F32, .NONE}},
		{.VFMS, {.DPR, .DPR, .DPR, .NONE, .NONE, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE, .NONE, .NONE}, 0x0EA00B40, 0x0FB00F50, .VFPV4, .A32, {}, {.F64, .NONE}},
		// VFP F16 scalar
		{.VFMS, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0EA00940, 0x0FB00F50, .HALF_FP, .A32, {}, {.F16, .NONE}},
		// MVE FP vector
		{.VFMS, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEF200C50, 0xEFE10FF1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}, {.F32, .NONE}},
	},
	.VFNMS = {
		{.VFNMS, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0E900A00, 0x0FB00F50, .VFPV4, .A32, {}, {.F32, .NONE}},
		{.VFNMS, {.DPR, .DPR, .DPR, .NONE, .NONE, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE, .NONE, .NONE}, 0x0E900B00, 0x0FB00F50, .VFPV4, .A32, {}, {.F64, .NONE}},
		// VFP F16 scalar
		{.VFNMS, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0E900900, 0x0FB00F50, .HALF_FP, .A32, {}, {.F16, .NONE}},
	},
	.VFNMA = {
		{.VFNMA, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0E900A40, 0x0FB00F50, .VFPV4, .A32, {}, {.F32, .NONE}},
		{.VFNMA, {.DPR, .DPR, .DPR, .NONE, .NONE, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE, .NONE, .NONE}, 0x0E900B40, 0x0FB00F50, .VFPV4, .A32, {}, {.F64, .NONE}},
		// VFP F16 scalar
		{.VFNMA, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0E900940, 0x0FB00F50, .HALF_FP, .A32, {}, {.F16, .NONE}},
	},

	// ---- 2-operand unary FP (opc1=1011 op2=xxxx) ----
	//   Format: cond 1110 1011 D opc2 Vd 101 sz E 1 M 0 Vm
	//   opc2 (bits 19:16): 0000 VMOV, 0001 VNEG, 0010 VSQRT, etc.
	// (VABS and VNEG are further below.)
	.VSQRT = {
		{.VSQRT, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EB10AC0, 0x0FBF0FD0, .VFPV2, .A32, {}, {.F32, .NONE}},
		{.VSQRT, {.DPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0x0EB10BC0, 0x0FBF0FD0, .VFPV2, .A32, {}, {.F64, .NONE}},
		// VFP F16 scalar (cp=1001)
		{.VSQRT, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EB109C0, 0x0FBF0FD0, .HALF_FP, .A32, {}, {.F16, .NONE}},
	},
	// VMOV reg-reg (opc2=0000, op=0)
	.VMOV = {
		{.VMOV, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EB00A40, 0x0FBF0FD0, .VFPV2, .A32, {}, {.F32, .NONE}},
		{.VMOV, {.DPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0x0EB00B40, 0x0FBF0FD0, .VFPV2, .A32, {}, {.F64, .NONE}},
		// VMOV imm (opc1=1011 opc2=0000 op=0, imm in (19:16)+(3:0) split)
		{.VMOV, {.SPR, .IMM8, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VFP_IMM8, .NONE, .NONE, .NONE, .NONE}, 0x0EB00A00, 0x0FB00FF0, .VFPV3, .A32, {}, {.F32, .NONE}},
		{.VMOV, {.DPR, .IMM8, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .VFP_IMM8, .NONE, .NONE, .NONE, .NONE}, 0x0EB00B00, 0x0FB00FF0, .VFPV3, .A32, {}, {.F64, .NONE}},
		// VMOV GPR <-> S reg: cond 1110 000 op L Vn Rt 1010 N 0010000
		{.VMOV, {.SPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.VN_S, .RT_A32, .NONE, .NONE, .NONE, .NONE}, 0x0E000A10, 0x0FF00F7F, .VFPV2, .A32, {}, {}},
		{.VMOV, {.GPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .VN_S, .NONE, .NONE, .NONE, .NONE}, 0x0E100A10, 0x0FF00F7F, .VFPV2, .A32, {}, {}},
		// The half-precision moves, through coprocessor 9.
		{.VMOV, {.SPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.VN_S, .RT_A32, .NONE, .NONE, .NONE, .NONE}, 0x0E000910, 0x0FF00F7F, .HALF_FP, .A32, {}, {.F16, .NONE}},
		{.VMOV, {.GPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .VN_S, .NONE, .NONE, .NONE, .NONE}, 0x0E100910, 0x0FF00F7F, .HALF_FP, .A32, {}, {.F16, .NONE}},
		// VMOV two GPRs <-> D reg (VMOV Rt, Rt2, Dm)
		{.VMOV, {.GPR, .GPR, .DPR, .NONE, .NONE, .NONE}, {.RT_A32, .RT2_A32, .VM_D, .NONE, .NONE, .NONE}, 0x0C500B10, 0x0FF00FD0, .VFPV2, .A32, {}, {}},
		{.VMOV, {.DPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.VM_D, .RT_A32, .RT2_A32, .NONE, .NONE, .NONE}, 0x0C400B10, 0x0FF00FD0, .VFPV2, .A32, {}, {}},
		// VMOV two GPRs <-> two consecutive S regs
		{.VMOV, {.GPR, .GPR, .SPR, .SPR, .NONE, .NONE}, {.RT_A32, .RT2_A32, .VM_S, .VM_S_PLUS1, .NONE, .NONE}, 0x0C500A10, 0x0FF00FD0, .VFPV2, .A32, {}, {}},
		{.VMOV, {.SPR, .SPR, .GPR, .GPR, .NONE, .NONE}, {.VM_S, .VM_S_PLUS1, .RT_A32, .RT2_A32, .NONE, .NONE}, 0x0C400A10, 0x0FF00FD0, .VFPV2, .A32, {}, {}},
		// 0x with opc2 00 a word, which takes no U.
		{.VMOV, {.GPR, .DPR_ELEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .VMOV_LANE_8, .NONE, .NONE, .NONE, .NONE}, 0x0E500B10, 0x0FD00F1F, .NEON, .A32, {}, {.S8, .NONE}},
		{.VMOV, {.GPR, .DPR_ELEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .VMOV_LANE_8, .NONE, .NONE, .NONE, .NONE}, 0x0ED00B10, 0x0FD00F1F, .NEON, .A32, {}, {.U8, .NONE}},
		{.VMOV, {.GPR, .DPR_ELEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .VMOV_LANE_16, .NONE, .NONE, .NONE, .NONE}, 0x0E100B30, 0x0FD00F3F, .NEON, .A32, {}, {.S16, .NONE}},
		{.VMOV, {.GPR, .DPR_ELEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .VMOV_LANE_16, .NONE, .NONE, .NONE, .NONE}, 0x0E900B30, 0x0FD00F3F, .NEON, .A32, {}, {.U16, .NONE}},
		{.VMOV, {.GPR, .DPR_ELEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .NEON_LANE_VN_32, .NONE, .NONE, .NONE, .NONE}, 0x0E100B10, 0x0FD00F7F, .VFPV2, .A32, {}, {.SZ32, .NONE}},
		// VMOV.<size> Qd[i], Rt  -- single lane Rt -> Qd[i]
		{.VMOV, {.QPR_ELEM, .GPR, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .RT_T32, .NONE, .NONE, .NONE, .NONE}, 0xEE000B10, 0xFFD00F1F, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.SZ32, .NONE}},
		// VMOV.<size> Rt, Qd[i]
		{.VMOV, {.GPR, .QPR_ELEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .QD_MVE, .NONE, .NONE, .NONE, .NONE}, 0xEE100B10, 0xFFD00F1F, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.SZ32, .NONE}},
		// VMOV Qd[2*i], Qd[2*i+1], Rt, Rt2  -- pair move
		{.VMOV, {.QPR_ELEM, .QPR_ELEM, .GPR, .GPR, .NONE, .NONE}, {.QD_MVE, .QD_MVE, .RT_T32, .RT2_T32, .NONE, .NONE}, 0xEC000F00, 0xFFD00F11, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
		{.VMOV, {.DPR_ELEM, .GPR, .NONE, .NONE, .NONE, .NONE}, {.VMOV_LANE_8, .RT_A32, .NONE, .NONE, .NONE, .NONE}, 0x0E400B10, 0x0FD00F1F, .VFPV2, .A32, {}, {.SZ8, .NONE}},
		{.VMOV, {.DPR_ELEM, .GPR, .NONE, .NONE, .NONE, .NONE}, {.VMOV_LANE_16, .RT_A32, .NONE, .NONE, .NONE, .NONE}, 0x0E000B30, 0x0FD00F3F, .VFPV2, .A32, {}, {.SZ16, .NONE}},
		{.VMOV, {.DPR_ELEM, .GPR, .NONE, .NONE, .NONE, .NONE}, {.VMOV_LANE_32, .RT_A32, .NONE, .NONE, .NONE, .NONE}, 0x0E000B10, 0x0FD00F7F, .VFPV2, .A32, {}, {.SZ32, .NONE}},
	},
	.VMVN = {
		// MVE VMVN Qd, Qm
		{.VMVN, {.QPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xFFB005C0, 0xFFF30F71, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},

	// VCMP / VCMPE: cond 1110 1011 D 0100 Vd 101 sz E 1 M 0 Vm    (E=1 raises invalid op on QNaN)
	.VCMP = {
		{.VCMP, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EB40A40, 0x0FBF0FD0, .VFPV2, .A32, {}, {.F32, .NONE}},
		{.VCMP, {.DPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0x0EB40B40, 0x0FBF0FD0, .VFPV2, .A32, {}, {.F64, .NONE}},
		// VCMP with zero: cond 1110 1011 D 0101 Vd 101 sz E 1 (0) 0 0000
		{.VCMP, {.SPR, .IMM, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .IMPL, .NONE, .NONE, .NONE, .NONE}, 0x0EB50A40, 0x0FBF0FFF, .VFPV2, .A32, {}, {.F32, .NONE}},
		{.VCMP, {.DPR, .IMM, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .IMPL, .NONE, .NONE, .NONE, .NONE}, 0x0EB50B40, 0x0FBF0FFF, .VFPV2, .A32, {}, {.F64, .NONE}},
		// VFP F16 scalar
		{.VCMP, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EB40940, 0x0FBF0FD0, .HALF_FP, .A32, {}, {.F16, .NONE}},
		{.VCMP, {.SPR, .IMM, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .IMPL, .NONE, .NONE, .NONE, .NONE}, 0x0EB50940, 0x0FBF0FFF, .HALF_FP, .A32, {}, {.F16, .NONE}},
		//   vcmp.f32 eq,q2,q3 -> 0xEE35_0F06 base 0xEE31_0F00
		{.VCMP, {.QPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.QN_MVE, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xFE010F00, 0xFE818FF0, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.I8, .NONE}},
		{.VCMP, {.QPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.QN_MVE, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xEE310F00, 0xEFB10FF0, .MVE_FP,  .T32, {thumb32=true, cond_in_28=false}, {.F32, .NONE}},
	},
	.VCMPE = {
		{.VCMPE, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EB40AC0, 0x0FBF0FD0, .VFPV2, .A32, {}, {.F32, .NONE}},
		{.VCMPE, {.DPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0x0EB40BC0, 0x0FBF0FD0, .VFPV2, .A32, {}, {.F64, .NONE}},
		{.VCMPE, {.SPR, .IMM, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .IMPL, .NONE, .NONE, .NONE, .NONE}, 0x0EB50AC0, 0x0FBF0FFF, .VFPV2, .A32, {}, {.F32, .NONE}},
		{.VCMPE, {.DPR, .IMM, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .IMPL, .NONE, .NONE, .NONE, .NONE}, 0x0EB50BC0, 0x0FBF0FFF, .VFPV2, .A32, {}, {.F64, .NONE}},
	},

	// VCVT family: int<->float and float<->float
	//   F32<->F64:  cond 1110 1011 D 0111 Vd 101 sz 1 1 M 0 Vm   (sz=0 to F64, sz=1 to F32)
	//   F32<->S32 / U32: opc2 selects direction and signedness.
	//   F32<->half-prec: VCVTB/VCVTT
	.VCVT = {
		// VCVT.F64.F32 Dd, Sm   (cond 1110 1011 D 0111 Vd 1010 11 M 0 Vm) sz=0 (output F32)... actually inverse:
		{.VCVT, {.DPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EB70AC0, 0x0FBF0FD0, .VFPV2, .A32, {}, {.F64, .F32}},
		// VCVT.F32.F64 Sd, Dm   (sz=1 output F64; opc2=0111)
		{.VCVT, {.SPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0x0EB70BC0, 0x0FBF0FD0, .VFPV2, .A32, {}, {.F32, .F64}},
		// VCVT.S32.F32 Sd, Sm   (opc2=1101 op=1)
		{.VCVT, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EBD0AC0, 0x0FBF0FD0, .VFPV2, .A32, {}, {.S32, .F32}},
		// VCVT.U32.F32 Sd, Sm   (opc2=1100 op=1)
		{.VCVT, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EBC0AC0, 0x0FBF0FD0, .VFPV2, .A32, {}, {.U32, .F32}},
		// VCVT.S32.F64 Sd, Dm
		{.VCVT, {.SPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0x0EBD0BC0, 0x0FBF0FD0, .VFPV2, .A32, {}, {.S32, .F64}},
		// VCVT.U32.F64 Sd, Dm
		{.VCVT, {.SPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0x0EBC0BC0, 0x0FBF0FD0, .VFPV2, .A32, {}, {.U32, .F64}},
		// VCVT.F32.S32 Sd, Sm   (opc2=1000 op=1)
		{.VCVT, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EB80AC0, 0x0FBF0FD0, .VFPV2, .A32, {}, {.F32, .S32}},
		// VCVT.F32.U32 Sd, Sm   (opc2=1000 op=0)
		{.VCVT, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EB80A40, 0x0FBF0FD0, .VFPV2, .A32, {}, {.F32, .U32}},
		// VCVT.F64.S32 Dd, Sm
		{.VCVT, {.DPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EB80BC0, 0x0FBF0FD0, .VFPV2, .A32, {}, {.F64, .S32}},
		// VCVT.F64.U32 Dd, Sm
		{.VCVT, {.DPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EB80B40, 0x0FBF0FD0, .VFPV2, .A32, {}, {.F64, .U32}},
		// field of zero is the widest fraction rather than none at all.
		{.VCVT, {.SPR, .SPR, .IMM, .NONE, .NONE, .NONE}, {.VD_S, .VD_S_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBA0940, 0x0FBF0FD0, .HALF_FP, .A32, {}, {.F16, .S16}},
		{.VCVT, {.SPR, .SPR, .IMM, .NONE, .NONE, .NONE}, {.VD_S, .VD_S_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBB0940, 0x0FBF0FD0, .HALF_FP, .A32, {}, {.F16, .U16}},
		{.VCVT, {.SPR, .SPR, .IMM, .NONE, .NONE, .NONE}, {.VD_S, .VD_S_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBE0940, 0x0FBF0FD0, .HALF_FP, .A32, {}, {.S16, .F16}},
		{.VCVT, {.SPR, .SPR, .IMM, .NONE, .NONE, .NONE}, {.VD_S, .VD_S_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBF0940, 0x0FBF0FD0, .HALF_FP, .A32, {}, {.U16, .F16}},
		{.VCVT, {.SPR, .SPR, .IMM, .NONE, .NONE, .NONE}, {.VD_S, .VD_S_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBA09C0, 0x0FBF0FD0, .HALF_FP, .A32, {}, {.F16, .S32}},
		{.VCVT, {.SPR, .SPR, .IMM, .NONE, .NONE, .NONE}, {.VD_S, .VD_S_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBB09C0, 0x0FBF0FD0, .HALF_FP, .A32, {}, {.F16, .U32}},
		{.VCVT, {.SPR, .SPR, .IMM, .NONE, .NONE, .NONE}, {.VD_S, .VD_S_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBE09C0, 0x0FBF0FD0, .HALF_FP, .A32, {}, {.S32, .F16}},
		{.VCVT, {.SPR, .SPR, .IMM, .NONE, .NONE, .NONE}, {.VD_S, .VD_S_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBF09C0, 0x0FBF0FD0, .HALF_FP, .A32, {}, {.U32, .F16}},
		{.VCVT, {.SPR, .SPR, .IMM, .NONE, .NONE, .NONE}, {.VD_S, .VD_S_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBA0A40, 0x0FBF0FD0, .VFPV3, .A32, {}, {.F32, .S16}},
		{.VCVT, {.SPR, .SPR, .IMM, .NONE, .NONE, .NONE}, {.VD_S, .VD_S_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBB0A40, 0x0FBF0FD0, .VFPV3, .A32, {}, {.F32, .U16}},
		{.VCVT, {.SPR, .SPR, .IMM, .NONE, .NONE, .NONE}, {.VD_S, .VD_S_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBE0A40, 0x0FBF0FD0, .VFPV3, .A32, {}, {.S16, .F32}},
		{.VCVT, {.SPR, .SPR, .IMM, .NONE, .NONE, .NONE}, {.VD_S, .VD_S_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBF0A40, 0x0FBF0FD0, .VFPV3, .A32, {}, {.U16, .F32}},
		{.VCVT, {.SPR, .SPR, .IMM, .NONE, .NONE, .NONE}, {.VD_S, .VD_S_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBA0AC0, 0x0FBF0FD0, .VFPV3, .A32, {}, {.F32, .S32}},
		{.VCVT, {.SPR, .SPR, .IMM, .NONE, .NONE, .NONE}, {.VD_S, .VD_S_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBB0AC0, 0x0FBF0FD0, .VFPV3, .A32, {}, {.F32, .U32}},
		{.VCVT, {.SPR, .SPR, .IMM, .NONE, .NONE, .NONE}, {.VD_S, .VD_S_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBE0AC0, 0x0FBF0FD0, .VFPV3, .A32, {}, {.S32, .F32}},
		{.VCVT, {.SPR, .SPR, .IMM, .NONE, .NONE, .NONE}, {.VD_S, .VD_S_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBF0AC0, 0x0FBF0FD0, .VFPV3, .A32, {}, {.U32, .F32}},
		{.VCVT, {.DPR, .DPR, .IMM, .NONE, .NONE, .NONE}, {.VD_D, .VD_D_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBA0B40, 0x0FBF0FD0, .VFPV3, .A32, {}, {.F64, .S16}},
		{.VCVT, {.DPR, .DPR, .IMM, .NONE, .NONE, .NONE}, {.VD_D, .VD_D_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBB0B40, 0x0FBF0FD0, .VFPV3, .A32, {}, {.F64, .U16}},
		{.VCVT, {.DPR, .DPR, .IMM, .NONE, .NONE, .NONE}, {.VD_D, .VD_D_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBE0B40, 0x0FBF0FD0, .VFPV3, .A32, {}, {.S16, .F64}},
		{.VCVT, {.DPR, .DPR, .IMM, .NONE, .NONE, .NONE}, {.VD_D, .VD_D_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBF0B40, 0x0FBF0FD0, .VFPV3, .A32, {}, {.U16, .F64}},
		{.VCVT, {.DPR, .DPR, .IMM, .NONE, .NONE, .NONE}, {.VD_D, .VD_D_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBA0BC0, 0x0FBF0FD0, .VFPV3, .A32, {}, {.F64, .S32}},
		{.VCVT, {.DPR, .DPR, .IMM, .NONE, .NONE, .NONE}, {.VD_D, .VD_D_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBB0BC0, 0x0FBF0FD0, .VFPV3, .A32, {}, {.F64, .U32}},
		{.VCVT, {.DPR, .DPR, .IMM, .NONE, .NONE, .NONE}, {.VD_D, .VD_D_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBE0BC0, 0x0FBF0FD0, .VFPV3, .A32, {}, {.S32, .F64}},
		{.VCVT, {.DPR, .DPR, .IMM, .NONE, .NONE, .NONE}, {.VD_D, .VD_D_AGAIN, .VFP_FBITS, .NONE, .NONE, .NONE}, 0x0EBF0BC0, 0x0FBF0FD0, .VFPV3, .A32, {}, {.U32, .F64}},
	},
	.VCVTB = {
		// VCVTB.F32.F16 / .F16.F32
		{.VCVTB, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EB20A40, 0x0FBF0FD0, .VFPV3, .A32, {}, {.F32, .F16}},
		{.VCVTB, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EB30A40, 0x0FBF0FD0, .VFPV3, .A32, {}, {.F16, .F32}},
		// Half to and from double: the sz bit picks D for the wide side.
		{.VCVTB, {.SPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0x0EB30B40, 0x0FBF0FD0, .V8, .A32, {}, {.F16, .F64}},
		{.VCVTB, {.DPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EB20B40, 0x0FBF0FD0, .V8, .A32, {}, {.F64, .F16}},
	},
	.VCVTT = {
		{.VCVTT, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EB20AC0, 0x0FBF0FD0, .VFPV3, .A32, {}, {.F32, .F16}},
		{.VCVTT, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EB30AC0, 0x0FBF0FD0, .VFPV3, .A32, {}, {.F16, .F32}},
		{.VCVTT, {.SPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0x0EB30BC0, 0x0FBF0FD0, .V8, .A32, {}, {.F16, .F64}},
		{.VCVTT, {.DPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EB20BC0, 0x0FBF0FD0, .V8, .A32, {}, {.F64, .F16}},
	},
	// ARMv8: VCVTA/N/P/M (rounding-mode FP-to-int) - cond=1111 (unconditional class)
	.VCVTA = {
		{.VCVTA, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0xFEBC0A40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}, {.U32, .F32}},
		{.VCVTA, {.SPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0xFEBC0B40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}, {.U32, .F64}},
	},
	.VCVTN = {
		{.VCVTN, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0xFEBD0A40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}, {.U32, .F32}},
		{.VCVTN, {.SPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0xFEBD0B40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}, {.U32, .F64}},
	},
	.VCVTP = {
		{.VCVTP, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0xFEBE0A40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}, {.U32, .F32}},
		{.VCVTP, {.SPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0xFEBE0B40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}, {.U32, .F64}},
	},
	.VCVTM = {
		{.VCVTM, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0xFEBF0A40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}, {.U32, .F32}},
		{.VCVTM, {.SPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0xFEBF0B40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}, {.U32, .F64}},
	},

	// VMRS / VMSR (access FPSCR + friends as GPR)
	//   VMRS: cond 1110 1111 0001 Rt 1010 0001 0000     (Rt=PC means transfer to APSR.NZCV)
	.VMRS = { {.VMRS, {.GPR, .PSR_FIELD, .NONE, .NONE, .NONE, .NONE}, {.RT_OR_APSR_NZCV, .VFP_SPEC_REG, .NONE, .NONE, .NONE, .NONE}, 0x0EF00A10, 0x0FF00FFF, .VFPV2, .A32, {}, {}} },
	.VMSR = { {.VMSR, {.PSR_FIELD, .GPR, .NONE, .NONE, .NONE, .NONE}, {.VFP_SPEC_REG, .RT_A32, .NONE, .NONE, .NONE, .NONE}, 0x0EE00A10, 0x0FF00FFF, .VFPV2, .A32, {}, {}} },

	// VLDR / VSTR (single / double):  cond 1101 U D 0 1 Rn Vd 101 sz imm8
	.VLDR = {
		{.VLDR, {.SPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .MEM_IMM8_SCALED4, .NONE, .NONE, .NONE, .NONE}, 0x0D100A00, 0x0F300F00, .VFPV2, .A32, {}, {}},
		{.VLDR, {.DPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .MEM_IMM8_SCALED4, .NONE, .NONE, .NONE, .NONE}, 0x0D100B00, 0x0F300F00, .VFPV2, .A32, {}, {}},
		// Half precision: coprocessor 9, and the offset counts halfwords.
		{.VLDR, {.SPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .MEM_IMM8_SCALED2, .NONE, .NONE, .NONE, .NONE}, 0x0D100900, 0x0F300F00, .HALF_FP, .A32, {}, {.SZ16, .NONE}},
	},
	.VSTR = {
		{.VSTR, {.SPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .MEM_IMM8_SCALED4, .NONE, .NONE, .NONE, .NONE}, 0x0D000A00, 0x0F300F00, .VFPV2, .A32, {}, {}},
		{.VSTR, {.DPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .MEM_IMM8_SCALED4, .NONE, .NONE, .NONE, .NONE}, 0x0D000B00, 0x0F300F00, .VFPV2, .A32, {}, {}},
		{.VSTR, {.SPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .MEM_IMM8_SCALED2, .NONE, .NONE, .NONE, .NONE}, 0x0D000900, 0x0F300F00, .HALF_FP, .A32, {}, {.SZ16, .NONE}},
	},

	// VLDM / VSTM (multiple S or D regs):  cond 110 P U D W L Rn Vd 101 sz imm8
	//   IA = P=0 U=1 ; DB = P=1 U=0 ; W=1 writeback; L=1 load / 0 store.
	.VLDMIA = {
		{.VLDMIA, {.GPR, .SPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .VFP_S_LIST, .NONE, .NONE, .NONE, .NONE}, 0x0C900A00, 0x0FB00F00, .VFPV2, .A32, {}, {}},
		{.VLDMIA, {.GPR, .DPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .VFP_D_LIST, .NONE, .NONE, .NONE, .NONE}, 0x0C900B00, 0x0FB00F01, .VFPV2, .A32, {}, {}},
		{.VLDMIA, {.GPR, .SPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .VFP_S_LIST, .NONE, .NONE, .NONE, .NONE}, 0x0CB00A00, 0x0FB00F00, .VFPV2, .A32, {}, {}},
		{.VLDMIA, {.GPR, .DPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .VFP_D_LIST, .NONE, .NONE, .NONE, .NONE}, 0x0CB00B00, 0x0FB00F01, .VFPV2, .A32, {}, {}},
	},
	.VLDMDB = {
		{.VLDMDB, {.GPR, .SPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .VFP_S_LIST, .NONE, .NONE, .NONE, .NONE}, 0x0D300A00, 0x0FB00F00, .VFPV2, .A32, {}, {}},
		{.VLDMDB, {.GPR, .DPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .VFP_D_LIST, .NONE, .NONE, .NONE, .NONE}, 0x0D300B00, 0x0FB00F01, .VFPV2, .A32, {}, {}},
	},
	.VSTMIA = {
		{.VSTMIA, {.GPR, .SPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .VFP_S_LIST, .NONE, .NONE, .NONE, .NONE}, 0x0C800A00, 0x0FB00F00, .VFPV2, .A32, {}, {}},
		{.VSTMIA, {.GPR, .DPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .VFP_D_LIST, .NONE, .NONE, .NONE, .NONE}, 0x0C800B00, 0x0FB00F01, .VFPV2, .A32, {}, {}},
		{.VSTMIA, {.GPR, .SPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .VFP_S_LIST, .NONE, .NONE, .NONE, .NONE}, 0x0CA00A00, 0x0FB00F00, .VFPV2, .A32, {}, {}},
		{.VSTMIA, {.GPR, .DPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .VFP_D_LIST, .NONE, .NONE, .NONE, .NONE}, 0x0CA00B00, 0x0FB00F01, .VFPV2, .A32, {}, {}},
	},
	.VSTMDB = {
		{.VSTMDB, {.GPR, .SPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .VFP_S_LIST, .NONE, .NONE, .NONE, .NONE}, 0x0D200A00, 0x0FB00F00, .VFPV2, .A32, {}, {}},
		{.VSTMDB, {.GPR, .DPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .VFP_D_LIST, .NONE, .NONE, .NONE, .NONE}, 0x0D200B00, 0x0FB00F01, .VFPV2, .A32, {}, {}},
	},
	.VPUSH = {
		{.VPUSH, {.SPR_LIST, .NONE, .NONE, .NONE, .NONE, .NONE}, {.VFP_S_LIST, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x0D2D0A00, 0x0FFF0F00, .VFPV2, .A32, {}, {}},
		{.VPUSH, {.DPR_LIST, .NONE, .NONE, .NONE, .NONE, .NONE}, {.VFP_D_LIST, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x0D2D0B00, 0x0FFF0F01, .VFPV2, .A32, {}, {}},
	},
	.VPOP = {
		{.VPOP, {.SPR_LIST, .NONE, .NONE, .NONE, .NONE, .NONE}, {.VFP_S_LIST, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x0CBD0A00, 0x0FFF0F00, .VFPV2, .A32, {}, {}},
		{.VPOP, {.DPR_LIST, .NONE, .NONE, .NONE, .NONE, .NONE}, {.VFP_D_LIST, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x0CBD0B00, 0x0FFF0F01, .VFPV2, .A32, {}, {}},
	},
	// FLDMX / FSTMX: D-register VLDM / VSTM whose word count is odd. They
	// predate D16-D31, and the list starts in D0-D15: D is 0.
	.FLDMIAX = {
		{.FLDMIAX, {.GPR, .DPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .VFP_DX_LIST, .NONE, .NONE, .NONE, .NONE}, 0x0C900B01, 0x0FF00F01, .VFPV2, .A32, {}, {}},
		{.FLDMIAX, {.GPR, .DPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .VFP_DX_LIST, .NONE, .NONE, .NONE, .NONE}, 0x0CB00B01, 0x0FF00F01, .VFPV2, .A32, {}, {}},
	},
	.FLDMDBX = {
		{.FLDMDBX, {.GPR, .DPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .VFP_DX_LIST, .NONE, .NONE, .NONE, .NONE}, 0x0D300B01, 0x0FF00F01, .VFPV2, .A32, {}, {}},
	},
	.FSTMIAX = {
		{.FSTMIAX, {.GPR, .DPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .VFP_DX_LIST, .NONE, .NONE, .NONE, .NONE}, 0x0C800B01, 0x0FF00F01, .VFPV2, .A32, {}, {}},
		{.FSTMIAX, {.GPR, .DPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .VFP_DX_LIST, .NONE, .NONE, .NONE, .NONE}, 0x0CA00B01, 0x0FF00F01, .VFPV2, .A32, {}, {}},
	},
	.FSTMDBX = {
		{.FSTMDBX, {.GPR, .DPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .VFP_DX_LIST, .NONE, .NONE, .NONE, .NONE}, 0x0D200B01, 0x0FF00F01, .VFPV2, .A32, {}, {}},
	},

	// ARMv8 FP min/max NaN-aware (VMAXNM/VMINNM), VSEL, VRINT*
	.VMAXNM = {
		{.VMAXNM, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0xFE800A00, 0xFFB00F50, .V8, .A32, {cond_in_28=false}, {.F32, .NONE}},
		{.VMAXNM, {.DPR, .DPR, .DPR, .NONE, .NONE, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE, .NONE, .NONE}, 0xFE800B00, 0xFFB00F50, .V8, .A32, {cond_in_28=false}, {.F64, .NONE}},
	},
	.VMINNM = {
		{.VMINNM, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0xFE800A40, 0xFFB00F50, .V8, .A32, {cond_in_28=false}, {.F32, .NONE}},
		{.VMINNM, {.DPR, .DPR, .DPR, .NONE, .NONE, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE, .NONE, .NONE}, 0xFE800B40, 0xFFB00F50, .V8, .A32, {cond_in_28=false}, {.F64, .NONE}},
	},
	.VSEL = {
		// VSEL<cond>.F32/F64 Sd, Sn, Sm -- cond field at bits 21-20 + 7
		{.VSEL, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0xFE000A00, 0xFF800F50, .V8, .A32, {cond_in_28=false, cond_in_21=true}, {.F32, .NONE}},
		{.VSEL, {.DPR, .DPR, .DPR, .NONE, .NONE, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE, .NONE, .NONE}, 0xFE000B00, 0xFF800F50, .V8, .A32, {cond_in_28=false, cond_in_21=true}, {.F64, .NONE}},
	},
	.VRINTA = {
		{.VRINTA, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0xFEB80A40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}, {.F32, .NONE}},
		{.VRINTA, {.DPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0xFEB80B40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}, {.F64, .NONE}},
		// MVE Q-form (FEAT_MVE_FP): per LLVM `vrinta.f32 q1, q3` -> 0xFFBA_0540
		{.VRINTA, {.QPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xFFBA0540, 0xFFFB0FF1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}, {.F32, .NONE}},
	},
	.VRINTN = {
		{.VRINTN, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0xFEB90A40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}, {.F32, .NONE}},
		{.VRINTN, {.DPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0xFEB90B40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}, {.F64, .NONE}},
		// MVE
		{.VRINTN, {.QPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xFFBA0440, 0xFFFB0FF1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}, {.F32, .NONE}},
	},
	.VRINTP = {
		{.VRINTP, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0xFEBA0A40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}, {.F32, .NONE}},
		{.VRINTP, {.DPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0xFEBA0B40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}, {.F64, .NONE}},
		// MVE
		{.VRINTP, {.QPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xFFBA07C0, 0xFFFB0FF1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}, {.F32, .NONE}},
	},
	.VRINTM = {
		{.VRINTM, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0xFEBB0A40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}, {.F32, .NONE}},
		{.VRINTM, {.DPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0xFEBB0B40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}, {.F64, .NONE}},
		// MVE
		{.VRINTM, {.QPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xFFBA06C0, 0xFFFB0FF1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}, {.F32, .NONE}},
	},
	.VRINTR = {
		{.VRINTR, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EB60A40, 0x0FBF0FD0, .V8, .A32, {}, {.F32, .NONE}},
		{.VRINTR, {.DPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0x0EB60B40, 0x0FBF0FD0, .V8, .A32, {}, {.F64, .NONE}},
	},
	.VRINTZ = {
		{.VRINTZ, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EB60AC0, 0x0FBF0FD0, .V8, .A32, {}, {.F32, .NONE}},
		{.VRINTZ, {.DPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0x0EB60BC0, 0x0FBF0FD0, .V8, .A32, {}, {.F64, .NONE}},
		// MVE
		{.VRINTZ, {.QPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xFFBA05C0, 0xFFFB0FF1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}, {.F32, .NONE}},
	},
	.VRINTX = {
		{.VRINTX, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EB70A40, 0x0FBF0FD0, .V8, .A32, {}, {.F32, .NONE}},
		{.VRINTX, {.DPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0x0EB70B40, 0x0FBF0FD0, .V8, .A32, {}, {.F64, .NONE}},
		// MVE
		{.VRINTX, {.QPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xFFBA04C0, 0xFFFB0FF1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}, {.F32, .NONE}},
	},
	// VJCVT (ARMv8.3): F64 -> S32 with JS-style rounding
	.VJCVT = { {.VJCVT, {.SPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0x0EB90BC0, 0x0FBF0FD0, .V8, .A32, {}, {.S32, .F64}} },

	// ---- VFP F16 scalar arithmetic (FEAT_FP16) ----
	//   Uses coproc 9 (cp_num = 1001) instead of 10/11 used by F32/F64.
	//   Format: cond 1110 opc1 D Vn Vd 1001 N op M 0 Vm
	// NOTE: VADD/VSUB/VMUL/VDIV/VABS/VNEG/VSQRT/VCMP F16 forms below extend
	// existing blocks; entries here go into their original mnemonic blocks
	// via the VADD/VSUB/etc. inline batches (see those blocks for the F16 row).

	// ---- F16 special: VCVTB / VCVTT for half/single conversion (already added) ----
	// VCVT.F16.F32 / .F32.F16 are at 0x0EB30A40 / 0x0EB20A40 (covered above).

	// =========================================================================
	// §10 -- Advanced SIMD
	// =========================================================================
	//
	// The A32 Advanced SIMD forms are generated class by class in
	// simd_table.odin, and their Thumb forms from those. What is here are the
	// VFP and MVE forms of the mnemonics they share.

	// ---- VMUL ----
	.VMUL = {
		// VFP scalar
		{.VMUL, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0E200A00, 0x0FB00F50, .VFPV2, .A32, {}, {.F32, .NONE}},
		{.VMUL, {.DPR, .DPR, .DPR, .NONE, .NONE, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE, .NONE, .NONE}, 0x0E200B00, 0x0FB00F50, .VFPV2, .A32, {}, {.F64, .NONE}},
		// VFP F16 scalar
		{.VMUL, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0E200900, 0x0FB00F50, .HALF_FP, .A32, {}, {.F16, .NONE}},
		// MVE integer / FP / scalar
		{.VMUL, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEF000950, 0xEFC10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.I8, .NONE}},
		{.VMUL, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xFF000D50, 0xFFE10FF1, .MVE_FP,  .T32, {thumb32=true, cond_in_28=false}, {.F32, .NONE}},
		// VMUL MVE scalar: per LLVM 0xEE05_3E63 -> base 0xEE011E60
		{.VMUL, {.QPR, .QPR, .GPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .RM_T32, .NONE, .NONE, .NONE}, 0xEE011E60, 0xEFC11FF0, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.I8, .NONE}},
	},
	// ---- VMLA / VMLS ----
	.VMLA = {
		{.VMLA, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0E000A00, 0x0FB00F50, .VFPV2, .A32, {}, {.F32, .NONE}},
		{.VMLA, {.DPR, .DPR, .DPR, .NONE, .NONE, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE, .NONE, .NONE}, 0x0E000B00, 0x0FB00F50, .VFPV2, .A32, {}, {.F64, .NONE}},
		// VFP F16 scalar
		{.VMLA, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0E000900, 0x0FB00F50, .HALF_FP, .A32, {}, {.F16, .NONE}},
		// MVE VMLA Qda, Qn, Rm (scalar)
		{.VMLA, {.QPR, .QPR, .GPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .RM_T32, .NONE, .NONE, .NONE}, 0xEE010E40, 0xEFC11FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.I8, .NONE}},
	},
	.VMLS = {
		{.VMLS, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0E000A40, 0x0FB00F50, .VFPV2, .A32, {}, {.F32, .NONE}},
		{.VMLS, {.DPR, .DPR, .DPR, .NONE, .NONE, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE, .NONE, .NONE}, 0x0E000B40, 0x0FB00F50, .VFPV2, .A32, {}, {.F64, .NONE}},
		// VFP F16 scalar
		{.VMLS, {.SPR, .SPR, .SPR, .NONE, .NONE, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE, .NONE, .NONE}, 0x0E000940, 0x0FB00F50, .HALF_FP, .A32, {}, {.F16, .NONE}},
	},
	// ---- VAND / VBIC / VORR / VORN / VEOR ----
	.VAND = {
		// VAND D: 1111 0010 0000 Vn Vd 0001 N 0 M 1 Vm  (no size; always byte-wise)
		{.VAND, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEF000150, 0xFFF10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VBIC = {
		// VBIC D: 1111 0010 0100 Vn Vd 0001 N 0 M 1 Vm
		{.VBIC, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEF100150, 0xFFF10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VORR = {
		{.VORR, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEF200150, 0xFFF10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VORN = {
		{.VORN, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEF300150, 0xFFF10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VEOR = {
		// U=1 distinguishes VEOR from VAND family
		{.VEOR, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xFF000150, 0xFFF10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	// ---- VMAX / VMIN ----
	.VMAX = {
		// MVE integer (VMAX.F32 doesn't exist in MVE; use VMAXNM.F32 instead)
		{.VMAX, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEF000640, 0xEFC10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	.VMIN = {
		// MVE integer (VMIN.F32 doesn't exist; use VMINNM.F32)
		{.VMIN, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEF000650, 0xEFC10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	// ---- VQADD / VQSUB (saturating) ----
	.VQADD = {
		// MVE
		{.VQADD, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEF000050, 0xEFC10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	.VQSUB = {
		// MVE
		{.VQSUB, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEF000250, 0xEFC10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	// ---- VHADD / VHSUB / VRHADD ----
	.VHADD = {
		// MVE
		{.VHADD, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEF000040, 0xEFC10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	.VHSUB = {
		// MVE
		{.VHSUB, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEF000240, 0xEFC10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	.VRHADD = {
		// MVE
		{.VRHADD, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEF000140, 0xEFC10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},

	// ---- VSHL register (variable shift) ----
	.VSHL = {
		// MVE
		{.VSHL, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEF000440, 0xEFC10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	// VSHR immediate
	.VSHR = {
		// MVE imm form (imm6 at bits 21:16)
		{.VSHR, {.QPR, .QPR, .IMM5, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NEON_SHIFT_IMM6, .NONE, .NONE, .NONE}, 0xEF800050, 0xEFC00F71, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.I32, .NONE}},
	},
	// VSRA imm
	.VSRA = {
		// MVE (imm6 at bits 21:16)
		{.VSRA, {.QPR, .QPR, .IMM5, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NEON_SHIFT_IMM6, .NONE, .NONE, .NONE}, 0xEF800150, 0xEFC00F71, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.I32, .NONE}},
	},
	// VQSHL imm (saturating shift left)
	.VQSHL = {
		// MVE
		{.VQSHL, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEF000450, 0xEFC10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	// VRSHL (rounding shift left)
	.VRSHL = {
		// MVE
		{.VRSHL, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEF000540, 0xEFC10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	// VRSHR (rounding shift right immediate)
	.VRSHR = {
		// MVE
		{.VRSHR, {.QPR, .QPR, .IMM5, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NEON_SHIFT_IMM6, .NONE, .NONE, .NONE}, 0xEF800250, 0xEFC00F71, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.I32, .NONE}},
	},

	// ---- VABS / VNEG ----
	.VABS = {
		// VFP scalar
		{.VABS, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EB00AC0, 0x0FBF0FD0, .VFPV2, .A32, {}, {.F32, .NONE}},
		{.VABS, {.DPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0x0EB00BC0, 0x0FBF0FD0, .VFPV2, .A32, {}, {.F64, .NONE}},
		// MVE integer + FP. Per LLVM: vabs.s8 q,q = FFB1_0340; vabs.f32 q,q = FFB9_0740 (bit 19 = 1 for FP).
		{.VABS, {.QPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xFFB10340, 0xFFF30FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
		{.VABS, {.QPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xFFB90740, 0xFFFB0FF1, .MVE_FP,  .T32, {thumb32=true, cond_in_28=false}, {.F32, .NONE}},
	},
	.VNEG = {
		{.VNEG, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EB10A40, 0x0FBF0FD0, .VFPV2, .A32, {}, {.F32, .NONE}},
		{.VNEG, {.DPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0x0EB10B40, 0x0FBF0FD0, .VFPV2, .A32, {}, {.F64, .NONE}},
		// MVE integer + FP. Per LLVM: vneg.s8 q,q = FFB1_03C0; vneg.f32 q,q = FFB9_07C0.
		{.VNEG, {.QPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xFFB103C0, 0xFFF30FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
		{.VNEG, {.QPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xFFB907C0, 0xFFFB0FF1, .MVE_FP,  .T32, {thumb32=true, cond_in_28=false}, {.F32, .NONE}},
	},



	// ---- VDUP (duplicate scalar/reg to vector) ----
	.VDUP = {
		// (encoder picks based on operand kinds)
		// From a core register: cond 1110 1bQ0 Vd Rt 1011 D0e1 0000, b:e the
		// size -- 00 .32, 01 .16, 10 .8.
		{.VDUP, {.DPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.VN_D, .RT_A32, .NONE, .NONE, .NONE, .NONE}, 0x0EC00B10, 0x0FF00F7F, .NEON, .A32, {}, {.SZ8, .NONE}},
		{.VDUP, {.QPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.VN_Q, .RT_A32, .NONE, .NONE, .NONE, .NONE}, 0x0EE00B10, 0x0FF00F7F, .NEON, .A32, {}, {.SZ8, .NONE}},
		{.VDUP, {.DPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.VN_D, .RT_A32, .NONE, .NONE, .NONE, .NONE}, 0x0E800B30, 0x0FF00F7F, .NEON, .A32, {}, {.SZ16, .NONE}},
		{.VDUP, {.QPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.VN_Q, .RT_A32, .NONE, .NONE, .NONE, .NONE}, 0x0EA00B30, 0x0FF00F7F, .NEON, .A32, {}, {.SZ16, .NONE}},
		{.VDUP, {.DPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.VN_D, .RT_A32, .NONE, .NONE, .NONE, .NONE}, 0x0E800B10, 0x0FF00F7F, .NEON, .A32, {}, {.SZ32, .NONE}},
		{.VDUP, {.QPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.VN_Q, .RT_A32, .NONE, .NONE, .NONE, .NONE}, 0x0EA00B10, 0x0FF00F7F, .NEON, .A32, {}, {.SZ32, .NONE}},
		// MVE VDUP Qd, Rt
		{.VDUP, {.QPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .RT_T32, .NONE, .NONE, .NONE, .NONE}, 0xEE800B10, 0xFFD00F5F, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.SZ32, .NONE}},
	},













	// =========================================================================
	// §11 -- T16 Thumb-1 + T32 Thumb-2 (Thumb-only mnemonics)
	// =========================================================================
	//
	// T16 entries store the 16-bit instruction in the LOW halfword of `bits`.
	// T32 entries pack as `bits = low_halfword | (high_halfword << 16)`.
	// Thumb mnemonics that share a name with an A32 mnemonic (.MOV, .ADD, ...)
	// have all their A32+T16+T32 entries listed within a single .MNEMONIC = {..}
	// block earlier in the file (see §1-§9). Only Thumb-exclusive mnemonics
	// appear here.

	// -------------------------------------------------------------------------
	// T16 Thumb-1 standalone mnemonics (no A32 equivalent under this name)
	// -------------------------------------------------------------------------

	// Format 1: Move shifted register
	//   000 op imm5 Rs Rd       op=00 LSL, 01 LSR, 10 ASR (imm)
	// Format 4: ALU register-form shifts share the LSL/LSR/ASR/ROR mnemonics:
	//   010000 op4 Rs Rd        op4=0010 LSL, 0011 LSR, 0100 ASR, 0111 ROR
	.LSL = {
		// A32: MOV reg with LSL #imm (cond 00011010 0000 Rd imm5 000 Rm)
		{.LSL, {.GPR, .GPR, .IMM5, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .A32_IMM_SHIFT, .NONE, .NONE, .NONE}, 0x01A00000, 0x0FFF0070, .BASE, .A32, {}, {}},
		// A32: MOV reg with LSL Rs (RSR form)
		{.LSL, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .RS_A32, .NONE, .NONE, .NONE},          0x01A00010, 0x0FFF00F0, .BASE, .A32, {}, {}},
	},
	.LSR = {
		{.LSR, {.GPR, .GPR, .IMM5, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .A32_IMM_SHIFT_32, .NONE, .NONE, .NONE}, 0x01A00020, 0x0FFF0070, .BASE, .A32, {}, {}},
		{.LSR, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .RS_A32, .NONE, .NONE, .NONE},          0x01A00030, 0x0FFF00F0, .BASE, .A32, {}, {}},
	},
	.ASR = {
		{.ASR, {.GPR, .GPR, .IMM5, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .A32_IMM_SHIFT_32, .NONE, .NONE, .NONE}, 0x01A00040, 0x0FFF0070, .BASE, .A32, {}, {}},
		{.ASR, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .RS_A32, .NONE, .NONE, .NONE},          0x01A00050, 0x0FFF00F0, .BASE, .A32, {}, {}},
	},
	.ROR = {
		{.ROR, {.GPR, .GPR, .IMM5, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .A32_IMM_SHIFT, .NONE, .NONE, .NONE}, 0x01A00060, 0x0FFF0070, .BASE, .A32, {}, {}},
		{.ROR, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .RS_A32, .NONE, .NONE, .NONE},          0x01A00070, 0x0FFF00F0, .BASE, .A32, {}, {}},
	},
	.RRX = {
		// RRX is ROR with imm=0 (cond 00011010 0000 Rd 00000110 Rm)
		{.RRX, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD, .RM_A32, .NONE, .NONE, .NONE, .NONE}, 0x01A00060, 0x0FFF0FF0, .BASE, .A32, {}, {}},
	},


	// T16 NEG Rd, Rm = RSB Rd, Rm, #0 (Format 4, op=1001)


	// MVE VCMLA, the rotation in bits 24:23.
	.VCMLA = {
		{.VCMLA,  {.QPR, .QPR, .QPR, .IMM, .NONE, .NONE},  {.QD_MVE, .QN_MVE, .QM_MVE, .MVE_ROT_CMLA, .NONE, .NONE}, 0xFC200840, 0xFE611FF1, .MVE_FP,  .T32, {thumb32=true, cond_in_28=false}, {.F16, .NONE}},
	},




	// =========================================================================
	// MVE polish (gaps from earlier pass)
	// =========================================================================
	// VQABS Qd, Qm:  1111 1111 1 D 11 size 00 Vd 0111 1 1 M 0 Vm
	// VQNEG Qd, Qm:  1111 1111 1 D 11 size 00 Vd 0111 1 1 M 1 Vm
	.VQABS = {
		{.VQABS, {.QPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xFFB00740, 0xFFF30FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	.VQNEG = {
		{.VQNEG, {.QPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xFFB007C0, 0xFFF30FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},

	// VMOVX Sd, Sm  (extract high F16 lane to bottom of Sd) -- ARMv8.2 FP16
	//   1111 1110 1 D 11 0000 Vd 1010 01 M 0 Vm
	.VMOVX = {
		{.VMOVX, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0xFEB00A40, 0xFFBF0FD0, .HALF_FP, .T32, {thumb32=true, cond_in_28=false}, {.F16, .NONE}},
	},
	// VINS Sd, Sm  (insert F16 from Sm into high half of Sd)
	//   1111 1110 1 D 11 0000 Vd 1010 11 M 0 Vm
	.VINS = {
		{.VINS, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0xFEB00AC0, 0xFFBF0FD0, .HALF_FP, .T32, {thumb32=true, cond_in_28=false}, {.F16, .NONE}},
	},

	// ---- MVE gather/scatter (vector offset addressing) ----------------------
	// Encoding: 1111 1100 1 D L size 1 Qm Qd 1110 sz1 Q M sz0 Rn (where Qm is the vector offset)
	// MVE gather/scatter (LLVM-verified, bit 23 = 1, sizes in bits 21:20):
	//   vldrb.u8  q,[r,q] = 0xFC92_2E06 -> base 0xFC900E00
	//   vldrh.u16 q,[r,q] = 0xFC92_2E96 -> base 0xFC900E90
	//   vldrw.u32 q,[r,q] = 0xFC92_2F46 -> base 0xFC900F40
	//   vldrd.u64 q,[r,q] = 0xFC92_2FD6 -> base 0xFC900FD0
	// VSTR scatter (LLVM-verified): top byte 0xEC (vs 0xFC for VLDR gather).
	//   vstrb.8 q1,[r2,q3] = 0xEC82_2E06 -> base 0xEC600E00

	// =========================================================================
	// VFP fixed-point conversions (VCVT with #fbits) -- ARMv7 VFPv3 / FP16
	// =========================================================================
	// VCVT.<Td>.<Tm> Vd, Vd, #fbits
	//   cond 1110 1 D 11 1 op 1 U sf sx Vd 101 sz 1 0 1 imm4
	//   op    = 1 (to fixed)      / 0 (from fixed)
	//   U     = 0 (signed)        / 1 (unsigned)
	//   sf    = 0 (.16)           / 1 (.32)
	//   sx    = same as sf (size selector for output)
	//   sz    = 0 (F32)           / 1 (F64)

	// =========================================================================
	// ARMv8-M Security Extensions (TrustZone-M) -- TT / TTT / TTA / TTAT
	// =========================================================================
	// T32 32-bit form: 1110 1000 0100 Rn 1111 Rd 0 0 A T 0 0000
	//   A=bit 7, T=bit 6
	//   TT   : A=0 T=0  -> 0xE840F000
	//   TTT  : A=0 T=1  -> 0xE840F040
	//   TTA  : A=1 T=0  -> 0xE840F080
	//   TTAT : A=1 T=1  -> 0xE840F0C0
	// mask 0xFFF0FFC0 keeps Rn and Rd variable, fixes A and T bits per mnemonic.
	.TT = {
		{.TT, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xE840F000, 0xFFF0F0C0, .V8M_SE, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.TTT = {
		{.TTT, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xE840F040, 0xFFF0F0C0, .V8M_SE, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.TTA = {
		{.TTA, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xE840F080, 0xFFF0F0C0, .V8M_SE, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.TTAT = {
		{.TTAT, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xE840F0C0, 0xFFF0F0C0, .V8M_SE, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	// SG: Secure Gateway -- 32-bit T32 instruction that looks like two NOPs
	//   bits = 0xE97F E97F
	.SG = {
		{.SG, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xE97FE97F, 0xFFFFFFFF, .V8M_SE, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	// BXNS Rm: T16 16-bit, 0100 0111 0 Rm[3:0] 100 = 0x4704 base, bit 2 = 1
	// BLXNS Rm: T16, 0100 0111 1 Rm[3:0] 100 = 0x4784 base

	// =========================================================================
	// PACBTI for ARMv8.1-M (Cortex-M85) -- pointer auth + branch target ID
	// =========================================================================
	// PAC R12, LR, SP:    T32 hint-class encoding 0xF3AF801D
	// PACBTI R12, LR, SP: combined PAC + BTI = 0xF3AF800D
	// AUT R12, LR, SP:    0xF3AF802D
	// AUTG Rd, Rn, Rm:    more general form using FB50F000 base
	// BTI:                HINT #15 = 0xF3AF80F0

	// =========================================================================
	// ARMv8.1-M low-overhead loops (LOL) -- can be used without MVE
	// =========================================================================
	// WLS  Rn, label:   1111 0000 0000 Rn 1100 0 imm10 imm1 1
	//                   high=F040, low varies
	// DLS  Rn:          1111 0000 0000 Rn 1110 0 000 0000 0000 0 1
	// LE   {LR,} label: 1111 0000 0000 1111 1100 imm5  ... 0 1
	// LETP / WLSTP / DLSTP: same family with TP variant bit
	// LCTP: 1111 0000 0000 1111 1110 0 0000 0000 0000 1

	// BF / BFL / BFLX / BFX (Branch Future, ARMv8.1-M). T32, word = hw0<<16|hw1.
	// bf-point: imm4 = (label-(PC+4))/2 at hw0[10:7]; branch target: val =
	// (label-(PC+4))/2 with J at hw1[11] and imm10 at hw1[10:1]; BFLX/BFX target
	// is a register Rm at hw0[3:0]. (BFCSEL has an extra else-target + condition.)
	.BF = {
		{.BF, {.REL_BF, .REL_BF, .NONE, .NONE, .NONE, .NONE}, {.BF_BOFF, .BF_BLOC, .NONE, .NONE, .NONE, .NONE}, 0xF040E001, 0xF87FF001, .V81M, .T32, {thumb32=true, cond_in_28=false, branch=true}, {}},
	},
	.BFL = {
		{.BFL, {.REL_BF, .REL_BF, .NONE, .NONE, .NONE, .NONE}, {.BF_BOFF, .BF_BLOC, .NONE, .NONE, .NONE, .NONE}, 0xF000C001, 0xF87FF001, .V81M, .T32, {thumb32=true, cond_in_28=false, branch=true}, {.SZ8, .NONE}},
	},
	.BFLX = {
		{.BFLX, {.REL_BF, .GPR, .NONE, .NONE, .NONE, .NONE}, {.BF_BOFF, .BF_RM, .NONE, .NONE, .NONE, .NONE}, 0xF070E001, 0xF870FFFF, .V81M, .T32, {thumb32=true, cond_in_28=false, branch=true}, {}},
	},
	.BFX = {
		{.BFX, {.REL_BF, .GPR, .NONE, .NONE, .NONE, .NONE}, {.BF_BOFF, .BF_RM, .NONE, .NONE, .NONE, .NONE}, 0xF060E001, 0xF870FFFF, .V81M, .T32, {thumb32=true, cond_in_28=false, branch=true}, {}},
	},
	// BFCSEL: bf-point + true-target (hw1, like BF) + 4-bit condition at hw0[5:2];
	// hw0[1] is a static marker. The else-target is the architectural fall-through
	// (implicit) so it is not a separate operand.
	.BFCSEL = {
		{.BFCSEL, {.REL_BF, .REL_BF, .IMM4, .NONE, .NONE, .NONE}, {.BF_BOFF, .BF_BLOC, .BFCSEL_COND, .NONE, .NONE, .NONE}, 0xF002E001, 0xF843F001, .V81M, .T32, {thumb32=true, cond_in_28=false, branch=true}, {.SZ8, .NONE}},
	},

	// =========================================================================
	// CDE -- the Custom Datapath Extension (v8-M)
	// =========================================================================
	//
	// A core can give coprocessors 0 to 7 to CDE, and the instructions then sit
	// where the generic coprocessor instructions would. Bit 28 is the A, the
	// accumulating form; bit 6 is the D, a register pair -- or for the vector
	// forms the Q, Q registers. Bit 11 is 0, and the coprocessor is 10-8.
	//
	//   CX1{A}  p, Rd, #imm13          111a 1110 00ii iiii  dddd 0ccc i0ii iiii
	//   CX2{A}  p, Rd, Rn, #imm9       111a 1110 01ii nnnn  dddd 0ccc i0ii iiii
	//   CX3{A}  p, Rd, Rn, Rm, #imm6   111a 1110 1iii nnnn  mmmm 0ccc i0ii dddd
	//   VCX1{A} p, Vd, #imm11          111a 110s 0D10 iiii  dddd 0ccc iQii iiii
	//   VCX2{A} p, Vd, Vm, #imm6       111a 110s 0D11 iiii  dddd 0ccc iQMi mmmm
	//   VCX3{A} p, Vd, Vn, Vm, #imm3   111a 110s 1Dii nnnn  dddd 0ccc NQMi mmmm
	//
	// The D forms name a pair, an even register and the one after it. A
	// register field of 1111 is APSR_nzcv. The vector forms are on S, D or Q
	// registers: s picks S or D, and where Q is set it is one more immediate
	// bit instead. A D or Q register's top bit must be 0 -- v8-M has sixteen D
	// registers and eight Q.
	//
	// These are preferred over the generic coprocessor instructions they
	// overlap: a core with CDE on a coprocessor has no generic one there.
	.CX1 = {
		{.CX1, {.COPROC_NUM, .GPR, .IMM, .NONE, .NONE, .NONE}, {.CDE_COPROC_FIELD, .RT_OR_APSR_NZCV, .CDE_IMM_CX1, .NONE, .NONE, .NONE}, 0xEE000000, 0xFFC00840, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
	},
	.CX1D = {
		{.CX1D, {.COPROC_NUM, .GPR, .GPR, .IMM, .NONE, .NONE}, {.CDE_COPROC_FIELD, .RT_T32, .RT_PAIR_NEXT, .CDE_IMM_CX1, .NONE, .NONE}, 0xEE000040, 0xFFC01840, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
	},
	.CX2 = {
		{.CX2, {.COPROC_NUM, .GPR, .GPR, .IMM, .NONE, .NONE}, {.CDE_COPROC_FIELD, .RT_OR_APSR_NZCV, .RN_OR_APSR_NZCV, .CDE_IMM_CX2, .NONE, .NONE}, 0xEE400000, 0xFFC00840, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
	},
	.CX2D = {
		{.CX2D, {.COPROC_NUM, .GPR, .GPR, .GPR, .IMM, .NONE}, {.CDE_COPROC_FIELD, .RT_T32, .RT_PAIR_NEXT, .RN_OR_APSR_NZCV, .CDE_IMM_CX2, .NONE}, 0xEE400040, 0xFFC01840, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
	},
	.CX3 = {
		{.CX3, {.COPROC_NUM, .GPR, .GPR, .GPR, .IMM, .NONE}, {.CDE_COPROC_FIELD, .RM_OR_APSR_NZCV, .RN_OR_APSR_NZCV, .RT_OR_APSR_NZCV, .CDE_IMM_CX3, .NONE}, 0xEE800000, 0xFF800840, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
	},
	.CX3D = {
		{.CX3D, {.COPROC_NUM, .GPR, .GPR, .GPR, .GPR, .IMM}, {.CDE_COPROC_FIELD, .RM_T32, .RM_PAIR_NEXT, .RN_OR_APSR_NZCV, .RT_OR_APSR_NZCV, .CDE_IMM_CX3}, 0xEE800040, 0xFF800841, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
	},
	.CX1A = {
		{.CX1A, {.COPROC_NUM, .GPR, .IMM, .NONE, .NONE, .NONE}, {.CDE_COPROC_FIELD, .RT_OR_APSR_NZCV, .CDE_IMM_CX1, .NONE, .NONE, .NONE}, 0xFE000000, 0xFFC00840, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
	},
	.CX1DA = {
		{.CX1DA, {.COPROC_NUM, .GPR, .GPR, .IMM, .NONE, .NONE}, {.CDE_COPROC_FIELD, .RT_T32, .RT_PAIR_NEXT, .CDE_IMM_CX1, .NONE, .NONE}, 0xFE000040, 0xFFC01840, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
	},
	.CX2A = {
		{.CX2A, {.COPROC_NUM, .GPR, .GPR, .IMM, .NONE, .NONE}, {.CDE_COPROC_FIELD, .RT_OR_APSR_NZCV, .RN_OR_APSR_NZCV, .CDE_IMM_CX2, .NONE, .NONE}, 0xFE400000, 0xFFC00840, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
	},
	.CX2DA = {
		{.CX2DA, {.COPROC_NUM, .GPR, .GPR, .GPR, .IMM, .NONE}, {.CDE_COPROC_FIELD, .RT_T32, .RT_PAIR_NEXT, .RN_OR_APSR_NZCV, .CDE_IMM_CX2, .NONE}, 0xFE400040, 0xFFC01840, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
	},
	.CX3A = {
		{.CX3A, {.COPROC_NUM, .GPR, .GPR, .GPR, .IMM, .NONE}, {.CDE_COPROC_FIELD, .RM_OR_APSR_NZCV, .RN_OR_APSR_NZCV, .RT_OR_APSR_NZCV, .CDE_IMM_CX3, .NONE}, 0xFE800000, 0xFF800840, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
	},
	.CX3DA = {
		{.CX3DA, {.COPROC_NUM, .GPR, .GPR, .GPR, .GPR, .IMM}, {.CDE_COPROC_FIELD, .RM_T32, .RM_PAIR_NEXT, .RN_OR_APSR_NZCV, .RT_OR_APSR_NZCV, .CDE_IMM_CX3}, 0xFE800040, 0xFF800841, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
	},
	.VCX1 = {
		{.VCX1, {.COPROC_NUM, .SPR, .IMM, .NONE, .NONE, .NONE}, {.CDE_COPROC_FIELD, .VD_S, .CDE_IMM_VCX1, .NONE, .NONE, .NONE}, 0xEC200000, 0xFFB00840, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
		{.VCX1, {.COPROC_NUM, .DPR, .IMM, .NONE, .NONE, .NONE}, {.CDE_COPROC_FIELD, .VD_D, .CDE_IMM_VCX1, .NONE, .NONE, .NONE}, 0xED200000, 0xFFF00840, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
		{.VCX1, {.COPROC_NUM, .QPR, .IMM, .NONE, .NONE, .NONE}, {.CDE_COPROC_FIELD, .QD_MVE, .CDE_IMM_VCX1, .NONE, .NONE, .NONE}, 0xEC200040, 0xFEF01840, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
	},
	.VCX2 = {
		{.VCX2, {.COPROC_NUM, .SPR, .SPR, .IMM, .NONE, .NONE}, {.CDE_COPROC_FIELD, .VD_S, .VM_S, .CDE_IMM_VCX2, .NONE, .NONE}, 0xEC300000, 0xFFB00840, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
		{.VCX2, {.COPROC_NUM, .DPR, .DPR, .IMM, .NONE, .NONE}, {.CDE_COPROC_FIELD, .VD_D, .VM_D, .CDE_IMM_VCX2, .NONE, .NONE}, 0xED300000, 0xFFF00860, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
		{.VCX2, {.COPROC_NUM, .QPR, .QPR, .IMM, .NONE, .NONE}, {.CDE_COPROC_FIELD, .QD_MVE, .QM_MVE, .CDE_IMM_VCX2, .NONE, .NONE}, 0xEC300040, 0xFEF01861, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
	},
	.VCX3 = {
		{.VCX3, {.COPROC_NUM, .SPR, .SPR, .SPR, .IMM, .NONE}, {.CDE_COPROC_FIELD, .VD_S, .VN_S, .VM_S, .CDE_IMM_VCX3, .NONE}, 0xEC800000, 0xFF800840, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
		{.VCX3, {.COPROC_NUM, .DPR, .DPR, .DPR, .IMM, .NONE}, {.CDE_COPROC_FIELD, .VD_D, .VN_D, .VM_D, .CDE_IMM_VCX3, .NONE}, 0xED800000, 0xFFC008E0, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
		{.VCX3, {.COPROC_NUM, .QPR, .QPR, .QPR, .IMM, .NONE}, {.CDE_COPROC_FIELD, .QD_MVE, .QN_MVE, .QM_MVE, .CDE_IMM_VCX3, .NONE}, 0xEC800040, 0xFEC118E1, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
	},
	.VCX1A = {
		{.VCX1A, {.COPROC_NUM, .SPR, .IMM, .NONE, .NONE, .NONE}, {.CDE_COPROC_FIELD, .VD_S, .CDE_IMM_VCX1, .NONE, .NONE, .NONE}, 0xFC200000, 0xFFB00840, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
		{.VCX1A, {.COPROC_NUM, .DPR, .IMM, .NONE, .NONE, .NONE}, {.CDE_COPROC_FIELD, .VD_D, .CDE_IMM_VCX1, .NONE, .NONE, .NONE}, 0xFD200000, 0xFFF00840, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
		{.VCX1A, {.COPROC_NUM, .QPR, .IMM, .NONE, .NONE, .NONE}, {.CDE_COPROC_FIELD, .QD_MVE, .CDE_IMM_VCX1, .NONE, .NONE, .NONE}, 0xFC200040, 0xFEF01840, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
	},
	.VCX2A = {
		{.VCX2A, {.COPROC_NUM, .SPR, .SPR, .IMM, .NONE, .NONE}, {.CDE_COPROC_FIELD, .VD_S, .VM_S, .CDE_IMM_VCX2, .NONE, .NONE}, 0xFC300000, 0xFFB00840, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
		{.VCX2A, {.COPROC_NUM, .DPR, .DPR, .IMM, .NONE, .NONE}, {.CDE_COPROC_FIELD, .VD_D, .VM_D, .CDE_IMM_VCX2, .NONE, .NONE}, 0xFD300000, 0xFFF00860, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
		{.VCX2A, {.COPROC_NUM, .QPR, .QPR, .IMM, .NONE, .NONE}, {.CDE_COPROC_FIELD, .QD_MVE, .QM_MVE, .CDE_IMM_VCX2, .NONE, .NONE}, 0xFC300040, 0xFEF01861, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
	},
	.VCX3A = {
		{.VCX3A, {.COPROC_NUM, .SPR, .SPR, .SPR, .IMM, .NONE}, {.CDE_COPROC_FIELD, .VD_S, .VN_S, .VM_S, .CDE_IMM_VCX3, .NONE}, 0xFC800000, 0xFF800840, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
		{.VCX3A, {.COPROC_NUM, .DPR, .DPR, .DPR, .IMM, .NONE}, {.CDE_COPROC_FIELD, .VD_D, .VN_D, .VM_D, .CDE_IMM_VCX3, .NONE}, 0xFD800000, 0xFFC008E0, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
		{.VCX3A, {.COPROC_NUM, .QPR, .QPR, .QPR, .IMM, .NONE}, {.CDE_COPROC_FIELD, .QD_MVE, .QN_MVE, .QM_MVE, .CDE_IMM_VCX3, .NONE}, 0xFC800040, 0xFEC118E1, .CDE, .T32, {thumb32=true, cond_in_28=false, preferred=true}, {}},
	},

	// =========================================================================
	// MVE (Helium) -- ARMv8.1-M Vector Extension (Cortex-M55, M85)
	// =========================================================================
	//
	// MVE uses Q-registers Q0..Q7 (3-bit field, bit 22 = 0). Element sizes B/H/W/D
	// selected by bits 21:20 (or 20 only for some forms). All MVE instructions
	// are T32 32-bit. Bit 28 distinguishes T32-class from NEON A32-class.
	//
	// Encodings below follow the ARMv8-M ARM Section C2 (MVE encoding).
	// Some bit patterns are educated estimates pending LLVM verification.

	// ---- Predication control ----------------------------------------------------
	// VPT<x> ENCODING_T1: 1111 1110 0 mask cond Qn 1111 1 size 0 1 Qm 1
	//   where mask in bits 13-11 encodes then/else pattern + length
	// VPT (LLVM-verified): vpt.i8 eq, q2, q3 = 0xFE45_0F06 -> base 0xFE010F00
	.VPT = {
		{.VPT, {.MVE_VPT_MASK, .COND, .QPR, .QPR, .NONE, .NONE}, {.MVE_VPT_MASK_FIELD, .NONE, .QN_MVE, .QM_MVE, .NONE, .NONE}, 0xFE010F00, 0xFE018FF0, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.I8, .NONE}},
	},
	// VPST = 0xFE71_0F4D
	.VPST = {
		{.VPST, {.MVE_VPT_MASK, .NONE, .NONE, .NONE, .NONE, .NONE}, {.MVE_VPT_MASK_FIELD, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xFE710F4D, 0xFFFFFFFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	// VPSEL (LLVM): vpsel q1, q2, q3 = 0xFE35_2F07 -> base 0xFE010F01
	.VPSEL = {
		{.VPSEL, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xFE010F01, 0xFFF10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.U8, .NONE}},
	},
	// VPNOT = 0xFE31_0F4D
	.VPNOT = {
		{.VPNOT, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xFE310F4D, 0xFFFFFFFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	// VCTP (LLVM): vctp.8 r3 = 0xF003_E801 -> base 0xF000E801 with Rn at bits 19:16
	.VCTP = {
		{.VCTP, {.GPR, .NONE, .NONE, .NONE, .NONE, .NONE}, {.RN_T32, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF000E801, 0xFFC0FFFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.SZ8, .NONE}},
	},

	// ---- MVE reductions (single Q -> GPR or pair) -----------------------------
	// MVE reductions (LLVM-verified bases for size-00 .S8 forms).
	.VADDV = {
		// vaddv.s8 r0, q3 = 0xEEF1_0F06 -> base 0xEEF10F00
		{.VADDV, {.GPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.MVE_RDA_EVEN, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xEEF10F00, 0xEFF31FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	.VADDVA = {
		// vaddva.s8 r0, q3 = 0xEEF1_0F26 -> base 0xEEF10F20
		{.VADDVA, {.GPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.MVE_RDA_EVEN, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xEEF10F20, 0xEFF31FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	.VADDLV = {
		// vaddlv.s32 r0,r1,q3 = 0xEE89_0F06 -> base 0xEE890F00 (Rd=R0 at 11:8, Rn=R1 implicit pair)
		{.VADDLV, {.GPR, .GPR, .QPR, .NONE, .NONE, .NONE}, {.MVE_RDALO, .MVE_RDAHI, .QM_MVE, .NONE, .NONE, .NONE}, 0xEE890F00, 0xEF8F1FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S32, .NONE}},
	},
	.VADDLVA = {
		{.VADDLVA, {.GPR, .GPR, .QPR, .NONE, .NONE, .NONE}, {.MVE_RDALO, .MVE_RDAHI, .QM_MVE, .NONE, .NONE, .NONE}, 0xEE890F20, 0xEF8F1FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S32, .NONE}},
	},
	.VMAXV = {
		// vmaxv.s8 r0, q3 = 0xEEE2_0F06 -> base 0xEEE20F00
		{.VMAXV, {.GPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xEEE20F00, 0xEFF30FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	.VMAXAV = {
		{.VMAXAV, {.GPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xEEE00F00, 0xEFF30FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	.VMINV = {
		// vminv.s8 r0, q3 = 0xEEE2_0F86 -> base 0xEEE20F80
		{.VMINV, {.GPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xEEE20F80, 0xEFF30FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	.VMINAV = {
		{.VMINAV, {.GPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xEEE00F80, 0xEFF30FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	.VMAXNMV = {
		// vmaxnmv.f32 r0, q3 = 0xEEEE_0F06 -> base 0xEEEE0F00
		{.VMAXNMV, {.GPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xEEEE0F00, 0xEFFF0FF1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}, {.F32, .NONE}},
	},
	.VMAXNMAV = {
		{.VMAXNMAV, {.GPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xEEEC0F00, 0xEFFF0FF1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}, {.F32, .NONE}},
	},
	.VMINNMV = {
		// vminnmv.f32 r0, q3 = 0xEEEE_0F86 -> base 0xEEEE0F80
		{.VMINNMV, {.GPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xEEEE0F80, 0xEFFF0FF1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}, {.F32, .NONE}},
	},
	.VMINNMAV = {
		{.VMINNMAV, {.GPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xEEEC0F80, 0xEFFF0FF1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}, {.F32, .NONE}},
	},

	// ---- MVE dual MAC reductions (representative; full B/T/X variants encoded similarly) ----
	// MVE MAC reductions (LLVM-verified for .S8 sizes; size bits in 21:20):
	//   vabav.s8 r0, q2, q3 = 0xEE84_0F07 -> base 0xEE800F01
	.VABAV = {
		{.VABAV, {.GPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.RT_T32, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEE800F01, 0xEFB10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	//   vmlav.s8 r0,q2,q3 = 0xEEF4_0F06 -> base 0xEEB00F00
	//   vmladav.s8 = same encoding as vmlav (alias)
	.VMLAV = {
		{.VMLAV, {.GPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.MVE_RDA_EVEN, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEEB00F00, 0xEFB11FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S32, .NONE}},
	},
	.VMLAVA = {
		{.VMLAVA, {.GPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.MVE_RDA_EVEN, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEEB00F20, 0xEFB11FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S32, .NONE}},
	},
	.VMLADAV = {
		{.VMLADAV, {.GPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.MVE_RDA_EVEN, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEEB00F00, 0xEFB11FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S32, .NONE}},
	},
	.VMLADAVA = {
		// vmladava.s8 = 0xEEF4_0F26 -> base 0xEEB00F20
		{.VMLADAVA, {.GPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.MVE_RDA_EVEN, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEEB00F20, 0xEFB11FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S32, .NONE}},
	},
	.VMLADAVX = {
		// vmladavx.s8 = 0xEEF4_1F06 -> base 0xEEB01F00
		{.VMLADAVX, {.GPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.MVE_RDA_EVEN, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEEB01F00, 0xEFB11FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S32, .NONE}},
	},
	.VMLADAVAX = {
		{.VMLADAVAX, {.GPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.MVE_RDA_EVEN, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEEB01F20, 0xEFB11FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S32, .NONE}},
	},
	.VMLSDAV = {
		// vmlsdav.s8 r0,q2,q3 = 0xFEF4_0E07 -> base 0xFEB00E01
		{.VMLSDAV, {.GPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.MVE_RDA_EVEN, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xFEB00E01, 0xFFB110F1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S32, .NONE}},
	},
	.VMLSDAVA = {
		{.VMLSDAVA, {.GPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.MVE_RDA_EVEN, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xFEB00E21, 0xFFB110D1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S32, .NONE}},
	},
	.VMLSDAVX = {
		{.VMLSDAVX, {.GPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.MVE_RDA_EVEN, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xFEB01E01, 0xFFB110F1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S32, .NONE}},
	},
	.VMLSDAVAX = {
		{.VMLSDAVAX, {.GPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.MVE_RDA_EVEN, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xFEB01E21, 0xFFB110D1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S32, .NONE}},
	},
	// Long-version (64-bit pair RdaLo, RdaHi)
	//   vmlaldav.s32 r0,r1,q2,q3 = 0xEE85_0E06 -> base 0xEE800E00 (with Qn at 19:17 expanded view)
	//   Need to verify exact base after Rn at bits 11:8 + Rd at bits 15:12.
	.VMLALDAV = {
		{.VMLALDAV, {.GPR, .GPR, .QPR, .QPR, .NONE, .NONE}, {.MVE_RDALO, .MVE_RDAHI, .QN_MVE, .QM_MVE, .NONE, .NONE}, 0xEE800E00, 0xEF811FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S16, .NONE}},
	},
	.VMLALDAVA = {
		{.VMLALDAVA, {.GPR, .GPR, .QPR, .QPR, .NONE, .NONE}, {.MVE_RDALO, .MVE_RDAHI, .QN_MVE, .QM_MVE, .NONE, .NONE}, 0xEE800E20, 0xEF811FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S16, .NONE}},
	},
	.VMLALDAVX = {
		{.VMLALDAVX, {.GPR, .GPR, .QPR, .QPR, .NONE, .NONE}, {.MVE_RDALO, .MVE_RDAHI, .QN_MVE, .QM_MVE, .NONE, .NONE}, 0xEE801E00, 0xEF811FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S16, .NONE}},
	},
	.VMLALDAVAX = {
		{.VMLALDAVAX, {.GPR, .GPR, .QPR, .QPR, .NONE, .NONE}, {.MVE_RDALO, .MVE_RDAHI, .QN_MVE, .QM_MVE, .NONE, .NONE}, 0xEE801E20, 0xEF811FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S16, .NONE}},
	},
	.VMLSLDAV = {
		// vmlsldav.s32 r0,r1,q2,q3 = 0xEE85_0E07 -> base 0xEE800E01
		{.VMLSLDAV, {.GPR, .GPR, .QPR, .QPR, .NONE, .NONE}, {.MVE_RDALO, .MVE_RDAHI, .QN_MVE, .QM_MVE, .NONE, .NONE}, 0xEE800E01, 0xFF811FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S16, .NONE}},
	},
	.VMLSLDAVA = {
		{.VMLSLDAVA, {.GPR, .GPR, .QPR, .QPR, .NONE, .NONE}, {.MVE_RDALO, .MVE_RDAHI, .QN_MVE, .QM_MVE, .NONE, .NONE}, 0xEE800E21, 0xFF811FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S16, .NONE}},
	},
	.VMLSLDAVX = {
		// vmlsldavx.s32 = 0xEE85_1E07 -> base 0xEE801E01
		{.VMLSLDAVX, {.GPR, .GPR, .QPR, .QPR, .NONE, .NONE}, {.MVE_RDALO, .MVE_RDAHI, .QN_MVE, .QM_MVE, .NONE, .NONE}, 0xEE801E01, 0xFF8110F1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S16, .NONE}},
	},
	.VMLSLDAVAX = {
		{.VMLSLDAVAX, {.GPR, .GPR, .QPR, .QPR, .NONE, .NONE}, {.MVE_RDALO, .MVE_RDAHI, .QN_MVE, .QM_MVE, .NONE, .NONE}, 0xEE801E21, 0xFF8110D1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S16, .NONE}},
	},
	// High-half rounding reductions:
	//   vrmlaldavh.s32 r0,r1,q2,q3 = 0xEE84_0F06 -> base 0xEE800F00
	//   vrmlsldavh.s32 r0,r1,q2,q3 = 0xFE84_0E07 -> base 0xFE800E01
	.VRMLALDAVH = {
		{.VRMLALDAVH, {.GPR, .GPR, .QPR, .QPR, .NONE, .NONE}, {.MVE_RDALO, .MVE_RDAHI, .QN_MVE, .QM_MVE, .NONE, .NONE}, 0xEE800F00, 0xEF811FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S32, .NONE}},
	},
	.VRMLALDAVHA = {
		{.VRMLALDAVHA, {.GPR, .GPR, .QPR, .QPR, .NONE, .NONE}, {.MVE_RDALO, .MVE_RDAHI, .QN_MVE, .QM_MVE, .NONE, .NONE}, 0xEE800F20, 0xEF811FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S32, .NONE}},
	},
	.VRMLALDAVHX = {
		{.VRMLALDAVHX, {.GPR, .GPR, .QPR, .QPR, .NONE, .NONE}, {.MVE_RDALO, .MVE_RDAHI, .QN_MVE, .QM_MVE, .NONE, .NONE}, 0xEE801F00, 0xEF811FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S32, .NONE}},
	},
	.VRMLALDAVHAX = {
		{.VRMLALDAVHAX, {.GPR, .GPR, .QPR, .QPR, .NONE, .NONE}, {.MVE_RDALO, .MVE_RDAHI, .QN_MVE, .QM_MVE, .NONE, .NONE}, 0xEE801F20, 0xEF811FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S32, .NONE}},
	},
	.VRMLSLDAVH = {
		{.VRMLSLDAVH, {.GPR, .GPR, .QPR, .QPR, .NONE, .NONE}, {.MVE_RDALO, .MVE_RDAHI, .QN_MVE, .QM_MVE, .NONE, .NONE}, 0xFE800E01, 0xFF8110F1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S32, .NONE}},
	},
	.VRMLSLDAVHA = {
		{.VRMLSLDAVHA, {.GPR, .GPR, .QPR, .QPR, .NONE, .NONE}, {.MVE_RDALO, .MVE_RDAHI, .QN_MVE, .QM_MVE, .NONE, .NONE}, 0xFE800E21, 0xFF8110D1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S32, .NONE}},
	},
	.VRMLSLDAVHX = {
		{.VRMLSLDAVHX, {.GPR, .GPR, .QPR, .QPR, .NONE, .NONE}, {.MVE_RDALO, .MVE_RDAHI, .QN_MVE, .QM_MVE, .NONE, .NONE}, 0xFE801E01, 0xFF8110F1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S32, .NONE}},
	},
	.VRMLSLDAVHAX = {
		{.VRMLSLDAVHAX, {.GPR, .GPR, .QPR, .QPR, .NONE, .NONE}, {.MVE_RDALO, .MVE_RDAHI, .QN_MVE, .QM_MVE, .NONE, .NONE}, 0xFE801E21, 0xFF8110D1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S32, .NONE}},
	},

	// ---- MVE complex arithmetic ------------------------------------------------
	.VCMUL = {
		{.VCMUL, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEE300E00, 0xEFF10FF1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}, {.F16, .NONE}},
	},
	.VHCADD = {
		{.VHCADD, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEE000F00, 0xEFF10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
		{.VHCADD, {.QPR, .QPR, .QPR, .IMM, .NONE, .NONE},  {.QD_MVE, .QN_MVE, .QM_MVE, .MVE_ROT_HCADD, .NONE, .NONE}, 0xEE000F00, 0xFFE10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},

	// ---- MVE shifts (specialized) ---------------------------------------------
	.VSHLC = {
		// VSHLC Qd, Rdm, #imm5  -- vector shift left with carry from GPR
		{.VSHLC, {.QPR, .GPR, .IMM5, .NONE, .NONE, .NONE}, {.QD_MVE, .RM_T32, .A32_IMM_SHIFT, .NONE, .NONE, .NONE}, 0xEE000FC0, 0xFFC00FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VBRSR = {
		// VBRSR Qd, Qn, Rm  -- bit reverse with shift right
		{.VBRSR, {.QPR, .QPR, .GPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .RM_T32, .NONE, .NONE, .NONE}, 0xEE011E60, 0xEFC11FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.I8, .NONE}},
	},

	// ---- MVE incrementing and decrementing duplicates ----------------------
	// VIDUP Qd, Rn, #imm      1110 1110 0 0 sz nnn 1  ddd 0 1111 i 110 111 i
	// VIWDUP Qd, Rn, Rm, #imm 1110 1110 0 0 sz nnn 1  ddd 0 1111 i 110 mmm i
	// Bit 12 set makes them the decrementing VDDUP and VDWDUP. Rn is even and
	// Rm odd, each named by half its number; Rm = 15 is the immediate form.
	// The step is 1, 2, 4 or 8, written as its log2.
	.VIDUP = {
		{.VIDUP, {.QPR, .GPR, .IMM, .NONE, .NONE, .NONE}, {.QD_MVE, .MVE_RN_EVEN, .MVE_DUP_IMM, .NONE, .NONE, .NONE}, 0xEE010F6E, 0xFFF11F7E, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.U8, .NONE}},
		{.VIDUP, {.QPR, .GPR, .IMM, .NONE, .NONE, .NONE}, {.QD_MVE, .MVE_RN_EVEN, .MVE_DUP_IMM, .NONE, .NONE, .NONE}, 0xEE110F6E, 0xFFF11F7E, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.U16, .NONE}},
		{.VIDUP, {.QPR, .GPR, .IMM, .NONE, .NONE, .NONE}, {.QD_MVE, .MVE_RN_EVEN, .MVE_DUP_IMM, .NONE, .NONE, .NONE}, 0xEE210F6E, 0xFFF11F7E, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.U32, .NONE}},
	},
	.VDDUP = {
		{.VDDUP, {.QPR, .GPR, .IMM, .NONE, .NONE, .NONE}, {.QD_MVE, .MVE_RN_EVEN, .MVE_DUP_IMM, .NONE, .NONE, .NONE}, 0xEE011F6E, 0xFFF11F7E, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.U8, .NONE}},
		{.VDDUP, {.QPR, .GPR, .IMM, .NONE, .NONE, .NONE}, {.QD_MVE, .MVE_RN_EVEN, .MVE_DUP_IMM, .NONE, .NONE, .NONE}, 0xEE111F6E, 0xFFF11F7E, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.U16, .NONE}},
		{.VDDUP, {.QPR, .GPR, .IMM, .NONE, .NONE, .NONE}, {.QD_MVE, .MVE_RN_EVEN, .MVE_DUP_IMM, .NONE, .NONE, .NONE}, 0xEE211F6E, 0xFFF11F7E, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.U32, .NONE}},
	},
	.VIWDUP = {
		{.VIWDUP, {.QPR, .GPR, .GPR, .IMM, .NONE, .NONE}, {.QD_MVE, .MVE_RN_EVEN, .MVE_RM_ODD, .MVE_DUP_IMM, .NONE, .NONE}, 0xEE010F60, 0xFFF11F70, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.U8, .NONE}},
		{.VIWDUP, {.QPR, .GPR, .GPR, .IMM, .NONE, .NONE}, {.QD_MVE, .MVE_RN_EVEN, .MVE_RM_ODD, .MVE_DUP_IMM, .NONE, .NONE}, 0xEE110F60, 0xFFF11F70, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.U16, .NONE}},
		{.VIWDUP, {.QPR, .GPR, .GPR, .IMM, .NONE, .NONE}, {.QD_MVE, .MVE_RN_EVEN, .MVE_RM_ODD, .MVE_DUP_IMM, .NONE, .NONE}, 0xEE210F60, 0xFFF11F70, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.U32, .NONE}},
	},
	.VDWDUP = {
		{.VDWDUP, {.QPR, .GPR, .GPR, .IMM, .NONE, .NONE}, {.QD_MVE, .MVE_RN_EVEN, .MVE_RM_ODD, .MVE_DUP_IMM, .NONE, .NONE}, 0xEE011F60, 0xFFF11F70, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.U8, .NONE}},
		{.VDWDUP, {.QPR, .GPR, .GPR, .IMM, .NONE, .NONE}, {.QD_MVE, .MVE_RN_EVEN, .MVE_RM_ODD, .MVE_DUP_IMM, .NONE, .NONE}, 0xEE111F60, 0xFFF11F70, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.U16, .NONE}},
		{.VDWDUP, {.QPR, .GPR, .GPR, .IMM, .NONE, .NONE}, {.QD_MVE, .MVE_RN_EVEN, .MVE_RM_ODD, .MVE_DUP_IMM, .NONE, .NONE}, 0xEE211F60, 0xFFF11F70, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.U32, .NONE}},
	},

	// MVE narrow B/T (LLVM-verified for .S16 sizes; T-form bit 12 = 1):
	.VMOVNB = {
		// vmovnb.s16 q1, q3 = 0xFE31_2E87 -> base 0xFE310E81
		{.VMOVNB, {.QPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xFE310E81, 0xFFF31FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.I16, .NONE}},
	},
	.VMOVNT = {
		{.VMOVNT, {.QPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xFE311E81, 0xFFF31FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.I16, .NONE}},
	},
	.VQMOVNB = {
		// vqmovnb.s16 q1, q3 = 0xEE33_2E07 -> base 0xEE330E01
		{.VQMOVNB, {.QPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xEE330E01, 0xFFF31FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S16, .NONE}},
	},
	.VQMOVNT = {
		{.VQMOVNT, {.QPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xEE331E01, 0xFFF31FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S16, .NONE}},
	},
	.VQMOVUNB = {
		// vqmovunb.s16 q1, q3 = 0xEE31_2E87 -> base 0xEE310E81
		{.VQMOVUNB, {.QPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xEE310E81, 0xFFF31FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S16, .NONE}},
	},
	.VQMOVUNT = {
		{.VQMOVUNT, {.QPR, .QPR, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NONE, .NONE, .NONE, .NONE}, 0xEE311E81, 0xFFF31FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S16, .NONE}},
	},
	// MVE widening (long) B/T forms:
	.VSHLLB = {
		// includes the size-prefix 101sss for .S8)
		{.VSHLLB, {.QPR, .QPR, .IMM5, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NEON_SHIFT_IMM6, .NONE, .NONE, .NONE}, 0xEE800F40, 0xEFC01FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VSHLLT = {
		{.VSHLLT, {.QPR, .QPR, .IMM5, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NEON_SHIFT_IMM6, .NONE, .NONE, .NONE}, 0xEE801F40, 0xEFC01FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VMULLB = {
		// vmullb.s8 q1, q2, q3 = 0xEE05_2E06 -> base 0xEE000E00
		{.VMULLB, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEE000E00, 0xEFC11FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	.VMULLT = {
		{.VMULLT, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEE001E00, 0xEFC11FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	// VMLALB/T/VMLSLB/T: LLVM doesn't seem to support direct mnemonics in
	// its assembler; encodings derived heuristically from VMULL B/T pattern
	.VMLALB = {
		{.VMLALB, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEE000E20, 0xEFC11FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VMLALT = {
		{.VMLALT, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEE001E20, 0xEFC11FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VMLSLB = {
		{.VMLSLB, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEE000E10, 0xEFC11FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VMLSLT = {
		{.VMLSLT, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEE001E10, 0xEFC11FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	// Narrow shift B/T forms (LLVM-verified):
	//   vshrnb.i16 q,q,#shift = 0xEE8F_2EC7 base 0xEE800EC1 (imm6 = 16-shift)
	//   vshrnt.i16 = bit 12 = 1
	.VSHRNB = {
		{.VSHRNB, {.QPR, .QPR, .IMM5, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NEON_SHIFT_IMM6, .NONE, .NONE, .NONE}, 0xEE800EC1, 0xEFC01FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VSHRNT = {
		{.VSHRNT, {.QPR, .QPR, .IMM5, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NEON_SHIFT_IMM6, .NONE, .NONE, .NONE}, 0xEE801EC1, 0xEFC01FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VRSHRNB = {
		{.VRSHRNB, {.QPR, .QPR, .IMM5, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NEON_SHIFT_IMM6, .NONE, .NONE, .NONE}, 0xFE800EC1, 0xFFC01FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VRSHRNT = {
		{.VRSHRNT, {.QPR, .QPR, .IMM5, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NEON_SHIFT_IMM6, .NONE, .NONE, .NONE}, 0xFE801EC1, 0xFFC01FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VQSHRNB = {
		// vqshrnb.s16 q,q,#4 = 0xEE8C_2F46 -> base 0xEE800F40
		{.VQSHRNB, {.QPR, .QPR, .IMM5, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NEON_SHIFT_IMM6, .NONE, .NONE, .NONE}, 0xEE800F40, 0xEFC01FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VQSHRNT = {
		{.VQSHRNT, {.QPR, .QPR, .IMM5, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NEON_SHIFT_IMM6, .NONE, .NONE, .NONE}, 0xEE801F40, 0xEFC01FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VQRSHRNB = {
		// vqrshrnb.s16 q,q,#4 = 0xEE8C_2F47 -> base 0xEE800F41
		{.VQRSHRNB, {.QPR, .QPR, .IMM5, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NEON_SHIFT_IMM6, .NONE, .NONE, .NONE}, 0xEE800F41, 0xEFC01FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VQRSHRNT = {
		{.VQRSHRNT, {.QPR, .QPR, .IMM5, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NEON_SHIFT_IMM6, .NONE, .NONE, .NONE}, 0xEE801F41, 0xEFC01FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VQSHRUNB = {
		// vqshrunb.s16 q,q,#4 = 0xEE8C_2FC6 -> base 0xEE800FC0
		{.VQSHRUNB, {.QPR, .QPR, .IMM5, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NEON_SHIFT_IMM6, .NONE, .NONE, .NONE}, 0xEE800FC0, 0xEFC01FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VQSHRUNT = {
		{.VQSHRUNT, {.QPR, .QPR, .IMM5, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NEON_SHIFT_IMM6, .NONE, .NONE, .NONE}, 0xEE801FC0, 0xEFC01FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VQRSHRUNB = {
		// vqrshrunb.s16 q,q,#4 = 0xFE8C_2FC6 -> base 0xFE800FC0
		{.VQRSHRUNB, {.QPR, .QPR, .IMM5, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NEON_SHIFT_IMM6, .NONE, .NONE, .NONE}, 0xFE800FC0, 0xFFC01FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VQRSHRUNT = {
		{.VQRSHRUNT, {.QPR, .QPR, .IMM5, .NONE, .NONE, .NONE}, {.QD_MVE, .QM_MVE, .NEON_SHIFT_IMM6, .NONE, .NONE, .NONE}, 0xFE801FC0, 0xFFC01FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},

	// ---- MVE Q-lane GPR move ---------------------------------------------------

	// MVE saturating doubling MAC (LLVM-verified for .S8 sizes):
	//   vqdmladh.s8 q1,q2,q3 = 0xEE04_2E06 -> base 0xEE000E00
	//   vqdmladhx (X-form bit 12 = 1)
	//   vqdmlsdh = top byte 0xFE (vs 0xEE)
	//   vqrdmladh = bit 0 = 1 (vs 0)
	.VQDMLADH = {
		{.VQDMLADH, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEE000E00, 0xEFC11FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	.VQDMLADHX = {
		{.VQDMLADHX, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEE001E00, 0xEFC11FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	.VQDMLSDH = {
		{.VQDMLSDH, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xFE000E00, 0xFFC11FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	.VQDMLSDHX = {
		{.VQDMLSDHX, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xFE001E00, 0xFFC11FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	.VQRDMLADH = {
		{.VQRDMLADH, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEE000E01, 0xEFC11FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	.VQRDMLADHX = {
		{.VQRDMLADHX, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xEE001E01, 0xEFC11FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	.VQRDMLSDH = {
		{.VQRDMLSDH, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xFE000E01, 0xFFC11FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},
	.VQRDMLSDHX = {
		{.VQRDMLSDHX, {.QPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .QN_MVE, .QM_MVE, .NONE, .NONE, .NONE}, 0xFE001E01, 0xFFC11FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.S8, .NONE}},
	},

	// ---- MVE load/store --------------------------------------------------------
	// VLDR<dt>/VSTR<dt> Qd, [Rn{, #imm}] (LLVM-verified contiguous load/store):
	//   vldrb.u8  q1, [r2] = 0xED92_3E00 -> base 0xED901E00
	//   vldrh.u16 q1, [r2] = 0xED92_3E80 -> base 0xED901E80
	//   vldrw.u32 q1, [r2] = 0xED92_3F00 -> base 0xED901F00
	//   vstrb.8   q1, [r2] = 0xED82_3E00 -> base 0xED801E00
	.VLDRB = {
		{.VLDRB, {.QPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .MEM_IMM12_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0xED901E00, 0xFFF01F00, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.U8, .NONE}},
		{.VLDRB, {.QPR, .MEM, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .RN_T32, .QM_MVE, .NONE, .NONE, .NONE}, 0xFC900E00, 0xFEF00FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.U8, .NONE}},
	},
	.VLDRH = {
		{.VLDRH, {.QPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .MEM_IMM12_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0xED901E80, 0xFFF01F80, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.U16, .NONE}},
		{.VLDRH, {.QPR, .MEM, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .RN_T32, .QM_MVE, .NONE, .NONE, .NONE}, 0xFC900E90, 0xFEF00FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.U16, .NONE}},
	},
	.VLDRW = {
		{.VLDRW, {.QPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .MEM_IMM12_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0xED901F00, 0xFFF01F80, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.U32, .NONE}},
		{.VLDRW, {.QPR, .MEM, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .RN_T32, .QM_MVE, .NONE, .NONE, .NONE}, 0xFC900F40, 0xFEF00FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.U32, .NONE}},
	},
	.VLDRD = {
		{.VLDRD, {.QPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .MEM_IMM12_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0xED901F80, 0xFFF01F80, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
		{.VLDRD, {.QPR, .MEM, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .RN_T32, .QM_MVE, .NONE, .NONE, .NONE}, 0xFC900FD0, 0xFEF00FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.U64, .NONE}},
	},
	.VSTRB = {
		{.VSTRB, {.QPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .MEM_IMM12_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0xED801E00, 0xFFF01F00, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.SZ8, .NONE}},
		{.VSTRB, {.QPR, .MEM, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .RN_T32, .QM_MVE, .NONE, .NONE, .NONE}, 0xEC600E00, 0xFEF00FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VSTRH = {
		{.VSTRH, {.QPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .MEM_IMM12_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0xED801E80, 0xFFF01F80, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.SZ16, .NONE}},
		{.VSTRH, {.QPR, .MEM, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .RN_T32, .QM_MVE, .NONE, .NONE, .NONE}, 0xEC600E90, 0xFEF00FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VSTRW = {
		{.VSTRW, {.QPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .MEM_IMM12_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0xED801F00, 0xFFF01F80, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.SZ32, .NONE}},
		{.VSTRW, {.QPR, .MEM, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .RN_T32, .QM_MVE, .NONE, .NONE, .NONE}, 0xEC600F40, 0xFEF00FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	.VSTRD = {
		{.VSTRD, {.QPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .MEM_IMM12_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0xED801F80, 0xFFF01F80, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
		{.VSTRD, {.QPR, .MEM, .QPR, .NONE, .NONE, .NONE}, {.QD_MVE, .RN_T32, .QM_MVE, .NONE, .NONE, .NONE}, 0xEC600FD0, 0xFEF00FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}},
	},
	// Interleaved load/store -- 2-vector
	.VLD20 = {
		{.VLD20, {.QPR_MVE_LIST, .MEM, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .MEM_IMM8_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0xFC901E00, 0xFFF01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.SZ8, .NONE}},
	},
	.VLD21 = {
		{.VLD21, {.QPR_MVE_LIST, .MEM, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .MEM_IMM8_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0xFC901E20, 0xFFF01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.SZ8, .NONE}},
	},
	.VLD40 = {
		{.VLD40, {.QPR_MVE_LIST, .MEM, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .MEM_IMM8_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0xFC901E01, 0xFFF01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.SZ8, .NONE}},
	},
	.VLD41 = {
		{.VLD41, {.QPR_MVE_LIST, .MEM, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .MEM_IMM8_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0xFC901E21, 0xFFF01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.SZ8, .NONE}},
	},
	.VLD42 = {
		{.VLD42, {.QPR_MVE_LIST, .MEM, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .MEM_IMM8_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0xFC901E41, 0xFFF01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.SZ8, .NONE}},
	},
	.VLD43 = {
		{.VLD43, {.QPR_MVE_LIST, .MEM, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .MEM_IMM8_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0xFC901E61, 0xFFF01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.SZ8, .NONE}},
	},
	.VST20 = {
		{.VST20, {.QPR_MVE_LIST, .MEM, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .MEM_IMM8_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0xFC801E00, 0xFFF01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.SZ8, .NONE}},
	},
	.VST21 = {
		{.VST21, {.QPR_MVE_LIST, .MEM, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .MEM_IMM8_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0xFC801E20, 0xFFF01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.SZ8, .NONE}},
	},
	.VST40 = {
		{.VST40, {.QPR_MVE_LIST, .MEM, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .MEM_IMM8_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0xFC801E01, 0xFFF01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.SZ8, .NONE}},
	},
	.VST41 = {
		{.VST41, {.QPR_MVE_LIST, .MEM, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .MEM_IMM8_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0xFC801E21, 0xFFF01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.SZ8, .NONE}},
	},
	.VST42 = {
		{.VST42, {.QPR_MVE_LIST, .MEM, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .MEM_IMM8_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0xFC801E41, 0xFFF01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.SZ8, .NONE}},
	},
	.VST43 = {
		{.VST43, {.QPR_MVE_LIST, .MEM, .NONE, .NONE, .NONE, .NONE}, {.QD_MVE, .MEM_IMM8_OFFSET, .NONE, .NONE, .NONE, .NONE}, 0xFC801E61, 0xFFF01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {.SZ8, .NONE}},
	},

	// Unprivileged (translate) post-indexed loads/stores: the post-index form
	// with the W bit (21) set. Word/byte use imm12, half/signed use imm8 split.
	.LDRT = {
		{.LDRT,   {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x04300000, 0x0F700000, .BASE, .A32, {}, {}},
		{.LDRT, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_SHIFTED_POST, .NONE, .NONE, .NONE, .NONE}, 0x06300000, 0x0F700010, .BASE, .A32, {}, {}},
	},
	.LDRBT = {
		{.LDRBT,  {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x04700000, 0x0F700000, .BASE, .A32, {}, {}},
		{.LDRBT, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_SHIFTED_POST, .NONE, .NONE, .NONE, .NONE}, 0x06700000, 0x0F700010, .BASE, .A32, {}, {}},
	},
	.STRT = {
		{.STRT,   {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x04200000, 0x0F700000, .BASE, .A32, {}, {}},
		{.STRT, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_SHIFTED_POST, .NONE, .NONE, .NONE, .NONE}, 0x06200000, 0x0F700010, .BASE, .A32, {}, {}},
	},
	.STRBT = {
		{.STRBT,  {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x04600000, 0x0F700000, .BASE, .A32, {}, {}},
		{.STRBT, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_SHIFTED_POST, .NONE, .NONE, .NONE, .NONE}, 0x06600000, 0x0F700010, .BASE, .A32, {}, {}},
	},
	.LDRHT = {
		{.LDRHT,  {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_IMM8_POST_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x007000B0, 0x0F7000F0, .BASE, .A32, {}, {}},
		{.LDRHT, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_POST, .NONE, .NONE, .NONE, .NONE}, 0x003000B0, 0x0F700FF0, .BASE, .A32, {}, {}},
	},
	.STRHT = {
		{.STRHT,  {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_IMM8_POST_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x006000B0, 0x0F7000F0, .BASE, .A32, {}, {}},
		{.STRHT, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_POST, .NONE, .NONE, .NONE, .NONE}, 0x002000B0, 0x0F700FF0, .BASE, .A32, {}, {}},
	},
	.LDRSBT = {
		{.LDRSBT, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_IMM8_POST_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x007000D0, 0x0F7000F0, .BASE, .A32, {}, {}},
		{.LDRSBT, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_POST, .NONE, .NONE, .NONE, .NONE}, 0x003000D0, 0x0F700FF0, .BASE, .A32, {}, {}},
	},
	.LDRSHT = {
		{.LDRSHT, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_IMM8_POST_INDEX, .NONE, .NONE, .NONE, .NONE}, 0x007000F0, 0x0F7000F0, .BASE, .A32, {}, {}},
		{.LDRSHT, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_A32, .MEM_REG_POST, .NONE, .NONE, .NONE, .NONE}, 0x003000F0, 0x0F700FF0, .BASE, .A32, {}, {}},
	},

	.VCVTR = {
		{.VCVTR, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EBD0A40, 0x0FBF0FD0, .VFPV2, .A32, {}, {.S32, .F32}},
		{.VCVTR, {.SPR, .SPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE, .NONE, .NONE}, 0x0EBC0A40, 0x0FBF0FD0, .VFPV2, .A32, {}, {.U32, .F32}},
		{.VCVTR, {.SPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0x0EBD0B40, 0x0FBF0FD0, .VFPV2, .A32, {}, {.S32, .F64}},
		{.VCVTR, {.SPR, .DPR, .NONE, .NONE, .NONE, .NONE}, {.VD_S, .VM_D, .NONE, .NONE, .NONE, .NONE}, 0x0EBC0B40, 0x0FBF0FD0, .VFPV2, .A32, {}, {.U32, .F64}},
	},


	// NEON (saturating) doubling multiply-high by scalar Dm[lane]:
	//   .16 -> Dm in D0..D7 (bits 2:0), lane at bit5:bit3;  .32 -> D0..D15, lane bit5.
	// VMOV (ARM core register to scalar): Dd[lane], Rt. The lane bits depend on
	// the element size (see VMOV_LANE_8/16/32); bit22/bit5 carry the size.

	// MVE (M-profile vector) multiply-subtract-across-vector reduce, halving
	// complex add (saturating), and complex multiply-accumulate. T32; the
	// complex ops carry a rotation immediate (degrees).
	// One form per mnemonic with the element-size bits left variable in the
	// mask (the MVE convention); the complex ops encode the rotation immediate.
	// MVE multiply-subtract reduce (Rd at 15:12, Qn at 19:17, Qm at 3:1 -- the
	// proper 3-bit MVE Q fields, .s16 form). VMLSVA accumulates (bit 5).
	.VMLSV      = { {.VMLSV,      {.GPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.RDLO_A32, .VN_Q_MVE, .VM_Q_MVE, .NONE, .NONE, .NONE}, 0xEEF00E01, 0xFFF10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}} },
	.VMLSVA     = { {.VMLSVA,     {.GPR, .QPR, .QPR, .NONE, .NONE, .NONE}, {.RDLO_A32, .VN_Q_MVE, .VM_Q_MVE, .NONE, .NONE, .NONE}, 0xEEF00E21, 0xFFF10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}, {}} },

	// SPECGEN:END
	.LDMIB = {
		{.LDMIB, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0x09900000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.LDMIB, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0x09B00000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.LDMIB, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST_USER, .NONE, .NONE, .NONE, .NONE}, 0x09D00000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.LDMIB, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST_USER, .NONE, .NONE, .NONE, .NONE}, 0x09F00000, 0x0FF00000, .BASE, .A32, {}, {}},
	},
	.LDMDA = {
		{.LDMDA, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0x08100000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.LDMDA, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0x08300000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.LDMDA, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST_USER, .NONE, .NONE, .NONE, .NONE}, 0x08500000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.LDMDA, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST_USER, .NONE, .NONE, .NONE, .NONE}, 0x08700000, 0x0FF00000, .BASE, .A32, {}, {}},
	},
	.LDMDB = {
		{.LDMDB, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0x09100000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.LDMDB, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0x09300000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.LDMDB, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST_USER, .NONE, .NONE, .NONE, .NONE}, 0x09500000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.LDMDB, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST_USER, .NONE, .NONE, .NONE, .NONE}, 0x09700000, 0x0FF00000, .BASE, .A32, {}, {}},
	},
	.STMIB = {
		{.STMIB, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0x09800000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.STMIB, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0x09A00000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.STMIB, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST_USER, .NONE, .NONE, .NONE, .NONE}, 0x09C00000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.STMIB, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST_USER, .NONE, .NONE, .NONE, .NONE}, 0x09E00000, 0x0FF00000, .BASE, .A32, {}, {}},
	},
	.STMDA = {
		{.STMDA, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0x08000000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.STMDA, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0x08200000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.STMDA, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST_USER, .NONE, .NONE, .NONE, .NONE}, 0x08400000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.STMDA, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST_USER, .NONE, .NONE, .NONE, .NONE}, 0x08600000, 0x0FF00000, .BASE, .A32, {}, {}},
	},
	.STMDB = {
		{.STMDB, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0x09000000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.STMDB, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0x09200000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.STMDB, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST_USER, .NONE, .NONE, .NONE, .NONE}, 0x09400000, 0x0FF00000, .BASE, .A32, {}, {}},
		{.STMDB, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST_USER, .NONE, .NONE, .NONE, .NONE}, 0x09600000, 0x0FF00000, .BASE, .A32, {}, {}},
	},
}

