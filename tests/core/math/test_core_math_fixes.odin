package test_core_math

import "base:intrinsics"
import "core:math"
import "core:testing"

same :: proc(got, want: $T) -> bool where intrinsics.type_is_float(T) {
	if math.is_nan(want) {
		return math.is_nan(got)
	}
	return got == want && math.sign_bit(got) == math.sign_bit(want)
}

within_ulps :: proc(got, want: $T, max_ulps: i64 = 2) -> bool where intrinsics.type_is_float(T) {
	if math.is_nan(want) || math.is_inf(want) || want == 0 {
		return same(got, want)
	}
	if math.is_nan(got) || math.is_inf(got) || math.sign_bit(got) != math.sign_bit(want) {
		return false
	}
	when size_of(T) == 2 {
		g, w := i64(transmute(u16)abs(got)), i64(transmute(u16)abs(want))
	} else when size_of(T) == 4 {
		g, w := i64(transmute(u32)abs(got)), i64(transmute(u32)abs(want))
	} else {
		g, w := i64(transmute(u64)abs(got)), i64(transmute(u64)abs(want))
	}
	return abs(g - w) <= max_ulps
}

@(private="file")
pow10_literals := [632]f64{
	1.0e-323, 1.0e-322, 1.0e-321, 1.0e-320, 1.0e-319, 1.0e-318, 1.0e-317, 1.0e-316,
	1.0e-315, 1.0e-314, 1.0e-313, 1.0e-312, 1.0e-311, 1.0e-310, 1.0e-309, 1.0e-308,
	1.0e-307, 1.0e-306, 1.0e-305, 1.0e-304, 1.0e-303, 1.0e-302, 1.0e-301, 1.0e-300,
	1.0e-299, 1.0e-298, 1.0e-297, 1.0e-296, 1.0e-295, 1.0e-294, 1.0e-293, 1.0e-292,
	1.0e-291, 1.0e-290, 1.0e-289, 1.0e-288, 1.0e-287, 1.0e-286, 1.0e-285, 1.0e-284,
	1.0e-283, 1.0e-282, 1.0e-281, 1.0e-280, 1.0e-279, 1.0e-278, 1.0e-277, 1.0e-276,
	1.0e-275, 1.0e-274, 1.0e-273, 1.0e-272, 1.0e-271, 1.0e-270, 1.0e-269, 1.0e-268,
	1.0e-267, 1.0e-266, 1.0e-265, 1.0e-264, 1.0e-263, 1.0e-262, 1.0e-261, 1.0e-260,
	1.0e-259, 1.0e-258, 1.0e-257, 1.0e-256, 1.0e-255, 1.0e-254, 1.0e-253, 1.0e-252,
	1.0e-251, 1.0e-250, 1.0e-249, 1.0e-248, 1.0e-247, 1.0e-246, 1.0e-245, 1.0e-244,
	1.0e-243, 1.0e-242, 1.0e-241, 1.0e-240, 1.0e-239, 1.0e-238, 1.0e-237, 1.0e-236,
	1.0e-235, 1.0e-234, 1.0e-233, 1.0e-232, 1.0e-231, 1.0e-230, 1.0e-229, 1.0e-228,
	1.0e-227, 1.0e-226, 1.0e-225, 1.0e-224, 1.0e-223, 1.0e-222, 1.0e-221, 1.0e-220,
	1.0e-219, 1.0e-218, 1.0e-217, 1.0e-216, 1.0e-215, 1.0e-214, 1.0e-213, 1.0e-212,
	1.0e-211, 1.0e-210, 1.0e-209, 1.0e-208, 1.0e-207, 1.0e-206, 1.0e-205, 1.0e-204,
	1.0e-203, 1.0e-202, 1.0e-201, 1.0e-200, 1.0e-199, 1.0e-198, 1.0e-197, 1.0e-196,
	1.0e-195, 1.0e-194, 1.0e-193, 1.0e-192, 1.0e-191, 1.0e-190, 1.0e-189, 1.0e-188,
	1.0e-187, 1.0e-186, 1.0e-185, 1.0e-184, 1.0e-183, 1.0e-182, 1.0e-181, 1.0e-180,
	1.0e-179, 1.0e-178, 1.0e-177, 1.0e-176, 1.0e-175, 1.0e-174, 1.0e-173, 1.0e-172,
	1.0e-171, 1.0e-170, 1.0e-169, 1.0e-168, 1.0e-167, 1.0e-166, 1.0e-165, 1.0e-164,
	1.0e-163, 1.0e-162, 1.0e-161, 1.0e-160, 1.0e-159, 1.0e-158, 1.0e-157, 1.0e-156,
	1.0e-155, 1.0e-154, 1.0e-153, 1.0e-152, 1.0e-151, 1.0e-150, 1.0e-149, 1.0e-148,
	1.0e-147, 1.0e-146, 1.0e-145, 1.0e-144, 1.0e-143, 1.0e-142, 1.0e-141, 1.0e-140,
	1.0e-139, 1.0e-138, 1.0e-137, 1.0e-136, 1.0e-135, 1.0e-134, 1.0e-133, 1.0e-132,
	1.0e-131, 1.0e-130, 1.0e-129, 1.0e-128, 1.0e-127, 1.0e-126, 1.0e-125, 1.0e-124,
	1.0e-123, 1.0e-122, 1.0e-121, 1.0e-120, 1.0e-119, 1.0e-118, 1.0e-117, 1.0e-116,
	1.0e-115, 1.0e-114, 1.0e-113, 1.0e-112, 1.0e-111, 1.0e-110, 1.0e-109, 1.0e-108,
	1.0e-107, 1.0e-106, 1.0e-105, 1.0e-104, 1.0e-103, 1.0e-102, 1.0e-101, 1.0e-100,
	1.0e-99, 1.0e-98, 1.0e-97, 1.0e-96, 1.0e-95, 1.0e-94, 1.0e-93, 1.0e-92,
	1.0e-91, 1.0e-90, 1.0e-89, 1.0e-88, 1.0e-87, 1.0e-86, 1.0e-85, 1.0e-84,
	1.0e-83, 1.0e-82, 1.0e-81, 1.0e-80, 1.0e-79, 1.0e-78, 1.0e-77, 1.0e-76,
	1.0e-75, 1.0e-74, 1.0e-73, 1.0e-72, 1.0e-71, 1.0e-70, 1.0e-69, 1.0e-68,
	1.0e-67, 1.0e-66, 1.0e-65, 1.0e-64, 1.0e-63, 1.0e-62, 1.0e-61, 1.0e-60,
	1.0e-59, 1.0e-58, 1.0e-57, 1.0e-56, 1.0e-55, 1.0e-54, 1.0e-53, 1.0e-52,
	1.0e-51, 1.0e-50, 1.0e-49, 1.0e-48, 1.0e-47, 1.0e-46, 1.0e-45, 1.0e-44,
	1.0e-43, 1.0e-42, 1.0e-41, 1.0e-40, 1.0e-39, 1.0e-38, 1.0e-37, 1.0e-36,
	1.0e-35, 1.0e-34, 1.0e-33, 1.0e-32, 1.0e-31, 1.0e-30, 1.0e-29, 1.0e-28,
	1.0e-27, 1.0e-26, 1.0e-25, 1.0e-24, 1.0e-23, 1.0e-22, 1.0e-21, 1.0e-20,
	1.0e-19, 1.0e-18, 1.0e-17, 1.0e-16, 1.0e-15, 1.0e-14, 1.0e-13, 1.0e-12,
	1.0e-11, 1.0e-10, 1.0e-9, 1.0e-8, 1.0e-7, 1.0e-6, 1.0e-5, 1.0e-4,
	1.0e-3, 1.0e-2, 1.0e-1, 1.0e0, 1.0e1, 1.0e2, 1.0e3, 1.0e4,
	1.0e5, 1.0e6, 1.0e7, 1.0e8, 1.0e9, 1.0e10, 1.0e11, 1.0e12,
	1.0e13, 1.0e14, 1.0e15, 1.0e16, 1.0e17, 1.0e18, 1.0e19, 1.0e20,
	1.0e21, 1.0e22, 1.0e23, 1.0e24, 1.0e25, 1.0e26, 1.0e27, 1.0e28,
	1.0e29, 1.0e30, 1.0e31, 1.0e32, 1.0e33, 1.0e34, 1.0e35, 1.0e36,
	1.0e37, 1.0e38, 1.0e39, 1.0e40, 1.0e41, 1.0e42, 1.0e43, 1.0e44,
	1.0e45, 1.0e46, 1.0e47, 1.0e48, 1.0e49, 1.0e50, 1.0e51, 1.0e52,
	1.0e53, 1.0e54, 1.0e55, 1.0e56, 1.0e57, 1.0e58, 1.0e59, 1.0e60,
	1.0e61, 1.0e62, 1.0e63, 1.0e64, 1.0e65, 1.0e66, 1.0e67, 1.0e68,
	1.0e69, 1.0e70, 1.0e71, 1.0e72, 1.0e73, 1.0e74, 1.0e75, 1.0e76,
	1.0e77, 1.0e78, 1.0e79, 1.0e80, 1.0e81, 1.0e82, 1.0e83, 1.0e84,
	1.0e85, 1.0e86, 1.0e87, 1.0e88, 1.0e89, 1.0e90, 1.0e91, 1.0e92,
	1.0e93, 1.0e94, 1.0e95, 1.0e96, 1.0e97, 1.0e98, 1.0e99, 1.0e100,
	1.0e101, 1.0e102, 1.0e103, 1.0e104, 1.0e105, 1.0e106, 1.0e107, 1.0e108,
	1.0e109, 1.0e110, 1.0e111, 1.0e112, 1.0e113, 1.0e114, 1.0e115, 1.0e116,
	1.0e117, 1.0e118, 1.0e119, 1.0e120, 1.0e121, 1.0e122, 1.0e123, 1.0e124,
	1.0e125, 1.0e126, 1.0e127, 1.0e128, 1.0e129, 1.0e130, 1.0e131, 1.0e132,
	1.0e133, 1.0e134, 1.0e135, 1.0e136, 1.0e137, 1.0e138, 1.0e139, 1.0e140,
	1.0e141, 1.0e142, 1.0e143, 1.0e144, 1.0e145, 1.0e146, 1.0e147, 1.0e148,
	1.0e149, 1.0e150, 1.0e151, 1.0e152, 1.0e153, 1.0e154, 1.0e155, 1.0e156,
	1.0e157, 1.0e158, 1.0e159, 1.0e160, 1.0e161, 1.0e162, 1.0e163, 1.0e164,
	1.0e165, 1.0e166, 1.0e167, 1.0e168, 1.0e169, 1.0e170, 1.0e171, 1.0e172,
	1.0e173, 1.0e174, 1.0e175, 1.0e176, 1.0e177, 1.0e178, 1.0e179, 1.0e180,
	1.0e181, 1.0e182, 1.0e183, 1.0e184, 1.0e185, 1.0e186, 1.0e187, 1.0e188,
	1.0e189, 1.0e190, 1.0e191, 1.0e192, 1.0e193, 1.0e194, 1.0e195, 1.0e196,
	1.0e197, 1.0e198, 1.0e199, 1.0e200, 1.0e201, 1.0e202, 1.0e203, 1.0e204,
	1.0e205, 1.0e206, 1.0e207, 1.0e208, 1.0e209, 1.0e210, 1.0e211, 1.0e212,
	1.0e213, 1.0e214, 1.0e215, 1.0e216, 1.0e217, 1.0e218, 1.0e219, 1.0e220,
	1.0e221, 1.0e222, 1.0e223, 1.0e224, 1.0e225, 1.0e226, 1.0e227, 1.0e228,
	1.0e229, 1.0e230, 1.0e231, 1.0e232, 1.0e233, 1.0e234, 1.0e235, 1.0e236,
	1.0e237, 1.0e238, 1.0e239, 1.0e240, 1.0e241, 1.0e242, 1.0e243, 1.0e244,
	1.0e245, 1.0e246, 1.0e247, 1.0e248, 1.0e249, 1.0e250, 1.0e251, 1.0e252,
	1.0e253, 1.0e254, 1.0e255, 1.0e256, 1.0e257, 1.0e258, 1.0e259, 1.0e260,
	1.0e261, 1.0e262, 1.0e263, 1.0e264, 1.0e265, 1.0e266, 1.0e267, 1.0e268,
	1.0e269, 1.0e270, 1.0e271, 1.0e272, 1.0e273, 1.0e274, 1.0e275, 1.0e276,
	1.0e277, 1.0e278, 1.0e279, 1.0e280, 1.0e281, 1.0e282, 1.0e283, 1.0e284,
	1.0e285, 1.0e286, 1.0e287, 1.0e288, 1.0e289, 1.0e290, 1.0e291, 1.0e292,
	1.0e293, 1.0e294, 1.0e295, 1.0e296, 1.0e297, 1.0e298, 1.0e299, 1.0e300,
	1.0e301, 1.0e302, 1.0e303, 1.0e304, 1.0e305, 1.0e306, 1.0e307, 1.0e308,
}

