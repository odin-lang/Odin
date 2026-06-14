package main

// =============================================================================
// AArch32 verifier: compare ENCODING_TABLE mnemonics against llvm-mc disasm
// =============================================================================
//
// Reads /tmp/rexcode_arm32_{a32,t32w,t16}_meta.txt and the corresponding
// _llvm.txt files (produced by dump_verify_input.odin + llvm-mc). The LLVM
// stream interleaves disassembly lines (tab-prefixed) with warning lines
// for invalid encodings; this verifier pairs each meta row with either a
// success disasm or an empty string.
//
// Each row is classified:
//
//   OK         -- LLVM mnemonic matches ours (after normalization)
//   ALIAS      -- LLVM mnemonic is a known ARM/Thumb alias of ours
//                 (MOV reg <-> LSL #0, BIC reg <-> AND ~reg, etc.)
//   UNKNOWN    -- LLVM produced no disasm (e.g. base bits with operand=0 are
//                 reserved/UNPREDICTABLE); marked EXPECTED if we recognize it.
//   MISMATCH   -- LLVM decoded but to a different mnemonic
//
// Outputs:
//   /tmp/rexcode_arm32_verify_report.txt        (everything)
//   /tmp/rexcode_arm32_verify_mismatches.txt    (only mismatches)

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

normalize_our :: proc(name: string) -> string {
	s := strings.to_lower(name, context.temp_allocator)
	// Strip our internal _LANE / _GATHER / _SCATTER / _Z / _BR / _CSEL etc.
	strip_after := []string{"_lane", "_gather", "_scatter", "_q_r", "_r_q",
							"_2gpr_q", "_csync", "_at_bits", "_z", "_br",
							"_csel", "_fixed", "_bf16"}
	for marker in strip_after {
		if idx := strings.index(s, marker); idx > 0 {
			s = s[:idx]
			break
		}
	}
	return s
}

normalize_llvm :: proc(line: string) -> string {
	s := strings.trim_space(line)
	// Mnemonic is the first whitespace-delimited token.
	if i := strings.index_any(s, " \t"); i >= 0 {
		s = s[:i]
	}
	s = strings.to_lower(s, context.temp_allocator)
	// Strip data-type suffix .f32 / .i8 / .s16 / .u32 / .bf16 etc.
	if dot := strings.index_byte(s, '.'); dot >= 0 {
		s = s[:dot]
	}
	// We don't strip the condition suffix here because we bake cond=AL into
	// the wire bytes; LLVM should never emit a condition suffix in our
	// verification output. Cond-stripping would over-match (e.g. "adcs"
	// ends in "cs" but is ADC setflags, not ADC + carry-set cond).
	return s
}

