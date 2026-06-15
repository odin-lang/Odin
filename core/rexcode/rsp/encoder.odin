// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_rsp

// =============================================================================
// N64 RSP ENCODER
// =============================================================================
//
// Mirrors mips/encoder.odin's two-pass design: pass 1 encodes each
// instruction to a u32 word and emits Relocation entries for label-
// referencing operands; pass 1.5 rewrites label_defs from instruction-
// index to byte-offset; pass 2 patches resolvable relocations.
//
// What's different from mips/:
//   - The Operand model carries a `element: u8` for vector-register
//     operands (VR_ELEM kind) and a Vector_Mem variant for vector L/S.
//   - Operand encodings VT and VBASE pack *multiple* word fields from a
//     single operand: VT pulls vt + element from a VR_ELEM operand;
//     VBASE pulls base + element + offset from a VECTOR_MEM operand.
//   - No COP1 / FPU paths -- RSP has no FPU.

MAX_INST_SIZE :: 4

encode_max_code_size :: #force_inline proc "contextless" (n: int) -> int {
	return n * 4
}

encode_max_relocation_count :: #force_inline proc "contextless" (n: int) -> int {
	return n
}

encode :: proc(
	instructions: []Instruction,
	label_defs:   []Label_Definition,
	code:         []u8,
	relocs:       ^[dynamic]Relocation,
	errors:       ^[dynamic]Error,
	endianness:   Endianness = .BIG,
	resolve:      bool       = true,
	base_address: u64        = 0,
) -> Result {
	n_inst := u32(len(instructions))
	if u32(len(code)) < n_inst * 4 {
		append(errors, Error{inst_idx = 0, code = .BUFFER_OVERFLOW})
		return Result{byte_count = 0, success = false}
	}

	errors_start  := u32(len(errors))
	pending_start := u32(len(relocs))
	pc: u32       = 0

	for i in 0..<n_inst {
		inst := &instructions[i]
		word, ok := encode_one_inline(inst, pc, u16(i), relocs, errors)
		if !ok {
			return Result{byte_count = pc, success = false}
		}
		write_u32(code, pc, word, endianness)
		pc += 4
	}

	// PASS 1.5
	for &ld in label_defs {
		if ld != LABEL_UNDEFINED {
			ld = Label_Definition(u32(ld) * 4)
		}
	}

	if !resolve {
		return Result{byte_count = pc, success = u32(len(errors)) == errors_start}
	}

	// PASS 2
	n_relocs  := u32(len(relocs))
	write_idx := pending_start
	for read_idx in pending_start..<n_relocs {
		r := relocs[read_idx]
		if resolve_relocation_inline(code, label_defs, &r, endianness, base_address, errors) {
			continue
		}
		if write_idx != read_idx {
			relocs[write_idx] = r
		}
		write_idx += 1
	}
	if write_idx != n_relocs {
		resize(relocs, int(write_idx))
	}

	return Result{byte_count = pc, success = u32(len(errors)) == errors_start}
}

// =============================================================================
// Internal: encode one instruction
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
// Matcher
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
	case .VR:
		// Plain vector register (no element).  Accept VECTOR_REG OR
		// REGISTER if the user did not need an element.
		if op.kind == .VECTOR_REG  { return reg_class(op.reg) == REG_VR }
		if op.kind == .REGISTER    { return reg_class(op.reg) == REG_VR }
		return false
	case .VR_ELEM:
		// Vector register with element selector (always VECTOR_REG kind
		// semantically, but accept both for ergonomics -- element defaults
		// to 0 for plain REGISTER use).
		if op.kind == .VECTOR_REG  { return reg_class(op.reg) == REG_VR }
		if op.kind == .REGISTER    { return reg_class(op.reg) == REG_VR }
		return false
	case .CP0_REG:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_CP0
	case .CP2_CTRL:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_VC
	case .IMM5, .IMM16S, .IMM16U, .IMM20, .IMM26:
		return op.kind == .IMMEDIATE
	case .REL16, .REL_J26:
		return op.kind == .RELATIVE
	case .MEM:
		return op.kind == .MEMORY
	case .VMEM:
		return op.kind == .VECTOR_MEM
	}
	return false
}

// -----------------------------------------------------------------------------
// Operand packer
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

	// Scalar GPR slots ------------------------------------------------------
	case .RS:
		return (u32(reg_hw(op.reg)) & 0x1F) << 21
	case .RT:
		return (u32(reg_hw(op.reg)) & 0x1F) << 16
	case .RD:
		return (u32(reg_hw(op.reg)) & 0x1F) << 11
	case .SHAMT:
		return (u32(op.immediate) & 0x1F) << 6

	// Immediates ------------------------------------------------------------
	case .IMM_16:
		return u32(op.immediate) & 0xFFFF
	case .IMM_5:
		return (u32(op.immediate) & 0x1F) << 6
	case .IMM_20:
		return (u32(op.immediate) & 0xFFFFF) << 6
	case .IMM_26:
		if op.kind == .RELATIVE {
			append(relocs, Relocation{
				offset = pc, label_id = u32(op.relative),
				type = .J26, size = 4, inst_idx = inst_idx,
			})
			return 0
		}
		return u32(op.immediate) & 0x3FFFFFF

	// Scalar memory ---------------------------------------------------------
	case .OFFSET_BASE:
		return ((u32(reg_hw(op.mem.base)) & 0x1F) << 21) | (u32(op.mem.disp) & 0xFFFF)

	case .BRANCH_16:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .REL16, size = 4, inst_idx = inst_idx,
		})
		return 0

	case .IMPL:
		return 0

	// Vector ALU register slots --------------------------------------------
	// VT packs the vector register hw number AND its element selector
	// (for VR_ELEM operands); ELEM alone is rarely used in practice.
	case .VT:
		v := (u32(reg_hw(op.reg)) & 0x1F) << 16
		if op.kind == .VECTOR_REG {
			v |= (u32(op.element) & 0x0F) << 21   // element field bits 24-21
		}
		return v
	case .VS:
		return (u32(reg_hw(op.reg)) & 0x1F) << 11
	case .VD:
		return (u32(reg_hw(op.reg)) & 0x1F) << 6
	case .ELEM:
		return (u32(op.element) & 0x0F) << 21

	// Vector load/store -----------------------------------------------------
	case .VT_LS:
		return (u32(reg_hw(op.reg)) & 0x1F) << 16
	case .VOP:
		return 0   // VOP is part of static bits, not operand-driven
	case .VELEM_LS:
		return (u32(op.vmem.element) & 0x0F) << 7
	case .VOFFSET:
		return u32(op.vmem.offset) & 0x7F
	case .VBASE:
		// The VMEM operand packs base + element + offset in one shot.
		base_bits   := (u32(reg_hw(op.vmem.base)) & 0x1F) << 21
		elem_bits   := (u32(op.vmem.element) & 0x0F) << 7
		offset_bits :=  u32(op.vmem.offset) & 0x7F
		return base_bits | elem_bits | offset_bits
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
		return false
	}
	ld := label_defs[relocation.label_id]
	if ld == LABEL_UNDEFINED {
		return false
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

	case .J26:
		if target & 3 != 0 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		target_abs := base_address + u64(target)
		next_pc    := base_address + u64(relocation.offset) + 4
		if (u32(next_pc) >> 28) != (u32(target_abs) >> 28) {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		word = (word &~ 0x3FFFFFF) | (u32(target_abs >> 2) & 0x3FFFFFF)

	case .NONE:
		return false
	}

	write_u32(code, relocation.offset, word, endianness)
	return true
}

// =============================================================================
// Endian-aware word read/write
// =============================================================================

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
