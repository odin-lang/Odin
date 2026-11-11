package test_core_math_big

import "core:math"
import "core:math/big"
import "core:mem"
import "core:testing"

@(private="file")
fix_set :: proc(t: ^testing.T, a: ^big.Int, value: string, loc := #caller_location) {
	testing.expect_value(t, big.atoi(a, value, 10), nil, loc=loc)
}

@(private="file")
fix_expect :: proc(t: ^testing.T, got: ^big.Int, expected: string, loc := #caller_location) {
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
	if !valid {
		testing.expectf(t, false, "expected %v, got an invalid Int (used=%v len=%v sign=%v)", expected, got.used, len(got.digit), got.sign, loc=loc)
		return
	}
	s, _ := big.int_itoa_string(got, 10, false, context.temp_allocator)
	testing.expect_value(t, s, expected, loc=loc)
}

@(test)
test_fix_add_digit_negative :: proc(t: ^testing.T) {
	a, x := &big.Int{}, &big.Int{}
	defer big.destroy(a, x)

	Case :: struct {
		a:   string,
		d:   big.DIGIT,
		sum: string,
	}
	cases := []Case{
		{"-10",                                      3, "-7"},
		{"-3",                                       3, "0"},
		{"-2",                                       3, "1"},
		{"-9223372036854775808",                     5, "-9223372036854775803"},
		{"-1361129467683753853853498429727072845824", 1, "-1361129467683753853853498429727072845823"},
	}
	for c in cases {
		fix_set(t, a, c.a)
		testing.expect_value(t, big.add(x, a, c.d), nil)
		fix_expect(t, x, c.sum)
		fix_expect(t, a, c.a)

		testing.expect_value(t, big.add(a, a, c.d), nil)
		fix_expect(t, a, c.sum)
	}

	fix_set(t, a, "-1")
	testing.expect_value(t, big.internal_incr(a), nil)
	fix_expect(t, a, "0")

	fix_set(t, a, "-9223372036854775808")
	testing.expect_value(t, big.internal_incr(a), nil)
	fix_expect(t, a, "-9223372036854775807")
}

@(test)
test_fix_sub_digit_negative :: proc(t: ^testing.T) {
	a, x := &big.Int{}, &big.Int{}
	defer big.destroy(a, x)

	fix_set(t, a, "-10")
	testing.expect_value(t, big.sub(x, a, big.DIGIT(3)), nil)
	fix_expect(t, x, "-13")
	fix_expect(t, a, "-10")

	testing.expect_value(t, big.sub(a, a, big.DIGIT(3)), nil)
	fix_expect(t, a, "-13")

	fix_set(t, a, "-1")
	testing.expect_value(t, big.internal_decr(a), nil)
	fix_expect(t, a, "-2")
}

@(test)
test_fix_digit_above_mask :: proc(t: ^testing.T) {
	a, x := &big.Int{}, &big.Int{}
	defer big.destroy(a, x)

	fix_set(t, a, "0")
	testing.expect_value(t, big.add(x, a, max(big.DIGIT)), nil)
	fix_expect(t, x, "18446744073709551615")

	fix_set(t, a, "5")
	testing.expect_value(t, big.add(a, a, max(big.DIGIT) - 2), nil)
	fix_expect(t, a, "18446744073709551618")

	fix_set(t, a, "-1")
	testing.expect_value(t, big.add(x, a, max(big.DIGIT)), nil)
	fix_expect(t, x, "18446744073709551614")

	fix_set(t, a, "9223372036854775808")
	testing.expect_value(t, big.sub(x, a, max(big.DIGIT)), nil)
	fix_expect(t, x, "-9223372036854775807")

	fix_set(t, a, "1361129467683753853853498429727072845824")
	testing.expect_value(t, big.sub(x, a, max(big.DIGIT)), nil)
	fix_expect(t, x, "1361129467683753853835051685653363294209")

	fix_set(t, a, "-5")
	testing.expect_value(t, big.sub(x, a, max(big.DIGIT)), nil)
	fix_expect(t, x, "-18446744073709551620")

	fix_set(t, a, "9223372036854775807")
	testing.expect_value(t, big.mul(x, a, max(big.DIGIT)), nil)
	fix_expect(t, x, "170141183460469231704017187605319778305")

	fix_set(t, a, "-3")
	testing.expect_value(t, big.mul(a, a, big.DIGIT(1 << 63)), nil)
	fix_expect(t, a, "-27670116110564327424")

	fix_set(t, a, "18446744073709551615")
	c, err := big.cmp(a, max(big.DIGIT))
	testing.expect_value(t, err, nil)
	testing.expect_value(t, c, 0)

	fix_set(t, a, "18446744073709551616")
	c, _ = big.cmp(a, max(big.DIGIT))
	testing.expect_value(t, c, 1)

	fix_set(t, a, "9223372036854775808")
	c, _ = big.cmp(a, big.DIGIT(1 << 63 + 1))
	testing.expect_value(t, c, -1)
	lt, _ := big.lt(a, big.DIGIT(1 << 63 + 1))
	testing.expect(t, lt)

	c, _ = big.cmp(a, big.DIGIT(1 << 63))
	testing.expect_value(t, c, 0)
}

