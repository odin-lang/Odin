package orca

import "core:math"

// TODO use orcas or native?

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	mat2x3_mul_m :: proc(lhs, rhs: mat2x3) -> mat2x3 ---
	mat2x3_inv :: proc(x: mat2x3) -> mat2x3 ---
	mat2x3_mul :: proc(m: mat2x3, p: vec2) -> vec2 ---
	mat2x3_rotate :: proc(radians: f32) -> mat2x3 ---
	mat2x3_translate :: proc(x, y: f32) -> mat2x3 ---
}

// mat2x3_mul_m :: proc "contextless" (lhs, rhs: mat2x3) -> (res: mat2x3) {
// 	res[0] = lhs[0] * rhs[0] + lhs[1] * rhs[3]
// 	res[1] = lhs[0] * rhs[1] + lhs[1] * rhs[4]
// 	res[2] = lhs[0] * rhs[2] + lhs[1] * rhs[5] + lhs[2]
// 	res[3] = lhs[3] * rhs[0] + lhs[4] * rhs[3]
// 	res[4] = lhs[3] * rhs[1] + lhs[4] * rhs[4]
// 	res[5] = lhs[3] * rhs[2] + lhs[4] * rhs[5] + lhs[5]
// 	return
// }

// mat2x3_inv :: proc "contextless" (x: mat2x3) -> (res: mat2x3) {
// 	res[0] = x[4] / (x[0] * x[4] - x[1] * x[3])
// 	res[1] = x[1] / (x[1] * x[3] - x[0] * x[4])
// 	res[3] = x[3] / (x[1] * x[3] - x[0] * x[4])
// 	res[4] = x[0] / (x[0] * x[4] - x[1] * x[3])
// 	res[2] = -(x[2] * res[0] + x[5] * res[1])
// 	res[5] = -(x[2] * res[3] + x[5] * res[4])
// 	return
// }

// mat2x3_mul :: proc "contextless" (m: mat2x3, p: vec2) -> vec2 {
// 	return {
// 		p.x * m[0] + p.y * m[1] + m[2],
// 		p.x * m[3] + p.y * m[4] + m[5],
// 	}
// }

// mat2x3_rotate :: proc "contextless" (radians: f32) -> mat2x3 {
// 	sinRot := math.sin(radians)
// 	cosRot := math.cos(radians)
// 	rot := mat2x3 {
// 		cosRot, -sinRot, 0,
// 		sinRot, cosRot, 0,
// 	}
// 	return rot
// }

// mat2x3_translate :: proc "contextless" (x, y: f32) -> mat2x3 {
// 	return {
// 		1, 0, x,
// 		0, 1, y,
// 	}
// }
