// Tests "core:reflect/reflect".
package test_core_reflect

import "base:intrinsics"
import "core:reflect"
import "core:testing"

@test
test_as_u64 :: proc(t: ^testing.T) {
	{
		/* i8 */
		Datum :: struct { i: int, v: i8, e: u64 }
		@static data := []Datum{
			{ 0, 0x7F, 0x7F },
			{ 1, -1, 0xFFFF_FFFF_FFFF_FFFF },
			{ 2, -0x80, 0xFFFF_FFFF_FFFF_FF80 },
		}

		for d, i in data {
			assert(i == d.i)
			r, valid := reflect.as_u64(d.v)
			testing.expectf(t, valid,    "i8 %v !valid",                    d.v)
			testing.expectf(t, r == d.e, "i8 %v -> %v (0x%X) != %v (0x%X)", d.v, r, r, d.e, d.e)
		}
	}
	{
		/* i16 */
		Datum :: struct { i: int, v: i16, e: u64 }
		@static data := []Datum{
			{ 0, 0x7FFF, 0x7FFF },
			{ 1, -1, 0xFFFF_FFFF_FFFF_FFFF },
			{ 2, -0x8000, 0xFFFF_FFFF_FFFF_8000 },
		}

		for d, i in data {
			assert(i == d.i)
			r, valid := reflect.as_u64(d.v)
			testing.expectf(t, valid,    "i16 %v !valid",                    d.v)
			testing.expectf(t, r == d.e, "i16 %v -> %v (0x%X) != %v (0x%X)", d.v, r, r, d.e, d.e)
		}
	}
	{
		/* i32 */
		Datum :: struct { i: int, v: i32, e: u64 }
		@static data := []Datum{
			{ 0, 0x7FFF_FFFF, 0x7FFF_FFFF },
			{ 1, -1, 0xFFFF_FFFF_FFFF_FFFF },
			{ 2, -0x8000_0000, 0xFFFF_FFFF_8000_0000 },
		}

		for d, i in data {
			assert(i == d.i)
			r, valid := reflect.as_u64(d.v)
			testing.expectf(t, valid,    "i32 %v !valid",                    d.v)
			testing.expectf(t, r == d.e, "i32 %v -> %v (0x%X) != %v (0x%X)", d.v, r, r, d.e, d.e)
		}
	}
	{
		/* i64 */
		Datum :: struct { i: int, v: i64, e: u64 }
		@static data := []Datum{
			{ 0, 0x7FFF_FFFF_FFFF_FFFF, 0x7FFF_FFFF_FFFF_FFFF },
			{ 1, -1, 0xFFFF_FFFF_FFFF_FFFF },
			{ 2, -0x8000_0000_0000_0000, 0x8000_0000_0000_0000 },
		}

		for d, i in data {
			assert(i == d.i)
			r, valid := reflect.as_u64(d.v)
			testing.expectf(t, valid,    "i64 %v !valid",                    d.v)
			testing.expectf(t, r == d.e, "i64 %v -> %v (0x%X) != %v (0x%X)", d.v, r, r, d.e, d.e)
		}
	}
	{
		/* i128 */
		Datum :: struct { i: int, v: i128, e: u64 }
		@static data := []Datum{
			{ 0, 0x7FFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF, 0xFFFF_FFFF_FFFF_FFFF },
			{ 1, -1, 0xFFFF_FFFF_FFFF_FFFF },
			{ 2, 0x8000_0000_0000_0000, 0x8000_0000_0000_0000 },
			{ 3, -0x8000_0000_0000_0000, 0x8000_0000_0000_0000 },
			{ 4, 0x0001_0000_0000_0000_0000, 0 },
			{ 5, -0x8000_0000_0000_0000_0000_0000_0000_0000, 0 },
		}

		for d, i in data {
			assert(i == d.i)
			r, valid := reflect.as_u64(d.v)
			testing.expectf(t, valid,    "i128 %v !valid",                    d.v)
			testing.expectf(t, r == d.e, "i128 %v -> %v (0x%X) != %v (0x%X)", d.v, r, r, d.e, d.e)
		}
	}
	{
		/* f16 */
		Datum :: struct { i: int, v: f16, e: u64 }
		@static data := []Datum{
			{ 0, 1.2, 1 },
			{ 1, 123.12, 123 },
		}

		for d, i in data {
			assert(i == d.i)
			r, valid := reflect.as_u64(d.v)
			testing.expectf(t, valid,    "f16 %v !valid",      d.v)
			testing.expectf(t, r == d.e, "f16 %v -> %v != %v", d.v, r, d.e)
		}
	}
	{
		/* f32 */
		Datum :: struct { i: int, v: f32, e: u64 }
		@static data := []Datum{
			{ 0, 123.3415, 123 },
		}

		for d, i in data {
			assert(i == d.i)
			r, valid := reflect.as_u64(d.v)
			testing.expectf(t, valid,    "f32 %v !valid",      d.v)
			testing.expectf(t, r == d.e, "f32 %v -> %v != %v", d.v, r, d.e)
		}
	}
	{
		/* f64 */
		Datum :: struct { i: int, v: f64, e: u64 }
		@static data := []Datum{
			{ 0, 12345345345.3415234234, 12345345345 },
		}

		for d, i in data {
			assert(i == d.i)
			r, valid := reflect.as_u64(d.v)
			testing.expectf(t, valid,    "f64 %v !valid",      d.v)
			testing.expectf(t, r == d.e, "f64 %v -> %v != %v", d.v, r, d.e)
		}
	}
}

