package libc

// 7.12 Mathematics

import "base:intrinsics"

when ODIN_OS == .Windows {
	foreign import libc "system:libucrt.lib"
} else when ODIN_OS == .Darwin {
	foreign import libc "system:System.framework"
} else {
	foreign import libc "system:c"
}

// To support C's tgmath behavior we use Odin's explicit procedure overloading,
// but we cannot use the same names as exported by libc so use @(link_name)
// and keep them as private symbols of name "libc_"
@(private="file")
@(default_calling_convention="c")
foreign libc {
	// 7.12.4 Trigonometric functions
	@(link_name="acos")       libc_acos       :: proc(x: double) -> double ---
	@(link_name="acosf")      libc_acosf      :: proc(x: float) -> float ---
	@(link_name="asin")       libc_asin       :: proc(x: double) -> double ---
	@(link_name="asinf")      libc_asinf      :: proc(x: float) -> float ---
	@(link_name="atan")       libc_atan       :: proc(x: double) -> double ---
	@(link_name="atanf")      libc_atanf      :: proc(x: float) -> float ---
	@(link_name="atan2")      libc_atan2      :: proc(y: double, x: double) -> double ---
	@(link_name="atan2f")     libc_atan2f     :: proc(y: float, x: float) -> float ---
	@(link_name="cos")        libc_cos        :: proc(x: double) -> double ---
	@(link_name="cosf")       libc_cosf       :: proc(x: float) -> float ---
	@(link_name="sin")        libc_sin        :: proc(x: double) -> double ---
	@(link_name="sinf")       libc_sinf       :: proc(x: float) -> float ---
	@(link_name="tan")        libc_tan        :: proc(x: double) -> double ---
	@(link_name="tanf")       libc_tanf       :: proc(x: float) -> float ---

	// 7.12.5 Hyperbolic functions
	@(link_name="acosh")      libc_acosh      :: proc(x: double) -> double ---
	@(link_name="acoshf")     libc_acoshf     :: proc(x: float) -> float ---
	@(link_name="asinh")      libc_asinh      :: proc(x: double) -> double ---
	@(link_name="asinhf")     libc_asinhf     :: proc(x: float) -> float ---
	@(link_name="atanh")      libc_atanh      :: proc(x: double) -> double ---
	@(link_name="atanhf")     libc_atanhf     :: proc(x: float) -> float ---
	@(link_name="cosh")       libc_cosh       :: proc(x: double) -> double ---
	@(link_name="coshf")      libc_coshf      :: proc(x: float) -> float ---
	@(link_name="sinh")       libc_sinh       :: proc(x: double) -> double ---
	@(link_name="sinhf")      libc_sinhf      :: proc(x: float) -> float ---
	@(link_name="tanh")       libc_tanh       :: proc(x: double) -> double ---
	@(link_name="tanhf")      libc_tanhf      :: proc(x: float) -> float ---

	// 7.12.6 Exponential and logarithmic functions
	@(link_name="exp")        libc_exp        :: proc(x: double) -> double ---
	@(link_name="expf")       libc_expf       :: proc(x: float) -> float ---
	@(link_name="exp2")       libc_exp2       :: proc(x: double) -> double ---
	@(link_name="exp2f")      libc_exp2f      :: proc(x: float) -> float ---
	@(link_name="expm1")      libc_expm1      :: proc(x: double) -> double ---
	@(link_name="expm1f")     libc_expm1f     :: proc(x: float) -> float ---
	@(link_name="frexp")      libc_frexp      :: proc(value: double, exp: ^int) -> double ---
	@(link_name="frexpf")     libc_frexpf     :: proc(value: float, exp: ^int) -> float ---
	@(link_name="ilogb")      libc_ilogb      :: proc(x: double) -> int ---
	@(link_name="ilogbf")     libc_ilogbf     :: proc(x: float) -> int ---
	@(link_name="ldexp")      libc_ldexp      :: proc(x: double, exp: int) -> double ---
	@(link_name="ldexpf")     libc_ldexpf     :: proc(x: float, exp: int) -> float ---
	@(link_name="log")        libc_log        :: proc(x: double) -> double ---
	@(link_name="logf")       libc_logf       :: proc(x: float) -> float ---
	@(link_name="log10")      libc_log10      :: proc(x: double) -> double ---
	@(link_name="log10f")     libc_log10f     :: proc(x: float) -> float ---
	@(link_name="log1p")      libc_log1p      :: proc(x: double) -> double ---
	@(link_name="log1pf")     libc_log1pf     :: proc(x: float) -> float ---
	@(link_name="log2")       libc_log2       :: proc(x: double) -> double ---
	@(link_name="log2f")      libc_log2f      :: proc(x: float) -> float ---
	@(link_name="logb")       libc_logb       :: proc(x: double) -> double ---
	@(link_name="logbf")      libc_logbf      :: proc(x: float) -> float ---
	@(link_name="modf")       libc_modf       :: proc(value: double, iptr: ^double) -> double ---
	@(link_name="modff")      libc_modff      :: proc(value: float, iptr: ^float) -> float ---
	@(link_name="scalbn")     libc_scalbn     :: proc(x: double, n: int) -> double ---
	@(link_name="scalbnf")    libc_scalbnf    :: proc(x: float, n: int) -> float ---
	@(link_name="scalbln")    libc_scalbln    :: proc(x: double, n: long) -> double ---
	@(link_name="scalblnf")   libc_scalblnf   :: proc(x: float, n: long) -> float ---

	// 7.12.7 Power and absolute-value functions
	@(link_name="cbrt")       libc_cbrt       :: proc(x: double) -> double ---
	@(link_name="cbrtf")      libc_cbrtf      :: proc(x: float) -> float ---
	@(link_name="fabs")       libc_fabs       :: proc(x: double) -> double ---
	@(link_name="fabsf")      libc_fabsf      :: proc(x: float) -> float ---
	@(link_name="hypot")      libc_hypot      :: proc(x: double, y: double) -> double ---
	@(link_name="hypotf")     libc_hypotf     :: proc(x: float, y: float) -> float ---
	@(link_name="pow")        libc_pow        :: proc(x: double, y: double) -> double ---
	@(link_name="powf")       libc_powf       :: proc(x: float, y: float) -> float ---
	@(link_name="sqrt")       libc_sqrt       :: proc(x: double) -> double ---
	@(link_name="sqrtf")      libc_sqrtf      :: proc(x: float) -> float ---

	// 7.12.8 Error and gamma functions
	@(link_name="erf")        libc_erf        :: proc(x: double) -> double ---
	@(link_name="erff")       libc_erff       :: proc(x: float) -> float ---
	@(link_name="erfc")       libc_erfc       :: proc(x: double) -> double ---
	@(link_name="erfcf")      libc_erfcf      :: proc(x: float) -> float ---
	@(link_name="lgamma")     libc_lgamma     :: proc(x: double) -> double ---
	@(link_name="lgammaf")    libc_lgammaf    :: proc(x: float) -> float ---
	@(link_name="tgamma")     libc_tgamma     :: proc(x: double) -> double ---
	@(link_name="tgammaf")    libc_tgammaf    :: proc(x: float) -> float ---

	// 7.12.9 Nearest integer functions
	@(link_name="ceil")       libc_ceil       :: proc(x: double) -> double ---
	@(link_name="ceilf")      libc_ceilf      :: proc(x: float) -> float ---
	@(link_name="floor")      libc_floor      :: proc(x: double) -> double ---
	@(link_name="floorf")     libc_floorf     :: proc(x: float) -> float ---
	@(link_name="nearbyint")  libc_nearbyint  :: proc(x: double) -> double ---
	@(link_name="nearbyintf") libc_nearbyintf :: proc(x: float) -> float ---
	@(link_name="rint")       libc_rint       :: proc(x: double) -> double ---
	@(link_name="rintf")      libc_rintf      :: proc(x: float) -> float ---
	@(link_name="lrint")      libc_lrint      :: proc(x: double) -> long ---
	@(link_name="lrintf")     libc_lrintf     :: proc(x: float) -> long ---
	@(link_name="llrint")     libc_llrint     :: proc(x: double) -> longlong ---
	@(link_name="llrintf")    libc_llrintf    :: proc(x: float) -> longlong ---
	@(link_name="round")      libc_round      :: proc(x: double) -> double ---
	@(link_name="roundf")     libc_roundf     :: proc(x: float) -> float ---
	@(link_name="lround")     libc_lround     :: proc(x: double) -> long ---
	@(link_name="lroundf")    libc_lroundf    :: proc(x: float) -> long ---
	@(link_name="llround")    libc_llround    :: proc(x: double) -> longlong ---
	@(link_name="llroundf")   libc_llroundf   :: proc(x: float) -> longlong ---
	@(link_name="trunc")      libc_trunc      :: proc(x: double) -> double ---
	@(link_name="truncf")     libc_truncf     :: proc(x: float) -> float ---

	// 7.12.10 Remainder functions
	@(link_name="fmod")       libc_fmod       :: proc(x: double, y: double) -> double ---
	@(link_name="fmodf")      libc_fmodf      :: proc(x: float, y: float) -> float ---
	@(link_name="remainder")  libc_remainder  :: proc(x: double, y: double) -> double ---
	@(link_name="remainderf") libc_remainderf :: proc(x: float, y: float) -> float ---
	@(link_name="remquo")     libc_remquo     :: proc(x: double, y: double, quo: ^int) -> double ---
	@(link_name="remquof")    libc_remquof    :: proc(x: float, y: float, quo: ^int) -> float ---

	// 7.12.11 Manipulation functions
	@(link_name="copysign")   libc_copysign   :: proc(x: double, y: double) -> double ---
	@(link_name="copysignf")  libc_copysignf  :: proc(x: float, y: float) -> float ---
	@(link_name="nan")        libc_nan        :: proc(tagp: cstring) -> double ---
	@(link_name="nanf")       libc_nanf       :: proc(tagp: cstring) -> float ---
	@(link_name="nextafter")  libc_nextafter  :: proc(x: double, y: double) -> double ---
	@(link_name="nextafterf") libc_nextafterf :: proc(x: float, y: float) -> float ---

	// 7.12.12 Maximum, minimum, and positive difference functions
	@(link_name="fdim")       libc_fdim       :: proc(x: double, y: double) -> double ---
	@(link_name="fdimf")      libc_fdimf      :: proc(x: float, y: float) -> float ---
	@(link_name="fmax")       libc_fmax       :: proc(x: double, y: double) -> double ---
	@(link_name="fmaxf")      libc_fmaxf      :: proc(x: float, y: float) -> float ---
	@(link_name="fmin")       libc_fmin       :: proc(x: double, y: double) -> double ---
	@(link_name="fminf")      libc_fminf      :: proc(x: float, y: float) -> float ---
	@(link_name="fma")        libc_fma        :: proc(x, y, z: double) -> double ---
	@(link_name="fmaf")       libc_fmaf       :: proc(x, y, z: float) -> float ---
}

