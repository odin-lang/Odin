package rexcode_arm64

// =============================================================================
// INSTRUCTION
// =============================================================================

Instruction_Flags :: bit_field u8 {
	_: u8 | 8,
}

Instruction :: struct #packed {
	ops:           [4]Operand `fmt:"v,operand_count"`, // 4 * size_of(Operand)
	mnemonic:      Mnemonic,                           // 2
	operand_count: u8,                                 // 1
	flags:         Instruction_Flags,                  // 1
	length:        u8,                                 // 1 -- always 4
	_:             [3]u8,                              // 3
}

// =============================================================================
// Builders -- the most common shapes; less-common forms can be built
// inline by the caller using the Instruction struct directly.
// =============================================================================

@(require_results)
inst_none :: #force_inline proc "contextless" (m: Mnemonic) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 0, length = 4}
}

// Single-register (e.g. BR, BLR).
@(require_results)
inst_r :: #force_inline proc "contextless" (m: Mnemonic, r: Register) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, length = 4,
					   ops = {op_reg(r), {}, {}, {}}}
}

// 2-register (e.g. CLZ, RBIT).
@(require_results)
inst_r_r :: #force_inline proc "contextless" (m: Mnemonic, rd, rn: Register) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4,
					   ops = {op_reg(rd), op_reg(rn), {}, {}}}
}

// 3-register (e.g. ADD shifted, MUL, UDIV, ASRV).
@(require_results)
inst_r_r_r :: #force_inline proc "contextless" (m: Mnemonic, rd, rn, rm: Register) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4,
					   ops = {op_reg(rd), op_reg(rn), op_reg(rm), {}}}
}

// 4-register R4-type (MADD, MSUB, SMADDL, ...).
@(require_results)
inst_r_r_r_r :: #force_inline proc "contextless" (m: Mnemonic, rd, rn, rm, ra: Register) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 4, length = 4,
					   ops = {op_reg(rd), op_reg(rn), op_reg(rm), op_reg(ra)}}
}

// 2-register + immediate (e.g. ADD imm).
@(require_results)
inst_r_r_i :: #force_inline proc "contextless" (m: Mnemonic, rd, rn: Register, imm: i64) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4,
					   ops = {op_reg(rd), op_reg(rn), op_imm(imm), {}}}
}

// 1-register + immediate (e.g. MOVZ).
@(require_results)
inst_r_i :: #force_inline proc "contextless" (m: Mnemonic, rd: Register, imm: i64) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4,
					   ops = {op_reg(rd), op_imm(imm), {}, {}}}
}

// MOVZ/MOVN/MOVK with explicit hw shift (0/16/32/48).
@(require_results)
inst_mov_imm :: #force_inline proc "contextless" (m: Mnemonic, rd: Register, imm: i64, hw: u8) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4,
					   ops = {op_reg(rd), op_imm(imm), op_imm(i64(hw), 1), {}}}
}

// Load/store register: Rt + memory.
@(require_results)
inst_ldst :: #force_inline proc "contextless" (m: Mnemonic, rt: Register, mm: Memory) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4,
					   ops = {op_reg(rt), op_mem(mm), {}, {}}}
}

// Load/store pair: Rt, Rt2, memory.
@(require_results)
inst_ldp_stp :: #force_inline proc "contextless" (m: Mnemonic, rt, rt2: Register, mm: Memory) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4,
					   ops = {op_reg(rt), op_reg(rt2), op_mem(mm), {}}}
}

// PC-relative branch (B, BL).
@(require_results)
inst_branch :: #force_inline proc "contextless" (m: Mnemonic, label_id: u32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, length = 4,
					   ops = {op_label(label_id, 4), {}, {}, {}}}
}

// Conditional branch (B.cond label).
@(require_results)
inst_b_cond :: #force_inline proc "contextless" (c: Cond, label_id: u32) -> Instruction {
	return Instruction{mnemonic = .B_COND, operand_count = 2, length = 4,
					   ops = {op_cond(c), op_label(label_id, 4), {}, {}}}
}

// CBZ/CBNZ: Rt, label.
@(require_results)
inst_cbz :: #force_inline proc "contextless" (m: Mnemonic, rt: Register, label_id: u32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4,
					   ops = {op_reg(rt), op_label(label_id, 4), {}, {}}}
}

// TBZ/TBNZ: Rt, bit, label.
@(require_results)
inst_tbz :: #force_inline proc "contextless" (m: Mnemonic, rt: Register, bit: u8, label_id: u32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4,
					   ops = {op_reg(rt), op_imm(i64(bit), 1), op_label(label_id, 4), {}}}
}

// CSEL/CSINC/CSINV/CSNEG: Rd, Rn, Rm, cond.
@(require_results)
inst_csel :: #force_inline proc "contextless" (m: Mnemonic, rd, rn, rm: Register, c: Cond) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 4, length = 4,
					   ops = {op_reg(rd), op_reg(rn), op_reg(rm), op_cond(c)}}
}
