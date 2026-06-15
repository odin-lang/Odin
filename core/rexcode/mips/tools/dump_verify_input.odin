// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package main

// =============================================================================
// MIPS verification manifest dumper
// =============================================================================
//
// Same shape as arm64's harness. Writes:
//   /tmp/rexcode_mips_input.hex  -- "0xAA,0xBB,0xCC,0xDD" per line, BE byte order
//   /tmp/rexcode_mips_meta.txt   -- "<mnemonic>\t<bits>\t<mask>\t<isa>"
//
// MIPS u32 instruction words go on the wire big-endian; llvm-mc's
// `-triple=mips` consumes hex bytes in that order, so we emit byte 3,2,1,0.
//
// Run:  cd mips && odin run tools/dump_verify_input.odin -file

import "core:fmt"
import "core:os"
import "core:strings"

import m "../"

main :: proc() {
	fmt.println("Dumping MIPS verification manifest...")

	hex_buf:  strings.Builder
	meta_buf: strings.Builder
	strings.builder_init(&hex_buf)
	strings.builder_init(&meta_buf)
	defer strings.builder_destroy(&hex_buf)
	defer strings.builder_destroy(&meta_buf)

	count := 0
	for mn in m.Mnemonic {
		_run := m.ENCODE_RUNS[u16(mn)]
		for f in m.ENCODE_FORMS[_run.start:][:_run.count] {
			b3 := u8((f.bits >> 24) & 0xFF)
			b2 := u8((f.bits >> 16) & 0xFF)
			b1 := u8((f.bits >>  8) & 0xFF)
			b0 := u8( f.bits        & 0xFF)
			// MIPS big-endian byte order: most-significant byte first
			fmt.sbprintf(&hex_buf, "0x%02x,0x%02x,0x%02x,0x%02x\n", b3, b2, b1, b0)
			fmt.sbprintf(&meta_buf, "%v\t%08x\t%08x\t%v\n", mn, f.bits, f.mask, f.feature)
			count += 1
		}
	}

	_ = os.write_entire_file("/tmp/rexcode_mips_input.hex", hex_buf.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_mips_meta.txt", meta_buf.buf[:])

	fmt.printf("Wrote %d entries.\n", count)
}
