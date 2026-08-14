// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ppc_vle_tests

import "core:fmt"
import "core:os"
import v ".."
import "core:rexcode/isa"

stats: struct { ok, mn_alias, byte_mismatch, encode_fail, decode_fail: int }

run_full_sweep :: proc() {
	fmt.println("==== ppc_vle full sweep ====")

	for mn in v.Mnemonic {
		_run := v.ENCODE_RUNS[u16(mn)]
		forms := v.ENCODE_FORMS[_run.start:][:_run.count]
		for &f, fi in forms {
			test_one(mn, fi, &f)
		}
	}

	total := stats.ok + stats.mn_alias + stats.byte_mismatch + stats.encode_fail + stats.decode_fail
	fmt.printf("\n[TOTAL] %d entries\n", total)
	fmt.printf("    OK:            %d  (%.1f%%)\n", stats.ok,          100.0 * f32(stats.ok)            / f32(total))
	fmt.printf("    MN_ALIAS:      %d  (%.1f%%)\n", stats.mn_alias,    100.0 * f32(stats.mn_alias)      / f32(total))
	fmt.printf("    BYTE_MISMATCH: %d  (%.1f%%)\n", stats.byte_mismatch, 100.0 * f32(stats.byte_mismatch) / f32(total))
	fmt.printf("    ENCODE_FAIL:   %d  (%.1f%%)\n", stats.encode_fail, 100.0 * f32(stats.encode_fail)   / f32(total))
	fmt.printf("    DECODE_FAIL:   %d  (%.1f%%)\n", stats.decode_fail, 100.0 * f32(stats.decode_fail)   / f32(total))
}

test_one :: proc(mn: v.Mnemonic, fi: int, f: ^v.Encoding) {
	inst := v.Instruction{
		mnemonic = mn,
		mode     = .PPC32_VLE,
		form_id  = u16(fi + 1),
		length   = f.flags.short ? 2 : 4,
	}
	code := make([]u8, 8, context.temp_allocator)
	label_defs: []isa.Label_Definition
	relocs: [dynamic]v.Relocation
	errors: [dynamic]v.Error
	defer delete(relocs); defer delete(errors)

	instructions := []v.Instruction{inst}
	byte_count, success := v.encode(instructions, label_defs, code, &relocs, &errors)
	if !success {
		stats.encode_fail += 1
		return
	}

	decoded:    [dynamic]v.Instruction
	info:       [dynamic]v.Instruction_Info
	dec_labels: [dynamic]v.Label_Definition
	dec_errors: [dynamic]v.Error
	defer delete(decoded); defer delete(info); defer delete(dec_labels); defer delete(dec_errors)

	dbyte_count, dsuccess := v.decode(code[:byte_count], nil, &decoded, &info, &dec_labels, &dec_errors)
	if !dsuccess || len(decoded) == 0 || decoded[0].mnemonic == .INVALID {
		stats.decode_fail += 1
		return
	}

	// Re-encode and check bytes
	code2 := make([]u8, 8, context.temp_allocator)
	re_relocs: [dynamic]v.Relocation
	re_errors: [dynamic]v.Error
	defer delete(re_relocs); defer delete(re_errors)

	rrbyte_count, rrsuccess := v.encode(decoded[:], dec_labels[:], code2, &re_relocs, &re_errors)
	if !rrsuccess || rrbyte_count != byte_count {
		stats.byte_mismatch += 1
		return
	}
	for i in 0..<byte_count {
		if code[i] != code2[i] {
			stats.byte_mismatch += 1
			if stats.byte_mismatch <= 10 {
				fmt.printf("  [BYTE_MISMATCH] %v: orig=", mn)
				for j in 0..<byte_count { fmt.printf("%02x", code[j]) }
				fmt.printf(" re=")
				for j in 0..<byte_count { fmt.printf("%02x", code2[j]) }
				fmt.printf(" decoded=%v\n", decoded[0].mnemonic)
			}
			return
		}
	}

	if decoded[0].mnemonic == mn {
		stats.ok += 1
	} else {
		stats.mn_alias += 1
	}
}
