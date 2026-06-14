package rexcode_ppc_tests

import "core:fmt"
import "core:os"
import p ".."

// Iterate every entry in the encoding table, build a canonical wire word
// from base bits + safe-fill operand values, and verify the decoder finds
// SOME mnemonic. Stronger check: the decoder finds the SAME mnemonic
// (modulo bake-everything entries where many mnemonics share bit patterns).

run_decode_sweep :: proc() {
	fmt.println("==== ppc decode sweep ====")

	ok_total, missing_mn_total, wrong_mn_total: int

	for mn in p.Mnemonic {
		forms := p.ENCODING_TABLE[mn]
		for &f in forms {
			// Build a canonical word — base bits | safe-fill operands.
			// Safe-fill values mirror dump_verify_input.odin.
			word := f.bits
			for k in 0..<4 {
				word |= safe_fill(f.enc[k])
			}

			// Decode it
			buf: [8]u8
			buf[0] = u8(word >> 24)
			buf[1] = u8(word >> 16)
			buf[2] = u8(word >> 8)
			buf[3] = u8(word)
			ilen := 4
			if f.flags.prefixed {
				pfx := p.PREFIX_BITS_TABLE[mn]
				buf[0] = u8(pfx >> 24); buf[1] = u8(pfx >> 16); buf[2] = u8(pfx >> 8); buf[3] = u8(pfx)
				buf[4] = u8(word >> 24); buf[5] = u8(word >> 16); buf[6] = u8(word >> 8); buf[7] = u8(word)
				ilen = 8
			}

			decoded: [dynamic]p.Instruction
			info:    [dynamic]p.Instruction_Info
			labels:  [dynamic]p.Label_Definition
			errors:  [dynamic]p.Error
			defer delete(decoded); defer delete(info); defer delete(labels); defer delete(errors)

			r := p.decode(buf[:ilen], nil, &decoded, &info, &labels, &errors, .PPC64)
			if !r.success || len(decoded) == 0 || (len(decoded) > 0 && decoded[0].mnemonic == .INVALID) {
				if missing_mn_total < 20 {
					fmt.printf("  [UNDECODABLE] %v  word=%08x prefixed=%v\n", mn, word, f.flags.prefixed)
				}
				missing_mn_total += 1
				continue
			}
			got := decoded[0].mnemonic
			if got == mn {
				ok_total += 1
			} else {
				if wrong_mn_total < 20 {
					fmt.printf("  [WRONG] %v -> %v  word=%08x\n", mn, got, word)
				}
				wrong_mn_total += 1
			}
		}
	}

	total := ok_total + missing_mn_total + wrong_mn_total
	fmt.printf("\n[TOTAL] %d entries\n", total)
	fmt.printf("    OK:              %d  (%.1f%%)\n", ok_total,         100.0 * f32(ok_total)         / f32(total))
	fmt.printf("    WRONG_MNEMONIC:  %d  (%.1f%%)\n", wrong_mn_total,   100.0 * f32(wrong_mn_total)   / f32(total))
	fmt.printf("    UNDECODABLE:     %d  (%.1f%%)\n", missing_mn_total, 100.0 * f32(missing_mn_total) / f32(total))
	if missing_mn_total > 0 { os.exit(1) }
}

safe_fill :: proc(enc: p.Operand_Encoding) -> u32 {
	#partial switch enc {
	case .RT, .RS:        return (u32(3) & 0x1F) << 21
	case .RA:             return (u32(4) & 0x1F) << 16
	case .RB:             return (u32(5) & 0x1F) << 11
	case .RC:             return (u32(6) & 0x1F) << 6
	case .FRT:            return (u32(1) & 0x1F) << 21
	case .FRA:            return (u32(2) & 0x1F) << 16
	case .FRB:            return (u32(3) & 0x1F) << 11
	case .FRC:            return (u32(4) & 0x1F) << 6
	case .VRT:            return (u32(2) & 0x1F) << 21
	case .VRA:            return (u32(3) & 0x1F) << 16
	case .VRB:            return (u32(4) & 0x1F) << 11
	case .VRC:            return (u32(5) & 0x1F) << 6
	case .XT:             return (u32(2) & 0x1F) << 21
	case .XA:             return (u32(3) & 0x1F) << 16
	case .XB:             return (u32(4) & 0x1F) << 11
	case .XC:             return (u32(5) & 0x1F) << 6
	case .BF:             return (u32(1) & 0x7) << 23
	case .BFA:            return (u32(2) & 0x7) << 18
	case .BT:             return (u32(0) & 0x1F) << 21
	case .BA:             return (u32(1) & 0x1F) << 16
	case .BB:             return (u32(2) & 0x1F) << 11
	case .BO_FIELD:       return (u32(12) & 0x1F) << 21
	case .BI_FIELD:       return (u32(0) & 0x1F) << 16
	case .BH_FIELD:       return 0
	case .SPR_FIELD:      return (u32(8) & 0x1F) << 11 | (u32(8) >> 5) << 16
	case .OFFSET_BASE_D, .OFFSET_BASE_DS, .OFFSET_BASE_DQ:
		return (u32(4) & 0x1F) << 16
	case .OFFSET_BASE_X, .OFFSET_VSX_X:
		return (u32(4) & 0x1F) << 16 | (u32(5) & 0x1F) << 11
	case .D16, .UI16, .DS14, .DQ12: return 0
	case .SH5:            return u32(4) << 11
	case .SH6:            return u32(4) << 11
	case .MB5:            return u32(0) << 6
	case .ME5:            return u32(31) << 1
	case .MB6:            return u32(0) << 5
	case .SIMM_5, .UIMM_5, .UIMM_4, .UIMM_2: return u32(1) << 16
	case .FXM:            return u32(0x80) << 12
	case .L_FIELD:        return 0
	case .TO_FIELD:       return u32(31) << 21
	case .NB_FIELD:       return u32(4) << 11
	case .SR_FIELD:       return 0
	case .CRM:            return u32(0x80) << 12
	case .DCMX:           return 0
	case .BRANCH_LI, .BRANCH_BD: return 0
	}
	return 0
}
