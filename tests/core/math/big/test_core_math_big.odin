package test_core_math_big

import "core:math/big"
import "core:testing"

@(test)
test_permutations_and_combinations :: proc(t: ^testing.T) {
	{
		calc, exp := &big.Int{}, &big.Int{}
		defer big.destroy(calc, exp)
		big.permutations_without_repetition(calc, 9000, 10)
		big.int_atoi(exp, "3469387884476822917768284664849390080000")
		equals, error := big.equals(calc, exp)
		testing.expect(t, equals)
		testing.expect_value(t, error, nil)
	}

	{
		calc, exp := &big.Int{}, &big.Int{}
		defer big.destroy(calc, exp)
		big.combinations_with_repetition(calc, 9000, 10)
		big.int_atoi(exp, "965678962435231708695393645683400")
		equals, error := big.equals(calc, exp)
		testing.expect(t, equals)
		testing.expect_value(t, error, nil)
	}

	{
		calc, exp := &big.Int{}, &big.Int{}
		defer big.destroy(calc, exp)
		big.combinations_without_repetition(calc, 9000, 10)
		big.int_atoi(exp, "956070294443568925751842114431600")
		equals, error := big.equals(calc, exp)
		testing.expect(t, equals)
		testing.expect_value(t, error, nil)
	}
}

Rational_Vectors :: struct {
	numerator:    int,
	denominator:  int,
	expected_f64: f64,
	expected_f32: f32,
	expected_f16: f16,
	exact_f64:    bool,
	exact_f32:    bool,
	exact_f16:    bool,
}
rational_vectors := []Rational_Vectors{
	{-1, 1, -1.00, -1.00, -1.00, true, true, true},
	{ 1, 4,  0.25,  0.25,  0.25, true, true, true},
	{ 3, 4,  0.75,  0.75,  0.75, true, true, true},
	{-3, 4, -0.75, -0.75, -0.75, true, true, true},
}

@(test)
test_rational_to_float :: proc(t: ^testing.T) {
	for vec in rational_vectors {
		r: big.Rat
		defer big.destroy(&r)
		big.set(&r.a, vec.numerator)
		big.set(&r.b, vec.denominator)

		{
			float, exact, err := big.rat_to_f64(&r)
			testing.expect_value(t, float, vec.expected_f64)
			testing.expect(t, exact == vec.exact_f64)
			testing.expect(t, err   == nil)
		}

		{
			float, exact, err := big.rat_to_f32(&r)
			testing.expect_value(t, float, vec.expected_f32)
			testing.expect(t, exact == vec.exact_f32)
			testing.expect(t, err   == nil)
		}

		{
			float, exact, err := big.rat_to_f16(&r)
			testing.expect_value(t, float, vec.expected_f16)
			testing.expect(t, exact == vec.exact_f16)
			testing.expect(t, err   == nil)
		}
	}
}