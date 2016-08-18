type Vec2: {2}f32
type Vec3: {3}f32
type Vec4: {4}f32
type Mat2: {4}f32



sqrt_f32 :: proc(x: f32) -> f32 #foreign "llvm.sqrt.f32"
sqrt_f64 :: proc(x: f64) -> f64 #foreign "llvm.sqrt.f64"

vec2_dot :: proc(a, b: Vec2) -> f32 { c := a*b; return c[0] + c[1]; }
vec3_dot :: proc(a, b: Vec3) -> f32 { c := a*b; return c[0] + c[1] + c[2]; }

lerp :: proc(a, b, t: f32) -> f32 { return a*(1-t) + b*t; }

vec2_mag :: proc(a: Vec2) -> f32 { return sqrt_f32(vec2_dot(a, a)); }
vec3_mag :: proc(a: Vec3) -> f32 { return sqrt_f32(vec3_dot(a, a)); }

