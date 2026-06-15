// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package main

// =============================================================================
// RISC-V Mnemonic Builder Generator
// =============================================================================
//
// This script generates mnemonic_builders.odin by iterating the encoder's
// ENCODE_RUNS / ENCODE_FORMS tables and creating typed builder procedures with
// overloading for each mnemonic, in the same spirit as x86's generator.
//
// For each mnemonic we walk its encode forms, build an operand signature
// (skipping .NONE), map every operand type to a typed parameter plus an `op_*`
// expression, and emit:
//
//   inst_<mnem>_<suffix>  -> returns an Instruction (built directly)
//   emit_<mnem>_<suffix>  -> appends inst_<...>() to a [dynamic]Instruction
//
// Duplicate signatures are deduplicated; the survivors are grouped into
// `inst_<mnem>` / `emit_<mnem>` overload sets.
//
// RISC-V's operand model maps onto the typed register enums GPR / FPR
// (registers.odin) and the op_* constructors (operands.odin):
//
//   GPR / GPR_C / GPR_SP / GPR_NONZERO  -> GPR    via op_gpr
//   FPR / FPR_C                         -> FPR    via op_fpr
//   IMM* / CSR / ZIMM5 / FENCE_FLAGS    -> i64    via op_imm
//   REL13 / REL21 / REL9 / REL12        -> u32    via op_label  (label id)
//   MEM  / MEM_C_*                      -> Memory via op_mem
//
// Run with: odin run riscv/tools/gen_mnemonic_builders.odin -file
//
// Output: mnemonic_builders.odin (written to current directory; move to the
// riscv package root).

import "core:fmt"
import "core:os"
import "core:strings"
import "core:slice"
import rv "../"

GEN_ATTRIB :: "// rexcode  ·  Brendan Punsky (dotbmp@github), original author\n\n"

// -----------------------------------------------------------------------------
// Collected data
// -----------------------------------------------------------------------------

// One operand of a signature.
Operand_Info :: struct {
	op_type: rv.Operand_Type,
}

// Operand signature for one builder variant.
Operand_Signature :: struct {
	types: [4]Operand_Info,
	count: int,
}

// A procedure to generate.
Proc_Entry :: struct {
	mnemonic:  rv.Mnemonic,
	sig:       Operand_Signature,
	proc_name: string, // includes the "inst_" prefix
	length:    u8,     // 2 (compressed) or 4 (base)
}

// -----------------------------------------------------------------------------
// Mnemonic name helpers
// -----------------------------------------------------------------------------

// Lowercase the enum identifier (FENCE_I -> fence_i, C_ADDI -> c_addi).
// This is purely for the *generated identifier*; it keeps the underscores
// rather than the canonical dotted assembly spelling so the result is a valid
// Odin identifier.
mnemonic_to_lower :: proc(m: rv.Mnemonic) -> string {
	name := fmt.tprintf("%v", m)
	return strings.to_lower(name)
}

// -----------------------------------------------------------------------------
// Operand classification
// -----------------------------------------------------------------------------

Operand_Class :: enum {
	GPR,
	FPR,
	IMM,
	LABEL,
	MEM,
	SKIP, // not cleanly constructible
}

classify :: proc(op: rv.Operand_Type) -> Operand_Class {
	#partial switch op {
	case .GPR, .GPR_C, .GPR_SP, .GPR_NONZERO:
		return .GPR
	case .FPR, .FPR_C:
		return .FPR
	case .IMM12, .IMM12U, .IMM5, .IMM6, .IMM20,
		 .CSR, .ZIMM5, .FENCE_FLAGS,
		 .IMM_C6S, .IMM_C6U, .IMM_C8U, .IMM_C10S, .IMM_C18S:
		return .IMM
	case .REL13, .REL21, .REL9, .REL12:
		return .LABEL
	case .MEM, .MEM_C_W, .MEM_C_D, .MEM_C_SP_W, .MEM_C_SP_D:
		return .MEM
	case:
		// ROUND_MODE and anything unexpected: not part of a constructible
		// operand list (rounding mode is funct3-encoded, never an explicit
		// operand in the table). Skip and report.
		return .SKIP
	}
}

