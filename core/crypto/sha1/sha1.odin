package sha1

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
        Jeroen van Rijn: Context design to be able to change from Odin implementation to bindings.

    Implementation of the SHA1 hashing algorithm, as defined in RFC 3174 <https://datatracker.ietf.org/doc/html/rfc3174>
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
    ctx.hash_bytes_20  = hash_bytes_odin
    ctx.hash_file_20   = hash_file_odin
    ctx.hash_stream_20 = hash_stream_odin
    ctx.init           = _init_odin
    ctx.update         = _update_odin
    ctx.final          = _final_odin
}

_hash_impl := _init_vtable()

// use_botan assigns the internal vtable of the hash context to use the Botan bindings
use_botan :: #force_inline proc() {
    botan.assign_hash_vtable(_hash_impl, botan.HASH_SHA1)
}

// use_odin assigns the internal vtable of the hash context to use the Odin implementation
use_odin :: #force_inline proc() {
    _assign_hash_vtable(_hash_impl)
}

/*
    High level API
*/

// hash_string will hash the given input and return the
// computed hash
hash_string :: proc(data: string) -> [20]byte {
    return hash_bytes(transmute([]byte)(data))
}

// hash_bytes will hash the given input and return the
// computed hash
hash_bytes :: proc(data: []byte) -> [20]byte {
	_create_sha1_ctx()
    return _hash_impl->hash_bytes_20(data)
}

// hash_stream will read the stream in chunks and compute a
// hash from its contents
hash_stream :: proc(s: io.Stream) -> ([20]byte, bool) {
	_create_sha1_ctx()
    return _hash_impl->hash_stream_20(s)
}

// hash_file will read the file provided by the given handle
// and compute a hash
hash_file :: proc(hd: os.Handle, load_at_once := false) -> ([20]byte, bool) {
	_create_sha1_ctx()
    return _hash_impl->hash_file_20(hd, load_at_once)
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

init :: proc(ctx: ^_ctx.Hash_Context) {
    _hash_impl->init()
}

update :: proc(ctx: ^_ctx.Hash_Context, data: []byte) {
    _hash_impl->update(data)
}

final :: proc(ctx: ^_ctx.Hash_Context, hash: []byte) {
    _hash_impl->final(hash)
}

hash_bytes_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) -> [20]byte {
    hash: [20]byte
    if c, ok := ctx.internal_ctx.(Sha1_Context); ok {
    	init_odin(&c)
    	update_odin(&c, data)
    	final_odin(&c, hash[:])
    }
    return hash
}

hash_stream_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, fs: io.Stream) -> ([20]byte, bool) {
    hash: [20]byte
    if c, ok := ctx.internal_ctx.(Sha1_Context); ok {
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

hash_file_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, hd: os.Handle, load_at_once := false) -> ([20]byte, bool) {
    if !load_at_once {
        return hash_stream_odin(ctx, os.stream_from_handle(hd))
    } else {
        if buf, ok := os.read_entire_file(hd); ok {
            return hash_bytes_odin(ctx, buf[:]), ok
        }
    }
    return [20]byte{}, false
}

@(private)
_create_sha1_ctx :: #force_inline proc() {
	ctx: Sha1_Context
	_hash_impl.internal_ctx = ctx
	_hash_impl.hash_size    = ._20
}

@(private)
_init_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context) {
    _create_sha1_ctx()
    if c, ok := ctx.internal_ctx.(Sha1_Context); ok {
    	init_odin(&c)
    }
}

@(private)
_update_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, data: []byte) {
    if c, ok := ctx.internal_ctx.(Sha1_Context); ok {
    	update_odin(&c, data)
    }
}

@(private)
_final_odin :: #force_inline proc(ctx: ^_ctx.Hash_Context, hash: []byte) {
    if c, ok := ctx.internal_ctx.(Sha1_Context); ok {
    	final_odin(&c, hash)
    }
}

/*
    SHA1 implementation
*/

BLOCK_SIZE  :: 64

Sha1_Context :: struct {
    data:    [BLOCK_SIZE]byte,
    datalen: u32,
    bitlen:  u64,
    state:   [5]u32,
    k:       [4]u32,
}

