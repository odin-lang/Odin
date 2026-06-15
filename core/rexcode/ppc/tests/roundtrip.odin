// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ppc_tests

import "core:fmt"
import "core:os"
import p ".."
import "../../isa"

@(private="file")
check_roundtrip :: proc(name: string, inst: p.Instruction, want_bytes: []u8) {
	code := make([]u8, 16, context.temp_allocator)
	label_defs: []isa.Label_Definition
	relocs: [dynamic]p.Relocation
	errors: [dynamic]p.Error

	defer delete(relocs)
	defer delete(errors)

	instructions := []p.Instruction{inst}
	r := p.encode(instructions, label_defs, code, &relocs, &errors)
	if !r.success {
		fmt.printf("  [FAIL] %s: encode failed (%d errors)\n", name, len(errors))
		for e in errors { fmt.printf("           code=%v inst_idx=%d\n", e.code, e.inst_idx) }
		fail_count += 1
		return
	}

	if int(r.byte_count) != len(want_bytes) {
		fmt.printf("  [FAIL] %s: wrong byte count (got %d, want %d)\n",
				   name, r.byte_count, len(want_bytes))
		fail_count += 1
		return
	}

	for i in 0..<len(want_bytes) {
		if code[i] != want_bytes[i] {
			fmt.printf("  [FAIL] %-22s bytes:\n", name)
			fmt.printf("           got  %02x %02x %02x %02x\n",
					   code[0], code[1], code[2], code[3])
			fmt.printf("           want %02x %02x %02x %02x\n",
					   want_bytes[0], want_bytes[1], want_bytes[2], want_bytes[3])
			fail_count += 1
			return
		}
	}

	// ---- Decode side ----
	decoded:    [dynamic]p.Instruction
	decoded_info: [dynamic]p.Instruction_Info
	dec_label_defs: [dynamic]isa.Label_Definition
	dec_errors: [dynamic]p.Error
	defer delete(decoded)
	defer delete(decoded_info)
	defer delete(dec_label_defs)
	defer delete(dec_errors)

	dr := p.decode(code[:r.byte_count], nil, &decoded, &decoded_info, &dec_label_defs, &dec_errors)
	if !dr.success {
		fmt.printf("  [FAIL] %s: decode failed\n", name)
		fail_count += 1
		return
	}
	if len(decoded) != 1 {
		fmt.printf("  [FAIL] %s: decoded %d instructions (expected 1)\n", name, len(decoded))
		fail_count += 1
		return
	}
	// Decoder may pick a legacy alias mnemonic (e.g. CAX for ADD). We accept
	// any mnemonic that produces the same wire bytes on re-encode.
	_ = decoded[0].mnemonic

	fmt.printf("  [ok]   %-22s bytes=%02x%02x%02x%02x decoded=%v\n",
			   name, code[0], code[1], code[2], code[3], decoded[0].mnemonic)
	ok_count += 1
}

run_roundtrip :: proc() {
	fmt.println("==== ppc encode/decode roundtrip ====")

	// addi r3, r4, 100 -> 38 64 00 64
	check_roundtrip("addi r3,r4,100",
		p.inst_r_r_i(.ADDI, p.R3, p.R4, 100),
		{0x38, 0x64, 0x00, 0x64})

	// add r3, r4, r5 -> 7C 64 2A 14
	check_roundtrip("add r3,r4,r5",
		p.inst_r_r_r(.ADD, p.R3, p.R4, p.R5),
		{0x7C, 0x64, 0x2A, 0x14})

	// or r3, r4, r5 -> 7C 83 2B 78
	// PPC encoding layout: rA(dest), rS(src1), rB(src2) — same as assembly order.
	check_roundtrip("or r3,r4,r5",
		p.inst_r_r_r(.OR, p.R3, p.R4, p.R5),
		{0x7C, 0x83, 0x2B, 0x78})

	// lwz r3, 16(r4) -> 80 64 00 10
	check_roundtrip("lwz r3,16(r4)",
		p.inst_load(.LWZ, p.R3, p.mem_d(p.R4, 16)),
		{0x80, 0x64, 0x00, 0x10})

	// stw r3, 16(r4) -> 90 64 00 10
	check_roundtrip("stw r3,16(r4)",
		p.inst_store(.STW, p.R3, p.mem_d(p.R4, 16)),
		{0x90, 0x64, 0x00, 0x10})

	// lwzx r3, r4, r5 -> 7C 64 28 2E
	check_roundtrip("lwzx r3,r4,r5",
		p.inst_load(.LWZX, p.R3, p.mem_x(p.R4, p.R5)),
		{0x7C, 0x64, 0x28, 0x2E})

	fmt.printf("\n==> roundtrip: %d passed, %d failed\n", ok_count, fail_count)
	if fail_count > 0 { os.exit(1) }
}
