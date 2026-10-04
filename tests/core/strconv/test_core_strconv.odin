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

@(test)
test_float_scanner :: proc(t: ^testing.T) {
	// Cover the fast scanner's 8-digit steps, the 19-digit limit, skipped leading zeros,
	Case :: struct { s: string, bits: u64, n: int, ok: bool }
	cases := []Case{
		{"12345678", 0x41678c29c0000000, 8, true},
		{"123456789", 0x419d6f3454000000, 9, true},
		{"1234567812345678", 0x43118b54df9fbd38, 16, true},
		{"12345678.12345678", 0x41678c29c3f35ba2, 17, true},
		{"0.1234567812345678", 0x3fbf9add15df3486, 18, true},
		{"1234567890123456789", 0x43b12210f47de981, 19, true},
		{"12345678901234567890", 0x43e56a95319d63e1, 20, true},
		{"123456789012345678901234567890", 0x45f8ee90ff6c373e, 30, true},
		{"0.00000000000000000000123456789", 0x3b97520105b1fbe2, 31, true},
		{"00000000000000001.5", 0x3ff8000000000000, 19, true},
		{"0000000000000000", 0x0000000000000000, 16, true},
		{"0.000000000000000000", 0x0000000000000000, 20, true},
		{"9007199254740993", 0x4340000000000000, 16, true},
		{"1.00000000000000011102230246251565404236316680908203125", 0x3ff0000000000000, 55, true},
		{"1_000_000", 0x412e848000000000, 9, true},
		{"1.000_5", 0x3ff0020c49ba5e35, 7, true},
		{"1e1_0", 0x4202a05f20000000, 5, true},
		{"_1", 0x3ff0000000000000, 2, true},
		{"1_", 0x3ff0000000000000, 2, true},
		{"1__2.5", 0x4029000000000000, 6, true},
		{".5", 0x3fe0000000000000, 2, true},
		{"-.5", 0xbfe0000000000000, 3, true},
		{"5.", 0x4014000000000000, 2, true},
		{"+1.5", 0x3ff8000000000000, 4, true},
		{"1.5 ", 0x3ff8000000000000, 3, false},
		{"1..5", 0x3ff0000000000000, 2, false},
		{"1.5.5", 0x3ff8000000000000, 3, false},
		{".", 0x0000000000000000, 0, false},
		{"-", 0x0000000000000000, 0, false},
		{"+", 0x0000000000000000, 0, false},
		{"", 0x0000000000000000, 0, false},
		{"e5", 0x0000000000000000, 0, false},
		{".e5", 0x0000000000000000, 0, false},
		{"1.5e", 0x0000000000000000, 0, false},
		{"1.5e+", 0x0000000000000000, 0, false},
		{"1.5ex", 0x0000000000000000, 0, false},
		{"1.5E-3", 0x3f589374bc6a7efa, 6, true},
		{"1e400", 0x7ff0000000000000, 5, false},
		{"1e-400", 0x0000000000000000, 6, true},
		{"1e999999999", 0x7ff0000000000000, 11, false},
		{"-0", 0x8000000000000000, 2, true},
		{"0x", 0x0000000000000000, 1, false},
		{"0x1p0", 0x3ff0000000000000, 5, true},
		{"0xg", 0x0000000000000000, 0, false},
		{"inf", 0x7ff0000000000000, 3, true},
		{"-inf", 0xfff0000000000000, 4, true},
		{"nan", 0x7ff8000000000001, 3, true},
		{"infinity", 0x7ff0000000000000, 8, true},
	}
	for c in cases {
		n: int
		f, ok := strconv.parse_f64(c.s, &n)
		testing.expectf(t, transmute(u64)f == c.bits && n == c.n && ok == c.ok,
			"%q: got (%016x, n=%d, ok=%v), want (%016x, n=%d, ok=%v)", c.s, transmute(u64)f, n, ok, c.bits, c.n, c.ok)
	}
}

