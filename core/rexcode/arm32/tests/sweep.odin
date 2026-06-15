// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_arm32_tests

import "core:fmt"
import a "../"

// =============================================================================
// AArch32 ENCODING_TABLE sweep
// =============================================================================
//
// For every entry in ENCODING_TABLE, this builds a canonical word with safe
// operand fills, decodes it, verifies the decoder picked the right mnemonic,
// and re-encodes the decoded Instruction to verify pack/unpack are mutual
// inverses on the masked bits.
//
// What this catches:
//   * Bucket misses: decoder fails to find the entry from its own canonical
//     bits. Implies the dispatch index is missing a bucket for this form.
//   * Wrong-entry decode: bucket has the entry but a different entry's mask
//     happens to also match.
//   * Pack/unpack asymmetry: decoder returns operands that, when re-encoded,
//     produce a different bit pattern (off-by-one in a field shift, wrong
//     sign handling, etc.).

Sweep_Stats :: struct {
	total:           int,
	ok:              int,
	fail_decode:     int,    // decoder returned INVALID
	fail_mnemonic:   int,    // decoded a different mnemonic
	fail_reencode:   int,    // re-encoded word doesn't match (masked)
	fail_encode:     int,    // re-encode itself failed
}

run_sweep_tests :: proc() {
	fmt.println("\n==== ENCODING_TABLE sweep ====")
	a32_stats, t32_stats, t16_stats: Sweep_Stats

	// Cap the per-bucket failure printing so a wholesale regression doesn't
	// wallpaper the test output.
	max_fail_print :: 80
	failed_examples: int
	only_print_kind: string = ""

	for mn in a.Mnemonic {
		_run := a.ENCODE_RUNS[u16(mn)]
		forms := a.ENCODE_FORMS[_run.start:][:_run.count]
		for &f, idx in forms {
			ilen := a.inst_size_from_bits(f.bits, f.mode)

			// Canonical word: form.bits | safe-fill operand bits.
			word := f.bits
			for _, k in f.enc { word |= sweep_safe_fill(f.enc[k]) }
			// Operand-type-driven extras: GPR_RSR needs a non-zero Rs in bits
			// 11..8 to disambiguate from GPR_SHIFTED on decode/re-encode; the
			// base bits already set bit 4 (the RSR flag), but Rs=0 would alias
			// with R0 and the shape_matches predicate requires shift_amt != 0.
			for _, k in f.enc {
				if f.ops[k] == .GPR_RSR && (f.enc[k] == .RM_A32 || f.enc[k] == .RM_T32) {
					word |= u32(4) << 8
				}
			}
			// Bake AL cond for conditional A32.
			if f.mode == .A32 && (f.mask >> 28) == 0 {
				word = (word & 0x0FFFFFFF) | (0xE << 28)
			}

			stats := &a32_stats
			if f.mode != .A32 { stats = ilen == 4 ? &t32_stats : &t16_stats }
			stats.total += 1

			// Serialize to bytes per mode/ilen.
			buf: [4]u8
			if f.mode == .A32 {
				buf[0] = u8(word);  buf[1] = u8(word >> 8)
				buf[2] = u8(word >> 16); buf[3] = u8(word >> 24)
			} else if ilen == 4 {
				hi := u16(word >> 16); lo := u16(word & 0xFFFF)
				buf[0] = u8(hi); buf[1] = u8(hi >> 8)
				buf[2] = u8(lo); buf[3] = u8(lo >> 8)
			} else {
				v := u16(word & 0xFFFF)
				buf[0] = u8(v); buf[1] = u8(v >> 8)
			}
			n := int(ilen)

			relocs := []a.Relocation{}
			insts: [dynamic]a.Instruction
			info:  [dynamic]a.Instruction_Info
			label_defs: [dynamic]a.Label_Definition
			errors: [dynamic]a.Error
			defer { delete(insts); delete(info); delete(label_defs); delete(errors) }

			a.decode(buf[:n], relocs, &insts, &info, &label_defs, &errors, f.mode)

			if len(insts) == 0 || insts[0].mnemonic == .INVALID {
				stats.fail_decode += 1
				if failed_examples < max_fail_print && (only_print_kind == "" || only_print_kind == "decode") {
					fmt.printf("  [decode  ] %v[%d] %08X mode=%v ilen=%d mask=%08X bits=%08X\n",
						mn, idx, word, f.mode, ilen, f.mask, f.bits)
					failed_examples += 1
				}
				continue
			}
			// Mnemonic mismatch is acceptable IF the decoded mnemonic
			// re-encodes to the same masked bits (a legitimate alias — e.g.
			// MOV+shift is canonically LSL). We defer the verdict to the
			// bytes-roundtrip check below; track for diagnostics only.
			mnem_alias := insts[0].mnemonic != mn

			// Re-encode and verify masked bits.
			ren_relocs: [dynamic]a.Relocation
			ren_errors: [dynamic]a.Error
			out: [4]u8
			defer { delete(ren_relocs); delete(ren_errors) }
			res := a.encode(insts[:], label_defs[:], out[:], &ren_relocs, &ren_errors, resolve=false)
			if !res.success {
				stats.fail_encode += 1
				if failed_examples < max_fail_print && (only_print_kind == "" || only_print_kind == "re-enc") {
					fmt.printf("  [re-enc  ] %v[%d] %08X re-encode failed\n", mn, idx, word)
					failed_examples += 1
				}
				continue
			}
			// Reassemble the produced word for comparison.
			word2: u32
			if f.mode == .A32 {
				word2 = u32(out[0]) | u32(out[1]) << 8 | u32(out[2]) << 16 | u32(out[3]) << 24
			} else if ilen == 4 {
				hi := u32(out[0]) | u32(out[1]) << 8
				lo := u32(out[2]) | u32(out[3]) << 8
				word2 = (hi << 16) | lo
			} else {
				word2 = u32(out[0]) | u32(out[1]) << 8
			}
			if (word2 & f.mask) != (word & f.mask) {
				if mnem_alias { stats.fail_mnemonic += 1 } else { stats.fail_reencode += 1 }
				if failed_examples < max_fail_print && (only_print_kind == "" || only_print_kind == "reenc!=") {
					fmt.printf("  [reenc!= ] %v[%d] in %08X out %08X mask %08X (xor %08X)\n",
						mn, idx, word, word2, f.mask, (word ~ word2) & f.mask)
					failed_examples += 1
				}
				continue
			}
			stats.ok += 1
		}
	}

	report :: proc(name: string, s: ^Sweep_Stats) {
		fmt.printf("  %s: %d total | ok=%d  decode=%d  mnem=%d  enc=%d  reenc=%d\n",
				   name, s.total, s.ok,
				   s.fail_decode, s.fail_mnemonic, s.fail_encode, s.fail_reencode)
	}
	report("A32", &a32_stats)
	report("T32", &t32_stats)
	report("T16", &t16_stats)

	grand_total := a32_stats.total + t32_stats.total + t16_stats.total
	grand_ok    := a32_stats.ok    + t32_stats.ok    + t16_stats.ok
	grand_fail  := grand_total - grand_ok
	fmt.printf("\n==> arm32 sweep: %d / %d ok (%.1f%%), %d failed\n",
			   grand_ok, grand_total, 100.0 * f32(grand_ok) / f32(grand_total), grand_fail)
	if grand_fail > 0 { fail_count += grand_fail }
}

