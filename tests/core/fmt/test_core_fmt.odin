package test_core_fmt

import "base:runtime"
import "core:fmt"
import "core:math"
import "core:mem"
import "core:testing"

@(test)
test_fmt_memory :: proc(t: ^testing.T) {
	check(t, "5b",        "%m",    5)
	check(t, "5B",        "%M",    5)
	check(t, "-5B",       "%M",    -5)
	check(t, "3.00kib",   "%m",    mem.Kilobyte * 3)
	check(t, "3kib",      "%.0m",  mem.Kilobyte * 3)
	check(t, "3KiB",      "%.0M",  mem.Kilobyte * 3)
	check(t, "3.000 mib", "%#.3m", mem.Megabyte * 3)
	check(t, "3.50 gib",  "%#m",   u32(mem.Gigabyte * 3.5))
	check(t, "01tib",     "%5.0m", mem.Terabyte)
	check(t, "-1tib",     "%5.0m", -mem.Terabyte)
	check(t, "2 pib",     "%#5.m", uint(mem.Petabyte * 2.5))
	check(t, "1.00 EiB",  "%#M",   mem.Exabyte)
	check(t, "255 B",     "%#M",   u8(255))
	check(t, "0b",        "%m",    u8(0))
}

@(test)
test_fmt_complex_quaternion :: proc(t: ^testing.T) {
	neg_inf  := math.inf_f64(-1)
	pos_inf  := math.inf_f64(+1)
	neg_zero := f64(0h80000000_00000000)
	nan      := math.nan_f64()

	// NOTE(Feoramund): Doing it this way, because complex construction is broken.
	// Reported in issue #3665.
	c: complex128
	cptr := cast(^runtime.Raw_Complex128)&c

	cptr^ = {0, 0}
	check(t, "0+0i",      "%v", c)
	cptr^ = {1, 1}
	check(t, "1+1i",      "%v", c)
	cptr^ = {1, 0}
	check(t, "1+0i",      "%v", c)
	cptr^ = {-1, -1}
	check(t, "-1-1i",     "%v", c)
	cptr^ = {0, neg_zero}
	check(t, "0-0i",      "%v", c)
	cptr^ = {nan, nan}
	check(t, "NaNNaNi",   "%v", c)
	cptr^ = {pos_inf, pos_inf}
	check(t, "+Inf+Infi", "%v", c)
	cptr^ = {neg_inf, neg_inf}
	check(t, "-Inf-Infi", "%v", c)

	// Check forced plus signs.
	cptr^ = {0, neg_zero}
	check(t, "+0-0i",     "%+v", c)
	cptr^ = {1, 1}
	check(t, "+1+1i",     "%+v", c)
	cptr^ = {nan, nan}
	check(t, "NaNNaNi",   "%+v", c)
	cptr^ = {pos_inf, pos_inf}
	check(t, "+Inf+Infi", "%+v", c)
	cptr^ = {neg_inf, neg_inf}
	check(t, "-Inf-Infi", "%+v", c)

	// Remember that the real number is the last in a quaternion's data layout,
	// opposed to a complex, where it is the first.
	q: quaternion256
	qptr := cast(^runtime.Raw_Quaternion256)&q

	qptr^ = {0, 0, 0, 0}
	check(t, "0+0i+0j+0k",        "%v", q)
	qptr^ = {1, 1, 1, 1}
	check(t, "1+1i+1j+1k",        "%v", q)
	qptr^ = {2, 3, 4, 1}
	check(t, "1+2i+3j+4k",        "%v", q)
	qptr^ = {-1, -1, -1, -1}
	check(t, "-1-1i-1j-1k",       "%v", q)
	qptr^ = {2, neg_zero, neg_zero, 1}
	check(t, "1+2i-0j-0k",        "%v", q)
	qptr^ = {neg_inf, neg_inf, neg_inf, -1}
	check(t, "-1-Infi-Infj-Infk", "%v", q)
	qptr^ = {pos_inf, pos_inf, pos_inf, -1}
	check(t, "-1+Infi+Infj+Infk", "%v", q)
	qptr^ = {nan, nan, nan, -1}
	check(t, "-1NaNiNaNjNaNk",    "%v", q)
}

@(test)
test_fmt_doc_examples :: proc(t: ^testing.T) {
	// C-like syntax
	check(t, "37 13",  "%[1]d %[0]d",    13,   37)
	check(t, "017.00", "%*[2].*[1][0]f", 17.0, 2, 6)
	check(t, "017.00", "%6.2f",          17.0)

	 // Python-like syntax
	check(t, "37 13",  "{1:d} {0:d}",    13,   37)
	check(t, "017.00", "{0:*[2].*[1]f}", 17.0, 2, 6)
	check(t, "017.00", "{:6.2f}",        17.0)
}

