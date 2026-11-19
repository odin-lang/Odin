package test_core_math_big

import "core:math/big"
import "core:mem"
import "core:os"
import "core:testing"

@(private="file")
reg_set :: proc(t: ^testing.T, a: ^big.Int, value: string, radix := i8(10), loc := #caller_location) {
	testing.expect_value(t, big.atoi(a, value, radix), nil, loc=loc)
}

@(private="file")
reg_pow2 :: proc(t: ^testing.T, a: ^big.Int, power: int, delta := i64(0), loc := #caller_location) {
	d := &big.Int{}
	defer big.destroy(d)
	testing.expect_value(t, big.power_of_two(a, power), nil, loc=loc)
	testing.expect_value(t, big.set(d, delta), nil, loc=loc)
	testing.expect_value(t, big.add(a, a, d), nil, loc=loc)
}

@(private="file")
reg_ones :: proc(t: ^testing.T, a: ^big.Int, limbs: int, loc := #caller_location) {
	reg_pow2(t, a, limbs * big._DIGIT_BITS, -1, loc)
}

@(private="file")
reg_valid :: proc(t: ^testing.T, got: ^big.Int, loc := #caller_location) -> bool {
	valid := got.used >= 0 && got.used <= len(got.digit)
	if valid && got.used > 0 && got.digit[got.used - 1] == 0 {
		valid = false
	}
	if got.used == 0 && got.sign == .Negative {
		valid = false
	}
	if valid {
		for i in 0..<len(got.digit) {
			if got.digit[i] > big._MASK || (i >= got.used && got.digit[i] != 0) {
				valid = false
			}
		}
	}
	return testing.expectf(t, valid, "invalid Int (used=%v len=%v sign=%v)", got.used, len(got.digit), got.sign, loc=loc)
}

@(private="file")
reg_expect :: proc(t: ^testing.T, got: ^big.Int, expected: string, radix := i8(10), loc := #caller_location) {
	if !reg_valid(t, got, loc) {
		return
	}
	s, err := big.int_itoa_string(got, radix, false, context.temp_allocator)
	testing.expect_value(t, err, nil, loc=loc)
	testing.expect_value(t, s, expected, loc=loc)
}

@(private="file")
reg_expect_i64 :: proc(t: ^testing.T, got: ^big.Int, expected: i64, loc := #caller_location) {
	if !reg_valid(t, got, loc) {
		return
	}
	v, err := big.get_i64(got)
	testing.expect_value(t, err, nil, loc=loc)
	testing.expect_value(t, v, expected, loc=loc)
}

@(private="file")
reg_rat_set :: proc(t: ^testing.T, r: ^big.Rat, num, den: string, radix := i8(10), loc := #caller_location) {
	n, d := &big.Int{}, &big.Int{}
	defer big.destroy(n, d)
	reg_set(t, n, num, radix, loc)
	reg_set(t, d, den, radix, loc)
	testing.expect_value(t, big.rat_set_frac_int(r, n, d), nil, loc=loc)
}

@(private="file")
reg_rat_expect :: proc(t: ^testing.T, r: ^big.Rat, num, den: string, radix := i8(10), loc := #caller_location) {
	reg_expect(t, &r.a, num, radix, loc)
	reg_expect(t, &r.b, den, radix, loc)
}

@(private="file")
Reg_Fail_State :: struct {
	backing: mem.Allocator,
	count:   int,
	fail_at: int,
	active:  bool,
}

@(private="file")
reg_fail_proc :: proc(data: rawptr, mode: mem.Allocator_Mode, size, alignment: int, old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, mem.Allocator_Error) {
	st := (^Reg_Fail_State)(data)
	if st.active {
		#partial switch mode {
		case .Alloc, .Alloc_Non_Zeroed, .Resize, .Resize_Non_Zeroed:
			st.count += 1
			if st.count == st.fail_at {
				return nil, .Out_Of_Memory
			}
		}
	}
	return st.backing.procedure(st.backing.data, mode, size, alignment, old_memory, old_size, loc)
}

@(test)
test_regression_halve_double :: proc(t: ^testing.T) {
	a, x := &big.Int{}, &big.Int{}
	defer big.destroy(a, x)

	Case :: struct {
		a, result: string,
	}
	halve_cases := []Case{
		{"-3",                                        "-1"},
		{"-1",                                        "0"},
		{"-1361129467683753853853498429727072845829", "-680564733841876926926749214863536422914"},
	}
	for c in halve_cases {
		reg_set(t, a, c.a)
		testing.expect_value(t, big.halve(x, a), nil)
		reg_expect(t, x, c.result)
	}

	double_cases := []Case{
		{"9223372036854775807",                                       "18446744073709551614"},
		{"-784637716923335095479473677900958302012794430558004314112", "-1569275433846670190958947355801916604025588861116008628224"},
		{"0",                                                         "0"},
	}
	for c in double_cases {
		reg_set(t, a, c.a)
		testing.expect_value(t, big.double(x, a), nil)
		reg_expect(t, x, c.result)
	}
}

@(test)
test_regression_divmod_signs :: proc(t: ^testing.T) {
	n, d, q, r, x := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(n, d, q, r, x)

	Case :: struct {
		n, d, q, r, m: i64,
	}
	cases := []Case{
		{ 7,  2,  3,  1,  1},
		{-7,  2, -3, -1,  1},
		{ 7, -2, -3,  1, -1},
		{-7, -2,  3, -1, -1},
		{ 1,  7,  0,  1,  1},
		{-1,  7,  0, -1,  6},
		{-6,  3, -2,  0,  0},
	}
	for c in cases {
		big.set(n, c.n)
		big.set(d, c.d)
		testing.expect_value(t, big.divmod(q, r, n, d), nil)
		reg_expect_i64(t, q, c.q)
		reg_expect_i64(t, r, c.r)
		testing.expect_value(t, big.div(x, n, d), nil)
		reg_expect_i64(t, x, c.q)
		testing.expect_value(t, big.mod(x, n, d), nil)
		reg_expect_i64(t, x, c.m)
	}

	big.set(n, 5)
	big.set(d, 0)
	testing.expect_value(t, big.div(x, n, d), big.Error.Division_by_Zero)
	testing.expect_value(t, big.divmod(q, r, n, d), big.Error.Division_by_Zero)
	testing.expect_value(t, big.mod(x, n, d), big.Error.Division_by_Zero)
	_, err := big.divmod(q, n, big.DIGIT(0))
	testing.expect_value(t, err, big.Error.Division_by_Zero)
	testing.expect_value(t, big.div(q, n, big.DIGIT(0)), big.Error.Division_by_Zero)
}

@(test)
test_regression_divmod_digit :: proc(t: ^testing.T) {
	n, q := &big.Int{}, &big.Int{}
	defer big.destroy(n, q)

	reg_pow2(t, n, 200, 12345)

	Case :: struct {
		d: big.DIGIT,
		q: string,
		r: big.DIGIT,
	}
	cases := []Case{
		{18446744073709551615, "87112285931760246651346265985402307346688",                     12601},
		{3,                    "535646014752996758513987364113720867507400997927597611771240",   1},
		{4611686018427387905,  "348449143727040986510937734284216325128191",                    4611686018427383866},
		{9223372036854775809,  "174224571863520493274358333073586743412736",                    10297},
	}
	for c in cases {
		r, err := big.divmod(q, n, c.d)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, r, c.r)
		reg_expect(t, q, c.q)
	}

	r, err := big.mod(n, big.DIGIT(999999999999999989))
	testing.expect_value(t, err, nil)
	testing.expect_value(t, r, 364873406942469900)

	big.set(n, -7)
	r, err = big.divmod(q, n, big.DIGIT(2))
	testing.expect_value(t, err, nil)
	testing.expect_value(t, r, 1)
	reg_expect_i64(t, q, -3)

	r, err = big.divmod(q, n, big.DIGIT(1))
	testing.expect_value(t, err, nil)
	testing.expect_value(t, r, 0)
	reg_expect_i64(t, q, -7)
}

@(test)
test_regression_mod_bits :: proc(t: ^testing.T) {
	a, x := &big.Int{}, &big.Int{}
	defer big.destroy(a, x)

	reg_set(t, a, "-1361129467683753853853498429727072845829")
	testing.expect_value(t, big.mod_bits(x, a, 64), nil)
	reg_expect_i64(t, x, -5)
	testing.expect_value(t, big.mod_bits(x, a, 0), nil)
	reg_expect_i64(t, x, 0)
	testing.expect_value(t, big.mod_bits(x, a, -1), big.Error.Invalid_Argument)

	reg_set(t, a, "1361129467683753853853498429727072845829")
	testing.expect_value(t, big.mod_bits(x, a, 130), nil)
	reg_expect_i64(t, x, 5)
	testing.expect_value(t, big.mod_bits(x, a, 131), nil)
	reg_expect(t, x, "1361129467683753853853498429727072845829")
	testing.expect_value(t, big.mod_bits(x, a, 1000), nil)
	reg_expect(t, x, "1361129467683753853853498429727072845829")

	testing.expect_value(t, big.mod_bits(a, a, 126), nil)
	reg_expect_i64(t, a, 5)
}

@(test)
test_regression_gcd_lcm :: proc(t: ^testing.T) {
	a, b, g, l := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(a, b, g, l)

	Case :: struct {
		a, b, gcd, lcm: string,
	}
	cases := []Case{
		{"-12", "18", "6", "36"},
		{"0",   "-5", "5", "0"},
		{"0",   "0",  "0", "0"},
		{"-4",  "6",  "2", "12"},
		{"-4",  "-6", "2", "12"},
		{"1361129467683753853853498429727072845824", "3541774862152233910272", "1180591620717411303424", "4083388403051261561560495289181218537472"},
		{"359579325206583560961765665172189099052367214309267232255589801", "222232244629420445529739893461909967206666939096499764990979600", "1", "79910120562991407400855037269648455626959263786477851492702924332928417391045244352241316094168328827198660591058442759059600"},
		{"6633067786283024899705737090835023421818660167907645618803248257159274560655335829", "4099461341604932936193880503401671848181392391546236121189611031211377545485768400", "18446744073709551629", ""},
		{"1606938044258990275541962092341162602522202993782792835313721", "999999999999999989", "1", ""},
	}
	for c in cases {
		reg_set(t, a, c.a)
		reg_set(t, b, c.b)
		testing.expect_value(t, big.gcd(g, a, b), nil)
		reg_expect(t, g, c.gcd)
		if c.lcm != "" {
			testing.expect_value(t, big.lcm(l, a, b), nil)
			reg_expect(t, l, c.lcm)
			testing.expect_value(t, big.gcd_lcm(g, l, a, b), nil)
			reg_expect(t, g, c.gcd)
			reg_expect(t, l, c.lcm)
		}
	}

	reg_pow2(t, a, 189, -1)
	reg_pow2(t, b, 126, -1)
	testing.expect_value(t, big.gcd_lcm(g, l, a, b), nil)
	reg_expect(t, g, "9223372036854775807")
	reg_expect(t, l, "7237005577332262214757824279966329336308847719503493554469670059015720140799")

	big.set(a, -12)
	big.set(b, 18)
	testing.expect_value(t, big.gcd(a, a, b), nil)
	reg_expect_i64(t, a, 6)

	big.set(a, -4)
	big.set(b, 6)
	testing.expect_value(t, big.gcd_lcm(a, b, a, b), nil)
	reg_expect_i64(t, a, 2)
	reg_expect_i64(t, b, 12)

	big.set(a, 6)
	big.set(b, -4)
	testing.expect_value(t, big.gcd_lcm(b, a, a, b), nil)
	reg_expect_i64(t, b, 2)
	reg_expect_i64(t, a, 12)

	big.set(a, 4)
	big.set(b, 6)
	testing.expect_value(t, big.lcm(b, a, b), nil)
	reg_expect_i64(t, b, 12)

	big.set(a, -7)
	testing.expect_value(t, big.gcd_lcm(g, l, a, a), nil)
	reg_expect_i64(t, g, 7)
	reg_expect_i64(t, l, 7)
	testing.expect_value(t, big.lcm(a, a, a), nil)
	reg_expect_i64(t, a, 7)

	U64_Case :: struct {
		a, b, gcd: u64,
	}
	u64_cases := []U64_Case{
		{max(u64),             1 << 63,                    1},
		{max(u64) - 1,         1 << 63 + 2,                2},
		{0xFFFFFFFF00000000,   max(u64) - (1 << 33) + 1,   4294967296},
		{0,                    0,                          0},
	}
	for c in u64_cases {
		testing.expect_value(t, big._private_gcd_u64(c.a, c.b), c.gcd)
	}
}

