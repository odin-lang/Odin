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
// coprocessor selectors, MVE/CDE classes, ...). EVERY operand type maps to one
// or more typed parameters here — there are no skipped operand classes — so a
// builder is emitted for every form whose operands fit in <=4 slots (which is
// every real form). The mapping mirrors what the encoder's pack_operand_inline
// reads out of each Operand:
//
//   plain reg            -> op_reg(Register)
//   shifted reg (imm)    -> op_reg_shifted(Register, Shift_Type, u8)
//   register-shifted reg -> op_reg_shifted(Register, Shift_Type, u8(reg_hw(Rs)))
//   register list        -> op_reg_list(u16 mask)
//   NEON D/Q lane elem   -> op_dpr_lane / op_qpr_lane (Register, u8 lane)
//   any immediate class  -> op_imm(i64)  (the encoder does the field packing:
//                           modified-imm, barrier, endian, iflags, sysm, coproc,
//                           saturating, PSR field, hint, cond-operand, ...)
//   memory               -> op_mem(Memory)
//   PC-relative / loop    -> op_rel_offset(i64)
//
// Note: arm32's Register is a single distinct-u16 type with NO per-class typed
// enums (GPR / SPR / DPR / QPR all share the `Register` type). Every register
// parameter is therefore `Register`. Two forms of one mnemonic that reduce to
// the same ordered Odin parameter-type tuple would create an ambiguous overload
// set, so we dedup by that tuple, keeping the first (table-order) form.

import "core:fmt"
import "core:os"
import "core:strings"
import "core:slice"
import a "../"

GEN_ATTRIB :: "// rexcode  ·  Brendan Punsky (dotbmp@github), original author\n\n"

// Per-form operand signature.
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
// the operand TYPE rather than a named slot (or, for COND-as-operand, the value
// rides in a sibling field). Presence is keyed on the operand TYPE
// (ops[i] != .NONE); only enc == .IMPL is dropped. (The current arm32 table
// contains zero .IMPL operands; this guard is for forward-compat.)
is_implicit_operand :: proc(enc: a.Operand_Encoding) -> bool {
	return enc == .IMPL
}

// A build class describes the shape of the typed parameter(s) an operand needs
// and which op_* constructor assembles it. Unlike the old generator, this is
// TOTAL over Operand_Type: every type maps to exactly one class so no form is
// ever skipped for operand reasons.
Operand_Class :: enum {
	REG,      // op_reg(Register)
	IMM,      // op_imm(i64)              -- includes all encoded-imm subclasses
	MEM,      // op_mem(Memory)
	REL,      // op_rel_offset(i64)
	SHIFTED,  // op_reg_shifted(Register, Shift_Type, u8)        -- imm shift
	RSR,      // op_reg_shifted(Register, Shift_Type, u8(reg_hw(Rs))) -- reg shift
	LIST,     // op_reg_list(u16)
	LANE_D,   // op_dpr_lane(Register, u8)
	LANE_Q,   // op_qpr_lane(Register, u8)
}

// Map an operand TYPE to its build class. Total: every Operand_Type that can
// appear in a form has a mapping. The encoder's operand_matches_inline /
// pack_operand_inline define the contract each class must satisfy.
operand_class :: proc(ot: a.Operand_Type) -> Operand_Class {
	#partial switch ot {
	// ---- Shifted / register-shifted GPR ----
	case .GPR_SHIFTED:
		return .SHIFTED
	case .GPR_RSR:
		return .RSR

	// ---- Register lists (GPR/SPR/DPR/MVE-Q) ----
	case .GPR_LIST, .SPR_LIST, .DPR_LIST, .QPR_MVE_LIST:
		return .LIST

	// ---- NEON lane elements ----
	case .DPR_ELEM:
		return .LANE_D
	case .QPR_ELEM:
		return .LANE_Q

	// ---- Memory ----
	case .MEM:
		return .MEM

	// ---- PC-relative branch targets & low-overhead-loop targets ----
	case .REL24, .REL24_T32, .REL20, .REL11, .REL8, .REL_LDR_LITERAL, .MVE_LOOP_TGT:
		return .REL

	// ---- Plain registers (single Register value) ----
	case .GPR, .GPR_NOPC, .GPR_NOSP, .GPR_LOW,
	     .SPR, .DPR, .QPR, .SPR_ELEM, .QPR_MVE, .VPR,
	     .COPROC_REG, .COPROC_NUM, .CDE_VFP_REG:
		return .REG
	}

	// Everything else is an immediate the encoder packs from op.immediate:
	// IMM/IMM12/IMM5/.../modified-imm/barrier/endian/iflags/banked/sysm/coproc/
	// coproc-op/NEON-imm/hint/PSR_FIELD/COND/MVE-size/MVE-vpt-mask/CDE-imm/
	// CDE-coproc, etc. All single i64 via op_imm.
	return .IMM
}

