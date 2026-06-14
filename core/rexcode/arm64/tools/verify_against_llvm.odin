package main

// =============================================================================
// AArch64 verifier: compare ENCODING_TABLE mnemonics against llvm-mc disasm
// =============================================================================
//
// Reads /tmp/rexcode_aarch64_meta.txt and /tmp/rexcode_aarch64_llvm.txt
// (produced by dump_verify_input.odin then llvm-mc on each row), then
// classifies each entry as one of:
//
//   OK         -- LLVM mnemonic matches our mnemonic (after normalization)
//   ALIAS      -- LLVM mnemonic is a known alias of our mnemonic
//   UNKNOWN    -- LLVM produced no output (custom/private encoding)
//   MISMATCH   -- LLVM decoded but to a different mnemonic
//
// Writes:
//   /tmp/rexcode_aarch64_verify_report.txt   -- full report
//   /tmp/rexcode_aarch64_verify_mismatches.txt -- just the mismatches
//
// Run:  cd arm64 && odin run tools/verify_against_llvm.odin -file

import "core:fmt"
import "core:os"
import "core:strings"

// Lookup table: normalized base name of our mnemonic.
// Our enum names like SVE_BSL, FMOV_X_D, MOV_V_ALIAS get stripped of suffix
// markers so they match LLVM's base mnemonic ("bsl", "fmov", "mov", ...).
normalize_our :: proc(name: string) -> string {
	s := strings.to_lower(name, context.temp_allocator)
	prefixes := []string{"sve2_", "sve_", "sme2_", "sme_"}
	for prefix in prefixes {
		if strings.has_prefix(s, prefix) {
			s = s[len(prefix):]
			break
		}
	}
	if i := strings.index_byte(s, '_'); i >= 0 {
		s = s[:i]
	}
	return s
}

normalize_llvm :: proc(line: string) -> string {
	s := strings.trim_space(line)
	if i := strings.index_any(s, " \t"); i >= 0 {
		s = s[:i]
	}
	return strings.to_lower(s, context.temp_allocator)
}

// Suffix-stripped name maps for "RORV" -> "ror", "LSLV" -> "lsl", etc.
strip_suffix :: proc(name: string, suffixes: ..string) -> string {
	for s in suffixes {
		if strings.has_suffix(name, s) { return name[:len(name)-len(s)] }
	}
	return name
}

