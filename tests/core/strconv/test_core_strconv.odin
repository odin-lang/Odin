package test_core_strconv

import "core:math"
import "core:strconv"
import "core:testing"

@(test)
test_float :: proc(t: ^testing.T) {
	n: int
	f: f64
	ok: bool

	f, ok = strconv.parse_f64("1.2", &n)
	testing.expect_value(t, f, 1.2)
	testing.expect_value(t, n, 3)
	testing.expect_value(t, ok, true)

	f, ok = strconv.parse_f64("1.2a", &n)
	testing.expect_value(t, f, 1.2)
	testing.expect_value(t, n, 3)
	testing.expect_value(t, ok, false)

	f, ok = strconv.parse_f64("+", &n)
	testing.expect_value(t, f, 0)
	testing.expect_value(t, n, 0)
	testing.expect_value(t, ok, false)

	f, ok = strconv.parse_f64("-", &n)
	testing.expect_value(t, f, 0)
	testing.expect_value(t, n, 0)
	testing.expect_value(t, ok, false)

	f, ok = strconv.parse_f64("0", &n)
	testing.expect_value(t, f, 0)
	testing.expect_value(t, n, 1)
	testing.expect_value(t, ok, true)

	f, ok = strconv.parse_f64("0h", &n)
	testing.expect_value(t, f, 0)
	testing.expect_value(t, n, 1)
	testing.expect_value(t, ok, false)

	f, ok = strconv.parse_f64("0h1", &n)
	testing.expect_value(t, f, 0)
	testing.expect_value(t, n, 3)
	testing.expect_value(t, ok, false)

	f, ok = strconv.parse_f64("0h0000_0001", &n)
	testing.expect_value(t, f, 0h0000_0001)
	testing.expect_value(t, n, 11)
	testing.expect_value(t, ok, true)

	f, ok = strconv.parse_f64("0h4c60", &n)
	testing.expect_value(t, f, 0h4c60)
	testing.expect_value(t, f, 17.5)
	testing.expect_value(t, n, 6)
	testing.expect_value(t, ok, true)

	f, ok = strconv.parse_f64("0h418c0000", &n)
	testing.expect_value(t, f, 0h418c0000)
	testing.expect_value(t, f, 17.5)
	testing.expect_value(t, n, 10)
	testing.expect_value(t, ok, true)

	f, ok = strconv.parse_f64("0h4031_8000_0000_0000", &n)
	testing.expect_value(t, f, 0h4031800000000000)
	testing.expect_value(t, f, f64(17.5))
	testing.expect_value(t, n, 21)
	testing.expect_value(t, ok, true)
}

@(test)
test_nan :: proc(t: ^testing.T) {
	n: int
	f: f64
	ok: bool

	f, ok = strconv.parse_f64("nan", &n)
	testing.expect_value(t, math.classify(f), math.Float_Class.NaN)
	testing.expect_value(t, n, 3)
	testing.expect_value(t, ok, true)

	f, ok = strconv.parse_f64("nAN", &n)
	testing.expect_value(t, math.classify(f), math.Float_Class.NaN)
	testing.expect_value(t, n, 3)
	testing.expect_value(t, ok, true)

	f, ok = strconv.parse_f64("Nani", &n)
	testing.expect_value(t, math.classify(f), math.Float_Class.NaN)
	testing.expect_value(t, n, 3)
	testing.expect_value(t, ok, false)
}

@(test)
test_infinity :: proc(t: ^testing.T) {
	pos_inf := math.inf_f64(+1)
	neg_inf := math.inf_f64(-1)

	n: int
	s := "infinity"

	for i in 0 ..< len(s) + 1 {
		ss := s[:i]
		f, ok := strconv.parse_f64(ss, &n)
		if i >= 3 { // "inf" .. "infinity"
			expected_n := 8 if i == 8 else 3
			expected_ok := i == 3 || i == 8
			testing.expect_value(t, f, pos_inf)
			testing.expect_value(t, n, expected_n)
			testing.expect_value(t, ok, expected_ok)
			testing.expect_value(t, math.classify(f), math.Float_Class.Inf)
		} else { // invalid substring
			testing.expect_value(t, f, 0)
			testing.expect_value(t, n, 0)
			testing.expect_value(t, ok, false)
			testing.expect_value(t, math.classify(f), math.Float_Class.Zero)
		}
	}
	
	s = "+infinity"
	for i in 0 ..< len(s) + 1 {
		ss := s[:i]
		f, ok := strconv.parse_f64(ss, &n)
		if i >= 4 { // "+inf" .. "+infinity"
			expected_n := 9 if i == 9 else 4
			expected_ok := i == 4 || i == 9
			testing.expect_value(t, f, pos_inf)
			testing.expect_value(t, n, expected_n)
			testing.expect_value(t, ok, expected_ok)
			testing.expect_value(t, math.classify(f), math.Float_Class.Inf)
		} else { // invalid substring
			testing.expect_value(t, f, 0)
			testing.expect_value(t, n, 0)
			testing.expect_value(t, ok, false)
			testing.expect_value(t, math.classify(f), math.Float_Class.Zero)
		}
	}

	s = "-infinity"
	for i in 0 ..< len(s) + 1 {
		ss := s[:i]
		f, ok := strconv.parse_f64(ss, &n)
		if i >= 4 { // "-inf" .. "infinity"
			expected_n := 9 if i == 9 else 4
			expected_ok := i == 4 || i == 9
			testing.expect_value(t, f, neg_inf)
			testing.expect_value(t, n, expected_n)
			testing.expect_value(t, ok, expected_ok)
			testing.expect_value(t, math.classify(f), math.Float_Class.Neg_Inf)
		} else { // invalid substring
			testing.expect_value(t, f, 0)
			testing.expect_value(t, n, 0)
			testing.expect_value(t, ok, false)
			testing.expect_value(t, math.classify(f), math.Float_Class.Zero)
		}
	}

	// Make sure odd casing works.
	batch := [?]string {"INFiniTY", "iNfInItY", "InFiNiTy"}
	for ss in batch {
		f, ok := strconv.parse_f64(ss, &n)
		testing.expect_value(t, f, pos_inf)
		testing.expect_value(t, n, 8)
		testing.expect_value(t, ok, true)
		testing.expect_value(t, math.classify(f), math.Float_Class.Inf)
	}

	// Explicitly check how trailing characters are handled.
	s = "infinityyyy"
	f, ok := strconv.parse_f64(s, &n)
	testing.expect_value(t, f, pos_inf)
	testing.expect_value(t, n, 8)
	testing.expect_value(t, ok, false)
	testing.expect_value(t, math.classify(f), math.Float_Class.Inf)

	s = "inflippity"
	f, ok = strconv.parse_f64(s, &n)
	testing.expect_value(t, f, pos_inf)
	testing.expect_value(t, n, 3)
	testing.expect_value(t, ok, false)
	testing.expect_value(t, math.classify(f), math.Float_Class.Inf)
}

