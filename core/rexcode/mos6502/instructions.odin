// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_mos6502

// =============================================================================
// INSTRUCTION
// =============================================================================
//
// Up to 3 operands per instruction (only the HuC6280 block-transfer ops
// actually use all three; the rest top out at two).

Instruction_Flags :: bit_field u8 {
	_: u8 | 8,
}

Instruction :: struct #packed {
	ops:           [3]Operand `fmt:"v,operand_count"`, // 30 bytes
	mnemonic:      Mnemonic,                           // 2
	operand_count: u8,                                 // 1
	flags:         Instruction_Flags,                  // 1
	length:        u8,                                 // 1 (filled by decoder; 1..7)
	_:             [1]u8,                              // 1
}
#assert(size_of(Instruction) == 36)

// =============================================================================
// Builders (mirror the contract: shape spelled out, comma-separated)
// =============================================================================

@(require_results)
inst_none :: #force_inline proc "contextless" (m: Mnemonic) -> Instruction {
	return Instruction{mnemonic = m, operand_count = 0, length = 1}
}

@(require_results)
inst_a :: #force_inline proc "contextless" (m: Mnemonic) -> Instruction {
	// Explicit accumulator (e.g. `ROL A`).  Encodes to 1 byte (opcode only)
	// and counts as 1 operand for the matcher.
	return Instruction{
		mnemonic = m, operand_count = 1, length = 1,
		ops = {op_reg(A), {}, {}},
	}
}

@(require_results)
inst_i :: #force_inline proc "contextless" (m: Mnemonic, imm: i64) -> Instruction {
	return Instruction{
		mnemonic = m, operand_count = 1, length = 2,
		ops = {op_imm8(imm), {}, {}},
	}
}

@(require_results)
inst_m :: #force_inline proc "contextless" (m: Mnemonic, mm: Memory) -> Instruction {
	return Instruction{
		mnemonic = m, operand_count = 1, length = 0,   // filled by encoder
		ops = {op_mem(mm), {}, {}},
	}
}

@(require_results)
inst_rel :: #force_inline proc "contextless" (m: Mnemonic, label_id: u32) -> Instruction {
	return Instruction{
		mnemonic = m, operand_count = 1, length = 2,
		ops = {op_label(label_id, 1), {}, {}},
	}
}

// BBR/BBS: zero-page byte + relative branch (3-byte encoding).
@(require_results)
inst_zp_rel :: #force_inline proc "contextless" (m: Mnemonic, zp: u8, label_id: u32) -> Instruction {
	return Instruction{
		mnemonic = m, operand_count = 2, length = 3,
		ops = {op_zp(zp), op_label(label_id, 1), {}},
	}
}

// HuC6280 TST # imm, addr  (3 or 4 bytes depending on addressing mode).
@(require_results)
inst_tst :: #force_inline proc "contextless" (m: Mnemonic, imm: i64, mm: Memory) -> Instruction {
	return Instruction{
		mnemonic = m, operand_count = 2, length = 0,
		ops = {op_imm8(imm), op_mem(mm), {}},
	}
}

// HuC6280 block transfer: src, dst, length (7-byte encoding).
@(require_results)
inst_block :: #force_inline proc "contextless" (m: Mnemonic, src, dst, length_val: u16) -> Instruction {
	return Instruction{
		mnemonic = m, operand_count = 3, length = 7,
		ops = {
			Operand{immediate = i64(src),        kind = .IMMEDIATE, size = 2},
			Operand{immediate = i64(dst),        kind = .IMMEDIATE, size = 2},
			Operand{immediate = i64(length_val), kind = .IMMEDIATE, size = 2},
		},
	}
}