@(test)
test_fix_divmod_small_karatsuba_cutoff :: proc(t: ^testing.T) {
	a, b, q, r, check := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(a, b, q, r, check)

	big.power_of_two(a, 63 * 200 - 5)
	big.sub(a, a, big.DIGIT(1))
	big.power_of_two(b, 63 * 100 - 7)
	big.add(b, b, big.DIGIT(12345))

	saved := big.MUL_KARATSUBA_CUTOFF
	big.MUL_KARATSUBA_CUTOFF = 40
	err := big.divmod(q, r, a, b)
	big.MUL_KARATSUBA_CUTOFF = saved
	testing.expect_value(t, err, nil)

	big.mul(check, q, b)
	big.add(check, check, r)
	equal, _ := big.equals(check, a)
	testing.expect(t, equal)
	less, _ := big.lt(r, b)
	testing.expect(t, less)
}

@(test)
test_fix_shr1_grows_dest :: proc(t: ^testing.T) {
	a, x, e := &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(a, x, e)

	big.power_of_two(a, 63 * 40 - 1)
	big.power_of_two(e, 63 * 40 - 2)
	big.grow(x, 4)

	testing.expect_value(t, big.internal_int_shr1(x, a), nil)
	testing.expect(t, x.used <= len(x.digit))
	equal, _ := big.equals(x, e)
	testing.expect(t, equal)

	big.set(x, 1)
	testing.expect_value(t, big.halve(x, a), nil)
	equal, _ = big.equals(x, e)
	testing.expect(t, equal)
}

@(test)
test_fix_mod_aliasing :: proc(t: ^testing.T) {
	a, b := &big.Int{}, &big.Int{}
	defer big.destroy(a, b)

	fix_set(t, a, "-7")
	fix_set(t, b, "3")
	testing.expect_value(t, big.mod(b, a, b), nil)
	fix_expect(t, b, "2")

	fix_set(t, a, "7")
	fix_set(t, b, "-117224624314804210796494043584166625280")
	testing.expect_value(t, big.mod(b, a, b), nil)
	fix_expect(t, b, "-117224624314804210796494043584166625273")
}

@(test)
test_fix_internal_mod_digit_floored :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	Case :: struct {
		a: string,
		d: big.DIGIT,
		r: big.DIGIT,
	}
	cases := []Case{
		{"-7",                      3,       2},
		{"-6",                      3,       0},
		{"7",                       3,       1},
		{"0",                       3,       0},
		{"-1180591620717411303424", 1000003, 556101},
		{"1180591620717411303424",  1000003, 443902},
		{"-1",                      max(big.DIGIT), max(big.DIGIT) - 1},
	}
	for c in cases {
		fix_set(t, a, c.a)
		r, err := big.internal_int_mod_digit(a, c.d)
		testing.expect_value(t, err, nil)
		testing.expectf(t, r == c.r, "internal_int_mod_digit(%v, %v) = %v, expected %v", c.a, c.d, r, c.r)
		fix_expect(t, a, c.a)
	}
}

@(test)
test_fix_modular_aliasing :: proc(t: ^testing.T) {
	a, b, m := &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(a, b, m)

	fix_set(t, a, "4")
	fix_set(t, b, "5")

	fix_set(t, m, "7")
	testing.expect_value(t, big.addmod(m, a, b, m), nil)
	fix_expect(t, m, "2")

	fix_set(t, m, "7")
	testing.expect_value(t, big.submod(m, a, b, m), nil)
	fix_expect(t, m, "6")

	fix_set(t, m, "7")
	testing.expect_value(t, big.mulmod(m, a, b, m), nil)
	fix_expect(t, m, "6")

	fix_set(t, m, "7")
	testing.expect_value(t, big.sqrmod(m, a, m), nil)
	fix_expect(t, m, "2")

	fix_set(t, a, "-3")
	fix_set(t, b, "3")
	fix_set(t, m, "85070591730234615865843651857942052863")
	testing.expect_value(t, big.addmod(m, a, b, m), nil)
	fix_expect(t, m, "0")
}

@(test)
test_fix_internal_is_power_of_two :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	Case :: struct {
		a:    string,
		pow2: bool,
	}
	cases := []Case{
		{"0",                                                             false},
		{"1",                                                             true},
		{"9223372036854775808",                                           true},
		{"85070591730234615865843651857942052864",                        true},
		{"85070591730234615875067023894796828672",                        false},
		{"1361129467683753853890391917874491949056",                      false},
		{"1606938044258990275541962092341162602522202993782792835301376", true},
	}
	for c in cases {
		fix_set(t, a, c.a)
		pow2 := big.internal_is_power_of_two(a)
		testing.expectf(t, pow2 == c.pow2, "internal_is_power_of_two(%v) = %v, expected %v", c.a, pow2, c.pow2)
	}
}