@(private="file")
Binary_Case :: struct {
	x, y, want: f64,
}

@test
test_mod_exact :: proc(t: ^testing.T) {
	cases := [?]Binary_Case{
		{1e17, 3, 1},
		{1e308, 1e-308, 3.498445546245627e-309},
		{-7, 3, -1},
		{7, -3, 1},
		{-7, -3, -1},
		{5.5, 2, 1.5},
		{-6, 3, -0.0},
		{6, -3, 0},
		{3, 1e308, 3},
		{math.F64_MAX, 3, 2},
		{math.F64_MAX, 1e-300, 2.589523889680434e-302},
		{math.F64_MAX, 5e-324, 0},
		{2.5e-323, 1.5e-323, 1e-323},
		{1, 1.5e-323, 5e-324},
		{math.F64_MIN, 1.5e-323, 5e-324},
		{-math.F64_MIN, 7e-310, -5.5073858507208e-310},
		{1e-310, 7e-311, 3e-311},
	}
	for c in cases {
		got := math.mod(c.x, c.y)
		testing.expectf(t, same(got, c.want), "mod(%v, %v) = %v, want %v", c.x, c.y, got, c.want)
	}
}

@test
test_mod_specials :: proc(t: ^testing.T) {
	inf, ninf, nan := math.INF_F64, math.NEG_INF_F64, math.QNAN_F64
	cases := [?]Binary_Case{
		{0, 3, 0},
		{-0.0, 3, -0.0},
		{0, inf, 0},
		{-0.0, ninf, -0.0},
		{5, inf, 5},
		{-5, inf, -5},
		{5, ninf, 5},
		{inf, 3, nan},
		{ninf, 3, nan},
		{inf, inf, nan},
		{3, 0, nan},
		{3, -0.0, nan},
		{0, 0, nan},
		{nan, 3, nan},
		{3, nan, nan},
		{nan, inf, nan},
		{inf, nan, nan},
	}
	for c in cases {
		got := math.mod(c.x, c.y)
		testing.expectf(t, same(got, c.want), "mod(%v, %v) = %v, want %v", c.x, c.y, got, c.want)
	}
}

