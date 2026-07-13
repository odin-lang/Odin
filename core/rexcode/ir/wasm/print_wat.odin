package rexcode_wasm

import "base:runtime"
import "core:fmt"
import "core:io"
import "core:os"
import "core:strings"

// =============================================================================
// WebAssembly TEXT (WAT) PRINTER
// =============================================================================
//
// `print.odin` emits a compact, custom *disassembly* of a parsed `Module`.
// This file emits the standard WebAssembly text format (`.wat`): the nested
// s-expression module that `wat2wasm` consumes and that `wasm2wat` produces.
//
//   (module
//     (type (;0;) (func (param i32 i32) (result i32)))
//     (func $add (type 0) (param i32 i32) (result i32)
//       (i32.add
//         (local.get 0)
//         (local.get 1)))
//     (export "add" (func 0)))
//
// Folding
// -------
// A WASM code section is a *linear* stack-machine stream; WAT bodies are
// *folded* operator trees. Reconstructing the trees needs each instruction's
// stack arity (operands consumed / results produced), which the linear stream
// does not carry, so it is recovered here:
//   * fixed for the numeric / memory / variable / parametric / reference /
//     bulk-memory operators (`instruction_arity`),
//   * computed from the module's own type table for `call` (callee signature),
//     `call_indirect` (the referenced type), and `block`/`loop`/`if` results.
//
// The folder is the algorithm `wat2wasm`/`wasm2wat` use: keep a stack of
// partially built operand trees; an operator with N operands claims the top N
// trees as children; an operator that yields no value (a "statement", e.g. a
// store / drop / void call) flushes the stack so nothing is reordered. Where
// folding would be unsound (not enough operands contiguously on top, e.g.
// across a side-effecting statement) it degrades to flat folded exprs such as
// `(i32.add)` whose operands are the preceding sibling exprs -- still valid,
// still correct, just less nested. SIMD / atomic operators are conservatively
// treated as statements (rendered flat) rather than risk an incorrect tree.
//
// Index operands print numerically (`call 3`, `local.get 0`): the decoder
// marks `call` targets `symbolic` (which would print `$3`); that flag is
// cleared per-instruction so references always resolve. Names from the "name"
// custom section are attached to *definitions* as `$name` (or kept as an index
// comment when the text would not be a legal WAT identifier).
//
// Coverage: TYPE, IMPORT (all four kinds), FUNCTION/CODE, TABLE, MEMORY,
// GLOBAL, EXPORT, START, ELEMENT (active table-0 funcref form), DATA.

WAT_Options :: struct {
	indent_unit: string, // one indentation step; default "  "
}

DEFAULT_WAT_OPTIONS :: WAT_Options{
	indent_unit = "  ",
}

print_wat :: proc(m: Module, file: ^os.File, opts := DEFAULT_WAT_OPTIONS) {
	sb := strings.builder_make(context.allocator)
	defer strings.builder_destroy(&sb)
	sbprint_wat(&sb, m, opts)
	os.write_string(file, strings.to_string(sb))
}

fprint_wat :: proc(w: io.Writer, m: Module, opts := DEFAULT_WAT_OPTIONS) {
	sb := strings.builder_make(context.temp_allocator)
	sbprint_wat(&sb, m, opts)
	io.write_string(w, strings.to_string(sb))
}

// Allocates the result with `allocator` (caller owns it).
aprint_wat :: proc(m: Module, opts := DEFAULT_WAT_OPTIONS, allocator := context.allocator) -> string {
	sb := strings.builder_make(allocator)
	sbprint_wat(&sb, m, opts)
	return strings.to_string(sb)
}

// Result lives in the temp allocator.
tprint_wat :: proc(m: Module, opts := DEFAULT_WAT_OPTIONS) -> string {
	sb := strings.builder_make(context.temp_allocator)
	sbprint_wat(&sb, m, opts)
	return strings.to_string(sb)
}

