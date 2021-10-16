package skein

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
        Jeroen van Rijn: Context design to be able to change from Odin implementation to bindings.

    Implementation of the SKEIN hashing algorithm, as defined in <https://www.schneier.com/academic/skein/>
    
    This package offers the internal state sizes of 256, 512 and 1024 bits and arbitrary output size.
*/

import "core:os"
import "core:io"

import "../botan"
import "../_ctx"

/*
    Context initialization and switching between the Odin implementation and the bindings
*/

USE_BOTAN_LIB :: bool(#config(USE_BOTAN_LIB, false))

@(private)
_init_vtable :: #force_inline proc() -> ^_ctx.Hash_Context {
    ctx := _ctx._init_vtable()
    when USE_BOTAN_LIB {
        use_botan()
        ctx.is_using_odin = false
    } else {
        _assign_hash_vtable(ctx)
        ctx.is_using_odin = true
    }
    return ctx
}

@(private)
_assign_hash_vtable :: #force_inline proc(ctx: ^_ctx.Hash_Context) {
    // @note(zh): Default to SKEIN-512
    ctx.hash_bytes_slice  = hash_bytes_skein512_odin
    ctx.hash_file_slice   = hash_file_skein512_odin
    ctx.hash_stream_slice = hash_stream_skein512_odin
    ctx.init              = _init_skein512_odin
    ctx.update            = _update_skein512_odin
    ctx.final             = _final_skein512_odin
}

_hash_impl := _init_vtable()

// use_botan assigns the internal vtable of the hash context to use the Botan bindings
use_botan :: #force_inline proc() {
    _hash_impl.is_using_odin = false
    // @note(zh): Botan only supports SKEIN-512.
    botan.assign_hash_vtable(_hash_impl, botan.HASH_SKEIN_512)
}

// use_odin assigns the internal vtable of the hash context to use the Odin implementation
@(warning="SKEIN is not yet implemented in Odin. Botan bindings will be used")
use_odin :: #force_inline proc() {
    // _hash_impl.is_using_odin = true
    // _assign_hash_vtable(_hash_impl)
    use_botan()
}

@(private)
_create_skein256_ctx :: #force_inline proc(size: int) {
    _hash_impl.hash_size_val = size
    if _hash_impl.is_using_odin {
        ctx: Skein256_Context
        ctx.h.bit_length             = u64(size)
        _hash_impl.internal_ctx      = ctx
        _hash_impl.hash_bytes_slice  = hash_bytes_skein256_odin
        _hash_impl.hash_file_slice   = hash_file_skein256_odin
        _hash_impl.hash_stream_slice = hash_stream_skein256_odin
        _hash_impl.init              = _init_skein256_odin
        _hash_impl.update            = _update_skein256_odin
        _hash_impl.final             = _final_skein256_odin
    }
}

@(private)
_create_skein512_ctx :: #force_inline proc(size: int) {
    _hash_impl.hash_size_val = size
    if _hash_impl.is_using_odin {
        ctx: Skein512_Context
        ctx.h.bit_length             = u64(size)
        _hash_impl.internal_ctx      = ctx
        _hash_impl.hash_bytes_slice  = hash_bytes_skein512_odin
        _hash_impl.hash_file_slice   = hash_file_skein512_odin
        _hash_impl.hash_stream_slice = hash_stream_skein512_odin
        _hash_impl.init              = _init_skein512_odin
        _hash_impl.update            = _update_skein512_odin
        _hash_impl.final             = _final_skein512_odin
    }
}

@(private)
_create_skein1024_ctx :: #force_inline proc(size: int) {
    _hash_impl.hash_size_val = size
    if _hash_impl.is_using_odin {
        ctx: Skein1024_Context
        ctx.h.bit_length             = u64(size)
        _hash_impl.internal_ctx      = ctx
        _hash_impl.hash_bytes_slice  = hash_bytes_skein1024_odin
        _hash_impl.hash_file_slice   = hash_file_skein1024_odin
        _hash_impl.hash_stream_slice = hash_stream_skein1024_odin
        _hash_impl.init              = _init_skein1024_odin
        _hash_impl.update            = _update_skein1024_odin
        _hash_impl.final             = _final_skein1024_odin
    }
}

