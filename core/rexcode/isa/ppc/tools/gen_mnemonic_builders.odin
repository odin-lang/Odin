// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package main

// =============================================================================
// PowerPC Mnemonic Builder Generator
// =============================================================================
//
// Generates ppc/mnemonic_builders.odin by iterating the encoder's per-mnemonic
// ENCODE_FORMS runs and emitting typed builder procedures (one `inst_*` that
// returns an Instruction, one `emit_*` that appends it) with overload groups
// `inst_<mnemonic>` / `emit_<mnemonic>`.
//
// Unlike x86, PowerPC has no typed register enums — every register operand
// (GPR/FPR/VR/VSR/VR128/CR_FIELD/CR_BIT/SPR) is the generic `Register` type,
// so builder params for those operands are `Register`. This is less type-safe
// than x86's per-class wrappers, but the per-mnemonic overloads still document
// each form's operand shape.
//
// Run with: odin run tools/gen_mnemonic_builders.odin -file
//           (writes ppc/mnemonic_builders.odin)

import "core:fmt"
import "core:os"
import "core:strings"
import "core:slice"
import ppc "../"

GEN_ATTRIB :: "// rexcode  ·  Brendan Punsky (dotbmp@github), original author\n\n"

OUTPUT_PATH :: #directory + "/../mnemonic_builders.odin"

// One generated builder: a mnemonic plus its operand signature (the non-NONE
// operand types of a single encode form).
Proc_Entry :: struct {
	mnemonic:  ppc.Mnemonic,
	ops:       [4]ppc.Operand_Type,
	count:     int,
	proc_name: string, // full "inst_<mnem>_<suffix...>" name
}

main :: proc() {
	fmt.println("Generating PowerPC mnemonic builders from ENCODE_FORMS...")

	// Collect builders grouped by mnemonic. Each mnemonic owns at most a
	// handful of forms; we dedup by full proc name so identical signatures
	// collapse to one overload.
	procs_by_mnemonic: map[ppc.Mnemonic][dynamic]Proc_Entry
	defer {
		for _, v in procs_by_mnemonic { delete(v) }
		delete(procs_by_mnemonic)
	}

	seen_proc_names: map[string]bool
	defer delete(seen_proc_names)

	skipped_ops: map[ppc.Operand_Type]int // operand types we could not build
	defer delete(skipped_ops)

	for m in ppc.Mnemonic {
		if m == .INVALID { continue }

		_run := ppc.ENCODE_RUNS[u16(m)]
		forms := ppc.ENCODE_FORMS[_run.start:][:_run.count]
		if len(forms) == 0 { continue }

		for form in forms {
			entry: Proc_Entry
			entry.mnemonic = m

			ok := true
			for op in form.ops {
				if op == .NONE { continue }
				if !can_build_operand(op) {
					skipped_ops[op] += 1
					ok = false
					break
				}
				entry.ops[entry.count] = op
				entry.count += 1
			}
			if !ok { continue }

			entry.proc_name = make_proc_name(m, entry.ops[:entry.count])

			if entry.proc_name in seen_proc_names { continue }
			seen_proc_names[entry.proc_name] = true

			if m not_in procs_by_mnemonic {
				procs_by_mnemonic[m] = make([dynamic]Proc_Entry)
			}
			append(&procs_by_mnemonic[m], entry)
		}
	}

	// Stable, deterministic mnemonic order (enum order).
	mnemonic_list: [dynamic]ppc.Mnemonic
	defer delete(mnemonic_list)
	for m in procs_by_mnemonic { append(&mnemonic_list, m) }
	slice.sort_by(mnemonic_list[:], proc(a, b: ppc.Mnemonic) -> bool {
		return int(a) < int(b)
	})

	max_name_padding := 0
	for m in mnemonic_list {
		for entry in procs_by_mnemonic[m] {
			max_name_padding = max(max_name_padding, len(entry.proc_name))
		}
	}

	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)

	generate_header(&sb)

	strings.write_string(&sb, `// =============================================================================
// Individual Typed Builder Procedures
// =============================================================================

`)

	for m in mnemonic_list {
		procs := procs_by_mnemonic[m]
		for entry in procs {
			generate_inst_proc(&sb, entry, max_name_padding)
		}
		for entry in procs {
			generate_emit_proc(&sb, entry, max_name_padding)
		}
	}

	strings.write_string(&sb, `
// =============================================================================
// Overload Groups
// =============================================================================

`)

	for m in mnemonic_list {
		procs := procs_by_mnemonic[m]
		if len(procs) == 0 { continue }
		generate_overload_group(&sb, m, procs[:], max_name_padding)
	}

	output := strings.to_string(sb)
	full := strings.concatenate({GEN_ATTRIB, output})
	defer delete(full)

	err := os.write_entire_file(OUTPUT_PATH, transmute([]u8)full)
	if err == nil {
		total_procs := 0
		for m in mnemonic_list { total_procs += len(procs_by_mnemonic[m]) }
		fmt.printf("Generated %s\n", OUTPUT_PATH)
		fmt.printf("  mnemonics with builders: %d\n", len(mnemonic_list))
		fmt.printf("  total builder procs:     %d\n", total_procs)
		if len(skipped_ops) > 0 {
			fmt.println("  skipped operand types (could not build):")
			for ot, n in skipped_ops {
				fmt.printf("    %-14v %d form(s)\n", ot, n)
			}
		} else {
			fmt.println("  skipped operand types: none")
		}
	} else {
		fmt.eprintf("FAILED to write %s\n", OUTPUT_PATH)
		os.exit(1)
	}
}