sbprint_wat :: proc(sb: ^strings.Builder, m: Module, opts := DEFAULT_WAT_OPTIONS) {
	unit := opts.indent_unit
	if unit == "" {
		unit = "  "
	}

	strings.write_string(sb, "(module")
	defer strings.write_string(sb, ")\n")

	if name, ok := module_name(m); ok {
		if wat_ident_ok(name) {
			strings.write_string(sb, " $")
			strings.write_string(sb, name)
		} else {
			fmt.sbprintf(sb, " (;%q;)", name)
		}
	}
	strings.write_byte(sb, '\n')

	for t, i in m.func_types {
		fmt.sbprintf(sb, "%s(type (;%d;) ", unit, i)
		wat_write_functype(sb, t)
		strings.write_string(sb, ")\n")
	}

	wat_write_imports(sb, m, unit)

	func_relocs := relocations_for_section(m.relocations, .FUNCTION)

	for f in m.functions {
		if len(f.blocks) == 0 {
			// assume this is the equivalent of an imported block
			continue
		}
		wat_write_function(sb, m, func_relocs, f, unit)
	}

	wat_write_tables  (sb, m, unit)
	wat_write_memories(sb, m, unit)
	wat_write_globals (sb, m, unit)

	for e in m.exports {
		fmt.sbprintf(sb, "%s(export %q (%s %d))\n", unit, e.name, external_kind_name(e.kind), e.index)
	}

	if m.start >= 0 {
		fmt.sbprintf(sb, "%s(start %d)\n", unit, m.start)
	}

	wat_write_elements(sb, m, unit)
	wat_write_data    (sb, m, unit)
}

wat_write_functype :: proc(sb: ^strings.Builder, t: Func_Type) {
	strings.write_string(sb, "(func")
	defer strings.write_byte(sb, ')')
	if len(t.params) > 0 {
		strings.write_string(sb, " (param")
		defer strings.write_byte(sb, ')')
		for p in t.params {
			strings.write_byte(sb, ' ')
			strings.write_string(sb, valtype_name(p))
		}
	}
	if len(t.results) > 0 {
		strings.write_string(sb, " (result")
		defer strings.write_byte(sb, ')')
		for rt in t.results {
			strings.write_byte(sb, ' ')
			strings.write_string(sb, valtype_name(rt))
		}
	}
}

wat_write_imports :: proc(sb: ^strings.Builder, m: Module, unit: string) -> Parse_Error {
	sec: Section
	{
		found := false
		for s in m.sections {
			if s.id == .IMPORT {
				sec = s
				found = true
				break
			}
		}
		if !found {
			return nil
		}
	}

	r := reader(m.data, sec.offset)
	count := rd_u32(&r) or_return

	fi: u32
	ti: u32
	mi: u32
	gi: u32

	for _ in 0..<count {
		mod := rd_name(&r) or_return
		fld := rd_name(&r) or_return
		kb  := rd_byte(&r) or_return

		fmt.sbprintf(sb, "%s(import %q %q (", unit, mod, fld)
		defer strings.write_string(sb, "))\n")

		switch External_Kind(kb) {
		case .FUNC:
			tidx, _ := rd_u32(&r)
			strings.write_string(sb, "func")
			name := ""
			if int(fi) < len(m.functions) {
				name = m.functions[fi].name
			}
			wat_write_id_or_comment(sb, name, Id(fi))
			fmt.sbprintf(sb, " (type %d)", tidx)
			fi += 1
		case .TABLE:
			rt, _ := rd_byte(&r)
			min, max, _ := rd_limits(&r)
			fmt.sbprintf(sb, "table (;%d;) %d", ti, min)
			if mx, ok := max.?; ok {
				fmt.sbprintf(sb, " %d", mx)
			}
			fmt.sbprintf(sb, " %s", valtype_name(Value_Type(rt)))
			ti += 1
		case .MEMORY:
			min, max, _ := rd_limits(&r)
			fmt.sbprintf(sb, "memory (;%d;) %d", mi, min)
			if mx, ok := max.?; ok {
				fmt.sbprintf(sb, " %d", mx)
			}
			mi += 1
		case .GLOBAL:
			vt, _  := rd_byte(&r)
			mut, _ := rd_byte(&r)
			fmt.sbprintf(sb, "global (;%d;) ", gi)
			if mut == 1 {
				fmt.sbprintf(sb, "(mut %s)", valtype_name(Value_Type(vt)))
			} else {
				strings.write_string(sb, valtype_name(Value_Type(vt)))
			}
			gi += 1
		}
	}

	return nil
}

