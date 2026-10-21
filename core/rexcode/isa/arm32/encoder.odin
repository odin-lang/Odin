// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm32

// =============================================================================
// AArch32 ENCODER
// =============================================================================
//
// Two-pass design (mirrors riscv/encoder.odin):
//
//   PASS 1   - For each Instruction, find the first matching Encoding form
//              (by Mnemonic / mode / operand-shape), pack operand bits onto
//              the form's static `bits`, and emit either 2 or 4 bytes
//              depending on inst_size_from_bits. Branch operands emit
//              Relocation entries that PASS 2 resolves.
//   PASS 1.5 - Rewrite label_defs[] from instruction index to byte offset
//              (required because T16 and T32 instructions mix 2/4-byte sizes).
//   PASS 2   - Walk the pending relocations and patch in scattered branch
//              offsets, dropping any whose label resolved.
//
// PC for arm32 is (current_inst_addr + 8) in A32 and (+4) in T32; the
// resolver subtracts that automatically.

MAX_INST_SIZE :: 4

encode_max_code_size :: #force_inline proc "contextless" (instructions: []Instruction) -> int {
	return len(instructions) * MAX_INST_SIZE
}

encode_max_relocation_count :: #force_inline proc "contextless" (instructions: []Instruction) -> int {
	return len(instructions)
}

// Pre-size the caller's encode outputs (code grown by length so code[:] is a
// valid emit target; relocs reserved by capacity) so the encode hot path never
// reallocates. Allocates no new buffers; pass nil to skip either array.
encode_reserve :: proc(code: ^[dynamic]u8, relocs: ^[dynamic]Relocation, instructions: []Instruction) {
	if code != nil {
		size := encode_max_code_size(instructions)
		if len(code) < size {
			resize(code, size)
		}
	}
	if relocs != nil {
		reserve(relocs, len(relocs) + encode_max_relocation_count(instructions))
	}
}

encode :: proc(
	instructions: []Instruction,
	label_defs:   []Label_Definition,
	code:         []u8,
	relocs:       ^[dynamic]Relocation,
	errors:       ^[dynamic]Error,
	resolve:      bool = true,
	base_address: u64  = 0,
) -> (byte_count: u32, ok: bool) {
	n_inst := len(instructions)
	if len(code) < n_inst * 4 {
		append(errors, Error{inst_idx = 0, code = .BUFFER_OVERFLOW})
		return
	}

	errors_start  := u32(len(errors))
	pending_start := u32(len(relocs))

	inst_pc := make([]u32, n_inst, context.temp_allocator)

	// ITSTATE, kept the way the decoder keeps it: whether an instruction is
	// inside an IT block decides whether its 16-bit form sets the flags.
	it_state: u8 = 0

	// ---- PASS 1 ------------------------------------------------------------
	for i in 0..<n_inst {
		inst_pc[i] = byte_count
		inst := &instructions[i]
		in_it_block := inst.mode == .T32 && it_state & 0xF != 0
		word, ilen := encode_one_inline(inst, byte_count, u16(i), relocs, errors, in_it_block) or_return
		if inst.mnemonic == .IT {
			it_state = u8(inst.ops[0].immediate & 0xF) << 4 | u8(inst.ops[1].immediate & 0xF)
		} else if in_it_block {
			if it_state & 0x7 == 0 {
				it_state = 0
			} else {
				it_state = (it_state & 0xE0) | ((it_state << 1) & 0x1F)
			}
		}

		if ilen == 2 {
			write_u16_le(code, byte_count, u16(word))
		} else {
			// T32 32-bit: bits = low_hword | (high_hword << 16); each
			// halfword is written little-endian in its own slot.
			if inst.mode == .T32 {
				write_u16_le(code, byte_count,     u16(word >> 16))
				write_u16_le(code, byte_count + 2, u16(word))
			} else {
				write_u32_le(code, byte_count, word)
			}
		}
		byte_count += u32(ilen)
	}

	// ---- PASS 1.5: label_def instruction-idx -> byte-offset -----------------
	for &ld in label_defs {
		if ld != LABEL_UNDEFINED {
			idx := int(u32(ld))
			if idx < n_inst {
				ld = Label_Definition(inst_pc[idx])
			} else {
				ld = LABEL_UNDEFINED
			}
		}
	}

	if !resolve {
		ok = u32(len(errors)) == errors_start
		return
	}

	// ---- PASS 2: resolve relocations ----------------------------------------
	n_relocs  := u32(len(relocs))
	write_idx := pending_start
	for read_idx in pending_start..<n_relocs {
		r := relocs[read_idx]
		if resolve_relocation_inline(code, label_defs, &r, base_address, errors) {
			continue
		}
		if write_idx != read_idx { relocs[write_idx] = r }
		write_idx += 1
	}
	if write_idx != n_relocs { resize(relocs, int(write_idx)) }

	ok = u32(len(errors)) == errors_start
	return
}

// =============================================================================
// Encode one instruction
// =============================================================================

@(private="file")
encode_one_inline :: #force_inline proc(
	inst:     ^Instruction,
	pc:       u32,
	inst_idx: u16,
	relocs:   ^[dynamic]Relocation,
	errors:   ^[dynamic]Error,
	in_it_block: bool,
) -> (word: u32, ilen: u8, ok: bool) {
	if inst.mnemonic == .INVALID {
		append(errors, Error{inst_idx = u32(inst_idx), code = .INVALID_MNEMONIC})
		return 0, 0, false
	}

	forms := encoding_forms(inst.mnemonic)
	if len(forms) == 0 {
		append(errors, Error{inst_idx = u32(inst_idx), code = .INVALID_MNEMONIC})
		return 0, 0, false
	}

	// Find a form matching the active mode + operand shape + S-flag.
	// If the caller supplied an inst.length, also constrain the candidate
	// form's ilen — T32 mode hosts both T16 (ilen=2) and T32-wide (ilen=4)
	// forms with overlapping shape matches; without this filter the wide
	// form silently degrades to the narrow form on encode.
	want_len: u8 = inst.length
	form: ^Encoding

	// form-id hint: when the decoder roundtrips an instruction, it stamps the
	// ENCODING_TABLE-relative form index it picked (+1, so 0 means "no hint").
	// Try that exact form first; if it still passes the shape/mode checks,
	// use it. Resolves the NEON size-variant ambiguity (DPR,DPR,DPR shape is
	// shared by VADD.I8/.I16/.I32/.F16/.F32 forms with different fixed bits).
	if inst.form_id != 0 && int(inst.form_id) - 1 < len(forms) {
		f := &forms[inst.form_id - 1]
		if f.mode == inst.mode &&
		   (inst.dt[0] == .NONE || f.dt == inst.dt) &&
		   (want_len == 0 || inst_size_from_bits(f.bits, f.mode) == want_len) &&
		   encoding_matches_inline(inst, f) &&
		   inst.sets_flags == form_sets_flags(f, in_it_block) &&
		   condition_matches(inst, f, in_it_block) &&
		   writeback_matches(inst, f) &&
		   mem_mode_matches(inst, f) &&
		   operands_fit(inst, f) {
			form = f
		}
	}
	if form == nil {
		for &f in forms {
			if f.mode != inst.mode { continue }
			// The `.i32` / `.s32.f32` suffix. NEON reuses one operand shape
			// across every element width, so without this the scan can only
			// ever reach the first form of a shape. .NONE means the caller did
			// not say, and every form of the shape stays eligible.
			if inst.dt[0] != .NONE && f.dt != inst.dt { continue }
			if want_len > 0 && inst_size_from_bits(f.bits, f.mode) != want_len { continue }
			if !encoding_matches_inline(inst, &f) { continue }
			if inst.sets_flags != form_sets_flags(&f, in_it_block) { continue }
			if !condition_matches(inst, &f, in_it_block) { continue }
			if !writeback_matches(inst, &f) { continue }
			if !mem_mode_matches(inst, &f) { continue }
			if !operands_fit(inst, &f) { continue }
			form = &f
			break
		}
	}
	if form == nil {
		append(errors, Error{inst_idx = u32(inst_idx), code = .NO_MATCHING_ENCODING})
		return 0, 0, false
	}

	word = form.bits

	// Bake condition into bits 31:28 for A32 conditional entries.
	// Detect: mask bits 31:28 = 0 means cond field is variable (conditional).
	// (cond_in_28 flag in encoding_types.odin defaults to false, so we use
	// the structural mask test as the source of truth here.)
	if form.mode == .A32 && (form.mask >> 28) == 0 {
		word = (word & 0x0FFFFFFF) | (u32(inst.cond) << 28)
	}
	ilen = inst_size_from_bits(form.bits, form.mode)
	if form.flags.thumb_condition {
		word |= u32(inst.cond & 0xF) << (ilen == 2 ? 8 : 22)
	}
	// VSEL names one of four conditions, in bits 21:20.
	if form.flags.cond_in_21 {
		switch inst.cond {
		case 0:  word |= 0 << 20   // EQ
		case 6:  word |= 1 << 20   // VS
		case 10: word |= 2 << 20   // GE
		case 12: word |= 3 << 20   // GT
		}
	}

	operand_bits: u32 = 0
	for k in 0 ..< len(form.enc) {
		if form.enc[k] == .NONE { continue }
		operand_bits |= pack_operand_inline(&inst.ops[k], form.enc[k], pc, inst_idx, relocs, form, inst)
	}
	// The operand packers write A32 layout, where Advanced SIMD has a bit of
	// the instruction at 24; Thumb moved that bit to 28.
	if form.mode == .T32 && is_thumb_simd(form.bits) {
		operand_bits = (operand_bits & ~u32(1 << 24)) | ((operand_bits >> 24) & 1) << 28
	}
	word |= operand_bits

	return word, ilen, true
}

// Whether a 32-bit Thumb instruction could have been encoded in 16 bits: same
// mnemonic, an operand shape and values a 16-bit form takes, and the flag
// setting that form has where the instruction stands. This is the test for
// printing `.w` -- without it an assembler picks the 16-bit form.
@(private)
has_narrow_encoding :: proc(inst: ^Instruction, in_it_block: bool) -> bool {
	for &form in encoding_forms(inst.mnemonic) {
		if form.mode != .T32 || inst_size_from_bits(form.bits, form.mode) != 2 { continue }
		if !encoding_matches_inline(inst, &form) { continue }
		if inst.sets_flags != form_sets_flags(&form, in_it_block) { continue }
		if !condition_matches(inst, &form, in_it_block) { continue }
		if !writeback_matches(inst, &form) { continue }
		if !mem_mode_matches(inst, &form) { continue }
		if !operands_fit(inst, &form) { continue }
		return true
	}
	return false
}

// The value a modified-immediate operand stands for, in the form decode gives
// it: a float's bit pattern for cmode 1111, the integer otherwise.
@(private)
neon_modimm_value :: #force_inline proc "contextless" (op: ^Operand, cmode: u32) -> u64 {
	if cmode == 0b1111 {
		return u64(u32(op.immediate))
	}
	return u64(op.immediate)
}

// Whether a form sets the flags where the instruction stands. Most 16-bit
// Thumb data processing does exactly when it is outside an IT block.
@(private)
form_sets_flags :: #force_inline proc "contextless" (form: ^Encoding, in_it_block: bool) -> bool {
	return form.flags.sets_flags || (form.flags.flags_outside_it && !in_it_block)
}

