package rexcode_riscv

// =============================================================================
// RISC-V ENCODER
// =============================================================================
//
// Fixed-width 4-byte ISA. Two-pass design mirroring mips/encoder.odin:
//
//   PASS 1   - encode each instruction to a u32 word; emit Relocation
//              entries for B-type (BRANCH) and J-type (JAL) operands.
//   PASS 1.5 - rewrite label_defs from instruction-index to byte-offset
//              (just multiply by 4).
//   PASS 2   - patch resolvable BRANCH / JAL relocations.
//
// The interesting bits vs other arches:
//
//   * The B-type and J-type immediates are *scattered* across non-
//     contiguous positions in the word. `scatter_b` and `scatter_j`
//     rearrange a contiguous signed value into the wire bits.
//
//   * Memory operands come in three flavours -- OFFSET_BASE_I for loads
//     and JALR (I-type imm), OFFSET_BASE_S for stores (S-type scatter),
//     and OFFSET_BASE_A for atomics (rs1 only, disp must be 0).

MAX_INST_SIZE :: 4

encode_max_code_size :: #force_inline proc "contextless" (n: int) -> int {
	return n * 4
}
encode_max_relocation_count :: #force_inline proc "contextless" (n: int) -> int {
	return n
}

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
	if u32(len(code)) < n_inst * 4 {
		append(errors, Error{inst_idx = 0, code = .BUFFER_OVERFLOW})
		return Result{byte_count = 0, success = false}
	}

	errors_start  := u32(len(errors))
	pending_start := u32(len(relocs))
	pc: u32 = 0

	// Per-instruction byte offsets so label_defs (instruction-indexed)
	// can be rewritten to byte-offset after pass 1 in the presence of
	// mixed 2/4-byte (RVC) instructions.
	inst_pc := make([]u32, n_inst, context.temp_allocator)

	// ---- PASS 1 -----------------------------------------------------------
	for i in 0..<n_inst {
		inst_pc[i] = pc
		inst := &instructions[i]
		word, ilen, ok := encode_one_inline(inst, pc, u16(i), relocs, errors)
		if !ok { return Result{byte_count = pc, success = false} }
		if ilen == 2 {
			write_u16_le(code, pc, u16(word))
		} else {
			write_u32_le(code, pc, word)
		}
		pc += u32(ilen)
	}

	// ---- PASS 1.5: rewrite label_defs (instruction-index -> byte-offset) --
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

	// ---- PASS 2: resolve relocations --------------------------------------
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
// Internal: encode one instruction
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

	form: ^Encoding
	for &f in forms {
		if encoding_matches_inline(inst, &f) {
			form = &f
			break
		}
	}
	if form == nil {
		append(errors, Error{inst_idx = u32(inst_idx), code = .NO_MATCHING_ENCODING})
		return 0, 0, false
	}

	word = form.bits
	if form.enc[0] != .NONE { word |= pack_operand_inline(&inst.ops[0], form.enc[0], pc, inst_idx, relocs) }
	if form.enc[1] != .NONE { word |= pack_operand_inline(&inst.ops[1], form.enc[1], pc, inst_idx, relocs) }
	if form.enc[2] != .NONE { word |= pack_operand_inline(&inst.ops[2], form.enc[2], pc, inst_idx, relocs) }
	if form.enc[3] != .NONE { word |= pack_operand_inline(&inst.ops[3], form.enc[3], pc, inst_idx, relocs) }
	return word, inst_size_from_bits(form.bits), true
}

@(private="file")
encoding_matches_inline :: #force_inline proc "contextless" (
	inst: ^Instruction, form: ^Encoding,
) -> bool {
	return  operand_matches_inline(&inst.ops[0], form.ops[0]) &&
			operand_matches_inline(&inst.ops[1], form.ops[1]) &&
			operand_matches_inline(&inst.ops[2], form.ops[2]) &&
			operand_matches_inline(&inst.ops[3], form.ops[3])
}

