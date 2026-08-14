// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package main

// =============================================================================
// MIPS Mnemonic Builder Generator
// =============================================================================
//
// Generates mnemonic_builders.odin by iterating the encoder's ENCODE_RUNS /
// ENCODE_FORMS tables and emitting typed, overloaded builder procedures per
// mnemonic. This mirrors x86/tools/gen_mnemonic_builders.odin, adapted to the
// simpler MIPS operand model:
//
//   * every operand is REGISTER / MEMORY / IMMEDIATE / RELATIVE
//   * registers carry their class typed enums where one exists (GPR, FPR,
//     CP0_Reg, GTE_DataReg, GTE_CtrlReg); classes without a typed enum
//     (FCR, MSA, VFPU) fall back to the generic `Register`
//   * memory is always `disp(base)` (one GPR + signed-16 displacement)
//
// For each form we build an operand signature (skipping NONE and purely
// implicit operands), map each operand type to (typed param, op_* expr),
// then emit:
//
//   inst_<mnem>_<suffix> :: proc(...) -> Instruction   (constructs Instruction)
//   emit_<mnem>_<suffix> :: proc(instructions, ...)     (appends inst_ result)
//
// deduped by proc name, and grouped into `inst_<mnem>` / `emit_<mnem>`
// overload sets.
//
// Run with: odin run tools/gen_mnemonic_builders.odin -file
// (writes mnemonic_builders.odin into the package root, ../).

import "core:fmt"
import "core:os"
import "core:strings"
import "core:slice"
import mips "../"

GEN_ATTRIB :: "// rexcode  ·  Brendan Punsky (dotbmp@github), original author\n\n"

// Output path: package root (one level up from tools/).
OUTPUT_PATH :: #directory + "/../mnemonic_builders.odin"

// -----------------------------------------------------------------------------
// Per-form operand signature
// -----------------------------------------------------------------------------

Operand_Signature :: struct {
	types: [4]mips.Operand_Type,
	count: int,
}

Proc_Entry :: struct {
	mnemonic:  mips.Mnemonic,
	sig:       Operand_Signature,
	proc_name: string, // includes the "inst_" prefix
}

mnemonic_to_lower :: proc(m: mips.Mnemonic) -> string {
	name := fmt.tprintf("%v", m)
	return strings.to_lower(name)
}

