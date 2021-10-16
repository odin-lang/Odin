package sha2

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
        Jeroen van Rijn: Context design to be able to change from Odin implementation to bindings.

    Implementation of the SHA2 hashing algorithm, as defined in <https://csrc.nist.gov/csrc/media/publications/fips/180/2/archive/2002-08-01/documents/fips180-2.pdf>
    and in RFC 3874 <https://datatracker.ietf.org/doc/html/rfc3874>
*/

import "core:mem"
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
    botan.assign_hash_vtable(_hash_impl, botan.HASH_SHA2)
}

// use_odin assigns the internal vtable of the hash context to use the Odin implementation
use_odin :: #force_inline proc() {
    _assign_hash_vtable(_hash_impl)
}

@(private)
_create_sha256_ctx :: #force_inline proc(is224: bool) {
	ctx: Sha256_Context
	ctx.is224 = is224
	_hash_impl.internal_ctx = ctx
	_hash_impl.hash_size    = is224 ? ._28 : ._32
}

@(private)
_create_sha512_ctx :: #force_inline proc(is384: bool) {
	ctx: Sha512_Context
	ctx.is384 = is384
	_hash_impl.internal_ctx = ctx
	_hash_impl.hash_size    = is384 ? ._48 : ._64
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
	_create_sha256_ctx(true)
    return _hash_impl->hash_bytes_28(data)
}

// hash_stream_224 will read the stream in chunks and compute a
// hash from its contents
hash_stream_224 :: proc(s: io.Stream) -> ([28]byte, bool) {
	_create_sha256_ctx(true)
    return _hash_impl->hash_stream_28(s)
}

// hash_file_224 will read the file provided by the given handle
// and compute a hash
hash_file_224 :: proc(hd: os.Handle, load_at_once := false) -> ([28]byte, bool) {
	_create_sha256_ctx(true)
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
	_create_sha256_ctx(false)
    return _hash_impl->hash_bytes_32(data)
}

// hash_stream_256 will read the stream in chunks and compute a
// hash from its contents
hash_stream_256 :: proc(s: io.Stream) -> ([32]byte, bool) {
	_create_sha256_ctx(false)
    return _hash_impl->hash_stream_32(s)
}

// hash_file_256 will read the file provided by the given handle
// and compute a hash
hash_file_256 :: proc(hd: os.Handle, load_at_once := false) -> ([32]byte, bool) {
	_create_sha256_ctx(false)
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
	_create_sha512_ctx(true)
    return _hash_impl->hash_bytes_48(data)
}

// hash_stream_384 will read the stream in chunks and compute a
// hash from its contents
hash_stream_384 :: proc(s: io.Stream) -> ([48]byte, bool) {
	_create_sha512_ctx(true)
    return _hash_impl->hash_stream_48(s)
}

// hash_file_384 will read the file provided by the given handle
// and compute a hash
hash_file_384 :: proc(hd: os.Handle, load_at_once := false) -> ([48]byte, bool) {
	_create_sha512_ctx(true)
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
	_create_sha512_ctx(false)
    return _hash_impl->hash_bytes_64(data)
}

// hash_stream_512 will read the stream in chunks and compute a
// hash from its contents
hash_stream_512 :: proc(s: io.Stream) -> ([64]byte, bool) {
	_create_sha512_ctx(false)
    return _hash_impl->hash_stream_64(s)
}

