// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)

package rexcode_wasm

import "base:runtime"

// =============================================================================
// SECTION: Decoder  (WASM instruction byte stream -> ir.Operations / Module)
// =============================================================================
//
// Single forward pass, mirroring the encoder. Each step reads an opcode (a
// leading 0xFC/0xFD/0xFE switches to a prefix group whose sub-opcode is an
// unsigned LEB128; otherwise the single byte is the opcode), looks its form up
// in ENCODING_TABLE, and reads the immediates in declaration order, building the
// operation's variable-arity `[]Operand` as it goes.
//
// WASM control flow is structured (branches carry relative label depths, not
// byte offsets), so there is no PC-relative label inference. Object-file index
// relocations *are* re-attached: when an input relocation lands on a decoded
// index field, that operand is marked symbolic and carries the label id.

// decode_expr: parse a bare WASM `expr` byte stream (one instruction stream,
// no container) into a single-function, single-block Module (dataflow = .STACK).
// The full-container module verb is `decode` (parse.odin); the reusable
// stream-level decoder both share is `decode_ops`.
decode_expr :: proc(
	data:      []u8,
	m:         ^Module,
	errors:    ^[dynamic]Error,
	allocator := context.allocator,
) -> (byte_count: u32, ok: bool) {
	ops: []Operation
	ops, byte_count, ok = decode_ops(data, nil, errors, allocator)

	blocks := make([]Block, 1, allocator)
	blocks[0] = Block{id = ID_NONE, ops = ops}
	funcs := make([]Function, 1, allocator)
	funcs[0] = Function{blocks = blocks, signature = TYPE_NONE}

	m.base.dataflow  = .STACK
	m.base.functions = funcs
	m.version        = WASM_VERSION
	m.start          = -1
	return
}

// decode_ops: the reusable instruction-stream decoder. `relocs` (may be nil) are
// the input relocations to re-attach to symbolic index fields.
decode_ops :: proc(
	data:      []u8,
	relocs:    []Relocation,
	errors:    ^[dynamic]Error,
	allocator := context.allocator,
) -> (ops: []Operation, byte_count: u32, ok: bool) {
	errors_start := u32(len(errors))
	acc := make([dynamic]Operation, allocator)
	n := u32(len(data))

	for byte_count < n {
		op, next, dok := decode_one(data, relocs, byte_count, allocator)
		if !dok {
			append(errors, Error{location = byte_count, code = .INVALID_OPCODE})
			append(&acc, operation(.INVALID))
			byte_count += 1
			continue
		}
		append(&acc, op)
		byte_count = next
	}

	ops = acc[:]
	ok = u32(len(errors)) == errors_start
	return
}

