package test_core_math_big

import "core:math/big"
import "core:strconv"
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

import "core:log"

@(test)
test_big_math_vectors :: proc(t: ^testing.T) {
	for vec in big_test_vectors {
		a, b, res, expected := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
		defer big.destroy(a, b, res, expected)

		atoi(t, a,        vec.a)   or_continue
		atoi(t, b,        vec.b)   or_continue
		atoi(t, expected, vec.exp) or_continue

		#partial switch vec.op {
		case .Add:
			err := big.add(res, a, b)
			testing.expect(t, err == vec.err)

			expect_ab(t, "Expected add(%v, %v) to be %v, got %v", a, b, expected, res, err)

		case .Sub:
			err := big.sub(res, a, b)
			testing.expect(t, err == vec.err)

			expect_ab(t, "Expected sub(%v, %v) to be %v, got %v", a, b, expected, res, err)

		case .Mul:
			err := big.mul(res, a, b)
			testing.expect(t, err == vec.err)

			expect_ab(t, "Expected mul(%v, %v) to be %v, got %v", a, b, expected, res, err)

		case .Div:
			err := big.div(res, a, b)
			testing.expect(t, err == vec.err)

			expect_ab(t, "Expected div(%v, %v) to be %v, got %v", a, b, expected, res, err)

		case .Sqr:
			err := big.sqr(res, a)
			testing.expect(t, err == vec.err)

			expect_a(t, "Expected sqr(%v) to be %v, got %v", a, expected, res, err)

		case .Log:
			base, base_ok := strconv.parse_i64_of_base(vec.b, 16)
			testing.expect(t, base_ok == true)

			log_res, err := big.log(a, big.DIGIT(base))
			testing.expect(t, err == vec.err)

			big.set(res, log_res)
			expect_ab(t, "Expected log(%v, %v) to be %v, got %v", a, b, expected, res, err)

		case .Sqrt:
			err := big.sqrt(res, a)
			testing.expect(t, err == vec.err)

			expect_a(t, "Expected sqrt(%v) to be %v, got %v", a, expected, res, err)

		case .Pow:
			power, power_ok := strconv.parse_i64_of_base(vec.b, 16)
			testing.expect(t, power_ok == true)

			err := big.pow(res, a, int(power))
			testing.expect(t, err == vec.err)

			expect_ab(t, "Expected pow(%v, %v) to be '%v', got %v", a, b, expected, res, err)

		case .Root:
			n, n_ok := strconv.parse_i64_of_base(vec.b, 16)
			testing.expect(t, n_ok == true)

			err := big.root_n(res, a, int(n))
			testing.expect(t, err == vec.err)

			expect_ab(t, "Expected root_n(%v, %v) to be '%v', got %v", a, b, expected, res, err)

		case .Shl:
			bits, bits_ok := strconv.parse_i64_of_base(vec.b, 16)
			testing.expect(t, bits_ok == true)

			err := big.internal_int_shl(res, a, int(bits))
			testing.expect(t, err == vec.err)

			expect_ab(t, "Expected internal_int_shl(%v, %v) to be '%v', got %v", a, b, expected, res, err)

		case .Shr:
			bits, bits_ok := strconv.parse_i64_of_base(vec.b, 16)
			testing.expect(t, bits_ok == true)

			err := big.internal_int_shr(res, a, int(bits))
			testing.expect(t, err == vec.err)

			expect_ab(t, "Expected internal_int_shr(%v, %v) to be '%v', got %v", a, b, expected, res, err)

		case .Shr_Signed:
			bits, bits_ok := strconv.parse_i64_of_base(vec.b, 16)
			testing.expect(t, bits_ok == true)

			big.set(res, a)
			err := big.internal_int_shr_signed(res, res, int(bits))
			testing.expect(t, err == vec.err)

			expect_ab(t, "Expected internal_int_shr_signed(%v, %v) to be '%v', got %v", a, b, expected, res, err)

		case .Factorial:
			n, n_ok := strconv.parse_i64_of_base(vec.a, 16)
			testing.expect(t, n_ok == true)

			err := big.factorial(res, int(n))
			testing.expect(t, err == vec.err)

			expect_a(t, "Expected factorial(%v) to be '%v', got %v", a, expected, res, err)

		case .Gcd:
			err := big.internal_int_gcd_lcm(res, nil, a, b)
			testing.expect(t, err == vec.err)

			expect_ab(t, "Expected gcd(%v, %v) to be '%v', got %v", a, b, expected, res, err)

		case .Lcm:
			err := big.internal_int_gcd_lcm(nil, res, a, b)
			testing.expect(t, err == vec.err)

			expect_ab(t, "Expected lcm(%v, %v) to be '%v', got %v", a, b, expected, res, err)

		case .Is_Square:
			square, err := big.internal_int_is_square(a)
			testing.expect(t, err == vec.err)

			big.set(res, 1 if square else 0)
			expect_a(t, "Expected is_square(%v) to be '%v', got %v", a, expected, res, err)

		case:
			log.assertf(false, "Unhandled op: %v", vec.op)
		}
	}
}

expect_a :: proc(t: ^testing.T, format: string, a, expected, res: ^big.Int, err: big.Error, loc := #caller_location) {
	if err != .Okay { return }

	equal, _ := big.equals(res, expected)
	if !equal {
		as, _ := big.itoa(a)
		rs, _ := big.itoa(res)
		es, _ := big.itoa(expected)

		defer delete(as)
		defer delete(rs)
		defer delete(es)

		testing.expectf(t, equal, format, as, es, rs, loc=loc)
		assert(equal)
	}
}

expect_ab :: proc(t: ^testing.T, format: string, a, b, expected, res: ^big.Int, err: big.Error, loc := #caller_location) {
	if err != .Okay { return }

	equal, _ := big.equals(res, expected)
	if !equal {
		as, _ := big.itoa(a)
		bs, _ := big.itoa(b)
		rs, _ := big.itoa(res)
		es, _ := big.itoa(expected)

		defer delete(as)
		defer delete(bs)
		defer delete(rs)
		defer delete(es)

		testing.expectf(t, equal, format, as, bs, es, rs, loc=loc)
		assert(equal)
	}
}

atoi :: proc(t: ^testing.T, i: ^big.Int, a: string, loc := #caller_location) -> bool {
	err := big.atoi(i, a, 16)
	testing.expect(t, err == .Okay, loc=loc)
	return err == .Okay
}