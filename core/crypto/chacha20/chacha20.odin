/*
package chacha20 implements the ChaCha20 and XChaCha20 stream ciphers.

See:
- [[ https://datatracker.ietf.org/doc/html/rfc8439 ]]
- [[ https://datatracker.ietf.org/doc/draft-irtf-cfrg-xchacha/03/ ]]
*/
package chacha20

import "core:bytes"
import "core:crypto/_chacha20"
import "core:mem"

// KEY_SIZE is the (X)ChaCha20 key size in bytes.
KEY_SIZE :: _chacha20.KEY_SIZE
// IV_SIZE is the ChaCha20 IV size in bytes.
IV_SIZE :: _chacha20.IV_SIZE
// XIV_SIZE is the XChaCha20 IV size in bytes.
XIV_SIZE :: _chacha20.XIV_SIZE

// Context is a ChaCha20 or XChaCha20 instance.
Context :: struct {
	_state: _chacha20.Context,
	_impl:  Implementation,
}

// init inititializes a Context for ChaCha20 or XChaCha20 with the provided
// key and iv.
init :: proc(ctx: ^Context, key, iv: []byte, impl := DEFAULT_IMPLEMENTATION) {
	if len(key) != KEY_SIZE {
		panic("crypto/chacha20: invalid (X)ChaCha20 key size")
	}
	if l := len(iv); l != IV_SIZE && l != XIV_SIZE {
		panic("crypto/chacha20: invalid (X)ChaCha20 IV size")
	}

	k, n := key, iv

	init_impl(ctx, impl)

	is_xchacha := len(iv) == XIV_SIZE
	if is_xchacha {
		sub_iv: [IV_SIZE]byte
		sub_key := ctx._state._buffer[:KEY_SIZE]
		hchacha20(sub_key, k, n, ctx._impl)
		k = sub_key
		copy(sub_iv[4:], n[16:])
		n = sub_iv[:]
	}

	_chacha20.init(&ctx._state, k, n, is_xchacha)

	if is_xchacha {
		// The sub-key is stored in the keystream buffer.  While
		// this will be overwritten in most circumstances, explicitly
		// clear it out early.
		mem.zero_explicit(&ctx._state._buffer, KEY_SIZE)
	}
}

// seek seeks the (X)ChaCha20 stream counter to the specified block.
seek :: proc(ctx: ^Context, block_nr: u64) {
	_chacha20.seek(&ctx._state, block_nr)
}

// xor_bytes XORs each byte in src with bytes taken from the (X)ChaCha20
// keystream, and writes the resulting output to dst.  Dst and src MUST
// alias exactly or not at all.
xor_bytes :: proc(ctx: ^Context, dst, src: []byte) {
	assert(ctx._state._is_initialized)

	src, dst := src, dst
	if dst_len := len(dst); dst_len < len(src) {
		src = src[:dst_len]
	}

	if bytes.alias_inexactly(dst, src) {
		panic("crypto/chacha20: dst and src alias inexactly")
	}

	st := &ctx._state
	#no_bounds_check for remaining := len(src); remaining > 0; {
		// Process multiple blocks at once
		if st._off == _chacha20.BLOCK_SIZE {
			if nr_blocks := remaining / _chacha20.BLOCK_SIZE; nr_blocks > 0 {
				direct_bytes := nr_blocks * _chacha20.BLOCK_SIZE
				stream_blocks(ctx, dst, src, nr_blocks)
				remaining -= direct_bytes
				if remaining == 0 {
					return
				}
				dst = dst[direct_bytes:]
				src = src[direct_bytes:]
			}

			// If there is a partial block, generate and buffer 1 block
			// worth of keystream.
			stream_blocks(ctx, st._buffer[:], nil, 1)
			st._off = 0
		}

		// Process partial blocks from the buffered keystream.
		to_xor := min(_chacha20.BLOCK_SIZE - st._off, remaining)
		buffered_keystream := st._buffer[st._off:]
		for i := 0; i < to_xor; i = i + 1 {
			dst[i] = buffered_keystream[i] ~ src[i]
		}
		st._off += to_xor
		dst = dst[to_xor:]
		src = src[to_xor:]
		remaining -= to_xor
	}
}

// keystream_bytes fills dst with the raw (X)ChaCha20 keystream output.
keystream_bytes :: proc(ctx: ^Context, dst: []byte) {
	assert(ctx._state._is_initialized)

	dst, st := dst, &ctx._state
	#no_bounds_check for remaining := len(dst); remaining > 0; {
		// Process multiple blocks at once
		if st._off == _chacha20.BLOCK_SIZE {
			if nr_blocks := remaining / _chacha20.BLOCK_SIZE; nr_blocks > 0 {
				direct_bytes := nr_blocks * _chacha20.BLOCK_SIZE
				stream_blocks(ctx, dst, nil, nr_blocks)
				remaining -= direct_bytes
				if remaining == 0 {
					return
				}
				dst = dst[direct_bytes:]
			}

			// If there is a partial block, generate and buffer 1 block
			// worth of keystream.
			stream_blocks(ctx, st._buffer[:], nil, 1)
			st._off = 0
		}

		// Process partial blocks from the buffered keystream.
		to_copy := min(_chacha20.BLOCK_SIZE - st._off, remaining)
		buffered_keystream := st._buffer[st._off:]
		copy(dst[:to_copy], buffered_keystream[:to_copy])
		st._off += to_copy
		dst = dst[to_copy:]
		remaining -= to_copy
	}
}

// reset sanitizes the Context.  The Context must be re-initialized to
// be used again.
reset :: proc(ctx: ^Context) {
	_chacha20.reset(&ctx._state)
}