@test
test_mod_narrow :: proc(t: ^testing.T) {
	testing.expect(t, same(math.mod(f32(1e10), 3), f32(1)))
	testing.expect(t, same(math.mod(f32(-1e10), 3), f32(-1)))
	testing.expect(t, same(math.mod(f32(3.4028234663852886e38), 3), f32(0)))
	testing.expect(t, same(math.mod(f32le(1e10), 3), f32le(1)))
	testing.expect(t, same(math.mod(f16(65504), 3), f16(2)))
	testing.expect(t, same(math.mod(f16(1000), 7), f16(6)))
	testing.expect(t, same(math.mod(f16(-6), 3), f16(-0.0)))
	testing.expect(t, same(math.mod(f16be(1000), 7), f16be(6)))
	testing.expect(t, same(math.mod(f64be(1e17), 3), f64be(1)))
}

@test
test_remainder_exact :: proc(t: ^testing.T) {
	cases := [?]Binary_Case{
		{5, 2, 1},
		{3, 2, -1},
		{-5, 2, -1},
		{7, 2, -1},
		{1, 2, 1},
		{-1, 2, -1},
		{6, 3, 0},
		{-6, 3, -0.0},
		{1e17, 3, 1},
		{3, 1e308, 3},
		{math.F64_MAX, 3, -1},
		{math.F64_MAX, 5.992310449541053e307, -9.9792015476736e291},
		{math.F64_MAX, 1e308, -2.0230686513768431e307},
		{-math.F64_MAX, 1e308, 2.0230686513768431e307},
		{1e308, 1e-308, 3.498445546245627e-309},
		{2.5e-323, 1e-323, 5e-324},
		{3.5e-323, 1e-323, -5e-324},
		{math.F64_MIN, 1.5e-323, 5e-324},
	}
	for c in cases {
		got := math.remainder(c.x, c.y)
		testing.expectf(t, same(got, c.want), "remainder(%v, %v) = %v, want %v", c.x, c.y, got, c.want)
	}
}

