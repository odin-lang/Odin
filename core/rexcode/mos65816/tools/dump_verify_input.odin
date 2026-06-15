// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package main

// =============================================================================
// W65C816 verification manifest dumper
// =============================================================================
//
// Iterates ENCODING_TABLE and emits THREE parallel files:
//
//   /tmp/rexcode_mos65816.hex   bytes per line (1-4 bytes, hex)
//   /tmp/rexcode_mos65816.s     canonical ca65 asm, one line per entry
//   /tmp/rexcode_mos65816_meta.txt   parallel meta: mn opcode length
//
// The .s file leads with `.setcpu "65816"`, then for each entry emits any
// needed `.a8/.a16/.i8/.i16` directive followed by the asm line. The
// verifier assembles this through ca65 with --listing and compares the
// listing's per-line bytes against our table.
//
// Run:  cd mos65816 && odin run tools/dump_verify_input.odin -file

import "core:fmt"
import "core:os"
import "core:reflect"
import "core:strings"

import m ".."

mnemonic_str :: proc(mn: m.Mnemonic) -> string {
	s, ok := reflect.enum_name_from_value(mn)
	if !ok { return "<?>" }
	return s
}

// Safe-fill convention matches the .hex dumper exactly:
//   byte[1] = 0x42, byte[2] = 0x52, byte[3] = 0x62
// So the values we pass to ca65 must be such that ca65 emits these very
// bytes in LE order at the right offsets.
DP_VAL    :: 0x42       // byte[1]
WORD_VAL  :: 0x5242     // byte[1]=42  byte[2]=52  (LE)
LONG_VAL  :: 0x625242   // byte[1]=42  byte[2]=52  byte[3]=62
IMM_VAL   :: 0x42
IMM16_VAL :: 0x5242

// PC-relative offsets — ca65 encodes (target - (PC + instr_len)).
// For an 8-bit branch we want byte[1] = 0x42 → target = PC + 2 + 0x42 = * + $44.
// For a 16-bit BRL/PER we want bytes[1..2] = 0x42, 0x52 (LE value 0x5242)
//   → target = PC + 3 + 0x5242 = * + $5245.
REL_TARGET     :: "* + $44"
REL_LONG_TGT   :: "* + $5245"

operand_asm :: proc(sb: ^strings.Builder, op: m.Operand_Type) {
	switch op {
	case .NONE:
	case .A_IMPL:           strings.write_string(sb, "a")
	case .IMM_8:            fmt.sbprintf(sb, "#$%02X", IMM_VAL)
	case .IMM_M8, .IMM_X8:  fmt.sbprintf(sb, "#$%02X", IMM_VAL)
	case .IMM_M16, .IMM_X16: fmt.sbprintf(sb, "#$%04X", IMM16_VAL)
	case .REL:              strings.write_string(sb, REL_TARGET)
	case .REL_LONG:         strings.write_string(sb, REL_LONG_TGT)
	case .MEM_DP:           fmt.sbprintf(sb, "$%02X",   DP_VAL)
	case .MEM_DP_X:         fmt.sbprintf(sb, "$%02X,x", DP_VAL)
	case .MEM_DP_Y:         fmt.sbprintf(sb, "$%02X,y", DP_VAL)
	case .MEM_DP_IND:       fmt.sbprintf(sb, "($%02X)", DP_VAL)
	case .MEM_DP_IND_X:     fmt.sbprintf(sb, "($%02X,x)", DP_VAL)
	case .MEM_DP_IND_Y:     fmt.sbprintf(sb, "($%02X),y", DP_VAL)
	case .MEM_DP_IND_LONG:  fmt.sbprintf(sb, "[$%02X]",  DP_VAL)
	case .MEM_DP_IND_LONG_Y: fmt.sbprintf(sb, "[$%02X],y", DP_VAL)
	case .MEM_ABS:          fmt.sbprintf(sb, "$%04X",   WORD_VAL)
	case .MEM_ABS_X:        fmt.sbprintf(sb, "$%04X,x", WORD_VAL)
	case .MEM_ABS_Y:        fmt.sbprintf(sb, "$%04X,y", WORD_VAL)
	case .MEM_ABS_IND:      fmt.sbprintf(sb, "($%04X)", WORD_VAL)
	case .MEM_ABS_IND_LONG: fmt.sbprintf(sb, "[$%04X]", WORD_VAL)
	case .MEM_ABS_IND_X:    fmt.sbprintf(sb, "($%04X,x)", WORD_VAL)
	case .MEM_LONG:         fmt.sbprintf(sb, "$%06X",   LONG_VAL)
	case .MEM_LONG_X:       fmt.sbprintf(sb, "$%06X,x", LONG_VAL)
	case .MEM_SR:           fmt.sbprintf(sb, "$%02X,s", DP_VAL)
	case .MEM_SR_IND_Y:     fmt.sbprintf(sb, "($%02X,s),y", DP_VAL)
	case .BANK_SRC:         fmt.sbprintf(sb, "#$%02X", 0x52)  // byte[2]
	case .BANK_DST:         fmt.sbprintf(sb, "#$%02X", 0x42)  // byte[1]
	}
}

