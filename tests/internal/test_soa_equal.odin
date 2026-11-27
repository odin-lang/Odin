package test_internal

import "base:intrinsics"
import "core:testing"

@(private="file")
Q :: struct {
	a, b: i32,
	f:    f32,
}

#assert(intrinsics.type_is_comparable(#soa[4]Q))
#assert(intrinsics.type_is_comparable(#soa[4][3]f32))
#assert(!intrinsics.type_is_comparable(#soa[]Q))
#assert(!intrinsics.type_is_comparable(#soa[dynamic]Q))
#assert(!intrinsics.type_is_comparable(#soa[dynamic; 4]Q))

// `#soa[N]T` compares its elements, as `[N]T` does
@(test)
test_soa_fixed_equal :: proc(t: ^testing.T) {
	a, b: #soa[4]Q
	testing.expect(t, a == b)
	a[2] = {1, 2, 3}
	testing.expect(t, a != b)
	b[2] = {1, 2, 3}
	testing.expect(t, a == b)

	// Fields are compared as their types are
	a.f[0] = -0.0
	testing.expect(t, a == b)

	l1, l2: #soa[3][2]f32
	l1[1] = {1, 2}
	testing.expect(t, l1 != l2)

	m: map[#soa[2]Q]int
	defer delete(m)
	k1, k2: #soa[2]Q
	k1[1] = {3, 4, 5}
	k2[1] = {3, 4, 5}
	m[k1] = 7
	testing.expect_value(t, m[k2], 7)
}

// The padding between the columns of `#soa[N]T` is not compared, even when the elements could be compared as bytes
@(test)
test_soa_fixed_equal_padding :: proc(t: ^testing.T) {
	I :: struct {
		a, b: i32,
	}
	T :: #soa[1024]I
	#assert(offset_of(T, b) > offset_of(T, a) + 1024*size_of(i32))

	a, b := new(T), new(T)
	defer free(a)
	defer free(b)
	a[1023] = {1, 2}
	b[1023] = {1, 2}

	bytes := ([^]u8)(a)
	bytes[offset_of(T, b) - 1] = 0xff
	testing.expect(t, a^ == b^)
}
