package rexcode_ppc_vle

// =============================================================================
// PowerPC VLE Encoder
// =============================================================================
//
// Variable-length: 2 bytes for `se_*`, 4 bytes for `e_*`. Big-endian on wire.
//
// Each ENCODING_TABLE entry describes a form: its fixed `bits` (primary
// opcode + sub-op + baked operand defaults) and operand encodings in
// `enc[k]`. The encoder ORs the operand-packed bits onto `bits`.

MAX_INST_SIZE :: 4

encode_max_code_size :: #force_inline proc "contextless" (n: int) -> int { return n * 4 }
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

	for i in 0..<n_inst {
		inst_pc[i] = pc
		inst := &instructions[i]
		ok := encode_one_inline(inst, pc, code, u16(i), relocs, errors)
		if !ok { return Result{byte_count = pc, success = false} }
		pc += u32(inst.length)
	}

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
	if inst.form_id != 0 && int(inst.form_id) - 1 < len(forms) {
		form = &forms[inst.form_id - 1]
	} else {
		form = &forms[0]
	}

	word := form.bits

	for k in 0..<4 {
		if form.enc[k] != .NONE {
			word |= pack_operand_inline(&inst.ops[k], form.enc[k], pc, inst_idx, relocs)
		}
	}

	if form.flags.short {
		write_u16_be(code, pc, u16(word))
		inst.length = 2
	} else {
		write_u32_be(code, pc, word)
		inst.length = 4
	}
	return true
}

// VLE 4-bit register encoding: maps r0..r7 → 0..7 and r24..r31 → 8..15.
@(private="file")
encode_vle16_reg :: #force_inline proc "contextless" (r: Register) -> u32 {
	n := u32(reg_hw(r)) & 0x1F
	if n < 8     { return n }
	if n >= 24   { return n - 16 }
	return 0xF   // invalid in VLE16 — best-effort fallback
}

@(private="file")
pack_operand_inline :: #force_inline proc(
	op:       ^Operand,
	enc:      Operand_Encoding,
	pc:       u32,
	inst_idx: u16,
	relocs:   ^[dynamic]Relocation,
) -> u32 {
	#partial switch enc {
	case .NONE, .IMPL: return 0

	// 32-bit GPR slots
	case .RT, .RS: return (u32(reg_hw(op.reg)) & 0x1F) << 21
	case .RA:      return (u32(reg_hw(op.reg)) & 0x1F) << 16
	case .RB:      return (u32(reg_hw(op.reg)) & 0x1F) << 11

	// 32-bit immediates
	case .UI16:    return u32(op.immediate) & 0xFFFF
	case .SI16:    return u32(op.immediate) & 0xFFFF
	case .LI20:
		v := u32(op.immediate) & 0xFFFFF
		return ((v >> 16) & 0xF) << 17 | ((v >> 11) & 0x1F) << 11 | (v & 0x7FF)
	case .SCI8:
		// Pack the low 8 bits of the value directly at bits 0..7.
		return u32(op.immediate) & 0xFF

	// 32-bit branches
	case .B15:
		if op.kind == .RELATIVE {
			append(relocs, Relocation{
				offset = pc, label_id = u32(op.relative),
				type = .BRANCH_BD15, size = 4, inst_idx = inst_idx,
			})
		}
		return 0
	case .B24:
		if op.kind == .RELATIVE {
			append(relocs, Relocation{
				offset = pc, label_id = u32(op.relative),
				type = .BRANCH_BD24, size = 4, inst_idx = inst_idx,
			})
		}
		return 0
	case .BO32:
		v := u32(op.immediate) if op.kind == .IMMEDIATE else u32(reg_hw(op.reg))
		return (v & 0x3) << 20
	case .BI32:
		v := u32(op.immediate) if op.kind == .IMMEDIATE else u32(reg_hw(op.reg))
		return (v & 0xF) << 16

	// 16-bit register fields
	case .RX:   return encode_vle16_reg(op.reg)
	case .RY:   return encode_vle16_reg(op.reg) << 4
	case .RZ:   return encode_vle16_reg(op.reg) << 4

	// 16-bit immediates
	case .UI5:  return (u32(op.immediate) & 0x1F) << 4
	case .UI7:  return (u32(op.immediate) & 0x7F)

	// 16-bit branches
	case .B8:
		if op.kind == .RELATIVE {
			append(relocs, Relocation{
				offset = pc, label_id = u32(op.relative),
				type = .BRANCH_BD8, size = 2, inst_idx = inst_idx,
			})
		}
		return 0
	case .BO16:
		v := u32(op.immediate) if op.kind == .IMMEDIATE else u32(reg_hw(op.reg))
		return (v & 1) << 10
	case .BI16:
		v := u32(op.immediate) if op.kind == .IMMEDIATE else u32(reg_hw(op.reg))
		return (v & 0x3) << 8

	// Memory composites
	case .OFFSET_BASE_D:
		return (u32(reg_hw(op.mem.base)) & 0x1F) << 16 | (u32(op.mem.disp) & 0xFFFF)
	case .OFFSET_BASE_SD4:
		return encode_vle16_reg(op.mem.base) | (u32(op.mem.disp) & 0xF) << 8
	case .OFFSET_BASE_SD4_H:
		return encode_vle16_reg(op.mem.base) | ((u32(op.mem.disp) >> 1) & 0xF) << 8
	case .OFFSET_BASE_SD4_W:
		return encode_vle16_reg(op.mem.base) | ((u32(op.mem.disp) >> 2) & 0xF) << 8
	}
	return 0
}

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
	case .BRANCH_BD8:
		rel := i32(target) - i32(r.offset)
		if rel & 1 != 0 || rel < -256 || rel >= 256 {
			append(errors, Error{inst_idx = u32(r.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		// BD8 stores displacement >> 1 in bits 0..7 of halfword.
		bd := u16((rel >> 1) & 0xFF)
		hw := read_u16_be(code, r.offset)
		hw = (hw & 0xFF00) | bd
		write_u16_be(code, r.offset, hw)
		return true

	case .BRANCH_BD15:
		rel := i32(target) - i32(r.offset)
		if rel & 1 != 0 || rel < -(1 << 15) || rel >= (1 << 15) {
			append(errors, Error{inst_idx = u32(r.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		// BD15 stores displacement[15:1] at bits 1..15 (bit 0 = LK, fixed).
		bd := u32(rel) & 0xFFFE
		word := read_u32_be(code, r.offset)
		word = (word & 0xFFFF0001) | bd
		write_u32_be(code, r.offset, word)
		return true

	case .BRANCH_BD24:
		rel := i32(target) - i32(r.offset)
		if rel & 1 != 0 || rel < -(1 << 24) || rel >= (1 << 24) {
			append(errors, Error{inst_idx = u32(r.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		// BD24 stores displacement[24:1] at bits 1..24 (bit 0 = LK, fixed).
		bd := u32(rel) & 0x01FFFFFE
		word := read_u32_be(code, r.offset)
		word = (word & 0xFE000001) | bd
		write_u32_be(code, r.offset, word)
		return true

	case:
		return false
	}
}

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

@(private="package")
write_u16_be :: #force_inline proc "contextless" (code: []u8, offset: u32, hw: u16) {
	code[offset+0] = u8(hw >> 8)
	code[offset+1] = u8(hw)
}

@(private="package")
read_u16_be :: #force_inline proc "contextless" (code: []u8, offset: u32) -> u16 {
	return (u16(code[offset+0]) << 8) | u16(code[offset+1])
}
