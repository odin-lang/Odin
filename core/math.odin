TAU          :: 6.28318530717958647692528676655900576;
PI           :: 3.14159265358979323846264338327950288;

E            :: 2.71828182845904523536;
SQRT_TWO     :: 1.41421356237309504880168872420969808;
SQRT_THREE   :: 1.73205080756887729352744634150587236;
SQRT_FIVE    :: 2.23606797749978969640917366873127623;

LOG_TWO      :: 0.693147180559945309417232121458176568;
LOG_TEN      :: 2.30258509299404568401799145468436421;

EPSILON      :: 1.19209290e-7;

τ :: TAU;
π :: PI;

Vec2 :: distinct [2]f32;
Vec3 :: distinct [3]f32;
Vec4 :: distinct [4]f32;

// Column major
Mat2 :: distinct [2][2]f32;
Mat3 :: distinct [3][3]f32;
Mat4 :: distinct [4][4]f32;

Quat :: struct {x, y, z: f32, w: f32 = 1};

@(default_calling_convention="c")
foreign __llvm_core {
	@(link_name="llvm.sqrt.f32")
	sqrt_f32 :: proc(x: f32) -> f32 ---;
	@(link_name="llvm.sqrt.f64")
	sqrt_f64 :: proc(x: f64) -> f64 ---;

	@(link_name="llvm.sin.f32")
	sin_f32 :: proc(θ: f32) -> f32 ---;
	@(link_name="llvm.sin.f64")
	sin_f64 :: proc(θ: f64) -> f64 ---;

	@(link_name="llvm.cos.f32")
	cos_f32 :: proc(θ: f32) -> f32 ---;
	@(link_name="llvm.cos.f64")
	cos_f64 :: proc(θ: f64) -> f64 ---;

	@(link_name="llvm.pow.f32")
	pow_f32 :: proc(x, power: f32) -> f32 ---;
	@(link_name="llvm.pow.f64")
	pow_f64 :: proc(x, power: f64) -> f64 ---;

	@(link_name="llvm.fmuladd.f32")
	fmuladd_f32 :: proc(a, b, c: f32) -> f32 ---;
	@(link_name="llvm.fmuladd.f64")
	fmuladd_f64 :: proc(a, b, c: f64) -> f64 ---;

	@(link_name="llvm.log.f32")
	log_f32 :: proc(x: f32) -> f32 ---;
	@(link_name="llvm.log.f64")
	log_f64 :: proc(x: f64) -> f64 ---;
}

log :: proc[log_f32, log_f64];

tan_f32 :: proc "c" (θ: f32) -> f32 { return sin(θ)/cos(θ); }
tan_f64 :: proc "c" (θ: f64) -> f64 { return sin(θ)/cos(θ); }

lerp :: proc(a, b: $T, t: $E) -> (x: T) { return a*(1-t) + b*t; }

unlerp_f32 :: proc(a, b, x: f32) -> (t: f32) { return (x-a)/(b-a); }
unlerp_f64 :: proc(a, b, x: f64) -> (t: f64) { return (x-a)/(b-a); }


sign_f32 :: proc(x: f32) -> f32 { return x >= 0 ? +1 : -1; }
sign_f64 :: proc(x: f64) -> f64 { return x >= 0 ? +1 : -1; }

copy_sign_f32 :: proc(x, y: f32) -> f32 {
	ix := transmute(u32)x;
	iy := transmute(u32)y;
	ix &= 0x7fff_ffff;
	ix |= iy & 0x8000_0000;
	return transmute(f32)ix;
}

copy_sign_f64 :: proc(x, y: f64) -> f64 {
	ix := transmute(u64)x;
	iy := transmute(u64)y;
	ix &= 0x7fff_ffff_ffff_ff;
	ix |= iy & 0x8000_0000_0000_0000;
	return transmute(f64)ix;
}


sqrt      :: proc[sqrt_f32, sqrt_f64];
sin       :: proc[sin_f32, sin_f64];
cos       :: proc[cos_f32, cos_f64];
tan       :: proc[tan_f32, tan_f64];
pow       :: proc[pow_f32, pow_f64];
fmuladd   :: proc[fmuladd_f32, fmuladd_f64];
sign      :: proc[sign_f32, sign_f64];
copy_sign :: proc[copy_sign_f32, copy_sign_f64];


round_f32 :: proc(x: f32) -> f32 { return x >= 0 ? floor(x + 0.5) : ceil(x - 0.5); }
round_f64 :: proc(x: f64) -> f64 { return x >= 0 ? floor(x + 0.5) : ceil(x - 0.5); }
round :: proc[round_f32, round_f64];

