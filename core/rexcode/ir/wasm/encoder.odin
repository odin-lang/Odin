// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)

package rexcode_wasm

import "core:math/bits"

// =============================================================================
// SECTION: Encoder  (Module -> WASM instruction byte stream)
// =============================================================================
//
// Variable-length, byte-oriented, LEB128-heavy. Encoding is a single forward
// pass: each operation writes its opcode (a byte, or a prefix byte plus an
// unsigned-LEB sub-opcode) followed by its immediates, advancing a byte cursor.
//
// WASM has no PC-relative branches (control flow uses structured label depths),
// so there is no second resolution pass -- which is exactly why the ir verbs
// (docs/ir_design.md §4) drop the ISA `label_defs`/`resolve`/`base_address`.
// Relocations *are* produced, for symbolic index references (see op_label), and
// returned for a linker to patch; symbolic indices are laid down as fixed-width
// 5-byte LEB placeholders so the patched value always fits.
//
// The reusable core is `encode_ops` (an operation stream = a WASM `expr`). The
// Module verb `encode` drives it over each function's body blocks. Byte-level
// container framing (the type/function/code section wrappers) is a separate,
// symmetric concern -- the sibling container reader lives in the WASM `module`
// parsing path -- and is not part of this instruction-stream codec.

MAX_OPCODE_SIZE :: 3   // prefix byte + two-byte unsigned-LEB sub-opcode (SIMD reaches 0x113)

@(require_results)
encode_max_code_size :: #force_inline proc "contextless" (n: int) -> int {
	// Worst case per op without a br_table: a 3-byte opcode plus the largest
	// single immediate, v128.const's 16 raw bytes. br_table is unbounded in its
	// target count; callers encoding those should size from the target totals.
	return n * 24
}
@(require_results)
encode_max_relocation_count :: #force_inline proc "contextless" (n: int) -> int {
	return n
}

// encode: serialize the module's function bodies into `code`, in order. Returns
// the total byte count written. (A Module built as one function / one block
// reproduces the old flat `encode([]Instruction)` behavior exactly.)
encode :: proc(m: Module, code: []u8, relocs: ^[dynamic]Relocation, errors: ^[dynamic]Error) -> (byte_count: u32, ok: bool) {
	errors_start := u32(len(errors))
	op_index := u16(0)
	for fn in m.functions {
		for blk in fn.blocks {
			for &op in blk.ops {
				n := encode_operation(&op, byte_count, op_index, code, relocs, errors) or_return
				byte_count += n
				op_index += 1
			}
		}
	}
	ok = u32(len(errors)) == errors_start
	return
}

// encode_ops: the reusable instruction-stream encoder (a WASM `expr`).
encode_ops :: proc(ops: []Operation, code: []u8, relocs: ^[dynamic]Relocation, errors: ^[dynamic]Error) -> (byte_count: u32, ok: bool) {
	errors_start := u32(len(errors))
	for &op, i in ops {
		n := encode_operation(&op, byte_count, u16(i), code, relocs, errors) or_return
		byte_count += n
	}
	ok = u32(len(errors)) == errors_start
	return
}

encode_operation :: proc(
	op:       ^Operation,
	pc:       u32,
	op_index: u16,
	code:     []u8,
	relocs:   ^[dynamic]Relocation,
	errors:   ^[dynamic]Error,
) -> (size: u32, ok: bool) {
	opcode := Opcode(op.opcode)
	if opcode == .INVALID {
		append(errors, Error{location = u32(op_index), code = .INVALID_OPCODE})
		return
	}
	form := encoding_form(opcode)

	need := encoded_size(op, form)
	if pc + need > u32(len(code)) {
		append(errors, Error{location = u32(op_index), code = .BUFFER_OVERFLOW})
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
			write_sleb(code, &off, op.operands[opi].imm)
			opi += 1

		case .F32:
			write_u32_block(code, &off, u32(op.operands[opi].imm))
			opi += 1

		case .F64:
			write_u64_block(code, &off, u64(op.operands[opi].imm))
			opi += 1

		case .IDX:
			o := op.operands[opi]
			if operand_symbolic(o) {
				append(relocs, Relocation{
					offset = off, label_id = operand_index(o), addend = 0,
					type = reloc_type_for(operand_index_kind(o)), size = 5, inst_idx = op_index,
				})
				write_uleb_padded5(code, &off, u64(operand_index(o)))
			} else {
				write_uleb(code, &off, u64(operand_index(o)))
			}
			opi += 1

		case .MEMARG:
			ma := operand_memarg(op.operands[opi])
			// NOTE(bill): stored as log2 even though the spec text reads otherwise.
			align := bits.log2(u64(ma.align))
			write_uleb(code, &off, align)
			write_uleb(code, &off, u64(ma.offset))
			opi += 1

		case .REFTYPE:
			code[off] = u8(op.operands[opi].imm)
			off += 1
			opi += 1

		case .BR_TABLE:
			// operands = [default, case0, case1, ...] -- every entry a label depth.
			cases := op.operands[opi + 1:]
			write_uleb(code, &off, u64(len(cases)))
			for c in cases {
				write_uleb(code, &off, u64(operand_index(c)))
			}
			write_uleb(code, &off, u64(operand_index(op.operands[opi])))   // default
			opi = len(op.operands)

		case .ZERO_BYTE:
			code[off] = 0x00
			off += 1

		case .LANE:
			code[off] = u8(op.operands[opi].imm)
			off += 1
			opi += 1

		case .LANES16:
			bytes := operand_v128(op.operands[opi], op.operands[opi + 1])
			for bb in bytes {
				code[off] = bb
				off += 1
			}
			opi += 2
		}
	}

	return off - pc, true
}

@(private="file")
encoded_size :: proc(op: ^Operation, form: ^Encoding) -> u32 {
	size: u32 = 1
	if form.prefix != PREFIX_NONE {
		size += uleb_size(u64(form.opcode))
	}
	opi := 0
	for k in form.imm {
		switch k {
		case .NONE:
		case .BLOCKTYPE, .I32, .I64:
			size += sleb_size(op.operands[opi].imm)
			opi  += 1
		case .F32:
			size += 4
			opi  += 1
		case .F64:
			size += 8
			opi  += 1
		case .IDX:
			o := op.operands[opi]
			size += operand_symbolic(o) ? 5 : uleb_size(u64(operand_index(o)))
			opi  += 1
		case .MEMARG:
			ma := operand_memarg(op.operands[opi])
			size += uleb_size(bits.log2(u64(ma.align))) + uleb_size(u64(ma.offset))
			opi  += 1
		case .REFTYPE:
			size += 1
			opi  += 1
		case .BR_TABLE:
			cases := op.operands[opi + 1:]
			size += uleb_size(u64(len(cases)))
			for c in cases {
				size += uleb_size(u64(operand_index(c)))
			}
			size += uleb_size(u64(operand_index(op.operands[opi])))
			opi = len(op.operands)
		case .ZERO_BYTE:
			size += 1
		case .LANE:
			size += 1
			opi  += 1
		case .LANES16:
			size += 16
			opi  += 2
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
