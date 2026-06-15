// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package main

// =============================================================================
// AArch32 Mnemonic Builder Generator
// =============================================================================
//
// Generates mnemonic_builders.odin by iterating the encoder's ENCODE_FORMS
// (via ENCODE_RUNS) and creating typed builder procedures with overloading for
// each mnemonic — mirroring x86/tools/gen_mnemonic_builders.odin.
//
// Run with:  odin run tools/gen_mnemonic_builders.odin -file
// Output:    arm32/mnemonic_builders.odin (written to package root)
//
// arm32 has a very rich operand set (shifted/extended regs, register-shifted
// register, NEON lane/vector forms, modified immediates, register lists,
// coprocessor selectors, MVE/CDE classes, ...). Many of these have no clean
// single-value constructor, so — like x86 skips far pointers / moffs — we only
// emit a builder for a form when EVERY one of its operands is cleanly
// constructible from a single typed parameter. The skipped operand classes are
// listed in is_buildable_operand() below.
//
// Note: arm32's Register is a single distinct-u16 type with NO per-class typed
// enums (GPR / SPR / DPR / QPR all share the `Register` type). Every register
// parameter is therefore `Register`. Two forms of one mnemonic that reduce to
// the same parameter-type tuple would create an ambiguous overload set, so we
// additionally dedup by the Odin parameter-type signature, keeping the first
// (table-order) form.

import "core:fmt"
import "core:os"
import "core:strings"
import "core:slice"
import a "../"

GEN_ATTRIB :: "// rexcode  ·  Brendan Punsky (dotbmp@github), original author\n\n"

// Per-form operand signature (explicit, buildable operands only).
Operand_Signature :: struct {
	types:  [4]a.Operand_Type,
	mode:   a.Mode,
	length: u8,            // on-wire byte length of the matched form (2 or 4)
	count:  int,
}

Proc_Entry :: struct {
	mnemonic:  a.Mnemonic,
	sig:       Operand_Signature,
	proc_name: string, // includes the "inst_" prefix
}

mnemonic_to_lower :: proc(m: a.Mnemonic) -> string {
	return strings.to_lower(fmt.tprintf("%v", m))
}

// ---- Operand classification -------------------------------------------------

// Truly-implicit operands carry no user value and emit no bits. Note: a .NONE
// encoding slot does NOT mean implicit — many real operands (immediates, some
// regs) have enc == .NONE because the encoder derives their bit placement from
// the operand TYPE rather than a named slot. Presence is keyed on the operand
// type (ops[i] != .NONE); only enc == .IMPL is dropped. (The current arm32
// table contains zero .IMPL operands; this guard is for forward-compat.)
is_implicit_operand :: proc(enc: a.Operand_Encoding) -> bool {
	return enc == .IMPL
}

Operand_Class :: enum {
	NONE,  // not buildable
	REG,   // single Register
	IMM,   // i64 immediate
	MEM,   // Memory operand
	REL,   // branch target (raw i64 offset)
}

// Map an operand TYPE to a build class. Returns .NONE for operand types that
// have no clean single-value constructor (these forms are skipped wholesale).
//
// Covered : plain GPR/FP/SIMD registers, plain numeric immediates, MEM,
//           PC-relative branch targets.
// Skipped : shifted/RSR regs, register lists, NEON lane/vector elem forms,
//           modified immediates, NEON imm, condition-code operand, coprocessor
//           selectors, PSR field, MVE/CDE classes, special encoded immediates
//           (barrier/endian/iflags/banked/sysm/coproc/hint).
operand_class :: proc(ot: a.Operand_Type) -> Operand_Class {
	#partial switch ot {
	// ---- Plain registers (single Register value) ----
	case .GPR, .GPR_NOPC, .GPR_NOSP, .GPR_LOW:
		return .REG
	case .SPR, .DPR, .QPR, .SPR_ELEM, .QPR_MVE:
		return .REG

	// ---- Plain numeric immediates (single i64 value) ----
	case .IMM, .IMM12, .IMM5, .IMM5_W, .IMM4, .IMM4_SAT, .IMM8, .IMM3, .IMM16_LO_HI:
		return .IMM

	// ---- Memory ----
	case .MEM:
		return .MEM

	// ---- PC-relative branch targets ----
	case .REL24, .REL24_T32, .REL20, .REL11, .REL8:
		return .REL
	}

	// Everything else is not cleanly buildable -> skip the form.
	return .NONE
}

