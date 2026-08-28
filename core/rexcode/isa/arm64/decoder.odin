// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm64

import "core:rexcode/isa"

// =============================================================================
// AArch64 DECODER
// =============================================================================
//
// Two passes, mirroring riscv/decoder.odin. Specifics:
//
//   * Single-level dispatch by op0 (bits[28:25], 4 bits = 16 slots);
//     linear scan within each bucket. Entries are sorted by mask-
//     popcount descending so the most-specific encoding form wins.
//
//   * SP-vs-ZR reconstruction is contextual: the decoder reads hw 0-31
//     and emits an X / W register; if the form expects WSP_REG/XSP_REG
//     it emits a REG_WSP/REG_XSP at hw 31 instead of ZR.
//
//   * .RM extraction is form-dependent: SHIFTED_REG and EXTENDED_REG
//     operand types pull both the register hw and the shift/extend bits.

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
	endianness:   Endianness = .LITTLE,
) -> (byte_count: u32, ok: bool) {
	n_bytes := u32(len(data)) & ~u32(3)
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
	op0 := (word >> 25) & 0xF
	range := DECODE_INDEX_OP0[op0]
	if range.count == 0 { return -1 }

	base := int(range.start)
	cnt  := int(range.count)
	matched_idx := -1
	for i in 0..<cnt {
		e := &DECODE_ENTRIES[base + i]
		if (word & e.mask) == e.bits {
			// RN_RM is one operand filling both source slots, which is what
			// makes cinc/cinv/cneg an alias at all -- the encoding is only
			// theirs when the two register fields actually agree. No mask can
			// say that, so it is checked here; the branch costs nothing,
			// since it is only reached on a match.
			if e.enc[1] == .RN_RM && ((word >> 16) & 0x1F) != ((word >> 5) & 0x1F) {
				continue
			}
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
	#partial switch en {
	case .NONE, .IMPL:
		// For IMPL on .COND_HI/etc. cases the operand stays NONE.
		return {}

	// ---- Register slots ----------------------------------------------------
	case .RD, .RT:
		return reg_from_field(word, 0, ot)
	case .RN, .RN_RM:
		return reg_from_field(word, 5, ot)
	case .RT2, .RA:
		return reg_from_field(word, 10, ot)
	case .RM:
		// Three flavours per operand type: plain / shifted / extended.
		#partial switch ot {
		case .W_SHIFTED, .X_SHIFTED:
			hw := u8((word >> 16) & 0x1F)
			return Operand{
				shifted = Shifted_Reg{
					reg    = ot == .X_SHIFTED ? Register(REG_X | u16(hw)) : Register(REG_W | u16(hw)),
					type   = Shift_Type((word >> 22) & 0x3),
					amount = u8((word >> 10) & 0x3F),
				},
				kind = .SHIFTED_REG, size = 4,
			}
		case .W_EXTENDED, .X_EXTENDED:
			hw := u8((word >> 16) & 0x1F)
			return Operand{
				extended = Extended_Reg{
					reg    = ot == .X_EXTENDED ? Register(REG_X | u16(hw)) : Register(REG_W | u16(hw)),
					extend = Extend((word >> 13) & 0x7),
					amount = u8((word >> 10) & 0x7),
				},
				kind = .EXTENDED_REG, size = 4,
			}
		case:
			return reg_from_field(word, 16, ot)
		}

	// ---- Immediates --------------------------------------------------------
	case .IMM12:    return Operand{immediate = i64((word >> 10) & 0xFFF),   kind = .IMMEDIATE, size = 2}
	case .IMM16:    return Operand{immediate = i64((word >>  5) & 0xFFFF),  kind = .IMMEDIATE, size = 2}
	case .IMM6:     return Operand{immediate = i64((word >> 10) & 0x3F),    kind = .IMMEDIATE, size = 1}
	case .IMM9:
		v := i32((word >> 12) & 0x1FF)
		if v & (1 << 8) != 0 { v |= ~i32(0x1FF) }   // sign-extend from bit 8
		return Operand{immediate = i64(v), kind = .IMMEDIATE, size = 1}
	case .IMM_HW:   return Operand{immediate = i64((word >> 21) & 0x3),     kind = .IMMEDIATE, size = 1}
	case .IMM_SH12: return Operand{immediate = i64((word >> 22) & 0x1),     kind = .IMMEDIATE, size = 1}
	case .SHIFT_TYPE: return Operand{immediate = i64((word >> 22) & 0x3),   kind = .IMMEDIATE, size = 1}
	case .EXT_OPT:  return Operand{immediate = i64((word >> 13) & 0x7),     kind = .IMMEDIATE, size = 1}
	case .EXT_IMM3: return Operand{immediate = i64((word >> 10) & 0x7),     kind = .IMMEDIATE, size = 1}
	case .COND_HI:
		return Operand{cond = u8((word >> 12) & 0xF), kind = .COND, size = 1}
	case .COND_HI_INV:
		return Operand{cond = u8(((word >> 12) & 0xF) ~ 1), kind = .COND, size = 1}
	case .COND_LO:
		return Operand{cond = u8(word & 0xF), kind = .COND, size = 1}
	case .NZCV_FIELD:
		return Operand{immediate = i64(word & 0xF), kind = .IMMEDIATE, size = 1}
	case .SYS_FIELD:
		return Operand{sysreg = System_Register((word >> 5) & 0x7FFF), kind = .SYSTEM_REGISTER, size = 2}
	case .HINT_FIELD:
		return Operand{immediate = i64((word >> 5) & 0x7F), kind = .IMMEDIATE, size = 1}
	case .BARRIER_FIELD:
		return Operand{immediate = i64((word >> 8) & 0xF), kind = .IMMEDIATE, size = 1}

	// ---- NEON shift-by-immediate: recover the amount from immh:immb ---------
	case .NEON_SHL_IMM, .NEON_SHR_IMM:
		immh := (word >> 19) & 0xF
		esize: i64 = 8
		if      immh >= 8 { esize = 64 }
		else if immh >= 4 { esize = 32 }
		else if immh >= 2 { esize = 16 }
		val := i64((word >> 16) & 0x7F)
		amt := val - esize
		if en == .NEON_SHR_IMM { amt = 2 * esize - val }
		return Operand{immediate = amt, kind = .IMMEDIATE, size = 1}

	// ---- NEON copy/permute index fields ------------------------------------
	case .VN_VM_DUP:
		return Operand{reg = Register(REG_V | u16((word >> 5) & 0x1F)), kind = .REGISTER, size = reg_size_for_type(ot)}
	case .NEON_IDX5:
		// imm5 = index << (markerbit+1) | (1 << markerbit); marker = lowest set bit.
		imm5 := (word >> 16) & 0x1F
		mb: u32 = 0
		if      imm5 & 0x1 != 0 { mb = 0 }
		else if imm5 & 0x2 != 0 { mb = 1 }
		else if imm5 & 0x4 != 0 { mb = 2 }
		else                    { mb = 3 }
		return Operand{immediate = i64(imm5 >> (mb + 1)), kind = .IMMEDIATE, size = LANE_INDEX}
	case .NEON_IDX4:
		// imm4 = index << markerbit; recover markerbit from imm5 in the word.
		imm5 := (word >> 16) & 0x1F
		mb: u32 = 0
		if      imm5 & 0x1 != 0 { mb = 0 }
		else if imm5 & 0x2 != 0 { mb = 1 }
		else if imm5 & 0x4 != 0 { mb = 2 }
		else                    { mb = 3 }
		return Operand{immediate = i64(((word >> 11) & 0xF) >> mb), kind = .IMMEDIATE, size = LANE_INDEX}
	case .NEON_EXT_IDX:
		return Operand{immediate = i64((word >> 11) & 0xF), kind = .IMMEDIATE, size = 1}
	case .IMM5_HI:
		return Operand{immediate = i64((word >> 16) & 0x1F), kind = .IMMEDIATE, size = 1}
	case .MSR_PSTATE:
		v := ((word >> 16) & 0x7) << 3 | ((word >> 5) & 0x7)
		return Operand{immediate = i64(v), kind = .IMMEDIATE, size = 1}
	case .FMOV_SCALAR_IMM:
		return Operand{immediate = i64((word >> 13) & 0xFF), kind = .IMMEDIATE, size = 1}
	case .PG4_PM_DUP:
		return Operand{reg = Register(REG_P | u16((word >> 10) & 0xF)), kind = .REGISTER, size = 4}
	case .PN_PM_DUP, .PN_PG_PM_DUP:
		return Operand{reg = Register(REG_P | u16((word >> 5) & 0xF)), kind = .REGISTER, size = 4}
	case .ZD_ZM_DUP:
		return Operand{reg = Register(REG_Z | u16(word & 0x1F)), kind = .REGISTER, size = reg_size_for_type(ot)}
	case .SVE_EXT_IMM:
		v := ((word >> 16) & 0x1F) << 3 | ((word >> 10) & 0x7)
		return Operand{immediate = i64(v), kind = .IMMEDIATE, size = 1}
	case .ZA_TILE_LOW:
		return Operand{reg = Register(REG_ZA | u16(word & 0x7)), kind = .REGISTER,
		               size = za_elem_for_type(ot)}
	case .NEON_LANE_B:
		i := ((word >> 30) & 0x1) << 3 | ((word >> 12) & 0x1) << 2 | ((word >> 10) & 0x3)
		return Operand{immediate = i64(i), kind = .IMMEDIATE, size = LANE_INDEX}
	case .NEON_LANE_H:
		i := ((word >> 30) & 0x1) << 2 | ((word >> 12) & 0x1) << 1 | ((word >> 11) & 0x1)
		return Operand{immediate = i64(i), kind = .IMMEDIATE, size = LANE_INDEX}
	case .NEON_LANE_S:
		i := ((word >> 30) & 0x1) << 1 | ((word >> 12) & 0x1)
		return Operand{immediate = i64(i), kind = .IMMEDIATE, size = LANE_INDEX}
	case .NEON_LANE_D:
		return Operand{immediate = i64((word >> 30) & 0x1), kind = .IMMEDIATE, size = LANE_INDEX}
	case .SVE_XAR_SHIFT:
		return Operand{immediate = i64(sve_tsz_shift(sve_tsz_field(word))), kind = .IMMEDIATE, size = 1}

	// ---- Memory operand variants ------------------------------------------
	case .OFFSET_BASE_U12:
		size := u32(1) << ((word >> 30) & 0x3)
		base_hw := u8((word >> 5) & 0x1F)
		imm12   := u32((word >> 10) & 0xFFF)
		return Operand{
			mem = Memory{
				base = Register(REG_X | u16(base_hw)),
				index = NONE,
				disp = i32(imm12 * size),
				mode = .OFFSET,
			},
			kind = .MEMORY, size = 4,
		}
	case .OFFSET_BASE_S9:
		base_hw := u8((word >> 5) & 0x1F)
		imm9    := i32((word >> 12) & 0x1FF)
		if imm9 & (1 << 8) != 0 { imm9 |= ~i32(0x1FF) }
		return Operand{
			mem = Memory{
				base = Register(REG_X | u16(base_hw)),
				index = NONE,
				disp = imm9,
				mode = .OFFSET,
			},
			kind = .MEMORY, size = 4,
		}
	case .OFFSET_BASE_PRE:
		base_hw := u8((word >> 5) & 0x1F)
		imm9    := i32((word >> 12) & 0x1FF)
		if imm9 & (1 << 8) != 0 { imm9 |= ~i32(0x1FF) }
		return Operand{
			mem = Memory{
				base = Register(REG_X | u16(base_hw)),
				index = NONE,
				disp = imm9,
				mode = .PRE_INDEXED,
			},
			kind = .MEMORY, size = 4,
		}
	case .OFFSET_BASE_POST:
		base_hw := u8((word >> 5) & 0x1F)
		imm9    := i32((word >> 12) & 0x1FF)
		if imm9 & (1 << 8) != 0 { imm9 |= ~i32(0x1FF) }
		return Operand{
			mem = Memory{
				base = Register(REG_X | u16(base_hw)),
				index = NONE,
				disp = imm9,
				mode = .POST_INDEXED,
			},
			kind = .MEMORY, size = 4,
		}
	case .OFFSET_BASE_A:
		// [Xn] only: no displacement, no index.
		base_hw := u8((word >> 5) & 0x1F)
		return Operand{
			mem = Memory{
				base = Register(REG_X | u16(base_hw)),
				index = NONE,
				mode = .OFFSET,
			},
			kind = .MEMORY, size = 4,
		}
	case .OFFSET_PAIR_4, .OFFSET_PAIR_8, .OFFSET_PAIR_16:
		// LDP/STP: signed imm7 at 21:15, scaled by the transfer size. The
		// addressing mode is bits[24:23] of the word (01 post, 11 pre,
		// 10 signed offset / 00 no-allocate), not part of the encoding.
		base_hw := u8((word >> 5) & 0x1F)
		imm7    := i32((word >> 15) & 0x7F)
		if imm7 & (1 << 6) != 0 {
			imm7 |= ~i32(0x7F)
		}
		scale := i32(4)
		if en == .OFFSET_PAIR_8 {
			scale = 8
		} else if en == .OFFSET_PAIR_16 {
			scale = 16
		}
		mode := Address_Mode.OFFSET
		switch (word >> 23) & 0x3 {
		case 0b01: mode = .POST_INDEXED
		case 0b11: mode = .PRE_INDEXED
		}
		return Operand{
			mem = Memory{
				base = Register(REG_X | u16(base_hw)),
				index = NONE,
				disp = imm7 * scale,
				mode = mode,
			},
			kind = .MEMORY, size = 4,
		}
	case .OFFSET_REG, .OFFSET_EXT:
		base_hw := u8((word >> 5) & 0x1F)
		idx_hw  := u8((word >> 16) & 0x1F)
		option  := Extend((word >> 13) & 0x7)
		s       := u8((word >> 12) & 0x1)
		idx_cls := u16(REG_X)
		if option == .UXTW || option == .SXTW { idx_cls = REG_W }
		return Operand{
			mem = Memory{
				base   = Register(REG_X | u16(base_hw)),
				index  = Register(idx_cls | u16(idx_hw)),
				extend = option,
				shift  = s,
				mode   = en == .OFFSET_EXT ? .EXT_REG_OFFSET : .REG_OFFSET,
			},
			kind = .MEMORY, size = 4,
		}

	// ---- PC-relative branches ---------------------------------------------
	case .BRANCH_26:
		v := i32(word & 0x03FFFFFF)
		if v & (1 << 25) != 0 { v |= ~i32(0x03FFFFFF) }
		target := u32(i32(pc) + (v << 2))
		return Operand{relative = i64(target), kind = .RELATIVE, size = 4}
	case .BRANCH_19:
		v := i32((word >> 5) & 0x7FFFF)
		if v & (1 << 18) != 0 { v |= ~i32(0x7FFFF) }
		target := u32(i32(pc) + (v << 2))
		return Operand{relative = i64(target), kind = .RELATIVE, size = 4}
	case .BRANCH_14:
		v := i32((word >> 5) & 0x3FFF)
		if v & (1 << 13) != 0 { v |= ~i32(0x3FFF) }
		target := u32(i32(pc) + (v << 2))
		return Operand{relative = i64(target), kind = .RELATIVE, size = 4}
	case .BRANCH_PG21:
		// Sign-extended 21-bit value reassembled from immlo/immhi.
		lo := (word >> 29) & 0x3
		hi := (word >>  5) & 0x7FFFF
		v  := i32((hi << 2) | lo)
		if v & (1 << 20) != 0 { v |= ~i32(0x1FFFFF) }
		// For ADR (op=0 bit 31) target = PC + imm21.
		// For ADRP (op=1) target = (PC & ~0xFFF) + (imm21 << 12).
		if (word >> 31) & 1 != 0 {
			// ADRP
			target := (i64(pc) & ~i64(0xFFF)) + (i64(v) << 12)
			return Operand{relative = target, kind = .RELATIVE, size = 4}
		} else {
			target := u32(i32(pc) + v)
			return Operand{relative = i64(target), kind = .RELATIVE, size = 4}
		}

	case .TBZ_BIT:
		// Reassemble bit position: b5 at bit 31, b40 at bits 23-19.
		b5  := (word >> 31) & 0x1
		b40 := (word >> 19) & 0x1F
		return Operand{immediate = i64((b5 << 5) | b40), kind = .IMMEDIATE, size = 1}

	// ---- Bitmask logical immediate (round-trip back to the raw mask) ----
	case .BITMASK_FIELD:
		is_64 := (word >> 31) & 1 != 0
		n_bit := u8((word >> 22) & 1)
		immr  := u8((word >> 16) & 0x3F)
		imms  := u8((word >> 10) & 0x3F)
		value, ok := decode_bitmask_imm(n_bit, immr, imms, is_64)
		if !ok { return {} }
		return Operand{immediate = i64(value), kind = .IMMEDIATE, size = is_64 ? 8 : 4}

	// ---- NEON / SIMD register slots ----
	// The class comes from the operand TYPE, not from the encoding: SVE forms
	// use these same Vd/Vn/Vm slots with Z_REG_* operands, so hardcoding
	// REG_V here decoded `add z0.d, z0.d, z0.d` as a V register.
	case .VD:
		return reg_from_field(word, 0, ot)
	// The element size is not in the static pattern -- it shares the tsz field
	// with the shift -- so it has to be read out of the word.
	case .VD_TSZ:
		return Operand{reg = Register(REG_Z | u16(word & 0x1F)), kind = .REGISTER,
		               size = sve_esize_code(sve_tsz_esize(sve_tsz_field(word)))}
	case .VN_TSZ:
		return Operand{reg = Register(REG_Z | u16((word >> 5) & 0x1F)), kind = .REGISTER,
		               size = sve_esize_code(sve_tsz_esize(sve_tsz_field(word)))}
	case .VN:
		return reg_from_field(word, 5, ot)
	case .VD_LIST1, .VD_LIST2, .VD_LIST3, .VD_LIST4:
		op := reg_from_field(word, 0, ot)
		op.list_count = u8(int(en) - int(Operand_Encoding.VD_LIST1)) + 1
		return op
	case .VN_LIST1, .VN_LIST2, .VN_LIST3, .VN_LIST4:
		op := reg_from_field(word, 5, ot)
		op.list_count = u8(int(en) - int(Operand_Encoding.VN_LIST1)) + 1
		return op
	case .VM:
		return reg_from_field(word, 16, ot)
	case .VA:
		return reg_from_field(word, 10, ot)

	// ---- NEON / SVE indexed/immediate fields ----
	case .NEON_IMM8_FMOV:
		v := ((word >> 16) & 0x7) << 5 | ((word >> 5) & 0x1F)
		return Operand{immediate = i64(v), kind = .IMMEDIATE, size = 1}
	case .NEON_INDEX_H:
		return Operand{immediate = i64((word >> 19) & 0x3), kind = .IMMEDIATE, size = 1}
	case .NEON_INDEX_S:
		v := ((word >> 21) & 0x1) | ((word >> 11) & 0x1) << 1
		return Operand{immediate = i64(v), kind = .IMMEDIATE, size = 1}
	case .NEON_INDEX_D:
		return Operand{immediate = i64((word >> 11) & 0x1), kind = .IMMEDIATE, size = 1}

	// ---- LSE atomic register slots ----
	case .ATOMIC_RS:
		return reg_from_field(word, 16, ot)
	case .ATOMIC_RT:
		return reg_from_field(word, 0, ot)
	case .ATOMIC_RN:
		// Memory operand: only the base register is encoded in the word,
		// displacement is always zero (atomic addressing).
		base_hw := u8((word >> 5) & 0x1F)
		return Operand{
			mem = Memory{
				base = Register(REG_X | u16(base_hw)),
				index = NONE,
				mode = .OFFSET,
			},
			kind = .MEMORY, size = 4,
		}

	// ---- SVE predicate slots ----
	case .PD:
		return Operand{reg = Register(REG_P | u16(word & 0xF)), kind = .REGISTER, size = pqual_for_type(ot)}
	case .PN:
		return Operand{reg = Register(REG_P | u16((word >> 5) & 0xF)), kind = .REGISTER, size = pqual_for_type(ot)}
	case .PM:
		return Operand{reg = Register(REG_P | u16((word >> 16) & 0xF)), kind = .REGISTER, size = pqual_for_type(ot)}
	case .ENC_ZT0:
		return Operand{reg = ZT0, kind = .REGISTER, size = 0}
	case .LUTI_IDX:
		return Operand{immediate = i64((word >> 15) & 0x3), kind = .IMMEDIATE, size = LANE_INDEX}
	case .PNG:
		return Operand{reg = Register(REG_PN | u16(8 + ((word >> 10) & 0x7))), kind = .REGISTER, size = pqual_for_type(ot)}
	case .PG:
		return Operand{reg = Register(REG_P | u16((word >> 10) & 0x7)), kind = .REGISTER, size = pqual_for_type(ot)}
	case .PG4:
		return Operand{reg = Register(REG_P | u16((word >> 10) & 0xF)), kind = .REGISTER, size = pqual_for_type(ot)}
	case .PM3:
		return Operand{reg = Register(REG_P | u16((word >> 13) & 0x7)), kind = .REGISTER, size = pqual_for_type(ot)}

	// ---- SVE immediates ----
	case .SVE_IMM8:
		v := i32((word >> 5) & 0xFF)
		if v & 0x80 != 0 { v |= ~i32(0xFF) }
		return Operand{immediate = i64(v), kind = .IMMEDIATE, size = 1}
	case .SVE_IMM5A:
		v := i64((word >> 5) & 0x1F)
		if v & 0x10 != 0 { v |= ~i64(0x1F) }
		return Operand{immediate = v, kind = .IMMEDIATE, size = 1}
	case .SVE_IMM5:
		return Operand{immediate = i64((word >> 16) & 0x1F), kind = .IMMEDIATE, size = 1}
	case .SVE_SHIFT_TSZ_IMM:
		return Operand{immediate = i64((word >> 16) & 0x7F), kind = .IMMEDIATE, size = 1}
	case .SVE_PATTERN:
		return Operand{immediate = i64((word >> 5) & 0x1F), kind = .IMMEDIATE, size = 1}

	// ---- SVE memory operands ----
	case .SVE_OFFSET_BASE_SS, .SVE_OFFSET_BASE_SS1, .SVE_OFFSET_BASE_SS2, .SVE_OFFSET_BASE_SS3,
	     .SVE_OFFSET_BASE_SS4:
		base_hw := u8((word >> 5) & 0x1F)
		idx_hw  := u8((word >> 16) & 0x1F)
		shift: u8 = 0
		#partial switch en {
		case .SVE_OFFSET_BASE_SS1: shift = 1
		case .SVE_OFFSET_BASE_SS2: shift = 2
		case .SVE_OFFSET_BASE_SS3: shift = 3
		case .SVE_OFFSET_BASE_SS4: shift = 4
		}
		return Operand{
			mem = Memory{
				base = Register(REG_X | u16(base_hw)),
				index = Register(REG_X | u16(idx_hw)),
				shift = shift,
				mode = .REG_OFFSET,
			},
			kind = .MEMORY, size = 4,
		}
	case .SVE_OFFSET_BASE_SI:
		base_hw := u8((word >> 5) & 0x1F)
		imm     := i32((word >> 16) & 0xF)
		if imm & 0x8 != 0 { imm |= ~i32(0xF) }
		return Operand{
			mem = Memory{
				base = Register(REG_X | u16(base_hw)),
				index = NONE,
				disp = imm,
				mode = .OFFSET,
			},
			kind = .MEMORY, size = 4,
		}

	// ---- SME ZA tile fields ----
	case .ZA_TILE_NUM_B:
		return Operand{reg = Register(REG_ZA | 0), kind = .REGISTER,
		               size = za_elem_for_type(ot)}
	case .ZA_TILE_NUM_H:
		return Operand{reg = Register(REG_ZA | u16((word >> 22) & 0x1)), kind = .REGISTER,
		               size = za_elem_for_type(ot)}
	case .ZA_TILE_NUM_S:
		return Operand{reg = Register(REG_ZA | u16((word >> 22) & 0x3)), kind = .REGISTER,
		               size = za_elem_for_type(ot)}
	case .ZA_TILE_NUM_D:
		return Operand{reg = Register(REG_ZA | u16((word >> 21) & 0x7)), kind = .REGISTER,
		               size = za_elem_for_type(ot)}
	case .SME_PATTERN_FIELD:
		return Operand{immediate = i64((word >> 5) & 0xF), kind = .IMMEDIATE, size = 1}

	// ---- SVE gather/scatter + vector-base memory ----
	case .SVE_OFFSET_BASE_VEC, .SVE_OFFSET_BASE_VEC_S, .SVE_OFFSET_BASE_VEC_D,
	     .SVE_OFFSET_BASE_VECST_S, .SVE_OFFSET_BASE_VECST_D:
		base_hw := u8((word >> 5)  & 0x1F)
		idx_hw  := u8((word >> 16) & 0x1F)
		m := Memory{
			base  = Register(REG_X | u16(base_hw)),
			index = Register(REG_Z | u16(idx_hw)),
			mode  = .REG_OFFSET,
		}
		// These forms all extend a 32-bit-wide index, and bit 22 says which way.
		// The index's own element size is not derivable from the word, so it
		// travels in the operand's size -- Memory has no bits left.
		shape := u8(4)
		#partial switch en {
		case .SVE_OFFSET_BASE_VEC_S, .SVE_OFFSET_BASE_VEC_D:
			m.mode   = .EXT_REG_OFFSET
			m.extend = (word >> 22) & 1 != 0 ? .SXTW : .UXTW
			shape    = en == .SVE_OFFSET_BASE_VEC_D ? ZSHAPE_D : ZSHAPE_S
		case .SVE_OFFSET_BASE_VECST_S, .SVE_OFFSET_BASE_VECST_D:
			m.mode   = .EXT_REG_OFFSET
			m.extend = (word >> 14) & 1 != 0 ? .SXTW : .UXTW
			shape    = en == .SVE_OFFSET_BASE_VECST_D ? ZSHAPE_D : ZSHAPE_S
		}
		return Operand{mem = m, kind = .MEMORY, size = shape}
	case .SVE_OFFSET_VEC_BASE:
		base_hw := u8((word >> 5) & 0x1F)
		imm     := i32((word >> 16) & 0x1F)
		return Operand{
			mem = Memory{
				base  = Register(REG_Z | u16(base_hw)),
				disp  = imm,
				mode  = .OFFSET,
			},
			kind = .MEMORY, size = 4,
		}

	// ---- SVE indexed lane field ----
	case .SVE_FMLA_IDX_H:
		v := ((word >> 22) & 0x1) << 2 | ((word >> 19) & 0x3)
		return Operand{immediate = i64(v), kind = .IMMEDIATE, size = LANE_INDEX}
	case .SVE_FMLA_IDX_S:
		v := (word >> 19) & 0x3
		return Operand{immediate = i64(v), kind = .IMMEDIATE, size = LANE_INDEX}
	case .SVE_FMLA_IDX_D:
		v := (word >> 20) & 0x1
		return Operand{immediate = i64(v), kind = .IMMEDIATE, size = LANE_INDEX}

	// ---- SME tile slice descriptor (round-trip back to the packed form) ----
	//
	// Decode is the inverse of the packer: tile_num and imm bits live in
	// instruction bits 3:0 (packed per element size), Ws at bits 14:13,
	// V flag at bit 15.
	case .SME_SLICE_B:
		// The tile number and the offset share the low nibble; how it
		// splits follows the element size.
		return op_za_slice(u8((word >> 4) & 0x0), u8((word >> 13) & 0x3),
		                   u8(word & 0xF), ZSHAPE_B, (word >> 15) & 0x1 != 0)
	case .SME_SLICE_H:
		// The tile number and the offset share the low nibble; how it
		// splits follows the element size.
		return op_za_slice(u8((word >> 3) & 0x1), u8((word >> 13) & 0x3),
		                   u8(word & 0x7), ZSHAPE_H, (word >> 15) & 0x1 != 0)
	case .SME_SLICE_W:
		// The tile number and the offset share the low nibble; how it
		// splits follows the element size.
		return op_za_slice(u8((word >> 2) & 0x3), u8((word >> 13) & 0x3),
		                   u8(word & 0x3), ZSHAPE_S, (word >> 15) & 0x1 != 0)
	case .SME_SLICE_D:
		// The tile number and the offset share the low nibble; how it
		// splits follows the element size.
		return op_za_slice(u8((word >> 1) & 0x7), u8((word >> 13) & 0x3),
		                   u8(word & 0x1), ZSHAPE_D, (word >> 15) & 0x1 != 0)
	case .SME_SLICE_Q:
		// The tile number and the offset share the low nibble; how it
		// splits follows the element size.
		return op_za_slice(u8((word >> 0) & 0xF), u8((word >> 13) & 0x3),
		                   u8(word & 0x0), ZSHAPE_Q, (word >> 15) & 0x1 != 0)
	case .NEON_IDX2:
		return Operand{immediate = i64((word >> 12) & 0x3), kind = .IMMEDIATE, size = LANE_INDEX}
	case .ENC_FCMLA_ROT:
		return Operand{immediate = i64((word >> 12) & 0x3), kind = .IMMEDIATE, size = 1}
	case .ENC_FCADD_ROT:
		return Operand{immediate = i64((word >> 12) & 0x1), kind = .IMMEDIATE, size = 1}
	case .ENC_SVE_PRFOP:
		return Operand{immediate = i64(word & 0xF), kind = .IMMEDIATE, size = 1}
	case .ENC_LDRAA_IMM10:
		v := i32((word >> 12) & 0x3FF)
		if v & 0x200 != 0 { v |= ~i32(0x3FF) }
		return Operand{immediate = i64(v << 3), kind = .IMMEDIATE, size = 2}

	// ---- Batch 5 ----
	case .ENC_LSL_IMM_W:
		// Recover shift from imms: imms = 31 - imm.
		imms := (word >> 10) & 0x1F
		return Operand{immediate = i64((31 - imms) & 0x1F), kind = .IMMEDIATE, size = 1}
	case .ENC_LSL_IMM_X:
		imms := (word >> 10) & 0x3F
		return Operand{immediate = i64((63 - imms) & 0x3F), kind = .IMMEDIATE, size = 1}
	case .ENC_IMM6_LO:
		v := i32((word >> 5) & 0x3F)
		if v & (1 << 5) != 0 { v |= ~i32(0x3F) }   // sign-extend from bit 5
		return Operand{immediate = i64(v), kind = .IMMEDIATE, size = 1}
	case .ENC_SHIFT_IMMR:
		// LSR/ASR immediate: the shift is immr verbatim (bits 21:16).
		return Operand{immediate = i64((word >> 16) & 0x3F), kind = .IMMEDIATE, size = 1}
	case .ENC_DUAL_RN_RM:
		// Take the Rn slot (9:5) as the source register.
		return Operand{reg = Register(REG_X | u16((word >> 5) & 0x1F)), kind = .REGISTER, size = 4}
	case .ENC_ROR_SHIFT:
		return Operand{immediate = i64((word >> 10) & 0x3F), kind = .IMMEDIATE, size = 1}
	case .ENC_Z_PAIR_VD, .ENC_Z_QUAD_VD:
		return Operand{reg = Register(REG_Z | u16(word & 0x1F)), kind = .REGISTER,
		               size = reg_size_for_type(ot), list_count = en == .ENC_Z_PAIR_VD ? 2 : 4}
	case .ENC_Z_PAIR_VN, .ENC_Z_QUAD_VN:
		return Operand{reg = Register(REG_Z | u16((word >> 5) & 0x1F)), kind = .REGISTER,
		               size = reg_size_for_type(ot), list_count = en == .ENC_Z_PAIR_VN ? 2 : 4}
	case .ENC_Z_PAIR_VM, .ENC_Z_QUAD_VM:
		return Operand{reg = Register(REG_Z | u16((word >> 16) & 0x1F)), kind = .REGISTER, size = reg_size_for_type(ot)}
	}
	return {}
}

