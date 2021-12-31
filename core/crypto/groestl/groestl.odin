package groestl

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Implementation of the GROESTL hashing algorithm, as defined in <http://www.groestl.info/Groestl.zip>
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
    ctx: Groestl_Context
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
    hash_bytes_to_buffer_224(transmute([]byte)(data), hash);
}

// hash_bytes_to_buffer_224 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_224 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_224, "Size of destination buffer is smaller than the digest size")
    ctx: Groestl_Context
    ctx.hashbitlen = 224
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_224 will read the stream in chunks and compute a
// hash from its contents
hash_stream_224 :: proc(s: io.Stream) -> ([DIGEST_SIZE_224]byte, bool) {
    hash: [DIGEST_SIZE_224]byte
    ctx: Groestl_Context
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
    ctx: Groestl_Context
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
    hash_bytes_to_buffer_256(transmute([]byte)(data), hash);
}

// hash_bytes_to_buffer_256 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_256 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_256, "Size of destination buffer is smaller than the digest size")
    ctx: Groestl_Context
    ctx.hashbitlen = 256
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_256 will read the stream in chunks and compute a
// hash from its contents
hash_stream_256 :: proc(s: io.Stream) -> ([DIGEST_SIZE_256]byte, bool) {
    hash: [DIGEST_SIZE_256]byte
    ctx: Groestl_Context
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
    ctx: Groestl_Context
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
    hash_bytes_to_buffer_384(transmute([]byte)(data), hash);
}

// hash_bytes_to_buffer_384 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_384 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_384, "Size of destination buffer is smaller than the digest size")
    ctx: Groestl_Context
    ctx.hashbitlen = 384
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_384 will read the stream in chunks and compute a
// hash from its contents
hash_stream_384 :: proc(s: io.Stream) -> ([DIGEST_SIZE_384]byte, bool) {
    hash: [DIGEST_SIZE_384]byte
    ctx: Groestl_Context
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
    ctx: Groestl_Context
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
    hash_bytes_to_buffer_512(transmute([]byte)(data), hash);
}

// hash_bytes_to_buffer_512 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_512 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_512, "Size of destination buffer is smaller than the digest size")
    ctx: Groestl_Context
    ctx.hashbitlen = 512
    init(&ctx)
    update(&ctx, data)
    final(&ctx, hash)
}

