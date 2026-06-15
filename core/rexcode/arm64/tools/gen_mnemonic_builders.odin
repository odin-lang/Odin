// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package main

// =============================================================================
// AArch64 Mnemonic Builder Generator
// =============================================================================
//
// This script generates mnemonic_builders.odin by iterating the encoder's
// ENCODE_RUNS / ENCODE_FORMS tables and emitting typed builder procedures
// (inst_* returning Instruction, emit_* appending to a [dynamic]Instruction)
// with per-mnemonic overload groups.
//
// AArch64 has ~50 operand types, many exotic (SVE/SME/NEON-arrangement/
// shifted/extended/bitmask/sysreg). We only emit a builder for a form when
// EVERY one of its operands is in the cleanly-constructible "supported" set
// below; any form touching an unsupported operand type is skipped wholesale.
//
//   COVERED  (param type / op_ expr):
//     W_REG X_REG WSP_REG XSP_REG  -> Register / op_reg
//     B_REG H_REG S_REG D_REG Q_REG V_REG -> Register / op_reg
//     IMM_12 IMM_16 IMM_8 IMM_6 IMM_5 IMM_4 IMM_3 IMM_2 -> i64 / op_imm
//     HW_SHIFT NZCV_IMM           -> i64 / op_imm
//     REL_26 REL_19 REL_14 REL_PG21 -> u32 (label id) / op_label
//     MEM                          -> Memory / op_mem
//     COND                         -> Cond / op_cond
//
//   SKIPPED (no clean single-value constructor):
//     W_SHIFTED X_SHIFTED W_EXTENDED X_EXTENDED BITMASK_IMM SYS_REG
//     LSE_SIZE LDRAA_IMM10 LSL_SHIFT_W LSL_SHIFT_X ROR_SHIFT
//     FCMLA_ROT FCADD_ROT SVE_PRFOP SME_PATTERN SVE_PATTERN
//     all SVE  : Z_REG_B/H/S/D P_REG P_REG_MERGE P_REG_ZERO P_REG_GOV Z_PAIR Z_QUAD
//     all SME  : ZA_TILE_B/H/S/D/Q SME_SLICE_B/H/W/D/Q
//     all NEON arrangement/lane: V_8B V_16B V_4H V_8H V_2S V_4S V_1D V_2D
//                                V_4H_FP16 V_8H_FP16 V_ELEM_B/H/S/D
//
// Run with: odin run tools/gen_mnemonic_builders.odin -file
//
// Output: mnemonic_builders.odin (written to current directory; move to package root)

import "core:fmt"
import "core:os"
import "core:strings"
import "core:slice"
import a "../"

GEN_ATTRIB :: "// rexcode  ·  Brendan Punsky (dotbmp@github), original author\n\n"

// -----------------------------------------------------------------------------
// Operand model
// -----------------------------------------------------------------------------

// Category drives both the param type and the op_ expression.
Operand_Category :: enum {
	REG,    // Register   -> op_reg
	IMM,    // i64        -> op_imm
	REL,    // u32 label  -> op_label
	MEM,    // Memory     -> op_mem
	COND,   // Cond       -> op_cond
}

Operand_Signature :: struct {
	types: [4]a.Operand_Type,
	count: int,
}

Proc_Entry :: struct {
	mnemonic:  a.Mnemonic,
	sig:       Operand_Signature,
	proc_name: string,
}

mnemonic_to_lower :: proc(m: a.Mnemonic) -> string {
	name := fmt.tprintf("%v", m)
	return strings.to_lower(name)
}

// Is this operand type one we can build a clean single-value param for?
is_supported_operand :: proc(t: a.Operand_Type) -> bool {
	#partial switch t {
	case .W_REG, .X_REG, .WSP_REG, .XSP_REG,
	     .B_REG, .H_REG, .S_REG, .D_REG, .Q_REG, .V_REG:
		return true
	case .IMM_12, .IMM_16, .IMM_8, .IMM_6, .IMM_5, .IMM_4, .IMM_3, .IMM_2,
	     .HW_SHIFT, .NZCV_IMM:
		return true
	case .REL_26, .REL_19, .REL_14, .REL_PG21:
		return true
	case .MEM:
		return true
	case .COND:
		return true
	}
	return false
}

