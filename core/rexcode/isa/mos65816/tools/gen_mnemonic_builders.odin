// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package main

// =============================================================================
// Mnemonic Builder Generator (W65C816S)
// =============================================================================
//
// Generates mnemonic_builders.odin by iterating the encoder's ENCODE_FORMS and
// emitting typed builder procedures with overloading per mnemonic. Mirrors the
// x86 generator (core/rexcode/x86/tools/gen_mnemonic_builders.odin) but for the
// 65816's opcode/addressing-mode model.
//
// The 65816 is far simpler than x86 here: every encode form carries at most one
// explicit operand (one immediate, one PC-relative target, or one memory
// operand whose addressing mode is baked into the Memory value), except the two
// block-move mnemonics (MVN/MVP) which take a (src_bank, dst_bank) pair. So we
// collapse each mnemonic's forms by operand *category* and emit one overload per
// distinct category.
//
// Operand handling:
//   * Immediates  -> i64 param; op_imm8 (IMM_8/IMM_M8/IMM_X8) or op_imm16
//                    (IMM_M16/IMM_X16) via inst_i8 / inst_i16.
//   * REL         -> u32 label-id param via inst_rel      (op_label size 1).
//   * REL_LONG    -> u32 label-id param via inst_rel_long (op_label size 2).
//   * MEM_*       -> a single Memory param via inst_m; op_mem(m) reads the
//                    addressing mode straight out of the Memory value, so every
//                    MEM_* form maps to the SAME builder. Callers pick the mode
//                    with the mem_* constructors (mem_dp, mem_abs_x, mem_long...).
//   * A_IMPL      -> accumulator-implied ops (ASL/DEC/INC/LSR/ROL/ROR); emitted
//                    as a distinct `_a` overload via inst_a (op_reg(A)).
//   * BANK_*      -> MVN/MVP block move; (src_bank, dst_bank: u8) via
//                    inst_block_move (caller-natural src,dst order).
//
// Run with: odin run tools/gen_mnemonic_builders.odin -file
// Output:   mnemonic_builders.odin (written to cwd; move to package root)

import "core:fmt"
import "core:os"
import "core:strings"
import "core:slice"
import m816 "../"

GEN_ATTRIB :: "// rexcode  ·  Brendan Punsky (dotbmp@github), original author\n\n"

// Category of an explicit operand signature for a single encode form.
Sig_Kind :: enum {
	NONE,        // no explicit operand (RTS, NOP, ...)
	ACC,         // accumulator-implied (A_IMPL)
	IMM8,        // 8-bit immediate
	IMM16,       // 16-bit immediate
	REL,         // 8-bit PC-relative (label)
	REL_LONG,    // 16-bit PC-relative (label)
	MEM,         // memory operand (mode carried by Memory)
	BLOCK_MOVE,  // MVN/MVP: src_bank, dst_bank
}

Proc_Entry :: struct {
	mnemonic:  m816.Mnemonic,
	kind:      Sig_Kind,
	proc_name: string, // includes the inst_ prefix
}

mnemonic_to_lower :: proc(m: m816.Mnemonic) -> string {
	name := fmt.tprintf("%v", m)
	return strings.to_lower(name)
}

// Classify a form's ops (after stripping NONE) into a single Sig_Kind.
// ok=false means we cannot cleanly build this form and skip it.
classify_form :: proc(enc: m816.Encoding) -> (kind: Sig_Kind, ok: bool) {
	// Collect explicit operand types.
	ops: [4]m816.Operand_Type
	n := 0
	for op in enc.ops {
		if op == .NONE { continue }
		ops[n] = op
		n += 1
	}

	if n == 0 {
		return .NONE, true
	}

	// Block move is the only two-operand shape.
	if n == 2 && ops[0] == .BANK_SRC && ops[1] == .BANK_DST {
		return .BLOCK_MOVE, true
	}

	if n != 1 {
		// Unexpected multi-operand shape; skip and report.
		return .NONE, false
	}

	#partial switch ops[0] {
	case .A_IMPL:
		return .ACC, true
	case .IMM_8, .IMM_M8, .IMM_X8:
		return .IMM8, true
	case .IMM_M16, .IMM_X16:
		return .IMM16, true
	case .REL:
		return .REL, true
	case .REL_LONG:
		return .REL_LONG, true
	case .MEM_DP, .MEM_DP_X, .MEM_DP_Y,
	     .MEM_DP_IND, .MEM_DP_IND_X, .MEM_DP_IND_Y,
	     .MEM_DP_IND_LONG, .MEM_DP_IND_LONG_Y,
	     .MEM_ABS, .MEM_ABS_X, .MEM_ABS_Y,
	     .MEM_ABS_IND, .MEM_ABS_IND_LONG, .MEM_ABS_IND_X,
	     .MEM_LONG, .MEM_LONG_X,
	     .MEM_SR, .MEM_SR_IND_Y:
		return .MEM, true
	}

	// BANK_SRC/BANK_DST seen alone, or anything unmapped: skip + report.
	return .NONE, false
}

