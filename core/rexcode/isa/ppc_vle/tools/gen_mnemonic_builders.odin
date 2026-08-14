// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package main

// =============================================================================
// Mnemonic Builder Generator  (ppc_vle)
// =============================================================================
//
// Generates mnemonic_builders.odin by iterating the encoder's flattened encode
// forms (ENCODE_FORMS, indexed per-mnemonic via ENCODE_RUNS) and emitting typed
// builder procedures with overloading for each mnemonic.
//
// For every encode form of a mnemonic we build an operand signature from
// `form.ops` (skipping .NONE), map each operand type to a parameter type +
// an `op_*` constructor expression, then emit:
//
//     inst_<mnem>_<suffix>  -> returns an Instruction
//     emit_<mnem>_<suffix>  -> appends inst_<...>(...) onto a ^[dynamic]Instruction
//
// Builders are deduplicated by name and grouped into overload sets:
//
//     inst_<mnem> :: proc{ ... }
//     emit_<mnem> :: proc{ ... }
//
// ppc_vle has a single generic `Register` type (no typed register enums), so all
// register classes map to `Register`. Immediates map to `i64`, memory to
// `Memory`, branch targets (REL) to a `u32` label id.
//
// Run with: odin run tools/gen_mnemonic_builders.odin -file
// Output:   mnemonic_builders.odin (written to current directory, move to package root)

import "core:fmt"
import "core:os"
import "core:strings"
import "core:slice"
import vle "../"

GEN_ATTRIB :: "// rexcode  ·  Brendan Punsky (dotbmp@github), original author\n\n"

// Operand signature for a specific encode form.
Operand_Signature :: struct {
	types: [4]vle.Operand_Type,
	count: int,
}

// Collected procedure to generate.
Proc_Entry :: struct {
	mnemonic:  vle.Mnemonic,
	sig:       Operand_Signature,
	form_id:   u16,   // 1-based index into the mnemonic's ENCODE_FORMS run
	length:    u8,    // 2 for short (16-bit) forms, 4 for long (32-bit)
	proc_name: string,
}

mnemonic_to_lower :: proc(m: vle.Mnemonic) -> string {
	name := fmt.tprintf("%v", m)
	return strings.to_lower(name)
}

