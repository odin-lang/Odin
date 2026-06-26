// rexcode  ·  Brendan Punsky (dotbmp@github), original author

// SPIR-V table generator. Reads the vendored authoritative grammar
// (spirv.core.grammar.json, Khronos SPIRV-Headers unified1) and emits the
// package's generated Odin tables. The SPIR-V analog of an ISA tablegen: the
// grammar JSON is the single source of truth, as an arch's ENCODING_TABLE is.
//
//   odin run core/rexcode/ir/spirv/tablegen   # regenerate ../opcodes.odin + ../operand_kinds.odin
package rexcode_spirv_tablegen

import "core:encoding/json"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"

GRAMMAR_PATH :: #directory + "/spirv.core.grammar.json"
OPCODES_OUT  :: #directory + "/../opcodes.odin"
KINDS_OUT    :: #directory + "/../operand_kinds.odin"
TABLE_OUT    :: #directory + "/../encoding_table.odin"
BUILDERS_OUT :: #directory + "/../builders_gen.odin"

HDR ::
`// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_spirv

// GENERATED from spirv.core.grammar.json (SPIRV-Headers unified1) by tablegen/gen.odin.
// DO NOT EDIT -- regenerate with ` + "`odin run core/rexcode/ir/spirv/tablegen`" + `.
`

main :: proc() {
	data, rerr := os.read_entire_file(GRAMMAR_PATH, context.allocator)
	if rerr != nil {
		fmt.eprintln("spirv tablegen: cannot read", GRAMMAR_PATH, rerr)
		os.exit(1)
	}
	defer delete(data)

	root, err := json.parse(data, parse_integers = true)
	if err != .None {
		fmt.eprintln("spirv tablegen: json parse error:", err)
		os.exit(1)
	}
	defer json.destroy_value(root)

	g := root.(json.Object)
	insts := g["instructions"].(json.Array)
	kinds := g["operand_kinds"].(json.Array)
	n_op := gen_opcodes(insts)
	n_k  := gen_operand_kinds(kinds)
	n_sp := gen_encoding_table(insts, kinds)
	n_b  := gen_builders(insts, kinds)
	fmt.printfln("spirv tablegen: %d opcodes, %d operand kinds, %d operand specs, %d builders", n_op, n_k, n_sp, n_b)
}

write_file :: proc(path: string, sb: ^strings.Builder) {
	if werr := os.write_entire_file(path, sb.buf[:]); werr != nil {
		fmt.eprintln("spirv tablegen: write failed:", path, werr)
		os.exit(1)
	}
}

// --- opcodes.odin : the Opcode enum (deduped by opcode; the grammar lists
//     aliased opnames sharing an opcode, e.g. *GOOGLE == *KHR -- first wins). ---
gen_opcodes :: proc(insts: json.Array) -> int {
	Row :: struct { name: string, op: i64 }
	rows: [dynamic]Row; defer delete(rows)
	seen: map[i64]bool;  defer delete(seen)
	w := 0
	for v in insts {
		inst := v.(json.Object)
		op := i64(inst["opcode"].(json.Integer))
		if op in seen { continue }
		seen[op] = true
		name := string(inst["opname"].(json.String))
		append(&rows, Row{name, op})
		w = max(w, len(name))
	}

	sb := strings.builder_make(); defer strings.builder_destroy(&sb)
	strings.write_string(&sb, HDR)
	strings.write_string(&sb, "\n// SPIR-V operation opcodes. The values ARE the wire opcodes; the codec writes\n// them directly. OpNop = 0 doubles as the zero value (a benign no-op).\nOpcode :: enum u16 {\n")
	for r in rows {
		strings.write_byte(&sb, '\t')
		strings.write_string(&sb, r.name)
		for _ in 0 ..< w - len(r.name) { strings.write_byte(&sb, ' ') }
		fmt.sbprintf(&sb, " = %d,\n", r.op)
	}
	strings.write_string(&sb, "}\n")
	write_file(OPCODES_OUT, &sb)
	return len(rows)
}

