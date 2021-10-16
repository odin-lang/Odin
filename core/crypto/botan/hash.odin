package botan

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog: Initial creation and testing of the bindings.

    Implementation of the context for the Botan side.
*/

import "core:os"
import "core:io"
import "core:fmt"
import "core:strings"

import "../_ctx"

hash_bytes_16 :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) -> [16]byte {
    hash: [16]byte
    c: hash_t
    hash_init(&c, _check_ctx(ctx, _ctx.Hash_Size._16, 16), 0)
    hash_update(c, len(data) == 0 ? nil : &data[0], uint(len(data)))
    hash_final(c, &hash[0])
    hash_destroy(c)
    return hash
}

hash_bytes_20 :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) -> [20]byte {
    hash: [20]byte
    c: hash_t
    hash_init(&c, _check_ctx(ctx, _ctx.Hash_Size._20, 20), 0)
    hash_update(c, len(data) == 0 ? nil : &data[0], uint(len(data)))
    hash_final(c, &hash[0])
    hash_destroy(c)
    return hash
}

hash_bytes_24 :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) -> [24]byte {
    hash: [24]byte
    c: hash_t
    hash_init(&c, _check_ctx(ctx, _ctx.Hash_Size._24, 24), 0)
    hash_update(c, len(data) == 0 ? nil : &data[0], uint(len(data)))
    hash_final(c, &hash[0])
    hash_destroy(c)
    return hash
}

hash_bytes_28 :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) -> [28]byte {
    hash: [28]byte
    c: hash_t
    hash_init(&c, _check_ctx(ctx, _ctx.Hash_Size._28, 28), 0)
    hash_update(c, len(data) == 0 ? nil : &data[0], uint(len(data)))
    hash_final(c, &hash[0])
    hash_destroy(c)
    return hash
}

hash_bytes_32 :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) -> [32]byte {
    hash: [32]byte
    c: hash_t
    hash_init(&c, _check_ctx(ctx, _ctx.Hash_Size._32, 32), 0)
    hash_update(c, len(data) == 0 ? nil : &data[0], uint(len(data)))
    hash_final(c, &hash[0])
    hash_destroy(c)
    return hash
}

hash_bytes_48 :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) -> [48]byte {
    hash: [48]byte
    c: hash_t
    hash_init(&c, _check_ctx(ctx, _ctx.Hash_Size._48, 48), 0)
    hash_update(c, len(data) == 0 ? nil : &data[0], uint(len(data)))
    hash_final(c, &hash[0])
    hash_destroy(c)
    return hash
}

hash_bytes_64 :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) -> [64]byte {
    hash: [64]byte
    c: hash_t
    hash_init(&c, _check_ctx(ctx, _ctx.Hash_Size._64, 64), 0)
    hash_update(c, len(data) == 0 ? nil : &data[0], uint(len(data)))
    hash_final(c, &hash[0])
    hash_destroy(c)
    return hash
}

hash_bytes_128 :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) -> [128]byte {
    hash: [128]byte
    c: hash_t
    hash_init(&c, _check_ctx(ctx, _ctx.Hash_Size._128, 128), 0)
    hash_update(c, len(data) == 0 ? nil : &data[0], uint(len(data)))
    hash_final(c, &hash[0])
    hash_destroy(c)
    return hash
}

hash_bytes_slice :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte, bit_size: int, allocator := context.allocator) -> []byte {
    hash := make([]byte, bit_size, allocator)
    c: hash_t
    hash_init(&c, _check_ctx(ctx, nil, bit_size), 0)
    hash_update(c, len(data) == 0 ? nil : &data[0], uint(len(data)))
    hash_final(c, &hash[0])
    hash_destroy(c)
    return hash[:]
}

hash_file_16 :: #force_inline proc(ctx: ^_ctx.Hash_Context, hd: os.Handle, load_at_once := false) -> ([16]byte, bool) {
    if !load_at_once {
        return hash_stream_16(ctx, os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_16(ctx, buf[:]), ok
        }
    }
    return [16]byte{}, false
}

hash_file_20 :: #force_inline proc(ctx: ^_ctx.Hash_Context, hd: os.Handle, load_at_once := false) -> ([20]byte, bool) {
    if !load_at_once {
        return hash_stream_20(ctx, os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_20(ctx, buf[:]), ok
        }
    }
    return [20]byte{}, false
}

