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
// shifted/extended/bitmask/sysreg). EVERY operand type is now mapped to a
// concrete Odin parameter (or parameters) and a constructor expression, so
// NO form is skipped: every mnemonic that has at least one encode form gets
// an inst_<mnem> / emit_<mnem> overload group.
//
//   PARAM-TYPE per operand category (the suffix token is a function of the
//   Odin parameter TYPE only, so two builders with the same generated name
//   necessarily have the same Odin signature -- which is exactly what Odin
//   requires for legal overload sets, and lets name-dedup == signature-dedup):
//
//     integer/SIMD scalar/NEON-vector register  -> Register / op_reg, op_v_*   (suffix r)
//     SVE Z register / Z pair / Z quad           -> u8       / op_z_*           (suffix z)
//     SVE predicate (P_REG / merge / zero / gov) -> u8       / Register(REG_P|..) (suffix p)
//     all immediates (incl ZA tile, SME slice,   -> i64      / op_imm           (suffix i)
//       patterns, bitmask, sysreg, HW, NZCV, ...)
//     PC-relative label                          -> u32      / op_label         (suffix l)
//     memory                                     -> Memory   / op_mem           (suffix m)
//     condition code                             -> Cond     / op_cond          (suffix c)
//     shifted register (W/X_SHIFTED)             -> (Register, Shift_Type, u8) / op_shifted (suffix sh)
//     extended register (W/X_EXTENDED)           -> (Register, Extend, u8)     / op_extended (suffix ex)
//
// Because Register is `distinct u16` and the SVE-register / predicate params
// are `u8`, suffix `r` (one Register), `z`/`p` (one u8) are distinct Odin
// signatures and may coexist. Two forms of one mnemonic that collapse to the
// same Odin signature (e.g. the W and X variants, or the .8B and .16B
// arrangement variants which are all `Register`) are deduplicated to a single
// builder -- the first form wins and the encoder's matcher disambiguates the
// rest at encode time by register class / size. This mirrors the original
// W/X collapse and keeps every overload group legal.
//
// Run with: odin run tools/gen_mnemonic_builders.odin -file
//
// Output: mnemonic_builders.odin (written next to the package via #directory).

import "core:fmt"
import "core:os"
import "core:strings"
import "core:slice"
import a "../"

GEN_ATTRIB :: "// rexcode  ·  Brendan Punsky (dotbmp@github), original author\n\n"

// -----------------------------------------------------------------------------
// Operand model
// -----------------------------------------------------------------------------

// Category drives the param shape (count + Odin types) and the constructor
// expression. The suffix token is derived from the Odin param TYPE so that
// equal generated names imply equal Odin signatures.
Operand_Category :: enum {
	REG,       // Register   -> op_reg / op_v_*        (1 param, suffix r)
	ZREG,      // u8         -> op_z_* / Register(REG_Z) (1 param, suffix z)
	PREG,      // u8         -> Register(REG_P)        (1 param, suffix p)
	IMM,       // i64        -> op_imm                 (1 param, suffix i)
	REL,       // u32 label  -> op_label               (1 param, suffix l)
	MEM,       // Memory     -> op_mem                 (1 param, suffix m)
	COND,      // Cond       -> op_cond                (1 param, suffix c)
	SHIFTED,   // Register + Shift_Type + u8 -> op_shifted   (3 params, suffix sh)
	EXTENDED,  // Register + Extend + u8     -> op_extended  (3 params, suffix ex)
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

// Every operand type now maps to a category -- nothing is unsupported, so no
// form is ever skipped.
operand_category :: proc(t: a.Operand_Type) -> Operand_Category {
	#partial switch t {
	case .W_REG, .X_REG, .WSP_REG, .XSP_REG,
	     .B_REG, .H_REG, .S_REG, .D_REG, .Q_REG, .V_REG,
	     .V_8B, .V_16B, .V_4H, .V_8H, .V_2S, .V_4S, .V_1D, .V_2D,
	     .V_4H_FP16, .V_8H_FP16,
	     .V_ELEM_B, .V_ELEM_H, .V_ELEM_S, .V_ELEM_D:
		return .REG
	case .Z_REG_B, .Z_REG_H, .Z_REG_S, .Z_REG_D, .Z_PAIR, .Z_QUAD:
		return .ZREG
	case .P_REG, .P_REG_MERGE, .P_REG_ZERO, .P_REG_GOV:
		return .PREG
	case .REL_26, .REL_19, .REL_14, .REL_PG21:
		return .REL
	case .MEM:
		return .MEM
	case .COND:
		return .COND
	case .W_SHIFTED, .X_SHIFTED:
		return .SHIFTED
	case .W_EXTENDED, .X_EXTENDED:
		return .EXTENDED
	case:
		return .IMM
	}
}

