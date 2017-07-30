TAU          :: 6.28318530717958647692528676655900576;
PI           :: 3.14159265358979323846264338327950288;
ONE_OVER_TAU :: 0.636619772367581343075535053490057448;
ONE_OVER_PI  :: 0.159154943091895335768883763372514362;

E            :: 2.71828182845904523536;
SQRT_TWO     :: 1.41421356237309504880168872420969808;
SQRT_THREE   :: 1.73205080756887729352744634150587236;
SQRT_FIVE    :: 2.23606797749978969640917366873127623;

LOG_TWO      :: 0.693147180559945309417232121458176568;
LOG_TEN      :: 2.30258509299404568401799145468436421;

EPSILON      :: 1.19209290e-7;

τ :: TAU;
π :: PI;

Vec2 :: [vector 2]f32;
Vec3 :: [vector 3]f32;
Vec4 :: [vector 4]f32;

// Column major
Mat2 :: [2][2]f32;
Mat3 :: [3][3]f32;
Mat4 :: [4][4]f32;

Complex :: complex64;

foreign __llvm_core {
	sqrt    :: proc(x: f32) -> f32        #link_name "llvm.sqrt.f32" ---;
	sqrt    :: proc(x: f64) -> f64        #link_name "llvm.sqrt.f64" ---;

	sin     :: proc(θ: f32) -> f32        #link_name "llvm.sin.f32" ---;
	sin     :: proc(θ: f64) -> f64        #link_name "llvm.sin.f64" ---;

	cos     :: proc(θ: f32) -> f32        #link_name "llvm.cos.f32" ---;
	cos     :: proc(θ: f64) -> f64        #link_name "llvm.cos.f64" ---;

	pow     :: proc(x, power: f32) -> f32 #link_name "llvm.pow.f32" ---;
	pow     :: proc(x, power: f64) -> f64 #link_name "llvm.pow.f64" ---;

	fmuladd :: proc(a, b, c: f32) -> f32  #link_name "llvm.fmuladd.f32" ---;
	fmuladd :: proc(a, b, c: f64) -> f64  #link_name "llvm.fmuladd.f64" ---;
}

tan    :: proc(θ: f32) -> f32 #inline do return sin(θ)/cos(θ);
tan    :: proc(θ: f64) -> f64 #inline do return sin(θ)/cos(θ);


lerp   :: proc(a, b, t: f32) -> (x: f32) do return a*(1-t) + b*t;
lerp   :: proc(a, b, t: f64) -> (x: f64) do return a*(1-t) + b*t;
unlerp :: proc(a, b, x: f32) -> (t: f32) do return (x-a)/(b-a);
unlerp :: proc(a, b, x: f64) -> (t: f64) do return (x-a)/(b-a);


sign :: proc(x: f32) -> f32 { if x >= 0 do return +1; return -1; }
sign :: proc(x: f64) -> f64 { if x >= 0 do return +1; return -1; }



copy_sign :: proc(x, y: f32) -> f32 {
	ix := transmute(u32)x;
	iy := transmute(u32)y;
	ix &= 0x7fff_ffff;
	ix |= iy & 0x8000_0000;
	return transmute(f32)ix;
}

copy_sign :: proc(x, y: f64) -> f64 {
	ix := transmute(u64)x;
	iy := transmute(u64)y;
	ix &= 0x7fff_ffff_ffff_ff;
	ix |= iy & 0x8000_0000_0000_0000;
	return transmute(f64)ix;
}

round :: proc(x: f32) -> f32 { if x >= 0 do return floor(x + 0.5); return ceil(x - 0.5); }
round :: proc(x: f64) -> f64 { if x >= 0 do return floor(x + 0.5); return ceil(x - 0.5); }

floor :: proc(x: f32) -> f32 { if x >= 0 do return f32(i64(x)); return f32(i64(x-0.5)); } // TODO: Get accurate versions
floor :: proc(x: f64) -> f64 { if x >= 0 do return f64(i64(x)); return f64(i64(x-0.5)); } // TODO: Get accurate versions

