/*
package aegis implements the AEGIS-128L and AEGIS-256 Authenticated
Encryption with Additional Data algorithms.

See:
- [[ https://www.ietf.org/archive/id/draft-irtf-cfrg-aegis-aead-12.txt ]]
*/
package aegis

import "core:bytes"
import "core:crypto"
import "core:crypto/aes"
import "core:mem"

// KEY_SIZE_128L is the AEGIS-128L key size in bytes.
KEY_SIZE_128L :: 16
// KEY_SIZE_256 is the AEGIS-256 key size in bytes.
KEY_SIZE_256 :: 32
// IV_SIZE_128L is the AEGIS-128L IV size in bytes.
IV_SIZE_128L :: 16
// IV_SIZE_256 is the AEGIS-256 IV size in bytes.
IV_SIZE_256 :: 32
// TAG_SIZE_128 is the AEGIS-128L or AEGIS-256 128-bit tag size in bytes.
TAG_SIZE_128 :: 16
// TAG_SIZE_256 is the AEGIS-128L or AEGIS-256 256-bit tag size in bytes.
TAG_SIZE_256 :: 32

@(private)
_RATE_128L :: 32
@(private)
_RATE_256 :: 16
@(private)
_RATE_MAX :: _RATE_128L

@(private, rodata)
_C0 := [16]byte{
	0x00, 0x01, 0x01, 0x02, 0x03, 0x05, 0x08, 0x0d,
	0x15, 0x22, 0x37, 0x59, 0x90, 0xe9, 0x79, 0x62,
}

@(private, rodata)
_C1 := [16]byte {
	0xdb, 0x3d, 0x18, 0x55, 0x6d, 0xc2, 0x2f, 0xf1,
	0x20, 0x11, 0x31, 0x42, 0x73, 0xb5, 0x28, 0xdd,
}

// Context is a keyed AEGIS-128L or AEGIS-256 instance.
Context :: struct {
	_key:            [KEY_SIZE_256]byte,
	_key_len:        int,
	_impl:           aes.Implementation,
	_is_initialized: bool,
}

@(private)
_validate_common_slice_sizes :: proc (ctx: ^Context, tag, iv, aad, text: []byte) {
	switch len(tag) {
	case TAG_SIZE_128, TAG_SIZE_256:
	case:
		panic("crypto/aegis: invalid tag size")
	}

	iv_ok: bool
	switch ctx._key_len {
	case KEY_SIZE_128L:
		iv_ok = len(iv) == IV_SIZE_128L
	case KEY_SIZE_256:
		iv_ok = len(iv) == IV_SIZE_256
	}
	ensure(iv_ok,"crypto/aegis: invalid IV size")

	#assert(size_of(int) == 8 || size_of(int) <= 4)
	// As A_MAX and P_MAX are both defined to be 2^61 - 1 bytes, and
	// the maximum length of a slice is bound by `size_of(int)`, where
	// `int` is register sized, there is no need to check AAD/text
	// lengths.
}

// init initializes a Context with the provided key, for AEGIS-128L or AEGIS-256.
init :: proc(ctx: ^Context, key: []byte, impl := aes.DEFAULT_IMPLEMENTATION) {
	switch len(key) {
	case KEY_SIZE_128L, KEY_SIZE_256:
	case:
		panic("crypto/aegis: invalid key size")
	}

	copy(ctx._key[:], key)
	ctx._key_len = len(key)
	ctx._impl = impl
	if ctx._impl == .Hardware && !is_hardware_accelerated() {
		ctx._impl = .Portable
	}
	ctx._is_initialized = true
}

// seal encrypts the plaintext and authenticates the aad and ciphertext,
// with the provided Context and iv, stores the output in dst and tag.
//
// dst and plaintext MUST alias exactly or not at all.
seal :: proc(ctx: ^Context, dst, tag, iv, aad, plaintext: []byte) {
	ensure(ctx._is_initialized)

	_validate_common_slice_sizes(ctx, tag, iv, aad, plaintext)
	ensure(len(dst) == len(plaintext), "crypto/aegis: invalid destination ciphertext size")
	ensure(!bytes.alias_inexactly(dst, plaintext), "crypto/aegis: dst and plaintext alias inexactly")

	switch ctx._impl {
	case .Hardware:
		st: State_HW
		defer reset_state_hw(&st)

		init_hw(ctx, &st, iv)

		aad_len, pt_len := len(aad), len(plaintext)
		if aad_len > 0 {
			absorb_hw(&st, aad)
		}

		if pt_len > 0 {
			enc_hw(&st, dst, plaintext)
		}

		finalize_hw(&st, tag, aad_len, pt_len)
	case .Portable:
		st: State_SW
		defer reset_state_sw(&st)

		init_sw(ctx, &st, iv)

		aad_len, pt_len := len(aad), len(plaintext)
		if aad_len > 0 {
			absorb_sw(&st, aad)
		}

		if pt_len > 0 {
			enc_sw(&st, dst, plaintext)
		}

		finalize_sw(&st, tag, aad_len, pt_len)
	case:
		panic("core/crypto/aegis: not implemented")
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
	ensure(len(dst) == len(ciphertext), "crypto/aegis: invalid destination plaintext size")
	ensure(!bytes.alias_inexactly(dst, ciphertext), "crypto/aegis: dst and ciphertext alias inexactly")

	tmp: [TAG_SIZE_256]byte
	derived_tag := tmp[:len(tag)]
	aad_len, ct_len := len(aad), len(ciphertext)

	switch ctx._impl {
	case .Hardware:
		st: State_HW
		defer reset_state_hw(&st)

		init_hw(ctx, &st, iv)

		if aad_len > 0 {
			absorb_hw(&st, aad)
		}

		if ct_len > 0 {
			dec_hw(&st, dst, ciphertext)
		}

		finalize_hw(&st, derived_tag, aad_len, ct_len)
	case .Portable:
		st: State_SW
		defer reset_state_sw(&st)

		init_sw(ctx, &st, iv)

		if aad_len > 0 {
			absorb_sw(&st, aad)
		}

		if ct_len > 0 {
			dec_sw(&st, dst, ciphertext)
		}

		finalize_sw(&st, derived_tag, aad_len, ct_len)
	case:
		panic("core/crypto/aegis: not implemented")
	}

	if crypto.compare_constant_time(tag, derived_tag) != 1 {
		mem.zero_explicit(raw_data(derived_tag), len(derived_tag))
		mem.zero_explicit(raw_data(dst), ct_len)
		return false
	}

	return true
}

// reset sanitizes the Context.  The Context must be
// re-initialized to be used again.
reset :: proc "contextless" (ctx: ^Context) {
	mem.zero_explicit(&ctx._key, len(ctx._key))
	ctx._key_len = 0
	ctx._is_initialized = false
}
