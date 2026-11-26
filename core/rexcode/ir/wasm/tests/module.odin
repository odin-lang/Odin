package rexcode_wasm_tests

import "core:slice"
import "core:testing"
import wasm ".."

SAMPLE_WAT :: `(module
  (type (;0;) (func (param i32) (result i32)))
  (func $run (type 0) (param i32) (result i32)
    local.get 0
    i32.const 0
    call_indirect (type 0)
  )
  (table (;0;) 1 funcref)
  (memory (;0;) i64 1 2)
  (memory (;1;) 1 1 shared)
  (global (;0;) i32 i32.const 42)
  (export "run" (func 0))
  (elem (;0;) (offset i32.const 0) func 0)
  (data (;0;) (offset i64.const 8) "hi")
)
`

@(test)
test_module_prints_wat :: proc(t: ^testing.T) {
	data := sample_module()
	m: wasm.Module
	errors := make([dynamic]wasm.Error, context.temp_allocator)
	_, ok := wasm.decode(data, &m, &errors, context.temp_allocator)
	if !testing.expectf(t, ok, "decode failed: %v", errors[:]) {
		return
	}
	text := wasm.tprint_wat(m)
	testing.expectf(t, text == SAMPLE_WAT, "printed\n%s\nwant\n%s", text, SAMPLE_WAT)
}

@(test)
test_module_round_trips :: proc(t: ^testing.T) {
	data := sample_module()
	m: wasm.Module
	errors := make([dynamic]wasm.Error, context.temp_allocator)
	_, ok := wasm.decode(data, &m, &errors, context.temp_allocator)
	if !testing.expectf(t, ok, "decode failed: %v", errors[:]) {
		return
	}
	buf := make([]u8, 256, context.temp_allocator)
	relocs := make([dynamic]wasm.Relocation, context.temp_allocator)
	n, eok := wasm.encode(m, buf, &relocs, &errors)
	testing.expectf(t, eok && slice.equal(buf[:n], data), "re-encoded\n% x\nwant\n% x", buf[:n], data)
}