// Suffix used in the procedure name for an operand type.
operand_suffix :: proc(ot: a.Operand_Type) -> string {
	#partial switch ot {
	case .GPR:         return "r"
	case .GPR_NOPC:    return "r"
	case .GPR_NOSP:    return "r"
	case .GPR_LOW:     return "rlo"
	case .SPR:         return "s"
	case .SPR_ELEM:    return "s"
	case .DPR:         return "d"
	case .QPR:         return "q"
	case .QPR_MVE:     return "qm"
	case .IMM:         return "imm"
	case .IMM12:       return "imm12"
	case .IMM5:        return "imm5"
	case .IMM5_W:      return "imm5w"
	case .IMM4:        return "imm4"
	case .IMM4_SAT:    return "imm4s"
	case .IMM8:        return "imm8"
	case .IMM3:        return "imm3"
	case .IMM16_LO_HI: return "imm16"
	case .MEM:         return "mem"
	case .REL24:       return "rel"
	case .REL24_T32:   return "rel"
	case .REL20:       return "rel"
	case .REL11:       return "rel"
	case .REL8:        return "rel"
	}
	return "x"
}

// Odin parameter type for an operand type.
operand_odin_type :: proc(ot: a.Operand_Type) -> string {
	switch operand_class(ot) {
	case .REG: return "Register"
	case .IMM: return "i64"
	case .MEM: return "Memory"
	case .REL: return "i64"
	case .NONE: return "unknown"
	}
	return "unknown"
}

// Build the op_* expression for one operand.
operand_expr :: proc(sb: ^strings.Builder, ot: a.Operand_Type, name: string) {
	switch operand_class(ot) {
	case .REG: fmt.sbprintf(sb, "op_reg(%s)", name)
	case .IMM: fmt.sbprintf(sb, "op_imm(%s)", name)
	case .MEM: fmt.sbprintf(sb, "op_mem(%s)", name)
	case .REL: fmt.sbprintf(sb, "op_rel_offset(%s)", name)
	case .NONE: strings.write_string(sb, "{}")
	}
}

// ---- Signature extraction ---------------------------------------------------

// Returns ok=false if the form has any non-buildable explicit operand, or if it
// has more than 4 explicit operands. An all-NONE form yields count=0 (e.g. NOP).
form_signature :: proc(form: a.Encoding) -> (sig: Operand_Signature, ok: bool) {
	sig.mode = form.mode
	sig.length = a.inst_size_from_bits(form.bits, form.mode)
	for ot, i in form.ops {
		if ot == .NONE { continue }
		if is_implicit_operand(form.enc[i]) { continue }

		if operand_class(ot) == .NONE {
			return {}, false
		}
		if sig.count >= 4 {
			return {}, false
		}
		sig.types[sig.count] = ot
		sig.count += 1
	}
	return sig, true
}

// ---- Naming -----------------------------------------------------------------

// Procedure name (with "inst_" prefix). No-operand forms get an explicit _none
// suffix so they don't collide with the overload-group name.
proc_name_for :: proc(m: a.Mnemonic, sig: Operand_Signature) -> string {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)

	strings.write_string(&sb, "inst_")
	strings.write_string(&sb, mnemonic_to_lower(m))

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

// Parameter names: dst / src / src2 / src3 for register & memory operands;
// imm / imm2 for immediates; offset for branch targets.
param_names :: proc(sig: Operand_Signature) -> [4]string {
	out: [4]string
	src_count := 0
	imm_count := 0
	for i in 0..<sig.count {
		switch operand_class(sig.types[i]) {
		case .IMM:
			out[i] = imm_count == 0 ? "imm" : fmt.tprintf("imm%d", imm_count + 1)
			imm_count += 1
		case .REL:
			out[i] = "offset"
		case .REG, .MEM:
			if i == 0 {
				out[i] = "dst"
			} else {
				out[i] = src_count == 0 ? "src" : fmt.tprintf("src%d", src_count + 1)
				src_count += 1
			}
		case .NONE:
			out[i] = "_x"
		}
	}
	return out
}

// Type-signature key for overload-ambiguity dedup: the tuple of Odin parameter
// types plus the mnemonic. Two forms with identical param-type tuples cannot
// coexist in one overload set, so we keep only the first.
type_sig_key :: proc(m: a.Mnemonic, sig: Operand_Signature) -> string {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	fmt.sbprintf(&sb, "%v|", m)
	for i in 0..<sig.count {
		strings.write_string(&sb, operand_odin_type(sig.types[i]))
		strings.write_byte(&sb, ',')
	}
	return strings.clone(strings.to_string(sb))
}

// ---- Body generation --------------------------------------------------------

