package linalg

import "core:math"
import "core:builtin"
import "core:intrinsics"

// Generic

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

RAD_PER_DEG :: TAU/360.0
DEG_PER_RAD :: 360.0/TAU



@private IS_NUMERIC :: intrinsics.type_is_numeric
@private IS_QUATERNION :: intrinsics.type_is_quaternion
@private IS_ARRAY :: intrinsics.type_is_array
@private IS_FLOAT :: intrinsics.type_is_float
@private BASE_TYPE :: intrinsics.type_base_type
@private ELEM_TYPE :: intrinsics.type_elem_type


@(require_results)
scalar_dot :: proc "contextless" (a, b: $T) -> T where IS_FLOAT(T), !IS_ARRAY(T) {
	return a * b
}

@(require_results)
vector_dot :: proc "contextless" (a, b: $T/[$N]$E) -> (c: E) where IS_NUMERIC(E) #no_bounds_check {
	for i in 0..<N {
		c += a[i] * b[i]
	}
	return
}
@(require_results)
quaternion64_dot :: proc "contextless" (a, b: $T/quaternion64) -> (c: f16) {
	return a.w*a.w + a.x*b.x + a.y*b.y + a.z*b.z
}
@(require_results)
quaternion128_dot :: proc "contextless" (a, b: $T/quaternion128) -> (c: f32) {
	return a.w*a.w + a.x*b.x + a.y*b.y + a.z*b.z
}
@(require_results)
quaternion256_dot :: proc "contextless" (a, b: $T/quaternion256) -> (c: f64) {
	return a.w*a.w + a.x*b.x + a.y*b.y + a.z*b.z
}

dot :: proc{scalar_dot, vector_dot, quaternion64_dot, quaternion128_dot, quaternion256_dot}

inner_product :: dot
outer_product :: builtin.outer_product

@(require_results)
quaternion_inverse :: proc "contextless" (q: $Q) -> Q where IS_QUATERNION(Q) {
	return conj(q) * quaternion(1.0/dot(q, q), 0, 0, 0)
}


@(require_results)
scalar_cross :: proc "contextless" (a, b: $T) -> T where IS_FLOAT(T), !IS_ARRAY(T) {
	return a * b
}

@(require_results)
vector_cross2 :: proc "contextless" (a, b: $T/[2]$E) -> E where IS_NUMERIC(E) {
	return a[0]*b[1] - b[0]*a[1]
}

@(require_results)
vector_cross3 :: proc "contextless" (a, b: $T/[3]$E) -> (c: T) where IS_NUMERIC(E) {
	c[0] = a[1]*b[2] - b[1]*a[2]
	c[1] = a[2]*b[0] - b[2]*a[0]
	c[2] = a[0]*b[1] - b[0]*a[1]
	return
}

@(require_results)
quaternion_cross :: proc "contextless" (q1, q2: $Q) -> (q3: Q) where IS_QUATERNION(Q) {
	q3.x = q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y
	q3.y = q1.w * q2.y + q1.y * q2.w + q1.z * q2.x - q1.x * q2.z
	q3.z = q1.w * q2.z + q1.z * q2.w + q1.x * q2.y - q1.y * q2.x
	q3.w = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z
	return
}

vector_cross :: proc{scalar_cross, vector_cross2, vector_cross3}
cross :: proc{scalar_cross, vector_cross2, vector_cross3, quaternion_cross}

@(require_results)
vector_normalize :: proc "contextless" (v: $T/[$N]$E) -> T where IS_FLOAT(E) {
	return v / length(v)
}
@(require_results)
quaternion_normalize :: proc "contextless" (q: $Q) -> Q where IS_QUATERNION(Q) {
	return q/abs(q)
}
normalize :: proc{vector_normalize, quaternion_normalize}

@(require_results)
vector_normalize0 :: proc "contextless" (v: $T/[$N]$E) -> T where IS_FLOAT(E) {
	m := length(v)
	return 0 if m == 0 else v/m
}
@(require_results)
quaternion_normalize0 :: proc "contextless" (q: $Q) -> Q  where IS_QUATERNION(Q) {
	m := abs(q)
	return 0 if m == 0 else q/m
}
normalize0 :: proc{vector_normalize0, quaternion_normalize0}


@(require_results)
vector_length :: proc "contextless" (v: $T/[$N]$E) -> E where IS_FLOAT(E) {
	return math.sqrt(dot(v, v))
}

@(require_results)
vector_length2 :: proc "contextless" (v: $T/[$N]$E) -> E where IS_NUMERIC(E) {
	return dot(v, v)
}

@(require_results)
quaternion_length :: proc "contextless" (q: $Q) -> Q where IS_QUATERNION(Q) {
	return abs(q)
}

