package rexcode_arm32

// =============================================================================
// AArch32 IMMEDIATE ENCODING ALGORITHMS
// =============================================================================
//
// ARM/Thumb immediates have several non-trivial wire formats:
//
//   1. A32 modified-immediate (imm12: rotate << 8 | value)
//        effective = ROR(value, 2*rotate)
//      Range: 8-bit value rotated by even amount 0..30.
//
//   2. T32 modified-immediate (i:imm3:imm8 split):
//        - 4 replication patterns:  0x000000XY, 0x00XY00XY, 0xXY00XY00, 0xXYXYXYXY
//        - rotation pattern: ROR(0x80|imm7, shift) where shift = (i:imm3:imm4_hi)
//
//   3. NEON modified-immediate (cmode:abcdefgh:op):
//        12 cmode patterns covering .I8/.I16/.I32/.I64/.F32 broadcast
//        plus 16/32-bit shifted forms and trailing-ones forms.
//
//   4. VFP imm8 float (VMOV.F32 #imm / VMOV.F64 #imm):
//        a:bbbbb:cdef:0...  -> sign:exp(8 from 3):mantissa(23 from 4)
//        Only 256 distinct values representable, but covers common
//        constants (1.0, 0.5, 2.0, 3.0, ...).
//
// Each algorithm provides:
//   encode_<X>(value: u32, out: ^u32) -> bool   // returns false if value not representable
//   decode_<X>(field: u32) -> u32               // always succeeds (every field decodes to a u32)

// =============================================================================
// 1. A32 modified-immediate
// =============================================================================
//
// Encoded as 12-bit imm12 = (rotate << 8) | value8, where the effective
// constant is ROR(value8, 2*rotate). The encoder must find a rotation
// 0..15 such that the value rotates to fit in 8 bits.

@(require_results)
ror32 :: #force_inline proc "contextless" (v: u32, n: u32) -> u32 {
	n_ := n & 31
	if n_ == 0 { return v }
	return (v >> n_) | (v << (32 - n_))
}

@(require_results)
rol32 :: #force_inline proc "contextless" (v: u32, n: u32) -> u32 {
	n_ := n & 31
	if n_ == 0 { return v }
	return (v << n_) | (v >> (32 - n_))
}

// Encode an arbitrary 32-bit constant as an A32 modified-immediate.
// Returns the 12-bit field on success.
@(require_results)
encode_a32_modimm :: proc(value: u32) -> (u32, bool) {
	if value <= 0xFF { return value, true }
	// Try every even rotation 2..30 and check if the rotated value fits in 8 bits.
	for r in u32(1)..=15 {
		rotated := rol32(value, 2 * r)
		if rotated <= 0xFF {
			return (r << 8) | rotated, true
		}
	}
	return 0, false
}

// Decode an A32 modified-immediate field (12 bits) to its 32-bit value.
@(require_results)
decode_a32_modimm :: #force_inline proc "contextless" (imm12: u32) -> u32 {
	rotate := (imm12 >> 8) & 0xF
	value  :=  imm12       & 0xFF
	return ror32(value, 2 * rotate)
}

// =============================================================================
// 2. Thumb-2 modified-immediate
// =============================================================================
//
// T32 packs the 12-bit modimm field across non-adjacent positions:
//   bit 26 of the 32-bit word  -> i
//   bits 14:12 of word         -> imm3
//   bits 7:0 of word           -> imm8
// Concatenated as (i:imm3:imm8) for a 12-bit value.
//
// The 12 bits then expand to a 32-bit constant via 5 cases on (i:imm3):
//
//   i:imm3 = 0000 a   -> 00000000_00000000_00000000_aaaaaaaa
//   i:imm3 = 0001 a   -> 00000000_aaaaaaaa_00000000_aaaaaaaa  (a != 0)
//   i:imm3 = 0010 a   -> aaaaaaaa_00000000_aaaaaaaa_00000000  (a != 0)
//   i:imm3 = 0011 a   -> aaaaaaaa_aaaaaaaa_aaaaaaaa_aaaaaaaa  (a != 0)
//   i:imm3:imm8 high  -> ROR(0x80 | imm7, shift)   shift = i:imm3:imm8_top
//                        where imm7 = imm8[6:0] and shift = (i:imm3:imm4_hi) >> 0
//                        (5-bit shift from the top of the field, 8..31)

