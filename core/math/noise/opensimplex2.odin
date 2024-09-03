/*
	OpenSimplex2 noise implementation.

	Ported from [[ https://github.com/KdotJPG/OpenSimplex2 }].
	Copyright 2022 Yuki2 [[ https://github.com/NoahR02 ]]
*/
package math_noise

/*
	Input coordinate vectors
*/
Vec2 :: [2]f64
Vec3 :: [3]f64
Vec4 :: [4]f64

/*
	Noise Evaluators
*/

/*
	2D Simplex noise, standard lattice orientation.
*/
@(require_results)
noise_2d :: proc(seed: i64, coord: Vec2) -> (value: f32) {
	// Get points for A2* lattice
	skew   := SKEW_2D * (coord.x + coord.y)
	skewed := coord + skew

	return _internal_noise_2d_unskewed_base(seed, skewed)
}

/*
	2D Simplex noise, with Y pointing down the main diagonal.
	Might be better for a 2D sandbox style game, where Y is vertical.
	Probably slightly less optimal for heightmaps or continent maps,
	unless your map is centered around an equator. It's a subtle
	difference, but the option is here to make it an easy choice.
*/
@(require_results)
noise_2d_improve_x :: proc(seed: i64, coord: Vec2) -> (value: f32) {
	// Skew transform and rotation baked into one.
	xx := coord.x * ROOT_2_OVER_2
	yy := coord.y * (ROOT_2_OVER_2 * (1 + 2 * SKEW_2D))
	return _internal_noise_2d_unskewed_base(seed, Vec2{yy + xx, yy - xx})
}


/*
	3D OpenSimplex2 noise, with better visual isotropy in (X, Y).
	Recommended for 3D terrain and time-varied animations.
	The Z coordinate should always be the "different" coordinate in whatever your use case is.
	If Y is vertical in world coordinates, call `noise_3d_improve_xz(x, z, Y)` or use `noise_3d_xz_before_y`.
	If Z is vertical in world coordinates, call `noise_3d_improve_xz(x, y, Z)`.
	For a time varied animation, call `noise_3d_improve_xz(x, y, T)`.
*/
@(require_results)
noise_3d_improve_xy :: proc(seed: i64, coord: Vec3) -> (value: f32) {
	/*
		Re-orient the cubic lattices without skewing, so Z points up the main lattice diagonal,
		and the planes formed by XY are moved far out of alignment with the cube faces.
		Orthonormal rotation. Not a skew transform.
	*/
	xy := coord.x + coord.y
	s2 := xy * ROTATE_3D_ORTHOGONALIZER
	zz := coord.z * ROOT_3_OVER_3

	r := Vec3{coord.x + s2 + zz, coord.y + s2 + zz, xy * -ROOT_3_OVER_3 + zz}

	// Evaluate both lattices to form a BCC lattice.
	return _internal_noise_3d_unrotated_base(seed, r)
}

/*
	3D OpenSimplex2 noise, with better visual isotropy in (X, Z).
	Recommended for 3D terrain and time-varied animations.
	The Y coordinate should always be the "different" coordinate in whatever your use case is.
	If Y is vertical in world coordinates, call `noise_3d_improve_xz(x, Y, z)`.
	If Z is vertical in world coordinates, call `noise_3d_improve_xz(x, Z, y)` or use `noise_3d_improve_xy`.
	For a time varied animation, call `noise_3d_improve_xz(x, T, y)` or use `noise_3d_improve_xy`.
*/
@(require_results)
noise_3d_improve_xz :: proc(seed: i64, coord: Vec3) -> (value: f32) {
	/*
		Re-orient the cubic lattices without skewing, so Y points up the main lattice diagonal,
		and the planes formed by XZ are moved far out of alignment with the cube faces.
		Orthonormal rotation. Not a skew transform.
	*/
	xz := coord.x + coord.z
	s2 := xz * ROTATE_3D_ORTHOGONALIZER
	yy := coord.y * ROOT_3_OVER_3

	r := Vec3{coord.x + s2 + yy, xz * -ROOT_3_OVER_3 + yy, coord.z + s2 + yy}
	
	// Evaluate both lattices to form a BCC lattice.
	return _internal_noise_3d_unrotated_base(seed, r)
}

