// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_x86

// =============================================================================
// SECTION: 7.x Emit Descriptor (precompiled per-form recipe)
// =============================================================================
//
// Each ENCODE_FORMS entry is a compact description the encoder *interprets* at
// emit time: walk enc.ops to map operands to slots, switch on the escape ladder,
// select the mandatory prefix, decide the ModR/M reg source, etc. For the common
// legacy/SSE forms that work is identical on every instruction that shares the
// form, so we precompute it once into a flat Form_Recipe that the hot path can
// replay straight-line.
//
// Anything the flat recipe can't represent verbatim -- VEX/EVEX, 16-bit
// operand-size (66h), x87 fixed-ModR/M, moffs/far/rel/implicit operands -- is
// marked `eligible = false` and falls back to the existing interpreter, which
// stays the source of truth for correctness.
//
// ENCODE_RECIPES is produced by the tablegen (form_to_recipe over every form)
// and #loaded from x86.encode_recipes.bin like every other table -- see the note
// by form_to_recipe below.

Form_Recipe :: struct {
	prefix:     u8,      // mandatory legacy prefix emitted before REX (0 = none)
	opcode:     [3]u8,   // escape + opcode: [op] / [0F,op] / [0F,38,op] / [0F,3A,op]
	opcode_len: u8,      // 1..3
	ext:        u8,      // ModR/M reg ext digit (when reg_from_ext) or /digit source
	rm_op:      i8,      // user operand index -> ModR/M r/m field   (-1 = none)
	reg_op:     i8,      // user operand index -> ModR/M reg field   (-1 = none)
	opr_op:     i8,      // user operand index -> +rb opcode register (-1 = none)
	imm_op:     i8,      // user operand index -> immediate          (-1 = none)
	imm_size:   u8,      // 1/2/4/8 when imm_op >= 0
	flags:      Recipe_Flags,
}

Recipe_Flags :: bit_field u8 {
	eligible:     bool | 1,  // emit via the recipe fast path; else fall back
	reg_from_ext: bool | 1,  // ModR/M reg field = ext digit (opcode extension), not reg_op
	has_modrm:    bool | 1,  // a ModR/M byte is emitted (rm or reg operand present)
	force_rex_w:  bool | 1,  // always emit REX.W
	could_spl:    bool | 1,  // 8-bit form: an operand may be SPL/BPL/SIL/DIL (forces REX)
	default_64:   bool | 1,  // default 64-bit operand size (PUSH/POP/CALL/...)
}

// Derive the flat recipe for one encoding form. Pure; identical whether called
// here at startup or (later) from the table generator.
@(require_results)
form_to_recipe :: proc "contextless" (enc: ^Encoding) -> (r: Form_Recipe) {
	r.rm_op, r.reg_op, r.opr_op, r.imm_op = -1, -1, -1, -1

	// Escape + opcode blob.
	switch enc.flags.esc {
	case .NONE:  r.opcode = {enc.opcode, 0, 0};       r.opcode_len = 1
	case ._0F:   r.opcode = {0x0F, enc.opcode, 0};    r.opcode_len = 2
	case ._0F38: r.opcode = {0x0F, 0x38, enc.opcode}; r.opcode_len = 3
	case ._0F3A: r.opcode = {0x0F, 0x3A, enc.opcode}; r.opcode_len = 3
	}

	mand := [4]u8{0, 0x66, 0xF3, 0xF2}
	r.prefix = mand[enc.flags.prefix]
	// Operand-less 16-bit forms (CBW/CWD/MOVSW/...) carry no GPR16 operand to
	// trigger the operand-size prefix, so they request it explicitly via opsize_16.
	// (None of them also carry a mandatory prefix, so this never clobbers one.)
	if enc.flags.opsize_16 && r.prefix == 0 {
		r.prefix = 0x66
	}
	r.ext = enc.ext
	r.flags.reg_from_ext = enc.flags.modrm_reg_ext
	r.flags.force_rex_w  = enc.flags.force_rex_w
	r.flags.default_64   = enc.flags.default_64

	eligible     := enc.flags.vex_type == .NONE
	has_16bit    := false
	has_8bit     := false
	has_implicit := false
	has_exotic   := false

	// Walk the form's operands, mapping each encoded role to the *user* operand
	// index (implicit operands are not user-provided and don't advance it).
	user_idx := 0
	for op_type, i in enc.ops {
		if op_type == .NONE { break }
		if is_implicit_op_inline(op_type) {
			has_implicit = true
			continue
		}
		role_idx := i8(user_idx)
		user_idx += 1

		#partial switch op_type {
		case .R16, .RM16, .M16, .IMM16:
			has_16bit = true
		case .R8, .RM8, .M8:
			has_8bit = true
		case .REL8, .REL32, .MOFFS8, .MOFFS16, .MOFFS32, .MOFFS64,
		     .PTR16_16, .PTR16_32, .PTR16_64, .M16_16, .M16_32, .M16_64,
		     .SREG, .CR, .DR, .STI, .MM, .MM_M64,
		     .K, .K_M8, .K_M16, .K_M32, .K_M64:
			has_exotic = true
		}

		#partial switch enc.enc[i] {
		case .MR:   r.rm_op  = role_idx
		case .REG:  r.reg_op = role_idx
		case .OP_R: r.opr_op = role_idx
		case .IB:   r.imm_op = role_idx; r.imm_size = 1
		case .IW:   r.imm_op = role_idx; r.imm_size = 2
		case .ID:   r.imm_op = role_idx; r.imm_size = 4
		case .IQ:   r.imm_op = role_idx; r.imm_size = 8
		case .VVVV, .AAA, .IS4:
			eligible = false
		}
	}

	r.flags.has_modrm = r.rm_op >= 0 || r.reg_op >= 0
	r.flags.could_spl = has_8bit

	// x87 ST(i) / 0F NOP-class forms emit enc.ext as a literal ModR/M byte; the
	// fast path doesn't model that, so they fall back.
	is_x87 := enc.opcode >= 0xD8 && enc.opcode <= 0xDF
	fixed_modrm := enc.ext >= 0xC0 && !r.flags.has_modrm && (enc.flags.esc != .NONE || is_x87)

	r.flags.eligible = eligible && !has_16bit && !has_implicit && !has_exotic && !fixed_modrm
	return
}