@(require_results)
decode_one :: proc(
	data:      []u8,
	relocs:    []Relocation,
	pc:        u32,
	allocator: runtime.Allocator,
) -> (op: Operation, next: u32, ok: bool) {
	off := pc
	if off >= u32(len(data)) {
		next = pc
		return
	}

	b0 := data[off]
	off += 1

	m: Opcode = .INVALID
	switch b0 {
	case PREFIX_MISC:
		sub := read_uleb(data, &off) or_return
		if sub < u64(DECODE_MISC_COUNT)   { m = DECODE_MISC[sub] }
	case PREFIX_SIMD:
		sub := read_uleb(data, &off) or_return
		if sub < u64(DECODE_SIMD_COUNT)   { m = DECODE_SIMD[sub] }
	case PREFIX_ATOM:
		sub := read_uleb(data, &off) or_return
		if sub < u64(DECODE_ATOMIC_COUNT) { m = DECODE_ATOMIC[sub] }
	case:
		m = DECODE_MAIN[b0]
	}
	if m == .INVALID {
		next = pc
		return
	}

	form := encoding_form(m)
	operands := make([dynamic]Operand, allocator)

	for k, ki in form.imm {
		switch k {
		case .NONE:
			// nothing

		case .BLOCKTYPE:
			v := read_sleb(data, &off) or_return
			append(&operands, Operand{kind = .ATTRIBUTE, imm = v, aux = u16(Attr.BLOCKTYPE)})

		case .I32:
			v := read_sleb(data, &off) or_return
			append(&operands, op_int(v))

		case .I64:
			v := read_sleb(data, &off) or_return
			append(&operands, op_int(v))

		case .F32:
			b := read_u32_block(data, &off) or_return
			append(&operands, op_float(u64(b), 32))

		case .F64:
			b := read_u64_block(data, &off) or_return
			append(&operands, op_float(b, 64))

		case .IDX:
			field := off
			raw := read_uleb(data, &off) or_return
			kind := idx_kind_for(m, ki)
			o := op_wasm_index(kind, u32(raw))
			// An index is symbolic only when an input relocation actually lands
			// on this field; otherwise it is a concrete, self-contained index
			// (so a relocation-free stream round-trips byte-for-byte).
			if lid, found := reloc_label_at(relocs, field); found {
				o = op_wasm_index(kind, lid, symbolic = true)
			}
			append(&operands, o)

		case .MEMARG:
			align  := read_uleb(data, &off) or_return
			offset := read_uleb(data, &off) or_return
			// Stored as log2 on the wire; expand back to a byte alignment.
			append(&operands, op_memarg(Memarg{align = u32(1 << align), offset = u32(offset)}))

		case .REFTYPE:
			if off >= u32(len(data)) {
				next = pc
				return
			}
			t := data[off]
			off += 1
			append(&operands, Operand{kind = .ATTRIBUTE, imm = i64(t), aux = u16(Attr.REFTYPE)})

		case .BR_TABLE:
			count := int(read_uleb(data, &off) or_return)
			default_index := len(operands)
			reserve(&operands, count+1)
			append(&operands, Operand{}) // dummy for default
			for i in 0 ..< int(count) {
				t := read_uleb(data, &off) or_return
				append(&operands, op_labelidx(u32(t)))
			}
			def := read_uleb(data, &off) or_return
			operands[default_index] = op_labelidx(u32(def)) // default first

		case .ZERO_BYTE:
			if off >= u32(len(data)) {
				next = pc
				return
			}
			off += 1 // reserved 0x00, consumes no operand

		case .LANE:
			if off >= u32(len(data)) {
				next = pc
				return
			}
			l := data[off]
			off += 1
			append(&operands, Operand{kind = .ATTRIBUTE, imm = i64(l), aux = u16(Attr.LANE)})

		case .LANES16:
			if off + 16 > u32(len(data)) {
				next = pc
				return
			}
			bytes: [16]u8
			copy(bytes[:], data[off:][:16])
			off += 16
			lo, hi := op_v128(bytes)
			append(&operands, lo)
			append(&operands, hi)
		}
	}

	op = operation(m, operands[:])
	next = off
	ok = true
	return
}

// Which index space the IDX immediate in operand slot `which` addresses, by
// opcode. Mirrors how the builders tag each operand.
@(private="file", require_results)
idx_kind_for :: #force_inline proc "contextless" (m: Opcode, which: int) -> Index_Kind {
	#partial switch m {
	case .BR, .BR_IF:                           return .LABEL
	case .CALL, .REF_FUNC:                      return .FUNC
	case .CALL_INDIRECT:                        return .TYPE if which == 0 else .TABLE
	case .LOCAL_GET, .LOCAL_SET, .LOCAL_TEE:    return .LOCAL
	case .GLOBAL_GET, .GLOBAL_SET:              return .GLOBAL
	case .MEMORY_INIT, .DATA_DROP:              return .DATA
	case .TABLE_INIT:                           return .ELEM if which == 0 else .TABLE
	case .ELEM_DROP:                            return .ELEM
	case .TABLE_COPY:                           return .TABLE
	case .TABLE_GROW, .TABLE_SIZE, .TABLE_FILL: return .TABLE
	}
	return .NONE
}

@(private="file", require_results)
reloc_label_at :: #force_inline proc "contextless" (relocs: []Relocation, offset: u32) -> (label_id: u32, found: bool) {
	for r in relocs {
		if r.offset == offset {
			return r.label_id, true
		}
	}
	return
}