// Suffix used in the procedure name for an operand type. Distinct per type so
// proc names stay readable; overload ambiguity is handled separately by the
// Odin param-type-tuple dedup.
operand_suffix :: proc(ot: a.Operand_Type) -> string {
	#partial switch ot {
	case .GPR:           return "r"
	case .GPR_NOPC:      return "r"
	case .GPR_NOSP:      return "r"
	case .GPR_LOW:       return "rlo"
	case .GPR_SHIFTED:   return "rsh"
	case .GPR_RSR:       return "rsr"
	case .GPR_LIST:      return "list"
	case .SPR:           return "s"
	case .SPR_ELEM:      return "s"
	case .SPR_LIST:      return "slist"
	case .DPR:           return "d"
	case .DPR_ELEM:      return "dlane"
	case .DPR_LIST:      return "dlist"
	case .QPR:           return "q"
	case .QPR_ELEM:      return "qlane"
	case .QPR_MVE:       return "qm"
	case .QPR_MVE_LIST:  return "qlist"
	case .VPR:           return "vpr"
	case .IMM:           return "imm"
	case .IMM_MOD:       return "immm"
	case .IMM_T32_MOD:   return "immtm"
	case .IMM12:         return "imm12"
	case .IMM5:          return "imm5"
	case .IMM5_W:        return "imm5w"
	case .IMM4:          return "imm4"
	case .IMM4_SAT:      return "imm4s"
	case .IMM8:          return "imm8"
	case .IMM3:          return "imm3"
	case .IMM16_LO_HI:   return "imm16"
	case .IMM_HINT:      return "hint"
	case .IMM_BARRIER:   return "barr"
	case .IMM_ENDIAN:    return "end"
	case .IMM_IFLAGS:    return "ifl"
	case .IMM_BANKED:    return "bank"
	case .IMM_SYSM:      return "sysm"
	case .IMM_COPROC:    return "cp"
	case .IMM_COPROC_OP: return "cpop"
	case .NEON_IMM:      return "nimm"
	case .COND:          return "cond"
	case .MEM:           return "mem"
	case .REL24:         return "rel"
	case .REL24_T32:     return "rel"
	case .REL20:         return "rel"
	case .REL11:         return "rel"
	case .REL8:          return "rel"
	case .REL_LDR_LITERAL: return "rel"
	case .COPROC_REG:    return "crd"
	case .COPROC_NUM:    return "cpn"
	case .PSR_FIELD:     return "psr"
	case .MVE_VPT_MASK:  return "vpt"
	case .MVE_VCTP_SIZE: return "vsz"
	case .MVE_LOOP_TGT:  return "loop"
	case .CDE_COPROC:    return "cdec"
	case .CDE_IMM:       return "cdei"
	case .CDE_VFP_REG:   return "cdev"
	}
	return "x"
}

// Static parameter-type lists (returned as slices into rodata, so they don't
// alias a stack frame).
@(rodata) PT_REG     := []string{"Register"}
@(rodata) PT_IMM     := []string{"i64"}
@(rodata) PT_MEM     := []string{"Memory"}
@(rodata) PT_REL     := []string{"i64"}
@(rodata) PT_SHIFTED := []string{"Register", "Shift_Type", "u8"}
@(rodata) PT_RSR     := []string{"Register", "Shift_Type", "Register"}
@(rodata) PT_LIST    := []string{"u16"}
@(rodata) PT_LANE    := []string{"Register", "u8"}

