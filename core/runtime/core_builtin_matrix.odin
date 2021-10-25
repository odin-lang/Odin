package runtime

import "core:intrinsics"
_ :: intrinsics


@(builtin)
determinant :: proc{
	matrix1x1_determinant,
	matrix2x2_determinant,
	matrix3x3_determinant,
	matrix4x4_determinant,
}

@(builtin)
adjugate :: proc{
	matrix1x1_adjugate,
	matrix2x2_adjugate,
	matrix3x3_adjugate,
	matrix4x4_adjugate,
}

@(builtin)
inverse_transpose :: proc{
	matrix1x1_inverse_transpose,
	matrix2x2_inverse_transpose,
	matrix3x3_inverse_transpose,
	matrix4x4_inverse_transpose,
}


@(builtin)
inverse :: proc{
	matrix1x1_inverse,
	matrix2x2_inverse,
	matrix3x3_inverse,
	matrix4x4_inverse,
}

@(builtin)
hermitian_adjoint :: proc{
	matrix1x1_hermitian_adjoint,
	matrix2x2_hermitian_adjoint,
	matrix3x3_hermitian_adjoint,
	matrix4x4_hermitian_adjoint,
}

@(builtin)
matrix1x1_determinant :: proc(m: $M/matrix[1, 1]$T) -> (det: T) {
	return m[0, 0]
}

@(builtin)
matrix2x2_determinant :: proc(m: $M/matrix[2, 2]$T) -> (det: T) {
	return m[0, 0]*m[1, 1] - m[0, 1]*m[1, 0]
}
@(builtin)
matrix3x3_determinant :: proc(m: $M/matrix[3, 3]$T) -> (det: T) {
	a := +m[0, 0] * (m[1, 1] * m[2, 2] - m[1, 2] * m[2, 1])
	b := -m[0, 1] * (m[1, 0] * m[2, 2] - m[1, 2] * m[2, 0])
	c := +m[0, 2] * (m[1, 0] * m[2, 1] - m[1, 1] * m[2, 0])
	return a + b + c
}
@(builtin)
matrix4x4_determinant :: proc(m: $M/matrix[4, 4]$T) -> (det: T) {
	a := adjugate(m)
	#no_bounds_check for i in 0..<4 {
		det += m[0, i] * a[0, i]
	}
	return
}




@(builtin)
matrix1x1_adjugate :: proc(x: $M/matrix[1, 1]$T) -> (y: M) {
	y = x
	return
}

@(builtin)
matrix2x2_adjugate :: proc(x: $M/matrix[2, 2]$T) -> (y: M) {
	y[0, 0] = +x[1, 1]
	y[0, 1] = -x[1, 0]
	y[1, 0] = -x[0, 1]
	y[1, 1] = +x[0, 0]
	return
}

@(builtin)
matrix3x3_adjugate :: proc(m: $M/matrix[3, 3]$T) -> (y: M) {
	y[0, 0] = +(m[1, 1] * m[2, 2] - m[2, 1] * m[1, 2])
	y[0, 1] = -(m[1, 0] * m[2, 2] - m[2, 0] * m[1, 2])
	y[0, 2] = +(m[1, 0] * m[2, 1] - m[2, 0] * m[1, 1])
	y[1, 0] = -(m[0, 1] * m[2, 2] - m[2, 1] * m[0, 2])
	y[1, 1] = +(m[0, 0] * m[2, 2] - m[2, 0] * m[0, 2])
	y[1, 2] = -(m[0, 0] * m[2, 1] - m[2, 0] * m[0, 1])
	y[2, 0] = +(m[0, 1] * m[1, 2] - m[1, 1] * m[0, 2])
	y[2, 1] = -(m[0, 0] * m[1, 2] - m[1, 0] * m[0, 2])
	y[2, 2] = +(m[0, 0] * m[1, 1] - m[1, 0] * m[0, 1])
	return
}

@(builtin)
matrix4x4_adjugate :: proc(x: $M/matrix[4, 4]$T) -> (y: M) {
	minor :: proc(m: $M/matrix[4, 4]$T, row, column: i32) -> (minor: T) {
		cut_down: matrix[3, 3]T
		for col_idx in 0..<3 {
			col := col_idx + int(col_idx >= column)
			for row_idx in 0..<3 {
				row := row_idx + int(row_idx >= row)
				cut_down[row_idx, col_idx] = m[row, col]
			}
		}
		return determinant(cut_down)
	}
	cofactor :: proc(m: $M/matrix[4, 4]$T, row, column: i32) -> (cofactor: T) {	
		sign: T = 1 if (row + column) % 2 == 0 else -1
		return sign * minor(m, row, column)
	}
	
	for i in 0..<4 {
		for j in 0..<4 {
			y[i, j] = cofactor(x, i, j)
		}
	}
	return
}

