package test_internal

import "core:testing"

// Float aggregates returned in registers: each result must come back exactly as the callee built it.
// On amd64 float data past two registers goes in 16-byte vectors in XMM0 to XMM3.
// On arm64 a homogeneous float aggregate of up to 128 bytes goes in vectors in V0 to V7.

@(private="file")
Vec3d :: struct {
	x, y, z: f64,
}

// An integer word, then float words starting at an odd eightbyte
@(private="file")
Tagged :: struct {
	tag: i64,
	v:   [3]f64,
}

// A 16-byte chunk holding two floats and a double
@(private="file")
Mixed :: struct {
	a, b: f32,
	c, d: f64,
}

@(private="file")
Xform :: struct {
	pos:   [3]f32,
	scale: f32,
	rot:   quaternion128,
}

@(private="file") ret_3f64  :: #force_no_inline proc(s: f64) -> [3]f64        { return {s, s+1, s+2} }
@(private="file") ret_6f32  :: #force_no_inline proc(s: f32) -> [6]f32        { return {s, s+1, s+2, s+3, s+4, s+5} }
@(private="file") ret_q256  :: #force_no_inline proc(s: f64) -> quaternion256 { return quaternion(w=s, x=s+1, y=s+2, z=s+3) }
@(private="file") ret_3c128 :: #force_no_inline proc(s: f64) -> [3]complex128 { return {complex(s, 1), complex(s, 2), complex(s, 3)} }
@(private="file") ret_vec3d :: #force_no_inline proc(s: f64) -> Vec3d         { return {s, s+1, s+2} }
@(private="file") ret_tag   :: #force_no_inline proc(s: f64) -> Tagged        { return {7, {s, s+1, s+2}} }
@(private="file") ret_mixed :: #force_no_inline proc(s: f64) -> Mixed         { return {f32(s), f32(s+1), s+2, s+3} }
@(private="file") ret_xform :: #force_no_inline proc(s: f32) -> Xform         { return {{s, s+1, s+2}, s+3, quaternion(w=s, x=1, y=2, z=3)} }

@(private="file")
ret_m44f32 :: #force_no_inline proc(s: f32) -> (m: matrix[4, 4]f32) {
	for i in 0..<4 {
		for j in 0..<4 {
			m[i, j] = s + f32(i*4 + j)
		}
	}
	return
}

@(private="file")
ret_m33f32 :: #force_no_inline proc(s: f32) -> (m: matrix[3, 3]f32) {
	for i in 0..<3 {
		for j in 0..<3 {
			m[i, j] = s + f32(i*3 + j)
		}
	}
	return
}

@(private="file")
ret_m44f64 :: #force_no_inline proc(s: f64) -> (m: matrix[4, 4]f64) {
	for i in 0..<4 {
		for j in 0..<4 {
			m[i, j] = s + f64(i*4 + j)
		}
	}
	return
}

@(private="file")
ret_16f16 :: #force_no_inline proc(s: f16) -> (r: [16]f16) {
	for &e, i in r {
		e = s + f16(i)
	}
	return
}

@(private="file")
ret_floats_ok :: #force_no_inline proc(s: f64) -> ([3]f64, bool) {
	return {s, s+1, s+2}, s > 0
}

@(private="file")
ret_matrix_int :: #force_no_inline proc(s: f32) -> (matrix[4, 4]f32, int) {
	return ret_m44f32(s), int(s)
}

@(test)
test_float_returns :: proc(t: ^testing.T) {
	d, f := 1.5, f32(2.25)

	testing.expect_value(t, ret_3f64(d),  [3]f64{d, d+1, d+2})
	testing.expect_value(t, ret_6f32(f),  [6]f32{f, f+1, f+2, f+3, f+4, f+5})
	testing.expect_value(t, ret_q256(d),  quaternion(w=d, x=d+1, y=d+2, z=d+3))
	testing.expect_value(t, ret_3c128(d), [3]complex128{complex(d, 1), complex(d, 2), complex(d, 3)})
	testing.expect_value(t, ret_vec3d(d), Vec3d{d, d+1, d+2})
	testing.expect_value(t, ret_tag(d),   Tagged{7, {d, d+1, d+2}})
	testing.expect_value(t, ret_mixed(d), Mixed{f32(d), f32(d+1), d+2, d+3})
	testing.expect_value(t, ret_xform(f), Xform{{f, f+1, f+2}, f+3, quaternion(w=f, x=1, y=2, z=3)})

	m44: matrix[4, 4]f32
	m33: matrix[3, 3]f32
	m44d: matrix[4, 4]f64
	for i in 0..<4 {
		for j in 0..<4 {
			m44[i, j]  = f + f32(i*4 + j)
			m44d[i, j] = d + f64(i*4 + j)
		}
	}
	for i in 0..<3 {
		for j in 0..<3 {
			m33[i, j] = f + f32(i*3 + j)
		}
	}
	testing.expect_value(t, ret_m44f32(f), m44)
	testing.expect_value(t, ret_m33f32(f), m33)
	testing.expect_value(t, ret_m44f64(d), m44d)

	h16: [16]f16
	for &e, i in h16 {
		e = 3 + f16(i)
	}
	testing.expect_value(t, ret_16f16(3), h16)

	v, ok := ret_floats_ok(d)
	testing.expect_value(t, v, [3]f64{d, d+1, d+2})
	testing.expect(t, ok)

	m, n := ret_matrix_int(f)
	testing.expect_value(t, m, m44)
	testing.expect_value(t, n, int(f))
}
