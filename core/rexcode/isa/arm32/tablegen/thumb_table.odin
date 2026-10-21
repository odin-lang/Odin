// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm32_tablegen

// =============================================================================
// AArch32 THUMB ENCODING TABLE
// =============================================================================
//
// The integer Thumb instruction set, 16-bit and 32-bit, in the order the
// Architecture Reference Manual's encoding index gives it. It is a flat list
// rather than a per-mnemonic one so that it can follow that order -- a Thumb
// encoding class is a run of related mnemonics, and checking a class against
// the manual is easier when the class is one block. The generator merges these
// rows into each mnemonic's forms after its ENCODING_TABLE ones.
//
// Rows are the same `Encoding` as ENCODING_TABLE: mnemonic, operand types,
// operand encodings, bits, mask, feature, mode, flags, data type. A 16-bit form
// keeps its halfword in bits 15:0; a 32-bit form packs the first halfword in
// bits 31:16 and the second in 15:0.
//
// What the 16-bit forms need that A32 does not:
//
//   * flags_outside_it: most 16-bit data processing sets the flags outside an
//     IT block and not inside one. The same bits are `adds` and `add`.
//   * thumb_condition: B<c> is the only instruction with its own condition;
//     everything else takes one from the IT block it sits in.
//
// VFP, Advanced SIMD and the coprocessor instructions are not listed here:
// their Thumb encodings are their A32 encodings with the condition field
// fixed, and the generator derives them.

