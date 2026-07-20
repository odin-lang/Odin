// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_mips

// =============================================================================
// MIPS ENCODER
// =============================================================================
//
// Fixed-width 4-byte encoding pipeline. Table-driven (single source of truth:
// ENCODING_TABLE) and zero-allocation on the hot path -- the caller owns
// every output buffer.
//
// Two-pass design (parallel to the x86 encoder):
//
//   PASS 1   - encode each instruction to a 32-bit word, write it to `code`
//              in the requested endianness, and record a pending Relocation
//              for every label-referencing operand (forward AND backward).
//
//   PASS 1.5 - rewrite label_defs[i] from instruction-index to byte-offset.
//              For fixed-width MIPS this is a trivial multiply-by-4 sweep
//              which the compiler vectorises.
//
//   PASS 2   - if `resolve == true`, walk the pending relocations and patch
//              every one whose target is now known. Patched entries are
//              dropped from `relocs`; unresolvable entries (forward-
//              referenced external symbols) remain for the linker.
//
// Hot-path style choices:
//
//   - `encode_one_inline`, `encoding_matches_inline`, `operand_matches_inline`,
//     `pack_operand_inline` are `#force_inline` so the per-instruction body
//     collapses into one straight-line block with full register usage --
//     no procedure-call overhead between table lookup and word store.
//
//   - The 4-operand loop in `encode_one_inline` is hand-unrolled, with a
//     NONE fast-path on each slot so the common (<=3-operand) instruction
//     short-circuits the tail.
//
//   - Operand packing uses a switch that the compiler renders as a jump
//     table -- same throughput as a procedure-pointer table without the
//     extra indirection layer.
//
//   - Word writes are byte-by-byte with constant shifts; the compiler
//     pattern-matches this to a single u32 store (plus a bswap on the
//     big-endian path) while keeping the alignment-agnostic []u8 API.

// Largest instruction we ever emit (MIPS is fixed at 4).
MAX_INST_SIZE :: 4

// Upper bound on bytes emitted for `n` instructions.
encode_max_code_size :: #force_inline proc "contextless" (instructions: []Instruction) -> int {
	return len(instructions) * MAX_INST_SIZE
}

// Upper bound on pending relocations for `n` instructions
// (each instruction has at most one label-referencing operand).
encode_max_relocation_count :: #force_inline proc "contextless" (instructions: []Instruction) -> int {
	return len(instructions)
}

// Pre-size the caller's encode outputs (code grown by length so code[:] is a
// valid emit target; relocs reserved by capacity) so the encode hot path never
// reallocates. Allocates no new buffers; pass nil to skip either array.
encode_reserve :: proc(code: ^[dynamic]u8, relocs: ^[dynamic]Relocation, instructions: []Instruction) {
	if code != nil {
		size := encode_max_code_size(instructions)
		if len(code) < size {
			resize(code, size)
		}
	}
	if relocs != nil {
		reserve(relocs, len(relocs) + encode_max_relocation_count(instructions))
	}
}

// =============================================================================
// encode()
// =============================================================================

encode :: proc(
	instructions: []Instruction,
	label_defs:   []Label_Definition,
	code:         []u8,
	relocs:       ^[dynamic]Relocation,
	errors:       ^[dynamic]Error,
	endianness:   Endianness = .BIG,
	resolve:      bool       = true,
	base_address: u64        = 0,
) -> (byte_count: u32, ok: bool) {
	n_inst := u32(len(instructions))
	if u32(len(code)) < n_inst * 4 {
		append(errors, Error{inst_idx = 0, code = .BUFFER_OVERFLOW})
		return
	}

	errors_start  := u32(len(errors))
	pending_start := u32(len(relocs))

	// ---- PASS 1 ------------------------------------------------------------
	for i in 0..<n_inst {
		inst := &instructions[i]
		word := encode_one_inline(inst, byte_count, u16(i), relocs, errors) or_return
		write_u32(code, byte_count, word, endianness)
		byte_count += 4
	}

	// ---- PASS 1.5: rewrite label_defs from inst-idx to byte-offset --------
	// For fixed-width MIPS, byte_offset = inst_idx * 4.
	for &ld in label_defs {
		if ld != LABEL_UNDEFINED {
			ld = Label_Definition(u32(ld) * 4)
		}
	}

	if !resolve {
		ok = u32(len(errors)) == errors_start
		return
	}

	// ---- PASS 2: resolve relocations ---------------------------------------
	n_relocs  := u32(len(relocs))
	write_idx := pending_start

	for read_idx in pending_start..<n_relocs {
		r := relocs[read_idx]
		if resolve_relocation_inline(code, label_defs, &r, endianness, base_address, errors) {
			continue   // resolved & patched -> drop
		}
		// unresolved -> keep
		if write_idx != read_idx {
			relocs[write_idx] = r
		}
		write_idx += 1
	}
	if write_idx != n_relocs {
		resize(relocs, int(write_idx))
	}

	ok = u32(len(errors)) == errors_start
	return
}

