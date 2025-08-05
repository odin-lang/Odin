package math_linalg_glsl

import "core:math"

@(require_results) cos_f32         :: proc "c" (x: f32) -> f32 { return math.cos(x) }
@(require_results) sin_f32         :: proc "c" (x: f32) -> f32 { return math.sin(x) }
@(require_results) tan_f32         :: proc "c" (x: f32) -> f32 { return math.tan(x) }
@(require_results) acos_f32        :: proc "c" (x: f32) -> f32 { return math.acos(x) }
@(require_results) asin_f32        :: proc "c" (x: f32) -> f32 { return math.asin(x) }
@(require_results) atan_f32        :: proc "c" (x: f32) -> f32 { return math.atan(x) }
@(require_results) atan2_f32       :: proc "c" (y, x: f32) -> f32 { return math.atan2(y, x) }
@(require_results) cosh_f32        :: proc "c" (x: f32) -> f32 { return math.cosh(x) }
@(require_results) sinh_f32        :: proc "c" (x: f32) -> f32 { return math.sinh(x) }
@(require_results) tanh_f32        :: proc "c" (x: f32) -> f32 { return math.tanh(x) }
@(require_results) acosh_f32       :: proc "c" (x: f32) -> f32 { return math.acosh(x) }
@(require_results) asinh_f32       :: proc "c" (x: f32) -> f32 { return math.asinh(x) }
@(require_results) atanh_f32       :: proc "c" (x: f32) -> f32 { return math.atanh(x) }
@(require_results) sqrt_f32        :: proc "c" (x: f32) -> f32 { return math.sqrt(x) }
@(require_results) inversesqrt_f32 :: proc "c" (x: f32) -> f32 { return 1.0/math.sqrt(x) }
@(require_results) pow_f32         :: proc "c" (x, y: f32) -> f32 { return math.pow(x, y) }
@(require_results) exp_f32         :: proc "c" (x: f32) -> f32 { return math.exp(x) }
@(require_results) log_f32         :: proc "c" (x: f32) -> f32 { return math.ln(x) }
@(require_results) exp2_f32        :: proc "c" (x: f32) -> f32 { return math.pow(f32(2), x) }
@(require_results) sign_f32        :: proc "c" (x: f32) -> f32 { return math.sign(x) }
@(require_results) floor_f32       :: proc "c" (x: f32) -> f32 { return math.floor(x) }
@(require_results) trunc_f32       :: proc "c" (x: f32) -> f32 { return math.trunc(x) }
@(require_results) round_f32       :: proc "c" (x: f32) -> f32 { return math.round(x) }
@(require_results) ceil_f32        :: proc "c" (x: f32) -> f32 { return math.ceil(x) }
@(require_results) mod_f32         :: proc "c" (x, y: f32) -> f32 { return math.mod(x, y) }
@(require_results)
fract_f32 :: proc "c" (x: f32) -> f32 {
	if x >= 0 {
		return x - math.trunc(x)
	}
	return math.trunc(-x) + x
}

@(require_results) cos_f64         :: proc "c" (x: f64) -> f64 { return math.cos(x) }
@(require_results) sin_f64         :: proc "c" (x: f64) -> f64 { return math.sin(x) }
@(require_results) tan_f64         :: proc "c" (x: f64) -> f64 { return math.tan(x) }
@(require_results) acos_f64        :: proc "c" (x: f64) -> f64 { return math.acos(x) }
@(require_results) asin_f64        :: proc "c" (x: f64) -> f64 { return math.asin(x) }
@(require_results) atan_f64        :: proc "c" (x: f64) -> f64 { return math.atan(x) }
@(require_results) atan2_f64       :: proc "c" (y, x: f64) -> f64 { return math.atan2(y, x) }
@(require_results) cosh_f64        :: proc "c" (x: f64) -> f64 { return math.cosh(x) }
@(require_results) sinh_f64        :: proc "c" (x: f64) -> f64 { return math.sinh(x) }
@(require_results) tanh_f64        :: proc "c" (x: f64) -> f64 { return math.tanh(x) }
@(require_results) acosh_f64       :: proc "c" (x: f64) -> f64 { return math.acosh(x) }
@(require_results) asinh_f64       :: proc "c" (x: f64) -> f64 { return math.asinh(x) }
@(require_results) atanh_f64       :: proc "c" (x: f64) -> f64 { return math.atanh(x) }
@(require_results) sqrt_f64        :: proc "c" (x: f64) -> f64 { return math.sqrt(x) }
@(require_results) inversesqrt_f64 :: proc "c" (x: f64) -> f64 { return 1.0/math.sqrt(x) }
@(require_results) pow_f64         :: proc "c" (x, y: f64) -> f64 { return math.pow(x, y) }
@(require_results) exp_f64         :: proc "c" (x: f64) -> f64 { return math.exp(x) }
@(require_results) log_f64         :: proc "c" (x: f64) -> f64 { return math.ln(x) }
@(require_results) exp2_f64        :: proc "c" (x: f64) -> f64 { return math.pow(f64(2), x) }
@(require_results) sign_f64        :: proc "c" (x: f64) -> f64 { return math.sign(x) }
@(require_results) floor_f64       :: proc "c" (x: f64) -> f64 { return math.floor(x) }
@(require_results) trunc_f64       :: proc "c" (x: f64) -> f64 { return math.trunc(x) }
@(require_results) round_f64       :: proc "c" (x: f64) -> f64 { return math.round(x) }
@(require_results) ceil_f64        :: proc "c" (x: f64) -> f64 { return math.ceil(x) }
@(require_results) mod_f64         :: proc "c" (x, y: f64) -> f64 { return math.mod(x, y) }
@(require_results)
fract_f64 :: proc "c" (x: f64) -> f64 {
	if x >= 0 {
		return x - math.trunc(x)
	}
	return math.trunc(-x) + x
}
