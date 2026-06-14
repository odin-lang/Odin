package rexcode_mips

// =============================================================================
// INSTRUCTION
// =============================================================================

Instruction_Flags :: bit_field u8 {
	// Reserved for per-instance hints (e.g. taken-prediction, atomic
	// suffixes, addressing-mode overrides for future extensions). The
	// base ISA needs none of these at the instance level -- everything
	// semantic is already in the mnemonic.
	_: u8 | 8,
}

Instruction :: struct #packed {
	ops:           [4]Operand,        // 64 bytes
	mnemonic:      Mnemonic,          // 2 bytes
	operand_count: u8,                // 1 byte
	flags:         Instruction_Flags, // 1 byte
	length:        u8,                // 1 byte — always 4 for now; will be 2 for future μMIPS / MIPS16e
	_:             [3]u8,             // 3 bytes
}
#assert(size_of(Instruction) == 72)

// =============================================================================
// Builders (mirror x86's `inst_*` shapes; per the cross-arch contract)
// =============================================================================

inst_none :: #force_inline proc "contextless" (m: Mnemonic) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 0, length = 4}
}

inst_r :: #force_inline proc "contextless" (m: Mnemonic, a: Register) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, length = 4,
					   ops = {op_reg(a), {}, {}, {}}}
}

inst_r_r :: #force_inline proc "contextless" (m: Mnemonic, dst, src: Register) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4,
					   ops = {op_reg(dst), op_reg(src), {}, {}}}
}

inst_r_r_r :: #force_inline proc "contextless" (m: Mnemonic, dst, s1, s2: Register) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4,
					   ops = {op_reg(dst), op_reg(s1), op_reg(s2), {}}}
}

// MIPS three-operand immediate: $rt, $rs, imm (e.g. ADDI rt, rs, imm).
inst_r_r_i :: #force_inline proc "contextless" (m: Mnemonic, rt, rs: Register, imm: i64) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4,
					   ops = {op_reg(rt), op_reg(rs), op_imm(imm, 2), {}}}
}

// Two-operand immediate (e.g. LUI rt, imm; LI variants).
inst_r_i :: #force_inline proc "contextless" (m: Mnemonic, rt: Register, imm: i64) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4,
					   ops = {op_reg(rt), op_imm(imm, 2), {}, {}}}
}

// Load/store: reg + memory (LW $rt, disp($rs)).
inst_r_m :: #force_inline proc "contextless" (m: Mnemonic, r: Register, mm: Memory, size: u8 = 4) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4,
					   ops = {op_reg(r), op_mem(mm, size), {}, {}}}
}

// Shift by immediate: $rd, $rt, shamt (SLL/SRL/SRA).
inst_shift :: #force_inline proc "contextless" (m: Mnemonic, rd, rt: Register, shamt: u8) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4,
					   ops = {op_reg(rd), op_reg(rt), op_imm(i64(shamt), 1), {}}}
}

// Variable shift: $rd, $rt, $rs (SLLV/SRLV/SRAV).
inst_shift_v :: inst_r_r_r

// Single-operand: JR $rs, JALR $rd (with implicit RA), MFHI/MFLO/MTHI/MTLO,
// SYSCALL/BREAK take an imm code so they use inst_i below.
inst_i :: #force_inline proc "contextless" (m: Mnemonic, imm: i64) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, length = 4,
					   ops = {op_imm(imm, 4), {}, {}, {}}}
}

// Two-reg branch + label (BEQ/BNE: rs, rt, target).
inst_branch2 :: #force_inline proc "contextless" (m: Mnemonic, rs, rt: Register, label_id: u32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4,
					   ops = {op_reg(rs), op_reg(rt), op_label(label_id), {}}}
}

// One-reg branch + label (BLTZ/BGEZ/BLEZ/BGTZ/BLTZAL/BGEZAL/...).
inst_branch1 :: #force_inline proc "contextless" (m: Mnemonic, rs: Register, label_id: u32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4,
					   ops = {op_reg(rs), op_label(label_id), {}, {}}}
}

// J-type jump (J/JAL: target only).
inst_jump :: #force_inline proc "contextless" (m: Mnemonic, label_id: u32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, length = 4,
					   ops = {op_label(label_id), {}, {}, {}}}
}

// COP0 move with explicit selector: MFC0 $rt, $rd, sel (R2+).
inst_cp0_sel :: #force_inline proc "contextless" (m: Mnemonic, rt, rd: Register, sel: u8) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4,
					   ops = {op_reg(rt), op_reg(rd), op_imm(i64(sel), 1), {}}}
}
