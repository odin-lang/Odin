// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_rsp

import "core:rexcode/isa"

// =============================================================================
// N64 RSP DECODER
// =============================================================================
//
// Two passes, mirroring mips/decoder.odin. The RSP-specific bits live in
// `extract_operand_inline`: VR / VR_ELEM operands carry an element field
// extracted from bits 24-21 of the word, and VMEM operands collect base,
// element offset, and signed 7-bit byte offset from their respective
// positions in the LWC2/SWC2 layout.

Instruction_Info :: struct {
	offset:       u32,
	decode_entry: u16,
	_:            u16,
}
#assert(size_of(Instruction_Info) == 8)

decode :: proc(
	data:         []u8,
	relocs:       []Relocation,
	instructions: ^[dynamic]Instruction,
	inst_info:    ^[dynamic]Instruction_Info,
	label_defs:   ^[dynamic]Label_Definition,
	errors:       ^[dynamic]Error,
	endianness:   Endianness = .BIG,
) -> (byte_count: u32, ok: bool) {
	n_bytes := u32(len(data)) & ~u32(3)   // drop dangling tail
	errors_start := u32(len(errors))

	pending_branches: [dynamic]isa.Branch_Target
	defer delete(pending_branches)

	for byte_count < n_bytes {
		word := read_u32(data, byte_count, endianness)

		inst: Instruction
		info: Instruction_Info
		entry_idx := decode_one_inline(word, byte_count, &inst, &info)

		if entry_idx < 0 {
			append(errors, Error{inst_idx = byte_count, code = .INVALID_OPCODE})
			inst = Instruction{mnemonic = .INVALID, length = 4}
			info = Instruction_Info{offset = byte_count}
		} else {
			inst_idx_for_branches := u32(len(instructions))
			for slot in 0..<inst.operand_count {
				op := &inst.ops[slot]
				if op.kind == .RELATIVE && op.relative >= 0 {
					append(&pending_branches, isa.Branch_Target{
						inst_idx = inst_idx_for_branches,
						op_idx   = slot,
						target   = u32(op.relative),
					})
				}
			}
		}

		append(instructions, inst)
		append(inst_info,    info)
		byte_count += 4
	}

	isa.infer_labels_from_branches(pending_branches[:], byte_count, label_defs, relocs)

	ok = u32(len(errors)) == errors_start
	return
}

// =============================================================================
// Internal
// =============================================================================

@(private="file")
decode_one_inline :: #force_inline proc "contextless" (
	word: u32, pc: u32, inst: ^Instruction, info: ^Instruction_Info,
) -> int {
	primary := (word >> 26) & 0x3F

	range: Decode_Index
	switch primary {
	case 0x00: range = DECODE_INDEX_SPECIAL[word & 0x3F]
	case 0x01: range = DECODE_INDEX_REGIMM [(word >> 16) & 0x1F]
	case 0x12: range = DECODE_INDEX_COP2   [word & 0x3F]
	case 0x32: range = DECODE_INDEX_LWC2   [(word >> 11) & 0x1F]
	case 0x3A: range = DECODE_INDEX_SWC2   [(word >> 11) & 0x1F]
	case:      range = DECODE_INDEX_PRIMARY[primary]
	}

	if range.count == 0 { return -1 }

	base := int(range.start)
	cnt  := int(range.count)
	matched_idx := -1
	for i in 0..<cnt {
		e := &DECODE_ENTRIES[base + i]
		if (word & e.mask) == e.bits {
			matched_idx = base + i
			break
		}
	}
	if matched_idx < 0 { return -1 }

	entry := &DECODE_ENTRIES[matched_idx]
	inst.mnemonic = entry.mnemonic
	inst.length   = 4
	inst.flags    = {}

	cnt_used: u8 = 0
	if entry.ops[0] != .NONE {
		inst.ops[0] = extract_operand_inline(word, pc, entry.ops[0], entry.enc[0])
		cnt_used = 1
		if entry.ops[1] != .NONE {
			inst.ops[1] = extract_operand_inline(word, pc, entry.ops[1], entry.enc[1])
			cnt_used = 2
			if entry.ops[2] != .NONE {
				inst.ops[2] = extract_operand_inline(word, pc, entry.ops[2], entry.enc[2])
				cnt_used = 3
				if entry.ops[3] != .NONE {
					inst.ops[3] = extract_operand_inline(word, pc, entry.ops[3], entry.enc[3])
					cnt_used = 4
				}
			}
		}
	}
	inst.operand_count = cnt_used
	info.offset       = pc
	info.decode_entry = u16(matched_idx)
	return matched_idx
}

