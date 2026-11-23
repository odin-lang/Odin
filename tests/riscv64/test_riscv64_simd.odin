package test_riscv64

import "base:intrinsics"
import "core:math"
import "core:math/rand"
import "core:simd"
import "core:testing"

SIMD_ROUNDS :: 48

@(test) simd_lanes_u8x16  :: proc(t: ^testing.T) { check_int_lanes(t, u8,  u8,  16) }
@(test) simd_lanes_i8x16  :: proc(t: ^testing.T) { check_int_lanes(t, i8,  u8,  16) }
@(test) simd_lanes_u8x64  :: proc(t: ^testing.T) { check_int_lanes(t, u8,  u8,  64) }
@(test) simd_lanes_u16x8  :: proc(t: ^testing.T) { check_int_lanes(t, u16, u16, 8)  }
@(test) simd_lanes_i16x16 :: proc(t: ^testing.T) { check_int_lanes(t, i16, u16, 16) }
@(test) simd_lanes_u32x4  :: proc(t: ^testing.T) { check_int_lanes(t, u32, u32, 4)  }
@(test) simd_lanes_i32x8  :: proc(t: ^testing.T) { check_int_lanes(t, i32, u32, 8)  }
@(test) simd_lanes_u64x2  :: proc(t: ^testing.T) { check_int_lanes(t, u64, u64, 2)  }
@(test) simd_lanes_i64x4  :: proc(t: ^testing.T) { check_int_lanes(t, i64, u64, 4)  }
@(test) simd_lanes_i64x8  :: proc(t: ^testing.T) { check_int_lanes(t, i64, u64, 8)  }

@(test) simd_lanes_f32x4  :: proc(t: ^testing.T) { check_float_lanes(t, f32, u32, i32, 4)  }
@(test) simd_lanes_f32x16 :: proc(t: ^testing.T) { check_float_lanes(t, f32, u32, i32, 16) }
@(test) simd_lanes_f64x2  :: proc(t: ^testing.T) { check_float_lanes(t, f64, u64, i64, 2)  }
@(test) simd_lanes_f64x8  :: proc(t: ^testing.T) { check_float_lanes(t, f64, u64, i64, 8)  }

