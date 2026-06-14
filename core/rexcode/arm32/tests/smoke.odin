package rexcode_arm32_tests

import "core:fmt"
import "core:os"
import a "../"

ok_count, fail_count: int

@(private="file")
check :: proc(name: string, mn: a.Mnemonic, idx: int, want_bits, want_mask: u32) {
	enc := a.ENCODING_TABLE[mn]
	if idx >= len(enc) {
		fmt.printf("  [FAIL] %s: entry %d not present (have %d entries)\n", name, idx, len(enc))
		fail_count += 1
		return
	}
	e := enc[idx]
	if e.bits != want_bits || e.mask != want_mask {
		fmt.printf("  [FAIL] %-22s got bits=%08x mask=%08x  want bits=%08x mask=%08x\n",
				   name, e.bits, e.mask, want_bits, want_mask)
		fail_count += 1
		return
	}
	fmt.printf("  [ok]   %-22s %08x / %08x (mode=%v feat=%v)\n",
			   name, e.bits, e.mask, e.mode, e.feature)
	ok_count += 1
}

run_smoke :: proc() {
	fmt.println("==== arm32 ENCODING_TABLE smoke test ====")

	// ---- A32 data processing ----
	check("ADD imm",         .ADD, 0, 0x02800000, 0x0FE00000)
	check("ADD reg",         .ADD, 1, 0x00800000, 0x0FE00010)
	check("ADD rsr",         .ADD, 2, 0x00800010, 0x0FE00090)
	check("ADDS imm",        .ADD, 3, 0x02900000, 0x0FF00000)
	check("SUB imm",         .SUB, 0, 0x02400000, 0x0FE00000)
	check("AND reg",         .AND, 1, 0x00000000, 0x0FE00010)
	check("ORR imm",         .ORR, 0, 0x03800000, 0x0FE00000)
	check("MOVW",            .MOVW, 0, 0x03000000, 0x0FF00000)
	check("MOVT",            .MOVT, 0, 0x03400000, 0x0FF00000)
	check("CMP imm",         .CMP, 0, 0x03500000, 0x0FF0F000)
	check("TST reg",         .TST, 1, 0x01100000, 0x0FF0F010)

	// ---- Multiply family ----
	check("MUL",             .MUL,   0, 0x00000090, 0x0FE000F0)
	check("MLA",             .MLA,   0, 0x00200090, 0x0FE000F0)
	check("MLS",             .MLS,   0, 0x00600090, 0x0FF000F0)
	check("UMULL",           .UMULL, 0, 0x00800090, 0x0FE000F0)
	check("SMULL",           .SMULL, 0, 0x00C00090, 0x0FE000F0)
	check("UMAAL",           .UMAAL, 0, 0x00400090, 0x0FF000F0)
	check("SMLABB",          .SMLABB, 0, 0x01000080, 0x0FF000F0)
	check("SDIV",            .SDIV, 0, 0x0710F010, 0x0FF0F0F0)
	check("UDIV",            .UDIV, 0, 0x0730F010, 0x0FF0F0F0)

	// ---- ARMv6 DSP/SIMD ----
	check("SADD16",          .SADD16, 0, 0x06100F10, 0x0FF00FF0)
	check("SADD8",           .SADD8,  0, 0x06100F90, 0x0FF00FF0)
	check("UADD8",           .UADD8,  0, 0x06500F90, 0x0FF00FF0)
	check("QADD16",          .QADD16, 0, 0x06200F10, 0x0FF00FF0)
	check("QADD8",           .QADD8,  0, 0x06200F90, 0x0FF00FF0)

	// ---- Extends + bit-field ----
	check("SXTB",            .SXTB, 0, 0x06AF0070, 0x0FFF0070)
	check("UXTH",            .UXTH, 0, 0x06FF0070, 0x0FFF0070)
	check("CLZ",             .CLZ,  0, 0x016F0F10, 0x0FFF0FF0)
	check("REV",             .REV,  0, 0x06BF0F30, 0x0FFF0FF0)
	check("RBIT",            .RBIT, 0, 0x06FF0F30, 0x0FFF0FF0)
	check("BFI",             .BFI,  0, 0x07C00010, 0x0FE00070)
	check("UBFX",            .UBFX, 0, 0x07E00050, 0x0FE00070)

	// ---- Branches + exceptions ----
	check("B (A32)",         .B,   0, 0x0A000000, 0x0F000000)
	check("BL (A32)",        .BL,  0, 0x0B000000, 0x0F000000)
	check("BX",              .BX,  0, 0x012FFF10, 0x0FFFFFF0)
	check("BLX reg",         .BLX, 0, 0x012FFF30, 0x0FFFFFF0)
	check("BLX imm",         .BLX, 1, 0xFA000000, 0xFE000000)
	check("SVC (A32)",       .SVC, 0, 0x0F000000, 0x0F000000)
	check("BKPT (A32)",      .BKPT,0, 0xE1200070, 0xFFF000F0)
	check("UDF",             .UDF, 0, 0xE7F000F0, 0xFFF000F0)

	// ---- Status register access ----
	check("MRS",             .MRS, 0, 0x010F0000, 0x0FBF0FFF)
	check("MSR imm",         .MSR, 0, 0x0320F000, 0x0FB0F000)

	// ---- Hints / barriers ----
	check("NOP (A32)",       .NOP, 0, 0x0320F000, 0x0FFFFFFF)
	check("WFE (A32)",       .WFE, 0, 0x0320F002, 0x0FFFFFFF)
	check("DMB (A32)",       .DMB, 0, 0xF57FF050, 0xFFFFFFF0)
	check("ISB (A32)",       .ISB, 0, 0xF57FF060, 0xFFFFFFF0)
	check("CLREX (A32)",     .CLREX, 0, 0xF57FF01F, 0xFFFFFFFF)

	// ---- Load/Store ----
	check("LDR imm",         .LDR,  0, 0x05900000, 0x0F700000)
	check("LDR pre",         .LDR,  1, 0x05B00000, 0x0F700000)
	check("LDR post",        .LDR,  2, 0x04900000, 0x0F700000)
	check("STR imm",         .STR,  0, 0x05800000, 0x0F700000)
	check("LDRB imm",        .LDRB, 0, 0x05D00000, 0x0F700000)
	check("STRH imm",        .STRH, 0, 0x01C000B0, 0x0F7000F0)
	check("LDRSB imm",       .LDRSB, 0, 0x01D000D0, 0x0F7000F0)
	check("LDRD",            .LDRD, 0, 0x01C000D0, 0x0F7000F0)
	check("LDM",             .LDM, 0, 0x08900000, 0x0FD00000)
	check("STM DB",          .STM, 4, 0x09000000, 0x0FD00000)
	check("PUSH",            .PUSH, 0, 0x092D0000, 0x0FFF0000)
	check("POP",             .POP, 0, 0x08BD0000, 0x0FFF0000)
	check("SWP",             .SWP, 0, 0x01000090, 0x0FF00FF0)

	// ---- Exclusive ----
	check("LDREX",           .LDREX,  0, 0x01900F9F, 0x0FF00FFF)
	check("STREX",           .STREX,  0, 0x01800F90, 0x0FF00FF0)
	check("LDREXB",          .LDREXB, 0, 0x01D00F9F, 0x0FF00FFF)
	check("LDREXD",          .LDREXD, 0, 0x01B00F9F, 0x0FF00FFF)
	check("LDA (v8)",        .LDA,    0, 0x01900C9F, 0x0FF00FFF)
	check("STL (v8)",        .STL,    0, 0x0180FC90, 0x0FF0FFF0)

	// ---- CRC32 ----
	check("CRC32B",          .CRC32B,  0, 0x01000040, 0x0FF00FF0)
	check("CRC32CW",         .CRC32CW, 0, 0x01400240, 0x0FF00FF0)

	// ---- VFP scalar ----
	check("VADD.F32",        .VADD, 0, 0x0E300A00, 0x0FB00B50)
	check("VADD.F64",        .VADD, 1, 0x0E300B00, 0x0FB00B50)
	check("VSUB.F32",        .VSUB, 0, 0x0E300A40, 0x0FB00B50)
	check("VMUL.F32",        .VMUL, 0, 0x0E200A00, 0x0FB00B50)
	check("VDIV.F32",        .VDIV, 0, 0x0E800A00, 0x0FB00B50)
	check("VABS.F32",        .VABS, 0, 0x0EB00AC0, 0x0FBF0FD0)
	check("VNEG.F32",        .VNEG, 0, 0x0EB10A40, 0x0FBF0FD0)
	check("VSQRT.F32",       .VSQRT,0, 0x0EB10AC0, 0x0FBF0FD0)
	check("VFMA.F32",        .VFMA, 0, 0x0EA00A00, 0x0FB00B50)
	check("VLDR.F32",        .VLDR, 0, 0x0D100A00, 0x0F300F00)
	check("VSTR.F64",        .VSTR, 1, 0x0D000B00, 0x0F300F00)
	check("VMRS",            .VMRS, 0, 0x0EF10A10, 0x0FFF0FFF)
	check("VMSR",            .VMSR, 0, 0x0EE10A10, 0x0FFF0FFF)
	check("VPUSH.F32",       .VPUSH,0, 0x0D2D0A00, 0x0FFF0F00)
	check("VPOP.F64",        .VPOP, 1, 0x0CBD0B00, 0x0FFF0F00)
	check("VCMP.F32",        .VCMP, 0, 0x0EB40A40, 0x0FBF0F50)

	// ---- ARMv8 FP ----
	check("VMAXNM.F32",      .VMAXNM, 0, 0xFE800A00, 0xFFB00B50)
	check("VMINNM.F32",      .VMINNM, 0, 0xFE800A40, 0xFFB00B50)
	check("VCVTA.F32",       .VCVTA, 0, 0xFEBC0A40, 0xFFBF0FD0)
	check("VRINTA.F32",      .VRINTA, 0, 0xFEB80A40, 0xFFBF0FD0)

	// ---- NEON ----
	check("VADD NEON.I8 D",  .VADD, 5,  0xF2000800, 0xFFB00F10)
	check("VADD NEON.I32 D", .VADD, 7,  0xF2200800, 0xFFB00F10)
	check("VADD NEON.I8 Q",  .VADD, 9,  0xF2000840, 0xFFB00F50)
	check("VADD NEON.F32 D", .VADD, 13, 0xF2000D00, 0xFFB00F10)
	check("VADD NEON.F32 Q", .VADD, 14, 0xF2000D40, 0xFFB00F50)
	check("VADD VFP F16",    .VADD, 2,  0x0E300900, 0x0FB00F50)
	check("VADD NEON F16 D", .VADD, 3,  0xF2100D00, 0xFFB00F10)
	check("VADD NEON F16 Q", .VADD, 4,  0xF2100D40, 0xFFB00F50)
	check("AESE (v8)",       .AESE, 0, 0xF3B00300, 0xFFB30FD0)
	check("SHA1H",           .SHA1H, 0, 0xF3B902C0, 0xFFBF0FD0)
	check("SHA1C",           .SHA1C, 0, 0xF2000C40, 0xFFB00F50)
	// NEON arithmetic/logical
	check("VMUL NEON.I8 D",  .VMUL, 5, 0xF2000910, 0xFFB00F10)
	check("VMUL NEON.F32 D", .VMUL, 13, 0xF3000D10, 0xFFB00F10)
	check("VAND",            .VAND, 0, 0xF2000110, 0xFFB00F10)
	check("VORR",            .VORR, 0, 0xF2200110, 0xFFB00F10)
	check("VEOR",            .VEOR, 0, 0xF3000110, 0xFFB00F10)
	check("VBSL",            .VBSL, 0, 0xF3100110, 0xFFB00F10)
	check("VMAX.S16 D",      .VMAX, 1, 0xF2100600, 0xFFB00F10)
	check("VMIN.U8 D",       .VMIN, 6, 0xF3000610, 0xFFB00F10)
	check("VCEQ.I8 D",       .VCEQ, 0, 0xF3000810, 0xFFB00F10)
	check("VCGT.S8 D",       .VCGT, 0, 0xF2000300, 0xFFB00F10)
	check("VCGE.S8 D",       .VCGE, 0, 0xF2000310, 0xFFB00F10)
	check("VQADD.S8 D",      .VQADD, 0, 0xF2000010, 0xFFB00F10)
	check("VQSUB.U8 Q",      .VQSUB, 8, 0xF3000210, 0xFFB00F10)
	check("VHADD.S8 D",      .VHADD, 0, 0xF2000000, 0xFFB00F10)
	check("VABD.S8 D",       .VABD,  0, 0xF2000700, 0xFFB00F10)
	check("VPADD.I8 D",      .VPADD, 0, 0xF2000B10, 0xFFB00F10)
	// NEON unary + shifts
	check("VABS NEON.S8 D",  .VABS, 2, 0xF3B10300, 0xFFB30FD0)
	check("VNEG NEON.F32 D", .VNEG, 8, 0xF3B90780, 0xFFB30FD0)
	check("VMVN",            .VMVN, 0, 0xF3B00580, 0xFFB30FD0)
	check("VCNT",            .VCNT, 0, 0xF3B00500, 0xFFB30FD0)
	check("VCLZ.I8 D",       .VCLZ, 0, 0xF3B00480, 0xFFB30FD0)
	check("VSHR.S8 D imm",   .VSHR, 0, 0xF2800010, 0xFE800F10)
	check("VSHL reg.S8 D",   .VSHL, 0, 0xF2000400, 0xFFB00F10)
	check("VEXT D",          .VEXT, 0, 0xF2B00000, 0xFFB00010)
	check("VDUP from Rt D",  .VDUP, 0, 0x0EC00B10, 0x0FF00FD0)
	check("VREV64.I8 D",     .VREV64, 0, 0xF3B00000, 0xFFB30FD0)
	check("VTRN.I8 D",       .VTRN, 0, 0xF3B20080, 0xFFB30FD0)
	check("VZIP.I8 D",       .VZIP, 0, 0xF3B20180, 0xFFB30FD0)
	check("VTBL",            .VTBL, 0, 0xF3B00800, 0xFFB00F70)
	check("VRECPE F32 D",    .VRECPE, 2, 0xF3BB0500, 0xFFBF0FD0)
	check("VLD1 1-reg",      .VLD1, 0, 0xF4200700, 0xFFF00F00)
	check("VST1 1-reg",      .VST1, 0, 0xF4000700, 0xFFF00F00)
	check("VLD2 2-reg",      .VLD2, 0, 0xF4200800, 0xFFF00F00)
	check("VLD3 3-reg",      .VLD3, 0, 0xF4200400, 0xFFF00F00)
	check("VLD4 4-reg",      .VLD4, 0, 0xF4200000, 0xFFF00F00)
	check("VMULL.S8",        .VMULL, 0, 0xF2800C00, 0xFFB00F50)

	// ---- Thumb-2 ----
	check("CBZ (T16)",       .CBZ, 0, 0x0000B100, 0x0000FD00)
	check("CBNZ (T16)",      .CBNZ, 0, 0x0000B900, 0x0000FD00)
	check("IT",              .IT, 0, 0x0000BF00, 0x0000FF00)
	check("TBB",             .TBB, 0, 0xE8D0F000, 0xFFF0FFF0)
	check("TBH",             .TBH, 0, 0xE8D0F010, 0xFFF0FFF0)

	// ---- T16 Thumb-1 (GBA-critical) ----
	// LSL/LSR/ASR: entries 0..1 are A32, 2 = T16 imm, 3 = T16 reg
	check("LSL T16 imm",     .LSL, 2, 0x00000000, 0x0000F800)
	check("LSL T16 reg",     .LSL, 3, 0x00004080, 0x0000FFC0)
	check("LSR T16 imm",     .LSR, 2, 0x00000800, 0x0000F800)
	check("ASR T16 imm",     .ASR, 2, 0x00001000, 0x0000F800)
	check("ROR T16 reg",     .ROR, 2, 0x000041C0, 0x0000FFC0)
	check("RRX (A32 only)",  .RRX, 0, 0x01A00060, 0x0FFF0FF0)
	check("ADR T16",         .ADR, 0, 0x0000A000, 0x0000F800)
	check("NEG T16",         .NEG, 0, 0x00004240, 0x0000FFC0)
	// ADD T16 entries start after 6 A32 entries (indices 0-5)
	check("ADD T16 reg3",    .ADD, 6, 0x00001800, 0x0000FE00)
	check("ADD T16 imm3",    .ADD, 7, 0x00001C00, 0x0000FE00)
	check("ADD T16 imm8",    .ADD, 8, 0x00003000, 0x0000F800)
	check("ADD T16 hi-reg",  .ADD, 9, 0x00004400, 0x0000FF00)
	check("ADD T16 SP+imm",  .ADD, 10, 0x0000A800, 0x0000F800)
	check("ADD T16 SP,imm7", .ADD, 11, 0x0000B000, 0x0000FF80)
	check("SUB T16 reg3",    .SUB, 6, 0x00001A00, 0x0000FE00)
	check("SUB T16 imm3",    .SUB, 7, 0x00001E00, 0x0000FE00)
	check("SUB T16 imm8",    .SUB, 8, 0x00003800, 0x0000F800)
	check("SUB T16 SP,imm7", .SUB, 9, 0x0000B080, 0x0000FF80)
	check("MOV T16 imm8",    .MOV, 6, 0x00002000, 0x0000F800)
	check("MOV T16 hi-reg",  .MOV, 7, 0x00004600, 0x0000FF00)
	check("CMP T16 imm8",    .CMP, 3, 0x00002800, 0x0000F800)
	check("CMP T16 reg",     .CMP, 4, 0x00004280, 0x0000FFC0)
	check("CMP T16 hi-reg",  .CMP, 5, 0x00004500, 0x0000FF00)
	check("AND T16",         .AND, 6, 0x00004000, 0x0000FFC0)
	check("EOR T16",         .EOR, 6, 0x00004040, 0x0000FFC0)
	check("ORR T16",         .ORR, 6, 0x00004300, 0x0000FFC0)
	check("BIC T16",         .BIC, 6, 0x00004380, 0x0000FFC0)
	check("MVN T16",         .MVN, 6, 0x000043C0, 0x0000FFC0)
	check("MUL T16",         .MUL, 2, 0x00004340, 0x0000FFC0)
	check("TST T16",         .TST, 3, 0x00004200, 0x0000FFC0)
	check("CMN T16",         .CMN, 3, 0x000042C0, 0x0000FFC0)
	check("ADC T16",         .ADC, 6, 0x00004140, 0x0000FFC0)
	check("SBC T16",         .SBC, 6, 0x00004180, 0x0000FFC0)

	// T16 Load/store
	check("LDR T16 pc-rel",  .LDR,  4, 0x00004800, 0x0000F800)
	check("LDR T16 reg-off", .LDR,  5, 0x00005800, 0x0000FE00)
	check("LDR T16 imm5",    .LDR,  6, 0x00006800, 0x0000F800)
	check("LDR T16 sp-rel",  .LDR,  7, 0x00009800, 0x0000F800)
	check("STR T16 reg-off", .STR,  4, 0x00005000, 0x0000FE00)
	check("STR T16 imm5",    .STR,  5, 0x00006000, 0x0000F800)
	check("STR T16 sp-rel",  .STR,  6, 0x00009000, 0x0000F800)
	check("LDRB T16 reg",    .LDRB, 4, 0x00005C00, 0x0000FE00)
	check("LDRB T16 imm5",   .LDRB, 5, 0x00007800, 0x0000F800)
	check("STRB T16 reg",    .STRB, 4, 0x00005400, 0x0000FE00)
	check("STRB T16 imm5",   .STRB, 5, 0x00007000, 0x0000F800)
	check("LDRH T16 reg",    .LDRH, 4, 0x00005A00, 0x0000FE00)
	check("LDRH T16 imm5",   .LDRH, 5, 0x00008800, 0x0000F800)
	check("STRH T16 reg",    .STRH, 4, 0x00005200, 0x0000FE00)
	check("STRH T16 imm5",   .STRH, 5, 0x00008000, 0x0000F800)
	check("LDRSB T16",       .LDRSB,4, 0x00005600, 0x0000FE00)
	check("LDRSH T16",       .LDRSH,4, 0x00005E00, 0x0000FE00)
	check("LDM T16",         .LDM,  5, 0x0000C800, 0x0000F800)
	check("STM T16",         .STM,  5, 0x0000C000, 0x0000F800)
	check("PUSH T16",        .PUSH, 1, 0x0000B400, 0x0000FE00)
	check("POP T16",         .POP,  1, 0x0000BC00, 0x0000FE00)

	// T16 branches + exception
	check("B<cond> T16",     .B,   1, 0x0000D000, 0x0000F000)
	check("B unc T16",       .B,   2, 0x0000E000, 0x0000F800)
	check("B<cond> T32",     .B,   3, 0xF0008000, 0xF800D000)
	check("B unc T32",       .B,   4, 0xF0009000, 0xF800D000)
	check("BL T32",          .BL,  1, 0xF000D000, 0xF800D000)
	check("BX T16",          .BX,  1, 0x00004700, 0x0000FF87)
	check("BLX T16 reg",     .BLX, 2, 0x00004780, 0x0000FF87)
	check("SVC T16",         .SVC, 1, 0x0000DF00, 0x0000FF00)
	check("BKPT T16",        .BKPT,1, 0x0000BE00, 0x0000FF00)

	// T16 extends + REV
	check("SXTB T16",        .SXTB, 1, 0x0000B240, 0x0000FFC0)
	check("SXTH T16",        .SXTH, 1, 0x0000B200, 0x0000FFC0)
	check("UXTB T16",        .UXTB, 1, 0x0000B2C0, 0x0000FFC0)
	check("UXTH T16",        .UXTH, 1, 0x0000B280, 0x0000FFC0)
	check("REV T16",         .REV,  1, 0x0000BA00, 0x0000FFC0)
	check("REV16 T16",       .REV16, 1, 0x0000BA40, 0x0000FFC0)
	check("REVSH T16",       .REVSH, 1, 0x0000BAC0, 0x0000FFC0)

	// T16/T32 hints + barriers
	check("NOP T16",         .NOP, 1, 0x0000BF00, 0x0000FFFF)
	check("NOP T32",         .NOP, 2, 0xF3AF8000, 0xFFFFFFFF)
	check("DMB T32",         .DMB, 1, 0xF3BF8F50, 0xFFFFFFF0)
	check("CLREX T32",       .CLREX, 1, 0xF3BF8F2F, 0xFFFFFFFF)

	// ---- T32 32-bit Thumb-2 data-processing ----
	check("AND T32 imm",     .AND, 7,  0xF0000000, 0xFBE08000)
	check("AND T32 reg",     .AND, 9,  0xEA000000, 0xFFE08000)
	check("EOR T32 imm",     .EOR, 7,  0xF0800000, 0xFBE08000)
	check("ORR T32 imm",     .ORR, 7,  0xF0400000, 0xFBE08000)
	check("BIC T32 imm",     .BIC, 7,  0xF0200000, 0xFBE08000)
	check("MVN T32 imm",     .MVN, 7,  0xF06F0000, 0xFBEF8000)
	check("TST T32 imm",     .TST, 4,  0xF0100F00, 0xFBF08F00)
	check("TEQ T32 imm",     .TEQ, 3,  0xF0900F00, 0xFBF08F00)
	check("CMP T32 imm",     .CMP, 6,  0xF1B00F00, 0xFBF08F00)
	check("CMN T32 imm",     .CMN, 4,  0xF1100F00, 0xFBF08F00)
	check("ADC T32 imm",     .ADC, 7,  0xF1400000, 0xFBE08000)
	check("SBC T32 imm",     .SBC, 7,  0xF1600000, 0xFBE08000)
	check("RSB T32 imm",     .RSB, 6,  0xF1C00000, 0xFBE08000)
	check("MOVW T32",        .MOVW, 1, 0xF2400000, 0xFBF08000)
	check("MOVT T32",        .MOVT, 1, 0xF2C00000, 0xFBF08000)
	check("BFC T32",         .BFC,  1, 0xF36F0000, 0xFFFF8000)
	check("BFI T32",         .BFI,  1, 0xF3600000, 0xFFF08000)
	check("SBFX T32",        .SBFX, 1, 0xF3400000, 0xFFF08000)
	check("UBFX T32",        .UBFX, 1, 0xF3C00000, 0xFFF08000)
	check("MUL T32",         .MUL,  3, 0xFB00F000, 0xFFF0F0F0)
	check("MLA T32",         .MLA,  2, 0xFB000000, 0xFFF000F0)
	check("MLS T32",         .MLS,  1, 0xFB000010, 0xFFF000F0)
	check("UMULL T32",       .UMULL, 2, 0xFBA00000, 0xFFF000F0)
	check("SMULL T32",       .SMULL, 2, 0xFB800000, 0xFFF000F0)
	check("SDIV T32",        .SDIV, 1, 0xFB90F0F0, 0xFFF0F0F0)
	check("UDIV T32",        .UDIV, 1, 0xFBB0F0F0, 0xFFF0F0F0)
	check("LDR T32 imm12",   .LDR,  8, 0xF8D00000, 0xFFF00000)
	check("LDR T32 lit",     .LDR, 10, 0xF85F0000, 0xFF7F0000)
	check("STR T32 imm12",   .STR,  7, 0xF8C00000, 0xFFF00000)
	check("LDRB T32 imm12",  .LDRB, 6, 0xF8900000, 0xFFF00000)
	check("STRB T32 imm12",  .STRB, 6, 0xF8800000, 0xFFF00000)
	check("LDRH T32 imm12",  .LDRH, 6, 0xF8B00000, 0xFFF00000)
	check("STRH T32 imm12",  .STRH, 6, 0xF8A00000, 0xFFF00000)
	check("LDRSB T32 imm12", .LDRSB, 5, 0xF9900000, 0xFFF00000)
	check("LDRSH T32 imm12", .LDRSH, 5, 0xF9B00000, 0xFFF00000)
	check("LDM T32 IA",      .LDM, 6, 0xE8900000, 0xFFD00000)
	check("LDM T32 DB",      .LDM, 7, 0xE9100000, 0xFFD00000)
	check("STM T32 IA",      .STM, 6, 0xE8800000, 0xFFD00000)
	check("PUSH T32",        .PUSH, 2, 0xE92D0000, 0xFFFF0000)
	check("POP T32",         .POP,  2, 0xE8BD0000, 0xFFFF0000)

	// ---- Round 2: more NEON + T32 forms ----
	check("VMLAL.S8",        .VMLAL, 0, 0xF2800800, 0xFFB00F50)
	check("VMLSL.S16",       .VMLSL, 1, 0xF2900A00, 0xFFB00F50)
	check("VQDMULH.S16",     .VQDMULH, 0, 0xF2100B00, 0xFFB00F10)
	check("VQRDMULH.S16",    .VQRDMULH, 0, 0xF3100B00, 0xFFB00F10)
	check("VQDMULL.S16",     .VQDMULL, 0, 0xF2900D00, 0xFFB00F50)
	check("VMOVL.S8",        .VMOVL, 0, 0xF2880A10, 0xFFB80FD0)
	check("VMOVN.I16",       .VMOVN, 0, 0xF3B20200, 0xFFB30FD0)
	check("VQMOVN.S16",      .VQMOVN, 0, 0xF3B20280, 0xFFB30FD0)
	check("VQMOVUN.S16",     .VQMOVUN, 0, 0xF3B20240, 0xFFB30FD0)
	check("VSHRN imm",       .VSHRN, 0, 0xF2800810, 0xFE800FD0)
	check("VQSHRN.S",        .VQSHRN, 0, 0xF2800910, 0xFE800FD0)
	check("VPADDL.S8",       .VPADDL, 0, 0xF3B00200, 0xFFB30FD0)
	check("VPADAL.S8",       .VPADAL, 0, 0xF3B00600, 0xFFB30FD0)
	check("VSWP.I8",         .VSWP, 0, 0xF3B20000, 0xFFB30FD0)
	check("VACGE.F32 D",     .VACGE, 0, 0xF3000E10, 0xFFB00F10)
	check("VACGT.F32 D",     .VACGT, 0, 0xF3200E10, 0xFFB00F10)

	// ---- T32 forms of A32 misc ----
	check("LDREX T32",       .LDREX, 1, 0xE8500F00, 0xFFF00F00)
	check("STREX T32",       .STREX, 1, 0xE8400000, 0xFFF00000)
	check("LDREXB T32",      .LDREXB, 1, 0xE8D00F4F, 0xFFF00FFF)
	check("LDREXD T32",      .LDREXD, 1, 0xE8D0007F, 0xFFF000FF)
	check("MRS T32",         .MRS, 1, 0xF3EF8000, 0xFFFFF0FF)
	check("MSR T32",         .MSR, 2, 0xF3808000, 0xFFF0F0FF)
	check("LDRD T32",        .LDRD, 4, 0xE9500000, 0xFE500000)
	check("STRD T32",        .STRD, 4, 0xE9400000, 0xFE500000)
	check("SXTB T32",        .SXTB, 2, 0xFA4FF080, 0xFFFFF0C0)
	check("UXTH T32",        .UXTH, 2, 0xFA1FF080, 0xFFFFF0C0)
	check("REV T32",         .REV, 2, 0xFA90F080, 0xFFF0F0F0)
	check("RBIT T32",        .RBIT, 1, 0xFA90F0A0, 0xFFF0F0F0)
	check("CLZ T32",         .CLZ, 1, 0xFAB0F080, 0xFFF0F0F0)
	check("PLD T32",         .PLD, 1, 0xF890F000, 0xFFF0F000)
	check("PLI T32",         .PLI, 1, 0xF990F000, 0xFFF0F000)
	check("SXTAB T32",       .SXTAB, 1, 0xFA40F080, 0xFFF0F0C0)
	check("QADD T32",        .QADD, 1, 0xFA80F080, 0xFFF0F0F0)
	check("QSUB T32",        .QSUB, 1, 0xFA80F0A0, 0xFFF0F0F0)
	check("SSAT T32",        .SSAT, 1, 0xF3000000, 0xFFD08020)
	check("USAT T32",        .USAT, 1, 0xF3800000, 0xFFD08020)
	check("SADD8 T32",       .SADD8,  1, 0xFA80F000, 0xFFF0F0F0)
	check("SADD16 T32",      .SADD16, 1, 0xFA90F000, 0xFFF0F0F0)
	check("UADD8 T32",       .UADD8,  1, 0xFA80F040, 0xFFF0F0F0)
	check("QADD16 T32",      .QADD16, 1, 0xFA90F010, 0xFFF0F0F0)
	check("SHADD8 T32",      .SHADD8, 1, 0xFA80F020, 0xFFF0F0F0)
	check("UQADD8 T32",      .UQADD8, 1, 0xFA80F050, 0xFFF0F0F0)
	check("UHADD8 T32",      .UHADD8, 1, 0xFA80F060, 0xFFF0F0F0)
	check("UDF T32",         .UDF, 2, 0xF7F0A000, 0xFFF0F000)
	check("UDF T16",         .UDF, 1, 0x0000DE00, 0x0000FF00)

	// ---- Extensions: Dot product / FCMA / FHM / BF16 ----
	check("VSDOT D",         .VSDOT, 0, 0xFC200D00, 0xFFB00F10)
	check("VUDOT Q",         .VUDOT, 1, 0xFC200D50, 0xFFB00F50)
	check("VSDOT_LANE D",    .VSDOT_LANE, 0, 0xFE200D00, 0xFFB00F10)
	check("VCMLA D",         .VCMLA, 0, 0xFC200800, 0xFC800F10)
	check("VCADD Q",         .VCADD, 1, 0xFC800840, 0xFE800F50)
	check("VFMAL D",         .VFMAL, 0, 0xFC200810, 0xFFB00F10)
	check("VFMSL Q",         .VFMSL, 1, 0xFCA00850, 0xFFB00F50)
	check("VCVT BF16",       .VCVT_BF16, 0, 0xF3B60600, 0xFFBF0FD0)
	check("VDOT BF16 D",     .VDOT_BF16, 0, 0xFC000D00, 0xFFB00F10)
	check("VFMA BF16 Q",     .VFMA_BF16, 0, 0xFC300850, 0xFFB00F50)
	check("VMMLA BF16 Q",    .VMMLA_BF16, 0, 0xFC000C40, 0xFFB00F50)

	// ---- Barriers / hints: ESB, PSB CSYNC, TSB CSYNC, CSDB, SB ----
	check("ESB A32",         .ESB, 0, 0x0320F010, 0x0FFFFFFF)
	check("ESB T32",         .ESB, 1, 0xF3AF8010, 0xFFFFFFFF)
	check("PSB_CSYNC A32",   .PSB_CSYNC, 0, 0x0320F011, 0x0FFFFFFF)
	check("TSB_CSYNC A32",   .TSB_CSYNC, 0, 0x0320F012, 0x0FFFFFFF)
	check("CSDB A32",        .CSDB, 0, 0x0320F014, 0x0FFFFFFF)
	check("CSDB T32",        .CSDB, 1, 0xF3AF8014, 0xFFFFFFFF)
	check("SB A32",          .SB, 0, 0xF57FF070, 0xFFFFFFFF)
	check("SB T32",          .SB, 1, 0xF3BF8F70, 0xFFFFFFFF)

	// ---- SETPAN (ARMv8.1) ----
	check("SETPAN A32",      .SETPAN, 0, 0xF1100000, 0xFFFFFDFF)
	check("SETPAN T16",      .SETPAN, 1, 0x0000B610, 0x0000FFF7)

	// ---- VQRDMLAH / VQRDMLSH (FEAT_RDM, ARMv8.1) ----
	check("VQRDMLAH D .S16", .VQRDMLAH, 0, 0xF3100B10, 0xFFB00F10)
	check("VQRDMLAH D .S32", .VQRDMLAH, 1, 0xF3200B10, 0xFFB00F10)
	check("VQRDMLAH Q .S16", .VQRDMLAH, 2, 0xF3100B50, 0xFFB00F50)
	check("VQRDMLSH D .S16", .VQRDMLSH, 0, 0xF3100C10, 0xFFB00F10)
	check("VQRDMLSH Q .S32", .VQRDMLSH, 3, 0xF3200C50, 0xFFB00F50)

	// ---- ARMv8-M Security Extensions (TrustZone-M) ----
	check("TT",              .TT,   0, 0xE840F000, 0xFFF0F0C0)
	check("TTT",             .TTT,  0, 0xE840F040, 0xFFF0F0C0)
	check("TTA",             .TTA,  0, 0xE840F080, 0xFFF0F0C0)
	check("TTAT",            .TTAT, 0, 0xE840F0C0, 0xFFF0F0C0)

	// ---- ARMv8.1-M low-overhead loops ----
	check("WLS",             .WLS,  0, 0xF040C001, 0xFFF0F001)
	check("DLS",             .DLS,  0, 0xF040E001, 0xFFF0FFFF)
	check("LE",              .LE,   0, 0xF00FC001, 0xFFFFF001)
	check("LETP",            .LETP, 0, 0xF01FC001, 0xFFFFF001)
	check("LCTP",            .LCTP, 0, 0xF00FE001, 0xFFFFFFFF)

	// ---- Custom Datapath Extension (CDE) ----
	check("CX1",             .CX1,   0, 0xEE000000, 0xFF800000)
	check("CX1A",            .CX1A,  0, 0xFE000000, 0xFF800000)
	check("CX2",             .CX2,   0, 0xEE400000, 0xFFC00000)
	check("CX3",             .CX3,   0, 0xEE800000, 0xFFC00000)
	check("VCX1 S",          .VCX1,  0, 0xEC200000, 0xFF300000)
	check("VCX1 D",          .VCX1,  1, 0xEC300000, 0xFF300000)
	check("VCX3 D",          .VCX3,  1, 0xEC900000, 0xFF300000)

	// ---- MVE predication and tail-loop (LLVM-verified) ----
	check("VPT",             .VPT,       0, 0xFE010F00, 0xFE018FF0)
	check("VPST",            .VPST,      0, 0xFE710F4D, 0xFFFFFFFF)
	check("VPSEL",           .VPSEL,     0, 0xFE010F01, 0xFFB10FF1)
	check("VCTP",            .VCTP,      0, 0xF000E801, 0xFFC0FFFF)

	// ---- MVE reductions (LLVM-verified) ----
	check("VADDV",           .VADDV,     0, 0xEEF10F00, 0xEFF30FD1)
	check("VADDVA",          .VADDVA,    0, 0xEEF10F20, 0xEFF30FD1)
	check("VMAXV",           .VMAXV,     0, 0xEEE20F00, 0xEFF30FD1)
	check("VMINV",           .VMINV,     0, 0xEEE20F80, 0xEFF30FD1)
	check("VMAXNMV",         .VMAXNMV,   0, 0xEEEE0F00, 0xEFFF0FD1)

	// ---- MVE MAC reductions ----
	check("VMLAV",           .VMLAV,     0, 0xEEB00F00, 0xEFB10F51)
	check("VMLADAV",         .VMLADAV,   0, 0xEEB00F00, 0xEFB10F51)
	check("VMLALDAV",        .VMLALDAV,  0, 0xEE800E00, 0xEFB10F51)
	check("VRMLALDAVH",      .VRMLALDAVH,0, 0xEE800F00, 0xEFB10F51)
	check("VABAV",           .VABAV,     0, 0xEE800F01, 0xEFB11051)

	// ---- MVE specialized ops ----
	check("VCMUL",           .VCMUL,     0, 0xEE300E00, 0xEFB10F51)
	check("VHCADD",          .VHCADD,    0, 0xEE000F00, 0xEFB10F51)
	check("VBRSR",           .VBRSR,     0, 0xEE011E60, 0xEF811F71)
	check("VSHLC",           .VSHLC,     0, 0xEE000FC0, 0xFFC00FF1)
	check("VIDUP",           .VIDUP,     0, 0xEE010F6E, 0xEF811F7E)

	// ---- MVE narrowing/widening ----
	check("VMOVNB",          .VMOVNB,    0, 0xFE310E81, 0xFFB31FD1)
	check("VMOVNT",          .VMOVNT,    0, 0xFE311E81, 0xFFB31FD1)
	check("VQMOVNB",         .VQMOVNB,   0, 0xEE330E01, 0xFFB31FD1)
	check("VSHLLB",          .VSHLLB,    0, 0xEE800F40, 0xEF801FD1)
	check("VMULLB",          .VMULLB,    0, 0xEE000E00, 0xEF811F51)
	check("VMLALB",          .VMLALB,    0, 0xEE000E20, 0xEF811F51)
	check("VSHRNB",          .VSHRNB,    0, 0xEE800EC1, 0xEF801FD1)

	// ---- MVE saturating doubling MAC ----
	check("VQDMLADH",        .VQDMLADH,   0, 0xEE000E00, 0xEF811F51)
	check("VQRDMLADH",       .VQRDMLADH,  0, 0xEE000E01, 0xEF811F51)

	// ---- MVE load/store ----
	check("VLDRB",           .VLDRB,     0, 0xED901E00, 0xFFB01F00)
	check("VLDRW",           .VLDRW,     0, 0xED901F00, 0xFFB01F80)
	check("VSTRW",           .VSTRW,     0, 0xED801F00, 0xFFB01F80)
	check("VLD20",           .VLD20,     0, 0xFC901E00, 0xFFB01EFF)
	check("VLD40",           .VLD40,     0, 0xFC901E01, 0xFFB01EFF)
	check("VST40",           .VST40,     0, 0xFC801E01, 0xFFB01EFF)

	// ---- ARMv8-M Secure Gateway + Non-secure transitions ----
	check("SG",              .SG,    0, 0xE97FE97F, 0xFFFFFFFF)
	check("BXNS",            .BXNS,  0, 0x00004704, 0x0000FF87)
	check("BLXNS",           .BLXNS, 0, 0x00004784, 0x0000FF87)

	// ---- PACBTI (ARMv8.1-M, Cortex-M85) ----
	check("PAC",             .PAC,    0, 0xF3AF801D, 0xFFFFFFFF)
	check("PACBTI",          .PACBTI, 0, 0xF3AF800D, 0xFFFFFFFF)
	check("AUT",             .AUT,    0, 0xF3AF802D, 0xFFFFFFFF)
	check("AUTG",            .AUTG,   0, 0xFB50F000, 0xFFF0F0F0)
	check("BTI",             .BTI,    0, 0xF3AF80F0, 0xFFFFFFFF)

	// ---- FEAT_I8MM (ARMv8.6 integer matrix multiply) ----
	check("VSMMLA",          .VSMMLA,    0, 0xFC200C40, 0xFFB00F50)
	check("VUMMLA",          .VUMMLA,    0, 0xFC200C50, 0xFFB00F50)
	check("VUSMMLA",         .VUSMMLA,   0, 0xFCA00C40, 0xFFB00F50)
	check("VUSDOT D",        .VUSDOT,    0, 0xFCA00D00, 0xFFB00F10)
	check("VSUDOT_LANE",     .VSUDOT_LANE, 0, 0xFE800D50, 0xFFB00F50)

	// ---- Lane-indexed NEON ----
	check("VMUL_LANE D .S16", .VMUL_LANE,  0, 0xF2900840, 0xFFB00F50)
	check("VMUL_LANE Q .S32", .VMUL_LANE,  3, 0xF3A00840, 0xFFB00F50)
	check("VMLA_LANE D",      .VMLA_LANE,  0, 0xF2900040, 0xFFB00F50)
	check("VMLS_LANE Q",      .VMLS_LANE,  2, 0xF3900440, 0xFFB00F50)
	check("VMULL_LANE .S16",  .VMULL_LANE, 0, 0xF2900A40, 0xFFB00F50)
	check("VMLAL_LANE .S32",  .VMLAL_LANE, 1, 0xF2A00240, 0xFFB00F50)
	check("VMLSL_LANE .S16",  .VMLSL_LANE, 0, 0xF2900640, 0xFFB00F50)
	check("VQDMULL_LANE .S16",.VQDMULL_LANE, 0, 0xF2900B40, 0xFFB00F50)
	check("VQDMLAL_LANE .S32",.VQDMLAL_LANE, 1, 0xF2A00340, 0xFFB00F50)
	check("VQDMLSL_LANE",     .VQDMLSL_LANE, 0, 0xF2900740, 0xFFB00F50)
	check("VFMA_LANE D",      .VFMA_LANE,  0, 0xF2A000C0, 0xFFB00F50)
	check("VFMS_LANE Q",      .VFMS_LANE,  1, 0xF3A004C0, 0xFFB00F50)
	check("VQRDMLAH_LANE",    .VQRDMLAH_LANE, 0, 0xF2900E40, 0xFFB00F50)
	check("VQRDMLSH_LANE",    .VQRDMLSH_LANE, 0, 0xF2900F40, 0xFFB00F50)
	check("VCMLA_LANE D",     .VCMLA_LANE, 0, 0xFE000800, 0xFFB00F10)

	// ---- MVE polish ----
	check("VQABS",           .VQABS,  0, 0xFFB00740, 0xFFB30FD1)
	check("VQNEG",           .VQNEG,  0, 0xFFB007C0, 0xFFB30FD1)
	check("VMOVX",           .VMOVX,  0, 0xFEB00A40, 0xFFBF0FD0)
	check("VINS",            .VINS,   0, 0xFEB00AC0, 0xFFBF0FD0)

	// ---- MVE gather/scatter (LLVM-verified) ----
	check("VLDRW_GATHER",    .VLDRW_GATHER, 0, 0xFC900F40, 0xFEF00FF1)
	check("VLDRD_GATHER",    .VLDRD_GATHER, 0, 0xFC900FD0, 0xFEF00FF1)
	check("VSTRW_SCATTER",   .VSTRW_SCATTER, 0, 0xEC600F40, 0xFEF00FF1)
	check("VSTRB_SCATTER",   .VSTRB_SCATTER, 0, 0xEC600E00, 0xFEF00FD1)

	// ---- VFP fixed-point conversions (VCVT with #fbits) ----
	check("VCVT_FIXED S32.F32", .VCVT_FIXED, 0, 0x0EBE0A40, 0x0FBF0FD0)
	check("VCVT_FIXED U32.F32", .VCVT_FIXED, 1, 0x0EBF0A40, 0x0FBF0FD0)
	check("VCVT_FIXED F32.S32", .VCVT_FIXED, 2, 0x0EBA0A40, 0x0FBF0FD0)
	check("VCVT_FIXED F64",     .VCVT_FIXED, 6, 0x0EBE0B40, 0x0FBF0FD0)
	check("VCVT_FIXED F16",     .VCVT_FIXED, 8, 0x0EBE0940, 0x0FBF0FD0)

	// ---- NEON compare-with-zero ----
	check("VCEQ_Z D .I8",    .VCEQ_Z, 0, 0xF3B10100, 0xFFB30FD0)
	check("VCEQ_Z Q .F32",   .VCEQ_Z, 3, 0xF3B90540, 0xFFB30FD0)
	check("VCGE_Z D",        .VCGE_Z, 0, 0xF3B10080, 0xFFB30FD0)
	check("VCGT_Z D",        .VCGT_Z, 0, 0xF3B10000, 0xFFB30FD0)
	check("VCLE_Z D",        .VCLE_Z, 0, 0xF3B10180, 0xFFB30FD0)
	check("VCLT_Z D",        .VCLT_Z, 0, 0xF3B10200, 0xFFB30FD0)

	// ---- NEON replicate loads ----
	check("VLD2R",           .VLD2R, 0, 0xF4A00D0F, 0xFFB00F0F)
	check("VLD3R",           .VLD3R, 0, 0xF4A00E0F, 0xFFB00F0F)
	check("VLD4R",           .VLD4R, 0, 0xF4A00F0F, 0xFFB00F0F)

	// ---- NEON single-element lane loads/stores ----
	check("VLD1_LANE .8",    .VLD1_LANE, 0, 0xF4A00000, 0xFFB00C00)
	check("VLD1_LANE .16",   .VLD1_LANE, 1, 0xF4A00400, 0xFFB00C00)
	check("VLD1_LANE .32",   .VLD1_LANE, 2, 0xF4A00800, 0xFFB00C00)
	check("VLD2_LANE .8",    .VLD2_LANE, 0, 0xF4A00100, 0xFFB00D00)
	check("VLD3_LANE .16",   .VLD3_LANE, 1, 0xF4A00600, 0xFFB00D00)
	check("VLD4_LANE .32",   .VLD4_LANE, 2, 0xF4A00B00, 0xFFB00D00)
	check("VST1_LANE .8",    .VST1_LANE, 0, 0xF4800000, 0xFFB00C00)
	check("VST3_LANE .32",   .VST3_LANE, 2, 0xF4800A00, 0xFFB00D00)
	check("VST4_LANE .16",   .VST4_LANE, 1, 0xF4800700, 0xFFB00D00)

	// ---- MVE rounding-to-int (VPADD/VPMAX/VPMIN MVE forms removed - don't exist) ----
	check("VRINTA MVE",      .VRINTA, 2, 0xFFBA0540, 0xFFBB0FD1)
	check("VRINTN MVE",      .VRINTN, 2, 0xFFBA0440, 0xFFBB0FD1)
	check("VRINTP MVE",      .VRINTP, 2, 0xFFBA07C0, 0xFFBB0FD1)
	check("VRINTZ MVE",      .VRINTZ, 2, 0xFFBA05C0, 0xFFBB0FD1)

	fmt.printf("\n==> arm32 table: %d passed, %d failed\n", ok_count, fail_count)

	run_pipeline_tests()
	run_sweep_tests()

	if fail_count > 0 || fail > 0 { os.exit(1) }
}

main :: proc() {
	run_pipeline_tests()
	run_smoke()
	run_sweep_tests()
}