// Suffix appended to inst_<mnem> for this category (without leading underscore).
kind_suffix :: proc(kind: Sig_Kind) -> string {
	switch kind {
	case .NONE:       return "none"
	case .ACC:        return "a"
	case .IMM8:       return "imm8"
	case .IMM16:      return "imm16"
	case .REL:        return "rel"
	case .REL_LONG:   return "rel_long"
	case .MEM:        return "mem"
	case .BLOCK_MOVE: return "banks"
	}
	return "unk"
}

// Parameter list (no surrounding parens) for the inst_ proc of this category.
//
// imm8/imm16 take distinct fixed-width types (i8/i16) rather than i64 for two
// reasons: (a) the 65816's mode-dependent immediates make 8- vs 16-bit a real
// semantic choice the caller must make, so the type is the natural selector;
// (b) overload resolution needs the inst_<mnem> group's imm8/imm16 entries to
// differ by parameter type -- two `i64` params would collide.
kind_params :: proc(kind: Sig_Kind) -> string {
	switch kind {
	case .NONE:       return ""
	case .ACC:        return ""
	case .IMM8:       return "imm: i8"
	case .IMM16:      return "imm: i16"
	case .REL:        return "label: u32"
	case .REL_LONG:   return "label: u32"
	case .MEM:        return "m: Memory"
	case .BLOCK_MOVE: return "src_bank, dst_bank: u8"
	}
	return ""
}

// Argument list (no parens) forwarded to the inst_ proc from emit_.
kind_args :: proc(kind: Sig_Kind) -> string {
	switch kind {
	case .NONE:       return ""
	case .ACC:        return ""
	case .IMM8:       return "imm"
	case .IMM16:      return "imm"
	case .REL:        return "label"
	case .REL_LONG:   return "label"
	case .MEM:        return "m"
	case .BLOCK_MOVE: return "src_bank, dst_bank"
	}
	return ""
}

// Body of the inst_ proc: a call to the matching instructions.odin helper.
write_inst_body :: proc(sb: ^strings.Builder, mnemonic_str: string, kind: Sig_Kind) {
	switch kind {
	case .NONE:       fmt.sbprintf(sb, "inst_none(.%s)", mnemonic_str)
	case .ACC:        fmt.sbprintf(sb, "inst_a(.%s)", mnemonic_str)
	case .IMM8:       fmt.sbprintf(sb, "inst_i8(.%s, i64(imm))", mnemonic_str)
	case .IMM16:      fmt.sbprintf(sb, "inst_i16(.%s, i64(imm))", mnemonic_str)
	case .REL:        fmt.sbprintf(sb, "inst_rel(.%s, label)", mnemonic_str)
	case .REL_LONG:   fmt.sbprintf(sb, "inst_rel_long(.%s, label)", mnemonic_str)
	case .MEM:        fmt.sbprintf(sb, "inst_m(.%s, m)", mnemonic_str)
	case .BLOCK_MOVE: fmt.sbprintf(sb, "inst_block_move(.%s, src_bank, dst_bank)", mnemonic_str)
	}
}