operand_category :: proc(t: a.Operand_Type) -> Operand_Category {
	#partial switch t {
	case .W_REG, .X_REG, .WSP_REG, .XSP_REG,
	     .B_REG, .H_REG, .S_REG, .D_REG, .Q_REG, .V_REG:
		return .REG
	case .REL_26, .REL_19, .REL_14, .REL_PG21:
		return .REL
	case .MEM:
		return .MEM
	case .COND:
		return .COND
	case:
		return .IMM
	}
}

// Odin parameter type for an operand.
operand_param_type :: proc(t: a.Operand_Type) -> string {
	switch operand_category(t) {
	case .REG:  return "Register"
	case .IMM:  return "i64"
	case .REL:  return "u32"
	case .MEM:  return "Memory"
	case .COND: return "Cond"
	}
	return "i64"
}

// Width byte for op_imm / op_label (informational only; the matcher checks
// only operand kind, not size, so this never affects correctness).
operand_imm_size :: proc(t: a.Operand_Type) -> u8 {
	#partial switch t {
	case .IMM_16:        return 2
	case .IMM_12:        return 2
	case .IMM_8:         return 1
	case .IMM_6, .IMM_5, .IMM_4, .IMM_3, .IMM_2, .HW_SHIFT, .NZCV_IMM:
		return 1
	}
	return 4
}

// Procedure-name suffix token for an operand.
// Procedure-name suffix token. Because AArch64 has no typed register enums,
// every register operand maps to the same Odin param type (`Register`) and
// every plain immediate to `i64`. We therefore name by PARAM-TYPE CATEGORY
// (r/i/l/m/c), not by operand subtype. This makes name-based dedup exactly
// equivalent to Odin-type dedup: two forms that produce the same name also
// produce the same proc signature (which Odin forbids in one overload group).
operand_suffix :: proc(t: a.Operand_Type) -> string {
	switch operand_category(t) {
	case .REG:  return "r"
	case .IMM:  return "i"
	case .REL:  return "l"
	case .MEM:  return "m"
	case .COND: return "c"
	}
	return "x"
}

// -----------------------------------------------------------------------------
// Signature building
// -----------------------------------------------------------------------------

// Build the explicit-operand signature for a form, returning ok=false when any
// non-NONE operand is unsupported (the whole form is then skipped).
build_signature :: proc(form: a.Encoding) -> (sig: Operand_Signature, ok: bool) {
	for i in 0..<4 {
		op := form.ops[i]
		if op == .NONE { continue }

		// Implicit operands carry no bits and take no param.
		if form.enc[i] == .IMPL { continue }

		if !is_supported_operand(op) {
			return {}, false
		}

		sig.types[sig.count] = op
		sig.count += 1
	}
	return sig, true
}

// Unique, descriptive parameter names per operand.
param_names :: proc(sig: Operand_Signature) -> [4]string {
	result: [4]string
	reg_count := 0
	imm_count := 0

	for i in 0..<sig.count {
		t := sig.types[i]
		switch operand_category(t) {
		case .REG:
			if i == 0 {
				result[i] = "dst"
			} else if reg_count == 0 {
				result[i] = "src"
				reg_count += 1
			} else {
				result[i] = fmt.tprintf("src%d", reg_count + 1)
				reg_count += 1
			}
		case .IMM:
			if imm_count == 0 {
				result[i] = "imm"
			} else {
				result[i] = fmt.tprintf("imm%d", imm_count + 1)
			}
			imm_count += 1
		case .REL:
			result[i] = "label"
		case .MEM:
			result[i] = "mem"
		case .COND:
			result[i] = "cond"
		}
	}
	return result
}

