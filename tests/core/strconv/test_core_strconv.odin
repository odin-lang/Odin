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
test_float_hex :: proc(t: ^testing.T) {
	Case64 :: struct { s: string, bits: u64 }
	cases64 := [?]Case64{
		{"0x1.8p1",                 0x4008000000000000},
		{"0x1.0fp0",                0x3ff0f00000000000}, // hex letter digit after a zero
		{"0x1.0000000000000fp0",    0x3ff0000000000001}, // more bits than fit, must round
		{"0x1.123456789abcdef0p0",  0x3ff123456789abce},
		{"0x1.fffffffffffffp1023",  0x7fefffffffffffff},
		{"0x1p-1022",               0x0010000000000000},
		{"0x1p-1074",               0x0000000000000001}, // subnormal
		{"0x1.8p-1074",             0x0000000000000002},
		{"0x1p-1075",               0x0000000000000000},
		{"-0x1.fp-1070",            0x800000000000001f},
	}
	for c in cases64 {
		f, ok := strconv.parse_f64(c.s)
		testing.expectf(t, ok, "%q: ok=false", c.s)
		testing.expectf(t, transmute(u64)f == c.bits, "%q: got %016x, want %016x", c.s, transmute(u64)f, c.bits)
	}

	Case32 :: struct { s: string, bits: u32 }
	cases32 := [?]Case32{
		{"0x1.fffffep127", 0x7f7fffff},
		{"0x1.ffffffp0",   0x40000000}, // halfway, round to even
		{"0x1.234567p0",   0x3f91a2b4},
		{"0x1p-126",       0x00800000},
		{"0x1p-149",       0x00000001}, // subnormal
		{"0x1.8p-149",     0x00000002},
	}
	for c in cases32 {
		f, ok := strconv.parse_f32(c.s)
		testing.expectf(t, ok, "%q: ok=false", c.s)
		testing.expectf(t, transmute(u32)f == c.bits, "%q: got %08x, want %08x", c.s, transmute(u32)f, c.bits)
	}
}