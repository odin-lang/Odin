// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package main

import "core:fmt"
import "core:os"
import "core:strings"

// RISC-V mnemonics use underscore for various suffixes:
//   ADD_W -> addw, FADD_S -> fadd.s, AMOSWAP_W -> amoswap.w, etc.
// Translate LLVM dots to underscores so they compare directly.
normalize_our :: proc(name: string) -> string {
	// Use llvm-mc -M no-aliases which prints `c.addi` for compressed forms,
	// so keep our "C_ADDI" -> "c_addi" and the prefixes match after the
	// dot-to-underscore translation on the LLVM side.
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
	pairs := [?][2]string{
		// ADDI x0, x0, 0 -> NOP
		{"addi", "nop"},
		// ADD x, y, x0 -> MV
		{"add",  "mv"},
		{"addi", "mv"},
		// JAL x0, off -> J ; JAL ra, off stays JAL
		{"jal",  "j"},
		// JALR x0, x, 0 -> JR ; JALR ra, x, 0 -> stays
		{"jalr", "jr"},
		{"jalr", "ret"},
		// BEQ x, x0, off -> BEQZ ; same for BNE/BLT etc.
		{"beq",  "beqz"},
		{"bne",  "bnez"},
		{"blt",  "bltz"},   {"blt", "bgtz"},
		{"bge",  "bgez"},   {"bge", "blez"},
		{"bgeu", "bleu"},
		{"bltu", "bgtu"},
		// SUB x0,x,y -> NEG; SUBW -> NEGW
		{"sub",  "neg"},
		{"subw", "negw"},
		// XORI rd, rs, -1 -> NOT
		{"xori", "not"},
		// ADDIW rd, rs, 0 -> SEXT.W
		{"addiw","sext_w"},
		// SLTIU rd, rs, 1 -> SEQZ
		{"sltiu","seqz"},
		// SLTU rd, x0, rs -> SNEZ
		{"sltu", "snez"},
		// SLT rd, rs, x0 -> SLTZ; SLT rd, x0, rs -> SGTZ
		{"slt",  "sltz"},   {"slt", "sgtz"},
		// CSR pseudos: CSRRW/S/C with rd=x0 -> CSRW/S/C; etc.
		{"csrrw","csrw"},   {"csrrs","csrr"},   {"csrrs","csrs"},   {"csrrc","csrc"},
		{"csrrwi","csrwi"}, {"csrrsi","csrsi"}, {"csrrci","csrci"},
		// FMV.W.X / FMV.X.W aliases
		{"fmv_w_x","fmv_w_x"}, {"fmv_x_w","fmv_x_w"},
		// F-extension aliases: FSGNJ rd, rs, rs -> FMV; FSGNJX rs, rs -> FABS; FSGNJN -> FNEG
		{"fsgnj_s","fmv_s"}, {"fsgnjx_s","fabs_s"}, {"fsgnjn_s","fneg_s"},
		{"fsgnj_d","fmv_d"}, {"fsgnjx_d","fabs_d"}, {"fsgnjn_d","fneg_d"},
		// FENCE aliases
		{"fence","fence"},
		// Compressed bases that decode as "c.unimp" / "c.nop" / "c.ebreak"
		// when all operand bits are zero (special encodings)
		{"c_addi4spn", "c_unimp"},   // all-zero compressed = c.unimp
		{"c_addi",     "c_nop"},     // C.ADDI with rd=0 -> C.NOP
		{"c_jalr",     "c_ebreak"},  // C.JALR rd=0 -> C.EBREAK
		{"c_add",      "c_ebreak"},  // C.ADD rd=0 -> C.EBREAK
	}
	for p in pairs {
		if ours == p[0] && llvm == p[1] { return true }
		if ours == p[1] && llvm == p[0] { return true }
	}
	return false
}