// hash_file_512 will read the file provided by the given handle
// and compute a hash
hash_file_512 :: proc(hd: os.Handle, load_at_once := false) -> ([64]byte, bool) {
	_create_sha512_ctx(false)
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
    if c, ok := ctx.internal_ctx.(Sha256_Context); ok {
        init_odin(&c)
        update_odin(&c, data)
        final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_28 :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream) -> ([28]byte, bool) {
    hash: [28]byte
    if c, ok := ctx.internal_ctx.(Sha256_Context); ok {
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
    if c, ok := ctx.internal_ctx.(Sha256_Context); ok {
        init_odin(&c)
        update_odin(&c, data)
        final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_32 :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream) -> ([32]byte, bool) {
    hash: [32]byte
    if c, ok := ctx.internal_ctx.(Sha256_Context); ok {
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
    if c, ok := ctx.internal_ctx.(Sha512_Context); ok {
        init_odin(&c)
        update_odin(&c, data)
        final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_48 :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream) -> ([48]byte, bool) {
    hash: [48]byte
    if c, ok := ctx.internal_ctx.(Sha512_Context); ok {
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
    if c, ok := ctx.internal_ctx.(Sha512_Context); ok {
        init_odin(&c)
        update_odin(&c, data)
        final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin_64 :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream) -> ([64]byte, bool) {
    hash: [64]byte
    if c, ok := ctx.internal_ctx.(Sha512_Context); ok {
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
    if ctx.hash_size == ._28 || ctx.hash_size == ._32 {
        _create_sha256_ctx(ctx.hash_size == ._28)
        if c, ok := ctx.internal_ctx.(Sha256_Context); ok {
            init_odin(&c)
        }
        return
    }
    if ctx.hash_size == ._48 || ctx.hash_size == ._64 {
        _create_sha512_ctx(ctx.hash_size == ._48)
        if c, ok := ctx.internal_ctx.(Sha512_Context); ok {
            init_odin(&c)
        }
    }
}

@(private)
_update_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) {
    #partial switch ctx.hash_size {
        case ._28, ._32:
            if c, ok := ctx.internal_ctx.(Sha256_Context); ok {
                update_odin(&c, data)
            }
        case ._48, ._64:
            if c, ok := ctx.internal_ctx.(Sha512_Context); ok {
                update_odin(&c, data)
            }
    }
}

@(private)
_final_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, hash: []byte) {
    #partial switch ctx.hash_size {
        case ._28, ._32:
            if c, ok := ctx.internal_ctx.(Sha256_Context); ok {
                final_odin(&c, hash)
            }
        case ._48, ._64:
            if c, ok := ctx.internal_ctx.(Sha512_Context); ok {
                final_odin(&c, hash)
            }
    }
}

/*
    SHA2 implementation
*/

SHA256_BLOCK_SIZE :: 64
SHA512_BLOCK_SIZE :: 128

Sha256_Context :: struct {
    tot_len: uint,
    length:  uint,
    block:   [128]byte,
    h:       [8]u32,
    is224:   bool,
}

Sha512_Context :: struct {
    tot_len: uint,
    length:  uint,
    block:   [256]byte,
    h:       [8]u64,
    is384:   bool,
}

sha256_k := [64]u32 {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}

sha512_k := [80]u64 {
    0x428a2f98d728ae22, 0x7137449123ef65cd,
    0xb5c0fbcfec4d3b2f, 0xe9b5dba58189dbbc,
    0x3956c25bf348b538, 0x59f111f1b605d019,
    0x923f82a4af194f9b, 0xab1c5ed5da6d8118,
    0xd807aa98a3030242, 0x12835b0145706fbe,
    0x243185be4ee4b28c, 0x550c7dc3d5ffb4e2,
    0x72be5d74f27b896f, 0x80deb1fe3b1696b1,
    0x9bdc06a725c71235, 0xc19bf174cf692694,
    0xe49b69c19ef14ad2, 0xefbe4786384f25e3,
    0x0fc19dc68b8cd5b5, 0x240ca1cc77ac9c65,
    0x2de92c6f592b0275, 0x4a7484aa6ea6e483,
    0x5cb0a9dcbd41fbd4, 0x76f988da831153b5,
    0x983e5152ee66dfab, 0xa831c66d2db43210,
    0xb00327c898fb213f, 0xbf597fc7beef0ee4,
    0xc6e00bf33da88fc2, 0xd5a79147930aa725,
    0x06ca6351e003826f, 0x142929670a0e6e70,
    0x27b70a8546d22ffc, 0x2e1b21385c26c926,
    0x4d2c6dfc5ac42aed, 0x53380d139d95b3df,
    0x650a73548baf63de, 0x766a0abb3c77b2a8,
    0x81c2c92e47edaee6, 0x92722c851482353b,
    0xa2bfe8a14cf10364, 0xa81a664bbc423001,
    0xc24b8b70d0f89791, 0xc76c51a30654be30,
    0xd192e819d6ef5218, 0xd69906245565a910,
    0xf40e35855771202a, 0x106aa07032bbd1b8,
    0x19a4c116b8d2d0c8, 0x1e376c085141ab53,
    0x2748774cdf8eeb99, 0x34b0bcb5e19b48a8,
    0x391c0cb3c5c95a63, 0x4ed8aa4ae3418acb,
    0x5b9cca4f7763e373, 0x682e6ff3d6b2b8a3,
    0x748f82ee5defb2fc, 0x78a5636f43172f60,
    0x84c87814a1f0ab72, 0x8cc702081a6439ec,
    0x90befffa23631e28, 0xa4506cebde82bde9,
    0xbef9a3f7b2c67915, 0xc67178f2e372532b,
    0xca273eceea26619c, 0xd186b8c721c0c207,
    0xeada7dd6cde0eb1e, 0xf57d4f7fee6ed178,
    0x06f067aa72176fba, 0x0a637dc5a2c898a6,
    0x113f9804bef90dae, 0x1b710b35131c471b,
    0x28db77f523047d84, 0x32caab7b40c72493,
    0x3c9ebe0a15c9bebc, 0x431d67c49c100d4c,
    0x4cc5d4becb3e42b6, 0x597f299cfc657e2a,
    0x5fcb6fab3ad6faec, 0x6c44198c4a475817,
}

SHA256_CH :: #force_inline proc "contextless"(x, y, z: u32) -> u32 {
    return (x & y) ~ (~x & z)
}

SHA256_MAJ :: #force_inline proc "contextless"(x, y, z: u32) -> u32 {
    return (x & y) ~ (x & z) ~ (y & z)
}

SHA512_CH :: #force_inline proc "contextless"(x, y, z: u64) -> u64 {
    return (x & y) ~ (~x & z)
}

SHA512_MAJ :: #force_inline proc "contextless"(x, y, z: u64) -> u64 {
    return (x & y) ~ (x & z) ~ (y & z)
}

