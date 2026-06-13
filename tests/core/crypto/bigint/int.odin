// Tests for the constant time RSA primitives
package test_core_crypto_bigint

import "base:runtime"
import "core:crypto/_bigint"
import "core:log"
import "core:slice"
import "core:testing"

ROUNDS :: 100_000

i31_equal :: proc(a, b: []u32) -> bool {
	if a[0] != b[0] { return false }

	bits := uint(a[0])
	idx := 1
	for bits > 0 {
		ex   := min(bits, 31)
		mask := u32(1<<ex) - 1

		if a[idx] & mask != b[idx] & mask { return false }

		bits -= ex
		idx += 1
	}
	return true
}

@(test)
i31_is_zero :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	arr := make([][5]u32, ROUNDS, context.temp_allocator)
	for i in 0..<len(arr) {
		_bigint.i31_mkrand(arr[i][:], u32((len(arr[i])-1) * 32))
	}

	for &v in arr {
		v[0] = _bigint.i31_bit_length(v[1:])
		sum: u64
		for w in v[1:] {
			sum += u64(w)
		}
		testing.expect_value(t, _bigint.i31_is_zero(v[:]), 1 if sum == 0 else 0)

		slice.zero(v[1:])
		testing.expect_value(t, _bigint.i31_is_zero(v[:]), 1)
	}
}

@(test)
i31_add :: proc(t: ^testing.T) {
	N :: 5
	res: [N]u32

	for v in i31_add_test_vectors {
		if len(v.a) > N || len(v.b) > N || len(v.res) > N {
			log.infof("Skipped %v, not enough scratch space", v)
			continue
		}
		if !(len(v.a) == len(v.b) && len(v.b) == len(v.res)) {
			log.infof("Skipped %v, expected `a`, `b` and `res` lengths to be equal", v)
			continue
		}

		// Copy into writable memory
		copy(res[:], v.a[:])

		// Add b to "a" in place
		cc := _bigint.i31_add(res[:], v.b[:], 1)

		testing.expect(t, slice.equal(res[:len(v.res)], v.res))
		testing.expect_value(t, cc, v.carry)
	}
}

@(test)
i31_sub :: proc(t: ^testing.T) {
	N :: 5
	res: [N]u32

	for v in i31_sub_test_vectors {
		if len(v.a) > N || len(v.b) > N || len(v.res) > N {
			log.infof("Skipped %v, not enough scratch space", v)
			continue
		}
		if !(len(v.a) == len(v.b) && len(v.b) == len(v.res)) {
			log.infof("Skipped %v, expected `a`, `b` and `res` lengths to be equal", v)
			continue
		}

		// Copy into writable memory
		copy(res[:], v.a[:])

		// Add b to "a" in place
		cc := _bigint.i31_sub(res[:], v.b[:], 1)

		testing.expect(t, slice.equal(res[:len(v.res)], v.res))
		testing.expect_value(t, cc, v.carry)
	}
}

@(test)
i31_bit_length :: proc (t: ^testing.T) {
	for v in i31_add_test_vectors {
		a_len := _bigint.i31_bit_length(v.a[1:])
		b_len := _bigint.i31_bit_length(v.b[1:])

		testing.expect_value(t, a_len, v.a[0])
		testing.expect_value(t, b_len, v.b[0])
	}
}

@(test)
i31_decode :: proc(t: ^testing.T) {
	N :: 10
	res: [N]u32

	mod := []u32{42, 0x7fff_fffe, 0x3ff, 0}

	for v in i31_decode_test_vectors {
		if len(v.decode) > N || len(v.mod) > N {
			log.infof("Skipped %v, not enough scratch space", v)
			continue
		}

		_bigint.i31_decode(res[:], v.src)
		testing.expect(t, slice.equal(res[:len(v.decode)], v.decode))

		slice.zero(res[:])

		mod_res := _bigint.i31_decode_mod(res[:], v.src, mod)
		testing.expect(t, slice.equal(res[:len(v.mod)], v.mod))
		testing.expect_value(t, mod_res, v.mod_res)

		encoded: [32]u8 = 0
		_bigint.i31_encode(encoded[:], v.decode)
		testing.expect(t, slice.equal(encoded[32 - len(v.src):], v.src))
	}
}

@(test)
i31_rshift :: proc(t: ^testing.T) {
	N :: 4
	res: [N]u32
	for v in i31_rshift_test_vectors {
		if len(v.orig) > N || len(v.res) > N {
			log.infof("Skipped %v, not enough scratch space", v)
			continue
		}

		if v.shift < 0 || v.shift > 31 {
			log.infof("Skipped %v, invalid shift amount", v)
			continue
		}

		copy(res[:], v.orig)
		_bigint.i31_rshift(res[:], v.shift)
		testing.expect(t, slice.equal(res[:len(v.res)], v.res))
	}
}