check_int_lanes :: proc(t: ^testing.T, $T, $U: typeid, $N: int) where intrinsics.type_is_integer(T), intrinsics.type_is_unsigned(U), size_of(T) == size_of(U) {
	BITS :: U(8 * size_of(T))
	EDGES :: [?]u64{
		0, 1, 2, 0x7f, 0x80, 0xff, 0x7fff, 0x8000, 0xffff, 0x7fff_ffff, 0x8000_0000, 0xffff_ffff,
		0x7fff_ffff_ffff_ffff, 0x8000_0000_0000_0000, 0xffff_ffff_ffff_ffff, 0x5555_5555_5555_5555,
	}
	edges := EDGES
	rand.reset(u64(N) << 16 | u64(size_of(T)) << 8 | u64(intrinsics.type_is_unsigned(T)))

	for round in 0..<SIMD_ROUNDS {
		a, b, w: [N]T
		s: [N]U
		m: [N]U
		for i in 0..<N {
			if round < 4 {
				a[i] = T(edges[(i + round) % len(edges)])
				b[i] = T(edges[(i * 3 + round * 5) % len(edges)])
			} else {
				a[i] = T(rand.uint64())
				b[i] = T(rand.uint64())
			}
			s[i] = U(rand.uint64() % u64(2 * BITS))
		}
		va, vb, vs := simd.from_array(a), simd.from_array(b), simd.from_array(s)
		ua, ub := transmute([N]U)a, transmute([N]U)b

		for i in 0..<N { w[i] = a[i] + b[i] }
		expect_lanes(t, "+", simd.to_array(va + vb), w, a, b)
		for i in 0..<N { w[i] = a[i] - b[i] }
		expect_lanes(t, "-", simd.to_array(va - vb), w, a, b)
		for i in 0..<N { w[i] = a[i] * b[i] }
		expect_lanes(t, "*", simd.to_array(va * vb), w, a, b)
		for i in 0..<N { w[i] = a[i] & b[i] }
		expect_lanes(t, "&", simd.to_array(va & vb), w, a, b)
		for i in 0..<N { w[i] = a[i] | b[i] }
		expect_lanes(t, "|", simd.to_array(va | vb), w, a, b)
		for i in 0..<N { w[i] = a[i] ~ b[i] }
		expect_lanes(t, "~", simd.to_array(va ~ vb), w, a, b)
		for i in 0..<N { w[i] = a[i] &~ b[i] }
		expect_lanes(t, "bit_and_not", simd.to_array(simd.bit_and_not(va, vb)), w, a, b)
		for i in 0..<N { w[i] = T(0) - a[i] }
		expect_lanes(t, "neg", simd.to_array(simd.neg(va)), w, a, b)
		for i in 0..<N {
			when intrinsics.type_is_unsigned(T) {
				w[i] = a[i]
			} else {
				w[i] = a[i] if a[i] >= 0 else T(0) - a[i]
			}
		}
		expect_lanes(t, "abs", simd.to_array(intrinsics.simd_abs(va)), w, a, b)
		for i in 0..<N { w[i] = min(a[i], b[i]) }
		expect_lanes(t, "min", simd.to_array(intrinsics.simd_min(va, vb)), w, a, b)
		for i in 0..<N { w[i] = max(a[i], b[i]) }
		expect_lanes(t, "max", simd.to_array(intrinsics.simd_max(va, vb)), w, a, b)
		for i in 0..<N { w[i] = saturating_add_ref(a[i], b[i]) }
		expect_lanes(t, "saturating_add", simd.to_array(simd.saturating_add(va, vb)), w, a, b)
		for i in 0..<N { w[i] = saturating_sub_ref(a[i], b[i]) }
		expect_lanes(t, "saturating_sub", simd.to_array(simd.saturating_sub(va, vb)), w, a, b)

		for i in 0..<N { w[i] = a[i] << s[i] }
		expect_lanes(t, "shl", simd.to_array(simd.shl(va, vs)), w, a, transmute([N]T)s)
		for i in 0..<N { w[i] = a[i] >> s[i] }
		expect_lanes(t, "shr", simd.to_array(simd.shr(va, vs)), w, a, transmute([N]T)s)
		for i in 0..<N { w[i] = a[i] << (s[i] & (BITS - 1)) }
		expect_lanes(t, "shl_masked", simd.to_array(simd.shl_masked(va, vs)), w, a, transmute([N]T)s)
		for i in 0..<N { w[i] = a[i] >> (s[i] & (BITS - 1)) }
		expect_lanes(t, "shr_masked", simd.to_array(simd.shr_masked(va, vs)), w, a, transmute([N]T)s)

		for i in 0..<N { m[i] = ~U(0) if a[i] == b[i] else 0 }
		expect_lanes(t, "lanes_eq", simd.to_array(simd.lanes_eq(va, vb)), m, ua, ub)
		for i in 0..<N { m[i] = ~U(0) if a[i] != b[i] else 0 }
		expect_lanes(t, "lanes_ne", simd.to_array(simd.lanes_ne(va, vb)), m, ua, ub)
		for i in 0..<N { m[i] = ~U(0) if a[i] < b[i] else 0 }
		lt := simd.lanes_lt(va, vb)
		expect_lanes(t, "lanes_lt", simd.to_array(lt), m, ua, ub)
		for i in 0..<N { m[i] = ~U(0) if a[i] <= b[i] else 0 }
		expect_lanes(t, "lanes_le", simd.to_array(simd.lanes_le(va, vb)), m, ua, ub)
		for i in 0..<N { m[i] = ~U(0) if a[i] > b[i] else 0 }
		expect_lanes(t, "lanes_gt", simd.to_array(simd.lanes_gt(va, vb)), m, ua, ub)
		for i in 0..<N { m[i] = ~U(0) if a[i] >= b[i] else 0 }
		ge := simd.lanes_ge(va, vb)
		expect_lanes(t, "lanes_ge", simd.to_array(ge), m, ua, ub)

		for i in 0..<N { w[i] = a[i] if a[i] < b[i] else b[i] }
		expect_lanes(t, "select", simd.to_array(simd.select(lt, va, vb)), w, a, b)

		msbs: bit_set[0..<N]
		for i in 0..<N {
			if U(a[i]) >> (BITS - 1) != 0 {
				msbs += {i}
			}
		}
		testing.expectf(t, simd.extract_msbs(va) == msbs, "extract_msbs %v x%v: got %v, want %v (a %v)", typeid_of(T), N, simd.extract_msbs(va), msbs, a)

		sum, prod, lo, hi, all_and, all_or, all_xor := T(0), T(1), a[0], a[0], ~T(0), T(0), T(0)
		for x in a {
			sum += x
			prod *= x
			lo = min(lo, x)
			hi = max(hi, x)
			all_and &= x
			all_or |= x
			all_xor ~= x
		}
		expect_scalar(t, "reduce_add_ordered", simd.reduce_add_ordered(va), sum, a)
		expect_scalar(t, "reduce_mul_ordered", simd.reduce_mul_ordered(va), prod, a)
		expect_scalar(t, "reduce_min", simd.reduce_min(va), lo, a)
		expect_scalar(t, "reduce_max", simd.reduce_max(va), hi, a)
		expect_scalar(t, "reduce_and", simd.reduce_and(va), all_and, a)
		expect_scalar(t, "reduce_or", simd.reduce_or(va), all_or, a)
		expect_scalar(t, "reduce_xor", simd.reduce_xor(va), all_xor, a)

		for i in 0..<N { w[i] = intrinsics.count_ones(a[i]) }
		expect_lanes(t, "count_ones", simd.to_array(simd.count_ones(va)), w, a, b)
		for i in 0..<N { w[i] = intrinsics.count_trailing_zeros(a[i]) }
		expect_lanes(t, "count_trailing_zeros", simd.to_array(simd.count_trailing_zeros(va)), w, a, b)
		for i in 0..<N { w[i] = intrinsics.count_leading_zeros(a[i]) }
		expect_lanes(t, "count_leading_zeros", simd.to_array(simd.count_leading_zeros(va)), w, a, b)
		for i in 0..<N { w[i] = intrinsics.reverse_bits(a[i]) }
		expect_lanes(t, "reverse_bits", simd.to_array(simd.reverse_bits(va)), w, a, b)

		for i in 0..<N { w[i] = a[N - 1 - i] }
		expect_lanes(t, "lanes_reverse", simd.to_array(simd.lanes_reverse(va)), w, a, b)
		for i in 0..<N { w[i] = a[(i + 1) % N] }
		expect_lanes(t, "lanes_rotate_left", simd.to_array(simd.lanes_rotate_left(va, 1)), w, a, b)
		for i in 0..<N { w[i] = a[(i + N - 1) % N] }
		expect_lanes(t, "lanes_rotate_right", simd.to_array(simd.lanes_rotate_right(va, 1)), w, a, b)
		for i in 0..<N { w[i] = b[i] if i % 2 == 0 else a[i] }
		expect_lanes(t, "odd_even", simd.to_array(simd.odd_even(va, vb)), w, a, b)
		for i in 0..<N { w[i] = a[i] + b[i] if i % 2 == 1 else a[i] - b[i] }
		expect_lanes(t, "add_sub", simd.to_array(simd.add_sub(va, vb)), w, a, b)

		idx := uint(round % N)
		expect_scalar(t, "extract", simd.extract(va, idx), a[idx], a)
		w = a
		w[idx] = b[0]
		expect_lanes(t, "replace", simd.to_array(simd.replace(va, idx, b[0])), w, a, b)

		stored := b
		intrinsics.simd_masked_store(&stored, va, lt)
		for i in 0..<N { w[i] = a[i] if a[i] < b[i] else b[i] }
		expect_lanes(t, "masked_store", stored, w, a, b)
		for i in 0..<N { w[i] = a[i] if a[i] >= b[i] else b[i] }
		expect_lanes(t, "masked_load", simd.to_array(intrinsics.simd_masked_load(&a, vb, ge)), w, a, b)

		ptrs: [N]rawptr
		for i in 0..<N {
			j := (i * 3 + round) % N
			ptrs[i] = &b[j]
			w[i] = b[j] if a[i] >= b[i] else a[i]
		}
		expect_lanes(t, "gather", simd.to_array(intrinsics.simd_gather(simd.from_array(ptrs), va, ge)), w, a, b)

		wide: [N]i64
		for i in 0..<N { wide[i] = i64(a[i]) }
		testing.expectf(t, simd.to_array(cast(#simd[N]i64)va) == wide, "cast i64 %v x%v: got %v, want %v", typeid_of(T), N, simd.to_array(cast(#simd[N]i64)va), wide)
		narrow: [N]u8
		for i in 0..<N { narrow[i] = u8(a[i]) }
		testing.expectf(t, simd.to_array(cast(#simd[N]u8)va) == narrow, "cast u8 %v x%v: got %v, want %v", typeid_of(T), N, simd.to_array(cast(#simd[N]u8)va), narrow)
		fl: [N]f64
		for i in 0..<N { fl[i] = f64(a[i]) }
		vf := cast(#simd[N]f64)va
		testing.expectf(t, simd.to_array(vf) == fl, "cast f64 %v x%v: got %v, want %v (a %v)", typeid_of(T), N, simd.to_array(vf), fl, a)
		when size_of(T) <= 4 {
			expect_lanes(t, "f64 round trip", simd.to_array(cast(#simd[N]T)vf), a, a, b)
		}
	}
}

check_float_lanes :: proc(t: ^testing.T, $T, $U, $I: typeid, $N: int) where intrinsics.type_is_float(T), size_of(T) == size_of(U), size_of(T) == size_of(I) {
	edges := [?]T{0, -0.0, 1, -1, 0.5, 1.5, 2.5, -2.5, -0.5, 3, 1e30, -1e-30, 0, 0, 1.0 / 3.0, 1e-40}
	edges[12] = T(math.inf_f64(1))
	edges[13] = T(math.inf_f64(-1))
	when T == f32 {
		nans := [2]U{0x7fc0_0000, 0x7fa0_0001}
	} else {
		nans := [2]U{0x7ff8_0000_0000_0000, 0x7ff4_0000_0000_0001}
	}
	rand.reset(u64(N) << 16 | u64(size_of(T)) << 8 | 0x40)

	for round in 0..<SIMD_ROUNDS {
		a, b, c, w: [N]T
		for i in 0..<N {
			switch {
			case round < 4:
				a[i] = edges[(i + round) % len(edges)]
				b[i] = edges[(i * 3 + round * 5) % len(edges)]
				c[i] = edges[(i * 7 + round) % len(edges)]
			case round < 8:
				a[i] = transmute(T)U(rand.uint64())
				b[i] = transmute(T)U(rand.uint64())
				c[i] = transmute(T)U(rand.uint64())
			case:
				a[i] = T(rand.float64_range(-1000, 1000))
				b[i] = T(rand.float64_range(-1000, 1000))
				c[i] = T(rand.float64_range(-1000, 1000))
			}
		}
		if round == 1 {
			a[0] = transmute(T)nans[0]
			b[N - 1] = transmute(T)nans[1]
		}
		va, vb, vc := simd.from_array(a), simd.from_array(b), simd.from_array(c)

		for i in 0..<N { w[i] = a[i] + b[i] }
		expect_floats(t, "+", simd.to_array(va + vb), w, a, b, U)
		for i in 0..<N { w[i] = a[i] - b[i] }
		expect_floats(t, "-", simd.to_array(va - vb), w, a, b, U)
		for i in 0..<N { w[i] = a[i] * b[i] }
		expect_floats(t, "*", simd.to_array(va * vb), w, a, b, U)
		for i in 0..<N { w[i] = a[i] / b[i] }
		expect_floats(t, "/", simd.to_array(va / vb), w, a, b, U)
		for i in 0..<N { w[i] = math.sqrt(a[i]) }
		expect_floats(t, "sqrt", simd.to_array(simd.sqrt(va)), w, a, b, U)
		for i in 0..<N { w[i] = intrinsics.fused_mul_add(a[i], b[i], c[i]) }
		expect_floats(t, "fma", simd.to_array(simd.fma(va, vb, vc)), w, a, b, U)
		for i in 0..<N { w[i] = intrinsics.fused_mul_add(a[i], b[i], c[i] if i % 2 == 1 else -c[i]) }
		expect_floats(t, "fused_mul_add_sub", simd.to_array(simd.fused_mul_add_sub(va, vb, vc)), w, a, b, U)
		for i in 0..<N { w[i] = intrinsics.fused_mul_add(a[i], b[i], -c[i] if i % 2 == 1 else c[i]) }
		expect_floats(t, "fused_mul_sub_add", simd.to_array(simd.fused_mul_sub_add(va, vb, vc)), w, a, b, U)
		for i in 0..<N { w[i] = math.ceil(a[i]) }
		expect_floats(t, "ceil", simd.to_array(intrinsics.simd_ceil(va)), w, a, b, U)
		for i in 0..<N { w[i] = math.floor(a[i]) }
		expect_floats(t, "floor", simd.to_array(intrinsics.simd_floor(va)), w, a, b, U)
		for i in 0..<N { w[i] = math.trunc(a[i]) }
		expect_floats(t, "trunc", simd.to_array(intrinsics.simd_trunc(va)), w, a, b, U)
		for i in 0..<N { w[i] = nearest_even_ref(a[i]) }
		expect_floats(t, "nearest", simd.to_array(simd.nearest(va)), w, a, b, U)

		ua, ub := transmute([N]U)a, transmute([N]U)b
		sign :: U(1) << (8 * size_of(U) - 1)
		bits: [N]U
		for i in 0..<N { bits[i] = ua[i] ~ sign }
		expect_lanes(t, "neg bits", simd.to_array(simd.to_bits(simd.neg(va))), bits, ua, ub)
		for i in 0..<N { bits[i] = ua[i] &~ sign }
		expect_lanes(t, "abs bits", simd.to_array(simd.to_bits(intrinsics.simd_abs(va))), bits, ua, ub)
		for i in 0..<N { bits[i] = (ua[i] &~ sign) | (ub[i] & sign) }
		expect_lanes(t, "copysign bits", simd.to_array(simd.to_bits(simd.copysign(va, vb))), bits, ua, ub)
		expect_lanes(t, "to_bits", simd.to_array(simd.to_bits(va)), ua, ua, ub)

		m: [N]U
		for i in 0..<N { m[i] = ~U(0) if a[i] == b[i] else 0 }
		expect_lanes(t, "lanes_eq", simd.to_array(simd.lanes_eq(va, vb)), m, ua, ub)
		for i in 0..<N { m[i] = ~U(0) if a[i] != b[i] else 0 }
		expect_lanes(t, "lanes_ne", simd.to_array(simd.lanes_ne(va, vb)), m, ua, ub)
		for i in 0..<N { m[i] = ~U(0) if a[i] < b[i] else 0 }
		lt := simd.lanes_lt(va, vb)
		expect_lanes(t, "lanes_lt", simd.to_array(lt), m, ua, ub)
		for i in 0..<N { m[i] = ~U(0) if a[i] <= b[i] else 0 }
		expect_lanes(t, "lanes_le", simd.to_array(simd.lanes_le(va, vb)), m, ua, ub)
		for i in 0..<N { m[i] = ~U(0) if a[i] > b[i] else 0 }
		expect_lanes(t, "lanes_gt", simd.to_array(simd.lanes_gt(va, vb)), m, ua, ub)
		for i in 0..<N { m[i] = ~U(0) if a[i] >= b[i] else 0 }
		expect_lanes(t, "lanes_ge", simd.to_array(simd.lanes_ge(va, vb)), m, ua, ub)

		for i in 0..<N { w[i] = a[i] if a[i] < b[i] else b[i] }
		expect_floats(t, "select", simd.to_array(simd.select(lt, va, vb)), w, a, b, U)

		finite := true
		for i in 0..<N {
			if math.is_nan(a[i]) || math.is_inf(a[i]) {
				finite = false
			}
		}
		if finite {
			sum := T(0)
			for x in a {
				sum += x
			}
			expect_floats(t, "reduce_add_ordered", [1]T{simd.reduce_add_ordered(va)}, [1]T{sum}, [1]T{a[0]}, [1]T{a[N - 1]}, U)
		}

		widened: [N]f64
		for i in 0..<N { widened[i] = f64(a[i]) }
		expect_floats(t, "cast f64", simd.to_array(cast(#simd[N]f64)va), widened, widened, widened, u64)
		narrowed: [N]f32
		for i in 0..<N { narrowed[i] = f32(a[i]) }
		expect_floats(t, "cast f32", simd.to_array(cast(#simd[N]f32)va), narrowed, narrowed, narrowed, u32)

		ints: [N]I
		in_range: [N]T
		for i in 0..<N {
			in_range[i] = math.trunc(T(rand.float64_range(-30000, 30000)))
			ints[i] = I(in_range[i])
		}
		vi := cast(#simd[N]I)simd.from_array(in_range)
		testing.expectf(t, simd.to_array(vi) == ints, "cast %v x%v: got %v, want %v", typeid_of(I), N, simd.to_array(vi), ints)
	}
}

saturating_add_ref :: proc(x, y: $T) -> T {
	r, overflow := intrinsics.overflow_add(x, y)
	if !overflow {
		return r
	}
	when intrinsics.type_is_unsigned(T) {
		return max(T)
	} else {
		return max(T) if y > 0 else min(T)
	}
}

saturating_sub_ref :: proc(x, y: $T) -> T {
	r, overflow := intrinsics.overflow_sub(x, y)
	if !overflow {
		return r
	}
	when intrinsics.type_is_unsigned(T) {
		return 0
	} else {
		return max(T) if y < 0 else min(T)
	}
}

nearest_even_ref :: proc(x: $T) -> T {
	if math.is_nan(x) || math.is_inf(x) {
		return x
	}
	r := math.floor(x)
	d := x - r
	if d > 0.5 || (d == 0.5 && math.mod(r, 2) != 0) {
		r += 1
	}
	return math.copy_sign(r, x)
}

expect_lanes :: proc(t: ^testing.T, op: string, got, want, a, b: [$N]$T, loc := #caller_location) {
	if got != want {
		testing.expectf(t, false, "%v %v x%v: got %v, want %v (a %v, b %v)", op, typeid_of(T), N, got, want, a, b, loc = loc)
	}
}

expect_scalar :: proc(t: ^testing.T, op: string, got, want: $T, a: [$N]T, loc := #caller_location) {
	if got != want {
		testing.expectf(t, false, "%v %v x%v: got %v, want %v (a %v)", op, typeid_of(T), N, got, want, a, loc = loc)
	}
}

expect_floats :: proc(t: ^testing.T, op: string, got, want, a, b: [$N]$T, $U: typeid, loc := #caller_location) {
	for i in 0..<N {
		same := math.is_nan(want[i]) ? math.is_nan(got[i]) : transmute(U)got[i] == transmute(U)want[i]
		if !same {
			testing.expectf(t, false, "%v %v x%v lane %v: got %v (%x), want %v (%x) (a %v, b %v)", op, typeid_of(T), N, i, got[i], transmute(U)got[i], want[i], transmute(U)want[i], a[i], b[i], loc = loc)
		}
	}
}
