package blake2s

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Interface for the BLAKE2S hashing algorithm.
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
hash_string :: proc(data: string) -> [32]byte {
    return hash_bytes(transmute([]byte)(data))
}

// hash_bytes will hash the given input and return the
// computed hash
hash_bytes :: proc(data: []byte) -> [32]byte {
    hash: [32]byte
    ctx: _blake2.Blake2s_Context
    cfg: _blake2.Blake2_Config
    cfg.size = _blake2.BLAKE2S_SIZE
    ctx.cfg  = cfg
    _blake2.init(&ctx)
    _blake2.update(&ctx, data)
    _blake2.final(&ctx, hash[:])
    return hash
}

// hash_stream will read the stream in chunks and compute a
// hash from its contents
hash_stream :: proc(s: io.Stream) -> ([32]byte, bool) {
    hash: [32]byte
    ctx: _blake2.Blake2s_Context
    cfg: _blake2.Blake2_Config
    cfg.size = _blake2.BLAKE2S_SIZE
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
hash_file :: proc(hd: os.Handle, load_at_once := false) -> ([32]byte, bool) {
    if !load_at_once {
        return hash_stream(os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes(buf[:]), ok
        }
    }
    return [32]byte{}, false
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

Blake2s_Context :: _blake2.Blake2b_Context

init :: proc(ctx: ^_blake2.Blake2s_Context) {
    _blake2.init(ctx)
}

update :: proc "contextless" (ctx: ^_blake2.Blake2s_Context, data: []byte) {
    _blake2.update(ctx, data)
}

final :: proc "contextless" (ctx: ^_blake2.Blake2s_Context, hash: []byte) {
    _blake2.final(ctx, hash)
}