/*
	3D OpenSimplex2 noise, fallback rotation option
	Use `noise_3d_improve_xy` or `noise_3d_improve_xz` instead, wherever appropriate.
	They have less diagonal bias. This function's best use is as a fallback.
*/
@(require_results)
noise_3d_fallback :: proc(seed: i64, coord: Vec3) -> (value: f32) {
	/*
		Re-orient the cubic lattices via rotation, to produce a familiar look.
		Orthonormal rotation. Not a skew transform.
	*/
	bias   := FALLBACK_ROTATE_3D * (coord.x + coord.y + coord.z)
	biased := bias - coord
	// Evaluate both lattices to form a BCC lattice.
	return _internal_noise_3d_unrotated_base(seed, biased)
}


/*
	4D OpenSimplex2 noise, with XYZ oriented like `noise_3d_improve_xy`
	and W for an extra degree of freedom. W repeats eventually.
	Recommended for time-varied animations which texture a 3D object (W=time)
	in a space where Z is vertical.
*/
@(require_results)
noise_4d_improve_xyz_improve_xy :: proc(seed: i64, coord: Vec4) -> (value: f32) {
	xy := coord.x + coord.y
	s2 := xy * -0.21132486540518699998
	zz := coord.z * 0.28867513459481294226
	ww := coord.w * 0.2236067977499788

	xr, yr : f64 = coord.x + (zz + ww + s2), coord.y + (zz + ww + s2)
	zr : f64 = xy * -0.57735026918962599998 + (zz + ww)
	wr : f64 = coord.z * -0.866025403784439 + ww

	return _internal_noise_4d_unskewed_base(seed, Vec4{xr, yr, zr, wr})
}

/*
	4D OpenSimplex2 noise, with XYZ oriented like `noise_3d_improve_xz`
	and W for an extra degree of freedom. W repeats eventually.
	Recommended for time-varied animations which texture a 3D object (W=time)
	in a space where Y is vertical.
*/
@(require_results)
noise_4d_improve_xyz_improve_xz :: proc(seed: i64, coord: Vec4) -> (value: f32) {
	xz := coord.x + coord.z
	s2 := xz * -0.21132486540518699998
	yy := coord.y * 0.28867513459481294226
	ww := coord.w * 0.2236067977499788

	xr, zr : f64 = coord.x + (yy + ww + s2), coord.z + (yy + ww + s2)
	yr := xz * -0.57735026918962599998 + (yy + ww)
	wr := coord.y * -0.866025403784439 + ww

	return _internal_noise_4d_unskewed_base(seed, Vec4{xr, yr, zr, wr})
}

/*
	4D OpenSimplex2 noise, with XYZ oriented like `noise_3d_fallback`
	and W for an extra degree of freedom. W repeats eventually.
	Recommended for time-varied animations which texture a 3D object (W=time)
	where there isn't a clear distinction between horizontal and vertical
*/
@(require_results)
noise_4d_improve_xyz :: proc(seed: i64, coord: Vec4) -> (value: f32) {
	xyz := coord.x + coord.y + coord.z
	ww  := coord.w * 0.2236067977499788
	s2  := xyz * -0.16666666666666666 + ww

	skewed := Vec4{coord.x + s2, coord.y + s2, coord.z + s2, -0.5 * xyz + ww}
	return _internal_noise_4d_unskewed_base(seed, skewed)
}

/*
	4D OpenSimplex2 noise, fallback lattice orientation.
*/
@(require_results)
noise_4d_fallback :: proc(seed: i64, coord: Vec4) -> (value: f32) {
	// Get points for A4 lattice
	skew := f64(SKEW_4D) * (coord.x + coord.y + coord.z + coord.w)
	return _internal_noise_4d_unskewed_base(seed, coord + skew)
}