ceil :: proc(x: f32) -> f32 { if x <  0 do return f32(i64(x)); return f32(i64(x+1));  }// TODO: Get accurate versions
ceil :: proc(x: f64) -> f64 { if x <  0 do return f64(i64(x)); return f64(i64(x+1));  }// TODO: Get accurate versions

remainder :: proc(x, y: f32) -> f32 do return x - round(x/y) * y;
remainder :: proc(x, y: f64) -> f64 do return x - round(x/y) * y;

mod :: proc(x, y: f32) -> f32 {
	result: f32;
	y = abs(y);
	result = remainder(abs(x), y);
	if sign(result) < 0 {
		result += y;
	}
	return copy_sign(result, x);
}
mod :: proc(x, y: f64) -> f64 {
	result: f64;
	y = abs(y);
	result = remainder(abs(x), y);
	if sign(result) < 0 {
		result += y;
	}
	return copy_sign(result, x);
}


to_radians :: proc(degrees: f32) -> f32 do return degrees * TAU / 360;
to_degrees :: proc(radians: f32) -> f32 do return radians * 360 / TAU;



dot :: proc(a, b: $T/[vector 2]$E) -> E { c := a*b; return c.x + c.y; }
dot :: proc(a, b: $T/[vector 3]$E) -> E { c := a*b; return c.x + c.y + c.z; }
dot :: proc(a, b: $T/[vector 4]$E) -> E { c := a*b; return c.x + c.y + c.z + c.w; }

cross :: proc(x, y: $T/[vector 3]$E) -> T {
	a := swizzle(x, 1, 2, 0) * swizzle(y, 2, 0, 1);
	b := swizzle(x, 2, 0, 1) * swizzle(y, 1, 2, 0);
	return T(a - b);
}


mag :: proc(v: $T/[vector 2]$E) -> E do return sqrt(dot(v, v));
mag :: proc(v: $T/[vector 3]$E) -> E do return sqrt(dot(v, v));
mag :: proc(v: $T/[vector 4]$E) -> E do return sqrt(dot(v, v));

norm :: proc(v: $T/[vector 2]$E) -> T do return v / mag(v);
norm :: proc(v: $T/[vector 3]$E) -> T do return v / mag(v);
norm :: proc(v: $T/[vector 4]$E) -> T do return v / mag(v);

norm0 :: proc(v: $T/[vector 2]$E) -> T {
	m := mag(v);
	if m == 0 do return 0;
	return v/m;
}

norm0 :: proc(v: $T/[vector 3]$E) -> T {
	m := mag(v);
	if m == 0 do return 0;
	return v/m;
}

norm0 :: proc(v: $T/[vector 4]$E) -> T {
	m := mag(v);
	if m == 0 do return 0;
	return v/m;
}



mat4_identity :: proc() -> Mat4 {
	return Mat4{
		{1, 0, 0, 0},
		{0, 1, 0, 0},
		{0, 0, 1, 0},
		{0, 0, 0, 1},
	};
}

mat4_transpose :: proc(m: Mat4) -> Mat4 {
	for j in 0..4 {
		for i in 0..4 {
			m[i][j], m[j][i] = m[j][i], m[i][j];
		}
	}
	return m;
}

mul :: proc(a, b: Mat4) -> Mat4 {
	c: Mat4;
	for j in 0..4 {
		for i in 0..4 {
			c[j][i] = a[0][i]*b[j][0] +
			          a[1][i]*b[j][1] +
			          a[2][i]*b[j][2] +
			          a[3][i]*b[j][3];
		}
	}
	return c;
}

mul :: proc(m: Mat4, v: Vec4) -> Vec4 {
	return Vec4{
		m[0][0]*v.x + m[1][0]*v.y + m[2][0]*v.z + m[3][0]*v.w,
		m[0][1]*v.x + m[1][1]*v.y + m[2][1]*v.z + m[3][1]*v.w,
		m[0][2]*v.x + m[1][2]*v.y + m[2][2]*v.z + m[3][2]*v.w,
		m[0][3]*v.x + m[1][3]*v.y + m[2][3]*v.z + m[3][3]*v.w,
	};
}

