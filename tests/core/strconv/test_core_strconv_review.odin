package test_core_strconv

import "core:fmt"
import "core:math"
import "core:math/rand"
import "core:strconv"
import "core:testing"
import "core:unicode/utf8"

@(private="file")
review_unquote_err :: proc(err: strconv.Error) -> strconv.Unquote_Error {
	e, _ := err.(strconv.Unquote_Error)
	return e
}

@(test)
test_review_parse_f64_known_values :: proc(t: ^testing.T) {
	Case :: struct {
		s:    string,
		bits: u64,
		ok:   bool,
	}
	cases := [?]Case{
		{"0.1", 0x3fb999999999999a, true},
		{"1e23", 0x44b52d02c7e14af6, true},
		{"2.2250738585072011e-308", 0x000fffffffffffff, true},
		{"2.2250738585072014e-308", 0x0010000000000000, true},
		{"4.9e-324", 0x0000000000000001, true},
		{"2.4703282292062327e-324", 0x0000000000000000, true},
		{"2.4703282292062328e-324", 0x0000000000000001, true},
		{"1.7976931348623157e308", 0x7fefffffffffffff, true},
		{"1.7976931348623159e308", 0x7ff0000000000000, false},
		{"-0.0", 0x8000000000000000, true},
		{"9007199254740993", 0x4340000000000000, true},
		{"9007199254740995", 0x4340000000000002, true},
		{"0x1.fffffffffffffp1023", 0x7fefffffffffffff, true},
		{"0x1p-1074", 0x0000000000000001, true},
		{"1_000.000_5", 0x408f40010624dd2f, true},
	}
	for c in cases {
		v, ok := strconv.parse_f64(c.s)
		testing.expectf(t, transmute(u64)v == c.bits && ok == c.ok, "parse_f64(%q) = %016x, %v; want %016x, %v", c.s, transmute(u64)v, ok, c.bits, c.ok)
	}
}

@(test)
test_review_parse_f32_known_values :: proc(t: ^testing.T) {
	Case :: struct {
		s:    string,
		bits: u32,
		ok:   bool,
	}
	cases := [?]Case{
		{"0.1", 0x3dcccccd, true},
		{"3.4028235e38", 0x7f7fffff, true},
		{"3.4028235677e38", 0x7f7fffff, true},
		{"3.4028235678e38", 0x7f800000, false},
		{"3.5e38", 0x7f800000, false},
		{"1.4e-45", 0x00000001, true},
		{"1.17549435e-38", 0x00800000, true},
		{"16777217", 0x4b800000, true},
	}
	for c in cases {
		v, ok := strconv.parse_f32(c.s)
		testing.expectf(t, transmute(u32)v == c.bits && ok == c.ok, "parse_f32(%q) = %08x, %v; want %08x, %v", c.s, transmute(u32)v, ok, c.bits, c.ok)
	}
}

@(test)
test_review_parse_float_no_whitespace :: proc(t: ^testing.T) {
	n: int
	_, ok := strconv.parse_f64(" 1", &n)
	testing.expectf(t, !ok && n == 0, "parse_f64(\" 1\"): n=%d ok=%v", n, ok)
	_, nr, pok := strconv.parse_f64_prefix("\t1")
	testing.expectf(t, !pok && nr == 0, "parse_f64_prefix(\"\\t1\"): nr=%d ok=%v", nr, pok)
	v, nr2, ok2 := strconv.parse_f64_prefix("1.5abc")
	testing.expectf(t, ok2 && v == 1.5 && nr2 == 3, "parse_f64_prefix(\"1.5abc\") = %v, %d, %v", v, nr2, ok2)
}

@(test)
test_review_write_float_known_values :: proc(t: ^testing.T) {
	Case :: struct {
		v:    f64,
		fmt:  byte,
		prec: int,
		bits: int,
		want: string,
	}
	cases := [?]Case{
		{0.1, 'e', 20, 64, "1.00000000000000005551e-01"},
		{0.1, 'f', 30, 64, "0.100000000000000005551115123126"},
		{0.1, 'g', 17, 64, "0.10000000000000001"},
		{0.1, 'g', -1, 64, "0.1"},
		{f64(f32(0.1)), 'g', -1, 32, "0.1"},
		{f64(f32(0.1)), 'f', 12, 32, "0.100000001490"},
		{1e21, 'f', 0, 64, "1000000000000000000000"},
		{2.5, 'f', 0, 64, "2"},
		{3.5, 'f', 0, 64, "4"},
		{1.5, 'e', 0, 64, "2e+00"},
		{123456, 'g', 3, 64, "1.23e+05"},
		{0.0001, 'g', -1, 64, "0.0001"},
		{1e-5, 'g', -1, 64, "1e-05"},
		{-0.0, 'f', 1, 64, "-0.0"},
		{math.inf_f64(1), 'f', 2, 64, "+Inf"},
		{math.inf_f64(-1), 'e', 2, 64, "-Inf"},
	}
	buf: [64]byte
	for c in cases {
		got := strconv.write_float(buf[:], c.v, c.fmt, c.prec, c.bits, nil)
		testing.expectf(t, got == c.want, "write_float(%v, '%c', %d, %d) = %q, want %q", c.v, c.fmt, c.prec, c.bits, got, c.want)
	}
}