main :: proc() {
	fmt.println("Generating mnemonic builders from ENCODE_FORMS...")

	// Collect procedures grouped by mnemonic, deduped by full proc name.
	procs_by_mnemonic: map[m816.Mnemonic][dynamic]Proc_Entry
	defer {
		for _, v in procs_by_mnemonic { delete(v) }
		delete(procs_by_mnemonic)
	}

	seen_proc_names: map[string]bool
	defer delete(seen_proc_names)

	skipped: [dynamic]string
	defer delete(skipped)

	for mnemonic in m816.Mnemonic {
		if mnemonic == .INVALID { continue }

		_run := m816.ENCODE_RUNS[u16(mnemonic)]
		forms := m816.ENCODE_FORMS[_run.start:][:_run.count]
		if len(forms) == 0 { continue }

		mnemonic_lower := mnemonic_to_lower(mnemonic)

		for f in forms {
			kind, ok := classify_form(f)
			if !ok {
				append(&skipped, fmt.aprintf("%v opcode=$%02x ops=%v", mnemonic, f.opcode, f.ops))
				continue
			}

			proc_name := strings.concatenate({"inst_", mnemonic_lower, "_", kind_suffix(kind)})

			if proc_name in seen_proc_names {
				delete(proc_name)
				continue
			}
			seen_proc_names[proc_name] = true

			if mnemonic not_in procs_by_mnemonic {
				procs_by_mnemonic[mnemonic] = make([dynamic]Proc_Entry)
			}
			append(&procs_by_mnemonic[mnemonic], Proc_Entry{
				mnemonic  = mnemonic,
				kind      = kind,
				proc_name = proc_name,
			})
		}
	}

	// Deterministic mnemonic ordering (enum order).
	mnemonic_list: [dynamic]m816.Mnemonic
	defer delete(mnemonic_list)
	for mn in procs_by_mnemonic { append(&mnemonic_list, mn) }
	slice.sort_by(mnemonic_list[:], proc(a, b: m816.Mnemonic) -> bool {
		return int(a) < int(b)
	})

	// Widest proc name (for column alignment of the :: tokens).
	max_name_padding := 0
	for mnemonic in mnemonic_list {
		for entry in procs_by_mnemonic[mnemonic] {
			max_name_padding = max(max_name_padding, len(entry.proc_name))
		}
	}

	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)

	generate_header(&sb)

	// ---- Individual typed builder procedures --------------------------------
	strings.write_string(&sb, `// =============================================================================
// Individual Typed Builder Procedures
// =============================================================================

`)

	for mnemonic in mnemonic_list {
		procs := procs_by_mnemonic[mnemonic]
		mnemonic_str := fmt.tprintf("%v", mnemonic)

		for entry in procs {
			generate_inst_proc(&sb, entry, mnemonic_str, max_name_padding)
		}
		for entry in procs {
			generate_emit_proc(&sb, entry, mnemonic_str, max_name_padding)
		}
	}

	// ---- Overload groups ----------------------------------------------------
	strings.write_string(&sb, `
// =============================================================================
// Overload Groups
// =============================================================================

`)

	for mnemonic in mnemonic_list {
		procs := procs_by_mnemonic[mnemonic]
		if len(procs) == 0 { continue }

		mnemonic_lower := mnemonic_to_lower(mnemonic)
		write_overload_group(&sb, "inst_", mnemonic_lower, procs, max_name_padding, false)
		write_overload_group(&sb, "emit_", mnemonic_lower, procs, max_name_padding, true)
	}

	output := strings.to_string(sb)

	err := os.write_entire_file(#directory + "/../mnemonic_builders.odin", transmute([]u8)strings.concatenate({GEN_ATTRIB, output}))
	if err == nil {
		fmt.println("Generated mnemonic_builders.odin successfully!")
		fmt.printf("Total mnemonics with builders: %d\n", len(mnemonic_list))
		total_procs := 0
		for mn in mnemonic_list { total_procs += len(procs_by_mnemonic[mn]) }
		fmt.printf("Total inst_ procedures generated: %d (plus matching emit_)\n", total_procs)
		if len(skipped) > 0 {
			fmt.printf("Skipped %d form(s):\n", len(skipped))
			for s in skipped { fmt.printf("  %s\n", s) }
		} else {
			fmt.println("Skipped 0 forms.")
		}
	} else {
		fmt.eprintln("Failed to write mnemonic_builders.odin")
	}
}