// -----------------------------------------------------------------------------
// Operand classification
// -----------------------------------------------------------------------------

// Every PowerPC Operand_Type is constructible with the generic op_* helpers,
// so this is always true today; it stays as a guard so unexpected future
// operand types are skipped (and reported) rather than emitting broken code.
can_build_operand :: proc(op: ppc.Operand_Type) -> bool {
	#partial switch op {
	case .GPR, .GPR_OR_ZERO, .FPR, .VR, .VSR, .VR128, .CR_FIELD, .CR_BIT, .SPR:
		return true
	case .IMM, .SIMM, .UIMM:
		return true
	case .REL:
		return true
	case .MEM:
		return true
	case .BO, .BH:
		return true
	}
	return false
}

// Operand category drives parameter naming and the op_* constructor used.
Op_Cat :: enum { REG, IMM, REL, MEM }

op_category :: proc(op: ppc.Operand_Type) -> Op_Cat {
	#partial switch op {
	case .IMM, .SIMM, .UIMM, .BO, .BH:
		return .IMM
	case .REL:
		return .REL
	case .MEM:
		return .MEM
	case:
		return .REG // all register classes (incl. CR_BIT carried as Register)
	}
}

// Short suffix used in the generated procedure name.
op_suffix :: proc(op: ppc.Operand_Type) -> string {
	#partial switch op {
	case .GPR:         return "r"
	case .GPR_OR_ZERO: return "rz"
	case .FPR:         return "fr"
	case .VR:          return "v"
	case .VSR:         return "vs"
	case .VR128:       return "vr128"
	case .CR_FIELD:    return "crf"
	case .CR_BIT:      return "crb"
	case .SPR:         return "spr"
	case .IMM:         return "imm"
	case .SIMM:        return "simm"
	case .UIMM:        return "uimm"
	case .REL:         return "rel"
	case .MEM:         return "mem"
	case .BO:          return "bo"
	case .BH:          return "bh"
	}
	return "unk"
}

// Odin parameter type for the operand.
op_param_type :: proc(op: ppc.Operand_Type) -> string {
	switch op_category(op) {
	case .REG: return "Register"
	case .IMM: return "i64"
	case .REL: return "u32"     // label id (resolved via op_label)
	case .MEM: return "Memory"
	}
	return "Register"
}