@test
test_as_f64 :: proc(t: ^testing.T) {
	{
		/* i8 */
		Datum :: struct { i: int, v: i8, e: f64 }
		@static data := []Datum{
			{ 0, 0x7F, 0x7F },
			{ 1, -1, -1 },
			{ 2, -0x80, -0x80 },
		}

		for d, i in data {
			assert(i == d.i)
			r, valid := reflect.as_f64(d.v)
			testing.expectf(t, valid,    "i8 %v !valid",      d.v)
			testing.expectf(t, r == d.e, "i8 %v -> %v != %v", d.v, r, d.e)
		}
	}
	{
		/* i16 */
		Datum :: struct { i: int, v: i16, e: f64 }
		@static data := []Datum{
			{ 0, 0x7FFF, 0x7FFF },
			{ 1, -1, -1 },
			{ 2, -0x8000, -0x8000 },
		}

		for d, i in data {
			assert(i == d.i)
			r, valid := reflect.as_f64(d.v)
			testing.expectf(t, valid,    "i16 %v !valid",      d.v)
			testing.expectf(t, r == d.e, "i16 %v -> %v != %v", d.v, r, d.e)
		}
	}
	{
		/* i32 */
		Datum :: struct { i: int, v: i32, e: f64 }
		@static data := []Datum{
			{ 0, 0x7FFF_FFFF, 0x7FFF_FFFF },
			{ 1, -1, -1 },
			{ 2, -0x8000_0000, -0x8000_0000 },
		}

		for d, i in data {
			assert(i == d.i)
			r, valid := reflect.as_f64(d.v)
			testing.expectf(t, valid,    "i32 %v !valid",      d.v)
			testing.expectf(t, r == d.e, "i32 %v -> %v != %v", d.v, r, d.e)
		}
	}
	{
		/* i64 */
		Datum :: struct { i: int, v: i64, e: f64 }
		@static data := []Datum{
			{ 0, 0x7FFF_FFFF_FFFF_FFFF, 0x7FFF_FFFF_FFFF_FFFF },
			{ 1, -1, -1 },
			{ 2, -0x8000_0000_0000_0000, -0x8000_0000_0000_0000 },
		}

		for d, i in data {
			assert(i == d.i)
			r, valid := reflect.as_f64(d.v)
			testing.expectf(t, valid,    "i64 %v !valid",      d.v)
			testing.expectf(t, r == d.e, "i64 %v -> %v != %v", d.v, r, d.e)
		}
	}
	{
		/* i128 */
		Datum :: struct { i: int, v: i128, e: f64 }
		@static data := []Datum{
			{ 0, 0x7FFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF, 0x7FFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF },
			{ 1, -1, -1 },
			{ 2, 0x8000_0000_0000_0000_0000_0000_0000, 0x8000_0000_0000_0000_0000_0000_0000 },
			{ 3, -0x8000_0000_0000_0000_0000_0000_0000_0000, -0x8000_0000_0000_0000_0000_0000_0000_0000 },
		}

		for d, i in data {
			assert(i == d.i)
			r, valid := reflect.as_f64(d.v)
			testing.expectf(t, valid,    "i128 %v !valid",                d.v)
			testing.expectf(t, r == d.e, "i128 %v -> %v (%H) != %v (%H)", d.v, r, r, d.e, d.e)
		}
	}
	{
		/* f16 */
		Datum :: struct { i: int, v: f16, e: f64 }
		@static data := []Datum{
			{ 0, 1.2, 0h3FF3_3400_0000_0000 }, // Precision difference TODO: check
			{ 1, 123.12, 0h405E_C800_0000_0000 }, // Precision difference TODO: check
		}

		for d, i in data {
			assert(i == d.i)
			r, valid := reflect.as_f64(d.v)
			testing.expectf(t, valid,    "f16 %v !valid",                     d.v)
			testing.expectf(t, r == d.e, "f16 %v (%H) -> %v (%H) != %v (%H)", d.v, d.v, r, r, d.e, d.e)
		}
	}
	{
		/* f32 */
		Datum :: struct { i: int, v: f32, e: f64 }
		@static data := []Datum{
			{ 0, 123.3415, 0h405E_D5DB_2000_0000 }, // Precision difference TODO: check
		}

		for d, i in data {
			assert(i == d.i)
			r, valid := reflect.as_f64(d.v)
			testing.expectf(t, valid,    "f32 %v !valid", d.v)
			testing.expectf(t, r == d.e, "f32 %v (%H) -> %v (%H) != %v (%H)", d.v, d.v, r, r, d.e, d.e)
		}
	}
	{
		/* f64 */
		Datum :: struct { i: int, v: f64, e: f64 }
		@static data := []Datum{
			{ 0, 12345345345.3415234234, 12345345345.3415234234 },
		}

		for d, i in data {
			assert(i == d.i)
			r, valid := reflect.as_f64(d.v)
			testing.expectf(t, valid,    "f64 %v !valid",      d.v)
			testing.expectf(t, r == d.e, "f64 %v -> %v != %v", d.v, r, d.e)
		}
	}
}

