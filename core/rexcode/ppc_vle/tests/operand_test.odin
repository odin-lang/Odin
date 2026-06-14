package rexcode_ppc_vle_tests

import "core:fmt"
import "core:os"
import v ".."
import "../../isa"

@(private="file")
check :: proc(name: string, inst: v.Instruction, want_bytes: []u8) {
	code := make([]u8, 16, context.temp_allocator)
	label_defs: []isa.Label_Definition
	relocs: [dynamic]v.Relocation
	errors: [dynamic]v.Error
	defer delete(relocs); defer delete(errors)

	instructions := []v.Instruction{inst}
	r := v.encode(instructions, label_defs, code, &relocs, &errors)
	if !r.success {
		fmt.printf("  [FAIL] %s: encode failed\n", name)
		fail_count += 1
		return
	}
	if int(r.byte_count) != len(want_bytes) {
		fmt.printf("  [FAIL] %s: byte_count=%d (want %d)\n", name, r.byte_count, len(want_bytes))
		fail_count += 1
		return
	}
	for i in 0..<len(want_bytes) {
		if code[i] != want_bytes[i] {
			fmt.printf("  [FAIL] %s\n           got  ", name)
			for j in 0..<len(want_bytes) { fmt.printf("%02x", code[j]) }
			fmt.printf("\n           want ")
			for j in 0..<len(want_bytes) { fmt.printf("%02x", want_bytes[j]) }
			fmt.println()
			fail_count += 1
			return
		}
	}
	fmt.printf("  [ok]   %-30s bytes=", name)
	for j in 0..<len(want_bytes) { fmt.printf("%02x", code[j]) }
	fmt.println()
	ok_count += 1
}

run_operand_test :: proc() {
	fmt.println("==== ppc_vle operand encoding ====")

	// se_neg r3 — SE_R form, RX=3 → SE_R(0, 3) | 3 = 0x33
	check("se_neg r3",
		v.Instruction{mnemonic = .SE_NEG, ops = {v.op_reg(v.R3), {}, {}, {}},
					  operand_count = 1, length = 2, mode = .PPC32_VLE,
					  form_id = 1},
		{0x00, 0x33})

	// se_add r3, r4 — SE_RR form, RX=3, RY=4 → SE_RR(1, 0) | (4 << 4) | 3 = 0x443
	check("se_add r3, r4",
		v.Instruction{mnemonic = .SE_ADD, ops = {v.op_reg(v.R3), v.op_reg(v.R4), {}, {}},
					  operand_count = 2, length = 2, mode = .PPC32_VLE,
					  form_id = 1},
		{0x04, 0x43})

	// se_mr r24, r25 — RX=24 → 8, RY=25 → 9 → 0x498
	check("se_mr r24, r25",
		v.Instruction{mnemonic = .SE_MR, ops = {v.op_reg(v.R24), v.op_reg(v.R25), {}, {}},
					  operand_count = 2, length = 2, mode = .PPC32_VLE,
					  form_id = 1},
		{0x01, 0x98})

	fmt.printf("\n==> operand_test: %d passed, %d failed\n", ok_count, fail_count)
	if fail_count > 0 { os.exit(1) }
}
