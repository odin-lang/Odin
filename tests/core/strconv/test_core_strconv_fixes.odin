package test_core_strconv

import "base:runtime"
import "core:encoding/cbor"
import "core:encoding/ini"
import "core:fmt"
import "core:math"
import "core:math/big"
import "core:strconv"
import "core:strconv/decimal"
import "core:strings"
import "core:testing"

@(private="file")
cat :: proc(parts: ..string) -> string {
	return strings.concatenate(parts, context.temp_allocator)
}

@(private="file")
zeros :: proc(n: int) -> string {
	return strings.repeat("0", n, context.temp_allocator)
}

@(private="file")
f64_parts :: proc(bits: u64) -> (m: u64, e2: int) {
	biased := int(bits >> 52 & 0x7ff)
	m = bits & (1 << 52 - 1)
	if biased == 0 {
		return m, -1074
	}
	return m | 1 << 52, biased - 1075
}

@(private="file")
digits_times_pow5 :: proc(v: u64, k: int) -> string {
	a, p := &big.Int{}, &big.Int{}
	defer big.destroy(a, p)
	_ = big.set(a, v)
	_ = big.pow(p, 5, k)
	_ = big.mul(a, a, p)
	s, _ := big.int_itoa_string(a, 10, false, context.temp_allocator)
	return s
}

@(private="file")
digits_times_pow2 :: proc(v: u64, k: int) -> string {
	a := &big.Int{}
	defer big.destroy(a)
	_ = big.set(a, v)
	_ = big.shl(a, a, k)
	s, _ := big.int_itoa_string(a, 10, false, context.temp_allocator)
	return s
}

@(private="file")
same_f64 :: proc(a, b: f64) -> bool {
	return a == b || (math.is_nan(a) && math.is_nan(b))
}

@(private="file")
unquote_err :: proc(err: strconv.Error) -> strconv.Unquote_Error {
	e, _ := err.(strconv.Unquote_Error)
	return e
}

@(private="file")
oom_allocator_proc :: proc(allocator_data: rawptr, mode: runtime.Allocator_Mode, size, alignment: int, old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, runtime.Allocator_Error) {
	return nil, .Out_Of_Memory
}

@(test)
test_fix_parse_f64_long_midpoints :: proc(t: ^testing.T) {
	for bits in ([]u64{0x0000000000000001, 0x0000000000000002, 0x000fffffffffffff, 0x0010000000000001, 0x0010000000000002, 0x0123456789abcdef}) {
		m, e2 := f64_parts(bits)
		k := 1 - e2
		d := digits_times_pow5(2*m + 1, k)
		even := bits if m & 1 == 0 else bits + 1
		Case :: struct {
			s:    string,
			want: u64,
		}
		cases := [?]Case{
			{fmt.tprintf("%se-%d", d, k), even},
			{fmt.tprintf("%se-%d", d[:len(d)-1], k - 1), bits},
			{fmt.tprintf("%s1e-%d", d, k + 1), bits + 1},
			{fmt.tprintf("0.%se%d", d, len(d) - k), even},
			{fmt.tprintf("%s%s1e-%d", d, zeros(100), k + 101), bits + 1},
			{fmt.tprintf("%s%s1.5e-%d", d, zeros(100), k + 101), bits + 1},
		}
		for c in cases {
			v, ok := strconv.parse_f64(c.s)
			testing.expectf(t, ok && transmute(u64)v == c.want, "midpoint of %016x (%d digits): got %016x ok=%v, want %016x", bits, len(d), transmute(u64)v, ok, c.want)
		}
	}
}

@(test)
test_fix_parse_f64_long_exponents :: proc(t: ^testing.T) {
	Case :: struct {
		s:    string,
		want: u64,
	}
	cases := [?]Case{
		{cat("0.", zeros(100_000), "9007199254740993000000000001e100016"), 0x4340000000000001},
		{cat("1", zeros(1_000_000), "e-1000000"), 0x3ff0000000000000},
		{cat("0.", zeros(1_000_000), "1e1000001"), 0x3ff0000000000000},
		{cat("0x0.", zeros(100_000), "1p400004"), 0x3ff0000000000000},
		{cat("0x0.", zeros(300_000), "1p1200004"), 0x3ff0000000000000},
		{cat("0x1", zeros(100_000), "p-400000"), 0x3ff0000000000000},
	}
	for c in cases {
		v, ok := strconv.parse_f64(c.s)
		testing.expectf(t, ok && transmute(u64)v == c.want, "%d bytes: got %016x ok=%v, want %016x", len(c.s), transmute(u64)v, ok, c.want)
	}
}

