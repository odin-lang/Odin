// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_x86

// =============================================================================
// SECTION: 3. INSTRUCTION
// =============================================================================

// -----------------------------------------------------------------------------
// SECTION: 3.1 Instruction Flags and Rep Prefix
// -----------------------------------------------------------------------------

// Instruction flags for prefixes and modifiers
Instruction_Flags :: bit_field u8 {
	lock:    bool | 1,
	rep:     Rep  | 2,
	segment: u8   | 3,    // 0=none, 1=ES, 2=CS, 3=SS, 4=DS, 5=FS, 6=GS
	addr32:  bool | 1,    // address size override (32-bit in 64-bit mode)
	data16:  bool | 1,    // operand size override (for 16-bit operands)
}

Rep :: enum u8 {
	NONE,
	REP,      // REP/REPE/REPZ
	REPNE,    // REPNE/REPNZ
}

// -----------------------------------------------------------------------------
// SECTION: 3.2 Instruction STruct
// -----------------------------------------------------------------------------

Instruction :: struct #packed {
	ops:           [4]Operand `fmt:"v,operand_count`, // 64 bytes
	mnemonic:      Mnemonic,                          // 2 bytes
	operand_count: u8,                                // 1 byte
	flags:         Instruction_Flags,                 // 1 byte
	length:        u8,                                // 1 byte (filled by decoder, used for iteration)
	_pad:          [3]u8,                             // 3 bytes
}
#assert(size_of(Instruction) == 72)

// -----------------------------------------------------------------------------
// SECTION: 7.9 Instruction Builder Helpers
// -----------------------------------------------------------------------------

// Convenient instruction builders for common patterns
@(require_results)
inst_r_r :: #force_inline proc "contextless" (mnemonic: Mnemonic, destination, source: Register) -> Instruction {
	return Instruction{
		mnemonic      = mnemonic,
		operand_count = 2,
		ops           = {op_reg(destination), op_reg(source), {}, {}},
	}
}

@(require_results)
inst_r_m :: #force_inline proc "contextless" (mnemonic: Mnemonic, destination: Register, source: Memory, size: u8) -> Instruction {
	return Instruction{
		mnemonic      = mnemonic,
		operand_count = 2,
		ops           = {op_reg(destination), op_mem(source, size), {}, {}},
	}
}

@(require_results)
inst_m_r :: #force_inline proc "contextless" (mnemonic: Mnemonic, destination: Memory, size: u8, source: Register) -> Instruction {
	return Instruction{
		mnemonic      = mnemonic,
		operand_count = 2,
		ops           = {op_mem(destination, size), op_reg(source), {}, {}},
	}
}

@(require_results)
inst_r_i :: #force_inline proc "contextless" (mnemonic: Mnemonic, destination: Register, immediate: i64, immediate_size: u8) -> Instruction {
	return Instruction{
		mnemonic      = mnemonic,
		operand_count = 2,
		ops           = {op_reg(destination), Operand{immediate = immediate, kind = .IMMEDIATE, size = immediate_size}, {}, {}},
	}
}

@(require_results)
inst_r :: #force_inline proc "contextless" (mnemonic: Mnemonic, r: Register) -> Instruction {
	return Instruction{
		mnemonic      = mnemonic,
		operand_count = 1,
		ops           = {op_reg(r), {}, {}, {}},
	}
}

@(require_results)
inst_m :: #force_inline proc "contextless" (mnemonic: Mnemonic, m: Memory, size: u8) -> Instruction {
	return Instruction{
		mnemonic      = mnemonic,
		operand_count = 1,
		ops           = {op_mem(m, size), {}, {}, {}},
	}
}

@(require_results)
inst_none :: #force_inline proc "contextless" (mnemonic: Mnemonic) -> Instruction {
	return Instruction{
		mnemonic      = mnemonic,
		operand_count = 0,
	}
}

@(require_results)
inst_rel :: #force_inline proc "contextless" (mnemonic: Mnemonic, label_id: u32, size: u8 = 4) -> Instruction {
	return Instruction{
		mnemonic      = mnemonic,
		operand_count = 1,
		ops           = {op_label(label_id, size), {}, {}, {}},
	}
}

// 3-operand register instructions (VEX/EVEX: VADDPS xmm0, xmm1, xmm2)
@(require_results)
inst_r_r_r :: #force_inline proc "contextless" (mnemonic: Mnemonic, destination, source1, source2: Register) -> Instruction {
	return Instruction{
		mnemonic      = mnemonic,
		operand_count = 3,
		ops           = {op_reg(destination), op_reg(source1), op_reg(source2), {}},
	}
}

// 3-operand register-register-memory (VEX/EVEX: VADDPS xmm0, xmm1, [mem])
@(require_results)
inst_r_r_m :: #force_inline proc "contextless" (mnemonic: Mnemonic, destination, source1: Register, source2: Memory, size: u8) -> Instruction {
	return Instruction{
		mnemonic      = mnemonic,
		operand_count = 3,
		ops           = {op_reg(destination), op_reg(source1), op_mem(source2, size), {}},
	}
}

// 3-operand register-register-immediate (e.g., SHLD r64, r64, imm8)
@(require_results)
inst_r_r_i :: #force_inline proc "contextless" (mnemonic: Mnemonic, destination, source: Register, immediate: i64, immediate_size: u8) -> Instruction {
	return Instruction{
		mnemonic      = mnemonic,
		operand_count = 3,
		ops           = {op_reg(destination), op_reg(source), Operand{immediate = immediate, kind = .IMMEDIATE, size = immediate_size}, {}},
	}
}

