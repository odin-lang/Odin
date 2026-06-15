// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package main

// =============================================================================
// Decoder Table Verification
// =============================================================================
//
// Verifies that the generated decode tables are consistent with ENC_TABLE.
// Run with: odin run verify_tables.odin -file

import "core:fmt"
import x86 "../"

main :: proc() {
	fmt.println("Verifying decoder tables...")

	errors := 0

	// Verify ModR/M table
	fmt.println("\n--- ModR/M Table ---")
	for i in 0..<256 {
		modrm := u8(i)
		expected_mod := (modrm >> 6) & 0x3
		expected_reg := (modrm >> 3) & 0x7
		expected_rm := modrm & 0x7
		expected_has_sib := (expected_rm == 4) && (expected_mod != 3)

		expected_disp: u8 = 0
		if expected_mod == 0 && expected_rm == 5 {
			expected_disp = 4
		} else if expected_mod == 1 {
			expected_disp = 1
		} else if expected_mod == 2 {
			expected_disp = 4
		}

		info := x86.MODRM_TABLE[i]
		if info.mod != expected_mod || info.reg != expected_reg || info.rm != expected_rm ||
		   info.has_sib != expected_has_sib || info.disp_size != expected_disp {
			fmt.printf("ERROR: MODRM_TABLE[0x%02X] mismatch\n", i)
			fmt.printf("  expected: mod=%d reg=%d rm=%d has_sib=%v disp=%d\n",
					   expected_mod, expected_reg, expected_rm, expected_has_sib, expected_disp)
			fmt.printf("  got:      mod=%d reg=%d rm=%d has_sib=%v disp=%d\n",
					   info.mod, info.reg, info.rm, info.has_sib, info.disp_size)
			errors += 1
		}
	}
	fmt.printf("ModR/M table: %s\n", errors == 0 ? "PASS" : "FAIL")

	// Verify SIB table
	fmt.println("\n--- SIB Table ---")
	sib_errors := 0
	for i in 0..<256 {
		sib := u8(i)
		scale_bits := (sib >> 6) & 0x3
		expected_scale: u8 = 1 << scale_bits
		expected_index := (sib >> 3) & 0x7
		expected_base := sib & 0x7

		// index == 4 means no index
		if expected_index == 4 {
			expected_index = 0xFF
		}

		info := x86.SIB_TABLE[i]
		if info.scale != expected_scale || info.index != expected_index || info.base != expected_base {
			fmt.printf("ERROR: SIB_TABLE[0x%02X] mismatch\n", i)
			fmt.printf("  expected: scale=%d index=%d base=%d\n", expected_scale, expected_index, expected_base)
			fmt.printf("  got:      scale=%d index=%d base=%d\n", info.scale, info.index, info.base)
			sib_errors += 1
		}
	}
	errors += sib_errors
	fmt.printf("SIB table: %s\n", sib_errors == 0 ? "PASS" : "FAIL")

	// Verify decode entries match ENC_TABLE
	fmt.println("\n--- Decode Entry Consistency ---")
	entry_errors := 0

	// Check that each entry in LEGACY_DECODE_ENTRIES corresponds to something in ENC_TABLE
	for entry in x86.LEGACY_DECODE_ENTRIES {
		// Find matching encoding in ENC_TABLE
		_run := x86.ENCODE_RUNS[u16(entry.mnemonic)]
		encodings := x86.ENCODE_FORMS[_run.start:][:_run.count]
		found := false
		for enc in encodings {
			if enc.opcode == entry.opcode &&
			   enc.flags.esc == entry.esc &&
			   enc.flags.prefix == entry.prefix {
				// Check if ext matches (if applicable)
				if entry.ext != 0xFF {
					if enc.flags.modrm_reg_ext && enc.ext == entry.ext {
						found = true
						break
					}
				} else {
					if !enc.flags.modrm_reg_ext {
						found = true
						break
					}
				}
			}
		}
		if !found {
			fmt.printf("ERROR: Decode entry not found in ENC_TABLE: mnemonic=%v opcode=0x%02X esc=%v prefix=%d ext=0x%02X\n",
					   entry.mnemonic, entry.opcode, entry.esc, entry.prefix, entry.ext)
			entry_errors += 1
			if entry_errors >= 10 {
				fmt.println("  ... (truncated)")
				break
			}
		}
	}
	errors += entry_errors
	fmt.printf("Decode entries: %d entries, %s\n", len(x86.LEGACY_DECODE_ENTRIES), entry_errors == 0 ? "PASS" : "FAIL")

	// Verify index tables
	fmt.println("\n--- Index Table Verification ---")
	index_errors := 0

	// Test a few known opcodes
	test_cases := []struct{esc: x86.Escape, prefix: u8, opcode: u8, expected_mnemonic: x86.Mnemonic}{
		{.NONE, 0, 0x00, .ADD},     // ADD rm8, r8
		{.NONE, 0, 0x50, .PUSH},    // PUSH rAX
		// Note: 0x90 is XCHG EAX,EAX which is canonically NOP, but encoded as XCHG in ENCODING_TABLE
		{.NONE, 0, 0xC3, .RET},     // RET
		{.NONE, 0, 0xCC, .INT3},    // INT3
		{._0F, 0, 0xAF, .IMUL},     // IMUL r, rm
		{._0F, 0, 0x28, .MOVAPS},   // MOVAPS
	}

	for tc in test_cases {
		idx: x86.Decode_Index
		switch tc.esc {
		case .NONE:  idx = x86.DECODE_INDEX_LEGACY[(int(tc.prefix) << 8) | int(tc.opcode)]
		case ._0F:   idx = x86.DECODE_INDEX_ESC_0F[(int(tc.prefix) << 8) | int(tc.opcode)]
		case ._0F38: idx = x86.DECODE_INDEX_ESC_0F38[(int(tc.prefix) << 8) | int(tc.opcode)]
		case ._0F3A: idx = x86.DECODE_INDEX_ESC_0F3A[(int(tc.prefix) << 8) | int(tc.opcode)]
		}

		if idx.count == 0 {
			fmt.printf("ERROR: No entries for %v at esc=%v prefix=%d opcode=0x%02X\n",
					   tc.expected_mnemonic, tc.esc, tc.prefix, tc.opcode)
			index_errors += 1
		} else {
			entry := x86.LEGACY_DECODE_ENTRIES[idx.start]
			if entry.mnemonic != tc.expected_mnemonic {
				fmt.printf("ERROR: Expected %v but got %v at esc=%v prefix=%d opcode=0x%02X\n",
						   tc.expected_mnemonic, entry.mnemonic, tc.esc, tc.prefix, tc.opcode)
				index_errors += 1
			}
		}
	}
	errors += index_errors
	fmt.printf("Index tables: %s\n", index_errors == 0 ? "PASS" : "FAIL")

	// Summary
	fmt.println("\n========================================")
	if errors == 0 {
		fmt.println("All verification checks PASSED!")
	} else {
		fmt.printf("Verification FAILED with %d errors\n", errors)
	}
	fmt.println("========================================")
}