@(private="file")
_nan_bit_pattern := ~u64(0)

// On amd64 Windows and Linux, float_t and double_t are respectively both
// their usual types. On x86 it's not possible to define these types correctly
// since they would be long double which Odin does have support for.
float_t          :: float
double_t         :: double

NAN              := transmute(double)(_nan_bit_pattern)
INFINITY         :: 1e5000

HUGE_VALF        :: INFINITY
HUGE_VAL         :: double(INFINITY)

MATH_ERRNO       :: 1
MATH_ERREXCEPT   :: 2

math_errhandling :: 2 // Windows, Linux, macOS all use this mode.

FP_ILOGBNAN      :: -1 - int((~uint(0)) >> 1)
FP_ILOGB0        :: FP_ILOGBNAN

// Number classification constants. These do not have to match libc since we
// implement our own classification functions as libc requires they be macros,
// which means libc does not export standard functions for them.
FP_NAN           :: 0
FP_INFINITE      :: 1
FP_ZERO          :: 2
FP_NORMAL        :: 3
FP_SUBNORMAL     :: 4

@(private)
_fpclassify :: #force_inline proc(x: double) -> int {
	u := transmute(uint64_t)x
	switch e := u >> 52 & 0x7ff; e {
	case 0:     return FP_SUBNORMAL if (u << 1)  != 0 else FP_ZERO
	case 0x7ff: return FP_NAN       if (u << 12) != 0 else FP_INFINITE
	}
	return FP_NORMAL
}

