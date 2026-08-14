// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ppc_vle_tests

import "core:fmt"
import "core:os"
import v "../"

ok_count, fail_count: int

@(private="file")
check :: proc(name: string, mn: v.Mnemonic, idx: int, want_bits, want_mask: u32) {
	_run := v.ENCODE_RUNS[u16(mn)]
	enc := v.ENCODE_FORMS[_run.start:][:_run.count]
	if idx >= len(enc) {
		fmt.printf("  [FAIL] %s: no entry (have %d)\n", name, len(enc))
		fail_count += 1
		return
	}
	e := enc[idx]
	if e.bits != want_bits || e.mask != want_mask {
		fmt.printf("  [FAIL] %-22s got bits=%08x mask=%08x  want bits=%08x mask=%08x\n",
				   name, e.bits, e.mask, want_bits, want_mask)
		fail_count += 1
		return
	}
	fmt.printf("  [ok]   %-22s %08x / %08x feat=%v\n", name, e.bits, e.mask, e.feature)
	ok_count += 1
}

run_smoke :: proc() {
	fmt.println("==== ppc_vle ENCODING_TABLE smoke test ====")

	// 16-bit short instructions
	check("SE_ILLEGAL",  .SE_ILLEGAL,  0, 0x00000000, 0xFFFFFFFF)
	check("SE_ISYNC",  .SE_ISYNC,  0, 0x00000001, 0xFFFFFFFF)
	check("SE_NOP",  .SE_NOP,  0, 0x00004400, 0xFFFFFF00)

	// 32-bit
	check("E_ADD16I",  .E_ADD16I,  0, 0x1C000000, 0xFC000000)
	check("E_BDNZ",  .E_BDNZ,  0, 0x7A200000, 0xFFF00001)
	check("E_BDZ",  .E_BDZ,  0, 0x7A300000, 0xFFF00001)

	// Total count
	total := 0
	for mn in v.Mnemonic {
		_run := v.ENCODE_RUNS[u16(mn)]
		total += int(_run.count)
	}
	fmt.printf("\n[TOTAL entries] %d\n", total)
	fmt.printf("==> ppc_vle: %d passed, %d failed\n", ok_count, fail_count)
	if fail_count > 0 { os.exit(1) }
}

main :: proc() {
	run_cond_branch()
	run_e2e()
	run_extension()
	run_full_sweep()
	run_operand_test()
	run_printer()
	run_roundtrip()
	run_smoke()
	run_branch_test()
}
