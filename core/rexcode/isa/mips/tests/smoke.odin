// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_mips_tests

// Spot-check that ENCODING_TABLE entries are present and have the
// known canonical bit patterns. Validates one entry from each major
// section of the table.
//
// Run with: odin run mips/tests

import "core:fmt"
import "core:os"
import mips "../"

@(private="file") passes := 0
@(private="file") failures := 0

check :: proc(name: string, m: mips.Mnemonic, want_bits, want_mask: u32) {
	r := mips.ENCODE_RUNS[u16(m)]
	encs := mips.ENCODE_FORMS[r.start:][:r.count]
	if len(encs) == 0 {
		fmt.printfln("  [FAIL] %s: no encoding in table", name)
		failures += 1
		return
	}
	e := encs[0]
	if e.bits != want_bits || e.mask != want_mask {
		fmt.printfln("  [FAIL] %s: got bits=%08x mask=%08x; want bits=%08x mask=%08x",
					 name, e.bits, e.mask, want_bits, want_mask)
		failures += 1
		return
	}
	fmt.printfln("  [ok]   %-10s %08x / %08x (feature=%v)", name, e.bits, e.mask, e.feature)
	passes += 1
}

main :: proc() {
	fmt.println("=== MIPS encoding-table spot checks ===")

	// MIPS I core
	check("ADD",     .ADD,     0x00000020, 0xFC0007FF)
	check("ADDI",    .ADDI,    0x20000000, 0xFC000000)
	check("LW",      .LW,      0x8C000000, 0xFC000000)
	check("SW",      .SW,      0xAC000000, 0xFC000000)
	check("BEQ",     .BEQ,     0x10000000, 0xFC000000)
	check("BLTZ",    .BLTZ,    0x04000000, 0xFC1F0000)
	check("J",       .J,       0x08000000, 0xFC000000)
	check("JR",      .JR,      0x00000008, 0xFC1FFFFF)
	check("MULT",    .MULT,    0x00000018, 0xFC00FFFF)
	check("MFHI",    .MFHI,    0x00000010, 0xFFFF07FF)
	check("SLL",     .SLL,     0x00000000, 0xFFE0003F)
	check("NOP",     .NOP,     0x00000000, 0xFFFFFFFF)
	check("LUI",     .LUI,     0x3C000000, 0xFFE00000)
	check("SYSCALL", .SYSCALL, 0x0000000C, 0xFC00003F)

	// MIPS II
	check("LL",      .LL,      0xC0000000, 0xFC000000)
	check("BEQL",    .BEQL,    0x50000000, 0xFC000000)

	// MIPS III
	check("DADD",    .DADD,    0x0000002C, 0xFC0007FF)
	check("LD",      .LD,      0xDC000000, 0xFC000000)

	// MIPS IV
	check("MOVN",    .MOVN,    0x0000000B, 0xFC0007FF)

	// MIPS32 R1/R2
	check("MUL",     .MUL,     0x70000002, 0xFC0007FF)
	check("CLZ",     .CLZ,     0x70000020, 0xFC1F07FF)
	check("EXT",     .EXT,     0x7C000000, 0xFC00003F)
	check("SEB",     .SEB,     0x7C000420, 0xFFE007FF)
	check("ROTR",    .ROTR,    0x00200002, 0xFFE0003F)
	check("ERET",    .ERET,    0x42000018, 0xFFFFFFFF)

	// FPU base
	check("ADD.S",   .ADD_S,   0x46000000, 0xFFE0003F)
	check("MUL.D",   .MUL_D,   0x46200002, 0xFFE0003F)
	check("ABS.S",   .ABS_S,   0x46000005, 0xFFFF003F)
	check("SQRT.D",  .SQRT_D,  0x46200004, 0xFFFF003F)
	check("CVT.D.S", .CVT_D_S, 0x46000021, 0xFFFF003F)
	check("MFC1",    .MFC1,    0x44000000, 0xFFE007FF)
	check("LWC1",    .LWC1,    0xC4000000, 0xFC000000)
	check("BC1F",    .BC1F,    0x45000000, 0xFFE30000)
	check("BC1T",    .BC1T,    0x45010000, 0xFFE30000)

	// FP compares
	check("C.F.S",   .C_F_S,   0x46000030, 0xFFE000FF)
	check("C.EQ.S",  .C_EQ_S,  0x46000032, 0xFFE000FF)
	check("C.LT.D",  .C_LT_D,  0x4620003C, 0xFFE000FF)
	check("C.NGT.S", .C_NGT_S, 0x4600003F, 0xFFE000FF)
	check("C.EQ.PS", .C_EQ_PS, 0x46C00032, 0xFFE000FF)

	// COP0
	check("MFC0",    .MFC0,    0x40000000, 0xFFE007F8)
	check("TLBP",    .TLBP,    0x42000008, 0xFFFFFFFF)
	check("CACHE",   .CACHE,   0xBC000000, 0xFC000000)

	// PS1 GTE
	check("RTPS",    .RTPS,    0x4A000001, 0xFE00003F)
	check("NCLIP",   .NCLIP,   0x4A000006, 0xFE00003F)
	check("RTPT",    .RTPT,    0x4A000030, 0xFE00003F)
	check("AVSZ3",   .AVSZ3,   0x4A00002D, 0xFE00003F)
	check("MFC2",    .MFC2,    0x48000000, 0xFFE007FF)

	// PS2 MMI
	check("LQ",      .LQ,      0x78000000, 0xFC000000)
	check("SQ",      .SQ,      0x7C000000, 0xFC000000)
	check("MFHI1",   .MFHI1,   0x70000010, 0xFFFF07FF)
	check("PADDB",   .PADDB,   0x70000208, 0xFC0007FF)
	check("PADDW",   .PADDW,   0x70000008, 0xFC0007FF)
	check("PMULTW",  .PMULTW,  0x70000309, 0xFC0007FF)
	check("PMFHI",   .PMFHI,   0x70000209, 0xFFFF07FF)
	check("PINTOH",  .PINTOH,  0x700002A9, 0xFC0007FF)
	check("MFSA",    .MFSA,    0x00000028, 0xFFFF07FF)

	// MIPS32 R6
	check("BC",      .BC,      0xC8000000, 0xFC000000)
	check("BALC",    .BALC,    0xE8000000, 0xFC000000)
	check("JIC",     .JIC,     0xD8000000, 0xFFE00000)
	check("BEQZC",   .BEQZC,   0xD8000000, 0xFC000000)
	check("AUI",     .AUI,     0x3C000000, 0xFC000000)
	check("MUH",     .MUH,     0x000000D8, 0xFC0007FF)
	check("MODU",    .MODU,    0x000000DB, 0xFC0007FF)
	check("LSA",     .LSA,     0x00000005, 0xFC00071F)
	check("SELEQZ",  .SELEQZ,  0x00000035, 0xFC0007FF)
	check("BITSWAP", .BITSWAP, 0x7C000020, 0xFFE007FF)
	check("BC1EQZ",  .BC1EQZ,  0x45200000, 0xFFE00000)
	check("CRC32B",  .CRC32B,  0x7C00000F, 0xFC00F8FF)
	check("CRC32CD", .CRC32CD, 0x7C00034F, 0xFC00F8FF)

	// MIPS DSP ASE
	check("ADDU.QB",    .ADDU_QB,    0x7C000010, 0xFC0007FF)
	check("ADDQ.PH",    .ADDQ_PH,    0x7C000290, 0xFC0007FF)
	check("DPAQ.S.W.PH",.DPAQ_S_W_PH,0x7C000130, 0xFC0007FF)
	check("EXTR.W",     .EXTR_W,     0x7C000038, 0xFC00073F)
	check("RDDSP",      .RDDSP,      0x7C0004B8, 0xFC1F07FF)
	check("BITREV",     .BITREV,     0x7C0006D2, 0xFFE007FF)
	check("LWX",        .LWX,        0x7C00000A, 0xFC0007FF)
	check("INSV",       .INSV,       0x7C00000C, 0xFC00FFFF)
	check("BPOSGE32",   .BPOSGE32,   0x041C0000, 0xFFFF0000)

	// ---- MSA (MIPS SIMD Architecture) -----------------------------------
	check("ADDV.B",     .ADDV_B,     0x7800000E, 0xFFE0003F)
	check("ADDV.W",     .ADDV_W,     0x7840000E, 0xFFE0003F)
	check("SUBV.D",     .SUBV_D,     0x78E0000E, 0xFFE0003F)
	check("MULV.W",     .MULV_W,     0x78400012, 0xFFE0003F)
	check("AND.V",      .AND_V,      0x7800001E, 0xFFE0003F)
	check("XOR.V",      .XOR_V,      0x7860001E, 0xFFE0003F)
	check("CEQ.B",      .CEQ_B,      0x7800000F, 0xFFE0003F)
	check("MIN_S.W",    .MIN_S_W,    0x7A40000E, 0xFFE0003F)
	check("MAX_U.D",    .MAX_U_D,    0x79E0000E, 0xFFE0003F)
	check("LD.W",       .LD_W,       0x78000022, 0xFC00003F)
	check("ST.D",       .ST_D,       0x78000027, 0xFC00003F)

	// ---- VFPU (PSP Allegrex) control / no-operand ops -------------------
	check("VNOP",       .VNOP,       0xFFFF0000, 0xFFFFFFFF)
	check("VSYNC",      .VSYNC,      0xFFFF0320, 0xFFFFFFFF)
	check("VFLUSH",     .VFLUSH,     0xFFFF040D, 0xFFFFFFFF)

	// ---- VFPU arithmetic ------------------------------------------------
	check("VADD.S",     .VADD_S,     0x60000000, 0xFF808080)
	check("VADD.P",     .VADD_P,     0x60000080, 0xFF808080)
	check("VADD.T",     .VADD_T,     0x60008000, 0xFF808080)
	check("VADD.Q",     .VADD_Q,     0x60008080, 0xFF808080)
	check("VSUB.S",     .VSUB_S,     0x60800000, 0xFF808080)
	check("VMUL.S",     .VMUL_S,     0x64000000, 0xFF808080)
	check("VMUL.Q",     .VMUL_Q,     0x64008080, 0xFF808080)
	check("VDIV.S",     .VDIV_S,     0x63800000, 0xFF808080)
	check("VABS.S",     .VABS_S,     0xD0010000, 0xFFFF8080)
	check("VNEG.Q",     .VNEG_Q,     0xD0028080, 0xFFFF8080)
	check("VMOV.S",     .VMOV_S,     0xD0000000, 0xFFFF8080)
	check("VSQRT.S",    .VSQRT_S,    0xD0160000, 0xFFFF8080)
	check("VRCP.P",     .VRCP_P,     0xD0100080, 0xFFFF8080)
	check("VRSQ.T",     .VRSQ_T,     0xD0118000, 0xFFFF8080)
	check("VMIN.Q",     .VMIN_Q,     0x6D008080, 0xFF808080)
	check("VMAX.S",     .VMAX_S,     0x6D800000, 0xFF808080)
	check("VSCL.Q",     .VSCL_Q,     0x65008080, 0xFF808080)
	check("VDOT.Q",     .VDOT_Q,     0x64808080, 0xFF808080)

	// ---- VFPU memory + prefix + GPR-bridge ------------------------------
	check("LV.S",       .LV_S,       0xC8000000, 0xFC000000)
	check("LV.Q",       .LV_Q,       0xD8000000, 0xFC000000)
	check("SV.S",       .SV_S,       0xE8000000, 0xFC000000)
	check("SV.Q",       .SV_Q,       0xF8000000, 0xFC000000)
	check("VCST.S",     .VCST_S,     0xD0600000, 0xFFE08080)
	check("VPFXS",      .VPFXS,      0xDC000000, 0xFFF00000)
	check("VPFXT",      .VPFXT,      0xDD000000, 0xFFF00000)
	check("VPFXD",      .VPFXD,      0xDE000000, 0xFFF00000)
	check("MFV",        .MFV,        0x48600000, 0xFFE00080)
	check("MTV",        .MTV,        0x48E00000, 0xFFE00080)

	// ---- VFPU transcendentals -------------------------------------------
	check("VSIN.S",     .VSIN_S,     0xD0120000, 0xFFFF8080)
	check("VCOS.S",     .VCOS_S,     0xD0130000, 0xFFFF8080)
	check("VEXP2.S",    .VEXP2_S,    0xD0140000, 0xFFFF8080)
	check("VLOG2.S",    .VLOG2_S,    0xD0150000, 0xFFFF8080)
	check("VASIN.S",    .VASIN_S,    0xD0170000, 0xFFFF8080)
	check("VNRCP.S",    .VNRCP_S,    0xD0180000, 0xFFFF8080)
	check("VNSIN.S",    .VNSIN_S,    0xD01A0000, 0xFFFF8080)
	check("VREXP2.S",   .VREXP2_S,   0xD01C0000, 0xFFFF8080)
	check("VSGN.S",     .VSGN_S,     0xD04A0000, 0xFFFF8080)

	// ---- VFPU conversions -----------------------------------------------
	check("VF2IN.S",    .VF2IN_S,    0xD2000000, 0xFFE08080)
	check("VF2IZ.Q",    .VF2IZ_Q,    0xD2208080, 0xFFE08080)
	check("VF2IU.T",    .VF2IU_T,    0xD2408000, 0xFFE08080)
	check("VF2ID.P",    .VF2ID_P,    0xD2600080, 0xFFE08080)
	check("VI2F.S",     .VI2F_S,     0xD2800000, 0xFFE08080)
	check("VF2H.P",     .VF2H_P,     0xD0320080, 0xFFFF8080)
	check("VH2F.S",     .VH2F_S,     0xD0330000, 0xFFFF8080)

	// ---- VFPU reductions ------------------------------------------------
	check("VFAD.Q",     .VFAD_Q,     0xD0468080, 0xFFFF8080)
	check("VAVG.Q",     .VAVG_Q,     0xD0478080, 0xFFFF8080)
	check("VHDP.Q",     .VHDP_Q,     0x66008080, 0xFF808080)

	// ---- VFPU compare ---------------------------------------------------
	check("VCMP.S",     .VCMP_S,     0x6C000000, 0xFF8080F0)
	check("VCMP.Q",     .VCMP_Q,     0x6C008080, 0xFF8080F0)

	// ---- VFPU matrix ----------------------------------------------------
	check("VMMUL.P",    .VMMUL_P,    0xF0000080, 0xFF808080)
	check("VMMUL.T",    .VMMUL_T,    0xF0008000, 0xFF808080)
	check("VMMUL.Q",    .VMMUL_Q,    0xF0008080, 0xFF808080)
	check("VTFM2.P",    .VTFM2_P,    0xF0800080, 0xFF808080)
	check("VTFM4.Q",    .VTFM4_Q,    0xF0808080, 0xFF808080)
	check("VHTFM2.P",   .VHTFM2_P,   0xF0800000, 0xFF808080)
	check("VMSCL.Q",    .VMSCL_Q,    0xF2008080, 0xFF808080)
	check("VMMOV.Q",    .VMMOV_Q,    0xF3808080, 0xFFFF8080)
	check("VMIDT.Q",    .VMIDT_Q,    0xF3838080, 0xFFFFFF80)
	check("VMZERO.Q",   .VMZERO_Q,   0xF3868080, 0xFFFFFF80)
	check("VMONE.Q",    .VMONE_Q,    0xF3878080, 0xFFFFFF80)

	// ---- VFPU cross / quaternion ----------------------------------------
	check("VCRS.T",     .VCRS_T,     0x66808000, 0xFF808080)
	check("VQMUL.Q",    .VQMUL_Q,    0xF2808080, 0xFF808080)

	// ---- VFPU control + branches ----------------------------------------
	check("MFVC",       .MFVC,       0x48400000, 0xFFE00000)
	check("MTVC",       .MTVC,       0x48C00000, 0xFFE00000)
	check("BVF",        .BVF,        0x49000000, 0xFFE30000)
	check("BVT",        .BVT,        0x49010000, 0xFFE30000)
	check("BVFL",       .BVFL,       0x49020000, 0xFFE30000)
	check("BVTL",       .BVTL,       0x49030000, 0xFFE30000)

	// ---- VFPU unaligned quad memory -------------------------------------
	check("LVL.Q",      .LVL_Q,      0xD4000002, 0xFC000002)
	check("LVR.Q",      .LVR_Q,      0xD4000000, 0xFC000002)
	check("SVL.Q",      .SVL_Q,      0xF4000002, 0xFC000002)
	check("SVR.Q",      .SVR_Q,      0xF4000000, 0xFC000002)

	// ---- VFPU integer/float immediate load ------------------------------
	check("VIIM.S",     .VIIM_S,     0xDF000000, 0xFF800000)
	check("VFIM.S",     .VFIM_S,     0xDF800000, 0xFF800000)

	fmt.println()
	fmt.printfln("==> table: %d passed, %d failed", passes, failures)
	if failures > 0 { os.exit(1) }

	run_encoder_tests()
	run_decoder_tests()
	run_printer_tests()
}
