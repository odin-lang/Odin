package _sha3

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.

    Implementation of the Keccak hashing algorithm, standardized as SHA3 in <https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf>
    To use the original Keccak padding, set the is_keccak bool to true, otherwise it will use SHA3 padding.
*/

import "core:math/bits"

ROUNDS :: 24

Sha3_Context :: struct {
	st:        struct #raw_union {
		b: [200]u8,
		q: [25]u64,
	},
	pt:        int,
	rsiz:      int,
	mdlen:     int,
	is_keccak: bool,

	is_initialized: bool,
	is_finalized:   bool, // For SHAKE (unlimited squeeze is allowed)
}

keccakf :: proc "contextless" (st: ^[25]u64) {
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

	keccakf_rotc := [?]int {
		1, 3, 6, 10, 15, 21, 28, 36, 45, 55, 2, 14,
		27, 41, 56, 8, 25, 43, 62, 18, 39, 61, 20, 44,
	}

	keccakf_piln := [?]i32 {
		10, 7, 11, 17, 18, 3, 5, 16, 8, 21, 24, 4,
		15, 23, 19, 13, 12, 2, 20, 14, 22, 9, 6, 1,
	}

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

init :: proc(c: ^Sha3_Context) {
	for i := 0; i < 25; i += 1 {
		c.st.q[i] = 0
	}
	c.rsiz = 200 - 2 * c.mdlen
	c.pt = 0

	c.is_initialized = true
	c.is_finalized = false
}

update :: proc(c: ^Sha3_Context, data: []byte) {
	assert(c.is_initialized)
	assert(!c.is_finalized)

	j := c.pt
	for i := 0; i < len(data); i += 1 {
		c.st.b[j] ~= data[i]
		j += 1
		if j >= c.rsiz {
			keccakf(&c.st.q)
			j = 0
		}
	}
	c.pt = j
}

final :: proc(c: ^Sha3_Context, hash: []byte) {
	assert(c.is_initialized)

	if len(hash) < c.mdlen {
		if c.is_keccak {
			panic("crypto/keccac: invalid destination digest size")
		}
		panic("crypto/sha3: invalid destination digest size")
	}
	if c.is_keccak {
		c.st.b[c.pt] ~= 0x01
	} else {
		c.st.b[c.pt] ~= 0x06
	}

	c.st.b[c.rsiz - 1] ~= 0x80
	keccakf(&c.st.q)
	for i := 0; i < c.mdlen; i += 1 {
		hash[i] = c.st.b[i]
	}

	c.is_initialized = false // No more absorb, no more squeeze.
}

shake_xof :: proc(c: ^Sha3_Context) {
	assert(c.is_initialized)
	assert(!c.is_finalized)

	c.st.b[c.pt] ~= 0x1F
	c.st.b[c.rsiz - 1] ~= 0x80
	keccakf(&c.st.q)
	c.pt = 0

	c.is_finalized = true // No more absorb, unlimited squeeze.
}

shake_out :: proc(c: ^Sha3_Context, hash: []byte) {
	assert(c.is_initialized)
	assert(c.is_finalized)

	j := c.pt
	for i := 0; i < len(hash); i += 1 {
		if j >= c.rsiz {
			keccakf(&c.st.q)
			j = 0
		}
		hash[i] = c.st.b[j]
		j += 1
	}
	c.pt = j
}