@(test)
test_regression_factorial_choose :: proc(t: ^testing.T) {
	x := &big.Int{}
	defer big.destroy(x)

	Case :: struct {
		n:      int,
		result: string,
	}
	cases := []Case{
		{0,  "1"},
		{1,  "1"},
		{20, "2432902008176640000"},
		{25, "15511210043330985984000000"},
		{35, "10333147966386144929666651337523200000000"},
	}
	for c in cases {
		testing.expect_value(t, big.factorial(x, c.n), nil)
		reg_expect(t, x, c.result)
		testing.expect_value(t, big._private_int_factorial_binary_split(x, c.n), nil)
		reg_expect(t, x, c.result)
	}
	testing.expect_value(t, big.factorial(x, -1), big.Error.Invalid_Argument)
	testing.expect_value(t, big.factorial(x, big.FACTORIAL_MAX_N + 1), big.Error.Invalid_Argument)

	Choose_Case :: struct {
		n, k:   int,
		result: string,
	}
	choose_cases := []Choose_Case{
		{100, 30, "29372339821610944823963760"},
		{5,   0,  "1"},
		{5,   5,  "1"},
	}
	for c in choose_cases {
		testing.expect_value(t, big.choose(x, c.n, c.k), nil)
		reg_expect(t, x, c.result)
	}
	testing.expect_value(t, big.choose(x, -1, 0), big.Error.Invalid_Argument)
}

@(test)
test_regression_modular :: proc(t: ^testing.T) {
	a, b, m, x := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(a, b, m, x)

	big.set(a, -4)
	big.set(b, -5)
	big.set(m, 7)
	testing.expect_value(t, big.addmod(x, a, b, m), nil)
	reg_expect_i64(t, x, 5)

	big.set(a, 4)
	big.set(b, 5)
	big.set(m, -7)
	testing.expect_value(t, big.submod(x, a, b, m), nil)
	reg_expect_i64(t, x, -1)

	big.set(a, -5)
	big.set(b, 7)
	big.set(m, 3)
	testing.expect_value(t, big.mulmod(x, a, b, m), nil)
	reg_expect_i64(t, x, 1)

	big.set(a, -3)
	big.set(m, 5)
	testing.expect_value(t, big.sqrmod(x, a, m), nil)
	reg_expect_i64(t, x, 4)

	big.set(a, -3)
	big.set(b, 5)
	big.set(m, 7)
	testing.expect_value(t, big.addmod(a, a, b, m), nil)
	reg_expect_i64(t, a, 2)

	big.set(a, -3)
	big.set(m, 0)
	testing.expect_value(t, big.addmod(x, a, b, m), big.Error.Division_by_Zero)
}

@(test)
test_regression_add_sub :: proc(t: ^testing.T) {
	a, b, x := &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(a, b, x)

	Case :: struct {
		a:      string,
		d:      big.DIGIT,
		result: string,
	}
	sub_cases := []Case{
		{"0",                   5, "-5"},
		{"3",                   5, "-2"},
		{"5",                   5, "0"},
		{"9223372036854775808", 1, "9223372036854775807"},
	}
	for c in sub_cases {
		reg_set(t, a, c.a)
		testing.expect_value(t, big.sub(x, a, c.d), nil)
		reg_expect(t, x, c.result)
	}
	add_cases := []Case{
		{"9223372036854775807", 1, "9223372036854775808"},
		{"-3",                  5, "2"},
		{"0",                   0, "0"},
	}
	for c in add_cases {
		reg_set(t, a, c.a)
		testing.expect_value(t, big.add(x, a, c.d), nil)
		reg_expect(t, x, c.result)
	}

	Step_Case :: struct {
		a, result: string,
	}
	decr_cases := []Step_Case{
		{"0",                    "-1"},
		{"1",                    "0"},
		{"-9223372036854775807", "-9223372036854775808"},
	}
	for c in decr_cases {
		reg_set(t, a, c.a)
		testing.expect_value(t, big.internal_decr(a), nil)
		reg_expect(t, a, c.result)
	}
	reg_set(t, a, "9223372036854775807")
	testing.expect_value(t, big.internal_incr(a), nil)
	reg_expect(t, a, "9223372036854775808")

	big.set(a, 5)
	big.set(b, -5)
	testing.expect_value(t, big.add(x, a, b), nil)
	reg_expect_i64(t, x, 0)
	big.set(a, -5)
	testing.expect_value(t, big.sub(x, a, a), nil)
	reg_expect_i64(t, x, 0)
	big.set(a, 5)
	testing.expect_value(t, big.add(a, a, a), nil)
	reg_expect_i64(t, a, 10)
}

@(test)
test_regression_mul_sqr :: proc(t: ^testing.T) {
	a, b, c, e := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(a, b, c, e)

	reg_set(t, a, "-85070591730234615865843651857942052871")
	big.set(b, -3)
	testing.expect_value(t, big.internal_mul(c, a, b), nil)
	reg_expect(t, c, "255211775190703847597530955573826158613")

	reg_set(t, a, "784637716923335095479473677900958302012794430558004314111")
	testing.expect_value(t, big.sqr(c, a), nil)
	reg_expect(t, c, "615656346818663737691860001564743965704370926101022604185122809007492732488684968447545993628551218026487553720321")

	big.set(a, -7)
	big.set(b, 0)
	testing.expect_value(t, big.mul(c, a, b), nil)
	reg_expect_i64(t, c, 0)
	testing.expect_value(t, big.mul(c, a, big.DIGIT(0)), nil)
	reg_expect_i64(t, c, 0)
	testing.expect_value(t, big.mul(c, a, big.DIGIT(1 << 62)), nil)
	reg_expect(t, c, "-32281802128991715328")

	reg_ones(t, a, 4)
	testing.expect_value(t, big._private_int_mul_comba(c, a, a, 8), nil)
	reg_expect(t, c, "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE000000000000000000000000000000000000000000000000000000000000001", 16)

	reg_ones(t, a, 1)
	testing.expect_value(t, big._private_int_sqr_comba(c, a), nil)
	reg_expect(t, c, "3FFFFFFFFFFFFFFF0000000000000001", 16)

	reg_ones(t, a, 3)
	testing.expect_value(t, big.clear(c), nil)
	testing.expect_value(t, big._private_int_mul_high(c, a, a, 3), nil)
	reg_expect(t, c, "3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFD000000000000000400000000000000000000000000000000000000000000000", 16)

	reg_ones(t, a, 5)
	testing.expect_value(t, big.clear(c), nil)
	testing.expect_value(t, big._private_int_mul_high(c, a, a, 4), nil)
	reg_expect(t, c, "3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFD0000000000000005000000000000000000000000000000000000000000000000000000000000000", 16)

	reg_ones(t, a, 10)
	reg_ones(t, b, 9)
	testing.expect_value(t, big._private_int_mul(c, a, b, 12), nil)
	reg_expect(t, c, "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFFF8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001", 16)

	shapes := [?][2]int{{160, 400}, {350, 351}, {400, 400}}
	for s in shapes {
		reg_ones(t, a, s[0])
		reg_ones(t, b, s[1])
		if s[0] == s[1] {
			testing.expect_value(t, big.sqr(c, a), nil)
		} else {
			testing.expect_value(t, big.mul(c, a, b), nil)
		}
		reg_pow2(t, e, (s[0] + s[1]) * big._DIGIT_BITS, 1)
		reg_pow2(t, b, s[0] * big._DIGIT_BITS)
		testing.expect_value(t, big.sub(e, e, b), nil)
		reg_pow2(t, b, s[1] * big._DIGIT_BITS)
		testing.expect_value(t, big.sub(e, e, b), nil)
		cmp, err := big.cmp(c, e)
		testing.expect_value(t, err, nil)
		testing.expectf(t, cmp == 0, "(2^(63*%v) - 1) * (2^(63*%v) - 1) mismatch", s[0], s[1])
		reg_valid(t, c)
	}
}

@(test)
test_regression_div_3 :: proc(t: ^testing.T) {
	a, q := &big.Int{}, &big.Int{}
	defer big.destroy(a, q)

	big.set(a, -7)
	rem, err := big._private_int_div_3(q, a)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, rem, 1)
	reg_expect_i64(t, q, -2)

	big.set(a, -2)
	rem, err = big._private_int_div_3(q, a)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, rem, 2)
	reg_expect_i64(t, q, 0)
}

@(test)
test_regression_compare :: proc(t: ^testing.T) {
	a, b := &big.Int{}, &big.Int{}
	defer big.destroy(a, b)

	Digit_Case :: struct {
		a:   string,
		d:   big.DIGIT,
		cmp: int,
	}
	digit_cases := []Digit_Case{
		{"-5",                  5,          -1},
		{"0",                   0,           0},
		{"9223372036854775807", big._MASK,   0},
		{"9223372036854775808", 5,           1},
		{"3",                   5,          -1},
	}
	for c in digit_cases {
		reg_set(t, a, c.a)
		cmp, err := big.cmp(a, c.d)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, cmp, c.cmp)
	}

	big.set(a, 5)
	ok, err := big.lteq(a, big.DIGIT(5))
	testing.expect_value(t, err, nil)
	testing.expect_value(t, ok, true)
	big.set(a, -5)
	ok, err = big.gteq(a, big.DIGIT(0))
	testing.expect_value(t, ok, false)
	big.set(a, 6)
	ok, err = big.gt(a, big.DIGIT(5))
	testing.expect_value(t, ok, true)
	big.set(a, -5)
	ok, err = big.eq(a, big.DIGIT(5))
	testing.expect_value(t, ok, false)

	reg_pow2(t, a, 126)
	testing.expect_value(t, big.neg(a, a), nil)
	reg_pow2(t, b, 126)
	cmp: int
	cmp, err = big.cmp(a, b)
	testing.expect_value(t, cmp, -1)
	reg_pow2(t, b, 126, 1)
	testing.expect_value(t, big.neg(b, b), nil)
	cmp, err = big.cmp(a, b)
	testing.expect_value(t, cmp, 1)

	big.set(a, -5)
	big.set(b, 3)
	cmp, err = big.cmp_mag(a, b)
	testing.expect_value(t, cmp, 1)

	reg_pow2(t, a, 63)
	cmp, err = big.cmp(a, big.DIGIT(1 << 63 - 1))
	testing.expect_value(t, cmp, 1)

	big.set(a, -1)
	big.set(b, 0)
	ok, err = big.lt(a, b)
	testing.expect_value(t, ok, true)
	big.set(a, -5)
	big.set(b, 5)
	ok, err = big.greater_than_or_equal_abs(a, b)
	testing.expect_value(t, ok, true)
	ok, err = big.eq_abs(a, b)
	testing.expect_value(t, ok, true)
}

