// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_mos65816

import "core:rexcode/isa"

// =============================================================================
// W65C816S ENCODER
// =============================================================================
//
// Variable-length 1..4 byte pipeline. Same 2-pass shape as mos6502/encoder.
// The 65816-specific twists:
//
//   * Mode-dependent immediates: the matcher distinguishes IMM_M8/IMM_M16
//     and IMM_X8/IMM_X16 by `op.size`. The user picks which width to emit
//     via `inst_i8` or `inst_i16` and the encoder produces the matching
//     opcode form.
//
//   * 24-bit addresses: long ($nnnnnn) and long,X forms emit 3 LE bytes.
//
//   * Block moves (MVN/MVP): the source-then-destination user syntax is
//     emitted as `opcode | dst_bank | src_bank` -- the encoder routes
//     ops[0] -> BYTE_2_BANK (offset 2) and ops[1] -> BYTE_1_BANK (offset 1).

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
	n_inst := u32(len(instructions))
	errors_start  := u32(len(errors))
	pending_start := u32(len(relocs))

	inst_offsets := make([]u32, n_inst, context.temp_allocator)

	for i in 0..<n_inst {
		inst_offsets[i] = byte_count
		inst := &instructions[i]
		form := find_form_inline(inst, u16(i), errors) or_return

		if byte_count + u32(form.length) > u32(len(code)) {
			append(errors, Error{inst_idx = i, code = .BUFFER_OVERFLOW})
			return
		}

		code[byte_count] = form.opcode
		if form.enc[0] != .NONE { pack_operand_inline(&inst.ops[0], form.enc[0], byte_count, u16(i), code, relocs) }
		if form.enc[1] != .NONE { pack_operand_inline(&inst.ops[1], form.enc[1], byte_count, u16(i), code, relocs) }

		inst.length = form.length
		byte_count += u32(form.length)
	}

	isa.rewrite_label_defs_to_offsets(label_defs, inst_offsets)

	if !resolve {
		ok = u32(len(errors)) == errors_start
		return
	}

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

	ok = u32(len(errors)) == errors_start
	return
}

// =============================================================================
// Internal: form matching / operand packing
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
			operand_matches_inline(&inst.ops[1], form.ops[1])
}

