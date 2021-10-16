package ripemd

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
        Jeroen van Rijn: Context design to be able to change from Odin implementation to bindings.

    Implementation for the RIPEMD hashing algorithm as defined in <https://homes.esat.kuleuven.be/~bosselae/ripemd160.html>
*/

import "core:os"
import "core:io"

import "../util"
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
    ctx.hash_bytes_20  = hash_bytes_odin_20
    ctx.hash_file_20   = hash_file_odin_20
    ctx.hash_stream_20 = hash_stream_odin_20
    ctx.hash_bytes_32  = hash_bytes_odin_32
    ctx.hash_file_32   = hash_file_odin_32
    ctx.hash_stream_32 = hash_stream_odin_32
    ctx.hash_bytes_40  = hash_bytes_odin_40
    ctx.hash_file_40   = hash_file_odin_40
    ctx.hash_stream_40 = hash_stream_odin_40
    ctx.init           = _init_odin
    ctx.update         = _update_odin
    ctx.final          = _final_odin
}

_hash_impl := _init_vtable()

// use_botan assigns the internal vtable of the hash context to use the Botan bindings
use_botan :: #force_inline proc() {
    botan.assign_hash_vtable(_hash_impl, botan.HASH_RIPEMD_160)
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
    _create_ripemd_ctx(16)
    return _hash_impl->hash_bytes_16(data)
}

// hash_stream_128 will read the stream in chunks and compute a
// hash from its contents
hash_stream_128 :: proc(s: io.Stream) -> ([16]byte, bool) {
    _create_ripemd_ctx(16)
    return _hash_impl->hash_stream_16(s)
}

// hash_file_128 will read the file provided by the given handle
// and compute a hash
hash_file_128 :: proc(hd: os.Handle, load_at_once := false) -> ([16]byte, bool) {
    _create_ripemd_ctx(16)
    return _hash_impl->hash_file_16(hd, load_at_once)
}

hash_128 :: proc {
    hash_stream_128,
    hash_file_128,
    hash_bytes_128,
    hash_string_128,
}

// hash_string_160 will hash the given input and return the
// computed hash
hash_string_160 :: proc(data: string) -> [20]byte {
    return hash_bytes_160(transmute([]byte)(data))
}

// hash_bytes_160 will hash the given input and return the
// computed hash
hash_bytes_160 :: proc(data: []byte) -> [20]byte {
    _create_ripemd_ctx(20)
    return _hash_impl->hash_bytes_20(data)
}

// hash_stream_160 will read the stream in chunks and compute a
// hash from its contents
hash_stream_160 :: proc(s: io.Stream) -> ([20]byte, bool) {
    _create_ripemd_ctx(20)
    return _hash_impl->hash_stream_20(s)
}

// hash_file_160 will read the file provided by the given handle
// and compute a hash
hash_file_160 :: proc(hd: os.Handle, load_at_once := false) -> ([20]byte, bool) {
    _create_ripemd_ctx(20)
    return _hash_impl->hash_file_20(hd, load_at_once)
}

hash_160 :: proc {
    hash_stream_160,
    hash_file_160,
    hash_bytes_160,
    hash_string_160,
}

// hash_string_256 will hash the given input and return the
// computed hash
hash_string_256 :: proc(data: string) -> [32]byte {
    return hash_bytes_256(transmute([]byte)(data))
}

// hash_bytes_256 will hash the given input and return the
// computed hash
hash_bytes_256 :: proc(data: []byte) -> [32]byte {
    _create_ripemd_ctx(32)
    return _hash_impl->hash_bytes_32(data)
}

// hash_stream_256 will read the stream in chunks and compute a
// hash from its contents
hash_stream_256 :: proc(s: io.Stream) -> ([32]byte, bool) {
    _create_ripemd_ctx(32)
    return _hash_impl->hash_stream_32(s)
}

// hash_file_256 will read the file provided by the given handle
// and compute a hash
hash_file_256 :: proc(hd: os.Handle, load_at_once := false) -> ([32]byte, bool) {
    _create_ripemd_ctx(32)
    return _hash_impl->hash_file_32(hd, load_at_once)
}

hash_256 :: proc {
    hash_stream_256,
    hash_file_256,
    hash_bytes_256,
    hash_string_256,
}

// hash_string_320 will hash the given input and return the
// computed hash
hash_string_320 :: proc(data: string) -> [40]byte {
    return hash_bytes_320(transmute([]byte)(data))
}

// hash_bytes_320 will hash the given input and return the
// computed hash
hash_bytes_320 :: proc(data: []byte) -> [40]byte {
    _create_ripemd_ctx(40)
    return _hash_impl->hash_bytes_40(data)
}

// hash_stream_320 will read the stream in chunks and compute a
// hash from its contents
hash_stream_320 :: proc(s: io.Stream) -> ([40]byte, bool) {
    _create_ripemd_ctx(40)
    return _hash_impl->hash_stream_40(s)
}