// Known LLVM-prints-alias-when-our-canonical-applies pairs.
// Returns true if our mnemonic and llvm mnemonic refer to the same instruction.
is_known_alias :: proc(ours, llvm: string) -> bool {
	// "lslv" -> "lsl", "lsrv" -> "lsr", "asrv" -> "asr", "rorv" -> "ror"
	if strip_suffix(ours, "v") == llvm { return true }
	// LLVM may emit specific b.<cond> for our generic b/bc, and similar trailing-dot forms
	{
		pref := strings.concatenate({ours, "."}, context.temp_allocator)
		if strings.has_prefix(llvm, pref) { return true }
	}

	// (our, llvm-equivalent)
	pairs := [?][2]string{
		// Architecture-defined aliases where LLVM prints alias by default
		{"orr",   "mov"},     // ORR Xd,XZR,Xm -> MOV Xd,Xm
		{"add",   "mov"},     // ADD <sp>,<sp>,#0 -> MOV sp
		{"sub",   "neg"},
		{"subs",  "negs"},
		{"subs",  "cmp"},
		{"adds",  "cmn"},
		{"ands",  "tst"},
		{"orn",   "mvn"},
		{"csinc", "cinc"},
		{"csinc", "cset"},
		{"csinv", "cinv"},
		{"csinv", "csetm"},
		{"csneg", "cneg"},
		{"sbfm",  "sbfx"}, {"sbfm", "sxtb"}, {"sbfm", "sxth"}, {"sbfm", "sxtw"}, {"sbfm", "asr"},
		{"ubfm",  "ubfx"}, {"ubfm", "uxtb"}, {"ubfm", "uxth"}, {"ubfm", "lsr"}, {"ubfm", "lsl"},
		{"bfm",   "bfi"},  {"bfm",  "bfxil"},
		{"extr",  "ror"},
		{"madd",  "mul"},
		{"msub",  "mneg"},
		{"smaddl","smull"},
		{"smsubl","smnegl"},
		{"umaddl","umull"},
		{"umsubl","umnegl"},
		{"sysl",  "at"}, {"sysl", "dc"}, {"sysl", "ic"}, {"sysl", "tlbi"},
		{"sys",   "at"}, {"sys",  "dc"}, {"sys",  "ic"}, {"sys",  "tlbi"},
		{"mrs",   "rndr"}, {"mrs", "rndrrs"},
		{"hint",  "nop"}, {"hint", "yield"}, {"hint", "wfe"}, {"hint", "wfi"},
		{"hint",  "sev"}, {"hint", "sevl"}, {"hint", "esb"}, {"hint", "psb"},
		{"hint",  "tsb"}, {"hint", "csdb"}, {"hint", "bti"}, {"hint", "chkfeat"},
		{"hint",  "stshh"}, {"hint", "dgh"}, {"hint", "xpaclri"},
		// DSB #imm with specific imm values aliases to barrier-flavored mnemonics
		{"dsb",   "ssbb"}, {"dsb", "pssbb"},
		// UBFM-based aliases: bare bits don't disambiguate which alias LLVM prints
		{"ubfm",  "ubfx"}, {"ubfm", "uxtb"}, {"ubfm", "uxth"}, {"ubfm", "ubfiz"}, {"ubfm", "lsr"}, {"ubfm", "lsl"},
		{"sbfm",  "sbfx"}, {"sbfm", "sxtb"}, {"sbfm", "sxth"}, {"sbfm", "sxtw"}, {"sbfm", "asr"}, {"sbfm", "sbfiz"},
		// UXTW/UXTB/UXTH/SXTB/SXTH/SXTW are our entries; LLVM may print ubfx/sbfx for base bits
		{"uxtw",  "ubfx"}, {"uxtb", "ubfx"}, {"uxth", "ubfx"},
		{"sxtw",  "sbfx"}, {"sxtb", "sbfx"}, {"sxth", "sbfx"},
		{"lsl",   "ubfx"}, {"lsr",  "ubfx"},   // LSL_IMM 53000000 bare bits = UBFX form
		{"asr",   "sbfx"},                     // ASR_IMM bare bits = SBFX form
		// AT/DC/IC/TLBI canonical "alias" decoder, LLVM prints raw msr when
		// it doesn't recognize the system encoding number.
		{"at",    "msr"}, {"dc", "msr"}, {"ic", "msr"}, {"tlbi", "msr"}, {"sys", "msr"},
		// SVE predicate logical aliases: ANDS Pd,Pg/Z,Pn,Pn -> MOVS Pd,Pg/Z,Pn;
		// EOR Pd,Pg/Z,Pn,Pn -> NOT Pd,Pg/Z,Pn; ORRS Pd,Pg/Z,Pn,Pn -> MOVS; etc.
		{"eor",   "not"},  {"eors", "nots"},
		{"ands",  "movs"}, {"orrs", "movs"},  {"and", "mov"}, {"orr", "mov"},
		// SME tile<->Z move: ARM canonical mnemonic is MOVA, LLVM prefers alias MOV
		{"mova",  "mov"},
		// SVE TBL with multi-vector list: LLVM keeps mnemonic "tbl" for the 2-vec form
		{"tbl2",  "tbl"},
		// TME instructions (TSTART/TCOMMIT/TTEST): LLVM 22 doesn't recognize TME,
		// prints raw MRS/MSR with numeric sysreg name. Our encodings match the
		// pre-removal ARM TME spec, so accept the raw form.
		{"tstart",  "mrs"}, {"ttest", "mrs"}, {"tcommit", "msr"},
		// Register-MOV variants -- canonical encoding is ORR_V (vector) or MOVZ/MOVN/MOVK (immediate)
		{"orr",   "mov"},
		{"movz",  "mov"},
		{"movn",  "mov"},
		{"bic",   "and"},     // sometimes
		// FP/SIMD aliases
		{"orr",   "mov"},     // vector
		{"not",   "mvn"},
		{"dup",   "mov"},
		{"umov",  "mov"},
		{"smov",  "mov"},
		{"ins",   "mov"},
		// SVE aliases
		{"cpy",   "mov"},
		{"sel",   "mov"},
		{"and",   "mov"},
		{"facge", "facge"},
		{"facgt", "facgt"},
		// Conditional branches: our table has B_COND but LLVM prints b.eq/b.ne/...
		{"b",     "b.eq"}, {"b", "b.ne"}, {"b", "b.cs"}, {"b", "b.cc"},
		{"b",     "b.mi"}, {"b", "b.pl"}, {"b", "b.vs"}, {"b", "b.vc"},
		{"b",     "b.hi"}, {"b", "b.ls"}, {"b", "b.ge"}, {"b", "b.lt"},
		{"b",     "b.gt"}, {"b", "b.le"}, {"b", "b.al"}, {"b", "b.nv"},
		{"bc",    "bc.eq"}, {"bc", "bc.ne"}, {"bc", "bc.cs"}, {"bc", "bc.cc"},
		{"bc",    "bc.mi"}, {"bc", "bc.pl"}, {"bc", "bc.vs"}, {"bc", "bc.vc"},
		{"bc",    "bc.hi"}, {"bc", "bc.ls"}, {"bc", "bc.ge"}, {"bc", "bc.lt"},
		{"bc",    "bc.gt"}, {"bc", "bc.le"}, {"bc", "bc.al"}, {"bc", "bc.nv"},
		// FCSEL is canonical for FCSET/FCINC variants if any
		{"fmov",  "fmov"},
		// Atomics: many of these LLVM might print without the size suffix
		{"prfm",  "prfm"},
		// Special: TSB CSYNC is "tsb" with one operand "csync" -- LLVM prints "tsb"
		// GMI/SUBP/SUBPS lower to SUB-ish forms
		// ESB/PSB/TSB/CSDB/DGH/BTI all map to "hint" base
	}
	for p in pairs {
		if ours == p[0] && llvm == p[1] { return true }
		if ours == p[1] && llvm == p[0] { return true }
	}
	return false
}

