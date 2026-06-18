// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ppc_tests

import "core:fmt"
import "core:os"
import p ".."

ok_count, fail_count: int

@(private="file")
check :: proc(name: string, mn: p.Mnemonic, idx: int, want_bits, want_mask: u32) {
	_run := p.ENCODE_RUNS[u16(mn)]
	enc := p.ENCODE_FORMS[_run.start:][:_run.count]
	if idx >= len(enc) {
		fmt.printf("  [FAIL] %s: entry %d not present (have %d)\n", name, idx, len(enc))
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
	fmt.printf("  [ok]   %-22s %08x / %08x (mode=%v feat=%v)\n",
			   name, e.bits, e.mask, e.mode, e.feature)
	ok_count += 1
}

run_smoke :: proc() {
	fmt.println("==== ppc ENCODING_TABLE smoke test ====")

	// ---- Branch ----
	check("B",        .B,    0, 0x48000000, 0xFC000003)
	check("BL",       .BL,   0, 0x48000001, 0xFC000003)
	check("BA",       .BA,   0, 0x48000002, 0xFC000003)
	check("BLA",      .BLA,  0, 0x48000003, 0xFC000003)
	check("BC",       .BC,   0, 0x40000000, 0xFC000003)
	check("BCLR",     .BCLR, 0, 0x4C000020, 0xFC0007FF)
	check("BCCTR",    .BCCTR,0, 0x4C000420, 0xFC0007FF)
	check("SC",       .SC,   0, 0x44000002, 0xFFFFFFFD)

	fmt.printf("\n==> ppc table: %d passed, %d failed\n", ok_count, fail_count)
	if fail_count > 0 { os.exit(1) }
}

main :: proc() {
	run_decode_sweep()
	run_full_sweep()
	run_printer()
	run_roundtrip()
	run_smoke()
	run_branch_reloc()
}
