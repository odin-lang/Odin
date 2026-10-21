// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm32

import "core:rexcode/isa"

// =============================================================================
// AArch32 DECODER
// =============================================================================
//
// Variable-length: A32 = 4 bytes, T16 = 2 bytes, T32 = 4 bytes (two halfwords).
// The decoder takes a Mode parameter telling it whether to interpret bytes
// as A32 or T32. In T32 mode, the first halfword's top 5 bits indicate
// whether the instruction is 16 or 32 bits (top in {11101, 11110, 11111} = 32).
//
// Operation:
//
//   PASS 1 - For each instruction, read the appropriate halfword(s), match
//            against ENCODING_TABLE entries for the active mode, build the
//            Instruction with extracted operands. Branch operands are emitted
//            as RELATIVE with the absolute target byte offset; the post-pass
//            converts these into Label_Definitions via infer_labels_from_branches.
//
// Like riscv, decoding is structured as a linear-scan by mnemonic with a
// `(word & mask) == bits` test. For performance, future work could build a
// decode index table (see arm64/decoding_tables.odin pattern).

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
	mode:         Mode = .A32,
	// Only matters for Thumb: which reading of the words the profiles share.
	profile:      Profile = .A_PROFILE,
) -> (byte_count: u32, ok: bool) {
	n_bytes := u32(len(data))
	if mode == .T32 { n_bytes = n_bytes & ~u32(1) }
	else            { n_bytes = n_bytes & ~u32(3) }

	errors_start := u32(len(errors))

	pending_branches: [dynamic]isa.Branch_Target
	defer delete(pending_branches)

	// ITSTATE, as the architecture keeps it: the block's first condition in
	// bits 7:4 and the then/else mask in 3:0. Each instruction in the block
	// takes its condition from bits 7:4, and the mask shifts up one per
	// instruction until it is empty. Zero is "not in a block".
	it_state: u8 = 0

	for byte_count < n_bytes {
		word: u32
		ilen: u32 = 4

		if mode == .A32 {
			if byte_count + 4 > n_bytes { break }
			word = read_u32_le(data, byte_count)
		} else {
			// T32: 16 or 32 bit
			hword_hi := read_u16_le(data, byte_count)
			top5 := (hword_hi >> 11) & 0x1F
			if top5 == 0x1D || top5 == 0x1E || top5 == 0x1F {
				if byte_count + 4 > n_bytes { break }
				hword_lo := read_u16_le(data, byte_count + 2)
				// Pack: bits = first halfword << 16 | second halfword
				word = u32(hword_lo) | (u32(hword_hi) << 16)
				ilen = 4
			} else {
				word = u32(hword_hi)
				ilen = 2
			}
		}

		inst: Instruction
		info: Instruction_Info
		info.offset = byte_count

		in_it_block := it_state & 0xF != 0
		if !find_and_decode(word, mode, ilen, byte_count, it_state, profile, &inst, &info) {
			append(errors, Error{inst_idx = byte_count, code = .INVALID_OPCODE})
			inst = Instruction{mnemonic = .INVALID, length = u8(ilen), mode = mode}
		} else {
			inst.length = u8(ilen)
			inst.mode   = mode
			inst.in_it_block = in_it_block
			inst_idx := u32(len(instructions))
			for slot in 0..<inst.operand_count {
				op := &inst.ops[slot]
				if op.kind == .RELATIVE && op.relative >= 0 {
					append(&pending_branches, isa.Branch_Target{
						inst_idx = inst_idx,
						op_idx   = slot,
						target   = u32(op.relative),
					})
				}
			}
		}

		// Advance ITSTATE past this instruction, or start a new block.
		if inst.mnemonic == .IT {
			it_state = u8(word & 0xFF)
		} else if in_it_block {
			if it_state & 0x7 == 0 {
				it_state = 0
			} else {
				it_state = (it_state & 0xE0) | ((it_state << 1) & 0x1F)
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

// =============================================================================
// Decode dispatch via primary-opcode index tables (generated)
// =============================================================================

@(private="file")
find_and_decode :: proc(word: u32, mode: Mode, ilen: u32, pc: u32, it_state: u8, profile: Profile, inst: ^Instruction, info: ^Instruction_Info) -> bool {
	in_it_block := it_state & 0xF != 0
	range: Decode_Index
	if mode == .A32 {
		range = DECODE_INDEX_A32[(word >> 20) & 0xFF]
	} else if ilen == 4 {
		// Try the T32 secondary index first (sub-bucketed by bits 24:20).
		primary := (word >> 25) & 0x7F
		sub     := (word >> 20) & 0x1F
		sub_range := DECODE_INDEX_T32_SUB[primary * DECODE_T32_SUB_BUCKETS + sub]
		if sub_range.count > 0 {
			range = sub_range
		} else {
			range = DECODE_INDEX_T32[primary]
		}
	} else {
		range = DECODE_INDEX_T16[(word >> 10) & 0x3F]
	}
	if range.count == 0 { return false }

	base := int(range.start)
	cnt  := int(range.count)
	for i in 0..<cnt {
		entry_idx := DECODE_BUCKET_LIST[base + i]
		e := &DECODE_ENTRIES[entry_idx]
		// Match the masked word against the masked base. Some entries use
		// `bits` as a "canonical" form (e.g. U=1 for positive-offset memory),
		// and the variable bits in `bits` must not affect the match decision.
		if (word & e.mask) != (e.bits & e.mask) { continue }
		if !feature_in_profile(e.feature, profile) { continue }
		if profile == .M_PROFILE && e.flags.a_profile_only { continue }

		// Match -- decode this entry
		inst.mnemonic      = e.mnemonic
		inst.operand_count = 0
		info.decode_entry  = entry_idx
		// Stamp the form-id hint. DECODE_FORM_IDX maps a DECODE_ENTRIES index
		// back to the index within ENCODING_TABLE[mnemonic]. Stored as
		// (form_idx + 1) so a zero hint means "not set".
		inst.form_id = DECODE_FORM_IDX[entry_idx] + 1
		// Carry the `.i32` suffix out with the instruction, so a decoded
		// instruction re-encodes to the same form without needing form_id.
		inst.dt = e.dt

		// Cond: A32 entries with bits[31:28] variable in mask take cond from word
		if e.flags.cond_in_21 {
			// Four conditions only, and not in their usual order.
			inst.cond = VSEL_CONDITIONS[(word >> 20) & 3]
		} else if mode == .A32 && (e.mask >> 28) == 0 {
			inst.cond = u8((word >> 28) & 0xF)
		} else if e.flags.thumb_condition {
			inst.cond = u8(ilen == 2 ? (word >> 8) & 0xF : (word >> 22) & 0xF)
		} else if in_it_block {
			inst.cond = it_state >> 4
		} else {
			inst.cond = 14    // AL / unconditional
		}
		if e.flags.sets_flags || (e.flags.flags_outside_it && !in_it_block) {
			inst.sets_flags = true
		}
		// LDM/STM carry the writeback in bit 21; nothing else in the operand
		// model records it, and without it the two forms print identically.
		for k in 0 ..< len(e.enc) {
			if e.enc[k] == .A32_REG_LIST || e.enc[k] == .T32_REG_LIST || e.enc[k] == .RN_A32_WB || e.enc[k] == .IMPL_SP {
				inst.writeback = (word >> 21) & 1 != 0
				break
			}
		}

		// Operands of Thumb Advanced SIMD read the A32 layout; see
		// is_thumb_simd.
		operand_word := word
		if mode == .T32 && is_thumb_simd(e.bits) {
			operand_word = thumb_simd_as_a32(word)
		}
		for _, k in e.enc {
			if e.enc[k] == .NONE { continue }
			op := unpack_operand(operand_word, e.enc[k], e.ops[k], pc, mode)
			inst.ops[k] = op
			inst.operand_count = u8(k + 1)
		}
		// A Thumb register list that names no register is not an
		// instruction, nor is a banked register the architecture does not
		// name, nor a Q register whose D-register field is odd; try the next
		// candidate.
		if !thumb_list_valid(e, inst) || !banked_valid(inst) || !q_registers_even(word, e) {
			continue
		}
		// The 16-bit STM always writes the base back. The 16-bit LDM does
		// unless it loads the base itself, and the syntax shows which.
		if e.enc[1] == .T16_REG_LIST {
			if e.mnemonic == .STM {
				inst.writeback = true
			} else {
				base := (word >> 8) & 7
				inst.writeback = (word >> base) & 1 == 0
			}
		}
		// For slots where the form declares an Operand_Type but the wire
		// encoding is .NONE (e.g. MOVW's imm16, SVC's imm24, T16 LDR's imm5),
		// fabricate a zero-valued operand of the right Operand_Kind so the
		// re-encode shape match succeeds. The encoder won't pack anything for
		// those slots since enc is .NONE; carrying a placeholder lets the
		// user-facing API still show the slot.
		for _, k in e.enc {
			if e.enc[k] != .NONE { continue }
			if e.ops[k] == .NONE { continue }
			inst.ops[k] = default_operand_for(e.ops[k])
			inst.operand_count = u8(k + 1)
		}
		return true
	}
	return false
}

@(private="file")
thumb_list_valid :: proc "contextless" (e: ^Decode_Entry, inst: ^Instruction) -> bool {
	if e.mode != .T32 {
		return true
	}
	for k in 0 ..< int(inst.operand_count) {
		if inst.ops[k].kind == .REG_LIST && inst.ops[k].immediate == 0 {
			return false
		}
	}
	return true
}

// A Q register is a pair of D registers, named by the even one; a Q-register
// field holding an odd D number is UNDEFINED.
@(private="file")
q_registers_even :: proc "contextless" (word: u32, e: ^Decode_Entry) -> bool {
	for enc in e.enc {
		if enc == .VD_Q && (word >> 12) & 1 != 0 { return false }
		if enc == .VN_Q && (word >> 16) & 1 != 0 { return false }
		if enc == .VM_Q && word & 1 != 0 { return false }
	}
	return true
}

@(private="file")
banked_valid :: proc "contextless" (inst: ^Instruction) -> bool {
	for k in 0 ..< int(inst.operand_count) {
		op := &inst.ops[k]
		if op.kind == .REGISTER && reg_class(op.reg) == REG_BANKED && banked_name(reg_hw(op.reg)) == "" {
			return false
		}
	}
	return true
}

// Produce a zero-valued operand of the kind implied by an Operand_Type. Used
// when a form's wire encoding is .NONE for a slot but the operand type slot
// is non-NONE; we want a placeholder of the right kind so the encoder's
// shape_matches accepts the re-encode.
@(private="file")
default_operand_for :: proc(ot: Operand_Type) -> Operand {
	#partial switch ot {
	case .GPR, .GPR_NOPC, .GPR_NOSP, .GPR_LOW, .GPR_SHIFTED, .GPR_RSR:
		return op_reg(R0)
	case .GPR_LIST:
		return op_reg_list(0)
	case .SPR:        return op_reg(S0)
	case .DPR:        return op_reg(D0)
	case .QPR:        return op_reg(Q0)
	case .DPR_ELEM:   return op_reg(D0)
	case .QPR_ELEM:   return op_reg(Q0)
	case .SPR_ELEM:   return op_reg(S0)
	case .SPR_LIST, .DPR_LIST:
		return op_reg_list(0)
	case .QPR_MVE_LIST:
		return op_reg_list(0)
	case .VPR, .QPR_MVE:
		return op_reg(Q0)
	case .MEM:        return op_mem(mem_imm(R0, 0))
	case .REL24, .REL24_T32, .REL20, .REL11, .REL8, .REL_LDR_LITERAL:
		return op_rel_offset(0)
	}
	return op_imm(0)
}

// =============================================================================
// Operand un-packers (inverse of pack_operand in encoder.odin)
// =============================================================================

//
// A PC-relative operand decodes to the absolute offset of its target. PC reads
// as the instruction's own address plus 8 in A32 and plus 4 in Thumb, and the
// Thumb literal loads and ADR measure from that rounded down to a word.
@(private="file")
unpack_operand :: proc(word: u32, enc: Operand_Encoding, ot: Operand_Type, pc: u32, mode: Mode) -> Operand {
	pc_value := i64(pc) + (mode == .A32 ? 8 : 4)
	pc_aligned := pc_value & ~i64(3)
	switch enc {
	case .NONE, .IMPL:
		return op_imm(0)

	// ---- GPR slots ----
	case .RD, .RT_A32, .RA_A32, .RDLO_A32:
		return op_reg(Register(REG_GPR | u16((word >> 12) & 0xF)))
	case .RT2_A32:
		return op_reg(Register(REG_GPR | u16((word >> 16) & 0xF)))
	case .RN_A32, .RDHI_A32:
		reg := Register(REG_GPR | u16((word >> 16) & 0xF))
		// Some atomics/exclusives use .MEM as the operand type with .RN_A32 as
		// the wire encoding (the assembly is `INSN Rd, Rt, [Rn]` — Rn appears
		// inside brackets). Wrap into a bare Memory operand so the encoder
		// shape match accepts it on roundtrip.
		if ot == .MEM { return op_mem(mem_imm(reg, 0)) }
		return op_reg(reg)
	case .RM_A32:
		reg := Register(REG_GPR | u16(word & 0xF))
		#partial switch ot {
		case .GPR_RSR:
			// Register-shifted register: Rs in bits 11..8, shift type in 6..5,
			// bit 4 = 1. We map the 2-bit shift type onto the .{LSL,LSR,ASR,
			// ROR}_REG markers so the encoder shape-match can distinguish
			// imm-shift from reg-shift. Rs is stored in shift_amt.
			st_bits := (word >> 5) & 0x3
			st  := Shift_Type(u8(st_bits) + u8(Shift_Type.LSL_REG))
			rs  := u8((word >> 8) & 0xF)
			return Operand{reg = reg, kind = .REGISTER, size = 4,
						   shift_type = st, shift_amt = rs}
		case .GPR_SHIFTED:
			// Imm-shift: amount in bits 11..7, type in 6..5, bit 4 = 0.
			st  := Shift_Type((word >> 5) & 0x3)
			amt := u8((word >> 7) & 0x1F)
			if st == .ROR && amt == 0 { return op_reg_shifted(reg, .RRX, 0) }
			if st == .LSL && amt == 0 { return op_reg(reg) }
			// A shift of zero is not a shift, so the field spends that
			// spare value on 32 instead -- the one amount five bits cannot
			// otherwise reach. LSL has no use for it and ROR spends it on
			// RRX, so only these two.
			if (st == .LSR || st == .ASR) && amt == 0 { return op_reg_shifted(reg, st, 32) }
			return op_reg_shifted(reg, st, amt)
		}
		return op_reg(reg)
	case .RS_A32:
		return op_reg(Register(REG_GPR | u16((word >> 8) & 0xF)))

	case .RD_T32:
		return op_reg(Register(REG_GPR | u16((word >> 8) & 0xF)))
	case .RN_T32:
		reg := Register(REG_GPR | u16((word >> 16) & 0xF))
		if ot == .MEM { return op_mem(mem_imm(reg, 0)) }
		return op_reg(reg)
	case .RM_T32:
		reg := Register(REG_GPR | u16(word & 0xF))
		if ot == .GPR_SHIFTED {
			// The amount is imm3:imm2, split around Rd; the type is bits 5:4.
			// Zero amounts mean what they mean in A32: no shift for LSL,
			// 32 for LSR and ASR, and RRX for ROR.
			shift := Shift_Type((word >> 4) & 0x3)
			amount := u8(((word >> 12) & 0x7) << 2 | (word >> 6) & 0x3)
			if shift == .ROR && amount == 0 { return op_reg_shifted(reg, .RRX, 0) }
			if shift == .LSL && amount == 0 { return op_reg(reg) }
			if (shift == .LSR || shift == .ASR) && amount == 0 { return op_reg_shifted(reg, shift, 32) }
			return op_reg_shifted(reg, shift, amount)
		}
		return op_reg(reg)
	case .RT_T32, .RA_T32:
		return op_reg(Register(REG_GPR | u16((word >> 12) & 0xF)))
	case .RT2_T32:
		return op_reg(Register(REG_GPR | u16((word >> 8) & 0xF)))

	case .RD_T16_LO:
		return op_reg(Register(REG_GPR | u16(word & 0x7)))
	case .RM_T16_LO, .RN_T16_LO:
		return op_reg(Register(REG_GPR | u16((word >> 3) & 0x7)))
	case .RD_T16_HI:
		rd := (word & 0x7) | ((word >> 7) & 1) << 3
		return op_reg(Register(REG_GPR | u16(rd)))
	case .RM_T16_HI:
		return op_reg(Register(REG_GPR | u16((word >> 3) & 0xF)))
	case .RM_T16_8_6:
		return op_reg(Register(REG_GPR | u16((word >> 6) & 0x7)))
	case .RD_T16_10_8:
		return op_reg(Register(REG_GPR | u16((word >> 8) & 0x7)))
	case .RD_T16_LO_AGAIN:
		return op_reg(Register(REG_GPR | u16(word & 0x7)))
	case .RD_T16_HI_AGAIN:
		return op_reg(Register(REG_GPR | u16((word & 0x7) | ((word >> 7) & 1) << 3)))

	// ---- T16 immediates ----
	case .IMM3_T16:          return op_imm(i64((word >> 6) & 0x7))
	case .IMM8_T16:          return op_imm(i64(word & 0xFF))
	case .IMM5_T16_SHIFT:    return op_imm(i64((word >> 6) & 0x1F))
	case .IMM5_T16_SHIFT_32:
		amount := (word >> 6) & 0x1F
		return op_imm(i64(amount == 0 ? 32 : amount))
	case .IMM7_T16_SCALED4:  return op_imm(i64(word & 0x7F) * 4)
	case .IMM8_T16_SCALED4:  return op_imm(i64(word & 0xFF) * 4)
	case .IMM6_T16:          return op_imm(i64(word & 0x3F))
	case .IMM4_T16_HINT:     return op_imm(i64((word >> 4) & 0xF))
	case .IT_FIRSTCOND:      return op_imm(i64((word >> 4) & 0xF))
	case .IT_MASK_FIELD:     return op_imm(i64(word & 0xF))
	case .SETEND_ENDIAN_T16: return op_reg(Register(REG_ENDIAN | u16((word >> 3) & 1)))
	case .SETPAN_IMM_T16:    return op_imm(i64((word >> 3) & 1))
	case .CPS_IFLAGS_T16:    return op_reg(Register(REG_IFLAGS | u16(word & 0x7)))

	// ---- T16 memory, lists and PC-relative ----
	case .MEM_T16_IMM5_W:
		return op_mem(mem_imm(Register(REG_GPR | u16((word >> 3) & 0x7)), i32((word >> 6) & 0x1F) * 4))
	case .MEM_T16_IMM5_B:
		return op_mem(mem_imm(Register(REG_GPR | u16((word >> 3) & 0x7)), i32((word >> 6) & 0x1F)))
	case .MEM_T16_IMM5_H:
		return op_mem(mem_imm(Register(REG_GPR | u16((word >> 3) & 0x7)), i32((word >> 6) & 0x1F) * 2))
	case .MEM_T16_REG:
		return op_mem(mem_reg(Register(REG_GPR | u16((word >> 3) & 0x7)), Register(REG_GPR | u16((word >> 6) & 0x7))))
	case .MEM_T16_SP_IMM8:
		return op_mem(mem_imm(SP, i32(word & 0xFF) * 4))
	case .MEM_T16_LITERAL, .REL_T16_ADR:
		return op_rel_offset(pc_aligned + i64(word & 0xFF) * 4)
	case .T16_REG_LIST:
		return op_reg_list(u16(word & 0xFF))
	case .T16_REG_LIST_LR:
		return op_reg_list(u16(word & 0xFF) | u16((word >> 8) & 1) << 14)
	case .T16_REG_LIST_PC:
		return op_reg_list(u16(word & 0xFF) | u16((word >> 8) & 1) << 15)

	// ---- T32 ----
	case .RM_T32_TWICE:
		return op_reg(Register(REG_GPR | u16(word & 0xF)))
	case .RM_T32_ROTATED:
		reg := Register(REG_GPR | u16(word & 0xF))
		rotation := u8((word >> 4) & 0x3) * 8
		if rotation == 0 { return op_reg(reg) }
		return op_reg_shifted(reg, .ROR, rotation)
	case .RN_T32_SAT:
		reg := Register(REG_GPR | u16((word >> 16) & 0xF))
		amount := u8(t32_shift_amount(word))
		if (word >> 21) & 1 == 0 {
			if amount == 0 { return op_reg(reg) }
			return op_reg_shifted(reg, .LSL, amount)
		}
		return op_reg_shifted(reg, .ASR, amount == 0 ? 32 : amount)
	case .T32_IMM12:
		return op_imm(i64(((word >> 26) & 1) << 11 | ((word >> 12) & 0x7) << 8 | (word & 0xFF)))
	case .T32_IMM16:
		return op_imm(i64(((word >> 16) & 0xF) << 12 | ((word >> 26) & 1) << 11 | ((word >> 12) & 0x7) << 8 | (word & 0xFF)))
	case .T32_IMM_SHIFT:
		return op_imm(i64(t32_shift_amount(word)))
	case .T32_IMM_SHIFT_32:
		amount := t32_shift_amount(word)
		return op_imm(i64(amount == 0 ? 32 : amount))
	case .T32_IMM4_IMM12:
		return op_imm(i64(((word >> 16) & 0xF) << 12 | (word & 0xFFF)))
	case .T32_IMM4_SMC:    return op_imm(i64((word >> 16) & 0xF))
	case .T32_IMM8:        return op_imm(i64(word & 0xFF))
	case .CPS_IFLAGS_T32:  return op_reg(Register(REG_IFLAGS | u16((word >> 5) & 0x7)))
	case .CPS_MODE_T32:    return op_imm(i64(word & 0x1F))
	case .MRS_SPEC_REG_T32:
		return op_reg(Register(REG_SREG | u16(((word >> 20) & 1) * 2)))
	case .MSR_FIELDS_T32:
		return op_reg(Register(REG_PSR_FIELDS | u16(((word >> 20) & 1) << 4 | (word >> 8) & 0xF)))
	case .SYSM_T32:
		return op_reg(Register(REG_SYSM | u16(word & 0xFF)))
	case .MSR_SYSM_T32:
		return op_reg(Register(REG_SYSM | u16(((word >> 10) & 0x3) << 8 | (word & 0xFF))))
	case .MEM_T32_IMM12:
		return op_mem(mem_imm(Register(REG_GPR | u16((word >> 16) & 0xF)), i32(word & 0xFFF)))
	case .MEM_T32_IMM8_NEG:
		m := mem_imm(Register(REG_GPR | u16((word >> 16) & 0xF)), -i32(word & 0xFF))
		m.sign = -1
		return op_mem(m)
	case .MEM_T32_IMM8_PRE, .MEM_T32_IMM8_POST:
		base := Register(REG_GPR | u16((word >> 16) & 0xF))
		disp := i32(word & 0xFF)
		up := (word >> 9) & 1 != 0
		if !up { disp = -disp }
		m := enc == .MEM_T32_IMM8_PRE ? mem_imm_pre(base, disp) : mem_imm_post(base, disp)
		if !up { m.sign = -1 }
		return op_mem(m)
	case .MEM_T32_IMM8_POS:
		return op_mem(mem_imm(Register(REG_GPR | u16((word >> 16) & 0xF)), i32(word & 0xFF)))
	case .MEM_T32_REG:
		base  := Register(REG_GPR | u16((word >> 16) & 0xF))
		index := Register(REG_GPR | u16(word & 0xF))
		amount := u8((word >> 4) & 0x3)
		if amount == 0 { return op_mem(mem_reg(base, index)) }
		return op_mem(mem_reg_shift(base, index, .LSL, amount))
	case .MEM_T32_LITERAL:
		disp := i64(word & 0xFFF)
		if (word >> 23) & 1 == 0 { disp = -disp }
		return op_rel_offset(pc_aligned + disp)
	case .MEM_T32_LITERAL_DUAL:
		disp := i64(word & 0xFF) * 4
		if (word >> 23) & 1 == 0 { disp = -disp }
		return op_rel_offset(pc_aligned + disp)
	case .MEM_T32_EXCLUSIVE:
		return op_mem(mem_imm(Register(REG_GPR | u16((word >> 16) & 0xF)), i32(word & 0xFF) * 4))
	case .MEM_T32_TABLE_B:
		return op_mem(mem_reg(Register(REG_GPR | u16((word >> 16) & 0xF)), Register(REG_GPR | u16(word & 0xF))))
	case .MEM_T32_TABLE_H:
		return op_mem(mem_reg_shift(Register(REG_GPR | u16((word >> 16) & 0xF)), Register(REG_GPR | u16(word & 0xF)), .LSL, 1))
	case .RD_T32_STATUS:
		return op_reg(Register(REG_GPR | u16(word & 0xF)))
	case .T32_REG_LIST:
		return op_reg_list(u16(word & 0xFFFF))
	case .REL_T32_ADR_ADD:
		return op_rel_offset(pc_aligned + i64(t32_imm12(word)))
	case .REL_T32_ADR_SUB:
		return op_rel_offset(pc_aligned - i64(t32_imm12(word)))
	case .RN_T32_ZR:
		n := (word >> 16) & 0xF
		return op_reg(n == 15 ? ZR : Register(REG_GPR | u16(n)))
	case .RM_T32_ZR:
		n := word & 0xF
		return op_reg(n == 15 ? ZR : Register(REG_GPR | u16(n)))
	case .COND_T32_FCOND:
		return op_reg(Register(REG_COND | u16((word >> 4) & 0xF)))
	case .BANKED_MRS_T32:
		return op_reg(Register(REG_BANKED | u16(banked_number((word >> 20) & 1, (word >> 4) & 1, (word >> 16) & 0xF))))
	case .BANKED_MSR_T32:
		return op_reg(Register(REG_BANKED | u16(banked_number((word >> 20) & 1, (word >> 4) & 1, (word >> 8) & 0xF))))
	case .LOB_FORWARD:
		return op_rel_offset(pc_value + i64(lob_offset(word)))
	case .LOB_BACKWARD:
		return op_rel_offset(pc_value - i64(lob_offset(word)))
	case .BRANCH_BLX_T32:
		s     := (word >> 26) & 1
		j1    := (word >> 13) & 1
		j2    := (word >> 11) & 1
		imm10 := (word >> 16) & 0x3FF
		low   := (word >> 1) & 0x3FF
		i1 := j1 ~ (s ~ 1)
		i2 := j2 ~ (s ~ 1)
		v := (s << 22) | (i1 << 21) | (i2 << 20) | (imm10 << 10) | low
		if v & (1 << 22) != 0 { v |= ~u32(0x7FFFFF) }
		return op_rel_offset(pc_aligned + i64(i32(v) << 2))

	// ---- Modified immediates (decoded to their effective 32-bit value) ----
	case .A32_IMM_MOD, .A32_IMM12_ROT:
		return op_imm(i64(decode_a32_modimm(word & 0xFFF)))
	case .T32_IMM_MOD:
		i_bit := (word >> 26) & 1
		imm3  := (word >> 12) & 0x7
		imm8  :=  word        & 0xFF
		f12 := (i_bit << 11) | (imm3 << 8) | imm8
		return op_imm(i64(decode_t32_modimm(f12)))

	// ---- A32 immediates ----
	case .A32_IMM12:    return op_imm(i64(word & 0xFFF))
	case .A32_IMM_SHIFT: return op_imm(i64((word >> 7) & 0x1F))
	case .A32_IMM_SHIFT_32:
		// The LSR and ASR mnemonics reach 32 the same way a shifted operand
		// does: a field of zero, since a shift of zero would be a MOV.
		amt := (word >> 7) & 0x1F
		return op_imm(i64(amt == 0 ? 32 : amt))
	case .A32_SHIFT_TYPE: return op_imm(i64((word >> 5) & 0x3))
	case .A32_IMM24:
		// Ambiguous: A32_IMM24 is used both for branch displacements (B/BL,
		// shape REL24) and for the 24-bit `imm` of SVC (shape IMM). Use the
		// form's operand type to disambiguate.
		if ot == .IMM {
			return op_imm(i64(word & 0xFFFFFF))
		}
		v := i32(word & 0xFFFFFF)
		if v & 0x800000 != 0 { v |= -0x1000000 }
		return op_rel_offset(pc_value + i64(v << 2))
	case .A32_IMM4:      return op_imm(i64(word & 0xF))
	case .A32_IMM4_ROTATE: return op_imm(i64((word >> 8) & 0xF))
	case .A32_IMM5_LSB:  return op_imm(i64((word >> 7) & 0x1F))
	case .A32_IMM5_W:    return op_imm(i64((word >> 16) & 0x1F))
	case .A32_REG_LIST:  return op_reg_list(u16(word & 0xFFFF))

	// ---- VFP/NEON split fields ----
	case .VD_S:
		n := ((word >> 12) & 0xF) << 1 | ((word >> 22) & 1)
		return op_reg(Register(REG_SPR | u16(n)))
	case .VN_S:
		n := ((word >> 16) & 0xF) << 1 | ((word >> 7) & 1)
		return op_reg(Register(REG_SPR | u16(n)))
	case .VM_S:
		n := (word & 0xF) << 1 | ((word >> 5) & 1)
		return op_reg(Register(REG_SPR | u16(n)))
	case .VD_D:
		n := ((word >> 22) & 1) << 4 | ((word >> 12) & 0xF)
		return op_reg(Register(REG_DPR | u16(n)))
	case .VN_D:
		n := ((word >> 7) & 1) << 4 | ((word >> 16) & 0xF)
		return op_reg(Register(REG_DPR | u16(n)))
	case .VM_D:
		n := ((word >> 5) & 1) << 4 | (word & 0xF)
		return op_reg(Register(REG_DPR | u16(n)))
	case .NEON_VM_SCALAR16:
		lane := ((word >> 5) & 1) << 1 | ((word >> 3) & 1)
		return op_dpr_lane(Register(REG_DPR | u16(word & 0x7)), u8(lane))
	case .NEON_VM_SCALAR32:
		return op_dpr_lane(Register(REG_DPR | u16(word & 0xF)), u8((word >> 5) & 1))
	case .VMOV_LANE_8, .VMOV_LANE_16, .VMOV_LANE_32:
		n := ((word >> 7) & 1) << 4 | ((word >> 16) & 0xF)
		lane: u32 = 0
		if enc == .VMOV_LANE_8 {
			lane = ((word >> 21) & 1) << 2 | ((word >> 6) & 1) << 1 | ((word >> 5) & 1)
		} else if enc == .VMOV_LANE_16 {
			lane = ((word >> 21) & 1) << 1 | ((word >> 6) & 1)
		} else {
			lane = (word >> 21) & 1
		}
		return op_dpr_lane(Register(REG_DPR | u16(n)), u8(lane))
	case .MVE_ROT_HCADD:
		return op_imm(((word >> 12) & 1) == 1 ? 270 : 90)
	case .MVE_ROT_CMLA:
		return op_imm(i64((word >> 23) & 0x3) * 90)
	case .VN_Q_MVE:
		return op_reg(Register(REG_QPR | u16((word >> 17) & 0x7)))
	case .VM_Q_MVE:
		return op_reg(Register(REG_QPR | u16((word >> 1) & 0x7)))
	case .VD_Q:
		n := (((word >> 22) & 1) << 4 | ((word >> 12) & 0xF)) >> 1
		return op_reg(Register(REG_QPR | u16(n)))
	case .VN_Q:
		n := (((word >> 7) & 1) << 4 | ((word >> 16) & 0xF)) >> 1
		return op_reg(Register(REG_QPR | u16(n)))
	case .VM_Q:
		n := (((word >> 5) & 1) << 4 | (word & 0xF)) >> 1
		return op_reg(Register(REG_QPR | u16(n)))

	// ---- Memory ----
	case .MEM_IMM12_OFFSET:
		base := Register(REG_GPR | u16((word >> 16) & 0xF))
		u_bit := (word >> 23) & 1
		disp := i32(word & 0xFFF)
		if u_bit == 0 { disp = -disp }
		mm := mem_imm(base, disp)
		if u_bit == 0 { mm.sign = -1 }
		return op_mem(mm)
	case .MEM_IMM8_SCALED2:
		base := Register(REG_GPR | u16((word >> 16) & 0xF))
		disp := i32(word & 0xFF) * 2
		up := (word >> 23) & 1 != 0
		mm := mem_imm(base, up ? disp : -disp)
		if !up { mm.sign = -1 }
		return op_mem(mm)
	case .MEM_IMM8_SCALED4, .MEM_IMM8_SCALED4_PRE, .MEM_IMM8_SCALED4_POST:
		// The VFP and coprocessor loads count the offset in words, so the
		// eight bits reach +/-1020 rather than +/-255.
		base := Register(REG_GPR | u16((word >> 16) & 0xF))
		u_bit := (word >> 23) & 1
		disp := i32(word & 0xFF) * 4
		if u_bit == 0 { disp = -disp }
		mm := mem_imm(base, disp)
		if enc == .MEM_IMM8_SCALED4_PRE  { mm.mode = .PRE_INDEX  }
		if enc == .MEM_IMM8_SCALED4_POST { mm.mode = .POST_INDEX }
		if u_bit == 0 { mm.sign = -1 }
		return op_mem(mm)
	case .MEM_IMM8_OFFSET:
		base := Register(REG_GPR | u16((word >> 16) & 0xF))
		u_bit := (word >> 23) & 1
		disp := i32(((word >> 8) & 0xF) << 4 | (word & 0xF))
		if u_bit == 0 { disp = -disp }
		mm := mem_imm(base, disp)
		if u_bit == 0 { mm.sign = -1 }
		return op_mem(mm)
	case .MEM_REG_OFFSET:
		base := Register(REG_GPR | u16((word >> 16) & 0xF))
		idx  := Register(REG_GPR | u16(word & 0xF))
		sign: i8 = (word >> 23) & 1 != 0 ? 1 : -1
		return op_mem(mem_reg(base, idx, sign))
	case .MEM_DOUBLEREG:
		base := Register(REG_GPR | u16((word >> 16) & 0xF))
		idx  := Register(REG_GPR | u16(word & 0xF))
		return op_mem(mem_reg(base, idx))

	// ---- Misc ----
	case .BARRIER_TYPE: return op_imm(i64(word & 0xF))
	case .HINT_FIELD:   return op_imm(i64(word & 0xFF))
	case .CPS_IFLAGS:   return op_imm(i64(word & 0x1FF))
	case .PSR_FIELD_MASK: return op_imm(i64(decode_psr_field(word)))
	case .SYSM_FIELD:   return op_imm(i64(word & 0xFF))
	case .COPROC_NUM_FIELD:  return op_reg(Register(REG_COPROC_NUM | u16((word >> 8) & 0xF)))
	case .COPROC_OPC1_FIELD: return op_imm(i64((word >> 20) & 0xF))
	case .COPROC_OPC2_FIELD: return op_imm(i64((word >> 5) & 0x7))
	case .COPROC_CRN_FIELD:  return op_reg(Register(REG_COPROC | u16((word >> 16) & 0xF)))
	case .COPROC_CRM_FIELD:  return op_reg(Register(REG_COPROC | u16(word & 0xF)))
	case .COPROC_CRD_FIELD:  return op_reg(Register(REG_COPROC | u16((word >> 12) & 0xF)))
	case .COPROC_OPC1_MCR:   return op_imm(i64((word >> 21) & 0x7))
	case .COPROC_OPC_MCRR:   return op_imm(i64((word >> 4) & 0xF))
	case .NEON_CMODE:        return op_imm(i64((word >> 8) & 0xF))
	case .NEON_OP_BIT:       return op_imm(i64((word >> 5) & 1))
	case .NEON_IMM8_ABCDEFGH:
		// Reconstruct abcdefgh from scattered wire bits, then apply cmode/op
		// expansion via decode_neon_modimm.
		a := extract_neon_modimm_abcdefgh(word)
		cmode := (word >> 8) & 0xF
		op := (word >> 5) & 1
		v := decode_neon_modimm(a, cmode, op)
		// Only cmode 1111 expands to a float; the rest are bit patterns,
		// sixty-four bits wide for the .i64 form.
		if cmode == 0b1111 { return op_float_imm(u32(v)) }
		return Operand{immediate = i64(v), kind = .HEX_IMMEDIATE, size = 8}
	case .DBG_OPTION:    return op_imm(i64(word & 0xF))
	case .MRS_SPEC_REG:  return op_reg(Register(REG_SREG | u16(((word >> 22) & 1) * 2)))
	case .VFP_SPEC_REG:  return op_reg(Register(REG_FPSC | u16((word >> 16) & 0xF)))
	case .SETEND_ENDIAN: return op_reg(Register(REG_ENDIAN | u16((word >> 9) & 1)))
	case .IMPL_SP:       return op_reg(SP)
	case .IMPL_PC:       return op_reg(PC)
	case .IMPL_LR:       return op_reg(LR)
	case .IMPL_R12:      return op_reg(R12)
	case .MODE_IMM5:     return op_imm(i64(word & 0x1F))
	case .RN_A32_WB:     return op_reg(Register(REG_GPR | u16((word >> 16) & 0xF)))
	case .VM_S_PLUS1:
		// The second of a consecutive pair; only the first is encoded.
		return op_reg(Register(REG_SPR | u16(((word & 0xF) << 1 | ((word >> 5) & 1)) + 1)))
	case .NEON_LANE_VN_32:
		n := ((word >> 7) & 1) << 4 | ((word >> 16) & 0xF)
		return op_dpr_lane(Register(REG_DPR | u16(n)), u8((word >> 21) & 1))
	case .VFP_IMM8:
		a := ((word >> 16) & 0xF) << 4 | (word & 0xF)
		// Held as the 32-bit pattern whatever the form's width: it is the
		// same value either way, and it is what re-encoding needs back.
		return op_float_imm(decode_vfp_imm8_f32(a))
	case .NEON_D_LIST_1:
		n := ((word >> 22) & 1) << 4 | ((word >> 12) & 0xF)
		return op_reg_run(Register(REG_DPR | u16(n)), 1, 1, false)
	case .NEON_D_LIST_2:
		n := ((word >> 22) & 1) << 4 | ((word >> 12) & 0xF)
		return op_reg_run(Register(REG_DPR | u16(n)), 2, 1, false)
	case .NEON_D_LIST_3:
		n := ((word >> 22) & 1) << 4 | ((word >> 12) & 0xF)
		return op_reg_run(Register(REG_DPR | u16(n)), 3, 1, false)
	case .NEON_D_LIST_4:
		n := ((word >> 22) & 1) << 4 | ((word >> 12) & 0xF)
		return op_reg_run(Register(REG_DPR | u16(n)), 4, 1, false)
	case .NEON_D_LIST_2X:
		n := ((word >> 22) & 1) << 4 | ((word >> 12) & 0xF)
		return op_reg_run(Register(REG_DPR | u16(n)), 2, 2, false)
	case .NEON_D_LIST_3X:
		n := ((word >> 22) & 1) << 4 | ((word >> 12) & 0xF)
		return op_reg_run(Register(REG_DPR | u16(n)), 3, 2, false)
	case .NEON_D_LIST_4X:
		n := ((word >> 22) & 1) << 4 | ((word >> 12) & 0xF)
		return op_reg_run(Register(REG_DPR | u16(n)), 4, 2, false)
	case .NEON_D_LIST_ALL:
		n := ((word >> 22) & 1) << 4 | ((word >> 12) & 0xF)
		return op_reg_run(Register(REG_DPR | u16(n)), 1, 1, true)
	case .NEON_D_LIST_ALL_2, .NEON_D_LIST_ALL_3, .NEON_D_LIST_ALL_4:
		n := ((word >> 22) & 1) << 4 | ((word >> 12) & 0xF)
		count := u8(2 + (int(enc) - int(Operand_Encoding.NEON_D_LIST_ALL_2)))
		return op_reg_run(Register(REG_DPR | u16(n)), count,
		                  ((word >> 5) & 1) != 0 ? 2 : 1, true)
	case .NEON_LANE_D_8, .NEON_LANE_D_16, .NEON_LANE_D_32, .NEON_LANE_D_8_2, .NEON_LANE_D_16_2, .NEON_LANE_D_32_2, .NEON_LANE_D_8_3, .NEON_LANE_D_16_3, .NEON_LANE_D_32_3, .NEON_LANE_D_8_4, .NEON_LANE_D_16_4, .NEON_LANE_D_32_4:
		n := ((word >> 22) & 1) << 4 | ((word >> 12) & 0xF)
		shift, mask, count := neon_lane_shape(enc)
		op := op_dpr_lane(Register(REG_DPR | u16(n)), u8((word >> shift) & mask))
		op.list = {count = count, stride = 1}
		return op
	case .NEON_VDUP_LANE_8, .NEON_VDUP_LANE_16, .NEON_VDUP_LANE_32:
		imm4 := (word >> 16) & 0xF
		shift: u32 = enc == .NEON_VDUP_LANE_8 ? 1 : enc == .NEON_VDUP_LANE_16 ? 2 : 3
		return op_dpr_lane(Register(REG_DPR | u16(((word >> 5) & 1) << 4 | (word & 0xF))),
		                   u8(imm4 >> shift))
	case .NEON_VM_SCALAR_16:
		return op_dpr_lane(Register(REG_DPR | u16(word & 0x7)),
		                   u8(((word >> 5) & 1) << 1 | ((word >> 3) & 1)))
	case .NEON_VM_SCALAR_32:
		return op_dpr_lane(Register(REG_DPR | u16(word & 0xF)), u8((word >> 5) & 1))
	case .NEON_VN_TABLE_1, .NEON_VN_TABLE_2, .NEON_VN_TABLE_3, .NEON_VN_TABLE_4:
		n := ((word >> 7) & 1) << 4 | ((word >> 16) & 0xF)
		return op_reg_run(Register(REG_DPR | u16(n)), table_run_length(enc))
	case .VFP_S_LIST:
		// {S<Vd>, ...} -- imm8 counts the registers, and the run starts at Vd.
		// Both halves matter: keeping only the count printed the wrong bank
		// and the wrong registers. A count that runs past s31 is
		// UNPREDICTABLE; the list stops at the last register, as every
		// disassembler prints it.
		n := ((word >> 12) & 0xF) << 1 | ((word >> 22) & 1)
		return op_reg_run(Register(REG_SPR | u16(n)), u8(clamp(word & 0xFF, 1, 32 - n)))
	case .VFP_D_LIST, .VFP_DX_LIST:
		// {D<Vd>, ...} -- imm8 counts words, two per D register; the FLDMX
		// and FSTMX forms add one more, so their count is odd.
		n := ((word >> 22) & 1) << 4 | ((word >> 12) & 0xF)
		return op_reg_run(Register(REG_DPR | u16(n)), u8(clamp((word & 0xFF) / 2, 1, 32 - n)))

	// ---- Branch fields (decoded into RELATIVE) ----
	case .BRANCH_24:
		v := i32(word & 0xFFFFFF)
		if v & 0x800000 != 0 { v |= -0x1000000 }
		return op_rel_offset(pc_value + i64(v << 2))
	case .BRANCH_24_T32:
		// T32 25-bit signed scattered: S | I1 | I2 | imm10 | imm11
		s    := (word >> 26) & 1
		j1   := (word >> 13) & 1
		j2   := (word >> 11) & 1
		imm10 := (word >> 16) & 0x3FF
		imm11 :=  word        & 0x7FF
		i1 := j1 ~ (s ~ 1)
		i2 := j2 ~ (s ~ 1)
		v := (s << 23) | (i1 << 22) | (i2 << 21) | (imm10 << 11) | imm11
		if v & (1 << 23) != 0 { v |= ~u32(0xFFFFFF) }
		return op_rel_offset(pc_value + i64(i32(v) << 1))
	case .BRANCH_20_T32:
		// T32 21-bit signed for B<cond>
		s     := (word >> 26) & 1
		j1    := (word >> 13) & 1
		j2    := (word >> 11) & 1
		imm6  := (word >> 16) & 0x3F
		imm11 :=  word        & 0x7FF
		// S:J2:J1:imm6:imm11 -- J2 above J1, though J1 sits higher in the word.
		v := (s << 19) | (j2 << 18) | (j1 << 17) | (imm6 << 11) | imm11
		if v & (1 << 19) != 0 { v |= ~u32(0xFFFFF) }
		return op_rel_offset(pc_value + i64(i32(v) << 1))
	case .BRANCH_11_T16:
		v := word & 0x7FF
		if v & 0x400 != 0 { v |= ~u32(0x7FF) }
		return op_rel_offset(pc_value + i64(i32(v) << 1))
	case .BRANCH_8_T16:
		v := word & 0xFF
		if v & 0x80 != 0 { v |= ~u32(0xFF) }
		return op_rel_offset(pc_value + i64(i32(v) << 1))
	case .BRANCH_CBZ:
		i_bit := (word >> 9) & 1
		imm5  := (word >> 3) & 0x1F
		v := (i_bit << 6) | (imm5 << 1)
		return op_rel_offset(pc_value + i64(v))
	// ---- ARMv8.1-M Branch Future ----
	case .BF_BOFF:
		imm4 := (word >> 23) & 0xF          // hw0[10:7]
		return op_rel_offset(pc_value + i64(imm4) << 1)
	case .BF_BLOC:
		j     := (word >> 11) & 1           // hw1[11]
		imm10 := (word >> 1)  & 0x3FF       // hw1[10:1]
		val   := (imm10 << 1) | j
		return op_rel_offset(pc_value + i64(val) << 1)
	case .BF_RM:
		return op_reg(Register(REG_GPR | u16((word >> 16) & 0xF)))
	case .BFCSEL_COND:
		return op_imm(i64((word >> 18) & 0xF))

	// ---- Saturate / bit field ----
	case .NEON_SHLL_8:  return op_imm(8)
	case .NEON_SHLL_16: return op_imm(16)
	case .NEON_SHLL_32: return op_imm(32)
	case .NEON_ROT_2:   return op_imm(((word >> 24) & 1) != 0 ? 270 : 90)
	case .NEON_ROT_4:   return op_imm(i64(((word >> 20) & 3) * 90))
	case .NEON_ROT_4_HI: return op_imm(i64(((word >> 23) & 3) * 90))
	case .VFP_FBITS:
		// The fixed-point width is 16 or 32 by the sx bit, and the fraction
		// is that less imm4:i -- so the widest fraction encodes as zero. A
		// 16-bit form whose field exceeds 16 is UNPREDICTABLE, and comes out
		// negative rather than wrapping.
		width: i64 = ((word >> 7) & 1) != 0 ? 32 : 16
		return op_imm(width - i64(((word & 0xF) << 1) | ((word >> 5) & 1)))
	case .VD_S_AGAIN:
		n := ((word >> 12) & 0xF) << 1 | ((word >> 22) & 1)
		return op_reg(Register(REG_SPR | u16(n)))
	case .VD_D_AGAIN:
		n := ((word >> 22) & 1) << 4 | ((word >> 12) & 0xF)
		return op_reg(Register(REG_DPR | u16(n)))
	case .RT_VMRS:
		rt := (word >> 12) & 0xF
		return op_reg(rt == 15 ? APSR_NZCV : Register(REG_GPR | u16(rt)))
	case .SAT_IMM5:
		// SSAT and SSAT16 saturate to a signed width of one to 32, and the
		// field holds one less than that. USAT and USAT16 saturate to an
		// unsigned width of zero to 31, which the field holds as it stands.
		return op_imm(i64(((word >> 16) & 0x1F) + 1))
	case .SAT_IMM5_U:
		return op_imm(i64((word >> 16) & 0x1F))
	case .SAT_IMM5_T32:      return op_imm(i64((word & 0x1F) + 1))
	case .SAT_IMM5_U_T32:    return op_imm(i64(word & 0x1F))
	case .SAT16_IMM4_T32:    return op_imm(i64((word & 0xF) + 1))
	case .SAT16_IMM4_U_T32:  return op_imm(i64(word & 0xF))
	case .BFX_WIDTH:
		// One less than the width.
		return op_imm(i64(((word >> 16) & 0x1F) + 1))
	case .BFI_MSB:
		// The top bit's position; the syntax wants the width.
		return op_imm(i64(((word >> 16) & 0x1F) - ((word >> 7) & 0x1F) + 1))
	case .BFI_LSB:
		return op_imm(i64((word >> 7) & 0x1F))
	case .BFI_LSB_T32:
		return op_imm(i64(t32_shift_amount(word)))
	case .BFI_MSB_T32:
		return op_imm(i64((word & 0x1F) - t32_shift_amount(word) + 1))
	case .BFX_WIDTH_T32:
		return op_imm(i64((word & 0x1F) + 1))
	case .NEON_SHIFT_IMM6:
		return op_imm(i64((word >> 16) & 0x3F))
	case .NEON_SHIFT_IMM3:
		return op_imm(i64((word >> 16) & 0x7))
	case .NEON_SHIFT_IMM4:
		return op_imm(i64((word >> 16) & 0xF))
	case .NEON_SHIFT_IMM5:
		return op_imm(i64((word >> 16) & 0x1F))

	// ---- A32 RS shift (Rs register in bits 11:8) ----
	case .A32_RS_SHIFT:
		return op_reg(Register(REG_GPR | u16((word >> 8) & 0xF)))

	// ---- A32 COND ----
	case .A32_COND_FIELD: return op_imm(i64((word >> 28) & 0xF))

	// ---- MVE Q-registers (3-bit indexed) ----
	case .QD_MVE:
		n := (word >> 13) & 0x7
		return op_reg(Register(REG_QPR | u16(n)))
	case .QN_MVE:
		n := ((word >> 17) & 0x7) | (((word >> 7) & 1) << 3)
		return op_reg(Register(REG_QPR | u16(n & 0x7)))
	case .MVE_RDA_EVEN, .MVE_RDALO:
		return op_reg(Register(REG_GPR | u16(((word >> 13) & 0x7) * 2)))
	case .MVE_RDAHI:
		return op_reg(Register(REG_GPR | u16(((word >> 20) & 0x7) * 2 + 1)))
	case .QM_MVE:
		n := (word >> 1) & 0x7
		return op_reg(Register(REG_QPR | u16(n)))
	case .MVE_SIZE_FIELD:      return op_imm(i64((word >> 20) & 0x3))
	case .MVE_VPT_MASK_FIELD:  return op_imm(i64((word >> 13) & 0xF))
	case .MVE_LOOP_IMM:
		// ARMv8.1-M loop-branch imm11 sign-extended
		v := (word >> 1) & 0x7FF
		if v & 0x400 != 0 { v |= ~u32(0x7FF) }
		return op_rel_offset(pc_value + i64(i32(v) << 1))

	case .CDE_COPROC_FIELD:    return op_imm(i64((word >> 8) & 0x7))
	case .CDE_IMM_FIELD:       return op_imm(i64(word & 0x7F))
	case .CDE_ACC_FIELD:       return op_imm(i64((word >> 16) & 1))
	case .V8M_TT_AT_BITS:      return op_imm(i64((word >> 6) & 0x3))

	// ---- Memory addressing flavours ----
	// PRE_INDEX and POST_INDEX wrap MEM_IMM12_OFFSET: same field layout but the
	// addressing mode flag is set differently. We reconstruct the full Memory
	// operand here (base, disp, sign, mode).
	case .RT2_A32_PAIR:
		return op_reg(Register(REG_GPR | u16(((word >> 12) + 1) & 0xF)))
	case .MEM_IMM8_PRE_INDEX:
		base := Register(REG_GPR | u16((word >> 16) & 0xF))
		disp := i32(((word >> 8) & 0xF) << 4 | (word & 0xF))
		if (word >> 23) & 1 == 0 { disp = -disp }
		mm := mem_imm_pre(base, disp)

		if (word >> 23) & 1 == 0 { mm.sign = -1 }

		return op_mem(mm)
	case .MEM_IMM8_POST_INDEX:
		base := Register(REG_GPR | u16((word >> 16) & 0xF))
		disp := i32(((word >> 8) & 0xF) << 4 | (word & 0xF))
		if (word >> 23) & 1 == 0 { disp = -disp }
		mm := mem_imm_post(base, disp)

		if (word >> 23) & 1 == 0 { mm.sign = -1 }

		return op_mem(mm)
	case .MEM_PRE_INDEX:
		base := Register(REG_GPR | u16((word >> 16) & 0xF))
		u_bit := (word >> 23) & 1
		disp := i32(word & 0xFFF)
		if u_bit == 0 { disp = -disp }
		mm := mem_imm_pre(base, disp)
		if u_bit == 0 { mm.sign = -1 }
		return op_mem(mm)
	case .MEM_POST_INDEX:
		base := Register(REG_GPR | u16((word >> 16) & 0xF))
		u_bit := (word >> 23) & 1
		disp := i32(word & 0xFFF)
		if u_bit == 0 { disp = -disp }
		mm := mem_imm_post(base, disp)
		if u_bit == 0 { mm.sign = -1 }
		return op_mem(mm)
	case .MEM_LITERAL:
		// PC-relative literal load: U bit + 12-bit signed disp
		u_bit := (word >> 23) & 1
		disp := i32(word & 0xFFF)
		if u_bit == 0 { disp = -disp }
		return op_rel_offset(pc_aligned + i64(disp))
	}
	return op_imm(0)
}


// -----------------------------------------------------------------------------
// Buffer-Sizing Helpers (let callers pre-size so the decode hot path never
// reallocates; allocates no new buffers -- only the caller's arrays grow).
// -----------------------------------------------------------------------------

// Instruction-count ceiling for `data` (A32 is 4 bytes, Thumb 2; minimum 2).
@(require_results)
decode_max_instruction_count :: #force_inline proc "contextless" (data: []u8) -> int {
	return len(data) / 2
}

// The imm3:imm2 field Thumb-2 splits around Rd: bits 14:12 and 7:6.
@(private="file", require_results)
t32_shift_amount :: #force_inline proc "contextless" (word: u32) -> u32 {
	return ((word >> 12) & 0x7) << 2 | (word >> 6) & 0x3
}