@(test)
test_regression_sqrt_is_square :: proc(t: ^testing.T) {
	a, x := &big.Int{}, &big.Int{}
	defer big.destroy(a, x)

	Case :: struct {
		a, root: string,
	}
	cases := []Case{
		{"6277101735386680763835789423207666416102355444464034512895", "79228162514264337593543950335"},
		{"85070591730234615865843651857942052863",                     "9223372036854775807"},
		{"85070591730234615884290395931651604480",                     "9223372036854775808"},
		{"99999999999999999999999999999999999999",                     "9999999999999999999"},
	}
	for c in cases {
		reg_set(t, a, c.a)
		testing.expect_value(t, big.sqrt(x, a), nil)
		reg_expect(t, x, c.root)
	}
	big.set(a, -1)
	testing.expect_value(t, big.sqrt(x, a), big.Error.Invalid_Argument)

	Square_Case :: struct {
		a:      string,
		square: bool,
	}
	square_cases := []Square_Case{
		{"85070591730234615884290395931651604481", true},
		{"85070591730234615884290395931651604480", false},
		{"18446744082299486209",                   true},
		{"-4",                                     false},
	}
	for c in square_cases {
		reg_set(t, a, c.a)
		square, err := big.int_is_square(a)
		testing.expect_value(t, err, nil)
		testing.expectf(t, square == c.square, "is_square(%v) = %v", c.a, square)
	}
}

@(test)
test_regression_pow_log :: proc(t: ^testing.T) {
	a, x := &big.Int{}, &big.Int{}
	defer big.destroy(a, x)

	Pow_Case :: struct {
		base:   i64,
		power:  int,
		result: string,
	}
	pow_cases := []Pow_Case{
		{2,  100, "1267650600228229401496703205376"},
		{0,  0,   "1"},
		{-3, 41,  "-36472996377170786403"},
		{-2, 63,  "-9223372036854775808"},
		{3,  40,  "12157665459056928801"},
	}
	for c in pow_cases {
		big.set(a, c.base)
		testing.expect_value(t, big.pow(x, a, c.power), nil)
		reg_expect(t, x, c.result)
		testing.expect_value(t, big.pow(x, int(c.base), c.power), nil)
		reg_expect(t, x, c.result)
	}
	big.set(a, 0)
	testing.expect_value(t, big.pow(x, a, -1), big.Error.Math_Domain_Error)

	Log_Case :: struct {
		a:    string,
		base: big.DIGIT,
		log:  int,
	}
	log_cases := []Log_Case{
		{"1000",                                    10, 3},
		{"1000000000000000000",                     10, 18},
		{"999999999999999999",                      10, 17},
		{"12157665459056928801",                    3,  40},
		{"12157665459056928800",                    3,  39},
		{"85070591730234615865843651857942052864",  7,  44},
		{"15286700631942576193765185769276826401",  7,  44},
		{"15286700631942576193765185769276826400",  7,  43},
		{"85070591730234615865843651857942052864",  8,  42},
		{"85070591730234615865843651857942052863",  8,  41},
		{"9223372036854775808", 4611686018427387904,    1},
	}
	for c in log_cases {
		reg_set(t, a, c.a)
		l, err := big.log(a, c.base)
		testing.expect_value(t, err, nil)
		testing.expectf(t, l == c.log, "log(%v, %v) = %v, expected %v", c.a, c.base, l, c.log)
	}

	big.set(a, 0)
	l, err := big.log(a, 10)
	testing.expect_value(t, err, big.Error.Math_Domain_Error)
	testing.expect_value(t, l, -1)
	big.set(a, 5)
	_, err = big.log(a, 1)
	testing.expect_value(t, err, big.Error.Invalid_Argument)

	Digit_Log_Case :: struct {
		a, base: big.DIGIT,
		log:     int,
	}
	digit_log_cases := []Digit_Log_Case{
		{1000,                10, 3},
		{1 << 62,             2,  62},
		{1000000000000000000, 10, 18},
		{999999999999999999,  10, 17},
		{1,                   7,  0},
	}
	for c in digit_log_cases {
		l, err = big.log(c.a, c.base)
		testing.expect_value(t, err, nil)
		testing.expectf(t, l == c.log, "log(DIGIT(%v), %v) = %v, expected %v", c.a, c.base, l, c.log)
	}

	reg_set(t, a, "265613988875874769338781322035779626829233452653394495974574961739092490901302182994384699044001")
	l, err = big._private_int_log(a, 3)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, l, 200)
	testing.expect_value(t, big.sub(a, a, 1), nil)
	l, err = big._private_int_log(a, 3)
	testing.expect_value(t, l, 199)
	testing.expect_value(t, big.add(a, a, 2), nil)
	l, err = big._private_int_log(a, 3)
	testing.expect_value(t, l, 200)

	reg_set(t, a, "7FFFFFFFFFFFFFF6000000000000004FFFFFFFFFFFFFFEC0000000000000027FFFFFFFFFFFFFFE0", 16)
	l, err = big._private_int_log(a, big._MASK - 1)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, l, 5)
	testing.expect_value(t, big.sub(a, a, 1), nil)
	l, err = big._private_int_log(a, big._MASK - 1)
	testing.expect_value(t, l, 4)
}

@(test)
test_regression_predicates :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	testing.expect_value(t, big.int_is_initialized(&big.Int{}), false)

	big.set(a, 0)
	ok, err := big.is_zero(a)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, ok, true)
	ok, err = big.is_positive(a)
	testing.expect_value(t, ok, true)
	ok, err = big.is_even(a)
	testing.expect_value(t, ok, true)

	big.set(a, -3)
	ok, err = big.is_negative(a)
	testing.expect_value(t, ok, true)
	ok, err = big.is_odd(a)
	testing.expect_value(t, ok, true)

	big.set(a, -4)
	ok, err = big.is_even(a)
	testing.expect_value(t, ok, true)

	reg_pow2(t, a, 126)
	ok, err = big.is_even(a)
	testing.expect_value(t, ok, true)
	reg_pow2(t, a, 63, 1)
	ok, err = big.is_odd(a)
	testing.expect_value(t, ok, true)
}

@(test)
test_regression_logical :: proc(t: ^testing.T) {
	a, b, x := &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(a, b, x)

	Case :: struct {
		a, b, and, or, xor: string,
	}
	cases := []Case{
		{"5", "-5", "1", "-1", "-2"},
		{"-5", "-123456789012345678901234567890", "-123456789012345678901234567894", "-1", "123456789012345678901234567893"},
		{"123456789012345678901234567890", "-9223372036854775808", "123456789007485203164252078080", "-4362896299872285998", "-123456789011848099464124364078"},
		{"-123456789012345678901234567890", "-9223372036854775808", "-123456789016708575201106853888", "-4860475736982489810", "123456789011848099464124364078"},
		{"-9223372036854775808", "9223372036854775808", "9223372036854775808", "-9223372036854775808", "-18446744073709551616"},
		{"-5", "3", "3", "-5", "-8"},
		{"-9223372036854775808", "9223372036854775807", "0", "-1", "-1"},
		{"-85070591730234615865843651857942052869", "170141183460469231731687303715884105727", "85070591730234615865843651857942052859", "-1", "-85070591730234615865843651857942052860"},
		{"-85070591730234615865843651857942052864", "-9223372036854775808", "-85070591730234615865843651857942052864", "-9223372036854775808", "85070591730234615856620279821087277056"},
		{"-9223372036854775809", "-9223372036854775808", "-18446744073709551616", "-1", "18446744073709551615"},
		{"-1180591620717411303424", "1180591620717411303423", "0", "-1", "-1"},
		{"-1", "170141183460469231731687303715884105727", "170141183460469231731687303715884105727", "-1", "-170141183460469231731687303715884105728"},
	}
	for c in cases {
		reg_set(t, a, c.a)
		reg_set(t, b, c.b)
		testing.expect_value(t, big.bit_and(x, a, b), nil)
		reg_expect(t, x, c.and)
		testing.expect_value(t, big.bit_or(x, a, b), nil)
		reg_expect(t, x, c.or)
		testing.expect_value(t, big.bit_xor(x, a, b), nil)
		reg_expect(t, x, c.xor)
	}

	big.set(a, -7)
	testing.expect_value(t, big.bit_and(a, a, a), nil)
	reg_expect_i64(t, a, -7)

	reg_pow2(t, a, 126)
	testing.expect_value(t, big.neg(a, a), nil)
	big.set(b, 1)
	testing.expect_value(t, big.bit_or(x, a, b), nil)
	reg_expect(t, x, "-85070591730234615865843651857942052863")
	reg_pow2(t, a, 63, 1)
	testing.expect_value(t, big.neg(a, a), nil)
	reg_pow2(t, b, 63)
	testing.expect_value(t, big.bit_or(x, a, b), nil)
	reg_expect_i64(t, x, -1)

	Complement_Case :: struct {
		a, result: i64,
	}
	complement_cases := []Complement_Case{
		{0,         -1},
		{5,         -6},
		{-5,         4},
		{-1,         0},
		{max(i64),   min(i64)},
	}
	for c in complement_cases {
		big.set(a, c.a)
		testing.expect_value(t, big.bit_complement(x, a), nil)
		reg_expect_i64(t, x, c.result)
	}
	testing.expect_value(t, big.bit_complement(x, big.INT_ZERO), nil)
	reg_expect_i64(t, x, -1)
	reg_expect_i64(t, big.INT_ZERO, 0)
	testing.expect_value(t, big.INT_ZERO.flags, big.Flags{.Immutable})
}

@(test)
test_regression_shifts :: proc(t: ^testing.T) {
	a, q, r := &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(a, q, r)

	Shl_Case :: struct {
		a:      string,
		bits:   int,
		result: string,
	}
	shl_cases := []Shl_Case{
		{"-3",                  125, "-127605887595351923798765477786913079296"},
		{"-3",                  126, "-255211775190703847597530955573826158592"},
		{"-3",                  0,   "-3"},
		{"9223372036854775807", 63,  "85070591730234615856620279821087277056"},
	}
	for c in shl_cases {
		reg_set(t, a, c.a)
		testing.expect_value(t, big.shl(q, a, c.bits), nil)
		reg_expect(t, q, c.result)
	}
	testing.expect_value(t, big.shl(q, a, -1), big.Error.Invalid_Argument)
	testing.expect_value(t, big.shr(q, a, -1), big.Error.Invalid_Argument)
	testing.expect_value(t, big.shrmod(q, r, a, -1), big.Error.Invalid_Argument)

	Shrmod_Case :: struct {
		a:    string,
		bits: int,
		q, r: string,
	}
	shrmod_cases := []Shrmod_Case{
		{"3",    1, "1", "1"},
		{"7",    3, "0", "7"},
		{"-5",   3, "0", "-5"},
		{"784637716923335095479473677900958302022017802594859089927", 63, "85070591730234615865843651857942052865", "7"},
		{"-1180591620717411303429", 3, "-147573952589676412928", "-5"},
	}
	for c in shrmod_cases {
		reg_set(t, a, c.a)
		testing.expect_value(t, big.shrmod(q, r, a, c.bits), nil)
		reg_expect(t, q, c.q)
		reg_expect(t, r, c.r)
	}

	big.set(a, -1)
	testing.expect_value(t, big.shr(q, a, 1), nil)
	reg_expect_i64(t, q, 0)
	reg_pow2(t, a, 63)
	testing.expect_value(t, big.shr(q, a, 1), nil)
	testing.expect_value(t, q.used, 1)
	reg_expect(t, q, "4611686018427387904")
}

