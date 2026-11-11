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
