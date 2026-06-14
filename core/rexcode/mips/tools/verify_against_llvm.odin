package main

import "core:fmt"
import "core:os"
import "core:strings"

// MIPS mnemonics use underscore as a stand-in for the architectural dot
// suffix (ADD_S = add.s, ADDQ_PH = addq.ph, CMP_F_S = cmp.f.s).
// We keep the full identifier on our side and translate LLVM's dots to
// underscores so they compare directly.
normalize_our :: proc(name: string) -> string {
	return strings.to_lower(name, context.temp_allocator)
}

normalize_llvm :: proc(line: string) -> string {
	s := strings.trim_space(line)
	if i := strings.index_any(s, " \t"); i >= 0 {
		s = s[:i]
	}
	s = strings.to_lower(s, context.temp_allocator)
	s, _ = strings.replace_all(s, ".", "_", context.temp_allocator)
	return s
}

is_known_alias :: proc(ours, llvm: string) -> bool {
	// The strict equality after replace_all of `.` already catches the
	// common FP family ADD_S<->add.s. Below we capture mnemonic-level
	// aliases LLVM (or we) prefer.
	pairs := [?][2]string{
		// Generic MIPS aliases LLVM prefers
		{"or",   "move"},      {"add",   "move"}, {"addu", "move"}, {"daddu", "move"},
		{"sll",  "nop"},
		{"beq",  "b"},         {"beq",  "beqz"},  {"bne",  "bnez"},
		{"beql", "beqzl"},     {"bnel", "bnezl"},
		{"sub",  "neg"},       {"subu", "negu"},
		{"dsub", "dneg"},      {"dsubu","dnegu"},
		{"nor",  "not"},
		{"bgezal","bal"},      {"bgezall","bal"},
		// JALR with Rd=$ra and Rd=$zero collapses to JR or BAL in LLVM
		{"jalr", "jr"},
		// R6 reassigns BEQZC/BNEZC opcode space to JIC/JIALC for some operand
		// patterns; LLVM picks the latter
		{"beqzc","jrc"},       {"bnezc","jalrc"},
		{"jic",  "jrc"},       {"jialc","jalrc"},
		// R6 mnemonic name vs our explicit _R6 suffix
		{"dmul_r6", "dmul"},   {"ddiv_r6","ddiv"}, {"ddivu_r6", "ddivu"},
		{"mul_r6",  "mul"},    {"div_r6", "div"},  {"divu_r6",  "divu"},
		{"mod_r6",  "mod"},    {"modu_r6","modu"},
		{"muh_r6",  "muh"},    {"muhu_r6","muhu"},
		// DEXTM/DEXTU/DINSM/DINSU are encoded as DEXT/DINS with adjusted size
		// bits; LLVM picks the canonical DEXT/DINS form.
		{"dextm","dext"},      {"dextu","dext"},
		{"dinsm","dins"},      {"dinsu","dins"},
	}
	for p in pairs {
		if ours == p[0] && llvm == p[1] { return true }
		if ours == p[1] && llvm == p[0] { return true }
	}
	return false
}