// A Thumb instruction takes its condition from an IT block, except a B<c>,
// which carries one of its own and may not sit in a block. Outside a block,
// only that B<c> can be conditional, and it cannot be unconditional -- its
// AL and NV slots are UDF and SVC.
@(private)
condition_matches :: #force_inline proc "contextless" (inst: ^Instruction, form: ^Encoding, in_it_block: bool) -> bool {
	// VSEL's condition is its own, in the word, in A32 and Thumb alike, and
	// it can name only four.
	if form.flags.cond_in_21 {
		return inst.cond == 0 || inst.cond == 6 || inst.cond == 10 || inst.cond == 12
	}
	if form.mode != .T32 {
		return true
	}
	if form.flags.thumb_condition {
		return !in_it_block && inst.cond < 14
	}
	return in_it_block || inst.cond == 14
}

// =============================================================================
// Shape matching: do the Operand kinds line up with the form's Operand_Type?
// =============================================================================

@(private="file")
is_rsr_shift_type :: #force_inline proc "contextless" (s: Shift_Type) -> bool {
	return s == .LSL_REG || s == .LSR_REG || s == .ASR_REG || s == .ROR_REG
}

@(private="file")
rsr_type_bits :: #force_inline proc "contextless" (s: Shift_Type) -> u32 {
	#partial switch s {
	case .LSL_REG: return 0
	case .LSR_REG: return 1
	case .ASR_REG: return 2
	case .ROR_REG: return 3
	}
	return 0
}

// Memory addressing modes (OFFSET vs PRE_INDEX vs POST_INDEX) aren't carried
// in the Operand_Type shape — both .MEM forms shape-match equally. Pick the
// form whose memory encoding matches the operand's mode so a [Rn,#x]! input
// gets the writeback form, not the plain offset form (and vice versa).
@(private)
mem_mode_matches :: #force_inline proc "contextless" (inst: ^Instruction, form: ^Encoding) -> bool {
	for k in 0 ..< len(form.enc) {
		op := &inst.ops[k]
		if op.kind != .MEMORY { continue }
		m := op.mem.mode
		// `mem_imm` leaves index at Register(0), which has no class; R0 is
		// REG_GPR | 0 and a real index.
		has_index := reg_class(op.mem.index) == REG_GPR
		switch form.enc[k] {
		case .NONE, .IMPL, .RD:
			// not a memory slot; the shape check keeps addresses out of it
		case .RN_A32:
			if m != .OFFSET || has_index { return false }
		case .RM_A32, .RS_A32, .RT_A32, .RT2_A32, .RA_A32, .RDLO_A32, .RDHI_A32, .RD_T32:
			// not a memory slot; the shape check keeps addresses out of it
		case .RN_T32:
			if m != .OFFSET || has_index { return false }
		case .RM_T32, .RT_T32, .RT2_T32, .RA_T32, .RD_T16_LO, .RM_T16_LO, .RN_T16_LO,
		     .RD_T16_HI, .RM_T16_HI, .RM_T16_8_6, .RD_T16_10_8, .RD_T16_LO_AGAIN,
		     .RD_T16_HI_AGAIN, .IMM3_T16, .IMM8_T16, .IMM5_T16_SHIFT, .IMM5_T16_SHIFT_32,
		     .IMM7_T16_SCALED4, .IMM8_T16_SCALED4, .IMM6_T16, .IMM4_T16_HINT, .IT_FIRSTCOND,
		     .IT_MASK_FIELD, .SETEND_ENDIAN_T16, .SETPAN_IMM_T16, .CPS_IFLAGS_T16:
			// not a memory slot; the shape check keeps addresses out of it
		case .MEM_T16_IMM5_W, .MEM_T16_IMM5_B, .MEM_T16_IMM5_H:
			if m != .OFFSET || has_index { return false }
		case .MEM_T16_REG:
			if m != .OFFSET || !has_index { return false }
		case .MEM_T16_SP_IMM8:
			if m != .OFFSET || has_index { return false }
		case .MEM_T16_LITERAL:
			return false    // a literal slot takes a label, not an address
		case .REL_T16_ADR, .T16_REG_LIST, .T16_REG_LIST_LR, .T16_REG_LIST_PC,
		     .RM_T32_ROTATED, .RM_T32_TWICE, .RN_T32_SAT, .T32_IMM12, .T32_IMM16,
		     .T32_IMM_SHIFT, .T32_IMM_SHIFT_32, .SAT16_IMM4_T32, .SAT16_IMM4_U_T32,
		     .BFI_MSB_T32, .BFX_WIDTH_T32, .T32_IMM4_IMM12, .T32_IMM4_SMC, .T32_IMM8,
		     .CPS_IFLAGS_T32, .CPS_MODE_T32, .MRS_SPEC_REG_T32, .MSR_FIELDS_T32, .SYSM_T32,
		     .MSR_SYSM_T32:
			// not a memory slot; the shape check keeps addresses out of it
		case .MEM_T32_IMM12, .MEM_T32_IMM8_NEG:
			if m != .OFFSET || has_index { return false }
		case .MEM_T32_IMM8_PRE:
			if m != .PRE_INDEX || has_index { return false }
		case .MEM_T32_IMM8_POST:
			if m != .POST_INDEX || has_index { return false }
		case .MEM_T32_IMM8_POS:
			if m != .OFFSET || has_index { return false }
		case .MEM_T32_REG:
			if m != .OFFSET || !has_index { return false }
		case .MEM_T32_LITERAL, .MEM_T32_LITERAL_DUAL:
			return false    // a literal slot takes a label, not an address
		case .MEM_T32_EXCLUSIVE:
			if m != .OFFSET || has_index { return false }
		case .MEM_T32_TABLE_B, .MEM_T32_TABLE_H:
			if m != .OFFSET || !has_index { return false }
		case .RD_T32_STATUS, .T32_REG_LIST, .REL_T32_ADR_ADD, .REL_T32_ADR_SUB,
		     .BRANCH_BLX_T32, .RN_T32_ZR, .RM_T32_ZR, .COND_T32_FCOND, .BANKED_MRS_T32,
		     .BANKED_MSR_T32, .LOB_FORWARD, .LOB_BACKWARD, .A32_IMM_MOD, .T32_IMM_MOD,
		     .A32_IMM12_ROT, .A32_IMM12, .A32_IMM_SHIFT, .A32_IMM_SHIFT_32, .A32_SHIFT_TYPE,
		     .A32_RS_SHIFT, .A32_IMM24, .A32_IMM4, .A32_IMM4_ROTATE, .A32_IMM5_LSB,
		     .A32_IMM5_W, .A32_COND_FIELD, .A32_REG_LIST, .VD_S, .VN_S, .VM_S, .VD_D, .VN_D,
		     .VM_D, .VD_Q, .VN_Q, .VM_Q, .NEON_VM_SCALAR16, .NEON_VM_SCALAR32, .VMOV_LANE_8,
		     .VMOV_LANE_16, .VMOV_LANE_32, .MVE_ROT_HCADD, .MVE_ROT_CMLA, .VN_Q_MVE,
		     .VM_Q_MVE, .VFP_IMM8, .VM_S_PLUS1, .DBG_OPTION, .MRS_SPEC_REG, .VFP_SPEC_REG,
		     .SETEND_ENDIAN, .IMPL_SP, .IMPL_PC, .IMPL_LR, .IMPL_R12, .MODE_IMM5,
		     .RN_A32_WB, .NEON_LANE_VN_32, .NEON_IMM8_ABCDEFGH, .NEON_CMODE, .NEON_OP_BIT,
		     .VFP_S_LIST, .VFP_D_LIST, .VFP_DX_LIST, .VD_S_AGAIN, .VD_D_AGAIN, .RT_VMRS,
		     .NEON_VN_TABLE_1, .NEON_VN_TABLE_2, .NEON_VN_TABLE_3, .NEON_VN_TABLE_4,
		     .NEON_VM_SCALAR_16, .NEON_VM_SCALAR_32, .NEON_VDUP_LANE_8, .NEON_VDUP_LANE_16,
		     .NEON_VDUP_LANE_32, .NEON_D_LIST_1, .NEON_D_LIST_2, .NEON_D_LIST_3,
		     .NEON_D_LIST_4, .NEON_D_LIST_2X, .NEON_D_LIST_3X, .NEON_D_LIST_4X,
		     .NEON_D_LIST_ALL, .NEON_D_LIST_ALL_2, .NEON_D_LIST_ALL_3, .NEON_D_LIST_ALL_4,
		     .NEON_LANE_D_8, .NEON_LANE_D_16, .NEON_LANE_D_32, .NEON_LANE_D_8_2,
		     .NEON_LANE_D_16_2, .NEON_LANE_D_32_2, .NEON_LANE_D_8_3, .NEON_LANE_D_16_3,
		     .NEON_LANE_D_32_3, .NEON_LANE_D_8_4, .NEON_LANE_D_16_4, .NEON_LANE_D_32_4:
			// not a memory slot; the shape check keeps addresses out of it
		case .MEM_IMM12_OFFSET:
			if m != .OFFSET || has_index { return false }
		case .RT2_A32_PAIR:
			// not a memory slot; the shape check keeps addresses out of it
		case .MEM_IMM8_PRE_INDEX:
			if m != .PRE_INDEX || has_index { return false }
		case .MEM_IMM8_POST_INDEX:
			if m != .POST_INDEX || has_index { return false }
		case .MEM_IMM8_OFFSET, .MEM_IMM8_SCALED4:
			if m != .OFFSET || has_index { return false }
		case .MEM_IMM8_SCALED4_PRE:
			if m != .PRE_INDEX || has_index { return false }
		case .MEM_IMM8_SCALED4_POST:
			if m != .POST_INDEX || has_index { return false }
		case .MEM_IMM8_SCALED2:
			if m != .OFFSET || has_index { return false }
		case .MEM_REG_OFFSET:
			if m != .OFFSET || !has_index { return false }
		case .MEM_PRE_INDEX:
			if m != .PRE_INDEX || has_index { return false }
		case .MEM_POST_INDEX:
			if m != .POST_INDEX || has_index { return false }
		case .MEM_LITERAL:
			return false    // a literal slot takes a label, not an address
		case .MEM_DOUBLEREG:
			if m != .OFFSET || !has_index { return false }
		case .COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .COPROC_OPC1_MCR, .COPROC_OPC1_FIELD,
		     .COPROC_OPC2_FIELD, .COPROC_CRN_FIELD, .COPROC_CRM_FIELD, .COPROC_OPC_MCRR,
		     .BRANCH_24, .BRANCH_24_T32, .BRANCH_20_T32, .BRANCH_11_T16, .BRANCH_8_T16,
		     .BRANCH_CBZ, .BF_BOFF, .BF_BLOC, .BF_RM, .BFCSEL_COND, .PSR_FIELD_MASK,
		     .SYSM_FIELD, .BARRIER_TYPE, .CPS_IFLAGS, .HINT_FIELD, .VFP_FBITS, .NEON_SHLL_8,
		     .NEON_SHLL_16, .NEON_SHLL_32, .NEON_ROT_2, .NEON_ROT_4, .NEON_ROT_4_HI,
		     .SAT_IMM5, .SAT_IMM5_T32, .SAT_IMM5_U, .SAT_IMM5_U_T32, .BFX_WIDTH, .BFI_MSB,
		     .BFI_LSB, .BFI_LSB_T32, .NEON_SHIFT_IMM6, .NEON_SHIFT_IMM3, .NEON_SHIFT_IMM4,
		     .NEON_SHIFT_IMM5, .QD_MVE, .QN_MVE, .QM_MVE, .MVE_RDA_EVEN, .MVE_RDALO,
		     .MVE_RDAHI, .MVE_SIZE_FIELD, .MVE_VPT_MASK_FIELD, .MVE_LOOP_IMM,
		     .CDE_COPROC_FIELD, .CDE_IMM_FIELD, .CDE_ACC_FIELD, .V8M_TT_AT_BITS:
			// not a memory slot; the shape check keeps addresses out of it
		}
	}
	return true
}

