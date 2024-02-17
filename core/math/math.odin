package math

import "base:intrinsics"
import "base:builtin"
_ :: intrinsics

Float_Class :: enum {
	Normal,    // an ordinary nonzero floating point value
	Subnormal, // a subnormal floating point value
	Zero,      // zero
	Neg_Zero,  // the negative zero
	NaN,       // Not-A-Number (NaN)
	Inf,       // positive infinity
	Neg_Inf,   // negative infinity
}

TAU          :: 6.28318530717958647692528676655900576
PI           :: 3.14159265358979323846264338327950288

E            :: 2.71828182845904523536

τ :: TAU
π :: PI
e :: E

SQRT_TWO     :: 1.41421356237309504880168872420969808
SQRT_THREE   :: 1.73205080756887729352744634150587236
SQRT_FIVE    :: 2.23606797749978969640917366873127623

LN2          :: 0.693147180559945309417232121458176568
LN10         :: 2.30258509299404568401799145468436421

MAX_F64_PRECISION :: 16 // Maximum number of meaningful digits after the decimal point for 'f64'
MAX_F32_PRECISION ::  8 // Maximum number of meaningful digits after the decimal point for 'f32'
MAX_F16_PRECISION ::  4 // Maximum number of meaningful digits after the decimal point for 'f16'

RAD_PER_DEG :: TAU/360.0
DEG_PER_RAD :: 360.0/TAU

abs :: builtin.abs
min :: builtin.min
max :: builtin.max
clamp :: builtin.clamp

