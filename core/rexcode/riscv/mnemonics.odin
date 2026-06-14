package rexcode_riscv

// =============================================================================
// RISC-V MNEMONICS
// =============================================================================
//
// Coverage:
//   - RV32I + RV64I base integer (incl. JAL/JALR/branches/loads/stores)
//   - Zicsr (CSR access)
//   - Zifencei (FENCE.I)
//   - M  (multiply/divide, incl. .W RV64 variants)
//   - A  (atomics LR/SC + AMOs, .W and .D variants)
//   - F  (single-precision FP)
//   - D  (double-precision FP)
//
// RV32-only or RV64-only mnemonics are tagged in their Encoding entries
// via the `rv32_only` / `rv64_only` flags. The compressed extension (C)
// is intentionally out of scope for v1 -- it would require variable-
// length decoding and is best layered on later.

Mnemonic :: enum u16 {
	INVALID = 0,

	// -------------------------------------------------------------------------
	// RV32I / RV64I base
	// -------------------------------------------------------------------------

	// Upper-immediate
	LUI, AUIPC,

	// Jumps
	JAL, JALR,

	// Branches
	BEQ, BNE, BLT, BGE, BLTU, BGEU,

	// Loads / stores
	LB, LH, LW, LBU, LHU,
	SB, SH, SW,
	LWU, LD,            // RV64-only
	SD,                 // RV64-only

	// Integer reg-imm
	ADDI, SLTI, SLTIU, XORI, ORI, ANDI,
	SLLI, SRLI, SRAI,   // shift-immediate (5-bit shamt RV32; 6-bit RV64)
	ADDIW, SLLIW, SRLIW, SRAIW,   // RV64-only (32-bit ops)

	// Integer reg-reg
	ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND,
	ADDW, SUBW, SLLW, SRLW, SRAW,   // RV64-only

	// Memory ordering
	FENCE, FENCE_I,

	// System
	ECALL, EBREAK,

	// -------------------------------------------------------------------------
	// Zicsr (CSR access)
	// -------------------------------------------------------------------------

	CSRRW, CSRRS, CSRRC,
	CSRRWI, CSRRSI, CSRRCI,

	// -------------------------------------------------------------------------
	// M extension (multiply / divide)
	// -------------------------------------------------------------------------

	MUL, MULH, MULHSU, MULHU,
	DIV, DIVU, REM, REMU,
	MULW, DIVW, DIVUW, REMW, REMUW,   // RV64-only

	// -------------------------------------------------------------------------
	// A extension (atomics; word and doubleword forms)
	// -------------------------------------------------------------------------

	LR_W, SC_W,
	AMOSWAP_W, AMOADD_W, AMOXOR_W, AMOAND_W, AMOOR_W,
	AMOMIN_W, AMOMAX_W, AMOMINU_W, AMOMAXU_W,

	LR_D, SC_D,                       // RV64-only
	AMOSWAP_D, AMOADD_D, AMOXOR_D, AMOAND_D, AMOOR_D,
	AMOMIN_D, AMOMAX_D, AMOMINU_D, AMOMAXU_D,

	// -------------------------------------------------------------------------
	// F extension (single-precision FP)
	// -------------------------------------------------------------------------

	FLW, FSW,
	FMADD_S, FMSUB_S, FNMSUB_S, FNMADD_S,
	FADD_S, FSUB_S, FMUL_S, FDIV_S, FSQRT_S,
	FSGNJ_S, FSGNJN_S, FSGNJX_S,
	FMIN_S, FMAX_S,
	FCVT_W_S, FCVT_WU_S,
	FMV_X_W,
	FEQ_S, FLT_S, FLE_S,
	FCLASS_S,
	FCVT_S_W, FCVT_S_WU,
	FMV_W_X,
	FCVT_L_S, FCVT_LU_S, FCVT_S_L, FCVT_S_LU,   // RV64F

	// -------------------------------------------------------------------------
	// D extension (double-precision FP)
	// -------------------------------------------------------------------------

	FLD, FSD,
	FMADD_D, FMSUB_D, FNMSUB_D, FNMADD_D,
	FADD_D, FSUB_D, FMUL_D, FDIV_D, FSQRT_D,
	FSGNJ_D, FSGNJN_D, FSGNJX_D,
	FMIN_D, FMAX_D,
	FCVT_S_D, FCVT_D_S,
	FEQ_D, FLT_D, FLE_D,
	FCLASS_D,
	FCVT_W_D, FCVT_WU_D, FCVT_D_W, FCVT_D_WU,
	FCVT_L_D, FCVT_LU_D, FCVT_D_L, FCVT_D_LU,   // RV64D
	FMV_X_D, FMV_D_X,                            // RV64D

	// -------------------------------------------------------------------------
	// C extension (16-bit compressed). Each C.* mnemonic expands semantically
	// to a 32-bit base ISA instruction; the encoder picks the compressed
	// form by mnemonic.
	// -------------------------------------------------------------------------
	C_NOP, C_EBREAK,
	C_ADDI4SPN,                                  // rd', sp, imm
	C_LW, C_LD, C_SW, C_SD,                      // (RV64 LD/SD; RV32 has LW/SW)
	C_FLD, C_FSD,                                // double-precision FP load/store
	C_ADDI, C_ADDIW, C_LI, C_LUI,
	C_ADDI16SP,                                  // sp, imm
	C_SRLI, C_SRAI, C_ANDI,
	C_SUB, C_XOR, C_OR, C_AND,
	C_SUBW, C_ADDW,                              // RV64-only
	C_J, C_JAL,                                  // C.JAL is RV32-only; RV64 has C.ADDIW
	C_BEQZ, C_BNEZ,
	C_SLLI,
	C_LWSP, C_LDSP, C_SWSP, C_SDSP,
	C_FLDSP, C_FSDSP,
	C_JR, C_JALR, C_MV, C_ADD,
}
