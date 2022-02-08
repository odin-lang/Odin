package test_core_math_noise

import "core:testing"
import "core:math/noise"
import "core:fmt"

TEST_count := 0
TEST_fail  := 0

V2 :: noise.Vec2
V3 :: noise.Vec3
V4 :: noise.Vec4

when ODIN_TEST {
    expect  :: testing.expect
    log     :: testing.log
} else {
    expect  :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) {
        fmt.printf("[%v] ", loc)
        TEST_count += 1
        if !condition {
            TEST_fail += 1
            fmt.println(message)
            return
        }
        fmt.println(" PASS")
    }
    log     :: proc(t: ^testing.T, v: any, loc := #caller_location) {
        fmt.printf("[%v] ", loc)
        fmt.printf("log: %v\n", v)
    }
}

main :: proc() {
	t := testing.T{}
	noise_test(&t)
	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
}

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

SEED_1 :: 2324223232
SEED_2 :: 932466901
SEED_3 :: 9321

COORD_1 :: V4{  242.0,  3433.0,      920.0,    222312.0}
COORD_2 :: V4{  590.0,  9411.0,     5201.0, 942124256.0}
COORD_3 :: V4{12090.0, 19411.0, 81950901.0,   4224219.0}

Noise_Tests := []Test_Vector{
	/*
		`noise_2d` tests.
	*/
	{SEED_1, COORD_1.xy,   0.25010583,  noise.noise_2d},
	{SEED_2, COORD_2.xy,  -0.92513955,  noise.noise_2d},
	{SEED_3, COORD_3.xy,   0.67327416,  noise.noise_2d},

	/*
		`noise_2d_improve_x` tests.
	*/
	{SEED_1, COORD_1.xy,   0.17074019,  noise.noise_2d_improve_x},
	{SEED_2, COORD_2.xy,   0.72330487,  noise.noise_2d_improve_x},
	{SEED_3, COORD_3.xy,  -0.032076947, noise.noise_2d_improve_x},

	/*
		`noise_3d_improve_xy` tests.
	*/
	{SEED_1, COORD_1.xyz,  0.14819577,  noise.noise_3d_improve_xy},
	{SEED_2, COORD_2.xyz, -0.065345764, noise.noise_3d_improve_xy},
	{SEED_3, COORD_3.xyz, -0.37761918,  noise.noise_3d_improve_xy},

	/*
		`noise_3d_improve_xz` tests.
	*/
	{SEED_1, COORD_1.xyz, -0.50075006,  noise.noise_3d_improve_xz},
	{SEED_2, COORD_2.xyz, -0.36039603,  noise.noise_3d_improve_xz},
	{SEED_3, COORD_3.xyz, -0.3479203,   noise.noise_3d_improve_xz},

	/*
		`noise_3d_fallback` tests.
	*/
	{SEED_1, COORD_1.xyz,  0.6557345,   noise.noise_3d_fallback},
	{SEED_2, COORD_2.xyz,  0.55452216,  noise.noise_3d_fallback},
	{SEED_3, COORD_3.xyz, -0.26408964,  noise.noise_3d_fallback},

	/*
		`noise_3d_fallback` tests.
	*/
	{SEED_1, COORD_1.xyz,  0.6557345,   noise.noise_3d_fallback},
	{SEED_2, COORD_2.xyz,  0.55452216,  noise.noise_3d_fallback},
	{SEED_3, COORD_3.xyz, -0.26408964,  noise.noise_3d_fallback},

	/*
		`noise_4d_improve_xyz_improve_xy` tests.
	*/
	{SEED_1, COORD_1,      0.44929826,  noise.noise_4d_improve_xyz_improve_xy},
	{SEED_2, COORD_2,     -0.13270882,  noise.noise_4d_improve_xyz_improve_xy},
	{SEED_3, COORD_3,      0.10298563,  noise.noise_4d_improve_xyz_improve_xy},

	/*
		`noise_4d_improve_xyz_improve_xz` tests.
	*/
	{SEED_1, COORD_1,    -0.078514606,  noise.noise_4d_improve_xyz_improve_xz},
	{SEED_2, COORD_2,    -0.032157656,  noise.noise_4d_improve_xyz_improve_xz},
	{SEED_3, COORD_3,     -0.38607058,  noise.noise_4d_improve_xyz_improve_xz},

	/*
		`noise_4d_improve_xyz` tests.
	*/
	{SEED_1, COORD_1,      -0.4442258,  noise.noise_4d_improve_xyz},
	{SEED_2, COORD_2,      0.36822623,  noise.noise_4d_improve_xyz},
	{SEED_3, COORD_3,      0.22628775,  noise.noise_4d_improve_xyz},

	/*
		`noise_4d_fallback` tests.
	*/
	{SEED_1, COORD_1,     -0.14233987,  noise.noise_4d_fallback},
	{SEED_2, COORD_2,      0.1354035,  noise.noise_4d_fallback},
	{SEED_3, COORD_3,      0.14565045,  noise.noise_4d_fallback},

	// TODO: Output according to C# - Figure out which of these two is right (and why).
	// {SEED_1, COORD_1,     -0.14233987,  noise.noise_4d_fallback},
	// {SEED_2, COORD_2,      0.1354035,   noise.noise_4d_fallback},
	// {SEED_3, COORD_3,      0.14565045,  noise.noise_4d_fallback},
}

noise_test :: proc(t: ^testing.T) {
	for test in Noise_Tests {
		output: f32

		switch coord in test.coord {
		case V2:
			output = test.test_proc.(proc(_: i64, _: V2) -> f32)(test.seed, test.coord.(V2))
		case V3:
			output = test.test_proc.(proc(_: i64, _: V3) -> f32)(test.seed, test.coord.(V3))
		case V4:
			output = test.test_proc.(proc(_: i64, _: V4) -> f32)(test.seed, test.coord.(V4))
		}
	
		error  := fmt.tprintf("Seed %v, Coord: %v, Expected: %3.8f. Got %3.8f", test.seed, test.coord, test.expected, output)
		expect(t, test.expected == output, error)
	}
}