floor_f32 :: proc(x: f32) -> f32 { return x >= 0 ? f32(i64(x)) : f32(i64(x-0.5)); } // TODO: Get accurate versions
floor_f64 :: proc(x: f64) -> f64 { return x >= 0 ? f64(i64(x)) : f64(i64(x-0.5)); } // TODO: Get accurate versions
floor :: proc[floor_f32, floor_f64];

ceil_f32 :: proc(x: f32) -> f32 { return x < 0 ? f32(i64(x)) : f32(i64(x+1)); }// TODO: Get accurate versions
ceil_f64 :: proc(x: f64) -> f64 { return x < 0 ? f64(i64(x)) : f64(i64(x+1)); }// TODO: Get accurate versions
ceil :: proc[ceil_f32, ceil_f64];

remainder_f32 :: proc(x, y: f32) -> f32 { return x - round(x/y) * y; }
remainder_f64 :: proc(x, y: f64) -> f64 { return x - round(x/y) * y; }
remainder :: proc[remainder_f32, remainder_f64];

mod_f32 :: proc(x, y: f32) -> f32 {
	result: f32;
	y = abs(y);
	result = remainder(abs(x), y);
	if sign(result) < 0 {
		result += y;
	}
	return copy_sign(result, x);
}
mod_f64 :: proc(x, y: f64) -> f64 {
	result: f64;
	y = abs(y);
	result = remainder(abs(x), y);
	if sign(result) < 0 {
		result += y;
	}
	return copy_sign(result, x);
}
mod :: proc[mod_f32, mod_f64];



to_radians :: proc(degrees: f32) -> f32 { return degrees * TAU / 360; }
to_degrees :: proc(radians: f32) -> f32 { return radians * 360 / TAU; }




mul :: proc[
	mat4_mul, mat4_mul_vec4,
	quat_mul, quat_mulf,
];

div :: proc[
	quat_div, quat_divf,
];

inverse :: proc[mat4_inverse, quat_inverse];
dot     :: proc[vec_dot, quat_dot];
cross   :: proc[cross2, cross3];

vec_dot :: proc(a, b: $T/[$N]$E) -> E {
	res: E;
	for i in 0..N {
		res += a[i] * b[i];
	}
	return res;
}

cross2 :: proc(a, b: $T/[2]$E) -> E {
	return a[0]*b[1] - a[1]*b[0];
}

cross3 :: proc(a, b: $T/[3]$E) -> T {
	i := swizzle(a, 1, 2, 0) * swizzle(b, 2, 0, 1);
	j := swizzle(a, 2, 0, 1) * swizzle(b, 1, 2, 0);
	return T(i - j);
}


length :: proc(v: $T/[$N]$E) -> E { return sqrt(dot(v, v)); }

norm :: proc(v: $T/[$N]$E) -> T { return v / length(v); }

norm0 :: proc(v: $T/[$N]$E) -> T {
	m := length(v);
	return m == 0 ? 0 : v/m;
}



identity :: proc(T: type/[$N][N]$E) -> T {
	m: T;
	for i in 0..N do m[i][i] = E(1);
	return m;
}

transpose :: proc(m: Mat4) -> Mat4 {
	for j in 0..4 {
		for i in 0..4 {
			m[i][j], m[j][i] = m[j][i], m[i][j];
		}
	}
	return m;
}