// Odin parameter type for an operand.
operand_odin_type :: proc(op: rv.Operand_Type) -> string {
	switch classify(op) {
	case .GPR:   return "GPR"
	case .FPR:   return "FPR"
	case .IMM:   return "i64"
	case .LABEL: return "u32"
	case .MEM:   return "Memory"
	case .SKIP:  return "unknown"
	}
	return "unknown"
}

// Suffix used in the generated procedure name.
operand_suffix :: proc(op: rv.Operand_Type) -> string {
	#partial switch op {
	case .GPR, .GPR_C, .GPR_SP, .GPR_NONZERO: return "gpr"
	case .FPR, .FPR_C:                        return "fpr"
	case .IMM12:                              return "imm12"
	case .IMM12U:                             return "imm12u"
	case .IMM5:                               return "imm5"
	case .IMM6:                               return "imm6"
	case .IMM20:                              return "imm20"
	case .CSR:                                return "csr"
	case .ZIMM5:                              return "zimm5"
	case .FENCE_FLAGS:                        return "fence"
	case .IMM_C6S:                            return "imm6s"
	case .IMM_C6U:                            return "imm6u"
	case .IMM_C8U:                            return "imm8u"
	case .IMM_C10S:                           return "imm10s"
	case .IMM_C18S:                           return "imm18s"
	case .REL13, .REL9:                       return "label"
	case .REL21, .REL12:                      return "label"
	case .MEM, .MEM_C_W, .MEM_C_D, .MEM_C_SP_W, .MEM_C_SP_D: return "mem"
	}
	return "unk"
}

// Immediate "size" byte passed to op_imm (cosmetic: used by the printer, not
// by the encoder's operand matcher). Mirrors the sizes used by the hand-written
// builders in instructions.odin.
imm_size :: proc(op: rv.Operand_Type) -> int {
	#partial switch op {
	case .IMM20:                              return 4
	case .IMM12, .IMM12U, .CSR:               return 2
	case .IMM5, .IMM6, .ZIMM5, .FENCE_FLAGS:  return 1
	case .IMM_C6S, .IMM_C6U, .IMM_C8U, .IMM_C10S, .IMM_C18S: return 2
	}
	return 2
}

// Label "size" byte passed to op_label (size of the relocation target field).
label_size :: proc(op: rv.Operand_Type) -> int {
	#partial switch op {
	case .REL13, .REL9:  return 2
	case .REL21, .REL12: return 4
	}
	return 2
}

// Write the op_* expression that constructs an Operand from `pname`.
write_operand_expr :: proc(sb: ^strings.Builder, op: rv.Operand_Type, pname: string) {
	switch classify(op) {
	case .GPR:   fmt.sbprintf(sb, "op_gpr(%s)", pname)
	case .FPR:   fmt.sbprintf(sb, "op_fpr(%s)", pname)
	case .IMM:   fmt.sbprintf(sb, "op_imm(%s, %d)", pname, imm_size(op))
	case .LABEL: fmt.sbprintf(sb, "op_label(%s, %d)", pname, label_size(op))
	case .MEM:   fmt.sbprintf(sb, "op_mem(%s)", pname)
	case .SKIP:  strings.write_string(sb, "{}")
	}
}

// -----------------------------------------------------------------------------
// Parameter naming (unique, readable names per operand)
// -----------------------------------------------------------------------------

