// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package main

// =============================================================================
// RSP Mnemonic Builder Generator
// =============================================================================
//
// Generates rsp/mnemonic_builders.odin by iterating the encoder's flattened
// encode forms (ENCODE_RUNS + ENCODE_FORMS) and emitting typed builder
// procedures with overloading for each mnemonic, mirroring the structure of
// x86/tools/gen_mnemonic_builders.odin.
//
// For each mnemonic, every encode form's operand list (form.ops) becomes one
// builder:
//   inst_<mnem>_<suffixes>(...)  -> Instruction          (pure constructor)
//   emit_<mnem>_<suffixes>(...)                           (append helper)
// then grouped into overload sets `inst_<mnem>` / `emit_<mnem>`.
//
// Run with: odin run rsp/tools/gen_mnemonic_builders.odin -file
// Output:   rsp/mnemonic_builders.odin
//
// Operand-type mapping (RSP Operand_Type -> param type / op_ expr):
//   .GPR      Register        op_reg(x)
//   .VR       Register        op_vr(x)
//   .VR_ELEM  Register (+ u8) op_vr(x, element)     (extra `element: u8 = 0` param)
//   .CP0_REG  Register        op_reg(x)
//   .CP2_CTRL Register        op_reg(x)
//   .IMM5     i64             op_imm(x, 1)
//   .IMM16S   i64             op_imm(x, 2)
//   .IMM16U   i64             op_imm(x, 2)
//   .IMM20    i64             op_imm(x, 4)
//   .IMM26    i64             op_imm(x, 4)   (not present in current forms)
//   .REL16    u32             op_label(x)    (label id)
//   .REL_J26  u32             op_label(x)    (label id)
//   .MEM      Memory          op_mem(x, 4)
//   .VMEM     Vector_Mem      op_vmem(x, 16)
//
// .NONE operands are skipped. RSP has no purely-implicit operand classes in
// its forms, so nothing else is skipped; should an unmappable operand type
// ever appear, the form is skipped and reported.

import "core:fmt"
import "core:os"
import "core:strings"
import "core:slice"
import rsp "../"

GEN_ATTRIB :: "// rexcode  ·  Brendan Punsky (dotbmp@github), original author\n\n"

// One operand slot in a builder signature.
Operand_Info :: struct {
	op_type: rsp.Operand_Type,
}

// A full builder signature (explicit operands only).
Signature :: struct {
	types: [4]Operand_Info,
	count: int,
}

Proc_Entry :: struct {
	mnemonic:  rsp.Mnemonic,
	sig:       Signature,
	proc_name: string, // "inst_<mnem>_<suffix...>"
}

mnemonic_to_lower :: proc(m: rsp.Mnemonic) -> string {
	return strings.to_lower(fmt.tprintf("%v", m))
}

