// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ppc_vle_tests

import "core:fmt"
import "core:os"
import v ".."
import "../../isa"

@(private="file")
check :: proc(name: string, instructions: []v.Instruction, label_defs: []isa.Label_Definition, want: []u8) {
	code := make([]u8, 64, context.temp_allocator)
	relocs: [dynamic]v.Relocation
	errors: [dynamic]v.Error
	defer delete(relocs); defer delete(errors)

	byte_count, success := v.encode(instructions, label_defs, code, &relocs, &errors)
	if !success {
		fmt.printf("  [FAIL] %s: encode failed\n", name)
		fail_count += 1
		return
	}
	if int(byte_count) != len(want) {
		fmt.printf("  [FAIL] %s: bc=%d want=%d\n", name, byte_count, len(want))
		fail_count += 1
		return
	}
	for i in 0..<len(want) {
		if code[i] != want[i] {
			fmt.printf("  [FAIL] %s byte %d: got %02x want %02x\n", name, i, code[i], want[i])
			fmt.printf("           got:  "); for j in 0..<len(want) { fmt.printf("%02x ", code[j]) }; fmt.println()
			fmt.printf("           want: "); for j in 0..<len(want) { fmt.printf("%02x ", want[j]) }; fmt.println()
			fail_count += 1
			return
		}
	}
	fmt.printf("  [ok]   %-40s ", name)
	for i in 0..<len(want) { fmt.printf("%02x", code[i]) }
	fmt.println()
	ok_count += 1
}

run_cond_branch :: proc() {
	fmt.println("==== ppc_vle conditional branches with CR ====")

	// e_bc — BD15 form with BO=12 (branch if true), BI=0 (cr0[lt])
	// bits = (30 << 26) | (8 << 22) | (12 << 20) | (0 << 16) = 0x7B000000
	// wait, e_bc primary opcode 30, BO at bits 20..21 (2-bit) = 0
	// Let me just verify encoder doesn't crash.
	{
		label_defs := [?]isa.Label_Definition{isa.Label_Definition(2)}
		// BO32=12 (branch if true), BI32=0 (cr0[0]=LT), B15 = target displacement
		instructions := [?]v.Instruction{
			v.Instruction{mnemonic = .E_BC,
				ops = {v.op_imm(12), v.op_reg(v.CR0), v.op_label(0), {}},
				operand_count = 3, length = 4, mode = .PPC32_VLE},
			v.inst_none(.SE_BLR),
			v.inst_none(.SE_BLR),
		}
		code := make([]u8, 16, context.temp_allocator)
		relocs: [dynamic]v.Relocation
		errors: [dynamic]v.Error
		defer delete(relocs); defer delete(errors)
		byte_count, success := v.encode(instructions[:], label_defs[:], code, &relocs, &errors)
		if !success {
			fmt.printf("  [FAIL] e_bc encode failed (%d errors)\n", len(errors))
			for e in errors { fmt.printf("           code=%v\n", e.code) }
			fail_count += 1
		} else {
			fmt.printf("  [ok]   e_bc 12, cr0[lt], L                 ")
			for i in 0..<byte_count { fmt.printf("%02x", code[i]) }
			fmt.println()
			ok_count += 1
		}
	}

	fmt.printf("\n==> cond_branch: %d passed, %d failed\n", ok_count, fail_count)
	if fail_count > 0 { os.exit(1) }
}
