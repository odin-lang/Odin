// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm64_tablegen

// =============================================================================
// AArch64 ENCODING_TABLE (v1: base integer + FP scalar)
// =============================================================================
//
// (bits, mask) model -- same shape as MIPS/RISC-V. `bits` carries the
// static opcode pattern; `mask` covers exactly the bits that are fixed
// by the form. Operand-driven fields (Rd/Rn/Rm/imm*/sh/cond/...) land in
// zero positions of `bits` and are ORed in by the encoder.
//
// Sections (each follows the ARM ARM "C4.1.x Data-processing /" division):
//   §1  Data-processing -- immediate     (Add/Sub imm, Mov-wide, PC-rel)
//   §2  Data-processing -- shifted reg   (Add/Sub/AND/ORR/EOR/BIC/ORN/EON)
//   §3  Data-processing -- extended reg  (Add/Sub extended)
//   §4  Data-processing -- 2-source      (LSLV/LSRV/ASRV/RORV, UDIV/SDIV)
//   §5  Data-processing -- 3-source      (MADD/MSUB/SMADDL/.../UMULH)
//   §6  Data-processing -- 1-source      (CLZ/CLS/RBIT/REV/REV16/REV32)
//   §7  Conditional                      (CSEL/CSINC/CSINV/CSNEG)
//   §8  Branches                         (B/BL/BR/BLR/RET, B.cond, CBZ, TBZ)
//   §9  Loads / stores                   (LDR/STR families, LDP/STP, LDUR)
//   §10 System                           (NOP/HINT/ISB/MSR/MRS/SVC/...)
//   §11 FP scalar                        (FMOV/FADD/FCVT/FCMP/FCSEL/...)
//
// Logical-immediate forms (AND/ORR/EOR/ANDS imm) use the bitmask-
// immediate encoding (N:imms:immr); they're deferred to a follow-up
// turn that adds the bitmask encoder helper.
@(rodata)
ENCODING_TABLE := #partial [Mnemonic][]Encoding{
	.INVALID = {},

	// =========================================================================
	// §1 Data-processing -- immediate
	// =========================================================================
	//
	// ADD/SUB imm12 -- sf:op:S 10001 0 sh imm12 Rn Rd
	//   sh (bit 22) is operand-driven (LSL #0 or LSL #12); v1 callers
	//   typically pass sh=0 by passing imm <= 4095. Mask covers bits[31:23]
	//   (sf, op, S, "10001 0" fixed); sh, imm12, Rn, Rd are operand-driven.

	.ADD_IMM  = {
		{.ADD_IMM,  {.WSP_REG, .WSP_REG, .IMM_12, .NONE}, {.RD, .RN, .IMM12, .NONE}, 0x11000000, 0xFF800000, .BASE, {}},
		{.ADD_IMM,  {.XSP_REG, .XSP_REG, .IMM_12, .NONE}, {.RD, .RN, .IMM12, .NONE}, 0x91000000, 0xFF800000, .BASE, {is_64=true}},
	},
	.ADDS_IMM = {
		{.ADDS_IMM, {.W_REG,   .WSP_REG, .IMM_12, .NONE}, {.RD, .RN, .IMM12, .NONE}, 0x31000000, 0xFF800000, .BASE, {sets_flags=true}},
		{.ADDS_IMM, {.X_REG,   .XSP_REG, .IMM_12, .NONE}, {.RD, .RN, .IMM12, .NONE}, 0xB1000000, 0xFF800000, .BASE, {sets_flags=true, is_64=true}},
	},
	.SUB_IMM  = {
		{.SUB_IMM,  {.WSP_REG, .WSP_REG, .IMM_12, .NONE}, {.RD, .RN, .IMM12, .NONE}, 0x51000000, 0xFF800000, .BASE, {}},
		{.SUB_IMM,  {.XSP_REG, .XSP_REG, .IMM_12, .NONE}, {.RD, .RN, .IMM12, .NONE}, 0xD1000000, 0xFF800000, .BASE, {is_64=true}},
	},
	.SUBS_IMM = {
		{.SUBS_IMM, {.W_REG,   .WSP_REG, .IMM_12, .NONE}, {.RD, .RN, .IMM12, .NONE}, 0x71000000, 0xFF800000, .BASE, {sets_flags=true}},
		{.SUBS_IMM, {.X_REG,   .XSP_REG, .IMM_12, .NONE}, {.RD, .RN, .IMM12, .NONE}, 0xF1000000, 0xFF800000, .BASE, {sets_flags=true, is_64=true}},
	},

	// Move wide -- sf:opc:100101 hw imm16 Rd
	//   opc: 00=MOVN, 10=MOVZ, 11=MOVK
	//   hw (bits 22:21): 0/16/32/48 shift (only 0/16 valid in 32-bit mode)
	//   Mask covers bits[31:23] (sf + opc + fixed "100101")
	.MOVN = {
		{.MOVN, {.W_REG, .IMM_16, .HW_SHIFT, .NONE}, {.RD, .IMM16, .IMM_HW, .NONE}, 0x12800000, 0xFF800000, .BASE, {}},
		{.MOVN, {.X_REG, .IMM_16, .HW_SHIFT, .NONE}, {.RD, .IMM16, .IMM_HW, .NONE}, 0x92800000, 0xFF800000, .BASE, {is_64=true}},
	},
	.MOVZ = {
		{.MOVZ, {.W_REG, .IMM_16, .HW_SHIFT, .NONE}, {.RD, .IMM16, .IMM_HW, .NONE}, 0x52800000, 0xFF800000, .BASE, {}},
		{.MOVZ, {.X_REG, .IMM_16, .HW_SHIFT, .NONE}, {.RD, .IMM16, .IMM_HW, .NONE}, 0xD2800000, 0xFF800000, .BASE, {is_64=true}},
	},
	.MOVK = {
		{.MOVK, {.W_REG, .IMM_16, .HW_SHIFT, .NONE}, {.RD, .IMM16, .IMM_HW, .NONE}, 0x72800000, 0xFF800000, .BASE, {}},
		{.MOVK, {.X_REG, .IMM_16, .HW_SHIFT, .NONE}, {.RD, .IMM16, .IMM_HW, .NONE}, 0xF2800000, 0xFF800000, .BASE, {is_64=true}},
	},

	// PC-relative addressing -- op immlo 10000 immhi Rd
	//   ADR  (op=0): byte target,    ±1MB signed
	//   ADRP (op=1): 4KB-page target, ±4GB signed
	.ADR  = { {.ADR,  {.X_REG, .REL_PG21, .NONE, .NONE}, {.RD, .BRANCH_PG21, .NONE, .NONE}, 0x10000000, 0x9F000000, .BASE, {}} },
	.ADRP = { {.ADRP, {.X_REG, .REL_PG21, .NONE, .NONE}, {.RD, .BRANCH_PG21, .NONE, .NONE}, 0x90000000, 0x9F000000, .BASE, {}} },

	// =========================================================================
	// §2 Data-processing -- shifted register
	// =========================================================================
	//
	// ADD/SUB shifted -- sf:op:S 01011 shift 0 Rm imm6 Rn Rd
	//   shift type at bits 23:22 (LSL/LSR/ASR/ROR), N=0 fixed at bit 21
	//   Mask covers bits[31:29] + [28:24]=01011 + bit[21]=0 = 0xFF200000

	.ADD_SR  = {
		{.ADD_SR,  {.W_REG, .W_REG, .W_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0x0B000000, 0xFF200000, .BASE, {}},
		{.ADD_SR,  {.X_REG, .X_REG, .X_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0x8B000000, 0xFF200000, .BASE, {is_64=true}},
	},
	.ADDS_SR = {
		{.ADDS_SR, {.W_REG, .W_REG, .W_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0x2B000000, 0xFF200000, .BASE, {sets_flags=true}},
		{.ADDS_SR, {.X_REG, .X_REG, .X_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0xAB000000, 0xFF200000, .BASE, {sets_flags=true, is_64=true}},
	},
	.SUB_SR  = {
		{.SUB_SR,  {.W_REG, .W_REG, .W_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0x4B000000, 0xFF200000, .BASE, {}},
		{.SUB_SR,  {.X_REG, .X_REG, .X_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0xCB000000, 0xFF200000, .BASE, {is_64=true}},
	},
	.SUBS_SR = {
		{.SUBS_SR, {.W_REG, .W_REG, .W_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0x6B000000, 0xFF200000, .BASE, {sets_flags=true}},
		{.SUBS_SR, {.X_REG, .X_REG, .X_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0xEB000000, 0xFF200000, .BASE, {sets_flags=true, is_64=true}},
	},

	// Logical shifted register -- sf:opc 01010 shift N Rm imm6 Rn Rd
	//   opc/N pair selects: AND/BIC/ORR/ORN/EOR/EON/ANDS/BICS
	.AND_SR  = {
		{.AND_SR,  {.W_REG, .W_REG, .W_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0x0A000000, 0xFF200000, .BASE, {}},
		{.AND_SR,  {.X_REG, .X_REG, .X_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0x8A000000, 0xFF200000, .BASE, {is_64=true}},
	},
	.BIC_SR  = {
		{.BIC_SR,  {.W_REG, .W_REG, .W_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0x0A200000, 0xFF200000, .BASE, {}},
		{.BIC_SR,  {.X_REG, .X_REG, .X_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0x8A200000, 0xFF200000, .BASE, {is_64=true}},
	},
	.ORR_SR  = {
		{.ORR_SR,  {.W_REG, .W_REG, .W_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0x2A000000, 0xFF200000, .BASE, {}},
		{.ORR_SR,  {.X_REG, .X_REG, .X_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0xAA000000, 0xFF200000, .BASE, {is_64=true}},
	},
	.ORN_SR  = {
		{.ORN_SR,  {.W_REG, .W_REG, .W_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0x2A200000, 0xFF200000, .BASE, {}},
		{.ORN_SR,  {.X_REG, .X_REG, .X_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0xAA200000, 0xFF200000, .BASE, {is_64=true}},
	},
	.EOR_SR  = {
		{.EOR_SR,  {.W_REG, .W_REG, .W_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0x4A000000, 0xFF200000, .BASE, {}},
		{.EOR_SR,  {.X_REG, .X_REG, .X_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0xCA000000, 0xFF200000, .BASE, {is_64=true}},
	},
	.EON_SR  = {
		{.EON_SR,  {.W_REG, .W_REG, .W_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0x4A200000, 0xFF200000, .BASE, {}},
		{.EON_SR,  {.X_REG, .X_REG, .X_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0xCA200000, 0xFF200000, .BASE, {is_64=true}},
	},
	.ANDS_SR = {
		{.ANDS_SR, {.W_REG, .W_REG, .W_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0x6A000000, 0xFF200000, .BASE, {sets_flags=true}},
		{.ANDS_SR, {.X_REG, .X_REG, .X_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0xEA000000, 0xFF200000, .BASE, {sets_flags=true, is_64=true}},
	},
	.BICS_SR = {
		{.BICS_SR, {.W_REG, .W_REG, .W_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0x6A200000, 0xFF200000, .BASE, {sets_flags=true}},
		{.BICS_SR, {.X_REG, .X_REG, .X_SHIFTED, .NONE}, {.RD, .RN, .RM, .NONE}, 0xEA200000, 0xFF200000, .BASE, {sets_flags=true, is_64=true}},
	},

	// =========================================================================
	// §3 Data-processing -- extended register
	// =========================================================================
	//
	// ADD/SUB extended -- sf:op:S 01011 001 Rm option imm3 Rn Rd
	//   bits[28:21] = 01011001 fixed; option at 15:13, imm3 at 12:10
	//   Mask = bits[31:29] + bits[28:21] = 0xFFE00000

	.ADD_ER  = {
		{.ADD_ER,  {.WSP_REG, .WSP_REG, .W_EXTENDED, .NONE}, {.RD, .RN, .RM, .NONE}, 0x0B200000, 0xFFE00000, .BASE, {}},
		{.ADD_ER,  {.XSP_REG, .XSP_REG, .X_EXTENDED, .NONE}, {.RD, .RN, .RM, .NONE}, 0x8B200000, 0xFFE00000, .BASE, {is_64=true}},
	},
	.ADDS_ER = {
		{.ADDS_ER, {.W_REG,   .WSP_REG, .W_EXTENDED, .NONE}, {.RD, .RN, .RM, .NONE}, 0x2B200000, 0xFFE00000, .BASE, {sets_flags=true}},
		{.ADDS_ER, {.X_REG,   .XSP_REG, .X_EXTENDED, .NONE}, {.RD, .RN, .RM, .NONE}, 0xAB200000, 0xFFE00000, .BASE, {sets_flags=true, is_64=true}},
	},
	.SUB_ER  = {
		{.SUB_ER,  {.WSP_REG, .WSP_REG, .W_EXTENDED, .NONE}, {.RD, .RN, .RM, .NONE}, 0x4B200000, 0xFFE00000, .BASE, {}},
		{.SUB_ER,  {.XSP_REG, .XSP_REG, .X_EXTENDED, .NONE}, {.RD, .RN, .RM, .NONE}, 0xCB200000, 0xFFE00000, .BASE, {is_64=true}},
	},
	.SUBS_ER = {
		{.SUBS_ER, {.W_REG,   .WSP_REG, .W_EXTENDED, .NONE}, {.RD, .RN, .RM, .NONE}, 0x6B200000, 0xFFE00000, .BASE, {sets_flags=true}},
		{.SUBS_ER, {.X_REG,   .XSP_REG, .X_EXTENDED, .NONE}, {.RD, .RN, .RM, .NONE}, 0xEB200000, 0xFFE00000, .BASE, {sets_flags=true, is_64=true}},
	},

	// =========================================================================
	// §4 Data-processing -- 2-source (variable shift + division)
	// =========================================================================
	//
	//   sf 0 S 11010110 Rm op2 Rn Rd
	//   Mask covers bits[31:21] + bits[15:10] = 0xFFE0FC00

	.UDIV = {
		{.UDIV, {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1AC00800, 0xFFE0FC00, .BASE, {}},
		{.UDIV, {.X_REG, .X_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x9AC00800, 0xFFE0FC00, .BASE, {is_64=true}},
	},
	.SDIV = {
		{.SDIV, {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1AC00C00, 0xFFE0FC00, .BASE, {}},
		{.SDIV, {.X_REG, .X_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x9AC00C00, 0xFFE0FC00, .BASE, {is_64=true}},
	},
	.LSLV = {
		{.LSLV, {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1AC02000, 0xFFE0FC00, .BASE, {}},
		{.LSLV, {.X_REG, .X_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x9AC02000, 0xFFE0FC00, .BASE, {is_64=true}},
	},
	.LSRV = {
		{.LSRV, {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1AC02400, 0xFFE0FC00, .BASE, {}},
		{.LSRV, {.X_REG, .X_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x9AC02400, 0xFFE0FC00, .BASE, {is_64=true}},
	},
	.ASRV = {
		{.ASRV, {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1AC02800, 0xFFE0FC00, .BASE, {}},
		{.ASRV, {.X_REG, .X_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x9AC02800, 0xFFE0FC00, .BASE, {is_64=true}},
	},
	.RORV = {
		{.RORV, {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1AC02C00, 0xFFE0FC00, .BASE, {}},
		{.RORV, {.X_REG, .X_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x9AC02C00, 0xFFE0FC00, .BASE, {is_64=true}},
	},

	// =========================================================================
	// §5 Data-processing -- 3-source (multiply-accumulate)
	// =========================================================================
	//
	//   sf op54 11011 op31 Rm o0 Ra Rn Rd
	//   Mask = bits[31:21] + bit[15] = 0xFFE08000

	.MADD = {
		{.MADD, {.W_REG, .W_REG, .W_REG, .W_REG}, {.RD, .RN, .RM, .RA}, 0x1B000000, 0xFFE08000, .BASE, {}},
		{.MADD, {.X_REG, .X_REG, .X_REG, .X_REG}, {.RD, .RN, .RM, .RA}, 0x9B000000, 0xFFE08000, .BASE, {is_64=true}},
	},
	.MSUB = {
		{.MSUB, {.W_REG, .W_REG, .W_REG, .W_REG}, {.RD, .RN, .RM, .RA}, 0x1B008000, 0xFFE08000, .BASE, {}},
		{.MSUB, {.X_REG, .X_REG, .X_REG, .X_REG}, {.RD, .RN, .RM, .RA}, 0x9B008000, 0xFFE08000, .BASE, {is_64=true}},
	},
	.SMADDL = { {.SMADDL, {.X_REG, .W_REG, .W_REG, .X_REG}, {.RD, .RN, .RM, .RA}, 0x9B200000, 0xFFE08000, .BASE, {is_64=true}} },
	.SMSUBL = { {.SMSUBL, {.X_REG, .W_REG, .W_REG, .X_REG}, {.RD, .RN, .RM, .RA}, 0x9B208000, 0xFFE08000, .BASE, {is_64=true}} },
	.UMADDL = { {.UMADDL, {.X_REG, .W_REG, .W_REG, .X_REG}, {.RD, .RN, .RM, .RA}, 0x9BA00000, 0xFFE08000, .BASE, {is_64=true}} },
	.UMSUBL = { {.UMSUBL, {.X_REG, .W_REG, .W_REG, .X_REG}, {.RD, .RN, .RM, .RA}, 0x9BA08000, 0xFFE08000, .BASE, {is_64=true}} },
	// SMULH/UMULH have Ra=XZR (=11111) fixed; include in mask.
	.SMULH  = { {.SMULH,  {.X_REG, .X_REG, .X_REG, .NONE},  {.RD, .RN, .RM, .NONE}, 0x9B407C00, 0xFFE0FC00, .BASE, {is_64=true}} },
	.UMULH  = { {.UMULH,  {.X_REG, .X_REG, .X_REG, .NONE},  {.RD, .RN, .RM, .NONE}, 0x9BC07C00, 0xFFE0FC00, .BASE, {is_64=true}} },

	// =========================================================================
	// §6 Data-processing -- 1-source (bit twiddling)
	// =========================================================================
	//
	//   sf 1 S 11010110 op2 op Rn Rd
	//   Mask covers bits[31:10] = 0xFFFFFC00

	.RBIT  = {
		{.RBIT,  {.W_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x5AC00000, 0xFFFFFC00, .BASE, {}},
		{.RBIT,  {.X_REG, .X_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC00000, 0xFFFFFC00, .BASE, {is_64=true}},
	},
	.REV16 = {
		{.REV16, {.W_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x5AC00400, 0xFFFFFC00, .BASE, {}},
		{.REV16, {.X_REG, .X_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC00400, 0xFFFFFC00, .BASE, {is_64=true}},
	},
	.REV   = {
		// 32-bit REV (== REV32 conceptually on 32-bit registers)
		{.REV,   {.W_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x5AC00800, 0xFFFFFC00, .BASE, {}},
		// 64-bit REV (= REV64): op=000011
		{.REV,   {.X_REG, .X_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC00C00, 0xFFFFFC00, .BASE, {is_64=true}},
	},
	.REV32 = { {.REV32, {.X_REG, .X_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC00800, 0xFFFFFC00, .BASE, {is_64=true}} },
	.CLZ   = {
		{.CLZ,   {.W_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x5AC01000, 0xFFFFFC00, .BASE, {}},
		{.CLZ,   {.X_REG, .X_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC01000, 0xFFFFFC00, .BASE, {is_64=true}},
	},
	.CLS   = {
		{.CLS,   {.W_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x5AC01400, 0xFFFFFC00, .BASE, {}},
		{.CLS,   {.X_REG, .X_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC01400, 0xFFFFFC00, .BASE, {is_64=true}},
	},

	// EXTR (immediate-rotate; used by ROR alias)
	//   sf:0:0 10011 1:N 0 Rm imms Rn Rd  (N=sf)
	.EXTR = {
		{.EXTR, {.W_REG, .W_REG, .W_REG, .IMM_6}, {.RD, .RN, .RM, .IMM6}, 0x13800000, 0xFFE08000, .BASE, {}},
		{.EXTR, {.X_REG, .X_REG, .X_REG, .IMM_6}, {.RD, .RN, .RM, .IMM6}, 0x93C00000, 0xFFE08000, .BASE, {is_64=true}},
	},

	// =========================================================================
	// §7 Conditional select
	// =========================================================================
	//
	//   sf op S 11010100 Rm cond op2 Rn Rd
	//   Mask = bits[31:21] + bits[11:10] = 0xFFE00C00

	.CSEL  = {
		{.CSEL,  {.W_REG, .W_REG, .W_REG, .COND}, {.RD, .RN, .RM, .COND_HI}, 0x1A800000, 0xFFE00C00, .BASE, {}},
		{.CSEL,  {.X_REG, .X_REG, .X_REG, .COND}, {.RD, .RN, .RM, .COND_HI}, 0x9A800000, 0xFFE00C00, .BASE, {is_64=true}},
	},
	.CSINC = {
		{.CSINC, {.W_REG, .W_REG, .W_REG, .COND}, {.RD, .RN, .RM, .COND_HI}, 0x1A800400, 0xFFE00C00, .BASE, {}},
		{.CSINC, {.X_REG, .X_REG, .X_REG, .COND}, {.RD, .RN, .RM, .COND_HI}, 0x9A800400, 0xFFE00C00, .BASE, {is_64=true}},
	},
	.CSINV = {
		{.CSINV, {.W_REG, .W_REG, .W_REG, .COND}, {.RD, .RN, .RM, .COND_HI}, 0x5A800000, 0xFFE00C00, .BASE, {}},
		{.CSINV, {.X_REG, .X_REG, .X_REG, .COND}, {.RD, .RN, .RM, .COND_HI}, 0xDA800000, 0xFFE00C00, .BASE, {is_64=true}},
	},
	.CSNEG = {
		{.CSNEG, {.W_REG, .W_REG, .W_REG, .COND}, {.RD, .RN, .RM, .COND_HI}, 0x5A800400, 0xFFE00C00, .BASE, {}},
		{.CSNEG, {.X_REG, .X_REG, .X_REG, .COND}, {.RD, .RN, .RM, .COND_HI}, 0xDA800400, 0xFFE00C00, .BASE, {is_64=true}},
	},

	// =========================================================================
	// §7b Conditional compare (register form)
	// =========================================================================
	//
	//   sf op S 11010010 Rm cond 0 o2 Rn o3 nzcv   (o2 = bit11 = 0 for register)
	//   Mask = bits[31:21] + bits[11:10] + bit[4] = 0xFFE00C10
	//   CCMP op=1 (0x7A/0xFA), CCMN op=0 (0x3A/0xBA); nzcv@3:0, cond@15:12.
	//   (imm5 forms, which place the immediate at bits 20:16, need a new
	//    Operand_Encoding and are added separately.)

	.CCMP_REG = {
		{.CCMP_REG, {.W_REG, .W_REG, .NZCV_IMM, .COND}, {.RN, .RM, .NZCV_FIELD, .COND_HI}, 0x7A400000, 0xFFE00C10, .BASE, {sets_flags=true}},
		{.CCMP_REG, {.X_REG, .X_REG, .NZCV_IMM, .COND}, {.RN, .RM, .NZCV_FIELD, .COND_HI}, 0xFA400000, 0xFFE00C10, .BASE, {sets_flags=true, is_64=true}},
	},
	.CCMN_REG = {
		{.CCMN_REG, {.W_REG, .W_REG, .NZCV_IMM, .COND}, {.RN, .RM, .NZCV_FIELD, .COND_HI}, 0x3A400000, 0xFFE00C10, .BASE, {sets_flags=true}},
		{.CCMN_REG, {.X_REG, .X_REG, .NZCV_IMM, .COND}, {.RN, .RM, .NZCV_FIELD, .COND_HI}, 0xBA400000, 0xFFE00C10, .BASE, {sets_flags=true, is_64=true}},
	},
	// Conditional compare (immediate): imm5 at 20:16 replaces Rm; bit 11 = 1.
	.CCMP_IMM = {
		{.CCMP_IMM, {.W_REG, .IMM_5, .NZCV_IMM, .COND}, {.RN, .IMM5_HI, .NZCV_FIELD, .COND_HI}, 0x7A400800, 0xFFE00C10, .BASE, {sets_flags=true}},
		{.CCMP_IMM, {.X_REG, .IMM_5, .NZCV_IMM, .COND}, {.RN, .IMM5_HI, .NZCV_FIELD, .COND_HI}, 0xFA400800, 0xFFE00C10, .BASE, {sets_flags=true, is_64=true}},
	},
	.CCMN_IMM = {
		{.CCMN_IMM, {.W_REG, .IMM_5, .NZCV_IMM, .COND}, {.RN, .IMM5_HI, .NZCV_FIELD, .COND_HI}, 0x3A400800, 0xFFE00C10, .BASE, {sets_flags=true}},
		{.CCMN_IMM, {.X_REG, .IMM_5, .NZCV_IMM, .COND}, {.RN, .IMM5_HI, .NZCV_FIELD, .COND_HI}, 0xBA400800, 0xFFE00C10, .BASE, {sets_flags=true, is_64=true}},
	},
	// HINT #imm7 (imm at 11:5); NOP/YIELD/etc. are specific values of this.
	.HINT = { {.HINT, {.IMM_8, .NONE, .NONE, .NONE}, {.HINT_FIELD, .NONE, .NONE, .NONE}, 0xD503201F, 0xFFFFF01F, .BASE, {}} },
	// MSR <pstatefield>, #imm: op1:op2 selector (combined) + CRm immediate.
	.MSR_IMM = { {.MSR_IMM, {.SYS_REG, .IMM_4, .NONE, .NONE}, {.MSR_PSTATE, .BARRIER_FIELD, .NONE, .NONE}, 0xD500401F, 0xFFF8F01F, .BASE, {}} },
	// USDOT (unsigned-by-signed dot product, I8MM): Vd.<2S|4S>, Vn.<8B|16B>, Vm.<8B|16B>.
	.USDOT = {
		{.USDOT, {.V_2S, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E809C00, 0xFFE0FC00, .DOT, {}},
		{.USDOT, {.V_4S, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E809C00, 0xFFE0FC00, .DOT, {}},
	},
	// FMOV (immediate): scalar Hd/Sd/Dd, #imm (8-bit float at 20:13).
	.FMOV_IMM = {
		{.FMOV_IMM, {.S_REG, .IMM_8, .NONE, .NONE}, {.RD, .FMOV_SCALAR_IMM, .NONE, .NONE}, 0x1E201000, 0xFFE01FE0, .FP, {}},
		{.FMOV_IMM, {.D_REG, .IMM_8, .NONE, .NONE}, {.RD, .FMOV_SCALAR_IMM, .NONE, .NONE}, 0x1E601000, 0xFFE01FE0, .FP, {}},
		{.FMOV_IMM, {.H_REG, .IMM_8, .NONE, .NONE}, {.RD, .FMOV_SCALAR_IMM, .NONE, .NONE}, 0x1EE01000, 0xFFE01FE0, .FP16, {}},
	},
	// FMOV (vector, immediate): Vd.<T>, #imm (8-bit float in abc:defgh, cmode=1111).
	.FMOV_V_IMM = {
		{.FMOV_V_IMM, {.V_2S, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x0F00F400, 0xFFF8FC00, .NEON, {}},
		{.FMOV_V_IMM, {.V_4S, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x4F00F400, 0xFFF8FC00, .NEON, {}},
		{.FMOV_V_IMM, {.V_2D, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x6F00F400, 0xFFF8FC00, .NEON, {}},
		{.FMOV_V_IMM, {.V_4H_FP16, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x0F00FC00, 0xFFF8FC00, .FP16, {}},
		{.FMOV_V_IMM, {.V_8H_FP16, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x4F00FC00, 0xFFF8FC00, .FP16, {}},
	},

	// =========================================================================
	// Byte / half / signed scalar loads & stores (pre / post / register offset)
	// and vector LDP/STP/LDUR/STUR -- reusing the standard addressing encodings.
	// =========================================================================
	.LDRB_POST = { {.LDRB_POST, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_POST, .NONE, .NONE}, 0x38400400, 0xFFE00C00, .BASE, {}} },
	.LDRB_PRE  = { {.LDRB_PRE,  {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_PRE,  .NONE, .NONE}, 0x38400C00, 0xFFE00C00, .BASE, {}} },
	.LDRB_REG  = { {.LDRB_REG,  {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_REG,       .NONE, .NONE}, 0x38600800, 0xFFE00C00, .BASE, {}} },
	.LDRH_POST = { {.LDRH_POST, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_POST, .NONE, .NONE}, 0x78400400, 0xFFE00C00, .BASE, {}} },
	.LDRH_PRE  = { {.LDRH_PRE,  {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_PRE,  .NONE, .NONE}, 0x78400C00, 0xFFE00C00, .BASE, {}} },
	.LDRH_REG  = { {.LDRH_REG,  {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_REG,       .NONE, .NONE}, 0x78600800, 0xFFE00C00, .BASE, {}} },
	.STRB_POST = { {.STRB_POST, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_POST, .NONE, .NONE}, 0x38000400, 0xFFE00C00, .BASE, {}} },
	.STRB_PRE  = { {.STRB_PRE,  {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_PRE,  .NONE, .NONE}, 0x38000C00, 0xFFE00C00, .BASE, {}} },
	.STRB_REG  = { {.STRB_REG,  {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_REG,       .NONE, .NONE}, 0x38200800, 0xFFE00C00, .BASE, {}} },
	.STRH_POST = { {.STRH_POST, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_POST, .NONE, .NONE}, 0x78000400, 0xFFE00C00, .BASE, {}} },
	.STRH_PRE  = { {.STRH_PRE,  {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_PRE,  .NONE, .NONE}, 0x78000C00, 0xFFE00C00, .BASE, {}} },
	.STRH_REG  = { {.STRH_REG,  {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_REG,       .NONE, .NONE}, 0x78200800, 0xFFE00C00, .BASE, {}} },
	// Signed register-offset loads (sign-extend to W or X).
	.LDRSB_REG = {
		{.LDRSB_REG, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_REG, .NONE, .NONE}, 0x38E00800, 0xFFE00C00, .BASE, {}},
		{.LDRSB_REG, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_REG, .NONE, .NONE}, 0x38A00800, 0xFFE00C00, .BASE, {is_64=true}},
	},
	.LDRSH_REG = {
		{.LDRSH_REG, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_REG, .NONE, .NONE}, 0x78E00800, 0xFFE00C00, .BASE, {}},
		{.LDRSH_REG, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_REG, .NONE, .NONE}, 0x78A00800, 0xFFE00C00, .BASE, {is_64=true}},
	},
	.LDRSW_REG = { {.LDRSW_REG, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_REG, .NONE, .NONE}, 0xB8A00800, 0xFFE00C00, .BASE, {is_64=true}} },
	// Vector load/store pair (S/D/Q) and unscaled (LDUR/STUR).
	.LDP_V = {
		{.LDP_V, {.S_REG, .S_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_S9, .NONE}, 0x2D400000, 0xFFC00000, .NEON, {}},
		{.LDP_V, {.D_REG, .D_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_S9, .NONE}, 0x6D400000, 0xFFC00000, .NEON, {}},
		{.LDP_V, {.Q_REG, .Q_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_S9, .NONE}, 0xAD400000, 0xFFC00000, .NEON, {}},
	},
	.STP_V = {
		{.STP_V, {.S_REG, .S_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_S9, .NONE}, 0x2D000000, 0xFFC00000, .NEON, {}},
		{.STP_V, {.D_REG, .D_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_S9, .NONE}, 0x6D000000, 0xFFC00000, .NEON, {}},
		{.STP_V, {.Q_REG, .Q_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_S9, .NONE}, 0xAD000000, 0xFFC00000, .NEON, {}},
	},
	.LDUR_V = {
		{.LDUR_V, {.S_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xBC400000, 0xFFE00C00, .NEON, {}},
		{.LDUR_V, {.D_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xFC400000, 0xFFE00C00, .NEON, {}},
		{.LDUR_V, {.Q_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x3CC00000, 0xFFE00C00, .NEON, {}},
	},
	.STUR_V = {
		{.STUR_V, {.S_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xBC000000, 0xFFE00C00, .NEON, {}},
		{.STUR_V, {.D_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xFC000000, 0xFFE00C00, .NEON, {}},
		{.STUR_V, {.Q_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x3C800000, 0xFFE00C00, .NEON, {}},
	},

	// =========================================================================
	// §8 Branches
	// =========================================================================

	// Unconditional immediate -- op 00101 imm26
	.B  = { {.B,  {.REL_26, .NONE, .NONE, .NONE}, {.BRANCH_26, .NONE, .NONE, .NONE}, 0x14000000, 0xFC000000, .BASE, {branch=true}} },
	.BL = { {.BL, {.REL_26, .NONE, .NONE, .NONE}, {.BRANCH_26, .NONE, .NONE, .NONE}, 0x94000000, 0xFC000000, .BASE, {branch=true}} },

	// Conditional branch -- 01010100 imm19 0 cond
	//   Mask covers bits 31:24 + bit 4 (the lone static "0" between imm19 and
	//   cond). Bits 23:5 (imm19) and bits 3:0 (cond) are both operand-driven.
	.B_COND = { {.B_COND, {.COND, .REL_19, .NONE, .NONE}, {.COND_LO, .BRANCH_19, .NONE, .NONE},
				 0x54000000, 0xFF000010, .BASE, {cond_branch=true}} },

	// Compare-and-branch -- sf:011010:op:imm19:Rt
	.CBZ  = {
		{.CBZ,  {.W_REG, .REL_19, .NONE, .NONE}, {.RT, .BRANCH_19, .NONE, .NONE}, 0x34000000, 0xFF000000, .BASE, {cond_branch=true}},
		{.CBZ,  {.X_REG, .REL_19, .NONE, .NONE}, {.RT, .BRANCH_19, .NONE, .NONE}, 0xB4000000, 0xFF000000, .BASE, {cond_branch=true, is_64=true}},
	},
	.CBNZ = {
		{.CBNZ, {.W_REG, .REL_19, .NONE, .NONE}, {.RT, .BRANCH_19, .NONE, .NONE}, 0x35000000, 0xFF000000, .BASE, {cond_branch=true}},
		{.CBNZ, {.X_REG, .REL_19, .NONE, .NONE}, {.RT, .BRANCH_19, .NONE, .NONE}, 0xB5000000, 0xFF000000, .BASE, {cond_branch=true, is_64=true}},
	},

	// Test-bit-and-branch -- b5:011011:op:b40:imm14:Rt
	.TBZ  = {
		{.TBZ,  {.X_REG, .IMM_5, .REL_14, .NONE}, {.RT, .TBZ_BIT, .BRANCH_14, .NONE}, 0x36000000, 0x7F000000, .BASE, {cond_branch=true}},
	},
	.TBNZ = {
		{.TBNZ, {.X_REG, .IMM_5, .REL_14, .NONE}, {.RT, .TBZ_BIT, .BRANCH_14, .NONE}, 0x37000000, 0x7F000000, .BASE, {cond_branch=true}},
	},

	// Register indirect -- 11010110 opc 11111 000000 Rn 00000
	//   opc: 0000=BR, 0001=BLR, 0010=RET (with Rn=X30 default if absent)
	.BR  = { {.BR,  {.X_REG, .NONE, .NONE, .NONE}, {.RN, .NONE, .NONE, .NONE}, 0xD61F0000, 0xFFFFFC1F, .BASE, {branch=true, writes_pc=true}} },
	.BLR = { {.BLR, {.X_REG, .NONE, .NONE, .NONE}, {.RN, .NONE, .NONE, .NONE}, 0xD63F0000, 0xFFFFFC1F, .BASE, {branch=true, writes_pc=true}} },
	.RET = {
		{.RET, {.X_REG, .NONE, .NONE, .NONE}, {.RN, .NONE, .NONE, .NONE}, 0xD65F0000, 0xFFFFFC1F, .BASE, {branch=true, writes_pc=true}},
		{.RET, {.NONE,  .NONE, .NONE, .NONE}, {.NONE,.NONE,.NONE,.NONE},   0xD65F03C0, 0xFFFFFFFF, .BASE, {branch=true, writes_pc=true}},
	},

	// =========================================================================
	// §9 Loads / stores (subset: unsigned-offset, unscaled, pre/post, pair, literal)
	// =========================================================================

	// Unsigned-offset (LDR/STR imm12 scaled) -- size 111 001 opc imm12 Rn Rt
	//   Mask = bits[31:22] = 0xFFC00000

	.LDR = {
		// Plain LDR
		{.LDR, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0xB9400000, 0xFFC00000, .BASE, {}},
		{.LDR, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0xF9400000, 0xFFC00000, .BASE, {is_64=true}},
	},
	.STR = {
		{.STR, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0xB9000000, 0xFFC00000, .BASE, {}},
		{.STR, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0xF9000000, 0xFFC00000, .BASE, {is_64=true}},
	},
	.LDRB  = { {.LDRB,  {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0x39400000, 0xFFC00000, .BASE, {}} },
	.STRB  = { {.STRB,  {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0x39000000, 0xFFC00000, .BASE, {}} },
	.LDRSB = {
		// LDRSB Xt: opc=10
		{.LDRSB, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0x39800000, 0xFFC00000, .BASE, {is_64=true}},
		// LDRSB Wt: opc=11
		{.LDRSB, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0x39C00000, 0xFFC00000, .BASE, {}},
	},
	.LDRH  = { {.LDRH,  {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0x79400000, 0xFFC00000, .BASE, {}} },
	.STRH  = { {.STRH,  {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0x79000000, 0xFFC00000, .BASE, {}} },
	.LDRSH = {
		{.LDRSH, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0x79800000, 0xFFC00000, .BASE, {is_64=true}},
		{.LDRSH, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0x79C00000, 0xFFC00000, .BASE, {}},
	},
	.LDRSW = { {.LDRSW, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0xB9800000, 0xFFC00000, .BASE, {is_64=true}} },

	// LDR literal (PC-rel 19-bit signed scaled by 4) -- opc 011 V 00 imm19 Rt
	.LDR_LIT = {
		{.LDR_LIT, {.W_REG, .REL_19, .NONE, .NONE}, {.RT, .BRANCH_19, .NONE, .NONE}, 0x18000000, 0xFF000000, .BASE, {}},
		{.LDR_LIT, {.X_REG, .REL_19, .NONE, .NONE}, {.RT, .BRANCH_19, .NONE, .NONE}, 0x58000000, 0xFF000000, .BASE, {is_64=true}},
	},

	// Load/store pair -- opc 101 V 010 L imm7 Rt2 Rn Rt
	//   Mask covers bits[31:22] for the offset form
	.LDP = {
		{.LDP, {.W_REG, .W_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_S9, .NONE}, 0x29400000, 0xFFC00000, .BASE, {}},
		{.LDP, {.X_REG, .X_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_S9, .NONE}, 0xA9400000, 0xFFC00000, .BASE, {is_64=true}},
	},
	.STP = {
		{.STP, {.W_REG, .W_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_S9, .NONE}, 0x29000000, 0xFFC00000, .BASE, {}},
		{.STP, {.X_REG, .X_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_S9, .NONE}, 0xA9000000, 0xFFC00000, .BASE, {is_64=true}},
	},
	.LDPSW = { {.LDPSW, {.X_REG, .X_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_S9, .NONE}, 0x69400000, 0xFFC00000, .BASE, {is_64=true}} },

	// =========================================================================
	// §10 System
	// =========================================================================
	//
	// HINT space (NOP/YIELD/WFI/WFE/SEV/SEVL): 11010101 00000011 0010 CRm op2 11111

	.NOP   = { {.NOP,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD503201F, 0xFFFFFFFF, .BASE, {}} },
	.YIELD = { {.YIELD, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD503203F, 0xFFFFFFFF, .BASE, {}} },
	.WFE   = { {.WFE,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD503205F, 0xFFFFFFFF, .BASE, {}} },
	.WFI   = { {.WFI,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD503207F, 0xFFFFFFFF, .BASE, {}} },
	.SEV   = { {.SEV,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD503209F, 0xFFFFFFFF, .BASE, {}} },
	.SEVL  = { {.SEVL,  {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD50320BF, 0xFFFFFFFF, .BASE, {}} },

	// Barriers -- 11010101 00000011 0011 CRm opc 11111
	.ISB = { {.ISB, {.IMM_4, .NONE, .NONE, .NONE}, {.BARRIER_FIELD, .NONE, .NONE, .NONE}, 0xD50330DF, 0xFFFFF0FF, .BASE, {}} },
	.DSB = { {.DSB, {.IMM_4, .NONE, .NONE, .NONE}, {.BARRIER_FIELD, .NONE, .NONE, .NONE}, 0xD503309F, 0xFFFFF0FF, .BASE, {}} },
	.DMB = { {.DMB, {.IMM_4, .NONE, .NONE, .NONE}, {.BARRIER_FIELD, .NONE, .NONE, .NONE}, 0xD50330BF, 0xFFFFF0FF, .BASE, {}} },

	// Exception generation -- 11010100 opc imm16 op2 LL
	//   SVC = opc=000, LL=01 -> 0xD4000001
	//   HVC = opc=000, LL=10 -> 0xD4000002
	//   SMC = opc=000, LL=11 -> 0xD4000003
	//   BRK = opc=001, LL=00 -> 0xD4200000
	//   HLT = opc=010, LL=00 -> 0xD4400000
	.SVC = { {.SVC, {.IMM_16, .NONE, .NONE, .NONE}, {.IMM16, .NONE, .NONE, .NONE}, 0xD4000001, 0xFFE0001F, .BASE, {branch=true}} },
	.HVC = { {.HVC, {.IMM_16, .NONE, .NONE, .NONE}, {.IMM16, .NONE, .NONE, .NONE}, 0xD4000002, 0xFFE0001F, .BASE, {branch=true}} },
	.SMC = { {.SMC, {.IMM_16, .NONE, .NONE, .NONE}, {.IMM16, .NONE, .NONE, .NONE}, 0xD4000003, 0xFFE0001F, .BASE, {branch=true}} },
	.BRK = { {.BRK, {.IMM_16, .NONE, .NONE, .NONE}, {.IMM16, .NONE, .NONE, .NONE}, 0xD4200000, 0xFFE0001F, .BASE, {branch=true}} },
	.HLT = { {.HLT, {.IMM_16, .NONE, .NONE, .NONE}, {.IMM16, .NONE, .NONE, .NONE}, 0xD4400000, 0xFFE0001F, .BASE, {branch=true}} },

	// ERET -- 11010110 1001111 1 0000 00 11111 00000
	.ERET = { {.ERET, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD69F03E0, 0xFFFFFFFF, .BASE, {branch=true, writes_pc=true}} },

	// System register access -- MRS Xt, sysreg = 1101010100 1 1 op0 op1 CRn CRm op2 Rt
	//                          MSR sysreg, Xt = 1101010100 0 1 op0 op1 CRn CRm op2 Rt
	//   Mask covers bits[31:20] static (1101010100 1 1 for MRS) + the 5 LSBs left for Rt
	.MRS     = { {.MRS,     {.X_REG, .SYS_REG, .NONE, .NONE}, {.RT, .SYS_FIELD, .NONE, .NONE}, 0xD5300000, 0xFFF00000, .BASE, {}} },
	.MSR_REG = { {.MSR_REG, {.SYS_REG, .X_REG, .NONE, .NONE}, {.SYS_FIELD, .RT, .NONE, .NONE}, 0xD5100000, 0xFFF00000, .BASE, {}} },

	// =========================================================================
	// §11 FP scalar (single + double; half-precision deferred to FP16 turn)
	// =========================================================================
	//
	// OP-FP data-proc 1-source -- 0 0 0 11110 ftype 1 opcode 10000 Rn Rd
	//   ftype: 00=S, 01=D, 11=H (FP16, deferred)

	.FABS = {
		{.FABS, {.S_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E20C000, 0xFFFFFC00, .FP, {}},
		{.FABS, {.D_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E60C000, 0xFFFFFC00, .FP, {}},
	},
	.FNEG = {
		{.FNEG, {.S_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E214000, 0xFFFFFC00, .FP, {}},
		{.FNEG, {.D_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E614000, 0xFFFFFC00, .FP, {}},
	},
	.FSQRT = {
		{.FSQRT, {.S_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E21C000, 0xFFFFFC00, .FP, {}},
		{.FSQRT, {.D_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E61C000, 0xFFFFFC00, .FP, {}},
	},

	// OP-FP 2-source -- 0 0 0 11110 ftype 1 Rm opcode 10 Rn Rd
	.FADD = {
		{.FADD, {.S_REG, .S_REG, .S_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1E202800, 0xFFE0FC00, .FP, {}},
		{.FADD, {.D_REG, .D_REG, .D_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1E602800, 0xFFE0FC00, .FP, {}},
	},
	.FSUB = {
		{.FSUB, {.S_REG, .S_REG, .S_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1E203800, 0xFFE0FC00, .FP, {}},
		{.FSUB, {.D_REG, .D_REG, .D_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1E603800, 0xFFE0FC00, .FP, {}},
	},
	.FMUL = {
		{.FMUL, {.S_REG, .S_REG, .S_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1E200800, 0xFFE0FC00, .FP, {}},
		{.FMUL, {.D_REG, .D_REG, .D_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1E600800, 0xFFE0FC00, .FP, {}},
	},
	.FDIV = {
		{.FDIV, {.S_REG, .S_REG, .S_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1E201800, 0xFFE0FC00, .FP, {}},
		{.FDIV, {.D_REG, .D_REG, .D_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1E601800, 0xFFE0FC00, .FP, {}},
	},
	.FNMUL = {
		{.FNMUL, {.S_REG, .S_REG, .S_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1E208800, 0xFFE0FC00, .FP, {}},
		{.FNMUL, {.D_REG, .D_REG, .D_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1E608800, 0xFFE0FC00, .FP, {}},
	},
	.FMAX = {
		{.FMAX, {.S_REG, .S_REG, .S_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1E204800, 0xFFE0FC00, .FP, {}},
		{.FMAX, {.D_REG, .D_REG, .D_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1E604800, 0xFFE0FC00, .FP, {}},
	},
	.FMIN = {
		{.FMIN, {.S_REG, .S_REG, .S_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1E205800, 0xFFE0FC00, .FP, {}},
		{.FMIN, {.D_REG, .D_REG, .D_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1E605800, 0xFFE0FC00, .FP, {}},
	},
	.FMAXNM = {
		{.FMAXNM, {.S_REG, .S_REG, .S_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1E206800, 0xFFE0FC00, .FP, {}},
		{.FMAXNM, {.D_REG, .D_REG, .D_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1E606800, 0xFFE0FC00, .FP, {}},
	},
	.FMINNM = {
		{.FMINNM, {.S_REG, .S_REG, .S_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1E207800, 0xFFE0FC00, .FP, {}},
		{.FMINNM, {.D_REG, .D_REG, .D_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1E607800, 0xFFE0FC00, .FP, {}},
	},

	// OP-FP 3-source (FMADD/FMSUB/FNMADD/FNMSUB) -- 0 0 0 11111 ftype o1 Rm o0 Ra Rn Rd
	.FMADD  = {
		{.FMADD,  {.S_REG, .S_REG, .S_REG, .S_REG}, {.RD, .RN, .RM, .RA}, 0x1F000000, 0xFFE08000, .FP, {}},
		{.FMADD,  {.D_REG, .D_REG, .D_REG, .D_REG}, {.RD, .RN, .RM, .RA}, 0x1F400000, 0xFFE08000, .FP, {}},
	},
	.FMSUB  = {
		{.FMSUB,  {.S_REG, .S_REG, .S_REG, .S_REG}, {.RD, .RN, .RM, .RA}, 0x1F008000, 0xFFE08000, .FP, {}},
		{.FMSUB,  {.D_REG, .D_REG, .D_REG, .D_REG}, {.RD, .RN, .RM, .RA}, 0x1F408000, 0xFFE08000, .FP, {}},
	},
	.FNMADD = {
		{.FNMADD, {.S_REG, .S_REG, .S_REG, .S_REG}, {.RD, .RN, .RM, .RA}, 0x1F200000, 0xFFE08000, .FP, {}},
		{.FNMADD, {.D_REG, .D_REG, .D_REG, .D_REG}, {.RD, .RN, .RM, .RA}, 0x1F600000, 0xFFE08000, .FP, {}},
	},
	.FNMSUB = {
		{.FNMSUB, {.S_REG, .S_REG, .S_REG, .S_REG}, {.RD, .RN, .RM, .RA}, 0x1F208000, 0xFFE08000, .FP, {}},
		{.FNMSUB, {.D_REG, .D_REG, .D_REG, .D_REG}, {.RD, .RN, .RM, .RA}, 0x1F608000, 0xFFE08000, .FP, {}},
	},

	// FP compare -- 0 0 0 11110 ftype 1 Rm 0 0 1000 Rn opc opc opc 0 0 0
	.FCMP = {
		{.FCMP,  {.S_REG, .S_REG, .NONE, .NONE}, {.RN, .RM, .NONE, .NONE}, 0x1E202000, 0xFFE0FC1F, .FP, {sets_flags=true}},
		{.FCMP,  {.D_REG, .D_REG, .NONE, .NONE}, {.RN, .RM, .NONE, .NONE}, 0x1E602000, 0xFFE0FC1F, .FP, {sets_flags=true}},
	},
	.FCMPE = {
		{.FCMPE, {.S_REG, .S_REG, .NONE, .NONE}, {.RN, .RM, .NONE, .NONE}, 0x1E202010, 0xFFE0FC1F, .FP, {sets_flags=true}},
		{.FCMPE, {.D_REG, .D_REG, .NONE, .NONE}, {.RN, .RM, .NONE, .NONE}, 0x1E602010, 0xFFE0FC1F, .FP, {sets_flags=true}},
	},

	// FCSEL -- 0 0 0 11110 ftype 1 Rm cond 1 1 Rn Rd
	.FCSEL = {
		{.FCSEL, {.S_REG, .S_REG, .S_REG, .COND}, {.RD, .RN, .RM, .COND_HI}, 0x1E200C00, 0xFFE00C00, .FP, {}},
		{.FCSEL, {.D_REG, .D_REG, .D_REG, .COND}, {.RD, .RN, .RM, .COND_HI}, 0x1E600C00, 0xFFE00C00, .FP, {}},
	},

	// FP -> FP conversion -- 0 0 0 11110 ftype 1 0001 opc 10000 Rn Rd
	//   opc selects target type. We expose three common variants:
	//     FCVT D <- S : 0x1E22C000  (ftype=00 src=S, opc=01 dst=D)
	//     FCVT S <- D : 0x1E624000  (ftype=01 src=D, opc=00 dst=S)
	.FCVT = {
		{.FCVT, {.D_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E22C000, 0xFFFFFC00, .FP, {}},
		{.FCVT, {.S_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E624000, 0xFFFFFC00, .FP, {}},
	},

	// Int<->FP conversions -- sf 0 0 11110 ftype 1 rmode opc 000000 Rn Rd
	//   SCVTF/UCVTF: int -> FP. rmode=00, opc=010(SCVTF)/011(UCVTF)
	//   FCVTZS/FCVTZU: FP -> int (round toward zero). rmode=11, opc=000/001
	.SCVTF = {
		{.SCVTF, {.S_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E220000, 0xFFFFFC00, .FP, {}},
		{.SCVTF, {.D_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E620000, 0xFFFFFC00, .FP, {}},
		{.SCVTF, {.S_REG, .X_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E220000, 0xFFFFFC00, .FP, {is_64=true}},
		{.SCVTF, {.D_REG, .X_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E620000, 0xFFFFFC00, .FP, {is_64=true}},
	},
	.UCVTF = {
		{.UCVTF, {.S_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E230000, 0xFFFFFC00, .FP, {}},
		{.UCVTF, {.D_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E630000, 0xFFFFFC00, .FP, {}},
		{.UCVTF, {.S_REG, .X_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E230000, 0xFFFFFC00, .FP, {is_64=true}},
		{.UCVTF, {.D_REG, .X_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E630000, 0xFFFFFC00, .FP, {is_64=true}},
	},
	.FCVTZS = {
		{.FCVTZS, {.W_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E380000, 0xFFFFFC00, .FP, {}},
		{.FCVTZS, {.W_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E780000, 0xFFFFFC00, .FP, {}},
		{.FCVTZS, {.X_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E380000, 0xFFFFFC00, .FP, {is_64=true}},
		{.FCVTZS, {.X_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E780000, 0xFFFFFC00, .FP, {is_64=true}},
	},
	.FCVTZU = {
		{.FCVTZU, {.W_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E390000, 0xFFFFFC00, .FP, {}},
		{.FCVTZU, {.W_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E790000, 0xFFFFFC00, .FP, {}},
		{.FCVTZU, {.X_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E390000, 0xFFFFFC00, .FP, {is_64=true}},
		{.FCVTZU, {.X_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E790000, 0xFFFFFC00, .FP, {is_64=true}},
	},

	// FMOV -- three flavours: reg<->reg same type, GPR<->FP, immediate
	//   v1 covers reg-reg + GPR<->FP (the most common). FP-immediate
	//   uses an 8-bit encoded constant and is deferred.
	.FMOV_REG = {
		{.FMOV_REG, {.S_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E204000, 0xFFFFFC00, .FP, {}},
		{.FMOV_REG, {.D_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E604000, 0xFFFFFC00, .FP, {}},
	},
	.FMOV_GEN = {
		// W<->S, X<->D in both directions.
		// FMOV Wd, Sn:  sf=0 ftype=00 rmode=00 opc=110 -> 0x1E260000
		// FMOV Sd, Wn:  sf=0 ftype=00 rmode=00 opc=111 -> 0x1E270000
		// FMOV Xd, Dn:  sf=1 ftype=01 rmode=00 opc=110 -> 0x9E660000
		// FMOV Dd, Xn:  sf=1 ftype=01 rmode=00 opc=111 -> 0x9E670000
		{.FMOV_GEN, {.W_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E260000, 0xFFFFFC00, .FP, {}},
		{.FMOV_GEN, {.S_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E270000, 0xFFFFFC00, .FP, {}},
		{.FMOV_GEN, {.X_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E660000, 0xFFFFFC00, .FP, {is_64=true}},
		{.FMOV_GEN, {.D_REG, .X_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E670000, 0xFFFFFC00, .FP, {is_64=true}},
	},

	// =========================================================================
	// §12 Logical immediate (bitmask-encoded N:imms:immr)
	// =========================================================================
	//   sf:opc 100100 N immr imms Rn Rd
	//   opc: 00=AND, 01=ORR, 10=EOR, 11=ANDS
	//   The user passes a pre-encoded 13-bit value (N<<12 | immr<<6 | imms)
	//   in the IMMEDIATE; bitmask_encode() in bitmask.odin computes it
	//   from a raw 32/64-bit immediate.
	//   Mask covers sf + opc + 100100 + (for 32-bit) N=0 = 0xFF800000 / 0x7F800000.

	.AND_IMM  = {
		{.AND_IMM,  {.WSP_REG, .W_REG, .BITMASK_IMM, .NONE}, {.RD, .RN, .BITMASK_FIELD, .NONE}, 0x12000000, 0xFFC00000, .BASE, {}},
		{.AND_IMM,  {.XSP_REG, .X_REG, .BITMASK_IMM, .NONE}, {.RD, .RN, .BITMASK_FIELD, .NONE}, 0x92000000, 0xFF800000, .BASE, {is_64=true}},
	},
	.ORR_IMM  = {
		{.ORR_IMM,  {.WSP_REG, .W_REG, .BITMASK_IMM, .NONE}, {.RD, .RN, .BITMASK_FIELD, .NONE}, 0x32000000, 0xFFC00000, .BASE, {}},
		{.ORR_IMM,  {.XSP_REG, .X_REG, .BITMASK_IMM, .NONE}, {.RD, .RN, .BITMASK_FIELD, .NONE}, 0xB2000000, 0xFF800000, .BASE, {is_64=true}},
	},
	.EOR_IMM  = {
		{.EOR_IMM,  {.WSP_REG, .W_REG, .BITMASK_IMM, .NONE}, {.RD, .RN, .BITMASK_FIELD, .NONE}, 0x52000000, 0xFFC00000, .BASE, {}},
		{.EOR_IMM,  {.XSP_REG, .X_REG, .BITMASK_IMM, .NONE}, {.RD, .RN, .BITMASK_FIELD, .NONE}, 0xD2000000, 0xFF800000, .BASE, {is_64=true}},
	},
	.ANDS_IMM = {
		{.ANDS_IMM, {.W_REG,   .W_REG, .BITMASK_IMM, .NONE}, {.RD, .RN, .BITMASK_FIELD, .NONE}, 0x72000000, 0xFFC00000, .BASE, {sets_flags=true}},
		{.ANDS_IMM, {.X_REG,   .X_REG, .BITMASK_IMM, .NONE}, {.RD, .RN, .BITMASK_FIELD, .NONE}, 0xF2000000, 0xFF800000, .BASE, {sets_flags=true, is_64=true}},
	},
	// TST is the ANDS_IMM alias with Rd=ZR; we emit explicit bits with Rd=31.
	.TST_IMM  = {
		{.TST_IMM,  {.W_REG, .BITMASK_IMM, .NONE, .NONE}, {.RN, .BITMASK_FIELD, .NONE, .NONE}, 0x7200001F, 0xFFC0001F, .BASE, {sets_flags=true}},
		{.TST_IMM,  {.X_REG, .BITMASK_IMM, .NONE, .NONE}, {.RN, .BITMASK_FIELD, .NONE, .NONE}, 0xF200001F, 0xFF80001F, .BASE, {sets_flags=true, is_64=true}},
	},

	// =========================================================================
	// §13 Additional load/store addressing modes
	// =========================================================================
	//
	// Unscaled signed-9 (LDUR/STUR) -- size:111 000 opc:0 imm9:9 00 Rn Rt
	//   Mask covers bits[31:21] + bits[11:10] = 0xFFE00C00

	.LDUR  = {
		{.LDUR,  {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xB8400000, 0xFFE00C00, .BASE, {}},
		{.LDUR,  {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xF8400000, 0xFFE00C00, .BASE, {is_64=true}},
	},
	.STUR  = {
		{.STUR,  {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xB8000000, 0xFFE00C00, .BASE, {}},
		{.STUR,  {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xF8000000, 0xFFE00C00, .BASE, {is_64=true}},
	},
	.LDURB = { {.LDURB, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x38400000, 0xFFE00C00, .BASE, {}} },
	.STURB = { {.STURB, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x38000000, 0xFFE00C00, .BASE, {}} },
	.LDURH = { {.LDURH, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x78400000, 0xFFE00C00, .BASE, {}} },
	.STURH = { {.STURH, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x78000000, 0xFFE00C00, .BASE, {}} },
	.LDURSB = {
		{.LDURSB, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x38800000, 0xFFE00C00, .BASE, {is_64=true}},
		{.LDURSB, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x38C00000, 0xFFE00C00, .BASE, {}},
	},
	.LDURSH = {
		{.LDURSH, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x78800000, 0xFFE00C00, .BASE, {is_64=true}},
		{.LDURSH, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x78C00000, 0xFFE00C00, .BASE, {}},
	},
	.LDURSW = { {.LDURSW, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xB8800000, 0xFFE00C00, .BASE, {is_64=true}} },

	// Pre-index (mode bits[11:10] = 11)
	.LDR_PRE = {
		{.LDR_PRE, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_PRE, .NONE, .NONE}, 0xB8400C00, 0xFFE00C00, .BASE, {}},
		{.LDR_PRE, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_PRE, .NONE, .NONE}, 0xF8400C00, 0xFFE00C00, .BASE, {is_64=true}},
	},
	.STR_PRE = {
		{.STR_PRE, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_PRE, .NONE, .NONE}, 0xB8000C00, 0xFFE00C00, .BASE, {}},
		{.STR_PRE, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_PRE, .NONE, .NONE}, 0xF8000C00, 0xFFE00C00, .BASE, {is_64=true}},
	},
	// Post-index (mode bits[11:10] = 01)
	.LDR_POST = {
		{.LDR_POST, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_POST, .NONE, .NONE}, 0xB8400400, 0xFFE00C00, .BASE, {}},
		{.LDR_POST, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_POST, .NONE, .NONE}, 0xF8400400, 0xFFE00C00, .BASE, {is_64=true}},
	},
	.STR_POST = {
		{.STR_POST, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_POST, .NONE, .NONE}, 0xB8000400, 0xFFE00C00, .BASE, {}},
		{.STR_POST, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_POST, .NONE, .NONE}, 0xF8000400, 0xFFE00C00, .BASE, {is_64=true}},
	},

	// Register-offset load/store -- size:111 000 opc:1 Rm option S:1 10 Rn Rt
	//   Mask covers bits[31:21] + bits[15:10] -- option/S/index are operand
	.LDR_REG = {
		{.LDR_REG, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_REG, .NONE, .NONE}, 0xB8600800, 0xFFE00C00, .BASE, {}},
		{.LDR_REG, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_REG, .NONE, .NONE}, 0xF8600800, 0xFFE00C00, .BASE, {is_64=true}},
	},
	.STR_REG = {
		{.STR_REG, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_REG, .NONE, .NONE}, 0xB8200800, 0xFFE00C00, .BASE, {}},
		{.STR_REG, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_REG, .NONE, .NONE}, 0xF8200800, 0xFFE00C00, .BASE, {is_64=true}},
	},

	// LDP/STP pre/post-index (variants of the offset form with bits[24:23] = 11/01)
	.LDP_PRE  = {
		{.LDP_PRE,  {.W_REG, .W_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_PRE, .NONE}, 0x29C00000, 0xFFC00000, .BASE, {}},
		{.LDP_PRE,  {.X_REG, .X_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_PRE, .NONE}, 0xA9C00000, 0xFFC00000, .BASE, {is_64=true}},
	},
	.STP_PRE  = {
		{.STP_PRE,  {.W_REG, .W_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_PRE, .NONE}, 0x29800000, 0xFFC00000, .BASE, {}},
		{.STP_PRE,  {.X_REG, .X_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_PRE, .NONE}, 0xA9800000, 0xFFC00000, .BASE, {is_64=true}},
	},
	.LDP_POST = {
		{.LDP_POST, {.W_REG, .W_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_POST, .NONE}, 0x28C00000, 0xFFC00000, .BASE, {}},
		{.LDP_POST, {.X_REG, .X_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_POST, .NONE}, 0xA8C00000, 0xFFC00000, .BASE, {is_64=true}},
	},
	.STP_POST = {
		{.STP_POST, {.W_REG, .W_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_POST, .NONE}, 0x28800000, 0xFFC00000, .BASE, {}},
		{.STP_POST, {.X_REG, .X_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_POST, .NONE}, 0xA8800000, 0xFFC00000, .BASE, {is_64=true}},
	},
	.LDPSW_PRE  = { {.LDPSW_PRE,  {.X_REG, .X_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_PRE,  .NONE}, 0x69C00000, 0xFFC00000, .BASE, {is_64=true}} },
	.LDPSW_POST = { {.LDPSW_POST, {.X_REG, .X_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_POST, .NONE}, 0x68C00000, 0xFFC00000, .BASE, {is_64=true}} },
	.LDNP = {
		{.LDNP, {.W_REG, .W_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_S9, .NONE}, 0x28400000, 0xFFC00000, .BASE, {}},
		{.LDNP, {.X_REG, .X_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_S9, .NONE}, 0xA8400000, 0xFFC00000, .BASE, {is_64=true}},
	},
	.STNP = {
		{.STNP, {.W_REG, .W_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_S9, .NONE}, 0x28000000, 0xFFC00000, .BASE, {}},
		{.STNP, {.X_REG, .X_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_S9, .NONE}, 0xA8000000, 0xFFC00000, .BASE, {is_64=true}},
	},

	// Exclusive (LDXR/STXR) -- size:001000 010 0 11111 0 11111 Rn Rt
	.LDXR  = {
		{.LDXR,  {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x885F7C00, 0xFFE0FC00, .BASE, {}},
		{.LDXR,  {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0xC85F7C00, 0xFFE0FC00, .BASE, {is_64=true}},
	},
	.STXR  = {
		{.STXR,  {.W_REG, .W_REG, .MEM, .NONE}, {.RD, .RT, .OFFSET_BASE_A, .NONE}, 0x88007C00, 0xFFE0FC00, .BASE, {}},
		{.STXR,  {.W_REG, .X_REG, .MEM, .NONE}, {.RD, .RT, .OFFSET_BASE_A, .NONE}, 0xC8007C00, 0xFFE0FC00, .BASE, {is_64=true}},
	},
	.LDAXR = {
		{.LDAXR, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x885FFC00, 0xFFE0FC00, .BASE, {}},
		{.LDAXR, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0xC85FFC00, 0xFFE0FC00, .BASE, {is_64=true}},
	},
	.STLXR = {
		{.STLXR, {.W_REG, .W_REG, .MEM, .NONE}, {.RD, .RT, .OFFSET_BASE_A, .NONE}, 0x8800FC00, 0xFFE0FC00, .BASE, {}},
		{.STLXR, {.W_REG, .X_REG, .MEM, .NONE}, {.RD, .RT, .OFFSET_BASE_A, .NONE}, 0xC800FC00, 0xFFE0FC00, .BASE, {is_64=true}},
	},
	.LDXRB  = { {.LDXRB,  {.W_REG, .MEM, .NONE, .NONE},      {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x085F7C00, 0xFFE0FC00, .BASE, {}} },
	.STXRB  = { {.STXRB,  {.W_REG, .W_REG, .MEM, .NONE},     {.RD, .RT, .OFFSET_BASE_A, .NONE},   0x08007C00, 0xFFE0FC00, .BASE, {}} },
	.LDAXRB = { {.LDAXRB, {.W_REG, .MEM, .NONE, .NONE},      {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x085FFC00, 0xFFE0FC00, .BASE, {}} },
	.STLXRB = { {.STLXRB, {.W_REG, .W_REG, .MEM, .NONE},     {.RD, .RT, .OFFSET_BASE_A, .NONE},   0x0800FC00, 0xFFE0FC00, .BASE, {}} },
	.LDXRH  = { {.LDXRH,  {.W_REG, .MEM, .NONE, .NONE},      {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x485F7C00, 0xFFE0FC00, .BASE, {}} },
	.STXRH  = { {.STXRH,  {.W_REG, .W_REG, .MEM, .NONE},     {.RD, .RT, .OFFSET_BASE_A, .NONE},   0x48007C00, 0xFFE0FC00, .BASE, {}} },
	.LDAXRH = { {.LDAXRH, {.W_REG, .MEM, .NONE, .NONE},      {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x485FFC00, 0xFFE0FC00, .BASE, {}} },
	.STLXRH = { {.STLXRH, {.W_REG, .W_REG, .MEM, .NONE},     {.RD, .RT, .OFFSET_BASE_A, .NONE},   0x4800FC00, 0xFFE0FC00, .BASE, {}} },

	// Exclusive pair (LDXP/STXP) -- two registers
	.LDXP  = {
		{.LDXP,  {.W_REG, .W_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_A, .NONE}, 0x887F0000, 0xFFFF8000, .BASE, {}},
		{.LDXP,  {.X_REG, .X_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_A, .NONE}, 0xC87F0000, 0xFFFF8000, .BASE, {is_64=true}},
	},
	.STXP  = {
		{.STXP,  {.W_REG, .W_REG, .W_REG, .MEM}, {.RD, .RT, .RT2, .OFFSET_BASE_A}, 0x88200000, 0xFFE08000, .BASE, {}},
		{.STXP,  {.W_REG, .X_REG, .X_REG, .MEM}, {.RD, .RT, .RT2, .OFFSET_BASE_A}, 0xC8200000, 0xFFE08000, .BASE, {is_64=true}},
	},
	.LDAXP = {
		{.LDAXP, {.W_REG, .W_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_A, .NONE}, 0x887F8000, 0xFFFF8000, .BASE, {}},
		{.LDAXP, {.X_REG, .X_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_A, .NONE}, 0xC87F8000, 0xFFFF8000, .BASE, {is_64=true}},
	},
	.STLXP = {
		{.STLXP, {.W_REG, .W_REG, .W_REG, .MEM}, {.RD, .RT, .RT2, .OFFSET_BASE_A}, 0x88208000, 0xFFE08000, .BASE, {}},
		{.STLXP, {.W_REG, .X_REG, .X_REG, .MEM}, {.RD, .RT, .RT2, .OFFSET_BASE_A}, 0xC8208000, 0xFFE08000, .BASE, {is_64=true}},
	},

	// Acquire/Release (single register)
	.LDAR = {
		{.LDAR, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x88DFFC00, 0xFFFFFC00, .BASE, {}},
		{.LDAR, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0xC8DFFC00, 0xFFFFFC00, .BASE, {is_64=true}},
	},
	.STLR = {
		{.STLR, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x889FFC00, 0xFFFFFC00, .BASE, {}},
		{.STLR, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0xC89FFC00, 0xFFFFFC00, .BASE, {is_64=true}},
	},
	.LDARB = { {.LDARB, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x08DFFC00, 0xFFFFFC00, .BASE, {}} },
	.STLRB = { {.STLRB, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x089FFC00, 0xFFFFFC00, .BASE, {}} },
	.LDARH = { {.LDARH, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x48DFFC00, 0xFFFFFC00, .BASE, {}} },
	.STLRH = { {.STLRH, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x489FFC00, 0xFFFFFC00, .BASE, {}} },

	// LDAPR (load-acquire RCpc, v8.3-A)
	.LDAPR  = {
		{.LDAPR,  {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0xB8BFC000, 0xFFFFFC00, .LSE2, {}},
		{.LDAPR,  {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0xF8BFC000, 0xFFFFFC00, .LSE2, {is_64=true}},
	},
	.LDAPRB = { {.LDAPRB, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x38BFC000, 0xFFFFFC00, .LSE2, {}} },
	.LDAPRH = { {.LDAPRH, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_A, .NONE, .NONE}, 0x78BFC000, 0xFFFFFC00, .LSE2, {}} },

	// =========================================================================
	// §14 LSE atomics (v8.1-A)
	// =========================================================================
	//
	// Format: size:111000 A:R 1 Rs:5 o3:opc:3 00 Rn:5 Rt:5
	//   size (bits 31:30): 10=W, 11=X
	//   A (bit 23): acquire semantics
	//   R (bit 22): release semantics
	//   opc (bits 14:12): 000=ADD, 001=CLR, 010=EOR, 011=SET,
	//                     100=SMAX, 101=SMIN, 110=UMAX, 111=UMIN
	//   o3 (bit 15): 0 for LDADD/LDCLR/LDEOR/LDSET/LD{S,U}{MAX,MIN}
	//   Mask covers size + 11100 + A + R + 1 + Rs(operand) + o3 + opc + 00
	//   Operand-driven: A/R via flag in mask, Rs/Rn/Rt
	//
	// Per the ARM ARM these are encoded with bit 23 = A, bit 22 = R.
	// We emit one entry per (mnemonic, width) pair; A/L embedded in bits.

	// Macro-style: each LDxxx has 4 variants (none/A/L/AL) x 2 widths (W/X)
	.LDADD    = {
		{.LDADD,    {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8200000, 0xFFE0FC00, .LSE, {}},
		{.LDADD,    {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8200000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDADDA   = {
		{.LDADDA,   {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8A00000, 0xFFE0FC00, .LSE, {}},
		{.LDADDA,   {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8A00000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDADDL   = {
		{.LDADDL,   {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8600000, 0xFFE0FC00, .LSE, {}},
		{.LDADDL,   {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8600000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDADDAL  = {
		{.LDADDAL,  {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8E00000, 0xFFE0FC00, .LSE, {}},
		{.LDADDAL,  {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8E00000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDCLR    = {
		{.LDCLR,    {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8201000, 0xFFE0FC00, .LSE, {}},
		{.LDCLR,    {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8201000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDCLRA   = {
		{.LDCLRA,   {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8A01000, 0xFFE0FC00, .LSE, {}},
		{.LDCLRA,   {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8A01000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDCLRL   = {
		{.LDCLRL,   {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8601000, 0xFFE0FC00, .LSE, {}},
		{.LDCLRL,   {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8601000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDCLRAL  = {
		{.LDCLRAL,  {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8E01000, 0xFFE0FC00, .LSE, {}},
		{.LDCLRAL,  {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8E01000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDEOR    = {
		{.LDEOR,    {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8202000, 0xFFE0FC00, .LSE, {}},
		{.LDEOR,    {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8202000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDEORA   = {
		{.LDEORA,   {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8A02000, 0xFFE0FC00, .LSE, {}},
		{.LDEORA,   {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8A02000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDEORL   = {
		{.LDEORL,   {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8602000, 0xFFE0FC00, .LSE, {}},
		{.LDEORL,   {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8602000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDEORAL  = {
		{.LDEORAL,  {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8E02000, 0xFFE0FC00, .LSE, {}},
		{.LDEORAL,  {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8E02000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDSET    = {
		{.LDSET,    {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8203000, 0xFFE0FC00, .LSE, {}},
		{.LDSET,    {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8203000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDSETA   = {
		{.LDSETA,   {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8A03000, 0xFFE0FC00, .LSE, {}},
		{.LDSETA,   {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8A03000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDSETL   = {
		{.LDSETL,   {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8603000, 0xFFE0FC00, .LSE, {}},
		{.LDSETL,   {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8603000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDSETAL  = {
		{.LDSETAL,  {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8E03000, 0xFFE0FC00, .LSE, {}},
		{.LDSETAL,  {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8E03000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDSMAX   = {
		{.LDSMAX,   {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8204000, 0xFFE0FC00, .LSE, {}},
		{.LDSMAX,   {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8204000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDSMAXA  = {
		{.LDSMAXA,  {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8A04000, 0xFFE0FC00, .LSE, {}},
		{.LDSMAXA,  {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8A04000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDSMAXL  = {
		{.LDSMAXL,  {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8604000, 0xFFE0FC00, .LSE, {}},
		{.LDSMAXL,  {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8604000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDSMAXAL = {
		{.LDSMAXAL, {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8E04000, 0xFFE0FC00, .LSE, {}},
		{.LDSMAXAL, {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8E04000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDSMIN   = {
		{.LDSMIN,   {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8205000, 0xFFE0FC00, .LSE, {}},
		{.LDSMIN,   {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8205000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDSMINA  = {
		{.LDSMINA,  {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8A05000, 0xFFE0FC00, .LSE, {}},
		{.LDSMINA,  {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8A05000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDSMINL  = {
		{.LDSMINL,  {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8605000, 0xFFE0FC00, .LSE, {}},
		{.LDSMINL,  {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8605000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDSMINAL = {
		{.LDSMINAL, {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8E05000, 0xFFE0FC00, .LSE, {}},
		{.LDSMINAL, {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8E05000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDUMAX   = {
		{.LDUMAX,   {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8206000, 0xFFE0FC00, .LSE, {}},
		{.LDUMAX,   {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8206000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDUMAXA  = {
		{.LDUMAXA,  {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8A06000, 0xFFE0FC00, .LSE, {}},
		{.LDUMAXA,  {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8A06000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDUMAXL  = {
		{.LDUMAXL,  {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8606000, 0xFFE0FC00, .LSE, {}},
		{.LDUMAXL,  {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8606000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDUMAXAL = {
		{.LDUMAXAL, {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8E06000, 0xFFE0FC00, .LSE, {}},
		{.LDUMAXAL, {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8E06000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDUMIN   = {
		{.LDUMIN,   {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8207000, 0xFFE0FC00, .LSE, {}},
		{.LDUMIN,   {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8207000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDUMINA  = {
		{.LDUMINA,  {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8A07000, 0xFFE0FC00, .LSE, {}},
		{.LDUMINA,  {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8A07000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDUMINL  = {
		{.LDUMINL,  {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8607000, 0xFFE0FC00, .LSE, {}},
		{.LDUMINL,  {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8607000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.LDUMINAL = {
		{.LDUMINAL, {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8E07000, 0xFFE0FC00, .LSE, {}},
		{.LDUMINAL, {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8E07000, 0xFFE0FC00, .LSE, {is_64=true}},
	},

	// SWP (swap) -- opc=1000
	.SWP   = {
		{.SWP,   {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8208000, 0xFFE0FC00, .LSE, {}},
		{.SWP,   {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8208000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.SWPA  = {
		{.SWPA,  {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8A08000, 0xFFE0FC00, .LSE, {}},
		{.SWPA,  {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8A08000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.SWPL  = {
		{.SWPL,  {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8608000, 0xFFE0FC00, .LSE, {}},
		{.SWPL,  {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8608000, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.SWPAL = {
		{.SWPAL, {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xB8E08000, 0xFFE0FC00, .LSE, {}},
		{.SWPAL, {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xF8E08000, 0xFFE0FC00, .LSE, {is_64=true}},
	},

	// CAS (compare-and-swap) -- size:1000100 A:1 1 Rs:5 R 11111 Rn Rt
	.CAS   = {
		{.CAS,   {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x88A07C00, 0xFFE0FC00, .LSE, {}},
		{.CAS,   {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xC8A07C00, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.CASA  = {
		{.CASA,  {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x88E07C00, 0xFFE0FC00, .LSE, {}},
		{.CASA,  {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xC8E07C00, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.CASL  = {
		{.CASL,  {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x88A0FC00, 0xFFE0FC00, .LSE, {}},
		{.CASL,  {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xC8A0FC00, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.CASAL = {
		{.CASAL, {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x88E0FC00, 0xFFE0FC00, .LSE, {}},
		{.CASAL, {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0xC8E0FC00, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.CASB    = { {.CASB,    {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x08A07C00, 0xFFE0FC00, .LSE, {}} },
	.CASAB   = { {.CASAB,   {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x08E07C00, 0xFFE0FC00, .LSE, {}} },
	.CASLB   = { {.CASLB,   {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x08A0FC00, 0xFFE0FC00, .LSE, {}} },
	.CASALB  = { {.CASALB,  {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x08E0FC00, 0xFFE0FC00, .LSE, {}} },
	.CASH    = { {.CASH,    {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x48A07C00, 0xFFE0FC00, .LSE, {}} },
	.CASAH   = { {.CASAH,   {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x48E07C00, 0xFFE0FC00, .LSE, {}} },
	.CASLH   = { {.CASLH,   {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x48A0FC00, 0xFFE0FC00, .LSE, {}} },
	.CASALH  = { {.CASALH,  {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x48E0FC00, 0xFFE0FC00, .LSE, {}} },

	// CASP (compare-and-swap pair) -- Rs, Rs+1 with Rt, Rt+1
	.CASP   = {
		{.CASP,   {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x08207C00, 0xFFE0FC00, .LSE, {}},
		{.CASP,   {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x48207C00, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.CASPA  = {
		{.CASPA,  {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x08607C00, 0xFFE0FC00, .LSE, {}},
		{.CASPA,  {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x48607C00, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.CASPL  = {
		{.CASPL,  {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x0820FC00, 0xFFE0FC00, .LSE, {}},
		{.CASPL,  {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x4820FC00, 0xFFE0FC00, .LSE, {is_64=true}},
	},
	.CASPAL = {
		{.CASPAL, {.W_REG, .W_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x0860FC00, 0xFFE0FC00, .LSE, {}},
		{.CASPAL, {.X_REG, .X_REG, .MEM, .NONE}, {.ATOMIC_RS, .ATOMIC_RT, .ATOMIC_RN, .NONE}, 0x4860FC00, 0xFFE0FC00, .LSE, {is_64=true}},
	},

	// =========================================================================
	// §15 CRC32 (v8.0-A optional, mandatory v8.1+)
	// =========================================================================
	//   sf 0 0 11010110 Rm 0100 sz Rn Rd  (CRC32; sz=00 byte / 01 half / 10 word / 11 dword)
	//   CRC32C: bit 12 = 1
	//   Mask = bits[31:21] + bits[15:10] = 0xFFE0FC00

	.CRC32B  = { {.CRC32B,  {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1AC04000, 0xFFE0FC00, .CRC32, {}} },
	.CRC32H  = { {.CRC32H,  {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1AC04400, 0xFFE0FC00, .CRC32, {}} },
	.CRC32W  = { {.CRC32W,  {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1AC04800, 0xFFE0FC00, .CRC32, {}} },
	.CRC32X  = { {.CRC32X,  {.W_REG, .W_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x9AC04C00, 0xFFE0FC00, .CRC32, {is_64=true}} },
	.CRC32CB = { {.CRC32CB, {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1AC05000, 0xFFE0FC00, .CRC32, {}} },
	.CRC32CH = { {.CRC32CH, {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1AC05400, 0xFFE0FC00, .CRC32, {}} },
	.CRC32CW = { {.CRC32CW, {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1AC05800, 0xFFE0FC00, .CRC32, {}} },
	.CRC32CX = { {.CRC32CX, {.W_REG, .W_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x9AC05C00, 0xFFE0FC00, .CRC32, {is_64=true}} },

	// =========================================================================
	// §16 Crypto (AES / SHA1 / SHA256 / SHA512 / SHA3 / SM3 / SM4 / PMULL)
	// =========================================================================
	//
	// AES: 0 1 0 01110 0 0 10100 op 10 Vn Vd  (V regs treated as 16B)
	.AESE    = { {.AESE,    {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E284800, 0xFFFFFC00, .CRYPTO, {}} },
	.AESD    = { {.AESD,    {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E285800, 0xFFFFFC00, .CRYPTO, {}} },
	.AESMC   = { {.AESMC,   {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E286800, 0xFFFFFC00, .CRYPTO, {}} },
	.AESIMC  = { {.AESIMC,  {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E287800, 0xFFFFFC00, .CRYPTO, {}} },

	// SHA1: 0 1 0 11110 0 0 10100 ... 10 Vn Vd
	.SHA1H   = { {.SHA1H,   {.S_REG, .S_REG, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x5E280800, 0xFFFFFC00, .CRYPTO, {}} },
	.SHA1SU1 = { {.SHA1SU1, {.V_4S, .V_4S, .NONE, .NONE},   {.VD, .VN, .NONE, .NONE}, 0x5E281800, 0xFFFFFC00, .CRYPTO, {}} },
	.SHA1C   = { {.SHA1C,   {.Q_REG, .S_REG, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE},   0x5E000000, 0xFFE0FC00, .CRYPTO, {}} },
	.SHA1P   = { {.SHA1P,   {.Q_REG, .S_REG, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE},   0x5E001000, 0xFFE0FC00, .CRYPTO, {}} },
	.SHA1M   = { {.SHA1M,   {.Q_REG, .S_REG, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE},   0x5E002000, 0xFFE0FC00, .CRYPTO, {}} },
	.SHA1SU0 = { {.SHA1SU0, {.V_4S, .V_4S, .V_4S, .NONE},   {.VD, .VN, .VM, .NONE},   0x5E003000, 0xFFE0FC00, .CRYPTO, {}} },

	// SHA256
	.SHA256H   = { {.SHA256H,   {.Q_REG, .Q_REG, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x5E004000, 0xFFE0FC00, .CRYPTO, {}} },
	.SHA256H2  = { {.SHA256H2,  {.Q_REG, .Q_REG, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x5E005000, 0xFFE0FC00, .CRYPTO, {}} },
	.SHA256SU0 = { {.SHA256SU0, {.V_4S, .V_4S, .NONE, .NONE},   {.VD, .VN, .NONE, .NONE}, 0x5E282800, 0xFFFFFC00, .CRYPTO, {}} },
	.SHA256SU1 = { {.SHA256SU1, {.V_4S, .V_4S, .V_4S, .NONE},   {.VD, .VN, .VM, .NONE},   0x5E006000, 0xFFE0FC00, .CRYPTO, {}} },

	// SHA512 (v8.2-A)
	.SHA512H   = { {.SHA512H,   {.Q_REG, .Q_REG, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0xCE608000, 0xFFE0FC00, .CRYPTO, {}} },
	.SHA512H2  = { {.SHA512H2,  {.Q_REG, .Q_REG, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0xCE608400, 0xFFE0FC00, .CRYPTO, {}} },
	.SHA512SU0 = { {.SHA512SU0, {.V_2D, .V_2D, .NONE, .NONE},   {.VD, .VN, .NONE, .NONE}, 0xCEC08000, 0xFFFFFC00, .CRYPTO, {}} },
	.SHA512SU1 = { {.SHA512SU1, {.V_2D, .V_2D, .V_2D, .NONE},   {.VD, .VN, .VM, .NONE},   0xCE608800, 0xFFE0FC00, .CRYPTO, {}} },

	// SHA3 (v8.2-A)
	.EOR3 = { {.EOR3, {.V_16B, .V_16B, .V_16B, .V_16B}, {.VD, .VN, .VM, .VA}, 0xCE000000, 0xFFE08000, .CRYPTO, {}} },
	.BCAX = { {.BCAX, {.V_16B, .V_16B, .V_16B, .V_16B}, {.VD, .VN, .VM, .VA}, 0xCE200000, 0xFFE08000, .CRYPTO, {}} },
	.RAX1 = { {.RAX1, {.V_2D, .V_2D, .V_2D, .NONE},     {.VD, .VN, .VM, .NONE}, 0xCE608C00, 0xFFE0FC00, .CRYPTO, {}} },
	.XAR  = { {.XAR,  {.V_2D, .V_2D, .V_2D, .IMM_6},    {.VD, .VN, .VM, .IMM6}, 0xCE800000, 0xFFE00000, .CRYPTO, {}} },

	// SM3 / SM4
	.SM3PARTW1 = { {.SM3PARTW1, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0xCE60C000, 0xFFE0FC00, .CRYPTO, {}} },
	.SM3PARTW2 = { {.SM3PARTW2, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0xCE60C400, 0xFFE0FC00, .CRYPTO, {}} },
	.SM3SS1    = { {.SM3SS1,    {.V_4S, .V_4S, .V_4S, .V_4S}, {.VD, .VN, .VM, .VA},   0xCE400000, 0xFFE08000, .CRYPTO, {}} },
	.SM3TT1A   = { {.SM3TT1A,   {.V_4S, .V_4S, .V_ELEM_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0xCE408000, 0xFFE0CC00, .CRYPTO, {}} },
	.SM3TT1B   = { {.SM3TT1B,   {.V_4S, .V_4S, .V_ELEM_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0xCE408400, 0xFFE0CC00, .CRYPTO, {}} },
	.SM3TT2A   = { {.SM3TT2A,   {.V_4S, .V_4S, .V_ELEM_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0xCE408800, 0xFFE0CC00, .CRYPTO, {}} },
	.SM3TT2B   = { {.SM3TT2B,   {.V_4S, .V_4S, .V_ELEM_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0xCE408C00, 0xFFE0CC00, .CRYPTO, {}} },
	.SM4E      = { {.SM4E,      {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0xCEC08400, 0xFFFFFC00, .CRYPTO, {}} },
	.SM4EKEY   = { {.SM4EKEY,   {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE},   0xCE60C800, 0xFFE0FC00, .CRYPTO, {}} },

	// PMULL / PMULL2 (polynomial multiply long; AES/GHASH)
	.PMULL  = {
		{.PMULL,  {.V_8H, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E20E000, 0xFFE0FC00, .CRYPTO, {}},
		{.PMULL,  {.V_2D, .V_1D, .V_1D, .NONE},          {.VD, .VN, .VM, .NONE}, 0x0EE0E000, 0xFFE0FC00, .CRYPTO, {}},
	},
	.PMULL2 = {
		{.PMULL2, {.V_8H, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E20E000, 0xFFE0FC00, .CRYPTO, {}},
		{.PMULL2, {.V_2D, .V_2D, .V_2D, .NONE},   {.VD, .VN, .VM, .NONE}, 0x4EE0E000, 0xFFE0FC00, .CRYPTO, {}},
	},

	// =========================================================================
	// §17 Pointer Authentication (PAC v8.3-A)
	// =========================================================================
	//   PAC* / AUT* / XPAC* live in data-processing 1-source (op0=x110).
	//   The "Z" forms use Rn=XZR (encoded as register 31).

	.PACIA = { {.PACIA, {.X_REG, .XSP_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC10000, 0xFFFFFC00, .PAC, {is_64=true}} },
	.PACIB = { {.PACIB, {.X_REG, .XSP_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC10400, 0xFFFFFC00, .PAC, {is_64=true}} },
	.PACDA = { {.PACDA, {.X_REG, .XSP_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC10800, 0xFFFFFC00, .PAC, {is_64=true}} },
	.PACDB = { {.PACDB, {.X_REG, .XSP_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC10C00, 0xFFFFFC00, .PAC, {is_64=true}} },
	.AUTIA = { {.AUTIA, {.X_REG, .XSP_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC11000, 0xFFFFFC00, .PAC, {is_64=true}} },
	.AUTIB = { {.AUTIB, {.X_REG, .XSP_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC11400, 0xFFFFFC00, .PAC, {is_64=true}} },
	.AUTDA = { {.AUTDA, {.X_REG, .XSP_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC11800, 0xFFFFFC00, .PAC, {is_64=true}} },
	.AUTDB = { {.AUTDB, {.X_REG, .XSP_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xDAC11C00, 0xFFFFFC00, .PAC, {is_64=true}} },

	.PACIZA = { {.PACIZA, {.X_REG, .NONE, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0xDAC123E0, 0xFFFFFFE0, .PAC, {is_64=true}} },
	.PACIZB = { {.PACIZB, {.X_REG, .NONE, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0xDAC127E0, 0xFFFFFFE0, .PAC, {is_64=true}} },
	.PACDZA = { {.PACDZA, {.X_REG, .NONE, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0xDAC12BE0, 0xFFFFFFE0, .PAC, {is_64=true}} },
	.PACDZB = { {.PACDZB, {.X_REG, .NONE, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0xDAC12FE0, 0xFFFFFFE0, .PAC, {is_64=true}} },
	.AUTIZA = { {.AUTIZA, {.X_REG, .NONE, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0xDAC133E0, 0xFFFFFFE0, .PAC, {is_64=true}} },
	.AUTIZB = { {.AUTIZB, {.X_REG, .NONE, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0xDAC137E0, 0xFFFFFFE0, .PAC, {is_64=true}} },
	.AUTDZA = { {.AUTDZA, {.X_REG, .NONE, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0xDAC13BE0, 0xFFFFFFE0, .PAC, {is_64=true}} },
	.AUTDZB = { {.AUTDZB, {.X_REG, .NONE, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0xDAC13FE0, 0xFFFFFFE0, .PAC, {is_64=true}} },

	.XPACI   = { {.XPACI,   {.X_REG, .NONE, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0xDAC143E0, 0xFFFFFFE0, .PAC, {is_64=true}} },
	.XPACD   = { {.XPACD,   {.X_REG, .NONE, .NONE, .NONE}, {.RD, .NONE, .NONE, .NONE}, 0xDAC147E0, 0xFFFFFFE0, .PAC, {is_64=true}} },
	.XPACLRI = { {.XPACLRI, {.NONE, .NONE, .NONE, .NONE},  {.NONE,.NONE,.NONE,.NONE},  0xD50320FF, 0xFFFFFFFF, .PAC, {}} },

	// PAC SP-variant hints
	.PACIASP = { {.PACIASP, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD503233F, 0xFFFFFFFF, .PAC, {}} },
	.PACIBSP = { {.PACIBSP, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD503237F, 0xFFFFFFFF, .PAC, {}} },
	.AUTIASP = { {.AUTIASP, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD50323BF, 0xFFFFFFFF, .PAC, {}} },
	.AUTIBSP = { {.AUTIBSP, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD50323FF, 0xFFFFFFFF, .PAC, {}} },

	// PAC* / AUT* / RET* with key A or B and X16/X17
	.PACIA1716 = { {.PACIA1716, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD503211F, 0xFFFFFFFF, .PAC, {}} },
	.PACIB1716 = { {.PACIB1716, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD503215F, 0xFFFFFFFF, .PAC, {}} },
	.AUTIA1716 = { {.AUTIA1716, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD503219F, 0xFFFFFFFF, .PAC, {}} },
	.AUTIB1716 = { {.AUTIB1716, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD50321DF, 0xFFFFFFFF, .PAC, {}} },

	.PACGA = { {.PACGA, {.X_REG, .X_REG, .XSP_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x9AC03000, 0xFFE0FC00, .PAC, {is_64=true}} },

	.RETAA = { {.RETAA, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD65F0BFF, 0xFFFFFFFF, .PAC, {branch=true, writes_pc=true}} },
	.RETAB = { {.RETAB, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD65F0FFF, 0xFFFFFFFF, .PAC, {branch=true, writes_pc=true}} },

	.BRAA  = { {.BRAA,  {.X_REG, .XSP_REG, .NONE, .NONE}, {.RN, .RD, .NONE, .NONE}, 0xD71F0800, 0xFFFFFC00, .PAC, {branch=true, writes_pc=true}} },
	.BRAB  = { {.BRAB,  {.X_REG, .XSP_REG, .NONE, .NONE}, {.RN, .RD, .NONE, .NONE}, 0xD71F0C00, 0xFFFFFC00, .PAC, {branch=true, writes_pc=true}} },
	.BLRAA = { {.BLRAA, {.X_REG, .XSP_REG, .NONE, .NONE}, {.RN, .RD, .NONE, .NONE}, 0xD73F0800, 0xFFFFFC00, .PAC, {branch=true, writes_pc=true}} },
	.BLRAB = { {.BLRAB, {.X_REG, .XSP_REG, .NONE, .NONE}, {.RN, .RD, .NONE, .NONE}, 0xD73F0C00, 0xFFFFFC00, .PAC, {branch=true, writes_pc=true}} },
	.BRAAZ = { {.BRAAZ, {.X_REG, .NONE, .NONE, .NONE}, {.RN, .NONE, .NONE, .NONE}, 0xD61F081F, 0xFFFFFC1F, .PAC, {branch=true, writes_pc=true}} },
	.BRABZ = { {.BRABZ, {.X_REG, .NONE, .NONE, .NONE}, {.RN, .NONE, .NONE, .NONE}, 0xD61F0C1F, 0xFFFFFC1F, .PAC, {branch=true, writes_pc=true}} },
	.BLRAAZ = { {.BLRAAZ, {.X_REG, .NONE, .NONE, .NONE}, {.RN, .NONE, .NONE, .NONE}, 0xD63F081F, 0xFFFFFC1F, .PAC, {branch=true, writes_pc=true}} },
	.BLRABZ = { {.BLRABZ, {.X_REG, .NONE, .NONE, .NONE}, {.RN, .NONE, .NONE, .NONE}, 0xD63F0C1F, 0xFFFFFC1F, .PAC, {branch=true, writes_pc=true}} },
	.ERETAA = { {.ERETAA, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD69F0BFF, 0xFFFFFFFF, .PAC, {branch=true, writes_pc=true}} },
	.ERETAB = { {.ERETAB, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD69F0FFF, 0xFFFFFFFF, .PAC, {branch=true, writes_pc=true}} },

	// =========================================================================
	// §18 Branch Target Identification (BTI v8.5-A)
	// =========================================================================
	//   HINT space; opc selects {nop|c|j|jc} via CRm:op2 = 0100:000/010/100/110
	.BTI = { {.BTI, {.IMM_2, .NONE, .NONE, .NONE}, {.HINT_FIELD, .NONE, .NONE, .NONE}, 0xD503241F, 0xFFFFF8FF, .BTI, {}} },

	// =========================================================================
	// §19 Memory Tagging Extension (MTE v8.5-A)
	// =========================================================================
	//
	// ADDG/SUBG: sf=1 op:1 0 100011 0 uimm6 op3:2 uimm4 Rn Rd
	.ADDG = { {.ADDG, {.XSP_REG, .XSP_REG, .IMM_6, .IMM_4}, {.RD, .RN, .IMM6, .IMM_HW}, 0x91800000, 0xFFC0C000, .MTE, {is_64=true}} },
	.SUBG = { {.SUBG, {.XSP_REG, .XSP_REG, .IMM_6, .IMM_4}, {.RD, .RN, .IMM6, .IMM_HW}, 0xD1800000, 0xFFC0C000, .MTE, {is_64=true}} },

	// IRG: 10011010110 Rm 000100 Rn Rd
	.IRG  = { {.IRG,  {.XSP_REG, .XSP_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x9AC01000, 0xFFE0FC00, .MTE, {is_64=true}} },
	.GMI  = { {.GMI,  {.X_REG, .XSP_REG, .X_REG, .NONE},   {.RD, .RN, .RM, .NONE}, 0x9AC01400, 0xFFE0FC00, .MTE, {is_64=true}} },
	.SUBP = { {.SUBP, {.X_REG, .XSP_REG, .XSP_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x9AC00000, 0xFFE0FC00, .MTE, {is_64=true}} },
	.SUBPS = { {.SUBPS, {.X_REG, .XSP_REG, .XSP_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0xBAC00000, 0xFFE0FC00, .MTE, {sets_flags=true, is_64=true}} },

	// Tagged load/store (encoded in the load-store offset/pre/post space)
	//   STG  Xt, [Xn|SP], #imm  -- 1101100100 ... opc=10 ... bits[31:24] = 11011001 etc.
	.STG   = { {.STG,   {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xD9200800, 0xFFE00C00, .MTE, {is_64=true}} },
	.STZG  = { {.STZG,  {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xD9600800, 0xFFE00C00, .MTE, {is_64=true}} },
	.ST2G  = { {.ST2G,  {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xD9A00800, 0xFFE00C00, .MTE, {is_64=true}} },
	.STZ2G = { {.STZ2G, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xD9E00800, 0xFFE00C00, .MTE, {is_64=true}} },
	.LDG   = { {.LDG,   {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xD9600000, 0xFFE00C00, .MTE, {is_64=true}} },
	.STGM  = { {.STGM,  {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_A,  .NONE, .NONE}, 0xD9A00000, 0xFFE00C00, .MTE, {is_64=true}} },
	.LDGM  = { {.LDGM,  {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_A,  .NONE, .NONE}, 0xD9E00000, 0xFFE00C00, .MTE, {is_64=true}} },
	.STZGM = { {.STZGM, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_A,  .NONE, .NONE}, 0xD9200000, 0xFFE00C00, .MTE, {is_64=true}} },
	.STGP  = { {.STGP,  {.X_REG, .X_REG, .MEM, .NONE}, {.RT, .RT2, .OFFSET_BASE_S9, .NONE}, 0x69000000, 0xFFC00000, .MTE, {is_64=true}} },

	// =========================================================================
	// §20 FP scalar half-precision (FP16, v8.2-A)
	// =========================================================================
	//   Mirror of FP single/double but with ftype=11 (bits[23:22]=11).
	.FABS_H = { {.FABS_H, {.H_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE0C000, 0xFFFFFC00, .FP16, {}} },
	.FNEG_H = { {.FNEG_H, {.H_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE14000, 0xFFFFFC00, .FP16, {}} },
	.FSQRT_H = { {.FSQRT_H, {.H_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE1C000, 0xFFFFFC00, .FP16, {}} },
	.FADD_H = { {.FADD_H, {.H_REG, .H_REG, .H_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1EE02800, 0xFFE0FC00, .FP16, {}} },
	.FSUB_H = { {.FSUB_H, {.H_REG, .H_REG, .H_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1EE03800, 0xFFE0FC00, .FP16, {}} },
	.FMUL_H = { {.FMUL_H, {.H_REG, .H_REG, .H_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1EE00800, 0xFFE0FC00, .FP16, {}} },
	.FDIV_H = { {.FDIV_H, {.H_REG, .H_REG, .H_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1EE01800, 0xFFE0FC00, .FP16, {}} },
	.FNMUL_H = { {.FNMUL_H, {.H_REG, .H_REG, .H_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1EE08800, 0xFFE0FC00, .FP16, {}} },
	.FMAX_H = { {.FMAX_H, {.H_REG, .H_REG, .H_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1EE04800, 0xFFE0FC00, .FP16, {}} },
	.FMIN_H = { {.FMIN_H, {.H_REG, .H_REG, .H_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1EE05800, 0xFFE0FC00, .FP16, {}} },
	.FMAXNM_H = { {.FMAXNM_H, {.H_REG, .H_REG, .H_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1EE06800, 0xFFE0FC00, .FP16, {}} },
	.FMINNM_H = { {.FMINNM_H, {.H_REG, .H_REG, .H_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1EE07800, 0xFFE0FC00, .FP16, {}} },
	.FCMP_H  = { {.FCMP_H,  {.H_REG, .H_REG, .NONE, .NONE}, {.RN, .RM, .NONE, .NONE}, 0x1EE02000, 0xFFE0FC1F, .FP16, {sets_flags=true}} },
	.FCMPE_H = { {.FCMPE_H, {.H_REG, .H_REG, .NONE, .NONE}, {.RN, .RM, .NONE, .NONE}, 0x1EE02010, 0xFFE0FC1F, .FP16, {sets_flags=true}} },
	.FCSEL_H = { {.FCSEL_H, {.H_REG, .H_REG, .H_REG, .COND}, {.RD, .RN, .RM, .COND_HI}, 0x1EE00C00, 0xFFE00C00, .FP16, {}} },
	.FMADD_H = { {.FMADD_H, {.H_REG, .H_REG, .H_REG, .H_REG}, {.RD, .RN, .RM, .RA}, 0x1FC00000, 0xFFE08000, .FP16, {}} },
	.FMSUB_H = { {.FMSUB_H, {.H_REG, .H_REG, .H_REG, .H_REG}, {.RD, .RN, .RM, .RA}, 0x1FC08000, 0xFFE08000, .FP16, {}} },
	.FNMADD_H = { {.FNMADD_H, {.H_REG, .H_REG, .H_REG, .H_REG}, {.RD, .RN, .RM, .RA}, 0x1FE00000, 0xFFE08000, .FP16, {}} },
	.FNMSUB_H = { {.FNMSUB_H, {.H_REG, .H_REG, .H_REG, .H_REG}, {.RD, .RN, .RM, .RA}, 0x1FE08000, 0xFFE08000, .FP16, {}} },
	.FCVT_H_S = { {.FCVT_H_S, {.H_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E23C000, 0xFFFFFC00, .FP16, {}} },
	.FCVT_H_D = { {.FCVT_H_D, {.H_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E63C000, 0xFFFFFC00, .FP16, {}} },
	.FCVT_S_H = { {.FCVT_S_H, {.S_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE24000, 0xFFFFFC00, .FP16, {}} },
	.FCVT_D_H = { {.FCVT_D_H, {.D_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE2C000, 0xFFFFFC00, .FP16, {}} },
	.SCVTF_H  = { {.SCVTF_H,  {.H_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE20000, 0xFFFFFC00, .FP16, {}} },
	.UCVTF_H  = { {.UCVTF_H,  {.H_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE30000, 0xFFFFFC00, .FP16, {}} },
	.FCVTZS_H = { {.FCVTZS_H, {.W_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EF80000, 0xFFFFFC00, .FP16, {}} },
	.FCVTZU_H = { {.FCVTZU_H, {.W_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EF90000, 0xFFFFFC00, .FP16, {}} },
	.FMOV_H = { {.FMOV_H, {.H_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE04000, 0xFFFFFC00, .FP16, {}} },

	// =========================================================================
	// §21 BFloat16 (BF16, v8.6-A)
	// =========================================================================
	.BFCVT   = { {.BFCVT,   {.H_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E634000, 0xFFFFFC00, .BF16, {}} },
	.BFCVTN  = { {.BFCVTN,  {.V_8H, .V_4S, .NONE, .NONE},   {.VD, .VN, .NONE, .NONE}, 0x0EA16800, 0xFFFFFC00, .BF16, {}} },
	.BFCVTN2 = { {.BFCVTN2, {.V_8H, .V_4S, .NONE, .NONE},   {.VD, .VN, .NONE, .NONE}, 0x4EA16800, 0xFFFFFC00, .BF16, {}} },
	.BFDOT   = { {.BFDOT,   {.V_4S, .V_8H, .V_8H, .NONE},   {.VD, .VN, .VM, .NONE},   0x2E40FC00, 0xFFE0FC00, .BF16, {}} },
	.BFMMLA  = { {.BFMMLA,  {.V_4S, .V_8H, .V_8H, .NONE},   {.VD, .VN, .VM, .NONE},   0x6E40EC00, 0xFFE0FC00, .BF16, {}} },
	.BFMLALB = { {.BFMLALB, {.V_4S, .V_8H, .V_8H, .NONE},   {.VD, .VN, .VM, .NONE},   0x2EC0FC00, 0xFFE0FC00, .BF16, {}} },
	.BFMLALT = { {.BFMLALT, {.V_4S, .V_8H, .V_8H, .NONE},   {.VD, .VN, .VM, .NONE},   0x6EC0FC00, 0xFFE0FC00, .BF16, {}} },

	// =========================================================================
	// §22 NEON Advanced SIMD (3-same arithmetic + compare + logical + shift)
	// =========================================================================
	//
	// Format: 0Q U 01110 size:2 1 Rm opcode:5 1 Rn Rd
	//   Q (bit 30): 0=64-bit / 1=128-bit vector
	//   U (bit 29): selects signed/unsigned or alternate op
	//   size (bits 23:22): element-size 00=B 01=H 10=S 11=D
	//   bits[28:24] = 01110, bit 21 = 1, bit 10 = 1
	//   opcode at bits 15:11
	//
	// Per-arrangement entries: each vector mnemonic has up to 7 forms
	// (8B/16B/4H/8H/2S/4S/2D; 1D is reserved for most). For brevity we
	// list the densely-used arrangements (16B/8H/4S/2D) on the 128-bit
	// path and 8B/4H/2S on the 64-bit path. Some ops (like FADD) only
	// accept FP arrangements (4S/2S/2D + 8H if FP16).

	.ADD_V = {
		{.ADD_V, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E208400, 0xFFE0FC00, .NEON, {}},
		{.ADD_V, {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E608400, 0xFFE0FC00, .NEON, {}},
		{.ADD_V, {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA08400, 0xFFE0FC00, .NEON, {}},
		{.ADD_V, {.V_2D,  .V_2D,  .V_2D,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE08400, 0xFFE0FC00, .NEON, {}},
		{.ADD_V, {.V_8B,  .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E208400, 0xFFE0FC00, .NEON, {}},
		{.ADD_V, {.V_4H,  .V_4H,  .V_4H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E608400, 0xFFE0FC00, .NEON, {}},
		{.ADD_V, {.V_2S,  .V_2S,  .V_2S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA08400, 0xFFE0FC00, .NEON, {}},
	},
	.SUB_V = {
		{.SUB_V, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E208400, 0xFFE0FC00, .NEON, {}},
		{.SUB_V, {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E608400, 0xFFE0FC00, .NEON, {}},
		{.SUB_V, {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA08400, 0xFFE0FC00, .NEON, {}},
		{.SUB_V, {.V_2D,  .V_2D,  .V_2D,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE08400, 0xFFE0FC00, .NEON, {}},
	},
	.MUL_V = {
		// opcode = 10011 -> 0x4E209C00 for 16B
		{.MUL_V, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E209C00, 0xFFE0FC00, .NEON, {}},
		{.MUL_V, {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E609C00, 0xFFE0FC00, .NEON, {}},
		{.MUL_V, {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA09C00, 0xFFE0FC00, .NEON, {}},
	},

	// Vector compares
	.CMEQ = {
		{.CMEQ, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E208C00, 0xFFE0FC00, .NEON, {}},
		{.CMEQ, {.V_8H,  .V_8H,  .V_8H,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E608C00, 0xFFE0FC00, .NEON, {}},
		{.CMEQ, {.V_4S,  .V_4S,  .V_4S,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA08C00, 0xFFE0FC00, .NEON, {}},
		{.CMEQ, {.V_2D,  .V_2D,  .V_2D,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE08C00, 0xFFE0FC00, .NEON, {}},
	},
	.CMGT = {
		{.CMGT, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E203400, 0xFFE0FC00, .NEON, {}},
		{.CMGT, {.V_2D,  .V_2D,  .V_2D,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE03400, 0xFFE0FC00, .NEON, {}},
	},
	.CMHI = {
		{.CMHI, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E203400, 0xFFE0FC00, .NEON, {}},
		{.CMHI, {.V_2D,  .V_2D,  .V_2D,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE03400, 0xFFE0FC00, .NEON, {}},
	},

	// Logical (vector)
	.AND_V = { {.AND_V, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E201C00, 0xFFE0FC00, .NEON, {}} },
	.ORR_V = { {.ORR_V, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA01C00, 0xFFE0FC00, .NEON, {}} },
	.EOR_V = { {.EOR_V, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E201C00, 0xFFE0FC00, .NEON, {}} },
	.BIC_V = { {.BIC_V, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E601C00, 0xFFE0FC00, .NEON, {}} },
	.ORN_V = { {.ORN_V, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE01C00, 0xFFE0FC00, .NEON, {}} },

	// Bit insert/select (BIT/BIF/BSL): U=1
	.BIT = { {.BIT, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA01C00, 0xFFE0FC00, .NEON, {}} },
	.BIF = { {.BIF, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE01C00, 0xFFE0FC00, .NEON, {}} },
	.BSL = { {.BSL, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E601C00, 0xFFE0FC00, .NEON, {}} },

	// FP vector arithmetic (3-same FP encoding)
	.FADD_V = {
		{.FADD_V, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E20D400, 0xFFE0FC00, .NEON, {}},
		{.FADD_V, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E20D400, 0xFFE0FC00, .NEON, {}},
		{.FADD_V, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60D400, 0xFFE0FC00, .NEON, {}},
	},
	.FSUB_V = {
		{.FSUB_V, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA0D400, 0xFFE0FC00, .NEON, {}},
		{.FSUB_V, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA0D400, 0xFFE0FC00, .NEON, {}},
		{.FSUB_V, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE0D400, 0xFFE0FC00, .NEON, {}},
	},
	.FMUL_V = {
		{.FMUL_V, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E20DC00, 0xFFE0FC00, .NEON, {}},
		{.FMUL_V, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E20DC00, 0xFFE0FC00, .NEON, {}},
		{.FMUL_V, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E60DC00, 0xFFE0FC00, .NEON, {}},
	},
	.FDIV_V = {
		{.FDIV_V, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E20FC00, 0xFFE0FC00, .NEON, {}},
		{.FDIV_V, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E20FC00, 0xFFE0FC00, .NEON, {}},
		{.FDIV_V, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E60FC00, 0xFFE0FC00, .NEON, {}},
	},
	.FMLA_V = {
		{.FMLA_V, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E20CC00, 0xFFE0FC00, .NEON, {}},
		{.FMLA_V, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60CC00, 0xFFE0FC00, .NEON, {}},
	},
	.FMLS_V = {
		{.FMLS_V, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA0CC00, 0xFFE0FC00, .NEON, {}},
		{.FMLS_V, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE0CC00, 0xFFE0FC00, .NEON, {}},
	},

	// Dot product (SDOT/UDOT - v8.2-A optional, mandatory v8.4)
	.SDOT = {
		{.SDOT, {.V_2S, .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E809400, 0xFFE0FC00, .DOT, {}},
		{.SDOT, {.V_4S, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E809400, 0xFFE0FC00, .DOT, {}},
	},
	.UDOT = {
		{.UDOT, {.V_2S, .V_8B,  .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E809400, 0xFFE0FC00, .DOT, {}},
		{.UDOT, {.V_4S, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E809400, 0xFFE0FC00, .DOT, {}},
	},

	// NEON load/store: LD1/ST1 multiple structures (the simplest form)
	//   Single register, 1 vector: 0Q 001100 010 00000 0111 size Rn Rt
	//   Layout details vary by # registers and replicate vs. lane vs. multiple.
	//   v1 covers the common LD1/ST1 to one vector (1 reg, contiguous).
	.LD1 = {
		{.LD1, {.V_16B, .MEM, .NONE, .NONE}, {.VD, .OFFSET_BASE_A, .NONE, .NONE}, 0x4C407000, 0xFFFFF000, .NEON, {}},
		{.LD1, {.V_8H,  .MEM, .NONE, .NONE}, {.VD, .OFFSET_BASE_A, .NONE, .NONE}, 0x4C407400, 0xFFFFF400, .NEON, {}},
		{.LD1, {.V_4S,  .MEM, .NONE, .NONE}, {.VD, .OFFSET_BASE_A, .NONE, .NONE}, 0x4C407800, 0xFFFFF800, .NEON, {}},
		{.LD1, {.V_2D,  .MEM, .NONE, .NONE}, {.VD, .OFFSET_BASE_A, .NONE, .NONE}, 0x4C407C00, 0xFFFFFC00, .NEON, {}},
	},
	.ST1 = {
		{.ST1, {.V_16B, .MEM, .NONE, .NONE}, {.VD, .OFFSET_BASE_A, .NONE, .NONE}, 0x4C007000, 0xFFFFF000, .NEON, {}},
		{.ST1, {.V_8H,  .MEM, .NONE, .NONE}, {.VD, .OFFSET_BASE_A, .NONE, .NONE}, 0x4C007400, 0xFFFFF400, .NEON, {}},
		{.ST1, {.V_4S,  .MEM, .NONE, .NONE}, {.VD, .OFFSET_BASE_A, .NONE, .NONE}, 0x4C007800, 0xFFFFF800, .NEON, {}},
		{.ST1, {.V_2D,  .MEM, .NONE, .NONE}, {.VD, .OFFSET_BASE_A, .NONE, .NONE}, 0x4C007C00, 0xFFFFFC00, .NEON, {}},
	},

	// Table lookup (TBL/TBX): the table operand is a register list whose first
	// register is encoded at Vn; the list length (here 1) is fixed in the bits.
	.TBL = {
		{.TBL, {.V_8B,  .V_16B, .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E000000, 0xFFE0FC00, .NEON, {}},
		{.TBL, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E000000, 0xFFE0FC00, .NEON, {}},
	},
	.TBX = {
		{.TBX, {.V_8B,  .V_16B, .V_8B,  .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E001000, 0xFFE0FC00, .NEON, {}},
		{.TBX, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E001000, 0xFFE0FC00, .NEON, {}},
	},
	// Structured load/store of 2/3/4 registers, and load-and-replicate (LD#R).
	// The register list is encoded by its first register (Vd); the count and
	// arrangement (here .16b) are fixed in the bits (mirrors the LD1/ST1 forms).
	.LD2 = { {.LD2, {.V_16B, .MEM, .NONE, .NONE}, {.VD, .OFFSET_BASE_A, .NONE, .NONE}, 0x4C408000, 0xFFFFFC00, .NEON, {}} },
	.LD3 = { {.LD3, {.V_16B, .MEM, .NONE, .NONE}, {.VD, .OFFSET_BASE_A, .NONE, .NONE}, 0x4C404000, 0xFFFFFC00, .NEON, {}} },
	.LD4 = { {.LD4, {.V_16B, .MEM, .NONE, .NONE}, {.VD, .OFFSET_BASE_A, .NONE, .NONE}, 0x4C400000, 0xFFFFFC00, .NEON, {}} },
	.ST2 = { {.ST2, {.V_16B, .MEM, .NONE, .NONE}, {.VD, .OFFSET_BASE_A, .NONE, .NONE}, 0x4C008000, 0xFFFFFC00, .NEON, {}} },
	.ST3 = { {.ST3, {.V_16B, .MEM, .NONE, .NONE}, {.VD, .OFFSET_BASE_A, .NONE, .NONE}, 0x4C004000, 0xFFFFFC00, .NEON, {}} },
	.ST4 = { {.ST4, {.V_16B, .MEM, .NONE, .NONE}, {.VD, .OFFSET_BASE_A, .NONE, .NONE}, 0x4C000000, 0xFFFFFC00, .NEON, {}} },
	.LD1R = { {.LD1R, {.V_16B, .MEM, .NONE, .NONE}, {.VD, .OFFSET_BASE_A, .NONE, .NONE}, 0x4D40C000, 0xFFFFFC00, .NEON, {}} },
	.LD2R = { {.LD2R, {.V_16B, .MEM, .NONE, .NONE}, {.VD, .OFFSET_BASE_A, .NONE, .NONE}, 0x4D60C000, 0xFFFFFC00, .NEON, {}} },
	.LD3R = { {.LD3R, {.V_16B, .MEM, .NONE, .NONE}, {.VD, .OFFSET_BASE_A, .NONE, .NONE}, 0x4D40E000, 0xFFFFFC00, .NEON, {}} },
	.LD4R = { {.LD4R, {.V_16B, .MEM, .NONE, .NONE}, {.VD, .OFFSET_BASE_A, .NONE, .NONE}, 0x4D60E000, 0xFFFFFC00, .NEON, {}} },

	// Single-structure (one lane) load/store: LD#_LANE / ST#_LANE. The lane
	// index is split across Q (30), S (12) and size (11:10) per element size;
	// the list length + load/store bit are fixed in the bits.
	.LD1_LANE = {
		{.LD1_LANE, {.V_ELEM_B, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_B, .OFFSET_BASE_A, .NONE}, 0x0D400000, 0xBFFFE000, .NEON, {}},
		{.LD1_LANE, {.V_ELEM_H, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_H, .OFFSET_BASE_A, .NONE}, 0x0D404000, 0xBFFFE400, .NEON, {}},
		{.LD1_LANE, {.V_ELEM_S, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_S, .OFFSET_BASE_A, .NONE}, 0x0D408000, 0xBFFFEC00, .NEON, {}},
		{.LD1_LANE, {.V_ELEM_D, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_D, .OFFSET_BASE_A, .NONE}, 0x0D408400, 0xBFFFFC00, .NEON, {}},
	},
	.LD2_LANE = {
		{.LD2_LANE, {.V_ELEM_B, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_B, .OFFSET_BASE_A, .NONE}, 0x0D600000, 0xBFFFE000, .NEON, {}},
		{.LD2_LANE, {.V_ELEM_H, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_H, .OFFSET_BASE_A, .NONE}, 0x0D604000, 0xBFFFE400, .NEON, {}},
		{.LD2_LANE, {.V_ELEM_S, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_S, .OFFSET_BASE_A, .NONE}, 0x0D608000, 0xBFFFEC00, .NEON, {}},
		{.LD2_LANE, {.V_ELEM_D, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_D, .OFFSET_BASE_A, .NONE}, 0x0D608400, 0xBFFFFC00, .NEON, {}},
	},
	.LD3_LANE = {
		{.LD3_LANE, {.V_ELEM_B, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_B, .OFFSET_BASE_A, .NONE}, 0x0D402000, 0xBFFFE000, .NEON, {}},
		{.LD3_LANE, {.V_ELEM_H, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_H, .OFFSET_BASE_A, .NONE}, 0x0D406000, 0xBFFFE400, .NEON, {}},
		{.LD3_LANE, {.V_ELEM_S, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_S, .OFFSET_BASE_A, .NONE}, 0x0D40A000, 0xBFFFEC00, .NEON, {}},
		{.LD3_LANE, {.V_ELEM_D, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_D, .OFFSET_BASE_A, .NONE}, 0x0D40A400, 0xBFFFFC00, .NEON, {}},
	},
	.LD4_LANE = {
		{.LD4_LANE, {.V_ELEM_B, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_B, .OFFSET_BASE_A, .NONE}, 0x0D602000, 0xBFFFE000, .NEON, {}},
		{.LD4_LANE, {.V_ELEM_H, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_H, .OFFSET_BASE_A, .NONE}, 0x0D606000, 0xBFFFE400, .NEON, {}},
		{.LD4_LANE, {.V_ELEM_S, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_S, .OFFSET_BASE_A, .NONE}, 0x0D60A000, 0xBFFFEC00, .NEON, {}},
		{.LD4_LANE, {.V_ELEM_D, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_D, .OFFSET_BASE_A, .NONE}, 0x0D60A400, 0xBFFFFC00, .NEON, {}},
	},
	.ST1_LANE = {
		{.ST1_LANE, {.V_ELEM_B, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_B, .OFFSET_BASE_A, .NONE}, 0x0D000000, 0xBFFFE000, .NEON, {}},
		{.ST1_LANE, {.V_ELEM_H, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_H, .OFFSET_BASE_A, .NONE}, 0x0D004000, 0xBFFFE400, .NEON, {}},
		{.ST1_LANE, {.V_ELEM_S, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_S, .OFFSET_BASE_A, .NONE}, 0x0D008000, 0xBFFFEC00, .NEON, {}},
		{.ST1_LANE, {.V_ELEM_D, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_D, .OFFSET_BASE_A, .NONE}, 0x0D008400, 0xBFFFFC00, .NEON, {}},
	},
	.ST2_LANE = {
		{.ST2_LANE, {.V_ELEM_B, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_B, .OFFSET_BASE_A, .NONE}, 0x0D200000, 0xBFFFE000, .NEON, {}},
		{.ST2_LANE, {.V_ELEM_H, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_H, .OFFSET_BASE_A, .NONE}, 0x0D204000, 0xBFFFE400, .NEON, {}},
		{.ST2_LANE, {.V_ELEM_S, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_S, .OFFSET_BASE_A, .NONE}, 0x0D208000, 0xBFFFEC00, .NEON, {}},
		{.ST2_LANE, {.V_ELEM_D, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_D, .OFFSET_BASE_A, .NONE}, 0x0D208400, 0xBFFFFC00, .NEON, {}},
	},
	.ST3_LANE = {
		{.ST3_LANE, {.V_ELEM_B, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_B, .OFFSET_BASE_A, .NONE}, 0x0D002000, 0xBFFFE000, .NEON, {}},
		{.ST3_LANE, {.V_ELEM_H, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_H, .OFFSET_BASE_A, .NONE}, 0x0D006000, 0xBFFFE400, .NEON, {}},
		{.ST3_LANE, {.V_ELEM_S, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_S, .OFFSET_BASE_A, .NONE}, 0x0D00A000, 0xBFFFEC00, .NEON, {}},
		{.ST3_LANE, {.V_ELEM_D, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_D, .OFFSET_BASE_A, .NONE}, 0x0D00A400, 0xBFFFFC00, .NEON, {}},
	},
	.ST4_LANE = {
		{.ST4_LANE, {.V_ELEM_B, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_B, .OFFSET_BASE_A, .NONE}, 0x0D202000, 0xBFFFE000, .NEON, {}},
		{.ST4_LANE, {.V_ELEM_H, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_H, .OFFSET_BASE_A, .NONE}, 0x0D206000, 0xBFFFE400, .NEON, {}},
		{.ST4_LANE, {.V_ELEM_S, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_S, .OFFSET_BASE_A, .NONE}, 0x0D20A000, 0xBFFFEC00, .NEON, {}},
		{.ST4_LANE, {.V_ELEM_D, .VEC_INDEX, .MEM, .NONE}, {.VD, .NEON_LANE_D, .OFFSET_BASE_A, .NONE}, 0x0D20A400, 0xBFFFFC00, .NEON, {}},
	},

	// FP/SIMD scalar load/store via V regs (offset-form)
	.LDR_V = {
		{.LDR_V, {.B_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0x3D400000, 0xFFC00000, .FP, {}},
		{.LDR_V, {.H_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0x7D400000, 0xFFC00000, .FP, {}},
		{.LDR_V, {.S_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0xBD400000, 0xFFC00000, .FP, {}},
		{.LDR_V, {.D_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0xFD400000, 0xFFC00000, .FP, {}},
		{.LDR_V, {.Q_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0x3DC00000, 0xFFC00000, .FP, {}},
	},
	.STR_V = {
		{.STR_V, {.B_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0x3D000000, 0xFFC00000, .FP, {}},
		{.STR_V, {.H_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0x7D000000, 0xFFC00000, .FP, {}},
		{.STR_V, {.S_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0xBD000000, 0xFFC00000, .FP, {}},
		{.STR_V, {.D_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0xFD000000, 0xFFC00000, .FP, {}},
		{.STR_V, {.Q_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0x3D800000, 0xFFC00000, .FP, {}},
	},

	// =========================================================================
	// §23 SVE / SVE2 (real coverage)
	// =========================================================================
	//
	// All SVE instructions live in op0 bucket 0b0010 (bits[28:25]) -- they
	// start with byte 0x04 / 0x05 / 0x24 / 0x25 / 0x44 / 0x45 / 0x64 / 0x65
	// (and the load/store family at 0x84 / 0x85 / 0xA4 / 0xA5 / 0xC4 / 0xC5
	// / 0xE4 / 0xE5). All are 4 bytes.
	//
	// Element size: when an instruction has 4 forms (B/H/S/D), the size
	// bits[23:22] differ -- 00/01/10/11.
	//
	// -------------------------------------------------------------------------
	// §23.1 Integer arithmetic, vectors unpredicated
	// -------------------------------------------------------------------------
	//   ADD/SUB/SQADD/UQADD/SQSUB/UQSUB Zd.T, Zn.T, Zm.T
	//   00000100 SS 1 Zm 0000 oo Zn Zd      (oo selects op)

	.SVE_ADD_Z = {
		{.SVE_ADD_Z, {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04200000, 0xFFE0FC00, .SVE, {}},
		{.SVE_ADD_Z, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04600000, 0xFFE0FC00, .SVE, {}},
		{.SVE_ADD_Z, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04A00000, 0xFFE0FC00, .SVE, {}},
		{.SVE_ADD_Z, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04E00000, 0xFFE0FC00, .SVE, {is_64=true}},
	},
	.SVE_SUB_Z = {
		{.SVE_SUB_Z, {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04200400, 0xFFE0FC00, .SVE, {}},
		{.SVE_SUB_Z, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04600400, 0xFFE0FC00, .SVE, {}},
		{.SVE_SUB_Z, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04A00400, 0xFFE0FC00, .SVE, {}},
		{.SVE_SUB_Z, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04E00400, 0xFFE0FC00, .SVE, {is_64=true}},
	},
	.SVE_SQADD_Z = {
		{.SVE_SQADD_Z, {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04201000, 0xFFE0FC00, .SVE, {}},
		{.SVE_SQADD_Z, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04601000, 0xFFE0FC00, .SVE, {}},
		{.SVE_SQADD_Z, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04A01000, 0xFFE0FC00, .SVE, {}},
		{.SVE_SQADD_Z, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04E01000, 0xFFE0FC00, .SVE, {is_64=true}},
	},
	.SVE_UQADD_Z = {
		{.SVE_UQADD_Z, {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04201400, 0xFFE0FC00, .SVE, {}},
		{.SVE_UQADD_Z, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04601400, 0xFFE0FC00, .SVE, {}},
		{.SVE_UQADD_Z, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04A01400, 0xFFE0FC00, .SVE, {}},
		{.SVE_UQADD_Z, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04E01400, 0xFFE0FC00, .SVE, {is_64=true}},
	},
	.SVE_SQSUB_Z = {
		{.SVE_SQSUB_Z, {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04201800, 0xFFE0FC00, .SVE, {}},
		{.SVE_SQSUB_Z, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04601800, 0xFFE0FC00, .SVE, {}},
		{.SVE_SQSUB_Z, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04A01800, 0xFFE0FC00, .SVE, {}},
		{.SVE_SQSUB_Z, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04E01800, 0xFFE0FC00, .SVE, {is_64=true}},
	},
	.SVE_UQSUB_Z = {
		{.SVE_UQSUB_Z, {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04201C00, 0xFFE0FC00, .SVE, {}},
		{.SVE_UQSUB_Z, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04601C00, 0xFFE0FC00, .SVE, {}},
		{.SVE_UQSUB_Z, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04A01C00, 0xFFE0FC00, .SVE, {}},
		{.SVE_UQSUB_Z, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04E01C00, 0xFFE0FC00, .SVE, {is_64=true}},
	},

	// -------------------------------------------------------------------------
	// §23.2 Integer arithmetic, predicated (destructive merging)
	// -------------------------------------------------------------------------
	//   ADD Zdn.T, Pg/M, Zdn.T, Zm.T
	//   00000100 SS 000 opc 001 Pg Zm Zdn      (opc selects op)
	//   Operand 1 (Pg) is governing predicate at bits 12:10 (P0..P7).

	.SVE_ADD_PRED = {
		{.SVE_ADD_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM}, 0x04000000, 0xFFE0E000, .SVE, {}},
		{.SVE_ADD_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x04400000, 0xFFE0E000, .SVE, {}},
		{.SVE_ADD_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x04800000, 0xFFE0E000, .SVE, {}},
		{.SVE_ADD_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x04C00000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_SUB_PRED = {
		{.SVE_SUB_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM}, 0x04010000, 0xFFE0E000, .SVE, {}},
		{.SVE_SUB_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x04410000, 0xFFE0E000, .SVE, {}},
		{.SVE_SUB_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x04810000, 0xFFE0E000, .SVE, {}},
		{.SVE_SUB_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x04C10000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_SUBR_PRED = {
		{.SVE_SUBR_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM}, 0x04030000, 0xFFE0E000, .SVE, {}},
		{.SVE_SUBR_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x04430000, 0xFFE0E000, .SVE, {}},
		{.SVE_SUBR_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x04830000, 0xFFE0E000, .SVE, {}},
		{.SVE_SUBR_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x04C30000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_MUL_PRED = {
		{.SVE_MUL_PRED,   {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM}, 0x04100000, 0xFFE0E000, .SVE, {}},
		{.SVE_MUL_PRED,   {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x04500000, 0xFFE0E000, .SVE, {}},
		{.SVE_MUL_PRED,   {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x04900000, 0xFFE0E000, .SVE, {}},
		{.SVE_MUL_PRED,   {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x04D00000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_SMULH_PRED = {
		{.SVE_SMULH_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM}, 0x04120000, 0xFFE0E000, .SVE, {}},
		{.SVE_SMULH_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x04520000, 0xFFE0E000, .SVE, {}},
		{.SVE_SMULH_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x04920000, 0xFFE0E000, .SVE, {}},
		{.SVE_SMULH_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x04D20000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_UMULH_PRED = {
		{.SVE_UMULH_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM}, 0x04130000, 0xFFE0E000, .SVE, {}},
		{.SVE_UMULH_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x04530000, 0xFFE0E000, .SVE, {}},
		{.SVE_UMULH_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x04930000, 0xFFE0E000, .SVE, {}},
		{.SVE_UMULH_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x04D30000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_SDIV_PRED = {
		{.SVE_SDIV_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x04940000, 0xFFE0E000, .SVE, {}},
		{.SVE_SDIV_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x04D40000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_UDIV_PRED = {
		{.SVE_UDIV_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x04950000, 0xFFE0E000, .SVE, {}},
		{.SVE_UDIV_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x04D50000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_SMAX_PRED = {
		{.SVE_SMAX_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM}, 0x04080000, 0xFFE0E000, .SVE, {}},
		{.SVE_SMAX_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x04480000, 0xFFE0E000, .SVE, {}},
		{.SVE_SMAX_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x04880000, 0xFFE0E000, .SVE, {}},
		{.SVE_SMAX_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x04C80000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_UMAX_PRED = {
		{.SVE_UMAX_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM}, 0x04090000, 0xFFE0E000, .SVE, {}},
		{.SVE_UMAX_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x04490000, 0xFFE0E000, .SVE, {}},
		{.SVE_UMAX_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x04890000, 0xFFE0E000, .SVE, {}},
		{.SVE_UMAX_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x04C90000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_SMIN_PRED = {
		{.SVE_SMIN_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM}, 0x040A0000, 0xFFE0E000, .SVE, {}},
		{.SVE_SMIN_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x044A0000, 0xFFE0E000, .SVE, {}},
		{.SVE_SMIN_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x048A0000, 0xFFE0E000, .SVE, {}},
		{.SVE_SMIN_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x04CA0000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_UMIN_PRED = {
		{.SVE_UMIN_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM}, 0x040B0000, 0xFFE0E000, .SVE, {}},
		{.SVE_UMIN_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x044B0000, 0xFFE0E000, .SVE, {}},
		{.SVE_UMIN_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x048B0000, 0xFFE0E000, .SVE, {}},
		{.SVE_UMIN_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x04CB0000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_SABD_PRED = {
		{.SVE_SABD_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM}, 0x040C0000, 0xFFE0E000, .SVE, {}},
		{.SVE_SABD_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x044C0000, 0xFFE0E000, .SVE, {}},
		{.SVE_SABD_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x048C0000, 0xFFE0E000, .SVE, {}},
		{.SVE_SABD_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x04CC0000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_UABD_PRED = {
		{.SVE_UABD_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM}, 0x040D0000, 0xFFE0E000, .SVE, {}},
		{.SVE_UABD_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x044D0000, 0xFFE0E000, .SVE, {}},
		{.SVE_UABD_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x048D0000, 0xFFE0E000, .SVE, {}},
		{.SVE_UABD_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x04CD0000, 0xFFE0E000, .SVE, {is_64=true}},
	},

	// -------------------------------------------------------------------------
	// §23.3 Bitwise predicated (AND/ORR/EOR/BIC Zdn.D, Pg/M, Zdn.D, Zm.D)
	//   00000100 011 opc 001 Pg Zm Zdn        (size always 11 = D for the
	//                                          element-agnostic logical forms)
	// -------------------------------------------------------------------------
	.SVE_AND_PRED = { {.SVE_AND_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x041A0000, 0xFFFFE000, .SVE, {is_64=true}} },
	.SVE_ORR_PRED = { {.SVE_ORR_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x04180000, 0xFFFFE000, .SVE, {is_64=true}} },
	.SVE_EOR_PRED = { {.SVE_EOR_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x04190000, 0xFFFFE000, .SVE, {is_64=true}} },
	.SVE_BIC_PRED = { {.SVE_BIC_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x041B0000, 0xFFFFE000, .SVE, {is_64=true}} },

	// -------------------------------------------------------------------------
	// §23.4 Shifts predicated (ASR/LSR/LSL Zdn, Pg/M, Zdn, Zm)
	//   00000100 SS 010 opc 100 Pg Zm Zdn
	// -------------------------------------------------------------------------
	.SVE_ASR_PRED = {
		{.SVE_ASR_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM}, 0x04108000, 0xFFE0E000, .SVE, {}},
		{.SVE_ASR_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x04508000, 0xFFE0E000, .SVE, {}},
		{.SVE_ASR_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x04908000, 0xFFE0E000, .SVE, {}},
		{.SVE_ASR_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x04D08000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_LSR_PRED = {
		{.SVE_LSR_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM}, 0x04118000, 0xFFE0E000, .SVE, {}},
		{.SVE_LSR_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x04518000, 0xFFE0E000, .SVE, {}},
		{.SVE_LSR_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x04918000, 0xFFE0E000, .SVE, {}},
		{.SVE_LSR_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x04D18000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_LSL_PRED = {
		{.SVE_LSL_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VM}, 0x04138000, 0xFFE0E000, .SVE, {}},
		{.SVE_LSL_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x04538000, 0xFFE0E000, .SVE, {}},
		{.SVE_LSL_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x04938000, 0xFFE0E000, .SVE, {}},
		{.SVE_LSL_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x04D38000, 0xFFE0E000, .SVE, {is_64=true}},
	},

	// -------------------------------------------------------------------------
	// §23.5 Unary integer predicated
	//   ABS / NEG / CLS / CLZ / CNT / NOT  Zd.T, Pg/M, Zn.T
	//   00000100 SS 010 opc 101 Pg Zn Zd
	// -------------------------------------------------------------------------
	.SVE_ABS_PRED = {
		{.SVE_ABS_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .NONE}, {.VD, .PG, .VN, .NONE}, 0x0416A000, 0xFFE0E000, .SVE, {}},
		{.SVE_ABS_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN, .NONE}, 0x0456A000, 0xFFE0E000, .SVE, {}},
		{.SVE_ABS_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN, .NONE}, 0x0496A000, 0xFFE0E000, .SVE, {}},
		{.SVE_ABS_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN, .NONE}, 0x04D6A000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_NEG_PRED = {
		{.SVE_NEG_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .NONE}, {.VD, .PG, .VN, .NONE}, 0x0417A000, 0xFFE0E000, .SVE, {}},
		{.SVE_NEG_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN, .NONE}, 0x0457A000, 0xFFE0E000, .SVE, {}},
		{.SVE_NEG_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN, .NONE}, 0x0497A000, 0xFFE0E000, .SVE, {}},
		{.SVE_NEG_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN, .NONE}, 0x04D7A000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_CLS_PRED = {
		{.SVE_CLS_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .NONE}, {.VD, .PG, .VN, .NONE}, 0x0418A000, 0xFFE0E000, .SVE, {}},
		{.SVE_CLS_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN, .NONE}, 0x0458A000, 0xFFE0E000, .SVE, {}},
		{.SVE_CLS_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN, .NONE}, 0x0498A000, 0xFFE0E000, .SVE, {}},
		{.SVE_CLS_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN, .NONE}, 0x04D8A000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_CLZ_PRED = {
		{.SVE_CLZ_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .NONE}, {.VD, .PG, .VN, .NONE}, 0x0419A000, 0xFFE0E000, .SVE, {}},
		{.SVE_CLZ_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN, .NONE}, 0x0459A000, 0xFFE0E000, .SVE, {}},
		{.SVE_CLZ_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN, .NONE}, 0x0499A000, 0xFFE0E000, .SVE, {}},
		{.SVE_CLZ_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN, .NONE}, 0x04D9A000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_CNT_PRED = {
		{.SVE_CNT_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .NONE}, {.VD, .PG, .VN, .NONE}, 0x041AA000, 0xFFE0E000, .SVE, {}},
		{.SVE_CNT_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN, .NONE}, 0x045AA000, 0xFFE0E000, .SVE, {}},
		{.SVE_CNT_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN, .NONE}, 0x049AA000, 0xFFE0E000, .SVE, {}},
		{.SVE_CNT_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN, .NONE}, 0x04DAA000, 0xFFE0E000, .SVE, {is_64=true}},
	},

	// -------------------------------------------------------------------------
	// §23.6 FP arithmetic vectors unpredicated (FADD/FSUB/FMUL Zd, Zn, Zm)
	//   01100101 SS 0 Zm 000 opc Zn Zd
	// -------------------------------------------------------------------------
	.SVE_FADD_Z = {
		{.SVE_FADD_Z, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65400000, 0xFFE0FC00, .SVE, {}},
		{.SVE_FADD_Z, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65800000, 0xFFE0FC00, .SVE, {}},
		{.SVE_FADD_Z, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65C00000, 0xFFE0FC00, .SVE, {is_64=true}},
	},
	.SVE_FSUB_Z = {
		{.SVE_FSUB_Z, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65400400, 0xFFE0FC00, .SVE, {}},
		{.SVE_FSUB_Z, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65800400, 0xFFE0FC00, .SVE, {}},
		{.SVE_FSUB_Z, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65C00400, 0xFFE0FC00, .SVE, {is_64=true}},
	},
	.SVE_FMUL_Z = {
		{.SVE_FMUL_Z, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65400800, 0xFFE0FC00, .SVE, {}},
		{.SVE_FMUL_Z, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65800800, 0xFFE0FC00, .SVE, {}},
		{.SVE_FMUL_Z, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65C00800, 0xFFE0FC00, .SVE, {is_64=true}},
	},
	.SVE_FRECPS = {
		{.SVE_FRECPS, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65401800, 0xFFE0FC00, .SVE, {}},
		{.SVE_FRECPS, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65801800, 0xFFE0FC00, .SVE, {}},
		{.SVE_FRECPS, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65C01800, 0xFFE0FC00, .SVE, {is_64=true}},
	},
	.SVE_FRSQRTS = {
		{.SVE_FRSQRTS, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65401C00, 0xFFE0FC00, .SVE, {}},
		{.SVE_FRSQRTS, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65801C00, 0xFFE0FC00, .SVE, {}},
		{.SVE_FRSQRTS, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65C01C00, 0xFFE0FC00, .SVE, {is_64=true}},
	},
	.SVE_FTSMUL = {
		{.SVE_FTSMUL, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65400C00, 0xFFE0FC00, .SVE, {}},
		{.SVE_FTSMUL, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65800C00, 0xFFE0FC00, .SVE, {}},
		{.SVE_FTSMUL, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65C00C00, 0xFFE0FC00, .SVE, {is_64=true}},
	},

	// -------------------------------------------------------------------------
	// §23.7 FP arithmetic predicated (FADD/FSUB/FMUL Zdn, Pg/M, Zdn, Zm)
	//   01100101 SS 0 opc 100 Pg Zm Zdn
	// -------------------------------------------------------------------------
	.SVE_FADD_PRED = {
		{.SVE_FADD_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x65408000, 0xFFE0E000, .SVE, {}},
		{.SVE_FADD_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x65808000, 0xFFE0E000, .SVE, {}},
		{.SVE_FADD_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x65C08000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_FSUB_PRED = {
		{.SVE_FSUB_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x65418000, 0xFFE0E000, .SVE, {}},
		{.SVE_FSUB_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x65818000, 0xFFE0E000, .SVE, {}},
		{.SVE_FSUB_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x65C18000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_FMUL_PRED = {
		{.SVE_FMUL_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x65428000, 0xFFE0E000, .SVE, {}},
		{.SVE_FMUL_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x65828000, 0xFFE0E000, .SVE, {}},
		{.SVE_FMUL_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x65C28000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_FDIV_PRED = {
		{.SVE_FDIV_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x654D8000, 0xFFE0E000, .SVE, {}},
		{.SVE_FDIV_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x658D8000, 0xFFE0E000, .SVE, {}},
		{.SVE_FDIV_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x65CD8000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_FMAX_PRED = {
		{.SVE_FMAX_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x65468000, 0xFFE0E000, .SVE, {}},
		{.SVE_FMAX_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x65868000, 0xFFE0E000, .SVE, {}},
		{.SVE_FMAX_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x65C68000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_FMIN_PRED = {
		{.SVE_FMIN_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x65478000, 0xFFE0E000, .SVE, {}},
		{.SVE_FMIN_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x65878000, 0xFFE0E000, .SVE, {}},
		{.SVE_FMIN_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x65C78000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_FMAXNM_PRED = {
		{.SVE_FMAXNM_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x65448000, 0xFFE0E000, .SVE, {}},
		{.SVE_FMAXNM_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x65848000, 0xFFE0E000, .SVE, {}},
		{.SVE_FMAXNM_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x65C48000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_FMINNM_PRED = {
		{.SVE_FMINNM_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x65458000, 0xFFE0E000, .SVE, {}},
		{.SVE_FMINNM_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VM}, 0x65858000, 0xFFE0E000, .SVE, {}},
		{.SVE_FMINNM_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VM}, 0x65C58000, 0xFFE0E000, .SVE, {is_64=true}},
	},

	// FP unary predicated (FABS/FNEG/FSQRT Zd, Pg/M, Zn)
	.SVE_FABS_Z = {
		{.SVE_FABS_Z, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN, .NONE}, 0x045CA000, 0xFFE0E000, .SVE, {}},
		{.SVE_FABS_Z, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN, .NONE}, 0x049CA000, 0xFFE0E000, .SVE, {}},
		{.SVE_FABS_Z, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN, .NONE}, 0x04DCA000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_FNEG_Z = {
		{.SVE_FNEG_Z, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN, .NONE}, 0x045DA000, 0xFFE0E000, .SVE, {}},
		{.SVE_FNEG_Z, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN, .NONE}, 0x049DA000, 0xFFE0E000, .SVE, {}},
		{.SVE_FNEG_Z, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN, .NONE}, 0x04DDA000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_FSQRT_Z = {
		{.SVE_FSQRT_Z, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN, .NONE}, 0x654DA000, 0xFFE0E000, .SVE, {}},
		{.SVE_FSQRT_Z, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN, .NONE}, 0x658DA000, 0xFFE0E000, .SVE, {}},
		{.SVE_FSQRT_Z, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN, .NONE}, 0x65CDA000, 0xFFE0E000, .SVE, {is_64=true}},
	},

	// -------------------------------------------------------------------------
	// §23.8 FP fused multiply-accumulate (predicated)
	//   FMLA  Zda, Pg/M, Zn, Zm
	//   01100101 SS 1 Zm 000 Pg Zn Zda     (FMLA)
	//   01100101 SS 1 Zm 001 Pg Zn Zda     (FMLS)
	//   01100101 SS 1 Zm 010 Pg Zn Zda     (FNMLA)
	//   01100101 SS 1 Zm 011 Pg Zn Zda     (FNMLS)
	// -------------------------------------------------------------------------
	.SVE_FMLA = {
		{.SVE_FMLA, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VN, .VM}, 0x65600000, 0xFFE0E000, .SVE, {}},
		{.SVE_FMLA, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VN, .VM}, 0x65A00000, 0xFFE0E000, .SVE, {}},
		{.SVE_FMLA, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VN, .VM}, 0x65E00000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_FMLS = {
		{.SVE_FMLS, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VN, .VM}, 0x65602000, 0xFFE0E000, .SVE, {}},
		{.SVE_FMLS, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VN, .VM}, 0x65A02000, 0xFFE0E000, .SVE, {}},
		{.SVE_FMLS, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VN, .VM}, 0x65E02000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_FNMLA = {
		{.SVE_FNMLA, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VN, .VM}, 0x65604000, 0xFFE0E000, .SVE, {}},
		{.SVE_FNMLA, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VN, .VM}, 0x65A04000, 0xFFE0E000, .SVE, {}},
		{.SVE_FNMLA, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VN, .VM}, 0x65E04000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_FNMLS = {
		{.SVE_FNMLS, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VN, .VM}, 0x65606000, 0xFFE0E000, .SVE, {}},
		{.SVE_FNMLS, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VN, .VM}, 0x65A06000, 0xFFE0E000, .SVE, {}},
		{.SVE_FNMLS, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VN, .VM}, 0x65E06000, 0xFFE0E000, .SVE, {is_64=true}},
	},

	// -------------------------------------------------------------------------
	// §23.9 Predicate logical operations (Pd.B, Pg/Z, Pn.B, Pm.B)
	//   00100101 SS 0 Pm o1 Pg o2 Pn O Pd   (SS=00 typically; opc differentiates)
	//   AND/BIC/ORR/EOR + NAND/NOR/ORN/SEL, with optional S setting flags
	// -------------------------------------------------------------------------
	.SVE_AND_P  = { {.SVE_AND_P,  {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25004000, 0xFFE0C210, .SVE, {}} },
	.SVE_BIC_P  = { {.SVE_BIC_P,  {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25004010, 0xFFE0C210, .SVE, {}} },
	.SVE_ORR_P  = { {.SVE_ORR_P,  {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25804000, 0xFFE0C210, .SVE, {}} },
	.SVE_ORN_P  = { {.SVE_ORN_P,  {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25804010, 0xFFE0C210, .SVE, {}} },
	.SVE_EOR_P  = { {.SVE_EOR_P,  {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25004200, 0xFFE0C210, .SVE, {}} },
	.SVE_NAND_P = { {.SVE_NAND_P, {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25804210, 0xFFE0C210, .SVE, {}} },
	.SVE_NOR_P  = { {.SVE_NOR_P,  {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25804200, 0xFFE0C210, .SVE, {}} },
	.SVE_SEL_P  = { {.SVE_SEL_P,  {.P_REG, .P_REG,      .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25004210, 0xFFE0C210, .SVE, {}} },

	// Flag-setting variants
	.SVE_ANDS_P  = { {.SVE_ANDS_P,  {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25404000, 0xFFE0C210, .SVE, {sets_flags=true}} },
	.SVE_BICS_P  = { {.SVE_BICS_P,  {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25404010, 0xFFE0C210, .SVE, {sets_flags=true}} },
	.SVE_ORRS_P  = { {.SVE_ORRS_P,  {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25C04000, 0xFFE0C210, .SVE, {sets_flags=true}} },
	.SVE_EORS_P  = { {.SVE_EORS_P,  {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25404200, 0xFFE0C210, .SVE, {sets_flags=true}} },

	// -------------------------------------------------------------------------
	// §23.10 PTRUE/PFALSE/PFIRST/PNEXT
	// -------------------------------------------------------------------------
	//   PTRUE  Pd.T, pattern   = 00100101 SS 011000 1110 0 pattern 0 Pd
	//   PFALSE Pd.B            = 00100101 0001 1000 1110 0100 0000 Pd
	//   PFIRST Pdn.B, Pg, Pdn.B = 00100101 0101 1000 1100 000 Pg Pdn
	//   PNEXT  Pdn.T, Pg, Pdn.T = 00100101 SS 011001 1100 010 Pg 0000 Pdn
	.SVE_PTRUE = {
		{.SVE_PTRUE, {.P_REG, .SVE_PATTERN, .NONE, .NONE}, {.PD, .SVE_PATTERN, .NONE, .NONE}, 0x2518E000, 0xFFFFFC10, .SVE, {}},
	},
	.SVE_PTRUES = {
		{.SVE_PTRUES, {.P_REG, .SVE_PATTERN, .NONE, .NONE}, {.PD, .SVE_PATTERN, .NONE, .NONE}, 0x2519E000, 0xFFFFFC10, .SVE, {sets_flags=true}},
	},
	.SVE_PFALSE = {
		{.SVE_PFALSE, {.P_REG, .NONE, .NONE, .NONE}, {.PD, .NONE, .NONE, .NONE}, 0x2518E400, 0xFFFFFFF0, .SVE, {}},
	},
	.SVE_PFIRST = {
		{.SVE_PFIRST, {.P_REG, .P_REG, .P_REG, .NONE}, {.PD, .PN, .PD, .NONE}, 0x2558C000, 0xFFFFFE10, .SVE, {}},
	},
	.SVE_PNEXT = {
		{.SVE_PNEXT, {.P_REG, .P_REG, .P_REG, .NONE}, {.PD, .PN, .PD, .NONE}, 0x2519C400, 0xFFFFFE10, .SVE, {}},
	},

	// -------------------------------------------------------------------------
	// SVE alias / copy / permute stragglers (duplicated-field encodings).
	// -------------------------------------------------------------------------
	// CPY (predicated, from general register): Zd.T, Pg/m, Wn/Xn.
	.SVE_CPY_Z = {
		{.SVE_CPY_Z, {.Z_REG_B, .P_REG_MERGE, .W_REG, .NONE}, {.VD, .PG, .VN, .NONE}, 0x0528A000, 0xFFFFE000, .SVE, {}},
		{.SVE_CPY_Z, {.Z_REG_H, .P_REG_MERGE, .W_REG, .NONE}, {.VD, .PG, .VN, .NONE}, 0x0568A000, 0xFFFFE000, .SVE, {}},
		{.SVE_CPY_Z, {.Z_REG_S, .P_REG_MERGE, .W_REG, .NONE}, {.VD, .PG, .VN, .NONE}, 0x05A8A000, 0xFFFFE000, .SVE, {}},
		{.SVE_CPY_Z, {.Z_REG_D, .P_REG_MERGE, .X_REG, .NONE}, {.VD, .PG, .VN, .NONE}, 0x05E8A000, 0xFFFFE000, .SVE, {is_64=true}},
	},
	// EXT (destructive vector extract): Zdn.B, Zdn.B, Zm.B, #imm (imm8 split).
	.SVE_EXT_Z = { {.SVE_EXT_Z, {.Z_REG_B, .Z_REG_B, .Z_REG_B, .VEC_SHIFT}, {.VD, .VD, .VN, .SVE_EXT_IMM}, 0x05200000, 0xFFE0E000, .SVE, {}} },
	// MOV (predicated, = SEL Zd, Pg, Zn, Zd): Zd.T, Pg/m, Zn.T.
	.SVE_MOV_PRED = {
		{.SVE_MOV_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .NONE}, {.ZD_ZM_DUP, .PG, .VN, .NONE}, 0x0520C000, 0xFFE0E000, .SVE, {}},
		{.SVE_MOV_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.ZD_ZM_DUP, .PG, .VN, .NONE}, 0x0560C000, 0xFFE0E000, .SVE, {}},
		{.SVE_MOV_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.ZD_ZM_DUP, .PG, .VN, .NONE}, 0x05A0C000, 0xFFE0E000, .SVE, {}},
		{.SVE_MOV_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.ZD_ZM_DUP, .PG, .VN, .NONE}, 0x05E0C000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	// Predicate aliases (EOR/ORR/AND with a duplicated predicate field).
	.SVE_NOT_P  = { {.SVE_NOT_P,  {.P_REG, .P_REG_ZERO, .P_REG, .NONE}, {.PD, .PG4_PM_DUP, .PN, .NONE}, 0x25004200, 0xFFE0C210, .SVE, {}} },
	.SVE_MOVS_P = { {.SVE_MOVS_P, {.P_REG, .P_REG_ZERO, .P_REG, .NONE}, {.PD, .PG4, .PN_PM_DUP, .NONE}, 0x25404000, 0xFFE0C210, .SVE, {sets_flags=true}} },
	.SVE_MOV_P  = {
		{.SVE_MOV_P, {.P_REG, .P_REG_ZERO, .P_REG, .NONE}, {.PD, .PG4, .PN_PM_DUP, .NONE}, 0x25004000, 0xFFE0C210, .SVE, {}},
		{.SVE_MOV_P, {.P_REG, .P_REG, .NONE, .NONE}, {.PD, .PN_PG_PM_DUP, .NONE, .NONE}, 0x25804000, 0xFFE0C210, .SVE, {}},
	},
	// SVE2 XAR (destructive): Zdn.T, Zdn.T, Zm.T, #rotate. The rotate amount is
	// V = 2*esize - amount, split tszh:tszl:imm3; esize selected by the Z type.
	.SVE_XAR_Z = {
		{.SVE_XAR_Z, {.Z_REG_B, .Z_REG_B, .Z_REG_B, .VEC_SHIFT}, {.VD, .VD, .VN, .SVE_XAR_SHIFT}, 0x04203400, 0xFF20FC00, .SVE2, {}},
		{.SVE_XAR_Z, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .VEC_SHIFT}, {.VD, .VD, .VN, .SVE_XAR_SHIFT}, 0x04203400, 0xFF20FC00, .SVE2, {}},
		{.SVE_XAR_Z, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .VEC_SHIFT}, {.VD, .VD, .VN, .SVE_XAR_SHIFT}, 0x04203400, 0xFF20FC00, .SVE2, {}},
		{.SVE_XAR_Z, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .VEC_SHIFT}, {.VD, .VD, .VN, .SVE_XAR_SHIFT}, 0x04203400, 0xFF20FC00, .SVE2, {is_64=true}},
	},

	// -------------------------------------------------------------------------
	// §23.11 Integer compare (Zn vs Zm) -> Pd.T
	//   CMPEQ Pd.T, Pg/Z, Zn.T, Zm.T  = 00100100 SS 1 Zm 101 Pg Zn O Pd
	//   opc bits at 15:13 distinguish HI/HS/EQ/NE/GE/GT/LE/LT
	// -------------------------------------------------------------------------
	.SVE_CMPEQ = {
		{.SVE_CMPEQ, {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VN, .VM}, 0x2400A000, 0xFFE0E000, .SVE, {sets_flags=true}},
		{.SVE_CMPEQ, {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x2440A000, 0xFFE0E000, .SVE, {sets_flags=true}},
		{.SVE_CMPEQ, {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VN, .VM}, 0x2480A000, 0xFFE0E000, .SVE, {sets_flags=true}},
		{.SVE_CMPEQ, {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VN, .VM}, 0x24C0A000, 0xFFE0E000, .SVE, {sets_flags=true, is_64=true}},
	},
	.SVE_CMPNE = {
		{.SVE_CMPNE, {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VN, .VM}, 0x2400A010, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPNE, {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x2440A010, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPNE, {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VN, .VM}, 0x2480A010, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPNE, {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VN, .VM}, 0x24C0A010, 0xFFE0E010, .SVE, {sets_flags=true, is_64=true}},
	},
	.SVE_CMPGE = {
		{.SVE_CMPGE, {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VN, .VM}, 0x24008000, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPGE, {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x24408000, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPGE, {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VN, .VM}, 0x24808000, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPGE, {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VN, .VM}, 0x24C08000, 0xFFE0E010, .SVE, {sets_flags=true, is_64=true}},
	},
	.SVE_CMPGT = {
		{.SVE_CMPGT, {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VN, .VM}, 0x24008010, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPGT, {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x24408010, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPGT, {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VN, .VM}, 0x24808010, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPGT, {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VN, .VM}, 0x24C08010, 0xFFE0E010, .SVE, {sets_flags=true, is_64=true}},
	},
	.SVE_CMPHI = {
		{.SVE_CMPHI, {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VN, .VM}, 0x24000010, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPHI, {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x24400010, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPHI, {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VN, .VM}, 0x24800010, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPHI, {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VN, .VM}, 0x24C00010, 0xFFE0E010, .SVE, {sets_flags=true, is_64=true}},
	},
	.SVE_CMPHS = {
		{.SVE_CMPHS, {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VN, .VM}, 0x24000000, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPHS, {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x24400000, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPHS, {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VN, .VM}, 0x24800000, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPHS, {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VN, .VM}, 0x24C00000, 0xFFE0E010, .SVE, {sets_flags=true, is_64=true}},
	},

	// -------------------------------------------------------------------------
	// §23.12 SVE DUP / INSR / REV / TBL
	// -------------------------------------------------------------------------
	//   DUP Zd.T, Zn.T[imm] = 00000101 SS 1 imm 001000 Zn Zd  (broadcast lane)
	//   INSR Zd.T, Rn       = 00000101 SS 1 00100 001110 Rn Zd
	//   REV  Pd.T, Pn.T     = 00000101 SS 11 0100 010 0000 Pn Pd
	//   REV  Zd.T, Zn.T     = 00000101 SS 11 1000 001110 Zn Zd
	.SVE_DUP_Z = {
		// Broadcast a GPR (DUP Zd.B, Wn): 00000101 SS 1 00 000 001110 Rn Zd
		{.SVE_DUP_Z, {.Z_REG_B, .W_REG, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x05203800, 0xFFFFFC00, .SVE, {}},
		{.SVE_DUP_Z, {.Z_REG_H, .W_REG, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x05603800, 0xFFFFFC00, .SVE, {}},
		{.SVE_DUP_Z, {.Z_REG_S, .W_REG, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x05A03800, 0xFFFFFC00, .SVE, {}},
		{.SVE_DUP_Z, {.Z_REG_D, .X_REG, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x05E03800, 0xFFFFFC00, .SVE, {is_64=true}},
	},
	.SVE_REV_Z = {
		{.SVE_REV_Z, {.Z_REG_B, .Z_REG_B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x05383800, 0xFFFFFC00, .SVE, {}},
		{.SVE_REV_Z, {.Z_REG_H, .Z_REG_H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x05783800, 0xFFFFFC00, .SVE, {}},
		{.SVE_REV_Z, {.Z_REG_S, .Z_REG_S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x05B83800, 0xFFFFFC00, .SVE, {}},
		{.SVE_REV_Z, {.Z_REG_D, .Z_REG_D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x05F83800, 0xFFFFFC00, .SVE, {is_64=true}},
	},
	.SVE_REV_P = {
		{.SVE_REV_P, {.P_REG, .P_REG, .NONE, .NONE}, {.PD, .PN, .NONE, .NONE}, 0x05344000, 0xFFFFFE10, .SVE, {}},
	},
	.SVE_TBL = {
		{.SVE_TBL, {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05203000, 0xFFE0FC00, .SVE, {}},
		{.SVE_TBL, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05603000, 0xFFE0FC00, .SVE, {}},
		{.SVE_TBL, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05A03000, 0xFFE0FC00, .SVE, {}},
		{.SVE_TBL, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05E03000, 0xFFE0FC00, .SVE, {is_64=true}},
	},

	// -------------------------------------------------------------------------
	// §23.13 Permute (ZIP1/2, UZP1/2, TRN1/2) for Z and P registers
	//   00000101 SS 1 Zm 011 oo o Zn Zd  (Z variants; oo=00 ZIP1, 01 ZIP2, etc.)
	//   00000101 SS 1 0 Pm 010 oo o Pn 0 Pd (P variants)
	// -------------------------------------------------------------------------
	.SVE_ZIP1_Z = {
		{.SVE_ZIP1_Z, {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05206000, 0xFFE0FC00, .SVE, {}},
		{.SVE_ZIP1_Z, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05606000, 0xFFE0FC00, .SVE, {}},
		{.SVE_ZIP1_Z, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05A06000, 0xFFE0FC00, .SVE, {}},
		{.SVE_ZIP1_Z, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05E06000, 0xFFE0FC00, .SVE, {is_64=true}},
	},
	.SVE_ZIP2_Z = {
		{.SVE_ZIP2_Z, {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05206400, 0xFFE0FC00, .SVE, {}},
		{.SVE_ZIP2_Z, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05606400, 0xFFE0FC00, .SVE, {}},
		{.SVE_ZIP2_Z, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05A06400, 0xFFE0FC00, .SVE, {}},
		{.SVE_ZIP2_Z, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05E06400, 0xFFE0FC00, .SVE, {is_64=true}},
	},
	.SVE_UZP1_Z = {
		{.SVE_UZP1_Z, {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05206800, 0xFFE0FC00, .SVE, {}},
		{.SVE_UZP1_Z, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05606800, 0xFFE0FC00, .SVE, {}},
		{.SVE_UZP1_Z, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05A06800, 0xFFE0FC00, .SVE, {}},
		{.SVE_UZP1_Z, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05E06800, 0xFFE0FC00, .SVE, {is_64=true}},
	},
	.SVE_UZP2_Z = {
		{.SVE_UZP2_Z, {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05206C00, 0xFFE0FC00, .SVE, {}},
		{.SVE_UZP2_Z, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05606C00, 0xFFE0FC00, .SVE, {}},
		{.SVE_UZP2_Z, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05A06C00, 0xFFE0FC00, .SVE, {}},
		{.SVE_UZP2_Z, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05E06C00, 0xFFE0FC00, .SVE, {is_64=true}},
	},
	.SVE_TRN1_Z = {
		{.SVE_TRN1_Z, {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05207000, 0xFFE0FC00, .SVE, {}},
		{.SVE_TRN1_Z, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05607000, 0xFFE0FC00, .SVE, {}},
		{.SVE_TRN1_Z, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05A07000, 0xFFE0FC00, .SVE, {}},
		{.SVE_TRN1_Z, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05E07000, 0xFFE0FC00, .SVE, {is_64=true}},
	},
	.SVE_TRN2_Z = {
		{.SVE_TRN2_Z, {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05207400, 0xFFE0FC00, .SVE, {}},
		{.SVE_TRN2_Z, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05607400, 0xFFE0FC00, .SVE, {}},
		{.SVE_TRN2_Z, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05A07400, 0xFFE0FC00, .SVE, {}},
		{.SVE_TRN2_Z, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05E07400, 0xFFE0FC00, .SVE, {is_64=true}},
	},

	// P-register permutes
	.SVE_ZIP1_P = { {.SVE_ZIP1_P, {.P_REG, .P_REG, .P_REG, .NONE}, {.PD, .PN, .PM, .NONE}, 0x05204000, 0xFFE0FE10, .SVE, {}} },
	.SVE_ZIP2_P = { {.SVE_ZIP2_P, {.P_REG, .P_REG, .P_REG, .NONE}, {.PD, .PN, .PM, .NONE}, 0x05204400, 0xFFE0FE10, .SVE, {}} },
	.SVE_UZP1_P = { {.SVE_UZP1_P, {.P_REG, .P_REG, .P_REG, .NONE}, {.PD, .PN, .PM, .NONE}, 0x05204800, 0xFFE0FE10, .SVE, {}} },
	.SVE_UZP2_P = { {.SVE_UZP2_P, {.P_REG, .P_REG, .P_REG, .NONE}, {.PD, .PN, .PM, .NONE}, 0x05204C00, 0xFFE0FE10, .SVE, {}} },
	.SVE_TRN1_P = { {.SVE_TRN1_P, {.P_REG, .P_REG, .P_REG, .NONE}, {.PD, .PN, .PM, .NONE}, 0x05205000, 0xFFE0FE10, .SVE, {}} },
	.SVE_TRN2_P = { {.SVE_TRN2_P, {.P_REG, .P_REG, .P_REG, .NONE}, {.PD, .PN, .PM, .NONE}, 0x05205400, 0xFFE0FE10, .SVE, {}} },

	// -------------------------------------------------------------------------
	// §23.14 Contiguous load/store (scalar+scalar)
	//   LD1B { Zt.T }, Pg/Z, [Xn, Xm]
	//     1010010 0 SS 0 Xm 010 Pg Xn Zt    (size: B=00, H=01, W=10, D=11)
	//   ST1B { Zt.T }, Pg,   [Xn, Xm]
	//     1110010 0 SS 0 Xm 010 Pg Xn Zt
	// -------------------------------------------------------------------------
	.SVE_LD1B = {
		{.SVE_LD1B, {.Z_REG_B, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA4004000, 0xFFE0E000, .SVE, {}},
	},
	.SVE_LD1H = {
		{.SVE_LD1H, {.Z_REG_H, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA4A04000, 0xFFE0E000, .SVE, {}},
	},
	.SVE_LD1W = {
		{.SVE_LD1W, {.Z_REG_S, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA5404000, 0xFFE0E000, .SVE, {}},
	},
	.SVE_LD1D = {
		{.SVE_LD1D, {.Z_REG_D, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA5E04000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_LD1SB = {
		{.SVE_LD1SB, {.Z_REG_H, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA5C04000, 0xFFE0E000, .SVE, {}},
	},
	.SVE_LD1SH = {
		{.SVE_LD1SH, {.Z_REG_S, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA5004000, 0xFFE0E000, .SVE, {}},
	},
	.SVE_LD1SW = {
		{.SVE_LD1SW, {.Z_REG_D, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA4804000, 0xFFE0E000, .SVE, {is_64=true}},
	},
	.SVE_ST1B = {
		{.SVE_ST1B, {.Z_REG_B, .P_REG, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE4004000, 0xFFE0E000, .SVE, {}},
	},
	.SVE_ST1H = {
		{.SVE_ST1H, {.Z_REG_H, .P_REG, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE4A04000, 0xFFE0E000, .SVE, {}},
	},
	.SVE_ST1W = {
		{.SVE_ST1W, {.Z_REG_S, .P_REG, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE5404000, 0xFFE0E000, .SVE, {}},
	},
	.SVE_ST1D = {
		{.SVE_ST1D, {.Z_REG_D, .P_REG, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE5C04000, 0xFFE0E000, .SVE, {is_64=true}},
	},

	// First-faulting (LDFF1*) variants -- same family, bit 23/22 chooses non-fault.
	// Spec uses bits[14:13] = 11 instead of 10 to mark FF; we encode them
	// explicitly so the mnemonic distinguishes the faulting behavior.
	.SVE_LDFF1B = {
		{.SVE_LDFF1B, {.Z_REG_B, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA4006000, 0xFFE0E000, .SVE, {}},
	},
	.SVE_LDFF1H = {
		{.SVE_LDFF1H, {.Z_REG_H, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA4A06000, 0xFFE0E000, .SVE, {}},
	},
	.SVE_LDFF1W = {
		{.SVE_LDFF1W, {.Z_REG_S, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA5406000, 0xFFE0E000, .SVE, {}},
	},
	.SVE_LDFF1D = {
		{.SVE_LDFF1D, {.Z_REG_D, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA5E06000, 0xFFE0E000, .SVE, {is_64=true}},
	},

	// Unpredicated LDR/STR of full Z/P registers (scalar+imm with MUL VL).
	//   LDR Zt, [Xn{, #imm, MUL VL}]   = 10000101 10 imm9 010 Xn Zt
	//   STR Zt, [Xn{, #imm, MUL VL}]   = 11100101 10 imm9 010 Xn Zt
	//   LDR Pt, [Xn{, #imm, MUL VL}]   = 10000101 10 imm9 000 Xn 0 Pt
	.SVE_LDR_Z = { {.SVE_LDR_Z, {.Z_REG_B, .MEM, .NONE, .NONE}, {.VD, .SVE_OFFSET_BASE_SI, .NONE, .NONE}, 0x85804000, 0xFFE0E000, .SVE, {}} },
	.SVE_STR_Z = { {.SVE_STR_Z, {.Z_REG_B, .MEM, .NONE, .NONE}, {.VD, .SVE_OFFSET_BASE_SI, .NONE, .NONE}, 0xE5804000, 0xFFE0E000, .SVE, {}} },
	.SVE_LDR_P = { {.SVE_LDR_P, {.P_REG,   .MEM, .NONE, .NONE}, {.PD, .SVE_OFFSET_BASE_SI, .NONE, .NONE}, 0x85800000, 0xFFE0E010, .SVE, {}} },
	.SVE_STR_P = { {.SVE_STR_P, {.P_REG,   .MEM, .NONE, .NONE}, {.PD, .SVE_OFFSET_BASE_SI, .NONE, .NONE}, 0xE5800000, 0xFFE0E010, .SVE, {}} },

	// -------------------------------------------------------------------------
	// §23.15 SVE2 -- WHILE family (Pd, Xn, Xm)
	//   WHILELT Pd.T, Wn, Wm = 00100101 SS 1 Rm 0 0 0 1 0 0 Rn 0 0000 Pd
	//   We encode the X variant (sf=1, bit 12 in original spec) for 64-bit.
	// -------------------------------------------------------------------------
	.SVE_WHILELT = {
		{.SVE_WHILELT, {.P_REG, .X_REG, .X_REG, .NONE}, {.PD, .RN, .RM, .NONE}, 0x25201400, 0xFF20FC10, .SVE2, {sets_flags=true, is_64=true}},
	},
	.SVE_WHILELE = {
		{.SVE_WHILELE, {.P_REG, .X_REG, .X_REG, .NONE}, {.PD, .RN, .RM, .NONE}, 0x25201410, 0xFF20FC10, .SVE2, {sets_flags=true, is_64=true}},
	},
	.SVE_WHILELO = {
		{.SVE_WHILELO, {.P_REG, .X_REG, .X_REG, .NONE}, {.PD, .RN, .RM, .NONE}, 0x25201C00, 0xFF20FC10, .SVE2, {sets_flags=true, is_64=true}},
	},
	.SVE_WHILELS = {
		{.SVE_WHILELS, {.P_REG, .X_REG, .X_REG, .NONE}, {.PD, .RN, .RM, .NONE}, 0x25201C10, 0xFF20FC10, .SVE2, {sets_flags=true, is_64=true}},
	},
	.SVE_WHILEGE = {
		{.SVE_WHILEGE, {.P_REG, .X_REG, .X_REG, .NONE}, {.PD, .RN, .RM, .NONE}, 0x25201000, 0xFF20FC10, .SVE2, {sets_flags=true, is_64=true}},
	},
	.SVE_WHILEGT = {
		{.SVE_WHILEGT, {.P_REG, .X_REG, .X_REG, .NONE}, {.PD, .RN, .RM, .NONE}, 0x25201010, 0xFF20FC10, .SVE2, {sets_flags=true, is_64=true}},
	},
	.SVE_WHILEHI = {
		{.SVE_WHILEHI, {.P_REG, .X_REG, .X_REG, .NONE}, {.PD, .RN, .RM, .NONE}, 0x25201810, 0xFF20FC10, .SVE2, {sets_flags=true, is_64=true}},
	},
	.SVE_WHILEHS = {
		{.SVE_WHILEHS, {.P_REG, .X_REG, .X_REG, .NONE}, {.PD, .RN, .RM, .NONE}, 0x25201800, 0xFF20FC10, .SVE2, {sets_flags=true, is_64=true}},
	},

	// -------------------------------------------------------------------------
	// §23.16 SVE2 saturating rounding multiply-accumulate
	//   SQRDMLAH Zda.T, Zn.T, Zm.T   = 01000100 SS 0 Zm 0111 00 Zn Zda
	//   SQRDMLSH Zda.T, Zn.T, Zm.T   = 01000100 SS 0 Zm 0111 01 Zn Zda
	// -------------------------------------------------------------------------
	.SVE_SQRDMLAH = {
		{.SVE_SQRDMLAH, {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x44007000, 0xFFE0FC00, .SVE2, {}},
		{.SVE_SQRDMLAH, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x44407000, 0xFFE0FC00, .SVE2, {}},
		{.SVE_SQRDMLAH, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x44807000, 0xFFE0FC00, .SVE2, {}},
		{.SVE_SQRDMLAH, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x44C07000, 0xFFE0FC00, .SVE2, {is_64=true}},
	},
	.SVE_SQRDMLSH = {
		{.SVE_SQRDMLSH, {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x44007400, 0xFFE0FC00, .SVE2, {}},
		{.SVE_SQRDMLSH, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x44407400, 0xFFE0FC00, .SVE2, {}},
		{.SVE_SQRDMLSH, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x44807400, 0xFFE0FC00, .SVE2, {}},
		{.SVE_SQRDMLSH, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x44C07400, 0xFFE0FC00, .SVE2, {is_64=true}},
	},

	// SVE2 Add/sub with carry (long), AESE/AESD/AESMC/AESIMC SVE2 forms
	.SVE_ADCLB = {
		{.SVE_ADCLB, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4500D000, 0xFFE0FC00, .SVE2, {}},
		{.SVE_ADCLB, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4540D000, 0xFFE0FC00, .SVE2, {is_64=true}},
	},
	.SVE_ADCLT = {
		{.SVE_ADCLT, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4500D400, 0xFFE0FC00, .SVE2, {}},
		{.SVE_ADCLT, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4540D400, 0xFFE0FC00, .SVE2, {is_64=true}},
	},
	.SVE_SBCLB = {
		{.SVE_SBCLB, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4580D000, 0xFFE0FC00, .SVE2, {}},
		{.SVE_SBCLB, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x45C0D000, 0xFFE0FC00, .SVE2, {is_64=true}},
	},
	.SVE_SBCLT = {
		{.SVE_SBCLT, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4580D400, 0xFFE0FC00, .SVE2, {}},
		{.SVE_SBCLT, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x45C0D400, 0xFFE0FC00, .SVE2, {is_64=true}},
	},

	.SVE_MATCH = {
		{.SVE_MATCH,  {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VN, .VM}, 0x45208000, 0xFFE0E010, .SVE2, {sets_flags=true}},
		{.SVE_MATCH,  {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x45608000, 0xFFE0E010, .SVE2, {sets_flags=true}},
	},
	.SVE_NMATCH = {
		{.SVE_NMATCH, {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VN, .VM}, 0x45208010, 0xFFE0E010, .SVE2, {sets_flags=true}},
		{.SVE_NMATCH, {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x45608010, 0xFFE0E010, .SVE2, {sets_flags=true}},
	},

	.SVE_TBL2 = {
		{.SVE_TBL2, {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05202800, 0xFFE0FC00, .SVE2, {}},
	},
	.SVE_TBX = {
		{.SVE_TBX,  {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x05202C00, 0xFFE0FC00, .SVE2, {}},
	},

	// SVE2 AES/SM4 (Z-form encryption)
	.SVE_AESE   = { {.SVE_AESE,  {.Z_REG_B, .Z_REG_B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4522E000, 0xFFFFFC00, .SVE2, {}} },
	.SVE_AESD   = { {.SVE_AESD,  {.Z_REG_B, .Z_REG_B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4522E400, 0xFFFFFC00, .SVE2, {}} },
	.SVE_AESMC  = { {.SVE_AESMC, {.Z_REG_B, .NONE, .NONE, .NONE},    {.VD, .NONE, .NONE, .NONE}, 0x4520E000, 0xFFFFFFE0, .SVE2, {}} },
	.SVE_AESIMC = { {.SVE_AESIMC,{.Z_REG_B, .NONE, .NONE, .NONE},    {.VD, .NONE, .NONE, .NONE}, 0x4520E400, 0xFFFFFFE0, .SVE2, {}} },

	.SVE_HISTCNT = {
		{.SVE_HISTCNT, {.Z_REG_S, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VN, .VM}, 0x45A0C000, 0xFFE0E000, .SVE2, {}},
		{.SVE_HISTCNT, {.Z_REG_D, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VN, .VM}, 0x45E0C000, 0xFFE0E000, .SVE2, {is_64=true}},
	},
	.SVE_HISTSEG = {
		{.SVE_HISTSEG, {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4520A000, 0xFFE0FC00, .SVE2, {}},
	},

	// -------------------------------------------------------------------------
	// §24 SME (Scalable Matrix Extension)
	// -------------------------------------------------------------------------
	//   SMSTART / SMSTOP control PSTATE.SM and PSTATE.ZA.
	//   SMSTART  = D503447F (default = both SM + ZA on)
	//   SMSTOP   = D503467F
	//
	//   These are hint-encoded as MSR (immediate) writes to SVCR.

	.SME_SMSTART = { {.SME_SMSTART, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD503477F, 0xFFFFFFFF, .SME, {}} },
	.SME_SMSTOP  = { {.SME_SMSTOP,  {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0xD503467F, 0xFFFFFFFF, .SME, {}} },

	// RDSVL Xd, #imm6 -- read streaming-mode vector length (in bytes) * imm6.
	//   00000100 10111111 010101 imm6 Xd
	.SME_RDSVL = {
		{.SME_RDSVL, {.X_REG, .IMM_6, .NONE, .NONE}, {.RD, .IMM6, .NONE, .NONE}, 0x04BF5800, 0xFFFFFC00, .SME, {is_64=true}},
	},

	// ZERO {<mask>} -- zero a list of ZA tiles using the 8-bit list as 4-bit field.
	//   11000000 00000011 00 0 imm4 11 0000 00000
	.SME_ZERO = {
		{.SME_ZERO, {.SME_PATTERN, .NONE, .NONE, .NONE}, {.SME_PATTERN_FIELD, .NONE, .NONE, .NONE}, 0xC0080000, 0xFFFFFF00, .SME, {}},
	},

	// FMOPA ZAd.S, Pn/M, Pm/M, Zn.S, Zm.S  (outer-product accumulate)
	//   10000000 10 0 Zm 0 Pm 0 Pn Zn 0 0000 ZAd
	.SME_FMOPA = {
		{.SME_FMOPA, {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_S}, {.ZA_TILE_NUM_S, .PG, .PM3, .VN}, 0x80800000, 0xFFE08010, .SME, {}},
	},
	.SME_FMOPS = {
		{.SME_FMOPS, {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_S}, {.ZA_TILE_NUM_S, .PG, .PM3, .VN}, 0x80800010, 0xFFE08010, .SME, {}},
	},
	.SME_BFMOPA = {
		{.SME_BFMOPA, {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_H}, {.ZA_TILE_NUM_S, .PG, .PM3, .VN}, 0x81800000, 0xFFE08010, .SME, {}},
	},
	.SME_BFMOPS = {
		{.SME_BFMOPS, {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_H}, {.ZA_TILE_NUM_S, .PG, .PM3, .VN}, 0x81800010, 0xFFE08010, .SME, {}},
	},
	.SME_SMOPA = {
		{.SME_SMOPA, {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_B}, {.ZA_TILE_NUM_S, .PG, .PM3, .VN}, 0xA0800000, 0xFFE08010, .SME, {}},
		{.SME_SMOPA, {.ZA_TILE_D, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_H}, {.ZA_TILE_NUM_D, .PG, .PM3, .VN}, 0xA0C00000, 0xFFE08010, .SME, {is_64=true}},
	},
	.SME_SMOPS = {
		{.SME_SMOPS, {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_B}, {.ZA_TILE_NUM_S, .PG, .PM3, .VN}, 0xA0800010, 0xFFE08010, .SME, {}},
		{.SME_SMOPS, {.ZA_TILE_D, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_H}, {.ZA_TILE_NUM_D, .PG, .PM3, .VN}, 0xA0C00010, 0xFFE08010, .SME, {is_64=true}},
	},
	.SME_UMOPA = {
		{.SME_UMOPA, {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_B}, {.ZA_TILE_NUM_S, .PG, .PM3, .VN}, 0xA1A00000, 0xFFE08010, .SME, {}},
		{.SME_UMOPA, {.ZA_TILE_D, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_H}, {.ZA_TILE_NUM_D, .PG, .PM3, .VN}, 0xA1E00000, 0xFFE08010, .SME, {is_64=true}},
	},
	.SME_UMOPS = {
		{.SME_UMOPS, {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_B}, {.ZA_TILE_NUM_S, .PG, .PM3, .VN}, 0xA1A00010, 0xFFE08010, .SME, {}},
		{.SME_UMOPS, {.ZA_TILE_D, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_H}, {.ZA_TILE_NUM_D, .PG, .PM3, .VN}, 0xA1E00010, 0xFFE08010, .SME, {is_64=true}},
	},
	.SME_USMOPA = {
		{.SME_USMOPA, {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_B}, {.ZA_TILE_NUM_S, .PG, .PM3, .VN}, 0xA1800000, 0xFFE08010, .SME, {}},
	},
	.SME_SUMOPA = {
		{.SME_SUMOPA, {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_B}, {.ZA_TILE_NUM_S, .PG, .PM3, .VN}, 0xA0A00000, 0xFFE08010, .SME, {}},
	},

	// SME LDR/STR ZA -- transfer single ZA slice from/to memory by tile-vector ref.
	//   11100001 00 0 Wv 000 Xn 00 ZAt   (encoded scaffolding; user supplies
	//   immediate tile selector as IMM_5 and vector base register as
	//   SVE_OFFSET_BASE_SI for the memory address)
	.SME_LDR_ZA = {
		{.SME_LDR_ZA, {.IMM_5, .MEM, .NONE, .NONE}, {.SVE_IMM5, .SVE_OFFSET_BASE_SI, .NONE, .NONE}, 0xE1000000, 0xFFE08000, .SME, {}},
	},
	.SME_STR_ZA = {
		{.SME_STR_ZA, {.IMM_5, .MEM, .NONE, .NONE}, {.SVE_IMM5, .SVE_OFFSET_BASE_SI, .NONE, .NONE}, 0xE1200000, 0xFFE08000, .SME, {}},
	},

	// =========================================================================
	// §25 Apple AMX (undocumented coprocessor; A13+, M1+)
	// =========================================================================
	//
	// Encoding: 0x00201000 | (op << 5) | operand
	//   bits[31:25] = 0000000  (op0 = 0b0000 -- "reserved" in standard ARM)
	//   bit [24]    = 0
	//   bit [23]    = 0
	//   bit [22]    = 0
	//   bit [21]    = 1
	//   bits[20:13] = 00000000
	//   bit [12]    = 1
	//   bits[11:10] = 00
	//   bits[9:5]   = op (5-bit AMX opcode 0..23)
	//   bits[4:0]   = operand (5-bit; usually GPR holding pointer + control)
	//
	// The static bits including the op field give mask 0xFFFFFFE0, leaving
	// bits[4:0] for the operand. SET/CLR have no operand and use mask
	// 0xFFFFFFFF (the operand field is fixed at 0).

	.AMX_LDX    = { {.AMX_LDX,    {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201000, 0xFFFFFFE0, .AMX, {is_64=true}} },
	.AMX_LDY    = { {.AMX_LDY,    {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201020, 0xFFFFFFE0, .AMX, {is_64=true}} },
	.AMX_STX    = { {.AMX_STX,    {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201040, 0xFFFFFFE0, .AMX, {is_64=true}} },
	.AMX_STY    = { {.AMX_STY,    {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201060, 0xFFFFFFE0, .AMX, {is_64=true}} },
	.AMX_LDZ    = { {.AMX_LDZ,    {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201080, 0xFFFFFFE0, .AMX, {is_64=true}} },
	.AMX_STZ    = { {.AMX_STZ,    {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x002010A0, 0xFFFFFFE0, .AMX, {is_64=true}} },
	.AMX_LDZI   = { {.AMX_LDZI,   {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x002010C0, 0xFFFFFFE0, .AMX, {is_64=true}} },
	.AMX_STZI   = { {.AMX_STZI,   {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x002010E0, 0xFFFFFFE0, .AMX, {is_64=true}} },
	.AMX_EXTRX  = { {.AMX_EXTRX,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201100, 0xFFFFFFE0, .AMX, {is_64=true}} },
	.AMX_EXTRY  = { {.AMX_EXTRY,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201120, 0xFFFFFFE0, .AMX, {is_64=true}} },
	.AMX_FMA64  = { {.AMX_FMA64,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201140, 0xFFFFFFE0, .AMX, {is_64=true}} },
	.AMX_FMS64  = { {.AMX_FMS64,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201160, 0xFFFFFFE0, .AMX, {is_64=true}} },
	.AMX_FMA32  = { {.AMX_FMA32,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201180, 0xFFFFFFE0, .AMX, {is_64=true}} },
	.AMX_FMS32  = { {.AMX_FMS32,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x002011A0, 0xFFFFFFE0, .AMX, {is_64=true}} },
	.AMX_MAC16  = { {.AMX_MAC16,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x002011C0, 0xFFFFFFE0, .AMX, {is_64=true}} },
	.AMX_FMA16  = { {.AMX_FMA16,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x002011E0, 0xFFFFFFE0, .AMX, {is_64=true}} },
	.AMX_FMS16  = { {.AMX_FMS16,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201200, 0xFFFFFFE0, .AMX, {is_64=true}} },

	// SET / CLR: no operand. Operand field is forced to 0; mask covers it.
	.AMX_SET    = { {.AMX_SET,    {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x00201220, 0xFFFFFFFF, .AMX, {}} },
	.AMX_CLR    = { {.AMX_CLR,    {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x00201240, 0xFFFFFFFF, .AMX, {}} },

	.AMX_VECINT = { {.AMX_VECINT, {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201260, 0xFFFFFFE0, .AMX, {is_64=true}} },
	.AMX_VECFP  = { {.AMX_VECFP,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x00201280, 0xFFFFFFE0, .AMX, {is_64=true}} },
	.AMX_MATINT = { {.AMX_MATINT, {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x002012A0, 0xFFFFFFE0, .AMX, {is_64=true}} },
	.AMX_MATFP  = { {.AMX_MATFP,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x002012C0, 0xFFFFFFE0, .AMX, {is_64=true}} },
	.AMX_GENLUT = { {.AMX_GENLUT, {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0x002012E0, 0xFFFFFFE0, .AMX, {is_64=true}} },

	// =========================================================================
	// §26 MOPS (v8.8-A memory operations)
	// =========================================================================
	//
	// Layout (general copy / set):
	//   bits 31:24 = 0x19 (CPY / SET), 0x1D (CPYF forward-only)
	//   bits 23:22 = stage (00=P, 01=M, 10=E)
	//   bits 20:16 = Rn (size register; updated on completion)
	//   bits 15:14 = options (00 = default)
	//   bits 13:12 = 01
	//   bits 11:10 = 00
	//   bits  9:5  = Rs (source / set value)
	//   bits  4:0  = Rd (destination address; updated)
	//
	// Mask covers bits 31:21 + 13:10 = 0xFFE03C00. All three GPRs are
	// updated on completion; user passes the initial addresses / size.

	.CPYP  = { {.CPYP,  {.XSP_REG, .XSP_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1D000400, 0xFFE03C00, .BASE, {is_64=true}} },
	.CPYM  = { {.CPYM,  {.XSP_REG, .XSP_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1D400400, 0xFFE03C00, .BASE, {is_64=true}} },
	.CPYE  = { {.CPYE,  {.XSP_REG, .XSP_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1D800400, 0xFFE03C00, .BASE, {is_64=true}} },
	.CPYFP = { {.CPYFP, {.XSP_REG, .XSP_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x19000400, 0xFFE03C00, .BASE, {is_64=true}} },
	.CPYFM = { {.CPYFM, {.XSP_REG, .XSP_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x19400400, 0xFFE03C00, .BASE, {is_64=true}} },
	.CPYFE = { {.CPYFE, {.XSP_REG, .XSP_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x19800400, 0xFFE03C00, .BASE, {is_64=true}} },
	// SET* shares the layout but uses bits 23:22 = 11 to mark memset.
	.SETP  = { {.SETP,  {.XSP_REG, .X_REG,   .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x19C00400, 0xFFE03C00, .BASE, {is_64=true}} },
	.SETM  = { {.SETM,  {.XSP_REG, .X_REG,   .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x19C04400, 0xFFE03C00, .BASE, {is_64=true}} },
	.SETE  = { {.SETE,  {.XSP_REG, .X_REG,   .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x19C08400, 0xFFE03C00, .BASE, {is_64=true}} },

	// =========================================================================
	// §27 Cache management (SYS-encoded)
	// =========================================================================
	//
	// SYS instruction layout:
	//   bits 31:22 = 1101_0101_00            (0xD500)
	//   bit  21    = L  (0 = SYS, 1 = SYSL)
	//   bit  20    = 1  (system instruction marker)
	//   bits 18:16 = op1
	//   bits 15:12 = CRn
	//   bits 11:8  = CRm
	//   bits  7:5  = op2
	//   bits  4:0  = Rt (operand register, or 0x1F for register-less variants)
	//
	// We encode each DC/IC/AT/TLBI variant as its own mnemonic so the
	// disassembly reads canonically. Entries with mask 0xFFFFFFE0 leave only
	// bits 4:0 (Rt) operand-driven; "no-Rt" variants use mask 0xFFFFFFFF
	// (Rt forced to ZR = 0x1F in the bits field).

	// ---- DC (Data Cache) ----------------------------------------------------
	//   DC IVAC  Xt    SYS #0 C7 C6  #1, Xt
	//   DC ISW   Xt    SYS #0 C7 C6  #2, Xt
	//   DC CSW   Xt    SYS #0 C7 C10 #2, Xt
	//   DC CISW  Xt    SYS #0 C7 C14 #2, Xt
	//   DC ZVA   Xt    SYS #3 C7 C4  #1, Xt
	//   DC CVAC  Xt    SYS #3 C7 C10 #1, Xt
	//   DC CVAU  Xt    SYS #3 C7 C11 #1, Xt
	//   DC CIVAC Xt    SYS #3 C7 C14 #1, Xt
	.DC_IVAC  = { {.DC_IVAC,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5087620, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.DC_ISW   = { {.DC_ISW,   {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5087640, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.DC_CSW   = { {.DC_CSW,   {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5087A40, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.DC_CISW  = { {.DC_CISW,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5087E40, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.DC_ZVA   = { {.DC_ZVA,   {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50B7420, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.DC_CVAC  = { {.DC_CVAC,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50B7A20, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.DC_CVAU  = { {.DC_CVAU,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50B7B20, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.DC_CIVAC = { {.DC_CIVAC, {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50B7E20, 0xFFFFFFE0, .BASE, {is_64=true}} },

	// ---- IC (Instruction Cache) --------------------------------------------
	//   IC IALLUIS         SYS #0 C7 C1 #0
	//   IC IALLU           SYS #0 C7 C5 #0
	//   IC IVAU  Xt        SYS #3 C7 C5 #1, Xt
	.IC_IALLUIS = { {.IC_IALLUIS, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD508711F, 0xFFFFFFFF, .BASE, {}} },
	.IC_IALLU   = { {.IC_IALLU,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD508751F, 0xFFFFFFFF, .BASE, {}} },
	.IC_IVAU    = { {.IC_IVAU,    {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50B7520, 0xFFFFFFE0, .BASE, {is_64=true}} },

	// ---- AT (Address Translate, PE current EL) ------------------------------
	//   AT S1E1R  Xt    SYS #0 C7 C8 #0, Xt
	//   AT S1E1W  Xt    SYS #0 C7 C8 #1, Xt
	//   AT S1E0R  Xt    SYS #0 C7 C8 #2, Xt
	//   AT S1E0W  Xt    SYS #0 C7 C8 #3, Xt
	//   AT S1E2R  Xt    SYS #4 C7 C8 #0, Xt
	//   AT S1E2W  Xt    SYS #4 C7 C8 #1, Xt
	//   AT S1E3R  Xt    SYS #6 C7 C8 #0, Xt
	//   AT S1E3W  Xt    SYS #6 C7 C8 #1, Xt
	//   AT S12E1R Xt    SYS #4 C7 C8 #4, Xt
	//   AT S12E1W Xt    SYS #4 C7 C8 #5, Xt
	//   AT S12E0R Xt    SYS #4 C7 C8 #6, Xt
	//   AT S12E0W Xt    SYS #4 C7 C8 #7, Xt
	.AT_S1E1R  = { {.AT_S1E1R,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5087800, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.AT_S1E1W  = { {.AT_S1E1W,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5087820, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.AT_S1E0R  = { {.AT_S1E0R,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5087840, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.AT_S1E0W  = { {.AT_S1E0W,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5087860, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.AT_S1E2R  = { {.AT_S1E2R,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50C7800, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.AT_S1E2W  = { {.AT_S1E2W,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50C7820, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.AT_S1E3R  = { {.AT_S1E3R,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50E7800, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.AT_S1E3W  = { {.AT_S1E3W,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50E7820, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.AT_S12E1R = { {.AT_S12E1R, {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50C7880, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.AT_S12E1W = { {.AT_S12E1W, {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50C78A0, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.AT_S12E0R = { {.AT_S12E0R, {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50C78C0, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.AT_S12E0W = { {.AT_S12E0W, {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50C78E0, 0xFFFFFFE0, .BASE, {is_64=true}} },

	// ---- TLBI (TLB Invalidate, EL1 + EL2/3 broadcasts) ----------------------
	//   TLBI VMALLE1IS         SYS #0 C8 C3 #0           -- broadcast inner-shareable
	//   TLBI VAE1IS    Xt      SYS #0 C8 C3 #1, Xt
	//   TLBI ASIDE1IS  Xt      SYS #0 C8 C3 #2, Xt
	//   TLBI VAAE1IS   Xt      SYS #0 C8 C3 #3, Xt
	//   TLBI VALE1IS   Xt      SYS #0 C8 C3 #5, Xt
	//   TLBI VAALE1IS  Xt      SYS #0 C8 C3 #7, Xt
	//   TLBI VMALLE1           SYS #0 C8 C7 #0
	//   TLBI VAE1      Xt      SYS #0 C8 C7 #1, Xt
	//   TLBI ASIDE1    Xt      SYS #0 C8 C7 #2, Xt
	//   TLBI VAAE1     Xt      SYS #0 C8 C7 #3, Xt
	//   TLBI VALE1     Xt      SYS #0 C8 C7 #5, Xt
	//   TLBI VAALE1    Xt      SYS #0 C8 C7 #7, Xt
	.TLBI_VMALLE1IS = { {.TLBI_VMALLE1IS, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD508831F, 0xFFFFFFFF, .BASE, {}} },
	.TLBI_VAE1IS    = { {.TLBI_VAE1IS,    {.X_REG,.NONE,.NONE,.NONE}, {.RT,.NONE,.NONE,.NONE}, 0xD5088320, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.TLBI_ASIDE1IS  = { {.TLBI_ASIDE1IS,  {.X_REG,.NONE,.NONE,.NONE}, {.RT,.NONE,.NONE,.NONE}, 0xD5088340, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.TLBI_VAAE1IS   = { {.TLBI_VAAE1IS,   {.X_REG,.NONE,.NONE,.NONE}, {.RT,.NONE,.NONE,.NONE}, 0xD5088360, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.TLBI_VALE1IS   = { {.TLBI_VALE1IS,   {.X_REG,.NONE,.NONE,.NONE}, {.RT,.NONE,.NONE,.NONE}, 0xD50883A0, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.TLBI_VAALE1IS  = { {.TLBI_VAALE1IS,  {.X_REG,.NONE,.NONE,.NONE}, {.RT,.NONE,.NONE,.NONE}, 0xD50883E0, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.TLBI_VMALLE1   = { {.TLBI_VMALLE1,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD508871F, 0xFFFFFFFF, .BASE, {}} },
	.TLBI_VAE1      = { {.TLBI_VAE1,      {.X_REG,.NONE,.NONE,.NONE}, {.RT,.NONE,.NONE,.NONE}, 0xD5088720, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.TLBI_ASIDE1    = { {.TLBI_ASIDE1,    {.X_REG,.NONE,.NONE,.NONE}, {.RT,.NONE,.NONE,.NONE}, 0xD5088740, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.TLBI_VAAE1     = { {.TLBI_VAAE1,     {.X_REG,.NONE,.NONE,.NONE}, {.RT,.NONE,.NONE,.NONE}, 0xD5088760, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.TLBI_VALE1     = { {.TLBI_VALE1,     {.X_REG,.NONE,.NONE,.NONE}, {.RT,.NONE,.NONE,.NONE}, 0xD50887A0, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.TLBI_VAALE1    = { {.TLBI_VAALE1,    {.X_REG,.NONE,.NONE,.NONE}, {.RT,.NONE,.NONE,.NONE}, 0xD50887E0, 0xFFFFFFE0, .BASE, {is_64=true}} },
	// EL2/EL3 "ALL" variants (no Rt)
	.TLBI_ALLE1   = { {.TLBI_ALLE1,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD508871F, 0xFFFFFFFF, .BASE, {}} },
	.TLBI_ALLE1IS = { {.TLBI_ALLE1IS, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD508831F, 0xFFFFFFFF, .BASE, {}} },
	.TLBI_ALLE2   = { {.TLBI_ALLE2,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD50C871F, 0xFFFFFFFF, .BASE, {}} },
	.TLBI_ALLE2IS = { {.TLBI_ALLE2IS, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD50C831F, 0xFFFFFFFF, .BASE, {}} },
	.TLBI_ALLE3   = { {.TLBI_ALLE3,   {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD50E871F, 0xFFFFFFFF, .BASE, {}} },
	.TLBI_ALLE3IS = { {.TLBI_ALLE3IS, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD50E831F, 0xFFFFFFFF, .BASE, {}} },

	// =========================================================================
	// §28 PRFM (Prefetch Memory)
	// =========================================================================
	//
	//   PRFM <prfop>, [Xn, #imm]   unsigned-offset form (imm scaled by 8)
	//     bits 31:22 = 1111_1000_10            (0x3E2 << 22)
	//     -> base 0xF9800000
	//     bits 21:10 = imm12 (operand)
	//     bits  9:5  = Rn (base)
	//     bits  4:0  = prfop (5-bit prefetch operation selector)
	//   PRFUM (unscaled): bits 31:21 = 1111_1000_100, base 0xF8800000
	//   PRFM (literal):   bits 31:24 = 1101_1000,    base 0xD8000000

	.PRFM     = { {.PRFM,     {.IMM_5, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0xF9800000, 0xFFC00000, .BASE, {is_64=true}} },
	.PRFUM    = { {.PRFUM,    {.IMM_5, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9,  .NONE, .NONE}, 0xF8800000, 0xFFE00C00, .BASE, {is_64=true}} },
	.PRFM_LIT = { {.PRFM_LIT, {.IMM_5, .REL_19, .NONE, .NONE}, {.RT, .BRANCH_19, .NONE, .NONE},    0xD8000000, 0xFF000000, .BASE, {is_64=true}} },

	// =========================================================================
	// §29 Aliases (printed canonically; encode with Rd=ZR or Rn=ZR)
	// =========================================================================
	//
	//   MOV  Rd, Rm          = ORR  Rd, ZR, Rm           (sf=1 0101010 shift=00 Rm imm6=0 Rn=31 Rd)
	//   MOV  Rd, #imm        = ORR  Rd, ZR, #bitmask     (sf=1 01100100 N immr imms Rn=31 Rd)
	//   MVN  Rd, Rm          = ORN  Rd, ZR, Rm           (sf=1 0101010 shift=00 1 Rm imm6=0 Rn=31 Rd)
	//   NEG  Rd, Rm{,shift}  = SUB  Rd, ZR, Rm{,shift}   (sf=1 1001011 shift Rm imm6 Rn=31 Rd)
	//   NEGS Rd, Rm{,shift}  = SUBS Rd, ZR, Rm{,shift}
	//   CMP  Rn, Rm{,shift}  = SUBS ZR, Rn, Rm{,shift}
	//   CMP  Rn, Rm, ext     = SUBS ZR, Rn, Rm, ext
	//   CMP  Rn, #imm        = SUBS ZR, Rn, #imm
	//   CMN  Rn, Rm{,shift}  = ADDS ZR, Rn, Rm{,shift}
	//   CMN  Rn, Rm, ext     = ADDS ZR, Rn, Rm, ext
	//   CMN  Rn, #imm        = ADDS ZR, Rn, #imm
	//   TST  Rn, Rm{,shift}  = ANDS ZR, Rn, Rm{,shift}

	.MOV_REG = {
		// 32-bit: ORR Wd, WZR, Wm  -- base 0x2A0003E0 = ORR Wd, W31, Wm (shift=LSL, imm6=0, Rn=31)
		{.MOV_REG, {.W_REG, .W_REG, .NONE, .NONE}, {.RD, .RM, .NONE, .NONE}, 0x2A0003E0, 0xFFE0FFE0, .BASE, {}},
		{.MOV_REG, {.X_REG, .X_REG, .NONE, .NONE}, {.RD, .RM, .NONE, .NONE}, 0xAA0003E0, 0xFFE0FFE0, .BASE, {is_64=true}},
	},
	.MOV_BITMASK = {
		{.MOV_BITMASK, {.W_REG, .BITMASK_IMM, .NONE, .NONE}, {.RD, .BITMASK_FIELD, .NONE, .NONE}, 0x320003E0, 0xFFC003E0, .BASE, {}},
		{.MOV_BITMASK, {.X_REG, .BITMASK_IMM, .NONE, .NONE}, {.RD, .BITMASK_FIELD, .NONE, .NONE}, 0xB20003E0, 0xFF8003E0, .BASE, {is_64=true}},
	},
	.MVN = {
		// ORN Wd, WZR, Wm  -- base 0x2A2003E0
		{.MVN, {.W_REG, .W_REG, .NONE, .NONE}, {.RD, .RM, .NONE, .NONE}, 0x2A2003E0, 0xFFE0FFE0, .BASE, {}},
		{.MVN, {.X_REG, .X_REG, .NONE, .NONE}, {.RD, .RM, .NONE, .NONE}, 0xAA2003E0, 0xFFE0FFE0, .BASE, {is_64=true}},
	},
	.NEG_SR = {
		// SUB Wd, WZR, Wm{, shift #imm6}  -- base 0x4B0003E0
		{.NEG_SR, {.W_REG, .W_SHIFTED, .NONE, .NONE}, {.RD, .RM, .NONE, .NONE}, 0x4B0003E0, 0xFF2003E0, .BASE, {}},
		{.NEG_SR, {.X_REG, .X_SHIFTED, .NONE, .NONE}, {.RD, .RM, .NONE, .NONE}, 0xCB0003E0, 0xFF2003E0, .BASE, {is_64=true}},
	},
	.NEGS = {
		// SUBS Wd, WZR, Wm{, shift #imm6} -- base 0x6B0003E0
		{.NEGS, {.W_REG, .W_SHIFTED, .NONE, .NONE}, {.RD, .RM, .NONE, .NONE}, 0x6B0003E0, 0xFF2003E0, .BASE, {sets_flags=true}},
		{.NEGS, {.X_REG, .X_SHIFTED, .NONE, .NONE}, {.RD, .RM, .NONE, .NONE}, 0xEB0003E0, 0xFF2003E0, .BASE, {sets_flags=true, is_64=true}},
	},
	.CMP_SR = {
		// SUBS WZR, Wn, Wm{, shift} -- base 0x6B00001F
		{.CMP_SR, {.W_REG, .W_SHIFTED, .NONE, .NONE}, {.RN, .RM, .NONE, .NONE}, 0x6B00001F, 0xFF20001F, .BASE, {sets_flags=true}},
		{.CMP_SR, {.X_REG, .X_SHIFTED, .NONE, .NONE}, {.RN, .RM, .NONE, .NONE}, 0xEB00001F, 0xFF20001F, .BASE, {sets_flags=true, is_64=true}},
	},
	.CMP_ER = {
		// SUBS WZR, Wn, Wm, ext -- base 0x6B20001F
		{.CMP_ER, {.WSP_REG, .W_EXTENDED, .NONE, .NONE}, {.RN, .RM, .NONE, .NONE}, 0x6B20001F, 0xFFE0001F, .BASE, {sets_flags=true}},
		{.CMP_ER, {.XSP_REG, .X_EXTENDED, .NONE, .NONE}, {.RN, .RM, .NONE, .NONE}, 0xEB20001F, 0xFFE0001F, .BASE, {sets_flags=true, is_64=true}},
	},
	.CMP_IMM = {
		// SUBS WZR, Wn, #imm12{, LSL #12} -- base 0x7100001F
		{.CMP_IMM, {.WSP_REG, .IMM_12, .NONE, .NONE}, {.RN, .IMM12, .NONE, .NONE}, 0x7100001F, 0xFF80001F, .BASE, {sets_flags=true}},
		{.CMP_IMM, {.XSP_REG, .IMM_12, .NONE, .NONE}, {.RN, .IMM12, .NONE, .NONE}, 0xF100001F, 0xFF80001F, .BASE, {sets_flags=true, is_64=true}},
	},
	.CMN_SR = {
		// ADDS WZR, Wn, Wm{, shift} -- base 0x2B00001F
		{.CMN_SR, {.W_REG, .W_SHIFTED, .NONE, .NONE}, {.RN, .RM, .NONE, .NONE}, 0x2B00001F, 0xFF20001F, .BASE, {sets_flags=true}},
		{.CMN_SR, {.X_REG, .X_SHIFTED, .NONE, .NONE}, {.RN, .RM, .NONE, .NONE}, 0xAB00001F, 0xFF20001F, .BASE, {sets_flags=true, is_64=true}},
	},
	.CMN_ER = {
		// ADDS WZR, Wn, Wm, ext -- base 0x2B20001F
		{.CMN_ER, {.WSP_REG, .W_EXTENDED, .NONE, .NONE}, {.RN, .RM, .NONE, .NONE}, 0x2B20001F, 0xFFE0001F, .BASE, {sets_flags=true}},
		{.CMN_ER, {.XSP_REG, .X_EXTENDED, .NONE, .NONE}, {.RN, .RM, .NONE, .NONE}, 0xAB20001F, 0xFFE0001F, .BASE, {sets_flags=true, is_64=true}},
	},
	.CMN_IMM = {
		// ADDS WZR, Wn, #imm12 -- base 0x3100001F
		{.CMN_IMM, {.WSP_REG, .IMM_12, .NONE, .NONE}, {.RN, .IMM12, .NONE, .NONE}, 0x3100001F, 0xFF80001F, .BASE, {sets_flags=true}},
		{.CMN_IMM, {.XSP_REG, .IMM_12, .NONE, .NONE}, {.RN, .IMM12, .NONE, .NONE}, 0xB100001F, 0xFF80001F, .BASE, {sets_flags=true, is_64=true}},
	},
	.TST_SR = {
		// ANDS WZR, Wn, Wm{, shift} -- base 0x6A00001F
		{.TST_SR, {.W_REG, .W_SHIFTED, .NONE, .NONE}, {.RN, .RM, .NONE, .NONE}, 0x6A00001F, 0xFF20001F, .BASE, {sets_flags=true}},
		{.TST_SR, {.X_REG, .X_SHIFTED, .NONE, .NONE}, {.RN, .RM, .NONE, .NONE}, 0xEA00001F, 0xFF20001F, .BASE, {sets_flags=true, is_64=true}},
	},

	// =========================================================================
	// §30 SVE indexed FMLA / FMLS (lane-broadcast multiply-accumulate)
	// =========================================================================
	//
	// Layout (.D, 1-bit lane):
	//   bits 31:22 = 01100100 11
	//   bit  21    = 1
	//   bit  20    = i1                              (lane[0])
	//   bits 19:16 = Zm   (4-bit, Z0-Z15)
	//   bits 15:13 = 000
	//   bit  12    = 0  (FMLA) / 1  (FMLS)
	//   bits 11:10 = 00
	//   bits  9:5  = Zn
	//   bits  4:0  = Zda
	//
	// .S form: lane is 2-bit at bits 20:19, Zm is 3-bit at 18:16 (Z0-Z7)
	// .H form: lane is 3-bit (bit 22, bits 20:19), Zm is 3-bit at 18:16

	.SVE_FMLA_IDX_H = {
		{.SVE_FMLA_IDX_H, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .IMM_3}, {.VD, .VN, .VM, .SVE_FMLA_IDX_H}, 0x64200000, 0xFFA0FC00, .SVE, {}},
	},
	.SVE_FMLA_IDX_S = {
		{.SVE_FMLA_IDX_S, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .IMM_2}, {.VD, .VN, .VM, .SVE_FMLA_IDX_S}, 0x64A00000, 0xFFE0FC00, .SVE, {}},
	},
	.SVE_FMLA_IDX_D = {
		{.SVE_FMLA_IDX_D, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .IMM_2}, {.VD, .VN, .VM, .SVE_FMLA_IDX_D}, 0x64E00000, 0xFFE0FC00, .SVE, {is_64=true}},
	},
	.SVE_FMLS_IDX_H = {
		{.SVE_FMLS_IDX_H, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .IMM_3}, {.VD, .VN, .VM, .SVE_FMLA_IDX_H}, 0x64200400, 0xFFA0FC00, .SVE, {}},
	},
	.SVE_FMLS_IDX_S = {
		{.SVE_FMLS_IDX_S, {.Z_REG_S, .Z_REG_S, .Z_REG_S, .IMM_2}, {.VD, .VN, .VM, .SVE_FMLA_IDX_S}, 0x64A00400, 0xFFE0FC00, .SVE, {}},
	},
	.SVE_FMLS_IDX_D = {
		{.SVE_FMLS_IDX_D, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .IMM_2}, {.VD, .VN, .VM, .SVE_FMLA_IDX_D}, 0x64E00400, 0xFFE0FC00, .SVE, {is_64=true}},
	},

	// =========================================================================
	// §31 SVE gather loads / scatter stores
	// =========================================================================
	//
	// Layout (scalar+vector form):
	//   bits 31:25 = 1000010  (gather)  /  1110010  (scatter)
	//   bits 24:23 = size       (00=B, 01=H, 10=W, 11=D)
	//   bits 22:21 = signed/unsigned + offsets-32/64 marker
	//   bits 20:16 = Zm (vector index register)
	//   bits 15:13 = options (extend type encoded here for 32-bit offsets)
	//   bits 12:10 = Pg (governing predicate, P0-P7)
	//   bits  9:5  = Xn (base register)
	//   bits  4:0  = Zt (destination)
	//
	// We commit to the most common variants: unscaled-byte and naturally-
	// scaled half/word/double gather/scatter with 32-bit or 64-bit vector
	// offsets.

	// Gather LD1B { Zt.S }, Pg/Z, [Xn, Zm.S, UXTW]
	.SVE_LD1B_GATHER_S = {
		{.SVE_LD1B_GATHER_S, {.Z_REG_S, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0x84004000, 0xFFA0E000, .SVE, {}},
	},
	.SVE_LD1B_GATHER_D = {
		{.SVE_LD1B_GATHER_D, {.Z_REG_D, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xC4004000, 0xFFA0E000, .SVE, {is_64=true}},
	},
	.SVE_LD1H_GATHER_S = {
		{.SVE_LD1H_GATHER_S, {.Z_REG_S, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0x84804000, 0xFFA0E000, .SVE, {}},
	},
	.SVE_LD1H_GATHER_D = {
		{.SVE_LD1H_GATHER_D, {.Z_REG_D, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xC4804000, 0xFFA0E000, .SVE, {is_64=true}},
	},
	.SVE_LD1W_GATHER_S = {
		{.SVE_LD1W_GATHER_S, {.Z_REG_S, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0x85004000, 0xFFA0E000, .SVE, {}},
	},
	.SVE_LD1W_GATHER_D = {
		{.SVE_LD1W_GATHER_D, {.Z_REG_D, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xC5004000, 0xFFA0E000, .SVE, {is_64=true}},
	},
	.SVE_LD1D_GATHER_D = {
		{.SVE_LD1D_GATHER_D, {.Z_REG_D, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xC5804000, 0xFFA0E000, .SVE, {is_64=true}},
	},

	// Signed-extending gather loads (LD1SB / LD1SH / LD1SW)
	.SVE_LD1SB_GATHER_S = {
		{.SVE_LD1SB_GATHER_S, {.Z_REG_S, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0x84000000, 0xFFA0E000, .SVE, {}},
	},
	.SVE_LD1SB_GATHER_D = {
		{.SVE_LD1SB_GATHER_D, {.Z_REG_D, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xC4000000, 0xFFA0E000, .SVE, {is_64=true}},
	},
	.SVE_LD1SH_GATHER_S = {
		{.SVE_LD1SH_GATHER_S, {.Z_REG_S, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0x84800000, 0xFFA0E000, .SVE, {}},
	},
	.SVE_LD1SH_GATHER_D = {
		{.SVE_LD1SH_GATHER_D, {.Z_REG_D, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xC4800000, 0xFFA0E000, .SVE, {is_64=true}},
	},
	.SVE_LD1SW_GATHER_D = {
		{.SVE_LD1SW_GATHER_D, {.Z_REG_D, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xC5000000, 0xFFA0E000, .SVE, {is_64=true}},
	},

	// Scatter stores
	.SVE_ST1B_SCATTER_S = {
		{.SVE_ST1B_SCATTER_S, {.Z_REG_S, .P_REG, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xE4008000, 0xFFA0E000, .SVE, {}},
	},
	.SVE_ST1B_SCATTER_D = {
		{.SVE_ST1B_SCATTER_D, {.Z_REG_D, .P_REG, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xE4008000, 0xFFA0E000, .SVE, {is_64=true}},
	},
	.SVE_ST1H_SCATTER_S = {
		{.SVE_ST1H_SCATTER_S, {.Z_REG_S, .P_REG, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xE4808000, 0xFFA0E000, .SVE, {}},
	},
	.SVE_ST1H_SCATTER_D = {
		{.SVE_ST1H_SCATTER_D, {.Z_REG_D, .P_REG, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xE4808000, 0xFFA0E000, .SVE, {is_64=true}},
	},
	.SVE_ST1W_SCATTER_S = {
		{.SVE_ST1W_SCATTER_S, {.Z_REG_S, .P_REG, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xE5008000, 0xFFA0E000, .SVE, {}},
	},
	.SVE_ST1W_SCATTER_D = {
		{.SVE_ST1W_SCATTER_D, {.Z_REG_D, .P_REG, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xE5008000, 0xFFA0E000, .SVE, {is_64=true}},
	},
	.SVE_ST1D_SCATTER_D = {
		{.SVE_ST1D_SCATTER_D, {.Z_REG_D, .P_REG, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_VEC, .NONE}, 0xE5808000, 0xFFA0E000, .SVE, {is_64=true}},
	},

	// =========================================================================
	// §32 SME tile slice load/store
	// =========================================================================
	//
	// Layout for LD1B { ZAt<H|V>.B[Ws, #imm] }, Pg/Z, [Xn, Xm]:
	//   bits 31:22 = 1110000000     (0xE00)
	//   bit  21    = 0
	//   bits 20:16 = Xm
	//   bit  15    = V flag (0=H, 1=V)
	//   bit  14    = 0
	//   bits 13:10 = ws[1:0] || pg[2:0]  (the slice descriptor packer
	//                splits the 4 bits as Ws<<13 + imm<<0 + Pg via the
	//                separate PG operand encoding; for v1 we treat the
	//                whole 4-bit field as Pg+Ws packed)
	//   bits  9:5  = Xn
	//   bit   4    = 0
	//   bits  3:0  = packed imm + sub-tile bits per element size
	//
	// Mask covers bits 31:22 + bit 21 + bit 14 + bit 4 (the always-fixed
	// ones) = 0xFFE00010. The H/V flag (bit 15), tile number (bits 22 or
	// 23:22 etc.), and operand fields stay operand-driven.

	//
	// Verified against LLVM's MC tests for AArch64 SME:
	//   ld1b {za0h.b[w12,0]}, p0/z, [x0, x0]   = 0xE0000000
	//   ld1h {za0h.h[w12,0]}, p0/z, [x0, x0]   = 0xE0400000
	//   ld1w {za0h.s[w12,0]}, p0/z, [x0]       = 0xE0800000
	//   ld1d {za0h.d[w12,0]}, p0/z, [x0, x0]   = 0xE0C00000
	//   ld1q {za0h.q[w12,0]}, p0/z, [x0, x0]   = 0xE0E00000  (note: same as
	//     ST1D bit pattern in the bits[31:22] field, but the tile/imm slot
	//     at bits 3:0 differs; the user-side slice descriptor encodes the
	//     element-size sub-format)
	//
	// The static prefix at bits 31:21 (0xE0 in byte 3, 0xE0 in byte 2's
	// top 3 bits) identifies the SME LD1 family. bits 23:22 select the
	// element size {00=B, 01=H, 10=W, 11=D}; bit 21 selects LD1Q (when set
	// alongside bits 23:22 = 11). Tile number and imm offset are *packed*
	// into bits 3:0 of the instruction (per element size):
	//   .B : imm[3:0]                  (single tile, ZA0.B implicit)
	//   .H : tile[0]<<3 | imm[2:0]     (2 tiles, 8 slices each)
	//   .W : tile[1:0]<<2 | imm[1:0]   (4 tiles, 4 slices each)
	//   .D : tile[2:0]<<1 | imm[0]     (8 tiles, 2 slices each)
	//   .Q : tile[3:0]                 (16 tiles, 1 slice each)

	.SME_LD1B_TILE = {
		{.SME_LD1B_TILE, {.SME_SLICE_B, .P_REG_ZERO, .MEM, .NONE}, {.SME_SLICE_B, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE0000000, 0xFFE00010, .SME, {}},
	},
	.SME_LD1H_TILE = {
		{.SME_LD1H_TILE, {.SME_SLICE_H, .P_REG_ZERO, .MEM, .NONE}, {.SME_SLICE_H, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE0400000, 0xFFE00010, .SME, {}},
	},
	.SME_LD1W_TILE = {
		{.SME_LD1W_TILE, {.SME_SLICE_W, .P_REG_ZERO, .MEM, .NONE}, {.SME_SLICE_W, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE0800000, 0xFFE00010, .SME, {}},
	},
	.SME_LD1D_TILE = {
		{.SME_LD1D_TILE, {.SME_SLICE_D, .P_REG_ZERO, .MEM, .NONE}, {.SME_SLICE_D, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE0C00000, 0xFFE00010, .SME, {is_64=true}},
	},
	.SME_LD1Q_TILE = {
		{.SME_LD1Q_TILE, {.SME_SLICE_Q, .P_REG_ZERO, .MEM, .NONE}, {.SME_SLICE_Q, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE1C00000, 0xFFE00010, .SME, {}},
	},

	// Store family: same prefix but bit 21 set (LD vs ST distinguisher).
	.SME_ST1B_TILE = {
		{.SME_ST1B_TILE, {.SME_SLICE_B, .P_REG, .MEM, .NONE}, {.SME_SLICE_B, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE0200000, 0xFFE00010, .SME, {}},
	},
	.SME_ST1H_TILE = {
		{.SME_ST1H_TILE, {.SME_SLICE_H, .P_REG, .MEM, .NONE}, {.SME_SLICE_H, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE0600000, 0xFFE00010, .SME, {}},
	},
	.SME_ST1W_TILE = {
		{.SME_ST1W_TILE, {.SME_SLICE_W, .P_REG, .MEM, .NONE}, {.SME_SLICE_W, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE0A00000, 0xFFE00010, .SME, {}},
	},
	.SME_ST1D_TILE = {
		{.SME_ST1D_TILE, {.SME_SLICE_D, .P_REG, .MEM, .NONE}, {.SME_SLICE_D, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE0E00000, 0xFFE00010, .SME, {is_64=true}},
	},
	.SME_ST1Q_TILE = {
		{.SME_ST1Q_TILE, {.SME_SLICE_Q, .P_REG, .MEM, .NONE}, {.SME_SLICE_Q, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE1E00000, 0xFFE00010, .SME, {}},
	},

	// =========================================================================
	// §33 SME MOVA (transfer between Z register and ZA tile slice)
	// =========================================================================
	//
	//   MOVA Zt.T, Pg/M, ZAt<H|V>.T[Ws, #imm]    -- tile slice -> Z reg
	//   MOVA ZAt<H|V>.T[Ws, #imm], Pg/M, Zn.T    -- Z reg -> tile slice

	.SME_MOVA_Z_FROM_TILE = {
		{.SME_MOVA_Z_FROM_TILE, {.Z_REG_B, .P_REG_MERGE, .SME_SLICE_B, .NONE}, {.VD, .PG, .SME_SLICE_B, .NONE}, 0xC0020000, 0xFFE08010, .SME, {}},
	},
	.SME_MOVA_TILE_FROM_Z = {
		{.SME_MOVA_TILE_FROM_Z, {.SME_SLICE_B, .P_REG_MERGE, .Z_REG_B, .NONE}, {.SME_SLICE_B, .PG, .VN, .NONE}, 0xC0000000, 0xFFE08010, .SME, {}},
	},

	// SME ZA outer-sum accumulate: ADDHA/ADDVA ZAda.S, Pn/m, Pm/m, Zn.S.
	// ZAda tile at bits 2:0, Pn (Pg) at 12:10, Pm at 15:13, Zn at 9:5.
	.SME_ADDHA = { {.SME_ADDHA, {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_S}, {.ZA_TILE_LOW, .PG, .PM3, .VN}, 0xC0900000, 0xFFFF001C, .SME, {}} },
	.SME_ADDVA = { {.SME_ADDVA, {.ZA_TILE_S, .P_REG_MERGE, .P_REG_MERGE, .Z_REG_S}, {.ZA_TILE_LOW, .PG, .PM3, .VN}, 0xC0910000, 0xFFFF001C, .SME, {}} },

	// =========================================================================
	// §34 NEON complex FP multiply-add (v8.3-A FCMA extension)
	// =========================================================================
	//
	// Verified against LLVM MC golden tests (test/MC/AArch64/armv8.3a-complex.s):
	//   fcmla v0.4h, v1.4h, v2.4h, #0   = 0x2E42C420
	//   fcmla v0.8h, v1.8h, v2.8h, #0   = 0x6E42C420
	//   fcmla v0.4s, v1.4s, v2.4s, #0   = 0x6E82C420
	//   fcmla v0.2d, v1.2d, v2.2d, #0   = 0x6EC2C420
	//   fcadd v0.4s, v1.4s, v2.4s, #90  = 0x6E82E420
	//
	// FCMLA layout:  bit 30 = Q, bit 29 = U=1, bits 28:24 = 01110, bits 23:22
	// = size (01=H, 10=S, 11=D), bit 21 = 0, bits 20:16 = Rm, bits 15:14 = 11,
	// bits 13:12 = rot (4 rotations), bits 11:10 = 01, Rn at 9:5, Rd at 4:0.
	//
	// FCADD layout: same except bit 13 = 1 (static), bit 12 = rot (0=90°, 1=270°).

	.FCMLA_4H = { {.FCMLA_4H, {.V_4H, .V_4H, .V_4H, .IMM_2}, {.VD, .VN, .VM, .ENC_FCMLA_ROT}, 0x2E40C400, 0xFFA0CC00, .NEON, {}} },
	.FCMLA_8H = { {.FCMLA_8H, {.V_8H, .V_8H, .V_8H, .IMM_2}, {.VD, .VN, .VM, .ENC_FCMLA_ROT}, 0x6E40C400, 0xFFA0CC00, .NEON, {}} },
	.FCMLA_4S = { {.FCMLA_4S, {.V_4S, .V_4S, .V_4S, .IMM_2}, {.VD, .VN, .VM, .ENC_FCMLA_ROT}, 0x6E80C400, 0xFFA0CC00, .NEON, {}} },
	.FCMLA_2D = { {.FCMLA_2D, {.V_2D, .V_2D, .V_2D, .IMM_2}, {.VD, .VN, .VM, .ENC_FCMLA_ROT}, 0x6EC0C400, 0xFFA0CC00, .NEON, {}} },

	.FCADD_4H = { {.FCADD_4H, {.V_4H, .V_4H, .V_4H, .IMM_2}, {.VD, .VN, .VM, .ENC_FCADD_ROT}, 0x2E40E400, 0xFFA0EC00, .NEON, {}} },
	.FCADD_8H = { {.FCADD_8H, {.V_8H, .V_8H, .V_8H, .IMM_2}, {.VD, .VN, .VM, .ENC_FCADD_ROT}, 0x6E40E400, 0xFFA0EC00, .NEON, {}} },
	.FCADD_4S = { {.FCADD_4S, {.V_4S, .V_4S, .V_4S, .IMM_2}, {.VD, .VN, .VM, .ENC_FCADD_ROT}, 0x6E80E400, 0xFFA0EC00, .NEON, {}} },
	.FCADD_2D = { {.FCADD_2D, {.V_2D, .V_2D, .V_2D, .IMM_2}, {.VD, .VN, .VM, .ENC_FCADD_ROT}, 0x6EC0E400, 0xFFA0EC00, .NEON, {}} },

	// =========================================================================
	// §35 SVE prefetch
	// =========================================================================
	.SVE_PRFB = { {.SVE_PRFB, {.IMM_4, .P_REG_GOV, .MEM, .NONE}, {.ENC_SVE_PRFOP, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0x8400C000, 0xFFE0E000, .SVE, {}} },
	.SVE_PRFH = { {.SVE_PRFH, {.IMM_4, .P_REG_GOV, .MEM, .NONE}, {.ENC_SVE_PRFOP, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0x8480C000, 0xFFE0E000, .SVE, {}} },
	.SVE_PRFW = { {.SVE_PRFW, {.IMM_4, .P_REG_GOV, .MEM, .NONE}, {.ENC_SVE_PRFOP, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0x8500C000, 0xFFE0E000, .SVE, {}} },
	.SVE_PRFD = { {.SVE_PRFD, {.IMM_4, .P_REG_GOV, .MEM, .NONE}, {.ENC_SVE_PRFOP, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0x8580C000, 0xFFE0E000, .SVE, {}} },

	// =========================================================================
	// §36 SVE non-temporal load/store
	// =========================================================================
	.SVE_LDNT1B = { {.SVE_LDNT1B, {.Z_REG_B, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA400C000, 0xFFE0E000, .SVE, {}} },
	.SVE_LDNT1H = { {.SVE_LDNT1H, {.Z_REG_H, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA480C000, 0xFFE0E000, .SVE, {}} },
	.SVE_LDNT1W = { {.SVE_LDNT1W, {.Z_REG_S, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA500C000, 0xFFE0E000, .SVE, {}} },
	.SVE_LDNT1D = { {.SVE_LDNT1D, {.Z_REG_D, .P_REG_ZERO, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA580C000, 0xFFE0E000, .SVE, {is_64=true}} },
	.SVE_STNT1B = { {.SVE_STNT1B, {.Z_REG_B, .P_REG, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE4006000, 0xFFE0E000, .SVE, {}} },
	.SVE_STNT1H = { {.SVE_STNT1H, {.Z_REG_H, .P_REG, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE4806000, 0xFFE0E000, .SVE, {}} },
	.SVE_STNT1W = { {.SVE_STNT1W, {.Z_REG_S, .P_REG, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE5006000, 0xFFE0E000, .SVE, {}} },
	.SVE_STNT1D = { {.SVE_STNT1D, {.Z_REG_D, .P_REG, .MEM, .NONE}, {.VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xE5806000, 0xFFE0E000, .SVE, {is_64=true}} },

	// =========================================================================
	// §37 SVE permute / init: EXT, SPLICE, INDEX (II / IR / RI / RR)
	// =========================================================================
	.SVE_EXT    = { {.SVE_EXT,    {.Z_REG_B, .Z_REG_B, .Z_REG_B, .IMM_8}, {.VD, .VD, .VM, .NONE}, 0x05200000, 0xFFE0E000, .SVE, {}} },
	.SVE_SPLICE = { {.SVE_SPLICE, {.Z_REG_B, .P_REG_GOV, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VN}, 0x052C8000, 0xFFFFE000, .SVE, {}} },
	.SVE_INDEX_II = { {.SVE_INDEX_II, {.Z_REG_B, .IMM_5, .IMM_5, .NONE}, {.VD, .SVE_IMM5, .NONE, .NONE}, 0x04204000, 0xFFE0FC00, .SVE, {}} },
	.SVE_INDEX_IR = { {.SVE_INDEX_IR, {.Z_REG_B, .IMM_5, .X_REG, .NONE}, {.VD, .SVE_IMM5, .RN, .NONE},  0x04204800, 0xFFE0FC00, .SVE, {}} },
	.SVE_INDEX_RI = { {.SVE_INDEX_RI, {.Z_REG_B, .X_REG, .IMM_5, .NONE}, {.VD, .RN, .SVE_IMM5, .NONE},  0x04204400, 0xFFE0FC00, .SVE, {}} },
	.SVE_INDEX_RR = { {.SVE_INDEX_RR, {.Z_REG_B, .X_REG, .X_REG, .NONE}, {.VD, .RN, .RM, .NONE},        0x04204C00, 0xFFE0FC00, .SVE, {}} },

	// =========================================================================
	// §38 SVE2 bit-select family
	// =========================================================================
	// Verified vs LLVM golden (test/MC/AArch64/SVE2/bsl.s):
	//   bsl z0.d, z0.d, z1.d, z2.d = 0x04213C40
	//   Decompose: Zdn=0 at bits 4:0, Zm=1 at bits 20:16, Zk=2 at bits 9:5
	//   Base (operands zero) = 0x04203C00.
	// The other three variants (BSL1N/BSL2N/NBSL) differ at bit 22/23 in
	// most family-encoding traditions; values below are best-memory.
	.SVE_BSL   = { {.SVE_BSL,   {.Z_REG_D, .Z_REG_D, .Z_REG_D, .Z_REG_D}, {.VD, .VD, .VM, .VN}, 0x04203C00, 0xFFE0FC00, .SVE2, {is_64=true}} },
	.SVE_BSL1N = { {.SVE_BSL1N, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .Z_REG_D}, {.VD, .VD, .VM, .VN}, 0x04603C00, 0xFFE0FC00, .SVE2, {is_64=true}} },
	.SVE_BSL2N = { {.SVE_BSL2N, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .Z_REG_D}, {.VD, .VD, .VM, .VN}, 0x04A03C00, 0xFFE0FC00, .SVE2, {is_64=true}} },
	.SVE_NBSL  = { {.SVE_NBSL,  {.Z_REG_D, .Z_REG_D, .Z_REG_D, .Z_REG_D}, {.VD, .VD, .VM, .VN}, 0x04E03C00, 0xFFE0FC00, .SVE2, {is_64=true}} },

	// =========================================================================
	// §39 SVE2 polynomial multiply
	// =========================================================================
	.SVE_PMUL_VEC = { {.SVE_PMUL_VEC, {.Z_REG_B, .Z_REG_B, .Z_REG_B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x04206400, 0xFFE0FC00, .SVE2, {}} },
	.SVE_PMULLB   = { {.SVE_PMULLB,   {.Z_REG_D, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x45006800, 0xFFE0FC00, .SVE2, {is_64=true}} },
	.SVE_PMULLT   = { {.SVE_PMULLT,   {.Z_REG_D, .Z_REG_S, .Z_REG_S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x45006C00, 0xFFE0FC00, .SVE2, {is_64=true}} },

	// =========================================================================
	// §40 SVE BF16 conversions
	// =========================================================================
	.SVE_BFCVT   = { {.SVE_BFCVT,   {.Z_REG_H, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN, .NONE}, 0x658AA000, 0xFFFFE000, .SVE, {}} },
	.SVE_BFCVTNT = { {.SVE_BFCVTNT, {.Z_REG_H, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN, .NONE}, 0x648AA000, 0xFFFFE000, .SVE, {}} },

	// =========================================================================
	// §41 PAC-authenticated loads (v8.3-A)
	// =========================================================================
	//
	//   LDRAA Xt, [Xn{, #imm}]    -- key A, offset form
	//   LDRAB Xt, [Xn{, #imm}]    -- key B, offset form
	//   LDRAA Xt, [Xn{, #imm}]!   -- pre-index variant
	//   LDRAB Xt, [Xn{, #imm}]!
	//
	// bits 31:24 = 11111000, bit 23 = M (key), bits 22:12 = imm10 (scaled by 8),
	// bits 11:10 = 01 (offset) or 11 (pre-index), bits 9:5 = Rn, bits 4:0 = Rt.

	.LDRAA     = { {.LDRAA,     {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0xF8200400, 0xFFA00C00, .PAC, {is_64=true}} },
	.LDRAB     = { {.LDRAB,     {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_U12, .NONE, .NONE}, 0xF8A00400, 0xFFA00C00, .PAC, {is_64=true}} },
	.LDRAA_PRE = { {.LDRAA_PRE, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_PRE, .NONE, .NONE}, 0xF8200C00, 0xFFA00C00, .PAC, {is_64=true}} },
	.LDRAB_PRE = { {.LDRAB_PRE, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_PRE, .NONE, .NONE}, 0xF8A00C00, 0xFFA00C00, .PAC, {is_64=true}} },

	// =========================================================================
	// §42 TME (Transactional Memory Extension, v9.0-A)
	// =========================================================================
	.TSTART  = { {.TSTART,  {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5233060, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.TCOMMIT = { {.TCOMMIT, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE},      0xD503307F, 0xFFFFFFFF, .BASE, {}} },
	.TCANCEL = { {.TCANCEL, {.IMM_16, .NONE, .NONE, .NONE}, {.IMM16, .NONE, .NONE, .NONE}, 0xD4600000, 0xFFE0001F, .BASE, {}} },
	.TTEST   = { {.TTEST,   {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5233160, 0xFFFFFFE0, .BASE, {is_64=true}} },

	// =========================================================================
	// §43 WFIT / WFET (v8.7-A wait with timeout)
	// =========================================================================
	.WFET = { {.WFET, {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5031000, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.WFIT = { {.WFIT, {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5031020, 0xFFFFFFE0, .BASE, {is_64=true}} },

	// =========================================================================
	// §44 BC.cond (v8.8-A branch consistency)
	// =========================================================================
	//
	// Identical to B.cond layout except bit 4 = 1 (the "consistency" hint).
	// The condition code at bits 3:0 is still operand-driven.

	.BC_COND = { {.BC_COND, {.COND, .REL_19, .NONE, .NONE}, {.COND_LO, .BRANCH_19, .NONE, .NONE},
				  0x54000010, 0xFF000010, .BASE, {cond_branch=true}} },

	// =========================================================================
	// §45 Sign/zero-extend aliases (UBFM/SBFM specific cases)
	// =========================================================================
	//
	//   UXTB Wd, Wn   = UBFM Wd, Wn, #0, #7
	//   UXTH Wd, Wn   = UBFM Wd, Wn, #0, #15
	//   UXTW Xd, Wn   = UBFM Xd, Xn, #0, #31  (N=1 for 64-bit form)
	//   SXTB Wd, Wn   = SBFM Wd, Wn, #0, #7
	//   SXTH Wd, Wn   = SBFM Wd, Wn, #0, #15
	//   SXTW Xd, Wn   = SBFM Xd, Wn, #0, #31

	.UXTB = { {.UXTB, {.W_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x53001C00, 0xFFFFFC00, .BASE, {}} },
	.UXTH = { {.UXTH, {.W_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x53003C00, 0xFFFFFC00, .BASE, {}} },
	.UXTW = { {.UXTW, {.X_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0xD3407C00, 0xFFFFFC00, .BASE, {is_64=true}} },
	.SXTB = { {.SXTB, {.W_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x13001C00, 0xFFFFFC00, .BASE, {}} },
	.SXTH = { {.SXTH, {.W_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x13003C00, 0xFFFFFC00, .BASE, {}} },
	.SXTW = { {.SXTW, {.X_REG, .W_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x93407C00, 0xFFFFFC00, .BASE, {is_64=true}} },

	// =========================================================================
	// §46 Carry arithmetic (ADC / ADCS / SBC / SBCS / NGC / NGCS)
	// =========================================================================
	//
	//   ADC  Rd, Rn, Rm    Rd = Rn + Rm + C
	//   ADCS Rd, Rn, Rm    flags-setting variant
	//   SBC  Rd, Rn, Rm    Rd = Rn - Rm - !C
	//   SBCS Rd, Rn, Rm    flags-setting
	//   NGC  Rd, Rm        alias of SBC Rd, ZR, Rm
	//   NGCS Rd, Rm        alias of SBCS Rd, ZR, Rm
	//
	// Layout: sf | op | S | 11010000 | Rm | 000000 | Rn | Rd. Mask covers
	// the static funct field at bits 30:21 + bits 15:10 = 0xFFE0FC00.

	.ADC  = {
		{.ADC,  {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x1A000000, 0xFFE0FC00, .BASE, {}},
		{.ADC,  {.X_REG, .X_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x9A000000, 0xFFE0FC00, .BASE, {is_64=true}},
	},
	.ADCS = {
		{.ADCS, {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x3A000000, 0xFFE0FC00, .BASE, {sets_flags=true}},
		{.ADCS, {.X_REG, .X_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0xBA000000, 0xFFE0FC00, .BASE, {sets_flags=true, is_64=true}},
	},
	.SBC  = {
		{.SBC,  {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x5A000000, 0xFFE0FC00, .BASE, {}},
		{.SBC,  {.X_REG, .X_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0xDA000000, 0xFFE0FC00, .BASE, {is_64=true}},
	},
	.SBCS = {
		{.SBCS, {.W_REG, .W_REG, .W_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0x7A000000, 0xFFE0FC00, .BASE, {sets_flags=true}},
		{.SBCS, {.X_REG, .X_REG, .X_REG, .NONE}, {.RD, .RN, .RM, .NONE}, 0xFA000000, 0xFFE0FC00, .BASE, {sets_flags=true, is_64=true}},
	},
	// NGC/NGCS: Rn = ZR (= 31). Static Rn=31 at bits 9:5 = 0x3E0.
	.NGC  = {
		{.NGC,  {.W_REG, .W_REG, .NONE, .NONE}, {.RD, .RM, .NONE, .NONE}, 0x5A0003E0, 0xFFE0FFE0, .BASE, {}},
		{.NGC,  {.X_REG, .X_REG, .NONE, .NONE}, {.RD, .RM, .NONE, .NONE}, 0xDA0003E0, 0xFFE0FFE0, .BASE, {is_64=true}},
	},
	.NGCS = {
		{.NGCS, {.W_REG, .W_REG, .NONE, .NONE}, {.RD, .RM, .NONE, .NONE}, 0x7A0003E0, 0xFFE0FFE0, .BASE, {sets_flags=true}},
		{.NGCS, {.X_REG, .X_REG, .NONE, .NONE}, {.RD, .RM, .NONE, .NONE}, 0xFA0003E0, 0xFFE0FFE0, .BASE, {sets_flags=true, is_64=true}},
	},

	// =========================================================================
	// §47 RCpc-unscaled load/store (LDAPUR / STLUR family, v8.4-A)
	// =========================================================================
	//
	//   LDAPUR  Rt, [Xn{, #imm9}]    -- load-acquire RCpc, unscaled signed-9
	//   STLUR   Rt, [Xn{, #imm9}]    -- store-release RCpc, unscaled signed-9
	//   LDAPURB Wt, ... / STLURB Wt  -- byte
	//   LDAPURH Wt, ... / STLURH Wt  -- halfword
	//   LDAPURSB Wt/Xt               -- signed-extend byte
	//   LDAPURSH Wt/Xt               -- signed-extend half
	//   LDAPURSW Xt                  -- signed-extend word (64-bit dest)
	//
	// Layout: size:111001 0 0 imm9 00 Rn Rt. opc field selects load/store
	// (00=STLUR, 01=LDAPUR, 10=LDAPURS-64, 11=LDAPURS-32). Mask covers
	// bits 31:21 + bits 11:10 = 0xFFE00C00.

	.LDAPUR  = {
		{.LDAPUR,  {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x99400000, 0xFFE00C00, .BASE, {}},
		{.LDAPUR,  {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xD9400000, 0xFFE00C00, .BASE, {is_64=true}},
	},
	.STLUR   = {
		{.STLUR,   {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x99000000, 0xFFE00C00, .BASE, {}},
		{.STLUR,   {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0xD9000000, 0xFFE00C00, .BASE, {is_64=true}},
	},
	.LDAPURB = { {.LDAPURB, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x19400000, 0xFFE00C00, .BASE, {}} },
	.STLURB  = { {.STLURB,  {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x19000000, 0xFFE00C00, .BASE, {}} },
	.LDAPURH = { {.LDAPURH, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x59400000, 0xFFE00C00, .BASE, {}} },
	.STLURH  = { {.STLURH,  {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x59000000, 0xFFE00C00, .BASE, {}} },
	.LDAPURSB = {
		{.LDAPURSB, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x19800000, 0xFFE00C00, .BASE, {is_64=true}},
		{.LDAPURSB, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x19C00000, 0xFFE00C00, .BASE, {}},
	},
	.LDAPURSH = {
		{.LDAPURSH, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x59800000, 0xFFE00C00, .BASE, {is_64=true}},
		{.LDAPURSH, {.W_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x59C00000, 0xFFE00C00, .BASE, {}},
	},
	.LDAPURSW = { {.LDAPURSW, {.X_REG, .MEM, .NONE, .NONE}, {.RT, .OFFSET_BASE_S9, .NONE, .NONE}, 0x99800000, 0xFFE00C00, .BASE, {is_64=true}} },

	// =========================================================================
	// §48 SVE BF16 predicated arithmetic (3-same)
	// =========================================================================
	//
	//   BFADD Zd.H, Pg/M, Zd.H, Zm.H    Zd = Zd + Zm
	//   BFSUB Zd.H, Pg/M, Zd.H, Zm.H    Zd = Zd - Zm
	//   BFMUL Zd.H, Pg/M, Zd.H, Zm.H    Zd = Zd * Zm
	//   BFMLA Zda.H, Pg/M, Zn.H, Zm.H   Zda += Zn * Zm
	//   BFMLS Zda.H, Pg/M, Zn.H, Zm.H   Zda -= Zn * Zm
	//
	// All use the standard SVE predicated 3-same layout (same shape as
	// FADD_PRED etc.) but with BF16-specific opcode bits.

	.SVE_BFADD = { {.SVE_BFADD, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x65008000, 0xFFE0E000, .SVE, {}} },
	.SVE_BFSUB = { {.SVE_BFSUB, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x65018000, 0xFFE0E000, .SVE, {}} },
	.SVE_BFMUL = { {.SVE_BFMUL, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x65028000, 0xFFE0E000, .SVE, {}} },
	.SVE_BFMLA = { {.SVE_BFMLA, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VN, .VM}, 0x65200000, 0xFFE0E000, .SVE, {}} },
	.SVE_BFMLS = { {.SVE_BFMLS, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VN, .VM}, 0x65202000, 0xFFE0E000, .SVE, {}} },

	// =========================================================================
	// §49 Speculation / profiling barriers + speculation hints
	// =========================================================================
	//
	//   SB              = 0xD50330FF (Speculation Barrier, v8.0)
	//   CSDB            = 0xD503229F (Consumption of Speculative Data Barrier)
	//   DGH             = 0xD50320DF (Data Gathering Hint, v8.5-A)
	//   PSB CSYNC       = 0xD503223F (Profile Sync Barrier)
	//   TSB CSYNC       = 0xD503225F (Trace Sync Barrier, v8.4-A SPE)
	//   BTI j           = 0xD503245F (Branch Target Identification: j)
	//   BTI c           = 0xD503249F (BTI: c)
	//   BTI jc          = 0xD50324DF (BTI: jc)

	.SB        = { {.SB,        {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD50330FF, 0xFFFFFFFF, .BASE, {}} },
	.CSDB      = { {.CSDB,      {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD503229F, 0xFFFFFFFF, .BASE, {}} },
	.DGH       = { {.DGH,       {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD50320DF, 0xFFFFFFFF, .BASE, {}} },
	.PSB_CSYNC = { {.PSB_CSYNC, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD503223F, 0xFFFFFFFF, .BASE, {}} },
	.TSB_CSYNC = { {.TSB_CSYNC, {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD503225F, 0xFFFFFFFF, .BASE, {}} },
	.BTI_J     = { {.BTI_J,     {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD503245F, 0xFFFFFFFF, .BTI,  {}} },
	.BTI_C     = { {.BTI_C,     {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD503249F, 0xFFFFFFFF, .BTI,  {}} },
	.BTI_JC    = { {.BTI_JC,    {.NONE,.NONE,.NONE,.NONE}, {.NONE,.NONE,.NONE,.NONE}, 0xD50324DF, 0xFFFFFFFF, .BTI,  {}} },

	// =========================================================================
	// §50 NEON aliases (printed canonically; encode as the underlying op)
	// =========================================================================
	//
	//   MOV Vd.<T>, Vn.<T>   = ORR Vd.<T>, Vn.<T>, Vn.<T>   (Rm = Rn)
	//   NOT Vd.<T>, Vn.<T>   = MVN with Rm = Rn (NEON vector form)
	//
	// For both we use Rn at both bit positions; the user passes Vd, Vn and
	// the encoder duplicates Vn into the Rm slot via two RM-style packs.

	.MOV_V_ALIAS = {
		// 8B form: 0x0EA01C00 base; Rm=Rn duplicated
		{.MOV_V_ALIAS, {.V_8B, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA01C00, 0xFFE0FC00, .NEON, {}},
		// 16B: 0x4EA01C00
		{.MOV_V_ALIAS, {.V_16B,.V_16B,.NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA01C00, 0xFFE0FC00, .NEON, {}},
	},
	.NOT_V_ALIAS = {
		// NOT.8B Vd, Vn = 0x2E205800 (Q=0)
		{.NOT_V_ALIAS, {.V_8B, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E205800, 0xFFFFFC00, .NEON, {}},
		// NOT.16B Vd, Vn = 0x6E205800 (Q=1)
		{.NOT_V_ALIAS, {.V_16B,.V_16B,.NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E205800, 0xFFFFFC00, .NEON, {}},
	},

	// =========================================================================
	// §51 Shift-by-immediate aliases (LSR / ASR with shift in IMM_5 / IMM_6)
	// =========================================================================
	//
	//   LSR Wd, Wn, #imm     = UBFM Wd, Wn, #imm, #31    base 0x53007C00
	//   LSR Xd, Xn, #imm     = UBFM Xd, Xn, #imm, #63    base 0xD340FC00
	//   ASR Wd, Wn, #imm     = SBFM Wd, Wn, #imm, #31    base 0x13007C00
	//   ASR Xd, Xn, #imm     = SBFM Xd, Xn, #imm, #63    base 0x9340FC00
	//
	// The shift amount (user-passed immediate) goes into the immr field at
	// bits 21:16. The imms field is fully static (31 or 63 baked in).
	//
	// LSL Wd/Xd is more complex (immr = -imm mod regsize, imms = regsize-1-imm)
	// and is intentionally omitted -- users construct via UBFM directly with
	// pre-computed fields.

	.LSR_IMM = {
		{.LSR_IMM, {.W_REG, .W_REG, .IMM_5, .NONE}, {.RD, .RN, .IMM12, .NONE}, 0x53007C00, 0xFFC0FC00, .BASE, {}},
		{.LSR_IMM, {.X_REG, .X_REG, .IMM_6, .NONE}, {.RD, .RN, .IMM12, .NONE}, 0xD340FC00, 0xFFC0FC00, .BASE, {is_64=true}},
	},
	.ASR_IMM = {
		{.ASR_IMM, {.W_REG, .W_REG, .IMM_5, .NONE}, {.RD, .RN, .IMM12, .NONE}, 0x13007C00, 0xFFC0FC00, .BASE, {}},
		{.ASR_IMM, {.X_REG, .X_REG, .IMM_6, .NONE}, {.RD, .RN, .IMM12, .NONE}, 0x9340FC00, 0xFFC0FC00, .BASE, {is_64=true}},
	},

	// Note: IMM12 encoding places the operand into bits 21:10 (12 bits).
	// For LSR/ASR we want immr at bits 21:16 (5 bits) but use IMM12 since
	// bits 15:10 are static (imms field = 31/63 baked in). The packer's
	// 12-bit shift puts the user value at bits 21:10, and the static imms
	// bits OR over the low 6 to fix imms = 31 (for W) or 63 (for X).
	// Mask 0xFFC0FC00 leaves bits 21:16 + 15:10 free for operand + verifies imms.
	// (Operand encoding done in encoder.odin packer; mask above ensures
	// imms is verified static at 31 for W and 63 for X via the bits field.)
	// Actually 0x53007C00 has bits 15:10 = 011111 = 31 ✓ and mask
	// 0xFFC0FC00 covers bits 15:10 too (mask byte 1 = 0xFC) so imms is
	// matched static. Good.

	// =========================================================================
	// §52 LSL_IMM / ROR_IMM composite-packed aliases
	// =========================================================================
	//
	//   LSL Rd, Rn, #imm   = UBFM Rd, Rn, #(-imm % regsize), #(regsize-1-imm)
	//   ROR Rd, Rn, #imm   = EXTR Rd, Rn, Rn, #imm           (Rm = Rn)
	//
	// LSL: the user's single shift amount drives BOTH immr (bits 21:16)
	// and imms (bits 15:10). The ENC_LSL_IMM_W/X packer computes both
	// fields from one operand.
	//
	// ROR: the source register is packed at BOTH the Rn (9:5) and Rm
	// (20:16) slots via ENC_DUAL_RN_RM; shift goes to imms (15:10).

	.LSL_IMM = {
		{.LSL_IMM, {.W_REG, .W_REG, .IMM_5, .NONE}, {.RD, .RN, .ENC_LSL_IMM_W, .NONE}, 0x53000000, 0xFFC00000, .BASE, {}},
		{.LSL_IMM, {.X_REG, .X_REG, .IMM_6, .NONE}, {.RD, .RN, .ENC_LSL_IMM_X, .NONE}, 0xD3400000, 0xFFC00000, .BASE, {is_64=true}},
	},
	.ROR_IMM = {
		// EXTR Rd, Rn, Rn, #lsb: bits = 0x13800000 (32-bit) / 0x93C00000 (64-bit, N=1)
		{.ROR_IMM, {.W_REG, .W_REG, .IMM_5, .NONE}, {.RD, .ENC_DUAL_RN_RM, .ENC_ROR_SHIFT, .NONE}, 0x13800000, 0xFFE00000, .BASE, {}},
		{.ROR_IMM, {.X_REG, .X_REG, .IMM_6, .NONE}, {.RD, .ENC_DUAL_RN_RM, .ENC_ROR_SHIFT, .NONE}, 0x93C00000, 0xFFE00000, .BASE, {is_64=true}},
	},

	// =========================================================================
	// §53 SVE2.1 / SME2 BF16 unpredicated + min/max + clamp
	// =========================================================================
	//
	//   BFADD Zd.H, Zn.H, Zm.H    (unpredicated, SVE2.1)
	//   BFSUB Zd.H, Zn.H, Zm.H
	//   BFMUL Zd.H, Zn.H, Zm.H
	//   BFCLAMP Zd.H, Zn.H, Zm.H  -- Zd = clamp(Zd, Zn, Zm) (min then max)
	//   BFMAXNM, BFMINNM          -- predicated max/min-num for BF16

	.SVE_BFADD_UNPRED = { {.SVE_BFADD_UNPRED, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65000000, 0xFFE0FC00, .SVE2, {}} },
	.SVE_BFSUB_UNPRED = { {.SVE_BFSUB_UNPRED, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65000400, 0xFFE0FC00, .SVE2, {}} },
	.SVE_BFMUL_UNPRED = { {.SVE_BFMUL_UNPRED, {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x65000800, 0xFFE0FC00, .SVE2, {}} },
	.SVE_BFCLAMP      = { {.SVE_BFCLAMP,      {.Z_REG_H, .Z_REG_H, .Z_REG_H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x64202400, 0xFFE0FC00, .SVE2, {}} },
	.SVE_BFMAXNM      = { {.SVE_BFMAXNM,      {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x65048000, 0xFFE0E000, .SVE2, {}} },
	.SVE_BFMINNM      = { {.SVE_BFMINNM,      {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VM}, 0x65058000, 0xFFE0E000, .SVE2, {}} },

	// =========================================================================
	// §54 SME2 multi-vector: LUTI2/LUTI4 + contiguous list LD1/ST1
	// =========================================================================
	//
	// SME2 introduces multi-vector instructions taking a 2-vector list
	// {Zt-Zt+1} or 4-vector list {Zt-Zt+3} as the operand. The starting
	// Z register's number is constrained to be even (pair) or a multiple
	// of 4 (quad), validated by the matcher (Z_PAIR / Z_QUAD types).
	//
	// The encodings here are representative starting bases; the exact
	// sub-opcode bits within each family are best-memory and will need
	// verification against the SME2 spec when actually exercised.

	.SME2_LUTI2_B = { {.SME2_LUTI2_B, {.Z_PAIR, .Z_PAIR, .Z_REG_B, .IMM_3}, {.ENC_Z_PAIR_VD, .ENC_Z_PAIR_VN, .VM, .IMM12}, 0xC08C4000, 0xFFE0F000, .SME, {}} },
	.SME2_LUTI4_B = { {.SME2_LUTI4_B, {.Z_PAIR, .Z_PAIR, .Z_REG_B, .IMM_2}, {.ENC_Z_PAIR_VD, .ENC_Z_PAIR_VN, .VM, .IMM12}, 0xC08A4000, 0xFFE0F000, .SME, {}} },

	// SME2 multi-vector contiguous loads / stores. Form:
	//   LD1B { Zt0.B, Zt1.B },         Pg/Z, [Xn, Xm]            (2-vector)
	//   LD1B { Zt0.B - Zt3.B },        Pg/Z, [Xn, Xm]            (4-vector)
	//   ST1B { Zt0.B, Zt1.B },         Pg,   [Xn, Xm]
	//   ST1B { Zt0.B - Zt3.B },        Pg,   [Xn, Xm]
	//
	// Bases differ by the {x2}/{x4} marker in the sub-opcode bits.

	.SME2_LD1B_X2 = { {.SME2_LD1B_X2, {.Z_PAIR, .P_REG_ZERO, .MEM, .NONE}, {.ENC_Z_PAIR_VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA0000000, 0xFFE0E000, .SME, {}} },
	.SME2_LD1H_X2 = { {.SME2_LD1H_X2, {.Z_PAIR, .P_REG_ZERO, .MEM, .NONE}, {.ENC_Z_PAIR_VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA0002000, 0xFFE0E000, .SME, {}} },
	.SME2_LD1W_X2 = { {.SME2_LD1W_X2, {.Z_PAIR, .P_REG_ZERO, .MEM, .NONE}, {.ENC_Z_PAIR_VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA0004000, 0xFFE0E000, .SME, {}} },
	.SME2_LD1D_X2 = { {.SME2_LD1D_X2, {.Z_PAIR, .P_REG_ZERO, .MEM, .NONE}, {.ENC_Z_PAIR_VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA0006000, 0xFFE0E000, .SME, {is_64=true}} },

	.SME2_LD1B_X4 = { {.SME2_LD1B_X4, {.Z_QUAD, .P_REG_ZERO, .MEM, .NONE}, {.ENC_Z_QUAD_VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA0008000, 0xFFE0E000, .SME, {}} },
	.SME2_LD1H_X4 = { {.SME2_LD1H_X4, {.Z_QUAD, .P_REG_ZERO, .MEM, .NONE}, {.ENC_Z_QUAD_VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA000A000, 0xFFE0E000, .SME, {}} },
	.SME2_LD1W_X4 = { {.SME2_LD1W_X4, {.Z_QUAD, .P_REG_ZERO, .MEM, .NONE}, {.ENC_Z_QUAD_VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA000C000, 0xFFE0E000, .SME, {}} },
	.SME2_LD1D_X4 = { {.SME2_LD1D_X4, {.Z_QUAD, .P_REG_ZERO, .MEM, .NONE}, {.ENC_Z_QUAD_VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA000E000, 0xFFE0E000, .SME, {is_64=true}} },

	.SME2_ST1B_X2 = { {.SME2_ST1B_X2, {.Z_PAIR, .P_REG, .MEM, .NONE}, {.ENC_Z_PAIR_VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA0200000, 0xFFE0E000, .SME, {}} },
	.SME2_ST1H_X2 = { {.SME2_ST1H_X2, {.Z_PAIR, .P_REG, .MEM, .NONE}, {.ENC_Z_PAIR_VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA0202000, 0xFFE0E000, .SME, {}} },
	.SME2_ST1W_X2 = { {.SME2_ST1W_X2, {.Z_PAIR, .P_REG, .MEM, .NONE}, {.ENC_Z_PAIR_VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA0204000, 0xFFE0E000, .SME, {}} },
	.SME2_ST1D_X2 = { {.SME2_ST1D_X2, {.Z_PAIR, .P_REG, .MEM, .NONE}, {.ENC_Z_PAIR_VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA0206000, 0xFFE0E000, .SME, {is_64=true}} },

	.SME2_ST1B_X4 = { {.SME2_ST1B_X4, {.Z_QUAD, .P_REG, .MEM, .NONE}, {.ENC_Z_QUAD_VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA0208000, 0xFFE0E000, .SME, {}} },
	.SME2_ST1H_X4 = { {.SME2_ST1H_X4, {.Z_QUAD, .P_REG, .MEM, .NONE}, {.ENC_Z_QUAD_VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA020A000, 0xFFE0E000, .SME, {}} },
	.SME2_ST1W_X4 = { {.SME2_ST1W_X4, {.Z_QUAD, .P_REG, .MEM, .NONE}, {.ENC_Z_QUAD_VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA020C000, 0xFFE0E000, .SME, {}} },
	.SME2_ST1D_X4 = { {.SME2_ST1D_X4, {.Z_QUAD, .P_REG, .MEM, .NONE}, {.ENC_Z_QUAD_VD, .PG, .SVE_OFFSET_BASE_SS, .NONE}, 0xA020E000, 0xFFE0E000, .SME, {is_64=true}} },

	// SME2 ZIP/UZP 3-way and 4-way multi-vector permutations (subset).
	// ZIP_3/UZP_3: pair result from two single sources (3-operand)
	// ZIP_4/UZP_4: quad list result from quad list source (2-operand, 4-vec)
	.SME2_ZIP_3 = { {.SME2_ZIP_3, {.Z_PAIR, .Z_REG_B, .Z_REG_B, .NONE}, {.ENC_Z_PAIR_VD, .VN, .VM, .NONE}, 0xC120D000, 0xFFE0FC00, .SME, {}} },
	.SME2_ZIP_4 = { {.SME2_ZIP_4, {.Z_QUAD, .Z_QUAD, .NONE,    .NONE}, {.ENC_Z_QUAD_VD, .ENC_Z_QUAD_VN, .NONE, .NONE}, 0xC136E000, 0xFFFFFC00, .SME, {}} },
	.SME2_UZP_3 = { {.SME2_UZP_3, {.Z_PAIR, .Z_REG_B, .Z_REG_B, .NONE}, {.ENC_Z_PAIR_VD, .VN, .VM, .NONE}, 0xC120D001, 0xFFE0FC00, .SME, {}} },
	.SME2_UZP_4 = { {.SME2_UZP_4, {.Z_QUAD, .Z_QUAD, .NONE,    .NONE}, {.ENC_Z_QUAD_VD, .ENC_Z_QUAD_VN, .NONE, .NONE}, 0xC136E002, 0xFFFFFC00, .SME, {}} },

	// =========================================================================
	// §55 RME (Realm Management Extension, ARMv9-A)
	// =========================================================================
	//
	//   TLBI RPALOS Xt    -- invalidate by physical addr (last level)
	//   TLBI RPAOS  Xt    -- invalidate by physical addr (all levels)
	//   TLBI PAALL        -- invalidate all entries in physical AS
	//   TLBI PAALLOS      -- same, outer shareable
	//   AT   S1E1A  Xt    -- stage-1 translate with implicit authority
	//   DC   CIPAPA Xt    -- cache mgmt by physical addr, clean+invalidate
	//   DC   CIGDPAPA Xt  -- same, including tags

	.TLBI_RPALOS   = { {.TLBI_RPALOS,   {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5084EE0, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.TLBI_RPAOS    = { {.TLBI_RPAOS,    {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5084EA0, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.TLBI_PAALL    = { {.TLBI_PAALL,    {.NONE,.NONE,.NONE,.NONE},     {.NONE,.NONE,.NONE,.NONE}, 0xD508E89F, 0xFFFFFFFF, .BASE, {}} },
	.TLBI_PAALLOS  = { {.TLBI_PAALLOS,  {.NONE,.NONE,.NONE,.NONE},     {.NONE,.NONE,.NONE,.NONE}, 0xD508E81F, 0xFFFFFFFF, .BASE, {}} },
	.AT_S1E1A      = { {.AT_S1E1A,      {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD5079140, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.DC_CIPAPA     = { {.DC_CIPAPA,     {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50E7CE0, 0xFFFFFFE0, .BASE, {is_64=true}} },
	.DC_CIGDPAPA   = { {.DC_CIGDPAPA,   {.X_REG, .NONE, .NONE, .NONE}, {.RT, .NONE, .NONE, .NONE}, 0xD50E7DE0, 0xFFFFFFE0, .BASE, {is_64=true}} },

	// =========================================================================
	// SPECGEN — auto-generated, llvm-mc-verified encode forms (NEON/SVE/SME/...).
	// Regenerate via:  luajit tablegen/specgen.lua   ·  do NOT hand-edit this region.
	// =========================================================================
	// SPECGEN:BEGIN
	// Advanced SIMD three-same (integer).
	.SHADD = {
		{.SHADD, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E200400, 0xFFE0FC00, .NEON, {}},
		{.SHADD, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E200400, 0xFFE0FC00, .NEON, {}},
		{.SHADD, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E600400, 0xFFE0FC00, .NEON, {}},
		{.SHADD, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E600400, 0xFFE0FC00, .NEON, {}},
		{.SHADD, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA00400, 0xFFE0FC00, .NEON, {}},
		{.SHADD, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA00400, 0xFFE0FC00, .NEON, {}},
	},
	.UHADD = {
		{.UHADD, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E200400, 0xFFE0FC00, .NEON, {}},
		{.UHADD, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E200400, 0xFFE0FC00, .NEON, {}},
		{.UHADD, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E600400, 0xFFE0FC00, .NEON, {}},
		{.UHADD, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E600400, 0xFFE0FC00, .NEON, {}},
		{.UHADD, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA00400, 0xFFE0FC00, .NEON, {}},
		{.UHADD, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA00400, 0xFFE0FC00, .NEON, {}},
	},
	.SHSUB = {
		{.SHSUB, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E202400, 0xFFE0FC00, .NEON, {}},
		{.SHSUB, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E202400, 0xFFE0FC00, .NEON, {}},
		{.SHSUB, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E602400, 0xFFE0FC00, .NEON, {}},
		{.SHSUB, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E602400, 0xFFE0FC00, .NEON, {}},
		{.SHSUB, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA02400, 0xFFE0FC00, .NEON, {}},
		{.SHSUB, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA02400, 0xFFE0FC00, .NEON, {}},
	},
	.UHSUB = {
		{.UHSUB, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E202400, 0xFFE0FC00, .NEON, {}},
		{.UHSUB, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E202400, 0xFFE0FC00, .NEON, {}},
		{.UHSUB, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E602400, 0xFFE0FC00, .NEON, {}},
		{.UHSUB, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E602400, 0xFFE0FC00, .NEON, {}},
		{.UHSUB, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA02400, 0xFFE0FC00, .NEON, {}},
		{.UHSUB, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA02400, 0xFFE0FC00, .NEON, {}},
	},
	.SRHADD = {
		{.SRHADD, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E201400, 0xFFE0FC00, .NEON, {}},
		{.SRHADD, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E201400, 0xFFE0FC00, .NEON, {}},
		{.SRHADD, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E601400, 0xFFE0FC00, .NEON, {}},
		{.SRHADD, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E601400, 0xFFE0FC00, .NEON, {}},
		{.SRHADD, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA01400, 0xFFE0FC00, .NEON, {}},
		{.SRHADD, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA01400, 0xFFE0FC00, .NEON, {}},
	},
	.URHADD = {
		{.URHADD, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E201400, 0xFFE0FC00, .NEON, {}},
		{.URHADD, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E201400, 0xFFE0FC00, .NEON, {}},
		{.URHADD, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E601400, 0xFFE0FC00, .NEON, {}},
		{.URHADD, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E601400, 0xFFE0FC00, .NEON, {}},
		{.URHADD, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA01400, 0xFFE0FC00, .NEON, {}},
		{.URHADD, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA01400, 0xFFE0FC00, .NEON, {}},
	},
	.SQADD = {
		{.SQADD, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E200C00, 0xFFE0FC00, .NEON, {}},
		{.SQADD, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E200C00, 0xFFE0FC00, .NEON, {}},
		{.SQADD, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E600C00, 0xFFE0FC00, .NEON, {}},
		{.SQADD, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E600C00, 0xFFE0FC00, .NEON, {}},
		{.SQADD, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA00C00, 0xFFE0FC00, .NEON, {}},
		{.SQADD, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA00C00, 0xFFE0FC00, .NEON, {}},
		{.SQADD, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE00C00, 0xFFE0FC00, .NEON, {}},
	},
	.UQADD = {
		{.UQADD, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E200C00, 0xFFE0FC00, .NEON, {}},
		{.UQADD, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E200C00, 0xFFE0FC00, .NEON, {}},
		{.UQADD, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E600C00, 0xFFE0FC00, .NEON, {}},
		{.UQADD, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E600C00, 0xFFE0FC00, .NEON, {}},
		{.UQADD, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA00C00, 0xFFE0FC00, .NEON, {}},
		{.UQADD, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA00C00, 0xFFE0FC00, .NEON, {}},
		{.UQADD, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE00C00, 0xFFE0FC00, .NEON, {}},
	},
	.SQSUB = {
		{.SQSUB, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E202C00, 0xFFE0FC00, .NEON, {}},
		{.SQSUB, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E202C00, 0xFFE0FC00, .NEON, {}},
		{.SQSUB, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E602C00, 0xFFE0FC00, .NEON, {}},
		{.SQSUB, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E602C00, 0xFFE0FC00, .NEON, {}},
		{.SQSUB, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA02C00, 0xFFE0FC00, .NEON, {}},
		{.SQSUB, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA02C00, 0xFFE0FC00, .NEON, {}},
		{.SQSUB, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE02C00, 0xFFE0FC00, .NEON, {}},
	},
	.UQSUB = {
		{.UQSUB, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E202C00, 0xFFE0FC00, .NEON, {}},
		{.UQSUB, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E202C00, 0xFFE0FC00, .NEON, {}},
		{.UQSUB, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E602C00, 0xFFE0FC00, .NEON, {}},
		{.UQSUB, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E602C00, 0xFFE0FC00, .NEON, {}},
		{.UQSUB, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA02C00, 0xFFE0FC00, .NEON, {}},
		{.UQSUB, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA02C00, 0xFFE0FC00, .NEON, {}},
		{.UQSUB, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE02C00, 0xFFE0FC00, .NEON, {}},
	},
	.SMAX = {
		{.SMAX, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E206400, 0xFFE0FC00, .NEON, {}},
		{.SMAX, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E206400, 0xFFE0FC00, .NEON, {}},
		{.SMAX, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E606400, 0xFFE0FC00, .NEON, {}},
		{.SMAX, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E606400, 0xFFE0FC00, .NEON, {}},
		{.SMAX, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA06400, 0xFFE0FC00, .NEON, {}},
		{.SMAX, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA06400, 0xFFE0FC00, .NEON, {}},
	},
	.UMAX = {
		{.UMAX, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E206400, 0xFFE0FC00, .NEON, {}},
		{.UMAX, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E206400, 0xFFE0FC00, .NEON, {}},
		{.UMAX, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E606400, 0xFFE0FC00, .NEON, {}},
		{.UMAX, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E606400, 0xFFE0FC00, .NEON, {}},
		{.UMAX, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA06400, 0xFFE0FC00, .NEON, {}},
		{.UMAX, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA06400, 0xFFE0FC00, .NEON, {}},
	},
	.SMIN = {
		{.SMIN, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E206C00, 0xFFE0FC00, .NEON, {}},
		{.SMIN, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E206C00, 0xFFE0FC00, .NEON, {}},
		{.SMIN, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E606C00, 0xFFE0FC00, .NEON, {}},
		{.SMIN, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E606C00, 0xFFE0FC00, .NEON, {}},
		{.SMIN, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA06C00, 0xFFE0FC00, .NEON, {}},
		{.SMIN, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA06C00, 0xFFE0FC00, .NEON, {}},
	},
	.UMIN = {
		{.UMIN, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E206C00, 0xFFE0FC00, .NEON, {}},
		{.UMIN, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E206C00, 0xFFE0FC00, .NEON, {}},
		{.UMIN, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E606C00, 0xFFE0FC00, .NEON, {}},
		{.UMIN, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E606C00, 0xFFE0FC00, .NEON, {}},
		{.UMIN, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA06C00, 0xFFE0FC00, .NEON, {}},
		{.UMIN, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA06C00, 0xFFE0FC00, .NEON, {}},
	},
	.SABD = {
		{.SABD, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E207400, 0xFFE0FC00, .NEON, {}},
		{.SABD, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E207400, 0xFFE0FC00, .NEON, {}},
		{.SABD, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E607400, 0xFFE0FC00, .NEON, {}},
		{.SABD, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E607400, 0xFFE0FC00, .NEON, {}},
		{.SABD, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA07400, 0xFFE0FC00, .NEON, {}},
		{.SABD, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA07400, 0xFFE0FC00, .NEON, {}},
	},
	.UABD = {
		{.UABD, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E207400, 0xFFE0FC00, .NEON, {}},
		{.UABD, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E207400, 0xFFE0FC00, .NEON, {}},
		{.UABD, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E607400, 0xFFE0FC00, .NEON, {}},
		{.UABD, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E607400, 0xFFE0FC00, .NEON, {}},
		{.UABD, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA07400, 0xFFE0FC00, .NEON, {}},
		{.UABD, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA07400, 0xFFE0FC00, .NEON, {}},
	},
	.SABA = {
		{.SABA, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E207C00, 0xFFE0FC00, .NEON, {}},
		{.SABA, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E207C00, 0xFFE0FC00, .NEON, {}},
		{.SABA, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E607C00, 0xFFE0FC00, .NEON, {}},
		{.SABA, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E607C00, 0xFFE0FC00, .NEON, {}},
		{.SABA, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA07C00, 0xFFE0FC00, .NEON, {}},
		{.SABA, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA07C00, 0xFFE0FC00, .NEON, {}},
	},
	.UABA = {
		{.UABA, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E207C00, 0xFFE0FC00, .NEON, {}},
		{.UABA, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E207C00, 0xFFE0FC00, .NEON, {}},
		{.UABA, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E607C00, 0xFFE0FC00, .NEON, {}},
		{.UABA, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E607C00, 0xFFE0FC00, .NEON, {}},
		{.UABA, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA07C00, 0xFFE0FC00, .NEON, {}},
		{.UABA, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA07C00, 0xFFE0FC00, .NEON, {}},
	},
	.MLA_V = {
		{.MLA_V, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E209400, 0xFFE0FC00, .NEON, {}},
		{.MLA_V, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E209400, 0xFFE0FC00, .NEON, {}},
		{.MLA_V, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E609400, 0xFFE0FC00, .NEON, {}},
		{.MLA_V, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E609400, 0xFFE0FC00, .NEON, {}},
		{.MLA_V, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA09400, 0xFFE0FC00, .NEON, {}},
		{.MLA_V, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA09400, 0xFFE0FC00, .NEON, {}},
	},
	.MLS_V = {
		{.MLS_V, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E209400, 0xFFE0FC00, .NEON, {}},
		{.MLS_V, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E209400, 0xFFE0FC00, .NEON, {}},
		{.MLS_V, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E609400, 0xFFE0FC00, .NEON, {}},
		{.MLS_V, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E609400, 0xFFE0FC00, .NEON, {}},
		{.MLS_V, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA09400, 0xFFE0FC00, .NEON, {}},
		{.MLS_V, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA09400, 0xFFE0FC00, .NEON, {}},
	},
	.CMGE = {
		{.CMGE, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E203C00, 0xFFE0FC00, .NEON, {}},
		{.CMGE, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E203C00, 0xFFE0FC00, .NEON, {}},
		{.CMGE, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E603C00, 0xFFE0FC00, .NEON, {}},
		{.CMGE, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E603C00, 0xFFE0FC00, .NEON, {}},
		{.CMGE, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA03C00, 0xFFE0FC00, .NEON, {}},
		{.CMGE, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA03C00, 0xFFE0FC00, .NEON, {}},
		{.CMGE, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE03C00, 0xFFE0FC00, .NEON, {}},
	},
	.CMHS = {
		{.CMHS, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E203C00, 0xFFE0FC00, .NEON, {}},
		{.CMHS, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E203C00, 0xFFE0FC00, .NEON, {}},
		{.CMHS, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E603C00, 0xFFE0FC00, .NEON, {}},
		{.CMHS, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E603C00, 0xFFE0FC00, .NEON, {}},
		{.CMHS, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA03C00, 0xFFE0FC00, .NEON, {}},
		{.CMHS, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA03C00, 0xFFE0FC00, .NEON, {}},
		{.CMHS, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE03C00, 0xFFE0FC00, .NEON, {}},
	},
	.CMTST = {
		{.CMTST, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E208C00, 0xFFE0FC00, .NEON, {}},
		{.CMTST, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E208C00, 0xFFE0FC00, .NEON, {}},
		{.CMTST, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E608C00, 0xFFE0FC00, .NEON, {}},
		{.CMTST, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E608C00, 0xFFE0FC00, .NEON, {}},
		{.CMTST, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA08C00, 0xFFE0FC00, .NEON, {}},
		{.CMTST, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA08C00, 0xFFE0FC00, .NEON, {}},
		{.CMTST, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE08C00, 0xFFE0FC00, .NEON, {}},
	},
	.SQDMULH = {
		{.SQDMULH, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E60B400, 0xFFE0FC00, .NEON, {}},
		{.SQDMULH, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60B400, 0xFFE0FC00, .NEON, {}},
		{.SQDMULH, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA0B400, 0xFFE0FC00, .NEON, {}},
		{.SQDMULH, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA0B400, 0xFFE0FC00, .NEON, {}},
	},
	.SQRDMULH = {
		{.SQRDMULH, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E60B400, 0xFFE0FC00, .NEON, {}},
		{.SQRDMULH, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E60B400, 0xFFE0FC00, .NEON, {}},
		{.SQRDMULH, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA0B400, 0xFFE0FC00, .NEON, {}},
		{.SQRDMULH, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA0B400, 0xFFE0FC00, .NEON, {}},
	},
	.ADDP_V = {
		{.ADDP_V, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E20BC00, 0xFFE0FC00, .NEON, {}},
		{.ADDP_V, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E20BC00, 0xFFE0FC00, .NEON, {}},
		{.ADDP_V, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E60BC00, 0xFFE0FC00, .NEON, {}},
		{.ADDP_V, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60BC00, 0xFFE0FC00, .NEON, {}},
		{.ADDP_V, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA0BC00, 0xFFE0FC00, .NEON, {}},
		{.ADDP_V, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA0BC00, 0xFFE0FC00, .NEON, {}},
		{.ADDP_V, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE0BC00, 0xFFE0FC00, .NEON, {}},
	},
	.SMAXP = {
		{.SMAXP, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E20A400, 0xFFE0FC00, .NEON, {}},
		{.SMAXP, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E20A400, 0xFFE0FC00, .NEON, {}},
		{.SMAXP, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E60A400, 0xFFE0FC00, .NEON, {}},
		{.SMAXP, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60A400, 0xFFE0FC00, .NEON, {}},
		{.SMAXP, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA0A400, 0xFFE0FC00, .NEON, {}},
		{.SMAXP, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA0A400, 0xFFE0FC00, .NEON, {}},
	},
	.SMINP = {
		{.SMINP, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E20AC00, 0xFFE0FC00, .NEON, {}},
		{.SMINP, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E20AC00, 0xFFE0FC00, .NEON, {}},
		{.SMINP, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E60AC00, 0xFFE0FC00, .NEON, {}},
		{.SMINP, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60AC00, 0xFFE0FC00, .NEON, {}},
		{.SMINP, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA0AC00, 0xFFE0FC00, .NEON, {}},
		{.SMINP, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA0AC00, 0xFFE0FC00, .NEON, {}},
	},
	.UMAXP = {
		{.UMAXP, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E20A400, 0xFFE0FC00, .NEON, {}},
		{.UMAXP, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E20A400, 0xFFE0FC00, .NEON, {}},
		{.UMAXP, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E60A400, 0xFFE0FC00, .NEON, {}},
		{.UMAXP, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E60A400, 0xFFE0FC00, .NEON, {}},
		{.UMAXP, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA0A400, 0xFFE0FC00, .NEON, {}},
		{.UMAXP, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA0A400, 0xFFE0FC00, .NEON, {}},
	},
	.UMINP = {
		{.UMINP, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E20AC00, 0xFFE0FC00, .NEON, {}},
		{.UMINP, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E20AC00, 0xFFE0FC00, .NEON, {}},
		{.UMINP, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E60AC00, 0xFFE0FC00, .NEON, {}},
		{.UMINP, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E60AC00, 0xFFE0FC00, .NEON, {}},
		{.UMINP, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA0AC00, 0xFFE0FC00, .NEON, {}},
		{.UMINP, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA0AC00, 0xFFE0FC00, .NEON, {}},
	},
	.SSHL = {
		{.SSHL, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E204400, 0xFFE0FC00, .NEON, {}},
		{.SSHL, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E204400, 0xFFE0FC00, .NEON, {}},
		{.SSHL, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E604400, 0xFFE0FC00, .NEON, {}},
		{.SSHL, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E604400, 0xFFE0FC00, .NEON, {}},
		{.SSHL, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA04400, 0xFFE0FC00, .NEON, {}},
		{.SSHL, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA04400, 0xFFE0FC00, .NEON, {}},
		{.SSHL, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE04400, 0xFFE0FC00, .NEON, {}},
	},
	.USHL = {
		{.USHL, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E204400, 0xFFE0FC00, .NEON, {}},
		{.USHL, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E204400, 0xFFE0FC00, .NEON, {}},
		{.USHL, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E604400, 0xFFE0FC00, .NEON, {}},
		{.USHL, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E604400, 0xFFE0FC00, .NEON, {}},
		{.USHL, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA04400, 0xFFE0FC00, .NEON, {}},
		{.USHL, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA04400, 0xFFE0FC00, .NEON, {}},
		{.USHL, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE04400, 0xFFE0FC00, .NEON, {}},
	},
	.SRSHL = {
		{.SRSHL, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E205400, 0xFFE0FC00, .NEON, {}},
		{.SRSHL, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E205400, 0xFFE0FC00, .NEON, {}},
		{.SRSHL, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E605400, 0xFFE0FC00, .NEON, {}},
		{.SRSHL, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E605400, 0xFFE0FC00, .NEON, {}},
		{.SRSHL, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA05400, 0xFFE0FC00, .NEON, {}},
		{.SRSHL, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA05400, 0xFFE0FC00, .NEON, {}},
		{.SRSHL, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE05400, 0xFFE0FC00, .NEON, {}},
	},
	.URSHL = {
		{.URSHL, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E205400, 0xFFE0FC00, .NEON, {}},
		{.URSHL, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E205400, 0xFFE0FC00, .NEON, {}},
		{.URSHL, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E605400, 0xFFE0FC00, .NEON, {}},
		{.URSHL, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E605400, 0xFFE0FC00, .NEON, {}},
		{.URSHL, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA05400, 0xFFE0FC00, .NEON, {}},
		{.URSHL, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA05400, 0xFFE0FC00, .NEON, {}},
		{.URSHL, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE05400, 0xFFE0FC00, .NEON, {}},
	},

	// Advanced SIMD permute (ZIP/UZP/TRN).
	.ZIP1 = {
		{.ZIP1, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E003800, 0xFFE0FC00, .NEON, {}},
		{.ZIP1, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E003800, 0xFFE0FC00, .NEON, {}},
		{.ZIP1, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E403800, 0xFFE0FC00, .NEON, {}},
		{.ZIP1, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E403800, 0xFFE0FC00, .NEON, {}},
		{.ZIP1, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E803800, 0xFFE0FC00, .NEON, {}},
		{.ZIP1, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E803800, 0xFFE0FC00, .NEON, {}},
		{.ZIP1, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EC03800, 0xFFE0FC00, .NEON, {}},
	},
	.ZIP2 = {
		{.ZIP2, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E007800, 0xFFE0FC00, .NEON, {}},
		{.ZIP2, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E007800, 0xFFE0FC00, .NEON, {}},
		{.ZIP2, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E407800, 0xFFE0FC00, .NEON, {}},
		{.ZIP2, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E407800, 0xFFE0FC00, .NEON, {}},
		{.ZIP2, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E807800, 0xFFE0FC00, .NEON, {}},
		{.ZIP2, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E807800, 0xFFE0FC00, .NEON, {}},
		{.ZIP2, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EC07800, 0xFFE0FC00, .NEON, {}},
	},
	.UZP1 = {
		{.UZP1, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E001800, 0xFFE0FC00, .NEON, {}},
		{.UZP1, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E001800, 0xFFE0FC00, .NEON, {}},
		{.UZP1, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E401800, 0xFFE0FC00, .NEON, {}},
		{.UZP1, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E401800, 0xFFE0FC00, .NEON, {}},
		{.UZP1, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E801800, 0xFFE0FC00, .NEON, {}},
		{.UZP1, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E801800, 0xFFE0FC00, .NEON, {}},
		{.UZP1, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EC01800, 0xFFE0FC00, .NEON, {}},
	},
	.UZP2 = {
		{.UZP2, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E005800, 0xFFE0FC00, .NEON, {}},
		{.UZP2, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E005800, 0xFFE0FC00, .NEON, {}},
		{.UZP2, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E405800, 0xFFE0FC00, .NEON, {}},
		{.UZP2, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E405800, 0xFFE0FC00, .NEON, {}},
		{.UZP2, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E805800, 0xFFE0FC00, .NEON, {}},
		{.UZP2, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E805800, 0xFFE0FC00, .NEON, {}},
		{.UZP2, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EC05800, 0xFFE0FC00, .NEON, {}},
	},
	.TRN1 = {
		{.TRN1, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E002800, 0xFFE0FC00, .NEON, {}},
		{.TRN1, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E002800, 0xFFE0FC00, .NEON, {}},
		{.TRN1, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E402800, 0xFFE0FC00, .NEON, {}},
		{.TRN1, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E402800, 0xFFE0FC00, .NEON, {}},
		{.TRN1, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E802800, 0xFFE0FC00, .NEON, {}},
		{.TRN1, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E802800, 0xFFE0FC00, .NEON, {}},
		{.TRN1, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EC02800, 0xFFE0FC00, .NEON, {}},
	},
	.TRN2 = {
		{.TRN2, {.V_8B, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E006800, 0xFFE0FC00, .NEON, {}},
		{.TRN2, {.V_16B, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E006800, 0xFFE0FC00, .NEON, {}},
		{.TRN2, {.V_4H, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E406800, 0xFFE0FC00, .NEON, {}},
		{.TRN2, {.V_8H, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E406800, 0xFFE0FC00, .NEON, {}},
		{.TRN2, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E806800, 0xFFE0FC00, .NEON, {}},
		{.TRN2, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E806800, 0xFFE0FC00, .NEON, {}},
		{.TRN2, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EC06800, 0xFFE0FC00, .NEON, {}},
	},

	// Advanced SIMD two-register misc.
	.ABS_V = {
		{.ABS_V, {.V_8B, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E20B800, 0xFFFFFC00, .NEON, {}},
		{.ABS_V, {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E20B800, 0xFFFFFC00, .NEON, {}},
		{.ABS_V, {.V_4H, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E60B800, 0xFFFFFC00, .NEON, {}},
		{.ABS_V, {.V_8H, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E60B800, 0xFFFFFC00, .NEON, {}},
		{.ABS_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA0B800, 0xFFFFFC00, .NEON, {}},
		{.ABS_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA0B800, 0xFFFFFC00, .NEON, {}},
		{.ABS_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EE0B800, 0xFFFFFC00, .NEON, {}},
	},
	.NEG_V = {
		{.NEG_V, {.V_8B, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E20B800, 0xFFFFFC00, .NEON, {}},
		{.NEG_V, {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E20B800, 0xFFFFFC00, .NEON, {}},
		{.NEG_V, {.V_4H, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E60B800, 0xFFFFFC00, .NEON, {}},
		{.NEG_V, {.V_8H, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E60B800, 0xFFFFFC00, .NEON, {}},
		{.NEG_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA0B800, 0xFFFFFC00, .NEON, {}},
		{.NEG_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA0B800, 0xFFFFFC00, .NEON, {}},
		{.NEG_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EE0B800, 0xFFFFFC00, .NEON, {}},
	},
	.NOT_V = {
		{.NOT_V, {.V_8B, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E205800, 0xFFFFFC00, .NEON, {}},
		{.NOT_V, {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E205800, 0xFFFFFC00, .NEON, {}},
	},
	.RBIT_V = {
		{.RBIT_V, {.V_8B, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E605800, 0xFFFFFC00, .NEON, {}},
		{.RBIT_V, {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E605800, 0xFFFFFC00, .NEON, {}},
	},
	.REV16_V = {
		{.REV16_V, {.V_8B, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E201800, 0xFFFFFC00, .NEON, {}},
		{.REV16_V, {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E201800, 0xFFFFFC00, .NEON, {}},
	},
	.REV32_V = {
		{.REV32_V, {.V_8B, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E200800, 0xFFFFFC00, .NEON, {}},
		{.REV32_V, {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E200800, 0xFFFFFC00, .NEON, {}},
		{.REV32_V, {.V_4H, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E600800, 0xFFFFFC00, .NEON, {}},
		{.REV32_V, {.V_8H, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E600800, 0xFFFFFC00, .NEON, {}},
	},
	.REV64 = {
		{.REV64, {.V_8B, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E200800, 0xFFFFFC00, .NEON, {}},
		{.REV64, {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E200800, 0xFFFFFC00, .NEON, {}},
		{.REV64, {.V_4H, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E600800, 0xFFFFFC00, .NEON, {}},
		{.REV64, {.V_8H, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E600800, 0xFFFFFC00, .NEON, {}},
		{.REV64, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA00800, 0xFFFFFC00, .NEON, {}},
		{.REV64, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA00800, 0xFFFFFC00, .NEON, {}},
	},
	.CLS_V = {
		{.CLS_V, {.V_8B, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E204800, 0xFFFFFC00, .NEON, {}},
		{.CLS_V, {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E204800, 0xFFFFFC00, .NEON, {}},
		{.CLS_V, {.V_4H, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E604800, 0xFFFFFC00, .NEON, {}},
		{.CLS_V, {.V_8H, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E604800, 0xFFFFFC00, .NEON, {}},
		{.CLS_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA04800, 0xFFFFFC00, .NEON, {}},
		{.CLS_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA04800, 0xFFFFFC00, .NEON, {}},
	},
	.CLZ_V = {
		{.CLZ_V, {.V_8B, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E204800, 0xFFFFFC00, .NEON, {}},
		{.CLZ_V, {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E204800, 0xFFFFFC00, .NEON, {}},
		{.CLZ_V, {.V_4H, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E604800, 0xFFFFFC00, .NEON, {}},
		{.CLZ_V, {.V_8H, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E604800, 0xFFFFFC00, .NEON, {}},
		{.CLZ_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA04800, 0xFFFFFC00, .NEON, {}},
		{.CLZ_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA04800, 0xFFFFFC00, .NEON, {}},
	},
	.CNT = {
		{.CNT, {.V_8B, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E205800, 0xFFFFFC00, .NEON, {}},
		{.CNT, {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E205800, 0xFFFFFC00, .NEON, {}},
	},
	.URECPE_V = {
		{.URECPE_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA1C800, 0xFFFFFC00, .NEON, {}},
		{.URECPE_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA1C800, 0xFFFFFC00, .NEON, {}},
	},
	.URSQRTE_V = {
		{.URSQRTE_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA1C800, 0xFFFFFC00, .NEON, {}},
		{.URSQRTE_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA1C800, 0xFFFFFC00, .NEON, {}},
	},

	// Advanced SIMD floating-point three-same.
	.FMAX_V = {
		{.FMAX_V, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E20F400, 0xFFE0FC00, .NEON, {}},
		{.FMAX_V, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E20F400, 0xFFE0FC00, .NEON, {}},
		{.FMAX_V, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60F400, 0xFFE0FC00, .NEON, {}},
		{.FMAX_V, {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E403400, 0xFFE0FC00, .FP16, {}},
		{.FMAX_V, {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E403400, 0xFFE0FC00, .FP16, {}},
	},
	.FMIN_V = {
		{.FMIN_V, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA0F400, 0xFFE0FC00, .NEON, {}},
		{.FMIN_V, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA0F400, 0xFFE0FC00, .NEON, {}},
		{.FMIN_V, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE0F400, 0xFFE0FC00, .NEON, {}},
		{.FMIN_V, {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EC03400, 0xFFE0FC00, .FP16, {}},
		{.FMIN_V, {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EC03400, 0xFFE0FC00, .FP16, {}},
	},
	.FMAXNM_V = {
		{.FMAXNM_V, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E20C400, 0xFFE0FC00, .NEON, {}},
		{.FMAXNM_V, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E20C400, 0xFFE0FC00, .NEON, {}},
		{.FMAXNM_V, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60C400, 0xFFE0FC00, .NEON, {}},
		{.FMAXNM_V, {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E400400, 0xFFE0FC00, .FP16, {}},
		{.FMAXNM_V, {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E400400, 0xFFE0FC00, .FP16, {}},
	},
	.FMINNM_V = {
		{.FMINNM_V, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA0C400, 0xFFE0FC00, .NEON, {}},
		{.FMINNM_V, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA0C400, 0xFFE0FC00, .NEON, {}},
		{.FMINNM_V, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE0C400, 0xFFE0FC00, .NEON, {}},
		{.FMINNM_V, {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EC00400, 0xFFE0FC00, .FP16, {}},
		{.FMINNM_V, {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EC00400, 0xFFE0FC00, .FP16, {}},
	},
	.FMULX = {
		{.FMULX, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E20DC00, 0xFFE0FC00, .NEON, {}},
		{.FMULX, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E20DC00, 0xFFE0FC00, .NEON, {}},
		{.FMULX, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60DC00, 0xFFE0FC00, .NEON, {}},
		{.FMULX, {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E401C00, 0xFFE0FC00, .FP16, {}},
		{.FMULX, {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E401C00, 0xFFE0FC00, .FP16, {}},
	},
	.FRECPS = {
		{.FRECPS, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E20FC00, 0xFFE0FC00, .NEON, {}},
		{.FRECPS, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E20FC00, 0xFFE0FC00, .NEON, {}},
		{.FRECPS, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60FC00, 0xFFE0FC00, .NEON, {}},
		{.FRECPS, {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E403C00, 0xFFE0FC00, .FP16, {}},
		{.FRECPS, {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E403C00, 0xFFE0FC00, .FP16, {}},
	},
	.FRSQRTS = {
		{.FRSQRTS, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA0FC00, 0xFFE0FC00, .NEON, {}},
		{.FRSQRTS, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA0FC00, 0xFFE0FC00, .NEON, {}},
		{.FRSQRTS, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EE0FC00, 0xFFE0FC00, .NEON, {}},
		{.FRSQRTS, {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EC03C00, 0xFFE0FC00, .FP16, {}},
		{.FRSQRTS, {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EC03C00, 0xFFE0FC00, .FP16, {}},
	},
	.FACGE = {
		{.FACGE, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E20EC00, 0xFFE0FC00, .NEON, {}},
		{.FACGE, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E20EC00, 0xFFE0FC00, .NEON, {}},
		{.FACGE, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E60EC00, 0xFFE0FC00, .NEON, {}},
		{.FACGE, {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E402C00, 0xFFE0FC00, .FP16, {}},
		{.FACGE, {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E402C00, 0xFFE0FC00, .FP16, {}},
	},
	.FACGT = {
		{.FACGT, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA0EC00, 0xFFE0FC00, .NEON, {}},
		{.FACGT, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA0EC00, 0xFFE0FC00, .NEON, {}},
		{.FACGT, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE0EC00, 0xFFE0FC00, .NEON, {}},
		{.FACGT, {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EC02C00, 0xFFE0FC00, .FP16, {}},
		{.FACGT, {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EC02C00, 0xFFE0FC00, .FP16, {}},
	},
	.FCMEQ = {
		{.FCMEQ, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E20E400, 0xFFE0FC00, .NEON, {}},
		{.FCMEQ, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E20E400, 0xFFE0FC00, .NEON, {}},
		{.FCMEQ, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60E400, 0xFFE0FC00, .NEON, {}},
		{.FCMEQ, {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E402400, 0xFFE0FC00, .FP16, {}},
		{.FCMEQ, {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E402400, 0xFFE0FC00, .FP16, {}},
	},
	.FCMGE = {
		{.FCMGE, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E20E400, 0xFFE0FC00, .NEON, {}},
		{.FCMGE, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E20E400, 0xFFE0FC00, .NEON, {}},
		{.FCMGE, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E60E400, 0xFFE0FC00, .NEON, {}},
		{.FCMGE, {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E402400, 0xFFE0FC00, .FP16, {}},
		{.FCMGE, {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E402400, 0xFFE0FC00, .FP16, {}},
	},
	.FCMGT = {
		{.FCMGT, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA0E400, 0xFFE0FC00, .NEON, {}},
		{.FCMGT, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA0E400, 0xFFE0FC00, .NEON, {}},
		{.FCMGT, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE0E400, 0xFFE0FC00, .NEON, {}},
		{.FCMGT, {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EC02400, 0xFFE0FC00, .FP16, {}},
		{.FCMGT, {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EC02400, 0xFFE0FC00, .FP16, {}},
	},
	.FADDP_V = {
		{.FADDP_V, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E20D400, 0xFFE0FC00, .NEON, {}},
		{.FADDP_V, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E20D400, 0xFFE0FC00, .NEON, {}},
		{.FADDP_V, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E60D400, 0xFFE0FC00, .NEON, {}},
		{.FADDP_V, {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E401400, 0xFFE0FC00, .FP16, {}},
		{.FADDP_V, {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E401400, 0xFFE0FC00, .FP16, {}},
	},
	.FMAXP_V = {
		{.FMAXP_V, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E20F400, 0xFFE0FC00, .NEON, {}},
		{.FMAXP_V, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E20F400, 0xFFE0FC00, .NEON, {}},
		{.FMAXP_V, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E60F400, 0xFFE0FC00, .NEON, {}},
		{.FMAXP_V, {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E403400, 0xFFE0FC00, .FP16, {}},
		{.FMAXP_V, {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E403400, 0xFFE0FC00, .FP16, {}},
	},
	.FMINP_V = {
		{.FMINP_V, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA0F400, 0xFFE0FC00, .NEON, {}},
		{.FMINP_V, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA0F400, 0xFFE0FC00, .NEON, {}},
		{.FMINP_V, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE0F400, 0xFFE0FC00, .NEON, {}},
		{.FMINP_V, {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EC03400, 0xFFE0FC00, .FP16, {}},
		{.FMINP_V, {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EC03400, 0xFFE0FC00, .FP16, {}},
	},
	.FMAXNMP = {
		{.FMAXNMP, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E20C400, 0xFFE0FC00, .NEON, {}},
		{.FMAXNMP, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E20C400, 0xFFE0FC00, .NEON, {}},
		{.FMAXNMP, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E60C400, 0xFFE0FC00, .NEON, {}},
		{.FMAXNMP, {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E400400, 0xFFE0FC00, .FP16, {}},
		{.FMAXNMP, {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E400400, 0xFFE0FC00, .FP16, {}},
	},
	.FMINNMP = {
		{.FMINNMP, {.V_2S, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA0C400, 0xFFE0FC00, .NEON, {}},
		{.FMINNMP, {.V_4S, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA0C400, 0xFFE0FC00, .NEON, {}},
		{.FMINNMP, {.V_2D, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EE0C400, 0xFFE0FC00, .NEON, {}},
		{.FMINNMP, {.V_4H_FP16, .V_4H_FP16, .V_4H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EC00400, 0xFFE0FC00, .FP16, {}},
		{.FMINNMP, {.V_8H_FP16, .V_8H_FP16, .V_8H_FP16, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EC00400, 0xFFE0FC00, .FP16, {}},
	},

	// Advanced SIMD floating-point two-register.
	.FABS_V = {
		{.FABS_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA0F800, 0xFFFFFC00, .NEON, {}},
		{.FABS_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA0F800, 0xFFFFFC00, .NEON, {}},
		{.FABS_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EE0F800, 0xFFFFFC00, .NEON, {}},
		{.FABS_V, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EF8F800, 0xFFFFFC00, .FP16, {}},
		{.FABS_V, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EF8F800, 0xFFFFFC00, .FP16, {}},
	},
	.FNEG_V = {
		{.FNEG_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA0F800, 0xFFFFFC00, .NEON, {}},
		{.FNEG_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA0F800, 0xFFFFFC00, .NEON, {}},
		{.FNEG_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EE0F800, 0xFFFFFC00, .NEON, {}},
		{.FNEG_V, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EF8F800, 0xFFFFFC00, .FP16, {}},
		{.FNEG_V, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EF8F800, 0xFFFFFC00, .FP16, {}},
	},
	.FSQRT_V = {
		{.FSQRT_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA1F800, 0xFFFFFC00, .NEON, {}},
		{.FSQRT_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA1F800, 0xFFFFFC00, .NEON, {}},
		{.FSQRT_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EE1F800, 0xFFFFFC00, .NEON, {}},
		{.FSQRT_V, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EF9F800, 0xFFFFFC00, .FP16, {}},
		{.FSQRT_V, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EF9F800, 0xFFFFFC00, .FP16, {}},
	},
	.FRINTA_V = {
		{.FRINTA_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E218800, 0xFFFFFC00, .NEON, {}},
		{.FRINTA_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E218800, 0xFFFFFC00, .NEON, {}},
		{.FRINTA_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E618800, 0xFFFFFC00, .NEON, {}},
		{.FRINTA_V, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E798800, 0xFFFFFC00, .FP16, {}},
		{.FRINTA_V, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E798800, 0xFFFFFC00, .FP16, {}},
	},
	.FRINTI_V = {
		{.FRINTI_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA19800, 0xFFFFFC00, .NEON, {}},
		{.FRINTI_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA19800, 0xFFFFFC00, .NEON, {}},
		{.FRINTI_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EE19800, 0xFFFFFC00, .NEON, {}},
		{.FRINTI_V, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EF99800, 0xFFFFFC00, .FP16, {}},
		{.FRINTI_V, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EF99800, 0xFFFFFC00, .FP16, {}},
	},
	.FRINTM_V = {
		{.FRINTM_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E219800, 0xFFFFFC00, .NEON, {}},
		{.FRINTM_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E219800, 0xFFFFFC00, .NEON, {}},
		{.FRINTM_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E619800, 0xFFFFFC00, .NEON, {}},
		{.FRINTM_V, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E799800, 0xFFFFFC00, .FP16, {}},
		{.FRINTM_V, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E799800, 0xFFFFFC00, .FP16, {}},
	},
	.FRINTN_V = {
		{.FRINTN_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E218800, 0xFFFFFC00, .NEON, {}},
		{.FRINTN_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E218800, 0xFFFFFC00, .NEON, {}},
		{.FRINTN_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E618800, 0xFFFFFC00, .NEON, {}},
		{.FRINTN_V, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E798800, 0xFFFFFC00, .FP16, {}},
		{.FRINTN_V, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E798800, 0xFFFFFC00, .FP16, {}},
	},
	.FRINTP_V = {
		{.FRINTP_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA18800, 0xFFFFFC00, .NEON, {}},
		{.FRINTP_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA18800, 0xFFFFFC00, .NEON, {}},
		{.FRINTP_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EE18800, 0xFFFFFC00, .NEON, {}},
		{.FRINTP_V, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EF98800, 0xFFFFFC00, .FP16, {}},
		{.FRINTP_V, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EF98800, 0xFFFFFC00, .FP16, {}},
	},
	.FRINTX_V = {
		{.FRINTX_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E219800, 0xFFFFFC00, .NEON, {}},
		{.FRINTX_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E219800, 0xFFFFFC00, .NEON, {}},
		{.FRINTX_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E619800, 0xFFFFFC00, .NEON, {}},
		{.FRINTX_V, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E799800, 0xFFFFFC00, .FP16, {}},
		{.FRINTX_V, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E799800, 0xFFFFFC00, .FP16, {}},
	},
	.FRINTZ_V = {
		{.FRINTZ_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA19800, 0xFFFFFC00, .NEON, {}},
		{.FRINTZ_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA19800, 0xFFFFFC00, .NEON, {}},
		{.FRINTZ_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EE19800, 0xFFFFFC00, .NEON, {}},
		{.FRINTZ_V, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EF99800, 0xFFFFFC00, .FP16, {}},
		{.FRINTZ_V, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EF99800, 0xFFFFFC00, .FP16, {}},
	},
	.FRECPE = {
		{.FRECPE, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA1D800, 0xFFFFFC00, .NEON, {}},
		{.FRECPE, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA1D800, 0xFFFFFC00, .NEON, {}},
		{.FRECPE, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EE1D800, 0xFFFFFC00, .NEON, {}},
		{.FRECPE, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EF9D800, 0xFFFFFC00, .FP16, {}},
		{.FRECPE, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EF9D800, 0xFFFFFC00, .FP16, {}},
	},
	.FRSQRTE = {
		{.FRSQRTE, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA1D800, 0xFFFFFC00, .NEON, {}},
		{.FRSQRTE, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA1D800, 0xFFFFFC00, .NEON, {}},
		{.FRSQRTE, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EE1D800, 0xFFFFFC00, .NEON, {}},
		{.FRSQRTE, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EF9D800, 0xFFFFFC00, .FP16, {}},
		{.FRSQRTE, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EF9D800, 0xFFFFFC00, .FP16, {}},
	},

	// Advanced SIMD floating-point convert (vector, register form).
	.FCVTAS_V = {
		{.FCVTAS_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E21C800, 0xFFFFFC00, .NEON, {}},
		{.FCVTAS_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E21C800, 0xFFFFFC00, .NEON, {}},
		{.FCVTAS_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E61C800, 0xFFFFFC00, .NEON, {}},
		{.FCVTAS_V, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E79C800, 0xFFFFFC00, .FP16, {}},
		{.FCVTAS_V, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E79C800, 0xFFFFFC00, .FP16, {}},
	},
	.FCVTAU_V = {
		{.FCVTAU_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E21C800, 0xFFFFFC00, .NEON, {}},
		{.FCVTAU_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E21C800, 0xFFFFFC00, .NEON, {}},
		{.FCVTAU_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E61C800, 0xFFFFFC00, .NEON, {}},
		{.FCVTAU_V, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E79C800, 0xFFFFFC00, .FP16, {}},
		{.FCVTAU_V, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E79C800, 0xFFFFFC00, .FP16, {}},
	},
	.FCVTMS_V = {
		{.FCVTMS_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E21B800, 0xFFFFFC00, .NEON, {}},
		{.FCVTMS_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E21B800, 0xFFFFFC00, .NEON, {}},
		{.FCVTMS_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E61B800, 0xFFFFFC00, .NEON, {}},
		{.FCVTMS_V, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E79B800, 0xFFFFFC00, .FP16, {}},
		{.FCVTMS_V, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E79B800, 0xFFFFFC00, .FP16, {}},
	},
	.FCVTMU_V = {
		{.FCVTMU_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E21B800, 0xFFFFFC00, .NEON, {}},
		{.FCVTMU_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E21B800, 0xFFFFFC00, .NEON, {}},
		{.FCVTMU_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E61B800, 0xFFFFFC00, .NEON, {}},
		{.FCVTMU_V, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E79B800, 0xFFFFFC00, .FP16, {}},
		{.FCVTMU_V, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E79B800, 0xFFFFFC00, .FP16, {}},
	},
	.FCVTNS_V = {
		{.FCVTNS_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E21A800, 0xFFFFFC00, .NEON, {}},
		{.FCVTNS_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E21A800, 0xFFFFFC00, .NEON, {}},
		{.FCVTNS_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E61A800, 0xFFFFFC00, .NEON, {}},
		{.FCVTNS_V, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E79A800, 0xFFFFFC00, .FP16, {}},
		{.FCVTNS_V, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E79A800, 0xFFFFFC00, .FP16, {}},
	},
	.FCVTNU_V = {
		{.FCVTNU_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E21A800, 0xFFFFFC00, .NEON, {}},
		{.FCVTNU_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E21A800, 0xFFFFFC00, .NEON, {}},
		{.FCVTNU_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E61A800, 0xFFFFFC00, .NEON, {}},
		{.FCVTNU_V, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E79A800, 0xFFFFFC00, .FP16, {}},
		{.FCVTNU_V, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E79A800, 0xFFFFFC00, .FP16, {}},
	},
	.FCVTPS_V = {
		{.FCVTPS_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA1A800, 0xFFFFFC00, .NEON, {}},
		{.FCVTPS_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA1A800, 0xFFFFFC00, .NEON, {}},
		{.FCVTPS_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EE1A800, 0xFFFFFC00, .NEON, {}},
		{.FCVTPS_V, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EF9A800, 0xFFFFFC00, .FP16, {}},
		{.FCVTPS_V, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EF9A800, 0xFFFFFC00, .FP16, {}},
	},
	.FCVTPU_V = {
		{.FCVTPU_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA1A800, 0xFFFFFC00, .NEON, {}},
		{.FCVTPU_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA1A800, 0xFFFFFC00, .NEON, {}},
		{.FCVTPU_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EE1A800, 0xFFFFFC00, .NEON, {}},
		{.FCVTPU_V, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EF9A800, 0xFFFFFC00, .FP16, {}},
		{.FCVTPU_V, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EF9A800, 0xFFFFFC00, .FP16, {}},
	},
	.FCVTZS_V = {
		{.FCVTZS_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA1B800, 0xFFFFFC00, .NEON, {}},
		{.FCVTZS_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA1B800, 0xFFFFFC00, .NEON, {}},
		{.FCVTZS_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EE1B800, 0xFFFFFC00, .NEON, {}},
		{.FCVTZS_V, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EF9B800, 0xFFFFFC00, .FP16, {}},
		{.FCVTZS_V, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EF9B800, 0xFFFFFC00, .FP16, {}},
	},
	.FCVTZU_V = {
		{.FCVTZU_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA1B800, 0xFFFFFC00, .NEON, {}},
		{.FCVTZU_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA1B800, 0xFFFFFC00, .NEON, {}},
		{.FCVTZU_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EE1B800, 0xFFFFFC00, .NEON, {}},
		{.FCVTZU_V, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EF9B800, 0xFFFFFC00, .FP16, {}},
		{.FCVTZU_V, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EF9B800, 0xFFFFFC00, .FP16, {}},
	},
	.SCVTF_V = {
		{.SCVTF_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E21D800, 0xFFFFFC00, .NEON, {}},
		{.SCVTF_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E21D800, 0xFFFFFC00, .NEON, {}},
		{.SCVTF_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E61D800, 0xFFFFFC00, .NEON, {}},
		{.SCVTF_V, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E79D800, 0xFFFFFC00, .FP16, {}},
		{.SCVTF_V, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E79D800, 0xFFFFFC00, .FP16, {}},
	},
	.UCVTF_V = {
		{.UCVTF_V, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E21D800, 0xFFFFFC00, .NEON, {}},
		{.UCVTF_V, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E21D800, 0xFFFFFC00, .NEON, {}},
		{.UCVTF_V, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E61D800, 0xFFFFFC00, .NEON, {}},
		{.UCVTF_V, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E79D800, 0xFFFFFC00, .FP16, {}},
		{.UCVTF_V, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E79D800, 0xFFFFFC00, .FP16, {}},
	},

	// Advanced SIMD three-different (long).
	.SADDL = {
		{.SADDL, {.V_8H, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E200000, 0xFFE0FC00, .NEON, {}},
		{.SADDL, {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E600000, 0xFFE0FC00, .NEON, {}},
		{.SADDL, {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA00000, 0xFFE0FC00, .NEON, {}},
	},
	.SADDL2 = {
		{.SADDL2, {.V_8H, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E200000, 0xFFE0FC00, .NEON, {}},
		{.SADDL2, {.V_4S, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E600000, 0xFFE0FC00, .NEON, {}},
		{.SADDL2, {.V_2D, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA00000, 0xFFE0FC00, .NEON, {}},
	},
	.UADDL = {
		{.UADDL, {.V_8H, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E200000, 0xFFE0FC00, .NEON, {}},
		{.UADDL, {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E600000, 0xFFE0FC00, .NEON, {}},
		{.UADDL, {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA00000, 0xFFE0FC00, .NEON, {}},
	},
	.UADDL2 = {
		{.UADDL2, {.V_8H, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E200000, 0xFFE0FC00, .NEON, {}},
		{.UADDL2, {.V_4S, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E600000, 0xFFE0FC00, .NEON, {}},
		{.UADDL2, {.V_2D, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA00000, 0xFFE0FC00, .NEON, {}},
	},
	.SSUBL = {
		{.SSUBL, {.V_8H, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E202000, 0xFFE0FC00, .NEON, {}},
		{.SSUBL, {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E602000, 0xFFE0FC00, .NEON, {}},
		{.SSUBL, {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA02000, 0xFFE0FC00, .NEON, {}},
	},
	.SSUBL2 = {
		{.SSUBL2, {.V_8H, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E202000, 0xFFE0FC00, .NEON, {}},
		{.SSUBL2, {.V_4S, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E602000, 0xFFE0FC00, .NEON, {}},
		{.SSUBL2, {.V_2D, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA02000, 0xFFE0FC00, .NEON, {}},
	},
	.USUBL = {
		{.USUBL, {.V_8H, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E202000, 0xFFE0FC00, .NEON, {}},
		{.USUBL, {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E602000, 0xFFE0FC00, .NEON, {}},
		{.USUBL, {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA02000, 0xFFE0FC00, .NEON, {}},
	},
	.USUBL2 = {
		{.USUBL2, {.V_8H, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E202000, 0xFFE0FC00, .NEON, {}},
		{.USUBL2, {.V_4S, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E602000, 0xFFE0FC00, .NEON, {}},
		{.USUBL2, {.V_2D, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA02000, 0xFFE0FC00, .NEON, {}},
	},
	.SMULL_V = {
		{.SMULL_V, {.V_8H, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E20C000, 0xFFE0FC00, .NEON, {}},
		{.SMULL_V, {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E60C000, 0xFFE0FC00, .NEON, {}},
		{.SMULL_V, {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA0C000, 0xFFE0FC00, .NEON, {}},
	},
	.SMULL2_V = {
		{.SMULL2_V, {.V_8H, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E20C000, 0xFFE0FC00, .NEON, {}},
		{.SMULL2_V, {.V_4S, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60C000, 0xFFE0FC00, .NEON, {}},
		{.SMULL2_V, {.V_2D, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA0C000, 0xFFE0FC00, .NEON, {}},
	},
	.UMULL_V = {
		{.UMULL_V, {.V_8H, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E20C000, 0xFFE0FC00, .NEON, {}},
		{.UMULL_V, {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E60C000, 0xFFE0FC00, .NEON, {}},
		{.UMULL_V, {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA0C000, 0xFFE0FC00, .NEON, {}},
	},
	.UMULL2_V = {
		{.UMULL2_V, {.V_8H, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E20C000, 0xFFE0FC00, .NEON, {}},
		{.UMULL2_V, {.V_4S, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E60C000, 0xFFE0FC00, .NEON, {}},
		{.UMULL2_V, {.V_2D, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA0C000, 0xFFE0FC00, .NEON, {}},
	},
	.SMLAL = {
		{.SMLAL, {.V_8H, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E208000, 0xFFE0FC00, .NEON, {}},
		{.SMLAL, {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E608000, 0xFFE0FC00, .NEON, {}},
		{.SMLAL, {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA08000, 0xFFE0FC00, .NEON, {}},
	},
	.SMLAL2 = {
		{.SMLAL2, {.V_8H, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E208000, 0xFFE0FC00, .NEON, {}},
		{.SMLAL2, {.V_4S, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E608000, 0xFFE0FC00, .NEON, {}},
		{.SMLAL2, {.V_2D, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA08000, 0xFFE0FC00, .NEON, {}},
	},
	.UMLAL = {
		{.UMLAL, {.V_8H, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E208000, 0xFFE0FC00, .NEON, {}},
		{.UMLAL, {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E608000, 0xFFE0FC00, .NEON, {}},
		{.UMLAL, {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA08000, 0xFFE0FC00, .NEON, {}},
	},
	.UMLAL2 = {
		{.UMLAL2, {.V_8H, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E208000, 0xFFE0FC00, .NEON, {}},
		{.UMLAL2, {.V_4S, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E608000, 0xFFE0FC00, .NEON, {}},
		{.UMLAL2, {.V_2D, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA08000, 0xFFE0FC00, .NEON, {}},
	},
	.SMLSL = {
		{.SMLSL, {.V_8H, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E20A000, 0xFFE0FC00, .NEON, {}},
		{.SMLSL, {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E60A000, 0xFFE0FC00, .NEON, {}},
		{.SMLSL, {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA0A000, 0xFFE0FC00, .NEON, {}},
	},
	.SMLSL2 = {
		{.SMLSL2, {.V_8H, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E20A000, 0xFFE0FC00, .NEON, {}},
		{.SMLSL2, {.V_4S, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60A000, 0xFFE0FC00, .NEON, {}},
		{.SMLSL2, {.V_2D, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA0A000, 0xFFE0FC00, .NEON, {}},
	},
	.UMLSL = {
		{.UMLSL, {.V_8H, .V_8B, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E20A000, 0xFFE0FC00, .NEON, {}},
		{.UMLSL, {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E60A000, 0xFFE0FC00, .NEON, {}},
		{.UMLSL, {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA0A000, 0xFFE0FC00, .NEON, {}},
	},
	.UMLSL2 = {
		{.UMLSL2, {.V_8H, .V_16B, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E20A000, 0xFFE0FC00, .NEON, {}},
		{.UMLSL2, {.V_4S, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E60A000, 0xFFE0FC00, .NEON, {}},
		{.UMLSL2, {.V_2D, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA0A000, 0xFFE0FC00, .NEON, {}},
	},
	.SQDMULL = {
		{.SQDMULL, {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E60D000, 0xFFE0FC00, .NEON, {}},
		{.SQDMULL, {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA0D000, 0xFFE0FC00, .NEON, {}},
	},
	.SQDMULL2 = {
		{.SQDMULL2, {.V_4S, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60D000, 0xFFE0FC00, .NEON, {}},
		{.SQDMULL2, {.V_2D, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA0D000, 0xFFE0FC00, .NEON, {}},
	},
	.SQDMLAL = {
		{.SQDMLAL, {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E609000, 0xFFE0FC00, .NEON, {}},
		{.SQDMLAL, {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA09000, 0xFFE0FC00, .NEON, {}},
	},
	.SQDMLAL2 = {
		{.SQDMLAL2, {.V_4S, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E609000, 0xFFE0FC00, .NEON, {}},
		{.SQDMLAL2, {.V_2D, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA09000, 0xFFE0FC00, .NEON, {}},
	},
	.SQDMLSL = {
		{.SQDMLSL, {.V_4S, .V_4H, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E60B000, 0xFFE0FC00, .NEON, {}},
		{.SQDMLSL, {.V_2D, .V_2S, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA0B000, 0xFFE0FC00, .NEON, {}},
	},
	.SQDMLSL2 = {
		{.SQDMLSL2, {.V_4S, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E60B000, 0xFFE0FC00, .NEON, {}},
		{.SQDMLSL2, {.V_2D, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA0B000, 0xFFE0FC00, .NEON, {}},
	},

	// Advanced SIMD three-different (wide).
	.SADDW = {
		{.SADDW, {.V_8H, .V_8H, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E201000, 0xFFE0FC00, .NEON, {}},
		{.SADDW, {.V_4S, .V_4S, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E601000, 0xFFE0FC00, .NEON, {}},
		{.SADDW, {.V_2D, .V_2D, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA01000, 0xFFE0FC00, .NEON, {}},
	},
	.SADDW2 = {
		{.SADDW2, {.V_8H, .V_8H, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E201000, 0xFFE0FC00, .NEON, {}},
		{.SADDW2, {.V_4S, .V_4S, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E601000, 0xFFE0FC00, .NEON, {}},
		{.SADDW2, {.V_2D, .V_2D, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA01000, 0xFFE0FC00, .NEON, {}},
	},
	.UADDW = {
		{.UADDW, {.V_8H, .V_8H, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E201000, 0xFFE0FC00, .NEON, {}},
		{.UADDW, {.V_4S, .V_4S, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E601000, 0xFFE0FC00, .NEON, {}},
		{.UADDW, {.V_2D, .V_2D, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA01000, 0xFFE0FC00, .NEON, {}},
	},
	.UADDW2 = {
		{.UADDW2, {.V_8H, .V_8H, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E201000, 0xFFE0FC00, .NEON, {}},
		{.UADDW2, {.V_4S, .V_4S, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E601000, 0xFFE0FC00, .NEON, {}},
		{.UADDW2, {.V_2D, .V_2D, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA01000, 0xFFE0FC00, .NEON, {}},
	},
	.SSUBW = {
		{.SSUBW, {.V_8H, .V_8H, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E203000, 0xFFE0FC00, .NEON, {}},
		{.SSUBW, {.V_4S, .V_4S, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E603000, 0xFFE0FC00, .NEON, {}},
		{.SSUBW, {.V_2D, .V_2D, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA03000, 0xFFE0FC00, .NEON, {}},
	},
	.SSUBW2 = {
		{.SSUBW2, {.V_8H, .V_8H, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E203000, 0xFFE0FC00, .NEON, {}},
		{.SSUBW2, {.V_4S, .V_4S, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E603000, 0xFFE0FC00, .NEON, {}},
		{.SSUBW2, {.V_2D, .V_2D, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA03000, 0xFFE0FC00, .NEON, {}},
	},
	.USUBW = {
		{.USUBW, {.V_8H, .V_8H, .V_8B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E203000, 0xFFE0FC00, .NEON, {}},
		{.USUBW, {.V_4S, .V_4S, .V_4H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E603000, 0xFFE0FC00, .NEON, {}},
		{.USUBW, {.V_2D, .V_2D, .V_2S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA03000, 0xFFE0FC00, .NEON, {}},
	},
	.USUBW2 = {
		{.USUBW2, {.V_8H, .V_8H, .V_16B, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E203000, 0xFFE0FC00, .NEON, {}},
		{.USUBW2, {.V_4S, .V_4S, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E603000, 0xFFE0FC00, .NEON, {}},
		{.USUBW2, {.V_2D, .V_2D, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA03000, 0xFFE0FC00, .NEON, {}},
	},

	// Advanced SIMD three-different (narrow, halving).
	.ADDHN = {
		{.ADDHN, {.V_8B, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E204000, 0xFFE0FC00, .NEON, {}},
		{.ADDHN, {.V_4H, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E604000, 0xFFE0FC00, .NEON, {}},
		{.ADDHN, {.V_2S, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA04000, 0xFFE0FC00, .NEON, {}},
	},
	.ADDHN2 = {
		{.ADDHN2, {.V_16B, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E204000, 0xFFE0FC00, .NEON, {}},
		{.ADDHN2, {.V_8H, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E604000, 0xFFE0FC00, .NEON, {}},
		{.ADDHN2, {.V_4S, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA04000, 0xFFE0FC00, .NEON, {}},
	},
	.SUBHN = {
		{.SUBHN, {.V_8B, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E206000, 0xFFE0FC00, .NEON, {}},
		{.SUBHN, {.V_4H, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0E606000, 0xFFE0FC00, .NEON, {}},
		{.SUBHN, {.V_2S, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x0EA06000, 0xFFE0FC00, .NEON, {}},
	},
	.SUBHN2 = {
		{.SUBHN2, {.V_16B, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E206000, 0xFFE0FC00, .NEON, {}},
		{.SUBHN2, {.V_8H, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4E606000, 0xFFE0FC00, .NEON, {}},
		{.SUBHN2, {.V_4S, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x4EA06000, 0xFFE0FC00, .NEON, {}},
	},
	.RADDHN = {
		{.RADDHN, {.V_8B, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E204000, 0xFFE0FC00, .NEON, {}},
		{.RADDHN, {.V_4H, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E604000, 0xFFE0FC00, .NEON, {}},
		{.RADDHN, {.V_2S, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA04000, 0xFFE0FC00, .NEON, {}},
	},
	.RADDHN2 = {
		{.RADDHN2, {.V_16B, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E204000, 0xFFE0FC00, .NEON, {}},
		{.RADDHN2, {.V_8H, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E604000, 0xFFE0FC00, .NEON, {}},
		{.RADDHN2, {.V_4S, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA04000, 0xFFE0FC00, .NEON, {}},
	},
	.RSUBHN = {
		{.RSUBHN, {.V_8B, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E206000, 0xFFE0FC00, .NEON, {}},
		{.RSUBHN, {.V_4H, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2E606000, 0xFFE0FC00, .NEON, {}},
		{.RSUBHN, {.V_2S, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x2EA06000, 0xFFE0FC00, .NEON, {}},
	},
	.RSUBHN2 = {
		{.RSUBHN2, {.V_16B, .V_8H, .V_8H, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E206000, 0xFFE0FC00, .NEON, {}},
		{.RSUBHN2, {.V_8H, .V_4S, .V_4S, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6E606000, 0xFFE0FC00, .NEON, {}},
		{.RSUBHN2, {.V_4S, .V_2D, .V_2D, .NONE}, {.VD, .VN, .VM, .NONE}, 0x6EA06000, 0xFFE0FC00, .NEON, {}},
	},

	// Advanced SIMD two-register narrowing (XTN).
	.XTN = {
		{.XTN, {.V_8B, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E212800, 0xFFFFFC00, .NEON, {}},
		{.XTN, {.V_4H, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E612800, 0xFFFFFC00, .NEON, {}},
		{.XTN, {.V_2S, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA12800, 0xFFFFFC00, .NEON, {}},
	},
	.XTN2 = {
		{.XTN2, {.V_16B, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E212800, 0xFFFFFC00, .NEON, {}},
		{.XTN2, {.V_8H, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E612800, 0xFFFFFC00, .NEON, {}},
		{.XTN2, {.V_4S, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA12800, 0xFFFFFC00, .NEON, {}},
	},
	.SQXTN = {
		{.SQXTN, {.V_8B, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E214800, 0xFFFFFC00, .NEON, {}},
		{.SQXTN, {.V_4H, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E614800, 0xFFFFFC00, .NEON, {}},
		{.SQXTN, {.V_2S, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA14800, 0xFFFFFC00, .NEON, {}},
	},
	.SQXTN2 = {
		{.SQXTN2, {.V_16B, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E214800, 0xFFFFFC00, .NEON, {}},
		{.SQXTN2, {.V_8H, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E614800, 0xFFFFFC00, .NEON, {}},
		{.SQXTN2, {.V_4S, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA14800, 0xFFFFFC00, .NEON, {}},
	},
	.UQXTN = {
		{.UQXTN, {.V_8B, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E214800, 0xFFFFFC00, .NEON, {}},
		{.UQXTN, {.V_4H, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E614800, 0xFFFFFC00, .NEON, {}},
		{.UQXTN, {.V_2S, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA14800, 0xFFFFFC00, .NEON, {}},
	},
	.UQXTN2 = {
		{.UQXTN2, {.V_16B, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E214800, 0xFFFFFC00, .NEON, {}},
		{.UQXTN2, {.V_8H, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E614800, 0xFFFFFC00, .NEON, {}},
		{.UQXTN2, {.V_4S, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA14800, 0xFFFFFC00, .NEON, {}},
	},
	.SQXTUN = {
		{.SQXTUN, {.V_8B, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E212800, 0xFFFFFC00, .NEON, {}},
		{.SQXTUN, {.V_4H, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E612800, 0xFFFFFC00, .NEON, {}},
		{.SQXTUN, {.V_2S, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA12800, 0xFFFFFC00, .NEON, {}},
	},
	.SQXTUN2 = {
		{.SQXTUN2, {.V_16B, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E212800, 0xFFFFFC00, .NEON, {}},
		{.SQXTUN2, {.V_8H, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E612800, 0xFFFFFC00, .NEON, {}},
		{.SQXTUN2, {.V_4S, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA12800, 0xFFFFFC00, .NEON, {}},
	},

	// Advanced SIMD two-register widen (SXTL/UXTL = SSHLL/USHLL #0).
	.SXTL = {
		{.SXTL, {.V_8H, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0F08A400, 0xFFFFFC00, .NEON, {}},
		{.SXTL, {.V_4S, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0F10A400, 0xFFFFFC00, .NEON, {}},
		{.SXTL, {.V_2D, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0F20A400, 0xFFFFFC00, .NEON, {}},
	},
	.SXTL2 = {
		{.SXTL2, {.V_8H, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4F08A400, 0xFFFFFC00, .NEON, {}},
		{.SXTL2, {.V_4S, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4F10A400, 0xFFFFFC00, .NEON, {}},
		{.SXTL2, {.V_2D, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4F20A400, 0xFFFFFC00, .NEON, {}},
	},
	.UXTL = {
		{.UXTL, {.V_8H, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2F08A400, 0xFFFFFC00, .NEON, {}},
		{.UXTL, {.V_4S, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2F10A400, 0xFFFFFC00, .NEON, {}},
		{.UXTL, {.V_2D, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2F20A400, 0xFFFFFC00, .NEON, {}},
	},
	.UXTL2 = {
		{.UXTL2, {.V_8H, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6F08A400, 0xFFFFFC00, .NEON, {}},
		{.UXTL2, {.V_4S, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6F10A400, 0xFFFFFC00, .NEON, {}},
		{.UXTL2, {.V_2D, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6F20A400, 0xFFFFFC00, .NEON, {}},
	},

	// Advanced SIMD two-register pairwise long.
	.SADDLP = {
		{.SADDLP, {.V_4H, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E202800, 0xFFFFFC00, .NEON, {}},
		{.SADDLP, {.V_8H, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E202800, 0xFFFFFC00, .NEON, {}},
		{.SADDLP, {.V_2S, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E602800, 0xFFFFFC00, .NEON, {}},
		{.SADDLP, {.V_4S, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E602800, 0xFFFFFC00, .NEON, {}},
		{.SADDLP, {.V_1D, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA02800, 0xFFFFFC00, .NEON, {}},
		{.SADDLP, {.V_2D, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA02800, 0xFFFFFC00, .NEON, {}},
	},
	.UADDLP = {
		{.UADDLP, {.V_4H, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E202800, 0xFFFFFC00, .NEON, {}},
		{.UADDLP, {.V_8H, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E202800, 0xFFFFFC00, .NEON, {}},
		{.UADDLP, {.V_2S, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E602800, 0xFFFFFC00, .NEON, {}},
		{.UADDLP, {.V_4S, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E602800, 0xFFFFFC00, .NEON, {}},
		{.UADDLP, {.V_1D, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA02800, 0xFFFFFC00, .NEON, {}},
		{.UADDLP, {.V_2D, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA02800, 0xFFFFFC00, .NEON, {}},
	},
	.SADALP = {
		{.SADALP, {.V_4H, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E206800, 0xFFFFFC00, .NEON, {}},
		{.SADALP, {.V_8H, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E206800, 0xFFFFFC00, .NEON, {}},
		{.SADALP, {.V_2S, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E606800, 0xFFFFFC00, .NEON, {}},
		{.SADALP, {.V_4S, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E606800, 0xFFFFFC00, .NEON, {}},
		{.SADALP, {.V_1D, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA06800, 0xFFFFFC00, .NEON, {}},
		{.SADALP, {.V_2D, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA06800, 0xFFFFFC00, .NEON, {}},
	},
	.UADALP = {
		{.UADALP, {.V_4H, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E206800, 0xFFFFFC00, .NEON, {}},
		{.UADALP, {.V_8H, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E206800, 0xFFFFFC00, .NEON, {}},
		{.UADALP, {.V_2S, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E606800, 0xFFFFFC00, .NEON, {}},
		{.UADALP, {.V_4S, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E606800, 0xFFFFFC00, .NEON, {}},
		{.UADALP, {.V_1D, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA06800, 0xFFFFFC00, .NEON, {}},
		{.UADALP, {.V_2D, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA06800, 0xFFFFFC00, .NEON, {}},
	},

	// Advanced SIMD across lanes.
	.ADDV = {
		{.ADDV, {.B_REG, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E31B800, 0xFFFFFC00, .NEON, {}},
		{.ADDV, {.B_REG, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E31B800, 0xFFFFFC00, .NEON, {}},
		{.ADDV, {.H_REG, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E71B800, 0xFFFFFC00, .NEON, {}},
		{.ADDV, {.H_REG, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E71B800, 0xFFFFFC00, .NEON, {}},
		{.ADDV, {.S_REG, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EB1B800, 0xFFFFFC00, .NEON, {}},
	},
	.SMAXV = {
		{.SMAXV, {.B_REG, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E30A800, 0xFFFFFC00, .NEON, {}},
		{.SMAXV, {.B_REG, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E30A800, 0xFFFFFC00, .NEON, {}},
		{.SMAXV, {.H_REG, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E70A800, 0xFFFFFC00, .NEON, {}},
		{.SMAXV, {.H_REG, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E70A800, 0xFFFFFC00, .NEON, {}},
		{.SMAXV, {.S_REG, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EB0A800, 0xFFFFFC00, .NEON, {}},
	},
	.SMINV = {
		{.SMINV, {.B_REG, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E31A800, 0xFFFFFC00, .NEON, {}},
		{.SMINV, {.B_REG, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E31A800, 0xFFFFFC00, .NEON, {}},
		{.SMINV, {.H_REG, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E71A800, 0xFFFFFC00, .NEON, {}},
		{.SMINV, {.H_REG, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E71A800, 0xFFFFFC00, .NEON, {}},
		{.SMINV, {.S_REG, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EB1A800, 0xFFFFFC00, .NEON, {}},
	},
	.UMAXV = {
		{.UMAXV, {.B_REG, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E30A800, 0xFFFFFC00, .NEON, {}},
		{.UMAXV, {.B_REG, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E30A800, 0xFFFFFC00, .NEON, {}},
		{.UMAXV, {.H_REG, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E70A800, 0xFFFFFC00, .NEON, {}},
		{.UMAXV, {.H_REG, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E70A800, 0xFFFFFC00, .NEON, {}},
		{.UMAXV, {.S_REG, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EB0A800, 0xFFFFFC00, .NEON, {}},
	},
	.UMINV = {
		{.UMINV, {.B_REG, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E31A800, 0xFFFFFC00, .NEON, {}},
		{.UMINV, {.B_REG, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E31A800, 0xFFFFFC00, .NEON, {}},
		{.UMINV, {.H_REG, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E71A800, 0xFFFFFC00, .NEON, {}},
		{.UMINV, {.H_REG, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E71A800, 0xFFFFFC00, .NEON, {}},
		{.UMINV, {.S_REG, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EB1A800, 0xFFFFFC00, .NEON, {}},
	},
	.SADDLV = {
		{.SADDLV, {.H_REG, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E303800, 0xFFFFFC00, .NEON, {}},
		{.SADDLV, {.H_REG, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E303800, 0xFFFFFC00, .NEON, {}},
		{.SADDLV, {.S_REG, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E703800, 0xFFFFFC00, .NEON, {}},
		{.SADDLV, {.S_REG, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E703800, 0xFFFFFC00, .NEON, {}},
		{.SADDLV, {.D_REG, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EB03800, 0xFFFFFC00, .NEON, {}},
	},
	.UADDLV = {
		{.UADDLV, {.H_REG, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E303800, 0xFFFFFC00, .NEON, {}},
		{.UADDLV, {.H_REG, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E303800, 0xFFFFFC00, .NEON, {}},
		{.UADDLV, {.S_REG, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E703800, 0xFFFFFC00, .NEON, {}},
		{.UADDLV, {.S_REG, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E703800, 0xFFFFFC00, .NEON, {}},
		{.UADDLV, {.D_REG, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EB03800, 0xFFFFFC00, .NEON, {}},
	},

	// Advanced SIMD floating-point across lanes.
	.FMAXV_V = {
		{.FMAXV_V, {.S_REG, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E30F800, 0xFFFFFC00, .NEON, {}},
		{.FMAXV_V, {.H_REG, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E30F800, 0xFFFFFC00, .FP16, {}},
		{.FMAXV_V, {.H_REG, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E30F800, 0xFFFFFC00, .FP16, {}},
	},
	.FMINV_V = {
		{.FMINV_V, {.S_REG, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EB0F800, 0xFFFFFC00, .NEON, {}},
		{.FMINV_V, {.H_REG, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EB0F800, 0xFFFFFC00, .FP16, {}},
		{.FMINV_V, {.H_REG, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EB0F800, 0xFFFFFC00, .FP16, {}},
	},
	.FMAXNMV = {
		{.FMAXNMV, {.S_REG, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E30C800, 0xFFFFFC00, .NEON, {}},
		{.FMAXNMV, {.H_REG, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E30C800, 0xFFFFFC00, .FP16, {}},
		{.FMAXNMV, {.H_REG, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E30C800, 0xFFFFFC00, .FP16, {}},
	},
	.FMINNMV = {
		{.FMINNMV, {.S_REG, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EB0C800, 0xFFFFFC00, .NEON, {}},
		{.FMINNMV, {.H_REG, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EB0C800, 0xFFFFFC00, .FP16, {}},
		{.FMINNMV, {.H_REG, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EB0C800, 0xFFFFFC00, .FP16, {}},
	},

	// Advanced SIMD floating-point widen / narrow.
	.FCVTL = {
		{.FCVTL, {.V_4S, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E217800, 0xFFFFFC00, .FP16, {}},
		{.FCVTL, {.V_2D, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E617800, 0xFFFFFC00, .NEON, {}},
	},
	.FCVTL2 = {
		{.FCVTL2, {.V_4S, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E217800, 0xFFFFFC00, .FP16, {}},
		{.FCVTL2, {.V_2D, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E617800, 0xFFFFFC00, .NEON, {}},
	},
	.FCVTN = {
		{.FCVTN, {.V_4H_FP16, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E216800, 0xFFFFFC00, .FP16, {}},
		{.FCVTN, {.V_2S, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E616800, 0xFFFFFC00, .NEON, {}},
	},
	.FCVTN2 = {
		{.FCVTN2, {.V_8H_FP16, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E216800, 0xFFFFFC00, .FP16, {}},
		{.FCVTN2, {.V_4S, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E616800, 0xFFFFFC00, .NEON, {}},
	},
	.FCVTXN = {
		{.FCVTXN, {.V_2S, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E616800, 0xFFFFFC00, .NEON, {}},
	},
	.FCVTXN2 = {
		{.FCVTXN2, {.V_4S, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E616800, 0xFFFFFC00, .NEON, {}},
	},

	// Advanced SIMD compare against zero.
	.CMLE = {
		{.CMLE, {.V_8B, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E209800, 0xFFFFFC00, .NEON, {}},
		{.CMLE, {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E209800, 0xFFFFFC00, .NEON, {}},
		{.CMLE, {.V_4H, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E609800, 0xFFFFFC00, .NEON, {}},
		{.CMLE, {.V_8H, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E609800, 0xFFFFFC00, .NEON, {}},
		{.CMLE, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA09800, 0xFFFFFC00, .NEON, {}},
		{.CMLE, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA09800, 0xFFFFFC00, .NEON, {}},
		{.CMLE, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EE09800, 0xFFFFFC00, .NEON, {}},
	},
	.CMLT = {
		{.CMLT, {.V_8B, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E20A800, 0xFFFFFC00, .NEON, {}},
		{.CMLT, {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E20A800, 0xFFFFFC00, .NEON, {}},
		{.CMLT, {.V_4H, .V_4H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0E60A800, 0xFFFFFC00, .NEON, {}},
		{.CMLT, {.V_8H, .V_8H, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4E60A800, 0xFFFFFC00, .NEON, {}},
		{.CMLT, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA0A800, 0xFFFFFC00, .NEON, {}},
		{.CMLT, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA0A800, 0xFFFFFC00, .NEON, {}},
		{.CMLT, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EE0A800, 0xFFFFFC00, .NEON, {}},
	},
	.FCMLE = {
		{.FCMLE, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EA0D800, 0xFFFFFC00, .NEON, {}},
		{.FCMLE, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EA0D800, 0xFFFFFC00, .NEON, {}},
		{.FCMLE, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EE0D800, 0xFFFFFC00, .NEON, {}},
		{.FCMLE, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2EF8D800, 0xFFFFFC00, .FP16, {}},
		{.FCMLE, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6EF8D800, 0xFFFFFC00, .FP16, {}},
	},
	.FCMLT = {
		{.FCMLT, {.V_2S, .V_2S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EA0E800, 0xFFFFFC00, .NEON, {}},
		{.FCMLT, {.V_4S, .V_4S, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EA0E800, 0xFFFFFC00, .NEON, {}},
		{.FCMLT, {.V_2D, .V_2D, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EE0E800, 0xFFFFFC00, .NEON, {}},
		{.FCMLT, {.V_4H_FP16, .V_4H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x0EF8E800, 0xFFFFFC00, .FP16, {}},
		{.FCMLT, {.V_8H_FP16, .V_8H_FP16, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x4EF8E800, 0xFFFFFC00, .FP16, {}},
	},

	// Advanced SIMD shift by immediate.
	.SHL_V = {
		{.SHL_V, {.V_8B, .V_8B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x0F085400, 0xFFF8FC00, .NEON, {}},
		{.SHL_V, {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x4F085400, 0xFFF8FC00, .NEON, {}},
		{.SHL_V, {.V_4H, .V_4H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x0F105400, 0xFFF0FC00, .NEON, {}},
		{.SHL_V, {.V_8H, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x4F105400, 0xFFF0FC00, .NEON, {}},
		{.SHL_V, {.V_2S, .V_2S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x0F205400, 0xFFE0FC00, .NEON, {}},
		{.SHL_V, {.V_4S, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x4F205400, 0xFFE0FC00, .NEON, {}},
		{.SHL_V, {.V_2D, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x4F405400, 0xFFC0FC00, .NEON, {}},
	},
	.SLI = {
		{.SLI, {.V_8B, .V_8B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x2F085400, 0xFFF8FC00, .NEON, {}},
		{.SLI, {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x6F085400, 0xFFF8FC00, .NEON, {}},
		{.SLI, {.V_4H, .V_4H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x2F105400, 0xFFF0FC00, .NEON, {}},
		{.SLI, {.V_8H, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x6F105400, 0xFFF0FC00, .NEON, {}},
		{.SLI, {.V_2S, .V_2S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x2F205400, 0xFFE0FC00, .NEON, {}},
		{.SLI, {.V_4S, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x6F205400, 0xFFE0FC00, .NEON, {}},
		{.SLI, {.V_2D, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x6F405400, 0xFFC0FC00, .NEON, {}},
	},
	.SQSHLU = {
		{.SQSHLU, {.V_8B, .V_8B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x2F086400, 0xFFF8FC00, .NEON, {}},
		{.SQSHLU, {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x6F086400, 0xFFF8FC00, .NEON, {}},
		{.SQSHLU, {.V_4H, .V_4H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x2F106400, 0xFFF0FC00, .NEON, {}},
		{.SQSHLU, {.V_8H, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x6F106400, 0xFFF0FC00, .NEON, {}},
		{.SQSHLU, {.V_2S, .V_2S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x2F206400, 0xFFE0FC00, .NEON, {}},
		{.SQSHLU, {.V_4S, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x6F206400, 0xFFE0FC00, .NEON, {}},
		{.SQSHLU, {.V_2D, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x6F406400, 0xFFC0FC00, .NEON, {}},
	},
	.SQSHL_V = {
		{.SQSHL_V, {.V_8B, .V_8B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x0F087400, 0xFFF8FC00, .NEON, {}},
		{.SQSHL_V, {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x4F087400, 0xFFF8FC00, .NEON, {}},
		{.SQSHL_V, {.V_4H, .V_4H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x0F107400, 0xFFF0FC00, .NEON, {}},
		{.SQSHL_V, {.V_8H, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x4F107400, 0xFFF0FC00, .NEON, {}},
		{.SQSHL_V, {.V_2S, .V_2S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x0F207400, 0xFFE0FC00, .NEON, {}},
		{.SQSHL_V, {.V_4S, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x4F207400, 0xFFE0FC00, .NEON, {}},
		{.SQSHL_V, {.V_2D, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x4F407400, 0xFFC0FC00, .NEON, {}},
	},
	.SSHR = {
		{.SSHR, {.V_8B, .V_8B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F080400, 0xFFF8FC00, .NEON, {}},
		{.SSHR, {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F080400, 0xFFF8FC00, .NEON, {}},
		{.SSHR, {.V_4H, .V_4H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F100400, 0xFFF0FC00, .NEON, {}},
		{.SSHR, {.V_8H, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F100400, 0xFFF0FC00, .NEON, {}},
		{.SSHR, {.V_2S, .V_2S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F200400, 0xFFE0FC00, .NEON, {}},
		{.SSHR, {.V_4S, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F200400, 0xFFE0FC00, .NEON, {}},
		{.SSHR, {.V_2D, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F400400, 0xFFC0FC00, .NEON, {}},
	},
	.USHR = {
		{.USHR, {.V_8B, .V_8B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F080400, 0xFFF8FC00, .NEON, {}},
		{.USHR, {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F080400, 0xFFF8FC00, .NEON, {}},
		{.USHR, {.V_4H, .V_4H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F100400, 0xFFF0FC00, .NEON, {}},
		{.USHR, {.V_8H, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F100400, 0xFFF0FC00, .NEON, {}},
		{.USHR, {.V_2S, .V_2S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F200400, 0xFFE0FC00, .NEON, {}},
		{.USHR, {.V_4S, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F200400, 0xFFE0FC00, .NEON, {}},
		{.USHR, {.V_2D, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F400400, 0xFFC0FC00, .NEON, {}},
	},
	.SRSHR = {
		{.SRSHR, {.V_8B, .V_8B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F082400, 0xFFF8FC00, .NEON, {}},
		{.SRSHR, {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F082400, 0xFFF8FC00, .NEON, {}},
		{.SRSHR, {.V_4H, .V_4H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F102400, 0xFFF0FC00, .NEON, {}},
		{.SRSHR, {.V_8H, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F102400, 0xFFF0FC00, .NEON, {}},
		{.SRSHR, {.V_2S, .V_2S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F202400, 0xFFE0FC00, .NEON, {}},
		{.SRSHR, {.V_4S, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F202400, 0xFFE0FC00, .NEON, {}},
		{.SRSHR, {.V_2D, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F402400, 0xFFC0FC00, .NEON, {}},
	},
	.URSHR = {
		{.URSHR, {.V_8B, .V_8B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F082400, 0xFFF8FC00, .NEON, {}},
		{.URSHR, {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F082400, 0xFFF8FC00, .NEON, {}},
		{.URSHR, {.V_4H, .V_4H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F102400, 0xFFF0FC00, .NEON, {}},
		{.URSHR, {.V_8H, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F102400, 0xFFF0FC00, .NEON, {}},
		{.URSHR, {.V_2S, .V_2S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F202400, 0xFFE0FC00, .NEON, {}},
		{.URSHR, {.V_4S, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F202400, 0xFFE0FC00, .NEON, {}},
		{.URSHR, {.V_2D, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F402400, 0xFFC0FC00, .NEON, {}},
	},
	.SSRA = {
		{.SSRA, {.V_8B, .V_8B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F081400, 0xFFF8FC00, .NEON, {}},
		{.SSRA, {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F081400, 0xFFF8FC00, .NEON, {}},
		{.SSRA, {.V_4H, .V_4H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F101400, 0xFFF0FC00, .NEON, {}},
		{.SSRA, {.V_8H, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F101400, 0xFFF0FC00, .NEON, {}},
		{.SSRA, {.V_2S, .V_2S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F201400, 0xFFE0FC00, .NEON, {}},
		{.SSRA, {.V_4S, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F201400, 0xFFE0FC00, .NEON, {}},
		{.SSRA, {.V_2D, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F401400, 0xFFC0FC00, .NEON, {}},
	},
	.USRA = {
		{.USRA, {.V_8B, .V_8B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F081400, 0xFFF8FC00, .NEON, {}},
		{.USRA, {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F081400, 0xFFF8FC00, .NEON, {}},
		{.USRA, {.V_4H, .V_4H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F101400, 0xFFF0FC00, .NEON, {}},
		{.USRA, {.V_8H, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F101400, 0xFFF0FC00, .NEON, {}},
		{.USRA, {.V_2S, .V_2S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F201400, 0xFFE0FC00, .NEON, {}},
		{.USRA, {.V_4S, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F201400, 0xFFE0FC00, .NEON, {}},
		{.USRA, {.V_2D, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F401400, 0xFFC0FC00, .NEON, {}},
	},
	.SRSRA = {
		{.SRSRA, {.V_8B, .V_8B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F083400, 0xFFF8FC00, .NEON, {}},
		{.SRSRA, {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F083400, 0xFFF8FC00, .NEON, {}},
		{.SRSRA, {.V_4H, .V_4H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F103400, 0xFFF0FC00, .NEON, {}},
		{.SRSRA, {.V_8H, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F103400, 0xFFF0FC00, .NEON, {}},
		{.SRSRA, {.V_2S, .V_2S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F203400, 0xFFE0FC00, .NEON, {}},
		{.SRSRA, {.V_4S, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F203400, 0xFFE0FC00, .NEON, {}},
		{.SRSRA, {.V_2D, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F403400, 0xFFC0FC00, .NEON, {}},
	},
	.URSRA = {
		{.URSRA, {.V_8B, .V_8B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F083400, 0xFFF8FC00, .NEON, {}},
		{.URSRA, {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F083400, 0xFFF8FC00, .NEON, {}},
		{.URSRA, {.V_4H, .V_4H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F103400, 0xFFF0FC00, .NEON, {}},
		{.URSRA, {.V_8H, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F103400, 0xFFF0FC00, .NEON, {}},
		{.URSRA, {.V_2S, .V_2S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F203400, 0xFFE0FC00, .NEON, {}},
		{.URSRA, {.V_4S, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F203400, 0xFFE0FC00, .NEON, {}},
		{.URSRA, {.V_2D, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F403400, 0xFFC0FC00, .NEON, {}},
	},
	.SRI = {
		{.SRI, {.V_8B, .V_8B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F084400, 0xFFF8FC00, .NEON, {}},
		{.SRI, {.V_16B, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F084400, 0xFFF8FC00, .NEON, {}},
		{.SRI, {.V_4H, .V_4H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F104400, 0xFFF0FC00, .NEON, {}},
		{.SRI, {.V_8H, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F104400, 0xFFF0FC00, .NEON, {}},
		{.SRI, {.V_2S, .V_2S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F204400, 0xFFE0FC00, .NEON, {}},
		{.SRI, {.V_4S, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F204400, 0xFFE0FC00, .NEON, {}},
		{.SRI, {.V_2D, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F404400, 0xFFC0FC00, .NEON, {}},
	},
	.SSHLL = {
		{.SSHLL, {.V_8H, .V_8B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x0F08A400, 0xFFF8FC00, .NEON, {}},
		{.SSHLL, {.V_4S, .V_4H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x0F10A400, 0xFFF0FC00, .NEON, {}},
		{.SSHLL, {.V_2D, .V_2S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x0F20A400, 0xFFE0FC00, .NEON, {}},
	},
	.SSHLL2 = {
		{.SSHLL2, {.V_8H, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x4F08A400, 0xFFF8FC00, .NEON, {}},
		{.SSHLL2, {.V_4S, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x4F10A400, 0xFFF0FC00, .NEON, {}},
		{.SSHLL2, {.V_2D, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x4F20A400, 0xFFE0FC00, .NEON, {}},
	},
	.USHLL = {
		{.USHLL, {.V_8H, .V_8B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x2F08A400, 0xFFF8FC00, .NEON, {}},
		{.USHLL, {.V_4S, .V_4H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x2F10A400, 0xFFF0FC00, .NEON, {}},
		{.USHLL, {.V_2D, .V_2S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x2F20A400, 0xFFE0FC00, .NEON, {}},
	},
	.USHLL2 = {
		{.USHLL2, {.V_8H, .V_16B, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x6F08A400, 0xFFF8FC00, .NEON, {}},
		{.USHLL2, {.V_4S, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x6F10A400, 0xFFF0FC00, .NEON, {}},
		{.USHLL2, {.V_2D, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHL_IMM, .NONE}, 0x6F20A400, 0xFFE0FC00, .NEON, {}},
	},
	.SHRN = {
		{.SHRN, {.V_8B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F088400, 0xFFF8FC00, .NEON, {}},
		{.SHRN, {.V_4H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F108400, 0xFFF0FC00, .NEON, {}},
		{.SHRN, {.V_2S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F208400, 0xFFE0FC00, .NEON, {}},
	},
	.SHRN2 = {
		{.SHRN2, {.V_16B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F088400, 0xFFF8FC00, .NEON, {}},
		{.SHRN2, {.V_8H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F108400, 0xFFF0FC00, .NEON, {}},
		{.SHRN2, {.V_4S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F208400, 0xFFE0FC00, .NEON, {}},
	},
	.RSHRN = {
		{.RSHRN, {.V_8B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F088C00, 0xFFF8FC00, .NEON, {}},
		{.RSHRN, {.V_4H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F108C00, 0xFFF0FC00, .NEON, {}},
		{.RSHRN, {.V_2S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F208C00, 0xFFE0FC00, .NEON, {}},
	},
	.RSHRN2 = {
		{.RSHRN2, {.V_16B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F088C00, 0xFFF8FC00, .NEON, {}},
		{.RSHRN2, {.V_8H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F108C00, 0xFFF0FC00, .NEON, {}},
		{.RSHRN2, {.V_4S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F208C00, 0xFFE0FC00, .NEON, {}},
	},
	.SQSHRN = {
		{.SQSHRN, {.V_8B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F089400, 0xFFF8FC00, .NEON, {}},
		{.SQSHRN, {.V_4H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F109400, 0xFFF0FC00, .NEON, {}},
		{.SQSHRN, {.V_2S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F209400, 0xFFE0FC00, .NEON, {}},
	},
	.SQSHRN2 = {
		{.SQSHRN2, {.V_16B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F089400, 0xFFF8FC00, .NEON, {}},
		{.SQSHRN2, {.V_8H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F109400, 0xFFF0FC00, .NEON, {}},
		{.SQSHRN2, {.V_4S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F209400, 0xFFE0FC00, .NEON, {}},
	},
	.UQSHRN = {
		{.UQSHRN, {.V_8B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F089400, 0xFFF8FC00, .NEON, {}},
		{.UQSHRN, {.V_4H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F109400, 0xFFF0FC00, .NEON, {}},
		{.UQSHRN, {.V_2S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F209400, 0xFFE0FC00, .NEON, {}},
	},
	.UQSHRN2 = {
		{.UQSHRN2, {.V_16B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F089400, 0xFFF8FC00, .NEON, {}},
		{.UQSHRN2, {.V_8H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F109400, 0xFFF0FC00, .NEON, {}},
		{.UQSHRN2, {.V_4S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F209400, 0xFFE0FC00, .NEON, {}},
	},
	.SQRSHRN = {
		{.SQRSHRN, {.V_8B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F089C00, 0xFFF8FC00, .NEON, {}},
		{.SQRSHRN, {.V_4H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F109C00, 0xFFF0FC00, .NEON, {}},
		{.SQRSHRN, {.V_2S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x0F209C00, 0xFFE0FC00, .NEON, {}},
	},
	.SQRSHRN2 = {
		{.SQRSHRN2, {.V_16B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F089C00, 0xFFF8FC00, .NEON, {}},
		{.SQRSHRN2, {.V_8H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F109C00, 0xFFF0FC00, .NEON, {}},
		{.SQRSHRN2, {.V_4S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x4F209C00, 0xFFE0FC00, .NEON, {}},
	},
	.UQRSHRN = {
		{.UQRSHRN, {.V_8B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F089C00, 0xFFF8FC00, .NEON, {}},
		{.UQRSHRN, {.V_4H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F109C00, 0xFFF0FC00, .NEON, {}},
		{.UQRSHRN, {.V_2S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F209C00, 0xFFE0FC00, .NEON, {}},
	},
	.UQRSHRN2 = {
		{.UQRSHRN2, {.V_16B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F089C00, 0xFFF8FC00, .NEON, {}},
		{.UQRSHRN2, {.V_8H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F109C00, 0xFFF0FC00, .NEON, {}},
		{.UQRSHRN2, {.V_4S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F209C00, 0xFFE0FC00, .NEON, {}},
	},
	.SQSHRUN = {
		{.SQSHRUN, {.V_8B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F088400, 0xFFF8FC00, .NEON, {}},
		{.SQSHRUN, {.V_4H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F108400, 0xFFF0FC00, .NEON, {}},
		{.SQSHRUN, {.V_2S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F208400, 0xFFE0FC00, .NEON, {}},
	},
	.SQSHRUN2 = {
		{.SQSHRUN2, {.V_16B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F088400, 0xFFF8FC00, .NEON, {}},
		{.SQSHRUN2, {.V_8H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F108400, 0xFFF0FC00, .NEON, {}},
		{.SQSHRUN2, {.V_4S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F208400, 0xFFE0FC00, .NEON, {}},
	},
	.SQRSHRUN = {
		{.SQRSHRUN, {.V_8B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F088C00, 0xFFF8FC00, .NEON, {}},
		{.SQRSHRUN, {.V_4H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F108C00, 0xFFF0FC00, .NEON, {}},
		{.SQRSHRUN, {.V_2S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x2F208C00, 0xFFE0FC00, .NEON, {}},
	},
	.SQRSHRUN2 = {
		{.SQRSHRUN2, {.V_16B, .V_8H, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F088C00, 0xFFF8FC00, .NEON, {}},
		{.SQRSHRUN2, {.V_8H, .V_4S, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F108C00, 0xFFF0FC00, .NEON, {}},
		{.SQRSHRUN2, {.V_4S, .V_2D, .VEC_SHIFT, .NONE}, {.VD, .VN, .NEON_SHR_IMM, .NONE}, 0x6F208C00, 0xFFE0FC00, .NEON, {}},
	},

	// Advanced SIMD copy / permute (MOV/MVN/DUP/INS/EXT).
	.MOV_V = {
		{.MOV_V, {.V_8B, .V_8B, .NONE, .NONE}, {.VD, .VN_VM_DUP, .NONE, .NONE}, 0x0EA01C00, 0xFFE0FC00, .NEON, {}},
		{.MOV_V, {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN_VM_DUP, .NONE, .NONE}, 0x4EA01C00, 0xFFE0FC00, .NEON, {}},
	},
	.MVN_V = {
		{.MVN_V, {.V_8B, .V_8B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x2E205800, 0xFFFFFC00, .NEON, {}},
		{.MVN_V, {.V_16B, .V_16B, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x6E205800, 0xFFFFFC00, .NEON, {}},
	},
	.DUP_V = {
		{.DUP_V, {.V_8B, .V_ELEM_B, .VEC_INDEX, .NONE}, {.VD, .VN, .NEON_IDX5, .NONE}, 0x0E010400, 0xFFE1FC00, .NEON, {}},
		{.DUP_V, {.V_16B, .V_ELEM_B, .VEC_INDEX, .NONE}, {.VD, .VN, .NEON_IDX5, .NONE}, 0x4E010400, 0xFFE1FC00, .NEON, {}},
		{.DUP_V, {.V_4H, .V_ELEM_H, .VEC_INDEX, .NONE}, {.VD, .VN, .NEON_IDX5, .NONE}, 0x0E020400, 0xFFE3FC00, .NEON, {}},
		{.DUP_V, {.V_8H, .V_ELEM_H, .VEC_INDEX, .NONE}, {.VD, .VN, .NEON_IDX5, .NONE}, 0x4E020400, 0xFFE3FC00, .NEON, {}},
		{.DUP_V, {.V_2S, .V_ELEM_S, .VEC_INDEX, .NONE}, {.VD, .VN, .NEON_IDX5, .NONE}, 0x0E040400, 0xFFE7FC00, .NEON, {}},
		{.DUP_V, {.V_4S, .V_ELEM_S, .VEC_INDEX, .NONE}, {.VD, .VN, .NEON_IDX5, .NONE}, 0x4E040400, 0xFFE7FC00, .NEON, {}},
		{.DUP_V, {.V_2D, .V_ELEM_D, .VEC_INDEX, .NONE}, {.VD, .VN, .NEON_IDX5, .NONE}, 0x4E080400, 0xFFEFFC00, .NEON, {}},
		{.DUP_V, {.V_8B, .W_REG, .NONE, .NONE}, {.VD, .RN, .NONE, .NONE}, 0x0E010C00, 0xFFFFFC00, .NEON, {}},
		{.DUP_V, {.V_16B, .W_REG, .NONE, .NONE}, {.VD, .RN, .NONE, .NONE}, 0x4E010C00, 0xFFFFFC00, .NEON, {}},
		{.DUP_V, {.V_4H, .W_REG, .NONE, .NONE}, {.VD, .RN, .NONE, .NONE}, 0x0E020C00, 0xFFFFFC00, .NEON, {}},
		{.DUP_V, {.V_8H, .W_REG, .NONE, .NONE}, {.VD, .RN, .NONE, .NONE}, 0x4E020C00, 0xFFFFFC00, .NEON, {}},
		{.DUP_V, {.V_2S, .W_REG, .NONE, .NONE}, {.VD, .RN, .NONE, .NONE}, 0x0E040C00, 0xFFFFFC00, .NEON, {}},
		{.DUP_V, {.V_4S, .W_REG, .NONE, .NONE}, {.VD, .RN, .NONE, .NONE}, 0x4E040C00, 0xFFFFFC00, .NEON, {}},
		{.DUP_V, {.V_2D, .X_REG, .NONE, .NONE}, {.VD, .RN, .NONE, .NONE}, 0x4E080C00, 0xFFFFFC00, .NEON, {}},
	},
	.INS = {
		{.INS, {.V_ELEM_B, .VEC_INDEX, .V_ELEM_B, .VEC_INDEX}, {.VD, .NEON_IDX5, .VN, .NEON_IDX4}, 0x6E010400, 0xFFE18400, .NEON, {}},
		{.INS, {.V_ELEM_H, .VEC_INDEX, .V_ELEM_H, .VEC_INDEX}, {.VD, .NEON_IDX5, .VN, .NEON_IDX4}, 0x6E020400, 0xFFE38C00, .NEON, {}},
		{.INS, {.V_ELEM_S, .VEC_INDEX, .V_ELEM_S, .VEC_INDEX}, {.VD, .NEON_IDX5, .VN, .NEON_IDX4}, 0x6E040400, 0xFFE79C00, .NEON, {}},
		{.INS, {.V_ELEM_D, .VEC_INDEX, .V_ELEM_D, .VEC_INDEX}, {.VD, .NEON_IDX5, .VN, .NEON_IDX4}, 0x6E080400, 0xFFEFBC00, .NEON, {}},
		{.INS, {.V_ELEM_B, .VEC_INDEX, .W_REG, .NONE}, {.VD, .NEON_IDX5, .RN, .NONE}, 0x4E011C00, 0xFFE1FC00, .NEON, {}},
		{.INS, {.V_ELEM_H, .VEC_INDEX, .W_REG, .NONE}, {.VD, .NEON_IDX5, .RN, .NONE}, 0x4E021C00, 0xFFE3FC00, .NEON, {}},
		{.INS, {.V_ELEM_S, .VEC_INDEX, .W_REG, .NONE}, {.VD, .NEON_IDX5, .RN, .NONE}, 0x4E041C00, 0xFFE7FC00, .NEON, {}},
		{.INS, {.V_ELEM_D, .VEC_INDEX, .X_REG, .NONE}, {.VD, .NEON_IDX5, .RN, .NONE}, 0x4E081C00, 0xFFEFFC00, .NEON, {}},
	},
	.EXT_V = {
		{.EXT_V, {.V_8B, .V_8B, .V_8B, .VEC_INDEX}, {.VD, .VN, .VM, .NEON_EXT_IDX}, 0x2E000000, 0xFFE0C400, .NEON, {}},
		{.EXT_V, {.V_16B, .V_16B, .V_16B, .VEC_INDEX}, {.VD, .VN, .VM, .NEON_EXT_IDX}, 0x6E000000, 0xFFE08400, .NEON, {}},
	},

	// Scalar FP round/reciprocal + FP-to-GPR convert.
	.FRINTN = {
		{.FRINTN, {.S_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E244000, 0xFFFFFC00, .FP, {}},
		{.FRINTN, {.D_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E644000, 0xFFFFFC00, .FP, {}},
		{.FRINTN, {.H_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE44000, 0xFFFFFC00, .FP16, {}},
	},
	.FRINTP = {
		{.FRINTP, {.S_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E24C000, 0xFFFFFC00, .FP, {}},
		{.FRINTP, {.D_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E64C000, 0xFFFFFC00, .FP, {}},
		{.FRINTP, {.H_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE4C000, 0xFFFFFC00, .FP16, {}},
	},
	.FRINTM = {
		{.FRINTM, {.S_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E254000, 0xFFFFFC00, .FP, {}},
		{.FRINTM, {.D_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E654000, 0xFFFFFC00, .FP, {}},
		{.FRINTM, {.H_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE54000, 0xFFFFFC00, .FP16, {}},
	},
	.FRINTZ = {
		{.FRINTZ, {.S_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E25C000, 0xFFFFFC00, .FP, {}},
		{.FRINTZ, {.D_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E65C000, 0xFFFFFC00, .FP, {}},
		{.FRINTZ, {.H_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE5C000, 0xFFFFFC00, .FP16, {}},
	},
	.FRINTA = {
		{.FRINTA, {.S_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E264000, 0xFFFFFC00, .FP, {}},
		{.FRINTA, {.D_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E664000, 0xFFFFFC00, .FP, {}},
		{.FRINTA, {.H_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE64000, 0xFFFFFC00, .FP16, {}},
	},
	.FRINTX = {
		{.FRINTX, {.S_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E274000, 0xFFFFFC00, .FP, {}},
		{.FRINTX, {.D_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E674000, 0xFFFFFC00, .FP, {}},
		{.FRINTX, {.H_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE74000, 0xFFFFFC00, .FP16, {}},
	},
	.FRINTI = {
		{.FRINTI, {.S_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E27C000, 0xFFFFFC00, .FP, {}},
		{.FRINTI, {.D_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E67C000, 0xFFFFFC00, .FP, {}},
		{.FRINTI, {.H_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE7C000, 0xFFFFFC00, .FP16, {}},
	},
	.FRECPX = {
		{.FRECPX, {.S_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x5EA1F800, 0xFFFFFC00, .FP, {}},
		{.FRECPX, {.D_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x5EE1F800, 0xFFFFFC00, .FP, {}},
		{.FRECPX, {.H_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x5EF9F800, 0xFFFFFC00, .FP16, {}},
	},
	.FCVTAS = {
		{.FCVTAS, {.W_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E240000, 0xFFFFFC00, .FP, {}},
		{.FCVTAS, {.W_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E640000, 0xFFFFFC00, .FP, {}},
		{.FCVTAS, {.W_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE40000, 0xFFFFFC00, .FP16, {}},
		{.FCVTAS, {.X_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E240000, 0xFFFFFC00, .FP, {}},
		{.FCVTAS, {.X_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E640000, 0xFFFFFC00, .FP, {}},
		{.FCVTAS, {.X_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9EE40000, 0xFFFFFC00, .FP16, {}},
	},
	.FCVTAU = {
		{.FCVTAU, {.W_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E250000, 0xFFFFFC00, .FP, {}},
		{.FCVTAU, {.W_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E650000, 0xFFFFFC00, .FP, {}},
		{.FCVTAU, {.W_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE50000, 0xFFFFFC00, .FP16, {}},
		{.FCVTAU, {.X_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E250000, 0xFFFFFC00, .FP, {}},
		{.FCVTAU, {.X_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E650000, 0xFFFFFC00, .FP, {}},
		{.FCVTAU, {.X_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9EE50000, 0xFFFFFC00, .FP16, {}},
	},
	.FCVTMS = {
		{.FCVTMS, {.W_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E300000, 0xFFFFFC00, .FP, {}},
		{.FCVTMS, {.W_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E700000, 0xFFFFFC00, .FP, {}},
		{.FCVTMS, {.W_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EF00000, 0xFFFFFC00, .FP16, {}},
		{.FCVTMS, {.X_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E300000, 0xFFFFFC00, .FP, {}},
		{.FCVTMS, {.X_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E700000, 0xFFFFFC00, .FP, {}},
		{.FCVTMS, {.X_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9EF00000, 0xFFFFFC00, .FP16, {}},
	},
	.FCVTMU = {
		{.FCVTMU, {.W_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E310000, 0xFFFFFC00, .FP, {}},
		{.FCVTMU, {.W_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E710000, 0xFFFFFC00, .FP, {}},
		{.FCVTMU, {.W_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EF10000, 0xFFFFFC00, .FP16, {}},
		{.FCVTMU, {.X_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E310000, 0xFFFFFC00, .FP, {}},
		{.FCVTMU, {.X_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E710000, 0xFFFFFC00, .FP, {}},
		{.FCVTMU, {.X_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9EF10000, 0xFFFFFC00, .FP16, {}},
	},
	.FCVTNS = {
		{.FCVTNS, {.W_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E200000, 0xFFFFFC00, .FP, {}},
		{.FCVTNS, {.W_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E600000, 0xFFFFFC00, .FP, {}},
		{.FCVTNS, {.W_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE00000, 0xFFFFFC00, .FP16, {}},
		{.FCVTNS, {.X_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E200000, 0xFFFFFC00, .FP, {}},
		{.FCVTNS, {.X_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E600000, 0xFFFFFC00, .FP, {}},
		{.FCVTNS, {.X_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9EE00000, 0xFFFFFC00, .FP16, {}},
	},
	.FCVTNU = {
		{.FCVTNU, {.W_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E210000, 0xFFFFFC00, .FP, {}},
		{.FCVTNU, {.W_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E610000, 0xFFFFFC00, .FP, {}},
		{.FCVTNU, {.W_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE10000, 0xFFFFFC00, .FP16, {}},
		{.FCVTNU, {.X_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E210000, 0xFFFFFC00, .FP, {}},
		{.FCVTNU, {.X_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E610000, 0xFFFFFC00, .FP, {}},
		{.FCVTNU, {.X_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9EE10000, 0xFFFFFC00, .FP16, {}},
	},
	.FCVTPS = {
		{.FCVTPS, {.W_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E280000, 0xFFFFFC00, .FP, {}},
		{.FCVTPS, {.W_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E680000, 0xFFFFFC00, .FP, {}},
		{.FCVTPS, {.W_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE80000, 0xFFFFFC00, .FP16, {}},
		{.FCVTPS, {.X_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E280000, 0xFFFFFC00, .FP, {}},
		{.FCVTPS, {.X_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E680000, 0xFFFFFC00, .FP, {}},
		{.FCVTPS, {.X_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9EE80000, 0xFFFFFC00, .FP16, {}},
	},
	.FCVTPU = {
		{.FCVTPU, {.W_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E290000, 0xFFFFFC00, .FP, {}},
		{.FCVTPU, {.W_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1E690000, 0xFFFFFC00, .FP, {}},
		{.FCVTPU, {.W_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x1EE90000, 0xFFFFFC00, .FP16, {}},
		{.FCVTPU, {.X_REG, .S_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E290000, 0xFFFFFC00, .FP, {}},
		{.FCVTPU, {.X_REG, .D_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9E690000, 0xFFFFFC00, .FP, {}},
		{.FCVTPU, {.X_REG, .H_REG, .NONE, .NONE}, {.RD, .RN, .NONE, .NONE}, 0x9EE90000, 0xFFFFFC00, .FP16, {}},
	},

	// NEON modified immediate (MOVI/MVNI).
	.MOVI = {
		{.MOVI, {.V_8B, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x0F00E400, 0xFFF8FC00, .NEON, {}},
		{.MOVI, {.V_16B, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x4F00E400, 0xFFF8FC00, .NEON, {}},
		{.MOVI, {.V_4H, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x0F008400, 0xFFF8FC00, .NEON, {}},
		{.MOVI, {.V_8H, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x4F008400, 0xFFF8FC00, .NEON, {}},
		{.MOVI, {.V_2S, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x0F000400, 0xFFF8FC00, .NEON, {}},
		{.MOVI, {.V_4S, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x4F000400, 0xFFF8FC00, .NEON, {}},
		{.MOVI, {.V_2D, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x6F00E400, 0xFFF8FC00, .NEON, {}},
	},
	.MVNI = {
		{.MVNI, {.V_4H, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x2F008400, 0xFFF8FC00, .NEON, {}},
		{.MVNI, {.V_8H, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x6F008400, 0xFFF8FC00, .NEON, {}},
		{.MVNI, {.V_2S, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x2F000400, 0xFFF8FC00, .NEON, {}},
		{.MVNI, {.V_4S, .IMM_8, .NONE, .NONE}, {.VD, .NEON_IMM8_FMOV, .NONE, .NONE}, 0x6F000400, 0xFFF8FC00, .NEON, {}},
	},

	// SVE predicated / compare / predicate-logical / SVE2.
	.SVE_FRINTN = {
		{.SVE_FRINTN, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN, .NONE}, 0x6540A000, 0xFFFFE000, .SVE, {}},
		{.SVE_FRINTN, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN, .NONE}, 0x6580A000, 0xFFFFE000, .SVE, {}},
		{.SVE_FRINTN, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN, .NONE}, 0x65C0A000, 0xFFFFE000, .SVE, {is_64=true}},
	},
	.SVE_FRINTP = {
		{.SVE_FRINTP, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN, .NONE}, 0x6541A000, 0xFFFFE000, .SVE, {}},
		{.SVE_FRINTP, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN, .NONE}, 0x6581A000, 0xFFFFE000, .SVE, {}},
		{.SVE_FRINTP, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN, .NONE}, 0x65C1A000, 0xFFFFE000, .SVE, {is_64=true}},
	},
	.SVE_FRINTM = {
		{.SVE_FRINTM, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN, .NONE}, 0x6542A000, 0xFFFFE000, .SVE, {}},
		{.SVE_FRINTM, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN, .NONE}, 0x6582A000, 0xFFFFE000, .SVE, {}},
		{.SVE_FRINTM, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN, .NONE}, 0x65C2A000, 0xFFFFE000, .SVE, {is_64=true}},
	},
	.SVE_FRINTZ = {
		{.SVE_FRINTZ, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN, .NONE}, 0x6543A000, 0xFFFFE000, .SVE, {}},
		{.SVE_FRINTZ, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN, .NONE}, 0x6583A000, 0xFFFFE000, .SVE, {}},
		{.SVE_FRINTZ, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN, .NONE}, 0x65C3A000, 0xFFFFE000, .SVE, {is_64=true}},
	},
	.SVE_FRINTA = {
		{.SVE_FRINTA, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN, .NONE}, 0x6544A000, 0xFFFFE000, .SVE, {}},
		{.SVE_FRINTA, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN, .NONE}, 0x6584A000, 0xFFFFE000, .SVE, {}},
		{.SVE_FRINTA, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN, .NONE}, 0x65C4A000, 0xFFFFE000, .SVE, {is_64=true}},
	},
	.SVE_FRINTX = {
		{.SVE_FRINTX, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN, .NONE}, 0x6546A000, 0xFFFFE000, .SVE, {}},
		{.SVE_FRINTX, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN, .NONE}, 0x6586A000, 0xFFFFE000, .SVE, {}},
		{.SVE_FRINTX, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN, .NONE}, 0x65C6A000, 0xFFFFE000, .SVE, {is_64=true}},
	},
	.SVE_FRINTI = {
		{.SVE_FRINTI, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN, .NONE}, 0x6547A000, 0xFFFFE000, .SVE, {}},
		{.SVE_FRINTI, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN, .NONE}, 0x6587A000, 0xFFFFE000, .SVE, {}},
		{.SVE_FRINTI, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN, .NONE}, 0x65C7A000, 0xFFFFE000, .SVE, {is_64=true}},
	},
	.SVE_FRECPX_Z = {
		{.SVE_FRECPX_Z, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .NONE}, {.VD, .PG, .VN, .NONE}, 0x654CA000, 0xFFFFE000, .SVE, {}},
		{.SVE_FRECPX_Z, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .NONE}, {.VD, .PG, .VN, .NONE}, 0x658CA000, 0xFFFFE000, .SVE, {}},
		{.SVE_FRECPX_Z, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .NONE}, {.VD, .PG, .VN, .NONE}, 0x65CCA000, 0xFFFFE000, .SVE, {is_64=true}},
	},
	.SVE_ASRR_PRED = {
		{.SVE_ASRR_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VN}, 0x04148000, 0xFFFFE000, .SVE, {}},
		{.SVE_ASRR_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VN}, 0x04548000, 0xFFFFE000, .SVE, {}},
		{.SVE_ASRR_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VN}, 0x04948000, 0xFFFFE000, .SVE, {}},
		{.SVE_ASRR_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VN}, 0x04D48000, 0xFFFFE000, .SVE, {is_64=true}},
	},
	.SVE_LSLR_PRED = {
		{.SVE_LSLR_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VN}, 0x04178000, 0xFFFFE000, .SVE, {}},
		{.SVE_LSLR_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VN}, 0x04578000, 0xFFFFE000, .SVE, {}},
		{.SVE_LSLR_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VN}, 0x04978000, 0xFFFFE000, .SVE, {}},
		{.SVE_LSLR_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VN}, 0x04D78000, 0xFFFFE000, .SVE, {is_64=true}},
	},
	.SVE_LSRR_PRED = {
		{.SVE_LSRR_PRED, {.Z_REG_B, .P_REG_MERGE, .Z_REG_B, .Z_REG_B}, {.VD, .PG, .VD, .VN}, 0x04158000, 0xFFFFE000, .SVE, {}},
		{.SVE_LSRR_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VN}, 0x04558000, 0xFFFFE000, .SVE, {}},
		{.SVE_LSRR_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VN}, 0x04958000, 0xFFFFE000, .SVE, {}},
		{.SVE_LSRR_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VN}, 0x04D58000, 0xFFFFE000, .SVE, {is_64=true}},
	},
	.SVE_FSUBR_PRED = {
		{.SVE_FSUBR_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VN}, 0x65438000, 0xFFFFE000, .SVE, {}},
		{.SVE_FSUBR_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VN}, 0x65838000, 0xFFFFE000, .SVE, {}},
		{.SVE_FSUBR_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VN}, 0x65C38000, 0xFFFFE000, .SVE, {is_64=true}},
	},
	.SVE_FDIVR_PRED = {
		{.SVE_FDIVR_PRED, {.Z_REG_H, .P_REG_MERGE, .Z_REG_H, .Z_REG_H}, {.VD, .PG, .VD, .VN}, 0x654C8000, 0xFFFFE000, .SVE, {}},
		{.SVE_FDIVR_PRED, {.Z_REG_S, .P_REG_MERGE, .Z_REG_S, .Z_REG_S}, {.VD, .PG, .VD, .VN}, 0x658C8000, 0xFFFFE000, .SVE, {}},
		{.SVE_FDIVR_PRED, {.Z_REG_D, .P_REG_MERGE, .Z_REG_D, .Z_REG_D}, {.VD, .PG, .VD, .VN}, 0x65CC8000, 0xFFFFE000, .SVE, {is_64=true}},
	},
	.SVE_FCMEQ = {
		{.SVE_FCMEQ, {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x65406000, 0xFFE0E010, .SVE, {}},
		{.SVE_FCMEQ, {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VN, .VM}, 0x65806000, 0xFFE0E010, .SVE, {}},
		{.SVE_FCMEQ, {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VN, .VM}, 0x65C06000, 0xFFE0E010, .SVE, {is_64=true}},
	},
	.SVE_FCMGE = {
		{.SVE_FCMGE, {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x65404000, 0xFFE0E010, .SVE, {}},
		{.SVE_FCMGE, {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VN, .VM}, 0x65804000, 0xFFE0E010, .SVE, {}},
		{.SVE_FCMGE, {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VN, .VM}, 0x65C04000, 0xFFE0E010, .SVE, {is_64=true}},
	},
	.SVE_FCMGT = {
		{.SVE_FCMGT, {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x65404010, 0xFFE0E010, .SVE, {}},
		{.SVE_FCMGT, {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VN, .VM}, 0x65804010, 0xFFE0E010, .SVE, {}},
		{.SVE_FCMGT, {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VN, .VM}, 0x65C04010, 0xFFE0E010, .SVE, {is_64=true}},
	},
	.SVE_FCMNE = {
		{.SVE_FCMNE, {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x65406010, 0xFFE0E010, .SVE, {}},
		{.SVE_FCMNE, {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VN, .VM}, 0x65806010, 0xFFE0E010, .SVE, {}},
		{.SVE_FCMNE, {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VN, .VM}, 0x65C06010, 0xFFE0E010, .SVE, {is_64=true}},
	},
	.SVE_FCMUO = {
		{.SVE_FCMUO, {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VN, .VM}, 0x6540C000, 0xFFE0E010, .SVE, {}},
		{.SVE_FCMUO, {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VN, .VM}, 0x6580C000, 0xFFE0E010, .SVE, {}},
		{.SVE_FCMUO, {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VN, .VM}, 0x65C0C000, 0xFFE0E010, .SVE, {is_64=true}},
	},
	.SVE_FCMLE = {
		{.SVE_FCMLE, {.P_REG, .P_REG_ZERO, .Z_REG_H, .NONE}, {.PD, .PG, .VN, .NONE}, 0x65512010, 0xFFFFE010, .SVE, {}},
		{.SVE_FCMLE, {.P_REG, .P_REG_ZERO, .Z_REG_S, .NONE}, {.PD, .PG, .VN, .NONE}, 0x65912010, 0xFFFFE010, .SVE, {}},
		{.SVE_FCMLE, {.P_REG, .P_REG_ZERO, .Z_REG_D, .NONE}, {.PD, .PG, .VN, .NONE}, 0x65D12010, 0xFFFFE010, .SVE, {is_64=true}},
	},
	.SVE_FCMLT = {
		{.SVE_FCMLT, {.P_REG, .P_REG_ZERO, .Z_REG_H, .NONE}, {.PD, .PG, .VN, .NONE}, 0x65512000, 0xFFFFE010, .SVE, {}},
		{.SVE_FCMLT, {.P_REG, .P_REG_ZERO, .Z_REG_S, .NONE}, {.PD, .PG, .VN, .NONE}, 0x65912000, 0xFFFFE010, .SVE, {}},
		{.SVE_FCMLT, {.P_REG, .P_REG_ZERO, .Z_REG_D, .NONE}, {.PD, .PG, .VN, .NONE}, 0x65D12000, 0xFFFFE010, .SVE, {is_64=true}},
	},
	.SVE_CMPLE = {
		{.SVE_CMPLE, {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VM, .VN}, 0x24008000, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPLE, {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VM, .VN}, 0x24408000, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPLE, {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VM, .VN}, 0x24808000, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPLE, {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VM, .VN}, 0x24C08000, 0xFFE0E010, .SVE, {sets_flags=true, is_64=true}},
	},
	.SVE_CMPLO = {
		{.SVE_CMPLO, {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VM, .VN}, 0x24000010, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPLO, {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VM, .VN}, 0x24400010, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPLO, {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VM, .VN}, 0x24800010, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPLO, {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VM, .VN}, 0x24C00010, 0xFFE0E010, .SVE, {sets_flags=true, is_64=true}},
	},
	.SVE_CMPLS = {
		{.SVE_CMPLS, {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VM, .VN}, 0x24000000, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPLS, {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VM, .VN}, 0x24400000, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPLS, {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VM, .VN}, 0x24800000, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPLS, {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VM, .VN}, 0x24C00000, 0xFFE0E010, .SVE, {sets_flags=true, is_64=true}},
	},
	.SVE_CMPLT = {
		{.SVE_CMPLT, {.P_REG, .P_REG_ZERO, .Z_REG_B, .Z_REG_B}, {.PD, .PG, .VM, .VN}, 0x24008010, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPLT, {.P_REG, .P_REG_ZERO, .Z_REG_H, .Z_REG_H}, {.PD, .PG, .VM, .VN}, 0x24408010, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPLT, {.P_REG, .P_REG_ZERO, .Z_REG_S, .Z_REG_S}, {.PD, .PG, .VM, .VN}, 0x24808010, 0xFFE0E010, .SVE, {sets_flags=true}},
		{.SVE_CMPLT, {.P_REG, .P_REG_ZERO, .Z_REG_D, .Z_REG_D}, {.PD, .PG, .VM, .VN}, 0x24C08010, 0xFFE0E010, .SVE, {sets_flags=true, is_64=true}},
	},
	.SVE_NANDS_P = {
		{.SVE_NANDS_P, {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25C04210, 0xFFF0C210, .SVE, {sets_flags=true}},
	},
	.SVE_NORS_P = {
		{.SVE_NORS_P, {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25C04200, 0xFFF0C210, .SVE, {sets_flags=true}},
	},
	.SVE_ORNS_P = {
		{.SVE_ORNS_P, {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x25C04010, 0xFFF0C210, .SVE, {sets_flags=true}},
	},
	.SVE_BRKPA = {
		{.SVE_BRKPA, {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x2500C000, 0xFFF0C210, .SVE, {}},
	},
	.SVE_BRKPB = {
		{.SVE_BRKPB, {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PM}, 0x2500C010, 0xFFF0C210, .SVE, {}},
	},
	.SVE_BRKA = {
		{.SVE_BRKA, {.P_REG, .P_REG_MERGE, .P_REG, .NONE}, {.PD, .PG4, .PN, .NONE}, 0x25104010, 0xFFFFC210, .SVE, {}},
	},
	.SVE_BRKB = {
		{.SVE_BRKB, {.P_REG, .P_REG_MERGE, .P_REG, .NONE}, {.PD, .PG4, .PN, .NONE}, 0x25904010, 0xFFFFC210, .SVE, {}},
	},
	.SVE_BRKAS = {
		{.SVE_BRKAS, {.P_REG, .P_REG_ZERO, .P_REG, .NONE}, {.PD, .PG4, .PN, .NONE}, 0x25504000, 0xFFFFC210, .SVE, {sets_flags=true}},
	},
	.SVE_BRKBS = {
		{.SVE_BRKBS, {.P_REG, .P_REG_ZERO, .P_REG, .NONE}, {.PD, .PG4, .PN, .NONE}, 0x25D04000, 0xFFFFC210, .SVE, {sets_flags=true}},
	},
	.SVE_EOR3_Z = {
		{.SVE_EOR3_Z, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .Z_REG_D}, {.VD, .VD, .VM, .VN}, 0x04203800, 0xFFE0FC00, .SVE, {is_64=true}},
	},
	.SVE_BCAX_Z = {
		{.SVE_BCAX_Z, {.Z_REG_D, .Z_REG_D, .Z_REG_D, .Z_REG_D}, {.VD, .VD, .VM, .VN}, 0x04603800, 0xFFE0FC00, .SVE, {is_64=true}},
	},
	.SVE_INSR = {
		{.SVE_INSR, {.Z_REG_B, .W_REG, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x05243800, 0xFFFFFC00, .SVE, {}},
		{.SVE_INSR, {.Z_REG_H, .W_REG, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x05643800, 0xFFFFFC00, .SVE, {}},
		{.SVE_INSR, {.Z_REG_S, .W_REG, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x05A43800, 0xFFFFFC00, .SVE, {}},
		{.SVE_INSR, {.Z_REG_D, .X_REG, .NONE, .NONE}, {.VD, .VN, .NONE, .NONE}, 0x05E43800, 0xFFFFFC00, .SVE, {is_64=true}},
	},
	.SVE_COMPACT = {
		{.SVE_COMPACT, {.Z_REG_S, .P_REG_GOV, .Z_REG_S, .NONE}, {.VD, .PG, .VN, .NONE}, 0x05A18000, 0xFFFFE000, .SVE, {}},
		{.SVE_COMPACT, {.Z_REG_D, .P_REG_GOV, .Z_REG_D, .NONE}, {.VD, .PG, .VN, .NONE}, 0x05E18000, 0xFFFFE000, .SVE, {is_64=true}},
	},
	.SVE_SETFFR = {
		{.SVE_SETFFR, {.NONE, .NONE, .NONE, .NONE}, {.NONE, .NONE, .NONE, .NONE}, 0x252C9000, 0xFFFFFFFF, .SVE, {}},
	},
	.SVE_RDFFR = {
		{.SVE_RDFFR, {.P_REG, .NONE, .NONE, .NONE}, {.PD, .NONE, .NONE, .NONE}, 0x2519F000, 0xFFFFFFF0, .SVE, {}},
	},
	.SVE_WRFFR = {
		{.SVE_WRFFR, {.P_REG, .NONE, .NONE, .NONE}, {.PN, .NONE, .NONE, .NONE}, 0x25289000, 0xFFFFFE1F, .SVE, {}},
	},
	.SVE_BRKN = {
		{.SVE_BRKN, {.P_REG, .P_REG_ZERO, .P_REG, .P_REG}, {.PD, .PG4, .PN, .PD}, 0x25184000, 0xFFFFC210, .SVE, {}},
	},
	// SPECGEN:END
}
