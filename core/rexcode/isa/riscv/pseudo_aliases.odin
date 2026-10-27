package rexcode_riscv

// =============================================================================
// RISC-V PSEUDO-INSTRUCTION ALIAS TABLE
//
// Every entry here lowers to exactly ONE real INSTRUCTION_TABLE mnemonic by
// filling that target's operand slots. The real entry supplies the encoding
// and the clobber set for free — a pseudo's dataflow is its target's dataflow.
//
// Pseudos that CANNOT be expressed this way (value-dependent expansions and a
// couple of fixed-word HINTs) are listed as comments at the bottom; they stay
// procedures or dedicated table rows.
// =============================================================================

// How each operand slot of the target instruction is filled.
Alias_Src :: enum u8 {
	NONE,    // slot unused
	ARG0,    // user's 1st operand
	ARG1,    // user's 2nd operand
	ARG2,    // user's 3rd operand
	X0,      // hardwired zero (x0)
	X1,      // link register (ra / x1)
	LIT,     // the `lit` field below (immediate literal)
	CSR_LIT, // the `csr` field below (fixed 12-bit CSR address)
}

Pseudo_Alias :: struct {
	target:    Mnemonic,     // real instruction emitted
	src:       [4]Alias_Src, // how to fill target's four operand slots
	lit:       i16,          // immediate when a src slot is .LIT
	csr:       u16,          // CSR address when a src slot is .CSR_LIT
	nargs:     u8,           // operands the user supplies (ARG0..<ARGn)
	rv32_only: bool,         // base gate (the *h counter reads)
}

Pseudo_Mnemonic :: enum u16 {
	INVALID,
	// integer moves / arithmetic
	NOP, MV, NOT, NEG, NEGW, SEXT_W, ZEXT_B,
	// set-if / compare-to-zero
	SEQZ, SNEZ, SLTZ, SGTZ,
	// branch-on-zero
	BEQZ, BNEZ, BLEZ, BGEZ, BLTZ, BGTZ,
	// branch with swapped operands
	BGT, BLE, BGTU, BLEU,
	// jumps
	J, JAL_RA, JR, JALR_RA, RET,
	// generic CSR access
	CSRR, CSRW, CSRS, CSRC, CSRWI, CSRSI, CSRCI,
	// named counter reads (CSR baked in)
	RDCYCLE, RDTIME, RDINSTRET, RDCYCLEH, RDTIMEH, RDINSTRETH,
	// fcsr / frm / fflags accessors
	FRCSR, FSCSR, FRRM, FSRM, FRFLAGS, FSFLAGS, FSRMI, FSFLAGSI,
	// FP sign-injection moves
	FMV_S, FABS_S, FNEG_S,
	FMV_D, FABS_D, FNEG_D,
	FMV_H, FABS_H, FNEG_H,
	// memory ordering
	FENCE_ALL,
}

