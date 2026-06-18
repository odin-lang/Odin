// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_mos6502

import "core:rexcode/isa"

// =============================================================================
// MOS 6502 DECODER
// =============================================================================
//
// Two passes, mirroring MIPS/RSP. The 6502-specific bits:
//
//   - Variable length 1..7 bytes per instruction. The matched entry tells
//     us the byte count via `entry.length`.
//
//   - CPU-tier filtering: the same opcode byte means different things on
//     NMOS vs 65C02 vs HuC6280 (e.g. $07 = SLO on NMOS-undoc, RMB0 on
//     65C02). The caller passes a target `CPU` value and the matcher
//     skips entries above that tier.
//
//   - Tier rule:
//       NMOS         accepts NMOS only
//       NMOS_UNDOC   accepts NMOS + NMOS_UNDOC
//       CMOS_65C02   accepts NMOS + CMOS_65C02 (NOT NMOS_UNDOC -- those
//                    opcodes mean RMB/SMB/etc. on 65C02)
//       HUC6280      accepts NMOS + CMOS_65C02 + HUC6280 (also not undoc)
//
//   - Operand extraction is the inverse of pack_operand_inline in
//     encoder.odin: pull each operand from its known offset+size in the
//     instruction byte stream.

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
	cpu:          CPU = .NMOS,
) -> (byte_count: u32, ok: bool) {
	n_bytes := u32(len(data))
	errors_start := u32(len(errors))

	pending_branches: [dynamic]isa.Branch_Target
	defer delete(pending_branches)

	for byte_count < n_bytes {
		inst: Instruction
		info: Instruction_Info
		entry_idx, consumed := decode_one_inline(data, byte_count, n_bytes, cpu, &inst, &info)

		if entry_idx < 0 {
			append(errors, Error{inst_idx = byte_count, code = .INVALID_OPCODE})
			inst = Instruction{mnemonic = .INVALID, length = 1}
			info = Instruction_Info{offset = byte_count}
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
		byte_count += consumed
	}

	isa.infer_labels_from_branches(pending_branches[:], byte_count, label_defs, relocs)
	ok = u32(len(errors)) == errors_start
	return
}

// =============================================================================
// Internal: decode one instruction starting at data[pc]
// =============================================================================
//
// Returns the matched DECODE_ENTRIES index (or -1) and the number of bytes
// consumed (always >= 1 to make forward progress).

@(private="file")
decode_one_inline :: #force_inline proc "contextless" (
	data: []u8, pc: u32, n_bytes: u32, cpu: CPU,
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
		if cpu_accepts(cpu, e.cpu) {
			matched_idx = base + i
			break
		}
	}
	if matched_idx < 0 { return -1, 1 }

	entry := &DECODE_ENTRIES[matched_idx]
	length := u32(entry.length)
	if pc + length > n_bytes {
		// Truncated instruction at end of buffer.
		return -1, 1
	}

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
			if entry.ops[2] != .NONE {
				inst.ops[2] = extract_operand_inline(data, pc, entry.ops[2], entry.enc[2])
				cnt_used = 3
			}
		}
	}
	inst.operand_count = cnt_used

	info.offset       = pc
	info.decode_entry = u16(matched_idx)
	return matched_idx, length
}

// CPU tier acceptance check (see top-of-file docstring).
@(private="file")
cpu_accepts :: #force_inline proc "contextless" (target, entry: CPU) -> bool {
	switch target {
	case .NMOS:
		return entry == .NMOS
	case .NMOS_UNDOC:
		return entry == .NMOS || entry == .NMOS_UNDOC
	case .CMOS_65C02:
		return entry == .NMOS || entry == .CMOS_65C02
	case .HUC6280:
		return entry == .NMOS || entry == .CMOS_65C02 || entry == .HUC6280
	}
	return false
}

// -----------------------------------------------------------------------------
// Operand extraction (inverse of pack_operand_inline)
// -----------------------------------------------------------------------------

@(private="file")
extract_operand_inline :: #force_inline proc "contextless" (
	data: []u8, pc: u32, ot: Operand_Type, en: Operand_Encoding,
) -> Operand {
	switch en {
	case .NONE:
		return {}

	case .IMPL:
		// The accumulator-implicit forms (ASL A, ROL A, ...) tag the
		// operand as REGISTER=A so the printer reproduces "A".
		if ot == .A_IMPL {
			return Operand{reg = A, kind = .REGISTER, size = 1}
		}
		return {}

	case .BYTE_1_IMM:
		return Operand{immediate = i64(data[pc+1]), kind = .IMMEDIATE, size = 1}

	case .BYTE_1_ADDR:
		return mem_operand(u16(data[pc+1]), ot)

	case .BYTE_1_REL:
		// PC-relative branch: target = (PC + 2) + signed_imm8
		rel    := i32(i8(data[pc+1]))
		target := u32(i32(pc) + 2 + rel)
		return Operand{relative = i64(target), kind = .RELATIVE, size = 1}

	case .WORD_1_ADDR:
		addr := u16(data[pc+1]) | (u16(data[pc+2]) << 8)
		return mem_operand(addr, ot)

	case .BYTE_2_REL:
		// BBR/BBS rel byte at offset 2; instruction is 3 bytes long.
		rel    := i32(i8(data[pc+2]))
		target := u32(i32(pc) + 3 + rel)
		return Operand{relative = i64(target), kind = .RELATIVE, size = 1}

	case .WORD_1:
		v := u16(data[pc+1]) | (u16(data[pc+2]) << 8)
		return Operand{immediate = i64(v), kind = .IMMEDIATE, size = 2}
	case .WORD_3:
		v := u16(data[pc+3]) | (u16(data[pc+4]) << 8)
		return Operand{immediate = i64(v), kind = .IMMEDIATE, size = 2}
	case .WORD_5:
		v := u16(data[pc+5]) | (u16(data[pc+6]) << 8)
		return Operand{immediate = i64(v), kind = .IMMEDIATE, size = 2}

	case .BYTE_2_ADDR:
		return mem_operand(u16(data[pc+2]), ot)
	case .WORD_2_ADDR:
		addr := u16(data[pc+2]) | (u16(data[pc+3]) << 8)
		return mem_operand(addr, ot)
	}
	return {}
}

// Build a MEMORY operand with the addressing mode implied by Operand_Type.
@(private="file")
mem_operand :: #force_inline proc "contextless" (addr: u16, ot: Operand_Type) -> Operand {
	mode: Address_Mode
	size: u8 = 1
	#partial switch ot {
	case .MEM_ZP:        mode = .ZP
	case .MEM_ZP_X:      mode = .ZP_X
	case .MEM_ZP_Y:      mode = .ZP_Y
	case .MEM_ABS:       mode = .ABS;       size = 2
	case .MEM_ABS_X:     mode = .ABS_X;     size = 2
	case .MEM_ABS_Y:     mode = .ABS_Y;     size = 2
	case .MEM_IND:       mode = .IND;       size = 2
	case .MEM_IND_X:     mode = .IND_X
	case .MEM_IND_Y:     mode = .IND_Y
	case .MEM_IND_ZP:    mode = .IND_ZP
	case .MEM_IND_ABS_X: mode = .IND_ABS_X; size = 2
	}
	return Operand{
		mem  = Memory{address = addr, mode = mode},
		kind = .MEMORY,
		size = size,
	}
}