// hash_file_320 will read the file provided by the given handle
// and compute a hash
hash_file_320 :: proc(hd: os.Handle, load_at_once := false) -> ([40]byte, bool) {
    _create_ripemd_ctx(40)
    return _hash_impl->hash_file_40(hd, load_at_once)
}

hash_320 :: proc {
    hash_stream_320,
    hash_file_320,
    hash_bytes_320,
    hash_string_320,
}

hash_bytes_odin_16 :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) -> [16]byte {
    hash: [16]byte
    if c, ok := ctx.internal_ctx.(Ripemd128_Context); ok {
        init_odin(&c)
        update_odin(&c, data)
        final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_16 :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream) -> ([16]byte, bool) {
    hash: [16]byte
    if c, ok := ctx.internal_ctx.(Ripemd128_Context); ok {
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

hash_bytes_odin_20 :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) -> [20]byte {
    hash: [20]byte
    if c, ok := ctx.internal_ctx.(Ripemd160_Context); ok {
        init_odin(&c)
        update_odin(&c, data)
        final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_20 :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream) -> ([20]byte, bool) {
    hash: [20]byte
    if c, ok := ctx.internal_ctx.(Ripemd160_Context); ok {
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

hash_file_odin_20 :: #force_inline proc(ctx: ^_ctx.Hash_Context, hd: os.Handle, load_at_once := false) -> ([20]byte, bool) {
    if !load_at_once {
        return hash_stream_odin_20(ctx, os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_odin_20(ctx, buf[:]), ok
        }
    }
    return [20]byte{}, false
}

hash_bytes_odin_32 :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) -> [32]byte {
    hash: [32]byte
    if c, ok := ctx.internal_ctx.(Ripemd256_Context); ok {
        init_odin(&c)
        update_odin(&c, data)
        final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_32 :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream) -> ([32]byte, bool) {
    hash: [32]byte
    if c, ok := ctx.internal_ctx.(Ripemd256_Context); ok {
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

hash_bytes_odin_40 :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) -> [40]byte {
    hash: [40]byte
    if c, ok := ctx.internal_ctx.(Ripemd320_Context); ok {
        init_odin(&c)
        update_odin(&c, data)
        final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_40 :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream) -> ([40]byte, bool) {
    hash: [40]byte
    if c, ok := ctx.internal_ctx.(Ripemd320_Context); ok {
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

hash_file_odin_40 :: #force_inline proc(ctx: ^_ctx.Hash_Context, hd: os.Handle, load_at_once := false) -> ([40]byte, bool) {
    if !load_at_once {
        return hash_stream_odin_40(ctx, os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_odin_40(ctx, buf[:]), ok
        }
    }
    return [40]byte{}, false
}

@(private)
_create_ripemd_ctx :: #force_inline proc(hash_size: int) {
    switch hash_size {
        case 16: 
            ctx: Ripemd128_Context
            _hash_impl.internal_ctx = ctx
            _hash_impl.hash_size    = ._16
        case 20: 
            ctx: Ripemd160_Context
            _hash_impl.internal_ctx = ctx
            _hash_impl.hash_size    = ._20
        case 32: 
            ctx: Ripemd256_Context
            _hash_impl.internal_ctx = ctx
            _hash_impl.hash_size    = ._32
        case 40: 
            ctx: Ripemd320_Context
            _hash_impl.internal_ctx = ctx
            _hash_impl.hash_size    = ._40
    }
}

@(private)
_init_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context) {
    #partial switch ctx.hash_size {
        case ._16: 
            _create_ripemd_ctx(16)
            if c, ok := ctx.internal_ctx.(Ripemd128_Context); ok {
                init_odin(&c)
            }
        case ._20: 
            _create_ripemd_ctx(20)
            if c, ok := ctx.internal_ctx.(Ripemd160_Context); ok {
                init_odin(&c)
            }
        case ._32: 
            _create_ripemd_ctx(32)
            if c, ok := ctx.internal_ctx.(Ripemd256_Context); ok {
                init_odin(&c)
            }
        case ._40: 
            _create_ripemd_ctx(40)
            if c, ok := ctx.internal_ctx.(Ripemd320_Context); ok {
                init_odin(&c)
            }
    }
}

@(private)
_update_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) {
    #partial switch ctx.hash_size {
        case ._16: 
            if c, ok := ctx.internal_ctx.(Ripemd128_Context); ok {
                update_odin(&c, data)
            }
        case ._20: 
            if c, ok := ctx.internal_ctx.(Ripemd160_Context); ok {
                update_odin(&c, data)
            }
        case ._32: 
            if c, ok := ctx.internal_ctx.(Ripemd256_Context); ok {
                update_odin(&c, data)
            }
        case ._40: 
            if c, ok := ctx.internal_ctx.(Ripemd320_Context); ok {
                update_odin(&c, data)
            }
    }
}

@(private)
_final_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, hash: []byte) {
    #partial switch ctx.hash_size {
        case ._16: 
            if c, ok := ctx.internal_ctx.(Ripemd128_Context); ok {
                final_odin(&c, hash)
            }
        case ._20: 
            if c, ok := ctx.internal_ctx.(Ripemd160_Context); ok {
                final_odin(&c, hash)
            }
        case ._32: 
            if c, ok := ctx.internal_ctx.(Ripemd256_Context); ok {
                final_odin(&c, hash)
            }
        case ._40: 
            if c, ok := ctx.internal_ctx.(Ripemd320_Context); ok {
                final_odin(&c, hash)
            }
    }
}

