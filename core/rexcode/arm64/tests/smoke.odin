package rexcode_arm64_tests

// Spot-check ENCODING_TABLE entries against canonical bit patterns from
// the ARM ARM (Arm Architecture Reference Manual for A-profile, F/G
// section for instruction set). One representative entry per family.
//
// Run with: odin run arm64/tests

import "core:fmt"
import "core:os"
import a "../"

@(private="file") passes := 0
@(private="file") failures := 0

@(private="file")
check :: proc(name: string, m: a.Mnemonic, idx: int, want_bits, want_mask: u32) {
	encs := a.ENCODING_TABLE[m]
	if idx >= len(encs) {
		fmt.printfln("  [FAIL] %s: no encoding at idx %d", name, idx)
		failures += 1
		return
	}
	e := encs[idx]
	if e.bits != want_bits || e.mask != want_mask {
		fmt.printfln("  [FAIL] %-18s got bits=%08x mask=%08x  want bits=%08x mask=%08x",
					 name, e.bits, e.mask, want_bits, want_mask)
		failures += 1
		return
	}
	fmt.printfln("  [ok]   %-18s %08x / %08x  (feat=%v)", name, e.bits, e.mask, e.feature)
	passes += 1
}

main :: proc() {
	fmt.println("=== AArch64 encoding-table spot checks ===")

	// ---- Data-proc immediate ------------------------------------------------
	check("ADD imm 32",     .ADD_IMM,  0, 0x11000000, 0xFF800000)
	check("ADD imm 64",     .ADD_IMM,  1, 0x91000000, 0xFF800000)
	check("SUBS imm 64",    .SUBS_IMM, 1, 0xF1000000, 0xFF800000)
	check("MOVZ 32",        .MOVZ,     0, 0x52800000, 0xFF800000)
	check("MOVZ 64",        .MOVZ,     1, 0xD2800000, 0xFF800000)
	check("MOVN 64",        .MOVN,     1, 0x92800000, 0xFF800000)
	check("MOVK 64",        .MOVK,     1, 0xF2800000, 0xFF800000)
	check("ADR",            .ADR,      0, 0x10000000, 0x9F000000)
	check("ADRP",           .ADRP,     0, 0x90000000, 0x9F000000)

	// ---- Data-proc shifted register -----------------------------------------
	check("ADD SR 64",      .ADD_SR,   1, 0x8B000000, 0xFF200000)
	check("SUBS SR 64",     .SUBS_SR,  1, 0xEB000000, 0xFF200000)
	check("AND SR 32",      .AND_SR,   0, 0x0A000000, 0xFF200000)
	check("BIC SR 64",      .BIC_SR,   1, 0x8A200000, 0xFF200000)
	check("ORR SR 64",      .ORR_SR,   1, 0xAA000000, 0xFF200000)
	check("ORN SR 64",      .ORN_SR,   1, 0xAA200000, 0xFF200000)
	check("EOR SR 64",      .EOR_SR,   1, 0xCA000000, 0xFF200000)
	check("EON SR 64",      .EON_SR,   1, 0xCA200000, 0xFF200000)
	check("ANDS SR 64",     .ANDS_SR,  1, 0xEA000000, 0xFF200000)

	// ---- Data-proc extended register ----------------------------------------
	check("ADD ER 64",      .ADD_ER,   1, 0x8B200000, 0xFFE00000)
	check("SUBS ER 64",     .SUBS_ER,  1, 0xEB200000, 0xFFE00000)

	// ---- Data-proc 2-source -------------------------------------------------
	check("UDIV 64",        .UDIV,     1, 0x9AC00800, 0xFFE0FC00)
	check("SDIV 64",        .SDIV,     1, 0x9AC00C00, 0xFFE0FC00)
	check("LSLV 64",        .LSLV,     1, 0x9AC02000, 0xFFE0FC00)
	check("LSRV 64",        .LSRV,     1, 0x9AC02400, 0xFFE0FC00)
	check("ASRV 64",        .ASRV,     1, 0x9AC02800, 0xFFE0FC00)
	check("RORV 64",        .RORV,     1, 0x9AC02C00, 0xFFE0FC00)

	// ---- Data-proc 3-source -------------------------------------------------
	check("MADD 64",        .MADD,     1, 0x9B000000, 0xFFE08000)
	check("MSUB 64",        .MSUB,     1, 0x9B008000, 0xFFE08000)
	check("SMADDL",         .SMADDL,   0, 0x9B200000, 0xFFE08000)
	check("UMADDL",         .UMADDL,   0, 0x9BA00000, 0xFFE08000)
	check("SMULH",          .SMULH,    0, 0x9B407C00, 0xFFE0FC00)
	check("UMULH",          .UMULH,    0, 0x9BC07C00, 0xFFE0FC00)

	// ---- Data-proc 1-source -------------------------------------------------
	check("RBIT 64",        .RBIT,     1, 0xDAC00000, 0xFFFFFC00)
	check("REV16 64",       .REV16,    1, 0xDAC00400, 0xFFFFFC00)
	check("REV 64",         .REV,      1, 0xDAC00C00, 0xFFFFFC00)
	check("REV32",          .REV32,    0, 0xDAC00800, 0xFFFFFC00)
	check("CLZ 64",         .CLZ,      1, 0xDAC01000, 0xFFFFFC00)
	check("CLS 64",         .CLS,      1, 0xDAC01400, 0xFFFFFC00)

	// ---- Conditional select -------------------------------------------------
	check("CSEL 64",        .CSEL,     1, 0x9A800000, 0xFFE00C00)
	check("CSINC 64",       .CSINC,    1, 0x9A800400, 0xFFE00C00)
	check("CSINV 64",       .CSINV,    1, 0xDA800000, 0xFFE00C00)
	check("CSNEG 64",       .CSNEG,    1, 0xDA800400, 0xFFE00C00)

	// ---- Branches -----------------------------------------------------------
	check("B",              .B,        0, 0x14000000, 0xFC000000)
	check("BL",             .BL,       0, 0x94000000, 0xFC000000)
	check("B.cond",         .B_COND,   0, 0x54000000, 0xFF000010)
	check("CBZ 64",         .CBZ,      1, 0xB4000000, 0xFF000000)
	check("CBNZ 64",        .CBNZ,     1, 0xB5000000, 0xFF000000)
	check("TBZ",            .TBZ,      0, 0x36000000, 0x7F000000)
	check("TBNZ",           .TBNZ,     0, 0x37000000, 0x7F000000)
	check("BR",             .BR,       0, 0xD61F0000, 0xFFFFFC1F)
	check("BLR",            .BLR,      0, 0xD63F0000, 0xFFFFFC1F)
	check("RET reg",        .RET,      0, 0xD65F0000, 0xFFFFFC1F)
	check("RET default",    .RET,      1, 0xD65F03C0, 0xFFFFFFFF)

	// ---- Loads / stores -----------------------------------------------------
	check("LDR W u12",      .LDR,      0, 0xB9400000, 0xFFC00000)
	check("LDR X u12",      .LDR,      1, 0xF9400000, 0xFFC00000)
	check("STR X u12",      .STR,      1, 0xF9000000, 0xFFC00000)
	check("LDRB",           .LDRB,     0, 0x39400000, 0xFFC00000)
	check("STRB",           .STRB,     0, 0x39000000, 0xFFC00000)
	check("LDRH",           .LDRH,     0, 0x79400000, 0xFFC00000)
	check("STRH",           .STRH,     0, 0x79000000, 0xFFC00000)
	check("LDRSW",          .LDRSW,    0, 0xB9800000, 0xFFC00000)
	check("LDP X",          .LDP,      1, 0xA9400000, 0xFFC00000)
	check("STP X",          .STP,      1, 0xA9000000, 0xFFC00000)
	check("LDR literal X",  .LDR_LIT,  1, 0x58000000, 0xFF000000)

	// ---- System -------------------------------------------------------------
	check("NOP",            .NOP,      0, 0xD503201F, 0xFFFFFFFF)
	check("YIELD",          .YIELD,    0, 0xD503203F, 0xFFFFFFFF)
	check("WFE",            .WFE,      0, 0xD503205F, 0xFFFFFFFF)
	check("WFI",            .WFI,      0, 0xD503207F, 0xFFFFFFFF)
	check("ISB",            .ISB,      0, 0xD50330DF, 0xFFFFF0FF)
	check("DSB",            .DSB,      0, 0xD503309F, 0xFFFFF0FF)
	check("DMB",            .DMB,      0, 0xD50330BF, 0xFFFFF0FF)
	check("SVC",            .SVC,      0, 0xD4000001, 0xFFE0001F)
	check("HVC",            .HVC,      0, 0xD4000002, 0xFFE0001F)
	check("BRK",            .BRK,      0, 0xD4200000, 0xFFE0001F)
	check("HLT",            .HLT,      0, 0xD4400000, 0xFFE0001F)
	check("ERET",           .ERET,     0, 0xD69F03E0, 0xFFFFFFFF)
	check("MRS",            .MRS,      0, 0xD5300000, 0xFFF00000)
	check("MSR reg",        .MSR_REG,  0, 0xD5100000, 0xFFF00000)

	// ---- FP scalar ----------------------------------------------------------
	check("FABS S",         .FABS,     0, 0x1E20C000, 0xFFFFFC00)
	check("FABS D",         .FABS,     1, 0x1E60C000, 0xFFFFFC00)
	check("FNEG D",         .FNEG,     1, 0x1E614000, 0xFFFFFC00)
	check("FSQRT D",        .FSQRT,    1, 0x1E61C000, 0xFFFFFC00)
	check("FADD D",         .FADD,     1, 0x1E602800, 0xFFE0FC00)
	check("FSUB D",         .FSUB,     1, 0x1E603800, 0xFFE0FC00)
	check("FMUL D",         .FMUL,     1, 0x1E600800, 0xFFE0FC00)
	check("FDIV D",         .FDIV,     1, 0x1E601800, 0xFFE0FC00)
	check("FNMUL D",        .FNMUL,    1, 0x1E608800, 0xFFE0FC00)
	check("FMAX D",         .FMAX,     1, 0x1E604800, 0xFFE0FC00)
	check("FMIN D",         .FMIN,     1, 0x1E605800, 0xFFE0FC00)
	check("FMAXNM D",       .FMAXNM,   1, 0x1E606800, 0xFFE0FC00)
	check("FMINNM D",       .FMINNM,   1, 0x1E607800, 0xFFE0FC00)
	check("FMADD D",        .FMADD,    1, 0x1F400000, 0xFFE08000)
	check("FMSUB D",        .FMSUB,    1, 0x1F408000, 0xFFE08000)
	check("FNMADD D",       .FNMADD,   1, 0x1F600000, 0xFFE08000)
	check("FNMSUB D",       .FNMSUB,   1, 0x1F608000, 0xFFE08000)
	check("FCMP D",         .FCMP,     1, 0x1E602000, 0xFFE0FC1F)
	check("FCMPE D",        .FCMPE,    1, 0x1E602010, 0xFFE0FC1F)
	check("FCSEL D",        .FCSEL,    1, 0x1E600C00, 0xFFE00C00)
	check("FCVT D<-S",      .FCVT,     0, 0x1E22C000, 0xFFFFFC00)
	check("FCVT S<-D",      .FCVT,     1, 0x1E624000, 0xFFFFFC00)
	check("SCVTF S<-W",     .SCVTF,    0, 0x1E220000, 0xFFFFFC00)
	check("SCVTF D<-X",     .SCVTF,    3, 0x9E620000, 0xFFFFFC00)
	check("UCVTF D<-X",     .UCVTF,    3, 0x9E630000, 0xFFFFFC00)
	check("FCVTZS X<-D",    .FCVTZS,   3, 0x9E780000, 0xFFFFFC00)
	check("FCVTZU X<-D",    .FCVTZU,   3, 0x9E790000, 0xFFFFFC00)
	check("FMOV S<-S",      .FMOV_REG, 0, 0x1E204000, 0xFFFFFC00)
	check("FMOV W<-S",      .FMOV_GEN, 0, 0x1E260000, 0xFFFFFC00)
	check("FMOV S<-W",      .FMOV_GEN, 1, 0x1E270000, 0xFFFFFC00)
	check("FMOV X<-D",      .FMOV_GEN, 2, 0x9E660000, 0xFFFFFC00)
	check("FMOV D<-X",      .FMOV_GEN, 3, 0x9E670000, 0xFFFFFC00)

	// ---- Bitmask logical immediate ------------------------------------------
	check("AND_IMM 32",     .AND_IMM,  0, 0x12000000, 0xFFC00000)
	check("AND_IMM 64",     .AND_IMM,  1, 0x92000000, 0xFF800000)
	check("ORR_IMM 64",     .ORR_IMM,  1, 0xB2000000, 0xFF800000)
	check("EOR_IMM 64",     .EOR_IMM,  1, 0xD2000000, 0xFF800000)
	check("ANDS_IMM 64",    .ANDS_IMM, 1, 0xF2000000, 0xFF800000)
	check("TST_IMM 64",     .TST_IMM,  1, 0xF200001F, 0xFF80001F)

	// ---- SVE -- vectors unpredicated ----------------------------------------
	check("SVE_ADD_Z B",    .SVE_ADD_Z,  0, 0x04200000, 0xFFE0FC00)
	check("SVE_ADD_Z S",    .SVE_ADD_Z,  2, 0x04A00000, 0xFFE0FC00)
	check("SVE_SUB_Z D",    .SVE_SUB_Z,  3, 0x04E00400, 0xFFE0FC00)
	check("SVE_SQADD_Z H",  .SVE_SQADD_Z,1, 0x04601000, 0xFFE0FC00)

	// ---- SVE -- vectors predicated ------------------------------------------
	check("SVE_ADD_PRED B", .SVE_ADD_PRED, 0, 0x04000000, 0xFFE0E000)
	check("SVE_MUL_PRED S", .SVE_MUL_PRED, 2, 0x04900000, 0xFFE0E000)
	check("SVE_SDIV S",     .SVE_SDIV_PRED, 0, 0x04940000, 0xFFE0E000)
	check("SVE_ASR_PRED D", .SVE_ASR_PRED, 3, 0x04D08000, 0xFFE0E000)
	check("SVE_NEG_PRED D", .SVE_NEG_PRED, 3, 0x04D7A000, 0xFFE0E000)

	// ---- SVE -- bitwise predicated ------------------------------------------
	check("SVE_AND_PRED D", .SVE_AND_PRED, 0, 0x041A0000, 0xFFFFE000)
	check("SVE_EOR_PRED D", .SVE_EOR_PRED, 0, 0x04190000, 0xFFFFE000)

	// ---- SVE -- FP unpredicated ---------------------------------------------
	check("SVE_FADD_Z S",   .SVE_FADD_Z, 1, 0x65800000, 0xFFE0FC00)
	check("SVE_FMUL_Z D",   .SVE_FMUL_Z, 2, 0x65C00800, 0xFFE0FC00)

	// ---- SVE -- FP predicated -----------------------------------------------
	check("SVE_FADD_PRED S",.SVE_FADD_PRED, 1, 0x65808000, 0xFFE0E000)
	check("SVE_FMLA S",     .SVE_FMLA,      1, 0x65A00000, 0xFFE0E000)

	// ---- SVE -- predicate logical -------------------------------------------
	check("SVE_AND_P",      .SVE_AND_P,   0, 0x25004000, 0xFFE0C210)
	check("SVE_ORR_P",      .SVE_ORR_P,   0, 0x25804000, 0xFFE0C210)
	check("SVE_SEL_P",      .SVE_SEL_P,   0, 0x25004210, 0xFFE0C210)
	check("SVE_PTRUE",      .SVE_PTRUE,   0, 0x2518E000, 0xFFFFFC10)
	check("SVE_PFALSE",     .SVE_PFALSE,  0, 0x2518E400, 0xFFFFFFF0)

	// ---- SVE -- compares ----------------------------------------------------
	check("SVE_CMPEQ B",    .SVE_CMPEQ, 0, 0x2400A000, 0xFFE0E000)
	check("SVE_CMPGT S",    .SVE_CMPGT, 2, 0x24808010, 0xFFE0E010)
	check("SVE_CMPHS D",    .SVE_CMPHS, 3, 0x24C00000, 0xFFE0E010)

	// ---- SVE -- loads/stores -----------------------------------------------
	check("SVE_LD1B",       .SVE_LD1B, 0, 0xA4004000, 0xFFE0E000)
	check("SVE_LD1D",       .SVE_LD1D, 0, 0xA5E04000, 0xFFE0E000)
	check("SVE_ST1W",       .SVE_ST1W, 0, 0xE5404000, 0xFFE0E000)

	// ---- SVE permute -------------------------------------------------------
	check("SVE_ZIP1_Z B",   .SVE_ZIP1_Z, 0, 0x05206000, 0xFFE0FC00)
	check("SVE_UZP2_Z S",   .SVE_UZP2_Z, 2, 0x05A06C00, 0xFFE0FC00)
	check("SVE_TBL B",      .SVE_TBL,    0, 0x05203000, 0xFFE0FC00)

	// ---- SVE2 ---------------------------------------------------------------
	check("SVE_WHILELT 64", .SVE_WHILELT,  0, 0x25201400, 0xFF20FC10)
	check("SVE_SQRDMLAH B", .SVE_SQRDMLAH, 0, 0x44007000, 0xFFE0FC00)
	check("SVE_AESE",       .SVE_AESE,     0, 0x4522E000, 0xFFFFFC00)
	check("SVE_MATCH B",    .SVE_MATCH,    0, 0x45208000, 0xFFE0E010)

	// ---- SME ----------------------------------------------------------------
	check("SME_SMSTART",    .SME_SMSTART, 0, 0xD503477F, 0xFFFFFFFF)
	check("SME_SMSTOP",     .SME_SMSTOP,  0, 0xD503467F, 0xFFFFFFFF)
	check("SME_RDSVL",      .SME_RDSVL,   0, 0x04BF5800, 0xFFFFFC00)
	check("SME_FMOPA S",    .SME_FMOPA,   0, 0x80800000, 0xFFE08010)
	check("SME_BFMOPA",     .SME_BFMOPA,  0, 0x81800000, 0xFFE08010)
	check("SME_SMOPA S",    .SME_SMOPA,   0, 0xA0800000, 0xFFE08010)
	check("SME_UMOPA D",    .SME_UMOPA,   1, 0xA1E00000, 0xFFE08010)

	// ---- Apple AMX ----------------------------------------------------------
	check("AMX_LDX",        .AMX_LDX,    0, 0x00201000, 0xFFFFFFE0)
	check("AMX_LDY",        .AMX_LDY,    0, 0x00201020, 0xFFFFFFE0)
	check("AMX_STZ",        .AMX_STZ,    0, 0x002010A0, 0xFFFFFFE0)
	check("AMX_FMA64",      .AMX_FMA64,  0, 0x00201140, 0xFFFFFFE0)
	check("AMX_FMA32",      .AMX_FMA32,  0, 0x00201180, 0xFFFFFFE0)
	check("AMX_MAC16",      .AMX_MAC16,  0, 0x002011C0, 0xFFFFFFE0)
	check("AMX_SET",        .AMX_SET,    0, 0x00201220, 0xFFFFFFFF)
	check("AMX_CLR",        .AMX_CLR,    0, 0x00201240, 0xFFFFFFFF)
	check("AMX_MATFP",      .AMX_MATFP,  0, 0x002012C0, 0xFFFFFFE0)
	check("AMX_GENLUT",     .AMX_GENLUT, 0, 0x002012E0, 0xFFFFFFE0)

	// ---- MOPS ---------------------------------------------------------------
	check("CPYP",       .CPYP,     0, 0x1D000400, 0xFFE03C00)
	check("CPYM",       .CPYM,     0, 0x1D400400, 0xFFE03C00)
	check("CPYE",       .CPYE,     0, 0x1D800400, 0xFFE03C00)
	check("CPYFP",      .CPYFP,    0, 0x19000400, 0xFFE03C00)
	check("CPYFM",      .CPYFM,    0, 0x19400400, 0xFFE03C00)
	check("CPYFE",      .CPYFE,    0, 0x19800400, 0xFFE03C00)
	check("SETP",       .SETP,     0, 0x19C00400, 0xFFE03C00)
	check("SETM",       .SETM,     0, 0x19C04400, 0xFFE03C00)
	check("SETE",       .SETE,     0, 0x19C08400, 0xFFE03C00)

	// ---- Cache management ---------------------------------------------------
	check("DC IVAC",    .DC_IVAC,    0, 0xD5087620, 0xFFFFFFE0)
	check("DC ISW",     .DC_ISW,     0, 0xD5087640, 0xFFFFFFE0)
	check("DC ZVA",     .DC_ZVA,     0, 0xD50B7420, 0xFFFFFFE0)
	check("DC CVAC",    .DC_CVAC,    0, 0xD50B7A20, 0xFFFFFFE0)
	check("DC CVAU",    .DC_CVAU,    0, 0xD50B7B20, 0xFFFFFFE0)
	check("DC CIVAC",   .DC_CIVAC,   0, 0xD50B7E20, 0xFFFFFFE0)
	check("IC IALLUIS", .IC_IALLUIS, 0, 0xD508711F, 0xFFFFFFFF)
	check("IC IALLU",   .IC_IALLU,   0, 0xD508751F, 0xFFFFFFFF)
	check("IC IVAU",    .IC_IVAU,    0, 0xD50B7520, 0xFFFFFFE0)
	check("AT S1E1R",   .AT_S1E1R,   0, 0xD5087800, 0xFFFFFFE0)
	check("AT S1E0W",   .AT_S1E0W,   0, 0xD5087860, 0xFFFFFFE0)
	check("AT S12E1R",  .AT_S12E1R,  0, 0xD50C7880, 0xFFFFFFE0)
	check("TLBI VMALLE1",   .TLBI_VMALLE1,   0, 0xD508871F, 0xFFFFFFFF)
	check("TLBI VAE1IS",    .TLBI_VAE1IS,    0, 0xD5088320, 0xFFFFFFE0)
	check("TLBI ASIDE1",    .TLBI_ASIDE1,    0, 0xD5088740, 0xFFFFFFE0)
	check("TLBI VAALE1",    .TLBI_VAALE1,    0, 0xD50887E0, 0xFFFFFFE0)
	check("TLBI ALLE2",     .TLBI_ALLE2,     0, 0xD50C871F, 0xFFFFFFFF)
	check("TLBI ALLE3IS",   .TLBI_ALLE3IS,   0, 0xD50E831F, 0xFFFFFFFF)

	// ---- PRFM ---------------------------------------------------------------
	check("PRFM",       .PRFM,     0, 0xF9800000, 0xFFC00000)
	check("PRFUM",      .PRFUM,    0, 0xF8800000, 0xFFE00C00)
	check("PRFM_LIT",   .PRFM_LIT, 0, 0xD8000000, 0xFF000000)

	// ---- Aliases ------------------------------------------------------------
	check("MOV_REG 32",   .MOV_REG,     0, 0x2A0003E0, 0xFFE0FFE0)
	check("MOV_REG 64",   .MOV_REG,     1, 0xAA0003E0, 0xFFE0FFE0)
	check("MOV_BITMASK 64", .MOV_BITMASK, 1, 0xB20003E0, 0xFF8003E0)
	check("MVN 64",       .MVN,         1, 0xAA2003E0, 0xFFE0FFE0)
	check("NEG_SR 64",    .NEG_SR,      1, 0xCB0003E0, 0xFF2003E0)
	check("NEGS 64",      .NEGS,        1, 0xEB0003E0, 0xFF2003E0)
	check("CMP_SR 64",    .CMP_SR,      1, 0xEB00001F, 0xFF20001F)
	check("CMP_ER 64",    .CMP_ER,      1, 0xEB20001F, 0xFFE0001F)
	check("CMP_IMM 64",   .CMP_IMM,     1, 0xF100001F, 0xFF80001F)
	check("CMN_SR 64",    .CMN_SR,      1, 0xAB00001F, 0xFF20001F)
	check("CMN_IMM 64",   .CMN_IMM,     1, 0xB100001F, 0xFF80001F)
	check("TST_SR 64",    .TST_SR,      1, 0xEA00001F, 0xFF20001F)

	// ---- SVE indexed FMLA / FMLS ---------------------------------------
	check("SVE_FMLA_IDX_H", .SVE_FMLA_IDX_H, 0, 0x64200000, 0xFFA0FC00)
	check("SVE_FMLA_IDX_S", .SVE_FMLA_IDX_S, 0, 0x64A00000, 0xFFE0FC00)
	check("SVE_FMLA_IDX_D", .SVE_FMLA_IDX_D, 0, 0x64E00000, 0xFFE0FC00)
	check("SVE_FMLS_IDX_S", .SVE_FMLS_IDX_S, 0, 0x64A00400, 0xFFE0FC00)
	check("SVE_FMLS_IDX_D", .SVE_FMLS_IDX_D, 0, 0x64E00400, 0xFFE0FC00)

	// ---- SVE gather loads ----------------------------------------------
	check("SVE_LD1B_GATHER_S", .SVE_LD1B_GATHER_S, 0, 0x84004000, 0xFFA0E000)
	check("SVE_LD1W_GATHER_D", .SVE_LD1W_GATHER_D, 0, 0xC5004000, 0xFFA0E000)
	check("SVE_LD1D_GATHER_D", .SVE_LD1D_GATHER_D, 0, 0xC5804000, 0xFFA0E000)
	check("SVE_LD1SB_GATHER_S",.SVE_LD1SB_GATHER_S,0, 0x84000000, 0xFFA0E000)
	check("SVE_LD1SW_GATHER_D",.SVE_LD1SW_GATHER_D,0, 0xC5000000, 0xFFA0E000)

	// ---- SVE scatter stores --------------------------------------------
	check("SVE_ST1B_SCATTER_S",.SVE_ST1B_SCATTER_S,0, 0xE4008000, 0xFFA0E000)
	check("SVE_ST1W_SCATTER_S",.SVE_ST1W_SCATTER_S,0, 0xE5008000, 0xFFA0E000)
	check("SVE_ST1D_SCATTER_D",.SVE_ST1D_SCATTER_D,0, 0xE5808000, 0xFFA0E000)

	// ---- SME tile slice memory -----------------------------------------
	check("SME_LD1B_TILE", .SME_LD1B_TILE, 0, 0xE0000000, 0xFFE00010)
	check("SME_LD1H_TILE", .SME_LD1H_TILE, 0, 0xE0400000, 0xFFE00010)
	check("SME_LD1W_TILE", .SME_LD1W_TILE, 0, 0xE0800000, 0xFFE00010)
	check("SME_LD1D_TILE", .SME_LD1D_TILE, 0, 0xE0C00000, 0xFFE00010)
	check("SME_LD1Q_TILE", .SME_LD1Q_TILE, 0, 0xE1C00000, 0xFFE00010)
	check("SME_ST1B_TILE", .SME_ST1B_TILE, 0, 0xE0200000, 0xFFE00010)
	check("SME_ST1W_TILE", .SME_ST1W_TILE, 0, 0xE0A00000, 0xFFE00010)
	check("SME_MOVA_Z_FROM_TILE", .SME_MOVA_Z_FROM_TILE, 0, 0xC0020000, 0xFFE08010)
	check("SME_MOVA_TILE_FROM_Z", .SME_MOVA_TILE_FROM_Z, 0, 0xC0000000, 0xFFE08010)

	// ---- NEON FCMLA / FCADD (v8.3-A FCMA) -- verified vs LLVM golden -----
	check("FCMLA_4H", .FCMLA_4H, 0, 0x2E40C400, 0xFFA0CC00)
	check("FCMLA_8H", .FCMLA_8H, 0, 0x6E40C400, 0xFFA0CC00)
	check("FCMLA_4S", .FCMLA_4S, 0, 0x6E80C400, 0xFFA0CC00)
	check("FCMLA_2D", .FCMLA_2D, 0, 0x6EC0C400, 0xFFA0CC00)
	check("FCADD_4H", .FCADD_4H, 0, 0x2E40E400, 0xFFA0EC00)
	check("FCADD_4S", .FCADD_4S, 0, 0x6E80E400, 0xFFA0EC00)

	// ---- SVE prefetch ----------------------------------------------------
	check("SVE_PRFB", .SVE_PRFB, 0, 0x8400C000, 0xFFE0E000)
	check("SVE_PRFH", .SVE_PRFH, 0, 0x8480C000, 0xFFE0E000)
	check("SVE_PRFW", .SVE_PRFW, 0, 0x8500C000, 0xFFE0E000)
	check("SVE_PRFD", .SVE_PRFD, 0, 0x8580C000, 0xFFE0E000)

	// ---- SVE LDNT / STNT (non-temporal) ----------------------------------
	check("SVE_LDNT1B", .SVE_LDNT1B, 0, 0xA400C000, 0xFFE0E000)
	check("SVE_LDNT1D", .SVE_LDNT1D, 0, 0xA580C000, 0xFFE0E000)
	check("SVE_STNT1B", .SVE_STNT1B, 0, 0xE4006000, 0xFFE0E000)
	check("SVE_STNT1D", .SVE_STNT1D, 0, 0xE5806000, 0xFFE0E000)

	// ---- SVE permute / init ---------------------------------------------
	check("SVE_EXT",     .SVE_EXT,    0, 0x05200000, 0xFFE0E000)
	check("SVE_SPLICE",  .SVE_SPLICE, 0, 0x052C8000, 0xFFFFE000)
	check("SVE_INDEX_II",.SVE_INDEX_II,0,0x04204000, 0xFFE0FC00)
	check("SVE_INDEX_RR",.SVE_INDEX_RR,0,0x04204C00, 0xFFE0FC00)

	// ---- SVE2 bit-select family + polynomial multiply -------------------
	check("SVE_BSL",     .SVE_BSL,    0, 0x04203C00, 0xFFE0FC00)
	check("SVE_BSL1N",   .SVE_BSL1N,  0, 0x04603C00, 0xFFE0FC00)
	check("SVE_NBSL",    .SVE_NBSL,   0, 0x04E03C00, 0xFFE0FC00)
	check("SVE_PMUL_VEC",.SVE_PMUL_VEC,0,0x04206400, 0xFFE0FC00)
	check("SVE_PMULLB",  .SVE_PMULLB, 0, 0x45006800, 0xFFE0FC00)
	check("SVE_PMULLT",  .SVE_PMULLT, 0, 0x45006C00, 0xFFE0FC00)

	// ---- SVE BF16 conversions -------------------------------------------
	check("SVE_BFCVT",   .SVE_BFCVT,   0, 0x658AA000, 0xFFFFE000)
	check("SVE_BFCVTNT", .SVE_BFCVTNT, 0, 0x648AA000, 0xFFFFE000)

	// ---- PAC-authenticated loads ----------------------------------------
	check("LDRAA",       .LDRAA,      0, 0xF8200400, 0xFFA00C00)
	check("LDRAB",       .LDRAB,      0, 0xF8A00400, 0xFFA00C00)
	check("LDRAA_PRE",   .LDRAA_PRE,  0, 0xF8200C00, 0xFFA00C00)
	check("LDRAB_PRE",   .LDRAB_PRE,  0, 0xF8A00C00, 0xFFA00C00)

	// ---- TME ------------------------------------------------------------
	check("TSTART",  .TSTART,  0, 0xD5233060, 0xFFFFFFE0)
	check("TCOMMIT", .TCOMMIT, 0, 0xD503307F, 0xFFFFFFFF)
	check("TCANCEL", .TCANCEL, 0, 0xD4600000, 0xFFE0001F)
	check("TTEST",   .TTEST,   0, 0xD5233160, 0xFFFFFFE0)

	// ---- WFIT / WFET -----------------------------------------------------
	check("WFET",    .WFET, 0, 0xD5031000, 0xFFFFFFE0)
	check("WFIT",    .WFIT, 0, 0xD5031020, 0xFFFFFFE0)

	// ---- BC.cond (v8.8-A) ------------------------------------------------
	check("BC.cond", .BC_COND, 0, 0x54000010, 0xFF000010)

	// ---- Sign/zero-extend aliases ---------------------------------------
	check("UXTB", .UXTB, 0, 0x53001C00, 0xFFFFFC00)
	check("UXTH", .UXTH, 0, 0x53003C00, 0xFFFFFC00)
	check("UXTW", .UXTW, 0, 0xD3407C00, 0xFFFFFC00)
	check("SXTB", .SXTB, 0, 0x13001C00, 0xFFFFFC00)
	check("SXTH", .SXTH, 0, 0x13003C00, 0xFFFFFC00)
	check("SXTW", .SXTW, 0, 0x93407C00, 0xFFFFFC00)

	// ---- Carry arithmetic -----------------------------------------------
	check("ADC 32",   .ADC,  0, 0x1A000000, 0xFFE0FC00)
	check("ADC 64",   .ADC,  1, 0x9A000000, 0xFFE0FC00)
	check("ADCS 64",  .ADCS, 1, 0xBA000000, 0xFFE0FC00)
	check("SBC 64",   .SBC,  1, 0xDA000000, 0xFFE0FC00)
	check("SBCS 64",  .SBCS, 1, 0xFA000000, 0xFFE0FC00)
	check("NGC 64",   .NGC,  1, 0xDA0003E0, 0xFFE0FFE0)
	check("NGCS 64",  .NGCS, 1, 0xFA0003E0, 0xFFE0FFE0)

	// ---- RCpc unscaled load/store ---------------------------------------
	check("LDAPUR W",  .LDAPUR,   0, 0x99400000, 0xFFE00C00)
	check("LDAPUR X",  .LDAPUR,   1, 0xD9400000, 0xFFE00C00)
	check("STLUR W",   .STLUR,    0, 0x99000000, 0xFFE00C00)
	check("STLUR X",   .STLUR,    1, 0xD9000000, 0xFFE00C00)
	check("LDAPURB",   .LDAPURB,  0, 0x19400000, 0xFFE00C00)
	check("LDAPURH",   .LDAPURH,  0, 0x59400000, 0xFFE00C00)
	check("LDAPURSW",  .LDAPURSW, 0, 0x99800000, 0xFFE00C00)

	// ---- SVE BF16 predicated arithmetic ---------------------------------
	check("SVE_BFADD", .SVE_BFADD, 0, 0x65008000, 0xFFE0E000)
	check("SVE_BFMUL", .SVE_BFMUL, 0, 0x65028000, 0xFFE0E000)
	check("SVE_BFMLA", .SVE_BFMLA, 0, 0x65200000, 0xFFE0E000)

	// ---- Speculation / profiling barriers + BTI variants ----------------
	check("SB",        .SB,        0, 0xD50330FF, 0xFFFFFFFF)
	check("CSDB",      .CSDB,      0, 0xD503229F, 0xFFFFFFFF)
	check("DGH",       .DGH,       0, 0xD50320DF, 0xFFFFFFFF)
	check("PSB CSYNC", .PSB_CSYNC, 0, 0xD503223F, 0xFFFFFFFF)
	check("TSB CSYNC", .TSB_CSYNC, 0, 0xD503225F, 0xFFFFFFFF)
	check("BTI j",     .BTI_J,     0, 0xD503245F, 0xFFFFFFFF)
	check("BTI c",     .BTI_C,     0, 0xD503249F, 0xFFFFFFFF)
	check("BTI jc",    .BTI_JC,    0, 0xD50324DF, 0xFFFFFFFF)

	// ---- NEON aliases ---------------------------------------------------
	check("MOV.16B",   .MOV_V_ALIAS, 1, 0x4EA01C00, 0xFFE0FC00)
	check("NOT.16B",   .NOT_V_ALIAS, 1, 0x6E205800, 0xFFFFFC00)

	// ---- Shift-by-immediate aliases -------------------------------------
	check("LSR_IMM 32", .LSR_IMM, 0, 0x53007C00, 0xFFC0FC00)
	check("LSR_IMM 64", .LSR_IMM, 1, 0xD340FC00, 0xFFC0FC00)
	check("ASR_IMM 32", .ASR_IMM, 0, 0x13007C00, 0xFFC0FC00)
	check("ASR_IMM 64", .ASR_IMM, 1, 0x9340FC00, 0xFFC0FC00)

	// ---- LSL_IMM / ROR_IMM (composite-packed aliases) --------------------
	check("LSL_IMM 32", .LSL_IMM, 0, 0x53000000, 0xFFC00000)
	check("LSL_IMM 64", .LSL_IMM, 1, 0xD3400000, 0xFFC00000)
	check("ROR_IMM 32", .ROR_IMM, 0, 0x13800000, 0xFFE00000)
	check("ROR_IMM 64", .ROR_IMM, 1, 0x93C00000, 0xFFE00000)

	// ---- SVE2.1 / SVE BF16 unpredicated + clamp + max/min ----------------
	check("BFADD unpred", .SVE_BFADD_UNPRED, 0, 0x65000000, 0xFFE0FC00)
	check("BFSUB unpred", .SVE_BFSUB_UNPRED, 0, 0x65000400, 0xFFE0FC00)
	check("BFMUL unpred", .SVE_BFMUL_UNPRED, 0, 0x65000800, 0xFFE0FC00)
	check("BFCLAMP",      .SVE_BFCLAMP,      0, 0x64202400, 0xFFE0FC00)
	check("BFMAXNM",      .SVE_BFMAXNM,      0, 0x65048000, 0xFFE0E000)
	check("BFMINNM",      .SVE_BFMINNM,      0, 0x65058000, 0xFFE0E000)

	// ---- SME2 multi-vector ----------------------------------------------
	check("SME2 LUTI2.B", .SME2_LUTI2_B, 0, 0xC08C4000, 0xFFE0F000)
	check("SME2 LUTI4.B", .SME2_LUTI4_B, 0, 0xC08A4000, 0xFFE0F000)
	check("SME2 LD1B x2", .SME2_LD1B_X2, 0, 0xA0000000, 0xFFE0E000)
	check("SME2 LD1W x4", .SME2_LD1W_X4, 0, 0xA000C000, 0xFFE0E000)
	check("SME2 ST1D x2", .SME2_ST1D_X2, 0, 0xA0206000, 0xFFE0E000)
	check("SME2 ZIP_4",   .SME2_ZIP_4,   0, 0xC136E000, 0xFFFFFC00)
	check("SME2 UZP_3",   .SME2_UZP_3,   0, 0xC120D001, 0xFFE0FC00)

	// ---- RME (Realm Management Extension) -------------------------------
	check("TLBI RPALOS",  .TLBI_RPALOS,  0, 0xD5084EE0, 0xFFFFFFE0)
	check("TLBI RPAOS",   .TLBI_RPAOS,   0, 0xD5084EA0, 0xFFFFFFE0)
	check("TLBI PAALL",   .TLBI_PAALL,   0, 0xD508E89F, 0xFFFFFFFF)
	check("TLBI PAALLOS", .TLBI_PAALLOS, 0, 0xD508E81F, 0xFFFFFFFF)
	check("AT S1E1A",     .AT_S1E1A,     0, 0xD5079140, 0xFFFFFFE0)
	check("DC CIPAPA",    .DC_CIPAPA,    0, 0xD50E7CE0, 0xFFFFFFE0)
	check("DC CIGDPAPA",  .DC_CIGDPAPA,  0, 0xD50E7DE0, 0xFFFFFFE0)

	fmt.println()
	fmt.printfln("==> arm64 table: %d passed, %d failed", passes, failures)
	if failures > 0 { os.exit(1) }

	run_pipeline_tests()
}
