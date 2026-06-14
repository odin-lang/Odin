package rexcode_mos65816_tests

// End-to-end W65C816S smoke tests: opcode-matrix spot checks, encode->
// decode round-trips covering each addressing mode family, mode-flag
// disambiguation (M and X), 24-bit long addressing, block move, and the
// new 65816-specific mnemonics (JML/JSL/PEA/PEI/PER/REP/SEP/MVN/XBA/XCE).

import "core:fmt"
import "core:os"
import m "../"

@(private="file") passes := 0
@(private="file") failures := 0

@(private="file")
ok :: proc(name: string, cond: bool) {
	if cond {
		fmt.printfln("  [ok]   %s", name)
		passes += 1
	} else {
		fmt.printfln("  [FAIL] %s", name)
		failures += 1
	}
}

@(private="file")
eq_bytes :: proc(name: string, got, want: []u8) {
	same := len(got) == len(want)
	if same {
		for i in 0..<len(got) { if got[i] != want[i] { same = false; break } }
	}
	if same {
		fmt.printf("  [ok]   %-32s", name)
		for b in got { fmt.printf(" %02x", b) }
		fmt.println()
		passes += 1
	} else {
		fmt.printfln("  [FAIL] %s", name)
		fmt.printf("    got: ")
		for b in got  { fmt.printf("%02x ", b) }
		fmt.println()
		fmt.printf("    want:")
		for b in want { fmt.printf(" %02x", b) }
		fmt.println()
		failures += 1
	}
}

@(private="file")
eq_str :: proc(name, got, want: string) {
	if got == want {
		fmt.printfln("  [ok]   %s", name)
		passes += 1
	} else {
		fmt.printfln("  [FAIL] %s", name)
		fmt.printfln("    got:  %q", got)
		fmt.printfln("    want: %q", want)
		failures += 1
	}
}

@(private="file")
enc :: proc(insts: []m.Instruction) -> []u8 {
	@(static) code: [16]u8
	@(static) relocs: [dynamic]m.Relocation
	@(static) errors: [dynamic]m.Error
	clear(&relocs); clear(&errors)
	for i in 0..<len(code) { code[i] = 0 }
	r := m.encode(insts, nil, code[:], &relocs, &errors)
	if !r.success { return nil }
	return code[:r.byte_count]
}

