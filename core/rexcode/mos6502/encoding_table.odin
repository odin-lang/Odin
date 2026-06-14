package rexcode_mos6502

// =============================================================================
// MOS 6502 ENCODING_TABLE
// =============================================================================
//
// Indexed by Mnemonic. Each entry is a slice of Encoding forms, one per
// addressing mode (mirrors x86's "one mnemonic, many forms" pattern).
//
// Section layout (each major opcode quadrant):
//   §1  NMOS official     -- 56 mnemonics, 151 opcodes
//   §2  NMOS undocumented -- LAX/SAX/DCP/ISC/RLA/RRA/SLO/SRE + immediates
//   §3  65C02 additions   -- BRA/STZ/INA/DEA/PHX/PHY/PLX/PLY/TRB/TSB/STP/WAI
//                           + RMB0-7/SMB0-7/BBR0-7/BBS0-7
//   §4  HuC6280 (PCE)     -- swap/clear regs, MMR ops, TST, BSR, block xfer
//
// Encoding shape: {mnemonic, {3 ops}, {3 enc}, opcode, length, cpu, flags}
//
//   length is the total byte count of the instruction:
//     1   implied / accumulator
//     2   imm, zp*, rel, (zp,X), (zp),Y, (zp)
//     3   abs*, (abs), (abs,X), BBR/BBS (zp + rel)
//     3   HuC TST # zp, ST0/ST1/ST2, TAM/TMA
//     4   HuC TST # abs
//     7   HuC block transfer
@(rodata)
ENCODING_TABLE: [Mnemonic][]Encoding = #partial {
	.INVALID = {},

	// =========================================================================
	// §1 NMOS official
	// =========================================================================

	// ---- ADC ----------------------------------------------------------------
	.ADC = {
		{.ADC, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x69, 2, .NMOS, {decimal=true}},
		{.ADC, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x65, 2, .NMOS, {decimal=true}},
		{.ADC, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x75, 2, .NMOS, {decimal=true}},
		{.ADC, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x6D, 3, .NMOS, {decimal=true}},
		{.ADC, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x7D, 3, .NMOS, {decimal=true, page_cross=true}},
		{.ADC, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x79, 3, .NMOS, {decimal=true, page_cross=true}},
		{.ADC, {.MEM_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x61, 2, .NMOS, {decimal=true}},
		{.ADC, {.MEM_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x71, 2, .NMOS, {decimal=true, page_cross=true}},
		{.ADC, {.MEM_IND_ZP, .NONE, .NONE, .NONE},{.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x72, 2, .CMOS_65C02, {decimal=true}},
	},

	// ---- AND ----------------------------------------------------------------
	.AND = {
		{.AND, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x29, 2, .NMOS, {}},
		{.AND, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x25, 2, .NMOS, {}},
		{.AND, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x35, 2, .NMOS, {}},
		{.AND, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x2D, 3, .NMOS, {}},
		{.AND, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x3D, 3, .NMOS, {page_cross=true}},
		{.AND, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x39, 3, .NMOS, {page_cross=true}},
		{.AND, {.MEM_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x21, 2, .NMOS, {}},
		{.AND, {.MEM_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x31, 2, .NMOS, {page_cross=true}},
		{.AND, {.MEM_IND_ZP, .NONE, .NONE, .NONE},{.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x32, 2, .CMOS_65C02, {}},
	},

	// ---- ASL ----------------------------------------------------------------
	.ASL = {
		{.ASL, {.A_IMPL, .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0x0A, 1, .NMOS, {}},
		{.ASL, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x06, 2, .NMOS, {}},
		{.ASL, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x16, 2, .NMOS, {}},
		{.ASL, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x0E, 3, .NMOS, {}},
		{.ASL, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x1E, 3, .NMOS, {}},
	},

	// ---- BIT ----------------------------------------------------------------
	.BIT = {
		{.BIT, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x24, 2, .NMOS, {}},
		{.BIT, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x2C, 3, .NMOS, {}},
		// 65C02 additions
		{.BIT, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x89, 2, .CMOS_65C02, {}},
		{.BIT, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x34, 2, .CMOS_65C02, {}},
		{.BIT, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x3C, 3, .CMOS_65C02, {page_cross=true}},
	},

	// ---- Branches (PC-relative) --------------------------------------------
	.BCC = { {.BCC, {.REL, .NONE, .NONE, .NONE}, {.BYTE_1_REL, .NONE, .NONE, .NONE}, 0x90, 2, .NMOS, {cond_branch=true}} },
	.BCS = { {.BCS, {.REL, .NONE, .NONE, .NONE}, {.BYTE_1_REL, .NONE, .NONE, .NONE}, 0xB0, 2, .NMOS, {cond_branch=true}} },
	.BEQ = { {.BEQ, {.REL, .NONE, .NONE, .NONE}, {.BYTE_1_REL, .NONE, .NONE, .NONE}, 0xF0, 2, .NMOS, {cond_branch=true}} },
	.BMI = { {.BMI, {.REL, .NONE, .NONE, .NONE}, {.BYTE_1_REL, .NONE, .NONE, .NONE}, 0x30, 2, .NMOS, {cond_branch=true}} },
	.BNE = { {.BNE, {.REL, .NONE, .NONE, .NONE}, {.BYTE_1_REL, .NONE, .NONE, .NONE}, 0xD0, 2, .NMOS, {cond_branch=true}} },
	.BPL = { {.BPL, {.REL, .NONE, .NONE, .NONE}, {.BYTE_1_REL, .NONE, .NONE, .NONE}, 0x10, 2, .NMOS, {cond_branch=true}} },
	.BVC = { {.BVC, {.REL, .NONE, .NONE, .NONE}, {.BYTE_1_REL, .NONE, .NONE, .NONE}, 0x50, 2, .NMOS, {cond_branch=true}} },
	.BVS = { {.BVS, {.REL, .NONE, .NONE, .NONE}, {.BYTE_1_REL, .NONE, .NONE, .NONE}, 0x70, 2, .NMOS, {cond_branch=true}} },

	// ---- BRK ----------------------------------------------------------------
	.BRK = { {.BRK, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x00, 1, .NMOS, {branch=true}} },

	// ---- Flag clear/set ----------------------------------------------------
	.CLC = { {.CLC, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x18, 1, .NMOS, {}} },
	.CLD = { {.CLD, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD8, 1, .NMOS, {}} },
	.CLI = { {.CLI, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x58, 1, .NMOS, {}} },
	.CLV = { {.CLV, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xB8, 1, .NMOS, {}} },
	.SEC = { {.SEC, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x38, 1, .NMOS, {}} },
	.SED = { {.SED, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF8, 1, .NMOS, {}} },
	.SEI = { {.SEI, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x78, 1, .NMOS, {}} },

	// ---- CMP/CPX/CPY -------------------------------------------------------
	.CMP = {
		{.CMP, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0xC9, 2, .NMOS, {}},
		{.CMP, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xC5, 2, .NMOS, {}},
		{.CMP, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xD5, 2, .NMOS, {}},
		{.CMP, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xCD, 3, .NMOS, {}},
		{.CMP, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xDD, 3, .NMOS, {page_cross=true}},
		{.CMP, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xD9, 3, .NMOS, {page_cross=true}},
		{.CMP, {.MEM_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xC1, 2, .NMOS, {}},
		{.CMP, {.MEM_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xD1, 2, .NMOS, {page_cross=true}},
		{.CMP, {.MEM_IND_ZP, .NONE, .NONE, .NONE},{.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xD2, 2, .CMOS_65C02, {}},
	},
	.CPX = {
		{.CPX, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0xE0, 2, .NMOS, {}},
		{.CPX, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xE4, 2, .NMOS, {}},
		{.CPX, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xEC, 3, .NMOS, {}},
	},
	.CPY = {
		{.CPY, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0xC0, 2, .NMOS, {}},
		{.CPY, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xC4, 2, .NMOS, {}},
		{.CPY, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xCC, 3, .NMOS, {}},
	},

	// ---- DEC / DEX / DEY ---------------------------------------------------
	.DEC = {
		{.DEC, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xC6, 2, .NMOS, {}},
		{.DEC, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xD6, 2, .NMOS, {}},
		{.DEC, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xCE, 3, .NMOS, {}},
		{.DEC, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xDE, 3, .NMOS, {}},
		// 65C02: DEC A (alias DEA)
		{.DEC, {.A_IMPL, .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0x3A, 1, .CMOS_65C02, {}},
	},
	.DEX = { {.DEX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xCA, 1, .NMOS, {}} },
	.DEY = { {.DEY, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x88, 1, .NMOS, {}} },

	// ---- EOR ---------------------------------------------------------------
	.EOR = {
		{.EOR, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x49, 2, .NMOS, {}},
		{.EOR, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x45, 2, .NMOS, {}},
		{.EOR, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x55, 2, .NMOS, {}},
		{.EOR, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x4D, 3, .NMOS, {}},
		{.EOR, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x5D, 3, .NMOS, {page_cross=true}},
		{.EOR, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x59, 3, .NMOS, {page_cross=true}},
		{.EOR, {.MEM_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x41, 2, .NMOS, {}},
		{.EOR, {.MEM_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x51, 2, .NMOS, {page_cross=true}},
		{.EOR, {.MEM_IND_ZP, .NONE, .NONE, .NONE},{.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x52, 2, .CMOS_65C02, {}},
	},

	// ---- INC / INX / INY ---------------------------------------------------
	.INC = {
		{.INC, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xE6, 2, .NMOS, {}},
		{.INC, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xF6, 2, .NMOS, {}},
		{.INC, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xEE, 3, .NMOS, {}},
		{.INC, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xFE, 3, .NMOS, {}},
		// 65C02: INC A (alias INA)
		{.INC, {.A_IMPL, .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0x1A, 1, .CMOS_65C02, {}},
	},
	.INX = { {.INX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xE8, 1, .NMOS, {}} },
	.INY = { {.INY, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xC8, 1, .NMOS, {}} },

	// ---- JMP / JSR / RTI / RTS --------------------------------------------
	.JMP = {
		{.JMP, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x4C, 3, .NMOS, {branch=true}},
		{.JMP, {.MEM_IND, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x6C, 3, .NMOS, {branch=true}},
		// 65C02: JMP ($nnnn,X)
		{.JMP, {.MEM_IND_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x7C, 3, .CMOS_65C02, {branch=true}},
	},
	.JSR = { {.JSR, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x20, 3, .NMOS, {branch=true}} },
	.RTI = { {.RTI, {.NONE, .NONE, .NONE, .NONE},     {.NONE, .NONE, .NONE, .NONE},        0x40, 1, .NMOS, {branch=true}} },
	.RTS = { {.RTS, {.NONE, .NONE, .NONE, .NONE},     {.NONE, .NONE, .NONE, .NONE},        0x60, 1, .NMOS, {branch=true}} },

	// ---- LDA / LDX / LDY ---------------------------------------------------
	.LDA = {
		{.LDA, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0xA9, 2, .NMOS, {}},
		{.LDA, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xA5, 2, .NMOS, {}},
		{.LDA, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xB5, 2, .NMOS, {}},
		{.LDA, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xAD, 3, .NMOS, {}},
		{.LDA, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xBD, 3, .NMOS, {page_cross=true}},
		{.LDA, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xB9, 3, .NMOS, {page_cross=true}},
		{.LDA, {.MEM_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xA1, 2, .NMOS, {}},
		{.LDA, {.MEM_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xB1, 2, .NMOS, {page_cross=true}},
		{.LDA, {.MEM_IND_ZP, .NONE, .NONE, .NONE},{.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xB2, 2, .CMOS_65C02, {}},
	},
	.LDX = {
		{.LDX, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0xA2, 2, .NMOS, {}},
		{.LDX, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xA6, 2, .NMOS, {}},
		{.LDX, {.MEM_ZP_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xB6, 2, .NMOS, {}},
		{.LDX, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xAE, 3, .NMOS, {}},
		{.LDX, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xBE, 3, .NMOS, {page_cross=true}},
	},
	.LDY = {
		{.LDY, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0xA0, 2, .NMOS, {}},
		{.LDY, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xA4, 2, .NMOS, {}},
		{.LDY, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xB4, 2, .NMOS, {}},
		{.LDY, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xAC, 3, .NMOS, {}},
		{.LDY, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xBC, 3, .NMOS, {page_cross=true}},
	},

	// ---- LSR ---------------------------------------------------------------
	.LSR = {
		{.LSR, {.A_IMPL, .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0x4A, 1, .NMOS, {}},
		{.LSR, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x46, 2, .NMOS, {}},
		{.LSR, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x56, 2, .NMOS, {}},
		{.LSR, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x4E, 3, .NMOS, {}},
		{.LSR, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x5E, 3, .NMOS, {}},
	},

	// ---- NOP ---------------------------------------------------------------
	.NOP = { {.NOP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xEA, 1, .NMOS, {}} },

	// ---- ORA ---------------------------------------------------------------
	.ORA = {
		{.ORA, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x09, 2, .NMOS, {}},
		{.ORA, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x05, 2, .NMOS, {}},
		{.ORA, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x15, 2, .NMOS, {}},
		{.ORA, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x0D, 3, .NMOS, {}},
		{.ORA, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x1D, 3, .NMOS, {page_cross=true}},
		{.ORA, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x19, 3, .NMOS, {page_cross=true}},
		{.ORA, {.MEM_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x01, 2, .NMOS, {}},
		{.ORA, {.MEM_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x11, 2, .NMOS, {page_cross=true}},
		{.ORA, {.MEM_IND_ZP, .NONE, .NONE, .NONE},{.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x12, 2, .CMOS_65C02, {}},
	},

	// ---- Stack ops ---------------------------------------------------------
	.PHA = { {.PHA, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x48, 1, .NMOS, {}} },
	.PHP = { {.PHP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x08, 1, .NMOS, {}} },
	.PLA = { {.PLA, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x68, 1, .NMOS, {}} },
	.PLP = { {.PLP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x28, 1, .NMOS, {}} },

	// ---- ROL / ROR ---------------------------------------------------------
	.ROL = {
		{.ROL, {.A_IMPL, .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0x2A, 1, .NMOS, {}},
		{.ROL, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x26, 2, .NMOS, {}},
		{.ROL, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x36, 2, .NMOS, {}},
		{.ROL, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x2E, 3, .NMOS, {}},
		{.ROL, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x3E, 3, .NMOS, {}},
	},
	.ROR = {
		{.ROR, {.A_IMPL, .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0x6A, 1, .NMOS, {}},
		{.ROR, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x66, 2, .NMOS, {}},
		{.ROR, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x76, 2, .NMOS, {}},
		{.ROR, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x6E, 3, .NMOS, {}},
		{.ROR, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x7E, 3, .NMOS, {}},
	},

	// ---- SBC ---------------------------------------------------------------
	.SBC = {
		{.SBC, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0xE9, 2, .NMOS, {decimal=true}},
		{.SBC, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xE5, 2, .NMOS, {decimal=true}},
		{.SBC, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xF5, 2, .NMOS, {decimal=true}},
		{.SBC, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xED, 3, .NMOS, {decimal=true}},
		{.SBC, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xFD, 3, .NMOS, {decimal=true, page_cross=true}},
		{.SBC, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xF9, 3, .NMOS, {decimal=true, page_cross=true}},
		{.SBC, {.MEM_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xE1, 2, .NMOS, {decimal=true}},
		{.SBC, {.MEM_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xF1, 2, .NMOS, {decimal=true, page_cross=true}},
		{.SBC, {.MEM_IND_ZP, .NONE, .NONE, .NONE},{.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xF2, 2, .CMOS_65C02, {decimal=true}},
	},

	// ---- STA / STX / STY ---------------------------------------------------
	.STA = {
		{.STA, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x85, 2, .NMOS, {}},
		{.STA, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x95, 2, .NMOS, {}},
		{.STA, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x8D, 3, .NMOS, {}},
		{.STA, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x9D, 3, .NMOS, {}},
		{.STA, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x99, 3, .NMOS, {}},
		{.STA, {.MEM_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x81, 2, .NMOS, {}},
		{.STA, {.MEM_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x91, 2, .NMOS, {}},
		{.STA, {.MEM_IND_ZP, .NONE, .NONE, .NONE},{.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x92, 2, .CMOS_65C02, {}},
	},
	.STX = {
		{.STX, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x86, 2, .NMOS, {}},
		{.STX, {.MEM_ZP_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x96, 2, .NMOS, {}},
		{.STX, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x8E, 3, .NMOS, {}},
	},
	.STY = {
		{.STY, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x84, 2, .NMOS, {}},
		{.STY, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x94, 2, .NMOS, {}},
		{.STY, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x8C, 3, .NMOS, {}},
	},

	// ---- Transfers ---------------------------------------------------------
	.TAX = { {.TAX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xAA, 1, .NMOS, {}} },
	.TAY = { {.TAY, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xA8, 1, .NMOS, {}} },
	.TSX = { {.TSX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xBA, 1, .NMOS, {}} },
	.TXA = { {.TXA, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x8A, 1, .NMOS, {}} },
	.TXS = { {.TXS, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x9A, 1, .NMOS, {}} },
	.TYA = { {.TYA, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x98, 1, .NMOS, {}} },

	// =========================================================================
	// §2 NMOS undocumented opcodes (commonly used on NES & Apple II)
	// =========================================================================

	// LAX (LDA + LDX) — load A and X simultaneously
	.LAX = {
		{.LAX, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xA7, 2, .NMOS_UNDOC, {}},
		{.LAX, {.MEM_ZP_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xB7, 2, .NMOS_UNDOC, {}},
		{.LAX, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xAF, 3, .NMOS_UNDOC, {}},
		{.LAX, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xBF, 3, .NMOS_UNDOC, {page_cross=true}},
		{.LAX, {.MEM_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xA3, 2, .NMOS_UNDOC, {}},
		{.LAX, {.MEM_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xB3, 2, .NMOS_UNDOC, {page_cross=true}},
	},

	// SAX_NMOS (A & X -> mem)
	.SAX_NMOS = {
		{.SAX_NMOS, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x87, 2, .NMOS_UNDOC, {}},
		{.SAX_NMOS, {.MEM_ZP_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x97, 2, .NMOS_UNDOC, {}},
		{.SAX_NMOS, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x8F, 3, .NMOS_UNDOC, {}},
		{.SAX_NMOS, {.MEM_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x83, 2, .NMOS_UNDOC, {}},
	},

	// DCP (DEC + CMP)
	.DCP = {
		{.DCP, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xC7, 2, .NMOS_UNDOC, {}},
		{.DCP, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xD7, 2, .NMOS_UNDOC, {}},
		{.DCP, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xCF, 3, .NMOS_UNDOC, {}},
		{.DCP, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xDF, 3, .NMOS_UNDOC, {}},
		{.DCP, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xDB, 3, .NMOS_UNDOC, {}},
		{.DCP, {.MEM_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xC3, 2, .NMOS_UNDOC, {}},
		{.DCP, {.MEM_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xD3, 2, .NMOS_UNDOC, {}},
	},

	// ISC / ISB (INC + SBC)
	.ISC = {
		{.ISC, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xE7, 2, .NMOS_UNDOC, {decimal=true}},
		{.ISC, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xF7, 2, .NMOS_UNDOC, {decimal=true}},
		{.ISC, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xEF, 3, .NMOS_UNDOC, {decimal=true}},
		{.ISC, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xFF, 3, .NMOS_UNDOC, {decimal=true}},
		{.ISC, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xFB, 3, .NMOS_UNDOC, {decimal=true}},
		{.ISC, {.MEM_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xE3, 2, .NMOS_UNDOC, {decimal=true}},
		{.ISC, {.MEM_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xF3, 2, .NMOS_UNDOC, {decimal=true}},
	},

	// RLA (ROL + AND)
	.RLA = {
		{.RLA, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x27, 2, .NMOS_UNDOC, {}},
		{.RLA, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x37, 2, .NMOS_UNDOC, {}},
		{.RLA, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x2F, 3, .NMOS_UNDOC, {}},
		{.RLA, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x3F, 3, .NMOS_UNDOC, {}},
		{.RLA, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x3B, 3, .NMOS_UNDOC, {}},
		{.RLA, {.MEM_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x23, 2, .NMOS_UNDOC, {}},
		{.RLA, {.MEM_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x33, 2, .NMOS_UNDOC, {}},
	},

	// RRA (ROR + ADC)
	.RRA = {
		{.RRA, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x67, 2, .NMOS_UNDOC, {decimal=true}},
		{.RRA, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x77, 2, .NMOS_UNDOC, {decimal=true}},
		{.RRA, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x6F, 3, .NMOS_UNDOC, {decimal=true}},
		{.RRA, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x7F, 3, .NMOS_UNDOC, {decimal=true}},
		{.RRA, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x7B, 3, .NMOS_UNDOC, {decimal=true}},
		{.RRA, {.MEM_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x63, 2, .NMOS_UNDOC, {decimal=true}},
		{.RRA, {.MEM_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x73, 2, .NMOS_UNDOC, {decimal=true}},
	},

	// SLO (ASL + ORA)
	.SLO = {
		{.SLO, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x07, 2, .NMOS_UNDOC, {}},
		{.SLO, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x17, 2, .NMOS_UNDOC, {}},
		{.SLO, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x0F, 3, .NMOS_UNDOC, {}},
		{.SLO, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x1F, 3, .NMOS_UNDOC, {}},
		{.SLO, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x1B, 3, .NMOS_UNDOC, {}},
		{.SLO, {.MEM_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x03, 2, .NMOS_UNDOC, {}},
		{.SLO, {.MEM_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x13, 2, .NMOS_UNDOC, {}},
	},

	// SRE (LSR + EOR)
	.SRE = {
		{.SRE, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x47, 2, .NMOS_UNDOC, {}},
		{.SRE, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x57, 2, .NMOS_UNDOC, {}},
		{.SRE, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x4F, 3, .NMOS_UNDOC, {}},
		{.SRE, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x5F, 3, .NMOS_UNDOC, {}},
		{.SRE, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x5B, 3, .NMOS_UNDOC, {}},
		{.SRE, {.MEM_IND_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x43, 2, .NMOS_UNDOC, {}},
		{.SRE, {.MEM_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x53, 2, .NMOS_UNDOC, {}},
	},

	// Immediate-only undocumented opcodes
	.ALR  = { {.ALR,  {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x4B, 2, .NMOS_UNDOC, {}} },
	.ARR  = { {.ARR,  {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x6B, 2, .NMOS_UNDOC, {decimal=true}} },
	.AXS  = { {.AXS,  {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0xCB, 2, .NMOS_UNDOC, {}} },
	.USBC = { {.USBC, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0xEB, 2, .NMOS_UNDOC, {decimal=true}} },
	.LAS  = { {.LAS,  {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0xBB, 3, .NMOS_UNDOC, {page_cross=true}} },
	.ANE  = { {.ANE,  {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x8B, 2, .NMOS_UNDOC, {}} },
	.LXA  = { {.LXA,  {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0xAB, 2, .NMOS_UNDOC, {}} },
	.SHA  = {
		{.SHA, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x9F, 3, .NMOS_UNDOC, {}},
		{.SHA, {.MEM_IND_Y, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x93, 2, .NMOS_UNDOC, {}},
	},
	.SHX  = { {.SHX, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x9E, 3, .NMOS_UNDOC, {}} },
	.SHY  = { {.SHY, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x9C, 3, .NMOS_UNDOC, {}} },
	.TAS  = { {.TAS, {.MEM_ABS_Y, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x9B, 3, .NMOS_UNDOC, {}} },

	// ANC has two opcodes ($0B and $2B); both encode identically semantically.
	// We emit the lower one as the canonical form; both decode to .ANC.
	.ANC  = {
		{.ANC, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x0B, 2, .NMOS_UNDOC, {}},
		{.ANC, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x2B, 2, .NMOS_UNDOC, {}},
	},

	// JAM / KIL / HLT (any of opcodes 02/12/22/32/42/52/62/72/92/B2/D2/F2)
	.JAM = {
		{.JAM, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x02, 1, .NMOS_UNDOC, {}},
		{.JAM, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x12, 1, .NMOS_UNDOC, {}},
		{.JAM, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x22, 1, .NMOS_UNDOC, {}},
		{.JAM, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x32, 1, .NMOS_UNDOC, {}},
		{.JAM, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x42, 1, .NMOS_UNDOC, {}},
		{.JAM, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x52, 1, .NMOS_UNDOC, {}},
		{.JAM, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x62, 1, .NMOS_UNDOC, {}},
		{.JAM, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x72, 1, .NMOS_UNDOC, {}},
		{.JAM, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x92, 1, .NMOS_UNDOC, {}},
		{.JAM, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xB2, 1, .NMOS_UNDOC, {}},
		{.JAM, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD2, 1, .NMOS_UNDOC, {}},
		{.JAM, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF2, 1, .NMOS_UNDOC, {}},
	},

	// DOP / TOP -- "double" and "triple" NOPs (skip 1 / 2 operand bytes).
	// Many opcodes alias to these on NMOS; we pick canonical forms.
	.DOP = {
		{.DOP, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x80, 2, .NMOS_UNDOC, {}},
		{.DOP, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x04, 2, .NMOS_UNDOC, {}},
		{.DOP, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x14, 2, .NMOS_UNDOC, {}},
	},
	.TOP = {
		{.TOP, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x0C, 3, .NMOS_UNDOC, {}},
		{.TOP, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x1C, 3, .NMOS_UNDOC, {page_cross=true}},
	},

	// =========================================================================
	// §3 65C02 additions (Rockwell + WDC)
	// =========================================================================

	.BRA = { {.BRA, {.REL, .NONE, .NONE, .NONE}, {.BYTE_1_REL, .NONE, .NONE, .NONE}, 0x80, 2, .CMOS_65C02, {branch=true}} },

	// INA / DEA are just the implied-A forms of INC / DEC; we list them under
	// INC/DEC above. The standalone mnemonics here let users write `inst_a(.INA)`.
	.INA = { {.INA, {.A_IMPL, .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0x1A, 1, .CMOS_65C02, {}} },
	.DEA = { {.DEA, {.A_IMPL, .NONE, .NONE, .NONE}, {.IMPL, .NONE, .NONE, .NONE}, 0x3A, 1, .CMOS_65C02, {}} },

	.PHX = { {.PHX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDA, 1, .CMOS_65C02, {}} },
	.PHY = { {.PHY, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x5A, 1, .CMOS_65C02, {}} },
	.PLX = { {.PLX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xFA, 1, .CMOS_65C02, {}} },
	.PLY = { {.PLY, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x7A, 1, .CMOS_65C02, {}} },

	.STP = { {.STP, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xDB, 1, .CMOS_65C02, {}} },
	.WAI = { {.WAI, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xCB, 1, .CMOS_65C02, {}} },

	.STZ = {
		{.STZ, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x64, 2, .CMOS_65C02, {}},
		{.STZ, {.MEM_ZP_X, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x74, 2, .CMOS_65C02, {}},
		{.STZ, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x9C, 3, .CMOS_65C02, {}},
		{.STZ, {.MEM_ABS_X, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x9E, 3, .CMOS_65C02, {}},
	},
	.TRB = {
		{.TRB, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x14, 2, .CMOS_65C02, {}},
		{.TRB, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x1C, 3, .CMOS_65C02, {}},
	},
	.TSB = {
		{.TSB, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x04, 2, .CMOS_65C02, {}},
		{.TSB, {.MEM_ABS, .NONE, .NONE, .NONE}, {.WORD_1_ADDR, .NONE, .NONE, .NONE}, 0x0C, 3, .CMOS_65C02, {}},
	},

	// Rockwell/WDC bit ops -- 32 opcodes (RMB/SMB take zp; BBR/BBS take zp + rel).
	.RMB0 = { {.RMB0, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x07, 2, .CMOS_65C02, {}} },
	.RMB1 = { {.RMB1, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x17, 2, .CMOS_65C02, {}} },
	.RMB2 = { {.RMB2, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x27, 2, .CMOS_65C02, {}} },
	.RMB3 = { {.RMB3, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x37, 2, .CMOS_65C02, {}} },
	.RMB4 = { {.RMB4, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x47, 2, .CMOS_65C02, {}} },
	.RMB5 = { {.RMB5, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x57, 2, .CMOS_65C02, {}} },
	.RMB6 = { {.RMB6, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x67, 2, .CMOS_65C02, {}} },
	.RMB7 = { {.RMB7, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x77, 2, .CMOS_65C02, {}} },
	.SMB0 = { {.SMB0, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x87, 2, .CMOS_65C02, {}} },
	.SMB1 = { {.SMB1, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0x97, 2, .CMOS_65C02, {}} },
	.SMB2 = { {.SMB2, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xA7, 2, .CMOS_65C02, {}} },
	.SMB3 = { {.SMB3, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xB7, 2, .CMOS_65C02, {}} },
	.SMB4 = { {.SMB4, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xC7, 2, .CMOS_65C02, {}} },
	.SMB5 = { {.SMB5, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xD7, 2, .CMOS_65C02, {}} },
	.SMB6 = { {.SMB6, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xE7, 2, .CMOS_65C02, {}} },
	.SMB7 = { {.SMB7, {.MEM_ZP, .NONE, .NONE, .NONE}, {.BYTE_1_ADDR, .NONE, .NONE, .NONE}, 0xF7, 2, .CMOS_65C02, {}} },

	.BBR0 = { {.BBR0, {.MEM_ZP, .REL, .NONE, .NONE}, {.BYTE_1_ADDR, .BYTE_2_REL, .NONE, .NONE}, 0x0F, 3, .CMOS_65C02, {cond_branch=true}} },
	.BBR1 = { {.BBR1, {.MEM_ZP, .REL, .NONE, .NONE}, {.BYTE_1_ADDR, .BYTE_2_REL, .NONE, .NONE}, 0x1F, 3, .CMOS_65C02, {cond_branch=true}} },
	.BBR2 = { {.BBR2, {.MEM_ZP, .REL, .NONE, .NONE}, {.BYTE_1_ADDR, .BYTE_2_REL, .NONE, .NONE}, 0x2F, 3, .CMOS_65C02, {cond_branch=true}} },
	.BBR3 = { {.BBR3, {.MEM_ZP, .REL, .NONE, .NONE}, {.BYTE_1_ADDR, .BYTE_2_REL, .NONE, .NONE}, 0x3F, 3, .CMOS_65C02, {cond_branch=true}} },
	.BBR4 = { {.BBR4, {.MEM_ZP, .REL, .NONE, .NONE}, {.BYTE_1_ADDR, .BYTE_2_REL, .NONE, .NONE}, 0x4F, 3, .CMOS_65C02, {cond_branch=true}} },
	.BBR5 = { {.BBR5, {.MEM_ZP, .REL, .NONE, .NONE}, {.BYTE_1_ADDR, .BYTE_2_REL, .NONE, .NONE}, 0x5F, 3, .CMOS_65C02, {cond_branch=true}} },
	.BBR6 = { {.BBR6, {.MEM_ZP, .REL, .NONE, .NONE}, {.BYTE_1_ADDR, .BYTE_2_REL, .NONE, .NONE}, 0x6F, 3, .CMOS_65C02, {cond_branch=true}} },
	.BBR7 = { {.BBR7, {.MEM_ZP, .REL, .NONE, .NONE}, {.BYTE_1_ADDR, .BYTE_2_REL, .NONE, .NONE}, 0x7F, 3, .CMOS_65C02, {cond_branch=true}} },
	.BBS0 = { {.BBS0, {.MEM_ZP, .REL, .NONE, .NONE}, {.BYTE_1_ADDR, .BYTE_2_REL, .NONE, .NONE}, 0x8F, 3, .CMOS_65C02, {cond_branch=true}} },
	.BBS1 = { {.BBS1, {.MEM_ZP, .REL, .NONE, .NONE}, {.BYTE_1_ADDR, .BYTE_2_REL, .NONE, .NONE}, 0x9F, 3, .CMOS_65C02, {cond_branch=true}} },
	.BBS2 = { {.BBS2, {.MEM_ZP, .REL, .NONE, .NONE}, {.BYTE_1_ADDR, .BYTE_2_REL, .NONE, .NONE}, 0xAF, 3, .CMOS_65C02, {cond_branch=true}} },
	.BBS3 = { {.BBS3, {.MEM_ZP, .REL, .NONE, .NONE}, {.BYTE_1_ADDR, .BYTE_2_REL, .NONE, .NONE}, 0xBF, 3, .CMOS_65C02, {cond_branch=true}} },
	.BBS4 = { {.BBS4, {.MEM_ZP, .REL, .NONE, .NONE}, {.BYTE_1_ADDR, .BYTE_2_REL, .NONE, .NONE}, 0xCF, 3, .CMOS_65C02, {cond_branch=true}} },
	.BBS5 = { {.BBS5, {.MEM_ZP, .REL, .NONE, .NONE}, {.BYTE_1_ADDR, .BYTE_2_REL, .NONE, .NONE}, 0xDF, 3, .CMOS_65C02, {cond_branch=true}} },
	.BBS6 = { {.BBS6, {.MEM_ZP, .REL, .NONE, .NONE}, {.BYTE_1_ADDR, .BYTE_2_REL, .NONE, .NONE}, 0xEF, 3, .CMOS_65C02, {cond_branch=true}} },
	.BBS7 = { {.BBS7, {.MEM_ZP, .REL, .NONE, .NONE}, {.BYTE_1_ADDR, .BYTE_2_REL, .NONE, .NONE}, 0xFF, 3, .CMOS_65C02, {cond_branch=true}} },

	// =========================================================================
	// §4 HuC6280 (PC Engine / TurboGrafx-16)
	// =========================================================================

	// Register swap / clear
	.SXY = { {.SXY, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x02, 1, .HUC6280, {}} },
	.SAX = { {.SAX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x22, 1, .HUC6280, {}} },
	.SAY = { {.SAY, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x42, 1, .HUC6280, {}} },
	.CLA = { {.CLA, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x62, 1, .HUC6280, {}} },
	.CLX = { {.CLX, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x82, 1, .HUC6280, {}} },
	.CLY = { {.CLY, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xC2, 1, .HUC6280, {}} },

	// CPU speed
	.CSL = { {.CSL, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x54, 1, .HUC6280, {}} },
	.CSH = { {.CSH, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD4, 1, .HUC6280, {}} },

	// T flag prefix (used by SET to enable T-mode for next instruction)
	.SET = { {.SET, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xF4, 1, .HUC6280, {}} },

	// ST0/1/2 -- write immediate to MMR0/1/2 (2-byte instructions)
	.ST0 = { {.ST0, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x03, 2, .HUC6280, {}} },
	.ST1 = { {.ST1, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x13, 2, .HUC6280, {}} },
	.ST2 = { {.ST2, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x23, 2, .HUC6280, {}} },

	// TAM / TMA -- transfer A to/from MMR selected by immediate (8-bit mask)
	.TAM = { {.TAM, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x53, 2, .HUC6280, {}} },
	.TMA = { {.TMA, {.IMM_8, .NONE, .NONE, .NONE}, {.BYTE_1_IMM, .NONE, .NONE, .NONE}, 0x43, 2, .HUC6280, {}} },

	// TST # imm, addr  -- bit test against memory (3 or 4 bytes)
	.TST = {
		{.TST, {.IMM_8, .MEM_ZP, .NONE, .NONE}, {.BYTE_1_IMM, .BYTE_2_ADDR, .NONE, .NONE}, 0x83, 3, .HUC6280, {}},
		{.TST, {.IMM_8, .MEM_ABS, .NONE, .NONE}, {.BYTE_1_IMM, .WORD_2_ADDR, .NONE, .NONE}, 0x93, 4, .HUC6280, {}},
		{.TST, {.IMM_8, .MEM_ZP_X, .NONE, .NONE}, {.BYTE_1_IMM, .BYTE_2_ADDR, .NONE, .NONE}, 0xA3, 3, .HUC6280, {}},
		{.TST, {.IMM_8, .MEM_ABS_X, .NONE, .NONE}, {.BYTE_1_IMM, .WORD_2_ADDR, .NONE, .NONE}, 0xB3, 4, .HUC6280, {}},
	},

	// BSR -- branch to subroutine, PC-relative
	.BSR = { {.BSR, {.REL, .NONE, .NONE, .NONE}, {.BYTE_1_REL, .NONE, .NONE, .NONE}, 0x44, 2, .HUC6280, {branch=true}} },

	// Block transfer (7 bytes): opcode | src word | dst word | length word
	.TII = { {.TII, {.IMM_16, .IMM_16, .IMM_16, .NONE}, {.WORD_1, .WORD_3, .WORD_5, .NONE}, 0x73, 7, .HUC6280, {}} },
	.TDD = { {.TDD, {.IMM_16, .IMM_16, .IMM_16, .NONE}, {.WORD_1, .WORD_3, .WORD_5, .NONE}, 0xC3, 7, .HUC6280, {}} },
	.TIN = { {.TIN, {.IMM_16, .IMM_16, .IMM_16, .NONE}, {.WORD_1, .WORD_3, .WORD_5, .NONE}, 0xD3, 7, .HUC6280, {}} },
	.TIA = { {.TIA, {.IMM_16, .IMM_16, .IMM_16, .NONE}, {.WORD_1, .WORD_3, .WORD_5, .NONE}, 0xE3, 7, .HUC6280, {}} },
	.TAI = { {.TAI, {.IMM_16, .IMM_16, .IMM_16, .NONE}, {.WORD_1, .WORD_3, .WORD_5, .NONE}, 0xF3, 7, .HUC6280, {}} },
}
