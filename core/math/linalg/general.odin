package linalg

import "core:math"
import "intrinsics"

// Generic

@private IS_NUMERIC :: intrinsics.type_is_numeric;
@private IS_QUATERNION :: intrinsics.type_is_quaternion;
@private IS_ARRAY :: intrinsics.type_is_array;


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

vector_cross :: proc{vector_cross2, vector_cross3};
cross :: vector_cross;

vector_normalize :: proc(v: $T/[$N]$E) -> T where IS_NUMERIC(E) {
	return v / length(v);
}
quaternion_normalize :: proc(q: $Q) -> Q where IS_QUATERNION(Q) {
	return q/abs(q);
}
normalize :: proc{vector_normalize, quaternion_normalize};

vector_normalize0 :: proc(v: $T/[$N]$E) -> T where IS_NUMERIC(E) {
	m := length(v);
	return m == 0 ? 0 : v/m;
}
quaternion_normalize0 :: proc(q: $Q) -> Q  where IS_QUATERNION(Q) {
	m := abs(q);
	return m == 0 ? 0 : q/m;
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


vector_lerp :: proc(x, y, t: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		ti := t[i];
		s[i] = x[i]*(1-ti) + y[i]*ti;
	}
	return s;
}

vector_unlerp :: proc(a, b, x: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		ai := a[i];
		s[i] = (x[i]-ai)/(b[i]-ai);
	}
	return s;
}

vector_sin :: proc(angle: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.sin(angle[i]);
	}
	return s;
}

vector_cos :: proc(angle: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.cos(angle[i]);
	}
	return s;
}

vector_tan :: proc(angle: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.tan(angle[i]);
	}
	return s;
}


vector_asin :: proc(x: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.asin(x[i]);
	}
	return s;
}

vector_acos :: proc(x: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.acos(x[i]);
	}
	return s;
}

vector_atan :: proc(x: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.atan(x[i]);
	}
	return s;
}

vector_atan2 :: proc(y, x: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.atan(y[i], x[i]);
	}
	return s;
}

vector_pow :: proc(x, y: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.pow(x[i], y[i]);
	}
	return s;
}

vector_expr :: proc(x: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.expr(x[i]);
	}
	return s;
}

vector_sqrt :: proc(x: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.sqrt(x[i]);
	}
	return s;
}

vector_abs :: proc(x: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = abs(x[i]);
	}
	return s;
}

vector_sign :: proc(v: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.sign(v[i]);
	}
	return s;
}

vector_floor :: proc(v: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.floor(v[i]);
	}
	return s;
}

vector_ceil :: proc(v: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.ceil(v[i]);
	}
	return s;
}


vector_mod :: proc(x, y: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = math.mod(x[i], y[i]);
	}
	return s;
}

vector_min :: proc(a, b: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = min(a[i], b[i]);
	}
	return s;
}

vector_max :: proc(a, b: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = max(a[i], b[i]);
	}
	return s;
}

vector_clamp :: proc(x, a, b: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = clamp(x[i], a[i], b[i]);
	}
	return s;
}

vector_mix :: proc(x, y, a: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = x[i]*(1-a[i]) + y[i]*a[i];
	}
	return s;
}

vector_step :: proc(edge, x: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		s[i] = x[i] < edge[i] ? 0 : 1;
	}
	return s;
}

vector_smoothstep :: proc(edge0, edge1, x: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		e0, e1 := edge0[i], edge1[i];
		t := clamp((x[i] - e0) / (e1 - e0), 0, 1);
		s[i] = t * t * (3 - 2*t);
	}
	return s;
}

vector_smootherstep :: proc(edge0, edge1, x: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	s: V;
	for i in 0..<N {
		e0, e1 := edge0[i], edge1[i];
		t := clamp((x[i] - e0) / (e1 - e0), 0, 1);
		s[i] = t * t * t * (t * (6*t - 15) + 10);
	}
	return s;
}

vector_distance :: proc(p0, p1: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	return length(p1 - p0);
}

vector_reflect :: proc(i, n: $V/[$N]$E) -> V where IS_NUMERIC(E) {
	b := n * (2 * dot(n, i));
	return i - b;
}

vector_refract :: proc(i, n: $V/[$N]$E, eta: E) -> V where IS_NUMERIC(E) {
	dv := dot(n, i);
	k := 1 - eta*eta - (1 - dv*dv);
	a := i * eta;
	b := n * eta*dv*math.sqrt(k);
	return (a - b) * E(int(k >= 0));
}



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
			c[i] += a[i][j] * b[i];
		}
	}
	return;
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
};

vector_to_ptr :: proc(v: ^$V/[$N]$E) -> ^E where IS_NUMERIC(E) {
	return &v[0];
}
matrix_to_ptr :: proc(m: ^$A/[$I][$J]$E) -> ^E where IS_NUMERIC(E) {
	return &m[0][0];
}

