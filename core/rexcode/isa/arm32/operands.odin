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
	// A modified immediate is a bit pattern an 8-bit field expands into, and
	// assemblers write it as one: in hex, or as a float when the expansion
	// produced one. The value is stored expanded either way -- for the float
	// it is the 32-bit pattern, which is what the encoder needs back.
	HEX_IMMEDIATE,
	FLOAT_IMMEDIATE,
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

// Packed into one word: this sits in every Operand, so its width is
// multiplied by four in every Instruction. Field syntax and composite
// literals are unchanged, so this is invisible to callers.
//
// A Register's raw value never exceeds REG_QPR|31 = 0x401F, so 15 bits hold
// one losslessly (index uses Register(0), not a high sentinel, for "absent").
// `disp` gets 19 bits (+/-262,143) against a worst case of 4,095 -- the imm12
// of an A32 load -- so there is ~64x headroom.
Memory :: bit_field u64 {
	base:       Register   | 15,  // GPR base register
	index:      Register   | 15,  // GPR, or Register(0) for imm-only forms
	shift_type: Shift_Type | 4,
	shift_amt:  u8         | 6,   // 0..32 -- LSR and ASR reach 32 through a zero field
	mode:       Index_Mode | 2,
	sign:       i8         | 3,   // +1 or -1 (U bit)
	disp:       i32        | 19,  // immediate displacement (sign-extended)
}
#assert(size_of(Memory) == 8)

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
		// A register operand's shift and lane ride WITH the register instead
		// of in the tail -- that is what keeps Operand at 10 bytes, and they
		// only ever apply to a register anyway. `using` means op.reg,
		// op.shift_type, op.shift_amt and op.lane still read and write
		// exactly as they did when these were separate fields.
		using _: bit_field u32 {
			reg:        Register   | 15,
			shift_type: Shift_Type | 4,   // GPR_SHIFTED; .LSL/0 when plain
			shift_amt:  u8         | 6,   // 0..32, or the Rs index for RSR
			lane:       u8         | 5,   // SIMD lane for DPR_ELEM / QPR_ELEM
			// Whether `lane` means anything. Lane 0 is a real index -- `d0[0]`
			// is not `d0` -- so it cannot be spelled by lane == 0.
			has_lane:   bool       | 1,
			// 1 bit spare
		},
		mem:       Memory,
		immediate: i64,
		relative:  i64,        // label id (pre) or signed byte offset (post)
	},
	kind:       Operand_Kind,
	size:       u8,
	// How the syntax writes this register as a list. `count` 0 means a plain
	// register. NEON structure loads also come in a spaced form that steps two
	// registers at a time -- `{d2, d4}` -- and a to-all-lanes form written
	// `{d2[]}`. A GPR list (`{r4, lr}`) is not a run at all and stays a
	// bitmask under REG_LIST.
	list: List_Shape,
}

List_Shape :: bit_field u8 {
	count:     u8   | 3,   // 0 = not a list, else 1..4
	stride:    u8   | 3,   // 1 for {d2, d3}, 2 for {d2, d4}
	all_lanes: bool | 1,   // `{d2[]}` -- loaded to every lane
}
#assert(size_of(Operand) == 11)

// ---- Operand builders ------------------------------------------------------

@(require_results)
op_reg :: #force_inline proc "contextless" (r: Register) -> Operand {
	return Operand{reg = r, kind = .REGISTER, size = 4}
}
@(require_results)
op_reg_shifted :: #force_inline proc "contextless" (
	r: Register, st: Shift_Type, amt: u8,
) -> Operand {
	return Operand{reg = r, kind = .REGISTER, size = 4, shift_type = st, shift_amt = amt}
}
@(require_results)
op_imm :: #force_inline proc "contextless" (v: i64, size: u8 = 4) -> Operand {
	return Operand{immediate = v, kind = .IMMEDIATE, size = size}
}
@(require_results)
op_hex_imm :: #force_inline proc "contextless" (v: u32) -> Operand {
	return Operand{immediate = i64(v), kind = .HEX_IMMEDIATE, size = 4}
}
@(require_results)
op_float_imm :: #force_inline proc "contextless" (bits: u32) -> Operand {
	return Operand{immediate = i64(bits), kind = .FLOAT_IMMEDIATE, size = 4}
}
@(require_results)
op_mem :: #force_inline proc "contextless" (m: Memory) -> Operand {
	return Operand{mem = m, kind = .MEMORY, size = 4}
}
@(require_results)
op_label :: #force_inline proc "contextless" (label_id: u32, size: u8 = 4) -> Operand {
	return Operand{relative = i64(label_id), kind = .RELATIVE, size = size}
}
@(require_results)
op_rel_offset :: #force_inline proc "contextless" (off: i64) -> Operand {
	return Operand{relative = off, kind = .RELATIVE, size = 4}
}
@(require_results)
op_reg_list :: #force_inline proc "contextless" (mask: u16) -> Operand {
	return Operand{immediate = i64(mask), kind = .REG_LIST, size = 2}
}

// The head of a register list, written `{d1, d2, d3}` (stride 1) or
// `{d2, d4}` (stride 2).
@(require_results)
op_reg_run :: #force_inline proc "contextless" (first: Register, count: u8, stride: u8 = 1, all_lanes := false) -> Operand {
	return Operand{reg = first, kind = .REGISTER, list = {count = count, stride = stride, all_lanes = all_lanes}}
}
@(require_results)
op_dpr_lane :: #force_inline proc "contextless" (d: Register, idx: u8) -> Operand {
	return Operand{reg = d, kind = .REGISTER, size = 4, lane = idx, has_lane = true}
}
@(require_results)
op_qpr_lane :: #force_inline proc "contextless" (q: Register, idx: u8) -> Operand {
	return Operand{reg = q, kind = .REGISTER, size = 4, lane = idx, has_lane = true}
}
