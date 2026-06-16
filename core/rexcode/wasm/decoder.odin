// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)

package rexcode_wasm

import "base:runtime"

// =============================================================================
// WebAssembly DECODER
// =============================================================================
//
// Single forward pass, mirroring the encoder. Each step:
//
//   1. Read the opcode. A leading 0xFC switches to the misc group, whose
//      sub-opcode is an unsigned LEB128 read next; otherwise the single byte
//      is the opcode. The byte (or sub-opcode) indexes the DECODE_MAIN /
//      DECODE_MISC tables built from ENCODING_TABLE at package init.
//   2. Look the resulting Mnemonic's form back up in ENCODING_TABLE and read
//      its immediates in declaration order, reconstructing Operands.
//
// WASM control flow is structured (branches carry relative label depths, not
// byte offsets), so there is no PC-relative label inference -- `label_defs`
// is part of the universal signature but left untouched. Object-file index
// relocations *are* re-attached: when an input relocation lands on a decoded
// index field, that operand is marked `symbolic` and carries the label id.
//
// `br_table`'s case-label vector is materialised into a freshly allocated
// `[]u32` (caller owns it, like the rest of the decoded output).

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
	targets_allocator := context.allocator,
) -> (byte_count: u32, ok: bool) {
	errors_start := u32(len(errors))
	n := u32(len(data))

	for byte_count < n {
		inst, info, next, dok := decode_one(data, relocs, byte_count, targets_allocator)
		if !dok {
			append(errors, Error{inst_idx = byte_count, code = .INVALID_OPCODE})
			inst = Instruction{mnemonic = .INVALID, length = 1}
			info = Instruction_Info{offset = byte_count}
			append(instructions, inst)
			append(inst_info,    info)
			byte_count += 1
			continue
		}
		inst.length = u8(min(next - byte_count, 255))
		append(instructions, inst)
		append(inst_info,    info)
		byte_count = next
	}

	ok = u32(len(errors)) == errors_start
	return
}

// =============================================================================
// Internal
// =============================================================================