// Memoryory-immediate (MOV [mem], imm32)
@(require_results)
inst_m_i :: #force_inline proc "contextless" (mnemonic: Mnemonic, destination: Memory, size: u8, immediate: i64, immediate_size: u8) -> Instruction {
	return Instruction{
		mnemonic      = mnemonic,
		operand_count = 2,
		ops           = {op_mem(destination, size), Operand{immediate = immediate, kind = .IMMEDIATE, size = immediate_size}, {}, {}},
	}
}

// Single immediate (PUSH imm32, RET imm16, INT imm8, etc.)
@(require_results)
inst_i :: #force_inline proc "contextless" (mnemonic: Mnemonic, immediate: i64, immediate_size: u8) -> Instruction {
	return Instruction{
		mnemonic      = mnemonic,
		operand_count = 1,
		ops           = {Operand{immediate = immediate, kind = .IMMEDIATE, size = immediate_size}, {}, {}, {}},
	}
}

// 3-operand register-memory-immediate (IMUL r64, m64, imm32)
@(require_results)
inst_r_m_i :: #force_inline proc "contextless" (mnemonic: Mnemonic, destination: Register, source: Memory, mem_size: u8, immediate: i64, immediate_size: u8) -> Instruction {
	return Instruction{
		mnemonic      = mnemonic,
		operand_count = 3,
		ops           = {op_reg(destination), op_mem(source, mem_size), Operand{immediate = immediate, kind = .IMMEDIATE, size = immediate_size}, {}},
	}
}

// 3-operand memory-register-immediate (SHLD m64, r64, imm8)
@(require_results)
inst_m_r_i :: #force_inline proc "contextless" (mnemonic: Mnemonic, destination: Memory, mem_size: u8, source: Register, immediate: i64, immediate_size: u8) -> Instruction {
	return Instruction{
		mnemonic      = mnemonic,
		operand_count = 3,
		ops           = {op_mem(destination, mem_size), op_reg(source), Operand{immediate = immediate, kind = .IMMEDIATE, size = immediate_size}, {}},
	}
}

// Relative offset (JMP rel8, JCC rel32, etc.) - uses raw offset, not label
@(require_results)
inst_rel_offset :: #force_inline proc "contextless" (mnemonic: Mnemonic, offset: i64, offset_size: u8) -> Instruction {
	return Instruction{
		mnemonic      = mnemonic,
		operand_count = 1,
		ops           = {Operand{immediate = offset, kind = .RELATIVE, size = offset_size}, {}, {}, {}},
	}
}

// 3-operand register-memory-register (BEXTR r64, m64, r64)
@(require_results)
inst_r_m_r :: #force_inline proc "contextless" (mnemonic: Mnemonic, destination: Register, source1: Memory, mem_size: u8, source2: Register) -> Instruction {
	return Instruction{
		mnemonic      = mnemonic,
		operand_count = 3,
		ops           = {op_reg(destination), op_mem(source1, mem_size), op_reg(source2), {}},
	}
}

// 4-operand register instructions (EVEX with 4 operands)
@(require_results)
inst_r_r_r_r :: #force_inline proc "contextless" (mnemonic: Mnemonic, destination, source1, source2, source3: Register) -> Instruction {
	return Instruction{
		mnemonic      = mnemonic,
		operand_count = 4,
		ops           = {op_reg(destination), op_reg(source1), op_reg(source2), op_reg(source3)},
	}
}

// 4-operand: 3 registers + immediate (VCMPPS xmm, xmm, xmm, imm8)
@(require_results)
inst_r_r_r_i :: #force_inline proc "contextless" (mnemonic: Mnemonic, destination, source1, source2: Register, immediate: i64, immediate_size: u8) -> Instruction {
	return Instruction{
		mnemonic      = mnemonic,
		operand_count = 4,
		ops           = {op_reg(destination), op_reg(source1), op_reg(source2), Operand{immediate = immediate, kind = .IMMEDIATE, size = immediate_size}},
	}
}

// 4-operand: 2 registers + memory + immediate (VCMPPS xmm, xmm, m128, imm8)
@(require_results)
inst_r_r_m_i :: #force_inline proc "contextless" (mnemonic: Mnemonic, destination, source1: Register, source2: Memory, mem_size: u8, immediate: i64, immediate_size: u8) -> Instruction {
	return Instruction{
		mnemonic      = mnemonic,
		operand_count = 4,
		ops           = {op_reg(destination), op_reg(source1), op_mem(source2, mem_size), Operand{immediate = immediate, kind = .IMMEDIATE, size = immediate_size}},
	}
}

// 4-operand: 2 registers + memory + register (VBLENDVPS xmm, xmm, m128, xmm)
@(require_results)
inst_r_r_m_r :: #force_inline proc "contextless" (mnemonic: Mnemonic, destination, source1: Register, source2: Memory, mem_size: u8, source3: Register) -> Instruction {
	return Instruction{
		mnemonic      = mnemonic,
		operand_count = 4,
		ops           = {op_reg(destination), op_reg(source1), op_mem(source2, mem_size), op_reg(source3)},
	}
}
