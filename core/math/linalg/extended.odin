package linalg

import "builtin"
import "core:math"

radians :: proc(degrees: $T) -> (out: T) where IS_NUMERIC(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = degrees * RAD_PER_DEG;
		}
	} else {
		out = degrees * RAD_PER_DEG;
	}
	return;
}
degrees :: proc(radians: $T) -> (out: T) where IS_NUMERIC(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = radians * DEG_PER_RAD;
		}
	} else {
		out = radians * DEG_PER_RAD;
	}
	return;
}

min_double :: proc(a, b: $T) -> (out: T) where IS_NUMERIC(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = builtin.min(a[i], b[i]);
		}
	} else {
		out = builtin.min(a, b);
	}
	return;
}

min_single :: proc(a: $T) -> (out: ELEM_TYPE(T)) where IS_NUMERIC(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		N :: len(T);

		when N == 1 {
			out = a[0];
		} else when N == 2 {
			out = builtin.min(a[0], a[1]);
		} else {
			out = builtin.min(a[0], a[1]);
			for i in 2..<N {
				out = builtin.min(out, a[i]);
			}
		}
	} else {
		out = a;
	}
	return;
}

min_triple :: proc(a, b, c: $T) -> T where IS_NUMERIC(ELEM_TYPE(T)) {
	return min_double(a, min_double(b, c));
}

min :: proc{min_single, min_double, min_triple};

max_double :: proc(a, b: $T) -> (out: T) where IS_NUMERIC(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = builtin.max(a[i], b[i]);
		}
	} else {
		out = builtin.max(a, b);
	}
	return;
}

max_single :: proc(a: $T) -> (out: ELEM_TYPE(T)) where IS_NUMERIC(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		N :: len(T);

		when N == 1 {
			out = a[0];
		} else when N == 2 {
			out = builtin.max(a[0], a[1]);
		} else when N == 3 {
			out = builtin.max(a[0], a[1], a[3]);
		}else {
			out = builtin.max(a[0], a[1]);
			for i in 2..<N {
				out = builtin.max(out, a[i]);
			}
		}
	} else {
		out = a;
	}
	return;
}

max_triple :: proc(a, b, c: $T) -> T where IS_NUMERIC(ELEM_TYPE(T)) {
	return max_double(a, max_double(b, c));
}

max :: proc{max_single, max_double, max_triple};

abs :: proc(a: $T) -> (out: T) where IS_NUMERIC(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = builtin.abs(a[i]);
		}
	} else {
		out = builtin.abs(a);
	}
	return;
}

sign :: proc(a: $T) -> (out: T) where IS_NUMERIC(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = #force_inline math.sign(a[i]);
		}
	} else {
		out = #force_inline math.sign(a);
	}
	return;
}

clamp :: proc(x, a, b: $T) -> (out: T) where IS_NUMERIC(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = builtin.clamp(x[i], a[i], b[i]);
		}
	} else {
		out = builtin.clamp(x, a, b);
	}
	return;
}


saturate :: proc(x: $T) -> T where IS_FLOAT(ELEM_TYPE(T)) {
	return clamp(x, 0.0, 1.0);
}

lerp :: proc(a, b, t: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = a[i]*(1-t[i]) + b[i]*t[i];
		}
	} else {
		out = a * (1.0 - t) + b * t;
	}
	return;
}
mix :: proc(a, b, t: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = a[i]*(1-t[i]) + b[i]*t[i];
		}
	} else {
		out = a * (1.0 - t) + b * t;
	}
	return;
}

unlerp :: proc(a, b, x: $T) -> T where IS_FLOAT(ELEM_TYPE(T)) {
	return (x - a) / (b - a);
}

step :: proc(e, x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = x[i] < e[i] ? 0.0 : 1.0;
		}
	} else {
		out = x < e ? 0.0 : 1.0;
	}
	return;
}

smoothstep :: proc(e0, e1, x: $T) -> T where IS_FLOAT(ELEM_TYPE(T)) {
	t := saturate(unlerp(e0, e1, x));
	return t * t * (3.0 - 2.0 * t);
}

smootherstep :: proc(e0, e1, x: $T) -> T where IS_FLOAT(ELEM_TYPE(T)) {
	t := saturate(unlerp(e0, e1, x));
	return t * t * t * (t * (6*t - 15) + 10);
}