@test
test_remainder_specials :: proc(t: ^testing.T) {
	inf, ninf, nan := math.INF_F64, math.NEG_INF_F64, math.QNAN_F64
	cases := [?]Binary_Case{
		{0, 3, 0},
		{-0.0, 3, -0.0},
		{-0.0, -3, -0.0},
		{0, inf, 0},
		{-0.0, ninf, -0.0},
		{5, inf, 5},
		{-5, ninf, -5},
		{inf, 3, nan},
		{ninf, 3, nan},
		{inf, inf, nan},
		{3, 0, nan},
		{3, -0.0, nan},
		{0, 0, nan},
		{nan, 3, nan},
		{3, nan, nan},
		{nan, inf, nan},
	}
	for c in cases {
		got := math.remainder(c.x, c.y)
		testing.expectf(t, same(got, c.want), "remainder(%v, %v) = %v, want %v", c.x, c.y, got, c.want)
	}
}

@test
test_remainder_narrow :: proc(t: ^testing.T) {
	testing.expect(t, same(math.remainder(f32(5), 2), f32(1)))
	testing.expect(t, same(math.remainder(f32(1e10), 3), f32(1)))
	testing.expect(t, same(math.remainder(f32(-6), 3), f32(-0.0)))
	testing.expect(t, same(math.remainder(f32(3.4028234663852886e38), 3), f32(0)))
	testing.expect(t, same(math.remainder(f32be(3), 2), f32be(-1)))
	testing.expect(t, same(math.remainder(f16(65504), 3), f16(-1)))
	testing.expect(t, same(math.remainder(f16(1000), 7), f16(-1)))
	testing.expect(t, same(math.remainder(f16le(5), 2), f16le(1)))
	testing.expect(t, same(math.remainder(f64le(1e17), 3), f64le(1)))
	testing.expect(t, same(math.remainder(f64be(5), 2), f64be(1)))
}