// =============================================================================
// Internal: encode one instruction into a 32-bit word
// =============================================================================

@(private="file")
encode_one_inline :: #force_inline proc(
	inst:     ^Instruction,
	pc:       u32,
	inst_idx: u16,
	relocs:   ^[dynamic]Relocation,
	errors:   ^[dynamic]Error,
) -> (word: u32, ok: bool) {
	if inst.mnemonic == .INVALID {
		append(errors, Error{inst_idx = u32(inst_idx), code = .INVALID_MNEMONIC})
		return 0, false
	}

	forms := encoding_forms(inst.mnemonic)
	if len(forms) == 0 {
		append(errors, Error{inst_idx = u32(inst_idx), code = .INVALID_MNEMONIC})
		return 0, false
	}

	// Find a matching form. Most mnemonics have exactly one.
	form: ^Encoding
	for &f in forms {
		if encoding_matches_inline(inst, &f) {
			form = &f
			break
		}
	}
	if form == nil {
		append(errors, Error{inst_idx = u32(inst_idx), code = .NO_MATCHING_ENCODING})
		return 0, false
	}

	word = form.bits

	// Pack the four operand slots. NONE-fast-path on each slot lets the
	// common case (<= 3 user operands) short-circuit the tail.
	if form.enc[0] != .NONE {
		word |= pack_operand_inline(&inst.ops[0], form.enc[0], pc, inst_idx, relocs)
	}
	if form.enc[1] != .NONE {
		word |= pack_operand_inline(&inst.ops[1], form.enc[1], pc, inst_idx, relocs)
	}
	if form.enc[2] != .NONE {
		word |= pack_operand_inline(&inst.ops[2], form.enc[2], pc, inst_idx, relocs)
	}
	if form.enc[3] != .NONE {
		word |= pack_operand_inline(&inst.ops[3], form.enc[3], pc, inst_idx, relocs)
	}

	return word, true
}

// -----------------------------------------------------------------------------
// Operand-type matcher
// -----------------------------------------------------------------------------

@(private="file")
encoding_matches_inline :: #force_inline proc "contextless" (
	inst: ^Instruction, form: ^Encoding,
) -> bool {
	return  operand_matches_inline(&inst.ops[0], form.ops[0]) &&
			operand_matches_inline(&inst.ops[1], form.ops[1]) &&
			operand_matches_inline(&inst.ops[2], form.ops[2]) &&
			operand_matches_inline(&inst.ops[3], form.ops[3])
}

@(private="file")
operand_matches_inline :: #force_inline proc "contextless" (
	op: ^Operand, ot: Operand_Type,
) -> bool {
	switch ot {
	case .NONE:
		return op.kind == .NONE
	case .GPR:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_GPR
	case .GPR_ZERO:
		return op.kind == .REGISTER && op.reg == ZERO
	case .FPR_S, .FPR_D, .FPR_W, .FPR_L, .FPR_PS:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_FPR
	case .FCR:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_FCR
	case .CP0_REG:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_CP0
	case .CP2_REG:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_CP2D
	case .CP2_CTRL:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_CP2C
	case .VFPU_S, .VFPU_P, .VFPU_T, .VFPU_Q, .VFPU_M_P, .VFPU_M_T, .VFPU_M_Q:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_VFPU
	case .MSA_VEC:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_MSA
	case .IMM5, .IMM16S, .IMM16U, .IMM20, .IMM26, .SEL, .FCC,
		 .GTE_SF, .GTE_MX, .GTE_V, .GTE_CV, .GTE_LM:
		return op.kind == .IMMEDIATE
	case .REL16, .REL21, .REL26, .REL_J26, .REL19, .REL18:
		return op.kind == .RELATIVE
	case .MEM:
		return op.kind == .MEMORY
	}
	return false
}

// -----------------------------------------------------------------------------
// Operand packer -- where each operand's bits land in the instruction word
// -----------------------------------------------------------------------------

