package _blake2

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Implementation of the BLAKE2 hashing algorithm, as defined in <https://datatracker.ietf.org/doc/html/rfc7693> and <https://www.blake2.net/>
*/

import "core:encoding/endian"
import "core:mem"

BLAKE2S_BLOCK_SIZE :: 64
BLAKE2S_SIZE :: 32
BLAKE2B_BLOCK_SIZE :: 128
BLAKE2B_SIZE :: 64

MAX_SIZE :: 255

Blake2s_Context :: struct {
	h:            [8]u32,
	t:            [2]u32,
	f:            [2]u32,
	x:            [BLAKE2S_BLOCK_SIZE]byte,
	nx:           int,
	ih:           [8]u32,
	padded_key:   [BLAKE2S_BLOCK_SIZE]byte,
	is_keyed:     bool,
	size:         byte,
	is_last_node: bool,

	is_initialized: bool,
}

Blake2b_Context :: struct {
	h:            [8]u64,
	t:            [2]u64,
	f:            [2]u64,
	x:            [BLAKE2B_BLOCK_SIZE]byte,
	nx:           int,
	ih:           [8]u64,
	padded_key:   [BLAKE2B_BLOCK_SIZE]byte,
	is_keyed:     bool,
	size:         byte,
	is_last_node: bool,

	is_initialized: bool,
}

Blake2_Config :: struct {
	size:   byte,
	key:    []byte,
	salt:   []byte,
	person: []byte,
	tree:   union {
		Blake2_Tree,
	},
}

Blake2_Tree :: struct {
	fanout:          byte,
	max_depth:       byte,
	leaf_size:       u32,
	node_offset:     u64,
	node_depth:      byte,
	inner_hash_size: byte,
	is_last_node:    bool,
}

@(private, rodata)
BLAKE2S_IV := [8]u32 {
	0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
	0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
}

@(private, rodata)
BLAKE2B_IV := [8]u64 {
	0x6a09e667f3bcc908, 0xbb67ae8584caa73b,
	0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,
	0x510e527fade682d1, 0x9b05688c2b3e6c1f,
	0x1f83d9abfb41bd6b, 0x5be0cd19137e2179,
}

init :: proc "contextless" (ctx: ^$T, cfg: ^Blake2_Config) {
	when T == Blake2s_Context {
		max_size :: BLAKE2S_SIZE
	} else when T == Blake2b_Context {
		max_size :: BLAKE2B_SIZE
	}
	ensure_contextless(cfg.size <= max_size, "blake2: requested output size exceeeds algorithm max")

	// To save having to allocate a scratch buffer, use the internal
	// data buffer (`ctx.x`), as it is exactly the correct size.
	p := ctx.x[:]

	p[0] = cfg.size
	p[1] = byte(len(cfg.key))

	if cfg.salt != nil {
		when T == Blake2s_Context {
			copy(p[16:], cfg.salt)
		} else when T == Blake2b_Context {
			copy(p[32:], cfg.salt)
		}
	}
	if cfg.person != nil {
		when T == Blake2s_Context {
			copy(p[24:], cfg.person)
		} else when T == Blake2b_Context {
			copy(p[48:], cfg.person)
		}
	}

	if cfg.tree != nil {
		p[2] = cfg.tree.(Blake2_Tree).fanout
		p[3] = cfg.tree.(Blake2_Tree).max_depth
		endian.unchecked_put_u32le(p[4:], cfg.tree.(Blake2_Tree).leaf_size)
		when T == Blake2s_Context {
			p[8] = byte(cfg.tree.(Blake2_Tree).node_offset)
			p[9] = byte(cfg.tree.(Blake2_Tree).node_offset >> 8)
			p[10] = byte(cfg.tree.(Blake2_Tree).node_offset >> 16)
			p[11] = byte(cfg.tree.(Blake2_Tree).node_offset >> 24)
			p[12] = byte(cfg.tree.(Blake2_Tree).node_offset >> 32)
			p[13] = byte(cfg.tree.(Blake2_Tree).node_offset >> 40)
			p[14] = cfg.tree.(Blake2_Tree).node_depth
			p[15] = cfg.tree.(Blake2_Tree).inner_hash_size
		} else when T == Blake2b_Context {
			endian.unchecked_put_u64le(p[8:], cfg.tree.(Blake2_Tree).node_offset)
			p[16] = cfg.tree.(Blake2_Tree).node_depth
			p[17] = cfg.tree.(Blake2_Tree).inner_hash_size
		}
	} else {
		p[2], p[3] = 1, 1
	}
	ctx.size = cfg.size
	for i := 0; i < 8; i += 1 {
		when T == Blake2s_Context {
			ctx.h[i] = BLAKE2S_IV[i] ~ endian.unchecked_get_u32le(p[i * 4:])
		}
		when T == Blake2b_Context {
			ctx.h[i] = BLAKE2B_IV[i] ~ endian.unchecked_get_u64le(p[i * 8:])
		}
	}

	mem.zero(&ctx.x, size_of(ctx.x)) // Done with the scratch space, no barrier.

	if cfg.tree != nil && cfg.tree.(Blake2_Tree).is_last_node {
		ctx.is_last_node = true
	}
	if len(cfg.key) > 0 {
		copy(ctx.padded_key[:], cfg.key)
		update(ctx, ctx.padded_key[:])
		ctx.is_keyed = true
	}
	copy(ctx.ih[:], ctx.h[:])
	copy(ctx.h[:], ctx.ih[:])
	if ctx.is_keyed {
		update(ctx, ctx.padded_key[:])
	}

	ctx.nx = 0

	ctx.is_initialized = true
}

update :: proc "contextless" (ctx: ^$T, p: []byte) {
	ensure_contextless(ctx.is_initialized)

	p := p
	when T == Blake2s_Context {
		block_size :: BLAKE2S_BLOCK_SIZE
	} else when T == Blake2b_Context {
		block_size :: BLAKE2B_BLOCK_SIZE
	}

	left := block_size - ctx.nx
	if len(p) > left {
		copy(ctx.x[ctx.nx:], p[:left])
		p = p[left:]
		blocks(ctx, ctx.x[:])
		ctx.nx = 0
	}
	if len(p) > block_size {
		n := len(p) &~ (block_size - 1)
		if n == len(p) {
			n -= block_size
		}
		blocks(ctx, p[:n])
		p = p[n:]
	}
	ctx.nx += copy(ctx.x[ctx.nx:], p)
}

final :: proc "contextless" (ctx: ^$T, hash: []byte, finalize_clone: bool = false) {
	ensure_contextless(ctx.is_initialized)

	ctx := ctx
	if finalize_clone {
		tmp_ctx: T
		clone(&tmp_ctx, ctx)
		ctx = &tmp_ctx
	}
	defer(reset(ctx))

	ensure_contextless(len(hash) >= int(ctx.size), "crypto/blake2: invalid destination digest size")
	when T == Blake2s_Context {
		blake2s_final(ctx, hash)
	} else when T == Blake2b_Context {
		blake2b_final(ctx, hash)
	}
}

clone :: proc "contextless" (ctx, other: ^$T) {
	ctx^ = other^
}

reset :: proc "contextless" (ctx: ^$T) {
	if !ctx.is_initialized {
		return
	}

	mem.zero_explicit(ctx, size_of(ctx^))
}