@test
test_wrap_stays_below_y :: proc(t: ^testing.T) {
	testing.expect(t, same(math.wrap(f64(-1e-20), math.TAU), f64(0)))
	testing.expect(t, same(math.wrap(f32(-1e-10), f32(math.TAU)), f32(0)))
	testing.expect(t, same(math.wrap(f64(-3), 2), f64(1)))
	testing.expect(t, same(math.wrap(f64(1e17), 3), f64(1)))
	testing.expect(t, same(math.wrap(f64(7.5), 2), f64(1.5)))
	testing.expect(t, within_ulps(math.wrap(f64(-6), math.TAU), f64(0.28318530717958623)))
}

@test
test_angle_diff_near_zero :: proc(t: ^testing.T) {
	d64 := math.angle_diff(f64(1e-20), 0)
	testing.expectf(t, abs(d64) < 1e-15, "angle_diff(1e-20, 0) = %v, want about 0", d64)
	d32 := math.angle_diff(f32(1e-10), 0)
	testing.expectf(t, abs(d32) < 1e-6, "angle_diff(f32(1e-10), 0) = %v, want about 0", d32)
	l64 := math.angle_lerp(f64(1e-20), 0, 0.5)
	testing.expectf(t, abs(l64) < 1e-15, "angle_lerp(1e-20, 0, 0.5) = %v, want about 0", l64)
	l32 := math.angle_lerp(f32(1e-10), 0, 0.5)
	testing.expectf(t, abs(l32) < 1e-6, "angle_lerp(f32(1e-10), 0, 0.5) = %v, want about 0", l32)
	testing.expect(t, within_ulps(math.angle_diff(f64(3), -3), f64(0.28318530717958623)))
}

@(private="file")
Sincos_Case :: struct {
	x, sin, cos: f64,
	j:           u64,
	z:           f64,
}

@test
test_sincos_near_multiples_of_half_pi :: proc(t: ^testing.T) {
	cases := [?]Sincos_Case{
		{1.5707963267948966, 1, 6.123233995736766e-17, 2, -6.123233995736766e-17},
		{6731237.680638236, -1, -1.4871569277433705e-14, 6, -1.4871569277433705e-14},
		{1e22, -0.8522008497671888, 0.523214785395139, 6, 0.5506189342358097},
		{math.F64_MAX, 0.004961954789184062, -0.9999876894265599, 4, -0.004961975150787273},
		{5.319372648326541e255, 1, -4.687165924254628e-19, 2, 4.687165924254628e-19},
	}
	for c in cases {
		s, co := math.sincos(c.x)
		testing.expectf(t, within_ulps(s, c.sin) && within_ulps(co, c.cos), "sincos(%v) = %v, %v, want %v, %v", c.x, s, co, c.sin, c.cos)
		j, z := math._trig_reduce_f64(c.x)
		testing.expectf(t, j == c.j && within_ulps(z, c.z, 1), "_trig_reduce_f64(%v) = %v, %v, want %v, %v", c.x, j, z, c.j, c.z)
	}
}

@test
test_cbrt_subnormal :: proc(t: ^testing.T) {
	Case :: struct {
		x, want: f64,
	}
	cases := [?]Case{
		{5e-324, 1.7031839360032603e-108},
		{1e-320, 2.1544266950262728e-107},
		{1e-310, 4.641588833612774e-104},
		{-1e-310, -4.641588833612774e-104},
		{-math.F64_MIN, -2.812644285236262e-103},
		{-0.0, -0.0},
		{0, 0},
	}
	for c in cases {
		got := math.cbrt(c.x)
		testing.expectf(t, within_ulps(got, c.want), "cbrt(%v) = %v, want %v", c.x, got, c.want)
	}
}

@test
test_lgamma_interval_bounds :: proc(t: ^testing.T) {
	Case :: struct {
		x, want: f64,
	}
	cases := [?]Case{
		{0.2, 1.5240638224307845},
		{0.21, 1.4724463831599772},
		{0.7, 0.26086724653166654},
		{1.1934, -0.083438752131070423},
		{1.2, -0.085374090003315833},
		{1.22, -0.090903361844300284},
		{1.5, -0.12078223763524522},
	}
	for c in cases {
		got, sign := math.lgamma(c.x)
		testing.expectf(t, within_ulps(got, c.want) && sign == 1, "lgamma(%v) = %v, %v, want %v, 1", c.x, got, sign, c.want)
	}
}

