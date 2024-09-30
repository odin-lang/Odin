#+build amd64
package deoxysii

import "base:intrinsics"
import "core:crypto"
import "core:crypto/aes"
import "core:mem"
import "core:simd"
import "core:simd/x86"

// This processes a maximum of 4 blocks at a time, as that is suitable
// for most current hardware that doesn't say "Xeon".

@(private = "file")
_BIT_ENC :: x86.__m128i{0x80, 0}
@(private = "file")
_PREFIX_AD_BLOCK :: x86.__m128i{PREFIX_AD_BLOCK << PREFIX_SHIFT, 0}
@(private = "file")
_PREFIX_AD_FINAL :: x86.__m128i{PREFIX_AD_FINAL << PREFIX_SHIFT, 0}
@(private = "file")
_PREFIX_MSG_BLOCK :: x86.__m128i{PREFIX_MSG_BLOCK << PREFIX_SHIFT, 0}
@(private = "file")
_PREFIX_MSG_FINAL :: x86.__m128i{PREFIX_MSG_FINAL << PREFIX_SHIFT, 0}

// is_hardware_accelerated returns true iff hardware accelerated Deoxys-II
// is supported.
is_hardware_accelerated :: proc "contextless" () -> bool {
	return aes.is_hardware_accelerated()
}

@(private = "file", enable_target_feature = "sse4.1", require_results)
auth_tweak :: #force_inline proc "contextless" (
	prefix:   x86.__m128i,
	block_nr: int,
) -> x86.__m128i {
	return x86._mm_insert_epi64(prefix, i64(intrinsics.byte_swap(u64(block_nr))), 1)
}

@(private = "file", enable_target_feature = "sse2", require_results)
enc_tweak :: #force_inline proc "contextless" (
	tag:      x86.__m128i,
	block_nr: int,
) -> x86.__m128i {
	return x86._mm_xor_si128(
		x86._mm_or_si128(tag, _BIT_ENC),
		x86.__m128i{0, i64(intrinsics.byte_swap(u64(block_nr)))},
	)
}

@(private = "file", enable_target_feature = "ssse3", require_results)
h_ :: #force_inline proc "contextless" (tk1: x86.__m128i) -> x86.__m128i {
	return transmute(x86.__m128i)h(transmute(simd.u8x16)tk1)
}

@(private = "file", enable_target_feature = "sse2,ssse3,aes", require_results)
bc_x4 :: #force_inline proc "contextless" (
	ctx: ^Context,
	s_0, s_1, s_2, s_3:                 x86.__m128i,
	tweak_0, tweak_1, tweak_2, tweak_3: x86.__m128i,
) -> (x86.__m128i, x86.__m128i, x86.__m128i, x86.__m128i) #no_bounds_check {
	s_0, s_1, s_2, s_3 := s_0, s_1, s_2, s_3
	tk1_0, tk1_1, tk1_2, tk1_3 := tweak_0, tweak_1, tweak_2, tweak_3

	sk := intrinsics.unaligned_load((^x86.__m128i)(&ctx._subkeys[0]))
	stk_0 := x86._mm_xor_si128(tk1_0, sk)
	stk_1 := x86._mm_xor_si128(tk1_1, sk)
	stk_2 := x86._mm_xor_si128(tk1_2, sk)
	stk_3 := x86._mm_xor_si128(tk1_3, sk)

	s_0 = x86._mm_xor_si128(s_0, stk_0)
	s_1 = x86._mm_xor_si128(s_1, stk_1)
	s_2 = x86._mm_xor_si128(s_2, stk_2)
	s_3 = x86._mm_xor_si128(s_3, stk_3)

	for i in 1 ..= BC_ROUNDS {
		sk = intrinsics.unaligned_load((^x86.__m128i)(&ctx._subkeys[i]))

		tk1_0 = h_(tk1_0)
		tk1_1 = h_(tk1_1)
		tk1_2 = h_(tk1_2)
		tk1_3 = h_(tk1_3)

		stk_0 = x86._mm_xor_si128(tk1_0, sk)
		stk_1 = x86._mm_xor_si128(tk1_1, sk)
		stk_2 = x86._mm_xor_si128(tk1_2, sk)
		stk_3 = x86._mm_xor_si128(tk1_3, sk)

		s_0 = x86._mm_aesenc_si128(s_0, stk_0)
		s_1 = x86._mm_aesenc_si128(s_1, stk_1)
		s_2 = x86._mm_aesenc_si128(s_2, stk_2)
		s_3 = x86._mm_aesenc_si128(s_3, stk_3)
	}

	return s_0, s_1, s_2, s_3
}

@(private = "file", enable_target_feature = "sse2,ssse3,aes", require_results)
bc_x1 :: #force_inline proc "contextless" (
	ctx:   ^Context,
	s:     x86.__m128i,
	tweak: x86.__m128i,
) -> x86.__m128i #no_bounds_check {
	s, tk1 := s, tweak

	sk := intrinsics.unaligned_load((^x86.__m128i)(&ctx._subkeys[0]))
	stk := x86._mm_xor_si128(tk1, sk)

	s = x86._mm_xor_si128(s, stk)

	for i in 1 ..= BC_ROUNDS {
		sk = intrinsics.unaligned_load((^x86.__m128i)(&ctx._subkeys[i]))

		tk1 = h_(tk1)

		stk = x86._mm_xor_si128(tk1, sk)

		s = x86._mm_aesenc_si128(s, stk)
	}

	return s
}

