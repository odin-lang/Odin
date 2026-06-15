// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_riscv_tests

// Spot-check ENCODING_TABLE entries against the canonical bit/mask
// patterns from the RISC-V User-Level ISA Manual (RV32I/RV64I + M/A/F/D
// + Zicsr/Zifencei). One representative entry from each section.
//
// Run with: odin run riscv/tests

import "core:fmt"
import "core:os"
import rv "../"

@(private="file") passes := 0
@(private="file") failures := 0

@(private="file")
check :: proc(name: string, m: rv.Mnemonic, want_bits, want_mask: u32) {
	_run := rv.ENCODE_RUNS[u16(m)]
	encs := rv.ENCODE_FORMS[_run.start:][:_run.count]
	if len(encs) == 0 {
		fmt.printfln("  [FAIL] %s: no encoding", name)
		failures += 1
		return
	}
	e := encs[0]
	if e.bits != want_bits || e.mask != want_mask {
		fmt.printfln("  [FAIL] %-14s got bits=%08x mask=%08x  want bits=%08x mask=%08x",
					 name, e.bits, e.mask, want_bits, want_mask)
		failures += 1
		return
	}
	fmt.printfln("  [ok]   %-14s %08x / %08x (feature=%v)", name, e.bits, e.mask, e.feature)
	passes += 1
}

