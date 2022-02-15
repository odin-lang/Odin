package jh

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Implementation of the JH hashing algorithm, as defined in <https://www3.ntu.edu.sg/home/wuhj/research/jh/index.html>
*/

import "core:os"
import "core:io"

/*
    High level API
*/

DIGEST_SIZE_224 :: 28
DIGEST_SIZE_256 :: 32
DIGEST_SIZE_384 :: 48
DIGEST_SIZE_512 :: 64

// hash_string_224 will hash the given input and return the
// computed hash
hash_string_224 :: proc(data: string) -> [DIGEST_SIZE_224]byte {
    return hash_bytes_224(transmute([]byte)(data))
}

// hash_bytes_224 will hash the given input and return the
// computed hash
hash_bytes_224 :: proc(data: []byte) -> [DIGEST_SIZE_224]byte {
    hash: [DIGEST_SIZE_224]byte
    ctx: Jh_Context
    ctx.hashbitlen = 224
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_224 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_224 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_224(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer_224 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_224 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_224, "Size of destination buffer is smaller than the digest size")
    ctx: Jh_Context
    ctx.hashbitlen = 224
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_224 will read the stream in chunks and compute a
// hash from its contents
hash_stream_224 :: proc(s: io.Stream) -> ([DIGEST_SIZE_224]byte, bool) {
    hash: [DIGEST_SIZE_224]byte
    ctx: Jh_Context
    ctx.hashbitlen = 224
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

// hash_file_224 will read the file provided by the given handle
// and compute a hash
hash_file_224 :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE_224]byte, bool) {
    if !load_at_once {
        return hash_stream_224(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_224(buf[:]), ok
        }
    }
    return [DIGEST_SIZE_224]byte{}, false
}

hash_224 :: proc {
    hash_stream_224,
    hash_file_224,
    hash_bytes_224,
    hash_string_224,
    hash_bytes_to_buffer_224,
    hash_string_to_buffer_224,
}

// hash_string_256 will hash the given input and return the
// computed hash
hash_string_256 :: proc(data: string) -> [DIGEST_SIZE_256]byte {
    return hash_bytes_256(transmute([]byte)(data))
}

// hash_bytes_256 will hash the given input and return the
// computed hash
hash_bytes_256 :: proc(data: []byte) -> [DIGEST_SIZE_256]byte {
    hash: [DIGEST_SIZE_256]byte
    ctx: Jh_Context
    ctx.hashbitlen = 256
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_256 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_256 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_256(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer_256 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_256 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_256, "Size of destination buffer is smaller than the digest size")
    ctx: Jh_Context
    ctx.hashbitlen = 256
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_256 will read the stream in chunks and compute a
// hash from its contents
hash_stream_256 :: proc(s: io.Stream) -> ([DIGEST_SIZE_256]byte, bool) {
    hash: [DIGEST_SIZE_256]byte
    ctx: Jh_Context
    ctx.hashbitlen = 256
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

// hash_file_256 will read the file provided by the given handle
// and compute a hash
hash_file_256 :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE_256]byte, bool) {
    if !load_at_once {
        return hash_stream_256(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_256(buf[:]), ok
        }
    }
    return [DIGEST_SIZE_256]byte{}, false
}

hash_256 :: proc {
    hash_stream_256,
    hash_file_256,
    hash_bytes_256,
    hash_string_256,
    hash_bytes_to_buffer_256,
    hash_string_to_buffer_256,
}

// hash_string_384 will hash the given input and return the
// computed hash
hash_string_384 :: proc(data: string) -> [DIGEST_SIZE_384]byte {
    return hash_bytes_384(transmute([]byte)(data))
}

// hash_bytes_384 will hash the given input and return the
// computed hash
hash_bytes_384 :: proc(data: []byte) -> [DIGEST_SIZE_384]byte {
    hash: [DIGEST_SIZE_384]byte
    ctx: Jh_Context
    ctx.hashbitlen = 384
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_384 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_384 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_384(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer_384 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_384 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_384, "Size of destination buffer is smaller than the digest size")
    ctx: Jh_Context
    ctx.hashbitlen = 384
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_384 will read the stream in chunks and compute a
// hash from its contents
hash_stream_384 :: proc(s: io.Stream) -> ([DIGEST_SIZE_384]byte, bool) {
    hash: [DIGEST_SIZE_384]byte
    ctx: Jh_Context
    ctx.hashbitlen = 384
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

// hash_file_384 will read the file provided by the given handle
// and compute a hash
hash_file_384 :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE_384]byte, bool) {
    if !load_at_once {
        return hash_stream_384(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_384(buf[:]), ok
        }
    }
    return [DIGEST_SIZE_384]byte{}, false
}

