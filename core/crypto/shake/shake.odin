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

// hash_string_128 will hash the given input and return the
// computed hash
hash_string_128 :: proc(data: string) -> [16]byte {
    return hash_bytes_128(transmute([]byte)(data))
}

// hash_bytes_128 will hash the given input and return the
// computed hash
hash_bytes_128 :: proc(data: []byte) -> [16]byte {
    hash: [16]byte
    ctx: _sha3.Sha3_Context
    ctx.mdlen = 16
    _sha3.init(&ctx)
    _sha3.update(&ctx, data)
    _sha3.shake_xof(&ctx)
    _sha3.shake_out(&ctx, hash[:])
    return hash
}

// hash_stream_128 will read the stream in chunks and compute a
// hash from its contents
hash_stream_128 :: proc(s: io.Stream) -> ([16]byte, bool) {
    hash: [16]byte
    ctx: _sha3.Sha3_Context
    ctx.mdlen = 16
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
hash_file_128 :: proc(hd: os.Handle, load_at_once := false) -> ([16]byte, bool) {
    if !load_at_once {
        return hash_stream_128(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_128(buf[:]), ok
        }
    }
    return [16]byte{}, false
}

hash_128 :: proc {
    hash_stream_128,
    hash_file_128,
    hash_bytes_128,
    hash_string_128,
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
    ctx: _sha3.Sha3_Context
    ctx.mdlen = 32
    _sha3.init(&ctx)
    _sha3.update(&ctx, data)
    _sha3.shake_xof(&ctx)
    _sha3.shake_out(&ctx, hash[:])
    return hash
}

// hash_stream_256 will read the stream in chunks and compute a
// hash from its contents
hash_stream_256 :: proc(s: io.Stream) -> ([32]byte, bool) {
    hash: [32]byte
    ctx: _sha3.Sha3_Context
    ctx.mdlen = 32
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

/*
    Low level API
*/

Sha3_Context :: _sha3.Sha3_Context

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
