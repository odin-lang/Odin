// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_mips_tests

// Decoder smoke tests. Drives encode -> decode round-trips and checks
// that mnemonics + operands survive intact, plus label inference for
// branches and graceful handling of garbage.

import "core:fmt"
import "core:os"
import mips "../"

@(private="file") dpasses   := 0
@(private="file") dfailures := 0

@(private="file")
dcheck_bool :: proc(name: string, got, want: bool) {
	if got == want {
		fmt.printfln("  [ok]   %-26s %v", name, got)
		dpasses += 1
	} else {
		fmt.printfln("  [FAIL] %-26s got=%v want=%v", name, got, want)
		dfailures += 1
	}
}

@(private="file")
dcheck_int :: proc(name: string, got, want: int) {
	if got == want {
		fmt.printfln("  [ok]   %-26s %d", name, got)
		dpasses += 1
	} else {
		fmt.printfln("  [FAIL] %-26s got=%d want=%d", name, got, want)
		dfailures += 1
	}
}

@(private="file")
dcheck_mnem :: proc(name: string, got, want: mips.Mnemonic) {
	if got == want {
		fmt.printfln("  [ok]   %-26s %v", name, got)
		dpasses += 1
	} else {
		fmt.printfln("  [FAIL] %-26s got=%v want=%v", name, got, want)
		dfailures += 1
	}
}

@(private="file")
dcheck_reg :: proc(name: string, got, want: mips.Register) {
	if got == want {
		fmt.printfln("  [ok]   %-26s %04x", name, u16(got))
		dpasses += 1
	} else {
		fmt.printfln("  [FAIL] %-26s got=%04x want=%04x", name, u16(got), u16(want))
		dfailures += 1
	}
}

