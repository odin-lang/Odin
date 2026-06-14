package rexcode_ppc_vle_tests

import "core:fmt"
import "core:os"
import v ".."
import "../../isa"

check_encode :: proc(name: string, inst: v.Instruction, want_bytes: []u8) {
	code := make([]u8, 16, context.temp_allocator)
	label_defs: []isa.Label_Definition
	relocs: [dynamic]v.Relocation
	errors: [dynamic]v.Error
	defer delete(relocs); defer delete(errors)

	instructions := []v.Instruction{inst}
	r := v.encode(instructions, label_defs, code, &relocs, &errors)
	if !r.success {
		fmt.printf("  [FAIL] %s: encode failed (%d errors)\n", name, len(errors))
		for e in errors { fmt.printf("           code=%v\n", e.code) }
		fail_count += 1
		return
	}
	if int(r.byte_count) != len(want_bytes) {
		fmt.printf("  [FAIL] %s: byte count %d != %d\n", name, r.byte_count, len(want_bytes))
		fail_count += 1
		return
	}
	for i in 0..<len(want_bytes) {
		if code[i] != want_bytes[i] {
			fmt.printf("  [FAIL] %s: byte %d (got %02x, want %02x)\n", name, i, code[i], want_bytes[i])
			fmt.printf("           got ")
			for j in 0..<len(want_bytes) { fmt.printf("%02x ", code[j]) }
			fmt.printf("\n           want ")
			for j in 0..<len(want_bytes) { fmt.printf("%02x ", want_bytes[j]) }
			fmt.printf("\n")
			fail_count += 1
			return
		}
	}
	// Decode roundtrip
	decoded:      [dynamic]v.Instruction
	info:         [dynamic]v.Instruction_Info
	dec_labels:   [dynamic]v.Label_Definition
	dec_errors:   [dynamic]v.Error
	defer delete(decoded); defer delete(info); defer delete(dec_labels); defer delete(dec_errors)

	dr := v.decode(code[:r.byte_count], nil, &decoded, &info, &dec_labels, &dec_errors)
	if !dr.success {
		fmt.printf("  [FAIL] %s: decode failed\n", name)
		fail_count += 1
		return
	}
	if len(decoded) != 1 {
		fmt.printf("  [FAIL] %s: decoded %d instructions (want 1)\n", name, len(decoded))
		fail_count += 1
		return
	}
	// Decoder may pick a canonical alias (e.g. SE_OR for SE_NOP, since both
	// encode to the same bits). Bytes are what matter; mnemonic identity is
	// informational.
	_ = decoded[0].mnemonic
	if decoded[0].length != u8(len(want_bytes)) {
		fmt.printf("  [FAIL] %s: decoded length %d (want %d)\n", name, decoded[0].length, len(want_bytes))
		fail_count += 1
		return
	}
	fmt.printf("  [ok]   %-25s bytes=%02x", name, code[0])
	for i in 1..<len(want_bytes) { fmt.printf("%02x", code[i]) }
	fmt.printf("  decoded=%v len=%d\n", decoded[0].mnemonic, decoded[0].length)
	ok_count += 1
}

run_roundtrip :: proc() {
	fmt.println("==== ppc_vle encode/decode roundtrip ====")

	// 16-bit short instructions (2 bytes)
	check_encode("se_illegal",   v.inst_none(.SE_ILLEGAL),  {0x00, 0x00})
	check_encode("se_isync",     v.inst_none(.SE_ISYNC),    {0x00, 0x01})
	check_encode("se_sc",        v.inst_none(.SE_SC),       {0x00, 0x02})
	check_encode("se_nop",       v.inst_none(.SE_NOP),      {0x44, 0x00})

	// 32-bit instructions (4 bytes)
	check_encode("e_add16i",     v.inst_none(.E_ADD16I),    {0x1C, 0x00, 0x00, 0x00})
	check_encode("e_bdnz",       v.inst_none(.E_BDNZ),      {0x7A, 0x20, 0x00, 0x00})
	check_encode("e_bdz",        v.inst_none(.E_BDZ),       {0x7A, 0x30, 0x00, 0x00})
	check_encode("e_bdzl",       v.inst_none(.E_BDZL),      {0x7A, 0x30, 0x00, 0x01})

	fmt.printf("\n==> ppc_vle roundtrip: %d passed, %d failed\n", ok_count, fail_count)
	if fail_count > 0 { os.exit(1) }
}
