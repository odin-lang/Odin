// Tests for the constant time RSA primitives
package test_core_crypto_bigint

// import    "base:builtin"
// import    "base:runtime"
// import ct "core:crypto/_bigint"
// import    "core:log"
// import    "core:testing"

/*

make_rand :: proc($T: typeid, n: int) -> (res: []T) {
	res = make([]T, n, context.temp_allocator)
	ok := runtime.random_generator_read_ptr(context.random_generator, raw_data(res), uint(n * size_of(T)))
	assert(ok, "uninitialized gen/context.random_generator")
	return
}

@(test)
ct_not :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	arr := make_rand(u32, ROUNDS)

	for v in arr {
		testing.expect_value(t, ct.not(v), v ~ 1)
	}
}

@(test)
ct_mux :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	arr := make_rand([2]u32, ROUNDS)

	for v in arr {
		testing.expect_value(t, ct.mux(1, v.x, v.y), v.x)
		testing.expect_value(t, ct.mux(0, v.x, v.y), v.y)
	}
}

@(test)
ct_u32_cmp :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	arr := make_rand([2]u32, ROUNDS)

	for &v in arr {
		testing.expect_value(t, ct.cmp(v.x, v.y), -1 if v.x < v.y else 0 if v.x == v.y else +1)
	}
}

@(test)
ct_u32_minmax :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	arr := make_rand([2]u32, ROUNDS)

	for &v in arr {
		testing.expect_value(t, ct.min(v.x, v.y), builtin.min(v.x, v.y))
		testing.expect_value(t, ct.max(v.x, v.y), builtin.max(v.x, v.y))
	}
}

@(test)
ct_u32_eq :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	arr := make_rand([2]u32, ROUNDS)

	for &v in arr {
		for op in 0..=2 {
			testing.expect_value(t, ct.eq (v.x, v.y), 1 if v.x == v.y else 0)
			testing.expect_value(t, ct.neq(v.x, v.y), 0 if v.x == v.y else 1)

			switch op {
			case 1: v.x += 1
			case 2: v.x = v.y
			case:
			}
		}
	}
}

@(test)
ct_u32_gte :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	arr := make_rand([2]u32, ROUNDS)

	for &v in arr {
		for op in 0..=2 {
			testing.expect_value(t, ct.gt (v.x, v.y), 1 if v.x  > v.y else 0)
			testing.expect_value(t, ct.ge (v.x, v.y), 1 if v.x >= v.y else 0)

			switch op {
			case 1: v.x += 1
			case 2: v.x = v.y
			case:
			}
		}
	}
}

@(test)
ct_u32_lte :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	arr := make_rand([2]u32, ROUNDS)

	for &v in arr {
		for op in 0..=2 {
			testing.expect_value(t, ct.lt (v.x, v.y), 1 if v.x  < v.y else 0)
			testing.expect_value(t, ct.le (v.x, v.y), 1 if v.x <= v.y else 0)

			switch op {
			case 1: v.x += 1
			case 2: v.x = v.y
			case:
			}
		}
	}
}

@(test)
ct_i32_eq0 :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	arr := make_rand([2]i32, ROUNDS)

	for &v in arr {
		for op in 0..=3 {
			testing.expect_value(t, ct.eq0(v.x), 1 if v.x == 0 else 0)
			testing.expect_value(t, ct.eq0(v.y), 1 if v.y == 0 else 0)

			switch op {
			case 1: v.x += 1
			case 2: v.x = -v.x; v.y = -v.y
			case 3: v.x = 0; v.y = 0
			case:
			}
		}
	}
}

@(test)
ct_i32_gte0 :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	arr := make_rand([2]i32, ROUNDS)

	for &v in arr {
		for op in 0..=2 {
			testing.expect_value(t, ct.gt0(v.x), 1 if v.x  > 0 else 0)
			testing.expect_value(t, ct.gt0(v.y), 1 if v.y  > 0 else 0)
			testing.expect_value(t, ct.ge0(v.x), 1 if v.x >= 0 else 0)
			testing.expect_value(t, ct.ge0(v.y), 1 if v.y >= 0 else 0)

			switch op {
			case 1: v.x = -v.x; v.y = -v.y
			case 2: v.x = 0; v.y = 0
			case:
			}
		}
	}
}

@(test)
ct_i32_lte0 :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	arr := make_rand([2]i32, ROUNDS)

	for &v in arr {
		for op in 0..=2 {
			testing.expect_value(t, ct.lt0(v.x), 1 if v.x  < 0 else 0)
			testing.expect_value(t, ct.lt0(v.y), 1 if v.y  < 0 else 0)
			testing.expect_value(t, ct.le0(v.x), 1 if v.x <= 0 else 0)
			testing.expect_value(t, ct.le0(v.y), 1 if v.y <= 0 else 0)

			switch op {
			case 1: v.x = -v.x; v.y = -v.y
			case 2: v.x = 0; v.y = 0
			case:
			}
		}
	}
}

@(test)
mul_primitives :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	arr := make_rand([2]u32, ROUNDS)

	for v in arr {
		hw_64 := u64(v.x) * u64(v.y)
		testing.expect_value(t, ct.hw_mul31   (v.x, v.y), hw_64)
		testing.expect_value(t, ct.hw_mul31_lo(v.x, v.y), u32(hw_64) & ct.I31_MASK)

		// sw_mul expects i31 with the top bit unset
		x := v.x & ct.I31_MASK
		y := v.y & ct.I31_MASK
		hw_64  = ct.hw_mul31(x, y)
		sw_64 := ct.sw_mul31(x, y)
		testing.expect_value(t, sw_64, hw_64)

		if sw_64 != hw_64 {
			log.infof("x: %v, y: %v, hw_64: %v, sw_mul31: %v", x, y, hw_64, sw_64)
			assert(false)
		}

		hw_31_lo := (x * y) & ct.I31_MASK
		sw_31_lo := ct.sw_mul31_lo(x, y)

		testing.expect_value(t, sw_31_lo, hw_31_lo)

		if sw_31_lo != hw_31_lo {
			log.infof("x: %v, y: %v, hw_64: %v, sw_mul31_lo: %v", x, y, hw_31_lo, sw_31_lo)
			assert(false)
		}
	}
}
*/
