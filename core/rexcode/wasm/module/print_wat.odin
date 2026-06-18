package rexcode_wasm_module

import "base:runtime"
import "core:strings"
import "core:os"
import "core:io"
import "core:fmt"
import wasm "core:rexcode/wasm"

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

	for t, i in m.types {
		fmt.sbprintf(sb, "%s(type (;%d;) ", unit, i)
		wat_write_functype(sb, t)
		strings.write_string(sb, ")\n")
	}

	wat_write_imports(sb, m, unit)

	func_relocs := relocations_from_section_id(m.reloc_groups, .FUNCTION)

	for f in m.functions {
		if f.imported {
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
			wat_write_id_or_comment(sb, name, fi)
			fmt.sbprintf(sb, " (type %d)", tidx)
			fi += 1
		case .TABLE:
			rt, _ := rd_byte(&r)
			min, max, _ := rd_limits(&r)
			fmt.sbprintf(sb, "table (;%d;) %d", ti, min)
			if mx, ok := max.?; ok {
				fmt.sbprintf(sb, " %d", mx)
			}
			fmt.sbprintf(sb, " %s", valtype_name(wasm.Value_Type(rt)))
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
				fmt.sbprintf(sb, "(mut %s)", valtype_name(wasm.Value_Type(vt)))
			} else {
				strings.write_string(sb, valtype_name(wasm.Value_Type(vt)))
			}
			gi += 1
		}
	}

	return nil
}

wat_write_function :: proc(sb: ^strings.Builder, m: Module, func_relocs: []wasm.Relocation, f: Function, unit: string) {
	strings.write_string(sb, unit)
	strings.write_string(sb, "(func")
	defer strings.write_string(sb, ")\n")
	wat_write_id_or_comment(sb, f.name, f.func_index)
	fmt.sbprintf(sb, " (type %d)", f.type_index)

	if len(f.type.params) > 0 {
		strings.write_string(sb, " (param")
		defer strings.write_byte(sb, ')')
		for p in f.type.params {
			strings.write_byte(sb, ' ')
			strings.write_string(sb, valtype_name(p))
		}
	}
	if len(f.type.results) > 0 {
		strings.write_string(sb, " (result")
		defer strings.write_byte(sb, ')')
		for rt in f.type.results {
			strings.write_byte(sb, ' ')
			strings.write_string(sb, valtype_name(rt))
		}
	}
	if len(f.locals) > 0 {
		strings.write_string(sb, " (local")
		defer strings.write_byte(sb, ')')
		for g in f.locals {
			for _ in 0..<g.count {
				strings.write_byte(sb, ' ')
				strings.write_string(sb, valtype_name(g.type))
			}
		}
	}
	strings.write_byte(sb, '\n')

	if f.body_size != 0 {
		body := m.data[f.body_offset:][:f.body_size]
		wat_write_body(sb, m, func_relocs, body, unit, level0=2)
	}

	strings.write_string(sb, unit)
}

wat_write_body :: proc(sb: ^strings.Builder, m: Module, func_relocs: []wasm.Relocation, body: []u8, unit: string, level0: int) {
	context.allocator = context.temp_allocator // scratch trees live in temp

	insts: [dynamic]wasm.Instruction
	info:  [dynamic]wasm.Instruction_Info
	errs:  [dynamic]wasm.Error
	wasm.decode(body, func_relocs, &insts, &info, &errs, context.temp_allocator)

	i := 0
	stmts, _ := wat_fold_region(insts[:], m, &i)
	for &s in stmts {
		indent_str(sb, unit, level0)
		wat_render(sb, &s, level0, unit)
		strings.write_byte(sb, '\n')
	}
}

WAT_Node_Kind :: enum u8 {
	PLAIN,
	BLOCK,
	LOOP,
	IF,
}

WAT_Node :: struct {
	kind:     WAT_Node_Kind,
	head:     string,            // "(head" payload: e.g. "i32.add", "block (result i32)"
	children: [dynamic]WAT_Node, // folded operands (PLAIN) / condition (IF)
	body:     [dynamic]WAT_Node, // block / loop / then body
	els:      [dynamic]WAT_Node, // if else body
	results:  int,
}

// Fold a straight-line region (a function body or a block body) into a list of top-level statement nodes, stopping at the matching `end` / `else`.
// `i` is advanced past the terminator. Returns the terminator that was consumed.
wat_fold_region :: proc(insts: []wasm.Instruction, m: Module, i: ^int) -> (out: [dynamic]WAT_Node, term: wasm.Mnemonic) {
	stack: [dynamic]WAT_Node
	defer delete(stack)

	for i^ < len(insts) {
		inst := insts[i^]
		#partial switch inst.mnemonic {
		case .END, .ELSE:
			i^ += 1
			append(&out, ..stack[:])
			return out, inst.mnemonic

		case .BLOCK, .LOOP:
			_, results := block_sig(m, inst.ops[0].immediate)
			head := render_head(inst)
			i^ += 1
			body, _ := wat_fold_region(insts, m, i)
			node := &WAT_Node{
				kind    = .BLOCK if inst.mnemonic == .BLOCK else .LOOP,
				head    = head,
				body    = body,
				results = results,
			}
			push_expr(&stack, &out, node, 0, results)

		case .IF:
			_, results := block_sig(m, inst.ops[0].immediate)
			head := render_head(inst)
			i^ += 1
			then_body, t := wat_fold_region(insts, m, i)
			else_body: [dynamic]WAT_Node
			if t == .ELSE {
				else_body, _ = wat_fold_region(insts, m, i)
			}
			node := &WAT_Node{
				kind    = .IF,
				head    = head,
				body    = then_body,
				els     = else_body,
				results = results,
			}
			push_expr(&stack, &out, node, 1, results) // 1 = the condition

		case:
			op, res := instruction_arity(m, inst)
			node := &WAT_Node{
				kind    = .PLAIN,
				head    = render_head(inst),
				results = res,
			}
			i^ += 1
			push_expr(&stack, &out, node, op, res)
		}
	}

	append(&out, ..stack[:])

	return out, .END
}

