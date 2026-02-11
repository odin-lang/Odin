#+build js
package math

import "base:intrinsics"

foreign import "odin_env"

@(default_calling_convention="c")
foreign odin_env {
	@(link_name="sin", require_results)
	_sin_f64 :: proc(θ: f64) -> f64 ---
	@(link_name="cos", require_results)
	_cos_f64 :: proc(θ: f64) -> f64 ---
	@(link_name="pow", require_results)
	_pow_f64 :: proc(x, power: f64) -> f64 ---
	@(link_name="fmuladd", require_results)
	_fmuladd_f64 :: proc(a, b, c: f64) -> f64 ---
	@(link_name="ln", require_results)
	_ln_f64 :: proc(x: f64) -> f64 ---
	@(link_name="exp", require_results)
	_exp_f64 :: proc(x: f64) -> f64 ---
}

@(require_results)
sin_f64 :: proc "contextless" (θ: f64, loc := #caller_location) -> f64 {
	return _sin_f64(θ)
}
@(require_results)
cos_f64 :: proc "contextless" (θ: f64, loc := #caller_location) -> f64 {
	return _cos_f64(θ)
}
@(require_results)
pow_f64 :: proc "contextless" (x, power: f64, loc := #caller_location) -> f64 {
	return _pow_f64(x, power)
}
@(require_results)
fmuladd_f64 :: proc "contextless" (a, b, c: f64, loc := #caller_location) -> f64 {
	return _fmuladd_f64(a, b, c)
}
@(require_results)
ln_f64 :: proc "contextless" (x: f64, loc := #caller_location) -> f64 {
	return _ln_f64(x)
}
@(require_results)
exp_f64 :: proc "contextless" (x: f64, loc := #caller_location) -> f64 {
	return _exp_f64(x)
}

@(require_results)
sqrt_f64 :: proc "contextless" (x: f64) -> f64 {
	return intrinsics.sqrt(x)
}

@(require_results) sqrt_f16    :: proc "c" (x: f16, loc := #caller_location) -> f16             { return f16(sqrt_f64(f64(x), loc))                    }
@(require_results) sin_f16     :: proc "c" (θ: f16, loc := #caller_location) -> f16             { return f16(sin_f64(f64(θ), loc))                     }
@(require_results) cos_f16     :: proc "c" (θ: f16, loc := #caller_location) -> f16             { return f16(cos_f64(f64(θ), loc))                     }
@(require_results) pow_f16     :: proc "c" (x, power: f16, loc := #caller_location) -> f16      { return f16(pow_f64(f64(x), f64(power), loc))         }
@(require_results) fmuladd_f16 :: proc "c" (a, b, c: f16, loc := #caller_location) -> f16       { return f16(fmuladd_f64(f64(a), f64(a), f64(c), loc)) }
@(require_results) ln_f16      :: proc "c" (x: f16, loc := #caller_location) -> f16             { return f16(ln_f64(f64(x), loc))                      }
@(require_results) exp_f16     :: proc "c" (x: f16, loc := #caller_location) -> f16             { return f16(exp_f64(f64(x), loc))                     }

@(require_results) sqrt_f32    :: proc "c" (x: f32, loc := #caller_location) -> f32             { return f32(sqrt_f64(f64(x), loc))                    }
@(require_results) sin_f32     :: proc "c" (θ: f32, loc := #caller_location) -> f32             { return f32(sin_f64(f64(θ), loc))                     }
@(require_results) cos_f32     :: proc "c" (θ: f32, loc := #caller_location) -> f32             { return f32(cos_f64(f64(θ), loc))                     }
@(require_results) pow_f32     :: proc "c" (x, power: f32, loc := #caller_location) -> f32      { return f32(pow_f64(f64(x), f64(power), loc))         }
@(require_results) fmuladd_f32 :: proc "c" (a, b, c: f32, loc := #caller_location) -> f32       { return f32(fmuladd_f64(f64(a), f64(a), f64(c), loc)) }
@(require_results) ln_f32      :: proc "c" (x: f32, loc := #caller_location) -> f32             { return f32(ln_f64(f64(x), loc))                      }
@(require_results) exp_f32     :: proc "c" (x: f32, loc := #caller_location) -> f32             { return f32(exp_f64(f64(x), loc))                     }

@(require_results) ln_f16le :: proc "contextless" (x: f16le, loc := #caller_location) -> f16le { return #force_inline f16le(ln_f64(f64(x), loc)) }
@(require_results) ln_f16be :: proc "contextless" (x: f16be, loc := #caller_location) -> f16be { return #force_inline f16be(ln_f64(f64(x), loc)) }
@(require_results) ln_f32le :: proc "contextless" (x: f32le, loc := #caller_location) -> f32le { return #force_inline f32le(ln_f64(f64(x), loc)) }
@(require_results) ln_f32be :: proc "contextless" (x: f32be, loc := #caller_location) -> f32be { return #force_inline f32be(ln_f64(f64(x), loc)) }
@(require_results) ln_f64le :: proc "contextless" (x: f64le, loc := #caller_location) -> f64le { return #force_inline f64le(ln_f64(f64(x), loc)) }
@(require_results) ln_f64be :: proc "contextless" (x: f64be, loc := #caller_location) -> f64be { return #force_inline f64be(ln_f64(f64(x), loc)) }
ln :: proc{
	ln_f16, ln_f16le, ln_f16be,
	ln_f32, ln_f32le, ln_f32be,
	ln_f64, ln_f64le, ln_f64be,
}
