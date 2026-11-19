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

SEED_4 :: 0
SEED_5 :: -1
SEED_6 :: 1
SEED_7 :: max(i64)
SEED_8 :: min(i64)
SEED_9 :: 6022140857

COORD_4 :: V4{0.5, 0.5, 0.5, 0.5}
COORD_5 :: V4{-0.25, 1.75, -3.5, 2.125}
COORD_6 :: V4{-71.3, 15.62, -8.04, 33.9}
COORD_7 :: V4{1234.5678, -9876.54321, 0.001, -0.001}
COORD_8 :: V4{3, -7, 11, -13}
COORD_9 :: V4{0.1, 0.2, 0.3, 0.4}

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

@(test)
test_noise_2d_reference :: proc(t: ^testing.T) {
	test(t, {SEED_4, COORD_4.xy, 0h3da59d04, noise.noise_2d})
	test(t, {SEED_5, COORD_5.xy, 0h3f65ab43, noise.noise_2d})
	test(t, {SEED_6, COORD_6.xy, 0h3f6fda92, noise.noise_2d})
	test(t, {SEED_7, COORD_7.xy, 0h3f32123e, noise.noise_2d})
	test(t, {SEED_8, COORD_8.xy, 0hbe0754b9, noise.noise_2d})
	test(t, {SEED_9, COORD_9.xy, 0h3f660ef3, noise.noise_2d})

	test(t, {SEED_4, COORD_4.xy, 0hbf1aeb25, noise.noise_2d_improve_x})
	test(t, {SEED_5, COORD_5.xy, 0h3d47600b, noise.noise_2d_improve_x})
	test(t, {SEED_6, COORD_6.xy, 0hbf33ef98, noise.noise_2d_improve_x})
	test(t, {SEED_7, COORD_7.xy, 0hbefb5d66, noise.noise_2d_improve_x})
	test(t, {SEED_8, COORD_8.xy, 0h3e8c5c51, noise.noise_2d_improve_x})
	test(t, {SEED_9, COORD_9.xy, 0h3f42bedf, noise.noise_2d_improve_x})
}

@(test)
test_noise_3d_reference :: proc(t: ^testing.T) {
	test(t, {SEED_4, COORD_4.xyz, 0h3f4d3add, noise.noise_3d_improve_xy})
	test(t, {SEED_5, COORD_5.xyz, 0hbf051c9e, noise.noise_3d_improve_xy})
	test(t, {SEED_6, COORD_6.xyz, 0hbe7fb768, noise.noise_3d_improve_xy})
	test(t, {SEED_7, COORD_7.xyz, 0hbeb91472, noise.noise_3d_improve_xy})
	test(t, {SEED_8, COORD_8.xyz, 0h3eae3601, noise.noise_3d_improve_xy})
	test(t, {SEED_9, COORD_9.xyz, 0hbddcc896, noise.noise_3d_improve_xy})

	test(t, {SEED_4, COORD_4.xyz, 0hbf19d613, noise.noise_3d_improve_xz})
	test(t, {SEED_5, COORD_5.xyz, 0h3eda6e0d, noise.noise_3d_improve_xz})
	test(t, {SEED_6, COORD_6.xyz, 0hbe688114, noise.noise_3d_improve_xz})
	test(t, {SEED_7, COORD_7.xyz, 0hbdef8722, noise.noise_3d_improve_xz})
	test(t, {SEED_8, COORD_8.xyz, 0h3ecf7f10, noise.noise_3d_improve_xz})
	test(t, {SEED_9, COORD_9.xyz, 0h3e4c4496, noise.noise_3d_improve_xz})

	test(t, {SEED_4, COORD_4.xyz, 0h00000000, noise.noise_3d_fallback})
	test(t, {SEED_5, COORD_5.xyz, 0h3d9225fe, noise.noise_3d_fallback})
	test(t, {SEED_6, COORD_6.xyz, 0h3e83d519, noise.noise_3d_fallback})
	test(t, {SEED_7, COORD_7.xyz, 0h3e9d70fc, noise.noise_3d_fallback})
	test(t, {SEED_8, COORD_8.xyz, 0hbe47dbf8, noise.noise_3d_fallback})
	test(t, {SEED_9, COORD_9.xyz, 0h3db1f09f, noise.noise_3d_fallback})
}