@(test)
test_parse_int_overflow :: proc(t: ^testing.T) {
	{
		v, ok := strconv.parse_i64("9223372036854775807")
		testing.expect_value(t, v, max(i64))
		testing.expect_value(t, ok, true)

		v, ok = strconv.parse_i64("-9223372036854775808")
		testing.expect_value(t, v, min(i64))
		testing.expect_value(t, ok, true)

		v, ok = strconv.parse_i64("-0x8000_0000_0000_0000")
		testing.expect_value(t, v, min(i64))
		testing.expect_value(t, ok, true)

		v, ok = strconv.parse_i64("7fffffffffffffff", 16)
		testing.expect_value(t, v, max(i64))
		testing.expect_value(t, ok, true)

		_, ok = strconv.parse_i64("9223372036854775808")
		testing.expect_value(t, ok, false)
		_, ok = strconv.parse_i64("-9223372036854775809")
		testing.expect_value(t, ok, false)
		_, ok = strconv.parse_i64("0x8000000000000000")
		testing.expect_value(t, ok, false)
		_, ok = strconv.parse_i64("-8000000000000001", 16)
		testing.expect_value(t, ok, false)
		_, ok = strconv.parse_i64("922337203685477580888")
		testing.expect_value(t, ok, false)
	}
	{
		v, ok := strconv.parse_u64("18446744073709551615")
		testing.expect_value(t, v, max(u64))
		testing.expect_value(t, ok, true)

		v, ok = strconv.parse_u64("ffffffffffffffff", 16)
		testing.expect_value(t, v, max(u64))
		testing.expect_value(t, ok, true)

		_, ok = strconv.parse_u64("18446744073709551616")
		testing.expect_value(t, ok, false)
		_, ok = strconv.parse_u64("0x1_0000_0000_0000_0000")
		testing.expect_value(t, ok, false)
		_, ok = strconv.parse_u64("10000000000000000", 16)
		testing.expect_value(t, ok, false)
	}
	{
		v, ok := strconv.parse_i128("170141183460469231731687303715884105727")
		testing.expect_value(t, v, max(i128))
		testing.expect_value(t, ok, true)

		v, ok = strconv.parse_i128("-170141183460469231731687303715884105728")
		testing.expect_value(t, v, min(i128))
		testing.expect_value(t, ok, true)

		v, ok = strconv.parse_i128("-80000000000000000000000000000000", 16)
		testing.expect_value(t, v, min(i128))
		testing.expect_value(t, ok, true)

		_, ok = strconv.parse_i128("170141183460469231731687303715884105728")
		testing.expect_value(t, ok, false)
		_, ok = strconv.parse_i128("-170141183460469231731687303715884105729")
		testing.expect_value(t, ok, false)
		_, ok = strconv.parse_i128("0x8000_0000_0000_0000_0000_0000_0000_0000")
		testing.expect_value(t, ok, false)
	}
	{
		v, ok := strconv.parse_u128("340282366920938463463374607431768211455")
		testing.expect_value(t, v, max(u128))
		testing.expect_value(t, ok, true)

		_, ok = strconv.parse_u128("340282366920938463463374607431768211456")
		testing.expect_value(t, ok, false)
		_, ok = strconv.parse_u128("100000000000000000000000000000000", 16)
		testing.expect_value(t, ok, false)
	}
	{
		v, ok := strconv.parse_int("-1234")
		testing.expect_value(t, v, -1234)
		testing.expect_value(t, ok, true)

		_, ok = strconv.parse_int("922337203685477580888")
		testing.expect_value(t, ok, false)

		_, ok = strconv.parse_uint("18446744073709551616")
		testing.expect_value(t, ok, false)
	}
}