@(private)
_fpclassifyf :: #force_inline proc(x: float) -> int {
	u := transmute(uint32_t)x
	switch e := u >> 23 & 0xff; e {
	case 0:    return FP_SUBNORMAL if (u << 1)  != 0 else FP_ZERO
	case 0xff: return FP_NAN       if (u << 9)  != 0 else FP_INFINITE
	}
	return FP_NORMAL
}

@(private)
_signbit :: #force_inline proc(x: double) -> int {
	return int(transmute(uint64_t)x >> 63)
}

@(private)
_signbitf :: #force_inline proc(x: float) -> int {
	return int(transmute(uint32_t)x >> 31)
}

isfinite :: #force_inline proc(x: $T) -> bool where intrinsics.type_is_float(T) {
	return fpclassify(x) == FP_INFINITE
}

isinf :: #force_inline proc(x: $T) -> bool where intrinsics.type_is_float(T) {
	return fpclassify(x) > FP_INFINITE
}

isnan :: #force_inline proc(x: $T) -> bool where intrinsics.type_is_float(T) {
	return fpclassify(x) == FP_NAN
}

isnormal :: #force_inline proc(x: $T) -> bool where intrinsics.type_is_float(T) {
	return fpclassify(x) == FP_NORMAL
}

// These are special in that they avoid float exceptions. They cannot just be
// implemented as the relational comparisons, as that would produce an invalid
// "sticky" state that propagates and affects maths results. These need
// to be implemented natively in Odin assuming isunordered to prevent that.
isgreater :: #force_inline proc(x, y: $T) -> bool where intrinsics.type_is_float(T) {
	return !isunordered(x, y) && x > y
}