main :: proc() {
	meta_bytes, err1 := os.read_entire_file_from_path("/tmp/rexcode_riscv_meta.txt", context.allocator)
	if err1 != nil { fmt.eprintln("ERROR meta:", err1); os.exit(1) }
	llvm_bytes, err2 := os.read_entire_file_from_path("/tmp/rexcode_riscv_llvm.txt", context.allocator)
	if err2 != nil { fmt.eprintln("ERROR llvm:", err2); os.exit(1) }

	meta := strings.split_lines(string(meta_bytes))
	llvm := strings.split_lines(string(llvm_bytes))
	if len(meta) > 0 && meta[len(meta)-1] == "" { meta = meta[:len(meta)-1] }
	if len(llvm) > 0 && llvm[len(llvm)-1] == "" { llvm = llvm[:len(llvm)-1] }
	if len(meta) != len(llvm) {
		fmt.eprintf("ERROR: meta=%d llvm=%d\n", len(meta), len(llvm))
		os.exit(1)
	}

	report, mismatch: strings.Builder
	strings.builder_init(&report)
	strings.builder_init(&mismatch)
	defer strings.builder_destroy(&report)
	defer strings.builder_destroy(&mismatch)

	n_ok, n_alias, n_unknown, n_mismatch := 0, 0, 0, 0
	for i in 0..<len(meta) {
		fields := strings.split(meta[i], "\t", context.temp_allocator)
		if len(fields) < 5 { continue }
		our_name := fields[0]
		bits_hex := fields[1]
		mask_hex := fields[2]
		ext      := fields[3]
		size     := fields[4]

		our_norm  := normalize_our(our_name)
		llvm_norm := normalize_llvm(llvm[i])

		// Compressed instructions whose base bits (operands=0) hit a
		// reserved encoding -- e.g. C_LUI requires rd!=0 and rd!=x2,
		// C_LWSP/C_LDSP require rd!=0, C_JR/C_MV require rs1!=0,
		// C_JAL is RV32-only and collides with C_ADDIW in RV64.
		is_expected_unknown :: proc(name: string) -> bool {
			switch name {
			case "c_addiw", "c_lui", "c_addi16sp", "c_jal",
				 "c_lwsp",  "c_ldsp", "c_jr", "c_mv":
				return true
			}
			return false
		}
		status: string
		if llvm_norm == "" {
			if is_expected_unknown(our_norm) {
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
		} else {
			status = "MISMATCH"
			n_mismatch += 1
			fmt.sbprintf(&mismatch, "%-22s bits=%s mask=%s ext=%-6s size=%s  llvm=%q\n",
						 our_name, bits_hex, mask_hex, ext, size, strings.trim_space(llvm[i]))
		}
		fmt.sbprintf(&report, "[%s] %-22s bits=%s mask=%s ext=%-6s size=%s  llvm=%q\n",
					 status, our_name, bits_hex, mask_hex, ext, size, strings.trim_space(llvm[i]))
	}

	_ = os.write_entire_file("/tmp/rexcode_riscv_verify_report.txt", report.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_riscv_verify_mismatches.txt", mismatch.buf[:])

	total := n_ok + n_alias + n_unknown + n_mismatch
	fmt.println()
	fmt.printf("==> RISC-V LLVM verification: %d rows\n", total)
	fmt.printf("    OK:       %4d  (%.1f%%)\n", n_ok,       100.0*f64(n_ok)/f64(total))
	fmt.printf("    ALIAS:    %4d  (%.1f%%)\n", n_alias,    100.0*f64(n_alias)/f64(total))
	fmt.printf("    UNKNOWN:  %4d  (%.1f%%)\n", n_unknown,  100.0*f64(n_unknown)/f64(total))
	fmt.printf("    MISMATCH: %4d  (%.1f%%)\n", n_mismatch, 100.0*f64(n_mismatch)/f64(total))
	fmt.println()
	fmt.println("  /tmp/rexcode_riscv_verify_report.txt")
	fmt.println("  /tmp/rexcode_riscv_verify_mismatches.txt")
}
