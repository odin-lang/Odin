package rexcode_ppc_tests

import "core:fmt"
import "core:os"
import "core:strings"
import p ".."
import "../../isa"

p_ok, p_fail: int

check_print :: proc(name: string, inst: p.Instruction, want_text: string) {
	instructions := []p.Instruction{inst}
	info := []p.Instruction_Info{p.Instruction_Info{offset = 0, decode_entry = 0}}
	label_defs: []isa.Label_Definition

	sb := strings.builder_make(context.temp_allocator)
	p.sbprint(&sb, instructions, info, label_defs, nil, nil, nil)
	got := strings.trim_right(strings.to_string(sb), "\n ")
	want_trimmed := strings.trim_right(want_text, "\n ")
	if got != want_trimmed {
		fmt.printf("  [FAIL] %s\n           got  %q\n           want %q\n",
				   name, got, want_trimmed)
		p_fail += 1
		return
	}
	fmt.printf("  [ok]   %-30s %q\n", name, got)
	p_ok += 1
}

run_printer :: proc() {
	fmt.println("==== ppc printer ====")
	check_print("addi r3,r4,100", p.inst_r_r_i(.ADDI, p.R3, p.R4, 100), "    addi r3, r4, 100")
	check_print("add r3,r4,r5",   p.inst_r_r_r(.ADD,  p.R3, p.R4, p.R5),  "    add r3, r4, r5")
	check_print("or r3,r4,r5",    p.inst_r_r_r(.OR,   p.R3, p.R4, p.R5),  "    or r3, r4, r5")
	check_print("lwz r3,16(r4)",  p.inst_load(.LWZ, p.R3, p.mem_d(p.R4, 16)), "    lwz r3, 16(r4)")
	check_print("lwzx r3,r4,r5",  p.inst_load(.LWZX, p.R3, p.mem_x(p.R4, p.R5)), "    lwzx r3, r4, r5")
	check_print("blr",            p.inst_none(.BLR),                          "    blr")
	check_print("nop",            p.inst_none(.NOP),                          "    nop")

	fmt.printf("\n==> printer: %d passed, %d failed\n", p_ok, p_fail)
	if p_fail > 0 { os.exit(1) }
}
