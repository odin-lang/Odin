#+build amd64,arm64,arm32
package deoxysii

import "base:intrinsics"
import "core:crypto"
import aes_hw "core:crypto/_aes/hw"
import "core:simd"

// This processes a maximum of 4 blocks at a time, as that is suitable
// for most current hardware that doesn't say "Xeon".
//
// TODO/perf: ARM should be able to do 8 at a time.

when ODIN_ARCH == .amd64 {
	@(private="file")
	TARGET_FEATURES :: "sse2,ssse3,aes"
} else when ODIN_ARCH == .arm64 || ODIN_ARCH == .arm32 {
	@(private="file")
	TARGET_FEATURES :: "neon,aes"
}

@(private = "file")
_BIT_ENC :: simd.u8x16{0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
@(private = "file")
_PREFIX_AD_BLOCK :: simd.u8x16{
	PREFIX_AD_BLOCK << PREFIX_SHIFT, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
}
@(private = "file")
_PREFIX_AD_FINAL :: simd.u8x16{
	PREFIX_AD_FINAL << PREFIX_SHIFT, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
}
@(private = "file")
_PREFIX_MSG_BLOCK :: simd.u8x16{
	PREFIX_MSG_BLOCK << PREFIX_SHIFT, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
}
@(private = "file")
_PREFIX_MSG_FINAL :: simd.u8x16{
	PREFIX_MSG_FINAL << PREFIX_SHIFT, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
}

// is_hardware_accelerated returns true if and only if (⟺) hardware accelerated Deoxys-II
// is supported.
is_hardware_accelerated :: proc "contextless" () -> bool {
	return aes_hw.is_supported()
}

@(private = "file", enable_target_feature = TARGET_FEATURES, require_results)
auth_tweak :: #force_inline proc "contextless" (
	prefix:   simd.u8x16,
	block_nr: int,
) -> simd.u8x16 {
	when ODIN_ENDIAN == .Little {
		block_nr_u64 := intrinsics.byte_swap(u64(block_nr))
	} else {
		block_nr_u64 := u64(block_nr)
	}

	return simd.bit_or(
		prefix,
		transmute(simd.u8x16)(simd.u64x2{0, block_nr_u64}),
	)
}

@(private = "file", enable_target_feature = TARGET_FEATURES, require_results)
enc_tweak :: #force_inline proc "contextless" (
	tag:      simd.u8x16,
	block_nr: int,
) -> simd.u8x16 {
	when ODIN_ENDIAN == .Little {
		block_nr_u64 := intrinsics.byte_swap(u64(block_nr))
	} else {
		block_nr_u64 := u64(block_nr)
	}

	return simd.bit_xor(
		simd.bit_or(tag, _BIT_ENC),
		transmute(simd.u8x16)(simd.u64x2{0, block_nr_u64}),
	)
}

@(private = "file", enable_target_feature = TARGET_FEATURES, require_results)
bc_x4 :: #force_inline proc "contextless" (
	ctx: ^Context,
	s_0, s_1, s_2, s_3:                 simd.u8x16,
	tweak_0, tweak_1, tweak_2, tweak_3: simd.u8x16,
) -> (simd.u8x16, simd.u8x16, simd.u8x16, simd.u8x16) #no_bounds_check {
	s_0, s_1, s_2, s_3 := s_0, s_1, s_2, s_3
	tk1_0, tk1_1, tk1_2, tk1_3 := tweak_0, tweak_1, tweak_2, tweak_3

	sk := intrinsics.unaligned_load((^simd.u8x16)(&ctx._subkeys[0]))
	stk_0 := simd.bit_xor(tk1_0, sk)
	stk_1 := simd.bit_xor(tk1_1, sk)
	stk_2 := simd.bit_xor(tk1_2, sk)
	stk_3 := simd.bit_xor(tk1_3, sk)

	s_0 = simd.bit_xor(s_0, stk_0)
	s_1 = simd.bit_xor(s_1, stk_1)
	s_2 = simd.bit_xor(s_2, stk_2)
	s_3 = simd.bit_xor(s_3, stk_3)

	for i in 1 ..= BC_ROUNDS {
		sk = intrinsics.unaligned_load((^simd.u8x16)(&ctx._subkeys[i]))

		tk1_0 = h(tk1_0)
		tk1_1 = h(tk1_1)
		tk1_2 = h(tk1_2)
		tk1_3 = h(tk1_3)

		stk_0 = simd.bit_xor(tk1_0, sk)
		stk_1 = simd.bit_xor(tk1_1, sk)
		stk_2 = simd.bit_xor(tk1_2, sk)
		stk_3 = simd.bit_xor(tk1_3, sk)

		s_0 = aes_hw.aesenc(s_0, stk_0)
		s_1 = aes_hw.aesenc(s_1, stk_1)
		s_2 = aes_hw.aesenc(s_2, stk_2)
		s_3 = aes_hw.aesenc(s_3, stk_3)
	}

	return s_0, s_1, s_2, s_3
}

@(private = "file", enable_target_feature = TARGET_FEATURES, require_results)
bc_x1 :: #force_inline proc "contextless" (
	ctx:   ^Context,
	s:     simd.u8x16,
	tweak: simd.u8x16,
) -> simd.u8x16 #no_bounds_check {
	s, tk1 := s, tweak

	sk := intrinsics.unaligned_load((^simd.u8x16)(&ctx._subkeys[0]))
	stk := simd.bit_xor(tk1, sk)

	s = simd.bit_xor(s, stk)

	for i in 1 ..= BC_ROUNDS {
		sk = intrinsics.unaligned_load((^simd.u8x16)(&ctx._subkeys[i]))

		tk1 = h(tk1)

		stk = simd.bit_xor(tk1, sk)

		s = aes_hw.aesenc(s, stk)
	}

	return s
}