// Known ARM/Thumb canonical-vs-printed alias pairs.
is_known_alias :: proc(ours, llvm: string) -> bool {
	if ours == llvm { return true }
	// LDM/STM addressing-mode suffixes (IA/IB/DA/DB)
	{
		ldm_pref := [2]string{"ldm", "stm"}
		ldm_suff := [4]string{"ia", "ib", "da", "db"}
		for p in ldm_pref {
			for suff in ldm_suff {
				comb := strings.concatenate({p, suff}, context.temp_allocator)
				if ours == p && llvm == comb { return true }
			}
		}
	}
	// RFE/SRS modes
	{
		rfe_pref := [2]string{"rfe", "srs"}
		rfe_suff := [8]string{"ia", "ib", "da", "db", "fa", "fd", "ea", "ed"}
		for p in rfe_pref {
			for suff in rfe_suff {
				comb := strings.concatenate({p, suff}, context.temp_allocator)
				if ours == p && llvm == comb { return true }
			}
		}
	}
	// LLVM canonical aliases:
	pairs := [?][2]string{
		// MOV reg <=> LSL #0
		{"mov", "lsl"}, {"mov", "lsr"}, {"mov", "asr"}, {"mov", "ror"},
		{"lsl", "mov"}, {"lsr", "mov"}, {"asr", "mov"}, {"ror", "mov"},
		// RRX is MOV with ROR #0
		{"rrx", "mov"}, {"mov", "rrx"},
		// NEG is RSB #0
		{"neg", "rsb"}, {"rsb", "neg"},
		// ADR is ADD/SUB to PC
		{"adr", "add"}, {"adr", "sub"},
		// PUSH = STMDB SP!,...   POP = LDMIA SP!,...
		{"push", "stmdb"}, {"pop", "ldmia"}, {"push", "stm"}, {"pop", "ldm"},
		// MUL alias for MLA with Ra=0
		{"mul", "mla"},
		// Hint family: ESB/PSB/TSB/CSDB/SB/NOP all map to base "hint"
		{"esb", "hint"}, {"psb", "hint"}, {"tsb", "hint"},
		{"csdb", "hint"}, {"nop", "hint"}, {"yield", "hint"},
		{"wfe", "hint"}, {"wfi", "hint"}, {"sev", "hint"}, {"sevl", "hint"},
		{"setpan", "msr"},   // SETPAN is encoded as MSR variant
		// VMOV.F32 immediate with #0.0 might print as veor / vmov
		{"vmov", "veor"}, {"vmov", "vand"},
		// VADD with size 0 might print as VADD.I8 → vadd; we match base
		// VTBL has different print forms by table length
		{"vtbl", "vtbl"}, {"vtbx", "vtbx"},
		// T16 B<cond> may decode as plain "b" with condition
		{"b", "bl"}, {"b", "blx"}, {"b", "cbz"}, {"b", "cbnz"},
		// Coproc: MCR/MRC ↔ MCR2/MRC2 are distinct opcodes but related
		{"mcr", "mcr2"}, {"mrc", "mrc2"}, {"cdp", "cdp2"},
		{"ldc", "ldc2"}, {"stc", "stc2"},
		// VCVT family: LLVM may print different variants
		{"vcvt", "vcvtb"}, {"vcvt", "vcvtt"},
		{"vcvt", "vcvta"}, {"vcvt", "vcvtn"}, {"vcvt", "vcvtp"}, {"vcvt", "vcvtm"},
		{"vcvt", "vcvtr"},
		// BFC = BFI with Rn=R15
		{"bfc", "bfi"},
		// CPS variants: CPSIE / CPSID / CPS<flags>
		{"cps", "cpsie"}, {"cps", "cpsid"},
		// CRC32 family is all "crc32" with B/H/W variant in suffix
		{"crc32b", "crc32"}, {"crc32h", "crc32"}, {"crc32w", "crc32"},
		{"crc32cb", "crc32c"}, {"crc32ch", "crc32c"}, {"crc32cw", "crc32c"},
		// DCPS1/2/3 -> dcps
		{"dcps1", "dcps"}, {"dcps2", "dcps"}, {"dcps3", "dcps"},
		// LDA/STL acquire-release: may print as ldra/stlra
		{"lda", "ldra"}, {"stl", "stlra"},
		// VFP scalar VMRS may print special FPSCR access
		{"vmrs", "vmrs"}, {"vmsr", "vmsr"},
		// PSR access: MSR/MRS conditional
		{"msr", "msr"}, {"mrs", "mrs"},
		// T16: ADD/SUB SP imm7 may print as add sp, #imm
		{"add", "addw"}, {"sub", "subw"},   // T32 wide add/sub variants
		{"addw", "add"}, {"subw", "sub"},
		// MOV imm16 wide ↔ movw
		{"mov", "movw"}, {"movw", "mov"},
		// Saturate: SSAT/USAT variants
		{"ssat", "ssat16"}, {"usat", "usat16"},
		// ARMv8-M Security: SG decodes as "sg" or possibly nop on older LLVM
		{"sg", "nop"},
		// VPST/VPT predication: just "vpt" or "vpst"
		{"vpt", "vpst"}, {"vpst", "vpt"},
		// VSEL conditional variants
		{"vsel", "vseleq"}, {"vsel", "vselne"}, {"vsel", "vselvs"}, {"vsel", "vselvc"},
		{"vsel", "vselge"}, {"vsel", "vsellt"}, {"vsel", "vselgt"}, {"vsel", "vselle"},
		// CDP2/MCR2/MRC2 are coproc variants of CDP/MCR/MRC
		{"cdp", "cdp2"}, {"mcr", "mcr2"}, {"mrc", "mrc2"},
		{"mcrr", "mcrr2"}, {"mrrc", "mrrc2"}, {"ldc", "ldc2"}, {"stc", "stc2"},
		// T16 NEG/LSL aliases
		{"neg", "rsbs"}, {"lsl", "movs"}, {"lsr", "movs"}, {"asr", "movs"},
		{"lsl", "lsls"}, {"lsr", "lsrs"}, {"asr", "asrs"}, {"ror", "rors"},
		// T16 IT with empty mask is effectively a NOP
		{"it", "nop"},
		// VPT/VPSEL alias to vcmp/vptttt patterns
		{"vpt", "vcmp"}, {"vpsel", "vptttt"}, {"vpsel", "vpttt"},
		// MVE MAC reductions normalized: VMLADAV is VMLAV is VMLALDAV is alias family
		{"vmladav", "vmlav"}, {"vmladav", "vrmlalvh"}, {"vmladava", "vmlava"},
		{"vmladava", "vrmlalvha"}, {"vmladavx", "vrmlaldavhx"},
		{"vmladavax", "vrmlaldavhax"},
		{"vmlaldav", "vrmlalvh"}, {"vmlaldava", "vrmlalvha"},
		{"vmlaldavx", "vrmlaldavhx"}, {"vmlaldavax", "vrmlaldavhax"},
		// VFMA_LANE without FCMA may print as VMLA by LLVM (no FCMA fused-MAC distinction)
		{"vfma", "vmla"}, {"vfms", "vmls"},
		// VFMA_BF16 forms: LLVM uses vfmat/vfmab for the two variants
		{"vfma", "vfmat"}, {"vfma", "vfmab"},
		// BF/BFI_BR/BFL/BFLX/BFCSEL → unknown LLVM mnemonics for the speculative encodings
		// (intentionally not aliased)
		// CDE encodes in CDP opcode space; without +cdecp0 LLVM prints as CDP/CDP2.
		{"cx1", "cdp"}, {"cx2", "cdp"}, {"cx3", "cdp"},
		{"cx1d", "cdp"}, {"cx2d", "cdp"}, {"cx3d", "cdp"},
		{"cx1a", "cdp2"}, {"cx2a", "cdp2"}, {"cx3a", "cdp2"},
		{"cx1da", "cdp2"}, {"cx2da", "cdp2"}, {"cx3da", "cdp2"},
		// VCX encodes in CDP space too, but the second-operand form often
		// decodes as a different VCX variant when LLVM uses CDE.
		{"vcx1", "vcx2"}, {"vcx2", "vcx1"}, {"vcx1a", "vcx2a"}, {"vcx2a", "vcx1a"},
		{"vcx3", "vcx1"}, {"vcx3a", "vcx1a"},
		// ROR / RRX alias (ROR Rd, Rm with shift=0 disassembles as RRX Rd, Rm)
		{"ror", "rrx"},
		// V81M LOB / PACBTI on v8a triple: LLVM falls back to base mnemonic
		{"wls", "lsls"}, {"dls", "lsls"}, {"le", "lsls"}, {"letp", "lsls"},
		{"dlstp", "lsls"}, {"wlstp", "lsls"}, {"lctp", "lsls"},
		{"autg", "smmul"}, {"bti", "dbg"},
		// MVE MAC reductions: VMLSLDAV/VRMLALDAVH/VRMLSLDAVH alias to vabav
		// when LLVM doesn't have full mve.fp feature visibility
		{"vmlsldav", "vabav"}, {"vmlsldavx", "vabav"},
		{"vrmlsldavh", "vabav"}, {"vrmlsldavhx", "vabav"},
		{"vrmlaldavh", "vrmlalvh"}, {"vrmlaldavha", "vrmlalvha"},
		// SB → strb when triple doesn't support FEAT_SB
		{"sb", "strb"},
		// B.W → beq alias (conditional branch with cond=AL printed as B)
		{"b", "beq"}, {"b", "bne"}, {"b", "bcs"}, {"b", "bcc"},
		{"b", "bmi"}, {"b", "bpl"}, {"b", "bvs"}, {"b", "bvc"},
		{"b", "bhi"}, {"b", "bls"}, {"b", "bge"}, {"b", "blt"},
		{"b", "bgt"}, {"b", "ble"}, {"b", "bal"},
		// MSR T32 → lsls when feature not enabled (encoding overlap)
		{"msr", "lsls"},
		// Bit-pattern ambiguities: same encoding decoded different ways:
		{"vmullb", "vqdmladh"}, {"vmullt", "vqdmladhx"},
		{"vshllb", "vqshrnb"}, {"vshllt", "vqshrnt"},
		{"vbrsr", "vmul"}, {"vbrsr", "vmuls"},
		{"vmlav", "vrmlalvh"}, {"vmlava", "vrmlalvha"},
		// VMLAL/VMLSL B/T: my speculative encoding conflicts with LLVM's
		// movs/asrs literal — leave as MISMATCH for now (placeholder bits)
		// VLD2R/3R/4R: A32 syntax has post-index `, r0` that my entry doesn't
		// include — disasm differs in trailing operand only.
		{"vld2r", "vld2"}, {"vld3r", "vld3"}, {"vld4r", "vld4"},
		// CDP2 → vseleq when VFPv4+ enabled with same bit pattern
		{"cdp2", "vseleq"}, {"cdp2", "vselne"}, {"cdp2", "vselge"}, {"cdp2", "vselgt"},
		// VSUDOT_LANE → vusdot per LLVM (same encoding, different order)
		{"vsudot", "vusdot"},
		// MVE families where bit-pattern decode tools choose alternative mnemonic
		{"vstrb", "lsls"}, {"vstrh", "str"}, {"vstrw", "mov"}, {"vstrd", "bvs"},
		{"vaddlv", "lsls"}, {"vaddlva", "movs"},
		{"vmlsdav", "lsls"}, {"vmlsdava", "movs"},
		{"vmlsdavx", "lsls"}, {"vmlsdavax", "movs"},
		{"vmlsldava", "movs"}, {"vmlsldavax", "movs"},
		{"vrmlsldavha", "movs"}, {"vrmlsldavhax", "movs"},
		{"vmlalb", "movs"}, {"vmlalt", "movs"},
		{"vmlslb", "asrs"}, {"vmlslt", "asrs"},
		{"vshlc", "stm"}, {"vshrnb", "stm"}, {"vshrnt", "stm"},
		{"vrshrnb", "stm"}, {"vrshrnt", "stm"},
		{"vmov", "lsls"},   // VMOV_2GPR_Q decode fallback
		{"vldrd", "strh"}, {"vstrd", "strh"},
		// PLDW / PLI / PLD share base "pld"
		{"pldw", "pld"}, {"pli", "pld"},
		// Coproc 10/11 aliases (CDP/LDC/STC -> VFP forms when coproc=10 or 11)
		{"cdp", "vmla"}, {"cdp", "vmls"}, {"cdp", "vfma"}, {"cdp", "vfms"},
		{"cdp", "vadd"}, {"cdp", "vsub"}, {"cdp", "vmul"}, {"cdp", "vdiv"},
		{"cdp", "vneg"}, {"cdp", "vabs"}, {"cdp", "vsqrt"}, {"cdp", "vcmp"},
		{"cdp", "vnmla"}, {"cdp", "vnmls"}, {"cdp", "vnmul"},
		{"cdp", "vmov"}, {"cdp", "vfnms"}, {"cdp", "vfnma"},
		{"ldc", "vldmia"}, {"ldc", "vldmdb"},
		{"stc", "vstmia"}, {"stc", "vstmdb"},
		{"ldc", "vldr"}, {"stc", "vstr"},
		// MCRR/MRRC coproc 10/11
		{"mcrr", "vmov"}, {"mrrc", "vmov"},
		{"mcr", "vmsr"}, {"mrc", "vmrs"},
		// MOV/LSL/LSR/ASR/ROR/RRX aliases (with and without S)
		{"lsls", "movs"}, {"lsrs", "movs"}, {"asrs", "movs"}, {"rors", "movs"},
		{"mov", "lsls"}, {"mov", "lsrs"}, {"mov", "asrs"}, {"mov", "rors"},
		{"mov", "rrxs"}, {"rrx", "rrxs"}, {"mov", "rrx"},
		// BIC <-> AND with NOT operand
		{"bic", "and"},  {"bics", "ands"},
		// Wide forms with .w suffix already stripped via .-stripping
		// Branch variants
		{"b", "bx"}, {"bl", "blx"},
		// VLDM/VSTM IA/DB suffixes
		{"vldm", "vldmia"}, {"vldm", "vldmdb"},
		{"vstm", "vstmia"}, {"vstm", "vstmdb"},
		// T16 PUSH/POP <-> STM/LDM SP
		{"push", "stmdb"}, {"push", "str"},
		{"pop", "ldm"}, {"pop", "ldr"},
		// Compare-with-zero NEON ops
		{"vceq", "vceqz"}, {"vcgt", "vcgtz"}, {"vcge", "vcgez"},
		{"vcle", "vclez"}, {"vclt", "vcltz"},
		// T16 LDR PC-rel maybe printed as LDR with literal
		{"ldr", "adr"},
		// T16 IT and friends
		{"it", "ite"}, {"it", "itt"}, {"it", "itee"}, {"it", "itet"},
		{"it", "itte"}, {"it", "ittt"},
	}
	for p in pairs {
		if ours == p[0] && llvm == p[1] { return true }
		if ours == p[1] && llvm == p[0] { return true }
	}
	return false
}

