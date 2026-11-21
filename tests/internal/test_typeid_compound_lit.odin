package test_internal

import "core:container/small_array"
import "core:testing"

@(private="file")
Box :: struct($T: typeid) {
	x: T,
}

@(private="file")
Pair :: struct($K, $V: typeid) {
	k: K,
	v: V,
}

@(private="file")
Poly_Union :: union($T: typeid) {
	T,
}

@(private="file")
Typeid_Holder :: struct {
	t: typeid,
}

@(private="file")
Typeid_Index :: enum {
	A,
	B,
}

@(private="file")
CONST_ARRAY :: [2]typeid{Box(int), Pair(int, f32)}

@(private="file")
CONST_STRUCT :: Typeid_Holder{Box(u8)}

@(private="file")
poly_typeids :: proc($T: typeid) -> [2]typeid {
	return [2]typeid{T, Box(T)}
}

@(test)
typeid_compound_lit_poly_record :: proc(t: ^testing.T) {
	box_int  := typeid_of(Box(int))
	pair     := typeid_of(Pair(int, f32))
	sa       := typeid_of(small_array.Small_Array(4, int))
	poly_u   := typeid_of(Poly_Union(int))

	a := [1]typeid{Box(int)}
	testing.expect_value(t, a[0], box_int)

	b := []typeid{Pair(int, f32)}
	testing.expect_value(t, b[0], pair)

	c := Typeid_Holder{Box(int)}
	testing.expect_value(t, c.t, box_int)

	d := Typeid_Holder{t = Poly_Union(int)}
	testing.expect_value(t, d.t, poly_u)

	e := [Typeid_Index]typeid{.A = Box(int), .B = small_array.Small_Array(4, int)}
	testing.expect_value(t, e[.A], box_int)
	testing.expect_value(t, e[.B], sa)

	f := [3]typeid{1 = Box(int)}
	testing.expect_value(t, f[1], box_int)

	g := [?]typeid{int, Pair(int, f32)}
	testing.expect_value(t, g[1], pair)

	h := #soa[1]Typeid_Holder{{Box(int)}}
	testing.expect_value(t, h[0].t, box_int)

	k := CONST_ARRAY
	testing.expect_value(t, k[0], box_int)
	testing.expect_value(t, k[1], pair)

	l := CONST_STRUCT
	testing.expect_value(t, l.t, typeid_of(Box(u8)))

	m := poly_typeids(f64)
	testing.expect_value(t, m[0], f64)
	testing.expect_value(t, m[1], typeid_of(Box(f64)))
}

@(test)
typeid_compound_lit_type_directive :: proc(t: ^testing.T) {
	a := [3]typeid{#type proc(int), #type proc "c" (int), #type []int}
	testing.expect_value(t, a[0], typeid_of(proc(int)))
	testing.expect_value(t, a[1], typeid_of(proc "c" (int)))
	testing.expect_value(t, a[2], []int)
}
