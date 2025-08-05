package odin_libc

import "base:builtin"

import "core:math"

@(require, linkage="strong", link_name="sqrtf")
sqrtf :: proc "c" (v: f32) -> f32 {
	return math.sqrt(v)
}

@(require, linkage="strong", link_name="cosf")
cosf :: proc "c" (v: f32) -> f32 {
	return math.cos(v)
}

@(require, linkage="strong", link_name="atan2f")
atan2f :: proc "c" (v: f32, v2: f32) -> f32 {
	return math.atan2(v, v2)
}

@(require, linkage="strong", link_name="__isnanf")
isnanf :: proc "c" (v: f32) -> bool {
	return math.is_nan(v)
}

@(require, linkage="strong", link_name="__isnand")
isnand :: proc "c" (v: f64) -> bool {
	return math.is_nan(v)
}

@(require, linkage="strong", link_name="__isinff")
isinff :: proc "c" (v: f32) -> bool {
	return math.is_inf(v)
}

@(require, linkage="strong", link_name="__isinfd")
isinfd :: proc "c" (v: f64) -> bool {
	return math.is_inf(v)
}

@(require, linkage="strong", link_name="sqrt")
sqrt :: proc "c" (x: f64) -> f64 {
	return math.sqrt(x)
}

@(require, linkage="strong", link_name="floorf")
floorf :: proc "c" (x: f32) -> f32 {
	return math.floor(x)
}

@(require, linkage="strong", link_name="floor")
floor :: proc "c" (x: f64) -> f64 {
	return math.floor(x)
}

@(require, linkage="strong", link_name="ceilf")
ceilf :: proc "c" (x: f32) -> f32 {
	return math.ceil(x)
}

@(require, linkage="strong", link_name="ceil")
ceil :: proc "c" (x: f64) -> f64 {
	return math.ceil(x)
}

@(require, linkage="strong", link_name="powf")
powf :: proc "c" (x, y: f32) -> f32 {
	return math.pow(x, y)
}

@(require, linkage="strong", link_name="pow")
pow :: proc "c" (x, y: f64) -> f64 {
	return math.pow(x, y)
}

@(require, linkage="strong", link_name="fmodf")
fmodf :: proc "c" (x, y: f32) -> f32 {
	return math.mod(x, y)
}

@(require, linkage="strong", link_name="fmod")
fmod :: proc "c" (x, y: f64) -> f64 {
	return math.mod(x, y)
}

@(require, linkage="strong", link_name="cos")
cos :: proc "c" (x: f64) -> f64 {
	return math.cos(x)
}

@(require, linkage="strong", link_name="acosf")
acosf :: proc "c" (x: f32) -> f32 {
	return math.acos(x)
}

@(require, linkage="strong", link_name="acos")
acos :: proc "c" (x: f64) -> f64 {
	return math.acos(x)
}

@(require, linkage="strong", link_name="fabsf")
fabsf :: proc "c" (x: f32) -> f32 {
	return math.abs(x)
}

@(require, linkage="strong", link_name="fabs")
fabs :: proc "c" (x: f64) -> f64 {
	return math.abs(x)
}

@(require, linkage="strong", link_name="abs")
abs :: proc "c" (x: i32) -> i32 {
	return builtin.abs(x)
}

@(require, linkage="strong", link_name="ldexp")
ldexp :: proc "c" (x: f64, y: i32) -> f64{
	return math.ldexp(x, int(y))
}

@(require, linkage="strong", link_name="exp")
exp :: proc "c" (x: f64) -> f64 {
	return math.exp(x)
}

@(require, linkage="strong", link_name="logf")
logf :: proc "c" (x: f32) -> f32 {
	return math.ln(x)
}

@(require, linkage="strong", link_name="log")
log :: proc "c" (x: f64) -> f64 {
	return math.ln(x)
}

@(require, linkage="strong", link_name="sin")
sin :: proc "c" (x: f64) -> f64 {
	return math.sin(x)
}

@(require, linkage="strong", link_name="sinf")
sinf :: proc "c" (v: f32) -> f32 {
	return math.sin(v)
}


@(require, linkage="strong", link_name="trunc")
trunc :: proc "c" (x: f64) -> f64 {
	return math.trunc(x)
}

@(require, linkage="strong", link_name="__isfinitef")
isfinitef :: proc "c" (x: f32) -> bool {
	switch math.classify(x) {
	case .Normal, .Subnormal, .Zero, .Neg_Zero: return true
	case .Inf, .Neg_Inf, .NaN:                  return false
	case:                                       unreachable()
	}
}

@(require, linkage="strong", link_name="__isfinited")
isfinited :: proc "c" (x: f64) -> bool {
	switch math.classify(x) {
	case .Normal, .Subnormal, .Zero, .Neg_Zero: return true
	case .Inf, .Neg_Inf, .NaN:                  return false
	case:                                       unreachable()
	}
}

@(require, linkage="strong", link_name="log2")
log2 :: proc "c" (x: f64) -> f64 {
	return math.log2(x)
}

@(require, linkage="strong", link_name="log10")
log10 :: proc "c" (x: f64) -> f64 {
	return math.log10(x)
}

@(require, linkage="strong", link_name="asin")
asin :: proc "c" (x: f64) -> f64 {
	return math.asin(x)
}

@(require, linkage="strong", link_name="atan")
atan :: proc "c" (x: f64) -> f64 {
	return math.atan(x)
}

@(require, linkage="strong", link_name="tan")
tan :: proc "c" (x: f64) -> f64 {
	return math.tan(x)
}

@(require, linkage="strong", link_name="atan2")
atan2 :: proc "c" (y: f64, x: f64) -> f64 {
	return math.atan2(y, x)
}

@(require, linkage="strong", link_name="modf")
modf :: proc "c" (num: f64, iptr: ^f64) -> f64 {
	integral, fractional := math.modf(num)
	iptr^ = integral
	return fractional
}
