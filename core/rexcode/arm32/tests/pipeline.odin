package rexcode_arm32_tests

import "core:fmt"
import "core:os"
import a "../"

ok, fail: int

// =============================================================================
// Helpers
// =============================================================================

@(private="file")
check_bytes :: proc(name: string, inst: a.Instruction, want: []u8) {
	insts := []a.Instruction{inst}
	label_defs: [dynamic]a.Label_Definition
	code := make([]u8, 4)
	relocs: [dynamic]a.Relocation
	errors: [dynamic]a.Error
	defer { delete(label_defs); delete(code); delete(relocs); delete(errors) }

	res := a.encode(insts, label_defs[:], code, &relocs, &errors)
	if !res.success {
		fmt.printf("  [FAIL] %s: encode failed (errors=%d)\n", name, len(errors))
		fail += 1
		return
	}
	if int(res.byte_count) != len(want) {
		fmt.printf("  [FAIL] %s: got %d bytes, want %d\n", name, res.byte_count, len(want))
		fail += 1
		return
	}
	for k in 0..<len(want) {
		if code[k] != want[k] {
			fmt.printf("  [FAIL] %s: byte %d got %02x want %02x  (full got: ", name, k, code[k], want[k])
			for j in 0..<len(want) { fmt.printf("%02x ", code[j]) }
			fmt.println(")")
			fail += 1
			return
		}
	}
	fmt.printf("  [ok]   %-44s -> ", name)
	for k in 0..<len(want) { fmt.printf("%02x ", code[k]) }
	fmt.println()
	ok += 1
}

@(private="file")
check_decode :: proc(name: string, bytes: []u8, want_mn: a.Mnemonic, mode: a.Mode = .A32) {
	relocs := []a.Relocation{}
	insts: [dynamic]a.Instruction
	info:  [dynamic]a.Instruction_Info
	labels: [dynamic]a.Label_Definition
	errors: [dynamic]a.Error
	defer { delete(insts); delete(info); delete(labels); delete(errors) }
	res := a.decode(bytes, relocs, &insts, &info, &labels, &errors, mode)
	if !res.success || len(insts) == 0 {
		fmt.printf("  [FAIL] decode %s: success=%v len=%d\n", name, res.success, len(insts))
		fail += 1
		return
	}
	if insts[0].mnemonic != want_mn && !alias_equivalent(want_mn, insts[0].mnemonic) {
		fmt.printf("  [FAIL] decode %s: got %v want %v\n", name, insts[0].mnemonic, want_mn)
		fail += 1
		return
	}
	fmt.printf("  [ok]   decode %-40s -> %v\n", name, insts[0].mnemonic)
	ok += 1
}

@(private="file")
check_modimm_a32 :: proc(name: string, value: u32, want_field: u32, want_decoded: u32) {
	encoded, encoded_ok := a.encode_a32_modimm(value)
	if !encoded_ok {
		fmt.printf("  [FAIL] modimm a32 %s (0x%x): not encodable\n", name, value)
		fail += 1
		return
	}
	if encoded != want_field {
		fmt.printf("  [FAIL] modimm a32 %s: got field=0x%03x want 0x%03x\n", name, encoded, want_field)
		fail += 1
		return
	}
	dec := a.decode_a32_modimm(encoded)
	if dec != want_decoded {
		fmt.printf("  [FAIL] modimm a32 %s: decode got 0x%x want 0x%x\n", name, dec, want_decoded)
		fail += 1
		return
	}
	fmt.printf("  [ok]   modimm a32 %-32s 0x%08x <-> field 0x%03x\n", name, value, encoded)
	ok += 1
}

@(private="file")
check_modimm_t32 :: proc(name: string, value: u32) {
	f12, encoded_ok := a.encode_t32_modimm(value)
	if !encoded_ok {
		fmt.printf("  [FAIL] modimm t32 %s (0x%x): not encodable\n", name, value)
		fail += 1
		return
	}
	dec := a.decode_t32_modimm(f12)
	if dec != value {
		fmt.printf("  [FAIL] modimm t32 %s: encode 0x%x -> 0x%x but decode -> 0x%x\n", name, value, f12, dec)
		fail += 1
		return
	}
	fmt.printf("  [ok]   modimm t32 %-32s 0x%08x <-> field 0x%03x\n", name, value, f12)
	ok += 1
}