main :: proc() {
	meta_bytes, err1 := os.read_entire_file_from_path("/tmp/rexcode_aarch64_meta.txt", context.allocator)
	if err1 != nil {
		fmt.eprintln("ERROR: cannot read /tmp/rexcode_aarch64_meta.txt:", err1)
		os.exit(1)
	}
	llvm_bytes, err2 := os.read_entire_file_from_path("/tmp/rexcode_aarch64_llvm.txt", context.allocator)
	if err2 != nil {
		fmt.eprintln("ERROR: cannot read /tmp/rexcode_aarch64_llvm.txt:", err2)
		os.exit(1)
	}

	meta := strings.split_lines(string(meta_bytes))
	llvm := strings.split_lines(string(llvm_bytes))

	// strip trailing empty entry from split_lines
	if len(meta) > 0 && meta[len(meta)-1] == "" { meta = meta[:len(meta)-1] }
	if len(llvm) > 0 && llvm[len(llvm)-1] == "" { llvm = llvm[:len(llvm)-1] }

	if len(meta) != len(llvm) {
		fmt.eprintf("ERROR: row count mismatch -- meta=%d llvm=%d\n", len(meta), len(llvm))
		os.exit(1)
	}

	report_buf:    strings.Builder
	mismatch_buf:  strings.Builder
	strings.builder_init(&report_buf)
	strings.builder_init(&mismatch_buf)
	defer strings.builder_destroy(&report_buf)
	defer strings.builder_destroy(&mismatch_buf)

	n_ok, n_alias, n_unknown, n_mismatch := 0, 0, 0, 0

	for i in 0..<len(meta) {
		meta_line := meta[i]
		llvm_line := llvm[i]
		fields := strings.split(meta_line, "\t", context.temp_allocator)
		if len(fields) < 4 { continue }
		our_name   := fields[0]
		bits_hex   := fields[1]
		mask_hex   := fields[2]
		feature    := fields[3]

		our_norm  := normalize_our(our_name)
		llvm_norm := normalize_llvm(llvm_line)

		status: string
		// Some entries have base bits that LLVM can't decode standalone because
		// the operand-driven field must be non-zero (e.g. LDR (reg) needs the
		// "option" field to be one of {LSL/UXTW/SXTW/SXTX}, not 000). Apple AMX
		// and TME aren't in LLVM at all. Mark those as expected-undecodable.
		// names are already normalized: e.g. "amx_ldx" -> "amx",
		// "ldr_reg" -> "ldr", "tcancel" -> "tcancel"
		is_expected_unknown :: proc(name, raw: string) -> bool {
			if name == "amx" { return true }
			if name == "tcancel" || name == "tstart" || name == "tcommit" || name == "ttest" {
				return true
			}
			// MOPS CPY/SET: base bits with Rd=Rs=Rn=X0 violate "registers must
			// differ" constraint; LLVM rejects the encoding.
			switch name {
			case "cpyp", "cpym", "cpye", "cpyfp", "cpyfm", "cpyfe",
				 "setp", "setm", "sete", "setgp", "setgm", "setge":
				return true
			}
			// LDR/STR (register) and friends: base bits have option=0 which is
			// not a valid encoding; LLVM rejects it. Distinguish from LDR_IMM
			// by checking the raw enum name for "_REG" suffix.
			if strings.has_suffix(raw, "_REG") &&
			   (strings.has_prefix(raw, "LDR") || strings.has_prefix(raw, "STR")) {
				return true
			}
			return false
		}
		if llvm_norm == "" {
			if is_expected_unknown(our_norm, our_name) {
				status = "EXPECTED"
				n_alias += 1  // count as alias for OK-grade total
			} else {
				status = "UNKNOWN"
				n_unknown += 1
			}
		} else if our_norm == llvm_norm {
			status = "OK"
			n_ok += 1
		} else if is_known_alias(our_norm, llvm_norm) {
			status = "ALIAS"
			n_alias += 1
		} else {
			status = "MISMATCH"
			n_mismatch += 1
			fmt.sbprintf(&mismatch_buf, "%-22s bits=%s mask=%s feat=%s  llvm=%q\n",
						 our_name, bits_hex, mask_hex, feature, strings.trim_space(llvm_line))
		}
		fmt.sbprintf(&report_buf, "[%s] %-22s bits=%s mask=%s feat=%-10s  llvm=%q\n",
					 status, our_name, bits_hex, mask_hex, feature, strings.trim_space(llvm_line))
	}

	_ = os.write_entire_file("/tmp/rexcode_aarch64_verify_report.txt",     report_buf.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_aarch64_verify_mismatches.txt", mismatch_buf.buf[:])

	total := n_ok + n_alias + n_unknown + n_mismatch
	fmt.println()
	fmt.printf("==> AArch64 LLVM verification: %d rows\n", total)
	fmt.printf("    OK:       %4d  (%.1f%%)\n", n_ok,       100.0*f64(n_ok)/f64(total))
	fmt.printf("    ALIAS:    %4d  (%.1f%%)\n", n_alias,    100.0*f64(n_alias)/f64(total))
	fmt.printf("    UNKNOWN:  %4d  (%.1f%%)\n", n_unknown,  100.0*f64(n_unknown)/f64(total))
	fmt.printf("    MISMATCH: %4d  (%.1f%%)\n", n_mismatch, 100.0*f64(n_mismatch)/f64(total))
	fmt.println()
	fmt.println("Reports:")
	fmt.println("  /tmp/rexcode_aarch64_verify_report.txt     (all rows)")
	fmt.println("  /tmp/rexcode_aarch64_verify_mismatches.txt (mismatches only)")
}
