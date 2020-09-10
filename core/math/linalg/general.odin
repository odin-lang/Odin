package linalg

import "core:math"
import "intrinsics"

// Generic

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

RAD_PER_DEG :: TAU/360.0;
DEG_PER_RAD :: 360.0/TAU;



@private IS_NUMERIC :: intrinsics.type_is_numeric;
@private IS_QUATERNION :: intrinsics.type_is_quaternion;
@private IS_ARRAY :: intrinsics.type_is_array;
@private IS_FLOAT :: intrinsics.type_is_float;
@private BASE_TYPE :: intrinsics.type_base_type;
@private ELEM_TYPE :: intrinsics.type_elem_type;


vector_dot :: proc(a, b: $T/[$N]$E) -> (c: E) where IS_NUMERIC(E) {
	for i in 0..<N {
		c += a[i] * b[i];
	}
	return;
}
quaternion128_dot :: proc(a, b: $T/quaternion128) -> (c: f32) {
	return a.w*a.w + a.x*b.x + a.y*b.y + a.z*b.z;
}
quaternion256_dot :: proc(a, b: $T/quaternion256) -> (c: f64) {
	return a.w*a.w + a.x*b.x + a.y*b.y + a.z*b.z;
}

dot :: proc{vector_dot, quaternion128_dot, quaternion256_dot};

quaternion_inverse :: proc(q: $Q) -> Q where IS_QUATERNION(Q) {
	return conj(q) * quaternion(1.0/dot(q, q), 0, 0, 0);
}


vector_cross2 :: proc(a, b: $T/[2]$E) -> E where IS_NUMERIC(E) {
	return a[0]*b[1] - b[0]*a[1];
}

vector_cross3 :: proc(a, b: $T/[3]$E) -> (c: T) where IS_NUMERIC(E) {
	c[0] = a[1]*b[2] - b[1]*a[2];
	c[1] = a[2]*b[0] - b[2]*a[0];
	c[2] = a[0]*b[1] - b[0]*a[1];
	return;
}

quaternion_cross :: proc(q1, q2: $Q) -> (q3: Q) where IS_QUATERNION(Q) {
	q3.x = q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y;
	q3.y = q1.w * q2.y + q1.y * q2.w + q1.z * q2.x - q1.x * q2.z;
	q3.z = q1.w * q2.z + q1.z * q2.w + q1.x * q2.y - q1.y * q2.x;
	q3.w = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z;
	return;
}

vector_cross :: proc{vector_cross2, vector_cross3};
cross :: proc{vector_cross2, vector_cross3, quaternion_cross};

vector_normalize :: proc(v: $T/[$N]$E) -> T where IS_NUMERIC(E) {
	return v / length(v);
}
quaternion_normalize :: proc(q: $Q) -> Q where IS_QUATERNION(Q) {
	return q/abs(q);
}
normalize :: proc{vector_normalize, quaternion_normalize};

vector_normalize0 :: proc(v: $T/[$N]$E) -> T where IS_NUMERIC(E) {
	m := length(v);
	return 0 if m == 0 else v/m;
}
quaternion_normalize0 :: proc(q: $Q) -> Q  where IS_QUATERNION(Q) {
	m := abs(q);
	return 0 if m == 0 else q/m;
}
normalize0 :: proc{vector_normalize0, quaternion_normalize0};


vector_length :: proc(v: $T/[$N]$E) -> E where IS_NUMERIC(E) {
	return math.sqrt(dot(v, v));
}

vector_length2 :: proc(v: $T/[$N]$E) -> E where IS_NUMERIC(E) {
	return dot(v, v);
}

quaternion_length :: proc(q: $Q) -> Q where IS_QUATERNION(Q) {
	return abs(q);
}

quaternion_length2 :: proc(q: $Q) -> Q where IS_QUATERNION(Q) {
	return dot(q, q);
}

length :: proc{vector_length, quaternion_length};
length2 :: proc{vector_length2, quaternion_length2};


identity :: proc($T: typeid/[$N][N]$E) -> (m: T) {
	for i in 0..<N do m[i][i] = E(1);
	return m;
}

trace :: proc(m: $T/[$N][N]$E) -> (tr: E) {
	for i in 0..<N {
		tr += m[i][i];
	}
	return;
}


transpose :: proc(a: $T/[$N][$M]$E) -> (m: T) {
	for j in 0..<M {
		for i in 0..<N {
			m[j][i] = a[i][j];
		}
	}
	return;
}

matrix_mul :: proc(a, b: $M/[$N][N]$E) -> (c: M)
	where !IS_ARRAY(E),
		  IS_NUMERIC(E) {
	for i in 0..<N {
		for k in 0..<N {
			for j in 0..<N {
				c[k][i] += a[j][i] * b[k][j];
			}
		}
	}
	return;
}

matrix_comp_mul :: proc(a, b: $M/[$J][$I]$E) -> (c: M)
	where !IS_ARRAY(E),
	     IS_NUMERIC(E) {
	for j in 0..<J {
		for i in 0..<I {
			c[j][i] = a[j][i] * b[j][i];
		}
	}
	return;
}

matrix_mul_differ :: proc(a: $A/[$J][$I]$E, b: $B/[$K][J]E) -> (c: [K][I]E)
	where !IS_ARRAY(E),
		  IS_NUMERIC(E),
		  I != K {
	for k in 0..<K {
		for j in 0..<J {
			for i in 0..<I {
				c[k][i] += a[j][i] * b[k][j];
			}
		}
	}
	return;
}


matrix_mul_vector :: proc(a: $A/[$I][$J]$E, b: $B/[I]E) -> (c: B)
	where !IS_ARRAY(E),
		  IS_NUMERIC(E) {
	for i in 0..<I {
		for j in 0..<J {
			c[j] += a[i][j] * b[i];
		}
	}
	return;
}

quaternion_mul_quaternion :: proc(q1, q2: $Q) -> Q where IS_QUATERNION(Q) {
	return q1 * q2;
}
quaternion128_mul_vector3 :: proc(q: $Q/quaternion128, v: $V/[3]$F/f32) -> V {
	Raw_Quaternion :: struct {xyz: [3]f32, r: f32};

	q := transmute(Raw_Quaternion)q;
	v := transmute([3]f32)v;

	t := cross(2*q.xyz, v);
	return V(v + q.r*t + cross(q.xyz, t));
}

quaternion256_mul_vector3 :: proc(q: $Q/quaternion256, v: $V/[3]$F/f64) -> V {
	Raw_Quaternion :: struct {xyz: [3]f64, r: f64};

	q := transmute(Raw_Quaternion)q;
	v := transmute([3]f64)v;

	t := cross(2*q.xyz, v);
	return V(v + q.r*t + cross(q.xyz, t));
}
quaternion_mul_vector3 :: proc{quaternion128_mul_vector3, quaternion256_mul_vector3};

mul :: proc{
	matrix_mul,
	matrix_mul_differ,
	matrix_mul_vector,
	quaternion128_mul_vector3,
	quaternion256_mul_vector3,
	quaternion_mul_quaternion,
};

vector_to_ptr :: proc(v: ^$V/[$N]$E) -> ^E where IS_NUMERIC(E), N > 0 #no_bounds_check {
	return &v[0];
}
matrix_to_ptr :: proc(m: ^$A/[$I][$J]$E) -> ^E where IS_NUMERIC(E), I > 0, J > 0 #no_bounds_check {
	return &m[0][0];
}

to_ptr :: proc{vector_to_ptr, matrix_to_ptr};