@(private="file")
extract_operand_inline :: #force_inline proc "contextless" (
	word: u32, pc: u32, ot: Operand_Type, en: Operand_Encoding,
) -> Operand {
	switch en {
	case .NONE:
		return {}

	// Scalar GPR slots ------------------------------------------------------
	case .RS:
		return reg_operand_scalar(decode_gpr(word, 21, ot), ot)
	case .RT:
		return reg_operand_scalar(decode_gpr(word, 16, ot), ot)
	case .RD:
		return reg_operand_scalar(decode_gpr(word, 11, ot), ot)
	case .SHAMT:
		return Operand{immediate = i64((word >> 6) & 0x1F), kind = .IMMEDIATE, size = 1}

	// Immediates ------------------------------------------------------------
	case .IMM_16:
		imm: i64
		if ot == .IMM16S {
			imm = i64(i16(word & 0xFFFF))
		} else {
			imm = i64(word & 0xFFFF)
		}
		return Operand{immediate = imm, kind = .IMMEDIATE, size = 2}
	case .IMM_5:
		return Operand{immediate = i64((word >> 6) & 0x1F), kind = .IMMEDIATE, size = 1}
	case .IMM_20:
		return Operand{immediate = i64((word >> 6) & 0xFFFFF), kind = .IMMEDIATE, size = 4}
	case .IMM_26:
		if ot == .REL_J26 {
			field  := word & 0x3FFFFFF
			target := ((pc + 4) & 0xF0000000) | (field << 2)
			return Operand{relative = i64(target), kind = .RELATIVE, size = 4}
		}
		return Operand{immediate = i64(word & 0x3FFFFFF), kind = .IMMEDIATE, size = 4}

	// Scalar memory ---------------------------------------------------------
	case .OFFSET_BASE:
		base_hw := u16((word >> 21) & 0x1F)
		disp    := i32(i16(word & 0xFFFF))
		m       := Memory{base = Register(REG_GPR | base_hw), disp = disp}
		return Operand{mem = m, kind = .MEMORY, size = 4}

	case .BRANCH_16:
		rel    := i32(i16(word & 0xFFFF)) << 2
		target := u32(i32(pc) + 4 + rel)
		return Operand{relative = i64(target), kind = .RELATIVE, size = 4}

	case .IMPL:
		return {}

	// Vector ALU register slots --------------------------------------------
	// VT pulls vt hw number (bits 20-16) AND element selector (bits 24-21).
	case .VT:
		hw   := u16((word >> 16) & 0x1F)
		elem := u8 ((word >> 21) & 0x0F)
		return Operand{
			reg     = Register(REG_VR | hw),
			kind    = ot == .VR_ELEM ? .VECTOR_REG : .VECTOR_REG,
			size    = 16,
			element = elem,
		}
	case .VS:
		hw := u16((word >> 11) & 0x1F)
		return Operand{reg = Register(REG_VR | hw), kind = .VECTOR_REG, size = 16}
	case .VD:
		hw := u16((word >> 6) & 0x1F)
		return Operand{reg = Register(REG_VR | hw), kind = .VECTOR_REG, size = 16}
	case .ELEM:
		return Operand{immediate = i64((word >> 21) & 0x0F), kind = .IMMEDIATE, size = 1}

	// Vector L/S placements -------------------------------------------------
	case .VT_LS:
		hw := u16((word >> 16) & 0x1F)
		return Operand{reg = Register(REG_VR | hw), kind = .VECTOR_REG, size = 16}
	case .VOP:
		return {}   // static, not an operand at runtime
	case .VELEM_LS:
		return Operand{immediate = i64((word >> 7) & 0x0F), kind = .IMMEDIATE, size = 1}
	case .VOFFSET:
		// Sign-extend the 7-bit field.
		v := i32(word & 0x7F)
		if v & 0x40 != 0 { v |= ~i32(0x7F) }
		return Operand{immediate = i64(v), kind = .IMMEDIATE, size = 1}
	case .VBASE:
		// The VBASE encoding emits the full Vector_Mem (base + element + offset).
		base_hw := u16((word >> 21) & 0x1F)
		elem    := u8 ((word >>  7) & 0x0F)
		v       := i32(word & 0x7F)
		if v & 0x40 != 0 { v |= ~i32(0x7F) }
		vm := Vector_Mem{
			base    = Register(REG_GPR | base_hw),
			element = elem,
			offset  = v,
		}
		return Operand{vmem = vm, kind = .VECTOR_MEM, size = 16}
	}
	return {}
}

@(private="file")
decode_gpr :: #force_inline proc "contextless" (word: u32, shift: u8, ot: Operand_Type) -> Register {
	hw: u16 = u16((word >> shift) & 0x1F)
	class: u16 = REG_GPR
	#partial switch ot {
	case .CP0_REG:  class = REG_CP0
	case .CP2_CTRL: class = REG_VC
	}
	return Register(class | hw)
}

@(private="file")
reg_operand_scalar :: #force_inline proc "contextless" (r: Register, ot: Operand_Type) -> Operand {
	return Operand{reg = r, kind = .REGISTER, size = 4}
}


// -----------------------------------------------------------------------------
// Buffer-Sizing Helpers (let callers pre-size so the decode hot path never
// reallocates; allocates no new buffers -- only the caller's arrays grow).
// -----------------------------------------------------------------------------

// Instruction-count ceiling for `data` (RSP instructions are 4 bytes).
@(require_results)
decode_max_instruction_count :: #force_inline proc "contextless" (data: []u8) -> int {
	return len(data) / 4
}

// Typical-case estimate of the instruction count for `data`.
@(require_results)
decode_estimate_instruction_count :: #force_inline proc "contextless" (data: []u8) -> int {
	return len(data) / 4 + 8
}

// Pre-size the caller's decode output arrays for `data` (reserves on top of any
// existing elements; nil to skip; exact=true for the ceiling, else the estimate).
decode_reserve :: proc(instructions: ^[dynamic]Instruction, inst_info: ^[dynamic]Instruction_Info, label_defs: ^[dynamic]Label_Definition, data: []u8, exact: bool = false) {
	n := exact ? decode_max_instruction_count(data) : decode_estimate_instruction_count(data)
	if instructions != nil { reserve(instructions, len(instructions) + n) }
	if inst_info    != nil { reserve(inst_info,    len(inst_info)    + n) }
	if label_defs   != nil { reserve(label_defs,   len(label_defs)   + n) }
}