@(rodata)
PSEUDO_ALIASES := [Pseudo_Mnemonic]Pseudo_Alias{
	.INVALID = {},
	// -------------------------------------------------------------------------
	// Integer moves / arithmetic
	// -------------------------------------------------------------------------
	.NOP    = {target = .ADDI,  src = {.X0,   .X0,   .LIT,  .NONE}, nargs = 0},            // addi  x0, x0, 0
	.MV     = {target = .ADDI,  src = {.ARG0, .ARG1, .LIT,  .NONE}, nargs = 2},            // addi  rd, rs, 0
	.NOT    = {target = .XORI,  src = {.ARG0, .ARG1, .LIT,  .NONE}, lit = -1, nargs = 2},  // xori  rd, rs, -1
	.NEG    = {target = .SUB,   src = {.ARG0, .X0,   .ARG1, .NONE}, nargs = 2},            // sub   rd, x0, rs
	.NEGW   = {target = .SUBW,  src = {.ARG0, .X0,   .ARG1, .NONE}, nargs = 2},            // subw  rd, x0, rs   (RV64)
	.SEXT_W = {target = .ADDIW, src = {.ARG0, .ARG1, .LIT,  .NONE}, nargs = 2},            // addiw rd, rs, 0    (RV64)
	.ZEXT_B = {target = .ANDI,  src = {.ARG0, .ARG1, .LIT,  .NONE}, lit = 255, nargs = 2}, // andi  rd, rs, 255

	// -------------------------------------------------------------------------
	// Set-if-condition against zero
	// -------------------------------------------------------------------------
	.SEQZ = {target = .SLTIU, src = {.ARG0, .ARG1, .LIT,  .NONE}, lit = 1, nargs = 2},     // sltiu rd, rs, 1
	.SNEZ = {target = .SLTU,  src = {.ARG0, .X0,   .ARG1, .NONE}, nargs = 2},              // sltu  rd, x0, rs
	.SLTZ = {target = .SLT,   src = {.ARG0, .ARG1, .X0,   .NONE}, nargs = 2},              // slt   rd, rs, x0
	.SGTZ = {target = .SLT,   src = {.ARG0, .X0,   .ARG1, .NONE}, nargs = 2},              // slt   rd, x0, rs

	// -------------------------------------------------------------------------
	// Branch on comparison with zero  (target ops: rs1, rs2, offset)
	// -------------------------------------------------------------------------
	.BEQZ = {target = .BEQ, src = {.ARG0, .X0,   .ARG1, .NONE}, nargs = 2},                // beq rs, x0, off
	.BNEZ = {target = .BNE, src = {.ARG0, .X0,   .ARG1, .NONE}, nargs = 2},                // bne rs, x0, off
	.BLEZ = {target = .BGE, src = {.X0,   .ARG0, .ARG1, .NONE}, nargs = 2},                // bge x0, rs, off
	.BGEZ = {target = .BGE, src = {.ARG0, .X0,   .ARG1, .NONE}, nargs = 2},                // bge rs, x0, off
	.BLTZ = {target = .BLT, src = {.ARG0, .X0,   .ARG1, .NONE}, nargs = 2},                // blt rs, x0, off
	.BGTZ = {target = .BLT, src = {.X0,   .ARG0, .ARG1, .NONE}, nargs = 2},                // blt x0, rs, off

	// -------------------------------------------------------------------------
	// Branch with the two source registers swapped (encode-only rewrite;
	// never participates in decode, so the swap is safe)
	// -------------------------------------------------------------------------
	.BGT  = {target = .BLT,  src = {.ARG1, .ARG0, .ARG2, .NONE}, nargs = 3},               // blt  rt, rs, off
	.BLE  = {target = .BGE,  src = {.ARG1, .ARG0, .ARG2, .NONE}, nargs = 3},               // bge  rt, rs, off
	.BGTU = {target = .BLTU, src = {.ARG1, .ARG0, .ARG2, .NONE}, nargs = 3},               // bltu rt, rs, off
	.BLEU = {target = .BGEU, src = {.ARG1, .ARG0, .ARG2, .NONE}, nargs = 3},               // bgeu rt, rs, off

	// -------------------------------------------------------------------------
	// Jumps.  JAL_RA / JALR_RA are the single-operand forms that default the
	// link register to ra; the front-end selects them by argument count vs the
	// real 2-operand JAL / JALR.
	// -------------------------------------------------------------------------
	.J       = {target = .JAL,  src = {.X0, .ARG0, .NONE, .NONE}, nargs = 1},              // jal  x0, off
	.JAL_RA  = {target = .JAL,  src = {.X1, .ARG0, .NONE, .NONE}, nargs = 1},              // jal  x1, off
	.JR      = {target = .JALR, src = {.X0, .ARG0, .LIT,  .NONE}, nargs = 1},              // jalr x0, rs, 0
	.JALR_RA = {target = .JALR, src = {.X1, .ARG0, .LIT,  .NONE}, nargs = 1},              // jalr x1, rs, 0
	.RET     = {target = .JALR, src = {.X0, .X1,   .LIT,  .NONE}, nargs = 0},              // jalr x0, ra, 0

	// -------------------------------------------------------------------------
	// Generic CSR access  (target ops: rd, csr, rs1/zimm)
	// -------------------------------------------------------------------------
	.CSRR  = {target = .CSRRS,  src = {.ARG0, .ARG1, .X0,   .NONE}, nargs = 2},            // csrrs  rd, csr, x0
	.CSRW  = {target = .CSRRW,  src = {.X0,   .ARG0, .ARG1, .NONE}, nargs = 2},            // csrrw  x0, csr, rs
	.CSRS  = {target = .CSRRS,  src = {.X0,   .ARG0, .ARG1, .NONE}, nargs = 2},            // csrrs  x0, csr, rs
	.CSRC  = {target = .CSRRC,  src = {.X0,   .ARG0, .ARG1, .NONE}, nargs = 2},            // csrrc  x0, csr, rs
	.CSRWI = {target = .CSRRWI, src = {.X0,   .ARG0, .ARG1, .NONE}, nargs = 2},            // csrrwi x0, csr, imm
	.CSRSI = {target = .CSRRSI, src = {.X0,   .ARG0, .ARG1, .NONE}, nargs = 2},            // csrrsi x0, csr, imm
	.CSRCI = {target = .CSRRCI, src = {.X0,   .ARG0, .ARG1, .NONE}, nargs = 2},            // csrrci x0, csr, imm

	// -------------------------------------------------------------------------
	// Named counter reads — CSR baked in, so nargs = 1 (just rd).
	// The *h forms read the high word and exist only on RV32.
	// -------------------------------------------------------------------------
	.RDCYCLE     = {target = .CSRRS, src = {.ARG0, .CSR_LIT, .X0, .NONE}, csr = 0xC00, nargs = 1},
	.RDTIME      = {target = .CSRRS, src = {.ARG0, .CSR_LIT, .X0, .NONE}, csr = 0xC01, nargs = 1},
	.RDINSTRET   = {target = .CSRRS, src = {.ARG0, .CSR_LIT, .X0, .NONE}, csr = 0xC02, nargs = 1},
	.RDCYCLEH    = {target = .CSRRS, src = {.ARG0, .CSR_LIT, .X0, .NONE}, csr = 0xC80, nargs = 1, rv32_only = true},
	.RDTIMEH     = {target = .CSRRS, src = {.ARG0, .CSR_LIT, .X0, .NONE}, csr = 0xC81, nargs = 1, rv32_only = true},
	.RDINSTRETH  = {target = .CSRRS, src = {.ARG0, .CSR_LIT, .X0, .NONE}, csr = 0xC82, nargs = 1, rv32_only = true},

	// -------------------------------------------------------------------------
	// fcsr / frm / fflags accessors.  The read forms use CSRRS+x0; the write
	// forms shown keep the old value in rd (rd, rs). Write-only spellings
	// (fscsr rs, fsrm rs, fsflags rs, fsrmi imm, fsflagsi imm) default rd = x0
	// and are dispatched by argument count — add them if you want those too.
	// -------------------------------------------------------------------------
	.FRCSR    = {target = .CSRRS,  src = {.ARG0, .CSR_LIT, .X0,   .NONE}, csr = 0x003, nargs = 1},
	.FSCSR    = {target = .CSRRW,  src = {.ARG0, .CSR_LIT, .ARG1, .NONE}, csr = 0x003, nargs = 2},
	.FRRM     = {target = .CSRRS,  src = {.ARG0, .CSR_LIT, .X0,   .NONE}, csr = 0x002, nargs = 1},
	.FSRM     = {target = .CSRRW,  src = {.ARG0, .CSR_LIT, .ARG1, .NONE}, csr = 0x002, nargs = 2},
	.FRFLAGS  = {target = .CSRRS,  src = {.ARG0, .CSR_LIT, .X0,   .NONE}, csr = 0x001, nargs = 1},
	.FSFLAGS  = {target = .CSRRW,  src = {.ARG0, .CSR_LIT, .ARG1, .NONE}, csr = 0x001, nargs = 2},
	.FSRMI    = {target = .CSRRWI, src = {.ARG0, .CSR_LIT, .ARG1, .NONE}, csr = 0x002, nargs = 2},
	.FSFLAGSI = {target = .CSRRWI, src = {.ARG0, .CSR_LIT, .ARG1, .NONE}, csr = 0x001, nargs = 2},

	// -------------------------------------------------------------------------
	// FP moves via sign-injection: fmv=SGNJ(rs,rs), fneg=SGNJN, fabs=SGNJX.
	// Both source slots are the same user register.
	// -------------------------------------------------------------------------
	.FMV_S  = {target = .FSGNJ_S,  src = {.ARG0, .ARG1, .ARG1, .NONE}, nargs = 2},
	.FABS_S = {target = .FSGNJX_S, src = {.ARG0, .ARG1, .ARG1, .NONE}, nargs = 2},
	.FNEG_S = {target = .FSGNJN_S, src = {.ARG0, .ARG1, .ARG1, .NONE}, nargs = 2},
	.FMV_D  = {target = .FSGNJ_D,  src = {.ARG0, .ARG1, .ARG1, .NONE}, nargs = 2},
	.FABS_D = {target = .FSGNJX_D, src = {.ARG0, .ARG1, .ARG1, .NONE}, nargs = 2},
	.FNEG_D = {target = .FSGNJN_D, src = {.ARG0, .ARG1, .ARG1, .NONE}, nargs = 2},
	.FMV_H  = {target = .FSGNJ_H,  src = {.ARG0, .ARG1, .ARG1, .NONE}, nargs = 2},  // Zfh
	.FABS_H = {target = .FSGNJX_H, src = {.ARG0, .ARG1, .ARG1, .NONE}, nargs = 2},  // Zfh
	.FNEG_H = {target = .FSGNJN_H, src = {.ARG0, .ARG1, .ARG1, .NONE}, nargs = 2},  // Zfh

	// -------------------------------------------------------------------------
	// Bare `fence` == `fence iorw, iorw`; both fence-flag slots take lit = 0xF.
	// (This assumes the lit fill applies to every .LIT slot. If your filler is
	// single-slot, make FENCE_ALL a special case instead.)
	// -------------------------------------------------------------------------
	.FENCE_ALL = {target = .FENCE, src = {.LIT, .LIT, .NONE, .NONE}, lit = 0xF, nargs = 0},
}