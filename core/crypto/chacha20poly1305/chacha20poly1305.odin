/*
package chacha20poly1305 implements the AEAD_CHACHA20_POLY1305 and
AEAD_XChaCha20_Poly1305 Authenticated Encryption with Additional Data
algorithms.

See:
- https://www.rfc-editor.org/rfc/rfc8439
- https://datatracker.ietf.org/doc/html/draft-arciszewski-xchacha-03
*/
package chacha20poly1305

import "core:crypto"
import "core:crypto/chacha20"
import "core:crypto/poly1305"
import "core:encoding/endian"
import "core:mem"

// KEY_SIZE is the chacha20poly1305 key size in bytes.
KEY_SIZE :: chacha20.KEY_SIZE
// IV_SIZE is the chacha20poly1305 IV size in bytes.
IV_SIZE :: chacha20.IV_SIZE
// XIV_SIZE is the xchacha20poly1305 IV size in bytes.
XIV_SIZE :: chacha20.XIV_SIZE
// TAG_SIZE is the chacha20poly1305 tag size in bytes.
TAG_SIZE :: poly1305.TAG_SIZE

@(private)
_P_MAX :: 64 * 0xffffffff // 64 * (2^32-1)

@(private)
_validate_common_slice_sizes :: proc (tag, iv, aad, text: []byte, is_xchacha: bool) {
	if len(tag) != TAG_SIZE {
		panic("crypto/chacha20poly1305: invalid destination tag size")
	}
	expected_iv_len := is_xchacha ? XIV_SIZE : IV_SIZE
	if len(iv) != expected_iv_len {
		panic("crypto/chacha20poly1305: invalid IV size")
	}

	#assert(size_of(int) == 8 || size_of(int) <= 4)
	when size_of(int) == 8 {
		// A_MAX = 2^64 - 1 due to the length field limit.
		// P_MAX = 64 * (2^32 - 1) due to the IETF ChaCha20 counter limit.
		//
		// A_MAX is limited by size_of(int), so there is no need to
		// enforce it. P_MAX only needs to be checked on 64-bit targets,
		// for reasons that should be obvious.
		if text_len := len(text); text_len > _P_MAX {
			panic("crypto/chacha20poly1305: oversized src data")
		}
	}
}

@(private)
_PAD: [16]byte

@(private)
_update_mac_pad16 :: #force_inline proc (ctx: ^poly1305.Context, x_len: int) {
	if pad_len := 16 - (x_len & (16-1)); pad_len != 16 {
		poly1305.update(ctx, _PAD[:pad_len])
	}
}

// Context is a keyed (X)Chacha20Poly1305 instance.
Context :: struct {
	_key:            [KEY_SIZE]byte,
	_impl:           chacha20.Implementation,
	_is_xchacha:     bool,
	_is_initialized: bool,
}

// init initializes a Context with the provided key, for AEAD_CHACHA20_POLY1305.
init :: proc(ctx: ^Context, key: []byte, impl := chacha20.DEFAULT_IMPLEMENTATION) {
	if len(key) != KEY_SIZE {
		panic("crypto/chacha20poly1305: invalid key size")
	}

	copy(ctx._key[:], key)
	ctx._impl = impl
	ctx._is_xchacha = false
	ctx._is_initialized = true
}

// init_xchacha initializes a Context with the provided key, for
// AEAD_XChaCha20_Poly1305.
//
// Note: While there are multiple definitions of XChaCha20-Poly1305
// this sticks to the IETF draft and uses a 32-bit counter.
init_xchacha :: proc(ctx: ^Context, key: []byte, impl := chacha20.DEFAULT_IMPLEMENTATION) {
	init(ctx, key, impl)
	ctx._is_xchacha = true
}

