// rexcode  ·  Brendan Punsky (dotbmp@github), original author
//             Ginger Bill (gingerBill@github)

package rexcode_wasm

import "base:runtime"
import "core:slice"

// =============================================================================
// SECTION: Container encode  (ir Module -> a whole .wasm binary module)
// =============================================================================
//
// The mirror of parse.odin. `encode_ops` (encoder.odin) serializes one WASM
// `expr` -- a single function's instruction stream. This file is the outer
// layer parse.odin reads: it wraps those bodies in the CODE section framing and
// emits the surrounding sections so `encode` produces a complete `.wasm` file
// (the 8-byte header plus the length-prefixed sections), not a bare run of
// concatenated bodies.
//
// Two shapes of module flow through here, dispatched on whether the module
// carries the binary framing decode preserved (`sections` + `data`):
//
//   * A decoded module (round-trip / edit-a-body): every section is re-emitted
//     verbatim from `data` in its original order, EXCEPT CODE, which is
//     regenerated from the ir Operations (so edits to a function body show up).
//     A decode -> encode with no edits reproduces the input byte-for-byte; the
//     sections parse.odin does not model structurally (table / memory / global
//     / element / data, non-func imports, custom sections) are never lost.
//
//   * A from-scratch module (built via make_module + the builders): there is no
//     `data` to copy, so the sections the ir core *does* model are synthesized
//     in the canonical WASM order -- TYPE, IMPORT (func), FUNCTION, EXPORT,
//     START, CODE. Sections with no structural slot (table/memory/global/...)
//     cannot be synthesized and are simply absent.
//
// Emitted relocations (for symbolic index refs inside bodies, e.g. op_label)
// are offset relative to the produced `code` buffer, and carried out through
// `relocs` for a linker; body errors surface through `errors` as usual.

// encode: serialize the module `m` into `code`, producing a complete `.wasm`
// binary. Returns the number of bytes written and whether it fully succeeded.
// Size `code` with `encode_size(m)` (or any larger buffer).
encode :: proc(m: Module, code: []u8, relocs: ^[dynamic]Relocation, errors: ^[dynamic]Error) -> (byte_count: u32, ok: bool) {
	errors_start := u32(len(errors))

	out := build_module(m, relocs, errors)
	defer delete(out)

	if len(out) > len(code) {
		append(errors, Error{location = 0, code = .BUFFER_OVERFLOW})
		return 0, false
	}
	copy(code, out[:])
	byte_count = u32(len(out))
	ok = u32(len(errors)) == errors_start
	return
}

// encode_size: the exact byte length `encode(m, ...)` will produce (a dry run,
// so callers can size the output buffer precisely). Uses the temp allocator.
@(require_results)
encode_size :: proc(m: Module) -> u32 {
	throw_r: [dynamic]Relocation; throw_r.allocator = runtime.nil_allocator()
	throw_e: [dynamic]Error;      throw_e.allocator = runtime.nil_allocator()
	out := build_module(m, &throw_r, &throw_e)
	defer delete(out)
	return u32(len(out))
}

// =============================================================================
// Module builder  (into a temp-allocated byte buffer)
// =============================================================================

@(private, require_results)
build_module :: proc(m: Module, relocs: ^[dynamic]Relocation, errors: ^[dynamic]Error) -> (out: [dynamic]u8) {
	append_u32le :: #force_inline proc(b: ^[dynamic]u8, v: u32) {
		append(b, u8(v), u8(v >> 8), u8(v >> 16), u8(v >> 24))
	}

	out.allocator = context.temp_allocator

	// header: `\0asm` magic + version.
	append_u32le(&out, WASM_MAGIC)
	append_u32le(&out, m.version if m.version != 0 else WASM_VERSION)

	if len(m.sections) > 0 && m.data != nil {
		emit_passthrough(m, &out, relocs, errors)
	} else {
		emit_synth(m, &out, relocs, errors)
	}
	return
}

// Decoded module: re-emit each section verbatim in file order, regenerating
// only CODE from the ir Operations.
@(private)
emit_passthrough :: proc(m: Module, out: ^[dynamic]u8, relocs: ^[dynamic]Relocation, errors: ^[dynamic]Error) {
	for sec in m.sections {
		if sec.id == .CODE {
			emit_code_section(m, out, relocs, errors)
		} else {
			append(out, u8(sec.id))
			append_uleb(out, u64(sec.size))
			append(out, ..m.data[sec.offset:][:sec.size])
		}
	}
}