@(private="file")
check_neon_modimm :: proc(name: string, value: u32) {
	form, encoded_ok := a.encode_neon_modimm(value)
	if !encoded_ok {
		fmt.printf("  [FAIL] neon modimm %s (0x%x): not encodable\n", name, value)
		fail += 1
		return
	}
	dec := a.decode_neon_modimm(u32(form.abcdefgh), u32(form.cmode), u32(form.op))
	if dec != value {
		fmt.printf("  [FAIL] neon modimm %s: encode 0x%x -> (cmode=%d op=%d abcd=0x%02x) but decode -> 0x%x\n",
				   name, value, form.cmode, form.op, form.abcdefgh, dec)
		fail += 1
		return
	}
	fmt.printf("  [ok]   neon modimm %-30s 0x%08x cmode=%d op=%d abcd=0x%02x\n",
			   name, value, form.cmode, form.op, form.abcdefgh)
	ok += 1
}

@(private="file")
check_vfp_imm8 :: proc(name: string, value: u32) {
	e, encoded_ok := a.encode_vfp_imm8_f32(value)
	if !encoded_ok {
		fmt.printf("  [FAIL] vfp imm8 %s (0x%x): not encodable\n", name, value)
		fail += 1
		return
	}
	dec := a.decode_vfp_imm8_f32(u32(e))
	if dec != value {
		fmt.printf("  [FAIL] vfp imm8 %s: encode 0x%x -> 0x%02x but decode -> 0x%x\n",
				   name, value, e, dec)
		fail += 1
		return
	}
	fmt.printf("  [ok]   vfp imm8 %-32s 0x%08x <-> 0x%02x\n", name, value, e)
	ok += 1
}

@(private="file")
check_roundtrip :: proc(name: string, inst: a.Instruction) {
	// Encode -> decode -> verify the same mnemonic + operand kinds come back.
	insts := []a.Instruction{inst}
	label_defs: [dynamic]a.Label_Definition
	code := make([]u8, 8)
	relocs: [dynamic]a.Relocation
	errors: [dynamic]a.Error
	defer { delete(label_defs); delete(code); delete(relocs); delete(errors) }

	res := a.encode(insts, label_defs[:], code, &relocs, &errors)
	if !res.success {
		fmt.printf("  [FAIL] roundtrip %s: encode failed\n", name)
		fail += 1
		return
	}

	dec_relocs := []a.Relocation{}
	decoded: [dynamic]a.Instruction
	info:    [dynamic]a.Instruction_Info
	labels:  [dynamic]a.Label_Definition
	dec_err: [dynamic]a.Error
	defer { delete(decoded); delete(info); delete(labels); delete(dec_err) }

	dec_res := a.decode(code[:res.byte_count], dec_relocs, &decoded, &info, &labels, &dec_err, inst.mode)
	if !dec_res.success || len(decoded) == 0 {
		fmt.printf("  [FAIL] roundtrip %s: decode failed\n", name)
		fail += 1
		return
	}
	if decoded[0].mnemonic != inst.mnemonic {
		// Allow well-known ARM UAL aliases (MOV reg == LSL #0 etc.)
		if !alias_equivalent(inst.mnemonic, decoded[0].mnemonic) {
			fmt.printf("  [FAIL] roundtrip %s: got %v want %v\n", name, decoded[0].mnemonic, inst.mnemonic)
			fail += 1
			return
		}
	}
	if decoded[0].operand_count != inst.operand_count && !alias_equivalent(inst.mnemonic, decoded[0].mnemonic) {
		fmt.printf("  [FAIL] roundtrip %s: opcount %d want %d\n", name, decoded[0].operand_count, inst.operand_count)
		fail += 1
		return
	}
	fmt.printf("  [ok]   roundtrip %-37s -> %v\n", name, decoded[0].mnemonic)
	ok += 1
}

@(private="file")
alias_equivalent :: proc(want, got: a.Mnemonic) -> bool {
	// ARM UAL aliases: MOV Rd, Rm <=> LSL Rd, Rm, #0
	if want == .MOV && got == .LSL { return true }
	if want == .LSL && got == .MOV { return true }
	return false
}