hash_384 :: proc {
    hash_stream_384,
    hash_file_384,
    hash_bytes_384,
    hash_string_384,
    hash_bytes_to_buffer_384,
    hash_string_to_buffer_384,
}

// hash_string_512 will hash the given input and return the
// computed hash
hash_string_512 :: proc(data: string) -> [DIGEST_SIZE_512]byte {
    return hash_bytes_512(transmute([]byte)(data))
}

// hash_bytes_512 will hash the given input and return the
// computed hash
hash_bytes_512 :: proc(data: []byte) -> [DIGEST_SIZE_512]byte {
    hash: [DIGEST_SIZE_512]byte
    ctx: Jh_Context
    ctx.hashbitlen = 512
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_512 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_512 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_512(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer_512 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_512 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_512, "Size of destination buffer is smaller than the digest size")
    ctx: Jh_Context
    ctx.hashbitlen = 512
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_512 will read the stream in chunks and compute a
// hash from its contents
hash_stream_512 :: proc(s: io.Stream) -> ([DIGEST_SIZE_512]byte, bool) {
    hash: [DIGEST_SIZE_512]byte
    ctx: Jh_Context
    ctx.hashbitlen = 512
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

// hash_file_512 will read the file provided by the given handle
// and compute a hash
hash_file_512 :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE_512]byte, bool) {
    if !load_at_once {
        return hash_stream_512(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_512(buf[:]), ok
        }
    }
    return [DIGEST_SIZE_512]byte{}, false
}

hash_512 :: proc {
    hash_stream_512,
    hash_file_512,
    hash_bytes_512,
    hash_string_512,
    hash_bytes_to_buffer_512,
    hash_string_to_buffer_512,
}

/*
    Low level API
*/

init :: proc(ctx: ^Jh_Context) {
    assert(ctx.hashbitlen == 224 || ctx.hashbitlen == 256 || ctx.hashbitlen == 384 || ctx.hashbitlen == 512, "hashbitlen must be set to 224, 256, 384 or 512")
    ctx.H[1] = byte(ctx.hashbitlen)      & 0xff
    ctx.H[0] = byte(ctx.hashbitlen >> 8) & 0xff
    F8(ctx)
}

update :: proc(ctx: ^Jh_Context, data: []byte) {
    databitlen     := u64(len(data)) * 8
    ctx.databitlen += databitlen
    i              := u64(0)

    if (ctx.buffer_size > 0) && ((ctx.buffer_size + databitlen) < 512) {
        if (databitlen & 7) == 0 {
            copy(ctx.buffer[ctx.buffer_size >> 3:], data[:64 - (ctx.buffer_size >> 3)])
        } else {
            copy(ctx.buffer[ctx.buffer_size >> 3:], data[:64 - (ctx.buffer_size >> 3) + 1])
        } 
        ctx.buffer_size += databitlen
        databitlen = 0
    }

    if (ctx.buffer_size > 0 ) && ((ctx.buffer_size + databitlen) >= 512) {
        copy(ctx.buffer[ctx.buffer_size >> 3:], data[:64 - (ctx.buffer_size >> 3)])
        i      = 64 - (ctx.buffer_size >> 3)
        databitlen = databitlen - (512 - ctx.buffer_size)
        F8(ctx)
        ctx.buffer_size = 0
    }

    for databitlen >= 512 {
        copy(ctx.buffer[:], data[i:i + 64])
        F8(ctx)
        i += 64
        databitlen -= 512
    }

    if databitlen > 0 {
        if (databitlen & 7) == 0 {
            copy(ctx.buffer[:], data[i:i + ((databitlen & 0x1ff) >> 3)])
        } else {
            copy(ctx.buffer[:], data[i:i + ((databitlen & 0x1ff) >> 3) + 1])
        }
        ctx.buffer_size = databitlen
    }
}