// --- operand_kinds.odin : the Spec_Kind dispatch enum + every ValueEnum (Odin
//     enum) and BitEnum (bit_set + _Bit enum). ---
gen_operand_kinds :: proc(kinds: json.Array) -> int {
	sb := strings.builder_make(); defer strings.builder_destroy(&sb)
	strings.write_string(&sb, HDR)

	strings.write_string(&sb, "\n// Every operand kind the codec dispatches on (Id / Literal / Composite / each\n// ValueEnum / each BitEnum), in grammar order. Named Spec_Kind to avoid colliding\n// with the re-exported ir.Operand_Kind; the operand-layout table tags each\n// operand with one of these.\nSpec_Kind :: enum u8 {\n\tNONE = 0,\n")
	for v in kinds {
		k := v.(json.Object)
		fmt.sbprintf(&sb, "\t%s,\n", string(k["kind"].(json.String)))
	}
	strings.write_string(&sb, "}\n")

	for v in kinds {
		k := v.(json.Object)
		cat  := string(k["category"].(json.String))
		kind := string(k["kind"].(json.String))
		switch cat {
		case "ValueEnum": gen_value_enum(&sb, snake(kind), k)
		case "BitEnum":   gen_bit_enum(&sb, snake(kind), k)
		}
	}
	write_file(KINDS_OUT, &sb)
	return len(kinds)
}

gen_value_enum :: proc(sb: ^strings.Builder, name: string, k: json.Object) {
	Row :: struct { nm: string, val: i64 }
	rows: [dynamic]Row; defer delete(rows)
	seen: map[i64]bool;  defer delete(seen)
	w := 0
	if ens, ok := k["enumerants"]; ok {
		for ev in ens.(json.Array) {
			e := ev.(json.Object)
			val := parse_value(e["value"])
			if val in seen { continue }   // dedup aliases (same value, first name)
			seen[val] = true
			nm := ident(string(e["enumerant"].(json.String)))
			append(&rows, Row{nm, val}); w = max(w, len(nm))
		}
	}
	fmt.sbprintf(sb, "\n%s :: enum u32 {{\n", name)
	for r in rows {
		strings.write_byte(sb, '\t')
		strings.write_string(sb, r.nm)
		for _ in 0 ..< w - len(r.nm) { strings.write_byte(sb, ' ') }
		fmt.sbprintf(sb, " = %d,\n", r.val)
	}
	strings.write_string(sb, "}\n")
}

gen_bit_enum :: proc(sb: ^strings.Builder, name: string, k: json.Object) {
	Row :: struct { nm: string, pos: int }
	rows: [dynamic]Row; defer delete(rows)
	seen: map[int]bool;  defer delete(seen)
	w, maxpos := 0, 0
	if ens, ok := k["enumerants"]; ok {
		for ev in ens.(json.Array) {
			e := ev.(json.Object)
			mask := parse_value(e["value"])
			if mask == 0 || mask & (mask - 1) != 0 { continue }   // skip None / non-single-bit
			pos := bit_pos(mask)
			if pos in seen { continue }
			seen[pos] = true
			nm := ident(string(e["enumerant"].(json.String)))
			append(&rows, Row{nm, pos}); w = max(w, len(nm)); maxpos = max(maxpos, pos)
		}
	}
	backing := maxpos >= 32 ? "u64" : "u32"
	fmt.sbprintf(sb, "\n%s :: bit_set[%s_Bit; %s]\n", name, name, backing)
	fmt.sbprintf(sb, "%s_Bit :: enum %s {{\n", name, backing)
	for r in rows {
		strings.write_byte(sb, '\t')
		strings.write_string(sb, r.nm)
		for _ in 0 ..< w - len(r.nm) { strings.write_byte(sb, ' ') }
		fmt.sbprintf(sb, " = %d,\n", r.pos)
	}
	strings.write_string(sb, "}\n")
}