/*
    RIPEMD implementation
*/

Ripemd128_Context :: struct {
	s:  [4]u32,
	x:  [RIPEMD_128_BLOCK_SIZE]byte,
	nx: int,
	tc: u64,
}

Ripemd160_Context :: struct {
	s:  [5]u32,
	x:  [RIPEMD_160_BLOCK_SIZE]byte,
	nx: int,
	tc: u64,
}

Ripemd256_Context :: struct {
	s:  [8]u32,
	x:  [RIPEMD_256_BLOCK_SIZE]byte,
	nx: int,
	tc: u64,
}

Ripemd320_Context :: struct {
	s:  [10]u32,
	x:  [RIPEMD_320_BLOCK_SIZE]byte,
	nx: int,
	tc: u64,
}

RIPEMD_128_SIZE       :: 16
RIPEMD_128_BLOCK_SIZE :: 64
RIPEMD_160_SIZE       :: 20
RIPEMD_160_BLOCK_SIZE :: 64
RIPEMD_256_SIZE       :: 32
RIPEMD_256_BLOCK_SIZE :: 64
RIPEMD_320_SIZE       :: 40
RIPEMD_320_BLOCK_SIZE :: 64

S0 :: 0x67452301
S1 :: 0xefcdab89
S2 :: 0x98badcfe
S3 :: 0x10325476
S4 :: 0xc3d2e1f0
S5 :: 0x76543210
S6 :: 0xfedcba98
S7 :: 0x89abcdef
S8 :: 0x01234567
S9 :: 0x3c2d1e0f

RIPEMD_128_N0 := [64]uint {
	0, 1,  2,  3,  4,  5,  6,  7, 8,  9, 10, 11, 12, 13, 14, 15,
	7, 4,  13, 1,  10, 6,  15, 3, 12, 0, 9,  5,  2,  14, 11, 8,
	3, 10, 14, 4,  9,  15, 8,  1, 2,  7, 0,  6,  13, 11, 5,  12,
	1, 9,  11, 10, 0,  8,  12, 4, 13, 3, 7,  15, 14, 5,  6,  2,
}

RIPEMD_128_R0 := [64]uint {
	11, 14, 15, 12, 5,  8,  7,  9,  11, 13, 14, 15, 6,  7,  9,  8,
	7,  6,  8,  13, 11, 9,  7,  15, 7,  12, 15, 9,  11, 7,  13, 12,
	11, 13, 6,  7,  14, 9,  13, 15, 14, 8,  13, 6,  5,  12, 7,  5,
	11, 12, 14, 15, 14, 15, 9,  8,  9,  14, 5,  6,  8,  6,  5,  12,
}

RIPEMD_128_N1 := [64]uint {
	5, 14, 7, 0, 9, 2, 11, 4, 13, 6, 15, 8, 1, 10, 3, 12,
	6, 11, 3, 7, 0, 13, 5, 10, 14, 15, 8, 12, 4, 9, 1, 2,
	15, 5, 1, 3, 7, 14, 6, 9, 11, 8, 12, 2, 10, 0, 4, 13,
	8, 6, 4, 1, 3, 11, 15, 0, 5, 12, 2, 13, 9, 7, 10, 14,
}

RIPEMD_128_R1 := [64]uint {
	8, 9, 9, 11, 13, 15, 15, 5, 7, 7, 8, 11, 14, 14, 12, 6,
	9, 13, 15, 7, 12, 8, 9, 11, 7, 7, 12, 7, 6, 15, 13, 11,
	9, 7, 15, 11, 8, 6, 6, 14, 12, 13, 5, 14, 13, 13, 7, 5,
	15, 5, 8, 11, 14, 14, 6, 14, 6, 9, 12, 9, 12, 5, 15, 8,
}

RIPEMD_160_N0 := [80]uint {
	0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
	7, 4, 13, 1, 10, 6, 15, 3, 12, 0, 9, 5, 2, 14, 11, 8,
	3, 10, 14, 4, 9, 15, 8, 1, 2, 7, 0, 6, 13, 11, 5, 12,
	1, 9, 11, 10, 0, 8, 12, 4, 13, 3, 7, 15, 14, 5, 6, 2,
	4, 0, 5, 9, 7, 12, 2, 10, 14, 1, 3, 8, 11, 6, 15, 13,
}