@(test)
test_fix_write_float_all_digits :: proc(t: ^testing.T) {
	d := digits_times_pow5(1, 1074)
	tiny := transmute(f64)u64(1)
	buf: [1200]byte

	got := strconv.write_float(buf[:], tiny, 'f', 1074, 64, nil)
	testing.expect_value(t, got, cat("0.", zeros(1074 - len(d)), d))

	got = strconv.write_float(buf[:], tiny, 'e', len(d) - 1, 64, nil)
	testing.expect_value(t, got, cat(d[:1], ".", d[1:], "e-324"))

	got = strconv.write_float(buf[:], tiny, 'e', 766, 64, nil)
	testing.expect_value(t, got, cat(d[:1], ".", d[1:], zeros(766 - (len(d) - 1)), "e-324"))
}

@(test)
test_fix_quote_latin1_runes :: proc(t: ^testing.T) {
	Case :: struct {
		s:    string,
		opts: strconv.Rune_Escaping_Options,
		want: string,
	}
	cases := [?]Case{
		{"\u0085", nil, `"\u0085"`},
		{"\u00ad", nil, `"\u00ad"`},
		{"é", {.ascii_compatible}, `"\u00e9"`},
		{"\u00ff", {.ascii_compatible}, `"\u00ff"`},
		{"\x85", nil, `"\x85"`},
	}
	buf: [64]byte
	for c in cases {
		q := strconv.quote_string_buf(buf[:], c.s, '"', c.opts)
		testing.expectf(t, q == c.want, "quote_string(%q, %v) = %s, want %s", c.s, c.opts, q, c.want)
		u, allocated, err := strconv.unquote_string(q)
		testing.expectf(t, err == nil && u == c.s, "unquote_string(%s) = %q, %v", q, u, err)
		if allocated {
			delete(u)
		}
	}
	testing.expect_value(t, fmt.tprintf("%q", "\u0085"), `"\u0085"`)
}

@(test)
test_fix_parse_complex_lone_imaginary :: proc(t: ^testing.T) {
	Case :: struct {
		s:    string,
		want: complex128,
	}
	cases := [?]Case{
		{"1i", complex(0, 1)},
		{"-2i", complex(0, -2)},
		{"+2.5i", complex(0, 2.5)},
		{"3+1i", complex(3, 1)},
		{"3-0i", complex(3, 0)},
	}
	for c in cases {
		n: int
		v, ok := strconv.parse_complex128(c.s, &n)
		testing.expectf(t, ok && v == c.want && n == len(c.s), "parse_complex128(%q) = %v, n=%d, ok=%v; want %v", c.s, v, n, ok, c.want)
	}

	n: int
	q, ok := strconv.parse_quaternion256("2i+3j+4k", &n)
	testing.expectf(t, ok && n == 8 && real(q) == 0 && imag(q) == 2 && jmag(q) == 3 && kmag(q) == 4, "parse_quaternion256(\"2i+3j+4k\") = %v, n=%d, ok=%v", q, n, ok)
}

