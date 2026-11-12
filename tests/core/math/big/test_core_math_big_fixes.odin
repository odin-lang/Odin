package test_core_math_big

import "core:math"
import "core:math/big"
import "core:mem"
import "core:slice"
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

@(test)
test_fix_powmod_modulus_one :: proc(t: ^testing.T) {
	g, x, p, r := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(g, x, p, r)

	Case :: struct {
		g, x: int,
	}
	cases := []Case{
		{10,  0},
		{ 0,  0},
		{ 3,  5},
		{-5,  0},
		{-5, -1},
		{ 7, -3},
	}
	big.set(p, 1)
	for c in cases {
		big.set(g, c.g)
		big.set(x, c.x)
		big.set(r, 42)
		testing.expectf(t, big.internal_int_power_modulo(r, g, x, p) == nil, "powmod(%v, %v, 1) failed", c.g, c.x)
		fix_expect(t, r, "0")
	}
}

@(test)
test_fix_miller_rabin_base_at_most_one :: proc(t: ^testing.T) {
	a, b := &big.Int{}, &big.Int{}
	defer big.destroy(a, b)

	big.set(a, 7)
	for base in ([]int{1, 0, -1, -5}) {
		big.set(b, base)
		probably_prime, err := big.internal_int_prime_miller_rabin(a, b)
		testing.expectf(t, !probably_prime && err == .Invalid_Argument, "miller_rabin(7, %v) = %v, %v", base, probably_prime, err)
	}
}

@(test)
test_fix_is_prime_negative :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	values := []string{"-1", "-2", "-3", "-7", "-1619", "-1621", "-1000003", "-2305843009213693951", "-170141183460469231731687303715884105727"}
	for v in values {
		fix_set(t, a, v)
		is_prime, err := big.internal_int_is_prime(a)
		testing.expectf(t, !is_prime && err == nil, "is_prime(%v) = %v, %v", v, is_prime, err)
	}
}

@(test)
test_fix_is_prime_random_bases :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	Case :: struct {
		n:       string,
		trials:  int,
		mr_only: bool,
		prime:   bool,
	}
	cases := []Case{
		{"1000003",                    1, false, true},
		{"1000001",                    1, false, false},
		{"2305843009213693951",        0, false, true},
		{"9223372036854775783",        3, true,  true},
		{"18446744073709551557",       5, false, true},
		{"3825123056546413051",       20, true,  false},
		{"318665857834031151167461",  20, true,  false},
		{"3317044064679887385961981", 20, true,  false},
	}
	for c in cases {
		fix_set(t, a, c.n)
		is_prime, err := big.internal_int_is_prime(a, c.trials, c.mr_only)
		testing.expectf(t, is_prime == c.prime && err == nil, "is_prime(%v, %v, %v) = %v, %v", c.n, c.trials, c.mr_only, is_prime, err)
	}
}

@(test)
test_fix_strong_lucas_selfridge :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	Case :: struct {
		n:     string,
		lucas: bool,
	}
	cases := []Case{
		{"3",                                       true},
		{"7",                                       true},
		{"19",                                      true},
		{"1000003",                                 true},
		{"170141183460469231731687303715884105727", true},
		{"5459",                                    true},
		{"5777",                                    true},
		{"187",                                     false},
		{"10403",                                   false},
	}
	for c in cases {
		fix_set(t, a, c.n)
		lucas, err := big.internal_int_prime_strong_lucas_selfridge(a)
		testing.expectf(t, lucas == c.lucas && err == nil, "strong_lucas_selfridge(%v) = %v, %v", c.n, lucas, err)
	}
}

@(test)
test_fix_strong_lucas_selfridge_square :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	squares := []string{
		"0",
		"1",
		"4",
		"9",
		"25",
		"2627641",
		"1000072001494007128009801",
		"5316911983139663487003542222693990401",
		"28948022309329048855892746252171976962977213799489202546401021394546514198529",
	}
	for n in squares {
		fix_set(t, a, n)
		lucas, err := big.internal_int_prime_strong_lucas_selfridge(a)
		testing.expectf(t, !lucas && err == nil, "strong_lucas_selfridge(%v) = %v, %v", n, lucas, err)
	}
}

@(test)
test_fix_prime_allocator_argument :: proc(t: ^testing.T) {
	ctx_track, arg_track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&ctx_track, context.allocator)
	mem.tracking_allocator_init(&arg_track, context.allocator)
	defer mem.tracking_allocator_destroy(&ctx_track)
	defer mem.tracking_allocator_destroy(&arg_track)
	arg_alloc := mem.tracking_allocator(&arg_track)

	a, b := &big.Int{}, &big.Int{}
	defer big.destroy(a, b)
	testing.expect_value(t, big.set(a, 1000003, false, arg_alloc), nil)
	testing.expect_value(t, big.set(b, 2, false, arg_alloc), nil)

	{
		context.allocator = mem.tracking_allocator(&ctx_track)
		fermat, fermat_err := big.internal_prime_fermat(a, b, arg_alloc)
		testing.expect(t, fermat && fermat_err == nil)
		lucas, lucas_err := big.internal_int_prime_strong_lucas_selfridge(a, arg_alloc)
		testing.expect(t, lucas && lucas_err == nil)
	}
	testing.expect_value(t, ctx_track.total_allocation_count, 0)
	testing.expect(t, arg_track.total_allocation_count > 0)
}

@(test)
test_fix_sqrtmod_prime_one_mod_four :: proc(t: ^testing.T) {
	n, p, r, root, other := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(n, p, r, root, other)

	Case :: struct {
		n, p, root: string,
	}
	cases := []Case{
		{"4",  "5",                                       "3"},
		{"1",  "5",                                       "1"},
		{"10", "13",                                      "7"},
		{"2",  "17",                                      "6"},
		{"3",  "1000000009",                              "742473516"},
		{"2",  "998244353",                               "882049182"},
		{"6",  "18446744073709551557",                    "14656824951921807778"},
		{"2",  "340282366920938463463374607431768211297", "173542385485469432711201807038307517008"},
		{"2",  "7",                                       "4"},
	}
	for c in cases {
		fix_set(t, n, c.n)
		fix_set(t, p, c.p)
		fix_set(t, root, c.root)
		big.sub(other, p, root)
		big.zero(r)
		err := big.internal_int_sqrtmod_prime(r, n, p)
		is_root, _  := big.equals(r, root)
		is_other, _ := big.equals(r, other)
		testing.expectf(t, err == nil && (is_root || is_other), "sqrtmod_prime(%v, %v) = %v; want %v or p - %v", c.n, c.p, err, c.root, c.root)
	}

	big.set(n, 5)
	big.set(p, 13)
	testing.expect_value(t, big.internal_int_sqrtmod_prime(r, n, p), big.Error.Invalid_Argument)
}

@(test)
test_fix_next_prime_sieve :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	Case :: struct {
		n:     string,
		bbs:   bool,
		prime: string,
	}
	cases := []Case{
		{"1618",                      false, "1619"},
		{"1619",                      false, "1621"},
		{"1637",                      false, "1657"},
		{"1627",                      true,  "1663"},
		{"2600000",                   false, "2600011"},
		{"36275199311",               true,  "36275199431"},
		{"1000000000000000000000000", false, "1000000000000000000000007"},
	}
	for c in cases {
		fix_set(t, a, c.n)
		testing.expectf(t, big.internal_int_prime_next_prime(a, -1, c.bbs) == nil, "next_prime(%v, bbs = %v) failed", c.n, c.bbs)
		fix_expect(t, a, c.prime)
	}
}

@(test)
test_fix_random_prime_size_and_flags :: proc(t: ^testing.T) {
	a, h := &big.Int{}, &big.Int{}
	defer big.destroy(a, h)

	Case :: struct {
		bits:   int,
		flags:  big.Primality_Flags,
		rounds: int,
	}
	cases := []Case{
		{ 2, {},                64},
		{ 2, {.Blum_Blum_Shub}, 64},
		{ 2, {.Second_MSB_On},  64},
		{ 3, {.Second_MSB_On},  64},
		{10, {.Second_MSB_On},  64},
		{16, {},                64},
		{32, {},                16},
		{63, {},                16},
		{64, {.Blum_Blum_Shub}, 16},
		{65, {.Second_MSB_On},  16},
		{64, {.Safe},            4},
	}
	for c in cases {
		for _ in 0..<c.rounds {
			big.set(a, -5)
			trials := 0 if c.bits == 32 else -1
			testing.expect_value(t, big.internal_random_prime(a, c.bits, trials, c.flags), nil)
			testing.expect_value(t, big.internal_count_bits(a), c.bits)
			testing.expect(t, !big.internal_is_negative(a))
			if .Blum_Blum_Shub in c.flags || .Safe in c.flags {
				testing.expect_value(t, a.digit[0] & 3, 3)
			}
			if .Second_MSB_On in c.flags {
				bit, _ := big.internal_int_bitfield_extract_bool(a, c.bits - 2)
				testing.expect(t, bit)
			}
			is_prime, err := big.internal_int_is_prime(a)
			testing.expect(t, is_prime && err == nil)
			if .Safe in c.flags {
				big.sub(h, a, 1)
				big.shr(h, h, 1)
				is_prime, err = big.internal_int_is_prime(h)
				testing.expect(t, is_prime && err == nil)
			}
			if testing.failed(t) {
				return
			}
		}
	}
}

@(test)
test_fix_choose_k_out_of_range :: proc(t: ^testing.T) {
	x := &big.Int{}
	defer big.destroy(x)

	testing.expect_value(t, big.choose(x, 5, -1), nil)
	fix_expect(t, x, "0")

	testing.expect_value(t, big.choose(x, 5, min(int)), nil)
	fix_expect(t, x, "0")

	testing.expect_value(t, big.choose(x, 5, 6), nil)
	fix_expect(t, x, "0")

	testing.expect_value(t, big.choose(x, 100, 30), nil)
	fix_expect(t, x, "29372339821610944823963760")
}