main :: proc() {
	fmt.println("Dumping W65C816 verification manifest...")

	hex_buf, meta_buf, asm_buf: strings.Builder
	strings.builder_init(&hex_buf);  defer strings.builder_destroy(&hex_buf)
	strings.builder_init(&meta_buf); defer strings.builder_destroy(&meta_buf)
	strings.builder_init(&asm_buf);  defer strings.builder_destroy(&asm_buf)

	strings.write_string(&asm_buf, ".setcpu \"65816\"\n.smart -\n.feature force_range\n.org $000000\n")

	cur_a := -1  // -1 = unknown, 0 = .a16, 1 = .a8
	cur_x := -1

	n: int
	for mn in m.Mnemonic {
		_run := m.ENCODE_RUNS[u16(mn)]
		for &f in m.ENCODE_FORMS[_run.start:][:_run.count] {
			// --- bytes ---
			bytes: [4]u8
			bytes[0] = f.opcode
			for k in 1..<int(f.length) {
				bytes[k] = u8(0x42 + (k - 1) * 0x10)
			}
			for k in 0..<int(f.length) {
				if k > 0 { fmt.sbprint(&hex_buf, ",") }
				fmt.sbprintf(&hex_buf, "0x%02x", bytes[k])
			}
			fmt.sbprint(&hex_buf, "\n")

			// --- meta ---
			fmt.sbprintf(&meta_buf, "%v\t%02X\t%v\n", mn, f.opcode, f.length)

			// --- asm ---
			// Pick A/X width from operand types
			need_a8 := false; need_a16 := false
			need_x8 := false; need_x16 := false
			for op in f.ops {
				#partial switch op {
				case .IMM_M8:  need_a8  = true
				case .IMM_M16: need_a16 = true
				case .IMM_X8:  need_x8  = true
				case .IMM_X16: need_x16 = true
				}
			}
			if need_a8 && cur_a != 1 {
				strings.write_string(&asm_buf, ".a8\n");  cur_a = 1
			} else if need_a16 && cur_a != 0 {
				strings.write_string(&asm_buf, ".a16\n"); cur_a = 0
			}
			if need_x8 && cur_x != 1 {
				strings.write_string(&asm_buf, ".i8\n");  cur_x = 1
			} else if need_x16 && cur_x != 0 {
				strings.write_string(&asm_buf, ".i16\n"); cur_x = 0
			}

			mn_str := mnemonic_str(mn)
			// ca65 reserves `BIT` style — emit lowercase mnemonic
			mn_lower: [16]u8
			ln := 0
			for i := 0; i < len(mn_str) && i < 16; i += 1 {
				c := mn_str[i]
				if c >= 'A' && c <= 'Z' { c += 32 }
				mn_lower[ln] = c
				ln += 1
			}
			strings.write_bytes(&asm_buf, mn_lower[:ln])

			// BRK/COP/WDM use the signature-byte form (no `#`):
			sig_byte_form := mn == .BRK || mn == .COP || mn == .WDM

			// Block-move (MVN/MVP) has 2 BANK operands but ca65 syntax
			// is `mvn src, dst` -- we just emit the two as bytes.
			has_op := false
			for slot in 0..<2 {
				if f.ops[slot] != .NONE {
					if !has_op {
						strings.write_byte(&asm_buf, ' ')
						has_op = true
					} else {
						strings.write_byte(&asm_buf, ',')
					}
					if sig_byte_form && f.ops[slot] == .IMM_8 {
						fmt.sbprintf(&asm_buf, "$%02X", IMM_VAL)
					} else {
						operand_asm(&asm_buf, f.ops[slot])
					}
				}
			}
			strings.write_byte(&asm_buf, '\n')
			n += 1
		}
	}

	_ = os.write_entire_file("/tmp/rexcode_mos65816.hex",      hex_buf.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_mos65816_meta.txt", meta_buf.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_mos65816.s",        asm_buf.buf[:])

	fmt.printf("Wrote %d entries:\n", n)
	fmt.println("  /tmp/rexcode_mos65816.hex")
	fmt.println("  /tmp/rexcode_mos65816.s")
	fmt.println("  /tmp/rexcode_mos65816_meta.txt")
	fmt.println()
	fmt.println("Next:  bash tools/verify_against_ca65.sh /tmp/rexcode_mos65816.hex")
}