final :: proc(ctx: ^Jh_Context, hash: []byte) {
    if ctx.databitlen & 0x1ff == 0 {
        for i := 0; i < 64; i += 1 {
            ctx.buffer[i] = 0
        }
        ctx.buffer[0]  = 0x80
        ctx.buffer[63] = byte(ctx.databitlen)       & 0xff
        ctx.buffer[62] = byte(ctx.databitlen >> 8)  & 0xff
        ctx.buffer[61] = byte(ctx.databitlen >> 16) & 0xff
        ctx.buffer[60] = byte(ctx.databitlen >> 24) & 0xff
        ctx.buffer[59] = byte(ctx.databitlen >> 32) & 0xff
        ctx.buffer[58] = byte(ctx.databitlen >> 40) & 0xff
        ctx.buffer[57] = byte(ctx.databitlen >> 48) & 0xff
        ctx.buffer[56] = byte(ctx.databitlen >> 56) & 0xff
        F8(ctx)
    } else {
        if ctx.buffer_size & 7 == 0 {
            for i := (ctx.databitlen & 0x1ff) >> 3; i < 64; i += 1 {
                ctx.buffer[i] = 0
            }
        } else {
            for i := ((ctx.databitlen & 0x1ff) >> 3) + 1; i < 64; i += 1 {
                ctx.buffer[i] = 0
            }
        }
        ctx.buffer[(ctx.databitlen & 0x1ff) >> 3] |= 1 << (7 - (ctx.databitlen & 7))
        F8(ctx)
        for i := 0; i < 64; i += 1 {
            ctx.buffer[i] = 0
        }
        ctx.buffer[63] = byte(ctx.databitlen)       & 0xff
        ctx.buffer[62] = byte(ctx.databitlen >> 8)  & 0xff
        ctx.buffer[61] = byte(ctx.databitlen >> 16) & 0xff
        ctx.buffer[60] = byte(ctx.databitlen >> 24) & 0xff
        ctx.buffer[59] = byte(ctx.databitlen >> 32) & 0xff
        ctx.buffer[58] = byte(ctx.databitlen >> 40) & 0xff
        ctx.buffer[57] = byte(ctx.databitlen >> 48) & 0xff
        ctx.buffer[56] = byte(ctx.databitlen >> 56) & 0xff
        F8(ctx)
    }
    switch ctx.hashbitlen {
        case 224: copy(hash[:], ctx.H[100:128])
        case 256: copy(hash[:], ctx.H[96:128])
        case 384: copy(hash[:], ctx.H[80:128])
        case 512: copy(hash[:], ctx.H[64:128])
    }
}

/*
    JH implementation
*/

ROUNDCONSTANT_ZERO := [64]byte {
    0x6, 0xa, 0x0, 0x9, 0xe, 0x6, 0x6, 0x7,
    0xf, 0x3, 0xb, 0xc, 0xc, 0x9, 0x0, 0x8,
    0xb, 0x2, 0xf, 0xb, 0x1, 0x3, 0x6, 0x6,
    0xe, 0xa, 0x9, 0x5, 0x7, 0xd, 0x3, 0xe,
    0x3, 0xa, 0xd, 0xe, 0xc, 0x1, 0x7, 0x5,
    0x1, 0x2, 0x7, 0x7, 0x5, 0x0, 0x9, 0x9,
    0xd, 0xa, 0x2, 0xf, 0x5, 0x9, 0x0, 0xb,
    0x0, 0x6, 0x6, 0x7, 0x3, 0x2, 0x2, 0xa,
}

SBOX := [2][16]byte {
    {9, 0,  4, 11, 13, 12, 3, 15, 1,  10, 2, 6, 7,  5,  8,  14},
    {3, 12, 6, 13, 5,  7,  1, 9,  15, 2,  0, 4, 11, 10, 14, 8},
}

Jh_Context :: struct {
    hashbitlen:    int,
    databitlen:    u64,
    buffer_size:   u64,
    H:             [128]byte,
    A:             [256]byte,
    roundconstant: [64]byte,
    buffer:        [64]byte,
}

E8_finaldegroup :: proc(ctx: ^Jh_Context) {
    t0,t1,t2,t3: byte
    tem: [256]byte
    for i := 0; i < 128; i += 1 {
        tem[i]       = ctx.A[i << 1]
        tem[i + 128] = ctx.A[(i << 1) + 1]
    }
    for i := 0; i < 128; i += 1 {
        ctx.H[i] = 0
    }
    for i := 0; i < 256; i += 1 {
        t0 = (tem[i] >> 3) & 1
        t1 = (tem[i] >> 2) & 1
        t2 = (tem[i] >> 1) & 1
        t3 = (tem[i] >> 0) & 1

        ctx.H[uint(i) >> 3]         |= t0 << (7 - (uint(i) & 7))
        ctx.H[(uint(i) + 256) >> 3] |= t1 << (7 - (uint(i) & 7))
        ctx.H[(uint(i) + 512) >> 3] |= t2 << (7 - (uint(i) & 7))
        ctx.H[(uint(i) + 768) >> 3] |= t3 << (7 - (uint(i) & 7))
    }
}