main :: proc() {
	fmt.println("Generating ppc_vle mnemonic builders from ENCODE_FORMS...")

	sb := strings.builder_make()

	generate_header(&sb)

	procs_by_mnemonic: map[vle.Mnemonic][dynamic]Proc_Entry
	defer {
		for _, v in procs_by_mnemonic { delete(v) }
		delete(procs_by_mnemonic)
	}

	// Dedup on generated procedure name.
	seen_proc_names: map[string]bool
	defer delete(seen_proc_names)

	skipped: [dynamic]string
	defer delete(skipped)

	for mnemonic in vle.Mnemonic {
		if mnemonic == .INVALID { continue }

		_run := vle.ENCODE_RUNS[u16(mnemonic)]
		forms := vle.ENCODE_FORMS[_run.start:][:_run.count]
		if len(forms) == 0 { continue }

		for form, form_idx in forms {
			sig: Operand_Signature
			valid := true

			for op in form.ops {
				if op == .NONE { continue }
				if !can_generate_operand(op) {
					valid = false
					append(&skipped, fmt.aprintf("%v (operand %v)", mnemonic, op))
					break
				}
				sig.types[sig.count] = op
				sig.count += 1
			}

			if !valid { continue }

			length: u8 = 4
			if form.flags.short { length = 2 }

			proc_name := generate_proc_name(mnemonic, sig)
			if proc_name in seen_proc_names { continue }
			seen_proc_names[proc_name] = true

			entry := Proc_Entry{
				mnemonic  = mnemonic,
				sig       = sig,
				form_id   = u16(form_idx + 1),
				length    = length,
				proc_name = proc_name,
			}

			if mnemonic not_in procs_by_mnemonic {
				procs_by_mnemonic[mnemonic] = make([dynamic]Proc_Entry)
			}
			append(&procs_by_mnemonic[mnemonic], entry)
		}
	}

	// Individual procedures.
	strings.write_string(&sb, `// =============================================================================
// Individual Typed Builder Procedures
// =============================================================================

`)

	mnemonic_list: [dynamic]vle.Mnemonic
	defer delete(mnemonic_list)
	for m in procs_by_mnemonic { append(&mnemonic_list, m) }
	slice.sort_by(mnemonic_list[:], proc(a, b: vle.Mnemonic) -> bool {
		return int(a) < int(b)
	})

	max_name_padding := 0
	for mnemonic in mnemonic_list {
		for entry in procs_by_mnemonic[mnemonic] {
			max_name_padding = max(max_name_padding, len(entry.proc_name))
		}
	}

	for mnemonic in mnemonic_list {
		procs := procs_by_mnemonic[mnemonic]
		for entry in procs { generate_proc(&sb, entry, max_name_padding) }
		for entry in procs { generate_emit_proc(&sb, entry, max_name_padding) }
	}

	// Overload groups.
	strings.write_string(&sb, `
// =============================================================================
// Overload Groups
// =============================================================================

`)

	for mnemonic in mnemonic_list {
		procs := procs_by_mnemonic[mnemonic]
		if len(procs) == 0 { continue }

		mnemonic_lower := mnemonic_to_lower(mnemonic)

		// inst_ group
		strings.write_string(&sb, "inst_")
		strings.write_string(&sb, mnemonic_lower)
		for n := max_name_padding - len(mnemonic_lower); n > 0; n -= 1 {
			strings.write_byte(&sb, ' ')
		}
		if len(procs) == 1 {
			strings.write_string(&sb, " :: ")
			strings.write_string(&sb, procs[0].proc_name)
			strings.write_string(&sb, "\n")
		} else {
			strings.write_string(&sb, " :: proc{ ")
			for entry, i in procs {
				if i > 0 { strings.write_string(&sb, ", ") }
				strings.write_string(&sb, entry.proc_name)
			}
			strings.write_string(&sb, " }\n")
		}

		// emit_ group
		strings.write_string(&sb, "emit_")
		strings.write_string(&sb, mnemonic_lower)
		for n := max_name_padding - len(mnemonic_lower); n > 0; n -= 1 {
			strings.write_byte(&sb, ' ')
		}
		if len(procs) == 1 {
			emit_name := strings.concatenate({"emit_", procs[0].proc_name[5:]})
			strings.write_string(&sb, " :: ")
			strings.write_string(&sb, emit_name)
			strings.write_string(&sb, "\n")
		} else {
			strings.write_string(&sb, " :: proc{ ")
			for entry, i in procs {
				if i > 0 { strings.write_string(&sb, ", ") }
				emit_name := strings.concatenate({"emit_", entry.proc_name[5:]})
				strings.write_string(&sb, emit_name)
			}
			strings.write_string(&sb, " }\n")
		}
	}

	output := strings.to_string(sb)

	err := os.write_entire_file(#directory + "/../mnemonic_builders.odin", transmute([]u8)strings.concatenate({GEN_ATTRIB, output}))
	if err == nil {
		fmt.println("Generated mnemonic_builders.odin successfully!")
		fmt.printf("Total mnemonics with builders: %d\n", len(mnemonic_list))
		total := 0
		for m in mnemonic_list { total += len(procs_by_mnemonic[m]) }
		fmt.printf("Total procedures generated: %d\n", total)
		if len(skipped) > 0 {
			fmt.printf("Skipped %d form(s) (unconstructible operands):\n", len(skipped))
			for s in skipped { fmt.printf("  - %s\n", s) }
		} else {
			fmt.println("Skipped 0 forms — every operand type was constructible.")
		}
	} else {
		fmt.eprintln("Failed to write mnemonic_builders.odin")
	}
}

generate_header :: proc(sb: ^strings.Builder) {
	strings.write_string(sb, `package rexcode_ppc_vle

// =============================================================================
// GENERATED FILE - DO NOT EDIT
// =============================================================================
//
// Generated by tools/gen_mnemonic_builders.odin from ENCODE_FORMS.
// Regenerate with: odin run ppc_vle/tools/gen_mnemonic_builders.odin -file
//
// This file provides typed mnemonic builder procedures with overloading.
// Each mnemonic maps to an inst_<mnem> (build an Instruction) and an
// emit_<mnem> (append onto a ^[dynamic]Instruction). ppc_vle uses a single
// generic Register type, so all register operands take Register; immediates
// take i64, memory takes Memory, and branch targets take a u32 label id.

`)
}

// All operand types actually produced by the encoder are constructible via the
// op_* helpers, so this currently returns true for every non-NONE operand.
// It exists so unconstructible operands (if any are ever added) are skipped and
// reported rather than producing a broken builder.
can_generate_operand :: proc(op: vle.Operand_Type) -> bool {
	#partial switch op {
	case .GPR, .GPR_VLE16, .GPR_OR_ZERO, .CR_FIELD, .SPR:
		return true            // -> Register, op_reg
	case .CR_BIT, .BO:
		return true            // -> i64, op_imm (encoder accepts imm or reg)
	case .IMM, .SIMM, .UIMM:
		return true            // -> i64, op_imm
	case .MEM:
		return true            // -> Memory, op_mem
	case .REL:
		return true            // -> u32 label id, op_label
	}
	return false
}