RIPEMD_160_R0 := [80]uint {
	11, 14, 15, 12, 5, 8, 7, 9, 11, 13, 14, 15, 6, 7, 9, 8,
	7, 6, 8, 13, 11, 9, 7, 15, 7, 12, 15, 9, 11, 7, 13, 12,
	11, 13, 6, 7, 14, 9, 13, 15, 14, 8, 13, 6, 5, 12, 7, 5,
	11, 12, 14, 15, 14, 15, 9, 8, 9, 14, 5, 6, 8, 6, 5, 12,
	9, 15, 5, 11, 6, 8, 13, 12, 5, 12, 13, 14, 11, 8, 5, 6,
}

RIPEMD_160_N1 := [80]uint {
	5, 14, 7, 0, 9, 2, 11, 4, 13, 6, 15, 8, 1, 10, 3, 12,
	6, 11, 3, 7, 0, 13, 5, 10, 14, 15, 8, 12, 4, 9, 1, 2,
	15, 5, 1, 3, 7, 14, 6, 9, 11, 8, 12, 2, 10, 0, 4, 13,
	8, 6, 4, 1, 3, 11, 15, 0, 5, 12, 2, 13, 9, 7, 10, 14,
	12, 15, 10, 4, 1, 5, 8, 7, 6, 2, 13, 14, 0, 3, 9, 11,
}

RIPEMD_160_R1 := [80]uint {
	8, 9, 9, 11, 13, 15, 15, 5, 7, 7, 8, 11, 14, 14, 12, 6,
	9, 13, 15, 7, 12, 8, 9, 11, 7, 7, 12, 7, 6, 15, 13, 11,
	9, 7, 15, 11, 8, 6, 6, 14, 12, 13, 5, 14, 13, 13, 7, 5,
	15, 5, 8, 11, 14, 14, 6, 14, 6, 9, 12, 9, 12, 5, 15, 8,
	8, 5, 12, 9, 12, 5, 14, 6, 8, 13, 6, 5, 15, 13, 11, 11,
}

init_odin :: proc(ctx: ^$T) {
    when T == Ripemd128_Context {
        ctx.s[0], ctx.s[1], ctx.s[2], ctx.s[3] = S0, S1, S2, S3
    } else when T == Ripemd160_Context {
        ctx.s[0], ctx.s[1], ctx.s[2], ctx.s[3], ctx.s[4] = S0, S1, S2, S3, S4
    } else when T == Ripemd256_Context {
        ctx.s[0], ctx.s[1], ctx.s[2], ctx.s[3] = S0, S1, S2, S3
        ctx.s[4], ctx.s[5], ctx.s[6], ctx.s[7] = S5, S6, S7, S8
    } else when T == Ripemd320_Context {
        ctx.s[0], ctx.s[1], ctx.s[2], ctx.s[3], ctx.s[4] = S0, S1, S2, S3, S4
        ctx.s[5], ctx.s[6], ctx.s[7], ctx.s[8], ctx.s[9] = S5, S6, S7, S8, S9
    }
}

block :: #force_inline proc (ctx: ^$T, p: []byte) -> int {
    when T == Ripemd128_Context {
    	return ripemd_128_block(ctx, p)
    }
    else when T == Ripemd160_Context {
    	return ripemd_160_block(ctx, p)
    }
    else when T == Ripemd256_Context {
    	return ripemd_256_block(ctx, p)
    }
    else when T == Ripemd320_Context {
    	return ripemd_320_block(ctx, p)
    }
}

