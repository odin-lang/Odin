package math_linalg_hlsl

import "core:math"

@(require_results) cos_float         :: proc "c" (x: float)    -> float { return math.cos(x) }
@(require_results) sin_float         :: proc "c" (x: float)    -> float { return math.sin(x) }
@(require_results) tan_float         :: proc "c" (x: float)    -> float { return math.tan(x) }
@(require_results) acos_float        :: proc "c" (x: float)    -> float { return math.acos(x) }
@(require_results) asin_float        :: proc "c" (x: float)    -> float { return math.asin(x) }
@(require_results) atan_float        :: proc "c" (x: float)    -> float { return math.atan(x) }
@(require_results) atan2_float       :: proc "c" (y, x: float) -> float { return math.atan2(y, x) }
@(require_results) cosh_float        :: proc "c" (x: float)    -> float { return math.cosh(x) }
@(require_results) sinh_float        :: proc "c" (x: float)    -> float { return math.sinh(x) }
@(require_results) tanh_float        :: proc "c" (x: float)    -> float { return math.tanh(x) }
@(require_results) acosh_float       :: proc "c" (x: float)    -> float { return math.acosh(x) }
@(require_results) asinh_float       :: proc "c" (x: float)    -> float { return math.asinh(x) }
@(require_results) atanh_float       :: proc "c" (x: float)    -> float { return math.atanh(x) }
@(require_results) sqrt_float        :: proc "c" (x: float)    -> float { return math.sqrt(x) }
@(require_results) rsqrt_float       :: proc "c" (x: float)    -> float { return 1.0/math.sqrt(x) }
@(require_results) rcp_float         :: proc "c" (x: float)    -> float { return 1.0/x }
@(require_results) pow_float         :: proc "c" (x, y: float) -> float { return math.pow(x, y) }
@(require_results) exp_float         :: proc "c" (x: float)    -> float { return math.exp(x) }
@(require_results) log_float         :: proc "c" (x: float)    -> float { return math.ln(x) }
@(require_results) log2_float        :: proc "c" (x: float)    -> float { return math.log(x, 2) }
@(require_results) log10_float       :: proc "c" (x: float)    -> float { return math.log(x, 10) }
@(require_results) exp2_float        :: proc "c" (x: float)    -> float { return math.pow(float(2), x) }
@(require_results) sign_float        :: proc "c" (x: float)    -> float { return math.sign(x) }
@(require_results) floor_float       :: proc "c" (x: float)    -> float { return math.floor(x) }
@(require_results) round_float       :: proc "c" (x: float)    -> float { return math.round(x) }
@(require_results) ceil_float        :: proc "c" (x: float)    -> float { return math.ceil(x) }
@(require_results) isnan_float       :: proc "c" (x: float)    -> bool  { return math.classify(x) == .NaN}
@(require_results) fmod_float        :: proc "c" (x, y: float) -> float { return math.mod(x, y) }
@(require_results)
frac_float :: proc "c" (x: float) -> float {
	if x >= 0 {
		return x - math.trunc(x)
	}
	return math.trunc(-x) + x
}


@(require_results) cos_double         :: proc "c" (x: double)    -> double { return math.cos(x) }
@(require_results) sin_double         :: proc "c" (x: double)    -> double { return math.sin(x) }
@(require_results) tan_double         :: proc "c" (x: double)    -> double { return math.tan(x) }
@(require_results) acos_double        :: proc "c" (x: double)    -> double { return math.acos(x) }
@(require_results) asin_double        :: proc "c" (x: double)    -> double { return math.asin(x) }
@(require_results) atan_double        :: proc "c" (x: double)    -> double { return math.atan(x) }
@(require_results) atan2_double       :: proc "c" (y, x: double) -> double { return math.atan2(y, x) }
@(require_results) cosh_double        :: proc "c" (x: double)    -> double { return math.cosh(x) }
@(require_results) sinh_double        :: proc "c" (x: double)    -> double { return math.sinh(x) }
@(require_results) tanh_double        :: proc "c" (x: double)    -> double { return math.tanh(x) }
@(require_results) acosh_double       :: proc "c" (x: double)    -> double { return math.acosh(x) }
@(require_results) asinh_double       :: proc "c" (x: double)    -> double { return math.asinh(x) }
@(require_results) atanh_double       :: proc "c" (x: double)    -> double { return math.atanh(x) }
@(require_results) sqrt_double        :: proc "c" (x: double)    -> double { return math.sqrt(x) }
@(require_results) rsqrt_double       :: proc "c" (x: double)    -> double { return 1.0/math.sqrt(x) }
@(require_results) rcp_double         :: proc "c" (x: double)    -> double { return 1.0/x }
@(require_results) pow_double         :: proc "c" (x, y: double) -> double { return math.pow(x, y) }
@(require_results) exp_double         :: proc "c" (x: double)    -> double { return math.exp(x) }
@(require_results) log_double         :: proc "c" (x: double)    -> double { return math.ln(x) }
@(require_results) log2_double        :: proc "c" (x: double)    -> double { return math.log(x, 2) }
@(require_results) log10_double       :: proc "c" (x: double)    -> double { return math.log(x, 10) }
@(require_results) exp2_double        :: proc "c" (x: double)    -> double { return math.pow(double(2), x) }
@(require_results) sign_double        :: proc "c" (x: double)    -> double { return math.sign(x) }
@(require_results) floor_double       :: proc "c" (x: double)    -> double { return math.floor(x) }
@(require_results) round_double       :: proc "c" (x: double)    -> double { return math.round(x) }
@(require_results) ceil_double        :: proc "c" (x: double)    -> double { return math.ceil(x) }
@(require_results) isnan_double       :: proc "c" (x: double)    -> bool   { return math.classify(x) == .NaN}
@(require_results) fmod_double        :: proc "c" (x, y: double) -> double { return math.mod(x, y) }
@(require_results)
frac_double :: proc "c" (x: double) -> double {
	if x >= 0 {
		return x - math.trunc(x)
	}
	return math.trunc(-x) + x
}
