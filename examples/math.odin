type Vec2: {2}f32
type Vec3: {3}f32
type Vec4: {4}f32
type Mat2: {4}f32



sqrtf :: proc(x: f32) -> f32 #foreign "llvm.sqrt.f32"
sinf  :: proc(x: f32) -> f32 #foreign "llvm.sin.f32"
cosf  :: proc(x: f32) -> f32 #foreign "llvm.cos.f32"

vec2_dot :: proc(a, b: Vec2) -> f32 { c := a*b; return c[0] + c[1]; }
vec3_dot :: proc(a, b: Vec3) -> f32 { c := a*b; return c[0] + c[1] + c[2]; }

lerp :: proc(a, b, t: f32) -> f32 { return a*(1-t) + b*t; }

vec2_mag :: proc(a: Vec2) -> f32 { return sqrtf(vec2_dot(a, a)); }
vec3_mag :: proc(a: Vec3) -> f32 { return sqrtf(vec3_dot(a, a)); }

