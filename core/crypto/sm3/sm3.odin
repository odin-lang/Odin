package sm3

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
        Jeroen van Rijn: Context design to be able to change from Odin implementation to bindings.

    Implementation of the SM3 hashing algorithm, as defined in <https://datatracker.ietf.org/doc/html/draft-sca-cfrg-sm3-02>
*/

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
    ctx.hash_bytes_32  = hash_bytes_odin
    ctx.hash_file_32   = hash_file_odin
    ctx.hash_stream_32 = hash_stream_odin
    ctx.init           = _init_odin
    ctx.update         = _update_odin
    ctx.final          = _final_odin
}

_hash_impl := _init_vtable()

// use_botan assigns the internal vtable of the hash context to use the Botan bindings
use_botan :: #force_inline proc() {
    botan.assign_hash_vtable(_hash_impl, botan.HASH_SM3)
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
    _create_sm3_ctx()
    return _hash_impl->hash_bytes_32(data)
}

// hash_stream will read the stream in chunks and compute a
// hash from its contents
hash_stream :: proc(s: io.Stream) -> ([32]byte, bool) {
    _create_sm3_ctx()
    return _hash_impl->hash_stream_32(s)
}

// hash_file will read the file provided by the given handle
// and compute a hash
hash_file :: proc(hd: os.Handle, load_at_once := false) -> ([32]byte, bool) {
    _create_sm3_ctx()
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
    if c, ok := ctx.internal_ctx.(Sm3_Context); ok {
        init_odin(&c)
        update_odin(&c, data)
        final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream) -> ([32]byte, bool) {
    hash: [32]byte
    if c, ok := ctx.internal_ctx.(Sm3_Context); ok {
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
_create_sm3_ctx :: #force_inline proc() {
    ctx: Sm3_Context
    _hash_impl.internal_ctx = ctx
    _hash_impl.hash_size    = ._32
}

@(private)
_init_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context) {
    _create_sm3_ctx()
    if c, ok := ctx.internal_ctx.(Sm3_Context); ok {
        init_odin(&c)
    }
}

@(private)
_update_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) {
    if c, ok := ctx.internal_ctx.(Sm3_Context); ok {
        update_odin(&c, data)
    }
}

@(private)
_final_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, hash: []byte) {
    if c, ok := ctx.internal_ctx.(Sm3_Context); ok {
        final_odin(&c, hash)
    }
}

/*
    SM3 implementation
*/

Sm3_Context :: struct {
    state:     [8]u32,
    x:         [64]byte,
    bitlength: u64,
    length:    u64,
}

BLOCK_SIZE_IN_BYTES :: 64
BLOCK_SIZE_IN_32    :: 16

IV := [8]u32 {
    0x7380166f, 0x4914b2b9, 0x172442d7, 0xda8a0600,
    0xa96f30bc, 0x163138aa, 0xe38dee4d, 0xb0fb0e4e,
}

init_odin :: proc(ctx: ^Sm3_Context) {
    ctx.state[0] = IV[0]
    ctx.state[1] = IV[1]
    ctx.state[2] = IV[2]
    ctx.state[3] = IV[3]
    ctx.state[4] = IV[4]
    ctx.state[5] = IV[5]
    ctx.state[6] = IV[6]
    ctx.state[7] = IV[7]
}