isgreaterequal :: #force_inline proc(x, y: $T) -> bool where intrinsics.type_is_float(T) {
	return !isunordered(x, y) && x >= y
}

isless :: #force_inline proc(x, y: $T) -> bool where intrinsics.type_is_float(T) {
	return !isunordered(x, y) && x < y
}

islessequal :: #force_inline proc(x, y: $T) -> bool where intrinsics.type_is_float(T) {
	return !isunordered(x, y) && x <= y
}

islessgreater :: #force_inline proc(x, y: $T) -> bool where intrinsics.type_is_float(T) {
	return !isunordered(x, y) && x <= y
}

isunordered :: #force_inline proc(x, y: $T) -> bool where intrinsics.type_is_float(T) {
	if isnan(x) {
		// Force evaluation of y to propagate exceptions for ordering semantics.
		// To ensure correct semantics of IEEE 754 this cannot be compiled away.
		sink: T
		intrinsics.volatile_store(&sink, intrinsics.volatile_load(&y))
		return true
	}
	return isnan(y)
}

fpclassify :: proc{_fpclassify, _fpclassifyf}
signbit    :: proc{_signbit, _signbitf}

// Emulate tgmath.h behavior with explicit procedure overloading here.
acos       :: proc{libc_acos, libc_acosf, cacos, cacosf}
asin       :: proc{libc_asin, libc_asinf, casin, casinf}
atan       :: proc{libc_atan, libc_atanf, catan, catanf}
atan2      :: proc{libc_atan2, libc_atan2f}
cos        :: proc{libc_cos, libc_cosf, ccos, ccosf}
sin        :: proc{libc_sin, libc_sinf, csin, csinf}
tan        :: proc{libc_tan, libc_tanf, ctan, ctanf}

acosh      :: proc{libc_acosh, libc_acoshf, cacosh, cacoshf}
asinh      :: proc{libc_asinh, libc_asinhf, casinh, casinhf}
atanh      :: proc{libc_atanh, libc_atanhf, catanh, catanhf}
cosh       :: proc{libc_cosh, libc_coshf, ccosh, ccoshf}
sinh       :: proc{libc_sinh, libc_sinhf, csinh, csinhf}
tanh       :: proc{libc_tanh, libc_tanhf, ctanh, ctanhf}

exp        :: proc{libc_exp, libc_expf, cexp, cexpf}
exp2       :: proc{libc_exp2, libc_exp2f} 
expm1      :: proc{libc_expm1, libc_expm1f}
frexp      :: proc{libc_frexp, libc_frexpf}
ilogb      :: proc{libc_ilogb, libc_ilogbf}
ldexp      :: proc{libc_ldexp, libc_ldexpf}
log        :: proc{libc_log, libc_logf, clog, clogf}
log10      :: proc{libc_log10, libc_log10f}
log1p      :: proc{libc_log1p, libc_log1pf}
log2       :: proc{libc_log2, libc_log2f}
logb       :: proc{libc_logb, libc_logbf}
modf       :: proc{libc_modf, libc_modff}
scalbn     :: proc{libc_scalbn, libc_scalbnf}
scalbln    :: proc{libc_scalbln, libc_scalblnf}

cbrt       :: proc{libc_cbrt, libc_cbrtf}
fabs       :: proc{libc_fabs, libc_fabsf, cabs, cabsf}
hypot      :: proc{libc_hypot, libc_hypotf}
pow        :: proc{libc_pow, libc_powf, cpow, cpowf}
sqrt       :: proc{libc_sqrt, libc_sqrtf, csqrt, csqrtf}

