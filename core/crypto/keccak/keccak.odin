package keccak

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
        Jeroen van Rijn: Context design to be able to change from Odin implementation to bindings.

    Interface for the Keccak hashing algorithm.
    This is done because the padding in the SHA3 standard was changed by the NIST, resulting in a different output.
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
    ctx.hash_bytes_28  = hash_bytes_odin_28
    ctx.hash_file_28   = hash_file_odin_28
    ctx.hash_stream_28 = hash_stream_odin_28
    ctx.hash_bytes_32  = hash_bytes_odin_32
    ctx.hash_file_32   = hash_file_odin_32
    ctx.hash_stream_32 = hash_stream_odin_32
    ctx.hash_bytes_48  = hash_bytes_odin_48
    ctx.hash_file_48   = hash_file_odin_48
    ctx.hash_stream_48 = hash_stream_odin_48
    ctx.hash_bytes_64  = hash_bytes_odin_64
    ctx.hash_file_64   = hash_file_odin_64
    ctx.hash_stream_64 = hash_stream_odin_64
    ctx.init           = _init_odin
    ctx.update         = _update_odin
    ctx.final          = _final_odin
}

_hash_impl := _init_vtable()

// use_botan assigns the internal vtable of the hash context to use the Botan bindings
use_botan :: #force_inline proc() {
    botan.assign_hash_vtable(_hash_impl, botan.HASH_KECCAK)
}

// use_odin assigns the internal vtable of the hash context to use the Odin implementation
use_odin :: #force_inline proc() {
    _assign_hash_vtable(_hash_impl)
}

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
    _create_keccak_ctx(28)
    return _hash_impl->hash_bytes_28(data)
}

// hash_stream_224 will read the stream in chunks and compute a
// hash from its contents
hash_stream_224 :: proc(s: io.Stream) -> ([28]byte, bool) {
    _create_keccak_ctx(28)
    return _hash_impl->hash_stream_28(s)
}

// hash_file_224 will read the file provided by the given handle
// and compute a hash
hash_file_224 :: proc(hd: os.Handle, load_at_once := false) -> ([28]byte, bool) {
    _create_keccak_ctx(28)
    return _hash_impl->hash_file_28(hd, load_at_once)
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
    _create_keccak_ctx(32)
    return _hash_impl->hash_bytes_32(data)
}

// hash_stream_256 will read the stream in chunks and compute a
// hash from its contents
hash_stream_256 :: proc(s: io.Stream) -> ([32]byte, bool) {
    _create_keccak_ctx(32)
    return _hash_impl->hash_stream_32(s)
}

// hash_file_256 will read the file provided by the given handle
// and compute a hash
hash_file_256 :: proc(hd: os.Handle, load_at_once := false) -> ([32]byte, bool) {
    _create_keccak_ctx(32)
    return _hash_impl->hash_file_32(hd, load_at_once)
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
    _create_keccak_ctx(48)
    return _hash_impl->hash_bytes_48(data)
}

// hash_stream_384 will read the stream in chunks and compute a
// hash from its contents
hash_stream_384 :: proc(s: io.Stream) -> ([48]byte, bool) {
    _create_keccak_ctx(48)
    return _hash_impl->hash_stream_48(s)
}

// hash_file_384 will read the file provided by the given handle
// and compute a hash
hash_file_384 :: proc(hd: os.Handle, load_at_once := false) -> ([48]byte, bool) {
    _create_keccak_ctx(48)
    return _hash_impl->hash_file_48(hd, load_at_once)
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
    _create_keccak_ctx(64)
    return _hash_impl->hash_bytes_64(data)
}

// hash_stream_512 will read the stream in chunks and compute a
// hash from its contents
hash_stream_512 :: proc(s: io.Stream) -> ([64]byte, bool) {
    _create_keccak_ctx(64)
    return _hash_impl->hash_stream_64(s)
}

