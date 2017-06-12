const (
	TAU          = 6.28318530717958647692528676655900576;
	PI           = 3.14159265358979323846264338327950288;
	ONE_OVER_TAU = 0.636619772367581343075535053490057448;
	ONE_OVER_PI  = 0.159154943091895335768883763372514362;

	E            = 2.71828182845904523536;
	SQRT_TWO     = 1.41421356237309504880168872420969808;
	SQRT_THREE   = 1.73205080756887729352744634150587236;
	SQRT_FIVE    = 2.23606797749978969640917366873127623;

	LOG_TWO      = 0.693147180559945309417232121458176568;
	LOG_TEN      = 2.30258509299404568401799145468436421;

	EPSILON      = 1.19209290e-7;

	τ = TAU;
	π = PI;
)
type (
	Vec2 [vector 2]f32;
	Vec3 [vector 3]f32;
	Vec4 [vector 4]f32;

// Column major
	Mat2 [2][2]f32;
	Mat3 [3][3]f32;
	Mat4 [4][4]f32;

	Complex complex64;
)

proc sqrt(x: f32) -> f32 #foreign __llvm_core "llvm.sqrt.f32";
proc sqrt(x: f64) -> f64 #foreign __llvm_core "llvm.sqrt.f64";

proc sin (θ: f32) -> f32 #foreign __llvm_core "llvm.sin.f32";
proc sin (θ: f64) -> f64 #foreign __llvm_core "llvm.sin.f64";

proc cos (θ: f32) -> f32 #foreign __llvm_core "llvm.cos.f32";
proc cos (θ: f64) -> f64 #foreign __llvm_core "llvm.cos.f64";

proc tan (θ: f32) -> f32 #inline { return sin(θ)/cos(θ); }
proc tan (θ: f64) -> f64 #inline { return sin(θ)/cos(θ); }

proc pow (x, power: f32) -> f32 #foreign __llvm_core "llvm.pow.f32";
proc pow (x, power: f64) -> f64 #foreign __llvm_core "llvm.pow.f64";


proc lerp  (a, b, t: f32) -> (x: f32) { return a*(1-t) + b*t; }
proc lerp  (a, b, t: f64) -> (x: f64) { return a*(1-t) + b*t; }
proc unlerp(a, b, x: f32) -> (t: f32) { return (x-a)/(b-a); }
proc unlerp(a, b, x: f64) -> (t: f64) { return (x-a)/(b-a); }


proc sign(x: f32) -> f32 { return x >= 0 ? +1 : -1; }
proc sign(x: f64) -> f64 { return x >= 0 ? +1 : -1; }

proc fmuladd(a, b, c: f32) -> f32 #foreign __llvm_core "llvm.fmuladd.f32";
proc fmuladd(a, b, c: f64) -> f64 #foreign __llvm_core "llvm.fmuladd.f64";


proc copy_sign(x, y: f32) -> f32 {
	var ix = transmute(u32, x);
	var iy = transmute(u32, y);
	ix &= 0x7fff_ffff;
	ix |= iy & 0x8000_0000;
	return transmute(f32, ix);
}

proc copy_sign(x, y: f64) -> f64 {
	var ix = transmute(u64, x);
	var iy = transmute(u64, y);
	ix &= 0x7fff_ffff_ffff_ff;
	ix |= iy & 0x8000_0000_0000_0000;
	return transmute(f64, ix);
}

proc round    (x: f32) -> f32 { return x >= 0 ? floor(x + 0.5) : ceil(x - 0.5); }
proc round    (x: f64) -> f64 { return x >= 0 ? floor(x + 0.5) : ceil(x - 0.5); }

proc floor    (x: f32) -> f32 { return x >= 0 ? f32(i64(x)) : f32(i64(x-0.5)); } // TODO: Get accurate versions
proc floor    (x: f64) -> f64 { return x >= 0 ? f64(i64(x)) : f64(i64(x-0.5)); } // TODO: Get accurate versions

proc ceil     (x: f32) -> f32 { return x <  0 ? f32(i64(x)) : f32(i64(x+1)); } // TODO: Get accurate versions
proc ceil     (x: f64) -> f64 { return x <  0 ? f64(i64(x)) : f64(i64(x+1)); } // TODO: Get accurate versions

