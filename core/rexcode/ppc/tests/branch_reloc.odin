// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ppc_tests

import "core:fmt"
import "core:os"
import p ".."
import "../../isa"

ok, fail: int

@(private="file")
check :: proc(name: string, instructions: []p.Instruction, label_defs: []isa.Label_Definition, want_bytes: []u8) {
	code := make([]u8, 64, context.temp_allocator)
	relocs: [dynamic]p.Relocation
	errors: [dynamic]p.Error
	defer delete(relocs); defer delete(errors)

	byte_count, success := p.encode(instructions, label_defs, code, &relocs, &errors)
	if !success {
		fmt.printf("  [FAIL] %s: encode failed, %d errors\n", name, len(errors))
		for e in errors { fmt.printf("           code=%v inst_idx=%d\n", e.code, e.inst_idx) }
		fail += 1
		return
	}
	if int(byte_count) != len(want_bytes) {
		fmt.printf("  [FAIL] %s: wrong byte count (got %d, want %d)\n", name, byte_count, len(want_bytes))
		fail += 1
		return
	}
	for i in 0..<len(want_bytes) {
		if code[i] != want_bytes[i] {
			fmt.printf("  [FAIL] %s: bytes differ at offset %d (got %02x want %02x)\n",
					   name, i, code[i], want_bytes[i])
			fmt.printf("           got  ")
			for j in 0..<len(want_bytes) { fmt.printf("%02x ", code[j]) }
			fmt.printf("\n           want ")
			for j in 0..<len(want_bytes) { fmt.printf("%02x ", want_bytes[j]) }
			fmt.printf("\n")
			fail += 1
			return
		}
	}
	fmt.printf("  [ok]   %s\n", name)
	ok += 1
}

run_branch_reloc :: proc() {
	fmt.println("==== ppc branch & relocation ====")

	// Test 1: forward unconditional branch
	// b L0    ; offset = 8 bytes
	// nop
	// L0:
	// blr
	// Expected: 48000008 60000000 4e800020
	{
		label_defs := [?]isa.Label_Definition{isa.Label_Definition(2)}  // points to instruction 2 (blr)
		instructions := [?]p.Instruction{
			p.inst_branch(.B, 0),
			p.inst_none(.NOP),
			p.inst_none(.BLR),
		}
		check("b L0; nop; L0: blr", instructions[:], label_defs[:],
			  {0x48, 0x00, 0x00, 0x08, 0x60, 0x00, 0x00, 0x00, 0x4E, 0x80, 0x00, 0x20})
	}

	// Test 2: Rc-bit (record bit / "." suffix)
	// add. r3, r4, r5  → 7C 64 2A 15
	{
		inst := p.inst_set_rc(p.inst_r_r_r(.ADD_DOT, p.R3, p.R4, p.R5))
		label_defs := []isa.Label_Definition{}
		check("add. r3,r4,r5", []p.Instruction{inst}, label_defs, {0x7C, 0x64, 0x2A, 0x15})
	}

	// Test 3: OE-bit (overflow / "o" suffix)
	// addo r3, r4, r5  → 7C 64 2E 14  (verified via llvm-mc)
	{
		inst := p.inst_r_r_r(.ADD_O, p.R3, p.R4, p.R5)
		label_defs := []isa.Label_Definition{}
		check("addo r3,r4,r5", []p.Instruction{inst}, label_defs, {0x7C, 0x64, 0x2E, 0x14})
	}

	// Test 4: backward branch
	// L0:
	// nop
	// b L0   ; offset = -4 bytes
	// Expected: 60000000 4BFFFFFC
	{
		label_defs := [?]isa.Label_Definition{isa.Label_Definition(0)}
		instructions := [?]p.Instruction{
			p.inst_none(.NOP),
			p.inst_branch(.B, 0),
		}
		check("L0: nop; b L0", instructions[:], label_defs[:],
			  {0x60, 0x00, 0x00, 0x00, 0x4B, 0xFF, 0xFF, 0xFC})
	}

	fmt.printf("\n==> branch tests: %d passed, %d failed\n", ok, fail)
	if fail > 0 { os.exit(1) }
}
