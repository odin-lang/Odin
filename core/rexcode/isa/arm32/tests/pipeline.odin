// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm32_tests

import "core:fmt"
import "core:strings"
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

	byte_count, success := a.encode(insts, label_defs[:], code, &relocs, &errors)
	if !success {
		fmt.printf("  [FAIL] %s: encode failed (errors=%d)\n", name, len(errors))
		fail += 1
		return
	}
	if int(byte_count) != len(want) {
		fmt.printf("  [FAIL] %s: got %d bytes, want %d\n", name, byte_count, len(want))
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
	byte_count, success := a.decode(bytes, relocs, &insts, &info, &labels, &errors, mode)
	if !success || len(insts) == 0 {
		fmt.printf("  [FAIL] decode %s: success=%v len=%d\n", name, success, len(insts))
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
	// An .i8 decodes to its byte, which is what every element gets.
	want := u64(value)
	if form.cmode == 0b1110 && form.op == 0 {
		want = u64(value & 0xFF)
	}
	if dec != want {
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

	byte_count, success := a.encode(insts, label_defs[:], code, &relocs, &errors)
	if !success {
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

	dec_byte_count, dec_success := a.decode(code[:byte_count], dec_relocs, &decoded, &info, &labels, &dec_err, inst.mode)
	if !dec_success || len(decoded) == 0 {
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

	// ---- Words the table sweep cannot reach ----
	// The sweep decodes each form's canonical word, which has every variable
	// field zero. For the coprocessor forms that means p0, which ARMv8
	// reserves and no assembler will take -- so these are checked here, by
	// the text they print, against what an assembler makes of it.
	fmt.println("\n==== Coprocessor words, decoded to text ====")
	check_decodes_to(0xEE2431C5, "cdp p1, #2, c3, c4, c5, #6")
	check_decodes_to(0xEE4431D5, "mcr p1, #2, r3, c4, c5, #6")
	check_decodes_to(0xEE5431D5, "mrc p1, #2, r3, c4, c5, #6")
	check_decodes_to(0xEE117F30, "mrc p15, #0, r7, c1, c0, #1")
	check_decodes_to(0xEC443125, "mcrr p1, #2, r3, r4, c5")
	check_decodes_to(0xEC543125, "mrrc p1, #2, r3, r4, c5")
	check_decodes_to(0xED932102, "ldc p1, c2, [r3, #8]")
	check_decodes_to(0xEDB32102, "ldc p1, c2, [r3, #8]!")
	check_decodes_to(0xECB32102, "ldc p1, c2, [r3], #8")
	check_decodes_to(0xEDD32102, "ldcl p1, c2, [r3, #8]")
	check_decodes_to(0xEDC32102, "stcl p1, c2, [r3, #8]")
	check_decodes_to(0xED132102, "ldc p1, c2, [r3, #-8]")

	// ---- Thumb, as an objdump would see it ----
	// The report that started the Thumb work: these four, from a Cortex-M7
	// image, decoded as A32 garbage, and as worse in Thumb mode -- the list
	// of a PUSH read from the wrong bits, LDR's literal and LDRB's base from
	// fields that are not theirs, CBNZ's target four bytes short.
	fmt.println("\n==== Thumb words, decoded to text ====")
	check_thumb_decodes_to({0x10, 0xb5, 0x05, 0x4c, 0x23, 0x78, 0x33, 0xb9}, .M_PROFILE,
		"    push {r4, lr}\n    ldr r4, 0x18\n    ldrb r3, [r4]\n    cbnz r3, 0x16\n")
	// One of each kind of Thumb instruction a compiler for an M-profile core
	// with an FPU emits, and the IT blocks around them. Every line here was
	// assembled by llvm-mc and round-trips through it byte for byte.
	check_thumb_decodes_to(THUMB_GOLDEN_BYTES, .M_PROFILE, THUMB_GOLDEN_TEXT)
	// And MVE: a load, store, multiply and reduction of each kind, VPT and
	// VPST blocks, whose instructions carry their T and E, and a
	// tail-predicated loop. Assembled by llvm-mc, and the text round-trips
	// through it byte for byte.
	check_thumb_decodes_to(MVE_GOLDEN_BYTES, .M_PROFILE, MVE_GOLDEN_TEXT)

	fmt.printf("\n==> arm32 pipeline: %d passed, %d failed\n", ok, fail)
}

// Decode a run of Thumb bytes as one stream and compare the whole listing,
// labels and all, against what it should print.
check_thumb_decodes_to :: proc(code: []u8, profile: a.Profile, want: string) {
	back:   [dynamic]a.Instruction
	info:   [dynamic]a.Instruction_Info
	labels: [dynamic]a.Label_Definition
	errs:   [dynamic]a.Error
	defer { delete(back); delete(info); delete(labels); delete(errs) }
	a.decode(code, nil, &back, &info, &labels, &errs, .T32, profile)
	if len(errs) > 0 {
		fmt.printf("  [FAIL] thumb: %d words did not decode\n", len(errs))
		fail += 1
		return
	}
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	a.sbprint(&sb, back[:], info[:], labels[:])
	got := strings.to_string(sb)
	if got == want {
		fmt.printf("  [ok]   thumb: %d instructions\n", len(back))
		ok += 1
		return
	}
	got_lines := strings.split_lines(got, context.temp_allocator)
	want_lines := strings.split_lines(want, context.temp_allocator)
	for i in 0 ..< max(len(got_lines), len(want_lines)) {
		g := i < len(got_lines) ? got_lines[i] : "<none>"
		w := i < len(want_lines) ? want_lines[i] : "<none>"
		if g != w {
			fmt.printf("  [FAIL] thumb line %d: got %q want %q\n", i + 1, g, w)
			fail += 1
			return
		}
	}
}

@(rodata)
THUMB_GOLDEN_BYTES := []u8{
	0x10, 0xb5, 0x05, 0x4c, 0x23, 0x78, 0x00, 0xbf, 0x05, 0x20, 0xd1, 0x18, 0xc8, 0x39, 0xc8, 0x07,
	0x08, 0x10, 0xe8, 0x46, 0xff, 0xa8, 0x7f, 0xb0, 0x81, 0xb0, 0x02, 0x98, 0xd1, 0x50, 0xd1, 0x5e,
	0xf5, 0x87, 0x48, 0x43, 0x48, 0x42, 0x06, 0xc0, 0x03, 0xc8, 0x70, 0xbd, 0x70, 0x47, 0x98, 0x47,
	0x88, 0xb2, 0x5a, 0xba, 0x72, 0xb6, 0xab, 0xbe, 0x11, 0xdf, 0xfe, 0xde, 0x00, 0xbf, 0xa5, 0xe0,
	0xde, 0xd0, 0x0c, 0xbf, 0x88, 0x18, 0x4f, 0xf4, 0x80, 0x63, 0x18, 0xbf, 0xd1, 0xf8, 0x04, 0x00,
	0x09, 0xeb, 0xca, 0x08, 0x11, 0xf1, 0xff, 0x10, 0x01, 0xf6, 0xff, 0x70, 0xad, 0xf2, 0x01, 0x0d,
	0x4f, 0xf4, 0x22, 0x70, 0x4b, 0xf6, 0xef, 0x61, 0xcd, 0xf6, 0xad, 0x61, 0x6f, 0xf0, 0x00, 0x02,
	0x64, 0xea, 0xf5, 0x13, 0x61, 0xf3, 0x0b, 0x10, 0xc1, 0xf3, 0xdc, 0x00, 0x43, 0xf3, 0x00, 0x02,
	0x21, 0xf3, 0x08, 0x10, 0xa1, 0xf3, 0x0f, 0x00, 0x01, 0xfa, 0x02, 0xf0, 0x01, 0xfa, 0xa2, 0xf0,
	0x5f, 0xfa, 0x84, 0xf3, 0x91, 0xfa, 0xa1, 0xf0, 0xb3, 0xfa, 0x83, 0xf2, 0x91, 0xfb, 0xf2, 0xf0,
	0xa2, 0xfb, 0x03, 0x01, 0xc6, 0xfb, 0x07, 0x45, 0x01, 0xfb, 0x02, 0x30, 0x61, 0xfb, 0x02, 0x30,
	0xd1, 0xf8, 0xff, 0x0f, 0x51, 0xf8, 0xff, 0x0c, 0x51, 0xf8, 0x08, 0x0f, 0x11, 0xf8, 0x10, 0x09,
	0x31, 0xf8, 0x32, 0x00, 0x1f, 0xf9, 0x64, 0x00, 0x51, 0xf8, 0x04, 0x0e, 0x62, 0xe9, 0x02, 0x01,
	0xf4, 0xe8, 0x04, 0x23, 0x51, 0xe8, 0x01, 0x0f, 0x41, 0xe8, 0x00, 0x02, 0xd1, 0xe8, 0x4f, 0x0f,
	0xd0, 0xe8, 0x01, 0xf0, 0xd0, 0xe8, 0x11, 0xf0, 0x10, 0xf8, 0x04, 0xfc, 0x2d, 0xe9, 0xf0, 0x4f,
	0xbd, 0xe8, 0xf0, 0x8f, 0x30, 0xe9, 0x0e, 0x00, 0x80, 0xe8, 0x06, 0x00, 0x00, 0xf0, 0x46, 0xb8,
	0x7f, 0xf4, 0x7e, 0xaf, 0x00, 0xf0, 0x42, 0xf8, 0xbf, 0xf3, 0x5b, 0x8f, 0xbf, 0xf3, 0x4f, 0x8f,
	0xbf, 0xf3, 0x6f, 0x8f, 0xbf, 0xf3, 0x2f, 0x8f, 0xaf, 0xf3, 0x00, 0x80, 0xef, 0xf3, 0x10, 0x80,
	0x81, 0xf3, 0x11, 0x88, 0xef, 0xf3, 0x00, 0x80, 0x82, 0xf3, 0x00, 0x88, 0x91, 0xed, 0x03, 0x0a,
	0x0d, 0xed, 0x04, 0x8b, 0x30, 0xee, 0x81, 0x0a, 0x21, 0xee, 0x02, 0x0b, 0xe2, 0xee, 0x22, 0x1a,
	0xb1, 0xee, 0xe0, 0x0a, 0xb8, 0xee, 0xc0, 0x0a, 0xfd, 0xee, 0xc1, 0x0a, 0xb7, 0xee, 0xe1, 0x0a,
	0xb3, 0xee, 0x60, 0x0a, 0xb5, 0xee, 0x40, 0x0a, 0xb4, 0xee, 0xc2, 0x1b, 0xf1, 0xee, 0x10, 0xfa,
	0x10, 0xee, 0x90, 0x0a, 0x01, 0xee, 0x10, 0x3a, 0x51, 0xec, 0x12, 0x0b, 0xb7, 0xee, 0x00, 0x0a,
	0x2d, 0xed, 0x10, 0x8b, 0xbd, 0xec, 0x0a, 0x8a, 0xb0, 0xec, 0x06, 0x0b, 0x20, 0xfe, 0x81, 0x0a,
	0x81, 0xfe, 0x02, 0x0b, 0xb8, 0xfe, 0x60, 0x0a, 0x00, 0xbf, 0x00, 0xbf, 0x00, 0xbf,
}

THUMB_GOLDEN_TEXT :: `.L0:
    push {r4, lr}
    ldr r4, .L1
    ldrb r3, [r4]
    nop
    movs r0, #5
    adds r1, r2, r3
    subs r1, #200
    lsls r0, r1, #31
    asrs r0, r1, #32
    mov r8, sp
    add r0, sp, #1020
    add sp, #508
.L1:
    sub sp, #4
    ldr r0, [sp, #8]
    str r1, [r2, r3]
    ldrsh r1, [r2, r3]
    strh r5, [r6, #62]
    muls r0, r1, r0
    rsbs r0, r1, #0
    stm r0!, {r1-r2}
    ldm r0, {r0-r1}
    pop {r4-r6, pc}
    bx lr
    blx r3
    uxth r0, r1
    rev16 r2, r3
    cpsid i
    bkpt #171
    svc #17
    udf #254
    nop
    b .L3
    beq .L0
    ite eq
    addeq r0, r1, r2
    movne.w r3, #1024
    it ne
    ldrne.w r0, [r1, #4]
    add r8, r9, r10, lsl #3
    adds r0, r1, #16711935
    addw r0, r1, #4095
    subw sp, sp, #1
    mov.w r0, #648
.L2:
    movw r1, #48879
    movt r1, #57005
    mvn r2, #0
    orn r3, r4, r5, ror #7
    bfi r0, r1, #4, #8
    ubfx r0, r1, #3, #29
    sbfx r2, r3, #0, #1
    ssat r0, #9, r1, asr #4
    usat16 r0, #15, r1
    lsl r0, r1, r2
    sxtah r0, r1, r2, ror #16
    uxtb.w r3, r4
    rbit r0, r1
    clz r2, r3
    sdiv r0, r1, r2
    umull r0, r1, r2, r3
    smlal r4, r5, r6, r7
    mla r0, r1, r2, r3
    smmls r0, r1, r2, r3
    ldr.w r0, [r1, #4095]
    ldr r0, [r1, #-255]
    ldr r0, [r1, #8]!
    ldrb r0, [r1], #-16
    ldrh r0, [r1, r2, lsl #3]
    ldrsb r0, .L2
    ldrt r0, [r1, #4]
    strd r0, r1, [r2, #-8]!
    ldrd r2, r3, [r4], #16
    ldrex r0, [r1, #4]
    strex r2, r0, [r1]
    ldrexb r0, [r1]
    tbb [r0, r1]
    tbh [r0, r1, lsl #1]
    pld [r0, #-4]
    push {r4-fp, lr}
    pop {r4-fp, pc}
    ldmdb r0!, {r1-r3}
    stm r0, {r1-r2}
    b.w .L3
    bne.w .L0
    bl .L3
    dmb ish
    dsb sy
    isb sy
    clrex
    nop.w
    mrs r0, primask
    msr basepri, r1
    mrs r0, apsr
    msr apsr_nzcvq, r2
    vldr s0, [r1, #12]
    vstr d8, [sp, #-16]
    vadd.f32 s0, s1, s2
    vmul.f64 d0, d1, d2
    vfma.f32 s3, s4, s5
    vsqrt.f32 s0, s1
    vcvt.f32.s32 s0, s0
    vcvt.s32.f32 s1, s2
    vcvt.f64.f32 d0, s3
    vcvtb.f16.f32 s0, s1
    vcmp.f32 s0, #0
    vcmpe.f64 d1, d2
    vmrs apsr_nzcv, fpscr
    vmov r0, s1
    vmov s2, r3
    vmov r0, r1, d2
    vmov.f32 s0, #1.000000e+00
    vpush {d8, d9, d10, d11, d12, d13, d14, d15}
    vpop {s16, s17, s18, s19, s20, s21, s22, s23, s24, s25}
    vldmia r0!, {d0, d1, d2}
    vselge.f32 s0, s1, s2
    vmaxnm.f64 d0, d1, d2
    vrinta.f32 s0, s1
    nop
    nop
.L3:
    nop
`

// Decode one word and compare what it prints against the text an assembler
// accepts for it.
check_decodes_to :: proc(word: u32, want: string) {
	code := [4]u8{u8(word), u8(word >> 8), u8(word >> 16), u8(word >> 24)}
	back:   [dynamic]a.Instruction
	info:   [dynamic]a.Instruction_Info
	labels: [dynamic]a.Label_Definition
	errs:   [dynamic]a.Error
	defer { delete(back); delete(info); delete(labels); delete(errs) }
	a.decode(code[:], nil, &back, &info, &labels, &errs, .A32)
	if len(back) != 1 {
		fmt.printf("  [FAIL] %08x: decoded to %d instructions, want 1\n", word, len(back))
		fail += 1
		return
	}
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	a.sbprint(&sb, back[:], info[:], nil)
	got := strings.trim_space(strings.to_string(sb))
	if got != want {
		fmt.printf("  [FAIL] %08x: got %q want %q\n", word, got, want)
		fail += 1
		return
	}
	fmt.printf("  [ok]   %08x -> %s\n", word, got)
	ok += 1
}

@(rodata)
MVE_GOLDEN_BYTES := []u8{
	0x90, 0xed, 0x04, 0x1f, 0xb1, 0xec, 0x88, 0x2e, 0x32, 0xed, 0x83, 0x5e, 0x20, 0xef, 0x42, 0x68,
	0x35, 0xee, 0x63, 0x8e, 0x00, 0xef, 0x52, 0xac, 0x13, 0xee, 0x62, 0xce, 0x8d, 0xff, 0x5c, 0xe0,
	0xaa, 0xee, 0x42, 0x0f, 0x97, 0xee, 0x45, 0x3f, 0xb0, 0xfe, 0x46, 0x4f, 0xf9, 0xee, 0x00, 0x4f,
	0x99, 0xfe, 0x22, 0x2f, 0xf4, 0xee, 0x06, 0x6e, 0x89, 0xee, 0x2a, 0x1e, 0xcc, 0xfe, 0x0e, 0x8f,
	0xee, 0xee, 0x02, 0x5f, 0xa6, 0xee, 0x30, 0x7b, 0x23, 0xee, 0x10, 0x2b, 0xf5, 0xee, 0x30, 0x3b,
	0x15, 0xec, 0x14, 0x0f, 0x82, 0xef, 0x5a, 0x8a, 0x81, 0xef, 0x7c, 0xa1, 0x31, 0xee, 0x02, 0x1f,
	0x37, 0xfe, 0x09, 0x4f, 0x26, 0xf0, 0x01, 0xe8, 0x71, 0xfe, 0x4d, 0x0f, 0x82, 0xed, 0x08, 0x3f,
	0x61, 0xfe, 0x61, 0x9f, 0x20, 0xef, 0x44, 0x08, 0x20, 0xff, 0x46, 0x08, 0x71, 0xfe, 0x4d, 0xcf,
	0x94, 0xed, 0x00, 0x7f, 0x94, 0xed, 0x04, 0x9f, 0x26, 0xef, 0x58, 0xa9, 0x1e, 0xfd, 0x02, 0xde,
	0x83, 0xec, 0x02, 0x0e, 0x94, 0xec, 0x17, 0x4f, 0x95, 0xfc, 0x00, 0x1f, 0xb6, 0xfc, 0x21, 0x5e,
	0x14, 0xfe, 0x06, 0x3f, 0x32, 0xfe, 0x05, 0x0e, 0x2a, 0xee, 0x0c, 0x8f, 0x13, 0xee, 0xee, 0x2f,
	0x05, 0xee, 0x67, 0x4f, 0xad, 0xee, 0xc8, 0x6f, 0x50, 0xea, 0x6f, 0x11, 0x52, 0xea, 0x0d, 0x43,
	0x55, 0xea, 0xad, 0x65, 0x57, 0xea, 0x4f, 0x2f, 0x58, 0xea, 0xdf, 0x7f, 0xb6, 0xff, 0x44, 0x24,
	0xb6, 0xef, 0x58, 0x6f, 0x3f, 0xee, 0x0d, 0xae, 0x82, 0xfe, 0x05, 0x9f, 0x37, 0xee, 0x89, 0x6e,
	0x12, 0xed, 0x85, 0x4f, 0xed, 0xec, 0x82, 0xaf, 0x10, 0xf0, 0x01, 0xc0, 0xb1, 0xec, 0x88, 0x1e,
	0x1f, 0xf0, 0x05, 0xc0,
}

MVE_GOLDEN_TEXT :: `    vldrw.u32 q0, [r0, #16]
    vldrb.s16 q1, [r1], #8
    vldrh.u16 q2, [r2, #-6]!
    vadd.i32 q3, q0, q1
    vmul.f32 q4, q2, r3
    vfma.f32 q5, q0, q1
    vqdmulh.s16 q6, q1, r2
    vshr.u8 q7, q6, #3
    vshllb.s8 q0, q1, #2
    vqrshrnt.s32 q1, q2, #9
    vmovlb.u16 q2, q3
    vaddv.s32 r4, q0
    vaddlva.u32 r2, r3, q1
    vmlav.s16 r6, q2, q3
    vmlaldavax.s32 r0, r1, q4, q5
    vrmlalvh.u32 r8, r9, q6, q7
    vmaxnmv.f32 r5, q1
    vdup.16 q3, r7
    vmov.32 q1[3], r2
    vmov.u8 r3, q2[13]
    vmov q0[3], q0[1], r4, r5
    vmov.i16 q4, #0x2a00
    vbic.i32 q5, #0x1c
    vcmp.f32 ge, q0, q1
    vpsel q2, q3, q4
    vctp.32 r6
    vpst
    vstrwt.32 q1, [r2, #32]
    vpte.s32 gt, q0, r1
    vaddt.i32 q0, q0, q2
    vsube.i32 q0, q0, q3
    vpstet
    vldrwt.u32 q3, [r4]
    vldrwe.u32 q4, [r4, #16]
    vmult.i32 q5, q3, q4
    vldrw.u32 q6, [q7, #-8]
    vstrb.8 q0, [r3, q1]
    vldrh.s32 q2, [r4, q3, uxtw #1]
    vld20.32 {q0, q1}, [r5]
    vld41.8 {q2, q3, q4, q5}, [r6]!
    vcadd.i16 q1, q2, q3, #270
    vcmul.f32 q0, q1, q2, #90
    vhcadd.s32 q4, q5, q6, #90
    vidup.u16 q1, r2, #4
    viwdup.u8 q2, r4, r7, #2
    vshlc q3, r8, #13
    asrl r0, r1, #5
    lsll r2, r3, r4
    sqrshrl r4, r5, #48, r6
    uqshl r7, #9
    urshr r8, #31
    vrintn.f16 q1, q2
    vcvt.s32.f32 q3, q4, #10
    vcvtb.f16.f32 q5, q6
    vabav.u8 r9, q1, q2
    vmaxa.s16 q3, q4
    vldr fpscr_nzcvqc, [r2, #-20]
    vstr p0, [sp], #8
    wlstp.16 lr, r0, .L0
.L0:
    vldrh.u16 q0, [r1], #16
    letp lr, .L0
`
