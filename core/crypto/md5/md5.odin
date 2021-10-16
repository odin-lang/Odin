package md5

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
        Jeroen van Rijn: Context design to be able to change from Odin implementation to bindings.

    Implementation of the MD5 hashing algorithm, as defined in RFC 1321 <https://datatracker.ietf.org/doc/html/rfc1321>
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
    botan.assign_hash_vtable(_hash_impl, botan.HASH_MD5)
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
    _create_md5_ctx()
    return _hash_impl->hash_bytes_16(data)
}

// hash_stream will read the stream in chunks and compute a
// hash from its contents
hash_stream :: proc(s: io.Stream) -> ([16]byte, bool) {
    _create_md5_ctx()
    return _hash_impl->hash_stream_16(s)
}

// hash_file will read the file provided by the given handle
// and compute a hash
hash_file :: proc(hd: os.Handle, load_at_once := false) -> ([16]byte, bool) {
    _create_md5_ctx()
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
    if c, ok := ctx.internal_ctx.(Md5_Context); ok {
        init_odin(&c)
        update_odin(&c, data)
        final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream) -> ([16]byte, bool) {
    hash: [16]byte
    if c, ok := ctx.internal_ctx.(Md5_Context); ok {
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
_create_md5_ctx :: #force_inline proc() {
    ctx: Md5_Context
    _hash_impl.internal_ctx = ctx
    _hash_impl.hash_size    = ._16
}

@(private)
_init_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context) {
    _create_md5_ctx()
    if c, ok := ctx.internal_ctx.(Md5_Context); ok {
        init_odin(&c)
    }
}

@(private)
_update_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) {
    if c, ok := ctx.internal_ctx.(Md5_Context); ok {
        update_odin(&c, data)
    }
}

@(private)
_final_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, hash: []byte) {
    if c, ok := ctx.internal_ctx.(Md5_Context); ok {
        final_odin(&c, hash)
    }
}

/*
    MD4 implementation
*/

BLOCK_SIZE  :: 64

Md5_Context :: struct {
    data:    [BLOCK_SIZE]byte,
    state:   [4]u32,
    bitlen:  u64,
    datalen: u32,
}

/*
    @note(zh): F, G, H and I, as mentioned in the RFC, have been inlined into FF, GG, HH 
    and II respectively, instead of declaring them separately.
*/

FF :: #force_inline proc "contextless" (a, b, c, d, m: u32, s: int, t: u32) -> u32 {
    return b + util.ROTL32(a + ((b & c) | (~b & d)) + m + t, s)
}

GG :: #force_inline proc "contextless" (a, b, c, d, m: u32, s: int, t: u32) -> u32 {
    return b + util.ROTL32(a + ((b & d) | (c & ~d)) + m + t, s)
}

HH :: #force_inline proc "contextless" (a, b, c, d, m: u32, s: int, t: u32) -> u32 {
    return b + util.ROTL32(a + (b ~ c ~ d) + m + t, s)
}

II :: #force_inline proc "contextless" (a, b, c, d, m: u32, s: int, t: u32) -> u32 {
    return b + util.ROTL32(a + (c ~ (b | ~d)) + m + t, s)
}

