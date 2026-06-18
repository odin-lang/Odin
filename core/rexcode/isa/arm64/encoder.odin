// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm64

// =============================================================================
// AArch64 ENCODER
// =============================================================================
//
// Fixed-width 4-byte ISA. Two-pass design mirroring mips/encoder.odin /
// riscv/encoder.odin. The interesting bits vs other arches:
//
//   * Compound operands: SHIFTED_REG (Rm + shift type + amount) and
//     EXTENDED_REG (Rm + extend + amount) are packed by the RM encoder
//     by inspecting the operand kind -- a plain REGISTER decays to
//     LSL #0 / UXTX, amount=0.
//
//   * Three split-immediate scatter patterns:
//       BRANCH_PG21 -- 21-bit imm split as immlo[30:29] + immhi[23:5]
//                      (ADR / ADRP)
//       TBZ_BIT     -- 6-bit bit position split as b5[31] + b40[23:19]
//                      (TBZ / TBNZ)
//       SYS_FIELD   -- 15-bit (op0:op1:CRn:CRm:op2) at bits 19:5
//
//   * Loads/stores with the unsigned-offset (LDR/STR) form scale the
//     user displacement by data size (1/2/4/8) derived from bits[31:30]
//     of the encoding. LDP/STP pair forms scale a signed 7-bit field.
//
//   * Endianness: AArch64 standard mode stores instructions LE; BE-32
//     (instructions stored big-endian) is legacy and rare. Parameter
//     defaults to LITTLE.

MAX_INST_SIZE :: 4

encode_max_code_size :: #force_inline proc "contextless" (n: int) -> int { return n * 4 }
encode_max_relocation_count :: #force_inline proc "contextless" (n: int) -> int { return n }