// The low-overhead loops' offset: imml:immh:'0', imml at 10:1 and immh at 11.
@(private="file", require_results)
lob_offset :: #force_inline proc "contextless" (word: u32) -> u32 {
	return ((word >> 1) & 0x3FF) << 2 | ((word >> 11) & 1) << 1
}

// A banked register's number: R (SPSR rather than a core register) above
// SYSm, which is m:m1.
@(private="file", require_results)
banked_number :: #force_inline proc "contextless" (r, m, m1: u32) -> u32 {
	return r << 5 | m << 4 | m1
}

// i:imm3:imm8, the plain 12-bit immediate of ADDW, SUBW and ADR.
@(private="file", require_results)
t32_imm12 :: #force_inline proc "contextless" (word: u32) -> u32 {
	return ((word >> 26) & 1) << 11 | ((word >> 12) & 0x7) << 8 | (word & 0xFF)
}

// How many D registers a VTBL/VTBX table spans.
@(private="file", require_results)
table_run_length :: #force_inline proc "contextless" (e: Operand_Encoding) -> u8 {
	#partial switch e {
	case .NEON_VN_TABLE_1: return 1
	case .NEON_VN_TABLE_2: return 2
	case .NEON_VN_TABLE_3: return 3
	case .NEON_VN_TABLE_4: return 4
	}
	return 1
}