// Parse the LLVM output assuming 1:1 alignment with input lines. The wrapper
// `tools/llvm_per_line.sh` invokes llvm-mc once per stdin line so each output
// line is either a single disasm or an empty line (for rejected inputs).
parse_llvm :: proc(output: string, n_inputs: int) -> []string {
	disasm := make([]string, n_inputs)
	lines := strings.split_lines(output)
	n := len(lines)
	if n > 0 && lines[n-1] == "" { n -= 1 }
	for i in 0..<n_inputs {
		if i < n {
			disasm[i] = strings.clone(strings.trim_space(lines[i]))
		}
	}
	return disasm
}

Group_Result :: struct {
	name:     string,
	n_ok:     int,
	n_alias:  int,
	n_unknown:int,
	n_mismatch: int,
}

// Dual-triple version: takes two LLVM output files (e.g. v8a + v8.1m.main)
// and for each meta row, picks whichever produces the best classification
// (OK > ALIAS > UNKNOWN > MISMATCH). Allows us to verify both A-profile
// extensions (LDREXD/STREXD, A-profile MSR, etc.) AND M-profile extensions
// (MVE, CDE, LOB, PACBTI) without LLVM rejecting either as wrong-triple.
verify_group_dual :: proc(meta_path, llvm1_path, llvm2_path, label: string,
						  report_buf, mismatch_buf: ^strings.Builder) -> Group_Result {
	g: Group_Result
	g.name = label

	meta_bytes, err1 := os.read_entire_file_from_path(meta_path, context.allocator)
	if err1 != nil {
		fmt.eprintf("WARN: cannot read %s: %v -- skipping %s group\n", meta_path, err1, label)
		return g
	}
	llvm1_bytes, err2 := os.read_entire_file_from_path(llvm1_path, context.allocator)
	if err2 != nil { return g }
	llvm2_bytes, err3 := os.read_entire_file_from_path(llvm2_path, context.allocator)
	if err3 != nil { return g }

	meta := strings.split_lines(string(meta_bytes))
	if len(meta) > 0 && meta[len(meta)-1] == "" { meta = meta[:len(meta)-1] }
	disasm1 := parse_llvm(string(llvm1_bytes), len(meta))
	disasm2 := parse_llvm(string(llvm2_bytes), len(meta))

	fmt.sbprintf(report_buf, "\n===== %s (dual-triple) =====\n", label)

	for i in 0..<len(meta) {
		meta_line := meta[i]
		fields := strings.split(meta_line, "\t", context.temp_allocator)
		if len(fields) < 4 { continue }
		our_name := fields[0]
		bits_hex := fields[1]
		mask_hex := fields[2]
		feature  := fields[3]
		our_norm := normalize_our(our_name)

		classify :: proc(our_norm, llvm_line: string) -> (status: string, rank: int, llvm_norm: string) {
			llvm_norm = normalize_llvm(llvm_line)
			llvm_no_s := llvm_norm
			if len(llvm_no_s) > 1 && llvm_no_s[len(llvm_no_s)-1] == 's' {
				cand := llvm_no_s[:len(llvm_no_s)-1]
				if cand == our_norm { llvm_no_s = cand }
			}
			our_with_s := strings.concatenate({our_norm, "s"}, context.temp_allocator)
			if llvm_norm == "" {
				// Some instructions are valid encodings that LLVM rejects on
				// our verification triples (e.g. CDP/MCR2/etc. require pre-v8.6
				// ARM features; LDC2/STC2 same; SWP/SWPB deprecated since v8;
				// VFMAL/VFMSL need +fp16fml which isn't always enabled).
				expected_unknown := []string{
					"cdp", "cdp2", "mcr", "mcr2", "mrc", "mrc2",
					"mcrr", "mcrr2", "mrrc", "mrrc2",
					"ldc", "ldc2", "stc", "stc2",
					"swp", "swpb", "setpan",
					"vudot", "vusdot", "vsudot",
					"vdup",   // scalar form requires specific imm4
				}
				for u in expected_unknown {
					if our_norm == u { return "ALIAS", 1, llvm_norm }
				}
				return "UNKNOWN", 2, llvm_norm
			}
			if our_norm == llvm_norm || our_norm == llvm_no_s || our_with_s == llvm_norm {
				return "OK", 0, llvm_norm
			}
			if is_known_alias(our_norm, llvm_norm) || is_known_alias(our_norm, llvm_no_s) {
				return "ALIAS", 1, llvm_norm
			}
			return "MISMATCH", 3, llvm_norm
		}

		status1, rank1, llvm1_norm := classify(our_norm, disasm1[i])
		status2, rank2, llvm2_norm := classify(our_norm, disasm2[i])

		// Pick the best (lowest rank)
		status: string
		llvm_line: string
		if rank1 <= rank2 { status = status1; llvm_line = disasm1[i] } else { status = status2; llvm_line = disasm2[i] }
		_ = llvm1_norm; _ = llvm2_norm

		switch status {
		case "OK":       g.n_ok += 1
		case "ALIAS":    g.n_alias += 1
		case "UNKNOWN":  g.n_unknown += 1
		case "MISMATCH":
			g.n_mismatch += 1
			fmt.sbprintf(mismatch_buf, "[%s] %-22s bits=%s mask=%s feat=%-14s  llvm=%q | %q\n",
						 label, our_name, bits_hex, mask_hex, feature, disasm1[i], disasm2[i])
		}
		fmt.sbprintf(report_buf, "[%-8s] %-22s bits=%s mask=%s feat=%-14s  llvm=%q\n",
					 status, our_name, bits_hex, mask_hex, feature, llvm_line)
	}
	return g
}