@(test)
test_fix_parse_complex_nan_imaginary :: proc(t: ^testing.T) {
	nan := math.nan_f64()
	inf := math.inf_f64(1)
	for c in ([]complex128{complex(nan, nan), complex(1, nan), complex(nan, -2), complex(inf, nan), complex(-inf, inf)}) {
		s := fmt.tprint(c)
		v, ok := strconv.parse_complex128(s)
		testing.expectf(t, ok && same_f64(real(v), real(c)) && same_f64(imag(v), imag(c)), "%q -> %v, ok=%v", s, v, ok)
	}
	q: quaternion256 = 1 + 2i + 3j + 4k
	for k in 0..<4 {
		p := q
		switch k {
		case 0: p = quaternion(real = nan, imag = 2, jmag = 3, kmag = 4)
		case 1: p = quaternion(real = 1, imag = nan, jmag = 3, kmag = 4)
		case 2: p = quaternion(real = 1, imag = 2, jmag = nan, kmag = 4)
		case 3: p = quaternion(real = nan, imag = nan, jmag = nan, kmag = nan)
		}
		s := fmt.tprint(p)
		v, ok := strconv.parse_quaternion256(s)
		same := same_f64(real(v), real(p)) && same_f64(imag(v), imag(p)) && same_f64(jmag(v), jmag(p)) && same_f64(kmag(v), kmag(p))
		testing.expectf(t, ok && same, "%q -> %v, ok=%v", s, v, ok)
	}
}

@(test)
test_fix_unquote_string :: proc(t: ^testing.T) {
	Case :: struct {
		lit:  string,
		want: string,
		err:  strconv.Unquote_Error,
	}
	cases := [?]Case{
		{`"abc'`, "", .Missing_Quote},
		{`xabcx`, "", .Missing_Quote},
		{"`raw", "", .Missing_Quote},
		{`"`, "", .Missing_Quote},
		{`'ab'`, "", .Invalid_Rune_Literal},
		{`''`, "", .Invalid_Rune_Literal},
		{`'''`, "", .Unescaped_Quote},
		{`'\''`, "'", .None},
		{`'"'`, `"`, .None},
		{`"a"b"`, "", .Unescaped_Quote},
		{"\"a\nb\"", "", .Newline},
		{"\"ab\xffc\"", "", .Invalid_UTF8},
		{"\"a\\tb\xffc\"", "", .Invalid_UTF8},
		{"\"\\t\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\"", "", .Invalid_UTF8},
		{"`a\xffb`", "", .Invalid_UTF8},
		{`"\UFFFFFFFF"`, "", .Invalid_Escape},
		{`"\U80000000"`, "", .Invalid_Escape},
		{`"\U00110000"`, "", .Invalid_Escape},
		{`"\U0010ffff"`, "\U0010ffff", .None},
		{`"\101B"`, "AB", .None},
		{`"\0601"`, "01", .None},
		{`"\101"`, "A", .None},
		{`"\400"`, "", .Invalid_Escape},
		{`"\e"`, "\x1b", .None},
		{`"\xff"`, "\xff", .None},
		{`'\xff'`, "\u00ff", .None},
		{`'\101'`, "A", .None},
	}
	for c in cases {
		s, allocated, err := strconv.unquote_string(c.lit)
		testing.expectf(t, s == c.want && unquote_err(err) == c.err, "unquote_string(%q) = %q, %v; want %q, %v", c.lit, s, err, c.want, c.err)
		if allocated {
			delete(s)
		}
	}

	esc: [8]byte
	q := strconv.quote_string_buf(esc[:], "\x1b")
	s, allocated, err := strconv.unquote_string(q)
	testing.expectf(t, err == nil && s == "\x1b", "unquote_string(quote_string(ESC)) = %q, %v (quoted %s)", s, err, q)
	if allocated {
		delete(s)
	}
}