/*
    High level API
*/

// hash_skein256_string will hash the given input and return the
// computed hash
hash_skein256_string :: proc(data: string, bit_size: int, allocator := context.allocator) -> []byte {
    return hash_skein256_bytes(transmute([]byte)(data), bit_size, allocator)
}

// hash_skein256_bytes will hash the given input and return the
// computed hash
hash_skein256_bytes :: proc(data: []byte, bit_size: int, allocator := context.allocator) -> []byte {
    _create_skein256_ctx(bit_size)
    return _hash_impl->hash_bytes_slice(data, bit_size, allocator)
}

// hash_skein256_stream will read the stream in chunks and compute a
// hash from its contents
hash_skein256_stream :: proc(s: io.Stream, bit_size: int, allocator := context.allocator) -> ([]byte, bool) {
    _create_skein256_ctx(bit_size)
    return _hash_impl->hash_stream_slice(s, bit_size, allocator)
}

// hash_skein256_file will read the file provided by the given handle
// and compute a hash
hash_skein256_file :: proc(hd: os.Handle, bit_size: int, load_at_once := false, allocator := context.allocator) -> ([]byte, bool) {
    _create_skein256_ctx(bit_size)
    return _hash_impl->hash_file_slice(hd, bit_size, load_at_once, allocator)
}

hash_skein256 :: proc {
    hash_skein256_stream,
    hash_skein256_file,
    hash_skein256_bytes,
    hash_skein256_string,
}

// hash_skein512_string will hash the given input and return the
// computed hash
hash_skein512_string :: proc(data: string, bit_size: int, allocator := context.allocator) -> []byte {
    return hash_skein512_bytes(transmute([]byte)(data), bit_size, allocator)
}

// hash_skein512_bytes will hash the given input and return the
// computed hash
hash_skein512_bytes :: proc(data: []byte, bit_size: int, allocator := context.allocator) -> []byte {
    _create_skein512_ctx(bit_size)
    return _hash_impl->hash_bytes_slice(data, bit_size, allocator)
}

// hash_skein512_stream will read the stream in chunks and compute a
// hash from its contents
hash_skein512_stream :: proc(s: io.Stream, bit_size: int, allocator := context.allocator) -> ([]byte, bool) {
    _create_skein512_ctx(bit_size)
    return _hash_impl->hash_stream_slice(s, bit_size, allocator)
}

// hash_skein512_file will read the file provided by the given handle
// and compute a hash
hash_skein512_file :: proc(hd: os.Handle, bit_size: int, load_at_once := false, allocator := context.allocator) -> ([]byte, bool) {
    _create_skein512_ctx(bit_size)
    return _hash_impl->hash_file_slice(hd, bit_size, load_at_once, allocator)
}

hash_skein512 :: proc {
    hash_skein512_stream,
    hash_skein512_file,
    hash_skein512_bytes,
    hash_skein512_string,
}

// hash_skein1024_string will hash the given input and return the
// computed hash
hash_skein1024_string :: proc(data: string, bit_size: int, allocator := context.allocator) -> []byte {
    return hash_skein1024_bytes(transmute([]byte)(data), bit_size, allocator)
}

// hash_skein1024_bytes will hash the given input and return the
// computed hash
hash_skein1024_bytes :: proc(data: []byte, bit_size: int, allocator := context.allocator) -> []byte {
    _create_skein1024_ctx(bit_size)
    return _hash_impl->hash_bytes_slice(data, bit_size, allocator)
}

