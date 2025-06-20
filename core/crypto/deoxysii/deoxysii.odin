/*
package deoxysii implements the Deoxys-II-256 Authenticated Encryption
with Additional Data algorithm.

- [[ https://sites.google.com/view/deoxyscipher ]]
- [[ https://thomaspeyrin.github.io/web/assets/docs/papers/Jean-etal-JoC2021.pdf ]]
*/
package deoxysii

import "base:intrinsics"
import "core:bytes"
import "core:crypto/aes"
import "core:mem"
import "core:simd"

// KEY_SIZE is the Deoxys-II-256 key size in bytes.
KEY_SIZE :: 32
// IV_SIZE iss the Deoxys-II-256 IV size in bytes.
IV_SIZE :: 15 // 120-bits
// TAG_SIZE is the Deoxys-II-256 tag size in bytes.
TAG_SIZE :: 16

@(private)
PREFIX_AD_BLOCK :: 0b0010
@(private)
PREFIX_AD_FINAL :: 0b0110
@(private)
PREFIX_MSG_BLOCK :: 0b0000
@(private)
PREFIX_MSG_FINAL :: 0b0100
@(private)
PREFIX_TAG :: 0b0001
@(private)
PREFIX_SHIFT :: 4

@(private)
BC_ROUNDS :: 16
@(private)
BLOCK_SIZE :: aes.BLOCK_SIZE

@(private = "file")
_LFSR2_MASK :: simd.u8x16{
	0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
	0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
}
@(private = "file")
_LFSR3_MASK :: simd.u8x16{
	0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80,
	0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80,
}
@(private = "file")
_LFSR_SH1 :: _LFSR2_MASK
@(private = "file")
_LFSR_SH5 :: simd.u8x16{
	0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05,
	0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05,
}
@(private = "file")
_LFSR_SH7 :: simd.u8x16{
	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07,
	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07,
}
@(private = "file", rodata)
_RCONS := []byte {
	0x2f, 0x5e, 0xbc, 0x63, 0xc6, 0x97, 0x35, 0x6a,
	0xd4, 0xb3, 0x7d, 0xfa, 0xef, 0xc5, 0x91, 0x39,
	0x72,
}

// Context is a keyed Deoxys-II-256 instance.
Context :: struct {
	_subkeys:        [BC_ROUNDS+1][16]byte,
	_impl:           aes.Implementation,
	_is_initialized: bool,
}

@(private)
_validate_common_slice_sizes :: proc (ctx: ^Context, tag, iv, aad, text: []byte) {
	ensure(len(tag) == TAG_SIZE, "crypto/deoxysii: invalid tag size")
	ensure(len(iv) == IV_SIZE, "crypto/deoxysii: invalid IV size")

	#assert(size_of(int) == 8 || size_of(int) <= 4)
	// For the nonce-misuse resistant mode, the total size of the
	// associated data and the total size of the message do not exceed
	// `16 * 2^max_l * 2^max_m bytes`, thus 2^128 bytes for all variants
	// of Deoxys-II. Moreover, the maximum number of messages that can
	// be handled for a same key is 2^max_m, that is 2^64 for all variants
	// of Deoxys.
}

// init initializes a Context with the provided key.
init :: proc(ctx: ^Context, key: []byte, impl := aes.DEFAULT_IMPLEMENTATION) {
	ensure(len(key) == KEY_SIZE, "crypto/deoxysii: invalid key size")

	ctx._impl = impl
	if ctx._impl == .Hardware && !is_hardware_accelerated() {
		ctx._impl = .Portable
	}

	derive_ks(ctx, key)

	ctx._is_initialized = true
}

// seal encrypts the plaintext and authenticates the aad and ciphertext,
// with the provided Context and iv, stores the output in dst and tag.
//
// dst and plaintext MUST alias exactly or not at all.
seal :: proc(ctx: ^Context, dst, tag, iv, aad, plaintext: []byte) {
	ensure(ctx._is_initialized)

	_validate_common_slice_sizes(ctx, tag, iv, aad, plaintext)
	ensure(len(dst) == len(plaintext), "crypto/deoxysii: invalid destination ciphertext size")
	ensure(!bytes.alias_inexactly(dst, plaintext), "crypto/deoxysii: dst and plaintext alias inexactly")

	switch ctx._impl {
	case .Hardware:
		e_hw(ctx, dst, tag, iv, aad, plaintext)
	case .Portable:
		e_ref(ctx, dst, tag, iv, aad, plaintext)
	}
}

// open authenticates the aad and ciphertext, and decrypts the ciphertext,
// with the provided Context, iv, and tag, and stores the output in dst,
// returning true iff the authentication was successful.  If authentication
// fails, the destination buffer will be zeroed.
//
// dst and plaintext MUST alias exactly or not at all.
@(require_results)
open :: proc(ctx: ^Context, dst, iv, aad, ciphertext, tag: []byte) -> bool {
	ensure(ctx._is_initialized)

	_validate_common_slice_sizes(ctx, tag, iv, aad, ciphertext)
	ensure(len(dst) == len(ciphertext), "crypto/deoxysii: invalid destination plaintext size")
	ensure(!bytes.alias_inexactly(dst, ciphertext), "crypto/deoxysii: dst and ciphertext alias inexactly")

	ok: bool
	switch ctx._impl {
	case .Hardware:
		ok = d_hw(ctx, dst, iv, aad, ciphertext, tag)
	case .Portable:
		ok = d_ref(ctx, dst, iv, aad, ciphertext, tag)
	}
	if !ok {
		mem.zero_explicit(raw_data(dst), len(ciphertext))
	}

	return ok
}