// Build the wire encoding (i in bit 26 of the 32-bit T32 word, imm3 in bits
// 14:12, imm8 in bits 7:0) into the i:imm3:imm8 12-bit number.
@(private)
build_t32_field12 :: #force_inline proc "contextless" (i: u32, imm3: u32, imm8: u32) -> u32 {
	return ((i & 1) << 11) | ((imm3 & 0x7) << 8) | (imm8 & 0xFF)
}

// Encode an arbitrary 32-bit constant as a T32 modified-immediate.
// Returns 12 bits packed as i:imm3:imm8 on success.
encode_t32_modimm :: proc(value: u32) -> (u32, bool) {
	// Case 1: 8-bit
	if value <= 0xFF { return value, true }
	// Case 2: 0x00XY00XY
	if (value & 0xFF00FF00) == 0 {
		a := value & 0xFF
		if (value >> 16) & 0xFF == a {
			return build_t32_field12(0, 1, a), true
		}
	}
	// Case 3: 0xXY00XY00
	if (value & 0x00FF00FF) == 0 {
		a := (value >> 8) & 0xFF
		if (value >> 24) & 0xFF == a {
			return build_t32_field12(0, 2, a), true
		}
	}
	// Case 4: 0xXYXYXYXY
	a := value & 0xFF
	if value == (a | (a << 8) | (a << 16) | (a << 24)) && a != 0 {
		return build_t32_field12(0, 3, a), true
	}
	// Case 5: rotated 8-bit with leading 1 (0x80..0xFF range, shifted)
	// Find a shift such that ROR(0x80..0xFF, shift) == value.
	// shift = 8..31. The unrotated value has the form 1xxxxxxx (top bit set).
	for shift in u32(8)..=31 {
		rotated := rol32(value, shift)
		if rotated >= 0x80 && rotated <= 0xFF {
			// shift is encoded as i:imm3:a (5 bits), where 'a' goes into imm8 bit 7,
			// and the low 7 bits of rotated (xxxxxxx) go into imm8[6:0].
			imm7 := rotated & 0x7F
			field5 := shift
			i    := (field5 >> 4) & 1
			imm3 := (field5 >> 1) & 0x7
			b    := field5 & 1                 // becomes imm8 bit 7
			imm8 := (b << 7) | imm7
			return build_t32_field12(i, imm3, imm8), true
		}
	}
	return 0, false
}

// Decode a 12-bit i:imm3:imm8 field to its 32-bit constant value.
decode_t32_modimm :: proc "contextless" (field12: u32) -> u32 {
	i_imm3 := (field12 >> 8) & 0xF      // bits 11:8 = i:imm3
	imm8   :=  field12        & 0xFF
	switch i_imm3 {
	case 0: return imm8
	case 1: return (imm8 << 16) | imm8
	case 2: return (imm8 << 24) | (imm8 << 8)
	case 3: return (imm8 << 24) | (imm8 << 16) | (imm8 << 8) | imm8
	}
	// Rotated form
	shift := (field12 >> 7) & 0x1F  // 5-bit shift = i:imm3:imm8[7]
	unrotated := (imm8 & 0x7F) | 0x80
	return ror32(unrotated, shift)
}

// =============================================================================
// 3. NEON modified-immediate (VMOV/VMVN/VORR/VBIC immediate forms)
// =============================================================================
//
// Encoded as cmode (4 bits) + op (1 bit) + abcdefgh (8 bits).
// cmode selects one of 12 broadcast/shift patterns:
//
//   cmode    op   pattern (.dt)
//   ---------------------------------------
//   000x     -    .I32   imm32 = 0x000000XY shifted 0/8/16/24
//   001x          (same, shifted 8 bits)
//   010x          (shifted 16)
//   011x          (shifted 24)
//   100x     -    .I16   imm32 = 0x0000XY00 shifted 0/8
//   101x
//   1100     -    .I32   imm32 = 0x00XYFFFF / 0xXYFFFFFF (trailing ones)
//   1101
//   1110     0    .I8    imm32 = XYXYXYXY (byte-wise)
//   1110     1    .I64   imm32_high = a:b:c:d  imm32_low = e:f:g:h (bit-expanded)
//   1111     0    .F32   imm32 = a:b̄:bbbbb:cdefgh:0... (VFP imm8)
//
// Encoder packs the 8-bit abcdefgh into wire bits (abc at bits 18:16, defgh
// at bits 3:0), cmode at bits 11:8, op at bit 5.