@(test)
test_noise_4d_reference :: proc(t: ^testing.T) {
	test(t, {SEED_4, COORD_4, 0hbe3a6993, noise.noise_4d_improve_xyz_improve_xy})
	test(t, {SEED_5, COORD_5, 0h3d2090a9, noise.noise_4d_improve_xyz_improve_xy})
	test(t, {SEED_6, COORD_6, 0h3db303a0, noise.noise_4d_improve_xyz_improve_xy})
	test(t, {SEED_7, COORD_7, 0h3eb13d80, noise.noise_4d_improve_xyz_improve_xy})
	test(t, {SEED_8, COORD_8, 0hbdfbb33e, noise.noise_4d_improve_xyz_improve_xy})
	test(t, {SEED_9, COORD_9, 0hbdb924ef, noise.noise_4d_improve_xyz_improve_xy})

	test(t, {SEED_4, COORD_4, 0hbe0b81f5, noise.noise_4d_improve_xyz_improve_xz})
	test(t, {SEED_5, COORD_5, 0hbf000367, noise.noise_4d_improve_xyz_improve_xz})
	test(t, {SEED_6, COORD_6, 0hbe815a26, noise.noise_4d_improve_xyz_improve_xz})
	test(t, {SEED_7, COORD_7, 0h3c38fed3, noise.noise_4d_improve_xyz_improve_xz})
	test(t, {SEED_8, COORD_8, 0hbe9c0a5d, noise.noise_4d_improve_xyz_improve_xz})
	test(t, {SEED_9, COORD_9, 0hbdf5cfff, noise.noise_4d_improve_xyz_improve_xz})

	test(t, {SEED_4, COORD_4, 0hbf478cb9, noise.noise_4d_improve_xyz})
	test(t, {SEED_5, COORD_5, 0hbe14f5cf, noise.noise_4d_improve_xyz})
	test(t, {SEED_6, COORD_6, 0hbdfd913d, noise.noise_4d_improve_xyz})
	test(t, {SEED_7, COORD_7, 0hbe227f44, noise.noise_4d_improve_xyz})
	test(t, {SEED_8, COORD_8, 0hbe9f2016, noise.noise_4d_improve_xyz})
	test(t, {SEED_9, COORD_9, 0hbe3095c4, noise.noise_4d_improve_xyz})

	test(t, {SEED_4, COORD_4, 0hbd8f8f54, noise.noise_4d_improve_xy_improve_zw})
	test(t, {SEED_5, COORD_5, 0h3ead4cc9, noise.noise_4d_improve_xy_improve_zw})
	test(t, {SEED_6, COORD_6, 0hbed5cbd6, noise.noise_4d_improve_xy_improve_zw})
	test(t, {SEED_7, COORD_7, 0hbe3f74e4, noise.noise_4d_improve_xy_improve_zw})
	test(t, {SEED_8, COORD_8, 0hbcde5e2c, noise.noise_4d_improve_xy_improve_zw})
	test(t, {SEED_9, COORD_9, 0hbd4bd2e7, noise.noise_4d_improve_xy_improve_zw})

	test(t, {SEED_4, COORD_4, 0h3ea2640b, noise.noise_4d_fallback})
	test(t, {SEED_5, COORD_5, 0hbe11381b, noise.noise_4d_fallback})
	test(t, {SEED_6, COORD_6, 0h3d2abe85, noise.noise_4d_fallback})
	test(t, {SEED_7, COORD_7, 0h3e98b978, noise.noise_4d_fallback})
	test(t, {SEED_8, COORD_8, 0hbe2d9546, noise.noise_4d_fallback})
	test(t, {SEED_9, COORD_9, 0h3e782e4e, noise.noise_4d_fallback})
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