// reg_from_field reconstructs a Register from a 5-bit hw field at `shift`,
// choosing the right class per the form's Operand_Type. SP/WSP variants
// use the REG_XSP/REG_WSP class at hw=31; everything else uses REG_X/REG_W.
@(private="file")
reg_from_field :: #force_inline proc "contextless" (
	word: u32, shift: u8, ot: Operand_Type,
) -> Operand {
	hw := u16((word >> shift) & 0x1F)
	cls: u16 = REG_X
	#partial switch ot {
	case .W_REG:    cls = REG_W
	case .X_REG:    cls = REG_X
	case .WSP_REG:  cls = hw == 31 ? REG_WSP : REG_W
	case .XSP_REG:  cls = hw == 31 ? REG_XSP : REG_X
	case .B_REG:    cls = REG_B
	case .H_REG:    cls = REG_H
	case .S_REG:    cls = REG_S
	case .D_REG:    cls = REG_D
	case .Q_REG:    cls = REG_Q
	case .V_REG,
		 .V_8B, .V_16B, .V_4H, .V_8H, .V_2S, .V_4S, .V_1D, .V_2D,
		 .V_4H_FP16, .V_8H_FP16, .V_1Q,
		 .V_ELEM_B, .V_ELEM_H, .V_ELEM_S, .V_ELEM_D:
		cls = REG_V
	case .Z_REG_B, .Z_REG_H, .Z_REG_S, .Z_REG_D, .Z_REG_ANY:
		cls = REG_Z
	case .P_REG, .P_REG_MERGE, .P_REG_ZERO, .P_REG_GOV,
	     .P_REG_B, .P_REG_H, .P_REG_S, .P_REG_D:
		cls = REG_P
	case .PN_REG, .PN_REG_ZERO:
		cls = REG_PN
	case .ZT_REG:
		cls = REG_ZT
	case .Z_PAIR_B, .Z_PAIR_H, .Z_PAIR_S, .Z_PAIR_D,
	     .Z_QUAD_B, .Z_QUAD_H, .Z_QUAD_S, .Z_QUAD_D:
		cls = REG_Z
	}
	// SP class needs the special hw=31 marker; everything else uses the
	// raw hw with the chosen class.
	if (ot == .WSP_REG && hw == 31) || (ot == .XSP_REG && hw == 31) {
		return Operand{reg = Register(cls | 31), kind = .REGISTER, size = 4}
	}
	// Vector operands carry their arrangement / element view in `size`, using
	// the same codes op_v_*/op_z_* produce (see operands.odin). Without this a
	// decoded V register would come back as a bare `v0` with no `.4s`, so a
	// disassembly could not be fed back to an assembler.
	return Operand{reg = Register(cls | hw), kind = .REGISTER, size = reg_size_for_type(ot)}
}

