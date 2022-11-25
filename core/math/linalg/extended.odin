package linalg

import "core:builtin"
import "core:math"

radians :: proc "contextless" (degrees: $T) -> (out: T) where IS_NUMERIC(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = degrees * RAD_PER_DEG
		}
	} else {
		out = degrees * RAD_PER_DEG
	}
	return
}
degrees :: proc "contextless" (radians: $T) -> (out: T) where IS_NUMERIC(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = radians * DEG_PER_RAD
		}
	} else {
		out = radians * DEG_PER_RAD
	}
	return
}

min_double :: proc "contextless" (a, b: $T) -> (out: T) where IS_NUMERIC(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = builtin.min(a[i], b[i])
		}
	} else {
		out = builtin.min(a, b)
	}
	return
}

min_single :: proc "contextless" (a: $T) -> (out: ELEM_TYPE(T)) where IS_NUMERIC(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		N :: len(T)

		when N == 1 {
			out = a[0]
		} else when N == 2 {
			out = builtin.min(a[0], a[1])
		} else {
			out = builtin.min(a[0], a[1])
			for i in 2..<N {
				out = builtin.min(out, a[i])
			}
		}
	} else {
		out = a
	}
	return
}

min_triple :: proc "contextless" (a, b, c: $T) -> T where IS_NUMERIC(ELEM_TYPE(T)) {
	return min_double(a, min_double(b, c))
}

min :: proc{min_single, min_double, min_triple}

max_double :: proc "contextless" (a, b: $T) -> (out: T) where IS_NUMERIC(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = builtin.max(a[i], b[i])
		}
	} else {
		out = builtin.max(a, b)
	}
	return
}

max_single :: proc "contextless" (a: $T) -> (out: ELEM_TYPE(T)) where IS_NUMERIC(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		N :: len(T)

		when N == 1 {
			out = a[0]
		} else when N == 2 {
			out = builtin.max(a[0], a[1])
		} else when N == 3 {
			out = builtin.max(a[0], a[1], a[2])
		}else {
			out = builtin.max(a[0], a[1])
			for i in 2..<N {
				out = builtin.max(out, a[i])
			}
		}
	} else {
		out = a
	}
	return
}

max_triple :: proc "contextless" (a, b, c: $T) -> T where IS_NUMERIC(ELEM_TYPE(T)) {
	return max_double(a, max_double(b, c))
}

max :: proc{max_single, max_double, max_triple}

abs :: proc "contextless" (a: $T) -> (out: T) where IS_NUMERIC(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = auto_cast builtin.abs(a[i])
		}
	} else {
		out = auto_cast builtin.abs(a)
	}
	return
}

sign :: proc "contextless" (a: $T) -> (out: T) where IS_NUMERIC(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = #force_inline math.sign(a[i])
		}
	} else {
		out = #force_inline math.sign(a)
	}
	return
}

clamp :: proc "contextless" (x, a, b: $T) -> (out: T) where IS_NUMERIC(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = builtin.clamp(x[i], a[i], b[i])
		}
	} else {
		out = builtin.clamp(x, a, b)
	}
	return
}


saturate :: proc "contextless" (x: $T) -> T where IS_FLOAT(ELEM_TYPE(T)) {
	return clamp(x, 0.0, 1.0)
}

lerp :: proc "contextless" (a, b, t: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = a[i]*(1-t[i]) + b[i]*t[i]
		}
	} else {
		out = a * (1.0 - t) + b * t
	}
	return
}
mix :: proc "contextless" (a, b, t: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = a[i]*(1-t[i]) + b[i]*t[i]
		}
	} else {
		out = a * (1.0 - t) + b * t
	}
	return
}

unlerp :: proc "contextless" (a, b, x: $T) -> T where IS_FLOAT(ELEM_TYPE(T)) {
	return (x - a) / (b - a)
}

step :: proc "contextless" (e, x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = x[i] < e[i] ? 0.0 : 1.0
		}
	} else {
		out = x < e ? 0.0 : 1.0
	}
	return
}

smoothstep :: proc "contextless" (e0, e1, x: $T) -> T where IS_FLOAT(ELEM_TYPE(T)) {
	t := saturate(unlerp(e0, e1, x))
	return t * t * (3.0 - 2.0 * t)
}

smootherstep :: proc "contextless" (e0, e1, x: $T) -> T where IS_FLOAT(ELEM_TYPE(T)) {
	t := saturate(unlerp(e0, e1, x))
	return t * t * t * (t * (6*t - 15) + 10)
}


sqrt :: proc "contextless" (x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.sqrt(x[i])
		}
	} else {
		out = math.sqrt(x)
	}
	return
}

