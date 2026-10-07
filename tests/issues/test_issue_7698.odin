// Test https://github.com/odin-lang/Odin/issues/7698 - incorrect quaternion formatting
package test_issues

import "core:fmt"
import "core:testing"
import "core:log"
import "core:math"

@(private="file")
Test_Tuple :: struct {
	q: quaternion256,
	expected_normal: string,
	expected_with_plus: string,
}

@(test)
test_issue_7698 :: proc(t: ^testing.T) {
	quaternions := []Test_Tuple {
		{ +1+1i+1j+1k, "  1.000 +1.000i +1.000j +1.000k", " +1.000 +1.000i +1.000j +1.000k" },
		{ +1+1i+1j-1k, "  1.000 +1.000i +1.000j -1.000k", " +1.000 +1.000i +1.000j -1.000k" },
		{ +1+1i-1j+1k, "  1.000 +1.000i -1.000j +1.000k", " +1.000 +1.000i -1.000j +1.000k" },
		{ +1+1i-1j-1k, "  1.000 +1.000i -1.000j -1.000k", " +1.000 +1.000i -1.000j -1.000k" },
		{ +1-1i+1j+1k, "  1.000 -1.000i +1.000j +1.000k", " +1.000 -1.000i +1.000j +1.000k" },
		{ +1-1i+1j-1k, "  1.000 -1.000i +1.000j -1.000k", " +1.000 -1.000i +1.000j -1.000k" },
		{ +1-1i-1j+1k, "  1.000 -1.000i -1.000j +1.000k", " +1.000 -1.000i -1.000j +1.000k" },
		{ +1-1i-1j-1k, "  1.000 -1.000i -1.000j -1.000k", " +1.000 -1.000i -1.000j -1.000k" },
		{ -1+1i+1j+1k, " -1.000 +1.000i +1.000j +1.000k", " -1.000 +1.000i +1.000j +1.000k" },
		{ -1+1i+1j-1k, " -1.000 +1.000i +1.000j -1.000k", " -1.000 +1.000i +1.000j -1.000k" },
		{ -1+1i-1j+1k, " -1.000 +1.000i -1.000j +1.000k", " -1.000 +1.000i -1.000j +1.000k" },
		{ -1+1i-1j-1k, " -1.000 +1.000i -1.000j -1.000k", " -1.000 +1.000i -1.000j -1.000k" },
		{ -1-1i+1j+1k, " -1.000 -1.000i +1.000j +1.000k", " -1.000 -1.000i +1.000j +1.000k" },
		{ -1-1i+1j-1k, " -1.000 -1.000i +1.000j -1.000k", " -1.000 -1.000i +1.000j -1.000k" },
		{ -1-1i-1j+1k, " -1.000 -1.000i -1.000j +1.000k", " -1.000 -1.000i -1.000j +1.000k" },
		{ -1-1i-1j-1k, " -1.000 -1.000i -1.000j -1.000k", " -1.000 -1.000i -1.000j -1.000k" },
		{ quaternion(real = math.INF_F64,    imag =  math.INF_F64,   jmag =  math.INF_F64,   kmag =  math.INF_F64),   "   +Inf   +Infi   +Infj   +Infk",                         "   +Inf   +Infi   +Infj   +Infk" },
		{ quaternion(real = -math.INF_F64,   imag = -math.INF_F64,   jmag = -math.INF_F64,   kmag = -math.INF_F64),   "   -Inf   -Infi   -Infj   -Infk",                         "   -Inf   -Infi   -Infj   -Infk" },
		{ quaternion(real = math.nan_f64(),  imag =  math.nan_f64(), jmag =  math.nan_f64(), kmag =  math.nan_f64()), "    NaN   +NaNi   +NaNj   +NaNk",                         "    NaN   +NaNi   +NaNj   +NaNk" },
		{ quaternion(real = 0,               imag =  0,              jmag =  0,              kmag =  0),              "  0.000 +0.000i +0.000j +0.000k",                         " +0.000 +0.000i +0.000j +0.000k" },
		{ quaternion(real = -0.0,            imag = -0.0,            jmag = -0.0,            kmag = -0.0),            " -0.000 -0.000i -0.000j -0.000k",                         " -0.000 -0.000i -0.000j -0.000k" },
		{ quaternion(real = 99999999.9,      imag =  99999999.9,     jmag =  99999999.9,     kmag =  99999999.9),     "99999999.900+99999999.900i+99999999.900j+99999999.900k",  "+99999999.900+99999999.900i+99999999.900j+99999999.900k" },
		{ quaternion(real = -99999999.9,     imag = -99999999.9,     jmag = -99999999.9,     kmag = -99999999.9),     "-99999999.900-99999999.900i-99999999.900j-99999999.900k", "-99999999.900-99999999.900i-99999999.900j-99999999.900k" },
	}
	for tuple in quaternions {
		{
			candidate := fmt.tprintf("% 7f", tuple.q)
			testing.expect_value(t, candidate, tuple.expected_normal)
		}
		{
			candidate := fmt.tprintf("% +7f", tuple.q)
			testing.expect_value(t, candidate, tuple.expected_with_plus)
		}
		log.debugf("% 7f", tuple.q)
	}
}

@(test)
test_issue_7698__hex :: proc(t: ^testing.T) {
	// This is an edge case because normally, fmt_float will disable the `+` sign.
	q := quaternion256(+1+1i-1j+1k)
	s := fmt.tprintf("%+h", q)
	log.debugf(s)
	testing.expect_value(t, s, "0h3ff0000000000000+0h3ff0000000000000i+0hbff0000000000000j+0h3ff0000000000000k")
}

@(test)
test_issue_7698__lower_precision_hex :: proc(t: ^testing.T) {
	testing.expect_value(t, fmt.tprintf("%h", complex32(1+1i)), "0h3c00+0h3c00i")
	testing.expect_value(t, fmt.tprintf("%h", complex64(1+1i)), "0h3f800000+0h3f800000i")
	testing.expect_value(t, fmt.tprintf("%h", quaternion64(1+1i-1j+1k)), "0h3c00+0h3c00i+0hbc00j+0h3c00k")
	testing.expect_value(t, fmt.tprintf("%h", quaternion128(1+1i-1j+1k)), "0h3f800000+0h3f800000i+0hbf800000j+0h3f800000k")
}