transform :: proc(ctx: ^Sha1_Context, data: []byte) {
    a, b, c, d, e, i, j, t: u32
    m: [80]u32

	for i, j = 0, 0; i < 16; i += 1 {
        m[i] = u32(data[j]) << 24 + u32(data[j + 1]) << 16 + u32(data[j + 2]) << 8 + u32(data[j + 3])
        j += 4
    }
	for i < 80 {
		m[i] = (m[i - 3] ~ m[i - 8] ~ m[i - 14] ~ m[i - 16])
		m[i] = (m[i] << 1) | (m[i] >> 31)
        i += 1
	}

	a = ctx.state[0]
	b = ctx.state[1]
	c = ctx.state[2]
	d = ctx.state[3]
	e = ctx.state[4]

	for i = 0; i < 20; i += 1 {
		t = util.ROTL32(a, 5) + ((b & c) ~ (~b & d)) + e + ctx.k[0] + m[i]
		e = d
		d = c
		c = util.ROTL32(b, 30)
		b = a
		a = t
	}
	for i < 40 {
		t = util.ROTL32(a, 5) + (b ~ c ~ d) + e + ctx.k[1] + m[i]
		e = d
		d = c
		c = util.ROTL32(b, 30)
		b = a
		a = t
        i += 1
	}
	for i < 60 {
		t = util.ROTL32(a, 5) + ((b & c) ~ (b & d) ~ (c & d)) + e + ctx.k[2] + m[i]
		e = d
		d = c
		c = util.ROTL32(b, 30)
		b = a
		a = t
        i += 1
	}
	for i < 80 {
		t = util.ROTL32(a, 5) + (b ~ c ~ d) + e + ctx.k[3] + m[i]
		e = d
		d = c
		c = util.ROTL32(b, 30)
		b = a
		a = t
        i += 1
	}

	ctx.state[0] += a
	ctx.state[1] += b
	ctx.state[2] += c
	ctx.state[3] += d
	ctx.state[4] += e
}

init_odin :: proc(ctx: ^Sha1_Context) {
	ctx.state[0] = 0x67452301
	ctx.state[1] = 0xefcdab89
	ctx.state[2] = 0x98badcfe
	ctx.state[3] = 0x10325476
	ctx.state[4] = 0xc3d2e1f0
	ctx.k[0]     = 0x5a827999
	ctx.k[1]     = 0x6ed9eba1
	ctx.k[2]     = 0x8f1bbcdc
	ctx.k[3]     = 0xca62c1d6
}

update_odin :: proc(ctx: ^Sha1_Context, data: []byte) {
	for i := 0; i < len(data); i += 1 {
		ctx.data[ctx.datalen] = data[i]
		ctx.datalen += 1
		if (ctx.datalen == BLOCK_SIZE) {
			transform(ctx, ctx.data[:])
			ctx.bitlen += 512
			ctx.datalen = 0
		}
	}
}

final_odin :: proc(ctx: ^Sha1_Context, hash: []byte) {
	i := ctx.datalen

	if ctx.datalen < 56 {
		ctx.data[i] = 0x80
        i += 1
        for i < 56 {
            ctx.data[i] = 0x00
            i += 1
        }
	}
	else {
		ctx.data[i] = 0x80
        i += 1
        for i < BLOCK_SIZE {
            ctx.data[i] = 0x00
            i += 1
        }
		transform(ctx, ctx.data[:])
		mem.set(&ctx.data, 0, 56)
	}

	ctx.bitlen  += u64(ctx.datalen * 8)
	ctx.data[63] = u8(ctx.bitlen)
	ctx.data[62] = u8(ctx.bitlen >> 8)
	ctx.data[61] = u8(ctx.bitlen >> 16)
	ctx.data[60] = u8(ctx.bitlen >> 24)
	ctx.data[59] = u8(ctx.bitlen >> 32)
	ctx.data[58] = u8(ctx.bitlen >> 40)
	ctx.data[57] = u8(ctx.bitlen >> 48)
	ctx.data[56] = u8(ctx.bitlen >> 56)
	transform(ctx, ctx.data[:])

	for j: u32 = 0; j < 4; j += 1 {
		hash[j]      = u8(ctx.state[0] >> (24 - j * 8)) & 0x000000ff
		hash[j + 4]  = u8(ctx.state[1] >> (24 - j * 8)) & 0x000000ff
		hash[j + 8]  = u8(ctx.state[2] >> (24 - j * 8)) & 0x000000ff
		hash[j + 12] = u8(ctx.state[3] >> (24 - j * 8)) & 0x000000ff
		hash[j + 16] = u8(ctx.state[4] >> (24 - j * 8)) & 0x000000ff
	}
}