// Number of Odin parameters this operand contributes.
operand_param_count :: proc(t: a.Operand_Type) -> int {
	#partial switch operand_category(t) {
	case .SHIFTED, .EXTENDED:
		return 3
	}
	return 1
}

// Width byte for op_imm / op_label (informational only; the matcher checks
// operand kind, not size, so this never affects correctness).
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

// Procedure-name suffix token for an operand -- a function of the Odin param
// TYPE only (see header). This makes name-based dedup exactly equivalent to
// Odin-type dedup: two forms producing the same name also produce the same
// proc signature (which Odin forbids twice in one overload group).
operand_suffix :: proc(t: a.Operand_Type) -> string {
	switch operand_category(t) {
	case .REG:      return "r"
	case .ZREG:     return "z"
	case .PREG:     return "p"
	case .IMM:      return "i"
	case .REL:      return "l"
	case .MEM:      return "m"
	case .COND:     return "c"
	case .SHIFTED:  return "sh"
	case .EXTENDED: return "ex"
	}
	return "x"
}

// -----------------------------------------------------------------------------
// Signature building
// -----------------------------------------------------------------------------

// Build the explicit-operand signature for a form. Every non-NONE operand is
// included; only truly implicit operands (enc == .IMPL, which AArch64's tables
// never actually use) carry no param.
build_signature :: proc(form: a.Encoding) -> (sig: Operand_Signature, ok: bool) {
	for i in 0..<4 {
		op := form.ops[i]
		if op == .NONE { continue }

		// Implicit operands carry no bits and take no param.
		if form.enc[i] == .IMPL { continue }

		sig.types[sig.count] = op
		sig.count += 1
	}
	return sig, true
}

// Unique, descriptive parameter NAME(S) per operand. SHIFTED / EXTENDED
// expand to three (reg, shift/ext, amount). Returns a flat list of
// "name: type" param fragments plus, separately, the argument expressions for
// emit_ forwarding.
Param :: struct {
	decl: string,   // e.g. "dst: Register"
	name: string,   // e.g. "dst"  (for emit forwarding)
}

// Names of just the per-operand "primary" identifiers, indexed by operand
// slot. names[i][0] is the main identifier; for SHIFTED/EXTENDED, [1]/[2] are
// the shift/extend kind and amount. This is the single source of truth for
// parameter names; param_list derives the typed declarations from it so the
// declared params always match the expressions that reference them.
operand_primary_names :: proc(sig: Operand_Signature) -> [4][3]string {
	result: [4][3]string
	reg_count := 0
	imm_count := 0
	zp_count  := 0

	reg_name :: proc(i: int, reg_count: ^int) -> string {
		if i == 0 {
			return "dst"
		} else if reg_count^ == 0 {
			reg_count^ += 1
			return "src"
		}
		n := reg_count^ + 1
		reg_count^ += 1
		return fmt.tprintf("src%d", n)
	}

	for i in 0..<sig.count {
		t := sig.types[i]
		switch operand_category(t) {
		case .REG:
			result[i][0] = reg_name(i, &reg_count)
		case .ZREG, .PREG:
			// SVE Z register / predicate -> u8 hardware number.
			base := "rz" if i == 0 else fmt.tprintf("rz%d", zp_count + 1)
			zp_count += 1
			result[i][0] = base
		case .IMM:
			result[i][0] = "imm" if imm_count == 0 else fmt.tprintf("imm%d", imm_count + 1)
			imm_count += 1
		case .REL:
			result[i][0] = "label"
		case .MEM:
			result[i][0] = "mem"
		case .COND:
			result[i][0] = "cond"
		case .SHIFTED:
			rn := reg_name(i, &reg_count)
			result[i][0] = rn
			result[i][1] = fmt.tprintf("%s_shift", rn)
			result[i][2] = fmt.tprintf("%s_amount", rn)
		case .EXTENDED:
			rn := reg_name(i, &reg_count)
			result[i][0] = rn
			result[i][1] = fmt.tprintf("%s_ext", rn)
			result[i][2] = fmt.tprintf("%s_amount", rn)
		}
	}
	return result
}

