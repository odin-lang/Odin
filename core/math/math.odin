package math

import "intrinsics"
_ :: intrinsics;

Float_Class :: enum {
	Normal,    // an ordinary nonzero floating point value
	Subnormal, // a subnormal floating point value
	Zero,      // zero
	Neg_Zero,  // the negative zero
	NaN,       // Not-A-Number (NaN)
	Inf,       // positive infinity
	Neg_Inf,   // negative infinity
};

TAU          :: 6.28318530717958647692528676655900576;
PI           :: 3.14159265358979323846264338327950288;

E            :: 2.71828182845904523536;

τ :: TAU;
π :: PI;
e :: E;

SQRT_TWO     :: 1.41421356237309504880168872420969808;
SQRT_THREE   :: 1.73205080756887729352744634150587236;
SQRT_FIVE    :: 2.23606797749978969640917366873127623;

LN2          :: 0.693147180559945309417232121458176568;
LN10         :: 2.30258509299404568401799145468436421;

MAX_F64_PRECISION :: 16; // Maximum number of meaningful digits after the decimal point for 'f64'
MAX_F32_PRECISION ::  8; // Maximum number of meaningful digits after the decimal point for 'f32'
MAX_F16_PRECISION ::  4; // Maximum number of meaningful digits after the decimal point for 'f16'

RAD_PER_DEG :: TAU/360.0;
DEG_PER_RAD :: 360.0/TAU;


@(default_calling_convention="none")
foreign _ {
	@(link_name="llvm.sqrt.f16")
	sqrt_f16 :: proc(x: f16) -> f16 ---;
	@(link_name="llvm.sqrt.f32")
	sqrt_f32 :: proc(x: f32) -> f32 ---;
	@(link_name="llvm.sqrt.f64")
	sqrt_f64 :: proc(x: f64) -> f64 ---;

	@(link_name="llvm.sin.f16")
	sin_f16 :: proc(θ: f16) -> f16 ---;
	@(link_name="llvm.sin.f32")
	sin_f32 :: proc(θ: f32) -> f32 ---;
	@(link_name="llvm.sin.f64")
	sin_f64 :: proc(θ: f64) -> f64 ---;

	@(link_name="llvm.cos.f16")
	cos_f16 :: proc(θ: f16) -> f16 ---;
	@(link_name="llvm.cos.f32")
	cos_f32 :: proc(θ: f32) -> f32 ---;
	@(link_name="llvm.cos.f64")
	cos_f64 :: proc(θ: f64) -> f64 ---;

	@(link_name="llvm.pow.f16")
	pow_f16 :: proc(x, power: f16) -> f16 ---;
	@(link_name="llvm.pow.f32")
	pow_f32 :: proc(x, power: f32) -> f32 ---;
	@(link_name="llvm.pow.f64")
	pow_f64 :: proc(x, power: f64) -> f64 ---;

	@(link_name="llvm.fmuladd.f16")
	fmuladd_f16 :: proc(a, b, c: f16) -> f16 ---;
	@(link_name="llvm.fmuladd.f32")
	fmuladd_f32 :: proc(a, b, c: f32) -> f32 ---;
	@(link_name="llvm.fmuladd.f64")
	fmuladd_f64 :: proc(a, b, c: f64) -> f64 ---;

	@(link_name="llvm.log.f16")
	ln_f16 :: proc(x: f16) -> f16 ---;
	@(link_name="llvm.log.f32")
	ln_f32 :: proc(x: f32) -> f32 ---;
	@(link_name="llvm.log.f64")
	ln_f64 :: proc(x: f64) -> f64 ---;

	@(link_name="llvm.exp.f16")
	exp_f16 :: proc(x: f16) -> f16 ---;
	@(link_name="llvm.exp.f32")
	exp_f32 :: proc(x: f32) -> f32 ---;
	@(link_name="llvm.exp.f64")
	exp_f64 :: proc(x: f64) -> f64 ---;

	@(link_name="llvm.ldexp.f16")
	ldexp_f16 :: proc(val: f16, exp: i32) -> f16 ---;
	@(link_name="llvm.ldexp.f32")
	ldexp_f32 :: proc(val: f32, exp: i32) -> f32 ---;
	@(link_name="llvm.ldexp.f64")
	ldexp_f64 :: proc(val: f64, exp: i32) -> f64 ---;
}