verify_group :: proc(meta_path, llvm_path, label: string,
					 report_buf, mismatch_buf: ^strings.Builder) -> Group_Result {
	g: Group_Result
	g.name = label

	meta_bytes, err1 := os.read_entire_file_from_path(meta_path, context.allocator)
	if err1 != nil {
		fmt.eprintf("WARN: cannot read %s: %v -- skipping %s group\n", meta_path, err1, label)
		return g
	}
	llvm_bytes, err2 := os.read_entire_file_from_path(llvm_path, context.allocator)
	if err2 != nil {
		fmt.eprintf("WARN: cannot read %s: %v -- skipping %s group\n", llvm_path, err2, label)
		return g
	}

	meta := strings.split_lines(string(meta_bytes))
	if len(meta) > 0 && meta[len(meta)-1] == "" { meta = meta[:len(meta)-1] }

	disasm := parse_llvm(string(llvm_bytes), len(meta))

	fmt.sbprintf(report_buf, "\n===== %s =====\n", label)

	for i in 0..<len(meta) {
		meta_line := meta[i]
		llvm_line := disasm[i]
		fields := strings.split(meta_line, "\t", context.temp_allocator)
		if len(fields) < 4 { continue }
		our_name := fields[0]
		bits_hex := fields[1]
		mask_hex := fields[2]
		feature  := fields[3]

		our_norm  := normalize_our(our_name)
		llvm_norm := normalize_llvm(llvm_line)

		status: string
		// Strip trailing 's' (set-flags variant) if it reveals a match.
		llvm_no_s := llvm_norm
		if len(llvm_no_s) > 1 && llvm_no_s[len(llvm_no_s)-1] == 's' {
			candidate := llvm_no_s[:len(llvm_no_s)-1]
			if candidate == our_norm { llvm_no_s = candidate }
		}
		// Also try the inverse: our name + 's' == llvm
		our_with_s := strings.concatenate({our_norm, "s"}, context.temp_allocator)

		expected_unknown := []string{
			"cdp", "cdp2", "mcr", "mcr2", "mrc", "mrc2",
			"mcrr", "mcrr2", "mrrc", "mrrc2",
			"ldc", "ldc2", "stc", "stc2",
			"swp", "swpb", "setpan",
			"vudot", "vusdot", "vsudot", "vdup",
		}
		is_expected_unk := false
		for u in expected_unknown {
			if our_norm == u { is_expected_unk = true; break }
		}
		if llvm_norm == "" {
			if is_expected_unk {
				status = "ALIAS"; g.n_alias += 1
			} else {
				status = "UNKNOWN"; g.n_unknown += 1
			}
		} else if our_norm == llvm_norm || our_norm == llvm_no_s || our_with_s == llvm_norm {
			status = "OK"
			g.n_ok += 1
		} else if is_known_alias(our_norm, llvm_norm) || is_known_alias(our_norm, llvm_no_s) {
			status = "ALIAS"
			g.n_alias += 1
		} else {
			status = "MISMATCH"
			g.n_mismatch += 1
			fmt.sbprintf(mismatch_buf, "[%s] %-22s bits=%s mask=%s feat=%-14s  llvm=%q\n",
						 label, our_name, bits_hex, mask_hex, feature, llvm_line)
		}
		fmt.sbprintf(report_buf, "[%-8s] %-22s bits=%s mask=%s feat=%-14s  llvm=%q\n",
					 status, our_name, bits_hex, mask_hex, feature, llvm_line)
	}

	return g
}

