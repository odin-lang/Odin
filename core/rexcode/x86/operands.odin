package rexcode_x86

// =============================================================================
// SECTION: 2. OPERANDS
// =============================================================================

// -----------------------------------------------------------------------------
// SECTION: 2.1 Operand Kind Enum
// -----------------------------------------------------------------------------

Operand_Kind :: enum u8 {
	NONE,
	REGISTER,   // register operand
	MEMORY,     // memory operand
	IMMEDIATE,  // immediate value
	RELATIVE,   // relative offset (for jumps/calls)
}

// -----------------------------------------------------------------------------
// SECTION: 2.2 Memory Operand - Packed Representation
// -----------------------------------------------------------------------------

MEM_BASE_RIP  :: 30
MEM_BASE_NONE :: 31
MEM_INDEX_NONE :: 31

Memory :: bit_field u64 {
	base_hw:            u8   | 5,
	base_ext:           bool | 1,
	index_hw:           u8   | 5,
	index_ext:          bool | 1,
	scale_enc:          u8   | 2,
	disp:               i32  | 32,
	segment:            u8   | 3,
	addr_size_override: bool | 1,
	base_class:         u8   | 5,
	index_class:        u8   | 5,
}

mem_make :: proc "contextless" (base: Register, index: Register, scale: u8, disp: i32, segment: Register) -> Memory {
	mem: Memory = ---
	mem.base_hw = MEM_BASE_NONE
	mem.base_ext = false
	mem.base_class = 0
	if base == RIP {
		mem.base_hw = MEM_BASE_RIP
	} else if base != NONE {
		mem.base_hw = reg_hw(base)
		mem.base_ext = reg_needs_rex(base)
		mem.base_class = u8((u16(base) >> 8) & 0x1F)
	}

	mem.index_hw = MEM_INDEX_NONE
	mem.index_ext = false
	mem.index_class = 0
	if index != NONE {
		mem.index_hw = reg_hw(index)
		mem.index_ext = reg_needs_rex(index)
		mem.index_class = u8((u16(index) >> 8) & 0x1F)
	}

	switch scale {
	case 1: mem.scale_enc = 0
	case 2: mem.scale_enc = 1
	case 4: mem.scale_enc = 2
	case 8: mem.scale_enc = 3
	case:   mem.scale_enc = 0
	}

	mem.segment = 0
	if segment != NONE && reg_class(segment) == REG_SEG {
		mem.segment = reg_hw(segment) + 1
	}

	mem.disp = disp

	return mem
}

// -----------------------------------------------------------------------------
// SECTION: 2.3 Memory Utility Functions
// -----------------------------------------------------------------------------

@(require_results)
mem_scale :: #force_inline proc "contextless" (m: Memory) -> u8 {
	return 1 << m.scale_enc
}

@(require_results)
mem_is_rip_relative :: #force_inline proc "contextless" (m: Memory) -> bool {
	return m.base_hw == MEM_BASE_RIP
}

@(require_results)
mem_has_base :: #force_inline proc "contextless" (m: Memory) -> bool {
	return m.base_hw != MEM_BASE_NONE
}

@(require_results)
mem_has_index :: #force_inline proc "contextless" (m: Memory) -> bool {
	return m.index_hw != MEM_INDEX_NONE
}

@(require_results)
mem_base :: proc "contextless" (m: Memory) -> Register {
	if m.base_hw == MEM_BASE_NONE { return NONE }
	if m.base_hw == MEM_BASE_RIP { return RIP }
	class := u16(m.base_class) << 8
	return Register(class | u16(m.base_hw))
}

@(require_results)
mem_index :: proc "contextless" (m: Memory) -> Register {
	if m.index_hw == MEM_INDEX_NONE { return NONE }
	class := u16(m.index_class) << 8
	return Register(class | u16(m.index_hw))
}


// -----------------------------------------------------------------------------
// SECTION: 2.4 Memory Convenience Constructors
// -----------------------------------------------------------------------------

// Convenience constructors for common memory patterns
@(require_results)
mem_base_only :: #force_inline proc "contextless" (base: Register) -> Memory {
	return mem_make(base, NONE, 1, 0, NONE)
}

