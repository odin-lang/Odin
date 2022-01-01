package sha1

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Implementation of the SHA1 hashing algorithm, as defined in RFC 3174 <https://datatracker.ietf.org/doc/html/rfc3174>
*/

import "core:mem"
import "core:os"
import "core:io"

import "../util"

/*
    High level API
*/

DIGEST_SIZE :: 20

// hash_string will hash the given input and return the
// computed hash
hash_string :: proc(data: string) -> [DIGEST_SIZE]byte {
    return hash_bytes(transmute([]byte)(data))
}

// hash_bytes will hash the given input and return the
// computed hash
hash_bytes :: proc(data: []byte) -> [DIGEST_SIZE]byte {
    hash: [DIGEST_SIZE]byte
    ctx: Sha1_Context
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer(transmute([]byte)(data), hash);
}

// hash_bytes_to_buffer will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE, "Size of destination buffer is smaller than the digest size")
    ctx: Sha1_Context
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream will read the stream in chunks and compute a
// hash from its contents
hash_stream :: proc(s: io.Stream) -> ([DIGEST_SIZE]byte, bool) {
    hash: [DIGEST_SIZE]byte
    ctx: Sha1_Context
    init(&ctx)
    buf := make([]byte, 512)
    defer delete(buf)
    read := 1
    for read > 0 {
        read, _ = s->impl_read(buf)
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

init :: proc(ctx: ^Sha1_Context) {
	ctx.state[0] = 0x67452301
	ctx.state[1] = 0xefcdab89
	ctx.state[2] = 0x98badcfe
	ctx.state[3] = 0x10325476
	ctx.state[4] = 0xc3d2e1f0
	ctx.k[0]     = 0x5a827999
	ctx.k[1]     = 0x6ed9eba1
	ctx.k[2]     = 0x8f1bbcdc
	ctx.k[3]     = 0xca62c1d6
}

update :: proc(ctx: ^Sha1_Context, data: []byte) {
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

final :: proc(ctx: ^Sha1_Context, hash: []byte) {
	i := ctx.datalen

	if ctx.datalen < 56 {
		ctx.data[i] = 0x80
        i += 1
        for i < 56 {
            ctx.data[i] = 0x00
            i += 1
        }
	}
	else {
		ctx.data[i] = 0x80
        i += 1
        for i < BLOCK_SIZE {
            ctx.data[i] = 0x00
            i += 1
        }
		transform(ctx, ctx.data[:])
		mem.set(&ctx.data, 0, 56)
	}

	ctx.bitlen  += u64(ctx.datalen * 8)
	ctx.data[63] = u8(ctx.bitlen)
	ctx.data[62] = u8(ctx.bitlen >> 8)
	ctx.data[61] = u8(ctx.bitlen >> 16)
	ctx.data[60] = u8(ctx.bitlen >> 24)
	ctx.data[59] = u8(ctx.bitlen >> 32)
	ctx.data[58] = u8(ctx.bitlen >> 40)
	ctx.data[57] = u8(ctx.bitlen >> 48)
	ctx.data[56] = u8(ctx.bitlen >> 56)
	transform(ctx, ctx.data[:])

	for j: u32 = 0; j < 4; j += 1 {
		hash[j]      = u8(ctx.state[0] >> (24 - j * 8)) & 0x000000ff
		hash[j + 4]  = u8(ctx.state[1] >> (24 - j * 8)) & 0x000000ff
		hash[j + 8]  = u8(ctx.state[2] >> (24 - j * 8)) & 0x000000ff
		hash[j + 12] = u8(ctx.state[3] >> (24 - j * 8)) & 0x000000ff
		hash[j + 16] = u8(ctx.state[4] >> (24 - j * 8)) & 0x000000ff
	}
}

/*
    SHA1 implementation
*/

BLOCK_SIZE  :: 64

Sha1_Context :: struct {
    data:    [BLOCK_SIZE]byte,
    datalen: u32,
    bitlen:  u64,
    state:   [5]u32,
    k:       [4]u32,
}

transform :: proc(ctx: ^Sha1_Context, data: []byte) {
    a, b, c, d, e, i, j, t: u32
    m: [80]u32

	for i, j = 0, 0; i < 16; i += 1 {
        m[i] = u32(data[j]) << 24 + u32(data[j + 1]) << 16 + u32(data[j + 2]) << 8 + u32(data[j + 3])
        j += 4
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
		t = util.ROTL32(a, 5) + ((b & c) ~ (~b & d)) + e + ctx.k[0] + m[i]
		e = d
		d = c
		c = util.ROTL32(b, 30)
		b = a
		a = t
	}
	for i < 40 {
		t = util.ROTL32(a, 5) + (b ~ c ~ d) + e + ctx.k[1] + m[i]
		e = d
		d = c
		c = util.ROTL32(b, 30)
		b = a
		a = t
        i += 1
	}
	for i < 60 {
		t = util.ROTL32(a, 5) + ((b & c) ~ (b & d) ~ (c & d)) + e + ctx.k[2] + m[i]
		e = d
		d = c
		c = util.ROTL32(b, 30)
		b = a
		a = t
        i += 1
	}
	for i < 80 {
		t = util.ROTL32(a, 5) + (b ~ c ~ d) + e + ctx.k[3] + m[i]
		e = d
		d = c
		c = util.ROTL32(b, 30)
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