@(test)
test_review_float_shortest_round_trip :: proc(t: ^testing.T) {
	r := rand.create(0x5eed)
	gen := rand.default_random_generator(&r)
	buf: [64]byte
	for _ in 0..<20_000 {
		bits := rand.uint64(gen)
		v := transmute(f64)bits
		if math.is_nan(v) || math.is_inf(v) {
			continue
		}
		s := strconv.write_float(buf[:], v, 'g', -1, 64, nil)
		w, ok := strconv.parse_f64(s)
		testing.expectf(t, ok && transmute(u64)w == bits, "%016x -> %q -> %016x, %v", bits, s, transmute(u64)w, ok)

		b32 := u32(bits)
		v32 := transmute(f32)b32
		if math.is_nan(v32) || math.is_inf(v32) {
			continue
		}
		s = strconv.write_float(buf[:], f64(v32), 'g', -1, 32, nil)
		w32, ok32 := strconv.parse_f32(s)
		testing.expectf(t, ok32 && transmute(u32)w32 == b32, "%08x -> %q -> %08x, %v", b32, s, transmute(u32)w32, ok32)
	}
}

@(test)
test_review_int_round_trip :: proc(t: ^testing.T) {
	buf: [140]byte
	values := [?]i64{0, 1, -1, 9, 10, 255, -256, max(i64), min(i64), 1234567890123}
	for base in 2..=16 {
		for v in values {
			s := strconv.write_int(buf[:], v, base)
			got, ok := strconv.parse_i64_of_base(s, base)
			testing.expectf(t, ok && got == v, "base %d: %d -> %q -> %d, %v", base, v, s, got, ok)
		}
		for v in ([]u128{0, 1, max(u128), u128(max(u64)) + 1}) {
			s := strconv.write_u128(buf[:], v, base)
			got, ok := strconv.parse_u128_of_base(s, base)
			testing.expectf(t, ok && got == v, "base %d: %v -> %q -> %v, %v", base, v, s, got, ok)
		}
	}
}

@(test)
test_review_parse_int_limits :: proc(t: ^testing.T) {
	v, ok := strconv.parse_i64("-9223372036854775808")
	testing.expectf(t, ok && v == min(i64), "min(i64): %d, %v", v, ok)
	_, ok = strconv.parse_i64("-9223372036854775809")
	testing.expect(t, !ok, "min(i64) - 1 overflows")
	_, ok = strconv.parse_i64("9223372036854775808")
	testing.expect(t, !ok, "max(i64) + 1 overflows")
	u, uok := strconv.parse_u64("18446744073709551615")
	testing.expectf(t, uok && u == max(u64), "max(u64): %d, %v", u, uok)
	_, uok = strconv.parse_u64("18446744073709551616")
	testing.expect(t, !uok, "max(u64) + 1 overflows")
	p, pok := strconv.parse_i64_maybe_prefixed("-0x8000_0000_0000_0000")
	testing.expectf(t, pok && p == min(i64), "-0x8000_0000_0000_0000: %d, %v", p, pok)
	z, zok := strconv.parse_u64_maybe_prefixed("0z1b")
	testing.expectf(t, zok && z == 23, "0z1b: %d, %v", z, zok)
}

@(test)
test_review_quote_unquote_every_byte :: proc(t: ^testing.T) {
	opts := [?]strconv.Rune_Escaping_Options{nil, {.ascii_compatible}, {.html_safe}}
	buf: [32]byte
	for b in 0..<256 {
		one := [1]byte{byte(b)}
		s := string(one[:])
		for o in opts {
			q := strconv.quote_string_buf(buf[:], s, '"', o)
			u, allocated, err := strconv.unquote_string(q)
			testing.expectf(t, err == nil && u == s, "byte %02x, %v: %s -> %v, %v", b, o, q, transmute([]byte)u, err)
			if allocated {
				delete(u)
			}
		}
	}
}