@(test)
test_fix_digit_log :: proc(t: ^testing.T) {
	_, err := big.digit_log(0, 2)
	testing.expect_value(t, err, big.Error.Math_Domain_Error)

	_, err = big.digit_log(5, 1)
	testing.expect_value(t, err, big.Error.Invalid_Argument)

	_, err = big.digit_log(5, 0)
	testing.expect_value(t, err, big.Error.Invalid_Argument)

	l: int
	l, err = big.digit_log(1, 2)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, l, 0)

	l, err = big.digit_log(big.DIGIT(1) << 62, 2)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, l, 62)

	l, err = big.digit_log(max(big.DIGIT), 3)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, l, 40)
}

@(test)
test_fix_root_n :: proc(t: ^testing.T) {
	a, b := &big.Int{}, &big.Int{}
	defer big.destroy(a, b)

	Case :: struct {
		src:  string,
		n:    int,
		root: string,
	}
	cases := []Case{
		{"27",      3, "3"},
		{"26",      3, "2"},
		{"28",      3, "3"},
		{"8",       3, "2"},
		{"125",     3, "5"},
		{"1024",   10, "2"},
		{"1000000", 3, "100"},
		{"0",       3, "0"},
		{"0",       4, "0"},
		{"1",       5, "1"},
		{"-1",      3, "-1"},
		{"-2",      3, "-1"},
		{"-27",     3, "-3"},
		{"-28",     3, "-3"},
		{"-30",     3, "-3"},
		{"-7",      1, "-7"},
		{"7",       1, "7"},
		{"2293498615990071631522058267935216351033252875934138343916536740976195317476058326482478869677696133629849", 5, "1180591620717411315769"},
		{"2293498615990071631522058267935216351033252875934138343916536740976195317476058326482478869677696133629848", 5, "1180591620717411315768"},
		{"6858417554272229231010592851597488237964919310333792092163740655365213223470332901755600663705508097042650915682315826416015625", 31, "12345"},
		{"6858417554272229231010592851597488237964919310333792092163740655365213223470332901755600663705508097042650915682315826416015624", 31, "12344"},
	}
	for c in cases {
		fix_set(t, a, c.src)
		testing.expect_value(t, big.root_n(b, a, c.n), nil)
		fix_expect(t, b, c.root)
	}

	big.power_of_two(a, 1000)
	testing.expect_value(t, big.root_n(b, a, 600), nil)
	fix_expect(t, b, "3")

	big.set(a, -28)
	testing.expect_value(t, big.root_n(a, a, 3), nil)
	fix_expect(t, a, "-3")

	big.set(a, 5)
	testing.expect_value(t, big.root_n(b, a, 0), big.Error.Invalid_Argument)
	testing.expect_value(t, big.root_n(b, a, -1), big.Error.Invalid_Argument)
	big.set(a, -16)
	testing.expect_value(t, big.root_n(b, a, 4), big.Error.Invalid_Argument)
}

@(test)
test_fix_pow_negative_exponent :: proc(t: ^testing.T) {
	x := &big.Int{}
	defer big.destroy(x)

	Case :: struct {
		base:  int,
		power: int,
		pow:   string,
	}
	cases := []Case{
		{ 1, -1, "1"},
		{ 1, -4, "1"},
		{-1, -1, "-1"},
		{-1, -3, "-1"},
		{-1, -2, "1"},
		{ 2, -1, "0"},
		{-7, -1, "0"},
	}
	for c in cases {
		testing.expect_value(t, big.pow(x, c.base, c.power), nil)
		fix_expect(t, x, c.pow)
	}
	testing.expect_value(t, big.pow(x, 0, -1), big.Error.Math_Domain_Error)
}

@(test)
test_fix_pow_error_path_no_leak :: proc(t: ^testing.T) {
	base, dest := &big.Int{}, &big.Int{}
	defer big.destroy(base, dest)

	big.set(base, 3)
	big.set(dest, 7)
	dest.flags = {.Immutable}
	testing.expect_value(t, big.internal_int_pow(dest, base, 5), big.Error.Assignment_To_Immutable)
	dest.flags = {}
}

@(test)
test_fix_is_square_zero :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	big.set(a, 0)
	square, err := big.int_is_square(a)
	testing.expect_value(t, err, nil)
	testing.expect(t, square)
}

@(test)
test_fix_shr_signed :: proc(t: ^testing.T) {
	a, b := &big.Int{}, &big.Int{}
	defer big.destroy(a, b)

	big.set(a, -8)
	testing.expect_value(t, big.shr_signed(b, a, 1), nil)
	fix_expect(t, b, "-4")
	fix_expect(t, a, "-8")

	big.set(a, -5)
	testing.expect_value(t, big.shr_signed(b, a, 1), nil)
	fix_expect(t, b, "-3")
	fix_expect(t, a, "-5")

	big.set(a, -1)
	testing.expect_value(t, big.shr_signed(b, a, 100), nil)
	fix_expect(t, b, "-1")

	big.set(a, -1)
	testing.expect_value(t, big.shr_signed(a, a, 0), nil)
	fix_expect(t, a, "-1")

	fix_set(t, a, "-9223372036854775809")
	testing.expect_value(t, big.shr_signed(b, a, 63), nil)
	fix_expect(t, b, "-2")

	fix_set(t, a, "-9223372036854775808")
	testing.expect_value(t, big.shr_signed(a, a, 1), nil)
	fix_expect(t, a, "-4611686018427387904")
}

