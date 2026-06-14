package rexcode_mos65816

import "../isa"

// =============================================================================
// W65C816S DECODER
// =============================================================================
//
// Two passes, mirroring mos6502/decoder. The 65816-specific bits:
//
//   * Mode-dependent operand widths. The decoder takes an
//     `Assumed_State{m, x, e}` parameter telling it the current state of
//     the M and X processor flags (E forces M=X=1 in emulation mode).
//     For an opcode like $A9 (LDA #imm), the bucket holds two entries;
//     the decoder picks IMM_M8 when m=1 and IMM_M16 when m=0.
//
//   * Variable length 1..4 bytes; the matched entry's `length` drives it.

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
	state:        Assumed_State = NATIVE_16,
) -> Result {
	n_bytes := u32(len(data))
	errors_start := u32(len(errors))

	pending_branches: [dynamic]isa.Branch_Target
	defer delete(pending_branches)

	// Emulation mode pins M and X to 1.
	eff := state
	if eff.e { eff.m = true; eff.x = true }

	pc: u32 = 0
	for pc < n_bytes {
		inst: Instruction
		info: Instruction_Info
		entry_idx, consumed := decode_one_inline(data, pc, n_bytes, eff, &inst, &info)

		if entry_idx < 0 {
			append(errors, Error{inst_idx = pc, code = .INVALID_OPCODE})
			inst = Instruction{mnemonic = .INVALID, length = 1}
			info = Instruction_Info{offset = pc}
			consumed = 1
		} else {
			inst_idx_for_branches := u32(len(instructions))
			for slot in 0..<inst.operand_count {
				op := &inst.ops[slot]
				if op.kind == .RELATIVE && op.relative >= 0 {
					append(&pending_branches, isa.Branch_Target{
						inst_idx = inst_idx_for_branches,
						op_idx   = slot,
						target   = u32(op.relative),
					})
				}
			}
		}

		append(instructions, inst)
		append(inst_info,    info)
		pc += consumed
	}

	isa.infer_labels_from_branches(pending_branches[:], pc, label_defs, relocs)
	return Result{byte_count = pc, success = u32(len(errors)) == errors_start}
}

// =============================================================================
// Internal
// =============================================================================

@(private="file")
decode_one_inline :: #force_inline proc "contextless" (
	data: []u8, pc: u32, n_bytes: u32, state: Assumed_State,
	inst: ^Instruction, info: ^Instruction_Info,
) -> (entry_idx: int, consumed: u32) {
	opcode := data[pc]
	range  := DECODE_INDEX_OPCODE[opcode]
	if range.count == 0 { return -1, 1 }

	base := int(range.start)
	cnt  := int(range.count)
	matched_idx := -1
	for i in 0..<cnt {
		e := &DECODE_ENTRIES[base + i]
		if mode_accepts(state, e.ops[0]) {
			matched_idx = base + i
			break
		}
	}
	if matched_idx < 0 { return -1, 1 }

	entry := &DECODE_ENTRIES[matched_idx]
	length := u32(entry.length)
	if pc + length > n_bytes { return -1, 1 }

	inst.mnemonic = entry.mnemonic
	inst.length   = entry.length
	inst.flags    = {}

	cnt_used: u8 = 0
	if entry.ops[0] != .NONE {
		inst.ops[0] = extract_operand_inline(data, pc, entry.ops[0], entry.enc[0])
		cnt_used = 1
		if entry.ops[1] != .NONE {
			inst.ops[1] = extract_operand_inline(data, pc, entry.ops[1], entry.enc[1])
			cnt_used = 2
		}
	}
	inst.operand_count = cnt_used

	info.offset       = pc
	info.decode_entry = u16(matched_idx)
	return matched_idx, length
}

// Reject an entry when the first operand's type would conflict with the
// assumed M/X flag state.  Non-IMM_M*/IMM_X* entries always pass.
@(private="file")
mode_accepts :: #force_inline proc "contextless" (state: Assumed_State, ot: Operand_Type) -> bool {
	#partial switch ot {
	case .IMM_M8:  return state.m
	case .IMM_M16: return !state.m
	case .IMM_X8:  return state.x
	case .IMM_X16: return !state.x
	}
	return true
}

