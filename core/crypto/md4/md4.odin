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
import "../botan"
import "../_ctx"

/*
    Context initialization and switching between the Odin implementation and the bindings
*/

USE_BOTAN_LIB :: bool(#config(USE_BOTAN_LIB, false))

@(private)
_init_vtable :: #force_inline proc() -> ^_ctx.Hash_Context {
    ctx := _ctx._init_vtable()
    when USE_BOTAN_LIB {
        use_botan()
    } else {
        _assign_hash_vtable(ctx)
    }
    return ctx
}

@(private)
_assign_hash_vtable :: #force_inline proc(ctx: ^_ctx.Hash_Context) {
    ctx.hash_bytes_16  = hash_bytes_odin
    ctx.hash_file_16   = hash_file_odin
    ctx.hash_stream_16 = hash_stream_odin
    ctx.init           = _init_odin
    ctx.update         = _update_odin
    ctx.final          = _final_odin
}

_hash_impl := _init_vtable()

// use_botan assigns the internal vtable of the hash context to use the Botan bindings
use_botan :: #force_inline proc() {
    botan.assign_hash_vtable(_hash_impl, botan.HASH_MD4)
}

// use_odin assigns the internal vtable of the hash context to use the Odin implementation
use_odin :: #force_inline proc() {
    _assign_hash_vtable(_hash_impl)
}

/*
    High level API
*/

// hash_string will hash the given input and return the
// computed hash
hash_string :: proc(data: string) -> [16]byte {
    return hash_bytes(transmute([]byte)(data))
}

// hash_bytes will hash the given input and return the
// computed hash
hash_bytes :: proc(data: []byte) -> [16]byte {
    _create_md4_ctx()
    return _hash_impl->hash_bytes_16(data)
}

// hash_stream will read the stream in chunks and compute a
// hash from its contents
hash_stream :: proc(s: io.Stream) -> ([16]byte, bool) {
    _create_md4_ctx()
    return _hash_impl->hash_stream_16(s)
}

// hash_file will read the file provided by the given handle
// and compute a hash
hash_file :: proc(hd: os.Handle, load_at_once := false) -> ([16]byte, bool) {
    _create_md4_ctx()
    return _hash_impl->hash_file_16(hd, load_at_once)
}

hash :: proc {
    hash_stream,
    hash_file,
    hash_bytes,
    hash_string,
}

/*
    Low level API
*/

init :: proc(ctx: ^_ctx.Hash_Context) {
    _hash_impl->init()
}

update :: proc(ctx: ^_ctx.Hash_Context, data: []byte) {
    _hash_impl->update(data)
}

final :: proc(ctx: ^_ctx.Hash_Context, hash: []byte) {
    _hash_impl->final(hash)
}

hash_bytes_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) -> [16]byte {
    hash: [16]byte
    if c, ok := ctx.internal_ctx.(Md4_Context); ok {
        init_odin(&c)
        update_odin(&c, data)
        final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream) -> ([16]byte, bool) {
    hash: [16]byte
    if c, ok := ctx.internal_ctx.(Md4_Context); ok {
        init_odin(&c)
        buf := make([]byte, 512)
        defer delete(buf)
        read := 1
        for read > 0 {
            read, _ = fs->impl_read(buf)
            if read > 0 {
                update_odin(&c, buf[:read])
            } 
        }
        final_odin(&c, hash[:])
        return hash, true
    } else {
        return hash, false
    }
}

hash_file_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, hd: os.Handle, load_at_once := false) -> ([16]byte, bool) {
    if !load_at_once {
        return hash_stream_odin(ctx, os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_odin(ctx, buf[:]), ok
        }
    }
    return [16]byte{}, false
}

@(private)
_create_md4_ctx :: #force_inline proc() {
    ctx: Md4_Context
    _hash_impl.internal_ctx = ctx
    _hash_impl.hash_size    = ._16
}

@(private)
_init_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context) {
    _create_md4_ctx()
    if c, ok := ctx.internal_ctx.(Md4_Context); ok {
        init_odin(&c)
    }
}

@(private)
_update_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) {
    if c, ok := ctx.internal_ctx.(Md4_Context); ok {
        update_odin(&c, data)
    }
}

@(private)
_final_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, hash: []byte) {
    if c, ok := ctx.internal_ctx.(Md4_Context); ok {
        final_odin(&c, hash)
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
    m: [16]u32

    for i, j = 0, 0; i < 16; i += 1 {
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

init_odin :: proc(ctx: ^Md4_Context) {
    ctx.state[0] = 0x67452301
    ctx.state[1] = 0xefcdab89
    ctx.state[2] = 0x98badcfe
    ctx.state[3] = 0x10325476
}

update_odin :: proc(ctx: ^Md4_Context, data: []byte) {
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

final_odin :: proc(ctx: ^Md4_Context, hash: []byte) {
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