@(test)
test_fix_is_power_of_two :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	Case :: struct {
		a:    string,
		pow2: bool,
	}
	cases := []Case{
		{"0",                                                             false},
		{"1",                                                             true},
		{"-1",                                                            false},
		{"-4",                                                            false},
		{"-9223372036854775808",                                          false},
		{"212676479325586539664609129644855132160",                       false},
		{"9223372036854775808",                                           true},
		{"1606938044258990275541962092341162602522202993782792835301376", true},
	}
	for c in cases {
		fix_set(t, a, c.a)
		pow2, err := big.is_power_of_two(a)
		testing.expectf(t, pow2 == c.pow2 && err == nil, "is_power_of_two(%v) = %v, %v", c.a, pow2, err)
	}

	testing.expect(t, !big.platform_int_is_power_of_two(min(int)))
	testing.expect(t, !big.platform_int_is_power_of_two(0))
	testing.expect(t, !big.platform_int_is_power_of_two(-2))
	testing.expect(t, big.platform_int_is_power_of_two(1))
	testing.expect(t, big.platform_int_is_power_of_two(1 << 20))
}

@(test)
test_fix_mod_digit_floored :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	Case :: struct {
		a:   string,
		d:   big.DIGIT,
		rem: big.DIGIT,
	}
	cases := []Case{
		{"7",                     3,                    1},
		{"-7",                    3,                    2},
		{"-6",                    3,                    0},
		{"-1",                    max(big.DIGIT),       max(big.DIGIT) - 1},
		{"-18446744073709551616", 7,                    5},
		{"-36893488147419103232", 9223372036854775807,  9223372036854775803},
	}
	for c in cases {
		fix_set(t, a, c.a)
		rem, err := big.mod(a, c.d)
		testing.expectf(t, rem == c.rem && err == nil, "mod(%v, %v) = %v, %v; want %v", c.a, c.d, rem, err, c.rem)
	}

	z := &big.Int{}
	defer big.destroy(z)
	rem, err := big.int_mod_digit(z, 3)
	testing.expectf(t, rem == 0 && err == nil, "mod(zero value, 3) = %v, %v", rem, err)
}

@(test)
test_fix_public_immutable_dest :: proc(t: ^testing.T) {
	a, b, m, x := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(a, b, m, x)

	fix_set(t, a, "12345")
	fix_set(t, b, "678")
	fix_set(t, m, "1009")
	fix_set(t, x, "1")
	x.flags = {.Immutable}

	IMM :: big.Error.Assignment_To_Immutable
	testing.expect_value(t, big.add(x, a, b), IMM)
	testing.expect_value(t, big.add(x, a, big.DIGIT(5)), IMM)
	testing.expect_value(t, big.sub(x, a, b), IMM)
	testing.expect_value(t, big.sub(x, a, big.DIGIT(5)), IMM)
	testing.expect_value(t, big.halve(x, a), IMM)
	testing.expect_value(t, big.halve(x, x), IMM)
	testing.expect_value(t, big.double(x, a), IMM)
	testing.expect_value(t, big.double(x, x), IMM)
	testing.expect_value(t, big.mul(x, a, big.DIGIT(7)), IMM)
	testing.expect_value(t, big.mul(x, a, b), IMM)
	testing.expect_value(t, big.sqr(x, a), IMM)
	testing.expect_value(t, big.int_divmod(x, nil, a, b), IMM)
	testing.expect_value(t, big.int_divmod(nil, x, a, b), IMM)
	_, err := big.divmod(x, a, big.DIGIT(7))
	testing.expect_value(t, err, IMM)
	testing.expect_value(t, big.div(x, a, b), IMM)
	testing.expect_value(t, big.div(x, a, big.DIGIT(7)), IMM)
	testing.expect_value(t, big.mod(x, a, b), IMM)
	testing.expect_value(t, big.addmod(x, a, b, m), IMM)
	testing.expect_value(t, big.submod(x, a, b, m), IMM)
	testing.expect_value(t, big.mulmod(x, a, b, m), IMM)
	testing.expect_value(t, big.sqrmod(x, a, m), IMM)
	testing.expect_value(t, big.factorial(x, 5), IMM)
	testing.expect_value(t, big.choose(x, 5, 2), IMM)
	testing.expect_value(t, big.choose(x, 5, 6), IMM)
	testing.expect_value(t, big.gcd_lcm(x, nil, a, b), IMM)
	testing.expect_value(t, big.gcd_lcm(nil, x, a, b), IMM)
	testing.expect_value(t, big.gcd(x, a, b), IMM)
	testing.expect_value(t, big.lcm(x, a, b), IMM)
	testing.expect_value(t, big.mod_bits(x, a, 3), IMM)
	testing.expect_value(t, big.pow(x, a, 2), IMM)
	testing.expect_value(t, big.int_pow_int(x, 3, 2), IMM)
	testing.expect_value(t, big.sqrt(x, a), IMM)
	testing.expect_value(t, big.root_n(x, a, 3), IMM)

	x.flags = {}
	fix_expect(t, x, "1")
}

@(test)
test_fix_logical_immutable_dest :: proc(t: ^testing.T) {
	a, b, q, x := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(a, b, q, x)

	fix_set(t, a, "12345")
	fix_set(t, b, "-678")
	fix_set(t, x, "1")
	x.flags = {.Immutable}

	IMM :: big.Error.Assignment_To_Immutable
	testing.expect_value(t, big.bit_and(x, a, b), IMM)
	testing.expect_value(t, big.bit_and(x, x, a), IMM)
	testing.expect_value(t, big.bit_or(x, a, b), IMM)
	testing.expect_value(t, big.bit_or(x, x, a), IMM)
	testing.expect_value(t, big.bit_xor(x, a, b), IMM)
	testing.expect_value(t, big.bit_xor(x, x, a), IMM)
	testing.expect_value(t, big.bit_complement(x, a), IMM)
	testing.expect_value(t, big.bit_complement(x, x), IMM)
	testing.expect_value(t, big.shrmod(x, nil, a, 3), IMM)
	testing.expect_value(t, big.shrmod(q, x, a, 3), IMM)
	testing.expect_value(t, big.shr(x, a, 1), IMM)
	testing.expect_value(t, big.shr(x, x, 1), IMM)
	testing.expect_value(t, big.shr_signed(x, b, 1), IMM)
	testing.expect_value(t, big.shr_signed(x, x, 1), IMM)
	testing.expect_value(t, big.shl(x, a, 1), IMM)
	testing.expect_value(t, big.shl(x, x, 1), IMM)

	x.flags = {}
	fix_expect(t, x, "1")
}

@(test)
test_fix_to_bytes_and_copy_digits_stay_below_used :: proc(t: ^testing.T) {
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

	buf: [24]u8
	testing.expect_value(t, big.int_to_bytes_big(b, buf[:]), nil)
	testing.expect_value(t, buf[0], 31)
	testing.expect_value(t, buf[23], 255)

	testing.expect_value(t, big.int_to_bytes_little(b, buf[:]), nil)
	testing.expect_value(t, buf[0], 255)
	testing.expect_value(t, buf[23], 31)

	e := &big.Int{}
	defer big.destroy(e)
	testing.expect_value(t, big.copy_digits(e, src, 1), nil)
	testing.expect_value(t, e.digit[0], big._MASK)
}

@(test)
test_fix_minus_inf :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	testing.expect_value(t, big.minus_inf(a), nil)
	testing.expect_value(t, a.sign, big.Sign.Negative)
	testing.expect_value(t, a.flags, big.Flags{.Inf})

	big.set(a, 5)
	testing.expect_value(t, big.int_minus_inf(a), nil)
	testing.expect_value(t, a.sign, big.Sign.Negative)
	testing.expect_value(t, a.flags, big.Flags{.Inf})
}

@(test)
test_fix_swap_immutable_asserts :: proc(t: ^testing.T) {
	storage: [1024]byte
	arena: mem.Arena
	mem.arena_init(&arena, storage[:])
	context.allocator = mem.arena_allocator(&arena)

	c, x := &big.Int{}, &big.Int{}
	big.set(c, 1)
	c.flags = {.Immutable}
	big.set(x, 6)
	testing.expect_assert(t, "Assignment to immutable")
	big.swap(x, c)
}

@(test)
test_fix_to_bytes_fills_buffer :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	Case :: struct {
		value:  string,
		little: bool,
		bytes:  []u8,
	}
	cases := []Case{
		{"-1",                              true,  {255, 255}},
		{"-1",                              false, {255, 255, 255, 255}},
		{"-128",                            true,  {128, 255, 255, 255}},
		{"-256",                            true,  {0, 255, 255}},
		{"-256",                            false, {255, 255, 0}},
		{"-257",                            false, {255, 255, 255, 254, 255}},
		{"-18446744073709551616",           false, {255, 255, 0, 0, 0, 0, 0, 0, 0, 0}},
		{"-123456789012345678901234567890", false, {255, 255, 255, 254, 113, 22, 240, 9, 60, 140, 31, 17, 177, 192, 245, 46}},
		{"5",                               true,  {5, 0, 0, 0}},
		{"5",                               false, {0, 0, 0, 5}},
	}
	for c in cases {
		fix_set(t, a, c.value)
		buf := make([]u8, len(c.bytes))
		defer delete(buf)
		for &v in buf {
			v = 170
		}
		err: big.Error
		if c.little {
			err = big.int_to_bytes_little_python(a, buf, true)
		} else {
			err = big.int_to_bytes_big_python(a, buf, true)
		}
		testing.expect_value(t, err, nil)
		testing.expectf(t, slice.equal(buf, c.bytes), "to_bytes_python(%v, little = %v) = %v; want %v", c.value, c.little, buf, c.bytes)
	}

	big.set(a, 5)
	buf: [4]u8 = {170, 170, 170, 170}
	testing.expect_value(t, big.int_to_bytes_little(a, buf[:]), nil)
	testing.expect_value(t, buf, [4]u8{5, 0, 0, 0})

	buf = {170, 170, 170, 170}
	testing.expect_value(t, big.int_to_bytes_big(a, buf[:]), nil)
	testing.expect_value(t, buf, [4]u8{0, 0, 0, 5})

	big.set(a, -5)
	buf = {170, 170, 170, 170}
	testing.expect_value(t, big.int_to_bytes_big(a, buf[:], true), nil)
	testing.expect_value(t, buf, [4]u8{1, 0, 0, 5})
}

@(test)
test_fix_from_bytes_python_signed :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	Case :: struct {
		bytes:  []u8,
		little: bool,
		value:  string,
	}
	cases := []Case{
		{{128},           false, "-128"},
		{{127},           false, "127"},
		{{1},             true,  "1"},
		{{255},           false, "-1"},
		{{1, 0},          false, "256"},
		{{255, 0},        false, "-256"},
		{{128, 0},        false, "-32768"},
		{{128, 0, 0},     false, "-8388608"},
		{{255, 255, 254}, true,  "-65537"},
		{{0, 0, 128},     true,  "-8388608"},
		{{128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, false, "-3138550867693340381917894711603833208051177722232017256448"},
		{{127, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255}, false, "3138550867693340381917894711603833208051177722232017256447"},
	}
	for c in cases {
		err: big.Error
		if c.little {
			err = big.int_from_bytes_little_python(a, c.bytes, true)
		} else {
			err = big.int_from_bytes_big_python(a, c.bytes, true)
		}
		testing.expect_value(t, err, nil)
		fix_expect(t, a, c.value)
	}
}