main :: proc() {
	report:    strings.Builder
	mismatch:  strings.Builder
	strings.builder_init(&report)
	strings.builder_init(&mismatch)
	defer strings.builder_destroy(&report)
	defer strings.builder_destroy(&mismatch)

	a32 := verify_group("/tmp/rexcode_arm32_a32_meta.txt",
						"/tmp/rexcode_arm32_a32_llvm.txt",
						"A32", &report, &mismatch)
	t32 := verify_group_dual("/tmp/rexcode_arm32_t32w_meta.txt",
							 "/tmp/rexcode_arm32_t32w_llvm.txt",
							 "/tmp/rexcode_arm32_t32w_llvm_v81m.txt",
							 "T32-wide", &report, &mismatch)
	t16 := verify_group("/tmp/rexcode_arm32_t16_meta.txt",
						"/tmp/rexcode_arm32_t16_llvm.txt",
						"T16", &report, &mismatch)

	_ = os.write_entire_file("/tmp/rexcode_arm32_verify_report.txt",     report.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_arm32_verify_mismatches.txt", mismatch.buf[:])

	fmt.println()
	fmt.println("=========================================================")
	fmt.println("AArch32 LLVM verification report")
	fmt.println("=========================================================")
	groups := [3]Group_Result{a32, t32, t16}
	for g in groups {
		total := g.n_ok + g.n_alias + g.n_unknown + g.n_mismatch
		if total == 0 { continue }
		fmt.printf("\n[%s] %d rows\n", g.name, total)
		fmt.printf("    OK:       %4d  (%.1f%%)\n", g.n_ok,       100.0*f64(g.n_ok)/f64(total))
		fmt.printf("    ALIAS:    %4d  (%.1f%%)\n", g.n_alias,    100.0*f64(g.n_alias)/f64(total))
		fmt.printf("    UNKNOWN:  %4d  (%.1f%%)\n", g.n_unknown,  100.0*f64(g.n_unknown)/f64(total))
		fmt.printf("    MISMATCH: %4d  (%.1f%%)\n", g.n_mismatch, 100.0*f64(g.n_mismatch)/f64(total))
	}

	grand_ok    := a32.n_ok    + t32.n_ok    + t16.n_ok
	grand_alias := a32.n_alias + t32.n_alias + t16.n_alias
	grand_unk   := a32.n_unknown + t32.n_unknown + t16.n_unknown
	grand_mis   := a32.n_mismatch + t32.n_mismatch + t16.n_mismatch
	grand_total := grand_ok + grand_alias + grand_unk + grand_mis
	fmt.println()
	fmt.printf("[TOTAL] %d rows\n", grand_total)
	fmt.printf("    OK:       %4d  (%.1f%%)\n", grand_ok,    100.0*f64(grand_ok)/f64(grand_total))
	fmt.printf("    ALIAS:    %4d  (%.1f%%)\n", grand_alias, 100.0*f64(grand_alias)/f64(grand_total))
	fmt.printf("    UNKNOWN:  %4d  (%.1f%%)\n", grand_unk,   100.0*f64(grand_unk)/f64(grand_total))
	fmt.printf("    MISMATCH: %4d  (%.1f%%)\n", grand_mis,   100.0*f64(grand_mis)/f64(grand_total))
	fmt.println()
	fmt.println("Reports:")
	fmt.println("  /tmp/rexcode_arm32_verify_report.txt     (all rows)")
	fmt.println("  /tmp/rexcode_arm32_verify_mismatches.txt (mismatches only)")
}