@(test)
test_regression_set_get :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	reg_ones(t, a, 16)
	testing.expect_value(t, big.set(a, min(i128)), nil)
	reg_expect(t, a, "-170141183460469231731687303715884105728")
	i128_value, err := big.get_i128(a)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, i128_value, min(i128))

	reg_ones(t, a, 16)
	testing.expect_value(t, big.set(a, u128(0)), nil)
	reg_expect_i64(t, a, 0)

	testing.expect_value(t, big.set(a, max(u128)), nil)
	reg_expect(t, a, "340282366920938463463374607431768211455")
	u128_value: u128
	u128_value, err = big.get_u128(a)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, u128_value, max(u128))

	testing.expect_value(t, big.set(a, i64be(min(i64))), nil)
	be_value: i64be
	be_value, err = big.get(a, i64be)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, be_value, i64be(min(i64)))

	testing.expect_value(t, big.set(a, u32le(max(u32))), nil)
	le_value: u32le
	le_value, err = big.get(a, u32le)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, le_value, u32le(max(u32)))

	reg_pow2(t, a, 128)
	u128_value, err = big.get_u128(a)
	testing.expect_value(t, err, big.Error.Integer_Overflow)
	testing.expect_value(t, u128_value, max(u128))

	big.set(a, -1)
	_, err = big.get_u64(a)
	testing.expect_value(t, err, big.Error.Integer_Underflow)

	big.set(a, max(u32))
	u32_value: u32
	u32_value, err = big.get_u32(a)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, u32_value, max(u32))
	big.set(a, i64(4294967296))
	_, err = big.get_u32(a)
	testing.expect_value(t, err, big.Error.Integer_Overflow)

	reg_pow2(t, a, 127, -1)
	i128_value, err = big.get_i128(a)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, i128_value, max(i128))

	big.set(a, -2147483648)
	i32_value: i32
	i32_value, err = big.get_i32(a)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, i32_value, min(i32))

	zero_value := &big.Int{}
	i64_value: i64
	i64_value, err = big.get_i64(zero_value)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, i64_value, 0)
	testing.expect_value(t, big.int_is_initialized(zero_value), false)
}

@(test)
test_regression_count_bits :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	Case :: struct {
		power:     int,
		delta:     i64,
		negative:  bool,
		bits, lsb: int,
	}
	cases := []Case{
		{-1,  0, false, 0,   0},
		{0,   0, false, 1,   0},
		{0,   0, true,  1,   0},
		{63,  0, false, 64,  63},
		{63,  0, true,  64,  63},
		{126, 0, false, 127, 126},
		{128, 0, false, 129, 128},
		{70,  0, true,  71,  70},
	}
	for c in cases {
		if c.power < 0 {
			big.set(a, 0)
		} else {
			reg_pow2(t, a, c.power, c.delta)
		}
		if c.negative {
			testing.expect_value(t, big.neg(a, a), nil)
		}
		bits, err := big.count_bits(a)
		testing.expect_value(t, err, nil)
		testing.expectf(t, bits == c.bits, "count_bits(%v2^%v) = %v", "-" if c.negative else "", c.power, bits)
		lsb: int
		lsb, err = big.count_lsb(a)
		testing.expect_value(t, err, nil)
		testing.expectf(t, lsb == c.lsb, "count_lsb(%v2^%v) = %v", "-" if c.negative else "", c.power, lsb)
	}

	reg_pow2(t, a, 126)
	testing.expect_value(t, big.add(a, a, big.DIGIT(1 << 63)), nil)
	lsb, err := big.count_lsb(a)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, lsb, 63)

	testing.expect_value(t, big.platform_count_lsb(u64(0)), 0)
	testing.expect_value(t, big.platform_count_lsb(u64(1) << 40), 40)
	testing.expect_value(t, big.platform_count_lsb(u128(1) << 100), 100)
	testing.expect_value(t, big.platform_count_lsb(u8(128)), 7)
}

@(test)
test_regression_abs_neg_constants :: proc(t: ^testing.T) {
	a, x := &big.Int{}, &big.Int{}
	defer big.destroy(a, x)

	reg_pow2(t, a, 126)
	testing.expect_value(t, big.neg(a, a), nil)
	testing.expect_value(t, big.abs(x, a), nil)
	reg_expect(t, x, "85070591730234615865843651857942052864")
	big.set(a, -5)
	testing.expect_value(t, big.abs(a, a), nil)
	reg_expect_i64(t, a, 5)
	big.set(a, 0)
	testing.expect_value(t, big.abs(x, a), nil)
	reg_expect_i64(t, x, 0)
	testing.expect_value(t, big.neg(x, a), nil)
	reg_expect_i64(t, x, 0)
	big.set(a, -3)
	testing.expect_value(t, big.neg(a, a), nil)
	reg_expect_i64(t, a, 3)

	testing.expect_value(t, big.platform_abs(-5), 5)
	testing.expect_value(t, big.platform_abs(i64(-9223372036854775807)), 9223372036854775807)

	testing.expect_value(t, big.nan(a), nil)
	testing.expect_value(t, big.one(a), nil)
	reg_expect_i64(t, a, 1)
	testing.expect_value(t, a.flags, big.Flags{})
	testing.expect_value(t, big.minus_one(a), nil)
	reg_expect_i64(t, a, -1)
	testing.expect_value(t, big.inf(a), nil)
	testing.expect_value(t, a.sign, big.Sign.Zero_or_Positive)
	testing.expect_value(t, a.flags, big.Flags{.Inf})
	testing.expect_value(t, big.nan(a), nil)
	testing.expect_value(t, a.flags, big.Flags{.NaN})

	testing.expect_value(t, big.add(x, big.INT_ONE, big.INT_ONE), nil)
	reg_expect_i64(t, x, 2)
	testing.expect_value(t, big.mul(x, big.INT_MINUS_ONE, big.INT_MINUS_ONE), nil)
	reg_expect_i64(t, x, 1)
	testing.expect_value(t, big.sub(x, big.INT_ZERO, big.INT_ONE), nil)
	reg_expect_i64(t, x, -1)
	reg_expect_i64(t, big.INT_ONE, 1)
	reg_expect_i64(t, big.INT_MINUS_ONE, -1)
	testing.expect_value(t, big.INT_ONE.flags, big.Flags{.Immutable})
	testing.expect_value(t, big.INT_MINUS_ONE.flags, big.Flags{.Immutable})
}

@(test)
test_regression_grow_clear :: proc(t: ^testing.T) {
	a, b := &big.Int{}, &big.Int{}
	defer big.destroy(a, b)

	reg_ones(t, a, 5)
	testing.expect_value(t, big.shrink(a), nil)
	testing.expect_value(t, len(a.digit), 5)
	testing.expect_value(t, big.grow(a, 2, true), nil)
	testing.expect_value(t, len(a.digit), 5)
	testing.expect_value(t, big.grow(a, 100), nil)
	testing.expect_value(t, len(a.digit), 100)
	testing.expect_value(t, big.grow(a, -5), nil)
	testing.expect_value(t, len(a.digit), 100)

	testing.expect_value(t, big.clear(a, true), nil)
	testing.expect_value(t, len(a.digit), 3)
	reg_expect_i64(t, a, 0)

	testing.expect_value(t, big.clamp(b), nil)

	c, d := &big.Int{}, &big.Int{}
	defer big.destroy(c, d)
	testing.expect_value(t, big.init_multi(c, d), nil)
	testing.expect_value(t, big.int_is_initialized(c), true)
	testing.expect_value(t, big.int_is_initialized(d), true)
	reg_expect_i64(t, c, 0)
	reg_expect_i64(t, d, 0)
}

@(test)
test_regression_bytes :: proc(t: ^testing.T) {
	a, x := &big.Int{}, &big.Int{}
	defer big.destroy(a, x)

	size, err := big.int_to_bytes_size(a)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, size, 0)
	size, err = big.int_to_bytes_size(a, true)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, size, 1)

	reg_set(t, a, "0102030405060708090A0B0C0D0E0F1011", 16)
	size, err = big.int_to_bytes_size(a)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, size, 17)

	buf: [17]u8
	testing.expect_value(t, big.int_to_bytes_big(a, buf[:]), nil)
	for i in 0..<17 {
		testing.expectf(t, buf[i] == u8(i + 1), "big-endian byte %v = %v", i, buf[i])
	}
	testing.expect_value(t, big.int_from_bytes_big(x, buf[:]), nil)
	reg_expect(t, x, "102030405060708090A0B0C0D0E0F1011", 16)

	testing.expect_value(t, big.int_to_bytes_little(a, buf[:]), nil)
	for i in 0..<17 {
		testing.expectf(t, buf[i] == u8(17 - i), "little-endian byte %v = %v", i, buf[i])
	}
	testing.expect_value(t, big.int_from_bytes_little(x, buf[:]), nil)
	reg_expect(t, x, "102030405060708090A0B0C0D0E0F1011", 16)
}

@(test)
test_regression_bitfield_extract :: proc(t: ^testing.T) {
	a, r := &big.Int{}, &big.Int{}
	defer big.destroy(a, r)

	reg_set(t, a, "F0E1D2C3B4A5968778695A4B3C2D1E0F0123456789ABCDEFFEDCBA9876543210", 16)

	offsets := [?]int{0, 5, 58, 62, 63, 100, 125, 200, 250, 255, 300}
	counts  := [?]int{1, 7, 8, 63, 64, 126}
	for offset in offsets {
		for count in counts {
			got, err := big.int_bitfield_extract(a, offset, count)
			testing.expect_value(t, err, nil)

			testing.expect_value(t, big.shr(r, a, offset), nil)
			testing.expect_value(t, big.mod_bits(r, r, count), nil)
			expected: u128
			expected, err = big.get_u128(r)
			testing.expect_value(t, err, nil)
			testing.expectf(t, u128(got) == expected, "bitfield_extract(offset=%v, count=%v) = %x, expected %x", offset, count, got, expected)
		}
	}
	_, err := big.int_bitfield_extract(a, 0, 127)
	testing.expect_value(t, err, big.Error.Invalid_Argument)
	_, err = big.int_bitfield_extract(a, 0, 0)
	testing.expect_value(t, err, big.Error.Invalid_Argument)
}

@(test)
test_regression_atoi :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	Case :: struct {
		input:  string,
		radix:  i8,
		result: string,
		err:    big.Error,
		n:      int,
	}
	cases := []Case{
		{"+/",                                          64, "4031", nil,                     2},
		{"+/",                                          63, "62",   .Invalid_Character,      1},
		{"0000000000000000000000000000000000000000001F", 16, "31",   nil,                     44},
		{"-00000000000000000000000000000000000000000000000000000000000000000001", 2, "-1", nil,  69},
		{"12\x0034",                                    10, "12",   .Invalid_Character,      2},
		{"0x1F",                                        16, "0",    .Invalid_Character,      1},
		{"1é",                                          10, "1",    .Invalid_Character,      1},
		{"zz",                                          36, "1295", nil,                     2},
		{"ZZ",                                          36, "1295", nil,                     2},
		{"a",                                           37, "36",   nil,                     1},
		{"A",                                           37, "10",   nil,                     1},
	}
	for c in cases {
		n := -1
		err := big.int_atoi(a, c.input, c.radix, &n)
		testing.expectf(t, err == c.err, "atoi(%q, %v): err = %v, expected %v", c.input, c.radix, err, c.err)
		testing.expectf(t, n == c.n, "atoi(%q, %v): n = %v, expected %v", c.input, c.radix, n, c.n)
		reg_expect(t, a, c.result)
	}

	radixes := [?]i8{0, 1, -5, 127}
	for radix in radixes {
		n := -1
		err := big.int_atoi(a, "1", radix, &n)
		testing.expect_value(t, err, big.Error.Invalid_Argument)
		testing.expect_value(t, n, 0)
	}
}

@(test)
test_regression_itoa :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	Case :: struct {
		power:  int,
		delta:  i64,
		negate: bool,
		radix:  i8,
		result: string,
	}
	cases := []Case{
		{63,  -1, false, 64, "7//////////"},
		{63,  0,  true,  36, "-1Y2P0IJ32E8E8"},
		{126, -1, false, 3,  "12011212011000120022000012112210022201211110120101000022212110022021120100011000"},
		{126, 0,  true,  10, "-85070591730234615865843651857942052864"},
		{189, 1,  false, 62, "LP90nCTXd7UcqSB282VBSBMF76XnL2mH"},
		{127, 0,  true,  64, "-2000000000000000000000"},
	}
	for c in cases {
		reg_pow2(t, a, c.power, c.delta)
		if c.negate {
			testing.expect_value(t, big.neg(a, a), nil)
		}
		reg_expect(t, a, c.result, c.radix)
	}

	reg_set(t, a, "12345678901234567890")
	reg_expect(t, a, "1010101101010100101010011000110011101011000111110000101011010010", 2)

	reg_set(t, a, "123456789012345678901234567890")
	cs, err := big.int_itoa_cstring(a, 7, context.temp_allocator)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, string(cs), "21653251153414601406403630240331250")

	zero_value := &big.Int{}
	radixes := [?]i8{2, 10, 16, 64}
	for radix in radixes {
		s: string
		s, err = big.int_itoa_string(zero_value, radix, false, context.temp_allocator)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, s, "0")
	}
}