// --- encoding_table.odin : the operand-layout table that drives the codec.
//     INSTRUCTION_INDEX[opcode] -> a run of INSTRUCTION_SPECS (the opcode's
//     operands). When an enum operand's value/bit is in ENUM_PARAMS, its
//     PARAM_SPECS run follows as trailing operands. ---
gen_encoding_table :: proc(insts: json.Array, kinds: json.Array) -> int {
	Spec :: struct { kind, quant: string }
	specs: [dynamic]Spec; defer delete(specs)
	Run  :: struct { op, start, count: int }
	runs: [dynamic]Run; defer delete(runs)
	seen: map[i64]bool;  defer delete(seen)
	maxop := 0
	for v in insts {
		inst := v.(json.Object)
		op := int(inst["opcode"].(json.Integer))
		if i64(op) in seen { continue }
		seen[i64(op)] = true
		if op > maxop { maxop = op }
		start := len(specs)
		if ops, ok := inst["operands"]; ok {
			for ov in ops.(json.Array) {
				o := ov.(json.Object)
				q := "ONE"
				if qv, qok := o["quantifier"]; qok {
					qs := string(qv.(json.String))
					q = qs == "?" ? "OPTIONAL" : (qs == "*" ? "VARIADIC" : "ONE")
				}
				append(&specs, Spec{string(o["kind"].(json.String)), q})
			}
		}
		append(&runs, Run{op, start, len(specs) - start})
	}

	// enumerant -> trailing parameter operands (MemoryAccess.Aligned, ...).
	Par :: struct { kind: string, value: i64, params: [dynamic]string }
	pars: [dynamic]Par; defer delete(pars)
	for kv in kinds {
		k := kv.(json.Object)
		cat := string(k["category"].(json.String))
		if cat != "ValueEnum" && cat != "BitEnum" { continue }
		kname := string(k["kind"].(json.String))
		if ens, ok := k["enumerants"]; ok {
			vseen: map[i64]bool; defer delete(vseen)
			for ev in ens.(json.Array) {
				e := ev.(json.Object)
				ps, pok := e["parameters"]
				if !pok { continue }
				val := parse_value(e["value"])
				if val in vseen { continue }
				vseen[val] = true
				pp: [dynamic]string
				for pv in ps.(json.Array) {
					append(&pp, string(pv.(json.Object)["kind"].(json.String)))
				}
				append(&pars, Par{kname, val, pp})
			}
		}
	}

	sb := strings.builder_make(); defer strings.builder_destroy(&sb)
	strings.write_string(&sb, HDR)
	strings.write_string(&sb, "\n// The operand-layout table that drives the codec. INSTRUCTION_INDEX[opcode]\n// gives the run of INSTRUCTION_SPECS describing that opcode's operands; an enum\n// operand whose value/bit appears in ENUM_PARAMS is followed by its PARAM_SPECS\n// run as trailing operands.\n\n")
	strings.write_string(&sb, "Quantifier :: enum u8 { ONE, OPTIONAL, VARIADIC }\n\n")
	strings.write_string(&sb, "Operand_Spec :: struct {\n\tkind:  Spec_Kind,\n\tquant: Quantifier,\n}\n\n")
	strings.write_string(&sb, "Spec_Run :: struct {\n\tstart: u16,\n\tcount: u8,\n}\n\n")
	strings.write_string(&sb, "Enum_Param :: struct {\n\tkind:   Spec_Kind,   // which enum kind\n\tvalue:  u32,         // enumerant value (ValueEnum) or bit mask (BitEnum)\n\tparams: Spec_Run,    // run in PARAM_SPECS\n}\n")

	fmt.sbprintf(&sb, "\n@(rodata) INSTRUCTION_SPECS := [%d]Operand_Spec{{\n", len(specs))
	for s in specs { fmt.sbprintf(&sb, "\t{{.%s, .%s}},\n", s.kind, s.quant) }
	strings.write_string(&sb, "}\n")

	fmt.sbprintf(&sb, "\n@(rodata) INSTRUCTION_INDEX := [%d]Spec_Run{{\n", maxop + 1)
	for r in runs { fmt.sbprintf(&sb, "\t%d = {{%d, %d}},\n", r.op, r.start, r.count) }
	strings.write_string(&sb, "}\n")

	pspecs: [dynamic]string; defer delete(pspecs)
	fmt.sbprintf(&sb, "\n@(rodata) ENUM_PARAMS := [%d]Enum_Param{{\n", len(pars))
	for p in pars {
		pstart := len(pspecs)
		for pk in p.params { append(&pspecs, pk) }
		fmt.sbprintf(&sb, "\t{{.%s, %d, {{%d, %d}}}},\n", p.kind, p.value, pstart, len(p.params))
	}
	strings.write_string(&sb, "}\n")

	fmt.sbprintf(&sb, "\n@(rodata) PARAM_SPECS := [%d]Spec_Kind{{\n", len(pspecs))
	for ps in pspecs { fmt.sbprintf(&sb, "\t.%s,\n", ps) }
	strings.write_string(&sb, "}\n")

	write_file(TABLE_OUT, &sb)
	return len(specs)
}

