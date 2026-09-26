// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_x86

import "base:intrinsics"

// =============================================================================
// SECTION: 7.y Form-match memoization cache (long mode)
// =============================================================================
//
// The matcher path resolves an instruction to its encoding form by linearly
// scanning the forms for its mnemonic and operand-matching each in turn -- the
// dominant cost on that path. This memoizes (mnemonic, operand-shape) -> form so
// a repeated instruction shape skips the scan after the first occurrence.
//
// The scan stays the source of truth: a miss runs it and records the result, so
// the cache can only ever return a form the scan would have. The key captures
// everything the match depends on (mnemonic + per-operand kind/class/size, with
// immediates folded to the smallest size class they fit -- exactly what
// imm_matches_inline distinguishes), so two instructions with the same key
// always match the same form.
//
// Direct-mapped and fixed-size (no allocation). Each slot packs the full 48-bit
// key and the form index into one u64, read/written with relaxed atomics: a
// reader sees either a slot whose key matches (use it) or one that doesn't
// (rescan) -- never a torn half-written entry -- so concurrent encode() calls
// stay safe. Collisions evict and rescan.

@(private) MATCH_CACHE_LOG :: 13
@(private) MATCH_CACHE_N   :: 1 << MATCH_CACHE_LOG          // 8192 slots, 64 KB
@(private) MATCH_CACHE: [MATCH_CACHE_N]u64                  // 0 = empty; else (key << 16) | (form_index + 1)

@(private, require_results)
match_hash :: #force_inline proc "contextless" (key: u64) -> u64 {
	return (key * 0x9E3779B97F4A7C15) >> (64 - MATCH_CACHE_LOG)
}

// Smallest immediate size the value fits, matching imm_matches_inline's nested
// ranges. Values in the same class match the same set of immediate forms.
@(private, require_results)
imm_value_class :: #force_inline proc "contextless" (v: i64) -> u8 {
	switch {
	case        -128 <= v && v <= 127:        return 0  // imm8sx
	case        -128 <= v && v <= 255:        return 1  // imm8 (not sign-extended)
	case      -32768 <= v && v <= 65535:      return 2  // imm16
	case -2147483648 <= v && v <= 4294967295: return 3  // imm32
	}
	return 4  // imm64
}

// Per-operand shape code: kind in bits 5-7, class/size/value-class in bits 0-4.
// ok = false means the operand can't be coded cleanly (a non-standard memory
// size); the caller then skips the cache and scans.
@(private, require_results)
op_match_code :: #force_inline proc "contextless" (op: ^Operand) -> (code: u8, ok: bool) {
	switch op.kind {
	case .NONE:
		return 0, true
	case .REGISTER:
		// Segment registers can select the encoding by their specific value
		// (push fs = 0F A0 vs push gs = 0F A8), which a class-only key can't
		// distinguish -- mark such instructions non-cacheable so the scan runs.
		if reg_class(op.reg) == REG_SEG { return 0, false }
		return (1 << 5) | u8((reg_class(op.reg) >> 8) & 0x1F), true
	case .MEMORY:
		switch op.size {
		case 1:  return (2 << 5) | 1, true
		case 2:  return (2 << 5) | 2, true
		case 4:  return (2 << 5) | 3, true
		case 8:  return (2 << 5) | 4, true
		case 10: return (2 << 5) | 5, true
		case 16: return (2 << 5) | 6, true
		case 32: return (2 << 5) | 7, true
		case 64: return (2 << 5) | 8, true
		}
		return 0, false
	case .IMMEDIATE:
		return (3 << 5) | imm_value_class(op.immediate), true
	case .RELATIVE:
		c: u8 = 0
		switch op.size {
		case 1: c = 1
		case 4: c = 2
		}
		return (4 << 5) | c, true
	}
	return 0, false
}

// Pack (mnemonic, four operand shape codes) into a 48-bit key. ok = false when
// any operand can't be coded -> the caller skips the cache for this instruction.
@(private, require_results)
match_key :: #force_inline proc "contextless" (inst: ^Instruction) -> (key: u64, ok: bool) {
	key = u64(u16(inst.mnemonic))
	for i in 0 ..< 4 {
		c, code_ok := op_match_code(&inst.ops[i])
		if !code_ok { return 0, false }
		key |= u64(c) << uint(16 + i*8)
	}
	return key, true
}

@(private, require_results)
match_cache_get :: #force_inline proc "contextless" (key: u64) -> (form_index: int, hit: bool) {
	v := intrinsics.atomic_load_explicit(&MATCH_CACHE[match_hash(key)], .Relaxed)
	if v != 0 && (v >> 16) == key {
		return int(v & 0xFFFF) - 1, true
	}
	return -1, false
}

@(private)
match_cache_put :: #force_inline proc "contextless" (key: u64, form_index: int) {
	intrinsics.atomic_store_explicit(&MATCH_CACHE[match_hash(key)], (key << 16) | u64(form_index + 1), .Relaxed)
}

// Resolve an instruction to its encoding form on the matcher path: long-mode
// cache lookup, else the linear scan, recording the result. err is .NONE on
// success. (form_index is returned but the caller currently discards it: the
// matcher path uses the interpreter to emit, not the recipe -- putting the
// recipe emit on this path costs the shared hint loop ~1.2-1.5 ns however it is
// isolated, and the cache alone already makes the matcher ~1.4x.)
//
// Deliberately NOT inlined: pulling the cache + scan out of encode()'s loop keeps
// the hot function small so the hint path that shares it isn't penalised by code
// it never runs. The matcher path eats the one call; it is the slow path anyway.
@(private)
find_form :: #force_no_inline proc "contextless" (inst: ^Instruction, mode: Mode) -> (matched_enc: ^Encoding, form_index: int, err: Error_Code) {
	form_index = -1

	cache_key: u64 = 0
	cacheable     := false
	if mode == ._64 {
		cache_key, cacheable = match_key(inst)
		if cacheable {
			if fi, hit := match_cache_get(cache_key); hit {
				return &ENCODE_FORMS[fi], fi, .NONE
			}
		}
	}

	encodings := encoding_forms(inst.mnemonic)
	if len(encodings) == 0 {
		return nil, -1, .INVALID_MNEMONIC
	}
	for &e in encodings {
		if encoding_matches_inline(inst, &e, mode) {
			matched_enc = &e
			break
		}
	}
	if matched_enc == nil {
		return nil, -1, .NO_MATCHING_ENCODING
	}

	if mode == ._64 {
		form_index = int((uintptr(matched_enc) - uintptr(&ENCODE_FORMS[0])) / size_of(Encoding))
		if cacheable {
			match_cache_put(cache_key, form_index)
		}
	}
	return matched_enc, form_index, .NONE
}