proc remainder(x, y: f32) -> f32 { return x - round(x/y) * y; }
proc remainder(x, y: f64) -> f64 { return x - round(x/y) * y; }

proc mod(x, y: f32) -> f32 {
	y = abs(y);
	var result = remainder(abs(x), y);
	if sign(result) < 0 {
		result += y;
	}
	return copy_sign(result, x);
}
proc mod(x, y: f64) -> f64 {
	y = abs(y);
	var result = remainder(abs(x), y);
	if sign(result) < 0 {
		result += y;
	}
	return copy_sign(result, x);
}


proc to_radians(degrees: f32) -> f32 { return degrees * TAU / 360; }
proc to_degrees(radians: f32) -> f32 { return radians * 360 / TAU; }



proc dot(a, b: Vec2) -> f32 { var c = a*b; return c.x + c.y; }
proc dot(a, b: Vec3) -> f32 { var c = a*b; return c.x + c.y + c.z; }
proc dot(a, b: Vec4) -> f32 { var c = a*b; return c.x + c.y + c.z + c.w; }

proc cross(x, y: Vec3) -> Vec3 {
	var a = swizzle(x, 1, 2, 0) * swizzle(y, 2, 0, 1);
	var b = swizzle(x, 2, 0, 1) * swizzle(y, 1, 2, 0);
	return a - b;
}


proc mag(v: Vec2) -> f32 { return sqrt(dot(v, v)); }
proc mag(v: Vec3) -> f32 { return sqrt(dot(v, v)); }
proc mag(v: Vec4) -> f32 { return sqrt(dot(v, v)); }

proc norm(v: Vec2) -> Vec2 { return v / mag(v); }
proc norm(v: Vec3) -> Vec3 { return v / mag(v); }
proc norm(v: Vec4) -> Vec4 { return v / mag(v); }

proc norm0(v: Vec2) -> Vec2 {
	var m = mag(v);
	if m == 0 {
		return 0;
	}
	return v / m;
}

proc norm0(v: Vec3) -> Vec3 {
	var m = mag(v);
	if m == 0 {
		return 0;
	}
	return v / m;
}

proc norm0(v: Vec4) -> Vec4 {
	var m = mag(v);
	if m == 0 {
		return 0;
	}
	return v / m;
}



proc mat4_identity() -> Mat4 {
	return Mat4{
		{1, 0, 0, 0},
		{0, 1, 0, 0},
		{0, 0, 1, 0},
		{0, 0, 0, 1},
	};
}

proc mat4_transpose(m: Mat4) -> Mat4 {
	for j in 0..<4 {
		for i in 0..<4 {
			m[i][j], m[j][i] = m[j][i], m[i][j];
		}
	}
	return m;
}

proc mul(a, b: Mat4) -> Mat4 {
	var c: Mat4;
	for j in 0..<4 {
		for i in 0..<4 {
			c[j][i] = a[0][i]*b[j][0] +
			          a[1][i]*b[j][1] +
			          a[2][i]*b[j][2] +
			          a[3][i]*b[j][3];
		}
	}
	return c;
}

proc mul(m: Mat4, v: Vec4) -> Vec4 {
	return Vec4{
		m[0][0]*v.x + m[1][0]*v.y + m[2][0]*v.z + m[3][0]*v.w,
		m[0][1]*v.x + m[1][1]*v.y + m[2][1]*v.z + m[3][1]*v.w,
		m[0][2]*v.x + m[1][2]*v.y + m[2][2]*v.z + m[3][2]*v.w,
		m[0][3]*v.x + m[1][3]*v.y + m[2][3]*v.z + m[3][3]*v.w,
	};
}

