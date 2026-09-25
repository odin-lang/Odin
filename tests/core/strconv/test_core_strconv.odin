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

@(test)
test_float_rounding_f64 :: proc(t: ^testing.T) {
	Case :: struct { s: string, bits: u64 }
	cases := []Case{
		{"1.2",                     0x3ff3333333333333},
		{"123456789e-5",            0x40934a4584f4c6e7},
		{"4503599627370495",        0x432ffffffffffffe}, // 2^52 - 1
		{"0.1234567890123456",      0x3fbf9add3746f659}, // 16 digits
		{"1e22",                    0x4480f0cf064dd592},
		{"1e-22",                   0x3b5e392010175ee6},
		{"1e37",                    0x479e17b84357691b}, // 1e15 * 1e22
		{"-0.0",                    0x8000000000000000},
		{"1_000.5",                 0x408f440000000000},
		{"12345678901234e30",       0x48e1b716107ef6cd},
		{"8807505e35",              0x48a43896104bfb7b},
		{"49275500062000e27",       0x486219d883804133},
		{"9007199254740991",        0x433fffffffffffff}, // 2^53 - 1
		{"0.12345678901234567",     0x3fbf9add3746f65e}, // 17 digits
		{"1e-23",                   0x3b282db34012b251},
		{"1e38",                    0x47d2ced32a16a1b1},
		{"1.7976931348623157e308",  0x7fefffffffffffff}, // largest f64
		{"2.2250738585072014e-308", 0x0010000000000000}, // smallest normal
		{"2.4703282292062328e-324", 0x0000000000000001}, // rounds up to the smallest subnormal
		{"2.4703282292062327e-324", 0x0000000000000000}, // rounds down to zero
		{"9007199254740993",        0x4340000000000000}, // halfway, round to even
		{"123456789012345678901234",   0x44ba249b1f10a06d},
		{"0.1000000000000000000000001", 0x3fb999999999999a},
		{"9007199254740993.0000000000000000001", 0x4340000000000001},
	}
	for c in cases {
		f, ok := strconv.parse_f64(c.s)
		testing.expectf(t, ok, "%q: ok=false", c.s)
		testing.expectf(t, transmute(u64)f == c.bits, "%q: got %016x, want %016x", c.s, transmute(u64)f, c.bits)
	}
}

@(test)
test_float_rounding_f32 :: proc(t: ^testing.T) {
	Case :: struct { s: string, bits: u32 }
	cases := []Case{
		{"1.2",                                  0x3f99999a},
		{"3.4028235e38",                         0x7f7fffff},
		{"1.17549435e-38",                       0x00800000},
		{"1e-45",                                0x00000001},
		// Parsing as f64 and converting to f32 rounds twice and gives the wrong f32.
		// These use Eisel-Lemire or the slow path.
		{"7.0064923216240854e-46",               0x00000001},
		{"1.1754947011469036e-38",               0x00800003},
		{"2.1665680640000002384185791015625e9",  0x4f012335},
		{"8.589934335999999523162841796875e+09", 0x4fffffff},
		{"0.00036393293703440577",               0x39bece41},
		// The f64 fast path gives exactly an f32 midpoint, but the input is not
		// a midpoint. The conversion to f32 would round the wrong way.
		{"2.295306995511055e-01",                0x3e6b0a19},
		{"2.346675395965576e+01",                0x41bbbbe9},
		{"1.26108672702685e-03",                 0x3aa54b0d},
		{"2.76996448636055e-01",                 0x3e8dd27b},
	}
	for c in cases {
		f, ok := strconv.parse_f32(c.s)
		testing.expectf(t, ok, "%q: ok=false", c.s)
		testing.expectf(t, transmute(u32)f == c.bits, "%q: got %08x, want %08x", c.s, transmute(u32)f, c.bits)
	}

	n: int
	f, ok := strconv.parse_f32("1.5x", &n)
	testing.expect_value(t, f, 1.5)
	testing.expect_value(t, n, 3)
	testing.expect_value(t, ok, false)
}

@(test)
test_float_overflow :: proc(t: ^testing.T) {
	f64v, ok64 := strconv.parse_f64("1e309")
	testing.expect_value(t, math.classify(f64v), math.Float_Class.Inf)
	testing.expect_value(t, ok64, false)

	f64v, ok64 = strconv.parse_f64("-1e309")
	testing.expect_value(t, math.classify(f64v), math.Float_Class.Neg_Inf)
	testing.expect_value(t, ok64, false)

	f32v, ok32 := strconv.parse_f32("1e39")
	testing.expect_value(t, math.classify(f32v), math.Float_Class.Inf)
	testing.expect_value(t, ok32, false)

	f32v, ok32 = strconv.parse_f32("-1e39")
	testing.expect_value(t, math.classify(f32v), math.Float_Class.Neg_Inf)
	testing.expect_value(t, ok32, false)

	f32v, ok32 = strconv.parse_f32("0x1p128")
	testing.expect_value(t, math.classify(f32v), math.Float_Class.Inf)
	testing.expect_value(t, ok32, false)

	f32v, ok32 = strconv.parse_f32("1e309")
	testing.expect_value(t, math.classify(f32v), math.Float_Class.Inf)
	testing.expect_value(t, ok32, false)

	// Underflow to zero is not an error.
	f64v, ok64 = strconv.parse_f64("1e-400")
	testing.expect_value(t, f64v, 0)
	testing.expect_value(t, ok64, true)

	f32v, ok32 = strconv.parse_f32("1e-50")
	testing.expect_value(t, f32v, 0)
	testing.expect_value(t, ok32, true)
}
