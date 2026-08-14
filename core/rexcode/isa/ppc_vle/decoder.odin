// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ppc_vle

import "core:rexcode/isa"

// =============================================================================
// PowerPC VLE Decoder
// =============================================================================
//
// Variable-length: try 16-bit match first, fall back to 32-bit.
// Operands are extracted via the form's enc[] field positions.

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
) -> (byte_count: u32, ok: bool) {
	n_bytes := u32(len(data)) & ~u32(1)
	errors_start := u32(len(errors))

	pending_branches: [dynamic]isa.Branch_Target
	defer delete(pending_branches)

	for byte_count < n_bytes {
		if byte_count + 2 > n_bytes { break }
		hw := u32(read_u16_be(data, byte_count))

		inst: Instruction
		info: Instruction_Info
		info.offset = byte_count

		matched := try_decode(hw, true, &inst, &info)
		ilen: u32 = 2

		if !matched {
			if byte_count + 4 > n_bytes {
				append(errors, Error{inst_idx = byte_count, code = .BUFFER_TOO_SHORT})
				break
			}
			word := (hw << 16) | u32(read_u16_be(data, byte_count + 2))
			matched = try_decode(word, false, &inst, &info)
			ilen = 4
		}

		if !matched {
			append(errors, Error{inst_idx = byte_count, code = .INVALID_OPCODE})
			inst = Instruction{mnemonic = .INVALID, length = 2, mode = .PPC32_VLE}
			ilen = 2
		} else {
			inst.length = u8(ilen)
			inst.mode   = .PPC32_VLE

			// Track branch targets for label inference
			inst_idx := u32(len(instructions))
			for slot in 0..<inst.operand_count {
				op := &inst.ops[slot]
				if op.kind == .RELATIVE && op.relative >= 0 {
					append(&pending_branches, isa.Branch_Target{
						inst_idx = inst_idx,
						op_idx   = slot,
						target   = u32(i32(byte_count) + i32(op.relative)),
					})
				}
			}
		}

		append(instructions, inst)
		append(inst_info,    info)
		byte_count += ilen
	}

	isa.infer_labels_from_branches(pending_branches[:], byte_count, label_defs, relocs)
	ok = u32(len(errors)) == errors_start
	return
}

@(private="file")
try_decode :: proc(word: u32, want_short: bool, inst: ^Instruction, info: ^Instruction_Info) -> bool {
	// Primary key: bits 10..15 for 16-bit, bits 26..31 for 32-bit
	primary: u32
	range:   Decode_Index
	if want_short {
		primary = (word >> 10) & 0x3F
		range = DECODE_INDEX_SHORT[primary]
	} else {
		primary = (word >> 26) & 0x3F
		range = DECODE_INDEX_LONG[primary]
	}
	if range.count == 0 { return false }

	base := int(range.start)
	cnt  := int(range.count)
	for i in 0..<cnt {
		entry_idx := DECODE_BUCKET_LIST[base + i]
		e := &DECODE_ENTRIES[entry_idx]
		if (word & e.mask) != (e.bits & e.mask) { continue }

		inst.mnemonic      = e.mnemonic
		inst.operand_count = 0
		inst.form_id       = DECODE_FORM_IDX[entry_idx] + 1
		info.decode_entry  = u16(entry_idx)

		for k in 0..<4 {
			if e.enc[k] == .NONE && e.ops[k] == .NONE { break }
			inst.ops[k] = unpack_operand(word, e.enc[k], e.ops[k])
			inst.operand_count = u8(k + 1)
		}
		return true
	}
	return false
}

// VLE 4-bit register decoding: 0..7 → r0..r7, 8..15 → r24..r31.
@(private="file")
decode_vle16_reg :: #force_inline proc "contextless" (v: u32) -> Register {
	n := v & 0xF
	if n < 8 { return Register(REG_GPR | u16(n)) }
	return Register(REG_GPR | u16(n + 16))
}

