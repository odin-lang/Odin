package rexcode_mos65816

// =============================================================================
// INSTRUCTION
// =============================================================================

Instruction_Flags :: bit_field u8 {
	_: u8 | 8,
}

Instruction :: struct #packed {
	ops:           [2]Operand,         // 32 bytes (only MVN/MVP use 2; rest use 0 or 1)
	mnemonic:      Mnemonic,           // 2
	operand_count: u8,                 // 1
	flags:         Instruction_Flags,  // 1
	length:        u8,                 // 1
	_:             [3]u8,              // 3
}
#assert(size_of(Instruction) == 40)

inst_none :: #force_inline proc "contextless" (m: Mnemonic) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 0, length = 1}
}

inst_a :: #force_inline proc "contextless" (m: Mnemonic) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, length = 1,
					   ops = {op_reg(A), {}}}
}

inst_i8 :: #force_inline proc "contextless" (m: Mnemonic, v: i64) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, length = 2,
					   ops = {op_imm8(v), {}}}
}

inst_i16 :: #force_inline proc "contextless" (m: Mnemonic, v: i64) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, length = 3,
					   ops = {op_imm16(v), {}}}
}

inst_m :: #force_inline proc "contextless" (m: Mnemonic, mm: Memory) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, length = 0,
					   ops = {op_mem(mm), {}}}
}

inst_rel :: #force_inline proc "contextless" (m: Mnemonic, label_id: u32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, length = 2,
					   ops = {op_label(label_id, 1), {}}}
}

inst_rel_long :: #force_inline proc "contextless" (m: Mnemonic, label_id: u32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, length = 3,
					   ops = {op_label(label_id, 2), {}}}
}

// MVN/MVP src, dst -- caller writes "natural" order; encoder reverses to
// the WDC-specified opcode | dst_bank | src_bank byte layout.
inst_block_move :: #force_inline proc "contextless" (m: Mnemonic, src_bank, dst_bank: u8) -> Instruction {
	return Instruction{
		mnemonic = m, operand_count = 2, length = 3,
		ops = {
			Operand{immediate = i64(src_bank), kind = .IMMEDIATE, size = 1},
			Operand{immediate = i64(dst_bank), kind = .IMMEDIATE, size = 1},
		},
	}
}
