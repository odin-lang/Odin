/*
package sm3 implements the SM3 hash algorithm.

See:
- [[ https://datatracker.ietf.org/doc/html/draft-sca-cfrg-sm3-02 ]]
*/
package sm3

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
*/

import "core:encoding/endian"
import "core:math/bits"
import "core:mem"

// DIGEST_SIZE is the SM3 digest size in bytes.
DIGEST_SIZE :: 32

// BLOCK_SIZE is the SM3 block size in bytes.
BLOCK_SIZE :: 64

// Context is a SM3 instance.
Context :: struct {
	state:     [8]u32,
	x:         [BLOCK_SIZE]byte,
	bitlength: u64,
	length:    u64,

	is_initialized: bool,
}

// init initializes a Context.
init :: proc(ctx: ^Context) {
	ctx.state[0] = IV[0]
	ctx.state[1] = IV[1]
	ctx.state[2] = IV[2]
	ctx.state[3] = IV[3]
	ctx.state[4] = IV[4]
	ctx.state[5] = IV[5]
	ctx.state[6] = IV[6]
	ctx.state[7] = IV[7]

	ctx.length = 0
	ctx.bitlength = 0

	ctx.is_initialized = true
}

// update adds more data to the Context.
update :: proc(ctx: ^Context, data: []byte) {
	ensure(ctx.is_initialized)

	data := data
	ctx.length += u64(len(data))

	if ctx.bitlength > 0 {
		n := copy(ctx.x[ctx.bitlength:], data[:])
		ctx.bitlength += u64(n)
		if ctx.bitlength == BLOCK_SIZE {
			block(ctx, ctx.x[:])
			ctx.bitlength = 0
		}
		data = data[n:]
	}
	if len(data) >= BLOCK_SIZE {
		n := len(data) &~ (BLOCK_SIZE - 1)
		block(ctx, data[:n])
		data = data[n:]
	}
	if len(data) > 0 {
		ctx.bitlength = u64(copy(ctx.x[:], data[:]))
	}
}

// final finalizes the Context, writes the digest to hash, and calls
// reset on the Context.
//
// Iff finalize_clone is set, final will work on a copy of the Context,
// which is useful for for calculating rolling digests.
final :: proc(ctx: ^Context, hash: []byte, finalize_clone: bool = false) {
	ensure(ctx.is_initialized)
	ensure(len(hash) >= DIGEST_SIZE, "crypto/sm3: invalid destination digest size")

	ctx := ctx
	if finalize_clone {
		tmp_ctx: Context
		clone(&tmp_ctx, ctx)
		ctx = &tmp_ctx
	}
	defer(reset(ctx))

	length := ctx.length

	pad: [BLOCK_SIZE]byte
	pad[0] = 0x80
	if length % BLOCK_SIZE < 56 {
		update(ctx, pad[0:56 - length % BLOCK_SIZE])
	} else {
		update(ctx, pad[0:BLOCK_SIZE + 56 - length % BLOCK_SIZE])
	}

	length <<= 3
	endian.unchecked_put_u64be(pad[:], length)
	update(ctx, pad[0:8])
	assert(ctx.bitlength == 0) // Check for bugs

	for i := 0; i < DIGEST_SIZE / 4; i += 1 {
		endian.unchecked_put_u32be(hash[i * 4:], ctx.state[i])
	}
}

// clone clones the Context other into ctx.
clone :: proc(ctx, other: ^Context) {
	ctx^ = other^
}

// reset sanitizes the Context.  The Context must be re-initialized to
// be used again.
reset :: proc(ctx: ^Context) {
	if !ctx.is_initialized {
		return
	}

	mem.zero_explicit(ctx, size_of(ctx^))
}

/*
    SM3 implementation
*/

@(private, rodata)
IV := [8]u32 {
	0x7380166f, 0x4914b2b9, 0x172442d7, 0xda8a0600,
	0xa96f30bc, 0x163138aa, 0xe38dee4d, 0xb0fb0e4e,
}

@(private)
block :: proc "contextless" (ctx: ^Context, buf: []byte) {
	buf := buf

	w: [68]u32
	wp: [64]u32

	state0, state1, state2, state3 := ctx.state[0], ctx.state[1], ctx.state[2], ctx.state[3]
	state4, state5, state6, state7 := ctx.state[4], ctx.state[5], ctx.state[6], ctx.state[7]

	for len(buf) >= BLOCK_SIZE {
		for i := 0; i < 16; i += 1 {
			w[i] = endian.unchecked_get_u32be(buf[i * 4:])
		}
		for i := 16; i < 68; i += 1 {
			p1v := w[i - 16] ~ w[i - 9] ~ bits.rotate_left32(w[i - 3], 15)
			// @note(zh): inlined P1
			w[i] =
				p1v ~
				bits.rotate_left32(p1v, 15) ~
				bits.rotate_left32(p1v, 23) ~
				bits.rotate_left32(w[i - 13], 7) ~
				w[i - 6]
		}
		for i := 0; i < 64; i += 1 {
			wp[i] = w[i] ~ w[i + 4]
		}

		a, b, c, d := state0, state1, state2, state3
		e, f, g, h := state4, state5, state6, state7

		for i := 0; i < 16; i += 1 {
			v1 := bits.rotate_left32(u32(a), 12)
			ss1 := bits.rotate_left32(v1 + u32(e) + bits.rotate_left32(0x79cc4519, i), 7)
			ss2 := ss1 ~ v1

			// @note(zh): inlined FF1
			tt1 := u32(a ~ b ~ c) + u32(d) + ss2 + wp[i]
			// @note(zh): inlined GG1
			tt2 := u32(e ~ f ~ g) + u32(h) + ss1 + w[i]

			a, b, c, d = tt1, a, bits.rotate_left32(u32(b), 9), c
			// @note(zh): inlined P0
			e, f, g, h =
				(tt2 ~ bits.rotate_left32(tt2, 9) ~ bits.rotate_left32(tt2, 17)),
				e,
				bits.rotate_left32(u32(f), 19),
				g
		}

		for i := 16; i < 64; i += 1 {
			v := bits.rotate_left32(u32(a), 12)
			ss1 := bits.rotate_left32(v + u32(e) + bits.rotate_left32(0x7a879d8a, i % 32), 7)
			ss2 := ss1 ~ v

			// @note(zh): inlined FF2
			tt1 := u32(((a & b) | (a & c) | (b & c)) + d) + ss2 + wp[i]
			// @note(zh): inlined GG2
			tt2 := u32(((e & f) | ((~e) & g)) + h) + ss1 + w[i]

			a, b, c, d = tt1, a, bits.rotate_left32(u32(b), 9), c
			// @note(zh): inlined P0
			e, f, g, h =
				(tt2 ~ bits.rotate_left32(tt2, 9) ~ bits.rotate_left32(tt2, 17)),
				e,
				bits.rotate_left32(u32(f), 19),
				g
		}

		state0 ~= a
		state1 ~= b
		state2 ~= c
		state3 ~= d
		state4 ~= e
		state5 ~= f
		state6 ~= g
		state7 ~= h

		buf = buf[BLOCK_SIZE:]
	}

	ctx.state[0], ctx.state[1], ctx.state[2], ctx.state[3] = state0, state1, state2, state3
	ctx.state[4], ctx.state[5], ctx.state[6], ctx.state[7] = state4, state5, state6, state7
}
