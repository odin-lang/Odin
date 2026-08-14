// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_mos6502_tests

// Spot-check that ENCODING_TABLE entries are present with the canonical
// opcode bytes and lengths. Covers a representative slice of every
// CPU tier (NMOS official, NMOS undocumented, 65C02, HuC6280).
//
// Run with: odin run mos6502/tests

import "core:fmt"
import "core:os"
import m "../"

@(private="file") passes := 0
@(private="file") failures := 0

@(private="file")
check :: proc(
	name: string,
	mn:   m.Mnemonic,
	want_mode_idx: int,    // which form (index) to check; usually 0
	want_opcode:   u8,
	want_length:   u8,
	want_cpu:      m.CPU,
) {
	_run := m.ENCODE_RUNS[u16(mn)]
	encs := m.ENCODE_FORMS[_run.start:][:_run.count]
	if len(encs) <= want_mode_idx {
		fmt.printfln("  [FAIL] %-12s no encoding at idx %d", name, want_mode_idx)
		failures += 1
		return
	}
	e := encs[want_mode_idx]
	if e.opcode != want_opcode || e.length != want_length || e.cpu != want_cpu {
		fmt.printfln("  [FAIL] %-12s op=%02x/len=%d/cpu=%v  want %02x/%d/%v",
					 name, e.opcode, e.length, e.cpu,
					 want_opcode, want_length, want_cpu)
		failures += 1
		return
	}
	fmt.printfln("  [ok]   %-12s op=%02x len=%d cpu=%v",
				 name, e.opcode, e.length, e.cpu)
	passes += 1
}

@(private="file")
check_mode :: proc(name: string, mn: m.Mnemonic, want_mode: m.Operand_Type, want_opcode: u8) {
	// Find the form whose first Operand_Type matches `want_mode`.
	_run := m.ENCODE_RUNS[u16(mn)]
	for e in m.ENCODE_FORMS[_run.start:][:_run.count] {
		if e.ops[0] == want_mode {
			if e.opcode == want_opcode {
				fmt.printfln("  [ok]   %-22s op=%02x", name, want_opcode)
				passes += 1
			} else {
				fmt.printfln("  [FAIL] %-22s got op=%02x want %02x", name, e.opcode, want_opcode)
				failures += 1
			}
			return
		}
	}
	fmt.printfln("  [FAIL] %-22s no form with mode %v", name, want_mode)
	failures += 1
}