// inst_ body: a direct Instruction{} literal with the matched form's exact mode
// and on-wire length baked in. We deliberately do NOT route through the
// instructions.odin shape helpers (inst_r_r etc.): those hardcode length = 4
// even for T32, which is wrong for 16-bit T16 forms (length must be 2) and
// causes the encoder to reject them. Baking `length` from the form via
// inst_size_from_bits() keeps A32 (4), T16 (2) and T32-wide (4) all correct.
// cond defaults to 14 (AL); sets_flags / wide are left at their zero defaults.
inst_body :: proc(sb: ^strings.Builder, entry: Proc_Entry) {
	sig := entry.sig
	names := param_names(sig)
	mn := fmt.tprintf("%v", entry.mnemonic)

	ops := strings.builder_make()
	defer strings.builder_destroy(&ops)
	for i in 0..<4 {
		if i > 0 { strings.write_string(&ops, ", ") }
		if i < sig.count {
			operand_expr(&ops, sig.types[i], names[i])
		} else {
			strings.write_string(&ops, "{}")
		}
	}

	fmt.sbprintf(sb, "Instruction{{mnemonic = .%s, operand_count = %d, mode = .%v, cond = 14, length = %d, ops = {{%s}}}}",
				 mn, sig.count, sig.mode, sig.length, strings.to_string(ops))
}

// ---- Emitters ---------------------------------------------------------------

// inst_ procedure (compact one line). #force_inline contextless like x86.
write_inst_proc :: proc(sb: ^strings.Builder, entry: Proc_Entry, pad: int) {
	sig := entry.sig
	names := param_names(sig)

	params := strings.builder_make()
	defer strings.builder_destroy(&params)
	for i in 0..<sig.count {
		if i > 0 { strings.write_string(&params, ", ") }
		fmt.sbprintf(&params, "%s: %s", names[i], operand_odin_type(sig.types[i]))
	}

	strings.write_string(sb, entry.proc_name)
	for n := pad - len(entry.proc_name); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	strings.write_string(sb, " :: #force_inline proc \"contextless\" (")
	strings.write_string(sb, strings.to_string(params))
	strings.write_string(sb, ") -> Instruction { return ")
	inst_body(sb, entry)
	strings.write_string(sb, " }\n")
}

// emit_ procedure: append(instructions, inst_<...>(args)). Not contextless —
// append needs context. arm32 has no encoder-level emit_* helpers, so these
// simply wrap the inst_ builder.
write_emit_proc :: proc(sb: ^strings.Builder, entry: Proc_Entry, pad: int) {
	sig := entry.sig
	names := param_names(sig)
	emit_name := strings.concatenate({"emit_", entry.proc_name[5:]})
	defer delete(emit_name)

	params := strings.builder_make()
	defer strings.builder_destroy(&params)
	strings.write_string(&params, "instructions: ^[dynamic]Instruction")
	for i in 0..<sig.count {
		fmt.sbprintf(&params, ", %s: %s", names[i], operand_odin_type(sig.types[i]))
	}

	strings.write_string(sb, emit_name)
	for n := pad - len(entry.proc_name); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	strings.write_string(sb, " :: #force_inline proc(")
	strings.write_string(sb, strings.to_string(params))
	strings.write_string(sb, ") { append(instructions, ")
	strings.write_string(sb, entry.proc_name)
	strings.write_byte(sb, '(')
	for i in 0..<sig.count {
		if i > 0 { strings.write_string(sb, ", ") }
		strings.write_string(sb, names[i])
	}
	strings.write_string(sb, ")) }\n")
}

// ---- Main -------------------------------------------------------------------