// The `size` marker an operand of this type carries: the NEON arrangement
// (multiples of 8), an element view (odd), or an SVE element width. 4 is the
// neutral "no vector shape" value used by every scalar class.
@(private="file", require_results)
reg_size_for_type :: #force_inline proc "contextless" (ot: Operand_Type) -> u8 {
	#partial switch ot {
	case .V_8B:                 return 8
	case .V_16B:                return 16
	case .V_4H, .V_4H_FP16:     return 24
	case .V_8H, .V_8H_FP16:     return 32
	case .V_2S:                 return 40
	case .V_4S:                 return 48
	case .V_1D:                 return 56
	case .V_2D:                 return 64
	case .V_1Q:                 return 72
	case .V_ELEM_B:             return 1
	case .V_ELEM_H:             return 3
	case .V_ELEM_S:             return 5
	case .V_ELEM_D:             return 7
	case .Z_REG_B:              return 1
	case .Z_REG_H:              return 2
	case .Z_REG_S:              return 4
	case .Z_REG_D:              return 8
	case .Z_REG_ANY:            return 0   // no element size in the syntax
	case .P_REG_ZERO, .PN_REG_ZERO: return PQUAL_ZERO
	case .P_REG_MERGE:          return PQUAL_MERGE
	case .P_REG_B:              return PSHAPE_B
	case .P_REG_H:              return PSHAPE_H
	case .P_REG_S:              return PSHAPE_S
	case .P_REG_D:              return PSHAPE_D
	case .Z_PAIR_B, .Z_QUAD_B:  return 1
	case .Z_PAIR_H, .Z_QUAD_H:  return 2
	case .Z_PAIR_S, .Z_QUAD_S:  return 4
	case .Z_PAIR_D, .Z_QUAD_D:  return 8
	}
	return 4
}