hash_file_24 :: #force_inline proc(ctx: ^_ctx.Hash_Context, hd: os.Handle, load_at_once := false) -> ([24]byte, bool) {
    if !load_at_once {
        return hash_stream_24(ctx, os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_24(ctx, buf[:]), ok
        }
    }
    return [24]byte{}, false
}

hash_file_28 :: #force_inline proc(ctx: ^_ctx.Hash_Context, hd: os.Handle, load_at_once := false) -> ([28]byte, bool) {
    if !load_at_once {
        return hash_stream_28(ctx, os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_28(ctx, buf[:]), ok
        }
    }
    return [28]byte{}, false
}

hash_file_32 :: #force_inline proc(ctx: ^_ctx.Hash_Context, hd: os.Handle, load_at_once := false) -> ([32]byte, bool) {
    if !load_at_once {
        return hash_stream_32(ctx, os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_32(ctx, buf[:]), ok
        }
    }
    return [32]byte{}, false
}

hash_file_48 :: #force_inline proc(ctx: ^_ctx.Hash_Context, hd: os.Handle, load_at_once := false) -> ([48]byte, bool) {
    if !load_at_once {
        return hash_stream_48(ctx, os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_48(ctx, buf[:]), ok
        }
    }
    return [48]byte{}, false
}

hash_file_64 :: #force_inline proc(ctx: ^_ctx.Hash_Context, hd: os.Handle, load_at_once := false) -> ([64]byte, bool) {
    if !load_at_once {
        return hash_stream_64(ctx, os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_64(ctx, buf[:]), ok
        }
    }
    return [64]byte{}, false
}

hash_file_128 :: #force_inline proc(ctx: ^_ctx.Hash_Context, hd: os.Handle, load_at_once := false) -> ([128]byte, bool) {
    if !load_at_once {
        return hash_stream_128(ctx, os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_128(ctx, buf[:]), ok
        }
    }
    return [128]byte{}, false
}

hash_file_slice :: #force_inline proc(ctx: ^_ctx.Hash_Context, hd: os.Handle, bit_size: int, load_at_once := false, allocator := context.allocator) -> ([]byte, bool) {
    if !load_at_once {
        return hash_stream_slice(ctx, os.stream_from_handle(hd), bit_size, allocator)
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_slice(ctx, buf[:], bit_size, allocator), ok
        }
    }
    return nil, false
}

hash_stream_16 :: #force_inline proc(ctx: ^_ctx.Hash_Context, s: io.Stream) -> ([16]byte, bool) {
    hash: [16]byte
    c: hash_t
    hash_init(&c, _check_ctx(ctx, _ctx.Hash_Size._16, 16), 0)
    buf := make([]byte, 512)
    defer delete(buf)
    i := 1
    for i > 0 {
        i, _ = s->impl_read(buf)
        if i > 0 {
            hash_update(c, len(buf) == 0 ? nil : &buf[0], uint(i))
        } 
    }
    hash_final(c, &hash[0])
    hash_destroy(c)
    return hash, true
}

hash_stream_20 :: #force_inline proc(ctx: ^_ctx.Hash_Context, s: io.Stream) -> ([20]byte, bool) {
    hash: [20]byte
    c: hash_t
    hash_init(&c, _check_ctx(ctx, _ctx.Hash_Size._20, 20), 0)
    buf := make([]byte, 512)
    defer delete(buf)
    i := 1
    for i > 0 {
        i, _ = s->impl_read(buf)
        if i > 0 {
            hash_update(c, len(buf) == 0 ? nil : &buf[0], uint(i))
        } 
    }
    hash_final(c, &hash[0])
    hash_destroy(c)
    return hash, true
}

hash_stream_24 :: #force_inline proc(ctx: ^_ctx.Hash_Context, s: io.Stream) -> ([24]byte, bool) {
    hash: [24]byte
    c: hash_t
    hash_init(&c, _check_ctx(ctx, _ctx.Hash_Size._24, 24), 0)
    buf := make([]byte, 512)
    defer delete(buf)
    i := 1
    for i > 0 {
        i, _ = s->impl_read(buf)
        if i > 0 {
            hash_update(c, len(buf) == 0 ? nil : &buf[0], uint(i))
        } 
    }
    hash_final(c, &hash[0])
    hash_destroy(c)
    return hash, true
}

