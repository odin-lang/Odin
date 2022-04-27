package chacha20

import "core:crypto/util"
import "core:math/bits"
import "core:mem"

KEY_SIZE :: 32
NONCE_SIZE :: 12
XNONCE_SIZE :: 24

_MAX_CTR_IETF :: 0xffffffff

_BLOCK_SIZE :: 64
_STATE_SIZE_U32 :: 16
_ROUNDS :: 20

_SIGMA_0 : u32 : 0x61707865
_SIGMA_1 : u32 : 0x3320646e
_SIGMA_2 : u32 : 0x79622d32
_SIGMA_3 : u32 : 0x6b206574

Context :: struct {
	_s: [_STATE_SIZE_U32]u32,

	_buffer: [_BLOCK_SIZE]byte,
	_off: int,

	_is_ietf_flavor: bool,
	_is_initialized: bool,
}

init :: proc (ctx: ^Context, key, nonce: []byte) {
	if len(key) != KEY_SIZE {
		panic("crypto/chacha20: invalid ChaCha20 key size")
	}
	if n_len := len(nonce); n_len != NONCE_SIZE && n_len != XNONCE_SIZE {
		panic("crypto/chacha20: invalid (X)ChaCha20 nonce size")
	}

	k, n := key, nonce

	// Derive the XChaCha20 subkey and sub-nonce via HChaCha20.
	is_xchacha := len(nonce) == XNONCE_SIZE
	if is_xchacha {
		sub_key := ctx._buffer[:KEY_SIZE]
		_hchacha20(sub_key, k, n)
		k = sub_key
		n = n[16:24]
	}

	ctx._s[0] = _SIGMA_0
	ctx._s[1] = _SIGMA_1
	ctx._s[2] = _SIGMA_2
	ctx._s[3] = _SIGMA_3
	ctx._s[4] = util.U32_LE(k[0:4])
	ctx._s[5] = util.U32_LE(k[4:8])
	ctx._s[6] = util.U32_LE(k[8:12])
	ctx._s[7] = util.U32_LE(k[12:16])
	ctx._s[8] = util.U32_LE(k[16:20])
	ctx._s[9] = util.U32_LE(k[20:24])
	ctx._s[10] = util.U32_LE(k[24:28])
	ctx._s[11] = util.U32_LE(k[28:32])
	ctx._s[12] = 0
	if !is_xchacha {
		ctx._s[13] = util.U32_LE(n[0:4])
		ctx._s[14] = util.U32_LE(n[4:8])
		ctx._s[15] = util.U32_LE(n[8:12])
	} else {
		ctx._s[13] = 0
		ctx._s[14] = util.U32_LE(n[0:4])
		ctx._s[15] = util.U32_LE(n[4:8])

		// The sub-key is stored in the keystream buffer.  While
		// this will be overwritten in most circumstances, explicitly
		// clear it out early.
		mem.zero_explicit(&ctx._buffer, KEY_SIZE)
	}

	ctx._off = _BLOCK_SIZE
	ctx._is_ietf_flavor = !is_xchacha
	ctx._is_initialized = true
}

seek :: proc (ctx: ^Context, block_nr: u64) {
	assert(ctx._is_initialized)

	if ctx._is_ietf_flavor {
		if block_nr > _MAX_CTR_IETF {
			panic("crypto/chacha20: attempted to seek past maximum counter")
		}
	} else {
		ctx._s[13] = u32(block_nr >> 32)
	}
	ctx._s[12] = u32(block_nr)
	ctx._off = _BLOCK_SIZE
}

xor_bytes :: proc (ctx: ^Context, dst, src: []byte) {
	assert(ctx._is_initialized)

	// TODO: Enforcing that dst and src alias exactly or not at all
	// is a good idea, though odd aliasing should be extremely uncommon.

	src, dst := src, dst
	if dst_len := len(dst); dst_len < len(src) {
		src = src[:dst_len]
	}

	for remaining := len(src); remaining > 0; {
		// Process multiple blocks at once
		if ctx._off == _BLOCK_SIZE {
			if nr_blocks := remaining / _BLOCK_SIZE; nr_blocks > 0 {
				direct_bytes := nr_blocks * _BLOCK_SIZE
				_do_blocks(ctx, dst, src, nr_blocks)
				remaining -= direct_bytes
				if remaining == 0 {
					return
				}
				dst = dst[direct_bytes:]
				src = src[direct_bytes:]
			}

			// If there is a partial block, generate and buffer 1 block
			// worth of keystream.
			_do_blocks(ctx, ctx._buffer[:], nil, 1)
			ctx._off = 0
		}

		// Process partial blocks from the buffered keystream.
		to_xor := min(_BLOCK_SIZE - ctx._off, remaining)
		buffered_keystream := ctx._buffer[ctx._off:]
		for i := 0; i < to_xor; i = i + 1 {
			dst[i] = buffered_keystream[i] ~ src[i]
		}
		ctx._off += to_xor
		dst = dst[to_xor:]
		src = src[to_xor:]
		remaining -= to_xor
	}
}

