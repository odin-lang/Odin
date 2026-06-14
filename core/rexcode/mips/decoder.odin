package rexcode_mips

import "../isa"

// =============================================================================
// MIPS DECODER
// =============================================================================
//
// Fixed-width 4-byte decoding pipeline. Two passes (parallel to x86):
//
//   PASS 1 - read each instruction word in the given endianness, dispatch
//            via the generated tables (DECODE_INDEX_PRIMARY plus the five
//            sub-tables in decoding_tables.odin), and emit one Instruction
//            + one Instruction_Info. Branch/jump operands are emitted as
//            RELATIVE-kind operands carrying the *absolute* target byte
//            offset within the decoded region.
//
//   PASS 2 - call isa.infer_labels_from_branches to materialise label
//            definitions at every in-range branch target, reusing IDs from
//            `relocs` when available so symbolic names survive the round
//            trip with the encoder.
//
// Performance: the table dispatch is O(1) primary lookup -> O(1) sub-bucket
// (where applicable) -> linear scan within a bucket that holds at most ~3
// entries for normal opcodes and ~37 for COP1 single-precision (the
// densest cell). Each candidate check is `(word & mask) == bits`, two
// dependent ALU ops; modern cores retire the comparison in <2 cycles.
//
// Style mirrors `encoder.odin`: hot inner procs are `#force_inline`, the
// per-instruction body collapses to one straight-line block.

// -----------------------------------------------------------------------------
// Per-decoded-instruction metadata (parallel to []Instruction).
// -----------------------------------------------------------------------------
//
// `offset`        -- byte offset within `data` where this instruction starts.
// `decode_entry`  -- index into DECODE_ENTRIES of the matched form; lets a
//                    printer query the Feature tag / flags without re-scanning.
Instruction_Info :: struct {
	offset:       u32,
	decode_entry: u16,
	_:            u16,
}
#assert(size_of(Instruction_Info) == 8)

// =============================================================================
// decode()
// =============================================================================

