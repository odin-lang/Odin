// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_mos6502

import "../isa"

// =============================================================================
// MOS 6502 ENCODER
// =============================================================================
//
// Variable-length encoding pipeline (1, 2, 3, 4, or 7 bytes per instruction).
// Two passes, mirroring the MIPS/RSP shape but with per-instruction length
// derived from the matched encoding form rather than a fixed 4.
//
//   PASS 1   - for each Instruction:
//                * find a matching Encoding form (mnemonic + operand shapes)
//                * record this instruction's byte offset in inst_offsets[i]
//                * write opcode byte + operand bytes per the form
//                * emit pending Relocation entries for label-referencing operands
//
//   PASS 1.5 - rewrite label_defs[i] from instruction-index to byte-offset
//              using the inst_offsets array gathered in pass 1 (variable
//              length means we can't just multiply by a constant).
//
//   PASS 2   - if `resolve == true`, patch resolvable Relocations:
//                * ABS16 -- write 2 LE bytes of (base_address + target + addend)
//                * REL8  -- write 1 signed byte of (target - (offset + 1) + addend)
//
// 16-bit operands are always little-endian (6502 ISA convention; no
// endianness parameter).

MAX_INST_SIZE :: 7   // HuC6280 block transfer

encode_max_code_size :: #force_inline proc "contextless" (n: int) -> int {
	return n * MAX_INST_SIZE
}

encode_max_relocation_count :: #force_inline proc "contextless" (n: int) -> int {
	// BBR/BBS have two operands but only one is a label; cap at one per inst.
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
	errors_start  := u32(len(errors))
	pending_start := u32(len(relocs))

	inst_offsets := make([]u32, n_inst, context.temp_allocator)

	pc: u32 = 0

	// ---- PASS 1 -----------------------------------------------------------
	for i in 0..<n_inst {
		inst_offsets[i] = pc

		inst := &instructions[i]
		form, ok := find_form_inline(inst, u16(i), errors)
		if !ok {
			return Result{byte_count = pc, success = false}
		}

		if pc + u32(form.length) > u32(len(code)) {
			append(errors, Error{inst_idx = i, code = .BUFFER_OVERFLOW})
			return Result{byte_count = pc, success = false}
		}

		// Opcode byte
		code[pc] = form.opcode

		// Operand bytes
		if form.enc[0] != .NONE { pack_operand_inline(&inst.ops[0], form.enc[0], pc, u16(i), code, relocs) }
		if form.enc[1] != .NONE { pack_operand_inline(&inst.ops[1], form.enc[1], pc, u16(i), code, relocs) }
		if form.enc[2] != .NONE { pack_operand_inline(&inst.ops[2], form.enc[2], pc, u16(i), code, relocs) }

		inst.length = form.length
		pc += u32(form.length)
	}

	// ---- PASS 1.5: inst-index -> byte-offset -----------------------------
	isa.rewrite_label_defs_to_offsets(label_defs, inst_offsets)

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
		if write_idx != read_idx {
			relocs[write_idx] = r
		}
		write_idx += 1
	}
	if write_idx != n_relocs {
		resize(relocs, int(write_idx))
	}

	return Result{byte_count = pc, success = u32(len(errors)) == errors_start}
}

// =============================================================================
// Internal: form matching & operand packing
// =============================================================================

@(private="file")
find_form_inline :: #force_inline proc(
	inst: ^Instruction, inst_idx: u16, errors: ^[dynamic]Error,
) -> (form: ^Encoding, ok: bool) {
	if inst.mnemonic == .INVALID {
		append(errors, Error{inst_idx = u32(inst_idx), code = .INVALID_MNEMONIC})
		return nil, false
	}
	forms := encoding_forms(inst.mnemonic)
	if len(forms) == 0 {
		append(errors, Error{inst_idx = u32(inst_idx), code = .INVALID_MNEMONIC})
		return nil, false
	}
	for &f in forms {
		if encoding_matches_inline(inst, &f) {
			return &f, true
		}
	}
	append(errors, Error{inst_idx = u32(inst_idx), code = .NO_MATCHING_ENCODING})
	return nil, false
}

@(private="file")
encoding_matches_inline :: #force_inline proc "contextless" (
	inst: ^Instruction, form: ^Encoding,
) -> bool {
	return  operand_matches_inline(&inst.ops[0], form.ops[0]) &&
			operand_matches_inline(&inst.ops[1], form.ops[1]) &&
			operand_matches_inline(&inst.ops[2], form.ops[2])
}