param_names :: proc(sig: Operand_Signature) -> [4]string {
	result: [4]string
	reg_count := 0
	imm_count := 0

	for i in 0..<sig.count {
		op := sig.types[i].op_type
		switch classify(op) {
		case .IMM:
			if imm_count == 0 {
				result[i] = "imm"
			} else {
				result[i] = fmt.tprintf("imm%d", imm_count + 1)
			}
			imm_count += 1
		case .LABEL:
			result[i] = "label"
		case .MEM:
			result[i] = "mem"
		case .GPR, .FPR:
			// First register is the destination; subsequent ones are sources.
			if reg_count == 0 {
				result[i] = "rd"
			} else if reg_count == 1 {
				result[i] = "rs1"
			} else if reg_count == 2 {
				result[i] = "rs2"
			} else {
				result[i] = "rs3"
			}
			reg_count += 1
		case .SKIP:
			result[i] = fmt.tprintf("_p%d", i)
		}
	}
	return result
}

// -----------------------------------------------------------------------------
// Signature construction
// -----------------------------------------------------------------------------

// Build a signature from an encode form. Returns ok=false if any explicit
// operand cannot be cleanly constructed (the form is then skipped + reported).
build_signature :: proc(form: rv.Encoding) -> (sig: Operand_Signature, ok: bool) {
	for op in form.ops {
		if op == .NONE { continue }
		if classify(op) == .SKIP {
			return {}, false
		}
		sig.types[sig.count] = Operand_Info{op_type = op}
		sig.count += 1
	}
	return sig, true
}