@(builtin)
matrix1x1_inverse_transpose :: proc(x: $M/matrix[1, 1]$T) -> (y: M) {
	y[0, 0] = 1/x[0, 0]
	return
}

@(builtin)
matrix2x2_inverse_transpose :: proc(x: $M/matrix[2, 2]$T) -> (y: M) {
	d := x[0, 0]*x[1, 1] - x[0, 1]*x[1, 0]
	when intrinsics.type_is_integer(T) {
		y[0, 0] = +x[1, 1] / d
		y[1, 0] = -x[1, 0] / d
		y[0, 1] = -x[0, 1] / d
		y[1, 1] = +x[0, 0] / d
	} else {
		id := 1 / d
		y[0, 0] = +x[1, 1] * id
		y[1, 0] = -x[1, 0] * id
		y[0, 1] = -x[0, 1] * id
		y[1, 1] = +x[0, 0] * id
	}
	return
}

@(builtin)
matrix3x3_inverse_transpose :: proc(x: $M/matrix[3, 3]$T) -> (y: M) #no_bounds_check {
	a := adjugate(x)
	d := determinant(x)
	when intrinsics.type_is_integer(T) {
		for i in 0..<3 {
			for j in 0..<3 {
				inverse_transpose[i, j] = a[i, j] / d
			}
		}
	} else {
		id := 1/d
		for i in 0..<3 {
			for j in 0..<3 {
				inverse_transpose[i, j] = a[i, j] * id
			}
		}
	}
	return
}

@(builtin)
matrix4x4_inverse_transpose :: proc(x: $M/matrix[4, 4]$T) -> (y: M) #no_bounds_check {
	a := adjugate(x)
	d: T
	for i in 0..<4 {
		d += x[0, i] * a[0, i]
	}
	when intrinsics.type_is_integer(T) {
		for i in 0..<4 {
			for j in 0..<4 {
				inverse_transpose[i, j] = a[i, j] / d
			}
		}
	} else {
		id := 1/d
		for i in 0..<4 {
			for j in 0..<4 {
				inverse_transpose[i, j] = a[i, j] * id
			}
		}
	}
	return
}

@(builtin)
matrix1x1_inverse :: proc(x: $M/matrix[1, 1]$T) -> (y: M) {
	y[0, 0] = 1/x[0, 0]
	return
}

@(builtin)
matrix2x2_inverse :: proc(x: $M/matrix[2, 2]$T) -> (y: M) {
	d := x[0, 0]*x[1, 1] - x[0, 1]*x[1, 0]
	when intrinsics.type_is_integer(T) {
		y[0, 0] = x[1, 1] / d
		y[0, 1] = x[1, 0] / d
		y[1, 0] = x[0, 1] / d
		y[1, 1] = x[0, 0] / d
	} else {
		id := 1 / d
		y[0, 0] = x[1, 1] * id
		y[0, 1] = x[1, 0] * id
		y[1, 0] = x[0, 1] * id
		y[1, 1] = x[0, 0] * id
	}
	return
}

@(builtin)
matrix3x3_inverse :: proc(x: $M/matrix[3, 3]$T) -> (y: M) #no_bounds_check {
	a := adjugate(x)
	d := determinant(x)
	when intrinsics.type_is_integer(T) {
		for i in 0..<3 {
			for j in 0..<3 {
				inverse_transpose[i, j] = a[j, i] / d
			}
		}
	} else {
		id := 1/d
		for i in 0..<3 {
			for j in 0..<3 {
				inverse_transpose[i, j] = a[j, i] * id
			}
		}
	}
	return
}

@(builtin)
matrix4x4_inverse :: proc(x: $M/matrix[4, 4]$T) -> (y: M) #no_bounds_check {
	a := adjugate(x)
	d: T
	for i in 0..<4 {
		d += x[0, i] * a[0, i]
	}
	when intrinsics.type_is_integer(T) {
		for i in 0..<4 {
			for j in 0..<4 {
				inverse_transpose[i, j] = a[j, i] / d
			}
		}
	} else {
		id := 1/d
		for i in 0..<4 {
			for j in 0..<4 {
				inverse_transpose[i, j] = a[j, i] * id
			}
		}
	}
	return
}


@(builtin)
matrix1x1_hermitian_adjoint :: proc(m: $M/matrix[1, 1]$T) -> M where intrinsics.type_is_complex(T) {
	return conj(transpose(m))
}
@(builtin)
matrix2x2_hermitian_adjoint :: proc(m: $M/matrix[2, 2]$T) -> M where intrinsics.type_is_complex(T) {
	return conj(transpose(m))
}
@(builtin)
matrix3x3_hermitian_adjoint :: proc(m: $M/matrix[3, 3]$T) -> M where intrinsics.type_is_complex(T) {
	return conj(transpose(m))
}
@(builtin)
matrix4x4_hermitian_adjoint :: proc(m: $M/matrix[4, 4]$T) -> M where intrinsics.type_is_complex(T) {
	return conj(transpose(m))
}