main :: proc() {
	fmt.println("Generating MIPS mnemonic builders from ENCODE_FORMS...")

	sb := strings.builder_make()

	generate_header(&sb)

	procs_by_mnemonic: map[mips.Mnemonic][dynamic]Proc_Entry
	defer {
		for _, v in procs_by_mnemonic { delete(v) }
		delete(procs_by_mnemonic)
	}

	// Dedup builder procedures by their generated name (per-mnemonic uniqueness
	// is already implied because the name embeds the mnemonic).
	seen_proc_names: map[string]bool
	defer delete(seen_proc_names)

	skipped_forms := 0

	for mnemonic in mips.Mnemonic {
		if mnemonic == .INVALID { continue }

		_run := mips.ENCODE_RUNS[u16(mnemonic)]
		forms := mips.ENCODE_FORMS[_run.start:][:_run.count]
		if len(forms) == 0 { continue }

		for form in forms {
			sig, ok := build_signature(form)
			if !ok {
				skipped_forms += 1
				continue
			}

			proc_name := generate_proc_name(mnemonic, sig)
			if proc_name in seen_proc_names { continue }
			seen_proc_names[proc_name] = true

			entry := Proc_Entry{ mnemonic = mnemonic, sig = sig, proc_name = proc_name }
			if mnemonic not_in procs_by_mnemonic {
				procs_by_mnemonic[mnemonic] = make([dynamic]Proc_Entry)
			}
			append(&procs_by_mnemonic[mnemonic], entry)
		}
	}

	// Sort mnemonics for deterministic output.
	mnemonic_list: [dynamic]mips.Mnemonic
	defer delete(mnemonic_list)
	for m in procs_by_mnemonic { append(&mnemonic_list, m) }
	slice.sort_by(mnemonic_list[:], proc(a, b: mips.Mnemonic) -> bool {
		return int(a) < int(b)
	})

	// Column padding for the proc-name alignment (cosmetic, matches x86 style).
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
		for entry in procs {
			generate_inst_proc(&sb, entry, max_name_padding)
		}
		for entry in procs {
			generate_emit_proc(&sb, entry, max_name_padding)
		}
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

		// inst_ group.
		strings.write_string(&sb, "inst_")
		strings.write_string(&sb, mnemonic_lower)
		for n := max_name_padding - len(mnemonic_lower) - 5; n > 0; n -= 1 {
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

		// emit_ group.
		strings.write_string(&sb, "emit_")
		strings.write_string(&sb, mnemonic_lower)
		for n := max_name_padding - len(mnemonic_lower) - 5; n > 0; n -= 1 {
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
	err := os.write_entire_file(OUTPUT_PATH, transmute([]u8)strings.concatenate({GEN_ATTRIB, output}))
	if err == nil {
		fmt.println("Generated mnemonic_builders.odin successfully!")
		total_procs := 0
		for m in mnemonic_list { total_procs += len(procs_by_mnemonic[m]) }
		fmt.printf("  mnemonics with builders: %d\n", len(mnemonic_list))
		fmt.printf("  inst_ procedures:        %d\n", total_procs)
		fmt.printf("  skipped forms:           %d\n", skipped_forms)
	} else {
		fmt.eprintln("Failed to write", OUTPUT_PATH, err)
	}
}

// -----------------------------------------------------------------------------
// Header
// -----------------------------------------------------------------------------

generate_header :: proc(sb: ^strings.Builder) {
	strings.write_string(sb, `package rexcode_mips

// =============================================================================
// GENERATED FILE - DO NOT EDIT
// =============================================================================
//
// Generated by tools/gen_mnemonic_builders.odin from ENCODE_FORMS.
// Regenerate with: odin run mips/tools/gen_mnemonic_builders.odin -file
//
// Typed mnemonic builder procedures with overloading. Each mnemonic exposes
// inst_<mnem> / emit_<mnem> overload sets; the underlying per-signature procs
// give compile-time operand-type checking (GPR vs FPR vs immediate, etc.).
//
// Operand-type -> parameter mapping:
//   GPR / GPR_ZERO        -> GPR          (op_gpr)
//   FPR_S/D/W/L/PS        -> FPR          (op_fpr; format is in the mnemonic)
//   CP0_REG               -> CP0_Reg      (op_cp0)
//   CP2_REG               -> GTE_DataReg  (op_gte_data)
//   CP2_CTRL              -> GTE_CtrlReg  (op_gte_ctrl)
//   FCR / MSA_VEC / VFPU* -> Register     (op_reg; no distinct typed enum)
//   IMM5/16S/16U/20, SEL, FCC -> i64      (op_imm)
//   REL16/21/26, REL_J26  -> u32 label id (op_label)
//   MEM                   -> Memory       (op_mem)

`)
}

// -----------------------------------------------------------------------------
// Signature construction
// -----------------------------------------------------------------------------

// Build the operand signature for a form, skipping NONE / implicit operands.
// Returns ok=false if the form contains an operand we cannot construct.
build_signature :: proc(form: mips.Encoding) -> (sig: Operand_Signature, ok: bool) {
	for op, i in form.ops {
		if op == .NONE { continue }
		if is_implicit_operand(form.enc[i]) { continue }
		if !can_generate_operand(op) {
			return {}, false
		}
		sig.types[sig.count] = op
		sig.count += 1
	}
	return sig, true
}

// An operand is implicit when it appears in the asm syntax but is not encoded.
is_implicit_operand :: proc(enc: mips.Operand_Encoding) -> bool {
	return enc == .IMPL
}

// Operand types we can map to a typed param + an op_ constructor.
can_generate_operand :: proc(op: mips.Operand_Type) -> bool {
	#partial switch op {
	case .GPR, .GPR_ZERO:
		return true
	case .FPR_S, .FPR_D, .FPR_W, .FPR_L, .FPR_PS:
		return true
	case .CP0_REG, .CP2_REG, .CP2_CTRL, .FCR, .MSA_VEC:
		return true
	case .VFPU_S, .VFPU_P, .VFPU_T, .VFPU_Q, .VFPU_M_P, .VFPU_M_T, .VFPU_M_Q:
		return true
	case .IMM5, .IMM16S, .IMM16U, .IMM20, .SEL, .FCC:
		return true
	case .REL16, .REL21, .REL26, .REL_J26, .REL19, .REL18:
		return true
	case .MEM:
		return true
	}
	// Skipped (no clean constructor): IMM26 (handled via REL_J26),
	// GTE_SF/MX/V/CV/LM cofun selectors (do not occur as user operands).
	return false
}

// -----------------------------------------------------------------------------
// Operand -> name suffix
// -----------------------------------------------------------------------------

operand_suffix :: proc(op: mips.Operand_Type) -> string {
	#partial switch op {
	case .GPR, .GPR_ZERO:                 return "r"
	case .FPR_S, .FPR_D, .FPR_W, .FPR_L, .FPR_PS: return "f"
	case .CP0_REG:                        return "c0"
	case .CP2_REG:                        return "c2"
	case .CP2_CTRL:                       return "c2c"
	case .FCR:                            return "fcr"
	case .MSA_VEC:                        return "w"
	case .VFPU_S:                         return "vs"
	case .VFPU_P:                         return "vp"
	case .VFPU_T:                         return "vt"
	case .VFPU_Q:                         return "vq"
	case .VFPU_M_P:                       return "vmp"
	case .VFPU_M_T:                       return "vmt"
	case .VFPU_M_Q:                       return "vmq"
	case .IMM5:                           return "i5"
	case .IMM16S:                         return "i16"
	case .IMM16U:                         return "u16"
	case .IMM20:                          return "i20"
	case .SEL:                            return "sel"
	case .FCC:                            return "cc"
	case .REL16, .REL19, .REL18:          return "rel"
	case .REL21:                          return "rel21"
	case .REL26:                          return "rel26"
	case .REL_J26:                        return "j"
	case .MEM:                            return "m"
	}
	return "x"
}

