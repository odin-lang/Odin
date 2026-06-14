package rexcode_rsp_tests

// End-to-end RSP pipeline tests: encode -> decode -> print round-trips
// over scalar core, vector ALU (with element selector), vector L/S,
// and branch label inference.

import "core:fmt"
import "core:os"
import "core:strings"
import rsp "../"

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
load_be :: proc(buf: []u8, offset: u32) -> u32 {
	return  (u32(buf[offset+0]) << 24) | (u32(buf[offset+1]) << 16) |
			(u32(buf[offset+2]) <<  8) |  u32(buf[offset+3])
}

run_rsp_pipeline_tests :: proc() {
	fmt.println()
	fmt.println("=== N64 RSP pipeline spot checks ===")

	code:   [256]u8
	relocs: [dynamic]rsp.Relocation
	errors: [dynamic]rsp.Error
	defer delete(relocs)
	defer delete(errors)

	// ---- 1. Scalar core encode + byte check + decode round-trip ---------
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		insts := []rsp.Instruction{
			rsp.inst_r_r_r(.ADD,  rsp.T0, rsp.T1, rsp.T2),
			rsp.inst_r_r_i(.ADDIU,rsp.T0, rsp.T1, 100),
			rsp.inst_r_m  (.LW,   rsp.T0, rsp.mem(rsp.SP, 16)),
			rsp.inst_none (.NOP),
		}
		e := rsp.encode(insts, nil, code[:], &relocs, &errors)
		ok      ("scalar: encode success",  e.success)
		eq_word ("scalar: ADD word",        load_be(code[:], 0),  0x012A4020)
		eq_word ("scalar: ADDIU word",      load_be(code[:], 4),  0x25280064)
		eq_word ("scalar: LW word",         load_be(code[:], 8),  0x8FA80010)
		eq_word ("scalar: NOP word",        load_be(code[:], 12), 0x00000000)

		d_insts:  [dynamic]rsp.Instruction
		d_info:   [dynamic]rsp.Instruction_Info
		d_labels: [dynamic]rsp.Label_Definition
		defer delete(d_insts)
		defer delete(d_info)
		defer delete(d_labels)
		clear(&errors)
		d := rsp.decode(code[:e.byte_count], nil, &d_insts, &d_info, &d_labels, &errors)
		ok("scalar: decode success", d.success)
		ok("scalar: 4 insts",        len(d_insts) == 4)
		ok("scalar[0] ADD",          d_insts[0].mnemonic == .ADD)
		ok("scalar[3] NOP",          d_insts[3].mnemonic == .NOP)

		// Printer:
		text := rsp.aprint(d_insts[:], d_info[:], d_labels[:],
						   nil, nil, nil, context.temp_allocator)
		eq_str("scalar: print",
			   text,
			   "    add $t0, $t1, $t2\n    addiu $t0, $t1, 100\n    lw $t0, 16($sp)\n    nop\n")
	}

	// ---- 2. Vector ALU: VMULF $v0, $v1, $v2[3] --------------------------
	//   bits: 0x4A000000 (op=0x12 | CO=1 | funct=0 VMULF)
	//   vd=0 (bits 10-6 = 0), vs=1 (bits 15-11 = 1 << 11 = 0x800),
	//   vt=2 (bits 20-16 = 2 << 16 = 0x20000), element=3 (bits 24-21 = 3 << 21 = 0x600000)
	//   word = 0x4A000000 | 0x600000 | 0x20000 | 0x800 | 0 = 0x4A620800
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []rsp.Instruction{
			rsp.inst_v_v_v(.VMULF, rsp.VR0, rsp.VR1, rsp.VR2, 3),
		}
		e := rsp.encode(insts, nil, code[:], &relocs, &errors)
		ok     ("vu: encode",   e.success)
		eq_word("vu: VMULF",    load_be(code[:], 0), 0x4A620800)

		d_insts:  [dynamic]rsp.Instruction
		d_info:   [dynamic]rsp.Instruction_Info
		d_labels: [dynamic]rsp.Label_Definition
		defer delete(d_insts)
		defer delete(d_info)
		defer delete(d_labels)
		clear(&errors)
		d := rsp.decode(code[:e.byte_count], nil, &d_insts, &d_info, &d_labels, &errors)
		ok("vu: decode",       d.success)
		ok("vu: VMULF mnem",   d_insts[0].mnemonic == .VMULF)
		i0 := d_insts[0]
		ok("vu: vd=$v0",       i0.ops[0].reg == rsp.VR0)
		ok("vu: vs=$v1",       i0.ops[1].reg == rsp.VR1)
		ok("vu: vt=$v2",       i0.ops[2].reg == rsp.VR2)
		ok("vu: elem=3",       i0.ops[2].element == 3)

		text := rsp.aprint(d_insts[:], d_info[:], d_labels[:],
						   nil, nil, nil, context.temp_allocator)
		eq_str("vu: print",
			   text,
			   "    vmulf $v0, $v1, $v2[3]\n")
	}

	// ---- 3. Vector load: LQV $v4, e[0], 16($t0) -------------------------
	//   bits: 0xC8002000 (LQV)
	//   base=$t0=8 (bits 25-21 = 8 << 21 = 0x01000000), vt=4 (bits 20-16 = 4 << 16 = 0x40000),
	//   element=0 (bits 10-7 = 0), offset=16 (bits 6-0 = 16 = 0x10)
	//   word = 0xC8002000 | 0x01000000 | 0x40000 | 0 | 0x10 = 0xC9042010
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		insts := []rsp.Instruction{
			rsp.inst_v_vmem(.LQV, rsp.VR4, rsp.vmem(rsp.T0, 0, 16)),
		}
		e := rsp.encode(insts, nil, code[:], &relocs, &errors)
		ok     ("vls: encode",   e.success)
		eq_word("vls: LQV",      load_be(code[:], 0), 0xC9042010)

		d_insts:  [dynamic]rsp.Instruction
		d_info:   [dynamic]rsp.Instruction_Info
		d_labels: [dynamic]rsp.Label_Definition
		defer delete(d_insts)
		defer delete(d_info)
		defer delete(d_labels)
		clear(&errors)
		d := rsp.decode(code[:e.byte_count], nil, &d_insts, &d_info, &d_labels, &errors)
		ok("vls: decode",       d.success)
		ok("vls: LQV mnem",     d_insts[0].mnemonic == .LQV)
		i0 := d_insts[0]
		ok("vls: vt=$v4",       i0.ops[0].reg == rsp.VR4)
		ok("vls: vmem.base=$t0",  i0.ops[1].vmem.base == rsp.T0)
		ok("vls: vmem.element=0", i0.ops[1].vmem.element == 0)
		ok("vls: vmem.offset=16", i0.ops[1].vmem.offset == 16)

		text := rsp.aprint(d_insts[:], d_info[:], d_labels[:],
						   nil, nil, nil, context.temp_allocator)
		eq_str("vls: print",
			   text,
			   "    lqv $v4, 16($t0)\n")
	}

	// ---- 4. Branch + label inference -------------------------------------
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		ld_in: [dynamic]rsp.Label_Definition
		defer delete(ld_in)
		append(&ld_in, rsp.Label_Definition(0))

		insts := []rsp.Instruction{
			rsp.inst_none(.NOP),
			rsp.inst_r_r_i(.ADDIU, rsp.T0, rsp.T0, 1),
			rsp.inst_branch2(.BNE, rsp.T0, rsp.ZERO, 0),
			rsp.inst_none(.NOP),
		}
		e := rsp.encode(insts, ld_in[:], code[:], &relocs, &errors)
		ok("br: encode", e.success)
		eq_word("br: BNE word", load_be(code[:], 8), 0x1500FFFD)

		d_insts:  [dynamic]rsp.Instruction
		d_info:   [dynamic]rsp.Instruction_Info
		d_labels: [dynamic]rsp.Label_Definition
		defer delete(d_insts)
		defer delete(d_info)
		defer delete(d_labels)
		clear(&errors)
		d := rsp.decode(code[:e.byte_count], nil, &d_insts, &d_info, &d_labels, &errors)
		ok("br: decode", d.success)
		ok("br: 1 label inferred", len(d_labels) == 1)
		ok("br: label at byte 0",  int(d_labels[0]) == 0)

		text := rsp.aprint(d_insts[:], d_info[:], d_labels[:],
						   nil, nil, nil, context.temp_allocator)
		eq_str("br: print",
			   text,
			   ".L0:\n    nop\n    addiu $t0, $t0, 1\n    bne $t0, $zero, .L0\n    nop\n")
	}

	// ---- 5. COP2 control move + CP0 named register ----------------------
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		// CFC2 $t0, VCO   (VCO is hw 0 of REG_VC class -> rd=0)
		// bits = 0x48400000, rt=8 << 16, rd=0 -> word = 0x48480000
		insts := []rsp.Instruction{
			rsp.Instruction{
				mnemonic = .CFC2,
				operand_count = 2,
				length = 4,
				ops = {rsp.op_reg(rsp.T0), rsp.op_reg(rsp.VCO), {}, {}},
			},
		}
		e := rsp.encode(insts, nil, code[:], &relocs, &errors)
		ok("cop2c: encode",   e.success)
		eq_word("cop2c: CFC2",load_be(code[:], 0), 0x48480000)

		d_insts:  [dynamic]rsp.Instruction
		d_info:   [dynamic]rsp.Instruction_Info
		d_labels: [dynamic]rsp.Label_Definition
		defer delete(d_insts)
		defer delete(d_info)
		defer delete(d_labels)
		clear(&errors)
		d := rsp.decode(code[:e.byte_count], nil, &d_insts, &d_info, &d_labels, &errors)
		ok("cop2c: decode",   d.success)
		ok("cop2c: CFC2 mnem",d_insts[0].mnemonic == .CFC2)

		text := rsp.aprint(d_insts[:], d_info[:], d_labels[:],
						   nil, nil, nil, context.temp_allocator)
		eq_str("cop2c: print", text, "    cfc2 $t0, vco\n")
	}

	// ---- 6. CP0 DMA register print --------------------------------------
	{
		clear(&relocs); clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }
		// MTC0 $t0, $4 (SP_STATUS) -> rt=8, rd=4
		// bits = 0x40800000, rt << 16 = 0x80000, rd << 11 = 0x2000
		// word = 0x40800000 | 0x80000 | 0x2000 = 0x40882000
		insts := []rsp.Instruction{
			rsp.Instruction{
				mnemonic = .MTC0,
				operand_count = 2,
				length = 4,
				ops = {rsp.op_reg(rsp.T0), rsp.op_reg(rsp.Register(rsp.REG_CP0 | 4)), {}, {}},
			},
		}
		e := rsp.encode(insts, nil, code[:], &relocs, &errors)
		ok("cp0: encode",     e.success)
		eq_word("cp0: MTC0",  load_be(code[:], 0), 0x40882000)

		d_insts:  [dynamic]rsp.Instruction
		d_info:   [dynamic]rsp.Instruction_Info
		d_labels: [dynamic]rsp.Label_Definition
		defer delete(d_insts)
		defer delete(d_info)
		defer delete(d_labels)
		clear(&errors)
		rsp.decode(code[:e.byte_count], nil, &d_insts, &d_info, &d_labels, &errors)

		text := rsp.aprint(d_insts[:], d_info[:], d_labels[:],
						   nil, nil, nil, context.temp_allocator)
		eq_str("cp0: print",  text, "    mtc0 $t0, $sp_status\n")
	}

	fmt.println()
	fmt.printfln("==> pipeline: %d passed, %d failed", rpasses, rfailures)
	if rfailures > 0 { os.exit(1) }
}

// Silence unused-import warning when this file is the only one referencing
// strings.
_ :: strings.builder_make
