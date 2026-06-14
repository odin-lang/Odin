package rexcode_ppc

// =============================================================================
// PowerPC ENCODER
// =============================================================================
//
// Two-pass design (mirrors arm32/encoder.odin):
//
//   PASS 1   - For each Instruction, find the first matching Encoding form
//              (by Mnemonic / mode / operand shape / flags), pack operand bits
//              onto the form's static `bits`, and emit 4 bytes (or 8 for
//              prefixed POWER10 ops). Branch operands emit Relocation entries
//              that PASS 2 resolves.
//   PASS 1.5 - Rewrite label_defs[] from instruction index to byte offset.
//   PASS 2   - Walk pending relocations and patch in scattered branch offsets.
//
// PowerPC instructions are big-endian on the wire (traditional). On
// little-endian PPC64 (ppc64le), the bytes are simply byte-swapped per
// instruction. The encoder produces BE bytes by default; callers can swap
// post-hoc for LE targets.

MAX_INST_SIZE :: 8     // prefixed instructions

encode_max_code_size :: #force_inline proc "contextless" (n: int) -> int { return n * MAX_INST_SIZE }
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
	n_inst := u32(len(instructions))
	if u32(len(code)) < n_inst * MAX_INST_SIZE {
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
		ok := encode_one_inline(inst, pc, code, u16(i), relocs, errors)
		if !ok {
			return Result{byte_count = pc, success = false}
		}
		pc += u32(inst.length)
	}

	// ---- PASS 1.5: label instruction-idx -> byte offset --------------------
	for &ld in label_defs {
		if ld != LABEL_UNDEFINED {
			idx := u32(ld)
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

	// ---- PASS 2: resolve relocations ---------------------------------------
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
	code:     []u8,
	inst_idx: u16,
	relocs:   ^[dynamic]Relocation,
	errors:   ^[dynamic]Error,
) -> bool {
	forms := ENCODING_TABLE[inst.mnemonic]
	if len(forms) == 0 {
		append(errors, Error{inst_idx = u32(inst_idx), code = .INVALID_MNEMONIC})
		return false
	}

	form: ^Encoding

	// Form-id hint from the decoder's roundtrip (1-based).
	if inst.form_id != 0 && int(inst.form_id) - 1 < len(forms) {
		f := &forms[inst.form_id - 1]
		if encoding_matches_inline(inst, f) { form = f }
	}
	if form == nil {
		for &f in forms {
			if encoding_matches_inline(inst, &f) { form = &f; break }
		}
	}
	if form == nil {
		append(errors, Error{inst_idx = u32(inst_idx), code = .NO_MATCHING_ENCODING})
		return false
	}

	word := form.bits

	// Pack operand bits.
	for k in 0..<4 {
		if form.enc[k] != .NONE {
			word |= pack_operand_inline(&inst.ops[k], form.enc[k], pc, inst_idx, relocs, form)
		}
	}

	// Apply Rc / OE / LK / AA flag bits if user requested them and the form
	// supports them (the form's flags advertise availability).
	if inst.flags.sets_cr0 && form.flags.sets_cr0 { word |= 1 }       // Rc at LSB 0
	if inst.flags.has_oe   && form.flags.has_oe   { word |= 1 << 10 } // OE at LSB 10
	if inst.flags.lk       { word |= 1 }   // LK at LSB 0 for branch forms
	if inst.flags.aa       { word |= 1 << 1 }   // AA at LSB 1 for branches

	// Emit bytes. PowerPC is big-endian on the wire.
	if form.flags.prefixed {
		prefix := PREFIX_BITS_TABLE[inst.mnemonic]
		write_u32_be(code, pc,     prefix)
		write_u32_be(code, pc + 4, word)
		inst.length = 8
	} else {
		write_u32_be(code, pc, word)
		inst.length = 4
	}
	return true
}

// =============================================================================
// Form matching: do the Operand kinds line up with the form's Operand_Type,
// and does the form's mode + feature gate allow this Instruction?
// =============================================================================

@(private="file")
encoding_matches_inline :: #force_inline proc "contextless" (inst: ^Instruction, form: ^Encoding) -> bool {
	// PPC32 entries are usable in either mode; PPC64 entries require .PPC64.
	if form.mode == .PPC64 && inst.mode == .PPC32 { return false }
	return operand_matches_inline(&inst.ops[0], form.ops[0]) &&
		   operand_matches_inline(&inst.ops[1], form.ops[1]) &&
		   operand_matches_inline(&inst.ops[2], form.ops[2]) &&
		   operand_matches_inline(&inst.ops[3], form.ops[3])
}

