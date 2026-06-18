// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_mos6502_tests

// End-to-end MOS 6502 pipeline tests: encode -> decode -> print round-trips
// across every addressing mode, CPU tier (NMOS, undocumented, 65C02,
// HuC6280), branch label inference, ABS16 reloc, and HuC block xfer.

import "core:fmt"
import "core:os"
import m "../"

@(private="file") rpasses   := 0
@(private="file") rfailures := 0

@(private="file")
ok :: proc(name: string, cond: bool) {
	if cond {
		fmt.printfln("  [ok]   %s", name)
		rpasses += 1
	} else {
		fmt.printfln("  [FAIL] %s", name)
		rfailures += 1
	}
}

@(private="file")
eq_bytes :: proc(name: string, got, want: []u8) {
	same := len(got) == len(want)
	if same {
		for i in 0..<len(got) {
			if got[i] != want[i] { same = false; break }
		}
	}
	if same {
		fmt.printf("  [ok]   %-30s", name)
		for b in got { fmt.printf(" %02x", b) }
		fmt.println()
		rpasses += 1
	} else {
		fmt.printfln("  [FAIL] %s", name)
		fmt.printf("    got: ")
		for b in got  { fmt.printf("%02x ", b) }
		fmt.println()
		fmt.printf("    want:")
		for b in want { fmt.printf(" %02x", b) }
		fmt.println()
		rfailures += 1
	}
}

@(private="file")
eq_str :: proc(name, got, want: string) {
	if got == want {
		fmt.printfln("  [ok]   %s", name)
		rpasses += 1
	} else {
		fmt.printfln("  [FAIL] %s", name)
		fmt.printfln("    got:  %q", got)
		fmt.printfln("    want: %q", want)
		rfailures += 1
	}
}

@(private="file")
encode_one :: proc(insts: []m.Instruction) -> ([]u8, bool) {
	@(static) code: [256]u8
	@(static) relocs: [dynamic]m.Relocation
	@(static) errors: [dynamic]m.Error
	clear(&relocs); clear(&errors)
	for i in 0..<len(code) { code[i] = 0 }
	byte_count, success := m.encode(insts, nil, code[:], &relocs, &errors)
	return code[:byte_count], success
}

