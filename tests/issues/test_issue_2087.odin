// Tests issue #2087 https://github.com/odin-lang/Odin/issues/2087
package test_issues

import "core:math"
import "core:strconv"
import "core:testing"

@(test)
test_parse_float :: proc(t: ^testing.T) {
	{
		f, ok := strconv.parse_f64("1.2")
		testing.expect(t, ok && f == 1.2, "expected f64(1.2), fully consumed")
		f, ok = strconv.parse_f64("1.2a")
		testing.expect(t, !ok && f == 1.2, "expected f64(1.2), partially consumed")
		f, ok = strconv.parse_f64("+")
		testing.expect(t, !ok && f == 0.0, "expected f64(0.0), with ok=false")
		f, ok = strconv.parse_f64("-")
		testing.expect(t, !ok && f == 0.0, "expected f64(0.0), with ok=false")


		f, ok = strconv.parse_f64("inf")
		testing.expect(t, ok && math.classify(f) == math.Float_Class.Inf, "expected f64(+inf), fully consumed")
		f, ok = strconv.parse_f64("+inf")
		testing.expect(t, ok && math.classify(f) == math.Float_Class.Inf, "expected f64(+inf), fully consumed")
		f, ok = strconv.parse_f64("-inf")
		testing.expect(t, ok && math.classify(f) == math.Float_Class.Neg_Inf, "expected f64(-inf), fully consumed")
		f, ok = strconv.parse_f64("inFinity")
		testing.expect(t, !ok && math.classify(f) == math.Float_Class.Inf, "expected f64(+inf), partially consumed")
		f, ok = strconv.parse_f64("+InFinity")
		testing.expect(t, !ok && math.classify(f) == math.Float_Class.Inf, "expected f64(+inf), partially consumed")
		f, ok = strconv.parse_f64("-InfiniTy")
		testing.expect(t, !ok && math.classify(f) == math.Float_Class.Neg_Inf, "expected f64(-inf), partially consumed")
		f, ok = strconv.parse_f64("nan")
		testing.expect(t, ok && math.classify(f) == math.Float_Class.NaN, "expected f64(nan), fully consumed")
		f, ok = strconv.parse_f64("nAN")
		testing.expect(t, ok && math.classify(f) == math.Float_Class.NaN, "expected f64(nan), fully consumed")
	}
	{
		f, ok := strconv.parse_f32("1.2")
		testing.expect(t, ok && f == 1.2, "expected f32(1.2), fully consumed")

		f, ok = strconv.parse_f32("1.2a")
		testing.expect(t, !ok && f == 1.2, "expected f32(1.2), partially consumed")

		f, ok = strconv.parse_f32("inf")
		testing.expect(t, ok && math.classify(f) == math.Float_Class.Inf, "expected f32(+inf), fully consumed")
		f, ok = strconv.parse_f32("+inf")
		testing.expect(t, ok && math.classify(f) == math.Float_Class.Inf, "expected f32(+inf), fully consumed")
		f, ok = strconv.parse_f32("-inf")
		testing.expect(t, ok && math.classify(f) == math.Float_Class.Neg_Inf, "expected f32(-inf), fully consumed")
		f, ok = strconv.parse_f32("inFinity")
		testing.expect(t, !ok && math.classify(f) == math.Float_Class.Inf, "expected f32(+inf), partially consumed")
		f, ok = strconv.parse_f32("+InFinity")
		testing.expect(t, !ok && math.classify(f) == math.Float_Class.Inf, "expected f32(+inf), partially consumed")
		f, ok = strconv.parse_f32("-InfiniTy")
		testing.expect(t, !ok && math.classify(f) == math.Float_Class.Neg_Inf, "expected f32(-inf), partially consumed")
		f, ok = strconv.parse_f32("nan")
		testing.expect(t, ok && math.classify(f) == math.Float_Class.NaN, "expected f32(nan), fully consumed")
		f, ok = strconv.parse_f32("nAN")
		testing.expect(t, ok && math.classify(f) == math.Float_Class.NaN, "expected f32(nan), fully consumed")
	}
}