@(private="file")
unpack_operand :: proc(word: u32, enc: Operand_Encoding, ot: Operand_Type) -> Operand {
	#partial switch enc {
	case .NONE, .IMPL:
		// Synthesize a placeholder by operand type
		#partial switch ot {
		case .GPR, .GPR_VLE16: return op_reg(R0)
		case .IMM, .SIMM, .UIMM: return op_imm(0)
		case .REL:               return op_rel_offset(0)
		case .CR_FIELD, .CR_BIT: return op_reg(CR0)
		case .MEM:               return op_mem(mem_d(R0, 0))
		case .BO:                return op_imm(0)
		}
		return Operand{}

	case .RT, .RS: return op_reg(Register(REG_GPR | u16((word >> 21) & 0x1F)))
	case .RA:      return op_reg(Register(REG_GPR | u16((word >> 16) & 0x1F)))
	case .RB:      return op_reg(Register(REG_GPR | u16((word >> 11) & 0x1F)))

	case .UI16:    return op_imm(i64(word & 0xFFFF))
	case .SI16:    return op_imm(i64(i16(word & 0xFFFF)))
	case .LI20:
		v := ((word >> 17) & 0xF) << 16 | ((word >> 11) & 0x1F) << 11 | (word & 0x7FF)
		return op_imm(i64(v))
	case .SCI8:    return op_imm(i64(word & 0xFF))

	case .B15:
		u := word & 0xFFFE
		v := i32(u)
		if u & 0x8000 != 0 { v = i32(u | 0xFFFF0000) }
		return op_rel_offset(i64(v))
	case .B24:
		u := word & 0x01FFFFFE
		v := i32(u)
		if u & 0x01000000 != 0 { v = i32(u | 0xFE000000) }
		return op_rel_offset(i64(v))
	case .BO32:    return op_imm(i64((word >> 20) & 0x3))
	case .BI32:    return op_reg(Register(REG_CR | u16((word >> 16) & 0xF)))

	case .RX:      return op_reg(decode_vle16_reg(word & 0xF))
	case .RY:      return op_reg(decode_vle16_reg((word >> 4) & 0xF))
	case .RZ:      return op_reg(decode_vle16_reg((word >> 4) & 0xF))

	case .UI5:     return op_imm(i64((word >> 4) & 0x1F))
	case .UI7:     return op_imm(i64(word & 0x7F))

	case .B8:
		u := word & 0xFF
		v := i32(u)
		if u & 0x80 != 0 { v = i32(u | 0xFFFFFF00) }
		// B8 displacement is signed << 1 in our convention (target = pc + v*2),
		// but binutils stores it pre-multiplied. Use raw value: v*2.
		return op_rel_offset(i64(v) * 2)
	case .BO16:    return op_imm(i64((word >> 10) & 1))
	case .BI16:    return op_reg(Register(REG_CR | u16((word >> 8) & 0x3)))

	case .OFFSET_BASE_D:
		return op_mem(mem_d(Register(REG_GPR | u16((word >> 16) & 0x1F)),
							i64(i16(word & 0xFFFF))))
	case .OFFSET_BASE_SD4:
		return op_mem(mem_d(decode_vle16_reg(word & 0xF),
							i64((word >> 8) & 0xF)))
	case .OFFSET_BASE_SD4_H:
		return op_mem(mem_d(decode_vle16_reg(word & 0xF),
							i64((word >> 8) & 0xF) * 2))
	case .OFFSET_BASE_SD4_W:
		return op_mem(mem_d(decode_vle16_reg(word & 0xF),
							i64((word >> 8) & 0xF) * 4))
	}
	return op_imm(0)
}


// -----------------------------------------------------------------------------
// Buffer-Sizing Helpers (let callers pre-size so the decode hot path never
// reallocates; allocates no new buffers -- only the caller's arrays grow).
// -----------------------------------------------------------------------------

// Instruction-count ceiling for `data` (VLE is 2 or 4 bytes; minimum 2).
@(require_results)
decode_max_instruction_count :: #force_inline proc "contextless" (data: []u8) -> int {
	return len(data) / 2
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