@(test)
test_regression_radix_size :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	size, err := big.radix_size(a, 10)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, size, 1)
	size, err = big.radix_size(a, 10, true)
	testing.expect_value(t, size, 2)

	reg_pow2(t, a, 64)
	testing.expect_value(t, big.neg(a, a), nil)
	size, err = big.radix_size(a, 16)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, size, 18)

	values := [?]string{"9999999999999999999999999999999999999999", "-9999999999999999999999999999999999999999", "-170141183460469231731687303715884105728"}
	radixes := [?]i8{2, 3, 10, 16, 36, 64}
	for v in values {
		reg_set(t, a, v)
		for radix in radixes {
			s: string
			s, err = big.int_itoa_string(a, radix, false, context.temp_allocator)
			testing.expect_value(t, err, nil)
			size, err = big.radix_size(a, radix)
			testing.expect_value(t, err, nil)
			testing.expectf(t, size >= len(s) && size <= len(s) + 1, "radix_size(%v, %v) = %v for %q", v, radix, size, s)
			terminated: int
			terminated, err = big.radix_size(a, radix, true)
			testing.expect_value(t, terminated, size + 1)
		}
	}

	size, err = big.radix_size(a, 1)
	testing.expect_value(t, err, big.Error.Invalid_Argument)
	testing.expect_value(t, size, -1)
	size, err = big.radix_size(a, 65)
	testing.expect_value(t, err, big.Error.Invalid_Argument)
	testing.expect_value(t, size, -1)
}

@(test)
test_regression_radix_file :: proc(t: ^testing.T) {
	root, root_err := os.make_directory_temp("", "odin-math-big-*", context.temp_allocator)
	if !testing.expect_value(t, root_err, nil) {
		return
	}
	defer os.remove_all(root)

	a, b := &big.Int{}, &big.Int{}
	defer big.destroy(a, b)

	path, _ := os.join_path({root, "value.txt"}, context.temp_allocator)

	values := [?]string{"0", "-1", "123456789012345678901234567890123456789", "-12345678901234567890123456789"}
	radixes := [?]i8{2, 10, 16, 64}
	for v in values {
		reg_set(t, a, v)
		for radix in radixes {
			testing.expect_value(t, big.internal_int_write_to_ascii_file(a, path, radix), nil)
			testing.expect_value(t, big.internal_int_read_from_ascii_file(b, path, radix), nil)
			reg_expect(t, b, v)
		}
	}

	testing.expect_value(t, os.write_entire_file(path, "12345\r\n"), nil)
	testing.expect_value(t, big.internal_int_read_from_ascii_file(b, path), nil)
	reg_expect_i64(t, b, 12345)

	testing.expect_value(t, os.write_entire_file(path, ""), nil)
	testing.expect_value(t, big.internal_int_read_from_ascii_file(b, path), big.Error.Empty_Input)

	testing.expect_value(t, os.write_entire_file(path, "12x"), nil)
	testing.expect_value(t, big.internal_int_read_from_ascii_file(b, path), big.Error.Invalid_Character)

	missing, _ := os.join_path({root, "missing.txt"}, context.temp_allocator)
	testing.expect_value(t, big.internal_int_read_from_ascii_file(b, missing), big.Error.Cannot_Read_File)

	missing_dir, _ := os.join_path({root, "missing", "value.txt"}, context.temp_allocator)
	testing.expect_value(t, big.internal_int_write_to_ascii_file(a, missing_dir), big.Error.Cannot_Write_File)

	testing.expect_value(t, big.internal_int_write_to_ascii_file(a, path, 1), big.Error.Invalid_Argument)
	testing.expect_value(t, big.internal_int_write_to_ascii_file(a, path, 65), big.Error.Invalid_Argument)
}

@(test)
test_regression_pack :: proc(t: ^testing.T) {
	a, b := &big.Int{}, &big.Int{}
	defer big.destroy(a, b)

	reg_pow2(t, a, 64)
	testing.expect_value(t, big.internal_int_pack_count(a, u8), 9)
	bytes: [9]u8
	written, err := big.internal_int_pack(a, bytes[:], 0, .LSB_First)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, written, 9)
	testing.expect_value(t, bytes, [9]u8{0, 0, 0, 0, 0, 0, 0, 0, 1})

	reg_set(t, a, "123456789ABCDEF0123456789ABCDEF0123456789ABCDEF", 16)
	testing.expect_value(t, big.internal_int_pack_count(a, u32), 6)
	words: [6]u32
	written, err = big.internal_int_pack(a, words[:], 0, .MSB_First)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, written, 6)
	testing.expect_value(t, words, [6]u32{0x1234567, 0x89abcdef, 0x1234567, 0x89abcdef, 0x1234567, 0x89abcdef})

	big.set(a, 0)
	testing.expect_value(t, big.internal_int_pack_count(a, u64), 0)

	reg_set(t, a, "F0E1D2C3B4A5968778695A4B3C2D1E0F0123456789ABCDEFFEDCBA98765432100F1E2D3C4B5A6978", 16)
	nails := [?]int{0, 1}
	orders := [?]big.Order{.LSB_First, .MSB_First}
	for nail in nails {
		for order in orders {
			buf: [8]u64
			count := big.internal_int_pack_count(a, u64, nail)
			testing.expect(t, count <= len(buf))
			written, err = big.internal_int_pack(a, buf[:count], nail, order)
			testing.expect_value(t, err, nil)
			testing.expect_value(t, written, count)
			testing.expect_value(t, big.internal_int_unpack(b, buf[:count], nail, order), nil)
			reg_expect(t, b, "F0E1D2C3B4A5968778695A4B3C2D1E0F0123456789ABCDEFFEDCBA98765432100F1E2D3C4B5A6978", 16)
		}
	}
}

@(test)
test_regression_is_prime :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	Case :: struct {
		value: string,
		prime: bool,
	}
	cases := []Case{
		{"0", false}, {"1", false}, {"4", false}, {"9", false}, {"15", false}, {"25", false}, {"1617", false}, {"2627641", false},
		{"2", true}, {"3", true}, {"5", true}, {"1613", true}, {"1619", true}, {"1621", true}, {"2600011", true},

		{"561", false}, {"1105", false}, {"1729", false}, {"2465", false}, {"2821", false}, {"6601", false}, {"8911", false},
		{"10585", false}, {"15841", false}, {"29341", false}, {"41041", false}, {"46657", false}, {"52633", false}, {"62745", false},
		{"63973", false}, {"75361", false}, {"101101", false}, {"115921", false}, {"126217", false}, {"162401", false}, {"172081", false},
		{"188461", false}, {"252601", false}, {"278545", false}, {"294409", false}, {"314821", false}, {"334153", false}, {"340561", false},
		{"399001", false}, {"410041", false}, {"449065", false}, {"488881", false}, {"512461", false}, {"9585921133193329", false},

		{"2047", false}, {"3277", false}, {"4033", false}, {"4681", false}, {"8321", false}, {"1373653", false}, {"25326001", false},
		{"3215031751", false}, {"2152302898747", false}, {"3474749660383", false}, {"341550071728321", false},
		{"3825123056546413051", false}, {"318665857834031151167461", false},

		{"5459", false}, {"5777", false}, {"10877", false}, {"16109", false}, {"18971", false}, {"22499", false}, {"24569", false},
		{"25199", false}, {"40309", false}, {"58519", false}, {"75077", false}, {"97439", false}, {"100127", false}, {"113573", false},
		{"115639", false},

		{"2147483647", true}, {"4294967291", true}, {"2305843009213693951", true}, {"4611686018427387847", true},
		{"9223372036854775783", true}, {"18446744073709551557", true},

		{"5316911983139663487003542222693990401", false}, {"4259406061", false}, {"36472996377170786403", false},
		{"318665857834031151167459", false}, {"3317044064679887385961979", false},
	}
	for c in cases {
		reg_set(t, a, c.value)
		prime, err := big.internal_int_is_prime(a, -1)
		testing.expect_value(t, err, nil)
		testing.expectf(t, prime == c.prime, "is_prime(%v) = %v", c.value, prime)
	}

	mersenne_composites := [?]int{11, 23, 29, 37, 41, 43, 47, 53, 59, 67, 71, 73, 79}
	for p in mersenne_composites {
		reg_pow2(t, a, p, -1)
		prime, err := big.internal_int_is_prime(a, -1)
		testing.expect_value(t, err, nil)
		testing.expectf(t, !prime, "is_prime(2^%v - 1) = %v", p, prime)
	}

	Pow2_Case :: struct {
		power: int,
		delta: i64,
		prime: bool,
	}
	pow2_cases := []Pow2_Case{
		{127, -1,   true},
		{521, -1,   true},
		{607, -1,   true},
		{128, -159, true},
		{126, -137, true},
		{257, -1,   false},
		{131, -1,   false},
		{113, -1,   false},
	}
	for c in pow2_cases {
		reg_pow2(t, a, c.power, c.delta)
		prime, err := big.internal_int_is_prime(a, 0)
		testing.expect_value(t, err, nil)
		testing.expectf(t, prime == c.prime, "is_prime(2^%v%+v, 0) = %v", c.power, c.delta, prime)
	}
}

@(test)
test_regression_frobenius_underwood :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	Case :: struct {
		value: string,
		prime: bool,
	}
	cases := []Case{
		{"1000003",                                 true},
		{"2305843009213693951",                     true},
		{"170141183460469231731687303715884105727", true},
		{"2047",                                    false},
		{"3215031751",                              false},
		{"3825123056546413051",                     false},
		{"318665857834031151167461",                false},
	}
	for c in cases {
		reg_set(t, a, c.value)
		prime, err := big.internal_int_prime_frobenius_underwood(a)
		testing.expect_value(t, err, nil)
		testing.expectf(t, prime == c.prime, "frobenius_underwood(%v) = %v", c.value, prime)
	}
}

@(test)
test_regression_kronecker :: proc(t: ^testing.T) {
	a, p := &big.Int{}, &big.Int{}
	defer big.destroy(a, p)

	Case :: struct {
		a, p:      string,
		kronecker: int,
	}
	cases := []Case{
		{"-1",  "0",  1},
		{"1",   "0",  1},
		{"2",   "0",  0},
		{"0",   "0",  0},
		{"0",   "1",  1},
		{"0",   "2",  0},
		{"0",   "-1", 1},
		{"3",   "-5", -1},
		{"-3",  "-5", 1},
		{"2",   "-6", 0},
		{"5",   "-6", 1},
		{"-5",  "-6", 1},
		{"-20", "-9", -1},
		{"9223372036854775808",   "9223372036854775807",                     1},
		{"-18446744073709551617", "170141183460469231731687303715884105727", -1},
	}
	for c in cases {
		reg_set(t, a, c.a)
		reg_set(t, p, c.p)
		k, err := big.internal_int_kronecker(a, p)
		testing.expect_value(t, err, nil)
		testing.expectf(t, k == c.kronecker, "kronecker(%v | %v) = %v, expected %v", c.a, c.p, k, c.kronecker)
	}
}