inverse_sqrt :: proc "contextless" (x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = 1.0/math.sqrt(x[i])
		}
	} else {
		out = 1.0/math.sqrt(x)
	}
	return
}

cos :: proc "contextless" (x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.cos(x[i])
		}
	} else {
		out = math.cos(x)
	}
	return
}

sin :: proc "contextless" (x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.sin(x[i])
		}
	} else {
		out = math.sin(x)
	}
	return
}

tan :: proc "contextless" (x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.tan(x[i])
		}
	} else {
		out = math.tan(x)
	}
	return
}

acos :: proc "contextless" (x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.acos(x[i])
		}
	} else {
		out = math.acos(x)
	}
	return
}

asin :: proc "contextless" (x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.asin(x[i])
		}
	} else {
		out = math.asin(x)
	}
	return
}

atan :: proc "contextless" (x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.atan(x[i])
		}
	} else {
		out = math.atan(x)
	}
	return
}
atan2 :: proc "contextless" (y, x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.atan2(y[i], x[i])
		}
	} else {
		out = math.atan2(y, x)
	}
	return
}


ln :: proc "contextless" (x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.ln(x[i])
		}
	} else {
		out = math.ln(x)
	}
	return
}

log2 :: proc "contextless" (x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = INVLN2 * math.ln(x[i])
		}
	} else {
		out = INVLN2 * math.ln(x)
	}
	return
}

log10 :: proc "contextless" (x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = INVLN10 * math.ln(x[i])
		}
	} else {
		out = INVLN10 * math.ln(x)
	}
	return
}

log :: proc "contextless" (x, b: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.ln(x[i]) / math.ln(cast(ELEM_TYPE(T))b[i])
		}
	} else {
		out = INVLN10 * math.ln(x) / math.ln(cast(ELEM_TYPE(T))b)
	}
	return
}

exp :: proc "contextless" (x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.exp(x[i])
		}
	} else {
		out = math.exp(x)
	}
	return
}

exp2 :: proc "contextless" (x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.exp(LN2 * x[i])
		}
	} else {
		out = math.exp(LN2 * x)
	}
	return
}

exp10 :: proc "contextless" (x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.exp(LN10 * x[i])
		}
	} else {
		out = math.exp(LN10 * x)
	}
	return
}

pow :: proc "contextless" (x, e: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = math.pow(x[i], e[i])
		}
	} else {
		out = math.pow(x, e)
	}
	return
}


ceil :: proc "contextless" (x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = #force_inline math.ceil(x[i])
		}
	} else {
		out = #force_inline math.ceil(x)
	}
	return
}

floor :: proc "contextless" (x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = #force_inline math.floor(x[i])
		}
	} else {
		out = #force_inline math.floor(x)
	}
	return
}

round :: proc "contextless" (x: $T) -> (out: T) where IS_FLOAT(ELEM_TYPE(T)) {
	when IS_ARRAY(T) {
		for i in 0..<len(T) {
			out[i] = #force_inline math.round(x[i])
		}
	} else {
		out = #force_inline math.round(x)
	}
	return
}

fract :: proc "contextless" (x: $T) -> T where IS_FLOAT(ELEM_TYPE(T)) {
	f := #force_inline floor(x)
	return x - f
}

mod :: proc "contextless" (x, m: $T) -> T where IS_FLOAT(ELEM_TYPE(T)) {
	f := #force_inline floor(x / m)
	return x - f * m
}


face_forward :: proc "contextless" (N, I, N_ref: $T) -> (out: T) where IS_ARRAY(T), IS_FLOAT(ELEM_TYPE(T)) {
	return dot(N_ref, I) < 0 ? N : -N
}

distance :: proc "contextless" (p0, p1: $V/[$N]$E) -> E where IS_NUMERIC(E) {
	return length(p1 - p0)
}

reflect :: proc "contextless" (I, N: $T) -> (out: T) where IS_ARRAY(T), IS_FLOAT(ELEM_TYPE(T)) {
	b := N * (2 * dot(N, I))
	return I - b
}
refract :: proc "contextless" (I, N: $T) -> (out: T) where IS_ARRAY(T), IS_FLOAT(ELEM_TYPE(T)) {
	dv := dot(N, I)
	k := 1 - eta*eta - (1 - dv*dv)
	a := I * eta
	b := N * eta*dv*math.sqrt(k)
	return (a - b) * E(int(k >= 0))
}




is_nan_single :: proc "contextless" (x: $T) -> bool where IS_FLOAT(T) {
	return #force_inline math.is_nan(x)
}

