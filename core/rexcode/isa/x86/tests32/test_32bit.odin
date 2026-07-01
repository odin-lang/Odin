// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_x86_tests32

// Focused smoke tests for the i386 (Mode._32) encode/decode paths.
// Run from rexcode root with:   odin run x86/tests32

import "core:fmt"
import "core:os"
import x86 "../"

// Counts kept module-global for the summary.
@(private="file") passes := 0
@(private="file") failures := 0

bytes_equal :: proc(a, b: []u8) -> bool {
	if len(a) != len(b) { return false }
	for v, i in a {
		if v != b[i] { return false }
	}
	return true
}

expect_encode :: proc(name: string, insts: []x86.Instruction, want: []u8, mode: x86.Mode = ._32) {
	code: [64]u8
	relocs: [dynamic]x86.Relocation
	defer delete(relocs)
	errors: [dynamic]x86.Error
	defer delete(errors)

	res := x86.encode(insts, nil, code[:], &relocs, &errors, mode = mode)
	got := code[:res.byte_count]

	if !res.success {
		fmt.printfln("  [FAIL] %s: encode reported failure; errors=%v", name, errors[:])
		failures += 1
		return
	}
	if !bytes_equal(got, want) {
		fmt.printfln("  [FAIL] %s: got %x, want %x", name, got, want)
		failures += 1
		return
	}
	fmt.printfln("  [ok]   %s -> %x", name, got)
	passes += 1
}

expect_encode_fails :: proc(name: string, insts: []x86.Instruction, mode: x86.Mode = ._32) {
	code: [64]u8
	relocs: [dynamic]x86.Relocation
	defer delete(relocs)
	errors: [dynamic]x86.Error
	defer delete(errors)

	res := x86.encode(insts, nil, code[:], &relocs, &errors, mode = mode)
	if res.success {
		fmt.printfln("  [FAIL] %s: expected encode to fail but it succeeded with %x",
					 name, code[:res.byte_count])
		failures += 1
		return
	}
	fmt.printfln("  [ok]   %s rejected (errors=%v)", name, errors[:])
	passes += 1
}

expect_decode :: proc(name: string, bytes: []u8, want_mnemonic: x86.Mnemonic,
					 want_ops: int, want_reg0: x86.Register = x86.NONE, mode: x86.Mode = ._32) {
	insts: [dynamic]x86.Instruction
	defer delete(insts)
	info: [dynamic]x86.Instruction_Info
	defer delete(info)
	labels: [dynamic]x86.Label_Definition
	defer delete(labels)
	errors: [dynamic]x86.Error
	defer delete(errors)

	res := x86.decode(bytes, nil, &insts, &info, &labels, &errors, mode = mode)
	if !res.success || len(insts) == 0 {
		fmt.printfln("  [FAIL] %s: decode failed; errors=%v", name, errors[:])
		failures += 1
		return
	}
	got := insts[0]
	if got.mnemonic != want_mnemonic {
		fmt.printfln("  [FAIL] %s: got mnemonic %v, want %v", name, got.mnemonic, want_mnemonic)
		failures += 1
		return
	}
	if int(got.operand_count) != want_ops {
		fmt.printfln("  [FAIL] %s: got %d operands, want %d", name, got.operand_count, want_ops)
		failures += 1
		return
	}
	if want_reg0 != x86.NONE && got.ops[0].kind == .REGISTER && got.ops[0].reg != want_reg0 {
		fmt.printfln("  [FAIL] %s: got op0 reg %v, want %v", name, got.ops[0].reg, want_reg0)
		failures += 1
		return
	}
	fmt.printfln("  [ok]   %s -> %v (%d ops)", name, got.mnemonic, got.operand_count)
	passes += 1
}