run_decoder_tests :: proc() {
	fmt.println()
	fmt.println("=== MIPS decoder spot checks ===")

	code:    [256]u8
	relocs:  [dynamic]mips.Relocation
	errors:  [dynamic]mips.Error
	defer delete(relocs)
	defer delete(errors)

	// ---- 1. Round-trip: R-type / I-type / load / NOP / LUI / shift -------
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		src := []mips.Instruction{
			mips.inst_r_r_r(.ADD,   mips.T0, mips.T1, mips.T2),
			mips.inst_r_r_i(.ADDIU, mips.T0, mips.T1, 100),
			mips.inst_r_m  (.LW,    mips.T0, mips.mem(mips.SP, 16)),
			mips.inst_none (.NOP),
			mips.inst_r_i  (.LUI,   mips.T0, 0x1234),
			mips.inst_shift(.SLL,   mips.T0, mips.T1, 5),
		}
		eres := mips.encode(src, nil, code[:], &relocs, &errors)
		dcheck_bool("rt: encode ok", eres.success, true)

		dec_insts:  [dynamic]mips.Instruction
		dec_info:   [dynamic]mips.Instruction_Info
		dec_labels: [dynamic]mips.Label_Definition
		defer delete(dec_insts)
		defer delete(dec_info)
		defer delete(dec_labels)
		clear(&errors)

		dres := mips.decode(code[:eres.byte_count], nil,
							&dec_insts, &dec_info, &dec_labels, &errors)

		dcheck_bool("rt: decode ok",      dres.success,   true)
		dcheck_int ("rt: byte_count",     int(dres.byte_count), 24)
		dcheck_int ("rt: instruction n",  len(dec_insts), 6)
		dcheck_int ("rt: info n",         len(dec_info),  6)
		dcheck_int ("rt: errors n",       len(errors),    0)

		dcheck_mnem("rt[0] ADD",          dec_insts[0].mnemonic, .ADD)
		dcheck_mnem("rt[1] ADDIU",        dec_insts[1].mnemonic, .ADDIU)
		dcheck_mnem("rt[2] LW",           dec_insts[2].mnemonic, .LW)
		dcheck_mnem("rt[3] NOP",          dec_insts[3].mnemonic, .NOP)
		dcheck_mnem("rt[4] LUI",          dec_insts[4].mnemonic, .LUI)
		dcheck_mnem("rt[5] SLL",          dec_insts[5].mnemonic, .SLL)

		// ADD rd,rs,rt -- the encoder's inst_r_r_r places (T0,T1,T2)
		// in ops[0..2]; decoder must reproduce the same.
		i0 := dec_insts[0]
		dcheck_int ("rt[0] opcnt", int(i0.operand_count), 3)
		dcheck_reg ("rt[0] op0=T0", i0.ops[0].reg, mips.T0)
		dcheck_reg ("rt[0] op1=T1", i0.ops[1].reg, mips.T1)
		dcheck_reg ("rt[0] op2=T2", i0.ops[2].reg, mips.T2)

		// ADDIU rt,rs,imm
		i1 := dec_insts[1]
		dcheck_int ("rt[1] opcnt", int(i1.operand_count), 3)
		dcheck_reg ("rt[1] op0=T0", i1.ops[0].reg, mips.T0)
		dcheck_reg ("rt[1] op1=T1", i1.ops[1].reg, mips.T1)
		dcheck_int ("rt[1] imm=100", int(i1.ops[2].immediate), 100)

		// LW rt,disp(base) -- ops[0]=T0 (rt), ops[1]=MEM(SP,16)
		i2 := dec_insts[2]
		dcheck_int ("rt[2] opcnt", int(i2.operand_count), 2)
		dcheck_reg ("rt[2] op0=T0", i2.ops[0].reg, mips.T0)
		dcheck_int ("rt[2] mem.kind",  int(i2.ops[1].kind), int(mips.Operand_Kind.MEMORY))
		dcheck_reg ("rt[2] mem.base=SP", i2.ops[1].mem.base, mips.SP)
		dcheck_int ("rt[2] mem.disp=16", int(i2.ops[1].mem.disp), 16)

		// LUI rt,imm
		i4 := dec_insts[4]
		dcheck_int ("rt[4] opcnt", int(i4.operand_count), 2)
		dcheck_int ("rt[4] imm=0x1234", int(i4.ops[1].immediate), 0x1234)

		// SLL rd,rt,shamt
		i5 := dec_insts[5]
		dcheck_int ("rt[5] opcnt", int(i5.operand_count), 3)
		dcheck_reg ("rt[5] op0=T0", i5.ops[0].reg, mips.T0)
		dcheck_reg ("rt[5] op1=T1", i5.ops[1].reg, mips.T1)
		dcheck_int ("rt[5] shamt=5", int(i5.ops[2].immediate), 5)
	}

	// ---- 2. Branch resolution survives the round trip --------------------
	//   loop: NOP; ADDIU; BNE t0,zero,loop; NOP
	//   After encode+decode, the BNE operand should point at byte offset 0
	//   and label inference should have created a label_def at 0.
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		ld_in: [dynamic]mips.Label_Definition
		defer delete(ld_in)
		append(&ld_in, mips.Label_Definition(0))

		src := []mips.Instruction{
			mips.inst_none(.NOP),
			mips.inst_r_r_i(.ADDIU, mips.T0, mips.T0, 1),
			mips.inst_branch2(.BNE, mips.T0, mips.ZERO, 0),
			mips.inst_none(.NOP),
		}
		eres := mips.encode(src, ld_in[:], code[:], &relocs, &errors)
		dcheck_bool("br: encode ok", eres.success, true)

		dec_insts:  [dynamic]mips.Instruction
		dec_info:   [dynamic]mips.Instruction_Info
		dec_labels: [dynamic]mips.Label_Definition
		defer delete(dec_insts)
		defer delete(dec_info)
		defer delete(dec_labels)
		clear(&errors)

		dres := mips.decode(code[:eres.byte_count], nil,
							&dec_insts, &dec_info, &dec_labels, &errors)
		dcheck_bool("br: decode ok",  dres.success,   true)
		dcheck_int ("br: insts",      len(dec_insts), 4)
		dcheck_mnem("br: BNE",        dec_insts[2].mnemonic, .BNE)

		bne := dec_insts[2]
		dcheck_int ("br: op2 kind",   int(bne.ops[2].kind), int(mips.Operand_Kind.RELATIVE))
		dcheck_int ("br: op2 target", int(bne.ops[2].relative), 0)

		// Label inference creates label_defs at branch targets.
		dcheck_int ("br: label_defs n", len(dec_labels), 1)
		dcheck_int ("br: label_defs[0]", int(dec_labels[0]), 0)
	}

	// ---- 3. J-type round-trip --------------------------------------------
	//   J target; target at inst 4 (byte 16). No base_address here means
	//   the J's target field will reflect the *byte region* containing PC.
	//   pc=0 -> (pc+4) & 0xF0000000 == 0 -> target_addr = field<<2 = 16.
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		ld_in: [dynamic]mips.Label_Definition
		defer delete(ld_in)
		append(&ld_in, mips.Label_Definition(4))

		src := []mips.Instruction{
			mips.inst_jump(.J, 0),
			mips.inst_none(.NOP),
			mips.inst_none(.NOP),
			mips.inst_none(.NOP),
			mips.inst_none(.NOP),
		}
		eres := mips.encode(src, ld_in[:], code[:], &relocs, &errors,
							base_address = 0)
		dcheck_bool("J: encode ok", eres.success, true)

		dec_insts:  [dynamic]mips.Instruction
		dec_info:   [dynamic]mips.Instruction_Info
		dec_labels: [dynamic]mips.Label_Definition
		defer delete(dec_insts)
		defer delete(dec_info)
		defer delete(dec_labels)
		clear(&errors)

		dres := mips.decode(code[:eres.byte_count], nil,
							&dec_insts, &dec_info, &dec_labels, &errors)
		dcheck_bool("J: decode ok",  dres.success,   true)
		dcheck_mnem("J: mnemonic",   dec_insts[0].mnemonic, .J)
		dcheck_int ("J: op kind",    int(dec_insts[0].ops[0].kind),
									 int(mips.Operand_Kind.RELATIVE))
		dcheck_int ("J: target",     int(dec_insts[0].ops[0].relative), 16)
	}

	// ---- 4. FPU ADD.S round-trip -----------------------------------------
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		src := []mips.Instruction{
			mips.inst_r_r_r(.ADD_S, mips.F4, mips.F5, mips.F6),
		}
		eres := mips.encode(src, nil, code[:], &relocs, &errors)
		dcheck_bool("FPU: encode ok", eres.success, true)

		dec_insts:  [dynamic]mips.Instruction
		dec_info:   [dynamic]mips.Instruction_Info
		dec_labels: [dynamic]mips.Label_Definition
		defer delete(dec_insts)
		defer delete(dec_info)
		defer delete(dec_labels)
		clear(&errors)

		dres := mips.decode(code[:eres.byte_count], nil,
							&dec_insts, &dec_info, &dec_labels, &errors)
		dcheck_bool("FPU: decode ok", dres.success, true)
		dcheck_mnem("FPU: ADD.S",     dec_insts[0].mnemonic, .ADD_S)
		i0 := dec_insts[0]
		dcheck_reg ("FPU: op0=F4",    i0.ops[0].reg, mips.F4)
		dcheck_reg ("FPU: op1=F5",    i0.ops[1].reg, mips.F5)
		dcheck_reg ("FPU: op2=F6",    i0.ops[2].reg, mips.F6)
	}

	// ---- 5. GTE RTPS round-trip ------------------------------------------
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		src := []mips.Instruction{mips.inst_none(.RTPS)}
		eres := mips.encode(src, nil, code[:], &relocs, &errors)
		dcheck_bool("GTE: encode ok", eres.success, true)

		dec_insts:  [dynamic]mips.Instruction
		dec_info:   [dynamic]mips.Instruction_Info
		dec_labels: [dynamic]mips.Label_Definition
		defer delete(dec_insts)
		defer delete(dec_info)
		defer delete(dec_labels)
		clear(&errors)

		dres := mips.decode(code[:eres.byte_count], nil,
							&dec_insts, &dec_info, &dec_labels, &errors)
		dcheck_bool("GTE: decode ok", dres.success, true)
		dcheck_mnem("GTE: RTPS",      dec_insts[0].mnemonic, .RTPS)
		dcheck_int ("GTE: opcnt 0",   int(dec_insts[0].operand_count), 0)
	}

	// ---- 6. Little-endian round-trip ------------------------------------
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		src := []mips.Instruction{
			mips.inst_r_r_r(.ADD, mips.T0, mips.T1, mips.T2),
		}
		eres := mips.encode(src, nil, code[:], &relocs, &errors,
							endianness = .LITTLE)
		dcheck_bool("LE: encode ok", eres.success, true)

		dec_insts:  [dynamic]mips.Instruction
		dec_info:   [dynamic]mips.Instruction_Info
		dec_labels: [dynamic]mips.Label_Definition
		defer delete(dec_insts)
		defer delete(dec_info)
		defer delete(dec_labels)
		clear(&errors)

		dres := mips.decode(code[:eres.byte_count], nil,
							&dec_insts, &dec_info, &dec_labels, &errors,
							endianness = .LITTLE)
		dcheck_bool("LE: decode ok", dres.success, true)
		dcheck_mnem("LE: ADD",       dec_insts[0].mnemonic, .ADD)
	}

	// ---- 7. Garbage word -> INVALID_OPCODE error -------------------------
	//   Every primary opcode is at least partially populated in MIPS, but
	//   we can hit an empty REGIMM rt slot (rt=4 has no entries in our
	//   table). word = (0x01 << 26) | (0x04 << 16) = 0x04040000.
	{
		for i in 0..<len(code) { code[i] = 0 }
		code[0] = 0x04
		code[1] = 0x04
		code[2] = 0x00
		code[3] = 0x00

		dec_insts:  [dynamic]mips.Instruction
		dec_info:   [dynamic]mips.Instruction_Info
		dec_labels: [dynamic]mips.Label_Definition
		defer delete(dec_insts)
		defer delete(dec_info)
		defer delete(dec_labels)
		clear(&errors)

		dres := mips.decode(code[:4], nil,
							&dec_insts, &dec_info, &dec_labels, &errors)
		dcheck_bool("garbage: success",   dres.success, false)
		dcheck_int ("garbage: insts",     len(dec_insts), 1)
		dcheck_mnem("garbage: INVALID",   dec_insts[0].mnemonic, .INVALID)
		dcheck_int ("garbage: errors n",  len(errors), 1)
		dcheck_bool("garbage: error code",
					len(errors) > 0 && errors[0].code == .INVALID_OPCODE,
					true)
	}

	fmt.println()
	fmt.printfln("==> decoder: %d passed, %d failed", dpasses, dfailures)
	if dfailures > 0 { os.exit(1) }
}