// hash_file_512 will read the file provided by the given handle
// and compute a hash
hash_file_512 :: proc(hd: os.Handle, load_at_once := false) -> ([64]byte, bool) {
    _create_keccak_ctx(64)
    return _hash_impl->hash_file_64(hd, load_at_once)
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

init :: proc(ctx: ^_ctx.Hash_Context) {
    _hash_impl->init()
}

update :: proc(ctx: ^_ctx.Hash_Context, data: []byte) {
    _hash_impl->update(data)
}

final :: proc(ctx: ^_ctx.Hash_Context, hash: []byte) {
    _hash_impl->final(hash)
}

hash_bytes_odin_28 :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) -> [28]byte {
    hash: [28]byte
    if c, ok := ctx.internal_ctx.(_sha3.Sha3_Context); ok {
        _sha3.init_odin(&c)
        _sha3.update_odin(&c, data)
        _sha3.final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_28 :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream) -> ([28]byte, bool) {
    hash: [28]byte
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
        _sha3.final_odin(&c, hash[:])
        return hash, true
    } else {
        return hash, false
    }
}

hash_file_odin_28 :: #force_inline proc(ctx: ^_ctx.Hash_Context, hd: os.Handle, load_at_once := false) -> ([28]byte, bool) {
    if !load_at_once {
        return hash_stream_odin_28(ctx, os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_odin_28(ctx, buf[:]), ok
        }
    }
    return [28]byte{}, false
}

hash_bytes_odin_32 :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) -> [32]byte {
    hash: [32]byte
    if c, ok := ctx.internal_ctx.(_sha3.Sha3_Context); ok {
        _sha3.init_odin(&c)
        _sha3.update_odin(&c, data)
        _sha3.final_odin(&c, hash[:])
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
        _sha3.final_odin(&c, hash[:])
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

hash_bytes_odin_48 :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) -> [48]byte {
    hash: [48]byte
    if c, ok := ctx.internal_ctx.(_sha3.Sha3_Context); ok {
        _sha3.init_odin(&c)
        _sha3.update_odin(&c, data)
        _sha3.final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_48 :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream) -> ([48]byte, bool) {
    hash: [48]byte
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
        _sha3.final_odin(&c, hash[:])
        return hash, true
    } else {
        return hash, false
    }
}

hash_file_odin_48 :: #force_inline proc(ctx: ^_ctx.Hash_Context, hd: os.Handle, load_at_once := false) -> ([48]byte, bool) {
    if !load_at_once {
        return hash_stream_odin_48(ctx, os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_odin_48(ctx, buf[:]), ok
        }
    }
    return [48]byte{}, false
}

hash_bytes_odin_64 :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) -> [64]byte {
    hash: [64]byte
    if c, ok := ctx.internal_ctx.(_sha3.Sha3_Context); ok {
        _sha3.init_odin(&c)
        _sha3.update_odin(&c, data)
        _sha3.final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_64 :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream) -> ([64]byte, bool) {
    hash: [64]byte
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
        _sha3.final_odin(&c, hash[:])
        return hash, true
    } else {
        return hash, false
    }
}

hash_file_odin_64 :: #force_inline proc(ctx: ^_ctx.Hash_Context, hd: os.Handle, load_at_once := false) -> ([64]byte, bool) {
    if !load_at_once {
        return hash_stream_odin_64(ctx, os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_odin_64(ctx, buf[:]), ok
        }
    }
    return [64]byte{}, false
}

@(private)
_create_keccak_ctx :: #force_inline proc(mdlen: int) {
    ctx: _sha3.Sha3_Context
    ctx.mdlen               = mdlen
    ctx.is_keccak           = true
    _hash_impl.internal_ctx = ctx
    switch mdlen {
        case 28: _hash_impl.hash_size = ._28
        case 32: _hash_impl.hash_size = ._32
        case 48: _hash_impl.hash_size = ._48
        case 64: _hash_impl.hash_size = ._64
    }
}

@(private)
_init_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context) {
    #partial switch ctx.hash_size {
        case ._28: _create_keccak_ctx(28)
        case ._32: _create_keccak_ctx(32)
        case ._48: _create_keccak_ctx(48)
        case ._64: _create_keccak_ctx(64)
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
        _sha3.final_odin(&c, hash)
    }
}