// From-scratch module: synthesize the modeled sections in canonical order.
@(private)
emit_synth :: proc(m: Module, out: ^[dynamic]u8, relocs: ^[dynamic]Relocation, errors: ^[dynamic]Error) {
	emit_section :: proc(out: ^[dynamic]u8, id: Section_Id, contents: []u8) {
		append(out, u8(id))
		append_uleb(out, u64(len(contents)))
		append(out, ..contents)
	}


	tmp := context.temp_allocator

	// TYPE
	if len(m.func_types) > 0 {
		c: [dynamic]u8; c.allocator = tmp
		append_uleb(&c, u64(len(m.func_types)))
		for ft in m.func_types {
			append(&c, 0x60) // functype form

			#assert(size_of(ft.params[0]) == 1)
			#assert(size_of(ft.results[0]) == 1)

			append_uleb(&c, u64(len(ft.params)))
			append(&c, ..slice.to_bytes(ft.params[:]))

			append_uleb(&c, u64(len(ft.results)))
			append(&c, ..slice.to_bytes(ft.results[:]))
		}
		emit_section(out, .TYPE, c[:])
	}

	// IMPORT (only the func kind is structurally modeled)
	if len(m.imports) > 0 {
		c: [dynamic]u8; c.allocator = tmp
		append_uleb(&c, u64(len(m.imports)))
		for imp in m.imports {
			append_uleb_name(&c, imp.module_name)
			append_uleb_name(&c, imp.field_name)
			append(&c, u8(imp.kind))
			#partial switch imp.kind {
			case .FUNC:
				append_uleb(&c, u64(imp.index))   // typeidx
			case:
				// table/memory/global descriptors are not modeled from scratch.
				append(errors, Error{location = 0, code = .UNSUPPORTED_FEATURE})
			}
		}
		emit_section(out, .IMPORT, c[:])
	}

	// FUNCTION (typeidx per *defined* function -- those with a body)
	if ndef := defined_function_count(m); ndef > 0 {
		c: [dynamic]u8; c.allocator = tmp
		append_uleb(&c, u64(ndef))
		for f in m.functions {
			if len(f.blocks) == 0 {
				continue // imported: no FUNCTION entry
			}
			append_uleb(&c, u64(u32(f.signature)))
		}
		emit_section(out, .FUNCTION, c[:])
	}

	// EXPORT
	if len(m.exports) > 0 {
		c: [dynamic]u8; c.allocator = tmp
		append_uleb(&c, u64(len(m.exports)))
		for e in m.exports {
			append_uleb_name(&c, e.name)
			append(&c, u8(e.kind))
			append_uleb(&c, u64(e.index))
		}
		emit_section(out, .EXPORT, c[:])
	}

	// START
	if m.start >= 0 {
		c: [dynamic]u8; c.allocator = tmp
		append_uleb(&c, u64(u32(m.start)))
		emit_section(out, .START, c[:])
	}

	// CODE
	emit_code_section(m, out, relocs, errors)

	// the remaining sections
	for sec in m.sections {
		switch sec.id {
		case .CUSTOM, .TABLE, .MEMORY, .GLOBAL, .ELEMENT, .DATA, .DATA_COUNT:
			emit_section(out, sec.id, m.data[sec.offset:][:sec.size])
		case .TYPE, .IMPORT, .FUNCTION, .EXPORT, .START, .CODE:
			// handled above
		}
	}

}

// =============================================================================
// CODE section  (shared by both modes -- always regenerated from the ir ops)
// =============================================================================

@(private)
emit_code_section :: proc(m: Module, out: ^[dynamic]u8, relocs: ^[dynamic]Relocation, errors: ^[dynamic]Error) {
	tmp := context.temp_allocator

	ndef := defined_function_count(m)
	if ndef == 0 {
		return
	}

	contents: [dynamic]u8; contents.allocator = tmp
	append_uleb(&contents, u64(ndef))

	// Body relocations, collected with offsets relative to the CODE contents;
	// rebased to buffer-relative once the section is placed.
	code_relocs: [dynamic]Relocation; code_relocs.allocator = tmp

	for f, fi in m.functions {
		if len(f.blocks) == 0 {
			continue  // imported function: no body
		}

		// A WASM function body is one `expr`. Concatenate all blocks' ops (the
		// decoder produces one block; a hand-built function may use several).
		all_ops := f.blocks[0].ops
		if len(f.blocks) > 1 {
			acc: [dynamic]Operation; acc.allocator = tmp
			for blk in f.blocks {
				append(&acc, ..blk.ops)
			}
			all_ops = acc[:]
		}

		// body = locals vector ++ expr bytes
		body: [dynamic]u8; body.allocator = tmp
		locals: []Value_Type
		if fi < len(m.function_locals) {
			locals = m.function_locals[fi]
		}
		emit_locals(&body, locals)
		expr_off_in_body := u32(len(body))

		scratch := make([]u8, encode_max_code_size(len(all_ops)) + 16, tmp)
		body_relocs: [dynamic]Relocation; body_relocs.allocator = tmp
		n, _ := encode_ops(all_ops, scratch, &body_relocs, errors)
		append(&body, ..scratch[:n])

		// entry = uleb(body_len) ++ body
		append_uleb(&contents, u64(len(body)))
		body_start_in_contents := u32(len(contents))
		append(&contents, ..body[:])

		expr_off_in_contents := body_start_in_contents + expr_off_in_body
		for rr in body_relocs {
			r2 := rr
			r2.offset += expr_off_in_contents
			append(&code_relocs, r2)
		}
	}

	// Emit the framed section; learn where its contents landed in the buffer.
	append(out, u8(Section_Id.CODE))
	append_uleb(out, u64(len(contents)))
	code_contents_file_off := u32(len(out))
	append(out, ..contents[:])

	for rr in code_relocs {
		r2 := rr
		r2.offset += code_contents_file_off
		append(relocs, r2)
	}
}

// A function's declared locals, re-compressed into `count x type` groups (runs
// of the same value type), exactly as the code section expects.
@(private)
emit_locals :: proc(body: ^[dynamic]u8, locals: []Value_Type) {
	group_count := u32(0)
	#no_bounds_check for i := 0; i < len(locals); /**/ {
		j := i+1
		for j < len(locals) && locals[j] == locals[i] {
			j += 1
		}
		group_count += 1
		i = j
	}
	append_uleb(body, u64(group_count))
	#no_bounds_check for i := 0; i < len(locals); /**/ {
		j := i+1
		for j < len(locals) && locals[j] == locals[i] {
			j += 1
		}
		append_uleb(body, u64(j - i))
		append(body, u8(locals[i]))
		i = j
	}
}

@(private, require_results)
defined_function_count :: proc "contextless" (m: Module) -> int {
	n := 0
	for f in m.functions {
		if len(f.blocks) > 0 {
			n += 1
		}
	}
	return n
}