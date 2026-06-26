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

// --- builders_gen.odin : typed per-opcode constructors (low level) + Builder
//     methods (high level). Opcodes whose operands aren't yet expressible as
//     simple typed params (optional, Pair* composites, LiteralString, ...) are
//     skipped -- those stay hand-written, like an ISA's can_generate_builder. ---
@(private="file")
B_Param :: struct { typ: string, emit: string }

gen_builders :: proc(insts: json.Array, kinds: json.Array) -> int {
	category: map[string]string; defer delete(category)
	for kv in kinds {
		k := kv.(json.Object)
		category[string(k["kind"].(json.String))] = string(k["category"].(json.String))
	}

	sb := strings.builder_make(); defer strings.builder_destroy(&sb)
	strings.write_string(&sb, HDR)

	seen: map[i64]bool;        defer delete(seen)
	verb_seen: map[string]bool; defer delete(verb_seen)
	count := 0
	for v in insts {
		inst := v.(json.Object)
		op := i64(inst["opcode"].(json.Integer))
		if op in seen { continue }
		seen[op] = true
		opname := string(inst["opname"].(json.String))

		// Type-declaration opcodes are ir.Type, not Operations -- skip them (their
		// verbs would also collide with the re-exported ir.type_* constructors).
		if c, hc := inst["class"]; hc && string(c.(json.String)) == "Type-Declaration" { continue }

		has_rt, has_r, variadic, ok := false, false, false, true
		fixed: [dynamic]B_Param; defer delete(fixed)
		if ops, hop := inst["operands"]; hop {
			oparr := ops.(json.Array)
			for ov, oi in oparr {
				o := ov.(json.Object)
				kind := string(o["kind"].(json.String))
				quant := ""
				if q, hq := o["quantifier"]; hq { quant = string(q.(json.String)) }
				switch {
				case kind == "IdResultType": has_rt = true
				case kind == "IdResult":     has_r = true
				case quant == "*":
					if oi != len(oparr) - 1 || kind != "IdRef" { ok = false } else { variadic = true }
				case quant == "?":
					ok = false   // optional operands not expressible yet
				case kind == "IdRef" || kind == "IdScope" || kind == "IdMemorySemantics":
					append(&fixed, B_Param{"Id", "id"})
				case kind == "LiteralInteger":
					append(&fixed, B_Param{"i64", "int"})
				case category[kind] == "ValueEnum":
					append(&fixed, B_Param{snake(kind), "venum"})
				case category[kind] == "BitEnum":
					append(&fixed, B_Param{snake(kind), "benum"})
				case:
					ok = false   // Composite / LiteralString / context-dependent number
				}
				if !ok { break }
			}
		}
		if !ok { continue }

		verb := verb_name(opname)
		if verb in verb_seen { continue }   // skip a name collision rather than shadow
		verb_seen[verb] = true
		gen_one_builder(&sb, opname, verb, has_rt, has_r, fixed[:], variadic)
		count += 1
	}

	write_file(BUILDERS_OUT, &sb)
	return count
}

@(private="file")
gen_one_builder :: proc(sb: ^strings.Builder, opname, verb: string, has_rt, has_r: bool, fixed: []B_Param, variadic: bool) {
	nfix := len(fixed)
	has_buf := nfix > 0 || variadic

	// --- low-level constructor ---
	ll: [dynamic]string; defer delete(ll)
	if has_buf { append(&ll, "buf: []Operand") }
	if has_rt  { append(&ll, "result_type: Type_Ref") }
	if has_r   { append(&ll, "result: Id") }
	for p, i in fixed { append(&ll, fmt.tprintf("op%d: %s", i + 1, p.typ)) }
	if variadic { append(&ll, "args: []Id") }

	fmt.sbprintf(sb, "\ninst_%s :: #force_inline proc \"contextless\" (%s) -> Operation {{\n",
		opname, join(ll[:]))
	for p, i in fixed {
		switch p.emit {
		case "id":    fmt.sbprintf(sb, "\tbuf[%d] = op_value(op%d)\n", i, i + 1)
		case "int":   fmt.sbprintf(sb, "\tbuf[%d] = op_int(op%d)\n", i, i + 1)
		case "venum": fmt.sbprintf(sb, "\tbuf[%d] = op_int(i64(op%d))\n", i, i + 1)
		case "benum": fmt.sbprintf(sb, "\tbuf[%d] = op_int(i64(transmute(u32)op%d))\n", i, i + 1)
		}
	}
	if variadic { fmt.sbprintf(sb, "\tfor v, i in args {{ buf[%d + i] = op_value(v) }}\n", nfix) }
	result_str := has_r ? (has_rt ? "{result, result_type}" : "{id = result}") : "{id = ID_NONE}"
	operands_str := ""
	if has_buf { operands_str = variadic ? fmt.tprintf(", operands = buf[:%d + len(args)]", nfix) : fmt.tprintf(", operands = buf[:%d]", nfix) }
	fmt.sbprintf(sb, "\treturn Operation{{opcode = u16(Opcode.%s), result = %s%s}}\n}}\n", opname, result_str, operands_str)

	// --- high-level Builder method ---
	hl: [dynamic]string; defer delete(hl)
	append(&hl, "b: ^Builder")
	if has_rt { append(&hl, "result_type: Type_Ref") }
	for p, i in fixed { append(&hl, fmt.tprintf("op%d: %s", i + 1, p.typ)) }
	if variadic { append(&hl, "args: []Id") }

	call: [dynamic]string; defer delete(call)
	if has_buf { append(&call, variadic ? fmt.tprintf("opbuf(b, %d + len(args))", nfix) : fmt.tprintf("opbuf(b, %d)", nfix)) }
	if has_rt { append(&call, "result_type") }
	if has_r  { append(&call, "r") }
	for _, i in fixed { append(&call, fmt.tprintf("op%d", i + 1)) }
	if variadic { append(&call, "args") }

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
	     "delete", "append", "copy", "assert", "transmute", "cast", "raw_data":
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