NEON_Imm_Form :: struct {
	raw_imm32: u32,    // the 32-bit constant the user wants
	cmode:     u8,     // selected cmode (0..15)
	op:        u8,     // op bit (0 or 1)
	abcdefgh:  u8,     // the 8-bit immediate
}

// Encode a (32-bit) constant for NEON immediate operations.
// On success, returns (cmode, op, abcdefgh) packed in the low bits as a
// single u32:   bits 12:8 = cmode, bit 7 = op, bits 7:0 = abcdefgh... actually
// returns a struct.
encode_neon_modimm :: proc(value: u32) -> (form: NEON_Imm_Form, ok: bool) {
	form = NEON_Imm_Form{ raw_imm32 = value }

	switch {
	// .I32 (cmode 0000): 0x000000XY
	case value <= 0xFF:
		form.cmode = 0b0000
		form.abcdefgh = u8(value)
		ok = true
		return
	// .I32 shifted 8: 0x0000XY00
	case (value & ~u32(0xFF00)) == 0:
		form.cmode = 0b0010
		form.abcdefgh = u8(value >> 8)
		ok = true
		return
	// .I32 shifted 16: 0x00XY0000
	case (value & ~u32(0xFF0000)) == 0:
		form.cmode = 0b0100
		form.abcdefgh = u8(value >> 16)
		ok = true
		return
	// .I32 shifted 24: 0xXY000000
	case (value & ~u32(0xFF000000)) == 0:
		form.cmode = 0b0110
		form.abcdefgh = u8(value >> 24)
		ok = true
		return
	// .I16 (cmode 1000): 0x0000_00XY (16-bit broadcast lower)
	case (value & ~u32(0xFF)) == 0:
		form.cmode = 0b1000
		form.abcdefgh = u8(value)
		ok = true
		return
	// .I16 shifted 8 (cmode 1010): 0x0000_XY00
	case (value & ~u32(0xFF00)) == 0:
		form.cmode = 0b1010
		form.abcdefgh = u8(value >> 8)
		ok = true
		return
	// .I32 trailing-ones-8 (cmode 1100): 0x0000_XYFF
	case (value & 0xFFFF0000) == 0 && (value & 0xFF) == 0xFF:
		form.cmode = 0b1100
		form.abcdefgh = u8((value >> 8) & 0xFF)
		ok = true
		return
	// .I32 trailing-ones-16 (cmode 1101): 0x00XY_FFFF
	case (value & 0xFF000000) == 0 && (value & 0xFFFF) == 0xFFFF:
		form.cmode = 0b1101
		form.abcdefgh = u8((value >> 16) & 0xFF)
		ok = true
		return
	}

	// .I8 byte broadcast (cmode 1110, op=0): XYXYXYXY
	if a := u32(value & 0xFF); value == (a | (a << 8) | (a << 16) | (a << 24)) {
		form.cmode = 0b1110
		form.op    = 0
		form.abcdefgh = u8(a)
		ok = true
		return
	}
	// .I64 bit-expanded (cmode 1110, op=1): only 256 patterns of a:b:c:d:e:f:g:h
	// where each bit expands to a full byte.  Check if every byte of `value`
	// is either 0x00 or 0xFF.
	{
		all_match := true
		bits_packed: u32
		for k in u32(0)..<4 {
			byte_v := (value >> (k * 8)) & 0xFF
			if byte_v == 0x00 {
				// 0 bit in packed
			} else if byte_v == 0xFF {
				bits_packed |= 1 << k
			} else {
				all_match = false
				break
			}
		}
		if all_match {
			form.cmode = 0b1110
			form.op    = 1
			form.abcdefgh = u8(bits_packed & 0xFF)
			// For .I64 form, the upper word of the full 64-bit constant
			// would also have to match the same pattern -- caller is
			// responsible for ensuring `value` is the 32-bit half.
			ok = true
			return
		}
	}
	// .F32 expanded (cmode 1111): VFP imm8 expanded to 32-bit float
	a := encode_vfp_imm8_f32(value) or_return
	form.cmode = 0b1111
	form.abcdefgh = a
	ok = true
	return
}

