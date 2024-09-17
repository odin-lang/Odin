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

@(require, linkage="strong", link_name="sinf")
sinf :: proc "c" (v: f32) -> f32 {
	return math.sin(v)
}

@(require, linkage="strong", link_name="atan2f")
atan2f :: proc "c" (v: f32, v2: f32) -> f32 {
	return math.atan2(v, v2)
}

@(require, linkage="strong", link_name="isnan")
isnan :: proc "c" (v: f32) -> bool {
	return math.is_nan(v)
}

@(require, linkage="strong", link_name="isinf")
isinf :: proc "c" (v: f32) -> bool {
	return math.is_inf(v)
}

@(require, linkage="strong", link_name="sqrt")
sqrt :: proc "c" (x: f64) -> f64 {
	return math.sqrt(x)
}

@(require, linkage="strong", link_name="floor")
floor :: proc "c" (x: f64) -> f64 {
	return math.floor(x)
}

@(require, linkage="strong", link_name="ceil")
ceil :: proc "c" (x: f64) -> f64 {
	return math.ceil(x)
}

@(require, linkage="strong", link_name="pow")
pow :: proc "c" (x, y: f64) -> f64 {
	return math.pow(x, y)
}

@(require, linkage="strong", link_name="fmod")
fmod :: proc "c" (x, y: f64) -> f64 {
	return math.mod(x, y)
}

@(require, linkage="strong", link_name="cos")
cos :: proc "c" (x: f64) -> f64 {
	return math.cos(x)
}

@(require, linkage="strong", link_name="acos")
acos :: proc "c" (x: f64) -> f64 {
	return math.acos(x)
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

@(require, linkage="strong", link_name="log")
log :: proc "c" (x: f32) -> f32 {
	return math.ln(x)
}

@(require, linkage="strong", link_name="sin")
sin :: proc "c" (x: f32) -> f32 {
	return math.sin(x)
}
