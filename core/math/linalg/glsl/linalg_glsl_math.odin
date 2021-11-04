//+build !freestanding !wasm32
package math_linalg_glsl

import "core:math"

cos_f32         :: proc "c" (x: f32) -> f32 { return math.cos_f32(x) }
sin_f32         :: proc "c" (x: f32) -> f32 { return math.sin_f32(x) }
tan_f32         :: proc "c" (x: f32) -> f32 { return math.tan_f32(x) }
acos_f32        :: proc "c" (x: f32) -> f32 { return math.acos(x) }
asin_f32        :: proc "c" (x: f32) -> f32 { return math.asin(x) }
atan_f32        :: proc "c" (x: f32) -> f32 { return math.atan(x) }
atan2_f32       :: proc "c" (y, x: f32) -> f32 { return math.atan2_f32(y, x) }
cosh_f32        :: proc "c" (x: f32) -> f32 { return math.cosh(x) }
sinh_f32        :: proc "c" (x: f32) -> f32 { return math.sinh(x) }
tanh_f32        :: proc "c" (x: f32) -> f32 { return math.tanh(x) }
acosh_f32       :: proc "c" (x: f32) -> f32 { return math.acosh(x) }
asinh_f32       :: proc "c" (x: f32) -> f32 { return math.asinh(x) }
atanh_f32       :: proc "c" (x: f32) -> f32 { return math.atanh(x) }
sqrt_f32        :: proc "c" (x: f32) -> f32 { return math.sqrt(x) }
inversesqrt_f32 :: proc "c" (x: f32) -> f32 { return 1.0/sqrt_f32(x) }
pow_f32         :: proc "c" (x, y: f32) -> f32 { return math.pow(x, y) }
exp_f32         :: proc "c" (x: f32) -> f32 { return math.exp(x) }
log_f32         :: proc "c" (x: f32) -> f32 { return math.ln_f32(x) }
exp2_f32        :: proc "c" (x: f32) -> f32 { return pow(2, x) }
sign_f32        :: proc "c" (x: f32) -> f32 { return math.sign(x) }
floor_f32       :: proc "c" (x: f32) -> f32 { return math.floor(x) }
ceil_f32        :: proc "c" (x: f32) -> f32 { return math.ceil(x) }
mod_f32         :: proc "c" (x, y: f32) -> f32 { return math.mod(x, y) }
fract_f32 :: proc "c" (x: f32) -> f32 {
	if x >= 0 {
		return x - math.trunc_f32(x)
	}
	return math.trunc_f32(-x) + x
}