@(test)
test_fix_from_bytes_empty :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	for signed in ([]bool{false, true}) {
		big.set(a, -7)
		testing.expect_value(t, big.int_from_bytes_big(a, nil, signed), nil)
		fix_expect(t, a, "0")
		big.set(a, -7)
		testing.expect_value(t, big.int_from_bytes_little(a, nil, signed), nil)
		fix_expect(t, a, "0")
		big.set(a, -7)
		testing.expect_value(t, big.int_from_bytes_big_python(a, nil, signed), nil)
		fix_expect(t, a, "0")
		big.set(a, -7)
		testing.expect_value(t, big.int_from_bytes_little_python(a, nil, signed), nil)
		fix_expect(t, a, "0")
	}
}

@(test)
test_fix_from_bytes_overflow :: proc(t: ^testing.T) {
	when size_of(int) == 4 {
		buf, alloc_err := make([]u8, 1 << 28)
		if !testing.expect_value(t, alloc_err, nil) {
			return
		}
		defer delete(buf)

		a := &big.Int{}
		defer big.destroy(a)

		for signed in ([]bool{false, true}) {
			testing.expect_value(t, big.int_from_bytes_big(a, buf, signed), big.Error.Integer_Overflow)
			testing.expect_value(t, big.int_from_bytes_little(a, buf, signed), big.Error.Integer_Overflow)
			testing.expect_value(t, big.int_from_bytes_big_python(a, buf, signed), big.Error.Integer_Overflow)
			testing.expect_value(t, big.int_from_bytes_little_python(a, buf, signed), big.Error.Integer_Overflow)
		}
	}
}

@(test)
test_fix_bytes_round_trip :: proc(t: ^testing.T) {
	a, b := &big.Int{}, &big.Int{}
	defer big.destroy(a, b)

	sizes := []int{1, 7, 8, 9, 55, 56, 57, 62, 63, 64, 65, 118, 119, 120, 126, 127, 128, 189, 190, 500, 1000}
	for bits in sizes {
		for delta in -1..=1 {
			for negative in ([]bool{false, true}) {
				big.power_of_two(a, bits)
				if delta < 0 {
					big.sub(a, a, big.DIGIT(1))
				} else if delta > 0 {
					big.add(a, a, big.DIGIT(1))
				}
				if negative {
					big.neg(a, a)
				}

				for signed in ([]bool{false, true}) {
					if negative && !signed {
						continue
					}
					size, _ := big.int_to_bytes_size(a, signed)
					buf := make([]u8, size)
					defer delete(buf)

					for format in 0..<4 {
						err: big.Error
						switch format {
						case 0:
							testing.expect_value(t, big.int_to_bytes_big(a, buf, signed), nil)
							err = big.int_from_bytes_big(b, buf, signed)
						case 1:
							testing.expect_value(t, big.int_to_bytes_little(a, buf, signed), nil)
							err = big.int_from_bytes_little(b, buf, signed)
						case 2:
							testing.expect_value(t, big.int_to_bytes_big_python(a, buf, signed), nil)
							err = big.int_from_bytes_big_python(b, buf, signed)
						case 3:
							testing.expect_value(t, big.int_to_bytes_little_python(a, buf, signed), nil)
							err = big.int_from_bytes_little_python(b, buf, signed)
						}
						same, _ := big.equals(a, b)
						if !testing.expectf(t, err == nil && same, "2^%v%+v negative = %v signed = %v format %v: round trip failed: %v", bits, delta, negative, signed, format, err) {
							return
						}
					}
				}
			}
		}
	}
}

@(test)
test_fix_helpers_immutable_dest :: proc(t: ^testing.T) {
	x := &big.Int{}
	defer big.destroy(x)

	fix_set(t, x, "1")
	x.flags = {.Immutable}
	bytes := [?]u8{18, 52}

	IMM :: big.Error.Assignment_To_Immutable
	testing.expect_value(t, big.clear(x), IMM)
	testing.expect_value(t, big.zero(x), IMM)
	testing.expect_value(t, big.power_of_two(x, 5), IMM)
	testing.expect_value(t, big.random(x, 30), IMM)
	testing.expect_value(t, big.init_multi(x), IMM)
	testing.expect_value(t, big.int_from_bytes_big(x, bytes[:]), IMM)
	testing.expect_value(t, big.int_from_bytes_little(x, bytes[:]), IMM)
	testing.expect_value(t, big.int_from_bytes_big_python(x, bytes[:], true), IMM)
	testing.expect_value(t, big.int_from_bytes_little_python(x, bytes[:], true), IMM)
	testing.expect_value(t, big.int_from_bytes_big(x, nil), IMM)

	testing.expect_value(t, x.flags, big.Flags{.Immutable})
	x.flags = {}
	fix_expect(t, x, "1")
}

@(test)
test_fix_combinatorics_edges :: proc(t: ^testing.T) {
	Proc :: enum { Perm, Comb, Comb_Rep, Perm_Rep }
	Case :: struct {
		p:        Proc,
		n, r:     int,
		err:      big.Error,
		expected: string,
	}
	cases := [?]Case{
		{.Perm,      5,         2,         nil,               "20"},
		{.Perm,      5,         0,         nil,               "1"},
		{.Perm,      5,         5,         nil,               "120"},
		{.Perm,      0,         0,         nil,               "1"},
		{.Perm,      20,        10,        nil,               "670442572800"},
		{.Perm,      3,         5,         nil,               "0"},
		{.Perm,      0,         3,         nil,               "0"},
		{.Perm,      5,         2_000_000, nil,               "0"},
		{.Perm,      5,         -1,        .Invalid_Argument, "123"},
		{.Perm,      -1,        0,         .Invalid_Argument, "123"},
		{.Perm,      min(int),  min(int),  .Invalid_Argument, "123"},
		{.Comb,      5,         2,         nil,               "10"},
		{.Comb,      0,         0,         nil,               "1"},
		{.Comb,      20,        10,        nil,               "184756"},
		{.Comb,      3,         5,         nil,               "0"},
		{.Comb,      2_000_000, 2_000_001, nil,               "0"},
		{.Comb,      5,         -1,        .Invalid_Argument, "123"},
		{.Comb,      -1,        0,         .Invalid_Argument, "123"},
		{.Comb_Rep,  3,         2,         nil,               "6"},
		{.Comb_Rep,  3,         0,         nil,               "1"},
		{.Comb_Rep,  0,         0,         nil,               "1"},
		{.Comb_Rep,  0,         3,         nil,               "0"},
		{.Comb_Rep,  1,         5,         nil,               "1"},
		{.Comb_Rep,  20,        10,        nil,               "20030010"},
		{.Comb_Rep,  5,         -1,        .Invalid_Argument, "123"},
		{.Comb_Rep,  -1,        2,         .Invalid_Argument, "123"},
		{.Comb_Rep,  -1,        0,         .Invalid_Argument, "123"},
		{.Perm_Rep,  2,         10,        nil,               "1024"},
		{.Perm_Rep,  0,         0,         nil,               "1"},
		{.Perm_Rep,  0,         3,         nil,               "0"},
		{.Perm_Rep,  20,        10,        nil,               "10240000000000"},
		{.Perm_Rep,  5,         -1,        .Invalid_Argument, "123"},
		{.Perm_Rep,  -3,        2,         .Invalid_Argument, "123"},
	}
	for c in cases {
		x := &big.Int{}
		defer big.destroy(x)

		fix_set(t, x, "123")
		err: big.Error
		switch c.p {
		case .Perm:     err = big.permutations_without_repetition(x, c.n, c.r)
		case .Comb:     err = big.combinations_without_repetition(x, c.n, c.r)
		case .Comb_Rep: err = big.combinations_with_repetition(x, c.n, c.r)
		case .Perm_Rep: err = big.permutations_with_repetition(x, c.n, c.r)
		}
		testing.expectf(t, err == c.err, "%v(%v, %v): err %v, expected %v", c.p, c.n, c.r, err, c.err)
		fix_expect(t, x, c.expected)
	}
}

@(test)
test_fix_combinatorics_immutable_dest :: proc(t: ^testing.T) {
	x := &big.Int{}
	defer big.destroy(x)

	fix_set(t, x, "7")
	x.flags = {.Immutable}

	IMM :: big.Error.Assignment_To_Immutable
	args := [?][2]int{{5, 2}, {5, 5}, {3, 5}, {0, 0}, {0, 3}}
	for a in args {
		testing.expect_value(t, big.permutations_without_repetition(x, a[0], a[1]), IMM)
		testing.expect_value(t, big.combinations_without_repetition(x, a[0], a[1]), IMM)
		testing.expect_value(t, big.combinations_with_repetition(x, a[0], a[1]), IMM)
		testing.expect_value(t, big.permutations_with_repetition(x, a[0], a[1]), IMM)
	}

	testing.expect_value(t, x.flags, big.Flags{.Immutable})
	x.flags = {}
	fix_expect(t, x, "7")
}

@(test)
test_fix_itoa_negative_no_leading_zero :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	Case :: struct {
		hex:      string,
		radix:    i8,
		expected: string,
	}
	cases := [?]Case{
		{"-40000000000000000000000000000001", 10, "-85070591730234615865843651857942052865"},
		{"-40000000000000000000000000000001", 3,  "-12011212011000120022000012112210022201211110120101000022212110022021120100011002"},
		{"-43B55E9784AC7DA10895EBA000000000", 10, "-90000000000000000000000000000000000000"},
	}
	for c in cases {
		testing.expect_value(t, big.atoi(a, c.hex, 16), nil)

		s, err := big.itoa(a, c.radix)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, s, c.expected)
		delete(s)

		cs, cerr := big.int_itoa_cstring(a, c.radix)
		testing.expect_value(t, cerr, nil)
		testing.expect_value(t, string(cs), c.expected)
		delete(cs)
	}
}

