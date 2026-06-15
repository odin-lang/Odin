// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package main

// =============================================================================
// MOS 6502 Mnemonic Builder Generator
// =============================================================================
//
// Generates mnemonic_builders.odin by iterating the encoder's ENCODE_FORMS
// (via ENCODE_RUNS) and emitting typed builder procedures with overloading
// for each mnemonic.
//
// The 6502 is opcode/addressing-mode based: an operand "type" IS an
// addressing mode. A single `Memory` value carries the addressing mode in
// its `mode` field, so every memory addressing-mode form of a mnemonic
// collapses to one `inst_<mnem>_m(m: Memory)` builder (the encoder's matcher
// dispatches to the right opcode from the mode). The remaining operand
// shapes (implicit accumulator, immediate, relative branch, BBR/BBS zp+rel,
// HuC TST imm+mem, HuC block transfer) each get their own builder.
//
// Run with: odin run tools/gen_mnemonic_builders.odin -file
//
// Output: mnemonic_builders.odin (written to current directory; move/copy to
// the package root).

import "core:fmt"
import "core:os"
import "core:strings"
import "core:slice"
import m6502 "../"

GEN_ATTRIB :: "// rexcode  ·  Brendan Punsky (dotbmp@github), original author\n\n"

// -----------------------------------------------------------------------------
// Builder shape: the distinct call signatures a 6502 mnemonic form maps to.
// -----------------------------------------------------------------------------

Shape :: enum {
	NONE,    // no operands               -> inst_none(.M)
	A,       // implicit accumulator      -> inst_a(.M)
	IMM8,    // #$nn                       -> inst_i(.M, imm)
	REL,     // PC-relative branch target -> inst_rel(.M, label)
	MEM,     // any addressing-mode mem   -> inst_m(.M, mem)
	ZP_REL,  // BBR/BBS: zp + rel branch  -> inst_zp_rel(.M, zp, label)
	TST,     // HuC TST: imm + mem        -> inst_tst(.M, imm, mem)
	BLOCK,   // HuC block xfer: 3x word16 -> inst_block(.M, src, dst, len)
	SKIP,    // could not classify
}

Proc_Entry :: struct {
	mnemonic: m6502.Mnemonic,
	shape:    Shape,
	name:     string, // inst_<mnem>_<suffix>
}

mnemonic_to_lower :: proc(m: m6502.Mnemonic) -> string {
	return strings.to_lower(fmt.tprintf("%v", m))
}

// Base instruction helpers in instructions.odin are inst_<x> for these x.
// If a mnemonic lowercases to one of them, an overload group named inst_<x>
// would redeclare the helper -- so we suppress the group for that mnemonic.
BASE_HELPER_SUFFIXES :: []string{"none", "a", "i", "m", "rel", "zp_rel", "tst", "block"}

collides_with_base_helper :: proc(lower: string) -> bool {
	for s in BASE_HELPER_SUFFIXES {
		if lower == s { return true }
	}
	return false
}

// Classify a single encoding form into a builder Shape.
classify :: proc(form: m6502.Encoding) -> Shape {
	// Gather the explicit operand types (skip trailing NONEs).
	ops: [4]m6502.Operand_Type
	n := 0
	for op in form.ops {
		if op == .NONE { continue }
		ops[n] = op
		n += 1
	}

	switch n {
	case 0:
		return .NONE
	case 1:
		switch ops[0] {
		case .A_IMPL:
			return .A
		case .IMM_8:
			return .IMM8
		case .REL:
			return .REL
		case .MEM_ZP, .MEM_ZP_X, .MEM_ZP_Y, .MEM_ABS, .MEM_ABS_X, .MEM_ABS_Y,
		     .MEM_IND, .MEM_IND_X, .MEM_IND_Y, .MEM_IND_ZP, .MEM_IND_ABS_X:
			return .MEM
		case .NONE, .IMM_16:
			return .SKIP
		}
	case 2:
		// BBR/BBS: zero-page byte + PC-relative branch.
		if ops[0] == .MEM_ZP && ops[1] == .REL {
			return .ZP_REL
		}
		// HuC6280 TST: immediate + memory (any of zp/abs/zp,X/abs,X).
		#partial switch ops[0] {
		case .IMM_8:
			#partial switch ops[1] {
			case .MEM_ZP, .MEM_ZP_X, .MEM_ABS, .MEM_ABS_X:
				return .TST
			}
		}
		return .SKIP
	case 3:
		// HuC6280 block transfer: three 16-bit immediates (src, dst, len).
		if ops[0] == .IMM_16 && ops[1] == .IMM_16 && ops[2] == .IMM_16 {
			return .BLOCK
		}
		return .SKIP
	}
	return .SKIP
}

// Suffix appended to inst_/emit_ for a shape (distinguishes overload members).
shape_suffix :: proc(s: Shape) -> string {
	switch s {
	case .NONE:   return "none"
	case .A:      return "a"
	case .IMM8:   return "imm8"
	case .REL:    return "rel"
	case .MEM:    return "m"
	case .ZP_REL: return "zp_rel"
	case .TST:    return "tst"
	case .BLOCK:  return "block"
	case .SKIP:   return "skip"
	}
	return "unk"
}