// hash_skein1024_stream will read the stream in chunks and compute a
// hash from its contents
hash_skein1024_stream :: proc(s: io.Stream, bit_size: int, allocator := context.allocator) -> ([]byte, bool) {
    _create_skein1024_ctx(bit_size)
    return _hash_impl->hash_stream_slice(s, bit_size, allocator)
}

// hash_skein1024_file will read the file provided by the given handle
// and compute a hash
hash_skein1024_file :: proc(hd: os.Handle, bit_size: int, load_at_once := false, allocator := context.allocator) -> ([]byte, bool) {
    _create_skein1024_ctx(bit_size)
    return _hash_impl->hash_file_slice(hd, bit_size, load_at_once, allocator)
}

hash_skein1024 :: proc {
    hash_skein1024_stream,
    hash_skein1024_file,
    hash_skein1024_bytes,
    hash_skein1024_string,
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

hash_bytes_skein256_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte, bit_size: int, allocator := context.allocator) -> []byte {
    hash := make([]byte, bit_size, allocator)
    if c, ok := ctx.internal_ctx.(Skein256_Context); ok {
        init_odin(&c)
        update_odin(&c, data)
        final_odin(&c, hash[:])
        return hash
    } else {
        delete(hash)
        return nil
    }
}

hash_stream_skein256_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream, bit_size: int, allocator := context.allocator) -> ([]byte, bool) {
    hash := make([]byte, bit_size, allocator)
    if c, ok := ctx.internal_ctx.(Skein256_Context); ok {
        init_odin(&c)
        buf := make([]byte, 512)
        defer delete(buf)
        read := 1
        for read > 0 {
            read, _ = fs->impl_read(buf)
            if read > 0 {
                update_odin(&c, buf[:read])
            } 
        }
        final_odin(&c, hash[:])
        return hash, true
    } else {
        delete(hash)
        return nil, false
    }
}

hash_file_skein256_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, hd: os.Handle, bit_size: int, load_at_once := false, allocator := context.allocator) -> ([]byte, bool) {
    if !load_at_once {
        return hash_stream_skein256_odin(ctx, os.stream_from_handle(hd), bit_size, allocator)
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_skein256_odin(ctx, buf[:], bit_size, allocator), ok
        }
    }
    return nil, false
}

hash_bytes_skein512_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte, bit_size: int, allocator := context.allocator) -> []byte {
    hash := make([]byte, bit_size, allocator)
    if c, ok := ctx.internal_ctx.(Skein512_Context); ok {
        init_odin(&c)
        update_odin(&c, data)
        final_odin(&c, hash[:])
        return hash
    } else {
        delete(hash)
        return nil
    }
}

hash_stream_skein512_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream, bit_size: int, allocator := context.allocator) -> ([]byte, bool) {
    hash := make([]byte, bit_size, allocator)
    if c, ok := ctx.internal_ctx.(Skein512_Context); ok {
        init_odin(&c)
        buf := make([]byte, 512)
        defer delete(buf)
        read := 1
        for read > 0 {
            read, _ = fs->impl_read(buf)
            if read > 0 {
                update_odin(&c, buf[:read])
            } 
        }
        final_odin(&c, hash[:])
        return hash, true
    } else {
        delete(hash)
        return nil, false
    }
}

hash_file_skein512_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, hd: os.Handle, bit_size: int, load_at_once := false, allocator := context.allocator) -> ([]byte, bool) {
    if !load_at_once {
        return hash_stream_skein512_odin(ctx, os.stream_from_handle(hd), bit_size, allocator)
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_skein512_odin(ctx, buf[:], bit_size, allocator), ok
        }
    }
    return nil, false
}

hash_bytes_skein1024_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte, bit_size: int, allocator := context.allocator) -> []byte {
    hash := make([]byte, bit_size, allocator)
    if c, ok := ctx.internal_ctx.(Skein1024_Context); ok {
        init_odin(&c)
        update_odin(&c, data)
        final_odin(&c, hash[:])
        return hash
    } else {
        delete(hash)
        return nil
    }
}