@(test)
test_malformed_modules_are_rejected :: proc(t: ^testing.T) {
	Case :: struct {
		name: string,
		data: []u8,
		err:  wasm.Parse_Error,
	}
	empty_type := section(.TYPE, 0x01, 0x60, 0x00, 0x00)
	one_func := section(.FUNCTION, 0x01, 0x00)
	cases := [?]Case{
		{"version 2", {0x00, 0x61, 0x73, 0x6d, 0x02, 0x00, 0x00, 0x00}, .BAD_VERSION},
		{"truncated header", {0x00, 0x61, 0x73, 0x6d}, .TRUNCATED},
		{"type after function", module_bytes(section(.FUNCTION, 0x00), section(.TYPE, 0x00)), .BAD_SECTION_ORDER},
		{"two type sections", module_bytes(section(.TYPE, 0x00), section(.TYPE, 0x00)), .BAD_SECTION_ORDER},
		{"data count after code", module_bytes(section(.CODE, 0x00), section(.DATA_COUNT, 0x00)), .BAD_SECTION_ORDER},
		{"data count before code", module_bytes(section(.DATA_COUNT, 0x00), section(.CODE, 0x00)), nil},
		{"custom sections anywhere", module_bytes(section(.CUSTOM, 0x01, 'a'), section(.TYPE, 0x00), section(.CUSTOM, 0x01, 'b')), nil},
		{"section id 14", module_bytes({0x0e, 0x00}), .BAD_SECTION_ID},
		{"section past the end", module_bytes({0x01, 0x05, 0x00}), .BAD_SECTION},
		{"section longer than its contents", module_bytes(section(.TYPE, 0x00, 0x00)), .SECTION_SIZE_MISMATCH},
		{"function without code", module_bytes(empty_type, one_func), .FUNCTION_CODE_MISMATCH},
		{"50000 locals", module_bytes(empty_type, one_func, section(.CODE, 0x01, 0x06, 0x01, 0xd0, 0x86, 0x03, 0x7f, 0x0b)), nil},
		{"50001 locals", module_bytes(empty_type, one_func, section(.CODE, 0x01, 0x06, 0x01, 0xd1, 0x86, 0x03, 0x7f, 0x0b)), .TOO_MANY_LOCALS},
		{"2^33 locals", module_bytes(empty_type, one_func, section(.CODE, 0x01, 0x0e, 0x02, 0xff, 0xff, 0xff, 0xff, 0x0f, 0x7f, 0xff, 0xff, 0xff, 0xff, 0x0f, 0x7e, 0x0b)), .TOO_MANY_LOCALS},
		{"bad local type", module_bytes(empty_type, one_func, section(.CODE, 0x01, 0x04, 0x01, 0x01, 0x40, 0x0b)), .BAD_VALTYPE},
		{"limits flags 8", module_bytes(section(.MEMORY, 0x01, 0x08, 0x00)), .BAD_LIMITS},
		{"memory64 limits", module_bytes(section(.MEMORY, 0x01, 0x05, 0x80, 0x80, 0x80, 0x80, 0x80, 0x20, 0x80, 0x80, 0x80, 0x80, 0x80, 0x20)), nil},
		{"memory32 limit over u32", module_bytes(section(.MEMORY, 0x01, 0x00, 0x80, 0x80, 0x80, 0x80, 0x10)), nil},
		{"memory32 limit in 10 bytes", module_bytes(section(.MEMORY, 0x01, 0x01, 0x82, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x00, 0x02)), nil},
		{"memory32 limit in 11 bytes", module_bytes(section(.MEMORY, 0x01, 0x00, 0x82, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x00)), .BAD_ULEB},
		{"memory32 limit over u64", module_bytes(section(.MEMORY, 0x01, 0x00, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x02)), .BAD_ULEB},
		{"table32 limit over u32", module_bytes(section(.TABLE, 0x01, 0x70, 0x00, 0x80, 0x80, 0x80, 0x80, 0x10)), nil},
		{"table64 limits", module_bytes(section(.TABLE, 0x01, 0x70, 0x05, 0x00, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x01)), nil},
		{"shared table", module_bytes(section(.TABLE, 0x01, 0x70, 0x03, 0x00, 0x01)), .BAD_LIMITS},
		{"import shared table", module_bytes(section(.IMPORT, 0x01, 0x01, 'a', 0x01, 'b', 0x01, 0x70, 0x02, 0x00)), .BAD_LIMITS},
		{"table of i32", module_bytes(section(.TABLE, 0x01, 0x7f, 0x00, 0x01)), .BAD_VALTYPE},
		{"overlong custom name", module_bytes(section(.CUSTOM, 0x02, 0xc0, 0x80)), .BAD_NAME},
		{"surrogate custom name", module_bytes(section(.CUSTOM, 0x03, 0xed, 0xa0, 0x80)), .BAD_NAME},
		{"name past the section", module_bytes(section(.CUSTOM, 0x05, 'a')), .TRUNCATED},
		{"import kind 5", module_bytes(section(.IMPORT, 0x01, 0x01, 'a', 0x01, 'b', 0x05, 0x00)), .BAD_KIND},
		{"import global mutability 2", module_bytes(section(.IMPORT, 0x01, 0x01, 'a', 0x01, 'b', 0x03, 0x7f, 0x02)), .BAD_MUTABILITY},
		{"global mutability 4", module_bytes(section(.GLOBAL, 0x01, 0x7f, 0x04, 0x41, 0x00, 0x0b)), .BAD_MUTABILITY},
		{"global without end", module_bytes(section(.GLOBAL, 0x01, 0x7f, 0x00, 0x41, 0x00)), .TRUNCATED},
		{"global with a bad opcode", module_bytes(section(.GLOBAL, 0x01, 0x7f, 0x00, 0xf3, 0x0b)), .BAD_OPCODE},
		{"global i32.const too long", module_bytes(section(.GLOBAL, 0x01, 0x7f, 0x00, 0x41, 0x80, 0x80, 0x80, 0x80, 0x80, 0x00, 0x0b)), .BAD_OPCODE},
		{"two globals counted, one present", module_bytes(section(.GLOBAL, 0x02, 0x7f, 0x00, 0x41, 0x00, 0x0b)), .TRUNCATED},
		{"one global counted, two present", module_bytes(section(.GLOBAL, 0x01, 0x7f, 0x00, 0x41, 0x00, 0x0b, 0x7f, 0x00, 0x41, 0x00, 0x0b)), .SECTION_SIZE_MISMATCH},
		{"element forms 0 to 7", module_bytes(section(.ELEMENT,
			0x08,
			0x00, 0x41, 0x00, 0x0b, 0x01, 0x00,
			0x01, 0x00, 0x01, 0x00,
			0x02, 0x00, 0x41, 0x00, 0x0b, 0x00, 0x01, 0x00,
			0x03, 0x00, 0x01, 0x00,
			0x04, 0x41, 0x00, 0x0b, 0x01, 0xd2, 0x00, 0x0b,
			0x05, 0x70, 0x01, 0xd0, 0x70, 0x0b,
			0x06, 0x00, 0x41, 0x00, 0x0b, 0x70, 0x01, 0xd2, 0x00, 0x0b,
			0x07, 0x70, 0x01, 0xd2, 0x00, 0x0b,
		)), nil},
		{"element flags 8", module_bytes(section(.ELEMENT, 0x01, 0x08, 0x00)), .BAD_SEGMENT},
		{"element kind 1", module_bytes(section(.ELEMENT, 0x01, 0x01, 0x01, 0x00)), .BAD_SEGMENT},
		{"element of i32", module_bytes(section(.ELEMENT, 0x01, 0x05, 0x7f, 0x01, 0xd2, 0x00, 0x0b)), .BAD_VALTYPE},
		{"data forms 0 to 2", module_bytes(section(.DATA_COUNT, 0x03), section(.DATA, 0x03, 0x00, 0x41, 0x00, 0x0b, 0x01, 'x', 0x01, 0x01, 'y', 0x02, 0x01, 0x41, 0x00, 0x0b, 0x01, 'z')), nil},
		{"data kind 3", module_bytes(section(.DATA, 0x01, 0x03, 0x00)), .BAD_SEGMENT},
		{"data bytes past the section", module_bytes(section(.DATA, 0x01, 0x01, 0x07, 'a', 'b')), .TRUNCATED},
		{"data count 3, two segments", module_bytes(section(.DATA_COUNT, 0x03), section(.DATA, 0x02, 0x01, 0x00, 0x01, 0x00)), .DATA_COUNT_MISMATCH},
		{"data count without data", module_bytes(section(.DATA_COUNT, 0x01)), .DATA_COUNT_MISMATCH},
		{"memory.init without data count", module_bytes(empty_type, one_func, section(.CODE, 0x01, 0x0c, 0x00, 0x41, 0x00, 0x41, 0x00, 0x41, 0x00, 0xfc, 0x08, 0x00, 0x00, 0x0b), section(.DATA, 0x01, 0x01, 0x00)), .DATA_COUNT_REQUIRED},
		{"data.drop without data count", module_bytes(empty_type, one_func, section(.CODE, 0x01, 0x05, 0x00, 0xfc, 0x09, 0x00, 0x0b), section(.DATA, 0x01, 0x01, 0x00)), .DATA_COUNT_REQUIRED},
		{"data.drop with data count", module_bytes(empty_type, one_func, section(.DATA_COUNT, 0x01), section(.CODE, 0x01, 0x05, 0x00, 0xfc, 0x09, 0x00, 0x0b), section(.DATA, 0x01, 0x01, 0x00)), nil},
		{"import memory64 shared", module_bytes(section(.IMPORT, 0x01, 0x01, 'a', 0x01, 'b', 0x02, 0x07, 0x01, 0x02)), nil},
		{"export kind 4", module_bytes(section(.EXPORT, 0x01, 0x01, 'a', 0x04, 0x00)), .BAD_KIND},
		{"vector count past the section", module_bytes(section(.TYPE, 0xff, 0xff, 0xff, 0xff, 0x0f)), .TRUNCATED},
		{"garbage name section", module_bytes(section(.CUSTOM, 0x04, 'n', 'a', 'm', 'e', 0x01, 0xff, 0xff, 0xff, 0xff, 0x0f)), nil},
		{"garbage target_features", module_bytes(section(.CUSTOM, 0x0f, 't', 'a', 'r', 'g', 'e', 't', '_', 'f', 'e', 'a', 't', 'u', 'r', 'e', 's', 0x05, 0x2b)), nil},
		{"reloc for a missing section", module_bytes(section(.CUSTOM, 0x0a, 'r', 'e', 'l', 'o', 'c', '.', 'C', 'O', 'D', 'E', 0x05, 0x00)), .BAD_SECTION},
	}
	for c in cases {
		_, err := parse_module(c.data)
		got, _ := err.(wasm.Parse_Error)
		testing.expectf(t, (err == nil) == (c.err == nil) && got == c.err, "%s: %v, want %v", c.name, err, c.err)
	}
}