@(private)
blake2s_final :: proc "contextless" (ctx: ^Blake2s_Context, hash: []byte) {
	if ctx.is_keyed {
		for i := 0; i < len(ctx.padded_key); i += 1 {
			ctx.padded_key[i] = 0
		}
	}

	dec := BLAKE2S_BLOCK_SIZE - u32(ctx.nx)
	if ctx.t[0] < dec {
		ctx.t[1] -= 1
	}
	ctx.t[0] -= dec

	ctx.f[0] = 0xffffffff
	if ctx.is_last_node {
		ctx.f[1] = 0xffffffff
	}

	blocks(ctx, ctx.x[:])

	dst: [BLAKE2S_SIZE]byte
	for i := 0; i < BLAKE2S_SIZE / 4; i += 1 {
		endian.unchecked_put_u32le(dst[i * 4:], ctx.h[i])
	}
	copy(hash, dst[:])
}

@(private)
blake2b_final :: proc "contextless" (ctx: ^Blake2b_Context, hash: []byte) {
	if ctx.is_keyed {
		for i := 0; i < len(ctx.padded_key); i += 1 {
			ctx.padded_key[i] = 0
		}
	}

	dec := BLAKE2B_BLOCK_SIZE - u64(ctx.nx)
	if ctx.t[0] < dec {
		ctx.t[1] -= 1
	}
	ctx.t[0] -= dec

	ctx.f[0] = 0xffffffffffffffff
	if ctx.is_last_node {
		ctx.f[1] = 0xffffffffffffffff
	}

	blocks(ctx, ctx.x[:])

	dst: [BLAKE2B_SIZE]byte
	for i := 0; i < BLAKE2B_SIZE / 8; i += 1 {
		endian.unchecked_put_u64le(dst[i * 8:], ctx.h[i])
	}
	copy(hash, dst[:])
}

@(private)
blocks :: proc "contextless" (ctx: ^$T, p: []byte) {
	when T == Blake2s_Context {
		blake2s_blocks(ctx, p)
	} else when T == Blake2b_Context {
		blake2b_blocks(ctx, p)
	}
}