sqrt_f16le :: proc(x: f16le) -> f16le { return #force_inline f16le(sqrt_f16(f16(x))); }
sqrt_f16be :: proc(x: f16be) -> f16be { return #force_inline f16be(sqrt_f16(f16(x))); }
sqrt_f32le :: proc(x: f32le) -> f32le { return #force_inline f32le(sqrt_f32(f32(x))); }
sqrt_f32be :: proc(x: f32be) -> f32be { return #force_inline f32be(sqrt_f32(f32(x))); }
sqrt_f64le :: proc(x: f64le) -> f64le { return #force_inline f64le(sqrt_f64(f64(x))); }
sqrt_f64be :: proc(x: f64be) -> f64be { return #force_inline f64be(sqrt_f64(f64(x))); }
sqrt       :: proc{
	sqrt_f16, sqrt_f16le, sqrt_f16be,
	sqrt_f32, sqrt_f32le, sqrt_f32be,
	sqrt_f64, sqrt_f64le, sqrt_f64be,
};

sin_f16le :: proc(θ: f16le) -> f16le { return #force_inline f16le(sin_f16(f16(θ))); }
sin_f16be :: proc(θ: f16be) -> f16be { return #force_inline f16be(sin_f16(f16(θ))); }
sin_f32le :: proc(θ: f32le) -> f32le { return #force_inline f32le(sin_f32(f32(θ))); }
sin_f32be :: proc(θ: f32be) -> f32be { return #force_inline f32be(sin_f32(f32(θ))); }
sin_f64le :: proc(θ: f64le) -> f64le { return #force_inline f64le(sin_f64(f64(θ))); }
sin_f64be :: proc(θ: f64be) -> f64be { return #force_inline f64be(sin_f64(f64(θ))); }
sin       :: proc{
	sin_f16, sin_f16le, sin_f16be,
	sin_f32, sin_f32le, sin_f32be,
	sin_f64, sin_f64le, sin_f64be,
};

cos_f16le :: proc(θ: f16le) -> f16le { return #force_inline f16le(cos_f16(f16(θ))); }
cos_f16be :: proc(θ: f16be) -> f16be { return #force_inline f16be(cos_f16(f16(θ))); }
cos_f32le :: proc(θ: f32le) -> f32le { return #force_inline f32le(cos_f32(f32(θ))); }
cos_f32be :: proc(θ: f32be) -> f32be { return #force_inline f32be(cos_f32(f32(θ))); }
cos_f64le :: proc(θ: f64le) -> f64le { return #force_inline f64le(cos_f64(f64(θ))); }
cos_f64be :: proc(θ: f64be) -> f64be { return #force_inline f64be(cos_f64(f64(θ))); }
cos       :: proc{
	cos_f16, cos_f16le, cos_f16be,
	cos_f32, cos_f32le, cos_f32be,
	cos_f64, cos_f64le, cos_f64be,
};

pow_f16le :: proc(x, power: f16le) -> f16le { return #force_inline f16le(pow_f16(f16(x), f16(power))); }
pow_f16be :: proc(x, power: f16be) -> f16be { return #force_inline f16be(pow_f16(f16(x), f16(power))); }
pow_f32le :: proc(x, power: f32le) -> f32le { return #force_inline f32le(pow_f32(f32(x), f32(power))); }
pow_f32be :: proc(x, power: f32be) -> f32be { return #force_inline f32be(pow_f32(f32(x), f32(power))); }
pow_f64le :: proc(x, power: f64le) -> f64le { return #force_inline f64le(pow_f64(f64(x), f64(power))); }
pow_f64be :: proc(x, power: f64be) -> f64be { return #force_inline f64be(pow_f64(f64(x), f64(power))); }
pow       :: proc{
	pow_f16, pow_f16le, pow_f16be,
	pow_f32, pow_f32le, pow_f32be,
	pow_f64, pow_f64le, pow_f64be,
};

fmuladd_f16le :: proc(a, b, c: f16le) -> f16le { return #force_inline f16le(fmuladd_f16(f16(a), f16(b), f16(c))); }
fmuladd_f16be :: proc(a, b, c: f16be) -> f16be { return #force_inline f16be(fmuladd_f16(f16(a), f16(b), f16(c))); }
fmuladd_f32le :: proc(a, b, c: f32le) -> f32le { return #force_inline f32le(fmuladd_f32(f32(a), f32(b), f32(c))); }
fmuladd_f32be :: proc(a, b, c: f32be) -> f32be { return #force_inline f32be(fmuladd_f32(f32(a), f32(b), f32(c))); }
fmuladd_f64le :: proc(a, b, c: f64le) -> f64le { return #force_inline f64le(fmuladd_f64(f64(a), f64(b), f64(c))); }
fmuladd_f64be :: proc(a, b, c: f64be) -> f64be { return #force_inline f64be(fmuladd_f64(f64(a), f64(b), f64(c))); }
fmuladd       :: proc{
	fmuladd_f16, fmuladd_f16le, fmuladd_f16be,
	fmuladd_f32, fmuladd_f32le, fmuladd_f32be,
	fmuladd_f64, fmuladd_f64le, fmuladd_f64be,
};

ln_f16le :: proc(x: f16le) -> f16le { return #force_inline f16le(ln_f16(f16(x))); }
ln_f16be :: proc(x: f16be) -> f16be { return #force_inline f16be(ln_f16(f16(x))); }
ln_f32le :: proc(x: f32le) -> f32le { return #force_inline f32le(ln_f32(f32(x))); }
ln_f32be :: proc(x: f32be) -> f32be { return #force_inline f32be(ln_f32(f32(x))); }
ln_f64le :: proc(x: f64le) -> f64le { return #force_inline f64le(ln_f64(f64(x))); }
ln_f64be :: proc(x: f64be) -> f64be { return #force_inline f64be(ln_f64(f64(x))); }
ln       :: proc{
	ln_f16, ln_f16le, ln_f16be,
	ln_f32, ln_f32le, ln_f32be,
	ln_f64, ln_f64le, ln_f64be,
};

exp_f16le :: proc(x: f16le) -> f16le { return #force_inline f16le(exp_f16(f16(x))); }
exp_f16be :: proc(x: f16be) -> f16be { return #force_inline f16be(exp_f16(f16(x))); }
exp_f32le :: proc(x: f32le) -> f32le { return #force_inline f32le(exp_f32(f32(x))); }
exp_f32be :: proc(x: f32be) -> f32be { return #force_inline f32be(exp_f32(f32(x))); }
exp_f64le :: proc(x: f64le) -> f64le { return #force_inline f64le(exp_f64(f64(x))); }
exp_f64be :: proc(x: f64be) -> f64be { return #force_inline f64be(exp_f64(f64(x))); }
exp       :: proc{
	exp_f16, exp_f16le, exp_f16be,
	exp_f32, exp_f32le, exp_f32be,
	exp_f64, exp_f64le, exp_f64be,
};

ldexp_f16le :: proc(val: f16le, exp: i32) -> f16le { return #force_inline f16le(ldexp_f16(f16(val), exp)); }
ldexp_f16be :: proc(val: f16be, exp: i32) -> f16be { return #force_inline f16be(ldexp_f16(f16(val), exp)); }
ldexp_f32le :: proc(val: f32le, exp: i32) -> f32le { return #force_inline f32le(ldexp_f32(f32(val), exp)); }
ldexp_f32be :: proc(val: f32be, exp: i32) -> f32be { return #force_inline f32be(ldexp_f32(f32(val), exp)); }
ldexp_f64le :: proc(val: f64le, exp: i32) -> f64le { return #force_inline f64le(ldexp_f64(f64(val), exp)); }
ldexp_f64be :: proc(val: f64be, exp: i32) -> f64be { return #force_inline f64be(ldexp_f64(f64(val), exp)); }
ldexp       :: proc{
	ldexp_f16, ldexp_f16le, ldexp_f16be,
	ldexp_f32, ldexp_f32le, ldexp_f32be,
	ldexp_f64, ldexp_f64le, ldexp_f64be,
};


log_f16   :: proc(x, base: f16)   -> f16   { return ln(x) / ln(base); }
log_f16le :: proc(x, base: f16le) -> f16le { return f16le(log_f16(f16(x), f16(base))); }
log_f16be :: proc(x, base: f16be) -> f16be { return f16be(log_f16(f16(x), f16(base))); }

log_f32   :: proc(x, base: f32)   -> f32   { return ln(x) / ln(base); }
log_f32le :: proc(x, base: f32le) -> f32le { return f32le(log_f32(f32(x), f32(base))); }
log_f32be :: proc(x, base: f32be) -> f32be { return f32be(log_f32(f32(x), f32(base))); }

log_f64   :: proc(x, base: f64)   -> f64   { return ln(x) / ln(base); }
log_f64le :: proc(x, base: f64le) -> f64le { return f64le(log_f64(f64(x), f64(base))); }
log_f64be :: proc(x, base: f64be) -> f64be { return f64be(log_f64(f64(x), f64(base))); }
log       :: proc{
	log_f16, log_f16le, log_f16be,
	log_f32, log_f32le, log_f32be,
	log_f64, log_f64le, log_f64be,
};

log2_f16   :: proc(x: f16)   -> f16   { return ln(x)/LN2; }
log2_f16le :: proc(x: f16le) -> f16le { return f16le(log2_f16(f16(x))); }
log2_f16be :: proc(x: f16be) -> f16be { return f16be(log2_f16(f16(x))); }

log2_f32   :: proc(x: f32)   -> f32   { return ln(x)/LN2; }
log2_f32le :: proc(x: f32le) -> f32le { return f32le(log2_f32(f32(x))); }
log2_f32be :: proc(x: f32be) -> f32be { return f32be(log2_f32(f32(x))); }

log2_f64   :: proc(x: f64)   -> f64   { return ln(x)/LN2; }
log2_f64le :: proc(x: f64le) -> f64le { return f64le(log2_f64(f64(x))); }
log2_f64be :: proc(x: f64be) -> f64be { return f64be(log2_f64(f64(x))); }
log2       :: proc{
	log2_f16, log2_f16le, log2_f16be,
	log2_f32, log2_f32le, log2_f32be,
	log2_f64, log2_f64le, log2_f64be,
};

log10_f16   :: proc(x: f16)   -> f16   { return ln(x)/LN10; }
log10_f16le :: proc(x: f16le) -> f16le { return f16le(log10_f16(f16(x))); }
log10_f16be :: proc(x: f16be) -> f16be { return f16be(log10_f16(f16(x))); }

log10_f32   :: proc(x: f32)   -> f32   { return ln(x)/LN10; }
log10_f32le :: proc(x: f32le) -> f32le { return f32le(log10_f32(f32(x))); }
log10_f32be :: proc(x: f32be) -> f32be { return f32be(log10_f32(f32(x))); }

log10_f64   :: proc(x: f64)   -> f64   { return ln(x)/LN10; }
log10_f64le :: proc(x: f64le) -> f64le { return f64le(log10_f64(f64(x))); }
log10_f64be :: proc(x: f64be) -> f64be { return f64be(log10_f64(f64(x))); }
log10       :: proc{
	log10_f16, log10_f16le, log10_f16be,
	log10_f32, log10_f32le, log10_f32be,
	log10_f64, log10_f64le, log10_f64be,
};

tan_f16   :: proc(θ: f16)   -> f16   { return sin(θ)/cos(θ); }
tan_f16le :: proc(θ: f16le) -> f16le { return f16le(tan_f16(f16(θ))); }
tan_f16be :: proc(θ: f16be) -> f16be { return f16be(tan_f16(f16(θ))); }

tan_f32   :: proc(θ: f32)   -> f32   { return sin(θ)/cos(θ); }
tan_f32le :: proc(θ: f32le) -> f32le { return f32le(tan_f32(f32(θ))); }
tan_f32be :: proc(θ: f32be) -> f32be { return f32be(tan_f32(f32(θ))); }

tan_f64   :: proc(θ: f64)   -> f64   { return sin(θ)/cos(θ); }
tan_f64le :: proc(θ: f64le) -> f64le { return f64le(tan_f64(f64(θ))); }
tan_f64be :: proc(θ: f64be) -> f64be { return f64be(tan_f64(f64(θ))); }
tan       :: proc{
	tan_f16, tan_f16le, tan_f16be,
	tan_f32, tan_f32le, tan_f32be,
	tan_f64, tan_f64le, tan_f64be,
};

lerp :: proc(a, b: $T, t: $E) -> (x: T) { return a*(1-t) + b*t; }
saturate :: proc(a: $T) -> (x: T) { return clamp(a, 0, 1); };

unlerp :: proc(a, b, x: $T) -> (t: T)  where intrinsics.type_is_float(T), !intrinsics.type_is_array(T) {
	return (x-a)/(b-a);
}

remap :: proc(old_value, old_min, old_max, new_min, new_max: $T) -> (x: T) where intrinsics.type_is_numeric(T), !intrinsics.type_is_array(T) {
	old_range := old_max - old_min;
	new_range := new_max - new_min;
	if old_range == 0 {
		return new_range / 2;
	}
	return ((old_value - old_min) / old_range) * new_range + new_min;
}

wrap :: proc(x, y: $T) -> T where intrinsics.type_is_numeric(T), !intrinsics.type_is_array(T) {
	tmp := mod(x, y);
	return y + tmp if tmp < 0 else tmp;
}
angle_diff :: proc(a, b: $T) -> T where intrinsics.type_is_numeric(T), !intrinsics.type_is_array(T) {

	dist := wrap(b - a, TAU);
	return wrap(dist*2, TAU) - dist;
}

angle_lerp :: proc(a, b, t: $T) -> T where intrinsics.type_is_numeric(T), !intrinsics.type_is_array(T) {
	return a + angle_diff(a, b) * t;
}

step :: proc(edge, x: $T) -> T where intrinsics.type_is_numeric(T), !intrinsics.type_is_array(T) {
	return 0 if x < edge else 1;
}

smoothstep :: proc(edge0, edge1, x: $T) -> T where intrinsics.type_is_numeric(T), !intrinsics.type_is_array(T) {
	t := clamp((x - edge0) / (edge1 - edge0), 0, 1);
	return t * t * (3 - 2*t);
}

bias :: proc(t, b: $T) -> T where intrinsics.type_is_numeric(T) {
	return t / (((1/b) - 2) * (1 - t) + 1);
}
gain :: proc(t, g: $T) -> T where intrinsics.type_is_numeric(T) {
	if t < 0.5 {
		return bias(t*2, g)*0.5;
	}
	return bias(t*2 - 1, 1 - g)*0.5 + 0.5;
}


sign_f16   :: proc(x: f16)   -> f16   { return f16(int(0 < x) - int(x < 0)); }
sign_f16le :: proc(x: f16le) -> f16le { return f16le(int(0 < x) - int(x < 0)); }
sign_f16be :: proc(x: f16be) -> f16be { return f16be(int(0 < x) - int(x < 0)); }
sign_f32   :: proc(x: f32)   -> f32   { return f32(int(0 < x) - int(x < 0)); }
sign_f32le :: proc(x: f32le) -> f32le { return f32le(int(0 < x) - int(x < 0)); }
sign_f32be :: proc(x: f32be) -> f32be { return f32be(int(0 < x) - int(x < 0)); }
sign_f64   :: proc(x: f64)   -> f64   { return f64(int(0 < x) - int(x < 0)); }
sign_f64le :: proc(x: f64le) -> f64le { return f64le(int(0 < x) - int(x < 0)); }
sign_f64be :: proc(x: f64be) -> f64be { return f64be(int(0 < x) - int(x < 0)); }
sign       :: proc{
	sign_f16, sign_f16le, sign_f16be,
	sign_f32, sign_f32le, sign_f32be,
	sign_f64, sign_f64le, sign_f64be,
};

sign_bit_f16 :: proc(x: f16)     -> bool {
	return (transmute(u16)x) & (1<<15) != 0;
}
sign_bit_f16le :: proc(x: f16le) -> bool { return #force_inline sign_bit_f16(f16(x)); }
sign_bit_f16be :: proc(x: f16be) -> bool { return #force_inline sign_bit_f16(f16(x)); }
sign_bit_f32   :: proc(x: f32)   -> bool {
	return (transmute(u32)x) & (1<<31) != 0;
}
sign_bit_f32le :: proc(x: f32le) -> bool { return #force_inline sign_bit_f32(f32(x)); }
sign_bit_f32be :: proc(x: f32be) -> bool { return #force_inline sign_bit_f32(f32(x)); }
sign_bit_f64   :: proc(x: f64)   -> bool {
	return (transmute(u64)x) & (1<<63) != 0;
}
sign_bit_f64le :: proc(x: f64le) -> bool { return #force_inline sign_bit_f64(f64(x)); }
sign_bit_f64be :: proc(x: f64be) -> bool { return #force_inline sign_bit_f64(f64(x)); }
sign_bit       :: proc{
	sign_bit_f16, sign_bit_f16le, sign_bit_f16be,
	sign_bit_f32, sign_bit_f32le, sign_bit_f32be,
	sign_bit_f64, sign_bit_f64le, sign_bit_f64be,
};

copy_sign_f16   :: proc(x, y: f16) -> f16 {
	ix := transmute(u16)x;
	iy := transmute(u16)y;
	ix &= 0x7fff;
	ix |= iy & 0x8000;
	return transmute(f16)ix;
}
copy_sign_f16le :: proc(x, y: f16le) -> f16le { return #force_inline f16le(copy_sign_f16(f16(x), f16(y))); }
copy_sign_f16be :: proc(x, y: f16be) -> f16be { return #force_inline f16be(copy_sign_f16(f16(x), f16(y))); }
copy_sign_f32   :: proc(x, y: f32) -> f32 {
	ix := transmute(u32)x;
	iy := transmute(u32)y;
	ix &= 0x7fff_ffff;
	ix |= iy & 0x8000_0000;
	return transmute(f32)ix;
}
copy_sign_f32le :: proc(x, y: f32le) -> f32le { return #force_inline f32le(copy_sign_f32(f32(x), f32(y))); }
copy_sign_f32be :: proc(x, y: f32be) -> f32be { return #force_inline f32be(copy_sign_f32(f32(x), f32(y))); }
copy_sign_f64   :: proc(x, y: f64) -> f64 {
	ix := transmute(u64)x;
	iy := transmute(u64)y;
	ix &= 0x7fff_ffff_ffff_ffff;
	ix |= iy & 0x8000_0000_0000_0000;
	return transmute(f64)ix;
}
copy_sign_f64le :: proc(x, y: f64le) -> f64le { return #force_inline f64le(copy_sign_f64(f64(x), f64(y))); }
copy_sign_f64be :: proc(x, y: f64be) -> f64be { return #force_inline f64be(copy_sign_f64(f64(x), f64(y))); }
copy_sign       :: proc{
	copy_sign_f16, copy_sign_f16le, copy_sign_f16be,
	copy_sign_f32, copy_sign_f32le, copy_sign_f32be,
	copy_sign_f64, copy_sign_f64le, copy_sign_f64be,
};

to_radians_f16   :: proc(degrees: f16)   -> f16   { return degrees * RAD_PER_DEG; }
to_radians_f16le :: proc(degrees: f16le) -> f16le { return degrees * RAD_PER_DEG; }
to_radians_f16be :: proc(degrees: f16be) -> f16be { return degrees * RAD_PER_DEG; }
to_radians_f32   :: proc(degrees: f32)   -> f32   { return degrees * RAD_PER_DEG; }
to_radians_f32le :: proc(degrees: f32le) -> f32le { return degrees * RAD_PER_DEG; }
to_radians_f32be :: proc(degrees: f32be) -> f32be { return degrees * RAD_PER_DEG; }
to_radians_f64   :: proc(degrees: f64)   -> f64   { return degrees * RAD_PER_DEG; }
to_radians_f64le :: proc(degrees: f64le) -> f64le { return degrees * RAD_PER_DEG; }
to_radians_f64be :: proc(degrees: f64be) -> f64be { return degrees * RAD_PER_DEG; }
to_degrees_f16   :: proc(radians: f16)   -> f16   { return radians * DEG_PER_RAD; }
to_degrees_f16le :: proc(radians: f16le) -> f16le { return radians * DEG_PER_RAD; }
to_degrees_f16be :: proc(radians: f16be) -> f16be { return radians * DEG_PER_RAD; }
to_degrees_f32   :: proc(radians: f32)   -> f32   { return radians * DEG_PER_RAD; }
to_degrees_f32le :: proc(radians: f32le) -> f32le { return radians * DEG_PER_RAD; }
to_degrees_f32be :: proc(radians: f32be) -> f32be { return radians * DEG_PER_RAD; }
to_degrees_f64   :: proc(radians: f64)   -> f64   { return radians * DEG_PER_RAD; }
to_degrees_f64le :: proc(radians: f64le) -> f64le { return radians * DEG_PER_RAD; }
to_degrees_f64be :: proc(radians: f64be) -> f64be { return radians * DEG_PER_RAD; }
to_radians       :: proc{
	to_radians_f16, to_radians_f16le, to_radians_f16be,
	to_radians_f32, to_radians_f32le, to_radians_f32be,
	to_radians_f64, to_radians_f64le, to_radians_f64be,
};
to_degrees       :: proc{
	to_degrees_f16, to_degrees_f16le, to_degrees_f16be,
	to_degrees_f32, to_degrees_f32le, to_degrees_f32be,
	to_degrees_f64, to_degrees_f64le, to_degrees_f64be,
};

trunc_f16   :: proc(x: f16) -> f16 {
	trunc_internal :: proc(f: f16) -> f16 {
		mask :: 0x1f;
		shift :: 16 - 6;
		bias :: 0xf;

		if f < 1 {
			switch {
			case f < 0:  return -trunc_internal(-f);
			case f == 0: return f;
			case:        return 0;
			}
		}

		x := transmute(u16)f;
		e := (x >> shift) & mask - bias;

		if e < shift {
			x &= ~(1 << (shift-e)) - 1;
		}
		return transmute(f16)x;
	}
	switch classify(x) {
	case .Zero, .Neg_Zero, .NaN, .Inf, .Neg_Inf:
		return x;
	case .Normal, .Subnormal: // carry on
	}
	return trunc_internal(x);
}
trunc_f16le :: proc(x: f16le) -> f16le { return #force_inline f16le(trunc_f16(f16(x))); }
trunc_f16be :: proc(x: f16be) -> f16be { return #force_inline f16be(trunc_f16(f16(x))); }

trunc_f32   :: proc(x: f32) -> f32 {
	trunc_internal :: proc(f: f32) -> f32 {
		mask :: 0xff;
		shift :: 32 - 9;
		bias :: 0x7f;

		if f < 1 {
			switch {
			case f < 0:  return -trunc_internal(-f);
			case f == 0: return f;
			case:        return 0;
			}
		}

		x := transmute(u32)f;
		e := (x >> shift) & mask - bias;

		if e < shift {
			x &= ~(1 << (shift-e)) - 1;
		}
		return transmute(f32)x;
	}
	switch classify(x) {
	case .Zero, .Neg_Zero, .NaN, .Inf, .Neg_Inf:
		return x;
	case .Normal, .Subnormal: // carry on
	}
	return trunc_internal(x);
}
trunc_f32le :: proc(x: f32le) -> f32le { return #force_inline f32le(trunc_f32(f32(x))); }
trunc_f32be :: proc(x: f32be) -> f32be { return #force_inline f32be(trunc_f32(f32(x))); }

trunc_f64   :: proc(x: f64) -> f64 {
	trunc_internal :: proc(f: f64) -> f64 {
		mask :: 0x7ff;
		shift :: 64 - 12;
		bias :: 0x3ff;

		if f < 1 {
			switch {
			case f < 0:  return -trunc_internal(-f);
			case f == 0: return f;
			case:        return 0;
			}
		}

		x := transmute(u64)f;
		e := (x >> shift) & mask - bias;

		if e < shift {
			x &= ~(1 << (shift-e)) - 1;
		}
		return transmute(f64)x;
	}
	switch classify(x) {
	case .Zero, .Neg_Zero, .NaN, .Inf, .Neg_Inf:
		return x;
	case .Normal, .Subnormal: // carry on
	}
	return trunc_internal(x);
}
trunc_f64le :: proc(x: f64le) -> f64le { return #force_inline f64le(trunc_f64(f64(x))); }
trunc_f64be :: proc(x: f64be) -> f64be { return #force_inline f64be(trunc_f64(f64(x))); }
trunc       :: proc{
	trunc_f16, trunc_f16le, trunc_f16be,
	trunc_f32, trunc_f32le, trunc_f32be, 
	trunc_f64, trunc_f64le, trunc_f64be, 
};

round_f16   :: proc(x: f16)   -> f16 {
	return ceil(x - 0.5) if x < 0 else floor(x + 0.5);
}
round_f16le :: proc(x: f16le) -> f16le {
	return ceil(x - 0.5) if x < 0 else floor(x + 0.5);
}
round_f16be :: proc(x: f16be) -> f16be {
	return ceil(x - 0.5) if x < 0 else floor(x + 0.5);
}

round_f32   :: proc(x: f32)   -> f32 {
	return ceil(x - 0.5) if x < 0 else floor(x + 0.5);
}
round_f32le :: proc(x: f32le) -> f32le {
	return ceil(x - 0.5) if x < 0 else floor(x + 0.5);
}
round_f32be :: proc(x: f32be) -> f32be {
	return ceil(x - 0.5) if x < 0 else floor(x + 0.5);
}
round_f64   :: proc(x: f64)   -> f64 {
	return ceil(x - 0.5) if x < 0 else floor(x + 0.5);
}
round_f64le :: proc(x: f64le) -> f64le {
	return ceil(x - 0.5) if x < 0 else floor(x + 0.5);
}
round_f64be :: proc(x: f64be) -> f64be {
	return ceil(x - 0.5) if x < 0 else floor(x + 0.5);
}
round       :: proc{
	round_f16, round_f16le, round_f16be,
	round_f32, round_f32le, round_f32be,
	round_f64, round_f64le, round_f64be,
};


ceil_f16   :: proc(x: f16)   -> f16   { return -floor(-x); }
ceil_f16le :: proc(x: f16le) -> f16le { return -floor(-x); }
ceil_f16be :: proc(x: f16be) -> f16be { return -floor(-x); }

ceil_f32   :: proc(x: f32)   -> f32   { return -floor(-x); }
ceil_f32le :: proc(x: f32le) -> f32le { return -floor(-x); }
ceil_f32be :: proc(x: f32be) -> f32be { return -floor(-x); }

ceil_f64   :: proc(x: f64)   -> f64   { return -floor(-x); }
ceil_f64le :: proc(x: f64le) -> f64le { return -floor(-x); }
ceil_f64be :: proc(x: f64be) -> f64be { return -floor(-x); }

ceil       :: proc{
	ceil_f16, ceil_f16le, ceil_f16be,
	ceil_f32, ceil_f32le, ceil_f32be,
	ceil_f64, ceil_f64le, ceil_f64be,
};

floor_f16   :: proc(x: f16)   -> f16 {
	if x == 0 || is_nan(x) || is_inf(x) {
		return x;
	}
	if x < 0 {
		d, fract := modf(-x);
		if fract != 0.0 {
			d = d + 1;
		}
		return -d;
	}
	d, _ := modf(x);
	return d;
}
floor_f16le :: proc(x: f16le) -> f16le { return #force_inline f16le(floor_f16(f16(x))); }
floor_f16be :: proc(x: f16be) -> f16be { return #force_inline f16be(floor_f16(f16(x))); }
floor_f32   :: proc(x: f32)   -> f32 {
	if x == 0 || is_nan(x) || is_inf(x) {
		return x;
	}
	if x < 0 {
		d, fract := modf(-x);
		if fract != 0.0 {
			d = d + 1;
		}
		return -d;
	}
	d, _ := modf(x);
	return d;
}
floor_f32le :: proc(x: f32le) -> f32le { return #force_inline f32le(floor_f32(f32(x))); }
floor_f32be :: proc(x: f32be) -> f32be { return #force_inline f32be(floor_f32(f32(x))); }
floor_f64   :: proc(x: f64)   -> f64 {
	if x == 0 || is_nan(x) || is_inf(x) {
		return x;
	}
	if x < 0 {
		d, fract := modf(-x);
		if fract != 0.0 {
			d = d + 1;
		}
		return -d;
	}
	d, _ := modf(x);
	return d;
}
floor_f64le :: proc(x: f64le) -> f64le { return #force_inline f64le(floor_f64(f64(x))); }
floor_f64be :: proc(x: f64be) -> f64be { return #force_inline f64be(floor_f64(f64(x))); }
floor       :: proc{
	floor_f16, floor_f16le, floor_f16be,
	floor_f32, floor_f32le, floor_f32be,
	floor_f64, floor_f64le, floor_f64be,
};


floor_div :: proc(x, y: $T) -> T
	where intrinsics.type_is_integer(T) {
	a := x / y;
	r := x % y;
	if (r > 0 && y < 0) || (r < 0 && y > 0) {
		a -= 1;
	}
	return a;
}

floor_mod :: proc(x, y: $T) -> T
	where intrinsics.type_is_integer(T) {
	r := x % y;
	if (r > 0 && y < 0) || (r < 0 && y > 0) {
		r += y;
	}
	return r;
}

modf_f16   :: proc(x: f16) -> (int: f16, frac: f16) {
	shift :: 16 - 5 - 1;
	mask  :: 0x1f;
	bias  :: 15;

	if x < 1 {
		switch {
		case x < 0:
			int, frac = modf(-x);
			return -int, -frac;
		case x == 0:
			return x, x;
		}
		return 0, x;
	}

	i := transmute(u16)x;
	e := uint(i>>shift)&mask - bias;

	if e < shift {
		i &~= 1<<(shift-e) - 1;
	}
	int = transmute(f16)i;
	frac = x - int;
	return;
}
modf_f16le :: proc(x: f16le) -> (int: f16le, frac: f16le) {
	i, f := #force_inline modf_f16(f16(x));
	return f16le(i), f16le(f);
}
modf_f16be :: proc(x: f16be) -> (int: f16be, frac: f16be) {
	i, f := #force_inline modf_f16(f16(x));
	return f16be(i), f16be(f);
}
modf_f32   :: proc(x: f32) -> (int: f32, frac: f32) {
	shift :: 32 - 8 - 1;
	mask  :: 0xff;
	bias  :: 127;

	if x < 1 {
		switch {
		case x < 0:
			int, frac = modf(-x);
			return -int, -frac;
		case x == 0:
			return x, x;
		}
		return 0, x;
	}

	i := transmute(u32)x;
	e := uint(i>>shift)&mask - bias;

	if e < shift {
		i &~= 1<<(shift-e) - 1;
	}
	int = transmute(f32)i;
	frac = x - int;
	return;
}
modf_f32le :: proc(x: f32le) -> (int: f32le, frac: f32le) {
	i, f := #force_inline modf_f32(f32(x));
	return f32le(i), f32le(f);
}
modf_f32be :: proc(x: f32be) -> (int: f32be, frac: f32be) {
	i, f := #force_inline modf_f32(f32(x));
	return f32be(i), f32be(f);
}
modf_f64   :: proc(x: f64) -> (int: f64, frac: f64) {
	shift :: 64 - 11 - 1;
	mask  :: 0x7ff;
	bias  :: 1023;

	if x < 1 {
		switch {
		case x < 0:
			int, frac = modf(-x);
			return -int, -frac;
		case x == 0:
			return x, x;
		}
		return 0, x;
	}

	i := transmute(u64)x;
	e := uint(i>>shift)&mask - bias;

	if e < shift {
		i &~= 1<<(shift-e) - 1;
	}
	int = transmute(f64)i;
	frac = x - int;
	return;
}
modf_f64le :: proc(x: f64le) -> (int: f64le, frac: f64le) {
	i, f := #force_inline modf_f64(f64(x));
	return f64le(i), f64le(f);
}
modf_f64be :: proc(x: f64be) -> (int: f64be, frac: f64be) {
	i, f := #force_inline modf_f64(f64(x));
	return f64be(i), f64be(f);
}
modf       :: proc{
	modf_f16, modf_f16le, modf_f16be,
	modf_f32, modf_f32le, modf_f32be,
	modf_f64, modf_f64le, modf_f64be,
};
split_decimal :: modf;

mod_f16   :: proc(x, y: f16) -> (n: f16) {
	z := abs(y);
	n = remainder(abs(x), z);
	if sign(n) < 0 {
		n += z;
	}
	return copy_sign(n, x);
}
mod_f16le :: proc(x, y: f16le) -> (n: f16le) { return #force_inline f16le(mod_f16(f16(x), f16(y))); }
mod_f16be :: proc(x, y: f16be) -> (n: f16be) { return #force_inline f16be(mod_f16(f16(x), f16(y))); }
mod_f32   :: proc(x, y: f32)   -> (n: f32) {
	z := abs(y);
	n = remainder(abs(x), z);
	if sign(n) < 0 {
		n += z;
	}
	return copy_sign(n, x);
}
mod_f32le :: proc(x, y: f32le) -> (n: f32le) { return #force_inline f32le(mod_f32(f32(x), f32(y))); }
mod_f32be :: proc(x, y: f32be) -> (n: f32be) { return #force_inline f32be(mod_f32(f32(x), f32(y))); }
mod_f64   :: proc(x, y: f64)   -> (n: f64) {
	z := abs(y);
	n = remainder(abs(x), z);
	if sign(n) < 0 {
		n += z;
	}
	return copy_sign(n, x);
}
mod_f64le :: proc(x, y: f64le) -> (n: f64le) { return #force_inline f64le(mod_f64(f64(x), f64(y))); }
mod_f64be :: proc(x, y: f64be) -> (n: f64be) { return #force_inline f64be(mod_f64(f64(x), f64(y))); }
mod       :: proc{
	mod_f16, mod_f16le, mod_f16be,
	mod_f32, mod_f32le, mod_f32be,
	mod_f64, mod_f64le, mod_f64be,
};

remainder_f16   :: proc(x, y: f16  ) -> f16   { return x - round(x/y) * y; }
remainder_f16le :: proc(x, y: f16le) -> f16le { return x - round(x/y) * y; }
remainder_f16be :: proc(x, y: f16be) -> f16be { return x - round(x/y) * y; }
remainder_f32   :: proc(x, y: f32  ) -> f32   { return x - round(x/y) * y; }
remainder_f32le :: proc(x, y: f32le) -> f32le { return x - round(x/y) * y; }
remainder_f32be :: proc(x, y: f32be) -> f32be { return x - round(x/y) * y; }
remainder_f64   :: proc(x, y: f64  ) -> f64   { return x - round(x/y) * y; }
remainder_f64le :: proc(x, y: f64le) -> f64le { return x - round(x/y) * y; }
remainder_f64be :: proc(x, y: f64be) -> f64be { return x - round(x/y) * y; }
remainder       :: proc{
	remainder_f16, remainder_f16le, remainder_f16be,
	remainder_f32, remainder_f32le, remainder_f32be,
	remainder_f64, remainder_f64le, remainder_f64be,
};

gcd :: proc(x, y: $T) -> T
	where intrinsics.type_is_ordered_numeric(T) {
	x, y := x, y;
	for y != 0 {
		x %= y;
		x, y = y, x;
	}
	return abs(x);
}

lcm :: proc(x, y: $T) -> T
	where intrinsics.type_is_ordered_numeric(T) {
	return x / gcd(x, y) * y;
}

frexp_f16   :: proc(x: f16)   -> (significand: f16,   exponent: int) {
	f, e := frexp_f64(f64(x));
	return f16(f), e;
}
frexp_f16le :: proc(x: f16le) -> (significand: f16le, exponent: int) {
	f, e := frexp_f64(f64(x));
	return f16le(f), e;
}
frexp_f16be :: proc(x: f16be) -> (significand: f16be, exponent: int) {
	f, e := frexp_f64(f64(x));
	return f16be(f), e;
}
frexp_f32 :: proc(x: f32)     -> (significand: f32,   exponent: int) {
	f, e := frexp_f64(f64(x));
	return f32(f), e;
}
frexp_f32le :: proc(x: f32le) -> (significand: f32le, exponent: int) {
	f, e := frexp_f64(f64(x));
	return f32le(f), e;
}
frexp_f32be :: proc(x: f32be) -> (significand: f32be, exponent: int) {
	f, e := frexp_f64(f64(x));
	return f32be(f), e;
}
frexp_f64 :: proc(x: f64) -> (significand: f64, exponent: int) {
	switch {
	case x == 0:
		return 0, 0;
	case x < 0:
		significand, exponent = frexp(-x);
		return -significand, exponent;
	}
	ex := trunc(log2(x));
	exponent = int(ex);
	significand = x / pow(2.0, ex);
	if abs(significand) >= 1 {
		exponent += 1;
		significand /= 2;
	}
	if exponent == 1024 && significand == 0 {
		significand = 0.99999999999999988898;
	}
	return;
}
frexp_f64le :: proc(x: f64le) -> (significand: f64le, exponent: int) {
	f, e := frexp_f64(f64(x));
	return f64le(f), e;
}
frexp_f64be :: proc(x: f64be) -> (significand: f64be, exponent: int) {
	f, e := frexp_f64(f64(x));
	return f64be(f), e;
}
frexp       :: proc{
	frexp_f16, frexp_f16le, frexp_f16be,
	frexp_f32, frexp_f32le, frexp_f32be,
	frexp_f64, frexp_f64le, frexp_f64be, 
};




binomial :: proc(n, k: int) -> int {
	switch {
	case k <= 0:  return 1;
	case 2*k > n: return binomial(n, n-k);
	}

	b := n;
	for i in 2..<k {
		b = (b * (n+1-i))/i;
	}
	return b;
}

factorial :: proc(n: int) -> int {
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
		};
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
		};
	}

	assert(n >= 0, "parameter must not be negative");
	assert(n < len(table), "parameter is too large to lookup in the table");
	return table[n];
}

classify_f16   :: proc(x: f16)   -> Float_Class {
	switch {
	case x == 0:
		i := transmute(i16)x;
		if i < 0 {
			return .Neg_Zero;
		}
		return .Zero;
	case x*0.5 == x:
		if x < 0 {
			return .Neg_Inf;
		}
		return .Inf;
	case !(x == x):
		return .NaN;
	}

	u := transmute(u16)x;
	exp := int(u>>10) & (1<<5 - 1);
	if exp == 0 {
		return .Subnormal;
	}
	return .Normal;
}
classify_f16le :: proc(x: f16le) -> Float_Class { return #force_inline classify_f16(f16(x)); }
classify_f16be :: proc(x: f16be) -> Float_Class { return #force_inline classify_f16(f16(x)); }
classify_f32   :: proc(x: f32)   -> Float_Class {
	switch {
	case x == 0:
		i := transmute(i32)x;
		if i < 0 {
			return .Neg_Zero;
		}
		return .Zero;
	case x*0.5 == x:
		if x < 0 {
			return .Neg_Inf;
		}
		return .Inf;
	case !(x == x):
		return .NaN;
	}

	u := transmute(u32)x;
	exp := int(u>>23) & (1<<8 - 1);
	if exp == 0 {
		return .Subnormal;
	}
	return .Normal;
}
classify_f32le :: proc(x: f32le) -> Float_Class { return #force_inline classify_f32(f32(x)); }
classify_f32be :: proc(x: f32be) -> Float_Class { return #force_inline classify_f32(f32(x)); }
classify_f64   :: proc(x: f64)   -> Float_Class {
	switch {
	case x == 0:
		i := transmute(i64)x;
		if i < 0 {
			return .Neg_Zero;
		}
		return .Zero;
	case x*0.5 == x:
		if x < 0 {
			return .Neg_Inf;
		}
		return .Inf;
	case !(x == x):
		return .NaN;
	}
	u := transmute(u64)x;
	exp := int(u>>52) & (1<<11 - 1);
	if exp == 0 {
		return .Subnormal;
	}
	return .Normal;
}
classify_f64le :: proc(x: f64le) -> Float_Class { return #force_inline classify_f64(f64(x)); }
classify_f64be :: proc(x: f64be) -> Float_Class { return #force_inline classify_f64(f64(x)); }
classify       :: proc{
	classify_f16, classify_f16le, classify_f16be,
	classify_f32, classify_f32le, classify_f32be,
	classify_f64, classify_f64le, classify_f64be,
};

is_nan_f16   :: proc(x: f16)   -> bool { return classify(x) == .NaN; }
is_nan_f16le :: proc(x: f16le) -> bool { return classify(x) == .NaN; }
is_nan_f16be :: proc(x: f16be) -> bool { return classify(x) == .NaN; }
is_nan_f32   :: proc(x: f32)   -> bool { return classify(x) == .NaN; }
is_nan_f32le :: proc(x: f32le) -> bool { return classify(x) == .NaN; }
is_nan_f32be :: proc(x: f32be) -> bool { return classify(x) == .NaN; }
is_nan_f64   :: proc(x: f64)   -> bool { return classify(x) == .NaN; }
is_nan_f64le :: proc(x: f64le) -> bool { return classify(x) == .NaN; }
is_nan_f64be :: proc(x: f64be) -> bool { return classify(x) == .NaN; }
is_nan       :: proc{
	is_nan_f16, is_nan_f16le, is_nan_f16be,
	is_nan_f32, is_nan_f32le, is_nan_f32be,
	is_nan_f64, is_nan_f64le, is_nan_f64be,
};

// is_inf reports whether f is an infinity, according to sign.
// If sign > 0, is_inf reports whether f is positive infinity.
// If sign < 0, is_inf reports whether f is negative infinity.
// If sign == 0, is_inf reports whether f is either infinity.
is_inf_f16 :: proc(x: f16, sign: int = 0) -> bool {
	class := classify(abs(x));
	switch {
	case sign > 0:
		return class == .Inf;
	case sign < 0:
		return class == .Neg_Inf;
	}
	return class == .Inf || class == .Neg_Inf;
}
is_inf_f16le :: proc(x: f16le, sign: int = 0) -> bool {
	return #force_inline is_inf_f16(f16(x), sign);
}
is_inf_f16be :: proc(x: f16be, sign: int = 0) -> bool {
	return #force_inline is_inf_f16(f16(x), sign);
}

is_inf_f32 :: proc(x: f32, sign: int = 0) -> bool {
	class := classify(abs(x));
	switch {
	case sign > 0:
		return class == .Inf;
	case sign < 0:
		return class == .Neg_Inf;
	}
	return class == .Inf || class == .Neg_Inf;
}
is_inf_f32le :: proc(x: f32le, sign: int = 0) -> bool {
	return #force_inline is_inf_f32(f32(x), sign);
}
is_inf_f32be :: proc(x: f32be, sign: int = 0) -> bool {
	return #force_inline is_inf_f32(f32(x), sign);
}

is_inf_f64 :: proc(x: f64, sign: int = 0) -> bool {
	class := classify(abs(x));
	switch {
	case sign > 0:
		return class == .Inf;
	case sign < 0:
		return class == .Neg_Inf;
	}
	return class == .Inf || class == .Neg_Inf;
}
is_inf_f64le :: proc(x: f64le, sign: int = 0) -> bool {
	return #force_inline is_inf_f64(f64(x), sign);
}
is_inf_f64be :: proc(x: f64be, sign: int = 0) -> bool {
	return #force_inline is_inf_f64(f64(x), sign);
}
is_inf :: proc{
	is_inf_f16, is_inf_f16le, is_inf_f16be,
	is_inf_f32, is_inf_f32le, is_inf_f32be,
	is_inf_f64, is_inf_f64le, is_inf_f64be,
};

inf_f16   :: proc(sign: int) -> f16 {
	return f16(inf_f64(sign));
}
inf_f16le :: proc(sign: int) -> f16le {
	return f16le(inf_f64(sign));
}
inf_f16be :: proc(sign: int) -> f16be {
	return f16be(inf_f64(sign));
}
inf_f32   :: proc(sign: int) -> f32 {
	return f32(inf_f64(sign));
}
inf_f32le :: proc(sign: int) -> f32le {
	return f32le(inf_f64(sign));
}
inf_f32be :: proc(sign: int) -> f32be {
	return f32be(inf_f64(sign));
}
inf_f64   :: proc(sign: int) -> f64 {
	v: u64;
	if sign >= 0 {
		v = 0x7ff00000_00000000;
	} else {
		v = 0xfff00000_00000000;
	}
	return transmute(f64)v;
}
inf_f64le :: proc(sign: int) -> f64le {
	return f64le(inf_f64(sign));
}
inf_f64be :: proc(sign: int) -> f64be {
	return f64be(inf_f64(sign));
}

nan_f16   :: proc() -> f16 {
	return f16(nan_f64());
}
nan_f16le :: proc() -> f16le {
	return f16le(nan_f64());
}
nan_f16be :: proc() -> f16be {
	return f16be(nan_f64());
}
nan_f32   :: proc() -> f32 {
	return f32(nan_f64());
}
nan_f32le :: proc() -> f32le {
	return f32le(nan_f64());
}
nan_f32be :: proc() -> f32be {
	return f32be(nan_f64());
}
nan_f64   :: proc() -> f64 {
	v: u64 = 0x7ff80000_00000001;
	return transmute(f64)v;
}
nan_f64le :: proc() -> f64le {
	return f64le(nan_f64());
}
nan_f64be :: proc() -> f64be {
	return f64be(nan_f64());
}

is_power_of_two :: proc(x: int) -> bool {
	return x > 0 && (x & (x-1)) == 0;
}

next_power_of_two :: proc(x: int) -> int {
	k := x -1;
	when size_of(int) == 8 {
		k = k | (k >> 32);
	}
	k = k | (k >> 16);
	k = k | (k >> 8);
	k = k | (k >> 4);
	k = k | (k >> 2);
	k = k | (k >> 1);
	k += 1 + int(x <= 0);
	return k;
}

sum :: proc(x: $T/[]$E) -> (res: E)
	where intrinsics.type_is_numeric(E) {
	for i in x {
		res += i;
	}
	return;
}

prod :: proc(x: $T/[]$E) -> (res: E)
	where intrinsics.type_is_numeric(E) {
	for i in x {
		res *= i;
	}
	return;
}

cumsum_inplace :: proc(x: $T/[]$E) -> T
	where intrinsics.type_is_numeric(E) {
	for i in 1..<len(x) {
		x[i] = x[i-1] + x[i];
	}
}


cumsum :: proc(dst, src: $T/[]$E) -> T
	where intrinsics.type_is_numeric(E) {
	N := min(len(dst), len(src));
	if N > 0 {
		dst[0] = src[0];
		for i in 1..<N {
			dst[i] = dst[i-1] + src[i];
		}
	}
	return dst[:N];
}


atan2_f16   :: proc(y, x: f16)   -> f16 {
	// TODO(bill): Better atan2_f16
	return f16(atan2_f64(f64(y), f64(x)));
}
atan2_f16le :: proc(y, x: f16le) -> f16le {
	// TODO(bill): Better atan2_f16
	return f16le(atan2_f64(f64(y), f64(x)));
}
atan2_f16be :: proc(y, x: f16be) -> f16be {
	// TODO(bill): Better atan2_f16
	return f16be(atan2_f64(f64(y), f64(x)));
}
atan2_f32 :: proc(y, x: f32)     -> f32 {
	// TODO(bill): Better atan2_f32
	return f32(atan2_f64(f64(y), f64(x)));
}
atan2_f32le :: proc(y, x: f32le) -> f32le {
	// TODO(bill): Better atan2_f32
	return f32le(atan2_f64(f64(y), f64(x)));
}
atan2_f32be :: proc(y, x: f32be) -> f32be {
	// TODO(bill): Better atan2_f32
	return f32be(atan2_f64(f64(y), f64(x)));
}

atan2_f64 :: proc(y, x: f64) -> f64 {
	// TODO(bill): Faster atan2_f64 if possible

	// The original C code:
	//   Stephen L. Moshier
	//   moshier@na-net.ornl.gov

	NAN :: 0h7fff_ffff_ffff_ffff;
	INF :: 0h7FF0_0000_0000_0000;
	PI  :: 0h4009_21fb_5444_2d18;

	atan :: proc(x: f64) -> f64 {
		if x == 0 {
			return x;
		}
		if x > 0 {
			return s_atan(x);
		}
		return -s_atan(-x);
	}
	// s_atan reduces its argument (known to be positive) to the range [0, 0.66] and calls x_atan.
	s_atan :: proc(x: f64) -> f64 {
		MORE_BITS :: 6.123233995736765886130e-17; // pi/2 = PIO2 + MORE_BITS
		TAN3PI08  :: 2.41421356237309504880;      // tan(3*pi/8)
		if x <= 0.66 {
			return x_atan(x);
		}
		if x > TAN3PI08 {
			return PI/2 - x_atan(1/x) + MORE_BITS;
		}
		return PI/4 + x_atan((x-1)/(x+1)) + 0.5*MORE_BITS;
	}
	// x_atan evaluates a series valid in the range [0, 0.66].
	x_atan :: proc(x: f64) -> f64 {
		P0 :: -8.750608600031904122785e-01;
		P1 :: -1.615753718733365076637e+01;
		P2 :: -7.500855792314704667340e+01;
		P3 :: -1.228866684490136173410e+02;
		P4 :: -6.485021904942025371773e+01;
		Q0 :: +2.485846490142306297962e+01;
		Q1 :: +1.650270098316988542046e+02;
		Q2 :: +4.328810604912902668951e+02;
		Q3 :: +4.853903996359136964868e+02;
		Q4 :: +1.945506571482613964425e+02;

		z := x * x;
		z = z * ((((P0*z+P1)*z+P2)*z+P3)*z + P4) / (((((z+Q0)*z+Q1)*z+Q2)*z+Q3)*z + Q4);
		z = x*z + x;
		return z;
	}

	switch {
	case is_nan(y) || is_nan(x):
		return NAN;
	case y == 0:
		if x >= 0 && !sign_bit(x) {
			return copy_sign(0.0, y);
		}
		return copy_sign(PI, y);
	case x == 0:
		return copy_sign(PI*0.5, y);
	case is_inf(x, 0):
		if is_inf(x, 1) {
			if is_inf(y, 0) {
				return copy_sign(PI*0.25, y);
			}
			return copy_sign(0, y);
		}
		if is_inf(y, 0) {
			return copy_sign(PI*0.75, y);
		}
		return copy_sign(PI, y);
	case is_inf(y, 0):
		return copy_sign(PI*0.5, y);
	}

	q := atan(y / x);
	if x < 0 {
		if q <= 0 {
			return q + PI;
		}
		return q - PI;
	}
	return q;
}
atan2_f64le :: proc(y, x: f64le) -> f64le {
	// TODO(bill): Better atan2_f32
	return f64le(atan2_f64(f64(y), f64(x)));
}
atan2_f64be :: proc(y, x: f64be) -> f64be {
	// TODO(bill): Better atan2_f32
	return f64be(atan2_f64(f64(y), f64(x)));
}

atan2 :: proc{
	atan2_f16, atan2_f16le, atan2_f16be,
	atan2_f32, atan2_f32le, atan2_f32be,
	atan2_f64, atan2_f64le, atan2_f64be,
};

atan :: proc(x: $T) -> T where intrinsics.type_is_float(T) {
	return atan2(x, 1);
}

asin :: proc(x: $T) -> T where intrinsics.type_is_float(T) {
	return atan2(x, 1 + sqrt(1 - x*x));
}

acos :: proc(x: $T) -> T where intrinsics.type_is_float(T) {
	return 2 * atan2(sqrt(1 - x), sqrt(1 + x));
}

sinh :: proc(x: $T) -> T where intrinsics.type_is_float(T) {
	return (exp(x) - exp(-x))*0.5;
}

cosh :: proc(x: $T) -> T where intrinsics.type_is_float(T) {
	return (exp(x) + exp(-x))*0.5;
}

tanh :: proc(x: $T) -> T where intrinsics.type_is_float(T) {
	t := exp(2*x);
	return (t - 1) / (t + 1);
}

F16_DIG        :: 3;
F16_EPSILON    :: 0.00097656;
F16_GUARD      :: 0;
F16_MANT_DIG   :: 11;
F16_MAX        :: 65504.0;
F16_MAX_10_EXP :: 4;
F16_MAX_EXP    :: 15;
F16_MIN        :: 6.10351562e-5;
F16_MIN_10_EXP :: -4;
F16_MIN_EXP    :: -14;
F16_NORMALIZE  :: 0;
F16_RADIX      :: 2;
F16_ROUNDS     :: 1;


F32_DIG        :: 6;
F32_EPSILON    :: 1.192092896e-07;
F32_GUARD      :: 0;
F32_MANT_DIG   :: 24;
F32_MAX        :: 3.402823466e+38;
F32_MAX_10_EXP :: 38;
F32_MAX_EXP    :: 128;
F32_MIN        :: 1.175494351e-38;
F32_MIN_10_EXP :: -37;
F32_MIN_EXP    :: -125;
F32_NORMALIZE  :: 0;
F32_RADIX      :: 2;
F32_ROUNDS     :: 1;

F64_DIG        :: 15;                       // # of decimal digits of precision
F64_EPSILON    :: 2.2204460492503131e-016;  // smallest such that 1.0+F64_EPSILON != 1.0
F64_MANT_DIG   :: 53;                       // # of bits in mantissa
F64_MAX        :: 1.7976931348623158e+308;  // max value
F64_MAX_10_EXP :: 308;                      // max decimal exponent
F64_MAX_EXP    :: 1024;                     // max binary exponent
F64_MIN        :: 2.2250738585072014e-308;  // min positive value
F64_MIN_10_EXP :: -307;                     // min decimal exponent
F64_MIN_EXP    :: -1021;                    // min binary exponent
F64_RADIX      :: 2;                        // exponent radix
F64_ROUNDS     :: 1;                        // addition rounding: near
