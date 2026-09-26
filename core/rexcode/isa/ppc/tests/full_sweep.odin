// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_ppc_tests

// Full encode→decode→re-encode sweep across the entire ENCODING_TABLE.
//
// For each form:
//   1. Synthesize an Instruction from the form's operand types
//   2. Encode it
//   3. Decode the bytes
//   4. Re-encode the decoded Instruction
//   5. Verify bytes match
//
// Categorise failures: BUILD_FAIL, ENCODE_FAIL, DECODE_FAIL, REENCODE_FAIL,
// BYTE_MISMATCH, MNEMONIC_MISMATCH.

import "core:fmt"
import "core:os"
import p ".."
import "core:rexcode/isa"

Stats :: struct {
	ok, build_fail, encode_fail, decode_fail, reencode_fail, byte_mismatch, mn_alias: int,
}

stats: Stats

run_full_sweep :: proc() {
	fmt.println("==== ppc full encode→decode→re-encode sweep ====")

	fail_samples: [dynamic]string
	defer delete(fail_samples)

	for mn in p.Mnemonic {
		_run := p.ENCODE_RUNS[u16(mn)]
		forms := p.ENCODE_FORMS[_run.start:][:_run.count]
		for &f, fi in forms {
			test_form(mn, fi, &f, &fail_samples)
		}
	}

	total := stats.ok + stats.build_fail + stats.encode_fail + stats.decode_fail +
			 stats.reencode_fail + stats.byte_mismatch + stats.mn_alias
	fmt.printf("\n[TOTAL] %d forms\n", total)
	fmt.printf("    OK:                 %d  (%.1f%%)\n", stats.ok,            100.0 * f32(stats.ok)            / f32(total))
	fmt.printf("    MN_ALIAS:           %d  (%.1f%%)\n", stats.mn_alias,      100.0 * f32(stats.mn_alias)      / f32(total))
	fmt.printf("    BUILD_FAIL:         %d  (%.1f%%)\n", stats.build_fail,    100.0 * f32(stats.build_fail)    / f32(total))
	fmt.printf("    ENCODE_FAIL:        %d  (%.1f%%)\n", stats.encode_fail,   100.0 * f32(stats.encode_fail)   / f32(total))
	fmt.printf("    DECODE_FAIL:        %d  (%.1f%%)\n", stats.decode_fail,   100.0 * f32(stats.decode_fail)   / f32(total))
	fmt.printf("    REENCODE_FAIL:      %d  (%.1f%%)\n", stats.reencode_fail, 100.0 * f32(stats.reencode_fail) / f32(total))
	fmt.printf("    BYTE_MISMATCH:      %d  (%.1f%%)\n", stats.byte_mismatch, 100.0 * f32(stats.byte_mismatch) / f32(total))

	if len(fail_samples) > 0 {
		fmt.println("\nFirst 50 failure samples:")
		for s, i in fail_samples {
			if i >= 50 { break }
			fmt.println("  " , s)
		}
	}
}

// Build a canonical Instruction from the form's operand types using
// safe-fill values matching dump_verify_input.odin.
build_instruction :: proc(mn: p.Mnemonic, fi: int, f: ^p.Encoding) -> (inst: p.Instruction, ok: bool) {
	inst.mnemonic = mn
	inst.mode     = f.mode
	inst.length   = 4
	inst.form_id  = u16(fi + 1)
	inst.flags    = {}

	if f.flags.prefixed { inst.length = 8 }

	n_ops: u8 = 0
	for k in 0..<4 {
		op, slot_ok := build_operand(f.ops[k], f.enc[k])
		if !slot_ok { return inst, false }
		if op.kind == .NONE { break }
		inst.ops[k] = op
		n_ops = u8(k + 1)
	}
	inst.operand_count = n_ops
	return inst, true
}

build_operand :: proc(ot: p.Operand_Type, enc: p.Operand_Encoding) -> (op: p.Operand, ok: bool) {
	#partial switch ot {
	case .NONE:        return p.Operand{}, true
	case .GPR, .GPR_OR_ZERO:
		return p.op_reg(safe_gpr_for(enc)), true
	case .FPR:         return p.op_reg(safe_fpr_for(enc)), true
	case .VR:          return p.op_reg(safe_vr_for(enc)), true
	case .VR128:
		#partial switch enc {
		case .VRT128: return p.op_reg(p.vr128_reg(2)), true
		case .VRA128: return p.op_reg(p.vr128_reg(3)), true
		case .VRB128: return p.op_reg(p.vr128_reg(4)), true
		case .VRC128: return p.op_reg(p.vr128_reg(5)), true
		}
		return p.op_reg(p.vr128_reg(2)), true
	case .VSR:         return p.op_reg(safe_vsr_for(enc)), true
	case .CR_FIELD:    return p.op_reg(p.Register(p.REG_CR | 1)), true
	case .CR_BIT:      return p.op_reg(p.Register(p.REG_CR | 0)), true
	case .SPR:         return p.op_reg(p.LR), true
	case .IMM, .SIMM, .UIMM:
		return p.op_imm(safe_imm_for(enc)), true
	case .REL:         return p.op_rel_offset(0), true
	case .MEM:
		if enc == .OFFSET_BASE_X || enc == .OFFSET_VSX_X {
			return p.op_mem(p.mem_x(p.R4, p.R5)), true
		}
		return p.op_mem(p.mem_d(p.R4, 0)), true
	case .BO:          return p.op_imm(12), true
	case .BH:          return p.op_imm(0), true
	}
	return p.Operand{}, true
}