@(test)
test_review_quote_unquote_runes :: proc(t: ^testing.T) {
	opts := [?]strconv.Rune_Escaping_Options{nil, {.ascii_compatible}, {.html_safe}}
	buf: [32]byte
	for r := rune(0); r <= utf8.MAX_RUNE; r += 1 + rune(r >> 8) {
		if r >= 0xd800 && r <= 0xdfff {
			continue
		}
		enc, w := utf8.encode_rune(r)
		s := string(enc[:w])
		for o in opts {
			q := strconv.quote_string_buf(buf[:], s, '"', o)
			u, allocated, err := strconv.unquote_string(q)
			testing.expectf(t, err == nil && u == s, "%U, %v: %s -> %q, %v", r, o, q, u, err)
			if allocated {
				delete(u)
			}
			rq := strconv.quote_rune(buf[:], r, o)
			ru, rallocated, rerr := strconv.unquote_string(rq)
			testing.expectf(t, rerr == nil && ru == s, "%U, %v: %s -> %q, %v", r, o, rq, ru, rerr)
			if rallocated {
				delete(ru)
			}
		}
	}
}

@(test)
test_review_unquote_string_literal_rules :: proc(t: ^testing.T) {
	Case :: struct {
		lit:       string,
		want:      string,
		allocated: bool,
		err:       strconv.Unquote_Error,
	}
	cases := [?]Case{
		{`"abc"`, "abc", false, .None},
		{`"a\tb"`, "a\tb", true, .None},
		{`"\u00e9\U0001f600"`, "é\U0001f600", true, .None},
		{`"\ud800"`, "\ufffd", true, .None},
		{`"\'"`, "'", true, .None},
		{`'\u00e9'`, "é", true, .None},
		{`'é'`, "é", false, .None},
		{"`a\\tb`", `a\tb`, false, .None},
		{"`a\r\nb`", "a\r\nb", false, .None},
		{"`a\nb`", "a\nb", false, .None},
		{"\"a\x00b\"", "a\x00b", false, .None},
		{"\"\ufeff\"", "\ufeff", false, .None},
		{"\"a\rb\"", "a\rb", false, .None},
		{`"\q"`, "", false, .Invalid_Escape},
		{`"\x4"`, "", false, .Invalid_Escape},
		{`"\u12"`, "", false, .Invalid_Escape},
		{`"\"`, "", false, .Invalid_Escape},
		{"", "", false, .Missing_Quote},
		{"\"\"\"\n\tx\n\t\"\"\"", "x", true, .None},
	}
	for c in cases {
		s, allocated, err := strconv.unquote_string(c.lit)
		testing.expectf(t, s == c.want && allocated == c.allocated && review_unquote_err(err) == c.err, "unquote_string(%q) = %q, %v, %v; want %q, %v, %v", c.lit, s, allocated, err, c.want, c.allocated, c.err)
		if allocated {
			delete(s)
		}
	}
}

@(test)
test_review_complex_round_trip :: proc(t: ^testing.T) {
	for c in ([]complex128{complex(1, 2), complex(-1.5, -0.25), complex(0, 0), complex(1e300, -1e-300)}) {
		s := fmt.tprint(c)
		v, ok := strconv.parse_complex128(s)
		testing.expectf(t, ok && v == c, "%q -> %v, %v", s, v, ok)
	}
	q: quaternion256 = 1 - 2i + 3.5j - 4k
	s := fmt.tprint(q)
	v, ok := strconv.parse_quaternion256(s)
	testing.expectf(t, ok && v == q, "%q -> %v, %v", s, v, ok)
}

@(test)
test_review_bool :: proc(t: ^testing.T) {
	for s in ([]string{"1", "t", "T", "true", "TRUE", "True"}) {
		v, ok := strconv.parse_bool(s)
		testing.expectf(t, ok && v, "parse_bool(%q) = %v, %v", s, v, ok)
	}
	for s in ([]string{"0", "f", "F", "false", "FALSE", "False"}) {
		v, ok := strconv.parse_bool(s)
		testing.expectf(t, ok && !v, "parse_bool(%q) = %v, %v", s, v, ok)
	}
	_, ok := strconv.parse_bool("yes")
	testing.expect(t, !ok, "parse_bool(\"yes\")")
	buf: [8]byte
	testing.expect_value(t, strconv.write_bool(buf[:], true), "true")
	testing.expect_value(t, strconv.write_bool(buf[:], false), "false")
}