@(private="file")
pack_operand_inline :: #force_inline proc(
	op:       ^Operand,
	enc:      Operand_Encoding,
	pc:       u32,
	inst_idx: u16,
	relocs:   ^[dynamic]Relocation,
) -> u32 {
	switch enc {
	case .NONE:
		return 0

	// Integer GPR slots (R-type / I-type rs/rt/rd).
	case .RS:
		return (u32(reg_hw(op.reg)) & 0x1F) << 21
	case .RT:
		return (u32(reg_hw(op.reg)) & 0x1F) << 16
	case .RD:
		return (u32(reg_hw(op.reg)) & 0x1F) << 11
	case .SHAMT:
		return (u32(op.immediate) & 0x1F) << 6

	// FPU register slots (COP1 FR-format; bit positions overlap RT/RD/SHAMT).
	case .FT:
		return (u32(reg_hw(op.reg)) & 0x1F) << 16
	case .FS:
		return (u32(reg_hw(op.reg)) & 0x1F) << 11
	case .FD:
		return (u32(reg_hw(op.reg)) & 0x1F) << 6

	// Immediates.
	case .IMM_16:
		return u32(op.immediate) & 0xFFFF
	case .IMM_5:
		return (u32(op.immediate) & 0x1F) << 6
	case .IMM_20:
		return (u32(op.immediate) & 0xFFFFF) << 6
	case .IMM_26:
		// J/JAL use this with a RELATIVE operand (label target).
		// SYSCALL/BREAK/SDBBP use IMM_20 instead, so IMM_26 with an
		// IMMEDIATE operand only occurs for hand-built region jumps.
		if op.kind == .RELATIVE {
			append(relocs, Relocation{
				offset = pc, label_id = u32(op.relative),
				type = .J26, size = 4, inst_idx = inst_idx,
			})
			return 0
		}
		return u32(op.immediate) & 0x3FFFFFF

	// Memory: rs(base) at bits 25-21 + imm16(disp) at bits 15-0.
	case .OFFSET_BASE:
		return ((u32(reg_hw(op.mem.base)) & 0x1F) << 21) | (u32(op.mem.disp) & 0xFFFF)

	// PC-relative -- emit a relocation; pass 2 patches the immediate field.
	case .BRANCH_16:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .REL16, size = 4, inst_idx = inst_idx,
		})
		return 0
	case .BRANCH_21:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .REL21, size = 4, inst_idx = inst_idx,
		})
		return 0
	case .BRANCH_26:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .REL26, size = 4, inst_idx = inst_idx,
		})
		return 0
	case .BRANCH_19:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .REL_PC19, size = 4, inst_idx = inst_idx,
		})
		return 0
	case .BRANCH_18:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .REL_PC18, size = 4, inst_idx = inst_idx,
		})
		return 0

	// FP condition-code field (BC1*, MOVF/MOVT, C.cond.fmt).
	case .FCC_BC:
		return (u32(op.immediate) & 0x7) << 18
	case .FCC_CC:
		return (u32(op.immediate) & 0x7) << 8

	// COP0 selector (R2+).
	case .SEL:
		return u32(op.immediate) & 0x7

	// Implicit operand -- bits already baked into form.bits.
	case .IMPL:
		return 0

	// GTE cofun sub-fields (bit positions within the 25-bit cofun field).
	case .GTE_SF_BIT:
		return (u32(op.immediate) & 0x1) << 19
	case .GTE_MX_BITS:
		return (u32(op.immediate) & 0x3) << 17
	case .GTE_V_BITS:
		return (u32(op.immediate) & 0x3) << 15
	case .GTE_CV_BITS:
		return (u32(op.immediate) & 0x3) << 13
	case .GTE_LM_BIT:
		return (u32(op.immediate) & 0x1) << 10

	// VFPU register slots: 7-bit register IDs.
	case .VFPU_VD:
		return (u32(reg_vfpu_hw(op.reg)) & 0x7F) << 0
	case .VFPU_VS:
		return (u32(reg_vfpu_hw(op.reg)) & 0x7F) << 8
	case .VFPU_VT:
		return (u32(reg_vfpu_hw(op.reg)) & 0x7F) << 16

	// VFPU memory-form register: 7-bit ID split as top-5 at bits 20:16
	// and low-2 at bits 1:0.
	case .VFPU_VT_MEM:
		hw := u32(reg_vfpu_hw(op.reg)) & 0x7F
		return ((hw >> 2) & 0x1F) << 16 | (hw & 0x3) << 0

	// VFPU SP-style memory: base GPR at 25:21 + 16-bit signed disp at 15:2.
	case .VFPU_OFFSET_BASE:
		base := (u32(reg_hw(op.mem.base)) & 0x1F) << 21
		// disp stored as bytes; bits 15:2 hold disp (low 2 forced to 0).
		return base | (u32(op.mem.disp) & 0xFFFC)

	// VFPU prefix 20-bit immediate at bits 19:0.
	case .VFPU_PFX:
		return u32(op.immediate) & 0xFFFFF

	// VFPU constant selector / 5-bit immediate at bits 20:16.
	case .VFPU_CONST:
		return (u32(op.immediate) & 0x1F) << 16

	// VFPU 4-bit condition code at bits 3:0.
	case .VFPU_COND4:
		return u32(op.immediate) & 0xF

	// VFPU 3-bit VCC selector at bits 18:16.
	case .VFPU_CC3:
		return (u32(op.immediate) & 0x7) << 18

	// MSA 3R-format register slots.
	case .WD:
		return (u32(reg_hw(op.reg)) & 0x1F) << 6
	case .WS:
		return (u32(reg_hw(op.reg)) & 0x1F) << 11
	case .WT:
		return (u32(reg_hw(op.reg)) & 0x1F) << 16

	// MSA immediates / displacements.
	case .MSA_I5:
		return (u32(op.immediate) & 0x1F) << 16
	case .MSA_S10:
		return (u32(op.immediate) & 0x3FF) << 16
	case .MSA_BIT5:
		return (u32(op.immediate) & 0x1F) << 11
	case .MSA_BIT_SHIFT, .MSA_ELM_IDX:
		// The marker (data format) is fixed in `bits`; the operand drives the
		// low bits of the shift/index field at bit 16.
		return (u32(op.immediate) & 0x3F) << 16
	case .MSA_I8:
		return (u32(op.immediate) & 0xFF) << 16
	case .FR:
		return (u32(reg_hw(op.reg)) & 0x1F) << 21
	case .GPR_AT_6:
		return (u32(reg_hw(op.reg)) & 0x1F) << 6
	case .GPR_AT_11:
		return (u32(reg_hw(op.reg)) & 0x1F) << 11
	case .DSP_SA:
		return (u32(op.immediate) & 0xF) << 21
	case .RS_RT:
		r := u32(reg_hw(op.reg)) & 0x1F
		return r << 21 | r << 16
	case .AC_NUM:
		return (u32(op.immediate) & 0x3) << 11
	case .SHILO_IMM:
		return (u32(op.immediate) & 0x3F) << 20
	case .EXT_SIZE:
		return (u32(op.immediate) & 0x1F) << 21

	// MSA memory operand: base GPR at 15:11, signed-10 disp at 25:16
	// (caller has already scaled the displacement by element size).
	case .MSA_OFFSET_BASE_B, .MSA_OFFSET_BASE_H, .MSA_OFFSET_BASE_W, .MSA_OFFSET_BASE_D:
		shift: u32 = 0
		#partial switch enc {
		case .MSA_OFFSET_BASE_H: shift = 1
		case .MSA_OFFSET_BASE_W: shift = 2
		case .MSA_OFFSET_BASE_D: shift = 3
		}
		base_bits := (u32(reg_hw(op.mem.base)) & 0x1F) << 11
		imm_bits  := ((u32(op.mem.disp) >> shift) & 0x3FF) << 16
		return base_bits | imm_bits
	}
	return 0
}