// Suffix fragment for the procedure name.
operand_suffix :: proc(op: vle.Operand_Type) -> string {
	#partial switch op {
	case .GPR, .GPR_VLE16, .GPR_OR_ZERO: return "r"
	case .CR_FIELD:                      return "crf"
	case .CR_BIT:                        return "crb"
	case .SPR:                           return "spr"
	case .BO:                            return "bo"
	case .IMM, .SIMM, .UIMM:             return "imm"
	case .MEM:                           return "mem"
	case .REL:                           return "rel"
	}
	return "unk"
}

// Odin parameter type for an operand.
operand_odin_type :: proc(op: vle.Operand_Type) -> string {
	#partial switch op {
	case .GPR, .GPR_VLE16, .GPR_OR_ZERO, .CR_FIELD, .SPR: return "Register"
	case .CR_BIT, .BO, .IMM, .SIMM, .UIMM:                return "i64"
	case .MEM:                                            return "Memory"
	case .REL:                                            return "u32"
	}
	return "rawptr"
}

// op_* constructor expression wrapping the given parameter name.
generate_operand_expr :: proc(sb: ^strings.Builder, op: vle.Operand_Type, param_name: string) {
	#partial switch op {
	case .GPR, .GPR_VLE16, .GPR_OR_ZERO, .CR_FIELD, .SPR:
		fmt.sbprintf(sb, "op_reg(%s)", param_name)
	case .CR_BIT, .BO, .IMM, .SIMM, .UIMM:
		fmt.sbprintf(sb, "op_imm(%s)", param_name)
	case .MEM:
		fmt.sbprintf(sb, "op_mem(%s)", param_name)
	case .REL:
		fmt.sbprintf(sb, "op_label(%s)", param_name)
	case:
		strings.write_string(sb, "{}")
	}
}

// Procedure name (with the inst_ prefix) for a mnemonic + signature.
generate_proc_name :: proc(mnemonic: vle.Mnemonic, sig: Operand_Signature) -> string {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)

	strings.write_string(&sb, "inst_")
	strings.write_string(&sb, mnemonic_to_lower(mnemonic))

	if sig.count == 0 {
		strings.write_string(&sb, "_none")
	} else {
		for i in 0..<sig.count {
			strings.write_string(&sb, "_")
			strings.write_string(&sb, operand_suffix(sig.types[i]))
		}
	}

	return strings.clone(strings.to_string(sb))
}

