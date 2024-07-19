package test_core_math_noise

import "core:testing"
import "core:math/noise"

Test_Vector :: struct {
	seed:      i64,
	coord:     union {V2, V3, V4},
	expected:  f32,

	test_proc: union {
		proc(_: i64, _: V2) -> f32,
		proc(_: i64, _: V3) -> f32,
		proc(_: i64, _: V4) -> f32,
	},
}

V2 :: noise.Vec2
V3 :: noise.Vec3
V4 :: noise.Vec4

SEED_1 :: 2324223232
SEED_2 :: 932466901
SEED_3 :: 9321

COORD_1 :: V4{  242.0,  3433.0,      920.0,    222312.0}
COORD_2 :: V4{  590.0,  9411.0,     5201.0, 942124256.0}
COORD_3 :: V4{12090.0, 19411.0, 81950901.0,   4224219.0}

@(test)
test_noise_2d :: proc(t: ^testing.T) {
	test(t, {SEED_1, COORD_1.xy,   0.25010583,  noise.noise_2d})
	test(t, {SEED_2, COORD_2.xy,  -0.92513955,  noise.noise_2d})
	test(t, {SEED_3, COORD_3.xy,   0.67327416,  noise.noise_2d})
}

@(test)
test_noise_2d_improve_x :: proc(t: ^testing.T) {
	test(t, {SEED_1, COORD_1.xy,   0.17074019,  noise.noise_2d_improve_x})
	test(t, {SEED_2, COORD_2.xy,   0.72330487,  noise.noise_2d_improve_x})
	test(t, {SEED_3, COORD_3.xy,  -0.032076947, noise.noise_2d_improve_x})
}

@(test)
test_noise_3d_improve_xy :: proc(t: ^testing.T) {
	test(t, {SEED_1, COORD_1.xyz,  0.14819577,  noise.noise_3d_improve_xy})
	test(t, {SEED_2, COORD_2.xyz, -0.065345764, noise.noise_3d_improve_xy})
	test(t, {SEED_3, COORD_3.xyz, -0.37761918,  noise.noise_3d_improve_xy})
}

@(test)
test_noise_3d_improve_xz :: proc(t: ^testing.T) {
	test(t, {SEED_1, COORD_1.xyz, -0.50075006,  noise.noise_3d_improve_xz})
	test(t, {SEED_2, COORD_2.xyz, -0.36039603,  noise.noise_3d_improve_xz})
	test(t, {SEED_3, COORD_3.xyz, -0.3479203,   noise.noise_3d_improve_xz})
}

@(test)
test_noise_3d_fallback :: proc(t: ^testing.T) {
	test(t, {SEED_1, COORD_1.xyz,  0.6557345,   noise.noise_3d_fallback})
	test(t, {SEED_2, COORD_2.xyz,  0.55452216,  noise.noise_3d_fallback})
	test(t, {SEED_3, COORD_3.xyz, -0.26408964,  noise.noise_3d_fallback})
}

@(test)
test_noise_4d_improve_xyz_improve_xy :: proc(t: ^testing.T) {
	test(t, {SEED_1, COORD_1,      0.44929826,  noise.noise_4d_improve_xyz_improve_xy})
	test(t, {SEED_2, COORD_2,     -0.13270882,  noise.noise_4d_improve_xyz_improve_xy})
	test(t, {SEED_3, COORD_3,      0.10298563,  noise.noise_4d_improve_xyz_improve_xy})
}

@(test)
test_noise_4d_improve_xyz_improve_xz :: proc(t: ^testing.T) {
	test(t, {SEED_1, COORD_1,    -0.078514606,  noise.noise_4d_improve_xyz_improve_xz})
	test(t, {SEED_2, COORD_2,    -0.032157656,  noise.noise_4d_improve_xyz_improve_xz})
	test(t, {SEED_3, COORD_3,     -0.38607058,  noise.noise_4d_improve_xyz_improve_xz})
}

@(test)
test_noise_4d_improve_xyz :: proc(t: ^testing.T) {
	test(t, {SEED_1, COORD_1,      -0.4442258,  noise.noise_4d_improve_xyz})
	test(t, {SEED_2, COORD_2,      0.36822623,  noise.noise_4d_improve_xyz})
	test(t, {SEED_3, COORD_3,      0.22628775,  noise.noise_4d_improve_xyz})
}

@(test)
test_noise_4d_fallback :: proc(t: ^testing.T) {
	test(t, {SEED_1, COORD_1,     -0.14233987,  noise.noise_4d_fallback})
	test(t, {SEED_2, COORD_2,      0.1354035,   noise.noise_4d_fallback})
	test(t, {SEED_3, COORD_3,      0.14565045,  noise.noise_4d_fallback})
}

test :: proc(t: ^testing.T, test: Test_Vector) {
	output: f32
	switch coord in test.coord {
	case V2:
		output = test.test_proc.(proc(_: i64, _: V2) -> f32)(test.seed, test.coord.(V2))
	case V3:
		output = test.test_proc.(proc(_: i64, _: V3) -> f32)(test.seed, test.coord.(V3))
	case V4:
		output = test.test_proc.(proc(_: i64, _: V4) -> f32)(test.seed, test.coord.(V4))
	}
	testing.expectf(t, test.expected == output, "Seed %v, Coord: %v, Expected: %3.8f. Got %3.8f", test.seed, test.coord, test.expected, output)
}