@(test)
test_function_bodies_must_be_well_nested :: proc(t: ^testing.T) {
	Case :: struct {
		name: string,
		body: []u8,
		ok:   bool,
	}
	cases := [?]Case{
		{"empty", {0x00, 0x0b}, true},
		{"no end", {0x00, 0x41, 0x01, 0x1a}, false},
		{"unclosed block", {0x00, 0x02, 0x40, 0x0b}, false},
		{"code after the end", {0x00, 0x0b, 0x01}, false},
		{"second end", {0x00, 0x0b, 0x0b}, false},
		{"else outside if", {0x00, 0x05, 0x0b}, false},
		{"else in a block", {0x00, 0x02, 0x40, 0x05, 0x0b, 0x0b}, false},
		{"two elses", {0x00, 0x04, 0x40, 0x05, 0x05, 0x0b, 0x0b}, false},
		{"if else end", {0x00, 0x41, 0x00, 0x04, 0x40, 0x05, 0x0b, 0x0b}, true},
		{"nested", {0x00, 0x02, 0x40, 0x03, 0x40, 0x41, 0x00, 0x04, 0x40, 0x0b, 0x0b, 0x0b, 0x0b}, true},
	}
	for c in cases {
		entry := make([dynamic]u8, context.temp_allocator)
		append(&entry, 0x01)
		wasm.append_uleb(&entry, u64(len(c.body)))
		append(&entry, ..c.body)
		data := module_bytes(section(.TYPE, 0x01, 0x60, 0x00, 0x00), section(.FUNCTION, 0x01, 0x00), section(.CODE, ..entry[:]))
		m: wasm.Module
		errors := make([dynamic]wasm.Error, context.temp_allocator)
		_, ok := wasm.decode(data, &m, &errors, context.temp_allocator)
		testing.expectf(t, ok == c.ok, "%s: decode ok = %v, want %v (%v)", c.name, ok, c.ok, errors[:])
	}
}

