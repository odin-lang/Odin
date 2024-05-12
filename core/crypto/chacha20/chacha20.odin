/*
package chacha20 implements the ChaCha20 and XChaCha20 stream ciphers.

See:
- https://datatracker.ietf.org/doc/html/rfc8439
- https://datatracker.ietf.org/doc/draft-irtf-cfrg-xchacha/03/
*/
package chacha20

import "core:bytes"
import "core:encoding/endian"
import "core:math/bits"
import "core:mem"

// KEY_SIZE is the (X)ChaCha20 key size in bytes.
KEY_SIZE :: 32
// NONCE_SIZE is the ChaCha20 nonce size in bytes.
NONCE_SIZE :: 12
// XNONCE_SIZE is the XChaCha20 nonce size in bytes.
XNONCE_SIZE :: 24

@(private)
_MAX_CTR_IETF :: 0xffffffff

@(private)
_BLOCK_SIZE :: 64
@(private)
_STATE_SIZE_U32 :: 16
@(private)
_ROUNDS :: 20

@(private)
_SIGMA_0: u32 : 0x61707865
@(private)
_SIGMA_1: u32 : 0x3320646e
@(private)
_SIGMA_2: u32 : 0x79622d32
@(private)
_SIGMA_3: u32 : 0x6b206574

// Context is a ChaCha20 or XChaCha20 instance.
Context :: struct {
	_s:              [_STATE_SIZE_U32]u32,
	_buffer:         [_BLOCK_SIZE]byte,
	_off:            int,
	_is_ietf_flavor: bool,
	_is_initialized: bool,
}

// init inititializes a Context for ChaCha20 or XChaCha20 with the provided
// key and nonce.
init :: proc(ctx: ^Context, key, nonce: []byte) {
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
	ctx._s[4] = endian.unchecked_get_u32le(k[0:4])
	ctx._s[5] = endian.unchecked_get_u32le(k[4:8])
	ctx._s[6] = endian.unchecked_get_u32le(k[8:12])
	ctx._s[7] = endian.unchecked_get_u32le(k[12:16])
	ctx._s[8] = endian.unchecked_get_u32le(k[16:20])
	ctx._s[9] = endian.unchecked_get_u32le(k[20:24])
	ctx._s[10] = endian.unchecked_get_u32le(k[24:28])
	ctx._s[11] = endian.unchecked_get_u32le(k[28:32])
	ctx._s[12] = 0
	if !is_xchacha {
		ctx._s[13] = endian.unchecked_get_u32le(n[0:4])
		ctx._s[14] = endian.unchecked_get_u32le(n[4:8])
		ctx._s[15] = endian.unchecked_get_u32le(n[8:12])
	} else {
		ctx._s[13] = 0
		ctx._s[14] = endian.unchecked_get_u32le(n[0:4])
		ctx._s[15] = endian.unchecked_get_u32le(n[4:8])

		// The sub-key is stored in the keystream buffer.  While
		// this will be overwritten in most circumstances, explicitly
		// clear it out early.
		mem.zero_explicit(&ctx._buffer, KEY_SIZE)
	}

	ctx._off = _BLOCK_SIZE
	ctx._is_ietf_flavor = !is_xchacha
	ctx._is_initialized = true
}

// seek seeks the (X)ChaCha20 stream counter to the specified block.
seek :: proc(ctx: ^Context, block_nr: u64) {
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

// xor_bytes XORs each byte in src with bytes taken from the (X)ChaCha20
// keystream, and writes the resulting output to dst.  Dst and src MUST
// alias exactly or not at all.
xor_bytes :: proc(ctx: ^Context, dst, src: []byte) {
	assert(ctx._is_initialized)

	src, dst := src, dst
	if dst_len := len(dst); dst_len < len(src) {
		src = src[:dst_len]
	}

	if bytes.alias_inexactly(src, dst) {
		panic("crypto/chacha20: src and dest alias inexactly")
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

// keystream_bytes fills dst with the raw (X)ChaCha20 keystream output.
keystream_bytes :: proc(ctx: ^Context, dst: []byte) {
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

// reset sanitizes the Context.  The Context must be re-initialized to
// be used again.
reset :: proc(ctx: ^Context) {
	mem.zero_explicit(&ctx._s, size_of(ctx._s))
	mem.zero_explicit(&ctx._buffer, size_of(ctx._buffer))

	ctx._is_initialized = false
}

@(private)
_check_counter_limit :: proc(ctx: ^Context, nr_blocks: int) {
	// Enforce the maximum consumed keystream per nonce.
	//
	// While all modern "standard" definitions of ChaCha20 use
	// the IETF 32-bit counter, for XChaCha20 most common
	// implementations allow for a 64-bit counter.
	//
	// Honestly, the answer here is "use a MRAE primitive", but
	// go with common practice in the case of XChaCha20.
	if ctx._is_ietf_flavor {
		if u64(ctx._s[12]) + u64(nr_blocks) > _MAX_CTR_IETF {
			panic("crypto/chacha20: maximum ChaCha20 keystream per nonce reached")
		}
	} else {
		ctr := (u64(ctx._s[13]) << 32) | u64(ctx._s[12])
		if _, carry := bits.add_u64(ctr, u64(nr_blocks), 0); carry != 0 {
			panic("crypto/chacha20: maximum XChaCha20 keystream per nonce reached")
		}
	}
}