main :: proc() {
	fmt.println("Generating RSP mnemonic builders from ENCODE_FORMS...")

	sb := strings.builder_make()
	generate_header(&sb)

	procs_by_mnemonic: map[rsp.Mnemonic][dynamic]Proc_Entry
	defer {
		for _, v in procs_by_mnemonic { delete(v) }
		delete(procs_by_mnemonic)
	}

	seen_proc_names: map[string]bool
	defer delete(seen_proc_names)

	skipped: [dynamic]string
	defer delete(skipped)

	for mnemonic in rsp.Mnemonic {
		if mnemonic == .INVALID { continue }

		_run := rsp.ENCODE_RUNS[u16(mnemonic)]
		forms := rsp.ENCODE_FORMS[_run.start:][:_run.count]
		if len(forms) == 0 { continue }

		for form in forms {
			sig, ok := build_signature(form)
			if !ok {
				append(&skipped, fmt.aprintf("%v (unmappable operand)", mnemonic))
				continue
			}

			proc_name := generate_proc_name(mnemonic, sig)
			if proc_name in seen_proc_names { continue }
			seen_proc_names[proc_name] = true

			if mnemonic not_in procs_by_mnemonic {
				procs_by_mnemonic[mnemonic] = make([dynamic]Proc_Entry)
			}
			append(&procs_by_mnemonic[mnemonic], Proc_Entry{
				mnemonic  = mnemonic,
				sig       = sig,
				proc_name = proc_name,
			})
		}
	}

	// Sort mnemonics by enum order for stable output.
	mnemonic_list: [dynamic]rsp.Mnemonic
	defer delete(mnemonic_list)
	for m in procs_by_mnemonic { append(&mnemonic_list, m) }
	slice.sort_by(mnemonic_list[:], proc(a, b: rsp.Mnemonic) -> bool {
		return int(a) < int(b)
	})

	// Column padding for tidy output.
	max_name_padding := 0
	for mnemonic in mnemonic_list {
		for entry in procs_by_mnemonic[mnemonic] {
			max_name_padding = max(max_name_padding, len(entry.proc_name))
		}
	}

	strings.write_string(&sb, `// =============================================================================
// Individual Typed Builder Procedures
// =============================================================================

`)
	for mnemonic in mnemonic_list {
		procs := procs_by_mnemonic[mnemonic]
		for entry in procs { generate_inst_proc(&sb, entry, max_name_padding) }
		for entry in procs { generate_emit_proc(&sb, entry, max_name_padding) }
	}

	strings.write_string(&sb, `
// =============================================================================
// Overload Groups
// =============================================================================

`)
	for mnemonic in mnemonic_list {
		procs := procs_by_mnemonic[mnemonic]
		if len(procs) == 0 { continue }
		generate_overload_group(&sb, mnemonic, procs, max_name_padding)
	}

	total_procs := 0
	for m in mnemonic_list { total_procs += len(procs_by_mnemonic[m]) }

	output := strings.to_string(sb)
	path := #directory + "/../mnemonic_builders.odin"
	if err := os.write_entire_file(path, transmute([]u8)strings.concatenate({GEN_ATTRIB, output})); err == nil {
		fmt.println("Generated mnemonic_builders.odin successfully!")
		fmt.printfln("Total mnemonics with builders: %d", len(mnemonic_list))
		fmt.printfln("Total procedures generated:     %d", total_procs)
		if len(skipped) > 0 {
			fmt.printfln("Skipped %d form(s):", len(skipped))
			for s in skipped { fmt.printfln("  - %s", s) }
		}
	} else {
		fmt.eprintfln("Failed to write %s: %v", path, err)
		os.exit(1)
	}
}

// -----------------------------------------------------------------------------
// Signature construction
// -----------------------------------------------------------------------------

build_signature :: proc(form: rsp.Encoding) -> (sig: Signature, ok: bool) {
	for op in form.ops {
		if op == .NONE { continue }
		if !can_map_operand(op) { return {}, false }
		sig.types[sig.count] = Operand_Info{op_type = op}
		sig.count += 1
	}
	return sig, true
}

can_map_operand :: proc(op: rsp.Operand_Type) -> bool {
	#partial switch op {
	case .GPR, .VR, .VR_ELEM, .CP0_REG, .CP2_CTRL,
	     .IMM5, .IMM16S, .IMM16U, .IMM20, .IMM26,
	     .REL16, .REL_J26, .MEM, .VMEM:
		return true
	}
	return false
}

// -----------------------------------------------------------------------------
// Naming
// -----------------------------------------------------------------------------

generate_proc_name :: proc(mnemonic: rsp.Mnemonic, sig: Signature) -> string {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)

	strings.write_string(&sb, "inst_")
	strings.write_string(&sb, mnemonic_to_lower(mnemonic))

	if sig.count == 0 {
		strings.write_string(&sb, "_none")
	} else {
		for i in 0..<sig.count {
			strings.write_byte(&sb, '_')
			strings.write_string(&sb, operand_suffix(sig.types[i].op_type))
		}
	}
	return strings.clone(strings.to_string(sb))
}

operand_suffix :: proc(op: rsp.Operand_Type) -> string {
	#partial switch op {
	case .GPR:      return "gpr"
	case .VR:       return "vr"
	case .VR_ELEM:  return "vr"
	case .CP0_REG:  return "cp0"
	case .CP2_CTRL: return "cp2"
	case .IMM5:     return "imm5"
	case .IMM16S:   return "imm16"
	case .IMM16U:   return "imm16"
	case .IMM20:    return "imm20"
	case .IMM26:    return "imm26"
	case .REL16:    return "rel"
	case .REL_J26:  return "rel"
	case .MEM:      return "mem"
	case .VMEM:     return "vmem"
	}
	return "unk"
}

// -----------------------------------------------------------------------------
// Operand -> Odin parameter type
// -----------------------------------------------------------------------------