ripemd_128_block :: proc(ctx: ^$T, p: []byte) -> int {
	n := 0
	x: [16]u32 = ---
	alpha: u32 = ---
	p := p
	for len(p) >= RIPEMD_128_BLOCK_SIZE {
		a, b, c, d := ctx.s[0], ctx.s[1], ctx.s[2], ctx.s[3]
		aa, bb, cc, dd := a, b, c, d
		for i,j := 0, 0; i < 16; i, j = i+1, j+4 {
			x[i] = u32(p[j]) | u32(p[j+1])<<8 | u32(p[j+2])<<16 | u32(p[j+3])<<24
		}
		i := 0
		for i < 16 {
			alpha = a + (b ~ c ~ d) + x[RIPEMD_128_N0[i]]
			s := int(RIPEMD_128_R0[i])
			alpha = util.ROTL32(alpha, s)
			a, b, c, d = d, alpha, b, c
			alpha = aa + (bb & dd | cc &~ dd) + x[RIPEMD_128_N1[i]] + 0x50a28be6
			s = int(RIPEMD_128_R1[i])
			alpha = util.ROTL32(alpha, s)
			aa, bb, cc, dd= dd, alpha, bb, cc
			i += 1
		}
		for i < 32 {
			alpha = a + (d ~ (b & (c~d))) + x[RIPEMD_128_N0[i]] + 0x5a827999
			s := int(RIPEMD_128_R0[i])
			alpha = util.ROTL32(alpha, s)
			a, b, c, d = d, alpha, b, c
			alpha = aa + (dd ~ (bb | ~cc)) + x[RIPEMD_128_N1[i]] + 0x5c4dd124
			s = int(RIPEMD_128_R1[i])
			alpha = util.ROTL32(alpha, s)
			aa, bb, cc, dd = dd, alpha, bb, cc
			i += 1
		}
		for i < 48 {
			alpha = a + (d ~ (b | ~c)) + x[RIPEMD_128_N0[i]] + 0x6ed9eba1
			s := int(RIPEMD_128_R0[i])
			alpha = util.ROTL32(alpha, s)
			a, b, c, d = d, alpha, b, c
			alpha = aa + (dd ~ (bb & (cc~dd))) + x[RIPEMD_128_N1[i]] + 0x6d703ef3
			s = int(RIPEMD_128_R1[i])
			alpha = util.ROTL32(alpha, s)
			aa, bb, cc, dd = dd, alpha, bb, cc
			i += 1
		}
		for i < 64 {
			alpha = a + (c ~ (d & (b~c))) + x[RIPEMD_128_N0[i]] + 0x8f1bbcdc
			s := int(RIPEMD_128_R0[i])
			alpha = util.ROTL32(alpha, s)
			a, b, c, d = d, alpha, b, c
			alpha = aa + (bb ~ cc ~ dd) + x[RIPEMD_128_N1[i]]
			s = int(RIPEMD_128_R1[i])
			alpha = util.ROTL32(alpha, s)
			aa, bb, cc, dd = dd, alpha, bb, cc
			i += 1
		}
		c = ctx.s[1] + c + dd
		ctx.s[1] = ctx.s[2] + d + aa
		ctx.s[2] = ctx.s[3] + a + bb
		ctx.s[3] = ctx.s[0] + b + cc
		ctx.s[0] = c
		p = p[RIPEMD_128_BLOCK_SIZE:]
		n += RIPEMD_128_BLOCK_SIZE
	}
	return n
}

ripemd_160_block :: proc(ctx: ^$T, p: []byte) -> int {
    n := 0
	x: [16]u32 = ---
	alpha, beta: u32 = ---, ---
	p := p
	for len(p) >= RIPEMD_160_BLOCK_SIZE {
		a, b, c, d, e := ctx.s[0], ctx.s[1], ctx.s[2], ctx.s[3], ctx.s[4]
		aa, bb, cc, dd, ee := a, b, c, d, e
		for i,j := 0, 0; i < 16; i, j = i+1, j+4 {
			x[i] = u32(p[j]) | u32(p[j+1])<<8 | u32(p[j+2])<<16 | u32(p[j+3])<<24
		}
		i := 0
		for i < 16 {
			alpha = a + (b ~ c ~ d) + x[RIPEMD_160_N0[i]]
			s := int(RIPEMD_160_R0[i])
			alpha = util.ROTL32(alpha, s) + e
			beta = util.ROTL32(c, 10)
			a, b, c, d, e = e, alpha, b, beta, d
			alpha = aa + (bb ~ (cc | ~dd)) + x[RIPEMD_160_N1[i]] + 0x50a28be6
			s = int(RIPEMD_160_R1[i])
			alpha = util.ROTL32(alpha, s) + ee
			beta = util.ROTL32(cc, 10)
			aa, bb, cc, dd, ee = ee, alpha, bb, beta, dd
			i += 1
		}
		for i < 32 {
			alpha = a + (b&c | ~b&d) + x[RIPEMD_160_N0[i]] + 0x5a827999
			s := int(RIPEMD_160_R0[i])
			alpha = util.ROTL32(alpha, s) + e
			beta = util.ROTL32(c, 10)
			a, b, c, d, e = e, alpha, b, beta, d
			alpha = aa + (bb&dd | cc&~dd) + x[RIPEMD_160_N1[i]] + 0x5c4dd124
			s = int(RIPEMD_160_R1[i])
			alpha = util.ROTL32(alpha, s) + ee
			beta = util.ROTL32(cc, 10)
			aa, bb, cc, dd, ee = ee, alpha, bb, beta, dd
			i += 1
		}
		for i < 48 {
			alpha = a + (b | ~c ~ d) + x[RIPEMD_160_N0[i]] + 0x6ed9eba1
			s := int(RIPEMD_160_R0[i])
			alpha = util.ROTL32(alpha, s) + e
			beta = util.ROTL32(c, 10)
			a, b, c, d, e = e, alpha, b, beta, d
			alpha = aa + (bb | ~cc ~ dd) + x[RIPEMD_160_N1[i]] + 0x6d703ef3
			s = int(RIPEMD_160_R1[i])
			alpha = util.ROTL32(alpha, s) + ee
			beta = util.ROTL32(cc, 10)
			aa, bb, cc, dd, ee = ee, alpha, bb, beta, dd
			i += 1
		}
		for i < 64 {
			alpha = a + (b&d | c&~d) + x[RIPEMD_160_N0[i]] + 0x8f1bbcdc
			s := int(RIPEMD_160_R0[i])
			alpha = util.ROTL32(alpha, s) + e
			beta = util.ROTL32(c, 10)
			a, b, c, d, e = e, alpha, b, beta, d
			alpha = aa + (bb&cc | ~bb&dd) + x[RIPEMD_160_N1[i]] + 0x7a6d76e9
			s = int(RIPEMD_160_R1[i])
			alpha = util.ROTL32(alpha, s) + ee
			beta = util.ROTL32(cc, 10)
			aa, bb, cc, dd, ee = ee, alpha, bb, beta, dd
			i += 1
		}
		for i < 80 {
			alpha = a + (b ~ (c | ~d)) + x[RIPEMD_160_N0[i]] + 0xa953fd4e
			s := int(RIPEMD_160_R0[i])
			alpha = util.ROTL32(alpha, s) + e
			beta = util.ROTL32(c, 10)
			a, b, c, d, e = e, alpha, b, beta, d
			alpha = aa + (bb ~ cc ~ dd) + x[RIPEMD_160_N1[i]]
			s = int(RIPEMD_160_R1[i])
			alpha = util.ROTL32(alpha, s) + ee
			beta = util.ROTL32(cc, 10)
			aa, bb, cc, dd, ee = ee, alpha, bb, beta, dd
			i += 1
		}
		dd += c + ctx.s[1]
		ctx.s[1] = ctx.s[2] + d + ee
		ctx.s[2] = ctx.s[3] + e + aa
		ctx.s[3] = ctx.s[4] + a + bb
		ctx.s[4] = ctx.s[0] + b + cc
		ctx.s[0] = dd
		p = p[RIPEMD_160_BLOCK_SIZE:]
		n += RIPEMD_160_BLOCK_SIZE
	}
	return n
}