// --- builders_gen.odin : a typed constructor (low level) + Builder method (high
//     level) for EVERY opcode. Each operand maps to a typed parameter by its kind
//     and quantifier; nothing is skipped. Operations are built with a running
//     operand index `n`, so optional (Maybe), variadic ([]T), composite ([]Pair_*)
//     and string operands all compose. A verb that would clash with a keyword,
//     builtin, or re-exported name gets a trailing "_". ---
@(private="file")
B_Op :: struct { class, quant, typ: string }   // class in {id,lit,venum,benum,string,pair_ii,pair_li,pair_il}; quant in {one,opt,var}

gen_builders :: proc(insts: json.Array, kinds: json.Array) -> int {
	category: map[string]string; defer delete(category)
	for kv in kinds {
		k := kv.(json.Object)
		category[string(k["kind"].(json.String))] = string(k["category"].(json.String))
	}

	sb := strings.builder_make(); defer strings.builder_destroy(&sb)
	strings.write_string(&sb, HDR)

	seen: map[i64]bool;       defer delete(seen)
	verb_n: map[string]int;   defer delete(verb_n)   // base verb -> times used (dedup)
	count := 0
	for v in insts {
		inst := v.(json.Object)
		op := i64(inst["opcode"].(json.Integer))
		if op in seen { continue }
		seen[op] = true
		opname := string(inst["opname"].(json.String))

		has_rt, has_r := false, false
		ops: [dynamic]B_Op; defer delete(ops)
		if oparr_v, hop := inst["operands"]; hop {
			for ov in oparr_v.(json.Array) {
				o := ov.(json.Object)
				kind := string(o["kind"].(json.String))
				quant := "one"
				if q, hq := o["quantifier"]; hq {
					qs := string(q.(json.String))
					quant = qs == "*" ? "var" : (qs == "?" ? "opt" : "one")
				}
				switch kind {
				case "IdResultType": has_rt = true
				case "IdResult":     has_r = true
				case:
					class, typ := classify_operand(kind, category[kind])
					append(&ops, B_Op{class, quant, typ})
				}
			}
		}

		base := verb_name(opname)
		verb := verb_n[base] == 0 ? base : fmt.tprintf("%s_%d", base, verb_n[base] + 1)
		verb_n[base] += 1
		gen_one_builder(&sb, opname, verb, has_rt, has_r, ops[:])
		count += 1
	}

	write_file(BUILDERS_OUT, &sb)
	return count
}

@(private="file")
classify_operand :: proc(kind, cat: string) -> (class, typ: string) {
	switch {
	case kind == "IdRef" || kind == "IdScope" || kind == "IdMemorySemantics": return "id", "Id"
	case kind == "LiteralString":            return "string", "string"
	case kind == "PairIdRefIdRef":           return "pair_ii", "Pair_Id_Id"
	case kind == "PairLiteralIntegerIdRef":  return "pair_li", "Pair_Lit_Id"
	case kind == "PairIdRefLiteralInteger":  return "pair_il", "Pair_Id_Lit"
	case cat == "ValueEnum":                 return "venum", snake(kind)
	case cat == "BitEnum":                   return "benum", snake(kind)
	}
	return "lit", "i64"   // LiteralInteger / context-dependent / ext-inst / spec-op number
}

@(private="file")
param_type :: proc(o: B_Op) -> string {
	switch o.quant {
	case "opt": return fmt.tprintf("Maybe(%s)", o.typ)
	case "var": return fmt.tprintf("[]%s", o.typ)
	}
	return o.typ
}

// op_* constructor expression for a single scalar value `v` of `class`.
@(private="file")
one_emit :: proc(class, v: string) -> string {
	switch class {
	case "id":    return fmt.tprintf("op_value(%s)", v)
	case "venum": return fmt.tprintf("op_int(i64(%s))", v)
	case "benum": return fmt.tprintf("op_int(i64(transmute(u32)%s))", v)
	}
	return fmt.tprintf("op_int(%s)", v)   // lit
}

