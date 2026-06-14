package rexcode_riscv

// =============================================================================
// INSTRUCTION
// =============================================================================
//
// All non-C base instructions are 4 bytes. The `length` field is
// preserved for shape parity with arches that have variable-length
// (mos65816, mos6502) -- here it's always 4.

Instruction_Flags :: bit_field u8 {
	_: u8 | 8,
}

Instruction :: struct #packed {
	ops:           [4]Operand,         // 64 bytes
	mnemonic:      Mnemonic,           // 2
	operand_count: u8,                 // 1
	flags:         Instruction_Flags,  // 1
	length:        u8,                 // 1 -- always 4 for non-C
	_:             [3]u8,              // 3
}
#assert(size_of(Instruction) == 72)

// =============================================================================
// Builders (shape spelled out, comma-separated)
// =============================================================================

inst_none :: #force_inline proc "contextless" (m: Mnemonic) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 0, length = 4}
}

// R-type: rd, rs1, rs2
inst_r_r_r :: #force_inline proc "contextless" (m: Mnemonic, rd, rs1, rs2: Register) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4,
					   ops = {op_reg(rd), op_reg(rs1), op_reg(rs2), {}}}
}

// I-type (ALU): rd, rs1, imm12
inst_r_r_i :: #force_inline proc "contextless" (m: Mnemonic, rd, rs1: Register, imm: i64) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4,
					   ops = {op_reg(rd), op_reg(rs1), op_imm(imm, 2), {}}}
}

// I-type (shift): rd, rs1, shamt
inst_shift :: #force_inline proc "contextless" (m: Mnemonic, rd, rs1: Register, shamt: u8) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4,
					   ops = {op_reg(rd), op_reg(rs1), op_imm(i64(shamt), 1), {}}}
}

// I-type load: rd, disp(base)
inst_load :: #force_inline proc "contextless" (m: Mnemonic, rd: Register, mm: Memory) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4,
					   ops = {op_reg(rd), op_mem(mm), {}, {}}}
}

// S-type store: rs2 (data), disp(base)
inst_store :: #force_inline proc "contextless" (m: Mnemonic, rs2: Register, mm: Memory) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4,
					   ops = {op_reg(rs2), op_mem(mm), {}, {}}}
}

// U-type: rd, imm20
inst_u :: #force_inline proc "contextless" (m: Mnemonic, rd: Register, imm: i64) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4,
					   ops = {op_reg(rd), op_imm(imm, 4), {}, {}}}
}

// J-type: rd, label
inst_jal :: #force_inline proc "contextless" (m: Mnemonic, rd: Register, label_id: u32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4,
					   ops = {op_reg(rd), op_label(label_id, 4), {}, {}}}
}

// B-type branch: rs1, rs2, label
inst_branch :: #force_inline proc "contextless" (m: Mnemonic, rs1, rs2: Register, label_id: u32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4,
					   ops = {op_reg(rs1), op_reg(rs2), op_label(label_id, 2), {}}}
}

// JALR: rd, rs1, imm12  (indirect jump with offset)
inst_jalr :: #force_inline proc "contextless" (rd, rs1: Register, imm: i64) -> Instruction {
	return Instruction{mnemonic = .JALR, operand_count = 3, length = 4,
					   ops = {op_reg(rd), op_reg(rs1), op_imm(imm, 2), {}}}
}

// CSR ops: rd, csr, rs1
inst_csr :: #force_inline proc "contextless" (m: Mnemonic, rd: Register, csr: u16, rs1: Register) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4,
					   ops = {op_reg(rd), op_imm(i64(csr), 2), op_reg(rs1), {}}}
}

// CSR immediate ops: rd, csr, zimm5
inst_csr_i :: #force_inline proc "contextless" (m: Mnemonic, rd: Register, csr: u16, zimm5: u8) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4,
					   ops = {op_reg(rd), op_imm(i64(csr), 2), op_imm(i64(zimm5), 1), {}}}
}

// FP R4-type: rd, rs1, rs2, rs3  (FMADD/FMSUB/FNMADD/FNMSUB)
inst_r4 :: #force_inline proc "contextless" (m: Mnemonic, rd, rs1, rs2, rs3: Register) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 4, length = 4,
					   ops = {op_reg(rd), op_reg(rs1), op_reg(rs2), op_reg(rs3)}}
}

// FP R-type with 2 regs: rd, rs1 (FSQRT, FCVT, FMV, FCLASS, ...)
inst_r_r :: #force_inline proc "contextless" (m: Mnemonic, rd, rs1: Register) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4,
					   ops = {op_reg(rd), op_reg(rs1), {}, {}}}
}
