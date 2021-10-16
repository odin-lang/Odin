package gost

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
        Jeroen van Rijn: Context design to be able to change from Odin implementation to bindings.

    Implementation of the GOST hashing algorithm, as defined in RFC 5831 <https://datatracker.ietf.org/doc/html/rfc5831>
*/

import "core:mem"
import "core:os"
import "core:io"

import "../botan"
import "../_ctx"

/*
    Context initialization and switching between the Odin implementation and the bindings
*/

@(private)
_init_vtable :: #force_inline proc() -> ^_ctx.Hash_Context {
    ctx := _ctx._init_vtable()
    _assign_hash_vtable(ctx)
    return ctx
}

@(private)
_assign_hash_vtable :: #force_inline proc(ctx: ^_ctx.Hash_Context) {
    ctx.hash_bytes_32  = hash_bytes_odin
    ctx.hash_file_32   = hash_file_odin
    ctx.hash_stream_32 = hash_stream_odin
    ctx.init           = _init_odin
    ctx.update         = _update_odin
    ctx.final          = _final_odin
}

_hash_impl := _init_vtable()

// use_botan does nothing, since MD2 is not available in Botan
use_botan :: #force_inline proc() {
    botan.assign_hash_vtable(_hash_impl, botan.HASH_GOST)
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
hash_string :: proc(data: string) -> [32]byte {
    return hash_bytes(transmute([]byte)(data))
}

// hash_bytes will hash the given input and return the
// computed hash
hash_bytes :: proc(data: []byte) -> [32]byte {
    _create_gost_ctx()
    return _hash_impl->hash_bytes_32(data)
}

// hash_stream will read the stream in chunks and compute a
// hash from its contents
hash_stream :: proc(s: io.Stream) -> ([32]byte, bool) {
    _create_gost_ctx()
    return _hash_impl->hash_stream_32(s)
}

// hash_file will read the file provided by the given handle
// and compute a hash
hash_file :: proc(hd: os.Handle, load_at_once := false) -> ([32]byte, bool) {
    _create_gost_ctx()
    return _hash_impl->hash_file_32(hd, load_at_once)
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

hash_bytes_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) -> [32]byte {
    hash: [32]byte
    if c, ok := ctx.internal_ctx.(Gost_Context); ok {
        init_odin(&c)
        update_odin(&c, data)
        final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream) -> ([32]byte, bool) {
    hash: [32]byte
    if c, ok := ctx.internal_ctx.(Gost_Context); ok {
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

hash_file_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, hd: os.Handle, load_at_once := false) -> ([32]byte, bool) {
    if !load_at_once {
        return hash_stream_odin(ctx, os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_odin(ctx, buf[:]), ok
        }
    }
    return [32]byte{}, false
}

@(private)
_create_gost_ctx :: #force_inline proc() {
    ctx: Gost_Context
    _hash_impl.internal_ctx = ctx
    _hash_impl.hash_size    = ._32
}

@(private)
_init_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context) {
    _create_gost_ctx()
    if c, ok := ctx.internal_ctx.(Gost_Context); ok {
        init_odin(&c)
    }
}

@(private)
_update_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) {
    if c, ok := ctx.internal_ctx.(Gost_Context); ok {
        update_odin(&c, data)
    }
}

@(private)
_final_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, hash: []byte) {
    if c, ok := ctx.internal_ctx.(Gost_Context); ok {
        final_odin(&c, hash)
    }
}

/*
    GOST implementation
*/

Gost_Context :: struct {
    sum:           [8]u32,
    hash:          [8]u32,
    len:           [8]u32,
    partial:       [32]byte,
    partial_bytes: byte,
}

SBOX_1 : [256]u32
SBOX_2 : [256]u32
SBOX_3 : [256]u32
SBOX_4 : [256]u32

GOST_ENCRYPT_ROUND :: #force_inline proc "contextless"(l, r, t, k1, k2: u32) -> (u32, u32, u32) {
    l, r, t := l, r, t
    t  = (k1) + r
    l ~= SBOX_1[t & 0xff] ~ SBOX_2[(t >> 8) & 0xff] ~ SBOX_3[(t >> 16) & 0xff] ~ SBOX_4[t >> 24]
    t  = (k2) + l
    r ~= SBOX_1[t & 0xff] ~ SBOX_2[(t >> 8) & 0xff] ~ SBOX_3[(t >> 16) & 0xff] ~ SBOX_4[t >> 24]
    return l, r, t
}