// Typed parameter declarations, derived from operand_primary_names so the
// names match exactly what the op_ expressions reference.
param_list :: proc(sig: Operand_Signature) -> [dynamic]Param {
	params: [dynamic]Param
	names := operand_primary_names(sig)
	for i in 0..<sig.count {
		t := sig.types[i]
		switch operand_category(t) {
		case .REG:
			append(&params, Param{decl = fmt.tprintf("%s: Register", names[i][0]), name = names[i][0]})
		case .ZREG, .PREG:
			append(&params, Param{decl = fmt.tprintf("%s: u8", names[i][0]), name = names[i][0]})
		case .IMM:
			append(&params, Param{decl = fmt.tprintf("%s: i64", names[i][0]), name = names[i][0]})
		case .REL:
			append(&params, Param{decl = fmt.tprintf("%s: u32", names[i][0]), name = names[i][0]})
		case .MEM:
			append(&params, Param{decl = fmt.tprintf("%s: Memory", names[i][0]), name = names[i][0]})
		case .COND:
			append(&params, Param{decl = fmt.tprintf("%s: Cond", names[i][0]), name = names[i][0]})
		case .SHIFTED:
			append(&params, Param{decl = fmt.tprintf("%s: Register",    names[i][0]), name = names[i][0]})
			append(&params, Param{decl = fmt.tprintf("%s: Shift_Type", names[i][1]), name = names[i][1]})
			append(&params, Param{decl = fmt.tprintf("%s: u8",         names[i][2]), name = names[i][2]})
		case .EXTENDED:
			append(&params, Param{decl = fmt.tprintf("%s: Register", names[i][0]), name = names[i][0]})
			append(&params, Param{decl = fmt.tprintf("%s: Extend",   names[i][1]), name = names[i][1]})
			append(&params, Param{decl = fmt.tprintf("%s: u8",       names[i][2]), name = names[i][2]})
		}
	}
	return params
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
// op_ expression for a single operand (uses the form's exact operand type so
// the produced encoding is valid for the kept form).
// -----------------------------------------------------------------------------

write_operand_expr :: proc(sb: ^strings.Builder, t: a.Operand_Type, names: [3]string) {
	#partial switch operand_category(t) {
	case .REG:
		#partial switch t {
		case .V_8B:  fmt.sbprintf(sb, "op_v_8b(u8(reg_hw(%s)))",  names[0])
		case .V_16B: fmt.sbprintf(sb, "op_v_16b(u8(reg_hw(%s)))", names[0])
		case .V_4H, .V_4H_FP16: fmt.sbprintf(sb, "op_v_4h(u8(reg_hw(%s)))", names[0])
		case .V_8H, .V_8H_FP16: fmt.sbprintf(sb, "op_v_8h(u8(reg_hw(%s)))", names[0])
		case .V_2S:  fmt.sbprintf(sb, "op_v_2s(u8(reg_hw(%s)))",  names[0])
		case .V_4S:  fmt.sbprintf(sb, "op_v_4s(u8(reg_hw(%s)))",  names[0])
		case .V_1D:  fmt.sbprintf(sb, "op_v_1d(u8(reg_hw(%s)))",  names[0])
		case .V_2D:  fmt.sbprintf(sb, "op_v_2d(u8(reg_hw(%s)))",  names[0])
		case:        fmt.sbprintf(sb, "op_reg(%s)", names[0])
		}
	case .ZREG:
		#partial switch t {
		case .Z_REG_B: fmt.sbprintf(sb, "op_z_b(%s)", names[0])
		case .Z_REG_H: fmt.sbprintf(sb, "op_z_h(%s)", names[0])
		case .Z_REG_S: fmt.sbprintf(sb, "op_z_s(%s)", names[0])
		case .Z_REG_D: fmt.sbprintf(sb, "op_z_d(%s)", names[0])
		case:          fmt.sbprintf(sb, "op_reg(Register(REG_Z | (u16(%s) & 0x1F)))", names[0])  // Z_PAIR / Z_QUAD
		}
	case .PREG:
		fmt.sbprintf(sb, "op_reg(Register(REG_P | (u16(%s) & 0xF)))", names[0])
	case .IMM:
		fmt.sbprintf(sb, "op_imm(%s, %d)", names[0], operand_imm_size(t))
	case .REL:
		fmt.sbprintf(sb, "op_label(%s, 4)", names[0])
	case .MEM:
		fmt.sbprintf(sb, "op_mem(%s)", names[0])
	case .COND:
		fmt.sbprintf(sb, "op_cond(%s)", names[0])
	case .SHIFTED:
		fmt.sbprintf(sb, "op_shifted(%s, %s, %s)", names[0], names[1], names[2])
	case .EXTENDED:
		fmt.sbprintf(sb, "op_extended(%s, %s, %s)", names[0], names[1], names[2])
	}
}