inverse :: proc(m: Mat4) -> Mat4 {
	o: Mat4;

	sf00 := m[2][2] * m[3][3] - m[3][2] * m[2][3];
	sf01 := m[2][1] * m[3][3] - m[3][1] * m[2][3];
	sf02 := m[2][1] * m[3][2] - m[3][1] * m[2][2];
	sf03 := m[2][0] * m[3][3] - m[3][0] * m[2][3];
	sf04 := m[2][0] * m[3][2] - m[3][0] * m[2][2];
	sf05 := m[2][0] * m[3][1] - m[3][0] * m[2][1];
	sf06 := m[1][2] * m[3][3] - m[3][2] * m[1][3];
	sf07 := m[1][1] * m[3][3] - m[3][1] * m[1][3];
	sf08 := m[1][1] * m[3][2] - m[3][1] * m[1][2];
	sf09 := m[1][0] * m[3][3] - m[3][0] * m[1][3];
	sf10 := m[1][0] * m[3][2] - m[3][0] * m[1][2];
	sf11 := m[1][1] * m[3][3] - m[3][1] * m[1][3];
	sf12 := m[1][0] * m[3][1] - m[3][0] * m[1][1];
	sf13 := m[1][2] * m[2][3] - m[2][2] * m[1][3];
	sf14 := m[1][1] * m[2][3] - m[2][1] * m[1][3];
	sf15 := m[1][1] * m[2][2] - m[2][1] * m[1][2];
	sf16 := m[1][0] * m[2][3] - m[2][0] * m[1][3];
	sf17 := m[1][0] * m[2][2] - m[2][0] * m[1][2];
	sf18 := m[1][0] * m[2][1] - m[2][0] * m[1][1];


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

	ood := 1.0 / (m[0][0] * o[0][0] +
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


mat4_translate :: proc(v: Vec3) -> Mat4 {
	m := mat4_identity();
	m[3][0] = v.x;
	m[3][1] = v.y;
	m[3][2] = v.z;
	m[3][3] = 1;
	return m;
}

mat4_rotate :: proc(v: Vec3, angle_radians: f32) -> Mat4 {
	c := cos(angle_radians);
	s := sin(angle_radians);

	a := norm(v);
	t := a * (1-c);

	rot := mat4_identity();

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

scale :: proc(m: Mat4, v: Vec3) -> Mat4 {
	m[0][0] *= v.x;
	m[1][1] *= v.y;
	m[2][2] *= v.z;
	return m;
}

scale :: proc(m: Mat4, s: f32) -> Mat4 {
	m[0][0] *= s;
	m[1][1] *= s;
	m[2][2] *= s;
	return m;
}


look_at :: proc(eye, centre, up: Vec3) -> Mat4 {
	f := norm(centre - eye);
	s := norm(cross(f, up));
	u := cross(s, f);

	return Mat4{
		{+s.x, +u.x, -f.x, 0},
		{+s.y, +u.y, -f.y, 0},
		{+s.z, +u.z, -f.z, 0},
		{-dot(s, eye), -dot(u, eye), dot(f, eye), 1},
	};
}

perspective :: proc(fovy, aspect, near, far: f32) -> Mat4 {
	m: Mat4;
	tan_half_fovy := tan(0.5 * fovy);

	m[0][0] = 1.0 / (aspect*tan_half_fovy);
	m[1][1] = 1.0 / (tan_half_fovy);
	m[2][2] = -(far + near) / (far - near);
	m[2][3] = -1.0;
	m[3][2] = -2.0*far*near / (far - near);
	return m;
}


ortho3d :: proc(left, right, bottom, top, near, far: f32) -> Mat4 {
	m := mat4_identity();
	m[0][0] = +2.0 / (right - left);
	m[1][1] = +2.0 / (top - bottom);
	m[2][2] = -2.0 / (far - near);
	m[3][0] = -(right + left)   / (right - left);
	m[3][1] = -(top   + bottom) / (top   - bottom);
	m[3][2] = -(far + near) / (far - near);
	return m;
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
