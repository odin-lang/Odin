// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_riscv_tablegen

// =============================================================================
// RISC-V ENCODING_TABLE
// =============================================================================
//
// (bits, mask) model -- same shape as MIPS. `bits` carries the static
// opcode/funct3/funct7 pattern; `mask` covers exactly the bits that are
// fixed. Operand-driven fields (rd, rs1, rs2, immediates, rounding mode,
// aq/rl) land in zero positions of `bits` and are ORed in by the encoder.
//
// Sections:
//   §1  RV32I + RV64I base
//   §2  Zicsr (CSR access) + Zifencei (FENCE.I)
//   §3  M extension
//   §4  A extension (atomics)
//   §5  F extension (single-precision FP)
//   §6  D extension (double-precision FP)
@(rodata)
ENCODING_TABLE:= #partial [Mnemonic][]Encoding{
	.INVALID = {},

	// =========================================================================
	// §1 RV32I / RV64I base
	// =========================================================================

	// ---- Upper-immediate ----------------------------------------------------
	.LUI   = { {.LUI,   {.GPR,.IMM20,.NONE,.NONE}, {.RD,.IMM_U,.NONE,.NONE}, 0x00000037, MASK_U, .I, {}} },
	.AUIPC = { {.AUIPC, {.GPR,.IMM20,.NONE,.NONE}, {.RD,.IMM_U,.NONE,.NONE}, 0x00000017, MASK_U, .I, {}} },

	// ---- Jumps --------------------------------------------------------------
	.JAL   = { {.JAL,  {.GPR,.REL21,.NONE,.NONE},  {.RD,.IMM_J,.NONE,.NONE}, 0x0000006F, MASK_J, .I, {branch=true}} },
	.JALR  = { {.JALR, {.GPR,.GPR,.IMM12,.NONE},   {.RD,.RS1,.IMM_I,.NONE},  0x00000067, MASK_OPCODE | MASK_FUNCT3, .I, {branch=true}} },

	// ---- Branches (B-type) --------------------------------------------------
	.BEQ  = { {.BEQ,  {.GPR,.GPR,.REL13,.NONE}, {.RS1,.RS2,.IMM_B,.NONE}, 0x00000063, MASK_B, .I, {branch=true}} },
	.BNE  = { {.BNE,  {.GPR,.GPR,.REL13,.NONE}, {.RS1,.RS2,.IMM_B,.NONE}, 0x00001063, MASK_B, .I, {branch=true}} },
	.BLT  = { {.BLT,  {.GPR,.GPR,.REL13,.NONE}, {.RS1,.RS2,.IMM_B,.NONE}, 0x00004063, MASK_B, .I, {branch=true}} },
	.BGE  = { {.BGE,  {.GPR,.GPR,.REL13,.NONE}, {.RS1,.RS2,.IMM_B,.NONE}, 0x00005063, MASK_B, .I, {branch=true}} },
	.BLTU = { {.BLTU, {.GPR,.GPR,.REL13,.NONE}, {.RS1,.RS2,.IMM_B,.NONE}, 0x00006063, MASK_B, .I, {branch=true}} },
	.BGEU = { {.BGEU, {.GPR,.GPR,.REL13,.NONE}, {.RS1,.RS2,.IMM_B,.NONE}, 0x00007063, MASK_B, .I, {branch=true}} },

	// ---- Loads (I-type) -----------------------------------------------------
	.LB  = { {.LB,  {.GPR,.MEM,.NONE,.NONE}, {.RD,.OFFSET_BASE_I,.NONE,.NONE}, 0x00000003, MASK_I, .I, {}} },
	.LH  = { {.LH,  {.GPR,.MEM,.NONE,.NONE}, {.RD,.OFFSET_BASE_I,.NONE,.NONE}, 0x00001003, MASK_I, .I, {}} },
	.LW  = { {.LW,  {.GPR,.MEM,.NONE,.NONE}, {.RD,.OFFSET_BASE_I,.NONE,.NONE}, 0x00002003, MASK_I, .I, {}} },
	.LBU = { {.LBU, {.GPR,.MEM,.NONE,.NONE}, {.RD,.OFFSET_BASE_I,.NONE,.NONE}, 0x00004003, MASK_I, .I, {}} },
	.LHU = { {.LHU, {.GPR,.MEM,.NONE,.NONE}, {.RD,.OFFSET_BASE_I,.NONE,.NONE}, 0x00005003, MASK_I, .I, {}} },
	.LWU = { {.LWU, {.GPR,.MEM,.NONE,.NONE}, {.RD,.OFFSET_BASE_I,.NONE,.NONE}, 0x00006003, MASK_I, .I, {rv64_only=true}} },
	.LD  = { {.LD,  {.GPR,.MEM,.NONE,.NONE}, {.RD,.OFFSET_BASE_I,.NONE,.NONE}, 0x00003003, MASK_I, .I, {rv64_only=true}} },

	// ---- Stores (S-type) ----------------------------------------------------
	.SB = { {.SB, {.GPR,.MEM,.NONE,.NONE}, {.RS2,.OFFSET_BASE_S,.NONE,.NONE}, 0x00000023, MASK_S, .I, {}} },
	.SH = { {.SH, {.GPR,.MEM,.NONE,.NONE}, {.RS2,.OFFSET_BASE_S,.NONE,.NONE}, 0x00001023, MASK_S, .I, {}} },
	.SW = { {.SW, {.GPR,.MEM,.NONE,.NONE}, {.RS2,.OFFSET_BASE_S,.NONE,.NONE}, 0x00002023, MASK_S, .I, {}} },
	.SD = { {.SD, {.GPR,.MEM,.NONE,.NONE}, {.RS2,.OFFSET_BASE_S,.NONE,.NONE}, 0x00003023, MASK_S, .I, {rv64_only=true}} },

	// ---- Integer reg-imm (I-type ALU) ---------------------------------------
	.ADDI  = { {.ADDI,  {.GPR,.GPR,.IMM12,.NONE}, {.RD,.RS1,.IMM_I,.NONE}, 0x00000013, MASK_I, .I, {}} },
	.SLTI  = { {.SLTI,  {.GPR,.GPR,.IMM12,.NONE}, {.RD,.RS1,.IMM_I,.NONE}, 0x00002013, MASK_I, .I, {}} },
	.SLTIU = { {.SLTIU, {.GPR,.GPR,.IMM12,.NONE}, {.RD,.RS1,.IMM_I,.NONE}, 0x00003013, MASK_I, .I, {}} },
	.XORI  = { {.XORI,  {.GPR,.GPR,.IMM12,.NONE}, {.RD,.RS1,.IMM_I,.NONE}, 0x00004013, MASK_I, .I, {}} },
	.ORI   = { {.ORI,   {.GPR,.GPR,.IMM12,.NONE}, {.RD,.RS1,.IMM_I,.NONE}, 0x00006013, MASK_I, .I, {}} },
	.ANDI  = { {.ANDI,  {.GPR,.GPR,.IMM12,.NONE}, {.RD,.RS1,.IMM_I,.NONE}, 0x00007013, MASK_I, .I, {}} },

	// I-type shifts. RV32 uses 5-bit shamt + funct7; RV64 widens to 6-bit
	// shamt + funct6. We list the RV64-compatible mask (funct6 fixed,
	// shamt[5] operand-driven); on RV32 the user must keep shamt < 32.
	.SLLI = { {.SLLI, {.GPR,.GPR,.IMM6,.NONE}, {.RD,.RS1,.SHAMT6,.NONE}, 0x00001013, MASK_OPCODE | MASK_FUNCT3 | 0xFC000000, .I, {}} },
	.SRLI = { {.SRLI, {.GPR,.GPR,.IMM6,.NONE}, {.RD,.RS1,.SHAMT6,.NONE}, 0x00005013, MASK_OPCODE | MASK_FUNCT3 | 0xFC000000, .I, {}} },
	.SRAI = { {.SRAI, {.GPR,.GPR,.IMM6,.NONE}, {.RD,.RS1,.SHAMT6,.NONE}, 0x40005013, MASK_OPCODE | MASK_FUNCT3 | 0xFC000000, .I, {}} },

	// RV64 OP-IMM-32 (operates on low 32 bits, sign-extends result)
	.ADDIW = { {.ADDIW, {.GPR,.GPR,.IMM12,.NONE}, {.RD,.RS1,.IMM_I,.NONE},  0x0000001B, MASK_I, .I, {rv64_only=true}} },
	.SLLIW = { {.SLLIW, {.GPR,.GPR,.IMM5,.NONE},  {.RD,.RS1,.SHAMT5,.NONE}, 0x0000101B, MASK_R, .I, {rv64_only=true}} },
	.SRLIW = { {.SRLIW, {.GPR,.GPR,.IMM5,.NONE},  {.RD,.RS1,.SHAMT5,.NONE}, 0x0000501B, MASK_R, .I, {rv64_only=true}} },
	.SRAIW = { {.SRAIW, {.GPR,.GPR,.IMM5,.NONE},  {.RD,.RS1,.SHAMT5,.NONE}, 0x4000501B, MASK_R, .I, {rv64_only=true}} },

	// ---- Integer reg-reg (R-type) -------------------------------------------
	.ADD  = { {.ADD,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x00000033, MASK_R, .I, {}} },
	.SUB  = { {.SUB,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x40000033, MASK_R, .I, {}} },
	.SLL  = { {.SLL,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x00001033, MASK_R, .I, {}} },
	.SLT  = { {.SLT,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x00002033, MASK_R, .I, {}} },
	.SLTU = { {.SLTU, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x00003033, MASK_R, .I, {}} },
	.XOR  = { {.XOR,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x00004033, MASK_R, .I, {}} },
	.SRL  = { {.SRL,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x00005033, MASK_R, .I, {}} },
	.SRA  = { {.SRA,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x40005033, MASK_R, .I, {}} },
	.OR   = { {.OR,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x00006033, MASK_R, .I, {}} },
	.AND  = { {.AND,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x00007033, MASK_R, .I, {}} },

	// RV64 OP-32
	.ADDW = { {.ADDW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x0000003B, MASK_R, .I, {rv64_only=true}} },
	.SUBW = { {.SUBW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x4000003B, MASK_R, .I, {rv64_only=true}} },
	.SLLW = { {.SLLW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x0000103B, MASK_R, .I, {rv64_only=true}} },
	.SRLW = { {.SRLW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x0000503B, MASK_R, .I, {rv64_only=true}} },
	.SRAW = { {.SRAW, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x4000503B, MASK_R, .I, {rv64_only=true}} },

	// ---- Memory ordering ----------------------------------------------------
	// FENCE encodes pred/succ in bits 27-24 / 23-20. The opcode reserves
	// these as operand-driven; mask covers opcode + funct3.
	.FENCE   = { {.FENCE,   {.FENCE_FLAGS,.FENCE_FLAGS,.NONE,.NONE}, {.FENCE_PRED,.FENCE_SUCC,.NONE,.NONE}, 0x0000000F, MASK_I, .I, {}} },
	.FENCE_I = { {.FENCE_I, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x0000100F, 0xFFFFFFFF, .ZIFENCEI, {}} },

	// ---- System -------------------------------------------------------------
	.ECALL  = { {.ECALL,  {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x00000073, 0xFFFFFFFF, .I, {branch=true}} },
	.EBREAK = { {.EBREAK, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x00100073, 0xFFFFFFFF, .I, {branch=true}} },

	// =========================================================================
	// §2 Zicsr (CSR access)
	// =========================================================================
	//   CSRRW rd, csr, rs1
	//   CSRRWI rd, csr, zimm5  (zimm5 lives in the RS1 field)

	.CSRRW  = { {.CSRRW,  {.GPR,.CSR,.GPR,.NONE},   {.RD,.CSR_FIELD,.RS1,.NONE},        0x00001073, MASK_I, .ZICSR, {}} },
	.CSRRS  = { {.CSRRS,  {.GPR,.CSR,.GPR,.NONE},   {.RD,.CSR_FIELD,.RS1,.NONE},        0x00002073, MASK_I, .ZICSR, {}} },
	.CSRRC  = { {.CSRRC,  {.GPR,.CSR,.GPR,.NONE},   {.RD,.CSR_FIELD,.RS1,.NONE},        0x00003073, MASK_I, .ZICSR, {}} },
	.CSRRWI = { {.CSRRWI, {.GPR,.CSR,.ZIMM5,.NONE}, {.RD,.CSR_FIELD,.ZIMM_FIELD,.NONE}, 0x00005073, MASK_I, .ZICSR, {}} },
	.CSRRSI = { {.CSRRSI, {.GPR,.CSR,.ZIMM5,.NONE}, {.RD,.CSR_FIELD,.ZIMM_FIELD,.NONE}, 0x00006073, MASK_I, .ZICSR, {}} },
	.CSRRCI = { {.CSRRCI, {.GPR,.CSR,.ZIMM5,.NONE}, {.RD,.CSR_FIELD,.ZIMM_FIELD,.NONE}, 0x00007073, MASK_I, .ZICSR, {}} },

	// =========================================================================
	// §3 M extension (RV32M / RV64M)
	// =========================================================================
	//   All share opcode 0x33 and funct7 = 0x01.

	.MUL    = { {.MUL,    {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x02000033, MASK_R, .M, {}} },
	.MULH   = { {.MULH,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x02001033, MASK_R, .M, {}} },
	.MULHSU = { {.MULHSU, {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x02002033, MASK_R, .M, {}} },
	.MULHU  = { {.MULHU,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x02003033, MASK_R, .M, {}} },
	.DIV    = { {.DIV,    {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x02004033, MASK_R, .M, {}} },
	.DIVU   = { {.DIVU,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x02005033, MASK_R, .M, {}} },
	.REM    = { {.REM,    {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x02006033, MASK_R, .M, {}} },
	.REMU   = { {.REMU,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x02007033, MASK_R, .M, {}} },

	// RV64 M-32 variants (opcode 0x3B)
	.MULW   = { {.MULW,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x0200003B, MASK_R, .M, {rv64_only=true}} },
	.DIVW   = { {.DIVW,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x0200403B, MASK_R, .M, {rv64_only=true}} },
	.DIVUW  = { {.DIVUW,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x0200503B, MASK_R, .M, {rv64_only=true}} },
	.REMW   = { {.REMW,   {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x0200603B, MASK_R, .M, {rv64_only=true}} },
	.REMUW  = { {.REMUW,  {.GPR,.GPR,.GPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x0200703B, MASK_R, .M, {rv64_only=true}} },

	// =========================================================================
	// §4 A extension (atomics)
	// =========================================================================
	//   opcode 0x2F; funct3 = 2 for .W and 3 for .D; funct5 (bits 31-27)
	//   picks the op; bits 26-25 are aq/rl (operand). Mask = opcode +
	//   funct3 + funct5 = 0xF800707F.
	//
	//   LR.W/LR.D take only one register addr (rd, rs1); rs2 must be 0
	//   and is part of the static mask.
	//
	//   The address operand uses OFFSET_BASE_A (rs1 only; disp must be 0).

	.LR_W      = { {.LR_W,      {.GPR,.MEM,.NONE,.NONE},      {.RD,.OFFSET_BASE_A,.NONE,.NONE},      0x1000202F, 0xF9F0707F, .A, {}} },
	.SC_W      = { {.SC_W,      {.GPR,.GPR,.MEM,.NONE},       {.RD,.RS2,.OFFSET_BASE_A,.NONE},       0x1800202F, 0xF800707F, .A, {}} },
	.AMOSWAP_W = { {.AMOSWAP_W, {.GPR,.GPR,.MEM,.NONE},       {.RD,.RS2,.OFFSET_BASE_A,.NONE},       0x0800202F, 0xF800707F, .A, {}} },
	.AMOADD_W  = { {.AMOADD_W,  {.GPR,.GPR,.MEM,.NONE},       {.RD,.RS2,.OFFSET_BASE_A,.NONE},       0x0000202F, 0xF800707F, .A, {}} },
	.AMOXOR_W  = { {.AMOXOR_W,  {.GPR,.GPR,.MEM,.NONE},       {.RD,.RS2,.OFFSET_BASE_A,.NONE},       0x2000202F, 0xF800707F, .A, {}} },
	.AMOAND_W  = { {.AMOAND_W,  {.GPR,.GPR,.MEM,.NONE},       {.RD,.RS2,.OFFSET_BASE_A,.NONE},       0x6000202F, 0xF800707F, .A, {}} },
	.AMOOR_W   = { {.AMOOR_W,   {.GPR,.GPR,.MEM,.NONE},       {.RD,.RS2,.OFFSET_BASE_A,.NONE},       0x4000202F, 0xF800707F, .A, {}} },
	.AMOMIN_W  = { {.AMOMIN_W,  {.GPR,.GPR,.MEM,.NONE},       {.RD,.RS2,.OFFSET_BASE_A,.NONE},       0x8000202F, 0xF800707F, .A, {}} },
	.AMOMAX_W  = { {.AMOMAX_W,  {.GPR,.GPR,.MEM,.NONE},       {.RD,.RS2,.OFFSET_BASE_A,.NONE},       0xA000202F, 0xF800707F, .A, {}} },
	.AMOMINU_W = { {.AMOMINU_W, {.GPR,.GPR,.MEM,.NONE},       {.RD,.RS2,.OFFSET_BASE_A,.NONE},       0xC000202F, 0xF800707F, .A, {}} },
	.AMOMAXU_W = { {.AMOMAXU_W, {.GPR,.GPR,.MEM,.NONE},       {.RD,.RS2,.OFFSET_BASE_A,.NONE},       0xE000202F, 0xF800707F, .A, {}} },

	.LR_D      = { {.LR_D,      {.GPR,.MEM,.NONE,.NONE},      {.RD,.OFFSET_BASE_A,.NONE,.NONE},      0x1000302F, 0xF9F0707F, .A, {rv64_only=true}} },
	.SC_D      = { {.SC_D,      {.GPR,.GPR,.MEM,.NONE},       {.RD,.RS2,.OFFSET_BASE_A,.NONE},       0x1800302F, 0xF800707F, .A, {rv64_only=true}} },
	.AMOSWAP_D = { {.AMOSWAP_D, {.GPR,.GPR,.MEM,.NONE},       {.RD,.RS2,.OFFSET_BASE_A,.NONE},       0x0800302F, 0xF800707F, .A, {rv64_only=true}} },
	.AMOADD_D  = { {.AMOADD_D,  {.GPR,.GPR,.MEM,.NONE},       {.RD,.RS2,.OFFSET_BASE_A,.NONE},       0x0000302F, 0xF800707F, .A, {rv64_only=true}} },
	.AMOXOR_D  = { {.AMOXOR_D,  {.GPR,.GPR,.MEM,.NONE},       {.RD,.RS2,.OFFSET_BASE_A,.NONE},       0x2000302F, 0xF800707F, .A, {rv64_only=true}} },
	.AMOAND_D  = { {.AMOAND_D,  {.GPR,.GPR,.MEM,.NONE},       {.RD,.RS2,.OFFSET_BASE_A,.NONE},       0x6000302F, 0xF800707F, .A, {rv64_only=true}} },
	.AMOOR_D   = { {.AMOOR_D,   {.GPR,.GPR,.MEM,.NONE},       {.RD,.RS2,.OFFSET_BASE_A,.NONE},       0x4000302F, 0xF800707F, .A, {rv64_only=true}} },
	.AMOMIN_D  = { {.AMOMIN_D,  {.GPR,.GPR,.MEM,.NONE},       {.RD,.RS2,.OFFSET_BASE_A,.NONE},       0x8000302F, 0xF800707F, .A, {rv64_only=true}} },
	.AMOMAX_D  = { {.AMOMAX_D,  {.GPR,.GPR,.MEM,.NONE},       {.RD,.RS2,.OFFSET_BASE_A,.NONE},       0xA000302F, 0xF800707F, .A, {rv64_only=true}} },
	.AMOMINU_D = { {.AMOMINU_D, {.GPR,.GPR,.MEM,.NONE},       {.RD,.RS2,.OFFSET_BASE_A,.NONE},       0xC000302F, 0xF800707F, .A, {rv64_only=true}} },
	.AMOMAXU_D = { {.AMOMAXU_D, {.GPR,.GPR,.MEM,.NONE},       {.RD,.RS2,.OFFSET_BASE_A,.NONE},       0xE000302F, 0xF800707F, .A, {rv64_only=true}} },

	// =========================================================================
	// §5 F extension (single-precision)
	// =========================================================================
	//
	// OP-FP opcode = 0x53. funct7 selects op family. funct3 is normally the
	// FP rounding mode (operand-driven, fp_round flag) but is fixed for a
	// few ops (FMV/FCLASS/FEQ/FLT/FLE/FSGNJ*).
	//
	// Masks include opcode + funct7 always. funct3 is included only when
	// it's a fixed selector rather than a rounding mode. rs2 is included
	// when it's a fixed selector (FCVT/FMV/FCLASS/FSQRT).
	//
	// MASK macros used below:
	//   M_OP_F7        :: opcode + funct7
	//   M_OP_F7_RS2    :: + rs2
	//   M_OP_F7_F3     :: + funct3
	//   M_OP_F7_F3_RS2 :: + both

	.FLW = { {.FLW, {.FPR,.MEM,.NONE,.NONE}, {.RD,.OFFSET_BASE_I,.NONE,.NONE}, 0x00002007, MASK_I, .F, {}} },
	.FSW = { {.FSW, {.FPR,.MEM,.NONE,.NONE}, {.RS2,.OFFSET_BASE_S,.NONE,.NONE}, 0x00002027, MASK_S, .F, {}} },

	// R4-type FMA: opcode + fmt (bits 26-25); fmt=00 for .S
	.FMADD_S  = { {.FMADD_S,  {.FPR,.FPR,.FPR,.FPR}, {.RD,.RS1,.RS2,.RS3}, 0x00000043, 0x0600007F, .F, {fp_round=true}} },
	.FMSUB_S  = { {.FMSUB_S,  {.FPR,.FPR,.FPR,.FPR}, {.RD,.RS1,.RS2,.RS3}, 0x00000047, 0x0600007F, .F, {fp_round=true}} },
	.FNMSUB_S = { {.FNMSUB_S, {.FPR,.FPR,.FPR,.FPR}, {.RD,.RS1,.RS2,.RS3}, 0x0000004B, 0x0600007F, .F, {fp_round=true}} },
	.FNMADD_S = { {.FNMADD_S, {.FPR,.FPR,.FPR,.FPR}, {.RD,.RS1,.RS2,.RS3}, 0x0000004F, 0x0600007F, .F, {fp_round=true}} },

	// R-type with rm
	.FADD_S  = { {.FADD_S,  {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x00000053, MASK_OPCODE | MASK_FUNCT7, .F, {fp_round=true}} },
	.FSUB_S  = { {.FSUB_S,  {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x08000053, MASK_OPCODE | MASK_FUNCT7, .F, {fp_round=true}} },
	.FMUL_S  = { {.FMUL_S,  {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x10000053, MASK_OPCODE | MASK_FUNCT7, .F, {fp_round=true}} },
	.FDIV_S  = { {.FDIV_S,  {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x18000053, MASK_OPCODE | MASK_FUNCT7, .F, {fp_round=true}} },
	.FSQRT_S = { {.FSQRT_S, {.FPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0x58000053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .F, {fp_round=true}} },

	// FSGNJ family: funct7 fixed (0x10), funct3 selects sub-op (no rm)
	.FSGNJ_S  = { {.FSGNJ_S,  {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x20000053, MASK_R, .F, {}} },
	.FSGNJN_S = { {.FSGNJN_S, {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x20001053, MASK_R, .F, {}} },
	.FSGNJX_S = { {.FSGNJX_S, {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x20002053, MASK_R, .F, {}} },

	// FMIN/FMAX: funct7=0x14, funct3 selects min(0)/max(1)
	.FMIN_S = { {.FMIN_S, {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x28000053, MASK_R, .F, {}} },
	.FMAX_S = { {.FMAX_S, {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x28001053, MASK_R, .F, {}} },

	// FP -> int convert: rs2 is the type selector
	.FCVT_W_S  = { {.FCVT_W_S,  {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xC0000053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .F, {fp_round=true}} },
	.FCVT_WU_S = { {.FCVT_WU_S, {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xC0100053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .F, {fp_round=true}} },
	.FCVT_L_S  = { {.FCVT_L_S,  {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xC0200053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .F, {fp_round=true, rv64_only=true}} },
	.FCVT_LU_S = { {.FCVT_LU_S, {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xC0300053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .F, {fp_round=true, rv64_only=true}} },

	// FP <- int convert
	.FCVT_S_W  = { {.FCVT_S_W,  {.FPR,.GPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xD0000053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .F, {fp_round=true}} },
	.FCVT_S_WU = { {.FCVT_S_WU, {.FPR,.GPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xD0100053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .F, {fp_round=true}} },
	.FCVT_S_L  = { {.FCVT_S_L,  {.FPR,.GPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xD0200053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .F, {fp_round=true, rv64_only=true}} },
	.FCVT_S_LU = { {.FCVT_S_LU, {.FPR,.GPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xD0300053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .F, {fp_round=true, rv64_only=true}} },

	// FMV / FCLASS: funct3 fixed (000 for FMV, 001 for FCLASS), rs2=0
	.FMV_X_W  = { {.FMV_X_W,  {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xE0000053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2 | MASK_FUNCT3, .F, {}} },
	.FMV_W_X  = { {.FMV_W_X,  {.FPR,.GPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xF0000053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2 | MASK_FUNCT3, .F, {}} },
	.FCLASS_S = { {.FCLASS_S, {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xE0001053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2 | MASK_FUNCT3, .F, {}} },

	// FP compare: funct7=0x50, funct3 selects EQ(2)/LT(1)/LE(0)
	.FEQ_S = { {.FEQ_S, {.GPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0xA0002053, MASK_R, .F, {}} },
	.FLT_S = { {.FLT_S, {.GPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0xA0001053, MASK_R, .F, {}} },
	.FLE_S = { {.FLE_S, {.GPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0xA0000053, MASK_R, .F, {}} },

	// =========================================================================
	// §6 D extension (double-precision)
	// =========================================================================
	//
	// Same pattern as F but funct7 low bit = 1 (fmt=01 = D).

	.FLD = { {.FLD, {.FPR,.MEM,.NONE,.NONE}, {.RD,.OFFSET_BASE_I,.NONE,.NONE}, 0x00003007, MASK_I, .D, {}} },
	.FSD = { {.FSD, {.FPR,.MEM,.NONE,.NONE}, {.RS2,.OFFSET_BASE_S,.NONE,.NONE}, 0x00003027, MASK_S, .D, {}} },

	.FMADD_D  = { {.FMADD_D,  {.FPR,.FPR,.FPR,.FPR}, {.RD,.RS1,.RS2,.RS3}, 0x02000043, 0x0600007F, .D, {fp_round=true}} },
	.FMSUB_D  = { {.FMSUB_D,  {.FPR,.FPR,.FPR,.FPR}, {.RD,.RS1,.RS2,.RS3}, 0x02000047, 0x0600007F, .D, {fp_round=true}} },
	.FNMSUB_D = { {.FNMSUB_D, {.FPR,.FPR,.FPR,.FPR}, {.RD,.RS1,.RS2,.RS3}, 0x0200004B, 0x0600007F, .D, {fp_round=true}} },
	.FNMADD_D = { {.FNMADD_D, {.FPR,.FPR,.FPR,.FPR}, {.RD,.RS1,.RS2,.RS3}, 0x0200004F, 0x0600007F, .D, {fp_round=true}} },

	.FADD_D  = { {.FADD_D,  {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x02000053, MASK_OPCODE | MASK_FUNCT7, .D, {fp_round=true}} },
	.FSUB_D  = { {.FSUB_D,  {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x0A000053, MASK_OPCODE | MASK_FUNCT7, .D, {fp_round=true}} },
	.FMUL_D  = { {.FMUL_D,  {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x12000053, MASK_OPCODE | MASK_FUNCT7, .D, {fp_round=true}} },
	.FDIV_D  = { {.FDIV_D,  {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x1A000053, MASK_OPCODE | MASK_FUNCT7, .D, {fp_round=true}} },
	.FSQRT_D = { {.FSQRT_D, {.FPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0x5A000053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .D, {fp_round=true}} },

	.FSGNJ_D  = { {.FSGNJ_D,  {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x22000053, MASK_R, .D, {}} },
	.FSGNJN_D = { {.FSGNJN_D, {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x22001053, MASK_R, .D, {}} },
	.FSGNJX_D = { {.FSGNJX_D, {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x22002053, MASK_R, .D, {}} },

	.FMIN_D = { {.FMIN_D, {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x2A000053, MASK_R, .D, {}} },
	.FMAX_D = { {.FMAX_D, {.FPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0x2A001053, MASK_R, .D, {}} },

	// FCVT between S and D
	.FCVT_S_D = { {.FCVT_S_D, {.FPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0x40100053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .D, {fp_round=true}} },
	.FCVT_D_S = { {.FCVT_D_S, {.FPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0x42000053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .D, {fp_round=true}} },

	// FP -> int (double-source)
	.FCVT_W_D  = { {.FCVT_W_D,  {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xC2000053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .D, {fp_round=true}} },
	.FCVT_WU_D = { {.FCVT_WU_D, {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xC2100053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .D, {fp_round=true}} },
	.FCVT_L_D  = { {.FCVT_L_D,  {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xC2200053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .D, {fp_round=true, rv64_only=true}} },
	.FCVT_LU_D = { {.FCVT_LU_D, {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xC2300053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .D, {fp_round=true, rv64_only=true}} },

	// FP <- int
	.FCVT_D_W  = { {.FCVT_D_W,  {.FPR,.GPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xD2000053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .D, {fp_round=true}} },
	.FCVT_D_WU = { {.FCVT_D_WU, {.FPR,.GPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xD2100053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .D, {fp_round=true}} },
	.FCVT_D_L  = { {.FCVT_D_L,  {.FPR,.GPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xD2200053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .D, {fp_round=true, rv64_only=true}} },
	.FCVT_D_LU = { {.FCVT_D_LU, {.FPR,.GPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xD2300053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2, .D, {fp_round=true, rv64_only=true}} },

	// FMV / FCLASS double
	.FMV_X_D  = { {.FMV_X_D,  {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xE2000053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2 | MASK_FUNCT3, .D, {rv64_only=true}} },
	.FMV_D_X  = { {.FMV_D_X,  {.FPR,.GPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xF2000053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2 | MASK_FUNCT3, .D, {rv64_only=true}} },
	.FCLASS_D = { {.FCLASS_D, {.GPR,.FPR,.NONE,.NONE}, {.RD,.RS1,.NONE,.NONE}, 0xE2001053, MASK_OPCODE | MASK_FUNCT7 | MASK_RS2 | MASK_FUNCT3, .D, {}} },

	// FP compare double
	.FEQ_D = { {.FEQ_D, {.GPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0xA2002053, MASK_R, .D, {}} },
	.FLT_D = { {.FLT_D, {.GPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0xA2001053, MASK_R, .D, {}} },
	.FLE_D = { {.FLE_D, {.GPR,.FPR,.FPR,.NONE}, {.RD,.RS1,.RS2,.NONE}, 0xA2000053, MASK_R, .D, {}} },

	// =========================================================================
	// C extension (16-bit compressed)
	// =========================================================================
	//
	// bits/mask use only the low 16 bits; the encoder writes 2 bytes for any
	// form whose (bits & 3) != 3. The constant-bit pattern places the C
	// dispatch fields (funct + op) in the low half-word.

	// ---- Quadrant 0 (op = 00) ----------------------------------------------

	// C.ADDI4SPN rd', sp, imm  =  000 imm[5:4] imm[9:6] imm[2] imm[3] rd' 00
	//   funct3=000, op=00 -> static bits 0x0000, mask covers funct3+op only
	//   so the imm fields and rd' are operand-driven.
	.C_ADDI4SPN = { {.C_ADDI4SPN, {.GPR_C, .GPR_SP, .IMM_C8U, .NONE}, {.C_RD_PRIMED, .NONE, .C_IMM_CIW, .NONE}, 0x0000, 0xE003, .C, {}} },

	// C.FLD rd', imm(rs1')   = 001 imm[5:3] rs1' imm[7:6] rd' 00     (D)
	.C_FLD = { {.C_FLD, {.FPR_C, .MEM_C_D, .NONE, .NONE}, {.C_RD_PRIMED, .C_OFFSET_BASE_D, .NONE, .NONE}, 0x2000, 0xE003, .D, {}} },

	// C.LW rd', imm(rs1')    = 010 imm[5:3] rs1' imm[2,6] rd' 00
	.C_LW  = { {.C_LW,  {.GPR_C, .MEM_C_W, .NONE, .NONE}, {.C_RD_PRIMED, .C_OFFSET_BASE_W, .NONE, .NONE}, 0x4000, 0xE003, .C, {}} },

	// C.LD rd', imm(rs1')    = 011 imm[5:3] rs1' imm[7:6] rd' 00     (RV64-only)
	.C_LD  = { {.C_LD,  {.GPR_C, .MEM_C_D, .NONE, .NONE}, {.C_RD_PRIMED, .C_OFFSET_BASE_D, .NONE, .NONE}, 0x6000, 0xE003, .C, {rv64_only=true}} },

	// C.FSD rs2', imm(rs1')  = 101 imm[5:3] rs1' imm[7:6] rs2' 00
	.C_FSD = { {.C_FSD, {.FPR_C, .MEM_C_D, .NONE, .NONE}, {.C_RS2_PRIMED, .C_OFFSET_BASE_D, .NONE, .NONE}, 0xA000, 0xE003, .D, {}} },

	// C.SW rs2', imm(rs1')   = 110 imm[5:3] rs1' imm[2,6] rs2' 00
	.C_SW  = { {.C_SW,  {.GPR_C, .MEM_C_W, .NONE, .NONE}, {.C_RS2_PRIMED, .C_OFFSET_BASE_W, .NONE, .NONE}, 0xC000, 0xE003, .C, {}} },

	// C.SD rs2', imm(rs1')   = 111 imm[5:3] rs1' imm[7:6] rs2' 00   (RV64-only)
	.C_SD  = { {.C_SD,  {.GPR_C, .MEM_C_D, .NONE, .NONE}, {.C_RS2_PRIMED, .C_OFFSET_BASE_D, .NONE, .NONE}, 0xE000, 0xE003, .C, {rv64_only=true}} },

	// ---- Quadrant 1 (op = 01) ----------------------------------------------

	// C.NOP = 0x0001 = C.ADDI x0, 0 (fully fixed encoding).
	.C_NOP = { {.C_NOP, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x0001, 0xFFFF, .C, {}} },

	// C.ADDI rd, imm  = 000 imm[5] rd!=0 imm[4:0] 01
	.C_ADDI = { {.C_ADDI, {.GPR_NONZERO, .IMM_C6S, .NONE, .NONE}, {.C_RD_RS1, .C_IMM_CI_S, .NONE, .NONE}, 0x0001, 0xE003, .C, {}} },

	// C.JAL imm     = 001 imm[11:1] 01   (RV32-only)
	.C_JAL = { {.C_JAL, {.REL12, .NONE, .NONE, .NONE}, {.C_BRANCH12, .NONE, .NONE, .NONE}, 0x2001, 0xE003, .C, {rv32_only=true, branch=true}} },

	// C.ADDIW rd, imm = 001 imm[5] rd!=0 imm[4:0] 01   (RV64-only)
	.C_ADDIW = { {.C_ADDIW, {.GPR_NONZERO, .IMM_C6S, .NONE, .NONE}, {.C_RD_RS1, .C_IMM_CI_S, .NONE, .NONE}, 0x2001, 0xE003, .C, {rv64_only=true}} },

	// C.LI rd, imm  = 010 imm[5] rd!=0 imm[4:0] 01
	.C_LI = { {.C_LI, {.GPR_NONZERO, .IMM_C6S, .NONE, .NONE}, {.C_RD_RS1, .C_IMM_CI_S, .NONE, .NONE}, 0x4001, 0xE003, .C, {}} },

	// C.ADDI16SP sp, imm    = 011 imm[9] 00010 imm[4,6,8:7,5] 01
	//   rd is fixed at 2 (sp); ensure the form discriminates by checking rd=2.
	.C_ADDI16SP = { {.C_ADDI16SP, {.GPR_SP, .IMM_C10S, .NONE, .NONE}, {.NONE, .C_IMM_ADDI16SP, .NONE, .NONE}, 0x6101, 0xEF83, .C, {}} },

	// C.LUI rd, imm  = 011 imm[17] rd!=0,2 imm[16:12] 01
	.C_LUI = { {.C_LUI, {.GPR_NONZERO, .IMM_C18S, .NONE, .NONE}, {.C_RD_RS1, .C_IMM_LUI, .NONE, .NONE}, 0x6001, 0xE003, .C, {}} },

	// C.SRLI rd', shamt  = 100 shamt[5] 00 rd' shamt[4:0] 01
	.C_SRLI = { {.C_SRLI, {.GPR_C, .IMM_C6U, .NONE, .NONE}, {.C_RD_RS1_PRIMED, .C_IMM_CI_U, .NONE, .NONE}, 0x8001, 0xEC03, .C, {}} },

	// C.SRAI rd', shamt  = 100 shamt[5] 01 rd' shamt[4:0] 01
	.C_SRAI = { {.C_SRAI, {.GPR_C, .IMM_C6U, .NONE, .NONE}, {.C_RD_RS1_PRIMED, .C_IMM_CI_U, .NONE, .NONE}, 0x8401, 0xEC03, .C, {}} },

	// C.ANDI rd', imm    = 100 imm[5] 10 rd' imm[4:0] 01
	.C_ANDI = { {.C_ANDI, {.GPR_C, .IMM_C6S, .NONE, .NONE}, {.C_RD_RS1_PRIMED, .C_IMM_CI_S, .NONE, .NONE}, 0x8801, 0xEC03, .C, {}} },

	// CA-format reg-reg (op=01, funct6=100011 / 100111 + funct2 picks op):
	//   C.SUB  rd', rs2' = 100011 rd' 00 rs2' 01
	//   C.XOR  rd', rs2' = 100011 rd' 01 rs2' 01
	//   C.OR   rd', rs2' = 100011 rd' 10 rs2' 01
	//   C.AND  rd', rs2' = 100011 rd' 11 rs2' 01
	//   C.SUBW rd', rs2' = 100111 rd' 00 rs2' 01   (RV64)
	//   C.ADDW rd', rs2' = 100111 rd' 01 rs2' 01   (RV64)
	.C_SUB  = { {.C_SUB,  {.GPR_C, .GPR_C, .NONE, .NONE}, {.C_RD_RS1_PRIMED, .C_RS2_PRIMED, .NONE, .NONE}, 0x8C01, 0xFC63, .C, {}} },
	.C_XOR  = { {.C_XOR,  {.GPR_C, .GPR_C, .NONE, .NONE}, {.C_RD_RS1_PRIMED, .C_RS2_PRIMED, .NONE, .NONE}, 0x8C21, 0xFC63, .C, {}} },
	.C_OR   = { {.C_OR,   {.GPR_C, .GPR_C, .NONE, .NONE}, {.C_RD_RS1_PRIMED, .C_RS2_PRIMED, .NONE, .NONE}, 0x8C41, 0xFC63, .C, {}} },
	.C_AND  = { {.C_AND,  {.GPR_C, .GPR_C, .NONE, .NONE}, {.C_RD_RS1_PRIMED, .C_RS2_PRIMED, .NONE, .NONE}, 0x8C61, 0xFC63, .C, {}} },
	.C_SUBW = { {.C_SUBW, {.GPR_C, .GPR_C, .NONE, .NONE}, {.C_RD_RS1_PRIMED, .C_RS2_PRIMED, .NONE, .NONE}, 0x9C01, 0xFC63, .C, {rv64_only=true}} },
	.C_ADDW = { {.C_ADDW, {.GPR_C, .GPR_C, .NONE, .NONE}, {.C_RD_RS1_PRIMED, .C_RS2_PRIMED, .NONE, .NONE}, 0x9C21, 0xFC63, .C, {rv64_only=true}} },

	// C.J offset = 101 offset[11:1] 01
	.C_J = { {.C_J, {.REL12, .NONE, .NONE, .NONE}, {.C_BRANCH12, .NONE, .NONE, .NONE}, 0xA001, 0xE003, .C, {branch=true}} },

	// C.BEQZ rs1', offset[8:1] = 110 offset[8,4:3] rs1' offset[7:6,2:1,5] 01
	.C_BEQZ = { {.C_BEQZ, {.GPR_C, .REL9, .NONE, .NONE}, {.C_RS1_PRIMED, .C_BRANCH9, .NONE, .NONE}, 0xC001, 0xE003, .C, {branch=true}} },
	// C.BNEZ rs1', offset[8:1] = 111 offset[8,4:3] rs1' offset[7:6,2:1,5] 01
	.C_BNEZ = { {.C_BNEZ, {.GPR_C, .REL9, .NONE, .NONE}, {.C_RS1_PRIMED, .C_BRANCH9, .NONE, .NONE}, 0xE001, 0xE003, .C, {branch=true}} },

	// ---- Quadrant 2 (op = 10) ----------------------------------------------

	// C.SLLI rd, shamt  = 000 shamt[5] rd!=0 shamt[4:0] 10
	.C_SLLI = { {.C_SLLI, {.GPR_NONZERO, .IMM_C6U, .NONE, .NONE}, {.C_RD_RS1, .C_IMM_CI_U, .NONE, .NONE}, 0x0002, 0xE003, .C, {}} },

	// C.FLDSP rd, imm   = 001 imm[5] rd imm[4:3,8:6] 10
	.C_FLDSP = { {.C_FLDSP, {.FPR, .MEM_C_SP_D, .NONE, .NONE}, {.C_RD_RS1, .C_SP_OFFSET_D, .NONE, .NONE}, 0x2002, 0xE003, .D, {}} },

	// C.LWSP rd, imm    = 010 imm[5] rd!=0 imm[4:2,7:6] 10
	.C_LWSP = { {.C_LWSP, {.GPR_NONZERO, .MEM_C_SP_W, .NONE, .NONE}, {.C_RD_RS1, .C_SP_OFFSET_W, .NONE, .NONE}, 0x4002, 0xE003, .C, {}} },

	// C.LDSP rd, imm    = 011 imm[5] rd!=0 imm[4:3,8:6] 10  (RV64)
	.C_LDSP = { {.C_LDSP, {.GPR_NONZERO, .MEM_C_SP_D, .NONE, .NONE}, {.C_RD_RS1, .C_SP_OFFSET_D, .NONE, .NONE}, 0x6002, 0xE003, .C, {rv64_only=true}} },

	// CR-format funct4=1000 / 1001 with rd!=0:
	//   C.JR rs1 = 1000 rs1!=0 00000 10           (rs2=0)
	//   C.MV rd, rs2 = 1000 rd!=0 rs2!=0 10
	//   C.EBREAK = 1001 00000 00000 10  (fully fixed 0x9002)
	//   C.JALR rs1 = 1001 rs1!=0 00000 10         (rs2=0)
	//   C.ADD rd, rs2 = 1001 rd!=0 rs2!=0 10
	.C_JR     = { {.C_JR,     {.GPR_NONZERO, .NONE, .NONE, .NONE}, {.C_RD_RS1, .NONE, .NONE, .NONE}, 0x8002, 0xF07F, .C, {branch=true}} },
	.C_MV     = { {.C_MV,     {.GPR_NONZERO, .GPR_NONZERO, .NONE, .NONE}, {.C_RD_RS1, .C_RS2, .NONE, .NONE}, 0x8002, 0xF003, .C, {}} },
	.C_EBREAK = { {.C_EBREAK, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0x9002, 0xFFFF, .C, {}} },
	.C_JALR   = { {.C_JALR,   {.GPR_NONZERO, .NONE, .NONE, .NONE}, {.C_RD_RS1, .NONE, .NONE, .NONE}, 0x9002, 0xF07F, .C, {branch=true}} },
	.C_ADD    = { {.C_ADD,    {.GPR_NONZERO, .GPR_NONZERO, .NONE, .NONE}, {.C_RD_RS1, .C_RS2, .NONE, .NONE}, 0x9002, 0xF003, .C, {}} },

	// C.FSDSP rs2, imm = 101 imm[5:3,8:6] rs2 10
	.C_FSDSP = { {.C_FSDSP, {.FPR, .MEM_C_SP_D, .NONE, .NONE}, {.C_RS2, .C_IMM_CSS_D, .NONE, .NONE}, 0xA002, 0xE003, .D, {}} },

	// C.SWSP rs2, imm  = 110 imm[5:2,7:6] rs2 10
	.C_SWSP = { {.C_SWSP, {.GPR, .MEM_C_SP_W, .NONE, .NONE}, {.C_RS2, .C_IMM_CSS_W, .NONE, .NONE}, 0xC002, 0xE003, .C, {}} },

	// C.SDSP rs2, imm  = 111 imm[5:3,8:6] rs2 10   (RV64)
	.C_SDSP = { {.C_SDSP, {.GPR, .MEM_C_SP_D, .NONE, .NONE}, {.C_RS2, .C_IMM_CSS_D, .NONE, .NONE}, 0xE002, 0xE003, .C, {rv64_only=true}} },
}