@(private)
encoding_matches_inline :: #force_inline proc "contextless" (inst: ^Instruction, form: ^Encoding) -> bool {
	return  operand_matches_inline(&inst.ops[0], form.ops[0], form.enc[0]) &&
	        operand_matches_inline(&inst.ops[1], form.ops[1], form.enc[1]) &&
	        operand_matches_inline(&inst.ops[2], form.ops[2], form.enc[2]) &&
	        operand_matches_inline(&inst.ops[3], form.ops[3], form.enc[3]) &&
	        operand_matches_inline(&inst.ops[4], form.ops[4], form.enc[4]) &&
	        operand_matches_inline(&inst.ops[5], form.ops[5], form.enc[5])
}

// Shape is not enough to pick a Thumb form: `add r0, r1, r2` and `add r8, r9,
// r10` have the same shape, and only one of them fits in sixteen bits. This
// checks each operand's value against the field it would be packed into, so a
// narrow form is chosen only when packing it loses nothing.
@(private)
operands_fit :: proc "contextless" (inst: ^Instruction, form: ^Encoding) -> bool {
	for k in 0 ..< len(form.enc) {
		op := &inst.ops[k]
		if !operand_fits(op, form.ops[k], form.enc[k], inst, form) {
			return false
		}
	}
	return true
}

@(private="file")
operand_fits :: proc "contextless" (op: ^Operand, ot: Operand_Type, enc: Operand_Encoding, inst: ^Instruction, form: ^Encoding) -> bool {
	if ot == .GPR_LOW && (op.kind != .REGISTER || reg_hw(op.reg) > 7) {
		return false
	}
	// A plain register slot has no room for a shift; a register that names
	// one belongs in a GPR_SHIFTED slot, or in one of the two encodings that
	// take a register with a rotation or a saturating shift.
	if (ot == .GPR || ot == .GPR_LOW || ot == .GPR_NOPC || ot == .GPR_NOSP) &&
	   op.kind == .REGISTER && is_shifted(op.shift_type, op.shift_amt) &&
	   enc != .RM_T32_ROTATED && enc != .RN_T32_SAT {
		return false
	}
	low_base :: proc "contextless" (m: Memory) -> bool {
		return is_gpr(m.base) && reg_hw(m.base) < 8
	}
	positive :: proc "contextless" (m: Memory) -> bool {
		return m.mode == .OFFSET && m.sign >= 0 && m.disp >= 0 && reg_class(m.index) != REG_GPR
	}
	scaled :: proc "contextless" (v: i64, scale: i64, limit: i64) -> bool {
		return v >= 0 && v % scale == 0 && v / scale <= limit
	}
	low_register :: proc "contextless" (op: ^Operand) -> bool {
		return op.kind == .REGISTER && reg_hw(op.reg) < 8
	}
	small_offset :: proc "contextless" (op: ^Operand, scale: i64) -> bool {
		return op.kind == .MEMORY && low_base(op.mem) && positive(op.mem) && scaled(i64(op.mem.disp), scale, 31)
	}
	low_register_offset :: proc "contextless" (op: ^Operand) -> bool {
		m := op.mem
		return op.kind == .MEMORY && low_base(m) && m.mode == .OFFSET && m.sign >= 0 &&
		       is_gpr(m.index) && reg_hw(m.index) < 8 && !is_shifted(m.shift_type, m.shift_amt)
	}
	modified_immediate_representable :: proc "contextless" (op: ^Operand, form: ^Encoding) -> bool {
		cmode := (form.bits >> 8) & 0xF
		_, representable := encode_neon_modimm_for(neon_modimm_value(op, cmode), cmode, (form.bits >> 5) & 1)
		return representable
	}
	// An immediate offset of at most `limit` either way, in steps of `scale`.
	address_within :: proc "contextless" (op: ^Operand, limit: i32, scale: i32) -> bool {
		if op.kind != .MEMORY { return false }
		d := op.mem.disp
		magnitude := d < 0 ? -d : d
		return magnitude <= limit && magnitude % scale == 0
	}
	// A register offset, shifted left by at most `limit`, and added.
	register_offset_shifted :: proc "contextless" (op: ^Operand, limit: u8) -> bool {
		m := op.mem
		if op.kind != .MEMORY || m.sign < 0 { return false }
		return !is_shifted(m.shift_type, m.shift_amt) || (m.shift_type == .LSL && m.shift_amt <= limit)
	}
	// Every encoding has a say. Most add nothing to the shape check but this:
	// a memory slot takes an address and a literal slot a label, and neither
	// takes the other. The 16-bit slots narrow registers and immediates to
	// what fits; the literal slots take only a label (NONE is the zero the
	// syntax names and no field holds, the #0 of RSBS Rd, Rn, #0).
	switch enc {
	case .NONE:
		return ot != .IMM || (op.kind == .IMMEDIATE && op.immediate == 0)
	case .IMPL, .RD, .RN_A32, .RM_A32, .RS_A32, .RT_A32, .RT2_A32, .RA_A32, .RDLO_A32,
	     .RDHI_A32, .RD_T32, .RN_T32, .RM_T32, .RT_T32, .RT2_T32, .RA_T32:
		return !(ot == .MEM && op.kind == .RELATIVE)
	case .RD_T16_LO, .RM_T16_LO, .RN_T16_LO:
		return low_register(op)
	case .RD_T16_HI, .RM_T16_HI:
		return !(ot == .MEM && op.kind == .RELATIVE)
	case .RM_T16_8_6, .RD_T16_10_8:
		return low_register(op)
	case .RD_T16_LO_AGAIN, .RD_T16_HI_AGAIN:
		return op.kind == .REGISTER && op.reg == inst.ops[0].reg
	case .IMM3_T16:
		return scaled(op.immediate, 1, 7)
	case .IMM8_T16:
		return scaled(op.immediate, 1, 255)
	case .IMM5_T16_SHIFT:
		return scaled(op.immediate, 1, 31)
	case .IMM5_T16_SHIFT_32:
		return op.immediate >= 1 && op.immediate <= 32
	case .IMM7_T16_SCALED4:
		return scaled(op.immediate, 4, 127)
	case .IMM8_T16_SCALED4:
		return scaled(op.immediate, 4, 255)
	case .IMM6_T16:
		return scaled(op.immediate, 1, 63)
	case .IMM4_T16_HINT:
		return scaled(op.immediate, 1, 15)
	case .IT_FIRSTCOND, .IT_MASK_FIELD, .SETEND_ENDIAN_T16, .SETPAN_IMM_T16,
	     .CPS_IFLAGS_T16:
		return !(ot == .MEM && op.kind == .RELATIVE)
	case .MEM_T16_IMM5_W:
		return small_offset(op, 4)
	case .MEM_T16_IMM5_B:
		return small_offset(op, 1)
	case .MEM_T16_IMM5_H:
		return small_offset(op, 2)
	case .MEM_T16_REG:
		return low_register_offset(op)
	case .MEM_T16_SP_IMM8:
		return op.kind == .MEMORY && op.mem.base == SP && positive(op.mem) && scaled(i64(op.mem.disp), 4, 255)
	case .MEM_T16_LITERAL:
		return op.kind == .RELATIVE
	case .REL_T16_ADR:
		return !(ot == .MEM && op.kind == .RELATIVE)
	case .T16_REG_LIST:
		return op.kind == .REG_LIST && u16(op.immediate) & 0xFF00 == 0
	case .T16_REG_LIST_LR:
		return op.kind == .REG_LIST && u16(op.immediate) & 0xBF00 == 0
	case .T16_REG_LIST_PC:
		return op.kind == .REG_LIST && u16(op.immediate) & 0x7F00 == 0
	case .RM_T32_ROTATED, .RM_T32_TWICE, .RN_T32_SAT, .T32_IMM12, .T32_IMM16,
	     .T32_IMM_SHIFT, .T32_IMM_SHIFT_32, .SAT16_IMM4_T32, .SAT16_IMM4_U_T32,
	     .BFI_MSB_T32, .BFX_WIDTH_T32, .T32_IMM4_IMM12, .T32_IMM4_SMC, .T32_IMM8,
	     .CPS_IFLAGS_T32, .CPS_MODE_T32, .MRS_SPEC_REG_T32, .MSR_FIELDS_T32, .SYSM_T32,
	     .MSR_SYSM_T32:
		return !(ot == .MEM && op.kind == .RELATIVE)
	case .MEM_T32_IMM12:
		return op.kind == .MEMORY && op.mem.sign >= 0 && address_within(op, 4095, 1)
	case .MEM_T32_IMM8_NEG:
		return op.kind == .MEMORY && (op.mem.disp < 0 || op.mem.sign < 0) && address_within(op, 255, 1)
	case .MEM_T32_IMM8_PRE:
		return address_within(op, 255, 1)
	case .MEM_T32_IMM8_POST:
		return address_within(op, 255, 1)
	case .MEM_T32_IMM8_POS:
		return op.kind == .MEMORY && op.mem.sign >= 0 && address_within(op, 255, 1)
	case .MEM_T32_REG:
		return register_offset_shifted(op, 3)
	case .MEM_T32_LITERAL, .MEM_T32_LITERAL_DUAL:
		return op.kind == .RELATIVE
	case .MEM_T32_EXCLUSIVE:
		return op.kind == .MEMORY && op.mem.sign >= 0 && address_within(op, 1020, 4)
	case .MEM_T32_TABLE_B:
		return op.kind == .MEMORY && !is_shifted(op.mem.shift_type, op.mem.shift_amt)
	case .MEM_T32_TABLE_H:
		return op.kind == .MEMORY && op.mem.shift_type == .LSL && op.mem.shift_amt == 1
	case .RD_T32_STATUS, .T32_REG_LIST, .REL_T32_ADR_ADD, .REL_T32_ADR_SUB,
	     .BRANCH_BLX_T32, .RN_T32_ZR, .RM_T32_ZR, .COND_T32_FCOND, .BANKED_MRS_T32,
	     .BANKED_MSR_T32, .LOB_FORWARD, .LOB_BACKWARD, .A32_IMM_MOD, .T32_IMM_MOD,
	     .A32_IMM12_ROT, .A32_IMM12, .A32_IMM_SHIFT, .A32_IMM_SHIFT_32, .A32_SHIFT_TYPE,
	     .A32_RS_SHIFT, .A32_IMM24, .A32_IMM4, .A32_IMM4_ROTATE, .A32_IMM5_LSB,
	     .A32_IMM5_W, .A32_COND_FIELD, .A32_REG_LIST, .VD_S, .VN_S, .VM_S, .VD_D, .VN_D,
	     .VM_D, .VD_Q, .VN_Q, .VM_Q, .NEON_VM_SCALAR16, .NEON_VM_SCALAR32, .VMOV_LANE_8,
	     .VMOV_LANE_16, .VMOV_LANE_32, .MVE_ROT_HCADD, .MVE_ROT_CMLA, .VN_Q_MVE,
	     .VM_Q_MVE, .VFP_IMM8, .VM_S_PLUS1, .DBG_OPTION, .MRS_SPEC_REG, .VFP_SPEC_REG,
	     .SETEND_ENDIAN:
		return !(ot == .MEM && op.kind == .RELATIVE)
	case .IMPL_SP:
		return op.kind == .REGISTER && op.reg == SP
	case .IMPL_PC:
		return op.kind == .REGISTER && op.reg == PC
	case .IMPL_LR:
		return op.kind == .REGISTER && op.reg == LR
	case .IMPL_R12:
		return op.kind == .REGISTER && op.reg == R12
	case .MODE_IMM5, .RN_A32_WB, .NEON_LANE_VN_32:
		return !(ot == .MEM && op.kind == .RELATIVE)
	case .NEON_IMM8_ABCDEFGH:
		return modified_immediate_representable(op, form)
	case .NEON_CMODE, .NEON_OP_BIT, .VFP_S_LIST, .VFP_D_LIST, .VFP_DX_LIST:
		return !(ot == .MEM && op.kind == .RELATIVE)
	case .VD_S_AGAIN, .VD_D_AGAIN:
		return op.kind == .REGISTER && op.reg == inst.ops[0].reg
	case .RT_VMRS, .NEON_VN_TABLE_1, .NEON_VN_TABLE_2, .NEON_VN_TABLE_3,
	     .NEON_VN_TABLE_4, .NEON_VM_SCALAR_16, .NEON_VM_SCALAR_32, .NEON_VDUP_LANE_8,
	     .NEON_VDUP_LANE_16, .NEON_VDUP_LANE_32, .NEON_D_LIST_1, .NEON_D_LIST_2,
	     .NEON_D_LIST_3, .NEON_D_LIST_4, .NEON_D_LIST_2X, .NEON_D_LIST_3X,
	     .NEON_D_LIST_4X, .NEON_D_LIST_ALL, .NEON_D_LIST_ALL_2, .NEON_D_LIST_ALL_3,
	     .NEON_D_LIST_ALL_4, .NEON_LANE_D_8, .NEON_LANE_D_16, .NEON_LANE_D_32,
	     .NEON_LANE_D_8_2, .NEON_LANE_D_16_2, .NEON_LANE_D_32_2, .NEON_LANE_D_8_3,
	     .NEON_LANE_D_16_3, .NEON_LANE_D_32_3, .NEON_LANE_D_8_4, .NEON_LANE_D_16_4,
	     .NEON_LANE_D_32_4:
		return !(ot == .MEM && op.kind == .RELATIVE)
	case .MEM_IMM12_OFFSET:
		return address_within(op, 4095, 1)
	case .RT2_A32_PAIR:
		return !(ot == .MEM && op.kind == .RELATIVE)
	case .MEM_IMM8_PRE_INDEX:
		return address_within(op, 255, 1)
	case .MEM_IMM8_POST_INDEX:
		return address_within(op, 255, 1)
	case .MEM_IMM8_OFFSET:
		return address_within(op, 255, 1)
	case .MEM_IMM8_SCALED4:
		return address_within(op, 1020, 4)
	case .MEM_IMM8_SCALED4_PRE:
		return address_within(op, 1020, 4)
	case .MEM_IMM8_SCALED4_POST:
		return address_within(op, 1020, 4)
	case .MEM_IMM8_SCALED2:
		return address_within(op, 510, 2)
	case .MEM_REG_OFFSET:
		return !(ot == .MEM && op.kind == .RELATIVE)
	case .MEM_PRE_INDEX:
		return address_within(op, 4095, 1)
	case .MEM_POST_INDEX:
		return address_within(op, 4095, 1)
	case .MEM_LITERAL:
		return op.kind == .RELATIVE
	case .MEM_DOUBLEREG, .COPROC_NUM_FIELD, .COPROC_CRD_FIELD, .COPROC_OPC1_MCR,
	     .COPROC_OPC1_FIELD, .COPROC_OPC2_FIELD, .COPROC_CRN_FIELD, .COPROC_CRM_FIELD,
	     .COPROC_OPC_MCRR, .BRANCH_24, .BRANCH_24_T32, .BRANCH_20_T32, .BRANCH_11_T16,
	     .BRANCH_8_T16, .BRANCH_CBZ, .BF_BOFF, .BF_BLOC, .BF_RM, .BFCSEL_COND,
	     .PSR_FIELD_MASK, .SYSM_FIELD, .BARRIER_TYPE, .CPS_IFLAGS, .HINT_FIELD, .VFP_FBITS,
	     .NEON_SHLL_8, .NEON_SHLL_16, .NEON_SHLL_32, .NEON_ROT_2, .NEON_ROT_4,
	     .NEON_ROT_4_HI, .SAT_IMM5, .SAT_IMM5_T32, .SAT_IMM5_U, .SAT_IMM5_U_T32, .BFX_WIDTH,
	     .BFI_MSB, .BFI_LSB, .BFI_LSB_T32, .NEON_SHIFT_IMM6, .NEON_SHIFT_IMM3,
	     .NEON_SHIFT_IMM4, .NEON_SHIFT_IMM5, .QD_MVE, .QN_MVE, .QM_MVE:
		return !(ot == .MEM && op.kind == .RELATIVE)
	case .MVE_RDA_EVEN, .MVE_RDALO:
		return op.kind == .REGISTER && reg_hw(op.reg) % 2 == 0 && reg_hw(op.reg) < 14
	case .MVE_RDAHI:
		return op.kind == .REGISTER && reg_hw(op.reg) % 2 == 1 && reg_hw(op.reg) < 14
	case .MVE_SIZE_FIELD, .MVE_VPT_MASK_FIELD, .MVE_LOOP_IMM, .CDE_COPROC_FIELD,
	     .CDE_IMM_FIELD, .CDE_ACC_FIELD, .V8M_TT_AT_BITS:
		return !(ot == .MEM && op.kind == .RELATIVE)
	}
	return false
}

