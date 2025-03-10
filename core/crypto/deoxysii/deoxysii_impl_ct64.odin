package deoxysii

import "base:intrinsics"
import "core:crypto"
import aes "core:crypto/_aes/ct64"
import "core:encoding/endian"
import "core:mem"
import "core:simd"

// This uses the bitlsiced 64-bit general purpose register SWAR AES
// round function.  The encryption pass skips orthogonalizing the
// AES round function input as it is aways going to be the leading 0
// padded IV, and doing a 64-byte copy is faster.

@(private = "file")
TWEAK_SIZE :: 16

@(private = "file")
State_SW :: struct {
	ctx:        ^Context,
	q_stk, q_b: [8]u64,
}

@(private = "file")
auth_tweak :: #force_inline proc "contextless" (
	dst: ^[TWEAK_SIZE]byte,
	prefix: byte,
	block_nr: int,
) {
	endian.unchecked_put_u64be(dst[8:], u64(block_nr))
	endian.unchecked_put_u64le(dst[0:], u64(prefix) << PREFIX_SHIFT) // dst[0] = prefix << PREFIX_SHIFT
}

@(private = "file")
enc_tweak :: #force_inline proc "contextless" (
	dst: ^[TWEAK_SIZE]byte,
	tag: ^[TAG_SIZE]byte,
	block_nr: int,
) {
	tmp: [8]byte
	endian.unchecked_put_u64be(tmp[:], u64(block_nr))

	copy(dst[:], tag[:])
	dst[0] |= 0x80
	for i in 0 ..< 8 {
		dst[i+8] ~= tmp[i]
	}
}

@(private = "file")
enc_plaintext :: #force_inline proc "contextless" (
	dst: ^[8]u64,
	iv:  []byte,
) {
	tmp: [BLOCK_SIZE]byte = ---
	tmp[0] = 0
	copy(tmp[1:], iv[:])

	q_0, q_1 := aes.load_interleaved(tmp[:])
	for i in 0 ..< 4 {
		dst[i], dst[i+4] = q_0, q_1
	}
	aes.orthogonalize(dst)
}

@(private = "file")
bc_x4 :: proc "contextless" (
	ctx:     ^Context,
	dst:     []byte,
	tweaks:  ^[4][TWEAK_SIZE]byte,
	q_stk:   ^[8]u64,
	q_b:     ^[8]u64, // Orthogonalized
	n:       int,
) {
	tk1s: [4]simd.u8x16
	for j in 0 ..< n {
		tk1s[j] = intrinsics.unaligned_load((^simd.u8x16)(&tweaks[j]))
	}

	// Deoxys-BC-384
	for i in 0 ..= BC_ROUNDS {
		// Derive the round's subtweakkey
		sk := intrinsics.unaligned_load((^simd.u8x16)(&ctx._subkeys[i]))
		for j in 0 ..< n {
			if i != 0 {
				tk1s[j] = h(tk1s[j])
			}
			intrinsics.unaligned_store(
				(^simd.u8x16)(raw_data(dst)),
				simd.bit_xor(sk, tk1s[j]),
			)
			q_stk[j], q_stk[j+4] = aes.load_interleaved(dst[:])
		}
		aes.orthogonalize(q_stk)

		if i != 0 {
			aes.sub_bytes(q_b)
			aes.shift_rows(q_b)
			aes.mix_columns(q_b)
		}
		aes.add_round_key(q_b, q_stk[:])
	}

	aes.orthogonalize(q_b)
	for i in 0 ..< n {
		aes.store_interleaved(dst[i*BLOCK_SIZE:], q_b[i], q_b[i+4])
	}
}

@(private = "file", require_results)
bc_absorb :: proc "contextless" (
	st:           ^State_SW,
	dst:          []byte,
	src:          []byte,
	tweak_prefix: byte,
	stk_block_nr: int,
) -> int {
	tweaks: [4][TWEAK_SIZE]byte = ---
	tmp: [BLOCK_SIZE*4]byte = ---

	src, stk_block_nr := src, stk_block_nr
	dst_ := intrinsics.unaligned_load((^simd.u8x16)(raw_data(dst)))

	nr_blocks := len(src) / BLOCK_SIZE
	for nr_blocks > 0 {
		// Derive the tweak(s), orthogonalize the plaintext
		n := min(nr_blocks, 4)
		for i in 0 ..< n {
			auth_tweak(&tweaks[i], tweak_prefix, stk_block_nr + i)
			st.q_b[i], st.q_b[i + 4] = aes.load_interleaved(src)
			src = src[BLOCK_SIZE:]
		}
		aes.orthogonalize(&st.q_b)

		// Deoxys-BC-384
		bc_x4(st.ctx, tmp[:], &tweaks, &st.q_stk, &st.q_b, n)

		// XOR in the existing Auth/tag
		for i in 0 ..< n {
			dst_ = simd.bit_xor(
				dst_,
				intrinsics.unaligned_load((^simd.u8x16)(raw_data(tmp[i*BLOCK_SIZE:]))),
			)
		}

		stk_block_nr += n
		nr_blocks -= n
	}

	intrinsics.unaligned_store((^simd.u8x16)(raw_data(dst)), dst_)

	mem.zero_explicit(&tweaks, size_of(tweaks))
	mem.zero_explicit(&tmp, size_of(tmp))

	return stk_block_nr
}