@(private = "file", enable_target_feature = TARGET_FEATURES, require_results)
bc_absorb :: proc "contextless" (
	ctx:          ^Context,
	tag:          simd.u8x16,
	src:          []byte,
	tweak_prefix: simd.u8x16,
	stk_block_nr: int,
) -> (simd.u8x16, int) #no_bounds_check {
	src, stk_block_nr, tag := src, stk_block_nr, tag

	nr_blocks := len(src) / BLOCK_SIZE
	for nr_blocks >= 4 {
		d_0, d_1, d_2, d_3 := bc_x4(
			ctx,
			intrinsics.unaligned_load((^simd.u8x16)(raw_data(src))),
			intrinsics.unaligned_load((^simd.u8x16)(raw_data(src[BLOCK_SIZE:]))),
			intrinsics.unaligned_load((^simd.u8x16)(raw_data(src[2*BLOCK_SIZE:]))),
			intrinsics.unaligned_load((^simd.u8x16)(raw_data(src[3*BLOCK_SIZE:]))),
			auth_tweak(tweak_prefix, stk_block_nr),
			auth_tweak(tweak_prefix, stk_block_nr + 1),
			auth_tweak(tweak_prefix, stk_block_nr + 2),
			auth_tweak(tweak_prefix, stk_block_nr + 3),
		)

		tag = simd.bit_xor(tag, d_0)
		tag = simd.bit_xor(tag, d_1)
		tag = simd.bit_xor(tag, d_2)
		tag = simd.bit_xor(tag, d_3)

		src = src[4*BLOCK_SIZE:]
		stk_block_nr += 4
		nr_blocks -= 4
	}

	for nr_blocks > 0 {
		d := bc_x1(
			ctx,
			intrinsics.unaligned_load((^simd.u8x16)(raw_data(src))),
			auth_tweak(tweak_prefix, stk_block_nr),
		)

		tag = simd.bit_xor(tag, d)

		src = src[BLOCK_SIZE:]
		stk_block_nr += 1
		nr_blocks -= 1
	}

	return tag, stk_block_nr
}

@(private = "file", enable_target_feature = TARGET_FEATURES, require_results)
bc_final :: proc "contextless" (
	ctx: ^Context,
	tag: simd.u8x16,
	iv:  []byte,
) -> simd.u8x16 {
	tmp: [BLOCK_SIZE]byte

	tmp[0] = PREFIX_TAG << PREFIX_SHIFT
	copy(tmp[1:], iv)

	tweak := intrinsics.unaligned_load((^simd.u8x16)(&tmp))

	return bc_x1(ctx, tag, tweak)
}

@(private = "file", enable_target_feature = TARGET_FEATURES, require_results)
bc_encrypt :: proc "contextless" (
	ctx:          ^Context,
	dst:          []byte,
	src:          []byte,
	iv:           simd.u8x16,
	tweak_tag:    simd.u8x16,
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
			(^simd.u8x16)(raw_data(dst)),
			simd.bit_xor(
				d_0,
				intrinsics.unaligned_load((^simd.u8x16)(raw_data(src))),
			),
		)
		intrinsics.unaligned_store(
			(^simd.u8x16)(raw_data(dst[BLOCK_SIZE:])),
			simd.bit_xor(
				d_1,
				intrinsics.unaligned_load((^simd.u8x16)(raw_data(src[BLOCK_SIZE:]))),
			),
		)
		intrinsics.unaligned_store(
			(^simd.u8x16)(raw_data(dst[2*BLOCK_SIZE:])),
			simd.bit_xor(
				d_2,
				intrinsics.unaligned_load((^simd.u8x16)(raw_data(src[2*BLOCK_SIZE:]))),
			),
		)
		intrinsics.unaligned_store(
			(^simd.u8x16)(raw_data(dst[3*BLOCK_SIZE:])),
			simd.bit_xor(
				d_3,
				intrinsics.unaligned_load((^simd.u8x16)(raw_data(src[3*BLOCK_SIZE:]))),
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
			(^simd.u8x16)(raw_data(dst)),
			simd.bit_xor(
				d,
				intrinsics.unaligned_load((^simd.u8x16)(raw_data(src))),
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
	iv_ := intrinsics.unaligned_load((^simd.u8x16)(raw_data(&tmp)))

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
	auth: simd.u8x16
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

	intrinsics.unaligned_store((^simd.u8x16)(raw_data(tag)), auth)
}

@(private, require_results)
d_hw :: proc "contextless" (ctx: ^Context, dst, iv, aad, ciphertext, tag: []byte) -> bool {
	tmp: [BLOCK_SIZE]byte
	copy(tmp[1:], iv)
	iv_ := intrinsics.unaligned_load((^simd.u8x16)(raw_data(&tmp)))

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
	auth := intrinsics.unaligned_load((^simd.u8x16)(raw_data(tag)))

	m := ciphertext
	n := bc_encrypt(ctx, dst, m, iv_, auth, 0)
	m = m[n*BLOCK_SIZE:]
	if l := len(m); l > 0 {
		m_star: [BLOCK_SIZE]byte

		copy(m_star[:], m)
		_ = bc_encrypt(ctx, m_star[:], m_star[:], iv_, auth, n)

		copy(dst[n*BLOCK_SIZE:], m_star[:])

		crypto.zero_explicit(&m_star, size_of(m_star))
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
	auth = simd.u8x16{}
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
	intrinsics.unaligned_store((^simd.u8x16)(raw_data(&tmp)), auth)
	ok := crypto.compare_constant_time(tmp[:], tag) == 1

	crypto.zero_explicit(&tmp, size_of(tmp))

	return ok
}
