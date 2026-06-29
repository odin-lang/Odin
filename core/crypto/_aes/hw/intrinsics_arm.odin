#+build arm64,arm32
package aes_hw

import "core:simd"
import "core:simd/arm"

// https://blog.michaelbrase.com/2018/05/08/emulating-x86-aes-intrinsics-on-armv8-a/

TARGET_FEATURES :: "neon,aes"
HAS_GHASH :: false // Temporary

@(require_results, enable_target_feature = "aes")
aesdec :: #force_inline proc "c" (data, key: simd.u8x16) -> simd.u8x16 {
	return simd.bit_xor(arm.vaesimcq_u8(arm.vaesdq_u8(data, simd.u8x16{})), key)
}

@(require_results, enable_target_feature = "aes")
aesdeclast :: #force_inline proc "c" (data, key: simd.u8x16) -> simd.u8x16 {
	return simd.bit_xor(arm.vaesdq_u8(data, simd.u8x16{}), key)
}

@(require_results, enable_target_feature = "aes")
aesenc :: #force_inline proc "c" (data, key: simd.u8x16) -> simd.u8x16 {
	return simd.bit_xor(arm.vaesmcq_u8(arm.vaeseq_u8(data, simd.u8x16{})), key)
}

@(require_results, enable_target_feature = "aes")
aesenclast :: #force_inline proc "c" (data, key: simd.u8x16) -> simd.u8x16 {
	return simd.bit_xor(arm.vaeseq_u8(data, simd.u8x16{}), key)
}

aesimc :: arm.vaesimcq_u8

@(require_results, enable_target_feature = "aes")
aeskeygenassist :: #force_inline proc "c" (data: simd.u8x16, $IMM8: u8) -> simd.u8x16 {
	a := arm.vaeseq_u8(data, simd.u8x16{}) // AESE does ShiftRows and SubBytes on A

	// Undo ShiftRows step from AESE and extract X1 and X3
	dest := simd.swizzle(
		a,
		0x04, 0x01, 0x0e, 0x0b, // SubBytes(X1)
		0x01, 0x0e, 0x0b, 0x04, // ROT(SubBytes(X1))
		0x0c, 0x09, 0x06, 0x03, // SubBytes(X3)
		0x09, 0x06, 0x03, 0x0c, // ROT(SubBytes(X3))
	)

	rcons := simd.u8x16{
		0, 0, 0, 0,
		IMM8, 0, 0, 0,
		0, 0, 0, 0,
		IMM8, 0, 0, 0,
	}

	return simd.bit_xor(dest, rcons)
}

// The keyschedule implementation is easier to read with some extra
// Intel intrinsics that are emulated by built-in LLVM ops anyway.

@(private, require_results, enable_target_feature = TARGET_FEATURES)
_mm_slli_si128 :: #force_inline proc "c" (a: simd.u8x16, $IMM8: u32) -> simd.u8x16 {
	shift :: IMM8 & 0xff

	// This needs to emit behavior identical to PSLLDQ which is as follows:
	//
	// TEMP := COUNT
	// IF (TEMP > 15) THEN TEMP := 16; FI
	// DEST := DEST << (TEMP * 8)
	// DEST[MAXVL-1:128] (Unmodified)

	return simd.shuffle(
		simd.u8x16{},
		a,
		0 when shift > 15 else (16 - shift + 0),
		1 when shift > 15 else (16 - shift + 1),
		2 when shift > 15 else (16 - shift + 2),
		3 when shift > 15 else (16 - shift + 3),
		4 when shift > 15 else (16 - shift + 4),
		5 when shift > 15 else (16 - shift + 5),
		6 when shift > 15 else (16 - shift + 6),
		7 when shift > 15 else (16 - shift + 7),
		8 when shift > 15 else (16 - shift + 8),
		9 when shift > 15 else (16 - shift + 9),
		10 when shift > 15 else (16 - shift + 10),
		11 when shift > 15 else (16 - shift + 11),
		12 when shift > 15 else (16 - shift + 12),
		13 when shift > 15 else (16 - shift + 13),
		14 when shift > 15 else (16 - shift + 14),
		15 when shift > 15 else (16 - shift + 15),
	)
}

@(private, require_results, enable_target_feature = TARGET_FEATURES)
_mm_shuffle_epi32 :: #force_inline proc "c" (a: simd.u8x16, $IMM8: u32) -> simd.u8x16 {
	v := transmute(simd.i32x4)a
	return transmute(simd.u8x16)simd.shuffle(
		v,
		v,
		IMM8 & 0b11,
		(IMM8 >> 2) & 0b11,
		(IMM8 >> 4) & 0b11,
		(IMM8 >> 6) & 0b11,
	)
}

@(private, require_results, enable_target_feature = TARGET_FEATURES)
_mm_shuffle_ps :: #force_inline proc "c" (a, b: simd.u8x16, $MASK: u32) -> simd.u8x16 {
	return transmute(simd.u8x16)simd.shuffle(
		transmute(simd.u32x4)(a),
		transmute(simd.u32x4)(b),
		u32(MASK) & 0b11,
		(u32(MASK)>>2) & 0b11,
		((u32(MASK)>>4) & 0b11)+4,
		((u32(MASK)>>6) & 0b11)+4)
}
