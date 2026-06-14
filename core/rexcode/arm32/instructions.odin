package rexcode_arm32

// =============================================================================
// AArch32 INSTRUCTION
// =============================================================================
//
// Variable-length: A32 is always 4 bytes, T16 is 2 bytes, T32 is 4 bytes (two
// halfwords). The `length` field is filled in by the encoder from the matched
// Encoding entry's `bits` field via `inst_size_from_bits`.
//
// The `mode` field tells the encoder whether to dispatch to A32 or T32
// encoding entries; for VFP/NEON entries the encoder applies bit-28 swap as
// documented in encoding_types.odin.

Instruction_Flags :: bit_field u8 {
	sets_flags: bool | 1,   // S bit (writes APSR.NZCV)
	wide:       bool | 1,   // force T32 wide form when both T16 + T32 exist
	_:          u8   | 6,
}

Instruction :: struct #packed {
	ops:           [4]Operand `fmt:"v,operand_count"`, // 4 * 17 = 68
	mnemonic:      Mnemonic,                           // 2
	cond:          u8,                                 // 0..15 (AL=14)
	operand_count: u8,                                 // 0..4
	flags:         Instruction_Flags,                  // 1
	mode:          Mode,                               // 1 (A32 or T32)
	length:        u8,                                 // 2 or 4 bytes
	// Form-id hint: when non-zero, this is (1 + the index into
	// ENCODING_TABLE[mnemonic]) of the form the decoder produced. The encoder
	// uses it as a tie-breaker for shape-ambiguous entries (NEON size variants
	// share an operand shape but live in distinct entries with different fixed
	// bits). User-constructed instructions leave it at 0; the encoder then
	// falls back to first-shape-match. Stored as u16 over the two padding bytes.
	form_id:       u16,
}
// 68 + 9 = 77 bytes (packed)

// =============================================================================
// Builders
// =============================================================================

@(require_results)
inst_none :: #force_inline proc "contextless" (m: Mnemonic, mode: Mode = .A32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 0, length = mode == .A32 ? 4 : 2, mode = mode, cond = 14}
}

// 1-operand
@(require_results)
inst_r :: #force_inline proc "contextless" (m: Mnemonic, r: Register, mode: Mode = .A32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, length = mode == .A32 ? 4 : 4, mode = mode, cond = 14,
					   ops = {op_reg(r), {}, {}, {}}}
}
@(require_results)
inst_i :: #force_inline proc "contextless" (m: Mnemonic, v: i64, mode: Mode = .A32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, length = mode == .A32 ? 4 : 4, mode = mode, cond = 14,
					   ops = {op_imm(v), {}, {}, {}}}
}

// 2-operand
@(require_results)
inst_r_r :: #force_inline proc "contextless" (m: Mnemonic, rd, rm: Register, mode: Mode = .A32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = mode == .A32 ? 4 : 4, mode = mode, cond = 14,
					   ops = {op_reg(rd), op_reg(rm), {}, {}}}
}
@(require_results)
inst_r_i :: #force_inline proc "contextless" (m: Mnemonic, rd: Register, v: i64, mode: Mode = .A32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = mode == .A32 ? 4 : 4, mode = mode, cond = 14,
					   ops = {op_reg(rd), op_imm(v), {}, {}}}
}

// 3-operand data-proc (ADD/SUB/AND/etc.)
@(require_results)
inst_r_r_r :: #force_inline proc "contextless" (m: Mnemonic, rd, rn, rm: Register, mode: Mode = .A32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = mode == .A32 ? 4 : 4, mode = mode, cond = 14,
					   ops = {op_reg(rd), op_reg(rn), op_reg(rm), {}}}
}
@(require_results)
inst_r_r_i :: #force_inline proc "contextless" (m: Mnemonic, rd, rn: Register, v: i64, mode: Mode = .A32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = mode == .A32 ? 4 : 4, mode = mode, cond = 14,
					   ops = {op_reg(rd), op_reg(rn), op_imm(v), {}}}
}
@(require_results)
inst_r_r_r_shifted :: #force_inline proc "contextless" (
	m: Mnemonic, rd, rn, rm: Register, st: Shift_Type, amt: u8, mode: Mode = .A32,
) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 3, length = mode == .A32 ? 4 : 4, mode = mode, cond = 14,
					   ops = {op_reg(rd), op_reg(rn), op_reg_shifted(rm, st, amt), {}}}
}

// 4-operand MLA / MLS / SMLAL etc.
@(require_results)
inst_r_r_r_r :: #force_inline proc "contextless" (m: Mnemonic, rd, rn, rm, ra: Register, mode: Mode = .A32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 4, length = mode == .A32 ? 4 : 4, mode = mode, cond = 14,
					   ops = {op_reg(rd), op_reg(rn), op_reg(rm), op_reg(ra)}}
}

// Memory load/store
@(require_results)
inst_load :: #force_inline proc "contextless" (m: Mnemonic, rd: Register, mm: Memory, mode: Mode = .A32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = mode == .A32 ? 4 : 4, mode = mode, cond = 14,
					   ops = {op_reg(rd), op_mem(mm), {}, {}}}
}
@(require_results)
inst_store :: #force_inline proc "contextless" (m: Mnemonic, rd: Register, mm: Memory, mode: Mode = .A32) -> Instruction {
	return inst_load(m, rd, mm, mode)
}

// LDM/STM/PUSH/POP block move
@(require_results)
inst_block :: #force_inline proc "contextless" (m: Mnemonic, base: Register, mask: u16, mode: Mode = .A32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 2, length = mode == .A32 ? 4 : 4, mode = mode, cond = 14,
					   ops = {op_reg(base), op_reg_list(mask), {}, {}}}
}

// Branches with label
@(require_results)
inst_branch :: #force_inline proc "contextless" (m: Mnemonic, label_id: u32, mode: Mode = .A32) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 1, length = mode == .A32 ? 4 : 4, mode = mode, cond = 14,
					   ops = {op_label(label_id), {}, {}, {}}}
}

// Set condition code on any builder
@(require_results)
inst_set_cond :: #force_inline proc "contextless" (inst: Instruction, cond: u8) -> Instruction {
	out := inst
	out.cond = cond
	return out
}

// Set S flag (sets APSR.NZCV)
@(require_results)
inst_set_flags :: #force_inline proc "contextless" (inst: Instruction) -> Instruction {
	out := inst
	out.flags.sets_flags = true
	return out
}