@(private = "file")
bc_final :: proc "contextless" (
	st:  ^State_SW,
	dst: []byte,
	iv:  []byte,
) {
	tweaks: [4][TWEAK_SIZE]byte = ---

	tweaks[0][0] = PREFIX_TAG << PREFIX_SHIFT
	copy(tweaks[0][1:], iv)

	st.q_b[0], st.q_b[4] = aes.load_interleaved(dst)
	aes.orthogonalize(&st.q_b)

	bc_x4(st.ctx, dst, &tweaks, &st.q_stk, &st.q_b, 1)
}

@(private = "file", require_results)
bc_encrypt :: proc "contextless" (
	st:           ^State_SW,
	dst:          []byte,
	src:          []byte,
	q_n:          ^[8]u64, // Orthogonalized
	tweak_tag:    ^[TAG_SIZE]byte,
	stk_block_nr: int,
) -> int {
	tweaks: [4][TWEAK_SIZE]byte = ---
	tmp: [BLOCK_SIZE*4]byte = ---

	dst, src, stk_block_nr := dst, src, stk_block_nr

	nr_blocks := len(src) / BLOCK_SIZE
	for nr_blocks > 0 {
		// Derive the tweak(s)
		n := min(nr_blocks, 4)
		for i in 0 ..< n {
			enc_tweak(&tweaks[i], tweak_tag, stk_block_nr + i)
		}
		st.q_b = q_n^ // The plaintext is always `0^8 || N`

		// Deoxys-BC-384
		bc_x4(st.ctx, tmp[:], &tweaks, &st.q_stk, &st.q_b, n)

		// XOR the ciphertext
		for i in 0 ..< n {
			intrinsics.unaligned_store(
				(^simd.u8x16)(raw_data(dst[i*BLOCK_SIZE:])),
				simd.bit_xor(
					intrinsics.unaligned_load((^simd.u8x16)(raw_data(src[i*BLOCK_SIZE:]))),
					intrinsics.unaligned_load((^simd.u8x16)(raw_data(tmp[i*BLOCK_SIZE:]))),
				),
			)
		}

		dst, src = dst[n*BLOCK_SIZE:], src[n*BLOCK_SIZE:]
		stk_block_nr += n
		nr_blocks -= n
	}

	mem.zero_explicit(&tweaks, size_of(tweaks))
	mem.zero_explicit(&tmp, size_of(tmp))

	return stk_block_nr
}

@(private)
e_ref :: proc "contextless" (ctx: ^Context, dst, tag, iv, aad, plaintext: []byte) #no_bounds_check {
	st: State_SW = ---
	st.ctx = ctx

	// Algorithm 3
	//
	// Associated data
	// A_1 || ... || A_la || A_∗ <- A where each |A_i| = n and |A_∗| < n
	// Auth <- 0^n
	// for i = 0 to la − 1 do
	//   Auth <- Auth ^ EK(0010 || i, A_i+1)
	// end
	// if A_∗ != nil then
	//   Auth <- Auth ^ EK(0110 || la, pad10∗(A_∗))
	// end
	auth: [TAG_SIZE]byte
	aad := aad
	n := bc_absorb(&st, auth[:], aad, PREFIX_AD_BLOCK, 0)
	aad = aad[n*BLOCK_SIZE:]
	if l := len(aad); l > 0 {
		a_star: [BLOCK_SIZE]byte

		copy(a_star[:], aad)
		a_star[l] = 0x80

		_ = bc_absorb(&st, auth[:], a_star[:], PREFIX_AD_FINAL, n)
	}

	// Message authentication and tag generation
	// M_1 || ... || M_l || M_∗ <- M where each |M_j| = n and |M_∗| < n
	// tag <- Auth
	// for j = 0 to l − 1 do
	//   tag <- tag ^ EK(0000 || j, M_j+1)
	// end
	// if M_∗ != nil then
	//   tag <- tag ^ EK(0100 || l, pad10∗(M_∗))
	// end
	// tag <- EK(0001 || 0^4 || N, tag)
	m := plaintext
	n = bc_absorb(&st, auth[:], m, PREFIX_MSG_BLOCK, 0)
	m = m[n*BLOCK_SIZE:]
	if l := len(m); l > 0 {
		m_star: [BLOCK_SIZE]byte

		copy(m_star[:], m)
		m_star[l] = 0x80

		_ = bc_absorb(&st, auth[:], m_star[:], PREFIX_MSG_FINAL, n)
	}
	bc_final(&st, auth[:], iv)

	// Message encryption
	// for j = 0 to l − 1 do
	//   C_j <- M_j ^ EK(1 || tag ^ j, 0^8 || N)
	// end
	// if M_∗ != nil then
	//   C_∗ <- M_* ^ EK(1 || tag ^ l, 0^8 || N)
	// end
	//
	// return (C_1 || ... || C_l || C_∗, tag)
	q_iv: [8]u64 = ---
	enc_plaintext(&q_iv, iv)

	m = plaintext
	n = bc_encrypt(&st, dst, m, &q_iv, &auth, 0)
	m = m[n*BLOCK_SIZE:]
	if l := len(m); l > 0 {
		m_star: [BLOCK_SIZE]byte

		copy(m_star[:], m)
		_ = bc_encrypt(&st, m_star[:], m_star[:], &q_iv, &auth, n)

		copy(dst[n*BLOCK_SIZE:], m_star[:])

		mem.zero_explicit(&m_star, size_of(m_star))
	}

	copy(tag, auth[:])

	mem.zero_explicit(&st.q_stk, size_of(st.q_stk))
	mem.zero_explicit(&st.q_b, size_of(st.q_b))
}