@(test)
test_fix_unquote_string_triple_quoted :: proc(t: ^testing.T) {
	Case :: struct {
		lit:  string,
		want: string,
		err:  strconv.Unquote_Error,
	}
	cases := [?]Case{
		{`""""""`, "", .None},
		{"``````", "", .None},
		{`"""a"b"""`, `a"b`, .None},
		{`"""a\tb"""`, "a\tb", .None},
		{"```a\\tb```", `a\tb`, .None},
		{`"""a\""""`, `a"`, .None},
		{"\"\"\"\n\tx\n\t  y\n\n\t\"\"\"", "x\n  y\n", .None},
		{"```\r\n\tx\r\n\t```", "x", .None},
		{"\"\"\"\n\tx\\ty\n\t\"\"\"", "x\ty", .None},
		{"```\n\ta\\tb\n\t```", `a\tb`, .None},
		{"\"\"\"\n\t\"\"\"", "", .None},
		{"\"\"\" \t\n\tx\n\t\"\"\"", "x", .None},
		{`"""`, "", .Missing_Quote},
		{`"""""`, "", .Missing_Quote},
		{`"""a\"""`, "", .Missing_Quote},
		{`"""a"""b"""`, "", .Unescaped_Quote},
		{"```a```b```", "", .Unescaped_Quote},
		{"\"\"\"x\n\"\"\"", "", .Content_On_Opening_Line},
		{"\"\"\"\n\tx\n\ty\"\"\"", "", .Closing_Not_On_Own_Line},
		{"\"\"\"\n x\n\t\"\"\"", "", .Indentation_Mismatch},
		{"\"\"\"\nx\n\t\"\"\"", "", .Under_Indented},
		{"\"\"\"\n\tx\\q\n\t\"\"\"", "", .Invalid_Escape},
		{"\"\"\"a\xffb\"\"\"", "", .Invalid_UTF8},
	}
	for c in cases {
		s, allocated, err := strconv.unquote_string(c.lit)
		testing.expectf(t, s == c.want && unquote_err(err) == c.err, "unquote_string(%q) = %q, %v; want %q, %v", c.lit, s, err, c.want, c.err)
		if allocated {
			delete(s)
		}
	}
}

@(test)
test_fix_unquote_char :: proc(t: ^testing.T) {
	r, multiple_bytes, tail, err := strconv.unquote_char("", '"')
	testing.expectf(t, err == .Empty_Input && r == 0 && !multiple_bytes && tail == "", "unquote_char(\"\") = %v, %v, %q, %v", r, multiple_bytes, tail, err)
	r, multiple_bytes, tail, err = strconv.unquote_char(`'x`, '\'')
	testing.expectf(t, err == .Unescaped_Quote, "unquote_char(`'x`, '\\'') = %v, %v, %q, %v", r, multiple_bytes, tail, err)
	r, multiple_bytes, tail, err = strconv.unquote_char(`"x`, '"')
	testing.expectf(t, err == .Unescaped_Quote, "unquote_char(`\"x`, '\"') = %v, %v, %q, %v", r, multiple_bytes, tail, err)
	r, multiple_bytes, tail, err = strconv.unquote_char(`\101B`, '"')
	testing.expectf(t, err == .None && r == 'A' && tail == "B", "unquote_char(`\\101B`) = %v, %v, %q, %v", r, multiple_bytes, tail, err)
}

@(test)
test_fix_unquote_string_allocation_failure :: proc(t: ^testing.T) {
	oom := runtime.Allocator{procedure = oom_allocator_proc}
	s, allocated, err := strconv.unquote_string(`"a\tb"`, oom)
	alloc_err, is_alloc_err := err.(runtime.Allocator_Error)
	testing.expectf(t, is_alloc_err && alloc_err == .Out_Of_Memory && s == "" && !allocated, "got %q, %v, %v", s, allocated, err)
}

@(test)
test_fix_ini_quoted_values :: proc(t: ^testing.T) {
	src := "[s]\nbad = \"\\t\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\"\nsingle = 'a\\tb'\ndouble = \"a\\tb\"\n"
	m, err := ini.load_map_from_string(src, context.temp_allocator)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, m["s"]["bad"], "\"\\t\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\"")
	testing.expect_value(t, m["s"]["single"], `a\tb`)
	testing.expect_value(t, m["s"]["double"], "a\tb")
}

@(test)
test_fix_write_bits_128_no_decimal_prefix :: proc(t: ^testing.T) {
	buf: [140]byte
	testing.expect_value(t, strconv.write_bits_128(buf[:], 42, 10, false, 64, strconv.digits, {.Prefix}), "42")
	testing.expect_value(t, strconv.write_bits(buf[:], 42, 10, false, 64, strconv.digits, {.Prefix}), "42")
	testing.expect_value(t, strconv.write_bits_128(buf[:], 42, 16, false, 64, strconv.digits, {.Prefix}), "0x2a")
}

when !testing.INLINE {
	@(test)
	test_fix_parse_of_base_zero_base :: proc(t: ^testing.T) {
		testing.expect_assert(t, "base must be 1-16")
		_, _ = strconv.parse_u64_of_base("1", 0)
	}

	@(test)
	test_fix_parse_of_base_negative_base :: proc(t: ^testing.T) {
		testing.expect_assert(t, "base must be 1-16")
		_, _ = strconv.parse_i128_of_base("1", -1)
	}
}