sqrt :: proc(x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.sqrt(x[i]);
		}
	} else {
		out = math.sqrt(x);
	}
	return;
}

inverse_sqrt :: proc(x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = 1.0/math.sqrt(x[i]);
		}
	} else {
		out = 1.0/math.sqrt(x);
	}
	return;
}

cos :: proc(x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.cos(x[i]);
		}
	} else {
		out = math.cos(x);
	}
	return;
}

sin :: proc(x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.sin(x[i]);
		}
	} else {
		out = math.sin(x);
	}
	return;
}

tan :: proc(x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.tan(x[i]);
		}
	} else {
		out = math.tan(x);
	}
	return;
}

acos :: proc(x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.acos(x[i]);
		}
	} else {
		out = math.acos(x);
	}
	return;
}

asin :: proc(x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.asin(x[i]);
		}
	} else {
		out = math.asin(x);
	}
	return;
}

atan :: proc(x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.atan(x[i]);
		}
	} else {
		out = math.atan(x);
	}
	return;
}
atan2 :: proc(y, x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.atan2(y[i], x[i]);
		}
	} else {
		out = math.atan2(y, x);
	}
	return;
}


ln :: proc(x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.ln(x[i]);
		}
	} else {
		out = math.ln(x);
	}
	return;
}

log2 :: proc(x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = INVLN2 * math.ln(x[i]);
		}
	} else {
		out = INVLN2 * math.ln(x);
	}
	return;
}

log10 :: proc(x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = INVLN10 * math.ln(x[i]);
		}
	} else {
		out = INVLN10 * math.ln(x);
	}
	return;
}

log :: proc(x, b: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.ln(x[i]) / math.ln(cast(ELEM_TYPE(T))b[i]);
		}
	} else {
		out = INVLN10 * math.ln(x) / math.ln(cast(ELEM_TYPE(T))b);
	}
	return;
}

exp :: proc(x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.exp(x[i]);
		}
	} else {
		out = math.exp(x);
	}
	return;
}

exp2 :: proc(x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.exp(LN2 * x[i]);
		}
	} else {
		out = math.exp(LN2 * x);
	}
	return;
}

exp10 :: proc(x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.exp(LN10 * x[i]);
		}
	} else {
		out = math.exp(LN10 * x);
	}
	return;
}

pow :: proc(x, e: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.pow(x[i], e[i]);
		}
	} else {
		out = math.pow(x, e);
	}
	return;
}


ceil :: proc(x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = #force_inline math.ceil(x[i]);
		}
	} else {
		out = #force_inline math.ceil(x);
	}
	return;
}

floor :: proc(x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = #force_inline math.floor(x[i]);
		}
	} else {
		out = #force_inline math.floor(x);
	}
	return;
}

round :: proc(x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = #force_inline math.round(x[i]);
		}
	} else {
		out = #force_inline math.round(x);
	}
	return;
}

fract :: proc(x: $T) -> T where IS_FLOAT(ELEM_TYPE(T)) {
	f := #force_inline floor(x);
	return x - f;
}

mod :: proc(x, m: $T) -> T where IS_FLOAT(ELEM_TYPE(T)) {
	f := #force_inline floor(x / m);
	return x - f * m;
}


face_forward :: proc(N, I, N_ref: $T) -> (out: T) where IS_ARRAY(T), IS_FLOAT(ELEM_TYPE(T)) {
	return dot(N_ref, I) < 0 ? N : -N;
}

distance :: proc(p0, p1: $V/[$N]$E) -> E where IS_NUMERIC(E) {
	return length(p1 - p0);
}

reflect :: proc(I, N: $T) -> (out: T) where IS_ARRAY(T), IS_FLOAT(ELEM_TYPE(T)) {
	b := n * (2 * dot(n, i));
	return i - b;
}
refract :: proc(I, N: $T) -> (out: T) where IS_ARRAY(T), IS_FLOAT(ELEM_TYPE(T)) {
	dv := dot(n, i);
	k := 1 - eta*eta - (1 - dv*dv);
	a := i * eta;
	b := n * eta*dv*math.sqrt(k);
	return (a - b) * E(int(k >= 0));
}




is_nan_single :: proc(x: $T) -> bool where IS_FLOAT(T) {
	return #force_inline math.is_nan(x);
}

is_nan_array :: proc(x: $A/[$N]$T) -> (out: [N]bool) where IS_FLOAT(T) {
	for i in 0..<N {
		out[i] = #force_inline is_nan(x[i]);
	}
	return;
}

