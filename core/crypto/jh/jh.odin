package jh

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
        Jeroen van Rijn: Context design to be able to change from Odin implementation to bindings.

    Implementation of the JH hashing algorithm, as defined in <https://www3.ntu.edu.sg/home/wuhj/research/jh/index.html>
*/

import "core:os"
import "core:io"

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

// use_botan does nothing, since JH is not available in Botan
@(warning="JH is not provided by the Botan API. Odin implementation will be used")
use_botan :: #force_inline proc() {
    use_odin()
}

// use_odin assigns the internal vtable of the hash context to use the Odin implementation
use_odin :: #force_inline proc() {
    _assign_hash_vtable(_hash_impl)
}

@(private)
_create_jh_ctx :: #force_inline proc(size: _ctx.Hash_Size) {
    ctx: Jh_Context
    _hash_impl.internal_ctx = ctx
    _hash_impl.hash_size    = size
    #partial switch size {
        case ._28: ctx.hashbitlen = 224
        case ._32: ctx.hashbitlen = 256
        case ._48: ctx.hashbitlen = 384
        case ._64: ctx.hashbitlen = 512
    }
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
    _create_jh_ctx(._28)
    return _hash_impl->hash_bytes_28(data)
}

// hash_stream_224 will read the stream in chunks and compute a
// hash from its contents
hash_stream_224 :: proc(s: io.Stream) -> ([28]byte, bool) {
    _create_jh_ctx(._28)
    return _hash_impl->hash_stream_28(s)
}

// hash_file_224 will read the file provided by the given handle
// and compute a hash
hash_file_224 :: proc(hd: os.Handle, load_at_once := false) -> ([28]byte, bool) {
    _create_jh_ctx(._28)
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
    _create_jh_ctx(._32)
    return _hash_impl->hash_bytes_32(data)
}

// hash_stream_256 will read the stream in chunks and compute a
// hash from its contents
hash_stream_256 :: proc(s: io.Stream) -> ([32]byte, bool) {
    _create_jh_ctx(._32)
    return _hash_impl->hash_stream_32(s)
}

// hash_file_256 will read the file provided by the given handle
// and compute a hash
hash_file_256 :: proc(hd: os.Handle, load_at_once := false) -> ([32]byte, bool) {
    _create_jh_ctx(._32)
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
    _create_jh_ctx(._48)
    return _hash_impl->hash_bytes_48(data)
}

// hash_stream_384 will read the stream in chunks and compute a
// hash from its contents
hash_stream_384 :: proc(s: io.Stream) -> ([48]byte, bool) {
    _create_jh_ctx(._48)
    return _hash_impl->hash_stream_48(s)
}

// hash_file_384 will read the file provided by the given handle
// and compute a hash
hash_file_384 :: proc(hd: os.Handle, load_at_once := false) -> ([48]byte, bool) {
    _create_jh_ctx(._48)
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
    _create_jh_ctx(._64)
    return _hash_impl->hash_bytes_64(data)
}

// hash_stream_512 will read the stream in chunks and compute a
// hash from its contents
hash_stream_512 :: proc(s: io.Stream) -> ([64]byte, bool) {
    _create_jh_ctx(._64)
    return _hash_impl->hash_stream_64(s)
}