GOST_ENCRYPT :: #force_inline proc "contextless"(a, b, c: u32, key: []u32) -> (l, r, t: u32) {
    l, r, t = GOST_ENCRYPT_ROUND(a, b, c, key[0], key[1])
    l, r, t = GOST_ENCRYPT_ROUND(l, r, t, key[2], key[3])
    l, r, t = GOST_ENCRYPT_ROUND(l, r, t, key[4], key[5])
    l, r, t = GOST_ENCRYPT_ROUND(l, r, t, key[6], key[7])
    l, r, t = GOST_ENCRYPT_ROUND(l, r, t, key[0], key[1])
    l, r, t = GOST_ENCRYPT_ROUND(l, r, t, key[2], key[3])
    l, r, t = GOST_ENCRYPT_ROUND(l, r, t, key[4], key[5])
    l, r, t = GOST_ENCRYPT_ROUND(l, r, t, key[6], key[7])
    l, r, t = GOST_ENCRYPT_ROUND(l, r, t, key[0], key[1])
    l, r, t = GOST_ENCRYPT_ROUND(l, r, t, key[2], key[3])
    l, r, t = GOST_ENCRYPT_ROUND(l, r, t, key[4], key[5])
    l, r, t = GOST_ENCRYPT_ROUND(l, r, t, key[6], key[7])
    l, r, t = GOST_ENCRYPT_ROUND(l, r, t, key[7], key[6])
    l, r, t = GOST_ENCRYPT_ROUND(l, r, t, key[5], key[4])
    l, r, t = GOST_ENCRYPT_ROUND(l, r, t, key[3], key[2])
    l, r, t = GOST_ENCRYPT_ROUND(l, r, t, key[1], key[0])
    t = r
    r = l
    l = t
    return
}

gost_bytes :: proc(ctx: ^Gost_Context, buf: []byte, bits: u32) {
    a, c: u32
    m: [8]u32

    for i, j := 0, 0; i < 8; i += 1 {
        a = u32(buf[j]) | u32(buf[j + 1]) << 8 | u32(buf[j + 2]) << 16 | u32(buf[j + 3]) << 24
        j += 4
        m[i] = a
        c = a + c + ctx.sum[i]
        ctx.sum[i] = c
        c = c < a ? 1 : 0
    }

    gost_compress(ctx.hash[:], m[:])
    ctx.len[0] += bits
    if ctx.len[0] < bits {
        ctx.len[1] += 1
    }
}

