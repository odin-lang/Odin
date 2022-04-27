package keccak

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Interface for the Keccak hashing algorithm.
    This is done because the padding in the SHA3 standard was changed by the NIST, resulting in a different output.
*/

import "core:os"
import "core:io"

import "../_sha3"


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
    ctx: _sha3.Sha3_Context
    ctx.mdlen = DIGEST_SIZE_224
    ctx.is_keccak = true
    _sha3.init(&ctx)
    _sha3.update(&ctx, data)
    _sha3.final(&ctx, hash[:])
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
    ctx: _sha3.Sha3_Context
    ctx.mdlen = DIGEST_SIZE_224
    ctx.is_keccak = true
    _sha3.init(&ctx)
    _sha3.update(&ctx, data)
    _sha3.final(&ctx, hash)
}

// hash_stream_224 will read the stream in chunks and compute a
// hash from its contents
hash_stream_224 :: proc(s: io.Stream) -> ([DIGEST_SIZE_224]byte, bool) {
    hash: [DIGEST_SIZE_224]byte
    ctx: _sha3.Sha3_Context
    ctx.mdlen = DIGEST_SIZE_224
    ctx.is_keccak = true
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
    _sha3.final(&ctx, hash[:])
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
    ctx: _sha3.Sha3_Context
    ctx.mdlen = DIGEST_SIZE_256
    ctx.is_keccak = true
    _sha3.init(&ctx)
    _sha3.update(&ctx, data)
    _sha3.final(&ctx, hash[:])
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
    ctx.is_keccak = true
    _sha3.init(&ctx)
    _sha3.update(&ctx, data)
    _sha3.final(&ctx, hash)
}

// hash_stream_256 will read the stream in chunks and compute a
// hash from its contents
hash_stream_256 :: proc(s: io.Stream) -> ([DIGEST_SIZE_256]byte, bool) {
    hash: [DIGEST_SIZE_256]byte
    ctx: _sha3.Sha3_Context
    ctx.mdlen = DIGEST_SIZE_256
    ctx.is_keccak = true
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
    _sha3.final(&ctx, hash[:])
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
    ctx: _sha3.Sha3_Context
    ctx.mdlen = DIGEST_SIZE_384
    ctx.is_keccak = true
    _sha3.init(&ctx)
    _sha3.update(&ctx, data)
    _sha3.final(&ctx, hash[:])
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
    ctx: _sha3.Sha3_Context
    ctx.mdlen = DIGEST_SIZE_384
    ctx.is_keccak = true
    _sha3.init(&ctx)
    _sha3.update(&ctx, data)
    _sha3.final(&ctx, hash)
}

// hash_stream_384 will read the stream in chunks and compute a
// hash from its contents
hash_stream_384 :: proc(s: io.Stream) -> ([DIGEST_SIZE_384]byte, bool) {
    hash: [DIGEST_SIZE_384]byte
    ctx: _sha3.Sha3_Context
    ctx.mdlen = DIGEST_SIZE_384
    ctx.is_keccak = true
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
    _sha3.final(&ctx, hash[:])
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
    ctx: _sha3.Sha3_Context
    ctx.mdlen = DIGEST_SIZE_512
    ctx.is_keccak = true
    _sha3.init(&ctx)
    _sha3.update(&ctx, data)
    _sha3.final(&ctx, hash[:])
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
    ctx: _sha3.Sha3_Context
    ctx.mdlen = DIGEST_SIZE_512
    ctx.is_keccak = true
    _sha3.init(&ctx)
    _sha3.update(&ctx, data)
    _sha3.final(&ctx, hash)
}

// hash_stream_512 will read the stream in chunks and compute a
// hash from its contents
hash_stream_512 :: proc(s: io.Stream) -> ([DIGEST_SIZE_512]byte, bool) {
    hash: [DIGEST_SIZE_512]byte
    ctx: _sha3.Sha3_Context
    ctx.mdlen = DIGEST_SIZE_512
    ctx.is_keccak = true
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
    _sha3.final(&ctx, hash[:])
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

Keccak_Context :: _sha3.Sha3_Context

init :: proc(ctx: ^_sha3.Sha3_Context) {
    ctx.is_keccak = true
    _sha3.init(ctx)
}

update :: proc "contextless" (ctx: ^_sha3.Sha3_Context, data: []byte) {
    _sha3.update(ctx, data)
}

final :: proc "contextless" (ctx: ^_sha3.Sha3_Context, hash: []byte) {
    _sha3.final(ctx, hash)
}
