package rexcode_ppc_vle

// =============================================================================
// PowerPC VLE Instruction
// =============================================================================
//
// Variable-length: 2 bytes for `se_*` short, 4 bytes for `e_*` long.
// The encoder picks length from the matched form's flags.short bit.

Instruction_Flags :: bit_field u8 {
	sets_cr0: bool | 1,   // Rc=1 — "." suffix
	has_oe:   bool | 1,   // OE=1 — "o" suffix
	lk:       bool | 1,   // link bit (e_bl, se_bl, etc.)
	aa:       bool | 1,   // absolute-address flag
	_:        u8   | 4,
}

Instruction :: struct #packed {
	ops:           [4]Operand,
	mnemonic:      Mnemonic,
	operand_count: u8,
	flags:         Instruction_Flags,
	mode:          Mode,
	length:        u8,       // 2 or 4
	form_id:       u16,
}

inst_none :: #force_inline proc "contextless" (m: Mnemonic) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 0, length = 2, mode = .PPC32_VLE}
}

inst_r :: #force_inline proc "contextless" (m: Mnemonic, r: Register) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, length = 2, mode = .PPC32_VLE,
					   ops = {op_reg(r), {}, {}, {}}}
}
inst_i :: #force_inline proc "contextless" (m: Mnemonic, v: i64) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, length = 4, mode = .PPC32_VLE,
					   ops = {op_imm(v), {}, {}, {}}}
}

inst_r_r :: #force_inline proc "contextless" (m: Mnemonic, rd, ra: Register) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 2, mode = .PPC32_VLE,
					   ops = {op_reg(rd), op_reg(ra), {}, {}}}
}

inst_r_r_r :: #force_inline proc "contextless" (m: Mnemonic, rd, ra, rb: Register) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4, mode = .PPC32_VLE,
					   ops = {op_reg(rd), op_reg(ra), op_reg(rb), {}}}
}

inst_r_r_i :: #force_inline proc "contextless" (m: Mnemonic, rd, ra: Register, v: i64) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4, mode = .PPC32_VLE,
					   ops = {op_reg(rd), op_reg(ra), op_imm(v), {}}}
}

inst_load :: #force_inline proc "contextless" (m: Mnemonic, rt: Register, mm: Memory) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4, mode = .PPC32_VLE,
					   ops = {op_reg(rt), op_mem(mm), {}, {}}}
}

inst_branch :: #force_inline proc "contextless" (m: Mnemonic, label_id: u32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, length = 4, mode = .PPC32_VLE,
					   ops = {op_label(label_id), {}, {}, {}}}
}