hash_stream_28 :: #force_inline proc(ctx: ^_ctx.Hash_Context, s: io.Stream) -> ([28]byte, bool) {
    hash: [28]byte
    c: hash_t
    hash_init(&c, _check_ctx(ctx, _ctx.Hash_Size._28, 28), 0)
    buf := make([]byte, 512)
    defer delete(buf)
    i := 1
    for i > 0 {
        i, _ = s->impl_read(buf)
        if i > 0 {
            hash_update(c, len(buf) == 0 ? nil : &buf[0], uint(i))
        } 
    }
    hash_final(c, &hash[0])
    hash_destroy(c)
    return hash, true
}

hash_stream_32 :: #force_inline proc(ctx: ^_ctx.Hash_Context, s: io.Stream) -> ([32]byte, bool) {
    hash: [32]byte
    c: hash_t
    hash_init(&c, _check_ctx(ctx, _ctx.Hash_Size._32, 32), 0)
    buf := make([]byte, 512)
    defer delete(buf)
    i := 1
    for i > 0 {
        i, _ = s->impl_read(buf)
        if i > 0 {
            hash_update(c, len(buf) == 0 ? nil : &buf[0], uint(i))
        } 
    }
    hash_final(c, &hash[0])
    hash_destroy(c)
    return hash, true
}

hash_stream_48 :: #force_inline proc(ctx: ^_ctx.Hash_Context, s: io.Stream) -> ([48]byte, bool) {
    hash: [48]byte
    c: hash_t
    hash_init(&c, _check_ctx(ctx, _ctx.Hash_Size._48, 48), 0)
    buf := make([]byte, 512)
    defer delete(buf)
    i := 1
    for i > 0 {
        i, _ = s->impl_read(buf)
        if i > 0 {
            hash_update(c, len(buf) == 0 ? nil : &buf[0], uint(i))
        } 
    }
    hash_final(c, &hash[0])
    hash_destroy(c)
    return hash, true
}

hash_stream_64 :: #force_inline proc(ctx: ^_ctx.Hash_Context, s: io.Stream) -> ([64]byte, bool) {
    hash: [64]byte
    c: hash_t
    hash_init(&c, _check_ctx(ctx, _ctx.Hash_Size._64, 64), 0)
    buf := make([]byte, 512)
    defer delete(buf)
    i := 1
    for i > 0 {
        i, _ = s->impl_read(buf)
        if i > 0 {
            hash_update(c, len(buf) == 0 ? nil : &buf[0], uint(i))
        } 
    }
    hash_final(c, &hash[0])
    hash_destroy(c)
    return hash, true
}

hash_stream_128 :: #force_inline proc(ctx: ^_ctx.Hash_Context, s: io.Stream) -> ([128]byte, bool) {
    hash: [128]byte
    c: hash_t
    hash_init(&c, _check_ctx(ctx, _ctx.Hash_Size._128, 128), 0)
    buf := make([]byte, 512)
    defer delete(buf)
    i := 1
    for i > 0 {
        i, _ = s->impl_read(buf)
        if i > 0 {
            hash_update(c, len(buf) == 0 ? nil : &buf[0], uint(i))
        } 
    }
    hash_final(c, &hash[0])
    hash_destroy(c)
    return hash, true
}

hash_stream_slice :: #force_inline proc(ctx: ^_ctx.Hash_Context, s: io.Stream, bit_size: int, allocator := context.allocator) -> ([]byte, bool) {
    hash := make([]byte, bit_size, allocator)
    c: hash_t
    hash_init(&c, _check_ctx(ctx, nil, bit_size), 0)
    buf := make([]byte, 512)
    defer delete(buf)
    i := 1
    for i > 0 {
        i, _ = s->impl_read(buf)
        if i > 0 {
            hash_update(c, len(buf) == 0 ? nil : &buf[0], uint(i))
        } 
    }
    hash_final(c, &hash[0])
    hash_destroy(c)
    return hash[:], true
}

init :: #force_inline proc(ctx: ^_ctx.Hash_Context) {
    c: hash_t
    hash_init(&c, ctx.botan_hash_algo, 0)
    ctx.external_ctx = c
}

update :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) {
    if c, ok := ctx.external_ctx.(hash_t); ok {
        hash_update(c, len(data) == 0 ? nil : &data[0], uint(len(data)))
    }
}

final :: #force_inline proc(ctx: ^_ctx.Hash_Context, hash: []byte) {
    if c, ok := ctx.external_ctx.(hash_t); ok {
        hash_final(c, &hash[0])
        hash_destroy(c)
    }
}

