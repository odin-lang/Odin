package runtime

import "core:intrinsics"
import "core:math/bits"

// wyhash hash function (4.2, WYHASH_CONDOM=2)
//
// This was chosen as it:
//  - Produces high quality output
//  - Can include a non-seed dynamic-secret
//  - Has high performance on reasonable architectures
//  - Is simple in terms of implementation
//
// https://github.com/rurban/smhasher/blob/master/doc/wyhash.txt
//
// While wyhash32 exists, it is not recommended for use by the designer,
// and it would add complexity of having to worry about bad seeds.
// See: https://github.com/wangyi-fudan/wyhash/issues/92
//
// TODO/perf:
// - Someone should figure out if any supported OS runs AArch64 with
//   strict alignment enabled, and add `_wy_read_8`/`_wy_read_4`
//   fast-paths as appropriate.
// - WASM can also do direct reads, but performance is doomed to suck
//   on that architecture because the multiply is slow.

// This is free and unencumbered software released into the public domain
// under The Unlicense (http://unlicense.org/)
//
// main repo: https://github.com/wangyi-fudan/wyhash
// author: 王一 Wang Yi <godspeed_china@yeah.net>
// contributors: Reini Urban, Dietrich Epp, Joshua Haberman, Tommy Ettinger,
// Daniel Lemire, Otmar Ertl, cocowalla, leo-yuriev, Diego Barrios Romero,
// paulie-g, dumblob, Yann Collet, ivte-ms, hyb, James Z.M. Gao,
// easyaspi314 (Devin), TheOneric

Wyhash_Secret :: distinct [4]u64

_WYHASH_DEFAULT_SECRET := Wyhash_Secret{
	0x2d358dccaa6c78a5,
	0x8bb84b93962eacc9,
	0x4b33a62ed433d4a3,
	0x4d5a2da51de1aa47,
}

@(private)
_wy_wide_mul :: #force_inline proc "contextless" (A, B: u64) -> (u64, u64) {
	hi, lo := bits.mul_u64(A, B)

	// This is where the `WYHASH_CONDOM` parameter is applied for the
	// standard (aka 64-bit) variant.
	//
	// Per the author, a 64-bit x 64-bit -> 128-bit wide multiply is
	// "normal valid behavior", so we can save some cycles and just
	// return, however doing the extra mix step is cheap and provides
	// "extra protection against entropy loss (probability=2^-63)".
	//
	// https://github.com/wangyi-fudan/wyhash/issues/49

	return A ~ lo, B ~ hi
}

@(private)
_wy_mix :: #force_inline proc "contextless" (A, B: u64) ->u64 {
	lo, hi := _wy_wide_mul(A, B)
	return lo ~ hi
}

@(private)
_wy_read_8 :: #force_inline proc "contextless" (p: [^]byte, off: int = 0) -> u64 {
	pp := intrinsics.ptr_offset(p, off)
	when ODIN_ARCH == .i386 || ODIN_ARCH == .amd64 {
		return (transmute([^]u64)(pp))[0]
	} else {
		return u64(pp[0]) | u64(pp[1])<<8 | u64(pp[2])<<16 | u64(pp[3])<<24 |
		    u64(pp[4])<<32 | u64(pp[5])<<40 | u64(pp[6])<<48 | u64(pp[7])<<56
	}
}

@(private)
_wy_read_4 :: #force_inline proc "contextless" (p: [^]byte, off: int = 0) -> u64 {
	pp := intrinsics.ptr_offset(p, off)
	when ODIN_ARCH == .i386 || ODIN_ARCH == .amd64 {
		return u64((transmute([^]u32)(pp))[0])
	} else {
		return u64(pp[0]) | u64(pp[1])<<8 | u64(pp[2])<<16 | u64(pp[3])<<24
	}
}

@(private)
_wy_read_3 :: #force_inline proc "contextless" (p: [^]byte, k: int) -> u64 {
	// Invariants: k < 4, k > 0.
	//
	// k = 1: p[0] << 16 | p[0] << 8 | p[0]
	// k = 2: p[0] << 16 | p[1] << 8 | p[1]
	// k = 3: p[0] << 16 | p[1] << 8 | p[2]
	return ((u64(p[0])) << 16) | ((u64(p[k >> 1])) << 8) | u64(p[k - 1])
}

@(optimization_mode="speed")
_wyhash :: proc "contextless" (data: rawptr, n: int, seed: u64, secret: ^Wyhash_Secret) -> u64 {
	p := ([^]byte)(data)
	seed_ := seed ~ _wy_mix(seed ~ secret[0], secret[1])
	a, b: u64 = ---, ---

	if intrinsics.expect(n <= 16, true) {
		if intrinsics.expect(n >= 4, true) {
			a = (_wy_read_4(p) << 32) | _wy_read_4(p, (n >> 3) << 2)
			b = (_wy_read_4(p, n - 4) << 32) | _wy_read_4(p, n - 4 - ((n >> 3) <<2))
		} else if intrinsics.expect(n > 0, true) {
			a = _wy_read_3(p, n)
			b = 0
		} else {
			a, b = 0, 0
		}
	} else {
		i := n
		if intrinsics.expect(i >= 48, false) {
			see1, see2 := seed_, seed_
			for {
				seed_ = _wy_mix(_wy_read_8(p) ~ secret[1], _wy_read_8(p, 8) ~ seed_)
				see1 = _wy_mix(_wy_read_8(p, 16) ~ secret[2], _wy_read_8(p, 24) ~ see1)
				see2 = _wy_mix(_wy_read_8(p, 32) ~ secret[3], _wy_read_8(p, 40) ~ see2)

				p = intrinsics.ptr_offset(p, 48)
				i -= 48
				if intrinsics.expect(i < 48, false) {
					break
				}
			}
			seed_ ~= see1 ~ see2
		}
		for intrinsics.expect(i > 16, false) {
			seed_ = _wy_mix(_wy_read_8(p) ~ secret[1], _wy_read_8(p, 8) ~ seed_)
			i -= 16
			p = intrinsics.ptr_offset(p, 16)
		}
		a = _wy_read_8(p, i - 16)
		b = _wy_read_8(p, i - 8)
	}

	a ~= secret[1]
	b ~= seed_
	a, b = _wy_wide_mul(a, b)

	return _wy_mix(a ~ secret[0] ~ u64(n), b ~ secret[1])
}