push_expr :: proc(stack, out: ^[dynamic]WAT_Node, node: ^WAT_Node, op, res: int) {
	if op <= len(stack) {
		start := len(stack) - op
		append(&node.children, ..stack[start:])
		resize(stack, start)
		append(stack, node^)
	} else {
		append(out, ..stack[:])
		clear(stack)
		append(stack, node^)
	}
	if res == 0 {
		append(out, ..stack[:])
		clear(stack)
	}
}

render_head :: proc(inst: wasm.Instruction) -> string {
	for j in 0..<inst.operand_count {
		op := inst.ops[j]
		if op.kind == .INDEX {
			op.flags.symbolic = false
		}
	}
	sb := strings.builder_make(context.temp_allocator)
	o := wasm.DEFAULT_PRINT_OPTIONS
	o.indent    = ""
	o.separator = ""
	wasm.sbprint(&sb, {inst}, nil, &o, nil)
	return strings.to_string(sb)
}

@(require_results)
wat_node_is_simple :: proc(n: ^WAT_Node) -> bool {
	(n.kind == .PLAIN) or_return
	for &c in n.children {
		wat_node_is_simple(&c) or_return
	}
	return true
}

wat_render :: proc(sb: ^strings.Builder, n: ^WAT_Node, level: int, unit: string) {
	strings.write_byte(sb, '(')
	defer strings.write_byte(sb, ')')
	strings.write_string(sb, n.head)

	switch n.kind {
	case .PLAIN:
		if wat_node_is_simple(n) {
			for &c in n.children {
				strings.write_byte(sb, ' ')
				wat_render(sb, &c, level, unit)
			}
		} else {
			for &c in n.children {
				strings.write_byte(sb, '\n')
				indent_str(sb, unit, level + 1)
				wat_render(sb, &c, level + 1, unit)
			}
		}

	case .BLOCK, .LOOP:
		for &s in n.body {
			strings.write_byte(sb, '\n')
			indent_str(sb, unit, level + 1)
			wat_render(sb, &s, level + 1, unit)
		}

	case .IF:
		for &c in n.children {
			if wat_node_is_simple(&c) {
				strings.write_byte(sb, ' ')
				wat_render(sb, &c, level, unit)
			} else {
				strings.write_byte(sb, '\n')
				indent_str(sb, unit, level + 1)
				wat_render(sb, &c, level + 1, unit)
			}
		}
		strings.write_byte(sb, '\n')
		indent_str(sb, unit, level + 1)
		{
			strings.write_string(sb, "(then")
			defer strings.write_byte(sb, ')')
			for &s in n.body {
				strings.write_byte(sb, '\n')
				indent_str(sb, unit, level + 2)
				wat_render(sb, &s, level + 2, unit)
			}
		}
		if len(n.els) > 0 {
			strings.write_byte(sb, '\n')
			indent_str(sb, unit, level + 1)
			strings.write_string(sb, "(else")
			defer strings.write_byte(sb, ')')
			for &s in n.els {
				strings.write_byte(sb, '\n')
				indent_str(sb, unit, level + 2)
				wat_render(sb, &s, level + 2, unit)
			}
		}
	}
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
			defer fmt.sbprintf(sb, " %s)\n", valtype_name(wasm.Value_Type(rt)))
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
		relocs := relocations_from_section_id(m.reloc_groups, sec.id)

		r := reader(m.data, sec.offset)
		count := rd_u32(&r) or_break
		for _ in 0..<count {
			vt  := rd_byte(&r) or_break
			mut := rd_byte(&r) or_break

			fmt.sbprintf(sb, "%s(global (;%d;) ", unit, idx)
			defer strings.write_string(sb, ")\n")

			if mut == 1 {
				fmt.sbprintf(sb, "(mut %s) ", valtype_name(wasm.Value_Type(vt)))
			} else {
				fmt.sbprintf(sb, "%s ", valtype_name(wasm.Value_Type(vt)))
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

		relocs := relocations_from_section_id(m.reloc_groups, sec.id)

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
				relocs := relocations_from_section_id(m.reloc_groups, sec.id)
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
wat_write_const_expr :: proc(sb: ^strings.Builder, m: Module, relocs: []wasm.Relocation, data: []u8, off: ^u32, unit: string, allocator: runtime.Allocator) {
	context.allocator = context.temp_allocator

	exprs: [dynamic]wasm.Instruction
	exprs.allocator = allocator
	defer delete(exprs)

	for off^ < u32(len(data)) {
		inst, _, next := wasm.decode_one(data, relocs, off^, allocator) or_break
		off^ = next
		if inst.mnemonic == .END {
			break
		}
		append(&exprs, inst)
	}

	i := 0
	stmts, _ := wat_fold_region(exprs[:], m, &i)
	for &s, k in stmts {
		if k > 0 { strings.write_byte(sb, ' ') }
		wat_render(sb, &s, 0, unit)
	}
}

wat_write_id_or_comment :: proc(sb: ^strings.Builder, name: string, index: u32) {
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