main :: proc() {
	fmt.println("=== W65C816S smoke checks ===")

	// ---- 1. Addressing-mode encoding (ALU/STA/LDA representative slice) ----

	eq_bytes("LDA #$12  (M=1)",      enc({m.inst_i8 (.LDA, 0x12)}),                       {0xA9, 0x12})
	eq_bytes("LDA #$1234 (M=0)",     enc({m.inst_i16(.LDA, 0x1234)}),                     {0xA9, 0x34, 0x12})
	eq_bytes("LDA $12",              enc({m.inst_m(.LDA, m.mem_dp(0x12))}),               {0xA5, 0x12})
	eq_bytes("LDA $12,X",            enc({m.inst_m(.LDA, m.mem_dp_x(0x12))}),             {0xB5, 0x12})
	eq_bytes("LDA ($12,X)",          enc({m.inst_m(.LDA, m.mem_dp_ind_x(0x12))}),         {0xA1, 0x12})
	eq_bytes("LDA ($12),Y",          enc({m.inst_m(.LDA, m.mem_dp_ind_y(0x12))}),         {0xB1, 0x12})
	eq_bytes("LDA ($12)",            enc({m.inst_m(.LDA, m.mem_dp_ind(0x12))}),           {0xB2, 0x12})
	eq_bytes("LDA [$12]",            enc({m.inst_m(.LDA, m.mem_dp_ind_long(0x12))}),      {0xA7, 0x12})
	eq_bytes("LDA [$12],Y",          enc({m.inst_m(.LDA, m.mem_dp_ind_long_y(0x12))}),    {0xB7, 0x12})
	eq_bytes("LDA $1234",            enc({m.inst_m(.LDA, m.mem_abs(0x1234))}),            {0xAD, 0x34, 0x12})
	eq_bytes("LDA $1234,X",          enc({m.inst_m(.LDA, m.mem_abs_x(0x1234))}),          {0xBD, 0x34, 0x12})
	eq_bytes("LDA $1234,Y",          enc({m.inst_m(.LDA, m.mem_abs_y(0x1234))}),          {0xB9, 0x34, 0x12})
	eq_bytes("LDA $123456",          enc({m.inst_m(.LDA, m.mem_long(0x123456))}),         {0xAF, 0x56, 0x34, 0x12})
	eq_bytes("LDA $123456,X",        enc({m.inst_m(.LDA, m.mem_long_x(0x123456))}),       {0xBF, 0x56, 0x34, 0x12})
	eq_bytes("LDA $12,S",            enc({m.inst_m(.LDA, m.mem_sr(0x12))}),               {0xA3, 0x12})
	eq_bytes("LDA ($12,S),Y",        enc({m.inst_m(.LDA, m.mem_sr_ind_y(0x12))}),         {0xB3, 0x12})

	// ---- 2. Mode-flag-dependent immediates for X/Y -----------------------
	eq_bytes("LDX #$12  (X=1)",      enc({m.inst_i8 (.LDX, 0x12)}),                       {0xA2, 0x12})
	eq_bytes("LDX #$1234 (X=0)",     enc({m.inst_i16(.LDX, 0x1234)}),                     {0xA2, 0x34, 0x12})
	eq_bytes("CPX #$12  (X=1)",      enc({m.inst_i8 (.CPX, 0x12)}),                       {0xE0, 0x12})

	// ---- 3. 65816-only jumps / returns -----------------------------------
	eq_bytes("JML $123456",          enc({m.inst_m(.JML, m.mem_long(0x123456))}),         {0x5C, 0x56, 0x34, 0x12})
	eq_bytes("JSL $123456",          enc({m.inst_m(.JSL, m.mem_long(0x123456))}),         {0x22, 0x56, 0x34, 0x12})
	eq_bytes("JML [$1234]",          enc({m.inst_m(.JML, m.mem_abs_ind_long(0x1234))}),   {0xDC, 0x34, 0x12})
	eq_bytes("RTL",                  enc({m.inst_none(.RTL)}),                            {0x6B})

	// ---- 4. Stack-effective / mode flags ---------------------------------
	eq_bytes("PEA $1234",            enc({m.inst_m(.PEA, m.mem_abs(0x1234))}),            {0xF4, 0x34, 0x12})
	eq_bytes("PEI ($12)",            enc({m.inst_m(.PEI, m.mem_dp_ind(0x12))}),           {0xD4, 0x12})
	eq_bytes("PHB",                  enc({m.inst_none(.PHB)}),                            {0x8B})
	eq_bytes("PHD",                  enc({m.inst_none(.PHD)}),                            {0x0B})
	eq_bytes("PHK",                  enc({m.inst_none(.PHK)}),                            {0x4B})
	eq_bytes("REP #$30",             enc({m.inst_i8(.REP, 0x30)}),                        {0xC2, 0x30})
	eq_bytes("SEP #$30",             enc({m.inst_i8(.SEP, 0x30)}),                        {0xE2, 0x30})
	eq_bytes("XBA",                  enc({m.inst_none(.XBA)}),                            {0xEB})
	eq_bytes("XCE",                  enc({m.inst_none(.XCE)}),                            {0xFB})
	eq_bytes("TCD",                  enc({m.inst_none(.TCD)}),                            {0x5B})
	eq_bytes("TCS",                  enc({m.inst_none(.TCS)}),                            {0x1B})
	eq_bytes("TXY",                  enc({m.inst_none(.TXY)}),                            {0x9B})

	// ---- 5. Block move: MVN/MVP src,dst -> opcode | dst | src ------------
	eq_bytes("MVN $00, $7E",         enc({m.inst_block_move(.MVN, 0x00, 0x7E)}),          {0x54, 0x7E, 0x00})
	eq_bytes("MVP $7E, $00",         enc({m.inst_block_move(.MVP, 0x7E, 0x00)}),          {0x44, 0x00, 0x7E})

	// ---- 6. BRL long relative branch -------------------------------------
	{
		@(static) code: [16]u8
		@(static) relocs: [dynamic]m.Relocation
		@(static) errors: [dynamic]m.Error
		clear(&relocs); clear(&errors)

		ld: [dynamic]m.Label_Definition
		defer delete(ld)
		append(&ld, m.Label_Definition(2))   // target at inst index 2

		insts := []m.Instruction{
			m.inst_rel_long(.BRL, 0),    // 3 bytes
			m.inst_none(.NOP),             // 1 byte
			m.inst_none(.RTS),             // 1 byte (target)
		}
		r := m.encode(insts, ld[:], code[:], &relocs, &errors)
		ok("BRL encode ok", r.success)
		// BRL at pc=0, target at byte 4. next_pc = 3. rel = 4-3 = 1.
		eq_bytes("BRL forward", code[:r.byte_count], {0x82, 0x01, 0x00, 0xEA, 0x60})
	}

	// ---- 7. PER (push effective PC-rel, 16-bit signed) -------------------
	{
		@(static) code: [16]u8
		@(static) relocs: [dynamic]m.Relocation
		@(static) errors: [dynamic]m.Error
		clear(&relocs); clear(&errors)

		ld: [dynamic]m.Label_Definition
		defer delete(ld)
		append(&ld, m.Label_Definition(2))   // target at inst 2

		insts := []m.Instruction{
			m.Instruction{
				mnemonic = .PER, operand_count = 1, length = 3,
				ops = {m.op_label(0, 2), {}},
			},
			m.inst_none(.NOP),
			m.inst_none(.RTS),
		}
		r := m.encode(insts, ld[:], code[:], &relocs, &errors)
		ok("PER encode ok", r.success)
		eq_bytes("PER forward",  code[:r.byte_count], {0x62, 0x01, 0x00, 0xEA, 0x60})
	}

	// ---- 8. Round-trip: encode -> decode in 16-bit native, print ---------
	{
		@(static) code: [32]u8
		@(static) relocs: [dynamic]m.Relocation
		@(static) errors: [dynamic]m.Error
		clear(&relocs); clear(&errors)

		ld: [dynamic]m.Label_Definition
		defer delete(ld)
		append(&ld, m.Label_Definition(0))   // loop: at inst 0

		src := []m.Instruction{
			m.inst_i16(.LDA, 0x1234),                // 3 bytes (M=0)
			m.inst_m(.STA, m.mem_long(0x7E1000)),    // 4 bytes
			m.inst_rel(.BRA, 0),                      // 2 bytes back to loop
		}
		r := m.encode(src, ld[:], code[:], &relocs, &errors)
		ok("rt: encode ok", r.success)

		d_insts:  [dynamic]m.Instruction
		d_info:   [dynamic]m.Instruction_Info
		d_labels: [dynamic]m.Label_Definition
		defer delete(d_insts); defer delete(d_info); defer delete(d_labels)
		clear(&errors)
		d := m.decode(code[:r.byte_count], nil,
					  &d_insts, &d_info, &d_labels, &errors,
					  state = m.NATIVE_16)
		ok("rt: decode ok", d.success)
		ok("rt: 3 insts",   len(d_insts) == 3)
		ok("rt: LDA",       d_insts[0].mnemonic == .LDA)
		ok("rt: STA",       d_insts[1].mnemonic == .STA)
		ok("rt: BRA",       d_insts[2].mnemonic == .BRA)

		text := m.aprint(d_insts[:], d_info[:], d_labels[:],
						 nil, nil, nil, context.temp_allocator)
		eq_str("rt: print",
			   text,
			   ".L0:\n    lda #$1234\n    sta $7e1000\n    bra .L0\n")
	}

	// ---- 9. Decoder picks IMM_M8 vs IMM_M16 per assumed state -----------
	{
		// Byte stream: A9 12 34 (could be LDA #$12 in M=1, then NOP at 0x34?
		// No, $34 is BIT zp,X. Let me use a simpler stream.)
		//
		// We want: A9 12  (LDA #$12 in M=1)   ->  2 insts since one byte left
		//          A9 34 12  (LDA #$1234 in M=0) -> 1 inst
		//
		// Use stream A9 12 EA EA:
		//   M=1: LDA #$12 (2 bytes) + NOP (1) + NOP (1) -> 3 insts
		//   M=0: LDA #$EA12 (3 bytes) + NOP (1)         -> 2 insts
		code := []u8{0xA9, 0x12, 0xEA, 0xEA}

		d_insts1:  [dynamic]m.Instruction
		d_info1:   [dynamic]m.Instruction_Info
		d_labels1: [dynamic]m.Label_Definition
		errs1:     [dynamic]m.Error
		defer delete(d_insts1); defer delete(d_info1); defer delete(d_labels1); defer delete(errs1)

		m.decode(code, nil, &d_insts1, &d_info1, &d_labels1, &errs1, state = m.NATIVE_8)
		ok("M=1: 3 insts", len(d_insts1) == 3)
		ok("M=1: LDA #$12", d_insts1[0].mnemonic == .LDA &&
							d_insts1[0].ops[0].immediate == 0x12 &&
							d_insts1[0].ops[0].size == 1)

		d_insts2:  [dynamic]m.Instruction
		d_info2:   [dynamic]m.Instruction_Info
		d_labels2: [dynamic]m.Label_Definition
		errs2:     [dynamic]m.Error
		defer delete(d_insts2); defer delete(d_info2); defer delete(d_labels2); defer delete(errs2)

		m.decode(code, nil, &d_insts2, &d_info2, &d_labels2, &errs2, state = m.NATIVE_16)
		ok("M=0: 2 insts", len(d_insts2) == 2)
		ok("M=0: LDA #$EA12", d_insts2[0].mnemonic == .LDA &&
							  d_insts2[0].ops[0].immediate == 0xEA12 &&
							  d_insts2[0].ops[0].size == 2)
	}

	// ---- 10. Printer: every addressing-mode renders correctly ------------
	{
		@(static) code: [32]u8
		@(static) relocs: [dynamic]m.Relocation
		@(static) errors: [dynamic]m.Error
		clear(&relocs); clear(&errors)

		src := []m.Instruction{
			m.inst_m(.LDA, m.mem_dp_ind_long_y(0x12)),
			m.inst_m(.STA, m.mem_long_x(0x7E1234)),
			m.inst_m(.JML, m.mem_abs_ind_long(0xFFFC)),
			m.inst_m(.LDA, m.mem_sr_ind_y(0x10)),
		}
		r := m.encode(src, nil, code[:], &relocs, &errors)

		d_insts:  [dynamic]m.Instruction
		d_info:   [dynamic]m.Instruction_Info
		d_labels: [dynamic]m.Label_Definition
		defer delete(d_insts); defer delete(d_info); defer delete(d_labels)
		clear(&errors)
		m.decode(code[:r.byte_count], nil, &d_insts, &d_info, &d_labels, &errors,
				 state = m.NATIVE_16)

		text := m.aprint(d_insts[:], d_info[:], d_labels[:],
						 nil, nil, nil, context.temp_allocator)
		eq_str("print: each mode",
			   text,
			   "    lda [$12],y\n    sta $7e1234,x\n    jml [$fffc]\n    lda ($10,s),y\n")
	}

	fmt.println()
	fmt.printfln("==> mos65816: %d passed, %d failed", passes, failures)
	if failures > 0 { os.exit(1) }
}