SHA256_F1 :: #force_inline proc "contextless"(x: u32) -> u32 {
    return util.ROTR32(x, 2) ~ util.ROTR32(x, 13) ~ util.ROTR32(x, 22)
}

SHA256_F2 :: #force_inline proc "contextless"(x: u32) -> u32 {
    return util.ROTR32(x, 6) ~ util.ROTR32(x, 11) ~ util.ROTR32(x, 25)
}

SHA256_F3 :: #force_inline proc "contextless"(x: u32) -> u32 {
    return util.ROTR32(x, 7) ~ util.ROTR32(x, 18) ~ (x >> 3)
}

SHA256_F4 :: #force_inline proc "contextless"(x: u32) -> u32 {
    return util.ROTR32(x, 17) ~ util.ROTR32(x, 19) ~ (x >> 10)
}

SHA512_F1 :: #force_inline proc "contextless"(x: u64) -> u64 {
    return util.ROTR64(x, 28) ~ util.ROTR64(x, 34) ~ util.ROTR64(x, 39)
}

SHA512_F2 :: #force_inline proc "contextless"(x: u64) -> u64 {
    return util.ROTR64(x, 14) ~ util.ROTR64(x, 18) ~ util.ROTR64(x, 41)
}

SHA512_F3 :: #force_inline proc "contextless"(x: u64) -> u64 {
    return util.ROTR64(x, 1) ~ util.ROTR64(x, 8) ~ (x >> 7)
}

SHA512_F4 :: #force_inline proc "contextless"(x: u64) -> u64 {
    return util.ROTR64(x, 19) ~ util.ROTR64(x, 61) ~ (x >> 6)
}

PACK32 :: #force_inline proc "contextless"(b: []byte, x: ^u32) {
	x^ = u32(b[3]) | u32(b[2]) << 8 | u32(b[1]) << 16 | u32(b[0]) << 24
}

PACK64 :: #force_inline proc "contextless"(b: []byte, x: ^u64) {
	x^ = u64(b[7]) | u64(b[6]) << 8 | u64(b[5]) << 16 | u64(b[4]) << 24 | u64(b[3]) << 32 | u64(b[2]) << 40 | u64(b[1]) << 48 | u64(b[0]) << 56
}

