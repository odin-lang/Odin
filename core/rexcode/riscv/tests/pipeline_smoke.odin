// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_riscv_tests

// End-to-end RISC-V pipeline tests: encode -> decode -> print across
// every instruction format (R/I/S/B/U/J), label inference for both B-type
// and J-type relocations (which exercise the scattered-immediate scatter/
// gather code), XLEN filtering for RV32-only and RV64-only entries, and
// representative spots from each extension (M/A/F/D).

import "core:fmt"
import "core:os"
import rv "../"

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
		fmt.printfln("  [ok]   %-26s %08x", name, got)
		rpasses += 1
	} else {
		fmt.printfln("  [FAIL] %-26s got=%08x want=%08x", name, got, want)
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
	fmt.println("=== RISC-V pipeline spot checks ===")

	code:   [256]u8
	relocs: [dynamic]rv.Relocation
	errors: [dynamic]rv.Error
	defer delete(relocs)
	defer delete(errors)

	// ---- 1. R-type / I-type / U-type byte-level checks ------------------
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		// ADD t0, a0, a1   = funct7=0, rs2=11, rs1=10, funct3=0, rd=5, opcode=0x33
		//                  = (11<<20)|(10<<15)|(0<<12)|(5<<7)|0x33
		//                  = 0x00B502B3
		// ADDI sp, sp, -16 = imm=-16 (0xFF0), rs1=2, funct3=0, rd=2, opcode=0x13
		//                  = (0xFF0<<20)|(2<<15)|(2<<7)|0x13
		//                  = 0xFF010113
		// LUI t0, 0x12345  = imm=0x12345, rd=5, opcode=0x37
		//                  = (0x12345<<12)|(5<<7)|0x37 = 0x123452B7
		// AUIPC ra, 0x10   = imm=0x10, rd=1, opcode=0x17
		//                  = (0x10<<12)|(1<<7)|0x17 = 0x000100B7  wait that's 0x000100 ... let me recompute
		//                  = 0x10 << 12 = 0x10000; rd=1 -> 0x80; opcode=0x17
		//                  = 0x00010000 | 0x00000080 | 0x00000017 = 0x00010097
		insts := []rv.Instruction{
			rv.inst_r_r_r(.ADD,  rv.T0, rv.A0, rv.A1),
			rv.inst_r_r_i(.ADDI, rv.SP, rv.SP, -16),
			rv.inst_u    (.LUI,  rv.T0, 0x12345),
			rv.inst_u    (.AUIPC,rv.RA, 0x10),
		}
		byte_count, success := rv.encode(insts, nil, code[:], &relocs, &errors)
		ok("R/I/U: encode ok", success)
		eq_word("R: ADD t0,a0,a1",     load_le(code[:], 0),  0x00B502B3)
		eq_word("I: ADDI sp,sp,-16",   load_le(code[:], 4),  0xFF010113)
		eq_word("U: LUI t0,0x12345",   load_le(code[:], 8),  0x123452B7)
		eq_word("U: AUIPC ra,0x10",    load_le(code[:], 12), 0x00010097)
	}

	// ---- 2. Loads / stores: I-type and S-type immediate scatter ----------
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		// LW t0, 100(sp)  = imm=100 (0x064), rs1=2, f3=2, rd=5, opcode=0x03
		//                 = (0x064<<20)|(2<<15)|(2<<12)|(5<<7)|0x03 = 0x06412283
		// SW a0, -8(sp)   = imm=-8 (0xFF8), rs2=10, rs1=2, f3=2, opcode=0x23
		//                 S-scatter: imm[11:5]=0x7F at 31-25, imm[4:0]=0x18 at 11-7
		//                 = (0x7F<<25)|(10<<20)|(2<<15)|(2<<12)|(0x18<<7)|0x23
		//                 = 0xFEA12C23
		insts := []rv.Instruction{
			rv.inst_load (.LW, rv.T0, rv.mem(rv.SP, 100)),
			rv.inst_store(.SW, rv.A0, rv.mem(rv.SP, -8)),
		}
		byte_count, success := rv.encode(insts, nil, code[:], &relocs, &errors)
		ok("LW/SW: encode ok", success)
		eq_word("LW t0,100(sp)",  load_le(code[:], 0), 0x06412283)
		eq_word("SW a0,-8(sp)",   load_le(code[:], 4), 0xFEA12C23)
	}

	// ---- 3. B-type branch with backward label ---------------------------
	//   loop:                             (inst 0, pc=0)
	//         addi t0, t0, 1              (inst 1, pc=4)
	//         bne  t0, zero, loop         (inst 2, pc=8 -> rel = -8)
	//         nop (encoded as addi x0,x0,0) (inst 3, pc=12)
	//
	//   BNE rs1=5, rs2=0, target=-8 -> imm[12]=1, imm[10:5]=0x3F, imm[4:1]=0xC, imm[11]=1
	//                                  encoded = scatter_b(-8 as u32 0xFFFFFFF8)
	//                                  = (1<<31)|(0x3F<<25)|(0<<20)|(5<<15)|(1<<12)|(0xC<<8)|(1<<7)|0x63
	//                                  = 0xFE029CE3
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		ld: [dynamic]rv.Label_Definition
		defer delete(ld)
		append(&ld, rv.Label_Definition(0))   // loop at inst 0

		insts := []rv.Instruction{
			rv.inst_r_r_i(.ADDI, rv.T0, rv.T0, 0),    // nop placeholder for inst 0
			rv.inst_r_r_i(.ADDI, rv.T0, rv.T0, 1),
			rv.inst_branch(.BNE, rv.T0, rv.ZERO, 0),
			rv.inst_r_r_i(.ADDI, rv.ZERO, rv.ZERO, 0),
		}
		byte_count, success := rv.encode(insts, ld[:], code[:], &relocs, &errors)
		ok("br: encode ok", success)
		ok("br: no leftover relocs", len(relocs) == 0)
		eq_word("BNE rel=-8",  load_le(code[:], 8), 0xFE029CE3)
	}

	// ---- 4. JAL forward jump --------------------------------------------
	//   jal  ra, target               (inst 0, pc=0)
	//   addi sp, sp, 0                (inst 1, pc=4)
	//   target: ret (encoded as JALR x0, ra, 0)   (inst 2, pc=8)
	//
	//   JAL ra, +8: scatter_j(8) places imm[10:1]=4 -> bits 30-21
	//               = (4 << 21)|(1<<7)|0x6F = 0x008000EF
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		ld: [dynamic]rv.Label_Definition
		defer delete(ld)
		append(&ld, rv.Label_Definition(2))   // target at inst 2

		insts := []rv.Instruction{
			rv.inst_jal(.JAL, rv.RA, 0),
			rv.inst_r_r_i(.ADDI, rv.SP, rv.SP, 0),
			rv.inst_jalr(rv.ZERO, rv.RA, 0),
		}
		byte_count, success := rv.encode(insts, ld[:], code[:], &relocs, &errors)
		ok("JAL: encode ok", success)
		eq_word("JAL ra,+8", load_le(code[:], 0), 0x008000EF)
	}

	// ---- 5. Round-trip: encode -> decode -> print -----------------------
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		ld: [dynamic]rv.Label_Definition
		defer delete(ld)
		append(&ld, rv.Label_Definition(0))

		src := []rv.Instruction{
			rv.inst_r_r_i(.ADDI, rv.T0, rv.T0, 1),
			rv.inst_load (.LW,   rv.A0, rv.mem(rv.SP, 0)),
			rv.inst_branch(.BNE, rv.T0, rv.ZERO, 0),
		}
		byte_count, success := rv.encode(src, ld[:], code[:], &relocs, &errors)
		ok("rt: encode ok", success)

		d_insts:  [dynamic]rv.Instruction
		d_info:   [dynamic]rv.Instruction_Info
		d_labels: [dynamic]rv.Label_Definition
		defer delete(d_insts); defer delete(d_info); defer delete(d_labels)
		clear(&errors)
		dbyte_count, dsuccess := rv.decode(code[:byte_count], nil, &d_insts, &d_info, &d_labels, &errors)
		ok("rt: decode ok",   dsuccess)
		ok("rt: 3 insts",     len(d_insts) == 3)
		ok("rt: ADDI",        d_insts[0].mnemonic == .ADDI)
		ok("rt: LW",          d_insts[1].mnemonic == .LW)
		ok("rt: BNE",         d_insts[2].mnemonic == .BNE)
		ok("rt: branch target = 0",
		   d_insts[2].ops[2].kind == .RELATIVE && int(d_insts[2].ops[2].relative) == 0)

		text := rv.aprint(d_insts[:], d_info[:], d_labels[:],
						  nil, nil, nil, context.temp_allocator)
		eq_str("rt: print",
			   text,
			   ".L0:\n    addi t0, t0, 1\n    lw a0, 0(sp)\n    bne t0, zero, .L0\n")
	}

	// ---- 6. M extension round-trip --------------------------------------
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		src := []rv.Instruction{
			rv.inst_r_r_r(.MUL,  rv.T0, rv.A0, rv.A1),
			rv.inst_r_r_r(.DIV,  rv.T1, rv.A0, rv.A1),
			rv.inst_r_r_r(.REMU, rv.T2, rv.A0, rv.A1),
		}
		byte_count, success := rv.encode(src, nil, code[:], &relocs, &errors)
		ok("M: encode ok", success)

		d_insts:  [dynamic]rv.Instruction
		d_info:   [dynamic]rv.Instruction_Info
		d_labels: [dynamic]rv.Label_Definition
		defer delete(d_insts); defer delete(d_info); defer delete(d_labels)
		clear(&errors)
		rv.decode(code[:byte_count], nil, &d_insts, &d_info, &d_labels, &errors)
		ok("M: MUL",  d_insts[0].mnemonic == .MUL)
		ok("M: DIV",  d_insts[1].mnemonic == .DIV)
		ok("M: REMU", d_insts[2].mnemonic == .REMU)
	}

	// ---- 7. A extension: AMOADD.W ---------------------------------------
	//   AMOADD.W rd=t0, rs2=a1, addr=(a0)
	//   funct5=0, aq=rl=0, funct3=2, opcode=0x2F
	//   = (0<<27)|(0<<25)|(11<<20)|(10<<15)|(2<<12)|(5<<7)|0x2F
	//   = (11<<20) | (10<<15) | (2<<12) | (5<<7) | 0x2F
	//   = 0x00B522AF
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		insts := []rv.Instruction{
			rv.Instruction{
				mnemonic = .AMOADD_W, operand_count = 3, length = 4,
				ops = {
					rv.op_reg(rv.T0),
					rv.op_reg(rv.A1),
					rv.op_mem(rv.mem(rv.A0, 0)),
					{},
				},
			},
		}
		byte_count, success := rv.encode(insts, nil, code[:], &relocs, &errors)
		ok("A: encode ok",       success)
		eq_word("A: AMOADD.W",   load_le(code[:], 0), 0x00B522AF)
	}

	// ---- 8. F extension: FADD.S round-trip ------------------------------
	//   FADD.S fa0, fa1, fa2 (with default rm=0 = RNE)
	//   funct7=0, rs2=12, rs1=11, funct3=0 (rm), rd=10, opcode=0x53
	//   = (12<<20)|(11<<15)|(0<<12)|(10<<7)|0x53
	//   = 0x00C58553
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		insts := []rv.Instruction{
			rv.Instruction{
				mnemonic = .FADD_S, operand_count = 3, length = 4,
				ops = {
					rv.op_fpr(.FA0),
					rv.op_fpr(.FA1),
					rv.op_fpr(.FA2),
					{},
				},
			},
		}
		byte_count, success := rv.encode(insts, nil, code[:], &relocs, &errors)
		ok("F: encode ok",    success)
		eq_word("F: FADD.S",  load_le(code[:], 0), 0x00C58553)

		d_insts:  [dynamic]rv.Instruction
		d_info:   [dynamic]rv.Instruction_Info
		d_labels: [dynamic]rv.Label_Definition
		defer delete(d_insts); defer delete(d_info); defer delete(d_labels)
		clear(&errors)
		rv.decode(code[:byte_count], nil, &d_insts, &d_info, &d_labels, &errors)

		text := rv.aprint(d_insts[:], d_info[:], d_labels[:],
						  nil, nil, nil, context.temp_allocator)
		eq_str("F: print", text, "    fadd.s fa0, fa1, fa2\n")
	}

	// ---- 9. D extension: FMADD.D R4-type --------------------------------
	//   FMADD.D fa0, fa1, fa2, fa3 (rm=0)
	//   funct7 = (fa3<<27) | (fmt=1<<25) -- wait FMADD format is in fmt
	//   bits = 0x02000043 base | rs3<<27 | rs2<<20 | rs1<<15 | rd<<7
	//        = 0x02000043 | (13<<27) | (12<<20) | (11<<15) | (10<<7)
	//        = 0x02000043 | 0x68000000 | 0x00C00000 | 0x00058000 | 0x00000500
	//        = 0x6AC58543
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		insts := []rv.Instruction{
			rv.inst_r4(.FMADD_D,
				rv.Register(rv.REG_FPR | 10),    // fa0
				rv.Register(rv.REG_FPR | 11),    // fa1
				rv.Register(rv.REG_FPR | 12),    // fa2
				rv.Register(rv.REG_FPR | 13)),   // fa3
		}
		byte_count, success := rv.encode(insts, nil, code[:], &relocs, &errors)
		ok("D: encode ok",     success)
		eq_word("D: FMADD.D",  load_le(code[:], 0), 0x6AC58543)
	}

	// ---- 10. CSR: csrrw a0, mhartid (0xF14), zero ------------------------
	//   bits: csr<<20 | rs1<<15 | f3=1 | rd<<7 | 0x73
	//       = (0xF14<<20) | (0<<15) | (1<<12) | (10<<7) | 0x73
	//       = 0xF1401573
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		insts := []rv.Instruction{
			rv.inst_csr(.CSRRW, rv.A0, 0xF14, rv.ZERO),
		}
		byte_count, success := rv.encode(insts, nil, code[:], &relocs, &errors)
		ok("CSR: encode ok",  success)
		eq_word("CSR: csrrw",  load_le(code[:], 0), 0xF1401573)
	}

	// ---- 11. XLEN filter: $00003003 decodes as LD on RV64, not on RV32 ---
	{
		// bytes: 03 30 00 00 (LE: 0x00003003)
		code_ld := []u8{0x03, 0x30, 0x00, 0x00}

		d_insts:  [dynamic]rv.Instruction
		d_info:   [dynamic]rv.Instruction_Info
		d_labels: [dynamic]rv.Label_Definition
		defer delete(d_insts); defer delete(d_info); defer delete(d_labels)
		clear(&errors)

		// RV64: should decode as LD.
		rv.decode(code_ld, nil, &d_insts, &d_info, &d_labels, &errors, xlen = .RV64)
		ok("XLEN: RV64 LD", len(d_insts) >= 1 && d_insts[0].mnemonic == .LD)

		clear(&d_insts); clear(&d_info); clear(&d_labels); clear(&errors)
		rv.decode(code_ld, nil, &d_insts, &d_info, &d_labels, &errors, xlen = .RV32)
		ok("XLEN: RV32 INVALID",
		   len(d_insts) >= 1 && d_insts[0].mnemonic == .INVALID)
	}

	// ---- 12. C extension: encode + 2-byte output ------------------------
	//   C.NOP                  = 0x0001
	//   C.LI a0, 5             = 010 0 01010 00101 01 = 0x4515
	//   C.ADD a0, a1           = 1001 01010 01011 10 = 0x952E
	//   C.MV a2, a3            = 1000 01100 01101 10 = 0x8636
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []rv.Instruction{
			rv.inst_none(.C_NOP),
			rv.Instruction{
				mnemonic = .C_LI, operand_count = 2, length = 2,
				ops = {rv.op_reg(rv.A0), rv.op_imm(5, 1), {}, {}},
			},
			rv.Instruction{
				mnemonic = .C_ADD, operand_count = 2, length = 2,
				ops = {rv.op_reg(rv.A0), rv.op_reg(rv.A1), {}, {}},
			},
			rv.Instruction{
				mnemonic = .C_MV, operand_count = 2, length = 2,
				ops = {rv.op_reg(rv.A2), rv.op_reg(rv.A3), {}, {}},
			},
		}
		byte_count, success := rv.encode(insts, nil, code[:], &relocs, &errors)
		ok("C: encode ok",  success)
		ok("C: byte count", byte_count == 8)
		get_hw := proc(buf: []u8, off: u32) -> u16 {
			return u16(buf[off]) | (u16(buf[off+1]) << 8)
		}
		check_hw := proc(name: string, got, want: u16) {
			if got == want { fmt.printfln("  [ok]   %-26s %04x", name, got); rpasses += 1 }
			else           { fmt.printfln("  [FAIL] %-26s got=%04x want=%04x", name, got, want); rfailures += 1 }
		}
		check_hw("C.NOP",         get_hw(code[:], 0), 0x0001)
		check_hw("C.LI a0, 5",    get_hw(code[:], 2), 0x4515)
		check_hw("C.ADD a0, a1",  get_hw(code[:], 4), 0x952E)
		check_hw("C.MV a2, a3",   get_hw(code[:], 6), 0x8636)

		d_insts:  [dynamic]rv.Instruction
		d_info:   [dynamic]rv.Instruction_Info
		d_labels: [dynamic]rv.Label_Definition
		defer delete(d_insts); defer delete(d_info); defer delete(d_labels)
		clear(&errors)
		rv.decode(code[:byte_count], nil, &d_insts, &d_info, &d_labels, &errors)
		ok("C: decode 4 insts", len(d_insts) == 4)
		ok("C: NOP",   len(d_insts) >= 1 && d_insts[0].mnemonic == .C_NOP)
		ok("C: LI",    len(d_insts) >= 2 && d_insts[1].mnemonic == .C_LI)
		ok("C: ADD",   len(d_insts) >= 3 && d_insts[2].mnemonic == .C_ADD)
		ok("C: MV",    len(d_insts) >= 4 && d_insts[3].mnemonic == .C_MV)
	}

	// ---- 13. Mixed C + RV64I: variable-length PC tracking ---------------
	//   C.LI a0, 0      (2 bytes)
	//   ADDI a1, a1, 1  (4 bytes)
	//   C.MV a2, a0     (2 bytes)
	//   total = 8 bytes
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []rv.Instruction{
			rv.Instruction{
				mnemonic = .C_LI, operand_count = 2, length = 2,
				ops = {rv.op_reg(rv.A0), rv.op_imm(0, 1), {}, {}},
			},
			rv.inst_r_r_i(.ADDI, rv.A1, rv.A1, 1),
			rv.Instruction{
				mnemonic = .C_MV, operand_count = 2, length = 2,
				ops = {rv.op_reg(rv.A2), rv.op_reg(rv.A0), {}, {}},
			},
		}
		byte_count, success := rv.encode(insts, nil, code[:], &relocs, &errors)
		ok("C: mixed encode",     success)
		ok("C: mixed bytes = 8",  byte_count == 8)

		d_insts:  [dynamic]rv.Instruction
		d_info:   [dynamic]rv.Instruction_Info
		d_labels: [dynamic]rv.Label_Definition
		defer delete(d_insts); defer delete(d_info); defer delete(d_labels)
		clear(&errors)
		rv.decode(code[:byte_count], nil, &d_insts, &d_info, &d_labels, &errors)
		ok("C: mixed decode 3",  len(d_insts) == 3)
		ok("C: [0]=C.LI len=2", len(d_insts) >= 1 && d_insts[0].mnemonic == .C_LI    && d_insts[0].length == 2)
		ok("C: [1]=ADDI len=4", len(d_insts) >= 2 && d_insts[1].mnemonic == .ADDI    && d_insts[1].length == 4)
		ok("C: [2]=C.MV len=2", len(d_insts) >= 3 && d_insts[2].mnemonic == .C_MV    && d_insts[2].length == 2)
	}

	// ---- 14. C.BEQZ forward branch -- exercise C_BRANCH9 relocation -----
	//   layout (bytes):
	//     0:  C.BEQZ a5, .L0     (2 bytes)  -- want offset = +6 (to byte 6)
	//     2:  C.LI a0, 0         (2 bytes)
	//     4:  C.LI a1, 1         (2 bytes)
	//     6:  .L0: C.NOP          (2 bytes)  -- target
	//
	//   Expected scatter for offset = 6:
	//     bit 12 = imm[8] = 0
	//     bits 11:10 = imm[4:3] = 00
	//     bits 6:5 = imm[7:6] = 0
	//     bits 4:3 = imm[2:1] = 11 (since 6 = 0b110: imm[2]=1, imm[1]=1)
	//     bit 2 = imm[5] = 0
	//   Plus C.BEQZ base 0xC001 + rs1' (a5 = x15, prime=7) at bits 9:7 = 7<<7=0x380
	//   Final: 0xC001 | 0x380 | 0x18 = 0xC399
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		ld: [dynamic]rv.Label_Definition
		defer delete(ld)
		append(&ld, rv.Label_Definition(3))   // .L0 = instruction index 3 (byte 6)

		insts := []rv.Instruction{
			rv.Instruction{
				mnemonic = .C_BEQZ, operand_count = 2, length = 2,
				ops = {rv.op_reg(rv.A5), rv.op_label(0), {}, {}},
			},
			rv.Instruction{
				mnemonic = .C_LI, operand_count = 2, length = 2,
				ops = {rv.op_reg(rv.A0), rv.op_imm(0, 1), {}, {}},
			},
			rv.Instruction{
				mnemonic = .C_LI, operand_count = 2, length = 2,
				ops = {rv.op_reg(rv.A1), rv.op_imm(1, 1), {}, {}},
			},
			rv.inst_none(.C_NOP),
		}
		byte_count, success := rv.encode(insts, ld[:], code[:], &relocs, &errors)
		ok("C.BEQZ: encode",       success)
		ok("C.BEQZ: byte_count=8", byte_count == 8)

		get_hw := proc(buf: []u8, off: u32) -> u16 {
			return u16(buf[off]) | (u16(buf[off+1]) << 8)
		}
		check_hw := proc(name: string, got, want: u16) {
			if got == want { fmt.printfln("  [ok]   %-26s %04x", name, got); rpasses += 1 }
			else           { fmt.printfln("  [FAIL] %-26s got=%04x want=%04x", name, got, want); rfailures += 1 }
		}
		check_hw("C.BEQZ +6 -> .L0", get_hw(code[:], 0), 0xC399)

		// Round-trip: decode and verify the C.BEQZ relative target is byte 6.
		d_insts:  [dynamic]rv.Instruction
		d_info:   [dynamic]rv.Instruction_Info
		d_labels: [dynamic]rv.Label_Definition
		defer delete(d_insts); defer delete(d_info); defer delete(d_labels)
		clear(&errors)
		rv.decode(code[:byte_count], nil, &d_insts, &d_info, &d_labels, &errors)
		ok("C.BEQZ: decode count",   len(d_insts) == 4)
		ok("C.BEQZ: [0] mnemonic",   len(d_insts) >= 1 && d_insts[0].mnemonic == .C_BEQZ)
		ok("C.BEQZ: target = 6",     len(d_insts) >= 1 && d_insts[0].ops[1].kind == .RELATIVE && u32(d_insts[0].ops[0].relative + d_insts[0].ops[1].relative)*0+ u32(d_insts[0].ops[1].relative) == 6)
	}

	// ---- 15. C.J backward jump across mixed-format code -----------------
	//   layout:
	//     0:  C.LI a0, 1              (2 bytes) -- .L0 target
	//     2:  ADDI a1, a1, 1          (4 bytes)
	//     6:  C.LI a2, 2              (2 bytes)
	//     8:  C.J .L0                 (2 bytes) -- want offset = -8
	//
	//   Expected scatter for offset = -8:
	//     The 12-bit signed value of -8 is 0xFF8 (twos complement,
	//     binary 1111_1111_1000 -- bits 11:3 all set, bit 4 = 1, bits 2:0 = 0).
	//     Per scatter_c_jump bit assignments:
	//       imm[11] = 1  -> bit 12 = 1     -> 0x1000
	//       imm[4]  = 1  -> bit 11 = 1     -> 0x0800
	//       imm[9:8]= 11 -> bits 10:9 = 11 -> 0x0600
	//       imm[10] = 1  -> bit 8  = 1     -> 0x0100
	//       imm[6]  = 1  -> bit 7  = 1     -> 0x0080
	//       imm[7]  = 1  -> bit 6  = 1     -> 0x0040
	//       imm[3:1]= 100-> bits 5:3= 100  -> 0x0020
	//       imm[5]  = 1  -> bit 2  = 1     -> 0x0004
	//     scatter result = 0x1FE4
	//   C.J base 0xA001 | 0x1FE4 = 0xBFE5
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		ld: [dynamic]rv.Label_Definition
		defer delete(ld)
		append(&ld, rv.Label_Definition(0))   // .L0 = first instruction

		insts := []rv.Instruction{
			rv.Instruction{
				mnemonic = .C_LI, operand_count = 2, length = 2,
				ops = {rv.op_reg(rv.A0), rv.op_imm(1, 1), {}, {}},
			},
			rv.inst_r_r_i(.ADDI, rv.A1, rv.A1, 1),
			rv.Instruction{
				mnemonic = .C_LI, operand_count = 2, length = 2,
				ops = {rv.op_reg(rv.A2), rv.op_imm(2, 1), {}, {}},
			},
			rv.Instruction{
				mnemonic = .C_J, operand_count = 1, length = 2,
				ops = {rv.op_label(0), {}, {}, {}},
			},
		}
		byte_count, success := rv.encode(insts, ld[:], code[:], &relocs, &errors)
		ok("C.J: encode",       success)
		ok("C.J: byte_count=10", byte_count == 10)

		get_hw := proc(buf: []u8, off: u32) -> u16 {
			return u16(buf[off]) | (u16(buf[off+1]) << 8)
		}
		check_hw := proc(name: string, got, want: u16) {
			if got == want { fmt.printfln("  [ok]   %-26s %04x", name, got); rpasses += 1 }
			else           { fmt.printfln("  [FAIL] %-26s got=%04x want=%04x", name, got, want); rfailures += 1 }
		}
		check_hw("C.J -8 -> .L0",  get_hw(code[:], 8), 0xBFE5)

		// Round-trip with label inference.
		d_insts:  [dynamic]rv.Instruction
		d_info:   [dynamic]rv.Instruction_Info
		d_labels: [dynamic]rv.Label_Definition
		defer delete(d_insts); defer delete(d_info); defer delete(d_labels)
		clear(&errors)
		rv.decode(code[:byte_count], nil, &d_insts, &d_info, &d_labels, &errors)
		ok("C.J: decode count",  len(d_insts) == 4)
		ok("C.J: [3] mnemonic",  len(d_insts) >= 4 && d_insts[3].mnemonic == .C_J)
		ok("C.J: target = 0",    len(d_insts) >= 4 && d_insts[3].ops[0].kind == .RELATIVE && u32(d_insts[3].ops[0].relative) == 0)
	}

	// ---- 16. Out-of-range C.BEQZ -- expect LABEL_OUT_OF_RANGE error -----
	//   C.BEQZ can reach -256..+254 in even bytes. We place the target
	//   exactly 256 bytes ahead by inserting 64 4-byte NOPs (ADDI x0, x0, 0).
	{
		clear(&relocs); clear(&errors)
		big_code: [1024]u8
		for i in 0..<len(big_code) { big_code[i] = 0 }

		ld: [dynamic]rv.Label_Definition
		defer delete(ld)
		append(&ld, rv.Label_Definition(65))  // index 65: after 1 branch + 64 nops

		long_insts: [dynamic]rv.Instruction
		defer delete(long_insts)
		append(&long_insts, rv.Instruction{
			mnemonic = .C_BEQZ, operand_count = 2, length = 2,
			ops = {rv.op_reg(rv.A5), rv.op_label(0), {}, {}},
		})
		for i in 0..<64 {
			append(&long_insts, rv.inst_r_r_i(.ADDI, rv.ZERO, rv.ZERO, 0))
		}
		// Target at byte 2 + 64*4 = 258 -- out of range for 9-bit signed (max 254)
		append(&long_insts, rv.inst_none(.C_NOP))

		byte_count, success := rv.encode(long_insts[:], ld[:], big_code[:], &relocs, &errors)
		ok("C.BEQZ out-of-range: error", !success && len(errors) > 0)
		if len(errors) > 0 {
			ok("C.BEQZ out-of-range: code", errors[0].code == .LABEL_OUT_OF_RANGE)
		}
	}

	fmt.println()
	fmt.printfln("==> pipeline: %d passed, %d failed", rpasses, rfailures)
	if rfailures > 0 { os.exit(1) }
}