main :: proc() {
	fmt.println("=== i386 (Mode._32) encode tests ===")

	// No REX, no force_rex_w: MOV EAX, EBX -> 89 D8
	expect_encode("MOV EAX, EBX",
		[]x86.Instruction{x86.inst_r_r(.MOV, x86.EAX, x86.EBX)},
		[]u8{0x89, 0xD8})

	// ADD EAX, imm32 -> 81 C0 2A 00 00 00. The encoder picks the
	// first matching form in ENCODING_TABLE, which is the imm32 form;
	// the shorter imm8sx form (83 /0 ib) would also be legal but is
	// listed later. Both are valid encodings of the same semantics.
	expect_encode("ADD EAX, 0x2A",
		[]x86.Instruction{x86.inst_r_i(.ADD, x86.EAX, 0x2A, 4)},
		[]u8{0x81, 0xC0, 0x2A, 0x00, 0x00, 0x00})

	// PUSH EAX short form -> 50
	expect_encode("PUSH EAX",
		[]x86.Instruction{x86.inst_r(.PUSH, x86.EAX)},
		[]u8{0x50})

	// RET -> C3
	expect_encode("RET",
		[]x86.Instruction{x86.inst_none(.RET)},
		[]u8{0xC3})

	// Short-form INC/DEC: 1-byte encoding in i386 (mode_32_only entries).
	expect_encode("INC EAX (short)",
		[]x86.Instruction{x86.inst_r(.INC, x86.EAX)},
		[]u8{0x40})
	expect_encode("DEC EDI (short)",
		[]x86.Instruction{x86.inst_r(.DEC, x86.EDI)},
		[]u8{0x4F})
	expect_encode("INC AX (short, 0x66)",
		[]x86.Instruction{x86.inst_r(.INC, x86.AX)},
		[]u8{0x66, 0x40})

	// 64-bit register in 32-bit mode: force_rex_w doesn't match any 32-bit
	// form; should fail to find an encoding (NO_MATCHING_ENCODING).
	expect_encode_fails("MOV RAX, RBX in _32",
		[]x86.Instruction{x86.inst_r_r(.MOV, x86.RAX, x86.RBX)})

	// R8D in 32-bit: GPR32 hw 8 forces REX.B -> rex != 0 -> OPERAND_MISMATCH
	expect_encode_fails("MOV EAX, R8D in _32",
		[]x86.Instruction{x86.inst_r_r(.MOV, x86.EAX, x86.R8D)})

	// SPL doesn't exist in i386 (encoding 4 in REG_GPR8 = AH there).
	// The pre-check rejects rather than silently encoding as MOV AH, AL.
	expect_encode_fails("MOV SPL, AL in _32",
		[]x86.Instruction{x86.inst_r_r(.MOV, x86.SPL, x86.AL)})

	// XMM8 doesn't exist in i386 (VEX.B would be required).
	expect_encode_fails("VMOVAPS XMM8, XMM0 in _32",
		[]x86.Instruction{x86.inst_r_r(.VMOVAPS, x86.XMM8, x86.XMM0)})

	// Memory with R8 as base: base_ext set, rejected pre-encoding.
	expect_encode_fails("MOV EAX, [R8] in _32",
		[]x86.Instruction{x86.inst_r_m(.MOV, x86.EAX, x86.mem_base_only(x86.R8), 4)})

	// AH-BH are fine in 32-bit (REG_GPR8H class, not REG_GPR8 hw 4-7).
	expect_encode("MOV AH, AL in _32",
		[]x86.Instruction{x86.inst_r_r(.MOV, x86.AH, x86.AL)},
		[]u8{0x88, 0xC4})

	fmt.println()
	fmt.println("=== i386 (Mode._32) decode tests ===")

	// Short-form INC EAX: 0x40 (REX in long mode, INC EAX in i386).
	expect_decode("0x40 -> INC EAX", []u8{0x40}, .INC, 1, x86.EAX)

	// Short-form DEC EDI: 0x4F.
	expect_decode("0x4F -> DEC EDI", []u8{0x4F}, .DEC, 1, x86.EDI)

	// 0x66 0x40 -> INC AX (16-bit operand).
	expect_decode("66 40 -> INC AX", []u8{0x66, 0x40}, .INC, 1, x86.AX)

	// MOV EAX, EBX = 89 D8 (no REX needed; same bytes work in both modes).
	expect_decode("89 D8 -> MOV EAX, EBX", []u8{0x89, 0xD8}, .MOV, 2, x86.EAX)

	// PUSH EAX short form 0x50.
	expect_decode("0x50 -> PUSH EAX", []u8{0x50}, .PUSH, 1, x86.EAX)

	// Round trip an integer kernel: MOV EAX, EBX; ADD EAX, 0x2A; INC ECX; RET
	fmt.println()
	fmt.println("=== round-trip test ===")
	{
		insts := []x86.Instruction{
			x86.inst_r_r(.MOV, x86.EAX, x86.EBX),
			x86.inst_r_i(.ADD, x86.EAX, 0x2A, 4),
			x86.inst_r(.INC, x86.ECX),     // encodes as long-form FF C1 (no short form in table)
			x86.inst_none(.RET),
		}
		code: [64]u8
		relocs: [dynamic]x86.Relocation
		defer delete(relocs)
		errors: [dynamic]x86.Error
		defer delete(errors)
		enc_res := x86.encode(insts, nil, code[:], &relocs, &errors, mode = ._32)
		fmt.printfln("  encoded %d bytes: %x (success=%v)", enc_res.byte_count, code[:enc_res.byte_count], enc_res.success)

		decoded: [dynamic]x86.Instruction
		defer delete(decoded)
		info: [dynamic]x86.Instruction_Info
		defer delete(info)
		labels: [dynamic]x86.Label_Definition
		defer delete(labels)
		derrors: [dynamic]x86.Error
		defer delete(derrors)
		dec_res := x86.decode(code[:enc_res.byte_count], nil, &decoded, &info, &labels, &derrors, mode = ._32)

		ok := dec_res.success && len(decoded) == len(insts)
		for d, i in decoded {
			if i >= len(insts) { break }
			if d.mnemonic != insts[i].mnemonic {
				ok = false
				break
			}
		}
		if ok {
			fmt.printfln("  [ok]   round-tripped %d instructions", len(decoded))
			passes += 1
		} else {
			fmt.printfln("  [FAIL] mnemonic mismatch on round-trip")
			for d, i in decoded {
				fmt.printfln("           [%d] decoded=%v", i, d.mnemonic)
			}
			failures += 1
		}
	}

	fmt.println()
	fmt.printfln("==> %d passed, %d failed", passes, failures)
	if failures > 0 { os.exit(1) }
}