main :: proc() {
	fmt.println("Generating arm32 mnemonic builders from ENCODE_FORMS...")

	procs_by_mnemonic: map[a.Mnemonic][dynamic]Proc_Entry
	defer {
		for _, v in procs_by_mnemonic { delete(v) }
		delete(procs_by_mnemonic)
	}

	// Dedup keys.
	seen_names:     map[string]bool   // unique proc names
	seen_type_sigs: map[string]bool   // unique param-type tuples (overload safety)
	defer delete(seen_names)
	defer delete(seen_type_sigs)

	total_forms := 0
	skipped_forms := 0

	for m in a.Mnemonic {
		if m == .INVALID { continue }

		_run := a.ENCODE_RUNS[u16(m)]
		forms := a.ENCODE_FORMS[_run.start:][:_run.count]

		for form in forms {
			total_forms += 1

			sig, ok := form_signature(form)
			if !ok {
				skipped_forms += 1
				continue
			}

			name := proc_name_for(m, sig)
			if name in seen_names { continue }

			tkey := type_sig_key(m, sig)
			if tkey in seen_type_sigs {
				// Same param-type tuple already taken for this mnemonic; a second
				// one would make the overload set ambiguous.
				continue
			}

			seen_names[name] = true
			seen_type_sigs[tkey] = true

			if m not_in procs_by_mnemonic {
				procs_by_mnemonic[m] = make([dynamic]Proc_Entry)
			}
			append(&procs_by_mnemonic[m], Proc_Entry{mnemonic = m, sig = sig, proc_name = name})
		}
	}

	// Sorted mnemonic list for stable output.
	mlist: [dynamic]a.Mnemonic
	defer delete(mlist)
	for m in procs_by_mnemonic { append(&mlist, m) }
	slice.sort_by(mlist[:], proc(x, y: a.Mnemonic) -> bool { return int(x) < int(y) })

	pad := 0
	for m in mlist {
		for e in procs_by_mnemonic[m] {
			pad = max(pad, len(e.proc_name))
		}
	}

	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)

	write_header(&sb)

	strings.write_string(&sb, `// =============================================================================
// Individual Typed Builder Procedures
// =============================================================================

`)
	for m in mlist {
		procs := procs_by_mnemonic[m]
		for e in procs { write_inst_proc(&sb, e, pad) }
		for e in procs { write_emit_proc(&sb, e, pad) }
	}

	strings.write_string(&sb, `
// =============================================================================
// Overload Groups
// =============================================================================

`)
	for m in mlist {
		procs := procs_by_mnemonic[m]
		if len(procs) == 0 { continue }
		ml := mnemonic_to_lower(m)

		// inst_<mnem>
		strings.write_string(&sb, "inst_")
		strings.write_string(&sb, ml)
		for n := pad - len(ml); n > 0; n -= 1 { strings.write_byte(&sb, ' ') }
		if len(procs) == 1 {
			fmt.sbprintf(&sb, " :: %s\n", procs[0].proc_name)
		} else {
			strings.write_string(&sb, " :: proc{ ")
			for e, i in procs {
				if i > 0 { strings.write_string(&sb, ", ") }
				strings.write_string(&sb, e.proc_name)
			}
			strings.write_string(&sb, " }\n")
		}

		// emit_<mnem>
		strings.write_string(&sb, "emit_")
		strings.write_string(&sb, ml)
		for n := pad - len(ml); n > 0; n -= 1 { strings.write_byte(&sb, ' ') }
		if len(procs) == 1 {
			fmt.sbprintf(&sb, " :: emit_%s\n", procs[0].proc_name[5:])
		} else {
			strings.write_string(&sb, " :: proc{ ")
			for e, i in procs {
				if i > 0 { strings.write_string(&sb, ", ") }
				fmt.sbprintf(&sb, "emit_%s", e.proc_name[5:])
			}
			strings.write_string(&sb, " }\n")
		}
	}

	path := #directory + "/../mnemonic_builders.odin"
	err := os.write_entire_file(path, transmute([]u8)strings.concatenate({GEN_ATTRIB, strings.to_string(sb)}))
	if err == nil {
		total_procs := 0
		for m in mlist { total_procs += len(procs_by_mnemonic[m]) }
		fmt.println("Generated mnemonic_builders.odin successfully!")
		fmt.printf("Mnemonics with builders: %d\n", len(mlist))
		fmt.printf("Procedures generated:    %d\n", total_procs)
		fmt.printf("Forms total:             %d\n", total_forms)
		fmt.printf("Forms skipped (operand): %d\n", skipped_forms)
	} else {
		fmt.eprintln("Failed to write mnemonic_builders.odin")
		os.exit(1)
	}
}

write_header :: proc(sb: ^strings.Builder) {
	strings.write_string(sb, `package rexcode_arm32

// =============================================================================
// GENERATED FILE - DO NOT EDIT
// =============================================================================
//
// Generated by tools/gen_mnemonic_builders.odin from ENCODE_FORMS / ENCODE_RUNS.
// Regenerate with: odin run arm32/tools/gen_mnemonic_builders.odin -file
//
// Typed mnemonic builder procedures with overloading. Each mnemonic exposes an
// inst_<mnem> overload set (returns Instruction) and an emit_<mnem> overload
// set (appends to a ^[dynamic]Instruction). Only forms whose every operand is
// cleanly constructible from a single typed parameter are generated; shifted /
// register-shifted registers, register lists, NEON lane/vector forms, modified
// immediates, condition-code operands, coprocessor / PSR / MVE / CDE selectors
// and special encoded immediates are intentionally omitted.

`)
}