// hash_stream_512 will read the stream in chunks and compute a
// hash from its contents
hash_stream_512 :: proc(s: io.Stream) -> ([DIGEST_SIZE_512]byte, bool) {
    hash: [DIGEST_SIZE_512]byte
    ctx: Groestl_Context
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

init :: proc(ctx: ^Groestl_Context) {
    assert(ctx.hashbitlen == 224 || ctx.hashbitlen == 256 || ctx.hashbitlen == 384 || ctx.hashbitlen == 512, "hashbitlen must be set to 224, 256, 384 or 512")
    if ctx.hashbitlen <= 256 {
        ctx.rounds    = 10
        ctx.columns   = 8
        ctx.statesize = 64
    } else {
        ctx.rounds    = 14
        ctx.columns   = 16
        ctx.statesize = 128
    }
    for i := 8 - size_of(i32); i < 8; i += 1 {
        ctx.chaining[i][ctx.columns - 1] = byte(ctx.hashbitlen >> (8 * (7 - uint(i))))
    }
}

update :: proc(ctx: ^Groestl_Context, data: []byte) {
    databitlen := len(data) * 8
    msglen     := databitlen / 8
    rem        := databitlen % 8

    i: int
    assert(ctx.bits_in_last_byte == 0)

    if ctx.buf_ptr != 0 {
        for i = 0; ctx.buf_ptr < ctx.statesize && i < msglen; i, ctx.buf_ptr =  i + 1, ctx.buf_ptr + 1 {
            ctx.buffer[ctx.buf_ptr] = data[i]
        }

        if ctx.buf_ptr < ctx.statesize {
            if rem != 0 {
                ctx.bits_in_last_byte    = rem
                ctx.buffer[ctx.buf_ptr]  = data[i]
                ctx.buf_ptr             += 1
            }
            return
        }

        ctx.buf_ptr = 0
        transform(ctx, ctx.buffer[:], u32(ctx.statesize))
    }

    transform(ctx, data[i:], u32(msglen - i))
    i += ((msglen - i) / ctx.statesize) * ctx.statesize
    for i < msglen {
        ctx.buffer[ctx.buf_ptr] = data[i]
        i, ctx.buf_ptr          = i + 1, ctx.buf_ptr + 1
    }
    
    if rem != 0 {
        ctx.bits_in_last_byte    = rem
        ctx.buffer[ctx.buf_ptr]  = data[i]
        ctx.buf_ptr             += 1
    }
}

final :: proc(ctx: ^Groestl_Context, hash: []byte) {
    hashbytelen := ctx.hashbitlen / 8

    if ctx.bits_in_last_byte != 0 {
        ctx.buffer[ctx.buf_ptr - 1] &= ((1 << uint(ctx.bits_in_last_byte)) - 1) << (8 - uint(ctx.bits_in_last_byte))
        ctx.buffer[ctx.buf_ptr - 1] ~= 0x1 << (7 - uint(ctx.bits_in_last_byte))
    } else {
        ctx.buffer[ctx.buf_ptr]  = 0x80
        ctx.buf_ptr             += 1
    }

    if ctx.buf_ptr > ctx.statesize - 8 {
        for ctx.buf_ptr < ctx.statesize {
            ctx.buffer[ctx.buf_ptr]  = 0
            ctx.buf_ptr             += 1
        }
        transform(ctx, ctx.buffer[:], u32(ctx.statesize))
        ctx.buf_ptr = 0
    }

    for ctx.buf_ptr < ctx.statesize - 8 {
        ctx.buffer[ctx.buf_ptr]  = 0
        ctx.buf_ptr             += 1
    }

    ctx.block_counter += 1
    ctx.buf_ptr        = ctx.statesize

    for ctx.buf_ptr > ctx.statesize - 8 {
        ctx.buf_ptr              -= 1
        ctx.buffer[ctx.buf_ptr]   = byte(ctx.block_counter)
        ctx.block_counter       >>= 8
    }

    transform(ctx, ctx.buffer[:], u32(ctx.statesize))
    output_transformation(ctx)

    for i, j := ctx.statesize - hashbytelen , 0; i < ctx.statesize; i, j = i + 1, j + 1 {
        hash[j] = ctx.chaining[i % 8][i / 8]
    }
}

/*
    GROESTL implementation
*/

SBOX := [256]byte {
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5,
    0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
    0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0,
    0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc,
    0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a,
    0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
    0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0,
    0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
    0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b,
    0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85,
    0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5,
    0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
    0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17,
    0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88,
    0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
    0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c,
    0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9,
    0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6,
    0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
    0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e,
    0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94,
    0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68,
    0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16,
}

SHIFT := [2][2][8]int {
    {{0, 1, 2, 3, 4, 5, 6, 7},  {1, 3, 5, 7,  0, 2, 4, 6}},
    {{0, 1, 2, 3, 4, 5, 6, 11}, {1, 3, 5, 11, 0, 2, 4, 6}},
}

Groestl_Context :: struct {
    chaining:          [8][16]byte,
    block_counter:     u64,
    hashbitlen:        int,
    buffer:            [128]byte,
    buf_ptr:           int,
    bits_in_last_byte: int,
    columns:           int,
    rounds:            int,
    statesize:         int,
}

Groestl_Variant :: enum {
    P512  = 0, 
    Q512  = 1, 
    P1024 = 2, 
    Q1024 = 3,
}

MUL2 :: #force_inline proc "contextless"(b: byte) -> byte {
    return (b >> 7) != 0 ? (b << 1) ~ 0x1b : (b << 1)
}

MUL3 :: #force_inline proc "contextless"(b: byte) -> byte {
    return MUL2(b) ~ b
}

MUL4 :: #force_inline proc "contextless"(b: byte) -> byte {
    return MUL2(MUL2(b))
}

MUL5 :: #force_inline proc "contextless"(b: byte) -> byte {
    return MUL4(b) ~ b
}

MUL6 :: #force_inline proc "contextless"(b: byte) -> byte {
    return MUL4(b) ~ MUL2(b)
}

MUL7 :: #force_inline proc "contextless"(b: byte) -> byte {
    return MUL4(b) ~ MUL2(b) ~ b
}

sub_bytes :: #force_inline proc (x: [][16]byte, columns: int) {
    for i := 0; i < 8; i += 1 {
        for j := 0; j < columns; j += 1 {
            x[i][j] = SBOX[x[i][j]]
        }
    }
}