@(private="file")
operand_matches_inline :: #force_inline proc "contextless" (
	op: ^Operand, ot: Operand_Type,
) -> bool {
	switch ot {
	case .NONE:        return op.kind == .NONE
	case .GPR:         return op.kind == .REGISTER && reg_class(op.reg) == REG_GPR
	case .FPR:         return op.kind == .REGISTER && reg_class(op.reg) == REG_FPR
	case .IMM12, .IMM12U, .IMM5, .IMM6, .IMM20,
		 .CSR, .FENCE_FLAGS, .ROUND_MODE, .ZIMM5,
		 .IMM_C6S, .IMM_C6U, .IMM_C8U, .IMM_C10S, .IMM_C18S:
		return op.kind == .IMMEDIATE
	case .REL13, .REL21, .REL9, .REL12:
		return op.kind == .RELATIVE
	case .MEM, .MEM_C_W, .MEM_C_D, .MEM_C_SP_W, .MEM_C_SP_D:
		return op.kind == .MEMORY

	// ---- C extension ----
	case .GPR_C:
		if op.kind != .REGISTER || reg_class(op.reg) != REG_GPR { return false }
		hw := reg_hw(op.reg)
		return hw >= 8 && hw <= 15
	case .FPR_C:
		if op.kind != .REGISTER || reg_class(op.reg) != REG_FPR { return false }
		hw := reg_hw(op.reg)
		return hw >= 8 && hw <= 15
	case .GPR_SP:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_GPR && reg_hw(op.reg) == 2
	case .GPR_NONZERO:
		return op.kind == .REGISTER && reg_class(op.reg) == REG_GPR && reg_hw(op.reg) != 0
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
) -> u32 {
	switch enc {
	case .NONE:
		return 0

	// ---- Register slots ----------------------------------------------------
	case .RD:    return (u32(reg_hw(op.reg)) & 0x1F) << 7
	case .RS1:   return (u32(reg_hw(op.reg)) & 0x1F) << 15
	case .RS2:   return (u32(reg_hw(op.reg)) & 0x1F) << 20
	case .RS3:   return (u32(reg_hw(op.reg)) & 0x1F) << 27

	// ---- Shift amounts -----------------------------------------------------
	case .SHAMT5: return (u32(op.immediate) & 0x1F) << 20
	case .SHAMT6: return (u32(op.immediate) & 0x3F) << 20

	// ---- Immediates --------------------------------------------------------
	case .IMM_I:
		return (u32(op.immediate) & 0xFFF) << 20
	case .IMM_S:
		v := u32(op.immediate)
		return ((v >> 5) & 0x7F) << 25 | (v & 0x1F) << 7
	case .IMM_U:
		return (u32(op.immediate) & 0xFFFFF) << 12
	case .IMM_B:
		// B-type PC-rel branch. Always paired with a RELATIVE operand
		// (label or raw offset).
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .BRANCH, size = 4, inst_idx = inst_idx,
		})
		return 0
	case .IMM_J:
		// J-type PC-rel JAL.
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .JAL, size = 4, inst_idx = inst_idx,
		})
		return 0

	// ---- Memory operand variants ------------------------------------------
	case .OFFSET_BASE_I:
		base_bits := (u32(reg_hw(op.mem.base)) & 0x1F) << 15
		imm_bits  := (u32(op.mem.disp) & 0xFFF) << 20
		return base_bits | imm_bits
	case .OFFSET_BASE_S:
		base_bits := (u32(reg_hw(op.mem.base)) & 0x1F) << 15
		v := u32(op.mem.disp)
		imm_bits  := ((v >> 5) & 0x7F) << 25 | (v & 0x1F) << 7
		return base_bits | imm_bits
	case .OFFSET_BASE_A:
		return (u32(reg_hw(op.mem.base)) & 0x1F) << 15

	// ---- Specialty fields --------------------------------------------------
	case .CSR_FIELD:
		return (u32(op.immediate) & 0xFFF) << 20
	case .ZIMM_FIELD:
		return (u32(op.immediate) & 0x1F) << 15
	case .FENCE_PRED:
		return (u32(op.immediate) & 0xF) << 24
	case .FENCE_SUCC:
		return (u32(op.immediate) & 0xF) << 20
	case .ROUND_FIELD:
		return (u32(op.immediate) & 0x7) << 12
	case .AQRL:
		return (u32(op.immediate) & 0x3) << 25

	// ---- C extension register slots ---------------------------------------
	case .C_RD_RS1:
		return (u32(reg_hw(op.reg)) & 0x1F) << 7
	case .C_RS2:
		return (u32(reg_hw(op.reg)) & 0x1F) << 2
	case .C_RD_PRIMED, .C_RS2_PRIMED:
		return (u32(reg_hw(op.reg)) & 0x7) << 2
	case .C_RS1_PRIMED, .C_RD_RS1_PRIMED:
		return (u32(reg_hw(op.reg)) & 0x7) << 7

	// ---- C extension immediates -------------------------------------------
	case .C_IMM_CI_S, .C_IMM_CI_U:
		// CI-form 6-bit imm: bit 5 -> bit 12, bits 4:0 -> bits 6:2.
		v := u32(op.immediate)
		return ((v >> 5) & 0x1) << 12 | (v & 0x1F) << 2
	case .C_IMM_CIW:
		// C.ADDI4SPN: imm[9:2] (multiple of 4, non-zero) packed as:
		//   imm[5:4] @ 12:11, imm[9:6] @ 10:7, imm[2] @ 6, imm[3] @ 5
		// imm here is the byte offset (already times 4 in the source).
		v := u32(op.immediate)
		return ((v >> 4) & 0x3) << 11 |
			   ((v >> 6) & 0xF) <<  7 |
			   ((v >> 2) & 0x1) <<  6 |
			   ((v >> 3) & 0x1) <<  5
	case .C_IMM_LUI:
		// C.LUI: imm[17:12] sign-extended. imm[17] @12, imm[16:12] @6:2.
		v := u32(op.immediate) >> 12
		return ((v >> 5) & 0x1) << 12 | (v & 0x1F) << 2
	case .C_IMM_ADDI16SP:
		// C.ADDI16SP: imm[9:4] non-zero, scaled by 16. Encoded as:
		//   imm[9] @12, imm[4] @6, imm[6] @5, imm[8:7] @4:3, imm[5] @2
		v := u32(op.immediate)
		return ((v >> 9) & 0x1) << 12 |
			   ((v >> 4) & 0x1) <<  6 |
			   ((v >> 6) & 0x1) <<  5 |
			   ((v >> 7) & 0x3) <<  3 |
			   ((v >> 5) & 0x1) <<  2
	case .C_IMM_CSS_W:
		// C.SWSP: imm scaled by 4, range 0..252. imm[5:2] @ 12:9, imm[7:6] @ 8:7.
		v := u32(op.immediate)
		return ((v >> 2) & 0xF) << 9 | ((v >> 6) & 0x3) << 7
	case .C_IMM_CSS_D:
		// C.SDSP: imm scaled by 8, range 0..504. imm[5:3] @ 12:10, imm[8:6] @ 9:7.
		v := u32(op.immediate)
		return ((v >> 3) & 0x7) << 10 | ((v >> 6) & 0x7) << 7
	case .C_IMM_CL_W:
		// C.LW/SW: imm[5:3] @12:10, imm[2] @6, imm[6] @5. Scaled by 4 (0..124).
		v := u32(op.immediate)
		return ((v >> 3) & 0x7) << 10 | ((v >> 2) & 0x1) << 6 | ((v >> 6) & 0x1) << 5
	case .C_IMM_CL_D:
		// C.LD/SD: imm[5:3] @12:10, imm[7:6] @6:5. Scaled by 8 (0..248).
		v := u32(op.immediate)
		return ((v >> 3) & 0x7) << 10 | ((v >> 6) & 0x3) << 5

	// ---- C extension memory operands --------------------------------------
	case .C_OFFSET_BASE_W:
		// [rs1', disp] with disp scaled by 4.
		base := (u32(reg_hw(op.mem.base)) & 0x7) << 7
		v    := u32(op.mem.disp)
		imm  := ((v >> 3) & 0x7) << 10 | ((v >> 2) & 0x1) << 6 | ((v >> 6) & 0x1) << 5
		return base | imm
	case .C_OFFSET_BASE_D:
		base := (u32(reg_hw(op.mem.base)) & 0x7) << 7
		v    := u32(op.mem.disp)
		imm  := ((v >> 3) & 0x7) << 10 | ((v >> 6) & 0x3) << 5
		return base | imm
	case .C_SP_OFFSET_W:
		// C.LWSP: imm[5] @12, imm[4:2] @6:4, imm[7:6] @3:2. Base is implicit SP.
		v := u32(op.mem.disp)
		return ((v >> 5) & 0x1) << 12 | ((v >> 2) & 0x7) << 4 | ((v >> 6) & 0x3) << 2
	case .C_SP_OFFSET_D:
		// C.LDSP: imm[5] @12, imm[4:3] @6:5, imm[8:6] @4:2. Base is implicit SP.
		v := u32(op.mem.disp)
		return ((v >> 5) & 0x1) << 12 | ((v >> 3) & 0x3) << 5 | ((v >> 6) & 0x7) << 2

	// ---- C extension PC-relative branches/jumps ---------------------------
	case .C_BRANCH9:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .C_BRANCH, size = 2, inst_idx = inst_idx,
		})
		return 0
	case .C_BRANCH12:
		append(relocs, Relocation{
			offset = pc, label_id = u32(op.relative),
			type = .C_JUMP, size = 2, inst_idx = inst_idx,
		})
		return 0
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
	base_address: u64,
	errors:       ^[dynamic]Error,
) -> bool {
	if int(relocation.label_id) >= len(label_defs) { return false }
	ld := label_defs[relocation.label_id]
	if ld == LABEL_UNDEFINED { return false }
	target := u32(ld)

	// 16-bit (RVC) relocations write a halfword; 32-bit ones write a full word.
	if relocation.size == 2 {
		hword := read_u16_le(code, relocation.offset)
		switch relocation.type {
		case .C_BRANCH:
			rel := i32(target) - i32(relocation.offset) + relocation.addend
			if rel & 1 != 0 || rel < -256 || rel > 254 {
				append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
				return true
			}
			hword |= u16(scatter_c_branch(u32(rel)))
		case .C_JUMP:
			rel := i32(target) - i32(relocation.offset) + relocation.addend
			if rel & 1 != 0 || rel < -2048 || rel > 2046 {
				append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
				return true
			}
			hword |= u16(scatter_c_jump(u32(rel)))
		case .NONE, .BRANCH, .JAL, .PCREL_HI20, .PCREL_LO12_I, .PCREL_LO12_S,
			 .HI20, .LO12_I, .LO12_S, .CALL:
			return false
		}
		write_u16_le(code, relocation.offset, hword)
		return true
	}

	word := read_u32_le(code, relocation.offset)

	switch relocation.type {
	case .BRANCH:
		rel := i32(target) - i32(relocation.offset) + relocation.addend
		if rel & 1 != 0 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		if rel < -4096 || rel > 4094 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		word |= scatter_b(u32(rel))

	case .JAL:
		rel := i32(target) - i32(relocation.offset) + relocation.addend
		if rel & 1 != 0 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		if rel < -(1 << 20) || rel > (1 << 20) - 2 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			return true
		}
		word |= scatter_j(u32(rel))

	case .NONE, .PCREL_HI20, .PCREL_LO12_I, .PCREL_LO12_S,
		 .HI20, .LO12_I, .LO12_S, .CALL, .C_BRANCH, .C_JUMP:
		// Not auto-resolved by the encoder pass 2; the assembler caller
		// supplies the raw values via %hi/%lo or expands CALL itself.
		return false
	}

	write_u32_le(code, relocation.offset, word)
	return true
}

