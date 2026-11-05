package test_core_math_big

import "core:math/big"
import "core:mem"
import "core:strconv"
import "core:testing"

@(test)
test_int_destroy :: proc(t: ^testing.T) {
	a, b, zero: big.Int
	testing.expect_value(t, big.set(&a, -123456789), nil)
	testing.expect_value(t, big.set(&b, 987654321), nil)

	big.destroy(&a, &b, &zero)
	integers := [?]^big.Int{&a, &b, &zero}
	for integer in integers {
		testing.expect_value(t, integer.used, 0)
		testing.expect_value(t, raw_data(integer.digit), nil)
		testing.expect_value(t, len(integer.digit), 0)
		testing.expect_value(t, cap(integer.digit), 0)
		testing.expect_value(t, integer.sign, .Zero_or_Positive)
		testing.expect_value(t, integer.flags, {})
	}

	// Avoid accessing freed memory if destroy did not clear the integers.
	if testing.failed(t) {
		return
	}

	big.destroy(&a, &b, &zero)
	defer big.destroy(&a, &b, &zero)

	testing.expect_value(t, big.set(&a, 42), nil)
	value, err := big.get_i64(&a)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, value, 42)
}

@(test)
test_int_destroy_custom_allocator :: proc(t: ^testing.T) {
	tracker: mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracker, context.allocator)
	defer mem.tracking_allocator_destroy(&tracker)

	a: big.Int
	err := big.set(&a, 123456789, allocator = mem.tracking_allocator(&tracker))
	if !testing.expect_value(t, err, nil) {
		return
	}

	big.destroy(&a)

	testing.expect_value(t, len(tracker.allocation_map), 0)
	testing.expect_value(t, tracker.current_memory_allocated, 0)
}

@(test)
test_int_destroy_wipes_capacity :: proc(t: ^testing.T) {
	for length in 0..=1 {
		storage: [1024]byte
		arena: mem.Arena
		mem.arena_init(&arena, storage[:])

		a: big.Int
		err := big.set(&a, 123456789, allocator = mem.arena_allocator(&arena))
		if !testing.expect_value(t, err, nil) {
			return
		}

		backing := a.digit[:cap(a.digit)]
		for &digit in backing {
			digit = 42
		}
		testing.expect_value(t, resize(&a.digit, length), nil)

		big.destroy(&a)

		// The arena retains its backing memory after individual frees.
		for digit in backing {
			testing.expect_value(t, digit, 0)
		}
	}
}

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

			expect_ab(t, "Expected pow(%v, %v) to be %q, got %q", a, b, expected, res, err)

		case .Root:
			n, n_ok := strconv.parse_i64_of_base(vec.b, 16)
			testing.expect(t, n_ok == true)

			err := big.root_n(res, a, int(n))
			testing.expect(t, err == vec.err)

			expect_ab(t, "Expected root_n(%v, %v) to be %q, got %q", a, b, expected, res, err)

		case .Shl:
			bits, bits_ok := strconv.parse_i64_of_base(vec.b, 16)
			testing.expect(t, bits_ok == true)

			err := big.internal_int_shl(res, a, int(bits))
			testing.expect(t, err == vec.err)

			expect_ab(t, "Expected internal_int_shl(%v, %v) to be %q, got %q", a, b, expected, res, err)

		case .Shr:
			bits, bits_ok := strconv.parse_i64_of_base(vec.b, 16)
			testing.expect(t, bits_ok == true)

			err := big.internal_int_shr(res, a, int(bits))
			testing.expect(t, err == vec.err)

			expect_ab(t, "Expected internal_int_shr(%v, %v) to be %q, got %q", a, b, expected, res, err)

		case .Shr_Signed:
			bits, bits_ok := strconv.parse_i64_of_base(vec.b, 16)
			testing.expect(t, bits_ok == true)

			big.set(res, a)
			err := big.internal_int_shr_signed(res, res, int(bits))
			testing.expect(t, err == vec.err)

			expect_ab(t, "Expected internal_int_shr_signed(%v, %v) to be %q, got %q", a, b, expected, res, err)

		case .Factorial:
			n, n_ok := strconv.parse_i64_of_base(vec.a, 16)
			testing.expect(t, n_ok == true)

			err := big.factorial(res, int(n))
			testing.expect(t, err == vec.err)

			expect_a(t, "Expected factorial(%v) to be %q, got %q", a, expected, res, err)

		case .Gcd:
			err := big.internal_int_gcd_lcm(res, nil, a, b)
			testing.expect(t, err == vec.err)

			expect_ab(t, "Expected gcd(%v, %v) to be %q, got %q", a, b, expected, res, err)

		case .Lcm:
			err := big.internal_int_gcd_lcm(nil, res, a, b)
			testing.expect(t, err == vec.err)

			expect_ab(t, "Expected lcm(%v, %v) to be %q, got %q", a, b, expected, res, err)

		case .Is_Square:
			square, err := big.internal_int_is_square(a)
			testing.expect(t, err == vec.err)

			big.set(res, 1 if square else 0)
			expect_a(t, "Expected is_square(%v) to be %q, got %q", a, expected, res, err)

		case:
			log.assertf(false, "Unhandled op: %v", vec.op)
		}
	}
}

