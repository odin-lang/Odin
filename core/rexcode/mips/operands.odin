package rexcode_mips

// =============================================================================
// OPERANDS
// =============================================================================
//
// MIPS operand model: simpler than x86's. Every operand is one of
// REGISTER / MEMORY / IMMEDIATE / RELATIVE. Memory is always
// `disp(base)` -- one GPR plus a signed 16-bit displacement. The
// encoder decomposes memory operands into their RS+IMM16 fields when
// assembling the instruction word.

Operand_Kind :: enum u8 {
	NONE,
	REGISTER,
	MEMORY,
	IMMEDIATE,
	RELATIVE,    // PC-relative target (label or raw offset)
}

// Memory operand: GPR base + signed 16-bit displacement. Stored with a
// 32-bit disp slot to make the type comfortable to construct, even
// though only -32768..32767 actually encode.
Memory :: struct #packed {
	base: Register,    // 2 bytes
	_:    u16,         // 2 bytes pad (keeps the struct power-of-two)
	disp: i32,         // 4 bytes
}
#assert(size_of(Memory) == 8)

mem :: #force_inline proc "contextless" (base: Register, disp: i32) -> Memory {
	return Memory{base = base, disp = disp}
}

// Convenience aliases that mirror x86's naming convention so cross-arch
// helper code reads the same.
mem_base_disp :: mem
mem_base_only :: #force_inline proc "contextless" (base: Register) -> Memory {
	return Memory{base = base, disp = 0}
}

mem_base :: #force_inline proc "contextless" (m: Memory) -> Register {
	return m.base
}

mem_disp :: #force_inline proc "contextless" (m: Memory) -> i32 {
	return m.disp
}

// Operand: kind-tagged union, 16 bytes.
Operand :: struct #packed {
	using _: struct #raw_union {
		reg:       Register,    // 2 bytes
		mem:       Memory,      // 8 bytes
		immediate: i64,         // 8 bytes
		relative:  i64,         // 8 bytes (label id when unresolved, byte offset when resolved)
	},
	kind: Operand_Kind,         // 1 byte
	size: u8,                   // 1 byte — width hint in bytes (4 = word, 8 = dword, etc.)
	_:    [6]u8,                // 6 bytes
}
#assert(size_of(Operand) == 16)

// -----------------------------------------------------------------------------
// Generic operand constructors
// -----------------------------------------------------------------------------

op_reg :: #force_inline proc "contextless" (r: Register) -> Operand {
	return Operand{reg = r, kind = .REGISTER, size = 4}
}

op_reg_sized :: #force_inline proc "contextless" (r: Register, size: u8) -> Operand {
	return Operand{reg = r, kind = .REGISTER, size = size}
}

op_mem :: #force_inline proc "contextless" (m: Memory, size: u8) -> Operand {
	return Operand{mem = m, kind = .MEMORY, size = size}
}

op_imm :: #force_inline proc "contextless" (v: i64, size: u8) -> Operand {
	return Operand{immediate = v, kind = .IMMEDIATE, size = size}
}

// Branch/jump target operand. `label_id` indexes a Label_Definition
// array (resolved by the encoder during pass 2 -- same model as x86).
op_label :: #force_inline proc "contextless" (label_id: u32) -> Operand {
	return Operand{relative = i64(label_id), kind = .RELATIVE, size = 4}
}

// Raw offset (skip label resolution).
op_rel_offset :: #force_inline proc "contextless" (offset: i64) -> Operand {
	return Operand{relative = offset, kind = .RELATIVE, size = 4}
}

// -----------------------------------------------------------------------------
// Typed register operand constructors (compile-time class safety)
// -----------------------------------------------------------------------------

op_gpr :: #force_inline proc "contextless" (g: GPR) -> Operand {
	return Operand{reg = Register(REG_GPR | u16(g)), kind = .REGISTER, size = 4}
}

op_fpr :: #force_inline proc "contextless" (f: FPR) -> Operand {
	return Operand{reg = Register(REG_FPR | u16(f)), kind = .REGISTER, size = 4}
}

op_cp0 :: #force_inline proc "contextless" (c: CP0_Reg) -> Operand {
	return Operand{reg = Register(REG_CP0 | u16(c)), kind = .REGISTER, size = 4}
}

op_gte_data :: #force_inline proc "contextless" (r: GTE_DataReg) -> Operand {
	return Operand{reg = Register(REG_CP2D | u16(r)), kind = .REGISTER, size = 4}
}

op_gte_ctrl :: #force_inline proc "contextless" (r: GTE_CtrlReg) -> Operand {
	return Operand{reg = Register(REG_CP2C | u16(r)), kind = .REGISTER, size = 4}
}