// op_* expression that wraps a parameter into an Operand.
write_op_expr :: proc(sb: ^strings.Builder, op: ppc.Operand_Type, name: string) {
	switch op_category(op) {
	case .REG: fmt.sbprintf(sb, "op_reg(%s)", name)
	case .IMM: fmt.sbprintf(sb, "op_imm(%s)", name)
	case .REL: fmt.sbprintf(sb, "op_label(%s)", name)
	case .MEM: fmt.sbprintf(sb, "op_mem(%s)", name)
	}
}

// -----------------------------------------------------------------------------
// Names
// -----------------------------------------------------------------------------

mnemonic_to_lower :: proc(m: ppc.Mnemonic) -> string {
	name := fmt.tprintf("%v", m)
	return strings.to_lower(name)
}

make_proc_name :: proc(m: ppc.Mnemonic, ops: []ppc.Operand_Type) -> string {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)

	strings.write_string(&sb, "inst_")
	strings.write_string(&sb, mnemonic_to_lower(m))

	if len(ops) == 0 {
		strings.write_string(&sb, "_none")
	} else {
		for op in ops {
			strings.write_byte(&sb, '_')
			strings.write_string(&sb, op_suffix(op))
		}
	}
	return strings.clone(strings.to_string(sb))
}

// Per-form parameter names. Guaranteed unique within a form: registers are
// dst/src/src2/...; immediates imm/imm2/...; rel offset; mem addr; bo/bh fields.
// An index suffix is always appended on the rare collision to stay safe.
param_names :: proc(ops: []ppc.Operand_Type) -> [4]string {
	result: [4]string
	used: map[string]bool
	defer delete(used)

	reg_n, imm_n, rel_n, mem_n := 0, 0, 0, 0

	for op, i in ops {
		base: string
		#partial switch op {
		case .BO:   base = "bo"
		case .BH:   base = "bh"
		case:
			switch op_category(op) {
			case .REG:
				if reg_n == 0 { base = "dst" }
				else if reg_n == 1 { base = "src" }
				else { base = fmt.tprintf("src%d", reg_n) }
				reg_n += 1
			case .IMM:
				if imm_n == 0 { base = "imm" }
				else { base = fmt.tprintf("imm%d", imm_n + 1) }
				imm_n += 1
			case .REL:
				if rel_n == 0 { base = "label" }
				else { base = fmt.tprintf("label%d", rel_n + 1) }
				rel_n += 1
			case .MEM:
				if mem_n == 0 { base = "addr" }
				else { base = fmt.tprintf("addr%d", mem_n + 1) }
				mem_n += 1
			}
		}

		name := base
		if name in used {
			name = fmt.tprintf("%s_%d", base, i)
		}
		used[name] = true
		result[i] = name
	}
	return result
}

// -----------------------------------------------------------------------------
// Emit code
// -----------------------------------------------------------------------------

generate_header :: proc(sb: ^strings.Builder) {
	strings.write_string(sb, `package rexcode_ppc

// =============================================================================
// GENERATED FILE - DO NOT EDIT
// =============================================================================
//
// Generated by tools/gen_mnemonic_builders.odin from ENCODE_FORMS.
// Regenerate with: odin run ppc/tools/gen_mnemonic_builders.odin -file
//
// Typed mnemonic builder procedures with overloading. Each mnemonic exposes
// inst_<mnemonic> (returns an Instruction) and emit_<mnemonic> (appends to a
// [dynamic]Instruction) overload sets, one variant per encode form.
//
// NOTE: PowerPC has no typed register enums; register operands of every class
// (GPR/FPR/VR/VSR/VR128/CR field and bit/SPR) take the generic Register type.

`)
}

// inst_<mnem>_<suffix> :: #force_inline proc "contextless" (params) -> Instruction { return Instruction{...} }
generate_inst_proc :: proc(sb: ^strings.Builder, entry: Proc_Entry, pad: int) {
	ops := entry.ops
	names := param_names(ops[:entry.count])
	mnem := fmt.aprintf("%v", entry.mnemonic)
	defer delete(mnem)

	strings.write_string(sb, entry.proc_name)
	for n := pad - len(entry.proc_name); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	strings.write_string(sb, " :: #force_inline proc \"contextless\" (")
	write_params(sb, entry, names)
	strings.write_string(sb, ") -> Instruction { return ")
	write_instruction_literal(sb, entry, names, mnem)
	strings.write_string(sb, " }\n")
}