@(test)
i31_reduce :: proc(t: ^testing.T) {
	N :: 12
	res: [N]u32 = ---
	mod := []u32{42, 0x7fff_fffe, 0x3ff, 0}

	for v in i31_reduce_test_vectors {
		if len(v.orig) > N || len(v.res) > N {
			log.infof("Skipped %v, not enough scratch space", v)
			continue
		}

		slice.zero(res[:])
		_bigint.i31_reduce(res[:], v.orig, mod)
		testing.expect(t, i31_equal(res[:], v.res))
	}
}

@(test)
i31_decode_reduce :: proc(t: ^testing.T) {
	N :: 4
	res: [N]u32 = 0
	mod := []u32{42, 0x7fff_fffe, 0x3ff, 0}

	for v in i31_decode_reduce_test_vectors {
		if len(v.decode) > N {
			log.infof("Skipped %v, not enough scratch space", v)
			continue
		}

		res = 0
		_bigint.i31_decode_reduce(res[:], v.src, mod)
		testing.expect(t, i31_equal(res[:], v.decode))
	}
}

@(test)
i31_muladd_small :: proc(t: ^testing.T) {
	mod := []u32{42, 0x7fff_fffe, 0x3ff, 0}

	for v in i31_mul_add_test_vectors {
		if len(v.orig) > len(mod) || len(v.res) > len(mod) {
			log.infof("Skipped %v, not enough scratch space", v)
			continue
		}

		res: [3]u32 = 0
		copy(res[:], v.orig)

		_bigint.i31_muladd_small(res[:], v.z, mod)
		l := len(v.res)
		testing.expect(t, slice.equal(res[:l], v.res[:l]))
	}
}

@(test)
i31_encode :: proc(t: ^testing.T) {
	for v in i31_encode_test_vectors {
		decoded: [10]u32 = 0
		_bigint.i31_decode(decoded[:], v.encoded)

		l := len(v.orig)
		testing.expect(t, slice.equal(decoded[:l], v.orig[:l]))

		encoded: [32]u8 = 0
		_bigint.i31_encode(encoded[:], v.orig)

		testing.expect(t, slice.equal(encoded[:], v.encoded))
	}
}

@(test)
i31_monty_mul :: proc(t: ^testing.T) {
	for v in i31_monty_mul_test_vectors {
		res: [6]u32 = 0

		m0i := _bigint.i31_ninv31(v.m[1])
		if m0i == 0 {
			log.infof("Expected _bigint.i31_ninv31(%v) to not be 0, m[1] must be even. Skipped.", v.m[1])
			continue
		}

		_bigint.i31_montymul(res[:], v.x, v.y, v.m, m0i)
		testing.expect(t, slice.equal(res[:], v.res))
	}
}

@(test)
i31_to_monty :: proc(t: ^testing.T) {
	for v in i31_to_monty_test_vectors {
		res: [6]u32 = 0
		copy(res[:], v.orig)

		_bigint.i31_to_monty(res[:], v.m)
		testing.expect(t, slice.equal(res[:], v.x))

		m0i := _bigint.i31_ninv31(v.m[1])
		if m0i == 0 {
			log.infof("Expected _bigint.i31_ninv31(%v) to not be 0, m[1] must be even. Skipped.", v.m[1])
			continue
		}

		_bigint.i31_from_monty(res[:], v.m, m0i)
		testing.expect(t, slice.equal(res[:], v.orig))
	}
}

@(test)
i31_modpow :: proc(t: ^testing.T) {
	for v in i31_mod_pow_test_vectors {
		x_out: [6]u32
		temp:  [100]u32

		copy(x_out[:], v.orig)

		m0i := _bigint.i31_ninv31(v.m[1])
		assert(m0i != 0)
		_bigint.i31_modpow(x_out[:], v.e, v.m, m0i, temp[:6], temp[6:][:6])

		testing.expect(t, slice.equal(x_out[:], v.x))
	}
}

@(test)
i31_mulacc :: proc(t: ^testing.T) {
	for v in i31_mul_acc_test_vectors {
		res: [12]u32 = 0
		copy(res[:], v.d)

		assert(v.d[0] == v.a[0])

		_bigint.i31_mulacc(res[:], v.a, v.b)

		testing.expect(t, slice.equal(res[:], v.res))
	}
}

@(test)
internal_div_rem_u32 :: proc(t: ^testing.T) {
	for v in i31_div_rem_test_vectors {
		den := u64(v.hi) << 32 + u64(v.lo)
		res := u64(v.quo) * u64(v.div) + u64(v.rem)
		assert(den == res)

		quo, rem := _bigint.div_rem_u32(v.hi, v.lo, v.div)
		testing.expect_value(t, quo, v.quo)
		testing.expect_value(t, rem, v.rem)
	}
}
