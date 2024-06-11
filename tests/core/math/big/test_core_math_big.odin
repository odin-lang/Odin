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
