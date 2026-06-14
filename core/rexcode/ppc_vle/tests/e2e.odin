package rexcode_ppc_vle_tests

import "core:fmt"
import "core:os"
import "core:strings"
import v ".."
import "../../isa"

// End-to-end: encode → decode → print, verify bytes and that asm contains key tokens.
@(private="file")
check :: proc(name: string, instructions: []v.Instruction, label_defs: []isa.Label_Definition,
			  want_bytes: []u8, want_tokens: []string) {
	code := make([]u8, 64, context.temp_allocator)
	relocs: [dynamic]v.Relocation
	errors: [dynamic]v.Error
	defer delete(relocs); defer delete(errors)

	r := v.encode(instructions, label_defs, code, &relocs, &errors)
	if !r.success {
		fmt.printf("  [FAIL] %s: encode failed\n", name)
		fail_count += 1
		return
	}
	if int(r.byte_count) != len(want_bytes) {
		fmt.printf("  [FAIL] %s: byte_count=%d want=%d\n", name, r.byte_count, len(want_bytes))
		fail_count += 1
		return
	}
	for i in 0..<len(want_bytes) {
		if code[i] != want_bytes[i] {
			fmt.printf("  [FAIL] %s: bytes differ at %d (got=%02x want=%02x)\n", name, i, code[i], want_bytes[i])
			fmt.printf("           got: ")
			for j in 0..<len(want_bytes) { fmt.printf("%02x ", code[j]) }
			fmt.println()
			fail_count += 1
			return
		}
	}

	// Decode
	decoded:  [dynamic]v.Instruction
	info:     [dynamic]v.Instruction_Info
	dec_labs: [dynamic]v.Label_Definition
	dec_errs: [dynamic]v.Error
	defer delete(decoded); defer delete(info); defer delete(dec_labs); defer delete(dec_errs)
	dr := v.decode(code[:r.byte_count], relocs[:], &decoded, &info, &dec_labs, &dec_errs)
	if !dr.success {
		fmt.printf("  [FAIL] %s: decode failed\n", name)
		fail_count += 1
		return
	}

	// Print
	sb := strings.builder_make(context.temp_allocator)
	v.sbprint(&sb, decoded[:], info[:], dec_labs[:], nil, nil)
	asm_text := strings.to_string(sb)

	// Verify required tokens appear in output
	for tok in want_tokens {
		if !strings.contains(asm_text, tok) {
			fmt.printf("  [FAIL] %s: missing %q in output\n           output:\n%s\n", name, tok, asm_text)
			fail_count += 1
			return
		}
	}
	fmt.printf("  [ok]   %-35s %d bytes, %d insts\n", name, r.byte_count, len(decoded))
	ok_count += 1
}

run_e2e :: proc() {
	fmt.println("==== ppc_vle end-to-end test ====")

	// Test 1: simple sequence
	{
		instructions := [?]v.Instruction{
			v.inst_r_r(.SE_MR, v.R3, v.R4),
			v.inst_r(.SE_MTLR, v.R3),
			v.inst_none(.SE_BLR),
		}
		check("se_mr; se_mtlr; se_blr",
			instructions[:], nil,
			{0x01, 0x43, 0x00, 0x93, 0x00, 0x04},
			{"se_mr", "r3", "r4", "se_mtlr", "se_blr"})
	}

	// Test 2: forward branch + return
	{
		label_defs := [?]isa.Label_Definition{isa.Label_Definition(2)}
		instructions := [?]v.Instruction{
			v.inst_branch(.SE_B, 0),
			v.inst_none(.SE_BLR),
			v.inst_none(.SE_BLR),
		}
		check("se_b L; se_blr; L: se_blr",
			instructions[:], label_defs[:],
			{0xE8, 0x02, 0x00, 0x04, 0x00, 0x04},
			{"se_b", "se_blr"})
	}

	// Test 3: 32-bit unconditional branch (e_b)
	{
		label_defs := [?]isa.Label_Definition{isa.Label_Definition(2)}
		instructions := [?]v.Instruction{
			v.inst_branch(.E_B, 0),
			v.inst_none(.SE_BLR),
			v.inst_none(.SE_BLR),
		}
		check("e_b L; se_blr; L: se_blr",
			instructions[:], label_defs[:],
			{0x78, 0x00, 0x00, 0x06, 0x00, 0x04, 0x00, 0x04},
			{"e_b", "se_blr"})
	}

	// Test 4: load + return (uses SD4 form)
	{
		instructions := [?]v.Instruction{
			v.inst_load(.SE_LWZ, v.R3, v.mem_d(v.R4, 8)),
			v.inst_none(.SE_BLR),
		}
		// SD4(12) = 0xC000. SE_LWZ uses OFFSET_BASE_SD4_W: RX=4, SE_SDW=2 (=8/4).
		// bits = 0xC000 | (2 << 8) | 4 = 0xC204
		check("se_lwz r3, 8(r4); se_blr",
			instructions[:], nil,
			{0xC2, 0x34, 0x00, 0x04},
			{"se_lwz"})
	}

	// Test 5: backward branch (16-bit se_b to start of code)
	{
		label_defs := [?]isa.Label_Definition{isa.Label_Definition(0)}
		instructions := [?]v.Instruction{
			v.inst_none(.SE_BLR),       // L0:
			v.inst_branch(.SE_B, 0),    // se_b L0 — backward 2 bytes
		}
		check("L: se_blr; se_b L (backward)",
			instructions[:], label_defs[:],
			// se_blr = 00 04, se_b with B8 = -1 (= -2/2) → 0xFF byte
			{0x00, 0x04, 0xE8, 0xFF},
			{"se_blr", "se_b"})
	}

	// Test 6: 32-bit D-form load (e_lwz)
	{
		instructions := [?]v.Instruction{
			v.inst_load(.E_LWZ, v.R3, v.mem_d(v.R4, 16)),
			v.inst_none(.SE_BLR),
		}
		// e_lwz primary 20 = 0x50000000, RT=3 at bits 21..25, RA=4 at bits 16..20, D=16
		// bits = 0x50000000 | (3 << 21) | (4 << 16) | 16 = 0x50640010
		check("e_lwz r3, 16(r4); se_blr",
			instructions[:], nil,
			{0x50, 0x64, 0x00, 0x10, 0x00, 0x04},
			{"e_lwz"})
	}

	fmt.printf("\n==> e2e: %d passed, %d failed\n", ok_count, fail_count)
	if fail_count > 0 { os.exit(1) }
}