shift_bytes :: #force_inline proc (x: [][16]byte, columns: int, v: Groestl_Variant) {
    temp: [16]byte
    R := &SHIFT[int(v) / 2][int(v) & 1]

    for i := 0; i < 8; i += 1 {
        for j := 0; j < columns; j += 1 {
            temp[j] = x[i][(j + R[i]) % columns]
        }
        for j := 0; j < columns; j += 1 {
            x[i][j] = temp[j]
        }
    }
}

mix_bytes :: #force_inline proc (x: [][16]byte, columns: int) {
    temp: [8]byte

    for i := 0; i < columns; i += 1 {
        for j := 0; j < 8; j += 1 {
            temp[j] =  MUL2(x[(j + 0) % 8][i]) ~
                       MUL2(x[(j + 1) % 8][i]) ~
                       MUL3(x[(j + 2) % 8][i]) ~
                       MUL4(x[(j + 3) % 8][i]) ~
                       MUL5(x[(j + 4) % 8][i]) ~
                       MUL3(x[(j + 5) % 8][i]) ~
                       MUL5(x[(j + 6) % 8][i]) ~
                       MUL7(x[(j + 7) % 8][i])
        }
        for j := 0; j < 8; j += 1 {
            x[j][i] = temp[j]
        }
    }
}

p :: #force_inline proc (ctx: ^Groestl_Context, x: [][16]byte) {
    v := ctx.columns == 8 ? Groestl_Variant.P512 : Groestl_Variant.P1024
    for i := 0; i < ctx.rounds; i += 1 {
        add_roundconstant(x, ctx.columns, byte(i), v)
        sub_bytes(x, ctx.columns)
        shift_bytes(x, ctx.columns, v)
        mix_bytes(x, ctx.columns)
    }
}

q :: #force_inline proc (ctx: ^Groestl_Context, x: [][16]byte) {
    v := ctx.columns == 8 ? Groestl_Variant.Q512 : Groestl_Variant.Q1024
    for i := 0; i < ctx.rounds; i += 1 {
        add_roundconstant(x, ctx.columns, byte(i), v)
        sub_bytes(x, ctx.columns)
        shift_bytes(x, ctx.columns, v)
        mix_bytes(x, ctx.columns)
    }
}

transform :: proc(ctx: ^Groestl_Context, input: []byte, msglen: u32) {
    tmp1, tmp2: [8][16]byte
    input, msglen := input, msglen

    for msglen >= u32(ctx.statesize) {
        for i := 0; i < 8; i += 1 {
            for j := 0; j < ctx.columns; j += 1 {
                tmp1[i][j] = ctx.chaining[i][j] ~ input[j * 8 + i]
                tmp2[i][j] = input[j * 8 + i]
            }
        }

        p(ctx, tmp1[:])
        q(ctx, tmp2[:])

        for i := 0; i < 8; i += 1 {
            for j := 0; j < ctx.columns; j += 1 {
                ctx.chaining[i][j] ~= tmp1[i][j] ~ tmp2[i][j]
            }
        }

        ctx.block_counter += 1
        msglen            -= u32(ctx.statesize)
        input              = input[ctx.statesize:]
    }
}

output_transformation :: proc(ctx: ^Groestl_Context) {
    temp: [8][16]byte

    for i := 0; i < 8; i += 1 {
        for j := 0; j < ctx.columns; j += 1 {
            temp[i][j] = ctx.chaining[i][j]
        }
    }

    p(ctx, temp[:])

    for i := 0; i < 8; i += 1 {
        for j := 0; j < ctx.columns; j += 1 {
            ctx.chaining[i][j] ~= temp[i][j]
        }
    }
}

add_roundconstant :: proc(x: [][16]byte, columns: int, round: byte, v: Groestl_Variant) {
    switch (i32(v) & 1) {
        case 0: 
            for i := 0; i < columns; i += 1 {
                x[0][i] ~= byte(i << 4) ~ round
            }
        case 1:
            for i := 0; i < columns; i += 1 {
                for j := 0; j < 7; j += 1 {
                    x[j][i] ~= 0xff
                }
            }
            for i := 0; i < columns; i += 1 {
                x[7][i] ~= byte(i << 4) ~ 0xff ~ round
            }
    }
}