@(private)
blake2s_blocks :: #force_inline proc "contextless" (ctx: ^Blake2s_Context, p: []byte) {
	h0, h1, h2, h3, h4, h5, h6, h7 :=
		ctx.h[0], ctx.h[1], ctx.h[2], ctx.h[3], ctx.h[4], ctx.h[5], ctx.h[6], ctx.h[7]
	p := p
	for len(p) >= BLAKE2S_BLOCK_SIZE {
		ctx.t[0] += BLAKE2S_BLOCK_SIZE
		if ctx.t[0] < BLAKE2S_BLOCK_SIZE {
			ctx.t[1] += 1
		}
		v0, v1, v2, v3, v4, v5, v6, v7 := h0, h1, h2, h3, h4, h5, h6, h7
		v8 := BLAKE2S_IV[0]
		v9 := BLAKE2S_IV[1]
		v10 := BLAKE2S_IV[2]
		v11 := BLAKE2S_IV[3]
		v12 := BLAKE2S_IV[4] ~ ctx.t[0]
		v13 := BLAKE2S_IV[5] ~ ctx.t[1]
		v14 := BLAKE2S_IV[6] ~ ctx.f[0]
		v15 := BLAKE2S_IV[7] ~ ctx.f[1]

		m: [16]u32 = ---
		for i := 0; i < 16; i += 1 {
			m[i] = endian.unchecked_get_u32le(p[i * 4:])
		}

		// Round 1
		v0 += m[0]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (32 - 16) | v12 >> 16
		v8 += v12
		v4 ~= v8
		v4 = v4 << (32 - 12) | v4 >> 12
		v1 += m[2]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (32 - 16) | v13 >> 16
		v9 += v13
		v5 ~= v9
		v5 = v5 << (32 - 12) | v5 >> 12
		v2 += m[4]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (32 - 16) | v14 >> 16
		v10 += v14
		v6 ~= v10
		v6 = v6 << (32 - 12) | v6 >> 12
		v3 += m[6]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (32 - 16) | v15 >> 16
		v11 += v15
		v7 ~= v11
		v7 = v7 << (32 - 12) | v7 >> 12
		v2 += m[5]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (32 - 8) | v14 >> 8
		v10 += v14
		v6 ~= v10
		v6 = v6 << (32 - 7) | v6 >> 7
		v3 += m[7]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (32 - 8) | v15 >> 8
		v11 += v15
		v7 ~= v11
		v7 = v7 << (32 - 7) | v7 >> 7
		v1 += m[3]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (32 - 8) | v13 >> 8
		v9 += v13
		v5 ~= v9
		v5 = v5 << (32 - 7) | v5 >> 7
		v0 += m[1]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (32 - 8) | v12 >> 8
		v8 += v12
		v4 ~= v8
		v4 = v4 << (32 - 7) | v4 >> 7
		v0 += m[8]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (32 - 16) | v15 >> 16
		v10 += v15
		v5 ~= v10
		v5 = v5 << (32 - 12) | v5 >> 12
		v1 += m[10]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (32 - 16) | v12 >> 16
		v11 += v12
		v6 ~= v11
		v6 = v6 << (32 - 12) | v6 >> 12
		v2 += m[12]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (32 - 16) | v13 >> 16
		v8 += v13
		v7 ~= v8
		v7 = v7 << (32 - 12) | v7 >> 12
		v3 += m[14]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (32 - 16) | v14 >> 16
		v9 += v14
		v4 ~= v9
		v4 = v4 << (32 - 12) | v4 >> 12
		v2 += m[13]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (32 - 8) | v13 >> 8
		v8 += v13
		v7 ~= v8
		v7 = v7 << (32 - 7) | v7 >> 7
		v3 += m[15]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (32 - 8) | v14 >> 8
		v9 += v14
		v4 ~= v9
		v4 = v4 << (32 - 7) | v4 >> 7
		v1 += m[11]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (32 - 8) | v12 >> 8
		v11 += v12
		v6 ~= v11
		v6 = v6 << (32 - 7) | v6 >> 7
		v0 += m[9]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (32 - 8) | v15 >> 8
		v10 += v15
		v5 ~= v10
		v5 = v5 << (32 - 7) | v5 >> 7

		// Round 2
		v0 += m[14]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (32 - 16) | v12 >> 16
		v8 += v12
		v4 ~= v8
		v4 = v4 << (32 - 12) | v4 >> 12
		v1 += m[4]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (32 - 16) | v13 >> 16
		v9 += v13
		v5 ~= v9
		v5 = v5 << (32 - 12) | v5 >> 12
		v2 += m[9]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (32 - 16) | v14 >> 16
		v10 += v14
		v6 ~= v10
		v6 = v6 << (32 - 12) | v6 >> 12
		v3 += m[13]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (32 - 16) | v15 >> 16
		v11 += v15
		v7 ~= v11
		v7 = v7 << (32 - 12) | v7 >> 12
		v2 += m[15]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (32 - 8) | v14 >> 8
		v10 += v14
		v6 ~= v10
		v6 = v6 << (32 - 7) | v6 >> 7
		v3 += m[6]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (32 - 8) | v15 >> 8
		v11 += v15
		v7 ~= v11
		v7 = v7 << (32 - 7) | v7 >> 7
		v1 += m[8]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (32 - 8) | v13 >> 8
		v9 += v13
		v5 ~= v9
		v5 = v5 << (32 - 7) | v5 >> 7
		v0 += m[10]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (32 - 8) | v12 >> 8
		v8 += v12
		v4 ~= v8
		v4 = v4 << (32 - 7) | v4 >> 7
		v0 += m[1]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (32 - 16) | v15 >> 16
		v10 += v15
		v5 ~= v10
		v5 = v5 << (32 - 12) | v5 >> 12
		v1 += m[0]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (32 - 16) | v12 >> 16
		v11 += v12
		v6 ~= v11
		v6 = v6 << (32 - 12) | v6 >> 12
		v2 += m[11]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (32 - 16) | v13 >> 16
		v8 += v13
		v7 ~= v8
		v7 = v7 << (32 - 12) | v7 >> 12
		v3 += m[5]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (32 - 16) | v14 >> 16
		v9 += v14
		v4 ~= v9
		v4 = v4 << (32 - 12) | v4 >> 12
		v2 += m[7]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (32 - 8) | v13 >> 8
		v8 += v13
		v7 ~= v8
		v7 = v7 << (32 - 7) | v7 >> 7
		v3 += m[3]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (32 - 8) | v14 >> 8
		v9 += v14
		v4 ~= v9
		v4 = v4 << (32 - 7) | v4 >> 7
		v1 += m[2]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (32 - 8) | v12 >> 8
		v11 += v12
		v6 ~= v11
		v6 = v6 << (32 - 7) | v6 >> 7
		v0 += m[12]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (32 - 8) | v15 >> 8
		v10 += v15
		v5 ~= v10
		v5 = v5 << (32 - 7) | v5 >> 7

		// Round 3
		v0 += m[11]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (32 - 16) | v12 >> 16
		v8 += v12
		v4 ~= v8
		v4 = v4 << (32 - 12) | v4 >> 12
		v1 += m[12]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (32 - 16) | v13 >> 16
		v9 += v13
		v5 ~= v9
		v5 = v5 << (32 - 12) | v5 >> 12
		v2 += m[5]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (32 - 16) | v14 >> 16
		v10 += v14
		v6 ~= v10
		v6 = v6 << (32 - 12) | v6 >> 12
		v3 += m[15]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (32 - 16) | v15 >> 16
		v11 += v15
		v7 ~= v11
		v7 = v7 << (32 - 12) | v7 >> 12
		v2 += m[2]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (32 - 8) | v14 >> 8
		v10 += v14
		v6 ~= v10
		v6 = v6 << (32 - 7) | v6 >> 7
		v3 += m[13]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (32 - 8) | v15 >> 8
		v11 += v15
		v7 ~= v11
		v7 = v7 << (32 - 7) | v7 >> 7
		v1 += m[0]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (32 - 8) | v13 >> 8
		v9 += v13
		v5 ~= v9
		v5 = v5 << (32 - 7) | v5 >> 7
		v0 += m[8]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (32 - 8) | v12 >> 8
		v8 += v12
		v4 ~= v8
		v4 = v4 << (32 - 7) | v4 >> 7
		v0 += m[10]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (32 - 16) | v15 >> 16
		v10 += v15
		v5 ~= v10
		v5 = v5 << (32 - 12) | v5 >> 12
		v1 += m[3]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (32 - 16) | v12 >> 16
		v11 += v12
		v6 ~= v11
		v6 = v6 << (32 - 12) | v6 >> 12
		v2 += m[7]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (32 - 16) | v13 >> 16
		v8 += v13
		v7 ~= v8
		v7 = v7 << (32 - 12) | v7 >> 12
		v3 += m[9]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (32 - 16) | v14 >> 16
		v9 += v14
		v4 ~= v9
		v4 = v4 << (32 - 12) | v4 >> 12
		v2 += m[1]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (32 - 8) | v13 >> 8
		v8 += v13
		v7 ~= v8
		v7 = v7 << (32 - 7) | v7 >> 7
		v3 += m[4]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (32 - 8) | v14 >> 8
		v9 += v14
		v4 ~= v9
		v4 = v4 << (32 - 7) | v4 >> 7
		v1 += m[6]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (32 - 8) | v12 >> 8
		v11 += v12
		v6 ~= v11
		v6 = v6 << (32 - 7) | v6 >> 7
		v0 += m[14]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (32 - 8) | v15 >> 8
		v10 += v15
		v5 ~= v10
		v5 = v5 << (32 - 7) | v5 >> 7

		// Round 4
		v0 += m[7]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (32 - 16) | v12 >> 16
		v8 += v12
		v4 ~= v8
		v4 = v4 << (32 - 12) | v4 >> 12
		v1 += m[3]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (32 - 16) | v13 >> 16
		v9 += v13
		v5 ~= v9
		v5 = v5 << (32 - 12) | v5 >> 12
		v2 += m[13]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (32 - 16) | v14 >> 16
		v10 += v14
		v6 ~= v10
		v6 = v6 << (32 - 12) | v6 >> 12
		v3 += m[11]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (32 - 16) | v15 >> 16
		v11 += v15
		v7 ~= v11
		v7 = v7 << (32 - 12) | v7 >> 12
		v2 += m[12]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (32 - 8) | v14 >> 8
		v10 += v14
		v6 ~= v10
		v6 = v6 << (32 - 7) | v6 >> 7
		v3 += m[14]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (32 - 8) | v15 >> 8
		v11 += v15
		v7 ~= v11
		v7 = v7 << (32 - 7) | v7 >> 7
		v1 += m[1]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (32 - 8) | v13 >> 8
		v9 += v13
		v5 ~= v9
		v5 = v5 << (32 - 7) | v5 >> 7
		v0 += m[9]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (32 - 8) | v12 >> 8
		v8 += v12
		v4 ~= v8
		v4 = v4 << (32 - 7) | v4 >> 7
		v0 += m[2]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (32 - 16) | v15 >> 16
		v10 += v15
		v5 ~= v10
		v5 = v5 << (32 - 12) | v5 >> 12
		v1 += m[5]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (32 - 16) | v12 >> 16
		v11 += v12
		v6 ~= v11
		v6 = v6 << (32 - 12) | v6 >> 12
		v2 += m[4]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (32 - 16) | v13 >> 16
		v8 += v13
		v7 ~= v8
		v7 = v7 << (32 - 12) | v7 >> 12
		v3 += m[15]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (32 - 16) | v14 >> 16
		v9 += v14
		v4 ~= v9
		v4 = v4 << (32 - 12) | v4 >> 12
		v2 += m[0]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (32 - 8) | v13 >> 8
		v8 += v13
		v7 ~= v8
		v7 = v7 << (32 - 7) | v7 >> 7
		v3 += m[8]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (32 - 8) | v14 >> 8
		v9 += v14
		v4 ~= v9
		v4 = v4 << (32 - 7) | v4 >> 7
		v1 += m[10]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (32 - 8) | v12 >> 8
		v11 += v12
		v6 ~= v11
		v6 = v6 << (32 - 7) | v6 >> 7
		v0 += m[6]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (32 - 8) | v15 >> 8
		v10 += v15
		v5 ~= v10
		v5 = v5 << (32 - 7) | v5 >> 7

		// Round 5
		v0 += m[9]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (32 - 16) | v12 >> 16
		v8 += v12
		v4 ~= v8
		v4 = v4 << (32 - 12) | v4 >> 12
		v1 += m[5]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (32 - 16) | v13 >> 16
		v9 += v13
		v5 ~= v9
		v5 = v5 << (32 - 12) | v5 >> 12
		v2 += m[2]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (32 - 16) | v14 >> 16
		v10 += v14
		v6 ~= v10
		v6 = v6 << (32 - 12) | v6 >> 12
		v3 += m[10]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (32 - 16) | v15 >> 16
		v11 += v15
		v7 ~= v11
		v7 = v7 << (32 - 12) | v7 >> 12
		v2 += m[4]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (32 - 8) | v14 >> 8
		v10 += v14
		v6 ~= v10
		v6 = v6 << (32 - 7) | v6 >> 7
		v3 += m[15]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (32 - 8) | v15 >> 8
		v11 += v15
		v7 ~= v11
		v7 = v7 << (32 - 7) | v7 >> 7
		v1 += m[7]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (32 - 8) | v13 >> 8
		v9 += v13
		v5 ~= v9
		v5 = v5 << (32 - 7) | v5 >> 7
		v0 += m[0]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (32 - 8) | v12 >> 8
		v8 += v12
		v4 ~= v8
		v4 = v4 << (32 - 7) | v4 >> 7
		v0 += m[14]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (32 - 16) | v15 >> 16
		v10 += v15
		v5 ~= v10
		v5 = v5 << (32 - 12) | v5 >> 12
		v1 += m[11]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (32 - 16) | v12 >> 16
		v11 += v12
		v6 ~= v11
		v6 = v6 << (32 - 12) | v6 >> 12
		v2 += m[6]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (32 - 16) | v13 >> 16
		v8 += v13
		v7 ~= v8
		v7 = v7 << (32 - 12) | v7 >> 12
		v3 += m[3]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (32 - 16) | v14 >> 16
		v9 += v14
		v4 ~= v9
		v4 = v4 << (32 - 12) | v4 >> 12
		v2 += m[8]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (32 - 8) | v13 >> 8
		v8 += v13
		v7 ~= v8
		v7 = v7 << (32 - 7) | v7 >> 7
		v3 += m[13]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (32 - 8) | v14 >> 8
		v9 += v14
		v4 ~= v9
		v4 = v4 << (32 - 7) | v4 >> 7
		v1 += m[12]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (32 - 8) | v12 >> 8
		v11 += v12
		v6 ~= v11
		v6 = v6 << (32 - 7) | v6 >> 7
		v0 += m[1]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (32 - 8) | v15 >> 8
		v10 += v15
		v5 ~= v10
		v5 = v5 << (32 - 7) | v5 >> 7

		// Round 6
		v0 += m[2]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (32 - 16) | v12 >> 16
		v8 += v12
		v4 ~= v8
		v4 = v4 << (32 - 12) | v4 >> 12
		v1 += m[6]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (32 - 16) | v13 >> 16
		v9 += v13
		v5 ~= v9
		v5 = v5 << (32 - 12) | v5 >> 12
		v2 += m[0]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (32 - 16) | v14 >> 16
		v10 += v14
		v6 ~= v10
		v6 = v6 << (32 - 12) | v6 >> 12
		v3 += m[8]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (32 - 16) | v15 >> 16
		v11 += v15
		v7 ~= v11
		v7 = v7 << (32 - 12) | v7 >> 12
		v2 += m[11]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (32 - 8) | v14 >> 8
		v10 += v14
		v6 ~= v10
		v6 = v6 << (32 - 7) | v6 >> 7
		v3 += m[3]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (32 - 8) | v15 >> 8
		v11 += v15
		v7 ~= v11
		v7 = v7 << (32 - 7) | v7 >> 7
		v1 += m[10]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (32 - 8) | v13 >> 8
		v9 += v13
		v5 ~= v9
		v5 = v5 << (32 - 7) | v5 >> 7
		v0 += m[12]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (32 - 8) | v12 >> 8
		v8 += v12
		v4 ~= v8
		v4 = v4 << (32 - 7) | v4 >> 7
		v0 += m[4]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (32 - 16) | v15 >> 16
		v10 += v15
		v5 ~= v10
		v5 = v5 << (32 - 12) | v5 >> 12
		v1 += m[7]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (32 - 16) | v12 >> 16
		v11 += v12
		v6 ~= v11
		v6 = v6 << (32 - 12) | v6 >> 12
		v2 += m[15]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (32 - 16) | v13 >> 16
		v8 += v13
		v7 ~= v8
		v7 = v7 << (32 - 12) | v7 >> 12
		v3 += m[1]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (32 - 16) | v14 >> 16
		v9 += v14
		v4 ~= v9
		v4 = v4 << (32 - 12) | v4 >> 12
		v2 += m[14]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (32 - 8) | v13 >> 8
		v8 += v13
		v7 ~= v8
		v7 = v7 << (32 - 7) | v7 >> 7
		v3 += m[9]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (32 - 8) | v14 >> 8
		v9 += v14
		v4 ~= v9
		v4 = v4 << (32 - 7) | v4 >> 7
		v1 += m[5]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (32 - 8) | v12 >> 8
		v11 += v12
		v6 ~= v11
		v6 = v6 << (32 - 7) | v6 >> 7
		v0 += m[13]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (32 - 8) | v15 >> 8
		v10 += v15
		v5 ~= v10
		v5 = v5 << (32 - 7) | v5 >> 7

		// Round 7
		v0 += m[12]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (32 - 16) | v12 >> 16
		v8 += v12
		v4 ~= v8
		v4 = v4 << (32 - 12) | v4 >> 12
		v1 += m[1]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (32 - 16) | v13 >> 16
		v9 += v13
		v5 ~= v9
		v5 = v5 << (32 - 12) | v5 >> 12
		v2 += m[14]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (32 - 16) | v14 >> 16
		v10 += v14
		v6 ~= v10
		v6 = v6 << (32 - 12) | v6 >> 12
		v3 += m[4]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (32 - 16) | v15 >> 16
		v11 += v15
		v7 ~= v11
		v7 = v7 << (32 - 12) | v7 >> 12
		v2 += m[13]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (32 - 8) | v14 >> 8
		v10 += v14
		v6 ~= v10
		v6 = v6 << (32 - 7) | v6 >> 7
		v3 += m[10]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (32 - 8) | v15 >> 8
		v11 += v15
		v7 ~= v11
		v7 = v7 << (32 - 7) | v7 >> 7
		v1 += m[15]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (32 - 8) | v13 >> 8
		v9 += v13
		v5 ~= v9
		v5 = v5 << (32 - 7) | v5 >> 7
		v0 += m[5]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (32 - 8) | v12 >> 8
		v8 += v12
		v4 ~= v8
		v4 = v4 << (32 - 7) | v4 >> 7
		v0 += m[0]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (32 - 16) | v15 >> 16
		v10 += v15
		v5 ~= v10
		v5 = v5 << (32 - 12) | v5 >> 12
		v1 += m[6]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (32 - 16) | v12 >> 16
		v11 += v12
		v6 ~= v11
		v6 = v6 << (32 - 12) | v6 >> 12
		v2 += m[9]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (32 - 16) | v13 >> 16
		v8 += v13
		v7 ~= v8
		v7 = v7 << (32 - 12) | v7 >> 12
		v3 += m[8]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (32 - 16) | v14 >> 16
		v9 += v14
		v4 ~= v9
		v4 = v4 << (32 - 12) | v4 >> 12
		v2 += m[2]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (32 - 8) | v13 >> 8
		v8 += v13
		v7 ~= v8
		v7 = v7 << (32 - 7) | v7 >> 7
		v3 += m[11]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (32 - 8) | v14 >> 8
		v9 += v14
		v4 ~= v9
		v4 = v4 << (32 - 7) | v4 >> 7
		v1 += m[3]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (32 - 8) | v12 >> 8
		v11 += v12
		v6 ~= v11
		v6 = v6 << (32 - 7) | v6 >> 7
		v0 += m[7]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (32 - 8) | v15 >> 8
		v10 += v15
		v5 ~= v10
		v5 = v5 << (32 - 7) | v5 >> 7

		// Round 8
		v0 += m[13]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (32 - 16) | v12 >> 16
		v8 += v12
		v4 ~= v8
		v4 = v4 << (32 - 12) | v4 >> 12
		v1 += m[7]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (32 - 16) | v13 >> 16
		v9 += v13
		v5 ~= v9
		v5 = v5 << (32 - 12) | v5 >> 12
		v2 += m[12]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (32 - 16) | v14 >> 16
		v10 += v14
		v6 ~= v10
		v6 = v6 << (32 - 12) | v6 >> 12
		v3 += m[3]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (32 - 16) | v15 >> 16
		v11 += v15
		v7 ~= v11
		v7 = v7 << (32 - 12) | v7 >> 12
		v2 += m[1]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (32 - 8) | v14 >> 8
		v10 += v14
		v6 ~= v10
		v6 = v6 << (32 - 7) | v6 >> 7
		v3 += m[9]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (32 - 8) | v15 >> 8
		v11 += v15
		v7 ~= v11
		v7 = v7 << (32 - 7) | v7 >> 7
		v1 += m[14]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (32 - 8) | v13 >> 8
		v9 += v13
		v5 ~= v9
		v5 = v5 << (32 - 7) | v5 >> 7
		v0 += m[11]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (32 - 8) | v12 >> 8
		v8 += v12
		v4 ~= v8
		v4 = v4 << (32 - 7) | v4 >> 7
		v0 += m[5]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (32 - 16) | v15 >> 16
		v10 += v15
		v5 ~= v10
		v5 = v5 << (32 - 12) | v5 >> 12
		v1 += m[15]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (32 - 16) | v12 >> 16
		v11 += v12
		v6 ~= v11
		v6 = v6 << (32 - 12) | v6 >> 12
		v2 += m[8]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (32 - 16) | v13 >> 16
		v8 += v13
		v7 ~= v8
		v7 = v7 << (32 - 12) | v7 >> 12
		v3 += m[2]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (32 - 16) | v14 >> 16
		v9 += v14
		v4 ~= v9
		v4 = v4 << (32 - 12) | v4 >> 12
		v2 += m[6]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (32 - 8) | v13 >> 8
		v8 += v13
		v7 ~= v8
		v7 = v7 << (32 - 7) | v7 >> 7
		v3 += m[10]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (32 - 8) | v14 >> 8
		v9 += v14
		v4 ~= v9
		v4 = v4 << (32 - 7) | v4 >> 7
		v1 += m[4]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (32 - 8) | v12 >> 8
		v11 += v12
		v6 ~= v11
		v6 = v6 << (32 - 7) | v6 >> 7
		v0 += m[0]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (32 - 8) | v15 >> 8
		v10 += v15
		v5 ~= v10
		v5 = v5 << (32 - 7) | v5 >> 7

		// Round 9
		v0 += m[6]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (32 - 16) | v12 >> 16
		v8 += v12
		v4 ~= v8
		v4 = v4 << (32 - 12) | v4 >> 12
		v1 += m[14]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (32 - 16) | v13 >> 16
		v9 += v13
		v5 ~= v9
		v5 = v5 << (32 - 12) | v5 >> 12
		v2 += m[11]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (32 - 16) | v14 >> 16
		v10 += v14
		v6 ~= v10
		v6 = v6 << (32 - 12) | v6 >> 12
		v3 += m[0]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (32 - 16) | v15 >> 16
		v11 += v15
		v7 ~= v11
		v7 = v7 << (32 - 12) | v7 >> 12
		v2 += m[3]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (32 - 8) | v14 >> 8
		v10 += v14
		v6 ~= v10
		v6 = v6 << (32 - 7) | v6 >> 7
		v3 += m[8]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (32 - 8) | v15 >> 8
		v11 += v15
		v7 ~= v11
		v7 = v7 << (32 - 7) | v7 >> 7
		v1 += m[9]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (32 - 8) | v13 >> 8
		v9 += v13
		v5 ~= v9
		v5 = v5 << (32 - 7) | v5 >> 7
		v0 += m[15]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (32 - 8) | v12 >> 8
		v8 += v12
		v4 ~= v8
		v4 = v4 << (32 - 7) | v4 >> 7
		v0 += m[12]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (32 - 16) | v15 >> 16
		v10 += v15
		v5 ~= v10
		v5 = v5 << (32 - 12) | v5 >> 12
		v1 += m[13]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (32 - 16) | v12 >> 16
		v11 += v12
		v6 ~= v11
		v6 = v6 << (32 - 12) | v6 >> 12
		v2 += m[1]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (32 - 16) | v13 >> 16
		v8 += v13
		v7 ~= v8
		v7 = v7 << (32 - 12) | v7 >> 12
		v3 += m[10]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (32 - 16) | v14 >> 16
		v9 += v14
		v4 ~= v9
		v4 = v4 << (32 - 12) | v4 >> 12
		v2 += m[4]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (32 - 8) | v13 >> 8
		v8 += v13
		v7 ~= v8
		v7 = v7 << (32 - 7) | v7 >> 7
		v3 += m[5]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (32 - 8) | v14 >> 8
		v9 += v14
		v4 ~= v9
		v4 = v4 << (32 - 7) | v4 >> 7
		v1 += m[7]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (32 - 8) | v12 >> 8
		v11 += v12
		v6 ~= v11
		v6 = v6 << (32 - 7) | v6 >> 7
		v0 += m[2]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (32 - 8) | v15 >> 8
		v10 += v15
		v5 ~= v10
		v5 = v5 << (32 - 7) | v5 >> 7

		// Round 10
		v0 += m[10]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (32 - 16) | v12 >> 16
		v8 += v12
		v4 ~= v8
		v4 = v4 << (32 - 12) | v4 >> 12
		v1 += m[8]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (32 - 16) | v13 >> 16
		v9 += v13
		v5 ~= v9
		v5 = v5 << (32 - 12) | v5 >> 12
		v2 += m[7]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (32 - 16) | v14 >> 16
		v10 += v14
		v6 ~= v10
		v6 = v6 << (32 - 12) | v6 >> 12
		v3 += m[1]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (32 - 16) | v15 >> 16
		v11 += v15
		v7 ~= v11
		v7 = v7 << (32 - 12) | v7 >> 12
		v2 += m[6]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (32 - 8) | v14 >> 8
		v10 += v14
		v6 ~= v10
		v6 = v6 << (32 - 7) | v6 >> 7
		v3 += m[5]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (32 - 8) | v15 >> 8
		v11 += v15
		v7 ~= v11
		v7 = v7 << (32 - 7) | v7 >> 7
		v1 += m[4]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (32 - 8) | v13 >> 8
		v9 += v13
		v5 ~= v9
		v5 = v5 << (32 - 7) | v5 >> 7
		v0 += m[2]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (32 - 8) | v12 >> 8
		v8 += v12
		v4 ~= v8
		v4 = v4 << (32 - 7) | v4 >> 7
		v0 += m[15]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (32 - 16) | v15 >> 16
		v10 += v15
		v5 ~= v10
		v5 = v5 << (32 - 12) | v5 >> 12
		v1 += m[9]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (32 - 16) | v12 >> 16
		v11 += v12
		v6 ~= v11
		v6 = v6 << (32 - 12) | v6 >> 12
		v2 += m[3]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (32 - 16) | v13 >> 16
		v8 += v13
		v7 ~= v8
		v7 = v7 << (32 - 12) | v7 >> 12
		v3 += m[13]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (32 - 16) | v14 >> 16
		v9 += v14
		v4 ~= v9
		v4 = v4 << (32 - 12) | v4 >> 12
		v2 += m[12]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (32 - 8) | v13 >> 8
		v8 += v13
		v7 ~= v8
		v7 = v7 << (32 - 7) | v7 >> 7
		v3 += m[0]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (32 - 8) | v14 >> 8
		v9 += v14
		v4 ~= v9
		v4 = v4 << (32 - 7) | v4 >> 7
		v1 += m[14]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (32 - 8) | v12 >> 8
		v11 += v12
		v6 ~= v11
		v6 = v6 << (32 - 7) | v6 >> 7
		v0 += m[11]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (32 - 8) | v15 >> 8
		v10 += v15
		v5 ~= v10
		v5 = v5 << (32 - 7) | v5 >> 7

		h0 ~= v0 ~ v8
		h1 ~= v1 ~ v9
		h2 ~= v2 ~ v10
		h3 ~= v3 ~ v11
		h4 ~= v4 ~ v12
		h5 ~= v5 ~ v13
		h6 ~= v6 ~ v14
		h7 ~= v7 ~ v15

		p = p[BLAKE2S_BLOCK_SIZE:]
	}
	ctx.h[0], ctx.h[1], ctx.h[2], ctx.h[3], ctx.h[4], ctx.h[5], ctx.h[6], ctx.h[7] =
		h0, h1, h2, h3, h4, h5, h6, h7
}

