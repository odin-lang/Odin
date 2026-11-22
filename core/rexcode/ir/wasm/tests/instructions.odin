package rexcode_wasm_tests

import "core:slice"
import "core:testing"
import wasm ".."

@(test)
test_instructions_decode_print_and_reencode :: proc(t: ^testing.T) {
	Case :: struct {
		bytes:     []u8,
		text:      string,
		canonical: []u8,
	}
	cases := [?]Case{
		{{0x11, 0x02, 0x00}, "call_indirect (type 2)", nil},
		{{0x11, 0x02, 0x01}, "call_indirect 1 (type 2)", nil},
		{{0x11, 0x02, 0x80, 0x80, 0x80, 0x80, 0x00}, "call_indirect (type 2)", {0x11, 0x02, 0x00}},
		{{0x13, 0x00, 0x03}, "return_call_indirect 3 (type 0)", nil},
		{{0x12, 0x05}, "return_call 5", nil},
		{{0x1b}, "select", nil},
		{{0x1c, 0x01, 0x7f}, "select (result i32)", nil},
		{{0x1c, 0x02, 0x7e, 0x7b}, "select (result i64 v128)", nil},
		{{0x25, 0x01}, "table.get 1", nil},
		{{0x26, 0x00}, "table.set 0", nil},
		{{0x28, 0x02, 0x08}, "i32.load offset=8 align=4", nil},
		{{0x28, 0x42, 0x01, 0x00}, "i32.load 1 align=4", nil},
		{{0x29, 0x03, 0x80, 0x80, 0x80, 0x80, 0x80, 0x01}, "i64.load offset=34359738368 align=8", nil},
		{{0x36, 0x40, 0x07, 0x04}, "i32.store 7 offset=4 align=1", nil},
		{{0x3f, 0x00}, "memory.size", nil},
		{{0x3f, 0x02}, "memory.size 2", nil},
		{{0x40, 0x00}, "memory.grow", nil},
		{{0xfc, 0x08, 0x05, 0x00}, "memory.init 5", nil},
		{{0xfc, 0x08, 0x05, 0x01}, "memory.init 1 5", nil},
		{{0xfc, 0x09, 0x05}, "data.drop 5", nil},
		{{0xfc, 0x0a, 0x00, 0x00}, "memory.copy", nil},
		{{0xfc, 0x0a, 0x01, 0x02}, "memory.copy 1 2", nil},
		{{0xfc, 0x0b, 0x00}, "memory.fill", nil},
		{{0xfc, 0x0b, 0x03}, "memory.fill 3", nil},
		{{0xfc, 0x0c, 0x04, 0x02}, "table.init 2 4", nil},
		{{0xfc, 0x0e, 0x01, 0x02}, "table.copy 1 2", nil},
		{{0xfe, 0x03, 0x00}, "atomic.fence", nil},
		{{0x02, 0x40}, "block", nil},
		{{0x02, 0x7f}, "block (result i32)", nil},
		{{0x02, 0x05}, "block (type 5)", nil},
		{{0x41, 0x80, 0x80, 0x80, 0x80, 0x78}, "i32.const -2147483648", nil},
		{{0x42, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x7f}, "i64.const -9223372036854775808", nil},
		{{0xd0, 0x70}, "ref.null func", nil},
		{{0x43, 0x00, 0x00, 0xc0, 0x7f}, "f32.const nan", nil},
		{{0x43, 0x01, 0x00, 0x80, 0xff}, "f32.const -nan:0x1", nil},
		{{0x43, 0x00, 0x00, 0x80, 0x7f}, "f32.const inf", nil},
		{{0x43, 0x00, 0x00, 0xc0, 0x3f}, "f32.const 1.5", nil},
		{{0x43, 0x00, 0x00, 0x00, 0x80}, "f32.const -0", nil},
		{{0x44, 0x9a, 0x99, 0x99, 0x99, 0x99, 0x99, 0xb9, 0x3f}, "f64.const 0.1", nil},
		{{0x44, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf0, 0xff}, "f64.const -inf", nil},
		{{0x44, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf8, 0x7f}, "f64.const nan", nil},
		{{0x44, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0xf8, 0x7f}, "f64.const nan:0x8000000000001", nil},
		{{0x0e, 0x02, 0x00, 0x01, 0x02}, "br_table 0 1 2", nil},
	}
	for c in cases {
		op, ok := decode_one_op(c.bytes)
		if !testing.expectf(t, ok, "% x does not decode", c.bytes) {
			continue
		}
		text := op_text(op)
		testing.expectf(t, text == c.text, "% x prints %q, want %q", c.bytes, text, c.text)
		want := c.canonical if c.canonical != nil else c.bytes
		again, code := encode_one_op(op)
		testing.expectf(t, code == .NONE && slice.equal(again, want), "% x re-encodes as % x (%v), want % x", c.bytes, again, code, want)
	}
}