// =============================================================================
// Scatter / gather helpers for B-type and J-type immediates
// =============================================================================

@(private="package")
scatter_b :: #force_inline proc "contextless" (v: u32) -> u32 {
	return  ((v >> 12) & 1)    << 31 |
			((v >>  5) & 0x3F) << 25 |
			((v >>  1) & 0xF)  <<  8 |
			((v >> 11) & 1)    <<  7
}

@(private="package")
scatter_j :: #force_inline proc "contextless" (v: u32) -> u32 {
	return  ((v >> 20) & 1)     << 31 |
			((v >>  1) & 0x3FF) << 21 |
			((v >> 11) & 1)     << 20 |
			((v >> 12) & 0xFF)  << 12
}

// Inverse for decoder. Returns sign-extended offset.
@(private="package")
gather_b :: #force_inline proc "contextless" (word: u32) -> i32 {
	v :=   ((word >> 31) & 1)    << 12 |
		   ((word >>  7) & 1)    << 11 |
		   ((word >> 25) & 0x3F) <<  5 |
		   ((word >>  8) & 0xF)  <<  1
	// sign-extend from bit 12
	if v & (1 << 12) != 0 { v |= ~u32(0x1FFF) }
	return i32(v)
}

@(private="package")
gather_j :: #force_inline proc "contextless" (word: u32) -> i32 {
	v :=   ((word >> 31) & 1)     << 20 |
		   ((word >> 12) & 0xFF)  << 12 |
		   ((word >> 20) & 1)     << 11 |
		   ((word >> 21) & 0x3FF) <<  1
	if v & (1 << 20) != 0 { v |= ~u32(0x1FFFFF) }
	return i32(v)
}

