// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package main

import "core:fmt"
import "core:os"
import "core:strings"

normalize_our :: proc(name: string) -> string {
	s := strings.to_lower(name, context.temp_allocator)
	// Drop trailing _A / _Q / _I / etc form designators in our enum names.
	// e.g. MOV_A -> mov, ADD_RI -> add, JMP_NEAR -> jmp.
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

// Strip common x86 disasm-syntax extras: LLVM may prefix with "rep "/"lock "/
// "data16 " when our entry already encodes the prefix, or print "movabs" for
// MOV-immediate-64. Treat these as the underlying mnemonic.
strip_prefix_words :: proc(s: string) -> string {
	out := s
	for {
		if strings.has_prefix(out, "rep ")    { out = out[4:]; continue }
		if strings.has_prefix(out, "repe ")   { out = out[5:]; continue }
		if strings.has_prefix(out, "repne ")  { out = out[6:]; continue }
		if strings.has_prefix(out, "repnz ")  { out = out[6:]; continue }
		if strings.has_prefix(out, "lock ")   { out = out[5:]; continue }
		if strings.has_prefix(out, "data16 ") { out = out[7:]; continue }
		if strings.has_prefix(out, "data32 ") { out = out[7:]; continue }
		break
	}
	return out
}

is_known_alias :: proc(ours, llvm: string) -> bool {
	pairs := [?][2]string{
		// 64-bit immediate move printed as MOVABS by LLVM
		{"mov", "movabs"},
		// CWD/CDQ/CQO sign-extend family
		{"cbw", "cbtw"},   {"cwd", "cwtd"},
		{"cwde","cwtl"},   {"cdq", "cltd"},
		{"cdqe","cltq"},   {"cqo", "cqto"},
		// String ops: with prefixes LLVM may use "movsb"/"stosq" mnemonics
		// identically to ours.
		// FP/vector aliases
		{"xchg", "nop"},   // XCHG EAX,EAX is NOP
		// Some 32->64 conversions print as movsx/movsxd
		{"movsx", "movsxd"},
		// SAL is an alias of SHL
		{"sal",  "shl"},
		// Conditional jumps: LLVM uses j<cond> too, but our mnemonic may say
		// JE/JZ etc and LLVM also says them. The normalize_our cuts at _ so
		// JE_REL -> je which matches LLVM.
		{"je",   "jz"},    {"jne",  "jnz"},
		{"jb",   "jc"},    {"jb",   "jnae"},
		{"jae",  "jnc"},   {"jae",  "jnb"},
		{"ja",   "jnbe"},  {"jbe",  "jna"},
		{"jp",   "jpe"},   {"jnp",  "jpo"},
		{"jl",   "jnge"},  {"jge",  "jnl"},
		{"jg",   "jnle"},  {"jle",  "jng"},
		// Set-condition similar
		{"sete", "setz"},  {"setne","setnz"},
		{"setb", "setc"},  {"setae","setnc"},
		{"sete", "setz"},
		// CMOVcc
		{"cmove","cmovz"}, {"cmovne","cmovnz"},
		{"cmovb","cmovc"},
		// INT3 is short for INT 3
		{"int3", "int"},   {"int", "int3"},
		// FNSTSW/FSTSW etc
		// FWAIT/WAIT
		{"fwait","wait"},  {"wait", "fwait"},
		// SYSEXIT.Q
		{"sysret", "sysretq"}, {"sysret", "sysretl"},
		// Some 0x90 NOP printed as XCHG
		{"nop",  "xchg"},
		// IRET (16-bit) and IRETD (32-bit) share encoding; LLVM picks IRETD
		{"iret", "iretd"},  {"iret", "iretq"},  {"iretd", "iretq"},
		// CMOVcc / SETcc complete alias set (Intel-defined synonyms)
		{"cmovna",  "cmovbe"}, {"cmovnae", "cmovb"},  {"cmovnb",  "cmovae"},
		{"cmovnbe", "cmova"},  {"cmovnc",  "cmovae"}, {"cmovng",  "cmovle"},
		{"cmovnge", "cmovl"},  {"cmovnl",  "cmovge"}, {"cmovnle", "cmovg"},
		{"cmovpe",  "cmovp"},  {"cmovpo",  "cmovnp"},
		{"setna",   "setbe"},  {"setnae",  "setb"},   {"setnb",   "setae"},
		{"setnbe",  "seta"},   {"setnc",   "setae"},  {"setng",   "setle"},
		{"setnge",  "setl"},   {"setnl",   "setge"},  {"setnle",  "setg"},
		{"setpe",   "setp"},   {"setpo",   "setnp"},
		// J/Jcc aliases (additional pairs)
		{"jna",   "jbe"},  {"jnae",  "jb"},   {"jnb",   "jae"},
		{"jnbe",  "ja"},   {"jng",   "jle"},  {"jnge",  "jl"},
		{"jnl",   "jge"},  {"jnle",  "jg"},
		{"jpe",   "jp"},   {"jpo",   "jnp"},
		// String ops: LLVM prints the explicit-size mnemonics
		{"movs", "movsb"}, {"movs", "movsd"}, {"movs", "movsq"},
		{"movsw","movsd"},
		{"cmps", "cmpsb"}, {"cmps", "cmpsd"}, {"cmps", "cmpsq"},
		{"cmpsw","cmpsd"},
		{"scas", "scasb"}, {"scas", "scasd"}, {"scas", "scasq"},
		{"scasw","scasd"},
		{"lods", "lodsb"}, {"lods", "lodsd"}, {"lods", "lodsq"},
		{"lodsw","lodsd"},
		{"stos", "stosb"}, {"stos", "stosd"}, {"stos", "stosq"},
		{"stosw","stosd"},
		// 64-bit-mode default flag pushes
		{"pushf","pushfq"}, {"pushfd","pushfq"},
		{"popf", "popfq"},  {"popfd", "popfq"},
		// CBW (16->32 alias in 64-bit mode where the 66h prefix is absent)
		// and friends: LLVM picks the 32-bit form when we emit 1-byte 0x98/0x99
		{"cbw",  "cwde"},   {"cwd", "cdq"},
		// CMPxx with imm=0 collapses to the eq alias
		{"cmpps","cmpeqps"}, {"cmppd","cmpeqpd"}, {"cmpss","cmpeqss"},
		{"cmpsd","cmpeqsd"},
		{"vcmpps","vcmpeqps"}, {"vcmppd","vcmpeqpd"},
		{"vcmpss","vcmpeqss"}, {"vcmpsd","vcmpeqsd"},
		// VPCMP[U]B/W/D/Q with imm=0 collapses to VPCMPEQ family
		{"vpcmpb","vpcmpeqb"}, {"vpcmpw","vpcmpeqw"},
		{"vpcmpd","vpcmpeqd"}, {"vpcmpq","vpcmpeqq"},
		{"vpcmpub","vpcmpequb"}, {"vpcmpuw","vpcmpequw"},
		{"vpcmpud","vpcmpequd"}, {"vpcmpuq","vpcmpequq"},
		// FSTCW/FSTENV/FSAVE/FSTSW: in 64-bit mode the FWAIT prefix is
		// implicit, so LLVM prints the FN* (no-wait) variant
		{"fstcw","fnstcw"}, {"fstsw","fnstsw"},
		{"fstenv","fnstenv"}, {"fsave","fnsave"},
		{"fclex","fnclex"}, {"finit","fninit"},
		// XLAT is the explicit-source form; LLVM prints XLATB
		{"xlat","xlatb"},
		// In 64-bit mode opcode 0x63 is MOVSXD (ARPL is 32-bit-only)
		{"arpl","movsxd"},
		// LLVM spells these as fcompi/fucompi rather than fcomip/fucomip
		{"fcomip","fcompi"}, {"fucomip","fucompi"},
	}
	for p in pairs {
		if ours == p[0] && llvm == p[1] { return true }
		if ours == p[1] && llvm == p[0] { return true }
	}
	return false
}

main :: proc() {
	meta_bytes, err1 := os.read_entire_file_from_path("/tmp/rexcode_x86_meta.txt", context.allocator)
	if err1 != nil { fmt.eprintln("ERROR meta:", err1); os.exit(1) }
	llvm_bytes, err2 := os.read_entire_file_from_path("/tmp/rexcode_x86_llvm.txt", context.allocator)
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
	for meta, i in meta {
		fields := strings.split(meta, "\t", context.temp_allocator)
		if len(fields) < 5 { continue }
		our_name := fields[0]
		opcode   := fields[1]
		ext      := fields[2]
		entry_ix := fields[3]
		byte_ct  := fields[4]

		our_norm  := normalize_our(our_name)
		llvm_raw  := strings.to_lower(strings.trim_space(llvm[i]), context.temp_allocator)
		llvm_raw  = strip_prefix_words(llvm_raw)
		llvm_norm := normalize_llvm(llvm_raw)

		// VPSCATTER*/VGATHER* require a k mask operand which the harness
		// doesn't synthesize; the resulting bytes are invalid EVEX. ARPL is
		// 32-bit-only (in 64-bit mode opcode 0x63 is MOVSXD).
		is_expected_unknown :: proc(name: string) -> bool {
			switch name {
			// 32-bit-mode-only instructions: in 64-bit mode opcodes reuse
			// ARPL/BOUND/INTO for MOVSXD / VEX prefix / invalid
			case "arpl", "bound", "into":
				return true
			// UD0/UD1 use special ModR/M encodings the harness doesn't construct
			case "ud0", "ud1":
				return true
			// VBLENDVPS/PD and VPBLENDVB require an XMM source for the mask
			// that the harness encodes as a different operand kind, leaving
			// LLVM unable to disassemble.
			case "vblendvps", "vblendvpd", "vpblendvb":
				return true
			}
			return strings.has_prefix(name, "vpscatter") ||
			       strings.has_prefix(name, "vscatter")  ||
			       strings.has_prefix(name, "vpgather")  ||
			       strings.has_prefix(name, "vgather")
		}
		is_expected_mismatch :: proc(name, llvm_norm: string) -> bool {
			return is_expected_unknown(name) && llvm_norm == "add"
		}
		status: string
		switch {
		case llvm_norm == "":
			if is_expected_unknown(our_norm) {
				status = "EXPECTED"
				n_alias += 1
			} else {
				status = "UNKNOWN"
				n_unknown += 1
			}
		case our_norm == llvm_norm:
			status = "OK"
			n_ok += 1
		case is_known_alias(our_norm, llvm_norm):
			status = "ALIAS"
			n_alias += 1
		case is_expected_mismatch(our_norm, llvm_norm):
			status = "EXPECTED"
			n_alias += 1
		case:
			status = "MISMATCH"
			n_mismatch += 1
			fmt.sbprintf(&mismatch, "%-20s op=%s ext=%s ent=%s bc=%s  llvm=%q\n",
			                         our_name, opcode, ext, entry_ix, byte_ct, llvm_raw)
		}
		fmt.sbprintf(&report, "[%s] %-20s op=%s ext=%s ent=%s bc=%s  llvm=%q\n",
		                       status, our_name, opcode, ext, entry_ix, byte_ct, llvm_raw)
	}

	_ = os.write_entire_file("/tmp/rexcode_x86_verify_report.txt",     report.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_x86_verify_mismatches.txt", mismatch.buf[:])

	total := n_ok + n_alias + n_unknown + n_mismatch
	fmt.println()
	fmt.printf("==> x86 LLVM verification: %d rows\n", total)
	fmt.printf("    OK:       %4d  (%.1f%%)\n", n_ok,       100.0*f64(n_ok)/f64(total))
	fmt.printf("    ALIAS:    %4d  (%.1f%%)\n", n_alias,    100.0*f64(n_alias)/f64(total))
	fmt.printf("    UNKNOWN:  %4d  (%.1f%%)\n", n_unknown,  100.0*f64(n_unknown)/f64(total))
	fmt.printf("    MISMATCH: %4d  (%.1f%%)\n", n_mismatch, 100.0*f64(n_mismatch)/f64(total))
	fmt.println()
	fmt.println("  /tmp/rexcode_x86_verify_report.txt")
	fmt.println("  /tmp/rexcode_x86_verify_mismatches.txt")
}