wat_write_function :: proc(sb: ^strings.Builder, m: Module, func_relocs: []Relocation, f: Function, unit: string) {
	strings.write_string(sb, unit)
	strings.write_string(sb, "(func")
	defer strings.write_string(sb, ")\n")
	wat_write_id_or_comment(sb, f.name, f.id)
	fmt.sbprintf(sb, " (type %d)", f.signature)

	type := &m.func_types[f.signature]

	if len(type.params) > 0 {
		strings.write_string(sb, " (param")
		defer strings.write_byte(sb, ')')
		for p in type.params {
			strings.write_byte(sb, ' ')
			strings.write_string(sb, valtype_name(p))
		}
	}
	if len(type.results) > 0 {
		strings.write_string(sb, " (result")
		defer strings.write_byte(sb, ')')
		for rt in type.results {
			strings.write_byte(sb, ' ')
			strings.write_string(sb, valtype_name(rt))
		}
	}
	locals := m.function_locals[f.id]
	if len(locals) > 0 {
		strings.write_string(sb, "\n")
		strings.write_string(sb, "    (local")
		defer strings.write_byte(sb, ')')
		for g in locals {
			strings.write_byte(sb, ' ')
			strings.write_string(sb, valtype_name(g))
		}
	}
	strings.write_byte(sb, '\n')

	opts := DEFAULT_PRINT_OPTIONS
	opts.indent = "    "
	assert(len(f.blocks) <= 1)
	for blk in f.blocks {
		for &op, i in blk.ops {
			if i+1 == len(blk.ops) && Opcode(op.opcode) == .END {
				// TODO(bill): Should this be rendered or NOT?
				// break
			}
			write_operation(sb, &op, &opts)
			strings.write_string(sb, opts.separator)
		}
	}

	strings.write_string(sb, unit)
}

wat_write_tables :: proc(sb: ^strings.Builder, m: Module, unit: string) {
	idx := count_import_kind(m, .TABLE)
	for sec in m.sections {
		if sec.id != .TABLE {
			continue
		}
		r := reader(m.data, sec.offset)
		count := rd_u32(&r) or_break
		for _ in 0..<count {
			rt := rd_byte(&r) or_break
			min, max := rd_limits(&r) or_break
			fmt.sbprintf(sb, "%s(table (;%d;) %d", unit, idx, min)
			defer fmt.sbprintf(sb, " %s)\n", valtype_name(Value_Type(rt)))
			if mx, ok := max.?; ok {
				fmt.sbprintf(sb, " %d", mx)
			}
			idx += 1
		}
	}
}

wat_write_memories :: proc(sb: ^strings.Builder, m: Module, unit: string) {
	idx := count_import_kind(m, .MEMORY)
	for sec in m.sections {
		if sec.id != .MEMORY {
			continue
		}
		r := reader(m.data, sec.offset)
		count := rd_u32(&r) or_break
		for _ in 0..<count {
			min, max := rd_limits(&r) or_break
			fmt.sbprintf(sb, "%s(memory (;%d;) %d", unit, idx, min)
			defer strings.write_string(sb, ")\n")
			if mx, ok := max.?; ok {
				fmt.sbprintf(sb, " %d", mx)
			}
			idx += 1
		}
	}
}

wat_write_globals :: proc(sb: ^strings.Builder, m: Module, unit: string) {
	idx := count_import_kind(m, .GLOBAL)
	for sec in m.sections {
		if sec.id != .GLOBAL {
			continue
		}
		relocs := relocations_for_section(m.relocations, sec.id)

		r := reader(m.data, sec.offset)
		count := rd_u32(&r) or_break
		for _ in 0..<count {
			vt  := rd_byte(&r) or_break
			mut := rd_byte(&r) or_break

			fmt.sbprintf(sb, "%s(global (;%d;) ", unit, idx)
			defer strings.write_string(sb, ")\n")

			if mut == 1 {
				fmt.sbprintf(sb, "(mut %s) ", valtype_name(Value_Type(vt)))
			} else {
				fmt.sbprintf(sb, "%s ", valtype_name(Value_Type(vt)))
			}
			wat_write_const_expr(sb, m, relocs, m.data, &r.off, unit, context.temp_allocator)
			idx += 1
		}
	}
}

wat_write_elements :: proc(sb: ^strings.Builder, m: Module, unit: string) -> Parse_Error {
	elem_idx := 0
	for sec in m.sections {
		if sec.id != .ELEMENT {
			continue
		}

		relocs := relocations_for_section(m.relocations, sec.id)

		r := reader(m.data, sec.offset)
		count := rd_u32(&r) or_break
		for _ in 0..<count {
			flags := rd_u32(&r) or_break
			if flags != 0 {
				fmt.sbprintf(sb, "%s(; elem segment %d: unsupported flags=%d ;)\n", unit, elem_idx, flags)
				return nil
			}

			fmt.sbprintf(sb, "%s(elem (;%d;) ", unit, elem_idx)
			defer strings.write_string(sb, ")\n")

			wat_write_const_expr(sb, m, relocs, m.data, &r.off, unit, context.temp_allocator)
			strings.write_string(sb, " func")
			n := rd_u32(&r) or_break
			for _ in 0..<n {
				fidx := rd_u32(&r) or_return
				fmt.sbprintf(sb, " %d", fidx)
			}
			elem_idx += 1
		}
	}
	return nil
}