// I-type sign-extended immediate (bits 31-20)
@(private="package")
gather_i :: #force_inline proc "contextless" (word: u32) -> i32 {
	return i32(word) >> 20   // arithmetic shift sign-extends
}

// S-type sign-extended immediate (bits 31-25 || 11-7)
@(private="package")
gather_s :: #force_inline proc "contextless" (word: u32) -> i32 {
	v := ((word >> 25) & 0x7F) << 5 | ((word >> 7) & 0x1F)
	if v & (1 << 11) != 0 { v |= ~u32(0xFFF) }
	return i32(v)
}

// ---- C extension scatter/gather --------------------------------------------
//
// C.BEQZ / C.BNEZ -- 9-bit signed PC-rel offset, scattered as:
//   imm[8]   @ bit 12      imm[4:3] @ bits 11:10
//   imm[7:6] @ bits 6:5    imm[2:1] @ bits 4:3   imm[5] @ bit 2
@(private="package")
scatter_c_branch :: #force_inline proc "contextless" (v: u32) -> u32 {
	return ((v >> 8) & 0x1) << 12 |
		   ((v >> 3) & 0x3) << 10 |
		   ((v >> 6) & 0x3) <<  5 |
		   ((v >> 1) & 0x3) <<  3 |
		   ((v >> 5) & 0x1) <<  2
}