@(test)
bug_5931 :: proc(t: ^testing.T) {
	numerator, divisor, quotient, remainder: big.Int
	defer big.destroy(&numerator, &divisor, &quotient, &remainder)

	big.string_to_int(&numerator, "3351951982485649274893506249551461531869841455148098344430890360930192345844485855956241793418914802713278852793799976230545127411560969441984014513833901")
	big.string_to_int(&divisor,   "115792089237316195423570985008687907853269984665640564039457584007908834671663")

	big.int_divmod(&quotient, &remainder, &numerator, &divisor)
	quo_str, _ := big.int_itoa_string(&quotient)
	defer delete(quo_str)
	assert(quo_str == "28948022309329048855892746252171976963317496166410141009864396001977208667923")

	rem_str, _ := big.int_itoa_string(&remainder)
	defer delete(rem_str)
	assert(rem_str == "28948022309329048855892746252171976963317496166410141009864396001977208667952")
}

@(test)
bug_8033 :: proc(t: ^testing.T) {
	// b = 2^10080 + 1 is large enough to take the recursive division path.
	// (b * b + c) / b must give quotient b and remainder c for any 0 <= c < b.
	b, c, numerator, quotient, remainder: big.Int
	defer big.destroy(&b, &c, &numerator, &quotient, &remainder)

	big.set(&b, 1)
	big.shl(&b, &b, 10080)
	big.add(&b, &b, 1)

	for shift in ([]int{0, 1, 64, 5000, 10080}) {
		// c = 2^shift - 1
		big.set(&c, 1)
		big.shl(&c, &c, shift)
		big.sub(&c, &c, 1)

		big.mul(&numerator, &b, &b)
		big.add(&numerator, &numerator, &c)
		testing.expect_value(t, big.int_divmod(&quotient, &remainder, &numerator, &b), nil)

		quotient_cmp, _ := big.cmp(&quotient, &b)
		testing.expectf(t, quotient_cmp == 0, "Expected quotient to be b for c = 2^%v - 1", shift)
		remainder_cmp, _ := big.cmp(&remainder, &c)
		testing.expectf(t, remainder_cmp == 0, "Expected remainder to be c for c = 2^%v - 1", shift)
	}
}

@(test)
bug_rat_mul_rat_square :: proc(t: ^testing.T) {
	x, square: big.Rat
	defer big.destroy(&x, &square)

	big.rat_set_frac(&x, big.DIGIT(2), big.DIGIT(3))

	big.rat_mul_rat(&square, &x, &x)
	big.rat_mul_rat(&x, &x, &x)

	for r in ([]^big.Rat{&square, &x}) {
		num_str, _ := big.int_itoa_string(&r.a)
		defer delete(num_str)
		assert(num_str == "4")

		den_str, _ := big.int_itoa_string(&r.b)
		defer delete(den_str)
		assert(den_str == "9")
	}
}


// Test helpers

expect_a :: proc(t: ^testing.T, format: string, a, expected, res: ^big.Int, err: big.Error, loc := #caller_location) {
	if err != nil { return }

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
	if err != nil { return }

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
	testing.expect(t, err == nil, loc=loc)
	return err == nil
}