@test
test_lgamma_specials :: proc(t: ^testing.T) {
	Case :: struct {
		x, want: f64,
		sign:    int,
	}
	cases := [?]Case{
		{0, math.INF_F64, 1},
		{-0.0, math.INF_F64, -1},
		{math.INF_F64, math.INF_F64, 1},
		// As in C, not Go: lgamma(-Inf) = +Inf.
		{math.NEG_INF_F64, math.INF_F64, 1},
	}
	for c in cases {
		got, sign := math.lgamma(c.x)
		testing.expectf(t, same(got, c.want) && sign == c.sign, "lgamma(%v) = %v, %v, want %v, %v", c.x, got, sign, c.want, c.sign)
	}
	got, _ := math.lgamma(math.QNAN_F64)
	testing.expectf(t, math.is_nan(got), "lgamma(NaN) = %v, want NaN", got)
}

@test
test_erfc_middle_interval :: proc(t: ^testing.T) {
	Case :: struct {
		x, want: f64,
	}
	cases := [?]Case{
		{0.3, 0.67137324054087255},
		{0.7, 0.32219880616258156},
		{0.81864689988550188, 0.24696952301120867},
		{-0.5, 1.5204998778130465},
	}
	for c in cases {
		got := math.erfc(c.x)
		testing.expectf(t, within_ulps(got, c.want), "erfc(%v) = %v, want %v", c.x, got, c.want)
	}
}

@test
test_pow10_correctly_rounded :: proc(t: ^testing.T) {
	for want, i in pow10_literals {
		n := i - 323
		got := math.pow10(f64(n))
		testing.expectf(t, same(got, want), "pow10(%v) = %v, want %v", n, got, want)
	}
}

@test
test_log_exact_powers :: proc(t: ^testing.T) {
	for k in -1022..=1023 {
		got := math.log2(math.ldexp(f64(1), k))
		testing.expectf(t, got == f64(k), "log2(2^%v) = %v", k, got)
	}
	for x, i in pow10_literals {
		n := i - 323
		if n < -307 {
			continue
		}
		got := math.log10(x)
		testing.expectf(t, got == f64(n), "log10(1e%v) = %v", n, got)
	}
	testing.expect_value(t, math.log10(f64(1000)), 3)
	testing.expect_value(t, math.log10(f64(1e15)), 15)
	testing.expect_value(t, math.log(f64(1000), 10), 3)
	testing.expect_value(t, math.log(f64(8), 2), 3)
}

@test
test_log_narrow_and_specials :: proc(t: ^testing.T) {
	testing.expect(t, same(math.log2(f32(8)), f32(3)))
	testing.expect(t, same(math.log10(f32(1000)), f32(3)))
	testing.expect(t, same(math.log10(f32(2)), f32(0.3010300099849701)))
	testing.expect(t, same(math.log2(f32(10)), f32(3.321928024291992)))
	testing.expect(t, same(math.log2(f16(1024)), f16(10)))
	testing.expect(t, same(math.log10(f16(3)), f16(0.47705078125)))

	testing.expect(t, same(math.log2(f64(0)), math.NEG_INF_F64))
	testing.expect(t, same(math.log2(f64(-0.0)), math.NEG_INF_F64))
	testing.expect(t, math.is_nan(math.log2(f64(-1))))
	testing.expect(t, same(math.log2(math.INF_F64), math.INF_F64))
	testing.expect(t, same(math.log10(f64(0)), math.NEG_INF_F64))
	testing.expect(t, math.is_nan(math.log10(f64(-1))))
	testing.expect(t, same(math.log10(math.INF_F64), math.INF_F64))
}

@test
test_tan_hypot_narrow :: proc(t: ^testing.T) {
	testing.expect(t, same(math.hypot(f16(-12280), f16(64384)), math.INF_F16))
	testing.expect(t, same(math.hypot(f16(3), f16(4)), f16(5)))
	testing.expect(t, same(math.hypot(f32(3), f32(4)), f32(5)))
	testing.expect(t, same(math.tan(f32(1)), f32(1.5574077367782593)))
	testing.expect(t, same(math.tan(f16(1)), f16(1.5576171875)))
}

@test
test_frexp_signed_zero :: proc(t: ^testing.T) {
	f64v, e64 := math.frexp(f64(-0.0))
	testing.expectf(t, same(f64v, f64(-0.0)) && e64 == 0, "frexp(f64(-0)) = %v, %v", f64v, e64)
	f32v, e32 := math.frexp(f32(-0.0))
	testing.expectf(t, same(f32v, f32(-0.0)) && e32 == 0, "frexp(f32(-0)) = %v, %v", f32v, e32)
	f16v, e16 := math.frexp(f16(-0.0))
	testing.expectf(t, same(f16v, f16(-0.0)) && e16 == 0, "frexp(f16(-0)) = %v, %v", f16v, e16)
	p64, pe64 := math.frexp(f64(0))
	testing.expectf(t, same(p64, f64(0)) && pe64 == 0, "frexp(f64(0)) = %v, %v", p64, pe64)
}

