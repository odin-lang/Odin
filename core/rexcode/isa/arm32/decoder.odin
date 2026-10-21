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
	// Only matters for M-profile Thumb: the coprocessors that are CDE's.
	cde:          CDE_Coprocessors = {},
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
	// The VPT block the same way: which predicate each instruction after a
	// VPT or VPST runs under.
	vpt_block: VPT_Block
	vpt_next := 0

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
		if !find_and_decode(word, mode, ilen, byte_count, it_state, profile, cde, &inst, &info) {
			append(errors, Error{inst_idx = byte_count, code = .INVALID_OPCODE})
			inst = Instruction{mnemonic = .INVALID, length = u8(ilen), mode = mode}
		} else {
			inst.length = u8(ilen)
			inst.mode   = mode
			inst.in_it_block = in_it_block
			inst.m_profile   = profile == .M_PROFILE
			if vpt_next < vpt_block.count {
				inst.vector_predicate = vpt_block.predicates[vpt_next]
				vpt_next += 1
			}
			if inst.mnemonic == .VPT || inst.mnemonic == .VPST {
				vpt_block = vpt_block_of(u8(inst.ops[0].immediate))
				vpt_next = 0
			}
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
find_and_decode :: proc(word: u32, mode: Mode, ilen: u32, pc: u32, it_state: u8, profile: Profile, cde: CDE_Coprocessors, inst: ^Instruction, info: ^Instruction_Info) -> bool {
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
		// A conditional A32 form never has condition 1111: that is the
		// unconditional space, a different set of instructions.
		if mode == .A32 && e.mask >> 28 == 0 && word >> 28 == 0xF { continue }
		coprocessor := (word >> 8) & 0xF
		if e.feature == .CDE && (coprocessor > 7 || int(coprocessor) not_in cde) { continue }
		if is_generic_coprocessor(e.mnemonic) && !coprocessor_is_generic(coprocessor, profile, cde) {
			// On v8.1-M the floating-point unit leaves one corner of
			// coprocessors 10 and 11 alone: LDC2L and STC2L without an offset,
			// passing an option.
			long_transfer := e.mnemonic == .LDC2L || e.mnemonic == .STC2L
			if !(profile == .M_PROFILE && long_transfer && e.enc[3] == .COPROC_OPTION && (coprocessor == 10 || coprocessor == 11)) { continue }
		}
		if profile == .M_PROFILE && e.flags.a_profile_only { continue }
		if profile == .A_PROFILE && e.flags.m_profile_only { continue }

		// Match -- decode this entry, from nothing: a candidate rejected below
		// after unpacking its operands must leave none of them behind.
		inst^ = {}
		inst.mnemonic      = e.mnemonic
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
			// A B<c> with condition 111x is not one: in sixteen bits that is
			// UDF and SVC, in thirty-two the miscellaneous control space.
			if inst.cond >= 14 { continue }
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
			// An SP as the first operand is SRS's base; PAC's is only a source.
			if e.enc[k] == .A32_REG_LIST || e.enc[k] == .A32_REG_LIST_USER || e.enc[k] == .T32_REG_LIST || e.enc[k] == .RN_A32_WB || (e.enc[k] == .IMPL_SP && k == 0) {
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
		if !thumb_list_valid(e, inst) || !banked_valid(inst) || !q_registers_even(word, e) || !pairs_valid(e, inst) ||
		   !register_lists_valid(e, inst) || !special_register_valid(e, word, profile) ||
		   !conditional_select_valid(e, word) || !loop_valid(e, word) || !thumb_operands_valid(e, word) ||
		   !mve_operands_valid(e, inst) || !branch_future_valid(e, word) {
			continue
		}
		// VMRS transfers flags to APSR_nzcv only from FPSCR; from anything
		// else Rt 1111 is PC.
		if e.mnemonic == .VMRS && inst.ops[0].reg == APSR_NZCV && (word >> 16) & 0xF != 1 {
			inst.ops[0].reg = PC
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

// Whether a coprocessor number names a generic coprocessor rather than
// space given to other instructions: 10 and 11 are the floating-point unit's
// everywhere, v8.1-M gives 8, 9, 14 and 15 to MVE, and a v8-M core can give
// any of 0 to 7 to CDE.
@(private="file")
coprocessor_is_generic :: proc "contextless" (number: u32, profile: Profile, cde: CDE_Coprocessors) -> bool {
	switch profile {
	case .A_PROFILE:
		return number != 10 && number != 11
	case .M_PROFILE:
		if number < 8 { return int(number) not_in cde }
		return number == 12 || number == 13
	}
	return false
}

@(private="file")
is_generic_coprocessor :: proc "contextless" (m: Mnemonic) -> bool {
	return m == .CDP || m == .CDP2 ||
	       m == .MCR || m == .MCR2 || m == .MRC || m == .MRC2 ||
	       m == .MCRR || m == .MCRR2 || m == .MRRC || m == .MRRC2 ||
	       m == .LDC || m == .LDCL || m == .LDC2 || m == .LDC2L ||
	       m == .STC || m == .STCL || m == .STC2 || m == .STC2L
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

// A run of registers that is empty, or runs off the end of its bank, is
// UNPREDICTABLE -- and not one an assembler can write. (More than sixteen D
// registers in a VLDM or VSTM is UNPREDICTABLE too, but assemblers take it;
// what the word says is clear, and it decodes.)
@(private="file")
register_lists_valid :: proc "contextless" (e: ^Decode_Entry, inst: ^Instruction) -> bool {
	for k in 0 ..< len(e.enc) {
		op := &inst.ops[k]
		first := u32(reg_hw(op.reg))
		count := u32(op.list.count)
		stride := u32(max(op.list.stride, 1))
		enc := e.enc[k]
		if enc == .VM_S_PLUS1 {
			// The pair starts at the S register before this one.
			if first > 31 || first == 0 { return false }
		} else if enc == .NEON_MULTIPLE_LIST || enc == .NEON_LANE_LIST || enc == .NEON_ALL_LANES_LIST || enc == .NEON_VN_TABLE {
			if first + (count - 1) * stride > 31 { return false }
		} else if enc == .VFP_S_LIST {
			if count == 0 || first + count > 32 { return false }
		} else if enc == .VFP_D_LIST || enc == .VFP_DX_LIST {
			if count == 0 || first + count > 32 { return false }
		}
	}
	return true
}

// v8.1-M's conditional selects take neither AL nor NV, write neither SP nor
// PC, and read ZR where a source field is 1111 -- but never SP.
@(private="file")
conditional_select_valid :: proc "contextless" (e: ^Decode_Entry, word: u32) -> bool {
	if e.mnemonic != .CSEL && e.mnemonic != .CSINC && e.mnemonic != .CSINV && e.mnemonic != .CSNEG {
		return true
	}
	rd := (word >> 8) & 0xF
	rn := (word >> 16) & 0xF
	rm := word & 0xF
	condition := (word >> 4) & 0xF
	return condition < 14 && rd != 13 && rd != 15 && rn != 13 && rm != 13
}

// Two corners of the 32-bit Thumb space that a row cannot pin. A store
// cannot address relative to PC -- the word is UNDEFINED. And a saturate
// shifted arithmetic-right by nothing is not one: with sh set and no amount,
// the word is SSAT16's or USAT16's.
@(private="file")
thumb_operands_valid :: proc "contextless" (e: ^Decode_Entry, word: u32) -> bool {
	if e.mode != .T32 || inst_size_from_bits(e.bits, e.mode) != 4 {
		return true
	}
	m := e.mnemonic
	if m == .STR || m == .STRB || m == .STRH || m == .STRT || m == .STRBT || m == .STRHT {
		if (word >> 16) & 0xF == 0xF { return false }
	}
	if m == .SSAT || m == .USAT {
		if (word >> 21) & 1 != 0 && t32_shift_amount(word) == 0 { return false }
	}
	// Data processing does not write PC in 32-bit Thumb: with Rd 1111 the
	// flag-setting ones are TST, TEQ, CMN and CMP, and the rest are not
	// instructions -- on v8.1-M, the scalar shifts.
	for k in 0 ..< len(e.enc) {
		if e.enc[k] == .RD_T32 && is_data_processing(m) && (word >> 8) & 0xF == 0xF { return false }
	}
	// A byte or halfword loaded into PC without writeback is a memory hint's
	// word, or none.
	if m == .LDRB || m == .LDRSB || m == .LDRH || m == .LDRSH {
		writeback := false
		for enc in e.enc {
			writeback ||= enc == .MEM_T32_IMM8_PRE || enc == .MEM_T32_IMM8_POST
		}
		if (word >> 12) & 0xF == 0xF && !writeback { return false }
	}
	// Nor does a load write back to PC.
	for enc in e.enc {
		if (enc == .MEM_T32_IMM8_PRE || enc == .MEM_T32_IMM8_POST) && (word >> 16) & 0xF == 0xF { return false }
	}
	return true
}

@(private="file")
is_data_processing :: proc "contextless" (m: Mnemonic) -> bool {
	return m == .AND || m == .BIC || m == .ORR || m == .ORN || m == .EOR || m == .ADD ||
	       m == .ADC || m == .SBC || m == .SUB || m == .RSB || m == .MOV || m == .MVN ||
	       m == .LSL || m == .LSR || m == .ASR || m == .ROR || m == .RRX
}

// MVE's registers that a field could name but the architecture does not
// allow: the high half of an accumulator pair or of a scalar long shift is
// R1 to R11, VIWDUP's wrap the same, a run of Q registers stops at Q7, and
// VLDR and VSTR reach six system registers.
@(private="file")
mve_operands_valid :: proc "contextless" (e: ^Decode_Entry, inst: ^Instruction) -> bool {
	for k in 0 ..< len(e.enc) {
		enc := e.enc[k]
		op := &inst.ops[k]
		if enc == .MVE_RDAHI || enc == .MVE_LONG_RDAHI || enc == .MVE_RM_ODD {
			if reg_hw(op.reg) > 11 { return false }
		} else if enc == .MVE_Q_LIST {
			if u32(reg_hw(op.reg)) + u32(op.list.count) > 8 { return false }
		} else if enc == .FP_SYSTEM_REGISTER {
			n := reg_hw(op.reg)
			if n != 1 && n != 2 && n < 12 { return false }
		}
	}
	return true
}

// A Branch Future names a condition other than AL and NV, and branches to a
// register other than SP and PC -- BFLX not LR either.
@(private="file")
branch_future_valid :: proc "contextless" (e: ^Decode_Entry, word: u32) -> bool {
	if e.mnemonic == .BFCSEL {
		return (word >> 18) & 0xF < 14
	}
	if e.mnemonic == .BFX || e.mnemonic == .BFLX {
		rm := (word >> 16) & 0xF
		return rm != 13 && rm != 15 && (e.mnemonic != .BFLX || rm != 14)
	}
	return true
}

// A low-overhead loop counts in a register, which SP and PC are not; DLSTP
// with PC there is LCTP.
@(private="file")
loop_valid :: proc "contextless" (e: ^Decode_Entry, word: u32) -> bool {
	if e.mnemonic != .WLS && e.mnemonic != .DLS && e.mnemonic != .WLSTP && e.mnemonic != .DLSTP {
		return true
	}
	rn := (word >> 16) & 0xF
	return rn != 13 && rn != 15
}

// VMRS and VMSR reach a different set of system registers in each profile:
// the M profile drops none of the A profile's but adds FPSCR_nzcvqc, VPR, P0
// and the FPCXT pair, and VMSR cannot write the three MVFRs.
@(private="file")
special_register_valid :: proc "contextless" (e: ^Decode_Entry, word: u32, profile: Profile) -> bool {
	if e.mnemonic != .VMRS && e.mnemonic != .VMSR {
		return true
	}
	register := (word >> 16) & 0xF
	A_READ  :: 0b0000_0111_1110_0011    // fpsid fpscr mvfr2-0 fpexc fpinst fpinst2
	M_EXTRA :: 0b1111_0000_0000_0100    // fpscr_nzcvqc vpr p0 fpcxtns fpcxts
	MVFR    :: 0b0000_0000_1110_0000
	valid: u32 = A_READ
	if profile == .M_PROFILE { valid |= M_EXTRA }
	if e.mnemonic == .VMSR { valid &~= MVFR }
	return valid & (1 << register) != 0
}

// The second of a register pair is the one after the first, and there is
// none after LR that a pair can use.
@(private="file")
pairs_valid :: proc "contextless" (e: ^Decode_Entry, inst: ^Instruction) -> bool {
	for k in 1 ..< len(e.enc) {
		if e.enc[k] != .RT_PAIR_NEXT && e.enc[k] != .RM_PAIR_NEXT { continue }
		if reg_hw(inst.ops[k - 1].reg) >= 14 { return false }
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
	switch ot {
	case .NONE:
		return Operand{}
	case .GPR, .GPR_NOPC, .GPR_NOSP, .GPR_LOW, .GPR_SHIFTED, .GPR_RSR:
		return op_reg(R0)
	case .GPR_LIST:
		return op_reg_list(0)
	case .GPR_ZR:
		return op_reg(R0)
	case .SPR:
		return op_reg(S0)
	case .DPR:
		return op_reg(D0)
	case .QPR:
		return op_reg(Q0)
	case .SPR_LIST, .DPR_LIST:
		return op_reg_list(0)
	case .SPR_ELEM:
		return op_reg(S0)
	case .DPR_ELEM:
		return op_reg(D0)
	case .QPR_ELEM:
		return op_reg(Q0)
	case .IMM, .IMM_MOD, .IMM_T32_MOD, .IMM16_LO_HI, .IMM12, .IMM5, .IMM5_W, .IMM4,
	     .IMM4_SAT, .IMM8, .IMM3, .IMM_HINT, .IMM_BARRIER, .IMM_ENDIAN, .IMM_IFLAGS,
	     .IMM_BANKED, .IMM_SYSM, .IMM_COPROC, .IMM_COPROC_OP, .NEON_IMM:
		return op_imm(0)
	case .REL24, .REL24_T32, .REL20, .REL11, .REL8, .REL_LDR_LITERAL, .REL_BF:
		return op_rel_offset(0)
	case .COND:
		return op_imm(0)
	case .MEM:
		return op_mem(mem_imm(R0, 0))
	case .COPROC_REG, .COPROC_NUM, .PSR_FIELD:
		return op_imm(0)
	case .VPR, .QPR_MVE:
		return op_reg(Q0)
	case .QPR_MVE_LIST:
		return op_reg_list(0)
	case .MVE_VPT_MASK, .MVE_VCTP_SIZE:
		return op_imm(0)
	case .MVE_LOOP_TGT:
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
	case .RD, .RT_A32, .RDLO_A32:
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
		if ot == .GPR_RSR {
			// Register-shifted register: Rs in bits 11..8, shift type in 6..5,
			// bit 4 = 1. We map the 2-bit shift type onto the .{LSL,LSR,ASR,
			// ROR}_REG markers so the encoder shape-match can distinguish
			// imm-shift from reg-shift. Rs is stored in shift_amt.
			st_bits := (word >> 5) & 0x3
			st  := Shift_Type(u8(st_bits) + u8(Shift_Type.LSL_REG))
			rs  := u8((word >> 8) & 0xF)
			return Operand{reg = reg, kind = .REGISTER, size = 4,
						   shift_type = st, shift_amt = rs}
		}
		if ot == .GPR_SHIFTED {
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
	case .RM_A32_ROTATED:
		reg := Register(REG_GPR | u16(word & 0xF))
		rotation := u8((word >> 10) & 0x3) * 8
		if rotation == 0 { return op_reg(reg) }
		return op_reg_shifted(reg, .ROR, rotation)
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
	case .IMM4_IMM12:
		return op_imm(i64(((word >> 16) & 0xF) << 12 | (word & 0xFFF)))
	case .CPS_IFLAGS_A32:
		return op_reg(Register(REG_IFLAGS | u16((word >> 6) & 0x7)))
	case .SETPAN_IMM_A32:
		return op_imm(i64((word >> 9) & 1))
	case .RM_PAIR_NEXT:
		return op_reg(Register(REG_GPR | u16(((word & 0xF) + 1) & 0xF)))
	case .BRANCH_BLX_A32:
		v := i32(word & 0xFFFFFF)
		if v & 0x800000 != 0 { v |= -0x1000000 }
		return op_rel_offset(pc_value + i64(v << 2) + i64((word >> 24) & 1) * 2)
	case .IMM12_IMM4:
		return op_imm(i64(((word >> 8) & 0xFFF) << 4 | (word & 0xF)))
	case .NEON_VEXT_IMM4:
		return op_imm(i64((word >> 8) & 0xF))
	case .A32_REG_LIST_USER:
		op := op_reg_list(u16(word & 0xFFFF))
		op.list.user = true
		return op
	case .MEM_REG_SHIFTED, .MEM_REG_SHIFTED_PRE, .MEM_REG_SHIFTED_POST:
		base  := Register(REG_GPR | u16((word >> 16) & 0xF))
		index := Register(REG_GPR | u16(word & 0xF))
		sign: i8 = (word >> 23) & 1 != 0 ? 1 : -1
		// The same shift encoding as a data-processing register: a zero
		// amount is no shift for LSL, 32 for LSR and ASR, RRX for ROR.
		shift := Shift_Type((word >> 5) & 0x3)
		amount := u8((word >> 7) & 0x1F)
		if shift == .ROR && amount == 0 {
			shift = .RRX
		} else if (shift == .LSR || shift == .ASR) && amount == 0 {
			amount = 32
		}
		m := mem_reg_shift(base, index, shift, amount, sign)
		if enc == .MEM_REG_SHIFTED_PRE  { m.mode = .PRE_INDEX }
		if enc == .MEM_REG_SHIFTED_POST { m.mode = .POST_INDEX }
		return op_mem(m)
	case .MEM_REG_PRE, .MEM_REG_POST:
		base  := Register(REG_GPR | u16((word >> 16) & 0xF))
		index := Register(REG_GPR | u16(word & 0xF))
		sign: i8 = (word >> 23) & 1 != 0 ? 1 : -1
		m := mem_reg(base, index, sign)
		m.mode = enc == .MEM_REG_PRE ? .PRE_INDEX : .POST_INDEX
		return op_mem(m)
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
	case .A32_IMM_MOD:
		// Written as a value when the word holds the encoding an assembler
		// would choose for it, and as its parts when it holds another.
		field := word & 0xFFF
		value := decode_a32_modimm(field)
		if canonical, ok := encode_a32_modimm(value); ok && canonical == field {
			return op_imm(i64(value))
		}
		return op_rotated_imm(u8(field & 0xFF), u8((field >> 8) * 2))
	case .T32_IMM_MOD:
		i_bit := (word >> 26) & 1
		imm3  := (word >> 12) & 0x7
		imm8  :=  word        & 0xFF
		f12 := (i_bit << 11) | (imm3 << 8) | imm8
		return op_imm(i64(decode_t32_modimm(f12)))

	// ---- A32 immediates ----

	case .A32_IMM_SHIFT: return op_imm(i64((word >> 7) & 0x1F))
	case .A32_IMM_SHIFT_32:
		// The LSR and ASR mnemonics reach 32 the same way a shifted operand
		// does: a field of zero, since a shift of zero would be a MOV.
		amt := (word >> 7) & 0x1F
		return op_imm(i64(amt == 0 ? 32 : amt))

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
	// ---- Misc ----
	case .BARRIER_TYPE: return op_imm(i64(word & 0xF))
	case .HINT_FIELD:   return op_imm(i64(word & 0xFF))

	// The fields MSR writes, and whether they are SPSR's: `cpsr_fc`.
	case .PSR_FIELD_MASK: return op_reg(Register(REG_PSR_FIELDS | u16(((word >> 22) & 1) << 4) | u16(decode_psr_field(word))))

	case .COPROC_NUM_FIELD:  return op_reg(Register(REG_COPROC_NUM | u16((word >> 8) & 0xF)))
	case .COPROC_OPC1_FIELD: return op_imm(i64((word >> 20) & 0xF))
	case .COPROC_OPC2_FIELD: return op_imm(i64((word >> 5) & 0x7))
	case .COPROC_CRN_FIELD:  return op_reg(Register(REG_COPROC | u16((word >> 16) & 0xF)))
	case .COPROC_CRM_FIELD:  return op_reg(Register(REG_COPROC | u16(word & 0xF)))
	case .COPROC_CRD_FIELD:  return op_reg(Register(REG_COPROC | u16((word >> 12) & 0xF)))
	case .COPROC_OPTION:     return op_imm(i64(word & 0xFF))
	case .COPROC_OPC1_MCR:   return op_imm(i64((word >> 21) & 0x7))
	case .COPROC_OPC_MCRR:   return op_imm(i64((word >> 4) & 0xF))


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
	case .NEON_MULTIPLE_LIST, .NEON_LANE_LIST, .NEON_ALL_LANES_LIST:
		n := ((word >> 22) & 1) << 4 | ((word >> 12) & 0xF)
		list := structure_list(word)
		op := op_reg_run(Register(REG_DPR | u16(n)), list.count, list.stride, enc == .NEON_ALL_LANES_LIST)
		if enc == .NEON_LANE_LIST {
			op.lane = list.lane
			op.has_lane = true
		}
		return op
	case .NEON_ADDRESS:
		// Rm says the writeback: 1111 none, 1101 by what was transferred, any
		// other register by that register.
		m := Memory{base = Register(REG_GPR | u16((word >> 16) & 0xF)), sign = 1, align = structure_alignment(word)}
		switch rm := word & 0xF; rm {
		case 0xF:
			m.mode = .OFFSET
		case 0xD:
			m.mode = .POST_INCREMENT
		case:
			m.mode = .POST_INDEX
			m.index = Register(REG_GPR | u16(rm))
		}
		return op_mem(m)
	case .NEON_VDUP_LANE:
		// The marker is the lowest set bit of imm4, the lane the bits above.
		imm4 := (word >> 16) & 0xF
		shift: u32 = imm4 & 1 != 0 ? 1 : imm4 & 2 != 0 ? 2 : 3
		return op_dpr_lane(Register(REG_DPR | u16(((word >> 5) & 1) << 4 | (word & 0xF))), u8(imm4 >> shift))
	case .NEON_VM_SCALAR_16:
		return op_dpr_lane(Register(REG_DPR | u16(word & 0x7)),
		                   u8(((word >> 5) & 1) << 1 | ((word >> 3) & 1)))
	case .NEON_VM_SCALAR_32:
		return op_dpr_lane(Register(REG_DPR | u16(word & 0xF)), u8((word >> 5) & 1))
	case .NEON_VM_D_LANE0:
		return op_dpr_lane(Register(REG_DPR | u16(((word >> 5) & 1) << 4 | (word & 0xF))), 0)
	case .NEON_VM_S_SCALAR:
		op := op_reg(Register(REG_SPR | u16((word & 0x7) << 1 | (word >> 5) & 1)))
		op.lane = u8((word >> 3) & 1)
		op.has_lane = true
		return op
	case .NEON_VN_TABLE:
		n := ((word >> 7) & 1) << 4 | ((word >> 16) & 0xF)
		return op_reg_run(Register(REG_DPR | u16(n)), u8((word >> 8) & 0x3) + 1)
	case .VFP_S_LIST:
		// {S<Vd>, ...} -- imm8 counts the registers, and the run starts at Vd.
		// Both halves matter: keeping only the count printed the wrong bank
		// and the wrong registers. register_lists_valid turns away a count
		// that is zero or runs past s31.
		n := ((word >> 12) & 0xF) << 1 | ((word >> 22) & 1)
		return op_reg_run(Register(REG_SPR | u16(n)), u8(min(word & 0xFF, 32)))
	case .VFP_D_LIST, .VFP_DX_LIST:
		// {D<Vd>, ...} -- imm8 counts words, two per D register; the FLDMX
		// and FSTMX forms add one more, so their count is odd.
		n := ((word >> 22) & 1) << 4 | ((word >> 12) & 0xF)
		return op_reg_run(Register(REG_DPR | u16(n)), u8(min((word & 0xFF) / 2, 32)))

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
		return op_reg(Register(REG_COND | u16((word >> 18) & 0xF)))
	case .BFCSEL_ELSE:
		imm4 := (word >> 23) & 0xF
		return op_rel_offset(pc_value + i64(imm4) << 1 + 2 + i64((word >> 17) & 1) * 2)

	// ---- Saturate / bit field ----
	case .NEON_SHLL:    return op_imm(i64(8) << ((word >> 18) & 0x3))
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
	case .RT_OR_APSR_NZCV:
		rt := (word >> 12) & 0xF
		return op_reg(rt == 15 ? APSR_NZCV : Register(REG_GPR | u16(rt)))
	case .RN_OR_APSR_NZCV:
		rn := (word >> 16) & 0xF
		return op_reg(rn == 15 ? APSR_NZCV : Register(REG_GPR | u16(rn)))
	case .RM_OR_APSR_NZCV:
		rm := word & 0xF
		return op_reg(rm == 15 ? APSR_NZCV : Register(REG_GPR | u16(rm)))
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
	case .NEON_SHIFT_RIGHT:
		return op_imm(i64(2 * shift_element_bits(word)) - i64(shift_field(word)))
	case .NEON_SHIFT_LEFT:
		return op_imm(i64(shift_field(word)) - i64(shift_element_bits(word)))
	case .NEON_FBITS:
		return op_imm(64 - i64((word >> 16) & 0x3F))

	// ---- A32 RS shift (Rs register in bits 11:8) ----
	// ---- A32 COND ----
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

	case .MVE_VPT_MASK:        return op_imm(i64(((word >> 22) & 1) << 3 | (word >> 13) & 0x7))
	case .MVE_VCMP_COND:
		fc := ((word >> 12) & 1) << 2 | ((word >> 7) & 1) << 1 | word & 1
		return op_reg(Register(REG_COND | u16(MVE_CONDITIONS[fc])))
	case .MVE_VCMP_COND_SCALAR:
		fc := ((word >> 12) & 1) << 2 | ((word >> 7) & 1) << 1 | (word >> 5) & 1
		return op_reg(Register(REG_COND | u16(MVE_CONDITIONS[fc])))
	case .MVE_LANE:
		return op_qpr_lane(Register(REG_QPR | u16((word >> 17) & 0x7)), mve_lane(word))
	case .MVE_LANE_PAIR_HIGH:
		return op_qpr_lane(Register(REG_QPR | u16((word >> 13) & 0x7)), u8(2 + (word >> 4) & 1))
	case .MVE_LANE_PAIR_LOW:
		return op_qpr_lane(Register(REG_QPR | u16((word >> 13) & 0x7)), u8((word >> 4) & 1))
	case .MVE_SHIFT_RIGHT:
		return op_imm(i64(2 * mve_shift_element_bits(word, false)) - i64((word >> 16) & 0x3F))
	case .MVE_SHIFT_LEFT:
		return op_imm(i64((word >> 16) & 0x3F) - i64(mve_shift_element_bits(word, false)))
	case .MVE_SHIFT_LONG:
		return op_imm(i64((word >> 16) & 0x1F) - i64(mve_shift_element_bits(word, true)))
	case .MVE_SHLL_MAX:
		return op_imm(i64(8) << ((word >> 18) & 1))
	case .MVE_SHLC_IMM:
		amount := (word >> 16) & 0x1F
		return op_imm(i64(amount == 0 ? 32 : amount))
	case .MVE_LONG_RDALO:
		return op_reg(Register(REG_GPR | u16(((word >> 17) & 0x7) * 2)))
	case .MVE_LONG_RDAHI:
		return op_reg(Register(REG_GPR | u16(((word >> 9) & 0x7) * 2 + 1)))
	case .MVE_LONG_SHIFT_IMM:
		amount := ((word >> 12) & 0x7) << 2 | (word >> 6) & 0x3
		return op_imm(i64(amount == 0 ? 32 : amount))
	case .MVE_SATURATE:
		return op_imm((word >> 7) & 1 != 0 ? 48 : 64)
	case .MVE_ROT_CMUL:
		return op_imm(i64(((word >> 12) & 1) << 1 | word & 1) * 90)
	case .MVE_Q_LIST:
		return op_reg_run(Register(REG_QPR | u16((word >> 13) & 0x7)), word & 1 != 0 ? 4 : 2)
	case .MVE_ADDRESS, .MVE_ADDRESS_WIDE, .MVE_ADDRESS_VECTOR:
		m := Memory{sign = (word >> 23) & 1 != 0 ? 1 : -1, mode = mve_index_mode(word)}
		scale: i32
		if enc == .MVE_ADDRESS {
			m.base = Register(REG_GPR | u16((word >> 16) & 0xF))
			scale = mve_address_scale(word)
		} else if enc == .MVE_ADDRESS_WIDE {
			m.base = Register(REG_GPR | u16((word >> 16) & 0x7))
			scale = mve_wide_scale(word)
		} else {
			m.base = Register(REG_QPR | u16((word >> 17) & 0x7))
			scale = mve_vector_scale(word)
		}
		m.disp = i32(word & 0x7F) * scale
		if m.sign < 0 { m.disp = -m.disp }
		return op_mem(m)
	case .MVE_STRUCTURE_ADDRESS:
		m := Memory{base = Register(REG_GPR | u16((word >> 16) & 0xF)), sign = 1}
		m.mode = (word >> 21) & 1 != 0 ? .POST_INCREMENT : .OFFSET
		return op_mem(m)
	case .MVE_ADDRESS_OFFSET:
		m := Memory{base = Register(REG_GPR | u16((word >> 16) & 0xF)), index = Register(REG_QPR | u16((word >> 1) & 0x7)), sign = 1, mode = .OFFSET}
		if word & 1 != 0 {
			m.shift_type = .UXTW
			m.shift_amt = mve_offset_shift(word)
		}
		return op_mem(m)
	case .FP_SYSTEM_REGISTER:
		return op_reg(Register(REG_FPSC | u16(((word >> 22) & 1) << 3 | (word >> 13) & 0x7)))
	case .MVE_RN_EVEN:         return op_reg(Register(REG_GPR | u16(((word >> 17) & 0x7) * 2)))
	case .MVE_RM_ODD:          return op_reg(Register(REG_GPR | u16(((word >> 1) & 0x7) * 2 + 1)))
	case .MVE_DUP_IMM:         return op_imm(i64(1) << (((word >> 7) & 1) << 1 | word & 1))
	case .CDE_COPROC_FIELD:    return op_reg(Register(REG_COPROC_NUM | u16((word >> 8) & 0x7)))
	case .CDE_IMM_CX1:
		return op_imm(i64(word & 0x3F | ((word >> 7) & 1) << 6 | ((word >> 16) & 0x3F) << 7))
	case .CDE_IMM_CX2:
		return op_imm(i64(word & 0x3F | ((word >> 7) & 1) << 6 | ((word >> 20) & 0x3) << 7))
	case .CDE_IMM_CX3:
		return op_imm(i64((word >> 4) & 0x3 | ((word >> 7) & 1) << 2 | ((word >> 20) & 0x7) << 3))
	case .CDE_IMM_VCX1:
		imm := word & 0x3F | ((word >> 7) & 1) << 6 | ((word >> 16) & 0xF) << 7
		if word & 0x40 != 0 { imm |= ((word >> 24) & 1) << 11 }
		return op_imm(i64(imm))
	case .CDE_IMM_VCX2:
		imm := (word >> 4) & 1 | ((word >> 7) & 1) << 1 | ((word >> 16) & 0xF) << 2
		if word & 0x40 != 0 { imm |= ((word >> 24) & 1) << 6 }
		return op_imm(i64(imm))
	case .CDE_IMM_VCX3:
		imm := (word >> 4) & 1 | ((word >> 20) & 0x3) << 1
		if word & 0x40 != 0 { imm |= ((word >> 24) & 1) << 3 }
		return op_imm(i64(imm))

	// ---- Memory addressing flavours ----
	// PRE_INDEX and POST_INDEX wrap MEM_IMM12_OFFSET: same field layout but the
	// addressing mode flag is set differently. We reconstruct the full Memory
	// operand here (base, disp, sign, mode).
	case .RT_PAIR_NEXT:
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