ripemd_256_block :: proc(ctx: ^$T, p: []byte) -> int {
	n := 0
	x: [16]u32 = ---
	alpha: u32 = ---
	p := p
	for len(p) >= RIPEMD_256_BLOCK_SIZE {
		a, b, c, d := ctx.s[0], ctx.s[1], ctx.s[2], ctx.s[3]
		aa, bb, cc, dd := ctx.s[4], ctx.s[5], ctx.s[6], ctx.s[7]
		for i,j := 0, 0; i < 16; i, j = i+1, j+4 {
			x[i] = u32(p[j]) | u32(p[j+1])<<8 | u32(p[j+2])<<16 | u32(p[j+3])<<24
		}
		i := 0
		for i < 16 {
			alpha = a + (b ~ c ~ d) + x[RIPEMD_128_N0[i]]
			s := int(RIPEMD_128_R0[i])
			alpha = util.ROTL32(alpha, s)
			a, b, c, d = d, alpha, b, c
			alpha = aa + (bb & dd | cc &~ dd) + x[RIPEMD_128_N1[i]] + 0x50a28be6
			s = int(RIPEMD_128_R1[i])
			alpha = util.ROTL32(alpha, s)
			aa, bb, cc, dd= dd, alpha, bb, cc
			i += 1
		}
		t := a
		a = aa
		aa = t
		for i < 32 {
			alpha = a + (d ~ (b & (c~d))) + x[RIPEMD_128_N0[i]] + 0x5a827999
			s := int(RIPEMD_128_R0[i])
			alpha = util.ROTL32(alpha, s)
			a, b, c, d = d, alpha, b, c
			alpha = aa + (dd ~ (bb | ~cc)) + x[RIPEMD_128_N1[i]] + 0x5c4dd124
			s = int(RIPEMD_128_R1[i])
			alpha = util.ROTL32(alpha, s)
			aa, bb, cc, dd = dd, alpha, bb, cc
			i += 1
		}
		t = b
		b = bb
		bb = t
		for i < 48 {
			alpha = a + (d ~ (b | ~c)) + x[RIPEMD_128_N0[i]] + 0x6ed9eba1
			s := int(RIPEMD_128_R0[i])
			alpha = util.ROTL32(alpha, s)
			a, b, c, d = d, alpha, b, c
			alpha = aa + (dd ~ (bb & (cc~dd))) + x[RIPEMD_128_N1[i]] + 0x6d703ef3
			s = int(RIPEMD_128_R1[i])
			alpha = util.ROTL32(alpha, s)
			aa, bb, cc, dd = dd, alpha, bb, cc
			i += 1
		}
		t = c
		c = cc
		cc = t
		for i < 64 {
			alpha = a + (c ~ (d & (b~c))) + x[RIPEMD_128_N0[i]] + 0x8f1bbcdc
			s := int(RIPEMD_128_R0[i])
			alpha = util.ROTL32(alpha, s)
			a, b, c, d = d, alpha, b, c
			alpha = aa + (bb ~ cc ~ dd) + x[RIPEMD_128_N1[i]]
			s = int(RIPEMD_128_R1[i])
			alpha = util.ROTL32(alpha, s)
			aa, bb, cc, dd = dd, alpha, bb, cc
			i += 1
		}
		t = d
		d = dd
		dd = t
		ctx.s[0] += a
		ctx.s[1] += b
		ctx.s[2] += c
		ctx.s[3] += d
		ctx.s[4] += aa
		ctx.s[5] += bb
		ctx.s[6] += cc
		ctx.s[7] += dd
		p = p[RIPEMD_256_BLOCK_SIZE:]
		n += RIPEMD_256_BLOCK_SIZE
	}
	return n
}

