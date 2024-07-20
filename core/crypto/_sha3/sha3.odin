package _sha3

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Implementation of the Keccak hashing algorithm, standardized as SHA3
    in <https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf>.

    As the only difference between the legacy Keccak and SHA3 is the domain
    separation byte, set dsbyte to the appropriate value to pick the desired
    algorithm.
*/

import "core:math/bits"
import "core:mem"

ROUNDS :: 24

RATE_128 :: 1344 / 8 // ONLY for SHAKE128.
RATE_224 :: 1152 / 8
RATE_256 :: 1088 / 8
RATE_384 :: 832 / 8
RATE_512 :: 576 / 8

DS_KECCAK :: 0x01
DS_SHA3 :: 0x06
DS_SHAKE :: 0x1f
DS_CSHAKE :: 0x04

Context :: struct {
	st:             struct #raw_union {
		b: [200]u8,
		q: [25]u64,
	},
	pt:             int,
	rsiz:           int,
	mdlen:          int,
	dsbyte:         byte,
	is_initialized: bool,
	is_finalized:   bool, // For SHAKE (unlimited squeeze is allowed)
}

@(private)
keccakf_rndc := [?]u64 {
	0x0000000000000001, 0x0000000000008082, 0x800000000000808a,
	0x8000000080008000, 0x000000000000808b, 0x0000000080000001,
	0x8000000080008081, 0x8000000000008009, 0x000000000000008a,
	0x0000000000000088, 0x0000000080008009, 0x000000008000000a,
	0x000000008000808b, 0x800000000000008b, 0x8000000000008089,
	0x8000000000008003, 0x8000000000008002, 0x8000000000000080,
	0x000000000000800a, 0x800000008000000a, 0x8000000080008081,
	0x8000000000008080, 0x0000000080000001, 0x8000000080008008,
}

@(private)
keccakf_rotc := [?]int {
	1, 3, 6, 10, 15, 21, 28, 36, 45, 55, 2, 14,
	27, 41, 56, 8, 25, 43, 62, 18, 39, 61, 20, 44,
}

@(private)
keccakf_piln := [?]i32 {
	10, 7, 11, 17, 18, 3, 5, 16, 8, 21, 24, 4,
	15, 23, 19, 13, 12, 2, 20, 14, 22, 9, 6, 1,
}

@(private)
keccakf :: proc "contextless" (st: ^[25]u64) {
	i, j, r: i32 = ---, ---, ---
	t: u64 = ---
	bc: [5]u64 = ---

	when ODIN_ENDIAN != .Little {
		for i = 0; i < 25; i += 1 {
			st[i] = bits.byte_swap(st[i])
		}
	}

	for r = 0; r < ROUNDS; r += 1 {
		// theta
		for i = 0; i < 5; i += 1 {
			bc[i] = st[i] ~ st[i + 5] ~ st[i + 10] ~ st[i + 15] ~ st[i + 20]
		}

		for i = 0; i < 5; i += 1 {
			t = bc[(i + 4) % 5] ~ bits.rotate_left64(bc[(i + 1) % 5], 1)
			for j = 0; j < 25; j += 5 {
				st[j + i] ~= t
			}
		}

		// rho pi
		t = st[1]
		for i = 0; i < 24; i += 1 {
			j = keccakf_piln[i]
			bc[0] = st[j]
			st[j] = bits.rotate_left64(t, keccakf_rotc[i])
			t = bc[0]
		}

		// chi
		for j = 0; j < 25; j += 5 {
			for i = 0; i < 5; i += 1 {
				bc[i] = st[j + i]
			}
			for i = 0; i < 5; i += 1 {
				st[j + i] ~= ~bc[(i + 1) % 5] & bc[(i + 2) % 5]
			}
		}

		st[0] ~= keccakf_rndc[r]
	}

	when ODIN_ENDIAN != .Little {
		for i = 0; i < 25; i += 1 {
			st[i] = bits.byte_swap(st[i])
		}
	}
}

init :: proc(ctx: ^Context) {
	for i := 0; i < 25; i += 1 {
		ctx.st.q[i] = 0
	}
	ctx.rsiz = 200 - 2 * ctx.mdlen
	ctx.pt = 0

	ctx.is_initialized = true
	ctx.is_finalized = false
}

update :: proc(ctx: ^Context, data: []byte) {
	assert(ctx.is_initialized)
	assert(!ctx.is_finalized)

	j := ctx.pt
	for i := 0; i < len(data); i += 1 {
		ctx.st.b[j] ~= data[i]
		j += 1
		if j >= ctx.rsiz {
			keccakf(&ctx.st.q)
			j = 0
		}
	}
	ctx.pt = j
}

final :: proc(ctx: ^Context, hash: []byte, finalize_clone: bool = false) {
	assert(ctx.is_initialized)

	if len(hash) < ctx.mdlen {
		panic("crypto/sha3: invalid destination digest size")
	}

	ctx := ctx
	if finalize_clone {
		tmp_ctx: Context
		clone(&tmp_ctx, ctx)
		ctx = &tmp_ctx
	}
	defer (reset(ctx))

	ctx.st.b[ctx.pt] ~= ctx.dsbyte

	ctx.st.b[ctx.rsiz - 1] ~= 0x80
	keccakf(&ctx.st.q)
	for i := 0; i < ctx.mdlen; i += 1 {
		hash[i] = ctx.st.b[i]
	}
}

clone :: proc(ctx, other: ^Context) {
	ctx^ = other^
}

reset :: proc(ctx: ^Context) {
	if !ctx.is_initialized {
		return
	}

	mem.zero_explicit(ctx, size_of(ctx^))
}

shake_xof :: proc(ctx: ^Context) {
	assert(ctx.is_initialized)
	assert(!ctx.is_finalized)

	ctx.st.b[ctx.pt] ~= ctx.dsbyte
	ctx.st.b[ctx.rsiz - 1] ~= 0x80
	keccakf(&ctx.st.q)
	ctx.pt = 0

	ctx.is_finalized = true // No more absorb, unlimited squeeze.
}

shake_out :: proc(ctx: ^Context, hash: []byte) {
	assert(ctx.is_initialized)
	assert(ctx.is_finalized)

	j := ctx.pt
	for i := 0; i < len(hash); i += 1 {
		if j >= ctx.rsiz {
			keccakf(&ctx.st.q)
			j = 0
		}
		hash[i] = ctx.st.b[j]
		j += 1
	}
	ctx.pt = j
}