@(test)
test_fix_cbor_diagnostic_large_f64 :: proc(t: ^testing.T) {
	m, e2 := f64_parts(transmute(u64)f64(1e300))
	want := cat(digits_times_pow2(m, e2), ".0000000000000000")
	got, err := cbor.to_diagnostic_format_string(f64(1e300), allocator = context.temp_allocator)
	testing.expect_value(t, err, nil)
	testing.expect_value(t, got, want)
}

@(test)
test_fix_fmt_float_large_precision :: proc(t: ^testing.T) {
	m, e2 := f64_parts(transmute(u64)f64(1e308))
	i308 := digits_times_pow2(m, e2)
	testing.expect_value(t, fmt.tprintf("%.100f", f64(1e308)), cat(i308, ".", zeros(100)))

	m, e2 = f64_parts(transmute(u64)f64(1e300))
	i300 := digits_times_pow2(m, e2)
	e400 := cat(i300[:1], ".", i300[1:], zeros(400 - (len(i300) - 1)), "e+300")
	testing.expect_value(t, fmt.tprintf("%.400e", f64(1e300)), e400)
	testing.expect_value(t, fmt.tprintf("%.390f", 1.0), cat("1.", zeros(390)))
	testing.expect_value(t, fmt.tprintf("%0410.400f", -1.0), cat("-", zeros(7), "1.", zeros(400)))
	testing.expect_value(t, fmt.tprintf("%420.400e", 1.0), cat(strings.repeat(" ", 14, context.temp_allocator), "1.", zeros(400), "e+00"))
	testing.expect_value(t, fmt.tprintf("%-420.400e|", 1.0), cat("1.", zeros(400), "e+00", strings.repeat(" ", 14, context.temp_allocator), "|"))

	sb := strings.builder_make(context.temp_allocator)
	strings.write_float(&sb, f64(1e300), 'e', 400, 64)
	testing.expect_value(t, strings.to_string(sb), e400)
	strings.builder_reset(&sb)
	strings.write_float(&sb, 1.0, 'f', 390, 64)
	testing.expect_value(t, strings.to_string(sb), cat("1.", zeros(390)))

	d := digits_times_pow5(1, 1074)
	tiny := transmute(f64)u64(1)
	e800 := cat(d[:1], ".", d[1:], zeros(800 - (len(d) - 1)), "e-324")
	f1100 := cat("0.", zeros(1074 - len(d)), d, zeros(26))
	testing.expect_value(t, fmt.tprintf("%.800e", tiny), e800)
	testing.expect_value(t, fmt.tprintf("%.1100f", tiny), f1100)
	strings.builder_reset(&sb)
	strings.write_float(&sb, tiny, 'e', 800, 64)
	testing.expect_value(t, strings.to_string(sb), e800)
	strings.builder_reset(&sb)
	strings.write_float(&sb, tiny, 'f', 1100, 64)
	testing.expect_value(t, strings.to_string(sb), f1100)
}

@(test)
test_fix_fmt_memory_large_precision :: proc(t: ^testing.T) {
	unit := fmt.tprintf("%.0m", 2048)[1:]
	testing.expect_value(t, fmt.tprintf("%.252m", 2048), cat("2.", zeros(252), unit))
	testing.expect_value(t, fmt.tprintf("%.400m", 2048), cat("2.", zeros(400), unit))
}

@(test)
test_fix_fmt_int_large_width :: proc(t: ^testing.T) {
	spaces := strings.repeat(" ", 299, context.temp_allocator)
	testing.expect_value(t, fmt.tprintf("%300d", 1), cat(spaces, "1"))
	testing.expect_value(t, fmt.tprintf("%-300d|", 1), cat("1", spaces, "|"))
	testing.expect_value(t, fmt.tprintf("%0300d", -5), cat("-", zeros(298), "5"))
	testing.expect_value(t, fmt.tprintf("%300d", i128(1)), cat(spaces, "1"))
	testing.expect_value(t, fmt.tprintf("%0300d", u128(5)), cat(zeros(299), "5"))
}