@(test)
test_malformed_instructions_are_rejected :: proc(t: ^testing.T) {
	cases := [?][]u8{
		{0x28, 0x80, 0x01, 0x00},
		{0x11, 0x02, 0x80, 0x80, 0x80, 0x80, 0x10},
		{0x11, 0x02},
		{0x1c, 0x01, 0x40},
		{0x1c, 0x05, 0x7f},
		{0x1c, 0xff, 0xff, 0xff, 0xff, 0x0f},
		{0x0e, 0xff, 0xff, 0xff, 0xff, 0x0f},
		{0xfe, 0x03, 0x01},
		{0x02, 0x41},
		{0x02, 0x80, 0x80, 0x80, 0x80, 0x20},
		{0x41, 0xff, 0xff, 0xff, 0xff, 0x0f},
		{0x41, 0x80, 0x80, 0x80, 0x80, 0x80, 0x00},
		{0xfc, 0x80, 0x80, 0x80, 0x80, 0x10},
		{0xd0, 0x7f},
		{0x25},
		{0x3f, 0x80, 0x80, 0x80, 0x80, 0x80, 0x00},
		{0xfc, 0x08, 0x05},
		{0x29, 0x03, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x02},
	}
	for c in cases {
		_, ok := decode_one_op(c)
		testing.expectf(t, !ok, "% x decodes", c)
	}
}