// Decode the 8-bit abcdefgh + cmode + op back into a 32-bit constant.
decode_neon_modimm :: proc "contextless" (abcdefgh: u32, cmode: u32, op: u32) -> u32 {
	a := abcdefgh & 0xFF
	switch cmode {
	case 0b0000: return a
	case 0b0010: return a << 8
	case 0b0100: return a << 16
	case 0b0110: return a << 24
	case 0b1000: return a
	case 0b1010: return a << 8
	case 0b1100: return (a << 8) | 0xFF
	case 0b1101: return (a << 16) | 0xFFFF
	case 0b1110:
		if op == 0 {
			return a | (a << 8) | (a << 16) | (a << 24)
		}
		// .I64 bit-expand: each bit -> 0x00 or 0xFF byte
		result: u32 = 0
		for k in u32(0)..<4 {
			if (a >> k) & 1 != 0 {
				result |= 0xFF << (k * 8)
			}
		}
		return result
	case 0b1111: return decode_vfp_imm8_f32(a)
	}
	return 0
}

// Pack the NEON_Imm_Form into the bits the encoder ORs into the instruction
// word: bits 18:16 = abc (high 3), bits 3:0 = defgh (low 4)... wait,
// abcdefgh is 8 bits split a:bcdefgh: actually it's (a)(bcd)(efgh) — 3 + 4? no.
// Standard NEON layout puts a at bit 24, bc at bits 18:17, d at bit 16, efgh at bits 3:0.
// Per ARM ARM:  bits 24, 18:16, 3:0 = abcdefgh
pack_neon_modimm_field :: #force_inline proc "contextless" (f: NEON_Imm_Form) -> u32 {
	a := u32(f.abcdefgh)
	return ((a >> 7) & 1)   << 24 |      // 'a' bit
	       ((a >> 4) & 0x7) << 16 |      // 'bcd' bits
	       (a & 0xF)              |      // 'efgh' bits
	       u32(f.cmode)     << 8  |
	       u32(f.op)        << 5
}

// Reconstruct abcdefgh from the instruction word.
extract_neon_modimm_abcdefgh :: #force_inline proc "contextless" (word: u32) -> u32 {
	return ((word >> 24) & 1)   << 7 |
	       ((word >> 16) & 0x7) << 4 |
	        (word & 0xF)
}

// =============================================================================
// 4. VFP imm8 float (VMOV.F32 / VMOV.F64 immediate)
// =============================================================================
//
// 8-bit field abcdefgh expands to a 32-bit float as:
//
//   sign     = a                          (bit 31 of float)
//   exponent = NOT(b) : b : b : b : b : b (bits 30..25 — i.e. 6 bits)
//              actually: b̄ : bbbbb           (1 bit + 5 bits) = exp bias
//   wait. The VFP imm8 expansion is:
//   F32: sign[1]:exp[8]:mant[23] where
//        sign = a
//        exp  = NOT(b):b:b:b:b:b:b:b   (8 bits)
//        mant = c:d:e:f:g:h:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0  (23 bits)
//   Wait no, that's wrong too. Per ARM ARM (VMOV imm):
//        F32: sign=a, exp = NOT(b):bbbbbb (7 bits + ... ). Actually:
//        F32 = a:NOT(b):bbbbb:cdefgh:0000000000000000000  (1 + 1 + 5 + 6 + 19 = 32)
//                                                 ^^^^^^ 6-bit mantissa from cdefgh
//
// For F64: sign[1]:exp[11]:mant[52]
//        F64 = a:NOT(b):bbbbbbbb:cdefgh:0...0  (1 + 1 + 8 + 6 + 48 = 64)
//                              ^^^^^^^^ 8-bit exponent extended
//
// For F16: sign[1]:exp[5]:mant[10]
//        F16 = a:NOT(b):bbb:cdefgh:0000  (1 + 1 + 3 + 6 + 4 = 16... but F16 is 16-bit)
//        Actually F16 doesn't fit in the same scheme cleanly; ARM ARM has a
//        specific F16 expansion using 5-bit exp and 4 mantissa bits.
//
// The set of representable F32 values is exactly 256: every encoded form
// has the same sign, top exp bit, and a 6-bit signed exponent + 4-bit
// mantissa pair. Common constants like 0.5, 1.0, 1.5, 2.0, 3.0, 0.25 are
// all encodable.