// A predicate operand's governing qualifier, which the form -- not the caller
// -- decides: an SVE load zeroes, a predicated add merges.
@(private="file", require_results)
pqual_for_type :: #force_inline proc "contextless" (ot: Operand_Type) -> u8 {
	#partial switch ot {
	case .P_REG_ZERO, .PN_REG_ZERO: return PQUAL_ZERO
	case .P_REG_MERGE: return PQUAL_MERGE
	case .P_REG_B:     return PSHAPE_B
	case .P_REG_H:     return PSHAPE_H
	case .P_REG_S:     return PSHAPE_S
	case .P_REG_D:     return PSHAPE_D
	}
	return PQUAL_NONE
}

// -----------------------------------------------------------------------------
// Buffer-Sizing Helpers (let callers pre-size so the decode hot path never
// reallocates; allocates no new buffers -- only the caller's arrays grow).
// -----------------------------------------------------------------------------

// Exact instruction-count ceiling for `data` (AArch64 instructions are 4 bytes).
@(require_results)
decode_max_instruction_count :: #force_inline proc "contextless" (data: []u8) -> int {
	return len(data) / 4
}

// Typical-case estimate (AArch64 is fixed 4 bytes/instruction, so this is exact).
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

// The packed tszh:tszl:imm3 value an SVE shift-by-immediate carries.
@(private="file", require_results)
sve_tsz_field :: #force_inline proc "contextless" (word: u32) -> u32 {
	return ((word >> 22) & 0x3) << 5 | ((word >> 19) & 0x3) << 3 | ((word >> 16) & 0x7)
}

// The element width a ZA tile operand is viewed at.
@(private="file", require_results)
za_elem_for_type :: #force_inline proc "contextless" (ot: Operand_Type) -> u8 {
	#partial switch ot {
	case .ZA_TILE_H: return ZSHAPE_H
	case .ZA_TILE_S: return ZSHAPE_S
	case .ZA_TILE_D: return ZSHAPE_D
	}
	return ZSHAPE_B
}