erf        :: proc{libc_erf, libc_erff}
erfc       :: proc{libc_erfc, libc_erfcf}
lgamma     :: proc{libc_lgamma, libc_lgammaf}
tgamma     :: proc{libc_tgamma, libc_tgammaf}

ceil       :: proc{libc_ceil, libc_ceilf}
floor      :: proc{libc_floor, libc_floorf}
nearbyint  :: proc{libc_nearbyint, libc_nearbyintf}
rint       :: proc{libc_rint, libc_rintf}
lrint      :: proc{libc_lrint, libc_lrintf}
llrint     :: proc{libc_llrint, libc_llrintf}
round      :: proc{libc_round, libc_roundf}
lround     :: proc{libc_lround, libc_lroundf}
llround    :: proc{libc_llround, libc_llroundf}
trunc      :: proc{libc_trunc, libc_truncf}

fmod       :: proc{libc_fmod, libc_fmodf}
remainder  :: proc{libc_remainder, libc_remainderf}
remquo     :: proc{libc_remquo, libc_remquof}

copysign   :: proc{libc_copysign, libc_copysignf}
nextafter  :: proc{libc_nextafter, libc_nextafterf}

fdim       :: proc{libc_fdim, libc_fdimf}
fmax       :: proc{libc_fmax, libc_fmaxf}
fmin       :: proc{libc_fmin, libc_fminf}
fma        :: proc{libc_fma, libc_fmaf}

// But retain the 'f' suffix-variant functions as well so they can be used,
// a trick is used here where we use explicit procedural overloading of one
// procedure. This is done because the foreign block is marked @(private) and
// aliasing functions does not remove privateness from the entity.
acosf      :: proc{libc_acosf}
asinf      :: proc{libc_asinf}
atanf      :: proc{libc_atanf}
atan2f     :: proc{libc_atan2f}
cosf       :: proc{libc_cosf}
sinf       :: proc{libc_sinf}
tanf       :: proc{libc_tanf}

acoshf     :: proc{libc_acoshf}
asinhf     :: proc{libc_asinhf}
atanhf     :: proc{libc_atanhf}
coshf      :: proc{libc_coshf}
sinhf      :: proc{libc_sinhf}
tanhf      :: proc{libc_tanhf}

expf       :: proc{libc_expf}
exp2f      :: proc{libc_exp2f}
expm1f     :: proc{libc_expm1f}
frexpf     :: proc{libc_frexpf}
ilogbf     :: proc{libc_ilogbf}
ldexpf     :: proc{libc_ldexpf}
logf       :: proc{libc_logf}
log10f     :: proc{libc_log10f}
log1pf     :: proc{libc_log1pf}
log2f      :: proc{libc_log2f}
logbf      :: proc{libc_logbf}
modff      :: proc{libc_modff}
scalbnf    :: proc{libc_scalbnf}
scalblnf   :: proc{libc_scalblnf}

cbrtf      :: proc{libc_cbrtf}
fabsf      :: proc{libc_fabsf}
hypotf     :: proc{libc_hypotf}
powf       :: proc{libc_powf}
sqrtf      :: proc{libc_sqrtf}

erff       :: proc{libc_erff}
erfcf      :: proc{libc_erfcf}
lgammaf    :: proc{libc_lgammaf}
tgammaf    :: proc{libc_tgammaf}

ceilf      :: proc{libc_ceilf}
floorf     :: proc{libc_floorf}
nearbyintf :: proc{libc_nearbyintf}
rintf      :: proc{libc_rintf}
lrintf     :: proc{libc_lrintf}
llrintf    :: proc{libc_llrintf}
roundf     :: proc{libc_roundf}
lroundf    :: proc{libc_lroundf}
llroundf   :: proc{libc_llroundf}
truncf     :: proc{libc_truncf}

fmodf      :: proc{libc_fmodf}
remainderf :: proc{libc_remainderf}
remquof    :: proc{libc_remquof}

copysignf  :: proc{libc_copysignf}
nextafterf :: proc{libc_nextafterf}

fdimf      :: proc{libc_fdimf} 
fmaxf      :: proc{libc_fmaxf}
fminf      :: proc{libc_fminf}
fmaf       :: proc{libc_fmaf}

// These two functions are special and not made type generic in tgmath.h since
// they only differ by their return type.
nan        :: proc{libc_nan}
nanf       :: proc{libc_nanf}
