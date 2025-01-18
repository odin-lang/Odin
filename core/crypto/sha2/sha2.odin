/*
package sha2 implements the SHA2 hash algorithm family.

See:
- [[ https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.180-4.pdf ]]
- [[ https://datatracker.ietf.org/doc/html/rfc3874 ]]
*/
package sha2

/*
    Copyright 2021 zhibog
    Made available under the BSD-3 license.

    List of contributors:
        zhibog, dotbmp:  Initial implementation.
*/

@(require) import "core:encoding/endian"
import "core:math/bits"
@(require) import "core:mem"

// DIGEST_SIZE_224 is the SHA-224 digest size in bytes.
DIGEST_SIZE_224 :: 28
// DIGEST_SIZE_256 is the SHA-256 digest size in bytes.
DIGEST_SIZE_256 :: 32
// DIGEST_SIZE_384 is the SHA-384 digest size in bytes.
DIGEST_SIZE_384 :: 48
// DIGEST_SIZE_512 is the SHA-512 digest size in bytes.
DIGEST_SIZE_512 :: 64
// DIGEST_SIZE_512_256 is the SHA-512/256 digest size in bytes.
DIGEST_SIZE_512_256 :: 32

// BLOCK_SIZE_256 is the SHA-224 and SHA-256 block size in bytes.
BLOCK_SIZE_256 :: 64
// BLOCK_SIZE_512 is the SHA-384, SHA-512, and SHA-512/256 block size
// in bytes.
BLOCK_SIZE_512 :: 128

// Context_256 is a SHA-224 or SHA-256 instance.
Context_256 :: struct {
	block:     [BLOCK_SIZE_256]byte,
	h:         [8]u32,
	bitlength: u64,
	length:    u64,
	md_bits:   int,

	is_initialized: bool,
}

// Context_512 is a SHA-384, SHA-512 or SHA-512/256 instance.
Context_512 :: struct {
	block:     [BLOCK_SIZE_512]byte,
	h:         [8]u64,
	bitlength: u64,
	length:    u64,
	md_bits:   int,

	is_initialized: bool,
}

// init_224 initializes a Context_256 for SHA-224.
init_224 :: proc(ctx: ^Context_256) {
	ctx.md_bits = 224
	_init(ctx)
}

// init_256 initializes a Context_256 for SHA-256.
init_256 :: proc(ctx: ^Context_256) {
	ctx.md_bits = 256
	_init(ctx)
}

// init_384 initializes a Context_512 for SHA-384.
init_384 :: proc(ctx: ^Context_512) {
	ctx.md_bits = 384
	_init(ctx)
}

// init_512 initializes a Context_512 for SHA-512.
init_512 :: proc(ctx: ^Context_512) {
	ctx.md_bits = 512
	_init(ctx)
}

// init_512_256 initializes a Context_512 for SHA-512/256.
init_512_256 :: proc(ctx: ^Context_512) {
	ctx.md_bits = 256
	_init(ctx)
}

@(private)
_init :: proc(ctx: ^$T) {
	when T == Context_256 {
		switch ctx.md_bits {
		case 224:
			ctx.h[0] = 0xc1059ed8
			ctx.h[1] = 0x367cd507
			ctx.h[2] = 0x3070dd17
			ctx.h[3] = 0xf70e5939
			ctx.h[4] = 0xffc00b31
			ctx.h[5] = 0x68581511
			ctx.h[6] = 0x64f98fa7
			ctx.h[7] = 0xbefa4fa4
		case 256:
			ctx.h[0] = 0x6a09e667
			ctx.h[1] = 0xbb67ae85
			ctx.h[2] = 0x3c6ef372
			ctx.h[3] = 0xa54ff53a
			ctx.h[4] = 0x510e527f
			ctx.h[5] = 0x9b05688c
			ctx.h[6] = 0x1f83d9ab
			ctx.h[7] = 0x5be0cd19
		case:
			panic("crypto/sha2: invalid digest output length")
		}
	} else when T == Context_512 {
		switch ctx.md_bits {
		case 256:
			// SHA-512/256
			ctx.h[0] = 0x22312194fc2bf72c
			ctx.h[1] = 0x9f555fa3c84c64c2
			ctx.h[2] = 0x2393b86b6f53b151
			ctx.h[3] = 0x963877195940eabd
			ctx.h[4] = 0x96283ee2a88effe3
			ctx.h[5] = 0xbe5e1e2553863992
			ctx.h[6] = 0x2b0199fc2c85b8aa
			ctx.h[7] = 0x0eb72ddc81c52ca2
		case 384:
			// SHA-384
			ctx.h[0] = 0xcbbb9d5dc1059ed8
			ctx.h[1] = 0x629a292a367cd507
			ctx.h[2] = 0x9159015a3070dd17
			ctx.h[3] = 0x152fecd8f70e5939
			ctx.h[4] = 0x67332667ffc00b31
			ctx.h[5] = 0x8eb44a8768581511
			ctx.h[6] = 0xdb0c2e0d64f98fa7
			ctx.h[7] = 0x47b5481dbefa4fa4
		case 512:
			// SHA-512
			ctx.h[0] = 0x6a09e667f3bcc908
			ctx.h[1] = 0xbb67ae8584caa73b
			ctx.h[2] = 0x3c6ef372fe94f82b
			ctx.h[3] = 0xa54ff53a5f1d36f1
			ctx.h[4] = 0x510e527fade682d1
			ctx.h[5] = 0x9b05688c2b3e6c1f
			ctx.h[6] = 0x1f83d9abfb41bd6b
			ctx.h[7] = 0x5be0cd19137e2179
		case:
			panic("crypto/sha2: invalid digest output length")
		}
	}

	ctx.length = 0
	ctx.bitlength = 0

	ctx.is_initialized = true
}