gost_compress :: proc(h, m: []u32) {
    key, u, v, w, s: [8]u32

    copy(u[:], h)
    copy(v[:], m)

    for i := 0; i < 8; i += 2 {
        w[0] = u[0] ~ v[0]
        w[1] = u[1] ~ v[1]
        w[2] = u[2] ~ v[2]
        w[3] = u[3] ~ v[3]
        w[4] = u[4] ~ v[4]
        w[5] = u[5] ~ v[5]
        w[6] = u[6] ~ v[6]
        w[7] = u[7] ~ v[7]

        key[0] = (w[0] & 0x000000ff)       | (w[2] & 0x000000ff) <<  8 | (w[4] & 0x000000ff) << 16 | (w[6] & 0x000000ff) << 24
        key[1] = (w[0] & 0x0000ff00) >>  8 | (w[2] & 0x0000ff00)       | (w[4] & 0x0000ff00) <<  8 | (w[6] & 0x0000ff00) << 16
        key[2] = (w[0] & 0x00ff0000) >> 16 | (w[2] & 0x00ff0000) >>  8 | (w[4] & 0x00ff0000)       | (w[6] & 0x00ff0000) <<  8
        key[3] = (w[0] & 0xff000000) >> 24 | (w[2] & 0xff000000) >> 16 | (w[4] & 0xff000000) >>  8 | (w[6] & 0xff000000)
        key[4] = (w[1] & 0x000000ff)       | (w[3] & 0x000000ff) <<  8 | (w[5] & 0x000000ff) << 16 | (w[7] & 0x000000ff) << 24
        key[5] = (w[1] & 0x0000ff00) >>  8 | (w[3] & 0x0000ff00)       | (w[5] & 0x0000ff00) <<  8 | (w[7] & 0x0000ff00) << 16
        key[6] = (w[1] & 0x00ff0000) >> 16 | (w[3] & 0x00ff0000) >>  8 | (w[5] & 0x00ff0000)       | (w[7] & 0x00ff0000) <<  8
        key[7] = (w[1] & 0xff000000) >> 24 | (w[3] & 0xff000000) >> 16 | (w[5] & 0xff000000) >>  8 | (w[7] & 0xff000000)

        r := h[i]
        l := h[i + 1]
        t: u32
        l, r, t = GOST_ENCRYPT(l, r, 0, key[:])

        s[i] = r
        s[i + 1] = l

        if i == 6 {
            break
        }

        l    = u[0] ~ u[2]
        r    = u[1] ~ u[3]
        u[0] = u[2]
        u[1] = u[3]
        u[2] = u[4]
        u[3] = u[5]
        u[4] = u[6]
        u[5] = u[7]
        u[6] = l
        u[7] = r

        if i == 2 {
            u[0] ~= 0xff00ff00
            u[1] ~= 0xff00ff00
            u[2] ~= 0x00ff00ff
            u[3] ~= 0x00ff00ff
            u[4] ~= 0x00ffff00
            u[5] ~= 0xff0000ff
            u[6] ~= 0x000000ff
            u[7] ~= 0xff00ffff
        }

        l    = v[0]
        r    = v[2]
        v[0] = v[4]
        v[2] = v[6]
        v[4] = l ~ r
        v[6] = v[0] ~ r
        l    = v[1]
        r    = v[3]
        v[1] = v[5]
        v[3] = v[7]
        v[5] = l ~ r
        v[7] = v[1] ~ r
    }

    u[0] = m[0] ~ s[6]
    u[1] = m[1] ~ s[7]
    u[2] = m[2] ~ (s[0] << 16) ~ (s[0] >> 16) ~ (s[0] & 0xffff) ~ 
        (s[1] & 0xffff) ~ (s[1] >> 16) ~ (s[2] << 16) ~ s[6] ~ (s[6] << 16) ~
        (s[7] & 0xffff0000) ~ (s[7] >> 16)
    u[3] = m[3] ~ (s[0] & 0xffff) ~ (s[0] << 16) ~ (s[1] & 0xffff) ~
        (s[1] << 16) ~ (s[1] >> 16) ~ (s[2] << 16) ~ (s[2] >> 16) ~
        (s[3] << 16) ~ s[6] ~ (s[6] << 16) ~ (s[6] >> 16) ~ (s[7] & 0xffff) ~
        (s[7] << 16) ~ (s[7] >> 16)
    u[4] = m[4] ~
        (s[0] & 0xffff0000) ~ (s[0] << 16) ~ (s[0] >> 16) ~
        (s[1] & 0xffff0000) ~ (s[1] >> 16) ~ (s[2] << 16) ~ (s[2] >> 16) ~
        (s[3] << 16) ~ (s[3] >> 16) ~ (s[4] << 16) ~ (s[6] << 16) ~
        (s[6] >> 16) ~(s[7] & 0xffff) ~ (s[7] << 16) ~ (s[7] >> 16)
    u[5] = m[5] ~ (s[0] << 16) ~ (s[0] >> 16) ~ (s[0] & 0xffff0000) ~
        (s[1] & 0xffff) ~ s[2] ~ (s[2] >> 16) ~ (s[3] << 16) ~ (s[3] >> 16) ~
        (s[4] << 16) ~ (s[4] >> 16) ~ (s[5] << 16) ~  (s[6] << 16) ~
        (s[6] >> 16) ~ (s[7] & 0xffff0000) ~ (s[7] << 16) ~ (s[7] >> 16)
    u[6] = m[6] ~ s[0] ~ (s[1] >> 16) ~ (s[2] << 16) ~ s[3] ~ (s[3] >> 16) ~
        (s[4] << 16) ~ (s[4] >> 16) ~ (s[5] << 16) ~ (s[5] >> 16) ~ s[6] ~
        (s[6] << 16) ~ (s[6] >> 16) ~ (s[7] << 16)
    u[7] = m[7] ~ (s[0] & 0xffff0000) ~ (s[0] << 16) ~ (s[1] & 0xffff) ~
        (s[1] << 16) ~ (s[2] >> 16) ~ (s[3] << 16) ~ s[4] ~ (s[4] >> 16) ~
        (s[5] << 16) ~ (s[5] >> 16) ~ (s[6] >> 16) ~ (s[7] & 0xffff) ~
        (s[7] << 16) ~ (s[7] >> 16)

    v[0] = h[0] ~ (u[1] << 16) ~ (u[0] >> 16)
    v[1] = h[1] ~ (u[2] << 16) ~ (u[1] >> 16)
    v[2] = h[2] ~ (u[3] << 16) ~ (u[2] >> 16)
    v[3] = h[3] ~ (u[4] << 16) ~ (u[3] >> 16)
    v[4] = h[4] ~ (u[5] << 16) ~ (u[4] >> 16)
    v[5] = h[5] ~ (u[6] << 16) ~ (u[5] >> 16)
    v[6] = h[6] ~ (u[7] << 16) ~ (u[6] >> 16)
    v[7] = h[7] ~ (u[0] & 0xffff0000) ~ (u[0] << 16) ~ (u[7] >> 16) ~ (u[1] & 0xffff0000) ~ (u[1] << 16) ~ (u[6] << 16) ~ (u[7] & 0xffff0000)

    h[0] = (v[0] & 0xffff0000) ~ (v[0] << 16) ~ (v[0] >> 16) ~ (v[1] >> 16) ~
        (v[1] & 0xffff0000) ~ (v[2] << 16) ~ (v[3] >> 16) ~ (v[4] << 16) ~
        (v[5] >> 16) ~ v[5] ~ (v[6] >> 16) ~ (v[7] << 16) ~ (v[7] >> 16) ~
        (v[7] & 0xffff)
    h[1] = (v[0] << 16) ~ (v[0] >> 16) ~ (v[0] & 0xffff0000) ~ (v[1] & 0xffff) ~
        v[2] ~ (v[2] >> 16) ~ (v[3] << 16) ~ (v[4] >> 16) ~ (v[5] << 16) ~
        (v[6] << 16) ~ v[6] ~ (v[7] & 0xffff0000) ~ (v[7] >> 16)
    h[2] = (v[0] & 0xffff) ~ (v[0] << 16) ~ (v[1] << 16) ~ (v[1] >> 16) ~
        (v[1] & 0xffff0000) ~ (v[2] << 16) ~ (v[3] >> 16) ~ v[3] ~ (v[4] << 16) ~
        (v[5] >> 16) ~ v[6] ~ (v[6] >> 16) ~ (v[7] & 0xffff) ~ (v[7] << 16) ~
        (v[7] >> 16)
    h[3] = (v[0] << 16) ~ (v[0] >> 16) ~ (v[0] & 0xffff0000) ~
        (v[1] & 0xffff0000) ~ (v[1] >> 16) ~ (v[2] << 16) ~ (v[2] >> 16) ~ v[2] ~
        (v[3] << 16) ~ (v[4] >> 16) ~ v[4] ~ (v[5] << 16) ~ (v[6] << 16) ~
        (v[7] & 0xffff) ~ (v[7] >> 16)
    h[4] = (v[0] >> 16) ~ (v[1] << 16) ~ v[1] ~ (v[2] >> 16) ~ v[2] ~
        (v[3] << 16) ~ (v[3] >> 16) ~ v[3] ~ (v[4] << 16) ~ (v[5] >> 16) ~
        v[5] ~ (v[6] << 16) ~ (v[6] >> 16) ~ (v[7] << 16)
    h[5] = (v[0] << 16) ~ (v[0] & 0xffff0000) ~ (v[1] << 16) ~ (v[1] >> 16) ~
        (v[1] & 0xffff0000) ~ (v[2] << 16) ~ v[2] ~ (v[3] >> 16) ~ v[3] ~
        (v[4] << 16) ~ (v[4] >> 16) ~ v[4] ~ (v[5] << 16) ~ (v[6] << 16) ~
        (v[6] >> 16) ~ v[6] ~ (v[7] << 16) ~ (v[7] >> 16) ~ (v[7] & 0xffff0000)
    h[6] = v[0] ~ v[2] ~ (v[2] >> 16) ~ v[3] ~ (v[3] << 16) ~ v[4] ~
        (v[4] >> 16) ~ (v[5] << 16) ~ (v[5] >> 16) ~ v[5] ~ (v[6] << 16) ~
        (v[6] >> 16) ~ v[6] ~ (v[7] << 16) ~ v[7]
    h[7] = v[0] ~ (v[0] >> 16) ~ (v[1] << 16) ~ (v[1] >> 16) ~ (v[2] << 16) ~
        (v[3] >> 16) ~ v[3] ~ (v[4] << 16) ~ v[4] ~ (v[5] >> 16) ~ v[5] ~
        (v[6] << 16) ~ (v[6] >> 16) ~ (v[7] << 16) ~ v[7]
}