@(test)
test_fix_complement :: proc(t: ^testing.T) {
	a, b := &big.Int{}, &big.Int{}
	defer big.destroy(a, b)

	Case :: struct {
		a:          string,
		complement: string,
	}
	cases := []Case{
		{"5",                    "-6"},
		{"-6",                   "5"},
		{"0",                    "-1"},
		{"-1",                   "0"},
		{"9223372036854775807",  "-9223372036854775808"},
		{"-9223372036854775809", "9223372036854775808"},
	}
	for c in cases {
		fix_set(t, a, c.a)
		testing.expect_value(t, big.bit_complement(b, a), nil)
		fix_expect(t, b, c.complement)
		fix_expect(t, a, c.a)

		testing.expect_value(t, big.bit_complement(a, a), nil)
		fix_expect(t, a, c.complement)
	}
}

@(test)
test_fix_get_signed_range :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	fix_set(t, a, "-9223372036854775809")
	v64, err := big.get(a, i64)
	testing.expect_value(t, err, big.Error.Integer_Underflow)
	testing.expect_value(t, v64, min(i64))

	fix_set(t, a, "-18446744073709551615")
	v64, err = big.get(a, i64)
	testing.expect_value(t, err, big.Error.Integer_Underflow)
	testing.expect_value(t, v64, min(i64))

	fix_set(t, a, "-9223372036854775808")
	v64, err = big.get(a, i64)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, v64, min(i64))

	fix_set(t, a, "-4294967295")
	v32: i32
	v32, err = big.get(a, i32)
	testing.expect_value(t, err, big.Error.Integer_Underflow)
	testing.expect_value(t, v32, min(i32))

	fix_set(t, a, "-2147483649")
	v32, err = big.get(a, i32)
	testing.expect_value(t, err, big.Error.Integer_Underflow)
	testing.expect_value(t, v32, min(i32))

	fix_set(t, a, "-2147483648")
	v32, err = big.get(a, i32)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, v32, min(i32))

	fix_set(t, a, "-340282366920938463463374607431768211455")
	v128: i128
	v128, err = big.get(a, i128)
	testing.expect_value(t, err, big.Error.Integer_Underflow)
	testing.expect_value(t, v128, min(i128))

	fix_set(t, a, "-170141183460469231731687303715884105729")
	v128, err = big.get(a, i128)
	testing.expect_value(t, err, big.Error.Integer_Underflow)
	testing.expect_value(t, v128, min(i128))

	fix_set(t, a, "-170141183460469231731687303715884105728")
	v128, err = big.get(a, i128)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, v128, min(i128))

	big.set(a, -255)
	v8: i8
	v8, err = big.get(a, i8)
	testing.expect_value(t, err, big.Error.Integer_Underflow)
	testing.expect_value(t, v8, min(i8))

	big.set(a, -129)
	v8, err = big.get(a, i8)
	testing.expect_value(t, err, big.Error.Integer_Underflow)
	testing.expect_value(t, v8, min(i8))

	big.set(a, -128)
	v8, err = big.get(a, i8)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, v8, min(i8))
}

@(test)
test_fix_get_low_u64 :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	fix_set(t, a, "9223372036854775813")
	testing.expect_value(t, big.internal_get_low_u64(a), u64(9223372036854775813))

	fix_set(t, a, "340282366920938463463374607431768211455")
	testing.expect_value(t, big.internal_get_low_u64(a), max(u64))
}

@(test)
test_fix_get_float :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	big.power_of_two(a, 1200)
	f, err := big.int_get_float(a)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, f, math.INF_F64)

	big.neg(a, a)
	f, _ = big.int_get_float(a)
	testing.expect_value(t, f, math.NEG_INF_F64)

	big.power_of_two(a, 1100)
	f, _ = big.int_get_float(a)
	testing.expect_value(t, f, math.INF_F64)

	big.power_of_two(a, 1023)
	f, _ = big.int_get_float(a)
	testing.expect_value(t, f, math.ldexp(f64(1), 1023))

	big.power_of_two(a, 1000)
	f, _ = big.int_get_float(a)
	testing.expect_value(t, f, math.ldexp(f64(1), 1000))

	fix_set(t, a, "13835058055282164737")
	f, _ = big.int_get_float(a)
	testing.expect_value(t, f, 13835058055282165760.0)

	big.power_of_two(a, 1024)
	big.sub(a, a, 1)
	f, _ = big.int_get_float(a)
	testing.expect_value(t, f, math.INF_F64)

	fix_set(t, a, "179769313486231580793728971405303415079934132710037826936173778980444968292764750946649017977587207096330286416692887910946555547851940402630657488671505820681908902000708383676273854845817711531764475730270069855571366959622842914819860834936475292719074168444365510704342711559699508093042880177904174497792")
	f, _ = big.int_get_float(a)
	testing.expect_value(t, f, math.INF_F64)

	fix_set(t, a, "179769313486231580793728971405303415079934132710037826936173778980444968292764750946649017977587207096330286416692887910946555547851940402630657488671505820681908902000708383676273854845817711531764475730270069855571366959622842914819860834936475292719074168444365510704342711559699508093042880177904174497791")
	f, _ = big.int_get_float(a)
	testing.expect_value(t, f, max(f64))

	big.set(a, max(u128))
	big.shrink(a)
	f, _ = big.int_get_float(a)
	testing.expect_value(t, f, math.ldexp(f64(1), 128))
}