ripemd_320_block :: proc(ctx: ^$T, p: []byte) -> int {
    n := 0
	x: [16]u32 = ---
	alpha, beta: u32 = ---, ---
	p := p
	for len(p) >= RIPEMD_320_BLOCK_SIZE {
		a, b, c, d, e := ctx.s[0], ctx.s[1], ctx.s[2], ctx.s[3], ctx.s[4]
		aa, bb, cc, dd, ee := ctx.s[5], ctx.s[6], ctx.s[7], ctx.s[8], ctx.s[9]
		for i,j := 0, 0; i < 16; i, j = i+1, j+4 {
			x[i] = u32(p[j]) | u32(p[j+1])<<8 | u32(p[j+2])<<16 | u32(p[j+3])<<24
		}
		i := 0
		for i < 16 {
			alpha = a + (b ~ c ~ d) + x[RIPEMD_160_N0[i]]
			s := int(RIPEMD_160_R0[i])
			alpha = util.ROTL32(alpha, s) + e
			beta = util.ROTL32(c, 10)
			a, b, c, d, e = e, alpha, b, beta, d
			alpha = aa + (bb ~ (cc | ~dd)) + x[RIPEMD_160_N1[i]] + 0x50a28be6
			s = int(RIPEMD_160_R1[i])
			alpha = util.ROTL32(alpha, s) + ee
			beta = util.ROTL32(cc, 10)
			aa, bb, cc, dd, ee = ee, alpha, bb, beta, dd
			i += 1
		}
		t := b
		b = bb
		bb = t
		for i < 32 {
			alpha = a + (b&c | ~b&d) + x[RIPEMD_160_N0[i]] + 0x5a827999
			s := int(RIPEMD_160_R0[i])
			alpha = util.ROTL32(alpha, s) + e
			beta = util.ROTL32(c, 10)
			a, b, c, d, e = e, alpha, b, beta, d
			alpha = aa + (bb&dd | cc&~dd) + x[RIPEMD_160_N1[i]] + 0x5c4dd124
			s = int(RIPEMD_160_R1[i])
			alpha = util.ROTL32(alpha, s) + ee
			beta = util.ROTL32(cc, 10)
			aa, bb, cc, dd, ee = ee, alpha, bb, beta, dd
			i += 1
		}
		t = d
		d = dd
		dd = t
		for i < 48 {
			alpha = a + (b | ~c ~ d) + x[RIPEMD_160_N0[i]] + 0x6ed9eba1
			s := int(RIPEMD_160_R0[i])
			alpha = util.ROTL32(alpha, s) + e
			beta = util.ROTL32(c, 10)
			a, b, c, d, e = e, alpha, b, beta, d
			alpha = aa + (bb | ~cc ~ dd) + x[RIPEMD_160_N1[i]] + 0x6d703ef3
			s = int(RIPEMD_160_R1[i])
			alpha = util.ROTL32(alpha, s) + ee
			beta = util.ROTL32(cc, 10)
			aa, bb, cc, dd, ee = ee, alpha, bb, beta, dd
			i += 1
		}
		t = a
		a = aa
		aa = t
		for i < 64 {
			alpha = a + (b&d | c&~d) + x[RIPEMD_160_N0[i]] + 0x8f1bbcdc
			s := int(RIPEMD_160_R0[i])
			alpha = util.ROTL32(alpha, s) + e
			beta = util.ROTL32(c, 10)
			a, b, c, d, e = e, alpha, b, beta, d
			alpha = aa + (bb&cc | ~bb&dd) + x[RIPEMD_160_N1[i]] + 0x7a6d76e9
			s = int(RIPEMD_160_R1[i])
			alpha = util.ROTL32(alpha, s) + ee
			beta = util.ROTL32(cc, 10)
			aa, bb, cc, dd, ee = ee, alpha, bb, beta, dd
			i += 1
		}
		t = c
		c = cc
		cc = t
		for i < 80 {
			alpha = a + (b ~ (c | ~d)) + x[RIPEMD_160_N0[i]] + 0xa953fd4e
			s := int(RIPEMD_160_R0[i])
			alpha = util.ROTL32(alpha, s) + e
			beta = util.ROTL32(c, 10)
			a, b, c, d, e = e, alpha, b, beta, d
			alpha = aa + (bb ~ cc ~ dd) + x[RIPEMD_160_N1[i]]
			s = int(RIPEMD_160_R1[i])
			alpha = util.ROTL32(alpha, s) + ee
			beta = util.ROTL32(cc, 10)
			aa, bb, cc, dd, ee = ee, alpha, bb, beta, dd
			i += 1
		}
		t = e
		e = ee
		ee = t
		ctx.s[0] += a
		ctx.s[1] += b
		ctx.s[2] += c
		ctx.s[3] += d
		ctx.s[4] += e
		ctx.s[5] += aa
		ctx.s[6] += bb
		ctx.s[7] += cc
		ctx.s[8] += dd
		ctx.s[9] += ee
		p = p[RIPEMD_320_BLOCK_SIZE:]
		n += RIPEMD_320_BLOCK_SIZE
	}
	return n
}

