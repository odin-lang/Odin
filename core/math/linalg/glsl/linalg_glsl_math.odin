package math_linalg_glsl

import "core:math"

cos_f32         :: proc "c" (x: f32) -> f32 { return math.cos(x) }
sin_f32         :: proc "c" (x: f32) -> f32 { return math.sin(x) }
tan_f32         :: proc "c" (x: f32) -> f32 { return math.tan(x) }
acos_f32        :: proc "c" (x: f32) -> f32 { return math.acos(x) }
asin_f32        :: proc "c" (x: f32) -> f32 { return math.asin(x) }
atan_f32        :: proc "c" (x: f32) -> f32 { return math.atan(x) }
atan2_f32       :: proc "c" (y, x: f32) -> f32 { return math.atan2(y, x) }
cosh_f32        :: proc "c" (x: f32) -> f32 { return math.cosh(x) }
sinh_f32        :: proc "c" (x: f32) -> f32 { return math.sinh(x) }
tanh_f32        :: proc "c" (x: f32) -> f32 { return math.tanh(x) }
acosh_f32       :: proc "c" (x: f32) -> f32 { return math.acosh(x) }
asinh_f32       :: proc "c" (x: f32) -> f32 { return math.asinh(x) }
atanh_f32       :: proc "c" (x: f32) -> f32 { return math.atanh(x) }
sqrt_f32        :: proc "c" (x: f32) -> f32 { return math.sqrt(x) }
inversesqrt_f32 :: proc "c" (x: f32) -> f32 { return 1.0/math.sqrt(x) }
pow_f32         :: proc "c" (x, y: f32) -> f32 { return math.pow(x, y) }
exp_f32         :: proc "c" (x: f32) -> f32 { return math.exp(x) }
log_f32         :: proc "c" (x: f32) -> f32 { return math.ln(x) }
exp2_f32        :: proc "c" (x: f32) -> f32 { return math.pow(f32(2), x) }
sign_f32        :: proc "c" (x: f32) -> f32 { return math.sign(x) }
floor_f32       :: proc "c" (x: f32) -> f32 { return math.floor(x) }
round_f32       :: proc "c" (x: f32) -> f32 { return math.round(x) }
ceil_f32        :: proc "c" (x: f32) -> f32 { return math.ceil(x) }
mod_f32         :: proc "c" (x, y: f32) -> f32 { return math.mod(x, y) }
fract_f32 :: proc "c" (x: f32) -> f32 {
	if x >= 0 {
		return x - math.trunc(x)
	}
	return math.trunc(-x) + x
}

cos_f64         :: proc "c" (x: f64) -> f64 { return math.cos(x) }
sin_f64         :: proc "c" (x: f64) -> f64 { return math.sin(x) }
tan_f64         :: proc "c" (x: f64) -> f64 { return math.tan(x) }
acos_f64        :: proc "c" (x: f64) -> f64 { return math.acos(x) }
asin_f64        :: proc "c" (x: f64) -> f64 { return math.asin(x) }
atan_f64        :: proc "c" (x: f64) -> f64 { return math.atan(x) }
atan2_f64       :: proc "c" (y, x: f64) -> f64 { return math.atan2(y, x) }
cosh_f64        :: proc "c" (x: f64) -> f64 { return math.cosh(x) }
sinh_f64        :: proc "c" (x: f64) -> f64 { return math.sinh(x) }
tanh_f64        :: proc "c" (x: f64) -> f64 { return math.tanh(x) }
acosh_f64       :: proc "c" (x: f64) -> f64 { return math.acosh(x) }
asinh_f64       :: proc "c" (x: f64) -> f64 { return math.asinh(x) }
atanh_f64       :: proc "c" (x: f64) -> f64 { return math.atanh(x) }
sqrt_f64        :: proc "c" (x: f64) -> f64 { return math.sqrt(x) }
inversesqrt_f64 :: proc "c" (x: f64) -> f64 { return 1.0/math.sqrt(x) }
pow_f64         :: proc "c" (x, y: f64) -> f64 { return math.pow(x, y) }
exp_f64         :: proc "c" (x: f64) -> f64 { return math.exp(x) }
log_f64         :: proc "c" (x: f64) -> f64 { return math.ln(x) }
exp2_f64        :: proc "c" (x: f64) -> f64 { return math.pow(f64(2), x) }
sign_f64        :: proc "c" (x: f64) -> f64 { return math.sign(x) }
floor_f64       :: proc "c" (x: f64) -> f64 { return math.floor(x) }
round_f64       :: proc "c" (x: f64) -> f64 { return math.round(x) }
ceil_f64        :: proc "c" (x: f64) -> f64 { return math.ceil(x) }
mod_f64         :: proc "c" (x, y: f64) -> f64 { return math.mod(x, y) }
fract_f64 :: proc "c" (x: f64) -> f64 {
	if x >= 0 {
		return x - math.trunc(x)
	}
	return math.trunc(-x) + x
}