@(private = "file", enable_target_feature = "sse2,ssse3,sse4.1,aes", require_results)
bc_absorb :: proc "contextless" (
	ctx:          ^Context,
	tag:          x86.__m128i,
	src:          []byte,
	tweak_prefix: x86.__m128i,
	stk_block_nr: int,
) -> (x86.__m128i, int) #no_bounds_check {
	src, stk_block_nr, tag := src, stk_block_nr, tag

	nr_blocks := len(src) / BLOCK_SIZE
	for nr_blocks >= 4 {
		d_0, d_1, d_2, d_3 := bc_x4(
			ctx,
			intrinsics.unaligned_load((^x86.__m128i)(raw_data(src))),
			intrinsics.unaligned_load((^x86.__m128i)(raw_data(src[BLOCK_SIZE:]))),
			intrinsics.unaligned_load((^x86.__m128i)(raw_data(src[2*BLOCK_SIZE:]))),
			intrinsics.unaligned_load((^x86.__m128i)(raw_data(src[3*BLOCK_SIZE:]))),
			auth_tweak(tweak_prefix, stk_block_nr),
			auth_tweak(tweak_prefix, stk_block_nr + 1),
			auth_tweak(tweak_prefix, stk_block_nr + 2),
			auth_tweak(tweak_prefix, stk_block_nr + 3),
		)

		tag = x86._mm_xor_si128(tag, d_0)
		tag = x86._mm_xor_si128(tag, d_1)
		tag = x86._mm_xor_si128(tag, d_2)
		tag = x86._mm_xor_si128(tag, d_3)

		src = src[4*BLOCK_SIZE:]
		stk_block_nr += 4
		nr_blocks -= 4
	}

	for nr_blocks > 0 {
		d := bc_x1(
			ctx,
			intrinsics.unaligned_load((^x86.__m128i)(raw_data(src))),
			auth_tweak(tweak_prefix, stk_block_nr),
		)

		tag = x86._mm_xor_si128(tag, d)

		src = src[BLOCK_SIZE:]
		stk_block_nr += 1
		nr_blocks -= 1
	}

	return tag, stk_block_nr
}

@(private = "file", enable_target_feature = "sse2,ssse3,aes", require_results)
bc_final :: proc "contextless" (
	ctx: ^Context,
	tag: x86.__m128i,
	iv:  []byte,
) -> x86.__m128i {
	tmp: [BLOCK_SIZE]byte

	tmp[0] = PREFIX_TAG << PREFIX_SHIFT
	copy(tmp[1:], iv)

	tweak := intrinsics.unaligned_load((^x86.__m128i)(&tmp))

	return bc_x1(ctx, tag, tweak)
}

@(private = "file", enable_target_feature = "sse2,ssse3,aes", require_results)
bc_encrypt :: proc "contextless" (
	ctx:          ^Context,
	dst:          []byte,
	src:          []byte,
	iv:           x86.__m128i,
	tweak_tag:    x86.__m128i,
	stk_block_nr: int,
) -> int {
	dst, src, stk_block_nr := dst, src, stk_block_nr

	nr_blocks := len(src) / BLOCK_SIZE
	for nr_blocks >= 4 {
		d_0, d_1, d_2, d_3 := bc_x4(
			ctx,
			iv, iv, iv, iv,
			enc_tweak(tweak_tag, stk_block_nr),
			enc_tweak(tweak_tag, stk_block_nr + 1),
			enc_tweak(tweak_tag, stk_block_nr + 2),
			enc_tweak(tweak_tag, stk_block_nr + 3),
		)

		intrinsics.unaligned_store(
			(^x86.__m128i)(raw_data(dst)),
			x86._mm_xor_si128(
				d_0,
				intrinsics.unaligned_load((^x86.__m128i)(raw_data(src))),
			),
		)
		intrinsics.unaligned_store(
			(^x86.__m128i)(raw_data(dst[BLOCK_SIZE:])),
			x86._mm_xor_si128(
				d_1,
				intrinsics.unaligned_load((^x86.__m128i)(raw_data(src[BLOCK_SIZE:]))),
			),
		)
		intrinsics.unaligned_store(
			(^x86.__m128i)(raw_data(dst[2*BLOCK_SIZE:])),
			x86._mm_xor_si128(
				d_2,
				intrinsics.unaligned_load((^x86.__m128i)(raw_data(src[2*BLOCK_SIZE:]))),
			),
		)
		intrinsics.unaligned_store(
			(^x86.__m128i)(raw_data(dst[3*BLOCK_SIZE:])),
			x86._mm_xor_si128(
				d_3,
				intrinsics.unaligned_load((^x86.__m128i)(raw_data(src[3*BLOCK_SIZE:]))),
			),
		)

		src, dst = src[4*BLOCK_SIZE:], dst[4*BLOCK_SIZE:]
		stk_block_nr += 4
		nr_blocks -= 4
	}

	for nr_blocks > 0 {
		d := bc_x1(
			ctx,
			iv,
			enc_tweak(tweak_tag, stk_block_nr),
		)

		intrinsics.unaligned_store(
			(^x86.__m128i)(raw_data(dst)),
			x86._mm_xor_si128(
				d,
				intrinsics.unaligned_load((^x86.__m128i)(raw_data(src))),
			),
		)

		src, dst = src[BLOCK_SIZE:], dst[BLOCK_SIZE:]
		stk_block_nr += 1
		nr_blocks -= 1
	}

	return stk_block_nr
}