update_odin :: proc(ctx: ^$T, p: []byte) {
    ctx.tc += u64(len(p))
	p := p
	if ctx.nx > 0 {
		n := len(p)

        when T == Ripemd128_Context {
            if n > RIPEMD_128_BLOCK_SIZE - ctx.nx {
			    n = RIPEMD_128_BLOCK_SIZE - ctx.nx
		    }
        } else when T == Ripemd160_Context {
            if n > RIPEMD_160_BLOCK_SIZE - ctx.nx {
			    n = RIPEMD_160_BLOCK_SIZE - ctx.nx
		    }
        } else when T == Ripemd256_Context{
            if n > RIPEMD_256_BLOCK_SIZE - ctx.nx {
			    n = RIPEMD_256_BLOCK_SIZE - ctx.nx
		    }
        } else when T == Ripemd320_Context{
            if n > RIPEMD_320_BLOCK_SIZE - ctx.nx {
			    n = RIPEMD_320_BLOCK_SIZE - ctx.nx
		    }
        }

		for i := 0; i < n; i += 1 {
			ctx.x[ctx.nx + i] = p[i]
		}

		ctx.nx += n
        when T == Ripemd128_Context {
            if ctx.nx == RIPEMD_128_BLOCK_SIZE {
                block(ctx, ctx.x[0:])
                ctx.nx = 0
            }
        } else when T == Ripemd160_Context {
            if ctx.nx == RIPEMD_160_BLOCK_SIZE {
                block(ctx, ctx.x[0:])
                ctx.nx = 0
            }
        } else when T == Ripemd256_Context{
            if ctx.nx == RIPEMD_256_BLOCK_SIZE {
                block(ctx, ctx.x[0:])
                ctx.nx = 0
            }
        } else when T == Ripemd320_Context{
            if ctx.nx == RIPEMD_320_BLOCK_SIZE {
                block(ctx, ctx.x[0:])
                ctx.nx = 0
            }
        }
		p = p[n:]
	}
    n := block(ctx, p)
	p = p[n:]
	if len(p) > 0 {
		ctx.nx = copy(ctx.x[:], p)
	}
}

final_odin :: proc(ctx: ^$T, hash: []byte) {
	d := ctx
    tc := d.tc
    tmp: [64]byte
    tmp[0] = 0x80

    if tc % 64 < 56 {
        update_odin(d, tmp[0:56 - tc % 64])
    } else {
        update_odin(d, tmp[0:64 + 56 - tc % 64])
    }

    tc <<= 3
    for i : u32 = 0; i < 8; i += 1 {
        tmp[i] = byte(tc >> (8 * i))
    }

    update_odin(d, tmp[0:8])

    when T == Ripemd128_Context {
        size :: RIPEMD_128_SIZE
    } else when T == Ripemd160_Context {
        size :: RIPEMD_160_SIZE
    } else when T == Ripemd256_Context{
        size :: RIPEMD_256_SIZE
    } else when T == Ripemd320_Context{
        size :: RIPEMD_320_SIZE
    }

    digest: [size]byte
    for s, i in d.s {
		digest[i * 4] 	  = byte(s)
		digest[i * 4 + 1] = byte(s >> 8)
		digest[i * 4 + 2] = byte(s >> 16)
		digest[i * 4 + 3] = byte(s >> 24)
	}
    copy(hash[:], digest[:])
}
