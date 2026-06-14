package main

// =============================================================================
// AArch64 verification manifest dumper
// =============================================================================
//
// Iterates ENCODING_TABLE and writes:
//   /tmp/rexcode_aarch64_input.hex   -- "0xAA,0xBB,0xCC,0xDD" per line, LE order
//   /tmp/rexcode_aarch64_meta.txt    -- "<mnemonic>\t<bits>\t<mask>\t<feature>"
//
// The hex file is piped to:
//   llvm-mc --disassemble -triple=aarch64 -mattr=+all
//
// Then verify_against_llvm.odin reads meta + llvm output and reports mismatches.
//
// Run:  cd arm64 && odin run tools/dump_verify_input.odin -file

import "core:fmt"
import "core:os"
import "core:strings"

import a "../"

main :: proc() {
	fmt.println("Dumping AArch64 verification manifest...")

	hex_buf:  strings.Builder
	meta_buf: strings.Builder
	strings.builder_init(&hex_buf)
	strings.builder_init(&meta_buf)
	defer strings.builder_destroy(&hex_buf)
	defer strings.builder_destroy(&meta_buf)

	count := 0
	for mn in a.Mnemonic {
		for f in a.ENCODING_TABLE[mn] {
			b0 := u8( f.bits        & 0xFF)
			b1 := u8((f.bits >>  8) & 0xFF)
			b2 := u8((f.bits >> 16) & 0xFF)
			b3 := u8((f.bits >> 24) & 0xFF)
			fmt.sbprintf(&hex_buf, "0x%02x,0x%02x,0x%02x,0x%02x\n", b0, b1, b2, b3)
			fmt.sbprintf(&meta_buf, "%v\t%08x\t%08x\t%v\n", mn, f.bits, f.mask, f.feature)
			count += 1
		}
	}

	_ = os.write_entire_file("/tmp/rexcode_aarch64_input.hex", hex_buf.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_aarch64_meta.txt", meta_buf.buf[:])

	fmt.printf("Wrote %d entries:\n", count)
	fmt.println("  /tmp/rexcode_aarch64_input.hex")
	fmt.println("  /tmp/rexcode_aarch64_meta.txt")
	fmt.println()
	fmt.println("Next step:")
	fmt.println("  llvm-mc --disassemble -triple=aarch64 -mattr=+all \\")
	fmt.println("      < /tmp/rexcode_aarch64_input.hex \\")
	fmt.println("      > /tmp/rexcode_aarch64_llvm.txt 2>&1")
	fmt.println("Then:")
	fmt.println("  cd arm64 && odin run tools/verify_against_llvm.odin -file")
}
