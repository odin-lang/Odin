package test_core_strconv

import "core:math"
import "core:strconv"
import "core:testing"

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
		} else if i == 8 { // "infinity"
			testing.expect_value(t, f, pos_inf)
			testing.expect_value(t, n, 8)
			testing.expect_value(t, ok, true)
		} else { // invalid substring
			testing.expect_value(t, f, 0)
			testing.expect_value(t, n, 0)
			testing.expect_value(t, ok, false)
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
		} else if i == 9 { // "+infinity"
			testing.expect_value(t, f, pos_inf)
			testing.expect_value(t, n, 9)
			testing.expect_value(t, ok, true)
		} else { // invalid substring
			testing.expect_value(t, f, 0)
			testing.expect_value(t, n, 0)
			testing.expect_value(t, ok, false)
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
		} else if i == 9 { // "-infinity"
			testing.expect_value(t, f, neg_inf)
			testing.expect_value(t, n, 9)
			testing.expect_value(t, ok, true)
		} else { // invalid substring
			testing.expect_value(t, f, 0)
			testing.expect_value(t, n, 0)
			testing.expect_value(t, ok, false)
		}
	}

	// Make sure odd casing works.
	batch := [?]string {"INFiniTY", "iNfInItY", "InFiNiTy"}
	for ss in batch {
		f, ok := strconv.parse_f64(ss, &n)
		testing.expect_value(t, f, pos_inf)
		testing.expect_value(t, n, 8)
		testing.expect_value(t, ok, true)
	}
}