@(test)
test_fix_write_int_small_buffer :: proc(t: ^testing.T) {
	buf: [2]byte
	s, ok := strconv.write_int(buf[:], -42, 10)
	testing.expectf(t, s == "-4" && !ok, "write_int: %q, %v", s, ok)
	s, ok = strconv.write_uint(buf[:], 123, 10)
	testing.expectf(t, s == "12" && !ok, "write_uint: %q, %v", s, ok)
	s, ok = strconv.write_u128(buf[:], 123, 10)
	testing.expectf(t, s == "12" && !ok, "write_u128: %q, %v", s, ok)
	s, ok = strconv.write_bits(buf[:], 255, 16, false, 64, strconv.digits, {.Prefix})
	testing.expectf(t, s == "0x" && !ok, "write_bits: %q, %v", s, ok)
	s, ok = strconv.write_bits_128(buf[:], 255, 16, false, 64, strconv.digits, {.Prefix})
	testing.expectf(t, s == "0x" && !ok, "write_bits_128: %q, %v", s, ok)
	s, ok = strconv.write_bool(buf[:], true)
	testing.expectf(t, s == "tr" && !ok, "write_bool: %q, %v", s, ok)
	s, ok = strconv.write_float(buf[:], 1.5, 'f', 2, 64, nil)
	testing.expectf(t, s == "1." && !ok, "write_float: %q, %v", s, ok)

	fit: [3]byte
	s, ok = strconv.write_int(fit[:], -42, 10)
	testing.expectf(t, s == "-42" && ok, "write_int into 3 bytes: %q, %v", s, ok)
	s, ok = strconv.write_float(fit[:], 1.5, 'f', 1, 64, nil)
	testing.expectf(t, s == "1.5" && ok, "write_float into 3 bytes: %q, %v", s, ok)

	sb := strings.builder_make(context.temp_allocator)
	strings.write_u64(&sb, max(u64), 2)
	testing.expect_value(t, strings.to_string(sb), strings.repeat("1", 64, context.temp_allocator))
	strings.builder_reset(&sb)
	strings.write_i64(&sb, min(i64), 2)
	testing.expect_value(t, strings.to_string(sb), cat("-1", zeros(63)))
}

@(test)
test_fix_parse_int_n_without_digits :: proc(t: ^testing.T) {
	Case :: struct {
		s:  string,
		n:  int,
		ok: bool,
	}
	signed := [?]Case{
		{"0xZZ", 1, false},
		{"-0xZZ", 2, false},
		{"0x_", 1, false},
		{"-Z", 0, false},
		{"-", 0, false},
		{"___", 0, false},
		{"0x", 1, false},
		{"+0b", 2, false},
		{"12z", 2, false},
		{"0x1_f", 5, true},
	}
	for c in signed {
		n: int
		_, ok := strconv.parse_i64_maybe_prefixed(c.s, &n)
		testing.expectf(t, n == c.n && ok == c.ok, "parse_i64_maybe_prefixed(%q): n=%d ok=%v, want n=%d ok=%v", c.s, n, ok, c.n, c.ok)
		_, ok = strconv.parse_i128_maybe_prefixed(c.s, &n)
		testing.expectf(t, n == c.n && ok == c.ok, "parse_i128_maybe_prefixed(%q): n=%d ok=%v, want n=%d ok=%v", c.s, n, ok, c.n, c.ok)
		_, ok = strconv.parse_int(c.s, 0, &n)
		testing.expectf(t, n == c.n && ok == c.ok, "parse_int(%q): n=%d ok=%v, want n=%d ok=%v", c.s, n, ok, c.n, c.ok)
	}
	unsigned := [?]Case{
		{"0xZZ", 1, false},
		{"+0xZZ", 2, false},
		{"-0xZZ", 0, false},
		{"___", 0, false},
		{"12z", 2, false},
	}
	for c in unsigned {
		n: int
		_, ok := strconv.parse_u64_maybe_prefixed(c.s, &n)
		testing.expectf(t, n == c.n && ok == c.ok, "parse_u64_maybe_prefixed(%q): n=%d ok=%v, want n=%d ok=%v", c.s, n, ok, c.n, c.ok)
		_, ok = strconv.parse_u128_maybe_prefixed(c.s, &n)
		testing.expectf(t, n == c.n && ok == c.ok, "parse_u128_maybe_prefixed(%q): n=%d ok=%v, want n=%d ok=%v", c.s, n, ok, c.n, c.ok)
		_, ok = strconv.parse_uint(c.s, 0, &n)
		testing.expectf(t, n == c.n && ok == c.ok, "parse_uint(%q): n=%d ok=%v, want n=%d ok=%v", c.s, n, ok, c.n, c.ok)
	}
	of_base := [?]Case{
		{"-Z", 0, false},
		{"___", 0, false},
		{"12z", 2, false},
		{"_1_", 3, true},
	}
	for c in of_base {
		n: int
		_, ok := strconv.parse_i64_of_base(c.s, 10, &n)
		testing.expectf(t, n == c.n && ok == c.ok, "parse_i64_of_base(%q): n=%d ok=%v, want n=%d ok=%v", c.s, n, ok, c.n, c.ok)
		_, ok = strconv.parse_u128_of_base(c.s, 10, &n)
		testing.expectf(t, n == c.n && ok == c.ok, "parse_u128_of_base(%q): n=%d ok=%v, want n=%d ok=%v", c.s, n, ok, c.n, c.ok)
	}
}