@(test)
test_regression_extended_euclidean :: proc(t: ^testing.T) {
	a, b, u1, u2, u3 := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(a, b, u1, u2, u3)

	Case :: struct {
		a, b, u1, u2, u3: string,
	}
	cases := []Case{
		{"-12", "18", "1",  "1",  "6"},
		{"240", "46", "-9", "47", "2"},
		{"0",   "0",  "1",  "0",  "0"},
		{"0",   "-5", "0",  "-1", "5"},
		{"170141183460469231731687303715884105727", "18446744073709551616", "-1", "9223372036854775808", "1"},
	}
	for c in cases {
		reg_set(t, a, c.a)
		reg_set(t, b, c.b)
		testing.expect_value(t, big.internal_int_extended_euclidean(a, b, u1, u2, u3), nil)
		reg_expect(t, u1, c.u1)
		reg_expect(t, u2, c.u2)
		reg_expect(t, u3, c.u3)
	}
}

@(test)
test_regression_prime_helpers :: proc(t: ^testing.T) {
	a, b, r, p, x := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(a, b, r, p, x)

	Divisible_Case :: struct {
		value:     string,
		divisible: bool,
	}
	divisible_cases := []Divisible_Case{
		{"0",                                       true},
		{"1",                                       false},
		{"2",                                       true},
		{"1619",                                    true},
		{"1621",                                    false},
		{"2637367",                                 false},
		{"3242",                                    true},
		{"-3",                                      true},
		{"-1621",                                   false},
		{"170141183460469231731687303715884105727", false},
		{"29865278655335764066304",                 true},
		{"29865278655335764066305",                 true},
	}
	for c in divisible_cases {
		reg_set(t, a, c.value)
		divisible, err := big.internal_int_prime_is_divisible(a)
		testing.expect_value(t, err, nil)
		testing.expectf(t, divisible == c.divisible, "is_divisible(%v) = %v", c.value, divisible)
	}

	Next_Case :: struct {
		value: i64,
		bbs:   bool,
		next:  i64,
	}
	next_cases := []Next_Case{
		{0,    false, 2},
		{2,    false, 3},
		{1617, false, 1619},
		{-30,  false, 31},
		{0,    true,  3},
		{3,    true,  7},
		{1609, true,  1619},
	}
	for c in next_cases {
		big.set(a, c.value)
		testing.expect_value(t, big.internal_int_prime_next_prime(a, -1, c.bbs), nil)
		reg_expect_i64(t, a, c.next)
	}

	Fermat_Case :: struct {
		a, b:   i64,
		fermat: bool,
		err:    big.Error,
	}
	fermat_cases := []Fermat_Case{
		{561, 2, true,  nil},
		{341, 2, true,  nil},
		{341, 3, false, nil},
		{7,   1, false, .Invalid_Argument},
	}
	for c in fermat_cases {
		big.set(a, c.a)
		big.set(b, c.b)
		fermat, err := big.internal_prime_fermat(a, b)
		testing.expect_value(t, err, c.err)
		testing.expect_value(t, fermat, c.fermat)
	}

	big.set(a, 2)
	big.set(p, 7)
	testing.expect_value(t, big.internal_int_sqrtmod_prime(r, a, p), nil)
	root, _ := big.get_i64(r)
	testing.expectf(t, root == 3 || root == 4, "sqrtmod(2, 7) = %v", root)

	Sqrt_Case :: struct {
		power: int,
		n:     i64,
		add_p: bool,
	}
	sqrt_cases := []Sqrt_Case{
		{61,  -3, false},
		{127, 4,  true},
	}
	for c in sqrt_cases {
		reg_pow2(t, p, c.power, -1)
		big.set(a, c.n)
		if c.add_p {
			testing.expect_value(t, big.add(a, a, p), nil)
		}
		testing.expect_value(t, big.internal_int_sqrtmod_prime(r, a, p), nil)
		testing.expect_value(t, big.mulmod(x, r, r, p), nil)
		testing.expect_value(t, big.mod(b, a, p), nil)
		cmp, _ := big.cmp(x, b)
		testing.expectf(t, cmp == 0, "sqrtmod(%v, 2^%v - 1): root squared differs", c.n, c.power)
		negative, _ := big.is_negative(r)
		testing.expect(t, !negative)
		cmp, _ = big.cmp(r, p)
		testing.expect_value(t, cmp, -1)
	}

	big.set(a, 5)
	big.set(p, 7)
	testing.expect_value(t, big.internal_int_sqrtmod_prime(r, a, p), big.Error.Invalid_Argument)
	big.set(a, 1)
	bad_primes := [?]i64{4, 2, 1}
	for bad in bad_primes {
		big.set(p, bad)
		testing.expect_value(t, big.internal_int_sqrtmod_prime(r, a, p), big.Error.Invalid_Argument)
	}
	big.set(a, 0)
	big.set(p, 7)
	testing.expect_value(t, big.internal_int_sqrtmod_prime(r, a, p), nil)
	reg_expect_i64(t, r, 0)
}

@(test)
test_regression_rabin_miller_trials :: proc(t: ^testing.T) {
	Case :: struct {
		bits, trials: int,
	}
	cases := []Case{
		{1, -1}, {80, -1}, {81, 37}, {95, 37}, {96, 32}, {127, 32}, {128, 40}, {160, 35}, {256, 27}, {384, 16},
		{512, 18}, {767, 18}, {768, 11}, {896, 10}, {1023, 10}, {1024, 12}, {1536, 8}, {2048, 6}, {3072, 4},
		{4096, 5}, {5120, 4}, {6144, 4}, {8192, 3}, {9216, 3}, {10239, 3}, {10240, 2}, {100000, 2},
	}
	for c in cases {
		trials := big.number_of_rabin_miller_trials(c.bits)
		testing.expectf(t, trials == c.trials, "number_of_rabin_miller_trials(%v) = %v, expected %v", c.bits, trials, c.trials)
	}
}

@(test)
test_regression_prime_table :: proc(t: ^testing.T) {
	table := big._private_prime_table
	testing.expect_value(t, len(table), 256)
	testing.expect_value(t, table[0], 2)
	testing.expect_value(t, table[12], 41)
	testing.expect_value(t, table[255], 1619)

	for i in 1..<len(table) {
		for candidate := table[i - 1] + 1; candidate <= table[i]; candidate += 1 {
			composite := false
			for d := big.DIGIT(2); d * d <= candidate; d += 1 {
				if candidate % d == 0 {
					composite = true
					break
				}
			}
			testing.expectf(t, composite == (candidate != table[i]), "prime table entry %v = %v, %v is %v", i, table[i], candidate, "composite" if composite else "prime")
		}
	}
}

@(test)
test_regression_montgomery :: proc(t: ^testing.T) {
	n, x, r := &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(n, x, r)

	reg_set(t, n, "8FC686F9FD800FF", 16)
	rho, err := big._private_int_montgomery_setup(n)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, rho, 0x30854E7850D90101)
	big.set(n, 16)
	_, err = big._private_int_montgomery_setup(n)
	testing.expect_value(t, err, big.Error.Invalid_Argument)

	reg_set(t, n, "10000000000000001", 16)
	testing.expect_value(t, big._private_int_montgomery_calc_normalization(r, n), nil)
	reg_expect(t, r, "C000000000000001", 16)
	rho, err = big._private_int_montgomery_setup(n)
	testing.expect_value(t, err, nil)
	reg_set(t, x, "40000000000000003FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", 16)
	testing.expect_value(t, big._private_montgomery_reduce_comba(x, n, rho), nil)
	reg_expect(t, x, "FFFFFFFFFFFFFFFD", 16)

	reg_set(t, n, "95506A7A4B402C9E740B6578A96AB462BFD9A7F2C5882369CFCDD00F7A3D667", 16)
	testing.expect_value(t, big._private_int_montgomery_calc_normalization(r, n), nil)
	reg_expect(t, r, "6AAF9585B4BFD3618BF49A8756954B9D4026580D3A77DC9630322FF085C2999", 16)
	rho, err = big._private_int_montgomery_setup(n)
	testing.expect_value(t, err, nil)
	reg_set(t, x, "95506A7A4B402C9E740B6578A96AB462BFD9A7F2C5882369CFCDD00F7A3D666FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", 16)
	testing.expect_value(t, big._private_int_montgomery_reduce(x, n, rho), nil)
	reg_expect(t, x, "20D2F8791AC260C9F7DF9A39003AB4E265B1B4F825A50332456C2BC1721FC27", 16)
}

@(test)
test_regression_reduce :: proc(t: ^testing.T) {
	m, mu, x := &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(m, mu, x)

	reg_set(t, m, "B01B03F9BC6ACEC627A855ADB434B24", 16)
	testing.expect_value(t, big._private_int_reduce_setup(mu, m), nil)
	reg_set(t, x, "38D27C8C27EF5F59FB03CD36D093AAFE36866C63455A133F587EEACE04CDAF", 16)
	testing.expect_value(t, big._private_int_reduce(x, m, mu), nil)
	reg_expect(t, x, "16C5ACF070B1B4A414C13C50F7DCCA3", 16)

	reg_set(t, m, "1FFFFFFFFFFFFFFFFFFFFFFD", 16)
	d, err := big._private_int_reduce_2k_setup(m)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, d, 3)
	reg_set(t, x, "1FEDCBA9876543210FEDCBA9876543210FEDCBA98765", 16)
	testing.expect_value(t, big._private_int_reduce_2k(x, m, d), nil)
	reg_expect(t, x, "BAC85B05B05C16C16C305AF", 16)

	reg_set(t, m, "1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFCFC7", 16)
	testing.expect_value(t, big._private_int_reduce_2k_setup_l(mu, m), nil)
	reg_expect(t, mu, "3039", 16)
	reg_set(t, x, "3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF3F180000000000000000000000000000000000000000915CA1B", 16)
	testing.expect_value(t, big._private_int_reduce_2k_l(x, m, mu), nil)
	reg_expect(t, x, "1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFCCBF", 16)

	Case :: struct {
		value:          string,
		is_2k, is_2k_l: bool,
	}
	cases := []Case{
		{"1FFFFFFFFFFFFFFFFFFFFFFD",         true,  false},
		{"10000000000000001",                false, false},
		{"3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", true,  true},
		{"0",                                false, false},
	}
	for c in cases {
		reg_set(t, m, c.value, 16)
		is_2k, is_2k_err := big._private_int_reduce_is_2k(m)
		testing.expect_value(t, is_2k_err, nil)
		testing.expectf(t, is_2k == c.is_2k, "is_2k(%v) = %v", c.value, is_2k)
		is_2k_l, is_2k_l_err := big._private_int_reduce_is_2k_l(m)
		testing.expect_value(t, is_2k_l_err, nil)
		testing.expectf(t, is_2k_l == c.is_2k_l, "is_2k_l(%v) = %v", c.value, is_2k_l)
	}
}

@(test)
test_regression_invmod_powmod :: proc(t: ^testing.T) {
	a, b, m, x := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(a, b, m, x)

	Case :: struct {
		a, b, result: i64,
		err:          big.Error,
	}
	cases := []Case{
		{-3, 8,  5, nil},
		{3,  8,  3, nil},
		{5,  1,  0, nil},
		{2,  4,  0, .Invalid_Argument},
		{0,  7,  0, .Invalid_Argument},
		{3,  0,  0, .Invalid_Argument},
		{3,  -7, 0, .Invalid_Argument},
	}
	for c in cases {
		big.set(a, c.a)
		big.set(b, c.b)
		err := big.internal_invmod(x, a, b)
		testing.expectf(t, err == c.err, "invmod(%v, %v): err = %v", c.a, c.b, err)
		if c.err == nil {
			reg_expect_i64(t, x, c.result)
		}
	}

	big.set(a, 3)
	reg_pow2(t, m, 200)
	testing.expect_value(t, big.internal_invmod(x, a, m), nil)
	reg_expect(t, x, "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB", 16)

	reg_set(t, m, "B01B03F9BC6ACEC627A855ADB434B24", 16)
	big.set(a, 3)
	big.set(b, -1)
	testing.expect_value(t, big.internal_powmod(x, a, b, m), nil)
	reg_expect(t, x, "756757FBD2F1DF2EC51AE3C922CDCC3", 16)

	reg_set(t, a, "1234567890ABCDEF1234567", 16)
	big.set(b, -0x10001)
	testing.expect_value(t, big.internal_powmod(x, a, b, m), nil)
	reg_expect(t, x, "6C24899B925A2548C02B079D0F7851F", 16)
}

