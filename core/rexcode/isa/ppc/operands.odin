// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ppc

// =============================================================================
// PowerPC OPERANDS
// =============================================================================
//
// Kind-tagged operand, same shape as other arches. PowerPC-specific notes:
//
//   * Memory operands cover D-form (RA + signed 16-bit displacement), DS-form
//     (RA + signed 14-bit displacement, scaled by 4), DQ-form (12-bit scaled
//     by 16), X-form (RA + RB indexed), and prefixed (34-bit signed offset).
//
//   * REGISTER operands carry a single Register; the encoder routes by
//     register class (GPR/FPR/VR/VSR/CR/SPR).
//
//   * IMMEDIATE i64 is wide enough for 34-bit prefixed immediates and the
//     signed branch displacements.
//
//   * RELATIVE = label id (pre-resolution) or signed byte offset (post).

Operand_Kind :: enum u8 {
	NONE,
	REGISTER,
	IMMEDIATE,
	MEMORY,
	RELATIVE,
}

// PowerPC memory operand. Covers all D / DS / DQ / X / prefixed forms.
Memory :: struct #packed {
	base:  Register,   // RA — base register (R0 may be literal zero in D-form)
	index: Register,   // RB for X-form indexed; NONE for D/DS/DQ-form
	disp:  i64,        // signed displacement (16/14/12 or 34-bit prefixed)
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
		relative:  i64,        // label id (pre) or signed byte offset (post)
	},
	kind: Operand_Kind,
	size: u8,                  // operand size in bytes (4 = word, 8 = dword)
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
