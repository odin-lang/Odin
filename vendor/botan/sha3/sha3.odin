package sha3

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Interface for the SHA-3 hashing algorithm. Variants for Keccak and SHAKE can be found in the appropriate packages.
    The hash will be computed via bindings to the Botan crypto library
*/

import "core:os"
import "core:io"

import botan "../bindings"

/*
    High level API
*/

// hash_string_224 will hash the given input and return the
// computed hash
hash_string_224 :: proc(data: string) -> [28]byte {
    return hash_bytes_224(transmute([]byte)(data))
}

// hash_bytes_224 will hash the given input and return the
// computed hash
hash_bytes_224 :: proc(data: []byte) -> [28]byte {
    hash: [28]byte
    ctx: botan.hash_t
    botan.hash_init(&ctx, botan.HASH_SHA3_224, 0)
    botan.hash_update(ctx, len(data) == 0 ? nil : &data[0], uint(len(data)))
    botan.hash_final(ctx, &hash[0])
    botan.hash_destroy(ctx)
    return hash
}

// hash_stream_224 will read the stream in chunks and compute a
// hash from its contents
hash_stream_224 :: proc(s: io.Stream) -> ([28]byte, bool) {
    hash: [28]byte
    ctx: botan.hash_t
    botan.hash_init(&ctx, botan.HASH_SHA3_224, 0)
    buf := make([]byte, 512)
    defer delete(buf)
    i := 1
    for i > 0 {
        i, _ = s->impl_read(buf)
        if i > 0 {
            botan.hash_update(ctx, len(buf) == 0 ? nil : &buf[0], uint(i))
        } 
    }
    botan.hash_final(ctx, &hash[0])
    botan.hash_destroy(ctx)
    return hash, true 
}

// hash_file_224 will read the file provided by the given handle
// and compute a hash
hash_file_224 :: proc(hd: os.Handle, load_at_once := false) -> ([28]byte, bool) {
    if !load_at_once {
        return hash_stream_224(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_224(buf[:]), ok
        }
    }
    return [28]byte{}, false
}

hash_224 :: proc {
    hash_stream_224,
    hash_file_224,
    hash_bytes_224,
    hash_string_224,
}

// hash_string_256 will hash the given input and return the
// computed hash
hash_string_256 :: proc(data: string) -> [32]byte {
    return hash_bytes_256(transmute([]byte)(data))
}

// hash_bytes_256 will hash the given input and return the
// computed hash
hash_bytes_256 :: proc(data: []byte) -> [32]byte {
    hash: [32]byte
    ctx: botan.hash_t
    botan.hash_init(&ctx, botan.HASH_SHA3_256, 0)
    botan.hash_update(ctx, len(data) == 0 ? nil : &data[0], uint(len(data)))
    botan.hash_final(ctx, &hash[0])
    botan.hash_destroy(ctx)
    return hash
}

// hash_stream_256 will read the stream in chunks and compute a
// hash from its contents
hash_stream_256 :: proc(s: io.Stream) -> ([32]byte, bool) {
    hash: [32]byte
    ctx: botan.hash_t
    botan.hash_init(&ctx, botan.HASH_SHA3_256, 0)
    buf := make([]byte, 512)
    defer delete(buf)
    i := 1
    for i > 0 {
        i, _ = s->impl_read(buf)
        if i > 0 {
            botan.hash_update(ctx, len(buf) == 0 ? nil : &buf[0], uint(i))
        } 
    }
    botan.hash_final(ctx, &hash[0])
    botan.hash_destroy(ctx)
    return hash, true 
}

// hash_file_256 will read the file provided by the given handle
// and compute a hash
hash_file_256 :: proc(hd: os.Handle, load_at_once := false) -> ([32]byte, bool) {
    if !load_at_once {
        return hash_stream_256(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_256(buf[:]), ok
        }
    }
    return [32]byte{}, false
}

hash_256 :: proc {
    hash_stream_256,
    hash_file_256,
    hash_bytes_256,
    hash_string_256,
}

// hash_string_384 will hash the given input and return the
// computed hash
hash_string_384 :: proc(data: string) -> [48]byte {
    return hash_bytes_384(transmute([]byte)(data))
}