encode :: proc(
	instructions: []Instruction,
	label_defs:   []Label_Definition,
	code:         []u8,
	relocs:       ^[dynamic]Relocation,
	errors:       ^[dynamic]Error,
	endianness:   Endianness = .LITTLE,
	resolve:      bool       = true,
	base_address: u64        = 0,
) -> (byte_count: u32, ok: bool) {
	n_inst := u32(len(instructions))
	if u32(len(code)) < n_inst * 4 {
		append(errors, Error{inst_idx = 0, code = .BUFFER_OVERFLOW})
		return
	}

	errors_start  := u32(len(errors))
	pending_start := u32(len(relocs))

	// ---- PASS 1 -----------------------------------------------------------
	for i in 0..<n_inst {
		inst := &instructions[i]
		word := encode_one_inline(inst, byte_count, u16(i), relocs, errors) or_return
		write_u32(code, byte_count, word, endianness)
		byte_count += 4
	}

	// ---- PASS 1.5: fixed-width => *4 -------------------------------------
	for &ld in label_defs {
		if ld != LABEL_UNDEFINED {
			ld = Label_Definition(u32(ld) * 4)
		}
	}

	if !resolve {
		ok = u32(len(errors)) == errors_start
		return
	}

	// ---- PASS 2: resolve relocations -------------------------------------
	n_relocs  := u32(len(relocs))
	write_idx := pending_start
	for read_idx in pending_start..<n_relocs {
		r := relocs[read_idx]
		if resolve_relocation_inline(code, label_defs, &r, endianness, base_address, errors) {
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
// Internal: encode one instruction
// =============================================================================

@(private="file")
encode_one_inline :: #force_inline proc(
	inst:     ^Instruction,
	pc:       u32,
	inst_idx: u16,
	relocs:   ^[dynamic]Relocation,
	errors:   ^[dynamic]Error,
) -> (word: u32, ok: bool) {
	if inst.mnemonic == .INVALID {
		append(errors, Error{inst_idx = u32(inst_idx), code = .INVALID_MNEMONIC})
		return 0, false
	}
	forms := encoding_forms(inst.mnemonic)
	if len(forms) == 0 {
		append(errors, Error{inst_idx = u32(inst_idx), code = .INVALID_MNEMONIC})
		return 0, false
	}

	form: ^Encoding
	for &f in forms {
		if encoding_matches_inline(inst, &f) { form = &f; break }
	}
	if form == nil {
		append(errors, Error{inst_idx = u32(inst_idx), code = .NO_MATCHING_ENCODING})
		return 0, false
	}

	word = form.bits
	if form.enc[0] != .NONE { word |= pack_operand_inline(&inst.ops[0], form.enc[0], form, pc, inst_idx, relocs) }
	if form.enc[1] != .NONE { word |= pack_operand_inline(&inst.ops[1], form.enc[1], form, pc, inst_idx, relocs) }
	if form.enc[2] != .NONE { word |= pack_operand_inline(&inst.ops[2], form.enc[2], form, pc, inst_idx, relocs) }
	if form.enc[3] != .NONE { word |= pack_operand_inline(&inst.ops[3], form.enc[3], form, pc, inst_idx, relocs) }
	return word, true
}

@(private="file")
encoding_matches_inline :: #force_inline proc "contextless" (
	inst: ^Instruction, form: ^Encoding,
) -> bool {
	return  operand_matches_inline(&inst.ops[0], form.ops[0], form) &&
			operand_matches_inline(&inst.ops[1], form.ops[1], form) &&
			operand_matches_inline(&inst.ops[2], form.ops[2], form) &&
			operand_matches_inline(&inst.ops[3], form.ops[3], form)
}

@(private="file")
operand_matches_inline :: #force_inline proc "contextless" (
	op: ^Operand, ot: Operand_Type, form: ^Encoding,
) -> bool {
	switch ot {
	case .NONE:
		return op.kind == .NONE
	case .W_REG:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_W
	case .X_REG:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_X
	case .WSP_REG:
		return op.kind == .REGISTER && (reg_class(op.reg) == REG_W || reg_class(op.reg) == REG_WSP)
	case .XSP_REG:
		return op.kind == .REGISTER && (reg_class(op.reg) == REG_X || reg_class(op.reg) == REG_XSP)
	case .W_SHIFTED:
		if op.kind == .REGISTER     { return reg_class(op.reg) == REG_W }
		if op.kind == .SHIFTED_REG  { return reg_class(op.shifted.reg) == REG_W }
		return false
	case .X_SHIFTED:
		if op.kind == .REGISTER     { return reg_class(op.reg) == REG_X }
		if op.kind == .SHIFTED_REG  { return reg_class(op.shifted.reg) == REG_X }
		return false
	case .W_EXTENDED:
		// The extend type selects W vs X for the inner reg; accept either
		// and let the encoder pack option = extend faithfully.
		if op.kind == .REGISTER     { return reg_class(op.reg) == REG_W }
		if op.kind == .EXTENDED_REG {
			c := reg_class(op.extended.reg)
			return c == REG_W || c == REG_X
		}
		return false
	case .X_EXTENDED:
		if op.kind == .REGISTER     { return reg_class(op.reg) == REG_X }
		if op.kind == .EXTENDED_REG {
			c := reg_class(op.extended.reg)
			return c == REG_W || c == REG_X
		}
		return false
	case .B_REG: return op.kind == .REGISTER && reg_class(op.reg) == REG_B
	case .H_REG: return op.kind == .REGISTER && reg_class(op.reg) == REG_H
	case .S_REG: return op.kind == .REGISTER && reg_class(op.reg) == REG_S
	case .D_REG: return op.kind == .REGISTER && reg_class(op.reg) == REG_D
	case .Q_REG: return op.kind == .REGISTER && reg_class(op.reg) == REG_Q
	case .V_REG: return op.kind == .REGISTER && reg_class(op.reg) == REG_V

	// NEON vector arrangement variants. The user encodes the arrangement
	// via op.size: 8B=8, 16B=16, 4H=24, 8H=32, 2S=40, 4S=48, 1D=56, 2D=64.
	// (lanes * elem_bytes; unique per arrangement). When op.size==0 the
	// matcher accepts any V register (legacy / "first form wins") --
	// callers using op_reg() get size=4 by default which matches the
	// .V_4H form arithmetically; prefer the explicit op_v_*() builders.
	case .V_8B:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_V && (op.size == 0 || op.size == 8)
	case .V_16B:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_V && (op.size == 0 || op.size == 16)
	case .V_4H:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_V && (op.size == 0 || op.size == 24)
	case .V_8H, .V_8H_FP16:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_V && (op.size == 0 || op.size == 32)
	case .V_2S:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_V && (op.size == 0 || op.size == 40)
	case .V_4S:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_V && (op.size == 0 || op.size == 48)
	case .V_1D:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_V && (op.size == 0 || op.size == 56)
	case .V_2D:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_V && (op.size == 0 || op.size == 64)
	case .V_4H_FP16:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_V && (op.size == 0 || op.size == 24)
	// Element-indexed V views: element size carried in op.size (B=1,H=2,S=4,
	// D=8) so DUP/INS forms disambiguate. .S also accepts size 0 so a plain
	// op_reg (as the hand-written SM3TT forms pass) still matches the .S slot.
	case .V_ELEM_B:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_V && op.size == 1
	case .V_ELEM_H:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_V && op.size == 2
	case .V_ELEM_S:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_V && (op.size == 4 || op.size == 0)
	case .V_ELEM_D:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_V && op.size == 8

	// SVE Z registers. Element size carried in op.size: B=1, H=2, S=4, D=8.
	// op.size==0 (legacy / default-constructed) accepts any width.
	case .Z_REG_B:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_Z && (op.size == 0 || op.size == 1)
	case .Z_REG_H:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_Z && (op.size == 0 || op.size == 2)
	case .Z_REG_S:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_Z && (op.size == 0 || op.size == 4)
	case .Z_REG_D:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_Z && (op.size == 0 || op.size == 8)
	case .P_REG, .P_REG_MERGE, .P_REG_ZERO, .P_REG_GOV:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_P

	// SME tile state (immediate-encoded tile number; user supplies the
	// tile index as an immediate, e.g. 0 for ZA0.S, 3 for ZA3.S).
	case .ZA_TILE_B, .ZA_TILE_H, .ZA_TILE_S, .ZA_TILE_D, .ZA_TILE_Q:
		return op.kind == .IMMEDIATE
	// Misc immediate sub-types added in batch 3
	case .FCMLA_ROT, .FCADD_ROT, .SVE_PRFOP, .LDRAA_IMM10:
		return op.kind == .IMMEDIATE
	case .LSL_SHIFT_W, .LSL_SHIFT_X, .ROR_SHIFT:
		return op.kind == .IMMEDIATE
	case .Z_PAIR:
		// SME2 vector pair: first reg must be even (Z0, Z2, ..., Z30).
		return op.kind == .REGISTER && reg_class(op.reg) == REG_Z && (reg_hw(op.reg) & 0x1) == 0
	case .Z_QUAD:
		// SME2 vector quad: first reg must be multiple of 4.
		return op.kind == .REGISTER && reg_class(op.reg) == REG_Z && (reg_hw(op.reg) & 0x3) == 0
	case .SME_PATTERN, .SVE_PATTERN:
		return op.kind == .IMMEDIATE
	// SME tile slice (packed immediate descriptor; see encoding_types.odin)
	case .SME_SLICE_B, .SME_SLICE_H, .SME_SLICE_W, .SME_SLICE_D, .SME_SLICE_Q:
		return op.kind == .IMMEDIATE

	case .IMM_12, .IMM_16, .IMM_8, .IMM_6, .IMM_5, .IMM_4, .IMM_3, .IMM_2,
		 .NZCV_IMM, .SYS_REG, .HW_SHIFT, .LSE_SIZE, .VEC_SHIFT, .VEC_INDEX:
		return op.kind == .IMMEDIATE
	case .BITMASK_IMM:
		// The user passes the raw logical mask value; we validate that it
		// fits the AArch64 bitmask-immediate encoding at the form's width.
		return op.kind == .IMMEDIATE && is_valid_bitmask_imm(u64(op.immediate), form.flags.is_64)
	case .REL_26, .REL_19, .REL_14, .REL_PG21:
		return op.kind == .RELATIVE
	case .MEM:
		return op.kind == .MEMORY
	case .COND:
		return op.kind == .COND
	}
	return false
}