// update adds more data to the Context.
update :: proc(ctx: ^$T, data: []byte) {
	ensure(ctx.is_initialized)

	when T == Context_256 {
		CURR_BLOCK_SIZE :: BLOCK_SIZE_256
	} else when T == Context_512 {
		CURR_BLOCK_SIZE :: BLOCK_SIZE_512
	}

	data := data
	ctx.length += u64(len(data))

	if ctx.bitlength > 0 {
		n := copy(ctx.block[ctx.bitlength:], data[:])
		ctx.bitlength += u64(n)
		if ctx.bitlength == CURR_BLOCK_SIZE {
			sha2_transf(ctx, ctx.block[:])
			ctx.bitlength = 0
		}
		data = data[n:]
	}
	if len(data) >= CURR_BLOCK_SIZE {
		n := len(data) &~ (CURR_BLOCK_SIZE - 1)
		sha2_transf(ctx, data[:n])
		data = data[n:]
	}
	if len(data) > 0 {
		ctx.bitlength = u64(copy(ctx.block[:], data[:]))
	}
}

// final finalizes the Context, writes the digest to hash, and calls
// reset on the Context.
//
// Iff finalize_clone is set, final will work on a copy of the Context,
// which is useful for for calculating rolling digests.
final :: proc(ctx: ^$T, hash: []byte, finalize_clone: bool = false) {
	ensure(ctx.is_initialized)
	ensure(len(hash) * 8 >= ctx.md_bits, "crypto/sha2: invalid destination digest size")

	ctx := ctx
	if finalize_clone {
		tmp_ctx: T
		clone(&tmp_ctx, ctx)
		ctx = &tmp_ctx
	}
	defer(reset(ctx))

	length := ctx.length

	raw_pad: [BLOCK_SIZE_512]byte
	when T == Context_256 {
		CURR_BLOCK_SIZE :: BLOCK_SIZE_256
		pm_len := 8 // 64-bits for length
	} else when T == Context_512 {
		CURR_BLOCK_SIZE :: BLOCK_SIZE_512
		pm_len := 16 // 128-bits for length
	}
	pad := raw_pad[:CURR_BLOCK_SIZE]
	pad_len := u64(CURR_BLOCK_SIZE - pm_len)

	pad[0] = 0x80
	if length % CURR_BLOCK_SIZE < pad_len {
		update(ctx, pad[0:pad_len - length % CURR_BLOCK_SIZE])
	} else {
		update(ctx, pad[0:CURR_BLOCK_SIZE + pad_len - length % CURR_BLOCK_SIZE])
	}

	length_hi, length_lo := bits.mul_u64(length, 8) // Length in bits
	when T == Context_256 {
		_ = length_hi
		endian.unchecked_put_u64be(pad[:], length_lo)
		update(ctx, pad[:8])
	} else when T == Context_512 {
		endian.unchecked_put_u64be(pad[:], length_hi)
		endian.unchecked_put_u64be(pad[8:], length_lo)
		update(ctx, pad[0:16])
	}
	assert(ctx.bitlength == 0) // Check for bugs

	when T == Context_256 {
		for i := 0; i < ctx.md_bits / 32; i += 1 {
			endian.unchecked_put_u32be(hash[i * 4:], ctx.h[i])
		}
	} else when T == Context_512 {
		for i := 0; i < ctx.md_bits / 64; i += 1 {
			endian.unchecked_put_u64be(hash[i * 8:], ctx.h[i])
		}
	}
}

// clone clones the Context other into ctx.
clone :: proc(ctx, other: ^$T) {
	ctx^ = other^
}

// reset sanitizes the Context.  The Context must be re-initialized to
// be used again.
reset :: proc(ctx: ^$T) {
	if !ctx.is_initialized {
		return
	}

	mem.zero_explicit(ctx, size_of(ctx^))
}

/*
    SHA2 implementation
*/

