/*
package sha1 implements the SHA1 hash algorithm.

WARNING: The SHA1 algorithm is known to be insecure and should only be
used for interoperating with legacy applications.

See:
- [[ https://eprint.iacr.org/2017/190 ]]
- [[ https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.180-4.pdf ]]
- [[ https://datatracker.ietf.org/doc/html/rfc3174 ]]
*/
package sha1

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
*/

import "core:encoding/endian"
import "core:math/bits"
import "core:mem"

// DIGEST_SIZE is the SHA1 digest size in bytes.
DIGEST_SIZE :: 20

// BLOCK_SIZE is the SHA1 block size in bytes.
BLOCK_SIZE :: 64

// Context is a SHA1 instance.
Context :: struct {
	data:    [BLOCK_SIZE]byte,
	state:   [5]u32,
	k:       [4]u32,
	bitlen:  u64,
	datalen: u32,

	is_initialized: bool,
}

// init initializes a Context.
init :: proc(ctx: ^Context) {
	ctx.state[0] = 0x67452301
	ctx.state[1] = 0xefcdab89
	ctx.state[2] = 0x98badcfe
	ctx.state[3] = 0x10325476
	ctx.state[4] = 0xc3d2e1f0
	ctx.k[0] = 0x5a827999
	ctx.k[1] = 0x6ed9eba1
	ctx.k[2] = 0x8f1bbcdc
	ctx.k[3] = 0xca62c1d6

	ctx.datalen = 0
	ctx.bitlen = 0

	ctx.is_initialized = true
}

// update adds more data to the Context.
update :: proc(ctx: ^Context, data: []byte) {
	assert(ctx.is_initialized)

	for i := 0; i < len(data); i += 1 {
		ctx.data[ctx.datalen] = data[i]
		ctx.datalen += 1
		if (ctx.datalen == BLOCK_SIZE) {
			transform(ctx, ctx.data[:])
			ctx.bitlen += 512
			ctx.datalen = 0
		}
	}
}

// final finalizes the Context, writes the digest to hash, and calls
// reset on the Context.
//
// Iff finalize_clone is set, final will work on a copy of the Context,
// which is useful for for calculating rolling digests.
final :: proc(ctx: ^Context, hash: []byte, finalize_clone: bool = false) {
	assert(ctx.is_initialized)

	if len(hash) < DIGEST_SIZE {
		panic("crypto/sha1: invalid destination digest size")
	}

	ctx := ctx
	if finalize_clone {
		tmp_ctx: Context
		clone(&tmp_ctx, ctx)
		ctx = &tmp_ctx
	}
	defer(reset(ctx))

	i := ctx.datalen

	if ctx.datalen < 56 {
		ctx.data[i] = 0x80
		i += 1
		for i < 56 {
			ctx.data[i] = 0x00
			i += 1
		}
	} else {
		ctx.data[i] = 0x80
		i += 1
		for i < BLOCK_SIZE {
			ctx.data[i] = 0x00
			i += 1
		}
		transform(ctx, ctx.data[:])
		mem.set(&ctx.data, 0, 56)
	}

	ctx.bitlen += u64(ctx.datalen * 8)
	endian.unchecked_put_u64be(ctx.data[56:], ctx.bitlen)
	transform(ctx, ctx.data[:])

	for i = 0; i < DIGEST_SIZE / 4; i += 1 {
		endian.unchecked_put_u32be(hash[i * 4:], ctx.state[i])
	}
}

// clone clones the Context other into ctx.
clone :: proc(ctx, other: ^$T) {
	ctx^ = other^
}

// reset sanitizes the Context.  The Context must be re-initialized to
// be used again.
reset :: proc(ctx: ^$T) {
	if !ctx.is_initialized {
		return
	}

	mem.zero_explicit(ctx, size_of(ctx^))
}

/*
    SHA1 implementation
*/

@(private)
transform :: proc "contextless" (ctx: ^Context, data: []byte) {
	a, b, c, d, e, i, t: u32
	m: [80]u32

	for i = 0; i < 16; i += 1 {
		m[i] = endian.unchecked_get_u32be(data[i * 4:])
	}
	for i < 80 {
		m[i] = (m[i - 3] ~ m[i - 8] ~ m[i - 14] ~ m[i - 16])
		m[i] = (m[i] << 1) | (m[i] >> 31)
		i += 1
	}

	a = ctx.state[0]
	b = ctx.state[1]
	c = ctx.state[2]
	d = ctx.state[3]
	e = ctx.state[4]

	for i = 0; i < 20; i += 1 {
		t = bits.rotate_left32(a, 5) + ((b & c) ~ (~b & d)) + e + ctx.k[0] + m[i]
		e = d
		d = c
		c = bits.rotate_left32(b, 30)
		b = a
		a = t
	}
	for i < 40 {
		t = bits.rotate_left32(a, 5) + (b ~ c ~ d) + e + ctx.k[1] + m[i]
		e = d
		d = c
		c = bits.rotate_left32(b, 30)
		b = a
		a = t
		i += 1
	}
	for i < 60 {
		t = bits.rotate_left32(a, 5) + ((b & c) ~ (b & d) ~ (c & d)) + e + ctx.k[2] + m[i]
		e = d
		d = c
		c = bits.rotate_left32(b, 30)
		b = a
		a = t
		i += 1
	}
	for i < 80 {
		t = bits.rotate_left32(a, 5) + (b ~ c ~ d) + e + ctx.k[3] + m[i]
		e = d
		d = c
		c = bits.rotate_left32(b, 30)
		b = a
		a = t
		i += 1
	}

	ctx.state[0] += a
	ctx.state[1] += b
	ctx.state[2] += c
	ctx.state[3] += d
	ctx.state[4] += e
}
