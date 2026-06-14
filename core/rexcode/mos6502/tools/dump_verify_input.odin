package main

// =============================================================================
// MOS 6502 verification manifest dumper
// =============================================================================
//
// Iterates ENCODING_TABLE and emits a hex file with safe-filled bytes per
// entry, plus a parallel meta file (mnemonic name + CPU tier + length).
//
// Outputs:
//   /tmp/rexcode_mos6502.hex        bytes per line (1-7 bytes)
//   /tmp/rexcode_mos6502_meta.txt   parallel meta
//
// Run:  cd mos6502 && odin run tools/dump_verify_input.odin -file
//
// Verifier:  bash tools/verify_against_xa.sh /tmp/rexcode_mos6502.hex

import "core:fmt"
import "core:os"
import "core:strings"

import m ".."

main :: proc() {
	fmt.println("Dumping MOS 6502 verification manifest...")

	hex_buf, meta_buf: strings.Builder
	strings.builder_init(&hex_buf);  defer strings.builder_destroy(&hex_buf)
	strings.builder_init(&meta_buf); defer strings.builder_destroy(&meta_buf)

	n: int
	for mn in m.Mnemonic {
		for &f in m.ENCODING_TABLE[mn] {
			bytes: [7]u8
			bytes[0] = f.opcode
			// Safe-fill the operand bytes: byte1 = 0x42, byte2 = 0x12 (page 0x12, offset 0x42)
			for k in 1..<int(f.length) {
				bytes[k] = u8(0x42 + (k - 1) * 0x10)
			}
			for k in 0..<int(f.length) {
				if k > 0 { fmt.sbprint(&hex_buf, ",") }
				fmt.sbprintf(&hex_buf, "0x%02x", bytes[k])
			}
			fmt.sbprint(&hex_buf, "\n")
			fmt.sbprintf(&meta_buf, "%v\t%02X\t%v\t%v\n", mn, f.opcode, f.cpu, f.length)
			n += 1
		}
	}

	_ = os.write_entire_file("/tmp/rexcode_mos6502.hex",      hex_buf.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_mos6502_meta.txt", meta_buf.buf[:])

	fmt.printf("Wrote %d entries:\n", n)
	fmt.println("  /tmp/rexcode_mos6502.hex")
	fmt.println("  /tmp/rexcode_mos6502_meta.txt")
	fmt.println()
	fmt.println("Next:  bash tools/verify_against_xa.sh /tmp/rexcode_mos6502.hex")
}