operand_odin_type :: proc(op: rsp.Operand_Type) -> string {
	#partial switch op {
	case .GPR, .VR, .VR_ELEM, .CP0_REG, .CP2_CTRL: return "Register"
	case .IMM5, .IMM16S, .IMM16U, .IMM20, .IMM26:  return "i64"
	case .REL16, .REL_J26:                         return "u32"
	case .MEM:                                     return "Memory"
	case .VMEM:                                    return "Vector_Mem"
	}
	return "unknown"
}

// -----------------------------------------------------------------------------
// Parameter naming (unique within a signature)
// -----------------------------------------------------------------------------

Param :: struct {
	name: string,
	type: string,
	op:   rsp.Operand_Type,
}

// Builds the parameter list for a signature. Returns the params plus the name
// of the trailing element parameter (empty if none). VR_ELEM gets an extra
// `element: u8 = 0` parameter appended (at most one such operand per form).
build_params :: proc(sig: Signature) -> (params: [dynamic]Param, element_name: string) {
	reg_idx := 0
	imm_idx := 0
	has_elem := false

	for i in 0..<sig.count {
		op := sig.types[i].op_type
		p: Param
		p.op = op
		p.type = operand_odin_type(op)

		#partial switch op {
		case .IMM5, .IMM16S, .IMM16U, .IMM20, .IMM26:
			p.name = imm_idx == 0 ? "imm" : fmt.aprintf("imm%d", imm_idx + 1)
			imm_idx += 1
		case .REL16, .REL_J26:
			p.name = "label_id"
		case .MEM:
			p.name = "m"
		case .VMEM:
			p.name = "m"
		case:
			// register-family operand
			if reg_idx == 0 {
				p.name = "a"
			} else {
				p.name = fmt.aprintf("%c", rune('a' + reg_idx))
			}
			reg_idx += 1
		}

		append(&params, p)
		if op == .VR_ELEM { has_elem = true }
	}

	if has_elem {
		element_name = "element"
		append(&params, Param{name = element_name, type = "u8", op = .NONE})
	}
	return
}

// -----------------------------------------------------------------------------
// op_ expression for one operand
// -----------------------------------------------------------------------------

write_operand_expr :: proc(sb: ^strings.Builder, op: rsp.Operand_Type, name: string, element_name: string) {
	#partial switch op {
	case .GPR, .CP0_REG, .CP2_CTRL:
		fmt.sbprintf(sb, "op_reg(%s)", name)
	case .VR:
		fmt.sbprintf(sb, "op_vr(%s)", name)
	case .VR_ELEM:
		fmt.sbprintf(sb, "op_vr(%s, %s)", name, element_name)
	case .IMM5:
		fmt.sbprintf(sb, "op_imm(%s, 1)", name)
	case .IMM16S, .IMM16U:
		fmt.sbprintf(sb, "op_imm(%s, 2)", name)
	case .IMM20, .IMM26:
		fmt.sbprintf(sb, "op_imm(%s, 4)", name)
	case .REL16, .REL_J26:
		fmt.sbprintf(sb, "op_label(%s)", name)
	case .MEM:
		fmt.sbprintf(sb, "op_mem(%s, 4)", name)
	case .VMEM:
		fmt.sbprintf(sb, "op_vmem(%s, 16)", name)
	case:
		strings.write_string(sb, "{}")
	}
}

// -----------------------------------------------------------------------------
// Procedure emission
// -----------------------------------------------------------------------------

write_param_list :: proc(sb: ^strings.Builder, params: []Param) {
	for p, i in params {
		if i > 0 { strings.write_string(sb, ", ") }
		strings.write_string(sb, p.name)
		strings.write_string(sb, ": ")
		strings.write_string(sb, p.type)
		if p.op == .NONE && p.type == "u8" {
			// trailing element selector defaults to 0
			strings.write_string(sb, " = 0")
		}
	}
}

write_ops_literal :: proc(sb: ^strings.Builder, sig: Signature, params: []Param, element_name: string) {
	strings.write_string(sb, "{")
	// Map explicit operands to their op_ expressions; pad the rest with {}.
	for i in 0..<4 {
		if i > 0 { strings.write_string(sb, ", ") }
		if i < sig.count {
			op := sig.types[i].op_type
			write_operand_expr(sb, op, params[i].name, element_name)
		} else {
			strings.write_string(sb, "{}")
		}
	}
	strings.write_string(sb, "}")
}