keystream_bytes :: proc (ctx: ^Context, dst: []byte) {
	assert(ctx._is_initialized)

	dst := dst
	for remaining := len(dst); remaining > 0; {
		// Process multiple blocks at once
		if ctx._off == _BLOCK_SIZE {
			if nr_blocks := remaining / _BLOCK_SIZE; nr_blocks > 0 {
				direct_bytes := nr_blocks * _BLOCK_SIZE
				_do_blocks(ctx, dst, nil, nr_blocks)
				remaining -= direct_bytes
				if remaining == 0 {
					return
				}
				dst = dst[direct_bytes:]
			}

			// If there is a partial block, generate and buffer 1 block
			// worth of keystream.
			_do_blocks(ctx, ctx._buffer[:], nil, 1)
			ctx._off = 0
		}

		// Process partial blocks from the buffered keystream.
		to_copy := min(_BLOCK_SIZE - ctx._off, remaining)
		buffered_keystream := ctx._buffer[ctx._off:]
		copy(dst[:to_copy], buffered_keystream[:to_copy])
		ctx._off += to_copy
		dst = dst[to_copy:]
		remaining -= to_copy
	}
}

reset :: proc (ctx: ^Context) {
	mem.zero_explicit(&ctx._s, size_of(ctx._s))
	mem.zero_explicit(&ctx._buffer, size_of(ctx._buffer))

	ctx._is_initialized = false
}

