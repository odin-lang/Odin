// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_rsp

// =============================================================================
// RSP OPERANDS
// =============================================================================
//
// Same shape as mips/operands.odin; the addition for the RSP is that
// vector operands carry an element selector. Memory comes in two
// flavours: scalar (base + 16-bit signed disp; standard MIPS) and
// vector (base + 7-bit element-scaled offset + element selector).

Operand_Kind :: enum u8 {
	NONE,
	REGISTER,
	VECTOR_REG,    // vector register with element selector
	MEMORY,
	VECTOR_MEM,    // vector memory: base + 7-bit offset + element selector
	IMMEDIATE,
	RELATIVE,
}

Memory :: struct #packed {
	base: Register,    // GPR base
	_:    u16,
	disp: i32,
}
#assert(size_of(Memory) == 8)

Vector_Mem :: struct #packed {
	base:    Register,    // GPR base
	element: u8,          // element selector (0-15; restricted by op)
	_:       u8,
	offset:  i32,         // -64..63 after element-size scaling
}
#assert(size_of(Vector_Mem) == 8)

@(require_results)
mem :: #force_inline proc "contextless" (base: Register, disp: i32) -> Memory {
	return Memory{base = base, disp = disp}
}

@(require_results)
vmem :: #force_inline proc "contextless" (base: Register, element: u8, offset: i32) -> Vector_Mem {
	return Vector_Mem{base = base, element = element, offset = offset}
}

// Operand: 16-byte tagged union.
Operand :: struct #packed {
	using _: struct #raw_union {
		reg:        Register,    // for REGISTER and VECTOR_REG
		mem:        Memory,
		vmem:       Vector_Mem,
		immediate:  i64,
		relative:   i64,
	},
	kind:    Operand_Kind,        // 1 byte
	size:    u8,                  // 1 byte
	element: u8,                  // 1 byte — for VECTOR_REG
	_:       [5]u8,
}
#assert(size_of(Operand) == 16)

@(require_results)
op_reg :: #force_inline proc "contextless" (r: Register) -> Operand {
	return Operand{reg = r, kind = .REGISTER, size = 4}
}

@(require_results)
op_vr :: #force_inline proc "contextless" (r: Register, element: u8 = 0) -> Operand {
	return Operand{reg = r, kind = .VECTOR_REG, size = 16, element = element}
}

@(require_results)
op_mem :: #force_inline proc "contextless" (m: Memory, size: u8) -> Operand {
	return Operand{mem = m, kind = .MEMORY, size = size}
}

@(require_results)
op_vmem :: #force_inline proc "contextless" (m: Vector_Mem, size: u8) -> Operand {
	return Operand{vmem = m, kind = .VECTOR_MEM, size = size}
}

@(require_results)
op_imm :: #force_inline proc "contextless" (v: i64, size: u8) -> Operand {
	return Operand{immediate = v, kind = .IMMEDIATE, size = size}
}

@(require_results)
op_label :: #force_inline proc "contextless" (label_id: u32) -> Operand {
	return Operand{relative = i64(label_id), kind = .RELATIVE, size = 4}
}
