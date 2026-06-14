package main

// =============================================================================
// AArch32 verification manifest dumper
// =============================================================================
//
// Iterates ENCODING_TABLE and writes hex files of canonical "filled" wire
// bytes plus a parallel meta file. The filled bytes have safe non-zero
// operand values written in so LLVM can decode them (a base-bits-only dump
// hits many UNDEFINED encodings where Rd=R0/PC etc. clash with reserved
// patterns).
//
// Outputs:
//   /tmp/rexcode_arm32_a32.hex  / _meta.txt   -- 4-byte A32 instructions
//   /tmp/rexcode_arm32_t32w.hex / _meta.txt   -- T32 32-bit (high half first)
//   /tmp/rexcode_arm32_t16.hex  / _meta.txt   -- T16 16-bit (2-byte halfword)
//
// Run:  cd arm32 && odin run tools/dump_verify_input.odin -file

import "core:fmt"
import "core:os"
import "core:strings"

import a "../"

main :: proc() {
	fmt.println("Dumping AArch32 verification manifest...")

	a32_hex, a32_meta:   strings.Builder
	t32_hex, t32_meta:   strings.Builder
	t16_hex, t16_meta:   strings.Builder
	strings.builder_init(&a32_hex); strings.builder_init(&a32_meta)
	strings.builder_init(&t32_hex); strings.builder_init(&t32_meta)
	strings.builder_init(&t16_hex); strings.builder_init(&t16_meta)
	defer { strings.builder_destroy(&a32_hex);  strings.builder_destroy(&a32_meta) }
	defer { strings.builder_destroy(&t32_hex);  strings.builder_destroy(&t32_meta) }
	defer { strings.builder_destroy(&t16_hex);  strings.builder_destroy(&t16_meta) }

	n_a32, n_t32, n_t16 := 0, 0, 0

	for mn in a.Mnemonic {
		for &f in a.ENCODING_TABLE[mn] {
			bits := fill_safe_operands(&f)
			ilen := a.inst_size_from_bits(f.bits, f.mode)
			if f.mode == .A32 {
				// Bake AL cond for conditional A32 entries
				if (f.mask >> 28) == 0 {
					bits = (bits & 0x0FFFFFFF) | (0xE << 28)
				}
				emit_le_bytes(&a32_hex, bits, 4)
				fmt.sbprintf(&a32_meta, "%v\t%08x\t%08x\t%v\n", mn, f.bits, f.mask, f.feature)
				n_a32 += 1
			} else if ilen == 4 {
				hi := u16(bits >> 16)
				lo := u16(bits & 0xFFFF)
				fmt.sbprintf(&t32_hex, "0x%02x,0x%02x,0x%02x,0x%02x\n",
					hi & 0xFF, (hi >> 8) & 0xFF,
					lo & 0xFF, (lo >> 8) & 0xFF)
				fmt.sbprintf(&t32_meta, "%v\t%08x\t%08x\t%v\n", mn, f.bits, f.mask, f.feature)
				n_t32 += 1
			} else {
				v := u16(bits & 0xFFFF)
				fmt.sbprintf(&t16_hex, "0x%02x,0x%02x\n",
					v & 0xFF, (v >> 8) & 0xFF)
				fmt.sbprintf(&t16_meta, "%v\t%08x\t%08x\t%v\n", mn, f.bits, f.mask, f.feature)
				n_t16 += 1
			}
		}
	}

	_ = os.write_entire_file("/tmp/rexcode_arm32_a32.hex",       a32_hex.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_arm32_a32_meta.txt",  a32_meta.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_arm32_t32w.hex",      t32_hex.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_arm32_t32w_meta.txt", t32_meta.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_arm32_t16.hex",       t16_hex.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_arm32_t16_meta.txt",  t16_meta.buf[:])

	fmt.printf("Wrote A32=%d T32-wide=%d T16=%d entries:\n", n_a32, n_t32, n_t16)
	fmt.println("  /tmp/rexcode_arm32_a32.hex / _meta.txt")
	fmt.println("  /tmp/rexcode_arm32_t32w.hex / _meta.txt")
	fmt.println("  /tmp/rexcode_arm32_t16.hex / _meta.txt")
	fmt.println()
	fmt.println("Next steps:")
	fmt.println("  llvm-mc --disassemble -triple=arm-none-eabi   -mattr=+armv8,+neon,+vfp4,+crc,+crypto < /tmp/rexcode_arm32_a32.hex   > /tmp/rexcode_arm32_a32_llvm.txt   2>&1")
	fmt.println("  llvm-mc --disassemble -triple=thumbv8-none-eabi -mattr=+v8.1m.main,+mve.fp,+fp.dp,+vfp4 < /tmp/rexcode_arm32_t32w.hex > /tmp/rexcode_arm32_t32w_llvm.txt 2>&1")
	fmt.println("  llvm-mc --disassemble -triple=thumbv8-none-eabi -mattr=+v8.1m.main,+mve.fp,+fp.dp,+vfp4 < /tmp/rexcode_arm32_t16.hex  > /tmp/rexcode_arm32_t16_llvm.txt  2>&1")
	fmt.println("Then:  cd arm32 && odin run tools/verify_against_llvm.odin -file")
}

// Fill in safe non-zero values for operand fields so LLVM can decode without
// hitting UNPREDICTABLE/reserved patterns.
//
// Safe values:
//   GPR slots:    Rd=R1, Rn=R2, Rm=R3, Rs=R4, Rt=R1, Rt2=R2, Ra=R5
//   VFP S regs:   S1/S2/S3
//   VFP D regs:   D1/D2/D3
//   NEON Q regs:  Q1/Q2/Q3
//   Immediates:   0 (already in base bits)
fill_safe_operands :: proc(f: ^a.Encoding) -> u32 {
	bits := f.bits
	for k in 0..<4 {
		bits |= operand_safe_fill(f.enc[k])
	}
	return bits
}

operand_safe_fill :: proc(enc: a.Operand_Encoding) -> u32 {
	#partial switch enc {
	// ---- A32 GPR slots ----
	case .RD:                  return u32(1) << 12     // R1
	case .RN_A32:              return u32(2) << 16     // R2
	case .RM_A32:              return u32(3)           // R3
	case .RS_A32:              return u32(4) << 8      // R4
	case .RT_A32:              return u32(1) << 12     // R1
	case .RT2_A32:             return 0                // implicit
	case .RA_A32:              return u32(5) << 12     // R5
	case .RDLO_A32:            return u32(1) << 12     // R1
	case .RDHI_A32:            return u32(2) << 16     // R2

	// ---- T32 GPR slots ----
	case .RD_T32:              return u32(1) << 8      // R1 (low halfword bits 11:8)
	case .RN_T32:              return u32(2) << 16     // R2 (high halfword bits 19:16)
	case .RM_T32:              return u32(3)           // R3
	case .RT_T32:              return u32(1) << 12     // R1
	case .RT2_T32:             return u32(2) << 8      // R2
	case .RA_T32:              return u32(5) << 12     // R5

	// ---- T16 GPR slots (low 3 bits each, except hi-reg forms) ----
	case .RD_T16_LO:           return 1                // R1
	case .RM_T16_LO, .RN_T16_LO: return u32(2) << 3    // R2
	case .RD_T16_HI:           return 1                // R1 (low 3 bits)
	case .RM_T16_HI:           return u32(2) << 3      // R2 in bits 6:3

	// ---- VFP/NEON split-register fields ----
	// For S/D registers: hw index 1/2/3.
	// For Q registers: each Q is two D-regs so safe Q values are EVEN
	// (Q1 = D2/D3 → Vd=2; Q2 = D4/D5 → Vn=4; Q3 = D6/D7 → Vm=6). This also
	// satisfies MVE Q-encoding which expects bits 15:13 = Qd[2:0] with bit
	// 12 = 0 (and our NEON-style packing makes bit 12 = 0 when Vd is even).
	case .VD_S, .VD_D:         return u32(1) << 12     // S1/D1
	case .VD_Q:                return u32(2) << 12     // Q1 = D2:D3
	case .VN_S, .VN_D:         return u32(2) << 16     // S2/D2
	case .VN_Q:                return u32(4) << 16     // Q2 = D4:D5
	case .VM_S, .VM_D:         return u32(3)           // S3/D3
	case .VM_Q:                return u32(6)           // Q3 = D6:D7

	// ---- MVE Q regs (3-bit) ----
	case .QD_MVE:              return u32(1) << 13
	case .QN_MVE:              return u32(2) << 17
	case .QM_MVE:              return u32(3) << 1

	// ---- Memory (use [R4, #0]) ----
	case .MEM_IMM12_OFFSET, .MEM_IMM8_OFFSET, .MEM_REG_OFFSET, .MEM_DOUBLEREG:
		return (u32(4) << 16) | (u32(1) << 23)         // base R4, U=1
	case .MEM_LITERAL:
		return u32(1) << 23                            // U=1, base R15 implicit

	// ---- VFP/NEON list count (use 4 regs) ----
	case .VFP_S_LIST, .VFP_D_LIST: return 4

	// ---- A32 reg list (PUSH/POP/LDM/STM) ----
	case .A32_REG_LIST:        return 0x0030          // {R4, R5}

	// ---- Coprocessor ----
	// Use p15 (system control): p10/p11 are VFP/NEON aliases and LLVM rejects
	// MCR/MRC/MCRR/MRRC/CDP/LDC/STC with those numbers as ambiguous with VFP
	// ops. p7 was tested but some CRn/OPC1/OPC2 combinations are still
	// rejected as UNPREDICTABLE on disassembly. p15 accepts the broadest set.
	case .COPROC_NUM_FIELD:    return u32(15) << 8
	case .COPROC_OPC1_FIELD:   return 0
	case .COPROC_OPC2_FIELD:   return 0
	case .COPROC_CRN_FIELD:    return u32(1) << 16     // c1
	case .COPROC_CRM_FIELD:    return 1                // c1

	// ---- CDE ----
	case .CDE_COPROC_FIELD:    return 0
	case .CDE_IMM_FIELD:       return 0
	case .CDE_ACC_FIELD:       return 0

	// ---- Misc ----
	case .A32_COND_FIELD: return 0              // (cond baked separately)
	case .NEON_CMODE:          return 0
	case .NEON_OP_BIT:         return 0
	case .HINT_FIELD, .IT_MASK, .CPS_IFLAGS, .SYSM_FIELD: return 0
	case .BARRIER_TYPE:        return 0xF              // SY barrier
	case .PSR_FIELD_MASK:      return u32(0xF) << 16   // _all field
	// NEON_SHIFT_IMM6: imm6 encoding = (size_const - actual_shift). For .I8
	// safe shift=4 → imm6 = 16-4 = 12 (decimal) = 0b001100, fits in bits 19:16.
	case .NEON_SHIFT_IMM6:     return u32(12) << 16
	case .NEON_SHIFT_IMM3:     return u32(1) << 16
	}
	return 0
}

emit_le_bytes :: proc(sb: ^strings.Builder, v: u32, n: int) {
	fmt.sbprintf(sb, "0x%02x", v & 0xFF)
	if n > 1 { fmt.sbprintf(sb, ",0x%02x", (v >> 8) & 0xFF) }
	if n > 2 { fmt.sbprintf(sb, ",0x%02x", (v >> 16) & 0xFF) }
	if n > 3 { fmt.sbprintf(sb, ",0x%02x", (v >> 24) & 0xFF) }
	strings.write_byte(sb, '\n')
}