@(private="file")
extract_operand_inline :: #force_inline proc "contextless" (
	data: []u8, pc: u32, ot: Operand_Type, en: Operand_Encoding,
) -> Operand {
	switch en {
	case .NONE:
		return {}

	case .IMPL:
		if ot == .A_IMPL {
			return Operand{reg = A, kind = .REGISTER, size = 1}
		}
		return {}

	case .BYTE_1_IMM:
		return Operand{immediate = i64(data[pc+1]), kind = .IMMEDIATE, size = 1}

	case .WORD_1_IMM:
		v := u16(data[pc+1]) | (u16(data[pc+2]) << 8)
		return Operand{immediate = i64(v), kind = .IMMEDIATE, size = 2}

	case .BYTE_1_ADDR:
		return mem_operand_byte(u16(data[pc+1]), ot)

	case .WORD_1_ADDR:
		addr := u16(data[pc+1]) | (u16(data[pc+2]) << 8)
		return mem_operand_word(addr, ot)

	case .LONG_1_ADDR:
		addr :=  u32(data[pc+1])         |
				(u32(data[pc+2]) <<  8)  |
				(u32(data[pc+3]) << 16)
		return mem_operand_long(addr, ot)

	case .BYTE_1_REL:
		rel    := i32(i8(data[pc+1]))
		target := u32(i32(pc) + 2 + rel)
		return Operand{relative = i64(target), kind = .RELATIVE, size = 1}

	case .WORD_1_REL:
		v := i32(i16(u16(data[pc+1]) | (u16(data[pc+2]) << 8)))
		target := u32(i32(pc) + 3 + v)
		return Operand{relative = i64(target), kind = .RELATIVE, size = 2}

	case .BYTE_1_BANK:
		// dst bank (offset 1) -- the SECOND user-facing operand (MVN src,dst)
		return Operand{immediate = i64(data[pc+1]), kind = .IMMEDIATE, size = 1}
	case .BYTE_2_BANK:
		// src bank (offset 2) -- the FIRST user-facing operand
		return Operand{immediate = i64(data[pc+2]), kind = .IMMEDIATE, size = 1}
	}
	return {}
}

@(private="file")
mem_operand_byte :: #force_inline proc "contextless" (addr: u16, ot: Operand_Type) -> Operand {
	mode: Address_Mode
	#partial switch ot {
	case .MEM_DP:            mode = .DP
	case .MEM_DP_X:          mode = .DP_X
	case .MEM_DP_Y:          mode = .DP_Y
	case .MEM_DP_IND:        mode = .DP_IND
	case .MEM_DP_IND_X:      mode = .DP_IND_X
	case .MEM_DP_IND_Y:      mode = .DP_IND_Y
	case .MEM_DP_IND_LONG:   mode = .DP_IND_LONG
	case .MEM_DP_IND_LONG_Y: mode = .DP_IND_LONG_Y
	case .MEM_SR:            mode = .SR
	case .MEM_SR_IND_Y:      mode = .SR_IND_Y
	case:                    mode = .DP
	}
	return Operand{
		mem  = Memory{address = u32(addr), mode = mode},
		kind = .MEMORY,
		size = 1,
	}
}

@(private="file")
mem_operand_word :: #force_inline proc "contextless" (addr: u16, ot: Operand_Type) -> Operand {
	mode: Address_Mode
	#partial switch ot {
	case .MEM_ABS:          mode = .ABS
	case .MEM_ABS_X:        mode = .ABS_X
	case .MEM_ABS_Y:        mode = .ABS_Y
	case .MEM_ABS_IND:      mode = .ABS_IND
	case .MEM_ABS_IND_LONG: mode = .ABS_IND_LONG
	case .MEM_ABS_IND_X:    mode = .ABS_IND_X
	case:                   mode = .ABS
	}
	return Operand{
		mem  = Memory{address = u32(addr), mode = mode},
		kind = .MEMORY,
		size = 2,
	}
}

@(private="file")
mem_operand_long :: #force_inline proc "contextless" (addr: u32, ot: Operand_Type) -> Operand {
	mode: Address_Mode = .LONG
	if ot == .MEM_LONG_X { mode = .LONG_X }
	return Operand{
		mem  = Memory{address = addr, mode = mode},
		kind = .MEMORY,
		size = 3,
	}
}
