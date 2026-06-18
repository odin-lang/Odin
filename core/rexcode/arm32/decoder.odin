// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm32

import "../isa"

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
) -> Result {
	n_bytes := u32(len(data))
	if mode == .T32 { n_bytes = n_bytes & ~u32(1) }
	else            { n_bytes = n_bytes & ~u32(3) }

	errors_start := u32(len(errors))

	pending_branches: [dynamic]isa.Branch_Target
	defer delete(pending_branches)

	pc: u32 = 0
	for pc < n_bytes {
		word: u32
		ilen: u32 = 4

		if mode == .A32 {
			if pc + 4 > n_bytes { break }
			word = read_u32_le(data, pc)
		} else {
			// T32: 16 or 32 bit
			hword_hi := read_u16_le(data, pc)
			top5 := (hword_hi >> 11) & 0x1F
			if top5 == 0x1D || top5 == 0x1E || top5 == 0x1F {
				if pc + 4 > n_bytes { break }
				hword_lo := read_u16_le(data, pc + 2)
				// Pack: bits = low_halfword | (high_halfword << 16)
				word = u32(hword_lo) | (u32(hword_hi) << 16)
				ilen = 4
			} else {
				word = u32(hword_hi)
				ilen = 2
			}
		}

		inst: Instruction
		info: Instruction_Info
		info.offset = pc

		if !find_and_decode(word, mode, ilen, &inst, &info) {
			append(errors, Error{inst_idx = pc, code = .INVALID_OPCODE})
			inst = Instruction{mnemonic = .INVALID, length = u8(ilen), mode = mode}
		} else {
			inst.length = u8(ilen)
			inst.mode   = mode
			// Pull condition out of bits 31:28 for conditional A32 entries.
			// The find_and_decode helper has already set inst.cond using the
			// mask-based test (mask bits 31:28 == 0 ⇒ conditional). See
			// encoding_types.odin for the rationale.
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

		append(instructions, inst)
		append(inst_info,    info)
		pc += ilen
	}

	isa.infer_labels_from_branches(pending_branches[:], pc, label_defs, relocs)
	return Result{byte_count = pc, success = u32(len(errors)) == errors_start}
}

// =============================================================================
// Decode dispatch via primary-opcode index tables (generated)
// =============================================================================

@(private="file")
find_and_decode :: proc(word: u32, mode: Mode, ilen: u32, inst: ^Instruction, info: ^Instruction_Info) -> bool {
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

		// Match -- decode this entry
		inst.mnemonic      = e.mnemonic
		inst.operand_count = 0
		info.decode_entry  = entry_idx
		// Stamp the form-id hint. DECODE_FORM_IDX maps a DECODE_ENTRIES index
		// back to the index within ENCODING_TABLE[mnemonic]. Stored as
		// (form_idx + 1) so a zero hint means "not set".
		inst.form_id = DECODE_FORM_IDX[entry_idx] + 1

		// Cond: A32 entries with bits[31:28] variable in mask take cond from word
		if mode == .A32 && (e.mask >> 28) == 0 {
			inst.cond = u8((word >> 28) & 0xF)
		} else {
			inst.cond = 14    // AL / unconditional
		}
		if e.flags.sets_flags {
			inst.flags.sets_flags = true
		}

		for _, k in e.enc {
			if e.enc[k] == .NONE { continue }
			op := unpack_operand(word, e.enc[k], e.ops[k])
			inst.ops[k] = op
			inst.operand_count = u8(k + 1)
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

@(private="file")
unpack_operand :: proc(word: u32, enc: Operand_Encoding, ot: Operand_Type) -> Operand {
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
						   shift_type = st, shift_amt = rs, cond = 14}
		case .GPR_SHIFTED:
			// Imm-shift: amount in bits 11..7, type in 6..5, bit 4 = 0.
			st  := Shift_Type((word >> 5) & 0x3)
			amt := u8((word >> 7) & 0x1F)
			if st == .ROR && amt == 0 { return op_reg_shifted(reg, .RRX, 0) }
			if st == .LSL && amt == 0 { return op_reg(reg) }
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
		return op_reg(Register(REG_GPR | u16(word & 0xF)))
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
		return op_rel_offset(i64(v << 2))
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
		return op_mem(mem_imm(base, disp))
	case .MEM_IMM8_OFFSET:
		base := Register(REG_GPR | u16((word >> 16) & 0xF))
		u_bit := (word >> 23) & 1
		disp := i32(((word >> 8) & 0xF) << 4 | (word & 0xF))
		if u_bit == 0 { disp = -disp }
		return op_mem(mem_imm(base, disp))
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
	case .IT_MASK:      return op_imm(i64(word & 0xFF))
	case .CPS_IFLAGS:   return op_imm(i64(word & 0x1FF))
	case .PSR_FIELD_MASK: return op_imm(i64(decode_psr_field(word)))
	case .SYSM_FIELD:   return op_imm(i64(word & 0xFF))
	case .COPROC_NUM_FIELD:  return op_imm(i64((word >> 8) & 0xF))
	case .COPROC_OPC1_FIELD: return op_imm(i64((word >> 20) & 0xF))
	case .COPROC_OPC2_FIELD: return op_imm(i64((word >> 5) & 0x7))
	case .COPROC_CRN_FIELD:  return op_reg(Register(REG_COPROC | u16((word >> 16) & 0xF)))
	case .COPROC_CRM_FIELD:  return op_reg(Register(REG_COPROC | u16(word & 0xF)))
	case .COPROC_OPC_MCRR:   return op_imm(i64((word >> 4) & 0xF))
	case .NEON_CMODE:        return op_imm(i64((word >> 8) & 0xF))
	case .NEON_OP_BIT:       return op_imm(i64((word >> 5) & 1))
	case .NEON_IMM8_ABCDEFGH:
		// Reconstruct abcdefgh from scattered wire bits, then apply cmode/op
		// expansion via decode_neon_modimm.
		a := extract_neon_modimm_abcdefgh(word)
		cmode := (word >> 8) & 0xF
		op := (word >> 5) & 1
		return op_imm(i64(decode_neon_modimm(a, cmode, op)))
	case .VFP_IMM8:
		a := ((word >> 16) & 0xF) << 4 | (word & 0xF)
		return op_imm(i64(decode_vfp_imm8_f32(a)))
	case .VFP_S_LIST, .VFP_D_LIST:
		// Register count is encoded in bits 7..0 (count, not bitmask). Wrap
		// as a REG_LIST so the encoder's shape_match for SPR_LIST/DPR_LIST
		// accepts it; the encoder packs the same 8-bit count back out.
		return op_reg_list(u16(word & 0xFF))

	// ---- Branch fields (decoded into RELATIVE) ----
	case .BRANCH_24:
		v := i32(word & 0xFFFFFF)
		if v & 0x800000 != 0 { v |= -0x1000000 }
		return op_rel_offset(i64(v << 2))
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
		return op_rel_offset(i64(i32(v) << 1))
	case .BRANCH_20_T32:
		// T32 21-bit signed for B<cond>
		s     := (word >> 26) & 1
		j1    := (word >> 13) & 1
		j2    := (word >> 11) & 1
		imm6  := (word >> 16) & 0x3F
		imm11 :=  word        & 0x7FF
		v := (s << 19) | (j1 << 18) | (j2 << 17) | (imm6 << 11) | imm11
		if v & (1 << 19) != 0 { v |= ~u32(0xFFFFF) }
		return op_rel_offset(i64(i32(v) << 1))
	case .BRANCH_11_T16:
		v := word & 0x7FF
		if v & 0x400 != 0 { v |= ~u32(0x7FF) }
		return op_rel_offset(i64(i32(v) << 1))
	case .BRANCH_8_T16:
		v := word & 0xFF
		if v & 0x80 != 0 { v |= ~u32(0xFF) }
		return op_rel_offset(i64(i32(v) << 1))
	case .BRANCH_CBZ:
		i_bit := (word >> 9) & 1
		imm5  := (word >> 3) & 0x1F
		v := (i_bit << 6) | (imm5 << 1)
		return op_rel_offset(i64(v))
	// ---- ARMv8.1-M Branch Future ----
	case .BF_BOFF:
		imm4 := (word >> 23) & 0xF          // hw0[10:7]
		return op_rel_offset(i64(imm4) << 1)
	case .BF_BLOC:
		j     := (word >> 11) & 1           // hw1[11]
		imm10 := (word >> 1)  & 0x3FF       // hw1[10:1]
		val   := (imm10 << 1) | j
		return op_rel_offset(i64(val) << 1)
	case .BF_BELSE:
		imm   := (word >> 23) & 0xF
		return op_rel_offset(i64(imm) << 1)
	case .BF_RM:
		return op_reg(Register(REG_GPR | u16((word >> 16) & 0xF)))
	case .BFCSEL_COND:
		return op_imm(i64((word >> 18) & 0xF))

	// ---- Saturate / bit field ----
	case .SAT_IMM5, .SAT_IMM5_T32, .BFI_MSB:
		return op_imm(i64((word >> 16) & 0x1F))
	case .BFI_LSB, .BFI_LSB_T32:
		return op_imm(i64((word >> 7) & 0x1F))
	case .NEON_SHIFT_IMM6:
		return op_imm(i64((word >> 16) & 0x3F))
	case .NEON_SHIFT_IMM3:
		return op_imm(i64((word >> 16) & 0x7))

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
	case .QM_MVE:
		n := (word >> 1) & 0x7
		return op_reg(Register(REG_QPR | u16(n)))
	case .MVE_SIZE_FIELD:      return op_imm(i64((word >> 20) & 0x3))
	case .MVE_VPT_MASK_FIELD:  return op_imm(i64((word >> 13) & 0xF))
	case .MVE_LOOP_IMM:
		// ARMv8.1-M loop-branch imm11 sign-extended
		v := (word >> 1) & 0x7FF
		if v & 0x400 != 0 { v |= ~u32(0x7FF) }
		return op_rel_offset(i64(i32(v) << 1))

	case .CDE_COPROC_FIELD:    return op_imm(i64((word >> 8) & 0x7))
	case .CDE_IMM_FIELD:       return op_imm(i64(word & 0x7F))
	case .CDE_ACC_FIELD:       return op_imm(i64((word >> 16) & 1))
	case .V8M_TT_AT_BITS:      return op_imm(i64((word >> 6) & 0x3))

	// ---- Memory addressing flavours ----
	// PRE_INDEX and POST_INDEX wrap MEM_IMM12_OFFSET: same field layout but the
	// addressing mode flag is set differently. We reconstruct the full Memory
	// operand here (base, disp, sign, mode).
	case .MEM_PRE_INDEX:
		base := Register(REG_GPR | u16((word >> 16) & 0xF))
		u_bit := (word >> 23) & 1
		disp := i32(word & 0xFFF)
		if u_bit == 0 { disp = -disp }
		return op_mem(mem_imm_pre(base, disp))
	case .MEM_POST_INDEX:
		base := Register(REG_GPR | u16((word >> 16) & 0xF))
		u_bit := (word >> 23) & 1
		disp := i32(word & 0xFFF)
		if u_bit == 0 { disp = -disp }
		return op_mem(mem_imm_post(base, disp))
	case .MEM_LITERAL:
		// PC-relative literal load: U bit + 12-bit signed disp
		u_bit := (word >> 23) & 1
		disp := i32(word & 0xFFF)
		if u_bit == 0 { disp = -disp }
		return op_rel_offset(i64(disp))

	case:
		return op_imm(0)
	}
}