// Procedure name from mnemonic + signature, including the "inst_" prefix.
generate_proc_name :: proc(mnemonic: rv.Mnemonic, sig: Operand_Signature) -> string {
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

// -----------------------------------------------------------------------------
// Body construction
// -----------------------------------------------------------------------------

// inst_ body: direct Instruction{} construction.
write_inst_body :: proc(sb: ^strings.Builder, entry: Proc_Entry) {
	sig   := entry.sig
	names := param_names(sig)

	mnem := fmt.aprintf("%v", entry.mnemonic)
	defer delete(mnem)

	if sig.count == 0 {
		// No operands: use the shared inst_none helper, then fix length for
		// compressed forms (inst_none defaults length to 4).
		if entry.length == 2 {
			fmt.sbprintf(sb, "Instruction{{mnemonic = .%s, operand_count = 0, length = 2}}", mnem)
		} else {
			fmt.sbprintf(sb, "inst_none(.%s)", mnem)
		}
		return
	}

	fmt.sbprintf(sb, "Instruction{{mnemonic = .%s, operand_count = %d, length = %d, ops = {{",
				 mnem, sig.count, entry.length)
	for i in 0..<4 {
		if i > 0 { strings.write_string(sb, ", ") }
		if i < sig.count {
			write_operand_expr(sb, sig.types[i].op_type, names[i])
		} else {
			strings.write_string(sb, "{}")
		}
	}
	strings.write_string(sb, "}}")
}

// emit_ body: append the inst_ result.
write_emit_body :: proc(sb: ^strings.Builder, entry: Proc_Entry) {
	sig   := entry.sig
	names := param_names(sig)

	strings.write_string(sb, "append(instructions, ")
	strings.write_string(sb, entry.proc_name)
	strings.write_byte(sb, '(')
	for i in 0..<sig.count {
		if i > 0 { strings.write_string(sb, ", ") }
		strings.write_string(sb, names[i])
	}
	strings.write_string(sb, "))")
}

// -----------------------------------------------------------------------------
// Procedure emission
// -----------------------------------------------------------------------------

write_params :: proc(sb: ^strings.Builder, sig: Operand_Signature, names: [4]string) {
	for i in 0..<sig.count {
		if i > 0 { strings.write_string(sb, ", ") }
		strings.write_string(sb, names[i])
		strings.write_string(sb, ": ")
		strings.write_string(sb, operand_odin_type(sig.types[i].op_type))
	}
}

generate_inst_proc :: proc(sb: ^strings.Builder, entry: Proc_Entry, pad: int) {
	names := param_names(entry.sig)

	strings.write_string(sb, entry.proc_name)
	for n := pad - len(entry.proc_name); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	strings.write_string(sb, " :: #force_inline proc \"contextless\" (")
	write_params(sb, entry.sig, names)
	strings.write_string(sb, ") -> Instruction { return ")
	write_inst_body(sb, entry)
	strings.write_string(sb, " }\n")
}

generate_emit_proc :: proc(sb: ^strings.Builder, entry: Proc_Entry, pad: int) {
	names := param_names(entry.sig)
	emit_name := strings.concatenate({"emit_", entry.proc_name[5:]})
	defer delete(emit_name)

	strings.write_string(sb, emit_name)
	for n := pad - len(entry.proc_name); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	strings.write_string(sb, " :: #force_inline proc(instructions: ^[dynamic]Instruction")
	if entry.sig.count > 0 {
		strings.write_string(sb, ", ")
		names2 := names
		write_params(sb, entry.sig, names2)
	}
	strings.write_string(sb, ") { ")
	write_emit_body(sb, entry)
	strings.write_string(sb, " }\n")
}

// -----------------------------------------------------------------------------
// main
// -----------------------------------------------------------------------------

main :: proc() {
	fmt.println("Generating RISC-V mnemonic builders from ENCODE_FORMS...")

	procs_by_mnemonic: map[rv.Mnemonic][dynamic]Proc_Entry
	defer {
		for _, v in procs_by_mnemonic { delete(v) }
		delete(procs_by_mnemonic)
	}

	seen_proc_names: map[string]bool
	defer delete(seen_proc_names)

	skipped: [dynamic]string
	defer delete(skipped)

	total_forms := 0

	for mnemonic in rv.Mnemonic {
		if mnemonic == .INVALID { continue }

		_run := rv.ENCODE_RUNS[u16(mnemonic)]
		forms := rv.ENCODE_FORMS[_run.start:][:_run.count]
		if len(forms) == 0 { continue }

		for form in forms {
			total_forms += 1

			sig, ok := build_signature(form)
			if !ok {
				append(&skipped, fmt.aprintf("%v (unconstructible operand)", mnemonic))
				continue
			}

			proc_name := generate_proc_name(mnemonic, sig)
			if proc_name in seen_proc_names {
				delete(proc_name)
				continue
			}
			seen_proc_names[proc_name] = true

			entry := Proc_Entry{
				mnemonic  = mnemonic,
				sig       = sig,
				proc_name = proc_name,
				length    = rv.inst_size_from_bits(form.bits),
			}

			if mnemonic not_in procs_by_mnemonic {
				procs_by_mnemonic[mnemonic] = make([dynamic]Proc_Entry)
			}
			append(&procs_by_mnemonic[mnemonic], entry)
		}
	}

	// Sorted mnemonic list for stable output.
	mnemonic_list: [dynamic]rv.Mnemonic
	defer delete(mnemonic_list)
	for m in procs_by_mnemonic { append(&mnemonic_list, m) }
	slice.sort_by(mnemonic_list[:], proc(a, b: rv.Mnemonic) -> bool {
		return int(a) < int(b)
	})

	// Padding width for nice column alignment.
	pad := 0
	for m in mnemonic_list {
		for entry in procs_by_mnemonic[m] {
			pad = max(pad, len(entry.proc_name))
		}
	}

	// ---- Build output -------------------------------------------------------
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
			generate_inst_proc(&sb, entry, pad)
		}
		for entry in procs {
			generate_emit_proc(&sb, entry, pad)
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

		mlow := mnemonic_to_lower(m)

		// inst_<mnem> overload group. If "inst_<mlow>" would collide with a
		// hand-written helper of the same name in instructions.odin (inst_jal,
		// inst_jalr), the standalone group alias is suppressed -- the existing
		// helper keeps that name and the typed builder stays reachable under its
		// explicit per-variant name (e.g. inst_jal_gpr_label).
		inst_group := strings.concatenate({"inst_", mlow})
		defer delete(inst_group)
		if is_reserved_inst_group(inst_group) {
			fmt.sbprintf(&sb, "// inst_%s: overload alias omitted (name taken by hand-written helper in instructions.odin); use %s\n",
						 mlow, procs[0].proc_name)
		} else {
			strings.write_string(&sb, inst_group)
			for n := pad - len(mlow); n > 0; n -= 1 { strings.write_byte(&sb, ' ') }
			write_group(&sb, procs, "inst_")
		}

		// emit_<mnem> overload group. No hand-written emit_ helpers collide.
		strings.write_string(&sb, "emit_")
		strings.write_string(&sb, mlow)
		for n := pad - len(mlow); n > 0; n -= 1 { strings.write_byte(&sb, ' ') }
		write_group(&sb, procs, "emit_")
	}

	output := strings.to_string(sb)
	err := os.write_entire_file(#directory + "/../mnemonic_builders.odin",
		transmute([]u8)strings.concatenate({GEN_ATTRIB, output}))

	if err == nil {
		total := 0
		for m in mnemonic_list { total += len(procs_by_mnemonic[m]) }
		fmt.println("Generated mnemonic_builders.odin successfully!")
		fmt.printf("  forms scanned:            %d\n", total_forms)
		fmt.printf("  mnemonics with builders:  %d\n", len(mnemonic_list))
		fmt.printf("  inst_/emit_ pairs:        %d\n", total)
		if len(skipped) > 0 {
			fmt.printf("  skipped forms:            %d\n", len(skipped))
			for s in skipped { fmt.printf("    - %s\n", s) }
		}
	} else {
		fmt.eprintln("Failed to write mnemonic_builders.odin")
		os.exit(1)
	}
}