@(private="file")
emit_op_body :: proc(sb: ^strings.Builder, o: B_Op, idx: int) {
	v := fmt.tprintf("op%d", idx)
	switch o.quant {
	case "one":
		if o.class == "string" { fmt.sbprintf(sb, "\tn += pack_string_operands(buf[n:], %s)\n", v) }
		else                   { fmt.sbprintf(sb, "\tbuf[n] = %s; n += 1\n", one_emit(o.class, v)) }
	case "opt":
		if o.class == "string" { fmt.sbprintf(sb, "\tif s, sok := %s.?; sok {{ n += pack_string_operands(buf[n:], s) }}\n", v) }
		else                   { fmt.sbprintf(sb, "\tif x, xok := %s.?; xok {{ buf[n] = %s; n += 1 }}\n", v, one_emit(o.class, "x")) }
	case "var":
		switch o.class {
		case "pair_ii": fmt.sbprintf(sb, "\tfor p in %s {{ buf[n] = op_value(p.a); buf[n + 1] = op_value(p.b); n += 2 }}\n", v)
		case "pair_li": fmt.sbprintf(sb, "\tfor p in %s {{ buf[n] = op_int(p.lit); buf[n + 1] = op_value(p.id); n += 2 }}\n", v)
		case "pair_il": fmt.sbprintf(sb, "\tfor p in %s {{ buf[n] = op_value(p.id); buf[n + 1] = op_int(p.lit); n += 2 }}\n", v)
		case:           fmt.sbprintf(sb, "\tfor x in %s {{ buf[n] = %s; n += 1 }}\n", v, one_emit(o.class, "x"))
		}
	}
}

// Upper bound on the operand words `op{idx}` contributes (for opbuf sizing).
@(private="file")
size_term :: proc(o: B_Op, idx: int) -> string {
	v := fmt.tprintf("op%d", idx)
	switch o.quant {
	case "opt":
		if o.class == "string" { return fmt.tprintf("(len(%s.? or_else \"\") + 4) / 4", v) }
		return "1"
	case "var":
		if o.class == "pair_ii" || o.class == "pair_li" || o.class == "pair_il" { return fmt.tprintf("2 * len(%s)", v) }
		return fmt.tprintf("len(%s)", v)
	}
	if o.class == "string" { return fmt.tprintf("(len(%s) + 4) / 4", v) }
	return "1"
}

@(private="file")
gen_one_builder :: proc(sb: ^strings.Builder, opname, verb: string, has_rt, has_r: bool, ops: []B_Op) {
	has_buf := len(ops) > 0

	// --- low-level constructor ---
	ll: [dynamic]string; defer delete(ll)
	if has_buf { append(&ll, "buf: []Operand") }
	if has_rt  { append(&ll, "result_type: Type_Ref") }
	if has_r   { append(&ll, "result: Id") }
	for o, i in ops { append(&ll, fmt.tprintf("op%d: %s", i + 1, param_type(o))) }

	fmt.sbprintf(sb, "\ninst_%s :: #force_inline proc \"contextless\" (%s) -> Operation {{\n", opname, join(ll[:]))
	if has_buf { strings.write_string(sb, "\tn := 0\n") }
	for o, i in ops { emit_op_body(sb, o, i + 1) }
	result_str := has_r ? (has_rt ? "{result, result_type}" : "{id = result}") : "{id = ID_NONE}"
	operands_str := has_buf ? ", operands = buf[:n]" : ""
	fmt.sbprintf(sb, "\treturn Operation{{opcode = u16(Opcode.%s), result = %s%s}}\n}}\n", opname, result_str, operands_str)

	// --- high-level Builder method ---
	hl: [dynamic]string; defer delete(hl)
	append(&hl, "b: ^Builder")
	if has_rt { append(&hl, "result_type: Type_Ref") }
	for o, i in ops { append(&hl, fmt.tprintf("op%d: %s", i + 1, param_type(o))) }

	call: [dynamic]string; defer delete(call)
	if has_buf {
		size: [dynamic]string; defer delete(size)
		for o, i in ops { append(&size, size_term(o, i + 1)) }
		append(&call, fmt.tprintf("opbuf(b, %s)", strings.join(size[:], " + ")))
	}
	if has_rt { append(&call, "result_type") }
	if has_r  { append(&call, "r") }
	for _, i in ops { append(&call, fmt.tprintf("op%d", i + 1)) }

	fmt.sbprintf(sb, "\n%s :: proc(%s)%s {{\n", verb, join(hl[:]), has_r ? " -> Id" : "")
	if has_r { strings.write_string(sb, "\tr := alloc_id(b)\n") }
	fmt.sbprintf(sb, "\tappend(&b.ops, inst_%s(%s))\n", opname, join(call[:]))
	if has_r { strings.write_string(sb, "\treturn r\n") }
	strings.write_string(sb, "}\n")
}