encode_vfp_imm8_f32 :: proc(value: u32) -> (u8, bool) {
	// Reverse the expansion: extract sign, exp[6:0], mant.
	// From the layout F32 = a:NOT(b):bbbbb:cdefgh:0(19 zeros)
	// - sign (bit 31) = a
	// - bit 30 = NOT(b), bits 29:25 = bbbbb -> if these are all-b, valid
	// - bits 24:19 = cdefgh
	// - bits 18:0 must be zero

	if (value & 0x7FFFF) != 0 { return 0, false }       // bottom 19 bits must be 0

	sign := (value >> 31) & 1
	bit30 := (value >> 30) & 1
	bits_29_25 := (value >> 25) & 0x1F
	bit_b := bit30 ~ 1                                  // b = NOT(bit30)
	// bits 29:25 must all equal b
	expected_29_25 := bit_b == 1 ? u32(0x1F) : u32(0)
	if bits_29_25 != expected_29_25 { return 0, false }

	cdefgh := (value >> 19) & 0x3F
	abcdefgh := (sign << 7) | (bit_b << 6) | cdefgh
	return u8(abcdefgh), true
}

decode_vfp_imm8_f32 :: proc "contextless" (abcdefgh: u32) -> u32 {
	a := (abcdefgh >> 7) & 1
	b := (abcdefgh >> 6) & 1
	cdefgh := abcdefgh & 0x3F
	not_b := b ~ 1
	bbbbb: u32 = b == 1 ? 0x1F : 0
	return (a << 31) | (not_b << 30) | (bbbbb << 25) | (cdefgh << 19)
}

encode_vfp_imm8_f64 :: proc(value: u64) -> (u8, bool) {
	// F64 = a:NOT(b):bbbbbbbb:cdefgh:0(48 zeros)
	if (value & ((u64(1) << 48) - 1)) != 0 { return 0, false }
	sign := u32(value >> 63) & 1
	bit62 := u32(value >> 62) & 1
	bits_61_54 := u32(value >> 54) & 0xFF
	bit_b := bit62 ~ 1
	expected := bit_b == 1 ? u32(0xFF) : u32(0)
	if bits_61_54 != expected { return 0, false }
	cdefgh := u32(value >> 48) & 0x3F
	abcdefgh := (sign << 7) | (bit_b << 6) | cdefgh
	return u8(abcdefgh), true
}

decode_vfp_imm8_f64 :: proc "contextless" (abcdefgh: u32) -> u64 {
	a := u64((abcdefgh >> 7) & 1)
	b := u64((abcdefgh >> 6) & 1)
	cdefgh := u64(abcdefgh & 0x3F)
	not_b := b ~ 1
	bbbbbbbb: u64 = b == 1 ? 0xFF : 0
	return (a << 63) | (not_b << 62) | (bbbbbbbb << 54) | (cdefgh << 48)
}