is_nan_array :: proc "contextless" (x: $A/[$N]$T) -> (out: [N]bool) where IS_FLOAT(T) {
	for i in 0..<N {
		out[i] = #force_inline is_nan(x[i])
	}
	return
}

is_inf_single :: proc "contextless" (x: $T) -> bool where IS_FLOAT(T) {
	return #force_inline math.is_inf(x)
}

is_inf_array :: proc "contextless" (x: $A/[$N]$T) -> (out: [N]bool) where IS_FLOAT(T) {
	for i in 0..<N {
		out[i] = #force_inline is_inf(x[i])
	}
	return
}

classify_single :: proc "contextless" (x: $T) -> math.Float_Class where IS_FLOAT(T) {
	return #force_inline math.classify(x)
}

classify_array :: proc "contextless" (x: $A/[$N]$T) -> (out: [N]math.Float_Class) where IS_FLOAT(T) {
	for i in 0..<N {
		out[i] = #force_inline classify_single(x[i])
	}
	return
}

is_nan :: proc{is_nan_single, is_nan_array}
is_inf :: proc{is_inf_single, is_inf_array}
classify :: proc{classify_single, classify_array}


less_than_single          :: proc "contextless" (x, y: $T) -> (out: bool) where !IS_ARRAY(T), IS_FLOAT(T) { return x < y }
less_than_equal_single    :: proc "contextless" (x, y: $T) -> (out: bool) where !IS_ARRAY(T), IS_FLOAT(T) { return x <= y }
greater_than_single       :: proc "contextless" (x, y: $T) -> (out: bool) where !IS_ARRAY(T), IS_FLOAT(T) { return x > y }
greater_than_equal_single :: proc "contextless" (x, y: $T) -> (out: bool) where !IS_ARRAY(T), IS_FLOAT(T) { return x >= y }
equal_single              :: proc "contextless" (x, y: $T) -> (out: bool) where !IS_ARRAY(T), IS_FLOAT(T) { return x == y }
not_equal_single          :: proc "contextless" (x, y: $T) -> (out: bool) where !IS_ARRAY(T), IS_FLOAT(T) { return x != y }

less_than_array :: proc "contextless" (x, y: $A/[$N]$T) -> (out: [N]bool) where IS_ARRAY(A), IS_FLOAT(ELEM_TYPE(A)) {
	for i in 0..<N {
		out[i] = x[i] < y[i]
	}
	return
}
less_than_equal_array :: proc "contextless" (x, y: $A/[$N]$T) -> (out: [N]bool) where IS_ARRAY(A), IS_FLOAT(ELEM_TYPE(A)) {
	for i in 0..<N {
		out[i] = x[i] <= y[i]
	}
	return
}
greater_than_array :: proc "contextless" (x, y: $A/[$N]$T) -> (out: [N]bool) where IS_ARRAY(A), IS_FLOAT(ELEM_TYPE(A)) {
	for i in 0..<N {
		out[i] = x[i] > y[i]
	}
	return
}
greater_than_equal_array :: proc "contextless" (x, y: $A/[$N]$T) -> (out: [N]bool) where IS_ARRAY(A), IS_FLOAT(ELEM_TYPE(A)) {
	for i in 0..<N {
		out[i] = x[i] >= y[i]
	}
	return
}
equal_array :: proc "contextless" (x, y: $A/[$N]$T) -> (out: [N]bool) where IS_ARRAY(A), IS_FLOAT(ELEM_TYPE(A)) {
	for i in 0..<N {
		out[i] = x[i] == y[i]
	}
	return
}
not_equal_array :: proc "contextless" (x, y: $A/[$N]$T) -> (out: [N]bool) where IS_ARRAY(A), IS_FLOAT(ELEM_TYPE(A)) {
	for i in 0..<N {
		out[i] = x[i] != y[i]
	}
	return
}

less_than          :: proc{less_than_single, less_than_array}
less_than_equal    :: proc{less_than_equal_single, less_than_equal_array}
greater_than       :: proc{greater_than_single, greater_than_array}
greater_than_equal :: proc{greater_than_equal_single, greater_than_equal_array}
equal              :: proc{equal_single, equal_array}
not_equal          :: proc{not_equal_single, not_equal_array}

any :: proc "contextless" (x: $A/[$N]bool) -> (out: bool) {
	for e in x {
		if x {
			return true
		}
	}
	return false
}
all :: proc "contextless" (x: $A/[$N]bool) -> (out: bool) {
	for e in x {
		if !e {
			return false
		}
	}
	return true
}
not :: proc "contextless" (x: $A/[$N]bool) -> (out: A) {
	for e, i in x {
		out[i] = !e
	}
	return
}
