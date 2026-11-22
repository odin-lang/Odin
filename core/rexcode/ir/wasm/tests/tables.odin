package rexcode_wasm_tests

import "core:slice"
import "core:strings"
import "core:testing"
import wasm ".."

@(test)
test_encoding_and_decoding_tables_agree :: proc(t: ^testing.T) {
	for op in wasm.Opcode {
		if op == .INVALID {
			continue
		}
		e := wasm.ENCODING_TABLE[op]
		back := decode_table_lookup(e.prefix, e.opcode)
		testing.expectf(t, back == op, "%v encodes as %02x %x, which decodes as %v", op, e.prefix, e.opcode, back)
		testing.expectf(t, wasm.MNEMONIC_NAMES[op] != "", "%v has no mnemonic", op)
	}
	check_decode_table(t, wasm.PREFIX_NONE, wasm.DECODE_MAIN[:])
	check_decode_table(t, wasm.PREFIX_MISC, wasm.DECODE_MISC[:])
	check_decode_table(t, wasm.PREFIX_SIMD, wasm.DECODE_SIMD[:])
	check_decode_table(t, wasm.PREFIX_ATOM, wasm.DECODE_ATOMIC[:])
}

@(test)
test_every_opcode_round_trips :: proc(t: ^testing.T) {
	for op in wasm.Opcode {
		if op == .INVALID {
			continue
		}
		bytes, code := encode_one_op(wasm.operation(op, sample_operands(wasm.ENCODING_TABLE[op].imm)))
		if !testing.expectf(t, code == .NONE, "%v: encode failed with %v", op, code) {
			continue
		}
		back, ok := decode_one_op(bytes)
		if !testing.expectf(t, ok, "%v: % x does not decode", op, bytes) {
			continue
		}
		testing.expectf(t, wasm.Opcode(back.opcode) == op, "%v: % x decodes as %v", op, bytes, wasm.Opcode(back.opcode))
		again, code2 := encode_one_op(back)
		testing.expectf(t, code2 == .NONE && slice.equal(again, bytes), "%v: % x re-encodes as % x (%v)", op, bytes, again, code2)
		text := op_text(back)
		testing.expectf(t, strings.has_prefix(text, wasm.MNEMONIC_NAMES[op]), "%v prints as %q", op, text)
	}
}

@(private="file")
decode_table_lookup :: proc(prefix: u8, sub: u16) -> wasm.Opcode {
	switch prefix {
	case wasm.PREFIX_NONE:
		if int(sub) < wasm.DECODE_MAIN_COUNT { return wasm.DECODE_MAIN[sub] }
	case wasm.PREFIX_MISC:
		if int(sub) < wasm.DECODE_MISC_COUNT { return wasm.DECODE_MISC[sub] }
	case wasm.PREFIX_SIMD:
		if int(sub) < wasm.DECODE_SIMD_COUNT { return wasm.DECODE_SIMD[sub] }
	case wasm.PREFIX_ATOM:
		if int(sub) < wasm.DECODE_ATOMIC_COUNT { return wasm.DECODE_ATOMIC[sub] }
	}
	return .INVALID
}

@(private="file")
check_decode_table :: proc(t: ^testing.T, prefix: u8, table: []wasm.Opcode) {
	for op, i in table {
		if op == .INVALID {
			continue
		}
		e := wasm.ENCODING_TABLE[op]
		testing.expectf(t, e.prefix == prefix && int(e.opcode) == i, "%02x %x decodes as %v, which encodes as %02x %x", prefix, i, op, e.prefix, e.opcode)
	}
}

@(private="file")
sample_operands :: proc(imm: [2]wasm.Imm_Kind) -> []wasm.Operand {
	out := make([dynamic]wasm.Operand, context.temp_allocator)
	for k in imm {
		switch k {
		case .NONE, .ZERO_BYTE:
		case .BLOCKTYPE: append(&out, wasm.op_blocktype(.I32))
		case .I32:       append(&out, wasm.op_i32(min(i32)))
		case .I64:       append(&out, wasm.op_i64(min(i64)))
		case .F32:       append(&out, wasm.op_f32(-1.5))
		case .F64:       append(&out, wasm.op_f64(2.25))
		case .IDX:       append(&out, wasm.op_wasm_index(.NONE, 300))
		case .MEMARG:    append(&out, wasm.op_memarg(wasm.memarg(3, 1 << 40, 2)))
		case .REFTYPE:   append(&out, wasm.op_reftype(.EXTERNREF))
		case .BR_TABLE:  append(&out, wasm.op_labelidx(2), wasm.op_labelidx(0), wasm.op_labelidx(1))
		case .LANE:      append(&out, wasm.op_lane(1))
		case .LANES16:
			lo, hi := wasm.op_v128({0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15})
			append(&out, lo, hi)
		case .VALTYPES:  append(&out, wasm.op_valtype(.F64), wasm.op_valtype(.V128))
		}
	}
	return out[:]
}