update_roundconstant :: proc(ctx: ^Jh_Context) {
    tem: [64]byte
    t: byte
    for i := 0; i < 64; i += 1 {
        tem[i] = SBOX[0][ctx.roundconstant[i]]
    }
    for i := 0; i < 64; i += 2 {
        tem[i + 1] ~= ((tem[i]   << 1)   ~ (tem[i]   >> 3)   ~ ((tem[i]   >> 2) & 2))   & 0xf
        tem[i]     ~= ((tem[i + 1] << 1) ~ (tem[i + 1] >> 3) ~ ((tem[i + 1] >> 2) & 2)) & 0xf
    }
    for i := 0; i < 64; i += 4 {
        t          = tem[i + 2]
        tem[i + 2] = tem[i + 3]
        tem[i + 3] = t
    }
    for i := 0; i < 32; i += 1 {
        ctx.roundconstant[i]      = tem[i << 1]
        ctx.roundconstant[i + 32] = tem[(i << 1) + 1]
    }
    for i := 32; i < 64; i += 2 {
        t                        = ctx.roundconstant[i]
        ctx.roundconstant[i]     = ctx.roundconstant[i + 1]
        ctx.roundconstant[i + 1] = t
    }
}

R8 :: proc(ctx: ^Jh_Context) {
    t: byte
    tem, roundconstant_expanded: [256]byte
    for i := u32(0); i < 256; i += 1 {
        roundconstant_expanded[i] = (ctx.roundconstant[i >> 2] >> (3 - (i & 3)) ) & 1
    }
    for i := 0; i < 256; i += 1 {
        tem[i] = SBOX[roundconstant_expanded[i]][ctx.A[i]]
    }
    for i := 0; i < 256; i += 2 {
        tem[i+1] ~= ((tem[i]   << 1)   ~ (tem[i]   >> 3)   ~ ((tem[i]   >> 2) & 2))   & 0xf
        tem[i]   ~= ((tem[i + 1] << 1) ~ (tem[i + 1] >> 3) ~ ((tem[i + 1] >> 2) & 2)) & 0xf
    }
    for i := 0; i < 256; i += 4 {
        t        = tem[i + 2]
        tem[i+2] = tem[i + 3]
        tem[i+3] = t
    }
    for i := 0; i < 128; i += 1 {
        ctx.A[i]       = tem[i << 1]
        ctx.A[i + 128] = tem[(i << 1) + 1]
    }
    for i := 128; i < 256; i += 2 {
        t            = ctx.A[i]
        ctx.A[i]     = ctx.A[i + 1]
        ctx.A[i + 1] = t
    }
}

E8_initialgroup :: proc(ctx: ^Jh_Context) {
    t0, t1, t2, t3: byte
    tem:            [256]byte
    for i := u32(0); i < 256; i += 1 {
        t0     = (ctx.H[i >> 3]   >> (7 - (i & 7)))       & 1
        t1     = (ctx.H[(i + 256) >> 3] >> (7 - (i & 7))) & 1
        t2     = (ctx.H[(i + 512) >> 3] >> (7 - (i & 7))) & 1
        t3     = (ctx.H[(i + 768) >> 3] >> (7 - (i & 7))) & 1
        tem[i] = (t0 << 3) | (t1 << 2) | (t2 << 1) | (t3 << 0)
    }
    for i := 0; i < 128; i += 1 {
        ctx.A[i << 1]       = tem[i]
        ctx.A[(i << 1) + 1] = tem[i + 128]
    }
}

E8 :: proc(ctx: ^Jh_Context) {
    for i := 0; i < 64; i += 1 {
        ctx.roundconstant[i] = ROUNDCONSTANT_ZERO[i]
    }
    E8_initialgroup(ctx)
    for i := 0; i < 42; i += 1 {
        R8(ctx)
        update_roundconstant(ctx)
    }
    E8_finaldegroup(ctx)
}

F8 :: proc(ctx: ^Jh_Context) {
    for i := 0; i < 64; i += 1 {
        ctx.H[i] ~= ctx.buffer[i]
    }
    E8(ctx)
    for i := 0; i < 64; i += 1 {
        ctx.H[i + 64] ~= ctx.buffer[i]
    }
}