@(require_results)
quaternion_length2 :: proc "contextless" (q: $Q) -> Q where IS_QUATERNION(Q) {
	return dot(q, q)
}

@(require_results)
scalar_triple_product :: proc "contextless" (a, b, c: $T/[$N]$E) -> E where IS_NUMERIC(E) {
	// a . (b x c)
	// b . (c x a)
	// c . (a x b)
	return dot(a, cross(b, c))
}

@(require_results)
vector_triple_product :: proc "contextless" (a, b, c: $T/[$N]$E) -> T where IS_NUMERIC(E) {
	// a x (b x c)
	// (a . c)b - (a . b)c
	return cross(a, cross(b, c))
}


length :: proc{vector_length, quaternion_length}
length2 :: proc{vector_length2, quaternion_length2}

@(require_results)
projection :: proc "contextless" (x, normal: $T/[$N]$E) -> T where IS_NUMERIC(E) {
	return dot(x, normal) / dot(normal, normal) * normal
}

@(require_results)
identity :: proc "contextless" ($T: typeid/[$N][N]$E) -> (m: T) #no_bounds_check {
	for i in 0..<N {
		m[i][i] = E(1)
	}
	return m
}

trace :: builtin.matrix_trace
transpose :: builtin.transpose

@(require_results)
matrix_mul :: proc "contextless" (a, b: $M/matrix[$N, N]$E) -> (c: M)
	where !IS_ARRAY(E), IS_NUMERIC(E) #no_bounds_check {
	return a * b
}

@(require_results)
matrix_comp_mul :: proc "contextless" (a, b: $M/matrix[$I, $J]$E) -> (c: M)
	where !IS_ARRAY(E), IS_NUMERIC(E) #no_bounds_check {
	return hadamard_product(a, b)
}

@(require_results)
matrix_mul_differ :: proc "contextless" (a: $A/matrix[$I, $J]$E, b: $B/matrix[J, $K]E) -> (c: matrix[I, K]E)
	where !IS_ARRAY(E), IS_NUMERIC(E), I != K #no_bounds_check {
	return a * b
}


@(require_results)
matrix_mul_vector :: proc "contextless" (a: $A/matrix[$I, $J]$E, b: $B/[J]E) -> (c: B)
	where !IS_ARRAY(E), IS_NUMERIC(E) #no_bounds_check {
	return a * b
}

@(require_results)
quaternion_mul_quaternion :: proc "contextless" (q1, q2: $Q) -> Q where IS_QUATERNION(Q) {
	return q1 * q2
}

@(require_results)
quaternion64_mul_vector3 :: proc "contextless" (q: $Q/quaternion64, v: $V/[3]$F/f16) -> V {
	Raw_Quaternion :: struct {xyz: [3]f16, r: f16}

	q := transmute(Raw_Quaternion)q
	v := transmute([3]f16)v

	t := cross(2*q.xyz, v)
	return V(v + q.r*t + cross(q.xyz, t))
}
@(require_results)
quaternion128_mul_vector3 :: proc "contextless" (q: $Q/quaternion128, v: $V/[3]$F/f32) -> V {
	Raw_Quaternion :: struct {xyz: [3]f32, r: f32}

	q := transmute(Raw_Quaternion)q
	v := transmute([3]f32)v

	t := cross(2*q.xyz, v)
	return V(v + q.r*t + cross(q.xyz, t))
}
@(require_results)
quaternion256_mul_vector3 :: proc "contextless" (q: $Q/quaternion256, v: $V/[3]$F/f64) -> V {
	Raw_Quaternion :: struct {xyz: [3]f64, r: f64}

	q := transmute(Raw_Quaternion)q
	v := transmute([3]f64)v

	t := cross(2*q.xyz, v)
	return V(v + q.r*t + cross(q.xyz, t))
}
quaternion_mul_vector3 :: proc{quaternion64_mul_vector3, quaternion128_mul_vector3, quaternion256_mul_vector3}

mul :: proc{
	matrix_mul,
	matrix_mul_differ,
	matrix_mul_vector,
	quaternion64_mul_vector3,
	quaternion128_mul_vector3,
	quaternion256_mul_vector3,
	quaternion_mul_quaternion,
}

@(require_results)
vector_to_ptr :: proc "contextless" (v: ^$V/[$N]$E) -> ^E where IS_NUMERIC(E), N > 0 #no_bounds_check {
	return &v[0]
}
@(require_results)
matrix_to_ptr :: proc "contextless" (m: ^$A/matrix[$I, $J]$E) -> ^E where IS_NUMERIC(E), I > 0, J > 0 #no_bounds_check {
	return &m[0, 0]
}

to_ptr :: proc{vector_to_ptr, matrix_to_ptr}





// Splines