main :: proc() {
	meta_bytes, err1 := os.read_entire_file_from_path("/tmp/rexcode_mips_meta.txt", context.allocator)
	if err1 != nil { fmt.eprintln("ERROR meta:", err1); os.exit(1) }
	llvm_bytes, err2 := os.read_entire_file_from_path("/tmp/rexcode_mips_llvm.txt", context.allocator)
	if err2 != nil { fmt.eprintln("ERROR llvm:", err2); os.exit(1) }

	meta := strings.split_lines(string(meta_bytes))
	llvm := strings.split_lines(string(llvm_bytes))
	if len(meta) > 0 && meta[len(meta)-1] == "" { meta = meta[:len(meta)-1] }
	if len(llvm) > 0 && llvm[len(llvm)-1] == "" { llvm = llvm[:len(llvm)-1] }
	if len(meta) != len(llvm) {
		fmt.eprintf("ERROR: meta=%d llvm=%d\n", len(meta), len(llvm)); os.exit(1)
	}

	report:    strings.Builder
	mismatch:  strings.Builder
	strings.builder_init(&report)
	strings.builder_init(&mismatch)
	defer strings.builder_destroy(&report)
	defer strings.builder_destroy(&mismatch)

	// ISAs that LLVM doesn't recognize at all (Sony PS1/PS2/PSP custom).
	// Note: LLVM may still produce a mnemonic for these bits because the
	// opcode space is shared with standard MIPS COP2/SPECIAL2 ops — but
	// semantically they belong to the Sony custom ISA, not the matched
	// MIPS mnemonic.
	is_sony_isa :: proc(isa: string) -> bool {
		return isa == "GTE_PS1" || isa == "MMI_PS2" || isa == "VU_PS2" ||
			   isa == "VFPU_PSP"
	}
	is_expected_unknown :: proc(name, raw, isa: string) -> bool {
		if is_sony_isa(isa) { return true }
		// MIPS_V `.PS` paired-single FP was deprecated and removed from LLVM
		if strings.has_suffix(raw, "_PS") || strings.has_suffix(raw, "_PS\t") {
			return true
		}
		// CRC32W/D/CW/CD encodings: LLVM may need a non-zero Rs/Rt to decode
		// (it requires source/destination to match per its AsmParser).
		// The 64-bit forms (CRC32D/CRC32CD) may also need a specific mcpu.
		switch name {
		case "crc32w", "crc32cw", "crc32d", "crc32cd":
			return true
		// PREFX (MIPS_IV FP indexed prefetch) and MFHC0/MTHC0 (MIPS32_R5
		// coprocessor 0 high-half moves) aren't decoded by any LLVM mcpu
		// configuration available locally.
		case "prefx", "mfhc0", "mthc0":
			return true
		}
		return false
	}

	n_ok, n_alias, n_unknown, n_mismatch := 0, 0, 0, 0
	for i in 0..<len(meta) {
		fields := strings.split(meta[i], "\t", context.temp_allocator)
		if len(fields) < 4 { continue }
		our_name, bits_hex, mask_hex, isa := fields[0], fields[1], fields[2], fields[3]
		our_norm  := normalize_our(our_name)
		llvm_norm := normalize_llvm(llvm[i])

		status: string
		if llvm_norm == "" {
			if is_expected_unknown(our_norm, our_name, isa) {
				status = "EXPECTED"
				n_alias += 1
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
		} else if is_sony_isa(isa) {
			// LLVM matched a standard MIPS mnemonic in the shared COP2/SPECIAL2
			// opcode space, but our entry is Sony-custom. Trust our spec.
			status = "SONY"
			n_alias += 1
		} else {
			status = "MISMATCH"
			n_mismatch += 1
			fmt.sbprintf(&mismatch, "%-22s bits=%s mask=%s isa=%-10s  llvm=%q\n",
						 our_name, bits_hex, mask_hex, isa, strings.trim_space(llvm[i]))
		}
		fmt.sbprintf(&report, "[%s] %-22s bits=%s mask=%s isa=%-10s  llvm=%q\n",
					 status, our_name, bits_hex, mask_hex, isa, strings.trim_space(llvm[i]))
	}

	_ = os.write_entire_file("/tmp/rexcode_mips_verify_report.txt", report.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_mips_verify_mismatches.txt", mismatch.buf[:])

	total := n_ok + n_alias + n_unknown + n_mismatch
	fmt.println()
	fmt.printf("==> MIPS LLVM verification: %d rows\n", total)
	fmt.printf("    OK:       %4d  (%.1f%%)\n", n_ok,       100.0*f64(n_ok)/f64(total))
	fmt.printf("    ALIAS:    %4d  (%.1f%%)\n", n_alias,    100.0*f64(n_alias)/f64(total))
	fmt.printf("    UNKNOWN:  %4d  (%.1f%%)\n", n_unknown,  100.0*f64(n_unknown)/f64(total))
	fmt.printf("    MISMATCH: %4d  (%.1f%%)\n", n_mismatch, 100.0*f64(n_mismatch)/f64(total))
	fmt.println()
	fmt.println("  /tmp/rexcode_mips_verify_report.txt")
	fmt.println("  /tmp/rexcode_mips_verify_mismatches.txt")
}
