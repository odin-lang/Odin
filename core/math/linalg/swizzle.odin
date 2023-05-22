package linalg

/*
	These procedures are to allow for swizzling with non-compile (runtime) known components
*/


Scalar_Components :: enum u8 {
	x = 0,
	r = 0,
}

Vector2_Components :: enum u8 {
	x = 0,
	y = 1,
	r = 0,
	g = 1,
}

Vector3_Components :: enum u8 {
	x = 0,
	y = 1,
	z = 2,
	r = 0,
	g = 1,
	b = 2,
}

Vector4_Components :: enum u8 {
	x = 0,
	y = 1,
	z = 2,
	w = 3,
	r = 0,
	g = 1,
	b = 2,
	a = 3,
}

@(require_results)
scalar_f32_swizzle1 :: proc "contextless" (f: f32, c0: Scalar_Components) -> f32 {
	return f
}
@(require_results)
scalar_f32_swizzle2 :: proc "contextless" (f: f32, c0, c1: Scalar_Components) -> Vector2f32 {
	return {f, f}
}
@(require_results)
scalar_f32_swizzle3 :: proc "contextless" (f: f32, c0, c1, c2: Scalar_Components) -> Vector3f32 {
	return {f, f, f}
}
@(require_results)
scalar_f32_swizzle4 :: proc "contextless" (f: f32, c0, c1, c2, c3: Scalar_Components) -> Vector4f32 {
	return {f, f, f, f}
}

@(require_results)
vector2f32_swizzle1 :: proc "contextless" (v: Vector2f32, c0: Vector2_Components) -> f32 {
	return v[c0]
}
@(require_results)
vector2f32_swizzle2 :: proc "contextless" (v: Vector2f32, c0, c1: Vector2_Components) -> Vector2f32 {
	return {v[c0], v[c1]}
}
@(require_results)
vector2f32_swizzle3 :: proc "contextless" (v: Vector2f32, c0, c1, c2: Vector2_Components) -> Vector3f32 {
	return {v[c0], v[c1], v[c2]}
}
@(require_results)
vector2f32_swizzle4 :: proc "contextless" (v: Vector2f32, c0, c1, c2, c3: Vector2_Components) -> Vector4f32 {
	return {v[c0], v[c1], v[c2], v[c3]}
}


@(require_results)
vector3f32_swizzle1 :: proc "contextless" (v: Vector3f32, c0: Vector3_Components) -> f32 {
	return v[c0]
}
@(require_results)
vector3f32_swizzle2 :: proc "contextless" (v: Vector3f32, c0, c1: Vector3_Components) -> Vector2f32 {
	return {v[c0], v[c1]}
}
@(require_results)
vector3f32_swizzle3 :: proc "contextless" (v: Vector3f32, c0, c1, c2: Vector3_Components) -> Vector3f32 {
	return {v[c0], v[c1], v[c2]}
}
@(require_results)
vector3f32_swizzle4 :: proc "contextless" (v: Vector3f32, c0, c1, c2, c3: Vector3_Components) -> Vector4f32 {
	return {v[c0], v[c1], v[c2], v[c3]}
}

@(require_results)
vector4f32_swizzle1 :: proc "contextless" (v: Vector4f32, c0: Vector4_Components) -> f32 {
	return v[c0]
}
@(require_results)
vector4f32_swizzle2 :: proc "contextless" (v: Vector4f32, c0, c1: Vector4_Components) -> Vector2f32 {
	return {v[c0], v[c1]}
}
@(require_results)
vector4f32_swizzle3 :: proc "contextless" (v: Vector4f32, c0, c1, c2: Vector4_Components) -> Vector3f32 {
	return {v[c0], v[c1], v[c2]}
}
@(require_results)
vector4f32_swizzle4 :: proc "contextless" (v: Vector4f32, c0, c1, c2, c3: Vector4_Components) -> Vector4f32 {
	return {v[c0], v[c1], v[c2], v[c3]}
}


@(require_results)
scalar_f64_swizzle1 :: proc "contextless" (f: f64, c0: Scalar_Components) -> f64 {
	return f
}
@(require_results)
scalar_f64_swizzle2 :: proc "contextless" (f: f64, c0, c1: Scalar_Components) -> Vector2f64 {
	return {f, f}
}
@(require_results)
scalar_f64_swizzle3 :: proc "contextless" (f: f64, c0, c1, c2: Scalar_Components) -> Vector3f64 {
	return {f, f, f}
}
@(require_results)
scalar_f64_swizzle4 :: proc "contextless" (f: f64, c0, c1, c2, c3: Scalar_Components) -> Vector4f64 {
	return {f, f, f, f}
}