main :: proc() {
	fmt.println("=== RISC-V encoding-table spot checks ===")

	// ---- RV32I base ---------------------------------------------------------
	check("ADD",     .ADD,     0x00000033, 0xFE00707F)
	check("SUB",     .SUB,     0x40000033, 0xFE00707F)
	check("AND",     .AND,     0x00007033, 0xFE00707F)
	check("OR",      .OR,      0x00006033, 0xFE00707F)
	check("XOR",     .XOR,     0x00004033, 0xFE00707F)
	check("SLT",     .SLT,     0x00002033, 0xFE00707F)
	check("SLTU",    .SLTU,    0x00003033, 0xFE00707F)
	check("SLL",     .SLL,     0x00001033, 0xFE00707F)
	check("SRL",     .SRL,     0x00005033, 0xFE00707F)
	check("SRA",     .SRA,     0x40005033, 0xFE00707F)

	check("ADDI",    .ADDI,    0x00000013, 0x0000707F)
	check("XORI",    .XORI,    0x00004013, 0x0000707F)
	check("SLLI",    .SLLI,    0x00001013, 0xFC00707F)
	check("SRAI",    .SRAI,    0x40005013, 0xFC00707F)

	check("LUI",     .LUI,     0x00000037, 0x0000007F)
	check("AUIPC",   .AUIPC,   0x00000017, 0x0000007F)
	check("JAL",     .JAL,     0x0000006F, 0x0000007F)
	check("JALR",    .JALR,    0x00000067, 0x0000707F)

	check("BEQ",     .BEQ,     0x00000063, 0x0000707F)
	check("BNE",     .BNE,     0x00001063, 0x0000707F)
	check("BLT",     .BLT,     0x00004063, 0x0000707F)
	check("BGEU",    .BGEU,    0x00007063, 0x0000707F)

	check("LB",      .LB,      0x00000003, 0x0000707F)
	check("LW",      .LW,      0x00002003, 0x0000707F)
	check("LBU",     .LBU,     0x00004003, 0x0000707F)
	check("SB",      .SB,      0x00000023, 0x0000707F)
	check("SW",      .SW,      0x00002023, 0x0000707F)

	check("FENCE",   .FENCE,   0x0000000F, 0x0000707F)
	check("FENCE_I", .FENCE_I, 0x0000100F, 0xFFFFFFFF)
	check("ECALL",   .ECALL,   0x00000073, 0xFFFFFFFF)
	check("EBREAK",  .EBREAK,  0x00100073, 0xFFFFFFFF)

	// ---- RV64I additions ---------------------------------------------------
	check("LD",      .LD,      0x00003003, 0x0000707F)
	check("LWU",     .LWU,     0x00006003, 0x0000707F)
	check("SD",      .SD,      0x00003023, 0x0000707F)
	check("ADDIW",   .ADDIW,   0x0000001B, 0x0000707F)
	check("SLLIW",   .SLLIW,   0x0000101B, 0xFE00707F)
	check("ADDW",    .ADDW,    0x0000003B, 0xFE00707F)
	check("SUBW",    .SUBW,    0x4000003B, 0xFE00707F)

	// ---- Zicsr -------------------------------------------------------------
	check("CSRRW",   .CSRRW,   0x00001073, 0x0000707F)
	check("CSRRS",   .CSRRS,   0x00002073, 0x0000707F)
	check("CSRRWI",  .CSRRWI,  0x00005073, 0x0000707F)

	// ---- M extension -------------------------------------------------------
	check("MUL",     .MUL,     0x02000033, 0xFE00707F)
	check("MULH",    .MULH,    0x02001033, 0xFE00707F)
	check("DIV",     .DIV,     0x02004033, 0xFE00707F)
	check("REMU",    .REMU,    0x02007033, 0xFE00707F)
	check("MULW",    .MULW,    0x0200003B, 0xFE00707F)
	check("DIVUW",   .DIVUW,   0x0200503B, 0xFE00707F)

	// ---- A extension -------------------------------------------------------
	check("LR_W",      .LR_W,      0x1000202F, 0xF9F0707F)
	check("SC_W",      .SC_W,      0x1800202F, 0xF800707F)
	check("AMOSWAP_W", .AMOSWAP_W, 0x0800202F, 0xF800707F)
	check("AMOADD_W",  .AMOADD_W,  0x0000202F, 0xF800707F)
	check("AMOMAXU_W", .AMOMAXU_W, 0xE000202F, 0xF800707F)
	check("LR_D",      .LR_D,      0x1000302F, 0xF9F0707F)
	check("AMOADD_D",  .AMOADD_D,  0x0000302F, 0xF800707F)

	// ---- F extension -------------------------------------------------------
	check("FLW",       .FLW,       0x00002007, 0x0000707F)
	check("FSW",       .FSW,       0x00002027, 0x0000707F)
	check("FADD_S",    .FADD_S,    0x00000053, 0xFE00007F)
	check("FSUB_S",    .FSUB_S,    0x08000053, 0xFE00007F)
	check("FMUL_S",    .FMUL_S,    0x10000053, 0xFE00007F)
	check("FDIV_S",    .FDIV_S,    0x18000053, 0xFE00007F)
	check("FSQRT_S",   .FSQRT_S,   0x58000053, 0xFFF0007F)
	check("FSGNJ_S",   .FSGNJ_S,   0x20000053, 0xFE00707F)
	check("FMIN_S",    .FMIN_S,    0x28000053, 0xFE00707F)
	check("FMAX_S",    .FMAX_S,    0x28001053, 0xFE00707F)
	check("FCVT_W_S",  .FCVT_W_S,  0xC0000053, 0xFFF0007F)
	check("FCVT_S_W",  .FCVT_S_W,  0xD0000053, 0xFFF0007F)
	check("FMV_X_W",   .FMV_X_W,   0xE0000053, 0xFFF0707F)
	check("FMV_W_X",   .FMV_W_X,   0xF0000053, 0xFFF0707F)
	check("FCLASS_S",  .FCLASS_S,  0xE0001053, 0xFFF0707F)
	check("FEQ_S",     .FEQ_S,     0xA0002053, 0xFE00707F)
	check("FLT_S",     .FLT_S,     0xA0001053, 0xFE00707F)
	check("FLE_S",     .FLE_S,     0xA0000053, 0xFE00707F)
	check("FMADD_S",   .FMADD_S,   0x00000043, 0x0600007F)
	check("FNMADD_S",  .FNMADD_S,  0x0000004F, 0x0600007F)

	// ---- D extension -------------------------------------------------------
	check("FLD",       .FLD,       0x00003007, 0x0000707F)
	check("FSD",       .FSD,       0x00003027, 0x0000707F)
	check("FADD_D",    .FADD_D,    0x02000053, 0xFE00007F)
	check("FSUB_D",    .FSUB_D,    0x0A000053, 0xFE00007F)
	check("FMUL_D",    .FMUL_D,    0x12000053, 0xFE00007F)
	check("FSQRT_D",   .FSQRT_D,   0x5A000053, 0xFFF0007F)
	check("FCVT_S_D",  .FCVT_S_D,  0x40100053, 0xFFF0007F)
	check("FCVT_D_S",  .FCVT_D_S,  0x42000053, 0xFFF0007F)
	check("FEQ_D",     .FEQ_D,     0xA2002053, 0xFE00707F)
	check("FCLASS_D",  .FCLASS_D,  0xE2001053, 0xFFF0707F)
	check("FMADD_D",   .FMADD_D,   0x02000043, 0x0600007F)
	check("FMV_X_D",   .FMV_X_D,   0xE2000053, 0xFFF0707F)
	check("FMV_D_X",   .FMV_D_X,   0xF2000053, 0xFFF0707F)

	fmt.println()
	fmt.printfln("==> table: %d passed, %d failed", passes, failures)
	if failures > 0 { os.exit(1) }

	run_pipeline_tests()
}
