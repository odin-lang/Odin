//+build js
package math

import "core:intrinsics"

foreign import "odin_env"

@(default_calling_convention="c")
foreign odin_env {
	@(link_name="sin")
	sin_f64 :: proc(θ: f64) -> f64 ---
	@(link_name="cos")
	cos_f64 :: proc(θ: f64) -> f64 ---
	@(link_name="pow")
	pow_f64 :: proc(x, power: f64) -> f64 ---
	@(link_name="fmuladd")
	fmuladd_f64 :: proc(a, b, c: f64) -> f64 ---
	@(link_name="ln")
	ln_f64 :: proc(x: f64) -> f64 ---
	@(link_name="exp")
	exp_f64 :: proc(x: f64) -> f64 ---
}

sqrt_f64 :: proc "contextless" (x: f64) -> f64 {
	return intrinsics.sqrt(x)
}

sqrt_f16    :: proc "c" (x: f16) -> f16             { return f16(sqrt_f64(f64(x)))                    }
sin_f16     :: proc "c" (θ: f16) -> f16             { return f16(sin_f64(f64(θ)))                     }
cos_f16     :: proc "c" (θ: f16) -> f16             { return f16(cos_f64(f64(θ)))                     }
pow_f16     :: proc "c" (x, power: f16) -> f16      { return f16(pow_f64(f64(x), f64(power)))         }
fmuladd_f16 :: proc "c" (a, b, c: f16) -> f16       { return f16(fmuladd_f64(f64(a), f64(a), f64(c))) }
ln_f16      :: proc "c" (x: f16) -> f16             { return f16(ln_f64(f64(x)))                      }
exp_f16     :: proc "c" (x: f16) -> f16             { return f16(exp_f64(f64(x)))                     }

sqrt_f32    :: proc "c" (x: f32) -> f32             { return f32(sqrt_f64(f64(x)))                    }
sin_f32     :: proc "c" (θ: f32) -> f32             { return f32(sin_f64(f64(θ)))                     }
cos_f32     :: proc "c" (θ: f32) -> f32             { return f32(cos_f64(f64(θ)))                     }
pow_f32     :: proc "c" (x, power: f32) -> f32      { return f32(pow_f64(f64(x), f64(power)))         }
fmuladd_f32 :: proc "c" (a, b, c: f32) -> f32       { return f32(fmuladd_f64(f64(a), f64(a), f64(c))) }
ln_f32      :: proc "c" (x: f32) -> f32             { return f32(ln_f64(f64(x)))                      }
exp_f32     :: proc "c" (x: f32) -> f32             { return f32(exp_f64(f64(x)))                     }

ln_f16le :: proc "contextless" (x: f16le) -> f16le { return #force_inline f16le(ln_f64(f64(x))) }
ln_f16be :: proc "contextless" (x: f16be) -> f16be { return #force_inline f16be(ln_f64(f64(x))) }
ln_f32le :: proc "contextless" (x: f32le) -> f32le { return #force_inline f32le(ln_f64(f64(x))) }
ln_f32be :: proc "contextless" (x: f32be) -> f32be { return #force_inline f32be(ln_f64(f64(x))) }
ln_f64le :: proc "contextless" (x: f64le) -> f64le { return #force_inline f64le(ln_f64(f64(x))) }
ln_f64be :: proc "contextless" (x: f64be) -> f64be { return #force_inline f64be(ln_f64(f64(x))) }
ln :: proc{
	ln_f16, ln_f16le, ln_f16be,
	ln_f32, ln_f32le, ln_f32be,
	ln_f64, ln_f64le, ln_f64be,
}