@(private="file")
operand_matches_inline :: #force_inline proc "contextless" (op: ^Operand, ot: Operand_Type) -> bool {
	#partial switch ot {
	case .NONE:        return op.kind == .NONE
	case .GPR, .GPR_OR_ZERO:
		return op.kind == .REGISTER && reg_is_gpr(op.reg)
	case .FPR:         return op.kind == .REGISTER && reg_is_fpr(op.reg)
	case .VR:          return op.kind == .REGISTER && reg_is_vr(op.reg)
	case .VR128:       return op.kind == .REGISTER && (reg_is_vr128(op.reg) || reg_is_vr(op.reg))
	case .VSR:
		// VSR slots accept both vs-registers and FPR/VR (they alias).
		return op.kind == .REGISTER && (reg_is_vsr(op.reg) || reg_is_fpr(op.reg) || reg_is_vr(op.reg))
	case .CR_FIELD:
		return op.kind == .REGISTER && reg_is_cr(op.reg)
	case .CR_BIT:
		// CR_BIT is a 5-bit CR-bit selector (0..31). It can be carried as
		// either a Register (REG_CR class, low byte = bit number) or as a
		// plain Immediate (bit number). The decoder always emits Register
		// form, but user code may construct either.
		return (op.kind == .REGISTER && reg_is_cr(op.reg)) || op.kind == .IMMEDIATE
	case .SPR:         return op.kind == .REGISTER && reg_is_spr(op.reg)
	case .IMM, .SIMM, .UIMM:
		return op.kind == .IMMEDIATE
	case .REL:         return op.kind == .RELATIVE
	case .MEM:         return op.kind == .MEMORY
	case .BO, .BH:     return op.kind == .IMMEDIATE
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
	#partial switch enc {
	case .NONE, .IMPL: return 0

	// ---- Integer register slots ----
	case .RT, .RS:     return (u32(reg_hw(op.reg)) & 0x1F) << 21
	case .RA:          return (u32(reg_hw(op.reg)) & 0x1F) << 16
	case .RB:          return (u32(reg_hw(op.reg)) & 0x1F) << 11
	case .RC:          return (u32(reg_hw(op.reg)) & 0x1F) << 6

	// ---- Floating-point ----
	case .FRT:         return (u32(reg_hw(op.reg)) & 0x1F) << 21
	case .FRA:         return (u32(reg_hw(op.reg)) & 0x1F) << 16
	case .FRB:         return (u32(reg_hw(op.reg)) & 0x1F) << 11
	case .FRC:         return (u32(reg_hw(op.reg)) & 0x1F) << 6

	// ---- AltiVec ----
	case .VRT:         return (u32(reg_hw(op.reg)) & 0x1F) << 21
	case .VRA:         return (u32(reg_hw(op.reg)) & 0x1F) << 16
	case .VRB:         return (u32(reg_hw(op.reg)) & 0x1F) << 11
	case .VRC:         return (u32(reg_hw(op.reg)) & 0x1F) << 6

	// ---- VSX (split 5+1 register fields) ----
	case .XT:
		n := u32(reg_hw(op.reg)) & 0x3F
		return ((n & 0x1F) << 21) | ((n >> 5) & 1)         // TX at bit 0
	case .XA:
		n := u32(reg_hw(op.reg)) & 0x3F
		return ((n & 0x1F) << 16) | (((n >> 5) & 1) << 2)  // AX at bit 2
	case .XB:
		n := u32(reg_hw(op.reg)) & 0x3F
		return ((n & 0x1F) << 11) | (((n >> 5) & 1) << 1)  // BX at bit 1
	case .XC:
		n := u32(reg_hw(op.reg)) & 0x3F
		return ((n & 0x1F) << 6)  | (((n >> 5) & 1) << 3)  // CX at bit 3

	// ---- VMX128 (Xbox 360 Xenon — 7-bit register fields) ----
	// VMX128 encodes the extra 2 bits of each 7-bit register index in
	// scattered positions (bits 5..6 for VDh, 3..4 for VBh, etc.). However
	// those positions ALSO carry per-form XO bits, so a generic encoder
	// can't pack the high register bits without breaking opcode resolution.
	// We use 5-bit packing (vr0..vr31) only — matching the AltiVec subset
	// common in real Xbox 360 code. Users targeting vr32..vr127 must edit
	// the form's bake-everything bits directly.
	case .VRT128:  return (u32(reg_hw(op.reg)) & 0x1F) << 21
	case .VRA128:  return (u32(reg_hw(op.reg)) & 0x1F) << 16
	case .VRB128:  return (u32(reg_hw(op.reg)) & 0x1F) << 11
	case .VRC128:  return (u32(reg_hw(op.reg)) & 0x1F) << 6

	// ---- Condition register fields ----
	case .BF:          return (u32(reg_hw(op.reg)) & 0x7) << 23
	case .BFA:         return (u32(reg_hw(op.reg)) & 0x7) << 18
	case .BT:          return (u32(reg_hw(op.reg)) & 0x1F) << 21
	case .BA:          return (u32(reg_hw(op.reg)) & 0x1F) << 16
	case .BB:          return (u32(reg_hw(op.reg)) & 0x1F) << 11
	case .BO_FIELD:
		if op.kind == .REGISTER { return (u32(reg_hw(op.reg)) & 0x1F) << 21 }
		return (u32(op.immediate) & 0x1F) << 21
	case .BI_FIELD:
		if op.kind == .REGISTER { return (u32(reg_hw(op.reg)) & 0x1F) << 16 }
		return (u32(op.immediate) & 0x1F) << 16
	case .BH_FIELD:
		if op.kind == .REGISTER { return (u32(reg_hw(op.reg)) & 0x3) << 11 }
		return (u32(op.immediate) & 0x3) << 11

	// ---- SPR (10-bit split with halves swapped) ----
	case .SPR_FIELD:
		n := u32(reg_hw(op.reg)) & 0x3FF
		return ((n & 0x1F) << 11) | (((n >> 5) & 0x1F) << 16)

	// ---- Immediates ----
	case .D16:         return u32(op.immediate) & 0xFFFF
	case .UI16:        return u32(op.immediate) & 0xFFFF
	case .DS14:        return u32(op.immediate) & 0xFFFC          // signed, low 2 zero
	case .DQ12:        return u32(op.immediate) & 0xFFF0          // signed, low 4 zero
	case .SH5:         return (u32(op.immediate) & 0x1F) << 11
	case .SH6:
		// 6-bit MD-form shift: low 5 at bits 11..15, bit 5 at bit 1
		v := u32(op.immediate) & 0x3F
		return ((v & 0x1F) << 11) | (((v >> 5) & 1) << 1)
	case .MB5:         return (u32(op.immediate) & 0x1F) << 6
	case .ME5:         return (u32(op.immediate) & 0x1F) << 1
	case .MB6:
		v := u32(op.immediate) & 0x3F
		return ((v & 0x1F) << 6) | (((v >> 5) & 1) << 5)
	case .SIMM_5, .UIMM_5: return (u32(op.immediate) & 0x1F) << 16
	case .UIMM_4:          return (u32(op.immediate) & 0xF)  << 16
	case .UIMM_2:          return (u32(op.immediate) & 0x3)  << 16
	case .FXM:             return (u32(op.immediate) & 0xFF) << 12
	case .L_FIELD:         return (u32(op.immediate) & 0x1)  << 21
	case .TO_FIELD:        return (u32(op.immediate) & 0x1F) << 21
	case .NB_FIELD:        return (u32(op.immediate) & 0x1F) << 11
	case .SR_FIELD:        return (u32(op.immediate) & 0xF)  << 16
	case .CRM:             return (u32(op.immediate) & 0xFF) << 12
	case .DCMX:            return (u32(op.immediate) & 0x7F) << 16

	// ---- Memory addressing composites ----
	case .OFFSET_BASE_D:
		return ((u32(reg_hw(op.mem.base)) & 0x1F) << 16) | (u32(op.mem.disp) & 0xFFFF)
	case .OFFSET_BASE_DS:
		return ((u32(reg_hw(op.mem.base)) & 0x1F) << 16) | (u32(op.mem.disp) & 0xFFFC)
	case .OFFSET_BASE_DQ:
		return ((u32(reg_hw(op.mem.base)) & 0x1F) << 16) | (u32(op.mem.disp) & 0xFFF0)
	case .OFFSET_BASE_X, .OFFSET_VSX_X:
		return ((u32(reg_hw(op.mem.base)) & 0x1F) << 16) | ((u32(reg_hw(op.mem.index)) & 0x1F) << 11)

	// ---- PC-relative branches ----
	case .BRANCH_LI:
		// I-form: 24-bit signed << 2 at bits 2..25. Emit relocation; resolver
		// fills in. Word at this stage has 0 in the displacement.
		if op.kind == .RELATIVE {
			append(relocs, Relocation{
				offset   = pc,
				label_id = u32(op.relative),
				type     = .BRANCH_I_24,
				size     = 4,
				inst_idx = inst_idx,
			})
		}
		return 0
	case .BRANCH_BD:
		// B-form: 14-bit signed << 2 at bits 2..15.
		if op.kind == .RELATIVE {
			append(relocs, Relocation{
				offset   = pc,
				label_id = u32(op.relative),
				type     = .BRANCH_B_14,
				size     = 4,
				inst_idx = inst_idx,
			})
		}
		return 0

	// ---- Flag bits packed via packer (the encode_one_inline() flag pass handles
	//      these for user-set values; included here for completeness) ----
	case .AA_FLAG:     return 0
	case .LK_FLAG:     return 0
	case .RC_FLAG:     return 0
	case .OE_FLAG:     return 0
	}
	return 0
}

