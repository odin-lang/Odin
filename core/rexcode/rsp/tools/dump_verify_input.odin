// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package main

// =============================================================================
// N64 RSP verification manifest dumper
// =============================================================================
//
// Iterates ENCODING_TABLE and emits three files:
//
//   /tmp/rexcode_rsp.hex        4-byte words per entry (BE)
//   /tmp/rexcode_rsp_meta.txt   parallel meta: mnemonic, bits, mask
//   /tmp/rexcode_rsp.asm        canonical armips RSP asm, one line per entry
//
// All operand fields are filled with `$0`/`$v0`/element-0/immediate-0 so
// the resulting encoded word equals our table's `bits` field exactly.
//
// Run:  cd rsp && odin run tools/dump_verify_input.odin -file
//
// Verifier:  bash tools/verify_against_armips.sh /tmp/rexcode_rsp.hex

import "core:fmt"
import "core:os"
import "core:reflect"
import "core:strings"

import r ".."

mnemonic_str :: proc(mn: r.Mnemonic) -> string {
	s, ok := reflect.enum_name_from_value(mn)
	if !ok { return "<?>" }
	return s
}

// Single-source vector ops (vmov/vrcp/vrcpl/vrcph/vrsq/vrsql/vrsqh) require
// armips to see EXPLICIT `[N]` element selectors on BOTH operands, and the
// parser maps `[0]` → encoded value 8 (RspScalarElement). So armips will
// emit bits = our_bits | (8<<21) | (8<<11), differing from our table.
// We mark these as "armips encoding offset" so the verifier can deduct.
needs_scalar_elem :: proc(mn: r.Mnemonic) -> bool {
	#partial switch mn {
	case .VMOV, .VRCP, .VRCPL, .VRCPH, .VRSQ, .VRSQL, .VRSQH:
		return true
	}
	return false
}

armips_lacks :: proc(mn: r.Mnemonic) -> bool {
	// Mnemonics the standard armips 0.11.0 doesn't recognise.
	// Upstream armips removed LWV (known broken RSP instruction), but we
	// build a patched armips at ~/.local/bin/armips-lwv that restores it.
	// The verifier prefers that binary when present, so we emit normal asm
	// here.
	_ = mn
	return false
}

write_operand :: proc(sb: ^strings.Builder, op: r.Operand_Type, mn: r.Mnemonic) {
	scalar_elem := needs_scalar_elem(mn)
	switch op {
	case .NONE:
	case .GPR:        strings.write_string(sb, "$0")
	case .VR:
		strings.write_string(sb, "$v0")
		if scalar_elem { strings.write_string(sb, "[0]") }
	case .VR_ELEM:
		strings.write_string(sb, "$v0")
		if scalar_elem { strings.write_string(sb, "[0]") }
	case .CP0_REG:    strings.write_string(sb, "$0")
	case .CP2_CTRL:   strings.write_string(sb, "$0")
	case .IMM5:       strings.write_string(sb, "0")
	case .IMM16S:     strings.write_string(sb, "0")
	case .IMM16U:     strings.write_string(sb, "0")
	case .IMM20:      strings.write_string(sb, "0")
	case .IMM26:      strings.write_string(sb, "0")
	case .REL16:      strings.write_string(sb, ".+4")    // offset = 0 in encoded word
	case .REL_J26:    strings.write_string(sb, "0")
	case .MEM:        strings.write_string(sb, "0($0)")
	case .VMEM:       strings.write_string(sb, "0($0)")
	}
}

main :: proc() {
	fmt.println("Dumping N64 RSP verification manifest...")

	hex_buf, meta_buf, asm_buf: strings.Builder
	strings.builder_init(&hex_buf);  defer strings.builder_destroy(&hex_buf)
	strings.builder_init(&meta_buf); defer strings.builder_destroy(&meta_buf)
	strings.builder_init(&asm_buf);  defer strings.builder_destroy(&asm_buf)

	strings.write_string(&asm_buf, ".rsp\n.resetdelay\n.create \"/tmp/rexcode_rsp.bin\", 0\n.headersize 0\n.org 0\n")

	n: int
	for mn in r.Mnemonic {
		_run := r.ENCODE_RUNS[u16(mn)]
		for &f in r.ENCODE_FORMS[_run.start:][:_run.count] {
			word := f.bits
			// Compute "armips-effective" expected bytes:
			// For single-source ops, armips's [0] yields element=8 in two fields.
			//   VMOV/VRCP family: source element field at bits 24-21 (value 8)
			//                     dest element field at bits 14-11 (value 8)
			// → adds (8<<21) | (8<<11) = 0x01004000
			arm_bits := word
			if needs_scalar_elem(mn) {
				arm_bits |= (8 << 21) | (8 << 11)
			}

			fmt.sbprintf(&hex_buf, "0x%02x,0x%02x,0x%02x,0x%02x\n",
				(arm_bits >> 24) & 0xFF, (arm_bits >> 16) & 0xFF,
				(arm_bits >>  8) & 0xFF,  arm_bits        & 0xFF)
			fmt.sbprintf(&meta_buf, "%v\t%08x\t%08x\n", mn, f.bits, f.mask)

			if armips_lacks(mn) {
				// Skip — armips doesn't recognise this mnemonic. Verifier
				// will detect the missing line and report as SKIPPED.
				strings.write_string(&asm_buf, "; ")  // comment out
			}
			// Build canonical asm
			mn_name := mnemonic_str(mn)
			for i in 0..<len(mn_name) {
				c := mn_name[i]
				if c >= 'A' && c <= 'Z' { c += 32 }
				strings.write_byte(&asm_buf, c)
			}
			// Operands. For the VRCP family our table has 3 vector regs but
			// armips's syntax (RdRm,RtRl) only takes 2 — skip the middle .VS.
			first := true
			scalar_elem := needs_scalar_elem(mn)
			for slot in 0..<4 {
				op := f.ops[slot]
				if op == .NONE { continue }
				if scalar_elem && op == .VR && slot == 1 {
					continue   // armips's vrcp doesn't take a vs operand
				}
				if first {
					strings.write_byte(&asm_buf, ' ')
					first = false
				} else {
					strings.write_byte(&asm_buf, ',')
				}
				write_operand(&asm_buf, op, mn)
			}
			strings.write_byte(&asm_buf, '\n')
			n += 1
		}
	}

	strings.write_string(&asm_buf, ".close\n")

	_ = os.write_entire_file("/tmp/rexcode_rsp.hex",      hex_buf.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_rsp_meta.txt", meta_buf.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_rsp.asm",      asm_buf.buf[:])

	fmt.printf("Wrote %d entries:\n", n)
	fmt.println("  /tmp/rexcode_rsp.hex")
	fmt.println("  /tmp/rexcode_rsp.asm")
	fmt.println("  /tmp/rexcode_rsp_meta.txt")
	fmt.println()
	fmt.println("Next:  bash tools/verify_against_armips.sh /tmp/rexcode_rsp.hex")
}