@(test)
test_fix_itoa_raw_larger_buffer :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	Case :: struct {
		decimal:  string,
		radix:    i8,
		expected: string,
	}
	cases := [?]Case{
		{"0",                                         10, "0"},
		{"5",                                         10, "5"},
		{"-123",                                      16, "-7B"},
		{"18446744073709551616",                      16, "10000000000000000"},
		{"18446744073709551616",                      7,  "45012021522523134134602"},
		{"1361129467683753853853498429727072845825",  10, "1361129467683753853853498429727072845825"},
		{"-1361129467683753853853498429727072845825", 16, "-400000000000000000000000000000001"},
		{"-1361129467683753853853498429727072845825", 7,  "-15501652041535445035004034651000412123144600523"},
		{"-9999999999999999999999999999999999999999", 10, "-9999999999999999999999999999999999999999"},
	}
	for c in cases {
		fix_set(t, a, c.decimal)

		buf: [80]u8
		written, err := big.int_itoa_raw(a, c.radix, buf[:])
		testing.expect_value(t, err, nil)
		testing.expect_value(t, string(buf[:written]), c.expected)

		zbuf: [80]u8
		written, err = big.int_itoa_raw(a, c.radix, zbuf[:], zero_terminate = true)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, written, len(c.expected) + 1)
		testing.expect_value(t, string(zbuf[:len(c.expected)]), c.expected)
		testing.expect_value(t, zbuf[len(c.expected)], 0)
	}
}

@(test)
test_fix_itoa_negative_zero :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	fix_set(t, a, "0")
	a.sign = .Negative

	size, size_err := big.radix_size(a, 10)
	testing.expect_value(t, size_err, nil)

	s, err := big.itoa(a, 10)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, s, "0")
	testing.expect_value(t, len(s), size)
	delete(s)
}

@(private="file")
fix_radix_size_with_context :: proc(a: ^big.Int, ctx, arg: mem.Allocator) -> (size: int, err: big.Error) {
	context.allocator = ctx
	return big.radix_size(a, 10, false, arg)
}

@(test)
test_fix_radix_size_allocator :: proc(t: ^testing.T) {
	ctx_track, arg_track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&ctx_track, context.allocator)
	defer mem.tracking_allocator_destroy(&ctx_track)
	mem.tracking_allocator_init(&arg_track, context.allocator)
	defer mem.tracking_allocator_destroy(&arg_track)
	ctx := mem.tracking_allocator(&ctx_track)
	arg := mem.tracking_allocator(&arg_track)

	a := &big.Int{}
	size, err := fix_radix_size_with_context(a, ctx, arg)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, size, 1)

	testing.expect_value(t, big.int_set_from_integer(a, 1234567, allocator = arg), nil)
	size, err = fix_radix_size_with_context(a, ctx, arg)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, size, 7)

	testing.expect_value(t, ctx_track.total_allocation_count, 0)
	big.destroy(a)
}

@(test)
test_fix_atoi_immutable_and_flags :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	fix_set(t, a, "7")
	a.flags = {.Immutable}
	testing.expect_value(t, big.atoi(a, "12345", 10), big.Error.Assignment_To_Immutable)
	testing.expect_value(t, big.atoi(big.INT_ONE, "5", 10), big.Error.Assignment_To_Immutable)
	a.flags = {}
	fix_expect(t, a, "7")
	fix_expect(t, big.INT_ONE, "1")

	testing.expect_value(t, big.nan(a), nil)
	testing.expect_value(t, big.atoi(a, "5", 10), nil)
	testing.expect_value(t, a.flags, big.Flags{})
	fix_expect(t, a, "5")
}

@(private="file")
Fix_Fail_State :: struct {
	backing: mem.Allocator,
	count:   int,
	fail_at: int,
}

@(private="file")
fix_fail_proc :: proc(data: rawptr, mode: mem.Allocator_Mode, size, alignment: int, old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, mem.Allocator_Error) {
	st := (^Fix_Fail_State)(data)
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed, .Resize, .Resize_Non_Zeroed:
		st.count += 1
		if st.count == st.fail_at {
			return nil, .Out_Of_Memory
		}
	}
	return st.backing.procedure(st.backing.data, mode, size, alignment, old_memory, old_size, loc)
}

@(test)
test_fix_itoa_allocators :: proc(t: ^testing.T) {
	expected := "-9999999999999999999999999999999999999999"
	failed := 0
	for fail_at in 1..=12 {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		base := mem.tracking_allocator(&track)
		st := Fix_Fail_State{backing = base, fail_at = fail_at}
		fa := mem.Allocator{procedure = fix_fail_proc, data = &st}

		a := &big.Int{}
		testing.expect_value(t, big.int_atoi(a, expected, 10, nil, base), nil)

		s, err := big.int_itoa_string(a, 10, false, fa)
		if err == nil {
			testing.expect_value(t, s, expected)
			delete(s, fa)
		} else {
			testing.expect_value(t, s, "")
			failed += 1
		}

		big.destroy(a)
		testing.expectf(t, len(track.allocation_map) == 0, "allocation %v failed: %v allocations leaked", fail_at, len(track.allocation_map))
		mem.tracking_allocator_destroy(&track)
	}
	testing.expect(t, failed > 1)

	str_track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&str_track, context.allocator)
	defer mem.tracking_allocator_destroy(&str_track)
	str_alloc := mem.tracking_allocator(&str_track)

	z := &big.Int{}
	defer big.destroy(z)

	s, err := big.int_itoa_string(z, 10, false, str_alloc)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, s, "0")
	delete(s, str_alloc)

	cs, cerr := big.int_itoa_cstring(z, 10, str_alloc)
	testing.expect_value(t, cerr, nil)
	testing.expect_value(t, string(cs), "0")
	delete(cs, str_alloc)

	testing.expect_value(t, len(str_track.allocation_map), 0)
}

@(test)
test_fix_unpack_overwrites_destination :: proc(t: ^testing.T) {
	x := &big.Int{}
	defer big.destroy(x)
	buf := [?]u8{1, 2}

	fix_set(t, x, "-5")
	testing.expect_value(t, big.internal_int_unpack(x, buf[:], 0, .LSB_First), nil)
	fix_expect(t, x, "513")

	fix_set(t, x, "5")
	testing.expect_value(t, big.internal_int_unpack(x, buf[:], 0, .MSB_First), nil)
	fix_expect(t, x, "258")

	testing.expect_value(t, big.nan(x), nil)
	testing.expect_value(t, big.internal_int_unpack(x, buf[:], 0, .LSB_First), nil)
	testing.expect_value(t, x.flags, big.Flags{})
	fix_expect(t, x, "513")
}

@(test)
test_fix_pack_u128 :: proc(t: ^testing.T) {
	x, y := &big.Int{}, &big.Int{}
	defer big.destroy(x, y)
	testing.expect_value(t, big.atoi(x, "123456789ABCDEF0123456789ABCDEF0123456789ABCDEF", 16), nil)

	words: [2]u128
	testing.expect_value(t, big.internal_int_pack_count(x, u128, 0), 2)
	written, err := big.internal_int_pack(x, words[:], 0, .LSB_First)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, written, 2)
	testing.expect_value(t, words[0], 0x0123456789abcdef0123456789abcdef)
	testing.expect_value(t, words[1], 0x123456789abcdef)
	testing.expect_value(t, big.internal_int_unpack(y, words[:], 0, .LSB_First), nil)
	equal, _ := big.equals(x, y)
	testing.expect(t, equal)

	written, err = big.internal_int_pack(x, words[:], 1, .MSB_First)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, written, 2)
	testing.expect_value(t, words[0], 0x2468acf13579bde)
	testing.expect_value(t, words[1], 0x123456789abcdef0123456789abcdef)
	testing.expect_value(t, big.internal_int_unpack(y, words[:], 1, .MSB_First), nil)
	equal, _ = big.equals(x, y)
	testing.expect(t, equal)
}

@(test)
test_fix_clear_drops_nan_inf :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)
	bytes := [?]u8{1, 2}

	testing.expect_value(t, big.nan(a), nil)
	testing.expect_value(t, big.zero(a), nil)
	testing.expect_value(t, a.flags, big.Flags{})
	fix_expect(t, a, "0")

	testing.expect_value(t, big.inf(a), nil)
	testing.expect_value(t, big.int_from_bytes_big(a, bytes[:]), nil)
	testing.expect_value(t, a.flags, big.Flags{})
	fix_expect(t, a, "258")

	testing.expect_value(t, big.minus_inf(a), nil)
	testing.expect_value(t, big.int_from_bytes_little_python(a, bytes[:], true), nil)
	testing.expect_value(t, a.flags, big.Flags{})
	fix_expect(t, a, "513")

	testing.expect_value(t, big.nan(a), nil)
	testing.expect_value(t, big.int_from_bytes_big(a, nil), nil)
	testing.expect_value(t, a.flags, big.Flags{})
	fix_expect(t, a, "0")

	testing.expect_value(t, big.nan(a), nil)
	testing.expect_value(t, big.combinations_without_repetition(a, 3, 5), nil)
	testing.expect_value(t, a.flags, big.Flags{})
	fix_expect(t, a, "0")

	testing.expect_value(t, big.inf(a), nil)
	testing.expect_value(t, big.choose(a, 5, 6), nil)
	testing.expect_value(t, a.flags, big.Flags{})
	fix_expect(t, a, "0")

	fix_set(t, a, "7")
	a.flags = {.Immutable, .NaN, .Inf}
	testing.expect_value(t, big.internal_int_clear(a), nil)
	testing.expect_value(t, a.flags, big.Flags{.Immutable})
	a.flags = {}
	fix_expect(t, a, "0")
}

@(test)
test_fix_pack_unpack_zero :: proc(t: ^testing.T) {
	x := &big.Int{}
	defer big.destroy(x)

	fix_set(t, x, "0")
	testing.expect_value(t, big.internal_int_pack_count(x, u128, 0), 0)
	words: [1]u128
	written, err := big.internal_int_pack(x, words[:], 0, .LSB_First)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, written, 0)

	fix_set(t, x, "-5")
	testing.expect_value(t, big.internal_int_unpack(x, words[:written], 0, .LSB_First), nil)
	fix_expect(t, x, "0")

	bytes: []u8
	testing.expect_value(t, big.nan(x), nil)
	testing.expect_value(t, big.internal_int_unpack(x, bytes, 0, .MSB_First), nil)
	testing.expect_value(t, x.flags, big.Flags{})
	fix_expect(t, x, "0")
}