init_odin :: proc(ctx: ^Gost_Context) {
    sbox: [8][16]u32 = {
        { 10, 4,  5,  6,  8,  1,  3,  7,  13, 12, 14, 0,  9,  2,  11, 15 },
        { 5,  15, 4,  0,  2,  13, 11, 9,  1,  7,  6,  3,  12, 14, 10, 8  },
        { 7,  15, 12, 14, 9,  4,  1,  0,  3,  11, 5,  2,  6,  10, 8,  13 },
        { 4,  10, 7,  12, 0,  15, 2,  8,  14, 1,  6,  5,  13, 11, 9,  3  },
        { 7,  6,  4,  11, 9,  12, 2,  10, 1,  8,  0,  14, 15, 13, 3,  5  },
        { 7,  6,  2,  4,  13, 9,  15, 0,  10, 1,  5,  11, 8,  14, 12, 3  },
        { 13, 14, 4,  1,  7,  0,  5,  10, 3,  12, 8,  15, 6,  2,  9,  11 },
        { 1,  3,  10, 9,  5,  11, 4,  15, 8,  6,  7,  14, 13, 0,  2,  12 },
    }

    i := 0
    for a := 0; a < 16; a += 1 {
        ax := sbox[1][a] << 15
        bx := sbox[3][a] << 23
        cx := sbox[5][a]
        cx = (cx >> 1) | (cx << 31)
        dx := sbox[7][a] << 7
        for b := 0; b < 16; b, i = b + 1, i + 1 {
            SBOX_1[i] = ax | (sbox[0][b] << 11)
            SBOX_2[i] = bx | (sbox[2][b] << 19)
            SBOX_3[i] = cx | (sbox[4][b] << 27)
            SBOX_4[i] = dx | (sbox[6][b] << 3)
        }
    }
}

