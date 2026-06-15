// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package main

// =============================================================================
// PowerPC VLE verification manifest dumper
// =============================================================================
//
// Iterates ENCODING_TABLE and emits three files:
//
//   /tmp/rexcode_ppc_vle.hex        bytes per line (2 or 4, hex)
//   /tmp/rexcode_ppc_vle_meta.txt   parallel meta: mnemonic, bits, mask, ilen
//   /tmp/rexcode_ppc_vle.s          raw-bytes asm: .short / .long per entry
//
// The .s file leads with `.machine vle` + a single real `se_isync` so the
// linker sets the SHF_PPC_VLE section flag — then objdump -M vle will
// correctly decode every subsequent .short/.long as VLE.
//
// Run:  cd ppc_vle && odin run tools/dump_verify_input.odin -file
//
// Verifier:  bash tools/verify_against_vle_as.sh /tmp/rexcode_ppc_vle.hex

import "core:fmt"
import "core:os"
import "core:strings"

import v ".."

main :: proc() {
	fmt.println("Dumping PPC VLE verification manifest...")

	hex_buf, meta_buf, asm_buf: strings.Builder
	strings.builder_init(&hex_buf);  defer strings.builder_destroy(&hex_buf)
	strings.builder_init(&meta_buf); defer strings.builder_destroy(&meta_buf)
	strings.builder_init(&asm_buf);  defer strings.builder_destroy(&asm_buf)

	// Prologue: triggers SHF_PPC_VLE on .text so objdump decodes the
	// subsequent raw data as VLE instructions.
	strings.write_string(&asm_buf, ".section .text\n.machine vle\nse_isync\n")
	// Track the prologue byte count so the verifier can skip it when
	// matching against our expected hex.
	prologue_bytes := 2   // se_isync = 0x0001 (2 bytes)
	_ = prologue_bytes

	n: int
	for mn in v.Mnemonic {
		_run := v.ENCODE_RUNS[u16(mn)]
		for &f in v.ENCODE_FORMS[_run.start:][:_run.count] {
			word := f.bits
			if f.flags.short {
				fmt.sbprintf(&hex_buf, "0x%02x,0x%02x\n",
					(word >>  8) & 0xFF, word & 0xFF)
				fmt.sbprintf(&asm_buf, ".short 0x%04x\n", word & 0xFFFF)
			} else {
				fmt.sbprintf(&hex_buf, "0x%02x,0x%02x,0x%02x,0x%02x\n",
					(word >> 24) & 0xFF, (word >> 16) & 0xFF,
					(word >>  8) & 0xFF,  word        & 0xFF)
				fmt.sbprintf(&asm_buf, ".long 0x%08x\n", word)
			}
			ilen := 4 if !f.flags.short else 2
			fmt.sbprintf(&meta_buf, "%v\t%08x\t%08x\t%d\n", mn, f.bits, f.mask, ilen)
			n += 1
		}
	}

	_ = os.write_entire_file("/tmp/rexcode_ppc_vle.hex",      hex_buf.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_ppc_vle_meta.txt", meta_buf.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_ppc_vle.s",        asm_buf.buf[:])

	fmt.printf("Wrote %d entries:\n", n)
	fmt.println("  /tmp/rexcode_ppc_vle.hex")
	fmt.println("  /tmp/rexcode_ppc_vle.s")
	fmt.println("  /tmp/rexcode_ppc_vle_meta.txt")
	fmt.println()
	fmt.println("Next:  bash tools/verify_against_vle_as.sh /tmp/rexcode_ppc_vle.hex")
}