// One inst_ proc, compact one-line form mirroring x86's output.
generate_inst_proc :: proc(sb: ^strings.Builder, entry: Proc_Entry, mnemonic_str: string, pad: int) {
	strings.write_string(sb, entry.proc_name)
	for n := pad - len(entry.proc_name); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	strings.write_string(sb, " :: #force_inline proc \"contextless\" (")
	strings.write_string(sb, kind_params(entry.kind))
	strings.write_string(sb, ") -> Instruction { return ")
	write_inst_body(sb, mnemonic_str, entry.kind)
	strings.write_string(sb, " }\n")
}

// One emit_ proc. emit_ appends, so it is NOT contextless (append needs context).
generate_emit_proc :: proc(sb: ^strings.Builder, entry: Proc_Entry, mnemonic_str: string, pad: int) {
	emit_name := strings.concatenate({"emit_", entry.proc_name[5:]})
	defer delete(emit_name)

	strings.write_string(sb, emit_name)
	for n := pad - len(entry.proc_name); n > 0; n -= 1 { strings.write_byte(sb, ' ') }
	strings.write_string(sb, " :: #force_inline proc(instructions: ^[dynamic]Instruction")

	params := kind_params(entry.kind)
	if len(params) > 0 {
		strings.write_string(sb, ", ")
		strings.write_string(sb, params)
	}
	strings.write_string(sb, ") { append(instructions, ")
	strings.write_string(sb, entry.proc_name)
	strings.write_string(sb, "(")
	strings.write_string(sb, kind_args(entry.kind))
	strings.write_string(sb, ")) }\n")
}

// inst_<mnem> / emit_<mnem> overload group (or a single alias when 1 entry).
write_overload_group :: proc(
	sb: ^strings.Builder, prefix, mnemonic_lower: string,
	procs: [dynamic]Proc_Entry, pad: int, emit: bool,
) {
	strings.write_string(sb, prefix)
	strings.write_string(sb, mnemonic_lower)
	for n := pad - len(mnemonic_lower); n > 0; n -= 1 { strings.write_byte(sb, ' ') }

	entry_name :: proc(entry: Proc_Entry, emit: bool) -> string {
		if emit { return strings.concatenate({"emit_", entry.proc_name[5:]}) }
		return strings.clone(entry.proc_name)
	}

	if len(procs) == 1 {
		name := entry_name(procs[0], emit)
		defer delete(name)
		strings.write_string(sb, " :: ")
		strings.write_string(sb, name)
		strings.write_string(sb, "\n")
	} else {
		strings.write_string(sb, " :: proc{ ")
		for entry, i in procs {
			if i > 0 { strings.write_string(sb, ", ") }
			name := entry_name(entry, emit)
			defer delete(name)
			strings.write_string(sb, name)
		}
		strings.write_string(sb, " }\n")
	}
}

generate_header :: proc(sb: ^strings.Builder) {
	strings.write_string(sb, `package rexcode_mos65816

// =============================================================================
// GENERATED FILE - DO NOT EDIT
// =============================================================================
//
// Generated by tools/gen_mnemonic_builders.odin from ENCODE_FORMS.
// Regenerate with: odin run mos65816/tools/gen_mnemonic_builders.odin -file
//
// Typed mnemonic builder procedures with overloading. Each mnemonic exposes one
// overloaded variant per distinct operand category it accepts:
//
//   inst_<mnem>(...)  -> Instruction        (build, caller appends)
//   emit_<mnem>(dst, ...)                    (build + append to a ^[dynamic]Instruction)
//
// Operand categories and how to supply them:
//   * <none>     no operand                 inst_rts()
//   * _a         accumulator (ASL A, ...)   inst_asl_a()
//   * _imm8      8-bit immediate (i64)      inst_lda_imm8(0x12)
//   * _imm16     16-bit immediate (i64)     inst_lda_imm16(0x1234)
//   * _rel       8-bit branch (label u32)   inst_bra_rel(label_id)
//   * _rel_long  16-bit branch (label u32)  inst_brl_rel_long(label_id)
//   * _mem       memory; mode rides in the  inst_lda_mem(mem_abs_x(0x1234))
//                Memory value (use mem_*)
//   * _banks     block move (src,dst: u8)   inst_mvn_banks(0x00, 0x7e)

`)
}
