package shake

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
        Jeroen van Rijn: Context design to be able to change from Odin implementation to bindings.

    Interface for the SHAKE hashing algorithm.
    The SHA3 functionality can be found in package sha3.
*/

import "core:os"
import "core:io"

import "../botan"
import "../_ctx"
import "../_sha3"

/*
    Context initialization and switching between the Odin implementation and the bindings
*/

USE_BOTAN_LIB :: bool(#config(USE_BOTAN_LIB, false))

@(private)
_init_vtable :: #force_inline proc() -> ^_ctx.Hash_Context {
    ctx := _ctx._init_vtable()
    when USE_BOTAN_LIB {
        use_botan()
    } else {
        _assign_hash_vtable(ctx)
    }
    return ctx
}

@(private)
_assign_hash_vtable :: #force_inline proc(ctx: ^_ctx.Hash_Context) {
    ctx.hash_bytes_16  = hash_bytes_odin_16
    ctx.hash_file_16   = hash_file_odin_16
    ctx.hash_stream_16 = hash_stream_odin_16
    ctx.hash_bytes_32  = hash_bytes_odin_32
    ctx.hash_file_32   = hash_file_odin_32
    ctx.hash_stream_32 = hash_stream_odin_32
    ctx.init           = _init_odin
    ctx.update         = _update_odin
    ctx.final          = _final_odin
}

_hash_impl := _init_vtable()

// use_botan assigns the internal vtable of the hash context to use the Botan bindings
use_botan :: #force_inline proc() {
    botan.assign_hash_vtable(_hash_impl, botan.HASH_SHAKE)
}

// use_odin assigns the internal vtable of the hash context to use the Odin implementation
use_odin :: #force_inline proc() {
    _assign_hash_vtable(_hash_impl)
}

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
    _create_shake_ctx(16)
    return _hash_impl->hash_bytes_16(data)
}

// hash_stream_128 will read the stream in chunks and compute a
// hash from its contents
hash_stream_128 :: proc(s: io.Stream) -> ([16]byte, bool) {
    _create_shake_ctx(16)
    return _hash_impl->hash_stream_16(s)
}

// hash_file_128 will read the file provided by the given handle
// and compute a hash
hash_file_128 :: proc(hd: os.Handle, load_at_once := false) -> ([16]byte, bool) {
    _create_shake_ctx(16)
    return _hash_impl->hash_file_16(hd, load_at_once)
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
    _create_shake_ctx(32)
    return _hash_impl->hash_bytes_32(data)
}

// hash_stream_256 will read the stream in chunks and compute a
// hash from its contents
hash_stream_256 :: proc(s: io.Stream) -> ([32]byte, bool) {
    _create_shake_ctx(32)
    return _hash_impl->hash_stream_32(s)
}

// hash_file_256 will read the file provided by the given handle
// and compute a hash
hash_file_256 :: proc(hd: os.Handle, load_at_once := false) -> ([32]byte, bool) {
    _create_shake_ctx(32)
    return _hash_impl->hash_file_32(hd, load_at_once)
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

init :: proc(ctx: ^_ctx.Hash_Context) {
    _hash_impl->init()
}

update :: proc(ctx: ^_ctx.Hash_Context, data: []byte) {
    _hash_impl->update(data)
}

final :: proc(ctx: ^_ctx.Hash_Context, hash: []byte) {
    _hash_impl->final(hash)
}

hash_bytes_odin_16 :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) -> [16]byte {
    hash: [16]byte
    if c, ok := ctx.internal_ctx.(_sha3.Sha3_Context); ok {
        _sha3.init_odin(&c)
        _sha3.update_odin(&c, data)
        _sha3.shake_xof_odin(&c)
        _sha3.shake_out_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_16 :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream) -> ([16]byte, bool) {
    hash: [16]byte
    if c, ok := ctx.internal_ctx.(_sha3.Sha3_Context); ok {
        _sha3.init_odin(&c)
        buf := make([]byte, 512)
        defer delete(buf)
        read := 1
        for read > 0 {
            read, _ = fs->impl_read(buf)
            if read > 0 {
                _sha3.update_odin(&c, buf[:read])
            } 
        }
        _sha3.shake_xof_odin(&c)
        _sha3.shake_out_odin(&c, hash[:])
        return hash, true
    } else {
        return hash, false
    }
}

hash_file_odin_16 :: #force_inline proc(ctx: ^_ctx.Hash_Context, hd: os.Handle, load_at_once := false) -> ([16]byte, bool) {
    if !load_at_once {
        return hash_stream_odin_16(ctx, os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_odin_16(ctx, buf[:]), ok
        }
    }
    return [16]byte{}, false
}

hash_bytes_odin_32 :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) -> [32]byte {
    hash: [32]byte
    if c, ok := ctx.internal_ctx.(_sha3.Sha3_Context); ok {
        _sha3.init_odin(&c)
        _sha3.update_odin(&c, data)
        _sha3.shake_xof_odin(&c)
        _sha3.shake_out_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_32 :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream) -> ([32]byte, bool) {
    hash: [32]byte
    if c, ok := ctx.internal_ctx.(_sha3.Sha3_Context); ok {
        _sha3.init_odin(&c)
        buf := make([]byte, 512)
        defer delete(buf)
        read := 1
        for read > 0 {
            read, _ = fs->impl_read(buf)
            if read > 0 {
                _sha3.update_odin(&c, buf[:read])
            } 
        }
        _sha3.shake_xof_odin(&c)
        _sha3.shake_out_odin(&c, hash[:])
        return hash, true
    } else {
        return hash, false
    }
}

hash_file_odin_32 :: #force_inline proc(ctx: ^_ctx.Hash_Context, hd: os.Handle, load_at_once := false) -> ([32]byte, bool) {
    if !load_at_once {
        return hash_stream_odin_32(ctx, os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_odin_32(ctx, buf[:]), ok
        }
    }
    return [32]byte{}, false
}

@(private)
_create_shake_ctx :: #force_inline proc(mdlen: int) {
    ctx: _sha3.Sha3_Context
    ctx.mdlen               = mdlen
    _hash_impl.internal_ctx = ctx
    switch mdlen {
        case 16: _hash_impl.hash_size = ._16
        case 32: _hash_impl.hash_size = ._32
    }
}

@(private)
_init_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context) {
    #partial switch ctx.hash_size {
        case ._16: _create_shake_ctx(16)
        case ._32: _create_shake_ctx(32)
    }
    if c, ok := ctx.internal_ctx.(_sha3.Sha3_Context); ok {
        _sha3.init_odin(&c)
    }
}

@(private)
_update_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) {
    if c, ok := ctx.internal_ctx.(_sha3.Sha3_Context); ok {
        _sha3.update_odin(&c, data)
    }
}

@(private)
_final_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, hash: []byte) {
    if c, ok := ctx.internal_ctx.(_sha3.Sha3_Context); ok {
        _sha3.shake_xof_odin(&c)
        _sha3.shake_out_odin(&c, hash[:])
    }
}