// =============================================================================
// Pass 2 -- relocation resolver
// =============================================================================

@(private="file")
resolve_relocation_inline :: #force_inline proc(
	code:         []u8,
	label_defs:   []Label_Definition,
	relocation:   ^Relocation,
	endianness:   Endianness,
	base_address: u64,
	errors:       ^[dynamic]Error,
) -> bool {
	if int(relocation.label_id) >= len(label_defs) {
		return false   // bogus label id -- keep as unresolved (linker can fix)
	}
	ld := label_defs[relocation.label_id]
	if ld == LABEL_UNDEFINED {
		return false   // not defined yet -- keep
	}
	target := u32(ld)

	word := read_u32(code, relocation.offset, endianness)

	switch relocation.type {
	case .REL16:
		rel := i32(target) - i32(relocation.offset) - 4
		if rel & 3 != 0 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		rel >>= 2
		if rel < -32768 || rel > 32767 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		word = (word &~ 0xFFFF) | (u32(rel) & 0xFFFF)

	case .REL21:
		rel := i32(target) - i32(relocation.offset) - 4
		if rel & 3 != 0 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		rel >>= 2
		if rel < -(1<<20) || rel > (1<<20)-1 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		word = (word &~ 0x1FFFFF) | (u32(rel) & 0x1FFFFF)

	case .REL26:
		rel := i32(target) - i32(relocation.offset) - 4
		if rel & 3 != 0 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		rel >>= 2
		if rel < -(1<<25) || rel > (1<<25)-1 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		word = (word &~ 0x3FFFFFF) | (u32(rel) & 0x3FFFFFF)

	case .REL_PC19:
		// R6 PC-relative load: offset is relative to the instruction's own
		// address (no delay-slot adjustment), scaled by 4, 19-bit signed.
		rel := i32(target) - i32(relocation.offset)
		if rel & 3 != 0 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		rel >>= 2
		if rel < -(1<<18) || rel > (1<<18)-1 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		word = (word &~ 0x7FFFF) | (u32(rel) & 0x7FFFF)

	case .REL_PC18:
		// LDPC: relative to the instruction's address aligned down to 8, scaled
		// by 8, 18-bit signed.
		rel := i32(target) - (i32(relocation.offset) &~ i32(7))
		if rel & 7 != 0 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		rel >>= 3
		if rel < -(1<<17) || rel > (1<<17)-1 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		word = (word &~ 0x3FFFF) | (u32(rel) & 0x3FFFF)

	case .J26:
		// J/JAL: target = ((PC+4)[31:28] << 28) | (encoded_field << 2)
		if target & 3 != 0 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		target_abs := base_address + u64(target)
		next_pc    := base_address + u64(relocation.offset) + 4
		if (u32(next_pc) >> 28) != (u32(target_abs) >> 28) {
			// Region crossing -- J cannot reach a different 256MB region.
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		word = (word &~ 0x3FFFFFF) | (u32(target_abs >> 2) & 0x3FFFFFF)

	case .NONE, .HI16, .LO16:
		// %hi/%lo absolute pairs are not auto-resolved yet (the user
		// supplies raw IMM_16 today; no syntactic %hi()/%lo()).
		return false
	}

	write_u32(code, relocation.offset, word, endianness)
	return true
}

// =============================================================================
// Endian-aware u32 read/write
// =============================================================================
//
// Byte-wise stores with constant shifts: the compiler folds these into one
// u32 store (and a bswap on the big-endian path for little-endian hosts),
// without requiring the []u8 output buffer to be 4-byte aligned.

write_u32 :: #force_inline proc "contextless" (
	code: []u8, offset: u32, word: u32, endianness: Endianness,
) {
	if endianness == .LITTLE {
		code[offset+0] = u8(word)
		code[offset+1] = u8(word >> 8)
		code[offset+2] = u8(word >> 16)
		code[offset+3] = u8(word >> 24)
	} else {
		code[offset+0] = u8(word >> 24)
		code[offset+1] = u8(word >> 16)
		code[offset+2] = u8(word >> 8)
		code[offset+3] = u8(word)
	}
}

