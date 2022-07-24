package md4

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
        Jeroen van Rijn: Context design to be able to change from Odin implementation to bindings.

    Implementation of the MD4 hashing algorithm, as defined in RFC 1320 <https://datatracker.ietf.org/doc/html/rfc1320>
*/

import "core:mem"
import "core:os"
import "core:io"

import "../util"

/*
    High level API
*/

DIGEST_SIZE :: 16

// hash_string will hash the given input and return the
// computed hash
hash_string :: proc(data: string) -> [DIGEST_SIZE]byte {
    return hash_bytes(transmute([]byte)(data))
}

// hash_bytes will hash the given input and return the
// computed hash
hash_bytes :: proc(data: []byte) -> [DIGEST_SIZE]byte {
    hash: [DIGEST_SIZE]byte
    ctx: Md4_Context
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
    assert(len(hash) >= DIGEST_SIZE, "Size of destination buffer is smaller than the digest size")
    ctx: Md4_Context
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream will read the stream in chunks and compute a
// hash from its contents
hash_stream :: proc(s: io.Stream) -> ([DIGEST_SIZE]byte, bool) {
    hash: [DIGEST_SIZE]byte
    ctx: Md4_Context
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

init :: proc(ctx: ^Md4_Context) {
    ctx.state[0] = 0x67452301
    ctx.state[1] = 0xefcdab89
    ctx.state[2] = 0x98badcfe
    ctx.state[3] = 0x10325476
}

update :: proc(ctx: ^Md4_Context, data: []byte) {
    for i := 0; i < len(data); i += 1 {
        ctx.data[ctx.datalen] = data[i]
        ctx.datalen += 1
        if(ctx.datalen == BLOCK_SIZE) {
            transform(ctx, ctx.data[:])
            ctx.bitlen += 512
            ctx.datalen = 0
        }
    }
}

final :: proc(ctx: ^Md4_Context, hash: []byte) {
    i := ctx.datalen
    if ctx.datalen < 56 {
        ctx.data[i] = 0x80
        i += 1
        for i < 56 {
            ctx.data[i] = 0x00
            i += 1
        }
    } else if ctx.datalen >= 56 {
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
    ctx.data[56] = byte(ctx.bitlen)
    ctx.data[57] = byte(ctx.bitlen >> 8)
    ctx.data[58] = byte(ctx.bitlen >> 16)
    ctx.data[59] = byte(ctx.bitlen >> 24)
    ctx.data[60] = byte(ctx.bitlen >> 32)
    ctx.data[61] = byte(ctx.bitlen >> 40)
    ctx.data[62] = byte(ctx.bitlen >> 48)
    ctx.data[63] = byte(ctx.bitlen >> 56)
    transform(ctx, ctx.data[:])

    for i = 0; i < 4; i += 1 {
        hash[i]      = byte(ctx.state[0] >> (i * 8)) & 0x000000ff
        hash[i + 4]  = byte(ctx.state[1] >> (i * 8)) & 0x000000ff
        hash[i + 8]  = byte(ctx.state[2] >> (i * 8)) & 0x000000ff
        hash[i + 12] = byte(ctx.state[3] >> (i * 8)) & 0x000000ff
    }
}

/*
    MD4 implementation
*/

BLOCK_SIZE  :: 64

Md4_Context :: struct {
    data:    [64]byte,
    state:   [4]u32,
    bitlen:  u64,
    datalen: u32,
}

/*
    @note(zh): F, G and H, as mentioned in the RFC, have been inlined into FF, GG 
    and HH respectively, instead of declaring them separately.
*/

FF :: #force_inline proc "contextless"(a, b, c, d, x: u32, s : int) -> u32 {
    return util.ROTL32(a + ((b & c) | (~b & d)) + x, s)
}

GG :: #force_inline proc "contextless"(a, b, c, d, x: u32, s : int) -> u32 {
    return util.ROTL32(a + ((b & c) | (b & d) | (c & d)) + x + 0x5a827999, s)
}

HH :: #force_inline proc "contextless"(a, b, c, d, x: u32, s : int) -> u32 {
    return util.ROTL32(a + (b ~ c ~ d) + x + 0x6ed9eba1, s)
}

transform :: proc(ctx: ^Md4_Context, data: []byte) {
    a, b, c, d, i, j: u32
    m: [DIGEST_SIZE]u32

    for i, j = 0, 0; i < DIGEST_SIZE; i += 1 {
        m[i] = u32(data[j]) | (u32(data[j + 1]) << 8) | (u32(data[j + 2]) << 16) | (u32(data[j + 3]) << 24)
        j += 4
    }

    a = ctx.state[0]
    b = ctx.state[1]
    c = ctx.state[2]
    d = ctx.state[3]

    a = FF(a, b, c, d, m[0],  3)
    d = FF(d, a, b, c, m[1],  7)
    c = FF(c, d, a, b, m[2],  11)
    b = FF(b, c, d, a, m[3],  19)
    a = FF(a, b, c, d, m[4],  3)
    d = FF(d, a, b, c, m[5],  7)
    c = FF(c, d, a, b, m[6],  11)
    b = FF(b, c, d, a, m[7],  19)
    a = FF(a, b, c, d, m[8],  3)
    d = FF(d, a, b, c, m[9],  7)
    c = FF(c, d, a, b, m[10], 11)
    b = FF(b, c, d, a, m[11], 19)
    a = FF(a, b, c, d, m[12], 3)
    d = FF(d, a, b, c, m[13], 7)
    c = FF(c, d, a, b, m[14], 11)
    b = FF(b, c, d, a, m[15], 19)

    a = GG(a, b, c, d, m[0],  3)
    d = GG(d, a, b, c, m[4],  5)
    c = GG(c, d, a, b, m[8],  9)
    b = GG(b, c, d, a, m[12], 13)
    a = GG(a, b, c, d, m[1],  3)
    d = GG(d, a, b, c, m[5],  5)
    c = GG(c, d, a, b, m[9],  9)
    b = GG(b, c, d, a, m[13], 13)
    a = GG(a, b, c, d, m[2],  3)
    d = GG(d, a, b, c, m[6],  5)
    c = GG(c, d, a, b, m[10], 9)
    b = GG(b, c, d, a, m[14], 13)
    a = GG(a, b, c, d, m[3],  3)
    d = GG(d, a, b, c, m[7],  5)
    c = GG(c, d, a, b, m[11], 9)
    b = GG(b, c, d, a, m[15], 13)

    a = HH(a, b, c, d, m[0],  3)
    d = HH(d, a, b, c, m[8],  9)
    c = HH(c, d, a, b, m[4],  11)
    b = HH(b, c, d, a, m[12], 15)
    a = HH(a, b, c, d, m[2],  3)
    d = HH(d, a, b, c, m[10], 9)
    c = HH(c, d, a, b, m[6],  11)
    b = HH(b, c, d, a, m[14], 15)
    a = HH(a, b, c, d, m[1],  3)
    d = HH(d, a, b, c, m[9],  9)
    c = HH(c, d, a, b, m[5],  11)
    b = HH(b, c, d, a, m[13], 15)
    a = HH(a, b, c, d, m[3],  3)
    d = HH(d, a, b, c, m[11], 9)
    c = HH(c, d, a, b, m[7],  11)
    b = HH(b, c, d, a, m[15], 15)

    ctx.state[0] += a
    ctx.state[1] += b
    ctx.state[2] += c
    ctx.state[3] += d
}
