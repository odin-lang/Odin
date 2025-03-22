package aes

import "core:bytes"
import "core:crypto/_aes/ct64"
import "core:encoding/endian"
import "core:math/bits"
import "core:mem"

// CTR_IV_SIZE is the size of the CTR mode IV in bytes.
CTR_IV_SIZE :: 16

// Context_CTR is a keyed AES-CTR instance.
Context_CTR :: struct {
	_impl:           Context_Impl,
	_buffer:         [BLOCK_SIZE]byte,
	_off:            int,
	_ctr_hi:         u64,
	_ctr_lo:         u64,
	_is_initialized: bool,
}

// init_ctr initializes a Context_CTR with the provided key and IV.
init_ctr :: proc(ctx: ^Context_CTR, key, iv: []byte, impl := DEFAULT_IMPLEMENTATION) {
	ensure(len(iv) == CTR_IV_SIZE, "crypto/aes: invalid CTR IV size")

	init_impl(&ctx._impl, key, impl)
	ctx._off = BLOCK_SIZE
	ctx._ctr_hi = endian.unchecked_get_u64be(iv[0:])
	ctx._ctr_lo = endian.unchecked_get_u64be(iv[8:])
	ctx._is_initialized = true
}

// xor_bytes_ctr XORs each byte in src with bytes taken from the AES-CTR
// keystream, and writes the resulting output to dst.  dst and src MUST
// alias exactly or not at all.
xor_bytes_ctr :: proc(ctx: ^Context_CTR, dst, src: []byte) {
	ensure(ctx._is_initialized)

	src, dst := src, dst
	if dst_len := len(dst); dst_len < len(src) {
		src = src[:dst_len]
	}

	ensure(!bytes.alias_inexactly(dst, src), "crypto/aes: dst and src alias inexactly")

	#no_bounds_check for remaining := len(src); remaining > 0; {
		// Process multiple blocks at once
		if ctx._off == BLOCK_SIZE {
			if nr_blocks := remaining / BLOCK_SIZE; nr_blocks > 0 {
				direct_bytes := nr_blocks * BLOCK_SIZE
				ctr_blocks(ctx, dst, src, nr_blocks)
				remaining -= direct_bytes
				if remaining == 0 {
					return
				}
				dst = dst[direct_bytes:]
				src = src[direct_bytes:]
			}

			// If there is a partial block, generate and buffer 1 block
			// worth of keystream.
			ctr_blocks(ctx, ctx._buffer[:], nil, 1)
			ctx._off = 0
		}

		// Process partial blocks from the buffered keystream.
		to_xor := min(BLOCK_SIZE - ctx._off, remaining)
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

// keystream_bytes_ctr fills dst with the raw AES-CTR keystream output.
keystream_bytes_ctr :: proc(ctx: ^Context_CTR, dst: []byte) {
	ensure(ctx._is_initialized)

	dst := dst
	#no_bounds_check for remaining := len(dst); remaining > 0; {
		// Process multiple blocks at once
		if ctx._off == BLOCK_SIZE {
			if nr_blocks := remaining / BLOCK_SIZE; nr_blocks > 0 {
				direct_bytes := nr_blocks * BLOCK_SIZE
				ctr_blocks(ctx, dst, nil, nr_blocks)
				remaining -= direct_bytes
				if remaining == 0 {
					return
				}
				dst = dst[direct_bytes:]
			}

			// If there is a partial block, generate and buffer 1 block
			// worth of keystream.
			ctr_blocks(ctx, ctx._buffer[:], nil, 1)
			ctx._off = 0
		}

		// Process partial blocks from the buffered keystream.
		to_copy := min(BLOCK_SIZE - ctx._off, remaining)
		buffered_keystream := ctx._buffer[ctx._off:]
		copy(dst[:to_copy], buffered_keystream[:to_copy])
		ctx._off += to_copy
		dst = dst[to_copy:]
		remaining -= to_copy
	}
}

// reset_ctr sanitizes the Context_CTR.  The Context_CTR must be
// re-initialized to be used again.
reset_ctr :: proc "contextless" (ctx: ^Context_CTR) {
	reset_impl(&ctx._impl)
	ctx._off = 0
	ctx._ctr_hi = 0
	ctx._ctr_lo = 0
	mem.zero_explicit(&ctx._buffer, size_of(ctx._buffer))
	ctx._is_initialized = false
}

@(private = "file")
ctr_blocks :: proc(ctx: ^Context_CTR, dst, src: []byte, nr_blocks: int) #no_bounds_check {
	// Use the optimized hardware implementation if available.
	if _, is_hw := ctx._impl.(Context_Impl_Hardware); is_hw {
		ctr_blocks_hw(ctx, dst, src, nr_blocks)
		return
	}

	// Portable implementation.
	ct64_inc_ctr := #force_inline proc "contextless" (dst: []byte, hi, lo: u64) -> (u64, u64) {
		endian.unchecked_put_u64be(dst[0:], hi)
		endian.unchecked_put_u64be(dst[8:], lo)

		hi, lo := hi, lo
		carry: u64
		lo, carry = bits.add_u64(lo, 1, 0)
		hi, _ = bits.add_u64(hi, 0, carry)
		return hi, lo
	}

	impl := &ctx._impl.(ct64.Context)
	src, dst := src, dst
	nr_blocks := nr_blocks
	ctr_hi, ctr_lo := ctx._ctr_hi, ctx._ctr_lo

	tmp: [ct64.STRIDE][BLOCK_SIZE]byte = ---
	ctrs: [ct64.STRIDE][]byte = ---
	for i in 0 ..< ct64.STRIDE {
		ctrs[i] = tmp[i][:]
	}
	for nr_blocks > 0 {
		n := min(ct64.STRIDE, nr_blocks)
		blocks := ctrs[:n]

		for i in 0 ..< n {
			ctr_hi, ctr_lo = ct64_inc_ctr(blocks[i], ctr_hi, ctr_lo)
		}
		ct64.encrypt_blocks(impl, blocks, blocks)

		xor_blocks(dst, src, blocks)

		if src != nil {
			src = src[n * BLOCK_SIZE:]
		}
		dst = dst[n * BLOCK_SIZE:]
		nr_blocks -= n
	}

	// Write back the counter.
	ctx._ctr_hi, ctx._ctr_lo = ctr_hi, ctr_lo

	mem.zero_explicit(&tmp, size_of(tmp))
}

@(private)
xor_blocks :: #force_inline proc "contextless" (dst, src: []byte, blocks: [][]byte) {
	// Note: This would be faster `core:simd` was used, however if
	// performance of this implementation matters to where that
	// optimization would be worth it, use chacha20poly1305, or a
	// CPU that isn't e-waste.
	#no_bounds_check {
		if src != nil {
				for i in 0 ..< len(blocks) {
					off := i * BLOCK_SIZE
					for j in 0 ..< BLOCK_SIZE {
						blocks[i][j] ~= src[off + j]
					}
				}
		}
		for i in 0 ..< len(blocks) {
			copy(dst[i * BLOCK_SIZE:], blocks[i])
		}
	}
}