@(private)
e_hw :: proc "contextless" (ctx: ^Context, dst, tag, iv, aad, plaintext: []byte) #no_bounds_check {
	tmp: [BLOCK_SIZE]byte
	copy(tmp[1:], iv)
	iv_ := intrinsics.unaligned_load((^x86.__m128i)(raw_data(&tmp)))

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
	auth: x86.__m128i
	n: int

	aad := aad
	auth, n = bc_absorb(ctx, auth, aad, _PREFIX_AD_BLOCK, 0)
	aad = aad[n*BLOCK_SIZE:]
	if l := len(aad); l > 0 {
		a_star: [BLOCK_SIZE]byte

		copy(a_star[:], aad)
		a_star[l] = 0x80

		auth, _ = bc_absorb(ctx, auth, a_star[:], _PREFIX_AD_FINAL, n)
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
	// tag <- EK(0001 || 0^4 ||N, tag)
	m := plaintext
	auth, n = bc_absorb(ctx, auth, m, _PREFIX_MSG_BLOCK, 0)
	m = m[n*BLOCK_SIZE:]
	if l := len(m); l > 0 {
		m_star: [BLOCK_SIZE]byte

		copy(m_star[:], m)
		m_star[l] = 0x80

		auth, _ = bc_absorb(ctx, auth, m_star[:], _PREFIX_MSG_FINAL, n)
	}
	auth = bc_final(ctx, auth, iv)

	// Message encryption
	// for j = 0 to l − 1 do
	//   C_j <- M_j ^ EK(1 || tag ^ j, 0^8 || N)
	// end
	// if M_∗ != nil then
	//   C_∗ <- M_* ^ EK(1 || tag ^ l, 0^8 || N)
	// end
	//
	// return (C_1 || ... || C_l || C_∗, tag)
	m = plaintext
	n = bc_encrypt(ctx, dst, m, iv_, auth, 0)
	m = m[n*BLOCK_SIZE:]
	if l := len(m); l > 0 {
		m_star: [BLOCK_SIZE]byte

		copy(m_star[:], m)
		_ = bc_encrypt(ctx, m_star[:], m_star[:], iv_, auth, n)

		copy(dst[n*BLOCK_SIZE:], m_star[:])
	}

	intrinsics.unaligned_store((^x86.__m128i)(raw_data(tag)), auth)
}

@(private, require_results)
d_hw :: proc "contextless" (ctx: ^Context, dst, iv, aad, ciphertext, tag: []byte) -> bool {
	tmp: [BLOCK_SIZE]byte
	copy(tmp[1:], iv)
	iv_ := intrinsics.unaligned_load((^x86.__m128i)(raw_data(&tmp)))

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
	auth := intrinsics.unaligned_load((^x86.__m128i)(raw_data(tag)))

	m := ciphertext
	n := bc_encrypt(ctx, dst, m, iv_, auth, 0)
	m = m[n*BLOCK_SIZE:]
	if l := len(m); l > 0 {
		m_star: [BLOCK_SIZE]byte

		copy(m_star[:], m)
		_ = bc_encrypt(ctx, m_star[:], m_star[:], iv_, auth, n)

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
	auth = x86.__m128i{0, 0}
	aad := aad
	auth, n = bc_absorb(ctx, auth, aad, _PREFIX_AD_BLOCK, 0)
	aad = aad[BLOCK_SIZE*n:]
	if l := len(aad); l > 0 {
		a_star: [BLOCK_SIZE]byte

		copy(a_star[:], aad)
		a_star[l] = 0x80

		auth, _ = bc_absorb(ctx, auth, a_star[:], _PREFIX_AD_FINAL, n)
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
	auth, n = bc_absorb(ctx, auth, m, _PREFIX_MSG_BLOCK, 0)
	m = m[n*BLOCK_SIZE:]
	if l := len(m); l > 0 {
		m_star: [BLOCK_SIZE]byte

		copy(m_star[:], m)
		m_star[l] = 0x80

		auth, _ = bc_absorb(ctx, auth, m_star[:], _PREFIX_MSG_FINAL, n)
	}
	auth = bc_final(ctx, auth, iv)

	// Tag verification
	// if tag0 = tag then return (M_1 || ... || M_l || M_∗)
	// else return false
	intrinsics.unaligned_store((^x86.__m128i)(raw_data(&tmp)), auth)
	ok := crypto.compare_constant_time(tmp[:], tag) == 1

	mem.zero_explicit(&tmp, size_of(tmp))

	return ok
}
