package sm3

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Implementation of the SM3 hashing algorithm, as defined in <https://datatracker.ietf.org/doc/html/draft-sca-cfrg-sm3-02>
*/

import "core:encoding/endian"
import "core:io"
import "core:math/bits"
import "core:os"

/*
    High level API
*/

DIGEST_SIZE :: 32

// hash_string will hash the given input and return the
// computed hash
hash_string :: proc(data: string) -> [DIGEST_SIZE]byte {
	return hash_bytes(transmute([]byte)(data))
}

// hash_bytes will hash the given input and return the
// computed hash
hash_bytes :: proc(data: []byte) -> [DIGEST_SIZE]byte {
	hash: [DIGEST_SIZE]byte
	ctx: Sm3_Context
	init(&ctx)
	update(&ctx, data)
	final(&ctx, hash[:])
	return hash
}

// hash_string_to_buffer will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer :: proc(data: string, hash: []byte) {
	hash_bytes_to_buffer(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer :: proc(data, hash: []byte) {
	ctx: Sm3_Context
	init(&ctx)
	update(&ctx, data)
	final(&ctx, hash)
}

// hash_stream will read the stream in chunks and compute a
// hash from its contents
hash_stream :: proc(s: io.Stream) -> ([DIGEST_SIZE]byte, bool) {
	hash: [DIGEST_SIZE]byte
	ctx: Sm3_Context
	init(&ctx)
	buf := make([]byte, 512)
	defer delete(buf)
	read := 1
	for read > 0 {
		read, _ = io.read(s, buf)
		if read > 0 {
			update(&ctx, buf[:read])
		}
	}
	final(&ctx, hash[:])
	return hash, true
}

// hash_file will read the file provided by the given handle
// and compute a hash
hash_file :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE]byte, bool) {
	if !load_at_once {
		return hash_stream(os.stream_from_handle(hd))
	} else {
		if buf, ok := os.read_entire_file(hd); ok {
			return hash_bytes(buf[:]), ok
		}
	}
	return [DIGEST_SIZE]byte{}, false
}

hash :: proc {
	hash_stream,
	hash_file,
	hash_bytes,
	hash_string,
	hash_bytes_to_buffer,
	hash_string_to_buffer,
}

/*
    Low level API
*/

init :: proc(ctx: ^Sm3_Context) {
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

update :: proc(ctx: ^Sm3_Context, data: []byte) {
	assert(ctx.is_initialized)

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

final :: proc(ctx: ^Sm3_Context, hash: []byte) {
	assert(ctx.is_initialized)

	if len(hash) < DIGEST_SIZE {
		panic("crypto/sm3: invalid destination digest size")
	}

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
	assert(ctx.bitlength == 0)

	for i := 0; i < DIGEST_SIZE / 4; i += 1 {
		endian.unchecked_put_u32be(hash[i * 4:], ctx.state[i])
	}

	ctx.is_initialized = false
}

/*
    SM3 implementation
*/

BLOCK_SIZE :: 64

Sm3_Context :: struct {
	state:     [8]u32,
	x:         [BLOCK_SIZE]byte,
	bitlength: u64,
	length:    u64,

	is_initialized: bool,
}

@(private)
IV := [8]u32 {
	0x7380166f, 0x4914b2b9, 0x172442d7, 0xda8a0600,
	0xa96f30bc, 0x163138aa, 0xe38dee4d, 0xb0fb0e4e,
}

@(private)
block :: proc "contextless" (ctx: ^Sm3_Context, buf: []byte) {
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