@(test)
test_fmt_escaping_prefixes :: proc(t: ^testing.T) {
	// Escaping
	check(t, "% { } 0 { } } {", "%% {{ }} {} {{ }} }} {{", 0 )

	// Prefixes
	check(t, "+3.000", "%+f",   3.0 )
	check(t, "0003",   "%04i",  3 )
	check(t, "3   ",   "% -4i", 3 )
	check(t, "+3",     "%+i",   3 )
	check(t, "0b11",   "%#b",   3 )
	check(t, "0xA",    "%#X",   10 )
}

@(test)
test_fmt_indexing :: proc(t: ^testing.T) {
	// Specific index formatting
	check(t, "1 2 3", "%i %i %i",          1, 2, 3)
	check(t, "1 2 3", "%[0]i %[1]i %[2]i", 1, 2, 3)
	check(t, "3 2 1", "%[2]i %[1]i %[0]i", 1, 2, 3)
	check(t, "3 1 2", "%[2]i %i %i",       1, 2, 3)
	check(t, "1 2 3", "%i %[1]i %i",       1, 2, 3)
	check(t, "1 3 2", "%i %[2]i %i",       1, 2, 3)
	check(t, "1 1 1", "%[0]i %[0]i %[0]i", 1)
}

@(test)
test_fmt_width_precision :: proc(t: ^testing.T) {
	// Width
	check(t, "3.140",  "%f",  3.14)
	check(t, "3.140",  "%4f", 3.14)
	check(t, "3.140",  "%5f", 3.14)
	check(t, "03.140", "%6f", 3.14)

	// Precision
	check(t, "3",       "%.f",  3.14)
	check(t, "3",       "%.0f", 3.14)
	check(t, "3.1",     "%.1f", 3.14)
	check(t, "3.140",   "%.3f", 3.14)
	check(t, "3.14000", "%.5f", 3.14)

	check(t, "3.1415",  "%g",   3.1415)

	// Scientific notation
	check(t, "3.000000e+00", "%e",   3.0)

	check(t, "3e+02",        "%.e",  300.0)
	check(t, "3e+02",        "%.0e", 300.0)
	check(t, "3.0e+02",      "%.1e", 300.0)
	check(t, "3.00e+02",     "%.2e", 300.0)
	check(t, "3.000e+02",    "%.3e", 300.0)

	check(t, "3e+01",        "%.e",  30.56)
	check(t, "3e+01",        "%.0e", 30.56)
	check(t, "3.1e+01",      "%.1e", 30.56)
	check(t, "3.06e+01",     "%.2e", 30.56)
	check(t, "3.056e+01",    "%.3e", 30.56)

	// Width and precision
	check(t, "3.140", "%5.3f",          3.14)
	check(t, "3.140", "%*[1].3f",       3.14, 5)
	check(t, "3.140", "%*[1].*[2]f",    3.14, 5, 3)
	check(t, "3.140", "%*[1].*[2][0]f", 3.14, 5, 3)
	check(t, "3.140", "%*[2].*[1]f",    3.14, 3, 5)
	check(t, "3.140", "%5.*[1]f",       3.14, 3)
}

@(test)
test_fmt_arg_errors :: proc(t: ^testing.T) {
	// Error checking
	check(t, "%!(MISSING ARGUMENT)%!(NO VERB)", "%" )

	check(t, "1%!(EXTRA 2, 3)", "%i",    1, 2, 3)
	check(t, "2%!(EXTRA 1, 3)", "%[1]i", 1, 2, 3)

	check(t, "%!(BAD ARGUMENT NUMBER)%!(EXTRA 0)", "%[1]i", 0)

	check(t, "%!(MISSING ARGUMENT)",               "%f")
	check(t, "%!(BAD ARGUMENT NUMBER)%!(NO VERB)", "%[0]")
	check(t, "%!(BAD ARGUMENT NUMBER)",            "%[0]f")

	check(t, "%!(BAD ARGUMENT NUMBER)%!(NO VERB) %!(MISSING ARGUMENT)", "%[0] %i")

	check(t, "%!(NO VERB) 1%!(EXTRA 2)", "%[0] %i", 1, 2)

	check(t, "1 2 %!(MISSING ARGUMENT)",    "%i %i %i",    1, 2)
	check(t, "1 2 %!(BAD ARGUMENT NUMBER)", "%i %i %[2]i", 1, 2)

	check(t, "%!(BAD ARGUMENT NUMBER)%!(NO VERB)%!(EXTRA 0)", "%[1]", 0)

	check(t, "3.1%!(EXTRA 3.14)", "%.1f", 3.14, 3.14)
}