@(test)
test_fix_itoa_raw_small_buffer :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	Case :: struct {
		decimal:  string,
		radix:    i8,
		expected: string,
	}
	cases := [?]Case{
		{"0",                                         10, "0"},
		{"-0",                                        10, "0"},
		{"7",                                         10, "7"},
		{"-7",                                        10, "-7"},
		{"-123",                                      10, "-123"},
		{"18446744073709551616",                      10, "18446744073709551616"},
		{"-18446744073709551616",                     7,  "-45012021522523134134602"},
		{"-1361129467683753853853498429727072845825", 16, "-400000000000000000000000000000001"},
		{"1361129467683753853853498429727072845825",  32, "100000000000000000000000001"},
		{"1361129467683753853853498429727072845825",  10, "1361129467683753853853498429727072845825"},
		{"-1361129467683753853853498429727072845825", 7,  "-15501652041535445035004034651000412123144600523"},
	}
	for c in cases {
		fix_set(t, a, c.decimal)
		if c.decimal == "-0" {
			a.sign = .Negative
		}

		for zero_terminate in ([?]bool{false, true}) {
			exact := len(c.expected) + (1 if zero_terminate else 0)
			storage: [64]u8

			for l in 0..<exact {
				written, err := big.int_itoa_raw(a, c.radix, storage[:l], l, zero_terminate)
				testing.expectf(t, err == .Buffer_Overflow && written == 0, "%v radix %v, %v bytes, size passed: %v, %v", c.decimal, c.radix, l, written, err)

				written, err = big.int_itoa_raw(a, c.radix, storage[:l], -1, zero_terminate)
				testing.expectf(t, err == .Buffer_Overflow && written == 0, "%v radix %v, %v bytes: %v, %v", c.decimal, c.radix, l, written, err)
			}

			written, err := big.int_itoa_raw(a, c.radix, storage[:exact], exact, zero_terminate)
			testing.expect_value(t, err, nil)
			testing.expect_value(t, written, exact)
			testing.expect_value(t, string(storage[:len(c.expected)]), c.expected)
			if zero_terminate {
				testing.expect_value(t, storage[len(c.expected)], 0)
			}
		}
	}
}

@(private="file")
FIX_RAT_X_N :: "1556BC09CB91215785D99773382DD301C8A91AFA5C7623C4DD"
@(private="file")
FIX_RAT_X_D :: "8FFA5FC6A29D1C6231C6A83B6087BE1D408D4D4BF75093B433"
@(private="file")
FIX_RAT_Y_N :: "748F79FFB25306DDF2B2AEADD8B86A08"
@(private="file")
FIX_RAT_Y_D :: "65545AFEFEC7612E319A2FBAF253374D802EF90D40B086AD6A0D"

@(private="file")
fix_rat_expect :: proc(t: ^testing.T, r: ^big.Rat, num, den: string, radix := i8(10), loc := #caller_location) -> bool {
	a, _ := big.itoa(&r.a, radix)
	b, _ := big.itoa(&r.b, radix)
	defer delete(a)
	defer delete(b)
	return testing.expectf(t, a == num && b == den, "expected %s/%s, got %s/%s", num, den, a, b, loc = loc)
}

@(private="file")
fix_rat_set_hex :: proc(r: ^big.Rat, num, den: string) {
	big.destroy(r)
	big.atoi(&r.a, num, 16)
	big.atoi(&r.b, den, 16)
}

@(test)
test_fix_rat_set_frac_int_aliasing :: proc(t: ^testing.T) {
	x: big.Rat
	defer big.destroy(&x)
	n: big.Int
	defer big.destroy(&n)
	fix_set(t, &n, "5")

	testing.expect_value(t, big.rat_set_frac_digit(&x, 2, 3), nil)
	testing.expect_value(t, big.rat_set_frac_int(&x, &x.b, &x.a), nil)
	fix_rat_expect(t, &x, "3", "2")

	testing.expect_value(t, big.rat_set_frac_digit(&x, 2, 3), nil)
	testing.expect_value(t, big.rat_set_frac_int(&x, &n, &x.a), nil)
	fix_rat_expect(t, &x, "5", "2")

	testing.expect_value(t, big.rat_set_frac_digit(&x, 2, 3), nil)
	testing.expect_value(t, big.rat_set_frac_int(&x, &x.a, &x.a), nil)
	fix_rat_expect(t, &x, "1", "1")

	testing.expect_value(t, big.rat_set_frac_digit(&x, 2, 3), nil)
	testing.expect_value(t, big.rat_set_frac_int(&x, &x.b, &n), nil)
	fix_rat_expect(t, &x, "3", "5")

	testing.expect_value(t, big.rat_set_frac_digit(&x, 2, 3), nil)
	testing.expect_value(t, big.rat_set_frac_int(&x, &x.b, &x.b), nil)
	fix_rat_expect(t, &x, "1", "1")

	big.destroy(&x)
	fix_set(t, &x.a, "-340282366920938463463374607431768211457")
	fix_set(t, &x.b, "18446744073709551617")
	testing.expect_value(t, big.rat_set_frac_int(&x, &x.b, &x.a), nil)
	fix_rat_expect(t, &x, "-18446744073709551617", "340282366920938463463374607431768211457")

	fix_set(t, &x.a, "6")
	fix_set(t, &x.b, "35")
	testing.expect_value(t, big.rat_set_frac_int(&x, &n, &x.a), nil)
	fix_rat_expect(t, &x, "5", "6")
}

@(private="file")
fix_rat_set_one_over_power_of_two :: proc(t: ^testing.T, r: ^big.Rat, negative: bool, k: int) {
	big.destroy(r)
	fix_set(t, &r.a, "-1" if negative else "1")
	testing.expect_value(t, big.power_of_two(&r.b, k), nil)
}

@(test)
test_fix_rat_to_float_underflow_is_inexact :: proc(t: ^testing.T) {
	r: big.Rat
	defer big.destroy(&r)

	Case :: struct {
		negative: bool,
		k:        int,
		bits:     u64,
		exact:    bool,
	}
	f16_cases := [?]Case{
		{false, 24, 0x0001, true},
		{false, 25, 0x0000, false},
		{false, 30, 0x0000, false},
		{true,  30, 0x8000, false},
	}
	for c in f16_cases {
		fix_rat_set_one_over_power_of_two(t, &r, c.negative, c.k)
		f, exact, err := big.rat_to_f16(&r)
		testing.expect_value(t, err, nil)
		testing.expectf(t, u64(transmute(u16)f) == c.bits && exact == c.exact, "f16 1/2^%v: got %x %v", c.k, transmute(u16)f, exact)
	}
	f32_cases := [?]Case{
		{false, 149, 0x00000001, true},
		{false, 150, 0x00000000, false},
		{false, 200, 0x00000000, false},
		{true,  200, 0x80000000, false},
	}
	for c in f32_cases {
		fix_rat_set_one_over_power_of_two(t, &r, c.negative, c.k)
		f, exact, err := big.rat_to_f32(&r)
		testing.expect_value(t, err, nil)
		testing.expectf(t, u64(transmute(u32)f) == c.bits && exact == c.exact, "f32 1/2^%v: got %x %v", c.k, transmute(u32)f, exact)
	}
	f64_cases := [?]Case{
		{false, 1074, 0x0000000000000001, true},
		{false, 1075, 0x0000000000000000, false},
		{false, 1200, 0x0000000000000000, false},
		{true,  1200, 0x8000000000000000, false},
	}
	for c in f64_cases {
		fix_rat_set_one_over_power_of_two(t, &r, c.negative, c.k)
		f, exact, err := big.rat_to_f64(&r)
		testing.expect_value(t, err, nil)
		testing.expectf(t, transmute(u64)f == c.bits && exact == c.exact, "f64 1/2^%v: got %x %v", c.k, transmute(u64)f, exact)
	}
}

@(test)
test_fix_rat_immutable_dst :: proc(t: ^testing.T) {
	x, y, d: big.Rat
	defer big.destroy(&x, &y, &d)
	n, m: big.Int
	defer big.destroy(&n, &m)

	fix_rat_set_hex(&x, FIX_RAT_X_N, FIX_RAT_X_D)
	fix_rat_set_hex(&y, FIX_RAT_Y_N, FIX_RAT_Y_D)
	fix_set(t, &n, "7")
	fix_set(t, &m, "340282366920938463463374607431768211457")

	Op :: enum {
		Set_F64, Set_F32, Set_F16, Set_Frac_Digit, Set_Frac_Int, Set_Int, Set_Digit, Set_Rat, Set_U64, Set_I64,
		Copy, Abs, Neg, Add, Sub, Mul_Self, Div, Div_Dst_Y,
		Rat_Add_Int, Rat_Sub_Int, Rat_Mul_Int, Rat_Div_Int,
		Int_Add_Rat, Int_Sub_Rat, Int_Mul_Rat, Int_Div_Rat, Int_Div_Rat_Dst_Y,
	}
	for b_only in ([?]bool{false, true}) {
		for op in Op {
			fix_rat_set_hex(&d, FIX_RAT_Y_N, FIX_RAT_Y_D)
			d.a.flags = {} if b_only else {.Immutable}
			d.b.flags = {.Immutable}

			err: big.Error
			switch op {
			case .Set_F64:            err = big.rat_set_f64(&d, 0.5)
			case .Set_F32:            err = big.rat_set_f32(&d, 0.25)
			case .Set_F16:            err = big.rat_set_f16(&d, 0.75)
			case .Set_Frac_Digit:     err = big.rat_set_frac_digit(&d, 5, 11)
			case .Set_Frac_Int:       err = big.rat_set_frac_int(&d, &m, &n)
			case .Set_Int:            err = big.rat_set_int(&d, &m)
			case .Set_Digit:          err = big.rat_set_digit(&d, 9)
			case .Set_Rat:            err = big.rat_set_rat(&d, &x)
			case .Set_U64:            err = big.rat_set_u64(&d, 12345)
			case .Set_I64:            err = big.rat_set_i64(&d, -12345)
			case .Copy:               err = big.rat_copy(&d, &x)
			case .Abs:                err = big.rat_abs(&d, &x)
			case .Neg:                err = big.rat_neg(&d, &x)
			case .Add:                err = big.rat_add_rat(&d, &x, &y)
			case .Sub:                err = big.rat_sub_rat(&d, &x, &y)
			case .Mul_Self:           err = big.rat_mul_rat(&d, &d, &d)
			case .Div:                err = big.rat_div_rat(&d, &x, &y)
			case .Div_Dst_Y:          err = big.rat_div_rat(&d, &x, &d)
			case .Rat_Add_Int:        err = big.rat_add_int(&d, &x, &m)
			case .Rat_Sub_Int:        err = big.rat_sub_int(&d, &x, &m)
			case .Rat_Mul_Int:        err = big.rat_mul_int(&d, &x, &m)
			case .Rat_Div_Int:        err = big.rat_div_int(&d, &x, &m)
			case .Int_Add_Rat:        err = big.int_add_rat(&d, &m, &x)
			case .Int_Sub_Rat:        err = big.int_sub_rat(&d, &m, &x)
			case .Int_Mul_Rat:        err = big.int_mul_rat(&d, &m, &x)
			case .Int_Div_Rat:        err = big.int_div_rat(&d, &m, &x)
			case .Int_Div_Rat_Dst_Y:  err = big.int_div_rat(&d, &n, &d)
			}
			testing.expectf(t, err == .Assignment_To_Immutable, "%v (b only: %v): err = %v", op, b_only, err)
			testing.expectf(t, d.b.flags == {.Immutable}, "%v (b only: %v): b.flags = %v", op, b_only, d.b.flags)

			d.a.flags = {}
			d.b.flags = {}
			fix_rat_expect(t, &d, FIX_RAT_Y_N, FIX_RAT_Y_D, 16)
		}
	}
}