@(test)
test_fix_reads_stay_below_used :: proc(t: ^testing.T) {
	storage: [4096]byte
	for &b in storage {
		b = 0xFF
	}
	arena: mem.Arena
	mem.arena_init(&arena, storage[:])

	src := &big.Int{}
	defer big.destroy(src)
	big.power_of_two(src, 189)
	big.sub(src, src, 1)

	b := &big.Int{}
	testing.expect_value(t, big.copy(b, src, true, mem.arena_allocator(&arena)), nil)
	testing.expect_value(t, b.used, 3)
	testing.expect_value(t, len(b.digit), 3)

	f, _ := big.int_get_float(b)
	testing.expect_value(t, f, math.ldexp(f64(1), 189))

	r, err := big.int_bitfield_extract(b, 184, 8)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, r, 31)

	_, err = big.int_bitfield_extract(b, 630, 8)
	testing.expect_value(t, err, big.Error.Invalid_Argument)

	d := &big.Int{}
	defer big.destroy(d)
	big.set(d, 0)
	testing.expect_value(t, big.copy_digits(d, b, 3, 2), nil)
	testing.expect_value(t, d.digit[0], big._MASK)
	testing.expect_value(t, d.digit[1], 0)
	testing.expect_value(t, d.digit[2], 0)
}

@(test)
test_fix_bitfield_offsets :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	big.set(a, 5)
	_, err := big.internal_int_bitfield_extract_single(a, -1)
	testing.expect_value(t, err, big.Error.Invalid_Argument)
	_, err = big.internal_int_bitfield_extract_bool(a, -1)
	testing.expect_value(t, err, big.Error.Invalid_Argument)
	testing.expect_value(t, big.internal_int_bitfield_set_single(a, -1), big.Error.Invalid_Argument)
	testing.expect_value(t, big.internal_int_bitfield_unset_single(a, -2), big.Error.Invalid_Argument)
	testing.expect_value(t, big.internal_int_bitfield_toggle_single(a, -3), big.Error.Invalid_Argument)
	fix_expect(t, a, "5")

	_, err = big.int_bitfield_extract(a, 63 * 1000, 8)
	testing.expect_value(t, err, big.Error.Invalid_Argument)
	_, err = big.int_bitfield_extract(a, -126, 8)
	testing.expect_value(t, err, big.Error.Invalid_Argument)
	_, err = big.int_bitfield_extract(a, -1, 1)
	testing.expect_value(t, err, big.Error.Invalid_Argument)

	fix_set(t, a, "123456789012345678901234567890123456789")
	v, verr := big.int_bitfield_extract(a, 120, 126)
	testing.expect_value(t, verr, nil)
	testing.expect_value(t, v, 92)
	v, verr = big.int_bitfield_extract(a, 40, 100)
	testing.expect_value(t, verr, nil)
	testing.expect_value(t, v, 112283295504626656930881443)
	v, verr = big.int_bitfield_extract(a, 62, 64)
	testing.expect_value(t, verr, nil)
	testing.expect_value(t, v, 8323679697344396054)
}

@(test)
test_fix_bitfield_clamps :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	big.set(a, 1)
	testing.expect_value(t, big.internal_int_bitfield_unset_single(a, 0), nil)
	fix_expect(t, a, "0")

	big.set(a, 1)
	testing.expect_value(t, big.internal_int_bitfield_toggle_single(a, 0), nil)
	fix_expect(t, a, "0")

	fix_set(t, a, "9223372036854775808")
	testing.expect_value(t, big.internal_int_bitfield_toggle_single(a, 63), nil)
	fix_expect(t, a, "0")
}

@(test)
test_fix_random_resets_flags :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	big.nan(a)
	testing.expect_value(t, big.random(a, 64), nil)
	testing.expect_value(t, a.flags, big.Flags{})

	big.inf(a)
	testing.expect_value(t, big.random(a, 200), nil)
	testing.expect_value(t, a.flags, big.Flags{})
}