// -----------------------------------------------------------------------------
// Operand -> Odin parameter type
// -----------------------------------------------------------------------------

operand_param_type :: proc(op: mips.Operand_Type) -> string {
	#partial switch op {
	case .GPR, .GPR_ZERO:                 return "GPR"
	case .FPR_S, .FPR_D, .FPR_W, .FPR_L, .FPR_PS: return "FPR"
	case .CP0_REG:                        return "CP0_Reg"
	case .CP2_REG:                        return "GTE_DataReg"
	case .CP2_CTRL:                       return "GTE_CtrlReg"
	case .FCR, .MSA_VEC,
	     .VFPU_S, .VFPU_P, .VFPU_T, .VFPU_Q, .VFPU_M_P, .VFPU_M_T, .VFPU_M_Q:
		return "Register"
	case .IMM5, .IMM16S, .IMM16U, .IMM20, .SEL, .FCC:
		return "i64"
	case .REL16, .REL21, .REL26, .REL_J26, .REL19, .REL18:
		return "u32"
	case .MEM:                            return "Memory"
	}
	return "int"
}

// -----------------------------------------------------------------------------
// Operand -> op_* constructor expression (for the ops literal)
// -----------------------------------------------------------------------------

// Width hint (bytes) written into op_imm / op_mem. Encoding ignores it; it is
// only a cosmetic size annotation on the Operand.
operand_imm_size :: proc(op: mips.Operand_Type) -> int {
	#partial switch op {
	case .IMM5, .SEL, .FCC: return 1
	case .IMM16S, .IMM16U:  return 2
	case .IMM20:            return 4
	}
	return 4
}

write_op_expr :: proc(sb: ^strings.Builder, op: mips.Operand_Type, name: string) {
	#partial switch op {
	case .GPR, .GPR_ZERO:
		fmt.sbprintf(sb, "op_gpr(%s)", name)
	case .FPR_S, .FPR_D, .FPR_W, .FPR_L, .FPR_PS:
		fmt.sbprintf(sb, "op_fpr(%s)", name)
	case .CP0_REG:
		fmt.sbprintf(sb, "op_cp0(%s)", name)
	case .CP2_REG:
		fmt.sbprintf(sb, "op_gte_data(%s)", name)
	case .CP2_CTRL:
		fmt.sbprintf(sb, "op_gte_ctrl(%s)", name)
	case .FCR, .MSA_VEC,
	     .VFPU_S, .VFPU_P, .VFPU_T, .VFPU_Q, .VFPU_M_P, .VFPU_M_T, .VFPU_M_Q:
		fmt.sbprintf(sb, "op_reg(%s)", name)
	case .IMM5, .IMM16S, .IMM16U, .IMM20, .SEL, .FCC:
		fmt.sbprintf(sb, "op_imm(%s, %d)", name, operand_imm_size(op))
	case .REL16, .REL21, .REL26, .REL_J26, .REL19, .REL18:
		fmt.sbprintf(sb, "op_label(%s)", name)
	case .MEM:
		fmt.sbprintf(sb, "op_mem(%s, 4)", name)
	case:
		strings.write_string(sb, "{}")
	}
}

// -----------------------------------------------------------------------------
// Parameter naming (unique per slot)
// -----------------------------------------------------------------------------