// The ordered list of Odin parameter TYPES an operand expands to. Most operands
// are a single param; shifted / register-shifted regs and NEON lane elems take
// extra params (shift kind + amount, or lane index).
operand_param_types :: proc(ot: a.Operand_Type) -> []string {
	switch operand_class(ot) {
	case .REG:     return PT_REG
	case .IMM:     return PT_IMM
	case .MEM:     return PT_MEM
	case .REL:     return PT_REL
	case .SHIFTED: return PT_SHIFTED
	case .RSR:     return PT_RSR
	case .LIST:    return PT_LIST
	case .LANE_D:  return PT_LANE
	case .LANE_Q:  return PT_LANE
	}
	return PT_REG
}

// ---- Signature extraction ---------------------------------------------------

// Returns ok=false only if the form has more than 4 explicit operands (no real
// arm32 form does). An all-NONE form yields count=0 (e.g. NOP). No form is
// skipped for operand-type reasons — operand_class is total.
form_signature :: proc(form: a.Encoding) -> (sig: Operand_Signature, ok: bool) {
	sig.mode = form.mode
	sig.length = a.inst_size_from_bits(form.bits, form.mode)
	for ot, i in form.ops {
		if ot == .NONE { continue }
		if is_implicit_operand(form.enc[i]) { continue }

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

// One concrete parameter: a name and an Odin type.
Param :: struct {
	name: string,
	type: string,
}

// Flatten a signature into the ordered list of concrete (name, type) params.
// Names are derived per role so the generated source is readable and unique
// within a proc:
//   register/memory dst -> dst; subsequent -> src, src2, ...
//   immediates          -> imm, imm2, ...
//   branch targets      -> offset
//   shift kind / amount -> shift / amount (suffixed when repeated)
//   lane index          -> lane (suffixed when repeated)
//   register list mask  -> regs (suffixed when repeated)
//   RSR shift register  -> rs (suffixed when repeated)
flatten_params :: proc(sig: Operand_Signature) -> [dynamic]Param {
	out: [dynamic]Param
	src_count   := 0
	imm_count   := 0
	off_count   := 0
	shift_count := 0
	amt_count   := 0
	lane_count  := 0
	list_count  := 0
	rs_count    := 0

	uniq :: proc(base: string, n: ^int) -> string {
		defer n^ += 1
		return n^ == 0 ? strings.clone(base) : fmt.aprintf("%s%d", base, n^ + 1)
	}

	for i in 0..<sig.count {
		ot := sig.types[i]
		switch operand_class(ot) {
		case .IMM:
			append(&out, Param{uniq("imm", &imm_count), "i64"})
		case .REL:
			append(&out, Param{uniq("offset", &off_count), "i64"})
		case .MEM:
			if i == 0 {
				append(&out, Param{strings.clone("dst"), "Memory"})
			} else {
				append(&out, Param{uniq("src", &src_count), "Memory"})
			}
		case .REG:
			if i == 0 {
				append(&out, Param{strings.clone("dst"), "Register"})
			} else {
				append(&out, Param{uniq("src", &src_count), "Register"})
			}
		case .SHIFTED:
			rname := i == 0 ? strings.clone("dst") : uniq("src", &src_count)
			append(&out, Param{rname, "Register"})
			append(&out, Param{uniq("shift", &shift_count), "Shift_Type"})
			append(&out, Param{uniq("amount", &amt_count), "u8"})
		case .RSR:
			rname := i == 0 ? strings.clone("dst") : uniq("src", &src_count)
			append(&out, Param{rname, "Register"})
			append(&out, Param{uniq("shift", &shift_count), "Shift_Type"})
			append(&out, Param{uniq("rs", &rs_count), "Register"})
		case .LIST:
			append(&out, Param{uniq("regs", &list_count), "u16"})
		case .LANE_D, .LANE_Q:
			rname := i == 0 ? strings.clone("dst") : uniq("src", &src_count)
			append(&out, Param{rname, "Register"})
			append(&out, Param{uniq("lane", &lane_count), "u8"})
		}
	}
	return out
}

// Build the op_* expression for one operand, consuming params from `ps` starting
// at index `pi`; returns the next param index.
operand_expr :: proc(sb: ^strings.Builder, ot: a.Operand_Type, ps: []Param, pi: int) -> int {
	switch operand_class(ot) {
	case .REG:
		fmt.sbprintf(sb, "op_reg(%s)", ps[pi].name)
		return pi + 1
	case .IMM:
		fmt.sbprintf(sb, "op_imm(%s)", ps[pi].name)
		return pi + 1
	case .MEM:
		fmt.sbprintf(sb, "op_mem(%s)", ps[pi].name)
		return pi + 1
	case .REL:
		fmt.sbprintf(sb, "op_rel_offset(%s)", ps[pi].name)
		return pi + 1
	case .SHIFTED:
		fmt.sbprintf(sb, "op_reg_shifted(%s, %s, %s)", ps[pi].name, ps[pi+1].name, ps[pi+2].name)
		return pi + 3
	case .RSR:
		// op_reg_shifted's amount slot carries the Rs hardware number for
		// register-shifted-register forms (see pack_operand_inline / RM_A32).
		fmt.sbprintf(sb, "op_reg_shifted(%s, %s, u8(reg_hw(%s)))", ps[pi].name, ps[pi+1].name, ps[pi+2].name)
		return pi + 3
	case .LIST:
		fmt.sbprintf(sb, "op_reg_list(%s)", ps[pi].name)
		return pi + 1
	case .LANE_D:
		fmt.sbprintf(sb, "op_dpr_lane(%s, %s)", ps[pi].name, ps[pi+1].name)
		return pi + 2
	case .LANE_Q:
		fmt.sbprintf(sb, "op_qpr_lane(%s, %s)", ps[pi].name, ps[pi+1].name)
		return pi + 2
	}
	strings.write_string(sb, "{}")
	return pi + 1
}

// Type-signature key for overload-ambiguity dedup: the ordered tuple of Odin
// parameter types plus the mnemonic. Two forms with identical param-type tuples
// cannot coexist in one overload set, so we keep only the first.
type_sig_key :: proc(m: a.Mnemonic, sig: Operand_Signature) -> string {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	fmt.sbprintf(&sb, "%v|", m)
	for i in 0..<sig.count {
		for t in operand_param_types(sig.types[i]) {
			strings.write_string(&sb, t)
			strings.write_byte(&sb, ',')
		}
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
inst_body :: proc(sb: ^strings.Builder, entry: Proc_Entry, ps: []Param) {
	sig := entry.sig
	mn := fmt.tprintf("%v", entry.mnemonic)

	ops := strings.builder_make()
	defer strings.builder_destroy(&ops)
	pi := 0
	for i in 0..<4 {
		if i > 0 { strings.write_string(&ops, ", ") }
		if i < sig.count {
			pi = operand_expr(&ops, sig.types[i], ps, pi)
		} else {
			strings.write_string(&ops, "{}")
		}
	}

	fmt.sbprintf(sb, "Instruction{{mnemonic = .%s, operand_count = %d, mode = .%v, cond = 14, length = %d, ops = {{%s}}}}",
				 mn, sig.count, sig.mode, sig.length, strings.to_string(ops))
}

// ---- Emitters ---------------------------------------------------------------

write_param_list :: proc(sb: ^strings.Builder, ps: []Param) {
	for p, i in ps {
		if i > 0 { strings.write_string(sb, ", ") }
		fmt.sbprintf(sb, "%s: %s", p.name, p.type)
	}
}

// inst_ procedure (compact one line). #force_inline contextless like x86.
write_inst_proc :: proc(sb: ^strings.Builder, entry: Proc_Entry, pad: int) {
	ps := flatten_params(entry.sig)
	defer { for p in ps { delete(p.name) }; delete(ps) }

	strings.write_string(sb, entry.proc_name)
	for n := pad - len(entry.proc_name); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	strings.write_string(sb, " :: #force_inline proc \"contextless\" (")
	write_param_list(sb, ps[:])
	strings.write_string(sb, ") -> Instruction { return ")
	inst_body(sb, entry, ps[:])
	strings.write_string(sb, " }\n")
}

// emit_ procedure: append(instructions, inst_<...>(args)). Not contextless —
// append needs context. arm32 has no encoder-level emit_* helpers, so these
// simply wrap the inst_ builder.
write_emit_proc :: proc(sb: ^strings.Builder, entry: Proc_Entry, pad: int) {
	ps := flatten_params(entry.sig)
	defer { for p in ps { delete(p.name) }; delete(ps) }

	emit_name := strings.concatenate({"emit_", entry.proc_name[5:]})
	defer delete(emit_name)

	strings.write_string(sb, emit_name)
	for n := pad - len(entry.proc_name); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	strings.write_string(sb, " :: #force_inline proc(instructions: ^[dynamic]Instruction")
	for p in ps {
		fmt.sbprintf(sb, ", %s: %s", p.name, p.type)
	}
	strings.write_string(sb, ") { append(instructions, ")
	strings.write_string(sb, entry.proc_name)
	strings.write_byte(sb, '(')
	for p, i in ps {
		if i > 0 { strings.write_string(sb, ", ") }
		strings.write_string(sb, p.name)
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

	// Zero-form mnemonics (no encode forms at all) get no builder.
	zero_form: [dynamic]a.Mnemonic
	defer delete(zero_form)

	total_forms       := 0
	skipped_forms     := 0  // forms dropped for >4 operands (expected: 0)
	dropped_overload  := 0  // forms collapsed into an existing overload signature

	for m in a.Mnemonic {
		if m == .INVALID { continue }
		if m == ._COUNT  { continue }   // enum-size sentinel, not a real mnemonic

		_run := a.ENCODE_RUNS[u16(m)]
		if _run.count == 0 {
			append(&zero_form, m)
			continue
		}
		forms := a.ENCODE_FORMS[_run.start:][:_run.count]

		for form in forms {
			total_forms += 1

			sig, ok := form_signature(form)
			if !ok {
				skipped_forms += 1
				continue
			}

			name := proc_name_for(m, sig)
			if name in seen_names { delete(name); continue }

			tkey := type_sig_key(m, sig)
			if tkey in seen_type_sigs {
				// Same param-type tuple already taken for this mnemonic; a second
				// one would make the overload set ambiguous (all arm32 register
				// classes share the single `Register` type).
				dropped_overload += 1
				delete(name)
				delete(tkey)
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
		fmt.printf("Mnemonics with builders:   %d\n", len(mlist))
		fmt.printf("Procedures generated:      %d\n", total_procs)
		fmt.printf("Forms total:               %d\n", total_forms)
		fmt.printf("Forms skipped (>4 ops):    %d\n", skipped_forms)
		fmt.printf("Forms folded (overload):   %d\n", dropped_overload)
		fmt.printf("Zero-form mnemonics:       %d\n", len(zero_form))
		for zm in zero_form { fmt.printf("    %v\n", zm) }
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
// Typed mnemonic builder procedures with overloading. Each mnemonic with at
// least one encode form exposes an inst_<mnem> overload set (returns
// Instruction) and an emit_<mnem> overload set (appends to a
// ^[dynamic]Instruction). EVERY operand type is mapped to typed parameters:
// shifted / register-shifted registers (Register, Shift_Type, u8/Register),
// register lists (u16 mask), NEON D/Q lane elems (Register, u8), and every
// immediate subclass (modified-imm / barrier / endian / iflags / sysm / coproc
// / saturating / PSR field / hint / condition-operand / MVE / CDE) as i64 — the
// encoder performs the field packing. Forms whose ordered Odin parameter-type
// tuple duplicates an earlier form of the same mnemonic are folded out to keep
// each overload set unambiguous (all arm32 register classes share one Register
// type).

`)
}