hash_stream_skein1024_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream, bit_size: int, allocator := context.allocator) -> ([]byte, bool) {
    hash := make([]byte, bit_size, allocator)
    if c, ok := ctx.internal_ctx.(Skein1024_Context); ok {
        init_odin(&c)
        buf := make([]byte, 512)
        defer delete(buf)
        read := 1
        for read > 0 {
            read, _ = fs->impl_read(buf)
            if read > 0 {
                update_odin(&c, buf[:read])
            } 
        }
        final_odin(&c, hash[:])
        return hash, true
    } else {
        delete(hash)
        return nil, false
    }
}

hash_file_skein1024_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, hd: os.Handle, bit_size: int, load_at_once := false, allocator := context.allocator) -> ([]byte, bool) {
    if !load_at_once {
        return hash_stream_skein512_odin(ctx, os.stream_from_handle(hd), bit_size, allocator)
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_skein512_odin(ctx, buf[:], bit_size, allocator), ok
        }
    }
    return nil, false
}

@(private)
_init_skein256_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context) {
    _create_skein256_ctx(ctx.hash_size_val)
    if c, ok := ctx.internal_ctx.(Skein256_Context); ok {
        init_odin(&c)
    }
}

@(private)
_update_skein256_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) {
    if c, ok := ctx.internal_ctx.(Skein256_Context); ok {
        update_odin(&c, data)
    }
}

@(private)
_final_skein256_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, hash: []byte) {
    if c, ok := ctx.internal_ctx.(Skein256_Context); ok {
        final_odin(&c, hash)
    }
}

@(private)
_init_skein512_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context) {
    _create_skein512_ctx(ctx.hash_size_val)
    if c, ok := ctx.internal_ctx.(Skein512_Context); ok {
        init_odin(&c)
    }
}

@(private)
_update_skein512_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) {
    if c, ok := ctx.internal_ctx.(Skein512_Context); ok {
        update_odin(&c, data)
    }
}

@(private)
_final_skein512_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, hash: []byte) {
    if c, ok := ctx.internal_ctx.(Skein512_Context); ok {
        final_odin(&c, hash)
    }
}

@(private)
_init_skein1024_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context) {
    _create_skein1024_ctx(ctx.hash_size_val)
    if c, ok := ctx.internal_ctx.(Skein1024_Context); ok {
        init_odin(&c)
    }
}

@(private)
_update_skein1024_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) {
    if c, ok := ctx.internal_ctx.(Skein1024_Context); ok {
        update_odin(&c, data)
    }
}

@(private)
_final_skein1024_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, hash: []byte) {
    if c, ok := ctx.internal_ctx.(Skein1024_Context); ok {
        final_odin(&c, hash)
    }
}

/*
    SKEIN implementation
*/

STATE_WORDS_256  :: 4
STATE_WORDS_512  :: 8
STATE_WORDS_1024 :: 16

STATE_BYTES_256  :: 32
STATE_BYTES_512  :: 64
STATE_BYTES_1024 :: 128

Skein_Header :: struct {
    bit_length: u64,
    bcnt:       u64,
    t:          [2]u64,
}

Skein256_Context :: struct {
    h: Skein_Header,
    x: [STATE_WORDS_256]u64,
    b: [STATE_BYTES_256]byte,
}

Skein512_Context :: struct {
    h: Skein_Header,
    x: [STATE_WORDS_512]u64,
    b: [STATE_BYTES_512]byte,
}

Skein1024_Context :: struct {
    h: Skein_Header,
    x: [STATE_WORDS_1024]u64,
    b: [STATE_BYTES_1024]byte,
}


init_odin :: proc(ctx: ^$T) {

}

update_odin :: proc(ctx: ^$T, data: []byte) {

}

final_odin :: proc(ctx: ^$T, hash: []byte) {

}