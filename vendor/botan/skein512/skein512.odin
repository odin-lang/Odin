package skein512

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Interface for the SKEIN-512 hashing algorithm.
    The hash will be computed via bindings to the Botan crypto library
*/

import "core:os"
import "core:io"
import "core:strings"
import "core:fmt"

import botan "../bindings"

/*
    High level API
*/

DIGEST_SIZE_256 :: 32
DIGEST_SIZE_512 :: 64

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
    botan.hash_init(&ctx, botan.HASH_SKEIN_512_256, 0)
    botan.hash_update(ctx, len(data) == 0 ? nil : &data[0], uint(len(data)))
    botan.hash_final(ctx, &hash[0])
    botan.hash_destroy(ctx)
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
    ctx: botan.hash_t
    botan.hash_init(&ctx, botan.HASH_SKEIN_512_256, 0)
    botan.hash_update(ctx, len(data) == 0 ? nil : &data[0], uint(len(data)))
    botan.hash_final(ctx, &hash[0])
    botan.hash_destroy(ctx)
}

// hash_stream_256 will read the stream in chunks and compute a
// hash from its contents
hash_stream_256 :: proc(s: io.Stream) -> ([DIGEST_SIZE_256]byte, bool) {
    hash: [DIGEST_SIZE_256]byte
    ctx: botan.hash_t
    botan.hash_init(&ctx, botan.HASH_SKEIN_512_256, 0)
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

// hash_string_512 will hash the given input and return the
// computed hash
hash_string_512 :: proc(data: string) -> [DIGEST_SIZE_512]byte {
    return hash_bytes_512(transmute([]byte)(data))
}

// hash_bytes_512 will hash the given input and return the
// computed hash
hash_bytes_512 :: proc(data: []byte) -> [DIGEST_SIZE_512]byte {
    hash: [DIGEST_SIZE_512]byte
    ctx: botan.hash_t
    botan.hash_init(&ctx, botan.HASH_SKEIN_512_512, 0)
    botan.hash_update(ctx, len(data) == 0 ? nil : &data[0], uint(len(data)))
    botan.hash_final(ctx, &hash[0])
    botan.hash_destroy(ctx)
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
    ctx: botan.hash_t
    botan.hash_init(&ctx, botan.HASH_SKEIN_512_512, 0)
    botan.hash_update(ctx, len(data) == 0 ? nil : &data[0], uint(len(data)))
    botan.hash_final(ctx, &hash[0])
    botan.hash_destroy(ctx)
}

// hash_stream_512 will read the stream in chunks and compute a
// hash from its contents
hash_stream_512 :: proc(s: io.Stream) -> ([DIGEST_SIZE_512]byte, bool) {
    hash: [DIGEST_SIZE_512]byte
    ctx: botan.hash_t
    botan.hash_init(&ctx, botan.HASH_SKEIN_512_512, 0)
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

// hash_string_slice will hash the given input and return the
// computed hash
hash_string_slice :: proc(data: string, bit_size: int, allocator := context.allocator) -> []byte {
    return hash_bytes_slice(transmute([]byte)(data), bit_size, allocator)
}

// hash_bytes_slice will hash the given input and return the
// computed hash
hash_bytes_slice :: proc(data: []byte, bit_size: int, allocator := context.allocator) -> []byte {
    hash := make([]byte, bit_size, allocator)
    ctx: botan.hash_t
    botan.hash_init(&ctx, strings.unsafe_string_to_cstring(fmt.tprintf("Skein-512(%d)", bit_size * 8)), 0)
    botan.hash_update(ctx, len(data) == 0 ? nil : &data[0], uint(len(data)))
    botan.hash_final(ctx, &hash[0])
    botan.hash_destroy(ctx)
    return hash
}

// hash_string_to_buffer_512 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_slice :: proc(data: string, hash: []byte, bit_size: int, allocator := context.allocator) {
    hash_bytes_to_buffer_slice(transmute([]byte)(data), hash, bit_size, allocator)
}

// hash_bytes_to_buffer_slice will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_slice :: proc(data, hash: []byte, bit_size: int, allocator := context.allocator) {
    assert(len(hash) >= bit_size, "Size of destination buffer is smaller than the digest size")
    ctx: botan.hash_t
    botan.hash_init(&ctx, strings.unsafe_string_to_cstring(fmt.tprintf("Skein-512(%d)", bit_size * 8)), 0)
    botan.hash_update(ctx, len(data) == 0 ? nil : &data[0], uint(len(data)))
    botan.hash_final(ctx, &hash[0])
    botan.hash_destroy(ctx)
}

// hash_stream_slice will read the stream in chunks and compute a
// hash from its contents
hash_stream_slice :: proc(s: io.Stream, bit_size: int, allocator := context.allocator) -> ([]byte, bool) {
    hash := make([]byte, bit_size, allocator)
    ctx: botan.hash_t
    botan.hash_init(&ctx, strings.unsafe_string_to_cstring(fmt.tprintf("Skein-512(%d)", bit_size * 8)), 0)
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

// hash_file_slice will read the file provided by the given handle
// and compute a hash
hash_file_slice :: proc(hd: os.Handle, bit_size: int, load_at_once := false, allocator := context.allocator) -> ([]byte, bool) {
    if !load_at_once {
        return hash_stream_slice(os.stream_from_handle(hd), bit_size, allocator)
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_slice(buf[:], bit_size, allocator), ok
        }
    }
    return nil, false
}

hash_slice :: proc {
    hash_stream_slice,
    hash_file_slice,
    hash_bytes_slice,
    hash_string_slice,
    hash_bytes_to_buffer_slice,
    hash_string_to_buffer_slice,
}

/*
    Low level API
*/

Skein512_Context :: botan.hash_t

init :: proc(ctx: ^botan.hash_t, hash_size := 512) {
    switch hash_size {
        case 256:  botan.hash_init(ctx, botan.HASH_SKEIN_512_256,  0)
        case 512:  botan.hash_init(ctx, botan.HASH_SKEIN_512_512,  0)
        case:      botan.hash_init(ctx, strings.unsafe_string_to_cstring(fmt.tprintf("Skein-512(%d)", hash_size)), 0)
    }
}

update :: proc "contextless" (ctx: ^botan.hash_t, data: []byte) {
    botan.hash_update(ctx^, len(data) == 0 ? nil : &data[0], uint(len(data)))
}

final :: proc "contextless" (ctx: ^botan.hash_t, hash: []byte) {
    botan.hash_final(ctx^, &hash[0])
    botan.hash_destroy(ctx^)
}
