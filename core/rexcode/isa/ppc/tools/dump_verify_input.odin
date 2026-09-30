// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package main

// =============================================================================
// PowerPC verification manifest dumper
// =============================================================================
//
// Iterates ENCODING_TABLE and writes hex files of canonical "filled" wire
// bytes plus a parallel meta file. Each line is one entry's bytes in BIG-
// ENDIAN order (PowerPC traditional). llvm-mc decodes these and we compare
// the disassembly mnemonic against ours.
//
// PPC32 and SPE share opcode space (primary opcode 4) with AltiVec/VSX. A
// real PPC implementation has either SPE OR AltiVec, never both. So we emit
// TWO separate hex files split by entry.feature:
//
//   /tmp/rexcode_ppc_main.hex   non-SPE entries  (verify with +altivec/+vsx)
//   /tmp/rexcode_ppc_spe.hex    SPE entries      (verify with +spe only)
//
// Parallel meta files keep the row-to-mnemonic mapping.
//
// Run:  cd isa/ppc && odin run tools/dump_verify_input.odin -file

import "core:fmt"
import "core:os"
import "core:strings"

import p ".."

main :: proc() {
	fmt.println("Dumping PowerPC verification manifest...")

	main_hex, main_meta, spe_hex, spe_meta: strings.Builder
	strings.builder_init(&main_hex);  defer strings.builder_destroy(&main_hex)
	strings.builder_init(&main_meta); defer strings.builder_destroy(&main_meta)
	strings.builder_init(&spe_hex);   defer strings.builder_destroy(&spe_hex)
	strings.builder_init(&spe_meta);  defer strings.builder_destroy(&spe_meta)

	n_main, n_spe: int

	for mn in p.Mnemonic {
		_run := p.ENCODE_RUNS[u16(mn)]
		for &f in p.ENCODE_FORMS[_run.start:][:_run.count] {
			bits := fill_safe_operands(&f)
			hex_buf  := &main_hex
			meta_buf := &main_meta
			if f.feature == .SPE {
				hex_buf  = &spe_hex
				meta_buf = &spe_meta
				n_spe += 1
			} else {
				n_main += 1
			}
			// PowerPC traditional BE byte order: byte 31..24 first.
			// For prefixed (POWER10 8-byte) instructions, emit the PREFIX
			// word first, then the SUFFIX word, both BE.
			if f.flags.prefixed {
				pfx := p.PREFIX_BITS_TABLE[u16(mn)] | prefix_safe_fill(&f)
				fmt.sbprintf(hex_buf, "0x%02x,0x%02x,0x%02x,0x%02x,0x%02x,0x%02x,0x%02x,0x%02x\n",
					(pfx  >> 24) & 0xFF, (pfx  >> 16) & 0xFF, (pfx  >> 8) & 0xFF, pfx  & 0xFF,
					(bits >> 24) & 0xFF, (bits >> 16) & 0xFF, (bits >> 8) & 0xFF, bits & 0xFF)
			} else {
				fmt.sbprintf(hex_buf, "0x%02x,0x%02x,0x%02x,0x%02x\n",
					(bits >> 24) & 0xFF, (bits >> 16) & 0xFF, (bits >> 8) & 0xFF, bits & 0xFF)
			}
			fmt.sbprintf(meta_buf, "%v\t%08x\t%08x\t%v\t%v\n",
				mn, f.bits, f.mask, f.feature, f.mode)
		}
	}

	_ = os.write_entire_file("/tmp/rexcode_ppc_main.hex",      main_hex.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_ppc_main_meta.txt", main_meta.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_ppc_spe.hex",       spe_hex.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_ppc_spe_meta.txt",  spe_meta.buf[:])

	// Back-compat: legacy single-file consumers still read these.
	_ = os.write_entire_file("/tmp/rexcode_ppc.hex",           main_hex.buf[:])
	_ = os.write_entire_file("/tmp/rexcode_ppc_meta.txt",      main_meta.buf[:])

	fmt.printf("Wrote %d main + %d SPE entries:\n", n_main, n_spe)
	fmt.println("  /tmp/rexcode_ppc_main.hex / _meta.txt")
	fmt.println("  /tmp/rexcode_ppc_spe.hex  / _meta.txt")
	fmt.println()
	fmt.println("Next:")
	fmt.println("  bash tools/llvm_per_line.sh /tmp/rexcode_ppc_main.hex powerpc64-unknown-linux-gnu +isa-v207-instructions,+isa-v30-instructions,+isa-v31-instructions,+altivec,+vsx,+power8-vector,+power9-vector,+power10-vector,+power8-altivec,+power9-altivec,+crypto,+mfocrf,+paired-vector-memops,+prefix-instrs,+mma,+htm,+booke > /tmp/rexcode_ppc_main_llvm.txt 2>&1")
	fmt.println("  bash tools/llvm_per_line.sh /tmp/rexcode_ppc_spe.hex powerpc-unknown-linux-gnu +spe > /tmp/rexcode_ppc_spe_llvm.txt 2>&1")
	fmt.println("  cd isa/ppc && odin run tools/verify_against_llvm.odin -file")
}

// Fill operand fields with safe values so LLVM accepts the bytes as a valid
// (decodable) instance of the form. We avoid r0 (literal-zero ambiguity in
// addressing modes) and avoid same-register pairs that LLVM might canonicalise
// into an alias mnemonic.
fill_safe_operands :: proc(f: ^p.Encoding) -> u32 {
	bits := f.bits
	for k in 0..<4 {
		bits |= operand_safe_fill(f.enc[k])
	}
	return bits
}

// Prefix-side safe-fill. The PREFIX word's 34-bit displacement (R, IMM18 at
// bits 0..17) is mostly a continuation of the SUFFIX's d16. Our safe-fill
// uses small dispatches (D=0 in d16), so the high 18 bits of the 34-bit value
// are also 0 — i.e. the prefix needs no further bits beyond PREFIX_BITS_TABLE.
prefix_safe_fill :: proc(f: ^p.Encoding) -> u32 {
	return 0
}

operand_safe_fill :: proc(enc: p.Operand_Encoding) -> u32 {
	#partial switch enc {
	// ---- Integer registers ----
	case .RT:        return (u32(3) & 0x1F) << 21    // r3
	case .RS:        return (u32(3) & 0x1F) << 21    // r3
	case .RA:        return (u32(4) & 0x1F) << 16    // r4
	case .RB:        return (u32(5) & 0x1F) << 11    // r5
	case .RC:        return (u32(6) & 0x1F) << 6     // r6

	// ---- Floating-point ----
	case .FRT:       return (u32(1) & 0x1F) << 21    // f1
	case .FRA:       return (u32(2) & 0x1F) << 16    // f2
	case .FRB:       return (u32(3) & 0x1F) << 11    // f3
	case .FRC:       return (u32(4) & 0x1F) << 6     // f4

	// ---- AltiVec vector ----
	case .VRT:       return (u32(2) & 0x1F) << 21
	case .VRA:       return (u32(3) & 0x1F) << 16
	case .VRB:       return (u32(4) & 0x1F) << 11
	case .VRC:       return (u32(5) & 0x1F) << 6

	// ---- VSX (we leave the high bit 0; values map to vs2..vs5) ----
	case .XT:        return (u32(2) & 0x1F) << 21
	case .XA:        return (u32(3) & 0x1F) << 16
	case .XB:        return (u32(4) & 0x1F) << 11
	case .XC:        return (u32(5) & 0x1F) << 6

	// ---- CR fields ----
	case .BF:        return (u32(1) & 0x7) << 23
	case .BFA:       return (u32(2) & 0x7) << 18
	case .BT:        return (u32(0) & 0x1F) << 21    // cr0[lt]
	case .BA:        return (u32(1) & 0x1F) << 16    // cr0[gt]
	case .BB:        return (u32(2) & 0x1F) << 11    // cr0[eq]
	case .BO_FIELD:  return (u32(12) & 0x1F) << 21   // BO=12 (branch if true)
	case .BI_FIELD:  return (u32(0) & 0x1F) << 16    // CR bit 0
	case .BH_FIELD:  return 0

	// ---- SPR (LR=8). PPC convention splits the 10-bit SPR field as
	//      low 5 bits → instruction bits 11..15, high 5 bits → 16..20. ----
	case .SPR_FIELD: return (u32(8) & 0x1F) << 11 | (u32(8) >> 5) << 16

	// ---- Memory addressing composites ----
	case .OFFSET_BASE_D:
		// RA=4 (avoid r0 = literal zero); D = 0 (safe)
		return (u32(4) & 0x1F) << 16
	case .OFFSET_BASE_DS:
		return (u32(4) & 0x1F) << 16
	case .OFFSET_BASE_DQ:
		return (u32(4) & 0x1F) << 16
	case .OFFSET_BASE_X:
		return (u32(4) & 0x1F) << 16 | (u32(5) & 0x1F) << 11
	case .OFFSET_VSX_X:
		return (u32(4) & 0x1F) << 16 | (u32(5) & 0x1F) << 11

	// ---- Immediates ----
	case .D16:       return 0    // already 0; safe for D-form load/store/addi
	case .UI16:      return 0
	case .DS14:      return 0
	case .DQ12:      return 0
	case .SH5:       return u32(4) << 11
	case .SH6:       return u32(4) << 11
	case .MB5:       return u32(0) << 6
	case .ME5:       return u32(31) << 1
	case .MB6:       return u32(0) << 5
	case .SIMM_5:    return u32(1) << 16
	case .UIMM_5:    return u32(1) << 16
	case .UIMM_4:    return u32(1) << 16
	case .UIMM_2:    return u32(1) << 16
	case .FXM:       return u32(0x80) << 12          // single-field mtcrf
	case .L_FIELD:   return 0
	case .TO_FIELD:  return u32(31) << 21            // trap-always
	case .NB_FIELD:  return u32(4) << 11
	case .SR_FIELD:  return u32(0) << 16
	case .CRM:       return u32(0x80) << 12
	case .DCMX:      return 0

	// ---- PC-relative (let LLVM resolve to relative-to-self) ----
	case .BRANCH_LI: return 0
	case .BRANCH_BD: return 0
	}
	return 0
}