// Generate the proc name (with inst_ prefix) from mnemonic + signature.
generate_proc_name :: proc(mnemonic: a.Mnemonic, sig: Operand_Signature) -> string {
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
// op_ expression for a single operand
// -----------------------------------------------------------------------------

write_operand_expr :: proc(sb: ^strings.Builder, t: a.Operand_Type, name: string) {
	switch operand_category(t) {
	case .REG:
		fmt.sbprintf(sb, "op_reg(%s)", name)
	case .IMM:
		fmt.sbprintf(sb, "op_imm(%s, %d)", name, operand_imm_size(t))
	case .REL:
		fmt.sbprintf(sb, "op_label(%s, 4)", name)
	case .MEM:
		fmt.sbprintf(sb, "op_mem(%s)", name)
	case .COND:
		fmt.sbprintf(sb, "op_cond(%s)", name)
	}
}

// Pattern string of operand categories, e.g. "r_r_i", used to pick a shape
// helper from instructions.odin where one fits cleanly.
pattern_string :: proc(sig: Operand_Signature) -> string {
	if sig.count == 0 { return "none" }
	sb := strings.builder_make()
	for i in 0..<sig.count {
		if i > 0 { strings.write_byte(&sb, '_') }
		switch operand_category(sig.types[i]) {
		case .REG:  strings.write_byte(&sb, 'r')
		case .IMM:  strings.write_byte(&sb, 'i')
		case .REL:  strings.write_byte(&sb, 'l')
		case .MEM:  strings.write_byte(&sb, 'm')
		case .COND: strings.write_byte(&sb, 'c')
		}
	}
	return strings.to_string(sb)
}

// -----------------------------------------------------------------------------
// inst_ body
// -----------------------------------------------------------------------------

write_inst_body :: proc(sb: ^strings.Builder, entry: Proc_Entry) {
	sig := entry.sig
	names := param_names(sig)
	pattern := pattern_string(sig)
	mstr := fmt.aprintf("%v", entry.mnemonic)
	defer delete(mstr)

	// Prefer arm64 shape helpers where the operand kinds line up exactly.
	switch pattern {
	case "none":
		fmt.sbprintf(sb, "inst_none(.%s)", mstr)
		return
	case "r":
		fmt.sbprintf(sb, "inst_r(.%s, %s)", mstr, names[0])
		return
	case "r_r":
		fmt.sbprintf(sb, "inst_r_r(.%s, %s, %s)", mstr, names[0], names[1])
		return
	case "r_r_r":
		fmt.sbprintf(sb, "inst_r_r_r(.%s, %s, %s, %s)", mstr, names[0], names[1], names[2])
		return
	case "r_r_r_r":
		fmt.sbprintf(sb, "inst_r_r_r_r(.%s, %s, %s, %s, %s)", mstr, names[0], names[1], names[2], names[3])
		return
	case "r_i":
		fmt.sbprintf(sb, "inst_r_i(.%s, %s, %s)", mstr, names[0], names[1])
		return
	case "r_r_i":
		fmt.sbprintf(sb, "inst_r_r_i(.%s, %s, %s, %s)", mstr, names[0], names[1], names[2])
		return
	case "r_m":
		fmt.sbprintf(sb, "inst_ldst(.%s, %s, %s)", mstr, names[0], names[1])
		return
	case "r_r_m":
		fmt.sbprintf(sb, "inst_ldp_stp(.%s, %s, %s, %s)", mstr, names[0], names[1], names[2])
		return
	case "l":
		fmt.sbprintf(sb, "inst_branch(.%s, %s)", mstr, names[0])
		return
	case "r_l":
		fmt.sbprintf(sb, "inst_cbz(.%s, %s, %s)", mstr, names[0], names[1])
		return
	}

	// Fallback: direct Instruction{} construction (always correct).
	write_inst_fallback(sb, entry)
}

write_inst_fallback :: proc(sb: ^strings.Builder, entry: Proc_Entry) {
	sig := entry.sig
	names := param_names(sig)
	mstr := fmt.aprintf("%v", entry.mnemonic)
	defer delete(mstr)

	fmt.sbprintf(sb, "Instruction{{mnemonic = .%s, operand_count = %d, length = 4, ops = {{", mstr, sig.count)
	for i in 0..<4 {
		if i > 0 { strings.write_string(sb, ", ") }
		if i < sig.count {
			write_operand_expr(sb, sig.types[i], names[i])
		} else {
			strings.write_string(sb, "{}")
		}
	}
	strings.write_string(sb, "}}")
}

// -----------------------------------------------------------------------------
// Procedure emission
// -----------------------------------------------------------------------------

write_proc :: proc(sb: ^strings.Builder, entry: Proc_Entry, pad: int) {
	sig := entry.sig
	names := param_names(sig)

	// params
	params := strings.builder_make()
	defer strings.builder_destroy(&params)
	for i in 0..<sig.count {
		if i > 0 { strings.write_string(&params, ", ") }
		fmt.sbprintf(&params, "%s: %s", names[i], operand_param_type(sig.types[i]))
	}

	strings.write_string(sb, entry.proc_name)
	for n := pad - len(entry.proc_name); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	strings.write_string(sb, " :: #force_inline proc \"contextless\" (")
	strings.write_string(sb, strings.to_string(params))
	strings.write_string(sb, ") -> Instruction { return ")
	write_inst_body(sb, entry)
	strings.write_string(sb, " }\n")
}

write_emit_proc :: proc(sb: ^strings.Builder, entry: Proc_Entry, pad: int) {
	sig := entry.sig
	names := param_names(sig)

	emit_name := strings.concatenate({"emit_", entry.proc_name[5:]})
	defer delete(emit_name)

	// params (instructions + originals)
	params := strings.builder_make()
	defer strings.builder_destroy(&params)
	strings.write_string(&params, "instructions: ^[dynamic]Instruction")
	for i in 0..<sig.count {
		fmt.sbprintf(&params, ", %s: %s", names[i], operand_param_type(sig.types[i]))
	}

	// call args (forward originals)
	args := strings.builder_make()
	defer strings.builder_destroy(&args)
	for i in 0..<sig.count {
		if i > 0 { strings.write_string(&args, ", ") }
		strings.write_string(&args, names[i])
	}

	strings.write_string(sb, emit_name)
	for n := pad - len(entry.proc_name); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	strings.write_string(sb, " :: #force_inline proc(")
	strings.write_string(sb, strings.to_string(params))
	strings.write_string(sb, ") { append(instructions, ")
	strings.write_string(sb, entry.proc_name)
	strings.write_byte(sb, '(')
	strings.write_string(sb, strings.to_string(args))
	strings.write_string(sb, ")) }\n")
}

// -----------------------------------------------------------------------------
// Driver
// -----------------------------------------------------------------------------

// Lowercased mnemonic names whose generated overload group (inst_<name> /
// emit_<name>) would collide with a hand-written shape helper already defined
// in instructions.odin. Those mnemonics already have dedicated typed builders,
// so we skip generating overloads for them entirely.
RESERVED_MNEMONIC_NAMES :: []string{
	"none", "r", "branch", "ldst", "mov_imm",  // inst_none/inst_r/inst_branch/inst_ldst/inst_mov_imm
	"b_cond", "cbz", "tbz", "csel",            // inst_b_cond/inst_cbz/inst_tbz/inst_csel
}

is_reserved_mnemonic :: proc(name: string) -> bool {
	for r in RESERVED_MNEMONIC_NAMES {
		if name == r { return true }
	}
	return false
}

main :: proc() {
	fmt.println("Generating AArch64 mnemonic builders from ENCODE_FORMS...")

	sb := strings.builder_make()
	generate_header(&sb)

	procs_by_mnemonic: map[a.Mnemonic][dynamic]Proc_Entry
	defer {
		for _, v in procs_by_mnemonic { delete(v) }
		delete(procs_by_mnemonic)
	}

	seen_proc_names: map[string]bool
	defer delete(seen_proc_names)

	for mnemonic in a.Mnemonic {
		if mnemonic == .INVALID { continue }

		// Skip mnemonics whose overload-group name collides with a hand-written
		// helper in instructions.odin (they already have typed builders).
		if is_reserved_mnemonic(mnemonic_to_lower(mnemonic)) { continue }

		_run := a.ENCODE_RUNS[u16(mnemonic)]
		forms := a.ENCODE_FORMS[_run.start:][:_run.count]
		if len(forms) == 0 { continue }

		for form in forms {
			sig, ok := build_signature(form)
			if !ok { continue }

			proc_name := generate_proc_name(mnemonic, sig)
			// Dedup by generated name. Because suffixes are param-type
			// categories, equal names mean equal Odin signatures, so this
			// collapses W/X (and other same-shape) variants into one generic-
			// Register builder; the encoder's matcher disambiguates at encode
			// time by register class. (Two same-typed procs in one overload
			// group is also a hard Odin error, so this dedup is required.)
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

	// Sorted mnemonic list for deterministic output.
	mnemonic_list: [dynamic]a.Mnemonic
	defer delete(mnemonic_list)
	for m in procs_by_mnemonic { append(&mnemonic_list, m) }
	slice.sort_by(mnemonic_list[:], proc(x, y: a.Mnemonic) -> bool {
		return int(x) < int(y)
	})

	// Name padding for aligned output.
	pad := 0
	for m in mnemonic_list {
		for e in procs_by_mnemonic[m] { pad = max(pad, len(e.proc_name)) }
	}

	strings.write_string(&sb, `// =============================================================================
// Individual Typed Builder Procedures
// =============================================================================

`)
	for m in mnemonic_list {
		procs := procs_by_mnemonic[m]
		for e in procs { write_proc(&sb, e, pad) }
		for e in procs { write_emit_proc(&sb, e, pad) }
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

		// inst_ group
		strings.write_string(&sb, "inst_")
		strings.write_string(&sb, mlow)
		for n := pad - len(mlow); n > 0; n -= 1 { strings.write_byte(&sb, ' ') }
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

		// emit_ group
		strings.write_string(&sb, "emit_")
		strings.write_string(&sb, mlow)
		for n := pad - len(mlow); n > 0; n -= 1 { strings.write_byte(&sb, ' ') }
		if len(procs) == 1 {
			emit_name := strings.concatenate({"emit_", procs[0].proc_name[5:]})
			defer delete(emit_name)
			fmt.sbprintf(&sb, " :: %s\n", emit_name)
		} else {
			strings.write_string(&sb, " :: proc{ ")
			for e, i in procs {
				if i > 0 { strings.write_string(&sb, ", ") }
				emit_name := strings.concatenate({"emit_", e.proc_name[5:]})
				defer delete(emit_name)
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
	} else {
		fmt.eprintln("Failed to write mnemonic_builders.odin")
	}
}

generate_header :: proc(sb: ^strings.Builder) {
	strings.write_string(sb, `package rexcode_arm64

// =============================================================================
// GENERATED FILE - DO NOT EDIT
// =============================================================================
//
// Generated by tools/gen_mnemonic_builders.odin from ENCODE_FORMS.
// Regenerate with: odin run arm64/tools/gen_mnemonic_builders.odin -file
//
// Typed mnemonic builder procedures with overloading. Each supported mnemonic
// form gets an inst_* (returns Instruction) and emit_* (appends to a
// [dynamic]Instruction). Forms touching exotic operand types
// (SVE/SME/NEON-arrangement/shifted/extended/bitmask/sysreg/...) are skipped.

`)
}