@(require_results)
mem_base_disp :: #force_inline proc "contextless" (base: Register, disp: i32) -> Memory {
	return mem_make(base, NONE, 1, disp, NONE)
}

@(require_results)
mem_base_index :: #force_inline proc "contextless" (base, index: Register, scale: u8) -> Memory {
	return mem_make(base, index, scale, 0, NONE)
}

@(require_results)
mem_base_index_disp :: #force_inline proc "contextless" (base, index: Register, scale: u8, disp: i32) -> Memory {
	return mem_make(base, index, scale, disp, NONE)
}

@(require_results)
mem_rip_disp :: #force_inline proc "contextless" (disp: i32) -> Memory {
	return mem_make(RIP, NONE, 1, disp, NONE)
}

// -----------------------------------------------------------------------------
// SECTION: 2.5 Operand struct and Flags
// -----------------------------------------------------------------------------

// The unified Operand type
Operand :: struct #packed {
	using _: struct #raw_union {
		reg:       Register, // for Register kind
		mem:       Memory,   // for Memory kind (packed)
		immediate: i64,      // for Immediate kind
		relative:  i64,      // for Relative kind (offset or label id)
	},
	kind:  Operand_Kind,
	size:  u8,           // operand size in bytes (1, 2, 4, 8, 16, 32, 64)
	flags: Operand_Flags,
	_:     [4]u8,
}
#assert(size_of(Operand) == 16)

// EVEX broadcast mode values for Operand_Flags.broadcast
// Used for EVEX instructions to broadcast a scalar element to all lanes
Broadcast :: enum u8 {
	NONE   = 0, // No broadcast (full vector load)
	B1TO2  = 1, // Broadcast 1 element to 2 (64-bit element to 128-bit vector)
	B1TO4  = 2, // Broadcast 1 element to 4 (32-bit to 128-bit, or 64-bit to 256-bit)
	B1TO8  = 3, // Broadcast 1 element to 8 (32-bit to 256-bit, or 64-bit to 512-bit)
	B1TO16 = 4, // Broadcast 1 element to 16 (32-bit to 512-bit)
}

Operand_Flags :: bit_field u16 {
	// EVEX-specific
	mask:      u8        | 3,           // opmask register K1-K7 (0 = no mask)
	zeroing:   bool      | 1,      // merge (0) vs zero (1) masking
	broadcast: Broadcast | 3, // broadcast mode (see Broadcast enum)
	er_sae:    u8        | 2,         // embedded rounding / SAE (0=none, 1=RN-SAE, 2=RD-SAE, 3=RU-SAE/RZ-SAE)
}

// -----------------------------------------------------------------------------
// SECTION: 2.6 Operand Constructors
// -----------------------------------------------------------------------------

// Operand constructors
@(require_results)
op_reg :: #force_inline proc "contextless" (r: Register) -> Operand {
	return Operand{reg = r, kind = .REGISTER, size = u8(reg_size(r) / 8)}
}

@(require_results)
op_mem :: #force_inline proc "contextless" (m: Memory, size: u8) -> Operand {
	return Operand{mem = m, kind = .MEMORY, size = size}
}

@(require_results)
op_mem_from_parts :: #force_inline proc "contextless" (
	base:  Register,
	index: Register,
	scale: u8,
	disp:  i32,
	size:  u8,
) -> Operand {
	return op_mem(mem_make(base, index, scale, disp, NONE), size)
}

// Generic immediate constructor — value + explicit byte size. The typed
// op_imm8/16/32/64 variants below are convenience wrappers.
@(require_results)
op_imm :: #force_inline proc "contextless" (v: i64, size: u8) -> Operand {
	return Operand{immediate = v, kind = .IMMEDIATE, size = size}
}

@(require_results)
op_imm8 :: #force_inline proc "contextless" (v: i8) -> Operand {
	return Operand{immediate = i64(v), kind = .IMMEDIATE, size = 1}
}

@(require_results)
op_imm16 :: #force_inline proc "contextless" (v: i16) -> Operand {
	return Operand{immediate = i64(v), kind = .IMMEDIATE, size = 2}
}

@(require_results)
op_imm32 :: #force_inline proc "contextless" (v: i32) -> Operand {
	return Operand{immediate = i64(v), kind = .IMMEDIATE, size = 4}
}