// The high-level verb: the OpName minus "Op", snake-cased + lowercased, with a
// trailing "_" if it collides with an Odin keyword (return, switch, ...).
@(private="file")
verb_name :: proc(opname: string) -> string {
	s := opname
	if len(s) > 2 && s[0] == 'O' && s[1] == 'p' { s = s[2:] }
	out := to_lower(snake(s))
	return is_keyword(out) ? strings.concatenate({out, "_"}) : out
}

@(private="file")
to_lower :: proc(s: string) -> string {
	b := make([]u8, len(s))
	for i in 0 ..< len(s) { b[i] = (s[i] >= 'A' && s[i] <= 'Z') ? s[i] + 32 : s[i] }
	return string(b)
}

// Odin keywords AND builtins a generated verb must not shadow (e.g. OpSizeOf ->
// size_of would shadow the size_of builtin and break the package).
@(private="file")
is_keyword :: proc(s: string) -> bool {
	switch s {
	case "return", "switch", "in", "map", "for", "if", "else", "when", "case",
	     "struct", "enum", "union", "proc", "import", "package", "using", "defer",
	     "context", "distinct", "bit_set", "matrix", "or_else", "or_return",
	     "size_of", "align_of", "offset_of", "type_of", "typeid_of", "type_info_of",
	     "len", "cap", "min", "max", "abs", "clamp", "swizzle", "make", "new",
	     "delete", "append", "copy", "assert", "transmute", "cast", "raw_data",
	     // re-exported ir.type_* constructors (Type-Declaration verbs collide):
	     "type_void", "type_bool", "type_int", "type_float", "type_vector",
	     "type_pointer", "type_array",
	     // builtin type names (OpString -> string would shadow the string type):
	     "string", "cstring", "bool", "int", "uint", "uintptr", "rawptr", "rune",
	     "byte", "any", "typeid", "i8", "i16", "i32", "i64", "i128", "u8", "u16",
	     "u32", "u64", "u128", "f16", "f32", "f64", "b8", "b16", "b32", "b64":
		return true
	}
	return false
}

@(private="file")
join :: proc(parts: []string) -> string {
	return strings.join(parts, ", ")
}

// -----------------------------------------------------------------------------
// helpers
// -----------------------------------------------------------------------------

is_upper :: proc(c: u8) -> bool { return c >= 'A' && c <= 'Z' }
is_lower :: proc(c: u8) -> bool { return c >= 'a' && c <= 'z' }
is_digit :: proc(c: u8) -> bool { return c >= '0' && c <= '9' }
is_alnum :: proc(c: u8) -> bool { return is_upper(c) || is_lower(c) || is_digit(c) }

// CamelCase grammar kind -> Snake_Case Odin type name (AddressingModel ->
// Addressing_Model, FPRoundingMode -> FP_Rounding_Mode), preserving acronym runs.
snake :: proc(name: string) -> string {
	sb := strings.builder_make()
	for i in 0 ..< len(name) {
		c := name[i]
		if i > 0 && is_upper(c) {
			prev := name[i - 1]
			next_lower := i + 1 < len(name) && is_lower(name[i + 1])
			if is_lower(prev) || is_digit(prev) || (is_upper(prev) && next_lower) {
				strings.write_byte(&sb, '_')
			}
		}
		strings.write_byte(&sb, c)
	}
	return strings.to_string(sb)
}

// A valid Odin enumerant identifier (SPIR-V enumerants are already valid; guard
// the rare leading digit / stray punctuation anyway).
ident :: proc(name: string) -> string {
	sb := strings.builder_make()
	if len(name) > 0 && is_digit(name[0]) { strings.write_byte(&sb, '_') }
	for i in 0 ..< len(name) {
		c := name[i]
		strings.write_byte(&sb, (is_alnum(c) || c == '_') ? c : '_')
	}
	return strings.to_string(sb)
}

bit_pos :: proc(mask: i64) -> int {
	p, m := 0, mask
	for m > 1 { m >>= 1; p += 1 }
	return p
}

// An enumerant value is either a JSON integer or a hex string ("0x0001").
parse_value :: proc(v: json.Value) -> i64 {
	#partial switch x in v {
	case json.Integer: return i64(x)
	case json.String:  n, _ := strconv.parse_i64(string(x)); return n
	}
	return 0
}
