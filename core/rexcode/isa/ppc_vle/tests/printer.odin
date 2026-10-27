// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ppc_vle_tests

import "core:fmt"
import "core:os"
import "core:strings"
import v ".."
import "core:rexcode/isa"

check_print :: proc(name: string, inst: v.Instruction, want_text: string) {
	instructions := []v.Instruction{inst}
	info := []v.Instruction_Info{v.Instruction_Info{offset = 0, decode_entry = 0}}
	label_defs: []v.Label_Definition

	sb := strings.builder_make(context.temp_allocator)
	v.sbprint(&sb, instructions, info, label_defs, nil, nil)
	got := strings.trim_right(strings.to_string(sb), "\n ")
	want_trimmed := strings.trim_right(want_text, "\n ")
	if got != want_trimmed {
		fmt.printf("  [FAIL] %s\n           got  %q\n           want %q\n", name, got, want_trimmed)
		fail_count += 1
		return
	}
	fmt.printf("  [ok]   %-25s %q\n", name, got)
	ok_count += 1
}

run_printer :: proc() {
	fmt.println("==== ppc_vle printer ====")

	check_print("se_illegal", v.inst_none(.SE_ILLEGAL), "    se_illegal")
	check_print("se_isync",   v.inst_none(.SE_ISYNC),   "    se_isync")
	check_print("se_sc",      v.inst_none(.SE_SC),      "    se_sc")
	check_print("se_blr",     v.inst_none(.SE_BLR),     "    se_blr")

	// Print with custom operands
	check_print("se_neg r3",
		v.Instruction{mnemonic = .SE_NEG, ops = {v.op_reg(v.R3), {}, {}, {}},
					  operand_count = 1, length = 2, mode = .PPC32_VLE},
		"    se_neg r3")

	check_print("se_add r3, r4",
		v.Instruction{mnemonic = .SE_ADD, ops = {v.op_reg(v.R3), v.op_reg(v.R4), {}, {}},
					  operand_count = 2, length = 2, mode = .PPC32_VLE},
		"    se_add r3, r4")

	check_print("se_mr r24, r25",
		v.Instruction{mnemonic = .SE_MR, ops = {v.op_reg(v.R24), v.op_reg(v.R25), {}, {}},
					  operand_count = 2, length = 2, mode = .PPC32_VLE},
		"    se_mr r24, r25")

	fmt.printf("\n==> printer: %d passed, %d failed\n", ok_count, fail_count)
	if fail_count > 0 { os.exit(1) }
}
