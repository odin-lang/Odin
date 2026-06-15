// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_mips_tests

// Encoder smoke tests. Exercises encode() end-to-end across all the
// shapes the table can produce: R-type, I-type, load/store, J-type
// jumps with relocations, branches resolved forward and backward,
// little-endian byte ordering for console targets, and a few
// out-of-range failure modes.

import "core:fmt"
import "core:os"
import mips "../"

@(private="file") epasses   := 0
@(private="file") efailures := 0

@(private="file")
load_word_be :: proc(buf: []u8, offset: u32) -> u32 {
	return  (u32(buf[offset+0]) << 24) |
			(u32(buf[offset+1]) << 16) |
			(u32(buf[offset+2]) <<  8) |
			 u32(buf[offset+3])
}

@(private="file")
load_word_le :: proc(buf: []u8, offset: u32) -> u32 {
	return   u32(buf[offset+0])        |
			(u32(buf[offset+1]) <<  8) |
			(u32(buf[offset+2]) << 16) |
			(u32(buf[offset+3]) << 24)
}

@(private="file")
check_word :: proc(name: string, got, want: u32) {
	if got == want {
		fmt.printfln("  [ok]   %-18s %08x", name, got)
		epasses += 1
	} else {
		fmt.printfln("  [FAIL] %-18s got=%08x want=%08x", name, got, want)
		efailures += 1
	}
}

@(private="file")
check_bool :: proc(name: string, got, want: bool) {
	if got == want {
		fmt.printfln("  [ok]   %-18s %v", name, got)
		epasses += 1
	} else {
		fmt.printfln("  [FAIL] %-18s got=%v want=%v", name, got, want)
		efailures += 1
	}
}

@(private="file")
check_int :: proc(name: string, got, want: int) {
	if got == want {
		fmt.printfln("  [ok]   %-18s %d", name, got)
		epasses += 1
	} else {
		fmt.printfln("  [FAIL] %-18s got=%d want=%d", name, got, want)
		efailures += 1
	}
}

