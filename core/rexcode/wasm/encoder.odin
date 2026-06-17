// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)

package rexcode_wasm

// =============================================================================
// WebAssembly ENCODER
// =============================================================================
//
// Variable-length, byte-oriented, LEB128-heavy. Because LEB fields are not a
// fixed width, encoding is sequential: a single forward pass writes each
// instruction's opcode (a byte, or a prefix byte plus an unsigned-LEB
// sub-opcode) followed by its immediates, advancing a byte cursor.
//
// WASM has no PC-relative branches (control flow uses structured label
// depths), so there is no second resolution pass and no rewrite of
// `label_defs`: those parameters are part of the universal signature but are
// inert here. Relocations *are* produced -- for symbolic index references
// (see op_label) -- and returned for a linker to patch; symbolic indices are
// laid down as fixed-width 5-byte LEB placeholders so the patched value fits.

MAX_OPCODE_SIZE :: 3   // prefix byte + two-byte unsigned-LEB sub-opcode (SIMD reaches 0x113)

@(require_results)
encode_max_code_size :: #force_inline proc "contextless" (n: int) -> int {
	// Worst case per instruction without a br_table: a 3-byte opcode plus the
	// largest single immediate, which is v128.const's 16 raw bytes (a memarg+
	// lane pair is smaller). br_table is unbounded in its target count;
	// callers encoding tables should size from the target totals.
	return n * 24
}
@(require_results)
encode_max_relocation_count :: #force_inline proc "contextless" (n: int) -> int {
	return n
}

encode :: proc(
	instructions: []Instruction,
	label_defs:   []Label_Definition,
	code:         []u8,
	relocs:       ^[dynamic]Relocation,
	errors:       ^[dynamic]Error,
) -> (byte_count: u32, ok: bool) {
	errors_start := u32(len(errors))

	for &inst, i in instructions {
		n := encode_one(&inst, byte_count, u16(i), code, relocs, errors) or_return
		inst.length = u8(min(n, 255))
		byte_count += n
	}

	ok = u32(len(errors)) == errors_start
	return
}


encode_one :: #force_inline proc(
	inst:     ^Instruction,
	pc:       u32,
	inst_idx: u16,
	code:     []u8,
	relocs:   ^[dynamic]Relocation,
	errors:   ^[dynamic]Error,
) -> (size: u32, ok: bool) {
	if inst.mnemonic == .INVALID {
		append(errors, Error{inst_idx = u32(inst_idx), code = .INVALID_MNEMONIC})
		return
	}
	form := encoding_form(inst.mnemonic)

	need := encoded_size(inst, form)
	if pc + need > u32(len(code)) {
		append(errors, Error{inst_idx = u32(inst_idx), code = .BUFFER_OVERFLOW})
		return
	}

	off := pc

	// Opcode (and prefix sub-opcode).
	if form.prefix == PREFIX_NONE {
		code[off] = u8(form.opcode)
		off += 1
	} else {
		code[off] = form.prefix
		off += 1
		write_uleb(code, &off, u64(form.opcode))
	}

	// Immediates, walked in declaration order with an operand cursor.
	opi := 0
	for k in form.imm {
		switch k {
		case .NONE:
			// nothing
		case .BLOCKTYPE, .I32, .I64:
			write_sleb(code, &off, inst.ops[opi].immediate)
			opi += 1
		case .F32:
			write_u32le(code, &off, u32(inst.ops[opi].immediate))
			opi += 1
		case .F64:
			write_u64le(code, &off, u64(inst.ops[opi].immediate))
			opi += 1
		case .IDX:
			op := &inst.ops[opi]
			if op.flags.symbolic {
				append(relocs, Relocation{
					offset = off, label_id = op.index, addend = 0,
					type = reloc_type_for(op.idx_kind), size = 5, inst_idx = inst_idx,
				})
				write_uleb_padded5(code, &off, u64(op.index))
			} else {
				write_uleb(code, &off, u64(op.index))
			}
			opi += 1
		case .MEMARG:
			ma := inst.ops[opi].memarg
			write_uleb(code, &off, u64(ma.align))
			write_uleb(code, &off, u64(ma.offset))
			opi += 1
		case .REFTYPE:
			code[off] = u8(inst.ops[opi].immediate)
			off += 1
			opi += 1
		case .BR_TABLE:
			write_uleb(code, &off, u64(len(inst.targets)))
			for t in inst.targets {
				write_uleb(code, &off, u64(t))
			}
			write_uleb(code, &off, u64(inst.ops[opi].index))   // default depth
			opi += 1
		case .ZERO_BYTE:
			code[off] = 0x00
			off += 1
		case .LANE:
			code[off] = u8(inst.ops[opi].immediate)
			off += 1
			opi += 1
		case .LANES16:
			for bb in inst.bytes {
				code[off] = bb
				off += 1
			}
		}
	}

	return off - pc, true
}

@(private="file")
encoded_size :: proc(inst: ^Instruction, form: ^Encoding) -> u32 {
	size: u32 = 1
	if form.prefix != PREFIX_NONE {
		size += uleb_size(u64(form.opcode))
	}
	opi := 0
	for k in form.imm {
		switch k {
		case .NONE:
		case .BLOCKTYPE, .I32, .I64:
			size += sleb_size(inst.ops[opi].immediate)
			opi  += 1
		case .F32:
			size += 4
			opi  += 1
		case .F64:
			size += 8
			opi  += 1
		case .IDX:
			op := &inst.ops[opi]
			size += op.flags.symbolic ? 5 : uleb_size(u64(op.index))
			opi  += 1
		case .MEMARG:
			ma := inst.ops[opi].memarg
			size += uleb_size(u64(ma.align)) + uleb_size(u64(ma.offset))
			opi  += 1
		case .REFTYPE:
			size += 1
			opi  += 1
		case .BR_TABLE:
			size += uleb_size(u64(len(inst.targets)))
			for t in inst.targets {
				size += uleb_size(u64(t))
			}
			size += uleb_size(u64(inst.ops[opi].index))
			opi  += 1
		case .ZERO_BYTE:
			size += 1
		case .LANE:
			size += 1
			opi  += 1
		case .LANES16:
			size += 16
		}
	}
	return size
}

@(private="file")
reloc_type_for :: #force_inline proc "contextless" (k: Index_Kind) -> Relocation_Type {
	#partial switch k {
	case .FUNC:   return .FUNCTION_INDEX_LEB
	case .TYPE:   return .TYPE_INDEX_LEB
	case .GLOBAL: return .GLOBAL_INDEX_LEB
	case .TABLE:  return .TABLE_NUMBER_LEB
	}
	return .FUNCTION_INDEX_LEB
}