block :: proc "contextless" (ctx: ^Sm3_Context, buf: []byte) {
    buf := buf

    w:  [68]u32
    wp: [64]u32

    state0, state1, state2, state3 := ctx.state[0], ctx.state[1], ctx.state[2], ctx.state[3]
    state4, state5, state6, state7 := ctx.state[4], ctx.state[5], ctx.state[6], ctx.state[7]

    for len(buf) >= 64 {
        for i := 0; i < 16; i += 1 {
            j := i * 4
            w[i] = u32(buf[j]) << 24 | u32(buf[j + 1]) << 16 | u32(buf[j + 2]) << 8 | u32(buf[j + 3])
        }
        for i := 16; i < 68; i += 1 {
            p1v := w[i - 16] ~ w[i - 9] ~ util.ROTL32(w[i - 3], 15)
            // @note(zh): inlined P1
            w[i] = p1v ~ util.ROTL32(p1v, 15) ~ util.ROTL32(p1v, 23) ~ util.ROTL32(w[i - 13], 7) ~ w[i - 6]
        }
        for i := 0; i < 64; i += 1 {
            wp[i] = w[i] ~ w[i + 4]
        }

        a, b, c, d := state0, state1, state2, state3
        e, f, g, h := state4, state5, state6, state7

        for i := 0; i < 16; i += 1 {
            v1  := util.ROTL32(u32(a), 12)
            ss1 := util.ROTL32(v1 + u32(e) + util.ROTL32(0x79cc4519, i), 7)
            ss2 := ss1 ~ v1

            // @note(zh): inlined FF1
            tt1 := u32(a ~ b ~ c) + u32(d) + ss2 + wp[i]
            // @note(zh): inlined GG1
            tt2 := u32(e ~ f ~ g) + u32(h) + ss1 + w[i]

            a, b, c, d = tt1, a, util.ROTL32(u32(b), 9), c
            // @note(zh): inlined P0
            e, f, g, h = (tt2 ~ util.ROTL32(tt2, 9) ~ util.ROTL32(tt2, 17)), e, util.ROTL32(u32(f), 19), g
        }

        for i := 16; i < 64; i += 1 {
            v   := util.ROTL32(u32(a), 12)
            ss1 := util.ROTL32(v + u32(e) + util.ROTL32(0x7a879d8a, i % 32), 7)
            ss2 := ss1 ~ v

            // @note(zh): inlined FF2
            tt1 := u32(((a & b) | (a & c) | (b & c)) + d) + ss2 + wp[i]
            // @note(zh): inlined GG2
            tt2 := u32(((e & f) | ((~e) & g)) + h) + ss1 + w[i]

            a, b, c, d = tt1, a, util.ROTL32(u32(b), 9), c
            // @note(zh): inlined P0
            e, f, g, h = (tt2 ~ util.ROTL32(tt2, 9) ~ util.ROTL32(tt2, 17)), e, util.ROTL32(u32(f), 19), g
        }

        state0 ~= a
        state1 ~= b
        state2 ~= c
        state3 ~= d
        state4 ~= e
        state5 ~= f
        state6 ~= g
        state7 ~= h

        buf = buf[64:]
    }

    ctx.state[0], ctx.state[1], ctx.state[2], ctx.state[3] = state0, state1, state2, state3
    ctx.state[4], ctx.state[5], ctx.state[6], ctx.state[7] = state4, state5, state6, state7
}

update_odin :: proc(ctx: ^Sm3_Context, data: []byte) {
    data := data
    ctx.length += u64(len(data))

    if ctx.bitlength > 0 {
        n := copy(ctx.x[ctx.bitlength:], data[:])
        ctx.bitlength += u64(n)
        if ctx.bitlength == 64 {
            block(ctx, ctx.x[:])
            ctx.bitlength = 0
        }
        data = data[n:]
    }
    if len(data) >= 64 {
        n := len(data) &~ (64 - 1)
        block(ctx, data[:n])
        data = data[n:]
    }
    if len(data) > 0 {
        ctx.bitlength = u64(copy(ctx.x[:], data[:]))
    }
}

final_odin :: proc(ctx: ^Sm3_Context, hash: []byte) {
    length := ctx.length

    pad: [64]byte
    pad[0] = 0x80
    if length % 64 < 56 {
        update_odin(ctx, pad[0: 56 - length % 64])
    } else {
        update_odin(ctx, pad[0: 64 + 56 - length % 64])
    }

    length <<= 3
    util.PUT_U64_BE(pad[:], length)
    update_odin(ctx, pad[0: 8])
    assert(ctx.bitlength == 0)

    util.PUT_U32_BE(hash[0:],  ctx.state[0])
    util.PUT_U32_BE(hash[4:],  ctx.state[1])
    util.PUT_U32_BE(hash[8:],  ctx.state[2])
    util.PUT_U32_BE(hash[12:], ctx.state[3])
    util.PUT_U32_BE(hash[16:], ctx.state[4])
    util.PUT_U32_BE(hash[20:], ctx.state[5])
    util.PUT_U32_BE(hash[24:], ctx.state[6])
    util.PUT_U32_BE(hash[28:], ctx.state[7])
}