proc inverse(m: Mat4) -> Mat4 {
	var o: Mat4;

	var sf00 = m[2][2] * m[3][3] - m[3][2] * m[2][3];
	var sf01 = m[2][1] * m[3][3] - m[3][1] * m[2][3];
	var sf02 = m[2][1] * m[3][2] - m[3][1] * m[2][2];
	var sf03 = m[2][0] * m[3][3] - m[3][0] * m[2][3];
	var sf04 = m[2][0] * m[3][2] - m[3][0] * m[2][2];
	var sf05 = m[2][0] * m[3][1] - m[3][0] * m[2][1];
	var sf06 = m[1][2] * m[3][3] - m[3][2] * m[1][3];
	var sf07 = m[1][1] * m[3][3] - m[3][1] * m[1][3];
	var sf08 = m[1][1] * m[3][2] - m[3][1] * m[1][2];
	var sf09 = m[1][0] * m[3][3] - m[3][0] * m[1][3];
	var sf10 = m[1][0] * m[3][2] - m[3][0] * m[1][2];
	var sf11 = m[1][1] * m[3][3] - m[3][1] * m[1][3];
	var sf12 = m[1][0] * m[3][1] - m[3][0] * m[1][1];
	var sf13 = m[1][2] * m[2][3] - m[2][2] * m[1][3];
	var sf14 = m[1][1] * m[2][3] - m[2][1] * m[1][3];
	var sf15 = m[1][1] * m[2][2] - m[2][1] * m[1][2];
	var sf16 = m[1][0] * m[2][3] - m[2][0] * m[1][3];
	var sf17 = m[1][0] * m[2][2] - m[2][0] * m[1][2];
	var sf18 = m[1][0] * m[2][1] - m[2][0] * m[1][1];

	o[0][0] = +(m[1][1] * sf00 - m[1][2] * sf01 + m[1][3] * sf02);
	o[0][1] = -(m[1][0] * sf00 - m[1][2] * sf03 + m[1][3] * sf04);
	o[0][2] = +(m[1][0] * sf01 - m[1][1] * sf03 + m[1][3] * sf05);
	o[0][3] = -(m[1][0] * sf02 - m[1][1] * sf04 + m[1][2] * sf05);

	o[1][0] = -(m[0][1] * sf00 - m[0][2] * sf01 + m[0][3] * sf02);
	o[1][1] = +(m[0][0] * sf00 - m[0][2] * sf03 + m[0][3] * sf04);
	o[1][2] = -(m[0][0] * sf01 - m[0][1] * sf03 + m[0][3] * sf05);
	o[1][3] = +(m[0][0] * sf02 - m[0][1] * sf04 + m[0][2] * sf05);

	o[2][0] = +(m[0][1] * sf06 - m[0][2] * sf07 + m[0][3] * sf08);
	o[2][1] = -(m[0][0] * sf06 - m[0][2] * sf09 + m[0][3] * sf10);
	o[2][2] = +(m[0][0] * sf11 - m[0][1] * sf09 + m[0][3] * sf12);
	o[2][3] = -(m[0][0] * sf08 - m[0][1] * sf10 + m[0][2] * sf12);

	o[3][0] = -(m[0][1] * sf13 - m[0][2] * sf14 + m[0][3] * sf15);
	o[3][1] = +(m[0][0] * sf13 - m[0][2] * sf16 + m[0][3] * sf17);
	o[3][2] = -(m[0][0] * sf14 - m[0][1] * sf16 + m[0][3] * sf18);
	o[3][3] = +(m[0][0] * sf15 - m[0][1] * sf17 + m[0][2] * sf18);

	var ood = 1.0 / (m[0][0] * o[0][0] +
	              m[0][1] * o[0][1] +
	              m[0][2] * o[0][2] +
	              m[0][3] * o[0][3]);

	o[0][0] *= ood;
	o[0][1] *= ood;
	o[0][2] *= ood;
	o[0][3] *= ood;
	o[1][0] *= ood;
	o[1][1] *= ood;
	o[1][2] *= ood;
	o[1][3] *= ood;
	o[2][0] *= ood;
	o[2][1] *= ood;
	o[2][2] *= ood;
	o[2][3] *= ood;
	o[3][0] *= ood;
	o[3][1] *= ood;
	o[3][2] *= ood;
	o[3][3] *= ood;

	return o;
}


proc mat4_translate(v: Vec3) -> Mat4 {
	var m = mat4_identity();
	m[3][0] = v.x;
	m[3][1] = v.y;
	m[3][2] = v.z;
	m[3][3] = 1;
	return m;
}

