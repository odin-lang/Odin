package sm3

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Implementation of the SM3 hashing algorithm, as defined in <https://datatracker.ietf.org/doc/html/draft-sca-cfrg-sm3-02>
*/

import "core:os"
import "core:io"

import "../util"

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
    hash_bytes_to_buffer(transmute([]byte)(data), hash);
}

// hash_bytes_to_buffer will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE, "Size of destination buffer is smaller than the digest size")
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

init :: proc(ctx: ^Sm3_Context) {
    ctx.state[0] = IV[0]
    ctx.state[1] = IV[1]
    ctx.state[2] = IV[2]
    ctx.state[3] = IV[3]
    ctx.state[4] = IV[4]
    ctx.state[5] = IV[5]
    ctx.state[6] = IV[6]
    ctx.state[7] = IV[7]
}

update :: proc(ctx: ^Sm3_Context, data: []byte) {
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

final :: proc(ctx: ^Sm3_Context, hash: []byte) {
    length := ctx.length

    pad: [64]byte
    pad[0] = 0x80
    if length % 64 < 56 {
        update(ctx, pad[0: 56 - length % 64])
    } else {
        update(ctx, pad[0: 64 + 56 - length % 64])
    }

    length <<= 3
    util.PUT_U64_BE(pad[:], length)
    update(ctx, pad[0: 8])
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

/*
    SM3 implementation
*/

Sm3_Context :: struct {
    state:     [8]u32,
    x:         [64]byte,
    bitlength: u64,
    length:    u64,
}

IV := [8]u32 {
    0x7380166f, 0x4914b2b9, 0x172442d7, 0xda8a0600,
    0xa96f30bc, 0x163138aa, 0xe38dee4d, 0xb0fb0e4e,
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
