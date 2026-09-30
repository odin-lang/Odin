// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package main

// =============================================================================
// RISC-V verification manifest dumper
// =============================================================================
//
// Writes:
//   /tmp/rexcode_riscv_input.hex  -- LE hex bytes per row (2 or 4 bytes)
//   /tmp/rexcode_riscv_meta.txt   -- "<mnemonic>\t<bits>\t<mask>\t<ext>\t<size>"
//
// Compressed (RVC) instructions take 2 bytes; everything else takes 4.
//
// Run:  cd isa/riscv && odin run tools/dump_verify_input.odin -file

import "core:fmt"
import "core:os"
import "core:strings"

import r "../"

main :: proc() {
	fmt.println("Dumping RISC-V verification manifest...")

	hex_buf, meta_buf: strings.Builder
	strings.builder_init(&hex_buf)
	strings.builder_init(&meta_buf)
	defer strings.builder_destroy(&hex_buf)
	defer strings.builder_destroy(&meta_buf)

	count := 0
	for mn in r.Mnemonic {
		_run := r.ENCODE_RUNS[u16(mn)]
		for f in r.ENCODE_FORMS[_run.start:][:_run.count] {
			size := r.inst_size_from_bits(f.bits)
			b0 := u8( f.bits        & 0xFF)
			b1 := u8((f.bits >>  8) & 0xFF)
			if size == 2 {
				fmt.sbprintf(&hex_buf, "0x%02x,0x%02x\n", b0, b1)
			} else {
				b2 := u8((f.bits >> 16) & 0xFF)
				b3 := u8((f.bits >> 24) & 0xFF)
				fmt.sbprintf(&hex_buf, "0x%02x,0x%02x,0x%02x,0x%02x\n", b0, b1, b2, b3)
			}
			fmt.sbprintf(&meta_buf, "%v\t%08x\t%08x\t%v\t%d\n",
						 mn, f.bits, f.mask, f.feature, size)
			count += 1
		}
	}

	_ = os.write_entire_file("/tmp/rexcode_riscv_input.hex", hex_buf.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_riscv_meta.txt", meta_buf.buf[:])

	fmt.printf("Wrote %d entries.\n", count)
}
