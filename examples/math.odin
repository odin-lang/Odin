MATH_TAU          :: 6.28318530717958647692528676655900576;
MATH_PI           :: 3.14159265358979323846264338327950288;
MATH_ONE_OVER_TAU :: 0.636619772367581343075535053490057448;
MATH_ONE_OVER_PI  :: 0.159154943091895335768883763372514362;

MATH_E            :: 2.71828182845904523536;
MATH_SQRT_TWO     :: 1.41421356237309504880168872420969808;
MATH_SQRT_THREE   :: 1.73205080756887729352744634150587236;
MATH_SQRT_FIVE    :: 2.23606797749978969640917366873127623;

MATH_LOG_TWO      :: 0.693147180559945309417232121458176568;
MATH_LOG_TEN      :: 2.30258509299404568401799145468436421;

MATH_EPSILON      :: 1.19209290e-7;

τ :: MATH_TAU;
π :: MATH_PI;

Vec2 :: type {2}f32;
Vec3 :: type {3}f32;
Vec4 :: type {4}f32;

Mat2 :: type  {4}f32;
Mat3 :: type  {9}f32;
Mat4 :: type {16}f32;


fsqrt    :: proc(x: f32) -> f32 #foreign "llvm.sqrt.f32"
fsin     :: proc(x: f32) -> f32 #foreign "llvm.sin.f32"
fcos     :: proc(x: f32) -> f32 #foreign "llvm.cos.f32"
flerp    :: proc(a, b, t: f32) -> f32 { return a*(1-t) + b*t; }
fclamp   :: proc(x, lower, upper: f32) -> f32 { return fmin(fmax(x, lower), upper); }
fclamp01 :: proc(x: f32) -> f32 { return fclamp(x, 0, 1); }
fabs     :: proc(x: f32) -> f32 { if x < 0 { x = -x; } return x; }
fsign    :: proc(x: f32) -> f32 { if x >= 0 { return +1; } return -1; }

fmin     :: proc(a, b: f32) -> f32 { if a < b { return a; } return b; }
fmax     :: proc(a, b: f32) -> f32 { if a > b { return a; } return b; }
fmin3    :: proc(a, b, c: f32) -> f32 { return fmin(fmin(a, b), c); }
fmax3    :: proc(a, b, c: f32) -> f32 { return fmax(fmax(a, b), c); }


copy_sign :: proc(x, y: f32) -> f32 {
	ix := x transmute u32;
	iy := y transmute u32;
	ix &= 0x7fffffff;
	ix |= iy & 0x80000000;
	return ix transmute f32;
}


round :: proc(x: f32) -> f32 {
	if x >= 0 {
		return floor(x + 0.5);
	}
	return ceil(x - 0.5);
}
floor :: proc(x: f32) -> f32 {
	if x >= 0 {
		return x as int as f32;
	}
	return (x-0.5) as int as f32;
}
ceil :: proc(x: f32) -> f32 {
	if x < 0 {
		return x as int as f32;
	}
	return ((x as int)+1) as f32;
}




remainder :: proc(x, y: f32) -> f32 {
	return x - round(x/y) * y;
}

fmod :: proc(x, y: f32) -> f32 {
	y = fabs(y);
	result := remainder(fabs(x), y);
	if fsign(result) < 0 {
		result += y;
	}
	return copy_sign(result, x);
}


to_radians :: proc(degrees: f32) -> f32 { return degrees * MATH_TAU / 360; }
to_degrees :: proc(radians: f32) -> f32 { return radians * 360 / MATH_TAU; }




dot2 :: proc(a, b: Vec2) -> f32 { c := a*b; return c[0] + c[1]; }
dot3 :: proc(a, b: Vec3) -> f32 { c := a*b; return c[0] + c[1] + c[2]; }
dot4 :: proc(a, b: Vec4) -> f32 { c := a*b; return c[0] + c[1] + c[2] + c[3]; }

cross :: proc(x, y: Vec3) -> Vec3 {
	a := swizzle(x, 1, 2, 0) * swizzle(y, 2, 0, 1);
	b := swizzle(x, 2, 0, 1) * swizzle(y, 1, 2, 0);
	return a - b;
}


vec2_mag :: proc(v: Vec2) -> f32 { return fsqrt(v 'dot2' v); }
vec3_mag :: proc(v: Vec3) -> f32 { return fsqrt(v 'dot3' v); }
vec4_mag :: proc(v: Vec4) -> f32 { return fsqrt(v 'dot4' v); }

vec2_norm :: proc(v: Vec2) -> Vec2 { return v / Vec2{vec2_mag(v)}; }
vec3_norm :: proc(v: Vec3) -> Vec3 { return v / Vec3{vec3_mag(v)}; }
vec4_norm :: proc(v: Vec4) -> Vec4 { return v / Vec4{vec4_mag(v)}; }

vec2_norm0 :: proc(v: Vec2) -> Vec2 {
	m := vec2_mag(v);
	if m == 0 {
		return Vec2{0};
	}
	return v / Vec2{m};
}

vec3_norm0 :: proc(v: Vec3) -> Vec3 {
	m := vec3_mag(v);
	if m == 0 {
		return Vec3{0};
	}
	return v / Vec3{m};
}

vec4_norm0 :: proc(v: Vec4) -> Vec4 {
	m := vec4_mag(v);
	if m == 0 {
		return Vec4{0};
	}
	return v / Vec4{m};
}


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

F64_DIG        :: 15;                      // # of decimal digits of precision
F64_EPSILON    :: 2.2204460492503131e-016; // smallest such that 1.0+F64_EPSILON != 1.0
F64_MANT_DIG   :: 53;                      // # of bits in mantissa
F64_MAX        :: 1.7976931348623158e+308; // max value
F64_MAX_10_EXP :: 308;                     // max decimal exponent
F64_MAX_EXP    :: 1024;                    // max binary exponent
F64_MIN        :: 2.2250738585072014e-308; // min positive value
F64_MIN_10_EXP :: -307;                    // min decimal exponent
F64_MIN_EXP    :: -1021;                   // min binary exponent
F64_RADIX      :: 2;                       // exponent radix
F64_ROUNDS     :: 1;                       // addition rounding: near