transform :: proc(ctx: ^Md5_Context, data: []byte) {
    i, j: u32
    m: [16]u32

    for i, j = 0, 0; i < 16; i+=1 {
        m[i] = u32(data[j]) + u32(data[j + 1]) << 8 + u32(data[j + 2]) << 16 + u32(data[j + 3]) << 24
        j += 4
    }

    a := ctx.state[0]
    b := ctx.state[1]
    c := ctx.state[2]
    d := ctx.state[3]

    a = FF(a, b, c, d, m[0],   7, 0xd76aa478)
    d = FF(d, a, b, c, m[1],  12, 0xe8c7b756)
    c = FF(c, d, a, b, m[2],  17, 0x242070db)
    b = FF(b, c, d, a, m[3],  22, 0xc1bdceee)
    a = FF(a, b, c, d, m[4],   7, 0xf57c0faf)
    d = FF(d, a, b, c, m[5],  12, 0x4787c62a)
    c = FF(c, d, a, b, m[6],  17, 0xa8304613)
    b = FF(b, c, d, a, m[7],  22, 0xfd469501)
    a = FF(a, b, c, d, m[8],   7, 0x698098d8)
    d = FF(d, a, b, c, m[9],  12, 0x8b44f7af)
    c = FF(c, d, a, b, m[10], 17, 0xffff5bb1)
    b = FF(b, c, d, a, m[11], 22, 0x895cd7be)
    a = FF(a, b, c, d, m[12],  7, 0x6b901122)
    d = FF(d, a, b, c, m[13], 12, 0xfd987193)
    c = FF(c, d, a, b, m[14], 17, 0xa679438e)
    b = FF(b, c, d, a, m[15], 22, 0x49b40821)

    a = GG(a, b, c, d, m[1],   5, 0xf61e2562)
    d = GG(d, a, b, c, m[6],   9, 0xc040b340)
    c = GG(c, d, a, b, m[11], 14, 0x265e5a51)
    b = GG(b, c, d, a, m[0],  20, 0xe9b6c7aa)
    a = GG(a, b, c, d, m[5],   5, 0xd62f105d)
    d = GG(d, a, b, c, m[10],  9, 0x02441453)
    c = GG(c, d, a, b, m[15], 14, 0xd8a1e681)
    b = GG(b, c, d, a, m[4],  20, 0xe7d3fbc8)
    a = GG(a, b, c, d, m[9],   5, 0x21e1cde6)
    d = GG(d, a, b, c, m[14],  9, 0xc33707d6)
    c = GG(c, d, a, b, m[3],  14, 0xf4d50d87)
    b = GG(b, c, d, a, m[8],  20, 0x455a14ed)
    a = GG(a, b, c, d, m[13],  5, 0xa9e3e905)
    d = GG(d, a, b, c, m[2],   9, 0xfcefa3f8)
    c = GG(c, d, a, b, m[7],  14, 0x676f02d9)
    b = GG(b, c, d, a, m[12], 20, 0x8d2a4c8a)

    a = HH(a, b, c, d, m[5],   4, 0xfffa3942)
    d = HH(d, a, b, c, m[8],  11, 0x8771f681)
    c = HH(c, d, a, b, m[11], 16, 0x6d9d6122)
    b = HH(b, c, d, a, m[14], 23, 0xfde5380c)
    a = HH(a, b, c, d, m[1],   4, 0xa4beea44)
    d = HH(d, a, b, c, m[4],  11, 0x4bdecfa9)
    c = HH(c, d, a, b, m[7],  16, 0xf6bb4b60)
    b = HH(b, c, d, a, m[10], 23, 0xbebfbc70)
    a = HH(a, b, c, d, m[13],  4, 0x289b7ec6)
    d = HH(d, a, b, c, m[0],  11, 0xeaa127fa)
    c = HH(c, d, a, b, m[3],  16, 0xd4ef3085)
    b = HH(b, c, d, a, m[6],  23, 0x04881d05)
    a = HH(a, b, c, d, m[9],   4, 0xd9d4d039)
    d = HH(d, a, b, c, m[12], 11, 0xe6db99e5)
    c = HH(c, d, a, b, m[15], 16, 0x1fa27cf8)
    b = HH(b, c, d, a, m[2],  23, 0xc4ac5665)

    a = II(a, b, c, d, m[0],   6, 0xf4292244)
    d = II(d, a, b, c, m[7],  10, 0x432aff97)
    c = II(c, d, a, b, m[14], 15, 0xab9423a7)
    b = II(b, c, d, a, m[5],  21, 0xfc93a039)
    a = II(a, b, c, d, m[12],  6, 0x655b59c3)
    d = II(d, a, b, c, m[3],  10, 0x8f0ccc92)
    c = II(c, d, a, b, m[10], 15, 0xffeff47d)
    b = II(b, c, d, a, m[1],  21, 0x85845dd1)
    a = II(a, b, c, d, m[8],   6, 0x6fa87e4f)
    d = II(d, a, b, c, m[15], 10, 0xfe2ce6e0)
    c = II(c, d, a, b, m[6],  15, 0xa3014314)
    b = II(b, c, d, a, m[13], 21, 0x4e0811a1)
    a = II(a, b, c, d, m[4],   6, 0xf7537e82)
    d = II(d, a, b, c, m[11], 10, 0xbd3af235)
    c = II(c, d, a, b, m[2],  15, 0x2ad7d2bb)
    b = II(b, c, d, a, m[9],  21, 0xeb86d391)

    ctx.state[0] += a
    ctx.state[1] += b
    ctx.state[2] += c
    ctx.state[3] += d
}

init_odin :: proc(ctx: ^Md5_Context) {
    ctx.state[0] = 0x67452301
    ctx.state[1] = 0xefcdab89
    ctx.state[2] = 0x98badcfe
    ctx.state[3] = 0x10325476
}

update_odin :: proc(ctx: ^Md5_Context, data: []byte) {
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

final_odin :: proc(ctx: ^Md5_Context, hash: []byte){
    i : u32
    i = ctx.datalen

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