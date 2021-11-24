package chacha20poly1305

import "core:crypto"
import "core:crypto/chacha20"
import "core:crypto/poly1305"
import "core:crypto/util"
import "core:mem"

KEY_SIZE :: chacha20.KEY_SIZE
NONCE_SIZE :: chacha20.NONCE_SIZE
TAG_SIZE :: poly1305.TAG_SIZE

_P_MAX :: 64 * 0xffffffff // 64 * (2^32-1)

_validate_common_slice_sizes :: proc (tag, key, nonce, aad, text: []byte) {
	if len(tag) != TAG_SIZE {
		panic("crypto/chacha20poly1305: invalid destination tag size")
	}
	if len(key) != KEY_SIZE {
		panic("crypto/chacha20poly1305: invalid key size")
	}
	if len(nonce) != NONCE_SIZE {
		panic("crypto/chacha20poly1305: invalid nonce size")
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

_PAD: [16]byte
_update_mac_pad16 :: #force_inline proc (ctx: ^poly1305.Context, x_len: int) {
	if pad_len := 16 - (x_len & (16-1)); pad_len != 16 {
		poly1305.update(ctx, _PAD[:pad_len])
	}
}

encrypt :: proc (ciphertext, tag, key, nonce, aad, plaintext: []byte) {
	_validate_common_slice_sizes(tag, key, nonce, aad, plaintext)
	if len(ciphertext) != len(plaintext) {
		panic("crypto/chacha20poly1305: invalid destination ciphertext size")
	}

	stream_ctx: chacha20.Context = ---
	chacha20.init(&stream_ctx, key, nonce)

	// otk = poly1305_key_gen(key, nonce)
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

	// ciphertext = chacha20_encrypt(key, 1, nonce, plaintext)
	chacha20.seek(&stream_ctx, 1)
	chacha20.xor_bytes(&stream_ctx, ciphertext, plaintext)
	chacha20.reset(&stream_ctx) // Don't need the stream context anymore.

	// mac_data |= ciphertext | pad16(ciphertext)
	poly1305.update(&mac_ctx, ciphertext)
	_update_mac_pad16(&mac_ctx, ciphertext_len)

	// mac_data |= num_to_8_le_bytes(aad.length)
	// mac_data |= num_to_8_le_bytes(ciphertext.length)
	l_buf := otk[0:16] // Reuse the scratch buffer.
	util.PUT_U64_LE(l_buf[0:8], u64(aad_len))
	util.PUT_U64_LE(l_buf[8:16], u64(ciphertext_len))
	poly1305.update(&mac_ctx, l_buf)

	// tag = poly1305_mac(mac_data, otk)
	poly1305.final(&mac_ctx, tag) // Implicitly sanitizes context.
}

decrypt :: proc (plaintext, tag, key, nonce, aad, ciphertext: []byte) -> bool {
	_validate_common_slice_sizes(tag, key, nonce, aad, ciphertext)
	if len(ciphertext) != len(plaintext) {
		panic("crypto/chacha20poly1305: invalid destination plaintext size")
	}

	// Note: Unlike encrypt, this can fail early, so use defer for
	// sanitization rather than assuming control flow reaches certain
	// points where needed.

	stream_ctx: chacha20.Context = ---
	chacha20.init(&stream_ctx, key, nonce)

	// otk = poly1305_key_gen(key, nonce)
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
	util.PUT_U64_LE(l_buf[0:8], u64(aad_len))
	util.PUT_U64_LE(l_buf[8:16], u64(ciphertext_len))
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

	// plaintext = chacha20_decrypt(key, 1, nonce, ciphertext)
	chacha20.seek(&stream_ctx, 1)
	chacha20.xor_bytes(&stream_ctx, plaintext, ciphertext)

	return true
}
