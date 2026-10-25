// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_rsp_tests

// Operand range checks: every field is tested at both ends of its range
// (must encode) and one past each end (must fail with IMMEDIATE_OUT_OF_RANGE
// instead of being masked into a different instruction). Also covers the
// MTC2/MFC2 element field (bits 10-7).
//
// Scalar words were checked against GNU as (mips-linux-gnu-as -march=mips1).
// Vector words follow the RSP layouts in encoding_types.odin; MTC2/MFC2 follow
// the COP2 move layout, where libdragon's `mtc2 t0, $v01.e2` (byte element 4)
// assembles to 0x48880a00.

import "core:fmt"
import "core:os"
import rsp "../"

@(private="file") gpasses   := 0
@(private="file") gfailures := 0

@(private="file")
encode_single :: proc(inst: rsp.Instruction) -> (word: u32, ok: bool, errors: [dynamic]rsp.Error) {
	code:   [4]u8
	relocs: [dynamic]rsp.Relocation
	defer delete(relocs)
	insts := []rsp.Instruction{inst}
	_, ok = rsp.encode(insts, nil, code[:], &relocs, &errors)
	word = u32(code[0]) << 24 | u32(code[1]) << 16 | u32(code[2]) << 8 | u32(code[3])
	return
}

@(private="file")
accepts :: proc(name: string, inst: rsp.Instruction, want: u32) {
	word, ok, errors := encode_single(inst)
	defer delete(errors)
	if ok && len(errors) == 0 && word == want {
		fmt.printfln("  [ok]   %-34s %08x", name, word)
		gpasses += 1
	} else {
		fmt.printfln("  [FAIL] %-34s ok=%v errors=%d got=%08x want=%08x", name, ok, len(errors), word, want)
		gfailures += 1
	}
}

@(private="file")
rejects :: proc(name: string, inst: rsp.Instruction) {
	_, ok, errors := encode_single(inst)
	defer delete(errors)
	if !ok && len(errors) == 1 && errors[0].code == .IMMEDIATE_OUT_OF_RANGE && errors[0].inst_idx == 0 {
		fmt.printfln("  [ok]   %-34s rejected", name)
		gpasses += 1
	} else {
		code := len(errors) > 0 ? errors[0].code : .NONE
		fmt.printfln("  [FAIL] %-34s ok=%v errors=%d code=%v", name, ok, len(errors), code)
		gfailures += 1
	}
}

@(private="file")
r_r_i :: proc(m: rsp.Mnemonic, imm: i64) -> rsp.Instruction {
	return rsp.Instruction{mnemonic = m, operand_count = 3, length = 4,
		ops = {rsp.op_reg(rsp.T0), rsp.op_reg(rsp.T0), rsp.op_imm(imm, 2), {}}}
}

@(private="file")
lw_disp :: proc(disp: i32) -> rsp.Instruction {
	return rsp.Instruction{mnemonic = .LW, operand_count = 2, length = 4,
		ops = {rsp.op_reg(rsp.T0), rsp.op_mem(rsp.mem(rsp.SP, disp), 4), {}, {}}}
}

@(private="file")
vls :: proc(m: rsp.Mnemonic, element: u8, offset: i32) -> rsp.Instruction {
	return rsp.Instruction{mnemonic = m, operand_count = 2, length = 4,
		ops = {rsp.op_vr(rsp.VR1), rsp.op_vmem(rsp.vmem(rsp.T0, element, offset), 16), {}, {}}}
}