// ENCODE_RECIPES (parallel to ENCODE_FORMS) is generated, not built here: the
// tablegen runs form_to_recipe over every form, serializes the result to
// x86.encode_recipes.bin, and tables.odin #loads it. So form_to_recipe above is
// a tablegen-time helper -- it is not called on the encode hot path.

@(private)
op_is_spl :: #force_inline proc "contextless" (op: ^Operand) -> bool {
	// SPL/BPL/SIL/DIL (GPR8 hw 4..7) require any REX to encode (else they read
	// as AH/CH/DH/BH).
	return op.kind == .REGISTER && reg_class(op.reg) == REG_GPR8 && reg_hw(op.reg) >= 4 && reg_hw(op.reg) <= 7
}

// Recipe-driven straight-line emit. Handles the eligible legacy/SSE forms with a
// register (or absent) r/m and a literal immediate -- exactly the cases the
// caller guards for. Produces byte-identical output to the interpreter; anything
// outside that envelope is rejected by the caller and never reaches here.
@(require_results)
emit_recipe :: #force_inline proc "contextless" (recipe: ^Form_Recipe, inst: ^Instruction, out: []u8) -> (pos: u32) {
	// Mandatory prefix (66/F3/F2 for SSE); operand-size 66h forms are ineligible.
	if recipe.prefix != 0 {
		out[pos] = recipe.prefix
		pos += 1
	}

	// REX, OR-masked from the register-bearing roles (no memory base/index here).
	rex: u8 = recipe.flags.force_rex_w ? 0x48 : 0
	if recipe.reg_op >= 0 {
		op := &inst.ops[recipe.reg_op]
		rex |= bmask(op.kind == .REGISTER && reg_needs_rex(op.reg)) & 0x44
	}
	if recipe.rm_op >= 0 {
		op := &inst.ops[recipe.rm_op]
		is_reg := op.kind == .REGISTER
		is_mem := op.kind == .MEMORY
		m := op.mem   // union bytes; only used when is_mem
		rex |= bmask(is_reg && reg_needs_rex(op.reg))           & 0x41
		rex |= bmask(is_mem && mem_has_base(m)  && m.base_ext)  & 0x41
		rex |= bmask(is_mem && mem_has_index(m) && m.index_ext) & 0x42
	}
	if recipe.opr_op >= 0 {
		op := &inst.ops[recipe.opr_op]
		rex |= bmask(op.kind == .REGISTER && reg_needs_rex(op.reg)) & 0x41
	}
	if recipe.flags.could_spl && rex == 0 {
		spl := false
		if recipe.rm_op  >= 0 { spl = spl || op_is_spl(&inst.ops[recipe.rm_op])  }
		if recipe.reg_op >= 0 { spl = spl || op_is_spl(&inst.ops[recipe.reg_op]) }
		if recipe.opr_op >= 0 { spl = spl || op_is_spl(&inst.ops[recipe.opr_op]) }
		rex |= bmask(spl) & 0x40
	}
	if rex != 0 {
		out[pos] = rex
		pos += 1
	}

	// Opcode blob; for +rb forms the register index folds into the last byte.
	ob := recipe.opcode
	if recipe.opr_op >= 0 {
		op := &inst.ops[recipe.opr_op]
		if op.kind == .REGISTER {
			ob[recipe.opcode_len - 1] += reg_hw(op.reg) & 0x7
		}
	}
	for j in 0..<recipe.opcode_len {
		out[pos] = ob[j]
		pos += 1
	}

	// ModR/M (+ SIB + displacement); the r/m operand is a register or memory.
	// The memory addressing mirrors the interpreter's path byte-for-byte.
	if recipe.flags.has_modrm {
		reg_field: u8 = recipe.ext & 0x7
		if !recipe.flags.reg_from_ext {
			reg_field = 0
			if recipe.reg_op >= 0 {
				op := &inst.ops[recipe.reg_op]
				if op.kind == .REGISTER { reg_field = reg_hw(op.reg) & 0x7 }
			}
		}

		mod:               u8  = 0
		rm:                u8  = 0
		has_sib                := false
		sib:               u8  = 0
		disp:              i32 = 0
		displacement_size: u8  = 0

		if recipe.rm_op >= 0 {
			mr_op := &inst.ops[recipe.rm_op]
			#partial switch mr_op.kind {
			case .REGISTER:
				mod = 0b11
				rm  = reg_hw(mr_op.reg) & 0x07
			case .MEMORY:
				m := mr_op.mem
				if mem_is_rip_relative(m) {
					mod = 0b00; rm = 0b101
					disp = m.disp; displacement_size = 4
				} else if !mem_has_base(m) && !mem_has_index(m) {
					mod = 0b00; rm = 0b100
					has_sib = true; sib = 0b00_100_101
					disp = m.disp; displacement_size = 4
				} else {
					base_hw    := m.base_hw
					has_index  := mem_has_index(m)
					disp_value := m.disp
					needs_sib  := has_index || (base_hw & 0x07) == 4
					has_base   := mem_has_base(m)
					is_rbp     := (base_hw & 0x07) == 5
					is_zero    := disp_value == 0
					fits8      := disp_value >= -128 && disp_value <= 127
					disp = disp_value

					if needs_sib {
						has_sib = true
						rm = 0b100
						scale: u8 = 0
						switch mem_scale(m) {
						case 2: scale = 1
						case 4: scale = 2
						case 8: scale = 3
						}
						idx      := has_index ? (m.index_hw & 0x07) : u8(0b100)
						base_sib := has_base  ? (base_hw   & 0x07) : u8(0b101)
						sib = (scale << 6) | (idx << 3) | base_sib
						no_disp := has_base && is_zero && !(has_base && is_rbp)
						displacement_size = !has_base ? 4 : (no_disp ? 0 : (fits8 ? 1 : 4))
						mod               = !has_base ? 0b00 : (no_disp ? 0b00 : (fits8 ? 0b01 : 0b10))
					} else {
						rm = base_hw & 0x07
						no_disp := is_zero && !is_rbp
						displacement_size = no_disp ? 0 : (fits8 ? 1 : 4)
						mod               = no_disp ? 0b00 : (fits8 ? 0b01 : 0b10)
					}
				}
			}
		}

		out[pos] = (mod << 6) | (reg_field << 3) | rm
		pos += 1
		if has_sib {
			out[pos] = sib
			pos += 1
		}
		for _ in 0..<displacement_size {
			out[pos] = u8(disp & 0xFF)
			disp >>= 8
			pos += 1
		}
	}

	// Immediate (literal; .RELATIVE/label immediates are rejected by the caller).
	if recipe.imm_op >= 0 {
		v := u64(inst.ops[recipe.imm_op].immediate)
		switch recipe.imm_size {
		case 1:
			out[pos] = u8(v)
			pos += 1
		case 2:
			out[pos] = u8(v); out[pos+1] = u8(v >> 8)
			pos += 2
		case 4:
			out[pos] = u8(v);       out[pos+1] = u8(v >> 8); out[pos+2] = u8(v >> 16); out[pos+3] = u8(v >> 24)
			pos += 4
		case 8:
			out[pos]   = u8(v);       out[pos+1] = u8(v >> 8);  out[pos+2] = u8(v >> 16); out[pos+3] = u8(v >> 24)
			out[pos+4] = u8(v >> 32); out[pos+5] = u8(v >> 40); out[pos+6] = u8(v >> 48); out[pos+7] = u8(v >> 56)
			pos += 8
		}
	}

	return
}