@(private="file")
decode_one :: proc(
	data:      []u8,
	relocs:    []Relocation,
	pc:        u32,
	targets_allocator: runtime.Allocator,
) -> (inst: Instruction, info: Instruction_Info, next: u32, ok: bool) {
	off := pc
	if off >= u32(len(data)) {
		next = pc
		return
	}

	// --- opcode (and optional misc sub-opcode) ------------------------------
	b0 := data[off]
	off += 1

	m: Mnemonic = .INVALID
	switch b0 {
	case PREFIX_MISC:
		sub := read_uleb(data, &off) or_return
		if sub < u64(DECODE_MISC_COUNT) {
			m = DECODE_MISC[sub]
		}
	case PREFIX_SIMD:
		sub := read_uleb(data, &off) or_return
		if sub < u64(DECODE_SIMD_COUNT) {
			m = DECODE_SIMD[sub]
		}
	case PREFIX_ATOM:
		sub := read_uleb(data, &off) or_return
		if sub < u64(DECODE_ATOMIC_COUNT) {
			m = DECODE_ATOMIC[sub]
		}
	case:
		m = DECODE_MAIN[b0]
	}
	if m == .INVALID {
		next = pc
		return
	}

	form := encoding_form(m)
	inst.mnemonic = m
	inst.flags    = {}

	// --- immediates ---------------------------------------------------------
	slot := 0
	for k, ki in form.imm {
		switch k {
		case .NONE:
			// nothing

		case .BLOCKTYPE:
			v := read_sleb(data, &off) or_return
			inst.ops[slot] = Operand{immediate = v, kind = .BLOCK_TYPE}
			slot += 1

		case .I32:
			v := read_sleb(data, &off) or_return
			inst.ops[slot] = Operand{immediate = v, kind = .IMMEDIATE, size = 4}
			slot += 1

		case .I64:
			v := read_sleb(data, &off) or_return
			inst.ops[slot] = Operand{immediate = v, kind = .IMMEDIATE, size = 8}
			slot += 1

		case .F32:
			bits := read_u32le(data, &off) or_return
			inst.ops[slot] = Operand{
				immediate = i64(bits), kind = .IMMEDIATE, size = 4, flags = {is_float = true},
			}
			slot += 1

		case .F64:
			bits := read_u64le(data, &off) or_return
			inst.ops[slot] = Operand{
				immediate = i64(bits), kind = .IMMEDIATE, size = 8, flags = {is_float = true},
			}
			slot += 1

		case .IDX:
			field := off
			raw := read_uleb(data, &off) or_return
			op := Operand{index = u32(raw), kind = .INDEX, idx_kind = idx_kind_for(m, ki)}
			if lid, found := reloc_label_at(relocs, field); found {
				op.index          = lid
				op.flags.symbolic = true
				op.size           = 5
			}
			inst.ops[slot] = op
			slot += 1

		case .MEMARG:
			align  := read_uleb(data, &off) or_return
			offset := read_uleb(data, &off) or_return
			inst.ops[slot] = Operand{memarg = Memarg{align = u32(align), offset = u32(offset)}, kind = .MEMARG}
			slot += 1

		case .REFTYPE:
			if off >= u32(len(data)) {
				next = pc
				return
			}
			t := data[off]
			off += 1
			inst.ops[slot] = Operand{immediate = i64(t), kind = .IMMEDIATE, size = 1}
			slot += 1

		case .BR_TABLE:
			count := read_uleb(data, &off) or_return
			targets := make([]u32, int(count), targets_allocator)
			for &target in targets {
				t := read_uleb(data, &off) or_return
				target = u32(t)
			}
			def := read_uleb(data, &off) or_return
			inst.targets   = targets
			inst.ops[slot] = Operand{index = u32(def), kind = .INDEX, idx_kind = .LABEL}
			slot += 1

		case .ZERO_BYTE:
			if off >= u32(len(data)) {
				next = pc
				return
			}
			off += 1   // reserved 0x00, consumes no operand

		case .LANE:
			if off >= u32(len(data)) {
				next = pc
				return
			}
			l := data[off]
			off += 1
			inst.ops[slot] = Operand{immediate = i64(l), kind = .IMMEDIATE, size = 1}
			slot += 1

		case .LANES16:
			if off + 16 > u32(len(data)) {
				next = pc
				return
			}
			copy(inst.bytes[:], data[off:off + 16])
			off += 16   // value lives in inst.bytes, no operand
		}
	}

	inst.operand_count = u8(slot)
	info.offset       = pc
	info.decode_entry = u16(m)
	next = off
	ok = true
	return
}

// Which index space the IDX immediate in operand slot `which` addresses, by
// mnemonic. Mirrors how the builders in instructions.odin tag each operand.
@(private="file")
idx_kind_for :: #force_inline proc "contextless" (m: Mnemonic, which: int) -> Index_Kind {
	#partial switch m {
	case .BR, .BR_IF:                 return .LABEL
	case .CALL, .REF_FUNC:            return .FUNC
	case .CALL_INDIRECT:              return which == 0 ? .TYPE : .TABLE
	case .LOCAL_GET, .LOCAL_SET, .LOCAL_TEE:   return .LOCAL
	case .GLOBAL_GET, .GLOBAL_SET:    return .GLOBAL
	case .MEMORY_INIT, .DATA_DROP:    return .DATA
	case .TABLE_INIT:                 return which == 0 ? .ELEM : .TABLE
	case .ELEM_DROP:                  return .ELEM
	case .TABLE_COPY:                 return .TABLE
	case .TABLE_GROW, .TABLE_SIZE, .TABLE_FILL: return .TABLE
	}
	return .NONE
}

@(private="file")
reloc_label_at :: #force_inline proc "contextless" (relocs: []Relocation, offset: u32) -> (label_id: u32, found: bool) {
	for r in relocs {
		if r.offset == offset {
			return r.label_id, true
		}
	}
	return
}
