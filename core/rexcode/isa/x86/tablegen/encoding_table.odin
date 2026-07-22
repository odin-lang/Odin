// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_x86_tablegen

// =============================================================================
// x86 ENCODING_TABLE
// =============================================================================
//
// Indexed by Mnemonic. Each entry is a slice of Encoding forms, one per
// operand-shape variant. Encoding shape: {mnemonic, ops[4], enc[4], opcode,
// ext, flags}. The matcher walks the slice and picks the first form whose
// Operand_Type list satisfies the user's Instruction operands.

@(rodata)
ENCODING_TABLE: [Mnemonic][]Encoding = {
	.INVALID = {},

	// -------------------------------------------------------------------------
	// SECTION: 8.1 Data Transfer Encodings
	// -------------------------------------------------------------------------
	.MOV = {
		{.MOV, {.RM8,      .R8,       .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x88, 0, {}},
		{.MOV, {.RM16,     .R16,      .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x89, 0, {}},
		{.MOV, {.RM32,     .R32,      .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x89, 0, {}},
		{.MOV, {.RM64,     .R64,      .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x89, 0, {force_rex_w=true}},
		{.MOV, {.R8,       .RM8,      .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x8A, 0, {}},
		{.MOV, {.R16,      .RM16,     .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x8B, 0, {}},
		{.MOV, {.R32,      .RM32,     .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x8B, 0, {}},
		{.MOV, {.R64,      .RM64,     .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x8B, 0, {force_rex_w=true}},
		{.MOV, {.R8,       .IMM8,     .NONE, .NONE}, {.OP_R, .IB,   .NONE, .NONE}, 0xB0, 0, {}},
		{.MOV, {.R16,      .IMM16,    .NONE, .NONE}, {.OP_R, .IW,   .NONE, .NONE}, 0xB8, 0, {}},
		{.MOV, {.R32,      .IMM32,    .NONE, .NONE}, {.OP_R, .ID,   .NONE, .NONE}, 0xB8, 0, {}},
		{.MOV, {.R64,      .IMM64,    .NONE, .NONE}, {.OP_R, .IQ,   .NONE, .NONE}, 0xB8, 0, {force_rex_w=true}},
		{.MOV, {.RM8,      .IMM8,     .NONE, .NONE}, {.MR,   .IB,   .NONE, .NONE}, 0xC6, 0, {modrm_reg_ext=true}},
		{.MOV, {.RM16,     .IMM16,    .NONE, .NONE}, {.MR,   .IW,   .NONE, .NONE}, 0xC7, 0, {modrm_reg_ext=true}},
		{.MOV, {.RM32,     .IMM32,    .NONE, .NONE}, {.MR,   .ID,   .NONE, .NONE}, 0xC7, 0, {modrm_reg_ext=true}},
		{.MOV, {.RM64,     .IMM32,    .NONE, .NONE}, {.MR,   .ID,   .NONE, .NONE}, 0xC7, 0, {modrm_reg_ext=true, force_rex_w=true}},
		{.MOV, {.AL_IMPL,  .MOFFS8,   .NONE, .NONE}, {.IMPL, .IQ,   .NONE, .NONE}, 0xA0, 0, {}},
		{.MOV, {.AX_IMPL,  .MOFFS16,  .NONE, .NONE}, {.IMPL, .IQ,   .NONE, .NONE}, 0xA1, 0, {}},
		{.MOV, {.EAX_IMPL, .MOFFS32,  .NONE, .NONE}, {.IMPL, .IQ,   .NONE, .NONE}, 0xA1, 0, {}},
		{.MOV, {.RAX_IMPL, .MOFFS64,  .NONE, .NONE}, {.IMPL, .IQ,   .NONE, .NONE}, 0xA1, 0, {force_rex_w=true}},
		{.MOV, {.MOFFS8,   .AL_IMPL,  .NONE, .NONE}, {.IQ,   .IMPL, .NONE, .NONE}, 0xA2, 0, {}},
		{.MOV, {.MOFFS16,  .AX_IMPL,  .NONE, .NONE}, {.IQ,   .IMPL, .NONE, .NONE}, 0xA3, 0, {}},
		{.MOV, {.MOFFS32,  .EAX_IMPL, .NONE, .NONE}, {.IQ,   .IMPL, .NONE, .NONE}, 0xA3, 0, {}},
		{.MOV, {.MOFFS64,  .RAX_IMPL, .NONE, .NONE}, {.IQ,   .IMPL, .NONE, .NONE}, 0xA3, 0, {force_rex_w=true}},
		{.MOV, {.RM16,     .SREG,     .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x8C, 0, {}},
		{.MOV, {.RM64,     .SREG,     .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x8C, 0, {force_rex_w=true}},
		{.MOV, {.SREG,     .RM16,     .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x8E, 0, {}},
		{.MOV, {.SREG,     .RM64,     .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x8E, 0, {force_rex_w=true}},
		{.MOV, {.R64,      .CR,       .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x20, 0, {esc=._0F}},
		{.MOV, {.CR,       .R64,      .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x22, 0, {esc=._0F}},
		{.MOV, {.R64,      .DR,       .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x21, 0, {esc=._0F}},
		{.MOV, {.DR,       .R64,      .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x23, 0, {esc=._0F}},
	},
	.MOVABS = {  // 64-bit immediate MOV (alias for MOV with 64-bit imm)
		{.MOVABS, {.R64,      .IMM64,    .NONE, .NONE}, {.OP_R, .IQ,   .NONE, .NONE}, 0xB8, 0, {force_rex_w=true}},
		{.MOVABS, {.AL_IMPL,  .MOFFS8,   .NONE, .NONE}, {.IMPL, .IQ,   .NONE, .NONE}, 0xA0, 0, {}},
		{.MOVABS, {.AX_IMPL,  .MOFFS16,  .NONE, .NONE}, {.IMPL, .IQ,   .NONE, .NONE}, 0xA1, 0, {}},
		{.MOVABS, {.EAX_IMPL, .MOFFS32,  .NONE, .NONE}, {.IMPL, .IQ,   .NONE, .NONE}, 0xA1, 0, {}},
		{.MOVABS, {.RAX_IMPL, .MOFFS64,  .NONE, .NONE}, {.IMPL, .IQ,   .NONE, .NONE}, 0xA1, 0, {force_rex_w=true}},
		{.MOVABS, {.MOFFS8,   .AL_IMPL,  .NONE, .NONE}, {.IQ,   .IMPL, .NONE, .NONE}, 0xA2, 0, {}},
		{.MOVABS, {.MOFFS16,  .AX_IMPL,  .NONE, .NONE}, {.IQ,   .IMPL, .NONE, .NONE}, 0xA3, 0, {}},
		{.MOVABS, {.MOFFS32,  .EAX_IMPL, .NONE, .NONE}, {.IQ,   .IMPL, .NONE, .NONE}, 0xA3, 0, {}},
		{.MOVABS, {.MOFFS64,  .RAX_IMPL, .NONE, .NONE}, {.IQ,   .IMPL, .NONE, .NONE}, 0xA3, 0, {force_rex_w=true}},
	},
	.MOVZX = {
		{.MOVZX, {.R16, .RM8,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xB6, 0, {esc=._0F}},
		{.MOVZX, {.R32, .RM8,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xB6, 0, {esc=._0F}},
		{.MOVZX, {.R64, .RM8,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xB6, 0, {esc=._0F, force_rex_w=true}},
		{.MOVZX, {.R32, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xB7, 0, {esc=._0F}},
		{.MOVZX, {.R64, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xB7, 0, {esc=._0F, force_rex_w=true}},
	},
	.MOVSX = {
		{.MOVSX, {.R16, .RM8,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xBE, 0, {esc=._0F}},
		{.MOVSX, {.R32, .RM8,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xBE, 0, {esc=._0F}},
		{.MOVSX, {.R64, .RM8,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xBE, 0, {esc=._0F, force_rex_w=true}},
		{.MOVSX, {.R32, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xBF, 0, {esc=._0F}},
		{.MOVSX, {.R64, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xBF, 0, {esc=._0F, force_rex_w=true}},
	},
	.MOVSXD = {
		{.MOVSXD, {.R64, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x63, 0, {force_rex_w=true}},
	},
	.XCHG = {
		{.XCHG, {.AX_IMPL,  .R16, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0x90, 0, {}},
		{.XCHG, {.EAX_IMPL, .R32, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0x90, 0, {}},
		{.XCHG, {.RAX_IMPL, .R64, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0x90, 0, {force_rex_w=true}},
		{.XCHG, {.RM8,      .R8,  .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x86, 0, {lock_ok=true}},
		{.XCHG, {.RM16,     .R16, .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x87, 0, {lock_ok=true}},
		{.XCHG, {.RM32,     .R32, .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x87, 0, {lock_ok=true}},
		{.XCHG, {.RM64,     .R64, .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x87, 0, {lock_ok=true, force_rex_w=true}},
	},
	.PUSH = {
		{.PUSH, {.R16,    .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0x50, 0, {}},
		{.PUSH, {.R64,    .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0x50, 0, {default_64=true}},
		{.PUSH, {.RM16,   .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xFF, 6, {modrm_reg_ext=true}},
		{.PUSH, {.RM64,   .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xFF, 6, {modrm_reg_ext=true, default_64=true}},
		{.PUSH, {.IMM8SX, .NONE, .NONE, .NONE}, {.IB,   .NONE, .NONE, .NONE}, 0x6A, 0, {}},
		{.PUSH, {.IMM16,  .NONE, .NONE, .NONE}, {.IW,   .NONE, .NONE, .NONE}, 0x68, 0, {}},
		{.PUSH, {.IMM32,  .NONE, .NONE, .NONE}, {.ID,   .NONE, .NONE, .NONE}, 0x68, 0, {}},
		{.PUSH, {.SREG,   .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0xA0, 0, {esc=._0F}},
		{.PUSH, {.SREG,   .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0xA8, 0, {esc=._0F}},
	},
	.POP = {
		{.POP, {.R16,  .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0x58, 0, {}},
		{.POP, {.R64,  .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0x58, 0, {default_64=true}},
		{.POP, {.RM16, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x8F, 0, {modrm_reg_ext=true}},
		{.POP, {.RM64, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x8F, 0, {modrm_reg_ext=true, default_64=true}},
		{.POP, {.SREG, .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0xA1, 0, {esc=._0F}},
		{.POP, {.SREG, .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0xA9, 0, {esc=._0F}},
	},
	.LEA = {
		{.LEA, {.R16, .M, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x8D, 0, {}},
		{.LEA, {.R32, .M, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x8D, 0, {}},
		{.LEA, {.R64, .M, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x8D, 0, {force_rex_w=true}},
	},

	// -------------------------------------------------------------------------
	// SECTION: 8.2 Arithmetic Encodings
	// -------------------------------------------------------------------------
	.ADD = {
		{.ADD, {.RM8,      .R8,     .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x00, 0, {lock_ok=true}},
		{.ADD, {.RM16,     .R16,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x01, 0, {lock_ok=true}},
		{.ADD, {.RM32,     .R32,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x01, 0, {lock_ok=true}},
		{.ADD, {.RM64,     .R64,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x01, 0, {lock_ok=true, force_rex_w=true}},
		{.ADD, {.R8,       .RM8,    .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x02, 0, {}},
		{.ADD, {.R16,      .RM16,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x03, 0, {}},
		{.ADD, {.R32,      .RM32,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x03, 0, {}},
		{.ADD, {.R64,      .RM64,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x03, 0, {force_rex_w=true}},
		{.ADD, {.AL_IMPL,  .IMM8,   .NONE, .NONE}, {.IMPL, .IB,  .NONE, .NONE}, 0x04, 0, {}},
		{.ADD, {.AX_IMPL,  .IMM16,  .NONE, .NONE}, {.IMPL, .IW,  .NONE, .NONE}, 0x05, 0, {}},
		{.ADD, {.EAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x05, 0, {}},
		{.ADD, {.RAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x05, 0, {force_rex_w=true}},
		{.ADD, {.RM8,      .IMM8,   .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x80, 0, {modrm_reg_ext=true, lock_ok=true}},
		{.ADD, {.RM16,     .IMM16,  .NONE, .NONE}, {.MR,   .IW,  .NONE, .NONE}, 0x81, 0, {modrm_reg_ext=true, lock_ok=true}},
		{.ADD, {.RM32,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 0, {modrm_reg_ext=true, lock_ok=true}},
		{.ADD, {.RM64,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 0, {modrm_reg_ext=true, lock_ok=true, force_rex_w=true}},
		{.ADD, {.RM16,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 0, {modrm_reg_ext=true, lock_ok=true}},
		{.ADD, {.RM32,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 0, {modrm_reg_ext=true, lock_ok=true}},
		{.ADD, {.RM64,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 0, {modrm_reg_ext=true, lock_ok=true, force_rex_w=true}},
	},
	.ADC = {
		{.ADC, {.RM8,      .R8,     .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x10, 0, {lock_ok=true}},
		{.ADC, {.RM16,     .R16,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x11, 0, {lock_ok=true}},
		{.ADC, {.RM32,     .R32,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x11, 0, {lock_ok=true}},
		{.ADC, {.RM64,     .R64,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x11, 0, {lock_ok=true, force_rex_w=true}},
		{.ADC, {.R8,       .RM8,    .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x12, 0, {}},
		{.ADC, {.R16,      .RM16,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x13, 0, {}},
		{.ADC, {.R32,      .RM32,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x13, 0, {}},
		{.ADC, {.R64,      .RM64,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x13, 0, {force_rex_w=true}},
		{.ADC, {.AL_IMPL,  .IMM8,   .NONE, .NONE}, {.IMPL, .IB,  .NONE, .NONE}, 0x14, 0, {}},
		{.ADC, {.AX_IMPL,  .IMM16,  .NONE, .NONE}, {.IMPL, .IW,  .NONE, .NONE}, 0x15, 0, {}},
		{.ADC, {.EAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x15, 0, {}},
		{.ADC, {.RAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x15, 0, {force_rex_w=true}},
		{.ADC, {.RM8,      .IMM8,   .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x80, 2, {modrm_reg_ext=true, lock_ok=true}},
		{.ADC, {.RM16,     .IMM16,  .NONE, .NONE}, {.MR,   .IW,  .NONE, .NONE}, 0x81, 2, {modrm_reg_ext=true, lock_ok=true}},
		{.ADC, {.RM32,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 2, {modrm_reg_ext=true, lock_ok=true}},
		{.ADC, {.RM64,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 2, {modrm_reg_ext=true, lock_ok=true, force_rex_w=true}},
		{.ADC, {.RM16,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 2, {modrm_reg_ext=true, lock_ok=true}},
		{.ADC, {.RM32,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 2, {modrm_reg_ext=true, lock_ok=true}},
		{.ADC, {.RM64,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 2, {modrm_reg_ext=true, lock_ok=true, force_rex_w=true}},
	},
	.SUB = {
		{.SUB, {.RM8,      .R8,     .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x28, 0, {lock_ok=true}},
		{.SUB, {.RM16,     .R16,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x29, 0, {lock_ok=true}},
		{.SUB, {.RM32,     .R32,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x29, 0, {lock_ok=true}},
		{.SUB, {.RM64,     .R64,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x29, 0, {lock_ok=true, force_rex_w=true}},
		{.SUB, {.R8,       .RM8,    .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x2A, 0, {}},
		{.SUB, {.R16,      .RM16,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x2B, 0, {}},
		{.SUB, {.R32,      .RM32,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x2B, 0, {}},
		{.SUB, {.R64,      .RM64,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x2B, 0, {force_rex_w=true}},
		{.SUB, {.AL_IMPL,  .IMM8,   .NONE, .NONE}, {.IMPL, .IB,  .NONE, .NONE}, 0x2C, 0, {}},
		{.SUB, {.AX_IMPL,  .IMM16,  .NONE, .NONE}, {.IMPL, .IW,  .NONE, .NONE}, 0x2D, 0, {}},
		{.SUB, {.EAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x2D, 0, {}},
		{.SUB, {.RAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x2D, 0, {force_rex_w=true}},
		{.SUB, {.RM8,      .IMM8,   .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x80, 5, {modrm_reg_ext=true, lock_ok=true}},
		{.SUB, {.RM16,     .IMM16,  .NONE, .NONE}, {.MR,   .IW,  .NONE, .NONE}, 0x81, 5, {modrm_reg_ext=true, lock_ok=true}},
		{.SUB, {.RM32,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 5, {modrm_reg_ext=true, lock_ok=true}},
		{.SUB, {.RM64,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 5, {modrm_reg_ext=true, lock_ok=true, force_rex_w=true}},
		{.SUB, {.RM16,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 5, {modrm_reg_ext=true, lock_ok=true}},
		{.SUB, {.RM32,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 5, {modrm_reg_ext=true, lock_ok=true}},
		{.SUB, {.RM64,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 5, {modrm_reg_ext=true, lock_ok=true, force_rex_w=true}},
	},
	.SBB = {
		{.SBB, {.RM8,      .R8,     .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x18, 0, {lock_ok=true}},
		{.SBB, {.RM16,     .R16,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x19, 0, {lock_ok=true}},
		{.SBB, {.RM32,     .R32,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x19, 0, {lock_ok=true}},
		{.SBB, {.RM64,     .R64,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x19, 0, {lock_ok=true, force_rex_w=true}},
		{.SBB, {.R8,       .RM8,    .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x1A, 0, {}},
		{.SBB, {.R16,      .RM16,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x1B, 0, {}},
		{.SBB, {.R32,      .RM32,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x1B, 0, {}},
		{.SBB, {.R64,      .RM64,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x1B, 0, {force_rex_w=true}},
		{.SBB, {.AL_IMPL,  .IMM8,   .NONE, .NONE}, {.IMPL, .IB,  .NONE, .NONE}, 0x1C, 0, {}},
		{.SBB, {.AX_IMPL,  .IMM16,  .NONE, .NONE}, {.IMPL, .IW,  .NONE, .NONE}, 0x1D, 0, {}},
		{.SBB, {.EAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x1D, 0, {}},
		{.SBB, {.RAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x1D, 0, {force_rex_w=true}},
		{.SBB, {.RM8,      .IMM8,   .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x80, 3, {modrm_reg_ext=true, lock_ok=true}},
		{.SBB, {.RM16,     .IMM16,  .NONE, .NONE}, {.MR,   .IW,  .NONE, .NONE}, 0x81, 3, {modrm_reg_ext=true, lock_ok=true}},
		{.SBB, {.RM32,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 3, {modrm_reg_ext=true, lock_ok=true}},
		{.SBB, {.RM64,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 3, {modrm_reg_ext=true, lock_ok=true, force_rex_w=true}},
		{.SBB, {.RM16,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 3, {modrm_reg_ext=true, lock_ok=true}},
		{.SBB, {.RM32,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 3, {modrm_reg_ext=true, lock_ok=true}},
		{.SBB, {.RM64,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 3, {modrm_reg_ext=true, lock_ok=true, force_rex_w=true}},
	},
	.MUL = {
		{.MUL, {.RM8,  .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF6, 4, {modrm_reg_ext=true}},
		{.MUL, {.RM16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 4, {modrm_reg_ext=true}},
		{.MUL, {.RM32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 4, {modrm_reg_ext=true}},
		{.MUL, {.RM64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 4, {modrm_reg_ext=true, force_rex_w=true}},
	},
	.IMUL = {
		{.IMUL, {.RM8,  .NONE, .NONE,   .NONE}, {.MR,  .NONE, .NONE, .NONE}, 0xF6, 5, {modrm_reg_ext=true}},
		{.IMUL, {.RM16, .NONE, .NONE,   .NONE}, {.MR,  .NONE, .NONE, .NONE}, 0xF7, 5, {modrm_reg_ext=true}},
		{.IMUL, {.RM32, .NONE, .NONE,   .NONE}, {.MR,  .NONE, .NONE, .NONE}, 0xF7, 5, {modrm_reg_ext=true}},
		{.IMUL, {.RM64, .NONE, .NONE,   .NONE}, {.MR,  .NONE, .NONE, .NONE}, 0xF7, 5, {modrm_reg_ext=true, force_rex_w=true}},
		{.IMUL, {.R16,  .RM16, .NONE,   .NONE}, {.REG, .MR,   .NONE, .NONE}, 0xAF, 0, {esc=._0F}},
		{.IMUL, {.R32,  .RM32, .NONE,   .NONE}, {.REG, .MR,   .NONE, .NONE}, 0xAF, 0, {esc=._0F}},
		{.IMUL, {.R64,  .RM64, .NONE,   .NONE}, {.REG, .MR,   .NONE, .NONE}, 0xAF, 0, {esc=._0F, force_rex_w=true}},
		{.IMUL, {.R16,  .RM16, .IMM8SX, .NONE}, {.REG, .MR,   .IB,   .NONE}, 0x6B, 0, {}},
		{.IMUL, {.R32,  .RM32, .IMM8SX, .NONE}, {.REG, .MR,   .IB,   .NONE}, 0x6B, 0, {}},
		{.IMUL, {.R64,  .RM64, .IMM8SX, .NONE}, {.REG, .MR,   .IB,   .NONE}, 0x6B, 0, {force_rex_w=true}},
		{.IMUL, {.R16,  .RM16, .IMM16,  .NONE}, {.REG, .MR,   .IW,   .NONE}, 0x69, 0, {}},
		{.IMUL, {.R32,  .RM32, .IMM32,  .NONE}, {.REG, .MR,   .ID,   .NONE}, 0x69, 0, {}},
		{.IMUL, {.R64,  .RM64, .IMM32,  .NONE}, {.REG, .MR,   .ID,   .NONE}, 0x69, 0, {force_rex_w=true}},
	},
	.DIV = {
		{.DIV, {.RM8,  .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF6, 6, {modrm_reg_ext=true}},
		{.DIV, {.RM16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 6, {modrm_reg_ext=true}},
		{.DIV, {.RM32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 6, {modrm_reg_ext=true}},
		{.DIV, {.RM64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 6, {modrm_reg_ext=true, force_rex_w=true}},
	},
	.IDIV = {
		{.IDIV, {.RM8,  .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF6, 7, {modrm_reg_ext=true}},
		{.IDIV, {.RM16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 7, {modrm_reg_ext=true}},
		{.IDIV, {.RM32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 7, {modrm_reg_ext=true}},
		{.IDIV, {.RM64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 7, {modrm_reg_ext=true, force_rex_w=true}},
	},
	.INC = {
		// i386 short forms (0x40+rd / 0x48+rd) -- 1 byte vs 2 bytes for FF /0.
		// These collide with REX in long mode so the matcher filters them
		// out when mode != _32 via mode_32_only. Listed first so the encoder
		// prefers them in i386.
		{.INC, {.R16,  .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0x40, 0, {mode_32_only=true}},
		{.INC, {.R32,  .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0x40, 0, {mode_32_only=true}},

		{.INC, {.RM8,  .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xFE, 0, {modrm_reg_ext=true, lock_ok=true}},
		{.INC, {.RM16, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xFF, 0, {modrm_reg_ext=true, lock_ok=true}},
		{.INC, {.RM32, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xFF, 0, {modrm_reg_ext=true, lock_ok=true}},
		{.INC, {.RM64, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xFF, 0, {modrm_reg_ext=true, lock_ok=true, force_rex_w=true}},
	},
	.DEC = {
		// i386 short forms -- see comment on .INC.
		{.DEC, {.R16,  .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0x48, 0, {mode_32_only=true}},
		{.DEC, {.R32,  .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0x48, 0, {mode_32_only=true}},

		{.DEC, {.RM8,  .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xFE, 1, {modrm_reg_ext=true, lock_ok=true}},
		{.DEC, {.RM16, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xFF, 1, {modrm_reg_ext=true, lock_ok=true}},
		{.DEC, {.RM32, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xFF, 1, {modrm_reg_ext=true, lock_ok=true}},
		{.DEC, {.RM64, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xFF, 1, {modrm_reg_ext=true, lock_ok=true, force_rex_w=true}},
	},
	.NEG = {
		{.NEG, {.RM8,  .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF6, 3, {modrm_reg_ext=true, lock_ok=true}},
		{.NEG, {.RM16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 3, {modrm_reg_ext=true, lock_ok=true}},
		{.NEG, {.RM32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 3, {modrm_reg_ext=true, lock_ok=true}},
		{.NEG, {.RM64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 3, {modrm_reg_ext=true, lock_ok=true, force_rex_w=true}},
	},
	.CMP = {
		{.CMP, {.RM8,      .R8,     .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x38, 0, {}},
		{.CMP, {.RM16,     .R16,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x39, 0, {}},
		{.CMP, {.RM32,     .R32,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x39, 0, {}},
		{.CMP, {.RM64,     .R64,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x39, 0, {force_rex_w=true}},
		{.CMP, {.R8,       .RM8,    .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x3A, 0, {}},
		{.CMP, {.R16,      .RM16,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x3B, 0, {}},
		{.CMP, {.R32,      .RM32,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x3B, 0, {}},
		{.CMP, {.R64,      .RM64,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x3B, 0, {force_rex_w=true}},
		{.CMP, {.AL_IMPL,  .IMM8,   .NONE, .NONE}, {.IMPL, .IB,  .NONE, .NONE}, 0x3C, 0, {}},
		{.CMP, {.AX_IMPL,  .IMM16,  .NONE, .NONE}, {.IMPL, .IW,  .NONE, .NONE}, 0x3D, 0, {}},
		{.CMP, {.EAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x3D, 0, {}},
		{.CMP, {.RAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x3D, 0, {force_rex_w=true}},
		{.CMP, {.RM8,      .IMM8,   .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x80, 7, {modrm_reg_ext=true}},
		{.CMP, {.RM16,     .IMM16,  .NONE, .NONE}, {.MR,   .IW,  .NONE, .NONE}, 0x81, 7, {modrm_reg_ext=true}},
		{.CMP, {.RM32,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 7, {modrm_reg_ext=true}},
		{.CMP, {.RM64,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 7, {modrm_reg_ext=true, force_rex_w=true}},
		{.CMP, {.RM16,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 7, {modrm_reg_ext=true}},
		{.CMP, {.RM32,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 7, {modrm_reg_ext=true}},
		{.CMP, {.RM64,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 7, {modrm_reg_ext=true, force_rex_w=true}},
	},

	// -------------------------------------------------------------------------
	// SECTION: 8.3 Logical Encodings
	// -------------------------------------------------------------------------
	.AND = {
		{.AND, {.RM8,      .R8,     .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x20, 0, {lock_ok=true}},
		{.AND, {.RM16,     .R16,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x21, 0, {lock_ok=true}},
		{.AND, {.RM32,     .R32,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x21, 0, {lock_ok=true}},
		{.AND, {.RM64,     .R64,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x21, 0, {lock_ok=true, force_rex_w=true}},
		{.AND, {.R8,       .RM8,    .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x22, 0, {}},
		{.AND, {.R16,      .RM16,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x23, 0, {}},
		{.AND, {.R32,      .RM32,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x23, 0, {}},
		{.AND, {.R64,      .RM64,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x23, 0, {force_rex_w=true}},
		{.AND, {.AL_IMPL,  .IMM8,   .NONE, .NONE}, {.IMPL, .IB,  .NONE, .NONE}, 0x24, 0, {}},
		{.AND, {.AX_IMPL,  .IMM16,  .NONE, .NONE}, {.IMPL, .IW,  .NONE, .NONE}, 0x25, 0, {}},
		{.AND, {.EAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x25, 0, {}},
		{.AND, {.RAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x25, 0, {force_rex_w=true}},
		{.AND, {.RM8,      .IMM8,   .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x80, 4, {modrm_reg_ext=true, lock_ok=true}},
		{.AND, {.RM16,     .IMM16,  .NONE, .NONE}, {.MR,   .IW,  .NONE, .NONE}, 0x81, 4, {modrm_reg_ext=true, lock_ok=true}},
		{.AND, {.RM32,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 4, {modrm_reg_ext=true, lock_ok=true}},
		{.AND, {.RM64,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 4, {modrm_reg_ext=true, lock_ok=true, force_rex_w=true}},
		{.AND, {.RM16,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 4, {modrm_reg_ext=true, lock_ok=true}},
		{.AND, {.RM32,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 4, {modrm_reg_ext=true, lock_ok=true}},
		{.AND, {.RM64,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 4, {modrm_reg_ext=true, lock_ok=true, force_rex_w=true}},
	},
	.OR = {
		{.OR, {.RM8,      .R8,     .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x08, 0, {lock_ok=true}},
		{.OR, {.RM16,     .R16,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x09, 0, {lock_ok=true}},
		{.OR, {.RM32,     .R32,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x09, 0, {lock_ok=true}},
		{.OR, {.RM64,     .R64,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x09, 0, {lock_ok=true, force_rex_w=true}},
		{.OR, {.R8,       .RM8,    .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x0A, 0, {}},
		{.OR, {.R16,      .RM16,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x0B, 0, {}},
		{.OR, {.R32,      .RM32,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x0B, 0, {}},
		{.OR, {.R64,      .RM64,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x0B, 0, {force_rex_w=true}},
		{.OR, {.AL_IMPL,  .IMM8,   .NONE, .NONE}, {.IMPL, .IB,  .NONE, .NONE}, 0x0C, 0, {}},
		{.OR, {.AX_IMPL,  .IMM16,  .NONE, .NONE}, {.IMPL, .IW,  .NONE, .NONE}, 0x0D, 0, {}},
		{.OR, {.EAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x0D, 0, {}},
		{.OR, {.RAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x0D, 0, {force_rex_w=true}},
		{.OR, {.RM8,      .IMM8,   .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x80, 1, {modrm_reg_ext=true, lock_ok=true}},
		{.OR, {.RM16,     .IMM16,  .NONE, .NONE}, {.MR,   .IW,  .NONE, .NONE}, 0x81, 1, {modrm_reg_ext=true, lock_ok=true}},
		{.OR, {.RM32,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 1, {modrm_reg_ext=true, lock_ok=true}},
		{.OR, {.RM64,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 1, {modrm_reg_ext=true, lock_ok=true, force_rex_w=true}},
		{.OR, {.RM16,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 1, {modrm_reg_ext=true, lock_ok=true}},
		{.OR, {.RM32,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 1, {modrm_reg_ext=true, lock_ok=true}},
		{.OR, {.RM64,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 1, {modrm_reg_ext=true, lock_ok=true, force_rex_w=true}},
	},
	.XOR = {
		{.XOR, {.RM8,      .R8,     .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x30, 0, {lock_ok=true}},
		{.XOR, {.RM16,     .R16,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x31, 0, {lock_ok=true}},
		{.XOR, {.RM32,     .R32,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x31, 0, {lock_ok=true}},
		{.XOR, {.RM64,     .R64,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x31, 0, {lock_ok=true, force_rex_w=true}},
		{.XOR, {.R8,       .RM8,    .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x32, 0, {}},
		{.XOR, {.R16,      .RM16,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x33, 0, {}},
		{.XOR, {.R32,      .RM32,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x33, 0, {}},
		{.XOR, {.R64,      .RM64,   .NONE, .NONE}, {.REG,  .MR,  .NONE, .NONE}, 0x33, 0, {force_rex_w=true}},
		{.XOR, {.AL_IMPL,  .IMM8,   .NONE, .NONE}, {.IMPL, .IB,  .NONE, .NONE}, 0x34, 0, {}},
		{.XOR, {.AX_IMPL,  .IMM16,  .NONE, .NONE}, {.IMPL, .IW,  .NONE, .NONE}, 0x35, 0, {}},
		{.XOR, {.EAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x35, 0, {}},
		{.XOR, {.RAX_IMPL, .IMM32,  .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0x35, 0, {force_rex_w=true}},
		{.XOR, {.RM8,      .IMM8,   .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x80, 6, {modrm_reg_ext=true, lock_ok=true}},
		{.XOR, {.RM16,     .IMM16,  .NONE, .NONE}, {.MR,   .IW,  .NONE, .NONE}, 0x81, 6, {modrm_reg_ext=true, lock_ok=true}},
		{.XOR, {.RM32,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 6, {modrm_reg_ext=true, lock_ok=true}},
		{.XOR, {.RM64,     .IMM32,  .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0x81, 6, {modrm_reg_ext=true, lock_ok=true, force_rex_w=true}},
		{.XOR, {.RM16,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 6, {modrm_reg_ext=true, lock_ok=true}},
		{.XOR, {.RM32,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 6, {modrm_reg_ext=true, lock_ok=true}},
		{.XOR, {.RM64,     .IMM8SX, .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0x83, 6, {modrm_reg_ext=true, lock_ok=true, force_rex_w=true}},
	},
	.NOT = {
		{.NOT, {.RM8,  .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF6, 2, {modrm_reg_ext=true, lock_ok=true}},
		{.NOT, {.RM16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 2, {modrm_reg_ext=true, lock_ok=true}},
		{.NOT, {.RM32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 2, {modrm_reg_ext=true, lock_ok=true}},
		{.NOT, {.RM64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xF7, 2, {modrm_reg_ext=true, lock_ok=true, force_rex_w=true}},
	},
	.TEST = {
		{.TEST, {.RM8,      .R8,    .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x84, 0, {}},
		{.TEST, {.RM16,     .R16,   .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x85, 0, {}},
		{.TEST, {.RM32,     .R32,   .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x85, 0, {}},
		{.TEST, {.RM64,     .R64,   .NONE, .NONE}, {.MR,   .REG, .NONE, .NONE}, 0x85, 0, {force_rex_w=true}},
		{.TEST, {.AL_IMPL,  .IMM8,  .NONE, .NONE}, {.IMPL, .IB,  .NONE, .NONE}, 0xA8, 0, {}},
		{.TEST, {.AX_IMPL,  .IMM16, .NONE, .NONE}, {.IMPL, .IW,  .NONE, .NONE}, 0xA9, 0, {}},
		{.TEST, {.EAX_IMPL, .IMM32, .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0xA9, 0, {}},
		{.TEST, {.RAX_IMPL, .IMM32, .NONE, .NONE}, {.IMPL, .ID,  .NONE, .NONE}, 0xA9, 0, {force_rex_w=true}},
		{.TEST, {.RM8,      .IMM8,  .NONE, .NONE}, {.MR,   .IB,  .NONE, .NONE}, 0xF6, 0, {modrm_reg_ext=true}},
		{.TEST, {.RM16,     .IMM16, .NONE, .NONE}, {.MR,   .IW,  .NONE, .NONE}, 0xF7, 0, {modrm_reg_ext=true}},
		{.TEST, {.RM32,     .IMM32, .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0xF7, 0, {modrm_reg_ext=true}},
		{.TEST, {.RM64,     .IMM32, .NONE, .NONE}, {.MR,   .ID,  .NONE, .NONE}, 0xF7, 0, {modrm_reg_ext=true, force_rex_w=true}},
	},

	// -------------------------------------------------------------------------
	// SECTION: 8.4 Shift/Rotate Encodings
	// -------------------------------------------------------------------------
	.SHL = {
		{.SHL, {.RM8,   .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD0, 4, {modrm_reg_ext=true}},
		{.SHL, {.RM8,   .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD2, 4, {modrm_reg_ext=true}},
		{.SHL, {.RM8,   .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC0, 4, {modrm_reg_ext=true}},
		{.SHL, {.RM16,  .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 4, {modrm_reg_ext=true}},
		{.SHL, {.RM16,  .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 4, {modrm_reg_ext=true}},
		{.SHL, {.RM16,  .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 4, {modrm_reg_ext=true}},
		{.SHL, {.RM32,  .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 4, {modrm_reg_ext=true}},
		{.SHL, {.RM32,  .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 4, {modrm_reg_ext=true}},
		{.SHL, {.RM32,  .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 4, {modrm_reg_ext=true}},
		{.SHL, {.RM64,  .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 4, {modrm_reg_ext=true, force_rex_w=true}},
		{.SHL, {.RM64,  .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 4, {modrm_reg_ext=true, force_rex_w=true}},
		{.SHL, {.RM64,  .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 4, {modrm_reg_ext=true, force_rex_w=true}},
	},
	.SHR = {
		{.SHR, {.RM8,   .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD0, 5, {modrm_reg_ext=true}},
		{.SHR, {.RM8,   .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD2, 5, {modrm_reg_ext=true}},
		{.SHR, {.RM8,   .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC0, 5, {modrm_reg_ext=true}},
		{.SHR, {.RM16,  .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 5, {modrm_reg_ext=true}},
		{.SHR, {.RM16,  .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 5, {modrm_reg_ext=true}},
		{.SHR, {.RM16,  .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 5, {modrm_reg_ext=true}},
		{.SHR, {.RM32,  .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 5, {modrm_reg_ext=true}},
		{.SHR, {.RM32,  .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 5, {modrm_reg_ext=true}},
		{.SHR, {.RM32,  .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 5, {modrm_reg_ext=true}},
		{.SHR, {.RM64,  .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 5, {modrm_reg_ext=true, force_rex_w=true}},
		{.SHR, {.RM64,  .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 5, {modrm_reg_ext=true, force_rex_w=true}},
		{.SHR, {.RM64,  .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 5, {modrm_reg_ext=true, force_rex_w=true}},
	},
	.SAR = {
		{.SAR, {.RM8,   .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD0, 7, {modrm_reg_ext=true}},
		{.SAR, {.RM8,   .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD2, 7, {modrm_reg_ext=true}},
		{.SAR, {.RM8,   .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC0, 7, {modrm_reg_ext=true}},
		{.SAR, {.RM16,  .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 7, {modrm_reg_ext=true}},
		{.SAR, {.RM16,  .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 7, {modrm_reg_ext=true}},
		{.SAR, {.RM16,  .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 7, {modrm_reg_ext=true}},
		{.SAR, {.RM32,  .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 7, {modrm_reg_ext=true}},
		{.SAR, {.RM32,  .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 7, {modrm_reg_ext=true}},
		{.SAR, {.RM32,  .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 7, {modrm_reg_ext=true}},
		{.SAR, {.RM64,  .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 7, {modrm_reg_ext=true, force_rex_w=true}},
		{.SAR, {.RM64,  .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 7, {modrm_reg_ext=true, force_rex_w=true}},
		{.SAR, {.RM64,  .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 7, {modrm_reg_ext=true, force_rex_w=true}},
	},
	.ROL = {
		{.ROL, {.RM8,   .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD0, 0, {modrm_reg_ext=true}},
		{.ROL, {.RM8,   .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD2, 0, {modrm_reg_ext=true}},
		{.ROL, {.RM8,   .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC0, 0, {modrm_reg_ext=true}},
		{.ROL, {.RM16,  .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 0, {modrm_reg_ext=true}},
		{.ROL, {.RM16,  .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 0, {modrm_reg_ext=true}},
		{.ROL, {.RM16,  .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 0, {modrm_reg_ext=true}},
		{.ROL, {.RM32,  .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 0, {modrm_reg_ext=true}},
		{.ROL, {.RM32,  .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 0, {modrm_reg_ext=true}},
		{.ROL, {.RM32,  .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 0, {modrm_reg_ext=true}},
		{.ROL, {.RM64,  .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 0, {modrm_reg_ext=true, force_rex_w=true}},
		{.ROL, {.RM64,  .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 0, {modrm_reg_ext=true, force_rex_w=true}},
		{.ROL, {.RM64,  .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 0, {modrm_reg_ext=true, force_rex_w=true}},
	},
	.ROR = {
		{.ROR, {.RM8,   .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD0, 1, {modrm_reg_ext=true}},
		{.ROR, {.RM8,   .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD2, 1, {modrm_reg_ext=true}},
		{.ROR, {.RM8,   .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC0, 1, {modrm_reg_ext=true}},
		{.ROR, {.RM16,  .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 1, {modrm_reg_ext=true}},
		{.ROR, {.RM16,  .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 1, {modrm_reg_ext=true}},
		{.ROR, {.RM16,  .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 1, {modrm_reg_ext=true}},
		{.ROR, {.RM32,  .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 1, {modrm_reg_ext=true}},
		{.ROR, {.RM32,  .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 1, {modrm_reg_ext=true}},
		{.ROR, {.RM32,  .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 1, {modrm_reg_ext=true}},
		{.ROR, {.RM64,  .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 1, {modrm_reg_ext=true, force_rex_w=true}},
		{.ROR, {.RM64,  .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 1, {modrm_reg_ext=true, force_rex_w=true}},
		{.ROR, {.RM64,  .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 1, {modrm_reg_ext=true, force_rex_w=true}},
	},
	.RCL = {
		{.RCL, {.RM8,   .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD0, 2, {modrm_reg_ext=true}},
		{.RCL, {.RM8,   .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD2, 2, {modrm_reg_ext=true}},
		{.RCL, {.RM8,   .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC0, 2, {modrm_reg_ext=true}},
		{.RCL, {.RM16,  .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 2, {modrm_reg_ext=true}},
		{.RCL, {.RM16,  .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 2, {modrm_reg_ext=true}},
		{.RCL, {.RM16,  .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 2, {modrm_reg_ext=true}},
		{.RCL, {.RM32,  .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 2, {modrm_reg_ext=true}},
		{.RCL, {.RM32,  .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 2, {modrm_reg_ext=true}},
		{.RCL, {.RM32,  .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 2, {modrm_reg_ext=true}},
		{.RCL, {.RM64,  .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 2, {modrm_reg_ext=true, force_rex_w=true}},
		{.RCL, {.RM64,  .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 2, {modrm_reg_ext=true, force_rex_w=true}},
		{.RCL, {.RM64,  .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 2, {modrm_reg_ext=true, force_rex_w=true}},
	},
	.RCR = {
		{.RCR, {.RM8,   .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD0, 3, {modrm_reg_ext=true}},
		{.RCR, {.RM8,   .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD2, 3, {modrm_reg_ext=true}},
		{.RCR, {.RM8,   .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC0, 3, {modrm_reg_ext=true}},
		{.RCR, {.RM16,  .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 3, {modrm_reg_ext=true}},
		{.RCR, {.RM16,  .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 3, {modrm_reg_ext=true}},
		{.RCR, {.RM16,  .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 3, {modrm_reg_ext=true}},
		{.RCR, {.RM32,  .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 3, {modrm_reg_ext=true}},
		{.RCR, {.RM32,  .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 3, {modrm_reg_ext=true}},
		{.RCR, {.RM32,  .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 3, {modrm_reg_ext=true}},
		{.RCR, {.RM64,  .ONE_IMPL, .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD1, 3, {modrm_reg_ext=true, force_rex_w=true}},
		{.RCR, {.RM64,  .CL_IMPL,  .NONE,    .NONE}, {.MR, .IMPL, .NONE, .NONE}, 0xD3, 3, {modrm_reg_ext=true, force_rex_w=true}},
		{.RCR, {.RM64,  .IMM8,     .NONE,    .NONE}, {.MR, .IB,   .NONE, .NONE}, 0xC1, 3, {modrm_reg_ext=true, force_rex_w=true}},
	},
	.SHLD = {
		{.SHLD, {.RM16, .R16,      .IMM8,    .NONE}, {.MR, .REG,  .IB,   .NONE}, 0xA4, 0, {esc=._0F}},
		{.SHLD, {.RM32, .R32,      .IMM8,    .NONE}, {.MR, .REG,  .IB,   .NONE}, 0xA4, 0, {esc=._0F}},
		{.SHLD, {.RM64, .R64,      .IMM8,    .NONE}, {.MR, .REG,  .IB,   .NONE}, 0xA4, 0, {esc=._0F, force_rex_w=true}},
		{.SHLD, {.RM16, .R16,      .CL_IMPL, .NONE}, {.MR, .REG,  .IMPL, .NONE}, 0xA5, 0, {esc=._0F}},
		{.SHLD, {.RM32, .R32,      .CL_IMPL, .NONE}, {.MR, .REG,  .IMPL, .NONE}, 0xA5, 0, {esc=._0F}},
		{.SHLD, {.RM64, .R64,      .CL_IMPL, .NONE}, {.MR, .REG,  .IMPL, .NONE}, 0xA5, 0, {esc=._0F, force_rex_w=true}},
	},
	.SHRD = {
		{.SHRD, {.RM16, .R16,      .IMM8,    .NONE}, {.MR, .REG,  .IB,   .NONE}, 0xAC, 0, {esc=._0F}},
		{.SHRD, {.RM32, .R32,      .IMM8,    .NONE}, {.MR, .REG,  .IB,   .NONE}, 0xAC, 0, {esc=._0F}},
		{.SHRD, {.RM64, .R64,      .IMM8,    .NONE}, {.MR, .REG,  .IB,   .NONE}, 0xAC, 0, {esc=._0F, force_rex_w=true}},
		{.SHRD, {.RM16, .R16,      .CL_IMPL, .NONE}, {.MR, .REG,  .IMPL, .NONE}, 0xAD, 0, {esc=._0F}},
		{.SHRD, {.RM32, .R32,      .CL_IMPL, .NONE}, {.MR, .REG,  .IMPL, .NONE}, 0xAD, 0, {esc=._0F}},
		{.SHRD, {.RM64, .R64,      .CL_IMPL, .NONE}, {.MR, .REG,  .IMPL, .NONE}, 0xAD, 0, {esc=._0F, force_rex_w=true}},
	},

	// -------------------------------------------------------------------------
	// SECTION: 8.5 Bit Operation Encodings
	// -------------------------------------------------------------------------
	.BT = {
		{.BT,     {.RM16, .R16,  .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0xA3, 0, {esc=._0F}},
		{.BT,     {.RM32, .R32,  .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0xA3, 0, {esc=._0F}},
		{.BT,     {.RM64, .R64,  .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0xA3, 0, {esc=._0F, force_rex_w=true}},
		{.BT,     {.RM16, .IMM8, .NONE, .NONE}, {.MR,  .IB,  .NONE, .NONE}, 0xBA, 4, {esc=._0F, modrm_reg_ext=true}},
		{.BT,     {.RM32, .IMM8, .NONE, .NONE}, {.MR,  .IB,  .NONE, .NONE}, 0xBA, 4, {esc=._0F, modrm_reg_ext=true}},
		{.BT,     {.RM64, .IMM8, .NONE, .NONE}, {.MR,  .IB,  .NONE, .NONE}, 0xBA, 4, {esc=._0F, modrm_reg_ext=true, force_rex_w=true}},
	},
	.BTS = {
		{.BTS,    {.RM16, .R16,  .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0xAB, 0, {esc=._0F, lock_ok=true}},
		{.BTS,    {.RM32, .R32,  .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0xAB, 0, {esc=._0F, lock_ok=true}},
		{.BTS,    {.RM64, .R64,  .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0xAB, 0, {esc=._0F, lock_ok=true, force_rex_w=true}},
		{.BTS,    {.RM16, .IMM8, .NONE, .NONE}, {.MR,  .IB,  .NONE, .NONE}, 0xBA, 5, {esc=._0F, modrm_reg_ext=true, lock_ok=true}},
		{.BTS,    {.RM32, .IMM8, .NONE, .NONE}, {.MR,  .IB,  .NONE, .NONE}, 0xBA, 5, {esc=._0F, modrm_reg_ext=true, lock_ok=true}},
		{.BTS,    {.RM64, .IMM8, .NONE, .NONE}, {.MR,  .IB,  .NONE, .NONE}, 0xBA, 5, {esc=._0F, modrm_reg_ext=true, lock_ok=true, force_rex_w=true}},
	},
	.BTR = {
		{.BTR,    {.RM16, .R16,  .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0xB3, 0, {esc=._0F, lock_ok=true}},
		{.BTR,    {.RM32, .R32,  .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0xB3, 0, {esc=._0F, lock_ok=true}},
		{.BTR,    {.RM64, .R64,  .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0xB3, 0, {esc=._0F, lock_ok=true, force_rex_w=true}},
		{.BTR,    {.RM16, .IMM8, .NONE, .NONE}, {.MR,  .IB,  .NONE, .NONE}, 0xBA, 6, {esc=._0F, modrm_reg_ext=true, lock_ok=true}},
		{.BTR,    {.RM32, .IMM8, .NONE, .NONE}, {.MR,  .IB,  .NONE, .NONE}, 0xBA, 6, {esc=._0F, modrm_reg_ext=true, lock_ok=true}},
		{.BTR,    {.RM64, .IMM8, .NONE, .NONE}, {.MR,  .IB,  .NONE, .NONE}, 0xBA, 6, {esc=._0F, modrm_reg_ext=true, lock_ok=true, force_rex_w=true}},
	},
	.BTC = {
		{.BTC,    {.RM16, .R16,  .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0xBB, 0, {esc=._0F, lock_ok=true}},
		{.BTC,    {.RM32, .R32,  .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0xBB, 0, {esc=._0F, lock_ok=true}},
		{.BTC,    {.RM64, .R64,  .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0xBB, 0, {esc=._0F, lock_ok=true, force_rex_w=true}},
		{.BTC,    {.RM16, .IMM8, .NONE, .NONE}, {.MR,  .IB,  .NONE, .NONE}, 0xBA, 7, {esc=._0F, modrm_reg_ext=true, lock_ok=true}},
		{.BTC,    {.RM32, .IMM8, .NONE, .NONE}, {.MR,  .IB,  .NONE, .NONE}, 0xBA, 7, {esc=._0F, modrm_reg_ext=true, lock_ok=true}},
		{.BTC,    {.RM64, .IMM8, .NONE, .NONE}, {.MR,  .IB,  .NONE, .NONE}, 0xBA, 7, {esc=._0F, modrm_reg_ext=true, lock_ok=true, force_rex_w=true}},
	},
	.BSF = {
		{.BSF,    {.R16,  .RM16, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0xBC, 0, {esc=._0F}},
		{.BSF,    {.R32,  .RM32, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0xBC, 0, {esc=._0F}},
		{.BSF,    {.R64,  .RM64, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0xBC, 0, {esc=._0F, force_rex_w=true}},
	},
	.BSR = {
		{.BSR,    {.R16,  .RM16, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0xBD, 0, {esc=._0F}},
		{.BSR,    {.R32,  .RM32, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0xBD, 0, {esc=._0F}},
		{.BSR,    {.R64,  .RM64, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0xBD, 0, {esc=._0F, force_rex_w=true}},
	},
	.POPCNT = {
		{.POPCNT, {.R16,  .RM16, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0xB8, 0, {esc=._0F, prefix=PREFIX_F3}},
		{.POPCNT, {.R32,  .RM32, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0xB8, 0, {esc=._0F, prefix=PREFIX_F3}},
		{.POPCNT, {.R64,  .RM64, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0xB8, 0, {esc=._0F, prefix=PREFIX_F3, force_rex_w=true}},
	},
	.LZCNT = {
		{.LZCNT,  {.R16,  .RM16, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0xBD, 0, {esc=._0F, prefix=PREFIX_F3}},
		{.LZCNT,  {.R32,  .RM32, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0xBD, 0, {esc=._0F, prefix=PREFIX_F3}},
		{.LZCNT,  {.R64,  .RM64, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0xBD, 0, {esc=._0F, prefix=PREFIX_F3, force_rex_w=true}},
	},
	.TZCNT = {
		{.TZCNT,  {.R16,  .RM16, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0xBC, 0, {esc=._0F, prefix=PREFIX_F3}},
		{.TZCNT,  {.R32,  .RM32, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0xBC, 0, {esc=._0F, prefix=PREFIX_F3}},
		{.TZCNT,  {.R64,  .RM64, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0xBC, 0, {esc=._0F, prefix=PREFIX_F3, force_rex_w=true}},
	},

	// -------------------------------------------------------------------------
	// SECTION: 8.6 Control Flow Encodings
	// -------------------------------------------------------------------------
	.JMP = {
		{.JMP, {.REL8,   .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0xEB, 0, {}},
		{.JMP, {.REL32,  .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0xE9, 0, {}},
		{.JMP, {.RM64,   .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xFF, 4, {modrm_reg_ext=true, default_64=true}},
		{.JMP, {.M16_16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xFF, 5, {modrm_reg_ext=true}},
		{.JMP, {.M16_32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xFF, 5, {modrm_reg_ext=true}},
		{.JMP, {.M16_64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xFF, 5, {modrm_reg_ext=true, force_rex_w=true}},
	},
	.JA = {
		{.JA,     {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x77, 0, {}},
		{.JA,     {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x87, 0, {esc=._0F}},
	},
	.JAE = {
		{.JAE,    {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x73, 0, {}},
		{.JAE,    {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x83, 0, {esc=._0F}},
	},
	.JB = {
		{.JB,     {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x72, 0, {}},
		{.JB,     {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x82, 0, {esc=._0F}},
	},
	.JBE = {
		{.JBE,    {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x76, 0, {}},
		{.JBE,    {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x86, 0, {esc=._0F}},
	},
	.JC = {  // Alias for JB (carry = below)
		{.JC,     {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x72, 0, {}},
		{.JC,     {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x82, 0, {esc=._0F}},
	},
	.JE = {
		{.JE,     {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x74, 0, {}},
		{.JE,     {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x84, 0, {esc=._0F}},
	},
	.JZ = {  // Alias for JE (zero = equal)
		{.JZ,     {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x74, 0, {}},
		{.JZ,     {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x84, 0, {esc=._0F}},
	},
	.JG = {
		{.JG,     {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7F, 0, {}},
		{.JG,     {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8F, 0, {esc=._0F}},
	},
	.JGE = {
		{.JGE,    {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7D, 0, {}},
		{.JGE,    {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8D, 0, {esc=._0F}},
	},
	.JL = {
		{.JL,     {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7C, 0, {}},
		{.JL,     {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8C, 0, {esc=._0F}},
	},
	.JLE = {
		{.JLE,    {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7E, 0, {}},
		{.JLE,    {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8E, 0, {esc=._0F}},
	},
	.JNA = {  // Alias for JBE (not above = below or equal)
		{.JNA,    {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x76, 0, {}},
		{.JNA,    {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x86, 0, {esc=._0F}},
	},
	.JNAE = {  // Alias for JB (not above or equal = below)
		{.JNAE,   {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x72, 0, {}},
		{.JNAE,   {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x82, 0, {esc=._0F}},
	},
	.JNB = {  // Alias for JAE (not below = above or equal)
		{.JNB,    {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x73, 0, {}},
		{.JNB,    {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x83, 0, {esc=._0F}},
	},
	.JNBE = {  // Alias for JA (not below or equal = above)
		{.JNBE,   {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x77, 0, {}},
		{.JNBE,   {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x87, 0, {esc=._0F}},
	},
	.JNC = {  // Alias for JAE (no carry = above or equal)
		{.JNC,    {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x73, 0, {}},
		{.JNC,    {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x83, 0, {esc=._0F}},
	},
	.JNE = {
		{.JNE,    {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x75, 0, {}},
		{.JNE,    {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x85, 0, {esc=._0F}},
	},
	.JNZ = {  // Alias for JNE (not zero = not equal)
		{.JNZ,    {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x75, 0, {}},
		{.JNZ,    {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x85, 0, {esc=._0F}},
	},
	.JNG = {  // Alias for JLE (not greater = less or equal)
		{.JNG,    {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7E, 0, {}},
		{.JNG,    {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8E, 0, {esc=._0F}},
	},
	.JNGE = {  // Alias for JL (not greater or equal = less)
		{.JNGE,   {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7C, 0, {}},
		{.JNGE,   {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8C, 0, {esc=._0F}},
	},
	.JNL = {  // Alias for JGE (not less = greater or equal)
		{.JNL,    {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7D, 0, {}},
		{.JNL,    {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8D, 0, {esc=._0F}},
	},
	.JNLE = {  // Alias for JG (not less or equal = greater)
		{.JNLE,   {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7F, 0, {}},
		{.JNLE,   {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8F, 0, {esc=._0F}},
	},
	.JNO = {
		{.JNO,    {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x71, 0, {}},
		{.JNO,    {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x81, 0, {esc=._0F}},
	},
	.JNP = {
		{.JNP,    {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7B, 0, {}},
		{.JNP,    {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8B, 0, {esc=._0F}},
	},
	.JNS = {
		{.JNS,    {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x79, 0, {}},
		{.JNS,    {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x89, 0, {esc=._0F}},
	},
	.JO = {
		{.JO,     {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x70, 0, {}},
		{.JO,     {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x80, 0, {esc=._0F}},
	},
	.JP = {
		{.JP,     {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7A, 0, {}},
		{.JP,     {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8A, 0, {esc=._0F}},
	},
	.JPE = {  // Alias for JP (parity even = parity)
		{.JPE,    {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7A, 0, {}},
		{.JPE,    {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8A, 0, {esc=._0F}},
	},
	.JPO = {  // Alias for JNP (parity odd = no parity)
		{.JPO,    {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x7B, 0, {}},
		{.JPO,    {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x8B, 0, {esc=._0F}},
	},
	.JS = {
		{.JS,     {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0x78, 0, {}},
		{.JS,     {.REL32, .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0x88, 0, {esc=._0F}},
	},
	.JCXZ = {  // Jump if CX is zero (16-bit mode) - needs address size override
		{.JCXZ,   {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0xE3, 0, {}},
	},
	.JECXZ = {  // Jump if ECX is zero (32-bit mode)
		{.JECXZ,  {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0xE3, 0, {}},
	},
	.JRCXZ = {  // Jump if RCX is zero (64-bit mode)
		{.JRCXZ,  {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0xE3, 0, {force_rex_w=true}},
	},
	.LOOP = {
		{.LOOP,   {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0xE2, 0, {}},
	},
	.LOOPE = {
		{.LOOPE,  {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0xE1, 0, {}},
	},
	.LOOPNE = {
		{.LOOPNE, {.REL8,  .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0xE0, 0, {}},
	},
	.CALL = {
		{.CALL, {.REL32,  .NONE, .NONE, .NONE}, {.ID, .NONE, .NONE, .NONE}, 0xE8, 0, {}},
		{.CALL, {.RM64,   .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xFF, 2, {modrm_reg_ext=true, default_64=true}},
		{.CALL, {.M16_16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xFF, 3, {modrm_reg_ext=true}},
		{.CALL, {.M16_32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xFF, 3, {modrm_reg_ext=true}},
		{.CALL, {.M16_64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xFF, 3, {modrm_reg_ext=true, force_rex_w=true}},
	},
	.RET = {
		{.RET, {.NONE,  .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xC3, 0, {}},
		{.RET, {.IMM16, .NONE, .NONE, .NONE}, {.IW  , .NONE, .NONE, .NONE}, 0xC2, 0, {}},
	},
	.IRET = {
		{.IRET, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xCF, 0, {opsize_16=true}},
	},
	.IRETD = {
		{.IRETD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xCF, 0, {}},
	},
	.IRETQ = {
		{.IRETQ, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xCF, 0, {force_rex_w=true}},
	},
	.INT = {
		{.INT, {.IMM8, .NONE, .NONE, .NONE}, {.IB, .NONE, .NONE, .NONE}, 0xCD, 0, {}},
	},
	.INT3 = {
		{.INT3, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xCC, 0, {}},
	},
	.INTO = {  // Interrupt on overflow (invalid in 64-bit mode)
		{.INTO, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xCE, 0, {}},
	},
	.SYSCALL = {
		{.SYSCALL, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x05, 0, {esc=._0F}},
	},
	.SYSRET = {
		{.SYSRET, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x07, 0, {esc=._0F}},
	},
	.SYSENTER = {
		{.SYSENTER, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x34, 0, {esc=._0F}},
	},
	.SYSEXIT = {
		{.SYSEXIT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x35, 0, {esc=._0F}},
	},

	// -------------------------------------------------------------------------
	// SECTION: 8.7 Conditional Set/Move Encodings
	// -------------------------------------------------------------------------
	.SETA = {
		{.SETA, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x97, 0, {esc=._0F}},
	},
	.SETAE = {
		{.SETAE, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x93, 0, {esc=._0F}},
	},
	.SETB = {
		{.SETB, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x92, 0, {esc=._0F}},
	},
	.SETBE = {
		{.SETBE, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x96, 0, {esc=._0F}},
	},
	.SETC = {  // Alias for SETB (carry = below)
		{.SETC, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x92, 0, {esc=._0F}},
	},
	.SETE = {
		{.SETE, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x94, 0, {esc=._0F}},
	},
	.SETG = {
		{.SETG, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9F, 0, {esc=._0F}},
	},
	.SETGE = {
		{.SETGE, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9D, 0, {esc=._0F}},
	},
	.SETL = {
		{.SETL, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9C, 0, {esc=._0F}},
	},
	.SETLE = {
		{.SETLE, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9E, 0, {esc=._0F}},
	},
	.SETNA = {  // Alias for SETBE
		{.SETNA, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x96, 0, {esc=._0F}},
	},
	.SETNAE = {  // Alias for SETB
		{.SETNAE, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x92, 0, {esc=._0F}},
	},
	.SETNB = {  // Alias for SETAE
		{.SETNB, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x93, 0, {esc=._0F}},
	},
	.SETNBE = {  // Alias for SETA
		{.SETNBE, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x97, 0, {esc=._0F}},
	},
	.SETNC = {  // Alias for SETAE
		{.SETNC, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x93, 0, {esc=._0F}},
	},
	.SETNE = {
		{.SETNE, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x95, 0, {esc=._0F}},
	},
	.SETNG = {  // Alias for SETLE
		{.SETNG, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9E, 0, {esc=._0F}},
	},
	.SETNGE = {  // Alias for SETL
		{.SETNGE, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9C, 0, {esc=._0F}},
	},
	.SETNL = {  // Alias for SETGE
		{.SETNL, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9D, 0, {esc=._0F}},
	},
	.SETNLE = {  // Alias for SETG
		{.SETNLE, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9F, 0, {esc=._0F}},
	},
	.SETNO = {
		{.SETNO, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x91, 0, {esc=._0F}},
	},
	.SETNP = {
		{.SETNP, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9B, 0, {esc=._0F}},
	},
	.SETNS = {
		{.SETNS, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x99, 0, {esc=._0F}},
	},
	.SETNZ = {  // Alias for SETNE
		{.SETNZ, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x95, 0, {esc=._0F}},
	},
	.SETO = {
		{.SETO, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x90, 0, {esc=._0F}},
	},
	.SETP = {
		{.SETP, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9A, 0, {esc=._0F}},
	},
	.SETPE = {  // Alias for SETP (parity even)
		{.SETPE, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9A, 0, {esc=._0F}},
	},
	.SETPO = {  // Alias for SETNP (parity odd)
		{.SETPO, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x9B, 0, {esc=._0F}},
	},
	.SETS = {
		{.SETS, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x98, 0, {esc=._0F}},
	},
	.SETZ = {  // Alias for SETE
		{.SETZ, {.RM8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x94, 0, {esc=._0F}},
	},
	.CMOVA = {
		{.CMOVA,   {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x47, 0, {esc=._0F}},
		{.CMOVA,   {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x47, 0, {esc=._0F}},
		{.CMOVA,   {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x47, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVAE = {
		{.CMOVAE,  {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x43, 0, {esc=._0F}},
		{.CMOVAE,  {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x43, 0, {esc=._0F}},
		{.CMOVAE,  {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x43, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVB = {
		{.CMOVB,   {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F}},
		{.CMOVB,   {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F}},
		{.CMOVB,   {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVBE = {
		{.CMOVBE,  {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x46, 0, {esc=._0F}},
		{.CMOVBE,  {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x46, 0, {esc=._0F}},
		{.CMOVBE,  {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x46, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVC = {  // Alias for CMOVB (carry = below)
		{.CMOVC,   {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F}},
		{.CMOVC,   {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F}},
		{.CMOVC,   {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVE = {
		{.CMOVE,   {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F}},
		{.CMOVE,   {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F}},
		{.CMOVE,   {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVG = {
		{.CMOVG,   {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4F, 0, {esc=._0F}},
		{.CMOVG,   {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4F, 0, {esc=._0F}},
		{.CMOVG,   {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4F, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVGE = {
		{.CMOVGE,  {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4D, 0, {esc=._0F}},
		{.CMOVGE,  {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4D, 0, {esc=._0F}},
		{.CMOVGE,  {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4D, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVL = {
		{.CMOVL,   {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F}},
		{.CMOVL,   {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F}},
		{.CMOVL,   {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVLE = {
		{.CMOVLE,  {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F}},
		{.CMOVLE,  {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F}},
		{.CMOVLE,  {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVNA = {  // Alias for CMOVBE
		{.CMOVNA,  {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x46, 0, {esc=._0F}},
		{.CMOVNA,  {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x46, 0, {esc=._0F}},
		{.CMOVNA,  {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x46, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVNAE = {  // Alias for CMOVB
		{.CMOVNAE, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F}},
		{.CMOVNAE, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F}},
		{.CMOVNAE, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVNB = {  // Alias for CMOVAE
		{.CMOVNB,  {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x43, 0, {esc=._0F}},
		{.CMOVNB,  {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x43, 0, {esc=._0F}},
		{.CMOVNB,  {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x43, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVNBE = {  // Alias for CMOVA
		{.CMOVNBE, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x47, 0, {esc=._0F}},
		{.CMOVNBE, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x47, 0, {esc=._0F}},
		{.CMOVNBE, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x47, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVNC = {  // Alias for CMOVAE
		{.CMOVNC,  {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x43, 0, {esc=._0F}},
		{.CMOVNC,  {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x43, 0, {esc=._0F}},
		{.CMOVNC,  {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x43, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVNE = {
		{.CMOVNE,  {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x45, 0, {esc=._0F}},
		{.CMOVNE,  {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x45, 0, {esc=._0F}},
		{.CMOVNE,  {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x45, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVNG = {  // Alias for CMOVLE
		{.CMOVNG,  {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F}},
		{.CMOVNG,  {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F}},
		{.CMOVNG,  {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVNGE = {  // Alias for CMOVL
		{.CMOVNGE, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F}},
		{.CMOVNGE, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F}},
		{.CMOVNGE, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVNL = {  // Alias for CMOVGE
		{.CMOVNL,  {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4D, 0, {esc=._0F}},
		{.CMOVNL,  {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4D, 0, {esc=._0F}},
		{.CMOVNL,  {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4D, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVNLE = {  // Alias for CMOVG
		{.CMOVNLE, {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4F, 0, {esc=._0F}},
		{.CMOVNLE, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4F, 0, {esc=._0F}},
		{.CMOVNLE, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4F, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVNO = {
		{.CMOVNO,  {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x41, 0, {esc=._0F}},
		{.CMOVNO,  {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x41, 0, {esc=._0F}},
		{.CMOVNO,  {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x41, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVNP = {
		{.CMOVNP,  {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4B, 0, {esc=._0F}},
		{.CMOVNP,  {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4B, 0, {esc=._0F}},
		{.CMOVNP,  {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4B, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVNS = {
		{.CMOVNS,  {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x49, 0, {esc=._0F}},
		{.CMOVNS,  {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x49, 0, {esc=._0F}},
		{.CMOVNS,  {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x49, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVNZ = {  // Alias for CMOVNE
		{.CMOVNZ,  {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x45, 0, {esc=._0F}},
		{.CMOVNZ,  {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x45, 0, {esc=._0F}},
		{.CMOVNZ,  {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x45, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVO = {
		{.CMOVO,   {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x40, 0, {esc=._0F}},
		{.CMOVO,   {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x40, 0, {esc=._0F}},
		{.CMOVO,   {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x40, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVP = {
		{.CMOVP,   {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4A, 0, {esc=._0F}},
		{.CMOVP,   {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4A, 0, {esc=._0F}},
		{.CMOVP,   {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4A, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVPE = {  // Alias for CMOVP (parity even)
		{.CMOVPE,  {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4A, 0, {esc=._0F}},
		{.CMOVPE,  {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4A, 0, {esc=._0F}},
		{.CMOVPE,  {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4A, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVPO = {  // Alias for CMOVNP (parity odd)
		{.CMOVPO,  {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4B, 0, {esc=._0F}},
		{.CMOVPO,  {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4B, 0, {esc=._0F}},
		{.CMOVPO,  {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4B, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVS = {
		{.CMOVS,   {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x48, 0, {esc=._0F}},
		{.CMOVS,   {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x48, 0, {esc=._0F}},
		{.CMOVS,   {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x48, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMOVZ = {  // Alias for CMOVE
		{.CMOVZ,   {.R16, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F}},
		{.CMOVZ,   {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F}},
		{.CMOVZ,   {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F, force_rex_w=true}},
	},

	// -------------------------------------------------------------------------
	// SECTION: 8.8 String Operation Encodings
	// -------------------------------------------------------------------------
	.MOVS = {  // Generic form, needs size suffix
		{.MOVS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA4, 0, {rep_ok=true}},
	},
	.MOVSB = {
		{.MOVSB, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA4, 0, {rep_ok=true}},
	},
	.MOVSW = {
		{.MOVSW, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA5, 0, {rep_ok=true, opsize_16=true}},
	},
	.MOVSD = {
		{.MOVSD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA5, 0, {rep_ok=true}},
	},
	.MOVSQ = {
		{.MOVSQ, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA5, 0, {rep_ok=true, force_rex_w=true}},
	},
	.CMPS = {  // Generic form
		{.CMPS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA6, 0, {rep_ok=true}},
	},
	.CMPSB = {
		{.CMPSB, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA6, 0, {rep_ok=true}},
	},
	.CMPSW = {
		{.CMPSW, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA7, 0, {rep_ok=true, opsize_16=true}},
	},
	.CMPSD = {
		{.CMPSD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA7, 0, {rep_ok=true}},
	},
	.CMPSQ = {
		{.CMPSQ, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA7, 0, {rep_ok=true, force_rex_w=true}},
	},
	.SCAS = {  // Generic form
		{.SCAS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAE, 0, {rep_ok=true}},
	},
	.SCASB = {
		{.SCASB, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAE, 0, {rep_ok=true}},
	},
	.SCASW = {
		{.SCASW, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAF, 0, {rep_ok=true, opsize_16=true}},
	},
	.SCASD = {
		{.SCASD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAF, 0, {rep_ok=true}},
	},
	.SCASQ = {
		{.SCASQ, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAF, 0, {rep_ok=true, force_rex_w=true}},
	},
	.LODS = {  // Generic form
		{.LODS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAC, 0, {rep_ok=true}},
	},
	.LODSB = {
		{.LODSB, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAC, 0, {rep_ok=true}},
	},
	.LODSW = {
		{.LODSW, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAD, 0, {rep_ok=true, opsize_16=true}},
	},
	.LODSD = {
		{.LODSD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAD, 0, {rep_ok=true}},
	},
	.LODSQ = {
		{.LODSQ, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAD, 0, {rep_ok=true, force_rex_w=true}},
	},
	.STOS = {  // Generic form
		{.STOS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAA, 0, {rep_ok=true}},
	},
	.STOSB = {
		{.STOSB, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAA, 0, {rep_ok=true}},
	},
	.STOSW = {
		{.STOSW, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAB, 0, {rep_ok=true, opsize_16=true}},
	},
	.STOSD = {
		{.STOSD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAB, 0, {rep_ok=true}},
	},
	.STOSQ = {
		{.STOSQ, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAB, 0, {rep_ok=true, force_rex_w=true}},
	},

	// -------------------------------------------------------------------------
	// SECTION: 8.9 Flag Operation Encodings
	// -------------------------------------------------------------------------
	.CLC = {
		{.CLC,    {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF8, 0, {}},
	},
	.STC = {
		{.STC,    {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF9, 0, {}},
	},
	.CMC = {
		{.CMC,    {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF5, 0, {}},
	},
	.CLD = {
		{.CLD,    {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xFC, 0, {}},
	},
	.STD = {
		{.STD,    {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xFD, 0, {}},
	},
	.CLI = {
		{.CLI,    {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xFA, 0, {}},
	},
	.STI = {
		{.STI,    {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xFB, 0, {}},
	},
	.LAHF = {
		{.LAHF,   {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9F, 0, {}},
	},
	.SAHF = {
		{.SAHF,   {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9E, 0, {}},
	},
	.PUSHF = {
		{.PUSHF,  {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9C, 0, {opsize_16=true}},
	},
	.PUSHFD = {
		{.PUSHFD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9C, 0, {}},
	},
	.PUSHFQ = {
		{.PUSHFQ, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9C, 0, {default_64=true}},
	},
	.POPF = {
		{.POPF,   {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9D, 0, {opsize_16=true}},
	},
	.POPFD = {
		{.POPFD,  {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9D, 0, {}},
	},
	.POPFQ = {
		{.POPFQ,  {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9D, 0, {default_64=true}},
	},

	// -------------------------------------------------------------------------
	// SECTION: 8.10 Miscellaneous Encodings
	// -------------------------------------------------------------------------
	.NOP = {
		{.NOP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x90, 0, {}},
		{.NOP, {.RM16, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x1F, 0, {esc=._0F, modrm_reg_ext=true}},
		{.NOP, {.RM32, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x1F, 0, {esc=._0F, modrm_reg_ext=true}},
		{.NOP, {.RM64, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x1F, 0, {esc=._0F, modrm_reg_ext=true, force_rex_w=true}},
	},
	.HLT = {
		{.HLT,    {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF4, 0, {}},
	},
	.WAIT = {  // Also known as FWAIT
		{.WAIT,   {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9B, 0, {}},
	},
	.LOCK = {  // LOCK prefix
		{.LOCK,   {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF0, 0, {}},
	},
	.UD0 = {
		{.UD0,    {.R32,  .RM32, .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0xFF, 0, {esc=._0F}},
	},
	.UD1 = {
		{.UD1,    {.R32,  .RM32, .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0xB9, 0, {esc=._0F}},
	},
	.UD2 = {
		{.UD2,    {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x0B, 0, {esc=._0F}},
	},
	.CPUID = {
		{.CPUID,  {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA2, 0, {esc=._0F}},
	},
	.RDTSC = {
		{.RDTSC,  {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x31, 0, {esc=._0F}},
	},
	.RDTSCP = {  // 0F 01 F9
		{.RDTSCP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xF9, {esc=._0F}},
	},
	.RDPMC = {
		{.RDPMC,  {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x33, 0, {esc=._0F}},
	},
	.XGETBV = {  // 0F 01 D0
		{.XGETBV, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xD0, {esc=._0F}},
	},
	.XSETBV = {  // 0F 01 D1
		{.XSETBV, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xD1, {esc=._0F}},
	},
	.CBW = {
		{.CBW,    {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x98, 0, {opsize_16=true}},
	},
	.CWDE = {
		{.CWDE,   {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x98, 0, {}},
	},
	.CDQE = {
		{.CDQE,   {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x98, 0, {force_rex_w=true}},
	},
	.CWD = {
		{.CWD,    {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x99, 0, {opsize_16=true}},
	},
	.CDQ = {
		{.CDQ,    {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x99, 0, {}},
	},
	.CQO = {
		{.CQO,    {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x99, 0, {force_rex_w=true}},
	},

	// -------------------------------------------------------------------------
	// SECTION: 8.11 BMI/ADX Encodings
	// -------------------------------------------------------------------------
	.ANDN = {
		{.ANDN,   {.R32, .R32,  .RM32, .NONE}, {.REG,  .VVVV, .MR,   .NONE}, 0xF2, 0, {esc=._0F38, vex_type=.VEX, vex_w=.W0, vex_l=.L0}},
		{.ANDN,   {.R64, .R64,  .RM64, .NONE}, {.REG,  .VVVV, .MR,   .NONE}, 0xF2, 0, {esc=._0F38, vex_type=.VEX, vex_w=.W1, vex_l=.L0}},
	},
	.BEXTR = {
		{.BEXTR,  {.R32, .RM32, .R32,  .NONE}, {.REG,  .MR,   .VVVV, .NONE}, 0xF7, 0, {esc=._0F38, vex_type=.VEX, vex_w=.W0, vex_l=.L0}},
		{.BEXTR,  {.R64, .RM64, .R64,  .NONE}, {.REG,  .MR,   .VVVV, .NONE}, 0xF7, 0, {esc=._0F38, vex_type=.VEX, vex_w=.W1, vex_l=.L0}},
	},
	.BLSI = {
		{.BLSI,   {.R32, .RM32, .NONE, .NONE}, {.VVVV, .MR,   .NONE, .NONE}, 0xF3, 3, {esc=._0F38, vex_type=.VEX, vex_w=.W0, vex_l=.L0, modrm_reg_ext=true}},
		{.BLSI,   {.R64, .RM64, .NONE, .NONE}, {.VVVV, .MR,   .NONE, .NONE}, 0xF3, 3, {esc=._0F38, vex_type=.VEX, vex_w=.W1, vex_l=.L0, modrm_reg_ext=true}},
	},
	.BLSMSK = {
		{.BLSMSK, {.R32, .RM32, .NONE, .NONE}, {.VVVV, .MR,   .NONE, .NONE}, 0xF3, 2, {esc=._0F38, vex_type=.VEX, vex_w=.W0, vex_l=.L0, modrm_reg_ext=true}},
		{.BLSMSK, {.R64, .RM64, .NONE, .NONE}, {.VVVV, .MR,   .NONE, .NONE}, 0xF3, 2, {esc=._0F38, vex_type=.VEX, vex_w=.W1, vex_l=.L0, modrm_reg_ext=true}},
	},
	.BLSR = {
		{.BLSR,   {.R32, .RM32, .NONE, .NONE}, {.VVVV, .MR,   .NONE, .NONE}, 0xF3, 1, {esc=._0F38, vex_type=.VEX, vex_w=.W0, vex_l=.L0, modrm_reg_ext=true}},
		{.BLSR,   {.R64, .RM64, .NONE, .NONE}, {.VVVV, .MR,   .NONE, .NONE}, 0xF3, 1, {esc=._0F38, vex_type=.VEX, vex_w=.W1, vex_l=.L0, modrm_reg_ext=true}},
	},
	.BZHI = {
		{.BZHI,   {.R32, .RM32, .R32,  .NONE}, {.REG,  .MR,   .VVVV, .NONE}, 0xF5, 0, {esc=._0F38, vex_type=.VEX, vex_w=.W0, vex_l=.L0}},
		{.BZHI,   {.R64, .RM64, .R64,  .NONE}, {.REG,  .MR,   .VVVV, .NONE}, 0xF5, 0, {esc=._0F38, vex_type=.VEX, vex_w=.W1, vex_l=.L0}},
	},
	.PDEP = {
		{.PDEP,   {.R32, .R32,  .RM32, .NONE}, {.REG,  .VVVV, .MR,   .NONE}, 0xF5, 0, {esc=._0F38, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W0, vex_l=.L0}},
		{.PDEP,   {.R64, .R64,  .RM64, .NONE}, {.REG,  .VVVV, .MR,   .NONE}, 0xF5, 0, {esc=._0F38, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W1, vex_l=.L0}},
	},
	.PEXT = {
		{.PEXT,   {.R32, .R32,  .RM32, .NONE}, {.REG,  .VVVV, .MR,   .NONE}, 0xF5, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.VEX, vex_w=.W0, vex_l=.L0}},
		{.PEXT,   {.R64, .R64,  .RM64, .NONE}, {.REG,  .VVVV, .MR,   .NONE}, 0xF5, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.VEX, vex_w=.W1, vex_l=.L0}},
	},
	.RORX = {
		{.RORX,   {.R32, .RM32, .IMM8, .NONE}, {.REG,  .MR,   .IB,   .NONE}, 0xF0, 0, {esc=._0F3A, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W0, vex_l=.L0}},
		{.RORX,   {.R64, .RM64, .IMM8, .NONE}, {.REG,  .MR,   .IB,   .NONE}, 0xF0, 0, {esc=._0F3A, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W1, vex_l=.L0}},
	},
	.SARX = {
		{.SARX,   {.R32, .RM32, .R32,  .NONE}, {.REG,  .MR,   .VVVV, .NONE}, 0xF7, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.VEX, vex_w=.W0, vex_l=.L0}},
		{.SARX,   {.R64, .RM64, .R64,  .NONE}, {.REG,  .MR,   .VVVV, .NONE}, 0xF7, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.VEX, vex_w=.W1, vex_l=.L0}},
	},
	.SHLX = {
		{.SHLX,   {.R32, .RM32, .R32,  .NONE}, {.REG,  .MR,   .VVVV, .NONE}, 0xF7, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W0, vex_l=.L0}},
		{.SHLX,   {.R64, .RM64, .R64,  .NONE}, {.REG,  .MR,   .VVVV, .NONE}, 0xF7, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_w=.W1, vex_l=.L0}},
	},
	.SHRX = {
		{.SHRX,   {.R32, .RM32, .R32,  .NONE}, {.REG,  .MR,   .VVVV, .NONE}, 0xF7, 0, {esc=._0F38, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W0, vex_l=.L0}},
		{.SHRX,   {.R64, .RM64, .R64,  .NONE}, {.REG,  .MR,   .VVVV, .NONE}, 0xF7, 0, {esc=._0F38, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W1, vex_l=.L0}},
	},
	.MULX = {
		{.MULX,   {.R32, .R32,  .RM32, .NONE}, {.REG,  .VVVV, .MR,   .NONE}, 0xF6, 0, {esc=._0F38, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W0, vex_l=.L0}},
		{.MULX,   {.R64, .R64,  .RM64, .NONE}, {.REG,  .VVVV, .MR,   .NONE}, 0xF6, 0, {esc=._0F38, prefix=PREFIX_F2, vex_type=.VEX, vex_w=.W1, vex_l=.L0}},
	},
	.ADCX = {
		{.ADCX,   {.R32, .RM32, .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0xF6, 0, {esc=._0F38, prefix=PREFIX_66}},
		{.ADCX,   {.R64, .RM64, .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0xF6, 0, {esc=._0F38, prefix=PREFIX_66, force_rex_w=true}},
	},
	.ADOX = {
		{.ADOX,   {.R32, .RM32, .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0xF6, 0, {esc=._0F38, prefix=PREFIX_F3}},
		{.ADOX,   {.R64, .RM64, .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0xF6, 0, {esc=._0F38, prefix=PREFIX_F3, force_rex_w=true}},
	},

	// -------------------------------------------------------------------------
	// SECTION: 8.12 SSE Encodings
	// -------------------------------------------------------------------------
	.MOVAPS = {
		{.MOVAPS,    {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x28, 0, {esc=._0F}},
		{.MOVAPS,    {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x29, 0, {esc=._0F}},
	},
	.MOVUPS = {
		{.MOVUPS,    {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x10, 0, {esc=._0F}},
		{.MOVUPS,    {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x11, 0, {esc=._0F}},
	},
	.MOVAPD = {
		{.MOVAPD,    {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x28, 0, {esc=._0F, prefix=PREFIX_66}},
		{.MOVAPD,    {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x29, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.MOVUPD = {
		{.MOVUPD,    {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x10, 0, {esc=._0F, prefix=PREFIX_66}},
		{.MOVUPD,    {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x11, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.MOVSS = {
		{.MOVSS,     {.XMM,      .XMM_M32,  .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x10, 0, {esc=._0F, prefix=PREFIX_F3}},
		{.MOVSS,     {.XMM_M32,  .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x11, 0, {esc=._0F, prefix=PREFIX_F3}},
	},
	.MOVSD_SSE = {
		{.MOVSD_SSE, {.XMM,      .XMM_M64,  .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x10, 0, {esc=._0F, prefix=PREFIX_F2}},
		{.MOVSD_SSE, {.XMM_M64,  .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x11, 0, {esc=._0F, prefix=PREFIX_F2}},
	},
	.MOVDQA = {
		{.MOVDQA,    {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_66}},
		{.MOVDQA,    {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.MOVDQU = {
		{.MOVDQU,    {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F3}},
		{.MOVDQU,    {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F3}},
	},
	.MOVQ = {
		{.MOVQ,      {.XMM,      .XMM_M64,  .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x7E, 0, {esc=._0F, prefix=PREFIX_F3}},
		{.MOVQ,      {.XMM_M64,  .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0xD6, 0, {esc=._0F, prefix=PREFIX_66}},
		{.MOVQ,      {.MM,       .MM_M64,   .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F}},
		{.MOVQ,      {.MM_M64,   .MM,       .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F}},
		{.MOVQ,      {.R64,      .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7E, 0, {esc=._0F, prefix=PREFIX_66, force_rex_w=true}},
		{.MOVQ,      {.XMM,      .R64,      .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6E, 0, {esc=._0F, prefix=PREFIX_66, force_rex_w=true}},
	},
	.MOVD = {
		{.MOVD,      {.XMM,      .RM32,     .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6E, 0, {esc=._0F, prefix=PREFIX_66}},
		{.MOVD,      {.RM32,     .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7E, 0, {esc=._0F, prefix=PREFIX_66}},
		{.MOVD,      {.MM,       .RM32,     .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6E, 0, {esc=._0F}},
		{.MOVD,      {.RM32,     .MM,       .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7E, 0, {esc=._0F}},
	},
	.MOVLPS = {
		{.MOVLPS,    {.XMM,      .M64,      .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x12, 0, {esc=._0F}},
		{.MOVLPS,    {.M64,      .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x13, 0, {esc=._0F}},
	},
	.MOVHPS = {
		{.MOVHPS,    {.XMM,      .M64,      .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x16, 0, {esc=._0F}},
		{.MOVHPS,    {.M64,      .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x17, 0, {esc=._0F}},
	},
	.MOVLPD = {
		{.MOVLPD,    {.XMM,      .M64,      .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x12, 0, {esc=._0F, prefix=PREFIX_66}},
		{.MOVLPD,    {.M64,      .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x13, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.MOVHPD = {
		{.MOVHPD,    {.XMM,      .M64,      .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x16, 0, {esc=._0F, prefix=PREFIX_66}},
		{.MOVHPD,    {.M64,      .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x17, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.MOVLHPS = {
		{.MOVLHPS,   {.XMM,      .XMM,      .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x16, 0, {esc=._0F}},
	},
	.MOVHLPS = {
		{.MOVHLPS,   {.XMM,      .XMM,      .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x12, 0, {esc=._0F}},
	},
	.MOVMSKPS = {
		{.MOVMSKPS,  {.R32,      .XMM,      .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x50, 0, {esc=._0F}},
		{.MOVMSKPS,  {.R64,      .XMM,      .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x50, 0, {esc=._0F, force_rex_w=true}},
	},
	.MOVMSKPD = {
		{.MOVMSKPD,  {.R32,      .XMM,      .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x50, 0, {esc=._0F, prefix=PREFIX_66}},
		{.MOVMSKPD,  {.R64,      .XMM,      .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x50, 0, {esc=._0F, prefix=PREFIX_66, force_rex_w=true}},
	},
	.MOVNTPS = {
		{.MOVNTPS,   {.M128,     .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x2B, 0, {esc=._0F}},
	},
	.MOVNTPD = {
		{.MOVNTPD,   {.M128,     .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x2B, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.MOVNTDQ = {
		{.MOVNTDQ,   {.M128,     .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0xE7, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.MOVNTDQA = {
		{.MOVNTDQA,  {.XMM,      .M128,     .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x2A, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.ADDPS = {
		{.ADDPS,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x58, 0, {esc=._0F}},
	},
	.ADDPD = {
		{.ADDPD,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x58, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.ADDSS = {
		{.ADDSS,     {.XMM, .XMM_M32,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x58, 0, {esc=._0F, prefix=PREFIX_F3}},
	},
	.ADDSD = {
		{.ADDSD,     {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x58, 0, {esc=._0F, prefix=PREFIX_F2}},
	},
	.SUBPS = {
		{.SUBPS,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5C, 0, {esc=._0F}},
	},
	.SUBPD = {
		{.SUBPD,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5C, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.SUBSS = {
		{.SUBSS,     {.XMM, .XMM_M32,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5C, 0, {esc=._0F, prefix=PREFIX_F3}},
	},
	.SUBSD = {
		{.SUBSD,     {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5C, 0, {esc=._0F, prefix=PREFIX_F2}},
	},
	.MULPS = {
		{.MULPS,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x59, 0, {esc=._0F}},
	},
	.MULPD = {
		{.MULPD,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x59, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.MULSS = {
		{.MULSS,     {.XMM, .XMM_M32,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x59, 0, {esc=._0F, prefix=PREFIX_F3}},
	},
	.MULSD = {
		{.MULSD,     {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x59, 0, {esc=._0F, prefix=PREFIX_F2}},
	},
	.DIVPS = {
		{.DIVPS,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5E, 0, {esc=._0F}},
	},
	.DIVPD = {
		{.DIVPD,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5E, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.DIVSS = {
		{.DIVSS,     {.XMM, .XMM_M32,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5E, 0, {esc=._0F, prefix=PREFIX_F3}},
	},
	.DIVSD = {
		{.DIVSD,     {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5E, 0, {esc=._0F, prefix=PREFIX_F2}},
	},
	.SQRTPS = {
		{.SQRTPS,    {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x51, 0, {esc=._0F}},
	},
	.SQRTPD = {
		{.SQRTPD,    {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x51, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.SQRTSS = {
		{.SQRTSS,    {.XMM, .XMM_M32,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x51, 0, {esc=._0F, prefix=PREFIX_F3}},
	},
	.SQRTSD = {
		{.SQRTSD,    {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x51, 0, {esc=._0F, prefix=PREFIX_F2}},
	},
	.RCPPS = {
		{.RCPPS,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x53, 0, {esc=._0F}},
	},
	.RCPSS = {
		{.RCPSS,     {.XMM, .XMM_M32,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x53, 0, {esc=._0F, prefix=PREFIX_F3}},
	},
	.RSQRTPS = {
		{.RSQRTPS,   {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x52, 0, {esc=._0F}},
	},
	.RSQRTSS = {
		{.RSQRTSS,   {.XMM, .XMM_M32,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x52, 0, {esc=._0F, prefix=PREFIX_F3}},
	},
	.MAXPS = {
		{.MAXPS,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5F, 0, {esc=._0F}},
	},
	.MAXPD = {
		{.MAXPD,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5F, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.MAXSS = {
		{.MAXSS,     {.XMM, .XMM_M32,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5F, 0, {esc=._0F, prefix=PREFIX_F3}},
	},
	.MAXSD = {
		{.MAXSD,     {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5F, 0, {esc=._0F, prefix=PREFIX_F2}},
	},
	.MINPS = {
		{.MINPS,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5D, 0, {esc=._0F}},
	},
	.MINPD = {
		{.MINPD,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5D, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.MINSS = {
		{.MINSS,     {.XMM, .XMM_M32,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5D, 0, {esc=._0F, prefix=PREFIX_F3}},
	},
	.MINSD = {
		{.MINSD,     {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5D, 0, {esc=._0F, prefix=PREFIX_F2}},
	},
	.ANDPS = {
		{.ANDPS,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x54, 0, {esc=._0F}},
	},
	.ANDPD = {
		{.ANDPD,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x54, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.ANDNPS = {
		{.ANDNPS,    {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x55, 0, {esc=._0F}},
	},
	.ANDNPD = {
		{.ANDNPD,    {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x55, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.ORPS = {
		{.ORPS,      {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x56, 0, {esc=._0F}},
	},
	.ORPD = {
		{.ORPD,      {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x56, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.XORPS = {
		{.XORPS,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x57, 0, {esc=._0F}},
	},
	.XORPD = {
		{.XORPD,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x57, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.CMPPS = {
		{.CMPPS,     {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB,   .NONE}, 0xC2, 0, {esc=._0F}},
	},
	.CMPPD = {
		{.CMPPD,     {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB,   .NONE}, 0xC2, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.CMPSS = {
		{.CMPSS,     {.XMM, .XMM_M32,  .IMM8, .NONE}, {.REG, .MR, .IB,   .NONE}, 0xC2, 0, {esc=._0F, prefix=PREFIX_F3}},
	},
	.CMPSD_SSE = {
		{.CMPSD_SSE, {.XMM, .XMM_M64,  .IMM8, .NONE}, {.REG, .MR, .IB,   .NONE}, 0xC2, 0, {esc=._0F, prefix=PREFIX_F2}},
	},
	.COMISS = {
		{.COMISS,    {.XMM, .XMM_M32,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2F, 0, {esc=._0F}},
	},
	.COMISD = {
		{.COMISD,    {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2F, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.UCOMISS = {
		{.UCOMISS,   {.XMM, .XMM_M32,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2E, 0, {esc=._0F}},
	},
	.UCOMISD = {
		{.UCOMISD,   {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2E, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.SHUFPS = {
		{.SHUFPS,    {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB,   .NONE}, 0xC6, 0, {esc=._0F}},
	},
	.SHUFPD = {
		{.SHUFPD,    {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB,   .NONE}, 0xC6, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.UNPCKLPS = {
		{.UNPCKLPS,  {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x14, 0, {esc=._0F}},
	},
	.UNPCKHPS = {
		{.UNPCKHPS,  {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x15, 0, {esc=._0F}},
	},
	.UNPCKLPD = {
		{.UNPCKLPD,  {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x14, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.UNPCKHPD = {
		{.UNPCKHPD,  {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x15, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.CVTPS2PD = {
		{.CVTPS2PD,  {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5A, 0, {esc=._0F}},
	},
	.CVTPD2PS = {
		{.CVTPD2PS,  {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5A, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.CVTSS2SD = {
		{.CVTSS2SD,  {.XMM, .XMM_M32,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5A, 0, {esc=._0F, prefix=PREFIX_F3}},
	},
	.CVTSD2SS = {
		{.CVTSD2SS,  {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5A, 0, {esc=._0F, prefix=PREFIX_F2}},
	},
	.CVTPS2DQ = {
		{.CVTPS2DQ,  {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5B, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.CVTPD2DQ = {
		{.CVTPD2DQ,  {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE6, 0, {esc=._0F, prefix=PREFIX_F2}},
	},
	.CVTDQ2PS = {
		{.CVTDQ2PS,  {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5B, 0, {esc=._0F}},
	},
	.CVTDQ2PD = {
		{.CVTDQ2PD,  {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE6, 0, {esc=._0F, prefix=PREFIX_F3}},
	},
	.CVTSS2SI = {
		{.CVTSS2SI,  {.R32, .XMM_M32,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2D, 0, {esc=._0F, prefix=PREFIX_F3}},
		{.CVTSS2SI,  {.R64, .XMM_M32,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2D, 0, {esc=._0F, prefix=PREFIX_F3, force_rex_w=true}},
	},
	.CVTSD2SI = {
		{.CVTSD2SI,  {.R32, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2D, 0, {esc=._0F, prefix=PREFIX_F2}},
		{.CVTSD2SI,  {.R64, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2D, 0, {esc=._0F, prefix=PREFIX_F2, force_rex_w=true}},
	},
	.CVTSI2SS = {
		{.CVTSI2SS,  {.XMM, .RM32,     .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2A, 0, {esc=._0F, prefix=PREFIX_F3}},
		{.CVTSI2SS,  {.XMM, .RM64,     .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2A, 0, {esc=._0F, prefix=PREFIX_F3, force_rex_w=true}},
	},
	.CVTSI2SD = {
		{.CVTSI2SD,  {.XMM, .RM32,     .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2A, 0, {esc=._0F, prefix=PREFIX_F2}},
		{.CVTSI2SD,  {.XMM, .RM64,     .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2A, 0, {esc=._0F, prefix=PREFIX_F2, force_rex_w=true}},
	},
	.CVTTPS2DQ = {
		{.CVTTPS2DQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5B, 0, {esc=._0F, prefix=PREFIX_F3}},
	},
	.CVTTPD2DQ = {
		{.CVTTPD2DQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE6, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.CVTTSS2SI = {
		{.CVTTSS2SI, {.R32, .XMM_M32,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2C, 0, {esc=._0F, prefix=PREFIX_F3}},
		{.CVTTSS2SI, {.R64, .XMM_M32,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2C, 0, {esc=._0F, prefix=PREFIX_F3, force_rex_w=true}},
	},
	.CVTTSD2SI = {
		{.CVTTSD2SI, {.R32, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2C, 0, {esc=._0F, prefix=PREFIX_F2}},
		{.CVTTSD2SI, {.R64, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2C, 0, {esc=._0F, prefix=PREFIX_F2, force_rex_w=true}},
	},
	.PADDB = {
		{.PADDB,   {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xFC, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PADDW = {
		{.PADDW,   {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xFD, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PADDD = {
		{.PADDD,   {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xFE, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PADDQ = {
		{.PADDQ,   {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD4, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PSUBB = {
		{.PSUBB,   {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF8, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PSUBW = {
		{.PSUBW,   {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF9, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PSUBD = {
		{.PSUBD,   {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xFA, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PSUBQ = {
		{.PSUBQ,   {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xFB, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PADDSB = {
		{.PADDSB,  {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xEC, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PADDSW = {
		{.PADDSW,  {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xED, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PADDUSB = {
		{.PADDUSB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDC, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PADDUSW = {
		{.PADDUSW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDD, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PSUBSB = {
		{.PSUBSB,  {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE8, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PSUBSW = {
		{.PSUBSW,  {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE9, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PSUBUSB = {
		{.PSUBUSB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD8, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PSUBUSW = {
		{.PSUBUSW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD9, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PMULLW = {
		{.PMULLW,  {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD5, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PMULHW = {
		{.PMULHW,  {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE5, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PMULHUW = {
		{.PMULHUW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE4, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PMULUDQ = {
		{.PMULUDQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF4, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PMADDWD = {
		{.PMADDWD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF5, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PAND = {
		{.PAND,    {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDB, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PANDN = {
		{.PANDN,   {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDF, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.POR = {
		{.POR,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xEB, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PXOR = {
		{.PXOR,    {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xEF, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PSLLW = {
		{.PSLLW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF1, 0, {esc=._0F, prefix=PREFIX_66}},
		{.PSLLW, {.XMM, .IMM8,     .NONE, .NONE}, {.MR,  .IB, .NONE, .NONE}, 0x71, 6, {esc=._0F, prefix=PREFIX_66, modrm_reg_ext=true}},
	},
	.PSLLD = {
		{.PSLLD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF2, 0, {esc=._0F, prefix=PREFIX_66}},
		{.PSLLD, {.XMM, .IMM8,     .NONE, .NONE}, {.MR,  .IB, .NONE, .NONE}, 0x72, 6, {esc=._0F, prefix=PREFIX_66, modrm_reg_ext=true}},
	},
	.PSLLQ = {
		{.PSLLQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF3, 0, {esc=._0F, prefix=PREFIX_66}},
		{.PSLLQ, {.XMM, .IMM8,     .NONE, .NONE}, {.MR,  .IB, .NONE, .NONE}, 0x73, 6, {esc=._0F, prefix=PREFIX_66, modrm_reg_ext=true}},
	},
	.PSRLW = {
		{.PSRLW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD1, 0, {esc=._0F, prefix=PREFIX_66}},
		{.PSRLW, {.XMM, .IMM8,     .NONE, .NONE}, {.MR,  .IB, .NONE, .NONE}, 0x71, 2, {esc=._0F, prefix=PREFIX_66, modrm_reg_ext=true}},
	},
	.PSRLD = {
		{.PSRLD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD2, 0, {esc=._0F, prefix=PREFIX_66}},
		{.PSRLD, {.XMM, .IMM8,     .NONE, .NONE}, {.MR,  .IB, .NONE, .NONE}, 0x72, 2, {esc=._0F, prefix=PREFIX_66, modrm_reg_ext=true}},
	},
	.PSRLQ = {
		{.PSRLQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD3, 0, {esc=._0F, prefix=PREFIX_66}},
		{.PSRLQ, {.XMM, .IMM8,     .NONE, .NONE}, {.MR,  .IB, .NONE, .NONE}, 0x73, 2, {esc=._0F, prefix=PREFIX_66, modrm_reg_ext=true}},
	},
	.PSRAW = {
		{.PSRAW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE1, 0, {esc=._0F, prefix=PREFIX_66}},
		{.PSRAW, {.XMM, .IMM8,     .NONE, .NONE}, {.MR,  .IB, .NONE, .NONE}, 0x71, 4, {esc=._0F, prefix=PREFIX_66, modrm_reg_ext=true}},
	},
	.PSRAD = {
		{.PSRAD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE2, 0, {esc=._0F, prefix=PREFIX_66}},
		{.PSRAD, {.XMM, .IMM8,     .NONE, .NONE}, {.MR,  .IB, .NONE, .NONE}, 0x72, 4, {esc=._0F, prefix=PREFIX_66, modrm_reg_ext=true}},
	},
	.PCMPEQB = {
		{.PCMPEQB,    {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x74, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PCMPEQW = {
		{.PCMPEQW,    {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x75, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PCMPEQD = {
		{.PCMPEQD,    {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x76, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PCMPGTB = {
		{.PCMPGTB,    {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x64, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PCMPGTW = {
		{.PCMPGTW,    {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x65, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PCMPGTD = {
		{.PCMPGTD,    {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x66, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PACKSSWB = {
		{.PACKSSWB,   {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x63, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PACKSSDW = {
		{.PACKSSDW,   {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x6B, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PACKUSWB = {
		{.PACKUSWB,   {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x67, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PUNPCKLBW = {
		{.PUNPCKLBW,  {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x60, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PUNPCKLWD = {
		{.PUNPCKLWD,  {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x61, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PUNPCKLDQ = {
		{.PUNPCKLDQ,  {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x62, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PUNPCKLQDQ = {
		{.PUNPCKLQDQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x6C, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PUNPCKHBW = {
		{.PUNPCKHBW,  {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x68, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PUNPCKHWD = {
		{.PUNPCKHWD,  {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x69, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PUNPCKHDQ = {
		{.PUNPCKHDQ,  {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x6A, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PUNPCKHQDQ = {
		{.PUNPCKHQDQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x6D, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PSHUFD = {
		{.PSHUFD,     {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x70, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PSHUFHW = {
		{.PSHUFHW,    {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x70, 0, {esc=._0F, prefix=PREFIX_F3}},
	},
	.PSHUFLW = {
		{.PSHUFLW,    {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x70, 0, {esc=._0F, prefix=PREFIX_F2}},
	},
	.PSHUFW = {
		{.PSHUFW,     {.MM,  .MM_M64,   .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x70, 0, {esc=._0F}},
	},
	.PEXTRW = {
		{.PEXTRW,     {.R32, .XMM,      .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0xC5, 0, {esc=._0F, prefix=PREFIX_66}},
		{.PEXTRW,     {.R64, .XMM,      .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0xC5, 0, {esc=._0F, prefix=PREFIX_66, force_rex_w=true}},
	},
	.PINSRW = {
		{.PINSRW,     {.XMM, .R32,      .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0xC4, 0, {esc=._0F, prefix=PREFIX_66}},
		{.PINSRW,     {.XMM, .M16,      .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0xC4, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PMOVMSKB = {
		{.PMOVMSKB,   {.R32, .XMM,      .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD7, 0, {esc=._0F, prefix=PREFIX_66}},
		{.PMOVMSKB,   {.R64, .XMM,      .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD7, 0, {esc=._0F, prefix=PREFIX_66, force_rex_w=true}},
	},
	.PAVGB = {
		{.PAVGB,      {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE0, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PAVGW = {
		{.PAVGW,      {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xE3, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PMAXUB = {
		{.PMAXUB,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDE, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PMAXSW = {
		{.PMAXSW,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xEE, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PMINUB = {
		{.PMINUB,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDA, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PMINSW = {
		{.PMINSW,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xEA, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.PSADBW = {
		{.PSADBW,     {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF6, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.MASKMOVDQU = {
		{.MASKMOVDQU, {.XMM, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF7, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.LFENCE = {
		{.LFENCE, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAE, 0xE8, {esc=._0F}},
	},
	.SFENCE = {
		{.SFENCE, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAE, 0xF8, {esc=._0F}},
	},
	.MFENCE = {
		{.MFENCE, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAE, 0xF0, {esc=._0F}},
	},
	.PAUSE = {
		{.PAUSE, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x90, 0, {prefix=PREFIX_F3}},
	},
	.CLFLUSH = {
		{.CLFLUSH, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 7, {esc=._0F, modrm_reg_ext=true}},
	},
	.ADDSUBPS = {
		{.ADDSUBPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD0, 0, {esc=._0F, prefix=PREFIX_F2}},
	},
	.ADDSUBPD = {
		{.ADDSUBPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xD0, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.HADDPS = {
		{.HADDPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x7C, 0, {esc=._0F, prefix=PREFIX_F2}},
	},
	.HADDPD = {
		{.HADDPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x7C, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.HSUBPS = {
		{.HSUBPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x7D, 0, {esc=._0F, prefix=PREFIX_F2}},
	},
	.HSUBPD = {
		{.HSUBPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x7D, 0, {esc=._0F, prefix=PREFIX_66}},
	},
	.MOVDDUP = {
		{.MOVDDUP, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x12, 0, {esc=._0F, prefix=PREFIX_F2}},
	},
	.MOVSLDUP = {
		{.MOVSLDUP, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x12, 0, {esc=._0F, prefix=PREFIX_F3}},
	},
	.MOVSHDUP = {
		{.MOVSHDUP, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x16, 0, {esc=._0F, prefix=PREFIX_F3}},
	},
	.LDDQU = {
		{.LDDQU, {.XMM, .M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF0, 0, {esc=._0F, prefix=PREFIX_F2}},
	},
	.PSHUFB = {
		{.PSHUFB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x00, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PHADDW = {
		{.PHADDW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x01, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PHADDD = {
		{.PHADDD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x02, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PHADDSW = {
		{.PHADDSW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x03, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PHSUBW = {
		{.PHSUBW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x05, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PHSUBD = {
		{.PHSUBD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x06, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PHSUBSW = {
		{.PHSUBSW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x07, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMADDUBSW = {
		{.PMADDUBSW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x04, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMULHRSW = {
		{.PMULHRSW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x0B, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PSIGNB = {
		{.PSIGNB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x08, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PSIGNW = {
		{.PSIGNW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x09, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PSIGND = {
		{.PSIGND, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x0A, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PABSB = {
		{.PABSB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x1C, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PABSW = {
		{.PABSW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x1D, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PABSD = {
		{.PABSD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x1E, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PALIGNR = {
		{.PALIGNR, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x0F, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.BLENDPS = {
		{.BLENDPS, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x0C, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.BLENDPD = {
		{.BLENDPD, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x0D, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.BLENDVPS = {
		{.BLENDVPS, {.XMM, .XMM_M128, .XMM0_IMPL, .NONE}, {.REG, .MR, .IMPL, .NONE}, 0x14, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.BLENDVPD = {
		{.BLENDVPD, {.XMM, .XMM_M128, .XMM0_IMPL, .NONE}, {.REG, .MR, .IMPL, .NONE}, 0x15, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PBLENDW = {
		{.PBLENDW, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x0E, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.PBLENDVB = {
		{.PBLENDVB, {.XMM, .XMM_M128, .XMM0_IMPL, .NONE}, {.REG, .MR, .IMPL, .NONE}, 0x10, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.DPPS = {
		{.DPPS, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x40, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.DPPD = {
		{.DPPD, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x41, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.EXTRACTPS = {
		{.EXTRACTPS, {.RM32, .XMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x17, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.INSERTPS = {
		{.INSERTPS, {.XMM, .XMM_M32, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x21, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.MPSADBW = {
		{.MPSADBW, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x42, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.PACKUSDW = {
		{.PACKUSDW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2B, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PEXTRB = {
		{.PEXTRB, {.RM8, .XMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x14, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.PEXTRD = {
		{.PEXTRD, {.RM32, .XMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x16, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.PEXTRQ = {
		{.PEXTRQ, {.RM64, .XMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x16, 0, {esc=._0F3A, prefix=PREFIX_66, force_rex_w=true}},
	},
	.PHMINPOSUW = {
		{.PHMINPOSUW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x41, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PINSRB = {
		{.PINSRB, {.XMM, .RM8, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x20, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.PINSRD = {
		{.PINSRD, {.XMM, .RM32, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x22, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.PINSRQ = {
		{.PINSRQ, {.XMM, .RM64, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x22, 0, {esc=._0F3A, prefix=PREFIX_66, force_rex_w=true}},
	},
	.PMAXSB = {
		{.PMAXSB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x3C, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMAXSD = {
		{.PMAXSD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x3D, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMAXUW = {
		{.PMAXUW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x3E, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMAXUD = {
		{.PMAXUD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x3F, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMINSB = {
		{.PMINSB, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x38, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMINSD = {
		{.PMINSD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x39, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMINUW = {
		{.PMINUW, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x3A, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMINUD = {
		{.PMINUD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x3B, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMOVSXBW = {
		{.PMOVSXBW, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x20, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMOVSXBD = {
		{.PMOVSXBD, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x21, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMOVSXBQ = {
		{.PMOVSXBQ, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x22, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMOVSXWD = {
		{.PMOVSXWD, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x23, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMOVSXWQ = {
		{.PMOVSXWQ, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x24, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMOVSXDQ = {
		{.PMOVSXDQ, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x25, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMOVZXBW = {
		{.PMOVZXBW, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x30, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMOVZXBD = {
		{.PMOVZXBD, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x31, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMOVZXBQ = {
		{.PMOVZXBQ, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x32, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMOVZXWD = {
		{.PMOVZXWD, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x33, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMOVZXWQ = {
		{.PMOVZXWQ, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x34, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMOVZXDQ = {
		{.PMOVZXDQ, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x35, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMULDQ = {
		{.PMULDQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x28, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PMULLD = {
		{.PMULLD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x40, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PTEST = {
		{.PTEST, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x17, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.ROUNDPS = {
		{.ROUNDPS, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x08, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.ROUNDPD = {
		{.ROUNDPD, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x09, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.ROUNDSS = {
		{.ROUNDSS, {.XMM, .XMM_M32, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x0A, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.ROUNDSD = {
		{.ROUNDSD, {.XMM, .XMM_M64, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x0B, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.PCMPEQQ = {
		{.PCMPEQQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x29, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.CRC32 = {
		{.CRC32, {.R32, .RM8,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF0, 0, {esc=._0F38, prefix=PREFIX_F2}},
		{.CRC32, {.R32, .RM16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF1, 0, {esc=._0F38, prefix=PREFIX_F2}},
		{.CRC32, {.R32, .RM32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF1, 0, {esc=._0F38, prefix=PREFIX_F2}},
		{.CRC32, {.R64, .RM8,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF0, 0, {esc=._0F38, prefix=PREFIX_F2, force_rex_w=true}},
		{.CRC32, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xF1, 0, {esc=._0F38, prefix=PREFIX_F2, force_rex_w=true}},
	},
	.PCMPESTRI = {
		{.PCMPESTRI, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x61, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.PCMPESTRM = {
		{.PCMPESTRM, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x60, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.PCMPISTRI = {
		{.PCMPISTRI, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x63, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.PCMPISTRM = {
		{.PCMPISTRM, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x62, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.PCMPGTQ = {
		{.PCMPGTQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x37, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.PCLMULQDQ = {
		{.PCLMULQDQ, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x44, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.AESDEC = {
		{.AESDEC, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDE, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.AESDECLAST = {
		{.AESDECLAST, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDF, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.AESENC = {
		{.AESENC, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDC, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.AESENCLAST = {
		{.AESENCLAST, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDD, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.AESIMC = {
		{.AESIMC, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xDB, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.AESKEYGENASSIST = {
		{.AESKEYGENASSIST, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0xDF, 0, {esc=._0F3A, prefix=PREFIX_66}},
	},
	.SHA1MSG1 = {
		{.SHA1MSG1, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xC9, 0, {esc=._0F38}},
	},
	.SHA1MSG2 = {
		{.SHA1MSG2, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xCA, 0, {esc=._0F38}},
	},
	.SHA1NEXTE = {
		{.SHA1NEXTE, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xC8, 0, {esc=._0F38}},
	},
	.SHA1RNDS4 = {
		{.SHA1RNDS4, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0xCC, 0, {esc=._0F3A}},
	},
	.SHA256MSG1 = {
		{.SHA256MSG1, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xCC, 0, {esc=._0F38}},
	},
	.SHA256MSG2 = {
		{.SHA256MSG2, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xCD, 0, {esc=._0F38}},
	},
	.SHA256RNDS2 = {
		{.SHA256RNDS2, {.XMM, .XMM_M128, .XMM0_IMPL, .NONE}, {.REG, .MR, .IMPL, .NONE}, 0xCB, 0, {esc=._0F38}},
	},

	// -------------------------------------------------------------------------
	// SECTION: 8.13 AVX/AVX2 Encodings
	// -------------------------------------------------------------------------
	.VADDPS = {
		{.VADDPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x58, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VADDPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x58, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VADDPD = {
		{.VADDPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x58, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VADDPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x58, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VADDSS = {
		{.VADDSS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x58, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.LIG}},
	},
	.VADDSD = {
		{.VADDSD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x58, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.LIG}},
	},
	.VSUBPS = {
		{.VSUBPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5C, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VSUBPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5C, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VSUBPD = {
		{.VSUBPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5C, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VSUBPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5C, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VSUBSS = {
		{.VSUBSS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5C, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.LIG}},
	},
	.VSUBSD = {
		{.VSUBSD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5C, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.LIG}},
	},
	.VMULPS = {
		{.VMULPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x59, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VMULPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x59, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VMULPD = {
		{.VMULPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x59, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VMULPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x59, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VMULSS = {
		{.VMULSS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x59, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.LIG}},
	},
	.VMULSD = {
		{.VMULSD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x59, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.LIG}},
	},
	.VDIVPS = {
		{.VDIVPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5E, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VDIVPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5E, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VDIVPD = {
		{.VDIVPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5E, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VDIVPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5E, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VDIVSS = {
		{.VDIVSS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5E, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.LIG}},
	},
	.VDIVSD = {
		{.VDIVSD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5E, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.LIG}},
	},
	.VSQRTPS = {
		{.VSQRTPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x51, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VSQRTPS, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x51, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VSQRTPD = {
		{.VSQRTPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x51, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VSQRTPD, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x51, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VSQRTSS = {
		{.VSQRTSS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x51, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.LIG}},
	},
	.VSQRTSD = {
		{.VSQRTSD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x51, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.LIG}},
	},
	.VRCPPS = {
		{.VRCPPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x53, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VRCPPS, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x53, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VRCPSS = {
		{.VRCPSS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x53, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.LIG}},
	},
	.VRSQRTPS = {
		{.VRSQRTPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x52, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VRSQRTPS, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x52, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VRSQRTSS = {
		{.VRSQRTSS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x52, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.LIG}},
	},
	.VMAXPS = {
		{.VMAXPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5F, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VMAXPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5F, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VMAXPD = {
		{.VMAXPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VMAXPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VMAXSS = {
		{.VMAXSS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.LIG}},
	},
	.VMAXSD = {
		{.VMAXSD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.LIG}},
	},
	.VMINPS = {
		{.VMINPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5D, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VMINPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5D, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VMINPD = {
		{.VMINPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5D, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VMINPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5D, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VMINSS = {
		{.VMINSS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5D, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.LIG}},
	},
	.VMINSD = {
		{.VMINSD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x5D, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.LIG}},
	},
	.VANDPS = {
		{.VANDPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x54, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VANDPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x54, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VANDPD = {
		{.VANDPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x54, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VANDPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x54, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VANDNPS = {
		{.VANDNPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x55, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VANDNPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x55, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VANDNPD = {
		{.VANDNPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x55, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VANDNPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x55, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VORPS = {
		{.VORPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x56, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VORPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x56, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VORPD = {
		{.VORPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x56, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VORPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x56, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VXORPS = {
		{.VXORPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x57, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VXORPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x57, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VXORPD = {
		{.VXORPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x57, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VXORPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x57, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VCMPPS = {
		{.VCMPPS, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0xC2, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VCMPPS, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0xC2, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VCMPPD = {
		{.VCMPPD, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0xC2, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VCMPPD, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0xC2, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VCMPSS = {
		{.VCMPSS, {.XMM, .XMM, .XMM_M32, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0xC2, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.LIG}},
	},
	.VCMPSD = {
		{.VCMPSD, {.XMM, .XMM, .XMM_M64, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0xC2, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.LIG}},
	},
	.VCOMISS = {
		{.VCOMISS, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2F, 0, {esc=._0F, vex_type=.VEX, vex_l=.LIG}},
	},
	.VCOMISD = {
		{.VCOMISD, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG}},
	},
	.VUCOMISS = {
		{.VUCOMISS, {.XMM, .XMM_M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2E, 0, {esc=._0F, vex_type=.VEX, vex_l=.LIG}},
	},
	.VUCOMISD = {
		{.VUCOMISD, {.XMM, .XMM_M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x2E, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG}},
	},
	.VSHUFPS = {
		{.VSHUFPS, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0xC6, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VSHUFPS, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0xC6, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VSHUFPD = {
		{.VSHUFPD, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0xC6, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VSHUFPD, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0xC6, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VUNPCKLPS = {
		{.VUNPCKLPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x14, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VUNPCKLPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x14, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VUNPCKHPS = {
		{.VUNPCKHPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x15, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VUNPCKHPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x15, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VUNPCKLPD = {
		{.VUNPCKLPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x14, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VUNPCKLPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x14, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VUNPCKHPD = {
		{.VUNPCKHPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x15, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VUNPCKHPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x15, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VBLENDPS = {
		{.VBLENDPS, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x0C, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VBLENDPS, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x0C, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VBLENDPD = {
		{.VBLENDPD, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x0D, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VBLENDPD, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x0D, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VBLENDVPS = {
		{.VBLENDVPS, {.XMM, .XMM, .XMM_M128, .XMM}, {.REG, .VVVV, .MR, .IS4}, 0x4A, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VBLENDVPS, {.YMM, .YMM, .YMM_M256, .YMM}, {.REG, .VVVV, .MR, .IS4}, 0x4A, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VBLENDVPD = {
		{.VBLENDVPD, {.XMM, .XMM, .XMM_M128, .XMM}, {.REG, .VVVV, .MR, .IS4}, 0x4B, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VBLENDVPD, {.YMM, .YMM, .YMM_M256, .YMM}, {.REG, .VVVV, .MR, .IS4}, 0x4B, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VDPPS = {
		{.VDPPS, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x40, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VDPPS, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x40, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VDPPD = {
		{.VDPPD, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x41, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
	},
	.VROUNDPS = {
		{.VROUNDPS, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x08, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VROUNDPS, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x08, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VROUNDPD = {
		{.VROUNDPD, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x09, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VROUNDPD, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x09, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VROUNDSS = {
		{.VROUNDSS, {.XMM, .XMM, .XMM_M32, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x0A, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG}},
	},
	.VROUNDSD = {
		{.VROUNDSD, {.XMM, .XMM, .XMM_M64, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x0B, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG}},
	},
	.VEXTRACTPS = {
		{.VEXTRACTPS, {.RM32, .XMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x17, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
	},
	.VINSERTPS = {
		{.VINSERTPS, {.XMM, .XMM, .XMM_M32, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x21, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
	},
	.VMOVAPS = {
		{.VMOVAPS,    {.XMM,      .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x28, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VMOVAPS,    {.XMM_M128, .XMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x29, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VMOVAPS,    {.YMM,      .YMM_M256, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x28, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
		{.VMOVAPS,    {.YMM_M256, .YMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x29, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VMOVUPS = {
		{.VMOVUPS,    {.XMM,      .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x10, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VMOVUPS,    {.XMM_M128, .XMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x11, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VMOVUPS,    {.YMM,      .YMM_M256, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x10, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
		{.VMOVUPS,    {.YMM_M256, .YMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x11, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VMOVAPD = {
		{.VMOVAPD,    {.XMM,      .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x28, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VMOVAPD,    {.XMM_M128, .XMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x29, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VMOVAPD,    {.YMM,      .YMM_M256, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x28, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
		{.VMOVAPD,    {.YMM_M256, .YMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x29, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VMOVUPD = {
		{.VMOVUPD,    {.XMM,      .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x10, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VMOVUPD,    {.XMM_M128, .XMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x11, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VMOVUPD,    {.YMM,      .YMM_M256, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x10, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
		{.VMOVUPD,    {.YMM_M256, .YMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x11, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VMOVSS = {
		{.VMOVSS,     {.XMM,      .M32,      .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x10, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.LIG}},
		{.VMOVSS,     {.M32,      .XMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x11, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.LIG}},
		{.VMOVSS,     {.XMM,      .XMM,      .XMM,      .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x10, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.LIG}},
	},
	.VMOVSD = {
		{.VMOVSD,     {.XMM,      .M64,      .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x10, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.LIG}},
		{.VMOVSD,     {.M64,      .XMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x11, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.LIG}},
		{.VMOVSD,     {.XMM,      .XMM,      .XMM,      .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x10, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.LIG}},
	},
	.VMOVDQA = {
		{.VMOVDQA,    {.XMM,      .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VMOVDQA,    {.XMM_M128, .XMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VMOVDQA,    {.YMM,      .YMM_M256, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
		{.VMOVDQA,    {.YMM_M256, .YMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VMOVDQU = {
		{.VMOVDQU,    {.XMM,      .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L0}},
		{.VMOVDQU,    {.XMM_M128, .XMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L0}},
		{.VMOVDQU,    {.YMM,      .YMM_M256, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L1}},
		{.VMOVDQU,    {.YMM_M256, .YMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L1}},
	},
	.VMOVQ = {
		{.VMOVQ,      {.XMM,      .XMM_M64,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x7E, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L0}},
		{.VMOVQ,      {.XMM_M64,  .XMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0xD6, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VMOVQ,      {.XMM,      .R64,      .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x6E, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VMOVQ,      {.R64,      .XMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x7E, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
	},
	.VMOVD = {
		{.VMOVD,      {.XMM,      .RM32,     .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x6E, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VMOVD,      {.RM32,     .XMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x7E, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
	},
	.VMOVLPS = {
		{.VMOVLPS,    {.XMM,      .XMM,      .M64,      .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x12, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VMOVLPS,    {.M64,      .XMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x13, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
	},
	.VMOVHPS = {
		{.VMOVHPS,    {.XMM,      .XMM,      .M64,      .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x16, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VMOVHPS,    {.M64,      .XMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x17, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
	},
	.VMOVLPD = {
		{.VMOVLPD,    {.XMM,      .XMM,      .M64,      .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x12, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VMOVLPD,    {.M64,      .XMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x13, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
	},
	.VMOVHPD = {
		{.VMOVHPD,    {.XMM,      .XMM,      .M64,      .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x16, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VMOVHPD,    {.M64,      .XMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x17, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
	},
	.VMOVLHPS = {
		{.VMOVLHPS,   {.XMM,      .XMM,      .XMM,      .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x16, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
	},
	.VMOVHLPS = {
		{.VMOVHLPS,   {.XMM,      .XMM,      .XMM,      .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x12, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
	},
	.VMOVMSKPS = {
		{.VMOVMSKPS,  {.R32,      .XMM,      .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x50, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VMOVMSKPS,  {.R32,      .YMM,      .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x50, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VMOVMSKPD = {
		{.VMOVMSKPD,  {.R32,      .XMM,      .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x50, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VMOVMSKPD,  {.R32,      .YMM,      .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x50, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VMOVNTPS = {
		{.VMOVNTPS,   {.M128,     .XMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x2B, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VMOVNTPS,   {.M256,     .YMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x2B, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VMOVNTPD = {
		{.VMOVNTPD,   {.M128,     .XMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x2B, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VMOVNTPD,   {.M256,     .YMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0x2B, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VMOVNTDQ = {
		{.VMOVNTDQ,   {.M128,     .XMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0xE7, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VMOVNTDQ,   {.M256,     .YMM,      .NONE,     .NONE}, {.MR,  .REG,  .NONE, .NONE}, 0xE7, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VMOVNTDQA = {
		{.VMOVNTDQA,  {.XMM,      .M128,     .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x2A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VMOVNTDQA,  {.YMM,      .M256,     .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x2A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VCVTPS2PD = {
		{.VCVTPS2PD,  {.XMM,      .XMM_M64,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x5A, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VCVTPS2PD,  {.YMM,      .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x5A, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VCVTPD2PS = {
		{.VCVTPD2PS,  {.XMM,      .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x5A, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VCVTPD2PS,  {.XMM,      .YMM_M256, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x5A, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VCVTSS2SD = {
		{.VCVTSS2SD,  {.XMM,      .XMM,      .XMM_M32,  .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x5A, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.LIG}},
	},
	.VCVTSD2SS = {
		{.VCVTSD2SS,  {.XMM,      .XMM,      .XMM_M64,  .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x5A, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.LIG}},
	},
	.VCVTPS2DQ = {
		{.VCVTPS2DQ,  {.XMM,      .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x5B, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VCVTPS2DQ,  {.YMM,      .YMM_M256, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x5B, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VCVTPD2DQ = {
		{.VCVTPD2DQ,  {.XMM,      .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0xE6, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.L0}},
		{.VCVTPD2DQ,  {.XMM,      .YMM_M256, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0xE6, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.L1}},
	},
	.VCVTDQ2PS = {
		{.VCVTDQ2PS,  {.XMM,      .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x5B, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
		{.VCVTDQ2PS,  {.YMM,      .YMM_M256, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x5B, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VCVTDQ2PD = {
		{.VCVTDQ2PD,  {.XMM,      .XMM_M64,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0xE6, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L0}},
		{.VCVTDQ2PD,  {.YMM,      .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0xE6, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L1}},
	},
	.VCVTSS2SI = {
		{.VCVTSS2SI,  {.R32,      .XMM_M32,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x2D, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.LIG}},
		{.VCVTSS2SI,  {.R64,      .XMM_M32,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x2D, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.LIG, vex_w=.W1}},
	},
	.VCVTSD2SI = {
		{.VCVTSD2SI,  {.R32,      .XMM_M64,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x2D, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.LIG}},
		{.VCVTSD2SI,  {.R64,      .XMM_M64,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x2D, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.LIG, vex_w=.W1}},
	},
	.VCVTSI2SS = {
		{.VCVTSI2SS,  {.XMM,      .XMM,      .RM32,     .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x2A, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.LIG}},
		{.VCVTSI2SS,  {.XMM,      .XMM,      .RM64,     .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x2A, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.LIG, vex_w=.W1}},
	},
	.VCVTSI2SD = {
		{.VCVTSI2SD,  {.XMM,      .XMM,      .RM32,     .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x2A, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.LIG}},
		{.VCVTSI2SD,  {.XMM,      .XMM,      .RM64,     .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x2A, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.LIG, vex_w=.W1}},
	},
	.VCVTTPS2DQ = {
		{.VCVTTPS2DQ, {.XMM,      .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x5B, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L0}},
		{.VCVTTPS2DQ, {.YMM,      .YMM_M256, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x5B, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L1}},
	},
	.VCVTTPD2DQ = {
		{.VCVTTPD2DQ, {.XMM,      .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0xE6, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VCVTTPD2DQ, {.XMM,      .YMM_M256, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0xE6, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VCVTTSS2SI = {
		{.VCVTTSS2SI, {.R32,      .XMM_M32,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x2C, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.LIG}},
		{.VCVTTSS2SI, {.R64,      .XMM_M32,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x2C, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.LIG, vex_w=.W1}},
	},
	.VCVTTSD2SI = {
		{.VCVTTSD2SI, {.R32,      .XMM_M64,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x2C, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.LIG}},
		{.VCVTTSD2SI, {.R64,      .XMM_M64,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x2C, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.LIG, vex_w=.W1}},
	},
	.VPADDB = {
		{.VPADDB,     {.XMM,      .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xFC, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPADDB,     {.YMM,      .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xFC, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPADDW = {
		{.VPADDW,     {.XMM,      .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xFD, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPADDW,     {.YMM,      .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xFD, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPADDD = {
		{.VPADDD,     {.XMM,      .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xFE, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPADDD,     {.YMM,      .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xFE, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPADDQ = {
		{.VPADDQ,     {.XMM,      .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xD4, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPADDQ,     {.YMM,      .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xD4, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPSUBB = {
		{.VPSUBB,     {.XMM,      .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xF8, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSUBB,     {.YMM,      .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xF8, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPSUBW = {
		{.VPSUBW,     {.XMM,      .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xF9, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSUBW,     {.YMM,      .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xF9, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPSUBD = {
		{.VPSUBD,     {.XMM,      .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xFA, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSUBD,     {.YMM,      .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xFA, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPSUBQ = {
		{.VPSUBQ,     {.XMM,      .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xFB, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSUBQ,     {.YMM,      .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xFB, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMULLW = {
		{.VPMULLW,    {.XMM,      .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xD5, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMULLW,    {.YMM,      .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xD5, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMULHW = {
		{.VPMULHW,    {.XMM,      .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xE5, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMULHW,    {.YMM,      .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xE5, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMULHUW = {
		{.VPMULHUW,   {.XMM,      .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xE4, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMULHUW,   {.YMM,      .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xE4, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMULUDQ = {
		{.VPMULUDQ,   {.XMM,      .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xF4, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMULUDQ,   {.YMM,      .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xF4, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMADDWD = {
		{.VPMADDWD,   {.XMM,      .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xF5, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMADDWD,   {.YMM,      .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xF5, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPAND = {
		{.VPAND,      {.XMM,      .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xDB, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPAND,      {.YMM,      .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xDB, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPANDN = {
		{.VPANDN,     {.XMM,      .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xDF, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPANDN,     {.YMM,      .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xDF, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPOR = {
		{.VPOR,       {.XMM,      .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xEB, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPOR,       {.YMM,      .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xEB, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPXOR = {
		{.VPXOR,      {.XMM,      .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xEF, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPXOR,      {.YMM,      .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xEF, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPSLLW = {
		{.VPSLLW, {.XMM, .XMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xF1, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSLLW, {.XMM, .XMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x71, 6, {modrm_reg_ext=true, esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSLLW, {.YMM, .YMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xF1, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
		{.VPSLLW, {.YMM, .YMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x71, 6, {modrm_reg_ext=true, esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPSLLD = {
		{.VPSLLD, {.XMM, .XMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xF2, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSLLD, {.XMM, .XMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x72, 6, {modrm_reg_ext=true, esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSLLD, {.YMM, .YMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xF2, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
		{.VPSLLD, {.YMM, .YMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x72, 6, {modrm_reg_ext=true, esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPSLLQ = {
		{.VPSLLQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xF3, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSLLQ, {.XMM, .XMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x73, 6, {modrm_reg_ext=true, esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSLLQ, {.YMM, .YMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xF3, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
		{.VPSLLQ, {.YMM, .YMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x73, 6, {modrm_reg_ext=true, esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPSRLW = {
		{.VPSRLW, {.XMM, .XMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xD1, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSRLW, {.XMM, .XMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x71, 2, {modrm_reg_ext=true, esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSRLW, {.YMM, .YMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xD1, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
		{.VPSRLW, {.YMM, .YMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x71, 2, {modrm_reg_ext=true, esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPSRLD = {
		{.VPSRLD, {.XMM, .XMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xD2, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSRLD, {.XMM, .XMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x72, 2, {modrm_reg_ext=true, esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSRLD, {.YMM, .YMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xD2, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
		{.VPSRLD, {.YMM, .YMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x72, 2, {modrm_reg_ext=true, esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPSRLQ = {
		{.VPSRLQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xD3, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSRLQ, {.XMM, .XMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x73, 2, {modrm_reg_ext=true, esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSRLQ, {.YMM, .YMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xD3, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
		{.VPSRLQ, {.YMM, .YMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x73, 2, {modrm_reg_ext=true, esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPSRAW = {
		{.VPSRAW, {.XMM, .XMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xE1, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSRAW, {.XMM, .XMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x71, 4, {modrm_reg_ext=true, esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSRAW, {.YMM, .YMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xE1, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
		{.VPSRAW, {.YMM, .YMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x71, 4, {modrm_reg_ext=true, esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPSRAD = {
		{.VPSRAD, {.XMM, .XMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xE2, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSRAD, {.XMM, .XMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x72, 4, {modrm_reg_ext=true, esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSRAD, {.YMM, .YMM, .XMM_M128, .NONE}, {.VVVV, .REG, .MR, .NONE}, 0xE2, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
		{.VPSRAD, {.YMM, .YMM, .IMM8,     .NONE}, {.VVVV, .MR,  .IB, .NONE}, 0x72, 4, {modrm_reg_ext=true, esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPCMPEQB = {
		{.VPCMPEQB,    {.XMM,  .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x74, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPCMPEQB,    {.YMM,  .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x74, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPCMPEQW = {
		{.VPCMPEQW,    {.XMM,  .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x75, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPCMPEQW,    {.YMM,  .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x75, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPCMPEQD = {
		{.VPCMPEQD,    {.XMM,  .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x76, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPCMPEQD,    {.YMM,  .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x76, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPCMPEQQ = {
		{.VPCMPEQQ,    {.XMM,  .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x29, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPCMPEQQ,    {.YMM,  .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x29, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPCMPGTB = {
		{.VPCMPGTB,    {.XMM,  .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x64, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPCMPGTB,    {.YMM,  .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x64, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPCMPGTW = {
		{.VPCMPGTW,    {.XMM,  .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x65, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPCMPGTW,    {.YMM,  .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x65, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPCMPGTD = {
		{.VPCMPGTD,    {.XMM,  .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x66, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPCMPGTD,    {.YMM,  .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x66, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPCMPGTQ = {
		{.VPCMPGTQ,    {.XMM,  .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x37, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPCMPGTQ,    {.YMM,  .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x37, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPACKSSWB = {
		{.VPACKSSWB,   {.XMM,  .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x63, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPACKSSWB,   {.YMM,  .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x63, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPACKSSDW = {
		{.VPACKSSDW,   {.XMM,  .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x6B, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPACKSSDW,   {.YMM,  .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x6B, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPACKUSWB = {
		{.VPACKUSWB,   {.XMM,  .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x67, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPACKUSWB,   {.YMM,  .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x67, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPACKUSDW = {
		{.VPACKUSDW,   {.XMM,  .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPACKUSDW,   {.YMM,  .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPUNPCKLBW = {
		{.VPUNPCKLBW,  {.XMM,  .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x60, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPUNPCKLBW,  {.YMM,  .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x60, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPUNPCKLWD = {
		{.VPUNPCKLWD,  {.XMM,  .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x61, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPUNPCKLWD,  {.YMM,  .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x61, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPUNPCKLDQ = {
		{.VPUNPCKLDQ,  {.XMM,  .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x62, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPUNPCKLDQ,  {.YMM,  .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x62, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPUNPCKLQDQ = {
		{.VPUNPCKLQDQ, {.XMM,  .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x6C, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPUNPCKLQDQ, {.YMM,  .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x6C, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPUNPCKHBW = {
		{.VPUNPCKHBW,  {.XMM,  .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x68, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPUNPCKHBW,  {.YMM,  .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x68, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPUNPCKHWD = {
		{.VPUNPCKHWD,  {.XMM,  .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x69, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPUNPCKHWD,  {.YMM,  .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x69, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPUNPCKHDQ = {
		{.VPUNPCKHDQ,  {.XMM,  .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x6A, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPUNPCKHDQ,  {.YMM,  .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x6A, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPUNPCKHQDQ = {
		{.VPUNPCKHQDQ, {.XMM,  .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x6D, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPUNPCKHQDQ, {.YMM,  .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x6D, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPSHUFD = {
		{.VPSHUFD,     {.XMM,  .XMM_M128, .IMM8,     .NONE}, {.REG, .MR,   .IB, .NONE}, 0x70, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSHUFD,     {.YMM,  .YMM_M256, .IMM8,     .NONE}, {.REG, .MR,   .IB, .NONE}, 0x70, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPSHUFHW = {
		{.VPSHUFHW,    {.XMM,  .XMM_M128, .IMM8,     .NONE}, {.REG, .MR,   .IB, .NONE}, 0x70, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L0}},
		{.VPSHUFHW,    {.YMM,  .YMM_M256, .IMM8,     .NONE}, {.REG, .MR,   .IB, .NONE}, 0x70, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.VEX, vex_l=.L1}},
	},
	.VPSHUFLW = {
		{.VPSHUFLW,    {.XMM,  .XMM_M128, .IMM8,     .NONE}, {.REG, .MR,   .IB, .NONE}, 0x70, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.L0}},
		{.VPSHUFLW,    {.YMM,  .YMM_M256, .IMM8,     .NONE}, {.REG, .MR,   .IB, .NONE}, 0x70, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.L1}},
	},
	.VPEXTRB = {
		{.VPEXTRB,     {.RM8,  .XMM,      .IMM8,     .NONE}, {.MR,  .REG,  .IB, .NONE}, 0x14, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
	},
	.VPEXTRW = {
		{.VPEXTRW,     {.R32,  .XMM,      .IMM8,     .NONE}, {.REG, .MR,   .IB, .NONE}, 0xC5, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPEXTRW,     {.RM16, .XMM,      .IMM8,     .NONE}, {.MR,  .REG,  .IB, .NONE}, 0x15, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
	},
	.VPEXTRD = {
		{.VPEXTRD,     {.RM32, .XMM,      .IMM8,     .NONE}, {.MR,  .REG,  .IB, .NONE}, 0x16, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
	},
	.VPEXTRQ = {
		{.VPEXTRQ,     {.RM64, .XMM,      .IMM8,     .NONE}, {.MR,  .REG,  .IB, .NONE}, 0x16, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
	},
	.VPINSRB = {
		{.VPINSRB,     {.XMM,  .XMM,      .RM8,      .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x20, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
	},
	.VPINSRW = {
		{.VPINSRW,     {.XMM,  .XMM,      .RM16,     .IMM8}, {.REG, .VVVV, .MR, .IB}, 0xC4, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
	},
	.VPINSRD = {
		{.VPINSRD,     {.XMM,  .XMM,      .RM32,     .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x22, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
	},
	.VPINSRQ = {
		{.VPINSRQ,     {.XMM,  .XMM,      .RM64,     .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x22, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
	},
	.VPMOVMSKB = {
		{.VPMOVMSKB,   {.R32, .XMM,      .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0xD7, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMOVMSKB,   {.R32, .YMM,      .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0xD7, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPTEST = {
		{.VPTEST,      {.XMM, .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x17, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPTEST,      {.YMM, .YMM_M256, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x17, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPSHUFB = {
		{.VPSHUFB,     {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x00, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSHUFB,     {.YMM, .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x00, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPHADDW = {
		{.VPHADDW,     {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x01, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPHADDW,     {.YMM, .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x01, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPHADDD = {
		{.VPHADDD,     {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x02, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPHADDD,     {.YMM, .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x02, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPHADDSW = {
		{.VPHADDSW,    {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x03, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPHADDSW,    {.YMM, .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x03, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPHSUBW = {
		{.VPHSUBW,     {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x05, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPHSUBW,     {.YMM, .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x05, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPHSUBD = {
		{.VPHSUBD,     {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x06, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPHSUBD,     {.YMM, .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x06, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPHSUBSW = {
		{.VPHSUBSW,    {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x07, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPHSUBSW,    {.YMM, .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x07, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMADDUBSW = {
		{.VPMADDUBSW,  {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x04, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMADDUBSW,  {.YMM, .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x04, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMULHRSW = {
		{.VPMULHRSW,   {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x0B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMULHRSW,   {.YMM, .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x0B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPSIGNB = {
		{.VPSIGNB,     {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x08, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSIGNB,     {.YMM, .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x08, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPSIGNW = {
		{.VPSIGNW,     {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x09, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSIGNW,     {.YMM, .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x09, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPSIGND = {
		{.VPSIGND,     {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x0A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPSIGND,     {.YMM, .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x0A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPABSB = {
		{.VPABSB,      {.XMM, .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x1C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPABSB,      {.YMM, .YMM_M256, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x1C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPABSW = {
		{.VPABSW,      {.XMM, .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x1D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPABSW,      {.YMM, .YMM_M256, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x1D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPABSD = {
		{.VPABSD,      {.XMM, .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x1E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPABSD,      {.YMM, .YMM_M256, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x1E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPALIGNR = {
		{.VPALIGNR,    {.XMM, .XMM,      .XMM_M128, .IMM8}, {.REG, .VVVV, .MR,   .IB}, 0x0F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPALIGNR,    {.YMM, .YMM,      .YMM_M256, .IMM8}, {.REG, .VVVV, .MR,   .IB}, 0x0F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPBLENDW = {
		{.VPBLENDW,    {.XMM, .XMM,      .XMM_M128, .IMM8}, {.REG, .VVVV, .MR,   .IB}, 0x0E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPBLENDW,    {.YMM, .YMM,      .YMM_M256, .IMM8}, {.REG, .VVVV, .MR,   .IB}, 0x0E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPBLENDVB = {
		{.VPBLENDVB,   {.XMM, .XMM,      .XMM_M128, .XMM}, {.REG,  .VVVV, .MR,   .IS4}, 0x4C, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VPBLENDVB,   {.YMM, .YMM,      .YMM_M256, .YMM}, {.REG,  .VVVV, .MR,   .IS4}, 0x4C, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VMPSADBW = {
		{.VMPSADBW,    {.XMM, .XMM,      .XMM_M128, .IMM8}, {.REG, .VVVV, .MR,   .IB}, 0x42, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VMPSADBW,    {.YMM, .YMM,      .YMM_M256, .IMM8}, {.REG, .VVVV, .MR,   .IB}, 0x42, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPHMINPOSUW = {
		{.VPHMINPOSUW, {.XMM, .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x41, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
	},
	.VPMAXSB = {
		{.VPMAXSB,     {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x3C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMAXSB,     {.YMM, .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x3C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMAXSD = {
		{.VPMAXSD,     {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x3D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMAXSD,     {.YMM, .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x3D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMAXUW = {
		{.VPMAXUW,     {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x3E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMAXUW,     {.YMM, .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x3E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMAXUD = {
		{.VPMAXUD,     {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x3F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMAXUD,     {.YMM, .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x3F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMINSB = {
		{.VPMINSB,     {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x38, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMINSB,     {.YMM, .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x38, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMINSD = {
		{.VPMINSD,     {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x39, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMINSD,     {.YMM, .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x39, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMINUW = {
		{.VPMINUW,     {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x3A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMINUW,     {.YMM, .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x3A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMINUD = {
		{.VPMINUD,     {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x3B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMINUD,     {.YMM, .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x3B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMOVSXBW = {
		{.VPMOVSXBW,   {.XMM, .XMM_M64,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x20, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMOVSXBW,   {.YMM, .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x20, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMOVSXBD = {
		{.VPMOVSXBD,   {.XMM, .XMM_M32,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x21, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMOVSXBD,   {.YMM, .XMM_M64,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x21, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMOVSXBQ = {
		{.VPMOVSXBQ,   {.XMM, .XMM,      .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x22, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMOVSXBQ,   {.YMM, .XMM_M32,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x22, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMOVSXWD = {
		{.VPMOVSXWD,   {.XMM, .XMM_M64,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x23, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMOVSXWD,   {.YMM, .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x23, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMOVSXWQ = {
		{.VPMOVSXWQ,   {.XMM, .XMM_M32,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x24, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMOVSXWQ,   {.YMM, .XMM_M64,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x24, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMOVSXDQ = {
		{.VPMOVSXDQ,   {.XMM, .XMM_M64,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x25, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMOVSXDQ,   {.YMM, .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x25, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMOVZXBW = {
		{.VPMOVZXBW,   {.XMM, .XMM_M64,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x30, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMOVZXBW,   {.YMM, .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x30, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMOVZXBD = {
		{.VPMOVZXBD,   {.XMM, .XMM_M32,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x31, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMOVZXBD,   {.YMM, .XMM_M64,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x31, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMOVZXBQ = {
		{.VPMOVZXBQ,   {.XMM, .XMM,      .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x32, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMOVZXBQ,   {.YMM, .XMM_M32,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x32, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMOVZXWD = {
		{.VPMOVZXWD,   {.XMM, .XMM_M64,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x33, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMOVZXWD,   {.YMM, .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x33, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMOVZXWQ = {
		{.VPMOVZXWQ,   {.XMM, .XMM_M32,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x34, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMOVZXWQ,   {.YMM, .XMM_M64,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x34, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMOVZXDQ = {
		{.VPMOVZXDQ,   {.XMM, .XMM_M64,  .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x35, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMOVZXDQ,   {.YMM, .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0x35, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMULDQ = {
		{.VPMULDQ,     {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x28, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMULDQ,     {.YMM, .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x28, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPMULLD = {
		{.VPMULLD,     {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x40, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPMULLD,     {.YMM, .YMM,      .YMM_M256, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0x40, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VMASKMOVDQU = {
		{.VMASKMOVDQU, {.XMM, .XMM,      .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0xF7, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
	},
	.VPCLMULQDQ = {
		{.VPCLMULQDQ,  {.XMM, .XMM,      .XMM_M128, .IMM8}, {.REG, .VVVV, .MR,   .IB}, 0x44, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VPCLMULQDQ,  {.YMM, .YMM,      .YMM_M256, .IMM8}, {.REG, .VVVV, .MR,   .IB}, 0x44, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VAESDEC = {
		{.VAESDEC,     {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xDE, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
	},
	.VAESDECLAST = {
		{.VAESDECLAST, {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xDF, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
	},
	.VAESENC = {
		{.VAESENC,     {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xDC, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
	},
	.VAESENCLAST = {
		{.VAESENCLAST, {.XMM, .XMM,      .XMM_M128, .NONE}, {.REG, .VVVV, .MR,   .NONE}, 0xDD, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
	},
	.VAESIMC = {
		{.VAESIMC,     {.XMM, .XMM_M128, .NONE,     .NONE}, {.REG, .MR,   .NONE, .NONE}, 0xDB, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
	},
	.VAESKEYGENASSIST = {
		{.VAESKEYGENASSIST, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0xDF, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
	},
	.VBROADCASTSS = {
		{.VBROADCASTSS, {.XMM, .M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x18, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VBROADCASTSS, {.YMM, .M32, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x18, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
		{.VBROADCASTSS, {.XMM, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x18, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VBROADCASTSS, {.YMM, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x18, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VBROADCASTSD = {
		{.VBROADCASTSD, {.YMM, .M64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x19, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
		{.VBROADCASTSD, {.YMM, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x19, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VBROADCASTF128 = {
		{.VBROADCASTF128, {.YMM, .M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x1A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VEXTRACTF128 = {
		{.VEXTRACTF128, {.XMM_M128, .YMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x19, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VINSERTF128 = {
		{.VINSERTF128, {.YMM, .YMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x18, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPERM2F128 = {
		{.VPERM2F128, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x06, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VMASKMOVPS = {
		{.VMASKMOVPS, {.XMM,  .XMM, .M128, .NONE}, {.REG, .VVVV, .MR,  .NONE}, 0x2C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VMASKMOVPS, {.YMM,  .YMM, .M256, .NONE}, {.REG, .VVVV, .MR,  .NONE}, 0x2C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
		{.VMASKMOVPS, {.M128, .XMM, .XMM,  .NONE}, {.MR,  .VVVV, .REG, .NONE}, 0x2E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VMASKMOVPS, {.M256, .YMM, .YMM,  .NONE}, {.MR,  .VVVV, .REG, .NONE}, 0x2E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VMASKMOVPD = {
		{.VMASKMOVPD, {.XMM,  .XMM, .M128, .NONE}, {.REG, .VVVV, .MR,  .NONE}, 0x2D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VMASKMOVPD, {.YMM,  .YMM, .M256, .NONE}, {.REG, .VVVV, .MR,  .NONE}, 0x2D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
		{.VMASKMOVPD, {.M128, .XMM, .XMM,  .NONE}, {.MR,  .VVVV, .REG, .NONE}, 0x2F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VMASKMOVPD, {.M256, .YMM, .YMM,  .NONE}, {.MR,  .VVVV, .REG, .NONE}, 0x2F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VTESTPS = {
		{.VTESTPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x0E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VTESTPS, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x0E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VTESTPD = {
		{.VTESTPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x0F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VTESTPD, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x0F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VZEROALL = {
		{.VZEROALL, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x77, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1}},
	},
	.VZEROUPPER = {
		{.VZEROUPPER, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x77, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0}},
	},
	.VBROADCASTI128 = {
		{.VBROADCASTI128, {.YMM, .M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x5A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VEXTRACTI128 = {
		{.VEXTRACTI128, {.XMM_M128, .YMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x39, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VINSERTI128 = {
		{.VINSERTI128, {.YMM, .YMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x38, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPERM2I128 = {
		{.VPERM2I128, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x46, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
	},
	.VPERMD = {
		{.VPERMD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x36, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VPERMPS = {
		{.VPERMPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x16, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VPERMQ = {
		{.VPERMQ, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x00, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VPERMPD = {
		{.VPERMPD, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x01, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VPBLENDD = {
		{.VPBLENDD, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x02, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VPBLENDD, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x02, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VPSLLVD = {
		{.VPSLLVD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x47, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VPSLLVD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x47, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VPSLLVQ = {
		{.VPSLLVQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x47, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VPSLLVQ, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x47, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VPSRLVD = {
		{.VPSRLVD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x45, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VPSRLVD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x45, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VPSRLVQ = {
		{.VPSRLVQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x45, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VPSRLVQ, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x45, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VPSRAVD = {
		{.VPSRAVD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x46, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VPSRAVD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x46, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VPMASKMOVD = {
		{.VPMASKMOVD, {.XMM,  .XMM, .M128, .NONE}, {.REG, .VVVV, .MR,  .NONE}, 0x8C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VPMASKMOVD, {.YMM,  .YMM, .M256, .NONE}, {.REG, .VVVV, .MR,  .NONE}, 0x8C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
		{.VPMASKMOVD, {.M128, .XMM, .XMM,  .NONE}, {.MR,  .VVVV, .REG, .NONE}, 0x8E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VPMASKMOVD, {.M256, .YMM, .YMM,  .NONE}, {.MR,  .VVVV, .REG, .NONE}, 0x8E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VPMASKMOVQ = {
		{.VPMASKMOVQ, {.XMM,  .XMM, .M128, .NONE}, {.REG, .VVVV, .MR,  .NONE}, 0x8C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VPMASKMOVQ, {.YMM,  .YMM, .M256, .NONE}, {.REG, .VVVV, .MR,  .NONE}, 0x8C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
		{.VPMASKMOVQ, {.M128, .XMM, .XMM,  .NONE}, {.MR,  .VVVV, .REG, .NONE}, 0x8E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VPMASKMOVQ, {.M256, .YMM, .YMM,  .NONE}, {.MR,  .VVVV, .REG, .NONE}, 0x8E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VGATHERDPS = {
		{.VGATHERDPS, {.XMM, .M, .XMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x92, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VGATHERDPS, {.YMM, .M, .YMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x92, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VGATHERDPD = {
		{.VGATHERDPD, {.XMM, .M, .XMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x92, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VGATHERDPD, {.YMM, .M, .YMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x92, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VGATHERQPS = {
		{.VGATHERQPS, {.XMM, .M, .XMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x93, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VGATHERQPS, {.XMM, .M, .XMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x93, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VGATHERQPD = {
		{.VGATHERQPD, {.XMM, .M, .XMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x93, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VGATHERQPD, {.YMM, .M, .YMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x93, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VPGATHERDD = {
		{.VPGATHERDD, {.XMM, .M, .XMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x90, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VPGATHERDD, {.YMM, .M, .YMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x90, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VPGATHERDQ = {
		{.VPGATHERDQ, {.XMM, .M, .XMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x90, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VPGATHERDQ, {.YMM, .M, .YMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x90, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VPGATHERQD = {
		{.VPGATHERQD, {.XMM, .M, .XMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x91, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VPGATHERQD, {.XMM, .M, .XMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x91, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VPGATHERQQ = {
		{.VPGATHERQQ, {.XMM, .M, .XMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x91, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VPGATHERQQ, {.YMM, .M, .YMM, .NONE}, {.REG, .MR, .VVVV, .NONE}, 0x91, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},

	// -------------------------------------------------------------------------
	// SECTION: 8.14 FMA Encodings
	// -------------------------------------------------------------------------
	.VFMADD132PS = {
		{.VFMADD132PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x98, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VFMADD132PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x98, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VFMADD213PS = {
		{.VFMADD213PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA8, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VFMADD213PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA8, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VFMADD231PS = {
		{.VFMADD231PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB8, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VFMADD231PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB8, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VFMADD132PD = {
		{.VFMADD132PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x98, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VFMADD132PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x98, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VFMADD213PD = {
		{.VFMADD213PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA8, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VFMADD213PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA8, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VFMADD231PD = {
		{.VFMADD231PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB8, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VFMADD231PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB8, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VFMADD132SS = {
		{.VFMADD132SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x99, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W0}},
	},
	.VFMADD213SS = {
		{.VFMADD213SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA9, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W0}},
	},
	.VFMADD231SS = {
		{.VFMADD231SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB9, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W0}},
	},
	.VFMADD132SD = {
		{.VFMADD132SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x99, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W1}},
	},
	.VFMADD213SD = {
		{.VFMADD213SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA9, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W1}},
	},
	.VFMADD231SD = {
		{.VFMADD231SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB9, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W1}},
	},
	.VFMSUB132PS = {
		{.VFMSUB132PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VFMSUB132PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VFMSUB213PS = {
		{.VFMSUB213PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAA, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VFMSUB213PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAA, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VFMSUB231PS = {
		{.VFMSUB231PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBA, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VFMSUB231PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBA, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VFMSUB132PD = {
		{.VFMSUB132PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VFMSUB132PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VFMSUB213PD = {
		{.VFMSUB213PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAA, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VFMSUB213PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAA, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VFMSUB231PD = {
		{.VFMSUB231PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBA, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VFMSUB231PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBA, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VFMSUB132SS = {
		{.VFMSUB132SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W0}},
	},
	.VFMSUB213SS = {
		{.VFMSUB213SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAB, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W0}},
	},
	.VFMSUB231SS = {
		{.VFMSUB231SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBB, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W0}},
	},
	.VFMSUB132SD = {
		{.VFMSUB132SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W1}},
	},
	.VFMSUB213SD = {
		{.VFMSUB213SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAB, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W1}},
	},
	.VFMSUB231SD = {
		{.VFMSUB231SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBB, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W1}},
	},
	.VFNMADD132PS = {
		{.VFNMADD132PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VFNMADD132PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VFNMADD213PS = {
		{.VFNMADD213PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAC, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VFNMADD213PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAC, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VFNMADD231PS = {
		{.VFNMADD231PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBC, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VFNMADD231PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBC, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VFNMADD132PD = {
		{.VFNMADD132PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VFNMADD132PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VFNMADD213PD = {
		{.VFNMADD213PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAC, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VFNMADD213PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAC, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VFNMADD231PD = {
		{.VFNMADD231PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBC, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VFNMADD231PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBC, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VFNMADD132SS = {
		{.VFNMADD132SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W0}},
	},
	.VFNMADD213SS = {
		{.VFNMADD213SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAD, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W0}},
	},
	.VFNMADD231SS = {
		{.VFNMADD231SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBD, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W0}},
	},
	.VFNMADD132SD = {
		{.VFNMADD132SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W1}},
	},
	.VFNMADD213SD = {
		{.VFNMADD213SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAD, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W1}},
	},
	.VFNMADD231SD = {
		{.VFNMADD231SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBD, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W1}},
	},
	.VFNMSUB132PS = {
		{.VFNMSUB132PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VFNMSUB132PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VFNMSUB213PS = {
		{.VFNMSUB213PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAE, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VFNMSUB213PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAE, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VFNMSUB231PS = {
		{.VFNMSUB231PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBE, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VFNMSUB231PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBE, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VFNMSUB132PD = {
		{.VFNMSUB132PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VFNMSUB132PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VFNMSUB213PD = {
		{.VFNMSUB213PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAE, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VFNMSUB213PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAE, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VFNMSUB231PD = {
		{.VFNMSUB231PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBE, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VFNMSUB231PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBE, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VFNMSUB132SS = {
		{.VFNMSUB132SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W0}},
	},
	.VFNMSUB213SS = {
		{.VFNMSUB213SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAF, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W0}},
	},
	.VFNMSUB231SS = {
		{.VFNMSUB231SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBF, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W0}},
	},
	.VFNMSUB132SD = {
		{.VFNMSUB132SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x9F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W1}},
	},
	.VFNMSUB213SD = {
		{.VFNMSUB213SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xAF, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W1}},
	},
	.VFNMSUB231SD = {
		{.VFNMSUB231SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xBF, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.LIG, vex_w=.W1}},
	},
	.VFMADDSUB132PS = {
		{.VFMADDSUB132PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x96, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VFMADDSUB132PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x96, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VFMADDSUB213PS = {
		{.VFMADDSUB213PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA6, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VFMADDSUB213PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA6, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VFMADDSUB231PS = {
		{.VFMADDSUB231PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB6, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VFMADDSUB231PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB6, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VFMADDSUB132PD = {
		{.VFMADDSUB132PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x96, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VFMADDSUB132PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x96, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VFMADDSUB213PD = {
		{.VFMADDSUB213PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA6, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VFMADDSUB213PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA6, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VFMADDSUB231PD = {
		{.VFMADDSUB231PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB6, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VFMADDSUB231PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB6, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VFMSUBADD132PS = {
		{.VFMSUBADD132PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x97, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VFMSUBADD132PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x97, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VFMSUBADD213PS = {
		{.VFMSUBADD213PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA7, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VFMSUBADD213PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA7, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VFMSUBADD231PS = {
		{.VFMSUBADD231PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB7, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.VFMSUBADD231PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB7, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.VFMSUBADD132PD = {
		{.VFMSUBADD132PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x97, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VFMSUBADD132PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x97, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VFMSUBADD213PD = {
		{.VFMSUBADD213PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA7, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VFMSUBADD213PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xA7, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.VFMSUBADD231PD = {
		{.VFMSUBADD231PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB7, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.VFMSUBADD231PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0xB7, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	// F16C instructions
	.VCVTPH2PS = {
		{.VCVTPH2PS, {.XMM, .XMM_M64,  .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x13, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VCVTPH2PS, {.YMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x13, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
		{.VCVTPH2PS, {.ZMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x13, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2}},
	},
	.VCVTPS2PH = {
		{.VCVTPS2PH, {.XMM_M64,  .XMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x1D, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0}},
		{.VCVTPS2PH, {.XMM_M128, .YMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x1D, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1}},
		{.VCVTPS2PH, {.YMM_M256, .ZMM, .IMM8, .NONE}, {.MR, .REG, .IB, .NONE}, 0x1D, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2}},
	},

	// -------------------------------------------------------------------------
	// SECTION: 8.15 AVX-512 Encodings
	// -------------------------------------------------------------------------
	.VMOVDQA32 = {
		{.VMOVDQA32, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VMOVDQA32, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VMOVDQA32, {.YMM,      .YMM_M256, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VMOVDQA32, {.YMM_M256, .YMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VMOVDQA32, {.ZMM,      .ZMM_M512, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
		{.VMOVDQA32, {.ZMM_M512, .ZMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VMOVDQA64 = {
		{.VMOVDQA64, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VMOVDQA64, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VMOVDQA64, {.YMM,      .YMM_M256, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VMOVDQA64, {.YMM_M256, .YMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VMOVDQA64, {.ZMM,      .ZMM_M512, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
		{.VMOVDQA64, {.ZMM_M512, .ZMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VMOVDQU8 = {
		{.VMOVDQU8, {.XMM,       .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VMOVDQU8, {.XMM_M128,  .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VMOVDQU8, {.YMM,       .YMM_M256, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VMOVDQU8, {.YMM_M256,  .YMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VMOVDQU8, {.ZMM,       .ZMM_M512, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
		{.VMOVDQU8, {.ZMM_M512,  .ZMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VMOVDQU16 = {
		{.VMOVDQU16, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VMOVDQU16, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VMOVDQU16, {.YMM,      .YMM_M256, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VMOVDQU16, {.YMM_M256, .YMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VMOVDQU16, {.ZMM,      .ZMM_M512, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
		{.VMOVDQU16, {.ZMM_M512, .ZMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VMOVDQU32 = {
		{.VMOVDQU32, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VMOVDQU32, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VMOVDQU32, {.YMM,      .YMM_M256, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VMOVDQU32, {.YMM_M256, .YMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VMOVDQU32, {.ZMM,      .ZMM_M512, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
		{.VMOVDQU32, {.ZMM_M512, .ZMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VMOVDQU64 = {
		{.VMOVDQU64, {.XMM,      .XMM_M128, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VMOVDQU64, {.XMM_M128, .XMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VMOVDQU64, {.YMM,      .YMM_M256, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VMOVDQU64, {.YMM_M256, .YMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VMOVDQU64, {.ZMM,      .ZMM_M512, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x6F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
		{.VMOVDQU64, {.ZMM_M512, .ZMM,      .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x7F, 0, {esc=._0F, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	// AVX-512 blend instructions
	.VPBLENDMB = {
		{.VPBLENDMB, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x66, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPBLENDMB, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x66, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPBLENDMB, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x66, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPBLENDMW = {
		{.VPBLENDMW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x66, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPBLENDMW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x66, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPBLENDMW, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x66, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPBLENDMD = {
		{.VPBLENDMD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x64, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPBLENDMD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x64, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPBLENDMD, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x64, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPBLENDMQ = {
		{.VPBLENDMQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x64, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPBLENDMQ, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x64, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPBLENDMQ, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x64, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VBLENDMPS = {
		{.VBLENDMPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x65, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VBLENDMPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x65, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VBLENDMPS, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x65, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VBLENDMPD = {
		{.VBLENDMPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x65, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VBLENDMPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x65, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VBLENDMPD, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x65, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	// AVX-512 comparison instructions (output to mask register)
	.VPCMPB = {
		{.VPCMPB, {.K, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPCMPB, {.K, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPCMPB, {.K, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPCMPUB = {
		{.VPCMPUB, {.K, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPCMPUB, {.K, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPCMPUB, {.K, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPCMPW = {
		{.VPCMPW, {.K, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPCMPW, {.K, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPCMPW, {.K, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPCMPUW = {
		{.VPCMPUW, {.K, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPCMPUW, {.K, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPCMPUW, {.K, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x3E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPCMPD = {
		{.VPCMPD, {.K, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPCMPD, {.K, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPCMPD, {.K, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPCMPUD = {
		{.VPCMPUD, {.K, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPCMPUD, {.K, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPCMPUD, {.K, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPCMPQ = {
		{.VPCMPQ, {.K, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPCMPQ, {.K, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPCMPQ, {.K, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1F, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPCMPUQ = {
		{.VPCMPUQ, {.K, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPCMPUQ, {.K, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPCMPUQ, {.K, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x1E, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	// AVX-512 test instructions (output to mask register)
	.VPTESTMB = {
		{.VPTESTMB, {.K, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPTESTMB, {.K, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPTESTMB, {.K, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPTESTMW = {
		{.VPTESTMW, {.K, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPTESTMW, {.K, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPTESTMW, {.K, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPTESTMD = {
		{.VPTESTMD, {.K, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPTESTMD, {.K, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPTESTMD, {.K, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPTESTMQ = {
		{.VPTESTMQ, {.K, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPTESTMQ, {.K, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPTESTMQ, {.K, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPTESTNMB = {
		{.VPTESTNMB, {.K, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPTESTNMB, {.K, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPTESTNMB, {.K, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPTESTNMW = {
		{.VPTESTNMW, {.K, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPTESTNMW, {.K, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPTESTNMW, {.K, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x26, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPTESTNMD = {
		{.VPTESTNMD, {.K, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPTESTNMD, {.K, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPTESTNMD, {.K, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPTESTNMQ = {
		{.VPTESTNMQ, {.K, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPTESTNMQ, {.K, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPTESTNMQ, {.K, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x27, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	// AVX-512 compress/expand instructions
	.VPCOMPRESSD = {
		{.VPCOMPRESSD, {.XMM_M128, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPCOMPRESSD, {.YMM_M256, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPCOMPRESSD, {.ZMM_M512, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPCOMPRESSQ = {
		{.VPCOMPRESSQ, {.XMM_M128, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPCOMPRESSQ, {.YMM_M256, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPCOMPRESSQ, {.ZMM_M512, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8B, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VCOMPRESSPS = {
		{.VCOMPRESSPS, {.XMM_M128, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VCOMPRESSPS, {.YMM_M256, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VCOMPRESSPS, {.ZMM_M512, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VCOMPRESSPD = {
		{.VCOMPRESSPD, {.XMM_M128, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VCOMPRESSPD, {.YMM_M256, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VCOMPRESSPD, {.ZMM_M512, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x8A, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPEXPANDD = {
		{.VPEXPANDD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x89, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPEXPANDD, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x89, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPEXPANDD, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x89, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPEXPANDQ = {
		{.VPEXPANDQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x89, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPEXPANDQ, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x89, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPEXPANDQ, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x89, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VEXPANDPS = {
		{.VEXPANDPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x88, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VEXPANDPS, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x88, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VEXPANDPS, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x88, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VEXPANDPD = {
		{.VEXPANDPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x88, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VEXPANDPD, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x88, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VEXPANDPD, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x88, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	// AVX-512 conflict detection
	.VPCONFLICTD = {
		{.VPCONFLICTD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xC4, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPCONFLICTD, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xC4, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPCONFLICTD, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xC4, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPCONFLICTQ = {
		{.VPCONFLICTQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xC4, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPCONFLICTQ, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xC4, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPCONFLICTQ, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0xC4, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPLZCNTD = {
		{.VPLZCNTD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPLZCNTD, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPLZCNTD, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPLZCNTQ = {
		{.VPLZCNTQ, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPLZCNTQ, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPLZCNTQ, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	// AVX-512 permute instructions
	.VPERMI2B = {
		{.VPERMI2B, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x75, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPERMI2B, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x75, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPERMI2B, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x75, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPERMI2W = {
		{.VPERMI2W, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x75, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPERMI2W, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x75, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPERMI2W, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x75, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPERMI2D = {
		{.VPERMI2D, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x76, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPERMI2D, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x76, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPERMI2D, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x76, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPERMI2Q = {
		{.VPERMI2Q, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x76, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPERMI2Q, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x76, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPERMI2Q, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x76, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPERMI2PS = {
		{.VPERMI2PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x77, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPERMI2PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x77, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPERMI2PS, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x77, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPERMI2PD = {
		{.VPERMI2PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x77, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPERMI2PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x77, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPERMI2PD, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x77, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPERMT2B = {
		{.VPERMT2B, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPERMT2B, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPERMT2B, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPERMT2W = {
		{.VPERMT2W, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPERMT2W, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPERMT2W, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPERMT2D = {
		{.VPERMT2D, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPERMT2D, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPERMT2D, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPERMT2Q = {
		{.VPERMT2Q, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPERMT2Q, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPERMT2Q, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPERMT2PS = {
		{.VPERMT2PS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPERMT2PS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPERMT2PS, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPERMT2PD = {
		{.VPERMT2PD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPERMT2PD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPERMT2PD, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x7F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPERMB = {
		{.VPERMB, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x8D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPERMB, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x8D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPERMB, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x8D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPERMW = {
		{.VPERMW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x8D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPERMW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x8D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPERMW, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x8D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	// AVX-512 mask-to-vector and vector-to-mask conversions
	.VPMOVB2M = {
		{.VPMOVB2M, {.K, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x29, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPMOVB2M, {.K, .YMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x29, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPMOVB2M, {.K, .ZMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x29, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPMOVW2M = {
		{.VPMOVW2M, {.K, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x29, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPMOVW2M, {.K, .YMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x29, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPMOVW2M, {.K, .ZMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x29, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPMOVD2M = {
		{.VPMOVD2M, {.K, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x39, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPMOVD2M, {.K, .YMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x39, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPMOVD2M, {.K, .ZMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x39, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPMOVQ2M = {
		{.VPMOVQ2M, {.K, .XMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x39, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPMOVQ2M, {.K, .YMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x39, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPMOVQ2M, {.K, .ZMM, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x39, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPMOVM2B = {
		{.VPMOVM2B, {.XMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x28, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPMOVM2B, {.YMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x28, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPMOVM2B, {.ZMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x28, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPMOVM2W = {
		{.VPMOVM2W, {.XMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x28, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPMOVM2W, {.YMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x28, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPMOVM2W, {.ZMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x28, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPMOVM2D = {
		{.VPMOVM2D, {.XMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x38, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPMOVM2D, {.YMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x38, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPMOVM2D, {.ZMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x38, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPMOVM2Q = {
		{.VPMOVM2Q, {.XMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x38, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPMOVM2Q, {.YMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x38, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPMOVM2Q, {.ZMM, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x38, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	// AVX-512 down-conversion instructions
	.VPMOVQB = {
		{.VPMOVQB, {.XMM_M32, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x32, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPMOVQB, {.XMM_M32, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x32, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPMOVQB, {.XMM_M64, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x32, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPMOVSQB = {
		{.VPMOVSQB, {.XMM_M32, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x22, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPMOVSQB, {.XMM_M32, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x22, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPMOVSQB, {.XMM_M64, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x22, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPMOVUSQB = {
		{.VPMOVUSQB, {.XMM_M32, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x12, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPMOVUSQB, {.XMM_M32, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x12, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPMOVUSQB, {.XMM_M64, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x12, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPMOVQW = {
		{.VPMOVQW, {.XMM_M32,  .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x34, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPMOVQW, {.XMM_M64,  .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x34, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPMOVQW, {.XMM_M128, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x34, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPMOVSQW = {
		{.VPMOVSQW, {.XMM_M32,   .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x24, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPMOVSQW, {.XMM_M64,   .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x24, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPMOVSQW, {.XMM_M128,  .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x24, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPMOVUSQW = {
		{.VPMOVUSQW, {.XMM_M32,  .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x14, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPMOVUSQW, {.XMM_M64,  .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x14, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPMOVUSQW, {.XMM_M128, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x14, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPMOVQD = {
		{.VPMOVQD, {.XMM_M64,    .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x35, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPMOVQD, {.XMM_M128,   .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x35, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPMOVQD, {.YMM_M256,   .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x35, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPMOVSQD = {
		{.VPMOVSQD, {.XMM_M64,   .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x25, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPMOVSQD, {.XMM_M128,  .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x25, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPMOVSQD, {.YMM_M256,  .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x25, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPMOVUSQD = {
		{.VPMOVUSQD, {.XMM_M64,  .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x15, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPMOVUSQD, {.XMM_M128, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x15, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPMOVUSQD, {.YMM_M256, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x15, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPMOVDB = {
		{.VPMOVDB, {.XMM_M32,    .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x31, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPMOVDB, {.XMM_M64,    .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x31, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPMOVDB, {.XMM_M128,   .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x31, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPMOVSDB = {
		{.VPMOVSDB, {.XMM_M32,   .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x21, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPMOVSDB, {.XMM_M64,   .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x21, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPMOVSDB, {.XMM_M128,  .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x21, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPMOVUSDB = {
		{.VPMOVUSDB, {.XMM_M32,  .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x11, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPMOVUSDB, {.XMM_M64,  .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x11, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPMOVUSDB, {.XMM_M128, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x11, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPMOVDW = {
		{.VPMOVDW, {.XMM_M64,    .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x33, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPMOVDW, {.XMM_M128,   .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x33, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPMOVDW, {.YMM_M256,   .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x33, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPMOVSDW = {
		{.VPMOVSDW, {.XMM_M64,   .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x23, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPMOVSDW, {.XMM_M128,  .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x23, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPMOVSDW, {.YMM_M256,  .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x23, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPMOVUSDW = {
		{.VPMOVUSDW, {.XMM_M64,  .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x13, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPMOVUSDW, {.XMM_M128, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x13, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPMOVUSDW, {.YMM_M256, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x13, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPMOVWB = {
		{.VPMOVWB, {.XMM_M64,    .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x30, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPMOVWB, {.XMM_M128,   .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x30, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPMOVWB, {.YMM_M256,   .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x30, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPMOVSWB = {
		{.VPMOVSWB, {.XMM_M64,   .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x20, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPMOVSWB, {.XMM_M128,  .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x20, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPMOVSWB, {.YMM_M256,  .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x20, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPMOVUSWB = {
		{.VPMOVUSWB, {.XMM_M64,  .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x10, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPMOVUSWB, {.XMM_M128, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x10, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPMOVUSWB, {.YMM_M256, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x10, 0, {esc=._0F38, prefix=PREFIX_F3, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	// AVX-512 rotate instructions
	.VPROLD = {
		{.VPROLD, {.XMM, .XMM_M128, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 1, {modrm_reg_ext=true, esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPROLD, {.YMM, .YMM_M256, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 1, {modrm_reg_ext=true, esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPROLD, {.ZMM, .ZMM_M512, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 1, {modrm_reg_ext=true, esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPROLQ = {
		{.VPROLQ, {.XMM, .XMM_M128, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 1, {modrm_reg_ext=true, esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPROLQ, {.YMM, .YMM_M256, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 1, {modrm_reg_ext=true, esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPROLQ, {.ZMM, .ZMM_M512, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 1, {modrm_reg_ext=true, esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPROLVD = {
		{.VPROLVD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x15, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPROLVD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x15, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPROLVD, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x15, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPROLVQ = {
		{.VPROLVQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x15, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPROLVQ, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x15, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPROLVQ, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x15, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPRORD = {
		{.VPRORD, {.XMM, .XMM_M128, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPRORD, {.YMM, .YMM_M256, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPRORD, {.ZMM, .ZMM_M512, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPRORQ = {
		{.VPRORQ, {.XMM, .XMM_M128, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPRORQ, {.YMM, .YMM_M256, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPRORQ, {.ZMM, .ZMM_M512, .IMM8, .NONE}, {.VVVV, .MR, .IB, .NONE}, 0x72, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPRORVD = {
		{.VPRORVD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x14, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPRORVD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x14, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPRORVD, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x14, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPRORVQ = {
		{.VPRORVQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x14, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPRORVQ, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x14, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPRORVQ, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x14, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	// AVX-512 scatter instructions (use M for VSIB addressing)
	.VPSCATTERDD = {
		{.VPSCATTERDD, {.M, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA0, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPSCATTERDD, {.M, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA0, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPSCATTERDD, {.M, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA0, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPSCATTERDQ = {
		{.VPSCATTERDQ, {.M, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA0, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPSCATTERDQ, {.M, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA0, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPSCATTERDQ, {.M, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA0, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPSCATTERQD = {
		{.VPSCATTERQD, {.M, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA1, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPSCATTERQD, {.M, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA1, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPSCATTERQD, {.M, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA1, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPSCATTERQQ = {
		{.VPSCATTERQQ, {.M, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA1, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPSCATTERQQ, {.M, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA1, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPSCATTERQQ, {.M, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA1, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VSCATTERDPS = {
		{.VSCATTERDPS, {.M, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA2, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VSCATTERDPS, {.M, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA2, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VSCATTERDPS, {.M, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA2, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VSCATTERDPD = {
		{.VSCATTERDPD, {.M, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA2, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VSCATTERDPD, {.M, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA2, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VSCATTERDPD, {.M, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA2, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VSCATTERQPS = {
		{.VSCATTERQPS, {.M, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA3, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VSCATTERQPS, {.M, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA3, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VSCATTERQPS, {.M, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA3, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VSCATTERQPD = {
		{.VSCATTERQPD, {.M, .XMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA3, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VSCATTERQPD, {.M, .YMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA3, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VSCATTERQPD, {.M, .ZMM, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xA3, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	// AVX-512 variable shift instructions
	.VPSRAVQ = {
		{.VPSRAVQ, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x46, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPSRAVQ, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x46, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPSRAVQ, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x46, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPSRAVW = {
		{.VPSRAVW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x11, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPSRAVW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x11, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPSRAVW, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x11, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPSLLVW = {
		{.VPSLLVW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x12, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPSLLVW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x12, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPSLLVW, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x12, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPSRLVW = {
		{.VPSRLVW, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x10, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPSRLVW, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x10, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPSRLVW, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x10, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	// AVX-512 range instructions
	.VRANGEPS = {
		{.VRANGEPS, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x50, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VRANGEPS, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x50, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VRANGEPS, {.ZMM, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x50, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VRANGEPD = {
		{.VRANGEPD, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x50, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VRANGEPD, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x50, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VRANGEPD, {.ZMM, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x50, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VRANGESS = {
		{.VRANGESS, {.XMM, .XMM, .XMM_M32, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x51, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.LIG, vex_w=.W0}},
	},
	.VRANGESD = {
		{.VRANGESD, {.XMM, .XMM, .XMM_M64, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x51, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.LIG, vex_w=.W1}},
	},
	// AVX-512 reduce instructions
	.VREDUCEPS = {
		{.VREDUCEPS, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x56, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VREDUCEPS, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x56, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VREDUCEPS, {.ZMM, .ZMM_M512, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x56, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VREDUCEPD = {
		{.VREDUCEPD, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x56, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VREDUCEPD, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x56, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VREDUCEPD, {.ZMM, .ZMM_M512, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x56, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VREDUCESS = {
		{.VREDUCESS, {.XMM, .XMM, .XMM_M32, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x57, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.LIG, vex_w=.W0}},
	},
	.VREDUCESD = {
		{.VREDUCESD, {.XMM, .XMM, .XMM_M64, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x57, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.LIG, vex_w=.W1}},
	},
	// AVX-512 rndscale instructions
	.VRNDSCALEPS = {
		{.VRNDSCALEPS, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x08, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VRNDSCALEPS, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x08, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VRNDSCALEPS, {.ZMM, .ZMM_M512, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x08, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VRNDSCALEPD = {
		{.VRNDSCALEPD, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x09, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VRNDSCALEPD, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x09, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VRNDSCALEPD, {.ZMM, .ZMM_M512, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x09, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VRNDSCALESS = {
		{.VRNDSCALESS, {.XMM, .XMM, .XMM_M32, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x0A, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.LIG, vex_w=.W0}},
	},
	.VRNDSCALESD = {
		{.VRNDSCALESD, {.XMM, .XMM, .XMM_M64, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x0B, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.LIG, vex_w=.W1}},
	},
	// AVX-512 reciprocal instructions
	.VRSQRT14PS = {
		{.VRSQRT14PS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VRSQRT14PS, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VRSQRT14PS, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VRSQRT14PD = {
		{.VRSQRT14PD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VRSQRT14PD, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VRSQRT14PD, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4E, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VRSQRT14SS = {
		{.VRSQRT14SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x4F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.LIG, vex_w=.W0}},
	},
	.VRSQRT14SD = {
		{.VRSQRT14SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x4F, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.LIG, vex_w=.W1}},
	},
	.VRCP14PS = {
		{.VRCP14PS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VRCP14PS, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VRCP14PS, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VRCP14PD = {
		{.VRCP14PD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VRCP14PD, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VRCP14PD, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x4C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VRCP14SS = {
		{.VRCP14SS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x4D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.LIG, vex_w=.W0}},
	},
	.VRCP14SD = {
		{.VRCP14SD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x4D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.LIG, vex_w=.W1}},
	},
	// AVX-512 scale instructions
	.VSCALEFPS = {
		{.VSCALEFPS, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VSCALEFPS, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VSCALEFPS, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VSCALEFPD = {
		{.VSCALEFPD, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VSCALEFPD, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VSCALEFPD, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2C, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VSCALEFSS = {
		{.VSCALEFSS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.LIG, vex_w=.W0}},
	},
	.VSCALEFSD = {
		{.VSCALEFSD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x2D, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.LIG, vex_w=.W1}},
	},
	// AVX-512 get exponent/mantissa instructions
	.VGETEXPPS = {
		{.VGETEXPPS, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VGETEXPPS, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VGETEXPPS, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VGETEXPPD = {
		{.VGETEXPPD, {.XMM, .XMM_M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VGETEXPPD, {.YMM, .YMM_M256, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VGETEXPPD, {.ZMM, .ZMM_M512, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x42, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VGETEXPSS = {
		{.VGETEXPSS, {.XMM, .XMM, .XMM_M32, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x43, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.LIG, vex_w=.W0}},
	},
	.VGETEXPSD = {
		{.VGETEXPSD, {.XMM, .XMM, .XMM_M64, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x43, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.LIG, vex_w=.W1}},
	},
	.VGETMANTPS = {
		{.VGETMANTPS, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x26, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VGETMANTPS, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x26, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VGETMANTPS, {.ZMM, .ZMM_M512, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x26, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VGETMANTPD = {
		{.VGETMANTPD, {.XMM, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x26, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VGETMANTPD, {.YMM, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x26, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VGETMANTPD, {.ZMM, .ZMM_M512, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x26, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VGETMANTSS = {
		{.VGETMANTSS, {.XMM, .XMM, .XMM_M32, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x27, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.LIG, vex_w=.W0}},
	},
	.VGETMANTSD = {
		{.VGETMANTSD, {.XMM, .XMM, .XMM_M64, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x27, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.LIG, vex_w=.W1}},
	},
	// AVX-512 fixup instructions
	.VFIXUPIMMPS = {
		{.VFIXUPIMMPS, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x54, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VFIXUPIMMPS, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x54, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VFIXUPIMMPS, {.ZMM, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x54, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VFIXUPIMMPD = {
		{.VFIXUPIMMPD, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x54, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VFIXUPIMMPD, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x54, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VFIXUPIMMPD, {.ZMM, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x54, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VFIXUPIMMSS = {
		{.VFIXUPIMMSS, {.XMM, .XMM, .XMM_M32, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x55, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.LIG, vex_w=.W0}},
	},
	.VFIXUPIMMSD = {
		{.VFIXUPIMMSD, {.XMM, .XMM, .XMM_M64, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x55, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.LIG, vex_w=.W1}},
	},
	// AVX-512 fpclass instructions
	.VFPCLASSPS = {
		{.VFPCLASSPS, {.K, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x66, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VFPCLASSPS, {.K, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x66, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VFPCLASSPS, {.K, .ZMM_M512, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x66, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VFPCLASSPD = {
		{.VFPCLASSPD, {.K, .XMM_M128, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x66, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VFPCLASSPD, {.K, .YMM_M256, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x66, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VFPCLASSPD, {.K, .ZMM_M512, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x66, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VFPCLASSSS = {
		{.VFPCLASSSS, {.K, .XMM_M32, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x67, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.LIG, vex_w=.W0}},
	},
	.VFPCLASSSD = {
		{.VFPCLASSSD, {.K, .XMM_M64, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x67, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.LIG, vex_w=.W1}},
	},
	// AVX-512 align and misc instructions
	.VALIGNQ = {
		{.VALIGNQ, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x03, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VALIGNQ, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x03, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VALIGNQ, {.ZMM, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x03, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VALIGND = {
		{.VALIGND, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x03, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VALIGND, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x03, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VALIGND, {.ZMM, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x03, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VDBPSADBW = {
		{.VDBPSADBW, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x42, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VDBPSADBW, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x42, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VDBPSADBW, {.ZMM, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x42, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPTERNLOGD = {
		{.VPTERNLOGD, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x25, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W0}},
		{.VPTERNLOGD, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x25, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W0}},
		{.VPTERNLOGD, {.ZMM, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x25, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W0}},
	},
	.VPTERNLOGQ = {
		{.VPTERNLOGQ, {.XMM, .XMM, .XMM_M128, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x25, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPTERNLOGQ, {.YMM, .YMM, .YMM_M256, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x25, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPTERNLOGQ, {.ZMM, .ZMM, .ZMM_M512, .IMM8}, {.REG, .VVVV, .MR, .IB}, 0x25, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	.VPMULTISHIFTQB = {
		{.VPMULTISHIFTQB, {.XMM, .XMM, .XMM_M128, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x83, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L0, vex_w=.W1}},
		{.VPMULTISHIFTQB, {.YMM, .YMM, .YMM_M256, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x83, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L1, vex_w=.W1}},
		{.VPMULTISHIFTQB, {.ZMM, .ZMM, .ZMM_M512, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x83, 0, {esc=._0F38, prefix=PREFIX_66, vex_type=.EVEX, vex_l=.L2, vex_w=.W1}},
	},
	// Mask register add instructions
	.KADDW = {
		{.KADDW, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x4A, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.KADDB = {
		{.KADDB, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x4A, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.KADDQ = {
		{.KADDQ, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x4A, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.KADDD = {
		{.KADDD, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x4A, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	// Mask register AND instructions
	.KANDW = {
		{.KANDW, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x41, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.KANDB = {
		{.KANDB, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x41, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.KANDQ = {
		{.KANDQ, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x41, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.KANDD = {
		{.KANDD, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x41, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	// Mask register AND NOT instructions
	.KANDNW = {
		{.KANDNW, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x42, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.KANDNB = {
		{.KANDNB, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x42, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.KANDNQ = {
		{.KANDNQ, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x42, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.KANDND = {
		{.KANDND, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x42, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	// Mask register move instructions
	.KMOVW = {
		{.KMOVW, {.K,   .K_M16, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x90, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.KMOVW, {.M16, .K,     .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x91, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.KMOVW, {.K,   .R32,   .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x92, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.KMOVW, {.R32, .K,     .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x93, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
	},
	.KMOVB = {
		{.KMOVB, {.K,   .K_M8,  .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x90, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.KMOVB, {.M8,  .K,     .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x91, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.KMOVB, {.K,   .R32,   .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x92, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.KMOVB, {.R32, .K,     .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x93, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
	},
	.KMOVQ = {
		{.KMOVQ, {.K,   .K_M64, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x90, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.KMOVQ, {.M64, .K,     .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x91, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.KMOVQ, {.K,   .R64,   .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x92, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.KMOVQ, {.R64, .K,     .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x93, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
	},
	.KMOVD = {
		{.KMOVD, {.K,   .K_M32, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x90, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.KMOVD, {.M32, .K,     .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0x91, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
		{.KMOVD, {.K,   .R32,   .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x92, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
		{.KMOVD, {.R32, .K,     .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0x93, 0, {esc=._0F, prefix=PREFIX_F2, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
	},
	// Mask register NOT instructions
	.KNOTW = {
		{.KNOTW, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
	},
	.KNOTB = {
		{.KNOTB, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
	},
	.KNOTQ = {
		{.KNOTQ, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
	},
	.KNOTD = {
		{.KNOTD, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x44, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
	},
	// Mask register OR instructions
	.KORW = {
		{.KORW, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x45, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.KORB = {
		{.KORB, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x45, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.KORQ = {
		{.KORQ, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x45, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.KORD = {
		{.KORD, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x45, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	// Mask register OR test instructions
	.KORTESTW = {
		{.KORTESTW, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x98, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
	},
	.KORTESTB = {
		{.KORTESTB, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x98, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
	},
	.KORTESTQ = {
		{.KORTESTQ, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x98, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
	},
	.KORTESTD = {
		{.KORTESTD, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x98, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
	},
	// Mask register shift left instructions
	.KSHIFTLW = {
		{.KSHIFTLW, {.K, .K, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x32, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
	},
	.KSHIFTLB = {
		{.KSHIFTLB, {.K, .K, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x32, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
	},
	.KSHIFTLQ = {
		{.KSHIFTLQ, {.K, .K, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x33, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
	},
	.KSHIFTLD = {
		{.KSHIFTLD, {.K, .K, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x33, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
	},
	// Mask register shift right instructions
	.KSHIFTRW = {
		{.KSHIFTRW, {.K, .K, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x30, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
	},
	.KSHIFTRB = {
		{.KSHIFTRB, {.K, .K, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x30, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
	},
	.KSHIFTRQ = {
		{.KSHIFTRQ, {.K, .K, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x31, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
	},
	.KSHIFTRD = {
		{.KSHIFTRD, {.K, .K, .IMM8, .NONE}, {.REG, .MR, .IB, .NONE}, 0x31, 0, {esc=._0F3A, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
	},
	// Mask register test instructions
	.KTESTW = {
		{.KTESTW, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x99, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
	},
	.KTESTB = {
		{.KTESTB, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x99, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W0}},
	},
	.KTESTQ = {
		{.KTESTQ, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x99, 0, {esc=._0F, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
	},
	.KTESTD = {
		{.KTESTD, {.K, .K, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x99, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L0, vex_w=.W1}},
	},
	// Mask register unpack instructions
	.KUNPCKBW = {
		{.KUNPCKBW, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x4B, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.KUNPCKWD = {
		{.KUNPCKWD, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x4B, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.KUNPCKDQ = {
		{.KUNPCKDQ, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x4B, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	// Mask register XNOR instructions
	.KXNORW = {
		{.KXNORW, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x46, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.KXNORB = {
		{.KXNORB, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x46, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.KXNORQ = {
		{.KXNORQ, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x46, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.KXNORD = {
		{.KXNORD, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x46, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	// Mask register XOR instructions
	.KXORW = {
		{.KXORW, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x47, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.KXORB = {
		{.KXORB, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x47, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W0}},
	},
	.KXORQ = {
		{.KXORQ, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x47, 0, {esc=._0F, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},
	.KXORD = {
		{.KXORD, {.K, .K, .K, .NONE}, {.REG, .VVVV, .MR, .NONE}, 0x47, 0, {esc=._0F, prefix=PREFIX_66, vex_type=.VEX, vex_l=.L1, vex_w=.W1}},
	},

	// -------------------------------------------------------------------------
	// SECTION: 8.16 x87 FPU Encodings
	// -------------------------------------------------------------------------
	.FADD = {
		{.FADD,   {.M32,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xD8, 0, {}},
		{.FADD,   {.M64,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDC, 0, {}},
		{.FADD,   {.ST0_IMPL, .STI,      .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xD8, 0xC0, {}},
		{.FADD,   {.STI,      .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDC, 0xC0, {}},
	},
	.FADDP = {
		{.FADDP,  {.STI,      .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDE, 0xC0, {}},
		{.FADDP,  {.NONE,     .NONE,     .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDE, 0xC1, {}},
	},
	.FIADD = {
		{.FIADD,  {.M16,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDE, 0, {}},
		{.FIADD,  {.M32,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDA, 0, {}},
	},
	.FSUB = {
		{.FSUB,   {.M32,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xD8, 4, {modrm_reg_ext=true}},
		{.FSUB,   {.M64,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDC, 4, {modrm_reg_ext=true}},
		{.FSUB,   {.ST0_IMPL, .STI,      .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xD8, 0xE0, {}},
		{.FSUB,   {.STI,      .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDC, 0xE8, {}},
	},
	.FSUBP = {
		{.FSUBP,  {.STI,      .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDE, 0xE8, {}},
		{.FSUBP,  {.NONE,     .NONE,     .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDE, 0xE9, {}},
	},
	.FISUB = {
		{.FISUB,  {.M16,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDE, 4, {modrm_reg_ext=true}},
		{.FISUB,  {.M32,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDA, 4, {modrm_reg_ext=true}},
	},
	.FSUBR = {
		{.FSUBR,  {.M32,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xD8, 5, {modrm_reg_ext=true}},
		{.FSUBR,  {.M64,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDC, 5, {modrm_reg_ext=true}},
		{.FSUBR,  {.ST0_IMPL, .STI,      .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xD8, 0xE8, {}},
		{.FSUBR,  {.STI,      .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDC, 0xE0, {}},
	},
	.FSUBRP = {
		{.FSUBRP, {.STI,      .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDE, 0xE0, {}},
		{.FSUBRP, {.NONE,     .NONE,     .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDE, 0xE1, {}},
	},
	.FISUBR = {
		{.FISUBR, {.M16,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDE, 5, {modrm_reg_ext=true}},
		{.FISUBR, {.M32,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDA, 5, {modrm_reg_ext=true}},
	},
	.FMUL = {
		{.FMUL,   {.M32,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xD8, 1, {modrm_reg_ext=true}},
		{.FMUL,   {.M64,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDC, 1, {modrm_reg_ext=true}},
		{.FMUL,   {.ST0_IMPL, .STI,      .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xD8, 0xC8, {}},
		{.FMUL,   {.STI,      .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDC, 0xC8, {}},
	},
	.FMULP = {
		{.FMULP,  {.STI,      .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDE, 0xC8, {}},
		{.FMULP,  {.NONE,     .NONE,     .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDE, 0xC9, {}},
	},
	.FIMUL = {
		{.FIMUL,  {.M16,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDE, 1, {modrm_reg_ext=true}},
		{.FIMUL,  {.M32,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDA, 1, {modrm_reg_ext=true}},
	},
	.FDIV = {
		{.FDIV,   {.M32,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xD8, 6, {modrm_reg_ext=true}},
		{.FDIV,   {.M64,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDC, 6, {modrm_reg_ext=true}},
		{.FDIV,   {.ST0_IMPL, .STI,      .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xD8, 0xF0, {}},
		{.FDIV,   {.STI,      .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDC, 0xF8, {}},
	},
	.FDIVP = {
		{.FDIVP,  {.STI,      .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDE, 0xF8, {}},
		{.FDIVP,  {.NONE,     .NONE,     .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDE, 0xF9, {}},
	},
	.FIDIV = {
		{.FIDIV,  {.M16,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDE, 6, {modrm_reg_ext=true}},
		{.FIDIV,  {.M32,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDA, 6, {modrm_reg_ext=true}},
	},
	.FDIVR = {
		{.FDIVR,  {.M32,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xD8, 7, {modrm_reg_ext=true}},
		{.FDIVR,  {.M64,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDC, 7, {modrm_reg_ext=true}},
		{.FDIVR,  {.ST0_IMPL, .STI,      .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xD8, 0xF8, {}},
		{.FDIVR,  {.STI,      .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDC, 0xF0, {}},
	},
	.FDIVRP = {
		{.FDIVRP, {.STI,      .ST0_IMPL, .NONE, .NONE}, {.OP_R, .IMPL, .NONE, .NONE}, 0xDE, 0xF0, {}},
		{.FDIVRP, {.NONE,     .NONE,     .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDE, 0xF1, {}},
	},
	.FIDIVR = {
		{.FIDIVR, {.M16,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDE, 7, {modrm_reg_ext=true}},
		{.FIDIVR, {.M32,      .NONE,     .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDA, 7, {modrm_reg_ext=true}},
	},
	.FSQRT = {
		{.FSQRT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xFA, {}},
	},
	.FABS = {
		{.FABS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xE1, {}},
	},
	.FCHS = {
		{.FCHS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xE0, {}},
	},
	.FPREM = {
		{.FPREM, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xF8, {}},
	},
	.FPREM1 = {
		{.FPREM1, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xF5, {}},
	},
	.FRNDINT = {
		{.FRNDINT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xFC, {}},
	},
	.FSCALE = {
		{.FSCALE, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xFD, {}},
	},
	.FXTRACT = {
		{.FXTRACT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xF4, {}},
	},
	.FXAM = {
		{.FXAM, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xE5, {}},
	},
	.FLD = {
		{.FLD, {.M32, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xD9, 0, {}},
		{.FLD, {.M64, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDD, 0, {}},
		{.FLD, {.M80, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDB, 5, {modrm_reg_ext=true}},
		{.FLD, {.STI, .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xD9, 0xC0, {}},
	},
	.FILD = {
		{.FILD, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDF, 0, {}},
		{.FILD, {.M32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDB, 0, {}},
		{.FILD, {.M64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDF, 5, {modrm_reg_ext=true}},
	},
	.FBLD = {
		{.FBLD, {.M80, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDF, 4, {modrm_reg_ext=true}},
	},
	.FST = {
		{.FST, {.M32, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xD9, 2, {modrm_reg_ext=true}},
		{.FST, {.M64, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDD, 2, {modrm_reg_ext=true}},
		{.FST, {.STI, .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xDD, 0xD0, {}},
	},
	.FSTP = {
		{.FSTP, {.M32, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xD9, 3, {modrm_reg_ext=true}},
		{.FSTP, {.M64, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDD, 3, {modrm_reg_ext=true}},
		{.FSTP, {.M80, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDB, 7, {modrm_reg_ext=true}},
		{.FSTP, {.STI, .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xDD, 0xD8, {}},
	},
	.FIST = {
		{.FIST, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDF, 2, {modrm_reg_ext=true}},
		{.FIST, {.M32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDB, 2, {modrm_reg_ext=true}},
	},
	.FISTP = {
		{.FISTP, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDF, 3, {modrm_reg_ext=true}},
		{.FISTP, {.M32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDB, 3, {modrm_reg_ext=true}},
		{.FISTP, {.M64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDF, 7, {modrm_reg_ext=true}},
	},
	.FISTTP = {
		{.FISTTP, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDF, 1, {modrm_reg_ext=true}},
		{.FISTTP, {.M32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDB, 1, {modrm_reg_ext=true}},
		{.FISTTP, {.M64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDD, 1, {modrm_reg_ext=true}},
	},
	.FBSTP = {
		{.FBSTP, {.M80, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDF, 6, {modrm_reg_ext=true}},
	},
	.FXCH = {
		{.FXCH, {.STI,  .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xD9, 0xC8, {}},
		{.FXCH, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xC9, {}},
	},
	.FCMOVB = {
		{.FCMOVB, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDA, 0xC0, {}},
	},
	.FCMOVE = {
		{.FCMOVE, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDA, 0xC8, {}},
	},
	.FCMOVBE = {
		{.FCMOVBE, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDA, 0xD0, {}},
	},
	.FCMOVU = {
		{.FCMOVU, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDA, 0xD8, {}},
	},
	.FCMOVNB = {
		{.FCMOVNB, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDB, 0xC0, {}},
	},
	.FCMOVNE = {
		{.FCMOVNE, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDB, 0xC8, {}},
	},
	.FCMOVNBE = {
		{.FCMOVNBE, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDB, 0xD0, {}},
	},
	.FCMOVNU = {
		{.FCMOVNU, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDB, 0xD8, {}},
	},
	.FCOM = {
		{.FCOM, {.M32,  .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xD8, 2, {modrm_reg_ext=true}},
		{.FCOM, {.M64,  .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDC, 2, {modrm_reg_ext=true}},
		{.FCOM, {.STI,  .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xD8, 0xD0, {}},
		{.FCOM, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD8, 0xD1, {}},
	},
	.FCOMP = {
		{.FCOMP, {.M32,  .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xD8, 3, {modrm_reg_ext=true}},
		{.FCOMP, {.M64,  .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDC, 3, {modrm_reg_ext=true}},
		{.FCOMP, {.STI,  .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xD8, 0xD8, {}},
		{.FCOMP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD8, 0xD9, {}},
	},
	.FCOMPP = {
		{.FCOMPP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDE, 0xD9, {}},
	},
	.FICOM = {
		{.FICOM, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDE, 2, {modrm_reg_ext=true}},
		{.FICOM, {.M32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDA, 2, {modrm_reg_ext=true}},
	},
	.FICOMP = {
		{.FICOMP, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDE, 3, {modrm_reg_ext=true}},
		{.FICOMP, {.M32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDA, 3, {modrm_reg_ext=true}},
	},
	.FCOMI = {
		{.FCOMI, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDB, 0xF0, {}},
	},
	.FCOMIP = {
		{.FCOMIP, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDF, 0xF0, {}},
	},
	.FUCOMI = {
		{.FUCOMI, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDB, 0xE8, {}},
	},
	.FUCOMIP = {
		{.FUCOMIP, {.ST0_IMPL, .STI, .NONE, .NONE}, {.IMPL, .OP_R, .NONE, .NONE}, 0xDF, 0xE8, {}},
	},
	.FUCOM = {
		{.FUCOM, {.STI,   .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xDD, 0xE0, {}},
		{.FUCOM, {.NONE,  .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDD, 0xE1, {}},
	},
	.FUCOMP = {
		{.FUCOMP, {.STI,  .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xDD, 0xE8, {}},
		{.FUCOMP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDD, 0xE9, {}},
	},
	.FUCOMPP = {
		{.FUCOMPP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDA, 0xE9, {}},
	},
	.FTST = {
		{.FTST, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xE4, {}},
	},
	.FLDZ = {
		{.FLDZ, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xEE, {}},
	},
	.FLD1 = {
		{.FLD1, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xE8, {}},
	},
	.FLDPI = {
		{.FLDPI, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xEB, {}},
	},
	.FLDL2T = {
		{.FLDL2T, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xE9, {}},
	},
	.FLDL2E = {
		{.FLDL2E, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xEA, {}},
	},
	.FLDLG2 = {
		{.FLDLG2, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xEC, {}},
	},
	.FLDLN2 = {
		{.FLDLN2, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xED, {}},
	},
	.FSIN = {
		{.FSIN, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xFE, {}},
	},
	.FCOS = {
		{.FCOS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xFF, {}},
	},
	.FSINCOS = {
		{.FSINCOS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xFB, {}},
	},
	.FPTAN = {
		{.FPTAN, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xF2, {}},
	},
	.FPATAN = {
		{.FPATAN, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xF3, {}},
	},
	.F2XM1 = {
		{.F2XM1, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xF0, {}},
	},
	.FYL2X = {
		{.FYL2X, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xF1, {}},
	},
	.FYL2XP1 = {
		{.FYL2XP1, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xF9, {}},
	},
	.FINIT = {
		{.FINIT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDB, 0xE3, {}},
	},
	.FNINIT = {
		{.FNINIT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDB, 0xE3, {}},
	},
	.FINCSTP = {
		{.FINCSTP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xF7, {}},
	},
	.FDECSTP = {
		{.FDECSTP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xF6, {}},
	},
	.FFREE = {
		{.FFREE, {.STI, .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xDD, 0xC0, {}},
	},
	.FFREEP = {  // DF C0+i - undocumented, frees ST(i) and pops
		{.FFREEP, {.STI, .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xDF, 0xC0, {}},
	},
	.FNOP = {
		{.FNOP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD9, 0xD0, {}},
	},
	.FWAIT = {
		{.FWAIT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9B, 0, {}},
	},
	.FCLEX = {
		{.FCLEX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDB, 0xE2, {}},
	},
	.FNCLEX = {
		{.FNCLEX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDB, 0xE2, {}},
	},
	.FSTCW = {
		{.FSTCW, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xD9, 7, {modrm_reg_ext=true}},
	},
	.FNSTCW = {
		{.FNSTCW, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xD9, 7, {modrm_reg_ext=true}},
	},
	.FLDCW = {
		{.FLDCW, {.M16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xD9, 5, {modrm_reg_ext=true}},
	},
	.FSTENV = {
		{.FSTENV, {.M, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xD9, 6, {modrm_reg_ext=true}},
	},
	.FNSTENV = {
		{.FNSTENV, {.M, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xD9, 6, {modrm_reg_ext=true}},
	},
	.FLDENV = {
		{.FLDENV, {.M, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xD9, 4, {modrm_reg_ext=true}},
	},
	.FSAVE = {
		{.FSAVE, {.M, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDD, 6, {modrm_reg_ext=true}},
	},
	.FNSAVE = {
		{.FNSAVE, {.M, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDD, 6, {modrm_reg_ext=true}},
	},
	.FRSTOR = {
		{.FRSTOR, {.M, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xDD, 4, {modrm_reg_ext=true}},
	},
	.FSTSW = {
		{.FSTSW, {.M16,     .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDD, 7, {modrm_reg_ext=true}},
		{.FSTSW, {.AX_IMPL, .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0xDF, 0xE0, {}},
	},
	.FNSTSW = {
		{.FNSTSW, {.M16,     .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0xDD, 7, {modrm_reg_ext=true}},
		{.FNSTSW, {.AX_IMPL, .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0xDF, 0xE0, {}},
	},
	.FXSAVE = {
		{.FXSAVE, {.M512, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 0, {esc=._0F, modrm_reg_ext=true}},
	},
	.FXSAVE64 = {
		{.FXSAVE64, {.M512, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 0, {esc=._0F, modrm_reg_ext=true, force_rex_w=true}},
	},
	.FXRSTOR = {
		{.FXRSTOR, {.M512, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 1, {esc=._0F, modrm_reg_ext=true}},
	},
	.FXRSTOR64 = {
		{.FXRSTOR64, {.M512, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 1, {esc=._0F, modrm_reg_ext=true, force_rex_w=true}},
	},

	// -------------------------------------------------------------------------
	// SECTION: 8.17 System Instruction Encodings
	// -------------------------------------------------------------------------
	.LGDT = {
		{.LGDT, {.M16_32, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x01, 2, {esc=._0F, modrm_reg_ext=true}},
		{.LGDT, {.M16_64, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x01, 2, {esc=._0F, modrm_reg_ext=true}},
	},
	.SGDT = {
		{.SGDT, {.M16_32, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x01, 0, {esc=._0F, modrm_reg_ext=true}},
		{.SGDT, {.M16_64, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x01, 0, {esc=._0F, modrm_reg_ext=true}},
	},
	.LIDT = {
		{.LIDT, {.M16_32, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x01, 3, {esc=._0F, modrm_reg_ext=true}},
		{.LIDT, {.M16_64, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x01, 3, {esc=._0F, modrm_reg_ext=true}},
	},
	.SIDT = {
		{.SIDT, {.M16_32, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x01, 1, {esc=._0F, modrm_reg_ext=true}},
		{.SIDT, {.M16_64, .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x01, 1, {esc=._0F, modrm_reg_ext=true}},
	},
	.LLDT = {
		{.LLDT, {.RM16,   .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x00, 2, {esc=._0F, modrm_reg_ext=true}},
	},
	.SLDT = {
		{.SLDT, {.RM16,   .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x00, 0, {esc=._0F, modrm_reg_ext=true}},
		{.SLDT, {.R32,    .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x00, 0, {esc=._0F, modrm_reg_ext=true}},
		{.SLDT, {.R64,    .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x00, 0, {esc=._0F, modrm_reg_ext=true, force_rex_w=true}},
	},
	.LTR = {
		{.LTR,  {.RM16,   .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x00, 3, {esc=._0F, modrm_reg_ext=true}},
	},
	.STR = {
		{.STR,  {.RM16,   .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x00, 1, {esc=._0F, modrm_reg_ext=true}},
		{.STR,  {.R32,    .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x00, 1, {esc=._0F, modrm_reg_ext=true}},
		{.STR,  {.R64,    .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x00, 1, {esc=._0F, modrm_reg_ext=true, force_rex_w=true}},
	},
	.LMSW = {
		{.LMSW, {.RM16,   .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x01, 6, {esc=._0F, modrm_reg_ext=true}},
	},
	.SMSW = {
		{.SMSW, {.RM16,   .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x01, 4, {esc=._0F, modrm_reg_ext=true}},
		{.SMSW, {.R32,    .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x01, 4, {esc=._0F, modrm_reg_ext=true}},
		{.SMSW, {.R64,    .NONE, .NONE, .NONE}, {.MR,   .NONE, .NONE, .NONE}, 0x01, 4, {esc=._0F, modrm_reg_ext=true, force_rex_w=true}},
	},
	.CLTS = {  // 0F 06
		{.CLTS, {.NONE,   .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x06, 0, {esc=._0F}},
	},
	.ARPL = {  // Invalid in 64-bit mode
		{.ARPL, {.RM16,   .R16,  .NONE, .NONE}, {.MR,   .REG,  .NONE, .NONE}, 0x63, 0, {}},
	},
	.LAR = {
		{.LAR,  {.R16,    .RM16, .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x02, 0, {esc=._0F}},
		{.LAR,  {.R32,    .RM32, .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x02, 0, {esc=._0F}},
		{.LAR,  {.R64,    .RM64, .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x02, 0, {esc=._0F, force_rex_w=true}},
	},
	.LSL = {
		{.LSL,  {.R16,    .RM16, .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x03, 0, {esc=._0F}},
		{.LSL,  {.R32,    .RM32, .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x03, 0, {esc=._0F}},
		{.LSL,  {.R64,    .RM64, .NONE, .NONE}, {.REG,  .MR,   .NONE, .NONE}, 0x03, 0, {esc=._0F, force_rex_w=true}},
	},
	.VERR = {
		{.VERR, {.RM16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x00, 4, {esc=._0F, modrm_reg_ext=true}},
	},
	.VERW = {
		{.VERW, {.RM16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x00, 5, {esc=._0F, modrm_reg_ext=true}},
	},
	.INVD = {  // 0F 08
		{.INVD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x08, 0, {esc=._0F}},
	},
	.WBINVD = {  // 0F 09
		{.WBINVD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x09, 0, {esc=._0F}},
	},
	.INVLPG = {
		{.INVLPG, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x01, 7, {esc=._0F, modrm_reg_ext=true}},
	},
	.INVPCID = {
		{.INVPCID, {.R32, .M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x82, 0, {esc=._0F38, prefix=PREFIX_66}},
		{.INVPCID, {.R64, .M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x82, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.RSM = {  // 0F AA
		{.RSM, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAA, 0, {esc=._0F}},
	},
	.RDMSR = {  // 0F 32
		{.RDMSR, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x32, 0, {esc=._0F}},
	},
	.WRMSR = {  // 0F 30
		{.WRMSR, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x30, 0, {esc=._0F}},
	},
	.VMCALL = {  // 0F 01 C1
		{.VMCALL, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xC1, {esc=._0F}},
	},
	.VMLAUNCH = {  // 0F 01 C2
		{.VMLAUNCH, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xC2, {esc=._0F}},
	},
	.VMRESUME = {  // 0F 01 C3
		{.VMRESUME, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xC3, {esc=._0F}},
	},
	.VMXOFF = {  // 0F 01 C4
		{.VMXOFF, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xC4, {esc=._0F}},
	},
	.VMXON = {
		{.VMXON, {.M64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 6, {esc=._0F, modrm_reg_ext=true, prefix=PREFIX_F3}},
	},
	.VMCLEAR = {
		{.VMCLEAR, {.M64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 6, {esc=._0F, modrm_reg_ext=true, prefix=PREFIX_66}},
	},
	.VMPTRLD = {
		{.VMPTRLD, {.M64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 6, {esc=._0F, modrm_reg_ext=true}},
	},
	.VMPTRST = {
		{.VMPTRST, {.M64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 7, {esc=._0F, modrm_reg_ext=true}},
	},
	.VMREAD = {
		{.VMREAD, {.RM64, .R64, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0x78, 0, {esc=._0F}},
	},
	.VMWRITE = {
		{.VMWRITE, {.R64, .RM64, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x79, 0, {esc=._0F}},
	},
	.VMFUNC = {  // 0F 01 D4
		{.VMFUNC, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xD4, {esc=._0F}},
	},
	.INVEPT = {
		{.INVEPT, {.R64, .M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x80, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.INVVPID = {
		{.INVVPID, {.R64, .M128, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x81, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	// -----------------------------------------------------------------------------
	// SECTION: 8.18 Security and Memory Protection Encodings
	// -----------------------------------------------------------------------------
	.ENCLS = {  // 0F 01 CF
		{.ENCLS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xCF, {esc=._0F}},
	},
	.ENCLU = {  // 0F 01 D7
		{.ENCLU, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xD7, {esc=._0F}},
	},
	.ENCLV = {  // 0F 01 C0
		{.ENCLV, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xC0, {esc=._0F}},
	},
	.RDPKRU = {  // 0F 01 EE
		{.RDPKRU, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xEE, {esc=._0F}},
	},
	.WRPKRU = {  // 0F 01 EF
		{.WRPKRU, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xEF, {esc=._0F}},
	},
	.INCSSPD = {  // F3 0F AE /5
		{.INCSSPD, {.R32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 5, {esc=._0F, modrm_reg_ext=true, prefix=PREFIX_F3}},
	},
	.INCSSPQ = {  // F3 REX.W 0F AE /5
		{.INCSSPQ, {.R64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 5, {esc=._0F, modrm_reg_ext=true, prefix=PREFIX_F3, force_rex_w=true}},
	},
	.RDSSPD = {  // F3 0F 1E /1
		{.RDSSPD, {.R32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x1E, 1, {esc=._0F, modrm_reg_ext=true, prefix=PREFIX_F3}},
	},
	.RDSSPQ = {  // F3 REX.W 0F 1E /1
		{.RDSSPQ, {.R64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x1E, 1, {esc=._0F, modrm_reg_ext=true, prefix=PREFIX_F3, force_rex_w=true}},
	},
	.SAVEPREVSSP = {  // F3 0F 01 EA
		{.SAVEPREVSSP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xEA, {esc=._0F, prefix=PREFIX_F3}},
	},
	.RSTORSSP = {  // F3 0F 01 /5
		{.RSTORSSP, {.M64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x01, 5, {esc=._0F, modrm_reg_ext=true, prefix=PREFIX_F3}},
	},
	.WRSSD = {
		{.WRSSD, {.M32, .R32, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xF6, 0, {esc=._0F38}},
	},
	.WRSSQ = {
		{.WRSSQ, {.M64, .R64, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xF6, 0, {esc=._0F38, force_rex_w=true}},
	},
	.WRUSSD = {
		{.WRUSSD, {.M32, .R32, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xF5, 0, {esc=._0F38, prefix=PREFIX_66}},
	},
	.WRUSSQ = {
		{.WRUSSQ, {.M64, .R64, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xF5, 0, {esc=._0F38, prefix=PREFIX_66, force_rex_w=true}},
	},
	.SETSSBSY = {  // F3 0F 01 E8
		{.SETSSBSY, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x01, 0xE8, {esc=._0F, prefix=PREFIX_F3}},
	},
	.CLRSSBSY = {  // F3 0F AE /6
		{.CLRSSBSY, {.M64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 6, {esc=._0F, modrm_reg_ext=true, prefix=PREFIX_F3}},
	},
	.ENDBR64 = {  // F3 0F 1E FA
		{.ENDBR64, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x1E, 0xFA, {esc=._0F, prefix=PREFIX_F3}},
	},
	.ENDBR32 = {  // F3 0F 1E FB
		{.ENDBR32, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x1E, 0xFB, {esc=._0F, prefix=PREFIX_F3}},
	},
	// -----------------------------------------------------------------------------
	// SECTION: 8.19 XSAVE/XRSTOR State Management Encodings
	// -----------------------------------------------------------------------------
	.XSAVE = {
		{.XSAVE, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 4, {esc=._0F, modrm_reg_ext=true}},
	},
	.XSAVE64 = {
		{.XSAVE64, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 4, {esc=._0F, modrm_reg_ext=true, force_rex_w=true}},
	},
	.XRSTOR = {
		{.XRSTOR, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 5, {esc=._0F, modrm_reg_ext=true}},
	},
	.XRSTOR64 = {
		{.XRSTOR64, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 5, {esc=._0F, modrm_reg_ext=true, force_rex_w=true}},
	},
	.XSAVEOPT = {
		{.XSAVEOPT, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 6, {esc=._0F, modrm_reg_ext=true}},
	},
	.XSAVEOPT64 = {
		{.XSAVEOPT64, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 6, {esc=._0F, modrm_reg_ext=true, force_rex_w=true}},
	},
	.XSAVEC = {
		{.XSAVEC, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 4, {esc=._0F, modrm_reg_ext=true}},
	},
	.XSAVEC64 = {
		{.XSAVEC64, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 4, {esc=._0F, modrm_reg_ext=true, force_rex_w=true}},
	},
	.XSAVES = {
		{.XSAVES, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 5, {esc=._0F, modrm_reg_ext=true}},
	},
	.XSAVES64 = {
		{.XSAVES64, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 5, {esc=._0F, modrm_reg_ext=true, force_rex_w=true}},
	},
	.XRSTORS = {
		{.XRSTORS, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 3, {esc=._0F, modrm_reg_ext=true}},
	},
	.XRSTORS64 = {
		{.XRSTORS64, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 3, {esc=._0F, modrm_reg_ext=true, force_rex_w=true}},
	},
	// -----------------------------------------------------------------------------
	// SECTION: 8.20 Cache and Prefetch Encodings
	// -----------------------------------------------------------------------------
	.PREFETCHT0 = {
		{.PREFETCHT0, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x18, 1, {esc=._0F, modrm_reg_ext=true}},
	},
	.PREFETCHT1 = {
		{.PREFETCHT1, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x18, 2, {esc=._0F, modrm_reg_ext=true}},
	},
	.PREFETCHT2 = {
		{.PREFETCHT2, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x18, 3, {esc=._0F, modrm_reg_ext=true}},
	},
	.PREFETCHNTA = {
		{.PREFETCHNTA, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x18, 0, {esc=._0F, modrm_reg_ext=true}},
	},
	.PREFETCHW = {
		{.PREFETCHW, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x0D, 1, {esc=._0F, modrm_reg_ext=true}},
	},
	.CLFLUSHOPT = {
		{.CLFLUSHOPT, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 7, {esc=._0F, modrm_reg_ext=true, prefix=PREFIX_66}},
	},
	.CLWB = {
		{.CLWB, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xAE, 6, {esc=._0F, modrm_reg_ext=true, prefix=PREFIX_66}},
	},
	.CLDEMOTE = {
		{.CLDEMOTE, {.M8, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0x1C, 0, {esc=._0F, modrm_reg_ext=true}},
	},
	// -----------------------------------------------------------------------------
	// SECTION: 8.21 Atomic and Byte Swap Encodings
	// -----------------------------------------------------------------------------
	.BSWAP = {
		{.BSWAP, {.R32, .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xC8, 0, {esc=._0F}},
		{.BSWAP, {.R64, .NONE, .NONE, .NONE}, {.OP_R, .NONE, .NONE, .NONE}, 0xC8, 0, {esc=._0F, force_rex_w=true}},
	},
	.CMPXCHG = {
		{.CMPXCHG, {.RM8 , .R8,  .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xB0, 0, {esc=._0F, lock_ok=true}},
		{.CMPXCHG, {.RM16, .R16, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xB1, 0, {esc=._0F, lock_ok=true}},
		{.CMPXCHG, {.RM32, .R32, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xB1, 0, {esc=._0F, lock_ok=true}},
		{.CMPXCHG, {.RM64, .R64, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xB1, 0, {esc=._0F, lock_ok=true, force_rex_w=true}},
	},
	.CMPXCHG8B = {
		{.CMPXCHG8B, {.M64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 1, {esc=._0F, modrm_reg_ext=true, lock_ok=true}},
	},
	.CMPXCHG16B = {
		{.CMPXCHG16B, {.M128, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 1, {esc=._0F, modrm_reg_ext=true, lock_ok=true, force_rex_w=true}},
	},
	.XADD = {
		{.XADD, {.RM8,  .R8,  .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xC0, 0, {esc=._0F, lock_ok=true}},
		{.XADD, {.RM16, .R16, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xC1, 0, {esc=._0F, lock_ok=true}},
		{.XADD, {.RM32, .R32, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xC1, 0, {esc=._0F, lock_ok=true}},
		{.XADD, {.RM64, .R64, .NONE, .NONE}, {.MR, .REG, .NONE, .NONE}, 0xC1, 0, {esc=._0F, lock_ok=true, force_rex_w=true}},
	},
	// -----------------------------------------------------------------------------
	// SECTION: 8.22 Miscellaneous Encodings
	// -----------------------------------------------------------------------------
	.BOUND = {  // Invalid in 64-bit mode
		{.BOUND, {.R16, .M16_16, .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x62, 0, {mode_32_only=true}},
		{.BOUND, {.R32, .M32,    .NONE, .NONE}, {.REG, .MR, .NONE, .NONE}, 0x62, 0, {mode_32_only=true}},
	},
	.ENTER = {
		{.ENTER, {.IMM16, .IMM8, .NONE, .NONE}, {.IW, .IB, .NONE, .NONE}, 0xC8, 0, {}},
	},
	.LEAVE = {
		{.LEAVE, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xC9, 0, {}},
	},
	.XLAT = {
		{.XLAT, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD7, 0, {}},
	},
	.XLATB = {
		{.XLATB, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD7, 0, {}},
	},
	.MOVBE = {
		{.MOVBE, {.R16, .M16, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0xF0, 0, {esc=._0F38}},
		{.MOVBE, {.R32, .M32, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0xF0, 0, {esc=._0F38}},
		{.MOVBE, {.R64, .M64, .NONE, .NONE}, {.REG, .MR,  .NONE, .NONE}, 0xF0, 0, {esc=._0F38, force_rex_w=true}},
		{.MOVBE, {.M16, .R16, .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0xF1, 0, {esc=._0F38}},
		{.MOVBE, {.M32, .R32, .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0xF1, 0, {esc=._0F38}},
		{.MOVBE, {.M64, .R64, .NONE, .NONE}, {.MR,  .REG, .NONE, .NONE}, 0xF1, 0, {esc=._0F38, force_rex_w=true}},
	},
	.RDRAND = {
		{.RDRAND, {.R16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 6, {esc=._0F, modrm_reg_ext=true}},
		{.RDRAND, {.R32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 6, {esc=._0F, modrm_reg_ext=true}},
		{.RDRAND, {.R64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 6, {esc=._0F, modrm_reg_ext=true, force_rex_w=true}},
	},
	.RDSEED = {
		{.RDSEED, {.R16, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 7, {esc=._0F, modrm_reg_ext=true}},
		{.RDSEED, {.R32, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 7, {esc=._0F, modrm_reg_ext=true}},
		{.RDSEED, {.R64, .NONE, .NONE, .NONE}, {.MR, .NONE, .NONE, .NONE}, 0xC7, 7, {esc=._0F, modrm_reg_ext=true, force_rex_w=true}},
	},
}