@(test)
test_atoi :: proc(t: ^testing.T) {
	a, b := &big.Int{}, &big.Int{}
	defer big.destroy(a, b)

	// Read back what `_itoa_raw_old` writes, in every radix, from a single input digit up to
	// several chunks, and for negative numbers.
	sizes := [?]int{8, 64, 200, 2048}
	for bits in sizes {
		for negative in ([?]bool{false, true}) {
			big.random(a, bits)
			if negative {
				big.neg(a, a)
			}
			for radix in 2..=64 {
				size, _ := big.radix_size(a, i8(radix), false)
				buffer := make([]u8, size)
				defer delete(buffer)
				written, _ := big._itoa_raw_old(a, i8(radix), buffer, false)
				input := string(buffer[:written])

				testing.expect_value(t, big.atoi(b, input, i8(radix)), nil)
				equal, _ := big.equals(a, b)
				testing.expectf(t, equal, "radix %v: atoi(%q) read back a different number", radix, input)
			}
		}
	}

	// What follows the number decides the error. `res` keeps the number read before it, sign
	// included, and `n` counts the characters read the way `strconv` does. Both paths, with a
	// partial chunk and with a full one.
	Case :: struct {
		input:    string,
		radix:    i8,
		err:      big.Error,
		expected: string,
		n:        int,
	}
	cases := [?]Case{
		{"1F",                                     16, nil,                  "31",                        2},
		{"-0",                                     10, nil,                  "0",                         2},
		{"+1",                                     64, nil,                  "3969",                      2},
		{"00000000000000000000000000000000000012", 10, nil,                  "12",                        38},

		{"1F\n",                                   16, .Trailing_Whitespace, "31",                        2},
		{"-ff\r\n",                                16, .Trailing_Whitespace, "-255",                      3},
		{"123456789abcdef\n",                      16, .Trailing_Whitespace, "81985529216486895",         15},
		{"123456789abcdef0123 ",                   16, .Trailing_Whitespace, "5373003642731685151011",    19},
		{"123 \t\v\f\r\n",                         10, .Trailing_Whitespace, "123",                       3},
		{"-12\x00\x00",                            10, .Trailing_Whitespace, "-12",                       3},
		{"1234567890123456789012345\n",            10, .Trailing_Whitespace, "1234567890123456789012345", 25},

		{"1Fg",                                    16, .Invalid_Character,   "31",                        2},
		{"f.f",                                    16, .Invalid_Character,   "15",                        1},
		{"-1x",                                    16, .Invalid_Character,   "-1",                        2},
		{"123456789abcdef0123x",                   16, .Invalid_Character,   "5373003642731685151011",    19},
		{"101012",                                 2,  .Invalid_Character,   "21",                        5},
		{"123x",                                   10, .Invalid_Character,   "123",                       3},
		{"12.3",                                   10, .Invalid_Character,   "12",                        2},
		{"-12x",                                   10, .Invalid_Character,   "-12",                       3},
		{"123456789012345678x",                    10, .Invalid_Character,   "123456789012345678",        18},
		{"1234567890123456789012345x",             10, .Invalid_Character,   "1234567890123456789012345", 25},
		{"12a",                                    10, .Invalid_Character,   "12",                        2},
		{"1\n23",                                  10, .Invalid_Character,   "1",                         1},
		{"12 \nx",                                 10, .Invalid_Character,   "12",                        2},
		{" 12",                                    10, .Invalid_Character,   "0",                         0},
		{"-x",                                     10, .Invalid_Character,   "0",                         1},
		{"--1",                                    10, .Invalid_Character,   "0",                         1},
		{"-\n",                                    10, .Invalid_Character,   "0",                         1},
		{"- \r\n",                                 16, .Invalid_Character,   "0",                         1},
		{"+1",                                     10, .Invalid_Character,   "0",                         0},

		{"",                                       10, .Empty_Input,         "0",                         0},
		{"-",                                      16, .Empty_Input,         "0",                         0},
		{"\n",                                     10, .Empty_Input,         "0",                         0},
		{" \t\x00",                                16, .Empty_Input,         "0",                         0},
	}
	for c in cases {
		n := -1
		err := big.atoi(b, c.input, c.radix, n = &n)
		str, _ := big.itoa(b, 10)
		defer delete(str)
		testing.expectf(t, err == c.err && str == c.expected && n == c.n,
			"atoi(%q, %v) = %v, %v, n = %v, expected %v, %v, n = %v", c.input, c.radix, err, str, n, c.err, c.expected, c.n)
	}

	// `strconv` sets the same `n` for input that both of them read.
	for input in ([?]string{"12", "-12", "12x", "-12x", "12 \n", "-12\n", "-", "-x", "- \r\n", "--1", "x", " 12", "\n", ""}) {
		n, strconv_n := -1, -1
		_ = big.atoi(b, input, 10, n = &n)
		_, _ = strconv.parse_i64_of_base(input, 10, &strconv_n)
		testing.expectf(t, n == strconv_n, "atoi(%q) set n = %v, strconv sets %v", input, n, strconv_n)
	}

	n := -1
	testing.expect_value(t, big.atoi(b, "12", 65, n = &n), big.Error.Invalid_Argument)
	testing.expect_value(t, n, 0)
}