main :: proc() {
	fmt.println("=== MOS 6502 encoding-table spot checks ===")

	// ---- NMOS official core --------------------------------------------------
	check_mode("LDA #imm",     .LDA, .IMM_8,     0xA9)
	check_mode("LDA zp",       .LDA, .MEM_ZP,    0xA5)
	check_mode("LDA zp,X",     .LDA, .MEM_ZP_X,  0xB5)
	check_mode("LDA abs",      .LDA, .MEM_ABS,   0xAD)
	check_mode("LDA abs,X",    .LDA, .MEM_ABS_X, 0xBD)
	check_mode("LDA abs,Y",    .LDA, .MEM_ABS_Y, 0xB9)
	check_mode("LDA (zp,X)",   .LDA, .MEM_IND_X, 0xA1)
	check_mode("LDA (zp),Y",   .LDA, .MEM_IND_Y, 0xB1)
	check_mode("STA zp",       .STA, .MEM_ZP,    0x85)
	check_mode("STA abs",      .STA, .MEM_ABS,   0x8D)
	check_mode("ADC #imm",     .ADC, .IMM_8,     0x69)
	check_mode("SBC abs,Y",    .SBC, .MEM_ABS_Y, 0xF9)
	check_mode("ASL A",        .ASL, .A_IMPL,    0x0A)
	check_mode("ROL A",        .ROL, .A_IMPL,    0x2A)
	check_mode("BIT zp",       .BIT, .MEM_ZP,    0x24)
	check_mode("BIT abs",      .BIT, .MEM_ABS,   0x2C)

	check("BNE",      .BNE, 0, 0xD0, 2, .NMOS)
	check("BEQ",      .BEQ, 0, 0xF0, 2, .NMOS)
	check("BPL",      .BPL, 0, 0x10, 2, .NMOS)
	check("BVS",      .BVS, 0, 0x70, 2, .NMOS)

	check_mode("JMP abs",      .JMP, .MEM_ABS,    0x4C)
	check_mode("JMP (abs)",    .JMP, .MEM_IND,    0x6C)
	check("JSR",      .JSR, 0, 0x20, 3, .NMOS)
	check("RTS",      .RTS, 0, 0x60, 1, .NMOS)
	check("RTI",      .RTI, 0, 0x40, 1, .NMOS)
	check("BRK",      .BRK, 0, 0x00, 1, .NMOS)

	check("NOP",      .NOP, 0, 0xEA, 1, .NMOS)
	check("CLC",      .CLC, 0, 0x18, 1, .NMOS)
	check("SEI",      .SEI, 0, 0x78, 1, .NMOS)
	check("CLD",      .CLD, 0, 0xD8, 1, .NMOS)
	check("TXA",      .TXA, 0, 0x8A, 1, .NMOS)
	check("TYA",      .TYA, 0, 0x98, 1, .NMOS)
	check("PHA",      .PHA, 0, 0x48, 1, .NMOS)
	check("PLA",      .PLA, 0, 0x68, 1, .NMOS)
	check("INX",      .INX, 0, 0xE8, 1, .NMOS)
	check("INY",      .INY, 0, 0xC8, 1, .NMOS)
	check("DEX",      .DEX, 0, 0xCA, 1, .NMOS)
	check("DEY",      .DEY, 0, 0x88, 1, .NMOS)

	// ---- NMOS undocumented ----------------------------------------------------
	check_mode("LAX zp",       .LAX,      .MEM_ZP,   0xA7)
	check_mode("LAX abs,Y",    .LAX,      .MEM_ABS_Y,0xBF)
	check_mode("SAX_NMOS zp",  .SAX_NMOS, .MEM_ZP,   0x87)
	check_mode("SAX_NMOS abs", .SAX_NMOS, .MEM_ABS,  0x8F)
	check_mode("DCP abs",      .DCP,      .MEM_ABS,  0xCF)
	check_mode("ISC abs",      .ISC,      .MEM_ABS,  0xEF)
	check_mode("RLA abs",      .RLA,      .MEM_ABS,  0x2F)
	check_mode("RRA abs",      .RRA,      .MEM_ABS,  0x6F)
	check_mode("SLO abs",      .SLO,      .MEM_ABS,  0x0F)
	check_mode("SRE abs",      .SRE,      .MEM_ABS,  0x4F)
	check("ALR",      .ALR,  0, 0x4B, 2, .NMOS_UNDOC)
	check("ARR",      .ARR,  0, 0x6B, 2, .NMOS_UNDOC)
	check("AXS",      .AXS,  0, 0xCB, 2, .NMOS_UNDOC)
	check("USBC",     .USBC, 0, 0xEB, 2, .NMOS_UNDOC)
	check("JAM (0x02)",.JAM, 0, 0x02, 1, .NMOS_UNDOC)
	check("ANC ($0B)", .ANC, 0, 0x0B, 2, .NMOS_UNDOC)
	check("ANC ($2B)", .ANC, 1, 0x2B, 2, .NMOS_UNDOC)

	// ---- 65C02 additions ------------------------------------------------------
	check("BRA",      .BRA, 0, 0x80, 2, .CMOS_65C02)
	check("INA",      .INA, 0, 0x1A, 1, .CMOS_65C02)
	check("DEA",      .DEA, 0, 0x3A, 1, .CMOS_65C02)
	check("PHX",      .PHX, 0, 0xDA, 1, .CMOS_65C02)
	check("PHY",      .PHY, 0, 0x5A, 1, .CMOS_65C02)
	check("PLX",      .PLX, 0, 0xFA, 1, .CMOS_65C02)
	check("PLY",      .PLY, 0, 0x7A, 1, .CMOS_65C02)
	check_mode("STZ zp",      .STZ, .MEM_ZP,    0x64)
	check_mode("STZ abs",     .STZ, .MEM_ABS,   0x9C)
	check_mode("LDA (zp)",    .LDA, .MEM_IND_ZP, 0xB2)
	check_mode("ADC (zp)",    .ADC, .MEM_IND_ZP, 0x72)
	check_mode("JMP (abs,X)", .JMP, .MEM_IND_ABS_X, 0x7C)
	check_mode("TRB zp",      .TRB, .MEM_ZP,    0x14)
	check_mode("TSB zp",      .TSB, .MEM_ZP,    0x04)
	check_mode("BIT #imm",    .BIT, .IMM_8,     0x89)

	// Rockwell bit ops
	check("RMB0",     .RMB0, 0, 0x07, 2, .CMOS_65C02)
	check("RMB3",     .RMB3, 0, 0x37, 2, .CMOS_65C02)
	check("SMB0",     .SMB0, 0, 0x87, 2, .CMOS_65C02)
	check("SMB7",     .SMB7, 0, 0xF7, 2, .CMOS_65C02)
	check("BBR0",     .BBR0, 0, 0x0F, 3, .CMOS_65C02)
	check("BBR7",     .BBR7, 0, 0x7F, 3, .CMOS_65C02)
	check("BBS0",     .BBS0, 0, 0x8F, 3, .CMOS_65C02)
	check("BBS7",     .BBS7, 0, 0xFF, 3, .CMOS_65C02)

	// ---- HuC6280 --------------------------------------------------------------
	check("SXY",      .SXY, 0, 0x02, 1, .HUC6280)
	check("SAX (HuC)",.SAX, 0, 0x22, 1, .HUC6280)
	check("SAY",      .SAY, 0, 0x42, 1, .HUC6280)
	check("CLA",      .CLA, 0, 0x62, 1, .HUC6280)
	check("CLX",      .CLX, 0, 0x82, 1, .HUC6280)
	check("CLY",      .CLY, 0, 0xC2, 1, .HUC6280)
	check("CSL",      .CSL, 0, 0x54, 1, .HUC6280)
	check("CSH",      .CSH, 0, 0xD4, 1, .HUC6280)
	check("ST0",      .ST0, 0, 0x03, 2, .HUC6280)
	check("ST1",      .ST1, 0, 0x13, 2, .HUC6280)
	check("ST2",      .ST2, 0, 0x23, 2, .HUC6280)
	check("TAM",      .TAM, 0, 0x53, 2, .HUC6280)
	check("TMA",      .TMA, 0, 0x43, 2, .HUC6280)
	check("BSR",      .BSR, 0, 0x44, 2, .HUC6280)
	check("TII",      .TII, 0, 0x73, 7, .HUC6280)
	check("TDD",      .TDD, 0, 0xC3, 7, .HUC6280)
	check("TIN",      .TIN, 0, 0xD3, 7, .HUC6280)
	check("TIA",      .TIA, 0, 0xE3, 7, .HUC6280)
	check("TAI",      .TAI, 0, 0xF3, 7, .HUC6280)
	check_mode("TST # zp",   .TST, .IMM_8, 0x83)

	fmt.println()
	fmt.printfln("==> table: %d passed, %d failed", passes, failures)
	if failures > 0 { os.exit(1) }

	run_pipeline_tests()
}