// hash_file_512 will read the file provided by the given handle
// and compute a hash
hash_file_512 :: proc(hd: os.Handle, load_at_once := false) -> ([64]byte, bool) {
    _create_jh_ctx(._64)
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
    if c, ok := ctx.internal_ctx.(Jh_Context); ok {
        init_odin(&c)
        update_odin(&c, data)
        final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_28 :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream) -> ([28]byte, bool) {
    hash: [28]byte
    if c, ok := ctx.internal_ctx.(Jh_Context); ok {
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
    if c, ok := ctx.internal_ctx.(Jh_Context); ok {
        init_odin(&c)
        update_odin(&c, data)
        final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_32 :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream) -> ([32]byte, bool) {
    hash: [32]byte
    if c, ok := ctx.internal_ctx.(Jh_Context); ok {
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
    if c, ok := ctx.internal_ctx.(Jh_Context); ok {
        init_odin(&c)
        update_odin(&c, data)
        final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_48 :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream) -> ([48]byte, bool) {
    hash: [48]byte
    if c, ok := ctx.internal_ctx.(Jh_Context); ok {
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
    if c, ok := ctx.internal_ctx.(Jh_Context); ok {
        init_odin(&c)
        update_odin(&c, data)
        final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_64 :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream) -> ([64]byte, bool) {
    hash: [64]byte
    if c, ok := ctx.internal_ctx.(Jh_Context); ok {
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
_init_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context) {
    _create_jh_ctx(ctx.hash_size)
    if c, ok := ctx.internal_ctx.(Jh_Context); ok {
        init_odin(&c)
    }
}

@(private)
_update_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) {
    if c, ok := ctx.internal_ctx.(Jh_Context); ok {
        update_odin(&c, data)
    }
}

@(private)
_final_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, hash: []byte) {
    if c, ok := ctx.internal_ctx.(Jh_Context); ok {
        final_odin(&c, hash)
    }
}

/*
    JH implementation
*/

JH_ROUNDCONSTANT_ZERO := [64]byte {
    0x6, 0xa, 0x0, 0x9, 0xe, 0x6, 0x6, 0x7,
    0xf, 0x3, 0xb, 0xc, 0xc, 0x9, 0x0, 0x8,
    0xb, 0x2, 0xf, 0xb, 0x1, 0x3, 0x6, 0x6,
    0xe, 0xa, 0x9, 0x5, 0x7, 0xd, 0x3, 0xe,
    0x3, 0xa, 0xd, 0xe, 0xc, 0x1, 0x7, 0x5,
    0x1, 0x2, 0x7, 0x7, 0x5, 0x0, 0x9, 0x9,
    0xd, 0xa, 0x2, 0xf, 0x5, 0x9, 0x0, 0xb,
    0x0, 0x6, 0x6, 0x7, 0x3, 0x2, 0x2, 0xa,
}

JH_S := [2][16]byte {
    {9, 0,  4, 11, 13, 12, 3, 15, 1,  10, 2, 6, 7,  5,  8,  14},
    {3, 12, 6, 13, 5,  7,  1, 9,  15, 2,  0, 4, 11, 10, 14, 8},
}

Jh_Context :: struct {
    hashbitlen:    int,
    databitlen:    u64,
    buffer_size:   u64,
    H:             [128]byte,
    A:             [256]byte,
    roundconstant: [64]byte,
    buffer:        [64]byte,
}

JH_E8_finaldegroup :: proc(ctx: ^Jh_Context) {
    t0,t1,t2,t3: byte
    tem: [256]byte
    for i := 0; i < 128; i += 1 {
        tem[i]       = ctx.A[i << 1]
        tem[i + 128] = ctx.A[(i << 1) + 1]
    }
    for i := 0; i < 128; i += 1 {
        ctx.H[i] = 0
    }
    for i := 0; i < 256; i += 1 {
        t0 = (tem[i] >> 3) & 1
        t1 = (tem[i] >> 2) & 1
        t2 = (tem[i] >> 1) & 1
        t3 = (tem[i] >> 0) & 1

        ctx.H[uint(i) >> 3]         |= t0 << (7 - (uint(i) & 7))
        ctx.H[(uint(i) + 256) >> 3] |= t1 << (7 - (uint(i) & 7))
        ctx.H[(uint(i) + 512) >> 3] |= t2 << (7 - (uint(i) & 7))
        ctx.H[(uint(i) + 768) >> 3] |= t3 << (7 - (uint(i) & 7))
    }
}

jh_update_roundconstant :: proc(ctx: ^Jh_Context) {
    tem: [64]byte
    t: byte
    for i := 0; i < 64; i += 1 {
        tem[i] = JH_S[0][ctx.roundconstant[i]]
    }
    for i := 0; i < 64; i += 2 {
        tem[i + 1] ~= ((tem[i]   << 1)   ~ (tem[i]   >> 3)   ~ ((tem[i]   >> 2) & 2))   & 0xf
        tem[i]     ~= ((tem[i + 1] << 1) ~ (tem[i + 1] >> 3) ~ ((tem[i + 1] >> 2) & 2)) & 0xf
    }
    for i := 0; i < 64; i += 4 {
        t          = tem[i + 2]
        tem[i + 2] = tem[i + 3]
        tem[i + 3] = t
    }
    for i := 0; i < 32; i += 1 {
        ctx.roundconstant[i]      = tem[i << 1]
        ctx.roundconstant[i + 32] = tem[(i << 1) + 1]
    }
    for i := 32; i < 64; i += 2 {
        t                        = ctx.roundconstant[i]
        ctx.roundconstant[i]     = ctx.roundconstant[i + 1]
        ctx.roundconstant[i + 1] = t
    }
}

JH_R8 :: proc(ctx: ^Jh_Context) {
    t: byte
    tem, roundconstant_expanded: [256]byte
    for i := u32(0); i < 256; i += 1 {
        roundconstant_expanded[i] = (ctx.roundconstant[i >> 2] >> (3 - (i & 3)) ) & 1
    }
    for i := 0; i < 256; i += 1 {
        tem[i] = JH_S[roundconstant_expanded[i]][ctx.A[i]]
    }
    for i := 0; i < 256; i += 2 {
        tem[i+1] ~= ((tem[i]   << 1)   ~ (tem[i]   >> 3)   ~ ((tem[i]   >> 2) & 2))   & 0xf
        tem[i]   ~= ((tem[i + 1] << 1) ~ (tem[i + 1] >> 3) ~ ((tem[i + 1] >> 2) & 2)) & 0xf
    }
    for i := 0; i < 256; i += 4 {
        t        = tem[i + 2]
        tem[i+2] = tem[i + 3]
        tem[i+3] = t
    }
    for i := 0; i < 128; i += 1 {
        ctx.A[i]       = tem[i << 1]
        ctx.A[i + 128] = tem[(i << 1) + 1]
    }
    for i := 128; i < 256; i += 2 {
        t            = ctx.A[i]
        ctx.A[i]     = ctx.A[i + 1]
        ctx.A[i + 1] = t
    }
}

JH_E8_initialgroup :: proc(ctx: ^Jh_Context) {
    t0, t1, t2, t3: byte
    tem:            [256]byte
    for i := u32(0); i < 256; i += 1 {
        t0     = (ctx.H[i >> 3]   >> (7 - (i & 7)))       & 1
        t1     = (ctx.H[(i + 256) >> 3] >> (7 - (i & 7))) & 1
        t2     = (ctx.H[(i + 512) >> 3] >> (7 - (i & 7))) & 1
        t3     = (ctx.H[(i + 768) >> 3] >> (7 - (i & 7))) & 1
        tem[i] = (t0 << 3) | (t1 << 2) | (t2 << 1) | (t3 << 0)
    }
    for i := 0; i < 128; i += 1 {
        ctx.A[i << 1]       = tem[i]
        ctx.A[(i << 1) + 1] = tem[i + 128]
    }
}

JH_E8 :: proc(ctx: ^Jh_Context) {
    for i := 0; i < 64; i += 1 {
        ctx.roundconstant[i] = JH_ROUNDCONSTANT_ZERO[i]
    }
    JH_E8_initialgroup(ctx)
    for i := 0; i < 42; i += 1 {
        JH_R8(ctx)
        jh_update_roundconstant(ctx)
    }
    JH_E8_finaldegroup(ctx)
}

JH_F8 :: proc(ctx: ^Jh_Context) {
    for i := 0; i < 64; i += 1 {
        ctx.H[i] ~= ctx.buffer[i]
    }
    JH_E8(ctx)
    for i := 0; i < 64; i += 1 {
        ctx.H[i + 64] ~= ctx.buffer[i]
    }
}

init_odin :: proc(ctx: ^Jh_Context) {
    ctx.H[1] = byte(ctx.hashbitlen)      & 0xff
    ctx.H[0] = byte(ctx.hashbitlen >> 8) & 0xff
    JH_F8(ctx)
}

update_odin :: proc(ctx: ^Jh_Context, data: []byte) {
    databitlen     := u64(len(data)) * 8
    ctx.databitlen += databitlen
    i              := u64(0)

    if (ctx.buffer_size > 0) && ((ctx.buffer_size + databitlen) < 512) {
        if (databitlen & 7) == 0 {
            copy(ctx.buffer[ctx.buffer_size >> 3:], data[:64 - (ctx.buffer_size >> 3)])
		} else {
            copy(ctx.buffer[ctx.buffer_size >> 3:], data[:64 - (ctx.buffer_size >> 3) + 1])
        } 
        ctx.buffer_size += databitlen
        databitlen = 0
    }

    if (ctx.buffer_size > 0 ) && ((ctx.buffer_size + databitlen) >= 512) {
        copy(ctx.buffer[ctx.buffer_size >> 3:], data[:64 - (ctx.buffer_size >> 3)])
	    i      = 64 - (ctx.buffer_size >> 3)
	    databitlen = databitlen - (512 - ctx.buffer_size)
	    JH_F8(ctx)
	    ctx.buffer_size = 0
    }

    for databitlen >= 512 {
        copy(ctx.buffer[:], data[i:i + 64])
        JH_F8(ctx)
        i += 64
        databitlen -= 512
    }

    if databitlen > 0 {
        if (databitlen & 7) == 0 {
            copy(ctx.buffer[:], data[i:i + ((databitlen & 0x1ff) >> 3)])
        } else {
            copy(ctx.buffer[:], data[i:i + ((databitlen & 0x1ff) >> 3) + 1])
        }
        ctx.buffer_size = databitlen
    }
}

final_odin :: proc(ctx: ^Jh_Context, hash: []byte) {
    if ctx.databitlen & 0x1ff == 0 {
        for i := 0; i < 64; i += 1 {
            ctx.buffer[i] = 0
        }
        ctx.buffer[0]  = 0x80
        ctx.buffer[63] = byte(ctx.databitlen)       & 0xff
        ctx.buffer[62] = byte(ctx.databitlen >> 8)  & 0xff
        ctx.buffer[61] = byte(ctx.databitlen >> 16) & 0xff
        ctx.buffer[60] = byte(ctx.databitlen >> 24) & 0xff
        ctx.buffer[59] = byte(ctx.databitlen >> 32) & 0xff
        ctx.buffer[58] = byte(ctx.databitlen >> 40) & 0xff
        ctx.buffer[57] = byte(ctx.databitlen >> 48) & 0xff
        ctx.buffer[56] = byte(ctx.databitlen >> 56) & 0xff
        JH_F8(ctx)
    } else {
        if ctx.buffer_size & 7 == 0 {
            for i := (ctx.databitlen & 0x1ff) >> 3; i < 64; i += 1 {
                ctx.buffer[i] = 0
            }
        } else {
            for i := ((ctx.databitlen & 0x1ff) >> 3) + 1; i < 64; i += 1 {
                ctx.buffer[i] = 0
            }
        }
        ctx.buffer[(ctx.databitlen & 0x1ff) >> 3] |= 1 << (7 - (ctx.databitlen & 7))
        JH_F8(ctx)
        for i := 0; i < 64; i += 1 {
            ctx.buffer[i] = 0
        }
        ctx.buffer[63] = byte(ctx.databitlen)       & 0xff
        ctx.buffer[62] = byte(ctx.databitlen >> 8)  & 0xff
        ctx.buffer[61] = byte(ctx.databitlen >> 16) & 0xff
        ctx.buffer[60] = byte(ctx.databitlen >> 24) & 0xff
        ctx.buffer[59] = byte(ctx.databitlen >> 32) & 0xff
        ctx.buffer[58] = byte(ctx.databitlen >> 40) & 0xff
        ctx.buffer[57] = byte(ctx.databitlen >> 48) & 0xff
        ctx.buffer[56] = byte(ctx.databitlen >> 56) & 0xff
        JH_F8(ctx)
    }
    switch ctx.hashbitlen {
        case 224: copy(hash[:], ctx.H[100:128])
        case 256: copy(hash[:], ctx.H[96:128])
        case 384: copy(hash[:], ctx.H[80:128])
        case 512: copy(hash[:], ctx.H[64:128])
    }
}