@(private="file")
operand_matches_inline :: #force_inline proc "contextless" (op: ^Operand, ot: Operand_Type, enc: Operand_Encoding) -> bool {
	// A modified immediate reaches an immediate slot as an expanded bit
	// pattern or a float, so all three kinds are the same slot's shape.
	immediate :: proc "contextless" (op: ^Operand) -> bool {
		return op.kind == .IMMEDIATE || op.kind == .HEX_IMMEDIATE || op.kind == .FLOAT_IMMEDIATE
	}
	switch ot {
	case .NONE:
		return op.kind == .NONE
	case .GPR, .GPR_NOPC, .GPR_NOSP, .GPR_LOW:
		return op.kind == .REGISTER && is_gpr(op.reg)
	case .GPR_SHIFTED:
		// An unshifted register is the shifted register with no shift:
		// `add r0, r1, r2` is the same form as `add r0, r1, r2, lsl #3`.
		return op.kind == .REGISTER && is_gpr(op.reg) && !is_rsr_shift_type(op.shift_type)
	case .GPR_RSR:
		return op.kind == .REGISTER && is_gpr(op.reg) && is_rsr_shift_type(op.shift_type)
	case .GPR_LIST:
		return op.kind == .REG_LIST
	case .GPR_ZR:
		return op.kind == .REGISTER && (is_gpr(op.reg) || op.reg == ZR)
	case .SPR:
		return op.kind == .REGISTER && is_spr(op.reg)
	case .DPR:
		return op.kind == .REGISTER && is_dpr(op.reg)
	case .QPR:
		return op.kind == .REGISTER && is_qpr(op.reg)
	case .SPR_LIST:
		return op.kind == .REGISTER && is_spr(op.reg)
	case .DPR_LIST:
		if op.kind != .REGISTER || !is_dpr(op.reg) { return false }
		// Forms whose run length is a fixed pattern bit are told apart only
		// by that length -- {d0} and {d0, d1} are different instructions.
		if enc == .NEON_VN_TABLE_1 { return op.list.count == 1 }
		if enc == .NEON_VN_TABLE_2 { return op.list.count == 2 }
		if enc == .NEON_VN_TABLE_3 { return op.list.count == 3 }
		if enc == .NEON_VN_TABLE_4 { return op.list.count == 4 }
		return true
	case .SPR_ELEM:
		return op.kind == .REGISTER && is_spr(op.reg)
	case .DPR_ELEM:
		if op.kind != .REGISTER || !is_dpr(op.reg) { return false }
		// A by-scalar multiplier names a lane, and how far the register and
		// lane numbers reach depends on how they share the field.
		if enc == .NEON_VM_SCALAR_16 { return op.has_lane && reg_hw(op.reg) < 8  && op.lane < 4 }
		if enc == .NEON_VM_SCALAR_32 { return op.has_lane && reg_hw(op.reg) < 16 && op.lane < 2 }
		if enc == .NEON_VDUP_LANE_8  { return op.has_lane && op.lane < 8 }
		if enc == .NEON_VDUP_LANE_16 { return op.has_lane && op.lane < 4 }
		if enc == .NEON_VDUP_LANE_32 { return op.has_lane && op.lane < 2 }
		return true
	case .QPR_ELEM:
		return op.kind == .REGISTER && is_qpr(op.reg)
	case .IMM, .IMM_MOD, .IMM_T32_MOD, .IMM16_LO_HI, .IMM12, .IMM5, .IMM5_W,
	     .IMM4, .IMM4_SAT, .IMM8, .IMM3, .IMM_HINT, .IMM_BARRIER:
		return immediate(op)
	case .IMM_ENDIAN:
		return op.kind == .REGISTER
	case .IMM_IFLAGS:
		// CPS names its masks as letters, which decode as a token.
		return op.kind == .IMMEDIATE || (op.kind == .REGISTER && reg_class(op.reg) == REG_IFLAGS)
	case .IMM_BANKED, .IMM_SYSM, .IMM_COPROC, .IMM_COPROC_OP, .NEON_IMM:
		return immediate(op)
	case .REL24, .REL24_T32, .REL20, .REL11, .REL8, .REL_LDR_LITERAL, .REL_BF:
		return op.kind == .RELATIVE
	case .COND:
		// IT's first condition is a number; CSEL's condition is a token.
		return op.kind == .IMMEDIATE || (op.kind == .REGISTER && reg_class(op.reg) == REG_COND)
	case .MEM:
		// Most MEM forms expect a Memory operand, but PC-relative literal
		// loads decode to a RELATIVE operand so the branch-resolution pass
		// can patch the label offset. Accept both; operands_fit tells them
		// apart.
		return op.kind == .MEMORY || op.kind == .RELATIVE
	case .COPROC_REG, .COPROC_NUM:
		return op.kind == .REGISTER || op.kind == .IMMEDIATE
	case .PSR_FIELD:
		// APSR, SPSR and the endian tokens are named registers in the syntax
		// even where no field encodes them.
		return op.kind == .IMMEDIATE || op.kind == .REGISTER
	case .VPR, .QPR_MVE:
		return op.kind == .REGISTER && is_qpr(op.reg)
	case .QPR_MVE_LIST:
		return op.kind == .REG_LIST || (op.kind == .REGISTER && is_qpr(op.reg))
	case .MVE_VPT_MASK, .MVE_VCTP_SIZE, .MVE_LOOP_TGT, .CDE_COPROC, .CDE_IMM, .CDE_VFP_REG:
		return op.kind == .IMMEDIATE || op.kind == .REGISTER || op.kind == .RELATIVE
	}
	return false
}

// =============================================================================
// Operand packer
// =============================================================================