generate_inst_proc :: proc(sb: ^strings.Builder, entry: Proc_Entry, pad: int) {
	params, element_name := build_params(entry.sig)
	defer delete(params)

	mnem := fmt.aprintf("%v", entry.mnemonic)
	defer delete(mnem)

	strings.write_string(sb, entry.proc_name)
	for n := pad - len(entry.proc_name); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	strings.write_string(sb, " :: #force_inline proc \"contextless\" (")
	write_param_list(sb, params[:])
	strings.write_string(sb, ") -> Instruction { return Instruction{ mnemonic = .")
	strings.write_string(sb, mnem)
	fmt.sbprintf(sb, ", operand_count = %d, length = 4, ops = ", entry.sig.count)
	write_ops_literal(sb, entry.sig, params[:], element_name)
	strings.write_string(sb, " } }\n")
}

generate_emit_proc :: proc(sb: ^strings.Builder, entry: Proc_Entry, pad: int) {
	params, _ := build_params(entry.sig)
	defer delete(params)

	emit_name := strings.concatenate({"emit_", entry.proc_name[5:]})
	defer delete(emit_name)

	strings.write_string(sb, emit_name)
	for n := pad - len(entry.proc_name); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	strings.write_string(sb, " :: #force_inline proc(instructions: ^[dynamic]Instruction")
	for p in params {
		strings.write_string(sb, ", ")
		strings.write_string(sb, p.name)
		strings.write_string(sb, ": ")
		strings.write_string(sb, p.type)
		if p.op == .NONE && p.type == "u8" {
			strings.write_string(sb, " = 0")
		}
	}
	strings.write_string(sb, ") { append(instructions, ")
	strings.write_string(sb, entry.proc_name)
	strings.write_string(sb, "(")
	for p, i in params {
		if i > 0 { strings.write_string(sb, ", ") }
		strings.write_string(sb, p.name)
	}
	strings.write_string(sb, ")) }\n")
}

generate_overload_group :: proc(sb: ^strings.Builder, mnemonic: rsp.Mnemonic, procs: [dynamic]Proc_Entry, pad: int) {
	mnem_lower := mnemonic_to_lower(mnemonic)

	// inst_<mnem> :: ...
	strings.write_string(sb, "inst_")
	strings.write_string(sb, mnem_lower)
	for n := pad - len(mnem_lower); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	if len(procs) == 1 {
		strings.write_string(sb, " :: ")
		strings.write_string(sb, procs[0].proc_name)
		strings.write_string(sb, "\n")
	} else {
		strings.write_string(sb, " :: proc{ ")
		for entry, i in procs {
			if i > 0 { strings.write_string(sb, ", ") }
			strings.write_string(sb, entry.proc_name)
		}
		strings.write_string(sb, " }\n")
	}

	// emit_<mnem> :: ...
	strings.write_string(sb, "emit_")
	strings.write_string(sb, mnem_lower)
	for n := pad - len(mnem_lower); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	if len(procs) == 1 {
		emit_name := strings.concatenate({"emit_", procs[0].proc_name[5:]})
		defer delete(emit_name)
		strings.write_string(sb, " :: ")
		strings.write_string(sb, emit_name)
		strings.write_string(sb, "\n")
	} else {
		strings.write_string(sb, " :: proc{ ")
		for entry, i in procs {
			if i > 0 { strings.write_string(sb, ", ") }
			emit_name := strings.concatenate({"emit_", entry.proc_name[5:]})
			strings.write_string(sb, emit_name)
			delete(emit_name)
		}
		strings.write_string(sb, " }\n")
	}
}

// -----------------------------------------------------------------------------
// File header
// -----------------------------------------------------------------------------

generate_header :: proc(sb: ^strings.Builder) {
	strings.write_string(sb, `package rexcode_rsp

// =============================================================================
// GENERATED FILE - DO NOT EDIT
// =============================================================================
//
// Generated by tools/gen_mnemonic_builders.odin from ENCODE_FORMS.
// Regenerate with: odin run rsp/tools/gen_mnemonic_builders.odin -file
//
// This file provides typed mnemonic builder procedures with overloading.
// Each mnemonic has an inst_<mnem> constructor (returns an Instruction) and an
// emit_<mnem> helper (appends to a ^[dynamic]Instruction). Vector operands with
// an element selector (.VR_ELEM) take a trailing 'element: u8 = 0' parameter.

`)
}
