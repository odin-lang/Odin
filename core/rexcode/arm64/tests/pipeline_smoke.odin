// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm64_tests

// End-to-end AArch64 pipeline tests: encode -> decode -> print round-trips
// across each instruction family, with byte-level verification of the
// canonical encodings from the ARM ARM. Validates SP-vs-ZR handling,
// shifted/extended register packing, split immediates (B/J/BR-PG), and
// label inference for every branch flavour.

import "core:fmt"
import "core:os"
import a "../"
import "../../isa"

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
eq_word :: proc(name: string, got, want: u32) {
	if got == want {
		fmt.printfln("  [ok]   %-30s %08x", name, got)
		rpasses += 1
	} else {
		fmt.printfln("  [FAIL] %-30s got=%08x want=%08x", name, got, want)
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
load_le :: proc(buf: []u8, offset: u32) -> u32 {
	return  u32(buf[offset+0])        |
		   (u32(buf[offset+1]) <<  8) |
		   (u32(buf[offset+2]) << 16) |
		   (u32(buf[offset+3]) << 24)
}

run_pipeline_tests :: proc() {
	fmt.println()
	fmt.println("=== AArch64 pipeline spot checks ===")

	code:   [256]u8
	relocs: [dynamic]a.Relocation
	errors: [dynamic]a.Error
	defer delete(relocs)
	defer delete(errors)

	// ---- 1. ADD/SUB imm12 ------------------------------------------------
	//   ADD X0, X1, #100      sf=1 op=0 S=0 sh=0 imm12=100 Rn=1 Rd=0
	//     = 0x91000000 | (100<<10) | (1<<5) | 0 = 0x91019020
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.inst_r_r_i(.ADD_IMM, a.X0, a.X1, 100),
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("ADD_IMM: encode", r.success)
		eq_word("ADD X0,X1,#100",         load_le(code[:], 0), 0x91019020)
	}

	// ---- 2. MOVZ ---------------------------------------------------------
	//   MOVZ X0, #0x1234, LSL #16
	//     sf=1 opc=10 hw=01 imm=0x1234 Rd=0
	//     = 0xD2800000 | (1<<21) | (0x1234<<5) | 0
	//     = 0xD2A24680
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{ a.inst_mov_imm(.MOVZ, a.X0, 0x1234, 1) }
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("MOVZ: encode", r.success)
		eq_word("MOVZ X0,#0x1234,LSL#16", load_le(code[:], 0), 0xD2A24680)
	}

	// ---- 3. ADD shifted register ----------------------------------------
	//   ADD X0, X1, X2, LSL #3
	//     sf=1 op=0 S=0 shift=00 Rm=2 imm6=3 Rn=1 Rd=0
	//     = 0x8B000000 | (2<<16) | (3<<10) | (1<<5) | 0
	//     = 0x8B020C20
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.Instruction{
				mnemonic = .ADD_SR, operand_count = 3, length = 4,
				ops = {a.op_reg(a.X0), a.op_reg(a.X1), a.op_shifted(a.X2, .LSL, 3), {}},
			},
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("ADD_SR: encode", r.success)
		eq_word("ADD X0,X1,X2,LSL#3",     load_le(code[:], 0), 0x8B020C20)
	}

	// ---- 4. ADD extended register: ADD X0, SP, W1, UXTW #2 --------------
	//   sf=1 op=0 S=0 fixed bits...001 Rm=1 option=010 imm3=2 Rn=31 Rd=0
	//   = 0x8B200000 | (1<<16) | (2<<13) | (2<<10) | (31<<5) | 0
	//   = 0x8B214BE0
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.Instruction{
				mnemonic = .ADD_ER, operand_count = 3, length = 4,
				ops = {a.op_reg(a.X0), a.op_reg(a.SP), a.op_extended(a.W1, .UXTW, 2), {}},
			},
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("ADD_ER: encode", r.success)
		eq_word("ADD X0,SP,W1,UXTW#2",   load_le(code[:], 0), 0x8B214BE0)
	}

	// ---- 5. UDIV / SDIV / MADD ------------------------------------------
	//   UDIV X0, X1, X2: 0x9AC00800 | (2<<16) | (1<<5) | 0 = 0x9AC20820
	//   MADD X0, X1, X2, X3: 0x9B000000 | (2<<16) | (3<<10) | (1<<5) | 0 = 0x9B020C20
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.inst_r_r_r  (.UDIV, a.X0, a.X1, a.X2),
			a.inst_r_r_r_r(.MADD, a.X0, a.X1, a.X2, a.X3),
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("UDIV/MADD: encode", r.success)
		eq_word("UDIV X0,X1,X2",         load_le(code[:], 0), 0x9AC20820)
		eq_word("MADD X0,X1,X2,X3",      load_le(code[:], 4), 0x9B020C20)
	}

	// ---- 6. CLZ / REV ---------------------------------------------------
	//   CLZ X0, X1:  0xDAC01000 | (1<<5) | 0 = 0xDAC01020
	//   REV X0, X1:  0xDAC00C00 | (1<<5) | 0 = 0xDAC00C20
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.inst_r_r(.CLZ, a.X0, a.X1),
			a.inst_r_r(.REV, a.X0, a.X1),
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("CLZ/REV: encode", r.success)
		eq_word("CLZ X0,X1",             load_le(code[:], 0), 0xDAC01020)
		eq_word("REV X0,X1",             load_le(code[:], 4), 0xDAC00C20)
	}

	// ---- 7. CSEL --------------------------------------------------------
	//   CSEL X0, X1, X2, EQ:  0x9A800000 | (2<<16) | (0<<12) | (1<<5) | 0 = 0x9A820020
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{ a.inst_csel(a.X0, a.X1, a.X2, .EQ) }
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("CSEL: encode", r.success)
		eq_word("CSEL X0,X1,X2,EQ",     load_le(code[:], 0), 0x9A820020)
	}

	// ---- 8. LDR/STR unsigned-offset -------------------------------------
	//   LDR X0, [X1, #16]:  size=11 -> bits=0xF9400000 | (16/8=2 << 10) | (1<<5) | 0
	//                       = 0xF9400000 | 0x800 | 0x20 = 0xF9400820
	//   STR W0, [SP, #20]:  size=10 -> bits=0xB9000000 | (20/4=5 << 10) | (31<<5) | 0
	//                       = 0xB9000000 | 0x1400 | 0x3E0 = 0xB90017E0
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.inst_ldst(.LDR, a.X0, a.mem_offset(a.X1, 16)),
			a.inst_ldst(.STR, a.W0, a.mem_offset(a.SP, 20)),
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("LDR/STR: encode", r.success)
		eq_word("LDR X0,[X1,#16]",       load_le(code[:], 0), 0xF9400820)
		eq_word("STR W0,[SP,#20]",       load_le(code[:], 4), 0xB90017E0)
	}

	// ---- 9. B forward + BL backward + label inference -------------------
	//   B target:        pc=0, target at byte 12 -> off = +12 = +3 words
	//                    bits = 0x14000000 | 3 = 0x14000003
	//   NOP                                   pc=4
	//   NOP                                   pc=8
	//   target: RET                           pc=12
	//
	//   Then BL backwards: BL target  at pc=16. target at byte 12 -> off = -4 = -1 word
	//                      bits = 0x94000000 | 0x03FFFFFF = 0x97FFFFFF
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		ld: [dynamic]a.Label_Definition
		defer delete(ld)
		append(&ld, a.Label_Definition(3))    // target at inst 3 (byte 12)

		insts := []a.Instruction{
			a.inst_branch(.B,  0),
			a.inst_none(.NOP),
			a.inst_none(.NOP),
			a.inst_none(.RET),
			a.inst_branch(.BL, 0),
		}
		r := a.encode(insts, ld[:], code[:], &relocs, &errors)
		ok("br: encode", r.success)
		eq_word("B  forward (+3 words)", load_le(code[:], 0),  0x14000003)
		eq_word("BL backward (-1 word)", load_le(code[:], 16), 0x97FFFFFF)
	}

	// ---- 10. CBZ / TBZ --------------------------------------------------
	//   CBZ X0, target  at pc=0, target at byte 8 -> off = +2 words
	//     bits = 0xB4000000 | (2 << 5) | 0 = 0xB4000040
	//   TBZ X0, #5, target  at pc=4, target at byte 8 -> off = +1 word
	//     bits = 0x36000000 | (0 << 31) | (5 << 19) | (1 << 5) | 0 = 0x362800A0
	//   Wait: bit=5 means b5=0, b40=5. (5 << 19) = 0x00280000. + (1<<5)=0x20.
	//     Hmm Rt=0 -> 0 << 0 = 0. So bits = 0x36000000 | 0x280000 | (1<<5)=0x20
	//                     = 0x36280020
	//   Actually target is at byte 8, TBZ at pc=4, off = 4 bytes = +1 word.
	//   BRANCH_14 field at bits[18:5] gets value 1. So + (1<<5) = 0x20.
	//   Final: 0x36000000 | 0x280000 | 0x20 = 0x36280020
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		ld: [dynamic]a.Label_Definition
		defer delete(ld)
		append(&ld, a.Label_Definition(2))   // target at inst 2 (byte 8)

		insts := []a.Instruction{
			a.inst_cbz(a.X0, 0),
			a.inst_tbz(a.X0, 5, 0),
			a.inst_none(.NOP),                // target
		}
		r := a.encode(insts, ld[:], code[:], &relocs, &errors)
		ok("CBZ/TBZ: encode", r.success)
		eq_word("CBZ X0,+2 words",       load_le(code[:], 0), 0xB4000040)
		eq_word("TBZ X0,#5,+1 word",     load_le(code[:], 4), 0x36280020)
	}

	// ---- 11. ADRP + ADD immediate (PC-relative load idiom) -------------
	//   ADRP X0, target_page  (target at byte 0x4000)
	//     pc = 0; target_page = 0x4000; diff = 0x4000 - 0 = 0x4000
	//     pages = 4; encoded immlo:immhi = 4
	//     bits = 0x90000000 | (4 & 0x3) << 29 | (4 >> 2) & 0x7FFFF) << 5
	//          = 0x90000000 | (0 << 29) | (1 << 5)
	//          = 0x90000020
	//   But our test uses target at byte 16 (inst 4); page diff = 0 -> ADRP imm = 0
	//   So actually ADRP X0, target where target is at byte 16 gives ADRP X0, 0.
	//   bits = 0x90000000 | 0 = 0x90000000
	//   Hmm not very interesting. Let me skip this test for v1.
	//   Just test ADR with small offset.
	//   ADR X0, target  at pc=0, target at byte 8 -> rel = 8
	//     immlo = 8 & 3 = 0, immhi = 8 >> 2 = 2
	//     bits = 0x10000000 | (0 << 29) | (2 << 5) | 0 = 0x10000040
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		ld: [dynamic]a.Label_Definition
		defer delete(ld)
		append(&ld, a.Label_Definition(2))   // target at inst 2 (byte 8)

		insts := []a.Instruction{
			a.Instruction{
				mnemonic = .ADR, operand_count = 2, length = 4,
				ops = {a.op_reg(a.X0), a.op_label(0, 4), {}, {}},
			},
			a.inst_none(.NOP),
			a.inst_none(.NOP),
		}
		r := a.encode(insts, ld[:], code[:], &relocs, &errors)
		ok("ADR: encode", r.success)
		eq_word("ADR X0,+8",             load_le(code[:], 0), 0x10000040)
	}

	// ---- 12. System: NOP/SVC/MRS --------------------------------------
	//   NOP -- 0xD503201F (no operands)
	//   SVC #1 -- 0xD4000021  (0xD4000001 | (1<<5) = 0xD4000021)
	//   MRS X0, NZCV  (sysreg encoding 0xDA10 -> bits[19:5] = 0xDA10)
	//     bits = 0xD5300000 | (0xDA10 << 5) | 0 = 0xD53B4200
	//     Actually NZCV is op0=3, op1=3, CRn=4, CRm=2, op2=0 → enc:
	//       op0:op1:CRn:CRm:op2 = 11 011 0100 0010 000 = 1 1011 0100 0010 000
	//       = 0xDA10 in 15 bits (bits 19-5).
	//     bits = 0xD5300000 | (0xDA10 << 5) | 0 = 0xD53B4200
	//     Hmm let me double check: 0xDA10 << 5 = 0x1B4200. Plus 0xD5300000 = 0xD53B4200.
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.inst_none(.NOP),
			a.Instruction{
				mnemonic = .SVC, operand_count = 1, length = 4,
				ops = {a.op_imm(1, 2), {}, {}, {}},
			},
			a.Instruction{
				mnemonic = .MRS, operand_count = 2, length = 4,
				ops = {a.op_reg(a.X0), a.op_imm(0xDA10, 2), {}, {}},
			},
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("system: encode", r.success)
		eq_word("NOP",                   load_le(code[:], 0), 0xD503201F)
		eq_word("SVC #1",                load_le(code[:], 4), 0xD4000021)
		eq_word("MRS X0,NZCV",           load_le(code[:], 8), 0xD53B4200)
	}

	// ---- 13. FP scalar: FADD D0, D1, D2 ---------------------------------
	//   bits = 0x1E602800 | (2<<16) | (1<<5) | 0 = 0x1E622820
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.inst_r_r_r(.FADD, a.d_reg(0), a.d_reg(1), a.d_reg(2)),
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("FADD: encode", r.success)
		eq_word("FADD D0,D1,D2",         load_le(code[:], 0), 0x1E622820)
	}

	// ---- 14. Round-trip: encode -> decode -> print -----------------------
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		ld: [dynamic]a.Label_Definition
		defer delete(ld)
		append(&ld, a.Label_Definition(0))   // loop: at inst 0

		src := []a.Instruction{
			a.inst_r_r_i(.ADD_IMM, a.X0, a.X0, 1),
			a.inst_cbnz(a.X0, 0),
			a.inst_none(.RET),
		}
		r := a.encode(src, ld[:], code[:], &relocs, &errors)
		ok("rt: encode", r.success)

		d_insts:  [dynamic]a.Instruction
		d_info:   [dynamic]a.Instruction_Info
		d_labels: [dynamic]a.Label_Definition
		defer delete(d_insts); defer delete(d_info); defer delete(d_labels)
		clear(&errors)
		d := a.decode(code[:r.byte_count], nil, &d_insts, &d_info, &d_labels, &errors)
		ok("rt: decode", d.success)
		ok("rt: 3 insts",  len(d_insts) == 3)
		ok("rt: ADD",      d_insts[0].mnemonic == .ADD_IMM)
		ok("rt: CBNZ",     d_insts[1].mnemonic == .CBNZ)
		ok("rt: RET",      d_insts[2].mnemonic == .RET)

		text := a.aprint(d_insts[:], d_info[:], d_labels[:],
						 nil, nil, nil, context.temp_allocator)
		eq_str("rt: print",
			   text,
			   ".L0:\n    add x0, x0, #1\n    cbnz x0, .L0\n    ret\n")
	}

	// ---- 15. B.cond round-trip prints with condition suffix --------------
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		ld: [dynamic]a.Label_Definition
		defer delete(ld)
		append(&ld, a.Label_Definition(0))

		src := []a.Instruction{
			a.inst_r_r_i(.SUBS_IMM, a.X0, a.X1, 0),
			a.inst_b_cond(.EQ, 0),
			a.inst_none(.RET),
		}
		r := a.encode(src, ld[:], code[:], &relocs, &errors)
		ok("b.cond: encode", r.success)

		d_insts:  [dynamic]a.Instruction
		d_info:   [dynamic]a.Instruction_Info
		d_labels: [dynamic]a.Label_Definition
		defer delete(d_insts); defer delete(d_info); defer delete(d_labels)
		clear(&errors)
		a.decode(code[:r.byte_count], nil, &d_insts, &d_info, &d_labels, &errors)

		text := a.aprint(d_insts[:], d_info[:], d_labels[:],
						 nil, nil, nil, context.temp_allocator)
		eq_str("b.cond: print",
			   text,
			   ".L0:\n    subs x0, x1, #0\n    b.eq .L0\n    ret\n")
	}

	// ---- 16. Bitmask logical immediate: ORR_IMM X0, X1, #0xFF00FF00FF00FF00 --
	//   Element=16-bit pattern 0xFF00 repeated 4x (64-bit). N=0, imms=10 0111,
	//   immr=0 0 0 1 0 0 0 (the rotation lands the LSB of the high 8 ones byte).
	//   Quick truth check: mask 0xFF00FF00FF00FF00 has 32 ones, but our 16-bit
	//   element is 0xFF00 with 8 ones — so ones=8, S=7, imms_top=10_xxxx → imms=0100111=0x27
	//   immr must rotate the pattern so the run-of-ones is contiguous from LSB
	//   after rotation; for element=0xFF00 the right-rotation that makes a
	//   contiguous-low pattern is r=8 (rotating 0xFF00 right by 8 gives 0x00FF).
	//   So immr=0x08, N=0, imms=0x27. Encoded field = (0<<22)|(0x08<<16)|(0x27<<10)
	//                                                 = 0x00089C00.
	//   Final bits = ORR_IMM 64 base 0xB2000000 | (0<<22) | (8<<16) | (0x27<<10) | (1<<5) | 0
	//              = 0xB2000000 | 0x80000 | 0x9C00 | 0x20
	//              = 0xB2089C20
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		// Sign-bit-set u64 routed through transmute to i64.
		mask: u64 = 0xFF00FF00FF00FF00
		insts := []a.Instruction{
			a.inst_r_r_i(.ORR_IMM, a.X0, a.X1, transmute(i64)mask),
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("bitmask ORR: encode", r.success)
		eq_word("ORR X0,X1,#0xFF00.. repeat", load_le(code[:], 0), 0xB2089C20)

		// Round-trip: decode and verify operand round-trips back to the raw mask.
		d_insts:  [dynamic]a.Instruction
		d_info:   [dynamic]a.Instruction_Info
		d_labels: [dynamic]a.Label_Definition
		defer delete(d_insts); defer delete(d_info); defer delete(d_labels)
		clear(&errors)
		a.decode(code[:r.byte_count], nil, &d_insts, &d_info, &d_labels, &errors)
		ok("bitmask ORR: decode", len(d_insts) == 1 && d_insts[0].mnemonic == .ORR_IMM)
		if len(d_insts) == 1 {
			got := u64(d_insts[0].ops[2].immediate)
			ok("bitmask ORR: roundtrip", got == 0xFF00FF00FF00FF00)
		}
	}

	// ---- 17. Bitmask AND with element-32 pattern ----------------------------
	//   AND W0, W1, #0xF0
	//   In 32-bit, 0xF0 does NOT repeat at any smaller power-of-2 element,
	//   so the algorithm picks element=32 (single 32-bit pattern).
	//     ones=4, rotation=4 → immr=4
	//     element=32: imms_top=000000, S=ones-1=3 → imms=000011=0x03
	//     N=0
	//   Field at (bits 22:10): (0<<22) | (4<<16) | (3<<10) = 0x00040C00
	//   AND_IMM 32 base = 0x12000000, Rd=0, Rn=1.
	//   Final = 0x12000000 | 0x00040C00 | (1<<5) | 0 = 0x12040C20
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.inst_r_r_i(.AND_IMM, a.W0, a.W1, 0xF0),
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("bitmask AND 32: encode", r.success)
		eq_word("AND W0,W1,#0xF0", load_le(code[:], 0), 0x12040C20)

		// Round-trip.
		d_insts:  [dynamic]a.Instruction
		d_info:   [dynamic]a.Instruction_Info
		d_labels: [dynamic]a.Label_Definition
		defer delete(d_insts); defer delete(d_info); defer delete(d_labels)
		clear(&errors)
		a.decode(code[:r.byte_count], nil, &d_insts, &d_info, &d_labels, &errors)
		ok("bitmask AND 32: decode", len(d_insts) == 1 && d_insts[0].mnemonic == .AND_IMM)
		if len(d_insts) == 1 {
			got := u64(d_insts[0].ops[2].immediate)
			ok("bitmask AND 32: roundtrip", got == 0xF0)
		}
	}

	// ---- 18. SVE: ADD Z0.S, Z1.S, Z2.S (vectors unpredicated) --------------
	//   bits = 0x04A00000 | (Zm=2<<16) | (Zn=1<<5) | Zd=0
	//        = 0x04A20020
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.Instruction{
				mnemonic = .SVE_ADD_Z, operand_count = 3, length = 4,
				ops = {a.op_z_s(0), a.op_z_s(1), a.op_z_s(2), {}},
			},
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("SVE ADD Z: encode", r.success)
		eq_word("SVE ADD Z0.S,Z1.S,Z2.S", load_le(code[:], 0), 0x04A20020)

		// Round-trip.
		d_insts:  [dynamic]a.Instruction
		d_info:   [dynamic]a.Instruction_Info
		d_labels: [dynamic]a.Label_Definition
		defer delete(d_insts); defer delete(d_info); defer delete(d_labels)
		clear(&errors)
		a.decode(code[:r.byte_count], nil, &d_insts, &d_info, &d_labels, &errors)
		ok("SVE ADD Z: decode", len(d_insts) == 1 && d_insts[0].mnemonic == .SVE_ADD_Z)
	}

	// ---- 19. SVE predicated: ADD Z0.S, P0/M, Z0.S, Z1.S --------------------
	//   bits = 0x04800000 | (Pg=0<<10) | (Zm=1<<16) | Zdn=0
	//        = 0x04810000
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		p0 := a.Register(a.REG_P | 0)
		insts := []a.Instruction{
			a.Instruction{
				mnemonic = .SVE_ADD_PRED, operand_count = 4, length = 4,
				ops = {a.op_z_s(0), a.op_reg(p0), a.op_z_s(0), a.op_z_s(1)},
			},
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("SVE ADD_PRED: encode", r.success)
		eq_word("SVE ADD Z0.S,P0/M,Z0.S,Z1.S", load_le(code[:], 0), 0x04810000)
	}

	// ---- 20. SVE PTRUE P0.B, ALL --------------------------------------------
	//   bits = 0x2518E000 | (pattern=0x1F=ALL << 5) | Pd=0
	//        = 0x2518E000 | 0x3E0 | 0 = 0x2518E3E0
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		p0 := a.Register(a.REG_P | 0)
		insts := []a.Instruction{
			a.Instruction{
				mnemonic = .SVE_PTRUE, operand_count = 2, length = 4,
				ops = {a.op_reg(p0), a.op_imm(0x1F, 1), {}, {}},
			},
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("SVE PTRUE: encode", r.success)
		eq_word("SVE PTRUE P0.B,ALL", load_le(code[:], 0), 0x2518E3E0)
	}

	// ---- 21. SME SMSTART / SMSTOP -----------------------------------------
	//   SMSTART = 0xD503477F (SVCRSMZA = SM+ZA enabled)
	//   SMSTOP  = 0xD503467F
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.inst_none(.SME_SMSTART),
			a.inst_none(.SME_SMSTOP),
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("SME SMSTART/SMSTOP: encode", r.success)
		eq_word("SME SMSTART", load_le(code[:], 0), 0xD503477F)
		eq_word("SME SMSTOP",  load_le(code[:], 4), 0xD503467F)
	}

	// ---- 22. SME FMOPA ZA0.S, P0/M, P1/M, Z0.S, Z0.S -----------------------
	//   Encoded with Zm=0 implicitly (the v1 outer-product schema uses 4
	//   operands and treats Zm as zero; users who need a non-zero Zm
	//   construct the Instruction by hand with the desired bits).
	//   bits = 0x80800000 (FMOPA base, S form)
	//        | Pm=1<<13 = 0x2000
	//        | Pn=0<<10 | Zn=0<<5 | ZAd=0 | Zm=0<<16
	//        = 0x80802000
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		p0 := a.Register(a.REG_P | 0)
		p1 := a.Register(a.REG_P | 1)
		insts := []a.Instruction{
			a.Instruction{
				mnemonic = .SME_FMOPA, operand_count = 4, length = 4,
				ops = {a.op_imm(0, 1), a.op_reg(p0), a.op_reg(p1), a.op_z_s(0)},
			},
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("SME FMOPA: encode", r.success)
		eq_word("SME FMOPA ZA0.S,P0/M,P1/M,Z0.S,Z0.S", load_le(code[:], 0), 0x80802000)
	}

	// ---- 23. Apple AMX ------------------------------------------------------
	//   AMX_SET                          = 0x00201220 (enable AMX, no operand)
	//   AMX_LDX X0                       = 0x00201000 | 0 = 0x00201000
	//   AMX_LDY X1                       = 0x00201020 | 1 = 0x00201021
	//   AMX_FMA32 X2                     = 0x00201180 | 2 = 0x00201182
	//   AMX_STZ X3                       = 0x002010A0 | 3 = 0x002010A3
	//   AMX_CLR                          = 0x00201240
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.inst_none(.AMX_SET),
			a.inst_r(.AMX_LDX,   a.X0),
			a.inst_r(.AMX_LDY,   a.X1),
			a.inst_r(.AMX_FMA32, a.X2),
			a.inst_r(.AMX_STZ,   a.X3),
			a.inst_none(.AMX_CLR),
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("AMX: encode", r.success)
		eq_word("AMX SET",         load_le(code[:],  0), 0x00201220)
		eq_word("AMX LDX X0",      load_le(code[:],  4), 0x00201000)
		eq_word("AMX LDY X1",      load_le(code[:],  8), 0x00201021)
		eq_word("AMX FMA32 X2",    load_le(code[:], 12), 0x00201182)
		eq_word("AMX STZ X3",      load_le(code[:], 16), 0x002010A3)
		eq_word("AMX CLR",         load_le(code[:], 20), 0x00201240)

		// Round-trip decode.
		d_insts:  [dynamic]a.Instruction
		d_info:   [dynamic]a.Instruction_Info
		d_labels: [dynamic]a.Label_Definition
		defer delete(d_insts); defer delete(d_info); defer delete(d_labels)
		clear(&errors)
		d := a.decode(code[:r.byte_count], nil, &d_insts, &d_info, &d_labels, &errors)
		ok("AMX: decode",       d.success)
		ok("AMX: 6 insts",      len(d_insts) == 6)
		ok("AMX: SET",          len(d_insts) >= 1 && d_insts[0].mnemonic == .AMX_SET)
		ok("AMX: LDX",          len(d_insts) >= 2 && d_insts[1].mnemonic == .AMX_LDX)
		ok("AMX: LDY",          len(d_insts) >= 3 && d_insts[2].mnemonic == .AMX_LDY)
		ok("AMX: FMA32",        len(d_insts) >= 4 && d_insts[3].mnemonic == .AMX_FMA32)
		ok("AMX: STZ",          len(d_insts) >= 5 && d_insts[4].mnemonic == .AMX_STZ)
		ok("AMX: CLR",          len(d_insts) >= 6 && d_insts[5].mnemonic == .AMX_CLR)
	}

	// ---- 24. Anonymous labels: forward + backward refs in one buffer ----
	//   Mimics the x86-style `1:` local-label pattern:
	//       back := label(&labels, &insts)   // .L0:  (definition)
	//       ADD X0, X0, #1
	//       CMP X0, #5
	//       fwd  := label_forward(&labels)   // reserve .L1
	//       B.LT fwd                          // forward branch
	//       B    back                         // backward branch
	//       label_set_at(&labels, fwd, &insts)  // .L1:
	//       RET
	//
	//   The shape exercises both directions in one buffer with anonymous IDs.
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		labels: [dynamic]a.Label_Definition
		defer delete(labels)
		insts:  [dynamic]a.Instruction
		defer delete(insts)

		back := isa.label(&labels, &insts)                          // .L0: at instruction 0
		append(&insts, a.inst_r_r_i(.ADD_IMM, a.X0, a.X0, 1))      // [0] byte  0: ADD X0,X0,#1
		append(&insts, a.inst_r_r_i(.SUBS_IMM, a.XZR, a.X0, 5))    // [1] byte  4: SUBS XZR,X0,#5
		fwd  := isa.label_forward(&labels)                          //    reserve .L1
		append(&insts, a.inst_b_cond(.LT, fwd))                    // [2] byte  8: B.LT .L1
		append(&insts, a.inst_branch(.B, back))                    // [3] byte 12: B .L0
		isa.label_set_at(&labels, fwd, &insts)                     //    .L1: at instruction 4
		append(&insts, a.inst_none(.RET))                          // [4] byte 16: RET

		r := a.encode(insts[:], labels[:], code[:], &relocs, &errors)
		ok("anon labels: encode",          r.success)
		ok("anon labels: byte_count = 20", r.byte_count == 20)

		// B.LT at byte 8 -> .L1 at byte 16: offset = +8 = +2 words.
		//   bits = 0x54000000 | (2<<5) | LT(0xB) = 0x5400004B
		// B at byte 12 -> .L0 at byte 0: offset = -12 = -3 words.
		//   bits = 0x14000000 | (-3 & 0x03FFFFFF) = 0x17FFFFFD
		bcond_word := load_le(code[:], 8)
		b_word     := load_le(code[:], 12)
		eq_word("anon: B.LT forward (+8)", bcond_word, 0x5400004B)
		eq_word("anon: B backward (-12)",  b_word,     0x17FFFFFD)

		// Round-trip via decode + label inference.
		d_insts:  [dynamic]a.Instruction
		d_info:   [dynamic]a.Instruction_Info
		d_labels: [dynamic]a.Label_Definition
		defer delete(d_insts); defer delete(d_info); defer delete(d_labels)
		clear(&errors)
		a.decode(code[:r.byte_count], nil, &d_insts, &d_info, &d_labels, &errors)
		ok("anon labels: decode 5 insts", len(d_insts) == 5)
		have_back, have_fwd: bool
		for ld in d_labels {
			if ld == a.Label_Definition(0)  { have_back = true }
			if ld == a.Label_Definition(16) { have_fwd  = true }
		}
		ok("anon labels: backward label inferred", have_back)
		ok("anon labels: forward  label inferred", have_fwd)
	}

	// ---- 25. MRS / MSR with sysreg constants ----------------------------
	//   MRS X0, NZCV     -- read condition flags
	//   MRS X1, TPIDR_EL0 -- read thread-local pointer
	//   MRS X2, CNTVCT_EL0 -- read virtual count
	//   MRS X3, DCZID_EL0  -- read DC ZVA block size info
	//
	//   Encoding: bits 31:20 = 1101_0101_0011, bits 19:5 = sysreg field, bits 4:0 = Rt
	//   For NZCV (0x5A10): word = 0xD5300000 | (0x5A10 << 5) | 0 = 0xD5300000 | 0xB4200 | 0 = 0xD53B4200
	//   For TPIDR_EL0 (0x5E82): word = 0xD5300000 | (0x5E82 << 5) | 1 = 0xD5300000 | 0xBD040 | 1 = 0xD53BD041
	//   For CNTVCT_EL0 (0x5F02): word = 0xD5300000 | (0x5F02 << 5) | 2 = 0xD5300000 | 0xBE040 | 2 = 0xD53BE042
	//   For DCZID_EL0 (0x5807): word = 0xD5300000 | (0x5807 << 5) | 3 = 0xD5300000 | 0xB00E0 | 3 = 0xD53B00E3
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.Instruction{
				mnemonic = .MRS, operand_count = 2, length = 4,
				ops = {a.op_reg(a.X0), a.op_imm(a.NZCV, 2), {}, {}},
			},
			a.Instruction{
				mnemonic = .MRS, operand_count = 2, length = 4,
				ops = {a.op_reg(a.X1), a.op_imm(a.TPIDR_EL0, 2), {}, {}},
			},
			a.Instruction{
				mnemonic = .MRS, operand_count = 2, length = 4,
				ops = {a.op_reg(a.X2), a.op_imm(a.CNTVCT_EL0, 2), {}, {}},
			},
			a.Instruction{
				mnemonic = .MRS, operand_count = 2, length = 4,
				ops = {a.op_reg(a.X3), a.op_imm(a.DCZID_EL0, 2), {}, {}},
			},
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("sysreg: encode", r.success)
		eq_word("MRS X0,NZCV",       load_le(code[:],  0), 0xD53B4200)
		eq_word("MRS X1,TPIDR_EL0",  load_le(code[:],  4), 0xD53BD041)
		eq_word("MRS X2,CNTVCT_EL0", load_le(code[:],  8), 0xD53BE042)
		eq_word("MRS X3,DCZID_EL0",  load_le(code[:], 12), 0xD53B00E3)
	}

	// ---- 26. DC ZVA round-trip (libc memset cache-line idiom) -----------
	//   DC ZVA, X0       = 0xD50B7420 | 0 = 0xD50B7420
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.inst_r(.DC_ZVA, a.X0),
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("DC ZVA: encode",     r.success)
		eq_word("DC ZVA X0",     load_le(code[:], 0), 0xD50B7420)

		d_insts:  [dynamic]a.Instruction
		d_info:   [dynamic]a.Instruction_Info
		d_labels: [dynamic]a.Label_Definition
		defer delete(d_insts); defer delete(d_info); defer delete(d_labels)
		clear(&errors)
		a.decode(code[:r.byte_count], nil, &d_insts, &d_info, &d_labels, &errors)
		ok("DC ZVA: decode",         len(d_insts) == 1 && d_insts[0].mnemonic == .DC_ZVA)
		ok("DC ZVA: Rt = X0",        len(d_insts) == 1 && d_insts[0].ops[0].reg == a.X0)
	}

	// ---- 27. CMP alias: encodes as SUBS XZR, Xn, Rm{,shift} -------------
	//   CMP X0, X1   = SUBS XZR, X0, X1
	//                = 0xEB00001F | (Rm=1 << 16) | (Rn=0 << 5) | 0
	//                = 0xEB00001F | 0x10000 | 0 = 0xEB01001F
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.Instruction{
				mnemonic = .CMP_SR, operand_count = 2, length = 4,
				ops = {a.op_reg(a.X0), a.op_shifted(a.X1, .LSL, 0), {}, {}},
			},
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("CMP_SR: encode",    r.success)
		eq_word("CMP X0,X1",    load_le(code[:], 0), 0xEB01001F)
	}

	// ---- 28. MOPS memcpy triplet -----------------------------------------
	//   CPYP [X0]!, [X1]!, X2!
	//   CPYM [X0]!, [X1]!, X2!
	//   CPYE [X0]!, [X1]!, X2!
	//
	//   With Rd=X0, Rs=X1 (at bit 9-5), Rn=X2 (at bit 20-16):
	//     CPYP base 0x1D000400 | (X2=2 << 16) | (X1=1 << 5) | X0=0
	//         = 0x1D000400 | 0x20000 | 0x20 | 0 = 0x1D020420
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.Instruction{
				mnemonic = .CPYP, operand_count = 3, length = 4,
				ops = {a.op_reg(a.X0), a.op_reg(a.X1), a.op_reg(a.X2), {}},
			},
			a.Instruction{
				mnemonic = .CPYM, operand_count = 3, length = 4,
				ops = {a.op_reg(a.X0), a.op_reg(a.X1), a.op_reg(a.X2), {}},
			},
			a.Instruction{
				mnemonic = .CPYE, operand_count = 3, length = 4,
				ops = {a.op_reg(a.X0), a.op_reg(a.X1), a.op_reg(a.X2), {}},
			},
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("MOPS CPY: encode", r.success)
		eq_word("CPYP X0,X1,X2", load_le(code[:], 0), 0x1D020420)
		eq_word("CPYM X0,X1,X2", load_le(code[:], 4), 0x1D420420)
		eq_word("CPYE X0,X1,X2", load_le(code[:], 8), 0x1D820420)
	}

	// ---- 29. SVE indexed FMLA: FMLA Zda.S, Zn.S, Zm.S[2] ------------------
	//   With Zda=Z0, Zn=Z1, Zm=Z2, lane=2:
	//     bits = 0x64A00000 base
	//          | (Zm=2 << 16) | (lane=2 << 19) | (Zn=1 << 5) | Zda=0
	//          = 0x64A00000 | 0x20000 | 0x100000 | 0x20 | 0
	//          = 0x64B20020
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.Instruction{
				mnemonic = .SVE_FMLA_IDX_S, operand_count = 4, length = 4,
				ops = {a.op_z_s(0), a.op_z_s(1), a.op_z_s(2), a.op_imm(2, 1)},
			},
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("SVE FMLA indexed: encode", r.success)
		eq_word("SVE FMLA Z0.S, Z1.S, Z2.S[2]", load_le(code[:], 0), 0x64B20020)
	}

	// ---- 30. SVE gather load: LD1W { Z0.S }, P0/Z, [X1, Z2.S, UXTW] ------
	//   With Zt=Z0, Pg=P0, base=X1, Zm=Z2:
	//     bits = 0x85004000 base
	//          | (Zm=2 << 16) | (Pg=0 << 10) | (Xn=1 << 5) | Zt=0
	//          = 0x85004000 | 0x20000 | 0 | 0x20 | 0
	//          = 0x85024020
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		p0 := a.Register(a.REG_P | 0)
		// Vector-offset memory: base = X1 (GPR), index = Z2 (Z reg as vector offset).
		mem := a.Memory{
			base  = a.X1,
			index = a.Register(a.REG_Z | 2),
			mode  = .REG_OFFSET,
		}
		insts := []a.Instruction{
			a.Instruction{
				mnemonic = .SVE_LD1W_GATHER_S, operand_count = 3, length = 4,
				ops = {a.op_z_s(0), a.op_reg(p0), a.op_mem(mem), {}},
			},
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("SVE LD1W gather: encode", r.success)
		eq_word("SVE LD1W Z0.S,P0/Z,[X1,Z2.S,UXTW]", load_le(code[:], 0), 0x85024020)
	}

	// ---- 31. SME tile load round-trip vs LLVM golden ---------------------
	//
	//   ld1b { za0v.b[w14, 5] }, p5/z, [x10, x21]  =  0xE015D545
	//
	//   Per LLVM MC test for AArch64 SME (file: test/MC/AArch64/SME/ld1b.s).
	//   Slice descriptor (packed): imm=5, V=1 (vertical), Ws=W14 (idx=2),
	//   tile=0 (ZA0.B is implicit for byte tile)
	//     packed = 5 | (1<<4) | (2<<5) | (0<<7) = 0x55
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		p5 := a.Register(a.REG_P | 5)
		slice_packed := i64(5 | (1 << 4) | (2 << 5))
		mem := a.Memory{
			base  = a.X10,
			index = a.X21,
			mode  = .REG_OFFSET,
		}
		insts := []a.Instruction{
			a.Instruction{
				mnemonic = .SME_LD1B_TILE, operand_count = 3, length = 4,
				ops = {a.op_imm(slice_packed, 2), a.op_reg(p5), a.op_mem(mem), {}},
			},
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("SME LD1B tile vs LLVM: encode", r.success)
		eq_word("SME LD1B ZA0V.B[W14,5],P5/Z,[X10,X21]", load_le(code[:], 0), 0xE015D545)

		d_insts:  [dynamic]a.Instruction
		d_info:   [dynamic]a.Instruction_Info
		d_labels: [dynamic]a.Label_Definition
		defer delete(d_insts); defer delete(d_info); defer delete(d_labels)
		clear(&errors)
		a.decode(code[:r.byte_count], nil, &d_insts, &d_info, &d_labels, &errors)
		ok("SME LD1B tile: decode 1 inst", len(d_insts) == 1)
		ok("SME LD1B tile: mnemonic",      len(d_insts) == 1 && d_insts[0].mnemonic == .SME_LD1B_TILE)
		ok("SME LD1B tile: slice roundtrip",
		   len(d_insts) == 1 && d_insts[0].ops[0].immediate == slice_packed)
	}

	// ---- 32. FCMLA v0.4s, v1.4s, v2.4s, #0 (LLVM golden) ----------------
	//   Verified: bytes [0x20,0xc4,0x82,0x6e] = 0x6E82C420
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.Instruction{
				mnemonic = .FCMLA_4S, operand_count = 4, length = 4,
				ops = {a.op_v_4s(0), a.op_v_4s(1), a.op_v_4s(2), a.op_imm(0, 1)},
			},
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("FCMLA: encode", r.success)
		eq_word("FCMLA V0.4S,V1.4S,V2.4S,#0", load_le(code[:], 0), 0x6E82C420)
	}

	// ---- 33. TME: TSTART X0; TCOMMIT; TTEST X1 ----------------------------
	//   TSTART X0  = 0xD5233060 | 0 = 0xD5233060
	//   TCOMMIT    = 0xD503307F
	//   TTEST X1   = 0xD5233160 | 1 = 0xD5233161
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.inst_r(.TSTART,  a.X0),
			a.inst_none(.TCOMMIT),
			a.inst_r(.TTEST,   a.X1),
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("TME: encode", r.success)
		eq_word("TSTART X0",  load_le(code[:], 0), 0xD5233060)
		eq_word("TCOMMIT",    load_le(code[:], 4), 0xD503307F)
		eq_word("TTEST X1",   load_le(code[:], 8), 0xD5233161)
	}

	// ---- 34. Extend aliases: UXTB W0,W1; SXTW X0,W1 -----------------------
	//   UXTB W0,W1 = 0x53001C00 | (W1 << 5) | W0 = 0x53001C20
	//   SXTW X0,W1 = 0x93407C00 | 0x20 = 0x93407C20
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.inst_r_r(.UXTB, a.W0, a.W1),
			a.inst_r_r(.SXTW, a.X0, a.W1),
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("extend aliases: encode", r.success)
		eq_word("UXTB W0,W1", load_le(code[:], 0), 0x53001C20)
		eq_word("SXTW X0,W1", load_le(code[:], 4), 0x93407C20)
	}

	// ---- 35. ADC X0, X1, X2; SBCS X3, X4, X5 -----------------------------
	//   ADC X0,X1,X2  = 0x9A000000 | (X2<<16=0x20000) | (X1<<5=0x20) | X0
	//                 = 0x9A020020
	//   SBCS X3,X4,X5 = 0xFA000000 | 0x50000 | 0x80 | 3 = 0xFA050083
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.inst_r_r_r(.ADC,  a.X0, a.X1, a.X2),
			a.inst_r_r_r(.SBCS, a.X3, a.X4, a.X5),
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("ADC/SBCS: encode", r.success)
		eq_word("ADC X0,X1,X2",  load_le(code[:], 0), 0x9A020020)
		eq_word("SBCS X3,X4,X5", load_le(code[:], 4), 0xFA050083)
	}

	// ---- 36. Read RNDR via MRS ------------------------------------------
	//   MRS X7, RNDR  -- uses RNDR sysreg constant (0x5920)
	//     bits = 0xD5300000 | (0x5920 << 5) | 7
	//          = 0xD5300000 | 0xB2400 | 7 = 0xD53B2407
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.Instruction{
				mnemonic = .MRS, operand_count = 2, length = 4,
				ops = {a.op_reg(a.X7), a.op_imm(a.RNDR, 2), {}, {}},
			},
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("MRS X7,RNDR: encode", r.success)
		eq_word("MRS X7,RNDR",   load_le(code[:], 0), 0xD53B2407)
	}

	// ---- 37. LDAPUR / STLUR round-trip ----------------------------------
	//   LDAPUR X0, [X1, #8]   = 0xD9400000 | (8 << 12) | (1 << 5) | 0
	//                         = 0xD9400000 | 0x8000 | 0x20 = 0xD9408020
	//   STLUR  X2, [SP, #-8]  = 0xD9000000 | (-8 & 0x1FF) << 12 | (31 << 5) | 2
	//                         = 0xD9000000 | 0x1F8 << 12 | 0x3E0 | 2
	//                         = 0xD9000000 | 0x1F8000 | 0x3E2 = 0xD91F83E2
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.inst_ldst(.LDAPUR, a.X0, a.mem_offset(a.X1, 8)),
			a.inst_ldst(.STLUR,  a.X2, a.mem_offset(a.SP, -8)),
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("RCpc unscaled: encode",   r.success)
		eq_word("LDAPUR X0,[X1,#8]",  load_le(code[:], 0), 0xD9408020)
		eq_word("STLUR X2,[SP,#-8]",  load_le(code[:], 4), 0xD91F83E2)
	}

	// ---- 38. System barriers + BTI: SB; BTI j; PSB CSYNC ----------------
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.inst_none(.SB),
			a.inst_none(.BTI_J),
			a.inst_none(.PSB_CSYNC),
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("barriers/BTI: encode", r.success)
		eq_word("SB",        load_le(code[:], 0), 0xD50330FF)
		eq_word("BTI j",     load_le(code[:], 4), 0xD503245F)
		eq_word("PSB CSYNC", load_le(code[:], 8), 0xD503223F)
	}

	// ---- 39. LSL_IMM Wd, Wn, #4 -- composite-packed alias --------------
	//   LSL W0, W1, #4  = UBFM W0, W1, #(32-4)=#28, #(31-4)=#27
	//     = 0x53000000 | (28<<16=0x1C0000) | (27<<10=0x6C00) | (W1<<5=0x20) | W0
	//     = 0x531C6C20
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.inst_r_r_i(.LSL_IMM, a.W0, a.W1, 4),
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("LSL_IMM 32: encode", r.success)
		eq_word("LSL W0,W1,#4", load_le(code[:], 0), 0x531C6C20)
	}

	// ---- 40. ROR_IMM Wd, Wn, #4 -- dual-Rn-packed alias ----------------
	//   ROR W0, W1, #4  = EXTR W0, W1, W1, #4
	//     = 0x13800000 | (W1<<16=0x10000) | (4<<10=0x1000) | (W1<<5=0x20) | W0
	//     = 0x13811020
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []a.Instruction{
			a.inst_r_r_i(.ROR_IMM, a.W0, a.W1, 4),
		}
		r := a.encode(insts, nil, code[:], &relocs, &errors)
		ok("ROR_IMM 32: encode", r.success)
		eq_word("ROR W0,W1,#4", load_le(code[:], 0), 0x13811020)
	}

	fmt.println()
	fmt.printfln("==> arm64 pipeline: %d passed, %d failed", rpasses, rfailures)
	if rfailures > 0 { os.exit(1) }
}