main :: proc() {
	fmt.println("Generating MOS 6502 mnemonic builders from ENCODE_FORMS...")

	procs_by_mnemonic: map[m6502.Mnemonic][dynamic]Proc_Entry
	defer {
		for _, v in procs_by_mnemonic { delete(v) }
		delete(procs_by_mnemonic)
	}

	seen: map[string]bool          // dedup by generated proc name
	defer delete(seen)

	skipped: [dynamic]string
	defer delete(skipped)

	total_forms := 0

	for mnemonic in m6502.Mnemonic {
		if mnemonic == .INVALID { continue }

		_run := m6502.ENCODE_RUNS[u16(mnemonic)]
		forms := m6502.ENCODE_FORMS[_run.start:][:_run.count]
		if len(forms) == 0 { continue }

		for form in forms {
			total_forms += 1
			shape := classify(form)
			if shape == .SKIP {
				append(&skipped, fmt.aprintf("%v (opcode 0x%02X)", mnemonic, form.opcode))
				continue
			}

			name := fmt.aprintf("inst_%s_%s", mnemonic_to_lower(mnemonic), shape_suffix(shape))
			if name in seen {
				delete(name)
				continue
			}
			seen[name] = true

			if mnemonic not_in procs_by_mnemonic {
				procs_by_mnemonic[mnemonic] = make([dynamic]Proc_Entry)
			}
			append(&procs_by_mnemonic[mnemonic], Proc_Entry{
				mnemonic = mnemonic,
				shape    = shape,
				name     = name,
			})
		}
	}

	// Stable mnemonic ordering (enum order).
	mnemonic_list: [dynamic]m6502.Mnemonic
	defer delete(mnemonic_list)
	for k in procs_by_mnemonic { append(&mnemonic_list, k) }
	slice.sort_by(mnemonic_list[:], proc(a, b: m6502.Mnemonic) -> bool {
		return int(a) < int(b)
	})

	// Column width for tidy alignment of names.
	pad := 0
	for mnemonic in mnemonic_list {
		for e in procs_by_mnemonic[mnemonic] {
			pad = max(pad, len(e.name))
		}
	}

	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)

	generate_header(&sb)

	strings.write_string(&sb, `// =============================================================================
// Individual Typed Builder Procedures
// =============================================================================

`)

	for mnemonic in mnemonic_list {
		procs := procs_by_mnemonic[mnemonic]
		for e in procs { generate_inst_proc(&sb, e, pad) }
		for e in procs { generate_emit_proc(&sb, e, pad) }
	}

	strings.write_string(&sb, `
// =============================================================================
// Overload Groups
// =============================================================================

`)

	for mnemonic in mnemonic_list {
		procs := procs_by_mnemonic[mnemonic]
		if len(procs) == 0 { continue }
		// A mnemonic named the same as an existing base helper (e.g. TST -> the
		// HuC `inst_tst` bit-test helper) would have its overload group shadow /
		// redeclare that helper. Skip the group in that case; the per-shape
		// members (inst_<mnem>_<suffix>) remain the typed entry points.
		lower := mnemonic_to_lower(mnemonic)
		if collides_with_base_helper(lower) {
			fmt.sbprintf(&sb, "// inst_%s / emit_%s overload group omitted: name collides with base helper inst_%s.\n",
				lower, lower, lower)
			continue
		}
		generate_overload_group(&sb, mnemonic, procs[:], pad)
	}

	output := strings.to_string(sb)
	err := os.write_entire_file(#directory + "/../mnemonic_builders.odin",
		transmute([]u8)strings.concatenate({GEN_ATTRIB, output}))
	if err == nil {
		fmt.println("Generated mnemonic_builders.odin successfully!")
		total_procs := 0
		for mn in mnemonic_list { total_procs += len(procs_by_mnemonic[mn]) }
		fmt.printf("Mnemonics with builders: %d\n", len(mnemonic_list))
		fmt.printf("Builder procedures:      %d (each with an emit_ twin)\n", total_procs)
		fmt.printf("Encode forms scanned:    %d\n", total_forms)
		fmt.printf("Forms skipped:           %d\n", len(skipped))
		for s in skipped { fmt.printf("  - %s\n", s) }
	} else {
		fmt.eprintln("Failed to write mnemonic_builders.odin")
		os.exit(1)
	}
}

generate_header :: proc(sb: ^strings.Builder) {
	strings.write_string(sb, `package rexcode_mos6502

// =============================================================================
// GENERATED FILE - DO NOT EDIT
// =============================================================================
//
// Generated by tools/gen_mnemonic_builders.odin from ENCODE_FORMS / ENCODE_RUNS.
// Regenerate with: odin run mos6502/tools/gen_mnemonic_builders.odin -file
//
// Typed mnemonic builder procedures with overloading. The 6502's addressing
// mode is intrinsic to the Memory value passed in (its 'mode' field), so a
// single inst_<mnem>_m(m: Memory) covers every addressing-mode form of a
// mnemonic; the encoder's matcher selects the opcode from the mode.
//
// For each mnemonic:
//   inst_<mnem>     overload set returning an Instruction
//   emit_<mnem>     overload set that appends to a [dynamic]Instruction

`)
}