@test
test_ldexp_exponent_overflow :: proc(t: ^testing.T) {
	testing.expect(t, same(math.ldexp(f64(2), max(int)), math.INF_F64))
	testing.expect(t, same(math.ldexp(f64(-1), max(int)), math.NEG_INF_F64))
	testing.expect(t, same(math.ldexp(f64(5e-324), max(int)), math.INF_F64))
	testing.expect(t, same(math.ldexp(f64(0.5), min(int)), f64(0)))
	testing.expect(t, same(math.ldexp(f64(-0.5), min(int)), f64(-0.0)))
	testing.expect(t, same(math.ldexp(f64(5e-324), min(int)), f64(0)))
	testing.expect(t, same(math.ldexp(f64(1), 1024), math.INF_F64))
	testing.expect(t, same(math.ldexp(f64(1), -1074), f64(5e-324)))
	testing.expect(t, same(math.ldexp(f64(1), -1075), f64(0)))
}

@test
test_float_constants_exact :: proc(t: ^testing.T) {
	testing.expect(t, f64(math.F32_MAX) == 3.4028234663852886e38)
	testing.expect(t, f64(math.F32_MIN) == 1.1754943508222875e-38)
	testing.expect(t, f64(math.F32_EPSILON) == 1.1920928955078125e-7)
	testing.expect(t, f64(math.F16_EPSILON) == 0.0009765625)
	testing.expect(t, f64(math.F16_MIN) == 6.103515625e-5)
	testing.expect_value(t, math.F16_MAX_EXP, 16)
	testing.expect_value(t, math.F16_MIN_EXP, -13)
	testing.expect(t, math.is_nan(math.QNAN_F32) && !math.sign_bit(math.QNAN_F32))
	testing.expect(t, math.is_nan(math.SNAN_F32) && !math.sign_bit(math.SNAN_F32))
	testing.expect(t, math.is_nan(math.QNAN_F16) && !math.sign_bit(math.QNAN_F16))
	testing.expect(t, math.is_nan(math.QNAN_F64) && !math.sign_bit(math.QNAN_F64))
}

@test
test_remap_clamped_reversed :: proc(t: ^testing.T) {
	testing.expect_value(t, math.remap_clamped(f64(0.25), 0, 1, 10, 0), 7.5)
	testing.expect_value(t, math.remap_clamped(f64(2), 0, 1, 10, 0), 0)
	testing.expect_value(t, math.remap_clamped(f64(-1), 0, 1, 10, 0), 10)
	testing.expect_value(t, math.remap_clamped(f64(2), 0, 1, 10, 20), 20)
	testing.expect_value(t, math.remap_clamped(f32(0.25), 0, 1, 10, 0), 7.5)
	testing.expect_value(t, math.remap_clamped(i32(5), 0, 10, 100, 0), 50)
	testing.expect_value(t, math.remap_clamped(i32(15), 0, 10, 100, 0), 0)
	testing.expect_value(t, math.remap_clamped(i32(15), 0, 10, 0, 100), 100)
}

@test
test_binomial_range :: proc(t: ^testing.T) {
	testing.expect_value(t, math.binomial(0, 0), 1)
	testing.expect_value(t, math.binomial(5, 2), 10)
	testing.expect_value(t, math.binomial(3, 5), 0)
	testing.expect_value(t, math.binomial(5, -1), 0)
	testing.expect_value(t, math.binomial(33, 16), 1166803110)
	when size_of(int) == 8 {
		testing.expect_value(t, math.binomial(62, 31), 465428353255261088)
		testing.expect_value(t, math.binomial(66, 33), 7219428434016265740)
	}
}

@test
test_lcm_sign_and_zero :: proc(t: ^testing.T) {
	testing.expect_value(t, math.lcm(4, 6), 12)
	testing.expect_value(t, math.lcm(-4, 6), 12)
	testing.expect_value(t, math.lcm(4, -6), 12)
	testing.expect_value(t, math.lcm(i64(-3), -5), 15)
	testing.expect_value(t, math.lcm(0, 5), 0)
	testing.expect_value(t, math.lcm(0, 0), 0)
}

@test
test_erf_endian_variants :: proc(t: ^testing.T) {
	testing.expect(t, same(math.erf(f64le(0.5)), f64le(math.erf(f64(0.5)))))
	testing.expect(t, same(math.erf(f64be(0.5)), f64be(math.erf(f64(0.5)))))
	testing.expect(t, same(math.erfc(f64le(0.5)), f64le(math.erfc(f64(0.5)))))
	testing.expect(t, same(math.erfc(f64be(0.5)), f64be(math.erfc(f64(0.5)))))
}