// Pattern string of operand categories (one token each), used to pick a shape
// helper from instructions.odin where one fits cleanly. Shifted/extended use
// multi-char tokens so they never collide with the simple ones.
pattern_string :: proc(sig: Operand_Signature) -> string {
	if sig.count == 0 { return "none" }
	sb := strings.builder_make()
	for i in 0..<sig.count {
		if i > 0 { strings.write_byte(&sb, '_') }
		strings.write_string(&sb, operand_suffix(sig.types[i]))
	}
	return strings.to_string(sb)
}

// True when every operand maps to one of the plain constructors
// (op_reg/op_imm/op_mem/op_label) that the hand-written shape helpers use.
// V-arrangement / Z / P / shifted / extended forms must use the direct
// Instruction{} fallback instead, since the helpers would build the wrong
// constructor.
uses_plain_constructors :: proc(sig: Operand_Signature) -> bool {
	for i in 0..<sig.count {
		t := sig.types[i]
		#partial switch operand_category(t) {
		case .REG:
			#partial switch t {
			case .V_8B, .V_16B, .V_4H, .V_8H, .V_2S, .V_4S, .V_1D, .V_2D,
			     .V_4H_FP16, .V_8H_FP16:
				return false   // needs op_v_*
			}
		case .IMM, .REL, .MEM, .COND:
			// fine
		case:
			return false       // ZREG / PREG / SHIFTED / EXTENDED
		}
	}
	return true
}

// -----------------------------------------------------------------------------
// inst_ body
// -----------------------------------------------------------------------------

write_inst_body :: proc(sb: ^strings.Builder, entry: Proc_Entry) {
	sig := entry.sig
	pnames := operand_primary_names(sig)
	pattern := pattern_string(sig)
	mstr := fmt.aprintf("%v", entry.mnemonic)
	defer delete(mstr)

	// Prefer arm64 shape helpers where the operand kinds line up exactly AND
	// every operand uses a plain constructor.
	if uses_plain_constructors(sig) {
		switch pattern {
		case "none":
			fmt.sbprintf(sb, "inst_none(.%s)", mstr)
			return
		case "r":
			fmt.sbprintf(sb, "inst_r(.%s, %s)", mstr, pnames[0][0])
			return
		case "r_r":
			fmt.sbprintf(sb, "inst_r_r(.%s, %s, %s)", mstr, pnames[0][0], pnames[1][0])
			return
		case "r_r_r":
			fmt.sbprintf(sb, "inst_r_r_r(.%s, %s, %s, %s)", mstr, pnames[0][0], pnames[1][0], pnames[2][0])
			return
		case "r_r_r_r":
			fmt.sbprintf(sb, "inst_r_r_r_r(.%s, %s, %s, %s, %s)", mstr, pnames[0][0], pnames[1][0], pnames[2][0], pnames[3][0])
			return
		case "r_i":
			fmt.sbprintf(sb, "inst_r_i(.%s, %s, %s)", mstr, pnames[0][0], pnames[1][0])
			return
		case "r_r_i":
			fmt.sbprintf(sb, "inst_r_r_i(.%s, %s, %s, %s)", mstr, pnames[0][0], pnames[1][0], pnames[2][0])
			return
		case "r_m":
			fmt.sbprintf(sb, "inst_ldst(.%s, %s, %s)", mstr, pnames[0][0], pnames[1][0])
			return
		case "r_r_m":
			fmt.sbprintf(sb, "inst_ldp_stp(.%s, %s, %s, %s)", mstr, pnames[0][0], pnames[1][0], pnames[2][0])
			return
		case "l":
			fmt.sbprintf(sb, "inst_branch(.%s, %s)", mstr, pnames[0][0])
			return
		}
	}

	// Fallback: direct Instruction{} construction (always correct).
	write_inst_fallback(sb, entry)
}