// =============================================================================
// Operand packer
// =============================================================================

@(private="file")
// Element size in bits for a NEON vector arrangement operand type.
vec_esize :: #force_inline proc "contextless" (ot: Operand_Type) -> u32 {
	#partial switch ot {
	case .V_8B, .V_16B:                         return 8
	case .V_4H, .V_8H, .V_4H_FP16, .V_8H_FP16:  return 16
	case .V_2S, .V_4S:                          return 32
	case .V_1D, .V_2D:                          return 64
	case .Z_REG_B:                              return 8
	case .Z_REG_H:                              return 16
	case .Z_REG_S:                              return 32
	case .Z_REG_D:                              return 64
	}
	return 8
}

@(private="file")
// Lane-index marker bit (log2 of element-size in bytes) for a DUP/INS form:
// derived from the V_ELEM_* operand the form carries. B=0, H=1, S=2, D=3.
vidx_markerbit :: #force_inline proc "contextless" (form: ^Encoding) -> u32 {
	for ot in form.ops {
		#partial switch ot {
		case .V_ELEM_B: return 0
		case .V_ELEM_H: return 1
		case .V_ELEM_S: return 2
		case .V_ELEM_D: return 3
		}
	}
	return 0
}

pack_operand_inline :: #force_inline proc(
	op:       ^Operand,
	enc:      Operand_Encoding,
	form:     ^Encoding,
	pc:       u32,
	inst_idx: u16,
	relocs:   ^[dynamic]Relocation,
) -> u32 {
	switch enc {
	case .NONE, .IMPL:
		return 0

	// ---- Register slots ----------------------------------------------------
	case .RD, .RT:
		return (u32(reg_hw(op.reg)) & 0x1F) << 0
	case .RN:
		return (u32(reg_hw(op.reg)) & 0x1F) << 5
	case .RT2, .RA:
		return (u32(reg_hw(op.reg)) & 0x1F) << 10
	case .RM:
		// RM has three flavours per the operand kind:
		//   REGISTER     -- plain Rm at bits 20-16
		//   SHIFTED_REG  -- Rm + shift type (22:23) + amount (15:10)
		//   EXTENDED_REG -- Rm + extend (13:15) + amount (10:12)
		switch op.kind {
		case .REGISTER:
			return (u32(reg_hw(op.reg)) & 0x1F) << 16
		case .SHIFTED_REG:
			return (u32(reg_hw(op.shifted.reg)) & 0x1F) << 16 |
				   (u32(op.shifted.type)        & 0x3)  << 22 |
				   (u32(op.shifted.amount)      & 0x3F) << 10
		case .EXTENDED_REG:
			return (u32(reg_hw(op.extended.reg)) & 0x1F) << 16 |
				   (u32(op.extended.extend)      & 0x7)  << 13 |
				   (u32(op.extended.amount)      & 0x7)  << 10
		case .NONE, .IMMEDIATE, .MEMORY, .RELATIVE, .COND:
			return 0
		}

	// ---- Immediates --------------------------------------------------------
	case .IMM12:    return (u32(op.immediate) & 0xFFF)    << 10
	case .IMM16:    return (u32(op.immediate) & 0xFFFF)   << 5
	case .IMM6:     return (u32(op.immediate) & 0x3F)     << 10
	case .IMM9:     return (u32(op.immediate) & 0x1FF)    << 12
	case .IMM_HW:   return (u32(op.immediate) & 0x3)      << 21
	case .IMM_SH12: return (u32(op.immediate) & 0x1)      << 22
	case .SHIFT_TYPE: return (u32(op.immediate) & 0x3)    << 22
	case .EXT_OPT:  return (u32(op.immediate) & 0x7)      << 13
	case .EXT_IMM3: return (u32(op.immediate) & 0x7)      << 10
	case .COND_HI:
		// Condition payload may arrive as IMMEDIATE (raw) or COND kind.
		c := u32(op.cond) if op.kind == .COND else u32(op.immediate)
		return (c & 0xF) << 12
	case .COND_LO:
		c := u32(op.cond) if op.kind == .COND else u32(op.immediate)
		return (c & 0xF) << 0
	case .NZCV_FIELD:
		return (u32(op.immediate) & 0xF) << 0
	case .SYS_FIELD:
		return (u32(op.immediate) & 0x7FFF) << 5
	case .HINT_FIELD:
		return (u32(op.immediate) & 0x7F) << 5
	case .BARRIER_FIELD:
		return (u32(op.immediate) & 0xF) << 8

	// ---- Memory operand variants ------------------------------------------
	case .OFFSET_BASE_U12:
		// Scaled unsigned 12-bit: imm12 = disp / data_size
		// data_size derived from bits[31:30] of the form: 00=1, 01=2, 10=4, 11=8
		size := u32(1) << ((form.bits >> 30) & 0x3)
		base_bits := (u32(reg_hw(op.mem.base)) & 0x1F) << 5
		imm_bits  := (u32(op.mem.disp) / size) & 0xFFF
		return base_bits | (imm_bits << 10)
	case .OFFSET_BASE_S9:
		// Signed 9-bit unscaled at bits 20-12.
		base_bits := (u32(reg_hw(op.mem.base)) & 0x1F) << 5
		imm_bits  := u32(op.mem.disp) & 0x1FF
		return base_bits | (imm_bits << 12)
	case .OFFSET_BASE_PRE:
		// Pre-index: bits[11:10] = 11, signed 9-bit at 20-12.
		base_bits := (u32(reg_hw(op.mem.base)) & 0x1F) << 5
		imm_bits  := u32(op.mem.disp) & 0x1FF
		return base_bits | (imm_bits << 12) | (0x3 << 10)
	case .OFFSET_BASE_POST:
		// Post-index: bits[11:10] = 01.
		base_bits := (u32(reg_hw(op.mem.base)) & 0x1F) << 5
		imm_bits  := u32(op.mem.disp) & 0x1FF
		return base_bits | (imm_bits << 12) | (0x1 << 10)
	case .OFFSET_BASE_A:
		// Atomic addressing: [Xn] only -- no displacement, no shift.
		// Used by load/store exclusives, acquire/release, LSE atomics.
		return (u32(reg_hw(op.mem.base)) & 0x1F) << 5
	case .OFFSET_REG:
		// [Xn, Xm{, LSL #s}]: option=011, S = shift!=0.
		base_bits := (u32(reg_hw(op.mem.base))  & 0x1F) << 5
		idx_bits  := (u32(reg_hw(op.mem.index)) & 0x1F) << 16
		option    := u32(0x3) << 13
		s_bit     := op.mem.shift != 0 ? u32(1) << 12 : 0
		return base_bits | idx_bits | option | s_bit | (0x2 << 10)
	case .OFFSET_EXT:
		// [Xn, Wm, SXTW|UXTW|SXTX #s]: option = ext, S = shift!=0.
		base_bits := (u32(reg_hw(op.mem.base))  & 0x1F) << 5
		idx_bits  := (u32(reg_hw(op.mem.index)) & 0x1F) << 16
		option    := (u32(op.mem.extend) & 0x7) << 13
		s_bit     := op.mem.shift != 0 ? u32(1) << 12 : 0
		return base_bits | idx_bits | option | s_bit | (0x2 << 10)

	// ---- PC-relative branches ---------------------------------------------
	case .BRANCH_26:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .B26, size = 4, inst_idx = inst_idx,
		})
		return 0
	case .BRANCH_19:
		// Could be B.cond, CBZ/CBNZ, or LDR literal -- the relocation
		// type for all three is the same B_COND19 (19-bit signed PC-rel
		// scaled by 4) since the encoding field is identical.
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .B_COND19, size = 4, inst_idx = inst_idx,
		})
		return 0
	case .BRANCH_14:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .TBZ14, size = 4, inst_idx = inst_idx,
		})
		return 0
	case .BRANCH_PG21:
		// ADR / ADRP -- choose reloc type by the form's bits[31] (op flag).
		ty: Relocation_Type = .ADR_PCREL21
		if (form.bits >> 31) & 1 != 0 { ty = .ADRP_PCREL21 }
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = ty, size = 4, inst_idx = inst_idx,
		})
		return 0

	// ---- TBZ / TBNZ bit position split (b5 at bit 31, b40 at 23-19) -----
	case .TBZ_BIT:
		bit := u32(op.immediate) & 0x3F
		return ((bit >> 5) & 1) << 31 | (bit & 0x1F) << 19

	// ---- NEON / SIMD register slots (alias of RD/RN/RM/RA bit positions) --
	case .VD:
		return (u32(reg_hw(op.reg)) & 0x1F) << 0
	case .VN:
		return (u32(reg_hw(op.reg)) & 0x1F) << 5
	case .VM:
		return (u32(reg_hw(op.reg)) & 0x1F) << 16
	case .VA:
		return (u32(reg_hw(op.reg)) & 0x1F) << 10

	// NEON shift-by-immediate: the element-size marker is already in `bits`;
	// the operand drives only the low immh:immb bits at 22:16.
	case .NEON_SHL_IMM:
		return (u32(op.immediate) & 0x3F) << 16
	case .NEON_SHR_IMM:
		esize := vec_esize(form.ops[0])
		return ((esize - u32(op.immediate)) & 0x3F) << 16

	// NEON copy/permute index fields (element-size marker fixed in `bits`).
	case .VN_VM_DUP:
		hw := u32(reg_hw(op.reg)) & 0x1F
		return (hw << 5) | (hw << 16)
	case .NEON_IDX5:
		mb := vidx_markerbit(form)
		return (u32(op.immediate) << (mb + 1)) << 16
	case .NEON_IDX4:
		mb := vidx_markerbit(form)
		return (u32(op.immediate) << mb) << 11
	case .NEON_EXT_IDX:
		return (u32(op.immediate) & 0xF) << 11

	// CCMP/CCMN immediate (imm5 at 20:16) and MSR-immediate PSTATE selector.
	case .IMM5_HI:
		return (u32(op.immediate) & 0x1F) << 16
	case .MSR_PSTATE:
		v := u32(op.immediate)
		return ((v >> 3) & 0x7) << 16 | (v & 0x7) << 5
	case .FMOV_SCALAR_IMM:
		return (u32(op.immediate) & 0xFF) << 13

	// SVE alias duplicated predicate / Z fields + EXT byte index.
	case .PG4_PM_DUP:
		p := u32(reg_hw(op.reg)) & 0xF
		return p << 10 | p << 16
	case .PN_PM_DUP:
		p := u32(reg_hw(op.reg)) & 0xF
		return p << 5 | p << 16
	case .PN_PG_PM_DUP:
		p := u32(reg_hw(op.reg)) & 0xF
		return p << 5 | p << 10 | p << 16
	case .ZD_ZM_DUP:
		z := u32(reg_hw(op.reg)) & 0x1F
		return z << 0 | z << 16
	case .SVE_EXT_IMM:
		v := u32(op.immediate)
		return ((v >> 3) & 0x1F) << 16 | (v & 0x7) << 10
	case .ZA_TILE_LOW:
		return (u32(op.immediate) & 0x7) << 0

	// NEON single-structure lane index (Q at 30, S at 12, size at 11:10).
	case .NEON_LANE_B:
		i := u32(op.immediate)
		return ((i >> 3) & 0x1) << 30 | ((i >> 2) & 0x1) << 12 | (i & 0x3) << 10
	case .NEON_LANE_H:
		i := u32(op.immediate)
		return ((i >> 2) & 0x1) << 30 | ((i >> 1) & 0x1) << 12 | (i & 0x1) << 11
	case .NEON_LANE_S:
		i := u32(op.immediate)
		return ((i >> 1) & 0x1) << 30 | (i & 0x1) << 12
	case .NEON_LANE_D:
		return (u32(op.immediate) & 0x1) << 30

	// SVE2 XAR rotate amount: V = 2*esize - amount, split tszh:tszl:imm3.
	case .SVE_XAR_SHIFT:
		esize := vec_esize(form.ops[0])
		v := (2 * esize - u32(op.immediate)) & 0x7F
		return ((v >> 5) & 0x3) << 22 | ((v >> 3) & 0x3) << 19 | (v & 0x7) << 16

	// NEON MOVI/FMOV immediate split: abc at bits 18-16, defgh at bits 9-5.
	case .NEON_IMM8_FMOV:
		v := u32(op.immediate) & 0xFF
		return ((v >> 5) & 0x7) << 16 | (v & 0x1F) << 5

	case .NEON_INDEX_H:
		// H lane index: H at bit 20, L at bit 21, M at bit 11 (3 bits total
		// when ESize=H). v1 keeps the simpler layout: just bits 20-19.
		return (u32(op.immediate) & 0x3) << 19
	case .NEON_INDEX_S:
		// S lane index: bits 11 (H) + 21 (L). v1: bit 11 + bit 21.
		v := u32(op.immediate) & 0x3
		return (v & 0x1) << 21 | ((v >> 1) & 0x1) << 11
	case .NEON_INDEX_D:
		return (u32(op.immediate) & 0x1) << 11

	// LSE atomics share field positions with the standard load/store
	// encoding (Rs at 16-20, Rt at 0-4, Rn at 5-9).
	case .ATOMIC_RS:
		return (u32(reg_hw(op.reg)) & 0x1F) << 16
	case .ATOMIC_RT:
		return (u32(reg_hw(op.reg)) & 0x1F) << 0
	case .ATOMIC_RN:
		// Memory operand carries the address register in mem.base.
		if op.kind == .MEMORY {
			return (u32(reg_hw(op.mem.base)) & 0x1F) << 5
		}
		return (u32(reg_hw(op.reg)) & 0x1F) << 5

	// Bitmask logical immediate. The user passes the raw 32/64-bit mask
	// value in op.immediate; the matcher has already validated that the
	// value is encodable at the form's width, so encode_bitmask_imm
	// cannot fail here.
	case .BITMASK_FIELD:
		n, immr, imms, _ := encode_bitmask_imm(u64(op.immediate), form.flags.is_64)
		return (u32(n) << 22) | (u32(immr) << 16) | (u32(imms) << 10)

	// SVE predicates (low 4 bits at 0/5/16; merge/zero via bit 14 etc.)
	case .PD:
		return (u32(reg_hw(op.reg)) & 0xF) << 0
	case .PN:
		return (u32(reg_hw(op.reg)) & 0xF) << 5
	case .PM:
		return (u32(reg_hw(op.reg)) & 0xF) << 16
	case .PG:
		// Governing predicate (3-bit slot, P0..P7 only).
		return (u32(reg_hw(op.reg)) & 0x7) << 10
	case .PG4:
		// 4-bit Pg slot (P0..P15) used by predicate-logical and a few
		// SVE2 ops.
		return (u32(reg_hw(op.reg)) & 0xF) << 10
	case .PM3:
		// 3-bit Pm at bits 15:13 (SME outer products FMOPA/SMOPA/etc.).
		return (u32(reg_hw(op.reg)) & 0x7) << 13

	// SVE immediates
	case .SVE_IMM8:
		// Signed 8-bit at bits 12-5 (DUP/CPY/ADD imm).
		return (u32(op.immediate) & 0xFF) << 5
	case .SVE_IMM5:
		// 5-bit at bits 20-16 (INDEX imm, etc.).
		return (u32(op.immediate) & 0x1F) << 16
	case .SVE_SHIFT_TSZ_IMM:
		// tsz:imm3 at bits 22:16 -- caller passes the already-composed
		// 7-bit field (tsz<6:3>:imm3<2:0>) in the IMMEDIATE.
		return (u32(op.immediate) & 0x7F) << 16
	case .SVE_PATTERN:
		return (u32(op.immediate) & 0x1F) << 5

	// SVE memory operands
	case .SVE_OFFSET_BASE_SS:
		// [Xn, Xm, LSL #s] scalar+scalar. Base at 9:5, index at 20:16;
		// shift is implicit in the encoding's static bits (per ESize).
		base_bits := (u32(reg_hw(op.mem.base))  & 0x1F) << 5
		idx_bits  := (u32(reg_hw(op.mem.index)) & 0x1F) << 16
		return base_bits | idx_bits
	case .SVE_OFFSET_BASE_SI:
		// [Xn{, #imm, MUL VL}] scalar+imm. Base at 9:5, signed 4-bit imm
		// at bits 19:16 (caller passes signed disp as op.mem.disp).
		base_bits := (u32(reg_hw(op.mem.base)) & 0x1F) << 5
		imm_bits  := (u32(op.mem.disp) & 0xF)         << 16
		return base_bits | imm_bits

	// SME ZA tile number fields (position depends on element size).
	case .ZA_TILE_NUM_B:
		// ZA0.B only -- nothing to encode (single tile of byte form).
		return 0
	case .ZA_TILE_NUM_H:
		// ZA0.H..ZA1.H -- 1-bit tile number at bit 22.
		return (u32(op.immediate) & 0x1) << 22
	case .ZA_TILE_NUM_S:
		// ZA0.S..ZA3.S -- 2-bit tile number at bits 23:22.
		return (u32(op.immediate) & 0x3) << 22
	case .ZA_TILE_NUM_D:
		// ZA0.D..ZA7.D -- 3-bit tile number at bits 23:21.
		return (u32(op.immediate) & 0x7) << 21
	case .SME_PATTERN_FIELD:
		// 4-bit SME pattern/list at bits 8:5 (ZERO instruction list mask).
		return (u32(op.immediate) & 0xF) << 5

	// ---- SVE gather/scatter + vector-base memory --------------------------
	case .SVE_OFFSET_BASE_VEC:
		// [Xn, Zm.S/D, extend] -- base GPR at 9:5, Zm at 20:16.
		base := (u32(reg_hw(op.mem.base))  & 0x1F) << 5
		idx  := (u32(reg_hw(op.mem.index)) & 0x1F) << 16
		return base | idx
	case .SVE_OFFSET_VEC_BASE:
		// [Zn.S/D, #imm5] -- vector base at 9:5, signed-5 imm at bits 20:16.
		base := (u32(reg_hw(op.mem.base)) & 0x1F) << 5
		imm  := (u32(op.mem.disp)         & 0x1F) << 16
		return base | imm

	// ---- SVE indexed lane field (FMLA Zda.T, Zn.T, Zm.T[i]) --------------
	case .SVE_FMLA_IDX_H:
		// i3 = (op.immediate >> 4) & 0x7? No -- user passes lane index
		// (0..7) directly. Encoder packs i3 split as bit 22, bits 20:19,
		// and Zm at bits 18:16 (low 8 regs only for indexed .H/.S).
		// The instruction format we use accepts the lane index as a
		// 3-bit immediate; the Zm register comes via .VM.
		lane := u32(op.immediate) & 0x7
		return ((lane >> 2) & 0x1) << 22 | (lane & 0x3) << 19
	case .SVE_FMLA_IDX_S:
		lane := u32(op.immediate) & 0x3
		return lane << 19
	case .SVE_FMLA_IDX_D:
		lane := u32(op.immediate) & 0x1
		return lane << 20

	// ---- SME tile slice descriptor packing -------------------------------
	//
	// The slice descriptor (packed immediate) is unpacked into the
	// instruction's bit positions per element size. The user-passed
	// packed value carries:
	//   imm[3:0] | V[4] | Ws[6:5] | tile[10:7]
	//
	// Instruction layout (per LLVM golden tests):
	//   bit 15      = V flag (0=H, 1=V)
	//   bits 14:13  = Ws index (Ws is W12 + this)
	//   bits  3:0   = tile_num and imm packed (per element size):
	//     .B : imm[3:0]                  (single tile, ZA0.B)
	//     .H : tile[0]<<3 | imm[2:0]     (2 tiles, 8 slices each)
	//     .W : tile[1:0]<<2 | imm[1:0]   (4 tiles, 4 slices each)
	//     .D : tile[2:0]<<1 | imm[0]     (8 tiles, 2 slices each)
	//     .Q : tile[3:0]                 (16 tiles, no imm)
	case .SME_SLICE_B:
		v     := u32(op.immediate)
		imm   := v & 0xF
		vflag := (v >> 4) & 0x1
		ws    := (v >> 5) & 0x3
		return (vflag << 15) | (ws << 13) | imm
	case .SME_SLICE_H:
		v     := u32(op.immediate)
		imm   := v & 0x7
		vflag := (v >> 4) & 0x1
		ws    := (v >> 5) & 0x3
		tile  := (v >> 7) & 0x1
		return (vflag << 15) | (ws << 13) | imm | (tile << 3)
	case .SME_SLICE_W:
		v     := u32(op.immediate)
		imm   := v & 0x3
		vflag := (v >> 4) & 0x1
		ws    := (v >> 5) & 0x3
		tile  := (v >> 7) & 0x3
		return (vflag << 15) | (ws << 13) | imm | (tile << 2)
	case .SME_SLICE_D:
		v     := u32(op.immediate)
		imm   := v & 0x1
		vflag := (v >> 4) & 0x1
		ws    := (v >> 5) & 0x3
		tile  := (v >> 7) & 0x7
		return (vflag << 15) | (ws << 13) | imm | (tile << 1)
	case .SME_SLICE_Q:
		v     := u32(op.immediate)
		vflag := (v >> 4) & 0x1
		ws    := (v >> 5) & 0x3
		tile  := (v >> 7) & 0xF
		return (vflag << 15) | (ws << 13) | tile

	// ---- Batch 3 misc immediate encodings ----
	case .ENC_FCMLA_ROT:
		// 2-bit rotation at bits 13:12 (0/1/2/3 = 0°/90°/180°/270°).
		return (u32(op.immediate) & 0x3) << 12
	case .ENC_FCADD_ROT:
		// 1-bit rotation at bit 12 (0 = 90°, 1 = 270°).
		return (u32(op.immediate) & 0x1) << 12
	case .ENC_SVE_PRFOP:
		// 4-bit SVE prefetch op at bits 3:0.
		return u32(op.immediate) & 0xF
	case .ENC_LDRAA_IMM10:
		// Signed 10-bit immediate at bits 21:12 (the user passes a byte
		// offset that must be a multiple of 8; we encode imm >> 3).
		v := u32(i32(op.immediate) >> 3) & 0x3FF
		return v << 12

	// ---- Batch 5 composite-packed encodings ----
	case .ENC_LSL_IMM_W:
		// 32-bit LSL alias: immr = (-imm) & 31, imms = 31 - imm.
		imm  := u32(op.immediate) & 0x1F
		immr := ((~imm + 1) & 0x1F)
		imms := (31 - imm) & 0x1F
		return (immr << 16) | (imms << 10)
	case .ENC_LSL_IMM_X:
		// 64-bit LSL alias: immr = (-imm) & 63, imms = 63 - imm.
		imm  := u32(op.immediate) & 0x3F
		immr := ((~imm + 1) & 0x3F)
		imms := (63 - imm) & 0x3F
		return (immr << 16) | (imms << 10)
	case .ENC_DUAL_RN_RM:
		// Pack the register at both Rn (9:5) AND Rm (20:16) slots
		// (for ROR Rd, Rn, #imm = EXTR Rd, Rn, Rn, #imm).
		hw := u32(reg_hw(op.reg)) & 0x1F
		return (hw << 5) | (hw << 16)
	case .ENC_ROR_SHIFT:
		// imms (shift amount) at bits 15:10.
		return (u32(op.immediate) & 0x3F) << 10

	case .ENC_Z_PAIR_VD, .ENC_Z_QUAD_VD:
		// Pack first Z reg into Vd slot (bits 4:0).
		return (u32(reg_hw(op.reg)) & 0x1F) << 0
	case .ENC_Z_PAIR_VN, .ENC_Z_QUAD_VN:
		return (u32(reg_hw(op.reg)) & 0x1F) << 5
	case .ENC_Z_PAIR_VM, .ENC_Z_QUAD_VM:
		return (u32(reg_hw(op.reg)) & 0x1F) << 16
	}
	return 0
}