@(test)
test_fix_power_of_two_resets_state :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	big.set(a, -7)
	testing.expect_value(t, big.power_of_two(a, 5), nil)
	fix_expect(t, a, "32")

	big.set(a, -7)
	testing.expect_value(t, big.power_of_two(a, 126), nil)
	fix_expect(t, a, "85070591730234615865843651857942052864")

	big.inf(a)
	testing.expect_value(t, big.power_of_two(a, 200), nil)
	testing.expect_value(t, a.flags, big.Flags{})
	fix_expect(t, a, "1606938044258990275541962092341162602522202993782792835301376")
}

@(test)
test_fix_internal_minus_inf :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	testing.expect_value(t, big.internal_minus_inf(a), nil)
	testing.expect_value(t, a.sign, big.Sign.Negative)
	testing.expect_value(t, a.flags, big.Flags{.Inf})
}

@(test)
test_fix_swap_flags :: proc(t: ^testing.T) {
	a, b := &big.Int{}, &big.Int{}
	defer big.destroy(a, b)

	big.set(a, 5)
	big.nan(b)
	big.swap(a, b)
	testing.expect_value(t, a.flags, big.Flags{.NaN})
	testing.expect_value(t, b.flags, big.Flags{})
	fix_expect(t, b, "5")
}

@(test)
test_fix_shrink :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	big.power_of_two(a, 700)
	big.set(a, max(u128))
	testing.expect_value(t, big.shrink(a), nil)
	testing.expect_value(t, cap(a.digit), a.used)
	fix_expect(t, a, "340282366920938463463374607431768211455")
}

@(test)
test_fix_grow_limit :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	testing.expect_value(t, big.grow(a, big._MAX_DIGIT_COUNT + 1), big.Error.Integer_Overflow)
	testing.expect_value(t, big.grow(a, max(int)), big.Error.Integer_Overflow)
}

@(test)
test_fix_copy_digits_bounds :: proc(t: ^testing.T) {
	a, b := &big.Int{}, &big.Int{}
	defer big.destroy(a, b)

	big.set(a, max(u128))
	big.shrink(a)
	big.zero(b)
	testing.expect_value(t, big.copy_digits(b, a, 3, 2), nil)
	testing.expect_value(t, b.digit[0], a.digit[2])
	testing.expect_value(t, b.digit[1], 0)
	testing.expect_value(t, b.digit[2], 0)

	testing.expect_value(t, big.copy_digits(b, a, 1, -1), big.Error.Invalid_Argument)
	testing.expect_value(t, big.copy_digits(b, a, 1, 4), big.Error.Invalid_Argument)
}

@(private="file")
fix_expect_hex :: proc(t: ^testing.T, got: ^big.Int, expected: string, loc := #caller_location) {
	s, err := big.int_itoa_string(got, 16, false, context.temp_allocator)
	testing.expect_value(t, err, nil, loc=loc)
	testing.expect_value(t, s, expected, loc=loc)
}

@(private="file")
fix_ones :: proc(a: ^big.Int, limbs: int) {
	big.power_of_two(a, limbs * big._DIGIT_BITS)
	big.sub(a, a, 1)
}

@(private="file")
fix_ones_product :: proc(e, tmp: ^big.Int, m, n: int) {
	big.power_of_two(e, (m + n) * big._DIGIT_BITS)
	big.add(e, e, 1)
	big.power_of_two(tmp, m * big._DIGIT_BITS)
	big.sub(e, e, tmp)
	big.power_of_two(tmp, n * big._DIGIT_BITS)
	big.sub(e, e, tmp)
}

@(test)
test_fix_cutoffs_below_minimum :: proc(t: ^testing.T) {
	mk, sk, mt, st := big.MUL_KARATSUBA_CUTOFF, big.SQR_KARATSUBA_CUTOFF, big.MUL_TOOM_CUTOFF, big.SQR_TOOM_CUTOFF
	defer big.MUL_KARATSUBA_CUTOFF, big.SQR_KARATSUBA_CUTOFF, big.MUL_TOOM_CUTOFF, big.SQR_TOOM_CUTOFF = mk, sk, mt, st

	a, b, c, e, tmp, q, r := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(a, b, c, e, tmp, q, r)

	settings := [?][4]int{{0, 0, 0, 0}, {1, 1, 2, 2}, {2, 2, 3, 3}}
	shapes   := [?][2]int{{1, 1}, {1, 2}, {2, 2}, {2, 3}, {3, 3}, {3, 7}, {5, 5}, {9, 4}}

	for s in settings {
		big.MUL_KARATSUBA_CUTOFF, big.SQR_KARATSUBA_CUTOFF, big.MUL_TOOM_CUTOFF, big.SQR_TOOM_CUTOFF = s[0], s[1], s[2], s[3]

		for shape in shapes {
			fix_ones(a, shape[0])
			fix_ones(b, shape[1])

			fix_ones_product(e, tmp, shape[0], shape[1])
			testing.expect_value(t, big.mul(c, a, b), nil)
			equal, _ := big.equals(c, e)
			testing.expectf(t, equal, "cutoffs %v: mul of %v and %v limbs of ones is wrong", s, shape[0], shape[1])

			fix_ones_product(e, tmp, shape[0], shape[0])
			testing.expect_value(t, big.sqr(c, a), nil)
			equal, _ = big.equals(c, e)
			testing.expectf(t, equal, "cutoffs %v: sqr of %v limbs of ones is wrong", s, shape[0])
		}

		fix_ones(a, 3)
		fix_ones(b, 2)
		testing.expect_value(t, big._private_int_div_recursive(q, r, a, b), nil)
		fix_expect_hex(t, q, "8000000000000000")
		fix_expect_hex(t, r, "7FFFFFFFFFFFFFFF")

		fix_ones(a, 30)
		fix_ones(b, 9)
		testing.expect_value(t, big.divmod(q, r, a, b), nil)
		big.mul(c, q, b)
		big.add(c, c, r)
		equal, _ := big.equals(c, a)
		testing.expectf(t, equal, "cutoffs %v: divmod doesn't round-trip", s)
		less, _ := big.lt(r, b)
		testing.expectf(t, less, "cutoffs %v: divmod remainder isn't below the divisor", s)
	}
}