@(test)
test_regression_int_out_of_memory_does_not_leak :: proc(t: ^testing.T) {
	Op :: enum {
		Mul,
		Sqr,
		Divmod,
		Sqrt,
		Root_N,
		Pow,
		Gcd_Lcm,
		Log,
		Factorial,
		Choose,
		Invmod,
		Powmod,
		Is_Prime,
		Itoa,
		Atoi,
	}
	outer := context.allocator
	for op in Op {
		for fail_at in 1..=200 {
			track: mem.Tracking_Allocator
			mem.tracking_allocator_init(&track, outer)
			st := Reg_Fail_State{backing = mem.tracking_allocator(&track), fail_at = fail_at}
			context.allocator = mem.Allocator{procedure = reg_fail_proc, data = &st}

			a, b, c, d := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
			reg_ones(t, a, 40)
			reg_ones(t, b, 23)
			testing.expect_value(t, big.sub(b, b, big.DIGIT(2)), nil)
			s := ""

			st.active = true
			err: big.Error
			switch op {
			case .Mul:       err = big.mul(c, a, b)
			case .Sqr:       err = big.sqr(c, a)
			case .Divmod:    err = big.divmod(c, d, a, b)
			case .Sqrt:      err = big.sqrt(c, a)
			case .Root_N:    err = big.root_n(c, a, 5)
			case .Pow:       err = big.pow(c, b, 7)
			case .Gcd_Lcm:   err = big.gcd_lcm(c, d, a, b)
			case .Log:       _, err = big.log(a, 7)
			case .Factorial: err = big.factorial(c, 300)
			case .Choose:    err = big.choose(c, 300, 150)
			case .Invmod:    err = big.internal_invmod(c, b, a)
			case .Powmod:    err = big.internal_powmod(c, b, a, a)
			case .Is_Prime:  _, err = big.internal_int_is_prime(b, 2)
			case .Itoa:      s, err = big.int_itoa_string(a, 10)
			case .Atoi:      err = big.atoi(c, "123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890")
			}
			st.active = false
			reached := st.count >= fail_at

			delete(s)
			big.destroy(a, b, c, d)
			testing.expectf(t, len(track.allocation_map) == 0, "%v, allocation %v failed: %v leaked", op, fail_at, len(track.allocation_map))
			if reached {
				testing.expectf(t, err == .Out_Of_Memory, "%v, allocation %v failed: err = %v", op, fail_at, err)
			}
			mem.tracking_allocator_destroy(&track)
			if !reached {
				break
			}
		}
	}
}

@(private="file")
REG_X_N :: "1556BC09CB91215785D99773382DD301C8A91AFA5C7623C4DD"
@(private="file")
REG_X_D :: "8FFA5FC6A29D1C6231C6A83B6087BE1D408D4D4BF75093B433"
@(private="file")
REG_Y_N :: "748F79FFB25306DDF2B2AEADD8B86A08"
@(private="file")
REG_Y_D :: "65545AFEFEC7612E319A2FBAF253374D802EF90D40B086AD6A0D"

@(test)
test_regression_rat_multi_digit_gcd :: proc(t: ^testing.T) {
	x, y, z: big.Rat
	defer big.destroy(&x, &y, &z)

	reg_rat_set(t, &x, REG_X_N, REG_X_D, 16)
	reg_rat_set(t, &y, REG_Y_N, REG_Y_D, 16)
	reg_rat_expect(t, &x, REG_X_N, REG_X_D, 16)
	reg_rat_expect(t, &y, REG_Y_N, REG_Y_D, 16)

	testing.expect_value(t, big.rat_add_rat(&z, &x, &y), nil)
	reg_rat_expect(t, &z, "13FFF661A222BC0AFA29BDED29C85533BF3C1", "86F19BE3C5BD17EE73DF66C32BCB958E63B27", 16)

	testing.expect_value(t, big.rat_sub_rat(&z, &x, &y), nil)
	reg_rat_expect(t, &z, "33FD07D25A52A70CBDF4B56EB1A0FCE67E4B850DD0F9EB4CDFD2F1FA0CD05E31BC579", "15EC734F24CAC3C4AE79A8E1470ED97C42268E2A1228456186878BE061E95928F85FFF", 16)

	testing.expect_value(t, big.rat_div_rat(&y, &x, &y), nil)
	reg_rat_expect(t, &y, "33FD07D25A52A70CBDF648EFB5DE5EE988309684ECB30275C2D9BA30B1E68F1098D51", "19381043D620309E511771BB91728E306C836A51630DEDC7D8", 16)
}

@(test)
test_regression_rat_one_word_boundary :: proc(t: ^testing.T) {
	x, y, z: big.Rat
	defer big.destroy(&x, &y, &z)

	Op :: enum {
		Add,
		Sub,
		Mul,
	}
	Case :: struct {
		op:                         Op,
		x_num, x_den, y_num, y_den: string,
		num, den:                   string,
	}
	cases := []Case{
		{.Add, "9223372036854775807", "3",                   "9223372036854775807", "6",                   "9223372036854775807", "2"},
		{.Sub, "1",                   "9223372036854775807", "1",                   "9223372036854775806", "-1", "85070591730234615838173535747377725442"},
		{.Add, "9223372036854775807", "9223372036854775806", "9223372036854775807", "9223372036854775805", "170141183460469231667123699457900675077", "85070591730234615819726791673668173830"},
		{.Add, "9223372036854775807", "9223372036854775808", "1",                   "9223372036854775808", "1", "1"},
		{.Mul, "9223372036854775807", "9223372036854775806", "9223372036854775806", "9223372036854775807", "1", "1"},
	}
	for c in cases {
		reg_rat_set(t, &x, c.x_num, c.x_den)
		reg_rat_set(t, &y, c.y_num, c.y_den)
		err: big.Error
		switch c.op {
		case .Add: err = big.rat_add_rat(&z, &x, &y)
		case .Sub: err = big.rat_sub_rat(&z, &x, &y)
		case .Mul: err = big.rat_mul_rat(&z, &x, &y)
		}
		testing.expect_value(t, err, nil)
		reg_rat_expect(t, &z, c.num, c.den)
	}
}

@(test)
test_regression_rat_int_operand_aliasing :: proc(t: ^testing.T) {
	x: big.Rat
	defer big.destroy(&x)

	testing.expect_value(t, big.rat_set_frac_digit(&x, 2, 3), nil)
	testing.expect_value(t, big.rat_add_int(&x, &x, &x.b), nil)
	reg_rat_expect(t, &x, "11", "3")

	testing.expect_value(t, big.rat_set_frac_digit(&x, 2, 3), nil)
	testing.expect_value(t, big.rat_div_int(&x, &x, &x.a), nil)
	reg_rat_expect(t, &x, "1", "3")

	testing.expect_value(t, big.rat_set_frac_digit(&x, 2, 3), nil)
	testing.expect_value(t, big.int_div_rat(&x, &x.a, &x), nil)
	reg_rat_expect(t, &x, "3", "1")

	testing.expect_value(t, big.rat_set_frac_digit(&x, 2, 3), nil)
	testing.expect_value(t, big.int_div_rat(&x, &x.b, &x), nil)
	reg_rat_expect(t, &x, "9", "2")

	testing.expect_value(t, big.rat_set_frac_digit(&x, 2, 3), nil)
	testing.expect_value(t, big.int_sub_rat(&x, &x.b, &x), nil)
	reg_rat_expect(t, &x, "7", "3")

	testing.expect_value(t, big.rat_set_frac_digit(&x, 1, 2), nil)
	testing.expect_value(t, big.rat_add_int(&x, &x, &x.a), nil)
	reg_rat_expect(t, &x, "3", "2")

	reg_rat_set(t, &x, REG_X_N, REG_X_D, 16)
	testing.expect_value(t, big.int_div_rat(&x, &x.b, &x), nil)
	reg_rat_expect(t, &x, "50F9ABDF1D762761B0C92921748E982529E75FBDC5103E5688ED0390F6CB4C1631E7FCB84C7C3E75ACFDB6A642425169C229", REG_X_N, 16)

	reg_rat_set(t, &x, REG_X_N, REG_X_D, 16)
	testing.expect_value(t, big.int_div_rat(&x, &x.a, &x), nil)
	reg_rat_expect(t, &x, REG_X_D, "1", 16)

	reg_rat_set(t, &x, REG_X_N, REG_X_D, 16)
	testing.expect_value(t, big.rat_mul_int(&x, &x, &x.b), nil)
	reg_rat_expect(t, &x, REG_X_N, "1", 16)

	reg_rat_set(t, &x, REG_X_N, REG_X_D, 16)
	testing.expect_value(t, big.int_sub_rat(&x, &x.a, &x), nil)
	reg_rat_expect(t, &x, "C0051B8D8B1EB05F19B6CAC58F44D96B08F69AFA67399F9679A330B36F91A3BB17E5D9FDACE940F1B150DF99D6A544ED72A", REG_X_D, 16)
}

@(test)
test_regression_rat_set_float :: proc(t: ^testing.T) {
	r: big.Rat
	defer big.destroy(&r)

	testing.expect_value(t, big.rat_set_f32(&r, 0.1), nil)
	reg_rat_expect(t, &r, "13421773", "134217728")
	testing.expect_value(t, big.rat_set_f16(&r, 0.1), nil)
	reg_rat_expect(t, &r, "819", "8192")

	g := &big.Int{}
	defer big.destroy(g)
	for bits in 0..<0x10000 {
		f := transmute(f16)u16(bits)
		if bits & 0x7c00 == 0x7c00 {
			continue
		}
		testing.expect_value(t, big.rat_set_f16(&r, f), nil)
		testing.expect_value(t, big.gcd(g, &r.a, &r.b), nil)
		one, _ := big.eq(g, big.DIGIT(1))
		positive, _ := big.is_positive(&r.b)
		back, exact, err := big.rat_to_f16(&r)
		testing.expect_value(t, err, nil)
		if !testing.expectf(t, one && positive && exact && back == f, "f16 bits %4x: reduced=%v exact=%v back=%v", bits, one && positive, exact, back) {
			return
		}
	}
}