// =============================================================================
// Pass 2 -- relocation resolver
// =============================================================================

@(private="file")
resolve_relocation_inline :: #force_inline proc(
	code:         []u8,
	label_defs:   []Label_Definition,
	relocation:   ^Relocation,
	endianness:   Endianness,
	base_address: u64,
	errors:       ^[dynamic]Error,
) -> bool {
	if int(relocation.label_id) >= len(label_defs) { return false }
	ld := label_defs[relocation.label_id]
	if ld == LABEL_UNDEFINED { return false }
	target := u32(ld)

	word := read_u32(code, relocation.offset, endianness)

	switch relocation.type {
	case .B26:
		rel := i32(target) - i32(relocation.offset) + relocation.addend
		if rel & 3 != 0 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		words := rel >> 2
		if words < -(1<<25) || words > (1<<25)-1 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		word |= u32(words) & 0x03FFFFFF

	case .B_COND19, .LDR_LITERAL19:
		rel := i32(target) - i32(relocation.offset) + relocation.addend
		if rel & 3 != 0 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		words := rel >> 2
		if words < -(1<<18) || words > (1<<18)-1 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		word |= (u32(words) & 0x7FFFF) << 5

	case .TBZ14:
		rel := i32(target) - i32(relocation.offset) + relocation.addend
		if rel & 3 != 0 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		words := rel >> 2
		if words < -(1<<13) || words > (1<<13)-1 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		word |= (u32(words) & 0x3FFF) << 5

	case .ADR_PCREL21:
		// ADR: signed 21-bit byte offset (no scaling).
		rel := i32(target) - i32(relocation.offset) + relocation.addend
		if rel < -(1<<20) || rel > (1<<20)-1 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		v := u32(rel) & 0x1FFFFF
		word |= (v & 0x3) << 29 | ((v >> 2) & 0x7FFFF) << 5

	case .ADRP_PCREL21:
		// ADRP: difference of page (4KB-aligned) targets.
		target_page := u64(target) & ~u64(0xFFF) + base_address & ~u64(0xFFF)
		// Effective: ((target + base) >> 12) - ((pc + base) >> 12)
		// Simpler:   ((target + base) - (pc + base)) >> 12  when both are
		// 4KB-aligned; but base + offset alignment is the caller's concern.
		pc_page  := (u64(relocation.offset) + base_address) & ~u64(0xFFF)
		tg_page  := target_page
		diff     := i64(tg_page) - i64(pc_page) + i64(relocation.addend)
		if diff & 0xFFF != 0 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		pages := diff >> 12
		if pages < -(1<<20) || pages > (1<<20)-1 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		v := u32(pages) & 0x1FFFFF
		word |= (v & 0x3) << 29 | ((v >> 2) & 0x7FFFF) << 5

	case .NONE, .PCREL_LO12_I, .PCREL_LO12_S, .ABS64, .ABS32, .ABS16:
		// Linker-bound or assembler-layer; not auto-resolved here.
		return false
	}

	write_u32(code, relocation.offset, word, endianness)
	return true
}

// =============================================================================
// Endian-aware word I/O
// =============================================================================

@(private="package")
write_u32 :: #force_inline proc "contextless" (
	code: []u8, offset: u32, word: u32, endianness: Endianness,
) {
	if endianness == .LITTLE {
		code[offset+0] = u8(word)
		code[offset+1] = u8(word >>  8)
		code[offset+2] = u8(word >> 16)
		code[offset+3] = u8(word >> 24)
	} else {
		code[offset+0] = u8(word >> 24)
		code[offset+1] = u8(word >> 16)
		code[offset+2] = u8(word >>  8)
		code[offset+3] = u8(word)
	}
}

@(private="package")
read_u32 :: #force_inline proc "contextless" (
	code: []u8, offset: u32, endianness: Endianness,
) -> u32 {
	if endianness == .LITTLE {
		return  u32(code[offset+0])        |
			   (u32(code[offset+1]) <<  8) |
			   (u32(code[offset+2]) << 16) |
			   (u32(code[offset+3]) << 24)
	}
	return  (u32(code[offset+0]) << 24) |
			(u32(code[offset+1]) << 16) |
			(u32(code[offset+2]) <<  8) |
			 u32(code[offset+3])
}