// Unique, readable parameter names for a signature.
param_names :: proc(sig: Operand_Signature) -> [4]string {
	result: [4]string
	reg_count := 0
	imm_count := 0
	mem_count := 0

	for i in 0..<sig.count {
		op := sig.types[i]
		#partial switch op {
		case .IMM, .SIMM, .UIMM, .CR_BIT, .BO:
			if imm_count == 0 { result[i] = "imm" } else { result[i] = fmt.tprintf("imm%d", imm_count + 1) }
			imm_count += 1
		case .MEM:
			if mem_count == 0 { result[i] = "mem" } else { result[i] = fmt.tprintf("mem%d", mem_count + 1) }
			mem_count += 1
		case .REL:
			result[i] = "target"
		case:
			// Register-class operand.
			if reg_count == 0 { result[i] = "rd" } else { result[i] = fmt.tprintf("r%d", reg_count + 1) }
			reg_count += 1
		}
	}

	return result
}

// Build the parameter list "name: Type, ..." for a signature.
write_params :: proc(sb: ^strings.Builder, sig: Operand_Signature, names: [4]string) {
	for i in 0..<sig.count {
		if i > 0 { strings.write_string(sb, ", ") }
		strings.write_string(sb, names[i])
		strings.write_string(sb, ": ")
		strings.write_string(sb, operand_odin_type(sig.types[i]))
	}
}

// Emit the Instruction{...} literal for an entry.
generate_instruction_literal :: proc(sb: ^strings.Builder, entry: Proc_Entry, names: [4]string) {
	sig := entry.sig

	mnemonic_str := fmt.aprintf("%v", entry.mnemonic)
	defer delete(mnemonic_str)

	ops_sb := strings.builder_make()
	defer strings.builder_destroy(&ops_sb)
	for i in 0..<4 {
		if i > 0 { strings.write_string(&ops_sb, ", ") }
		if i < sig.count {
			generate_operand_expr(&ops_sb, sig.types[i], names[i])
		} else {
			strings.write_string(&ops_sb, "{}")
		}
	}

	fmt.sbprintf(sb,
		"Instruction{{mnemonic = .%s, operand_count = %d, length = %d, mode = .PPC32_VLE, form_id = %d, ops = {{%s}}}}",
		mnemonic_str, sig.count, entry.length, entry.form_id, strings.to_string(ops_sb))
}

// One inst_ procedure (compact one-line).
generate_proc :: proc(sb: ^strings.Builder, entry: Proc_Entry, max_name_padding: int) {
	names := param_names(entry.sig)

	strings.write_string(sb, entry.proc_name)
	for n := max_name_padding - len(entry.proc_name); n > 0; n -= 1 {
		strings.write_byte(sb, ' ')
	}
	strings.write_string(sb, " :: #force_inline proc \"contextless\" (")
	write_params(sb, entry.sig, names)
	strings.write_string(sb, ") -> Instruction { return ")
	generate_instruction_literal(sb, entry, names)
	strings.write_string(sb, " }\n")
}

// One emit_ procedure (compact one-line). Not contextless — append needs context.
generate_emit_proc :: proc(sb: ^strings.Builder, entry: Proc_Entry, max_name_padding: int) {
	names := param_names(entry.sig)

	emit_name := strings.concatenate({"emit_", entry.proc_name[5:]})
	defer delete(emit_name)

	strings.write_string(sb, emit_name)
	for n := max_name_padding - len(entry.proc_name); n > 0; n -= 1 {
		strings.write_byte(sb, ' ')
	}
	strings.write_string(sb, " :: #force_inline proc(instructions: ^[dynamic]Instruction")
	for i in 0..<entry.sig.count {
		strings.write_string(sb, ", ")
		strings.write_string(sb, names[i])
		strings.write_string(sb, ": ")
		strings.write_string(sb, operand_odin_type(entry.sig.types[i]))
	}
	strings.write_string(sb, ") { append(instructions, ")
	strings.write_string(sb, entry.proc_name)
	strings.write_string(sb, "(")
	for i in 0..<entry.sig.count {
		if i > 0 { strings.write_string(sb, ", ") }
		strings.write_string(sb, names[i])
	}
	strings.write_string(sb, ")) }\n")
}