@(test)
test_regression_rat_to_float :: proc(t: ^testing.T) {
	r: big.Rat
	defer big.destroy(&r)

	F16_Case :: struct {
		num, den: string,
		bits:     u16,
		exact:    bool,
	}
	f16_cases := []F16_Case{
		{"65519", "1",        0x7bff, false},
		{"65520", "1",        0x7c00, false},
		{"1",     "10",       0x2e66, false},
		{"3",     "67108864", 0x0001, false},
		{"3",     "33554432", 0x0002, false},
		{"2047",  "1024",     0x3fff, true},
		{"1",     "3",        0x3555, false},
		{"2047",  "3",        0x6155, false},
		{"-2",    "2047",     0x9401, false},
		{"1",     "2047",     0x1001, false},
	}
	for c in f16_cases {
		reg_rat_set(t, &r, c.num, c.den)
		f, exact, err := big.rat_to_f16(&r)
		testing.expect_value(t, err, nil)
		testing.expectf(t, transmute(u16)f == c.bits && exact == c.exact, "%v/%v: f16 bits %4x exact %v", c.num, c.den, transmute(u16)f, exact)
	}

	F32_Case :: struct {
		num, den: string,
		bits:     u32,
		exact:    bool,
	}
	f32_cases := []F32_Case{
		{"16777217", "1",                                              0x4b800000, false},
		{"16777219", "1",                                              0x4b800002, false},
		{"-2",       "3",                                              0xbf2aaaab, false},
		{"1",        "713623846352979940529142984724747568191373312",  0x00000001, true},
		{"3",        "2854495385411919762116571938898990272765493248", 0x00000001, false},
		{"1",        "16777215",                                       0x33800001, false},
	}
	for c in f32_cases {
		reg_rat_set(t, &r, c.num, c.den)
		f, exact, err := big.rat_to_f32(&r)
		testing.expect_value(t, err, nil)
		testing.expectf(t, transmute(u32)f == c.bits && exact == c.exact, "%v/%v: f32 bits %8x exact %v", c.num, c.den, transmute(u32)f, exact)
	}

	F64_Case :: struct {
		num, den: string,
		bits:     u64,
		exact:    bool,
	}
	f64_cases := []F64_Case{
		{"9007199254740993",  "1",                 0x4340000000000000, false},
		{"9007199254740995",  "1",                 0x4340000000000002, false},
		{"1",                 "3",                 0x3fd5555555555555, false},
		{"18014398509481983", "18014398509481984", 0x3ff0000000000000, false},
		{"9007199254740991",  "4503599627370496",  0x3fffffffffffffff, true},
		{"9007199254740991",  "3",                 0x4325555555555555, false},
		{"9007199254740991",  "9007199254740990",  0x3ff0000000000001, false},
		{"7405100827744127",  "4544324125120101",  0x3ffa128b5ba025f3, false},
	}
	for c in f64_cases {
		reg_rat_set(t, &r, c.num, c.den)
		f, exact, err := big.rat_to_f64(&r)
		testing.expect_value(t, err, nil)
		testing.expectf(t, transmute(u64)f == c.bits && exact == c.exact, "%v/%v: f64 bits %16x exact %v", c.num, c.den, transmute(u64)f, exact)
	}

	n, d := &big.Int{}, &big.Int{}
	defer big.destroy(n, d)

	Big_Case :: struct {
		delta: i64,
		bits:  u64,
	}
	big_cases := []Big_Case{
		{0,  0x7ff0000000000000},
		{-1, 0x7fefffffffffffff},
	}
	for c in big_cases {
		reg_pow2(t, n, 54, -1)
		testing.expect_value(t, big.shl(n, n, 970), nil)
		big.set(d, c.delta)
		testing.expect_value(t, big.add(n, n, d), nil)
		big.set(d, 1)
		testing.expect_value(t, big.rat_set_frac_int(&r, n, d), nil)
		f, exact, err := big.rat_to_f64(&r)
		testing.expect_value(t, err, nil)
		testing.expectf(t, transmute(u64)f == c.bits && !exact, "2^1024 - 2^970 %+v: f64 bits %16x exact %v", c.delta, transmute(u64)f, exact)
	}

	reg_pow2(t, n, 1075, 1)
	reg_pow2(t, d, 2150)
	testing.expect_value(t, big.rat_set_frac_int(&r, n, d), nil)
	f, exact, err := big.rat_to_f64(&r)
	testing.expect_value(t, err, nil)
	testing.expectf(t, transmute(u64)f == 1 && !exact, "(2^1075 + 1) / 2^2150: f64 bits %16x exact %v", transmute(u64)f, exact)
}

@(test)
test_regression_rat_predicates :: proc(t: ^testing.T) {
	r, s: big.Rat
	defer big.destroy(&r, &s)

	zero_value: big.Rat
	testing.expect_value(t, big.rat_sign(&zero_value), big.Sign.Zero_or_Positive)
	even, err := big.rat_is_even(&zero_value)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, even, true)

	testing.expect_value(t, big.rat_set_frac_digit(&r, 0, 1), nil)
	testing.expect_value(t, big.rat_sign(&r), big.Sign.Zero_or_Positive)
	ok: bool
	ok, err = big.rat_is_positive(&r)
	testing.expect_value(t, ok, true)
	ok, err = big.rat_is_negative(&r)
	testing.expect_value(t, ok, false)
	ok, err = big.rat_is_even(&r)
	testing.expect_value(t, ok, true)
	ok, err = big.rat_is_odd(&r)
	testing.expect_value(t, ok, false)
	testing.expect_value(t, big.rat_is_int(&r), true)

	reg_rat_set(t, &r, "-1", "2")
	testing.expect_value(t, big.rat_sign(&r), big.Sign.Negative)
	ok, err = big.rat_is_negative(&r)
	testing.expect_value(t, ok, true)
	ok, err = big.rat_is_even(&r)
	testing.expect_value(t, ok, false)
	ok, err = big.rat_is_odd(&r)
	testing.expect_value(t, ok, false)
	testing.expect_value(t, big.rat_is_int(&r), false)

	reg_rat_set(t, &r, "-4", "1")
	ok, err = big.rat_is_even(&r)
	testing.expect_value(t, ok, true)
	ok, err = big.rat_is_odd(&r)
	testing.expect_value(t, ok, false)

	reg_rat_set(t, &r, "5", "1")
	ok, err = big.rat_is_odd(&r)
	testing.expect_value(t, ok, true)

	testing.expect_value(t, big.rat_set_frac_digit(&r, 10, 4), nil)
	reg_rat_expect(t, &r, "5", "2")
	testing.expect_value(t, big.rat_set_frac_digit(&r, 10, 0), big.Error.Division_by_Zero)

	testing.expect_value(t, big.rat_set_frac_digit(&r, 1, 2), nil)
	testing.expect_value(t, big.rat_set_frac_digit(&s, 3, 4), nil)
	big.rat_swap(&r, &s)
	reg_rat_expect(t, &r, "3", "4")
	reg_rat_expect(t, &s, "1", "2")
}

@(test)
test_regression_rat_norm :: proc(t: ^testing.T) {
	r: big.Rat
	defer big.destroy(&r)

	reg_pow2(t, &r.a, 200)
	testing.expect_value(t, big.mul(&r.a, &r.a, big.DIGIT(6)), nil)
	testing.expect_value(t, big.neg(&r.a, &r.a), nil)
	reg_pow2(t, &r.b, 200)
	testing.expect_value(t, big.mul(&r.b, &r.b, big.DIGIT(4)), nil)
	testing.expect_value(t, big.neg(&r.b, &r.b), nil)
	testing.expect_value(t, big.internal_rat_norm(&r), nil)
	reg_rat_expect(t, &r, "3", "2")

	big.set(&r.a, 6)
	big.set(&r.b, -4)
	testing.expect_value(t, big.internal_rat_norm(&r), nil)
	reg_rat_expect(t, &r, "-3", "2")

	big.set(&r.a, 0)
	big.set(&r.b, -5)
	testing.expect_value(t, big.internal_rat_norm(&r), nil)
	reg_rat_expect(t, &r, "0", "1")
}

@(test)
test_regression_rat_out_of_memory_does_not_leak :: proc(t: ^testing.T) {
	Op :: enum {
		Add,
		Sub,
		Div_Dst_Y,
		Compare,
		To_F64,
		Set_Frac_Int,
		Rat_Add_Int,
		Rat_Mul_Int,
		Rat_Div_Int,
		Int_Sub_Rat,
		Int_Div_Rat,
	}
	outer := context.allocator
	for op in Op {
		for fail_at in 1..=64 {
			track: mem.Tracking_Allocator
			mem.tracking_allocator_init(&track, outer)
			st := Reg_Fail_State{backing = mem.tracking_allocator(&track), fail_at = fail_at}
			context.allocator = mem.Allocator{procedure = reg_fail_proc, data = &st}

			x, y, d: big.Rat
			n: big.Int
			reg_rat_set(t, &x, REG_X_N, REG_X_D, 16)
			reg_rat_set(t, &y, REG_Y_N, REG_Y_D, 16)
			reg_set(t, &n, REG_X_D, 16)

			st.active = true
			err: big.Error
			switch op {
			case .Add:          err = big.rat_add_rat(&d, &x, &y)
			case .Sub:          err = big.rat_sub_rat(&d, &x, &y)
			case .Div_Dst_Y:    err = big.rat_div_rat(&y, &x, &y)
			case .Compare:      _, err = big.rat_compare(&x, &y)
			case .To_F64:       _, _, err = big.rat_to_f64(&x)
			case .Set_Frac_Int: err = big.rat_set_frac_int(&d, &n, &x.a)
			case .Rat_Add_Int:  err = big.rat_add_int(&d, &x, &n)
			case .Rat_Mul_Int:  err = big.rat_mul_int(&d, &x, &n)
			case .Rat_Div_Int:  err = big.rat_div_int(&d, &x, &n)
			case .Int_Sub_Rat:  err = big.int_sub_rat(&d, &n, &x)
			case .Int_Div_Rat:  err = big.int_div_rat(&d, &n, &x)
			}
			st.active = false
			reached := st.count >= fail_at

			big.destroy(&x, &y, &d)
			big.destroy(&n)
			testing.expectf(t, len(track.allocation_map) == 0, "%v, allocation %v failed: %v leaked", op, fail_at, len(track.allocation_map))
			if reached {
				testing.expectf(t, err == .Out_Of_Memory, "%v, allocation %v failed: err = %v", op, fail_at, err)
			}
			mem.tracking_allocator_destroy(&track)
			if !reached {
				break
			}
		}
	}
}

@(test)
test_regression_rat_allocator_argument :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	alloc := mem.tracking_allocator(&track)

	context.allocator = mem.panic_allocator()

	x, y, d: big.Rat
	n, num, den: big.Int
	testing.expect_value(t, big.atoi(&num, REG_X_N, 16, nil, alloc), nil)
	testing.expect_value(t, big.atoi(&den, REG_X_D, 16, nil, alloc), nil)
	testing.expect_value(t, big.rat_set_frac_int(&x, &num, &den, alloc), nil)
	testing.expect_value(t, big.atoi(&num, REG_Y_N, 16, nil, alloc), nil)
	testing.expect_value(t, big.atoi(&den, REG_Y_D, 16, nil, alloc), nil)
	testing.expect_value(t, big.rat_set_frac_int(&y, &num, &den, alloc), nil)
	testing.expect_value(t, big.atoi(&n, REG_X_D, 16, nil, alloc), nil)

	testing.expect_value(t, big.rat_add_rat(&d, &x, &y, alloc), nil)
	testing.expect_value(t, big.rat_sub_rat(&d, &x, &y, alloc), nil)
	testing.expect_value(t, big.rat_mul_rat(&d, &x, &y, alloc), nil)
	testing.expect_value(t, big.rat_div_rat(&d, &x, &y, alloc), nil)
	testing.expect_value(t, big.rat_div_rat(&y, &x, &y, alloc), nil)
	_, cmp_err := big.rat_compare(&x, &y, alloc)
	testing.expect_value(t, cmp_err, nil)
	testing.expect_value(t, big.rat_add_int(&d, &x, &n, alloc), nil)
	testing.expect_value(t, big.rat_div_int(&d, &x, &n, alloc), nil)
	testing.expect_value(t, big.int_sub_rat(&d, &n, &x, alloc), nil)
	testing.expect_value(t, big.rat_set_rat(&d, &x, alloc), nil)
	testing.expect_value(t, big.int_div_rat(&d, &d.a, &d, alloc), nil)
	_, _, f64_err := big.rat_to_f64(&x, alloc)
	testing.expect_value(t, f64_err, nil)
	_, _, f16_err := big.rat_to_f16(&x, alloc)
	testing.expect_value(t, f16_err, nil)
	testing.expect_value(t, big.rat_set_f64(&d, 1e300, alloc), nil)
	testing.expect_value(t, big.rat_set_f64(&d, 1e-300, alloc), nil)
	big.set(&d.a, 6, false, alloc)
	big.set(&d.b, -4, false, alloc)
	testing.expect_value(t, big.internal_rat_norm(&d, alloc), nil)

	big.destroy(&x, &y, &d)
	big.destroy(&n, &num, &den)
	testing.expect_value(t, len(track.allocation_map), 0)
}