@(test)
test_fmt_python_syntax :: proc(t: ^testing.T) {
	// Python-like syntax
	check(t, "1 2 3", "{} {} {}",          1, 2, 3)
	check(t, "3 2 1", "{2} {1} {0}",       1, 2, 3)
	check(t, "1 2 3", "{:i} {:i} {:i}",    1, 2, 3)
	check(t, "1 2 3", "{0:i} {1:i} {2:i}", 1, 2, 3)
	check(t, "3 2 1", "{2:i} {1:i} {0:i}", 1, 2, 3)
	check(t, "3 1 2", "{2:i} {0:i} {1:i}", 1, 2, 3)
	check(t, "1 2 3", "{:i} {1:i} {:i}",   1, 2, 3)
	check(t, "1 3 2", "{:i} {2:i} {:i}",   1, 2, 3)
	check(t, "1 1 1", "{0:i} {0:i} {0:i}", 1)

	check(t, "1 1%!(EXTRA 2)", "{} {0}", 1, 2)
	check(t, "2 1", "{1} {}", 1, 2)
	check(t, "%!(BAD ARGUMENT NUMBER) 1%!(EXTRA 2)", "{2} {}", 1, 2)

	check(t, "%!(BAD ARGUMENT NUMBER)",                       "{1}")
	check(t, "%!(BAD ARGUMENT NUMBER)%!(NO VERB)",            "{1:}")
	check(t, "%!(BAD ARGUMENT NUMBER)%!(NO VERB)%!(EXTRA 0)", "{1:}", 0)

	check(t, "%!(MISSING ARGUMENT)",                        "{}" )
	check(t, "%!(MISSING ARGUMENT)%!(MISSING CLOSE BRACE)", "{" )
	check(t, "%!(MISSING CLOSE BRACE)%!(EXTRA 1)",          "{",  1)
	check(t, "%!(MISSING CLOSE BRACE)%!(EXTRA 1)",          "{0", 1 )
}

@(test)
test_pointers :: proc(t: ^testing.T) {
	S :: struct { i: int }
	a: rawptr
	b: ^int
	c: ^S
	d: ^S = cast(^S)cast(uintptr)0xFFFF

	check(t, "0x0", "%p", a)
	check(t, "0x0", "%p", b)
	check(t, "0x0", "%p", c)
	check(t, "0xFFFF", "%p", d)

	check(t, "0x0", "%#p", a)
	check(t, "0x0", "%#p", b)
	check(t, "0x0", "%#p", c)
	check(t, "0xFFFF", "%#p", d)

	check(t, "0x0",   "%v", a)
	check(t, "0x0",   "%v", b)
	check(t, "<nil>", "%v", c)

	check(t, "0x0",   "%#v", a)
	check(t, "0x0",   "%#v", b)
	check(t, "<nil>", "%#v", c)

	check(t, "0x0000", "%4p", a)
	check(t, "0x0000", "%4p", b)
	check(t, "0x0000", "%4p", c)
	check(t, "0xFFFF", "%4p", d)

	check(t, "0x0000", "%#4p", a)
	check(t, "0x0000", "%#4p", b)
	check(t, "0x0000", "%#4p", c)
	check(t, "0xFFFF", "%#4p", d)
}