write_inst_fallback :: proc(sb: ^strings.Builder, entry: Proc_Entry) {
	sig := entry.sig
	pnames := operand_primary_names(sig)
	mstr := fmt.aprintf("%v", entry.mnemonic)
	defer delete(mstr)

	fmt.sbprintf(sb, "Instruction{{mnemonic = .%s, operand_count = %d, length = 4, ops = {{", mstr, sig.count)
	for i in 0..<4 {
		if i > 0 { strings.write_string(sb, ", ") }
		if i < sig.count {
			write_operand_expr(sb, sig.types[i], pnames[i])
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
	params := param_list(entry.sig)
	defer delete(params)

	pstr := strings.builder_make()
	defer strings.builder_destroy(&pstr)
	for p, i in params {
		if i > 0 { strings.write_string(&pstr, ", ") }
		strings.write_string(&pstr, p.decl)
	}

	strings.write_string(sb, entry.proc_name)
	for n := pad - len(entry.proc_name); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	strings.write_string(sb, " :: #force_inline proc \"contextless\" (")
	strings.write_string(sb, strings.to_string(pstr))
	strings.write_string(sb, ") -> Instruction { return ")
	write_inst_body(sb, entry)
	strings.write_string(sb, " }\n")
}

write_emit_proc :: proc(sb: ^strings.Builder, entry: Proc_Entry, pad: int) {
	params := param_list(entry.sig)
	defer delete(params)

	emit_name := strings.concatenate({"emit_", entry.proc_name[5:]})
	defer delete(emit_name)

	pstr := strings.builder_make()
	defer strings.builder_destroy(&pstr)
	strings.write_string(&pstr, "instructions: ^[dynamic]Instruction")
	for p in params {
		fmt.sbprintf(&pstr, ", %s", p.decl)
	}

	astr := strings.builder_make()
	defer strings.builder_destroy(&astr)
	for p, i in params {
		if i > 0 { strings.write_string(&astr, ", ") }
		strings.write_string(&astr, p.name)
	}

	strings.write_string(sb, emit_name)
	for n := pad - len(entry.proc_name); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	strings.write_string(sb, " :: #force_inline proc(")
	strings.write_string(sb, strings.to_string(pstr))
	strings.write_string(sb, ") { append(instructions, ")
	strings.write_string(sb, entry.proc_name)
	strings.write_byte(sb, '(')
	strings.write_string(sb, strings.to_string(astr))
	strings.write_string(sb, ")) }\n")
}

// -----------------------------------------------------------------------------
// Driver
// -----------------------------------------------------------------------------

// Lowercased mnemonic names whose generated overload group would collide with
// a generic shape helper already defined in instructions.odin. Those helpers
// are not per-mnemonic (they take the Mnemonic as a parameter), so the
// generator must not also define a group of the same name.
RESERVED_MNEMONIC_NAMES :: []string{
	"none", "r", "branch", "ldst", "mov_imm",
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

	zero_form_mnemonics: [dynamic]a.Mnemonic
	defer delete(zero_form_mnemonics)

	form_bearing := 0

	seen_proc_names: map[string]bool
	defer delete(seen_proc_names)

	for mnemonic in a.Mnemonic {
		if mnemonic == .INVALID { continue }

		_run := a.ENCODE_RUNS[u16(mnemonic)]
		forms := a.ENCODE_FORMS[_run.start:][:_run.count]
		if len(forms) == 0 {
			append(&zero_form_mnemonics, mnemonic)
			continue
		}
		form_bearing += 1

		// Skip mnemonics whose overload-group name collides with a generic
		// hand-written helper in instructions.odin.
		if is_reserved_mnemonic(mnemonic_to_lower(mnemonic)) { continue }

		for form in forms {
			sig, ok := build_signature(form)
			if !ok { continue }

			proc_name := generate_proc_name(mnemonic, sig)
			// Dedup by generated name. Because the suffix is a function of the
			// Odin param TYPE, equal names mean equal Odin signatures, so this
			// collapses W/X (and same-shape arrangement) variants into one
			// builder; the encoder's matcher disambiguates at encode time by
			// register class / size. (Two same-typed procs in one overload
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
		fmt.printf("Form-bearing mnemonics:        %d\n", form_bearing)
		fmt.printf("Mnemonics with builder groups: %d\n", len(mnemonic_list))
		fmt.printf("Reserved (generic helper) skip:%d\n", form_bearing - len(mnemonic_list))
		total := 0
		for m in mnemonic_list { total += len(procs_by_mnemonic[m]) }
		fmt.printf("Total inst_ procedures:        %d\n", total)
		fmt.printf("Zero-form (decode-only) mnemonics: %d\n", len(zero_form_mnemonics))
		for m in zero_form_mnemonics {
			fmt.printf("  %v\n", m)
		}
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
// Typed mnemonic builder procedures with overloading. Every mnemonic that has
// at least one encode form gets an inst_* (returns Instruction) and emit_*
// (appends to a [dynamic]Instruction) overload group covering all of its
// distinct operand SHAPES. Forms that share an Odin signature (e.g. the W/X
// variants, or NEON arrangement / SVE element-size variants which are all
// passed as a Register/u8) collapse to one builder; the encoder's matcher
// disambiguates by register class / size at encode time.

`)
}