// reset sanitizes the Context.  The Context must be
// re-initialized to be used again.
reset :: proc "contextless" (ctx: ^Context) {
	mem.zero_explicit(&ctx._subkeys, len(ctx._subkeys))
	ctx._is_initialized = false
}

@(private = "file")
derive_ks :: proc "contextless" (ctx: ^Context, key: []byte) {
	// Derive the constant component of each subtweakkey.
	//
	// The key schedule is as thus:
	//
	//   STK_i = TK1_i ^ TK2_i ^ TK3_i ^ RC_i
	//
	//   TK1_i = h(TK1_(i-1))
	//   TK2_i = h(LFSR2(TK2_(i-1)))
	//   TK3_i = h(LFSR3(TK2_(i-1)))
	//
	// where:
	//
	//   KT = K || T
	//   W3 = KT[:16]
	//   W2 = KT[16:32]
	//   W1 = KT[32:]
	//
	//   TK1_0 = W1
	//   TK2_0 = W2
	//   TK3_0 = W3
	//
	// As `K` is fixed per Context, the XORs of `TK3_0 .. TK3_n`,
	// `TK2_0 .. TK2_n` and RC_i can be precomputed in advance like
	// thus:
	//
	//   subkey_i = TK3_i ^ TK2_i ^ RC_i
	//
	// When it is time to actually call Deoxys-BC-384, it is then
	// a simple matter of deriving each round subtweakkey via:
	//
	//   TK1_0 = T (Tweak)
	//   STK_0 = subkey_0 ^ TK1_0
	//   STK_i = subkey_i (precomputed) ^ H(TK1_(i-1))
	//
	// We opt to use SIMD here and for the subtweakkey deriviation
	// as `H()` is typically a single vector instruction.

	tk2 := intrinsics.unaligned_load((^simd.u8x16)(raw_data(key[16:])))
	tk3 := intrinsics.unaligned_load((^simd.u8x16)(raw_data(key)))

	// subkey_0 does not apply LFSR2/3 or H.
	intrinsics.unaligned_store(
		(^simd.u8x16)(&ctx._subkeys[0]),
		simd.bit_xor(
			tk2,
			simd.bit_xor(
				tk3,
				rcon(0),
			),
		),
	)

	// Precompute k_1 .. k_16.
	for i in 1 ..< BC_ROUNDS+1 {
		tk2 = h(lfsr2(tk2))
		tk3 = h(lfsr3(tk3))
		intrinsics.unaligned_store(
			(^simd.u8x16)(&ctx._subkeys[i]),
			simd.bit_xor(
				tk2,
				simd.bit_xor(
					tk3,
					rcon(i),
				),
			),
		)
	}
}

@(private = "file")
lfsr2 :: #force_inline proc "contextless" (tk: simd.u8x16) -> simd.u8x16 {
	// LFSR2 is a application of the following LFSR to each byte of input.
	// (x7||x6||x5||x4||x3||x2||x1||x0) -> (x6||x5||x4||x3||x2||x1||x0||x7 ^ x5)
	return simd.bit_or(
		simd.shl(tk, _LFSR_SH1),
		simd.bit_and(
			simd.bit_xor(
				simd.shr(tk, _LFSR_SH7), // x7
				simd.shr(tk, _LFSR_SH5), // x5
			),
			_LFSR2_MASK,
		),
	)
}

@(private = "file")
lfsr3 :: #force_inline proc "contextless"  (tk: simd.u8x16) -> simd.u8x16 {
	// LFSR3 is a application of the following LFSR to each byte of input.
	// (x7||x6||x5||x4||x3||x2||x1||x0) -> (x0 ^ x6||x7||x6||x5||x4||x3||x2||x1)
	return simd.bit_or(
		simd.shr(tk, _LFSR_SH1),
		simd.bit_and(
			simd.bit_xor(
				simd.shl(tk, _LFSR_SH7), // x0
				simd.shl(tk, _LFSR_SH1), // x6
			),
			_LFSR3_MASK,
		),
	)
}

@(private)
h :: #force_inline proc "contextless" (tk: simd.u8x16) -> simd.u8x16 {
	return simd.swizzle(
		tk,
		0x01, 0x06, 0x0b, 0x0c, 0x05, 0x0a, 0x0f, 0x00,
		0x09, 0x0e, 0x03, 0x04, 0x0d, 0x02, 0x07, 0x08,
	)
}

@(private = "file")
rcon :: #force_inline proc "contextless" (rd: int) -> simd.u8x16 #no_bounds_check {
	rc := _RCONS[rd]
	return simd.u8x16{
		1, 2, 4, 8,
		rc, rc, rc, rc,
		0, 0, 0, 0,
		0, 0, 0, 0,
	}
}