assign_hash_vtable :: proc(ctx: ^_ctx.Hash_Context, hash_algo: cstring) {
    ctx.init            = init
    ctx.update          = update
    ctx.final           = final
    ctx.botan_hash_algo = hash_algo

    switch hash_algo {
        case HASH_MD4, HASH_MD5:
            ctx.hash_bytes_16  = hash_bytes_16
            ctx.hash_file_16   = hash_file_16
            ctx.hash_stream_16 = hash_stream_16

        case HASH_SHA1, HASH_RIPEMD_160:
            ctx.hash_bytes_20  = hash_bytes_20
            ctx.hash_file_20   = hash_file_20
            ctx.hash_stream_20 = hash_stream_20

        case HASH_SHA2, HASH_SHA3:
            ctx.hash_bytes_28  = hash_bytes_28
            ctx.hash_file_28   = hash_file_28
            ctx.hash_stream_28 = hash_stream_28
            ctx.hash_bytes_32  = hash_bytes_32
            ctx.hash_file_32   = hash_file_32
            ctx.hash_stream_32 = hash_stream_32
            ctx.hash_bytes_48  = hash_bytes_48
            ctx.hash_file_48   = hash_file_48
            ctx.hash_stream_48 = hash_stream_48
            ctx.hash_bytes_64  = hash_bytes_64
            ctx.hash_file_64   = hash_file_64
            ctx.hash_stream_64 = hash_stream_64

        case HASH_GOST, HASH_WHIRLPOOL, HASH_SM3:
            ctx.hash_bytes_32  = hash_bytes_32
            ctx.hash_file_32   = hash_file_32
            ctx.hash_stream_32 = hash_stream_32

        case HASH_STREEBOG:
            ctx.hash_bytes_32  = hash_bytes_32
            ctx.hash_file_32   = hash_file_32
            ctx.hash_stream_32 = hash_stream_32
            ctx.hash_bytes_64  = hash_bytes_64
            ctx.hash_file_64   = hash_file_64
            ctx.hash_stream_64 = hash_stream_64

        case HASH_BLAKE2B:
            ctx.hash_bytes_64  = hash_bytes_64
            ctx.hash_file_64   = hash_file_64
            ctx.hash_stream_64 = hash_stream_64

        case HASH_TIGER:
            ctx.hash_bytes_16  = hash_bytes_16
            ctx.hash_file_16   = hash_file_16
            ctx.hash_stream_16 = hash_stream_16
            ctx.hash_bytes_20  = hash_bytes_20
            ctx.hash_file_20   = hash_file_20
            ctx.hash_stream_20 = hash_stream_20
            ctx.hash_bytes_24  = hash_bytes_24
            ctx.hash_file_24   = hash_file_24
            ctx.hash_stream_24 = hash_stream_24

        case HASH_SKEIN_512:
            ctx.hash_bytes_slice  = hash_bytes_slice
            ctx.hash_file_slice   = hash_file_slice
            ctx.hash_stream_slice = hash_stream_slice
    }
}

_check_ctx :: #force_inline proc(ctx: ^_ctx.Hash_Context, hash_size: _ctx.Hash_Size, hash_size_val: int) -> cstring {
    ctx.hash_size     = hash_size
    ctx.hash_size_val = hash_size_val
    switch ctx.botan_hash_algo {
        case HASH_SHA2:
            #partial switch hash_size {
                case ._28: return HASH_SHA_224
                case ._32: return HASH_SHA_256
                case ._48: return HASH_SHA_384
                case ._64: return HASH_SHA_512
            }
        case HASH_SHA3:
            #partial switch hash_size {
                case ._28: return HASH_SHA3_224
                case ._32: return HASH_SHA3_256
                case ._48: return HASH_SHA3_384
                case ._64: return HASH_SHA3_512
            }
        case HASH_KECCAK:
            #partial switch hash_size {
                case ._28: return HASH_KECCAK_224
                case ._32: return HASH_KECCAK_256
                case ._48: return HASH_KECCAK_384
                case ._64: return HASH_KECCAK_512
            }
        case HASH_STREEBOG:
            #partial switch hash_size {
                case ._32: return HASH_STREEBOG_256
                case ._64: return HASH_STREEBOG_512
            }
        case HASH_TIGER:
            #partial switch hash_size {
                case ._16: return HASH_TIGER_128
                case ._20: return HASH_TIGER_160
                case ._24: return HASH_TIGER_192
            }
        case HASH_SKEIN_512:
            return strings.unsafe_string_to_cstring(fmt.tprintf("Skein-512(%d)", hash_size_val * 8))
        case: return ctx.botan_hash_algo
    }
    return nil
}