@(require_results)
vector_slerp :: proc "contextless" (x, y: $T/[$N]$E, a: E) -> T {
	cos_alpha := dot(x, y)
	alpha := math.acos(cos_alpha)
	sin_alpha := math.sin(alpha)

	t1 := math.sin((1 - a) * alpha) / sin_alpha
	t2 := math.sin(a * alpha) / sin_alpha

	return x * t1 + y * t2
}

@(require_results)
catmull_rom :: proc "contextless" (v1, v2, v3, v4: $T/[$N]$E, s: E) -> T {
	s2 := s*s
	s3 := s2*s

	f1 := -s3 + 2 * s2 - s
	f2 := 3 * s3 - 5 * s2 + 2
	f3 := -3 * s3 + 4 * s2 + s
	f4 := s3 - s2

	return (f1 * v1 + f2 * v2 + f3 * v3 + f4 * v4) * 0.5
}

@(require_results)
hermite :: proc "contextless" (v1, t1, v2, t2: $T/[$N]$E, s: E) -> T {
	s2 := s*s
	s3 := s2*s

	f1 := 2 * s3 - 3 * s2 + 1
	f2 := -2 * s3 + 3 * s2
	f3 := s3 - 2 * s2 + s
	f4 := s3 - s2

	return f1 * v1 + f2 * v2 + f3 * t1 + f4 * t2
}

@(require_results)
cubic :: proc "contextless" (v1, v2, v3, v4: $T/[$N]$E, s: E) -> T {
	return ((v1 * s + v2) * s + v3) * s + v4
}



@(require_results)
array_cast :: proc "contextless" (v: $A/[$N]$T, $Elem_Type: typeid) -> (w: [N]Elem_Type) #no_bounds_check {
	for i in 0..<N {
		w[i] = Elem_Type(v[i])
	}
	return
}

@(require_results)
matrix_cast :: proc "contextless" (v: $A/matrix[$M, $N]$T, $Elem_Type: typeid) -> (w: matrix[M, N]Elem_Type) #no_bounds_check {
	for j in 0..<N {
		for i in 0..<M {
			w[i, j] = Elem_Type(v[i, j])
		}
	}
	return
}

@(require_results) to_f32  :: #force_inline proc(v: $A/[$N]$T) -> [N]f32  { return array_cast(v, f32)  }
@(require_results) to_f64  :: #force_inline proc(v: $A/[$N]$T) -> [N]f64  { return array_cast(v, f64)  }

@(require_results) to_i8   :: #force_inline proc(v: $A/[$N]$T) -> [N]i8   { return array_cast(v, i8)   }
@(require_results) to_i16  :: #force_inline proc(v: $A/[$N]$T) -> [N]i16  { return array_cast(v, i16)  }
@(require_results) to_i32  :: #force_inline proc(v: $A/[$N]$T) -> [N]i32  { return array_cast(v, i32)  }
@(require_results) to_i64  :: #force_inline proc(v: $A/[$N]$T) -> [N]i64  { return array_cast(v, i64)  }
@(require_results) to_int  :: #force_inline proc(v: $A/[$N]$T) -> [N]int  { return array_cast(v, int)  }

@(require_results) to_u8   :: #force_inline proc(v: $A/[$N]$T) -> [N]u8   { return array_cast(v, u8)   }
@(require_results) to_u16  :: #force_inline proc(v: $A/[$N]$T) -> [N]u16  { return array_cast(v, u16)  }
@(require_results) to_u32  :: #force_inline proc(v: $A/[$N]$T) -> [N]u32  { return array_cast(v, u32)  }
@(require_results) to_u64  :: #force_inline proc(v: $A/[$N]$T) -> [N]u64  { return array_cast(v, u64)  }
@(require_results) to_uint :: #force_inline proc(v: $A/[$N]$T) -> [N]uint { return array_cast(v, uint) }

@(require_results) to_complex32     :: #force_inline proc(v: $A/[$N]$T) -> [N]complex32     { return array_cast(v, complex32)     }
@(require_results) to_complex64     :: #force_inline proc(v: $A/[$N]$T) -> [N]complex64     { return array_cast(v, complex64)     }
@(require_results) to_complex128    :: #force_inline proc(v: $A/[$N]$T) -> [N]complex128    { return array_cast(v, complex128)    }
@(require_results) to_quaternion64  :: #force_inline proc(v: $A/[$N]$T) -> [N]quaternion64  { return array_cast(v, quaternion64)  }
@(require_results) to_quaternion128 :: #force_inline proc(v: $A/[$N]$T) -> [N]quaternion128 { return array_cast(v, quaternion128) }
@(require_results) to_quaternion256 :: #force_inline proc(v: $A/[$N]$T) -> [N]quaternion256 { return array_cast(v, quaternion256) }
