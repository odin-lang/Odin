package rexcode_ppc

import "../isa"

// =============================================================================
// PowerPC DECODER
// =============================================================================
//
// PowerPC base instructions are 4 bytes; Power ISA 3.1 prefixed are 8.
// A prefixed instruction starts with a prefix word whose primary opcode is 1
// (bits 26..31 LSB = 0b000001 = 0x04 in the top byte BE).
//
// Operation per instruction:
//   1. Read 4 BE bytes -> word
//   2. Index into DECODE_INDEX by primary opcode (bits 26..31, 6 bits, 64 buckets)
//   3. For each candidate entry in the bucket, test (word & mask) == bits
//   4. On match, unpack operands and emit Instruction; branch operands emit
//      RELATIVE with absolute target byte offset.

Instruction_Info :: struct {
	offset:       u32,
	decode_entry: u16,    // index into DECODE_ENTRIES (or 0 for no-match)
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
	mode:         Mode = .PPC32,
) -> Result {
	n_bytes := u32(len(data)) & ~u32(3)
	errors_start := u32(len(errors))

	pending_branches: [dynamic]isa.Branch_Target
	defer delete(pending_branches)

	pc: u32 = 0
	for pc < n_bytes {
		if pc + 4 > n_bytes { break }
		word := read_u32_be(data, pc)

		// Detect prefixed instruction: primary opcode = 1.
		is_prefixed := (word >> 26) == 0x01
		ilen: u32 = 4
		suffix: u32 = 0
		if is_prefixed {
			if pc + 8 > n_bytes { break }
			suffix = read_u32_be(data, pc + 4)
			ilen   = 8
		}

		inst: Instruction
		info: Instruction_Info
		info.offset = pc

		match_word := is_prefixed ? suffix : word
		prefix_word := is_prefixed ? word : 0
		if !find_and_decode(match_word, prefix_word, is_prefixed, mode, &inst, &info) {
			append(errors, Error{inst_idx = pc, code = .INVALID_OPCODE})
			inst = Instruction{mnemonic = .INVALID, length = u8(ilen), mode = mode}
		} else {
			inst.length = u8(ilen)
			inst.mode   = mode
			inst_idx := u32(len(instructions))
			for slot in 0..<inst.operand_count {
				op := &inst.ops[slot]
				if op.kind == .RELATIVE && op.relative >= 0 {
					// The unpacker stores PC-relative byte offsets; convert
					// to absolute target = pc + relative.
					target := u32(i32(pc) + i32(op.relative))
					append(&pending_branches, isa.Branch_Target{
						inst_idx = inst_idx,
						op_idx   = slot,
						target   = target,
					})
				}
			}
		}

		append(instructions, inst)
		append(inst_info,    info)
		pc += ilen
	}

	isa.infer_labels_from_branches(pending_branches[:], pc, label_defs, relocs)
	return Result{byte_count = pc, success = u32(len(errors)) == errors_start}
}

// =============================================================================
// Decode dispatch via two-level (primary, primary*256+xo) bucket tables
// =============================================================================

@(private="file")
find_and_decode :: proc(word, prefix: u32, prefixed: bool, mode: Mode, inst: ^Instruction, info: ^Instruction_Info) -> bool {
	primary := (word >> 26) & 0x3F
	sub_key := primary * DECODE_SUB_BUCKETS + ((word >> 1) & 0xFF)

	sub_range := DECODE_INDEX_SUB[sub_key]
	if sub_range.count > 0 {
		if try_bucket(word, prefix, prefixed, mode, sub_range, inst, info) { return true }
	}

	primary_range := DECODE_INDEX_PRIMARY[primary]
	if primary_range.count > 0 {
		if try_bucket(word, prefix, prefixed, mode, primary_range, inst, info) { return true }
	}
	return false
}

