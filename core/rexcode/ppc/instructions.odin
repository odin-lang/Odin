// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ppc

// =============================================================================
// PowerPC INSTRUCTION
// =============================================================================
//
// All PowerPC instructions are 4 bytes except Power ISA 3.1 prefixed (8 bytes).
// `length` is derived by the encoder from the matched form's `bits` /
// `flags.prefixed`. `mode` selects PPC32 vs PPC64 form filtering (some ops
// gate on .P64 feature).

Instruction_Flags :: bit_field u8 {
	sets_cr0: bool | 1,   // Rc bit (record — writes CR0 from result)
	has_oe:   bool | 1,   // OE bit (overflow-enable, "o" suffix)
	aa:       bool | 1,   // absolute-address flag (branch AA bit)
	lk:       bool | 1,   // link bit (BL, BLR, BCL, BCCTRL etc.)
	_:        u8   | 4,
}

Instruction :: struct #packed {
	ops:           [4]Operand `fmt:"v,operand_count"`, // 4 * 16 = 64
	mnemonic:      Mnemonic,                           // 2
	operand_count: u8,                                 // 0..4
	flags:         Instruction_Flags,                  // 1
	mode:          Mode,                               // 1 (PPC32 / PPC64)
	length:        u8,                                 // 4 or 8 (prefixed)
	form_id:       u16,                                // 0 = no hint; otherwise 1 + form index
}
// 64 + 7 = 71 bytes (packed)

// =============================================================================
// Builders
// =============================================================================

@(require_results)
inst_none :: #force_inline proc "contextless" (m: Mnemonic, mode: Mode = .PPC32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 0, length = 4, mode = mode}
}

@(require_results)
inst_r :: #force_inline proc "contextless" (m: Mnemonic, r: Register, mode: Mode = .PPC32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, length = 4, mode = mode,
					   ops = {op_reg(r), {}, {}, {}}}
}
@(require_results)
inst_i :: #force_inline proc "contextless" (m: Mnemonic, v: i64, mode: Mode = .PPC32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, length = 4, mode = mode,
					   ops = {op_imm(v), {}, {}, {}}}
}

@(require_results)
inst_r_r :: #force_inline proc "contextless" (m: Mnemonic, rd, ra: Register, mode: Mode = .PPC32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4, mode = mode,
					   ops = {op_reg(rd), op_reg(ra), {}, {}}}
}
@(require_results)
inst_r_i :: #force_inline proc "contextless" (m: Mnemonic, rd: Register, v: i64, mode: Mode = .PPC32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4, mode = mode,
					   ops = {op_reg(rd), op_imm(v), {}, {}}}
}

@(require_results)
inst_r_r_r :: #force_inline proc "contextless" (m: Mnemonic, rd, ra, rb: Register, mode: Mode = .PPC32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4, mode = mode,
					   ops = {op_reg(rd), op_reg(ra), op_reg(rb), {}}}
}
@(require_results)
inst_r_r_i :: #force_inline proc "contextless" (m: Mnemonic, rd, ra: Register, v: i64, mode: Mode = .PPC32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = 4, mode = mode,
					   ops = {op_reg(rd), op_reg(ra), op_imm(v), {}}}
}

@(require_results)
inst_r_r_r_r :: #force_inline proc "contextless" (m: Mnemonic, rd, ra, rb, rc: Register, mode: Mode = .PPC32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 4, length = 4, mode = mode,
					   ops = {op_reg(rd), op_reg(ra), op_reg(rb), op_reg(rc)}}
}

// Memory load/store: RT, [RA + disp] or [RA + RB].
@(require_results)
inst_load :: #force_inline proc "contextless" (m: Mnemonic, rt: Register, mm: Memory, mode: Mode = .PPC32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4, mode = mode,
					   ops = {op_reg(rt), op_mem(mm), {}, {}}}
}
@(require_results)
inst_store :: #force_inline proc "contextless" (m: Mnemonic, rs: Register, mm: Memory, mode: Mode = .PPC32) -> Instruction {
	return inst_load(m, rs, mm, mode)
}

// Branches with label resolution
@(require_results)
inst_branch :: #force_inline proc "contextless" (m: Mnemonic, label_id: u32, mode: Mode = .PPC32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, length = 4, mode = mode,
					   ops = {op_label(label_id), {}, {}, {}}}
}

// Conditional branch with BO/BI baked into the mnemonic (BEQ/BNE/...) + label
@(require_results)
inst_branch_cond :: #force_inline proc "contextless" (m: Mnemonic, crf: Register, label_id: u32, mode: Mode = .PPC32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = 4, mode = mode,
					   ops = {op_reg(crf), op_label(label_id), {}, {}}}
}

// Flag setters
@(require_results)
inst_set_rc :: #force_inline proc "contextless" (inst: Instruction) -> Instruction {
	out := inst
	out.flags.sets_cr0 = true
	return out
}
@(require_results)
inst_set_oe :: #force_inline proc "contextless" (inst: Instruction) -> Instruction {
	out := inst
	out.flags.has_oe = true
	return out
}
@(require_results)
inst_set_lk :: #force_inline proc "contextless" (inst: Instruction) -> Instruction {
	out := inst
	out.flags.lk = true
	return out
}