@(require_results)
vector2f64_swizzle1 :: proc "contextless" (v: Vector2f64, c0: Vector2_Components) -> f64 {
	return v[c0]
}
@(require_results)
vector2f64_swizzle2 :: proc "contextless" (v: Vector2f64, c0, c1: Vector2_Components) -> Vector2f64 {
	return {v[c0], v[c1]}
}
@(require_results)
vector2f64_swizzle3 :: proc "contextless" (v: Vector2f64, c0, c1, c2: Vector2_Components) -> Vector3f64 {
	return {v[c0], v[c1], v[c2]}
}
@(require_results)
vector2f64_swizzle4 :: proc "contextless" (v: Vector2f64, c0, c1, c2, c3: Vector2_Components) -> Vector4f64 {
	return {v[c0], v[c1], v[c2], v[c3]}
}


@(require_results)
vector3f64_swizzle1 :: proc "contextless" (v: Vector3f64, c0: Vector3_Components) -> f64 {
	return v[c0]
}
@(require_results)
vector3f64_swizzle2 :: proc "contextless" (v: Vector3f64, c0, c1: Vector3_Components) -> Vector2f64 {
	return {v[c0], v[c1]}
}
@(require_results)
vector3f64_swizzle3 :: proc "contextless" (v: Vector3f64, c0, c1, c2: Vector3_Components) -> Vector3f64 {
	return {v[c0], v[c1], v[c2]}
}
@(require_results)
vector3f64_swizzle4 :: proc "contextless" (v: Vector3f64, c0, c1, c2, c3: Vector3_Components) -> Vector4f64 {
	return {v[c0], v[c1], v[c2], v[c3]}
}

@(require_results)
vector4f64_swizzle1 :: proc "contextless" (v: Vector4f64, c0: Vector4_Components) -> f64 {
	return v[c0]
}
@(require_results)
vector4f64_swizzle2 :: proc "contextless" (v: Vector4f64, c0, c1: Vector4_Components) -> Vector2f64 {
	return {v[c0], v[c1]}
}
@(require_results)
vector4f64_swizzle3 :: proc "contextless" (v: Vector4f64, c0, c1, c2: Vector4_Components) -> Vector3f64 {
	return {v[c0], v[c1], v[c2]}
}
@(require_results)
vector4f64_swizzle4 :: proc "contextless" (v: Vector4f64, c0, c1, c2, c3: Vector4_Components) -> Vector4f64 {
	return {v[c0], v[c1], v[c2], v[c3]}
}




scalar_swizzle :: proc{
	scalar_f32_swizzle1,
	scalar_f32_swizzle2,
	scalar_f32_swizzle3,
	scalar_f32_swizzle4,
	scalar_f64_swizzle1,
	scalar_f64_swizzle2,
	scalar_f64_swizzle3,
	scalar_f64_swizzle4,
}

vector2_swizzle :: proc{
	vector2f32_swizzle1,
	vector2f32_swizzle2,
	vector2f32_swizzle3,
	vector2f32_swizzle4,
	vector2f64_swizzle1,
	vector2f64_swizzle2,
	vector2f64_swizzle3,
	vector2f64_swizzle4,
}

vector3_swizzle :: proc{
	vector3f32_swizzle1,
	vector3f32_swizzle2,
	vector3f32_swizzle3,
	vector3f32_swizzle4,
	vector3f64_swizzle1,
	vector3f64_swizzle2,
	vector3f64_swizzle3,
	vector3f64_swizzle4,
}

vector4_swizzle :: proc{
	vector4f32_swizzle1,
	vector4f32_swizzle2,
	vector4f32_swizzle3,
	vector4f32_swizzle4,
	vector4f64_swizzle1,
	vector4f64_swizzle2,
	vector4f64_swizzle3,
	vector4f64_swizzle4,
}

swizzle :: proc{
	scalar_f32_swizzle1,
	scalar_f32_swizzle2,
	scalar_f32_swizzle3,
	scalar_f32_swizzle4,
	scalar_f64_swizzle1,
	scalar_f64_swizzle2,
	scalar_f64_swizzle3,
	scalar_f64_swizzle4,
	vector2f32_swizzle1,
	vector2f32_swizzle2,
	vector2f32_swizzle3,
	vector2f32_swizzle4,
	vector2f64_swizzle1,
	vector2f64_swizzle2,
	vector2f64_swizzle3,
	vector2f64_swizzle4,
	vector3f32_swizzle1,
	vector3f32_swizzle2,
	vector3f32_swizzle3,
	vector3f32_swizzle4,
	vector3f64_swizzle1,
	vector3f64_swizzle2,
	vector3f64_swizzle3,
	vector3f64_swizzle4,
	vector4f32_swizzle1,
	vector4f32_swizzle2,
	vector4f32_swizzle3,
	vector4f32_swizzle4,
	vector4f64_swizzle1,
	vector4f64_swizzle2,
	vector4f64_swizzle3,
	vector4f64_swizzle4,
}