@(rodata)
THUMB_TABLE := []Encoding{
	// =========================================================================
	// 16-bit: shift (immediate), add, subtract, move and compare
	// =========================================================================
	//   000 op(2) imm5 Rm Rd          LSL / LSR / ASR #imm  (LSL #0 is MOVS)
	//   000 11 I op Rm|imm3 Rn Rd     ADD / SUB, register or #imm3
	//   001 op(2) Rd imm8             MOV / CMP / ADD / SUB #imm8
	{.MOV, {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0x0000, 0xFFC0, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.LSL, {.GPR_LOW, .GPR_LOW, .IMM5, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .IMM5_T16_SHIFT, .NONE, .NONE, .NONE}, 0x0000, 0xF800, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.LSR, {.GPR_LOW, .GPR_LOW, .IMM5, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .IMM5_T16_SHIFT_32, .NONE, .NONE, .NONE}, 0x0800, 0xF800, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.ASR, {.GPR_LOW, .GPR_LOW, .IMM5, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .IMM5_T16_SHIFT_32, .NONE, .NONE, .NONE}, 0x1000, 0xF800, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.ADD, {.GPR_LOW, .GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RN_T16_LO, .RM_T16_8_6, .NONE, .NONE, .NONE}, 0x1800, 0xFE00, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.SUB, {.GPR_LOW, .GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RN_T16_LO, .RM_T16_8_6, .NONE, .NONE, .NONE}, 0x1A00, 0xFE00, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.ADD, {.GPR_LOW, .GPR_LOW, .IMM3, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RN_T16_LO, .IMM3_T16, .NONE, .NONE, .NONE}, 0x1C00, 0xFE00, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.SUB, {.GPR_LOW, .GPR_LOW, .IMM3, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RN_T16_LO, .IMM3_T16, .NONE, .NONE, .NONE}, 0x1E00, 0xFE00, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.MOV, {.GPR_LOW, .IMM8, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_10_8, .IMM8_T16, .NONE, .NONE, .NONE, .NONE}, 0x2000, 0xF800, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.CMP, {.GPR_LOW, .IMM8, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_10_8, .IMM8_T16, .NONE, .NONE, .NONE, .NONE}, 0x2800, 0xF800, .THUMB, .T32, {}, {}},
	{.ADD, {.GPR_LOW, .IMM8, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_10_8, .IMM8_T16, .NONE, .NONE, .NONE, .NONE}, 0x3000, 0xF800, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.SUB, {.GPR_LOW, .IMM8, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_10_8, .IMM8_T16, .NONE, .NONE, .NONE, .NONE}, 0x3800, 0xF800, .THUMB, .T32, {flags_outside_it = true}, {}},

	// =========================================================================
	// 16-bit: data processing
	// =========================================================================
	//   010000 op(4) Rm Rdn
	{.AND, {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0x4000, 0xFFC0, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.EOR, {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0x4040, 0xFFC0, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.LSL, {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0x4080, 0xFFC0, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.LSR, {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0x40C0, 0xFFC0, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.ASR, {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0x4100, 0xFFC0, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.ADC, {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0x4140, 0xFFC0, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.SBC, {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0x4180, 0xFFC0, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.ROR, {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0x41C0, 0xFFC0, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.TST, {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0x4200, 0xFFC0, .THUMB, .T32, {}, {}},
	// RSBS Rd, Rn, #0 -- the zero is the syntax's, not the word's. NEGS is
	// the same word under the name UAL gives it as an alias.
	{.RSB, {.GPR_LOW, .GPR_LOW, .IMM, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0x4240, 0xFFC0, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.NEG, {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0x4240, 0xFFC0, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.CMP, {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0x4280, 0xFFC0, .THUMB, .T32, {}, {}},
	{.CMN, {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0x42C0, 0xFFC0, .THUMB, .T32, {}, {}},
	{.ORR, {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0x4300, 0xFFC0, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.MUL, {.GPR_LOW, .GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .RD_T16_LO_AGAIN, .NONE, .NONE, .NONE}, 0x4340, 0xFFC0, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.BIC, {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0x4380, 0xFFC0, .THUMB, .T32, {flags_outside_it = true}, {}},
	{.MVN, {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0x43C0, 0xFFC0, .THUMB, .T32, {flags_outside_it = true}, {}},

	// =========================================================================
	// 16-bit: special data instructions and branch and exchange
	// =========================================================================
	//   010001 00 DN Rm Rdn    ADD   (any registers; SP gets its own spelling)
	//   010001 01 N  Rm Rn     CMP
	//   010001 10 D  Rm Rd     MOV
	//   010001 11 L  Rm 000    BX / BLX
	{.ADD, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T16_HI, .IMPL_SP, .RD_T16_HI_AGAIN, .NONE, .NONE, .NONE}, 0x4468, 0xFF78, .THUMB, .T32, {}, {}},
	{.ADD, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.IMPL_SP, .RM_T16_HI, .NONE, .NONE, .NONE, .NONE}, 0x4485, 0xFF87, .THUMB, .T32, {}, {}},
	{.ADD, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_HI, .RM_T16_HI, .NONE, .NONE, .NONE, .NONE}, 0x4400, 0xFF00, .THUMB, .T32, {}, {}},
	{.CMP, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_HI, .RM_T16_HI, .NONE, .NONE, .NONE, .NONE}, 0x4500, 0xFF00, .THUMB, .T32, {}, {}},
	{.MOV, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_HI, .RM_T16_HI, .NONE, .NONE, .NONE, .NONE}, 0x4600, 0xFF00, .THUMB, .T32, {}, {}},
	// Bits 2:0 should be zero. A BX where they are not is still BX to every
	// disassembler, and is printed as one; a BLX where they are not is not
	// an instruction at all, or (on v8-M) is BLXNS.
	{.BX, {.GPR, .NONE, .NONE, .NONE, .NONE, .NONE}, {.RM_T16_HI, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x4700, 0xFF80, .THUMB, .T32, {branch = true, writes_pc = true}, {}},
	{.BLX, {.GPR, .NONE, .NONE, .NONE, .NONE, .NONE}, {.RM_T16_HI, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x4780, 0xFF87, .V5T, .T32, {branch = true, writes_pc = true}, {}},
	{.BXNS, {.GPR, .NONE, .NONE, .NONE, .NONE, .NONE}, {.RM_T16_HI, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x4704, 0xFF84, .V8M_SE, .T32, {branch = true, writes_pc = true}, {}},
	{.BLXNS, {.GPR, .NONE, .NONE, .NONE, .NONE, .NONE}, {.RM_T16_HI, .NONE, .NONE, .NONE, .NONE, .NONE}, 0x4784, 0xFF84, .V8M_SE, .T32, {branch = true, writes_pc = true}, {}},

	// =========================================================================
	// 16-bit: loads and stores
	// =========================================================================
	//   01001 Rt imm8               LDR (literal)
	//   0101 op(3) Rm Rn Rt         register offset
	//   011 B L imm5 Rn Rt          word / byte, immediate offset
	//   1000 L imm5 Rn Rt           halfword, immediate offset
	//   1001 L Rt imm8              word, SP-relative
	{.LDR, {.GPR_LOW, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_10_8, .MEM_T16_LITERAL, .NONE, .NONE, .NONE, .NONE}, 0x4800, 0xF800, .THUMB, .T32, {}, {}},
	{.STR,   {.GPR_LOW, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .MEM_T16_REG, .NONE, .NONE, .NONE, .NONE}, 0x5000, 0xFE00, .THUMB, .T32, {}, {}},
	{.STRH,  {.GPR_LOW, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .MEM_T16_REG, .NONE, .NONE, .NONE, .NONE}, 0x5200, 0xFE00, .THUMB, .T32, {}, {}},
	{.STRB,  {.GPR_LOW, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .MEM_T16_REG, .NONE, .NONE, .NONE, .NONE}, 0x5400, 0xFE00, .THUMB, .T32, {}, {}},
	{.LDRSB, {.GPR_LOW, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .MEM_T16_REG, .NONE, .NONE, .NONE, .NONE}, 0x5600, 0xFE00, .THUMB, .T32, {}, {}},
	{.LDR,   {.GPR_LOW, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .MEM_T16_REG, .NONE, .NONE, .NONE, .NONE}, 0x5800, 0xFE00, .THUMB, .T32, {}, {}},
	{.LDRH,  {.GPR_LOW, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .MEM_T16_REG, .NONE, .NONE, .NONE, .NONE}, 0x5A00, 0xFE00, .THUMB, .T32, {}, {}},
	{.LDRB,  {.GPR_LOW, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .MEM_T16_REG, .NONE, .NONE, .NONE, .NONE}, 0x5C00, 0xFE00, .THUMB, .T32, {}, {}},
	{.LDRSH, {.GPR_LOW, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .MEM_T16_REG, .NONE, .NONE, .NONE, .NONE}, 0x5E00, 0xFE00, .THUMB, .T32, {}, {}},
	{.STR,  {.GPR_LOW, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .MEM_T16_IMM5_W, .NONE, .NONE, .NONE, .NONE}, 0x6000, 0xF800, .THUMB, .T32, {}, {}},
	{.LDR,  {.GPR_LOW, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .MEM_T16_IMM5_W, .NONE, .NONE, .NONE, .NONE}, 0x6800, 0xF800, .THUMB, .T32, {}, {}},
	{.STRB, {.GPR_LOW, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .MEM_T16_IMM5_B, .NONE, .NONE, .NONE, .NONE}, 0x7000, 0xF800, .THUMB, .T32, {}, {}},
	{.LDRB, {.GPR_LOW, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .MEM_T16_IMM5_B, .NONE, .NONE, .NONE, .NONE}, 0x7800, 0xF800, .THUMB, .T32, {}, {}},
	{.STRH, {.GPR_LOW, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .MEM_T16_IMM5_H, .NONE, .NONE, .NONE, .NONE}, 0x8000, 0xF800, .THUMB, .T32, {}, {}},
	{.LDRH, {.GPR_LOW, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .MEM_T16_IMM5_H, .NONE, .NONE, .NONE, .NONE}, 0x8800, 0xF800, .THUMB, .T32, {}, {}},
	{.STR,  {.GPR_LOW, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_10_8, .MEM_T16_SP_IMM8, .NONE, .NONE, .NONE, .NONE}, 0x9000, 0xF800, .THUMB, .T32, {}, {}},
	{.LDR,  {.GPR_LOW, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_10_8, .MEM_T16_SP_IMM8, .NONE, .NONE, .NONE, .NONE}, 0x9800, 0xF800, .THUMB, .T32, {}, {}},

	// =========================================================================
	// 16-bit: PC- and SP-relative addresses
	// =========================================================================
	{.ADR, {.GPR_LOW, .REL_LDR_LITERAL, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_10_8, .REL_T16_ADR, .NONE, .NONE, .NONE, .NONE}, 0xA000, 0xF800, .THUMB, .T32, {}, {}},
	{.ADD, {.GPR_LOW, .GPR, .IMM, .NONE, .NONE, .NONE}, {.RD_T16_10_8, .IMPL_SP, .IMM8_T16_SCALED4, .NONE, .NONE, .NONE}, 0xA800, 0xF800, .THUMB, .T32, {}, {}},

	// =========================================================================
	// 16-bit: miscellaneous
	// =========================================================================
	//   1011 0000 S imm7            ADD / SUB SP, SP, #imm
	//   1011 o0i1 imm5 Rn           CBZ / CBNZ
	//   1011 0010 op Rm Rd          SXTH / SXTB / UXTH / UXTB
	//   1011 010M list              PUSH
	//   1011 0110 000x x(000)       SETPAN  (bit 4 and bits 2:0 are not checked)
	//   1011 0110 0101 E000         SETEND
	//   1011 0110 011 m 0AIF        CPS
	//   1011 1010 op Rm Rd          REV / REV16 / HLT / REVSH
	//   1011 110P list              POP
	//   1011 1110 imm8              BKPT
	//   1011 1111 cond mask         IT, or a hint when the mask is zero
	{.ADD, {.GPR, .IMM, .NONE, .NONE, .NONE, .NONE}, {.IMPL_SP, .IMM7_T16_SCALED4, .NONE, .NONE, .NONE, .NONE}, 0xB000, 0xFF80, .THUMB, .T32, {}, {}},
	{.SUB, {.GPR, .IMM, .NONE, .NONE, .NONE, .NONE}, {.IMPL_SP, .IMM7_T16_SCALED4, .NONE, .NONE, .NONE, .NONE}, 0xB080, 0xFF80, .THUMB, .T32, {}, {}},
	{.CBZ,  {.GPR_LOW, .REL8, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .BRANCH_CBZ, .NONE, .NONE, .NONE, .NONE}, 0xB100, 0xFD00, .V6T2, .T32, {branch = true, cond_branch = true, writes_pc = true}, {}},
	{.CBNZ, {.GPR_LOW, .REL8, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .BRANCH_CBZ, .NONE, .NONE, .NONE, .NONE}, 0xB900, 0xFD00, .V6T2, .T32, {branch = true, cond_branch = true, writes_pc = true}, {}},
	{.SXTH, {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0xB200, 0xFFC0, .V6, .T32, {}, {}},
	{.SXTB, {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0xB240, 0xFFC0, .V6, .T32, {}, {}},
	{.UXTH, {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0xB280, 0xFFC0, .V6, .T32, {}, {}},
	{.UXTB, {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0xB2C0, 0xFFC0, .V6, .T32, {}, {}},
	{.PUSH, {.GPR_LIST, .NONE, .NONE, .NONE, .NONE, .NONE}, {.T16_REG_LIST_LR, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xB400, 0xFE00, .THUMB, .T32, {}, {}},
	{.SETPAN, {.IMM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.SETPAN_IMM_T16, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xB610, 0xFFE0, .V8, .T32, {a_profile_only = true}, {}},
	{.SETEND, {.IMM_ENDIAN, .NONE, .NONE, .NONE, .NONE, .NONE}, {.SETEND_ENDIAN_T16, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xB650, 0xFFF7, .V6, .T32, {deprecated = true, a_profile_only = true}, {}},
	{.CPSIE, {.IMM_IFLAGS, .NONE, .NONE, .NONE, .NONE, .NONE}, {.CPS_IFLAGS_T16, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xB660, 0xFFF8, .V6, .T32, {}, {}},
	{.CPSID, {.IMM_IFLAGS, .NONE, .NONE, .NONE, .NONE, .NONE}, {.CPS_IFLAGS_T16, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xB670, 0xFFF8, .V6, .T32, {}, {}},
	{.REV,   {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0xBA00, 0xFFC0, .V6, .T32, {}, {}},
	{.REV16, {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0xBA40, 0xFFC0, .V6, .T32, {}, {}},
	{.HLT,   {.IMM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.IMM6_T16, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xBA80, 0xFFC0, .V8, .T32, {a_profile_only = true}, {}},
	{.REVSH, {.GPR_LOW, .GPR_LOW, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_LO, .RM_T16_LO, .NONE, .NONE, .NONE, .NONE}, 0xBAC0, 0xFFC0, .V6, .T32, {}, {}},
	{.POP, {.GPR_LIST, .NONE, .NONE, .NONE, .NONE, .NONE}, {.T16_REG_LIST_PC, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xBC00, 0xFE00, .THUMB, .T32, {}, {}},
	{.BKPT, {.IMM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.IMM8_T16, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xBE00, 0xFF00, .V5T, .T32, {}, {}},
	{.IT, {.COND, .IMM4, .NONE, .NONE, .NONE, .NONE}, {.IT_FIRSTCOND, .IT_MASK_FIELD, .NONE, .NONE, .NONE, .NONE}, 0xBF00, 0xFF00, .V6T2, .T32, {}, {}},
	{.NOP,   {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xBF00, 0xFFFF, .V6T2, .T32, {}, {}},
	{.YIELD, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xBF10, 0xFFFF, .V6T2, .T32, {}, {}},
	{.WFE,   {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xBF20, 0xFFFF, .V6T2, .T32, {}, {}},
	{.WFI,   {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xBF30, 0xFFFF, .V6T2, .T32, {}, {}},
	{.SEV,   {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xBF40, 0xFFFF, .V6T2, .T32, {}, {}},
	{.SEVL,  {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xBF50, 0xFFFF, .V8, .T32, {a_profile_only = true}, {}},
	{.HINT, {.IMM_HINT, .NONE, .NONE, .NONE, .NONE, .NONE}, {.IMM4_T16_HINT, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xBF00, 0xFF0F, .V6T2, .T32, {}, {}},

	// =========================================================================
	// 16-bit: load/store multiple, branches, exceptions
	// =========================================================================
	//   1100 L Rn list              STM Rn!, / LDM Rn{!},
	//   1101 cond imm8              B<c>   (cond 1110 is UDF, 1111 SVC)
	//   11100 imm11                 B
	{.STM, {.GPR_LOW, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_10_8, .T16_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0xC000, 0xF800, .THUMB, .T32, {}, {}},
	{.LDM, {.GPR_LOW, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RD_T16_10_8, .T16_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0xC800, 0xF800, .THUMB, .T32, {}, {}},
	{.B, {.REL8, .NONE, .NONE, .NONE, .NONE, .NONE}, {.BRANCH_8_T16, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xD000, 0xF000, .THUMB, .T32, {branch = true, cond_branch = true, writes_pc = true, thumb_condition = true}, {}},
	{.UDF, {.IMM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.IMM8_T16, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xDE00, 0xFF00, .THUMB, .T32, {}, {}},
	{.SVC, {.IMM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.IMM8_T16, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xDF00, 0xFF00, .THUMB, .T32, {}, {}},
	{.B, {.REL11, .NONE, .NONE, .NONE, .NONE, .NONE}, {.BRANCH_11_T16, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xE000, 0xF800, .THUMB, .T32, {branch = true, writes_pc = true}, {}},

	// =========================================================================
	// 32-bit: data processing (modified immediate)
	// =========================================================================
	//   11110 i 0 op(4) S Rn | 0 imm3 Rd imm8
	{.AND, {.GPR, .GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE}, 0xF0000000, 0xFBF08000, .V6T2, .T32, {}, {}},
	{.AND, {.GPR, .GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE}, 0xF0100000, 0xFBF08000, .V6T2, .T32, {sets_flags = true}, {}},
	{.TST, {.GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE, .NONE}, {.RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE, .NONE}, 0xF0100F00, 0xFBF08F00, .V6T2, .T32, {}, {}},
	{.BIC, {.GPR, .GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE}, 0xF0200000, 0xFBF08000, .V6T2, .T32, {}, {}},
	{.BIC, {.GPR, .GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE}, 0xF0300000, 0xFBF08000, .V6T2, .T32, {sets_flags = true}, {}},
	{.ORR, {.GPR, .GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE}, 0xF0400000, 0xFBF08000, .V6T2, .T32, {}, {}},
	{.ORR, {.GPR, .GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE}, 0xF0500000, 0xFBF08000, .V6T2, .T32, {sets_flags = true}, {}},
	{.MOV, {.GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE, .NONE}, 0xF04F0000, 0xFBFF8000, .V6T2, .T32, {}, {}},
	{.MOV, {.GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE, .NONE}, 0xF05F0000, 0xFBFF8000, .V6T2, .T32, {sets_flags = true}, {}},
	{.ORN, {.GPR, .GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE}, 0xF0600000, 0xFBF08000, .V6T2, .T32, {}, {}},
	{.ORN, {.GPR, .GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE}, 0xF0700000, 0xFBF08000, .V6T2, .T32, {sets_flags = true}, {}},
	{.MVN, {.GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE, .NONE}, 0xF06F0000, 0xFBFF8000, .V6T2, .T32, {}, {}},
	{.MVN, {.GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE, .NONE}, 0xF07F0000, 0xFBFF8000, .V6T2, .T32, {sets_flags = true}, {}},
	{.EOR, {.GPR, .GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE}, 0xF0800000, 0xFBF08000, .V6T2, .T32, {}, {}},
	{.EOR, {.GPR, .GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE}, 0xF0900000, 0xFBF08000, .V6T2, .T32, {sets_flags = true}, {}},
	{.TEQ, {.GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE, .NONE}, {.RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE, .NONE}, 0xF0900F00, 0xFBF08F00, .V6T2, .T32, {}, {}},
	{.ADD, {.GPR, .GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE}, 0xF1000000, 0xFBF08000, .V6T2, .T32, {}, {}},
	{.ADD, {.GPR, .GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE}, 0xF1100000, 0xFBF08000, .V6T2, .T32, {sets_flags = true}, {}},
	{.CMN, {.GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE, .NONE}, {.RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE, .NONE}, 0xF1100F00, 0xFBF08F00, .V6T2, .T32, {}, {}},
	{.ADC, {.GPR, .GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE}, 0xF1400000, 0xFBF08000, .V6T2, .T32, {}, {}},
	{.ADC, {.GPR, .GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE}, 0xF1500000, 0xFBF08000, .V6T2, .T32, {sets_flags = true}, {}},
	{.SBC, {.GPR, .GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE}, 0xF1600000, 0xFBF08000, .V6T2, .T32, {}, {}},
	{.SBC, {.GPR, .GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE}, 0xF1700000, 0xFBF08000, .V6T2, .T32, {sets_flags = true}, {}},
	{.SUB, {.GPR, .GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE}, 0xF1A00000, 0xFBF08000, .V6T2, .T32, {}, {}},
	{.SUB, {.GPR, .GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE}, 0xF1B00000, 0xFBF08000, .V6T2, .T32, {sets_flags = true}, {}},
	{.CMP, {.GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE, .NONE}, {.RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE, .NONE}, 0xF1B00F00, 0xFBF08F00, .V6T2, .T32, {}, {}},
	{.RSB, {.GPR, .GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE}, 0xF1C00000, 0xFBF08000, .V6T2, .T32, {}, {}},
	{.RSB, {.GPR, .GPR, .IMM_T32_MOD, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .T32_IMM_MOD, .NONE, .NONE, .NONE}, 0xF1D00000, 0xFBF08000, .V6T2, .T32, {sets_flags = true}, {}},

	// =========================================================================
	// 32-bit: data processing (plain binary immediate)
	// =========================================================================
	//   11110 i 1 op(5) Rn | 0 imm3 Rd imm8
	{.ADDW, {.GPR, .GPR, .IMM12, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .T32_IMM12, .NONE, .NONE, .NONE}, 0xF2000000, 0xFBF08000, .V6T2, .T32, {}, {}},
	{.ADR, {.GPR, .REL_LDR_LITERAL, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .REL_T32_ADR_ADD, .NONE, .NONE, .NONE, .NONE}, 0xF20F0000, 0xFBFF8000, .V6T2, .T32, {}, {}},
	{.MOVW, {.GPR, .IMM16_LO_HI, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .T32_IMM16, .NONE, .NONE, .NONE, .NONE}, 0xF2400000, 0xFBF08000, .V6T2, .T32, {}, {}},
	{.SUBW, {.GPR, .GPR, .IMM12, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .T32_IMM12, .NONE, .NONE, .NONE}, 0xF2A00000, 0xFBF08000, .V6T2, .T32, {}, {}},
	{.ADR, {.GPR, .REL_LDR_LITERAL, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .REL_T32_ADR_SUB, .NONE, .NONE, .NONE, .NONE}, 0xF2AF0000, 0xFBFF8000, .V6T2, .T32, {}, {}},
	{.MOVT, {.GPR, .IMM16_LO_HI, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .T32_IMM16, .NONE, .NONE, .NONE, .NONE}, 0xF2C00000, 0xFBF08000, .V6T2, .T32, {}, {}},
	// The saturates and the bitfield operations have no i: bit 26 is 0, and
	// so is bit 5.
	{.SSAT, {.GPR, .IMM4_SAT, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .SAT_IMM5_T32, .RN_T32_SAT, .NONE, .NONE, .NONE}, 0xF3000000, 0xFFD08020, .V6T2, .T32, {}, {}},
	{.SSAT16, {.GPR, .IMM4_SAT, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .SAT16_IMM4_T32, .RN_T32, .NONE, .NONE, .NONE}, 0xF3200000, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SBFX, {.GPR, .GPR, .IMM5, .IMM5_W, .NONE, .NONE}, {.RD_T32, .RN_T32, .BFI_LSB_T32, .BFX_WIDTH_T32, .NONE, .NONE}, 0xF3400000, 0xFFF08020, .V6T2, .T32, {}, {}},
	{.BFI, {.GPR, .GPR, .IMM5, .IMM5_W, .NONE, .NONE}, {.RD_T32, .RN_T32, .BFI_LSB_T32, .BFI_MSB_T32, .NONE, .NONE}, 0xF3600000, 0xFFF08020, .V6T2, .T32, {}, {}},
	{.BFC, {.GPR, .IMM5, .IMM5_W, .NONE, .NONE, .NONE}, {.RD_T32, .BFI_LSB_T32, .BFI_MSB_T32, .NONE, .NONE, .NONE}, 0xF36F0000, 0xFFFF8020, .V6T2, .T32, {}, {}},
	{.USAT, {.GPR, .IMM4_SAT, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .SAT_IMM5_U_T32, .RN_T32_SAT, .NONE, .NONE, .NONE}, 0xF3800000, 0xFFD08020, .V6T2, .T32, {}, {}},
	{.USAT16, {.GPR, .IMM4_SAT, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .SAT16_IMM4_U_T32, .RN_T32, .NONE, .NONE, .NONE}, 0xF3A00000, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.UBFX, {.GPR, .GPR, .IMM5, .IMM5_W, .NONE, .NONE}, {.RD_T32, .RN_T32, .BFI_LSB_T32, .BFX_WIDTH_T32, .NONE, .NONE}, 0xF3C00000, 0xFFF08020, .V6T2, .T32, {}, {}},

	// =========================================================================
	// 32-bit: data processing (shifted register)
	// =========================================================================
	//   11101 01 op(4) S Rn | (0) imm3 Rd imm2 type Rm
	{.AND, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xEA000000, 0xFFF08000, .V6T2, .T32, {}, {}},
	{.AND, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xEA100000, 0xFFF08000, .V6T2, .T32, {sets_flags = true}, {}},
	{.TST, {.GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE, .NONE}, {.RN_T32, .RM_T32, .NONE, .NONE, .NONE, .NONE}, 0xEA100F00, 0xFFF08F00, .V6T2, .T32, {}, {}},
	{.BIC, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xEA200000, 0xFFF08000, .V6T2, .T32, {}, {}},
	{.BIC, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xEA300000, 0xFFF08000, .V6T2, .T32, {sets_flags = true}, {}},
	{.ORR, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xEA400000, 0xFFF08000, .V6T2, .T32, {}, {}},
	{.ORR, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xEA500000, 0xFFF08000, .V6T2, .T32, {sets_flags = true}, {}},
	{.MOV, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE, .NONE, .NONE}, 0xEA4F0000, 0xFFFFF0F0, .V6T2, .T32, {}, {}},
	{.LSL, {.GPR, .GPR, .IMM5, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32, .T32_IMM_SHIFT, .NONE, .NONE, .NONE}, 0xEA4F0000, 0xFFFF8030, .V6T2, .T32, {}, {}},
	{.LSR, {.GPR, .GPR, .IMM5, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32, .T32_IMM_SHIFT_32, .NONE, .NONE, .NONE}, 0xEA4F0010, 0xFFFF8030, .V6T2, .T32, {}, {}},
	{.ASR, {.GPR, .GPR, .IMM5, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32, .T32_IMM_SHIFT_32, .NONE, .NONE, .NONE}, 0xEA4F0020, 0xFFFF8030, .V6T2, .T32, {}, {}},
	{.ROR, {.GPR, .GPR, .IMM5, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32, .T32_IMM_SHIFT, .NONE, .NONE, .NONE}, 0xEA4F0030, 0xFFFF8030, .V6T2, .T32, {}, {}},
	{.RRX, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE, .NONE, .NONE}, 0xEA4F0030, 0xFFFFF0F0, .V6T2, .T32, {}, {}},
	{.MOV, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE, .NONE, .NONE}, 0xEA5F0000, 0xFFFFF0F0, .V6T2, .T32, {sets_flags = true}, {}},
	{.LSL, {.GPR, .GPR, .IMM5, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32, .T32_IMM_SHIFT, .NONE, .NONE, .NONE}, 0xEA5F0000, 0xFFFF8030, .V6T2, .T32, {sets_flags = true}, {}},
	{.LSR, {.GPR, .GPR, .IMM5, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32, .T32_IMM_SHIFT_32, .NONE, .NONE, .NONE}, 0xEA5F0010, 0xFFFF8030, .V6T2, .T32, {sets_flags = true}, {}},
	{.ASR, {.GPR, .GPR, .IMM5, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32, .T32_IMM_SHIFT_32, .NONE, .NONE, .NONE}, 0xEA5F0020, 0xFFFF8030, .V6T2, .T32, {sets_flags = true}, {}},
	{.ROR, {.GPR, .GPR, .IMM5, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32, .T32_IMM_SHIFT, .NONE, .NONE, .NONE}, 0xEA5F0030, 0xFFFF8030, .V6T2, .T32, {sets_flags = true}, {}},
	{.RRX, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE, .NONE, .NONE}, 0xEA5F0030, 0xFFFFF0F0, .V6T2, .T32, {sets_flags = true}, {}},
	{.ORN, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xEA600000, 0xFFF08000, .V6T2, .T32, {}, {}},
	{.ORN, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xEA700000, 0xFFF08000, .V6T2, .T32, {sets_flags = true}, {}},
	{.MVN, {.GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE, .NONE, .NONE}, 0xEA6F0000, 0xFFFF8000, .V6T2, .T32, {}, {}},
	{.MVN, {.GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32, .NONE, .NONE, .NONE, .NONE}, 0xEA7F0000, 0xFFFF8000, .V6T2, .T32, {sets_flags = true}, {}},
	{.EOR, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xEA800000, 0xFFF08000, .V6T2, .T32, {}, {}},
	{.EOR, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xEA900000, 0xFFF08000, .V6T2, .T32, {sets_flags = true}, {}},
	{.TEQ, {.GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE, .NONE}, {.RN_T32, .RM_T32, .NONE, .NONE, .NONE, .NONE}, 0xEA900F00, 0xFFF08F00, .V6T2, .T32, {}, {}},
	{.ADD, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xEB000000, 0xFFF08000, .V6T2, .T32, {}, {}},
	{.ADD, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xEB100000, 0xFFF08000, .V6T2, .T32, {sets_flags = true}, {}},
	{.CMN, {.GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE, .NONE}, {.RN_T32, .RM_T32, .NONE, .NONE, .NONE, .NONE}, 0xEB100F00, 0xFFF08F00, .V6T2, .T32, {}, {}},
	{.ADC, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xEB400000, 0xFFF08000, .V6T2, .T32, {}, {}},
	{.ADC, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xEB500000, 0xFFF08000, .V6T2, .T32, {sets_flags = true}, {}},
	{.SBC, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xEB600000, 0xFFF08000, .V6T2, .T32, {}, {}},
	{.SBC, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xEB700000, 0xFFF08000, .V6T2, .T32, {sets_flags = true}, {}},
	{.SUB, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xEBA00000, 0xFFF08000, .V6T2, .T32, {}, {}},
	{.SUB, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xEBB00000, 0xFFF08000, .V6T2, .T32, {sets_flags = true}, {}},
	{.CMP, {.GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE, .NONE}, {.RN_T32, .RM_T32, .NONE, .NONE, .NONE, .NONE}, 0xEBB00F00, 0xFFF08F00, .V6T2, .T32, {}, {}},
	{.RSB, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xEBC00000, 0xFFF08000, .V6T2, .T32, {}, {}},
	{.RSB, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xEBD00000, 0xFFF08000, .V6T2, .T32, {sets_flags = true}, {}},
	{.PKHBT, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xEAC00000, 0xFFF08030, .V6T2, .T32, {}, {}},
	{.PKHTB, {.GPR, .GPR, .GPR_SHIFTED, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xEAC00020, 0xFFF08030, .V6T2, .T32, {}, {}},

	// =========================================================================
	// 32-bit: data processing (register)
	// =========================================================================
	//   11111 010 op1(4) Rn | 1111 Rd op2(4) Rm
	{.LSL, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFA00F000, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.LSL, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFA10F000, 0xFFF0F0F0, .V6T2, .T32, {sets_flags = true}, {}},
	{.LSR, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFA20F000, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.LSR, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFA30F000, 0xFFF0F0F0, .V6T2, .T32, {sets_flags = true}, {}},
	{.ASR, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFA40F000, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.ASR, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFA50F000, 0xFFF0F0F0, .V6T2, .T32, {sets_flags = true}, {}},
	{.ROR, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFA60F000, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.ROR, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFA70F000, 0xFFF0F0F0, .V6T2, .T32, {sets_flags = true}, {}},
	{.SXTAH, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32_ROTATED, .NONE, .NONE, .NONE}, 0xFA00F080, 0xFFF0F0C0, .V6T2, .T32, {}, {}},
	{.SXTH, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32_ROTATED, .NONE, .NONE, .NONE, .NONE}, 0xFA0FF080, 0xFFFFF0C0, .V6T2, .T32, {}, {}},
	{.UXTAH, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32_ROTATED, .NONE, .NONE, .NONE}, 0xFA10F080, 0xFFF0F0C0, .V6T2, .T32, {}, {}},
	{.UXTH, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32_ROTATED, .NONE, .NONE, .NONE, .NONE}, 0xFA1FF080, 0xFFFFF0C0, .V6T2, .T32, {}, {}},
	{.SXTAB16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32_ROTATED, .NONE, .NONE, .NONE}, 0xFA20F080, 0xFFF0F0C0, .V6T2, .T32, {}, {}},
	{.SXTB16, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32_ROTATED, .NONE, .NONE, .NONE, .NONE}, 0xFA2FF080, 0xFFFFF0C0, .V6T2, .T32, {}, {}},
	{.UXTAB16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32_ROTATED, .NONE, .NONE, .NONE}, 0xFA30F080, 0xFFF0F0C0, .V6T2, .T32, {}, {}},
	{.UXTB16, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32_ROTATED, .NONE, .NONE, .NONE, .NONE}, 0xFA3FF080, 0xFFFFF0C0, .V6T2, .T32, {}, {}},
	{.SXTAB, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32_ROTATED, .NONE, .NONE, .NONE}, 0xFA40F080, 0xFFF0F0C0, .V6T2, .T32, {}, {}},
	{.SXTB, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32_ROTATED, .NONE, .NONE, .NONE, .NONE}, 0xFA4FF080, 0xFFFFF0C0, .V6T2, .T32, {}, {}},
	{.UXTAB, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32_ROTATED, .NONE, .NONE, .NONE}, 0xFA50F080, 0xFFF0F0C0, .V6T2, .T32, {}, {}},
	{.UXTB, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32_ROTATED, .NONE, .NONE, .NONE, .NONE}, 0xFA5FF080, 0xFFFFF0C0, .V6T2, .T32, {}, {}},
	{.SADD8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFA80F000, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SADD16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFA90F000, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SASX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAA0F000, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SSUB8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAC0F000, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SSUB16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAD0F000, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SSAX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAE0F000, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.QADD8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFA80F010, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.QADD16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFA90F010, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.QASX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAA0F010, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.QSUB8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAC0F010, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.QSUB16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAD0F010, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.QSAX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAE0F010, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SHADD8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFA80F020, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SHADD16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFA90F020, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SHASX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAA0F020, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SHSUB8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAC0F020, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SHSUB16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAD0F020, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SHSAX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAE0F020, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.UADD8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFA80F040, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.UADD16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFA90F040, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.UASX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAA0F040, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.USUB8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAC0F040, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.USUB16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAD0F040, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.USAX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAE0F040, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.UQADD8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFA80F050, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.UQADD16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFA90F050, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.UQASX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAA0F050, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.UQSUB8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAC0F050, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.UQSUB16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAD0F050, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.UQSAX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAE0F050, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.UHADD8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFA80F060, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.UHADD16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFA90F060, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.UHASX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAA0F060, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.UHSUB8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAC0F060, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.UHSUB16, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAD0F060, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.UHSAX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAE0F060, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.QADD, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32, .RN_T32, .NONE, .NONE, .NONE}, 0xFA80F080, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.QDADD, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32, .RN_T32, .NONE, .NONE, .NONE}, 0xFA80F090, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.QSUB, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32, .RN_T32, .NONE, .NONE, .NONE}, 0xFA80F0A0, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.QDSUB, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32, .RN_T32, .NONE, .NONE, .NONE}, 0xFA80F0B0, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.REV, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32_TWICE, .NONE, .NONE, .NONE, .NONE}, 0xFA90F080, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.REV16, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32_TWICE, .NONE, .NONE, .NONE, .NONE}, 0xFA90F090, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.RBIT, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32_TWICE, .NONE, .NONE, .NONE, .NONE}, 0xFA90F0A0, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.REVSH, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32_TWICE, .NONE, .NONE, .NONE, .NONE}, 0xFA90F0B0, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SEL, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAA0F080, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.CLZ, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .RM_T32_TWICE, .NONE, .NONE, .NONE, .NONE}, 0xFAB0F080, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.CRC32B, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAC0F080, 0xFFF0F0F0, .CRC32, .T32, {}, {}},
	{.CRC32H, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAC0F090, 0xFFF0F0F0, .CRC32, .T32, {}, {}},
	{.CRC32W, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAC0F0A0, 0xFFF0F0F0, .CRC32, .T32, {}, {}},
	{.CRC32CB, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAD0F080, 0xFFF0F0F0, .CRC32, .T32, {}, {}},
	{.CRC32CH, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAD0F090, 0xFFF0F0F0, .CRC32, .T32, {}, {}},
	{.CRC32CW, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFAD0F0A0, 0xFFF0F0F0, .CRC32, .T32, {}, {}},

	// =========================================================================
	// 32-bit: multiply, multiply-accumulate and divide
	// =========================================================================
	//   11111 0110 op1(3) Rn | Ra Rd 00 op2(2) Rm      (Ra = 1111 drops the accumulate)
	{.MUL, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFB00F000, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.MLA, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .RA_T32, .NONE, .NONE}, 0xFB000000, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.MLS, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .RA_T32, .NONE, .NONE}, 0xFB000010, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMULBB, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFB10F000, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SMLABB, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .RA_T32, .NONE, .NONE}, 0xFB100000, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMULBT, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFB10F010, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SMLABT, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .RA_T32, .NONE, .NONE}, 0xFB100010, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMULTB, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFB10F020, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SMLATB, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .RA_T32, .NONE, .NONE}, 0xFB100020, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMULTT, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFB10F030, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SMLATT, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .RA_T32, .NONE, .NONE}, 0xFB100030, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMUAD, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFB20F000, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SMLAD, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .RA_T32, .NONE, .NONE}, 0xFB200000, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMUADX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFB20F010, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SMLADX, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .RA_T32, .NONE, .NONE}, 0xFB200010, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMULWB, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFB30F000, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SMLAWB, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .RA_T32, .NONE, .NONE}, 0xFB300000, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMULWT, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFB30F010, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SMLAWT, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .RA_T32, .NONE, .NONE}, 0xFB300010, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMUSD, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFB40F000, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SMLSD, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .RA_T32, .NONE, .NONE}, 0xFB400000, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMUSDX, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFB40F010, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SMLSDX, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .RA_T32, .NONE, .NONE}, 0xFB400010, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMMUL, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFB50F000, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SMMLA, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .RA_T32, .NONE, .NONE}, 0xFB500000, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMMULR, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFB50F010, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.SMMLAR, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .RA_T32, .NONE, .NONE}, 0xFB500010, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMMLS, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .RA_T32, .NONE, .NONE}, 0xFB600000, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMMLSR, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .RA_T32, .NONE, .NONE}, 0xFB600010, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.USAD8, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFB70F000, 0xFFF0F0F0, .V6T2, .T32, {}, {}},
	{.USADA8, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .RA_T32, .NONE, .NONE}, 0xFB700000, 0xFFF000F0, .V6T2, .T32, {}, {}},
	//   11111 0111 op1(3) Rn | RdLo RdHi op2(4) Rm
	{.SMULL, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RT_T32, .RD_T32, .RN_T32, .RM_T32, .NONE, .NONE}, 0xFB800000, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.UMULL, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RT_T32, .RD_T32, .RN_T32, .RM_T32, .NONE, .NONE}, 0xFBA00000, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMLAL, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RT_T32, .RD_T32, .RN_T32, .RM_T32, .NONE, .NONE}, 0xFBC00000, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMLALBB, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RT_T32, .RD_T32, .RN_T32, .RM_T32, .NONE, .NONE}, 0xFBC00080, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMLALBT, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RT_T32, .RD_T32, .RN_T32, .RM_T32, .NONE, .NONE}, 0xFBC00090, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMLALTB, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RT_T32, .RD_T32, .RN_T32, .RM_T32, .NONE, .NONE}, 0xFBC000A0, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMLALTT, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RT_T32, .RD_T32, .RN_T32, .RM_T32, .NONE, .NONE}, 0xFBC000B0, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMLALD, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RT_T32, .RD_T32, .RN_T32, .RM_T32, .NONE, .NONE}, 0xFBC000C0, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMLALDX, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RT_T32, .RD_T32, .RN_T32, .RM_T32, .NONE, .NONE}, 0xFBC000D0, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMLSLD, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RT_T32, .RD_T32, .RN_T32, .RM_T32, .NONE, .NONE}, 0xFBD000C0, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SMLSLDX, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RT_T32, .RD_T32, .RN_T32, .RM_T32, .NONE, .NONE}, 0xFBD000D0, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.UMLAL, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RT_T32, .RD_T32, .RN_T32, .RM_T32, .NONE, .NONE}, 0xFBE00000, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.UMAAL, {.GPR, .GPR, .GPR, .GPR, .NONE, .NONE}, {.RT_T32, .RD_T32, .RN_T32, .RM_T32, .NONE, .NONE}, 0xFBE00060, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.SDIV, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFB90F0F0, 0xFFF0F0F0, .DIV, .T32, {}, {}},
	{.UDIV, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFBB0F0F0, 0xFFF0F0F0, .DIV, .T32, {}, {}},

	// =========================================================================
	// 32-bit: loads and stores, single register
	// =========================================================================
	//   1111 100 S op(2) L Rn | Rt ...   imm12 when bit 23 is set, else imm8 / register
	//   Rn = 1111 is the literal form; Rt = 1111 on a byte or halfword load is a preload.
	{.STR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM12, .NONE, .NONE, .NONE, .NONE}, 0xF8C00000, 0xFFF00000, .V6T2, .T32, {}, {}},
	{.STR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_NEG, .NONE, .NONE, .NONE, .NONE}, 0xF8400C00, 0xFFF00F00, .V6T2, .T32, {}, {}},
	{.STR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_POST, .NONE, .NONE, .NONE, .NONE}, 0xF8400900, 0xFFF00D00, .V6T2, .T32, {}, {}},
	{.STR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_PRE, .NONE, .NONE, .NONE, .NONE}, 0xF8400D00, 0xFFF00D00, .V6T2, .T32, {}, {}},
	{.STRT, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_POS, .NONE, .NONE, .NONE, .NONE}, 0xF8400E00, 0xFFF00F00, .V6T2, .T32, {}, {}},
	{.STR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_REG, .NONE, .NONE, .NONE, .NONE}, 0xF8400000, 0xFFF00FC0, .V6T2, .T32, {}, {}},
	{.LDR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM12, .NONE, .NONE, .NONE, .NONE}, 0xF8D00000, 0xFFF00000, .V6T2, .T32, {}, {}},
	{.LDR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_NEG, .NONE, .NONE, .NONE, .NONE}, 0xF8500C00, 0xFFF00F00, .V6T2, .T32, {}, {}},
	{.LDR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_POST, .NONE, .NONE, .NONE, .NONE}, 0xF8500900, 0xFFF00D00, .V6T2, .T32, {}, {}},
	{.LDR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_PRE, .NONE, .NONE, .NONE, .NONE}, 0xF8500D00, 0xFFF00D00, .V6T2, .T32, {}, {}},
	{.LDRT, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_POS, .NONE, .NONE, .NONE, .NONE}, 0xF8500E00, 0xFFF00F00, .V6T2, .T32, {}, {}},
	{.LDR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_REG, .NONE, .NONE, .NONE, .NONE}, 0xF8500000, 0xFFF00FC0, .V6T2, .T32, {}, {}},
	{.LDR, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_LITERAL, .NONE, .NONE, .NONE, .NONE}, 0xF85F0000, 0xFF7F0000, .V6T2, .T32, {preferred = true}, {}},
	{.STRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM12, .NONE, .NONE, .NONE, .NONE}, 0xF8800000, 0xFFF00000, .V6T2, .T32, {}, {}},
	{.STRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_NEG, .NONE, .NONE, .NONE, .NONE}, 0xF8000C00, 0xFFF00F00, .V6T2, .T32, {}, {}},
	{.STRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_POST, .NONE, .NONE, .NONE, .NONE}, 0xF8000900, 0xFFF00D00, .V6T2, .T32, {}, {}},
	{.STRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_PRE, .NONE, .NONE, .NONE, .NONE}, 0xF8000D00, 0xFFF00D00, .V6T2, .T32, {}, {}},
	{.STRBT, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_POS, .NONE, .NONE, .NONE, .NONE}, 0xF8000E00, 0xFFF00F00, .V6T2, .T32, {}, {}},
	{.STRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_REG, .NONE, .NONE, .NONE, .NONE}, 0xF8000000, 0xFFF00FC0, .V6T2, .T32, {}, {}},
	{.LDRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM12, .NONE, .NONE, .NONE, .NONE}, 0xF8900000, 0xFFF00000, .V6T2, .T32, {}, {}},
	{.LDRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_NEG, .NONE, .NONE, .NONE, .NONE}, 0xF8100C00, 0xFFF00F00, .V6T2, .T32, {}, {}},
	{.LDRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_POST, .NONE, .NONE, .NONE, .NONE}, 0xF8100900, 0xFFF00D00, .V6T2, .T32, {}, {}},
	{.LDRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_PRE, .NONE, .NONE, .NONE, .NONE}, 0xF8100D00, 0xFFF00D00, .V6T2, .T32, {}, {}},
	{.LDRBT, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_POS, .NONE, .NONE, .NONE, .NONE}, 0xF8100E00, 0xFFF00F00, .V6T2, .T32, {}, {}},
	{.LDRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_REG, .NONE, .NONE, .NONE, .NONE}, 0xF8100000, 0xFFF00FC0, .V6T2, .T32, {}, {}},
	{.LDRB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_LITERAL, .NONE, .NONE, .NONE, .NONE}, 0xF81F0000, 0xFF7F0000, .V6T2, .T32, {preferred = true}, {}},
	{.STRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM12, .NONE, .NONE, .NONE, .NONE}, 0xF8A00000, 0xFFF00000, .V6T2, .T32, {}, {}},
	{.STRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_NEG, .NONE, .NONE, .NONE, .NONE}, 0xF8200C00, 0xFFF00F00, .V6T2, .T32, {}, {}},
	{.STRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_POST, .NONE, .NONE, .NONE, .NONE}, 0xF8200900, 0xFFF00D00, .V6T2, .T32, {}, {}},
	{.STRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_PRE, .NONE, .NONE, .NONE, .NONE}, 0xF8200D00, 0xFFF00D00, .V6T2, .T32, {}, {}},
	{.STRHT, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_POS, .NONE, .NONE, .NONE, .NONE}, 0xF8200E00, 0xFFF00F00, .V6T2, .T32, {}, {}},
	{.STRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_REG, .NONE, .NONE, .NONE, .NONE}, 0xF8200000, 0xFFF00FC0, .V6T2, .T32, {}, {}},
	{.LDRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM12, .NONE, .NONE, .NONE, .NONE}, 0xF8B00000, 0xFFF00000, .V6T2, .T32, {}, {}},
	{.LDRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_NEG, .NONE, .NONE, .NONE, .NONE}, 0xF8300C00, 0xFFF00F00, .V6T2, .T32, {}, {}},
	{.LDRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_POST, .NONE, .NONE, .NONE, .NONE}, 0xF8300900, 0xFFF00D00, .V6T2, .T32, {}, {}},
	{.LDRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_PRE, .NONE, .NONE, .NONE, .NONE}, 0xF8300D00, 0xFFF00D00, .V6T2, .T32, {}, {}},
	{.LDRHT, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_POS, .NONE, .NONE, .NONE, .NONE}, 0xF8300E00, 0xFFF00F00, .V6T2, .T32, {}, {}},
	{.LDRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_REG, .NONE, .NONE, .NONE, .NONE}, 0xF8300000, 0xFFF00FC0, .V6T2, .T32, {}, {}},
	{.LDRH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_LITERAL, .NONE, .NONE, .NONE, .NONE}, 0xF83F0000, 0xFF7F0000, .V6T2, .T32, {preferred = true}, {}},
	{.LDRSB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM12, .NONE, .NONE, .NONE, .NONE}, 0xF9900000, 0xFFF00000, .V6T2, .T32, {}, {}},
	{.LDRSB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_NEG, .NONE, .NONE, .NONE, .NONE}, 0xF9100C00, 0xFFF00F00, .V6T2, .T32, {}, {}},
	{.LDRSB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_POST, .NONE, .NONE, .NONE, .NONE}, 0xF9100900, 0xFFF00D00, .V6T2, .T32, {}, {}},
	{.LDRSB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_PRE, .NONE, .NONE, .NONE, .NONE}, 0xF9100D00, 0xFFF00D00, .V6T2, .T32, {}, {}},
	{.LDRSBT, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_POS, .NONE, .NONE, .NONE, .NONE}, 0xF9100E00, 0xFFF00F00, .V6T2, .T32, {}, {}},
	{.LDRSB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_REG, .NONE, .NONE, .NONE, .NONE}, 0xF9100000, 0xFFF00FC0, .V6T2, .T32, {}, {}},
	{.LDRSB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_LITERAL, .NONE, .NONE, .NONE, .NONE}, 0xF91F0000, 0xFF7F0000, .V6T2, .T32, {preferred = true}, {}},
	{.LDRSH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM12, .NONE, .NONE, .NONE, .NONE}, 0xF9B00000, 0xFFF00000, .V6T2, .T32, {}, {}},
	{.LDRSH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_NEG, .NONE, .NONE, .NONE, .NONE}, 0xF9300C00, 0xFFF00F00, .V6T2, .T32, {}, {}},
	{.LDRSH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_POST, .NONE, .NONE, .NONE, .NONE}, 0xF9300900, 0xFFF00D00, .V6T2, .T32, {}, {}},
	{.LDRSH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_PRE, .NONE, .NONE, .NONE, .NONE}, 0xF9300D00, 0xFFF00D00, .V6T2, .T32, {}, {}},
	{.LDRSHT, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_IMM8_POS, .NONE, .NONE, .NONE, .NONE}, 0xF9300E00, 0xFFF00F00, .V6T2, .T32, {}, {}},
	{.LDRSH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_REG, .NONE, .NONE, .NONE, .NONE}, 0xF9300000, 0xFFF00FC0, .V6T2, .T32, {}, {}},
	{.LDRSH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_LITERAL, .NONE, .NONE, .NONE, .NONE}, 0xF93F0000, 0xFF7F0000, .V6T2, .T32, {preferred = true}, {}},
	{.PLD, {.MEM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.MEM_T32_IMM12, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF890F000, 0xFFF0F000, .V7, .T32, {}, {}},
	{.PLD, {.MEM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.MEM_T32_IMM8_NEG, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF810FC00, 0xFFF0FF00, .V7, .T32, {}, {}},
	{.PLD, {.MEM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.MEM_T32_REG, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF810F000, 0xFFF0FFC0, .V7, .T32, {}, {}},
	{.PLD, {.MEM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.MEM_T32_LITERAL, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF81FF000, 0xFF7FF000, .V7, .T32, {preferred = true}, {}},
	{.PLDW, {.MEM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.MEM_T32_IMM12, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF8B0F000, 0xFFF0F000, .V7, .T32, {}, {}},
	{.PLDW, {.MEM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.MEM_T32_IMM8_NEG, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF830FC00, 0xFFF0FF00, .V7, .T32, {}, {}},
	{.PLDW, {.MEM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.MEM_T32_REG, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF830F000, 0xFFF0FFC0, .V7, .T32, {}, {}},
	{.PLI, {.MEM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.MEM_T32_IMM12, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF990F000, 0xFFF0F000, .V7, .T32, {}, {}},
	{.PLI, {.MEM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.MEM_T32_IMM8_NEG, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF910FC00, 0xFFF0FF00, .V7, .T32, {}, {}},
	{.PLI, {.MEM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.MEM_T32_REG, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF910F000, 0xFFF0FFC0, .V7, .T32, {}, {}},
	{.PLI, {.MEM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.MEM_T32_LITERAL, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF91FF000, 0xFF7FF000, .V7, .T32, {preferred = true}, {}},

	// =========================================================================
	// 32-bit: loads and stores, dual and exclusive; table branch
	// =========================================================================
	//   1110 100 P U 1 W L Rn | Rt Rt2 imm8     LDRD/STRD (P U W pick the addressing mode)
	//   1110 1000 0100 Rn | Rt Rd imm8           STREX, and LDREX at 0101
	//   1110 1000 110L Rn | Rt Rt2 op Rd         byte/halfword/double exclusives, TBB/TBH, v8 acquire/release
	{.STRD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_T32, .RT2_T32, .MEM_IMM8_SCALED4, .NONE, .NONE, .NONE}, 0xE9400000, 0xFF700000, .V6T2, .T32, {}, {}},
	{.STRD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_T32, .RT2_T32, .MEM_IMM8_SCALED4_PRE, .NONE, .NONE, .NONE}, 0xE9600000, 0xFF700000, .V6T2, .T32, {}, {}},
	{.STRD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_T32, .RT2_T32, .MEM_IMM8_SCALED4_POST, .NONE, .NONE, .NONE}, 0xE8600000, 0xFF700000, .V6T2, .T32, {}, {}},
	{.LDRD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_T32, .RT2_T32, .MEM_IMM8_SCALED4, .NONE, .NONE, .NONE}, 0xE9500000, 0xFF700000, .V6T2, .T32, {}, {}},
	{.LDRD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_T32, .RT2_T32, .MEM_IMM8_SCALED4_PRE, .NONE, .NONE, .NONE}, 0xE9700000, 0xFF700000, .V6T2, .T32, {}, {}},
	{.LDRD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_T32, .RT2_T32, .MEM_IMM8_SCALED4_POST, .NONE, .NONE, .NONE}, 0xE8700000, 0xFF700000, .V6T2, .T32, {}, {}},
	{.LDRD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_T32, .RT2_T32, .MEM_T32_LITERAL_DUAL, .NONE, .NONE, .NONE}, 0xE95F0000, 0xFF7F0000, .V6T2, .T32, {}, {}},
	{.STREX, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RD_T32, .RT_T32, .MEM_T32_EXCLUSIVE, .NONE, .NONE, .NONE}, 0xE8400000, 0xFFF00000, .V6T2, .T32, {}, {}},
	{.LDREX, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .MEM_T32_EXCLUSIVE, .NONE, .NONE, .NONE, .NONE}, 0xE8500F00, 0xFFF00F00, .V6T2, .T32, {}, {}},
	{.STREXB, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RD_T32_STATUS, .RT_T32, .RN_T32, .NONE, .NONE, .NONE}, 0xE8C00F40, 0xFFF00FF0, .V6T2, .T32, {}, {}},
	{.STREXH, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RD_T32_STATUS, .RT_T32, .RN_T32, .NONE, .NONE, .NONE}, 0xE8C00F50, 0xFFF00FF0, .V6T2, .T32, {}, {}},
	{.STREXD, {.GPR, .GPR, .GPR, .MEM, .NONE, .NONE}, {.RD_T32_STATUS, .RT_T32, .RT2_T32, .RN_T32, .NONE, .NONE}, 0xE8C00070, 0xFFF000F0, .V6T2, .T32, {}, {}},
	{.TBB, {.MEM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.MEM_T32_TABLE_B, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xE8D0F000, 0xFFF0FFF0, .V6T2, .T32, {branch = true, writes_pc = true}, {}},
	{.TBH, {.MEM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.MEM_T32_TABLE_H, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xE8D0F010, 0xFFF0FFF0, .V6T2, .T32, {branch = true, writes_pc = true}, {}},
	{.LDREXB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xE8D00F4F, 0xFFF00FFF, .V6T2, .T32, {}, {}},
	{.LDREXH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xE8D00F5F, 0xFFF00FFF, .V6T2, .T32, {}, {}},
	{.LDREXD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_T32, .RT2_T32, .RN_T32, .NONE, .NONE, .NONE}, 0xE8D0007F, 0xFFF000FF, .V6T2, .T32, {}, {}},
	{.STLB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xE8C00F8F, 0xFFF00FFF, .V8, .T32, {}, {}},
	{.STLH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xE8C00F9F, 0xFFF00FFF, .V8, .T32, {}, {}},
	{.STL, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xE8C00FAF, 0xFFF00FFF, .V8, .T32, {}, {}},
	{.STLEXB, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RD_T32_STATUS, .RT_T32, .RN_T32, .NONE, .NONE, .NONE}, 0xE8C00FC0, 0xFFF00FF0, .V8, .T32, {}, {}},
	{.STLEXH, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RD_T32_STATUS, .RT_T32, .RN_T32, .NONE, .NONE, .NONE}, 0xE8C00FD0, 0xFFF00FF0, .V8, .T32, {}, {}},
	{.STLEX, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RD_T32_STATUS, .RT_T32, .RN_T32, .NONE, .NONE, .NONE}, 0xE8C00FE0, 0xFFF00FF0, .V8, .T32, {}, {}},
	{.STLEXD, {.GPR, .GPR, .GPR, .MEM, .NONE, .NONE}, {.RD_T32_STATUS, .RT_T32, .RT2_T32, .RN_T32, .NONE, .NONE}, 0xE8C000F0, 0xFFF000F0, .V8, .T32, {}, {}},
	{.LDAB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xE8D00F8F, 0xFFF00FFF, .V8, .T32, {}, {}},
	{.LDAH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xE8D00F9F, 0xFFF00FFF, .V8, .T32, {}, {}},
	{.LDA, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xE8D00FAF, 0xFFF00FFF, .V8, .T32, {}, {}},
	{.LDAEXB, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xE8D00FCF, 0xFFF00FFF, .V8, .T32, {}, {}},
	{.LDAEXH, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xE8D00FDF, 0xFFF00FFF, .V8, .T32, {}, {}},
	{.LDAEX, {.GPR, .MEM, .NONE, .NONE, .NONE, .NONE}, {.RT_T32, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xE8D00FEF, 0xFFF00FFF, .V8, .T32, {}, {}},
	{.LDAEXD, {.GPR, .GPR, .MEM, .NONE, .NONE, .NONE}, {.RT_T32, .RT2_T32, .RN_T32, .NONE, .NONE, .NONE}, 0xE8D000FF, 0xFFF000FF, .V8, .T32, {}, {}},

	// =========================================================================
	// 32-bit: load/store multiple
	// =========================================================================
	//   1110 100 op(2) 0 W L Rn | P M (0) list     IA when op is 01, DB when 10
	//   SP with writeback is PUSH (STMDB) and POP (LDMIA).
	// A store list can hold neither SP nor PC, a load list not SP: those
	// bits are zero in the word.
	{.STM, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_T32, .T32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0xE8800000, 0xFFF0A000, .V6T2, .T32, {}, {}},
	{.STM, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_T32, .T32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0xE8A00000, 0xFFF0A000, .V6T2, .T32, {}, {}},
	// v8.1-M's CLRM is the LDM whose base would be PC; bit 15 of its list is
	// APSR.
	{.CLRM, {.GPR_LIST, .NONE, .NONE, .NONE, .NONE, .NONE}, {.T32_REG_LIST, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xE89F0000, 0xFFFF2000, .V81M, .T32, {preferred = true}, {}},
	{.LDM, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_T32, .T32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0xE8900000, 0xFFF02000, .V6T2, .T32, {}, {}},
	{.LDM, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_T32, .T32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0xE8B00000, 0xFFF02000, .V6T2, .T32, {}, {}},
	{.STMDB, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_T32, .T32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0xE9000000, 0xFFF0A000, .V6T2, .T32, {}, {}},
	{.STMDB, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_T32, .T32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0xE9200000, 0xFFF0A000, .V6T2, .T32, {}, {}},
	{.LDMDB, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_T32, .T32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0xE9100000, 0xFFF02000, .V6T2, .T32, {}, {}},
	{.LDMDB, {.GPR, .GPR_LIST, .NONE, .NONE, .NONE, .NONE}, {.RN_T32, .T32_REG_LIST, .NONE, .NONE, .NONE, .NONE}, 0xE9300000, 0xFFF02000, .V6T2, .T32, {}, {}},
	{.PUSH, {.GPR_LIST, .NONE, .NONE, .NONE, .NONE, .NONE}, {.T32_REG_LIST, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xE92D0000, 0xFFFFA000, .V6T2, .T32, {}, {}},
	{.POP, {.GPR_LIST, .NONE, .NONE, .NONE, .NONE, .NONE}, {.T32_REG_LIST, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xE8BD0000, 0xFFFF2000, .V6T2, .T32, {}, {}},
	{.SRSDB, {.GPR, .IMM, .NONE, .NONE, .NONE, .NONE}, {.IMPL_SP, .MODE_IMM5, .NONE, .NONE, .NONE, .NONE}, 0xE80DC000, 0xFFFFFFE0, .V6, .T32, {a_profile_only = true}, {}},
	{.SRSDB, {.GPR, .IMM, .NONE, .NONE, .NONE, .NONE}, {.IMPL_SP, .MODE_IMM5, .NONE, .NONE, .NONE, .NONE}, 0xE82DC000, 0xFFFFFFE0, .V6, .T32, {a_profile_only = true}, {}},
	{.SRSIA, {.GPR, .IMM, .NONE, .NONE, .NONE, .NONE}, {.IMPL_SP, .MODE_IMM5, .NONE, .NONE, .NONE, .NONE}, 0xE98DC000, 0xFFFFFFE0, .V6, .T32, {a_profile_only = true}, {}},
	{.SRSIA, {.GPR, .IMM, .NONE, .NONE, .NONE, .NONE}, {.IMPL_SP, .MODE_IMM5, .NONE, .NONE, .NONE, .NONE}, 0xE9ADC000, 0xFFFFFFE0, .V6, .T32, {a_profile_only = true}, {}},
	{.RFEDB, {.GPR, .NONE, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xE810C000, 0xFFF0FFFF, .V6, .T32, {a_profile_only = true}, {}},
	{.RFEDB, {.GPR, .NONE, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xE830C000, 0xFFF0FFFF, .V6, .T32, {a_profile_only = true}, {}},
	{.RFEIA, {.GPR, .NONE, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xE990C000, 0xFFF0FFFF, .V6, .T32, {a_profile_only = true}, {}},
	{.RFEIA, {.GPR, .NONE, .NONE, .NONE, .NONE, .NONE}, {.RN_A32_WB, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xE9B0C000, 0xFFF0FFFF, .V6, .T32, {a_profile_only = true}, {}},

	// =========================================================================
	// 32-bit: branches and miscellaneous control
	// =========================================================================
	//   11110 S cond imm6 | 10 J1 0 J2 imm11      B<c>.W  (cond 111x is the misc space below)
	//   11110 S imm10     | 1 op J1 1 J2 imm11    B.W (op 0), BL (op 1); BLX when bit 12 is 0
	{.B, {.REL20, .NONE, .NONE, .NONE, .NONE, .NONE}, {.BRANCH_20_T32, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF0008000, 0xF800D000, .V6T2, .T32, {branch = true, cond_branch = true, writes_pc = true, thumb_condition = true}, {}},
	{.B, {.REL24_T32, .NONE, .NONE, .NONE, .NONE, .NONE}, {.BRANCH_24_T32, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF0009000, 0xF800D000, .V6T2, .T32, {branch = true, writes_pc = true}, {}},
	{.BL, {.REL24_T32, .NONE, .NONE, .NONE, .NONE, .NONE}, {.BRANCH_24_T32, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF000D000, 0xF800D000, .THUMB, .T32, {branch = true, writes_pc = true}, {}},
	{.BLX, {.REL24_T32, .NONE, .NONE, .NONE, .NONE, .NONE}, {.BRANCH_BLX_T32, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF000C000, 0xF800D001, .V5T, .T32, {branch = true, writes_pc = true}, {}},
	//   1111 0011 100R Rn | 1000 mask 000m 0000   MSR; M-profile puts SYSm in the low byte
	{.MSR, {.PSR_FIELD, .GPR, .NONE, .NONE, .NONE, .NONE}, {.MSR_FIELDS_T32, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xF3808000, 0xFFE0F0FF, .V6T2, .T32, {}, {}},
	{.MSR, {.PSR_FIELD, .GPR, .NONE, .NONE, .NONE, .NONE}, {.MSR_SYSM_T32, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xF3808000, 0xFFF0F300, .V6T2, .T32, {m_profile_only = true}, {}},
	{.MRS, {.GPR, .PSR_FIELD, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .MRS_SPEC_REG_T32, .NONE, .NONE, .NONE, .NONE}, 0xF3EF8000, 0xFFEFF0FF, .V6T2, .T32, {}, {}},
	{.MRS, {.GPR, .PSR_FIELD, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .SYSM_T32, .NONE, .NONE, .NONE, .NONE}, 0xF3EF8000, 0xFFFFF000, .V6T2, .T32, {m_profile_only = true}, {}},
	//   1111 0011 1010 1111 | 1000 0 imod M A I F mode    CPS; with imod and M zero, the hints
	{.CPSIE, {.IMM_IFLAGS, .NONE, .NONE, .NONE, .NONE, .NONE}, {.CPS_IFLAGS_T32, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3AF8400, 0xFFFFFF1F, .V6, .T32, {a_profile_only = true}, {}},
	{.CPSIE, {.IMM_IFLAGS, .IMM, .NONE, .NONE, .NONE, .NONE}, {.CPS_IFLAGS_T32, .CPS_MODE_T32, .NONE, .NONE, .NONE, .NONE}, 0xF3AF8500, 0xFFFFFF00, .V6, .T32, {a_profile_only = true}, {}},
	{.CPSID, {.IMM_IFLAGS, .NONE, .NONE, .NONE, .NONE, .NONE}, {.CPS_IFLAGS_T32, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3AF8600, 0xFFFFFF1F, .V6, .T32, {a_profile_only = true}, {}},
	{.CPSID, {.IMM_IFLAGS, .IMM, .NONE, .NONE, .NONE, .NONE}, {.CPS_IFLAGS_T32, .CPS_MODE_T32, .NONE, .NONE, .NONE, .NONE}, 0xF3AF8700, 0xFFFFFF00, .V6, .T32, {a_profile_only = true}, {}},
	{.CPS, {.IMM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.CPS_MODE_T32, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3AF8100, 0xFFFFFFE0, .V6, .T32, {a_profile_only = true}, {}},
	{.NOP, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3AF8000, 0xFFFFFFFF, .V6T2, .T32, {}, {}},
	{.YIELD, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3AF8001, 0xFFFFFFFF, .V6T2, .T32, {}, {}},
	{.WFE, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3AF8002, 0xFFFFFFFF, .V6T2, .T32, {}, {}},
	{.WFI, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3AF8003, 0xFFFFFFFF, .V6T2, .T32, {}, {}},
	{.SEV, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3AF8004, 0xFFFFFFFF, .V6T2, .T32, {}, {}},
	{.SEVL, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3AF8005, 0xFFFFFFFF, .V8, .T32, {a_profile_only = true}, {}},
	{.ESB, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3AF8010, 0xFFFFFFFF, .V8, .T32, {}, {}},
	{.CSDB, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3AF8014, 0xFFFFFFFF, .V8, .T32, {}, {}},
	{.DBG, {.IMM_HINT, .NONE, .NONE, .NONE, .NONE, .NONE}, {.DBG_OPTION, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3AF80F0, 0xFFFFFFF0, .V7, .T32, {}, {}},
	{.HINT, {.IMM_HINT, .NONE, .NONE, .NONE, .NONE, .NONE}, {.HINT_FIELD, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3AF8000, 0xFFFFFF00, .V6T2, .T32, {}, {}},
	//   1111 0011 1011 1111 | 1000 1111 op option    CLREX, DSB, DMB, ISB, SB
	{.CLREX, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3BF8F2F, 0xFFFFFFFF, .V7, .T32, {}, {}},
	{.SSBB, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3BF8F40, 0xFFFFFFFF, .V8, .T32, {}, {}},
	{.PSSBB, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3BF8F44, 0xFFFFFFFF, .V8, .T32, {}, {}},
	{.DSB, {.IMM_BARRIER, .NONE, .NONE, .NONE, .NONE, .NONE}, {.BARRIER_TYPE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3BF8F40, 0xFFFFFFF0, .V7, .T32, {}, {}},
	{.DMB, {.IMM_BARRIER, .NONE, .NONE, .NONE, .NONE, .NONE}, {.BARRIER_TYPE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3BF8F50, 0xFFFFFFF0, .V7, .T32, {}, {}},
	{.ISB, {.IMM_BARRIER, .NONE, .NONE, .NONE, .NONE, .NONE}, {.BARRIER_TYPE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3BF8F60, 0xFFFFFFF0, .V7, .T32, {}, {}},
	{.SB, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3BF8F70, 0xFFFFFFFF, .V8, .T32, {}, {}},
	{.BXJ, {.GPR, .NONE, .NONE, .NONE, .NONE, .NONE}, {.RN_T32, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3C08F00, 0xFFF0FFFF, .V6T2, .T32, {}, {}},
	{.ERET, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3DE8F00, 0xFFFFFFFF, .V7VE, .T32, {a_profile_only = true}, {}},
	{.SUB, {.GPR, .GPR, .IMM, .NONE, .NONE, .NONE}, {.IMPL_PC, .IMPL_LR, .T32_IMM8, .NONE, .NONE, .NONE}, 0xF3DE8F00, 0xFFFFFF00, .V6T2, .T32, {sets_flags = true, a_profile_only = true}, {}},
	{.HVC, {.IMM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.IMM4_IMM12, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF7E08000, 0xFFF0F000, .V7VE, .T32, {}, {}},
	{.SMC, {.IMM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.T32_IMM4_SMC, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF7F08000, 0xFFF0FFFF, .V6K, .T32, {a_profile_only = true}, {}},
	{.UDF, {.IMM, .NONE, .NONE, .NONE, .NONE, .NONE}, {.IMM4_IMM12, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF7F0A000, 0xFFF0F000, .V6T2, .T32, {}, {}},
	{.DCPS1, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF78F8001, 0xFFFFFFFF, .V8, .T32, {a_profile_only = true}, {}},
	{.DCPS2, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF78F8002, 0xFFFFFFFF, .V8, .T32, {a_profile_only = true}, {}},
	{.DCPS3, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF78F8003, 0xFFFFFFFF, .V8, .T32, {a_profile_only = true}, {}},

	// =========================================================================
	// 32-bit: banked register transfers (A profile, Virtualization Extensions)
	// =========================================================================
	//   1111 0011 111R m1 | 1000 Rd 001m 0000      MRS Rd, <banked>
	//   1111 0011 100R Rn | 1000 m1 001m 0000      MSR <banked>, Rn
	//   R:m:m1 names the register; the ones it does not name decode as nothing.
	{.MRS, {.GPR, .PSR_FIELD, .NONE, .NONE, .NONE, .NONE}, {.RD_T32, .BANKED_MRS_T32, .NONE, .NONE, .NONE, .NONE}, 0xF3E08020, 0xFFE0F0EF, .V7VE, .T32, {}, {}},
	{.MSR, {.PSR_FIELD, .GPR, .NONE, .NONE, .NONE, .NONE}, {.BANKED_MSR_T32, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xF3808020, 0xFFE0F0EF, .V7VE, .T32, {}, {}},

	// =========================================================================
	// 32-bit: v8.1-M low-overhead loops
	// =========================================================================
	//   1111 0000 0100 Rn | 1100 immh imml 1        WLS LR, Rn, label    (forward)
	//   1111 0000 00sz Rn | 1100 immh imml 1        WLSTP.<sz> LR, Rn, label
	//   1111 0000 0D T 0 1111 | 1100 immh imml 1    LE / LETP, back; D clear names LR
	//   1111 0000 0100 Rn | 1110 0000 0000 0001     DLS, and DLSTP with the size, LCTP with Rn 1111
	{.WLS, {.GPR, .GPR, .REL11, .NONE, .NONE, .NONE}, {.IMPL_LR, .RN_T32, .LOB_FORWARD, .NONE, .NONE, .NONE}, 0xF040C001, 0xFFF0F001, .V81M, .T32, {branch = true}, {}},
	{.DLS, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.IMPL_LR, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xF040E001, 0xFFF0FFFF, .V81M, .T32, {}, {}},
	{.WLSTP, {.GPR, .GPR, .REL11, .NONE, .NONE, .NONE}, {.IMPL_LR, .RN_T32, .LOB_FORWARD, .NONE, .NONE, .NONE}, 0xF000C001, 0xFFF0F001, .MVE_INT, .T32, {branch = true}, {.SZ8, .NONE}},
	{.DLSTP, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.IMPL_LR, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xF000E001, 0xFFF0FFFF, .MVE_INT, .T32, {}, {.SZ8, .NONE}},
	{.WLSTP, {.GPR, .GPR, .REL11, .NONE, .NONE, .NONE}, {.IMPL_LR, .RN_T32, .LOB_FORWARD, .NONE, .NONE, .NONE}, 0xF010C001, 0xFFF0F001, .MVE_INT, .T32, {branch = true}, {.SZ16, .NONE}},
	{.DLSTP, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.IMPL_LR, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xF010E001, 0xFFF0FFFF, .MVE_INT, .T32, {}, {.SZ16, .NONE}},
	{.WLSTP, {.GPR, .GPR, .REL11, .NONE, .NONE, .NONE}, {.IMPL_LR, .RN_T32, .LOB_FORWARD, .NONE, .NONE, .NONE}, 0xF020C001, 0xFFF0F001, .MVE_INT, .T32, {branch = true}, {.SZ32, .NONE}},
	{.DLSTP, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.IMPL_LR, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xF020E001, 0xFFF0FFFF, .MVE_INT, .T32, {}, {.SZ32, .NONE}},
	{.WLSTP, {.GPR, .GPR, .REL11, .NONE, .NONE, .NONE}, {.IMPL_LR, .RN_T32, .LOB_FORWARD, .NONE, .NONE, .NONE}, 0xF030C001, 0xFFF0F001, .MVE_INT, .T32, {branch = true}, {.SZ64, .NONE}},
	{.DLSTP, {.GPR, .GPR, .NONE, .NONE, .NONE, .NONE}, {.IMPL_LR, .RN_T32, .NONE, .NONE, .NONE, .NONE}, 0xF030E001, 0xFFF0FFFF, .MVE_INT, .T32, {}, {.SZ64, .NONE}},
	{.LE, {.GPR, .REL11, .NONE, .NONE, .NONE, .NONE}, {.IMPL_LR, .LOB_BACKWARD, .NONE, .NONE, .NONE, .NONE}, 0xF00FC001, 0xFFFFF001, .V81M, .T32, {branch = true}, {}},
	{.LE, {.REL11, .NONE, .NONE, .NONE, .NONE, .NONE}, {.LOB_BACKWARD, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF02FC001, 0xFFFFF001, .V81M, .T32, {branch = true}, {}},
	{.LETP, {.GPR, .REL11, .NONE, .NONE, .NONE, .NONE}, {.IMPL_LR, .LOB_BACKWARD, .NONE, .NONE, .NONE, .NONE}, 0xF01FC001, 0xFFFFF001, .MVE_INT, .T32, {branch = true}, {}},
	// Whatever the size field holds.
	{.LCTP, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF00FE001, 0xFFCFFFFF, .MVE_INT, .T32, {preferred = true}, {}},

	// =========================================================================
	// 32-bit: v8.1-M pointer authentication and branch target identification
	// =========================================================================
	//   PAC, PACBTI, AUT and BTI are hints; the registers they name are fixed.
	//   1111 1011 0101 Rn | Rd 1111 000x Rm          AUTG, BXAUT (x = 1)
	//   1111 1011 0110 Rn | 1111 Rd 0000 Rm          PACG
	{.PAC, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.IMPL_R12, .IMPL_LR, .IMPL_SP, .NONE, .NONE, .NONE}, 0xF3AF801D, 0xFFFFFFFF, .V81M, .T32, {}, {}},
	{.PACBTI, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.IMPL_R12, .IMPL_LR, .IMPL_SP, .NONE, .NONE, .NONE}, 0xF3AF800D, 0xFFFFFFFF, .V81M, .T32, {}, {}},
	{.AUT, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.IMPL_R12, .IMPL_LR, .IMPL_SP, .NONE, .NONE, .NONE}, 0xF3AF802D, 0xFFFFFFFF, .V81M, .T32, {}, {}},
	{.BTI, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE, .NONE, .NONE}, 0xF3AF800F, 0xFFFFFFFF, .V81M, .T32, {}, {}},
	// Preferred over SMMUL and SMMULR, whose words they are when Rd is 1111.
	{.AUTG, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RT_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFB500F00, 0xFFF00FF0, .V81M, .T32, {preferred = true}, {}},
	{.BXAUT, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RT_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFB500F10, 0xFFF00FF0, .V81M, .T32, {branch = true, writes_pc = true, preferred = true}, {}},
	{.PACG, {.GPR, .GPR, .GPR, .NONE, .NONE, .NONE}, {.RD_T32, .RN_T32, .RM_T32, .NONE, .NONE, .NONE}, 0xFB60F000, 0xFFF0F0F0, .V81M, .T32, {}, {}},

	// =========================================================================
	// 32-bit: v8.1-M conditional select
	// =========================================================================
	//   1110 1010 0101 Rn | 1 0 op Rd fcond Rm       Rn or Rm of 1111 is ZR. These sit in
	//   ORRS (shifted register)'s should-be-zero bit 15. On an M-profile core that
	//   bit makes the word one of these whatever the rest says, so they are
	//   preferred over MOVS and the shifts, whose masks are more specific.
	{.CSEL, {.GPR, .GPR_ZR, .GPR_ZR, .COND, .NONE, .NONE}, {.RD_T32, .RN_T32_ZR, .RM_T32_ZR, .COND_T32_FCOND, .NONE, .NONE}, 0xEA508000, 0xFFF0F000, .V81M, .T32, {preferred = true}, {}},
	{.CSINC, {.GPR, .GPR_ZR, .GPR_ZR, .COND, .NONE, .NONE}, {.RD_T32, .RN_T32_ZR, .RM_T32_ZR, .COND_T32_FCOND, .NONE, .NONE}, 0xEA509000, 0xFFF0F000, .V81M, .T32, {preferred = true}, {}},
	{.CSINV, {.GPR, .GPR_ZR, .GPR_ZR, .COND, .NONE, .NONE}, {.RD_T32, .RN_T32_ZR, .RM_T32_ZR, .COND_T32_FCOND, .NONE, .NONE}, 0xEA50A000, 0xFFF0F000, .V81M, .T32, {preferred = true}, {}},
	{.CSNEG, {.GPR, .GPR_ZR, .GPR_ZR, .COND, .NONE, .NONE}, {.RD_T32, .RN_T32_ZR, .RM_T32_ZR, .COND_T32_FCOND, .NONE, .NONE}, 0xEA50B000, 0xFFF0F000, .V81M, .T32, {preferred = true}, {}},
}