@(test)
test_fix_rat_swap_immutable_asserts :: proc(t: ^testing.T) {
	storage: [1024]byte
	arena: mem.Arena
	mem.arena_init(&arena, storage[:])
	context.allocator = mem.arena_allocator(&arena)

	c, x: big.Rat
	big.rat_set_frac_digit(&c, 1, 2)
	c.b.flags = {.Immutable}
	big.rat_set_frac_digit(&x, 3, 4)
	testing.expect_assert(t, "Assignment to immutable")
	big.swap(&x, &c)
}

@(test)
test_fix_rat_non_finite :: proc(t: ^testing.T) {
	pinf, ninf, nan, x, y, d, e: big.Rat
	defer big.destroy(&pinf, &ninf, &nan, &x, &y, &d, &e)
	n: big.Int
	defer big.destroy(&n)

	testing.expect_value(t, big.rat_set_f64(&pinf, math.inf_f64(1)), nil)
	testing.expect_value(t, big.rat_set_f64(&ninf, math.inf_f64(-1)), nil)
	testing.expect_value(t, big.rat_set_f64(&nan, math.nan_f64()), nil)
	fix_set(t, &n, "7")

	{
		f, exact, err := big.rat_to_f64(&pinf)
		testing.expectf(t, math.is_inf(f, 1) && !exact && err == nil, "to_f64(+Inf): %v %v %v", f, exact, err)
	}
	{
		f, exact, err := big.rat_to_f16(&ninf)
		testing.expectf(t, math.is_inf(f64(f), -1) && !exact && err == nil, "to_f16(-Inf): %v %v %v", f, exact, err)
	}
	{
		f, exact, err := big.rat_to_f32(&nan)
		testing.expectf(t, math.is_nan(f) && !exact && err == nil, "to_f32(NaN): %v %v %v", f, exact, err)
	}
	testing.expect(t, !big.rat_is_int(&pinf), "rat_is_int(+Inf)")
	testing.expect(t, !big.rat_is_int(&nan), "rat_is_int(NaN)")

	Op :: enum {
		Add_X, Add_Y, Sub_X, Sub_Y, Mul_X, Mul_Y, Div_X, Div_Y,
		Rat_Add_Int, Rat_Sub_Int, Rat_Mul_Int, Rat_Div_Int,
		Int_Add_Rat, Int_Sub_Rat, Int_Mul_Rat, Int_Div_Rat,
		Compare_X, Compare_Y, Is_Positive, Is_Negative, Is_Even, Is_Odd,
	}
	for v in ([?]^big.Rat{&pinf, &ninf, &nan}) {
		testing.expect_value(t, big.rat_set_frac_digit(&x, 5, 2), nil)
		for op in Op {
			testing.expect_value(t, big.rat_set_frac_digit(&d, 3, 4), nil)
			err: big.Error
			switch op {
			case .Add_X:       err = big.rat_add_rat(&d, v, &x)
			case .Add_Y:       err = big.rat_add_rat(&d, &x, v)
			case .Sub_X:       err = big.rat_sub_rat(&d, v, &x)
			case .Sub_Y:       err = big.rat_sub_rat(&d, &x, v)
			case .Mul_X:       err = big.rat_mul_rat(&d, v, &x)
			case .Mul_Y:       err = big.rat_mul_rat(&d, &x, v)
			case .Div_X:       err = big.rat_div_rat(&d, v, &x)
			case .Div_Y:       err = big.rat_div_rat(&d, &x, v)
			case .Rat_Add_Int: err = big.rat_add_int(&d, v, &n)
			case .Rat_Sub_Int: err = big.rat_sub_int(&d, v, &n)
			case .Rat_Mul_Int: err = big.rat_mul_int(&d, v, &n)
			case .Rat_Div_Int: err = big.rat_div_int(&d, v, &n)
			case .Int_Add_Rat: err = big.int_add_rat(&d, &n, v)
			case .Int_Sub_Rat: err = big.int_sub_rat(&d, &n, v)
			case .Int_Mul_Rat: err = big.int_mul_rat(&d, &n, v)
			case .Int_Div_Rat: err = big.int_div_rat(&d, &n, v)
			case .Compare_X:   _, err = big.rat_compare(v, &x)
			case .Compare_Y:   _, err = big.rat_compare(&x, v)
			case .Is_Positive: _, err = big.rat_is_positive(v)
			case .Is_Negative: _, err = big.rat_is_negative(v)
			case .Is_Even:     _, err = big.rat_is_even(v)
			case .Is_Odd:      _, err = big.rat_is_odd(v)
			}
			testing.expectf(t, err == .Invalid_Argument, "%v(%v): err = %v", op, v.a.flags, err)
			fix_rat_expect(t, &d, "3", "4")
		}
	}

	Copy_Op :: enum { Copy, Set_Rat, Abs, Neg }
	Copy_Case :: struct {
		op:  Copy_Op,
		src: ^big.Rat,
		inf: int,
	}
	copy_cases := [?]Copy_Case{
		{.Copy, &ninf, -1}, {.Set_Rat, &pinf, 1}, {.Abs, &ninf, 1}, {.Neg, &pinf, -1},
		{.Copy, &nan, 0}, {.Set_Rat, &nan, 0}, {.Abs, &nan, 0}, {.Neg, &nan, 0},
	}
	for c in copy_cases {
		testing.expect_value(t, big.rat_set_frac_digit(&d, 3, 4), nil)
		err: big.Error
		switch c.op {
		case .Copy:    err = big.rat_copy(&d, c.src)
		case .Set_Rat: err = big.rat_set_rat(&d, c.src)
		case .Abs:     err = big.rat_abs(&d, c.src)
		case .Neg:     err = big.rat_neg(&d, c.src)
		}
		testing.expect_value(t, err, nil)
		f, _, _ := big.rat_to_f64(&d)
		ok := math.is_nan(f) if c.inf == 0 else math.is_inf(f, c.inf)
		testing.expectf(t, ok, "%v(%v): %v", c.op, c.src.a.flags, f)
	}

	fix_rat_set_hex(&x, FIX_RAT_X_N, FIX_RAT_X_D)
	fix_rat_set_hex(&y, FIX_RAT_Y_N, FIX_RAT_Y_D)
	Write_Op :: enum {
		Set_F64, Set_Frac_Digit, Set_Frac_Int, Set_Int, Set_Digit, Set_Rat, Set_U64, Set_I64,
		Copy, Abs, Neg, Add_Small, Add, Sub, Mul, Div,
		Rat_Add_Int, Rat_Sub_Int, Rat_Mul_Int, Rat_Div_Int,
		Int_Add_Rat, Int_Sub_Rat, Int_Mul_Rat, Int_Div_Rat,
	}
	small: big.Rat
	defer big.destroy(&small)
	testing.expect_value(t, big.rat_set_frac_digit(&small, 5, 2), nil)
	for stale in ([?]f64{math.nan_f64(), math.inf_f64(-1)}) {
		for op in Write_Op {
			big.destroy(&e)
			for r in ([?]^big.Rat{&e, &d}) {
				if r == &d {
					testing.expect_value(t, big.rat_set_f64(&d, stale), nil)
				}
				err: big.Error
				switch op {
				case .Set_F64:        err = big.rat_set_f64(r, -0.375)
				case .Set_Frac_Digit: err = big.rat_set_frac_digit(r, 6, 4)
				case .Set_Frac_Int:   err = big.rat_set_frac_int(r, &n, &y.b)
				case .Set_Int:        err = big.rat_set_int(r, &y.b)
				case .Set_Digit:      err = big.rat_set_digit(r, 9)
				case .Set_Rat:        err = big.rat_set_rat(r, &x)
				case .Set_U64:        err = big.rat_set_u64(r, 12345)
				case .Set_I64:        err = big.rat_set_i64(r, -12345)
				case .Copy:           err = big.rat_copy(r, &x)
				case .Abs:            err = big.rat_abs(r, &x)
				case .Neg:            err = big.rat_neg(r, &x)
				case .Add_Small:      err = big.rat_add_rat(r, &small, &small)
				case .Add:            err = big.rat_add_rat(r, &x, &y)
				case .Sub:            err = big.rat_sub_rat(r, &x, &y)
				case .Mul:            err = big.rat_mul_rat(r, &x, &y)
				case .Div:            err = big.rat_div_rat(r, &x, &y)
				case .Rat_Add_Int:    err = big.rat_add_int(r, &x, &n)
				case .Rat_Sub_Int:    err = big.rat_sub_int(r, &x, &n)
				case .Rat_Mul_Int:    err = big.rat_mul_int(r, &x, &n)
				case .Rat_Div_Int:    err = big.rat_div_int(r, &x, &n)
				case .Int_Add_Rat:    err = big.int_add_rat(r, &n, &x)
				case .Int_Sub_Rat:    err = big.int_sub_rat(r, &n, &x)
				case .Int_Mul_Rat:    err = big.int_mul_rat(r, &n, &x)
				case .Int_Div_Rat:    err = big.int_div_rat(r, &n, &x)
				}
				testing.expectf(t, err == nil, "%v: err = %v", op, err)
			}
			testing.expectf(t, d.a.flags == {} && d.b.flags == {}, "%v over %v: flags = %v, %v", op, stale, d.a.flags, d.b.flags)
			c, err := big.rat_compare(&d, &e)
			testing.expectf(t, c == 0 && err == nil, "%v over %v: compare = %v, %v", op, stale, c, err)
		}
	}
}