mat4_mul :: proc(a, b: Mat4) -> Mat4 {
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

mat4_mul_vec4 :: proc(m: Mat4, v: Vec4) -> Vec4 {
	return Vec4{
		m[0][0]*v[0] + m[1][0]*v[1] + m[2][0]*v[2] + m[3][0]*v[3],
		m[0][1]*v[0] + m[1][1]*v[1] + m[2][1]*v[2] + m[3][1]*v[3],
		m[0][2]*v[0] + m[1][2]*v[1] + m[2][2]*v[2] + m[3][2]*v[3],
		m[0][3]*v[0] + m[1][3]*v[1] + m[2][3]*v[2] + m[3][3]*v[3],
	};
}


mat4_inverse :: proc(m: Mat4) -> Mat4 {
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
	m := identity(Mat4);
	m[3][0] = v[0];
	m[3][1] = v[1];
	m[3][2] = v[2];
	m[3][3] = 1;
	return m;
}

mat4_rotate :: proc(v: Vec3, angle_radians: f32) -> Mat4 {
	c := cos(angle_radians);
	s := sin(angle_radians);

	a := norm(v);
	t := a * (1-c);

	rot := identity(Mat4);

	rot[0][0] = c + t[0]*a[0];
	rot[0][1] = 0 + t[0]*a[1] + s*a[2];
	rot[0][2] = 0 + t[0]*a[2] - s*a[1];
	rot[0][3] = 0;

	rot[1][0] = 0 + t[1]*a[0] - s*a[2];
	rot[1][1] = c + t[1]*a[1];
	rot[1][2] = 0 + t[1]*a[2] + s*a[0];
	rot[1][3] = 0;

	rot[2][0] = 0 + t[2]*a[0] + s*a[1];
	rot[2][1] = 0 + t[2]*a[1] - s*a[0];
	rot[2][2] = c + t[2]*a[2];
	rot[2][3] = 0;

	return rot;
}

scale_vec3 :: proc(m: Mat4, v: Vec3) -> Mat4 {
	m[0][0] *= v[0];
	m[1][1] *= v[1];
	m[2][2] *= v[2];
	return m;
}

scale_f32 :: proc(m: Mat4, s: f32) -> Mat4 {
	m[0][0] *= s;
	m[1][1] *= s;
	m[2][2] *= s;
	return m;
}

scale :: proc[scale_vec3, scale_f32];


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
	m := identity(Mat4);
	m[0][0] = +2.0 / (right - left);
	m[1][1] = +2.0 / (top - bottom);
	m[2][2] = -2.0 / (far - near);
	m[3][0] = -(right + left)   / (right - left);
	m[3][1] = -(top   + bottom) / (top   - bottom);
	m[3][2] = -(far + near) / (far - near);
	return m;
}


// Quaternion operations

conj :: proc(q: Quat) -> Quat {
	return Quat{-q.x, -q.y, -q.z, q.w};
}

quat_mul :: proc(q0, q1: Quat) -> Quat {
	d: Quat;
	d.x = q0.w * q1.x + q0.x * q1.w + q0.y * q1.z - q0.z * q1.y;
	d.y = q0.w * q1.y - q0.x * q1.z + q0.y * q1.w + q0.z * q1.x;
	d.z = q0.w * q1.z + q0.x * q1.y - q0.y * q1.x + q0.z * q1.w;
	d.w = q0.w * q1.w - q0.x * q1.x - q0.y * q1.y - q0.z * q1.z;
	return d;
}

quat_mulf :: proc(q: Quat, f: f32) -> Quat { return Quat{q.x*f, q.y*f, q.z*f, q.w*f}; }
quat_divf :: proc(q: Quat, f: f32) -> Quat { return Quat{q.x/f, q.y/f, q.z/f, q.w/f}; }

quat_div     :: proc(q0, q1: Quat) -> Quat { return mul(q0, quat_inverse(q1)); }
quat_inverse :: proc(q: Quat) -> Quat { return div(conj(q), dot(q, q)); }
quat_dot     :: proc(q0, q1: Quat) -> f32 { return q0.x*q1.x + q0.y*q1.y + q0.z*q1.z + q0.w*q1.w; }

quat_norm :: proc(q: Quat) -> Quat {
	m := sqrt(dot(q, q));
	return div(q, m);
}

axis_angle :: proc(axis: Vec3, angle_radians: f32) -> Quat {
	v := norm(axis) * sin(0.5*angle_radians);
	w := cos(0.5*angle_radians);
	return Quat{v.x, v.y, v.z, w};
}

euler_angles :: proc(pitch, yaw, roll: f32) -> Quat {
	p := axis_angle(Vec3{1, 0, 0}, pitch);
	y := axis_angle(Vec3{0, 1, 0}, yaw);
	r := axis_angle(Vec3{0, 0, 1}, roll);
	return mul(mul(y, p), r);
}

quat_to_mat4 :: proc(q: Quat) -> Mat4 {
	a := quat_norm(q);
	xx := a.x*a.x; yy := a.y*a.y; zz := a.z*a.z;
	xy := a.x*a.y; xz := a.x*a.z; yz := a.y*a.z;
	wx := a.w*a.x; wy := a.w*a.y; wz := a.w*a.z;

	m := identity(Mat4);

	m[0][0] = 1 - 2*(yy + zz);
	m[0][1] =     2*(xy + wz);
	m[0][2] =     2*(xz - wy);

	m[1][0] =     2*(xy - wz);
	m[1][1] = 1 - 2*(xx + zz);
	m[1][2] =     2*(yz + wx);

	m[2][0] =     2*(xz + wy);
	m[2][1] =     2*(yz - wx);
	m[2][2] = 1 - 2*(xx + yy);
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