@(private="package")
gather_c_branch :: #force_inline proc "contextless" (hword: u32) -> i32 {
	v := ((hword >> 12) & 0x1) << 8 |
		 ((hword >> 10) & 0x3) << 3 |
		 ((hword >>  5) & 0x3) << 6 |
		 ((hword >>  3) & 0x3) << 1 |
		 ((hword >>  2) & 0x1) << 5
	if v & (1 << 8) != 0 { v |= ~u32(0x1FF) }
	return i32(v)
}

// C.J / C.JAL -- 12-bit signed PC-rel offset, scattered as:
//   imm[11] @12, imm[4] @11, imm[9:8] @10:9, imm[10] @8, imm[6] @7,
//   imm[7] @6, imm[3:1] @5:3, imm[5] @2
@(private="package")
scatter_c_jump :: #force_inline proc "contextless" (v: u32) -> u32 {
	return ((v >> 11) & 0x1) << 12 |
		   ((v >>  4) & 0x1) << 11 |
		   ((v >>  8) & 0x3) <<  9 |
		   ((v >> 10) & 0x1) <<  8 |
		   ((v >>  6) & 0x1) <<  7 |
		   ((v >>  7) & 0x1) <<  6 |
		   ((v >>  1) & 0x7) <<  3 |
		   ((v >>  5) & 0x1) <<  2
}

@(private="package")
gather_c_jump :: #force_inline proc "contextless" (hword: u32) -> i32 {
	v := ((hword >> 12) & 0x1) << 11 |
		 ((hword >> 11) & 0x1) <<  4 |
		 ((hword >>  9) & 0x3) <<  8 |
		 ((hword >>  8) & 0x1) << 10 |
		 ((hword >>  7) & 0x1) <<  6 |
		 ((hword >>  6) & 0x1) <<  7 |
		 ((hword >>  3) & 0x7) <<  1 |
		 ((hword >>  2) & 0x1) <<  5
	if v & (1 << 11) != 0 { v |= ~u32(0xFFF) }
	return i32(v)
}

// =============================================================================
// Little-endian word I/O
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