proc mat4_rotate(v: Vec3, angle_radians: f32) -> Mat4 {
	var c = cos(angle_radians);
	var s = sin(angle_radians);

	var a = norm(v);
	var t = a * (1-c);

	var rot = mat4_identity();

	rot[0][0] = c + t.x*a.x;
	rot[0][1] = 0 + t.x*a.y + s*a.z;
	rot[0][2] = 0 + t.x*a.z - s*a.y;
	rot[0][3] = 0;

	rot[1][0] = 0 + t.y*a.x - s*a.z;
	rot[1][1] = c + t.y*a.y;
	rot[1][2] = 0 + t.y*a.z + s*a.x;
	rot[1][3] = 0;

	rot[2][0] = 0 + t.z*a.x + s*a.y;
	rot[2][1] = 0 + t.z*a.y - s*a.x;
	rot[2][2] = c + t.z*a.z;
	rot[2][3] = 0;

	return rot;
}

proc scale(m: Mat4, v: Vec3) -> Mat4 {
	m[0][0] *= v.x;
	m[1][1] *= v.y;
	m[2][2] *= v.z;
	return m;
}

proc scale(m: Mat4, s: f32) -> Mat4 {
	m[0][0] *= s;
	m[1][1] *= s;
	m[2][2] *= s;
	return m;
}


proc look_at(eye, centre, up: Vec3) -> Mat4 {
	var f = norm(centre - eye);
	var s = norm(cross(f, up));
	var u = cross(s, f);

	return Mat4{
		{+s.x, +u.x, -f.x, 0},
		{+s.y, +u.y, -f.y, 0},
		{+s.z, +u.z, -f.z, 0},
		{-dot(s, eye), -dot(u, eye), dot(f, eye), 1},
	};
}

proc perspective(fovy, aspect, near, far: f32) -> Mat4 {
	var m: Mat4;
	var tan_half_fovy = tan(0.5 * fovy);
	m[0][0] = 1.0 / (aspect*tan_half_fovy);
	m[1][1] = 1.0 / (tan_half_fovy);
	m[2][2] = -(far + near) / (far - near);
	m[2][3] = -1.0;
	m[3][2] = -2.0*far*near / (far - near);
	return m;
}


proc ortho3d(left, right, bottom, top, near, far: f32) -> Mat4 {
	var m = mat4_identity();
	m[0][0] = +2.0 / (right - left);
	m[1][1] = +2.0 / (top - bottom);
	m[2][2] = -2.0 / (far - near);
	m[3][0] = -(right + left)   / (right - left);
	m[3][1] = -(top   + bottom) / (top   - bottom);
	m[3][2] = -(far + near) / (far - near);
	return m;
}





const F32_DIG        = 6;
const F32_EPSILON    = 1.192092896e-07;
const F32_GUARD      = 0;
const F32_MANT_DIG   = 24;
const F32_MAX        = 3.402823466e+38;
const F32_MAX_10_EXP = 38;
const F32_MAX_EXP    = 128;
const F32_MIN        = 1.175494351e-38;
const F32_MIN_10_EXP = -37;
const F32_MIN_EXP    = -125;
const F32_NORMALIZE  = 0;
const F32_RADIX      = 2;
const F32_ROUNDS     = 1;

const F64_DIG        = 15;                       // # of decimal digits of precision
const F64_EPSILON    = 2.2204460492503131e-016;  // smallest such that 1.0+F64_EPSILON != 1.0
const F64_MANT_DIG   = 53;                       // # of bits in mantissa
const F64_MAX        = 1.7976931348623158e+308;  // max value
const F64_MAX_10_EXP = 308;                      // max decimal exponent
const F64_MAX_EXP    = 1024;                     // max binary exponent
const F64_MIN        = 2.2250738585072014e-308;  // min positive value
const F64_MIN_10_EXP = -307;                     // min decimal exponent
const F64_MIN_EXP    = -1021;                    // min binary exponent
const F64_RADIX      = 2;                        // exponent radix
const F64_ROUNDS     = 1;                        // addition rounding: near