@(private="file")
operand_matches_inline :: #force_inline proc "contextless" (
	op: ^Operand, ot: Operand_Type,
) -> bool {
	switch ot {
	case .NONE:              return op.kind == .NONE
	case .A_IMPL:            return op.kind == .REGISTER && op.reg == A
	case .IMM_8:             return op.kind == .IMMEDIATE && op.size == 1
	case .IMM_M8:            return op.kind == .IMMEDIATE && op.size == 1
	case .IMM_M16:           return op.kind == .IMMEDIATE && op.size == 2
	case .IMM_X8:            return op.kind == .IMMEDIATE && op.size == 1
	case .IMM_X16:           return op.kind == .IMMEDIATE && op.size == 2
	case .REL:               return op.kind == .RELATIVE && op.size == 1
	case .REL_LONG:          return op.kind == .RELATIVE && op.size == 2
	case .MEM_DP:            return op.kind == .MEMORY && op.mem.mode == .DP
	case .MEM_DP_X:          return op.kind == .MEMORY && op.mem.mode == .DP_X
	case .MEM_DP_Y:          return op.kind == .MEMORY && op.mem.mode == .DP_Y
	case .MEM_DP_IND:        return op.kind == .MEMORY && op.mem.mode == .DP_IND
	case .MEM_DP_IND_X:      return op.kind == .MEMORY && op.mem.mode == .DP_IND_X
	case .MEM_DP_IND_Y:      return op.kind == .MEMORY && op.mem.mode == .DP_IND_Y
	case .MEM_DP_IND_LONG:   return op.kind == .MEMORY && op.mem.mode == .DP_IND_LONG
	case .MEM_DP_IND_LONG_Y: return op.kind == .MEMORY && op.mem.mode == .DP_IND_LONG_Y
	// MEM_ABS / MEM_LONG also accept RELATIVE-kind labels for forward
	// references (JMP/JSR/JML/JSL to a label).
	case .MEM_ABS:           return (op.kind == .MEMORY && op.mem.mode == .ABS) ||
								 (op.kind == .RELATIVE && op.size == 2)
	case .MEM_ABS_X:         return op.kind == .MEMORY && op.mem.mode == .ABS_X
	case .MEM_ABS_Y:         return op.kind == .MEMORY && op.mem.mode == .ABS_Y
	case .MEM_ABS_IND:       return op.kind == .MEMORY && op.mem.mode == .ABS_IND
	case .MEM_ABS_IND_LONG:  return op.kind == .MEMORY && op.mem.mode == .ABS_IND_LONG
	case .MEM_ABS_IND_X:     return op.kind == .MEMORY && op.mem.mode == .ABS_IND_X
	case .MEM_LONG:          return (op.kind == .MEMORY && op.mem.mode == .LONG) ||
								 (op.kind == .RELATIVE && op.size == 3)
	case .MEM_LONG_X:        return op.kind == .MEMORY && op.mem.mode == .LONG_X
	case .MEM_SR:            return op.kind == .MEMORY && op.mem.mode == .SR
	case .MEM_SR_IND_Y:      return op.kind == .MEMORY && op.mem.mode == .SR_IND_Y
	case .BANK_SRC:          return op.kind == .IMMEDIATE
	case .BANK_DST:          return op.kind == .IMMEDIATE
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

	case .BYTE_1_IMM:
		code[pc+1] = u8(op.immediate)

	case .WORD_1_IMM:
		v := u16(op.immediate)
		code[pc+1] = u8(v)
		code[pc+2] = u8(v >> 8)

	case .BYTE_1_ADDR:
		code[pc+1] = u8(op.mem.address)

	case .WORD_1_ADDR:
		if op.kind == .RELATIVE {
			append(relocs, Relocation{
				offset = pc + 1, label_id = u32(op.relative),
				type = .ABS16, size = 2, inst_idx = inst_idx,
			})
			code[pc+1] = 0
			code[pc+2] = 0
		} else {
			addr := u16(op.mem.address)
			code[pc+1] = u8(addr)
			code[pc+2] = u8(addr >> 8)
		}

	case .LONG_1_ADDR:
		if op.kind == .RELATIVE {
			append(relocs, Relocation{
				offset = pc + 1, label_id = u32(op.relative),
				type = .ABS24, size = 3, inst_idx = inst_idx,
			})
			code[pc+1] = 0
			code[pc+2] = 0
			code[pc+3] = 0
		} else {
			addr := op.mem.address & 0xFFFFFF
			code[pc+1] = u8(addr)
			code[pc+2] = u8(addr >> 8)
			code[pc+3] = u8(addr >> 16)
		}

	case .BYTE_1_REL:
		append(relocs, Relocation{
			offset = pc + 1, label_id = u32(op.relative),
			type = .REL8, size = 1, inst_idx = inst_idx,
		})
		code[pc+1] = 0

	case .WORD_1_REL:
		append(relocs, Relocation{
			offset = pc + 1, label_id = u32(op.relative),
			type = .REL16, size = 2, inst_idx = inst_idx,
		})
		code[pc+1] = 0
		code[pc+2] = 0

	case .BYTE_1_BANK:
		code[pc+1] = u8(op.immediate)
	case .BYTE_2_BANK:
		code[pc+2] = u8(op.immediate)
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
	if int(relocation.label_id) >= len(label_defs) { return false }
	ld := label_defs[relocation.label_id]
	if ld == LABEL_UNDEFINED { return false }
	target := u32(ld)

	switch relocation.type {
	case .REL8:
		next_pc := relocation.offset + 1
		rel := i32(target) - i32(next_pc) + relocation.addend
		if rel < -128 || rel > 127 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
			code[relocation.offset] = u8(i8(rel))
			return true
		}
		code[relocation.offset] = u8(i8(rel))

	case .REL16:
		next_pc := relocation.offset + 2
		rel := i32(target) - i32(next_pc) + relocation.addend
		if rel < -32768 || rel > 32767 {
			append(errors, Error{inst_idx = u32(relocation.inst_idx), code = .LABEL_OUT_OF_RANGE})
		}
		v := u16(rel)
		code[relocation.offset+0] = u8(v)
		code[relocation.offset+1] = u8(v >> 8)

	case .ABS16:
		abs := u16(u64(target) + base_address + u64(relocation.addend))
		code[relocation.offset+0] = u8(abs)
		code[relocation.offset+1] = u8(abs >> 8)

	case .ABS24:
		abs := u32((u64(target) + base_address + u64(relocation.addend)) & 0xFFFFFF)
		code[relocation.offset+0] = u8(abs)
		code[relocation.offset+1] = u8(abs >> 8)
		code[relocation.offset+2] = u8(abs >> 16)

	case .NONE:
		return false
	}
	return true
}