// =============================================================================
// run_pipeline_tests
// =============================================================================

run_pipeline_tests :: proc() {
	fmt.println("==== arm32 ENCODE pipeline smoke ====")

	// ---- A32 data processing ----
	check_bytes("MOV r0, r1",
		a.inst_r_r(.MOV, a.R0, a.R1),
		[]u8{0x01, 0x00, 0xA0, 0xE1})

	check_bytes("ADD r0, r1, r2",
		a.inst_r_r_r(.ADD, a.R0, a.R1, a.R2),
		[]u8{0x02, 0x00, 0x81, 0xE0})

	check_bytes("SUB r3, r4, r5",
		a.inst_r_r_r(.SUB, a.R3, a.R4, a.R5),
		[]u8{0x05, 0x30, 0x44, 0xE0})

	check_bytes("ADDS r0, r1, r2",
		a.inst_set_flags(a.inst_r_r_r(.ADD, a.R0, a.R1, a.R2)),
		[]u8{0x02, 0x00, 0x91, 0xE0})

	check_bytes("MUL r0, r1, r2",
		a.inst_r_r_r(.MUL, a.R0, a.R1, a.R2),
		[]u8{0x91, 0x02, 0x00, 0xE0})

	// ---- A32 conditional execution ----
	check_bytes("ADDEQ r0, r1, r2",
		a.inst_set_cond(a.inst_r_r_r(.ADD, a.R0, a.R1, a.R2), 0),
		[]u8{0x02, 0x00, 0x81, 0x00})

	check_bytes("MOVNE r0, r1",
		a.inst_set_cond(a.inst_r_r(.MOV, a.R0, a.R1), 1),
		[]u8{0x01, 0x00, 0xA0, 0x11})

	// ---- A32 modified-immediate encoding round-trip ----
	fmt.println("\n==== A32 modified-immediate algorithm ====")
	check_modimm_a32("0x00",           0x00,         0x000, 0x00)
	check_modimm_a32("0xFF",           0xFF,         0x0FF, 0xFF)
	check_modimm_a32("0x100",          0x100,        0xC01, 0x100)         // rotate=12, value=1 → ROR(1,24)=0x100
	check_modimm_a32("0xFF00",         0xFF00,       0xCFF, 0xFF00)
	check_modimm_a32("0xFF000000",     0xFF000000,   0x4FF, 0xFF000000)
	check_modimm_a32("0x3FC",          0x3FC,        0xFFF, 0x3FC)         // 0xFF rotated by 30

	// ---- T32 modified-immediate ----
	fmt.println("\n==== T32 modified-immediate algorithm ====")
	check_modimm_t32("0x00",           0x00)
	check_modimm_t32("0xFF",           0xFF)
	check_modimm_t32("0x00120012",     0x00120012)
	check_modimm_t32("0x34003400",     0x34003400)
	check_modimm_t32("0x56565656",     0x56565656)
	check_modimm_t32("0x80000000",     0x80000000)
	check_modimm_t32("0x00018000",     0x00018000)

	// ---- NEON modified-immediate ----
	fmt.println("\n==== NEON modified-immediate algorithm ====")
	check_neon_modimm(".I8 0x7B",          0x7B7B7B7B)
	check_neon_modimm(".I16 0x00AB",       0x000000AB)
	check_neon_modimm(".I32 0x00DD0000",   0x00DD0000)
	check_neon_modimm(".I32 0xFF000000",   0xFF000000)

	// ---- VFP imm8 float encoding ----
	fmt.println("\n==== VFP imm8 float algorithm ====")
	// VFP F32 values that encode exactly: 1.0 = 0x3F800000, 2.0 = 0x40000000,
	// 0.5 = 0x3F000000, -1.0 = 0xBF800000
	check_vfp_imm8("F32 +1.0",  0x3F800000)
	check_vfp_imm8("F32 +2.0",  0x40000000)
	check_vfp_imm8("F32 +0.5",  0x3F000000)
	check_vfp_imm8("F32 -1.0",  0xBF800000)

	// ---- Decoder roundtrip ----
	fmt.println("\n==== Decoder round-trip ====")
	check_decode("MOV bytes",  []u8{0x01, 0x00, 0xA0, 0xE1}, .MOV)
	check_decode("ADD bytes",  []u8{0x02, 0x00, 0x81, 0xE0}, .ADD)
	check_decode("SUB bytes",  []u8{0x05, 0x30, 0x44, 0xE0}, .SUB)
	check_decode("MUL bytes",  []u8{0x91, 0x02, 0x00, 0xE0}, .MUL)

	// ---- Encode-decode roundtrip ----
	fmt.println("\n==== Encode/decode roundtrip ====")
	check_roundtrip("MOV r0, r1",      a.inst_r_r(.MOV, a.R0, a.R1))
	check_roundtrip("ADD r0, r1, r2",  a.inst_r_r_r(.ADD, a.R0, a.R1, a.R2))
	check_roundtrip("SUB r3, r4, r5",  a.inst_r_r_r(.SUB, a.R3, a.R4, a.R5))
	check_roundtrip("MUL r0, r1, r2",  a.inst_r_r_r(.MUL, a.R0, a.R1, a.R2))
	check_roundtrip("AND r0, r1, r2",  a.inst_r_r_r(.AND, a.R0, a.R1, a.R2))
	check_roundtrip("EOR r0, r1, r2",  a.inst_r_r_r(.EOR, a.R0, a.R1, a.R2))
	check_roundtrip("ORR r0, r1, r2",  a.inst_r_r_r(.ORR, a.R0, a.R1, a.R2))
	check_roundtrip("BIC r0, r1, r2",  a.inst_r_r_r(.BIC, a.R0, a.R1, a.R2))
	check_roundtrip("ADC r0, r1, r2",  a.inst_r_r_r(.ADC, a.R0, a.R1, a.R2))
	check_roundtrip("SBC r0, r1, r2",  a.inst_r_r_r(.SBC, a.R0, a.R1, a.R2))

	// ---- Memory addressing roundtrips ----
	fmt.println("\n==== Memory addressing roundtrips ====")
	check_roundtrip("LDR r0, [r1]",
		a.inst_load(.LDR, a.R0, a.mem_imm(a.R1, 0)))
	check_roundtrip("LDR r0, [r1, #4]",
		a.inst_load(.LDR, a.R0, a.mem_imm(a.R1, 4)))
	check_roundtrip("LDR r0, [r1, #-4]",
		a.inst_load(.LDR, a.R0, a.mem_imm(a.R1, -4)))
	check_roundtrip("STR r0, [r1, #16]",
		a.inst_store(.STR, a.R0, a.mem_imm(a.R1, 16)))
	check_roundtrip("LDRB r0, [r1]",
		a.inst_load(.LDRB, a.R0, a.mem_imm(a.R1, 0)))
	check_roundtrip("STRB r0, [r1, #8]",
		a.inst_store(.STRB, a.R0, a.mem_imm(a.R1, 8)))
	check_roundtrip("LDR r0, [r1, #4]! (pre-index)",
		a.inst_load(.LDR, a.R0, a.mem_imm_pre(a.R1, 4)))
	check_roundtrip("LDR r0, [r1], #4  (post-index)",
		a.inst_load(.LDR, a.R0, a.mem_imm_post(a.R1, 4)))
	check_roundtrip("STR r0, [r1, #-8]! (pre-index neg)",
		a.inst_store(.STR, a.R0, a.mem_imm_pre(a.R1, -8)))

	// ---- Modified-immediate full roundtrip ----
	fmt.println("\n==== Modified-immediate constants via encoder ====")
	// ADD r0, r1, #0x00FF0000 — should encode via modimm and decode back.
	check_roundtrip("ADD r0, r1, #0xFF",
		a.inst_r_r_i(.ADD, a.R0, a.R1, 0xFF))
	check_roundtrip("ADD r0, r1, #0xFF00",
		a.inst_r_r_i(.ADD, a.R0, a.R1, 0xFF00))
	check_roundtrip("ADD r0, r1, #0xFF000000",
		a.inst_r_r_i(.ADD, a.R0, a.R1, 0xFF000000))

	fmt.printf("\n==> arm32 pipeline: %d passed, %d failed\n", ok, fail)
	if fail > 0 { os.exit(1) }
}