@(test)
test_float_underscore :: proc(t: ^testing.T) {
	Case :: struct { s: string, bits: u64, n: int, ok: bool }
	cases := []Case{
		// Odin literals with the same value.
		{"1_000_000",                  0x412e848000000000,  9, true},
		{"1_000.5",                    0x408f440000000000,  7, true},
		{"1.000_5",                    0x3ff0020c49ba5e35,  7, true},
		{"1e1_0",                      0x4202a05f20000000,  5, true},
		{"1_",                         0x3ff0000000000000,  2, true},
		{"1__2",                       0x4028000000000000,  4, true},
		{"1_.5",                       0x3ff8000000000000,  4, true},
		{"1._5",                       0x3ff8000000000000,  4, true},
		{"1_e5",                       0x40f86a0000000000,  4, true},
		{"1e5_",                       0x40f86a0000000000,  4, true},
		{"1.5_",                       0x3ff8000000000000,  4, true},
		{"0_1.5",                      0x3ff8000000000000,  5, true},
		{"-1_000.25",                  0xc08f420000000000,  9, true},
		{"+1_0",                       0x4024000000000000,  4, true},
		{"1e1_0_0",                    0x54b249ad2594c37d,  7, true},
		{"1.5e-0_0_3",                 0x3f589374bc6a7efa, 10, true},
		// Not Odin literals, but strconv accepts them.
		{"_1",                         0x3ff0000000000000,  2, true},
		{"-_1.5",                      0xbff8000000000000,  5, true},
		{"._5",                        0x3fe0000000000000,  3, true},
		// `_` next to the 8 and 4 digit steps of the fast scanner.
		{"0.12345678_12345678",        0x3fbf9add15df3486, 19, true},
		{"1234_5678.8765_4321",        0x41678c29dc0ca459, 19, true},
		{"0.1_2_3_4_5_6_7_8_9",        0x3fbf9add3739635f, 19, true},
		// `_` on each conversion path: Eisel-Lemire (17 digits), more than 19 digits
		// (including leading zeros), and the arbitrary-precision slow path.
		{"0.123_456_789_012_345_67",   0x3fbf9add3746f65e, 24, true},
		{"1_234.567_890_123_456e-2_0", 0x3c6c779a3f7ffdf5, 26, true},
		{"1.797_693_134_862_315_7e3_08", 0x7fefffffffffffff, 28, true},
		{"9_007_199_254_740_993",      0x4340000000000000, 21, true},
		{"0_000_000_000_000_000_000_1.5", 0x3ff8000000000000, 29, true},
		{"0.000_000_000_000_000_000_001_234_567_890_123_456_789", 0x3b97520105bbfffb, 53, true},
		{"1_234_567_890_123_456_789_012_345",   0x44f056e0f36a6444, 33, true},
		{"123_456_789_012_345_678_901_234",     0x44ba249b1f10a06d, 31, true},
		{"0.1_000_000_000_000_000_000_000_001", 0x3fb999999999999a, 35, true},
		{"9_007_199_254_740_993.000_000_000_000_000_000_1", 0x4340000000000001, 47, true},
		// The number stops at the first byte that is not a digit, `_`, `.` or an exponent.
		{"1_000.5x",                   0x408f440000000000,  7, false},
		{"1_000,5",                    0x408f400000000000,  5, false},
		{"_",                          0x0000000000000000,  0, false},
		{"__",                         0x0000000000000000,  0, false},
	}
	for c in cases {
		n: int
		f, ok := strconv.parse_f64(c.s, &n)
		testing.expectf(t, transmute(u64)f == c.bits && n == c.n && ok == c.ok,
			"%q: got (%016x, n=%d, ok=%v), want (%016x, n=%d, ok=%v)", c.s, transmute(u64)f, n, ok, c.bits, c.n, c.ok)
	}

	Case32 :: struct { s: string, bits: u32 }
	cases32 := []Case32{
		{"1_000.5",                      0x447a2000},
		{"0.123_456_7",                  0x3dfcd6de},
		{"3.402_823_5e3_8",              0x7f7fffff},
		{"1.175_494_701_146_903_6e-3_8", 0x00800003}, // parsing as f64 first would give 0x00800002
	}
	for c in cases32 {
		f, ok := strconv.parse_f32(c.s)
		testing.expectf(t, ok && transmute(u32)f == c.bits, "%q: got %08x (ok=%v), want %08x", c.s, transmute(u32)f, ok, c.bits)
	}
}