_do_blocks :: proc (ctx: ^Context, dst, src: []byte, nr_blocks: int) {
	// Enforce the maximum consumed keystream per nonce.
	//
	// While all modern "standard" definitions of ChaCha20 use
	// the IETF 32-bit counter, for XChaCha20 most common
	// implementations allow for a 64-bit counter.
	//
	// Honestly, the answer here is "use a MRAE primitive", but
	// go with common practice in the case of XChaCha20.
	if ctx._is_ietf_flavor {
		if u64(ctx._s[12]) + u64(nr_blocks) > 0xffffffff {
			panic("crypto/chacha20: maximum ChaCha20 keystream per nonce reached")
		}
	} else {
		ctr := (u64(ctx._s[13]) << 32) | u64(ctx._s[12])
		if _, carry := bits.add_u64(ctr, u64(nr_blocks), 0); carry != 0 {
			panic("crypto/chacha20: maximum XChaCha20 keystream per nonce reached")
		}
	}

	dst, src := dst, src
	x := &ctx._s
	for n := 0; n < nr_blocks; n = n + 1 {
		x0, x1, x2, x3 := _SIGMA_0, _SIGMA_1, _SIGMA_2, _SIGMA_3
		x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15 := x[4], x[5], x[6], x[7], x[8], x[9], x[10], x[11], x[12], x[13], x[14], x[15]

		for i := _ROUNDS; i > 0; i = i - 2 {
			// Even when forcing inlining manually inlining all of
			// these is decently faster.

			// quarterround(x, 0, 4, 8, 12)
			x0 += x4
			x12 ~= x0
			x12 = util.ROTL32(x12, 16)
			x8 += x12
			x4 ~= x8
			x4 = util.ROTL32(x4, 12)
			x0 += x4
			x12 ~= x0
			x12 = util.ROTL32(x12, 8)
			x8 += x12
			x4 ~= x8
			x4 = util.ROTL32(x4, 7)

			// quarterround(x, 1, 5, 9, 13)
			x1 += x5
			x13 ~= x1
			x13 = util.ROTL32(x13, 16)
			x9 += x13
			x5 ~= x9
			x5 = util.ROTL32(x5, 12)
			x1 += x5
			x13 ~= x1
			x13 = util.ROTL32(x13, 8)
			x9 += x13
			x5 ~= x9
			x5 = util.ROTL32(x5, 7)

			// quarterround(x, 2, 6, 10, 14)
			x2 += x6
			x14 ~= x2
			x14 = util.ROTL32(x14, 16)
			x10 += x14
			x6 ~= x10
			x6 = util.ROTL32(x6, 12)
			x2 += x6
			x14 ~= x2
			x14 = util.ROTL32(x14, 8)
			x10 += x14
			x6 ~= x10
			x6 = util.ROTL32(x6, 7)

			// quarterround(x, 3, 7, 11, 15)
			x3 += x7
			x15 ~= x3
			x15 = util.ROTL32(x15, 16)
			x11 += x15
			x7 ~= x11
			x7 = util.ROTL32(x7, 12)
			x3 += x7
			x15 ~= x3
			x15 = util.ROTL32(x15, 8)
			x11 += x15
			x7 ~= x11
			x7 = util.ROTL32(x7, 7)

			// quarterround(x, 0, 5, 10, 15)
			x0 += x5
			x15 ~= x0
			x15 = util.ROTL32(x15, 16)
			x10 += x15
			x5 ~= x10
			x5 = util.ROTL32(x5, 12)
			x0 += x5
			x15 ~= x0
			x15 = util.ROTL32(x15, 8)
			x10 += x15
			x5 ~= x10
			x5 = util.ROTL32(x5, 7)

			// quarterround(x, 1, 6, 11, 12)
			x1 += x6
			x12 ~= x1
			x12 = util.ROTL32(x12, 16)
			x11 += x12
			x6 ~= x11
			x6 = util.ROTL32(x6, 12)
			x1 += x6
			x12 ~= x1
			x12 = util.ROTL32(x12, 8)
			x11 += x12
			x6 ~= x11
			x6 = util.ROTL32(x6, 7)

			// quarterround(x, 2, 7, 8, 13)
			x2 += x7
			x13 ~= x2
			x13 = util.ROTL32(x13, 16)
			x8 += x13
			x7 ~= x8
			x7 = util.ROTL32(x7, 12)
			x2 += x7
			x13 ~= x2
			x13 = util.ROTL32(x13, 8)
			x8 += x13
			x7 ~= x8
			x7 = util.ROTL32(x7, 7)

			// quarterround(x, 3, 4, 9, 14)
			x3 += x4
			x14 ~= x3
			x14 = util.ROTL32(x14, 16)
			x9 += x14
			x4 ~= x9
			x4 = util.ROTL32(x4, 12)
			x3 += x4
			x14 ~= x3
			x14 = util.ROTL32(x14, 8)
			x9 += x14
			x4 ~= x9
			x4 = util.ROTL32(x4, 7)
		}

		x0 += _SIGMA_0
		x1 += _SIGMA_1
		x2 += _SIGMA_2
		x3 += _SIGMA_3
		x4 += x[4]
		x5 += x[5]
		x6 += x[6]
		x7 += x[7]
		x8 += x[8]
		x9 += x[9]
		x10 += x[10]
		x11 += x[11]
		x12 += x[12]
		x13 += x[13]
		x14 += x[14]
		x15 += x[15]

		// While the "correct" answer to getting more performance out of
		// this is "use vector operations", support for that is currently
		// a work in progress/to be designed.
		//
		// Until dedicated assembly can be written leverage the fact that
		// the callers of this routine ensure that src/dst are valid.

		when ODIN_ARCH == .i386 || ODIN_ARCH == .amd64 {
			// util.PUT_U32_LE/util.U32_LE are not required on little-endian
			// systems that also happen to not be strict about aligned
			// memory access.

			dst_p := transmute(^[16]u32)(&dst[0])
			if src != nil {
				src_p := transmute(^[16]u32)(&src[0])
				dst_p[0] = src_p[0] ~ x0
				dst_p[1] = src_p[1] ~ x1
				dst_p[2] = src_p[2] ~ x2
				dst_p[3] = src_p[3] ~ x3
				dst_p[4] = src_p[4] ~ x4
				dst_p[5] = src_p[5] ~ x5
				dst_p[6] = src_p[6] ~ x6
				dst_p[7] = src_p[7] ~ x7
				dst_p[8] = src_p[8] ~ x8
				dst_p[9] = src_p[9] ~ x9
				dst_p[10] = src_p[10] ~ x10
				dst_p[11] = src_p[11] ~ x11
				dst_p[12] = src_p[12] ~ x12
				dst_p[13] = src_p[13] ~ x13
				dst_p[14] = src_p[14] ~ x14
				dst_p[15] = src_p[15] ~ x15
				src = src[_BLOCK_SIZE:]
			} else {
				dst_p[0] = x0
				dst_p[1] = x1
				dst_p[2] = x2
				dst_p[3] = x3
				dst_p[4] = x4
				dst_p[5] = x5
				dst_p[6] = x6
				dst_p[7] = x7
				dst_p[8] = x8
				dst_p[9] = x9
				dst_p[10] = x10
				dst_p[11] = x11
				dst_p[12] = x12
				dst_p[13] = x13
				dst_p[14] = x14
				dst_p[15] = x15
			}
			dst = dst[_BLOCK_SIZE:]
		} else {
			#no_bounds_check {
				if src != nil {
					util.PUT_U32_LE(dst[0:4], util.U32_LE(src[0:4]) ~ x0)
					util.PUT_U32_LE(dst[4:8], util.U32_LE(src[4:8]) ~ x1)
					util.PUT_U32_LE(dst[8:12], util.U32_LE(src[8:12]) ~ x2)
					util.PUT_U32_LE(dst[12:16], util.U32_LE(src[12:16]) ~ x3)
					util.PUT_U32_LE(dst[16:20], util.U32_LE(src[16:20]) ~ x4)
					util.PUT_U32_LE(dst[20:24], util.U32_LE(src[20:24]) ~ x5)
					util.PUT_U32_LE(dst[24:28], util.U32_LE(src[24:28]) ~ x6)
					util.PUT_U32_LE(dst[28:32], util.U32_LE(src[28:32]) ~ x7)
					util.PUT_U32_LE(dst[32:36], util.U32_LE(src[32:36]) ~ x8)
					util.PUT_U32_LE(dst[36:40], util.U32_LE(src[36:40]) ~ x9)
					util.PUT_U32_LE(dst[40:44], util.U32_LE(src[40:44]) ~ x10)
					util.PUT_U32_LE(dst[44:48], util.U32_LE(src[44:48]) ~ x11)
					util.PUT_U32_LE(dst[48:52], util.U32_LE(src[48:52]) ~ x12)
					util.PUT_U32_LE(dst[52:56], util.U32_LE(src[52:56]) ~ x13)
					util.PUT_U32_LE(dst[56:60], util.U32_LE(src[56:60]) ~ x14)
					util.PUT_U32_LE(dst[60:64], util.U32_LE(src[60:64]) ~ x15)
					src = src[_BLOCK_SIZE:]
				} else {
					util.PUT_U32_LE(dst[0:4], x0)
					util.PUT_U32_LE(dst[4:8], x1)
					util.PUT_U32_LE(dst[8:12], x2)
					util.PUT_U32_LE(dst[12:16], x3)
					util.PUT_U32_LE(dst[16:20], x4)
					util.PUT_U32_LE(dst[20:24], x5)
					util.PUT_U32_LE(dst[24:28], x6)
					util.PUT_U32_LE(dst[28:32], x7)
					util.PUT_U32_LE(dst[32:36], x8)
					util.PUT_U32_LE(dst[36:40], x9)
					util.PUT_U32_LE(dst[40:44], x10)
					util.PUT_U32_LE(dst[44:48], x11)
					util.PUT_U32_LE(dst[48:52], x12)
					util.PUT_U32_LE(dst[52:56], x13)
					util.PUT_U32_LE(dst[56:60], x14)
					util.PUT_U32_LE(dst[60:64], x15)
				}
				dst = dst[_BLOCK_SIZE:]
			}
		}

		// Increment the counter.  Overflow checking is done upon
		// entry into the routine, so a 64-bit increment safely
		// covers both cases.
		new_ctr := ((u64(ctx._s[13]) << 32) | u64(ctx._s[12])) + 1
		x[12] = u32(new_ctr)
		x[13] = u32(new_ctr >> 32)
	}
}

