package rexcode_riscv

// =============================================================================
// RISC-V OPERANDS
// =============================================================================
//
// Same kind-tagged shape as the other arches. Memory is a single
// `(base GPR, signed 12-bit displacement)` pair -- RISC-V's only
// addressing mode is `disp12(base)`, with no index register, no scale,
// and no PC-relative form (PC-rel work is done by AUIPC + add/load pairs).
//
// RELATIVE operands cover both 13-bit branches (B-type) and 21-bit
// jumps (J-type); the encoding form's Operand_Encoding tells the
// encoder which scatter pattern to apply.

Operand_Kind :: enum u8 {
	NONE,
	REGISTER,
	IMMEDIATE,
	MEMORY,
	RELATIVE,
}

Memory :: struct #packed {
	base: Register,    // GPR base
	_:    u16,
	disp: i32,         // sign-extended 12-bit displacement
}
#assert(size_of(Memory) == 8)

@(require_results)
mem :: #force_inline proc "contextless" (base: Register, disp: i32) -> Memory {
	return Memory{base = base, disp = disp}
}

Operand :: struct #packed {
	using _: struct #raw_union {
		reg:       Register,    // REGISTER (int or FP)
		mem:       Memory,
		immediate: i64,
		relative:  i64,         // label id pre-resolution; byte offset post
	},
	kind: Operand_Kind,
	size: u8,
	_:   [6]u8,
}
#assert(size_of(Operand) == 16)

@(require_results)
op_reg    :: #force_inline proc "contextless" (r: Register)        -> Operand { return Operand{reg = r, kind = .REGISTER, size = 4} }
@(require_results)
op_imm    :: #force_inline proc "contextless" (v: i64, size: u8)   -> Operand { return Operand{immediate = v, kind = .IMMEDIATE, size = size} }
@(require_results)
op_mem    :: #force_inline proc "contextless" (m: Memory)          -> Operand { return Operand{mem = m,     kind = .MEMORY,    size = 4} }
@(require_results)
op_label  :: #force_inline proc "contextless" (label_id: u32, size: u8 = 2) -> Operand {
	return Operand{relative = i64(label_id), kind = .RELATIVE, size = size}
}
@(require_results)
op_rel_offset :: #force_inline proc "contextless" (off: i64) -> Operand {
	return Operand{relative = off, kind = .RELATIVE, size = 2}
}

// Typed constructors
@(require_results)
op_gpr :: #force_inline proc "contextless" (g: GPR) -> Operand {
	return Operand{reg = Register(REG_GPR | u16(g)), kind = .REGISTER, size = 4}
}
@(require_results)
op_fpr :: #force_inline proc "contextless" (f: FPR) -> Operand {
	return Operand{reg = Register(REG_FPR | u16(f)), kind = .REGISTER, size = 4}
}