@(private="file")
try_bucket :: proc(word, prefix: u32, prefixed: bool, mode: Mode, r: Decode_Index, inst: ^Instruction, info: ^Instruction_Info) -> bool {
	base := int(r.start)
	cnt  := int(r.count)
	for i in 0..<cnt {
		entry_idx := DECODE_BUCKET_LIST[base + i]
		e := &DECODE_ENTRIES[entry_idx]
		if (word & e.mask) != (e.bits & e.mask) { continue }
		if e.flags.prefixed != prefixed { continue }
		if e.mode == .PPC64 && mode == .PPC32 { continue }
		// For prefixed instructions, the PREFIX_BITS_TABLE entry must match
		// the prefix word's fixed bits (top 6 bits = primary opcode 1, plus
		// the 8-bit template at bits 24..21 LSB). Only the IMM18+R fields
		// (bits 0..18 LSB) are variable in the prefix.
		if prefixed {
			expected_prefix := PREFIX_BITS_TABLE[e.mnemonic]
			// Mask covers primary (bits 26..31) and template/R (bits 19..25).
			// IMM18 occupies bits 0..17 — leave those free.
			prefix_mask: u32 = 0xFFFC0000
			if (prefix & prefix_mask) != (expected_prefix & prefix_mask) { continue }
		}

		inst.mnemonic      = e.mnemonic
		inst.operand_count = 0
		inst.form_id       = DECODE_FORM_IDX[entry_idx] + 1
		info.decode_entry  = u16(entry_idx)

		if e.flags.sets_cr0 && (word & 1) != 0       { inst.flags.sets_cr0 = true }
		if e.flags.has_oe   && ((word >> 10) & 1) != 0 { inst.flags.has_oe = true }

		for k in 0..<4 {
			if e.enc[k] == .NONE && e.ops[k] == .NONE { break }
			if e.enc[k] == .NONE {
				inst.ops[k] = default_operand_for(e.ops[k])
			} else {
				inst.ops[k] = unpack_operand(word, e.enc[k], e.ops[k])
			}
			inst.operand_count = u8(k + 1)
		}
		return true
	}
	return false
}

@(private="file")
default_operand_for :: proc(ot: Operand_Type) -> Operand {
	#partial switch ot {
	case .GPR, .GPR_OR_ZERO: return op_reg(R0)
	case .FPR:               return op_reg(F0)
	case .VR:                return op_reg(V0)
	case .VR128:             return op_reg(vr128_reg(0))
	case .VSR:               return op_reg(vs_reg(0))
	case .CR_FIELD, .CR_BIT: return op_reg(CR0)
	case .SPR:               return op_reg(spr_reg(0))
	case .MEM:               return op_mem(mem_d(R0, 0))
	case .REL:               return op_rel_offset(0)
	case .IMM, .SIMM, .UIMM, .BO, .BH: return op_imm(0)
	}
	return op_imm(0)
}

// =============================================================================
// Operand un-packers (inverse of pack_operand in encoder.odin)
// =============================================================================