@(test)
test_float_hex_scanner :: proc(t: ^testing.T) {
	// Cover the fast hex scanner
	Case :: struct { s: string, bits: u64, n: int, ok: bool }
	cases := []Case{
		{"0x1.921fb54442d18p+1", 0x400921fb54442d18, 20, true},
		{"-0x1.921fb54442d18p+1", 0xc00921fb54442d18, 21, true},
		{"0X1.8P1", 0x4008000000000000, 7, true},
		{"0x1.8p-1", 0x3fe8000000000000, 8, true},
		{"0x123456789abcdef0p0", 0x43b23456789abcdf, 20, true},
		{"0x123456789abcdef08p0", 0x43f23456789abcdf, 21, true},
		{"0x123456789abcdef01p0", 0x43f23456789abcdf, 21, true},
		{"0x1.00000000000000001p0", 0x3ff0000000000000, 23, true},
		{"0x0.000000000000000000000001p0", 0x39f0000000000000, 30, true},
		{"0x.8p1", 0x3ff0000000000000, 6, true},
		{"0x1.p1", 0x4000000000000000, 6, true},
		{"0x00001p4", 0x4030000000000000, 9, true},
		{"0x1_000p0", 0x40b0000000000000, 9, true},
		{"0x1.8p1_0", 0x4098000000000000, 9, true},
		{"0x1.8", 0x0000000000000000, 0, false},
		{"0x1.8p", 0x0000000000000000, 0, false},
		{"0x1.8p+", 0x0000000000000000, 0, false},
		{"0x1..8p1", 0x0000000000000000, 0, false},
		{"0x", 0x0000000000000000, 1, false},
		{"0xp1", 0x0000000000000000, 0, false},
		{"0x.p1", 0x0000000000000000, 0, false},
		{"0x1.8p1 ", 0x4008000000000000, 7, false},
		{"0x1p1024", 0x7ff0000000000000, 8, false},
		{"0x1p-1074", 0x0000000000000001, 9, true},
		{"0x1p-1076", 0x0000000000000000, 9, true},
		{"0x1.8p-1075", 0x0000000000000001, 11, true},
		{"0x1p99999999", 0x7ff0000000000000, 12, false},
	}
	for c in cases {
		n: int
		f, ok := strconv.parse_f64(c.s, &n)
		testing.expectf(t, transmute(u64)f == c.bits && n == c.n && ok == c.ok,
			"%q: got (%016x, n=%d, ok=%v), want (%016x, n=%d, ok=%v)", c.s, transmute(u64)f, n, ok, c.bits, c.n, c.ok)
	}

	f32v, ok32 := strconv.parse_f32("0x1.000001000000000000001p0")
	testing.expectf(t, ok32 && transmute(u32)f32v == 0x3f800001, "got %08x (ok=%v), want 3f800001", transmute(u32)f32v, ok32)
}

@(test)
test_float_0h :: proc(t: ^testing.T) {
	// The 0h syntax gives the exact bits of an f16, f32 or f64
	Case :: struct { s: string, bits: u64, n: int, ok: bool }
	cases := [?]Case{
		{"0h9a54fdf3743fd6ab",    0x9a54fdf3743fd6ab, 18, true},
		{"0h9A54FDF3743FD6AB",    0x9a54fdf3743fd6ab, 18, true},
		{"0h28e4_8358_c264_335f", 0x28e48358c264335f, 21, true},
		{"0h3ff0_0000_0000_0000", 0x3ff0000000000000, 21, true},
		{"0h3f800000",            0x3ff0000000000000, 10, true},
		{"0h3c00",                0x3ff0000000000000,  6, true},
		{"0h3c0_0",               0x3ff0000000000000,  7, true},
		{"0h3ff00000000000001",   0x0000000000000000, 19, false}, // 17 digits
		{"0h3ff0000000000000g",   0x3ff0000000000000, 18, false},
		{"0h3ff00000_",           0x3ffe000000000000, 11, true}, // 8 digits: the f32 1.875
	}
	for c in cases {
		n: int
		f, ok := strconv.parse_f64(c.s, &n)
		testing.expectf(t, transmute(u64)f == c.bits && n == c.n && ok == c.ok,
			"%q: got (%016x, n=%d, ok=%v), want (%016x, n=%d, ok=%v)", c.s, transmute(u64)f, n, ok, c.bits, c.n, c.ok)
	}

	// parse_f32 keeps the exact bits, also for a signaling NaN.
	f32v, ok32 := strconv.parse_f32("0h7f9a7604")
	testing.expectf(t, ok32 && transmute(u32)f32v == 0x7f9a7604, "got %08x (ok=%v), want 7f9a7604", transmute(u32)f32v, ok32)
}