// inst_<mnemonic> group names that coincide with a hand-written helper of the
// same name in instructions.odin. For these the standalone group alias is
// suppressed (the existing helper keeps the name); the typed builder stays
// reachable under its explicit per-variant name.
is_reserved_inst_group :: proc(name: string) -> bool {
	switch name {
	case "inst_jal":  return true // inst_jal(m, rd, label_id)  in instructions.odin
	case "inst_jalr": return true // inst_jalr(rd, rs1, imm)     in instructions.odin
	}
	return false
}

// Write the " :: proc{ ... }\n" overload group body (or single alias).
// prefix is "inst_" or "emit_"; entry proc_names always carry the "inst_"
// prefix, so for emit_ we swap the prefix.
write_group :: proc(sb: ^strings.Builder, procs: [dynamic]Proc_Entry, prefix: string) {
	emit_one :: proc(sb: ^strings.Builder, name: string, prefix: string) {
		if prefix == "emit_" {
			strings.write_string(sb, "emit_")
			strings.write_string(sb, name[5:])
		} else {
			strings.write_string(sb, name)
		}
	}

	if len(procs) == 1 {
		strings.write_string(sb, " :: ")
		emit_one(sb, procs[0].proc_name, prefix)
		strings.write_byte(sb, '\n')
		return
	}

	strings.write_string(sb, " :: proc{ ")
	for entry, i in procs {
		if i > 0 { strings.write_string(sb, ", ") }
		emit_one(sb, entry.proc_name, prefix)
	}
	strings.write_string(sb, " }\n")
}

generate_header :: proc(sb: ^strings.Builder) {
	strings.write_string(sb, `package rexcode_riscv

// =============================================================================
// GENERATED FILE - DO NOT EDIT
// =============================================================================
//
// Generated by gen_mnemonic_builders.odin from ENCODE_RUNS / ENCODE_FORMS.
// Regenerate with: odin run riscv/tools/gen_mnemonic_builders.odin -file
//
// Typed mnemonic builder procedures with overloading. Each mnemonic has one or
// more overloaded variants for its operand shapes. inst_<mnem> returns an
// Instruction; emit_<mnem> appends it to a ^[dynamic]Instruction.
//
// Register operands take the typed GPR / FPR enums (registers.odin); immediates
// take i64; PC-relative targets take a u32 label id; memory takes Memory.

`)
}
