// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm32_tests

import "core:fmt"
import "core:os"
import a "../"

ok_count, fail_count: int

// Pins one row: the mnemonic must have a form with exactly these bits and
// this mask. Rows are found by their bits rather than their position, since
// the generator merges several tables and position is not stable.
@(private="file")
check :: proc(name: string, mn: a.Mnemonic, want_bits, want_mask: u32) {
	_run := a.ENCODE_RUNS[u16(mn)]
	forms := a.ENCODE_FORMS[_run.start:][:_run.count]
	found_bits := false
	for e in forms {
		if e.bits != want_bits {
			continue
		}
		found_bits = true
		if e.mask == want_mask {
			fmt.printf("  [ok]   %-22s %08x / %08x (mode=%v feat=%v)\n", name, e.bits, e.mask, e.mode, e.feature)
			ok_count += 1
			return
		}
	}
	if found_bits {
		fmt.printf("  [FAIL] %-22s no %v form with bits=%08x has mask=%08x\n", name, mn, want_bits, want_mask)
	} else {
		fmt.printf("  [FAIL] %-22s no %v form with bits=%08x\n", name, mn, want_bits)
	}
	fail_count += 1
}

run_smoke :: proc() {
	fmt.println("==== arm32 ENCODING_TABLE smoke test ====")

	// ---- A32 data processing ----
	check("ADD imm", .ADD, 0x02800000, 0x0FE00000)
	check("ADD reg", .ADD, 0x00800000, 0x0FE00010)
	check("ADD rsr", .ADD, 0x00800010, 0x0FE00090)
	check("ADDS imm", .ADD, 0x02900000, 0x0FF00000)
	check("SUB imm", .SUB, 0x02400000, 0x0FE00000)
	check("AND reg", .AND, 0x00000000, 0x0FE00010)
	check("ORR imm", .ORR, 0x03800000, 0x0FE00000)
	check("MOVW", .MOVW, 0x03000000, 0x0FF00000)
	check("MOVT", .MOVT, 0x03400000, 0x0FF00000)
	check("CMP imm", .CMP, 0x03500000, 0x0FF0F000)
	check("TST reg", .TST, 0x01100000, 0x0FF0F010)

	// ---- Multiply family ----
	check("MUL", .MUL, 0x00000090, 0x0FE000F0)
	check("MLA", .MLA, 0x00200090, 0x0FE000F0)
	check("MLS", .MLS, 0x00600090, 0x0FF000F0)
	check("UMULL", .UMULL, 0x00800090, 0x0FE000F0)
	check("SMULL", .SMULL, 0x00C00090, 0x0FE000F0)
	check("UMAAL", .UMAAL, 0x00400090, 0x0FF000F0)
	check("SMLABB", .SMLABB, 0x01000080, 0x0FF000F0)
	check("SDIV", .SDIV, 0x0710F010, 0x0FF0F0F0)
	check("UDIV", .UDIV, 0x0730F010, 0x0FF0F0F0)

	// ---- ARMv6 DSP/SIMD ----
	check("SADD16", .SADD16, 0x06100F10, 0x0FF00FF0)
	check("SADD8", .SADD8, 0x06100F90, 0x0FF00FF0)
	check("UADD8", .UADD8, 0x06500F90, 0x0FF00FF0)
	check("QADD16", .QADD16, 0x06200F10, 0x0FF00FF0)
	check("QADD8", .QADD8, 0x06200F90, 0x0FF00FF0)

	// ---- Extends + bit-field ----
	check("SXTB", .SXTB, 0x06AF0070, 0x0FFF0070)
	check("UXTH", .UXTH, 0x06FF0070, 0x0FFF0070)
	check("CLZ", .CLZ, 0x016F0F10, 0x0FFF0FF0)
	check("REV", .REV, 0x06BF0F30, 0x0FFF0FF0)
	check("RBIT", .RBIT, 0x06FF0F30, 0x0FFF0FF0)
	check("BFI", .BFI, 0x07C00010, 0x0FE00070)
	check("UBFX", .UBFX, 0x07E00050, 0x0FE00070)

	// ---- Branches + exceptions ----
	check("B (A32)", .B, 0x0A000000, 0x0F000000)
	check("BL (A32)", .BL, 0x0B000000, 0x0F000000)
	check("BX", .BX, 0x012FFF10, 0x0FFFFFF0)
	check("BLX reg", .BLX, 0x012FFF30, 0x0FFFFFF0)
	check("BLX imm", .BLX, 0xFA000000, 0xFE000000)
	check("SVC (A32)", .SVC, 0x0F000000, 0x0F000000)
	check("BKPT (A32)", .BKPT, 0xE1200070, 0xFFF000F0)
	check("UDF", .UDF, 0xE7F000F0, 0xFFF000F0)

	// ---- Status register access ----
	check("MRS", .MRS, 0x010F0000, 0x0FBF0FFF)
	check("MSR imm", .MSR, 0x0320F000, 0x0FB0F000)

	// ---- Hints / barriers ----
	check("NOP (A32)", .NOP, 0x0320F000, 0x0FFFFFFF)
	check("WFE (A32)", .WFE, 0x0320F002, 0x0FFFFFFF)
	check("DMB (A32)", .DMB, 0xF57FF050, 0xFFFFFFF0)
	check("ISB (A32)", .ISB, 0xF57FF060, 0xFFFFFFF0)
	check("CLREX (A32)", .CLREX, 0xF57FF01F, 0xFFFFFFFF)

	// ---- Load/Store ----
	check("LDR imm", .LDR, 0x05100000, 0x0F700000)
	check("LDR pre", .LDR, 0x05300000, 0x0F700000)
	check("LDR post", .LDR, 0x04100000, 0x0F700000)
	check("STR imm", .STR, 0x05000000, 0x0F700000)
	check("LDRB imm", .LDRB, 0x05500000, 0x0F700000)
	check("STRH imm", .STRH, 0x014000B0, 0x0F7000F0)
	check("LDRSB imm", .LDRSB, 0x015000D0, 0x0F7000F0)
	check("LDRD", .LDRD, 0x014000D0, 0x0F7000F0)
	check("LDM", .LDM, 0x08900000, 0x0FF00000)
	check("STM DB", .STMDB, 0x09000000, 0x0FD00000)
	check("PUSH", .PUSH, 0x092D0000, 0x0FFF0000)
	check("POP", .POP, 0x08BD0000, 0x0FFF0000)
	check("SWP", .SWP, 0x01000090, 0x0FF00FF0)

	// ---- Exclusive ----
	check("LDREX", .LDREX, 0x01900F9F, 0x0FF00FFF)
	check("STREX", .STREX, 0x01800F90, 0x0FF00FF0)
	check("LDREXB", .LDREXB, 0x01D00F9F, 0x0FF00FFF)
	check("LDREXD", .LDREXD, 0x01B00F9F, 0x0FF00FFF)
	check("LDA (v8)", .LDA, 0x01900C9F, 0x0FF00FFF)
	check("STL (v8)", .STL, 0x0180FC90, 0x0FF0FFF0)

	// ---- CRC32 ----
	check("CRC32B", .CRC32B, 0xE1000040, 0xFFF00FF0)
	check("CRC32CW", .CRC32CW, 0xE1400240, 0xFFF00FF0)

	// ---- VFP scalar ----
	check("VADD.F32", .VADD, 0x0E300A00, 0x0FB00F50)
	check("VADD.F64", .VADD, 0x0E300B00, 0x0FB00F50)
	check("VSUB.F32", .VSUB, 0x0E300A40, 0x0FB00F50)
	check("VMUL.F32", .VMUL, 0x0E200A00, 0x0FB00F50)
	check("VDIV.F32", .VDIV, 0x0E800A00, 0x0FB00F50)
	check("VABS.F32", .VABS, 0x0EB00AC0, 0x0FBF0FD0)
	check("VNEG.F32", .VNEG, 0x0EB10A40, 0x0FBF0FD0)
	check("VSQRT.F32", .VSQRT, 0x0EB10AC0, 0x0FBF0FD0)
	check("VFMA.F32", .VFMA, 0x0EA00A00, 0x0FB00F50)
	check("VLDR.F32", .VLDR, 0x0D100A00, 0x0F300F00)
	check("VSTR.F64", .VSTR, 0x0D000B00, 0x0F300F00)
	// The system register is an operand now, so its field is not fixed.
	check("VMRS", .VMRS, 0x0EF10A10, 0x0FF00FFF)
	check("VMSR", .VMSR, 0x0EE10A10, 0x0FF00FFF)
	check("VPUSH.F32", .VPUSH, 0x0D2D0A00, 0x0FFF0F00)
	check("VPOP.F64", .VPOP, 0x0CBD0B00, 0x0FFF0F01)
	check("VCMP.F32", .VCMP, 0x0EB40A40, 0x0FBF0FD0)

	// ---- ARMv8 FP ----
	check("VMAXNM.F32", .VMAXNM, 0xFE800A00, 0xFFB00F50)
	check("VMINNM.F32", .VMINNM, 0xFE800A40, 0xFFB00F50)
	check("VCVTA.F32", .VCVTA, 0xFEBC0A40, 0xFFBF0FD0)
	check("VRINTA.F32", .VRINTA, 0xFEB80A40, 0xFFBF0FD0)

	// ---- NEON ----
	check("VADD NEON.I8 D", .VADD, 0xF2000800, 0xFFB00F10)
	check("VADD NEON.I32 D", .VADD, 0xF2200800, 0xFFB00F10)
	check("VADD NEON.I8 Q", .VADD, 0xF2000840, 0xFFB00F50)
	check("VADD NEON.F32 D", .VADD, 0xF2000D00, 0xFFB00F10)
	check("VADD NEON.F32 Q", .VADD, 0xF2000D40, 0xFFB00F50)
	check("VADD VFP F16", .VADD, 0x0E300900, 0x0FB00F50)
	check("VADD NEON F16 D", .VADD, 0xF2100D00, 0xFFB00F10)
	check("VADD NEON F16 Q", .VADD, 0xF2100D40, 0xFFB00F50)
	check("AESE (v8)", .AESE, 0xF3B00300, 0xFFB30FD0)
	check("SHA1H", .SHA1H, 0xF3B902C0, 0xFFBF0FD0)
	check("SHA1C", .SHA1C, 0xF2000C40, 0xFFB00F50)
	// NEON arithmetic/logical
	check("VMUL NEON.I8 D", .VMUL, 0xF2000910, 0xFFB00F10)
	check("VMUL NEON.F32 D", .VMUL, 0xF3000D10, 0xFFB00F10)
	check("VAND", .VAND, 0xF2000110, 0xFFB00F10)
	// The modified-immediate forms come first; the register form follows.
	check("VORR imm", .VORR, 0xF2800110, 0xFEB80FF0)
	check("VORR reg", .VORR, 0xF2200110, 0xFFB00F10)
	check("VEOR", .VEOR, 0xF3000110, 0xFFB00F10)
	check("VBSL", .VBSL, 0xF3100110, 0xFFB00F10)
	check("VMAX.S16 D", .VMAX, 0xF2100600, 0xFFB00F10)
	check("VMIN.U8 D", .VMIN, 0xF3000610, 0xFFB00F10)
	check("VCEQ.I8 D", .VCEQ, 0xF3000810, 0xFFB00F10)
	check("VCGT.S8 D", .VCGT, 0xF2000300, 0xFFB00F10)
	check("VCGE.S8 D", .VCGE, 0xF2000310, 0xFFB00F10)
	check("VQADD.S8 D", .VQADD, 0xF2000010, 0xFFB00F10)
	check("VQSUB.U8 Q", .VQSUB, 0xF3000210, 0xFFB00F10)
	check("VHADD.S8 D", .VHADD, 0xF2000000, 0xFFB00F10)
	check("VABD.S8 D", .VABD, 0xF2000700, 0xFFB00F10)
	check("VPADD.I8 D", .VPADD, 0xF2000B10, 0xFFB00F10)
	// NEON unary + shifts
	check("VABS NEON.S8 D", .VABS, 0xF3B10300, 0xFFBF0FD0)
	check("VNEG NEON.F32 D", .VNEG, 0xF3B90780, 0xFFBF0FD0)
	check("VMVN", .VMVN, 0xF3B00580, 0xFFB30FD0)
	check("VCNT", .VCNT, 0xF3B00500, 0xFFB30FD0)
	check("VCLZ.I8 D", .VCLZ, 0xF3B00480, 0xFFBF0FD0)
	check("VSHR.S8 D imm", .VSHR, 0xF2800010, 0xFE800F10)
	check("VSHL reg.S8 D", .VSHL, 0xF2000400, 0xFFB00F10)
	check("VEXT D", .VEXT, 0xF2B00000, 0xFFB00010)
	check("VDUP from Rt D", .VDUP, 0x0EC00B10, 0x0FF00FD0)
	check("VREV64.I8 D", .VREV64, 0xF3B00000, 0xFFBF0FD0)
	check("VTRN.I8 D", .VTRN, 0xF3B20080, 0xFFBF0FD0)
	check("VZIP.I8 D", .VZIP, 0xF3B20180, 0xFFB70FD0)
	check("VTBL", .VTBL, 0xF3B00800, 0xFFB00F70)
	check("VRECPE F32 D", .VRECPE, 0xF3BB0500, 0xFFBF0FD0)
	check("VLD1 1-reg", .VLD1, 0xF420070F, 0xFFF00F0F)
	check("VST1 1-reg", .VST1, 0xF400070F, 0xFFF00F0F)
	check("VLD2 2-reg", .VLD2, 0xF420080F, 0xFFF00F0F)
	check("VLD3 3-reg", .VLD3, 0xF420040F, 0xFFF00F0F)
	check("VLD4 4-reg", .VLD4, 0xF420000F, 0xFFF00F0F)
	check("VMULL.S8", .VMULL, 0xF2800C00, 0xFFB00F50)

	// ---- Thumb-2 ----
	check("CBZ (T16)", .CBZ, 0x0000B100, 0x0000FD00)
	check("CBNZ (T16)", .CBNZ, 0x0000B900, 0x0000FD00)
	check("IT", .IT, 0x0000BF00, 0x0000FF00)
	check("TBB", .TBB, 0xE8D0F000, 0xFFF0FFF0)
	check("TBH", .TBH, 0xE8D0F010, 0xFFF0FFF0)

	// ---- T16 Thumb-1 (GBA-critical) ----
	// LSL/LSR/ASR: entries 0..1 are A32, 2 = T16 imm, 3 = T16 reg
	check("LSL T16 imm", .LSL, 0x00000000, 0x0000F800)
	check("LSL T16 reg", .LSL, 0x00004080, 0x0000FFC0)
	check("LSR T16 imm", .LSR, 0x00000800, 0x0000F800)
	check("ASR T16 imm", .ASR, 0x00001000, 0x0000F800)
	check("ROR T16 reg", .ROR, 0x000041C0, 0x0000FFC0)
	check("RRX (A32 only)", .RRX, 0x01A00060, 0x0FFF0FF0)
	check("ADR T16", .ADR, 0x0000A000, 0x0000F800)
	check("NEG T16", .NEG, 0x00004240, 0x0000FFC0)
	// ADD T16 entries start after 6 A32 entries (indices 0-5)
	check("ADD T16 reg3", .ADD, 0x00001800, 0x0000FE00)
	check("ADD T16 imm3", .ADD, 0x00001C00, 0x0000FE00)
	check("ADD T16 imm8", .ADD, 0x00003000, 0x0000F800)
	check("ADD T16 hi-reg", .ADD, 0x00004400, 0x0000FF00)
	check("ADD T16 SP+imm", .ADD, 0x0000A800, 0x0000F800)
	check("ADD T16 SP,imm7", .ADD, 0x0000B000, 0x0000FF80)
	check("SUB T16 reg3", .SUB, 0x00001A00, 0x0000FE00)
	check("SUB T16 imm3", .SUB, 0x00001E00, 0x0000FE00)
	check("SUB T16 imm8", .SUB, 0x00003800, 0x0000F800)
	check("SUB T16 SP,imm7", .SUB, 0x0000B080, 0x0000FF80)
	check("MOV T16 imm8", .MOV, 0x00002000, 0x0000F800)
	check("MOV T16 hi-reg", .MOV, 0x00004600, 0x0000FF00)
	check("CMP T16 imm8", .CMP, 0x00002800, 0x0000F800)
	check("CMP T16 reg", .CMP, 0x00004280, 0x0000FFC0)
	check("CMP T16 hi-reg", .CMP, 0x00004500, 0x0000FF00)
	check("AND T16", .AND, 0x00004000, 0x0000FFC0)
	check("EOR T16", .EOR, 0x00004040, 0x0000FFC0)
	check("ORR T16", .ORR, 0x00004300, 0x0000FFC0)
	check("BIC T16", .BIC, 0x00004380, 0x0000FFC0)
	check("MVN T16", .MVN, 0x000043C0, 0x0000FFC0)
	check("MUL T16", .MUL, 0x00004340, 0x0000FFC0)
	check("TST T16", .TST, 0x00004200, 0x0000FFC0)
	check("CMN T16", .CMN, 0x000042C0, 0x0000FFC0)
	check("ADC T16", .ADC, 0x00004140, 0x0000FFC0)
	check("SBC T16", .SBC, 0x00004180, 0x0000FFC0)

	// T16 Load/store
	check("LDR T16 pc-rel", .LDR, 0x00004800, 0x0000F800)
	check("LDR T16 reg-off", .LDR, 0x00005800, 0x0000FE00)
	check("LDR T16 imm5", .LDR, 0x00006800, 0x0000F800)
	check("LDR T16 sp-rel", .LDR, 0x00009800, 0x0000F800)
	check("STR T16 reg-off", .STR, 0x00005000, 0x0000FE00)
	check("STR T16 imm5", .STR, 0x00006000, 0x0000F800)
	check("STR T16 sp-rel", .STR, 0x00009000, 0x0000F800)
	check("LDRB T16 reg", .LDRB, 0x00005C00, 0x0000FE00)
	check("LDRB T16 imm5", .LDRB, 0x00007800, 0x0000F800)
	check("STRB T16 reg", .STRB, 0x00005400, 0x0000FE00)
	check("STRB T16 imm5", .STRB, 0x00007000, 0x0000F800)
	check("LDRH T16 reg", .LDRH, 0x00005A00, 0x0000FE00)
	check("LDRH T16 imm5", .LDRH, 0x00008800, 0x0000F800)
	check("STRH T16 reg", .STRH, 0x00005200, 0x0000FE00)
	check("STRH T16 imm5", .STRH, 0x00008000, 0x0000F800)
	check("LDRSB T16", .LDRSB, 0x00005600, 0x0000FE00)
	check("LDRSH T16", .LDRSH, 0x00005E00, 0x0000FE00)
	check("LDM T16", .LDM, 0x0000C800, 0x0000F800)
	check("STM T16", .STM, 0x0000C000, 0x0000F800)
	check("PUSH T16", .PUSH, 0x0000B400, 0x0000FE00)
	check("POP T16", .POP, 0x0000BC00, 0x0000FE00)

	// T16 branches + exception
	check("B<cond> T16", .B, 0x0000D000, 0x0000F000)
	check("B unc T16", .B, 0x0000E000, 0x0000F800)
	check("B<cond> T32", .B, 0xF0008000, 0xF800D000)
	check("B unc T32", .B, 0xF0009000, 0xF800D000)
	check("BL T32", .BL, 0xF000D000, 0xF800D000)
	check("BX T16", .BX, 0x00004700, 0x0000FF80)
	check("BLX T16 reg", .BLX, 0x00004780, 0x0000FF87)
	check("SVC T16", .SVC, 0x0000DF00, 0x0000FF00)
	check("BKPT T16", .BKPT, 0x0000BE00, 0x0000FF00)

	// T16 extends + REV
	check("SXTB T16", .SXTB, 0x0000B240, 0x0000FFC0)
	check("SXTH T16", .SXTH, 0x0000B200, 0x0000FFC0)
	check("UXTB T16", .UXTB, 0x0000B2C0, 0x0000FFC0)
	check("UXTH T16", .UXTH, 0x0000B280, 0x0000FFC0)
	check("REV T16", .REV, 0x0000BA00, 0x0000FFC0)
	check("REV16 T16", .REV16, 0x0000BA40, 0x0000FFC0)
	check("REVSH T16", .REVSH, 0x0000BAC0, 0x0000FFC0)

	// T16/T32 hints + barriers
	check("NOP T16", .NOP, 0x0000BF00, 0x0000FFFF)
	check("NOP T32", .NOP, 0xF3AF8000, 0xFFFFFFFF)
	check("DMB T32", .DMB, 0xF3BF8F50, 0xFFFFFFF0)
	check("CLREX T32", .CLREX, 0xF3BF8F2F, 0xFFFFFFFF)

	// ---- T32 32-bit Thumb-2 data-processing ----
	check("AND T32 imm", .AND, 0xF0000000, 0xFBF08000)
	check("AND T32 reg", .AND, 0xEA000000, 0xFFF00000)
	check("EOR T32 imm", .EOR, 0xF0800000, 0xFBF08000)
	check("ORR T32 imm", .ORR, 0xF0400000, 0xFBF08000)
	check("BIC T32 imm", .BIC, 0xF0200000, 0xFBF08000)
	check("MVN T32 imm", .MVN, 0xF06F0000, 0xFBFF8000)
	check("TST T32 imm", .TST, 0xF0100F00, 0xFBF08F00)
	check("TEQ T32 imm", .TEQ, 0xF0900F00, 0xFBF08F00)
	check("CMP T32 imm", .CMP, 0xF1B00F00, 0xFBF08F00)
	check("CMN T32 imm", .CMN, 0xF1100F00, 0xFBF08F00)
	check("ADC T32 imm", .ADC, 0xF1400000, 0xFBF08000)
	check("SBC T32 imm", .SBC, 0xF1600000, 0xFBF08000)
	check("RSB T32 imm", .RSB, 0xF1C00000, 0xFBF08000)
	check("MOVW T32", .MOVW, 0xF2400000, 0xFBF08000)
	check("MOVT T32", .MOVT, 0xF2C00000, 0xFBF08000)
	check("BFC T32", .BFC, 0xF36F0000, 0xFBFF8000)
	check("BFI T32", .BFI, 0xF3600000, 0xFBF08000)
	check("SBFX T32", .SBFX, 0xF3400000, 0xFBF08000)
	check("UBFX T32", .UBFX, 0xF3C00000, 0xFBF08000)
	check("MUL T32", .MUL, 0xFB00F000, 0xFFF0F0F0)
	check("MLA T32", .MLA, 0xFB000000, 0xFFF000F0)
	check("MLS T32", .MLS, 0xFB000010, 0xFFF000F0)
	check("UMULL T32", .UMULL, 0xFBA00000, 0xFFF000F0)
	check("SMULL T32", .SMULL, 0xFB800000, 0xFFF000F0)
	check("SDIV T32", .SDIV, 0xFB90F0F0, 0xFFF0F0F0)
	check("UDIV T32", .UDIV, 0xFBB0F0F0, 0xFFF0F0F0)
	check("LDR T32 imm12", .LDR, 0xF8D00000, 0xFFF00000)
	check("LDR T32 lit", .LDR, 0xF85F0000, 0xFF7F0000)
	check("STR T32 imm12", .STR, 0xF8C00000, 0xFFF00000)
	check("LDRB T32 imm12", .LDRB, 0xF8900000, 0xFFF00000)
	check("STRB T32 imm12", .STRB, 0xF8800000, 0xFFF00000)
	check("LDRH T32 imm12", .LDRH, 0xF8B00000, 0xFFF00000)
	check("STRH T32 imm12", .STRH, 0xF8A00000, 0xFFF00000)
	check("LDRSB T32 imm12", .LDRSB, 0xF9900000, 0xFFF00000)
	check("LDRSH T32 imm12", .LDRSH, 0xF9B00000, 0xFFF00000)
	check("LDM T32 IA", .LDM, 0xE8900000, 0xFFF00000)
	check("LDM T32 DB", .LDMDB, 0xE9100000, 0xFFF00000)
	check("STM T32 IA", .STM, 0xE8800000, 0xFFF00000)
	check("PUSH T32", .PUSH, 0xE92D0000, 0xFFFF0000)
	check("POP T32", .POP, 0xE8BD0000, 0xFFFF0000)

	// ---- Round 2: more NEON + T32 forms ----
	check("VMLAL.S8", .VMLAL, 0xF2800800, 0xFFB00F50)
	check("VMLSL.S16", .VMLSL, 0xF2900A00, 0xFFB00F50)
	check("VQDMULH.S16", .VQDMULH, 0xF2100B00, 0xFFB00F10)
	check("VQRDMULH.S16", .VQRDMULH, 0xF3100B00, 0xFFB00F10)
	check("VQDMULL.S16", .VQDMULL, 0xF2900D00, 0xFFB00F50)
	check("VMOVL.S8", .VMOVL, 0xF2880A10, 0xFFB80FD0)
	check("VMOVN.I16", .VMOVN, 0xF3B20200, 0xFFBF0FD0)
	check("VQMOVN.S16", .VQMOVN, 0xF3B20280, 0xFFBF0FD0)
	check("VQMOVUN.S16", .VQMOVUN, 0xF3B20240, 0xFFBF0FD0)
	check("VSHRN imm", .VSHRN, 0xF2800810, 0xFE800FD0)
	check("VQSHRN.S", .VQSHRN, 0xF2800910, 0xFE800FD0)
	check("VPADDL.S8", .VPADDL, 0xF3B00200, 0xFFBF0FD0)
	check("VPADAL.S8", .VPADAL, 0xF3B00600, 0xFFB30FD0)
	check("VSWP.I8", .VSWP, 0xF3B20000, 0xFFB30FD0)
	check("VACGE.F32 D", .VACGE, 0xF3000E10, 0xFFB00F10)
	check("VACGT.F32 D", .VACGT, 0xF3200E10, 0xFFB00F10)

	// ---- T32 forms of A32 misc ----
	check("LDREX T32", .LDREX, 0xE8500F00, 0xFFF00F00)
	check("STREX T32", .STREX, 0xE8400000, 0xFFF00000)
	check("LDREXB T32", .LDREXB, 0xE8D00F4F, 0xFFF00FFF)
	check("LDREXD T32", .LDREXD, 0xE8D0007F, 0xFFF000FF)
	check("MRS T32", .MRS, 0xF3EF8000, 0xFFEFF0FF)
	check("MSR T32", .MSR, 0xF3808000, 0xFFE0F0FF)
	check("LDRD T32", .LDRD, 0xE9500000, 0xFF700000)
	check("STRD T32", .STRD, 0xE9400000, 0xFF700000)
	check("SXTB T32", .SXTB, 0xFA4FF080, 0xFFFFF0C0)
	check("UXTH T32", .UXTH, 0xFA1FF080, 0xFFFFF0C0)
	check("REV T32", .REV, 0xFA90F080, 0xFFF0F0F0)
	check("RBIT T32", .RBIT, 0xFA90F0A0, 0xFFF0F0F0)
	check("CLZ T32", .CLZ, 0xFAB0F080, 0xFFF0F0F0)
	check("PLD T32", .PLD, 0xF890F000, 0xFFF0F000)
	check("PLI T32", .PLI, 0xF990F000, 0xFFF0F000)
	check("SXTAB T32", .SXTAB, 0xFA40F080, 0xFFF0F0C0)
	check("QADD T32", .QADD, 0xFA80F080, 0xFFF0F0F0)
	check("QSUB T32", .QSUB, 0xFA80F0A0, 0xFFF0F0F0)
	check("SSAT T32", .SSAT, 0xF3000000, 0xFBD08000)
	check("USAT T32", .USAT, 0xF3800000, 0xFBD08000)
	check("SADD8 T32", .SADD8, 0xFA80F000, 0xFFF0F0F0)
	check("SADD16 T32", .SADD16, 0xFA90F000, 0xFFF0F0F0)
	check("UADD8 T32", .UADD8, 0xFA80F040, 0xFFF0F0F0)
	check("QADD16 T32", .QADD16, 0xFA90F010, 0xFFF0F0F0)
	check("SHADD8 T32", .SHADD8, 0xFA80F020, 0xFFF0F0F0)
	check("UQADD8 T32", .UQADD8, 0xFA80F050, 0xFFF0F0F0)
	check("UHADD8 T32", .UHADD8, 0xFA80F060, 0xFFF0F0F0)
	check("UDF T32", .UDF, 0xF7F0A000, 0xFFF0F000)
	check("UDF T16", .UDF, 0x0000DE00, 0x0000FF00)

	// ---- Extensions: Dot product / FCMA / FHM / BF16 ----
	check("VSDOT D", .VSDOT, 0xFC200D00, 0xFFB00F10)
	check("VUDOT Q", .VUDOT, 0xFC200D50, 0xFFB00F50)
	check("VSDOT lane D", .VSDOT, 0xFE200D00, 0xFFB00F10)
	check("VCMLA D", .VCMLA, 0xFC200800, 0xFC800F10)
	check("VCADD Q", .VCADD, 0xFC800840, 0xFE800F50)
	check("VFMAL D", .VFMAL, 0xFC200810, 0xFFB00F10)
	check("VFMSL Q", .VFMSL, 0xFCA00850, 0xFFB00F50)
	check("VCVT BF16", .VCVT, 0xF3B60600, 0xFFBF0FD0)
	check("VDOT BF16 D", .VDOT, 0xFC000D00, 0xFFB00F10)
	// Bfloat16 names which half of each pair it takes on the mnemonic.
	check("VFMAB BF16 Q", .VFMAB, 0xFC300810, 0xFFB00F70)
	check("VFMAT BF16 Q", .VFMAT, 0xFC300850, 0xFFB00F70)
	check("VMMLA BF16 Q", .VMMLA, 0xFC000C40, 0xFFB00F50)

	// ---- Barriers / hints: ESB, PSB CSYNC, TSB CSYNC, CSDB, SB ----
	check("ESB A32", .ESB, 0x0320F010, 0x0FFFFFFF)
	check("ESB T32", .ESB, 0xF3AF8010, 0xFFFFFFFF)
	check("PSB_CSYNC A32", .PSB_CSYNC, 0xE320F011, 0xFFFFFFFF)
	check("TSB_CSYNC A32", .TSB_CSYNC, 0xE320F012, 0xFFFFFFFF)
	check("CSDB A32", .CSDB, 0x0320F014, 0x0FFFFFFF)
	check("CSDB T32", .CSDB, 0xF3AF8014, 0xFFFFFFFF)
	check("SB A32", .SB, 0xF57FF070, 0xFFFFFFFF)
	check("SB T32", .SB, 0xF3BF8F70, 0xFFFFFFFF)

	// ---- SETPAN (ARMv8.1) ----
	check("SETPAN A32", .SETPAN, 0xF1100000, 0xFFFFFDFF)
	check("SETPAN T16", .SETPAN, 0x0000B610, 0x0000FFE0)

	// ---- VQRDMLAH / VQRDMLSH (FEAT_RDM, ARMv8.1) ----
	check("VQRDMLAH D .S16", .VQRDMLAH, 0xF3100B10, 0xFFB00F10)
	check("VQRDMLAH D .S32", .VQRDMLAH, 0xF3200B10, 0xFFB00F10)
	check("VQRDMLAH Q .S16", .VQRDMLAH, 0xF3100B50, 0xFFB00F50)
	check("VQRDMLSH D .S16", .VQRDMLSH, 0xF3100C10, 0xFFB00F10)
	check("VQRDMLSH Q .S32", .VQRDMLSH, 0xF3200C50, 0xFFB00F50)

	// ---- ARMv8-M Security Extensions (TrustZone-M) ----
	check("TT", .TT, 0xE840F000, 0xFFF0F0C0)
	check("TTT", .TTT, 0xE840F040, 0xFFF0F0C0)
	check("TTA", .TTA, 0xE840F080, 0xFFF0F0C0)
	check("TTAT", .TTAT, 0xE840F0C0, 0xFFF0F0C0)

	// ---- ARMv8.1-M low-overhead loops ----
	check("WLS", .WLS, 0xF040C001, 0xFFF0F001)
	check("DLS", .DLS, 0xF040E001, 0xFFF0FFFF)
	check("LE", .LE, 0xF00FC001, 0xFFFFF001)
	check("LETP", .LETP, 0xF01FC001, 0xFFFFF001)
	check("LCTP", .LCTP, 0xF00FE001, 0xFFFFFFFF)

	// ---- Custom Datapath Extension (CDE) ----
	check("CX1", .CX1, 0xEE000000, 0xFF800800)
	check("CX1A", .CX1A, 0xFE000000, 0xFF800800)
	check("CX2", .CX2, 0xEE400000, 0xFFC00800)
	check("CX3", .CX3, 0xEE800000, 0xFFC00800)
	check("VCX1 S", .VCX1, 0xEC200000, 0xFF300800)
	check("VCX1 D", .VCX1, 0xEC300000, 0xFF300800)
	check("VCX3 D", .VCX3, 0xEC900000, 0xFF300800)

	// ---- MVE predication and tail-loop (LLVM-verified) ----
	check("VPT", .VPT, 0xFE010F00, 0xFE018FF0)
	check("VPST", .VPST, 0xFE710F4D, 0xFFFFFFFF)
	check("VPSEL", .VPSEL, 0xFE010F01, 0xFFF10FF1)
	check("VCTP", .VCTP, 0xF000E801, 0xFFC0FFFF)

	// ---- MVE reductions (LLVM-verified) ----
	check("VADDV", .VADDV, 0xEEF10F00, 0xEFF31FF1)
	check("VADDVA", .VADDVA, 0xEEF10F20, 0xEFF31FD1)
	check("VMAXV", .VMAXV, 0xEEE20F00, 0xEFF30FF1)
	check("VMINV", .VMINV, 0xEEE20F80, 0xEFF30FF1)
	check("VMAXNMV", .VMAXNMV, 0xEEEE0F00, 0xEFFF0FF1)

	// ---- MVE MAC reductions ----
	check("VMLAV", .VMLAV, 0xEEB00F00, 0xEFB11FF1)
	check("VMLADAV", .VMLADAV, 0xEEB00F00, 0xEFB11FF1)
	check("VMLALDAV", .VMLALDAV, 0xEE800E00, 0xEF811FF1)
	check("VRMLALDAVH", .VRMLALDAVH, 0xEE800F00, 0xEF811FF1)
	check("VABAV", .VABAV, 0xEE800F01, 0xEFB10FF1)

	// ---- MVE specialized ops ----
	check("VCMUL", .VCMUL, 0xEE300E00, 0xEFF10FF1)
	check("VHCADD", .VHCADD, 0xEE000F00, 0xEFF10FF1)
	check("VBRSR", .VBRSR, 0xEE011E60, 0xEFC11FF1)
	check("VSHLC", .VSHLC, 0xEE000FC0, 0xFFC00FF1)
	check("VIDUP", .VIDUP, 0xEE010F6E, 0xEFC11F7E)

	// ---- MVE narrowing/widening ----
	check("VMOVNB", .VMOVNB, 0xFE310E81, 0xFFF31FF1)
	check("VMOVNT", .VMOVNT, 0xFE311E81, 0xFFF31FF1)
	check("VQMOVNB", .VQMOVNB, 0xEE330E01, 0xFFF31FF1)
	check("VSHLLB", .VSHLLB, 0xEE800F40, 0xEFC01FF1)
	check("VMULLB", .VMULLB, 0xEE000E00, 0xEFC11FF1)
	check("VMLALB", .VMLALB, 0xEE000E20, 0xEFC11FD1)
	check("VSHRNB", .VSHRNB, 0xEE800EC1, 0xEFC01FF1)

	// ---- MVE saturating doubling MAC ----
	check("VQDMLADH", .VQDMLADH, 0xEE000E00, 0xEFC11FF1)
	check("VQRDMLADH", .VQRDMLADH, 0xEE000E01, 0xEFC11FF1)

	// ---- MVE load/store ----
	check("VLDRB", .VLDRB, 0xED901E00, 0xFFF01F00)
	check("VLDRW", .VLDRW, 0xED901F00, 0xFFF01F80)
	check("VSTRW", .VSTRW, 0xED801F00, 0xFFF01F80)
	check("VLD20", .VLD20, 0xFC901E00, 0xFFF01EFF)
	check("VLD40", .VLD40, 0xFC901E01, 0xFFF01EFF)
	check("VST40", .VST40, 0xFC801E01, 0xFFF01EFF)

	// ---- ARMv8-M Secure Gateway + Non-secure transitions ----
	check("SG", .SG, 0xE97FE97F, 0xFFFFFFFF)
	check("BXNS", .BXNS, 0x00004704, 0x0000FF84)
	check("BLXNS", .BLXNS, 0x00004784, 0x0000FF84)

	// ---- PACBTI (ARMv8.1-M, Cortex-M85) ----
	check("PAC", .PAC, 0xF3AF801D, 0xFFFFFFFF)
	check("PACBTI", .PACBTI, 0xF3AF800D, 0xFFFFFFFF)
	check("AUT", .AUT, 0xF3AF802D, 0xFFFFFFFF)
	check("AUTG", .AUTG, 0xFB500F00, 0xFFF00FF0)
	check("BTI", .BTI, 0xF3AF800F, 0xFFFFFFFF)

	// ---- FEAT_I8MM (ARMv8.6 integer matrix multiply) ----
	check("VSMMLA", .VSMMLA, 0xFC200C40, 0xFFB00F50)
	check("VUMMLA", .VUMMLA, 0xFC200C50, 0xFFB00F50)
	check("VUSMMLA", .VUSMMLA, 0xFCA00C40, 0xFFB00F50)
	check("VUSDOT D", .VUSDOT, 0xFCA00D00, 0xFFB00F10)
	check("VSUDOT lane", .VSUDOT, 0xFE800D50, 0xFFB00F50)

	// ---- Lane-indexed NEON ----
	check("VMUL lane D .S16", .VMUL, 0xF2900840, 0xFFB00F50)
	check("VMUL lane Q .S32", .VMUL, 0xF3A00840, 0xFFB00F50)
	check("VMLA lane D", .VMLA, 0xF2900040, 0xFFB00F50)
	check("VMLS lane Q", .VMLS, 0xF3900440, 0xFFB00F50)
	check("VMULL lane .S16", .VMULL, 0xF2900A40, 0xFFB00F50)
	check("VMLAL lane .S32", .VMLAL, 0xF2A00240, 0xFFB00F50)
	check("VMLSL lane .S16", .VMLSL, 0xF2900640, 0xFFB00F50)
	check("VQDMULL lane .S16", .VQDMULL, 0xF2900B40, 0xFFB00F50)
	check("VQDMLAL lane .S32", .VQDMLAL, 0xF2A00340, 0xFFB00F50)
	check("VQDMLSL lane", .VQDMLSL, 0xF2900740, 0xFFB00F50)
	check("VQRDMLAH lane", .VQRDMLAH, 0xF2900E40, 0xFFB00F50)
	check("VQRDMLSH lane", .VQRDMLSH, 0xF2900F40, 0xFFB00F50)
	check("VCMLA lane D", .VCMLA, 0xFE000800, 0xFFB00F10)

	// ---- MVE polish ----
	check("VQABS", .VQABS, 0xFFB00740, 0xFFF30FF1)
	check("VQNEG", .VQNEG, 0xFFB007C0, 0xFFF30FF1)
	check("VMOVX", .VMOVX, 0xFEB00A40, 0xFFBF0FD0)
	check("VINS", .VINS, 0xFEB00AC0, 0xFFBF0FD0)

	// ---- MVE gather/scatter (LLVM-verified) ----
	check("VLDRW", .VLDRW, 0xFC900F40, 0xFEF00FF1)
	check("VLDRD", .VLDRD, 0xFC900FD0, 0xFEF00FF1)
	check("VSTRW", .VSTRW, 0xEC600F40, 0xFEF00FF1)
	check("VSTRB", .VSTRB, 0xEC600E00, 0xFEF00FF1)

	// ---- VFP fixed-point conversions (VCVT with #fbits) ----
	// The matrix runs cp (F16, F32, F64) outermost, then sx (16- then 32-bit
	// fixed point), then opc2 (F<-S, F<-U, S<-F, U<-F).
	check("VCVT F16.S16", .VCVT, 0x0EBA0940, 0x0FBF0FD0)
	check("VCVT S32.F16", .VCVT, 0x0EBE09C0, 0x0FBF0FD0)
	check("VCVT F32.S16", .VCVT, 0x0EBA0A40, 0x0FBF0FD0)
	check("VCVT S16.F32", .VCVT, 0x0EBE0A40, 0x0FBF0FD0)
	check("VCVT F32.S32", .VCVT, 0x0EBA0AC0, 0x0FBF0FD0)
	check("VCVT S32.F32", .VCVT, 0x0EBE0AC0, 0x0FBF0FD0)
	check("VCVT F64.S16", .VCVT, 0x0EBA0B40, 0x0FBF0FD0)
	check("VCVT S32.F64", .VCVT, 0x0EBE0BC0, 0x0FBF0FD0)

	// ---- NEON compare-with-zero ----
	check("VCEQ D .I8", .VCEQ, 0xF3B10100, 0xFFBB0FD0)
	check("VCEQ Q .F32", .VCEQ, 0xF3B90540, 0xFFBB0FD0)
	check("VCGE D", .VCGE, 0xF3B10080, 0xFFBB0FD0)
	check("VCGT D", .VCGT, 0xF3B10000, 0xFFBB0FD0)
	check("VCLE D", .VCLE, 0xF3B10180, 0xFFBB0FD0)
	check("VCLT D", .VCLT, 0xF3B10200, 0xFFBB0FD0)

	// ---- NEON replicate loads ----
	// The broadcast loads are VLD2/VLD3/VLD4 with an all-lanes list, and
	// that form leads each of their entry lists.
	check("VLD2 all-lanes", .VLD2, 0xF4A00D0F, 0xFFB00F0F)
	check("VLD3 all-lanes", .VLD3, 0xF4A00E0F, 0xFFB00F0F)
	check("VLD4 all-lanes", .VLD4, 0xF4A00F0F, 0xFFB00F0F)

	// ---- NEON single-element lane loads/stores ----
	check("VLD1 lane .8", .VLD1, 0xF4A0000F, 0xFFB00F1F)
	check("VLD1 lane .16", .VLD1, 0xF4A0040F, 0xFFB00F3F)
	check("VLD1 lane .32", .VLD1, 0xF4A0080F, 0xFFB00F7F)
	check("VLD2 lane .8", .VLD2, 0xF4A0010F, 0xFFB00F1F)
	check("VLD3 lane .16", .VLD3, 0xF4A0060F, 0xFFB00F3F)
	check("VLD4 lane .32", .VLD4, 0xF4A00B0F, 0xFFB00F7F)
	check("VST1 lane .8", .VST1, 0xF480000F, 0xFFB00F1F)
	check("VST3 lane .32", .VST3, 0xF4800A0F, 0xFFB00F7F)
	check("VST4 lane .16", .VST4, 0xF480070F, 0xFFB00F3F)

	// ---- MVE rounding-to-int (VPADD/VPMAX/VPMIN MVE forms removed - don't exist) ----
	check("VRINTA MVE", .VRINTA, 0xFFBA0540, 0xFFFB0FF1)
	check("VRINTN MVE", .VRINTN, 0xFFBA0440, 0xFFFB0FF1)
	check("VRINTP MVE", .VRINTP, 0xFFBA07C0, 0xFFFB0FF1)
	check("VRINTZ MVE", .VRINTZ, 0xFFBA05C0, 0xFFFB0FF1)

	fmt.printf("\n==> arm32 table: %d passed, %d failed\n", ok_count, fail_count)
}

// Each suite once, and the exit code from all of them.
main :: proc() {
	run_pipeline_tests()
	run_smoke()
	run_sweep_tests()
	if fail_count > 0 || fail > 0 { os.exit(1) }
}