run_encoder_tests :: proc() {
	fmt.println()
	fmt.println("=== MIPS encoder spot checks ===")

	code:   [256]u8
	relocs: [dynamic]mips.Relocation
	errors: [dynamic]mips.Error
	defer delete(relocs)
	defer delete(errors)

	// ---- 1. Core R-type/I-type/load/store (big-endian) -------------------
	{
		clear(&relocs)
		clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		insts := []mips.Instruction{
			mips.inst_r_r_r(.ADD,  mips.T0, mips.T1, mips.T2),       // 0x012A4020
			mips.inst_r_r_i(.ADDI, mips.T0, mips.T1, 100),           // 0x21280064
			mips.inst_r_m  (.LW,   mips.T0, mips.mem(mips.SP, 16)),  // 0x8FA80010
			mips.inst_none (.NOP),                                    // 0x00000000
			mips.inst_r_i  (.LUI,  mips.T0, 0x1234),                  // 0x3C081234
			mips.inst_shift(.SLL,  mips.T0, mips.T1, 5),              // 0x00094140
		}
		res := mips.encode(insts, nil, code[:], &relocs, &errors)

		check_bool("core: success",       res.success,     true)
		check_int ("core: byte_count",    int(res.byte_count), 24)
		check_int ("core: errors len",    len(errors),     0)
		check_int ("core: relocs len",    len(relocs),     0)
		check_word("core: ADD t0,t1,t2",  load_word_be(code[:], 0),  0x012A4020)
		check_word("core: ADDI t0,t1,100",load_word_be(code[:], 4),  0x21280064)
		check_word("core: LW t0,16(sp)",  load_word_be(code[:], 8),  0x8FA80010)
		check_word("core: NOP",           load_word_be(code[:], 12), 0x00000000)
		check_word("core: LUI t0,0x1234", load_word_be(code[:], 16), 0x3C081234)
		check_word("core: SLL t0,t1,5",   load_word_be(code[:], 20), 0x00094140)
	}

	// ---- 2. Little-endian (PS1/PS2/PSP path) ------------------------------
	{
		clear(&relocs)
		clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		insts := []mips.Instruction{
			mips.inst_r_r_r(.ADD, mips.T0, mips.T1, mips.T2),
		}
		res := mips.encode(insts, nil, code[:], &relocs, &errors,
						   endianness = .LITTLE)

		check_bool("LE: success", res.success, true)
		check_word("LE: ADD (le bytes)",
				   load_word_le(code[:], 0),   // reads as native u32 little-endian
				   0x012A4020)
		// Verify the raw bytes are byte-swapped relative to BE.
		check_word("LE: ADD (be view)",
				   load_word_be(code[:], 0),
				   0x20402A01)
	}

	// ---- 3. Branch resolution: backward reference -------------------------
	//   loop:    NOP                    pc=0
	//            ADDIU t0, t0, 1        pc=4
	//            BNE   t0, zero, loop   pc=8 -> rel = -3 words
	//            NOP                    pc=12 (delay slot)
	{
		clear(&relocs)
		clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		label_defs := [dynamic]mips.Label_Definition{}
		defer delete(label_defs)
		append(&label_defs, mips.Label_Definition(0))   // loop at inst 0

		insts := []mips.Instruction{
			mips.inst_none(.NOP),
			mips.inst_r_r_i(.ADDIU, mips.T0, mips.T0, 1),
			mips.inst_branch2(.BNE, mips.T0, mips.ZERO, 0),
			mips.inst_none(.NOP),
		}
		res := mips.encode(insts, label_defs[:], code[:], &relocs, &errors)

		// BNE t0, zero, -3 = (op=5 << 26) | (rs=8 << 21) | (rt=0 << 16) | 0xFFFD
		//                   = 0x14000000 | 0x01000000 | 0xFFFD
		//                   = 0x1500FFFD
		check_bool("brB: success",   res.success,    true)
		check_int ("brB: relocs len",len(relocs),    0)         // resolved
		check_int ("brB: errors len",len(errors),    0)
		check_word("brB: BNE -3w",   load_word_be(code[:], 8), 0x1500FFFD)
		// label_defs[0] should now be byte offset 0.
		check_int ("brB: label_def[0]", int(label_defs[0]), 0)
	}

	// ---- 4. Branch resolution: forward reference --------------------------
	//   BEQ   t0, t1, target    pc=0 -> rel = +2 words
	//   NOP                     pc=4
	//   NOP                     pc=8
	//   target: ADD t2,t2,t2    pc=12 (inst 3)
	{
		clear(&relocs)
		clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		label_defs := [dynamic]mips.Label_Definition{}
		defer delete(label_defs)
		append(&label_defs, mips.Label_Definition(3))   // forward to inst 3

		insts := []mips.Instruction{
			mips.inst_branch2(.BEQ, mips.T0, mips.T1, 0),
			mips.inst_none(.NOP),
			mips.inst_none(.NOP),
			mips.inst_r_r_r(.ADD, mips.T2, mips.T2, mips.T2),
		}
		res := mips.encode(insts, label_defs[:], code[:], &relocs, &errors)

		// BEQ t0,t1,+2 = 0x10000000 | (8<<21) | (9<<16) | 0x0002 = 0x11090002
		check_bool("brF: success",   res.success,    true)
		check_int ("brF: relocs len",len(relocs),    0)
		check_word("brF: BEQ +2w",   load_word_be(code[:], 0), 0x11090002)
		check_int ("brF: label_def[0]", int(label_defs[0]), 12)
	}

	// ---- 5. J-type with base_address ---------------------------------------
	//   J target   (where target lives at inst index 4 -> byte offset 16)
	//   base_address = 0x80000000  => target_abs = 0x80000010
	//   The encoded 26-bit field carries (target_abs >> 2) & 0x3FFFFFF;
	//   the upper 4 region bits (0x2 here) come from PC at run-time.
	//   word = 0x08000000 | (0x80000010 >> 2 & 0x3FFFFFF)
	//        = 0x08000000 | 0x00000004 = 0x08000004
	{
		clear(&relocs)
		clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		label_defs := [dynamic]mips.Label_Definition{}
		defer delete(label_defs)
		append(&label_defs, mips.Label_Definition(4))

		insts := []mips.Instruction{
			mips.inst_jump(.J, 0),
			mips.inst_none(.NOP),
			mips.inst_none(.NOP),
			mips.inst_none(.NOP),
			mips.inst_none(.NOP),   // target
		}
		res := mips.encode(insts, label_defs[:], code[:], &relocs, &errors,
						   base_address = 0x80000000)

		check_bool("J: success",      res.success,    true)
		check_int ("J: relocs len",   len(relocs),    0)
		check_word("J: encoded",      load_word_be(code[:], 0), 0x08000004)
	}

	// ---- 6. Unresolved relocation survives encode() with resolve=false ----
	{
		clear(&relocs)
		clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		label_defs := [dynamic]mips.Label_Definition{}
		defer delete(label_defs)
		append(&label_defs, mips.LABEL_UNDEFINED)   // never defined

		insts := []mips.Instruction{
			mips.inst_branch2(.BEQ, mips.T0, mips.T1, 0),
		}
		res := mips.encode(insts, label_defs[:], code[:], &relocs, &errors)

		check_bool("unres: success",      res.success,    true)
		check_int ("unres: relocs left",  len(relocs),    1)   // kept for linker
		check_int ("unres: errors len",   len(errors),    0)
	}

	// ---- 7. Branch out of range (after pass 2) ----------------------------
	//   BEQ to a label 200K bytes away -> rel >> 2 won't fit in i16.
	//   This requires synthesizing the label_def manually because no
	//   instruction stream of this size is being encoded here.
	{
		clear(&relocs)
		clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		// Synthesize: BEQ at inst 0, label resolves to inst index 100_000
		// (byte offset 400_000), which is way out of the i16<<2 = ±128KB
		// range.
		label_defs := [dynamic]mips.Label_Definition{}
		defer delete(label_defs)
		append(&label_defs, mips.Label_Definition(100_000))

		insts := []mips.Instruction{
			mips.inst_branch2(.BEQ, mips.T0, mips.T1, 0),
		}
		res := mips.encode(insts, label_defs[:], code[:], &relocs, &errors)

		check_bool("OOR: success",     res.success,    false)   // had errors
		check_int ("OOR: relocs len",  len(relocs),    0)        // patched (truncated)
		check_int ("OOR: errors len",  len(errors),    1)
		// Error code should be LABEL_OUT_OF_RANGE.
		check_bool("OOR: error code",
				   len(errors) > 0 && errors[0].code == .LABEL_OUT_OF_RANGE,
				   true)
	}

	// ---- 8. Buffer overflow ------------------------------------------------
	{
		clear(&relocs)
		clear(&errors)

		insts := []mips.Instruction{
			mips.inst_none(.NOP),
			mips.inst_none(.NOP),
		}
		small_code: [4]u8
		res := mips.encode(insts, nil, small_code[:], &relocs, &errors)

		check_bool("OVF: success",    res.success,    false)
		check_int ("OVF: errors len", len(errors),    1)
		check_bool("OVF: error code",
				   len(errors) > 0 && errors[0].code == .BUFFER_OVERFLOW,
				   true)
	}

	// ---- 9. FPU triple-operand: ADD.S f4, f5, f6 --------------------------
	//   ADD.S form: {FD, FS, FT}, bits = 0x46000000 (fmt=S baked in).
	//   FD=4 at bits 10-6:  4 << 6  = 0x00000100
	//   FS=5 at bits 15-11: 5 << 11 = 0x00002800
	//   FT=6 at bits 20-16: 6 << 16 = 0x00060000
	//   word = 0x46000000 | 0x00060000 | 0x00002800 | 0x00000100 = 0x46062900
	{
		clear(&relocs)
		clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		insts := []mips.Instruction{
			mips.inst_r_r_r(.ADD_S, mips.F4, mips.F5, mips.F6),
		}
		res := mips.encode(insts, nil, code[:], &relocs, &errors)

		check_bool("FPU: success",  res.success, true)
		check_word("FPU: ADD.S",    load_word_be(code[:], 0), 0x46062900)
	}

	// ---- 10. GTE: RTPS (canonical cofun zero) -----------------------------
	//   Bits 0x4A000001, no operands, canonical.
	{
		clear(&relocs)
		clear(&errors)
		for i in 0..<len(code) { code[i] = 0 }

		insts := []mips.Instruction{
			mips.inst_none(.RTPS),
		}
		res := mips.encode(insts, nil, code[:], &relocs, &errors)

		check_bool("GTE: success",  res.success, true)
		check_word("GTE: RTPS",     load_word_be(code[:], 0), 0x4A000001)
	}

	fmt.println()
	fmt.printfln("==> encoder: %d passed, %d failed", epasses, efailures)
	if efailures > 0 { os.exit(1) }
}
