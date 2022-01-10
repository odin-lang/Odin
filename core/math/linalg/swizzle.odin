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

scalar_f32_swizzle1 :: proc(f: f32, c0: Scalar_Components) -> f32 {
	return f
}
scalar_f32_swizzle2 :: proc(f: f32, c0, c1: Scalar_Components) -> Vector2f32 {
	return {f, f}
}
scalar_f32_swizzle3 :: proc(f: f32, c0, c1, c2: Scalar_Components) -> Vector3f32 {
	return {f, f, f}
}
scalar_f32_swizzle4 :: proc(f: f32, c0, c1, c2, c3: Scalar_Components) -> Vector4f32 {
	return {f, f, f, f}
}

vector2f32_swizzle1 :: proc(v: Vector2f32, c0: Vector2_Components) -> f32 {
	return v[c0]
}
vector2f32_swizzle2 :: proc(v: Vector2f32, c0, c1: Vector2_Components) -> Vector2f32 {
	return {v[c0], v[c1]}
}
vector2f32_swizzle3 :: proc(v: Vector2f32, c0, c1, c2: Vector2_Components) -> Vector3f32 {
	return {v[c0], v[c1], v[c2]}
}
vector2f32_swizzle4 :: proc(v: Vector2f32, c0, c1, c2, c3: Vector2_Components) -> Vector4f32 {
	return {v[c0], v[c1], v[c2], v[c3]}
}


vector3f32_swizzle1 :: proc(v: Vector3f32, c0: Vector3_Components) -> f32 {
	return v[c0]
}
vector3f32_swizzle2 :: proc(v: Vector3f32, c0, c1: Vector3_Components) -> Vector2f32 {
	return {v[c0], v[c1]}
}
vector3f32_swizzle3 :: proc(v: Vector3f32, c0, c1, c2: Vector3_Components) -> Vector3f32 {
	return {v[c0], v[c1], v[c2]}
}
vector3f32_swizzle4 :: proc(v: Vector3f32, c0, c1, c2, c3: Vector3_Components) -> Vector4f32 {
	return {v[c0], v[c1], v[c2], v[c3]}
}

vector4f32_swizzle1 :: proc(v: Vector4f32, c0: Vector4_Components) -> f32 {
	return v[c0]
}
vector4f32_swizzle2 :: proc(v: Vector4f32, c0, c1: Vector4_Components) -> Vector2f32 {
	return {v[c0], v[c1]}
}
vector4f32_swizzle3 :: proc(v: Vector4f32, c0, c1, c2: Vector4_Components) -> Vector3f32 {
	return {v[c0], v[c1], v[c2]}
}
vector4f32_swizzle4 :: proc(v: Vector4f32, c0, c1, c2, c3: Vector4_Components) -> Vector4f32 {
	return {v[c0], v[c1], v[c2], v[c3]}
}


scalar_f64_swizzle1 :: proc(f: f64, c0: Scalar_Components) -> f64 {
	return f
}
scalar_f64_swizzle2 :: proc(f: f64, c0, c1: Scalar_Components) -> Vector2f64 {
	return {f, f}
}
scalar_f64_swizzle3 :: proc(f: f64, c0, c1, c2: Scalar_Components) -> Vector3f64 {
	return {f, f, f}
}
scalar_f64_swizzle4 :: proc(f: f64, c0, c1, c2, c3: Scalar_Components) -> Vector4f64 {
	return {f, f, f, f}
}

vector2f64_swizzle1 :: proc(v: Vector2f64, c0: Vector2_Components) -> f64 {
	return v[c0]
}
vector2f64_swizzle2 :: proc(v: Vector2f64, c0, c1: Vector2_Components) -> Vector2f64 {
	return {v[c0], v[c1]}
}
vector2f64_swizzle3 :: proc(v: Vector2f64, c0, c1, c2: Vector2_Components) -> Vector3f64 {
	return {v[c0], v[c1], v[c2]}
}
vector2f64_swizzle4 :: proc(v: Vector2f64, c0, c1, c2, c3: Vector2_Components) -> Vector4f64 {
	return {v[c0], v[c1], v[c2], v[c3]}
}


vector3f64_swizzle1 :: proc(v: Vector3f64, c0: Vector3_Components) -> f64 {
	return v[c0]
}
vector3f64_swizzle2 :: proc(v: Vector3f64, c0, c1: Vector3_Components) -> Vector2f64 {
	return {v[c0], v[c1]}
}
vector3f64_swizzle3 :: proc(v: Vector3f64, c0, c1, c2: Vector3_Components) -> Vector3f64 {
	return {v[c0], v[c1], v[c2]}
}
vector3f64_swizzle4 :: proc(v: Vector3f64, c0, c1, c2, c3: Vector3_Components) -> Vector4f64 {
	return {v[c0], v[c1], v[c2], v[c3]}
}

vector4f64_swizzle1 :: proc(v: Vector4f64, c0: Vector4_Components) -> f64 {
	return v[c0]
}
vector4f64_swizzle2 :: proc(v: Vector4f64, c0, c1: Vector4_Components) -> Vector2f64 {
	return {v[c0], v[c1]}
}
vector4f64_swizzle3 :: proc(v: Vector4f64, c0, c1, c2: Vector4_Components) -> Vector3f64 {
	return {v[c0], v[c1], v[c2]}
}
vector4f64_swizzle4 :: proc(v: Vector4f64, c0, c1, c2, c3: Vector4_Components) -> Vector4f64 {
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