run_rsp_range_tests :: proc() {
	fmt.println()
	fmt.println("=== N64 RSP operand range checks ===")

	// Signed 16-bit immediates (addi/addiu/slti/sltiu): -32768..32767.
	accepts("addiu imm 32767",          r_r_i(.ADDIU,  32767), 0x25087FFF)
	accepts("addiu imm -32768",         r_r_i(.ADDIU, -32768), 0x25088000)
	rejects("addiu imm 32768",          r_r_i(.ADDIU,  32768))
	rejects("addiu imm -32769",         r_r_i(.ADDIU, -32769))
	rejects("addiu imm 0x12345",        r_r_i(.ADDIU, 0x12345))

	// Unsigned 16-bit immediates (andi/ori/xori/lui): 0..0xFFFF.
	accepts("ori imm 0xFFFF",           r_r_i(.ORI, 0xFFFF), 0x3508FFFF)
	accepts("ori imm 0",                r_r_i(.ORI, 0),      0x35080000)
	rejects("ori imm 0x10000",          r_r_i(.ORI, 0x10000))
	rejects("ori imm -1",               r_r_i(.ORI, -1))
	lui :: proc(imm: i64) -> rsp.Instruction {
		return rsp.Instruction{mnemonic = .LUI, operand_count = 2, length = 4,
			ops = {rsp.op_reg(rsp.T0), rsp.op_imm(imm, 2), {}, {}}}
	}
	accepts("lui imm 0xFFFF",           lui(0xFFFF), 0x3C08FFFF)
	rejects("lui imm 0x10000",          lui(0x10000))
	rejects("lui imm -1",               lui(-1))

	// Shift amounts: 0..31.
	sll :: proc(sa: i64) -> rsp.Instruction {
		return rsp.Instruction{mnemonic = .SLL, operand_count = 3, length = 4,
			ops = {rsp.op_reg(rsp.T0), rsp.op_reg(rsp.T0), rsp.op_imm(sa, 1), {}}}
	}
	accepts("sll sa 31",                sll(31), 0x000847C0)
	accepts("sll sa 0",                 sll(0),  0x00084000)
	rejects("sll sa 32",                sll(32))
	rejects("sll sa 33",                sll(33))
	rejects("sll sa -1",                sll(-1))

	// BREAK code: 0..0xFFFFF.
	brk :: proc(code: i64) -> rsp.Instruction {
		return rsp.Instruction{mnemonic = .BREAK, operand_count = 1, length = 4,
			ops = {rsp.op_imm(code, 4), {}, {}, {}}}
	}
	accepts("break 0xFFFFF",            brk(0xFFFFF), 0x03FFFFCD)
	rejects("break 0x100000",           brk(0x100000))
	rejects("break -1",                 brk(-1))

	// Scalar memory displacement: -32768..32767.
	accepts("lw disp 32767",            lw_disp( 32767), 0x8FA87FFF)
	accepts("lw disp -32768",           lw_disp(-32768), 0x8FA88000)
	rejects("lw disp 32768",            lw_disp( 32768))
	rejects("lw disp -32769",           lw_disp(-32769))

	// Vector L/S offset (in units of the access size): -64..63.
	accepts("lqv offset 63",            vls(.LQV, 0,  63), 0xC901203F)
	accepts("lqv offset -64",           vls(.LQV, 0, -64), 0xC9012040)
	rejects("lqv offset 64",            vls(.LQV, 0,  64))
	rejects("lqv offset -65",           vls(.LQV, 0, -65))
	rejects("sqv offset 64",            vls(.SQV, 0,  64))

	// Vector L/S element: 0..15.
	accepts("lsv element 15",           vls(.LSV, 15, 0), 0xC9010F80)
	rejects("lsv element 16",           vls(.LSV, 16, 0))
	rejects("lsv element 18",           vls(.LSV, 18, 1))

	// Vector ALU element: 0..15.
	accepts("vadd element 15",          rsp.inst_vadd(rsp.VR1, rsp.VR2, rsp.VR3, 15), 0x4BE31050)
	rejects("vadd element 16",          rsp.inst_vadd(rsp.VR1, rsp.VR2, rsp.VR3, 16))
	rejects("vadd element 17",          rsp.inst_vadd(rsp.VR1, rsp.VR2, rsp.VR3, 17))
	rejects("vmov element 16",          rsp.inst_vmov(rsp.VR1, rsp.VR3, 16))

	// MTC2/MFC2 element (bits 10-7): 0..15.
	accepts("mtc2 $t0, $v1 (no element)", rsp.inst_mtc2(rsp.T0, rsp.VR1),     0x48880800)
	accepts("mtc2 $t0, $v1[4]",         rsp.inst_mtc2(rsp.T0, rsp.VR1, 4),  0x48880A00)
	accepts("mtc2 $t0, $v1[15]",        rsp.inst_mtc2(rsp.T0, rsp.VR1, 15), 0x48880F80)
	accepts("mfc2 $t0, $v1[6]",         rsp.inst_mfc2(rsp.T0, rsp.VR1, 6),  0x48080B00)
	accepts("mfc2 $t0, $v31[0]",        rsp.inst_mfc2(rsp.T0, rsp.VR31, 0), 0x4808F800)
	rejects("mtc2 $t0, $v1[16]",        rsp.inst_mtc2(rsp.T0, rsp.VR1, 16))
	rejects("mfc2 $t0, $v1[16]",        rsp.inst_mfc2(rsp.T0, rsp.VR1, 16))

	// The failing instruction's index is reported, and nothing after it is
	// encoded.
	{
		code:   [8]u8
		relocs: [dynamic]rsp.Relocation
		errors: [dynamic]rsp.Error
		defer delete(relocs)
		defer delete(errors)
		insts := []rsp.Instruction{r_r_i(.ADDIU, 1), sll(32)}
		_, ok := rsp.encode(insts, nil, code[:], &relocs, &errors)
		if !ok && len(errors) == 1 && errors[0].inst_idx == 1 && errors[0].code == .IMMEDIATE_OUT_OF_RANGE {
			fmt.printfln("  [ok]   %-34s inst_idx=1", "error reports failing inst")
			gpasses += 1
		} else {
			fmt.printfln("  [FAIL] %-34s ok=%v errors=%v", "error reports failing inst", ok, errors[:])
			gfailures += 1
		}
	}

	// MTC2/MFC2 elements survive a decode.
	{
		code: [8]u8
		relocs: [dynamic]rsp.Relocation
		errors: [dynamic]rsp.Error
		defer delete(relocs)
		defer delete(errors)
		insts := []rsp.Instruction{rsp.inst_mtc2(rsp.T0, rsp.VR1, 4), rsp.inst_mfc2(rsp.T1, rsp.VR2, 6)}
		byte_count, eok := rsp.encode(insts, nil, code[:], &relocs, &errors)

		d_insts:  [dynamic]rsp.Instruction
		d_info:   [dynamic]rsp.Instruction_Info
		d_labels: [dynamic]rsp.Label_Definition
		defer delete(d_insts)
		defer delete(d_info)
		defer delete(d_labels)
		_, dok := rsp.decode(code[:byte_count], nil, &d_insts, &d_info, &d_labels, &errors)
		round_trip := eok && dok && len(d_insts) == 2 &&
			d_insts[0].mnemonic == .MTC2 && d_insts[0].ops[0].reg == rsp.T0 &&
			d_insts[0].ops[1].reg == rsp.VR1 && d_insts[0].ops[1].element == 4 &&
			d_insts[1].mnemonic == .MFC2 && d_insts[1].ops[0].reg == rsp.T1 &&
			d_insts[1].ops[1].reg == rsp.VR2 && d_insts[1].ops[1].element == 6
		if round_trip {
			fmt.printfln("  [ok]   %s", "mtc2/mfc2 element decode")
			gpasses += 1
		} else {
			fmt.printfln("  [FAIL] %s", "mtc2/mfc2 element decode")
			gfailures += 1
		}
	}

	fmt.println()
	fmt.printfln("==> ranges: %d passed, %d failed", gpasses, gfailures)
	if gfailures > 0 { os.exit(1) }
}