@(private="file")
pack_operand_inline :: #force_inline proc(
	op:       ^Operand,
	enc:      Operand_Encoding,
	pc:       u32,
	inst_idx: u16,
	relocs:   ^[dynamic]Relocation,
	form:     ^Encoding,
	// BFI's msb is lsb + width - 1, so packing it needs a sibling operand.
	inst:     ^Instruction,
) -> u32 {
	switch enc {
	case .NONE, .IMPL:
		return 0

	// ---- A32 GPR slots ----
	case .RD:                  return (u32(reg_hw(op.reg)) & 0xF) << 12
	case .RN_A32:              return (u32(reg_hw(op.reg)) & 0xF) << 16
	case .RM_A32:
		reg := u32(reg_hw(op.reg)) & 0xF
		st := op.shift_type
		// Register-shifted register: type in 6..5, Rs in 11..8, bit 4 = 1.
		if is_rsr_shift_type(st) {
			rs := u32(op.shift_amt) & 0xF
			return reg | (rs << 8) | (rsr_type_bits(st) << 5) | (u32(1) << 4)
		}
		// Imm-shift / RRX / naked register.
		if st == .RRX  { return reg | (u32(Shift_Type.ROR) & 0x3) << 5 }
		if st == .NONE { return reg }
		if op.shift_amt == 0 && st == .LSL { return reg }  // LSL #0 == naked
		amt := u32(op.shift_amt) & 0x1F
		return reg | (amt << 7) | (u32(st) & 0x3) << 5
	case .RS_A32:              return (u32(reg_hw(op.reg)) & 0xF) << 8
	case .RT_A32:              return (u32(reg_hw(op.reg)) & 0xF) << 12
	case .RT2_A32:             return (u32(reg_hw(op.reg)) & 0xF) << 16
	case .RA_A32:              return (u32(reg_hw(op.reg)) & 0xF) << 12
	case .RDLO_A32:            return (u32(reg_hw(op.reg)) & 0xF) << 12
	case .RDHI_A32:            return (u32(reg_hw(op.reg)) & 0xF) << 16

	// ---- T32 GPR slots (bits 11:8 of high halfword for Rd, etc.) ----
	case .RD_T32:              return (u32(reg_hw(op.reg)) & 0xF) << 8
	case .RN_T32:              return (u32(reg_hw(op.reg)) & 0xF) << 16
	case .RM_T32:
		reg := u32(reg_hw(op.reg)) & 0xF
		// imm3:imm2 around Rd, the type at 5:4. LSR/ASR #32 and RRX are
		// written with a zero amount, as in A32.
		st := op.shift_type
		if st == .NONE { return reg }
		if st == .RRX { return reg | u32(Shift_Type.ROR) << 4 }
		amount := u32(op.shift_amt) & 0x1F
		return reg | (u32(st) & 0x3) << 4 | t32_split_shift(amount)
	case .RT_T32:              return (u32(reg_hw(op.reg)) & 0xF) << 12
	case .RT2_T32:             return (u32(reg_hw(op.reg)) & 0xF) << 8
	case .RA_T32:              return (u32(reg_hw(op.reg)) & 0xF) << 12

	// ---- T16 GPR slots ----
	case .RD_T16_LO:           return u32(reg_hw(op.reg)) & 0x7
	case .RM_T16_LO:           return (u32(reg_hw(op.reg)) & 0x7) << 3
	case .RN_T16_LO:           return (u32(reg_hw(op.reg)) & 0x7) << 3
	case .RD_T16_HI:
		// hi-reg form: rd[3] at bit 7, rd[2:0] at bits 2:0
		v := u32(reg_hw(op.reg)) & 0xF
		return (v & 0x7) | ((v >> 3) & 1) << 7
	case .RM_T16_HI:
		// hi-reg form: rm at bits 6:3 (4 bits)
		return (u32(reg_hw(op.reg)) & 0xF) << 3
	case .RM_T16_8_6:          return (u32(reg_hw(op.reg)) & 0x7) << 6
	case .RD_T16_10_8:         return (u32(reg_hw(op.reg)) & 0x7) << 8
	case .RD_T16_LO_AGAIN, .RD_T16_HI_AGAIN:
		return 0    // the field already holds it, from the first mention

	// ---- T16 immediates ----
	case .IMM3_T16:          return (u32(op.immediate) & 0x7) << 6
	case .IMM8_T16:          return  u32(op.immediate) & 0xFF
	case .IMM5_T16_SHIFT, .IMM5_T16_SHIFT_32:
		return (u32(op.immediate) & 0x1F) << 6    // 32 wraps to 0, which is how it is written
	case .IMM7_T16_SCALED4:  return (u32(op.immediate) / 4) & 0x7F
	case .IMM8_T16_SCALED4:  return (u32(op.immediate) / 4) & 0xFF
	case .IMM6_T16:          return  u32(op.immediate) & 0x3F
	case .IMM4_T16_HINT:     return (u32(op.immediate) & 0xF) << 4
	case .IT_FIRSTCOND:      return (u32(op.immediate) & 0xF) << 4
	case .IT_MASK_FIELD:     return  u32(op.immediate) & 0xF
	case .SETEND_ENDIAN_T16: return (u32(reg_hw(op.reg)) & 1) << 3
	case .SETPAN_IMM_T16:    return (u32(op.immediate) & 1) << 3
	case .CPS_IFLAGS_T16:    return  u32(reg_hw(op.reg)) & 0x7

	// ---- T16 memory, lists and PC-relative ----
	case .MEM_T16_IMM5_W:
		return (u32(reg_hw(op.mem.base)) & 0x7) << 3 | ((u32(op.mem.disp) / 4) & 0x1F) << 6
	case .MEM_T16_IMM5_B:
		return (u32(reg_hw(op.mem.base)) & 0x7) << 3 | (u32(op.mem.disp) & 0x1F) << 6
	case .MEM_T16_IMM5_H:
		return (u32(reg_hw(op.mem.base)) & 0x7) << 3 | ((u32(op.mem.disp) / 2) & 0x1F) << 6
	case .MEM_T16_REG:
		return (u32(reg_hw(op.mem.base)) & 0x7) << 3 | (u32(reg_hw(op.mem.index)) & 0x7) << 6
	case .MEM_T16_SP_IMM8:
		return (u32(op.mem.disp) / 4) & 0xFF
	case .MEM_T16_LITERAL:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .LDR_LITERAL_T16, size = 2, inst_idx = inst_idx,
		})
		return 0
	case .REL_T16_ADR:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .ADR_T16, size = 2, inst_idx = inst_idx,
		})
		return 0
	case .T16_REG_LIST:      return  u32(op.immediate) & 0xFF
	case .T16_REG_LIST_LR:   return (u32(op.immediate) & 0xFF) | ((u32(op.immediate) >> 14) & 1) << 8
	case .T16_REG_LIST_PC:   return (u32(op.immediate) & 0xFF) | ((u32(op.immediate) >> 15) & 1) << 8

	// ---- T32 ----
	case .RM_T32_TWICE:
		reg := u32(reg_hw(op.reg)) & 0xF
		return reg << 16 | reg
	case .RM_T32_ROTATED:
		reg := u32(reg_hw(op.reg)) & 0xF
		if op.shift_type != .ROR { return reg }
		return reg | ((u32(op.shift_amt) / 8) & 0x3) << 4
	case .RN_T32_SAT:
		reg := (u32(reg_hw(op.reg)) & 0xF) << 16
		amount := u32(op.shift_amt) & 0x1F    // ASR #32 wraps to the zero that writes it
		switch op.shift_type {
		case .LSL:
			return reg | t32_split_shift(amount)
		case .LSR:
			return reg    // not a saturating shift; operands_fit has refused it
		case .ASR:
			return reg | 1 << 21 | t32_split_shift(amount)
		case .ROR, .RRX, .NONE, .LSL_REG, .LSR_REG, .ASR_REG, .ROR_REG:
			return reg    // likewise
		}
		return reg
	case .T32_IMM12:
		v := u32(op.immediate) & 0xFFF
		return (v >> 11) << 26 | ((v >> 8) & 0x7) << 12 | (v & 0xFF)
	case .T32_IMM16:
		v := u32(op.immediate) & 0xFFFF
		return (v >> 12) << 16 | ((v >> 11) & 1) << 26 | ((v >> 8) & 0x7) << 12 | (v & 0xFF)
	case .T32_IMM_SHIFT, .T32_IMM_SHIFT_32:
		return t32_split_shift(u32(op.immediate) & 0x1F)
	case .T32_IMM4_IMM12:
		v := u32(op.immediate) & 0xFFFF
		return (v >> 12) << 16 | (v & 0xFFF)
	case .T32_IMM4_SMC:      return (u32(op.immediate) & 0xF) << 16
	case .T32_IMM8:          return  u32(op.immediate) & 0xFF
	case .CPS_IFLAGS_T32:    return (u32(reg_hw(op.reg)) & 0x7) << 5
	case .CPS_MODE_T32:      return  u32(op.immediate) & 0x1F
	case .MRS_SPEC_REG_T32:  return (u32(reg_hw(op.reg)) >> 1 & 1) << 20
	case .MSR_FIELDS_T32:
		hw := u32(reg_hw(op.reg))
		return ((hw >> 4) & 1) << 20 | (hw & 0xF) << 8
	case .SYSM_T32:          return  u32(reg_hw(op.reg)) & 0xFF
	case .MSR_SYSM_T32:
		hw := u32(reg_hw(op.reg))
		return ((hw >> 8) & 0x3) << 10 | (hw & 0xFF)
	case .MEM_T32_IMM12:
		return (u32(reg_hw(op.mem.base)) & 0xF) << 16 | (u32(op.mem.disp) & 0xFFF)
	case .MEM_T32_IMM8_NEG:
		return (u32(reg_hw(op.mem.base)) & 0xF) << 16 | (u32(abs_i32(op.mem.disp)) & 0xFF)
	case .MEM_T32_IMM8_PRE, .MEM_T32_IMM8_POST:
		m := op.mem
		up: u32 = (m.disp > 0 || (m.disp == 0 && m.sign >= 0)) ? 1 : 0
		return (u32(reg_hw(m.base)) & 0xF) << 16 | up << 9 | (u32(abs_i32(m.disp)) & 0xFF)
	case .MEM_T32_IMM8_POS:
		return (u32(reg_hw(op.mem.base)) & 0xF) << 16 | (u32(op.mem.disp) & 0xFF)
	case .MEM_T32_REG:
		m := op.mem
		return (u32(reg_hw(m.base)) & 0xF) << 16 | (u32(reg_hw(m.index)) & 0xF) | (u32(m.shift_amt) & 0x3) << 4
	case .MEM_T32_LITERAL:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .LDR_LITERAL_T32, size = 4, inst_idx = inst_idx,
		})
		return 0
	case .MEM_T32_LITERAL_DUAL:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .LDRD_LITERAL_T32, size = 4, inst_idx = inst_idx,
		})
		return 0
	case .MEM_T32_EXCLUSIVE:
		return (u32(reg_hw(op.mem.base)) & 0xF) << 16 | ((u32(op.mem.disp) / 4) & 0xFF)
	case .MEM_T32_TABLE_B, .MEM_T32_TABLE_H:
		return (u32(reg_hw(op.mem.base)) & 0xF) << 16 | (u32(reg_hw(op.mem.index)) & 0xF)
	case .RD_T32_STATUS:     return  u32(reg_hw(op.reg)) & 0xF
	case .T32_REG_LIST:      return  u32(op.immediate) & 0xFFFF
	case .REL_T32_ADR_ADD, .REL_T32_ADR_SUB:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .ADR_T32, size = 4, inst_idx = inst_idx,
		})
		return 0
	case .RN_T32_ZR:
		return (op.reg == ZR ? 0xF : u32(reg_hw(op.reg)) & 0xF) << 16
	case .RM_T32_ZR:
		return op.reg == ZR ? 0xF : u32(reg_hw(op.reg)) & 0xF
	case .COND_T32_FCOND:
		return (u32(reg_hw(op.reg)) & 0xF) << 4
	case .BANKED_MRS_T32, .BANKED_MSR_T32:
		number := u32(reg_hw(op.reg))
		m1 := number & 0xF
		return (number >> 5 & 1) << 20 | (number >> 4 & 1) << 4 | (enc == .BANKED_MRS_T32 ? m1 << 16 : m1 << 8)
	case .LOB_FORWARD:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .BRANCH_T32_WLS, size = 4, inst_idx = inst_idx,
		})
		return 0
	case .LOB_BACKWARD:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .BRANCH_T32_LE, size = 4, inst_idx = inst_idx,
		})
		return 0
	case .BRANCH_BLX_T32:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .BLX_T32, size = 4, inst_idx = inst_idx,
		})
		return 0

	// ---- Modified-immediate (A32 + T32) ----
	case .A32_IMM_MOD, .A32_IMM12_ROT:
		// Run the ARM modified-immediate algorithm: find a (rotate, value)
		// pair that represents the full 32-bit constant.
		v, ok := encode_a32_modimm(u32(op.immediate))
		if !ok {
			// Fall back to raw 12-bit if user pre-encoded
			return u32(op.immediate) & 0xFFF
		}
		return v
	case .T32_IMM_MOD:
		// Find i:imm3:imm8 (12 bits) that expand to the user's 32-bit constant.
		f12, ok := encode_t32_modimm(u32(op.immediate))
		if !ok {
			f12 = u32(op.immediate) & 0xFFF
		}
		i_bit := (f12 >> 11) & 1
		imm3  := (f12 >>  8) & 0x7
		imm8  :=  f12        & 0xFF
		return (i_bit << 26) | (imm3 << 12) | imm8

	// ---- A32 immediate field placements ----
	case .A32_IMM12:        return u32(op.immediate) & 0xFFF
	case .A32_IMM_SHIFT:    return (u32(op.immediate) & 0x1F) << 7
	case .A32_IMM_SHIFT_32: return (u32(op.immediate) & 0x1F) << 7   // 32 wraps to 0, which is what encodes it
	case .A32_SHIFT_TYPE:   return (u32(op.immediate) & 0x3)  << 5
	case .A32_RS_SHIFT:     return (u32(reg_hw(op.reg)) & 0xF) << 8
	case .A32_IMM24:
		// Branches: emit relocation
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .BRANCH_A32_24, size = 4, inst_idx = inst_idx,
		})
		return 0
	case .A32_IMM4:         return u32(op.immediate) & 0xF
	case .A32_IMM4_ROTATE:  return (u32(op.immediate) & 0xF) << 8
	case .A32_IMM5_LSB:     return (u32(op.immediate) & 0x1F) << 7
	case .A32_IMM5_W:       return (u32(op.immediate) & 0x1F) << 16
	case .A32_COND_FIELD:   return (u32(op.immediate) & 0xF)  << 28
	case .A32_REG_LIST:     return u32(op.immediate) & 0xFFFF

	// ---- VFP / NEON register-field split encoders --------------------------
	case .VD_S:
		// S<n>: Vd[4:1] at bits 15:12, D bit (bit 0) at bit 22
		n := u32(reg_hw(op.reg)) & 0x1F
		return ((n >> 1) & 0xF) << 12 | (n & 1) << 22
	case .VN_S:
		n := u32(reg_hw(op.reg)) & 0x1F
		return ((n >> 1) & 0xF) << 16 | (n & 1) << 7
	case .VM_S:
		n := u32(reg_hw(op.reg)) & 0x1F
		return ((n >> 1) & 0xF) | (n & 1) << 5
	case .VD_D, .VD_Q:
		// D<n>/Q<n>: Vd[3:0] at bits 15:12, D bit (bit 4) at bit 22
		// For Q-form, Q register index maps to D2*idx, so we use the QPR hw
		// number directly (caller passes Q0..Q15 = hw 0..15).
		n := u32(reg_hw(op.reg)) & 0x1F
		if reg_class(op.reg) == REG_QPR { n = (n & 0xF) * 2 }   // Q<n> -> D<2n>
		return (n & 0xF) << 12 | ((n >> 4) & 1) << 22
	case .VN_D, .VN_Q:
		n := u32(reg_hw(op.reg)) & 0x1F
		if reg_class(op.reg) == REG_QPR { n = (n & 0xF) * 2 }
		return (n & 0xF) << 16 | ((n >> 4) & 1) << 7
	case .VM_D, .VM_Q:
		n := u32(reg_hw(op.reg)) & 0x1F
		if reg_class(op.reg) == REG_QPR { n = (n & 0xF) * 2 }
		return (n & 0xF) | ((n >> 4) & 1) << 5
	case .NEON_VM_SCALAR16:
		// Dm in D0..D7 at bits 2:0; lane = bit5(lane[1]) : bit3(lane[0]).
		return (u32(reg_hw(op.reg)) & 0x7) | ((u32(op.lane) >> 1) & 1) << 5 | (u32(op.lane) & 1) << 3
	case .NEON_VM_SCALAR32:
		// Dm in D0..D15 at bits 3:0; lane = bit5.
		return (u32(reg_hw(op.reg)) & 0xF) | (u32(op.lane) & 1) << 5
	case .VMOV_LANE_8, .VMOV_LANE_16, .VMOV_LANE_32:
		n := u32(reg_hw(op.reg)) & 0x1F                       // Dd
		v := (n & 0xF) << 16 | ((n >> 4) & 1) << 7
		l := u32(op.lane)
		if enc == .VMOV_LANE_8 {
			v |= ((l >> 2) & 1) << 21 | ((l >> 1) & 1) << 6 | (l & 1) << 5
		} else if enc == .VMOV_LANE_16 {
			v |= ((l >> 1) & 1) << 21 | (l & 1) << 6
		} else {
			v |= (l & 1) << 21
		}
		return v
	case .MVE_ROT_HCADD:
		return (u32(op.immediate) == 270 ? 1 : 0) << 12
	case .MVE_ROT_CMLA:
		return ((u32(op.immediate) / 90) & 0x3) << 23
	case .VN_Q_MVE:
		return (u32(reg_hw(op.reg)) & 0x7) << 17
	case .VM_Q_MVE:
		return (u32(reg_hw(op.reg)) & 0x7) << 1
	case .DBG_OPTION:    return u32(op.immediate) & 0xF
	case .MRS_SPEC_REG:  return 0    // the R bit is a fixed bit of the form
	case .VFP_SPEC_REG:  return (u32(reg_hw(op.reg)) & 0xF) << 16
	case .SETEND_ENDIAN: return (u32(reg_hw(op.reg)) & 1) << 9
	case .IMPL_SP, .IMPL_PC, .IMPL_LR, .IMPL_R12:
		return 0
	case .MODE_IMM5:     return u32(op.immediate) & 0x1F
	case .RN_A32_WB:     return (u32(reg_hw(op.reg)) & 0xF) << 16
	case .VM_S_PLUS1:
		return 0    // only the first of the pair is encoded
	case .NEON_LANE_VN_32:
		n := u32(reg_hw(op.reg)) & 0x1F
		return ((n >> 4) & 1) << 7 | (n & 0xF) << 16 | (u32(op.lane) & 1) << 21
	case .VFP_IMM8:
		// Run the VFP 8-bit float encoder; the user supplies the wire-format
		// 32-bit float bit pattern (for F32). The encoder finds the abcdefgh.
		if a, ok := encode_vfp_imm8_f32(u32(op.immediate)); ok {
			return (u32(a) >> 4) << 16 | u32(a) & 0xF
		}
		return u32(op.immediate) & 0xFF
	case .NEON_IMM8_ABCDEFGH:
		// The form fixes cmode and op; only abcdefgh is the operand's, laid
		// out a at 24, bcd at 18:16 and efgh at 3:0.
		cmode := (form.bits >> 8) & 0xF
		op_bit := (form.bits >> 5) & 1
		abcdefgh, _ := encode_neon_modimm_for(neon_modimm_value(op, cmode), cmode, op_bit)
		v := u32(abcdefgh)
		return ((v >> 7) & 1) << 24 | ((v >> 4) & 0x7) << 16 | (v & 0xF)
	case .NEON_CMODE:       return (u32(op.immediate) & 0xF) << 8
	case .NEON_OP_BIT:      return (u32(op.immediate) & 1) << 5

	// ---- VFP/NEON register lists (LDM/STM/PUSH/POP for FP regs) ------------
	case .NEON_D_LIST_1, .NEON_D_LIST_2, .NEON_D_LIST_3, .NEON_D_LIST_4, .NEON_D_LIST_2X, .NEON_D_LIST_3X, .NEON_D_LIST_4X, .NEON_D_LIST_ALL:
		// Only Vd; the count lives in the form's type field.
		n := u32(reg_hw(op.reg)) & 0x1F
		return ((n >> 4) & 1) << 22 | (n & 0xF) << 12
	case .NEON_D_LIST_ALL_2, .NEON_D_LIST_ALL_3, .NEON_D_LIST_ALL_4:
		// Same, plus the spacing, which bit 5 carries.
		n := u32(reg_hw(op.reg)) & 0x1F
		return ((n >> 4) & 1) << 22 | (n & 0xF) << 12 | (op.list.stride > 1 ? u32(1) : 0) << 5
	case .NEON_LANE_D_8, .NEON_LANE_D_16, .NEON_LANE_D_32, .NEON_LANE_D_8_2, .NEON_LANE_D_16_2, .NEON_LANE_D_32_2, .NEON_LANE_D_8_3, .NEON_LANE_D_16_3, .NEON_LANE_D_32_3, .NEON_LANE_D_8_4, .NEON_LANE_D_16_4, .NEON_LANE_D_32_4:
		n := u32(reg_hw(op.reg)) & 0x1F
		shift, mask, _ := neon_lane_shape(enc)
		return ((n >> 4) & 1) << 22 | (n & 0xF) << 12 | (u32(op.lane) & mask) << shift
	case .NEON_VDUP_LANE_8, .NEON_VDUP_LANE_16, .NEON_VDUP_LANE_32:
		n := u32(reg_hw(op.reg)) & 0x1F
		shift: u32 = enc == .NEON_VDUP_LANE_8 ? 1 : enc == .NEON_VDUP_LANE_16 ? 2 : 3
		// The marker bit below the index is a fixed bit of the form.
		return ((n >> 4) & 1) << 5 | (n & 0xF) | (u32(op.lane) << shift) << 16
	case .NEON_VM_SCALAR_16:
		n := u32(reg_hw(op.reg)) & 0x7
		idx := u32(op.lane) & 0x3
		return n | ((idx >> 1) & 1) << 5 | (idx & 1) << 3
	case .NEON_VM_SCALAR_32:
		return (u32(reg_hw(op.reg)) & 0xF) | (u32(op.lane) & 1) << 5
	case .NEON_VN_TABLE_1, .NEON_VN_TABLE_2, .NEON_VN_TABLE_3, .NEON_VN_TABLE_4:
		// The run length is already a fixed bit of the form; only Vn is ours.
		n := u32(reg_hw(op.reg)) & 0x1F
		return ((n >> 4) & 1) << 7 | (n & 0xF) << 16
	case .VFP_S_LIST:
		n := u32(reg_hw(op.reg)) & 0x1F
		return ((n >> 1) & 0xF) << 12 | (n & 1) << 22 | (u32(op.list.count) & 0xFF)
	case .VFP_D_LIST:
		n := u32(reg_hw(op.reg)) & 0x1F
		return ((n >> 4) & 1) << 22 | (n & 0xF) << 12 | ((u32(op.list.count) * 2) & 0xFF)
	case .VFP_DX_LIST:
		n := u32(reg_hw(op.reg)) & 0x1F
		return ((n >> 4) & 1) << 22 | (n & 0xF) << 12 | ((u32(op.list.count) * 2 + 1) & 0xFF)
	case .VD_S_AGAIN, .VD_D_AGAIN:
		return 0    // Vd already holds it, from the first mention
	case .RT_VMRS:
		if op.reg == APSR_NZCV { return 0xF << 12 }
		return (u32(reg_hw(op.reg)) & 0xF) << 12

	// ---- Memory addressing composites --------------------------------------
	case .MEM_IMM8_SCALED2:
		m := op.mem
		base := (u32(reg_hw(m.base)) & 0xF) << 16
		u_bit: u32 = (m.disp > 0 || (m.disp == 0 && m.sign >= 0)) ? 1 : 0
		return base | (u_bit << 23) | ((u32(abs_i32(m.disp)) / 2) & 0xFF)
	case .MEM_IMM8_SCALED4, .MEM_IMM8_SCALED4_PRE, .MEM_IMM8_SCALED4_POST:
		m := op.mem
		base := (u32(reg_hw(m.base)) & 0xF) << 16
		u_bit: u32 = (m.disp > 0 || (m.disp == 0 && m.sign >= 0)) ? 1 : 0
		return base | (u_bit << 23) | ((u32(abs_i32(m.disp)) / 4) & 0xFF)
	case .MEM_IMM12_OFFSET:
		m := op.mem
		base := (u32(reg_hw(m.base)) & 0xF) << 16
		u_bit: u32 = (m.disp > 0 || (m.disp == 0 && m.sign >= 0)) ? 1 : 0
		disp := u32(abs_i32(m.disp)) & 0xFFF
		return base | (u_bit << 23) | disp
	case .RT2_A32_PAIR:
		return 0
	case .MEM_IMM8_PRE_INDEX, .MEM_IMM8_POST_INDEX, .MEM_IMM8_OFFSET:
		m := op.mem
		base := (u32(reg_hw(m.base)) & 0xF) << 16
		u_bit: u32 = (m.disp > 0 || (m.disp == 0 && m.sign >= 0)) ? 1 : 0
		disp := u32(abs_i32(m.disp)) & 0xFF
		return base | (u_bit << 23) | ((disp >> 4) & 0xF) << 8 | (disp & 0xF)
	case .MEM_REG_OFFSET:
		m := op.mem
		base := (u32(reg_hw(m.base)) & 0xF) << 16
		rm   :=  u32(reg_hw(m.index)) & 0xF
		u_bit: u32 = m.sign >= 0 ? 1 : 0
		return base | (u_bit << 23) | rm
	case .MEM_PRE_INDEX:
		// Same layout as MEM_IMM12_OFFSET (base, U, disp); the form bits set
		// P=1, W=1 in bits 24/21 to select pre-index addressing mode.
		m := op.mem
		base := (u32(reg_hw(m.base)) & 0xF) << 16
		u_bit: u32 = (m.disp > 0 || (m.disp == 0 && m.sign >= 0)) ? 1 : 0
		disp := u32(abs_i32(m.disp)) & 0xFFF
		return base | (u_bit << 23) | disp
	case .MEM_POST_INDEX:
		// Same layout as MEM_IMM12_OFFSET; form bits select P=0 in bit 24.
		m := op.mem
		base := (u32(reg_hw(m.base)) & 0xF) << 16
		u_bit: u32 = (m.disp > 0 || (m.disp == 0 && m.sign >= 0)) ? 1 : 0
		disp := u32(abs_i32(m.disp)) & 0xFFF
		return base | (u_bit << 23) | disp
	case .MEM_LITERAL:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .LDR_LITERAL_A32, size = 4, inst_idx = inst_idx,
		})
		return 0
	case .MEM_DOUBLEREG:
		m := op.mem
		return ((u32(reg_hw(m.base)) & 0xF) << 16) | (u32(reg_hw(m.index)) & 0xF)

	// ---- Coprocessor -------------------------------------------------------
	case .COPROC_NUM_FIELD:   return (u32(reg_hw(op.reg)) & 0xF) << 8
	case .COPROC_CRD_FIELD:   return (u32(reg_hw(op.reg)) & 0xF) << 12
	case .COPROC_OPC1_MCR:    return (u32(op.immediate) & 0x7) << 21
	case .COPROC_OPC1_FIELD:  return (u32(op.immediate) & 0xF) << 20
	case .COPROC_OPC2_FIELD:  return (u32(op.immediate) & 0x7) << 5
	case .COPROC_CRN_FIELD:   return (u32(reg_hw(op.reg)) & 0xF) << 16
	case .COPROC_CRM_FIELD:   return  u32(reg_hw(op.reg)) & 0xF
	case .COPROC_OPC_MCRR:    return (u32(op.immediate) & 0xF) << 4

	// ---- Branch fields -----------------------------------------------------
	case .BRANCH_24:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .BRANCH_A32_24, size = 4, inst_idx = inst_idx,
		})
		return 0
	case .BRANCH_24_T32:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .BRANCH_T32_25, size = 4, inst_idx = inst_idx,
		})
		return 0
	case .BRANCH_20_T32:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .BRANCH_T32_21, size = 4, inst_idx = inst_idx,
		})
		return 0
	case .BRANCH_11_T16:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .BRANCH_T16_11, size = 2, inst_idx = inst_idx,
		})
		return 0
	case .BRANCH_8_T16:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .BRANCH_T16_8, size = 2, inst_idx = inst_idx,
		})
		return 0
	case .BRANCH_CBZ:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .BRANCH_T16_CBZ, size = 2, inst_idx = inst_idx,
		})
		return 0

	// ---- ARMv8.1-M Branch Future -------------------------------------------
	case .BF_BOFF:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .BF_BOFF_T32, size = 4, inst_idx = inst_idx,
		})
		return 0
	case .BF_BLOC:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .BF_BLOC_T32, size = 4, inst_idx = inst_idx,
		})
		return 0
	case .BF_RM:
		return (u32(reg_hw(op.reg)) & 0xF) << 16   // Rm at hw0[3:0] (word bits 19:16)
	case .BFCSEL_COND:
		return (u32(op.immediate) & 0xF) << 18     // cond at hw0[5:2] (word bits 21:18)

	// ---- Misc --------------------------------------------------------------
	case .PSR_FIELD_MASK:   return encode_psr_field(u8(op.immediate))
	case .SYSM_FIELD:       return u32(op.immediate) & 0xFF
	case .BARRIER_TYPE:     return u32(op.immediate) & 0xF
	case .CPS_IFLAGS:       return u32(op.immediate) & 0x1FF
	case .HINT_FIELD:       return u32(op.immediate) & 0xFF
	case .NEON_SHLL_8, .NEON_SHLL_16, .NEON_SHLL_32:
		return 0    // the amount is the form's element size; no field carries it
	case .NEON_ROT_2:
		return (op.immediate == 270 ? u32(1) : 0) << 24
	case .NEON_ROT_4:
		return ((u32(op.immediate) / 90) & 3) << 20
	case .NEON_ROT_4_HI:
		return ((u32(op.immediate) / 90) & 3) << 23
	case .VFP_FBITS:
		// sx is a fixed bit of the form, so the width comes from its pattern.
		width: u32 = ((form.bits >> 7) & 1) != 0 ? 32 : 16
		imm := width - (u32(op.immediate) & 0x3F)
		return ((imm >> 1) & 0xF) | (imm & 1) << 5
	case .SAT_IMM5, .BFX_WIDTH:
		return ((u32(op.immediate) - 1) & 0x1F) << 16
	case .SAT_IMM5_U:
		return (u32(op.immediate) & 0x1F) << 16
	case .SAT_IMM5_T32:      return (u32(op.immediate) - 1) & 0x1F
	case .SAT_IMM5_U_T32:    return  u32(op.immediate) & 0x1F
	case .SAT16_IMM4_T32:    return (u32(op.immediate) - 1) & 0xF
	case .SAT16_IMM4_U_T32:  return  u32(op.immediate) & 0xF
	case .BFX_WIDTH_T32:     return (u32(op.immediate) - 1) & 0x1F
	case .BFI_MSB_T32:
		lsb: u32 = 0
		for e, k in form.enc {
			if e == .BFI_LSB_T32 { lsb = u32(inst.ops[k].immediate); break }
		}
		return (lsb + u32(op.immediate) - 1) & 0x1F
	case .BFI_MSB:
		// msb = lsb + width - 1; the lsb rides in whichever slot carries it.
		lsb: u32 = 0
		for e, k in form.enc {
			if e == .BFI_LSB || e == .BFI_LSB_T32 { lsb = u32(inst.ops[k].immediate); break }
		}
		return ((lsb + u32(op.immediate) - 1) & 0x1F) << 16
	case .BFI_LSB:
		return (u32(op.immediate) & 0x1F) << 7
	case .BFI_LSB_T32:
		return t32_split_shift(u32(op.immediate) & 0x1F)
	case .NEON_SHIFT_IMM6:  return (u32(op.immediate) & 0x3F) << 16
	case .NEON_SHIFT_IMM3:  return (u32(op.immediate) & 0x7)  << 16
	case .NEON_SHIFT_IMM4:  return (u32(op.immediate) & 0xF)  << 16
	case .NEON_SHIFT_IMM5:  return (u32(op.immediate) & 0x1F) << 16

	// ---- MVE / CDE specifics (placeholders; bits per operand encoding) -----
	case .QD_MVE:           return (u32(reg_hw(op.reg)) & 0x7) << 13
	case .QN_MVE:           return ((u32(reg_hw(op.reg)) & 0x7) << 17) | ((u32(reg_hw(op.reg)) & 0x8) << 4)
	case .QM_MVE:           return  (u32(reg_hw(op.reg)) & 0x7) << 1
	case .MVE_RDA_EVEN, .MVE_RDALO:
		return ((u32(reg_hw(op.reg)) / 2) & 0x7) << 13
	case .MVE_RDAHI:
		return ((u32(reg_hw(op.reg)) / 2) & 0x7) << 20
	case .MVE_SIZE_FIELD:   return (u32(op.immediate) & 0x3) << 20
	case .MVE_VPT_MASK_FIELD: return (u32(op.immediate) & 0xF) << 13
	case .MVE_LOOP_IMM:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .BRANCH_T32_WLS, size = 4, inst_idx = inst_idx,
		})
		return 0
	case .CDE_COPROC_FIELD: return (u32(op.immediate) & 0x7) << 8
	case .CDE_IMM_FIELD:    return  u32(op.immediate) & 0x7F
	case .CDE_ACC_FIELD:    return (u32(op.immediate) & 1) << 16
	case .V8M_TT_AT_BITS:   return (u32(op.immediate) & 0x3) << 6
	}

	return 0
}