@test
test_simd_vectors :: proc(t: ^testing.T) {
	{
		V :: #simd[2]u64
		v: V
		E := typeid_of(u64)

		testing.expect(t, typeid_of(intrinsics.type_elem_type(V)) == E)
		testing.expect(t, reflect.typeid_elem(V) == E)
		testing.expect(t, reflect.length(v)   == len(V))
		testing.expect(t, reflect.capacity(v) == cap(V))
		testing.expect(t, reflect.length(v)   == 2)
	}
	{
		V :: #simd[4]f32
		v: V
		E := typeid_of(f32)

		testing.expect(t, typeid_of(intrinsics.type_elem_type(V)) == E)
		testing.expect(t, reflect.typeid_elem(V) == E)
		testing.expect(t, reflect.length(v)   == len(V))
		testing.expect(t, reflect.capacity(v) == cap(V))
		testing.expect(t, reflect.length(v)   == 4)
	}
	{
		V :: #simd[8]i16
		v: V
		E := typeid_of(i16)

		testing.expect(t, typeid_of(intrinsics.type_elem_type(V)) == E)
		testing.expect(t, reflect.typeid_elem(V) == E)
		testing.expect(t, reflect.length(v)   == len(V))
		testing.expect(t, reflect.capacity(v) == cap(V))
		testing.expect(t, reflect.length(v)   == 8)
	}
	{
		V :: #simd[16]u32
		v: V
		E := typeid_of(u32)

		testing.expect(t, typeid_of(intrinsics.type_elem_type(V)) == E)
		testing.expect(t, reflect.typeid_elem(V) == E)
		testing.expect(t, reflect.length(v)   == len(V))
		testing.expect(t, reflect.capacity(v) == cap(V))
		testing.expect(t, reflect.length(v)   == 16)
	}
	{
		V :: #simd[32]u16
		v: V
		E := typeid_of(u16)

		testing.expect(t, typeid_of(intrinsics.type_elem_type(V)) == E)
		testing.expect(t, reflect.typeid_elem(V) == E)
		testing.expect(t, reflect.length(v)   == len(V))
		testing.expect(t, reflect.capacity(v) == cap(V))
		testing.expect(t, reflect.length(v)   == 32)
	}
	{
		V :: #simd[64]i8
		v: V
		E := typeid_of(i8)

		testing.expect(t, typeid_of(intrinsics.type_elem_type(V)) == E)
		testing.expect(t, reflect.typeid_elem(V) == E)
		testing.expect(t, reflect.length(v)   == len(V))
		testing.expect(t, reflect.capacity(v) == cap(V))
		testing.expect(t, reflect.length(v)   == 64)
	}
}