init_odin :: proc(ctx: ^$T) {
	when T == Sha256_Context {
		if ctx.is224 {
			ctx.h[0] = 0xc1059ed8
			ctx.h[1] = 0x367cd507
			ctx.h[2] = 0x3070dd17
			ctx.h[3] = 0xf70e5939
			ctx.h[4] = 0xffc00b31
			ctx.h[5] = 0x68581511
			ctx.h[6] = 0x64f98fa7
			ctx.h[7] = 0xbefa4fa4
		} else {
			ctx.h[0] = 0x6a09e667
			ctx.h[1] = 0xbb67ae85
			ctx.h[2] = 0x3c6ef372
			ctx.h[3] = 0xa54ff53a
			ctx.h[4] = 0x510e527f
			ctx.h[5] = 0x9b05688c
			ctx.h[6] = 0x1f83d9ab
			ctx.h[7] = 0x5be0cd19
		}
	} else when T == Sha512_Context {
		if ctx.is384 {
			ctx.h[0] = 0xcbbb9d5dc1059ed8
			ctx.h[1] = 0x629a292a367cd507
			ctx.h[2] = 0x9159015a3070dd17
			ctx.h[3] = 0x152fecd8f70e5939
			ctx.h[4] = 0x67332667ffc00b31
			ctx.h[5] = 0x8eb44a8768581511
			ctx.h[6] = 0xdb0c2e0d64f98fa7
			ctx.h[7] = 0x47b5481dbefa4fa4
		} else {
			ctx.h[0] = 0x6a09e667f3bcc908
			ctx.h[1] = 0xbb67ae8584caa73b
			ctx.h[2] = 0x3c6ef372fe94f82b
			ctx.h[3] = 0xa54ff53a5f1d36f1
			ctx.h[4] = 0x510e527fade682d1
			ctx.h[5] = 0x9b05688c2b3e6c1f
			ctx.h[6] = 0x1f83d9abfb41bd6b
			ctx.h[7] = 0x5be0cd19137e2179
		}
	}
}

sha2_transf :: proc(ctx: ^$T, data: []byte, block_nb: uint) {
	when T == Sha256_Context {
		w: [64]u32
		wv: [8]u32
		t1, t2: u32
	} else when T == Sha512_Context {
		w: [80]u64
		wv: [8]u64
		t1, t2: u64
	}

	sub_block := make([]byte, len(data))
	i, j: i32

	for i = 0; i < i32(block_nb); i += 1 {
		when T == Sha256_Context {
			sub_block = data[i << 6:]
		} else when T == Sha512_Context {
			sub_block = data[i << 7:]
		}

		for j = 0; j < 16; j += 1 {
			when T == Sha256_Context {
				PACK32(sub_block[j << 2:], &w[j])
			} else when T == Sha512_Context {
				PACK64(sub_block[j << 3:], &w[j])
			}
		}

		when T == Sha256_Context {
			for j = 16; j < 64; j += 1 {
				w[j] = SHA256_F4(w[j - 2]) + w[j - 7] + SHA256_F3(w[j - 15]) + w[j - 16]
			}
		} else when T == Sha512_Context {
			for j = 16; j < 80; j += 1 {
				w[j] = SHA512_F4(w[j - 2]) + w[j - 7] + SHA512_F3(w[j - 15]) + w[j - 16]
			}
		}

		for j = 0; j < 8; j += 1 {
			wv[j] = ctx.h[j]
		}

		when T == Sha256_Context {
			for j = 0; j < 64; j += 1 {
				t1 = wv[7] + SHA256_F2(wv[4]) + SHA256_CH(wv[4], wv[5], wv[6]) + sha256_k[j] + w[j]
				t2 = SHA256_F1(wv[0]) + SHA256_MAJ(wv[0], wv[1], wv[2])
				wv[7] = wv[6]
				wv[6] = wv[5]
				wv[5] = wv[4]
				wv[4] = wv[3] + t1
				wv[3] = wv[2]
				wv[2] = wv[1]
				wv[1] = wv[0]
				wv[0] = t1 + t2
			}
		} else when T == Sha512_Context {
			for j = 0; j < 80; j += 1 {
				t1 = wv[7] + SHA512_F2(wv[4]) + SHA512_CH(wv[4], wv[5], wv[6]) + sha512_k[j] + w[j]
				t2 = SHA512_F1(wv[0]) + SHA512_MAJ(wv[0], wv[1], wv[2])
				wv[7] = wv[6]
				wv[6] = wv[5]
				wv[5] = wv[4]
				wv[4] = wv[3] + t1
				wv[3] = wv[2]
				wv[2] = wv[1]
				wv[1] = wv[0]
				wv[0] = t1 + t2
			}
		}

		for j = 0; j < 8; j += 1 {
			ctx.h[j] += wv[j]
		}
	}
}