read_u32 :: #force_inline proc "contextless" (
	code: []u8, offset: u32, endianness: Endianness,
) -> u32 {
	if endianness == .LITTLE {
		return  u32(code[offset+0])        |
			   (u32(code[offset+1]) <<  8) |
			   (u32(code[offset+2]) << 16) |
			   (u32(code[offset+3]) << 24)
	}
	return  (u32(code[offset+0]) << 24) |
			(u32(code[offset+1]) << 16) |
			(u32(code[offset+2]) <<  8) |
			 u32(code[offset+3])
}

// =============================================================================
// Bulk endian conversion (callable separately for re-targeting an already-
// encoded buffer; uses a plain loop the compiler vectorises).
// =============================================================================

// In-place 32-bit byte-swap of `code`. Length must be a multiple of 4.
// Useful for switching a freshly-encoded buffer from native to wire endian
// when the consumer wants a single endian-conversion sweep after encoding.
swap_bytes_u32_inplace :: proc(code: []u8) {
	n := len(code) / 4
	for i in 0..<n {
		off := i * 4
		b0 := code[off+0]
		b1 := code[off+1]
		b2 := code[off+2]
		b3 := code[off+3]
		code[off+0] = b3
		code[off+1] = b2
		code[off+2] = b1
		code[off+3] = b0
	}
}