// -----------------------------------------------------------------------------
// Safe-fill operand bits per encoding (mirror of tools/dump_verify_input.odin)
// -----------------------------------------------------------------------------
//
// Distinct registers per role so a mis-shifted field corrupts the output
// instead of accidentally aliasing another register's slot.
@(private="file")
sweep_safe_fill :: proc(enc: a.Operand_Encoding) -> u32 {
	#partial switch enc {
	// ---- A32 GPR slots ----
	case .RD:                  return u32(1) << 12
	case .RN_A32:              return u32(2) << 16
	case .RM_A32:              return u32(3)
	case .RS_A32:              return u32(4) << 8
	case .RT_A32:              return u32(1) << 12
	case .RT2_A32:             return u32(2) << 16
	case .RA_A32:              return u32(5) << 12
	case .RDLO_A32:            return u32(1) << 12
	case .RDHI_A32:            return u32(2) << 16

	// ---- T32 GPR slots ----
	case .RD_T32:              return u32(1) << 8
	case .RN_T32:              return u32(2) << 16
	// Some MVE entries fix the LSB of Rm (bit 0) to zero, so the canonical
	// word for those forms must use an even-numbered Rm (R2 = 0010). Older
	// safe-fills used R3 here, which collided with the parity constraint.
	case .RM_T32:              return u32(2)
	case .RT_T32:              return u32(1) << 12
	case .RT2_T32:             return u32(2) << 8
	case .RA_T32:              return u32(5) << 12

	// ---- T16 GPR slots ----
	case .RD_T16_LO:           return 1
	case .RM_T16_LO, .RN_T16_LO: return u32(2) << 3
	case .RD_T16_HI:           return 1
	case .RM_T16_HI:           return u32(2) << 3

	// ---- VFP/NEON split-register fields (even Q values for MVE compat) ----
	case .VD_S, .VD_D:         return u32(1) << 12
	case .VD_Q:                return u32(2) << 12
	case .VN_S, .VN_D:         return u32(2) << 16
	case .VN_Q:                return u32(4) << 16
	case .VM_S, .VM_D:         return u32(3)
	case .VM_Q:                return u32(6)

	// ---- MVE Q regs ----
	case .QD_MVE:              return u32(1) << 13
	case .QN_MVE:              return u32(2) << 17
	case .QM_MVE:              return u32(3) << 1

	// ---- Memory ----
	case .MEM_IMM12_OFFSET, .MEM_IMM8_OFFSET,
		 .MEM_PRE_INDEX, .MEM_POST_INDEX:
		return (u32(4) << 16) | (u32(1) << 23)
	case .MEM_REG_OFFSET, .MEM_DOUBLEREG:
		// Include Rm at bits 3..0 so the resulting Memory has index != R0,
		// letting the encoder pick the register-offset form on round-trip.
		return (u32(4) << 16) | (u32(1) << 23) | u32(3)
	case .MEM_LITERAL:
		return u32(1) << 23

	// ---- Register lists ----
	case .VFP_S_LIST, .VFP_D_LIST: return 4
	case .A32_REG_LIST:            return 0x0030

	// ---- Coprocessor ----
	case .COPROC_NUM_FIELD:    return u32(15) << 8
	case .COPROC_CRN_FIELD:    return u32(1) << 16
	case .COPROC_CRM_FIELD:    return 1

	// ---- Misc ----
	case .BARRIER_TYPE:        return 0xF
	case .PSR_FIELD_MASK:      return u32(0xF) << 16
	case .NEON_SHIFT_IMM6:     return u32(12) << 16
	case .NEON_SHIFT_IMM3:     return u32(1) << 16
	}
	return 0
}