is_inf_single :: proc(x: $T) -> bool where IS_FLOAT(T) {
	return #force_inline math.is_inf(x);
}

is_inf_array :: proc(x: $A/[$N]$T) -> (out: [N]bool) where IS_FLOAT(T) {
	for i in 0..<N {
		out[i] = #force_inline is_inf(x[i]);
	}
	return;
}

classify_single :: proc(x: $T) -> math.Float_Class where IS_FLOAT(T) {
	return #force_inline math.classify(x);
}

classify_array :: proc(x: $A/[$N]$T) -> (out: [N]math.Float_Class) where IS_FLOAT(T) {
	for i in 0..<N {
		out[i] = #force_inline classify_single(x[i]);
	}
	return;
}

is_nan :: proc{is_nan_single, is_nan_array};
is_inf :: proc{is_inf_single, is_inf_array};
classify :: proc{classify_single, classify_array};


less_than_single          :: proc(x, y: $T) -> (out: bool) where !IS_ARRAY(T), IS_FLOAT(T) { return x < y; }
less_than_equal_single    :: proc(x, y: $T) -> (out: bool) where !IS_ARRAY(T), IS_FLOAT(T) { return x <= y; }
greater_than_single       :: proc(x, y: $T) -> (out: bool) where !IS_ARRAY(T), IS_FLOAT(T) { return x > y; }
greater_than_equal_single :: proc(x, y: $T) -> (out: bool) where !IS_ARRAY(T), IS_FLOAT(T) { return x >= y; }
equal_single              :: proc(x, y: $T) -> (out: bool) where !IS_ARRAY(T), IS_FLOAT(T) { return x == y; }
not_equal_single          :: proc(x, y: $T) -> (out: bool) where !IS_ARRAY(T), IS_FLOAT(T) { return x != y; }

less_than_array :: proc(x, y: $A/[$N]$T) -> (out: [N]bool) where IS_ARRAY(A), IS_FLOAT(ELEM_TYPE(A)) {
	for i in 0..<N {
		out[i] = x[i] < y[i];
	}
	return;
}
less_than_equal_array :: proc(x, y: $A/[$N]$T) -> (out: [N]bool) where IS_ARRAY(A), IS_FLOAT(ELEM_TYPE(A)) {
	for i in 0..<N {
		out[i] = x[i] <= y[i];
	}
	return;
}
greater_than_array :: proc(x, y: $A/[$N]$T) -> (out: [N]bool) where IS_ARRAY(A), IS_FLOAT(ELEM_TYPE(A)) {
	for i in 0..<N {
		out[i] = x[i] > y[i];
	}
	return;
}
greater_than_equal_array :: proc(x, y: $A/[$N]$T) -> (out: [N]bool) where IS_ARRAY(A), IS_FLOAT(ELEM_TYPE(A)) {
	for i in 0..<N {
		out[i] = x[i] >= y[i];
	}
	return;
}
equal_array :: proc(x, y: $A/[$N]$T) -> (out: [N]bool) where IS_ARRAY(A), IS_FLOAT(ELEM_TYPE(A)) {
	for i in 0..<N {
		out[i] = x[i] == y[i];
	}
	return;
}
not_equal_array :: proc(x, y: $A/[$N]$T) -> (out: [N]bool) where IS_ARRAY(A), IS_FLOAT(ELEM_TYPE(A)) {
	for i in 0..<N {
		out[i] = x[i] != y[i];
	}
	return;
}

less_than          :: proc{less_than_single, less_than_array};
less_than_equal    :: proc{less_than_equal_single, less_than_equal_array};
greater_than       :: proc{greater_than_single, greater_than_array};
greater_than_equal :: proc{greater_than_equal_single, greater_than_equal_array};
equal              :: proc{equal_single, equal_array};
not_equal          :: proc{not_equal_single, not_equal_array};

any :: proc(x: $A/[$N]bool) -> (out: bool) {
	for e in x {
		if x {
			return true;
		}
	}
	return false;
}
all :: proc(x: $A/[$N]bool) -> (out: bool) {
	for e in x {
		if !e {
			return false;
		}
	}
	return true;
}
not :: proc(x: $A/[$N]bool) -> (out: A) {
	for e, i in x {
		out[i] = !e;
	}
	return;
}