@(test)
test_fix_mul_high_small_digits :: proc(t: ^testing.T) {
	a, c := &big.Int{}, &big.Int{}
	defer big.destroy(a, c)

	fix_ones(a, 5)
	testing.expect_value(t, big._private_int_mul_high(c, a, a, 1), nil)
	fix_expect_hex(t, c, "3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC0000000000000010000000000000000")
}

@(test)
test_fix_comba_result_is_non_negative :: proc(t: ^testing.T) {
	a, b := &big.Int{}, &big.Int{}
	defer big.destroy(a, b)

	big.set(a, -3)
	big.set(b, 5)
	testing.expect_value(t, big._private_int_mul(a, a, b, 4), nil)
	fix_expect(t, a, "15")

	big.set(a, -3)
	testing.expect_value(t, big._private_int_sqr_comba(a, a), nil)
	fix_expect(t, a, "9")

	big.set(a, -3)
	testing.expect_value(t, big._private_int_mul_high(a, a, b, 0), nil)
	fix_expect(t, a, "15")
}

@(test)
test_fix_private_division_numerator_smaller :: proc(t: ^testing.T) {
	a, b, q, r := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(a, b, q, r)

	big.set(a, -5)
	big.set(b, 7)
	testing.expect_value(t, big._private_int_div_school(q, r, a, b), nil)
	fix_expect(t, q, "0")
	fix_expect(t, r, "-5")

	big.power_of_two(a, 130)
	big.add(a, a, 5)
	big.neg(a, a)
	big.power_of_two(b, 130)
	big.add(b, b, 7)
	testing.expect_value(t, big._private_int_div_recursive(q, r, a, b), nil)
	fix_expect(t, q, "0")
	fix_expect(t, r, "-1361129467683753853853498429727072845829")

	big.set(a, 5)
	testing.expect_value(t, big._private_int_div_recursive(q, r, a, b), nil)
	fix_expect(t, q, "0")
	fix_expect(t, r, "5")
}

@(test)
test_fix_invmod_negative :: proc(t: ^testing.T) {
	a, m, r := &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(a, m, r)

	Case :: struct {
		a, m, inv: string,
	}
	cases := []Case{
		{"-1",                    "3",                                       "2"},
		{"-2",                    "3",                                       "1"},
		{"-3",                    "7",                                       "2"},
		{"-3",                    "8",                                       "5"},
		{"-2",                    "1073741821",                              "536870910"},
		{"-50400527088052790036", "1706537743302510733",                     "602917333812113116"},
		{"-10",                   "170141183460469231731687303715884105727", "51042355038140769519506191114765231718"},
		{"3",                     "7",                                       "5"},
	}
	for c in cases {
		fix_set(t, a, c.a)
		fix_set(t, m, c.m)
		testing.expect_value(t, big.internal_int_inverse_modulo(r, a, m), nil)
		fix_expect(t, r, c.inv)
	}

	g, x, p := &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(g, x, p)

	Pow_Case :: struct {
		g, x, p, pow: int,
	}
	pow_cases := []Pow_Case{
		{-3, -1,  7,  2},
		{-2, -1,  5,  2},
		{-7, -3, 97, 69},
	}
	for c in pow_cases {
		big.set(g, c.g)
		big.set(x, c.x)
		big.set(p, c.p)
		testing.expect_value(t, big.internal_int_power_modulo(r, g, x, p), nil)
		equal, _ := big.equals(r, big.DIGIT(c.pow))
		testing.expectf(t, equal, "powmod(%v, %v, %v) is wrong", c.g, c.x, c.p)
	}
}

@(test)
test_fix_powmod_2k_modulus_with_zero_low_digit :: proc(t: ^testing.T) {
	Case :: struct {
		g, x, p, pow: string,
	}
	cases := []Case{
		{"2",                         "46",    "18000000000000000",                "10000000000000000"},
		{"123456789ABCDEF0123456789", "10001", "1FFFFFFFFFFFFFFF8000000000000000", "4BDF16062556D4D32256B2357ED6789"},
	}
	g, x, p, r := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(g, x, p, r)
	for c in cases {
		testing.expect_value(t, big.atoi(g, c.g, 16), nil)
		testing.expect_value(t, big.atoi(x, c.x, 16), nil)
		testing.expect_value(t, big.atoi(p, c.p, 16), nil)
		reducible, _ := big._private_int_reduce_is_2k(p)
		testing.expect(t, !reducible)
		testing.expect_value(t, big.internal_int_power_modulo(r, g, x, p), nil)
		fix_expect_hex(t, r, c.pow)
	}
}

