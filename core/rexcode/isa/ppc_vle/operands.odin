// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ppc_vle

// =============================================================================
// PowerPC VLE Operands
// =============================================================================

Operand_Kind :: enum u8 {
	NONE,
	REGISTER,
	IMMEDIATE,
	MEMORY,
	RELATIVE,
}

Memory :: struct #packed {
	base:  Register,
	index: Register,
	disp:  i64,
}
#assert(size_of(Memory) == 12)

@(require_results)
mem_d :: #force_inline proc "contextless" (base: Register, disp: i64) -> Memory {
	return Memory{base = base, index = NONE, disp = disp}
}
@(require_results)
mem_x :: #force_inline proc "contextless" (base, index: Register) -> Memory {
	return Memory{base = base, index = index, disp = 0}
}

Operand :: struct #packed {
	using _: struct #raw_union #packed {
		reg:       Register,
		mem:       Memory,
		immediate: i64,
		relative:  i64,
	},
	kind: Operand_Kind,
	size: u8,
}
#assert(size_of(Operand) == 14)

@(require_results)
op_reg :: #force_inline proc "contextless" (r: Register) -> Operand {
	return Operand{reg = r, kind = .REGISTER}
}
@(require_results)
op_imm :: #force_inline proc "contextless" (v: i64) -> Operand {
	return Operand{immediate = v, kind = .IMMEDIATE}
}
@(require_results)
op_mem :: #force_inline proc "contextless" (m: Memory) -> Operand {
	return Operand{mem = m, kind = .MEMORY}
}
@(require_results)
op_label :: #force_inline proc "contextless" (label_id: u32) -> Operand {
	return Operand{relative = i64(label_id), kind = .RELATIVE}
}
@(require_results)
op_rel_offset :: #force_inline proc "contextless" (off: i64) -> Operand {
	return Operand{relative = off, kind = .RELATIVE}
}