@(private)
blake2b_blocks :: #force_inline proc "contextless" (ctx: ^Blake2b_Context, p: []byte) {
	h0, h1, h2, h3, h4, h5, h6, h7 :=
		ctx.h[0], ctx.h[1], ctx.h[2], ctx.h[3], ctx.h[4], ctx.h[5], ctx.h[6], ctx.h[7]
	p := p
	for len(p) >= BLAKE2B_BLOCK_SIZE {
		ctx.t[0] += BLAKE2B_BLOCK_SIZE
		if ctx.t[0] < BLAKE2B_BLOCK_SIZE {
			ctx.t[1] += 1
		}
		v0, v1, v2, v3, v4, v5, v6, v7 := h0, h1, h2, h3, h4, h5, h6, h7
		v8 := BLAKE2B_IV[0]
		v9 := BLAKE2B_IV[1]
		v10 := BLAKE2B_IV[2]
		v11 := BLAKE2B_IV[3]
		v12 := BLAKE2B_IV[4] ~ ctx.t[0]
		v13 := BLAKE2B_IV[5] ~ ctx.t[1]
		v14 := BLAKE2B_IV[6] ~ ctx.f[0]
		v15 := BLAKE2B_IV[7] ~ ctx.f[1]

		m: [16]u64 = ---
		for i := 0; i < 16; i += 1 {
			m[i] = endian.unchecked_get_u64le(p[i * 8:])
		}

		// Round 1
		v0 += m[0]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 32) | v12 >> 32
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 24) | v4 >> 24
		v1 += m[2]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 32) | v13 >> 32
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 24) | v5 >> 24
		v2 += m[4]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 32) | v14 >> 32
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 24) | v6 >> 24
		v3 += m[6]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 32) | v15 >> 32
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 24) | v7 >> 24
		v2 += m[5]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 16) | v14 >> 16
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 63) | v6 >> 63
		v3 += m[7]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 16) | v15 >> 16
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 63) | v7 >> 63
		v1 += m[3]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 16) | v13 >> 16
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 63) | v5 >> 63
		v0 += m[1]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 16) | v12 >> 16
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 63) | v4 >> 63
		v0 += m[8]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 32) | v15 >> 32
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 24) | v5 >> 24
		v1 += m[10]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 32) | v12 >> 32
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 24) | v6 >> 24
		v2 += m[12]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 32) | v13 >> 32
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 24) | v7 >> 24
		v3 += m[14]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 32) | v14 >> 32
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 24) | v4 >> 24
		v2 += m[13]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 16) | v13 >> 16
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 63) | v7 >> 63
		v3 += m[15]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 16) | v14 >> 16
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 63) | v4 >> 63
		v1 += m[11]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 16) | v12 >> 16
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 63) | v6 >> 63
		v0 += m[9]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 16) | v15 >> 16
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 63) | v5 >> 63

		// Round 2
		v0 += m[14]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 32) | v12 >> 32
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 24) | v4 >> 24
		v1 += m[4]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 32) | v13 >> 32
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 24) | v5 >> 24
		v2 += m[9]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 32) | v14 >> 32
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 24) | v6 >> 24
		v3 += m[13]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 32) | v15 >> 32
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 24) | v7 >> 24
		v2 += m[15]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 16) | v14 >> 16
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 63) | v6 >> 63
		v3 += m[6]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 16) | v15 >> 16
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 63) | v7 >> 63
		v1 += m[8]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 16) | v13 >> 16
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 63) | v5 >> 63
		v0 += m[10]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 16) | v12 >> 16
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 63) | v4 >> 63
		v0 += m[1]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 32) | v15 >> 32
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 24) | v5 >> 24
		v1 += m[0]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 32) | v12 >> 32
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 24) | v6 >> 24
		v2 += m[11]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 32) | v13 >> 32
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 24) | v7 >> 24
		v3 += m[5]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 32) | v14 >> 32
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 24) | v4 >> 24
		v2 += m[7]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 16) | v13 >> 16
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 63) | v7 >> 63
		v3 += m[3]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 16) | v14 >> 16
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 63) | v4 >> 63
		v1 += m[2]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 16) | v12 >> 16
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 63) | v6 >> 63
		v0 += m[12]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 16) | v15 >> 16
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 63) | v5 >> 63

		// Round 3
		v0 += m[11]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 32) | v12 >> 32
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 24) | v4 >> 24
		v1 += m[12]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 32) | v13 >> 32
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 24) | v5 >> 24
		v2 += m[5]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 32) | v14 >> 32
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 24) | v6 >> 24
		v3 += m[15]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 32) | v15 >> 32
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 24) | v7 >> 24
		v2 += m[2]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 16) | v14 >> 16
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 63) | v6 >> 63
		v3 += m[13]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 16) | v15 >> 16
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 63) | v7 >> 63
		v1 += m[0]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 16) | v13 >> 16
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 63) | v5 >> 63
		v0 += m[8]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 16) | v12 >> 16
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 63) | v4 >> 63
		v0 += m[10]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 32) | v15 >> 32
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 24) | v5 >> 24
		v1 += m[3]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 32) | v12 >> 32
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 24) | v6 >> 24
		v2 += m[7]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 32) | v13 >> 32
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 24) | v7 >> 24
		v3 += m[9]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 32) | v14 >> 32
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 24) | v4 >> 24
		v2 += m[1]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 16) | v13 >> 16
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 63) | v7 >> 63
		v3 += m[4]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 16) | v14 >> 16
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 63) | v4 >> 63
		v1 += m[6]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 16) | v12 >> 16
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 63) | v6 >> 63
		v0 += m[14]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 16) | v15 >> 16
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 63) | v5 >> 63

		// Round 4
		v0 += m[7]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 32) | v12 >> 32
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 24) | v4 >> 24
		v1 += m[3]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 32) | v13 >> 32
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 24) | v5 >> 24
		v2 += m[13]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 32) | v14 >> 32
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 24) | v6 >> 24
		v3 += m[11]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 32) | v15 >> 32
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 24) | v7 >> 24
		v2 += m[12]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 16) | v14 >> 16
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 63) | v6 >> 63
		v3 += m[14]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 16) | v15 >> 16
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 63) | v7 >> 63
		v1 += m[1]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 16) | v13 >> 16
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 63) | v5 >> 63
		v0 += m[9]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 16) | v12 >> 16
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 63) | v4 >> 63
		v0 += m[2]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 32) | v15 >> 32
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 24) | v5 >> 24
		v1 += m[5]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 32) | v12 >> 32
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 24) | v6 >> 24
		v2 += m[4]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 32) | v13 >> 32
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 24) | v7 >> 24
		v3 += m[15]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 32) | v14 >> 32
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 24) | v4 >> 24
		v2 += m[0]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 16) | v13 >> 16
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 63) | v7 >> 63
		v3 += m[8]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 16) | v14 >> 16
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 63) | v4 >> 63
		v1 += m[10]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 16) | v12 >> 16
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 63) | v6 >> 63
		v0 += m[6]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 16) | v15 >> 16
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 63) | v5 >> 63

		// Round 5
		v0 += m[9]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 32) | v12 >> 32
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 24) | v4 >> 24
		v1 += m[5]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 32) | v13 >> 32
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 24) | v5 >> 24
		v2 += m[2]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 32) | v14 >> 32
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 24) | v6 >> 24
		v3 += m[10]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 32) | v15 >> 32
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 24) | v7 >> 24
		v2 += m[4]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 16) | v14 >> 16
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 63) | v6 >> 63
		v3 += m[15]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 16) | v15 >> 16
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 63) | v7 >> 63
		v1 += m[7]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 16) | v13 >> 16
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 63) | v5 >> 63
		v0 += m[0]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 16) | v12 >> 16
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 63) | v4 >> 63
		v0 += m[14]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 32) | v15 >> 32
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 24) | v5 >> 24
		v1 += m[11]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 32) | v12 >> 32
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 24) | v6 >> 24
		v2 += m[6]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 32) | v13 >> 32
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 24) | v7 >> 24
		v3 += m[3]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 32) | v14 >> 32
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 24) | v4 >> 24
		v2 += m[8]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 16) | v13 >> 16
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 63) | v7 >> 63
		v3 += m[13]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 16) | v14 >> 16
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 63) | v4 >> 63
		v1 += m[12]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 16) | v12 >> 16
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 63) | v6 >> 63
		v0 += m[1]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 16) | v15 >> 16
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 63) | v5 >> 63

		// Round 6
		v0 += m[2]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 32) | v12 >> 32
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 24) | v4 >> 24
		v1 += m[6]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 32) | v13 >> 32
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 24) | v5 >> 24
		v2 += m[0]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 32) | v14 >> 32
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 24) | v6 >> 24
		v3 += m[8]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 32) | v15 >> 32
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 24) | v7 >> 24
		v2 += m[11]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 16) | v14 >> 16
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 63) | v6 >> 63
		v3 += m[3]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 16) | v15 >> 16
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 63) | v7 >> 63
		v1 += m[10]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 16) | v13 >> 16
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 63) | v5 >> 63
		v0 += m[12]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 16) | v12 >> 16
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 63) | v4 >> 63
		v0 += m[4]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 32) | v15 >> 32
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 24) | v5 >> 24
		v1 += m[7]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 32) | v12 >> 32
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 24) | v6 >> 24
		v2 += m[15]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 32) | v13 >> 32
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 24) | v7 >> 24
		v3 += m[1]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 32) | v14 >> 32
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 24) | v4 >> 24
		v2 += m[14]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 16) | v13 >> 16
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 63) | v7 >> 63
		v3 += m[9]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 16) | v14 >> 16
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 63) | v4 >> 63
		v1 += m[5]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 16) | v12 >> 16
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 63) | v6 >> 63
		v0 += m[13]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 16) | v15 >> 16
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 63) | v5 >> 63

		// Round 7
		v0 += m[12]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 32) | v12 >> 32
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 24) | v4 >> 24
		v1 += m[1]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 32) | v13 >> 32
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 24) | v5 >> 24
		v2 += m[14]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 32) | v14 >> 32
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 24) | v6 >> 24
		v3 += m[4]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 32) | v15 >> 32
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 24) | v7 >> 24
		v2 += m[13]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 16) | v14 >> 16
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 63) | v6 >> 63
		v3 += m[10]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 16) | v15 >> 16
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 63) | v7 >> 63
		v1 += m[15]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 16) | v13 >> 16
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 63) | v5 >> 63
		v0 += m[5]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 16) | v12 >> 16
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 63) | v4 >> 63
		v0 += m[0]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 32) | v15 >> 32
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 24) | v5 >> 24
		v1 += m[6]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 32) | v12 >> 32
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 24) | v6 >> 24
		v2 += m[9]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 32) | v13 >> 32
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 24) | v7 >> 24
		v3 += m[8]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 32) | v14 >> 32
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 24) | v4 >> 24
		v2 += m[2]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 16) | v13 >> 16
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 63) | v7 >> 63
		v3 += m[11]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 16) | v14 >> 16
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 63) | v4 >> 63
		v1 += m[3]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 16) | v12 >> 16
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 63) | v6 >> 63
		v0 += m[7]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 16) | v15 >> 16
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 63) | v5 >> 63

		// Round 8
		v0 += m[13]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 32) | v12 >> 32
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 24) | v4 >> 24
		v1 += m[7]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 32) | v13 >> 32
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 24) | v5 >> 24
		v2 += m[12]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 32) | v14 >> 32
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 24) | v6 >> 24
		v3 += m[3]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 32) | v15 >> 32
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 24) | v7 >> 24
		v2 += m[1]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 16) | v14 >> 16
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 63) | v6 >> 63
		v3 += m[9]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 16) | v15 >> 16
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 63) | v7 >> 63
		v1 += m[14]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 16) | v13 >> 16
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 63) | v5 >> 63
		v0 += m[11]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 16) | v12 >> 16
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 63) | v4 >> 63
		v0 += m[5]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 32) | v15 >> 32
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 24) | v5 >> 24
		v1 += m[15]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 32) | v12 >> 32
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 24) | v6 >> 24
		v2 += m[8]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 32) | v13 >> 32
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 24) | v7 >> 24
		v3 += m[2]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 32) | v14 >> 32
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 24) | v4 >> 24
		v2 += m[6]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 16) | v13 >> 16
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 63) | v7 >> 63
		v3 += m[10]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 16) | v14 >> 16
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 63) | v4 >> 63
		v1 += m[4]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 16) | v12 >> 16
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 63) | v6 >> 63
		v0 += m[0]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 16) | v15 >> 16
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 63) | v5 >> 63

		// Round 9
		v0 += m[6]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 32) | v12 >> 32
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 24) | v4 >> 24
		v1 += m[14]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 32) | v13 >> 32
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 24) | v5 >> 24
		v2 += m[11]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 32) | v14 >> 32
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 24) | v6 >> 24
		v3 += m[0]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 32) | v15 >> 32
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 24) | v7 >> 24
		v2 += m[3]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 16) | v14 >> 16
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 63) | v6 >> 63
		v3 += m[8]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 16) | v15 >> 16
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 63) | v7 >> 63
		v1 += m[9]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 16) | v13 >> 16
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 63) | v5 >> 63
		v0 += m[15]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 16) | v12 >> 16
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 63) | v4 >> 63
		v0 += m[12]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 32) | v15 >> 32
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 24) | v5 >> 24
		v1 += m[13]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 32) | v12 >> 32
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 24) | v6 >> 24
		v2 += m[1]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 32) | v13 >> 32
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 24) | v7 >> 24
		v3 += m[10]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 32) | v14 >> 32
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 24) | v4 >> 24
		v2 += m[4]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 16) | v13 >> 16
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 63) | v7 >> 63
		v3 += m[5]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 16) | v14 >> 16
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 63) | v4 >> 63
		v1 += m[7]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 16) | v12 >> 16
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 63) | v6 >> 63
		v0 += m[2]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 16) | v15 >> 16
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 63) | v5 >> 63

		// Round 10
		v0 += m[10]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 32) | v12 >> 32
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 24) | v4 >> 24
		v1 += m[8]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 32) | v13 >> 32
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 24) | v5 >> 24
		v2 += m[7]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 32) | v14 >> 32
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 24) | v6 >> 24
		v3 += m[1]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 32) | v15 >> 32
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 24) | v7 >> 24
		v2 += m[6]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 16) | v14 >> 16
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 63) | v6 >> 63
		v3 += m[5]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 16) | v15 >> 16
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 63) | v7 >> 63
		v1 += m[4]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 16) | v13 >> 16
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 63) | v5 >> 63
		v0 += m[2]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 16) | v12 >> 16
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 63) | v4 >> 63
		v0 += m[15]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 32) | v15 >> 32
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 24) | v5 >> 24
		v1 += m[9]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 32) | v12 >> 32
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 24) | v6 >> 24
		v2 += m[3]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 32) | v13 >> 32
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 24) | v7 >> 24
		v3 += m[13]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 32) | v14 >> 32
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 24) | v4 >> 24
		v2 += m[12]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 16) | v13 >> 16
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 63) | v7 >> 63
		v3 += m[0]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 16) | v14 >> 16
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 63) | v4 >> 63
		v1 += m[14]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 16) | v12 >> 16
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 63) | v6 >> 63
		v0 += m[11]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 16) | v15 >> 16
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 63) | v5 >> 63

		// Round 11
		v0 += m[0]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 32) | v12 >> 32
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 24) | v4 >> 24
		v1 += m[2]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 32) | v13 >> 32
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 24) | v5 >> 24
		v2 += m[4]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 32) | v14 >> 32
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 24) | v6 >> 24
		v3 += m[6]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 32) | v15 >> 32
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 24) | v7 >> 24
		v2 += m[5]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 16) | v14 >> 16
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 63) | v6 >> 63
		v3 += m[7]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 16) | v15 >> 16
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 63) | v7 >> 63
		v1 += m[3]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 16) | v13 >> 16
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 63) | v5 >> 63
		v0 += m[1]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 16) | v12 >> 16
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 63) | v4 >> 63
		v0 += m[8]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 32) | v15 >> 32
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 24) | v5 >> 24
		v1 += m[10]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 32) | v12 >> 32
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 24) | v6 >> 24
		v2 += m[12]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 32) | v13 >> 32
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 24) | v7 >> 24
		v3 += m[14]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 32) | v14 >> 32
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 24) | v4 >> 24
		v2 += m[13]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 16) | v13 >> 16
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 63) | v7 >> 63
		v3 += m[15]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 16) | v14 >> 16
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 63) | v4 >> 63
		v1 += m[11]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 16) | v12 >> 16
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 63) | v6 >> 63
		v0 += m[9]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 16) | v15 >> 16
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 63) | v5 >> 63

		// Round 12
		v0 += m[14]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 32) | v12 >> 32
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 24) | v4 >> 24
		v1 += m[4]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 32) | v13 >> 32
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 24) | v5 >> 24
		v2 += m[9]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 32) | v14 >> 32
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 24) | v6 >> 24
		v3 += m[13]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 32) | v15 >> 32
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 24) | v7 >> 24
		v2 += m[15]
		v2 += v6
		v14 ~= v2
		v14 = v14 << (64 - 16) | v14 >> 16
		v10 += v14
		v6 ~= v10
		v6 = v6 << (64 - 63) | v6 >> 63
		v3 += m[6]
		v3 += v7
		v15 ~= v3
		v15 = v15 << (64 - 16) | v15 >> 16
		v11 += v15
		v7 ~= v11
		v7 = v7 << (64 - 63) | v7 >> 63
		v1 += m[8]
		v1 += v5
		v13 ~= v1
		v13 = v13 << (64 - 16) | v13 >> 16
		v9 += v13
		v5 ~= v9
		v5 = v5 << (64 - 63) | v5 >> 63
		v0 += m[10]
		v0 += v4
		v12 ~= v0
		v12 = v12 << (64 - 16) | v12 >> 16
		v8 += v12
		v4 ~= v8
		v4 = v4 << (64 - 63) | v4 >> 63
		v0 += m[1]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 32) | v15 >> 32
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 24) | v5 >> 24
		v1 += m[0]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 32) | v12 >> 32
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 24) | v6 >> 24
		v2 += m[11]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 32) | v13 >> 32
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 24) | v7 >> 24
		v3 += m[5]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 32) | v14 >> 32
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 24) | v4 >> 24
		v2 += m[7]
		v2 += v7
		v13 ~= v2
		v13 = v13 << (64 - 16) | v13 >> 16
		v8 += v13
		v7 ~= v8
		v7 = v7 << (64 - 63) | v7 >> 63
		v3 += m[3]
		v3 += v4
		v14 ~= v3
		v14 = v14 << (64 - 16) | v14 >> 16
		v9 += v14
		v4 ~= v9
		v4 = v4 << (64 - 63) | v4 >> 63
		v1 += m[2]
		v1 += v6
		v12 ~= v1
		v12 = v12 << (64 - 16) | v12 >> 16
		v11 += v12
		v6 ~= v11
		v6 = v6 << (64 - 63) | v6 >> 63
		v0 += m[12]
		v0 += v5
		v15 ~= v0
		v15 = v15 << (64 - 16) | v15 >> 16
		v10 += v15
		v5 ~= v10
		v5 = v5 << (64 - 63) | v5 >> 63

		h0 ~= v0 ~ v8
		h1 ~= v1 ~ v9
		h2 ~= v2 ~ v10
		h3 ~= v3 ~ v11
		h4 ~= v4 ~ v12
		h5 ~= v5 ~ v13
		h6 ~= v6 ~ v14
		h7 ~= v7 ~ v15

		p = p[BLAKE2B_BLOCK_SIZE:]
	}
	ctx.h[0], ctx.h[1], ctx.h[2], ctx.h[3], ctx.h[4], ctx.h[5], ctx.h[6], ctx.h[7] =
		h0, h1, h2, h3, h4, h5, h6, h7
}
