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
	n_op := gen_opcodes(g["instructions"].(json.Array))
	n_k  := gen_operand_kinds(g["operand_kinds"].(json.Array))
	fmt.printfln("spirv tablegen: %d opcodes, %d operand kinds", n_op, n_k)
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
