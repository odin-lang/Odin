package test_internal

import "base:intrinsics"
import "core:testing"

// Matrices whose column (row if #row_major) stride is a multiple of 16 bytes go through the SIMD lowering.

@(test)
test_matrix_simd_mul :: proc(t: ^testing.T) {
	check :: proc(t: ^testing.T, $R, $K, $C: int, $T: typeid, $ROW_MAJOR: bool) {
		when ROW_MAJOR {
			A :: #row_major matrix[R, K]T
			B :: #row_major matrix[K, C]T
			P :: #row_major matrix[R, C]T
		} else {
			A :: matrix[R, K]T
			B :: matrix[K, C]T
			P :: matrix[R, C]T
		}

		a: A
		b: B
		for i in 0..<R {
			for k in 0..<K {
				a[i, k] = T(i*K + k)
			}
		}
		for k in 0..<K {
			for j in 0..<C {
				b[k, j] = T(k*C + j + 1)
			}
		}
		a0, b0 := a, b

		p: P = a * b
		for i in 0..<R {
			for j in 0..<C {
				s: T
				for k in 0..<K {
					s += a0[i, k]*b0[k, j]
				}
				testing.expectf(t, p[i, j] == s, "%v * %v: [%d, %d] = %v, expected %v", typeid_of(A), typeid_of(B), i, j, p[i, j], s)
			}
		}
		testing.expectf(t, a == a0, "%v * %v changed its left operand", typeid_of(A), typeid_of(B))
		testing.expectf(t, b == b0, "%v * %v changed its right operand", typeid_of(A), typeid_of(B))
	}

	check(t, 4, 4, 4, f32, false)
	check(t, 4, 4, 4, f32, true)
	check(t, 8, 8, 8, f32, false)
	check(t, 8, 8, 8, f32, true)
	check(t, 2, 2, 2, f64, false)
	check(t, 2, 2, 2, f64, true)
	check(t, 4, 4, 4, f64, false)
	check(t, 4, 4, 4, f64, true)
	check(t, 6, 6, 6, f64, false)
	check(t, 6, 6, 6, f64, true)
	check(t, 8, 8, 8, f64, false)
	check(t, 8, 8, 8, f64, true)
	check(t, 6, 6, 6, i64, false)
	check(t, 6, 6, 6, i64, true)

	check(t, 2, 4, 3, f64, false)
	check(t, 2, 4, 3, f64, true)
	check(t, 4, 8, 1, f64, false)
	check(t, 4, 8, 1, f64, true)
	check(t, 4, 8, 6, f32, false)
	check(t, 4, 8, 6, f32, true)
	check(t, 6, 2, 8, f64, false)
	check(t, 6, 2, 8, f64, true)
}

@(test)
test_matrix_simd_transpose :: proc(t: ^testing.T) {
	check :: proc(t: ^testing.T, $R, $C: int, $T: typeid, $ROW_MAJOR: bool) {
		when ROW_MAJOR {
			M :: #row_major matrix[R, C]T
		} else {
			M :: matrix[R, C]T
		}

		m: M
		for i in 0..<R {
			for j in 0..<C {
				m[i, j] = T(i*C + j)
			}
		}

		mt := intrinsics.transpose(m)
		for i in 0..<R {
			for j in 0..<C {
				testing.expectf(t, mt[j, i] == m[i, j], "transpose(%v): [%d, %d] = %v, expected %v", typeid_of(M), j, i, mt[j, i], m[i, j])
			}
		}
	}

	check(t, 4, 4, f32, false)
	check(t, 4, 4, f32, true)
	check(t, 4, 8, f32, false)
	check(t, 4, 8, f32, true)
	check(t, 8, 4, f32, false)
	check(t, 8, 4, f32, true)
	check(t, 2, 4, f64, false)
	check(t, 2, 4, f64, true)
	check(t, 6, 6, f64, false)
	check(t, 6, 6, f64, true)
	check(t, 2, 8, f64, false)
	check(t, 2, 8, f64, true)
}
