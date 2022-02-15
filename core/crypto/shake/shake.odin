package shake

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Interface for the SHAKE hashing algorithm.
    The SHA3 functionality can be found in package sha3.
*/

import "core:os"
import "core:io"

import "../_sha3"

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
    ctx: _sha3.Sha3_Context
    ctx.mdlen = DIGEST_SIZE_128
    _sha3.init(&ctx)
    _sha3.update(&ctx, data)
    _sha3.shake_xof(&ctx)
    _sha3.shake_out(&ctx, hash[:])
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
    ctx: _sha3.Sha3_Context
    ctx.mdlen = DIGEST_SIZE_128
    _sha3.init(&ctx)
    _sha3.update(&ctx, data)
    _sha3.shake_xof(&ctx)
    _sha3.shake_out(&ctx, hash)
}

// hash_stream_128 will read the stream in chunks and compute a
// hash from its contents
hash_stream_128 :: proc(s: io.Stream) -> ([DIGEST_SIZE_128]byte, bool) {
    hash: [DIGEST_SIZE_128]byte
    ctx: _sha3.Sha3_Context
    ctx.mdlen = DIGEST_SIZE_128
    _sha3.init(&ctx)
    buf := make([]byte, 512)
    defer delete(buf)
    read := 1
    for read > 0 {
        read, _ = s->impl_read(buf)
        if read > 0 {
            _sha3.update(&ctx, buf[:read])
        } 
    }
    _sha3.shake_xof(&ctx)
    _sha3.shake_out(&ctx, hash[:])
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
    ctx: _sha3.Sha3_Context
    ctx.mdlen = DIGEST_SIZE_256
    _sha3.init(&ctx)
    _sha3.update(&ctx, data)
    _sha3.shake_xof(&ctx)
    _sha3.shake_out(&ctx, hash[:])
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
    ctx: _sha3.Sha3_Context
    ctx.mdlen = DIGEST_SIZE_256
    _sha3.init(&ctx)
    _sha3.update(&ctx, data)
    _sha3.shake_xof(&ctx)
    _sha3.shake_out(&ctx, hash)
}

// hash_stream_256 will read the stream in chunks and compute a
// hash from its contents
hash_stream_256 :: proc(s: io.Stream) -> ([DIGEST_SIZE_256]byte, bool) {
    hash: [DIGEST_SIZE_256]byte
    ctx: _sha3.Sha3_Context
    ctx.mdlen = DIGEST_SIZE_256
    _sha3.init(&ctx)
    buf := make([]byte, 512)
    defer delete(buf)
    read := 1
    for read > 0 {
        read, _ = s->impl_read(buf)
        if read > 0 {
            _sha3.update(&ctx, buf[:read])
        } 
    }
    _sha3.shake_xof(&ctx)
    _sha3.shake_out(&ctx, hash[:])
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

Shake_Context :: _sha3.Sha3_Context

init :: proc(ctx: ^_sha3.Sha3_Context) {
    _sha3.init(ctx)
}

update :: proc "contextless" (ctx: ^_sha3.Sha3_Context, data: []byte) {
    _sha3.update(ctx, data)
}

final :: proc "contextless" (ctx: ^_sha3.Sha3_Context, hash: []byte) {
    _sha3.shake_xof(ctx)
    _sha3.shake_out(ctx, hash[:])
}
