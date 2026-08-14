// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm32

// =============================================================================
// AArch32 OPERANDS
// =============================================================================
//
// Kind-tagged operand, same shape as other arches. Variations specific to
// AArch32:
//
//   * Memory operands carry a much richer payload than RISC-V: base GPR +
//     {imm | reg}-offset + shift {LSL/LSR/ASR/ROR/RRX} + pre/post indexing
//     + sign. We pack these into a single Memory struct.
//
//   * REGISTER operands always store a single Register byte; lane and shape
//     hints (e.g. D[idx]) ride in the `lane`/`shift_type` fields.
//
//   * IMMEDIATE i64 is wide enough for sign-extended branch displacements,
//     16-bit MOVW/MOVT immediates, modified-immediate raw values, and the
//     packed CDE/coproc imm fields.
//
//   * RELATIVE = label id (pre-resolution) or signed byte offset (post).
//
//   * REG_LIST is a 16-bit GPR bitmask packed into the immediate slot.

Operand_Kind :: enum u8 {
	NONE,
	REGISTER,
	IMMEDIATE,
	MEMORY,
	RELATIVE,
	REG_LIST,    // LDM/STM/PUSH/POP bitmask (low 16 bits = R0..R15)
}

// ---- Shift / addressing-mode helpers ---------------------------------------

Shift_Type :: enum u8 {
	LSL = 0,
	LSR = 1,
	ASR = 2,
	ROR = 3,
	RRX = 4,    // pseudo: encoded as ROR #0
	NONE = 5,
	// Register-shifted-register markers: the shift count comes from the Rs
	// register stored in shift_amt (0..15), not from an immediate. Encoder
	// packs bits 11..8 = Rs, 6..5 = (type - LSL_REG) low 2 bits, bit 4 = 1.
	LSL_REG = 6,
	LSR_REG = 7,
	ASR_REG = 8,
	ROR_REG = 9,
}

Index_Mode :: enum u8 {
	OFFSET     = 0,   // [Rn, #imm]      -- no writeback
	PRE_INDEX  = 1,   // [Rn, #imm]!     -- writeback after addr calc
	POST_INDEX = 2,   // [Rn], #imm      -- writeback, base = Rn pre-update
}

Memory :: struct #packed {
	base:       Register,    // GPR base register
	index:      Register,    // GPR or .NONE for imm-only forms
	shift_type: Shift_Type,
	shift_amt:  u8,          // 0..31 immediate shift
	mode:       Index_Mode,
	sign:       i8,          // +1 or -1 (U bit)
	disp:       i32,         // immediate displacement (sign-extended)
}
#assert(size_of(Memory) == 12)

@(require_results)
mem_imm     :: #force_inline proc "contextless" (base: Register, disp: i32) -> Memory {
	return Memory{base = base, disp = disp, sign = 1, mode = .OFFSET}
}
@(require_results)
mem_imm_pre :: #force_inline proc "contextless" (base: Register, disp: i32) -> Memory {
	return Memory{base = base, disp = disp, sign = 1, mode = .PRE_INDEX}
}
@(require_results)
mem_imm_post :: #force_inline proc "contextless" (base: Register, disp: i32) -> Memory {
	return Memory{base = base, disp = disp, sign = 1, mode = .POST_INDEX}
}
@(require_results)
mem_reg :: #force_inline proc "contextless" (base, index: Register, sign: i8 = 1) -> Memory {
	return Memory{base = base, index = index, sign = sign, mode = .OFFSET}
}
@(require_results)
mem_reg_shift :: #force_inline proc "contextless" (
	base, index: Register, st: Shift_Type, amt: u8, sign: i8 = 1,
) -> Memory {
	return Memory{base = base, index = index, shift_type = st, shift_amt = amt, sign = sign, mode = .OFFSET}
}

// ---- Operand structure -----------------------------------------------------

Operand :: struct #packed {
	using _: struct #raw_union #packed {
		reg:       Register,
		mem:       Memory,
		immediate: i64,
		relative:  i64,        // label id (pre) or signed byte offset (post)
	},
	kind:       Operand_Kind,
	size:       u8,
	shift_type: Shift_Type,   // for GPR_SHIFTED operands (otherwise NONE)
	shift_amt:  u8,           // immediate shift amount 0..31 (or Rs index for RSR)
	lane:       u8,           // SIMD lane index for DPR_ELEM / QPR_ELEM
	cond:       u8,           // condition code 0..15 (default = AL = 14)
}
#assert(size_of(Operand) == 18)

// ---- Operand builders ------------------------------------------------------

@(require_results)
op_reg :: #force_inline proc "contextless" (r: Register) -> Operand {
	return Operand{reg = r, kind = .REGISTER, size = 4, cond = 14}
}
@(require_results)
op_reg_shifted :: #force_inline proc "contextless" (
	r: Register, st: Shift_Type, amt: u8,
) -> Operand {
	return Operand{reg = r, kind = .REGISTER, size = 4, shift_type = st, shift_amt = amt, cond = 14}
}
@(require_results)
op_imm :: #force_inline proc "contextless" (v: i64, size: u8 = 4) -> Operand {
	return Operand{immediate = v, kind = .IMMEDIATE, size = size, cond = 14}
}
@(require_results)
op_mem :: #force_inline proc "contextless" (m: Memory) -> Operand {
	return Operand{mem = m, kind = .MEMORY, size = 4, cond = 14}
}
@(require_results)
op_label :: #force_inline proc "contextless" (label_id: u32, size: u8 = 4) -> Operand {
	return Operand{relative = i64(label_id), kind = .RELATIVE, size = size, cond = 14}
}
@(require_results)
op_rel_offset :: #force_inline proc "contextless" (off: i64) -> Operand {
	return Operand{relative = off, kind = .RELATIVE, size = 4, cond = 14}
}
@(require_results)
op_reg_list :: #force_inline proc "contextless" (mask: u16) -> Operand {
	return Operand{immediate = i64(mask), kind = .REG_LIST, size = 2, cond = 14}
}
@(require_results)
op_dpr_lane :: #force_inline proc "contextless" (d: Register, idx: u8) -> Operand {
	return Operand{reg = d, kind = .REGISTER, size = 4, lane = idx, cond = 14}
}
@(require_results)
op_qpr_lane :: #force_inline proc "contextless" (q: Register, idx: u8) -> Operand {
	return Operand{reg = q, kind = .REGISTER, size = 4, lane = idx, cond = 14}
}