update_odin :: proc(ctx: ^$T, data: []byte) {
	length := uint(len(data))
	block_nb: uint
	new_len, rem_len, tmp_len: uint
	shifted_message := make([]byte, length)

	when T == Sha256_Context {
        CURR_BLOCK_SIZE :: SHA256_BLOCK_SIZE
    } else when T == Sha512_Context {
        CURR_BLOCK_SIZE :: SHA512_BLOCK_SIZE
    }

	tmp_len = CURR_BLOCK_SIZE - ctx.length
	rem_len = length < tmp_len ? length : tmp_len
	copy(ctx.block[ctx.length:], data[:rem_len])

	if ctx.length + length < CURR_BLOCK_SIZE {
		ctx.length += length
		return
	}

	new_len = length - rem_len
	block_nb = new_len / CURR_BLOCK_SIZE
    shifted_message = data[rem_len:]

	sha2_transf(ctx, ctx.block[:], 1)
	sha2_transf(ctx, shifted_message, block_nb)

	rem_len = new_len % CURR_BLOCK_SIZE
	when T == Sha256_Context 	  {copy(ctx.block[:], shifted_message[block_nb << 6:rem_len])}
	else when T == Sha512_Context {copy(ctx.block[:], shifted_message[block_nb << 7:rem_len])}

	ctx.length = rem_len
	when T == Sha256_Context 	  {ctx.tot_len += (block_nb + 1) << 6}
	else when T == Sha512_Context {ctx.tot_len += (block_nb + 1) << 7}
}

final_odin :: proc(ctx: ^$T, hash: []byte) {
	block_nb, pm_len, len_b: u32
	i: i32

	when T == Sha256_Context 	  {CURR_BLOCK_SIZE :: SHA256_BLOCK_SIZE}
	else when T == Sha512_Context {CURR_BLOCK_SIZE :: SHA512_BLOCK_SIZE}

	when T == Sha256_Context 	  {block_nb = 1 + ((CURR_BLOCK_SIZE - 9)  < (ctx.length % CURR_BLOCK_SIZE) ? 1 : 0)}
	else when T == Sha512_Context {block_nb = 1 + ((CURR_BLOCK_SIZE - 17) < (ctx.length % CURR_BLOCK_SIZE) ? 1 : 0)}

	len_b = u32(ctx.tot_len + ctx.length) << 3
	when T == Sha256_Context 	  {pm_len = block_nb << 6}
	else when T == Sha512_Context {pm_len = block_nb << 7}

	mem.set(rawptr(&(ctx.block[ctx.length:])[0]), 0, int(uint(pm_len) - ctx.length))
    ctx.block[ctx.length] = 0x80

    util.PUT_U32_BE(ctx.block[pm_len - 4:], len_b)

	sha2_transf(ctx, ctx.block[:], uint(block_nb))

	when T == Sha256_Context {
		if ctx.is224 {
			for i = 0; i < 7; i += 1 {util.PUT_U32_BE(hash[i << 2:], ctx.h[i])}
		} else {
			for i = 0; i < 8; i += 1 {util.PUT_U32_BE(hash[i << 2:], ctx.h[i])}
		} 
	} else when T == Sha512_Context {
		if ctx.is384 {
			for i = 0; i < 6; i += 1 {util.PUT_U64_BE(hash[i << 3:], ctx.h[i])}
		} else {
			for i = 0; i < 8; i += 1 {util.PUT_U64_BE(hash[i << 3:], ctx.h[i])}
		} 
	} 
}