// Build the parameter list and the inst_ body call expression for a shape.
shape_params :: proc(s: Shape) -> string {
	switch s {
	case .NONE:   return ""
	case .A:      return ""
	case .IMM8:   return "imm: i64"
	case .REL:    return "label_id: u32"
	case .MEM:    return "m: Memory"
	case .ZP_REL: return "zp: u8, label_id: u32"
	case .TST:    return "imm: i64, m: Memory"
	case .BLOCK:  return "src, dst, length_val: u16"
	case .SKIP:   return ""
	}
	return ""
}

// inst_ body: `return inst_<helper>(.MNEM, args...)`
shape_inst_body :: proc(sb: ^strings.Builder, e: Proc_Entry) {
	mn := fmt.tprintf("%v", e.mnemonic)
	switch e.shape {
	case .NONE:   fmt.sbprintf(sb, "inst_none(.%s)", mn)
	case .A:      fmt.sbprintf(sb, "inst_a(.%s)", mn)
	case .IMM8:   fmt.sbprintf(sb, "inst_i(.%s, imm)", mn)
	case .REL:    fmt.sbprintf(sb, "inst_rel(.%s, label_id)", mn)
	case .MEM:    fmt.sbprintf(sb, "inst_m(.%s, m)", mn)
	case .ZP_REL: fmt.sbprintf(sb, "inst_zp_rel(.%s, zp, label_id)", mn)
	case .TST:    fmt.sbprintf(sb, "inst_tst(.%s, imm, m)", mn)
	case .BLOCK:  fmt.sbprintf(sb, "inst_block(.%s, src, dst, length_val)", mn)
	case .SKIP:   strings.write_string(sb, "{}")
	}
}

// emit_ body: append the corresponding inst_ result.
shape_emit_body :: proc(sb: ^strings.Builder, e: Proc_Entry) {
	strings.write_string(sb, "append(instructions, ")
	shape_inst_body(sb, e)
	strings.write_string(sb, ")")
}

generate_inst_proc :: proc(sb: ^strings.Builder, e: Proc_Entry, pad: int) {
	params := shape_params(e.shape)

	strings.write_string(sb, e.name)
	for n := pad - len(e.name); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	strings.write_string(sb, " :: #force_inline proc \"contextless\" (")
	strings.write_string(sb, params)
	strings.write_string(sb, ") -> Instruction { return ")
	shape_inst_body(sb, e)
	strings.write_string(sb, " }\n")
}

generate_emit_proc :: proc(sb: ^strings.Builder, e: Proc_Entry, pad: int) {
	params := shape_params(e.shape)
	emit_name := strings.concatenate({"emit_", e.name[5:]}) // strip "inst_"
	defer delete(emit_name)

	strings.write_string(sb, emit_name)
	for n := pad - len(e.name); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	strings.write_string(sb, " :: #force_inline proc(instructions: ^[dynamic]Instruction")
	if len(params) > 0 {
		strings.write_string(sb, ", ")
		strings.write_string(sb, params)
	}
	strings.write_string(sb, ") { ")
	shape_emit_body(sb, e)
	strings.write_string(sb, " }\n")
}

generate_overload_group :: proc(sb: ^strings.Builder, mnemonic: m6502.Mnemonic, procs: []Proc_Entry, pad: int) {
	lower := mnemonic_to_lower(mnemonic)

	// inst_<mnem> :: proc{ ... }  (or direct alias for a single member)
	strings.write_string(sb, "inst_")
	strings.write_string(sb, lower)
	for n := pad - len(lower); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	if len(procs) == 1 {
		strings.write_string(sb, " :: ")
		strings.write_string(sb, procs[0].name)
		strings.write_byte(sb, '\n')
	} else {
		strings.write_string(sb, " :: proc{ ")
		for e, i in procs {
			if i > 0 { strings.write_string(sb, ", ") }
			strings.write_string(sb, e.name)
		}
		strings.write_string(sb, " }\n")
	}

	// emit_<mnem> :: proc{ ... }
	strings.write_string(sb, "emit_")
	strings.write_string(sb, lower)
	for n := pad - len(lower); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	if len(procs) == 1 {
		name := strings.concatenate({"emit_", procs[0].name[5:]})
		defer delete(name)
		strings.write_string(sb, " :: ")
		strings.write_string(sb, name)
		strings.write_byte(sb, '\n')
	} else {
		strings.write_string(sb, " :: proc{ ")
		for e, i in procs {
			if i > 0 { strings.write_string(sb, ", ") }
			name := strings.concatenate({"emit_", e.name[5:]})
			defer delete(name)
			strings.write_string(sb, name)
		}
		strings.write_string(sb, " }\n")
	}
}
