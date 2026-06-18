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
//   §10 A32 Advanced SIMD (NEON) -- vector arithmetic + load/store
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
		{.ADD, {.GPR, .GPR, .IMM_MOD, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD,   .NONE}, 0x02800000, 0x0FE00000, .BASE, .A32, {}},
		// ADD reg: cond 0000 0100 S Rn Rd shift_imm shift_type 0 Rm
		{.ADD, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00800000, 0x0FE00010, .BASE, .A32, {}},
		// ADD rsr: cond 0000 0100 S Rn Rd Rs 0 shift_type 1 Rm
		{.ADD, {.GPR, .GPR, .GPR_RSR, .NONE},     {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00800010, 0x0FE00090, .BASE, .A32, {}},
		// ADDS variants
		{.ADD, {.GPR, .GPR, .IMM_MOD, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD,   .NONE}, 0x02900000, 0x0FF00000, .BASE, .A32, {sets_flags=true}},
		{.ADD, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00900000, 0x0FF00010, .BASE, .A32, {sets_flags=true}},
		{.ADD, {.GPR, .GPR, .GPR_RSR, .NONE},     {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00900010, 0x0FF00090, .BASE, .A32, {sets_flags=true}},
		// T16 Format 2 ADD reg (3-reg): 00011 00 Rm Rn Rd
		{.ADD, {.GPR_LOW, .GPR_LOW, .GPR_LOW, .NONE}, {.RD_T16_LO, .RN_T16_LO, .RM_T16_LO, .NONE}, 0x00001800, 0x0000FE00, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 2 ADD imm3: 00011 10 imm3 Rn Rd
		{.ADD, {.GPR_LOW, .GPR_LOW, .IMM3, .NONE}, {.RD_T16_LO, .RN_T16_LO, .NONE, .NONE}, 0x00001C00, 0x0000FE00, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 3 ADD imm8: 00110 Rd imm8
		{.ADD, {.GPR_LOW, .IMM8, .NONE, .NONE}, {.RD_T16_HI, .NONE, .NONE, .NONE}, 0x00003000, 0x0000F800, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 5 hi-reg ADD: 010001 00 H1 H2 Rm Rd
		{.ADD, {.GPR, .GPR, .NONE, .NONE}, {.RD_T16_HI, .RM_T16_HI, .NONE, .NONE}, 0x00004400, 0x0000FF00, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 12 ADD SP+imm: 10101 Rd imm8 (ADD Rd, SP, #imm8 << 2)
		{.ADD, {.GPR_LOW, .GPR, .IMM8, .NONE}, {.RD_T16_HI, .NONE, .NONE, .NONE}, 0x0000A800, 0x0000F800, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 13 ADD SP, #imm7: 10110000 0 imm7
		{.ADD, {.GPR, .IMM8, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0000B000, 0x0000FF80, .THUMB, .T32, {cond_in_28=false}},
	},
	.ADC = {
		{.ADC, {.GPR, .GPR, .IMM_MOD, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD,   .NONE}, 0x02A00000, 0x0FE00000, .BASE, .A32, {}},
		{.ADC, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00A00000, 0x0FE00010, .BASE, .A32, {}},
		{.ADC, {.GPR, .GPR, .GPR_RSR, .NONE},     {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00A00010, 0x0FE00090, .BASE, .A32, {}},
		{.ADC, {.GPR, .GPR, .IMM_MOD, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD,   .NONE}, 0x02B00000, 0x0FF00000, .BASE, .A32, {sets_flags=true}},
		{.ADC, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00B00000, 0x0FF00010, .BASE, .A32, {sets_flags=true}},
		{.ADC, {.GPR, .GPR, .GPR_RSR, .NONE},     {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00B00010, 0x0FF00090, .BASE, .A32, {sets_flags=true}},
		// T16 Format 4 ADC: 010000 0101 Rm Rd
		{.ADC, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x00004140, 0x0000FFC0, .THUMB, .T32, {cond_in_28=false}},
		// T32 ADC imm/reg (op=1010)
		{.ADC, {.GPR, .GPR, .IMM_T32_MOD, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE}, 0xF1400000, 0xFBE08000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		{.ADC, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xEB400000, 0xFFE08000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SUB = {
		{.SUB, {.GPR, .GPR, .IMM_MOD, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD,   .NONE}, 0x02400000, 0x0FE00000, .BASE, .A32, {}},
		{.SUB, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00400000, 0x0FE00010, .BASE, .A32, {}},
		{.SUB, {.GPR, .GPR, .GPR_RSR, .NONE},     {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00400010, 0x0FE00090, .BASE, .A32, {}},
		{.SUB, {.GPR, .GPR, .IMM_MOD, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD,   .NONE}, 0x02500000, 0x0FF00000, .BASE, .A32, {sets_flags=true}},
		{.SUB, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00500000, 0x0FF00010, .BASE, .A32, {sets_flags=true}},
		{.SUB, {.GPR, .GPR, .GPR_RSR, .NONE},     {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00500010, 0x0FF00090, .BASE, .A32, {sets_flags=true}},
		// T16 Format 2 SUB reg (3-reg): 00011 01 Rm Rn Rd
		{.SUB, {.GPR_LOW, .GPR_LOW, .GPR_LOW, .NONE}, {.RD_T16_LO, .RN_T16_LO, .RM_T16_LO, .NONE}, 0x00001A00, 0x0000FE00, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 2 SUB imm3: 00011 11 imm3 Rn Rd
		{.SUB, {.GPR_LOW, .GPR_LOW, .IMM3, .NONE}, {.RD_T16_LO, .RN_T16_LO, .NONE, .NONE}, 0x00001E00, 0x0000FE00, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 3 SUB imm8: 00111 Rd imm8
		{.SUB, {.GPR_LOW, .IMM8, .NONE, .NONE}, {.RD_T16_HI, .NONE, .NONE, .NONE}, 0x00003800, 0x0000F800, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 13 SUB SP, #imm7: 10110000 1 imm7
		{.SUB, {.GPR, .IMM8, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0000B080, 0x0000FF80, .THUMB, .T32, {cond_in_28=false}},
	},
	.SBC = {
		{.SBC, {.GPR, .GPR, .IMM_MOD, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD,   .NONE}, 0x02C00000, 0x0FE00000, .BASE, .A32, {}},
		{.SBC, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00C00000, 0x0FE00010, .BASE, .A32, {}},
		{.SBC, {.GPR, .GPR, .GPR_RSR, .NONE},     {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00C00010, 0x0FE00090, .BASE, .A32, {}},
		{.SBC, {.GPR, .GPR, .IMM_MOD, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD,   .NONE}, 0x02D00000, 0x0FF00000, .BASE, .A32, {sets_flags=true}},
		{.SBC, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00D00000, 0x0FF00010, .BASE, .A32, {sets_flags=true}},
		{.SBC, {.GPR, .GPR, .GPR_RSR, .NONE},     {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00D00010, 0x0FF00090, .BASE, .A32, {sets_flags=true}},
		// T16 Format 4 SBC: 010000 0110 Rm Rd
		{.SBC, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x00004180, 0x0000FFC0, .THUMB, .T32, {cond_in_28=false}},
		// T32 SBC imm/reg (op=1011)
		{.SBC, {.GPR, .GPR, .IMM_T32_MOD, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE}, 0xF1600000, 0xFBE08000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		{.SBC, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xEB600000, 0xFFE08000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.RSB = {
		{.RSB, {.GPR, .GPR, .IMM_MOD, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD,   .NONE}, 0x02600000, 0x0FE00000, .BASE, .A32, {}},
		{.RSB, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00600000, 0x0FE00010, .BASE, .A32, {}},
		{.RSB, {.GPR, .GPR, .GPR_RSR, .NONE},     {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00600010, 0x0FE00090, .BASE, .A32, {}},
		{.RSB, {.GPR, .GPR, .IMM_MOD, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD,   .NONE}, 0x02700000, 0x0FF00000, .BASE, .A32, {sets_flags=true}},
		{.RSB, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00700000, 0x0FF00010, .BASE, .A32, {sets_flags=true}},
		{.RSB, {.GPR, .GPR, .GPR_RSR, .NONE},     {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00700010, 0x0FF00090, .BASE, .A32, {sets_flags=true}},
		// T32 RSB imm/reg (op=1110)
		{.RSB, {.GPR, .GPR, .IMM_T32_MOD, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE}, 0xF1C00000, 0xFBE08000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		{.RSB, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xEBC00000, 0xFFE08000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.RSC = {
		{.RSC, {.GPR, .GPR, .IMM_MOD, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD,   .NONE}, 0x02E00000, 0x0FE00000, .BASE, .A32, {}},
		{.RSC, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00E00000, 0x0FE00010, .BASE, .A32, {}},
		{.RSC, {.GPR, .GPR, .GPR_RSR, .NONE},     {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00E00010, 0x0FE00090, .BASE, .A32, {}},
		{.RSC, {.GPR, .GPR, .IMM_MOD, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD,   .NONE}, 0x02F00000, 0x0FF00000, .BASE, .A32, {sets_flags=true}},
		{.RSC, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00F00000, 0x0FF00010, .BASE, .A32, {sets_flags=true}},
		{.RSC, {.GPR, .GPR, .GPR_RSR, .NONE},     {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00F00010, 0x0FF00090, .BASE, .A32, {sets_flags=true}},
	},
	.AND = {
		{.AND, {.GPR, .GPR, .IMM_MOD, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD,   .NONE}, 0x02000000, 0x0FE00000, .BASE, .A32, {}},
		{.AND, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00000000, 0x0FE00010, .BASE, .A32, {}},
		{.AND, {.GPR, .GPR, .GPR_RSR, .NONE},     {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00000010, 0x0FE00090, .BASE, .A32, {}},
		{.AND, {.GPR, .GPR, .IMM_MOD, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD,   .NONE}, 0x02100000, 0x0FF00000, .BASE, .A32, {sets_flags=true}},
		{.AND, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00100000, 0x0FF00010, .BASE, .A32, {sets_flags=true}},
		{.AND, {.GPR, .GPR, .GPR_RSR, .NONE},     {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00100010, 0x0FF00090, .BASE, .A32, {sets_flags=true}},
		// T16 Format 4 AND: 010000 0000 Rm Rd
		{.AND, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x00004000, 0x0000FFC0, .THUMB, .T32, {cond_in_28=false}},
		// T32 AND imm12: high=11110 i 0 0000 S Rn  low=0 imm3 Rd imm8
		{.AND, {.GPR, .GPR, .IMM_T32_MOD, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE}, 0xF0000000, 0xFBE08000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		{.AND, {.GPR, .GPR, .IMM_T32_MOD, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE}, 0xF0100000, 0xFBE08000, .V6T2, .T32, {thumb32=true, cond_in_28=false, sets_flags=true}},
		// T32 AND reg: high=11101 01 0000 S Rn  low=imm3 Rd imm2 type Rm
		{.AND, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xEA000000, 0xFFE08000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		{.AND, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xEA100000, 0xFFE08000, .V6T2, .T32, {thumb32=true, cond_in_28=false, sets_flags=true}},
	},
	.EOR = {
		{.EOR, {.GPR, .GPR, .IMM_MOD, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD,   .NONE}, 0x02200000, 0x0FE00000, .BASE, .A32, {}},
		{.EOR, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00200000, 0x0FE00010, .BASE, .A32, {}},
		{.EOR, {.GPR, .GPR, .GPR_RSR, .NONE},     {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00200010, 0x0FE00090, .BASE, .A32, {}},
		{.EOR, {.GPR, .GPR, .IMM_MOD, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD,   .NONE}, 0x02300000, 0x0FF00000, .BASE, .A32, {sets_flags=true}},
		{.EOR, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00300000, 0x0FF00010, .BASE, .A32, {sets_flags=true}},
		{.EOR, {.GPR, .GPR, .GPR_RSR, .NONE},     {.RD, .RN_A32, .RM_A32,         .NONE}, 0x00300010, 0x0FF00090, .BASE, .A32, {sets_flags=true}},
		// T16 Format 4 EOR: 010000 0001 Rm Rd
		{.EOR, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x00004040, 0x0000FFC0, .THUMB, .T32, {cond_in_28=false}},
		// T32 EOR imm/reg
		{.EOR, {.GPR, .GPR, .IMM_T32_MOD, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE}, 0xF0800000, 0xFBE08000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		{.EOR, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xEA800000, 0xFFE08000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.ORR = {
		{.ORR, {.GPR, .GPR, .IMM_MOD, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD,   .NONE}, 0x03800000, 0x0FE00000, .BASE, .A32, {}},
		{.ORR, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD, .RN_A32, .RM_A32,         .NONE}, 0x01800000, 0x0FE00010, .BASE, .A32, {}},
		{.ORR, {.GPR, .GPR, .GPR_RSR, .NONE},     {.RD, .RN_A32, .RM_A32,         .NONE}, 0x01800010, 0x0FE00090, .BASE, .A32, {}},
		{.ORR, {.GPR, .GPR, .IMM_MOD, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD,   .NONE}, 0x03900000, 0x0FF00000, .BASE, .A32, {sets_flags=true}},
		{.ORR, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD, .RN_A32, .RM_A32,         .NONE}, 0x01900000, 0x0FF00010, .BASE, .A32, {sets_flags=true}},
		{.ORR, {.GPR, .GPR, .GPR_RSR, .NONE},     {.RD, .RN_A32, .RM_A32,         .NONE}, 0x01900010, 0x0FF00090, .BASE, .A32, {sets_flags=true}},
		// T16 Format 4 ORR: 010000 1100 Rm Rd
		{.ORR, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x00004300, 0x0000FFC0, .THUMB, .T32, {cond_in_28=false}},
		// T32 ORR imm/reg (op=0010)
		{.ORR, {.GPR, .GPR, .IMM_T32_MOD, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE}, 0xF0400000, 0xFBE08000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		{.ORR, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xEA400000, 0xFFE08000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.BIC = {
		{.BIC, {.GPR, .GPR, .IMM_MOD, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD,   .NONE}, 0x03C00000, 0x0FE00000, .BASE, .A32, {}},
		{.BIC, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD, .RN_A32, .RM_A32,         .NONE}, 0x01C00000, 0x0FE00010, .BASE, .A32, {}},
		{.BIC, {.GPR, .GPR, .GPR_RSR, .NONE},     {.RD, .RN_A32, .RM_A32,         .NONE}, 0x01C00010, 0x0FE00090, .BASE, .A32, {}},
		{.BIC, {.GPR, .GPR, .IMM_MOD, .NONE},     {.RD, .RN_A32, .A32_IMM_MOD,   .NONE}, 0x03D00000, 0x0FF00000, .BASE, .A32, {sets_flags=true}},
		{.BIC, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD, .RN_A32, .RM_A32,         .NONE}, 0x01D00000, 0x0FF00010, .BASE, .A32, {sets_flags=true}},
		{.BIC, {.GPR, .GPR, .GPR_RSR, .NONE},     {.RD, .RN_A32, .RM_A32,         .NONE}, 0x01D00010, 0x0FF00090, .BASE, .A32, {sets_flags=true}},
		// T16 Format 4 BIC: 010000 1110 Rm Rd
		{.BIC, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x00004380, 0x0000FFC0, .THUMB, .T32, {cond_in_28=false}},
		// T32 BIC imm/reg (op=0001)
		{.BIC, {.GPR, .GPR, .IMM_T32_MOD, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE}, 0xF0200000, 0xFBE08000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		{.BIC, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xEA200000, 0xFFE08000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},

	// MOV and MVN have Rn unused (encoded as 0). The MOV-immediate form
	// additionally has ARMv6T2 MOVW (low half, no shift) and MOVT (high half).
	.MOV = {
		{.MOV, {.GPR, .IMM_MOD, .NONE, .NONE},     {.RD, .A32_IMM_MOD, .NONE, .NONE}, 0x03A00000, 0x0FEF0000, .BASE, .A32, {}},
		{.MOV, {.GPR, .GPR_SHIFTED, .NONE, .NONE}, {.RD, .RM_A32,       .NONE, .NONE}, 0x01A00000, 0x0FEF0010, .BASE, .A32, {}},
		{.MOV, {.GPR, .GPR_RSR, .NONE, .NONE},     {.RD, .RM_A32,       .NONE, .NONE}, 0x01A00010, 0x0FEF0090, .BASE, .A32, {}},
		{.MOV, {.GPR, .IMM_MOD, .NONE, .NONE},     {.RD, .A32_IMM_MOD, .NONE, .NONE}, 0x03B00000, 0x0FFF0000, .BASE, .A32, {sets_flags=true}},
		{.MOV, {.GPR, .GPR_SHIFTED, .NONE, .NONE}, {.RD, .RM_A32,       .NONE, .NONE}, 0x01B00000, 0x0FFF0010, .BASE, .A32, {sets_flags=true}},
		{.MOV, {.GPR, .GPR_RSR, .NONE, .NONE},     {.RD, .RM_A32,       .NONE, .NONE}, 0x01B00010, 0x0FFF0090, .BASE, .A32, {sets_flags=true}},
		// T16 Format 3 MOV imm8: 00100 Rd imm8
		{.MOV, {.GPR_LOW, .IMM8, .NONE, .NONE}, {.RD_T16_HI, .NONE, .NONE, .NONE}, 0x00002000, 0x0000F800, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 5 hi-reg MOV: 010001 10 H1 H2 Rm Rd
		{.MOV, {.GPR, .GPR, .NONE, .NONE}, {.RD_T16_HI, .RM_T16_HI, .NONE, .NONE}, 0x00004600, 0x0000FF00, .THUMB, .T32, {cond_in_28=false}},
		// T32 MOV imm12-mod (encoding T2): high=11110 i 0 0010 S 1111  low=0 imm3 Rd imm8
		{.MOV, {.GPR, .IMM_T32_MOD, .NONE, .NONE}, {.RD_T32, .T32_IMM_MOD, .NONE, .NONE}, 0xF04F0000, 0xFBEF8000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		{.MOV, {.GPR, .IMM_T32_MOD, .NONE, .NONE}, {.RD_T32, .T32_IMM_MOD, .NONE, .NONE}, 0xF05F0000, 0xFBEF8000, .V6T2, .T32, {thumb32=true, cond_in_28=false, sets_flags=true}},
		// T32 MOV reg (encoding T3): high=11101 01 0010 S 1111  low=0 imm3 Rd imm2 00 Rm
		{.MOV, {.GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE}, 0xEA4F0000, 0xFFEF8000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		{.MOV, {.GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE}, 0xEA5F0000, 0xFFEF8000, .V6T2, .T32, {thumb32=true, cond_in_28=false, sets_flags=true}},
	},
	.MVN = {
		{.MVN, {.GPR, .IMM_MOD, .NONE, .NONE},     {.RD, .A32_IMM_MOD, .NONE, .NONE}, 0x03E00000, 0x0FEF0000, .BASE, .A32, {}},
		{.MVN, {.GPR, .GPR_SHIFTED, .NONE, .NONE}, {.RD, .RM_A32,       .NONE, .NONE}, 0x01E00000, 0x0FEF0010, .BASE, .A32, {}},
		{.MVN, {.GPR, .GPR_RSR, .NONE, .NONE},     {.RD, .RM_A32,       .NONE, .NONE}, 0x01E00010, 0x0FEF0090, .BASE, .A32, {}},
		{.MVN, {.GPR, .IMM_MOD, .NONE, .NONE},     {.RD, .A32_IMM_MOD, .NONE, .NONE}, 0x03F00000, 0x0FFF0000, .BASE, .A32, {sets_flags=true}},
		{.MVN, {.GPR, .GPR_SHIFTED, .NONE, .NONE}, {.RD, .RM_A32,       .NONE, .NONE}, 0x01F00000, 0x0FFF0010, .BASE, .A32, {sets_flags=true}},
		{.MVN, {.GPR, .GPR_RSR, .NONE, .NONE},     {.RD, .RM_A32,       .NONE, .NONE}, 0x01F00010, 0x0FFF0090, .BASE, .A32, {sets_flags=true}},
		// T16 Format 4 MVN: 010000 1111 Rm Rd
		{.MVN, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x000043C0, 0x0000FFC0, .THUMB, .T32, {cond_in_28=false}},
		// T32 MVN imm/reg (op=0011, Rn=15)
		{.MVN, {.GPR, .IMM_T32_MOD, .NONE, .NONE}, {.RD_T32, .T32_IMM_MOD, .NONE, .NONE}, 0xF06F0000, 0xFBEF8000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		{.MVN, {.GPR, .GPR_SHIFTED, .NONE, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE}, 0xEA6F0000, 0xFFEF8000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},

	// MOVW / MOVT (ARMv6T2): 16-bit imm split as imm4(19:16) + imm12(11:0)
	.MOVW = {
		{.MOVW, {.GPR, .IMM16_LO_HI, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0x03000000, 0x0FF00000, .V6T2, .A32, {}},
		// T32 MOVW: high=11110 i 1 0010 0 imm4  low=0 imm3 Rd imm8
		{.MOVW, {.GPR, .IMM16_LO_HI, .NONE, .NONE}, {.RD_T32, .NONE, .NONE, .NONE}, 0xF2400000, 0xFBF08000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.MOVT = {
		{.MOVT, {.GPR, .IMM16_LO_HI, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0x03400000, 0x0FF00000, .V6T2, .A32, {}},
		// T32 MOVT: high=11110 i 1 0110 0 imm4
		{.MOVT, {.GPR, .IMM16_LO_HI, .NONE, .NONE}, {.RD_T32, .NONE, .NONE, .NONE}, 0xF2C00000, 0xFBF08000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},

	// Comparison-only ops: S is implicit-1, Rd is unused (encoded as 0).
	.TST = {
		{.TST, {.GPR, .IMM_MOD, .NONE, .NONE},     {.RN_A32, .A32_IMM_MOD, .NONE, .NONE}, 0x03100000, 0x0FF0F000, .BASE, .A32, {}},
		{.TST, {.GPR, .GPR_SHIFTED, .NONE, .NONE}, {.RN_A32, .RM_A32,       .NONE, .NONE}, 0x01100000, 0x0FF0F010, .BASE, .A32, {}},
		{.TST, {.GPR, .GPR_RSR, .NONE, .NONE},     {.RN_A32, .RM_A32,       .NONE, .NONE}, 0x01100010, 0x0FF0F090, .BASE, .A32, {}},
		// T16 Format 4 TST: 010000 1000 Rm Rn
		{.TST, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RN_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x00004200, 0x0000FFC0, .THUMB, .T32, {cond_in_28=false}},
		// T32 TST imm/reg (op=0000, S=1, Rd=15)
		{.TST, {.GPR, .IMM_T32_MOD, .NONE, .NONE}, {.RN_T32, .T32_IMM_MOD, .NONE, .NONE}, 0xF0100F00, 0xFBF08F00, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		{.TST, {.GPR, .GPR_SHIFTED, .NONE, .NONE}, {.RN_T32, .RM_T32, .NONE, .NONE}, 0xEA100F00, 0xFFF08F00, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.TEQ = {
		{.TEQ, {.GPR, .IMM_MOD, .NONE, .NONE},     {.RN_A32, .A32_IMM_MOD, .NONE, .NONE}, 0x03300000, 0x0FF0F000, .BASE, .A32, {}},
		{.TEQ, {.GPR, .GPR_SHIFTED, .NONE, .NONE}, {.RN_A32, .RM_A32,       .NONE, .NONE}, 0x01300000, 0x0FF0F010, .BASE, .A32, {}},
		{.TEQ, {.GPR, .GPR_RSR, .NONE, .NONE},     {.RN_A32, .RM_A32,       .NONE, .NONE}, 0x01300010, 0x0FF0F090, .BASE, .A32, {}},
		// T32 TEQ imm/reg (op=0100, S=1, Rd=15)
		{.TEQ, {.GPR, .IMM_T32_MOD, .NONE, .NONE}, {.RN_T32, .T32_IMM_MOD, .NONE, .NONE}, 0xF0900F00, 0xFBF08F00, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		{.TEQ, {.GPR, .GPR_SHIFTED, .NONE, .NONE}, {.RN_T32, .RM_T32, .NONE, .NONE}, 0xEA900F00, 0xFFF08F00, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.CMP = {
		{.CMP, {.GPR, .IMM_MOD, .NONE, .NONE},     {.RN_A32, .A32_IMM_MOD, .NONE, .NONE}, 0x03500000, 0x0FF0F000, .BASE, .A32, {}},
		{.CMP, {.GPR, .GPR_SHIFTED, .NONE, .NONE}, {.RN_A32, .RM_A32,       .NONE, .NONE}, 0x01500000, 0x0FF0F010, .BASE, .A32, {}},
		{.CMP, {.GPR, .GPR_RSR, .NONE, .NONE},     {.RN_A32, .RM_A32,       .NONE, .NONE}, 0x01500010, 0x0FF0F090, .BASE, .A32, {}},
		// T16 Format 3 CMP imm8: 00101 Rn imm8
		{.CMP, {.GPR_LOW, .IMM8, .NONE, .NONE}, {.RD_T16_HI, .NONE, .NONE, .NONE}, 0x00002800, 0x0000F800, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 4 CMP reg: 010000 1010 Rm Rn
		{.CMP, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RN_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x00004280, 0x0000FFC0, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 5 hi-reg CMP: 010001 01 H1 H2 Rm Rn
		{.CMP, {.GPR, .GPR, .NONE, .NONE}, {.RD_T16_HI, .RM_T16_HI, .NONE, .NONE}, 0x00004500, 0x0000FF00, .THUMB, .T32, {cond_in_28=false}},
		// T32 CMP imm/reg (op=1101, S=1, Rd=15)
		{.CMP, {.GPR, .IMM_T32_MOD, .NONE, .NONE}, {.RN_T32, .T32_IMM_MOD, .NONE, .NONE}, 0xF1B00F00, 0xFBF08F00, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		{.CMP, {.GPR, .GPR_SHIFTED, .NONE, .NONE}, {.RN_T32, .RM_T32, .NONE, .NONE}, 0xEBB00F00, 0xFFF08F00, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.CMN = {
		{.CMN, {.GPR, .IMM_MOD, .NONE, .NONE},     {.RN_A32, .A32_IMM_MOD, .NONE, .NONE}, 0x03700000, 0x0FF0F000, .BASE, .A32, {}},
		{.CMN, {.GPR, .GPR_SHIFTED, .NONE, .NONE}, {.RN_A32, .RM_A32,       .NONE, .NONE}, 0x01700000, 0x0FF0F010, .BASE, .A32, {}},
		{.CMN, {.GPR, .GPR_RSR, .NONE, .NONE},     {.RN_A32, .RM_A32,       .NONE, .NONE}, 0x01700010, 0x0FF0F090, .BASE, .A32, {}},
		// T16 Format 4 CMN: 010000 1011 Rm Rn
		{.CMN, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RN_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x000042C0, 0x0000FFC0, .THUMB, .T32, {cond_in_28=false}},
		// T32 CMN imm/reg (op=1000, S=1, Rd=15)
		{.CMN, {.GPR, .IMM_T32_MOD, .NONE, .NONE}, {.RN_T32, .T32_IMM_MOD, .NONE, .NONE}, 0xF1100F00, 0xFBF08F00, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		{.CMN, {.GPR, .GPR_SHIFTED, .NONE, .NONE}, {.RN_T32, .RM_T32, .NONE, .NONE}, 0xEB100F00, 0xFFF08F00, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
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
		{.MUL, {.GPR, .GPR, .GPR, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE}, 0x00000090, 0x0FE000F0, .BASE, .A32, {}},
		{.MUL, {.GPR, .GPR, .GPR, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE}, 0x00100090, 0x0FF000F0, .BASE, .A32, {sets_flags=true}},
		// T16 Format 4 MUL: 010000 1101 Rm Rd
		{.MUL, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x00004340, 0x0000FFC0, .THUMB, .T32, {cond_in_28=false}},
		// T32 MUL: high=11111011 0000 Rn  low=1111 Rd 0000 Rm
		{.MUL, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFB00F000, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.MLA = {
		{.MLA, {.GPR, .GPR, .GPR, .GPR}, {.RN_A32, .RM_A32, .RS_A32, .RD}, 0x00200090, 0x0FE000F0, .BASE, .A32, {}},
		{.MLA, {.GPR, .GPR, .GPR, .GPR}, {.RN_A32, .RM_A32, .RS_A32, .RD}, 0x00300090, 0x0FF000F0, .BASE, .A32, {sets_flags=true}},
		// T32 MLA: high=11111011 0000 Rn  low=Ra Rd 0000 Rm
		{.MLA, {.GPR, .GPR, .GPR, .GPR}, {.RD_T32, .RN_T32, .RM_T32, .RA_T32}, 0xFB000000, 0xFFF000F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.MLS = {
		{.MLS, {.GPR, .GPR, .GPR, .GPR}, {.RN_A32, .RM_A32, .RS_A32, .RD}, 0x00600090, 0x0FF000F0, .V6T2, .A32, {}},
		// T32 MLS: high=11111011 0000 Rn  low=Ra Rd 0001 Rm
		{.MLS, {.GPR, .GPR, .GPR, .GPR}, {.RD_T32, .RN_T32, .RM_T32, .RA_T32}, 0xFB000010, 0xFFF000F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.UMULL = {
		{.UMULL, {.GPR, .GPR, .GPR, .GPR}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32}, 0x00800090, 0x0FE000F0, .BASE, .A32, {}},
		{.UMULL, {.GPR, .GPR, .GPR, .GPR}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32}, 0x00900090, 0x0FF000F0, .BASE, .A32, {sets_flags=true}},
		// T32 UMULL: high=11111011 1010 Rn  low=RdLo RdHi 0000 Rm
		{.UMULL, {.GPR, .GPR, .GPR, .GPR}, {.RT_T32, .RD_T32, .RN_T32, .RM_T32}, 0xFBA00000, 0xFFF000F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.UMLAL = {
		{.UMLAL, {.GPR, .GPR, .GPR, .GPR}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32}, 0x00A00090, 0x0FE000F0, .BASE, .A32, {}},
		{.UMLAL, {.GPR, .GPR, .GPR, .GPR}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32}, 0x00B00090, 0x0FF000F0, .BASE, .A32, {sets_flags=true}},
		// T32 UMLAL: high=11111011 1110 Rn  low=RdLo RdHi 0000 Rm
		{.UMLAL, {.GPR, .GPR, .GPR, .GPR}, {.RT_T32, .RD_T32, .RN_T32, .RM_T32}, 0xFBE00000, 0xFFF000F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SMULL = {
		{.SMULL, {.GPR, .GPR, .GPR, .GPR}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32}, 0x00C00090, 0x0FE000F0, .BASE, .A32, {}},
		{.SMULL, {.GPR, .GPR, .GPR, .GPR}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32}, 0x00D00090, 0x0FF000F0, .BASE, .A32, {sets_flags=true}},
		// T32 SMULL: high=11111011 1000 Rn  low=RdLo RdHi 0000 Rm
		{.SMULL, {.GPR, .GPR, .GPR, .GPR}, {.RT_T32, .RD_T32, .RN_T32, .RM_T32}, 0xFB800000, 0xFFF000F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SMLAL = {
		{.SMLAL, {.GPR, .GPR, .GPR, .GPR}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32}, 0x00E00090, 0x0FE000F0, .BASE, .A32, {}},
		{.SMLAL, {.GPR, .GPR, .GPR, .GPR}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32}, 0x00F00090, 0x0FF000F0, .BASE, .A32, {sets_flags=true}},
		// T32 SMLAL: high=11111011 1100 Rn  low=RdLo RdHi 0000 Rm
		{.SMLAL, {.GPR, .GPR, .GPR, .GPR}, {.RT_T32, .RD_T32, .RN_T32, .RM_T32}, 0xFBC00000, 0xFFF000F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	// (MLA/MLS/UMULL/UMLAL/SMULL/SMLAL declared earlier in MUL block region.)
	.UMAAL = {
		{.UMAAL, {.GPR, .GPR, .GPR, .GPR}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32}, 0x00400090, 0x0FF000F0, .V6, .A32, {}},
	},

	// ARMv5TE halfword multiply (SMLAxy / SMULxy / SMLAWy / SMULWy / SMLALxy)
	// Encoding: cond 00010 op0 op1 Rd Rn Rs 1 y x 0 Rm
	//   op0/op1 distinguishes family. x/y selects top/bottom halfword of Rm/Rs.
	.SMLABB = { {.SMLABB, {.GPR, .GPR, .GPR, .GPR}, {.RN_A32, .RM_A32, .RS_A32, .RD}, 0x01000080, 0x0FF000F0, .V5TE, .A32, {}} },
	.SMLABT = { {.SMLABT, {.GPR, .GPR, .GPR, .GPR}, {.RN_A32, .RM_A32, .RS_A32, .RD}, 0x010000C0, 0x0FF000F0, .V5TE, .A32, {}} },
	.SMLATB = { {.SMLATB, {.GPR, .GPR, .GPR, .GPR}, {.RN_A32, .RM_A32, .RS_A32, .RD}, 0x010000A0, 0x0FF000F0, .V5TE, .A32, {}} },
	.SMLATT = { {.SMLATT, {.GPR, .GPR, .GPR, .GPR}, {.RN_A32, .RM_A32, .RS_A32, .RD}, 0x010000E0, 0x0FF000F0, .V5TE, .A32, {}} },
	.SMLAWB = { {.SMLAWB, {.GPR, .GPR, .GPR, .GPR}, {.RN_A32, .RM_A32, .RS_A32, .RD}, 0x01200080, 0x0FF000F0, .V5TE, .A32, {}} },
	.SMLAWT = { {.SMLAWT, {.GPR, .GPR, .GPR, .GPR}, {.RN_A32, .RM_A32, .RS_A32, .RD}, 0x012000C0, 0x0FF000F0, .V5TE, .A32, {}} },
	.SMULBB = { {.SMULBB, {.GPR, .GPR, .GPR, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE}, 0x01600080, 0x0FF0F0F0, .V5TE, .A32, {}} },
	.SMULBT = { {.SMULBT, {.GPR, .GPR, .GPR, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE}, 0x016000C0, 0x0FF0F0F0, .V5TE, .A32, {}} },
	.SMULTB = { {.SMULTB, {.GPR, .GPR, .GPR, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE}, 0x016000A0, 0x0FF0F0F0, .V5TE, .A32, {}} },
	.SMULTT = { {.SMULTT, {.GPR, .GPR, .GPR, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE}, 0x016000E0, 0x0FF0F0F0, .V5TE, .A32, {}} },
	.SMULWB = { {.SMULWB, {.GPR, .GPR, .GPR, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE}, 0x012000A0, 0x0FF0F0F0, .V5TE, .A32, {}} },
	.SMULWT = { {.SMULWT, {.GPR, .GPR, .GPR, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE}, 0x012000E0, 0x0FF0F0F0, .V5TE, .A32, {}} },
	.SMLALBB = { {.SMLALBB, {.GPR, .GPR, .GPR, .GPR}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32}, 0x01400080, 0x0FF000F0, .V5TE, .A32, {}} },
	.SMLALBT = { {.SMLALBT, {.GPR, .GPR, .GPR, .GPR}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32}, 0x014000C0, 0x0FF000F0, .V5TE, .A32, {}} },
	.SMLALTB = { {.SMLALTB, {.GPR, .GPR, .GPR, .GPR}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32}, 0x014000A0, 0x0FF000F0, .V5TE, .A32, {}} },
	.SMLALTT = { {.SMLALTT, {.GPR, .GPR, .GPR, .GPR}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32}, 0x014000E0, 0x0FF000F0, .V5TE, .A32, {}} },

	// ARMv6: dual multiply
	.SMUAD   = { {.SMUAD,   {.GPR, .GPR, .GPR, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE}, 0x0700F010, 0x0FF0F0F0, .V6, .A32, {}} },
	.SMUADX  = { {.SMUADX,  {.GPR, .GPR, .GPR, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE}, 0x0700F030, 0x0FF0F0F0, .V6, .A32, {}} },
	.SMUSD   = { {.SMUSD,   {.GPR, .GPR, .GPR, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE}, 0x0700F050, 0x0FF0F0F0, .V6, .A32, {}} },
	.SMUSDX  = { {.SMUSDX,  {.GPR, .GPR, .GPR, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE}, 0x0700F070, 0x0FF0F0F0, .V6, .A32, {}} },
	.SMLAD   = { {.SMLAD,   {.GPR, .GPR, .GPR, .GPR}, {.RN_A32, .RM_A32, .RS_A32, .RD}, 0x07000010, 0x0FF000F0, .V6, .A32, {}} },
	.SMLADX  = { {.SMLADX,  {.GPR, .GPR, .GPR, .GPR}, {.RN_A32, .RM_A32, .RS_A32, .RD}, 0x07000030, 0x0FF000F0, .V6, .A32, {}} },
	.SMLSD   = { {.SMLSD,   {.GPR, .GPR, .GPR, .GPR}, {.RN_A32, .RM_A32, .RS_A32, .RD}, 0x07000050, 0x0FF000F0, .V6, .A32, {}} },
	.SMLSDX  = { {.SMLSDX,  {.GPR, .GPR, .GPR, .GPR}, {.RN_A32, .RM_A32, .RS_A32, .RD}, 0x07000070, 0x0FF000F0, .V6, .A32, {}} },
	.SMLALD  = { {.SMLALD,  {.GPR, .GPR, .GPR, .GPR}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32}, 0x07400010, 0x0FF000F0, .V6, .A32, {}} },
	.SMLALDX = { {.SMLALDX, {.GPR, .GPR, .GPR, .GPR}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32}, 0x07400030, 0x0FF000F0, .V6, .A32, {}} },
	.SMLSLD  = { {.SMLSLD,  {.GPR, .GPR, .GPR, .GPR}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32}, 0x07400050, 0x0FF000F0, .V6, .A32, {}} },
	.SMLSLDX = { {.SMLSLDX, {.GPR, .GPR, .GPR, .GPR}, {.RDLO_A32, .RDHI_A32, .RM_A32, .RS_A32}, 0x07400070, 0x0FF000F0, .V6, .A32, {}} },

	// Most-significant-word multiply (ARMv6)
	.SMMUL  = { {.SMMUL,  {.GPR, .GPR, .GPR, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE}, 0x0750F010, 0x0FF0F0F0, .V6, .A32, {}} },
	.SMMULR = { {.SMMULR, {.GPR, .GPR, .GPR, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE}, 0x0750F030, 0x0FF0F0F0, .V6, .A32, {}} },
	.SMMLA  = { {.SMMLA,  {.GPR, .GPR, .GPR, .GPR}, {.RN_A32, .RM_A32, .RS_A32, .RD}, 0x07500010, 0x0FF000F0, .V6, .A32, {}} },
	.SMMLAR = { {.SMMLAR, {.GPR, .GPR, .GPR, .GPR}, {.RN_A32, .RM_A32, .RS_A32, .RD}, 0x07500030, 0x0FF000F0, .V6, .A32, {}} },
	.SMMLS  = { {.SMMLS,  {.GPR, .GPR, .GPR, .GPR}, {.RN_A32, .RM_A32, .RS_A32, .RD}, 0x075000D0, 0x0FF000F0, .V6, .A32, {}} },
	.SMMLSR = { {.SMMLSR, {.GPR, .GPR, .GPR, .GPR}, {.RN_A32, .RM_A32, .RS_A32, .RD}, 0x075000F0, 0x0FF000F0, .V6, .A32, {}} },

	// ARMv7-A optional / ARMv7-R/M: integer division
	.SDIV = {
		{.SDIV, {.GPR, .GPR, .GPR, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE}, 0x0710F010, 0x0FF0F0F0, .DIV, .A32, {}},
		// T32 SDIV: high=11111011 1001 Rn  low=1111 Rd 1111 Rm
		{.SDIV, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFB90F0F0, 0xFFF0F0F0, .DIV, .T32, {thumb32=true, cond_in_28=false}},
	},
	.UDIV = {
		{.UDIV, {.GPR, .GPR, .GPR, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE}, 0x0730F010, 0x0FF0F0F0, .DIV, .A32, {}},
		// T32 UDIV: high=11111011 1011 Rn  low=1111 Rd 1111 Rm
		{.UDIV, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFBB0F0F0, 0xFFF0F0F0, .DIV, .T32, {thumb32=true, cond_in_28=false}},
	},

	// =========================================================================
	// §3 -- Saturating arithmetic + ARMv6 SIMD-on-GPR
	// =========================================================================

	// ARMv5TE saturating arithmetic
	.QADD = {
		{.QADD, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RM_A32, .RN_A32, .NONE}, 0x01000050, 0x0FF000F0, .V5TE, .A32, {}},
		// T32 QADD: high=11111010 1000 Rn  low=1111 Rd 1000 Rm
		{.QADD, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RM_T32, .RN_T32, .NONE}, 0xFA80F080, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.QSUB = {
		{.QSUB, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RM_A32, .RN_A32, .NONE}, 0x01200050, 0x0FF000F0, .V5TE, .A32, {}},
		// T32 QSUB: bits 5:4 = 10
		{.QSUB, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RM_T32, .RN_T32, .NONE}, 0xFA80F0A0, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.QDADD = {
		{.QDADD, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RM_A32, .RN_A32, .NONE}, 0x01400050, 0x0FF000F0, .V5TE, .A32, {}},
		// T32 QDADD: bits 5:4 = 01
		{.QDADD, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RM_T32, .RN_T32, .NONE}, 0xFA80F090, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.QDSUB = {
		{.QDSUB, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RM_A32, .RN_A32, .NONE}, 0x01600050, 0x0FF000F0, .V5TE, .A32, {}},
		// T32 QDSUB: bits 5:4 = 11
		{.QDSUB, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RM_T32, .RN_T32, .NONE}, 0xFA80F0B0, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},

	// ARMv6 signed parallel arithmetic (8-bit and 16-bit lanes)
	//   cond 0110 0001 Rn Rd 1111 op Rm    -- op selects ADD/SUB/SUB16/etc.
	//   The "op" field at bits 7:4 distinguishes:
	//     0001 ADD16  0011 ASX    0101 SAX    0111 SUB16
	//     1001 ADD8   1111 SUB8
	.SADD16 = {
		{.SADD16, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06100F10, 0x0FF00FF0, .V6, .A32, {}},
		// T32 SADD16: high=11111010 1001 Rn  low=1111 Rd 0000 Rm
		{.SADD16, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFA90F000, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SASX = {
		{.SASX, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06100F30, 0x0FF00FF0, .V6, .A32, {}},
		// T32 SASX: 0xFAA0F000
		{.SASX, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAA0F000, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SSAX = {
		{.SSAX, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06100F50, 0x0FF00FF0, .V6, .A32, {}},
		// T32 SSAX: 0xFAE0F000
		{.SSAX, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAE0F000, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SSUB16 = {
		{.SSUB16, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06100F70, 0x0FF00FF0, .V6, .A32, {}},
		// T32 SSUB16: 0xFAD0F000
		{.SSUB16, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAD0F000, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SADD8 = {
		{.SADD8, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06100F90, 0x0FF00FF0, .V6, .A32, {}},
		// T32 SADD8: 0xFA80F000
		{.SADD8, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFA80F000, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SSUB8 = {
		{.SSUB8, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06100FF0, 0x0FF00FF0, .V6, .A32, {}},
		// T32 SSUB8: 0xFAC0F000
		{.SSUB8, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAC0F000, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},

	// ARMv6 saturating parallel arithmetic (op family 0110 0010)
	// Q* (signed saturating): T32 bits 6:4 = 001
	.QADD16 = {
		{.QADD16, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06200F10, 0x0FF00FF0, .V6, .A32, {}},
		{.QADD16, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFA90F010, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.QASX = {
		{.QASX, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06200F30, 0x0FF00FF0, .V6, .A32, {}},
		{.QASX, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAA0F010, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.QSAX = {
		{.QSAX, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06200F50, 0x0FF00FF0, .V6, .A32, {}},
		{.QSAX, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAE0F010, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.QSUB16 = {
		{.QSUB16, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06200F70, 0x0FF00FF0, .V6, .A32, {}},
		{.QSUB16, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAD0F010, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.QADD8 = {
		{.QADD8, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06200F90, 0x0FF00FF0, .V6, .A32, {}},
		{.QADD8, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFA80F010, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.QSUB8 = {
		{.QSUB8, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06200FF0, 0x0FF00FF0, .V6, .A32, {}},
		{.QSUB8, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAC0F010, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},

	// ARMv6 signed halving (T32 bits 6:4 = 010)
	.SHADD16 = {
		{.SHADD16, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06300F10, 0x0FF00FF0, .V6, .A32, {}},
		{.SHADD16, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFA90F020, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SHASX = {
		{.SHASX, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06300F30, 0x0FF00FF0, .V6, .A32, {}},
		{.SHASX, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAA0F020, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SHSAX = {
		{.SHSAX, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06300F50, 0x0FF00FF0, .V6, .A32, {}},
		{.SHSAX, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAE0F020, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SHSUB16 = {
		{.SHSUB16, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06300F70, 0x0FF00FF0, .V6, .A32, {}},
		{.SHSUB16, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAD0F020, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SHADD8 = {
		{.SHADD8, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06300F90, 0x0FF00FF0, .V6, .A32, {}},
		{.SHADD8, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFA80F020, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SHSUB8 = {
		{.SHSUB8, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06300FF0, 0x0FF00FF0, .V6, .A32, {}},
		{.SHSUB8, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAC0F020, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},

	// ARMv6 unsigned parallel arithmetic (op family 0110 0101)
	.UADD16 = {
		{.UADD16, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06500F10, 0x0FF00FF0, .V6, .A32, {}},
		// T32 UADD16: high=11111010 1001 Rn  low=1111 Rd 0100 Rm
		{.UADD16, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFA90F040, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.UASX = {
		{.UASX, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06500F30, 0x0FF00FF0, .V6, .A32, {}},
		{.UASX, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAA0F040, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.USAX = {
		{.USAX, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06500F50, 0x0FF00FF0, .V6, .A32, {}},
		{.USAX, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAE0F040, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.USUB16 = {
		{.USUB16, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06500F70, 0x0FF00FF0, .V6, .A32, {}},
		{.USUB16, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAD0F040, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.UADD8 = {
		{.UADD8, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06500F90, 0x0FF00FF0, .V6, .A32, {}},
		{.UADD8, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFA80F040, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.USUB8 = {
		{.USUB8, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06500FF0, 0x0FF00FF0, .V6, .A32, {}},
		{.USUB8, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAC0F040, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},

	// ARMv6 unsigned saturating (T32 bits 6:4 = 101)
	.UQADD16 = {
		{.UQADD16, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06600F10, 0x0FF00FF0, .V6, .A32, {}},
		{.UQADD16, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFA90F050, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.UQASX = {
		{.UQASX, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06600F30, 0x0FF00FF0, .V6, .A32, {}},
		{.UQASX, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAA0F050, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.UQSAX = {
		{.UQSAX, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06600F50, 0x0FF00FF0, .V6, .A32, {}},
		{.UQSAX, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAE0F050, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.UQSUB16 = {
		{.UQSUB16, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06600F70, 0x0FF00FF0, .V6, .A32, {}},
		{.UQSUB16, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAD0F050, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.UQADD8 = {
		{.UQADD8, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06600F90, 0x0FF00FF0, .V6, .A32, {}},
		{.UQADD8, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFA80F050, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.UQSUB8 = {
		{.UQSUB8, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06600FF0, 0x0FF00FF0, .V6, .A32, {}},
		{.UQSUB8, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAC0F050, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},

	// ARMv6 unsigned halving (T32 bits 6:4 = 110)
	.UHADD16 = {
		{.UHADD16, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06700F10, 0x0FF00FF0, .V6, .A32, {}},
		{.UHADD16, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFA90F060, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.UHASX = {
		{.UHASX, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06700F30, 0x0FF00FF0, .V6, .A32, {}},
		{.UHASX, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAA0F060, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.UHSAX = {
		{.UHSAX, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06700F50, 0x0FF00FF0, .V6, .A32, {}},
		{.UHSAX, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAE0F060, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.UHSUB16 = {
		{.UHSUB16, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06700F70, 0x0FF00FF0, .V6, .A32, {}},
		{.UHSUB16, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAD0F060, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.UHADD8 = {
		{.UHADD8, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06700F90, 0x0FF00FF0, .V6, .A32, {}},
		{.UHADD8, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFA80F060, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.UHSUB8 = {
		{.UHSUB8, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06700FF0, 0x0FF00FF0, .V6, .A32, {}},
		{.UHSUB8, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFAC0F060, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},

	// ARMv6 saturate to width
	.SSAT = {
		{.SSAT, {.GPR, .IMM4_SAT, .GPR_SHIFTED, .NONE}, {.RD, .SAT_IMM5, .RM_A32, .NONE}, 0x06A00010, 0x0FE00030, .V6, .A32, {}},
		// T32 SSAT: high=11110 0 1 1000 0 Rn  low=0 imm3 Rd imm2 0 sat_imm
		{.SSAT, {.GPR, .IMM4_SAT, .GPR_SHIFTED, .NONE}, {.RD_T32, .SAT_IMM5_T32, .RN_T32, .NONE}, 0xF3000000, 0xFFD08020, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.USAT = {
		{.USAT, {.GPR, .IMM4_SAT, .GPR_SHIFTED, .NONE}, {.RD, .SAT_IMM5, .RM_A32, .NONE}, 0x06E00010, 0x0FE00030, .V6, .A32, {}},
		{.USAT, {.GPR, .IMM4_SAT, .GPR_SHIFTED, .NONE}, {.RD_T32, .SAT_IMM5_T32, .RN_T32, .NONE}, 0xF3800000, 0xFFD08020, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SSAT16 = {
		{.SSAT16, {.GPR, .IMM4_SAT, .GPR, .NONE}, {.RD, .SAT_IMM5, .RM_A32, .NONE}, 0x06A00F30, 0x0FF00FF0, .V6, .A32, {}},
		// T32 SSAT16: high=11110 0 1 1001 0 Rn  low=0 000 Rd 0000 sat_imm
		{.SSAT16, {.GPR, .IMM4_SAT, .GPR, .NONE}, {.RD_T32, .SAT_IMM5_T32, .RN_T32, .NONE}, 0xF3200000, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.USAT16 = {
		{.USAT16, {.GPR, .IMM4_SAT, .GPR, .NONE}, {.RD, .SAT_IMM5, .RM_A32, .NONE}, 0x06E00F30, 0x0FF00FF0, .V6, .A32, {}},
		{.USAT16, {.GPR, .IMM4_SAT, .GPR, .NONE}, {.RD_T32, .SAT_IMM5_T32, .RN_T32, .NONE}, 0xF3A00000, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},

	// ARMv6 USAD8 / USADA8
	.USAD8  = { {.USAD8,  {.GPR, .GPR, .GPR, .NONE}, {.RN_A32, .RM_A32, .RS_A32, .NONE}, 0x0780F010, 0x0FF0F0F0, .V6, .A32, {}} },
	.USADA8 = { {.USADA8, {.GPR, .GPR, .GPR, .GPR}, {.RN_A32, .RM_A32, .RS_A32, .RD},    0x07800010, 0x0FF000F0, .V6, .A32, {}} },

	// =========================================================================
	// §4 -- Extends + bit-field + REV + CLZ + RBIT + SEL + PKHBT/TB
	// =========================================================================

	// PKHBT / PKHTB (pack halfword)
	//   PKHBT: cond 0110 1000 Rn Rd shift_imm 001 Rm
	//   PKHTB: cond 0110 1000 Rn Rd shift_imm 101 Rm
	.PKHBT = { {.PKHBT, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06800010, 0x0FF00070, .V6, .A32, {}} },
	.PKHTB = { {.PKHTB, {.GPR, .GPR, .GPR_SHIFTED, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06800050, 0x0FF00070, .V6, .A32, {}} },

	// Sign-extend / zero-extend (with optional rotation of Rm by 0/8/16/24)
	// Encoding: cond 0110 1xx0 1111 Rd rotate 0 0 0111 Rm   -- variant 1 (no Rn)
	//           cond 0110 1xx0 Rn   Rd rotate 0 0 0111 Rm   -- variant 2 (with Rn = SXTAB/etc.)
	.SXTB = {
		{.SXTB, {.GPR, .GPR, .NONE, .NONE}, {.RD, .RM_A32, .NONE, .NONE}, 0x06AF0070, 0x0FFF0070, .V6, .A32, {}},
		// T16 SXTB: 1011 0010 01 Rm Rd
		{.SXTB, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x0000B240, 0x0000FFC0, .V6, .T32, {cond_in_28=false}},
		// T32 SXTB (with rotate): high=11111010 0100 1111  low=1111 Rd 1 0 rot Rm
		{.SXTB, {.GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE}, 0xFA4FF080, 0xFFFFF0C0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SXTB16 = {
		{.SXTB16, {.GPR, .GPR, .NONE, .NONE}, {.RD, .RM_A32, .NONE, .NONE}, 0x068F0070, 0x0FFF0070, .V6, .A32, {}},
		// T32 SXTB16
		{.SXTB16, {.GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE}, 0xFA2FF080, 0xFFFFF0C0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SXTH = {
		{.SXTH, {.GPR, .GPR, .NONE, .NONE}, {.RD, .RM_A32, .NONE, .NONE}, 0x06BF0070, 0x0FFF0070, .V6, .A32, {}},
		// T16 SXTH: 1011 0010 00 Rm Rd
		{.SXTH, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x0000B200, 0x0000FFC0, .V6, .T32, {cond_in_28=false}},
		// T32 SXTH: 0xFA0FF080
		{.SXTH, {.GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE}, 0xFA0FF080, 0xFFFFF0C0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.UXTB = {
		{.UXTB, {.GPR, .GPR, .NONE, .NONE}, {.RD, .RM_A32, .NONE, .NONE}, 0x06EF0070, 0x0FFF0070, .V6, .A32, {}},
		// T16 UXTB: 1011 0010 11 Rm Rd
		{.UXTB, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x0000B2C0, 0x0000FFC0, .V6, .T32, {cond_in_28=false}},
		// T32 UXTB: 0xFA5FF080
		{.UXTB, {.GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE}, 0xFA5FF080, 0xFFFFF0C0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.UXTB16 = {
		{.UXTB16, {.GPR, .GPR, .NONE, .NONE}, {.RD, .RM_A32, .NONE, .NONE}, 0x06CF0070, 0x0FFF0070, .V6, .A32, {}},
		// T32 UXTB16
		{.UXTB16, {.GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE}, 0xFA3FF080, 0xFFFFF0C0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.UXTH = {
		{.UXTH, {.GPR, .GPR, .NONE, .NONE}, {.RD, .RM_A32, .NONE, .NONE}, 0x06FF0070, 0x0FFF0070, .V6, .A32, {}},
		// T16 UXTH: 1011 0010 10 Rm Rd
		{.UXTH, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x0000B280, 0x0000FFC0, .V6, .T32, {cond_in_28=false}},
		// T32 UXTH: 0xFA1FF080
		{.UXTH, {.GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE}, 0xFA1FF080, 0xFFFFF0C0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SXTAB = {
		{.SXTAB, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06A00070, 0x0FF00070, .V6, .A32, {}},
		// T32 SXTAB: high=11111010 0100 Rn  low=1111 Rd 1 0 rot Rm
		{.SXTAB, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFA40F080, 0xFFF0F0C0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SXTAB16 = {
		{.SXTAB16, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06800070, 0x0FF00070, .V6, .A32, {}},
		{.SXTAB16, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFA20F080, 0xFFF0F0C0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SXTAH = {
		{.SXTAH, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06B00070, 0x0FF00070, .V6, .A32, {}},
		{.SXTAH, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFA00F080, 0xFFF0F0C0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.UXTAB = {
		{.UXTAB, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06E00070, 0x0FF00070, .V6, .A32, {}},
		{.UXTAB, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFA50F080, 0xFFF0F0C0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.UXTAB16 = {
		{.UXTAB16, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06C00070, 0x0FF00070, .V6, .A32, {}},
		{.UXTAB16, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFA30F080, 0xFFF0F0C0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.UXTAH = {
		{.UXTAH, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06F00070, 0x0FF00070, .V6, .A32, {}},
		{.UXTAH, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFA10F080, 0xFFF0F0C0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},

	// Byte-reverse / count leading zeros / select / reverse bits
	.REV = {
		{.REV, {.GPR, .GPR, .NONE, .NONE}, {.RD, .RM_A32, .NONE, .NONE}, 0x06BF0F30, 0x0FFF0FF0, .V6, .A32, {}},
		// T16 REV: 1011 1010 00 Rm Rd
		{.REV, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x0000BA00, 0x0000FFC0, .V6, .T32, {cond_in_28=false}},
		// T32 REV: high=11111010 1001 Rm  low=1111 Rd 1000 Rm
		{.REV, {.GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE}, 0xFA90F080, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.REV16 = {
		{.REV16, {.GPR, .GPR, .NONE, .NONE}, {.RD, .RM_A32, .NONE, .NONE}, 0x06BF0FB0, 0x0FFF0FF0, .V6, .A32, {}},
		// T16 REV16: 1011 1010 01 Rm Rd
		{.REV16, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x0000BA40, 0x0000FFC0, .V6, .T32, {cond_in_28=false}},
		// T32 REV16: bits 5:4 = 01
		{.REV16, {.GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE}, 0xFA90F090, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.REVSH = {
		{.REVSH, {.GPR, .GPR, .NONE, .NONE}, {.RD, .RM_A32, .NONE, .NONE}, 0x06FF0FB0, 0x0FFF0FF0, .V6, .A32, {}},
		// T16 REVSH: 1011 1010 11 Rm Rd
		{.REVSH, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x0000BAC0, 0x0000FFC0, .V6, .T32, {cond_in_28=false}},
		// T32 REVSH: bits 5:4 = 11
		{.REVSH, {.GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE}, 0xFA90F0B0, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.RBIT = {
		{.RBIT, {.GPR, .GPR, .NONE, .NONE}, {.RD, .RM_A32, .NONE, .NONE}, 0x06FF0F30, 0x0FFF0FF0, .V6T2, .A32, {}},
		// T32 RBIT: bits 5:4 = 10
		{.RBIT, {.GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE}, 0xFA90F0A0, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.CLZ = {
		{.CLZ, {.GPR, .GPR, .NONE, .NONE}, {.RD, .RM_A32, .NONE, .NONE}, 0x016F0F10, 0x0FFF0FF0, .V5T, .A32, {}},
		// T32 CLZ: high=11111010 1011 Rm  low=1111 Rd 1000 Rm
		{.CLZ, {.GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE}, 0xFAB0F080, 0xFFF0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SEL   = { {.SEL,   {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x06800FB0, 0x0FF00FF0, .V6, .A32, {}} },

	// Bit field operations (ARMv6T2)
	.BFC = {
		{.BFC, {.GPR, .IMM5, .IMM5_W, .NONE}, {.RD, .BFI_LSB, .BFI_MSB, .NONE}, 0x07C0001F, 0x0FE0007F, .V6T2, .A32, {}},
		// T32 BFC: high=11110 0 1 1011 0 1111  low=0 imm3 Rd imm2 0 msb
		{.BFC, {.GPR, .IMM5, .IMM5_W, .NONE}, {.RD_T32, .BFI_LSB_T32, .BFI_MSB, .NONE}, 0xF36F0000, 0xFFFF8000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.BFI = {
		{.BFI, {.GPR, .GPR, .IMM5, .IMM5_W}, {.RD, .RM_A32, .BFI_LSB, .BFI_MSB}, 0x07C00010, 0x0FE00070, .V6T2, .A32, {}},
		// T32 BFI: high=11110 0 1 1011 0 Rn  low=0 imm3 Rd imm2 0 msb
		{.BFI, {.GPR, .GPR, .IMM5, .IMM5_W}, {.RD_T32, .RN_T32, .BFI_LSB_T32, .BFI_MSB}, 0xF3600000, 0xFFF08000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SBFX = {
		{.SBFX, {.GPR, .GPR, .IMM5, .IMM5_W}, {.RD, .RM_A32, .BFI_LSB, .BFI_MSB}, 0x07A00050, 0x0FE00070, .V6T2, .A32, {}},
		// T32 SBFX
		{.SBFX, {.GPR, .GPR, .IMM5, .IMM5_W}, {.RD_T32, .RN_T32, .BFI_LSB_T32, .BFI_MSB}, 0xF3400000, 0xFFF08000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.UBFX = {
		{.UBFX, {.GPR, .GPR, .IMM5, .IMM5_W}, {.RD, .RM_A32, .BFI_LSB, .BFI_MSB}, 0x07E00050, 0x0FE00070, .V6T2, .A32, {}},
		// T32 UBFX
		{.UBFX, {.GPR, .GPR, .IMM5, .IMM5_W}, {.RD_T32, .RN_T32, .BFI_LSB_T32, .BFI_MSB}, 0xF3C00000, 0xFFF08000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},

	// =========================================================================
	// §5 -- Branches, status reg access, exception generation
	// =========================================================================

	// B / BL: cond 101 L imm24
	.B = {
		{.B, {.REL24, .NONE, .NONE, .NONE}, {.BRANCH_24, .NONE, .NONE, .NONE}, 0x0A000000, 0x0F000000, .BASE, .A32, {branch=true, cond_branch=true, writes_pc=true}},
		// T16 Format 16 B<cond>: 1101 cond imm8
		{.B, {.REL8, .COND, .NONE, .NONE}, {.BRANCH_8_T16, .NONE, .NONE, .NONE}, 0x0000D000, 0x0000F000, .THUMB, .T32, {branch=true, cond_branch=true, writes_pc=true, cond_in_28=false}},
		// T16 Format 18 B unconditional: 11100 imm11
		{.B, {.REL11, .NONE, .NONE, .NONE}, {.BRANCH_11_T16, .NONE, .NONE, .NONE}, 0x0000E000, 0x0000F800, .THUMB, .T32, {branch=true, writes_pc=true, cond_in_28=false}},
		// T32 B<cond>: high=11110 S cond imm6  low=10 J1 0 J2 imm11
		{.B, {.REL20, .COND, .NONE, .NONE}, {.BRANCH_20_T32, .NONE, .NONE, .NONE}, 0xF0008000, 0xF800D000, .V6T2, .T32, {branch=true, cond_branch=true, writes_pc=true, thumb32=true, cond_in_28=false}},
		// T32 B unconditional: high=11110 S imm10  low=10 J1 1 J2 imm11
		{.B, {.REL24_T32, .NONE, .NONE, .NONE}, {.BRANCH_24_T32, .NONE, .NONE, .NONE}, 0xF0009000, 0xF800D000, .V6T2, .T32, {branch=true, writes_pc=true, thumb32=true, cond_in_28=false}},
	},
	.BL = {
		{.BL, {.REL24, .NONE, .NONE, .NONE}, {.BRANCH_24, .NONE, .NONE, .NONE}, 0x0B000000, 0x0F000000, .BASE, .A32, {branch=true, cond_branch=true, writes_pc=true}},
		// Thumb-1 / Thumb-2 BL (4 bytes): high=11110 S imm10  low=11 J1 1 J2 imm11
		{.BL, {.REL24_T32, .NONE, .NONE, .NONE}, {.BRANCH_24_T32, .NONE, .NONE, .NONE}, 0xF000D000, 0xF800D000, .THUMB, .T32, {branch=true, writes_pc=true, thumb32=true, cond_in_28=false}},
	},

	// BX / BLX (register form) -- ARMv4T+ for BX, ARMv5T+ for BLX_reg
	.BX = {
		{.BX, {.GPR, .NONE, .NONE, .NONE}, {.RM_A32, .NONE, .NONE, .NONE}, 0x012FFF10, 0x0FFFFFF0, .BASE, .A32, {branch=true, writes_pc=true}},
		// T16 Format 5 BX: 010001 11 0 Rm 000
		{.BX, {.GPR, .NONE, .NONE, .NONE}, {.RM_T16_HI, .NONE, .NONE, .NONE}, 0x00004700, 0x0000FF87, .THUMB, .T32, {branch=true, writes_pc=true, cond_in_28=false}},
	},
	.BLX = {
		// BLX register: cond 0001 0010 1111 1111 1111 0011 Rm
		{.BLX, {.GPR,   .NONE, .NONE, .NONE}, {.RM_A32,    .NONE, .NONE, .NONE}, 0x012FFF30, 0x0FFFFFF0, .V5T, .A32, {branch=true, writes_pc=true}},
		// BLX immediate (unconditional class): 1111 101 H imm24  -- H=bit24 toggles ARM/Thumb
		{.BLX, {.REL24, .NONE, .NONE, .NONE}, {.BRANCH_24, .NONE, .NONE, .NONE}, 0xFA000000, 0xFE000000, .V5T, .A32, {branch=true, writes_pc=true, cond_in_28=false}},
		// T16 Format 5 BLX reg: 010001 11 1 Rm 000
		{.BLX, {.GPR, .NONE, .NONE, .NONE}, {.RM_T16_HI, .NONE, .NONE, .NONE}, 0x00004780, 0x0000FF87, .V5T,  .T32, {branch=true, writes_pc=true, cond_in_28=false}},
	},
	.BXJ = { {.BXJ, {.GPR, .NONE, .NONE, .NONE}, {.RM_A32, .NONE, .NONE, .NONE}, 0x012FFF20, 0x0FFFFFF0, .V5TEJ, .A32, {branch=true, writes_pc=true, deprecated=true}} },

	// SVC (was SWI): cond 1111 imm24
	.SVC = {
		{.SVC, {.IMM, .NONE, .NONE, .NONE}, {.A32_IMM24, .NONE, .NONE, .NONE}, 0x0F000000, 0x0F000000, .BASE, .A32, {}},
		// T16 Format 17 SVC: 11011111 imm8
		{.SVC, {.IMM, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0000DF00, 0x0000FF00, .THUMB, .T32, {cond_in_28=false}},
	},
	// BKPT (unconditional class but uses cond=NV reserved encoding traditionally):
	//   cond 0001 0010 imm12 0111 imm4   (cond=AL only)
	.BKPT = {
		{.BKPT, {.IMM, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xE1200070, 0xFFF000F0, .V5T, .A32, {cond_in_28=false}},
		// T16 BKPT: 1011 1110 imm8
		{.BKPT, {.IMM, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0000BE00, 0x0000FF00, .V5T,  .T32, {cond_in_28=false}},
	},
	// HVC: 0001 0100 imm12 0111 imm4
	.HVC  = { {.HVC,  {.IMM, .NONE, .NONE, .NONE}, {.NONE,     .NONE, .NONE, .NONE}, 0xE1400070, 0xFFF000F0, .V7VE, .A32, {cond_in_28=false}} },
	// SMC: cond 0001 0110 0000 0000 0000 0111 imm4
	.SMC  = { {.SMC,  {.IMM, .NONE, .NONE, .NONE}, {.NONE,     .NONE, .NONE, .NONE}, 0x01600070, 0x0FFFFFF0, .V7,   .A32, {}} },
	// UDF: 1111 0111 1111 imm12 1111 imm4   (permanently undefined)
	.UDF = {
		{.UDF, {.IMM, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xE7F000F0, 0xFFF000F0, .BASE, .A32, {cond_in_28=false}},
		// T16 UDF: 1101 1110 imm8
		{.UDF, {.IMM, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0000DE00, 0x0000FF00, .THUMB, .T32, {cond_in_28=false}},
		// T32 UDF: high=11110 0 1111 1111 imm4  low=10 1 0 imm12
		{.UDF, {.IMM, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF7F0A000, 0xFFF0F000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	// HLT (ARMv8 AArch32): 0001 0000 imm12 0111 imm4
	.HLT  = { {.HLT,  {.IMM, .NONE, .NONE, .NONE}, {.NONE,     .NONE, .NONE, .NONE}, 0xE1000070, 0xFFF000F0, .V8,   .A32, {cond_in_28=false}} },

	// MSR / MRS (status reg access)
	.MRS = {
		{.MRS, {.GPR, .PSR_FIELD, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0x010F0000, 0x0FBF0FFF, .BASE, .A32, {}},
		// T32 MRS: high=11110011 1110 1111  low=10 0 0 Rd 0000 0000
		{.MRS, {.GPR, .PSR_FIELD, .NONE, .NONE}, {.RD_T32, .NONE, .NONE, .NONE}, 0xF3EF8000, 0xFFFFF0FF, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.MSR = {
		// MSR APSR_<fields>, #imm12_mod (immediate form)
		{.MSR, {.PSR_FIELD, .IMM_MOD, .NONE, .NONE},  {.PSR_FIELD_MASK, .A32_IMM_MOD, .NONE, .NONE}, 0x0320F000, 0x0FB0F000, .BASE, .A32, {}},
		// MSR APSR_<fields>, Rn (register form)
		{.MSR, {.PSR_FIELD, .GPR, .NONE, .NONE},      {.PSR_FIELD_MASK, .RM_A32,       .NONE, .NONE}, 0x0120F000, 0x0FB0FFF0, .BASE, .A32, {}},
		// T32 MSR: high=11110011 1000 Rn  low=10 0 0 mask 0000 0000
		{.MSR, {.PSR_FIELD, .GPR, .NONE, .NONE}, {.PSR_FIELD_MASK, .RN_T32, .NONE, .NONE}, 0xF3808000, 0xFFF0F0FF, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},

	// CPS (change processor state, ARMv6): 1111 0001 0000 imod M iflags mode_field
	.CPS = { {.CPS, {.IMM_IFLAGS, .NONE, .NONE, .NONE}, {.CPS_IFLAGS, .NONE, .NONE, .NONE}, 0xF1000000, 0xFFF1FE20, .V6, .A32, {cond_in_28=false}} },

	// SETEND (deprecated in ARMv8): 1111 0001 0000 0001 0000 000E 0000 0000
	.SETEND = { {.SETEND, {.IMM_ENDIAN, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF1010000, 0xFFFFFDFF, .V6, .A32, {cond_in_28=false, deprecated=true}} },

	// SETPAN (ARMv8.1): A32 = 1111 0001 0001 0000 0000 0000 imm1 0000 0000  → bit 9 = imm
	// T16:               1011 0110 0001 0 imm1 000                          → bit 3 = imm
	.SETPAN = {
		{.SETPAN, {.IMM_HINT, .NONE, .NONE, .NONE}, {.HINT_FIELD, .NONE, .NONE, .NONE}, 0xF1100000, 0xFFFFFDFF, .V8, .A32, {cond_in_28=false}},
		{.SETPAN, {.IMM_HINT, .NONE, .NONE, .NONE}, {.HINT_FIELD, .NONE, .NONE, .NONE}, 0x0000B610, 0x0000FFF7, .V8, .T32, {cond_in_28=false}},
	},

	// ---- Hint instructions (cond 0011 0010 0000 1111 0000 0000 imm8 OR encoded form)
	.NOP = {
		{.NOP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0320F000, 0x0FFFFFFF, .V6K, .A32, {}},
		// T16 NOP: 1011 1111 0000 0000
		{.NOP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0000BF00, 0x0000FFFF, .V6T2, .T32, {cond_in_28=false}},
		// T32 NOP: high=11110011 1010 1111  low=10000000 hint
		{.NOP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF3AF8000, 0xFFFFFFFF, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.YIELD = {
		{.YIELD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0320F001, 0x0FFFFFFF, .V6K, .A32, {}},
		{.YIELD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0000BF10, 0x0000FFFF, .V6T2, .T32, {cond_in_28=false}},
		{.YIELD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF3AF8001, 0xFFFFFFFF, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.WFE = {
		{.WFE, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0320F002, 0x0FFFFFFF, .V6K, .A32, {}},
		{.WFE, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0000BF20, 0x0000FFFF, .V6T2, .T32, {cond_in_28=false}},
		{.WFE, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF3AF8002, 0xFFFFFFFF, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.WFI = {
		{.WFI, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0320F003, 0x0FFFFFFF, .V6K, .A32, {}},
		{.WFI, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0000BF30, 0x0000FFFF, .V6T2, .T32, {cond_in_28=false}},
		{.WFI, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF3AF8003, 0xFFFFFFFF, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SEV = {
		{.SEV, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0320F004, 0x0FFFFFFF, .V6K, .A32, {}},
		{.SEV, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0000BF40, 0x0000FFFF, .V6T2, .T32, {cond_in_28=false}},
		{.SEV, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF3AF8004, 0xFFFFFFFF, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.SEVL = { {.SEVL, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0320F005, 0x0FFFFFFF, .V8,  .A32, {}} },
	.DBG  = { {.DBG,  {.IMM_HINT, .NONE, .NONE, .NONE}, {.HINT_FIELD, .NONE, .NONE, .NONE}, 0x0320F0F0, 0x0FFFFFF0, .V7, .A32, {}} },
	.HINT = { {.HINT, {.IMM_HINT, .NONE, .NONE, .NONE}, {.HINT_FIELD, .NONE, .NONE, .NONE}, 0x0320F000, 0x0FFFFF00, .V6K, .A32, {}} },

	// Memory barriers (ARMv7): 1111 0101 0111 1111 1111 0000 type imm4
	.DMB = {
		{.DMB, {.IMM_BARRIER, .NONE, .NONE, .NONE}, {.BARRIER_TYPE, .NONE, .NONE, .NONE}, 0xF57FF050, 0xFFFFFFF0, .V7, .A32, {cond_in_28=false}},
		// T32 DMB: F3BF 8F50 + type
		{.DMB, {.IMM_BARRIER, .NONE, .NONE, .NONE}, {.BARRIER_TYPE, .NONE, .NONE, .NONE}, 0xF3BF8F50, 0xFFFFFFF0, .V7, .T32, {thumb32=true, cond_in_28=false}},
	},
	.DSB = {
		{.DSB, {.IMM_BARRIER, .NONE, .NONE, .NONE}, {.BARRIER_TYPE, .NONE, .NONE, .NONE}, 0xF57FF040, 0xFFFFFFF0, .V7, .A32, {cond_in_28=false}},
		{.DSB, {.IMM_BARRIER, .NONE, .NONE, .NONE}, {.BARRIER_TYPE, .NONE, .NONE, .NONE}, 0xF3BF8F40, 0xFFFFFFF0, .V7, .T32, {thumb32=true, cond_in_28=false}},
	},
	.ISB = {
		{.ISB, {.IMM_BARRIER, .NONE, .NONE, .NONE}, {.BARRIER_TYPE, .NONE, .NONE, .NONE}, 0xF57FF060, 0xFFFFFFF0, .V7, .A32, {cond_in_28=false}},
		{.ISB, {.IMM_BARRIER, .NONE, .NONE, .NONE}, {.BARRIER_TYPE, .NONE, .NONE, .NONE}, 0xF3BF8F60, 0xFFFFFFF0, .V7, .T32, {thumb32=true, cond_in_28=false}},
	},

	// ---- HINT-family barriers (ARMv8 FEAT_RAS / FEAT_SPE / FEAT_TRF / FEAT_CSV2) ----
	// A32: cond 0011 0010 0000 1111 0000 0000 imm8 (HINT with specific imm)
	// T32: 1111 0011 1010 1111 1000 0000 imm8

	// ESB (Error Synchronization Barrier, FEAT_RAS) -- HINT #16
	.ESB = {
		{.ESB, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0320F010, 0x0FFFFFFF, .V8, .A32, {}},
		{.ESB, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF3AF8010, 0xFFFFFFFF, .V8, .T32, {thumb32=true, cond_in_28=false}},
	},
	// PSB CSYNC (Profiling Synchronization Barrier, FEAT_SPE) -- HINT #17
	.PSB_CSYNC = {
		{.PSB_CSYNC, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0320F011, 0x0FFFFFFF, .V8, .A32, {}},
		{.PSB_CSYNC, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF3AF8011, 0xFFFFFFFF, .V8, .T32, {thumb32=true, cond_in_28=false}},
	},
	// TSB CSYNC (Trace Synchronization Barrier, FEAT_TRF) -- HINT #18
	.TSB_CSYNC = {
		{.TSB_CSYNC, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0320F012, 0x0FFFFFFF, .V8, .A32, {}},
		{.TSB_CSYNC, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF3AF8012, 0xFFFFFFFF, .V8, .T32, {thumb32=true, cond_in_28=false}},
	},
	// CSDB (Consumption of Speculative Data Barrier, FEAT_CSV2) -- HINT #20
	.CSDB = {
		{.CSDB, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0320F014, 0x0FFFFFFF, .V8, .A32, {}},
		{.CSDB, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF3AF8014, 0xFFFFFFFF, .V8, .T32, {thumb32=true, cond_in_28=false}},
	},
	// SB (Synchronization Barrier, FEAT_SB, ARMv8.5) -- dedicated barrier encoding
	// A32: 1111 0101 0111 1111 1111 0000 0111 0000 = 0xF57FF070
	// T32: 1111 0011 1011 1111 1000 1111 0111 0000 = 0xF3BF8F70
	.SB = {
		{.SB, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF57FF070, 0xFFFFFFFF, .V8, .A32, {cond_in_28=false}},
		{.SB, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF3BF8F70, 0xFFFFFFFF, .V8, .T32, {thumb32=true, cond_in_28=false}},
	},

	// CLREX (clear exclusive monitor, ARMv6K+)
	.CLREX = {
		{.CLREX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF57FF01F, 0xFFFFFFFF, .V6K, .A32, {cond_in_28=false}},
		// T32 CLREX
		{.CLREX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF3BF8F2F, 0xFFFFFFFF, .V6K, .T32, {thumb32=true, cond_in_28=false}},
	},

	// Preload data / instruction (PLD/PLDW/PLI)
	.PLD = {
		{.PLD, {.MEM, .NONE, .NONE, .NONE}, {.MEM_IMM12_OFFSET, .NONE, .NONE, .NONE}, 0xF5D0F000, 0xFFF0F000, .V5T, .A32, {cond_in_28=false}},
		// T32 PLD imm12: 0xF890F000
		{.PLD, {.MEM, .NONE, .NONE, .NONE}, {.MEM_IMM12_OFFSET, .NONE, .NONE, .NONE}, 0xF890F000, 0xFFF0F000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.PLDW = {
		{.PLDW, {.MEM, .NONE, .NONE, .NONE}, {.MEM_IMM12_OFFSET, .NONE, .NONE, .NONE}, 0xF5D0F000, 0xFFF0F000, .V7, .A32, {cond_in_28=false}},
		// T32 PLDW imm12: 0xF830F000
		{.PLDW, {.MEM, .NONE, .NONE, .NONE}, {.MEM_IMM12_OFFSET, .NONE, .NONE, .NONE}, 0xF830F000, 0xFFF0F000, .V7, .T32, {thumb32=true, cond_in_28=false}},
	},
	.PLI = {
		{.PLI, {.MEM, .NONE, .NONE, .NONE}, {.MEM_IMM12_OFFSET, .NONE, .NONE, .NONE}, 0xF4D0F000, 0xFF70F000, .V7, .A32, {cond_in_28=false}},
		// T32 PLI imm12: 0xF990F000
		{.PLI, {.MEM, .NONE, .NONE, .NONE}, {.MEM_IMM12_OFFSET, .NONE, .NONE, .NONE}, 0xF990F000, 0xFFF0F000, .V7, .T32, {thumb32=true, cond_in_28=false}},
	},

	// ERET (exception return, ARMv7VE+)
	.ERET = { {.ERET, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0160006E, 0x0FFFFFFF, .V7VE, .A32, {writes_pc=true}} },

	// =========================================================================
	// §6 -- Load / Store (single + multiple)
	// =========================================================================

	// LDR / STR (word) -- immediate offset:
	//   cond 010 P U 0 W 1/0 Rn Rt imm12     (P=pre/U=add/W=writeback/0=str/1=ldr)
	// We split into three variants per direction: imm-offset, pre-index, post-index.
	.LDR = {
		// LDR imm12 offset: P=1 W=0
		{.LDR, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_IMM12_OFFSET, .NONE, .NONE}, 0x05900000, 0x0F700000, .BASE, .A32, {}},
		// LDR imm12 pre-index: P=1 W=1
		{.LDR, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_PRE_INDEX,    .NONE, .NONE}, 0x05B00000, 0x0F700000, .BASE, .A32, {}},
		// LDR imm12 post-index: P=0 W=0
		{.LDR, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX,   .NONE, .NONE}, 0x04900000, 0x0F700000, .BASE, .A32, {}},
		// LDR reg offset: cond 011 P U 0 W 1 Rn Rt shift_imm shift_type 0 Rm
		{.LDR, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_REG_OFFSET,   .NONE, .NONE}, 0x07900000, 0x0F700010, .BASE, .A32, {}},
		// T16 Format 6 LDR PC-relative: 01001 Rd imm8 (LDR Rd, [PC, #imm8 << 2])
		{.LDR, {.GPR_LOW, .MEM, .NONE, .NONE}, {.RD_T16_HI, .MEM_LITERAL, .NONE, .NONE}, 0x00004800, 0x0000F800, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 7 LDR reg-offset: 0101 100 Rm Rb Rd
		{.LDR, {.GPR_LOW, .MEM, .NONE, .NONE}, {.RD_T16_LO, .MEM_REG_OFFSET, .NONE, .NONE}, 0x00005800, 0x0000FE00, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 9 LDR imm5: 01101 imm5 Rb Rd  (offset = imm5 << 2)
		{.LDR, {.GPR_LOW, .MEM, .NONE, .NONE}, {.RD_T16_LO, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0x00006800, 0x0000F800, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 11 LDR SP-relative: 10011 Rd imm8 (LDR Rd, [SP, #imm8 << 2])
		{.LDR, {.GPR_LOW, .MEM, .NONE, .NONE}, {.RD_T16_HI, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0x00009800, 0x0000F800, .THUMB, .T32, {cond_in_28=false}},
		// T32 LDR imm12 offset: high=11111000 1101 Rn  low=Rt imm12
		{.LDR, {.GPR, .MEM, .NONE, .NONE}, {.RT_T32, .MEM_IMM12_OFFSET, .NONE, .NONE}, 0xF8D00000, 0xFFF00000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		// T32 LDR reg offset: high=11111000 0101 Rn  low=Rt 000000 imm2 Rm
		{.LDR, {.GPR, .MEM, .NONE, .NONE}, {.RT_T32, .MEM_REG_OFFSET, .NONE, .NONE}, 0xF8500000, 0xFFF00FC0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		// T32 LDR literal: high=11111000 X101 1111  low=Rt imm12  (PC-relative)
		{.LDR, {.GPR, .MEM, .NONE, .NONE}, {.RT_T32, .MEM_LITERAL, .NONE, .NONE}, 0xF85F0000, 0xFF7F0000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.STR = {
		{.STR, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_IMM12_OFFSET, .NONE, .NONE}, 0x05800000, 0x0F700000, .BASE, .A32, {}},
		{.STR, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_PRE_INDEX,    .NONE, .NONE}, 0x05A00000, 0x0F700000, .BASE, .A32, {}},
		{.STR, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX,   .NONE, .NONE}, 0x04800000, 0x0F700000, .BASE, .A32, {}},
		{.STR, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_REG_OFFSET,   .NONE, .NONE}, 0x07800000, 0x0F700010, .BASE, .A32, {}},
		// T16 Format 7 STR reg-offset: 0101 000 Rm Rb Rd
		{.STR, {.GPR_LOW, .MEM, .NONE, .NONE}, {.RD_T16_LO, .MEM_REG_OFFSET, .NONE, .NONE}, 0x00005000, 0x0000FE00, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 9 STR imm5: 01100 imm5 Rb Rd  (offset = imm5 << 2)
		{.STR, {.GPR_LOW, .MEM, .NONE, .NONE}, {.RD_T16_LO, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0x00006000, 0x0000F800, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 11 STR SP-relative: 10010 Rd imm8 (STR Rd, [SP, #imm8 << 2])
		{.STR, {.GPR_LOW, .MEM, .NONE, .NONE}, {.RD_T16_HI, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0x00009000, 0x0000F800, .THUMB, .T32, {cond_in_28=false}},
		// T32 STR imm12: 0xF8C00000
		{.STR, {.GPR, .MEM, .NONE, .NONE}, {.RT_T32, .MEM_IMM12_OFFSET, .NONE, .NONE}, 0xF8C00000, 0xFFF00000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		// T32 STR reg: 0xF8400000 base
		{.STR, {.GPR, .MEM, .NONE, .NONE}, {.RT_T32, .MEM_REG_OFFSET, .NONE, .NONE}, 0xF8400000, 0xFFF00FC0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.LDRB = {
		{.LDRB, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_IMM12_OFFSET, .NONE, .NONE}, 0x05D00000, 0x0F700000, .BASE, .A32, {}},
		{.LDRB, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_PRE_INDEX,    .NONE, .NONE}, 0x05F00000, 0x0F700000, .BASE, .A32, {}},
		{.LDRB, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX,   .NONE, .NONE}, 0x04D00000, 0x0F700000, .BASE, .A32, {}},
		{.LDRB, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_REG_OFFSET,   .NONE, .NONE}, 0x07D00000, 0x0F700010, .BASE, .A32, {}},
		// T16 Format 7 LDRB reg-offset: 0101 110 Rm Rb Rd
		{.LDRB, {.GPR_LOW, .MEM, .NONE, .NONE}, {.RD_T16_LO, .MEM_REG_OFFSET, .NONE, .NONE}, 0x00005C00, 0x0000FE00, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 9 LDRB imm5: 01111 imm5 Rb Rd
		{.LDRB, {.GPR_LOW, .MEM, .NONE, .NONE}, {.RD_T16_LO, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0x00007800, 0x0000F800, .THUMB, .T32, {cond_in_28=false}},
		// T32 LDRB imm12 / reg
		{.LDRB, {.GPR, .MEM, .NONE, .NONE}, {.RT_T32, .MEM_IMM12_OFFSET, .NONE, .NONE}, 0xF8900000, 0xFFF00000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		{.LDRB, {.GPR, .MEM, .NONE, .NONE}, {.RT_T32, .MEM_REG_OFFSET,   .NONE, .NONE}, 0xF8100000, 0xFFF00FC0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.STRB = {
		{.STRB, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_IMM12_OFFSET, .NONE, .NONE}, 0x05C00000, 0x0F700000, .BASE, .A32, {}},
		{.STRB, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_PRE_INDEX,    .NONE, .NONE}, 0x05E00000, 0x0F700000, .BASE, .A32, {}},
		{.STRB, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX,   .NONE, .NONE}, 0x04C00000, 0x0F700000, .BASE, .A32, {}},
		{.STRB, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_REG_OFFSET,   .NONE, .NONE}, 0x07C00000, 0x0F700010, .BASE, .A32, {}},
		// T16 Format 7 STRB reg-offset: 0101 010 Rm Rb Rd
		{.STRB, {.GPR_LOW, .MEM, .NONE, .NONE}, {.RD_T16_LO, .MEM_REG_OFFSET, .NONE, .NONE}, 0x00005400, 0x0000FE00, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 9 STRB imm5: 01110 imm5 Rb Rd
		{.STRB, {.GPR_LOW, .MEM, .NONE, .NONE}, {.RD_T16_LO, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0x00007000, 0x0000F800, .THUMB, .T32, {cond_in_28=false}},
		// T32 STRB imm12 / reg
		{.STRB, {.GPR, .MEM, .NONE, .NONE}, {.RT_T32, .MEM_IMM12_OFFSET, .NONE, .NONE}, 0xF8800000, 0xFFF00000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		{.STRB, {.GPR, .MEM, .NONE, .NONE}, {.RT_T32, .MEM_REG_OFFSET,   .NONE, .NONE}, 0xF8000000, 0xFFF00FC0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},

	// LDRH / STRH / LDRSB / LDRSH / LDRD / STRD: cond 000 P U I W L Rn Rt imm4H 1 op2 1 imm4L
	//   where op2 = 01 (halfword), 10 (signed byte), 11 (signed half / doubleword)
	.LDRH = {
		// LDRH imm offset (P=1 W=0): cond 000 1 U 1 0 1 Rn Rt imm4H 1011 imm4L
		{.LDRH, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0x01D000B0, 0x0F7000F0, .BASE, .A32, {}},
		{.LDRH, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_PRE_INDEX,   .NONE, .NONE}, 0x01F000B0, 0x0F7000F0, .BASE, .A32, {}},
		{.LDRH, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX,  .NONE, .NONE}, 0x00D000B0, 0x0F7000F0, .BASE, .A32, {}},
		// LDRH reg offset: cond 000 1 U 0 0 1 Rn Rt 0000 1011 Rm
		{.LDRH, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_REG_OFFSET,  .NONE, .NONE}, 0x019000B0, 0x0F700FF0, .BASE, .A32, {}},
		// T16 Format 7 LDRH reg-offset: 0101 101 Rm Rb Rd
		{.LDRH, {.GPR_LOW, .MEM, .NONE, .NONE}, {.RD_T16_LO, .MEM_REG_OFFSET, .NONE, .NONE}, 0x00005A00, 0x0000FE00, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 10 LDRH imm5: 10001 imm5 Rb Rd (offset = imm5 << 1)
		{.LDRH, {.GPR_LOW, .MEM, .NONE, .NONE}, {.RD_T16_LO, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0x00008800, 0x0000F800, .THUMB, .T32, {cond_in_28=false}},
		// T32 LDRH imm12 / reg
		{.LDRH, {.GPR, .MEM, .NONE, .NONE}, {.RT_T32, .MEM_IMM12_OFFSET, .NONE, .NONE}, 0xF8B00000, 0xFFF00000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		{.LDRH, {.GPR, .MEM, .NONE, .NONE}, {.RT_T32, .MEM_REG_OFFSET,   .NONE, .NONE}, 0xF8300000, 0xFFF00FC0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.STRH = {
		{.STRH, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0x01C000B0, 0x0F7000F0, .BASE, .A32, {}},
		{.STRH, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_PRE_INDEX,   .NONE, .NONE}, 0x01E000B0, 0x0F7000F0, .BASE, .A32, {}},
		{.STRH, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX,  .NONE, .NONE}, 0x00C000B0, 0x0F7000F0, .BASE, .A32, {}},
		{.STRH, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_REG_OFFSET,  .NONE, .NONE}, 0x018000B0, 0x0F700FF0, .BASE, .A32, {}},
		// T16 Format 7 STRH reg-offset: 0101 001 Rm Rb Rd
		{.STRH, {.GPR_LOW, .MEM, .NONE, .NONE}, {.RD_T16_LO, .MEM_REG_OFFSET, .NONE, .NONE}, 0x00005200, 0x0000FE00, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 10 STRH imm5: 10000 imm5 Rb Rd
		{.STRH, {.GPR_LOW, .MEM, .NONE, .NONE}, {.RD_T16_LO, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0x00008000, 0x0000F800, .THUMB, .T32, {cond_in_28=false}},
		// T32 STRH imm12 / reg
		{.STRH, {.GPR, .MEM, .NONE, .NONE}, {.RT_T32, .MEM_IMM12_OFFSET, .NONE, .NONE}, 0xF8A00000, 0xFFF00000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		{.STRH, {.GPR, .MEM, .NONE, .NONE}, {.RT_T32, .MEM_REG_OFFSET,   .NONE, .NONE}, 0xF8200000, 0xFFF00FC0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.LDRSB = {
		{.LDRSB, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0x01D000D0, 0x0F7000F0, .BASE, .A32, {}},
		{.LDRSB, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_PRE_INDEX,   .NONE, .NONE}, 0x01F000D0, 0x0F7000F0, .BASE, .A32, {}},
		{.LDRSB, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX,  .NONE, .NONE}, 0x00D000D0, 0x0F7000F0, .BASE, .A32, {}},
		{.LDRSB, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_REG_OFFSET,  .NONE, .NONE}, 0x019000D0, 0x0F700FF0, .BASE, .A32, {}},
		// T16 Format 7 LDRSB reg-offset: 0101 011 Rm Rb Rd
		{.LDRSB, {.GPR_LOW, .MEM, .NONE, .NONE}, {.RD_T16_LO, .MEM_REG_OFFSET, .NONE, .NONE}, 0x00005600, 0x0000FE00, .THUMB, .T32, {cond_in_28=false}},
		// T32 LDRSB imm12 / reg
		{.LDRSB, {.GPR, .MEM, .NONE, .NONE}, {.RT_T32, .MEM_IMM12_OFFSET, .NONE, .NONE}, 0xF9900000, 0xFFF00000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		{.LDRSB, {.GPR, .MEM, .NONE, .NONE}, {.RT_T32, .MEM_REG_OFFSET,   .NONE, .NONE}, 0xF9100000, 0xFFF00FC0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.LDRSH = {
		{.LDRSH, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0x01D000F0, 0x0F7000F0, .BASE, .A32, {}},
		{.LDRSH, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_PRE_INDEX,   .NONE, .NONE}, 0x01F000F0, 0x0F7000F0, .BASE, .A32, {}},
		{.LDRSH, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX,  .NONE, .NONE}, 0x00D000F0, 0x0F7000F0, .BASE, .A32, {}},
		{.LDRSH, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_REG_OFFSET,  .NONE, .NONE}, 0x019000F0, 0x0F700FF0, .BASE, .A32, {}},
		// T16 Format 7 LDRSH reg-offset: 0101 111 Rm Rb Rd
		{.LDRSH, {.GPR_LOW, .MEM, .NONE, .NONE}, {.RD_T16_LO, .MEM_REG_OFFSET, .NONE, .NONE}, 0x00005E00, 0x0000FE00, .THUMB, .T32, {cond_in_28=false}},
		// T32 LDRSH imm12 / reg
		{.LDRSH, {.GPR, .MEM, .NONE, .NONE}, {.RT_T32, .MEM_IMM12_OFFSET, .NONE, .NONE}, 0xF9B00000, 0xFFF00000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		{.LDRSH, {.GPR, .MEM, .NONE, .NONE}, {.RT_T32, .MEM_REG_OFFSET,   .NONE, .NONE}, 0xF9300000, 0xFFF00FC0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.LDRD = {
		// LDRD imm offset (ARMv5TE+): cond 000 P U 1 W 0 Rn Rt imm4H 1101 imm4L
		{.LDRD, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0x01C000D0, 0x0F7000F0, .V5TE, .A32, {}},
		{.LDRD, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_PRE_INDEX,   .NONE, .NONE}, 0x01E000D0, 0x0F7000F0, .V5TE, .A32, {}},
		{.LDRD, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX,  .NONE, .NONE}, 0x00C000D0, 0x0F7000F0, .V5TE, .A32, {}},
		{.LDRD, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_REG_OFFSET,  .NONE, .NONE}, 0x018000D0, 0x0F700FF0, .V5TE, .A32, {}},
		// T32 LDRD imm8: high=11101001 X101 Rn  low=Rt Rt2 imm8
		{.LDRD, {.GPR, .GPR, .MEM, .NONE}, {.RT_T32, .RT2_T32, .RN_T32, .NONE}, 0xE9500000, 0xFE500000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.STRD = {
		{.STRD, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0x01C000F0, 0x0F7000F0, .V5TE, .A32, {}},
		{.STRD, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_PRE_INDEX,   .NONE, .NONE}, 0x01E000F0, 0x0F7000F0, .V5TE, .A32, {}},
		{.STRD, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX,  .NONE, .NONE}, 0x00C000F0, 0x0F7000F0, .V5TE, .A32, {}},
		{.STRD, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_REG_OFFSET,  .NONE, .NONE}, 0x018000F0, 0x0F700FF0, .V5TE, .A32, {}},
		// T32 STRD imm8: high=11101001 X100 Rn  low=Rt Rt2 imm8
		{.STRD, {.GPR, .GPR, .MEM, .NONE}, {.RT_T32, .RT2_T32, .RN_T32, .NONE}, 0xE9400000, 0xFE500000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},

	// Load/Store multiple (LDM/STM family). cond 100 P U S W L Rn register_list
	//   IA = P=0 U=1 ; IB = P=1 U=1 ; DA = P=0 U=0 ; DB = P=1 U=0
	//   S=1 selects user-mode register set (LDM/STM exceptional forms)
	//   W=1 writeback. L=1 load / L=0 store.
	// We encode the addressing-mode in the static bits; the encoder OR's
	// base register + register-list into Rn + register_list operand slots.
	.LDM = {
		// LDM IA (default)
		{.LDM, {.GPR, .GPR_LIST, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE}, 0x08900000, 0x0FD00000, .BASE, .A32, {}},
		// LDMIA writeback (LDM Rn!, {reglist}): W=1
		{.LDM, {.GPR, .GPR_LIST, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE}, 0x08B00000, 0x0FD00000, .BASE, .A32, {}},
		// LDMIB
		{.LDM, {.GPR, .GPR_LIST, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE}, 0x09900000, 0x0FD00000, .BASE, .A32, {}},
		// LDMDA
		{.LDM, {.GPR, .GPR_LIST, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE}, 0x08100000, 0x0FD00000, .BASE, .A32, {}},
		// LDMDB
		{.LDM, {.GPR, .GPR_LIST, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE}, 0x09100000, 0x0FD00000, .BASE, .A32, {}},
		// T16 Format 15 LDMIA: 11001 Rb reg_list8
		{.LDM, {.GPR_LOW, .GPR_LIST, .NONE, .NONE}, {.RD_T16_HI, .A32_REG_LIST, .NONE, .NONE}, 0x0000C800, 0x0000F800, .THUMB, .T32, {cond_in_28=false}},
		// T32 LDMIA: high=11101000 1001 Rn  low=PM 0 reg_list14
		{.LDM, {.GPR, .GPR_LIST, .NONE, .NONE}, {.RN_T32, .A32_REG_LIST, .NONE, .NONE}, 0xE8900000, 0xFFD00000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		// T32 LDMDB: high=11101001 0001 Rn  low=PM 0 reg_list14
		{.LDM, {.GPR, .GPR_LIST, .NONE, .NONE}, {.RN_T32, .A32_REG_LIST, .NONE, .NONE}, 0xE9100000, 0xFFD00000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.STM = {
		{.STM, {.GPR, .GPR_LIST, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE}, 0x08800000, 0x0FD00000, .BASE, .A32, {}},
		{.STM, {.GPR, .GPR_LIST, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE}, 0x08A00000, 0x0FD00000, .BASE, .A32, {}},
		{.STM, {.GPR, .GPR_LIST, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE}, 0x09800000, 0x0FD00000, .BASE, .A32, {}},
		{.STM, {.GPR, .GPR_LIST, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE}, 0x08000000, 0x0FD00000, .BASE, .A32, {}},
		{.STM, {.GPR, .GPR_LIST, .NONE, .NONE}, {.RN_A32, .A32_REG_LIST, .NONE, .NONE}, 0x09000000, 0x0FD00000, .BASE, .A32, {}},
		// T16 Format 15 STMIA: 11000 Rb reg_list8
		{.STM, {.GPR_LOW, .GPR_LIST, .NONE, .NONE}, {.RD_T16_HI, .A32_REG_LIST, .NONE, .NONE}, 0x0000C000, 0x0000F800, .THUMB, .T32, {cond_in_28=false}},
		// T32 STMIA: 0xE8800000
		{.STM, {.GPR, .GPR_LIST, .NONE, .NONE}, {.RN_T32, .A32_REG_LIST, .NONE, .NONE}, 0xE8800000, 0xFFD00000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		// T32 STMDB: 0xE9000000
		{.STM, {.GPR, .GPR_LIST, .NONE, .NONE}, {.RN_T32, .A32_REG_LIST, .NONE, .NONE}, 0xE9000000, 0xFFD00000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},

	// PUSH / POP are conventional aliases for STMDB SP! / LDMIA SP!
	.PUSH = {
		{.PUSH, {.GPR_LIST, .NONE, .NONE, .NONE}, {.A32_REG_LIST, .NONE, .NONE, .NONE}, 0x092D0000, 0x0FFF0000, .BASE, .A32, {}},
		// T16 Format 14 PUSH: 1011010 R reg_list8  (R bit selects LR included)
		{.PUSH, {.GPR_LIST, .NONE, .NONE, .NONE}, {.A32_REG_LIST, .NONE, .NONE, .NONE}, 0x0000B400, 0x0000FE00, .THUMB, .T32, {cond_in_28=false}},
		// T32 PUSH (STMDB SP!, reglist): 0xE92D0000
		{.PUSH, {.GPR_LIST, .NONE, .NONE, .NONE}, {.A32_REG_LIST, .NONE, .NONE, .NONE}, 0xE92D0000, 0xFFFF0000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.POP = {
		{.POP,  {.GPR_LIST, .NONE, .NONE, .NONE}, {.A32_REG_LIST, .NONE, .NONE, .NONE}, 0x08BD0000, 0x0FFF0000, .BASE, .A32, {}},
		// T16 Format 14 POP: 1011110 R reg_list8  (R bit selects PC included)
		{.POP,  {.GPR_LIST, .NONE, .NONE, .NONE}, {.A32_REG_LIST, .NONE, .NONE, .NONE}, 0x0000BC00, 0x0000FE00, .THUMB, .T32, {cond_in_28=false}},
		// T32 POP (LDMIA SP!, reglist): 0xE8BD0000
		{.POP, {.GPR_LIST, .NONE, .NONE, .NONE}, {.A32_REG_LIST, .NONE, .NONE, .NONE}, 0xE8BD0000, 0xFFFF0000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},

	// SWP / SWPB (deprecated since ARMv6)
	.SWP  = { {.SWP,  {.GPR, .GPR, .GPR, .NONE}, {.RT_A32, .RM_A32, .RN_A32, .NONE}, 0x01000090, 0x0FF00FF0, .BASE, .A32, {deprecated=true}} },
	.SWPB = { {.SWPB, {.GPR, .GPR, .GPR, .NONE}, {.RT_A32, .RM_A32, .RN_A32, .NONE}, 0x01400090, 0x0FF00FF0, .BASE, .A32, {deprecated=true}} },

	// RFE / SRS (return-from-exception / store return state)
	.RFE = {
		// 1111 100 P U 0 W 1 Rn 0000 1010 0000 0000
		{.RFE, {.GPR, .NONE, .NONE, .NONE}, {.RN_A32, .NONE, .NONE, .NONE}, 0xF8100A00, 0xFE10FFFF, .V6, .A32, {cond_in_28=false}},
	},
	.SRS = {
		// 1111 100 P U 1 W 0 1101 0000 0101 000 mode4
		{.SRS, {.IMM, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF84D0500, 0xFE5FFFE0, .V6, .A32, {cond_in_28=false}},
	},

	// =========================================================================
	// §7 -- Exclusive monitors + acquire/release
	// =========================================================================

	// LDREX family (ARMv6K+, then ARMv7 added all widths)
	.LDREX = {
		{.LDREX, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .RN_A32, .NONE, .NONE}, 0x01900F9F, 0x0FF00FFF, .V6K, .A32, {}},
		// T32 LDREX: high=11101000 0101 Rn  low=Rt 1111 imm8
		{.LDREX, {.GPR, .MEM, .NONE, .NONE}, {.RT_T32, .RN_T32, .NONE, .NONE}, 0xE8500F00, 0xFFF00F00, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.STREX = {
		{.STREX, {.GPR, .GPR, .MEM, .NONE}, {.RD, .RT_A32, .RN_A32, .NONE}, 0x01800F90, 0x0FF00FF0, .V6K, .A32, {}},
		// T32 STREX: high=11101000 0100 Rn  low=Rt Rd imm8
		{.STREX, {.GPR, .GPR, .MEM, .NONE}, {.RD_T32, .RT_T32, .RN_T32, .NONE}, 0xE8400000, 0xFFF00000, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.LDREXB = {
		{.LDREXB, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .RN_A32, .NONE, .NONE}, 0x01D00F9F, 0x0FF00FFF, .V6K, .A32, {}},
		// T32 LDREXB: high=11101000 1101 Rn  low=Rt 1111 0100 1111
		{.LDREXB, {.GPR, .MEM, .NONE, .NONE}, {.RT_T32, .RN_T32, .NONE, .NONE}, 0xE8D00F4F, 0xFFF00FFF, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.STREXB = {
		{.STREXB, {.GPR, .GPR, .MEM, .NONE}, {.RD, .RT_A32, .RN_A32, .NONE}, 0x01C00F90, 0x0FF00FF0, .V6K, .A32, {}},
		// T32 STREXB: high=11101000 1100 Rn  low=Rt 1111 0100 Rd
		{.STREXB, {.GPR, .GPR, .MEM, .NONE}, {.RD_T32, .RT_T32, .RN_T32, .NONE}, 0xE8C00F40, 0xFFF00FF0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.LDREXH = {
		{.LDREXH, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .RN_A32, .NONE, .NONE}, 0x01F00F9F, 0x0FF00FFF, .V6K, .A32, {}},
		{.LDREXH, {.GPR, .MEM, .NONE, .NONE}, {.RT_T32, .RN_T32, .NONE, .NONE}, 0xE8D00F5F, 0xFFF00FFF, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.STREXH = {
		{.STREXH, {.GPR, .GPR, .MEM, .NONE}, {.RD, .RT_A32, .RN_A32, .NONE}, 0x01E00F90, 0x0FF00FF0, .V6K, .A32, {}},
		{.STREXH, {.GPR, .GPR, .MEM, .NONE}, {.RD_T32, .RT_T32, .RN_T32, .NONE}, 0xE8C00F50, 0xFFF00FF0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.LDREXD = {
		{.LDREXD, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .RN_A32, .NONE, .NONE}, 0x01B00F9F, 0x0FF00FFF, .V6K, .A32, {}},
		// T32 LDREXD: high=11101000 1101 Rn  low=Rt Rt2 0111 1111
		{.LDREXD, {.GPR, .GPR, .MEM, .NONE}, {.RT_T32, .RT2_T32, .RN_T32, .NONE}, 0xE8D0007F, 0xFFF000FF, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.STREXD = {
		{.STREXD, {.GPR, .GPR, .MEM, .NONE}, {.RD, .RT_A32, .RN_A32, .NONE}, 0x01A00F90, 0x0FF00FF0, .V6K, .A32, {}},
		// T32 STREXD: high=11101000 1100 Rn  low=Rt Rt2 0111 Rd
		{.STREXD, {.GPR, .GPR, .GPR, .MEM}, {.RD_T32, .RT_T32, .RT2_T32, .RN_T32}, 0xE8C00070, 0xFFF000F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},

	// ARMv8 acquire/release (LDA/STL family, exclusive too)
	.LDA   = { {.LDA,   {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .RN_A32, .NONE, .NONE}, 0x01900C9F, 0x0FF00FFF, .V8, .A32, {}} },
	// STL/STLB/STLH: per ARMv8 ARM, Rt is at bits 3:0 (NOT 15:12); bits 15:12 are
	// 0xF fixed. Use RM_A32 enc for Rt to place it correctly.
	.STL   = { {.STL,   {.GPR, .MEM, .NONE, .NONE}, {.RM_A32, .RN_A32, .NONE, .NONE}, 0x0180FC90, 0x0FF0FFF0, .V8, .A32, {}} },
	.LDAB  = { {.LDAB,  {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .RN_A32, .NONE, .NONE}, 0x01D00C9F, 0x0FF00FFF, .V8, .A32, {}} },
	.STLB  = { {.STLB,  {.GPR, .MEM, .NONE, .NONE}, {.RM_A32, .RN_A32, .NONE, .NONE}, 0x01C0FC90, 0x0FF0FFF0, .V8, .A32, {}} },
	.LDAH  = { {.LDAH,  {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .RN_A32, .NONE, .NONE}, 0x01F00C9F, 0x0FF00FFF, .V8, .A32, {}} },
	.STLH  = { {.STLH,  {.GPR, .MEM, .NONE, .NONE}, {.RM_A32, .RN_A32, .NONE, .NONE}, 0x01E0FC90, 0x0FF0FFF0, .V8, .A32, {}} },
	.LDAEX  = { {.LDAEX,  {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .RN_A32, .NONE, .NONE}, 0x01900E9F, 0x0FF00FFF, .V8, .A32, {}} },
	.STLEX  = { {.STLEX,  {.GPR, .GPR, .MEM, .NONE}, {.RD, .RT_A32, .RN_A32, .NONE},      0x01800E90, 0x0FF00FF0, .V8, .A32, {}} },
	.LDAEXB = { {.LDAEXB, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .RN_A32, .NONE, .NONE}, 0x01D00E9F, 0x0FF00FFF, .V8, .A32, {}} },
	.STLEXB = { {.STLEXB, {.GPR, .GPR, .MEM, .NONE}, {.RD, .RT_A32, .RN_A32, .NONE},      0x01C00E90, 0x0FF00FF0, .V8, .A32, {}} },
	.LDAEXH = { {.LDAEXH, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .RN_A32, .NONE, .NONE}, 0x01F00E9F, 0x0FF00FFF, .V8, .A32, {}} },
	.STLEXH = { {.STLEXH, {.GPR, .GPR, .MEM, .NONE}, {.RD, .RT_A32, .RN_A32, .NONE},      0x01E00E90, 0x0FF00FF0, .V8, .A32, {}} },
	.LDAEXD = { {.LDAEXD, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .RN_A32, .NONE, .NONE}, 0x01B00E9F, 0x0FF00FFF, .V8, .A32, {}} },
	.STLEXD = { {.STLEXD, {.GPR, .GPR, .MEM, .NONE}, {.RD, .RT_A32, .RN_A32, .NONE},      0x01A00E90, 0x0FF00FF0, .V8, .A32, {}} },

	// =========================================================================
	// §8 -- Coprocessor + CRC32 + Crypto
	// =========================================================================

	// CDP / CDP2:  cond 1110 opc1 CRn CRd cp_num opc2 0 CRm
	.CDP  = { {.CDP,  {.COPROC_NUM, .IMM_COPROC_OP, .COPROC_REG, .COPROC_REG}, {.COPROC_NUM_FIELD, .COPROC_OPC1_FIELD, .COPROC_CRN_FIELD, .COPROC_CRM_FIELD}, 0x0E000000, 0x0F000010, .BASE, .A32, {}} },
	.CDP2 = { {.CDP2, {.COPROC_NUM, .IMM_COPROC_OP, .COPROC_REG, .COPROC_REG}, {.COPROC_NUM_FIELD, .COPROC_OPC1_FIELD, .COPROC_CRN_FIELD, .COPROC_CRM_FIELD}, 0xFE000000, 0xFF000010, .V5T,  .A32, {cond_in_28=false}} },
	// MCR / MCR2 / MRC / MRC2: cond 1110 opc1 L CRn Rt cp_num opc2 1 CRm
	.MCR  = { {.MCR,  {.COPROC_NUM, .IMM_COPROC_OP, .GPR, .COPROC_REG},        {.COPROC_NUM_FIELD, .COPROC_OPC1_FIELD, .RT_A32,           .COPROC_CRM_FIELD}, 0x0E000010, 0x0F100010, .BASE, .A32, {}} },
	.MCR2 = { {.MCR2, {.COPROC_NUM, .IMM_COPROC_OP, .GPR, .COPROC_REG},        {.COPROC_NUM_FIELD, .COPROC_OPC1_FIELD, .RT_A32,           .COPROC_CRM_FIELD}, 0xFE000010, 0xFF100010, .V5T,  .A32, {cond_in_28=false}} },
	.MRC  = { {.MRC,  {.COPROC_NUM, .IMM_COPROC_OP, .GPR, .COPROC_REG},        {.COPROC_NUM_FIELD, .COPROC_OPC1_FIELD, .RT_A32,           .COPROC_CRM_FIELD}, 0x0E100010, 0x0F100010, .BASE, .A32, {}} },
	.MRC2 = { {.MRC2, {.COPROC_NUM, .IMM_COPROC_OP, .GPR, .COPROC_REG},        {.COPROC_NUM_FIELD, .COPROC_OPC1_FIELD, .RT_A32,           .COPROC_CRM_FIELD}, 0xFE100010, 0xFF100010, .V5T,  .A32, {cond_in_28=false}} },
	// MCRR / MCRR2 / MRRC / MRRC2: cond 1100 010 0/1 Rt2 Rt cp_num opc CRm
	.MCRR  = { {.MCRR,  {.COPROC_NUM, .IMM_COPROC_OP, .GPR, .GPR}, {.COPROC_NUM_FIELD, .COPROC_OPC_MCRR, .RT_A32, .RT2_A32}, 0x0C400000, 0x0FF00000, .V6, .A32, {}} },
	.MCRR2 = { {.MCRR2, {.COPROC_NUM, .IMM_COPROC_OP, .GPR, .GPR}, {.COPROC_NUM_FIELD, .COPROC_OPC_MCRR, .RT_A32, .RT2_A32}, 0xFC400000, 0xFFF00000, .V6, .A32, {cond_in_28=false}} },
	.MRRC  = { {.MRRC,  {.COPROC_NUM, .IMM_COPROC_OP, .GPR, .GPR}, {.COPROC_NUM_FIELD, .COPROC_OPC_MCRR, .RT_A32, .RT2_A32}, 0x0C500000, 0x0FF00000, .V6, .A32, {}} },
	.MRRC2 = { {.MRRC2, {.COPROC_NUM, .IMM_COPROC_OP, .GPR, .GPR}, {.COPROC_NUM_FIELD, .COPROC_OPC_MCRR, .RT_A32, .RT2_A32}, 0xFC500000, 0xFFF00000, .V6, .A32, {cond_in_28=false}} },
	// LDC / STC: cond 110 P U N W L Rn CRd cp_num imm8
	.LDC  = { {.LDC,  {.COPROC_NUM, .COPROC_REG, .MEM, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRN_FIELD, .MEM_IMM8_OFFSET, .NONE}, 0x0C100000, 0x0F100000, .BASE, .A32, {}} },
	.LDC2 = { {.LDC2, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRN_FIELD, .MEM_IMM8_OFFSET, .NONE}, 0xFC100000, 0xFF100000, .V5T, .A32, {cond_in_28=false}} },
	.STC  = { {.STC,  {.COPROC_NUM, .COPROC_REG, .MEM, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRN_FIELD, .MEM_IMM8_OFFSET, .NONE}, 0x0C000000, 0x0F100000, .BASE, .A32, {}} },
	.STC2 = { {.STC2, {.COPROC_NUM, .COPROC_REG, .MEM, .NONE}, {.COPROC_NUM_FIELD, .COPROC_CRN_FIELD, .MEM_IMM8_OFFSET, .NONE}, 0xFC000000, 0xFF100000, .V5T, .A32, {cond_in_28=false}} },

	// ARMv8 CRC32 family
	//   cond 0001 0 sz 0 Rn Rd 0000 0 0 1 0 0 Rm   sz=00 byte / 01 half / 10 word
	//   bit  9 selects CRC32 (0) vs CRC32C (1).
	.CRC32B  = { {.CRC32B,  {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x01000040, 0x0FF00FF0, .CRC32, .A32, {}} },
	.CRC32H  = { {.CRC32H,  {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x01200040, 0x0FF00FF0, .CRC32, .A32, {}} },
	.CRC32W  = { {.CRC32W,  {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x01400040, 0x0FF00FF0, .CRC32, .A32, {}} },
	.CRC32CB = { {.CRC32CB, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x01000240, 0x0FF00FF0, .CRC32, .A32, {}} },
	.CRC32CH = { {.CRC32CH, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x01200240, 0x0FF00FF0, .CRC32, .A32, {}} },
	.CRC32CW = { {.CRC32CW, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RN_A32, .RM_A32, .NONE}, 0x01400240, 0x0FF00FF0, .CRC32, .A32, {}} },


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
	//   VADD entries include both VFP scalar (S/D-reg) and NEON vector (D/Q-reg)
	//   forms. The matcher dispatches on operand types.
	.VADD = {
		// VFP scalar
		{.VADD, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0E300A00, 0x0FB00B50, .VFPV2, .A32, {}},
		{.VADD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0x0E300B00, 0x0FB00B50, .VFPV2, .A32, {}},
		// VFP F16 scalar (FEAT_FP16): cp=1001
		{.VADD, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0E300900, 0x0FB00F50, .HALF_FP, .A32, {}},
		// NEON F16 vector: 1111 0010 0 D 1 0 Vn Vd 1101 N Q M 0 Vm (bit 4 = 0 for VADD)
		{.VADD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2100D00, 0xFFB00F10, .NEON_HALF_FP, .A32, {cond_in_28=false}},
		{.VADD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2100D40, 0xFFB00F50, .NEON_HALF_FP, .A32, {cond_in_28=false}},
		// NEON integer (D-reg), size = 00/01/10/11
		{.VADD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000800, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VADD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2100800, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VADD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200800, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VADD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2300800, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		// NEON integer (Q-reg)
		{.VADD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000840, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VADD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2100840, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VADD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2200840, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VADD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2300840, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// NEON F32 (D and Q)
		{.VADD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000D00, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VADD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000D40, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// MVE integer: Q-only, T32, 1110 1111 0 0 sz Qn Qd 1000 N 1 M 0 Qm
		{.VADD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEF000840, 0xEF810F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
		// MVE FP: 1110 1111 0 0 sz Qn Qd 1101 N 1 M 1 Qm
		{.VADD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEF000D40, 0xEFA10F51, .MVE_FP,  .T32, {thumb32=true, cond_in_28=false}},
		// MVE scalar Rm (Qd, Qn, Rt): per LLVM vadd.i8 q1,q2,r3 = 0xEE05_2F43 -> base 0xEE010F40
		{.VADD, {.QPR, .QPR, .GPR, .NONE}, {.VD_Q, .VN_Q, .RM_T32, .NONE}, 0xEE010F40, 0xEF811FF0, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VSUB = {
		// VFP scalar
		{.VSUB, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0E300A40, 0x0FB00B50, .VFPV2, .A32, {}},
		{.VSUB, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0x0E300B40, 0x0FB00B50, .VFPV2, .A32, {}},
		// VFP F16 scalar
		{.VSUB, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0E300940, 0x0FB00F50, .HALF_FP, .A32, {}},
		// NEON F16 (bit 4 = 0 for VSUB; bit 21 = 1 selects sub)
		{.VSUB, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2300D00, 0xFFB00F10, .NEON_HALF_FP, .A32, {cond_in_28=false}},
		{.VSUB, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2300D40, 0xFFB00F50, .NEON_HALF_FP, .A32, {cond_in_28=false}},
		// NEON integer (D-reg)
		{.VSUB, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000800, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VSUB, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3100800, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VSUB, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3200800, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VSUB, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3300800, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		// NEON integer (Q-reg)
		{.VSUB, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3000840, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VSUB, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3100840, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VSUB, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3200840, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VSUB, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3300840, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// NEON F32 (D and Q)
		{.VSUB, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200D00, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VSUB, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2200D40, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// MVE integer / FP / scalar
		{.VSUB, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xFF000840, 0xFF810F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
		{.VSUB, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEF200D40, 0xEFA10F51, .MVE_FP,  .T32, {thumb32=true, cond_in_28=false}},
		// VSUB MVE scalar: per LLVM 0xEE05_3F43 -> base 0xEE011F40
		{.VSUB, {.QPR, .QPR, .GPR, .NONE}, {.VD_Q, .VN_Q, .RM_T32, .NONE}, 0xEE011F40, 0xEF811FF0, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// (VMUL/VMLA/VMLS are declared further below with both VFP scalar and
	//  NEON vector forms in a single block.)
	.VDIV = {
		{.VDIV, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0E800A00, 0x0FB00B50, .VFPV2, .A32, {}},
		{.VDIV, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0x0E800B00, 0x0FB00B50, .VFPV2, .A32, {}},
		// VFP F16 scalar
		{.VDIV, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0E800900, 0x0FB00F50, .HALF_FP, .A32, {}},
	},
	.VNMUL = {
		{.VNMUL, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0E200A40, 0x0FB00B50, .VFPV2, .A32, {}},
		{.VNMUL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0x0E200B40, 0x0FB00B50, .VFPV2, .A32, {}},
	},
	.VNMLS = {
		{.VNMLS, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0E100A00, 0x0FB00B50, .VFPV2, .A32, {}},
		{.VNMLS, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0x0E100B00, 0x0FB00B50, .VFPV2, .A32, {}},
	},
	.VNMLA = {
		{.VNMLA, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0E100A40, 0x0FB00B50, .VFPV2, .A32, {}},
		{.VNMLA, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0x0E100B40, 0x0FB00B50, .VFPV2, .A32, {}},
	},
	// VFPv4 fused multiply-add
	.VFMA = {
		{.VFMA, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0EA00A00, 0x0FB00B50, .VFPV4, .A32, {}},
		{.VFMA, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0x0EA00B00, 0x0FB00B50, .VFPV4, .A32, {}},
		// VFP F16 scalar
		{.VFMA, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0EA00900, 0x0FB00F50, .HALF_FP, .A32, {}},
		// NEON F32: 1111 0010 0 D 0 0 Vn Vd 1100 N Q M 1 Vm
		{.VFMA, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000C10, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VFMA, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000C50, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// MVE FP vector + scalar
		{.VFMA, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEF000C50, 0xEFA10F51, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}},
		{.VFMA, {.QPR, .QPR, .GPR, .NONE}, {.VD_Q, .VN_Q, .RM_T32, .NONE}, 0xEE310E40, 0xEFB10F51, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VFMS = {
		{.VFMS, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0EA00A40, 0x0FB00B50, .VFPV4, .A32, {}},
		{.VFMS, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0x0EA00B40, 0x0FB00B50, .VFPV4, .A32, {}},
		// VFP F16 scalar
		{.VFMS, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0EA00940, 0x0FB00F50, .HALF_FP, .A32, {}},
		// NEON F32 (bit 21 = 1)
		{.VFMS, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200C10, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VFMS, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2200C50, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// MVE FP vector
		{.VFMS, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEF200C50, 0xEFA10F51, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VFNMS = {
		{.VFNMS, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0E900A00, 0x0FB00B50, .VFPV4, .A32, {}},
		{.VFNMS, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0x0E900B00, 0x0FB00B50, .VFPV4, .A32, {}},
		// VFP F16 scalar
		{.VFNMS, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0E900900, 0x0FB00F50, .HALF_FP, .A32, {}},
	},
	.VFNMA = {
		{.VFNMA, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0E900A40, 0x0FB00B50, .VFPV4, .A32, {}},
		{.VFNMA, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0x0E900B40, 0x0FB00B50, .VFPV4, .A32, {}},
		// VFP F16 scalar
		{.VFNMA, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0E900940, 0x0FB00F50, .HALF_FP, .A32, {}},
	},

	// ---- 2-operand unary FP (opc1=1011 op2=xxxx) ----
	//   Format: cond 1110 1011 D opc2 Vd 101 sz E 1 M 0 Vm
	//   opc2 (bits 19:16): 0000 VMOV, 0001 VNEG, 0010 VSQRT, etc.
	// (VABS / VNEG: VFP scalar + NEON forms declared together further below.)
	.VSQRT = {
		{.VSQRT, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EB10AC0, 0x0FBF0FD0, .VFPV2, .A32, {}},
		{.VSQRT, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0x0EB10BC0, 0x0FBF0FD0, .VFPV2, .A32, {}},
		// VFP F16 scalar (cp=1001)
		{.VSQRT, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EB109C0, 0x0FBF0FD0, .HALF_FP, .A32, {}},
	},
	// VMOV reg-reg (opc2=0000, op=0)
	.VMOV = {
		{.VMOV, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EB00A40, 0x0FBF0FD0, .VFPV2, .A32, {}},
		{.VMOV, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0x0EB00B40, 0x0FBF0FD0, .VFPV2, .A32, {}},
		// VMOV imm (opc1=1011 opc2=0000 op=0, imm in (19:16)+(3:0) split)
		{.VMOV, {.SPR, .IMM8, .NONE, .NONE}, {.VD_S, .VFP_IMM8, .NONE, .NONE}, 0x0EB00A00, 0x0FB00FF0, .VFPV3, .A32, {}},
		{.VMOV, {.DPR, .IMM8, .NONE, .NONE}, {.VD_D, .VFP_IMM8, .NONE, .NONE}, 0x0EB00B00, 0x0FB00FF0, .VFPV3, .A32, {}},
		// VMOV GPR <-> S reg: cond 1110 000 op L Vn Rt 1010 N 0010000
		{.VMOV, {.SPR, .GPR, .NONE, .NONE}, {.VN_S, .RT_A32, .NONE, .NONE}, 0x0E000A10, 0x0FF00F7F, .VFPV2, .A32, {}},
		{.VMOV, {.GPR, .SPR, .NONE, .NONE}, {.RT_A32, .VN_S, .NONE, .NONE}, 0x0E100A10, 0x0FF00F7F, .VFPV2, .A32, {}},
		// VMOV two GPRs <-> D reg (VMOV Rt, Rt2, Dm)
		{.VMOV, {.GPR, .GPR, .DPR, .NONE}, {.RT_A32, .RT2_A32, .VM_D, .NONE}, 0x0C500B10, 0x0FF00FD0, .VFPV2, .A32, {}},
		{.VMOV, {.DPR, .GPR, .GPR, .NONE}, {.VM_D, .RT_A32, .RT2_A32, .NONE}, 0x0C400B10, 0x0FF00FD0, .VFPV2, .A32, {}},
		// VMOV two GPRs <-> two consecutive S regs
		{.VMOV, {.GPR, .GPR, .SPR, .SPR}, {.RT_A32, .RT2_A32, .VM_S, .NONE}, 0x0C500A10, 0x0FF00FD0, .VFPV2, .A32, {}},
		{.VMOV, {.SPR, .SPR, .GPR, .GPR}, {.VM_S, .NONE, .RT_A32, .RT2_A32}, 0x0C400A10, 0x0FF00FD0, .VFPV2, .A32, {}},
		// ---- VMOV NEON modified immediate ----
		//   1111 0010 1 D 000 imm3 Vd cmode 0 Q op 1 imm4   (op=0 VMOV, op=1 VMVN)
		// cmode mappings (8 forms when op=0):
		//   0000 .I32 (low byte broadcast)        → 0xF2800010
		//   0010 .I32 shifted 8 bits              → 0xF2800210
		//   0100 .I32 shifted 16 bits             → 0xF2800410
		//   0110 .I32 shifted 24 bits             → 0xF2800610
		//   1000 .I16 (low byte broadcast)        → 0xF2800810
		//   1010 .I16 shifted 8 bits              → 0xF2800A10
		//   1100 .I32 expanded with one trailing 1 → 0xF2800C10
		//   1101 .I32 expanded with two trailing 1s → 0xF2800D10
		//   1110 .I8                              → 0xF2800E10
		//   1111 .F32 (special: high bit = 0)     → 0xF2800F10 (limited to specific imm patterns)
		//   1110 op=1 + bit 5 set → .I64          → 0xF2800E30
		{.VMOV, {.DPR, .IMM, .NONE, .NONE}, {.VD_D, .NONE, .NONE, .NONE}, 0xF2800010, 0xFEB80F90, .NEON, .A32, {cond_in_28=false}},  // .I32 cmode=0000
		{.VMOV, {.DPR, .IMM, .NONE, .NONE}, {.VD_D, .NONE, .NONE, .NONE}, 0xF2800210, 0xFEB80F90, .NEON, .A32, {cond_in_28=false}},  // .I32 cmode=0010
		{.VMOV, {.DPR, .IMM, .NONE, .NONE}, {.VD_D, .NONE, .NONE, .NONE}, 0xF2800410, 0xFEB80F90, .NEON, .A32, {cond_in_28=false}},  // .I32 cmode=0100
		{.VMOV, {.DPR, .IMM, .NONE, .NONE}, {.VD_D, .NONE, .NONE, .NONE}, 0xF2800610, 0xFEB80F90, .NEON, .A32, {cond_in_28=false}},  // .I32 cmode=0110
		{.VMOV, {.DPR, .IMM, .NONE, .NONE}, {.VD_D, .NONE, .NONE, .NONE}, 0xF2800810, 0xFEB80F90, .NEON, .A32, {cond_in_28=false}},  // .I16 cmode=1000
		{.VMOV, {.DPR, .IMM, .NONE, .NONE}, {.VD_D, .NONE, .NONE, .NONE}, 0xF2800A10, 0xFEB80F90, .NEON, .A32, {cond_in_28=false}},  // .I16 cmode=1010
		{.VMOV, {.DPR, .IMM, .NONE, .NONE}, {.VD_D, .NONE, .NONE, .NONE}, 0xF2800C10, 0xFEB80F90, .NEON, .A32, {cond_in_28=false}},  // .I32 cmode=1100
		{.VMOV, {.DPR, .IMM, .NONE, .NONE}, {.VD_D, .NONE, .NONE, .NONE}, 0xF2800D10, 0xFEB80F90, .NEON, .A32, {cond_in_28=false}},  // .I32 cmode=1101
		{.VMOV, {.DPR, .IMM, .NONE, .NONE}, {.VD_D, .NONE, .NONE, .NONE}, 0xF2800E10, 0xFEB80F90, .NEON, .A32, {cond_in_28=false}},  // .I8 cmode=1110
		{.VMOV, {.DPR, .IMM, .NONE, .NONE}, {.VD_D, .NONE, .NONE, .NONE}, 0xF2800F10, 0xFEB80F90, .NEON, .A32, {cond_in_28=false}},  // .F32 cmode=1111
		{.VMOV, {.DPR, .IMM, .NONE, .NONE}, {.VD_D, .NONE, .NONE, .NONE}, 0xF2800E30, 0xFEB80F90, .NEON, .A32, {cond_in_28=false}},  // .I64 (op=0+bit5=1)
		// Q forms (Q=1, bit 6 = 1)
		{.VMOV, {.QPR, .IMM, .NONE, .NONE}, {.VD_Q, .NONE, .NONE, .NONE}, 0xF2800050, 0xFEB80FD0, .NEON, .A32, {cond_in_28=false}},  // .I32 Q
		{.VMOV, {.QPR, .IMM, .NONE, .NONE}, {.VD_Q, .NONE, .NONE, .NONE}, 0xF2800850, 0xFEB80FD0, .NEON, .A32, {cond_in_28=false}},  // .I16 Q
		{.VMOV, {.QPR, .IMM, .NONE, .NONE}, {.VD_Q, .NONE, .NONE, .NONE}, 0xF2800E50, 0xFEB80FD0, .NEON, .A32, {cond_in_28=false}},  // .I8 Q
		{.VMOV, {.QPR, .IMM, .NONE, .NONE}, {.VD_Q, .NONE, .NONE, .NONE}, 0xF2800F50, 0xFEB80FD0, .NEON, .A32, {cond_in_28=false}},  // .F32 Q
		{.VMOV, {.QPR, .IMM, .NONE, .NONE}, {.VD_Q, .NONE, .NONE, .NONE}, 0xF2800E70, 0xFEB80FD0, .NEON, .A32, {cond_in_28=false}},  // .I64 Q
		// ---- VMOV scalar to/from GPR (lane access) ----
		//   VMOV.<size> Rt, Dn[idx]:  cond 1110 U opc1 1 Vn Rt 1011 N opc2 1 0000
		//   VMOV.<size> Dn[idx], Rt:  cond 1110 0 opc1 0 Vn Rt 1011 N opc2 1 0000
		// .8 / .16 / .32 selected by opc1+opc2 split bits in encoding.
		// 32-bit lane move (.32):
		{.VMOV, {.GPR, .DPR_ELEM, .NONE, .NONE}, {.RT_A32, .VN_D, .NONE, .NONE}, 0x0E100B10, 0x0F100F1F, .NEON, .A32, {}},
		{.VMOV, {.DPR_ELEM, .GPR, .NONE, .NONE}, {.VN_D, .RT_A32, .NONE, .NONE}, 0x0E000B10, 0x0F100F1F, .NEON, .A32, {}},
	},
	// ---- VMVN NEON modified immediate (op=1 form) ----
	//   bit 5 = 1 distinguishes VMVN from VMOV
	.VMVN = {
		{.VMVN, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B00580, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VMVN, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B005C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		// VMVN immediate: 1111 0010 1 D 000 imm3 Vd cmode 0 Q 1 1 imm4 (op=1)
		{.VMVN, {.DPR, .IMM, .NONE, .NONE}, {.VD_D, .NONE, .NONE, .NONE}, 0xF2800030, 0xFEB80F90, .NEON, .A32, {cond_in_28=false}},  // .I32 cmode=0000
		{.VMVN, {.DPR, .IMM, .NONE, .NONE}, {.VD_D, .NONE, .NONE, .NONE}, 0xF2800230, 0xFEB80F90, .NEON, .A32, {cond_in_28=false}},
		{.VMVN, {.DPR, .IMM, .NONE, .NONE}, {.VD_D, .NONE, .NONE, .NONE}, 0xF2800430, 0xFEB80F90, .NEON, .A32, {cond_in_28=false}},
		{.VMVN, {.DPR, .IMM, .NONE, .NONE}, {.VD_D, .NONE, .NONE, .NONE}, 0xF2800630, 0xFEB80F90, .NEON, .A32, {cond_in_28=false}},
		{.VMVN, {.DPR, .IMM, .NONE, .NONE}, {.VD_D, .NONE, .NONE, .NONE}, 0xF2800830, 0xFEB80F90, .NEON, .A32, {cond_in_28=false}},  // .I16 cmode=1000
		{.VMVN, {.DPR, .IMM, .NONE, .NONE}, {.VD_D, .NONE, .NONE, .NONE}, 0xF2800A30, 0xFEB80F90, .NEON, .A32, {cond_in_28=false}},
		{.VMVN, {.DPR, .IMM, .NONE, .NONE}, {.VD_D, .NONE, .NONE, .NONE}, 0xF2800C30, 0xFEB80F90, .NEON, .A32, {cond_in_28=false}},
		{.VMVN, {.DPR, .IMM, .NONE, .NONE}, {.VD_D, .NONE, .NONE, .NONE}, 0xF2800D30, 0xFEB80F90, .NEON, .A32, {cond_in_28=false}},
		// Q forms
		{.VMVN, {.QPR, .IMM, .NONE, .NONE}, {.VD_Q, .NONE, .NONE, .NONE}, 0xF2800070, 0xFEB80FD0, .NEON, .A32, {cond_in_28=false}},
		{.VMVN, {.QPR, .IMM, .NONE, .NONE}, {.VD_Q, .NONE, .NONE, .NONE}, 0xF2800870, 0xFEB80FD0, .NEON, .A32, {cond_in_28=false}},
		// MVE VMVN Qd, Qm
		{.VMVN, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xFFB005C0, 0xFFB30F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},

	// VCMP / VCMPE: cond 1110 1011 D 0100 Vd 101 sz E 1 M 0 Vm    (E=1 raises invalid op on QNaN)
	.VCMP = {
		{.VCMP, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EB40A40, 0x0FBF0F50, .VFPV2, .A32, {}},
		{.VCMP, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0x0EB40B40, 0x0FBF0F50, .VFPV2, .A32, {}},
		// VCMP with zero: cond 1110 1011 D 0101 Vd 101 sz E 1 (0) 0 0000
		{.VCMP, {.SPR, .NONE, .NONE, .NONE}, {.VD_S, .NONE, .NONE, .NONE}, 0x0EB50A40, 0x0FBF0FFF, .VFPV2, .A32, {}},
		{.VCMP, {.DPR, .NONE, .NONE, .NONE}, {.VD_D, .NONE, .NONE, .NONE}, 0x0EB50B40, 0x0FBF0FFF, .VFPV2, .A32, {}},
		// VFP F16 scalar
		{.VCMP, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EB40940, 0x0FBF0F50, .HALF_FP, .A32, {}},
		{.VCMP, {.SPR, .NONE, .NONE, .NONE}, {.VD_S, .NONE, .NONE, .NONE}, 0x0EB50940, 0x0FBF0FFF, .HALF_FP, .A32, {}},
		// MVE VCMP Qn, Qm -- writes VPR.P0. Per LLVM:
		//   vcmp.i8 eq,q2,q3 -> 0xFE05_0F06  base 0xFE01_0F00
		//   vcmp.f32 eq,q2,q3 -> 0xEE35_0F06 base 0xEE31_0F00
		{.VCMP, {.QPR, .QPR, .NONE, .NONE}, {.VN_Q, .VM_Q, .NONE, .NONE}, 0xFE010F00, 0xFE818FF0, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
		{.VCMP, {.QPR, .QPR, .NONE, .NONE}, {.VN_Q, .VM_Q, .NONE, .NONE}, 0xEE310F00, 0xEFB10FF0, .MVE_FP,  .T32, {thumb32=true, cond_in_28=false}},
	},
	.VCMPE = {
		{.VCMPE, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EB40AC0, 0x0FBF0F50, .VFPV2, .A32, {}},
		{.VCMPE, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0x0EB40BC0, 0x0FBF0F50, .VFPV2, .A32, {}},
		{.VCMPE, {.SPR, .NONE, .NONE, .NONE}, {.VD_S, .NONE, .NONE, .NONE}, 0x0EB50AC0, 0x0FBF0FFF, .VFPV2, .A32, {}},
		{.VCMPE, {.DPR, .NONE, .NONE, .NONE}, {.VD_D, .NONE, .NONE, .NONE}, 0x0EB50BC0, 0x0FBF0FFF, .VFPV2, .A32, {}},
	},

	// VCVT family: int<->float and float<->float
	//   F32<->F64:  cond 1110 1011 D 0111 Vd 101 sz 1 1 M 0 Vm   (sz=0 to F64, sz=1 to F32)
	//   F32<->S32 / U32: opc2 selects direction and signedness.
	//   F32<->half-prec: VCVTB/VCVTT
	.VCVT = {
		// VCVT.F64.F32 Dd, Sm   (cond 1110 1011 D 0111 Vd 1010 11 M 0 Vm) sz=0 (output F32)... actually inverse:
		{.VCVT, {.DPR, .SPR, .NONE, .NONE}, {.VD_D, .VM_S, .NONE, .NONE}, 0x0EB70AC0, 0x0FBF0FD0, .VFPV2, .A32, {}},
		// VCVT.F32.F64 Sd, Dm   (sz=1 output F64; opc2=0111)
		{.VCVT, {.SPR, .DPR, .NONE, .NONE}, {.VD_S, .VM_D, .NONE, .NONE}, 0x0EB70BC0, 0x0FBF0FD0, .VFPV2, .A32, {}},
		// VCVT.S32.F32 Sd, Sm   (opc2=1101 op=1)
		{.VCVT, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EBD0AC0, 0x0FBF0FD0, .VFPV2, .A32, {}},
		// VCVT.U32.F32 Sd, Sm   (opc2=1100 op=1)
		{.VCVT, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EBC0AC0, 0x0FBF0FD0, .VFPV2, .A32, {}},
		// VCVT.S32.F64 Sd, Dm
		{.VCVT, {.SPR, .DPR, .NONE, .NONE}, {.VD_S, .VM_D, .NONE, .NONE}, 0x0EBD0BC0, 0x0FBF0FD0, .VFPV2, .A32, {}},
		// VCVT.U32.F64 Sd, Dm
		{.VCVT, {.SPR, .DPR, .NONE, .NONE}, {.VD_S, .VM_D, .NONE, .NONE}, 0x0EBC0BC0, 0x0FBF0FD0, .VFPV2, .A32, {}},
		// VCVT.F32.S32 Sd, Sm   (opc2=1000 op=1)
		{.VCVT, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EB80AC0, 0x0FBF0FD0, .VFPV2, .A32, {}},
		// VCVT.F32.U32 Sd, Sm   (opc2=1000 op=0)
		{.VCVT, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EB80A40, 0x0FBF0FD0, .VFPV2, .A32, {}},
		// VCVT.F64.S32 Dd, Sm
		{.VCVT, {.DPR, .SPR, .NONE, .NONE}, {.VD_D, .VM_S, .NONE, .NONE}, 0x0EB80BC0, 0x0FBF0FD0, .VFPV2, .A32, {}},
		// VCVT.F64.U32 Dd, Sm
		{.VCVT, {.DPR, .SPR, .NONE, .NONE}, {.VD_D, .VM_S, .NONE, .NONE}, 0x0EB80B40, 0x0FBF0FD0, .VFPV2, .A32, {}},
	},
	.VCVTB = {
		// VCVTB.F32.F16 / .F16.F32
		{.VCVTB, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EB20A40, 0x0FBF0FD0, .VFPV3, .A32, {}},
		{.VCVTB, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EB30A40, 0x0FBF0FD0, .VFPV3, .A32, {}},
	},
	.VCVTT = {
		{.VCVTT, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EB20AC0, 0x0FBF0FD0, .VFPV3, .A32, {}},
		{.VCVTT, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EB30AC0, 0x0FBF0FD0, .VFPV3, .A32, {}},
	},
	// ARMv8: VCVTA/N/P/M (rounding-mode FP-to-int) - cond=1111 (unconditional class)
	.VCVTA = {
		{.VCVTA, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0xFEBC0A40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}},
		{.VCVTA, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xFEBC0B40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}},
	},
	.VCVTN = {
		{.VCVTN, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0xFEBD0A40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}},
		{.VCVTN, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xFEBD0B40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}},
	},
	.VCVTP = {
		{.VCVTP, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0xFEBE0A40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}},
		{.VCVTP, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xFEBE0B40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}},
	},
	.VCVTM = {
		{.VCVTM, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0xFEBF0A40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}},
		{.VCVTM, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xFEBF0B40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}},
	},

	// VMRS / VMSR (access FPSCR + friends as GPR)
	//   VMRS: cond 1110 1111 0001 Rt 1010 0001 0000     (Rt=PC means transfer to APSR.NZCV)
	.VMRS = { {.VMRS, {.GPR, .NONE, .NONE, .NONE}, {.RT_A32, .NONE, .NONE, .NONE}, 0x0EF10A10, 0x0FFF0FFF, .VFPV2, .A32, {}} },
	.VMSR = { {.VMSR, {.GPR, .NONE, .NONE, .NONE}, {.RT_A32, .NONE, .NONE, .NONE}, 0x0EE10A10, 0x0FFF0FFF, .VFPV2, .A32, {}} },

	// VLDR / VSTR (single / double):  cond 1101 U D 0 1 Rn Vd 101 sz imm8
	.VLDR = {
		{.VLDR, {.SPR, .MEM, .NONE, .NONE}, {.VD_S, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0x0D100A00, 0x0F300F00, .VFPV2, .A32, {}},
		{.VLDR, {.DPR, .MEM, .NONE, .NONE}, {.VD_D, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0x0D100B00, 0x0F300F00, .VFPV2, .A32, {}},
	},
	.VSTR = {
		{.VSTR, {.SPR, .MEM, .NONE, .NONE}, {.VD_S, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0x0D000A00, 0x0F300F00, .VFPV2, .A32, {}},
		{.VSTR, {.DPR, .MEM, .NONE, .NONE}, {.VD_D, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0x0D000B00, 0x0F300F00, .VFPV2, .A32, {}},
	},

	// VLDM / VSTM (multiple S or D regs):  cond 110 P U D W L Rn Vd 101 sz imm8
	//   IA = P=0 U=1 ; DB = P=1 U=0 ; W=1 writeback; L=1 load / 0 store.
	.VLDM = {
		{.VLDM, {.GPR, .SPR_LIST, .NONE, .NONE}, {.RN_A32, .VFP_S_LIST, .NONE, .NONE}, 0x0C900A00, 0x0F900F00, .VFPV2, .A32, {}},
		{.VLDM, {.GPR, .DPR_LIST, .NONE, .NONE}, {.RN_A32, .VFP_D_LIST, .NONE, .NONE}, 0x0C900B00, 0x0F900F00, .VFPV2, .A32, {}},
	},
	.VSTM = {
		{.VSTM, {.GPR, .SPR_LIST, .NONE, .NONE}, {.RN_A32, .VFP_S_LIST, .NONE, .NONE}, 0x0C800A00, 0x0F900F00, .VFPV2, .A32, {}},
		{.VSTM, {.GPR, .DPR_LIST, .NONE, .NONE}, {.RN_A32, .VFP_D_LIST, .NONE, .NONE}, 0x0C800B00, 0x0F900F00, .VFPV2, .A32, {}},
	},
	.VPUSH = {
		{.VPUSH, {.SPR_LIST, .NONE, .NONE, .NONE}, {.VFP_S_LIST, .NONE, .NONE, .NONE}, 0x0D2D0A00, 0x0FFF0F00, .VFPV2, .A32, {}},
		{.VPUSH, {.DPR_LIST, .NONE, .NONE, .NONE}, {.VFP_D_LIST, .NONE, .NONE, .NONE}, 0x0D2D0B00, 0x0FFF0F00, .VFPV2, .A32, {}},
	},
	.VPOP = {
		{.VPOP, {.SPR_LIST, .NONE, .NONE, .NONE}, {.VFP_S_LIST, .NONE, .NONE, .NONE}, 0x0CBD0A00, 0x0FFF0F00, .VFPV2, .A32, {}},
		{.VPOP, {.DPR_LIST, .NONE, .NONE, .NONE}, {.VFP_D_LIST, .NONE, .NONE, .NONE}, 0x0CBD0B00, 0x0FFF0F00, .VFPV2, .A32, {}},
	},

	// ARMv8 FP min/max NaN-aware (VMAXNM/VMINNM), VSEL, VRINT*
	.VMAXNM = {
		{.VMAXNM, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0xFE800A00, 0xFFB00B50, .V8, .A32, {cond_in_28=false}},
		{.VMAXNM, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xFE800B00, 0xFFB00B50, .V8, .A32, {cond_in_28=false}},
	},
	.VMINNM = {
		{.VMINNM, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0xFE800A40, 0xFFB00B50, .V8, .A32, {cond_in_28=false}},
		{.VMINNM, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xFE800B40, 0xFFB00B50, .V8, .A32, {cond_in_28=false}},
	},
	.VSEL = {
		// VSEL<cond>.F32/F64 Sd, Sn, Sm -- cond field at bits 21-20 + 7
		{.VSEL, {.SPR, .SPR, .SPR, .COND}, {.VD_S, .VN_S, .VM_S, .NONE}, 0xFE000A00, 0xFF800F50, .V8, .A32, {cond_in_28=false}},
		{.VSEL, {.DPR, .DPR, .DPR, .COND}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xFE000B00, 0xFF800F50, .V8, .A32, {cond_in_28=false}},
	},
	.VRINTA = {
		{.VRINTA, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0xFEB80A40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}},
		{.VRINTA, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xFEB80B40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}},
		// MVE Q-form (FEAT_MVE_FP): per LLVM `vrinta.f32 q1, q3` -> 0xFFBA_0540
		{.VRINTA, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xFFBA0540, 0xFFBB0FD1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VRINTN = {
		{.VRINTN, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0xFEB90A40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}},
		{.VRINTN, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xFEB90B40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}},
		// MVE
		{.VRINTN, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xFFBA0440, 0xFFBB0FD1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VRINTP = {
		{.VRINTP, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0xFEBA0A40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}},
		{.VRINTP, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xFEBA0B40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}},
		// MVE
		{.VRINTP, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xFFBA07C0, 0xFFBB0FD1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VRINTM = {
		{.VRINTM, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0xFEBB0A40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}},
		{.VRINTM, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xFEBB0B40, 0xFFBF0FD0, .V8, .A32, {cond_in_28=false}},
		// MVE
		{.VRINTM, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xFFBA06C0, 0xFFBB0FD1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VRINTR = {
		{.VRINTR, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EB60A40, 0x0FBF0FD0, .V8, .A32, {}},
		{.VRINTR, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0x0EB60B40, 0x0FBF0FD0, .V8, .A32, {}},
	},
	.VRINTZ = {
		{.VRINTZ, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EB60AC0, 0x0FBF0FD0, .V8, .A32, {}},
		{.VRINTZ, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0x0EB60BC0, 0x0FBF0FD0, .V8, .A32, {}},
		// MVE
		{.VRINTZ, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xFFBA05C0, 0xFFBB0FD1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VRINTX = {
		{.VRINTX, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EB70A40, 0x0FBF0FD0, .V8, .A32, {}},
		{.VRINTX, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0x0EB70B40, 0x0FBF0FD0, .V8, .A32, {}},
		// MVE
		{.VRINTX, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xFFBA04C0, 0xFFBB0FD1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}},
	},
	// VJCVT (ARMv8.3): F64 -> S32 with JS-style rounding
	.VJCVT = { {.VJCVT, {.SPR, .DPR, .NONE, .NONE}, {.VD_S, .VM_D, .NONE, .NONE}, 0x0EB90BC0, 0x0FBF0FD0, .V8, .A32, {}} },

	// ---- VFP F16 scalar arithmetic (FEAT_FP16) ----
	//   Uses coproc 9 (cp_num = 1001) instead of 10/11 used by F32/F64.
	//   Format: cond 1110 opc1 D Vn Vd 1001 N op M 0 Vm
	// NOTE: VADD/VSUB/VMUL/VDIV/VABS/VNEG/VSQRT/VCMP F16 forms below extend
	// existing blocks; entries here go into their original mnemonic blocks
	// via the VADD/VSUB/etc. inline batches (see those blocks for the F16 row).

	// ---- F16 special: VCVTB / VCVTT for half/single conversion (already added) ----
	// VCVT.F16.F32 / .F32.F16 are at 0x0EB30A40 / 0x0EB20A40 (covered above).

	// =========================================================================
	// §10 -- Advanced SIMD (NEON) -- vector arithmetic + load/store
	// =========================================================================
	//
	// NEON A32 layout for 3-reg same: 1111 0010 U size Vn Vd op Q M op4 Vm
	//   U=0 signed / 1 unsigned (for ops where it matters)
	//   size (bits 21-20): 00=8b, 01=16b, 10=32b, 11=64b
	//   Q=1 -> 128-bit Q regs; Q=0 -> 64-bit D regs
	//   Top nibble F (1111) marks NEON unconditional class.
	//
	// We split by D vs Q form via separate Operand_Type entries.

	// ---- VMUL (integer + F32) ----
	.VMUL = {
		// VFP scalar
		{.VMUL, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0E200A00, 0x0FB00B50, .VFPV2, .A32, {}},
		{.VMUL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0x0E200B00, 0x0FB00B50, .VFPV2, .A32, {}},
		// VFP F16 scalar
		{.VMUL, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0E200900, 0x0FB00F50, .HALF_FP, .A32, {}},
		// NEON F16
		{.VMUL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3100D10, 0xFFB00F10, .NEON_HALF_FP, .A32, {cond_in_28=false}},
		{.VMUL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3100D50, 0xFFB00F50, .NEON_HALF_FP, .A32, {cond_in_28=false}},
		// NEON integer (.I8/.I16/.I32) D form: 1111 0010 0 size Vn Vd 1001 N 0 M 1 Vm
		{.VMUL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000910, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VMUL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2100910, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VMUL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200910, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		// NEON integer Q form
		{.VMUL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000950, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMUL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2100950, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMUL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2200950, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// NEON polynomial (.P8): U=1 bit 24
		{.VMUL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000910, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VMUL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3000950, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// NEON F32
		{.VMUL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000D10, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VMUL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3000D50, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// MVE integer / FP / scalar
		{.VMUL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEF000950, 0xEF810F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
		{.VMUL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xFF000D50, 0xFFA10F51, .MVE_FP,  .T32, {thumb32=true, cond_in_28=false}},
		// VMUL MVE scalar: per LLVM 0xEE05_3E63 -> base 0xEE011E60
		{.VMUL, {.QPR, .QPR, .GPR, .NONE}, {.VD_Q, .VN_Q, .RM_T32, .NONE}, 0xEE011E60, 0xEF811FF0, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// ---- VMLA / VMLS (integer + F32) ----
	.VMLA = {
		{.VMLA, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0E000A00, 0x0FB00B50, .VFPV2, .A32, {}},
		{.VMLA, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0x0E000B00, 0x0FB00B50, .VFPV2, .A32, {}},
		// VFP F16 scalar
		{.VMLA, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0E000900, 0x0FB00F50, .HALF_FP, .A32, {}},
		// NEON integer (multiply-accumulate)
		{.VMLA, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000900, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VMLA, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2100900, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VMLA, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200900, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VMLA, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000940, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLA, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2100940, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLA, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2200940, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// NEON F32
		{.VMLA, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000D10, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VMLA, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000D50, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// MVE VMLA Qda, Qn, Rm (scalar)
		{.VMLA, {.QPR, .QPR, .GPR, .NONE}, {.VD_Q, .VN_Q, .RM_T32, .NONE}, 0xEE010E40, 0xEF811F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMLS = {
		{.VMLS, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0E000A40, 0x0FB00B50, .VFPV2, .A32, {}},
		{.VMLS, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0x0E000B40, 0x0FB00B50, .VFPV2, .A32, {}},
		// VFP F16 scalar
		{.VMLS, {.SPR, .SPR, .SPR, .NONE}, {.VD_S, .VN_S, .VM_S, .NONE}, 0x0E000940, 0x0FB00F50, .HALF_FP, .A32, {}},
		// NEON integer (op-bit at 24 distinguishes VMLA vs VMLS for U=1)
		{.VMLS, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000900, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VMLS, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3100900, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VMLS, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3200900, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VMLS, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3000940, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLS, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3100940, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLS, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3200940, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// NEON F32 (bit 21 = 1 distinguishes FMLS from FMLA)
		{.VMLS, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200D10, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VMLS, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2200D50, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	// ---- VAND / VBIC / VORR / VORN / VEOR (bitwise, no size variants) ----
	.VAND = {
		// VAND D: 1111 0010 0000 Vn Vd 0001 N 0 M 1 Vm  (no size; always byte-wise)
		{.VAND, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000110, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VAND, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000150, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VAND, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEF000150, 0xFFB10F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VBIC = {
		// VBIC D: 1111 0010 0100 Vn Vd 0001 N 0 M 1 Vm
		{.VBIC, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2100110, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VBIC, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2100150, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VBIC, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEF100150, 0xFFB10F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VORR = {
		{.VORR, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200110, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VORR, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2200150, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VORR, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEF200150, 0xFFB10F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VORN = {
		{.VORN, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2300110, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VORN, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2300150, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VORN, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEF300150, 0xFFB10F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VEOR = {
		// U=1 distinguishes VEOR from VAND family
		{.VEOR, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000110, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VEOR, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3000150, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VEOR, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xFF000150, 0xFFB10F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// ---- VBSL / VBIT / VBIF (predicated bitwise select) ----
	.VBSL = {
		{.VBSL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3100110, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VBSL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3100150, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	.VBIT = {
		{.VBIT, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3200110, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VBIT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3200150, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	.VBIF = {
		{.VBIF, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3300110, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VBIF, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3300150, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	// ---- VMAX / VMIN (integer + F32) ----
	.VMAX = {
		// NEON integer signed (U=0)
		{.VMAX, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000600, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VMAX, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2100600, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VMAX, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200600, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VMAX, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000640, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMAX, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2100640, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMAX, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2200640, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// NEON integer unsigned (U=1)
		{.VMAX, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000600, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VMAX, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3000640, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// NEON F32
		{.VMAX, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000F00, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VMAX, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000F40, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// NEON F16 (sz bit 20 = 1)
		{.VMAX, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2100F00, 0xFFB00F10, .NEON_HALF_FP, .A32, {cond_in_28=false}},
		{.VMAX, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2100F40, 0xFFB00F50, .NEON_HALF_FP, .A32, {cond_in_28=false}},
		// MVE integer (VMAX.F32 doesn't exist in MVE; use VMAXNM.F32 instead)
		{.VMAX, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEF000640, 0xEF810F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMIN = {
		// bit 4 distinguishes MAX (0) vs MIN (1) within the 0x6_0 op family
		{.VMIN, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000610, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VMIN, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2100610, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VMIN, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200610, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VMIN, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000650, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMIN, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2100650, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMIN, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2200650, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMIN, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000610, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VMIN, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3000650, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// F32 (bit 21 = 1 selects MIN)
		{.VMIN, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200F00, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VMIN, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2200F40, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// NEON F16 (sz=1)
		{.VMIN, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2300F00, 0xFFB00F10, .NEON_HALF_FP, .A32, {cond_in_28=false}},
		{.VMIN, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2300F40, 0xFFB00F50, .NEON_HALF_FP, .A32, {cond_in_28=false}},
		// MVE integer (VMIN.F32 doesn't exist; use VMINNM.F32)
		{.VMIN, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEF000650, 0xEF810F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// ---- VCEQ / VCGT / VCGE (compare) ----
	.VCEQ = {
		// NEON integer (op family 0x8_0)
		{.VCEQ, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000810, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VCEQ, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3100810, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VCEQ, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3200810, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VCEQ, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3000850, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VCEQ, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3100850, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VCEQ, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3200850, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// NEON F32
		{.VCEQ, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000E00, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VCEQ, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000E40, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// NEON F16
		{.VCEQ, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2100E00, 0xFFB00F10, .NEON_HALF_FP, .A32, {cond_in_28=false}},
		{.VCEQ, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2100E40, 0xFFB00F50, .NEON_HALF_FP, .A32, {cond_in_28=false}},
	},
	.VCGT = {
		// signed: 0xF200_0300; unsigned: 0xF300_0300
		{.VCGT, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000300, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VCGT, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2100300, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VCGT, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200300, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VCGT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000340, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VCGT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2100340, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VCGT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2200340, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// unsigned
		{.VCGT, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000300, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VCGT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3000340, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// F32
		{.VCGT, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3200E00, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VCGT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3200E40, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// F16
		{.VCGT, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3300E00, 0xFFB00F10, .NEON_HALF_FP, .A32, {cond_in_28=false}},
		{.VCGT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3300E40, 0xFFB00F50, .NEON_HALF_FP, .A32, {cond_in_28=false}},
	},
	.VCGE = {
		// signed: 0xF200_0310; unsigned: 0xF300_0310
		{.VCGE, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000310, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VCGE, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2100310, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VCGE, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200310, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VCGE, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000350, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VCGE, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2100350, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VCGE, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2200350, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VCGE, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000310, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VCGE, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3000350, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// F32
		{.VCGE, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000E00, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VCGE, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3000E40, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// F16
		{.VCGE, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3100E00, 0xFFB00F10, .NEON_HALF_FP, .A32, {cond_in_28=false}},
		{.VCGE, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3100E40, 0xFFB00F50, .NEON_HALF_FP, .A32, {cond_in_28=false}},
	},
	// ---- VQADD / VQSUB (saturating) ----
	.VQADD = {
		// signed: F200_0010; unsigned: F300_0010
		{.VQADD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000010, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VQADD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2100010, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VQADD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200010, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VQADD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2300010, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VQADD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000050, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQADD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2100050, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQADD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2200050, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQADD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2300050, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// unsigned
		{.VQADD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000010, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VQADD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3000050, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// MVE
		{.VQADD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEF000050, 0xEF810F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VQSUB = {
		{.VQSUB, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000210, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VQSUB, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2100210, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VQSUB, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200210, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VQSUB, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2300210, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VQSUB, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000250, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQSUB, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2100250, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQSUB, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2200250, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQSUB, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2300250, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQSUB, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000210, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VQSUB, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3000250, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// MVE
		{.VQSUB, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEF000250, 0xEF810F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// ---- VHADD / VHSUB / VRHADD ----
	.VHADD = {
		{.VHADD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000000, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VHADD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2100000, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VHADD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200000, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VHADD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000040, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VHADD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2100040, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VHADD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2200040, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VHADD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000000, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VHADD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3000040, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// MVE
		{.VHADD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEF000040, 0xEF810F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VHSUB = {
		{.VHSUB, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000200, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VHSUB, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2100200, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VHSUB, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200200, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VHSUB, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000240, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VHSUB, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2100240, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VHSUB, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2200240, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VHSUB, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000200, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VHSUB, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3000240, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// MVE
		{.VHSUB, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEF000240, 0xEF810F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VRHADD = {
		{.VRHADD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000100, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VRHADD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000140, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// MVE
		{.VRHADD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEF000140, 0xEF810F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// ---- VPADD (pairwise add, D-form only) ----
	.VPADD = {
		// NEON integer (op 0xB10, bit 4 = 1)
		{.VPADD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000B10, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VPADD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2100B10, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VPADD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200B10, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		// F32
		{.VPADD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000D00, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		// (VPADD MVE form doesn't exist; MVE uses VADDV reduction instead)
	},
	// ---- VPMAX / VPMIN (D-form only) ----
	.VPMAX = {
		{.VPMAX, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000A00, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VPMAX, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2100A00, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VPMAX, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200A00, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VPMAX, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000A00, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		// F32
		{.VPMAX, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000F00, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		// (VPMAX MVE form doesn't exist; MVE uses VMAXV reduction)
	},
	.VPMIN = {
		{.VPMIN, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000A10, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VPMIN, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2100A10, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VPMIN, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200A10, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VPMIN, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000A10, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VPMIN, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3200F00, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		// (VPMIN MVE form doesn't exist; MVE uses VMINV reduction)
	},
	// ---- VTST (test bits) ----
	.VTST = {
		{.VTST, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000810, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VTST, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2100810, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VTST, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200810, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VTST, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000850, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VTST, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2100850, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VTST, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2200850, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	// ---- VABD (absolute difference) ----
	.VABD = {
		// signed
		{.VABD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000700, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VABD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2100700, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VABD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200700, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VABD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000740, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VABD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2100740, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VABD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2200740, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// unsigned
		{.VABD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000700, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VABD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3000740, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// F32 (bit 21=1 selects FP)
		{.VABD, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3200D00, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VABD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3200D40, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	// ---- VABA (accumulate absolute difference) ----
	.VABA = {
		{.VABA, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000710, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VABA, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2100710, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VABA, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200710, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VABA, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000750, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VABA, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2100750, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VABA, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2200750, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VABA, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000710, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VABA, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3000750, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},

	// ---- VSHL register (variable shift) ----
	.VSHL = {
		// signed: F200_0400; unsigned: F300_0400
		{.VSHL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF2000400, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VSHL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF2100400, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VSHL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF2200400, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VSHL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF2300400, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VSHL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF2000440, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VSHL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF2300440, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// unsigned shift by reg
		{.VSHL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF3000400, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VSHL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF3000440, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// MVE
		{.VSHL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEF000440, 0xEF810F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// VSHR immediate (signed/unsigned, .I8/.I16/.I32/.I64)
	.VSHR = {
		{.VSHR, {.DPR, .DPR, .IMM, .NONE}, {.VD_D, .VM_D, .NEON_SHIFT_IMM6, .NONE}, 0xF2800010, 0xFE800F10, .NEON, .A32, {cond_in_28=false}},
		{.VSHR, {.QPR, .QPR, .IMM, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xF2800050, 0xFE800F50, .NEON, .A32, {cond_in_28=false}},
		// unsigned
		{.VSHR, {.DPR, .DPR, .IMM, .NONE}, {.VD_D, .VM_D, .NEON_SHIFT_IMM6, .NONE}, 0xF3800010, 0xFE800F10, .NEON, .A32, {cond_in_28=false}},
		{.VSHR, {.QPR, .QPR, .IMM, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xF3800050, 0xFE800F50, .NEON, .A32, {cond_in_28=false}},
		// MVE imm form (imm6 at bits 21:16)
		{.VSHR, {.QPR, .QPR, .IMM5, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xEF800050, 0xEF800F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// VSRA imm
	.VSRA = {
		{.VSRA, {.DPR, .DPR, .IMM, .NONE}, {.VD_D, .VM_D, .NEON_SHIFT_IMM6, .NONE}, 0xF2800110, 0xFE800F10, .NEON, .A32, {cond_in_28=false}},
		{.VSRA, {.QPR, .QPR, .IMM, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xF2800150, 0xFE800F50, .NEON, .A32, {cond_in_28=false}},
		{.VSRA, {.DPR, .DPR, .IMM, .NONE}, {.VD_D, .VM_D, .NEON_SHIFT_IMM6, .NONE}, 0xF3800110, 0xFE800F10, .NEON, .A32, {cond_in_28=false}},
		{.VSRA, {.QPR, .QPR, .IMM, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xF3800150, 0xFE800F50, .NEON, .A32, {cond_in_28=false}},
		// MVE (imm6 at bits 21:16)
		{.VSRA, {.QPR, .QPR, .IMM5, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xEF800150, 0xEF800F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// VQSHL imm (saturating shift left)
	.VQSHL = {
		// register form (signed): F200_0410
		{.VQSHL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF2000410, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VQSHL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF2000450, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// unsigned: F300_0410
		{.VQSHL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF3000410, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VQSHL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF3000450, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// immediate form: F2800710
		{.VQSHL, {.DPR, .DPR, .IMM, .NONE}, {.VD_D, .VM_D, .NEON_SHIFT_IMM6, .NONE}, 0xF2800710, 0xFE800F10, .NEON, .A32, {cond_in_28=false}},
		{.VQSHL, {.QPR, .QPR, .IMM, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xF2800750, 0xFE800F50, .NEON, .A32, {cond_in_28=false}},
		// MVE
		{.VQSHL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEF000450, 0xEF810F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// VRSHL (rounding shift left)
	.VRSHL = {
		{.VRSHL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF2000500, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VRSHL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF2000540, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VRSHL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF3000500, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VRSHL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF3000540, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// MVE
		{.VRSHL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEF000540, 0xEF810F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// VRSHR (rounding shift right immediate)
	.VRSHR = {
		{.VRSHR, {.DPR, .DPR, .IMM, .NONE}, {.VD_D, .VM_D, .NEON_SHIFT_IMM6, .NONE}, 0xF2800210, 0xFE800F10, .NEON, .A32, {cond_in_28=false}},
		{.VRSHR, {.QPR, .QPR, .IMM, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xF2800250, 0xFE800F50, .NEON, .A32, {cond_in_28=false}},
		{.VRSHR, {.DPR, .DPR, .IMM, .NONE}, {.VD_D, .VM_D, .NEON_SHIFT_IMM6, .NONE}, 0xF3800210, 0xFE800F10, .NEON, .A32, {cond_in_28=false}},
		{.VRSHR, {.QPR, .QPR, .IMM, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xF3800250, 0xFE800F50, .NEON, .A32, {cond_in_28=false}},
		// MVE
		{.VRSHR, {.QPR, .QPR, .IMM5, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xEF800250, 0xEF800F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// VSLI / VSRI (shift left/right and insert)
	.VSLI = {
		{.VSLI, {.DPR, .DPR, .IMM, .NONE}, {.VD_D, .VM_D, .NEON_SHIFT_IMM6, .NONE}, 0xF3800510, 0xFE800F10, .NEON, .A32, {cond_in_28=false}},
		{.VSLI, {.QPR, .QPR, .IMM, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xF3800550, 0xFE800F50, .NEON, .A32, {cond_in_28=false}},
	},
	.VSRI = {
		{.VSRI, {.DPR, .DPR, .IMM, .NONE}, {.VD_D, .VM_D, .NEON_SHIFT_IMM6, .NONE}, 0xF3800410, 0xFE800F10, .NEON, .A32, {cond_in_28=false}},
		{.VSRI, {.QPR, .QPR, .IMM, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xF3800450, 0xFE800F50, .NEON, .A32, {cond_in_28=false}},
	},

	// ---- VABS / VNEG / VMVN / VCNT / VCLZ / VCLS (NEON unary) ----
	// (VABS/VNEG VFP scalar already declared; here we add NEON forms.)
	.VABS = {
		// VFP scalar (already declared near top of §9, here we extend the block)
		{.VABS, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EB00AC0, 0x0FBF0FD0, .VFPV2, .A32, {}},
		{.VABS, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0x0EB00BC0, 0x0FBF0FD0, .VFPV2, .A32, {}},
		// NEON integer: 1111 0011 1011 size 01 Vd 0011 0 Q M 0 Vm
		{.VABS, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B10300, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VABS, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B50300, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VABS, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B90300, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VABS, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B10340, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VABS, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B50340, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VABS, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B90340, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		// NEON F32 (size=10, bit 10 = 1)
		{.VABS, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B90700, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VABS, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B90740, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		// MVE integer + FP. Per LLVM: vabs.s8 q,q = FFB1_0340; vabs.f32 q,q = FFB9_0740 (bit 19 = 1 for FP).
		{.VABS, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xFFB10340, 0xFFB30F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
		{.VABS, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xFFB90740, 0xFFBB0F51, .MVE_FP,  .T32, {thumb32=true, cond_in_28=false}},
	},
	.VNEG = {
		{.VNEG, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EB10A40, 0x0FBF0FD0, .VFPV2, .A32, {}},
		{.VNEG, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0x0EB10B40, 0x0FBF0FD0, .VFPV2, .A32, {}},
		// NEON integer (bit 7 = 1 distinguishes VNEG from VABS)
		{.VNEG, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B10380, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VNEG, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B50380, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VNEG, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B90380, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VNEG, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B103C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VNEG, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B503C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VNEG, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B903C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		// NEON F32
		{.VNEG, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B90780, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VNEG, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B907C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		// MVE integer + FP. Per LLVM: vneg.s8 q,q = FFB1_03C0; vneg.f32 q,q = FFB9_07C0.
		{.VNEG, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xFFB103C0, 0xFFB30F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
		{.VNEG, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xFFB907C0, 0xFFBB0F51, .MVE_FP,  .T32, {thumb32=true, cond_in_28=false}},
	},
	// (VMVN declared earlier in VMOV neighbourhood with reg + immediate forms.)
	.VCNT = {
		// Byte-only: 1111 0011 1011 0000 size00 Vd 0101 0 Q M 0 Vm
		{.VCNT, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B00500, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCNT, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B00540, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
	},
	.VCLZ = {
		{.VCLZ, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B00480, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCLZ, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B40480, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCLZ, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B80480, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCLZ, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B004C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCLZ, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B404C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCLZ, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B804C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
	},
	.VCLS = {
		{.VCLS, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B00400, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCLS, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B40400, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCLS, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B80400, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCLS, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B00440, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCLS, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B40440, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCLS, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B80440, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
	},

	// ---- VREV16 / VREV32 / VREV64 (byte/half/word reverse within block) ----
	.VREV64 = {
		{.VREV64, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B00000, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VREV64, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B40000, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VREV64, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B80000, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VREV64, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B00040, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VREV64, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B40040, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VREV64, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B80040, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
	},
	.VREV32 = {
		{.VREV32, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B00080, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VREV32, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B40080, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VREV32, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B000C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VREV32, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B400C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
	},
	.VREV16 = {
		{.VREV16, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B00100, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VREV16, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B00140, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
	},

	// ---- VEXT (vector extract) ----
	.VEXT = {
		// 1111 0010 1011 Vn Vd imm4 N Q M 0 Vm
		{.VEXT, {.DPR, .DPR, .DPR, .IMM4}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2B00000, 0xFFB00010, .NEON, .A32, {cond_in_28=false}},
		{.VEXT, {.QPR, .QPR, .QPR, .IMM4}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2B00040, 0xFFB00050, .NEON, .A32, {cond_in_28=false}},
	},

	// ---- VDUP (duplicate scalar/reg to vector) ----
	.VDUP = {
		// VDUP from ARM register (Rt -> all lanes): cond 1110 1 B Q 0 Vd Rt 1011 D 0 E 1 0000
		//   B at bit 22, E at bit 5 select element size: BE=00 word, 10 half, 01 byte
		// Variant: vector D[lane] form (1111 0011 1011 imm4 Vd 1100 0 Q M 0 Vm)
		// We list the common scalar/Rt form for V_8B/V_16B/V_4H/V_8H/V_2S/V_4S.
		// (encoder picks based on operand kinds)
		{.VDUP, {.DPR, .GPR, .NONE, .NONE}, {.VD_D, .RT_A32, .NONE, .NONE}, 0x0EC00B10, 0x0FF00FD0, .NEON, .A32, {}},
		{.VDUP, {.QPR, .GPR, .NONE, .NONE}, {.VD_Q, .RT_A32, .NONE, .NONE}, 0x0EE00B10, 0x0FF00FD0, .NEON, .A32, {}},
		// VDUP from vector lane (.D form): 1111 0011 1011 imm4 Vd 1100 0 Q M 0 Vm
		{.VDUP, {.DPR, .DPR_ELEM, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B00C00, 0xFFB00FD0, .NEON, .A32, {cond_in_28=false}},
		{.VDUP, {.QPR, .DPR_ELEM, .NONE, .NONE}, {.VD_Q, .VM_D, .NONE, .NONE}, 0xF3B00C40, 0xFFB00FD0, .NEON, .A32, {cond_in_28=false}},
		// MVE VDUP Qd, Rt
		{.VDUP, {.QPR, .GPR, .NONE, .NONE}, {.VD_Q, .RT_T32, .NONE, .NONE}, 0xEE800B10, 0xFF900F5F, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},

	// ---- VTRN / VUZP / VZIP (interleave / deinterleave) ----
	.VTRN = {
		{.VTRN, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B20080, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VTRN, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B60080, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VTRN, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3BA0080, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VTRN, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B200C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VTRN, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B600C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VTRN, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3BA00C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
	},
	.VUZP = {
		{.VUZP, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B20100, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VUZP, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B60100, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VUZP, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B20140, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VUZP, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B60140, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VUZP, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3BA0140, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
	},
	.VZIP = {
		{.VZIP, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B20180, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VZIP, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B60180, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VZIP, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B201C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VZIP, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B601C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VZIP, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3BA01C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
	},

	// ---- VTBL / VTBX (table lookup) ----
	//   1111 0011 1 D 11 Vn Vd 10 len op M 0 Vm
	//   len = 00,01,10,11  selects 1/2/3/4-vec table; op=0 TBL, 1 TBX
	.VTBL = {
		// 1-vec table
		{.VTBL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3B00800, 0xFFB00F70, .NEON, .A32, {cond_in_28=false}},
		// 2-vec table
		{.VTBL, {.DPR, .DPR_LIST, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3B00900, 0xFFB00F70, .NEON, .A32, {cond_in_28=false}},
		// 3-vec table
		{.VTBL, {.DPR, .DPR_LIST, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3B00A00, 0xFFB00F70, .NEON, .A32, {cond_in_28=false}},
		// 4-vec table
		{.VTBL, {.DPR, .DPR_LIST, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3B00B00, 0xFFB00F70, .NEON, .A32, {cond_in_28=false}},
	},
	.VTBX = {
		{.VTBX, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3B00840, 0xFFB00F70, .NEON, .A32, {cond_in_28=false}},
		{.VTBX, {.DPR, .DPR_LIST, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3B00940, 0xFFB00F70, .NEON, .A32, {cond_in_28=false}},
		{.VTBX, {.DPR, .DPR_LIST, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3B00A40, 0xFFB00F70, .NEON, .A32, {cond_in_28=false}},
		{.VTBX, {.DPR, .DPR_LIST, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3B00B40, 0xFFB00F70, .NEON, .A32, {cond_in_28=false}},
	},

	// ---- VRECPE / VRSQRTE (reciprocal estimates) ----
	.VRECPE = {
		// Integer: 1111 0011 1011 1011 Vd 0100 0 Q M 0 Vm; FP: bit 8 = 1
		{.VRECPE, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3BB0400, 0xFFBF0FD0, .NEON, .A32, {cond_in_28=false}},
		{.VRECPE, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3BB0440, 0xFFBF0FD0, .NEON, .A32, {cond_in_28=false}},
		// FP form
		{.VRECPE, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3BB0500, 0xFFBF0FD0, .NEON, .A32, {cond_in_28=false}},
		{.VRECPE, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3BB0540, 0xFFBF0FD0, .NEON, .A32, {cond_in_28=false}},
		// (VRECPE MVE form doesn't exist in current MVE spec)
	},
	.VRSQRTE = {
		{.VRSQRTE, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3BB0480, 0xFFBF0FD0, .NEON, .A32, {cond_in_28=false}},
		{.VRSQRTE, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3BB04C0, 0xFFBF0FD0, .NEON, .A32, {cond_in_28=false}},
		{.VRSQRTE, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3BB0580, 0xFFBF0FD0, .NEON, .A32, {cond_in_28=false}},
		{.VRSQRTE, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3BB05C0, 0xFFBF0FD0, .NEON, .A32, {cond_in_28=false}},
		// (VRSQRTE MVE form doesn't exist)
	},
	// VRECPS / VRSQRTS (reciprocal step)
	.VRECPS = {
		{.VRECPS, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2000F10, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VRECPS, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000F50, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	.VRSQRTS = {
		{.VRSQRTS, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200F10, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VRSQRTS, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2200F50, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},

	// ---- VLD1 / VST1 (most-used load/store multiple structures) ----
	//   1111 0100 0D 00 Rn Vd type size align Rm
	//   We list the contiguous multi-vector forms. Lane and replicate forms
	//   have distinct opcode bits; included as separate entries.
	.VLD1 = {
		// VLD1 multiple (1-reg list, type=0111, size=00/01/10/11, D form)
		{.VLD1, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4200700, 0xFFF00F00, .NEON, .A32, {cond_in_28=false}},
		// VLD1 multiple (2-reg list, type=1010)
		{.VLD1, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4200A00, 0xFFF00F00, .NEON, .A32, {cond_in_28=false}},
		// VLD1 multiple (3-reg list, type=0110)
		{.VLD1, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4200600, 0xFFF00F00, .NEON, .A32, {cond_in_28=false}},
		// VLD1 multiple (4-reg list, type=0010)
		{.VLD1, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4200200, 0xFFF00F00, .NEON, .A32, {cond_in_28=false}},
		// VLD1 single lane to all lanes (VLD1R): 1111 0100 1 D 10 Rn Vd 1100 size T a Rm
		//   size 00 .8 / 01 .16 / 10 .32; T=0 single, T=1 pair
		{.VLD1, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4A00C00, 0xFFB00F00, .NEON, .A32, {cond_in_28=false}},
		// VLD1 single lane:  1111 0100 1 D 10 Rn Vd 0X00 size idx_align Rm  (X = 8/16/32 size selector)
		{.VLD1, {.DPR_ELEM, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4A00000, 0xFFB00F00, .NEON, .A32, {cond_in_28=false}},  // .8
		{.VLD1, {.DPR_ELEM, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4A00400, 0xFFB00F00, .NEON, .A32, {cond_in_28=false}},  // .16
		{.VLD1, {.DPR_ELEM, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4A00800, 0xFFB00F00, .NEON, .A32, {cond_in_28=false}},  // .32
	},
	.VST1 = {
		// VST1 multiple (1-reg list)
		{.VST1, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4000700, 0xFFF00F00, .NEON, .A32, {cond_in_28=false}},
		{.VST1, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4000A00, 0xFFF00F00, .NEON, .A32, {cond_in_28=false}},
		{.VST1, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4000600, 0xFFF00F00, .NEON, .A32, {cond_in_28=false}},
		{.VST1, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4000200, 0xFFF00F00, .NEON, .A32, {cond_in_28=false}},
		// VST1 single lane: 1111 0100 1 D 00 Rn Vd 0X00 size idx_align Rm
		{.VST1, {.DPR_ELEM, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4800000, 0xFFB00F00, .NEON, .A32, {cond_in_28=false}},  // .8
		{.VST1, {.DPR_ELEM, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4800400, 0xFFB00F00, .NEON, .A32, {cond_in_28=false}},  // .16
		{.VST1, {.DPR_ELEM, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4800800, 0xFFB00F00, .NEON, .A32, {cond_in_28=false}},  // .32
	},
	// VLD2 / VST2 / VLD3 / VST3 / VLD4 / VST4 - similar pattern with different "type" bits
	.VLD2 = {
		{.VLD2, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4200800, 0xFFF00F00, .NEON, .A32, {cond_in_28=false}},
		{.VLD2, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4200900, 0xFFF00F00, .NEON, .A32, {cond_in_28=false}},
		{.VLD2, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4200300, 0xFFF00F00, .NEON, .A32, {cond_in_28=false}},
	},
	.VST2 = {
		{.VST2, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4000800, 0xFFF00F00, .NEON, .A32, {cond_in_28=false}},
		{.VST2, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4000900, 0xFFF00F00, .NEON, .A32, {cond_in_28=false}},
		{.VST2, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4000300, 0xFFF00F00, .NEON, .A32, {cond_in_28=false}},
	},
	.VLD3 = {
		{.VLD3, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4200400, 0xFFF00F00, .NEON, .A32, {cond_in_28=false}},
		{.VLD3, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4200500, 0xFFF00F00, .NEON, .A32, {cond_in_28=false}},
	},
	.VST3 = {
		{.VST3, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4000400, 0xFFF00F00, .NEON, .A32, {cond_in_28=false}},
		{.VST3, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4000500, 0xFFF00F00, .NEON, .A32, {cond_in_28=false}},
	},
	.VLD4 = {
		{.VLD4, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4200000, 0xFFF00F00, .NEON, .A32, {cond_in_28=false}},
		{.VLD4, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4200100, 0xFFF00F00, .NEON, .A32, {cond_in_28=false}},
	},
	.VST4 = {
		{.VST4, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4000000, 0xFFF00F00, .NEON, .A32, {cond_in_28=false}},
		{.VST4, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VFP_D_LIST, .RN_A32, .NONE, .NONE}, 0xF4000100, 0xFFF00F00, .NEON, .A32, {cond_in_28=false}},
	},

	// ---- VMULL / VMLAL / VMLSL (widening multiplies) ----
	.VMULL = {
		// signed: 1111 0010 1U sz Vn Vd 1100 N 0 M 0 Vm
		{.VMULL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2800C00, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMULL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2900C00, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMULL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2A00C00, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// unsigned
		{.VMULL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3800C00, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMULL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3900C00, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMULL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3A00C00, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// polynomial: U=0, op=10
		{.VMULL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2800E00, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	// VMLAL / VMLSL (widening multiply-accumulate)
	//   VMLAL: signed F2800800 / unsigned F3800800; op=1000 (no minus); minus bit at 21
	.VMLAL = {
		{.VMLAL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2800800, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLAL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2900800, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLAL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2A00800, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLAL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3800800, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLAL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3900800, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLAL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3A00800, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	.VMLSL = {
		// VMLSL: op=1010 (bit 9 = 1)
		{.VMLSL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2800A00, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLSL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2900A00, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLSL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2A00A00, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLSL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3800A00, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLSL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3900A00, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLSL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3A00A00, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},

	// ---- VQDMULH / VQRDMULH (saturating doubling multiply, high half) ----
	//   1111 0010 0 D size Vn Vd 1011 N Q M 0 Vm    (VQDMULH)
	//   1111 0011 0 D size Vn Vd 1011 N Q M 0 Vm    (VQRDMULH)
	.VQDMULH = {
		{.VQDMULH, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2100B00, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VQDMULH, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2200B00, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VQDMULH, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2100B40, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQDMULH, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2200B40, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	.VQRDMULH = {
		{.VQRDMULH, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3100B00, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VQRDMULH, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3200B00, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VQRDMULH, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3100B40, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQRDMULH, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3200B40, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	// ---- VQRDMLAH / VQRDMLSH (ARMv8.1 FEAT_RDM, rounding doubling MAC) ----
	//   VQRDMLAH: 1111 0011 0 D size Vn Vd 1011 N Q M 1 Vm  (size = 01 .S16 or 10 .S32)
	//   VQRDMLSH: 1111 0011 0 D size Vn Vd 1100 N Q M 1 Vm
	.VQRDMLAH = {
		{.VQRDMLAH, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3100B10, 0xFFB00F10, .V8, .A32, {cond_in_28=false}},
		{.VQRDMLAH, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3200B10, 0xFFB00F10, .V8, .A32, {cond_in_28=false}},
		{.VQRDMLAH, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3100B50, 0xFFB00F50, .V8, .A32, {cond_in_28=false}},
		{.VQRDMLAH, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3200B50, 0xFFB00F50, .V8, .A32, {cond_in_28=false}},
	},
	.VQRDMLSH = {
		{.VQRDMLSH, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3100C10, 0xFFB00F10, .V8, .A32, {cond_in_28=false}},
		{.VQRDMLSH, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3200C10, 0xFFB00F10, .V8, .A32, {cond_in_28=false}},
		{.VQRDMLSH, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3100C50, 0xFFB00F50, .V8, .A32, {cond_in_28=false}},
		{.VQRDMLSH, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3200C50, 0xFFB00F50, .V8, .A32, {cond_in_28=false}},
	},
	// VQDMULL: 1111 0010 1 D size Vn Vd 1101 N 0 M 0 Vm
	.VQDMULL = {
		{.VQDMULL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2900D00, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQDMULL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2A00D00, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	// VQDMLAL / VQDMLSL (saturating doubling multiply-accumulate long)
	.VQDMLAL = {
		// signed: 1111 0010 1 D size Vn Vd 1001 N 0 M 0 Vm
		{.VQDMLAL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2900900, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQDMLAL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2A00900, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	.VQDMLSL = {
		// signed: 1111 0010 1 D size Vn Vd 1011 N 0 M 0 Vm
		{.VQDMLSL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2900B00, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQDMLSL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2A00B00, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},

	// ---- VMOVL / VMOVN / VQMOVN / VQMOVUN (widening/narrowing moves) ----
	.VMOVL = {
		// VMOVL.S<size> Q, D : 1111 0010 1 D imm3 0 0 0 Vd 1010 0 0 M 1 Vm   (imm3 = size)
		// We list signed/unsigned × 3 sizes (.S8/.S16/.S32 and .U variants)
		{.VMOVL, {.QPR, .DPR, .NONE, .NONE}, {.VD_Q, .VM_D, .NONE, .NONE}, 0xF2880A10, 0xFFB80FD0, .NEON, .A32, {cond_in_28=false}},  // .S8
		{.VMOVL, {.QPR, .DPR, .NONE, .NONE}, {.VD_Q, .VM_D, .NONE, .NONE}, 0xF2900A10, 0xFFB80FD0, .NEON, .A32, {cond_in_28=false}},  // .S16
		{.VMOVL, {.QPR, .DPR, .NONE, .NONE}, {.VD_Q, .VM_D, .NONE, .NONE}, 0xF2A00A10, 0xFFB80FD0, .NEON, .A32, {cond_in_28=false}},  // .S32
		{.VMOVL, {.QPR, .DPR, .NONE, .NONE}, {.VD_Q, .VM_D, .NONE, .NONE}, 0xF3880A10, 0xFFB80FD0, .NEON, .A32, {cond_in_28=false}},  // .U8
		{.VMOVL, {.QPR, .DPR, .NONE, .NONE}, {.VD_Q, .VM_D, .NONE, .NONE}, 0xF3900A10, 0xFFB80FD0, .NEON, .A32, {cond_in_28=false}},  // .U16
		{.VMOVL, {.QPR, .DPR, .NONE, .NONE}, {.VD_Q, .VM_D, .NONE, .NONE}, 0xF3A00A10, 0xFFB80FD0, .NEON, .A32, {cond_in_28=false}},  // .U32
	},
	.VMOVN = {
		// VMOVN.I<size> D, Q : 1111 0011 1 D 11 size 10 Vd 0010 0 0 M 0 Vm
		{.VMOVN, {.DPR, .QPR, .NONE, .NONE}, {.VD_D, .VM_Q, .NONE, .NONE}, 0xF3B20200, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},  // .I16
		{.VMOVN, {.DPR, .QPR, .NONE, .NONE}, {.VD_D, .VM_Q, .NONE, .NONE}, 0xF3B60200, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},  // .I32
		{.VMOVN, {.DPR, .QPR, .NONE, .NONE}, {.VD_D, .VM_Q, .NONE, .NONE}, 0xF3BA0200, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},  // .I64
	},
	.VQMOVN = {
		// VQMOVN.<sz> (signed saturating narrowing move)
		//   .S<size>: 1111 0011 1 D 11 size 10 Vd 0010 1 0 M 0 Vm
		//   .U<size>: same with op bit 6 = 1
		{.VQMOVN, {.DPR, .QPR, .NONE, .NONE}, {.VD_D, .VM_Q, .NONE, .NONE}, 0xF3B20280, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VQMOVN, {.DPR, .QPR, .NONE, .NONE}, {.VD_D, .VM_Q, .NONE, .NONE}, 0xF3B60280, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VQMOVN, {.DPR, .QPR, .NONE, .NONE}, {.VD_D, .VM_Q, .NONE, .NONE}, 0xF3BA0280, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VQMOVN, {.DPR, .QPR, .NONE, .NONE}, {.VD_D, .VM_Q, .NONE, .NONE}, 0xF3B202C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VQMOVN, {.DPR, .QPR, .NONE, .NONE}, {.VD_D, .VM_Q, .NONE, .NONE}, 0xF3B602C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VQMOVN, {.DPR, .QPR, .NONE, .NONE}, {.VD_D, .VM_Q, .NONE, .NONE}, 0xF3BA02C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
	},
	.VQMOVUN = {
		// VQMOVUN (signed input, unsigned saturating output): 1111 0011 1 D 11 size 10 Vd 0010 0 1 M 0 Vm  (bit 6=1, bit 7=0)
		{.VQMOVUN, {.DPR, .QPR, .NONE, .NONE}, {.VD_D, .VM_Q, .NONE, .NONE}, 0xF3B20240, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VQMOVUN, {.DPR, .QPR, .NONE, .NONE}, {.VD_D, .VM_Q, .NONE, .NONE}, 0xF3B60240, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VQMOVUN, {.DPR, .QPR, .NONE, .NONE}, {.VD_D, .VM_Q, .NONE, .NONE}, 0xF3BA0240, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
	},

	// ---- VSHLL / VSHRN / VRSHRN / VQSHRN / VQRSHRN ----
	.VSHLL = {
		// VSHLL.S<sz> Q, D, #imm: 1111 0010 1 D imm6 Vd 1010 0 0 M 1 Vm
		//   imm6 encodes sh + size: 001sss for sh<8, 01sss for sh<16, 1sss for sh<32
		{.VSHLL, {.QPR, .DPR, .IMM, .NONE}, {.VD_Q, .VM_D, .NEON_SHIFT_IMM6, .NONE}, 0xF2800A10, 0xFE800FD0, .NEON, .A32, {cond_in_28=false}},
		{.VSHLL, {.QPR, .DPR, .IMM, .NONE}, {.VD_Q, .VM_D, .NEON_SHIFT_IMM6, .NONE}, 0xF3800A10, 0xFE800FD0, .NEON, .A32, {cond_in_28=false}},  // U=1
		// VSHLL by max (#size) variant: 1111 0011 1 D 11 size 10 Vd 0011 0 0 M 0 Vm
		{.VSHLL, {.QPR, .DPR, .NONE, .NONE}, {.VD_Q, .VM_D, .NONE, .NONE}, 0xF3B20300, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VSHLL, {.QPR, .DPR, .NONE, .NONE}, {.VD_Q, .VM_D, .NONE, .NONE}, 0xF3B60300, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VSHLL, {.QPR, .DPR, .NONE, .NONE}, {.VD_Q, .VM_D, .NONE, .NONE}, 0xF3BA0300, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
	},
	.VSHRN = {
		// 1111 0010 1 D imm6 Vd 1000 0 0 M 1 Vm
		{.VSHRN, {.DPR, .QPR, .IMM, .NONE}, {.VD_D, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xF2800810, 0xFE800FD0, .NEON, .A32, {cond_in_28=false}},
	},
	.VRSHRN = {
		// 1111 0010 1 D imm6 Vd 1000 0 1 M 1 Vm
		{.VRSHRN, {.DPR, .QPR, .IMM, .NONE}, {.VD_D, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xF2800850, 0xFE800FD0, .NEON, .A32, {cond_in_28=false}},
	},
	.VQSHRN = {
		// signed: 1111 0010 1 D imm6 Vd 1001 0 0 M 1 Vm; unsigned: U=1
		{.VQSHRN, {.DPR, .QPR, .IMM, .NONE}, {.VD_D, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xF2800910, 0xFE800FD0, .NEON, .A32, {cond_in_28=false}},
		{.VQSHRN, {.DPR, .QPR, .IMM, .NONE}, {.VD_D, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xF3800910, 0xFE800FD0, .NEON, .A32, {cond_in_28=false}},
	},
	.VQRSHRN = {
		// 1111 0010 1 D imm6 Vd 1001 0 1 M 1 Vm
		{.VQRSHRN, {.DPR, .QPR, .IMM, .NONE}, {.VD_D, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xF2800950, 0xFE800FD0, .NEON, .A32, {cond_in_28=false}},
		{.VQRSHRN, {.DPR, .QPR, .IMM, .NONE}, {.VD_D, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xF3800950, 0xFE800FD0, .NEON, .A32, {cond_in_28=false}},
	},
	.VQSHRUN = {
		// signed input, unsigned saturating shift right narrow:
		// 1111 0011 1 D imm6 Vd 1000 0 0 M 1 Vm
		{.VQSHRUN, {.DPR, .QPR, .IMM, .NONE}, {.VD_D, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xF3800810, 0xFF800FD0, .NEON, .A32, {cond_in_28=false}},
	},
	.VQRSHRUN = {
		{.VQRSHRUN, {.DPR, .QPR, .IMM, .NONE}, {.VD_D, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xF3800850, 0xFF800FD0, .NEON, .A32, {cond_in_28=false}},
	},

	// ---- VPADDL / VPADAL (pairwise add long / accumulate) ----
	//   1111 0011 1 D 11 size 00 Vd 0010 op Q M 0 Vm  (op=0 add long, op=1 accumulate)
	.VPADDL = {
		// .S<size>:
		{.VPADDL, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B00200, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VPADDL, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B40200, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VPADDL, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B80200, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		// Q form
		{.VPADDL, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B00240, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		// .U<size> variants: bit 7 = 1
		{.VPADDL, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B00280, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VPADDL, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B002C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
	},
	.VPADAL = {
		// op4=0110 instead of 0010 (bit 8=1)
		{.VPADAL, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B00600, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VPADAL, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B00640, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		// unsigned
		{.VPADAL, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B00680, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VPADAL, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B006C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
	},

	// ---- VSWP (swap) ----
	//   1111 0011 1 D 11 size 10 Vd 0000 0 Q M 0 Vm
	.VSWP = {
		{.VSWP, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B20000, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VSWP, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B20040, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
	},

	// ---- VACGE / VACGT (FP absolute compare) ----
	.VACGE = {
		// 1111 0011 0 D 0 sz Vn Vd 1110 N Q M 1 Vm
		{.VACGE, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000E10, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VACGE, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3000E50, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	.VACGT = {
		// sz bit 21 = 1
		{.VACGT, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3200E10, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VACGT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3200E50, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},

	// NEON crypto (ARMv8 FEAT_AES / FEAT_SHA1 / FEAT_SHA256)
	//   AESE/AESD/AESMC/AESIMC: 1111 0011 1011 size 00 Vd 0011 op M 0 Vm  (op=0 AESE, 1 AESD; bit 7 selects MC)
	.AESE   = { {.AESE,   {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B00300, 0xFFB30FD0, .CRYPTO, .A32, {cond_in_28=false}} },
	.AESD   = { {.AESD,   {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B00340, 0xFFB30FD0, .CRYPTO, .A32, {cond_in_28=false}} },
	.AESMC  = { {.AESMC,  {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B00380, 0xFFB30FD0, .CRYPTO, .A32, {cond_in_28=false}} },
	.AESIMC = { {.AESIMC, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B003C0, 0xFFB30FD0, .CRYPTO, .A32, {cond_in_28=false}} },
	// SHA1 family
	.SHA1H   = { {.SHA1H,   {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B902C0, 0xFFBF0FD0, .CRYPTO, .A32, {cond_in_28=false}} },
	.SHA1SU1 = { {.SHA1SU1, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3BA0380, 0xFFBF0FD0, .CRYPTO, .A32, {cond_in_28=false}} },
	.SHA256SU0 = { {.SHA256SU0, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3BA03C0, 0xFFBF0FD0, .CRYPTO, .A32, {cond_in_28=false}} },
	.SHA1C   = { {.SHA1C,   {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2000C40, 0xFFB00F50, .CRYPTO, .A32, {cond_in_28=false}} },
	.SHA1P   = { {.SHA1P,   {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2100C40, 0xFFB00F50, .CRYPTO, .A32, {cond_in_28=false}} },
	.SHA1M   = { {.SHA1M,   {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2200C40, 0xFFB00F50, .CRYPTO, .A32, {cond_in_28=false}} },
	.SHA1SU0 = { {.SHA1SU0, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF2300C40, 0xFFB00F50, .CRYPTO, .A32, {cond_in_28=false}} },
	.SHA256H   = { {.SHA256H,   {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3000C40, 0xFFB00F50, .CRYPTO, .A32, {cond_in_28=false}} },
	.SHA256H2  = { {.SHA256H2,  {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3100C40, 0xFFB00F50, .CRYPTO, .A32, {cond_in_28=false}} },
	.SHA256SU1 = { {.SHA256SU1, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xF3200C40, 0xFFB00F50, .CRYPTO, .A32, {cond_in_28=false}} },

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
		{.LSL, {.GPR, .GPR, .IMM5, .NONE}, {.RD, .RM_A32, .A32_IMM_SHIFT, .NONE}, 0x01A00000, 0x0FFF0070, .BASE, .A32, {}},
		// A32: MOV reg with LSL Rs (RSR form)
		{.LSL, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RM_A32, .RS_A32, .NONE},          0x01A00010, 0x0FFF00F0, .BASE, .A32, {}},
		// T16 Format 1: LSL imm
		{.LSL, {.GPR_LOW, .GPR_LOW, .IMM5, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x00000000, 0x0000F800, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 4: LSL reg (Rd = Rd <<= Rs)
		{.LSL, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x00004080, 0x0000FFC0, .THUMB, .T32, {cond_in_28=false}},
		// T32 LSL imm (encoded as MOV with shift LSL): high=11101010 0100 1111  low=0 imm3 Rd imm2 00 Rm
		{.LSL, {.GPR, .GPR, .IMM5, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE}, 0xEA4F0000, 0xFFEF8030, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		// T32 LSL reg: high=11111010 0000 Rn  low=1111 Rd 0000 Rm
		{.LSL, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFA00F000, 0xFFE0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.LSR = {
		{.LSR, {.GPR, .GPR, .IMM5, .NONE}, {.RD, .RM_A32, .A32_IMM_SHIFT, .NONE}, 0x01A00020, 0x0FFF0070, .BASE, .A32, {}},
		{.LSR, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RM_A32, .RS_A32, .NONE},          0x01A00030, 0x0FFF00F0, .BASE, .A32, {}},
		// T16 Format 1: LSR imm
		{.LSR, {.GPR_LOW, .GPR_LOW, .IMM5, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x00000800, 0x0000F800, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 4: LSR reg
		{.LSR, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x000040C0, 0x0000FFC0, .THUMB, .T32, {cond_in_28=false}},
		// T32 LSR imm (MOV with shift LSR): bits 5:4 = 01
		{.LSR, {.GPR, .GPR, .IMM5, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE}, 0xEA4F0010, 0xFFEF8030, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		// T32 LSR reg: 0xFA20F000
		{.LSR, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFA20F000, 0xFFE0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.ASR = {
		{.ASR, {.GPR, .GPR, .IMM5, .NONE}, {.RD, .RM_A32, .A32_IMM_SHIFT, .NONE}, 0x01A00040, 0x0FFF0070, .BASE, .A32, {}},
		{.ASR, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RM_A32, .RS_A32, .NONE},          0x01A00050, 0x0FFF00F0, .BASE, .A32, {}},
		// T16 Format 1: ASR imm
		{.ASR, {.GPR_LOW, .GPR_LOW, .IMM5, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x00001000, 0x0000F800, .THUMB, .T32, {cond_in_28=false}},
		// T16 Format 4: ASR reg
		{.ASR, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x00004100, 0x0000FFC0, .THUMB, .T32, {cond_in_28=false}},
		// T32 ASR imm: bits 5:4 = 10
		{.ASR, {.GPR, .GPR, .IMM5, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE}, 0xEA4F0020, 0xFFEF8030, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		// T32 ASR reg: 0xFA40F000
		{.ASR, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFA40F000, 0xFFE0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.ROR = {
		{.ROR, {.GPR, .GPR, .IMM5, .NONE}, {.RD, .RM_A32, .A32_IMM_SHIFT, .NONE}, 0x01A00060, 0x0FFF0070, .BASE, .A32, {}},
		{.ROR, {.GPR, .GPR, .GPR, .NONE}, {.RD, .RM_A32, .RS_A32, .NONE},          0x01A00070, 0x0FFF00F0, .BASE, .A32, {}},
		// T16 Format 4: ROR reg
		{.ROR, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x000041C0, 0x0000FFC0, .THUMB, .T32, {cond_in_28=false}},
		// T32 ROR imm: bits 5:4 = 11
		{.ROR, {.GPR, .GPR, .IMM5, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE}, 0xEA4F0030, 0xFFEF8030, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
		// T32 ROR reg: 0xFA60F000
		{.ROR, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFA60F000, 0xFFE0F0F0, .V6T2, .T32, {thumb32=true, cond_in_28=false}},
	},
	.RRX = {
		// RRX is ROR with imm=0 (cond 00011010 0000 Rd 00000110 Rm)
		{.RRX, {.GPR, .GPR, .NONE, .NONE}, {.RD, .RM_A32, .NONE, .NONE}, 0x01A00060, 0x0FFF0FF0, .BASE, .A32, {}},
	},

	// T16 Format 12: ADR (ADD Rd, PC, #imm8 << 2)
	.ADR = {
		// A32 ADR forms (ADD/SUB to PC); handled via ADD encoded with Rn=PC.
		// T16 Format 12 form (10100 Rd imm8):
		{.ADR, {.GPR_LOW, .REL8, .NONE, .NONE}, {.RD_T16_HI, .NONE, .NONE, .NONE}, 0x0000A000, 0x0000F800, .THUMB, .T32, {cond_in_28=false}},
	},

	// T16 NEG Rd, Rm = RSB Rd, Rm, #0 (Format 4, op=1001)
	.NEG = {
		{.NEG, {.GPR_LOW, .GPR_LOW, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE}, 0x00004240, 0x0000FFC0, .THUMB, .T32, {cond_in_28=false}},
	},

	.CBZ  = { {.CBZ,  {.GPR_LOW, .REL8, .NONE, .NONE}, {.RD_T16_LO, .BRANCH_CBZ, .NONE, .NONE}, 0x0000B100, 0x0000FD00, .V6T2, .T32, {branch=true, cond_branch=true, writes_pc=true, cond_in_28=false}} },
	.CBNZ = { {.CBNZ, {.GPR_LOW, .REL8, .NONE, .NONE}, {.RD_T16_LO, .BRANCH_CBZ, .NONE, .NONE}, 0x0000B900, 0x0000FD00, .V6T2, .T32, {branch=true, cond_branch=true, writes_pc=true, cond_in_28=false}} },
	.IT   = { {.IT,   {.COND, .IMM4, .NONE, .NONE}, {.NONE, .IT_MASK, .NONE, .NONE}, 0x0000BF00, 0x0000FF00, .V6T2, .T32, {cond_in_28=false}} },
	.TBB  = { {.TBB,  {.GPR, .GPR, .NONE, .NONE}, {.RN_T32, .RM_T32, .NONE, .NONE}, 0xE8D0F000, 0xFFF0FFF0, .V6T2, .T32, {branch=true, writes_pc=true, thumb32=true, cond_in_28=false}} },
	.TBH  = { {.TBH,  {.GPR, .GPR, .NONE, .NONE}, {.RN_T32, .RM_T32, .NONE, .NONE}, 0xE8D0F010, 0xFFF0FFF0, .V6T2, .T32, {branch=true, writes_pc=true, thumb32=true, cond_in_28=false}} },

	// =========================================================================
	// §14 -- Extensions: Dot product / FCMA / FHM / BF16
	// =========================================================================

	// FEAT_DotProd (ARMv8.2-A): VSDOT/VUDOT (8-bit signed/unsigned dot product)
	.VSDOT = {
		// VSDOT.S8 D: 0xFC200D00
		{.VSDOT, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xFC200D00, 0xFFB00F10, .DOT, .A32, {cond_in_28=false}},
		{.VSDOT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xFC200D40, 0xFFB00F50, .DOT, .A32, {cond_in_28=false}},
	},
	// VUDOT (unsigned): bit 4 = 1 distinguishes from VSDOT (bit 4 = 0).
	//   vudot.u8 d0,d1,d2 = 0xFC21_0D12 -> base 0xFC200D10
	.VUDOT = {
		{.VUDOT, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xFC200D10, 0xFFB00F10, .DOT, .A32, {cond_in_28=false}},
		{.VUDOT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xFC200D50, 0xFFB00F50, .DOT, .A32, {cond_in_28=false}},
	},
	.VSDOT_LANE = {
		{.VSDOT_LANE, {.DPR, .DPR, .DPR_ELEM, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xFE200D00, 0xFFB00F10, .DOT, .A32, {cond_in_28=false}},
		{.VSDOT_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xFE200D40, 0xFFB00F50, .DOT, .A32, {cond_in_28=false}},
	},
	.VUDOT_LANE = {
		// vudot.u8 d0,d1,d2[0] = 0xFE21_0D12 -> base 0xFE200D10 (bit 4 = 1 for U)
		{.VUDOT_LANE, {.DPR, .DPR, .DPR_ELEM, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xFE200D10, 0xFFB00F10, .DOT, .A32, {cond_in_28=false}},
		{.VUDOT_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xFE200D50, 0xFFB00F50, .DOT, .A32, {cond_in_28=false}},
	},

	// FEAT_FCMA (ARMv8.3): VCMLA / VCADD (complex multiply-add + add)
	// VCMLA: rotation in bits 24:23 (4 values: 0, 90, 180, 270 deg)
	// VCADD: rotation in bit 24 only (2 values: 90, 270 deg)
	.VCMLA = {
		// Mask 0xFC800F10 leaves bits 24:23 variable for rotation operand
		{.VCMLA, {.DPR, .DPR, .DPR, .IMM}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xFC200800, 0xFC800F10, .FCMA, .A32, {cond_in_28=false}},
		{.VCMLA, {.QPR, .QPR, .QPR, .IMM}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xFC200840, 0xFC800F50, .FCMA, .A32, {cond_in_28=false}},
	},
	.VCADD = {
		// Mask 0xFE800F10 leaves bit 24 variable for rotation operand (90 or 270)
		{.VCADD, {.DPR, .DPR, .DPR, .IMM}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xFC800800, 0xFE800F10, .FCMA, .A32, {cond_in_28=false}},
		{.VCADD, {.QPR, .QPR, .QPR, .IMM}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xFC800840, 0xFE800F50, .FCMA, .A32, {cond_in_28=false}},
	},

	// FEAT_FHM (ARMv8.2): FP16 fused multiply-add long
	.VFMAL = {
		{.VFMAL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xFC200810, 0xFFB00F10, .FHM, .A32, {cond_in_28=false}},
		{.VFMAL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xFC200850, 0xFFB00F50, .FHM, .A32, {cond_in_28=false}},
	},
	.VFMSL = {
		{.VFMSL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xFCA00810, 0xFFB00F10, .FHM, .A32, {cond_in_28=false}},
		{.VFMSL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xFCA00850, 0xFFB00F50, .FHM, .A32, {cond_in_28=false}},
	},

	// FEAT_BF16 (ARMv8.6): BFloat16 arithmetic and conversion
	.VCVT_BF16 = {
		// VCVT.BF16.F32 D, Q
		// vcvt.bf16.f32 d0, q1 = 0xF3B6_0642 -> base 0xF3B60600
		{.VCVT_BF16, {.DPR, .QPR, .NONE, .NONE}, {.VD_D, .VM_Q, .NONE, .NONE}, 0xF3B60600, 0xFFBF0FD0, .BF16, .A32, {cond_in_28=false}},
	},
	.VDOT_BF16 = {
		// VDOT.BF16 D, D, D
		{.VDOT_BF16, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xFC000D00, 0xFFB00F10, .BF16, .A32, {cond_in_28=false}},
		{.VDOT_BF16, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xFC000D40, 0xFFB00F50, .BF16, .A32, {cond_in_28=false}},
	},
	.VFMA_BF16 = {
		{.VFMA_BF16, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xFC300850, 0xFFB00F50, .BF16, .A32, {cond_in_28=false}},
	},
	.VMMLA_BF16 = {
		{.VMMLA_BF16, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xFC000C40, 0xFFB00F50, .BF16, .A32, {cond_in_28=false}},
	},

	// =========================================================================
	// FEAT_I8MM (ARMv8.6) -- integer matrix multiply + mixed-sign dot product
	// =========================================================================
	// VSMMLA Qd, Qn, Qm:  1111 1100 0 D 1 0 Vn Vd 1100 N 1 M 0 Vm   (signed)
	// VUMMLA Qd, Qn, Qm:  1111 1100 0 D 1 0 Vn Vd 1100 N 1 M 1 Vm   (unsigned)
	// VUSMMLA Qd, Qn, Qm: 1111 1100 1 D 1 0 Vn Vd 1100 N 1 M 0 Vm   (mixed)
	.VSMMLA = {
		{.VSMMLA, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xFC200C40, 0xFFB00F50, .V8, .A32, {cond_in_28=false}},
	},
	.VUMMLA = {
		{.VUMMLA, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xFC200C50, 0xFFB00F50, .V8, .A32, {cond_in_28=false}},
	},
	.VUSMMLA = {
		{.VUSMMLA, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xFCA00C40, 0xFFB00F50, .V8, .A32, {cond_in_28=false}},
	},
	// VSUDOT Qd, Qn, Qm[idx]:  1111 1110 1 D 00 Vn Vd 1101 N Q M 1 Vm
	// VUSDOT Qd, Qn, Qm:       1111 1100 0 D 10 Vn Vd 1101 N Q M 0 Vm
	// VSUDOT/VUSDOT (FEAT_I8MM): mixed signed/unsigned dot product.
	//   vusdot.s8 d0,d1,d2 = 0xFCA1_0D02 -> base 0xFCA00D00
	//   vsudot.u8 q0,q1,d2[0] = 0xFE82_0D52 -> base 0xFE800D50 (lane only)
	.VSUDOT = {
		{.VSUDOT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xFCA00D50, 0xFFB00F50, .V8, .A32, {cond_in_28=false}},
	},
	.VUSDOT = {
		{.VUSDOT, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xFCA00D00, 0xFFB00F10, .V8, .A32, {cond_in_28=false}},
		{.VUSDOT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xFCA00D40, 0xFFB00F50, .V8, .A32, {cond_in_28=false}},
	},
	.VSUDOT_LANE = {
		{.VSUDOT_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xFE800D50, 0xFFB00F50, .V8, .A32, {cond_in_28=false}},
	},
	.VUSDOT_LANE = {
		{.VUSDOT_LANE, {.DPR, .DPR, .DPR_ELEM, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xFE800D00, 0xFFB00F10, .V8, .A32, {cond_in_28=false}},
		{.VUSDOT_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xFE800D40, 0xFFB00F50, .V8, .A32, {cond_in_28=false}},
	},

	// =========================================================================
	// NEON lane-indexed multiply / MAC forms (heavily used in DSP/codec/BLAS)
	// =========================================================================
	// All have the shape: 1111 0010 1 D size Vn Vd opcode N Q M 0 Vm
	// where size in {01, 10} for I16/I32, opcode selects MUL/MLA/MLS/MULL/...,
	// and Vm encodes reg + lane index.

	// VMUL by scalar: opcode bits[11:8] = 1000; Q bit at bit 24 (0=D, 1=Q);
	// size bits 21:20; F bit at bit 7 (0=integer, 1=FP F32)
	.VMUL_LANE = {
		// Integer D-form .I16/.I32
		{.VMUL_LANE, {.DPR, .DPR, .DPR_ELEM, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2900840, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMUL_LANE, {.DPR, .DPR, .DPR_ELEM, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2A00840, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// Integer Q-form .I16/.I32 (bit 24 = 1)
		{.VMUL_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF3900840, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMUL_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF3A00840, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// FP .F32 D-form / Q-form (F=1, size=10)
		{.VMUL_LANE, {.DPR, .DPR, .DPR_ELEM, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2A008C0, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMUL_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF3A008C0, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	// VMLA by scalar: opcode bits[11:8] = 0000
	.VMLA_LANE = {
		{.VMLA_LANE, {.DPR, .DPR, .DPR_ELEM, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2900040, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLA_LANE, {.DPR, .DPR, .DPR_ELEM, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2A00040, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLA_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF3900040, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLA_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF3A00040, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// FP .F32 (F=1)
		{.VMLA_LANE, {.DPR, .DPR, .DPR_ELEM, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2A000C0, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLA_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF3A000C0, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	// VMLS by scalar: opcode bits[11:8] = 0100
	.VMLS_LANE = {
		{.VMLS_LANE, {.DPR, .DPR, .DPR_ELEM, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2900440, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLS_LANE, {.DPR, .DPR, .DPR_ELEM, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2A00440, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLS_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF3900440, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLS_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF3A00440, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// FP .F32
		{.VMLS_LANE, {.DPR, .DPR, .DPR_ELEM, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2A004C0, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLS_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF3A004C0, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	// VMULL by scalar: opcode bits[11:8] = 1010. Long: Q dest from D inputs.
	.VMULL_LANE = {
		// signed .S16/.S32
		{.VMULL_LANE, {.QPR, .DPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2900A40, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMULL_LANE, {.QPR, .DPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2A00A40, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		// unsigned .U16/.U32 (top byte 0xF3)
		{.VMULL_LANE, {.QPR, .DPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3900A40, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMULL_LANE, {.QPR, .DPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3A00A40, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	// VMLAL by scalar: opcode bits[11:8] = 0010
	.VMLAL_LANE = {
		{.VMLAL_LANE, {.QPR, .DPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2900240, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLAL_LANE, {.QPR, .DPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2A00240, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLAL_LANE, {.QPR, .DPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3900240, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLAL_LANE, {.QPR, .DPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3A00240, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	// VMLSL by scalar: opcode bits[11:8] = 0110
	.VMLSL_LANE = {
		{.VMLSL_LANE, {.QPR, .DPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2900640, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLSL_LANE, {.QPR, .DPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2A00640, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLSL_LANE, {.QPR, .DPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3900640, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VMLSL_LANE, {.QPR, .DPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3A00640, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	// VQDMULL by scalar: opcode bits[11:8] = 1011 (signed only)
	.VQDMULL_LANE = {
		{.VQDMULL_LANE, {.QPR, .DPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2900B40, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQDMULL_LANE, {.QPR, .DPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2A00B40, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	// VQDMLAL by scalar: opcode bits[11:8] = 0011
	.VQDMLAL_LANE = {
		{.VQDMLAL_LANE, {.QPR, .DPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2900340, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQDMLAL_LANE, {.QPR, .DPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2A00340, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	// VQDMLSL by scalar: opcode bits[11:8] = 0111
	.VQDMLSL_LANE = {
		{.VQDMLSL_LANE, {.QPR, .DPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2900740, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQDMLSL_LANE, {.QPR, .DPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2A00740, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
	},
	// VFMA / VFMS by scalar -- FEAT_FCMA adds these as opcode 0001 / 0101 with F=1
	.VFMA_LANE = {
		{.VFMA_LANE, {.DPR, .DPR, .DPR_ELEM, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2A000C0, 0xFFB00F50, .VFPV4, .A32, {cond_in_28=false}},
		{.VFMA_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF3A000C0, 0xFFB00F50, .VFPV4, .A32, {cond_in_28=false}},
	},
	.VFMS_LANE = {
		{.VFMS_LANE, {.DPR, .DPR, .DPR_ELEM, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2A004C0, 0xFFB00F50, .VFPV4, .A32, {cond_in_28=false}},
		{.VFMS_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF3A004C0, 0xFFB00F50, .VFPV4, .A32, {cond_in_28=false}},
	},
	// VQRDMLAH / VQRDMLSH by scalar (FEAT_RDM): opcode 1110 / 1111, bit 4 = 1
	.VQRDMLAH_LANE = {
		{.VQRDMLAH_LANE, {.DPR, .DPR, .DPR_ELEM, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2900E40, 0xFFB00F50, .V8, .A32, {cond_in_28=false}},
		{.VQRDMLAH_LANE, {.DPR, .DPR, .DPR_ELEM, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2A00E40, 0xFFB00F50, .V8, .A32, {cond_in_28=false}},
		{.VQRDMLAH_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF3900E40, 0xFFB00F50, .V8, .A32, {cond_in_28=false}},
		{.VQRDMLAH_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF3A00E40, 0xFFB00F50, .V8, .A32, {cond_in_28=false}},
	},
	.VQRDMLSH_LANE = {
		{.VQRDMLSH_LANE, {.DPR, .DPR, .DPR_ELEM, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2900F40, 0xFFB00F50, .V8, .A32, {cond_in_28=false}},
		{.VQRDMLSH_LANE, {.DPR, .DPR, .DPR_ELEM, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF2A00F40, 0xFFB00F50, .V8, .A32, {cond_in_28=false}},
		{.VQRDMLSH_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF3900F40, 0xFFB00F50, .V8, .A32, {cond_in_28=false}},
		{.VQRDMLSH_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF3A00F40, 0xFFB00F50, .V8, .A32, {cond_in_28=false}},
	},
	// VCMLA by indexed scalar (FEAT_FCMA)
	.VCMLA_LANE = {
		{.VCMLA_LANE, {.DPR, .DPR, .DPR_ELEM, .IMM}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xFE000800, 0xFFB00F10, .FCMA, .A32, {cond_in_28=false}},
		{.VCMLA_LANE, {.QPR, .QPR, .DPR_ELEM, .IMM}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xFE000840, 0xFFB00F50, .FCMA, .A32, {cond_in_28=false}},
	},

	// =========================================================================
	// MVE polish (gaps from earlier pass)
	// =========================================================================
	// VQABS Qd, Qm:  1111 1111 1 D 11 size 00 Vd 0111 1 1 M 0 Vm
	// VQNEG Qd, Qm:  1111 1111 1 D 11 size 00 Vd 0111 1 1 M 1 Vm
	.VQABS = {
		{.VQABS, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xFFB00740, 0xFFB30FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VQNEG = {
		{.VQNEG, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xFFB007C0, 0xFFB30FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},

	// VMOVX Sd, Sm  (extract high F16 lane to bottom of Sd) -- ARMv8.2 FP16
	//   1111 1110 1 D 11 0000 Vd 1010 01 M 0 Vm
	.VMOVX = {
		{.VMOVX, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0xFEB00A40, 0xFFBF0FD0, .HALF_FP, .T32, {thumb32=true, cond_in_28=false}},
	},
	// VINS Sd, Sm  (insert F16 from Sm into high half of Sd)
	//   1111 1110 1 D 11 0000 Vd 1010 11 M 0 Vm
	.VINS = {
		{.VINS, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0xFEB00AC0, 0xFFBF0FD0, .HALF_FP, .T32, {thumb32=true, cond_in_28=false}},
	},

	// ---- MVE gather/scatter (vector offset addressing) ----------------------
	// Encoding: 1111 1100 1 D L size 1 Qm Qd 1110 sz1 Q M sz0 Rn (where Qm is the vector offset)
	// MVE gather/scatter (LLVM-verified, bit 23 = 1, sizes in bits 21:20):
	//   vldrb.u8  q,[r,q] = 0xFC92_2E06 -> base 0xFC900E00
	//   vldrh.u16 q,[r,q] = 0xFC92_2E96 -> base 0xFC900E90
	//   vldrw.u32 q,[r,q] = 0xFC92_2F46 -> base 0xFC900F40
	//   vldrd.u64 q,[r,q] = 0xFC92_2FD6 -> base 0xFC900FD0
	.VLDRB_GATHER = {
		{.VLDRB_GATHER, {.QPR, .MEM, .QPR, .NONE}, {.VD_Q, .RN_T32, .VM_Q, .NONE}, 0xFC900E00, 0xFEF00FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VLDRH_GATHER = {
		{.VLDRH_GATHER, {.QPR, .MEM, .QPR, .NONE}, {.VD_Q, .RN_T32, .VM_Q, .NONE}, 0xFC900E90, 0xFEF00FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VLDRW_GATHER = {
		{.VLDRW_GATHER, {.QPR, .MEM, .QPR, .NONE}, {.VD_Q, .RN_T32, .VM_Q, .NONE}, 0xFC900F40, 0xFEF00FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VLDRD_GATHER = {
		{.VLDRD_GATHER, {.QPR, .MEM, .QPR, .NONE}, {.VD_Q, .RN_T32, .VM_Q, .NONE}, 0xFC900FD0, 0xFEF00FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// VSTR scatter (LLVM-verified): top byte 0xEC (vs 0xFC for VLDR gather).
	//   vstrb.8 q1,[r2,q3] = 0xEC82_2E06 -> base 0xEC600E00
	.VSTRB_SCATTER = {
		{.VSTRB_SCATTER, {.QPR, .MEM, .QPR, .NONE}, {.VD_Q, .RN_T32, .VM_Q, .NONE}, 0xEC600E00, 0xFEF00FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VSTRH_SCATTER = {
		{.VSTRH_SCATTER, {.QPR, .MEM, .QPR, .NONE}, {.VD_Q, .RN_T32, .VM_Q, .NONE}, 0xEC600E90, 0xFEF00FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VSTRW_SCATTER = {
		{.VSTRW_SCATTER, {.QPR, .MEM, .QPR, .NONE}, {.VD_Q, .RN_T32, .VM_Q, .NONE}, 0xEC600F40, 0xFEF00FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VSTRD_SCATTER = {
		{.VSTRD_SCATTER, {.QPR, .MEM, .QPR, .NONE}, {.VD_Q, .RN_T32, .VM_Q, .NONE}, 0xEC600FD0, 0xFEF00FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},

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
	.VCVT_FIXED = {
		// VCVT.S32.F32 Sd, Sd, #fbits  -- to signed 32-bit fixed-point
		{.VCVT_FIXED, {.SPR, .SPR, .IMM, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EBE0A40, 0x0FBF0FD0, .VFPV3, .A32, {}},
		// VCVT.U32.F32 Sd, Sd, #fbits
		{.VCVT_FIXED, {.SPR, .SPR, .IMM, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EBF0A40, 0x0FBF0FD0, .VFPV3, .A32, {}},
		// VCVT.F32.S32 Sd, Sd, #fbits  -- from signed 32-bit fixed
		{.VCVT_FIXED, {.SPR, .SPR, .IMM, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EBA0A40, 0x0FBF0FD0, .VFPV3, .A32, {}},
		// VCVT.F32.U32 Sd, Sd, #fbits
		{.VCVT_FIXED, {.SPR, .SPR, .IMM, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EBB0A40, 0x0FBF0FD0, .VFPV3, .A32, {}},
		// VCVT.S16.F32 Sd, Sd, #fbits (sx=0 selects 16-bit fixed-point)
		{.VCVT_FIXED, {.SPR, .SPR, .IMM, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EBE0A40, 0x0FBF0FC0, .VFPV3, .A32, {}},
		// VCVT.F32.S16 Sd, Sd, #fbits
		{.VCVT_FIXED, {.SPR, .SPR, .IMM, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EBA0A40, 0x0FBF0FC0, .VFPV3, .A32, {}},
		// F64 variants (sz=1): change cp to 1011 (bit 8 = 1)
		{.VCVT_FIXED, {.DPR, .DPR, .IMM, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0x0EBE0B40, 0x0FBF0FD0, .VFPV3, .A32, {}},
		{.VCVT_FIXED, {.DPR, .DPR, .IMM, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0x0EBA0B40, 0x0FBF0FD0, .VFPV3, .A32, {}},
		// F16 variants (cp=1001, FEAT_FP16)
		{.VCVT_FIXED, {.SPR, .SPR, .IMM, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EBE0940, 0x0FBF0FD0, .HALF_FP, .A32, {}},
		{.VCVT_FIXED, {.SPR, .SPR, .IMM, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EBA0940, 0x0FBF0FD0, .HALF_FP, .A32, {}},
	},

	// =========================================================================
	// NEON compare-with-zero (single-operand, distinct encoding from reg form)
	// =========================================================================
	// 1111 0011 1011 size 01 Vd op 0 0 0 Q M 0 Vm  (integer)
	// 1111 0011 1011 size 10 Vd op 0 0 1 Q M 0 Vm  (float; op selects EQ/GE/GT/LE/LT)
	.VCEQ_Z = {
		// Integer: 0xF3B10100 base for .I8, opc=000
		{.VCEQ_Z, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B10100, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCEQ_Z, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B10140, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		// Float: 0xF3B90500 base (.F32, opc=010)
		{.VCEQ_Z, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B90500, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCEQ_Z, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B90540, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
	},
	.VCGE_Z = {
		{.VCGE_Z, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B10080, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCGE_Z, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B100C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCGE_Z, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B90480, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCGE_Z, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B904C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
	},
	.VCGT_Z = {
		{.VCGT_Z, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B10000, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCGT_Z, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B10040, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCGT_Z, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B90400, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCGT_Z, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B90440, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
	},
	.VCLE_Z = {
		{.VCLE_Z, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B10180, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCLE_Z, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B101C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCLE_Z, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B90580, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCLE_Z, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B905C0, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
	},
	.VCLT_Z = {
		{.VCLT_Z, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B10200, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCLT_Z, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B10240, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCLT_Z, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3B90600, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
		{.VCLT_Z, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3B90640, 0xFFB30FD0, .NEON, .A32, {cond_in_28=false}},
	},

	// =========================================================================
	// NEON replicate loads (broadcast single element to all lanes)
	// =========================================================================
	// 1111 0100 1 D 10 Rn Vd 11 N size T a Rm
	//   N=00 VLD1R, 01 VLD2R, 10 VLD3R, 11 VLD4R
	// VLD{2,3,4}R replicate forms (LLVM-verified for .8 element size):
	//   vld2.8 {d1[], d2[]}, [r2] = 0xF4A2_1D0F -> base 0xF4A0_0D0F
	//   vld3.8 {d1[], d2[], d3[]}, [r2] = 0xF4A2_1E0F -> base 0xF4A0_0E0F
	//   vld4.8 {d1[], d2[], d3[], d4[]}, [r2] = 0xF4A2_1F0F -> base 0xF4A0_0F0F
	.VLD2R = {
		{.VLD2R, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4A00D0F, 0xFFB00F0F, .NEON, .A32, {cond_in_28=false}},
	},
	.VLD3R = {
		{.VLD3R, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4A00E0F, 0xFFB00F0F, .NEON, .A32, {cond_in_28=false}},
	},
	.VLD4R = {
		{.VLD4R, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4A00F0F, 0xFFB00F0F, .NEON, .A32, {cond_in_28=false}},
	},

	// =========================================================================
	// NEON single-element-lane load/store (one element, with lane index)
	// =========================================================================
	// 1111 0100 1 D 10 Rn Vd size{2} N index_align Rm
	//   N=00 VLDx1, 01 VLDx2, 10 VLDx3, 11 VLDx4   (x = 1..4)
	// VLD1_LANE Dd[i], [Rn]:   size=00 (.8) 0xF4A00000, size=01 (.16) 0xF4A00400, size=10 (.32) 0xF4A00800
	.VLD1_LANE = {
		{.VLD1_LANE, {.DPR_ELEM, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4A00000, 0xFFB00C00, .NEON, .A32, {cond_in_28=false}},
		{.VLD1_LANE, {.DPR_ELEM, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4A00400, 0xFFB00C00, .NEON, .A32, {cond_in_28=false}},
		{.VLD1_LANE, {.DPR_ELEM, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4A00800, 0xFFB00C00, .NEON, .A32, {cond_in_28=false}},
	},
	.VLD2_LANE = {
		{.VLD2_LANE, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4A00100, 0xFFB00D00, .NEON, .A32, {cond_in_28=false}},
		{.VLD2_LANE, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4A00500, 0xFFB00D00, .NEON, .A32, {cond_in_28=false}},
		{.VLD2_LANE, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4A00900, 0xFFB00D00, .NEON, .A32, {cond_in_28=false}},
	},
	.VLD3_LANE = {
		{.VLD3_LANE, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4A00200, 0xFFB00D00, .NEON, .A32, {cond_in_28=false}},
		{.VLD3_LANE, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4A00600, 0xFFB00D00, .NEON, .A32, {cond_in_28=false}},
		{.VLD3_LANE, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4A00A00, 0xFFB00D00, .NEON, .A32, {cond_in_28=false}},
	},
	.VLD4_LANE = {
		{.VLD4_LANE, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4A00300, 0xFFB00D00, .NEON, .A32, {cond_in_28=false}},
		{.VLD4_LANE, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4A00700, 0xFFB00D00, .NEON, .A32, {cond_in_28=false}},
		{.VLD4_LANE, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4A00B00, 0xFFB00D00, .NEON, .A32, {cond_in_28=false}},
	},
	// VST1/2/3/4 single-lane: bit 21 = 0 (store, not load)
	.VST1_LANE = {
		{.VST1_LANE, {.DPR_ELEM, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4800000, 0xFFB00C00, .NEON, .A32, {cond_in_28=false}},
		{.VST1_LANE, {.DPR_ELEM, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4800400, 0xFFB00C00, .NEON, .A32, {cond_in_28=false}},
		{.VST1_LANE, {.DPR_ELEM, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4800800, 0xFFB00C00, .NEON, .A32, {cond_in_28=false}},
	},
	.VST2_LANE = {
		{.VST2_LANE, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4800100, 0xFFB00D00, .NEON, .A32, {cond_in_28=false}},
		{.VST2_LANE, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4800500, 0xFFB00D00, .NEON, .A32, {cond_in_28=false}},
		{.VST2_LANE, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4800900, 0xFFB00D00, .NEON, .A32, {cond_in_28=false}},
	},
	.VST3_LANE = {
		{.VST3_LANE, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4800200, 0xFFB00D00, .NEON, .A32, {cond_in_28=false}},
		{.VST3_LANE, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4800600, 0xFFB00D00, .NEON, .A32, {cond_in_28=false}},
		{.VST3_LANE, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4800A00, 0xFFB00D00, .NEON, .A32, {cond_in_28=false}},
	},
	.VST4_LANE = {
		{.VST4_LANE, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4800300, 0xFFB00D00, .NEON, .A32, {cond_in_28=false}},
		{.VST4_LANE, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4800700, 0xFFB00D00, .NEON, .A32, {cond_in_28=false}},
		{.VST4_LANE, {.DPR_LIST, .MEM, .NONE, .NONE}, {.VD_D, .RN_A32, .NONE, .NONE}, 0xF4800B00, 0xFFB00D00, .NEON, .A32, {cond_in_28=false}},
	},

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
		{.TT, {.GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RN_T32, .NONE, .NONE}, 0xE840F000, 0xFFF0F0C0, .V8M_SE, .T32, {thumb32=true, cond_in_28=false}},
	},
	.TTT = {
		{.TTT, {.GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RN_T32, .NONE, .NONE}, 0xE840F040, 0xFFF0F0C0, .V8M_SE, .T32, {thumb32=true, cond_in_28=false}},
	},
	.TTA = {
		{.TTA, {.GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RN_T32, .NONE, .NONE}, 0xE840F080, 0xFFF0F0C0, .V8M_SE, .T32, {thumb32=true, cond_in_28=false}},
	},
	.TTAT = {
		{.TTAT, {.GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RN_T32, .NONE, .NONE}, 0xE840F0C0, 0xFFF0F0C0, .V8M_SE, .T32, {thumb32=true, cond_in_28=false}},
	},
	// SG: Secure Gateway -- 32-bit T32 instruction that looks like two NOPs
	//   bits = 0xE97F E97F
	.SG = {
		{.SG, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xE97FE97F, 0xFFFFFFFF, .V8M_SE, .T32, {thumb32=true, cond_in_28=false}},
	},
	// BXNS Rm: T16 16-bit, 0100 0111 0 Rm[3:0] 100 = 0x4704 base, bit 2 = 1
	.BXNS = {
		{.BXNS, {.GPR, .NONE, .NONE, .NONE}, {.RM_T16_HI, .NONE, .NONE, .NONE}, 0x00004704, 0x0000FF87, .V8M_SE, .T32, {cond_in_28=false, branch=true}},
	},
	// BLXNS Rm: T16, 0100 0111 1 Rm[3:0] 100 = 0x4784 base
	.BLXNS = {
		{.BLXNS, {.GPR, .NONE, .NONE, .NONE}, {.RM_T16_HI, .NONE, .NONE, .NONE}, 0x00004784, 0x0000FF87, .V8M_SE, .T32, {cond_in_28=false, branch=true}},
	},

	// =========================================================================
	// PACBTI for ARMv8.1-M (Cortex-M85) -- pointer auth + branch target ID
	// =========================================================================
	// PAC R12, LR, SP:    T32 hint-class encoding 0xF3AF801D
	// PACBTI R12, LR, SP: combined PAC + BTI = 0xF3AF800D
	// AUT R12, LR, SP:    0xF3AF802D
	// AUTG Rd, Rn, Rm:    more general form using FB50F000 base
	// BTI:                HINT #15 = 0xF3AF80F0
	.PAC = {
		{.PAC, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF3AF801D, 0xFFFFFFFF, .V81M, .T32, {thumb32=true, cond_in_28=false}},
	},
	.PACBTI = {
		{.PACBTI, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF3AF800D, 0xFFFFFFFF, .V81M, .T32, {thumb32=true, cond_in_28=false}},
	},
	.AUT = {
		{.AUT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF3AF802D, 0xFFFFFFFF, .V81M, .T32, {thumb32=true, cond_in_28=false}},
	},
	.AUTG = {
		// AUTG Rd, Rn, Rm: 1111 1011 0101 Rn 1111 Rd 0000 Rm
		{.AUTG, {.GPR, .GPR, .GPR, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE}, 0xFB50F000, 0xFFF0F0F0, .V81M, .T32, {thumb32=true, cond_in_28=false}},
	},
	.BTI = {
		{.BTI, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF3AF80F0, 0xFFFFFFFF, .V81M, .T32, {thumb32=true, cond_in_28=false}},
	},

	// =========================================================================
	// ARMv8.1-M low-overhead loops (LOL) -- can be used without MVE
	// =========================================================================
	// WLS  Rn, label:   1111 0000 0000 Rn 1100 0 imm10 imm1 1
	//                   high=F040, low varies
	// DLS  Rn:          1111 0000 0000 Rn 1110 0 000 0000 0000 0 1
	// LE   {LR,} label: 1111 0000 0000 1111 1100 imm5  ... 0 1
	// LETP / WLSTP / DLSTP: same family with TP variant bit
	// LCTP: 1111 0000 0000 1111 1110 0 0000 0000 0000 1
	.WLS = {
		{.WLS, {.GPR, .REL11, .NONE, .NONE}, {.RN_T32, .MVE_LOOP_IMM, .NONE, .NONE}, 0xF040C001, 0xFFF0F001, .V81M, .T32, {thumb32=true, cond_in_28=false, branch=true}},
	},
	.WLSTP = {
		// WLSTP.<size>: bits 22:20 carry size selector (B/H/W/D)
		{.WLSTP, {.GPR, .REL11, .NONE, .NONE}, {.RN_T32, .MVE_LOOP_IMM, .NONE, .NONE}, 0xF000C001, 0xFE80F001, .V81M, .T32, {thumb32=true, cond_in_28=false, branch=true}},
	},
	.DLS = {
		{.DLS, {.GPR, .NONE, .NONE, .NONE}, {.RN_T32, .NONE, .NONE, .NONE}, 0xF040E001, 0xFFF0FFFF, .V81M, .T32, {thumb32=true, cond_in_28=false}},
	},
	.DLSTP = {
		{.DLSTP, {.GPR, .NONE, .NONE, .NONE}, {.RN_T32, .NONE, .NONE, .NONE}, 0xF000E001, 0xFE80FFFF, .V81M, .T32, {thumb32=true, cond_in_28=false}},
	},
	.LE = {
		{.LE, {.REL11, .NONE, .NONE, .NONE}, {.MVE_LOOP_IMM, .NONE, .NONE, .NONE}, 0xF00FC001, 0xFFFFF001, .V81M, .T32, {thumb32=true, cond_in_28=false, branch=true}},
	},
	.LETP = {
		{.LETP, {.REL11, .NONE, .NONE, .NONE}, {.MVE_LOOP_IMM, .NONE, .NONE, .NONE}, 0xF01FC001, 0xFFFFF001, .V81M, .T32, {thumb32=true, cond_in_28=false, branch=true}},
	},
	.LCTP = {
		{.LCTP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF00FE001, 0xFFFFFFFF, .V81M, .T32, {thumb32=true, cond_in_28=false}},
	},

	// BF / BFL / BFLX / BFCSEL / BFI_BR (branch future, ARMv8.1-M).
	// These encodings are scattered/relative and are intentionally left as
	// placeholders pending dedicated LLVM-verified bit-pattern work. The
	// mnemonics remain in the enum so callers can refer to them.

	// =========================================================================
	// Custom Datapath Extension (CDE) -- Cortex-M33+
	// =========================================================================
	// CDE uses the existing coprocessor encoding space (CP0..CP7).
	//
	// CX1{A}  p<n>, Rd,            #imm   -- T32, 32-bit GPR dest
	// CX1D{A} p<n>, Rd, Rd+1,      #imm   -- T32, 64-bit GPR pair dest
	// CX2{A}  p<n>, Rd,  Rn,       #imm   -- with single Rn input
	// CX2D{A} p<n>, Rd, Rd+1, Rn,  #imm
	// CX3{A}  p<n>, Rd,  Rn, Rm,   #imm   -- with two Rn inputs
	// CX3D{A} p<n>, Rd, Rd+1, Rn, Rm, #imm
	// VCX1{A} p<n>, <V>, #imm              -- VFP S/D-reg dest
	// VCX2{A} p<n>, <V>, <V>, #imm
	// VCX3{A} p<n>, <V>, <V>, <V>, #imm
	//
	// Base T32 prefix 0xEE/0xEC selects which coproc encoding family. Bit 16
	// (A bit) distinguishes accumulator variants (CX1A from CX1, etc.).
	.CX1 = {
		{.CX1, {.IMM_COPROC, .GPR, .IMM, .NONE}, {.CDE_COPROC_FIELD, .RD_T32, .CDE_IMM_FIELD, .NONE}, 0xEE000000, 0xFF800000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
	},
	.CX1A = {
		{.CX1A, {.IMM_COPROC, .GPR, .IMM, .NONE}, {.CDE_COPROC_FIELD, .RD_T32, .CDE_IMM_FIELD, .NONE}, 0xFE000000, 0xFF800000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
	},
	.CX1D = {
		{.CX1D, {.IMM_COPROC, .GPR, .IMM, .NONE}, {.CDE_COPROC_FIELD, .RD_T32, .CDE_IMM_FIELD, .NONE}, 0xEE800000, 0xFF800000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
	},
	.CX1DA = {
		{.CX1DA, {.IMM_COPROC, .GPR, .IMM, .NONE}, {.CDE_COPROC_FIELD, .RD_T32, .CDE_IMM_FIELD, .NONE}, 0xFE800000, 0xFF800000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
	},
	.CX2 = {
		{.CX2, {.IMM_COPROC, .GPR, .GPR, .IMM}, {.CDE_COPROC_FIELD, .RD_T32, .RN_T32, .CDE_IMM_FIELD}, 0xEE400000, 0xFFC00000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
	},
	.CX2A = {
		{.CX2A, {.IMM_COPROC, .GPR, .GPR, .IMM}, {.CDE_COPROC_FIELD, .RD_T32, .RN_T32, .CDE_IMM_FIELD}, 0xFE400000, 0xFFC00000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
	},
	.CX2D = {
		{.CX2D, {.IMM_COPROC, .GPR, .GPR, .IMM}, {.CDE_COPROC_FIELD, .RD_T32, .RN_T32, .CDE_IMM_FIELD}, 0xEEC00000, 0xFFC00000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
	},
	.CX2DA = {
		{.CX2DA, {.IMM_COPROC, .GPR, .GPR, .IMM}, {.CDE_COPROC_FIELD, .RD_T32, .RN_T32, .CDE_IMM_FIELD}, 0xFEC00000, 0xFFC00000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
	},
	// CX3 has Rn and Rm inputs (Rm placed at bits 3:0 of low half)
	.CX3 = {
		{.CX3, {.IMM_COPROC, .GPR, .GPR, .GPR}, {.CDE_COPROC_FIELD, .RD_T32, .RN_T32, .RM_T32}, 0xEE800000, 0xFFC00000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
	},
	.CX3A = {
		{.CX3A, {.IMM_COPROC, .GPR, .GPR, .GPR}, {.CDE_COPROC_FIELD, .RD_T32, .RN_T32, .RM_T32}, 0xFE800000, 0xFFC00000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
	},
	.CX3D = {
		{.CX3D, {.IMM_COPROC, .GPR, .GPR, .GPR}, {.CDE_COPROC_FIELD, .RD_T32, .RN_T32, .RM_T32}, 0xEEC00000, 0xFFC00000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
	},
	.CX3DA = {
		{.CX3DA, {.IMM_COPROC, .GPR, .GPR, .GPR}, {.CDE_COPROC_FIELD, .RD_T32, .RN_T32, .RM_T32}, 0xFEC00000, 0xFFC00000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
	},
	// VCX variants -- VFP/FP-register destination using S or D form
	.VCX1 = {
		{.VCX1, {.IMM_COPROC, .SPR, .IMM, .NONE}, {.CDE_COPROC_FIELD, .VD_S, .CDE_IMM_FIELD, .NONE}, 0xEC200000, 0xFF300000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
		{.VCX1, {.IMM_COPROC, .DPR, .IMM, .NONE}, {.CDE_COPROC_FIELD, .VD_D, .CDE_IMM_FIELD, .NONE}, 0xEC300000, 0xFF300000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VCX1A = {
		{.VCX1A, {.IMM_COPROC, .SPR, .IMM, .NONE}, {.CDE_COPROC_FIELD, .VD_S, .CDE_IMM_FIELD, .NONE}, 0xFC200000, 0xFF300000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
		{.VCX1A, {.IMM_COPROC, .DPR, .IMM, .NONE}, {.CDE_COPROC_FIELD, .VD_D, .CDE_IMM_FIELD, .NONE}, 0xFC300000, 0xFF300000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VCX2 = {
		{.VCX2, {.IMM_COPROC, .SPR, .SPR, .IMM}, {.CDE_COPROC_FIELD, .VD_S, .VM_S, .CDE_IMM_FIELD}, 0xEC600000, 0xFF300000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
		{.VCX2, {.IMM_COPROC, .DPR, .DPR, .IMM}, {.CDE_COPROC_FIELD, .VD_D, .VM_D, .CDE_IMM_FIELD}, 0xEC700000, 0xFF300000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VCX2A = {
		{.VCX2A, {.IMM_COPROC, .SPR, .SPR, .IMM}, {.CDE_COPROC_FIELD, .VD_S, .VM_S, .CDE_IMM_FIELD}, 0xFC600000, 0xFF300000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
		{.VCX2A, {.IMM_COPROC, .DPR, .DPR, .IMM}, {.CDE_COPROC_FIELD, .VD_D, .VM_D, .CDE_IMM_FIELD}, 0xFC700000, 0xFF300000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VCX3 = {
		{.VCX3, {.IMM_COPROC, .SPR, .SPR, .SPR}, {.CDE_COPROC_FIELD, .VD_S, .VN_S, .VM_S}, 0xEC800000, 0xFF300000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
		{.VCX3, {.IMM_COPROC, .DPR, .DPR, .DPR}, {.CDE_COPROC_FIELD, .VD_D, .VN_D, .VM_D}, 0xEC900000, 0xFF300000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VCX3A = {
		{.VCX3A, {.IMM_COPROC, .SPR, .SPR, .SPR}, {.CDE_COPROC_FIELD, .VD_S, .VN_S, .VM_S}, 0xFC800000, 0xFF300000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
		{.VCX3A, {.IMM_COPROC, .DPR, .DPR, .DPR}, {.CDE_COPROC_FIELD, .VD_D, .VN_D, .VM_D}, 0xFC900000, 0xFF300000, .CDE, .T32, {thumb32=true, cond_in_28=false}},
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
		{.VPT, {.MVE_VPT_MASK, .COND, .QPR, .QPR}, {.MVE_VPT_MASK_FIELD, .NONE, .VN_Q, .VM_Q}, 0xFE010F00, 0xFE018FF0, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// VPST = 0xFE71_0F4D
	.VPST = {
		{.VPST, {.MVE_VPT_MASK, .NONE, .NONE, .NONE}, {.MVE_VPT_MASK_FIELD, .NONE, .NONE, .NONE}, 0xFE710F4D, 0xFFFFFFFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// VPSEL (LLVM): vpsel q1, q2, q3 = 0xFE35_2F07 -> base 0xFE010F01
	.VPSEL = {
		{.VPSEL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xFE010F01, 0xFFB10FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// VPNOT = 0xFE31_0F4D
	.VPNOT = {
		{.VPNOT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xFE310F4D, 0xFFFFFFFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// VCTP (LLVM): vctp.8 r3 = 0xF003_E801 -> base 0xF000E801 with Rn at bits 19:16
	.VCTP = {
		{.VCTP, {.GPR, .NONE, .NONE, .NONE}, {.RN_T32, .NONE, .NONE, .NONE}, 0xF000E801, 0xFFC0FFFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},

	// ---- MVE reductions (single Q -> GPR or pair) -----------------------------
	// MVE reductions (LLVM-verified bases for size-00 .S8 forms).
	.VADDV = {
		// vaddv.s8 r0, q3 = 0xEEF1_0F06 -> base 0xEEF10F00
		{.VADDV, {.GPR, .QPR, .NONE, .NONE}, {.RD_T32, .VM_Q, .NONE, .NONE}, 0xEEF10F00, 0xEFF30FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VADDVA = {
		// vaddva.s8 r0, q3 = 0xEEF1_0F26 -> base 0xEEF10F20
		{.VADDVA, {.GPR, .QPR, .NONE, .NONE}, {.RD_T32, .VM_Q, .NONE, .NONE}, 0xEEF10F20, 0xEFF30FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VADDLV = {
		// vaddlv.s32 r0,r1,q3 = 0xEE89_0F06 -> base 0xEE890F00 (Rd=R0 at 11:8, Rn=R1 implicit pair)
		{.VADDLV, {.GPR, .GPR, .QPR, .NONE}, {.RD_T32, .RN_T32, .VM_Q, .NONE}, 0xEE890F00, 0xEFFF0FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VADDLVA = {
		{.VADDLVA, {.GPR, .GPR, .QPR, .NONE}, {.RD_T32, .RN_T32, .VM_Q, .NONE}, 0xEE890F20, 0xEFFF0FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMAXV = {
		// vmaxv.s8 r0, q3 = 0xEEE2_0F06 -> base 0xEEE20F00
		{.VMAXV, {.GPR, .QPR, .NONE, .NONE}, {.RD_T32, .VM_Q, .NONE, .NONE}, 0xEEE20F00, 0xEFF30FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMAXAV = {
		{.VMAXAV, {.GPR, .QPR, .NONE, .NONE}, {.RD_T32, .VM_Q, .NONE, .NONE}, 0xEEE00F00, 0xEFF30FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMINV = {
		// vminv.s8 r0, q3 = 0xEEE2_0F86 -> base 0xEEE20F80
		{.VMINV, {.GPR, .QPR, .NONE, .NONE}, {.RD_T32, .VM_Q, .NONE, .NONE}, 0xEEE20F80, 0xEFF30FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMINAV = {
		{.VMINAV, {.GPR, .QPR, .NONE, .NONE}, {.RD_T32, .VM_Q, .NONE, .NONE}, 0xEEE00F80, 0xEFF30FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMAXNMV = {
		// vmaxnmv.f32 r0, q3 = 0xEEEE_0F06 -> base 0xEEEE0F00
		{.VMAXNMV, {.GPR, .QPR, .NONE, .NONE}, {.RD_T32, .VM_Q, .NONE, .NONE}, 0xEEEE0F00, 0xEFFF0FD1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMAXNMAV = {
		{.VMAXNMAV, {.GPR, .QPR, .NONE, .NONE}, {.RD_T32, .VM_Q, .NONE, .NONE}, 0xEEEC0F00, 0xEFFF0FD1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMINNMV = {
		// vminnmv.f32 r0, q3 = 0xEEEE_0F86 -> base 0xEEEE0F80
		{.VMINNMV, {.GPR, .QPR, .NONE, .NONE}, {.RD_T32, .VM_Q, .NONE, .NONE}, 0xEEEE0F80, 0xEFFF0FD1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMINNMAV = {
		{.VMINNMAV, {.GPR, .QPR, .NONE, .NONE}, {.RD_T32, .VM_Q, .NONE, .NONE}, 0xEEEC0F80, 0xEFFF0FD1, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}},
	},

	// ---- MVE dual MAC reductions (representative; full B/T/X variants encoded similarly) ----
	// MVE MAC reductions (LLVM-verified for .S8 sizes; size bits in 21:20):
	//   vabav.s8 r0, q2, q3 = 0xEE84_0F07 -> base 0xEE800F01
	.VABAV = {
		{.VABAV, {.GPR, .QPR, .QPR, .NONE}, {.RD_T32, .VN_Q, .VM_Q, .NONE}, 0xEE800F01, 0xEFB11051, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	//   vmlav.s8 r0,q2,q3 = 0xEEF4_0F06 -> base 0xEEB00F00
	//   vmladav.s8 = same encoding as vmlav (alias)
	.VMLAV = {
		{.VMLAV, {.GPR, .QPR, .QPR, .NONE}, {.RD_T32, .VN_Q, .VM_Q, .NONE}, 0xEEB00F00, 0xEFB10F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMLAVA = {
		{.VMLAVA, {.GPR, .QPR, .QPR, .NONE}, {.RD_T32, .VN_Q, .VM_Q, .NONE}, 0xEEB00F20, 0xEFB10F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMLADAV = {
		{.VMLADAV, {.GPR, .QPR, .QPR, .NONE}, {.RD_T32, .VN_Q, .VM_Q, .NONE}, 0xEEB00F00, 0xEFB10F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMLADAVA = {
		// vmladava.s8 = 0xEEF4_0F26 -> base 0xEEB00F20
		{.VMLADAVA, {.GPR, .QPR, .QPR, .NONE}, {.RD_T32, .VN_Q, .VM_Q, .NONE}, 0xEEB00F20, 0xEFB10F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMLADAVX = {
		// vmladavx.s8 = 0xEEF4_1F06 -> base 0xEEB01F00
		{.VMLADAVX, {.GPR, .QPR, .QPR, .NONE}, {.RD_T32, .VN_Q, .VM_Q, .NONE}, 0xEEB01F00, 0xEFB11F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMLADAVAX = {
		{.VMLADAVAX, {.GPR, .QPR, .QPR, .NONE}, {.RD_T32, .VN_Q, .VM_Q, .NONE}, 0xEEB01F20, 0xEFB11F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMLSDAV = {
		// vmlsdav.s8 r0,q2,q3 = 0xFEF4_0E07 -> base 0xFEB00E01
		{.VMLSDAV, {.GPR, .QPR, .QPR, .NONE}, {.RD_T32, .VN_Q, .VM_Q, .NONE}, 0xFEB00E01, 0xFFB11051, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMLSDAVA = {
		{.VMLSDAVA, {.GPR, .QPR, .QPR, .NONE}, {.RD_T32, .VN_Q, .VM_Q, .NONE}, 0xFEB00E21, 0xFFB11051, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMLSDAVX = {
		{.VMLSDAVX, {.GPR, .QPR, .QPR, .NONE}, {.RD_T32, .VN_Q, .VM_Q, .NONE}, 0xFEB01E01, 0xFFB11051, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMLSDAVAX = {
		{.VMLSDAVAX, {.GPR, .QPR, .QPR, .NONE}, {.RD_T32, .VN_Q, .VM_Q, .NONE}, 0xFEB01E21, 0xFFB11051, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// Long-version (64-bit pair RdaLo, RdaHi)
	//   vmlaldav.s32 r0,r1,q2,q3 = 0xEE85_0E06 -> base 0xEE800E00 (with Qn at 19:17 expanded view)
	//   Need to verify exact base after Rn at bits 11:8 + Rd at bits 15:12.
	.VMLALDAV = {
		{.VMLALDAV, {.GPR, .GPR, .QPR, .QPR}, {.RD_T32, .RN_T32, .VN_Q, .VM_Q}, 0xEE800E00, 0xEFB10F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMLALDAVA = {
		{.VMLALDAVA, {.GPR, .GPR, .QPR, .QPR}, {.RD_T32, .RN_T32, .VN_Q, .VM_Q}, 0xEE800E20, 0xEFB11F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMLALDAVX = {
		{.VMLALDAVX, {.GPR, .GPR, .QPR, .QPR}, {.RD_T32, .RN_T32, .VN_Q, .VM_Q}, 0xEE801E00, 0xEFB10F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMLALDAVAX = {
		{.VMLALDAVAX, {.GPR, .GPR, .QPR, .QPR}, {.RD_T32, .RN_T32, .VN_Q, .VM_Q}, 0xEE801E20, 0xEFB11F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMLSLDAV = {
		// vmlsldav.s32 r0,r1,q2,q3 = 0xEE85_0E07 -> base 0xEE800E01
		{.VMLSLDAV, {.GPR, .GPR, .QPR, .QPR}, {.RD_T32, .RN_T32, .VN_Q, .VM_Q}, 0xEE800E01, 0xFFB11F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMLSLDAVA = {
		{.VMLSLDAVA, {.GPR, .GPR, .QPR, .QPR}, {.RD_T32, .RN_T32, .VN_Q, .VM_Q}, 0xEE800E21, 0xFFB11F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMLSLDAVX = {
		// vmlsldavx.s32 = 0xEE85_1E07 -> base 0xEE801E01
		{.VMLSLDAVX, {.GPR, .GPR, .QPR, .QPR}, {.RD_T32, .RN_T32, .VN_Q, .VM_Q}, 0xEE801E01, 0xFFB11051, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMLSLDAVAX = {
		{.VMLSLDAVAX, {.GPR, .GPR, .QPR, .QPR}, {.RD_T32, .RN_T32, .VN_Q, .VM_Q}, 0xEE801E21, 0xFFB11051, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// High-half rounding reductions:
	//   vrmlaldavh.s32 r0,r1,q2,q3 = 0xEE84_0F06 -> base 0xEE800F00
	//   vrmlsldavh.s32 r0,r1,q2,q3 = 0xFE84_0E07 -> base 0xFE800E01
	.VRMLALDAVH = {
		{.VRMLALDAVH, {.GPR, .GPR, .QPR, .QPR}, {.RD_T32, .RN_T32, .VN_Q, .VM_Q}, 0xEE800F00, 0xEFB10F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VRMLALDAVHA = {
		{.VRMLALDAVHA, {.GPR, .GPR, .QPR, .QPR}, {.RD_T32, .RN_T32, .VN_Q, .VM_Q}, 0xEE800F20, 0xEFB11F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VRMLALDAVHX = {
		{.VRMLALDAVHX, {.GPR, .GPR, .QPR, .QPR}, {.RD_T32, .RN_T32, .VN_Q, .VM_Q}, 0xEE801F00, 0xEFB10F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VRMLALDAVHAX = {
		{.VRMLALDAVHAX, {.GPR, .GPR, .QPR, .QPR}, {.RD_T32, .RN_T32, .VN_Q, .VM_Q}, 0xEE801F20, 0xEFB11F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VRMLSLDAVH = {
		{.VRMLSLDAVH, {.GPR, .GPR, .QPR, .QPR}, {.RD_T32, .RN_T32, .VN_Q, .VM_Q}, 0xFE800E01, 0xFFB11051, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VRMLSLDAVHA = {
		{.VRMLSLDAVHA, {.GPR, .GPR, .QPR, .QPR}, {.RD_T32, .RN_T32, .VN_Q, .VM_Q}, 0xFE800E21, 0xFFB11051, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VRMLSLDAVHX = {
		{.VRMLSLDAVHX, {.GPR, .GPR, .QPR, .QPR}, {.RD_T32, .RN_T32, .VN_Q, .VM_Q}, 0xFE801E01, 0xFFB11051, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VRMLSLDAVHAX = {
		{.VRMLSLDAVHAX, {.GPR, .GPR, .QPR, .QPR}, {.RD_T32, .RN_T32, .VN_Q, .VM_Q}, 0xFE801E21, 0xFFB11051, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},

	// ---- MVE complex arithmetic ------------------------------------------------
	.VCMUL = {
		{.VCMUL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEE300E00, 0xEFB10F51, .MVE_FP, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VHCADD = {
		{.VHCADD, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEE000F00, 0xEFB10F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},

	// ---- MVE shifts (specialized) ---------------------------------------------
	.VSHLC = {
		// VSHLC Qd, Rdm, #imm5  -- vector shift left with carry from GPR
		{.VSHLC, {.QPR, .GPR, .IMM5, .NONE}, {.VD_Q, .RM_T32, .A32_IMM_SHIFT, .NONE}, 0xEE000FC0, 0xFFC00FF1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VBRSR = {
		// VBRSR Qd, Qn, Rm  -- bit reverse with shift right
		{.VBRSR, {.QPR, .QPR, .GPR, .NONE}, {.VD_Q, .VN_Q, .RM_T32, .NONE}, 0xEE011E60, 0xEF811F71, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},

	// ---- MVE counter init duplicates ------------------------------------------
	.VDDUP = {
		{.VDDUP, {.QPR, .GPR, .IMM, .NONE}, {.VD_Q, .RM_T32, .CDE_IMM_FIELD, .NONE}, 0xEE011F6E, 0xEF811F7E, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VIDUP = {
		{.VIDUP, {.QPR, .GPR, .IMM, .NONE}, {.VD_Q, .RM_T32, .CDE_IMM_FIELD, .NONE}, 0xEE010F6E, 0xEF811F7E, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VDWDUP = {
		{.VDWDUP, {.QPR, .GPR, .GPR, .IMM}, {.VD_Q, .RM_T32, .RN_T32, .CDE_IMM_FIELD}, 0xEE011F60, 0xEF811F70, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VIWDUP = {
		{.VIWDUP, {.QPR, .GPR, .GPR, .IMM}, {.VD_Q, .RM_T32, .RN_T32, .CDE_IMM_FIELD}, 0xEE010F60, 0xEF811F70, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},

	// MVE narrow B/T (LLVM-verified for .S16 sizes; T-form bit 12 = 1):
	.VMOVNB = {
		// vmovnb.s16 q1, q3 = 0xFE31_2E87 -> base 0xFE310E81
		{.VMOVNB, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xFE310E81, 0xFFB31FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMOVNT = {
		{.VMOVNT, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xFE311E81, 0xFFB31FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VQMOVNB = {
		// vqmovnb.s16 q1, q3 = 0xEE33_2E07 -> base 0xEE330E01
		{.VQMOVNB, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xEE330E01, 0xFFB31FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VQMOVNT = {
		{.VQMOVNT, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xEE331E01, 0xFFB31FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VQMOVUNB = {
		// vqmovunb.s16 q1, q3 = 0xEE31_2E87 -> base 0xEE310E81
		{.VQMOVUNB, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xEE310E81, 0xFFB31FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VQMOVUNT = {
		{.VQMOVUNT, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xEE311E81, 0xFFB31FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// MVE widening (long) B/T forms:
	.VSHLLB = {
		// vshllb.s8 q1, q3, #4 = 0xEEAC_2F46 -> base 0xEE800F40 (imm6 in 21:16,
		// includes the size-prefix 101sss for .S8)
		{.VSHLLB, {.QPR, .QPR, .IMM5, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xEE800F40, 0xEF801FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VSHLLT = {
		{.VSHLLT, {.QPR, .QPR, .IMM5, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xEE801F40, 0xEF801FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMULLB = {
		// vmullb.s8 q1, q2, q3 = 0xEE05_2E06 -> base 0xEE000E00
		{.VMULLB, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEE000E00, 0xEF811F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMULLT = {
		{.VMULLT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEE001E00, 0xEF811F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// VMLALB/T/VMLSLB/T: LLVM doesn't seem to support direct mnemonics in
	// its assembler; encodings derived heuristically from VMULL B/T pattern
	.VMLALB = {
		{.VMLALB, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEE000E20, 0xEF811F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMLALT = {
		{.VMLALT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEE001E20, 0xEF811F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMLSLB = {
		{.VMLSLB, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEE000E10, 0xEF811F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMLSLT = {
		{.VMLSLT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEE001E10, 0xEF811F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// Narrow shift B/T forms (LLVM-verified):
	//   vshrnb.i16 q,q,#shift = 0xEE8F_2EC7 base 0xEE800EC1 (imm6 = 16-shift)
	//   vshrnt.i16 = bit 12 = 1
	.VSHRNB = {
		{.VSHRNB, {.QPR, .QPR, .IMM5, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xEE800EC1, 0xEF801FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VSHRNT = {
		{.VSHRNT, {.QPR, .QPR, .IMM5, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xEE801EC1, 0xEF801FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VRSHRNB = {
		{.VRSHRNB, {.QPR, .QPR, .IMM5, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xFE800EC1, 0xFF801FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VRSHRNT = {
		{.VRSHRNT, {.QPR, .QPR, .IMM5, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xFE801EC1, 0xFF801FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VQSHRNB = {
		// vqshrnb.s16 q,q,#4 = 0xEE8C_2F46 -> base 0xEE800F40
		{.VQSHRNB, {.QPR, .QPR, .IMM5, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xEE800F40, 0xEF801FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VQSHRNT = {
		{.VQSHRNT, {.QPR, .QPR, .IMM5, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xEE801F40, 0xEF801FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VQRSHRNB = {
		// vqrshrnb.s16 q,q,#4 = 0xEE8C_2F47 -> base 0xEE800F41
		{.VQRSHRNB, {.QPR, .QPR, .IMM5, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xEE800F41, 0xEF801FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VQRSHRNT = {
		{.VQRSHRNT, {.QPR, .QPR, .IMM5, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xEE801F41, 0xEF801FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VQSHRUNB = {
		// vqshrunb.s16 q,q,#4 = 0xEE8C_2FC6 -> base 0xEE800FC0
		{.VQSHRUNB, {.QPR, .QPR, .IMM5, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xEE800FC0, 0xEF801FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VQSHRUNT = {
		{.VQSHRUNT, {.QPR, .QPR, .IMM5, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xEE801FC0, 0xEF801FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VQRSHRUNB = {
		// vqrshrunb.s16 q,q,#4 = 0xFE8C_2FC6 -> base 0xFE800FC0
		{.VQRSHRUNB, {.QPR, .QPR, .IMM5, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xFE800FC0, 0xFF801FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VQRSHRUNT = {
		{.VQRSHRUNT, {.QPR, .QPR, .IMM5, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xFE801FC0, 0xFF801FD1, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},

	// ---- MVE Q-lane GPR move ---------------------------------------------------
	.VMOV_Q_R = {
		// VMOV.<size> Qd[i], Rt  -- single lane Rt -> Qd[i]
		{.VMOV_Q_R, {.QPR_ELEM, .GPR, .NONE, .NONE}, {.VD_Q, .RT_T32, .NONE, .NONE}, 0xEE000B10, 0xFF900F1F, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMOV_R_Q = {
		// VMOV.<size> Rt, Qd[i]
		{.VMOV_R_Q, {.GPR, .QPR_ELEM, .NONE, .NONE}, {.RT_T32, .VD_Q, .NONE, .NONE}, 0xEE100B10, 0xFF900F1F, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VMOV_2GPR_Q = {
		// VMOV Qd[2*i], Qd[2*i+1], Rt, Rt2  -- pair move
		{.VMOV_2GPR_Q, {.QPR_ELEM, .QPR_ELEM, .GPR, .GPR}, {.VD_Q, .VD_Q, .RT_T32, .RT2_T32}, 0xEC000F00, 0xFF900F11, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},

	// MVE saturating doubling MAC (LLVM-verified for .S8 sizes):
	//   vqdmladh.s8 q1,q2,q3 = 0xEE04_2E06 -> base 0xEE000E00
	//   vqdmladhx (X-form bit 12 = 1)
	//   vqdmlsdh = top byte 0xFE (vs 0xEE)
	//   vqrdmladh = bit 0 = 1 (vs 0)
	.VQDMLADH = {
		{.VQDMLADH, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEE000E00, 0xEF811F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VQDMLADHX = {
		{.VQDMLADHX, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEE001E00, 0xEF811F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VQDMLSDH = {
		{.VQDMLSDH, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xFE000E00, 0xFF811F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VQDMLSDHX = {
		{.VQDMLSDHX, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xFE001E00, 0xFF811F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VQRDMLADH = {
		{.VQRDMLADH, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEE000E01, 0xEF811F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VQRDMLADHX = {
		{.VQRDMLADHX, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xEE001E01, 0xEF811F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VQRDMLSDH = {
		{.VQRDMLSDH, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xFE000E01, 0xFF811F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VQRDMLSDHX = {
		{.VQRDMLSDHX, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VN_Q, .VM_Q, .NONE}, 0xFE001E01, 0xFF811F51, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},

	// ---- MVE load/store --------------------------------------------------------
	// VLDR<dt>/VSTR<dt> Qd, [Rn{, #imm}] (LLVM-verified contiguous load/store):
	//   vldrb.u8  q1, [r2] = 0xED92_3E00 -> base 0xED901E00
	//   vldrh.u16 q1, [r2] = 0xED92_3E80 -> base 0xED901E80
	//   vldrw.u32 q1, [r2] = 0xED92_3F00 -> base 0xED901F00
	//   vstrb.8   q1, [r2] = 0xED82_3E00 -> base 0xED801E00
	.VLDRB = {
		{.VLDRB, {.QPR, .MEM, .NONE, .NONE}, {.VD_Q, .MEM_IMM12_OFFSET, .NONE, .NONE}, 0xED901E00, 0xFFB01F00, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VLDRH = {
		{.VLDRH, {.QPR, .MEM, .NONE, .NONE}, {.VD_Q, .MEM_IMM12_OFFSET, .NONE, .NONE}, 0xED901E80, 0xFFB01F80, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VLDRW = {
		{.VLDRW, {.QPR, .MEM, .NONE, .NONE}, {.VD_Q, .MEM_IMM12_OFFSET, .NONE, .NONE}, 0xED901F00, 0xFFB01F80, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VLDRD = {
		{.VLDRD, {.QPR, .MEM, .NONE, .NONE}, {.VD_Q, .MEM_IMM12_OFFSET, .NONE, .NONE}, 0xED901F80, 0xFFB01F80, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VSTRB = {
		{.VSTRB, {.QPR, .MEM, .NONE, .NONE}, {.VD_Q, .MEM_IMM12_OFFSET, .NONE, .NONE}, 0xED801E00, 0xFFB01F00, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VSTRH = {
		{.VSTRH, {.QPR, .MEM, .NONE, .NONE}, {.VD_Q, .MEM_IMM12_OFFSET, .NONE, .NONE}, 0xED801E80, 0xFFB01F80, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VSTRW = {
		{.VSTRW, {.QPR, .MEM, .NONE, .NONE}, {.VD_Q, .MEM_IMM12_OFFSET, .NONE, .NONE}, 0xED801F00, 0xFFB01F80, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VSTRD = {
		{.VSTRD, {.QPR, .MEM, .NONE, .NONE}, {.VD_Q, .MEM_IMM12_OFFSET, .NONE, .NONE}, 0xED801F80, 0xFFB01F80, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	// Interleaved load/store -- 2-vector
	.VLD20 = {
		{.VLD20, {.QPR_MVE_LIST, .MEM, .NONE, .NONE}, {.VD_Q, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0xFC901E00, 0xFFB01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VLD21 = {
		{.VLD21, {.QPR_MVE_LIST, .MEM, .NONE, .NONE}, {.VD_Q, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0xFC901E20, 0xFFB01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VLD40 = {
		{.VLD40, {.QPR_MVE_LIST, .MEM, .NONE, .NONE}, {.VD_Q, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0xFC901E01, 0xFFB01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VLD41 = {
		{.VLD41, {.QPR_MVE_LIST, .MEM, .NONE, .NONE}, {.VD_Q, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0xFC901E21, 0xFFB01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VLD42 = {
		{.VLD42, {.QPR_MVE_LIST, .MEM, .NONE, .NONE}, {.VD_Q, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0xFC901E41, 0xFFB01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VLD43 = {
		{.VLD43, {.QPR_MVE_LIST, .MEM, .NONE, .NONE}, {.VD_Q, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0xFC901E61, 0xFFB01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VST20 = {
		{.VST20, {.QPR_MVE_LIST, .MEM, .NONE, .NONE}, {.VD_Q, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0xFC801E00, 0xFFB01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VST21 = {
		{.VST21, {.QPR_MVE_LIST, .MEM, .NONE, .NONE}, {.VD_Q, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0xFC801E20, 0xFFB01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VST40 = {
		{.VST40, {.QPR_MVE_LIST, .MEM, .NONE, .NONE}, {.VD_Q, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0xFC801E01, 0xFFB01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VST41 = {
		{.VST41, {.QPR_MVE_LIST, .MEM, .NONE, .NONE}, {.VD_Q, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0xFC801E21, 0xFFB01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VST42 = {
		{.VST42, {.QPR_MVE_LIST, .MEM, .NONE, .NONE}, {.VD_Q, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0xFC801E41, 0xFFB01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},
	.VST43 = {
		{.VST43, {.QPR_MVE_LIST, .MEM, .NONE, .NONE}, {.VD_Q, .MEM_IMM8_OFFSET, .NONE, .NONE}, 0xFC801E61, 0xFFB01EFF, .MVE_INT, .T32, {thumb32=true, cond_in_28=false}},
	},

	// Unprivileged (translate) post-indexed loads/stores: the post-index form
	// with the W bit (21) set. Word/byte use imm12, half/signed use imm8 split.
	.LDRT   = { {.LDRT,   {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX, .NONE, .NONE}, 0x04B00000, 0x0F700000, .BASE, .A32, {}} },
	.LDRBT  = { {.LDRBT,  {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX, .NONE, .NONE}, 0x04F00000, 0x0F700000, .BASE, .A32, {}} },
	.STRT   = { {.STRT,   {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX, .NONE, .NONE}, 0x04A00000, 0x0F700000, .BASE, .A32, {}} },
	.STRBT  = { {.STRBT,  {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX, .NONE, .NONE}, 0x04E00000, 0x0F700000, .BASE, .A32, {}} },
	.LDRHT  = { {.LDRHT,  {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX, .NONE, .NONE}, 0x00F000B0, 0x0F7000F0, .BASE, .A32, {}} },
	.STRHT  = { {.STRHT,  {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX, .NONE, .NONE}, 0x00E000B0, 0x0F7000F0, .BASE, .A32, {}} },
	.LDRSBT = { {.LDRSBT, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX, .NONE, .NONE}, 0x00F000D0, 0x0F7000F0, .BASE, .A32, {}} },
	.LDRSHT = { {.LDRSHT, {.GPR, .MEM, .NONE, .NONE}, {.RT_A32, .MEM_POST_INDEX, .NONE, .NONE}, 0x00F000F0, 0x0F7000F0, .BASE, .A32, {}} },

	// NEON rounding shift-right-accumulate (imm); FP reciprocal/rsqrt estimate;
	// FP pairwise add; VFP convert-to-integer using the FPSCR rounding mode.
	.VRSRA = {
		{.VRSRA, {.DPR, .DPR, .IMM, .NONE}, {.VD_D, .VM_D, .NEON_SHIFT_IMM6, .NONE}, 0xF2800310, 0xFE800F10, .NEON, .A32, {cond_in_28=false}},
		{.VRSRA, {.QPR, .QPR, .IMM, .NONE}, {.VD_Q, .VM_Q, .NEON_SHIFT_IMM6, .NONE}, 0xF2800350, 0xFE800F50, .NEON, .A32, {cond_in_28=false}},
	},
	.VRECPE_F = {
		{.VRECPE_F, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3BB0500, 0xFFBF0FD0, .NEON, .A32, {cond_in_28=false}},
		{.VRECPE_F, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3BB0540, 0xFFBF0FD0, .NEON, .A32, {cond_in_28=false}},
	},
	.VRSQRTE_F = {
		{.VRSQRTE_F, {.DPR, .DPR, .NONE, .NONE}, {.VD_D, .VM_D, .NONE, .NONE}, 0xF3BB0580, 0xFFBF0FD0, .NEON, .A32, {cond_in_28=false}},
		{.VRSQRTE_F, {.QPR, .QPR, .NONE, .NONE}, {.VD_Q, .VM_Q, .NONE, .NONE}, 0xF3BB05C0, 0xFFBF0FD0, .NEON, .A32, {cond_in_28=false}},
	},
	.VPADD_F = {
		{.VPADD_F, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3000D00, 0xFFB00F10, .NEON, .A32, {cond_in_28=false}},
		{.VPADD_F, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VN_D, .VM_D, .NONE}, 0xF3100D00, 0xFFB00F10, .NEON_HALF_FP, .A32, {cond_in_28=false}},
	},
	.VCVTR = {
		{.VCVTR, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EBD0A40, 0x0FBF0FD0, .VFPV2, .A32, {}},
		{.VCVTR, {.SPR, .SPR, .NONE, .NONE}, {.VD_S, .VM_S, .NONE, .NONE}, 0x0EBC0A40, 0x0FBF0FD0, .VFPV2, .A32, {}},
		{.VCVTR, {.SPR, .DPR, .NONE, .NONE}, {.VD_S, .VM_D, .NONE, .NONE}, 0x0EBD0B40, 0x0FBF0FD0, .VFPV2, .A32, {}},
		{.VCVTR, {.SPR, .DPR, .NONE, .NONE}, {.VD_S, .VM_D, .NONE, .NONE}, 0x0EBC0B40, 0x0FBF0FD0, .VFPV2, .A32, {}},
	},

	// Debug change PE state (T32, fixed encoding, no operands).
	.DCPS1 = { {.DCPS1, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF78F8001, 0xFFFFFFFF, .V8, .T32, {thumb32=true, cond_in_28=false}} },
	.DCPS2 = { {.DCPS2, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF78F8002, 0xFFFFFFFF, .V8, .T32, {thumb32=true, cond_in_28=false}} },
	.DCPS3 = { {.DCPS3, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF78F8003, 0xFFFFFFFF, .V8, .T32, {thumb32=true, cond_in_28=false}} },

	// NEON (saturating) doubling multiply-high by scalar Dm[lane]:
	//   .16 -> Dm in D0..D7 (bits 2:0), lane at bit5:bit3;  .32 -> D0..D15, lane bit5.
	.VQDMULH_LANE = {
		{.VQDMULH_LANE, {.DPR, .DPR, .DPR_ELEM, .NONE}, {.VD_D, .VN_D, .NEON_VM_SCALAR16, .NONE}, 0xF2900C40, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQDMULH_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .NEON_VM_SCALAR16, .NONE}, 0xF3900C40, 0xFFB11F50, .NEON, .A32, {cond_in_28=false}},
		{.VQDMULH_LANE, {.DPR, .DPR, .DPR_ELEM, .NONE}, {.VD_D, .VN_D, .NEON_VM_SCALAR32, .NONE}, 0xF2A00C40, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQDMULH_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .NEON_VM_SCALAR32, .NONE}, 0xF3A00C40, 0xFFB11F50, .NEON, .A32, {cond_in_28=false}},
	},
	.VQRDMULH_LANE = {
		{.VQRDMULH_LANE, {.DPR, .DPR, .DPR_ELEM, .NONE}, {.VD_D, .VN_D, .NEON_VM_SCALAR16, .NONE}, 0xF2900D40, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQRDMULH_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .NEON_VM_SCALAR16, .NONE}, 0xF3900D40, 0xFFB11F50, .NEON, .A32, {cond_in_28=false}},
		{.VQRDMULH_LANE, {.DPR, .DPR, .DPR_ELEM, .NONE}, {.VD_D, .VN_D, .NEON_VM_SCALAR32, .NONE}, 0xF2A00D40, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQRDMULH_LANE, {.QPR, .QPR, .DPR_ELEM, .NONE}, {.VD_Q, .VN_Q, .NEON_VM_SCALAR32, .NONE}, 0xF3A00D40, 0xFFB11F50, .NEON, .A32, {cond_in_28=false}},
	},

	// SPECGEN:BEGIN
	.VADDL = {
		{.VADDL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2800000, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
		{.VADDL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2900000, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
		{.VADDL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2A00000, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
		{.VADDL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3800000, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
		{.VADDL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3900000, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
		{.VADDL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3A00000, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
	},
	.VSUBL = {
		{.VSUBL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2800200, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
		{.VSUBL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2900200, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
		{.VSUBL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2A00200, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
		{.VSUBL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3800200, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
		{.VSUBL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3900200, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
		{.VSUBL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3A00200, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
	},
	.VABAL = {
		{.VABAL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2800500, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
		{.VABAL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2900500, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
		{.VABAL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2A00500, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
		{.VABAL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3800500, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
		{.VABAL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3900500, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
		{.VABAL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3A00500, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
	},
	.VABDL = {
		{.VABDL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2800700, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
		{.VABDL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2900700, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
		{.VABDL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF2A00700, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
		{.VABDL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3800700, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
		{.VABDL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3900700, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
		{.VABDL, {.QPR, .DPR, .DPR, .NONE}, {.VD_Q, .VN_D, .VM_D, .NONE}, 0xF3A00700, 0xFFB01F50, .NEON, .A32, {cond_in_28=false}},
	},
	.VADDW = {
		{.VADDW, {.QPR, .QPR, .DPR, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF2800100, 0xFFB11F50, .NEON, .A32, {cond_in_28=false}},
		{.VADDW, {.QPR, .QPR, .DPR, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF2900100, 0xFFB11F50, .NEON, .A32, {cond_in_28=false}},
		{.VADDW, {.QPR, .QPR, .DPR, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF2A00100, 0xFFB11F50, .NEON, .A32, {cond_in_28=false}},
		{.VADDW, {.QPR, .QPR, .DPR, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF3800100, 0xFFB11F50, .NEON, .A32, {cond_in_28=false}},
		{.VADDW, {.QPR, .QPR, .DPR, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF3900100, 0xFFB11F50, .NEON, .A32, {cond_in_28=false}},
		{.VADDW, {.QPR, .QPR, .DPR, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF3A00100, 0xFFB11F50, .NEON, .A32, {cond_in_28=false}},
	},
	.VSUBW = {
		{.VSUBW, {.QPR, .QPR, .DPR, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF2800300, 0xFFB11F50, .NEON, .A32, {cond_in_28=false}},
		{.VSUBW, {.QPR, .QPR, .DPR, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF2900300, 0xFFB11F50, .NEON, .A32, {cond_in_28=false}},
		{.VSUBW, {.QPR, .QPR, .DPR, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF2A00300, 0xFFB11F50, .NEON, .A32, {cond_in_28=false}},
		{.VSUBW, {.QPR, .QPR, .DPR, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF3800300, 0xFFB11F50, .NEON, .A32, {cond_in_28=false}},
		{.VSUBW, {.QPR, .QPR, .DPR, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF3900300, 0xFFB11F50, .NEON, .A32, {cond_in_28=false}},
		{.VSUBW, {.QPR, .QPR, .DPR, .NONE}, {.VD_Q, .VN_Q, .VM_D, .NONE}, 0xF3A00300, 0xFFB11F50, .NEON, .A32, {cond_in_28=false}},
	},
	.VCLE = {
		{.VCLE, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF2000310, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VCLE, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF2000350, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
		{.VCLE, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF2100310, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VCLE, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF2100350, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
		{.VCLE, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF2200310, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VCLE, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF2200350, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
		{.VCLE, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF3000310, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VCLE, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF3000350, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
		{.VCLE, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF3100310, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VCLE, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF3100350, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
		{.VCLE, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF3200310, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VCLE, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF3200350, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
		{.VCLE, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF3000E00, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VCLE, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF3000E40, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
	},
	.VCLT = {
		{.VCLT, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF2000300, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VCLT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF2000340, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
		{.VCLT, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF2100300, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VCLT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF2100340, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
		{.VCLT, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF2200300, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VCLT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF2200340, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
		{.VCLT, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF3000300, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VCLT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF3000340, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
		{.VCLT, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF3100300, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VCLT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF3100340, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
		{.VCLT, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF3200300, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VCLT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF3200340, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
		{.VCLT, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF3200E00, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VCLT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF3200E40, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
	},
	.VACLE = {
		{.VACLE, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF3000E10, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VACLE, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF3000E50, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
	},
	.VACLT = {
		{.VACLT, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF3200E10, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VACLT, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF3200E50, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
	},
	.VQRSHL = {
		{.VQRSHL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF2000510, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQRSHL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF2000550, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
		{.VQRSHL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF2100510, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQRSHL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF2100550, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
		{.VQRSHL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF2200510, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQRSHL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF2200550, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
		{.VQRSHL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF2300510, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQRSHL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF2300550, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
		{.VQRSHL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF3000510, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQRSHL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF3000550, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
		{.VQRSHL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF3100510, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQRSHL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF3100550, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
		{.VQRSHL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF3200510, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQRSHL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF3200550, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
		{.VQRSHL, {.DPR, .DPR, .DPR, .NONE}, {.VD_D, .VM_D, .VN_D, .NONE}, 0xF3300510, 0xFFB00F50, .NEON, .A32, {cond_in_28=false}},
		{.VQRSHL, {.QPR, .QPR, .QPR, .NONE}, {.VD_Q, .VM_Q, .VN_Q, .NONE}, 0xF3300550, 0xFFB11F51, .NEON, .A32, {cond_in_28=false}},
	},
	// SPECGEN:END
}

