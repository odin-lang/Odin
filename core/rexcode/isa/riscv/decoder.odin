// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_riscv

import "core:rexcode/isa"

// =============================================================================
// RISC-V DECODER
// =============================================================================
//
// Two passes, mirroring mips/decoder.odin. The RISC-V-specific bits:
//
//   * Two-level dispatch: primary opcode (bits 6-0) directly indexes
//     DECODE_INDEX_OPCODE[128]; opcode 0x53 (OP-FP) is sub-bucketed
//     further by funct7 (bits 31-25). Within each bucket, linear scan
//     of `(word & e.mask) == e.bits`.
//
//   * XLEN filter: the decoder takes an XLEN parameter (.RV32 / .RV64);
//     entries flagged `rv32_only` are skipped when decoding RV64, and
//     vice versa.
//
//   * Scattered immediates: B-type and J-type targets are reconstructed
//     via gather_b / gather_j helpers in encoder.odin and emitted as
//     RELATIVE-kind operands carrying the absolute byte target.

XLEN :: enum u8 {
	RV32,
	RV64,
}

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
	xlen:         XLEN = .RV64,
) -> (byte_count: u32, ok: bool) {
	n_bytes := u32(len(data)) & ~u32(1)   // align to halfword (RVC is 2-byte)
	errors_start := u32(len(errors))

	pending_branches: [dynamic]isa.Branch_Target
	defer delete(pending_branches)

	for byte_count < n_bytes {
		// Read the first halfword; bits[1:0] != 11 means compressed (2 bytes).
		hword_lo := read_u16_le(data, byte_count)
		ilen: u32 = 4
		word: u32
		if (hword_lo & 0x3) != 0x3 {
			ilen = 2
			word = u32(hword_lo)
		} else {
			if byte_count + 4 > n_bytes { break }
			word = read_u32_le(data, byte_count)
		}

		inst: Instruction
		info: Instruction_Info
		entry_idx := decode_one_inline(word, byte_count, xlen, ilen == 2, &inst, &info)

		if entry_idx < 0 {
			append(errors, Error{inst_idx = byte_count, code = .INVALID_OPCODE})
			inst = Instruction{mnemonic = .INVALID, length = u8(ilen)}
			info = Instruction_Info{offset = byte_count}
		} else {
			inst.length = u8(ilen)
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
		byte_count += ilen
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
	word: u32, pc: u32, xlen: XLEN, compressed: bool,
	inst: ^Instruction, info: ^Instruction_Info,
) -> int {
	range: Decode_Index
	if compressed {
		// RVC: 5-bit dispatch key from (op[1:0], funct3[15:13]).
		// op==0,1,2 + funct3=0..7 -> 24 buckets.
		key := (word & 0x3) | ((word >> 13) & 0x7) << 2
		range = DECODE_INDEX_RVC[key]
	} else {
		opcode := u8(word & 0x7F)
		if opcode == 0x53 {
			funct7 := u8((word >> 25) & 0x7F)
			range = DECODE_INDEX_OP_FP[funct7]
		} else {
			range = DECODE_INDEX_OPCODE[opcode]
		}
	}

	if range.count == 0 { return -1 }

	base := int(range.start)
	cnt  := int(range.count)
	matched_idx := -1
	for i in 0..<cnt {
		e := &DECODE_ENTRIES[base + i]
		if !xlen_accepts(xlen, e.flags) { continue }
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
xlen_accepts :: #force_inline proc "contextless" (xlen: XLEN, f: Encoding_Flags) -> bool {
	if f.rv32_only && xlen != .RV32 { return false }
	if f.rv64_only && xlen != .RV64 { return false }
	return true
}

@(private="file")
extract_operand_inline :: #force_inline proc "contextless" (
	word: u32, pc: u32, ot: Operand_Type, en: Operand_Encoding,
) -> Operand {
	switch en {
	case .NONE:
		return {}

	// ---- Register slots ----------------------------------------------------
	case .RD:
		return reg_operand(decode_reg(word, 7, ot))
	case .RS1:
		return reg_operand(decode_reg(word, 15, ot))
	case .RS2:
		return reg_operand(decode_reg(word, 20, ot))
	case .RS3:
		return reg_operand(decode_reg(word, 27, ot))

	// ---- Shift amounts -----------------------------------------------------
	case .SHAMT5:
		return Operand{immediate = i64((word >> 20) & 0x1F), kind = .IMMEDIATE, size = 1}
	case .SHAMT6:
		return Operand{immediate = i64((word >> 20) & 0x3F), kind = .IMMEDIATE, size = 1}

	// ---- Immediates --------------------------------------------------------
	case .IMM_I:
		return Operand{immediate = i64(gather_i(word)), kind = .IMMEDIATE, size = 2}
	case .IMM_S:
		return Operand{immediate = i64(gather_s(word)), kind = .IMMEDIATE, size = 2}
	case .IMM_U:
		return Operand{immediate = i64((word >> 12) & 0xFFFFF), kind = .IMMEDIATE, size = 4}
	case .IMM_B:
		target := u32(i32(pc) + gather_b(word))
		return Operand{relative = i64(target), kind = .RELATIVE, size = 2}
	case .IMM_J:
		target := u32(i32(pc) + gather_j(word))
		return Operand{relative = i64(target), kind = .RELATIVE, size = 4}

	// ---- Memory operand variants ------------------------------------------
	case .OFFSET_BASE_I:
		base := decode_reg(word, 15, .GPR)
		disp := gather_i(word)
		return Operand{mem = Memory{base = base, disp = disp}, kind = .MEMORY, size = 4}
	case .OFFSET_BASE_S:
		base := decode_reg(word, 15, .GPR)
		disp := gather_s(word)
		return Operand{mem = Memory{base = base, disp = disp}, kind = .MEMORY, size = 4}
	case .OFFSET_BASE_A:
		base := decode_reg(word, 15, .GPR)
		return Operand{mem = Memory{base = base, disp = 0}, kind = .MEMORY, size = 4}

	// ---- Specialty fields --------------------------------------------------
	case .CSR_FIELD:
		return Operand{immediate = i64((word >> 20) & 0xFFF), kind = .IMMEDIATE, size = 2}
	case .ZIMM_FIELD:
		return Operand{immediate = i64((word >> 15) & 0x1F), kind = .IMMEDIATE, size = 1}
	case .FENCE_PRED:
		return Operand{immediate = i64((word >> 24) & 0xF), kind = .IMMEDIATE, size = 1}
	case .FENCE_SUCC:
		return Operand{immediate = i64((word >> 20) & 0xF), kind = .IMMEDIATE, size = 1}
	case .ROUND_FIELD:
		return Operand{immediate = i64((word >> 12) & 0x7), kind = .IMMEDIATE, size = 1}
	case .AQRL:
		return Operand{immediate = i64((word >> 25) & 0x3), kind = .IMMEDIATE, size = 1}

	// ---- C extension register slots ---------------------------------------
	case .C_RD_RS1:
		return reg_operand(decode_reg(word, 7, ot))
	case .C_RS2:
		return reg_operand(decode_reg(word, 2, ot))
	case .C_RD_PRIMED, .C_RS2_PRIMED:
		hw := u16((word >> 2) & 0x7) + 8
		cls := u16(REG_GPR)
		if ot == .FPR_C { cls = REG_FPR }
		return reg_operand(Register(cls | hw))
	case .C_RS1_PRIMED, .C_RD_RS1_PRIMED:
		hw := u16((word >> 7) & 0x7) + 8
		cls := u16(REG_GPR)
		if ot == .FPR_C { cls = REG_FPR }
		return reg_operand(Register(cls | hw))

	// ---- C extension immediates -------------------------------------------
	case .C_IMM_CI_S:
		v := i32(((word >> 12) & 0x1) << 5 | ((word >> 2) & 0x1F))
		if v & 0x20 != 0 { v |= ~i32(0x3F) }
		return Operand{immediate = i64(v), kind = .IMMEDIATE, size = 1}
	case .C_IMM_CI_U:
		v := u32(((word >> 12) & 0x1) << 5 | ((word >> 2) & 0x1F))
		return Operand{immediate = i64(v), kind = .IMMEDIATE, size = 1}
	case .C_IMM_CIW:
		v := i64(((word >> 11) & 0x3) << 4 |
				 ((word >>  7) & 0xF) << 6 |
				 ((word >>  6) & 0x1) << 2 |
				 ((word >>  5) & 0x1) << 3)
		return Operand{immediate = v, kind = .IMMEDIATE, size = 2}
	case .C_IMM_LUI:
		v := i32(((word >> 12) & 0x1) << 17 | ((word >> 2) & 0x1F) << 12)
		if v & 0x20000 != 0 { v |= ~i32(0x3FFFF) }
		return Operand{immediate = i64(v), kind = .IMMEDIATE, size = 4}
	case .C_IMM_ADDI16SP:
		v := i32(((word >> 12) & 0x1) << 9 |
				 ((word >>  6) & 0x1) << 4 |
				 ((word >>  5) & 0x1) << 6 |
				 ((word >>  3) & 0x3) << 7 |
				 ((word >>  2) & 0x1) << 5)
		if v & 0x200 != 0 { v |= ~i32(0x3FF) }
		return Operand{immediate = i64(v), kind = .IMMEDIATE, size = 2}
	case .C_IMM_CSS_W:
		v := i64(((word >> 9) & 0xF) << 2 | ((word >> 7) & 0x3) << 6)
		return Operand{immediate = v, kind = .IMMEDIATE, size = 1}
	case .C_IMM_CSS_D:
		v := i64(((word >> 10) & 0x7) << 3 | ((word >> 7) & 0x7) << 6)
		return Operand{immediate = v, kind = .IMMEDIATE, size = 2}
	case .C_IMM_CL_W:
		v := i64(((word >> 10) & 0x7) << 3 | ((word >> 6) & 0x1) << 2 | ((word >> 5) & 0x1) << 6)
		return Operand{immediate = v, kind = .IMMEDIATE, size = 1}
	case .C_IMM_CL_D:
		v := i64(((word >> 10) & 0x7) << 3 | ((word >> 5) & 0x3) << 6)
		return Operand{immediate = v, kind = .IMMEDIATE, size = 2}

	// ---- C extension memory operands --------------------------------------
	case .C_OFFSET_BASE_W:
		base := Register(REG_GPR | u16(((word >> 7) & 0x7) + 8))
		disp := i32(((word >> 10) & 0x7) << 3 | ((word >> 6) & 0x1) << 2 | ((word >> 5) & 0x1) << 6)
		return Operand{mem = Memory{base = base, disp = disp}, kind = .MEMORY, size = 4}
	case .C_OFFSET_BASE_D:
		base := Register(REG_GPR | u16(((word >> 7) & 0x7) + 8))
		disp := i32(((word >> 10) & 0x7) << 3 | ((word >> 5) & 0x3) << 6)
		return Operand{mem = Memory{base = base, disp = disp}, kind = .MEMORY, size = 4}
	case .C_SP_OFFSET_W:
		disp := i32(((word >> 12) & 0x1) << 5 | ((word >> 4) & 0x7) << 2 | ((word >> 2) & 0x3) << 6)
		return Operand{mem = Memory{base = SP, disp = disp}, kind = .MEMORY, size = 4}
	case .C_SP_OFFSET_D:
		disp := i32(((word >> 12) & 0x1) << 5 | ((word >> 5) & 0x3) << 3 | ((word >> 2) & 0x7) << 6)
		return Operand{mem = Memory{base = SP, disp = disp}, kind = .MEMORY, size = 4}

	// ---- C extension branches/jumps ---------------------------------------
	case .C_BRANCH9:
		target := u32(i32(pc) + gather_c_branch(word))
		return Operand{relative = i64(target), kind = .RELATIVE, size = 2}
	case .C_BRANCH12:
		target := u32(i32(pc) + gather_c_jump(word))
		return Operand{relative = i64(target), kind = .RELATIVE, size = 2}
	}
	return {}
}

@(private="file")
decode_reg :: #force_inline proc "contextless" (word: u32, shift: u8, ot: Operand_Type) -> Register {
	hw := u16((word >> shift) & 0x1F)
	if ot == .FPR { return Register(REG_FPR | hw) }
	return Register(REG_GPR | hw)
}

@(private="file")
reg_operand :: #force_inline proc "contextless" (r: Register) -> Operand {
	return Operand{reg = r, kind = .REGISTER, size = 4}
}
