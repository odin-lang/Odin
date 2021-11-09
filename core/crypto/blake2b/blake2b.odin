package blake2b

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Interface for the BLAKE2B hashing algorithm.
    BLAKE2B and BLAKE2B share the implementation in the _blake2 package.
*/

import "core:os"
import "core:io"

import "../_blake2"

/*
    High level API
*/

// hash_string will hash the given input and return the
// computed hash
hash_string :: proc(data: string) -> [64]byte {
    return hash_bytes(transmute([]byte)(data))
}

// hash_bytes will hash the given input and return the
// computed hash
hash_bytes :: proc(data: []byte) -> [64]byte {
    hash: [64]byte
    ctx: _blake2.Blake2b_Context
    cfg: _blake2.Blake2_Config
    cfg.size = _blake2.BLAKE2B_SIZE
    ctx.cfg  = cfg
    _blake2.init(&ctx)
    _blake2.update(&ctx, data)
    _blake2.final(&ctx, hash[:])
    return hash
}

// hash_stream will read the stream in chunks and compute a
// hash from its contents
hash_stream :: proc(s: io.Stream) -> ([64]byte, bool) {
    hash: [64]byte
    ctx: _blake2.Blake2b_Context
    cfg: _blake2.Blake2_Config
    cfg.size = _blake2.BLAKE2B_SIZE
    ctx.cfg  = cfg
    _blake2.init(&ctx)
    buf := make([]byte, 512)
    defer delete(buf)
    read := 1
    for read > 0 {
        read, _ = s->impl_read(buf)
        if read > 0 {
            _blake2.update(&ctx, buf[:read])
        } 
    }
    _blake2.final(&ctx, hash[:])
    return hash, true 
}

// hash_file will read the file provided by the given handle
// and compute a hash
hash_file :: proc(hd: os.Handle, load_at_once := false) -> ([64]byte, bool) {
    if !load_at_once {
        return hash_stream(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes(buf[:]), ok
        }
    }
    return [64]byte{}, false
}

hash :: proc {
    hash_stream,
    hash_file,
    hash_bytes,
    hash_string,
}

/*
    Low level API
*/

Blake2b_Context :: _blake2.Blake2b_Context

init :: proc(ctx: ^_blake2.Blake2b_Context) {
    _blake2.init(ctx)
}

update :: proc "contextless" (ctx: ^_blake2.Blake2b_Context, data: []byte) {
    _blake2.update(ctx, data)
}

final :: proc "contextless" (ctx: ^_blake2.Blake2b_Context, hash: []byte) {
    _blake2.final(ctx, hash)
}