param_names :: proc(sig: Operand_Signature) -> [4]string {
	result: [4]string
	reg_n  := 0
	imm_n  := 0
	mem_n  := 0
	rel_n  := 0

	for i in 0..<sig.count {
		op := sig.types[i]
		#partial switch op {
		case .IMM5, .IMM16S, .IMM16U, .IMM20, .SEL, .FCC:
			result[i] = imm_n == 0 ? "imm" : fmt.tprintf("imm%d", imm_n + 1)
			imm_n += 1
		case .REL16, .REL21, .REL26, .REL_J26, .REL19, .REL18:
			result[i] = rel_n == 0 ? "target" : fmt.tprintf("target%d", rel_n + 1)
			rel_n += 1
		case .MEM:
			result[i] = mem_n == 0 ? "mem" : fmt.tprintf("mem%d", mem_n + 1)
			mem_n += 1
		case:
			// register-class operand
			if reg_n == 0      { result[i] = "dst" }
			else if reg_n == 1 { result[i] = "src" }
			else               { result[i] = fmt.tprintf("src%d", reg_n) }
			reg_n += 1
		}
	}
	return result
}

// -----------------------------------------------------------------------------
// Proc-name generation
// -----------------------------------------------------------------------------

generate_proc_name :: proc(mnemonic: mips.Mnemonic, sig: Operand_Signature) -> string {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)

	strings.write_string(&sb, "inst_")
	strings.write_string(&sb, mnemonic_to_lower(mnemonic))

	if sig.count == 0 {
		strings.write_string(&sb, "_none")
	} else {
		for i in 0..<sig.count {
			strings.write_byte(&sb, '_')
			strings.write_string(&sb, operand_suffix(sig.types[i]))
		}
	}
	return strings.clone(strings.to_string(sb))
}

// -----------------------------------------------------------------------------
// Procedure emission
// -----------------------------------------------------------------------------

// Build the `ops = { ... }` Instruction literal body (always direct
// construction -- robust against MIPS's varied operand orderings).
write_ops_literal :: proc(sb: ^strings.Builder, sig: Operand_Signature, names: [4]string) {
	strings.write_string(sb, "ops = {")
	for i in 0..<4 {
		if i > 0 { strings.write_string(sb, ", ") }
		if i < sig.count {
			write_op_expr(sb, sig.types[i], names[i])
		} else {
			strings.write_string(sb, "{}")
		}
	}
	strings.write_string(sb, "}")
}

generate_inst_proc :: proc(sb: ^strings.Builder, entry: Proc_Entry, pad: int) {
	sig   := entry.sig
	names := param_names(sig)

	// Params.
	params_sb := strings.builder_make()
	defer strings.builder_destroy(&params_sb)
	for i in 0..<sig.count {
		if i > 0 { strings.write_string(&params_sb, ", ") }
		fmt.sbprintf(&params_sb, "%s: %s", names[i], operand_param_type(sig.types[i]))
	}
	params := strings.to_string(params_sb)

	mnemonic_str := fmt.tprintf("%v", entry.mnemonic)

	strings.write_string(sb, entry.proc_name)
	for n := pad - len(entry.proc_name); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	strings.write_string(sb, " :: #force_inline proc \"contextless\" (")
	strings.write_string(sb, params)
	strings.write_string(sb, ") -> Instruction { return Instruction{mnemonic = .")
	strings.write_string(sb, mnemonic_str)
	fmt.sbprintf(sb, ", operand_count = %d, length = 4, ", sig.count)
	write_ops_literal(sb, sig, names)
	strings.write_string(sb, "} }\n")
}

generate_emit_proc :: proc(sb: ^strings.Builder, entry: Proc_Entry, pad: int) {
	sig   := entry.sig
	names := param_names(sig)

	// Params: instructions buffer + original params.
	params_sb := strings.builder_make()
	defer strings.builder_destroy(&params_sb)
	strings.write_string(&params_sb, "instructions: ^[dynamic]Instruction")
	for i in 0..<sig.count {
		fmt.sbprintf(&params_sb, ", %s: %s", names[i], operand_param_type(sig.types[i]))
	}
	params := strings.to_string(params_sb)

	emit_name := strings.concatenate({"emit_", entry.proc_name[5:]})

	strings.write_string(sb, emit_name)
	for n := pad - len(entry.proc_name); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	strings.write_string(sb, " :: #force_inline proc(")
	strings.write_string(sb, params)
	strings.write_string(sb, ") { append(instructions, ")
	strings.write_string(sb, entry.proc_name)
	strings.write_string(sb, "(")
	for i in 0..<sig.count {
		if i > 0 { strings.write_string(sb, ", ") }
		strings.write_string(sb, names[i])
	}
	strings.write_string(sb, ")) }\n")
}
