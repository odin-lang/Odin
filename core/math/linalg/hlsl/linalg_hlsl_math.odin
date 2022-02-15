package math_linalg_hlsl

import "core:math"

cos_float         :: proc "c" (x: float)    -> float { return math.cos(x) }
sin_float         :: proc "c" (x: float)    -> float { return math.sin(x) }
tan_float         :: proc "c" (x: float)    -> float { return math.tan(x) }
acos_float        :: proc "c" (x: float)    -> float { return math.acos(x) }
asin_float        :: proc "c" (x: float)    -> float { return math.asin(x) }
atan_float        :: proc "c" (x: float)    -> float { return math.atan(x) }
atan2_float       :: proc "c" (y, x: float) -> float { return math.atan2(y, x) }
cosh_float        :: proc "c" (x: float)    -> float { return math.cosh(x) }
sinh_float        :: proc "c" (x: float)    -> float { return math.sinh(x) }
tanh_float        :: proc "c" (x: float)    -> float { return math.tanh(x) }
acosh_float       :: proc "c" (x: float)    -> float { return math.acosh(x) }
asinh_float       :: proc "c" (x: float)    -> float { return math.asinh(x) }
atanh_float       :: proc "c" (x: float)    -> float { return math.atanh(x) }
sqrt_float        :: proc "c" (x: float)    -> float { return math.sqrt(x) }
rsqrt_float       :: proc "c" (x: float)    -> float { return 1.0/math.sqrt(x) }
rcp_float         :: proc "c" (x: float)    -> float { return 1.0/x }
pow_float         :: proc "c" (x, y: float) -> float { return math.pow(x, y) }
exp_float         :: proc "c" (x: float)    -> float { return math.exp(x) }
log_float         :: proc "c" (x: float)    -> float { return math.ln(x) }
log2_float        :: proc "c" (x: float)    -> float { return math.log(x, 2) }
log10_float       :: proc "c" (x: float)    -> float { return math.log(x, 10) }
exp2_float        :: proc "c" (x: float)    -> float { return math.pow(float(2), x) }
sign_float        :: proc "c" (x: float)    -> float { return math.sign(x) }
floor_float       :: proc "c" (x: float)    -> float { return math.floor(x) }
round_float       :: proc "c" (x: float)    -> float { return math.round(x) }
ceil_float        :: proc "c" (x: float)    -> float { return math.ceil(x) }
isnan_float       :: proc "c" (x: float)    -> bool  { return math.classify(x) == .NaN}
fmod_float        :: proc "c" (x, y: float) -> float { return math.mod(x, y) }
frac_float :: proc "c" (x: float) -> float {
	if x >= 0 {
		return x - math.trunc(x)
	}
	return math.trunc(-x) + x
}


cos_double         :: proc "c" (x: double)    -> double { return math.cos(x) }
sin_double         :: proc "c" (x: double)    -> double { return math.sin(x) }
tan_double         :: proc "c" (x: double)    -> double { return math.tan(x) }
acos_double        :: proc "c" (x: double)    -> double { return math.acos(x) }
asin_double        :: proc "c" (x: double)    -> double { return math.asin(x) }
atan_double        :: proc "c" (x: double)    -> double { return math.atan(x) }
atan2_double       :: proc "c" (y, x: double) -> double { return math.atan2(y, x) }
cosh_double        :: proc "c" (x: double)    -> double { return math.cosh(x) }
sinh_double        :: proc "c" (x: double)    -> double { return math.sinh(x) }
tanh_double        :: proc "c" (x: double)    -> double { return math.tanh(x) }
acosh_double       :: proc "c" (x: double)    -> double { return math.acosh(x) }
asinh_double       :: proc "c" (x: double)    -> double { return math.asinh(x) }
atanh_double       :: proc "c" (x: double)    -> double { return math.atanh(x) }
sqrt_double        :: proc "c" (x: double)    -> double { return math.sqrt(x) }
rsqrt_double       :: proc "c" (x: double)    -> double { return 1.0/math.sqrt(x) }
rcp_double         :: proc "c" (x: double)    -> double { return 1.0/x }
pow_double         :: proc "c" (x, y: double) -> double { return math.pow(x, y) }
exp_double         :: proc "c" (x: double)    -> double { return math.exp(x) }
log_double         :: proc "c" (x: double)    -> double { return math.ln(x) }
log2_double        :: proc "c" (x: double)    -> double { return math.log(x, 2) }
log10_double       :: proc "c" (x: double)    -> double { return math.log(x, 10) }
exp2_double        :: proc "c" (x: double)    -> double { return math.pow(double(2), x) }
sign_double        :: proc "c" (x: double)    -> double { return math.sign(x) }
floor_double       :: proc "c" (x: double)    -> double { return math.floor(x) }
round_double       :: proc "c" (x: double)    -> double { return math.round(x) }
ceil_double        :: proc "c" (x: double)    -> double { return math.ceil(x) }
isnan_double       :: proc "c" (x: double)    -> bool   { return math.classify(x) == .NaN}
fmod_double        :: proc "c" (x, y: double) -> double { return math.mod(x, y) }
frac_double :: proc "c" (x: double) -> double {
	if x >= 0 {
		return x - math.trunc(x)
	}
	return math.trunc(-x) + x
}