update_odin :: proc(ctx: ^Gost_Context, data: []byte) {
    length := byte(len(data))
    j: byte

    i := ctx.partial_bytes
    for i < 32 && j < length {
        ctx.partial[i] = data[j]
        i, j = i + 1, j + 1
    }

    if i < 32 {
        ctx.partial_bytes = i
        return
    }
    gost_bytes(ctx, ctx.partial[:], 256)

    for (j + 32) < length {
        gost_bytes(ctx, data[j:], 256)
        j += 32
    }

    i = 0
    for j < length {
        ctx.partial[i] = data[j]
        i, j = i + 1, j + 1
    }
    ctx.partial_bytes = i
}

final_odin :: proc(ctx: ^Gost_Context, hash: []byte) {
    if ctx.partial_bytes > 0 {
        mem.set(&ctx.partial[ctx.partial_bytes], 0, 32 - int(ctx.partial_bytes))
        gost_bytes(ctx, ctx.partial[:], u32(ctx.partial_bytes) << 3)
    }
  
    gost_compress(ctx.hash[:], ctx.len[:])
    gost_compress(ctx.hash[:], ctx.sum[:])

    for i, j := 0, 0; i < 8; i, j = i + 1, j + 4 {
        hash[j]     = byte(ctx.hash[i])
        hash[j + 1] = byte(ctx.hash[i] >> 8)
        hash[j + 2] = byte(ctx.hash[i] >> 16)
        hash[j + 3] = byte(ctx.hash[i] >> 24)
    }
}