@(require_results) sqrt_f16le :: proc "contextless" (x: f16le) -> f16le { return #force_inline f16le(sqrt_f16(f16(x))) }
@(require_results) sqrt_f16be :: proc "contextless" (x: f16be) -> f16be { return #force_inline f16be(sqrt_f16(f16(x))) }
@(require_results) sqrt_f32le :: proc "contextless" (x: f32le) -> f32le { return #force_inline f32le(sqrt_f32(f32(x))) }
@(require_results) sqrt_f32be :: proc "contextless" (x: f32be) -> f32be { return #force_inline f32be(sqrt_f32(f32(x))) }
@(require_results) sqrt_f64le :: proc "contextless" (x: f64le) -> f64le { return #force_inline f64le(sqrt_f64(f64(x))) }
@(require_results) sqrt_f64be :: proc "contextless" (x: f64be) -> f64be { return #force_inline f64be(sqrt_f64(f64(x))) }
sqrt :: proc{
	sqrt_f16, sqrt_f16le, sqrt_f16be,
	sqrt_f32, sqrt_f32le, sqrt_f32be,
	sqrt_f64, sqrt_f64le, sqrt_f64be,
}

@(require_results) sin_f16le :: proc "contextless" (θ: f16le) -> f16le { return #force_inline f16le(sin_f16(f16(θ))) }
@(require_results) sin_f16be :: proc "contextless" (θ: f16be) -> f16be { return #force_inline f16be(sin_f16(f16(θ))) }
@(require_results) sin_f32le :: proc "contextless" (θ: f32le) -> f32le { return #force_inline f32le(sin_f32(f32(θ))) }
@(require_results) sin_f32be :: proc "contextless" (θ: f32be) -> f32be { return #force_inline f32be(sin_f32(f32(θ))) }
@(require_results) sin_f64le :: proc "contextless" (θ: f64le) -> f64le { return #force_inline f64le(sin_f64(f64(θ))) }
@(require_results) sin_f64be :: proc "contextless" (θ: f64be) -> f64be { return #force_inline f64be(sin_f64(f64(θ))) }
sin :: proc{
	sin_f16, sin_f16le, sin_f16be,
	sin_f32, sin_f32le, sin_f32be,
	sin_f64, sin_f64le, sin_f64be,
}

@(require_results) cos_f16le :: proc "contextless" (θ: f16le) -> f16le { return #force_inline f16le(cos_f16(f16(θ))) }
@(require_results) cos_f16be :: proc "contextless" (θ: f16be) -> f16be { return #force_inline f16be(cos_f16(f16(θ))) }
@(require_results) cos_f32le :: proc "contextless" (θ: f32le) -> f32le { return #force_inline f32le(cos_f32(f32(θ))) }
@(require_results) cos_f32be :: proc "contextless" (θ: f32be) -> f32be { return #force_inline f32be(cos_f32(f32(θ))) }
@(require_results) cos_f64le :: proc "contextless" (θ: f64le) -> f64le { return #force_inline f64le(cos_f64(f64(θ))) }
@(require_results) cos_f64be :: proc "contextless" (θ: f64be) -> f64be { return #force_inline f64be(cos_f64(f64(θ))) }
cos :: proc{
	cos_f16, cos_f16le, cos_f16be,
	cos_f32, cos_f32le, cos_f32be,
	cos_f64, cos_f64le, cos_f64be,
}

@(require_results) pow_f16le :: proc "contextless" (x, power: f16le) -> f16le { return #force_inline f16le(pow_f16(f16(x), f16(power))) }
@(require_results) pow_f16be :: proc "contextless" (x, power: f16be) -> f16be { return #force_inline f16be(pow_f16(f16(x), f16(power))) }
@(require_results) pow_f32le :: proc "contextless" (x, power: f32le) -> f32le { return #force_inline f32le(pow_f32(f32(x), f32(power))) }
@(require_results) pow_f32be :: proc "contextless" (x, power: f32be) -> f32be { return #force_inline f32be(pow_f32(f32(x), f32(power))) }
@(require_results) pow_f64le :: proc "contextless" (x, power: f64le) -> f64le { return #force_inline f64le(pow_f64(f64(x), f64(power))) }
@(require_results) pow_f64be :: proc "contextless" (x, power: f64be) -> f64be { return #force_inline f64be(pow_f64(f64(x), f64(power))) }
pow :: proc{
	pow_f16, pow_f16le, pow_f16be,
	pow_f32, pow_f32le, pow_f32be,
	pow_f64, pow_f64le, pow_f64be,
}

@(require_results) fmuladd_f16le :: proc "contextless" (a, b, c: f16le) -> f16le { return #force_inline f16le(fmuladd_f16(f16(a), f16(b), f16(c))) }
@(require_results) fmuladd_f16be :: proc "contextless" (a, b, c: f16be) -> f16be { return #force_inline f16be(fmuladd_f16(f16(a), f16(b), f16(c))) }
@(require_results) fmuladd_f32le :: proc "contextless" (a, b, c: f32le) -> f32le { return #force_inline f32le(fmuladd_f32(f32(a), f32(b), f32(c))) }
@(require_results) fmuladd_f32be :: proc "contextless" (a, b, c: f32be) -> f32be { return #force_inline f32be(fmuladd_f32(f32(a), f32(b), f32(c))) }
@(require_results) fmuladd_f64le :: proc "contextless" (a, b, c: f64le) -> f64le { return #force_inline f64le(fmuladd_f64(f64(a), f64(b), f64(c))) }
@(require_results) fmuladd_f64be :: proc "contextless" (a, b, c: f64be) -> f64be { return #force_inline f64be(fmuladd_f64(f64(a), f64(b), f64(c))) }
fmuladd :: proc{
	fmuladd_f16, fmuladd_f16le, fmuladd_f16be,
	fmuladd_f32, fmuladd_f32le, fmuladd_f32be,
	fmuladd_f64, fmuladd_f64le, fmuladd_f64be,
}

@(require_results) exp_f16le :: proc "contextless" (x: f16le) -> f16le { return #force_inline f16le(exp_f16(f16(x))) }
@(require_results) exp_f16be :: proc "contextless" (x: f16be) -> f16be { return #force_inline f16be(exp_f16(f16(x))) }
@(require_results) exp_f32le :: proc "contextless" (x: f32le) -> f32le { return #force_inline f32le(exp_f32(f32(x))) }
@(require_results) exp_f32be :: proc "contextless" (x: f32be) -> f32be { return #force_inline f32be(exp_f32(f32(x))) }
@(require_results) exp_f64le :: proc "contextless" (x: f64le) -> f64le { return #force_inline f64le(exp_f64(f64(x))) }
@(require_results) exp_f64be :: proc "contextless" (x: f64be) -> f64be { return #force_inline f64be(exp_f64(f64(x))) }
exp :: proc{
	exp_f16, exp_f16le, exp_f16be,
	exp_f32, exp_f32le, exp_f32be,
	exp_f64, exp_f64le, exp_f64be,
}

@(require_results) pow10_f16le :: proc "contextless" (x: f16le) -> f16le { return #force_inline f16le(pow10_f16(f16(x))) }
@(require_results) pow10_f16be :: proc "contextless" (x: f16be) -> f16be { return #force_inline f16be(pow10_f16(f16(x))) }
@(require_results) pow10_f32le :: proc "contextless" (x: f32le) -> f32le { return #force_inline f32le(pow10_f32(f32(x))) }
@(require_results) pow10_f32be :: proc "contextless" (x: f32be) -> f32be { return #force_inline f32be(pow10_f32(f32(x))) }
@(require_results) pow10_f64le :: proc "contextless" (x: f64le) -> f64le { return #force_inline f64le(pow10_f64(f64(x))) }
@(require_results) pow10_f64be :: proc "contextless" (x: f64be) -> f64be { return #force_inline f64be(pow10_f64(f64(x))) }
pow10 :: proc{
	pow10_f16, pow10_f16le, pow10_f16be,
	pow10_f32, pow10_f32le, pow10_f32be,
	pow10_f64, pow10_f64le, pow10_f64be,
}

@(require_results)
pow10_f16 :: proc "contextless" (n: f16) -> f16 {
	@static pow10_pos_tab := [?]f16{
		1e00, 1e01, 1e02, 1e03, 1e04,
	}
	@static pow10_neg_tab := [?]f16{
		1e-00, 1e-01, 1e-02, 1e-03, 1e-04, 1e-05, 1e-06, 1e-07,
	}

	if 0 <= n && n <= 4 {
		return pow10_pos_tab[uint(n)]
	}
	if -7 <= n && n <= 0 {
		return pow10_neg_tab[uint(-n)]
	}
	if n > 0 {
		return inf_f16(1)
	}
	return 0
}

@(require_results)
pow10_f32 :: proc "contextless" (n: f32) -> f32 {
	@static pow10_pos_tab := [?]f32{
		1e00, 1e01, 1e02, 1e03, 1e04, 1e05, 1e06, 1e07, 1e08, 1e09,
		1e10, 1e11, 1e12, 1e13, 1e14, 1e15, 1e16, 1e17, 1e18, 1e19,
		1e20, 1e21, 1e22, 1e23, 1e24, 1e25, 1e26, 1e27, 1e28, 1e29,
		1e30, 1e31, 1e32, 1e33, 1e34, 1e35, 1e36, 1e37, 1e38,
	}
	@static pow10_neg_tab := [?]f32{
		1e-00, 1e-01, 1e-02, 1e-03, 1e-04, 1e-05, 1e-06, 1e-07, 1e-08, 1e-09,
		1e-10, 1e-11, 1e-12, 1e-13, 1e-14, 1e-15, 1e-16, 1e-17, 1e-18, 1e-19,
		1e-20, 1e-21, 1e-22, 1e-23, 1e-24, 1e-25, 1e-26, 1e-27, 1e-28, 1e-29,
		1e-30, 1e-31, 1e-32, 1e-33, 1e-34, 1e-35, 1e-36, 1e-37, 1e-38, 1e-39,
		1e-40, 1e-41, 1e-42, 1e-43, 1e-44, 1e-45,
	}

	if 0 <= n && n <= 38 {
		return pow10_pos_tab[uint(n)]
	}
	if -45 <= n && n <= 0 {
		return pow10_neg_tab[uint(-n)]
	}
	if n > 0 {
		return inf_f32(1)
	}
	return 0
}

@(require_results)
pow10_f64 :: proc "contextless" (n: f64) -> f64 {
	@static pow10_tab := [?]f64{
		1e00, 1e01, 1e02, 1e03, 1e04, 1e05, 1e06, 1e07, 1e08, 1e09,
		1e10, 1e11, 1e12, 1e13, 1e14, 1e15, 1e16, 1e17, 1e18, 1e19,
		1e20, 1e21, 1e22, 1e23, 1e24, 1e25, 1e26, 1e27, 1e28, 1e29,
		1e30, 1e31,
	}
	@static pow10_pos_tab32 := [?]f64{
		1e00, 1e32, 1e64, 1e96, 1e128, 1e160, 1e192, 1e224, 1e256, 1e288,
	}
	@static pow10_neg_tab32 := [?]f64{
		1e-00, 1e-32, 1e-64, 1e-96, 1e-128, 1e-160, 1e-192, 1e-224, 1e-256, 1e-288, 1e-320,
	}

	if 0 <= n && n <= 308 {
		return pow10_pos_tab32[uint(n)/32] * pow10_tab[uint(n)%32]
	}
	if -323 <= n && n <= 0 {
		return pow10_neg_tab32[uint(-n)/32] / pow10_tab[uint(-n)%32]
	}

	if n > 0 {
		return inf_f64(1)
	}
	return 0
}

@(require_results)
pow2_f64 :: proc "contextless" (#any_int exp: int) -> (res: f64) {
	switch {
	case exp >= -1022 && exp <= 1023: // Normal
		return transmute(f64)(u64(exp + F64_BIAS) << F64_SHIFT)
	case exp < -1075:                 // Underflow
		return f64(0)
	case exp == -1075:                // Underflow.
		// Note that pow(2, -1075) returns 0h1 on Windows and 0h0 on macOS & Linux.
		return 0h00000000_00000000
	case exp < -1022:                 // Denormal
		x := u64(exp + (F64_SHIFT + 1) + F64_BIAS) << F64_SHIFT
		return f64(1) / (1 << (F64_SHIFT + 1)) * transmute(f64)x
	case exp > 1023:                  // Overflow, +Inf
		return 0h7ff00000_00000000
	}
	unreachable()
}

@(require_results)
pow2_f32 :: proc "contextless" (#any_int exp: int) -> (res: f32) {
	switch {
	case exp >= -126 && exp <= 127:  // Normal
		return transmute(f32)(u32(exp + F32_BIAS) << F32_SHIFT)
	case exp < -151:                 // Underflow
		return f32(0)
	case exp < -126:                 // Denormal
		x := u32(exp + (F32_SHIFT + 1) + F32_BIAS) << F32_SHIFT
		return f32(1) / (1 << (F32_SHIFT + 1)) * transmute(f32)x
	case exp > 127:                  // Overflow, +Inf
		return 0h7f80_0000
	}
	unreachable()
}

@(require_results)
pow2_f16 :: proc "contextless" (#any_int exp: int) -> (res: f16) {
	switch {
	case exp >= -14 && exp <= 15:    // Normal
		return transmute(f16)(u16(exp + F16_BIAS) << F16_SHIFT)
	case exp < -25:                  // Underflow
		return 0h0000
	case exp == -25:                 // Underflow
		return 0h0001
	case exp < -14:                  // Denormal
		x := u16(exp + (F16_SHIFT + 1) + F16_BIAS) << F16_SHIFT
		return f16(1) / (1 << (F16_SHIFT + 1)) * transmute(f16)x
	case exp > 15:                   // Overflow, +Inf
		return 0h7c00
	}
	unreachable()
}

@(require_results)
ldexp_f64 :: proc "contextless" (val: f64, exp: int) -> f64 {
	mask  :: F64_MASK
	shift :: F64_SHIFT
	bias  :: F64_BIAS
	
	switch {
	case val == 0:
		return val
	case is_inf(val) || is_nan(val):
		return val
	}
	exp := exp
	frac, e := normalize_f64(val)
	exp += e
	x := transmute(u64)frac
	exp += int(x>>shift)&mask - bias
	if exp < -1075 { // underflow
		return copy_sign(0, frac) 
	} else if exp > 1023 { // overflow
		if frac < 0 {
			return inf_f64(-1)
		}
		return inf_f64(+1)
	}
	
	m: f64 = 1
	if exp < -1022 { // denormal
		exp += 53
		m = 1.0 / (1<<53)
	}
	x &~= mask << shift
	x |= u64(exp+bias) << shift
	return m * transmute(f64)x	
}
@(require_results) ldexp_f16   :: proc "contextless" (val: f16, exp: int) -> f16 { return f16(ldexp_f64(f64(val), exp)) }
@(require_results) ldexp_f32   :: proc "contextless" (val: f32, exp: int) -> f32 { return f32(ldexp_f64(f64(val), exp)) }
@(require_results) ldexp_f16le :: proc "contextless" (val: f16le, exp: int) -> f16le { return #force_inline f16le(ldexp_f16(f16(val), exp)) }
@(require_results) ldexp_f16be :: proc "contextless" (val: f16be, exp: int) -> f16be { return #force_inline f16be(ldexp_f16(f16(val), exp)) }
@(require_results) ldexp_f32le :: proc "contextless" (val: f32le, exp: int) -> f32le { return #force_inline f32le(ldexp_f32(f32(val), exp)) }
@(require_results) ldexp_f32be :: proc "contextless" (val: f32be, exp: int) -> f32be { return #force_inline f32be(ldexp_f32(f32(val), exp)) }
@(require_results) ldexp_f64le :: proc "contextless" (val: f64le, exp: int) -> f64le { return #force_inline f64le(ldexp_f64(f64(val), exp)) }
@(require_results) ldexp_f64be :: proc "contextless" (val: f64be, exp: int) -> f64be { return #force_inline f64be(ldexp_f64(f64(val), exp)) }
// ldexp is the inverse of frexp
// it returns val * 2**exp.
// 
// Special cases:
// 	ldexp(+0,   exp) = +0
// 	ldexp(-0,   exp) = -0
// 	ldexp(+inf, exp) = +inf
// 	ldexp(-inf, exp) = -inf
// 	ldexp(NaN,  exp) = NaN
ldexp :: proc{
	ldexp_f16, ldexp_f16le, ldexp_f16be,
	ldexp_f32, ldexp_f32le, ldexp_f32be,
	ldexp_f64, ldexp_f64le, ldexp_f64be,
}


@(require_results) log_f16   :: proc "contextless" (x, base: f16)   -> f16   { return ln(x) / ln(base) }
@(require_results) log_f16le :: proc "contextless" (x, base: f16le) -> f16le { return f16le(log_f16(f16(x), f16(base))) }
@(require_results) log_f16be :: proc "contextless" (x, base: f16be) -> f16be { return f16be(log_f16(f16(x), f16(base))) }

@(require_results) log_f32   :: proc "contextless" (x, base: f32)   -> f32   { return ln(x) / ln(base) }
@(require_results) log_f32le :: proc "contextless" (x, base: f32le) -> f32le { return f32le(log_f32(f32(x), f32(base))) }
@(require_results) log_f32be :: proc "contextless" (x, base: f32be) -> f32be { return f32be(log_f32(f32(x), f32(base))) }

@(require_results) log_f64   :: proc "contextless" (x, base: f64)   -> f64   { return ln(x) / ln(base) }
@(require_results) log_f64le :: proc "contextless" (x, base: f64le) -> f64le { return f64le(log_f64(f64(x), f64(base))) }
@(require_results) log_f64be :: proc "contextless" (x, base: f64be) -> f64be { return f64be(log_f64(f64(x), f64(base))) }
log :: proc{
	log_f16, log_f16le, log_f16be,
	log_f32, log_f32le, log_f32be,
	log_f64, log_f64le, log_f64be,
}

@(require_results) log2_f16   :: proc "contextless" (x: f16)   -> f16   { return log(f16(x), f16(2.0)) }
@(require_results) log2_f16le :: proc "contextless" (x: f16le) -> f16le { return f16le(log_f16(f16(x), f16(2.0))) }
@(require_results) log2_f16be :: proc "contextless" (x: f16be) -> f16be { return f16be(log_f16(f16(x), f16(2.0))) }

@(require_results) log2_f32   :: proc "contextless" (x: f32)   -> f32   { return log(f32(x), f32(2.0)) }
@(require_results) log2_f32le :: proc "contextless" (x: f32le) -> f32le { return f32le(log_f32(f32(x), f32(2.0))) }
@(require_results) log2_f32be :: proc "contextless" (x: f32be) -> f32be { return f32be(log_f32(f32(x), f32(2.0))) }

@(require_results) log2_f64   :: proc "contextless" (x: f64)   -> f64   { return log(f64(x), f64(2.0)) }
@(require_results) log2_f64le :: proc "contextless" (x: f64le) -> f64le { return f64le(log_f64(f64(x), f64(2.0))) }
@(require_results) log2_f64be :: proc "contextless" (x: f64be) -> f64be { return f64be(log_f64(f64(x), f64(2.0))) }

log2 :: proc{
	log2_f16, log2_f16le, log2_f16be,
	log2_f32, log2_f32le, log2_f32be,
	log2_f64, log2_f64le, log2_f64be,
}

@(require_results) log10_f16   :: proc "contextless" (x: f16)   -> f16   { return ln(x)/LN10 }
@(require_results) log10_f16le :: proc "contextless" (x: f16le) -> f16le { return f16le(log10_f16(f16(x))) }
@(require_results) log10_f16be :: proc "contextless" (x: f16be) -> f16be { return f16be(log10_f16(f16(x))) }

@(require_results) log10_f32   :: proc "contextless" (x: f32)   -> f32   { return ln(x)/LN10 }
@(require_results) log10_f32le :: proc "contextless" (x: f32le) -> f32le { return f32le(log10_f32(f32(x))) }
@(require_results) log10_f32be :: proc "contextless" (x: f32be) -> f32be { return f32be(log10_f32(f32(x))) }

@(require_results) log10_f64   :: proc "contextless" (x: f64)   -> f64   { return ln(x)/LN10 }
@(require_results) log10_f64le :: proc "contextless" (x: f64le) -> f64le { return f64le(log10_f64(f64(x))) }
@(require_results) log10_f64be :: proc "contextless" (x: f64be) -> f64be { return f64be(log10_f64(f64(x))) }
log10 :: proc{
	log10_f16, log10_f16le, log10_f16be,
	log10_f32, log10_f32le, log10_f32be,
	log10_f64, log10_f64le, log10_f64be,
}

@(require_results) tan_f16   :: proc "contextless" (θ: f16)   -> f16   { return sin(θ)/cos(θ) }
@(require_results) tan_f16le :: proc "contextless" (θ: f16le) -> f16le { return f16le(tan_f16(f16(θ))) }
@(require_results) tan_f16be :: proc "contextless" (θ: f16be) -> f16be { return f16be(tan_f16(f16(θ))) }

@(require_results) tan_f32   :: proc "contextless" (θ: f32)   -> f32   { return sin(θ)/cos(θ) }
@(require_results) tan_f32le :: proc "contextless" (θ: f32le) -> f32le { return f32le(tan_f32(f32(θ))) }
@(require_results) tan_f32be :: proc "contextless" (θ: f32be) -> f32be { return f32be(tan_f32(f32(θ))) }

@(require_results) tan_f64   :: proc "contextless" (θ: f64)   -> f64   { return sin(θ)/cos(θ) }
@(require_results) tan_f64le :: proc "contextless" (θ: f64le) -> f64le { return f64le(tan_f64(f64(θ))) }
@(require_results) tan_f64be :: proc "contextless" (θ: f64be) -> f64be { return f64be(tan_f64(f64(θ))) }
tan :: proc{
	tan_f16, tan_f16le, tan_f16be,
	tan_f32, tan_f32le, tan_f32be,
	tan_f64, tan_f64le, tan_f64be,
}

@(require_results) lerp :: proc "contextless" (a, b: $T, t: $E) -> (x: T) { return a*(1-t) + b*t }
@(require_results) saturate :: proc "contextless" (a: $T) -> (x: T) { return clamp(a, 0, 1) }

@(require_results)
unlerp :: proc "contextless" (a, b, x: $T) -> (t: T) where intrinsics.type_is_float(T), !intrinsics.type_is_array(T) {
	return (x-a)/(b-a)
}

@(require_results)
remap :: proc "contextless" (old_value, old_min, old_max, new_min, new_max: $T) -> (x: T) where intrinsics.type_is_numeric(T), !intrinsics.type_is_array(T) {
	old_range := old_max - old_min
	new_range := new_max - new_min
	if old_range == 0 {
		return new_range / 2
	}
	return ((old_value - old_min) / old_range) * new_range + new_min
}

@(require_results)
wrap :: proc "contextless" (x, y: $T) -> T where intrinsics.type_is_numeric(T), !intrinsics.type_is_array(T) {
	tmp := mod(x, y)
	return y + tmp if tmp < 0 else tmp
}
@(require_results)
angle_diff :: proc "contextless" (a, b: $T) -> T where intrinsics.type_is_numeric(T), !intrinsics.type_is_array(T) {

	dist := wrap(b - a, TAU)
	return wrap(dist*2, TAU) - dist
}

@(require_results)
angle_lerp :: proc "contextless" (a, b, t: $T) -> T where intrinsics.type_is_numeric(T), !intrinsics.type_is_array(T) {
	return a + angle_diff(a, b) * t
}

@(require_results)
step :: proc "contextless" (edge, x: $T) -> T where intrinsics.type_is_numeric(T), !intrinsics.type_is_array(T) {
	return 0 if x < edge else 1
}

@(require_results)
smoothstep :: proc "contextless" (edge0, edge1, x: $T) -> T where intrinsics.type_is_numeric(T), !intrinsics.type_is_array(T) {
	t := clamp((x - edge0) / (edge1 - edge0), 0, 1)
	return t * t * (3 - 2*t)
}

@(require_results)
bias :: proc "contextless" (t, b: $T) -> T where intrinsics.type_is_numeric(T) {
	return t / (((1/b) - 2) * (1 - t) + 1)
}
@(require_results)
gain :: proc "contextless" (t, g: $T) -> T where intrinsics.type_is_numeric(T) {
	if t < 0.5 {
		return bias(t*2, g)*0.5
	}
	return bias(t*2 - 1, 1 - g)*0.5 + 0.5
}


@(require_results) sign_f16   :: proc "contextless" (x: f16)   -> f16   { return f16(int(0 < x) - int(x < 0)) }
@(require_results) sign_f16le :: proc "contextless" (x: f16le) -> f16le { return f16le(int(0 < x) - int(x < 0)) }
@(require_results) sign_f16be :: proc "contextless" (x: f16be) -> f16be { return f16be(int(0 < x) - int(x < 0)) }
@(require_results) sign_f32   :: proc "contextless" (x: f32)   -> f32   { return f32(int(0 < x) - int(x < 0)) }
@(require_results) sign_f32le :: proc "contextless" (x: f32le) -> f32le { return f32le(int(0 < x) - int(x < 0)) }
@(require_results) sign_f32be :: proc "contextless" (x: f32be) -> f32be { return f32be(int(0 < x) - int(x < 0)) }
@(require_results) sign_f64   :: proc "contextless" (x: f64)   -> f64   { return f64(int(0 < x) - int(x < 0)) }
@(require_results) sign_f64le :: proc "contextless" (x: f64le) -> f64le { return f64le(int(0 < x) - int(x < 0)) }
@(require_results) sign_f64be :: proc "contextless" (x: f64be) -> f64be { return f64be(int(0 < x) - int(x < 0)) }
sign :: proc{
	sign_f16, sign_f16le, sign_f16be,
	sign_f32, sign_f32le, sign_f32be,
	sign_f64, sign_f64le, sign_f64be,
}

@(require_results) sign_bit_f16   :: proc "contextless" (x: f16)   -> bool { return (transmute(u16)x) & (1<<15) != 0 }
@(require_results) sign_bit_f16le :: proc "contextless" (x: f16le) -> bool { return #force_inline sign_bit_f16(f16(x)) }
@(require_results) sign_bit_f16be :: proc "contextless" (x: f16be) -> bool { return #force_inline sign_bit_f16(f16(x)) }
@(require_results) sign_bit_f32   :: proc "contextless" (x: f32)   -> bool { return (transmute(u32)x) & (1<<31) != 0 }
@(require_results) sign_bit_f32le :: proc "contextless" (x: f32le) -> bool { return #force_inline sign_bit_f32(f32(x)) }
@(require_results) sign_bit_f32be :: proc "contextless" (x: f32be) -> bool { return #force_inline sign_bit_f32(f32(x)) }
@(require_results) sign_bit_f64   :: proc "contextless" (x: f64)   -> bool { return (transmute(u64)x) & (1<<63) != 0 }
@(require_results) sign_bit_f64le :: proc "contextless" (x: f64le) -> bool { return #force_inline sign_bit_f64(f64(x)) }
@(require_results) sign_bit_f64be :: proc "contextless" (x: f64be) -> bool { return #force_inline sign_bit_f64(f64(x)) }
sign_bit :: proc{
	sign_bit_f16, sign_bit_f16le, sign_bit_f16be,
	sign_bit_f32, sign_bit_f32le, sign_bit_f32be,
	sign_bit_f64, sign_bit_f64le, sign_bit_f64be,
}

@(require_results)
copy_sign_f16 :: proc "contextless" (x, y: f16) -> f16 {
	ix := transmute(u16)x
	iy := transmute(u16)y
	ix &= 0x7fff
	ix |= iy & 0x8000
	return transmute(f16)ix
}
@(require_results) copy_sign_f16le :: proc "contextless" (x, y: f16le) -> f16le { return #force_inline f16le(copy_sign_f16(f16(x), f16(y))) }
@(require_results) copy_sign_f16be :: proc "contextless" (x, y: f16be) -> f16be { return #force_inline f16be(copy_sign_f16(f16(x), f16(y))) }
@(require_results)
copy_sign_f32   :: proc "contextless" (x, y: f32) -> f32 {
	ix := transmute(u32)x
	iy := transmute(u32)y
	ix &= 0x7fff_ffff
	ix |= iy & 0x8000_0000
	return transmute(f32)ix
}
@(require_results) copy_sign_f32le :: proc "contextless" (x, y: f32le) -> f32le { return #force_inline f32le(copy_sign_f32(f32(x), f32(y))) }
@(require_results) copy_sign_f32be :: proc "contextless" (x, y: f32be) -> f32be { return #force_inline f32be(copy_sign_f32(f32(x), f32(y))) }
@(require_results)
copy_sign_f64 :: proc "contextless" (x, y: f64) -> f64 {
	ix := transmute(u64)x
	iy := transmute(u64)y
	ix &= 0x7fff_ffff_ffff_ffff
	ix |= iy & 0x8000_0000_0000_0000
	return transmute(f64)ix
}
@(require_results) copy_sign_f64le :: proc "contextless" (x, y: f64le) -> f64le { return #force_inline f64le(copy_sign_f64(f64(x), f64(y))) }
@(require_results) copy_sign_f64be :: proc "contextless" (x, y: f64be) -> f64be { return #force_inline f64be(copy_sign_f64(f64(x), f64(y))) }
copy_sign :: proc{
	copy_sign_f16, copy_sign_f16le, copy_sign_f16be,
	copy_sign_f32, copy_sign_f32le, copy_sign_f32be,
	copy_sign_f64, copy_sign_f64le, copy_sign_f64be,
}

@(require_results) to_radians_f16   :: proc "contextless" (degrees: f16)   -> f16   { return degrees * RAD_PER_DEG }
@(require_results) to_radians_f16le :: proc "contextless" (degrees: f16le) -> f16le { return degrees * RAD_PER_DEG }
@(require_results) to_radians_f16be :: proc "contextless" (degrees: f16be) -> f16be { return degrees * RAD_PER_DEG }
@(require_results) to_radians_f32   :: proc "contextless" (degrees: f32)   -> f32   { return degrees * RAD_PER_DEG }
@(require_results) to_radians_f32le :: proc "contextless" (degrees: f32le) -> f32le { return degrees * RAD_PER_DEG }
@(require_results) to_radians_f32be :: proc "contextless" (degrees: f32be) -> f32be { return degrees * RAD_PER_DEG }
@(require_results) to_radians_f64   :: proc "contextless" (degrees: f64)   -> f64   { return degrees * RAD_PER_DEG }
@(require_results) to_radians_f64le :: proc "contextless" (degrees: f64le) -> f64le { return degrees * RAD_PER_DEG }
@(require_results) to_radians_f64be :: proc "contextless" (degrees: f64be) -> f64be { return degrees * RAD_PER_DEG }
@(require_results) to_degrees_f16   :: proc "contextless" (radians: f16)   -> f16   { return radians * DEG_PER_RAD }
@(require_results) to_degrees_f16le :: proc "contextless" (radians: f16le) -> f16le { return radians * DEG_PER_RAD }
@(require_results) to_degrees_f16be :: proc "contextless" (radians: f16be) -> f16be { return radians * DEG_PER_RAD }
@(require_results) to_degrees_f32   :: proc "contextless" (radians: f32)   -> f32   { return radians * DEG_PER_RAD }
@(require_results) to_degrees_f32le :: proc "contextless" (radians: f32le) -> f32le { return radians * DEG_PER_RAD }
@(require_results) to_degrees_f32be :: proc "contextless" (radians: f32be) -> f32be { return radians * DEG_PER_RAD }
@(require_results) to_degrees_f64   :: proc "contextless" (radians: f64)   -> f64   { return radians * DEG_PER_RAD }
@(require_results) to_degrees_f64le :: proc "contextless" (radians: f64le) -> f64le { return radians * DEG_PER_RAD }
@(require_results) to_degrees_f64be :: proc "contextless" (radians: f64be) -> f64be { return radians * DEG_PER_RAD }
to_radians :: proc{
	to_radians_f16, to_radians_f16le, to_radians_f16be,
	to_radians_f32, to_radians_f32le, to_radians_f32be,
	to_radians_f64, to_radians_f64le, to_radians_f64be,
}
to_degrees :: proc{
	to_degrees_f16, to_degrees_f16le, to_degrees_f16be,
	to_degrees_f32, to_degrees_f32le, to_degrees_f32be,
	to_degrees_f64, to_degrees_f64le, to_degrees_f64be,
}

@(require_results)
trunc_f16 :: proc "contextless" (x: f16) -> f16 {
	trunc_internal :: proc "contextless" (f: f16) -> f16 {
		mask  :: F16_MASK
		shift :: F16_SHIFT
		bias  :: F16_BIAS

		if f < 1 {
			switch {
			case f < 0:  return -trunc_internal(-f)
			case f == 0: return f
			case:        return 0
			}
		}

		x := transmute(u16)f
		e := (x >> shift) & mask - bias

		if e < shift {
			x &~= 1 << (shift-e) - 1
		}
		return transmute(f16)x
	}
	switch classify(x) {
	case .Zero, .Neg_Zero, .NaN, .Inf, .Neg_Inf:
		return x
	case .Normal, .Subnormal: // carry on
	}
	return trunc_internal(x)
}
@(require_results) trunc_f16le :: proc "contextless" (x: f16le) -> f16le { return #force_inline f16le(trunc_f16(f16(x))) }
@(require_results) trunc_f16be :: proc "contextless" (x: f16be) -> f16be { return #force_inline f16be(trunc_f16(f16(x))) }

@(require_results)
trunc_f32 :: proc "contextless" (x: f32) -> f32 {
	trunc_internal :: proc "contextless" (f: f32) -> f32 {
		mask  :: F32_MASK
		shift :: F32_SHIFT
		bias  :: F32_BIAS

		if f < 1 {
			switch {
			case f < 0:  return -trunc_internal(-f)
			case f == 0: return f
			case:        return 0
			}
		}

		x := transmute(u32)f
		e := (x >> shift) & mask - bias

		if e < shift {
			x &~= 1 << (shift-e) - 1
		}
		return transmute(f32)x
	}
	switch classify(x) {
	case .Zero, .Neg_Zero, .NaN, .Inf, .Neg_Inf:
		return x
	case .Normal, .Subnormal: // carry on
	}
	return trunc_internal(x)
}
@(require_results) trunc_f32le :: proc "contextless" (x: f32le) -> f32le { return #force_inline f32le(trunc_f32(f32(x))) }
@(require_results) trunc_f32be :: proc "contextless" (x: f32be) -> f32be { return #force_inline f32be(trunc_f32(f32(x))) }

@(require_results)
trunc_f64 :: proc "contextless" (x: f64) -> f64 {
	trunc_internal :: proc "contextless" (f: f64) -> f64 {
		mask  :: F64_MASK
		shift :: F64_SHIFT
		bias  :: F64_BIAS

		if f < 1 {
			switch {
			case f < 0:  return -trunc_internal(-f)
			case f == 0: return f
			case:        return 0
			}
		}

		x := transmute(u64)f
		e := (x >> shift) & mask - bias

		if e < shift {
			x &~= 1 << (shift-e) - 1
		}
		return transmute(f64)x
	}
	switch classify(x) {
	case .Zero, .Neg_Zero, .NaN, .Inf, .Neg_Inf:
		return x
	case .Normal, .Subnormal: // carry on
	}
	return trunc_internal(x)
}
@(require_results) trunc_f64le :: proc "contextless" (x: f64le) -> f64le { return #force_inline f64le(trunc_f64(f64(x))) }
@(require_results) trunc_f64be :: proc "contextless" (x: f64be) -> f64be { return #force_inline f64be(trunc_f64(f64(x))) }
// Removes the fractional part of the value, i.e. rounds towards zero.
trunc :: proc{
	trunc_f16, trunc_f16le, trunc_f16be,
	trunc_f32, trunc_f32le, trunc_f32be, 
	trunc_f64, trunc_f64le, trunc_f64be, 
}

@(require_results)
round_f16 :: proc "contextless" (x: f16) -> f16 {
	// origin: Go /src/math/floor.go
	//
	// Copyright (c) 2009 The Go Authors. All rights reserved.
	//
	// Redistribution and use in source and binary forms, with or without
	// modification, are permitted provided that the following conditions are
	// met:
	//
	//    * Redistributions of source code must retain the above copyright
	// notice, this list of conditions and the following disclaimer.
	//    * Redistributions in binary form must reproduce the above
	// copyright notice, this list of conditions and the following disclaimer
	// in the documentation and/or other materials provided with the
	// distribution.
	//    * Neither the name of Google Inc. nor the names of its
	// contributors may be used to endorse or promote products derived from
	// this software without specific prior written permission.
	//
	// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
	// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
	// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
	// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
	// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
	// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
	// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
	// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
	// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
	// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

	mask  :: F16_MASK
	shift :: F16_SHIFT
	bias  :: F16_BIAS

	bits := transmute(u16)x
	e := (bits >> shift) & mask

	if e < bias {
		bits &= 0x8000
		if e == bias - 1 {
			bits |= transmute(u16)f16(1)
		}
	} else if e < bias + shift {
		half     :: 1 << (shift - 1)
		mantissa :: (1 << shift) - 1
		e -= bias
		bits += half >> e
		bits &~= mantissa >> e
	}

	return transmute(f16)bits
}
@(require_results) round_f16le :: proc "contextless" (x: f16le) -> f16le { return #force_inline f16le(round_f16(f16(x))) }
@(require_results) round_f16be :: proc "contextless" (x: f16be) -> f16be { return #force_inline f16be(round_f16(f16(x))) }

@(require_results)
round_f32 :: proc "contextless" (x: f32) -> f32 {
	// origin: Go /src/math/floor.go
	//
	// Copyright (c) 2009 The Go Authors. All rights reserved.
	//
	// Redistribution and use in source and binary forms, with or without
	// modification, are permitted provided that the following conditions are
	// met:
	//
	//    * Redistributions of source code must retain the above copyright
	// notice, this list of conditions and the following disclaimer.
	//    * Redistributions in binary form must reproduce the above
	// copyright notice, this list of conditions and the following disclaimer
	// in the documentation and/or other materials provided with the
	// distribution.
	//    * Neither the name of Google Inc. nor the names of its
	// contributors may be used to endorse or promote products derived from
	// this software without specific prior written permission.
	//
	// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
	// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
	// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
	// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
	// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
	// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
	// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
	// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
	// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
	// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

	mask  :: F32_MASK
	shift :: F32_SHIFT
	bias  :: F32_BIAS

	bits := transmute(u32)x
	e := (bits >> shift) & mask

	if e < bias {
		bits &= 0x8000_0000
		if e == bias - 1 {
			bits |= transmute(u32)f32(1)
		}
	} else if e < bias + shift {
		half     :: 1 << (shift - 1)
		mantissa :: (1 << shift) - 1
		e -= bias
		bits += half >> e
		bits &~= mantissa >> e
	}

	return transmute(f32)bits
}
@(require_results) round_f32le :: proc "contextless" (x: f32le) -> f32le { return #force_inline f32le(round_f32(f32(x))) }
@(require_results) round_f32be :: proc "contextless" (x: f32be) -> f32be { return #force_inline f32be(round_f32(f32(x))) }

@(require_results)
round_f64 :: proc "contextless" (x: f64) -> f64 {
	// origin: Go /src/math/floor.go
	//
	// Copyright (c) 2009 The Go Authors. All rights reserved.
	//
	// Redistribution and use in source and binary forms, with or without
	// modification, are permitted provided that the following conditions are
	// met:
	//
	//    * Redistributions of source code must retain the above copyright
	// notice, this list of conditions and the following disclaimer.
	//    * Redistributions in binary form must reproduce the above
	// copyright notice, this list of conditions and the following disclaimer
	// in the documentation and/or other materials provided with the
	// distribution.
	//    * Neither the name of Google Inc. nor the names of its
	// contributors may be used to endorse or promote products derived from
	// this software without specific prior written permission.
	//
	// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
	// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
	// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
	// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
	// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
	// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
	// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
	// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
	// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
	// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

	mask  :: F64_MASK
	shift :: F64_SHIFT
	bias  :: F64_BIAS

	bits := transmute(u64)x
	e := (bits >> shift) & mask

	if e < bias {
		bits &= 0x8000_0000_0000_0000
		if e == bias - 1 {
			bits |= transmute(u64)f64(1)
		}
	} else if e < bias + shift {
		half     :: 1 << (shift - 1)
		mantissa :: (1 << shift) - 1
		e -= bias
		bits += half >> e
		bits &~= mantissa >> e
	}

	return transmute(f64)bits
}
@(require_results) round_f64le :: proc "contextless" (x: f64le) -> f64le { return #force_inline f64le(round_f64(f64(x))) }
@(require_results) round_f64be :: proc "contextless" (x: f64be) -> f64be { return #force_inline f64be(round_f64(f64(x))) }
round :: proc{
	round_f16, round_f16le, round_f16be,
	round_f32, round_f32le, round_f32be,
	round_f64, round_f64le, round_f64be,
}


@(require_results) ceil_f16   :: proc "contextless" (x: f16)   -> f16   { return -floor(-x) }
@(require_results) ceil_f16le :: proc "contextless" (x: f16le) -> f16le { return -floor(-x) }
@(require_results) ceil_f16be :: proc "contextless" (x: f16be) -> f16be { return -floor(-x) }

@(require_results) ceil_f32   :: proc "contextless" (x: f32)   -> f32   { return -floor(-x) }
@(require_results) ceil_f32le :: proc "contextless" (x: f32le) -> f32le { return -floor(-x) }
@(require_results) ceil_f32be :: proc "contextless" (x: f32be) -> f32be { return -floor(-x) }

@(require_results) ceil_f64   :: proc "contextless" (x: f64)   -> f64   { return -floor(-x) }
@(require_results) ceil_f64le :: proc "contextless" (x: f64le) -> f64le { return -floor(-x) }
@(require_results) ceil_f64be :: proc "contextless" (x: f64be) -> f64be { return -floor(-x) }

ceil :: proc{
	ceil_f16, ceil_f16le, ceil_f16be,
	ceil_f32, ceil_f32le, ceil_f32be,
	ceil_f64, ceil_f64le, ceil_f64be,
}

@(require_results)
floor_f16   :: proc "contextless" (x: f16)   -> f16 {
	if x == 0 || is_nan(x) || is_inf(x) {
		return x
	}
	if x < 0 {
		d, fract := modf(-x)
		if fract != 0.0 {
			d = d + 1
		}
		return -d
	}
	d, _ := modf(x)
	return d
}
@(require_results) floor_f16le :: proc "contextless" (x: f16le) -> f16le { return #force_inline f16le(floor_f16(f16(x))) }
@(require_results) floor_f16be :: proc "contextless" (x: f16be) -> f16be { return #force_inline f16be(floor_f16(f16(x))) }
@(require_results)
floor_f32 :: proc "contextless" (x: f32)   -> f32 {
	if x == 0 || is_nan(x) || is_inf(x) {
		return x
	}
	if x < 0 {
		d, fract := modf(-x)
		if fract != 0.0 {
			d = d + 1
		}
		return -d
	}
	d, _ := modf(x)
	return d
}
@(require_results) floor_f32le :: proc "contextless" (x: f32le) -> f32le { return #force_inline f32le(floor_f32(f32(x))) }
@(require_results) floor_f32be :: proc "contextless" (x: f32be) -> f32be { return #force_inline f32be(floor_f32(f32(x))) }
@(require_results)
floor_f64   :: proc "contextless" (x: f64)   -> f64 {
	if x == 0 || is_nan(x) || is_inf(x) {
		return x
	}
	if x < 0 {
		d, fract := modf(-x)
		if fract != 0.0 {
			d = d + 1
		}
		return -d
	}
	d, _ := modf(x)
	return d
}
@(require_results) floor_f64le :: proc "contextless" (x: f64le) -> f64le { return #force_inline f64le(floor_f64(f64(x))) }
@(require_results) floor_f64be :: proc "contextless" (x: f64be) -> f64be { return #force_inline f64be(floor_f64(f64(x))) }
floor :: proc{
	floor_f16, floor_f16le, floor_f16be,
	floor_f32, floor_f32le, floor_f32be,
	floor_f64, floor_f64le, floor_f64be,
}


@(require_results)
floor_div :: proc "contextless" (x, y: $T) -> T
	where intrinsics.type_is_integer(T) {
	a := x / y
	r := x % y
	if (r > 0 && y < 0) || (r < 0 && y > 0) {
		a -= 1
	}
	return a
}

@(require_results)
floor_mod :: proc "contextless" (x, y: $T) -> T
	where intrinsics.type_is_integer(T) {
	r := x % y
	if (r > 0 && y < 0) || (r < 0 && y > 0) {
		r += y
	}
	return r
}

@(require_results)
divmod :: #force_inline proc "contextless" (x, y: $T) -> (div, mod: T)
	where intrinsics.type_is_integer(T) {
	div = x / y
	mod = x % y
	return
}

@(require_results)
floor_divmod :: #force_inline proc "contextless" (x, y: $T) -> (div, mod: T)
	where intrinsics.type_is_integer(T) {
	div = x / y
	mod = x % y
	if (div > 0 && y < 0) || (mod < 0 && y > 0) {
		div -= 1
		mod += y
	}
	return
}


@(require_results)
modf_f16   :: proc "contextless" (x: f16) -> (int: f16, frac: f16) {
	shift :: F16_SHIFT
	mask  :: F16_MASK
	bias  :: F16_BIAS

	if x < 1 {
		switch {
		case x < 0:
			int, frac = modf(-x)
			return -int, -frac
		case x == 0:
			return x, x
		}
		return 0, x
	}

	i := transmute(u16)x
	e := uint(i>>shift)&mask - bias

	if e < shift {
		i &~= 1<<(shift-e) - 1
	}
	int = transmute(f16)i
	frac = x - int
	return
}
@(require_results)
modf_f16le :: proc "contextless" (x: f16le) -> (int: f16le, frac: f16le) {
	i, f := #force_inline modf_f16(f16(x))
	return f16le(i), f16le(f)
}
@(require_results)
modf_f16be :: proc "contextless" (x: f16be) -> (int: f16be, frac: f16be) {
	i, f := #force_inline modf_f16(f16(x))
	return f16be(i), f16be(f)
}
@(require_results)
modf_f32 :: proc "contextless" (x: f32) -> (int: f32, frac: f32) {
	shift :: F32_SHIFT
	mask  :: F32_MASK
	bias  :: F32_BIAS

	if x < 1 {
		switch {
		case x < 0:
			int, frac = modf(-x)
			return -int, -frac
		case x == 0:
			return x, x
		}
		return 0, x
	}

	i := transmute(u32)x
	e := uint(i>>shift)&mask - bias

	if e < shift {
		i &~= 1<<(shift-e) - 1
	}
	int = transmute(f32)i
	frac = x - int
	return
}
@(require_results)
modf_f32le :: proc "contextless" (x: f32le) -> (int: f32le, frac: f32le) {
	i, f := #force_inline modf_f32(f32(x))
	return f32le(i), f32le(f)
}
@(require_results)
modf_f32be :: proc "contextless" (x: f32be) -> (int: f32be, frac: f32be) {
	i, f := #force_inline modf_f32(f32(x))
	return f32be(i), f32be(f)
}
@(require_results)
modf_f64 :: proc "contextless" (x: f64) -> (int: f64, frac: f64) {
	shift :: F64_SHIFT
	mask  :: F64_MASK
	bias  :: F64_BIAS

	if x < 1 {
		switch {
		case x < 0:
			int, frac = modf(-x)
			return -int, -frac
		case x == 0:
			return x, x
		}
		return 0, x
	}

	i := transmute(u64)x
	e := uint(i>>shift)&mask - bias

	if e < shift {
		i &~= 1<<(shift-e) - 1
	}
	int = transmute(f64)i
	frac = x - int
	return
}
@(require_results)
modf_f64le :: proc "contextless" (x: f64le) -> (int: f64le, frac: f64le) {
	i, f := #force_inline modf_f64(f64(x))
	return f64le(i), f64le(f)
}
@(require_results)
modf_f64be :: proc "contextless" (x: f64be) -> (int: f64be, frac: f64be) {
	i, f := #force_inline modf_f64(f64(x))
	return f64be(i), f64be(f)
}
modf :: proc{
	modf_f16, modf_f16le, modf_f16be,
	modf_f32, modf_f32le, modf_f32be,
	modf_f64, modf_f64le, modf_f64be,
}
split_decimal :: modf

@(require_results)
mod_f16 :: proc "contextless" (x, y: f16) -> (n: f16) {
	z := abs(y)
	n = remainder(abs(x), z)
	if sign(n) < 0 {
		n += z
	}
	return copy_sign(n, x)
}
@(require_results) mod_f16le :: proc "contextless" (x, y: f16le) -> (n: f16le) { return #force_inline f16le(mod_f16(f16(x), f16(y))) }
@(require_results) mod_f16be :: proc "contextless" (x, y: f16be) -> (n: f16be) { return #force_inline f16be(mod_f16(f16(x), f16(y))) }
@(require_results)
mod_f32 :: proc "contextless" (x, y: f32)   -> (n: f32) {
	z := abs(y)
	n = remainder(abs(x), z)
	if sign(n) < 0 {
		n += z
	}
	return copy_sign(n, x)
}
@(require_results)
mod_f32le :: proc "contextless" (x, y: f32le) -> (n: f32le) { return #force_inline f32le(mod_f32(f32(x), f32(y))) }
@(require_results)
mod_f32be :: proc "contextless" (x, y: f32be) -> (n: f32be) { return #force_inline f32be(mod_f32(f32(x), f32(y))) }
@(require_results)
mod_f64 :: proc "contextless" (x, y: f64)   -> (n: f64) {
	z := abs(y)
	n = remainder(abs(x), z)
	if sign(n) < 0 {
		n += z
	}
	return copy_sign(n, x)
}
@(require_results)
mod_f64le :: proc "contextless" (x, y: f64le) -> (n: f64le) { return #force_inline f64le(mod_f64(f64(x), f64(y))) }
@(require_results)
mod_f64be :: proc "contextless" (x, y: f64be) -> (n: f64be) { return #force_inline f64be(mod_f64(f64(x), f64(y))) }
mod :: proc{
	mod_f16, mod_f16le, mod_f16be,
	mod_f32, mod_f32le, mod_f32be,
	mod_f64, mod_f64le, mod_f64be,
}

@(require_results) remainder_f16   :: proc "contextless" (x, y: f16  ) -> f16   { return x - round(x/y) * y }
@(require_results) remainder_f16le :: proc "contextless" (x, y: f16le) -> f16le { return x - round(x/y) * y }
@(require_results) remainder_f16be :: proc "contextless" (x, y: f16be) -> f16be { return x - round(x/y) * y }
@(require_results) remainder_f32   :: proc "contextless" (x, y: f32  ) -> f32   { return x - round(x/y) * y }
@(require_results) remainder_f32le :: proc "contextless" (x, y: f32le) -> f32le { return x - round(x/y) * y }
@(require_results) remainder_f32be :: proc "contextless" (x, y: f32be) -> f32be { return x - round(x/y) * y }
@(require_results) remainder_f64   :: proc "contextless" (x, y: f64  ) -> f64   { return x - round(x/y) * y }
@(require_results) remainder_f64le :: proc "contextless" (x, y: f64le) -> f64le { return x - round(x/y) * y }
@(require_results) remainder_f64be :: proc "contextless" (x, y: f64be) -> f64be { return x - round(x/y) * y }
remainder :: proc{
	remainder_f16, remainder_f16le, remainder_f16be,
	remainder_f32, remainder_f32le, remainder_f32be,
	remainder_f64, remainder_f64le, remainder_f64be,
}

@(require_results)
gcd :: proc "contextless" (x, y: $T) -> T
	where intrinsics.type_is_ordered_numeric(T) {
	x, y := x, y
	for y != 0 {
		x %= y
		x, y = y, x
	}
	return abs(x)
}

@(require_results)
lcm :: proc "contextless" (x, y: $T) -> T
	where intrinsics.type_is_ordered_numeric(T) {
	return x / gcd(x, y) * y
}

@(require_results)
normalize_f16 :: proc "contextless" (x: f16) -> (y: f16, exponent: int) {
	if abs(x) < F16_MIN {
		return x * (1<<F16_SHIFT), -F16_SHIFT
	}
	return x, 0
}
@(require_results)
normalize_f32 :: proc "contextless" (x: f32) -> (y: f32, exponent: int) {
	if abs(x) < F32_MIN {
		return x * (1<<F32_SHIFT), -F32_SHIFT
	}
	return x, 0
}
@(require_results)
normalize_f64 :: proc "contextless" (x: f64) -> (y: f64, exponent: int) {
	if abs(x) < F64_MIN {
		return x * (1<<F64_SHIFT), -F64_SHIFT
	}
	return x, 0
}

@(require_results) normalize_f16le :: proc "contextless" (x: f16le) -> (y: f16le, exponent: int) { y0, e := normalize_f16(f16(x)); return f16le(y0), e }
@(require_results) normalize_f16be :: proc "contextless" (x: f16be) -> (y: f16be, exponent: int) { y0, e := normalize_f16(f16(x)); return f16be(y0), e }
@(require_results) normalize_f32le :: proc "contextless" (x: f32le) -> (y: f32le, exponent: int) { y0, e := normalize_f32(f32(x)); return f32le(y0), e }
@(require_results) normalize_f32be :: proc "contextless" (x: f32be) -> (y: f32be, exponent: int) { y0, e := normalize_f32(f32(x)); return f32be(y0), e }
@(require_results) normalize_f64le :: proc "contextless" (x: f64le) -> (y: f64le, exponent: int) { y0, e := normalize_f64(f64(x)); return f64le(y0), e }
@(require_results) normalize_f64be :: proc "contextless" (x: f64be) -> (y: f64be, exponent: int) { y0, e := normalize_f64(f64(x)); return f64be(y0), e }

normalize :: proc{
	normalize_f16,
	normalize_f32,
	normalize_f64,
	normalize_f16le,
	normalize_f16be,
	normalize_f32le,
	normalize_f32be,
	normalize_f64le,
	normalize_f64be,
}

@(require_results)
frexp_f16   :: proc "contextless" (x: f16)   -> (significand: f16,   exponent: int) {
	f, e := frexp_f64(f64(x))
	return f16(f), e
}
@(require_results)
frexp_f16le :: proc "contextless" (x: f16le) -> (significand: f16le, exponent: int) {
	f, e := frexp_f64(f64(x))
	return f16le(f), e
}
@(require_results)
frexp_f16be :: proc "contextless" (x: f16be) -> (significand: f16be, exponent: int) {
	f, e := frexp_f64(f64(x))
	return f16be(f), e
}
@(require_results)
frexp_f32 :: proc "contextless" (x: f32)     -> (significand: f32,   exponent: int) {
	f, e := frexp_f64(f64(x))
	return f32(f), e
}
@(require_results)
frexp_f32le :: proc "contextless" (x: f32le) -> (significand: f32le, exponent: int) {
	f, e := frexp_f64(f64(x))
	return f32le(f), e
}
@(require_results)
frexp_f32be :: proc "contextless" (x: f32be) -> (significand: f32be, exponent: int) {
	f, e := frexp_f64(f64(x))
	return f32be(f), e
}
@(require_results)
frexp_f64 :: proc "contextless" (f: f64) -> (significand: f64, exponent: int) {
	mask  :: F64_MASK
	shift :: F64_SHIFT
	bias  :: F64_BIAS
	
	switch {
	case f == 0:
		return 0, 0
	case is_inf(f) || is_nan(f):
		return f, 0
	}
	f := f
	
	f, exponent = normalize_f64(f)
	x := transmute(u64)f
	exponent += int((x>>shift)&mask) - bias + 1
	x &~= mask << shift
	x |= (-1 + bias) << shift
	significand = transmute(f64)x
	return
}
@(require_results)
frexp_f64le :: proc "contextless" (x: f64le) -> (significand: f64le, exponent: int) {
	f, e := frexp_f64(f64(x))
	return f64le(f), e
}
@(require_results)
frexp_f64be :: proc "contextless" (x: f64be) -> (significand: f64be, exponent: int) {
	f, e := frexp_f64(f64(x))
	return f64be(f), e
}

// frexp breaks the value into a normalized fraction, and an integral power of two
// It returns a significand and exponent satisfying x == significand * 2**exponent
// with the absolute value of significand in the intervalue of [0.5, 1).
//
// Special cases: 
// 	frexp(+0)   = +0,   0
// 	frexp(-0)   = -0,   0
// 	frexp(+inf) = +inf, 0
// 	frexp(-inf) = -inf, 0
// 	frexp(NaN)  = NaN,  0
frexp :: proc{
	frexp_f16, frexp_f16le, frexp_f16be,
	frexp_f32, frexp_f32le, frexp_f32be,
	frexp_f64, frexp_f64le, frexp_f64be, 
}




@(require_results)
binomial :: proc "contextless" (n, k: int) -> int {
	switch {
	case k <= 0:  return 1
	case 2*k > n: return binomial(n, n-k)
	}

	b := n
	for i in 2..<k {
		b = (b * (n+1-i))/i
	}
	return b
}

@(require_results)
factorial :: proc "contextless" (n: int) -> int {
	when size_of(int) == size_of(i64) {
		@static table := [21]int{
			1,
			1,
			2,
			6,
			24,
			120,
			720,
			5_040,
			40_320,
			362_880,
			3_628_800,
			39_916_800,
			479_001_600,
			6_227_020_800,
			87_178_291_200,
			1_307_674_368_000,
			20_922_789_888_000,
			355_687_428_096_000,
			6_402_373_705_728_000,
			121_645_100_408_832_000,
			2_432_902_008_176_640_000,
		}
	} else {
		@static table := [13]int{
			1,
			1,
			2,
			6,
			24,
			120,
			720,
			5_040,
			40_320,
			362_880,
			3_628_800,
			39_916_800,
			479_001_600,
		}
	}
	return table[n]
}

@(require_results)
classify_f16 :: proc "contextless" (x: f16)   -> Float_Class {
	switch {
	case x == 0:
		i := transmute(i16)x
		if i < 0 {
			return .Neg_Zero
		}
		return .Zero
	case x*0.25 == x:
		if x < 0 {
			return .Neg_Inf
		}
		return .Inf
	case !(x == x):
		return .NaN
	}

	u := transmute(u16)x
	exp := int(u>>10) & (1<<5 - 1)
	if exp == 0 {
		return .Subnormal
	}
	return .Normal
}
@(require_results) classify_f16le :: proc "contextless" (x: f16le) -> Float_Class { return #force_inline classify_f16(f16(x)) }
@(require_results) classify_f16be :: proc "contextless" (x: f16be) -> Float_Class { return #force_inline classify_f16(f16(x)) }
@(require_results)
classify_f32   :: proc "contextless" (x: f32)   -> Float_Class {
	switch {
	case x == 0:
		i := transmute(i32)x
		if i < 0 {
			return .Neg_Zero
		}
		return .Zero
	case x*0.5 == x:
		if x < 0 {
			return .Neg_Inf
		}
		return .Inf
	case !(x == x):
		return .NaN
	}

	u := transmute(u32)x
	exp := int(u>>23) & (1<<8 - 1)
	if exp == 0 {
		return .Subnormal
	}
	return .Normal
}
@(require_results) classify_f32le :: proc "contextless" (x: f32le) -> Float_Class { return #force_inline classify_f32(f32(x)) }
@(require_results) classify_f32be :: proc "contextless" (x: f32be) -> Float_Class { return #force_inline classify_f32(f32(x)) }
@(require_results)
classify_f64   :: proc "contextless" (x: f64)   -> Float_Class {
	switch {
	case x == 0:
		i := transmute(i64)x
		if i < 0 {
			return .Neg_Zero
		}
		return .Zero
	case x*0.5 == x:
		if x < 0 {
			return .Neg_Inf
		}
		return .Inf
	case !(x == x):
		return .NaN
	}
	u := transmute(u64)x
	exp := int(u>>52) & (1<<11 - 1)
	if exp == 0 {
		return .Subnormal
	}
	return .Normal
}
@(require_results) classify_f64le :: proc "contextless" (x: f64le) -> Float_Class { return #force_inline classify_f64(f64(x)) }
@(require_results) classify_f64be :: proc "contextless" (x: f64be) -> Float_Class { return #force_inline classify_f64(f64(x)) }
// Returns the `Float_Class` of the value, i.e. whether normal, subnormal, zero, negative zero, NaN, infinity or
// negative infinity.
classify :: proc{
	classify_f16, classify_f16le, classify_f16be,
	classify_f32, classify_f32le, classify_f32be,
	classify_f64, classify_f64le, classify_f64be,
}

@(require_results) is_nan_f16   :: proc "contextless" (x: f16)   -> bool { return classify(x) == .NaN }
@(require_results) is_nan_f16le :: proc "contextless" (x: f16le) -> bool { return classify(x) == .NaN }
@(require_results) is_nan_f16be :: proc "contextless" (x: f16be) -> bool { return classify(x) == .NaN }
@(require_results) is_nan_f32   :: proc "contextless" (x: f32)   -> bool { return classify(x) == .NaN }
@(require_results) is_nan_f32le :: proc "contextless" (x: f32le) -> bool { return classify(x) == .NaN }
@(require_results) is_nan_f32be :: proc "contextless" (x: f32be) -> bool { return classify(x) == .NaN }
@(require_results) is_nan_f64   :: proc "contextless" (x: f64)   -> bool { return classify(x) == .NaN }
@(require_results) is_nan_f64le :: proc "contextless" (x: f64le) -> bool { return classify(x) == .NaN }
@(require_results) is_nan_f64be :: proc "contextless" (x: f64be) -> bool { return classify(x) == .NaN }
is_nan :: proc{
	is_nan_f16, is_nan_f16le, is_nan_f16be,
	is_nan_f32, is_nan_f32le, is_nan_f32be,
	is_nan_f64, is_nan_f64le, is_nan_f64be,
}

// is_inf reports whether f is an infinity, according to sign.
// If sign > 0, is_inf reports whether f is positive infinity.
// If sign < 0, is_inf reports whether f is negative infinity.
// If sign == 0, is_inf reports whether f is either infinity.
@(require_results)
is_inf_f16 :: proc "contextless" (x: f16, sign: int = 0) -> bool {
	class := classify(x)
	switch {
	case sign > 0:
		return class == .Inf
	case sign < 0:
		return class == .Neg_Inf
	}
	return class == .Inf || class == .Neg_Inf
}
@(require_results)
is_inf_f16le :: proc "contextless" (x: f16le, sign: int = 0) -> bool {
	return #force_inline is_inf_f16(f16(x), sign)
}
@(require_results)
is_inf_f16be :: proc "contextless" (x: f16be, sign: int = 0) -> bool {
	return #force_inline is_inf_f16(f16(x), sign)
}

@(require_results)
is_inf_f32 :: proc "contextless" (x: f32, sign: int = 0) -> bool {
	class := classify(x)
	switch {
	case sign > 0:
		return class == .Inf
	case sign < 0:
		return class == .Neg_Inf
	}
	return class == .Inf || class == .Neg_Inf
}
@(require_results)
is_inf_f32le :: proc "contextless" (x: f32le, sign: int = 0) -> bool {
	return #force_inline is_inf_f32(f32(x), sign)
}
@(require_results)
is_inf_f32be :: proc "contextless" (x: f32be, sign: int = 0) -> bool {
	return #force_inline is_inf_f32(f32(x), sign)
}

@(require_results)
is_inf_f64 :: proc "contextless" (x: f64, sign: int = 0) -> bool {
	class := classify(x)
	switch {
	case sign > 0:
		return class == .Inf
	case sign < 0:
		return class == .Neg_Inf
	}
	return class == .Inf || class == .Neg_Inf
}
@(require_results)
is_inf_f64le :: proc "contextless" (x: f64le, sign: int = 0) -> bool {
	return #force_inline is_inf_f64(f64(x), sign)
}
@(require_results)
is_inf_f64be :: proc "contextless" (x: f64be, sign: int = 0) -> bool {
	return #force_inline is_inf_f64(f64(x), sign)
}
is_inf :: proc{
	is_inf_f16, is_inf_f16le, is_inf_f16be,
	is_inf_f32, is_inf_f32le, is_inf_f32be,
	is_inf_f64, is_inf_f64le, is_inf_f64be,
}

@(require_results)
inf_f16   :: proc "contextless" (sign: int) -> f16 {
	return f16(inf_f64(sign))
}
@(require_results)
inf_f16le :: proc "contextless" (sign: int) -> f16le {
	return f16le(inf_f64(sign))
}
@(require_results)
inf_f16be :: proc "contextless" (sign: int) -> f16be {
	return f16be(inf_f64(sign))
}
@(require_results)
inf_f32   :: proc "contextless" (sign: int) -> f32 {
	return f32(inf_f64(sign))
}
@(require_results)
inf_f32le :: proc "contextless" (sign: int) -> f32le {
	return f32le(inf_f64(sign))
}
@(require_results)
inf_f32be :: proc "contextless" (sign: int) -> f32be {
	return f32be(inf_f64(sign))
}
@(require_results)
inf_f64   :: proc "contextless" (sign: int) -> f64 {
	if sign >= 0 {
		return 0h7ff00000_00000000
	} else {
		return 0hfff00000_00000000
	}
}
@(require_results)
inf_f64le :: proc "contextless" (sign: int) -> f64le {
	return f64le(inf_f64(sign))
}
@(require_results)
inf_f64be :: proc "contextless" (sign: int) -> f64be {
	return f64be(inf_f64(sign))
}

@(require_results)
nan_f16   :: proc "contextless" () -> f16 {
	return f16(nan_f64())
}
@(require_results)
nan_f16le :: proc "contextless" () -> f16le {
	return f16le(nan_f64())
}
@(require_results)
nan_f16be :: proc "contextless" () -> f16be {
	return f16be(nan_f64())
}
@(require_results)
nan_f32   :: proc "contextless" () -> f32 {
	return f32(nan_f64())
}
@(require_results)
nan_f32le :: proc "contextless" () -> f32le {
	return f32le(nan_f64())
}
@(require_results)
nan_f32be :: proc "contextless" () -> f32be {
	return f32be(nan_f64())
}
@(require_results)
nan_f64   :: proc "contextless" () -> f64 {
	return 0h7ff80000_00000001
}
@(require_results)
nan_f64le :: proc "contextless" () -> f64le {
	return f64le(nan_f64())
}
@(require_results)
nan_f64be :: proc "contextless" () -> f64be {
	return f64be(nan_f64())
}

@(require_results)
is_power_of_two :: proc "contextless" (x: int) -> bool {
	return x > 0 && (x & (x-1)) == 0
}

@(require_results)
next_power_of_two :: proc "contextless" (x: int) -> int {
	k := x -1
	when size_of(int) == 8 {
		k = k | (k >> 32)
	}
	k = k | (k >> 16)
	k = k | (k >> 8)
	k = k | (k >> 4)
	k = k | (k >> 2)
	k = k | (k >> 1)
	k += 1 + int(x <= 0)
	return k
}

@(require_results)
sum :: proc "contextless" (x: $T/[]$E) -> (res: E)
	where intrinsics.type_is_numeric(E) {
	for i in x {
		res += i
	}
	return
}

@(require_results)
prod :: proc "contextless" (x: $T/[]$E) -> (res: E)
	where intrinsics.type_is_numeric(E) {
	res = 1
	for i in x {
		res *= i
	}
	return
}

cumsum_inplace :: proc "contextless" (x: $T/[]$E)
	where intrinsics.type_is_numeric(E) {
	for i in 1..<len(x) {
		x[i] = x[i-1] + x[i]
	}
}


@(require_results)
cumsum :: proc "contextless" (dst, src: $T/[]$E) -> T
	where intrinsics.type_is_numeric(E) {
	N := min(len(dst), len(src))
	if N > 0 {
		dst[0] = src[0]
		for i in 1..<N {
			dst[i] = dst[i-1] + src[i]
		}
	}
	return dst[:N]
}


@(require_results)
atan2_f16   :: proc "contextless" (y, x: f16)   -> f16 {
	// TODO(bill): Better atan2_f16
	return f16(atan2_f64(f64(y), f64(x)))
}
@(require_results)
atan2_f16le :: proc "contextless" (y, x: f16le) -> f16le {
	// TODO(bill): Better atan2_f16
	return f16le(atan2_f64(f64(y), f64(x)))
}
@(require_results)
atan2_f16be :: proc "contextless" (y, x: f16be) -> f16be {
	// TODO(bill): Better atan2_f16
	return f16be(atan2_f64(f64(y), f64(x)))
}
@(require_results)
atan2_f32 :: proc "contextless" (y, x: f32)     -> f32 {
	// TODO(bill): Better atan2_f32
	return f32(atan2_f64(f64(y), f64(x)))
}
@(require_results)
atan2_f32le :: proc "contextless" (y, x: f32le) -> f32le {
	// TODO(bill): Better atan2_f32
	return f32le(atan2_f64(f64(y), f64(x)))
}
@(require_results)
atan2_f32be :: proc "contextless" (y, x: f32be) -> f32be {
	// TODO(bill): Better atan2_f32
	return f32be(atan2_f64(f64(y), f64(x)))
}

@(require_results)
atan2_f64 :: proc "contextless" (y, x: f64) -> f64 {
	// TODO(bill): Faster atan2_f64 if possible

	// The original C code:
	//   Stephen L. Moshier
	//   moshier@na-net.ornl.gov

	NAN :: 0h7fff_ffff_ffff_ffff
	INF :: 0h7FF0_0000_0000_0000
	PI  :: 0h4009_21fb_5444_2d18

	atan :: proc "contextless" (x: f64) -> f64 {
		if x == 0 {
			return x
		}
		if x > 0 {
			return s_atan(x)
		}
		return -s_atan(-x)
	}
	// s_atan reduces its argument (known to be positive) to the range [0, 0.66] and calls x_atan.
	s_atan :: proc "contextless" (x: f64) -> f64 {
		MORE_BITS :: 6.123233995736765886130e-17 // pi/2 = PIO2 + MORE_BITS
		TAN3PI08  :: 2.41421356237309504880      // tan(3*pi/8)
		if x <= 0.66 {
			return x_atan(x)
		}
		if x > TAN3PI08 {
			return PI/2 - x_atan(1/x) + MORE_BITS
		}
		return PI/4 + x_atan((x-1)/(x+1)) + 0.5*MORE_BITS
	}
	// x_atan evaluates a series valid in the range [0, 0.66].
	x_atan :: proc "contextless" (x: f64) -> f64 {
		P0 :: -8.750608600031904122785e-01
		P1 :: -1.615753718733365076637e+01
		P2 :: -7.500855792314704667340e+01
		P3 :: -1.228866684490136173410e+02
		P4 :: -6.485021904942025371773e+01
		Q0 :: +2.485846490142306297962e+01
		Q1 :: +1.650270098316988542046e+02
		Q2 :: +4.328810604912902668951e+02
		Q3 :: +4.853903996359136964868e+02
		Q4 :: +1.945506571482613964425e+02

		z := x * x
		z = z * ((((P0*z+P1)*z+P2)*z+P3)*z + P4) / (((((z+Q0)*z+Q1)*z+Q2)*z+Q3)*z + Q4)
		z = x*z + x
		return z
	}

	switch {
	case is_nan(y) || is_nan(x):
		return NAN
	case y == 0:
		if x >= 0 && !sign_bit(x) {
			return copy_sign(0.0, y)
		}
		return copy_sign(PI, y)
	case x == 0:
		return copy_sign(PI/2, y)
	case is_inf(x, 0):
		if is_inf(x, 1) {
			if is_inf(y, 0) {
				return copy_sign(PI/4, y)
			}
			return copy_sign(0, y)
		}
		if is_inf(y, 0) {
			return copy_sign(3*PI/4, y)
		}
		return copy_sign(PI, y)
	case is_inf(y, 0):
		return copy_sign(PI/2, y)
	}

	q := atan(y / x)
	if x < 0 {
		if q <= 0 {
			return q + PI
		}
		return q - PI
	}
	return q
}
@(require_results)
atan2_f64le :: proc "contextless" (y, x: f64le) -> f64le {
	// TODO(bill): Better atan2_f32
	return f64le(atan2_f64(f64(y), f64(x)))
}
@(require_results)
atan2_f64be :: proc "contextless" (y, x: f64be) -> f64be {
	// TODO(bill): Better atan2_f32
	return f64be(atan2_f64(f64(y), f64(x)))
}

atan2 :: proc{
	atan2_f64, atan2_f32, atan2_f16,
	atan2_f64le, atan2_f64be,
	atan2_f32le, atan2_f32be,
	atan2_f16le, atan2_f16be,
}

@(require_results)
atan :: proc "contextless" (x: $T) -> T where intrinsics.type_is_float(T) {
	return atan2(x, 1)
}



@(require_results)
asin_f64 :: proc "contextless" (x: f64) -> f64 {
	/* origin: FreeBSD /usr/src/lib/msun/src/e_asin.c */
	/*
	 * ====================================================
	 * Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
	 *
	 * Developed at SunSoft, a Sun Microsystems, Inc. business.
	 * Permission to use, copy, modify, and distribute this
	 * software is freely granted, provided that this notice
	 * is preserved.
	 * ====================================================
	 */

	pio2_hi :: 0h3FF921FB54442D18
	pio2_lo :: 0h3C91A62633145C07
	pS0     :: 0h3FC5555555555555
	pS1     :: 0hBFD4D61203EB6F7D
	pS2     :: 0h3FC9C1550E884455
	pS3     :: 0hBFA48228B5688F3B
	pS4     :: 0h3F49EFE07501B288
	pS5     :: 0h3F023DE10DFDF709
	qS1     :: 0hC0033A271C8A2D4B
	qS2     :: 0h40002AE59C598AC8
	qS3     :: 0hBFE6066C1B8D0159
	qS4     :: 0h3FB3B8C5B12E9282

	R :: #force_inline proc "contextless" (z: f64) -> f64 {
		p, q: f64
		p = z*(pS0+z*(pS1+z*(pS2+z*(pS3+z*(pS4+z*pS5)))))
		q = 1.0+z*(qS1+z*(qS2+z*(qS3+z*qS4)))
		return p/q
	}

	x := x
	z, r, s: f64
	dwords := transmute([2]u32)x
	hx := dwords[1]
	ix := hx & 0x7fffffff
	/* |x| >= 1 or nan */
	if ix >= 0x3ff00000 {
		lx := dwords[0]
		if (ix-0x3ff00000 | lx) == 0 {
			/* asin(1) = +-pi/2 with inexact */
			return x*pio2_hi + 1e-120
		}
		return 0/(x-x)
	}
	/* |x| < 0.5 */
	if ix < 0x3fe00000 {
		/* if 0x1p-1022 <= |x| < 0x1p-26, avoid raising underflow */
		if ix < 0x3e500000 && ix >= 0x00100000 {
			return x
		}
		return x + x*R(x*x)
	}
	/* 1 > |x| >= 0.5 */
	z = (1 - abs(x))*0.5
	s = sqrt(z)
	r = R(z)
	if ix >= 0x3fef3333 {  /* if |x| > 0.975 */
		x = pio2_hi-(2*(s+s*r)-pio2_lo)
	} else {
		f, c: f64
		/* f+c = sqrt(z) */
		f = s
		(^u64)(&f)^ &= 0xffffffff_00000000
		c = (z-f*f)/(s+f)
		x = 0.5*pio2_hi - (2*s*r - (pio2_lo-2*c) - (0.5*pio2_hi-2*f))
	}
	return -x if hx >> 31 != 0 else x
}
@(require_results)
asin_f64le :: proc "contextless" (x: f64le) -> f64le {
	return f64le(asin_f64(f64(x)))
}
@(require_results)
asin_f64be :: proc "contextless" (x: f64be) -> f64be {
	return f64be(asin_f64(f64(x)))
}
@(require_results)
asin_f32 :: proc "contextless" (x: f32) -> f32 {
	return f32(asin_f64(f64(x)))
}
@(require_results)
asin_f32le :: proc "contextless" (x: f32le) -> f32le {
	return f32le(asin_f64(f64(x)))
}
@(require_results)
asin_f32be :: proc "contextless" (x: f32be) -> f32be {
	return f32be(asin_f64(f64(x)))
}
@(require_results)
asin_f16 :: proc "contextless" (x: f16) -> f16 {
	return f16(asin_f64(f64(x)))
}
@(require_results)
asin_f16le :: proc "contextless" (x: f16le) -> f16le {
	return f16le(asin_f64(f64(x)))
}
@(require_results)
asin_f16be :: proc "contextless" (x: f16be) -> f16be {
	return f16be(asin_f64(f64(x)))
}
asin :: proc{
	asin_f64, asin_f32, asin_f16,
	asin_f64le, asin_f64be,
	asin_f32le, asin_f32be,
	asin_f16le, asin_f16be,
}


@(require_results)
acos_f64 :: proc "contextless" (x: f64) -> f64 {
	/* origin: FreeBSD /usr/src/lib/msun/src/e_acos.c */
	/*
	 * ====================================================
	 * Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
	 *
	 * Developed at SunSoft, a Sun Microsystems, Inc. business.
	 * Permission to use, copy, modify, and distribute this
	 * software is freely granted, provided that this notice
	 * is preserved.
	 * ====================================================
	 */

	pio2_hi :: 0h3FF921FB54442D18
	pio2_lo :: 0h3C91A62633145C07
	pS0     :: 0h3FC5555555555555
	pS1     :: 0hBFD4D61203EB6F7D
	pS2     :: 0h3FC9C1550E884455
	pS3     :: 0hBFA48228B5688F3B
	pS4     :: 0h3F49EFE07501B288
	pS5     :: 0h3F023DE10DFDF709
	qS1     :: 0hC0033A271C8A2D4B
	qS2     :: 0h40002AE59C598AC8
	qS3     :: 0hBFE6066C1B8D0159
	qS4     :: 0h3FB3B8C5B12E9282

	R :: #force_inline proc "contextless" (z: f64) -> f64 {
		p, q: f64
		p = z*(pS0+z*(pS1+z*(pS2+z*(pS3+z*(pS4+z*pS5)))))
		q = 1.0+z*(qS1+z*(qS2+z*(qS3+z*qS4)))
		return p/q
	}

	z, w, s, c, df: f64
	dwords := transmute([2]u32)x
	hx := dwords[1]
	ix := hx & 0x7fffffff
	/* |x| >= 1 or nan */
	if ix >= 0x3ff00000 {
		lx := dwords[0]

		if (ix-0x3ff00000 | lx) == 0 {
			/* acos(1)=0, acos(-1)=pi */
			if hx >> 31 != 0 {
				return 2*pio2_hi + 1e-120
			}
			return 0
		}
		return 0/(x-x)
	}
	/* |x| < 0.5 */
	if ix < 0x3fe00000 {
		if ix <= 0x3c600000 { /* |x| < 2**-57 */
			return pio2_hi + 1e-120
		}
		return pio2_hi - (x - (pio2_lo-x*R(x*x)))
	}
	/* x < -0.5 */
	if hx >> 31 != 0 {
		z = (1.0+x)*0.5
		s = sqrt(z)
		w = R(z)*s-pio2_lo
		return 2*(pio2_hi - (s+w))
	}
	/* x > 0.5 */
	z = (1.0-x)*0.5
	s = sqrt(z)
	df = s
	(^u64)(&df)^ &= 0xffffffff_00000000
	c = (z-df*df)/(s+df)
	w = R(z)*s+c
	return 2*(df+w)
}
@(require_results)
acos_f64le :: proc "contextless" (x: f64le) -> f64le {
	return f64le(acos_f64(f64(x)))
}
@(require_results)
acos_f64be :: proc "contextless" (x: f64be) -> f64be {
	return f64be(acos_f64(f64(x)))
}
@(require_results)
acos_f32 :: proc "contextless" (x: f32) -> f32 {
	return f32(acos_f64(f64(x)))
}
@(require_results)
acos_f32le :: proc "contextless" (x: f32le) -> f32le {
	return f32le(acos_f64(f64(x)))
}
@(require_results)
acos_f32be :: proc "contextless" (x: f32be) -> f32be {
	return f32be(acos_f64(f64(x)))
}
@(require_results)
acos_f16 :: proc "contextless" (x: f16) -> f16 {
	return f16(acos_f64(f64(x)))
}
@(require_results)
acos_f16le :: proc "contextless" (x: f16le) -> f16le {
	return f16le(acos_f64(f64(x)))
}
@(require_results)
acos_f16be :: proc "contextless" (x: f16be) -> f16be {
	return f16be(acos_f64(f64(x)))
}
acos :: proc{
	acos_f64, acos_f32, acos_f16,
	acos_f64le, acos_f64be,
	acos_f32le, acos_f32be,
	acos_f16le, acos_f16be,
}

@(require_results)
sinh :: proc "contextless" (x: $T) -> T where intrinsics.type_is_float(T) {
	return copy_sign(((exp(x) - exp(-x))*0.5), x)
}

@(require_results)
cosh :: proc "contextless" (x: $T) -> T where intrinsics.type_is_float(T) {
	return ((exp(x) + exp(-x))*0.5)
}

@(require_results)
tanh :: proc "contextless" (y: $T) -> T where intrinsics.type_is_float(T) {
	P0 :: -9.64399179425052238628e-1
	P1 :: -9.92877231001918586564e1
	P2 :: -1.61468768441708447952e3
	Q0 :: +1.12811678491632931402e2
	Q1 :: +2.23548839060100448583e3
	Q2 :: +4.84406305325125486048e3

	MAXLOG :: 8.8029691931113054295988e+01 // log(2**127)


	x := f64(y)
	z := abs(x)
	switch {
	case z > 0.5*MAXLOG:
		if x < 0 {
			return -1
		}
		return 1
	case z >= 0.625:
		s := exp(2 * z)
		z = 1 - 2/(s+1)
		if x < 0 {
			z = -z
		}
	case:
		if x == 0 {
			return T(x)
		}
		s := x * x
		z = x + x*s*((P0*s+P1)*s+P2)/(((s+Q0)*s+Q1)*s+Q2)
	}
	return T(z)
}

@(require_results)
asinh :: proc "contextless" (y: $T) -> T where intrinsics.type_is_float(T) {
	// The original C code, the long comment, and the constants
	// below are from FreeBSD's /usr/src/lib/msun/src/s_asinh.c
	// and came with this notice. 
	//
	// ====================================================
	// Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
	//
	// Developed at SunPro, a Sun Microsystems, Inc. business.
	// Permission to use, copy, modify, and distribute this
	// software is freely granted, provided that this notice
	// is preserved.
	// ====================================================
	
	LN2       :: 0h3FE62E42FEFA39EF
	NEAR_ZERO :: 1.0 / (1 << 28)
	LARGE     :: 1 << 28
	
	x := f64(y)
	
	if is_nan(x) || is_inf(x) {
		return T(x)
	}
	sign := false
	if x < 0 {
		x = -x
		sign = true
	}
	temp: f64
	switch {
	case x > LARGE:
		temp = ln(x) + LN2
	case x > 2:
		temp = ln(2*x + 1/(sqrt(x*x + 1) + x))
	case x < NEAR_ZERO:
		temp = x
	case:
		temp = log1p(x + x*x/(1 + sqrt(1 + x*x)))
	}
	
	if sign {
		temp = -temp
	}
	return T(temp)
}

@(require_results)
acosh :: proc "contextless" (y: $T) -> T where intrinsics.type_is_float(T) {
	// The original C code, the long comment, and the constants
	// below are from FreeBSD's /usr/src/lib/msun/src/e_acosh.c
	// and came with this notice. 
	//
	// ====================================================
	// Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
	//
	// Developed at SunPro, a Sun Microsystems, Inc. business.
	// Permission to use, copy, modify, and distribute this
	// software is freely granted, provided that this notice
	// is preserved.
	// ====================================================
	
	LARGE :: 1<<28
	LN2 :: 0h3FE62E42FEFA39EF
	x := f64(y)
	switch {
	case x < 1 || is_nan(x):
		return T(nan_f64())
	case x == 1:
		return 0
	case x >= LARGE:
		return T(ln(x) + LN2)
	case x > 2:
		return T(ln(2*x - 1/(x+sqrt(x*x-1))))
	}
	t := x-1
	return T(log1p(t + sqrt(2*t + t*t)))
}

@(require_results)
atanh :: proc "contextless" (y: $T) -> T where intrinsics.type_is_float(T) {
	// The original C code, the long comment, and the constants
	// below are from FreeBSD's /usr/src/lib/msun/src/e_atanh.c
	// and came with this notice. 
	//
	// ====================================================
	// Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
	//
	// Developed at SunPro, a Sun Microsystems, Inc. business.
	// Permission to use, copy, modify, and distribute this
	// software is freely granted, provided that this notice
	// is preserved.
	// ====================================================
	NEAR_ZERO :: 1.0 / (1 << 28)
	x := f64(y)
	switch {
	case x < -1 || x > 1 || is_nan(x):
		return T(nan_f64())
	case x == 1:
		return T(inf_f64(1))
	case x == -1:
		return T(inf_f64(-1))
	}
	sign := false
	if x < 0 {
		x = -x
		sign = true
	}
	temp: f64
	switch {
	case x < NEAR_ZERO:
		temp = x
	case x < 0.5:
		temp = x + x
		temp = 0.5 * log1p(temp + temp*x/(1-x))
	case:
		temp = 0.5 * log1p((x+x)/(1-x))
	}
	if sign {
		temp = -temp
	}
	return T(temp)
}

@(require_results)
ilogb_f16 :: proc "contextless" (val: f16) -> int {
	switch {
	case val == 0:    return int(min(i32))
	case is_nan(val): return int(max(i32))
	case is_inf(val): return int(max(i32))
	}
	x, exp := normalize_f16(val)
	return int(((transmute(u16)x)>>F16_SHIFT)&F16_MASK) - F16_BIAS + exp
}
@(require_results)
ilogb_f32 :: proc "contextless" (val: f32) -> int {
	switch {
	case val == 0:    return int(min(i32))
	case is_nan(val): return int(max(i32))
	case is_inf(val): return int(max(i32))
	}
	x, exp := normalize_f32(val)
	return int(((transmute(u32)x)>>F32_SHIFT)&F32_MASK) - F32_BIAS + exp
}
@(require_results)
ilogb_f64 :: proc "contextless" (val: f64) -> int {
	switch {
	case val == 0:    return int(min(i32))
	case is_nan(val): return int(max(i32))
	case is_inf(val): return int(max(i32))
	}
	x, exp := normalize_f64(val)
	return int(((transmute(u64)x)>>F64_SHIFT)&F64_MASK) - F64_BIAS + exp
}
@(require_results) ilogb_f16le :: proc "contextless" (value: f16le) -> int { return ilogb_f16(f16(value)) }
@(require_results) ilogb_f16be :: proc "contextless" (value: f16be) -> int { return ilogb_f16(f16(value)) }
@(require_results) ilogb_f32le :: proc "contextless" (value: f32le) -> int { return ilogb_f32(f32(value)) }
@(require_results) ilogb_f32be :: proc "contextless" (value: f32be) -> int { return ilogb_f32(f32(value)) }
@(require_results) ilogb_f64le :: proc "contextless" (value: f64le) -> int { return ilogb_f64(f64(value)) }
@(require_results) ilogb_f64be :: proc "contextless" (value: f64be) -> int { return ilogb_f64(f64(value)) }
ilogb :: proc {
	ilogb_f16,
	ilogb_f32,
	ilogb_f64,
	ilogb_f16le,
	ilogb_f16be,
	ilogb_f32le,
	ilogb_f32be,
	ilogb_f64le,
	ilogb_f64be,
}

@(require_results)
logb_f16 :: proc "contextless" (val: f16) -> f16 {
	switch {
	case val == 0:    return inf_f16(-1)
	case is_inf(val): return inf_f16(+1)
	case is_nan(val): return val
	}
	return f16(ilogb(val))
}
@(require_results)
logb_f32 :: proc "contextless" (val: f32) -> f32 {
	switch {
	case val == 0:    return inf_f32(-1)
	case is_inf(val): return inf_f32(+1)
	case is_nan(val): return val
	}
	return f32(ilogb(val))
}
@(require_results)
logb_f64 :: proc "contextless" (val: f64) -> f64 {
	switch {
	case val == 0:    return inf_f64(-1)
	case is_inf(val): return inf_f64(+1)
	case is_nan(val): return val
	}
	return f64(ilogb(val))
}
@(require_results) logb_f16le :: proc "contextless" (value: f16le) -> f16le { return f16le(logb_f16(f16(value))) }
@(require_results) logb_f16be :: proc "contextless" (value: f16be) -> f16be { return f16be(logb_f16(f16(value))) }
@(require_results) logb_f32le :: proc "contextless" (value: f32le) -> f32le { return f32le(logb_f32(f32(value))) }
@(require_results) logb_f32be :: proc "contextless" (value: f32be) -> f32be { return f32be(logb_f32(f32(value))) }
@(require_results) logb_f64le :: proc "contextless" (value: f64le) -> f64le { return f64le(logb_f64(f64(value))) }
@(require_results) logb_f64be :: proc "contextless" (value: f64be) -> f64be { return f64be(logb_f64(f64(value))) }
logb :: proc {
	logb_f16,
	logb_f32,
	logb_f64,
	logb_f16le,
	logb_f16be,
	logb_f32le,
	logb_f32be,
	logb_f64le,
	logb_f64be,
}

@(require_results)
nextafter_f16 :: proc "contextless" (x, y: f16) -> (r: f16) {
	switch {
	case is_nan(x) || is_nan(y):
		r = nan_f16()
	case x == y:
		r = x
	case x == 0:
		r = copy_sign_f16(1, y)
	case (y > x) == (x > 0):
		r = transmute(f16)(transmute(u16)x + 1)
	case:
		r = transmute(f16)(transmute(u16)x - 1)
	}
	return
}
@(require_results)
nextafter_f32 :: proc "contextless" (x, y: f32) -> (r: f32) {
	switch {
	case is_nan(x) || is_nan(y):
		r = nan_f32()
	case x == y:
		r = x
	case x == 0:
		r = copy_sign_f32(1, y)
	case (y > x) == (x > 0):
		r = transmute(f32)(transmute(u32)x + 1)
	case:
		r = transmute(f32)(transmute(u32)x - 1)
	}
	return
}
@(require_results)
nextafter_f64 :: proc "contextless" (x, y: f64) -> (r: f64) {
	switch {
	case is_nan(x) || is_nan(y):
		r = nan_f64()
	case x == y:
		r = x
	case x == 0:
		r = copy_sign_f64(1, y)
	case (y > x) == (x > 0):
		r = transmute(f64)(transmute(u64)x + 1)
	case:
		r = transmute(f64)(transmute(u64)x - 1)
	}
	return
}
@(require_results) nextafter_f16le :: proc "contextless" (x, y: f16le) -> (r: f16le) { return f16le(nextafter_f16(f16(x), f16(y))) }
@(require_results) nextafter_f16be :: proc "contextless" (x, y: f16be) -> (r: f16be) { return f16be(nextafter_f16(f16(x), f16(y))) }
@(require_results) nextafter_f32le :: proc "contextless" (x, y: f32le) -> (r: f32le) { return f32le(nextafter_f32(f32(x), f32(y))) }
@(require_results) nextafter_f32be :: proc "contextless" (x, y: f32be) -> (r: f32be) { return f32be(nextafter_f32(f32(x), f32(y))) }
@(require_results) nextafter_f64le :: proc "contextless" (x, y: f64le) -> (r: f64le) { return f64le(nextafter_f64(f64(x), f64(y))) }
@(require_results) nextafter_f64be :: proc "contextless" (x, y: f64be) -> (r: f64be) { return f64be(nextafter_f64(f64(x), f64(y))) }

nextafter :: proc{
	nextafter_f16, nextafter_f16le, nextafter_f16be,
	nextafter_f32, nextafter_f32le, nextafter_f32be,
	nextafter_f64, nextafter_f64le, nextafter_f64be,
}

@(require_results)
signbit_f16 :: proc "contextless" (x: f16) -> bool {
	return (transmute(u16)x)&(1<<15) != 0
}
@(require_results)
signbit_f32 :: proc "contextless" (x: f32) -> bool {
	return (transmute(u32)x)&(1<<31) != 0
}
@(require_results)
signbit_f64 :: proc "contextless" (x: f64) -> bool {
	return (transmute(u64)x)&(1<<63) != 0
}
@(require_results) signbit_f16le :: proc "contextless" (x: f16le) -> bool { return signbit_f16(f16(x)) }
@(require_results) signbit_f32le :: proc "contextless" (x: f32le) -> bool { return signbit_f32(f32(x)) }
@(require_results) signbit_f64le :: proc "contextless" (x: f64le) -> bool { return signbit_f64(f64(x)) }
@(require_results) signbit_f16be :: proc "contextless" (x: f16be) -> bool { return signbit_f16(f16(x)) }
@(require_results) signbit_f32be :: proc "contextless" (x: f32be) -> bool { return signbit_f32(f32(x)) }
@(require_results) signbit_f64be :: proc "contextless" (x: f64be) -> bool { return signbit_f64(f64(x)) }

signbit :: proc{
	signbit_f16, signbit_f16le, signbit_f16be,
	signbit_f32, signbit_f32le, signbit_f32be,
	signbit_f64, signbit_f64le, signbit_f64be,
}


@(require_results)
hypot_f16 :: proc "contextless" (x, y: f16) -> (r: f16) {
	p, q := abs(x), abs(y)
	switch {
	case is_inf(p, 1) || is_inf(q, 1):
		return inf_f16(1)
	case is_nan(p) || is_nan(q):
		return nan_f16()
	}
	if p < q {
		p, q = q, p
	}
	if p == 0 {
		return 0
	}
	q = q / p
	return p * sqrt(1+q*q)
}
@(require_results)
hypot_f32 :: proc "contextless" (x, y: f32) -> (r: f32) {
	p, q := abs(x), abs(y)
	switch {
	case is_inf(p, 1) || is_inf(q, 1):
		return inf_f32(1)
	case is_nan(p) || is_nan(q):
		return nan_f32()
	}
	if p < q {
		p, q = q, p
	}
	if p == 0 {
		return 0
	}
	q = q / p
	return p * sqrt(1+q*q)
}
@(require_results)
hypot_f64 :: proc "contextless" (x, y: f64) -> (r: f64) {
	p, q := abs(x), abs(y)
	switch {
	case is_inf(p, 1) || is_inf(q, 1):
		return inf_f64(1)
	case is_nan(p) || is_nan(q):
		return nan_f64()
	}
	if p < q {
		p, q = q, p
	}
	if p == 0 {
		return 0
	}
	q = q / p
	return p * sqrt(1+q*q)
}
@(require_results) hypot_f16le :: proc "contextless" (x, y: f16le) -> (r: f16le) { return f16le(hypot_f16(f16(x), f16(y))) }
@(require_results) hypot_f16be :: proc "contextless" (x, y: f16be) -> (r: f16be) { return f16be(hypot_f16(f16(x), f16(y))) }
@(require_results) hypot_f32le :: proc "contextless" (x, y: f32le) -> (r: f32le) { return f32le(hypot_f32(f32(x), f32(y))) }
@(require_results) hypot_f32be :: proc "contextless" (x, y: f32be) -> (r: f32be) { return f32be(hypot_f32(f32(x), f32(y))) }
@(require_results) hypot_f64le :: proc "contextless" (x, y: f64le) -> (r: f64le) { return f64le(hypot_f64(f64(x), f64(y))) }
@(require_results) hypot_f64be :: proc "contextless" (x, y: f64be) -> (r: f64be) { return f64be(hypot_f64(f64(x), f64(y))) }

// hypot returns Sqrt(p*p + q*q), taking care to avoid unnecessary overflow and underflow.
//
// Special cases:
//	hypot(±Inf, q) = +Inf
//	hypot(p, ±Inf) = +Inf
//	hypot(NaN, q) = NaN
//	hypot(p, NaN) = NaN
hypot :: proc{
	hypot_f16, hypot_f16le, hypot_f16be,
	hypot_f32, hypot_f32le, hypot_f32be,
	hypot_f64, hypot_f64le, hypot_f64be,
}

F16_DIG        :: 3
F16_EPSILON    :: 0.00097656
F16_GUARD      :: 0
F16_MANT_DIG   :: 11
F16_MAX        :: 65504.0
F16_MAX_10_EXP :: 4
F16_MAX_EXP    :: 15
F16_MIN        :: 6.10351562e-5
F16_MIN_10_EXP :: -4
F16_MIN_EXP    :: -14
F16_NORMALIZE  :: 0
F16_RADIX      :: 2
F16_ROUNDS     :: 1


F32_DIG        :: 6
F32_EPSILON    :: 1.192092896e-07
F32_GUARD      :: 0
F32_MANT_DIG   :: 24
F32_MAX        :: 3.402823466e+38
F32_MAX_10_EXP :: 38
F32_MAX_EXP    :: 128
F32_MIN        :: 1.175494351e-38
F32_MIN_10_EXP :: -37
F32_MIN_EXP    :: -125
F32_NORMALIZE  :: 0
F32_RADIX      :: 2
F32_ROUNDS     :: 1

F64_DIG        :: 15                       // Number of representable decimal digits.
F64_EPSILON    :: 2.2204460492503131e-016  // Smallest number such that `1.0 + F64_EPSILON != 1.0`.
F64_MANT_DIG   :: 53                       // Number of bits in the mantissa.
F64_MAX        :: 1.7976931348623158e+308  // Maximum representable value.
F64_MAX_10_EXP :: 308                      // Maximum base-10 exponent yielding normalized value.
F64_MAX_EXP    :: 1024                     // One greater than the maximum possible base-2 exponent yielding normalized value.
F64_MIN        :: 2.2250738585072014e-308  // Minimum positive normalized value.
F64_MIN_10_EXP :: -307                     // Minimum base-10 exponent yielding normalized value.
F64_MIN_EXP    :: -1021                    // One greater than the minimum possible base-2 exponent yielding normalized value.
F64_RADIX      :: 2                        // Exponent radix.
F64_ROUNDS     :: 1                        // Addition rounding: near.


F16_MASK  :: 0x1f
F16_SHIFT :: 16 - 6
F16_BIAS  :: 0xf

F32_MASK  :: 0xff
F32_SHIFT :: 32 - 9
F32_BIAS  :: 0x7f

F64_MASK  :: 0x7ff
F64_SHIFT :: 64 - 12
F64_BIAS  :: 0x3ff

INF_F16     :: f16(0h7C00)
NEG_INF_F16 :: f16(0hFC00)

SNAN_F16    :: f16(0h7C01)
QNAN_F16    :: f16(0h7E01)

INF_F32     :: f32(0h7F80_0000)
NEG_INF_F32 :: f32(0hFF80_0000)

SNAN_F32    :: f32(0hFF80_0001)
QNAN_F32    :: f32(0hFFC0_0001)

INF_F64     :: f64(0h7FF0_0000_0000_0000)
NEG_INF_F64 :: f64(0hFFF0_0000_0000_0000)

SNAN_F64    :: f64(0h7FF0_0000_0000_0001)
QNAN_F64    :: f64(0h7FF8_0000_0000_0001)