@(require_results)
op_imm64 :: #force_inline proc "contextless" (v: i64) -> Operand {
	return Operand{immediate = v, kind = .IMMEDIATE, size = 8}
}

@(require_results)
op_rel8 :: #force_inline proc "contextless" (offset: i8) -> Operand {
	return Operand{relative = i64(offset), kind = .RELATIVE, size = 1}
}

@(require_results)
op_rel32 :: #force_inline proc "contextless" (offset: i32) -> Operand {
	return Operand{relative = i64(offset), kind = .RELATIVE, size = 4}
}

// Create a relative operand referencing a label
@(require_results)
op_label :: #force_inline proc "contextless" (label_id: u32, size: u8 = 4) -> Operand {
	return Operand{relative = i64(label_id), kind = .RELATIVE, size = size}
}

// -----------------------------------------------------------------------------
// SECTION: 2.7 Typed Operand Constructors (compile-time type safety)
// -----------------------------------------------------------------------------
// These provide compile-time type safety: op_gpr64(.XMM0) is a compile error.
// The enum value IS the hardware number, so we just cast - no table lookup.

@(require_results)
op_gpr64 :: #force_inline proc "contextless" (r: GPR64) -> Operand {
	return Operand{reg = Register(REG_GPR64 | u16(r)), kind = .REGISTER, size = 8}
}

@(require_results)
op_gpr32 :: #force_inline proc "contextless" (r: GPR32) -> Operand {
	return Operand{reg = Register(REG_GPR32 | u16(r)), kind = .REGISTER, size = 4}
}

@(require_results)
op_gpr16 :: #force_inline proc "contextless" (r: GPR16) -> Operand {
	return Operand{reg = Register(REG_GPR16 | u16(r)), kind = .REGISTER, size = 2}
}

@(require_results)
op_gpr8 :: #force_inline proc "contextless" (r: GPR8) -> Operand {
	return Operand{reg = Register(REG_GPR8 | u16(r)), kind = .REGISTER, size = 1}
}

@(require_results)
op_gpr8h :: #force_inline proc "contextless" (r: GPR8H) -> Operand {
	return Operand{reg = Register(REG_GPR8H | u16(r)), kind = .REGISTER, size = 1}
}

@(require_results)
op_xmm :: #force_inline proc "contextless" (r: XMM) -> Operand {
	return Operand{reg = Register(REG_XMM | u16(r)), kind = .REGISTER, size = 16}
}

@(require_results)
op_ymm :: #force_inline proc "contextless" (r: YMM) -> Operand {
	return Operand{reg = Register(REG_YMM | u16(r)), kind = .REGISTER, size = 32}
}

@(require_results)
op_zmm :: #force_inline proc "contextless" (r: ZMM) -> Operand {
	return Operand{reg = Register(REG_ZMM | u16(r)), kind = .REGISTER, size = 64}
}

@(require_results)
op_kreg :: #force_inline proc "contextless" (r: KREG) -> Operand {
	return Operand{reg = Register(REG_K | u16(r)), kind = .REGISTER, size = 8}
}

@(require_results)
op_sreg :: #force_inline proc "contextless" (r: SREG) -> Operand {
	return Operand{reg = Register(REG_SEG | u16(r)), kind = .REGISTER, size = 2}
}

@(require_results)
op_mm :: #force_inline proc "contextless" (r: MM) -> Operand {
	return Operand{reg = Register(REG_MM | u16(r)), kind = .REGISTER, size = 8}
}

@(require_results)
op_creg :: #force_inline proc "contextless" (r: CREG) -> Operand {
	return Operand{reg = Register(REG_CR | u16(r)), kind = .REGISTER, size = 8}
}

@(require_results)
op_dreg :: #force_inline proc "contextless" (r: DREG) -> Operand {
	return Operand{reg = Register(REG_DR | u16(r)), kind = .REGISTER, size = 8}
}

@(require_results)
op_st :: #force_inline proc "contextless" (r: ST) -> Operand {
	return Operand{reg = Register(REG_ST | u16(r)), kind = .REGISTER, size = 10}
}

@(require_results)
op_bnd :: #force_inline proc "contextless" (r: BND) -> Operand {
	return Operand{reg = Register(REG_BND | u16(r)), kind = .REGISTER, size = 16}
}