// hash_bytes_384 will hash the given input and return the
// computed hash
hash_bytes_384 :: proc(data: []byte) -> [48]byte {
    hash: [48]byte
    ctx: botan.hash_t
    botan.hash_init(&ctx, botan.HASH_SHA3_384, 0)
    botan.hash_update(ctx, len(data) == 0 ? nil : &data[0], uint(len(data)))
    botan.hash_final(ctx, &hash[0])
    botan.hash_destroy(ctx)
    return hash
}

// hash_stream_384 will read the stream in chunks and compute a
// hash from its contents
hash_stream_384 :: proc(s: io.Stream) -> ([48]byte, bool) {
    hash: [48]byte
    ctx: botan.hash_t
    botan.hash_init(&ctx, botan.HASH_SHA3_384, 0)
    buf := make([]byte, 512)
    defer delete(buf)
    i := 1
    for i > 0 {
        i, _ = s->impl_read(buf)
        if i > 0 {
            botan.hash_update(ctx, len(buf) == 0 ? nil : &buf[0], uint(i))
        } 
    }
    botan.hash_final(ctx, &hash[0])
    botan.hash_destroy(ctx)
    return hash, true 
}

// hash_file_384 will read the file provided by the given handle
// and compute a hash
hash_file_384 :: proc(hd: os.Handle, load_at_once := false) -> ([48]byte, bool) {
    if !load_at_once {
        return hash_stream_384(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_384(buf[:]), ok
        }
    }
    return [48]byte{}, false
}

hash_384 :: proc {
    hash_stream_384,
    hash_file_384,
    hash_bytes_384,
    hash_string_384,
}

// hash_string_512 will hash the given input and return the
// computed hash
hash_string_512 :: proc(data: string) -> [64]byte {
    return hash_bytes_512(transmute([]byte)(data))
}

// hash_bytes_512 will hash the given input and return the
// computed hash
hash_bytes_512 :: proc(data: []byte) -> [64]byte {
    hash: [64]byte
    ctx: botan.hash_t
    botan.hash_init(&ctx, botan.HASH_SHA3_512, 0)
    botan.hash_update(ctx, len(data) == 0 ? nil : &data[0], uint(len(data)))
    botan.hash_final(ctx, &hash[0])
    botan.hash_destroy(ctx)
    return hash
}

// hash_stream_512 will read the stream in chunks and compute a
// hash from its contents
hash_stream_512 :: proc(s: io.Stream) -> ([64]byte, bool) {
    hash: [64]byte
    ctx: botan.hash_t
    botan.hash_init(&ctx, botan.HASH_SHA3_512, 0)
    buf := make([]byte, 512)
    defer delete(buf)
    i := 1
    for i > 0 {
        i, _ = s->impl_read(buf)
        if i > 0 {
            botan.hash_update(ctx, len(buf) == 0 ? nil : &buf[0], uint(i))
        } 
    }
    botan.hash_final(ctx, &hash[0])
    botan.hash_destroy(ctx)
    return hash, true 
}

// hash_file_512 will read the file provided by the given handle
// and compute a hash
hash_file_512 :: proc(hd: os.Handle, load_at_once := false) -> ([64]byte, bool) {
    if !load_at_once {
        return hash_stream_512(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_512(buf[:]), ok
        }
    }
    return [64]byte{}, false
}

hash_512 :: proc {
    hash_stream_512,
    hash_file_512,
    hash_bytes_512,
    hash_string_512,
}

/*
    Low level API
*/

Sha3_Context :: botan.hash_t

init :: proc "contextless" (ctx: ^botan.hash_t, hash_size := 512) {
    switch hash_size {
        case 224: botan.hash_init(ctx, botan.HASH_SHA3_224, 0)
        case 256: botan.hash_init(ctx, botan.HASH_SHA3_256, 0)
        case 384: botan.hash_init(ctx, botan.HASH_SHA3_384, 0)
        case 512: botan.hash_init(ctx, botan.HASH_SHA3_512, 0)
    }
}

update :: proc "contextless" (ctx: ^botan.hash_t, data: []byte) {
    botan.hash_update(ctx^, len(data) == 0 ? nil : &data[0], uint(len(data)))
}

final :: proc "contextless" (ctx: ^botan.hash_t, hash: []byte) {
    botan.hash_final(ctx^, &hash[0])
    botan.hash_destroy(ctx^)
}