_hchacha20 :: proc (dst, key, nonce: []byte) {
	x0, x1, x2, x3 := _SIGMA_0, _SIGMA_1, _SIGMA_2, _SIGMA_3
	x4 := util.U32_LE(key[0:4])
	x5 := util.U32_LE(key[4:8])
	x6 := util.U32_LE(key[8:12])
	x7 := util.U32_LE(key[12:16])
	x8 := util.U32_LE(key[16:20])
	x9 := util.U32_LE(key[20:24])
	x10 := util.U32_LE(key[24:28])
	x11 := util.U32_LE(key[28:32])
	x12 := util.U32_LE(nonce[0:4])
	x13 := util.U32_LE(nonce[4:8])
	x14 := util.U32_LE(nonce[8:12])
	x15 := util.U32_LE(nonce[12:16])

	for i := _ROUNDS; i > 0; i = i - 2 {
		// quarterround(x, 0, 4, 8, 12)
		x0 += x4
		x12 ~= x0
		x12 = util.ROTL32(x12, 16)
		x8 += x12
		x4 ~= x8
		x4 = util.ROTL32(x4, 12)
		x0 += x4
		x12 ~= x0
		x12 = util.ROTL32(x12, 8)
		x8 += x12
		x4 ~= x8
		x4 = util.ROTL32(x4, 7)

		// quarterround(x, 1, 5, 9, 13)
		x1 += x5
		x13 ~= x1
		x13 = util.ROTL32(x13, 16)
		x9 += x13
		x5 ~= x9
		x5 = util.ROTL32(x5, 12)
		x1 += x5
		x13 ~= x1
		x13 = util.ROTL32(x13, 8)
		x9 += x13
		x5 ~= x9
		x5 = util.ROTL32(x5, 7)

		// quarterround(x, 2, 6, 10, 14)
		x2 += x6
		x14 ~= x2
		x14 = util.ROTL32(x14, 16)
		x10 += x14
		x6 ~= x10
		x6 = util.ROTL32(x6, 12)
		x2 += x6
		x14 ~= x2
		x14 = util.ROTL32(x14, 8)
		x10 += x14
		x6 ~= x10
		x6 = util.ROTL32(x6, 7)

		// quarterround(x, 3, 7, 11, 15)
		x3 += x7
		x15 ~= x3
		x15 = util.ROTL32(x15, 16)
		x11 += x15
		x7 ~= x11
		x7 = util.ROTL32(x7, 12)
		x3 += x7
		x15 ~= x3
		x15 = util.ROTL32(x15, 8)
		x11 += x15
		x7 ~= x11
		x7 = util.ROTL32(x7, 7)

		// quarterround(x, 0, 5, 10, 15)
		x0 += x5
		x15 ~= x0
		x15 = util.ROTL32(x15, 16)
		x10 += x15
		x5 ~= x10
		x5 = util.ROTL32(x5, 12)
		x0 += x5
		x15 ~= x0
		x15 = util.ROTL32(x15, 8)
		x10 += x15
		x5 ~= x10
		x5 = util.ROTL32(x5, 7)

		// quarterround(x, 1, 6, 11, 12)
		x1 += x6
		x12 ~= x1
		x12 = util.ROTL32(x12, 16)
		x11 += x12
		x6 ~= x11
		x6 = util.ROTL32(x6, 12)
		x1 += x6
		x12 ~= x1
		x12 = util.ROTL32(x12, 8)
		x11 += x12
		x6 ~= x11
		x6 = util.ROTL32(x6, 7)

		// quarterround(x, 2, 7, 8, 13)
		x2 += x7
		x13 ~= x2
		x13 = util.ROTL32(x13, 16)
		x8 += x13
		x7 ~= x8
		x7 = util.ROTL32(x7, 12)
		x2 += x7
		x13 ~= x2
		x13 = util.ROTL32(x13, 8)
		x8 += x13
		x7 ~= x8
		x7 = util.ROTL32(x7, 7)

		// quarterround(x, 3, 4, 9, 14)
		x3 += x4
		x14 ~= x3
		x14 = util.ROTL32(x14, 16)
		x9 += x14
		x4 ~= x9
		x4 = util.ROTL32(x4, 12)
		x3 += x4
		x14 ~= x3
		x14 = util.ROTL32(x14, 8)
		x9 += x14
		x4 ~= x9
		x4 = util.ROTL32(x4, 7)
	}

	util.PUT_U32_LE(dst[0:4], x0)
	util.PUT_U32_LE(dst[4:8], x1)
	util.PUT_U32_LE(dst[8:12], x2)
	util.PUT_U32_LE(dst[12:16], x3)
	util.PUT_U32_LE(dst[16:20], x12)
	util.PUT_U32_LE(dst[20:24], x13)
	util.PUT_U32_LE(dst[24:28], x14)
	util.PUT_U32_LE(dst[28:32], x15)
}