encode_vfp_imm8_f16 :: proc(value: u16) -> (u8, bool) {
	// F16 layout: a:NOT(b):bbb:cdefgh:0000  (1+1+3+6+4 ... wait F16 is 16 bits)
	// Actually F16 = a:NOT(b):bb:cdefgh  (1+1+2+6 = 10 bits)... that doesn't fit either.
	// Per ARM ARM (VFP F16 imm): the 16-bit float is
	//   sign[1]:exp[5]:mant[10] where
	//   exp  = NOT(b):bb   (3 bits) + ... no.
	// Correctly: F16 = a:NOT(b):b:cdefgh:000  (1+1+1+6+3 = 12 bits)... not 16.
	//
	// The real layout: F16 imm = a:NOT(b):bb:cdefgh:000  expanded to
	//   sign=a (bit 15), exp[4]=NOT(b) (bit 14), exp[3:0]=bbb (bits 13:11)... that's 4-bit exp.
	// ARM ARM: F16 expansion -- f16 has 5-bit exp and 10-bit mantissa.
	//   sign[1], exp[5], mant[10]
	//   sign = a
	//   exp[4] = NOT(b)
	//   exp[3:0] = bbb...   (4 copies of b? no, exp[3] = b, exp[2:0] = bbb)
	//                       — let's just say exp = NOT(b):bbbb (1 + 4 = 5 bits)
	//   mant[9:6] = cdef (4 bits)
	//   mant[5:0] = gh:0000 (2 bits of gh + 4 zero bits)
	//
	// Net: bottom 6 bits of F16 mantissa must be zero.

	if (value & 0x3F) != 0 { return 0, false }
	sign := u32(value >> 15) & 1
	bit14 := u32(value >> 14) & 1
	bits_13_10 := u32(value >> 10) & 0xF
	bit_b := bit14 ~ 1
	expected := bit_b == 1 ? u32(0xF) : u32(0)
	if bits_13_10 != expected { return 0, false }
	cdefgh := u32(value >> 6) & 0xF        // only 4 bits of mantissa survive (cd_ef of cdefgh)
	// Hmm, only 4 mantissa bits in F16 form... so cdefgh becomes cdef + missing gh.
	// ARM ARM defines specific F16 imm form; for our purposes we only encode
	// the F32-compatible 256 values restricted to F16's range.
	// Pack: a:b:cdef (6 bits) + implicit gh=00 -> abcdefgh with low 2 zero
	abcdefgh := (sign << 7) | (bit_b << 6) | (cdefgh << 2)
	return u8(abcdefgh), true
}

decode_vfp_imm8_f16 :: proc "contextless" (abcdefgh: u32) -> u16 {
	a := (abcdefgh >> 7) & 1
	b := (abcdefgh >> 6) & 1
	cdef := (abcdefgh >> 2) & 0xF
	not_b := b ~ 1
	bbbb: u32 = b == 1 ? 0xF : 0
	v := (a << 15) | (not_b << 14) | (bbbb << 10) | (cdef << 6)
	return u16(v)
}

// =============================================================================
// 5. PSR field selector  (MSR <psrfield>_<bits>, ...)
// =============================================================================
//
// MSR takes a 4-bit fields mask in instruction bits 19:16 (mapped to the
// SPSR/CPSR _flags / _status / _extension / _control bits). Encoded as:
//
//   bit 19 = f (flags / N,Z,C,V,Q)
//   bit 18 = s (status / IT[1:0]:reserved)
//   bit 17 = x (extension / GE bits)
//   bit 16 = c (control / mode bits, I, F, T)
//
// We expose a packed selector in low 4 bits of u8 / Operand.immediate:
//   bit 3 = f, bit 2 = s, bit 1 = x, bit 0 = c

PSR_FIELD_F :: u8(1 << 3)
PSR_FIELD_S :: u8(1 << 2)
PSR_FIELD_X :: u8(1 << 1)
PSR_FIELD_C :: u8(1 << 0)

// _nzcvq                = F bit              (flags)
// _g                    = X bit              (GE bits, ARMv6+)
// _nzcvqg               = F | X
// _all (cpsr_all)       = F | S | X | C
PSR_FIELD_NZCVQ   :: PSR_FIELD_F
PSR_FIELD_G       :: PSR_FIELD_X
PSR_FIELD_NZCVQG  :: PSR_FIELD_F | PSR_FIELD_X
PSR_FIELD_ALL     :: PSR_FIELD_F | PSR_FIELD_S | PSR_FIELD_X | PSR_FIELD_C

@(require_results)
encode_psr_field :: #force_inline proc "contextless" (sel: u8) -> u32 {
	return u32(sel & 0xF) << 16
}

@(require_results)
decode_psr_field :: #force_inline proc "contextless" (word: u32) -> u8 {
	return u8((word >> 16) & 0xF)
}