@(private="file")
abs_i32 :: #force_inline proc "contextless" (v: i32) -> i32 {
	return v < 0 ? -v : v
}

// Whether a register (or an index) is shifted at all. The zero Shift_Type is
// LSL, so an operand nobody shifted reads as LSL #0, which is no shift.
@(private)
is_shifted :: #force_inline proc "contextless" (shift: Shift_Type, amount: u8) -> bool {
	return shift != .NONE && !(shift == .LSL && amount == 0)
}

// A five-bit amount as Thumb-2 splits it around Rd: imm3 at 14:12, imm2 at 7:6.
@(private="file")
t32_split_shift :: #force_inline proc "contextless" (amount: u32) -> u32 {
	return (amount >> 2) << 12 | (amount & 0x3) << 6
}


// =============================================================================
// Pass 2 -- relocation resolver
// =============================================================================

@(private="file")
resolve_relocation_inline :: #force_inline proc(
	code:         []u8,
	label_defs:   []Label_Definition,
	r:            ^Relocation,
	base_address: u64,
	errors:       ^[dynamic]Error,
) -> bool {
	if int(r.label_id) >= len(label_defs) { return false }
	ld := label_defs[r.label_id]
	if ld == LABEL_UNDEFINED { return false }
	target := u32(ld)

	switch r.type {
	case .NONE, .BLX_A32, .ADR_A32, .MOVW_ABS, .MOVT_ABS:
		// encode produces none of these; they stay pending for the caller.
		return false
	case .BRANCH_A32_24:
		// PC = inst_addr + 8 in A32 mode
		rel := i32(target) - (i32(r.offset) + 8) + r.addend
		if rel & 3 != 0 || rel < -(1 << 25) || rel >= (1 << 25) {
			append(errors, Error{inst_idx = u32(r.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		imm24 := u32(rel >> 2) & 0xFFFFFF
		word := read_u32_le(code, r.offset)
		word = (word & 0xFF000000) | imm24
		write_u32_le(code, r.offset, word)
		return true

	case .BRANCH_T32_25:
		// PC = inst_addr + 4 in T32
		rel := i32(target) - (i32(r.offset) + 4) + r.addend
		if rel & 1 != 0 || rel < -(1 << 24) || rel >= (1 << 24) {
			append(errors, Error{inst_idx = u32(r.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		// 25-bit signed: S | I1 | I2 | imm10 | imm11 (scattered)
		v := u32(rel >> 1)
		s := (v >> 23) & 1
		i1 := ((v >> 22) & 1) ~ (s ~ 1)
		i2 := ((v >> 21) & 1) ~ (s ~ 1)
		imm10 := (v >> 11) & 0x3FF
		imm11 := v & 0x7FF
		// word layout (low halfword first in memory, but we work on packed u32)
		hi := u16(0xF000) | u16(s << 10) | u16(imm10)
		lo := u16(0x9000) | u16(i1 << 13) | u16(i2 << 11) | u16(imm11)
		write_u16_le(code, r.offset,     hi)
		write_u16_le(code, r.offset + 2, lo)
		return true

	case .BRANCH_T32_21:
		// T32 B<cond>: PC = inst + 4
		rel := i32(target) - (i32(r.offset) + 4) + r.addend
		if rel & 1 != 0 || rel < -(1 << 20) || rel >= (1 << 20) {
			append(errors, Error{inst_idx = u32(r.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		// The offset is S:J2:J1:imm6:imm11 -- J2 above J1, the other way
		// round from where they sit in the word.
		v := u32(rel >> 1)
		s    := (v >> 19) & 1
		j2   := (v >> 18) & 1
		j1   := (v >> 17) & 1
		imm6 := (v >> 11) & 0x3F
		imm11 := v & 0x7FF
		hi := u16(0xF000) | u16(s << 10) | u16(imm6)
		lo := u16(0x8000) | u16(j1 << 13) | u16(j2 << 11) | u16(imm11)
		// Note: cond bits come from form.bits, which we OR with hi
		existing_hi := read_u16_le(code, r.offset)
		existing_lo := read_u16_le(code, r.offset + 2)
		write_u16_le(code, r.offset,     existing_hi | hi)
		write_u16_le(code, r.offset + 2, existing_lo | lo)
		return true

	case .BLX_T32:
		// BLX to A32 lands on a word: the target is Align(PC, 4) plus the
		// offset, and the offset's low two bits are not in the word.
		base := (i32(r.offset) + 4) & ~i32(3)
		rel := i32(target) - base + r.addend
		if rel & 3 != 0 || rel < -(1 << 24) || rel >= (1 << 24) {
			append(errors, Error{inst_idx = u32(r.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		v := u32(rel >> 2)
		s := (v >> 22) & 1
		i1 := ((v >> 21) & 1) ~ (s ~ 1)
		i2 := ((v >> 20) & 1) ~ (s ~ 1)
		first  := read_u16_le(code, r.offset)     | u16(s << 10) | u16((v >> 10) & 0x3FF)
		second := read_u16_le(code, r.offset + 2) | u16(i1 << 13) | u16(i2 << 11) | u16((v & 0x3FF) << 1)
		write_u16_le(code, r.offset,     first)
		write_u16_le(code, r.offset + 2, second)
		return true

	case .BRANCH_T16_11:
		rel := i32(target) - (i32(r.offset) + 4) + r.addend
		if rel & 1 != 0 || rel < -(1 << 11) || rel >= (1 << 11) {
			append(errors, Error{inst_idx = u32(r.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		imm11 := u16(u32(rel >> 1) & 0x7FF)
		word := read_u16_le(code, r.offset)
		word = (word & 0xF800) | imm11
		write_u16_le(code, r.offset, word)
		return true

	case .BRANCH_T16_8:
		rel := i32(target) - (i32(r.offset) + 4) + r.addend
		if rel & 1 != 0 || rel < -256 || rel >= 256 {
			append(errors, Error{inst_idx = u32(r.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		imm8 := u16(u32(rel >> 1) & 0xFF)
		word := read_u16_le(code, r.offset)
		word = (word & 0xFF00) | imm8
		write_u16_le(code, r.offset, word)
		return true

	case .BRANCH_T16_CBZ:
		rel := i32(target) - (i32(r.offset) + 4) + r.addend
		if rel < 0 || rel & 1 != 0 || rel >= (1 << 7) {
			append(errors, Error{inst_idx = u32(r.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		v := u32(rel >> 1)
		i_bit := (v >> 5) & 1
		imm5  := v & 0x1F
		word := read_u16_le(code, r.offset)
		word = (word & 0xFD07) | u16(i_bit << 9) | u16(imm5 << 3)
		write_u16_le(code, r.offset, word)
		return true

	case .BRANCH_T32_WLS, .BRANCH_T32_LE:
		// ARMv8.1-M low-overhead loops: an unsigned even offset, forward from
		// PC for WLS and back for LE, written imml:immh:'0' -- imml at the
		// second halfword's 10:1 and immh at 11.
		rel := i32(target) - (i32(r.offset) + 4) + r.addend
		if r.type == .BRANCH_T32_LE { rel = -rel }
		if rel & 1 != 0 || rel < 0 || rel >= (1 << 12) {
			append(errors, Error{inst_idx = u32(r.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		offset := u16(rel)
		existing := read_u16_le(code, r.offset + 2)
		write_u16_le(code, r.offset + 2, existing | (offset >> 2) << 1 | ((offset >> 1) & 1) << 11)
		return true

	case .BF_BOFF_T32:
		// Branch Future bf-point: imm4 = (label-(PC+4))/2 at hw0[10:7].
		rel := i32(target) - (i32(r.offset) + 4) + r.addend
		if rel & 1 != 0 || rel < 0 || rel >= (1 << 5) {
			append(errors, Error{inst_idx = u32(r.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		imm4 := u16(u32(rel >> 1) & 0xF)
		hw0  := read_u16_le(code, r.offset)
		write_u16_le(code, r.offset, hw0 | (imm4 << 7))
		return true

	case .BF_BLOC_T32:
		// Branch Future target: val=(label-(PC+4))/2; J at hw1[11], imm10 at hw1[10:1].
		rel := i32(target) - (i32(r.offset) + 4) + r.addend
		if rel & 1 != 0 || rel < -(1 << 11) || rel >= (1 << 11) {
			append(errors, Error{inst_idx = u32(r.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		val   := u32(rel >> 1)
		hw1   := read_u16_le(code, r.offset + 2)
		hw1 |= u16((val & 1) << 11) | u16(((val >> 1) & 0x3FF) << 1)
		write_u16_le(code, r.offset + 2, hw1)
		return true

	case .LDR_LITERAL_A32:
		rel := i32(target) - (i32(r.offset) + 8) + r.addend
		u_bit: u32 = rel >= 0 ? 1 : 0
		abs := u32(rel < 0 ? -rel : rel)
		if abs >= 4096 {
			append(errors, Error{inst_idx = u32(r.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		word := read_u32_le(code, r.offset)
		word = (word & 0xFF7FF000) | (u_bit << 23) | abs
		write_u32_le(code, r.offset, word)
		return true

	case .LDR_LITERAL_T32:
		return resolve_thumb_wide_literal(code, r, target, errors)
	case .LDR_LITERAL_T16:
		return resolve_thumb_narrow_literal(code, r, target, errors)
	case .LDRD_LITERAL_T32:
		return resolve_thumb_wide_literal(code, r, target, errors)
	case .ADR_T32:
		return resolve_thumb_wide_literal(code, r, target, errors)
	case .ADR_T16:
		return resolve_thumb_narrow_literal(code, r, target, errors)
	}
	return false
}

// The 32-bit Thumb literal loads and ADR, measured from PC rounded down to a
// word. See the comments below for how the three differ.
@(private="file")
resolve_thumb_wide_literal :: proc(code: []u8, r: ^Relocation, target: u32, errors: ^[dynamic]Error) -> bool {
	// Align(PC, 4) +/- the offset. LDR's and ADR's are twelve bits in
	// bytes; LDRD's is eight bits in words. The sign is U for the loads,
	// and the choice between ADR's add and sub forms for ADR -- which
	// is the first halfword's bits 7 and 5, so flip both together.
	base := (i32(r.offset) + 4) & ~i32(3)
	rel := i32(target) - base + r.addend
	magnitude := u32(rel < 0 ? -rel : rel)
	first  := u32(read_u16_le(code, r.offset))
	second := u32(read_u16_le(code, r.offset + 2))
	if r.type == .LDRD_LITERAL_T32 {
		if magnitude & 3 != 0 || magnitude > 1020 {
			append(errors, Error{inst_idx = u32(r.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		second |= magnitude >> 2
		if rel >= 0 { first |= 1 << 7 }
	} else if r.type == .ADR_T32 {
		if magnitude > 4095 {
			append(errors, Error{inst_idx = u32(r.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		// ADDW Rd, PC is 0xF20F; SUBW Rd, PC is 0xF2AF.
		if rel < 0 { first = (first & ~u32(0x00F0)) | 0x00A0 }
		first |= (magnitude >> 11) << 10
		second |= ((magnitude >> 8) & 0x7) << 12 | (magnitude & 0xFF)
	} else {
		if magnitude > 4095 {
			append(errors, Error{inst_idx = u32(r.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		second |= magnitude
		if rel >= 0 { first |= 1 << 7 }
	}
	write_u16_le(code, r.offset,     u16(first))
	write_u16_le(code, r.offset + 2, u16(second))
	return true
}

// The 16-bit Thumb literal load and ADR.
@(private="file")
resolve_thumb_narrow_literal :: proc(code: []u8, r: ^Relocation, target: u32, errors: ^[dynamic]Error) -> bool {
	// Both measure from PC rounded down to a word, in words, forward only.
	base := (i32(r.offset) + 4) & ~i32(3)
	rel := i32(target) - base + r.addend
	if rel < 0 || rel & 3 != 0 || rel > 1020 {
		append(errors, Error{inst_idx = u32(r.inst_idx), code = .LABEL_OUT_OF_RANGE})
		return true
	}
	word := read_u16_le(code, r.offset)
	write_u16_le(code, r.offset, word | u16(rel >> 2))
	return true
}

// =============================================================================
// Halfword/word I/O
// =============================================================================

@(private="package")
write_u32_le :: #force_inline proc "contextless" (code: []u8, offset, word: u32) {
	code[offset+0] = u8(word)
	code[offset+1] = u8(word >>  8)
	code[offset+2] = u8(word >> 16)
	code[offset+3] = u8(word >> 24)
}

@(private="package")
read_u32_le :: #force_inline proc "contextless" (code: []u8, offset: u32) -> u32 {
	return  u32(code[offset+0])        |
		   (u32(code[offset+1]) <<  8) |
		   (u32(code[offset+2]) << 16) |
		   (u32(code[offset+3]) << 24)
}

@(private="package")
write_u16_le :: #force_inline proc "contextless" (code: []u8, offset: u32, word: u16) {
	code[offset+0] = u8(word)
	code[offset+1] = u8(word >> 8)
}

@(private="package")
read_u16_le :: #force_inline proc "contextless" (code: []u8, offset: u32) -> u16 {
	return u16(code[offset+0]) | (u16(code[offset+1]) << 8)
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

// LDM/STM come in a writeback form and a plain one that differ only in bit 21,
// so the operand shapes cannot tell them apart.
@(private, require_results)
writeback_matches :: #force_inline proc "contextless" (inst: ^Instruction, f: ^Encoding) -> bool {
	for e in f.enc {
		if e == .A32_REG_LIST || e == .RN_A32_WB || e == .IMPL_SP {
			return ((f.bits >> 21) & 1 != 0) == inst.writeback
		}
	}
	return true
}