decode :: proc(
	data:         []u8,
	relocs:       []Relocation,
	instructions: ^[dynamic]Instruction,
	inst_info:    ^[dynamic]Instruction_Info,
	label_defs:   ^[dynamic]Label_Definition,
	errors:       ^[dynamic]Error,
	endianness:   Endianness = .BIG,
) -> Result {
	n_bytes := u32(len(data))
	if n_bytes & 3 != 0 {
		n_bytes &= ~u32(3)   // ignore the dangling tail
	}
	errors_start := u32(len(errors))

	pending_branches: [dynamic]isa.Branch_Target
	defer delete(pending_branches)

	// ---- PASS 1 -----------------------------------------------------------
	pc: u32 = 0
	for pc < n_bytes {
		word := read_u32(data, pc, endianness)

		inst: Instruction
		info: Instruction_Info
		entry_idx := decode_one_inline(word, pc, &inst, &info)

		if entry_idx < 0 {
			append(errors, Error{inst_idx = pc, code = .INVALID_OPCODE})
			inst = Instruction{mnemonic = .INVALID, length = 4}
			info = Instruction_Info{offset = pc}
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
		pc += 4
	}

	// ---- PASS 2: label inference -----------------------------------------
	isa.infer_labels_from_branches(pending_branches[:], pc, label_defs, relocs)

	return Result{byte_count = pc, success = u32(len(errors)) == errors_start}
}

// =============================================================================
// Internal: decode one 32-bit word into Instruction + Instruction_Info
// =============================================================================
//
// Returns the matched DECODE_ENTRIES index on success, or -1 if no encoding
// form matches (caller emits INVALID_OPCODE).

@(private="file")
decode_one_inline :: #force_inline proc "contextless" (
	word: u32, pc: u32, inst: ^Instruction, info: ^Instruction_Info,
) -> int {
	primary := (word >> 26) & 0x3F

	range: Decode_Index
	switch primary {
	case 0x00: range = DECODE_INDEX_SPECIAL [word & 0x3F]
	case 0x01: range = DECODE_INDEX_REGIMM  [(word >> 16) & 0x1F]
	case 0x11: range = DECODE_INDEX_COP1    [(word >> 21) & 0x1F]
	case 0x1C: range = DECODE_INDEX_SPECIAL2[word & 0x3F]
	case 0x1F: range = DECODE_INDEX_SPECIAL3[word & 0x3F]
	case:      range = DECODE_INDEX_PRIMARY [primary]
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

// -----------------------------------------------------------------------------
// Operand extractor -- inverse of pack_operand_inline in encoder.odin.
// -----------------------------------------------------------------------------

@(private="file")
extract_operand_inline :: #force_inline proc "contextless" (
	word: u32, pc: u32, ot: Operand_Type, en: Operand_Encoding,
) -> Operand {
	switch en {
	case .NONE:
		return {}

	// Integer / typed register slots ----------------------------------------
	case .RS:
		return reg_operand(decode_reg(word, 21, ot), ot)
	case .RT:
		return reg_operand(decode_reg(word, 16, ot), ot)
	case .RD:
		return reg_operand(decode_reg(word, 11, ot), ot)
	case .SHAMT:
		return Operand{immediate = i64((word >> 6) & 0x1F), kind = .IMMEDIATE, size = 1}

	// FPU register slots ----------------------------------------------------
	case .FT:
		return reg_operand(decode_reg(word, 16, ot), ot)
	case .FS:
		return reg_operand(decode_reg(word, 11, ot), ot)
	case .FD:
		return reg_operand(decode_reg(word, 6, ot), ot)

	// Immediates ------------------------------------------------------------
	case .IMM_16:
		imm: i64
		if ot == .IMM16S {
			imm = i64(i16(word & 0xFFFF))   // sign-extend
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
			// J-type: target_addr = ((PC+4) & 0xF0000000) | (field << 2).
			// The high 4 bits come from PC; we don't have base_address
			// at decode time, so the target reflects the data buffer's
			// own region (top 4 bits derived from `pc`).
			field  := word & 0x3FFFFFF
			target := ((pc + 4) & 0xF0000000) | (field << 2)
			return Operand{relative = i64(target), kind = .RELATIVE, size = 4}
		}
		return Operand{immediate = i64(word & 0x3FFFFFF), kind = .IMMEDIATE, size = 4}

	// Memory: rs(base) + signed imm16(disp) --------------------------------
	case .OFFSET_BASE:
		base_hw := u16((word >> 21) & 0x1F)
		disp    := i32(i16(word & 0xFFFF))   // sign-extend
		m       := Memory{base = Register(REG_GPR | base_hw), disp = disp}
		size: u8 = 4
		return Operand{mem = m, kind = .MEMORY, size = size}

	// PC-relative branches --------------------------------------------------
	case .BRANCH_16:
		rel    := i32(i16(word & 0xFFFF)) << 2
		target := u32(i32(pc) + 4 + rel)
		return Operand{relative = i64(target), kind = .RELATIVE, size = 4}
	case .BRANCH_21:
		rel21 := i32(word & 0x1FFFFF)
		if rel21 & (1 << 20) != 0 { rel21 |= ~i32(0x1FFFFF) }
		target := u32(i32(pc) + 4 + (rel21 << 2))
		return Operand{relative = i64(target), kind = .RELATIVE, size = 4}
	case .BRANCH_26:
		rel26 := i32(word & 0x3FFFFFF)
		if rel26 & (1 << 25) != 0 { rel26 |= ~i32(0x3FFFFFF) }
		target := u32(i32(pc) + 4 + (rel26 << 2))
		return Operand{relative = i64(target), kind = .RELATIVE, size = 4}

	// Misc small immediates -------------------------------------------------
	case .FCC_BC:
		return Operand{immediate = i64((word >> 18) & 0x7), kind = .IMMEDIATE, size = 1}
	case .FCC_CC:
		return Operand{immediate = i64((word >> 8) & 0x7), kind = .IMMEDIATE, size = 1}
	case .SEL:
		return Operand{immediate = i64(word & 0x7), kind = .IMMEDIATE, size = 1}

	case .IMPL:
		return {}   // implicit operand -- bits already in static pattern

	// GTE cofun sub-fields --------------------------------------------------
	case .GTE_SF_BIT:
		return Operand{immediate = i64((word >> 19) & 0x1), kind = .IMMEDIATE, size = 1}
	case .GTE_MX_BITS:
		return Operand{immediate = i64((word >> 17) & 0x3), kind = .IMMEDIATE, size = 1}
	case .GTE_V_BITS:
		return Operand{immediate = i64((word >> 15) & 0x3), kind = .IMMEDIATE, size = 1}
	case .GTE_CV_BITS:
		return Operand{immediate = i64((word >> 13) & 0x3), kind = .IMMEDIATE, size = 1}
	case .GTE_LM_BIT:
		return Operand{immediate = i64((word >> 10) & 0x1), kind = .IMMEDIATE, size = 1}

	case .VFPU_VD:
		return Operand{reg = Register(REG_VFPU | u16(word & 0x7F)),         kind = .REGISTER, size = 4}
	case .VFPU_VS:
		return Operand{reg = Register(REG_VFPU | u16((word >> 8) & 0x7F)),  kind = .REGISTER, size = 4}
	case .VFPU_VT:
		return Operand{reg = Register(REG_VFPU | u16((word >> 16) & 0x7F)), kind = .REGISTER, size = 4}
	case .VFPU_VT_MEM:
		hw := ((word >> 16) & 0x1F) << 2 | (word & 0x3)
		return Operand{reg = Register(REG_VFPU | u16(hw)), kind = .REGISTER, size = 4}
	case .VFPU_OFFSET_BASE:
		base := Register(REG_GPR | u16((word >> 21) & 0x1F))
		disp := i32(word & 0xFFFC)
		if disp & 0x8000 != 0 { disp |= ~i32(0xFFFF) }   // sign-extend from bit 15
		return Operand{mem = Memory{base = base, disp = disp}, kind = .MEMORY, size = 4}
	case .VFPU_PFX:
		return Operand{immediate = i64(word & 0xFFFFF), kind = .IMMEDIATE, size = 4}
	case .VFPU_CONST:
		return Operand{immediate = i64((word >> 16) & 0x1F), kind = .IMMEDIATE, size = 1}
	case .VFPU_COND4:
		return Operand{immediate = i64(word & 0xF), kind = .IMMEDIATE, size = 1}
	case .VFPU_CC3:
		return Operand{immediate = i64((word >> 18) & 0x7), kind = .IMMEDIATE, size = 1}

	// MSA 3R-format register slots.
	case .WD:
		return Operand{reg = Register(REG_MSA | u16((word >> 6) & 0x1F)), kind = .REGISTER, size = 4}
	case .WS:
		return Operand{reg = Register(REG_MSA | u16((word >> 11) & 0x1F)), kind = .REGISTER, size = 4}
	case .WT:
		return Operand{reg = Register(REG_MSA | u16((word >> 16) & 0x1F)), kind = .REGISTER, size = 4}

	// MSA immediates / displacements.
	case .MSA_I5:
		return Operand{immediate = i64((word >> 16) & 0x1F), kind = .IMMEDIATE, size = 1}
	case .MSA_S10:
		v := i32((word >> 16) & 0x3FF)
		if v & 0x200 != 0 { v |= ~i32(0x3FF) }
		return Operand{immediate = i64(v), kind = .IMMEDIATE, size = 2}
	case .MSA_BIT5:
		return Operand{immediate = i64((word >> 11) & 0x1F), kind = .IMMEDIATE, size = 1}

	case .MSA_OFFSET_BASE_B, .MSA_OFFSET_BASE_H, .MSA_OFFSET_BASE_W, .MSA_OFFSET_BASE_D:
		shift: u32 = 0
		#partial switch en {
		case .MSA_OFFSET_BASE_H: shift = 1
		case .MSA_OFFSET_BASE_W: shift = 2
		case .MSA_OFFSET_BASE_D: shift = 3
		}
		base_hw := u8((word >> 11) & 0x1F)
		v := i32((word >> 16) & 0x3FF)
		if v & 0x200 != 0 { v |= ~i32(0x3FF) }
		return Operand{
			mem = Memory{
				base = Register(REG_GPR | u16(base_hw)),
				disp = v << shift,
			},
			kind = .MEMORY, size = 4,
		}
	}
	return {}
}

@(private="file")
decode_reg :: #force_inline proc "contextless" (word: u32, shift: u8, ot: Operand_Type) -> Register {
	hw: u16 = u16((word >> shift) & 0x1F)
	class: u16 = REG_GPR
	#partial switch ot {
	case .FPR_S, .FPR_D, .FPR_W, .FPR_L, .FPR_PS:
		class = REG_FPR
	case .FCR:
		class = REG_FCR
	case .CP0_REG:
		class = REG_CP0
	case .CP2_REG:
		class = REG_CP2D
	case .CP2_CTRL:
		class = REG_CP2C
	case .VFPU_S, .VFPU_P, .VFPU_T, .VFPU_Q, .VFPU_M_P, .VFPU_M_T, .VFPU_M_Q:
		class = REG_VFPU
	}
	return Register(class | hw)
}

@(private="file")
reg_operand :: #force_inline proc "contextless" (r: Register, ot: Operand_Type) -> Operand {
	size: u8 = 4
	if ot == .FPR_D || ot == .FPR_L || ot == .FPR_PS {
		size = 8
	}
	return Operand{reg = r, kind = .REGISTER, size = size}
}