// seal encrypts the plaintext and authenticates the aad and ciphertext,
// with the provided Context and iv, stores the output in dst and tag.
//
// dst and plaintext MUST alias exactly or not at all.
seal :: proc(ctx: ^Context, dst, tag, iv, aad, plaintext: []byte) {
	ciphertext := dst
	_validate_common_slice_sizes(tag, iv, aad, plaintext, ctx._is_xchacha)
	if len(ciphertext) != len(plaintext) {
		panic("crypto/chacha20poly1305: invalid destination ciphertext size")
	}

	stream_ctx: chacha20.Context = ---
	chacha20.init(&stream_ctx, ctx._key[:],iv, ctx._impl)
	stream_ctx._state._is_ietf_flavor = true

	// otk = poly1305_key_gen(key, iv)
	otk: [poly1305.KEY_SIZE]byte = ---
	chacha20.keystream_bytes(&stream_ctx, otk[:])
	mac_ctx: poly1305.Context = ---
	poly1305.init(&mac_ctx, otk[:])
	mem.zero_explicit(&otk, size_of(otk))

	aad_len, ciphertext_len := len(aad), len(ciphertext)

	// There is nothing preventing aad and ciphertext from overlapping
	// so auth the AAD before encrypting (slightly different from the
	// RFC, since the RFC encrypts into a new buffer).
	//
	// mac_data = aad | pad16(aad)
	poly1305.update(&mac_ctx, aad)
	_update_mac_pad16(&mac_ctx, aad_len)

	// ciphertext = chacha20_encrypt(key, 1, iv, plaintext)
	chacha20.seek(&stream_ctx, 1)
	chacha20.xor_bytes(&stream_ctx, ciphertext, plaintext)
	chacha20.reset(&stream_ctx) // Don't need the stream context anymore.

	// mac_data |= ciphertext | pad16(ciphertext)
	poly1305.update(&mac_ctx, ciphertext)
	_update_mac_pad16(&mac_ctx, ciphertext_len)

	// mac_data |= num_to_8_le_bytes(aad.length)
	// mac_data |= num_to_8_le_bytes(ciphertext.length)
	l_buf := otk[0:16] // Reuse the scratch buffer.
	endian.unchecked_put_u64le(l_buf[0:8], u64(aad_len))
	endian.unchecked_put_u64le(l_buf[8:16], u64(ciphertext_len))
	poly1305.update(&mac_ctx, l_buf)

	// tag = poly1305_mac(mac_data, otk)
	poly1305.final(&mac_ctx, tag) // Implicitly sanitizes context.
}

// open authenticates the aad and ciphertext, and decrypts the ciphertext,
// with the provided Context, iv, and tag, and stores the output in dst,
// returning true iff the authentication was successful.  If authentication
// fails, the destination buffer will be zeroed.
//
// dst and plaintext MUST alias exactly or not at all.
@(require_results)
open :: proc(ctx: ^Context, dst, iv, aad, ciphertext, tag: []byte) -> bool {
	plaintext := dst
	_validate_common_slice_sizes(tag, iv, aad, ciphertext, ctx._is_xchacha)
	if len(ciphertext) != len(plaintext) {
		panic("crypto/chacha20poly1305: invalid destination plaintext size")
	}

	// Note: Unlike encrypt, this can fail early, so use defer for
	// sanitization rather than assuming control flow reaches certain
	// points where needed.

	stream_ctx: chacha20.Context = ---
	chacha20.init(&stream_ctx, ctx._key[:], iv, ctx._impl)
	stream_ctx._state._is_ietf_flavor = true

	// otk = poly1305_key_gen(key, iv)
	otk: [poly1305.KEY_SIZE]byte = ---
	chacha20.keystream_bytes(&stream_ctx, otk[:])
	defer chacha20.reset(&stream_ctx)

	mac_ctx: poly1305.Context = ---
	poly1305.init(&mac_ctx, otk[:])
	defer mem.zero_explicit(&otk, size_of(otk))

	aad_len, ciphertext_len := len(aad), len(ciphertext)

	// mac_data = aad | pad16(aad)
	// mac_data |= ciphertext | pad16(ciphertext)
	// mac_data |= num_to_8_le_bytes(aad.length)
	// mac_data |= num_to_8_le_bytes(ciphertext.length)
	poly1305.update(&mac_ctx, aad)
	_update_mac_pad16(&mac_ctx, aad_len)
	poly1305.update(&mac_ctx, ciphertext)
	_update_mac_pad16(&mac_ctx, ciphertext_len)
	l_buf := otk[0:16] // Reuse the scratch buffer.
	endian.unchecked_put_u64le(l_buf[0:8], u64(aad_len))
	endian.unchecked_put_u64le(l_buf[8:16], u64(ciphertext_len))
	poly1305.update(&mac_ctx, l_buf)

	// tag = poly1305_mac(mac_data, otk)
	derived_tag := otk[0:poly1305.TAG_SIZE] // Reuse the scratch buffer again.
	poly1305.final(&mac_ctx, derived_tag) // Implicitly sanitizes context.

	// Validate the tag in constant time.
	if crypto.compare_constant_time(tag, derived_tag) != 1 {
		// Zero out the plaintext, as a defense in depth measure.
		mem.zero_explicit(raw_data(plaintext), ciphertext_len)
		return false
	}

	// plaintext = chacha20_decrypt(key, 1, iv, ciphertext)
	chacha20.seek(&stream_ctx, 1)
	chacha20.xor_bytes(&stream_ctx, plaintext, ciphertext)

	return true
}

// reset sanitizes the Context.  The Context must be
// re-initialized to be used again.
reset :: proc "contextless" (ctx: ^Context) {
	mem.zero_explicit(&ctx._key, len(ctx._key))
	ctx._is_xchacha = false
	ctx._is_initialized = false
}
