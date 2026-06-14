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

encode_max_code_size        :: #force_inline proc "contextless" (n: int) -> int { return n * 4 }
encode_max_relocation_count :: #force_inline proc "contextless" (n: int) -> int { return n }

encode :: proc(
	instructions: []Instruction,
	label_defs:   []Label_Definition,
	code:         []u8,
	relocs:       ^[dynamic]Relocation,
	errors:       ^[dynamic]Error,
	resolve:      bool = true,
	base_address: u64  = 0,
) -> Result {
	n_inst := len(instructions)
	if len(code) < n_inst * 4 {
		append(errors, Error{inst_idx = 0, code = .BUFFER_OVERFLOW})
		return Result{byte_count = 0, success = false}
	}

	errors_start  := u32(len(errors))
	pending_start := u32(len(relocs))
	pc: u32 = 0

	inst_pc := make([]u32, n_inst, context.temp_allocator)

	// ---- PASS 1 ------------------------------------------------------------
	for i in 0..<n_inst {
		inst_pc[i] = pc
		inst := &instructions[i]
		word, ilen, ok := encode_one_inline(inst, pc, u16(i), relocs, errors)
		if !ok { return Result{byte_count = pc, success = false} }
		if ilen == 2 {
			write_u16_le(code, pc, u16(word))
		} else {
			// T32 32-bit: bits = low_hword | (high_hword << 16); each
			// halfword is written little-endian in its own slot.
			if inst.mode == .T32 {
				write_u16_le(code, pc,     u16(word >> 16))
				write_u16_le(code, pc + 2, u16(word))
			} else {
				write_u32_le(code, pc, word)
			}
		}
		pc += u32(ilen)
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
		return Result{byte_count = pc, success = u32(len(errors)) == errors_start}
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

	return Result{byte_count = pc, success = u32(len(errors)) == errors_start}
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
) -> (word: u32, ilen: u8, ok: bool) {
	if inst.mnemonic == .INVALID {
		append(errors, Error{inst_idx = u32(inst_idx), code = .INVALID_MNEMONIC})
		return 0, 0, false
	}

	forms := ENCODING_TABLE[inst.mnemonic]
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
		   (want_len == 0 || inst_size_from_bits(f.bits, f.mode) == want_len) &&
		   encoding_matches_inline(inst, f) &&
		   inst.flags.sets_flags == f.flags.sets_flags &&
		   mem_mode_matches(inst, f) {
			form = f
		}
	}
	if form == nil {
		for &f in forms {
			if f.mode != inst.mode { continue }
			if want_len > 0 && inst_size_from_bits(f.bits, f.mode) != want_len { continue }
			if !encoding_matches_inline(inst, &f) { continue }
			if inst.flags.sets_flags && !f.flags.sets_flags { continue }
			if !inst.flags.sets_flags && f.flags.sets_flags { continue }
			if !mem_mode_matches(inst, &f) { continue }
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

	if form.enc[0] != .NONE { word |= pack_operand_inline(&inst.ops[0], form.enc[0], pc, inst_idx, relocs, form) }
	if form.enc[1] != .NONE { word |= pack_operand_inline(&inst.ops[1], form.enc[1], pc, inst_idx, relocs, form) }
	if form.enc[2] != .NONE { word |= pack_operand_inline(&inst.ops[2], form.enc[2], pc, inst_idx, relocs, form) }
	if form.enc[3] != .NONE { word |= pack_operand_inline(&inst.ops[3], form.enc[3], pc, inst_idx, relocs, form) }

	return word, inst_size_from_bits(form.bits, form.mode), true
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
@(private="file")
mem_mode_matches :: #force_inline proc "contextless" (inst: ^Instruction, form: ^Encoding) -> bool {
	for k in 0..<4 {
		op := &inst.ops[k]
		if op.kind != .MEMORY { continue }
		m := op.mem.mode
		// No explicit "none" register sentinel — `mem_imm` leaves index at
		// the zero value (Register(0) == R0), which we treat as "no index".
		// Callers wanting [Rn, R0] must use `mem_reg(Rn, R1)` and pick a
		// different register; this is a pragmatic ambiguity, not a true bug,
		// because R0-as-index is exceedingly rare in real code.
		has_index := op.mem.index != Register(0)
		#partial switch form.enc[k] {
		case .MEM_IMM12_OFFSET, .MEM_IMM8_OFFSET:
			if m != .OFFSET { return false }
			if has_index { return false }
		case .MEM_REG_OFFSET, .MEM_DOUBLEREG:
			if m != .OFFSET { return false }
			if !has_index { return false }
		case .MEM_PRE_INDEX:
			if m != .PRE_INDEX { return false }
		case .MEM_POST_INDEX:
			if m != .POST_INDEX { return false }
		}
	}
	return true
}

@(private="file")
encoding_matches_inline :: #force_inline proc "contextless" (inst: ^Instruction, form: ^Encoding) -> bool {
	return  operand_matches_inline(&inst.ops[0], form.ops[0]) &&
	        operand_matches_inline(&inst.ops[1], form.ops[1]) &&
	        operand_matches_inline(&inst.ops[2], form.ops[2]) &&
	        operand_matches_inline(&inst.ops[3], form.ops[3])
}

