package rexcode_rsp

// =============================================================================
// RSP INSTRUCTION
// =============================================================================

Instruction_Flags :: bit_field u8 {
	_: u8 | 8,
}

Instruction :: struct #packed {
	ops:           [4]Operand `fmt:"v,operand_count"`, // 64 bytes
	mnemonic:      Mnemonic,                           //  2 bytes
	operand_count: u8,                                 //  1 byte
	flags:         Instruction_Flags,                  //  1 byte
	length:        u8,                                 //  1 byte (always 4)
	_:             [3]u8,                              //  3 bytes
}
#assert(size_of(Instruction) == 72)

// =============================================================================
// Builders (mirror x86/mips conventions)
// =============================================================================

@(require_results)
inst_none :: #force_inline proc "contextless" (m: Mnemonic) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 0, length = 4}
}
@(require_results)
inst_r :: #force_inline proc "contextless" (m: Mnemonic, a: Register) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, length = 4,
					   ops = {op_reg(a), {}, {}, {}}}
}
@(require_results)
inst_r_r :: #force_inline proc "contextless" (m: Mnemonic, d, s: Register) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4,
					   ops = {op_reg(d), op_reg(s), {}, {}}}
}
@(require_results)
inst_r_r_r :: #force_inline proc "contextless" (m: Mnemonic, d, s1, s2: Register) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4,
					   ops = {op_reg(d), op_reg(s1), op_reg(s2), {}}}
}
@(require_results)
inst_r_r_i :: #force_inline proc "contextless" (m: Mnemonic, rt, rs: Register, imm: i64) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4,
					   ops = {op_reg(rt), op_reg(rs), op_imm(imm, 2), {}}}
}
@(require_results)
inst_r_i :: #force_inline proc "contextless" (m: Mnemonic, rt: Register, imm: i64) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4,
					   ops = {op_reg(rt), op_imm(imm, 2), {}, {}}}
}
@(require_results)
inst_r_m :: #force_inline proc "contextless" (m: Mnemonic, r: Register, mm: Memory, size: u8 = 4) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4,
					   ops = {op_reg(r), op_mem(mm, size), {}, {}}}
}

// Vector ALU: 3-operand vector op with optional element selector on vt.
@(require_results)
inst_v_v_v :: #force_inline proc "contextless" (m: Mnemonic, vd, vs, vt: Register, vt_element: u8 = 0) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4,
					   ops = {op_vr(vd), op_vr(vs), op_vr(vt, vt_element), {}}}
}

// Vector load/store: $vt[element], offset(base).
@(require_results)
inst_v_vmem :: #force_inline proc "contextless" (m: Mnemonic, vt: Register, vmem_op: Vector_Mem) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4,
					   ops = {op_vr(vt, vmem_op.element), op_vmem(vmem_op, 16), {}, {}}}
}

// Branch helpers
@(require_results)
inst_branch1 :: #force_inline proc "contextless" (m: Mnemonic, rs: Register, label_id: u32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4,
					   ops = {op_reg(rs), op_label(label_id), {}, {}}}
}
@(require_results)
inst_branch2 :: #force_inline proc "contextless" (m: Mnemonic, rs, rt: Register, label_id: u32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4,
					   ops = {op_reg(rs), op_reg(rt), op_label(label_id), {}}}
}
@(require_results)
inst_jump :: #force_inline proc "contextless" (m: Mnemonic, label_id: u32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, length = 4,
					   ops = {op_label(label_id), {}, {}, {}}}
}
