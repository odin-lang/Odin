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

@(private)
check :: proc(t: ^testing.T, exp: string, format: string, args: ..any) {
	got := fmt.tprintf(format, ..args)
	testing.expectf(t, got == exp, "(%q, %v): %q != %q", format, args, got, exp)
}