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

	for i in 1 ..< len(s) + 1 {
		ss := s[:i]
		f, ok := strconv.parse_f64(ss, &n)
		if i == 3 { // "inf"
			testing.expect_value(t, f, pos_inf)
			testing.expect_value(t, n, 3)
			testing.expect_value(t, ok, true)
			testing.expect_value(t, math.classify(f), math.Float_Class.Inf)
		} else if i == 8 { // "infinity"
			testing.expect_value(t, f, pos_inf)
			testing.expect_value(t, n, 8)
			testing.expect_value(t, ok, true)
			testing.expect_value(t, math.classify(f), math.Float_Class.Inf)
		} else { // invalid substring
			testing.expect_value(t, f, 0)
			testing.expect_value(t, n, 0)
			testing.expect_value(t, ok, false)
			testing.expect_value(t, math.classify(f), math.Float_Class.Zero)
		}
	}
	
	s = "+infinity"
	for i in 1 ..< len(s) + 1 {
		ss := s[:i]
		f, ok := strconv.parse_f64(ss, &n)
		if i == 4 { // "+inf"
			testing.expect_value(t, f, pos_inf)
			testing.expect_value(t, n, 4)
			testing.expect_value(t, ok, true)
			testing.expect_value(t, math.classify(f), math.Float_Class.Inf)
		} else if i == 9 { // "+infinity"
			testing.expect_value(t, f, pos_inf)
			testing.expect_value(t, n, 9)
			testing.expect_value(t, ok, true)
			testing.expect_value(t, math.classify(f), math.Float_Class.Inf)
		} else { // invalid substring
			testing.expect_value(t, f, 0)
			testing.expect_value(t, n, 0)
			testing.expect_value(t, ok, false)
			testing.expect_value(t, math.classify(f), math.Float_Class.Zero)
		}
	}

	s = "-infinity"
	for i in 1 ..< len(s) + 1 {
		ss := s[:i]
		f, ok := strconv.parse_f64(ss, &n)
		if i == 4 { // "-inf"
			testing.expect_value(t, f, neg_inf)
			testing.expect_value(t, n, 4)
			testing.expect_value(t, ok, true)
			testing.expect_value(t, math.classify(f), math.Float_Class.Neg_Inf)
		} else if i == 9 { // "-infinity"
			testing.expect_value(t, f, neg_inf)
			testing.expect_value(t, n, 9)
			testing.expect_value(t, ok, true)
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