@(private="file")
unpack_operand :: proc(word: u32, enc: Operand_Encoding, ot: Operand_Type) -> Operand {
	#partial switch enc {
	// ---- Integer registers ----
	case .RT, .RS: return op_reg(Register(REG_GPR | u16((word >> 21) & 0x1F)))
	case .RA:      return op_reg(Register(REG_GPR | u16((word >> 16) & 0x1F)))
	case .RB:      return op_reg(Register(REG_GPR | u16((word >> 11) & 0x1F)))
	case .RC:      return op_reg(Register(REG_GPR | u16((word >>  6) & 0x1F)))

	// ---- Floating-point ----
	case .FRT:     return op_reg(Register(REG_FPR | u16((word >> 21) & 0x1F)))
	case .FRA:     return op_reg(Register(REG_FPR | u16((word >> 16) & 0x1F)))
	case .FRB:     return op_reg(Register(REG_FPR | u16((word >> 11) & 0x1F)))
	case .FRC:     return op_reg(Register(REG_FPR | u16((word >>  6) & 0x1F)))

	// ---- AltiVec ----
	case .VRT:     return op_reg(Register(REG_VR | u16((word >> 21) & 0x1F)))
	case .VRA:     return op_reg(Register(REG_VR | u16((word >> 16) & 0x1F)))
	case .VRB:     return op_reg(Register(REG_VR | u16((word >> 11) & 0x1F)))
	case .VRC:     return op_reg(Register(REG_VR | u16((word >>  6) & 0x1F)))

	// ---- VSX ----
	case .XT:
		n := ((word >> 21) & 0x1F) | ((word & 1) << 5)
		return op_reg(vs_reg(u8(n)))
	case .XA:
		n := ((word >> 16) & 0x1F) | (((word >> 2) & 1) << 5)
		return op_reg(vs_reg(u8(n)))
	case .XB:
		n := ((word >> 11) & 0x1F) | (((word >> 1) & 1) << 5)
		return op_reg(vs_reg(u8(n)))
	case .XC:
		n := ((word >>  6) & 0x1F) | (((word >> 3) & 1) << 5)
		return op_reg(vs_reg(u8(n)))

	// ---- VMX128 (5-bit subset — see encoder for why we don't unpack VDh/VBh) ----
	case .VRT128:  return op_reg(vr128_reg(u8((word >> 21) & 0x1F)))
	case .VRA128:  return op_reg(vr128_reg(u8((word >> 16) & 0x1F)))
	case .VRB128:  return op_reg(vr128_reg(u8((word >> 11) & 0x1F)))
	case .VRC128:  return op_reg(vr128_reg(u8((word >>  6) & 0x1F)))

	// ---- Condition register fields ----
	case .BF:        return op_reg(Register(REG_CR | u16((word >> 23) & 0x7)))
	case .BFA:       return op_reg(Register(REG_CR | u16((word >> 18) & 0x7)))
	case .BT:        return op_reg(Register(REG_CR | u16((word >> 21) & 0x1F)))
	case .BA:        return op_reg(Register(REG_CR | u16((word >> 16) & 0x1F)))
	case .BB:        return op_reg(Register(REG_CR | u16((word >> 11) & 0x1F)))
	case .BO_FIELD:
		n := (word >> 21) & 0x1F
		if ot == .CR_BIT { return op_reg(Register(REG_CR | u16(n))) }
		return op_imm(i64(n))
	case .BI_FIELD:
		n := (word >> 16) & 0x1F
		if ot == .CR_BIT { return op_reg(Register(REG_CR | u16(n))) }
		return op_imm(i64(n))
	case .BH_FIELD:
		n := (word >> 11) & 0x3
		if ot == .CR_BIT { return op_reg(Register(REG_CR | u16(n))) }
		return op_imm(i64(n))

	// ---- SPR (10-bit split with halves swapped) ----
	case .SPR_FIELD:
		n := ((word >> 11) & 0x1F) | (((word >> 16) & 0x1F) << 5)
		return op_reg(spr_reg(u16(n)))

	// ---- Immediates ----
	case .D16:    return op_imm(i64(i16(word & 0xFFFF)))
	case .UI16:   return op_imm(i64(u16(word & 0xFFFF)))
	case .DS14:   return op_imm(i64(i16(word & 0xFFFC)))
	case .DQ12:   return op_imm(i64(i16(word & 0xFFF0)))
	case .SH5:    return op_imm(i64((word >> 11) & 0x1F))
	case .SH6:
		v := ((word >> 11) & 0x1F) | (((word >> 1) & 1) << 5)
		return op_imm(i64(v))
	case .MB5:    return op_imm(i64((word >> 6) & 0x1F))
	case .ME5:    return op_imm(i64((word >> 1) & 0x1F))
	case .MB6:
		v := ((word >> 6) & 0x1F) | (((word >> 5) & 1) << 5)
		return op_imm(i64(v))
	case .SIMM_5: return op_imm(i64(i32((word >> 16) & 0x1F) - i32((word >> 16) & 0x10) * 2))
	case .UIMM_5: return op_imm(i64((word >> 16) & 0x1F))
	case .UIMM_4: return op_imm(i64((word >> 16) & 0xF))
	case .UIMM_2: return op_imm(i64((word >> 16) & 0x3))
	case .FXM:    return op_imm(i64((word >> 12) & 0xFF))
	case .L_FIELD: return op_imm(i64((word >> 21) & 0x1))
	case .TO_FIELD: return op_imm(i64((word >> 21) & 0x1F))
	case .NB_FIELD: return op_imm(i64((word >> 11) & 0x1F))
	case .SR_FIELD: return op_imm(i64((word >> 16) & 0xF))
	case .CRM:    return op_imm(i64((word >> 12) & 0xFF))
	case .DCMX:   return op_imm(i64((word >> 16) & 0x7F))

	// ---- Memory composites ----
	case .OFFSET_BASE_D:
		return op_mem(mem_d(Register(REG_GPR | u16((word >> 16) & 0x1F)),
							i64(i16(word & 0xFFFF))))
	case .OFFSET_BASE_DS:
		return op_mem(mem_d(Register(REG_GPR | u16((word >> 16) & 0x1F)),
							i64(i16(word & 0xFFFC))))
	case .OFFSET_BASE_DQ:
		return op_mem(mem_d(Register(REG_GPR | u16((word >> 16) & 0x1F)),
							i64(i16(word & 0xFFF0))))
	case .OFFSET_BASE_X, .OFFSET_VSX_X:
		return op_mem(mem_x(Register(REG_GPR | u16((word >> 16) & 0x1F)),
							Register(REG_GPR | u16((word >> 11) & 0x1F))))

	// ---- PC-relative ----
	case .BRANCH_LI:
		// 24-bit signed << 2 at bits 2..25 (sign-extend from bit 25).
		u := word & 0x03FFFFFC
		v := i32(u)
		if u & 0x02000000 != 0 { v = i32(u | 0xFC000000) }
		return op_rel_offset(i64(v))
	case .BRANCH_BD:
		// 14-bit signed << 2 at bits 2..15 (sign-extend from bit 15).
		u := word & 0xFFFC
		v := i32(u)
		if u & 0x8000 != 0 { v = i32(u | 0xFFFF0000) }
		return op_rel_offset(i64(v))
	}
	return op_imm(0)
}
