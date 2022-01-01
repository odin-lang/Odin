package blake

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Implementation of the BLAKE hashing algorithm, as defined in <https://web.archive.org/web/20190915215948/https://131002.net/blake>
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
hash_string_224 :: proc "contextless" (data: string) -> [DIGEST_SIZE_224]byte {
    return hash_bytes_224(transmute([]byte)(data))
}

// hash_bytes_224 will hash the given input and return the
// computed hash
hash_bytes_224 :: proc "contextless" (data: []byte) -> [DIGEST_SIZE_224]byte {
    hash: [DIGEST_SIZE_224]byte
    ctx: Blake256_Context
    ctx.is224 = true
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_224 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_224 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_224(transmute([]byte)(data), hash);
}

// hash_bytes_to_buffer_224 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_224 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_224, "Size of destination buffer is smaller than the digest size")
    ctx: Blake256_Context
    ctx.is224 = true
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_224 will read the stream in chunks and compute a
// hash from its contents
hash_stream_224 :: proc(s: io.Stream) -> ([DIGEST_SIZE_224]byte, bool) {
    hash: [DIGEST_SIZE_224]byte
    ctx: Blake256_Context
    ctx.is224 = true
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
hash_string_256 :: proc "contextless" (data: string) -> [DIGEST_SIZE_256]byte {
    return hash_bytes_256(transmute([]byte)(data))
}

// hash_bytes_256 will hash the given input and return the
// computed hash
hash_bytes_256 :: proc "contextless" (data: []byte) -> [DIGEST_SIZE_256]byte {
    hash: [DIGEST_SIZE_256]byte
    ctx: Blake256_Context
    ctx.is224 = false
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_256 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_256 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_256(transmute([]byte)(data), hash);
}

// hash_bytes_to_buffer_256 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_256 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_256, "Size of destination buffer is smaller than the digest size")
    ctx: Blake256_Context
    ctx.is224 = false
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_256 will read the stream in chunks and compute a
// hash from its contents
hash_stream_256 :: proc(s: io.Stream) -> ([DIGEST_SIZE_256]byte, bool) {
    hash: [DIGEST_SIZE_256]byte
    ctx: Blake256_Context
    ctx.is224 = false
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
hash_string_384 :: proc "contextless" (data: string) -> [DIGEST_SIZE_384]byte {
    return hash_bytes_384(transmute([]byte)(data))
}

// hash_bytes_384 will hash the given input and return the
// computed hash
hash_bytes_384 :: proc "contextless" (data: []byte) -> [DIGEST_SIZE_384]byte {
    hash: [DIGEST_SIZE_384]byte
    ctx: Blake512_Context
    ctx.is384 = true
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_384 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_384 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_384(transmute([]byte)(data), hash);
}

// hash_bytes_to_buffer_384 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_384 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_384, "Size of destination buffer is smaller than the digest size")
    ctx: Blake512_Context
    ctx.is384 = true
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_384 will read the stream in chunks and compute a
// hash from its contents
hash_stream_384 :: proc(s: io.Stream) -> ([DIGEST_SIZE_384]byte, bool) {
    hash: [DIGEST_SIZE_384]byte
    ctx: Blake512_Context
    ctx.is384 = true
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
hash_string_512 :: proc "contextless" (data: string) -> [DIGEST_SIZE_512]byte {
    return hash_bytes_512(transmute([]byte)(data))
}

// hash_bytes_512 will hash the given input and return the
// computed hash
hash_bytes_512 :: proc "contextless" (data: []byte) -> [DIGEST_SIZE_512]byte {
    hash: [DIGEST_SIZE_512]byte
    ctx: Blake512_Context
    ctx.is384 = false
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_512 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_512 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_512(transmute([]byte)(data), hash);
}

// hash_bytes_to_buffer_512 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_512 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_512, "Size of destination buffer is smaller than the digest size")
    ctx: Blake512_Context
    ctx.is384 = false
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_512 will read the stream in chunks and compute a
// hash from its contents
hash_stream_512 :: proc(s: io.Stream) -> ([DIGEST_SIZE_512]byte, bool) {
    hash: [DIGEST_SIZE_512]byte
    ctx: Blake512_Context
    ctx.is384 = false
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

init :: proc "contextless" (ctx: ^$T) {
    when T == Blake256_Context {
        if ctx.is224 {
            ctx.h[0] = 0xc1059ed8
            ctx.h[1] = 0x367cd507
            ctx.h[2] = 0x3070dd17
            ctx.h[3] = 0xf70e5939
            ctx.h[4] = 0xffc00b31
            ctx.h[5] = 0x68581511
            ctx.h[6] = 0x64f98fa7
            ctx.h[7] = 0xbefa4fa4
        } else {
            ctx.h[0] = 0x6a09e667
            ctx.h[1] = 0xbb67ae85
            ctx.h[2] = 0x3c6ef372
            ctx.h[3] = 0xa54ff53a
            ctx.h[4] = 0x510e527f
            ctx.h[5] = 0x9b05688c
            ctx.h[6] = 0x1f83d9ab
            ctx.h[7] = 0x5be0cd19
        }
    } else when T == Blake512_Context {
        if ctx.is384 {
            ctx.h[0] = 0xcbbb9d5dc1059ed8
            ctx.h[1] = 0x629a292a367cd507
            ctx.h[2] = 0x9159015a3070dd17
            ctx.h[3] = 0x152fecd8f70e5939
            ctx.h[4] = 0x67332667ffc00b31
            ctx.h[5] = 0x8eb44a8768581511
            ctx.h[6] = 0xdb0c2e0d64f98fa7
            ctx.h[7] = 0x47b5481dbefa4fa4
        } else {
            ctx.h[0] = 0x6a09e667f3bcc908
            ctx.h[1] = 0xbb67ae8584caa73b
            ctx.h[2] = 0x3c6ef372fe94f82b
            ctx.h[3] = 0xa54ff53a5f1d36f1
            ctx.h[4] = 0x510e527fade682d1
            ctx.h[5] = 0x9b05688c2b3e6c1f
            ctx.h[6] = 0x1f83d9abfb41bd6b
            ctx.h[7] = 0x5be0cd19137e2179
        }
    }
}

update :: proc "contextless" (ctx: ^$T, data: []byte) {
    data := data
    when T == Blake256_Context {
        if ctx.nx > 0 {
            n := copy(ctx.x[ctx.nx:], data)
            ctx.nx += n
            if ctx.nx == BLOCKSIZE_256 {
                block256(ctx, ctx.x[:])
                ctx.nx = 0
            }
            data = data[n:]
        }
        if len(data) >= BLOCKSIZE_256 {
            n := len(data) &~ (BLOCKSIZE_256 - 1)
            block256(ctx, data[:n])
            data = data[n:]
        }
        if len(data) > 0 {
            ctx.nx = copy(ctx.x[:], data)
        }
    } else when T == Blake512_Context {
        if ctx.nx > 0 {
            n := copy(ctx.x[ctx.nx:], data)
            ctx.nx += n
            if ctx.nx == BLOCKSIZE_512 {
                block512(ctx, ctx.x[:])
                ctx.nx = 0
            }
            data = data[n:]
        }
        if len(data) >= BLOCKSIZE_512 {
            n := len(data) &~ (BLOCKSIZE_512 - 1)
            block512(ctx, data[:n])
            data = data[n:]
        }
        if len(data) > 0 {
            ctx.nx = copy(ctx.x[:], data)
        }
    }
}

final :: proc "contextless" (ctx: ^$T, hash: []byte) {
    when T == Blake256_Context {
        tmp: [65]byte
    } else when T == Blake512_Context {
        tmp: [129]byte
    }
    nx     := u64(ctx.nx)
    tmp[0]  = 0x80
    length := (ctx.t + nx) << 3

    when T == Blake256_Context {
        if nx == 55 {
            if ctx.is224 {
                write_additional(ctx, {0x80})
            } else {
                write_additional(ctx, {0x81})
            }
        } else {
            if nx < 55 {
                if nx == 0 {
                    ctx.nullt = true
                }
                write_additional(ctx, tmp[0 : 55 - nx])
            } else { 
                write_additional(ctx, tmp[0 : 64 - nx])
                write_additional(ctx, tmp[1:56])
                ctx.nullt = true
            }
            if ctx.is224 {
                write_additional(ctx, {0x00})
            } else {
                write_additional(ctx, {0x01})
            }
        }

        for i : uint = 0; i < 8; i += 1 {
            tmp[i] = byte(length >> (56 - 8 * i))
        }
        write_additional(ctx, tmp[0:8])

        h := ctx.h[:]
        if ctx.is224 {
            h = h[0:7]
        }
        for s, i in h {
            hash[i * 4]     = byte(s >> 24)
            hash[i * 4 + 1] = byte(s >> 16)
            hash[i * 4 + 2] = byte(s >> 8)
            hash[i * 4 + 3] = byte(s)
        }
    } else when T == Blake512_Context {
        if nx == 111 {
            if ctx.is384 {
                write_additional(ctx, {0x80})
            } else {
                write_additional(ctx, {0x81})
            }
        } else {
            if nx < 111 {
                if nx == 0 {
                    ctx.nullt = true
                }
                write_additional(ctx, tmp[0 : 111 - nx])
            } else { 
                write_additional(ctx, tmp[0 : 128 - nx])
                write_additional(ctx, tmp[1:112])
                ctx.nullt = true
            }
            if ctx.is384 {
                write_additional(ctx, {0x00})
            } else {
                write_additional(ctx, {0x01})
            }
        }

        for i : uint = 0; i < 16; i += 1 {
            tmp[i] = byte(length >> (120 - 8 * i))
        }
        write_additional(ctx, tmp[0:16])

        h := ctx.h[:]
        if ctx.is384 {
            h = h[0:6]
        }
        for s, i in h {
            hash[i * 8]     = byte(s >> 56)
            hash[i * 8 + 1] = byte(s >> 48)
            hash[i * 8 + 2] = byte(s >> 40)
            hash[i * 8 + 3] = byte(s >> 32)
            hash[i * 8 + 4] = byte(s >> 24)
            hash[i * 8 + 5] = byte(s >> 16)
            hash[i * 8 + 6] = byte(s >> 8)
            hash[i * 8 + 7] = byte(s)
        }
    }
}

SIZE_224 :: 28
SIZE_256 :: 32
SIZE_384 :: 48
SIZE_512 :: 64
BLOCKSIZE_256 :: 64
BLOCKSIZE_512 :: 128

Blake256_Context :: struct {
    h:     [8]u32,
    s:     [4]u32,
    t:     u64,
    x:     [64]byte,
    nx:    int,
    is224: bool,
    nullt: bool,
}

Blake512_Context :: struct {
    h:     [8]u64,
    s:     [4]u64,
    t:     u64,
    x:     [128]byte,
    nx:    int,
    is384: bool,
    nullt: bool,
}

SIGMA := [?]int {
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
    14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3,
    11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4,
    7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8,
    9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13,
    2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9,
    12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11,
    13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10,
    6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5,
    10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0,
}

U256 := [16]u32 {
    0x243f6a88, 0x85a308d3, 0x13198a2e, 0x03707344,
    0xa4093822, 0x299f31d0, 0x082efa98, 0xec4e6c89,
    0x452821e6, 0x38d01377, 0xbe5466cf, 0x34e90c6c,
    0xc0ac29b7, 0xc97c50dd, 0x3f84d5b5, 0xb5470917,
}

U512 := [16]u64 {
    0x243f6a8885a308d3, 0x13198a2e03707344, 0xa4093822299f31d0, 0x082efa98ec4e6c89,
    0x452821e638d01377, 0xbe5466cf34e90c6c, 0xc0ac29b7c97c50dd, 0x3f84d5b5b5470917,
    0x9216d5d98979fb1b, 0xd1310ba698dfb5ac, 0x2ffd72dbd01adfb7, 0xb8e1afed6a267e96,
    0xba7c9045f12c7f99, 0x24a19947b3916cf7, 0x0801f2e2858efc16, 0x636920d871574e69,
}

G256 :: #force_inline proc "contextless" (a, b, c, d: u32, m: [16]u32, i, j: int) -> (u32, u32, u32, u32) {
    a, b, c, d := a, b, c, d
    a += m[SIGMA[(i % 10) * 16 + (2 * j)]] ~ U256[SIGMA[(i % 10) * 16 + (2 * j + 1)]]
    a += b
    d ~= a
    d = d << (32 - 16) | d >> 16
    c += d
    b ~= c
    b = b << (32 - 12) | b >> 12
    a += m[SIGMA[(i % 10) * 16 + (2 * j + 1)]] ~ U256[SIGMA[(i % 10) * 16 + (2 * j)]]
    a += b
    d ~= a
    d = d << (32 - 8) | d >> 8
    c += d
    b ~= c
    b = b << (32 - 7) | b >> 7
    return a, b, c, d
}

G512 :: #force_inline proc "contextless" (a, b, c, d: u64, m: [16]u64, i, j: int) -> (u64, u64, u64, u64) {
    a, b, c, d := a, b, c, d
    a += m[SIGMA[(i % 10) * 16 + (2 * j)]] ~ U512[SIGMA[(i % 10) * 16 + (2 * j + 1)]]
    a += b
    d ~= a
    d = d << (64 - 32) | d >> 32
    c += d
    b ~= c
    b = b << (64 - 25) | b >> 25
    a += m[SIGMA[(i % 10) * 16 + (2 * j + 1)]] ~ U512[SIGMA[(i % 10) * 16 + (2 * j)]]
    a += b
    d ~= a
    d = d << (64 - 16) | d >> 16
    c += d
    b ~= c
    b = b << (64 - 11) | b >> 11
    return a, b, c, d
}

block256 :: proc "contextless" (ctx: ^Blake256_Context, p: []byte) #no_bounds_check {
    i, j: int     = ---, ---
    v, m: [16]u32 = ---, ---
    p := p
    for len(p) >= BLOCKSIZE_256 {
        v[0]  = ctx.h[0]
        v[1]  = ctx.h[1]
        v[2]  = ctx.h[2]
        v[3]  = ctx.h[3]
        v[4]  = ctx.h[4]
        v[5]  = ctx.h[5]
        v[6]  = ctx.h[6]
        v[7]  = ctx.h[7]
        v[8]  = ctx.s[0] ~ U256[0]
        v[9]  = ctx.s[1] ~ U256[1]
        v[10] = ctx.s[2] ~ U256[2]
        v[11] = ctx.s[3] ~ U256[3]
        v[12] = U256[4]
        v[13] = U256[5]
        v[14] = U256[6]
        v[15] = U256[7]

        ctx.t += 512
        if !ctx.nullt {
            v[12] ~= u32(ctx.t)
            v[13] ~= u32(ctx.t)
            v[14] ~= u32(ctx.t >> 32)
            v[15] ~= u32(ctx.t >> 32)
        }

        for i, j = 0, 0; i < 16; i, j = i+1, j+4 {
            m[i] = u32(p[j]) << 24 | u32(p[j + 1]) << 16 | u32(p[j + 2]) << 8 | u32(p[j + 3])
        }

        for i = 0; i < 14; i += 1 {
            v[0], v[4], v[8],  v[12] = G256(v[0], v[4], v[8],  v[12], m, i, 0)
            v[1], v[5], v[9],  v[13] = G256(v[1], v[5], v[9],  v[13], m, i, 1)
            v[2], v[6], v[10], v[14] = G256(v[2], v[6], v[10], v[14], m, i, 2)
            v[3], v[7], v[11], v[15] = G256(v[3], v[7], v[11], v[15], m, i, 3)
            v[0], v[5], v[10], v[15] = G256(v[0], v[5], v[10], v[15], m, i, 4)
            v[1], v[6], v[11], v[12] = G256(v[1], v[6], v[11], v[12], m, i, 5)
            v[2], v[7], v[8],  v[13] = G256(v[2], v[7], v[8],  v[13], m, i, 6)
            v[3], v[4], v[9],  v[14] = G256(v[3], v[4], v[9],  v[14], m, i, 7)
        }

        for i = 0; i < 8; i += 1 {
            ctx.h[i] ~= ctx.s[i % 4] ~ v[i] ~ v[i + 8]
        }
        p = p[BLOCKSIZE_256:]
    }
}

block512 :: proc "contextless" (ctx: ^Blake512_Context, p: []byte) #no_bounds_check {
    i, j: int     = ---, ---
    v, m: [16]u64 = ---, ---
    p := p
    for len(p) >= BLOCKSIZE_512 {
        v[0]  = ctx.h[0]
        v[1]  = ctx.h[1]
        v[2]  = ctx.h[2]
        v[3]  = ctx.h[3]
        v[4]  = ctx.h[4]
        v[5]  = ctx.h[5]
        v[6]  = ctx.h[6]
        v[7]  = ctx.h[7]
        v[8]  = ctx.s[0] ~ U512[0]
        v[9]  = ctx.s[1] ~ U512[1]
        v[10] = ctx.s[2] ~ U512[2]
        v[11] = ctx.s[3] ~ U512[3]
        v[12] = U512[4]
        v[13] = U512[5]
        v[14] = U512[6]
        v[15] = U512[7]

        ctx.t += 1024
        if !ctx.nullt {
            v[12] ~= ctx.t
            v[13] ~= ctx.t
            v[14] ~= 0
            v[15] ~= 0
        }

        for i, j = 0, 0; i < 16; i, j = i + 1, j + 8 {
            m[i] = u64(p[j]) << 56     | u64(p[j + 1]) << 48 | u64(p[j + 2]) << 40 | u64(p[j + 3]) << 32 | 
                   u64(p[j + 4]) << 24 | u64(p[j + 5]) << 16 | u64(p[j + 6]) << 8  | u64(p[j + 7])
        }
        for i = 0; i < 16; i += 1 {
            v[0], v[4], v[8],  v[12] = G512(v[0], v[4], v[8],  v[12], m, i, 0)
            v[1], v[5], v[9],  v[13] = G512(v[1], v[5], v[9],  v[13], m, i, 1)
            v[2], v[6], v[10], v[14] = G512(v[2], v[6], v[10], v[14], m, i, 2)
            v[3], v[7], v[11], v[15] = G512(v[3], v[7], v[11], v[15], m, i, 3)
            v[0], v[5], v[10], v[15] = G512(v[0], v[5], v[10], v[15], m, i, 4)
            v[1], v[6], v[11], v[12] = G512(v[1], v[6], v[11], v[12], m, i, 5)
            v[2], v[7], v[8],  v[13] = G512(v[2], v[7], v[8],  v[13], m, i, 6)
            v[3], v[4], v[9],  v[14] = G512(v[3], v[4], v[9],  v[14], m, i, 7)
        }

        for i = 0; i < 8; i += 1 {
            ctx.h[i] ~= ctx.s[i % 4] ~ v[i] ~ v[i + 8]
        }
        p = p[BLOCKSIZE_512:]
    }
}

write_additional :: proc "contextless" (ctx: ^$T, data: []byte) {
	ctx.t -= u64(len(data)) << 3
    update(ctx, data)
}