safe_gpr_for :: proc(enc: p.Operand_Encoding) -> p.Register {
	#partial switch enc {
	case .RT, .RS:        return p.R3
	case .RA:             return p.R4
	case .RB:             return p.R5
	case .RC:             return p.R6
	}
	return p.R3
}
safe_fpr_for :: proc(enc: p.Operand_Encoding) -> p.Register {
	#partial switch enc {
	case .FRT:            return p.F1
	case .FRA:            return p.F2
	case .FRB:            return p.F3
	case .FRC:            return p.F4
	}
	return p.F1
}
safe_vr_for :: proc(enc: p.Operand_Encoding) -> p.Register {
	#partial switch enc {
	case .VRT:            return p.V2
	case .VRA:            return p.V3
	case .VRB:            return p.V4
	case .VRC:            return p.V5
	}
	return p.V2
}
safe_vsr_for :: proc(enc: p.Operand_Encoding) -> p.Register {
	#partial switch enc {
	case .XT:             return p.vs_reg(2)
	case .XA:             return p.vs_reg(3)
	case .XB:             return p.vs_reg(4)
	case .XC:             return p.vs_reg(5)
	}
	return p.vs_reg(2)
}
safe_imm_for :: proc(enc: p.Operand_Encoding) -> i64 {
	#partial switch enc {
	case .SH5, .SH6:      return 4
	case .MB5, .MB6:      return 0
	case .ME5:            return 31
	case .SIMM_5, .UIMM_5, .UIMM_4, .UIMM_2: return 1
	case .FXM:            return 0x80
	case .TO_FIELD:       return 31
	case .NB_FIELD:       return 4
	case .CRM:            return 0x80
	case .BO_FIELD:       return 12
	case .BI_FIELD:       return 0
	}
	return 0
}

test_form :: proc(mn: p.Mnemonic, fi: int, f: ^p.Encoding, fails: ^[dynamic]string) {
	inst, ok := build_instruction(mn, fi, f)
	if !ok {
		stats.build_fail += 1
		if len(fails) < 100 { append(fails, fmt.aprintf("BUILD_FAIL  %v[%d]", mn, fi)) }
		return
	}

	code := make([]u8, 16, context.temp_allocator)
	relocs:  [dynamic]p.Relocation
	errors:  [dynamic]p.Error
	defer delete(relocs); defer delete(errors)

	instructions := []p.Instruction{inst}
	label_defs:   []isa.Label_Definition
	byte_count, success := p.encode(instructions, label_defs, code, &relocs, &errors)
	if !success {
		stats.encode_fail += 1
		if len(fails) < 100 { append(fails, fmt.aprintf("ENCODE_FAIL %v[%d] errors=%d", mn, fi, len(errors))) }
		return
	}

	// ---- Decode ----
	decoded:        [dynamic]p.Instruction
	dec_info:       [dynamic]p.Instruction_Info
	dec_labels:     [dynamic]p.Label_Definition
	dec_errors:     [dynamic]p.Error
	defer delete(decoded); defer delete(dec_info); defer delete(dec_labels); defer delete(dec_errors)

	dbyte_count, dsuccess := p.decode(code[:byte_count], nil, &decoded, &dec_info, &dec_labels, &dec_errors, f.mode)
	if !dsuccess || len(decoded) == 0 || decoded[0].mnemonic == .INVALID {
		stats.decode_fail += 1
		if len(fails) < 100 {
			append(fails, fmt.aprintf("DECODE_FAIL %v[%d] bytes=%02x%02x%02x%02x",
				mn, fi, code[0], code[1], code[2], code[3]))
		}
		return
	}
	alias_decoded := decoded[0].mnemonic != mn

	// ---- Re-encode ----
	code2 := make([]u8, 16, context.temp_allocator)
	re_relocs: [dynamic]p.Relocation
	re_errors: [dynamic]p.Error
	defer delete(re_relocs); defer delete(re_errors)

	rrbyte_count, rrsuccess := p.encode(decoded[:], dec_labels[:], code2, &re_relocs, &re_errors)
	if !rrsuccess {
		stats.reencode_fail += 1
		if len(fails) < 100 {
			append(fails, fmt.aprintf("REENCODE_FAIL %v[%d] decoded_mn=%v",
				mn, fi, decoded[0].mnemonic))
		}
		return
	}

	if rrbyte_count != byte_count {
		stats.byte_mismatch += 1
		if len(fails) < 100 {
			append(fails, fmt.aprintf("LEN_MISMATCH %v[%d] orig=%d re=%d", mn, fi, byte_count, rrbyte_count))
		}
		return
	}
	for i in 0..<byte_count {
		if code[i] != code2[i] {
			stats.byte_mismatch += 1
			if len(fails) < 100 {
				append(fails, fmt.aprintf("BYTE_MISMATCH %v[%d]→%v orig=%02x%02x%02x%02x re=%02x%02x%02x%02x",
					mn, fi, decoded[0].mnemonic, code[0], code[1], code[2], code[3], code2[0], code2[1], code2[2], code2[3]))
			}
			return
		}
	}
	// Bytes match. Count as OK (or MN_ALIAS if decoded mnemonic differs but
	// bytes still round-trip stably — the form_id hint handled it).
	if alias_decoded {
		stats.mn_alias += 1
	} else {
		stats.ok += 1
	}
}