@(private, rodata)
SHA256_K := [64]u32 {
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

@(private, rodata)
SHA512_K := [80]u64 {
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

@(private)
SHA256_ROUNDS :: 64
@(private)
SHA512_ROUNDS :: 80

@(private)
SHA256_CH :: #force_inline proc "contextless" (x, y, z: u32) -> u32 {
	return (x & y) ~ (~x & z)
}

@(private)
SHA256_MAJ :: #force_inline proc "contextless" (x, y, z: u32) -> u32 {
	return (x & y) ~ (x & z) ~ (y & z)
}

@(private)
SHA512_CH :: #force_inline proc "contextless" (x, y, z: u64) -> u64 {
	return (x & y) ~ (~x & z)
}

@(private)
SHA512_MAJ :: #force_inline proc "contextless" (x, y, z: u64) -> u64 {
	return (x & y) ~ (x & z) ~ (y & z)
}

@(private)
SHA256_F1 :: #force_inline proc "contextless" (x: u32) -> u32 {
	return bits.rotate_left32(x, 30) ~ bits.rotate_left32(x, 19) ~ bits.rotate_left32(x, 10)
}

@(private)
SHA256_F2 :: #force_inline proc "contextless" (x: u32) -> u32 {
	return bits.rotate_left32(x, 26) ~ bits.rotate_left32(x, 21) ~ bits.rotate_left32(x, 7)
}

@(private)
SHA256_F3 :: #force_inline proc "contextless" (x: u32) -> u32 {
	return bits.rotate_left32(x, 25) ~ bits.rotate_left32(x, 14) ~ (x >> 3)
}

@(private)
SHA256_F4 :: #force_inline proc "contextless" (x: u32) -> u32 {
	return bits.rotate_left32(x, 15) ~ bits.rotate_left32(x, 13) ~ (x >> 10)
}

@(private)
SHA512_F1 :: #force_inline proc "contextless" (x: u64) -> u64 {
	return bits.rotate_left64(x, 36) ~ bits.rotate_left64(x, 30) ~ bits.rotate_left64(x, 25)
}

@(private)
SHA512_F2 :: #force_inline proc "contextless" (x: u64) -> u64 {
	return bits.rotate_left64(x, 50) ~ bits.rotate_left64(x, 46) ~ bits.rotate_left64(x, 23)
}

@(private)
SHA512_F3 :: #force_inline proc "contextless" (x: u64) -> u64 {
	return bits.rotate_left64(x, 63) ~ bits.rotate_left64(x, 56) ~ (x >> 7)
}

@(private)
SHA512_F4 :: #force_inline proc "contextless" (x: u64) -> u64 {
	return bits.rotate_left64(x, 45) ~ bits.rotate_left64(x, 3) ~ (x >> 6)
}

@(private)
sha2_transf :: proc "contextless" (ctx: ^$T, data: []byte) #no_bounds_check {
	when T == Context_256 {
		if is_hardware_accelerated_256() {
			sha256_transf_hw(ctx, data)
			return
		}

		w: [SHA256_ROUNDS]u32
		wv: [8]u32
		t1, t2: u32

		CURR_BLOCK_SIZE :: BLOCK_SIZE_256
	} else when T == Context_512 {
		w: [SHA512_ROUNDS]u64
		wv: [8]u64
		t1, t2: u64

		CURR_BLOCK_SIZE :: BLOCK_SIZE_512
	}

	data := data
	for len(data) >= CURR_BLOCK_SIZE {
		for i in 0 ..< 16 {
			when T == Context_256 {
				w[i] = endian.unchecked_get_u32be(data[i * 4:])
			} else when T == Context_512 {
				w[i] = endian.unchecked_get_u64be(data[i * 8:])
			}
		}

		when T == Context_256 {
			for i in 16 ..< SHA256_ROUNDS {
				w[i] = SHA256_F4(w[i - 2]) + w[i - 7] + SHA256_F3(w[i - 15]) + w[i - 16]
			}
		} else when T == Context_512 {
			for i in 16 ..< SHA512_ROUNDS {
				w[i] = SHA512_F4(w[i - 2]) + w[i - 7] + SHA512_F3(w[i - 15]) + w[i - 16]
			}
		}

		for i in 0 ..< 8 {
			wv[i] = ctx.h[i]
		}

		when T == Context_256 {
			for i in 0 ..< SHA256_ROUNDS {
				t1 = wv[7] + SHA256_F2(wv[4]) + SHA256_CH(wv[4], wv[5], wv[6]) + SHA256_K[i] + w[i]
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
		} else when T == Context_512 {
			for i in 0 ..< SHA512_ROUNDS {
				t1 = wv[7] + SHA512_F2(wv[4]) + SHA512_CH(wv[4], wv[5], wv[6]) + SHA512_K[i] + w[i]
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

		for i in 0 ..< 8 {
			ctx.h[i] += wv[i]
		}

		data = data[CURR_BLOCK_SIZE:]
	}
}