@(private="file")
operand_matches_inline :: #force_inline proc "contextless" (
	op: ^Operand, ot: Operand_Type,
) -> bool {
	switch ot {
	case .NONE:           return op.kind == .NONE
	case .A_IMPL:         return op.kind == .REGISTER && op.reg == A
	case .IMM_8, .IMM_16: return op.kind == .IMMEDIATE
	case .REL:            return op.kind == .RELATIVE
	case .MEM_ZP:         return op.kind == .MEMORY && op.mem.mode == .ZP
	case .MEM_ZP_X:       return op.kind == .MEMORY && op.mem.mode == .ZP_X
	case .MEM_ZP_Y:       return op.kind == .MEMORY && op.mem.mode == .ZP_Y
	// MEM_ABS also accepts a RELATIVE-kind operand (label) -- the encoder
	// emits an ABS16 relocation in that case so JMP/JSR/etc. work with
	// forward-referenced labels.
	case .MEM_ABS:        return (op.kind == .MEMORY && op.mem.mode == .ABS) || op.kind == .RELATIVE
	case .MEM_ABS_X:      return op.kind == .MEMORY && op.mem.mode == .ABS_X
	case .MEM_ABS_Y:      return op.kind == .MEMORY && op.mem.mode == .ABS_Y
	case .MEM_IND:        return op.kind == .MEMORY && op.mem.mode == .IND
	case .MEM_IND_X:      return op.kind == .MEMORY && op.mem.mode == .IND_X
	case .MEM_IND_Y:      return op.kind == .MEMORY && op.mem.mode == .IND_Y
	case .MEM_IND_ZP:     return op.kind == .MEMORY && op.mem.mode == .IND_ZP
	case .MEM_IND_ABS_X:  return op.kind == .MEMORY && op.mem.mode == .IND_ABS_X
	}
	return false
}

@(private="file")
pack_operand_inline :: #force_inline proc(
	op:       ^Operand,
	enc:      Operand_Encoding,
	pc:       u32,
	inst_idx: u16,
	code:     []u8,
	relocs:   ^[dynamic]Relocation,
) {
	switch enc {
	case .NONE, .IMPL:
		// Nothing to write -- opcode-only or accumulator.

	case .BYTE_1_IMM:
		code[pc+1] = u8(op.immediate)

	case .BYTE_1_ADDR:
		code[pc+1] = u8(op.mem.address)

	case .BYTE_1_REL:
		// PC-relative branch -- emit reloc; pass 2 fills the byte.
		append(relocs, Relocation{
			offset = pc + 1, label_id = u32(op.relative),
			type = .REL8, size = 1, inst_idx = inst_idx,
		})
		code[pc+1] = 0

	case .WORD_1_ADDR:
		// Either a literal 16-bit address or a label resolving to one.
		if op.kind == .RELATIVE {
			append(relocs, Relocation{
				offset = pc + 1, label_id = u32(op.relative),
				type = .ABS16, size = 2, inst_idx = inst_idx,
			})
			code[pc+1] = 0
			code[pc+2] = 0
		} else {
			addr := op.mem.address
			code[pc+1] = u8(addr)
			code[pc+2] = u8(addr >> 8)
		}

	case .BYTE_2_REL:
		// BBR/BBS: rel byte at offset 2 (zp byte at offset 1 was already packed).
		append(relocs, Relocation{
			offset = pc + 2, label_id = u32(op.relative),
			type = .REL8, size = 1, inst_idx = inst_idx,
		})
		code[pc+2] = 0

	case .WORD_1:
		v := u16(op.immediate)
		code[pc+1] = u8(v)
		code[pc+2] = u8(v >> 8)
	case .WORD_3:
		v := u16(op.immediate)
		code[pc+3] = u8(v)
		code[pc+4] = u8(v >> 8)
	case .WORD_5:
		v := u16(op.immediate)
		code[pc+5] = u8(v)
		code[pc+6] = u8(v >> 8)

	case .BYTE_2_ADDR:
		code[pc+2] = u8(op.mem.address)
	case .WORD_2_ADDR:
		addr := op.mem.address
		code[pc+2] = u8(addr)
		code[pc+3] = u8(addr >> 8)
	}
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
	if int(relocation.label_id) >= len(label_defs) {
		return false
	}
	ld := label_defs[relocation.label_id]
	if ld == LABEL_UNDEFINED {
		return false
	}
	target := u32(ld)

	switch relocation.type {
	case .REL8:
		// value byte sits at relocation.offset; the instruction ends 1 byte
		// after that, so next_pc = offset + 1.
		next_pc := relocation.offset + 1
		rel := i32(target) - i32(next_pc) + relocation.addend
		if rel < -128 || rel > 127 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			code[relocation.offset] = u8(i8(rel))   // truncate so it's at least visible
			return true
		}
		code[relocation.offset] = u8(i8(rel))

	case .ABS16:
		abs := u16(u64(target) + base_address + u64(relocation.addend))
		code[relocation.offset+0] = u8(abs)
		code[relocation.offset+1] = u8(abs >> 8)

	case .NONE:
		return false
	}
	return true
}