// emit_<mnem>_<suffix> :: #force_inline proc(instructions, params) { append(instructions, inst_<...>(args)) }
generate_emit_proc :: proc(sb: ^strings.Builder, entry: Proc_Entry, pad: int) {
	ops := entry.ops
	names := param_names(ops[:entry.count])
	emit_name := strings.concatenate({"emit_", entry.proc_name[5:]})
	defer delete(emit_name)

	strings.write_string(sb, emit_name)
	for n := pad - len(entry.proc_name); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	strings.write_string(sb, " :: #force_inline proc(instructions: ^[dynamic]Instruction")
	for i in 0..<entry.count {
		strings.write_string(sb, ", ")
		strings.write_string(sb, names[i])
		strings.write_string(sb, ": ")
		strings.write_string(sb, op_param_type(entry.ops[i]))
	}
	strings.write_string(sb, ") { append(instructions, ")
	strings.write_string(sb, entry.proc_name)
	strings.write_string(sb, "(")
	for i in 0..<entry.count {
		if i > 0 { strings.write_string(sb, ", ") }
		strings.write_string(sb, names[i])
	}
	strings.write_string(sb, ")) }\n")
}

write_params :: proc(sb: ^strings.Builder, entry: Proc_Entry, names: [4]string) {
	for i in 0..<entry.count {
		if i > 0 { strings.write_string(sb, ", ") }
		strings.write_string(sb, names[i])
		strings.write_string(sb, ": ")
		strings.write_string(sb, op_param_type(entry.ops[i]))
	}
}

write_instruction_literal :: proc(sb: ^strings.Builder, entry: Proc_Entry, names: [4]string, mnem: string) {
	strings.write_string(sb, "Instruction{mnemonic = .")
	strings.write_string(sb, mnem)
	fmt.sbprintf(sb, ", operand_count = %d, length = 4, ops = {{", entry.count)
	for i in 0..<4 {
		if i > 0 { strings.write_string(sb, ", ") }
		if i < entry.count {
			write_op_expr(sb, entry.ops[i], names[i])
		} else {
			strings.write_string(sb, "{}")
		}
	}
	strings.write_string(sb, "}}")
}

generate_overload_group :: proc(sb: ^strings.Builder, m: ppc.Mnemonic, procs: []Proc_Entry, pad: int) {
	lower := mnemonic_to_lower(m)

	// inst_<mnem>
	strings.write_string(sb, "inst_")
	strings.write_string(sb, lower)
	for n := pad - len(lower); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	if len(procs) == 1 {
		strings.write_string(sb, " :: ")
		strings.write_string(sb, procs[0].proc_name)
		strings.write_byte(sb, '\n')
	} else {
		strings.write_string(sb, " :: proc{ ")
		for entry, i in procs {
			if i > 0 { strings.write_string(sb, ", ") }
			strings.write_string(sb, entry.proc_name)
		}
		strings.write_string(sb, " }\n")
	}

	// emit_<mnem>
	strings.write_string(sb, "emit_")
	strings.write_string(sb, lower)
	for n := pad - len(lower); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	if len(procs) == 1 {
		emit_name := strings.concatenate({"emit_", procs[0].proc_name[5:]})
		defer delete(emit_name)
		strings.write_string(sb, " :: ")
		strings.write_string(sb, emit_name)
		strings.write_byte(sb, '\n')
	} else {
		strings.write_string(sb, " :: proc{ ")
		for entry, i in procs {
			if i > 0 { strings.write_string(sb, ", ") }
			emit_name := strings.concatenate({"emit_", entry.proc_name[5:]})
			defer delete(emit_name)
			strings.write_string(sb, emit_name)
		}
		strings.write_string(sb, " }\n")
	}
}