@(test)
test_relocations_attach_to_code :: proc(t: ^testing.T) {
	data := module_bytes(
		section(.TYPE, 0x01, 0x60, 0x00, 0x00),
		section(.FUNCTION, 0x01, 0x00),
		section(.CODE, 0x01, 0x08, 0x00, 0x10, 0x80, 0x80, 0x80, 0x80, 0x00, 0x0b),
		section(.CUSTOM,
			0x0a, 'r', 'e', 'l', 'o', 'c', '.', 'C', 'O', 'D', 'E',
			0x02,
			0x03,
			0x03, 0x64, 0x00, 0x7b,
			0x0b, 0x32, 0x00, 0x03,
			0x00, 0x04, 0x07,
		),
	)
	m, err := parse_module(data)
	if !testing.expectf(t, err == nil, "parse failed: %v", err) {
		return
	}
	if !testing.expect_value(t, len(m.relocations), 1) {
		return
	}
	group := m.relocations[0]
	testing.expect_value(t, group.target_section, wasm.Section_Id.CODE)
	if testing.expect_value(t, len(group.relocs), 2) {
		testing.expect_value(t, group.relocs[0].type, wasm.Relocation_Type.MEMORY_ADDR_LEB)
		testing.expect_value(t, group.relocs[0].addend, -5)
		testing.expect_value(t, group.relocs[1].type, wasm.Relocation_Type.FUNCTION_INDEX_LEB)
		testing.expect_value(t, group.relocs[1].offset, 4)
		testing.expect_value(t, group.relocs[1].label_id, 7)
	}
	ops := m.functions[0].blocks[0].ops
	if testing.expect(t, len(ops) == 2 && wasm.Opcode(ops[0].opcode) == .CALL && len(ops[0].operands) == 1) {
		callee := ops[0].operands[0]
		testing.expect(t, wasm.operand_symbolic(callee) && wasm.operand_index(callee) == 7)
	}
}

@(test)
test_mutated_modules_do_not_crash :: proc(t: ^testing.T) {
	data := sample_module()
	buf := make([]u8, len(data), context.temp_allocator)
	for n in 0..=len(data) {
		decode_and_print(buf[:copy(buf, data[:n])])
	}
	mutations := [?]u8{0x00, 0x01, 0x40, 0x7f, 0x80, 0xff}
	for i in 0..<len(data) {
		for v in mutations {
			copy(buf, data)
			buf[i] = v
			decode_and_print(buf)
			buf[i] = data[i] ~ v
			decode_and_print(buf)
		}
	}
}

@(private="file")
sample_module :: proc() -> []u8 {
	return module_bytes(
		section(.TYPE, 0x01, 0x60, 0x01, 0x7f, 0x01, 0x7f),
		section(.FUNCTION, 0x01, 0x00),
		section(.TABLE, 0x01, 0x70, 0x00, 0x01),
		section(.MEMORY, 0x02, 0x05, 0x01, 0x02, 0x03, 0x01, 0x01),
		section(.GLOBAL, 0x01, 0x7f, 0x00, 0x41, 0x2a, 0x0b),
		section(.EXPORT, 0x01, 0x03, 'r', 'u', 'n', 0x00, 0x00),
		section(.ELEMENT, 0x01, 0x00, 0x41, 0x00, 0x0b, 0x01, 0x00),
		section(.CODE, 0x01, 0x09, 0x00, 0x20, 0x00, 0x41, 0x00, 0x11, 0x00, 0x00, 0x0b),
		section(.DATA, 0x01, 0x00, 0x42, 0x08, 0x0b, 0x02, 'h', 'i'),
	)
}

@(private="file")
decode_and_print :: proc(data: []u8) {
	m: wasm.Module
	errors := make([dynamic]wasm.Error, context.temp_allocator)
	_, ok := wasm.decode(data, &m, &errors, context.temp_allocator)
	_ = wasm.tprint_wat(m)
	if ok {
		out := make([]u8, 4096, context.temp_allocator)
		relocs := make([dynamic]wasm.Relocation, context.temp_allocator)
		_, _ = wasm.encode(m, out, &relocs, &errors)
	}
}