@(test)
test_odin_value_export :: proc(t: ^testing.T) {
	E :: enum u32 {
		A, B, C,
	}

	F :: enum i16 {
		A, B, F,
	}

	S :: struct {
		j, k: int,
	}

	ST :: struct {
		x: int    `fmt:"-"`,
		y: u8     `fmt:"r,0"`,
		z: string `fmt:"s,0"`,
	}

	U :: union {
		i8,
		i16,
	}

	UEF :: union { E, F }

	A :: [2]int

	BSE :: distinct bit_set[E]

	i    : int                          = 64
	f    : f64                          = 3.14
	c    : complex128                   = 7+3i
	q    : quaternion256                = 1+2i+3j+4k
	mat  :               matrix[2,3]f32 = {1.5, 2, 1, 0.777, 0.333, 0.8}
	matc : #column_major matrix[2,3]f32 = {1.5, 2, 1, 0.777, 0.333, 0.8}
	e    : enum {A, B, C}               = .B
	en   : E                            = E.C
	ena  : [2]E                         = {E.A, E.C}
	s    : struct { j: int, k: int }    = { j = 16, k = 8 }
	sn   : S                            = S{ j = 24, k = 12 }
	st   : ST                           = { 32768, 57, "Hellope" }
	str  : string                       = "Hellope"
	strc : cstring                      = "Hellope"
	bsu  : bit_set[0..<32; u32]         = {0, 1}
	bs   : bit_set[4..<16]              = {5, 7}
	bse  : bit_set[E]                   = { .B, .A }
	bsE  : BSE                          = { .A, .C }
	arr  : [3]int                       = {1, 2, 3}
	ars  : [3]S                         = {S{j = 3, k = 2}, S{j = 2, k = 1}, S{j = 1, k = 0}}
	darr : [dynamic]u8                  = { 128, 64, 32 }
	dars : [dynamic]S                   = {S{j = 1, k = 2}, S{j = 3, k = 4}}
	na   : A                            = {7, 5}
	may0 : Maybe(int)
	may1 : Maybe(int)                   = 1
	uz   : union {i8, i16}              = i8(-33)
	u0   : U                            = U(nil)
	u1   : U                            = i16(42)
	uef0 : UEF                          = E.A
	uefa : [3]UEF                       = { E.A, F.A, F.F }
	map_ : map[string]u8                = {"foo" = 8, "bar" = 4}

	bf   : bit_field int {
		a: int | 4,
		b: int | 4,
		e: E   | 4,
	} = {a = 1, b = 2, e = .A}

	defer {
		delete(darr)
		delete(dars)
		delete(map_)
	}

	check(t, "64",                                                  "%w", i)
	check(t, "3.14",                                                "%w", f)
	check(t, "7+3i",                                                "%w", c)
	check(t, "1+2i+3j+4k",                                          "%w", q)
	check(t, "{1.5, 2, 1, 0.777, 0.333, 0.8}",                      "%w", mat)
	check(t, "{1.5, 2, 1, 0.777, 0.333, 0.8}",                      "%w", matc)
	check(t, ".B",                                                  "%w", e)
	check(t, "E.C",                                                 "%w", en)
	check(t, "{E.A, E.C}",                                          "%w", ena)
	check(t, "{j = 16, k = 8}",                                     "%w", s)
	check(t, "S{j = 24, k = 12}",                                   "%w", sn)
	check(t, `ST{y = 57, z = "Hellope"}`,                           "%w", st)
	check(t, `"Hellope"`,                                           "%w", str)
	check(t, `"Hellope"`,                                           "%w", strc)
	check(t, "{0, 1}",                                              "%w", bsu)
	check(t, "{5, 7}",                                              "%w", bs)
	check(t, "{E.A, E.B}",                                          "%w", bse)
	check(t, "{E.A, E.C}",                                          "%w", bsE)
	check(t, "{1, 2, 3}",                                           "%w", arr)
	check(t, "{S{j = 3, k = 2}, S{j = 2, k = 1}, S{j = 1, k = 0}}", "%w", ars)
	check(t, "{128, 64, 32}",                                       "%w", darr)
	check(t, "{S{j = 1, k = 2}, S{j = 3, k = 4}}",                  "%w", dars)
	check(t, "{7, 5}",                                              "%w", na)
	check(t, "nil",                                                 "%w", may0)
	check(t, "1",                                                   "%w", may1)
	check(t, "-33",                                                 "%w", uz)
	check(t, "nil",                                                 "%w", u0)
	check(t, "42",                                                  "%w", u1)
	check(t, "E.A",                                                 "%w", uef0)
	check(t, "{E.A, F.A, F.F}",                                     "%w", uefa)
	check(t, "{a = 1, b = 2, e = E.A}",                             "%w", bf)
	// Check this manually due to the non-deterministic ordering of map keys.
	switch fmt.tprintf("%w", map_) {
	case `{"foo"=8, "bar"=4}`: break
	case `{"bar"=4, "foo"=8}`: break
	case: testing.fail(t)
	}
}

@(test)
leaking_struct_tag :: proc(t: ^testing.T) {
	My_Struct :: struct {
		names:      [^]string `fmt:"v,name_count"`,
		name_count: int,
	}

	name := "hello?"
	foo := My_Struct {
		names = &name,
		name_count = 1,
	}

	check(t, "My_Struct{names = [\"hello?\"], name_count = 1}", "%v", foo)
}

@(private)
check :: proc(t: ^testing.T, exp: string, format: string, args: ..any, loc := #caller_location) {
	got := fmt.tprintf(format, ..args)
	testing.expectf(t, got == exp, "(%q, %v): %q != %q", format, args, got, exp, loc = loc)
}