@(private, require_results)
d_ref :: proc "contextless" (ctx: ^Context, dst, iv, aad, ciphertext, tag: []byte) -> bool {
	st: State_SW = ---
	st.ctx = ctx

	// Algorithm 4
	//
	// Message decryption
	// C_1 || ... || C_l || C_∗ <- C where each |C_j| = n and |C_∗| < n
	// for j = 0 to l − 1 do
	//   M_j <- C_j ^ EK(1 || tag ^ j, 0^8 || N)
	// end
	// if C_∗ != nil then
	//   M_∗ <- C_∗ ^ EK(1 || tag ^ l, 0^8 || N)
	// end
	q_iv: [8]u64 = ---
	enc_plaintext(&q_iv, iv)

	auth: [TAG_SIZE]byte
	copy(auth[:], tag)

	m := ciphertext
	n := bc_encrypt(&st, dst, m, &q_iv, &auth, 0)
	m = m[n*BLOCK_SIZE:]
	if l := len(m); l > 0 {
		m_star: [BLOCK_SIZE]byte

		copy(m_star[:], m)
		_ = bc_encrypt(&st, m_star[:], m_star[:], &q_iv, &auth, n)

		copy(dst[n*BLOCK_SIZE:], m_star[:])

		mem.zero_explicit(&m_star, size_of(m_star))
	}

	// Associated data
	// A_1 || ... || Al_a || A_∗ <- A where each |Ai_| = n and |A_∗| < n
	// Auth <- 0
	// for i = 0 to la − 1 do
	//   Auth <- Auth ^ EK(0010 || i, A_i+1)
	// end
	// if A∗ != nil then
	//   Auth <- Auth ^ EK(0110| | l_a, pad10∗(A_∗))
	// end
	auth = 0
	aad := aad
	n = bc_absorb(&st, auth[:], aad, PREFIX_AD_BLOCK, 0)
	aad = aad[n*BLOCK_SIZE:]
	if l := len(aad); l > 0 {
		a_star: [BLOCK_SIZE]byte

		copy(a_star[:], aad)
		a_star[l] = 0x80

		_ = bc_absorb(&st, auth[:], a_star[:], PREFIX_AD_FINAL, n)
	}

	// Message authentication and tag generation
	// M_1 || ... || M_l || M_∗ <- M where each |M_j| = n and |M_∗| < n
	// tag0 <- Auth
	// for j = 0 to l − 1 do
	//   tag0 <- tag0 ^ EK(0000 || j, M_j+1)
	// end
	// if M_∗ != nil then
	//   tag0 <- tag0 ^ EK(0100 || l, pad10∗(M_∗))
	// end
	// tag0 <- EK(0001 || 0^4 || N, tag0)
	m = dst[:len(ciphertext)]
	n = bc_absorb(&st, auth[:], m, PREFIX_MSG_BLOCK, 0)
	m = m[n*BLOCK_SIZE:]
	if l := len(m); l > 0 {
		m_star: [BLOCK_SIZE]byte

		copy(m_star[:], m)
		m_star[l] = 0x80

		_ = bc_absorb(&st, auth[:], m_star[:], PREFIX_MSG_FINAL, n)

		mem.zero_explicit(&m_star, size_of(m_star))
	}
	bc_final(&st, auth[:], iv)

	// Tag verification
	// if tag0 = tag then return (M_1 || ... || M_l || M_∗)
	// else return false
	ok := crypto.compare_constant_time(auth[:], tag) == 1

	mem.zero_explicit(&auth, size_of(auth))
	mem.zero_explicit(&st.q_stk, size_of(st.q_stk))
	mem.zero_explicit(&st.q_b, size_of(st.q_b))

	return ok
}