wat_write_data :: proc(sb: ^strings.Builder, m: Module, unit: string) -> Parse_Error {
	data_idx := 0
	for sec in m.sections {
		if sec.id != .DATA {
			continue
		}
		r := reader(m.data, sec.offset)
		count := rd_u32(&r) or_break
		for _ in 0..<count {
			kind := rd_u32(&r) or_return

			fmt.sbprintf(sb, "%s(data (;%d;)", unit, data_idx)
			defer strings.write_string(sb, ")\n")

			memidx: u32 = 0
			switch kind {
			case 2:
				// memidx + expr + bytes
				memidx, _ = rd_u32(&r)
				fallthrough
			case 0:
				// expr + bytes
				if memidx != 0 {
					fmt.sbprintf(sb, " (memory %d)", memidx)
				}
				strings.write_byte(sb, ' ')
				relocs := relocations_for_section(m.relocations, sec.id)
				wat_write_const_expr(sb, m, relocs, m.data, &r.off, unit, context.temp_allocator)
			case 1:
				// bytes
			case:
				fmt.sbprintf(sb, "%s(; data segment %d: unsupported kind=%d ;)\n", unit, data_idx, kind)
				return nil
			}

			size := rd_u32(&r) or_return
			strings.write_byte(sb, ' ')
			wat_write_quoted_string(sb, m.data[r.off:][:size])
			r.off += size

			data_idx += 1
		}
	}
	return nil
}

// Decode and fold a constant expression at `off^` (advancing past its `end`).
wat_write_const_expr :: proc(sb: ^strings.Builder, m: Module, relocs: []Relocation, data: []u8, off: ^u32, unit: string, allocator: runtime.Allocator) {
	context.allocator = context.temp_allocator

	ops: [dynamic]Operation
	ops.allocator = allocator
	defer delete(ops)

	for off^ < u32(len(data)) {
		op, next := decode_one(data, relocs, off^, allocator) or_break
		off^ = next
		if Opcode(op.opcode) == .END {
			break
		}
		append(&ops, op)
	}
	sbprint(sb, ops[:])

	// i := 0
	// stmts, _ := wat_fold_region(exprs[:], m, &i)
	// for &s, k in stmts {
	// 	if k > 0 { strings.write_byte(sb, ' ') }
	// 	wat_render(sb, &s, 0, unit)
	// }
}

wat_write_id_or_comment :: proc(sb: ^strings.Builder, name: string, index: Id) {
	if name != "" && wat_ident_ok(name) {
		strings.write_string(sb, " $")
		strings.write_string(sb, name)
	} else {
		fmt.sbprintf(sb, " (;%d;)", index)
	}
}

@(private)
indent_str :: proc(sb: ^strings.Builder, unit: string, level: int) {
	for _ in 0..<level {
		strings.write_string(sb, unit)
	}
}

@(require_results)
wat_ident_ok :: proc(s: string) -> bool {
	if len(s) == 0 {
		return false
	}
	#no_bounds_check for i in 0..<len(s) {
		c := s[i]
		switch c {
		case '0'..='9', 'A'..='Z', 'a'..='z':
			// okay
		case '!', '#', '$', '%', '&', '\'', '*', '+', '-', '.', '/',
		     ':', '<', '=', '>', '?', '@', '\\', '^', '_', '`', '|',
		     '~':
			// okay
		case:
			return false
		}
	}
	return true
}

wat_write_quoted_string :: proc(sb: ^strings.Builder, bytes: []u8) {
	@(rodata, static)
	HEX := "0123456789abcdef"
	strings.write_byte(sb, '"')
	for b in bytes {
		switch b {
		case '"':         strings.write_string(sb, "\\\"")
		case '\\':        strings.write_string(sb, "\\\\")
		case 0x20..<0x7F: strings.write_byte(sb, b)
		case:
			strings.write_byte(sb, '\\')
			strings.write_byte(sb, HEX[b >> 4])
			strings.write_byte(sb, HEX[b & 0xF])
		}
	}
	strings.write_byte(sb, '"')
}


@(require_results)
valtype_name :: #force_inline proc "contextless" (t: Value_Type) -> string {
	switch t {
	case .I32:       return "i32"
	case .I64:       return "i64"
	case .F32:       return "f32"
	case .F64:       return "f64"
	case .V128:      return "v128"
	case .FUNCREF:   return "funcref"
	case .EXTERNREF: return "externref"
	}
	return "?"
}

@(require_results)
external_kind_name :: #force_inline proc "contextless" (k: External_Kind) -> string {
	switch k {
	case .FUNC:   return "func"
	case .TABLE:  return "table"
	case .MEMORY: return "memory"
	case .GLOBAL: return "global"
	}
	return "?"
}