@test
test_trig_large_arguments :: proc(t: ^testing.T) {
	testing.expect(t, within_ulps(math.sin(f64(1e22)), f64(-0.8522008497671888)))
	testing.expect(t, within_ulps(math.cos(f64(1e22)), f64(0.523214785395139)))
	testing.expect(t, within_ulps(math.sin(f64(math.F64_MAX)), f64(0.004961954789184062)))
	testing.expect(t, within_ulps(math.cos(f64(math.F64_MAX)), f64(-0.9999876894265599)))
	testing.expect(t, within_ulps(math.sin(f32(1e22)), f32(-0.734081506729126)))
	testing.expect(t, within_ulps(math.cos(f32(1e22)), f32(0.6790613532066345)))
}

@test
test_sign_nan :: proc(t: ^testing.T) {
	testing.expect(t, math.is_nan(math.sign(math.QNAN_F16)))
	testing.expect(t, math.is_nan(math.sign(f16le(math.QNAN_F16))))
	testing.expect(t, math.is_nan(math.sign(f16be(math.QNAN_F16))))
	testing.expect(t, math.is_nan(math.sign(math.QNAN_F32)))
	testing.expect(t, math.is_nan(math.sign(f32le(math.QNAN_F32))))
	testing.expect(t, math.is_nan(math.sign(f32be(math.QNAN_F32))))
	testing.expect(t, math.is_nan(math.sign(math.QNAN_F64)))
	testing.expect(t, math.is_nan(math.sign(f64le(math.QNAN_F64))))
	testing.expect(t, math.is_nan(math.sign(f64be(math.QNAN_F64))))
	testing.expect(t, same(math.sign(f64(-0.0)), f64(0)))
	testing.expect(t, same(math.sign(f64(-2.5)), f64(-1)))
	testing.expect(t, same(math.sign(math.INF_F64), f64(1)))
}

@test
test_remap_integer_overflow :: proc(t: ^testing.T) {
	testing.expect_value(t, math.remap(i8(-100), -128, 127, 127, -128), 99)
	testing.expect_value(t, math.remap(u8(200), 0, 255, 0, 100), 78)
	testing.expect_value(t, math.remap(i16(30000), -32768, 32767, -32768, 32767), 30000)
	testing.expect_value(t, math.remap(i32(1_000_000), 0, 2_000_000, 0, 1_000_000), 500_000)
	testing.expect_value(t, math.remap(i32(-7), -10, 10, 100, -100), 70)
	testing.expect_value(t, math.remap(i32(7), max(i32), max(i32), min(i32), max(i32)), -1)
	testing.expect_value(t, math.remap(u32(4_000_000_000), 0, 4_000_000_000, 0, 4_000_000_000), 4_000_000_000)
	testing.expect_value(t, math.remap(u32(1_000_000_000), 0, 4_000_000_000, 4_000_000_000, 0), 3_000_000_000)
	testing.expect_value(t, math.remap(int(-1), 0, 3, 0, 10), -3)
	testing.expect_value(t, math.remap(i64(-5), -10, 10, min(i64), max(i64)), -4611686018427387905)
	testing.expect_value(t, math.remap(i64be(3), 0, 10, 0, 1000), 300)
	testing.expect_value(t, math.remap(u64(18_000_000_000_000_000_000), 0, max(u64), 0, max(u64)), 18_000_000_000_000_000_000)
	testing.expect_value(t, math.remap(i128(3), 0, 10, 0, 1000), 300)
	testing.expect_value(t, math.remap(f64(0.25), 0, 1, 10, 0), 7.5)
}

@test
test_remap_clamped_integer_range :: proc(t: ^testing.T) {
	testing.expect_value(t, math.remap_clamped(u8(200), 0, 100, 0, 255), 255)
	testing.expect_value(t, math.remap_clamped(u8(200), 100, 0, 0, 255), 0)
	testing.expect_value(t, math.remap_clamped(i8(100), 0, 50, 0, 100), 100)
	testing.expect_value(t, math.remap_clamped(i8(-100), 0, 50, 0, 100), 0)
	testing.expect_value(t, math.remap_clamped(i8(-100), 0, 50, 100, 0), 100)
	testing.expect_value(t, math.remap_clamped(i32(max(i32)), 0, 10, 0, 1_000_000_000), 1_000_000_000)
	testing.expect_value(t, math.remap_clamped(i64(max(i64)), 0, 2, min(i64), max(i64)), max(i64))
	testing.expect_value(t, math.remap_clamped(i64(min(i64)), 0, 2, min(i64), max(i64)), min(i64))
}