@(test)
test_fix_powmod_aliasing :: proc(t: ^testing.T) {
	Case :: struct {
		p, pow: string,
	}
	cases := []Case{
		{"8FC686F9FD800FF",                                                 "8F688E472CB1AFC"},
		{"10000000000000001",                                               "9B016010E3B29A07"},
		{"95506A7A4B402C9E740B6578A96AB462BFD9A7F2C5882369CFCDD00F7A3D667", "4053233023EB85D46542AEC472FF5B3A696B3D1A7A853F4A8D9FA028ECAE348"},
		{"1FFFFFFFFFFFFFFFFFFFFFFD",                                        "13E79A13BADC724D57973CBB"},
		{"B01B03F9BC6ACEC627A855ADB434B24",                                 "AF3C05700C011C289BD1B705F387F07"},
	}
	g, x, p, r := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(g, x, p, r)
	for c in cases {
		testing.expect_value(t, big.atoi(g, "1234567890ABCDEF1234567", 16), nil)
		testing.expect_value(t, big.atoi(x, "10001", 16), nil)
		testing.expect_value(t, big.atoi(p, c.p, 16), nil)

		testing.expect_value(t, big.internal_int_power_modulo(r, g, x, p), nil)
		fix_expect_hex(t, r, c.pow)

		big.copy(r, g)
		testing.expect_value(t, big.internal_int_power_modulo(r, r, x, p), nil)
		fix_expect_hex(t, r, c.pow)

		big.copy(r, x)
		testing.expect_value(t, big.internal_int_power_modulo(r, g, r, p), nil)
		fix_expect_hex(t, r, c.pow)

		big.copy(r, p)
		testing.expect_value(t, big.internal_int_power_modulo(r, g, x, r), nil)
		fix_expect_hex(t, r, c.pow)
	}

	big.set(g, 3)
	big.set(x, 5)
	big.set(p, 97)
	testing.expect_value(t, big.internal_int_power_modulo(x, g, x, p), nil)
	fix_expect(t, x, "49")

	big.set(x, 5)
	testing.expect_value(t, big.internal_int_power_modulo(p, g, x, p), nil)
	fix_expect(t, p, "49")

	fix_set(t, p, "18446744073709551557")
	testing.expect_value(t, big.internal_int_power_modulo(g, g, x, p), nil)
	fix_expect(t, g, "243")
}

@(test)
test_fix_powmod_diminished_radix_moduli :: proc(t: ^testing.T) {
	g, x, p, r := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(g, x, p, r)

	big.set(g, 3)
	big.power_of_two(x, 100)
	big.add(x, x, 1)
	big.power_of_two(p, 126)
	big.sub(p, p, 5)
	testing.expect_value(t, big.internal_int_power_modulo(r, g, x, p), nil)
	fix_expect(t, r, "76175742892888567509066520953182919715")

	testing.expect_value(t, big.atoi(g, "1234567890ABCDEF1234567", 16), nil)
	testing.expect_value(t, big.atoi(x, "10001", 16), nil)
	big.power_of_two(p, 189)
	big.sub(p, p, 1257)
	testing.expect_value(t, big.internal_int_power_modulo(r, g, x, p), nil)
	fix_expect(t, r, "458875556025950998708974390212727194273531641410459905588")
}

@(test)
test_fix_private_copy_digits_bounds :: proc(t: ^testing.T) {
	buf: [1024]byte
	arena: mem.Arena
	mem.arena_init(&arena, buf[:])
	arena_allocator := mem.arena_allocator(&arena)

	src, dest := &big.Int{}, &big.Int{}
	testing.expect_value(t, big.internal_grow(src, 4, true, arena_allocator), nil)
	after := make([]big.DIGIT, 4, arena_allocator)
	for i in 0..<4 {
		src.digit[i] = big.DIGIT(i + 1)
		after[i]     = 24158
	}
	src.used = 4
	testing.expect_value(t, big.internal_grow(dest, 8, true, arena_allocator), nil)

	testing.expect_value(t, big._private_copy_digits(dest, src, 4, 2), nil)
	testing.expect_value(t, dest.digit[0], 3)
	testing.expect_value(t, dest.digit[1], 4)
	testing.expect_value(t, dest.digit[2], 0)
	testing.expect_value(t, dest.digit[3], 0)

	testing.expect_value(t, big._private_copy_digits(dest, src, 1, -1), big.Error.Invalid_Argument)
	testing.expect_value(t, big._private_copy_digits(dest, src, -1, 0), big.Error.Invalid_Argument)
}