// =============================================================================
// Pass 2 — relocation resolver
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
	case .BRANCH_I_24:
		// PC = address of this instruction (PPC convention).
		rel := i32(target) - i32(r.offset) + r.addend
		if rel & 3 != 0 || rel < -(1 << 25) || rel >= (1 << 25) {
			append(errors, Error{inst_idx = u32(r.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		// 24-bit LI field at bits 2..25 LSB (= 6..29 MSB).
		li := u32(rel) & 0x03FFFFFC
		word := read_u32_be(code, r.offset)
		word = (word & 0xFC000003) | li
		write_u32_be(code, r.offset, word)
		return true

	case .BRANCH_B_14:
		rel := i32(target) - i32(r.offset) + r.addend
		if rel & 3 != 0 || rel < -(1 << 15) || rel >= (1 << 15) {
			append(errors, Error{inst_idx = u32(r.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		// 14-bit BD field at bits 2..15 LSB (= 16..29 MSB).
		bd := u32(rel) & 0xFFFC
		word := read_u32_be(code, r.offset)
		word = (word & 0xFFFF0003) | bd
		write_u32_be(code, r.offset, word)
		return true

	case .PREFIXED_34:
		// Power ISA 3.1: 34-bit signed at IMM18(prefix)||D(suffix).
		// Prefix occupies bytes r.offset .. r.offset+3 (BE), suffix bytes
		// r.offset+4 .. r.offset+7.
		rel := i64(target) - i64(r.offset) + i64(r.addend)
		if rel < -(i64(1) << 33) || rel >= (i64(1) << 33) {
			append(errors, Error{inst_idx = u32(r.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		v := u64(rel) & ((u64(1) << 34) - 1)
		pfx := read_u32_be(code, r.offset)
		sfx := read_u32_be(code, r.offset + 4)
		// IMM18 = high 18 bits, D = low 16
		imm18 := u32(v >> 16) & 0x3FFFF
		d16   := u32(v) & 0xFFFF
		pfx = (pfx & 0xFFFC0000) | imm18
		sfx = (sfx & 0xFFFF0000) | d16
		write_u32_be(code, r.offset,     pfx)
		write_u32_be(code, r.offset + 4, sfx)
		return true

	case:
		return false
	}
}

// =============================================================================
// Big-endian word I/O
// =============================================================================

@(private="package")
write_u32_be :: #force_inline proc "contextless" (code: []u8, offset, word: u32) {
	code[offset+0] = u8(word >> 24)
	code[offset+1] = u8(word >> 16)
	code[offset+2] = u8(word >>  8)
	code[offset+3] = u8(word)
}

@(private="package")
read_u32_be :: #force_inline proc "contextless" (code: []u8, offset: u32) -> u32 {
	return (u32(code[offset+0]) << 24) |
		   (u32(code[offset+1]) << 16) |
		   (u32(code[offset+2]) <<  8) |
			u32(code[offset+3])
}
