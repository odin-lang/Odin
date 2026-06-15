// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_rsp_tests

// Spot-check N64 RSP encodings across scalar core, vector ALU, and
// vector load/store.
//
// Run with: odin run rsp/tests

import "core:fmt"
import "core:os"
import rsp "../"

@(private="file") passes := 0
@(private="file") failures := 0

check :: proc(name: string, m: rsp.Mnemonic, want_bits, want_mask: u32) {
	_run := rsp.ENCODE_RUNS[u16(m)]
	encs := rsp.ENCODE_FORMS[_run.start:][:_run.count]
	if len(encs) == 0 {
		fmt.printfln("  [FAIL] %s: no encoding", name)
		failures += 1
		return
	}
	e := encs[0]
	if e.bits != want_bits || e.mask != want_mask {
		fmt.printfln("  [FAIL] %s: got %08x/%08x want %08x/%08x",
					 name, e.bits, e.mask, want_bits, want_mask)
		failures += 1
		return
	}
	fmt.printfln("  [ok]   %-10s %08x / %08x (feature=%v)", name, e.bits, e.mask, e.feature)
	passes += 1
}

main :: proc() {
	fmt.println("=== N64 RSP encoding-table spot checks ===")

	// Scalar core
	check("ADD",  .ADD,  0x00000020, 0xFC0007FF)
	check("ADDU", .ADDU, 0x00000021, 0xFC0007FF)
	check("LW",   .LW,   0x8C000000, 0xFC000000)
	check("SW",   .SW,   0xAC000000, 0xFC000000)
	check("BEQ",  .BEQ,  0x10000000, 0xFC000000)
	check("J",    .J,    0x08000000, 0xFC000000)
	check("MFC0", .MFC0, 0x40000000, 0xFFE007FF)
	check("MFC2", .MFC2, 0x48000000, 0xFFE0007F)
	check("BREAK",.BREAK,0x0000000D, 0xFC00003F)
	check("NOP",  .NOP,  0x00000000, 0xFFFFFFFF)

	// Vector ALU
	check("VMULF",.VMULF,0x4A000000, 0xFE00003F)
	check("VMADH",.VMADH,0x4A00000F, 0xFE00003F)
	check("VADD", .VADD, 0x4A000010, 0xFE00003F)
	check("VSUB", .VSUB, 0x4A000011, 0xFE00003F)
	check("VLT",  .VLT,  0x4A000020, 0xFE00003F)
	check("VCH",  .VCH,  0x4A000025, 0xFE00003F)
	check("VAND", .VAND, 0x4A000028, 0xFE00003F)
	check("VRCP", .VRCP, 0x4A000030, 0xFE00003F)
	check("VMOV", .VMOV, 0x4A000033, 0xFE00003F)
	check("VRSQL",.VRSQL,0x4A000035, 0xFE00003F)
	check("VNOP", .VNOP, 0x4A000037, 0xFE00003F)

	// Vector loads
	check("LBV",  .LBV,  0xC8000000, 0xFC00F800)
	check("LQV",  .LQV,  0xC8002000, 0xFC00F800)
	check("LPV",  .LPV,  0xC8003000, 0xFC00F800)
	check("LTV",  .LTV,  0xC8005800, 0xFC00F800)

	// Vector stores
	check("SBV",  .SBV,  0xE8000000, 0xFC00F800)
	check("SQV",  .SQV,  0xE8002000, 0xFC00F800)
	check("STV",  .STV,  0xE8005800, 0xFC00F800)

	fmt.println()
	fmt.printfln("==> table: %d passed, %d failed", passes, failures)
	if failures > 0 { os.exit(1) }

	run_rsp_pipeline_tests()
}
