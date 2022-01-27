package tiger2

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Interface for the Tiger2 variant of the Tiger hashing algorithm as defined in <https://www.cs.technion.ac.il/~biham/Reports/Tiger/>
*/

import "core:os"
import "core:io"

import "../_tiger"

/*
    High level API
*/

DIGEST_SIZE_128 :: 16
DIGEST_SIZE_160 :: 20
DIGEST_SIZE_192 :: 24

// hash_string_128 will hash the given input and return the
// computed hash
hash_string_128 :: proc(data: string) -> [DIGEST_SIZE_128]byte {
    return hash_bytes_128(transmute([]byte)(data))
}

// hash_bytes_128 will hash the given input and return the
// computed hash
hash_bytes_128 :: proc(data: []byte) -> [DIGEST_SIZE_128]byte {
    hash: [DIGEST_SIZE_128]byte
    ctx: _tiger.Tiger_Context
    ctx.ver = 2
    _tiger.init(&ctx)
    _tiger.update(&ctx, data)
    _tiger.final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_128 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_128 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_128(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer_128 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_128 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_128, "Size of destination buffer is smaller than the digest size")
    ctx: _tiger.Tiger_Context
    ctx.ver = 2
    _tiger.init(&ctx)
    _tiger.update(&ctx, data)
    _tiger.final(&ctx, hash)
}

// hash_stream_128 will read the stream in chunks and compute a
// hash from its contents
hash_stream_128 :: proc(s: io.Stream) -> ([DIGEST_SIZE_128]byte, bool) {
    hash: [DIGEST_SIZE_128]byte
    ctx: _tiger.Tiger_Context
    ctx.ver = 2
    _tiger.init(&ctx)
    buf := make([]byte, 512)
    defer delete(buf)
    read := 1
    for read > 0 {
        read, _ = s->impl_read(buf)
        if read > 0 {
            _tiger.update(&ctx, buf[:read])
        } 
    }
    _tiger.final(&ctx, hash[:])
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

// hash_string_160 will hash the given input and return the
// computed hash
hash_string_160 :: proc(data: string) -> [DIGEST_SIZE_160]byte {
    return hash_bytes_160(transmute([]byte)(data))
}

// hash_bytes_160 will hash the given input and return the
// computed hash
hash_bytes_160 :: proc(data: []byte) -> [DIGEST_SIZE_160]byte {
    hash: [DIGEST_SIZE_160]byte
    ctx: _tiger.Tiger_Context
    ctx.ver = 2
    _tiger.init(&ctx)
    _tiger.update(&ctx, data)
    _tiger.final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_160 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_160 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_160(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer_160 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_160 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_160, "Size of destination buffer is smaller than the digest size")
    ctx: _tiger.Tiger_Context
    ctx.ver = 2
    _tiger.init(&ctx)
    _tiger.update(&ctx, data)
    _tiger.final(&ctx, hash)
}

// hash_stream_160 will read the stream in chunks and compute a
// hash from its contents
hash_stream_160 :: proc(s: io.Stream) -> ([DIGEST_SIZE_160]byte, bool) {
    hash: [DIGEST_SIZE_160]byte
    ctx: _tiger.Tiger_Context
    ctx.ver = 2
    _tiger.init(&ctx)
    buf := make([]byte, 512)
    defer delete(buf)
    read := 1
    for read > 0 {
        read, _ = s->impl_read(buf)
        if read > 0 {
            _tiger.update(&ctx, buf[:read])
        } 
    }
    _tiger.final(&ctx, hash[:])
    return hash, true
}

// hash_file_160 will read the file provided by the given handle
// and compute a hash
hash_file_160 :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE_160]byte, bool) {
    if !load_at_once {
        return hash_stream_160(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_160(buf[:]), ok
        }
    }
    return [DIGEST_SIZE_160]byte{}, false
}

hash_160 :: proc {
    hash_stream_160,
    hash_file_160,
    hash_bytes_160,
    hash_string_160,
    hash_bytes_to_buffer_160,
    hash_string_to_buffer_160,
}

// hash_string_192 will hash the given input and return the
// computed hash
hash_string_192 :: proc(data: string) -> [DIGEST_SIZE_192]byte {
    return hash_bytes_192(transmute([]byte)(data))
}

// hash_bytes_192 will hash the given input and return the
// computed hash
hash_bytes_192 :: proc(data: []byte) -> [DIGEST_SIZE_192]byte {
    hash: [DIGEST_SIZE_192]byte
    ctx: _tiger.Tiger_Context
    ctx.ver = 2
    _tiger.init(&ctx)
    _tiger.update(&ctx, data)
    _tiger.final(&ctx, hash[:])
    return hash
}

// hash_string_to_buffer_192 will hash the given input and assign the
// computed hash to the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_string_to_buffer_192 :: proc(data: string, hash: []byte) {
    hash_bytes_to_buffer_192(transmute([]byte)(data), hash)
}

// hash_bytes_to_buffer_192 will hash the given input and write the
// computed hash into the second parameter.
// It requires that the destination buffer is at least as big as the digest size
hash_bytes_to_buffer_192 :: proc(data, hash: []byte) {
    assert(len(hash) >= DIGEST_SIZE_192, "Size of destination buffer is smaller than the digest size")
    ctx: _tiger.Tiger_Context
    ctx.ver = 2
    _tiger.init(&ctx)
    _tiger.update(&ctx, data)
    _tiger.final(&ctx, hash)
}

// hash_stream_192 will read the stream in chunks and compute a
// hash from its contents
hash_stream_192 :: proc(s: io.Stream) -> ([DIGEST_SIZE_192]byte, bool) {
    hash: [DIGEST_SIZE_192]byte
    ctx: _tiger.Tiger_Context
    ctx.ver = 2
    _tiger.init(&ctx)
    buf := make([]byte, 512)
    defer delete(buf)
    read := 1
    for read > 0 {
        read, _ = s->impl_read(buf)
        if read > 0 {
            _tiger.update(&ctx, buf[:read])
        } 
    }
    _tiger.final(&ctx, hash[:])
    return hash, true
}

// hash_file_192 will read the file provided by the given handle
// and compute a hash
hash_file_192 :: proc(hd: os.Handle, load_at_once := false) -> ([DIGEST_SIZE_192]byte, bool) {
    if !load_at_once {
        return hash_stream_192(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_192(buf[:]), ok
        }
    }
    return [DIGEST_SIZE_192]byte{}, false
}

hash_192 :: proc {
    hash_stream_192,
    hash_file_192,
    hash_bytes_192,
    hash_string_192,
    hash_bytes_to_buffer_192,
    hash_string_to_buffer_192,
}

/*
    Low level API
*/

Tiger_Context :: _tiger.Tiger_Context

init :: proc(ctx: ^_tiger.Tiger_Context) {
    ctx.ver = 2
    _tiger.init(ctx)
}

update :: proc(ctx: ^_tiger.Tiger_Context, data: []byte) {
    _tiger.update(ctx, data)
}

final :: proc(ctx: ^_tiger.Tiger_Context, hash: []byte) {
    _tiger.final(ctx, hash)
}