@(test)
test_encoder_rejects_bad_operands :: proc(t: ^testing.T) {
	Case :: struct {
		op:   wasm.Operation,
		code: wasm.Error_Code,
	}
	block_type_too_big := wasm.Operand{kind = .ATTRIBUTE, imm = 1 << 32, aux = u16(wasm.Attr.BLOCKTYPE)}
	index_too_big := wasm.Operand{kind = .REF, imm = 1 << 32, aux = u16(wasm.Index_Kind.LOCAL)}
	lane_too_big := wasm.Operand{kind = .ATTRIBUTE, imm = 256, aux = u16(wasm.Attr.LANE)}

	one_type   := [?]wasm.Operand{wasm.op_typeidx(1)}
	big_i32    := [?]wasm.Operand{wasm.op_int(1 << 31)}
	small_i32  := [?]wasm.Operand{wasm.op_int(-1 << 31 - 1)}
	wide_align := [?]wasm.Operand{wasm.op_memarg(wasm.memarg(64, 0))}
	bad_block  := [?]wasm.Operand{wasm.op_blocktype(wasm.Block_Type(-63))}
	big_block  := [?]wasm.Operand{block_type_too_big}
	bad_ref    := [?]wasm.Operand{wasm.op_reftype(.I32)}
	bad_select := [?]wasm.Operand{wasm.op_valtype(wasm.Value_Type(0x40))}
	big_index  := [?]wasm.Operand{index_too_big}
	big_lane   := [?]wasm.Operand{lane_too_big}
	big_label  := [?]wasm.Operand{wasm.op_labelidx(0), index_too_big}
	extra      := [?]wasm.Operand{wasm.op_int(1)}

	cases := [?]Case{
		{wasm.operation(.CALL_INDIRECT, one_type[:]), .OPERAND_MISMATCH},
		{wasm.operation(.I32_CONST, big_i32[:]), .IMMEDIATE_OUT_OF_RANGE},
		{wasm.operation(.I32_CONST, small_i32[:]), .IMMEDIATE_OUT_OF_RANGE},
		{wasm.operation(.I32_LOAD, wide_align[:]), .IMMEDIATE_OUT_OF_RANGE},
		{wasm.operation(.BLOCK, bad_block[:]), .IMMEDIATE_OUT_OF_RANGE},
		{wasm.operation(.BLOCK, big_block[:]), .IMMEDIATE_OUT_OF_RANGE},
		{wasm.operation(.REF_NULL, bad_ref[:]), .IMMEDIATE_OUT_OF_RANGE},
		{wasm.operation(.SELECT_T, bad_select[:]), .IMMEDIATE_OUT_OF_RANGE},
		{wasm.operation(.LOCAL_GET, big_index[:]), .IMMEDIATE_OUT_OF_RANGE},
		{wasm.operation(.I8X16_EXTRACT_LANE_S, big_lane[:]), .IMMEDIATE_OUT_OF_RANGE},
		{wasm.operation(.BR_TABLE, big_label[:]), .IMMEDIATE_OUT_OF_RANGE},
		{wasm.operation(.LOCAL_GET), .OPERAND_MISMATCH},
		{wasm.operation(.NOP, extra[:]), .OPERAND_MISMATCH},
		{wasm.operation(.BR_TABLE), .OPERAND_MISMATCH},
		{wasm.Operation{opcode = u16(max(wasm.Opcode)) + 1}, .INVALID_OPCODE},
		{wasm.Operation{opcode = 0}, .INVALID_OPCODE},
	}
	for c in cases {
		bytes, code := encode_one_op(c.op)
		testing.expectf(t, code == c.code, "%v encodes as % x with %v, want %v", wasm.Opcode(c.op.opcode), bytes, code, c.code)
	}
}

@(test)
test_builder_emits_wasm_3_immediates :: proc(t: ^testing.T) {
	b := wasm.builder_make(context.temp_allocator)
	wasm.emit_call_indirect(&b, 2, 1)
	wasm.emit_load(&b, .I32_LOAD, wasm.memarg(2, 8, 1))
	wasm.emit_store(&b, .I64_STORE, wasm.memarg(3, 1 << 33))
	wasm.emit(&b, .MEMORY_INIT, wasm.op_data(5), wasm.op_memory(1))
	wasm.emit(&b, .MEMORY_COPY, wasm.op_memory(1), wasm.op_memory(0))
	wasm.emit(&b, .SELECT_T, wasm.op_valtype(.F32))
	wasm.emit(&b, .TABLE_GET, wasm.op_table(3))
	blk := wasm.take_block(&b)

	buf := make([]u8, 64, context.temp_allocator)
	relocs := make([dynamic]wasm.Relocation, context.temp_allocator)
	errors := make([dynamic]wasm.Error, context.temp_allocator)
	n, ok := wasm.encode_ops(blk.ops, buf, &relocs, &errors)
	want := []u8{
		0x11, 0x02, 0x01,
		0x28, 0x42, 0x01, 0x08,
		0x37, 0x03, 0x80, 0x80, 0x80, 0x80, 0x20,
		0xfc, 0x08, 0x05, 0x01,
		0xfc, 0x0a, 0x01, 0x00,
		0x1c, 0x01, 0x7d,
		0x25, 0x03,
	}
	testing.expectf(t, ok && slice.equal(buf[:n], want), "encoded % x (%v), want % x", buf[:n], errors[:], want)

	small := make([]u8, 10, context.temp_allocator)
	clear(&errors)
	_, ok = wasm.encode_ops(blk.ops, small, &relocs, &errors)
	testing.expect(t, !ok && len(errors) == 1 && errors[0].code == .BUFFER_OVERFLOW)
}