// The conditions VSEL can name, in the order bits 21:20 give them.
@(private="file")
VSEL_CONDITIONS := [4]u8{0, 6, 10, 12}   // EQ, VS, GE, GT

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

// The lane field's position and the list length for a NEON single-lane
// load/store. The lane sits just above the alignment bits, and how far above
// follows the element size: bits 7:5 for .8, 7:6 for .16, bit 7 for .32.
@(private="file", require_results)
neon_lane_shape :: #force_inline proc "contextless" (e: Operand_Encoding) -> (shift, mask: u32, count: u8) {
	#partial switch e {
	case .NEON_LANE_D_8:    return 5, 0x7, 1
	case .NEON_LANE_D_16:   return 6, 0x3, 1
	case .NEON_LANE_D_32:   return 7, 0x1, 1
	case .NEON_LANE_D_8_2:  return 5, 0x7, 2
	case .NEON_LANE_D_16_2: return 6, 0x3, 2
	case .NEON_LANE_D_32_2: return 7, 0x1, 2
	case .NEON_LANE_D_8_3:  return 5, 0x7, 3
	case .NEON_LANE_D_16_3: return 6, 0x3, 3
	case .NEON_LANE_D_32_3: return 7, 0x1, 3
	case .NEON_LANE_D_8_4:  return 5, 0x7, 4
	case .NEON_LANE_D_16_4: return 6, 0x3, 4
	case:                   return 7, 0x1, 4
	}
}
