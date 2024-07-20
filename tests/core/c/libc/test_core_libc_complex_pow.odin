package test_core_libc

import "core:testing"
import "core:c/libc"
import "core:log"

reldiff :: proc(lhs, rhs: $T) -> f64  {
	if lhs == rhs {
		return 0.
	}
	amean := f64((abs(lhs)+abs(rhs)) / 2.)
	adiff := f64(abs(lhs - rhs))
	out := adiff / amean
	return out
}

isclose :: proc(t: ^testing.T, lhs, rhs: $T, rtol:f64 = 1e-12, atol:f64 = 1e-12) -> bool {
	adiff := f64(abs(lhs - rhs))
	if adiff < atol { 
		return true
	}
	rdiff := reldiff(lhs, rhs)
	if rdiff < rtol {
		return true
	}
	log.infof("not close -- lhs:%v rhs:%v -- adiff:%e   rdiff:%e\n",lhs, rhs, adiff, rdiff)
	return false
}

// declaring here so they can be used as function pointers

libc_pow :: proc(x, y: libc.complex_double) -> libc.complex_double {
	return libc.pow(x,y)
}

libc_powf :: proc(x, y: libc.complex_float) -> libc.complex_float {
	return libc.pow(x,y)
}

@test
test_libc_complex :: proc(t: ^testing.T) {
	test_libc_pow_binding(t, libc.complex_double, f64, libc_pow, 1e-12, 1e-12)
	// f32 needs more atol for comparing values close to zero
	test_libc_pow_binding(t, libc.complex_float, f32, libc_powf, 1e-12, 1e-5)
}

test_libc_pow_binding :: proc(t: ^testing.T, $LIBC_COMPLEX:typeid, $F:typeid, pow: proc(LIBC_COMPLEX, LIBC_COMPLEX) -> LIBC_COMPLEX, 
                              rtol: f64, atol: f64) {
	// Tests that c/libc/pow(f) functions have two arguments and that the function works as expected for simple inputs
	{
		// tests 2^n
		expected_real : F = 1./16.
		expected_imag : F = 0.
		complex_base := LIBC_COMPLEX(complex(F(2.), F(0.)))
		for n in -4..=4 {
			complex_power := LIBC_COMPLEX(complex(F(n), F(0.)))
			result := pow(complex_base, complex_power) 
			testing.expectf(t, isclose(t, expected_real, F(real(result)), rtol, atol), "ftype:%T, n:%v reldiff(%v, re(%v)) is greater than specified rtol:%e", F{}, n, expected_real, result, rtol)
			testing.expectf(t, isclose(t, expected_imag, F(imag(result)), rtol, atol), "ftype:%T, n:%v reldiff(%v, im(%v)) is greater than specified rtol:%e", F{}, n, expected_imag, result, rtol)
			expected_real *= 2
		}
	}
	{
		// tests (2i)^n
		value : F = 1/16.
		expected_real, expected_imag : F
		complex_base := LIBC_COMPLEX(complex(F(0.), F(2.)))
		for n in -4..=4 {
			complex_power := LIBC_COMPLEX(complex(F(n), F(0.)))
			result := pow(complex_base, complex_power) 
			switch n%%4 {
				case 0:
					expected_real = value
					expected_imag = 0.
				case 1:
					expected_real = 0.
					expected_imag = value
				case 2:
					expected_real = -value
					expected_imag = 0.
				case 3:
					expected_real = 0.
					expected_imag = -value
			}
			testing.expectf(t, isclose(t, expected_real, F(real(result)), rtol, atol), "ftype:%T, n:%v reldiff(%v, re(%v)) is greater than specified rtol:%e", F{}, n, expected_real, result, rtol)
			testing.expectf(t, isclose(t, expected_imag, F(imag(result)), rtol, atol), "ftype:%T, n:%v reldiff(%v, im(%v)) is greater than specified rtol:%e", F{}, n, expected_imag, result, rtol)
			value *= 2
		}
	}
}