@(private="file")
fix_non_finite :: proc(a: ^big.Int, kind: int) {
	switch kind {
	case 0: big.nan(a)
	case 1: big.inf(a)
	case:   big.minus_inf(a)
	}
}

@(private="file")
fix_same :: proc(t: ^testing.T, got_err, want_err: big.Error, got, want: ^big.Int, loc := #caller_location) {
	testing.expect_value(t, got_err, nil, loc=loc)
	testing.expect_value(t, want_err, nil, loc=loc)
	testing.expect_value(t, got.flags, big.Flags{}, loc=loc)
	g, _ := big.int_itoa_string(got,  10, false, context.temp_allocator)
	w, _ := big.int_itoa_string(want, 10, false, context.temp_allocator)
	testing.expect_value(t, g, w, loc=loc)
}

@(test)
test_fix_non_finite_operands_rejected :: proc(t: ^testing.T) {
	d, r, x, y, m := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(d, r, x, y, m)
	q, p := &big.Rat{}, &big.Rat{}
	defer big.destroy(q, p)
	buf: [64]u8

	INV :: big.Error.Invalid_Argument
	for kind in 0..<3 {
		fix_non_finite(x, kind)
		fix_set(t, y, "12345678901234567890123")
		fix_set(t, m, "1000003")
		fix_set(t, d, "7")
		fix_set(t, r, "9")
		testing.expect_value(t, big.rat_set_i64(q, 5), nil)
		testing.expect_value(t, big.rat_set_i64(p, 3), nil)

		testing.expect_value(t, big.int_add(d, x, y), INV)
		testing.expect_value(t, big.int_add(d, y, x), INV)
		testing.expect_value(t, big.int_add_digit(d, x, 5), INV)
		testing.expect_value(t, big.int_sub(d, x, y), INV)
		testing.expect_value(t, big.int_sub(d, y, x), INV)
		testing.expect_value(t, big.int_sub_digit(d, x, 5), INV)
		testing.expect_value(t, big.int_halve(d, x), INV)
		testing.expect_value(t, big.int_double(d, x), INV)
		testing.expect_value(t, big.int_mul_digit(d, x, 3), INV)
		testing.expect_value(t, big.int_mul(d, x, y), INV)
		testing.expect_value(t, big.int_mul(d, y, x), INV)
		testing.expect_value(t, big.int_divmod(d, r, x, y), INV)
		testing.expect_value(t, big.int_divmod(d, r, y, x), INV)
		_, err := big.int_divmod_digit(d, x, 3)
		testing.expect_value(t, err, INV)
		testing.expect_value(t, big.int_div(d, x, y), INV)
		testing.expect_value(t, big.int_div(d, y, x), INV)
		testing.expect_value(t, big.int_div_digit(d, x, 3), INV)
		testing.expect_value(t, big.int_mod(d, x, m), INV)
		testing.expect_value(t, big.int_mod(d, y, x), INV)
		_, err = big.int_mod_digit(x, 3)
		testing.expect_value(t, err, INV)
		testing.expect_value(t, big.int_addmod(d, x, y, m), INV)
		testing.expect_value(t, big.int_addmod(d, y, x, m), INV)
		testing.expect_value(t, big.int_addmod(d, y, y, x), INV)
		testing.expect_value(t, big.int_submod(d, x, y, m), INV)
		testing.expect_value(t, big.int_submod(d, y, x, m), INV)
		testing.expect_value(t, big.int_submod(d, y, y, x), INV)
		testing.expect_value(t, big.int_mulmod(d, x, y, m), INV)
		testing.expect_value(t, big.int_mulmod(d, y, x, m), INV)
		testing.expect_value(t, big.int_mulmod(d, y, y, x), INV)
		testing.expect_value(t, big.int_sqrmod(d, x, m), INV)
		testing.expect_value(t, big.int_sqrmod(d, y, x), INV)
		testing.expect_value(t, big.int_gcd_lcm(d, r, x, y), INV)
		testing.expect_value(t, big.int_gcd_lcm(d, r, y, x), INV)
		testing.expect_value(t, big.int_gcd(d, x, y), INV)
		testing.expect_value(t, big.int_lcm(d, y, x), INV)
		testing.expect_value(t, big.int_mod_bits(d, x, 5), INV)
		testing.expect_value(t, big.int_pow(d, x, 3), INV)
		testing.expect_value(t, big.int_sqrt(d, x), INV)
		testing.expect_value(t, big.int_root_n(d, x, 3), INV)
		testing.expect_value(t, big.int_bit_and(d, x, y), INV)
		testing.expect_value(t, big.int_bit_and(d, y, x), INV)
		testing.expect_value(t, big.int_bit_or(d, x, y), INV)
		testing.expect_value(t, big.int_bit_xor(d, y, x), INV)
		testing.expect_value(t, big.int_bit_complement(d, x), INV)
		testing.expect_value(t, big.int_shrmod(d, r, x, 3), INV)
		testing.expect_value(t, big.int_shr(d, x, 3), INV)
		testing.expect_value(t, big.int_shr_signed(d, x, 3), INV)
		testing.expect_value(t, big.int_shl(d, x, 3), INV)
		testing.expect_value(t, big.copy_digits(d, x, 1), INV)
		fix_expect(t, d, "7")
		fix_expect(t, r, "9")

		_, err = big.int_log(x, 10)
		testing.expect_value(t, err, INV)
		_, err = big.int_is_zero(x)
		testing.expect_value(t, err, INV)
		_, err = big.int_is_positive(x)
		testing.expect_value(t, err, INV)
		_, err = big.int_is_negative(x)
		testing.expect_value(t, err, INV)
		_, err = big.int_is_even(x)
		testing.expect_value(t, err, INV)
		_, err = big.int_is_odd(x)
		testing.expect_value(t, err, INV)
		_, err = big.int_is_power_of_two(x)
		testing.expect_value(t, err, INV)
		_, err = big.int_is_square(x)
		testing.expect_value(t, err, INV)
		_, err = big.int_compare(x, y)
		testing.expect_value(t, err, INV)
		_, err = big.int_compare(y, x)
		testing.expect_value(t, err, INV)
		_, err = big.int_compare(x, x)
		testing.expect_value(t, err, INV)
		_, err = big.int_compare_digit(x, 1)
		testing.expect_value(t, err, INV)
		_, err = big.int_compare_magnitude(y, x)
		testing.expect_value(t, err, INV)
		_, err = big.int_less_than(x, y)
		testing.expect_value(t, err, INV)
		_, err = big.int_equals(y, x)
		testing.expect_value(t, err, INV)
		_, err = big.int_greater_than_digit(x, 0)
		testing.expect_value(t, err, INV)
		_, err = big.int_get(x, i64)
		testing.expect_value(t, err, INV)
		_, err = big.int_get_u128(x)
		testing.expect_value(t, err, INV)
		_, err = big.count_bits(x)
		testing.expect_value(t, err, INV)
		_, err = big.int_count_lsb(x)
		testing.expect_value(t, err, INV)
		_, err = big.int_bitfield_extract(x, 0, 1)
		testing.expect_value(t, err, INV)
		_, err = big.int_to_bytes_size(x)
		testing.expect_value(t, err, INV)
		testing.expect_value(t, big.int_to_bytes_big(x, buf[:]), INV)
		testing.expect_value(t, big.int_to_bytes_little_python(x, buf[:], true), INV)

		testing.expect_value(t, big.rat_set_frac_int(q, x, y), INV)
		testing.expect_value(t, big.rat_set_frac_int(q, y, x), INV)
		testing.expect_value(t, big.rat_add_int(q, p, x), INV)
		testing.expect_value(t, big.rat_sub_int(q, p, x), INV)
		testing.expect_value(t, big.rat_mul_int(q, p, x), INV)
		testing.expect_value(t, big.rat_div_int(q, p, x), INV)
		testing.expect_value(t, big.int_add_rat(q, x, p), INV)
		testing.expect_value(t, big.int_sub_rat(q, x, p), INV)
		testing.expect_value(t, big.int_mul_rat(q, x, p), INV)
		testing.expect_value(t, big.int_div_rat(q, x, p), INV)
		f, _, _ := big.rat_to_f64(q)
		testing.expect_value(t, f, 5.0)
	}
}

