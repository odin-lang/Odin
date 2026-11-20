package test_core_math_noise

import "core:math/noise"
import "core:testing"

@(test)
test_noise_2d_matches_upstream :: proc(t: ^testing.T) {
	test(t, {596,                  V2{-76.29, -84.55}, -0.75474787, noise.noise_2d})
	test(t, {801,                  V2{  6.11, -88.96},  0.88714814, noise.noise_2d})
	test(t, {5354405683121439014,  V2{-41.97, -44.71},  0.9502458,  noise.noise_2d_improve_x})
	test(t, {-4871170550622980298, V2{ 36.73,  91.23}, -0.9258302,  noise.noise_2d_improve_x})
}

@(test)
test_noise_4d_matches_upstream :: proc(t: ^testing.T) {
	test(t, {6334433406424127541,  V4{ 71.0,   30.59, -14.93,  84.18}, -0.77621,    noise.noise_4d_improve_xyz_improve_xy})
	test(t, {789,                  V4{ 98.06,  -4.33,  71.94, -82.14}, -0.688594,   noise.noise_4d_improve_xyz_improve_xy})
	test(t, {4325520139877777767,  V4{-30.67, -49.76,  77.23, -14.32}, -0.794448,   noise.noise_4d_improve_xyz_improve_xz})
	test(t, {1035610539402611534,  V4{ 17.63, -48.75, -97.5,   -9.33},  0.8166532,  noise.noise_4d_improve_xyz_improve_xz})
	test(t, {-8477476643051326091, V4{ -7.76, -51.07,  95.01,  79.49}, -0.82100093, noise.noise_4d_improve_xyz})
	test(t, {-5671156733750256315, V4{ -6.54,  37.06, -27.8,   47.47}, -0.7446295,  noise.noise_4d_improve_xyz})
	test(t, {401,                  V4{ 48.18,  84.81,  66.94,  97.9 },  0.9336834,  noise.noise_4d_fallback})
	test(t, {9185295860997024408,  V4{-47.73,  25.87, -20.98,  52.09},  0.8793749,  noise.noise_4d_fallback})
}

@(test)
test_noise_4d_improve_xy_improve_zw :: proc(t: ^testing.T) {
	test(t, {4639160407840221765,  V4{ 55.53,   3.67, -42.46, -31.12},  0.9086987,  noise.noise_4d_improve_xy_improve_zw})
	test(t, {-3807046123034797143, V4{ 81.28, -85.91, -61.85, -57.71}, -0.90476674, noise.noise_4d_improve_xy_improve_zw})
	test(t, {-1194215371726667042, V4{-35.08, -36.33,  68.67,   8.41}, -0.9000999,  noise.noise_4d_improve_xy_improve_zw})
}

@(test)
test_noise_4d_continuity :: proc(t: ^testing.T) {
	STEP :: 1e-3
	procs := [?]proc(_: i64, _: V4) -> f32{
		noise.noise_4d_improve_xyz_improve_xy,
		noise.noise_4d_improve_xyz_improve_xz,
		noise.noise_4d_improve_xyz,
		noise.noise_4d_improve_xy_improve_zw,
		noise.noise_4d_fallback,
	}
	starts := [?]V4{
		{ 12.5,  -3.25,  7.75,  0.5},
		{-40.1,  22.7,  -5.3,  13.9},
		{  0.3,   0.6,   0.9,  -1.2},
		{ 88.8, -61.4,  35.2, -17.6},
	}
	dirs := [?]V4{
		{ 0.5,   0.25, -0.125,  0.125},
		{-0.25,  0.5,   0.125,  0.125},
		{ 0.125, 0.125, 0.5,   -0.25},
		{ 0.25, -0.25,  0.25,   0.25},
	}
	for p, i in procs {
		for start, j in starts {
			c := start
			prev := p(7, c)
			worst: f32
			for _ in 0..<20000 {
				c += dirs[j] * STEP
				v := p(7, c)
				worst = max(worst, abs(v - prev))
				prev = v
			}
			testing.expectf(t, worst < 0.01, "4D proc %v, line %v: a step of %v changed the noise by %v", i, j, STEP, worst)
		}
	}
}