@(private="file")
operand_matches_inline :: #force_inline proc "contextless" (op: ^Operand, ot: Operand_Type) -> bool {
	#partial switch ot {
	case .NONE:
		return op.kind == .NONE
	case .GPR, .GPR_NOPC, .GPR_NOSP, .GPR_LOW:
		return op.kind == .REGISTER && is_gpr(op.reg)
	case .GPR_SHIFTED:
		return op.kind == .REGISTER && is_gpr(op.reg) &&
			   op.shift_type != .NONE &&
			   !is_rsr_shift_type(op.shift_type)
	case .GPR_RSR:  return op.kind == .REGISTER && is_gpr(op.reg) && is_rsr_shift_type(op.shift_type)
	case .GPR_LIST: return op.kind == .REG_LIST
	case .SPR:      return op.kind == .REGISTER && is_spr(op.reg)
	case .DPR:      return op.kind == .REGISTER && is_dpr(op.reg)
	case .QPR:      return op.kind == .REGISTER && is_qpr(op.reg)
	case .DPR_ELEM: return op.kind == .REGISTER && is_dpr(op.reg)
	case .QPR_ELEM: return op.kind == .REGISTER && is_qpr(op.reg)
	case .SPR_ELEM: return op.kind == .REGISTER && is_spr(op.reg)
	case .SPR_LIST, .DPR_LIST:
		return op.kind == .REG_LIST || (op.kind == .REGISTER && (is_spr(op.reg) || is_dpr(op.reg)))
	case .IMM, .IMM_MOD, .IMM_T32_MOD, .IMM12, .IMM5, .IMM5_W,
	     .IMM4, .IMM4_SAT, .IMM8, .IMM3, .IMM_HINT, .IMM_BARRIER,
	     .IMM_ENDIAN, .IMM_IFLAGS, .IMM_BANKED, .IMM_SYSM,
	     .IMM_COPROC, .IMM_COPROC_OP, .NEON_IMM, .IMM16_LO_HI:
		return op.kind == .IMMEDIATE
	case .REL24, .REL24_T32, .REL20, .REL11, .REL8, .REL_LDR_LITERAL:
		return op.kind == .RELATIVE
	case .COND:
		return op.kind == .IMMEDIATE
	case .MEM:
		// Most MEM forms expect a Memory operand, but PC-relative literal
		// loads (form encoding .MEM_LITERAL) decode to a RELATIVE operand so
		// the branch-resolution pass can patch the label offset. Accept both.
		return op.kind == .MEMORY || op.kind == .RELATIVE
	case .COPROC_REG, .COPROC_NUM:
		return op.kind == .REGISTER || op.kind == .IMMEDIATE
	case .PSR_FIELD:
		return op.kind == .IMMEDIATE
	case .VPR, .QPR_MVE:
		return op.kind == .REGISTER && is_qpr(op.reg)
	case .QPR_MVE_LIST:
		return op.kind == .REG_LIST || (op.kind == .REGISTER && is_qpr(op.reg))
	case .MVE_VPT_MASK, .MVE_VCTP_SIZE, .MVE_LOOP_TGT, .CDE_COPROC,
		 .CDE_IMM, .CDE_VFP_REG:
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
	case .RM_T32:              return  u32(reg_hw(op.reg)) & 0xF
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
	case .VFP_IMM8:
		// Run the VFP 8-bit float encoder; the user supplies the wire-format
		// 32-bit float bit pattern (for F32). The encoder finds the abcdefgh.
		if a, ok := encode_vfp_imm8_f32(u32(op.immediate)); ok {
			return (u32(a) >> 4) << 16 | u32(a) & 0xF
		}
		return u32(op.immediate) & 0xFF
	case .NEON_IMM8_ABCDEFGH:
		// Caller passes a packed NEON_Imm_Form (cmode + op + abcdefgh) where
		// the 32-bit constant has already been resolved. We extract the
		// abcdefgh and lay it out per the wire (bits 24, 18:16, 3:0).
		f, ok := encode_neon_modimm(u32(op.immediate))
		if !ok {
			// Fall back: treat low 8 bits as raw abcdefgh
			v := u32(op.immediate) & 0xFF
			return ((v >> 7) & 1) << 24 |
				   ((v >> 4) & 0x7) << 16 |
					(v & 0xF)
		}
		return pack_neon_modimm_field(f)
	case .NEON_CMODE:       return (u32(op.immediate) & 0xF) << 8
	case .NEON_OP_BIT:      return (u32(op.immediate) & 1) << 5

	// ---- VFP/NEON register lists (LDM/STM/PUSH/POP for FP regs) ------------
	case .VFP_S_LIST, .VFP_D_LIST:
		return u32(op.immediate) & 0xFF

	// ---- Memory addressing composites --------------------------------------
	case .MEM_IMM12_OFFSET:
		m := op.mem
		base := (u32(reg_hw(m.base)) & 0xF) << 16
		u_bit: u32 = m.disp >= 0 ? 1 : 0
		disp := u32(abs_i32(m.disp)) & 0xFFF
		return base | (u_bit << 23) | disp
	case .MEM_IMM8_OFFSET:
		m := op.mem
		base := (u32(reg_hw(m.base)) & 0xF) << 16
		u_bit: u32 = m.disp >= 0 ? 1 : 0
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
		u_bit: u32 = m.disp >= 0 ? 1 : 0
		disp := u32(abs_i32(m.disp)) & 0xFFF
		return base | (u_bit << 23) | disp
	case .MEM_POST_INDEX:
		// Same layout as MEM_IMM12_OFFSET; form bits select P=0 in bit 24.
		m := op.mem
		base := (u32(reg_hw(m.base)) & 0xF) << 16
		u_bit: u32 = m.disp >= 0 ? 1 : 0
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
	case .COPROC_NUM_FIELD:   return (u32(op.immediate) & 0xF) << 8
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

	// ---- Misc --------------------------------------------------------------
	case .PSR_FIELD_MASK:   return encode_psr_field(u8(op.immediate))
	case .SYSM_FIELD:       return u32(op.immediate) & 0xFF
	case .BARRIER_TYPE:     return u32(op.immediate) & 0xF
	case .IT_MASK:          return u32(op.immediate) & 0xFF
	case .CPS_IFLAGS:       return u32(op.immediate) & 0x1FF
	case .HINT_FIELD:       return u32(op.immediate) & 0xFF
	case .SAT_IMM5, .SAT_IMM5_T32:
		return (u32(op.immediate) & 0x1F) << 16
	case .BFI_MSB:          return (u32(op.immediate) & 0x1F) << 16
	case .BFI_LSB, .BFI_LSB_T32:
		return (u32(op.immediate) & 0x1F) << 7
	case .NEON_SHIFT_IMM6:  return (u32(op.immediate) & 0x3F) << 16
	case .NEON_SHIFT_IMM3:  return (u32(op.immediate) & 0x7)  << 16

	// ---- MVE / CDE specifics (placeholders; bits per operand encoding) -----
	case .QD_MVE:           return (u32(reg_hw(op.reg)) & 0x7) << 13
	case .QN_MVE:           return ((u32(reg_hw(op.reg)) & 0x7) << 17) | ((u32(reg_hw(op.reg)) & 0x8) << 4)
	case .QM_MVE:           return  (u32(reg_hw(op.reg)) & 0x7) << 1
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

	#partial switch r.type {
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
		v := u32(rel >> 1)
		s    := (v >> 19) & 1
		j1   := (v >> 18) & 1
		j2   := (v >> 17) & 1
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
		// ARMv8.1-M low-overhead loop branches; signed 11-bit << 1
		rel := i32(target) - (i32(r.offset) + 4) + r.addend
		if rel & 1 != 0 || rel < -(1 << 11) || rel >= (1 << 11) {
			append(errors, Error{inst_idx = u32(r.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		// imm11 packed at bits 10:1 (low halfword)
		imm11 := u16(u32(rel >> 1) & 0x7FF)
		existing := read_u16_le(code, r.offset + 2)
		write_u16_le(code, r.offset + 2, existing | (imm11 << 1))
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

	case:
		return false
	}
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
