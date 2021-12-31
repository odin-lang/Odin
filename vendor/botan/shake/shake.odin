package shake

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Interface for the SHAKE hashing algorithm.
    The hash will be computed via bindings to the Botan crypto library
*/

import "core:os"
import "core:io"

import botan "../bindings"

/*
    High level API
*/

DIGEST_SIZE_128 :: 16
DIGEST_SIZE_256 :: 32

// hash_string_128 will hash the given input and return the
// computed hash
hash_string_128 :: proc(data: string) -> [DIGEST_SIZE_128]byte {
    return hash_bytes_128(transmute([]byte)(data))
}

// hash_bytes_128 will hash the given input and return the
// computed hash
hash_bytes_128 :: proc(data: []byte) -> [DIGEST_SIZE_128]byte {
    hash: [DIGEST_SIZE_128]byte
    ctx: botan.hash_t
    botan.hash_init(&ctx, botan.HASH_SHAKE_128, 0)
    botan.hash_update(ctx, len(data) == 0 ? nil : &data[0], uint(len(data)))
    botan.hash_final(ctx, &hash[0])
    botan.hash_destroy(ctx)
    return hash
}

// hash_string_to_buffer_128 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_128 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_128(transmute([]byte)(data), hash);
}

// hash_bytes_to_buffer_128 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_128 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_128, "Size of destination buffer is smaller than the digest size")
    ctx: botan.hash_t
    botan.hash_init(&ctx, botan.HASH_SHAKE_128, 0)
    botan.hash_update(ctx, len(data) == 0 ? nil : &data[0], uint(len(data)))
    botan.hash_final(ctx, &hash[0])
    botan.hash_destroy(ctx)
}

// hash_stream_128 will read the stream in chunks and compute a
// hash from its contents
hash_stream_128 :: proc(s: io.Stream) -> ([DIGEST_SIZE_128]byte, bool) {
    hash: [DIGEST_SIZE_128]byte
    ctx: botan.hash_t
    botan.hash_init(&ctx, botan.HASH_SHAKE_128, 0)
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

// hash_file_128 will read the file provided by the given handle
// and compute a hash
hash_file_128 :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE_128]byte, bool) {
    if !load_at_once {
        return hash_stream_128(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_128(buf[:]), ok
        }
    }
    return [DIGEST_SIZE_128]byte{}, false
}

hash_128 :: proc {
    hash_stream_128,
    hash_file_128,
    hash_bytes_128,
    hash_string_128,
    hash_bytes_to_buffer_128,
    hash_string_to_buffer_128,
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
    ctx: botan.hash_t
    botan.hash_init(&ctx, botan.HASH_SHAKE_256, 0)
    botan.hash_update(ctx, len(data) == 0 ? nil : &data[0], uint(len(data)))
    botan.hash_final(ctx, &hash[0])
    botan.hash_destroy(ctx)
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
    ctx: botan.hash_t
    botan.hash_init(&ctx, botan.HASH_SHAKE_256, 0)
    botan.hash_update(ctx, len(data) == 0 ? nil : &data[0], uint(len(data)))
    botan.hash_final(ctx, &hash[0])
    botan.hash_destroy(ctx)
}

// hash_stream_256 will read the stream in chunks and compute a
// hash from its contents
hash_stream_256 :: proc(s: io.Stream) -> ([DIGEST_SIZE_256]byte, bool) {
    hash: [DIGEST_SIZE_256]byte
    ctx: botan.hash_t
    botan.hash_init(&ctx, botan.HASH_SHAKE_256, 0)
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

/*
    Low level API
*/

Shake_Context :: botan.hash_t

init :: proc "contextless" (ctx: ^botan.hash_t, hash_size := 256) {
    switch hash_size {
        case 128: botan.hash_init(ctx, botan.HASH_SHAKE_128, 0)
        case 256: botan.hash_init(ctx, botan.HASH_SHAKE_256, 0)
    }
}

update :: proc "contextless" (ctx: ^botan.hash_t, data: []byte) {
    botan.hash_update(ctx^, len(data) == 0 ? nil : &data[0], uint(len(data)))
}

final :: proc "contextless" (ctx: ^botan.hash_t, hash: []byte) {
    botan.hash_final(ctx^, &hash[0])
    botan.hash_destroy(ctx^)
}