@(test)
test_digit_power_of_two :: proc(t: ^testing.T) {
	// `int` is 32 bits on 32-bit targets, so these used to see only the low 32 bits of a `DIGIT`.
	// The low 32 bits of `D` are a power of two, but `D` isn't one.
	D :: big.DIGIT(1 << 32 | 1 << 30)

	a, b, q := &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(a, b, q)

	big.set(a, 3)
	testing.expect_value(t, big.int_mul_digit(b, a, D), nil)
	product, _ := big.get(b, u64)
	testing.expect_value(t, product, 3 * u64(D))

	remainder, err := big.int_divmod_digit(q, b, D)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, remainder, 0)
	quotient, _ := big.get(q, u64)
	testing.expect_value(t, quotient, 3)

	big.set(a, u64(1) << 40)
	power_of_two, _ := big.int_is_power_of_two(a)
	testing.expect(t, power_of_two, "1 << 40 is a power of two")

	big.set(a, u64(1) << 32 | 1)
	power_of_two, _ = big.int_is_power_of_two(a)
	testing.expect(t, !power_of_two, "1 << 32 | 1 isn't a power of two")

	// D^1 <= 1 << 64 < D^2
	big.set(a, 1)
	big.int_shl(a, a, 64)
	log_d, _ := big.int_log(a, D)
	testing.expect_value(t, log_d, 1)
}

@(test)
test_itoa :: proc(t: ^testing.T) {
	a := &big.Int{}
	big.random(a, 2048)
	defer big.destroy(a)

	for radix in 2..=64 {
		if big.is_power_of_two(radix) {
			// Powers of two are trivial, and are handled before `_itoa_raw_*` is called.
			continue
		}

		size, _ := big.radix_size(a, i8(radix), false)
		buffer_old := make([]u8, size)
		defer delete(buffer_old)
		buffer_new := make([]u8, size)
		defer delete(buffer_new)

		written_old, _ := big._itoa_raw_old (a, i8(radix), buffer_old, false)
		written_new, _ := big._itoa_raw_full(a, i8(radix), buffer_new, false)

		str_old := string(buffer_old[:written_old])
		str_new := string(buffer_new[:written_new])
		testing.expect_value(t, str_new, str_old)
	}

	// Also test a number with a large number of zeroes
	big.set(a, "2970714761494550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000802525522395693895558562897961119110387707542077460459880227570865486047631557732177235787527971863645406120285117781450154113859156752194121206131440514109132606823127467068869589613665129498148285292867292641704871893467328665051712596763187306247339023362481")
	size, _ := big.radix_size(a, 10, false)
	buffer_old := make([]u8, size)
	defer delete(buffer_old)
	buffer_new := make([]u8, size)
	defer delete(buffer_new)

	written_old, _ := big._itoa_raw_old (a, 10, buffer_old, false)
	written_new, _ := big._itoa_raw_full(a, 10, buffer_new, false)

	str_old := string(buffer_old[:written_old])
	str_new := string(buffer_new[:written_new])
	testing.expect_value(t, str_new, str_old)
}