@(test)
test_fix_parse_float_prefix_0h :: proc(t: ^testing.T) {
	v, nr, ok := strconv.parse_f64_prefix("0h3ff0000000000000 rest")
	testing.expectf(t, v == 1 && nr == 18 && ok, "got %v, %d, %v", v, nr, ok)
	v, nr, ok = strconv.parse_f64_prefix("-0h3ff0000000000000")
	testing.expectf(t, v == -1 && nr == 19 && ok, "got %v, %d, %v", v, nr, ok)
	v32, nr32, ok32 := strconv.parse_f32_prefix("0h3f800000x")
	testing.expectf(t, v32 == 1 && nr32 == 10 && ok32, "got %v, %d, %v", v32, nr32, ok32)
}

@(test)
test_fix_parse_float_prefix_like_strtod :: proc(t: ^testing.T) {
	Case :: struct {
		s:    string,
		bits: u64,
		nr:   int,
	}
	cases := [?]Case{
		{"1.5e+", 0x3ff8000000000000, 3},
		{"1.5e", 0x3ff8000000000000, 3},
		{"12.34eee", 0x4028ae147ae147ae, 5},
		{"+nan", 0x7ff8000000000001, 4},
		{"-nan", 0xfff8000000000001, 4},
		{"nan(123)x", 0x7ff8000000000001, 8},
		{"nan(1 2)", 0x7ff8000000000001, 3},
		{"0x1.8", 0x3ff8000000000000, 5},
		{"0x1.8p", 0x3ff8000000000000, 5},
		{"0x1.8p+z", 0x3ff8000000000000, 5},
		{"0xg", 0x0000000000000000, 1},
		{"-0xg", 0x8000000000000000, 2},
	}
	for c in cases {
		v, nr, ok := strconv.parse_f64_prefix(c.s)
		testing.expectf(t, ok && transmute(u64)v == c.bits && nr == c.nr, "parse_f64_prefix(%q) = %016x, %d, %v; want %016x, %d", c.s, transmute(u64)v, nr, ok, c.bits, c.nr)
	}
}

@(test)
test_fix_write_string16_buf_clips_whole_runes :: proc(t: ^testing.T) {
	buf: [2]byte
	s16: string16 = "aé"
	s, ok := strconv.write_string16_buf(buf[:], s16)
	testing.expectf(t, s == "a" && !ok, "got %v, %v", transmute([]byte)s, ok)
}

@(test)
test_fix_decimal_to_string_sign :: proc(t: ^testing.T) {
	d: decimal.Decimal
	testing.expect(t, decimal.set(&d, "-1.5"))
	buf: [32]byte
	testing.expect_value(t, decimal.decimal_to_string(buf[:], &d), "-1.5")
}