@(test)
test_fix_non_finite_destination_cleared :: proc(t: ^testing.T) {
	d, r, e, g, x, y, m := &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}, &big.Int{}
	defer big.destroy(d, r, e, g, x, y, m)

	fix_set(t, x, "-12345678901234567890123456789")
	fix_set(t, y, "98765432109876543210")
	fix_set(t, m, "999983")

	for kind in 0..<3 {
		fix_non_finite(d, kind)
		big.zero(e)
		fix_same(t, big.int_add(d, x, y), big.int_add(e, x, y), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_add_digit(d, x, 5), big.int_add_digit(e, x, 5), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_sub(d, x, y), big.int_sub(e, x, y), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_sub_digit(d, x, 5), big.int_sub_digit(e, x, 5), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_halve(d, x), big.int_halve(e, x), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_double(d, x), big.int_double(e, x), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_mul_digit(d, x, 3), big.int_mul_digit(e, x, 3), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_mul(d, x, y), big.int_mul(e, x, y), d, e)

		fix_non_finite(d, kind)
		fix_non_finite(r, kind)
		err_d := big.int_divmod(d, r, x, y)
		err_e := big.int_divmod(e, g, x, y)
		fix_same(t, err_d, err_e, d, e)
		fix_same(t, err_d, err_e, r, g)

		fix_non_finite(d, kind)
		_, err_d = big.int_divmod_digit(d, x, 7)
		_, err_e = big.int_divmod_digit(e, x, 7)
		fix_same(t, err_d, err_e, d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_div(d, x, y), big.int_div(e, x, y), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_div_digit(d, x, 7), big.int_div_digit(e, x, 7), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_mod(d, x, m), big.int_mod(e, x, m), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_addmod(d, x, y, m), big.int_addmod(e, x, y, m), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_submod(d, x, y, m), big.int_submod(e, x, y, m), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_mulmod(d, x, y, m), big.int_mulmod(e, x, y, m), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_sqrmod(d, x, m), big.int_sqrmod(e, x, m), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_factorial(d, 25), big.int_factorial(e, 25), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_choose_digit(d, 30, 7), big.int_choose_digit(e, 30, 7), d, e)

		fix_non_finite(d, kind)
		fix_non_finite(r, kind)
		err_d = big.int_gcd_lcm(d, r, x, y)
		err_e = big.int_gcd_lcm(e, g, x, y)
		fix_same(t, err_d, err_e, d, e)
		fix_same(t, err_d, err_e, r, g)

		fix_non_finite(d, kind)
		fix_same(t, big.int_gcd(d, x, y), big.int_gcd(e, x, y), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_lcm(d, x, y), big.int_lcm(e, x, y), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_mod_bits(d, x, 70), big.int_mod_bits(e, x, 70), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_pow(d, x, 3), big.int_pow(e, x, 3), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_pow_int(d, 7, 30), big.int_pow_int(e, 7, 30), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_sqrt(d, y), big.int_sqrt(e, y), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_root_n(d, y, 3), big.int_root_n(e, y, 3), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_bit_and(d, x, y), big.int_bit_and(e, x, y), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_bit_or(d, x, y), big.int_bit_or(e, x, y), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_bit_xor(d, x, y), big.int_bit_xor(e, x, y), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_bit_complement(d, x), big.int_bit_complement(e, x), d, e)

		fix_non_finite(d, kind)
		fix_non_finite(r, kind)
		err_d = big.int_shrmod(d, r, x, 70)
		err_e = big.int_shrmod(e, g, x, 70)
		fix_same(t, err_d, err_e, d, e)
		fix_same(t, err_d, err_e, r, g)

		fix_non_finite(d, kind)
		fix_same(t, big.int_shr(d, x, 70), big.int_shr(e, x, 70), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_shr_signed(d, x, 70), big.int_shr_signed(e, x, 70), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.int_shl(d, x, 70), big.int_shl(e, x, 70), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.permutations_with_repetition(d, 5, 30), big.permutations_with_repetition(e, 5, 30), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.permutations_without_repetition(d, 30, 7), big.permutations_without_repetition(e, 30, 7), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.combinations_with_repetition(d, 30, 7), big.combinations_with_repetition(e, 30, 7), d, e)
		fix_non_finite(d, kind)
		fix_same(t, big.combinations_without_repetition(d, 30, 7), big.combinations_without_repetition(e, 30, 7), d, e)
		fix_non_finite(d, kind)
		testing.expect_value(t, big.copy_digits(d, x, 1), nil)
		testing.expect_value(t, d.flags, big.Flags{})
		testing.expect_value(t, d.digit[0], x.digit[0])

		fix_non_finite(d, kind)
		d.flags += {.Immutable}
		flags := d.flags
		testing.expect_value(t, big.int_add(d, x, y), big.Error.Assignment_To_Immutable)
		testing.expect_value(t, big.copy_digits(d, x, 1), big.Error.Assignment_To_Immutable)
		testing.expect_value(t, big.int_random(d, 64), big.Error.Assignment_To_Immutable)
		testing.expect_value(t, big.int_shrmod(d, r, x, 3), big.Error.Assignment_To_Immutable)
		testing.expect_value(t, big.combinations_without_repetition(d, 30, 7), big.Error.Assignment_To_Immutable)
		testing.expect_value(t, d.flags, flags)
		d.flags -= {.Immutable}
	}
}

@(test)
test_fix_non_finite_propagates :: proc(t: ^testing.T) {
	a, b := &big.Int{}, &big.Int{}
	defer big.destroy(a, b)

	big.nan(a)
	testing.expect_value(t, big.int_copy(b, a), nil)
	testing.expect_value(t, b.flags, big.Flags{.NaN})

	big.minus_inf(a)
	testing.expect_value(t, big.int_abs(b, a), nil)
	testing.expect_value(t, b.flags, big.Flags{.Inf})
	testing.expect_value(t, b.sign, big.Sign.Zero_or_Positive)

	testing.expect_value(t, big.int_neg(b, b), nil)
	testing.expect_value(t, b.flags, big.Flags{.Inf})
	testing.expect_value(t, b.sign, big.Sign.Negative)

	testing.expect_value(t, big.set(b, 5), nil)
	testing.expect_value(t, b.flags, big.Flags{})
	fix_expect(t, b, "5")
}

@(test)
test_fix_get_float_non_finite :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)

	big.nan(a)
	f, err := big.int_get_float(a)
	testing.expect_value(t, err, nil)
	testing.expect(t, math.is_nan(f))

	big.inf(a)
	f, err = big.int_get_float(a)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, f, math.inf_f64(1))

	big.minus_inf(a)
	f, err = big.int_get_float(a)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, f, math.inf_f64(-1))
}

@(test)
test_fix_itoa_non_finite :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)
	buf: [8]u8

	for radix in i8(2)..=23 {
		big.nan(a)
		s, err := big.int_itoa_string(a, radix, false, context.temp_allocator)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, s, "NaN")

		big.inf(a)
		s, err = big.int_itoa_string(a, radix, false, context.temp_allocator)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, s, "+Inf")

		big.minus_inf(a)
		s, err = big.int_itoa_string(a, radix, false, context.temp_allocator)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, s, "-Inf")
	}

	for radix in i8(24)..=64 {
		for kind in 0..<3 {
			fix_non_finite(a, kind)
			_, err := big.int_itoa_string(a, radix, false, context.temp_allocator)
			testing.expect_value(t, err, big.Error.Invalid_Argument)
			_, err = big.radix_size(a, radix)
			testing.expect_value(t, err, big.Error.Invalid_Argument)
			_, err = big.int_itoa_raw(a, radix, buf[:], len(buf))
			testing.expect_value(t, err, big.Error.Invalid_Argument)
		}
	}

	big.minus_inf(a)
	size, err := big.radix_size(a, 10, true)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, size, 5)

	written: int
	written, err = big.int_itoa_raw(a, 10, buf[:], -1, true)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, written, 5)
	testing.expect_value(t, string(buf[:written]), "-Inf\x00")

	_, err = big.int_itoa_raw(a, 10, buf[:4], 4, true)
	testing.expect_value(t, err, big.Error.Buffer_Overflow)
	_, err = big.int_itoa_raw(a, 10, buf[:4], -1, true)
	testing.expect_value(t, err, big.Error.Buffer_Overflow)

	cs: cstring
	cs, err = big.int_itoa_cstring(a, 10, context.temp_allocator)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, string(cs), "-Inf")

	big.nan(a)
	size, err = big.radix_size(a, 16)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, size, 3)

	written, err = big.int_itoa_raw(a, 0, buf[:])
	testing.expect_value(t, err, nil)
	testing.expect_value(t, string(buf[:written]), "NaN")
}

@(test)
test_fix_atoi_non_finite :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)
	n: int

	for radix in i8(2)..=23 {
		testing.expect_value(t, big.int_atoi(a, "NaN", radix, &n), nil)
		testing.expect_value(t, a.flags, big.Flags{.NaN})
		testing.expect_value(t, n, 3)

		testing.expect_value(t, big.int_atoi(a, "+Inf", radix, &n), nil)
		testing.expect_value(t, a.flags, big.Flags{.Inf})
		testing.expect_value(t, a.sign, big.Sign.Zero_or_Positive)
		testing.expect_value(t, n, 4)

		testing.expect_value(t, big.int_atoi(a, "-Inf", radix, &n), nil)
		testing.expect_value(t, a.flags, big.Flags{.Inf})
		testing.expect_value(t, a.sign, big.Sign.Negative)
		testing.expect_value(t, n, 4)

		for kind in 0..<3 {
			fix_non_finite(a, kind)
			s, err := big.int_itoa_string(a, radix, false, context.temp_allocator)
			testing.expect_value(t, err, nil)
			flags, sign := a.flags, a.sign
			testing.expect_value(t, big.int_atoi(a, s, radix), nil)
			testing.expect_value(t, a.flags, flags)
			testing.expect_value(t, a.sign, sign)
		}
	}

	testing.expect_value(t, big.int_atoi(a, "NaN \n", 10, &n), big.Error.Trailing_Whitespace)
	testing.expect_value(t, a.flags, big.Flags{.NaN})
	testing.expect_value(t, n, 3)

	testing.expect_value(t, big.int_atoi(a, "+Infinity", 10, &n), big.Error.Invalid_Character)
	testing.expect_value(t, a.flags, big.Flags{.Inf})
	testing.expect_value(t, n, 4)

	testing.expect_value(t, big.int_atoi(a, "nan", 10, &n), big.Error.Invalid_Character)
	testing.expect_value(t, a.flags, big.Flags{})
	testing.expect_value(t, n, 0)

	testing.expect_value(t, big.int_atoi(a, "Inf", 10, &n), big.Error.Invalid_Character)
	testing.expect_value(t, a.flags, big.Flags{})
	testing.expect_value(t, n, 0)

	testing.expect_value(t, big.int_atoi(a, "-inf", 10, &n), big.Error.Invalid_Character)
	testing.expect_value(t, a.flags, big.Flags{})
	testing.expect_value(t, n, 1)

	testing.expect_value(t, big.int_atoi(a, "-Inf", 19, &n), nil)
	testing.expect_value(t, a.flags, big.Flags{.Inf})
	testing.expect_value(t, a.sign, big.Sign.Negative)

	testing.expect_value(t, big.int_atoi(a, "NaN", 24, &n), nil)
	testing.expect_value(t, a.flags, big.Flags{})
	fix_expect(t, a, "13511")

	testing.expect_value(t, big.int_atoi(a, "NaN", 36, &n), nil)
	testing.expect_value(t, a.flags, big.Flags{})
	fix_expect(t, a, "30191")

	testing.expect_value(t, big.int_atoi(a, "-Inf", 36, &n), nil)
	testing.expect_value(t, a.flags, big.Flags{})
	fix_expect(t, a, "-24171")

	testing.expect_value(t, big.int_atoi(a, "+Inf", 64, &n), nil)
	testing.expect_value(t, a.flags, big.Flags{})
	testing.expect_value(t, n, 4)
	fix_expect(t, a, "16329833")
}

@(test)
test_fix_bit_length :: proc(t: ^testing.T) {
	testing.expect_value(t, big.bit_length(0), 0)
	testing.expect_value(t, big.bit_length(1), 1)
	testing.expect_value(t, big.bit_length(255), 8)
	testing.expect_value(t, big.bit_length(256), 9)
	testing.expect_value(t, big.bit_length(max(int)), 8 * size_of(int) - 1)
	testing.expect_value(t, big.bit_length(max(u64)), u64(64))
	testing.expect_value(t, big.bit_length(u8(0x80)), u8(8))
}
