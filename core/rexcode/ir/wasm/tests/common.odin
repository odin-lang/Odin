package rexcode_wasm_tests

import "core:strings"
import wasm ".."

@(private)
decode_one_op :: proc(bytes: []u8) -> (op: wasm.Operation, ok: bool) {
	next: u32
	op, next, ok = wasm.decode_one(bytes, nil, 0, context.temp_allocator)
	if ok && next != u32(len(bytes)) {
		ok = false
	}
	return
}

@(private)
encode_one_op :: proc(op: wasm.Operation) -> (bytes: []u8, code: wasm.Error_Code) {
	op := op
	buf := make([]u8, 1024, context.temp_allocator)
	relocs := make([dynamic]wasm.Relocation, context.temp_allocator)
	errors := make([dynamic]wasm.Error, context.temp_allocator)
	n, ok := wasm.encode_operation(&op, 0, 0, buf, &relocs, &errors)
	if !ok {
		code = errors[0].code if len(errors) > 0 else .MALFORMED_MODULE
		return
	}
	return buf[:n], .NONE
}

@(private)
op_text :: proc(op: wasm.Operation) -> string {
	op := op
	opts := wasm.DEFAULT_PRINT_OPTIONS
	opts.indent = ""
	sb := strings.builder_make(context.temp_allocator)
	wasm.write_operation(&sb, &op, &opts, nil)
	return strings.to_string(sb)
}

@(private)
section :: proc(id: wasm.Section_Id, contents: ..u8) -> []u8 {
	out := make([dynamic]u8, context.temp_allocator)
	append(&out, u8(id))
	wasm.append_uleb(&out, u64(len(contents)))
	append(&out, ..contents)
	return out[:]
}

@(private)
module_bytes :: proc(sections: ..[]u8) -> []u8 {
	out := make([dynamic]u8, context.temp_allocator)
	append(&out, 0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00)
	for s in sections {
		append(&out, ..s)
	}
	return out[:]
}

@(private)
parse_module :: proc(data: []u8) -> (m: wasm.Module, err: wasm.Reader_Error) {
	errors := make([dynamic]wasm.Error, context.temp_allocator)
	m.data = data
	err = wasm.parse_container(data, &m, &errors, context.temp_allocator)
	return
}
