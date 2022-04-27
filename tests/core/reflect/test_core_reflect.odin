// Tests "core:reflect/reflect".
// Must be run with `-collection:tests=` flag, e.g.
// ./odin run tests/core/reflect/test_core_reflect.odin -out=tests/core/test_core_reflect -collection:tests=./tests
package test_core_reflect

import "core:fmt"
import "core:reflect"
import "core:testing"
import tc "tests:common"

main :: proc() {
    t := testing.T{}

	test_as_u64(&t)
	test_as_f64(&t)

	tc.report(&t)
}

@test
test_as_u64 :: proc(t: ^testing.T) {
	using reflect

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
			r, valid := as_u64(d.v)
			tc.expect(t, valid, fmt.tprintf("i:%d %s(i8 %v) !valid\n", i, #procedure, d.v))
			tc.expect(t, r == d.e, fmt.tprintf("i:%d %s(i8 %v) -> %v (0x%X) != %v (0x%X)\n",
												i, #procedure, d.v, r, r, d.e, d.e))
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
			r, valid := as_u64(d.v)
			tc.expect(t, valid, fmt.tprintf("i:%d %s(i16 %v) !valid\n", i, #procedure, d.v))
			tc.expect(t, r == d.e, fmt.tprintf("i:%d %s(i16 %v) -> %v (0x%X) != %v (0x%X)\n",
												i, #procedure, d.v, r, r, d.e, d.e))
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
			r, valid := as_u64(d.v)
			tc.expect(t, valid, fmt.tprintf("i:%d %s(i32 %v) !valid\n", i, #procedure, d.v))
			tc.expect(t, r == d.e, fmt.tprintf("i:%d %s(i32 %v) -> %v (0x%X) != %v (0x%X)\n",
												i, #procedure, d.v, r, r, d.e, d.e))
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
			r, valid := as_u64(d.v)
			tc.expect(t, valid, fmt.tprintf("i:%d %s(i64 %v) !valid\n", i, #procedure, d.v))
			tc.expect(t, r == d.e, fmt.tprintf("i:%d %s(i64 %v) -> %v (0x%X) != %v (0x%X)\n",
												i, #procedure, d.v, r, r, d.e, d.e))
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
			r, valid := as_u64(d.v)
			tc.expect(t, valid, fmt.tprintf("i:%d %s(i128 %v) !valid\n", i, #procedure, d.v))
			tc.expect(t, r == d.e, fmt.tprintf("i:%d %s(i128 %v) -> %v (0x%X) != %v (0x%X)\n",
												i, #procedure, d.v, r, r, d.e, d.e))
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
			r, valid := as_u64(d.v)
			tc.expect(t, valid, fmt.tprintf("i:%d %s(f16 %v) !valid\n", i, #procedure, d.v))
			tc.expect(t, r == d.e, fmt.tprintf("i:%d %s(f16 %v) -> %v != %v\n", i, #procedure, d.v, r, d.e))
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
			r, valid := as_u64(d.v)
			tc.expect(t, valid, fmt.tprintf("i:%d %s(f32 %v) !valid\n", i, #procedure, d.v))
			tc.expect(t, r == d.e, fmt.tprintf("i:%d %s(f32 %v) -> %v != %v\n", i, #procedure, d.v, r, d.e))
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
			r, valid := as_u64(d.v)
			tc.expect(t, valid, fmt.tprintf("i:%d %s(f64 %v) !valid\n", i, #procedure, d.v))
			tc.expect(t, r == d.e, fmt.tprintf("i:%d %s(f64 %v) -> %v != %v\n", i, #procedure, d.v, r, d.e))
		}
	}
}

@test
test_as_f64 :: proc(t: ^testing.T) {
	using reflect

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
			r, valid := as_f64(d.v)
			tc.expect(t, valid, fmt.tprintf("i:%d %s(i8 %v) !valid\n", i, #procedure, d.v))
			tc.expect(t, r == d.e, fmt.tprintf("i:%d %s(i8 %v) -> %v != %v\n", i, #procedure, d.v, r, d.e))
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
			r, valid := as_f64(d.v)
			tc.expect(t, valid, fmt.tprintf("i:%d %s(i16 %v) !valid\n", i, #procedure, d.v))
			tc.expect(t, r == d.e, fmt.tprintf("i:%d %s(i16 %v) -> %v != %v\n", i, #procedure, d.v, r, d.e))
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
			r, valid := as_f64(d.v)
			tc.expect(t, valid, fmt.tprintf("i:%d %s(i32 %v) !valid\n", i, #procedure, d.v))
			tc.expect(t, r == d.e, fmt.tprintf("i:%d %s(i32 %v) -> %v != %v\n", i, #procedure, d.v, r, d.e))
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
			r, valid := as_f64(d.v)
			tc.expect(t, valid, fmt.tprintf("i:%d %s(i64 %v) !valid\n", i, #procedure, d.v))
			tc.expect(t, r == d.e, fmt.tprintf("i:%d %s(i64 %v) -> %v != %v\n", i, #procedure, d.v, r, d.e))
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
			r, valid := as_f64(d.v)
			tc.expect(t, valid, fmt.tprintf("i:%d %s(i128 %v) !valid\n", i, #procedure, d.v))
			tc.expect(t, r == d.e, fmt.tprintf("i:%d %s(i128 %v) -> %v (%H) != %v (%H)\n",
												i, #procedure, d.v, r, r, d.e, d.e))
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
			r, valid := as_f64(d.v)
			tc.expect(t, valid, fmt.tprintf("i:%d %s(f16 %v) !valid\n", i, #procedure, d.v))
			tc.expect(t, r == d.e, fmt.tprintf("i:%d %s(f16 %v (%H)) -> %v (%H) != %v (%H)\n",
												i, #procedure, d.v, d.v, r, r, d.e, d.e))
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
			r, valid := as_f64(d.v)
			tc.expect(t, valid, fmt.tprintf("i:%d %s(f32 %v) !valid\n", i, #procedure, d.v))
			tc.expect(t, r == d.e, fmt.tprintf("i:%d %s(f32 %v (%H)) -> %v (%H) != %v (%H)\n",
												i, #procedure, d.v, d.v, r, r, d.e, d.e))
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
			r, valid := as_f64(d.v)
			tc.expect(t, valid, fmt.tprintf("i:%d %s(f64 %v) !valid\n", i, #procedure, d.v))
			tc.expect(t, r == d.e, fmt.tprintf("i:%d %s(f64 %v) -> %v != %v\n", i, #procedure, d.v, r, d.e))
		}
	}
}