run_pipeline_tests :: proc() {
	fmt.println()
	fmt.println("=== MOS 6502 pipeline spot checks ===")

	relocs: [dynamic]m.Relocation
	errors: [dynamic]m.Error
	defer delete(relocs)
	defer delete(errors)

	// ---- 1. Each addressing mode encodes to the right byte sequence -------
	eq_bytes("LDA #$12",         encode_or_fail({m.inst_i(.LDA, 0x12)}),                  {0xA9, 0x12})
	eq_bytes("LDA $12",          encode_or_fail({m.inst_m(.LDA, m.mem_zp(0x12))}),        {0xA5, 0x12})
	eq_bytes("LDA $12,X",        encode_or_fail({m.inst_m(.LDA, m.mem_zp_x(0x12))}),      {0xB5, 0x12})
	eq_bytes("LDA $1234",        encode_or_fail({m.inst_m(.LDA, m.mem_abs(0x1234))}),     {0xAD, 0x34, 0x12})
	eq_bytes("LDA $1234,X",      encode_or_fail({m.inst_m(.LDA, m.mem_abs_x(0x1234))}),   {0xBD, 0x34, 0x12})
	eq_bytes("LDA $1234,Y",      encode_or_fail({m.inst_m(.LDA, m.mem_abs_y(0x1234))}),   {0xB9, 0x34, 0x12})
	eq_bytes("LDA ($12,X)",      encode_or_fail({m.inst_m(.LDA, m.mem_ind_x(0x12))}),     {0xA1, 0x12})
	eq_bytes("LDA ($12),Y",      encode_or_fail({m.inst_m(.LDA, m.mem_ind_y(0x12))}),     {0xB1, 0x12})
	eq_bytes("ASL A",            encode_or_fail({m.inst_a(.ASL)}),                        {0x0A})
	eq_bytes("BRK",              encode_or_fail({m.inst_none(.BRK)}),                     {0x00})
	eq_bytes("NOP",              encode_or_fail({m.inst_none(.NOP)}),                     {0xEA})
	eq_bytes("JMP ($1234)",      encode_or_fail({m.inst_m(.JMP, m.mem_ind(0x1234))}),     {0x6C, 0x34, 0x12})

	// ---- 2. 65C02-only addressing modes -----------------------------------
	eq_bytes("LDA ($12)",        encode_or_fail({m.inst_m(.LDA, m.mem_ind_zp(0x12))}),    {0xB2, 0x12})
	eq_bytes("STZ $1234",        encode_or_fail({m.inst_m(.STZ, m.mem_abs(0x1234))}),     {0x9C, 0x34, 0x12})
	eq_bytes("BIT #$42",         encode_or_fail({m.inst_i(.BIT, 0x42)}),                  {0x89, 0x42})
	eq_bytes("JMP ($1234,X)",    encode_or_fail({m.inst_m(.JMP, m.mem_ind_abs_x(0x1234))}), {0x7C, 0x34, 0x12})

	// ---- 3. NMOS undocumented ---------------------------------------------
	eq_bytes("LAX $12",          encode_or_fail({m.inst_m(.LAX, m.mem_zp(0x12))}),        {0xA7, 0x12})
	eq_bytes("DCP $1234",        encode_or_fail({m.inst_m(.DCP, m.mem_abs(0x1234))}),     {0xCF, 0x34, 0x12})
	eq_bytes("ALR #$0F",         encode_or_fail({m.inst_i(.ALR, 0x0F)}),                  {0x4B, 0x0F})

	// ---- 4. 65C02 bit ops -------------------------------------------------
	eq_bytes("RMB0 $42",         encode_or_fail({m.inst_m(.RMB0, m.mem_zp(0x42))}),       {0x07, 0x42})
	eq_bytes("SMB7 $42",         encode_or_fail({m.inst_m(.SMB7, m.mem_zp(0x42))}),       {0xF7, 0x42})

	// ---- 5. HuC6280 -------------------------------------------------------
	eq_bytes("SAX (HuC)",        encode_or_fail({m.inst_none(.SAX)}),                     {0x22})
	eq_bytes("CLA",              encode_or_fail({m.inst_none(.CLA)}),                     {0x62})
	eq_bytes("ST0 #$05",         encode_or_fail({m.inst_i(.ST0, 0x05)}),                  {0x03, 0x05})
	eq_bytes("TST #$10, $80",    encode_or_fail({m.inst_tst(0x10, m.mem_zp(0x80))}), {0x83, 0x10, 0x80})
	eq_bytes("TII",              encode_or_fail({m.inst_block(.TII, 0x4000, 0x2000, 0x100)}),
			 {0x73, 0x00, 0x40, 0x00, 0x20, 0x00, 0x01})

	// ---- 6. Branch with backward label ------------------------------------
	//   loop:                          (pc=0)  - label_def[0] = 0
	//         lda $42                  (pc=0..1, 2 bytes)
	//         dex                      (pc=2,   1 byte)
	//         bne loop                 (pc=3..4, 2 bytes; rel = -5)
	//         rts                      (pc=5,   1 byte)
	{
		clear(&relocs); clear(&errors)
		code: [16]u8

		ld: [dynamic]m.Label_Definition
		defer delete(ld)
		append(&ld, m.Label_Definition(0))

		insts := []m.Instruction{
			m.inst_m(.LDA, m.mem_zp(0x42)),
			m.inst_none(.DEX),
			m.inst_rel(.BNE, 0),
			m.inst_none(.RTS),
		}
		byte_count, success := m.encode(insts, ld[:], code[:], &relocs, &errors)
		ok("br: encode ok", success)
		// BNE rel byte at code[4]; target = 0, next_pc = 5, rel = -5.
		eq_bytes("br: bytes", code[:byte_count],
				 {0xA5, 0x42, 0xCA, 0xD0, 0xFB, 0x60})
		// label_defs[0] should be byte offset 0.
		ok("br: label_def[0] = 0", int(ld[0]) == 0)
	}

	// ---- 7. JMP $label (ABS16 reloc) ---------------------------------------
	//   start:  nop              (pc=0)
	//           jmp target       (pc=1..3, 3 bytes)
	//   target: rts              (pc=4)
	//   base_address=0x8000 -> target_abs=0x8004 -> JMP encodes $04 $80
	{
		clear(&relocs); clear(&errors)
		code: [16]u8

		ld: [dynamic]m.Label_Definition
		defer delete(ld)
		append(&ld, m.Label_Definition(2))   // inst 2 = "target:"

		insts := []m.Instruction{
			m.inst_none(.NOP),
			m.inst_rel(.JMP, 0),    // RELATIVE operand; matcher pairs with MEM_ABS form
			m.inst_none(.RTS),
		}
		// Patch inst_rel call -- JMP needs a label producing ABS16, so the
		// RELATIVE operand's size should be 2.  inst_rel sets size=1; use
		// op_label directly.
		insts[1] = m.Instruction{
			mnemonic = .JMP, operand_count = 1, length = 0,
			ops = {m.op_label(0, 2), {}, {}},
		}
		byte_count, success := m.encode(insts, ld[:], code[:], &relocs, &errors,
					  base_address = 0x8000)
		ok("jmp lbl: encode ok", success)
		eq_bytes("jmp lbl: bytes", code[:byte_count],
				 {0xEA, 0x4C, 0x04, 0x80, 0x60})
	}

	// ---- 8. Round-trip: decode + print of a small NMOS program ------------
	{
		clear(&relocs); clear(&errors)
		code: [64]u8

		ld: [dynamic]m.Label_Definition
		defer delete(ld)
		append(&ld, m.Label_Definition(0))   // loop:

		src := []m.Instruction{
			m.inst_m(.LDA, m.mem_zp(0x42)),
			m.inst_none(.DEX),
			m.inst_rel(.BNE, 0),
			m.inst_none(.RTS),
		}
		byte_count, success := m.encode(src, ld[:], code[:], &relocs, &errors)
		ok("rt: encode ok", success)

		d_insts:  [dynamic]m.Instruction
		d_info:   [dynamic]m.Instruction_Info
		d_labels: [dynamic]m.Label_Definition
		defer delete(d_insts)
		defer delete(d_info)
		defer delete(d_labels)
		clear(&errors)
		_, dsuccess := m.decode(code[:byte_count], nil,
					  &d_insts, &d_info, &d_labels, &errors)
		ok("rt: decode ok",   dsuccess)
		ok("rt: 4 insts",     len(d_insts) == 4)
		ok("rt: LDA",         d_insts[0].mnemonic == .LDA)
		ok("rt: BNE",         d_insts[2].mnemonic == .BNE)
		ok("rt: RTS",         d_insts[3].mnemonic == .RTS)
		ok("rt: label at 0",  len(d_labels) >= 1 && int(d_labels[0]) == 0)

		text := m.aprint(d_insts[:], d_info[:], d_labels[:],
						 nil, nil, nil, context.temp_allocator)
		eq_str("rt: print",
			   text,
			   ".L0:\n    lda $42\n    dex\n    bne .L0\n    rts\n")
	}

	// ---- 9. Decode + print: 65C02 stuff with named labels -----------------
	{
		clear(&relocs); clear(&errors)
		code: [64]u8

		ld: [dynamic]m.Label_Definition
		defer delete(ld)
		append(&ld, m.Label_Definition(0))

		src := []m.Instruction{
			m.inst_m(.LDA, m.mem_ind_zp(0x80)),     // 65C02 (zp)
			m.inst_m(.STZ, m.mem_abs(0x1234)),      // 65C02 STZ
			m.inst_rel(.BRA, 0),                     // 65C02 BRA
		}
		byte_count, success := m.encode(src, ld[:], code[:], &relocs, &errors)

		d_insts:  [dynamic]m.Instruction
		d_info:   [dynamic]m.Instruction_Info
		d_labels: [dynamic]m.Label_Definition
		defer delete(d_insts)
		defer delete(d_info)
		defer delete(d_labels)
		clear(&errors)
		// Decode in 65C02 mode -- $B2 is LDA(zp), $9C is STZ, $80 is BRA.
		m.decode(code[:byte_count], nil,
				 &d_insts, &d_info, &d_labels, &errors, cpu = .CMOS_65C02)

		names: map[u32]string
		defer delete(names)
		names[0] = "start"

		text := m.aprint(d_insts[:], d_info[:], d_labels[:],
						 nil, nil, &names, context.temp_allocator)
		eq_str("65C02: print",
			   text,
			   "start:\n    lda ($80)\n    stz $1234\n    bra start\n")
	}

	// ---- 10. CPU-tier filter: $07 is SLO on NMOS_UNDOC, RMB0 on 65C02 ----
	{
		// Build a byte stream of {0x07, 0x42, 0x60}: $07 op + zp byte + RTS.
		code := []u8{0x07, 0x42, 0x60}

		// Decode as NMOS (no undoc): $07 is unrecognized.
		d_insts:  [dynamic]m.Instruction
		d_info:   [dynamic]m.Instruction_Info
		d_labels: [dynamic]m.Label_Definition
		defer delete(d_insts); defer delete(d_info); defer delete(d_labels)
		clear(&errors)
		m.decode(code, nil, &d_insts, &d_info, &d_labels, &errors, cpu = .NMOS)
		ok("$07 on NMOS: INVALID", len(d_insts) >= 1 && d_insts[0].mnemonic == .INVALID)

		// Decode as NMOS_UNDOC: $07 is SLO.
		clear(&d_insts); clear(&d_info); clear(&d_labels); clear(&errors)
		m.decode(code, nil, &d_insts, &d_info, &d_labels, &errors, cpu = .NMOS_UNDOC)
		ok("$07 on NMOS_UNDOC: SLO", len(d_insts) >= 1 && d_insts[0].mnemonic == .SLO)

		// Decode as 65C02: $07 is RMB0.
		clear(&d_insts); clear(&d_info); clear(&d_labels); clear(&errors)
		m.decode(code, nil, &d_insts, &d_info, &d_labels, &errors, cpu = .CMOS_65C02)
		ok("$07 on 65C02: RMB0",     len(d_insts) >= 1 && d_insts[0].mnemonic == .RMB0)
	}

	// ---- 11. HuC6280 block transfer round-trip ----------------------------
	{
		clear(&relocs); clear(&errors)
		code: [16]u8
		src := []m.Instruction{
			m.inst_block(.TII, 0x4000, 0x2000, 0x100),
		}
		byte_count, success := m.encode(src, nil, code[:], &relocs, &errors)
		ok("huc tii: encode ok", success)
		ok("huc tii: 7 bytes",   int(byte_count) == 7)

		d_insts:  [dynamic]m.Instruction
		d_info:   [dynamic]m.Instruction_Info
		d_labels: [dynamic]m.Label_Definition
		defer delete(d_insts); defer delete(d_info); defer delete(d_labels)
		clear(&errors)
		m.decode(code[:byte_count], nil, &d_insts, &d_info, &d_labels, &errors,
				 cpu = .HUC6280)
		ok("huc tii: decode TII",   len(d_insts) >= 1 && d_insts[0].mnemonic == .TII)
		ok("huc tii: 3 operands",   d_insts[0].operand_count == 3)
		ok("huc tii: src=0x4000",   d_insts[0].ops[0].immediate == 0x4000)
		ok("huc tii: dst=0x2000",   d_insts[0].ops[1].immediate == 0x2000)
		ok("huc tii: len=0x100",    d_insts[0].ops[2].immediate == 0x100)
	}

	fmt.println()
	fmt.printfln("==> pipeline: %d passed, %d failed", rpasses, rfailures)
	if rfailures > 0 { os.exit(1) }
}

@(private="file")
encode_or_fail :: proc(insts: []m.Instruction) -> []u8 {
	@(static) code: [16]u8
	@(static) relocs: [dynamic]m.Relocation
	@(static) errors: [dynamic]m.Error
	clear(&relocs); clear(&errors)
	for i in 0..<len(code) { code[i] = 0 }
	byte_count, success := m.encode(insts, nil, code[:], &relocs, &errors)
	if !success { return nil }
	return code[:byte_count]
}
