// core:math/linalg/hlsl implements a HLSL-like mathematics library plus numerous other utility procedures
package math_linalg_hlsl

import "core:builtin"

TAU :: 6.28318530717958647692528676655900576
PI  :: 3.14159265358979323846264338327950288
E   :: 2.71828182845904523536
τ   :: TAU
π   :: PI
e   :: E

SQRT_TWO   :: 1.41421356237309504880168872420969808
SQRT_THREE :: 1.73205080756887729352744634150587236
SQRT_FIVE  :: 2.23606797749978969640917366873127623

LN2  :: 0.693147180559945309417232121458176568
LN10 :: 2.30258509299404568401799145468436421

FLOAT_EPSILON :: 1e-7
DOUBLE_EPSILON :: 1e-15

// Aliases (not distinct) of types
float  :: f32
double :: f64
int    :: builtin.i32
uint   :: builtin.u32

// Odin matrices are stored internally as Column-Major, which matches the internal layout of HLSL by default
float1x1 :: distinct matrix[1, 1]float
float2x2 :: distinct matrix[2, 2]float
float3x3 :: distinct matrix[3, 3]float
float4x4 :: distinct matrix[4, 4]float

float1x2 :: distinct matrix[1, 2]float
float1x3 :: distinct matrix[1, 3]float
float1x4 :: distinct matrix[1, 4]float
float2x1 :: distinct matrix[2, 1]float
float2x3 :: distinct matrix[2, 3]float
float2x4 :: distinct matrix[2, 4]float
float3x1 :: distinct matrix[3, 1]float
float3x2 :: distinct matrix[3, 2]float
float3x4 :: distinct matrix[3, 4]float
float4x1 :: distinct matrix[4, 1]float
float4x2 :: distinct matrix[4, 2]float
float4x3 :: distinct matrix[4, 3]float

float2 :: distinct [2]float
float3 :: distinct [3]float
float4 :: distinct [4]float

int2 :: distinct [2]int
int3 :: distinct [3]int
int4 :: distinct [4]int

uint2 :: distinct [2]uint
uint3 :: distinct [3]uint
uint4 :: distinct [4]uint

bool2 :: distinct [2]bool
bool3 :: distinct [3]bool
bool4 :: distinct [4]bool

// Double Precision (double) Floating Point Types 

double1x1 :: distinct matrix[1, 1]double
double2x2 :: distinct matrix[2, 2]double
double3x3 :: distinct matrix[3, 3]double
double4x4 :: distinct matrix[4, 4]double

double1x2 :: distinct matrix[1, 2]double
double1x3 :: distinct matrix[1, 3]double
double1x4 :: distinct matrix[1, 4]double
double2x1 :: distinct matrix[2, 1]double
double2x3 :: distinct matrix[2, 3]double
double2x4 :: distinct matrix[2, 4]double
double3x1 :: distinct matrix[3, 1]double
double3x2 :: distinct matrix[3, 2]double
double3x4 :: distinct matrix[3, 4]double
double4x1 :: distinct matrix[4, 1]double
double4x2 :: distinct matrix[4, 2]double
double4x3 :: distinct matrix[4, 3]double

double2 :: distinct [2]double
double3 :: distinct [3]double
double4 :: distinct [4]double


int1x1 :: distinct matrix[1, 1]int
int2x2 :: distinct matrix[2, 2]int
int3x3 :: distinct matrix[3, 3]int
int4x4 :: distinct matrix[4, 4]int

int1x2 :: distinct matrix[1, 2]int
int1x3 :: distinct matrix[1, 3]int
int1x4 :: distinct matrix[1, 4]int
int2x1 :: distinct matrix[2, 1]int
int2x3 :: distinct matrix[2, 3]int
int2x4 :: distinct matrix[2, 4]int
int3x1 :: distinct matrix[3, 1]int
int3x2 :: distinct matrix[3, 2]int
int3x4 :: distinct matrix[3, 4]int
int4x1 :: distinct matrix[4, 1]int
int4x2 :: distinct matrix[4, 2]int
int4x3 :: distinct matrix[4, 3]int

cos :: proc{
	cos_float,
	cos_double,
	cos_float2,
	cos_float3,
	cos_float4,
	cos_double2,
	cos_double3,
	cos_double4,
}
cos_float2 :: proc "c" (x: float2) -> float2 { return {cos(x.x), cos(x.y)} }
cos_float3 :: proc "c" (x: float3) -> float3 { return {cos(x.x), cos(x.y), cos(x.z)} }
cos_float4 :: proc "c" (x: float4) -> float4 { return {cos(x.x), cos(x.y), cos(x.z), cos(x.w)} }
cos_double2 :: proc "c" (x: double2) -> double2 { return {cos(x.x), cos(x.y)} }
cos_double3 :: proc "c" (x: double3) -> double3 { return {cos(x.x), cos(x.y), cos(x.z)} }
cos_double4 :: proc "c" (x: double4) -> double4 { return {cos(x.x), cos(x.y), cos(x.z), cos(x.w)} }

sin :: proc{
	sin_float,
	sin_double,
	sin_float2,
	sin_float3,
	sin_float4,
	sin_double2,
	sin_double3,
	sin_double4,
}
sin_float2 :: proc "c" (x: float2) -> float2 { return {sin(x.x), sin(x.y)} }
sin_float3 :: proc "c" (x: float3) -> float3 { return {sin(x.x), sin(x.y), sin(x.z)} }
sin_float4 :: proc "c" (x: float4) -> float4 { return {sin(x.x), sin(x.y), sin(x.z), sin(x.w)} }
sin_double2 :: proc "c" (x: double2) -> double2 { return {sin(x.x), sin(x.y)} }
sin_double3 :: proc "c" (x: double3) -> double3 { return {sin(x.x), sin(x.y), sin(x.z)} }
sin_double4 :: proc "c" (x: double4) -> double4 { return {sin(x.x), sin(x.y), sin(x.z), sin(x.w)} }

tan :: proc{
	tan_float,
	tan_double,
	tan_float2,
	tan_float3,
	tan_float4,
	tan_double2,
	tan_double3,
	tan_double4,
}
tan_float2 :: proc "c" (x: float2) -> float2 { return {tan(x.x), tan(x.y)} }
tan_float3 :: proc "c" (x: float3) -> float3 { return {tan(x.x), tan(x.y), tan(x.z)} }
tan_float4 :: proc "c" (x: float4) -> float4 { return {tan(x.x), tan(x.y), tan(x.z), tan(x.w)} }
tan_double2 :: proc "c" (x: double2) -> double2 { return {tan(x.x), tan(x.y)} }
tan_double3 :: proc "c" (x: double3) -> double3 { return {tan(x.x), tan(x.y), tan(x.z)} }
tan_double4 :: proc "c" (x: double4) -> double4 { return {tan(x.x), tan(x.y), tan(x.z), tan(x.w)} }

acos :: proc{
	acos_float,
	acos_double,
	acos_float2,
	acos_float3,
	acos_float4,
	acos_double2,
	acos_double3,
	acos_double4,
}
acos_float2 :: proc "c" (x: float2) -> float2 { return {acos(x.x), acos(x.y)} }
acos_float3 :: proc "c" (x: float3) -> float3 { return {acos(x.x), acos(x.y), acos(x.z)} }
acos_float4 :: proc "c" (x: float4) -> float4 { return {acos(x.x), acos(x.y), acos(x.z), acos(x.w)} }
acos_double2 :: proc "c" (x: double2) -> double2 { return {acos(x.x), acos(x.y)} }
acos_double3 :: proc "c" (x: double3) -> double3 { return {acos(x.x), acos(x.y), acos(x.z)} }
acos_double4 :: proc "c" (x: double4) -> double4 { return {acos(x.x), acos(x.y), acos(x.z), acos(x.w)} }

asin :: proc{
	asin_float,
	asin_double,
	asin_float2,
	asin_float3,
	asin_float4,
	asin_double2,
	asin_double3,
	asin_double4,
}
asin_float2 :: proc "c" (x: float2) -> float2 { return {asin(x.x), asin(x.y)} }
asin_float3 :: proc "c" (x: float3) -> float3 { return {asin(x.x), asin(x.y), asin(x.z)} }
asin_float4 :: proc "c" (x: float4) -> float4 { return {asin(x.x), asin(x.y), asin(x.z), asin(x.w)} }
asin_double2 :: proc "c" (x: double2) -> double2 { return {asin(x.x), asin(x.y)} }
asin_double3 :: proc "c" (x: double3) -> double3 { return {asin(x.x), asin(x.y), asin(x.z)} }
asin_double4 :: proc "c" (x: double4) -> double4 { return {asin(x.x), asin(x.y), asin(x.z), asin(x.w)} }

atan :: proc{
	atan_float,
	atan_double,
	atan_float2,
	atan_float3,
	atan_float4,
	atan_double2,
	atan_double3,
	atan_double4,
	atan2_float,
	atan2_double,
	atan2_float2,
	atan2_float3,
	atan2_float4,
	atan2_double2,
	atan2_double3,
	atan2_double4,
}
atan_float2 :: proc "c" (x: float2) -> float2 { return {atan(x.x), atan(x.y)} }
atan_float3 :: proc "c" (x: float3) -> float3 { return {atan(x.x), atan(x.y), atan(x.z)} }
atan_float4 :: proc "c" (x: float4) -> float4 { return {atan(x.x), atan(x.y), atan(x.z), atan(x.w)} }
atan_double2 :: proc "c" (x: double2) -> double2 { return {atan(x.x), atan(x.y)} }
atan_double3 :: proc "c" (x: double3) -> double3 { return {atan(x.x), atan(x.y), atan(x.z)} }
atan_double4 :: proc "c" (x: double4) -> double4 { return {atan(x.x), atan(x.y), atan(x.z), atan(x.w)} }

atan2 :: proc{
	atan2_float,
	atan2_double,
	atan2_float2,
	atan2_float3,
	atan2_float4,
	atan2_double2,
	atan2_double3,
	atan2_double4,
}
atan2_float2 :: proc "c" (y, x: float2) -> float2 { return {atan2(y.x, x.x), atan2(y.y, x.y)} }
atan2_float3 :: proc "c" (y, x: float3) -> float3 { return {atan2(y.x, x.x), atan2(y.y, x.y), atan2(y.z, x.z)} }
atan2_float4 :: proc "c" (y, x: float4) -> float4 { return {atan2(y.x, x.x), atan2(y.y, x.y), atan2(y.z, x.z), atan2(y.w, x.w)} }
atan2_double2 :: proc "c" (y, x: double2) -> double2 { return {atan2(y.x, x.x), atan2(y.y, x.y)} }
atan2_double3 :: proc "c" (y, x: double3) -> double3 { return {atan2(y.x, x.x), atan2(y.y, x.y), atan2(y.z, x.z)} }
atan2_double4 :: proc "c" (y, x: double4) -> double4 { return {atan2(y.x, x.x), atan2(y.y, x.y), atan2(y.z, x.z), atan2(y.w, x.w)} }



cosh :: proc{
	cosh_float,
	cosh_double,
	cosh_float2,
	cosh_float3,
	cosh_float4,
	cosh_double2,
	cosh_double3,
	cosh_double4,
}
cosh_float2 :: proc "c" (x: float2) -> float2 { return {cosh(x.x), cosh(x.y)} }
cosh_float3 :: proc "c" (x: float3) -> float3 { return {cosh(x.x), cosh(x.y), cosh(x.z)} }
cosh_float4 :: proc "c" (x: float4) -> float4 { return {cosh(x.x), cosh(x.y), cosh(x.z), cosh(x.w)} }
cosh_double2 :: proc "c" (x: double2) -> double2 { return {cosh(x.x), cosh(x.y)} }
cosh_double3 :: proc "c" (x: double3) -> double3 { return {cosh(x.x), cosh(x.y), cosh(x.z)} }
cosh_double4 :: proc "c" (x: double4) -> double4 { return {cosh(x.x), cosh(x.y), cosh(x.z), cosh(x.w)} }


sinh :: proc{
	sinh_float,
	sinh_double,
	sinh_float2,
	sinh_float3,
	sinh_float4,
	sinh_double2,
	sinh_double3,
	sinh_double4,
}
sinh_float2 :: proc "c" (x: float2) -> float2 { return {sinh(x.x), sinh(x.y)} }
sinh_float3 :: proc "c" (x: float3) -> float3 { return {sinh(x.x), sinh(x.y), sinh(x.z)} }
sinh_float4 :: proc "c" (x: float4) -> float4 { return {sinh(x.x), sinh(x.y), sinh(x.z), sinh(x.w)} }
sinh_double2 :: proc "c" (x: double2) -> double2 { return {sinh(x.x), sinh(x.y)} }
sinh_double3 :: proc "c" (x: double3) -> double3 { return {sinh(x.x), sinh(x.y), sinh(x.z)} }
sinh_double4 :: proc "c" (x: double4) -> double4 { return {sinh(x.x), sinh(x.y), sinh(x.z), sinh(x.w)} }

tanh :: proc{
	tanh_float,
	tanh_double,
	tanh_float2,
	tanh_float3,
	tanh_float4,
	tanh_double2,
	tanh_double3,
	tanh_double4,
}
tanh_float2 :: proc "c" (x: float2) -> float2 { return {tanh(x.x), tanh(x.y)} }
tanh_float3 :: proc "c" (x: float3) -> float3 { return {tanh(x.x), tanh(x.y), tanh(x.z)} }
tanh_float4 :: proc "c" (x: float4) -> float4 { return {tanh(x.x), tanh(x.y), tanh(x.z), tanh(x.w)} }
tanh_double2 :: proc "c" (x: double2) -> double2 { return {tanh(x.x), tanh(x.y)} }
tanh_double3 :: proc "c" (x: double3) -> double3 { return {tanh(x.x), tanh(x.y), tanh(x.z)} }
tanh_double4 :: proc "c" (x: double4) -> double4 { return {tanh(x.x), tanh(x.y), tanh(x.z), tanh(x.w)} }

acosh :: proc{
	acosh_float,
	acosh_double,
	acosh_float2,
	acosh_float3,
	acosh_float4,
	acosh_double2,
	acosh_double3,
	acosh_double4,
}
acosh_float2 :: proc "c" (x: float2) -> float2 { return {acosh(x.x), acosh(x.y)} }
acosh_float3 :: proc "c" (x: float3) -> float3 { return {acosh(x.x), acosh(x.y), acosh(x.z)} }
acosh_float4 :: proc "c" (x: float4) -> float4 { return {acosh(x.x), acosh(x.y), acosh(x.z), acosh(x.w)} }
acosh_double2 :: proc "c" (x: double2) -> double2 { return {acosh(x.x), acosh(x.y)} }
acosh_double3 :: proc "c" (x: double3) -> double3 { return {acosh(x.x), acosh(x.y), acosh(x.z)} }
acosh_double4 :: proc "c" (x: double4) -> double4 { return {acosh(x.x), acosh(x.y), acosh(x.z), acosh(x.w)} }

asinh :: proc{
	asinh_float,
	asinh_double,
	asinh_float2,
	asinh_float3,
	asinh_float4,
	asinh_double2,
	asinh_double3,
	asinh_double4,
}
asinh_float2 :: proc "c" (x: float2) -> float2 { return {asinh(x.x), asinh(x.y)} }
asinh_float3 :: proc "c" (x: float3) -> float3 { return {asinh(x.x), asinh(x.y), asinh(x.z)} }
asinh_float4 :: proc "c" (x: float4) -> float4 { return {asinh(x.x), asinh(x.y), asinh(x.z), asinh(x.w)} }
asinh_double2 :: proc "c" (x: double2) -> double2 { return {asinh(x.x), asinh(x.y)} }
asinh_double3 :: proc "c" (x: double3) -> double3 { return {asinh(x.x), asinh(x.y), asinh(x.z)} }
asinh_double4 :: proc "c" (x: double4) -> double4 { return {asinh(x.x), asinh(x.y), asinh(x.z), asinh(x.w)} }

atanh :: proc{
	atanh_float,
	atanh_double,
	atanh_float2,
	atanh_float3,
	atanh_float4,
	atanh_double2,
	atanh_double3,
	atanh_double4,
}
atanh_float2 :: proc "c" (x: float2) -> float2 { return {atanh(x.x), atanh(x.y)} }
atanh_float3 :: proc "c" (x: float3) -> float3 { return {atanh(x.x), atanh(x.y), atanh(x.z)} }
atanh_float4 :: proc "c" (x: float4) -> float4 { return {atanh(x.x), atanh(x.y), atanh(x.z), atanh(x.w)} }
atanh_double2 :: proc "c" (x: double2) -> double2 { return {atanh(x.x), atanh(x.y)} }
atanh_double3 :: proc "c" (x: double3) -> double3 { return {atanh(x.x), atanh(x.y), atanh(x.z)} }
atanh_double4 :: proc "c" (x: double4) -> double4 { return {atanh(x.x), atanh(x.y), atanh(x.z), atanh(x.w)} }

sqrt :: proc{
	sqrt_float,
	sqrt_double,
	sqrt_float2,
	sqrt_float3,
	sqrt_float4,
	sqrt_double2,
	sqrt_double3,
	sqrt_double4,
}
sqrt_float2 :: proc "c" (x: float2) -> float2 { return {sqrt(x.x), sqrt(x.y)} }
sqrt_float3 :: proc "c" (x: float3) -> float3 { return {sqrt(x.x), sqrt(x.y), sqrt(x.z)} }
sqrt_float4 :: proc "c" (x: float4) -> float4 { return {sqrt(x.x), sqrt(x.y), sqrt(x.z), sqrt(x.w)} }
sqrt_double2 :: proc "c" (x: double2) -> double2 { return {sqrt(x.x), sqrt(x.y)} }
sqrt_double3 :: proc "c" (x: double3) -> double3 { return {sqrt(x.x), sqrt(x.y), sqrt(x.z)} }
sqrt_double4 :: proc "c" (x: double4) -> double4 { return {sqrt(x.x), sqrt(x.y), sqrt(x.z), sqrt(x.w)} }

rsqrt :: proc{
	rsqrt_float,
	rsqrt_double,
	rsqrt_float2,
	rsqrt_float3,
	rsqrt_float4,
	rsqrt_double2,
	rsqrt_double3,
	rsqrt_double4,
}
rsqrt_float2 :: proc "c" (x: float2) -> float2 { return {rsqrt(x.x), rsqrt(x.y)} }
rsqrt_float3 :: proc "c" (x: float3) -> float3 { return {rsqrt(x.x), rsqrt(x.y), rsqrt(x.z)} }
rsqrt_float4 :: proc "c" (x: float4) -> float4 { return {rsqrt(x.x), rsqrt(x.y), rsqrt(x.z), rsqrt(x.w)} }
rsqrt_double2 :: proc "c" (x: double2) -> double2 { return {rsqrt(x.x), rsqrt(x.y)} }
rsqrt_double3 :: proc "c" (x: double3) -> double3 { return {rsqrt(x.x), rsqrt(x.y), rsqrt(x.z)} }
rsqrt_double4 :: proc "c" (x: double4) -> double4 { return {rsqrt(x.x), rsqrt(x.y), rsqrt(x.z), rsqrt(x.w)} }

rcp :: proc{
	rcp_float,
	rcp_double,
	rcp_float2,
	rcp_float3,
	rcp_float4,
	rcp_double2,
	rcp_double3,
	rcp_double4,
}
rcp_float2 :: proc "c" (x: float2) -> float2 { return {rcp(x.x), rcp(x.y)} }
rcp_float3 :: proc "c" (x: float3) -> float3 { return {rcp(x.x), rcp(x.y), rcp(x.z)} }
rcp_float4 :: proc "c" (x: float4) -> float4 { return {rcp(x.x), rcp(x.y), rcp(x.z), rcp(x.w)} }
rcp_double2 :: proc "c" (x: double2) -> double2 { return {rcp(x.x), rcp(x.y)} }
rcp_double3 :: proc "c" (x: double3) -> double3 { return {rcp(x.x), rcp(x.y), rcp(x.z)} }
rcp_double4 :: proc "c" (x: double4) -> double4 { return {rcp(x.x), rcp(x.y), rcp(x.z), rcp(x.w)} }


pow :: proc{
	pow_float,
	pow_double,
	pow_float2,
	pow_float3,
	pow_float4,
	pow_double2,
	pow_double3,
	pow_double4,
}
pow_float2 :: proc "c" (x, y: float2) -> float2 { return {pow(x.x, y.x), pow(x.y, y.y)} }
pow_float3 :: proc "c" (x, y: float3) -> float3 { return {pow(x.x, y.x), pow(x.y, y.y), pow(x.z, y.z)} }
pow_float4 :: proc "c" (x, y: float4) -> float4 { return {pow(x.x, y.x), pow(x.y, y.y), pow(x.z, y.z), pow(x.w, y.w)} }
pow_double2 :: proc "c" (x, y: double2) -> double2 { return {pow(x.x, y.x), pow(x.y, y.y)} }
pow_double3 :: proc "c" (x, y: double3) -> double3 { return {pow(x.x, y.x), pow(x.y, y.y), pow(x.z, y.z)} }
pow_double4 :: proc "c" (x, y: double4) -> double4 { return {pow(x.x, y.x), pow(x.y, y.y), pow(x.z, y.z), pow(x.w, y.w)} }



exp :: proc{
	exp_float,
	exp_double,
	exp_float2,
	exp_float3,
	exp_float4,
	exp_double2,
	exp_double3,
	exp_double4,
}
exp_float2 :: proc "c" (x: float2) -> float2 { return {exp(x.x), exp(x.y)} }
exp_float3 :: proc "c" (x: float3) -> float3 { return {exp(x.x), exp(x.y), exp(x.z)} }
exp_float4 :: proc "c" (x: float4) -> float4 { return {exp(x.x), exp(x.y), exp(x.z), exp(x.w)} }
exp_double2 :: proc "c" (x: double2) -> double2 { return {exp(x.x), exp(x.y)} }
exp_double3 :: proc "c" (x: double3) -> double3 { return {exp(x.x), exp(x.y), exp(x.z)} }
exp_double4 :: proc "c" (x: double4) -> double4 { return {exp(x.x), exp(x.y), exp(x.z), exp(x.w)} }



log :: proc{
	log_float,
	log_double,
	log_float2,
	log_float3,
	log_float4,
	log_double2,
	log_double3,
	log_double4,
}
log_float2 :: proc "c" (x: float2) -> float2 { return {log(x.x), log(x.y)} }
log_float3 :: proc "c" (x: float3) -> float3 { return {log(x.x), log(x.y), log(x.z)} }
log_float4 :: proc "c" (x: float4) -> float4 { return {log(x.x), log(x.y), log(x.z), log(x.w)} }
log_double2 :: proc "c" (x: double2) -> double2 { return {log(x.x), log(x.y)} }
log_double3 :: proc "c" (x: double3) -> double3 { return {log(x.x), log(x.y), log(x.z)} }
log_double4 :: proc "c" (x: double4) -> double4 { return {log(x.x), log(x.y), log(x.z), log(x.w)} }


log2 :: proc{
	log2_float,
	log2_double,
	log2_float2,
	log2_float3,
	log2_float4,
	log2_double2,
	log2_double3,
	log2_double4,
}
log2_float2 :: proc "c" (x: float2) -> float2 { return {log2(x.x), log2(x.y)} }
log2_float3 :: proc "c" (x: float3) -> float3 { return {log2(x.x), log2(x.y), log2(x.z)} }
log2_float4 :: proc "c" (x: float4) -> float4 { return {log2(x.x), log2(x.y), log2(x.z), log2(x.w)} }
log2_double2 :: proc "c" (x: double2) -> double2 { return {log2(x.x), log2(x.y)} }
log2_double3 :: proc "c" (x: double3) -> double3 { return {log2(x.x), log2(x.y), log2(x.z)} }
log2_double4 :: proc "c" (x: double4) -> double4 { return {log2(x.x), log2(x.y), log2(x.z), log2(x.w)} }



log10 :: proc{
	log10_float,
	log10_double,
	log10_float2,
	log10_float3,
	log10_float4,
	log10_double2,
	log10_double3,
	log10_double4,
}
log10_float2 :: proc "c" (x: float2) -> float2 { return {log10(x.x), log10(x.y)} }
log10_float3 :: proc "c" (x: float3) -> float3 { return {log10(x.x), log10(x.y), log10(x.z)} }
log10_float4 :: proc "c" (x: float4) -> float4 { return {log10(x.x), log10(x.y), log10(x.z), log10(x.w)} }
log10_double2 :: proc "c" (x: double2) -> double2 { return {log10(x.x), log10(x.y)} }
log10_double3 :: proc "c" (x: double3) -> double3 { return {log10(x.x), log10(x.y), log10(x.z)} }
log10_double4 :: proc "c" (x: double4) -> double4 { return {log10(x.x), log10(x.y), log10(x.z), log10(x.w)} }




exp2 :: proc{
	exp2_float,
	exp2_double,
	exp2_float2,
	exp2_float3,
	exp2_float4,
	exp2_double2,
	exp2_double3,
	exp2_double4,
}
exp2_float2 :: proc "c" (x: float2) -> float2 { return {exp2(x.x), exp2(x.y)} }
exp2_float3 :: proc "c" (x: float3) -> float3 { return {exp2(x.x), exp2(x.y), exp2(x.z)} }
exp2_float4 :: proc "c" (x: float4) -> float4 { return {exp2(x.x), exp2(x.y), exp2(x.z), exp2(x.w)} }
exp2_double2 :: proc "c" (x: double2) -> double2 { return {exp2(x.x), exp2(x.y)} }
exp2_double3 :: proc "c" (x: double3) -> double3 { return {exp2(x.x), exp2(x.y), exp2(x.z)} }
exp2_double4 :: proc "c" (x: double4) -> double4 { return {exp2(x.x), exp2(x.y), exp2(x.z), exp2(x.w)} }


sign :: proc{
	sign_int,
	sign_uint,
	sign_float,
	sign_double,
	sign_float2,
	sign_float3,
	sign_float4,
	sign_double2,
	sign_double3,
	sign_double4,
	sign_int2,
	sign_int3,
	sign_int4,
	sign_uint2,
	sign_uint3,
	sign_uint4,
}
sign_int :: proc "c" (x: int) -> int { return -1 if x < 0 else +1 if x > 0 else 0 }
sign_uint :: proc "c" (x: uint) -> uint { return +1 if x > 0 else 0 }
sign_float2 :: proc "c" (x: float2) -> float2 { return {sign(x.x), sign(x.y)} }
sign_float3 :: proc "c" (x: float3) -> float3 { return {sign(x.x), sign(x.y), sign(x.z)} }
sign_float4 :: proc "c" (x: float4) -> float4 { return {sign(x.x), sign(x.y), sign(x.z), sign(x.w)} }
sign_double2 :: proc "c" (x: double2) -> double2 { return {sign(x.x), sign(x.y)} }
sign_double3 :: proc "c" (x: double3) -> double3 { return {sign(x.x), sign(x.y), sign(x.z)} }
sign_double4 :: proc "c" (x: double4) -> double4 { return {sign(x.x), sign(x.y), sign(x.z), sign(x.w)} }
sign_int2 :: proc "c" (x: int2) -> int2 { return {sign(x.x), sign(x.y)} }
sign_int3 :: proc "c" (x: int3) -> int3 { return {sign(x.x), sign(x.y), sign(x.z)} }
sign_int4 :: proc "c" (x: int4) -> int4 { return {sign(x.x), sign(x.y), sign(x.z), sign(x.w)} }
sign_uint2 :: proc "c" (x: uint2) -> uint2 { return {sign(x.x), sign(x.y)} }
sign_uint3 :: proc "c" (x: uint3) -> uint3 { return {sign(x.x), sign(x.y), sign(x.z)} }
sign_uint4 :: proc "c" (x: uint4) -> uint4 { return {sign(x.x), sign(x.y), sign(x.z), sign(x.w)} }

floor :: proc{
	floor_float,
	floor_double,
	floor_float2,
	floor_float3,
	floor_float4,
	floor_double2,
	floor_double3,
	floor_double4,
}
floor_float2 :: proc "c" (x: float2) -> float2 { return {floor(x.x), floor(x.y)} }
floor_float3 :: proc "c" (x: float3) -> float3 { return {floor(x.x), floor(x.y), floor(x.z)} }
floor_float4 :: proc "c" (x: float4) -> float4 { return {floor(x.x), floor(x.y), floor(x.z), floor(x.w)} }
floor_double2 :: proc "c" (x: double2) -> double2 { return {floor(x.x), floor(x.y)} }
floor_double3 :: proc "c" (x: double3) -> double3 { return {floor(x.x), floor(x.y), floor(x.z)} }
floor_double4 :: proc "c" (x: double4) -> double4 { return {floor(x.x), floor(x.y), floor(x.z), floor(x.w)} }


ceil :: proc{
	ceil_float,
	ceil_double,
	ceil_float2,
	ceil_float3,
	ceil_float4,
	ceil_double2,
	ceil_double3,
	ceil_double4,
}
ceil_float2 :: proc "c" (x: float2) -> float2 { return {ceil(x.x), ceil(x.y)} }
ceil_float3 :: proc "c" (x: float3) -> float3 { return {ceil(x.x), ceil(x.y), ceil(x.z)} }
ceil_float4 :: proc "c" (x: float4) -> float4 { return {ceil(x.x), ceil(x.y), ceil(x.z), ceil(x.w)} }
ceil_double2 :: proc "c" (x: double2) -> double2 { return {ceil(x.x), ceil(x.y)} }
ceil_double3 :: proc "c" (x: double3) -> double3 { return {ceil(x.x), ceil(x.y), ceil(x.z)} }
ceil_double4 :: proc "c" (x: double4) -> double4 { return {ceil(x.x), ceil(x.y), ceil(x.z), ceil(x.w)} }


fmod :: proc{
	fmod_float,
	fmod_double,
	fmod_float2,
	fmod_float3,
	fmod_float4,
	fmod_double2,
	fmod_double3,
	fmod_double4,
}
fmod_float2 :: proc "c" (x, y: float2) -> float2 { return {fmod(x.x, y.x), fmod(x.y, y.y)} }
fmod_float3 :: proc "c" (x, y: float3) -> float3 { return {fmod(x.x, y.x), fmod(x.y, y.y), fmod(x.z, y.z)} }
fmod_float4 :: proc "c" (x, y: float4) -> float4 { return {fmod(x.x, y.x), fmod(x.y, y.y), fmod(x.z, y.z), fmod(x.w, y.w)} }
fmod_double2 :: proc "c" (x, y: double2) -> double2 { return {fmod(x.x, y.x), fmod(x.y, y.y)} }
fmod_double3 :: proc "c" (x, y: double3) -> double3 { return {fmod(x.x, y.x), fmod(x.y, y.y), fmod(x.z, y.z)} }
fmod_double4 :: proc "c" (x, y: double4) -> double4 { return {fmod(x.x, y.x), fmod(x.y, y.y), fmod(x.z, y.z), fmod(x.w, y.w)} }


frac :: proc{
	frac_float,
	frac_double,
	frac_float2,
	frac_float3,
	frac_float4,
	frac_double2,
	frac_double3,
	frac_double4,
}
frac_float2 :: proc "c" (x: float2) -> float2 { return {frac(x.x), frac(x.y)} }
frac_float3 :: proc "c" (x: float3) -> float3 { return {frac(x.x), frac(x.y), frac(x.z)} }
frac_float4 :: proc "c" (x: float4) -> float4 { return {frac(x.x), frac(x.y), frac(x.z), frac(x.w)} }
frac_double2 :: proc "c" (x: double2) -> double2 { return {frac(x.x), frac(x.y)} }
frac_double3 :: proc "c" (x: double3) -> double3 { return {frac(x.x), frac(x.y), frac(x.z)} }
frac_double4 :: proc "c" (x: double4) -> double4 { return {frac(x.x), frac(x.y), frac(x.z), frac(x.w)} }



radians :: proc{
	radians_float,
	radians_double,
	radians_float2,
	radians_float3,
	radians_float4,
	radians_double2,
	radians_double3,
	radians_double4,
}
radians_float  :: proc "c" (degrees: float)  -> float  { return degrees * TAU / 360.0 }
radians_double  :: proc "c" (degrees: double)  -> double  { return degrees * TAU / 360.0 }
radians_float2 :: proc "c" (degrees: float2) -> float2 { return degrees * TAU / 360.0 }
radians_float3 :: proc "c" (degrees: float3) -> float3 { return degrees * TAU / 360.0 }
radians_float4 :: proc "c" (degrees: float4) -> float4 { return degrees * TAU / 360.0 }
radians_double2 :: proc "c" (degrees: double2) -> double2 { return degrees * TAU / 360.0 }
radians_double3 :: proc "c" (degrees: double3) -> double3 { return degrees * TAU / 360.0 }
radians_double4 :: proc "c" (degrees: double4) -> double4 { return degrees * TAU / 360.0 }


degrees :: proc{
	degrees_float,
	degrees_double,
	degrees_float2,
	degrees_float3,
	degrees_float4,
	degrees_double2,
	degrees_double3,
	degrees_double4,
}
degrees_float  :: proc "c" (radians: float)  -> float  { return radians * 360.0 / TAU }
degrees_double  :: proc "c" (radians: double)  -> double  { return radians * 360.0 / TAU }
degrees_float2 :: proc "c" (radians: float2) -> float2 { return radians * 360.0 / TAU }
degrees_float3 :: proc "c" (radians: float3) -> float3 { return radians * 360.0 / TAU }
degrees_float4 :: proc "c" (radians: float4) -> float4 { return radians * 360.0 / TAU }
degrees_double2 :: proc "c" (radians: double2) -> double2 { return radians * 360.0 / TAU }
degrees_double3 :: proc "c" (radians: double3) -> double3 { return radians * 360.0 / TAU }
degrees_double4 :: proc "c" (radians: double4) -> double4 { return radians * 360.0 / TAU }

min :: proc{
	min_int,  
	min_uint,  
	min_float,  
	min_double,
	min_float2, 
	min_float3, 
	min_float4, 
	min_double2, 
	min_double3, 
	min_double4, 
	min_int2,
	min_int3,
	min_int4,
	min_uint2,
	min_uint3,
	min_uint4,
}
min_int  :: proc "c" (x, y: int) -> int   { return builtin.min(x, y) }
min_uint  :: proc "c" (x, y: uint) -> uint   { return builtin.min(x, y) }
min_float  :: proc "c" (x, y: float) -> float   { return builtin.min(x, y) }
min_double  :: proc "c" (x, y: double) -> double   { return builtin.min(x, y) }
min_float2 :: proc "c" (x, y: float2) -> float2 { return {min(x.x, y.x), min(x.y, y.y)} }
min_float3 :: proc "c" (x, y: float3) -> float3 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z)} }
min_float4 :: proc "c" (x, y: float4) -> float4 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z), min(x.w, y.w)} }
min_double2 :: proc "c" (x, y: double2) -> double2 { return {min(x.x, y.x), min(x.y, y.y)} }
min_double3 :: proc "c" (x, y: double3) -> double3 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z)} }
min_double4 :: proc "c" (x, y: double4) -> double4 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z), min(x.w, y.w)} }
min_int2 :: proc "c" (x, y: int2) -> int2 { return {min(x.x, y.x), min(x.y, y.y)} }
min_int3 :: proc "c" (x, y: int3) -> int3 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z)} }
min_int4 :: proc "c" (x, y: int4) -> int4 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z), min(x.w, y.w)} }
min_uint2 :: proc "c" (x, y: uint2) -> uint2 { return {min(x.x, y.x), min(x.y, y.y)} }
min_uint3 :: proc "c" (x, y: uint3) -> uint3 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z)} }
min_uint4 :: proc "c" (x, y: uint4) -> uint4 { return {min(x.x, y.x), min(x.y, y.y), min(x.z, y.z), min(x.w, y.w)} }


max :: proc{
	max_int,  
	max_uint,  
	max_float,  
	max_double,
	max_float2, 
	max_float3, 
	max_float4, 
	max_double2, 
	max_double3, 
	max_double4, 
	max_int2,
	max_int3,
	max_int4,
	max_uint2,
	max_uint3,
	max_uint4,
}
max_int  :: proc "c" (x, y: int) -> int   { return builtin.max(x, y) }
max_uint  :: proc "c" (x, y: uint) -> uint   { return builtin.max(x, y) }
max_float  :: proc "c" (x, y: float) -> float   { return builtin.max(x, y) }
max_double  :: proc "c" (x, y: double) -> double   { return builtin.max(x, y) }
max_float2 :: proc "c" (x, y: float2) -> float2 { return {max(x.x, y.x), max(x.y, y.y)} }
max_float3 :: proc "c" (x, y: float3) -> float3 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z)} }
max_float4 :: proc "c" (x, y: float4) -> float4 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z), max(x.w, y.w)} }
max_double2 :: proc "c" (x, y: double2) -> double2 { return {max(x.x, y.x), max(x.y, y.y)} }
max_double3 :: proc "c" (x, y: double3) -> double3 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z)} }
max_double4 :: proc "c" (x, y: double4) -> double4 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z), max(x.w, y.w)} }
max_int2 :: proc "c" (x, y: int2) -> int2 { return {max(x.x, y.x), max(x.y, y.y)} }
max_int3 :: proc "c" (x, y: int3) -> int3 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z)} }
max_int4 :: proc "c" (x, y: int4) -> int4 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z), max(x.w, y.w)} }
max_uint2 :: proc "c" (x, y: uint2) -> uint2 { return {max(x.x, y.x), max(x.y, y.y)} }
max_uint3 :: proc "c" (x, y: uint3) -> uint3 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z)} }
max_uint4 :: proc "c" (x, y: uint4) -> uint4 { return {max(x.x, y.x), max(x.y, y.y), max(x.z, y.z), max(x.w, y.w)} }



clamp :: proc{
	clamp_int, 
	clamp_uint, 
	clamp_float,  
	clamp_double,
	clamp_float2, 
	clamp_float3, 
	clamp_float4, 
	clamp_double2, 
	clamp_double3, 
	clamp_double4, 
	clamp_int2,
	clamp_int3,
	clamp_int4,
	clamp_uint2,
	clamp_uint3,
	clamp_uint4,
}
clamp_int  :: proc "c" (x, y, z: int) -> int   { return builtin.clamp(x, y, z) }
clamp_uint  :: proc "c" (x, y, z: uint) -> uint   { return builtin.clamp(x, y, z) }
clamp_float  :: proc "c" (x, y, z: float) -> float   { return builtin.clamp(x, y, z) }
clamp_double  :: proc "c" (x, y, z: double) -> double   { return builtin.clamp(x, y, z) }
clamp_float2 :: proc "c" (x, y, z: float2) -> float2 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y)} }
clamp_float3 :: proc "c" (x, y, z: float3) -> float3 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z)} }
clamp_float4 :: proc "c" (x, y, z: float4) -> float4 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z), clamp(x.w, y.w, z.w)} }
clamp_double2 :: proc "c" (x, y, z: double2) -> double2 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y)} }
clamp_double3 :: proc "c" (x, y, z: double3) -> double3 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z)} }
clamp_double4 :: proc "c" (x, y, z: double4) -> double4 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z), clamp(x.w, y.w, z.w)} }
clamp_int2 :: proc "c" (x, y, z: int2) -> int2 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y)} }
clamp_int3 :: proc "c" (x, y, z: int3) -> int3 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z)} }
clamp_int4 :: proc "c" (x, y, z: int4) -> int4 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z), clamp(x.w, y.w, z.w)} }
clamp_uint2 :: proc "c" (x, y, z: uint2) -> uint2 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y)} }
clamp_uint3 :: proc "c" (x, y, z: uint3) -> uint3 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z)} }
clamp_uint4 :: proc "c" (x, y, z: uint4) -> uint4 { return {clamp(x.x, y.x, z.x), clamp(x.y, y.y, z.y), clamp(x.z, y.z, z.z), clamp(x.w, y.w, z.w)} }

saturate :: proc{
	saturate_int,
	saturate_uint,
	saturate_float,
	saturate_double,
	saturate_float2,
	saturate_float3,
	saturate_float4,
	saturate_double2,
	saturate_double3,
	saturate_double4,
	saturate_int2,
	saturate_int3,
	saturate_int4,
	saturate_uint2,
	saturate_uint3,
	saturate_uint4,
}
saturate_int  :: proc "c" (v: int) -> int   { return builtin.clamp(v, 0, 1) }
saturate_uint  :: proc "c" (v: uint) -> uint   { return builtin.clamp(v, 0, 1) }
saturate_float  :: proc "c" (v: float) -> float   { return builtin.clamp(v, 0, 1) }
saturate_double  :: proc "c" (v: double) -> double   { return builtin.clamp(v, 0, 1) }
saturate_float2 :: proc "c" (v: float2) -> float2 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1)} }
saturate_float3 :: proc "c" (v: float3) -> float3 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1)} }
saturate_float4 :: proc "c" (v: float4) -> float4 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1), builtin.clamp(v.w, 0, 1)} }
saturate_double2 :: proc "c" (v: double2) -> double2 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1)} }
saturate_double3 :: proc "c" (v: double3) -> double3 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1)} }
saturate_double4 :: proc "c" (v: double4) -> double4 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1), builtin.clamp(v.w, 0, 1)} }
saturate_int2 :: proc "c" (v: int2) -> int2 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1)} }
saturate_int3 :: proc "c" (v: int3) -> int3 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1)} }
saturate_int4 :: proc "c" (v: int4) -> int4 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1), builtin.clamp(v.w, 0, 1)} }
saturate_uint2 :: proc "c" (v: uint2) -> uint2 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1)} }
saturate_uint3 :: proc "c" (v: uint3) -> uint3 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1)} }
saturate_uint4 :: proc "c" (v: uint4) -> uint4 { return {builtin.clamp(v.x, 0, 1), builtin.clamp(v.y, 0, 1), builtin.clamp(v.z, 0, 1), builtin.clamp(v.w, 0, 1)} }


lerp :: proc{
	lerp_float,
	lerp_double,
	lerp_float2,
	lerp_float3,
	lerp_float4,
	lerp_double2,
	lerp_double3,
	lerp_double4,
}
lerp_float  :: proc "c" (x, y, t: float) -> float   { return x*(1-t) + y*t }
lerp_double  :: proc "c" (x, y, t: double) -> double   { return x*(1-t) + y*t }
lerp_float2 :: proc "c" (x, y, t: float2) -> float2 { return {lerp(x.x, y.x, t.x), lerp(x.y, y.y, t.y)} }
lerp_float3 :: proc "c" (x, y, t: float3) -> float3 { return {lerp(x.x, y.x, t.x), lerp(x.y, y.y, t.y), lerp(x.z, y.z, t.z)} }
lerp_float4 :: proc "c" (x, y, t: float4) -> float4 { return {lerp(x.x, y.x, t.x), lerp(x.y, y.y, y.y), lerp(x.z, y.z, t.z), lerp(x.w, y.w, t.w)} }
lerp_double2 :: proc "c" (x, y, t: double2) -> double2 { return {lerp(x.x, y.x, t.x), lerp(x.y, y.y, t.y)} }
lerp_double3 :: proc "c" (x, y, t: double3) -> double3 { return {lerp(x.x, y.x, t.x), lerp(x.y, y.y, t.y), lerp(x.z, y.z, t.z)} }
lerp_double4 :: proc "c" (x, y, t: double4) -> double4 { return {lerp(x.x, y.x, t.x), lerp(x.y, y.y, y.y), lerp(x.z, y.z, t.z), lerp(x.w, y.w, t.w)} }


step :: proc{
	step_float,
	step_double,
	step_float2,
	step_float3,
	step_float4,
	step_double2,
	step_double3,
	step_double4,
}
step_float  :: proc "c" (edge, x: float) -> float   { return 0 if x < edge else 1 }
step_double  :: proc "c" (edge, x: double) -> double   { return 0 if x < edge else 1 }
step_float2 :: proc "c" (edge, x: float2) -> float2 { return {step(edge.x, x.x), step(edge.y, x.y)} }
step_float3 :: proc "c" (edge, x: float3) -> float3 { return {step(edge.x, x.x), step(edge.y, x.y), step(edge.z, x.z)} }
step_float4 :: proc "c" (edge, x: float4) -> float4 { return {step(edge.x, x.x), step(edge.y, x.y), step(edge.z, x.z), step(edge.w, x.w)} }
step_double2 :: proc "c" (edge, x: double2) -> double2 { return {step(edge.x, x.x), step(edge.y, x.y)} }
step_double3 :: proc "c" (edge, x: double3) -> double3 { return {step(edge.x, x.x), step(edge.y, x.y), step(edge.z, x.z)} }
step_double4 :: proc "c" (edge, x: double4) -> double4 { return {step(edge.x, x.x), step(edge.y, x.y), step(edge.z, x.z), step(edge.w, x.w)} }

smoothstep :: proc{
	smoothstep_float,
	smoothstep_double,
	smoothstep_float2,
	smoothstep_float3,
	smoothstep_float4,
	smoothstep_double2,
	smoothstep_double3,
	smoothstep_double4,
}
smoothstep_float :: proc "c" (edge0, edge1, x: float) -> float { 
	y := clamp(((x-edge0) / (edge1 - edge0)), 0, 1)
	return y * y * (3 - 2*y)
}
smoothstep_double :: proc "c" (edge0, edge1, x: double) -> double { 
	y := clamp(((x-edge0) / (edge1 - edge0)), 0, 1)
	return y * y * (3 - 2*y)
}
smoothstep_float2  :: proc "c" (edge0, edge1, x: float2) -> float2   { return {smoothstep(edge0.x, edge1.x, x.x), smoothstep(edge0.y, edge1.y, x.y)} }
smoothstep_float3  :: proc "c" (edge0, edge1, x: float3) -> float3   { return {smoothstep(edge0.x, edge1.x, x.x), smoothstep(edge0.y, edge1.y, x.y), smoothstep(edge0.z, edge1.z, x.z)} }
smoothstep_float4  :: proc "c" (edge0, edge1, x: float4) -> float4   { return {smoothstep(edge0.x, edge1.x, x.x), smoothstep(edge0.y, edge1.y, x.y), smoothstep(edge0.z, edge1.z, x.z), smoothstep(edge0.w, edge1.w, x.w)} }
smoothstep_double2 :: proc "c" (edge0, edge1, x: double2) -> double2 { return {smoothstep(edge0.x, edge1.x, x.x), smoothstep(edge0.y, edge1.y, x.y)} }
smoothstep_double3 :: proc "c" (edge0, edge1, x: double3) -> double3 { return {smoothstep(edge0.x, edge1.x, x.x), smoothstep(edge0.y, edge1.y, x.y), smoothstep(edge0.z, edge1.z, x.z)} }
smoothstep_double4 :: proc "c" (edge0, edge1, x: double4) -> double4 { return {smoothstep(edge0.x, edge1.x, x.x), smoothstep(edge0.y, edge1.y, x.y), smoothstep(edge0.z, edge1.z, x.z), smoothstep(edge0.w, edge1.w, x.w)} }


abs :: proc{
	abs_int,
	abs_uint,
	abs_float,
	abs_double,
	abs_float2,
	abs_float3,
	abs_float4,
	abs_double2,
	abs_double3,
	abs_double4,
	abs_int2,
	abs_int3,
	abs_int4,
	abs_uint2,
	abs_uint3,
	abs_uint4,
}
abs_int  :: proc "c" (x: int)  -> int  { return builtin.abs(x) }
abs_uint  :: proc "c" (x: uint)  -> uint  { return x }
abs_float  :: proc "c" (x: float)  -> float  { return builtin.abs(x) }
abs_double  :: proc "c" (x: double)  -> double  { return builtin.abs(x) }
abs_float2 :: proc "c" (x: float2) -> float2 { return {abs(x.x), abs(x.y)} }
abs_float3 :: proc "c" (x: float3) -> float3 { return {abs(x.x), abs(x.y), abs(x.z)} }
abs_float4 :: proc "c" (x: float4) -> float4 { return {abs(x.x), abs(x.y), abs(x.z), abs(x.w)} }
abs_double2 :: proc "c" (x: double2) -> double2 { return {abs(x.x), abs(x.y)} }
abs_double3 :: proc "c" (x: double3) -> double3 { return {abs(x.x), abs(x.y), abs(x.z)} }
abs_double4 :: proc "c" (x: double4) -> double4 { return {abs(x.x), abs(x.y), abs(x.z), abs(x.w)} }
abs_int2 :: proc "c" (x: int2) -> int2 { return {abs(x.x), abs(x.y)} }
abs_int3 :: proc "c" (x: int3) -> int3 { return {abs(x.x), abs(x.y), abs(x.z)} }
abs_int4 :: proc "c" (x: int4) -> int4 { return {abs(x.x), abs(x.y), abs(x.z), abs(x.w)} }
abs_uint2 :: proc "c" (x: uint2) -> uint2 { return x }
abs_uint3 :: proc "c" (x: uint3) -> uint3 { return x }
abs_uint4 :: proc "c" (x: uint4) -> uint4 { return x }

dot :: proc{
	dot_int,
	dot_uint,
	dot_float,
	dot_double,
	dot_float2,
	dot_float3,
	dot_float4,
	dot_double2,
	dot_double3,
	dot_double4,
	dot_int2,
	dot_int3,
	dot_int4,
	dot_uint2,
	dot_uint3,
	dot_uint4,
}
dot_int  :: proc "c" (a, b: int)  -> int { return a*b }
dot_uint  :: proc "c" (a, b: uint)  -> uint { return a*b }
dot_float  :: proc "c" (a, b: float)  -> float { return a*b }
dot_double  :: proc "c" (a, b: double)  -> double { return a*b }
dot_float2 :: proc "c" (a, b: float2) -> float { return a.x*b.x + a.y*b.y }
dot_float3 :: proc "c" (a, b: float3) -> float { return a.x*b.x + a.y*b.y + a.z*b.z }
dot_float4 :: proc "c" (a, b: float4) -> float { return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w }
dot_double2 :: proc "c" (a, b: double2) -> double { return a.x*b.x + a.y*b.y }
dot_double3 :: proc "c" (a, b: double3) -> double { return a.x*b.x + a.y*b.y + a.z*b.z }
dot_double4 :: proc "c" (a, b: double4) -> double { return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w }
dot_int2 :: proc "c" (a, b: int2) -> int { return a.x*b.x + a.y*b.y }
dot_int3 :: proc "c" (a, b: int3) -> int { return a.x*b.x + a.y*b.y + a.z*b.z }
dot_int4 :: proc "c" (a, b: int4) -> int { return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w }
dot_uint2 :: proc "c" (a, b: uint2) -> uint { return a.x*b.x + a.y*b.y }
dot_uint3 :: proc "c" (a, b: uint3) -> uint { return a.x*b.x + a.y*b.y + a.z*b.z }
dot_uint4 :: proc "c" (a, b: uint4) -> uint { return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w }

length :: proc{
	length_float,
	length_double,
	length_float2,
	length_float3,
	length_float4,
	length_double2,
	length_double3,
	length_double4,
}
length_float  :: proc "c" (x: float)  -> float { return builtin.abs(x) }
length_double  :: proc "c" (x: double)  -> double { return builtin.abs(x) }
length_float2 :: proc "c" (x: float2) -> float { return sqrt(x.x*x.x + x.y*x.y) }
length_float3 :: proc "c" (x: float3) -> float { return sqrt(x.x*x.x + x.y*x.y + x.z*x.z) }
length_float4 :: proc "c" (x: float4) -> float { return sqrt(x.x*x.x + x.y*x.y + x.z*x.z + x.w*x.w) }
length_double2 :: proc "c" (x: double2) -> double { return sqrt(x.x*x.x + x.y*x.y) }
length_double3 :: proc "c" (x: double3) -> double { return sqrt(x.x*x.x + x.y*x.y + x.z*x.z) }
length_double4 :: proc "c" (x: double4) -> double { return sqrt(x.x*x.x + x.y*x.y + x.z*x.z + x.w*x.w) }


distance :: proc{
	distance_float,
	distance_double,
	distance_float2,
	distance_float3,
	distance_float4,
	distance_double2,
	distance_double3,
	distance_double4,
}
distance_float  :: proc "c" (x, y: float)  -> float { return length(y-x) }
distance_double  :: proc "c" (x, y: double)  -> double { return length(y-x) }
distance_float2 :: proc "c" (x, y: float2) -> float { return length(y-x) }
distance_float3 :: proc "c" (x, y: float3) -> float { return length(y-x) }
distance_float4 :: proc "c" (x, y: float4) -> float { return length(y-x) }
distance_double2 :: proc "c" (x, y: double2) -> double { return length(y-x) }
distance_double3 :: proc "c" (x, y: double3) -> double { return length(y-x) }
distance_double4 :: proc "c" (x, y: double4) -> double { return length(y-x) }


cross :: proc{
	cross_float3,
	cross_double3,
	cross_int3,
}

cross_float3 :: proc "c" (a, b: float3) -> (c: float3) {
	c.x = a.y*b.z - b.y*a.z
	c.y = a.z*b.x - b.z*a.x
	c.z = a.x*b.y - b.x*a.y
	return
}
cross_double3 :: proc "c" (a, b: double3) -> (c: double3) {
	c.x = a.y*b.z - b.y*a.z
	c.y = a.z*b.x - b.z*a.x
	c.z = a.x*b.y - b.x*a.y
	return
}
cross_int3 :: proc "c" (a, b: int3) -> (c: int3) {
	c.x = a.y*b.z - b.y*a.z
	c.y = a.z*b.x - b.z*a.x
	c.z = a.x*b.y - b.x*a.y
	return
}

normalize :: proc{
	normalize_float,
	normalize_double,
	normalize_float2,
	normalize_float3,
	normalize_float4,
	normalize_double2,
	normalize_double3,
	normalize_double4,
}
normalize_float  :: proc "c" (x: float)  -> float  { return 1.0 }
normalize_double  :: proc "c" (x: double)  -> double  { return 1.0 }
normalize_float2 :: proc "c" (x: float2) -> float2 { return x / length(x) }
normalize_float3 :: proc "c" (x: float3) -> float3 { return x / length(x) }
normalize_float4 :: proc "c" (x: float4) -> float4 { return x / length(x) }
normalize_double2 :: proc "c" (x: double2) -> double2 { return x / length(x) }
normalize_double3 :: proc "c" (x: double3) -> double3 { return x / length(x) }
normalize_double4 :: proc "c" (x: double4) -> double4 { return x / length(x) }


faceforward :: proc{
	faceforward_float,
	faceforward_double,
	faceforward_float2,
	faceforward_float3,
	faceforward_float4,
	faceforward_double2,
	faceforward_double3,
	faceforward_double4,
}
faceforward_float  :: proc "c" (N, I, Nref: float)  -> float  { return N if dot(I, Nref) < 0 else -N }
faceforward_double  :: proc "c" (N, I, Nref: double)  -> double  { return N if dot(I, Nref) < 0 else -N }
faceforward_float2 :: proc "c" (N, I, Nref: float2) -> float2 { return N if dot(I, Nref) < 0 else -N }
faceforward_float3 :: proc "c" (N, I, Nref: float3) -> float3 { return N if dot(I, Nref) < 0 else -N }
faceforward_float4 :: proc "c" (N, I, Nref: float4) -> float4 { return N if dot(I, Nref) < 0 else -N }
faceforward_double2 :: proc "c" (N, I, Nref: double2) -> double2 { return N if dot(I, Nref) < 0 else -N }
faceforward_double3 :: proc "c" (N, I, Nref: double3) -> double3 { return N if dot(I, Nref) < 0 else -N }
faceforward_double4 :: proc "c" (N, I, Nref: double4) -> double4 { return N if dot(I, Nref) < 0 else -N }


reflect :: proc{
	reflect_float,
	reflect_double,
	reflect_float2,
	reflect_float3,
	reflect_float4,
	reflect_double2,
	reflect_double3,
	reflect_double4,
}
reflect_float  :: proc "c" (I, N: float)  -> float  { return I - 2*N*dot(N, I) }
reflect_double  :: proc "c" (I, N: double)  -> double  { return I - 2*N*dot(N, I) }
reflect_float2 :: proc "c" (I, N: float2) -> float2 { return I - 2*N*dot(N, I) }
reflect_float3 :: proc "c" (I, N: float3) -> float3 { return I - 2*N*dot(N, I) }
reflect_float4 :: proc "c" (I, N: float4) -> float4 { return I - 2*N*dot(N, I) }
reflect_double2 :: proc "c" (I, N: double2) -> double2 { return I - 2*N*dot(N, I) }
reflect_double3 :: proc "c" (I, N: double3) -> double3 { return I - 2*N*dot(N, I) }
reflect_double4 :: proc "c" (I, N: double4) -> double4 { return I - 2*N*dot(N, I) }




refract :: proc{
	refract_float,
	refract_double,
	refract_float2,
	refract_float3,
	refract_float4,
	refract_double2,
	refract_double3,
	refract_double4,
}
refract_float  :: proc "c" (i, n, eta: float) -> float { 
	cosi := dot(-i, n)
	cost2 := 1 - eta*eta*(1 - cosi*cosi)
	t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
	return t * float(int(cost2 > 0))
}
refract_double  :: proc "c" (i, n, eta: double) -> double { 
	cosi := dot(-i, n)
	cost2 := 1 - eta*eta*(1 - cosi*cosi)
	t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
	return t * double(int(cost2 > 0))
}
refract_float2  :: proc "c" (i, n, eta: float2) -> float2 { 
	cosi := dot(-i, n)
	cost2 := 1 - eta*eta*(1 - cosi*cosi)
	t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
	return t * float2{float(int(cost2.x > 0)), float(int(cost2.y > 0))}
}
refract_float3  :: proc "c" (i, n, eta: float3) -> float3 { 
	cosi := dot(-i, n)
	cost2 := 1 - eta*eta*(1 - cosi*cosi)
	t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
	return t * float3{float(int(cost2.x > 0)), float(int(cost2.y > 0)), float(int(cost2.z > 0))}
}
refract_float4  :: proc "c" (i, n, eta: float4) -> float4 { 
	cosi := dot(-i, n)
	cost2 := 1 - eta*eta*(1 - cosi*cosi)
	t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
	return t * float4{float(int(cost2.x > 0)), float(int(cost2.y > 0)), float(int(cost2.z > 0)), float(int(cost2.w > 0))}
}
refract_double2  :: proc "c" (i, n, eta: double2) -> double2 { 
	cosi := dot(-i, n)
	cost2 := 1 - eta*eta*(1 - cosi*cosi)
	t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
	return t * double2{double(int(cost2.x > 0)), double(int(cost2.y > 0))}
}
refract_double3  :: proc "c" (i, n, eta: double3) -> double3 { 
	cosi := dot(-i, n)
	cost2 := 1 - eta*eta*(1 - cosi*cosi)
	t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
	return t * double3{double(int(cost2.x > 0)), double(int(cost2.y > 0)), double(int(cost2.z > 0))}
}
refract_double4  :: proc "c" (i, n, eta: double4) -> double4 { 
	cosi := dot(-i, n)
	cost2 := 1 - eta*eta*(1 - cosi*cosi)
	t := eta*i + ((eta*cosi - sqrt(abs(cost2))) * n)
	return t * double4{double(int(cost2.x > 0)), double(int(cost2.y > 0)), double(int(cost2.z > 0)), double(int(cost2.w > 0))}
}

scalarTripleProduct :: proc{
	scalarTripleProduct_float3,
	scalarTripleProduct_double3,
	scalarTripleProduct_int3,
}
scalarTripleProduct_float3 :: proc "c" (a, b, c: float3) -> float  { return dot(a, cross(b, c)) }
scalarTripleProduct_double3 :: proc "c" (a, b, c: double3) -> double  { return dot(a, cross(b, c)) }
scalarTripleProduct_int3 :: proc "c" (a, b, c: int3) -> int  { return dot(a, cross(b, c)) }

vectorTripleProduct :: proc {
	vectorTripleProduct_float3,
	vectorTripleProduct_double3,
	vectorTripleProduct_int3,	
}
vectorTripleProduct_float3 :: proc "c" (a, b, c: float3) -> float3 { return cross(a, cross(b, c)) }
vectorTripleProduct_double3 :: proc "c" (a, b, c: double3) -> double3 { return cross(a, cross(b, c)) }
vectorTripleProduct_int3 :: proc "c" (a, b, c: int3) -> int3 { return cross(a, cross(b, c)) }


// Vector Relational Procedures

lessThan :: proc{
	lessThan_float,
	lessThan_double,
	lessThan_int,
	lessThan_uint,
	lessThan_float2,
	lessThan_double2,
	lessThan_int2,
	lessThan_uint2,
	lessThan_float3,
	lessThan_double3,
	lessThan_int3,
	lessThan_uint3,
	lessThan_float4,
	lessThan_double4,
	lessThan_int4,
	lessThan_uint4,
}
lessThan_float   :: proc "c" (a, b: float) -> bool { return a < b }
lessThan_double   :: proc "c" (a, b: double) -> bool { return a < b }
lessThan_int   :: proc "c" (a, b: int) -> bool { return a < b }
lessThan_uint   :: proc "c" (a, b: uint) -> bool { return a < b }
lessThan_float2  :: proc "c" (a, b: float2) -> bool2 { return {a.x < b.x, a.y < b.y} }
lessThan_double2 :: proc "c" (a, b: double2) -> bool2 { return {a.x < b.x, a.y < b.y} }
lessThan_int2 :: proc "c" (a, b: int2) -> bool2 { return {a.x < b.x, a.y < b.y} }
lessThan_uint2 :: proc "c" (a, b: uint2) -> bool2 { return {a.x < b.x, a.y < b.y} }
lessThan_float3  :: proc "c" (a, b: float3) -> bool3 { return {a.x < b.x, a.y < b.y, a.z < b.z} }
lessThan_double3  :: proc "c" (a, b: double3) -> bool3 { return {a.x < b.x, a.y < b.y, a.z < b.z} }
lessThan_int3 :: proc "c" (a, b: int3) -> bool3 { return {a.x < b.x, a.y < b.y, a.z < b.z} }
lessThan_uint3 :: proc "c" (a, b: uint3) -> bool3 { return {a.x < b.x, a.y < b.y, a.z < b.z} }
lessThan_float4  :: proc "c" (a, b: float4) -> bool4 { return {a.x < b.x, a.y < b.y, a.z < b.z, a.w < b.w} }
lessThan_double4  :: proc "c" (a, b: double4) -> bool4 { return {a.x < b.x, a.y < b.y, a.z < b.z, a.w < b.w} }
lessThan_int4 :: proc "c" (a, b: int4) -> bool4 { return {a.x < b.x, a.y < b.y, a.z < b.z, a.w < b.w} }
lessThan_uint4 :: proc "c" (a, b: uint4) -> bool4 { return {a.x < b.x, a.y < b.y, a.z < b.z, a.w < b.w} }


lessThanEqual :: proc{
	lessThanEqual_float,
	lessThanEqual_double,
	lessThanEqual_int,
	lessThanEqual_uint,
	lessThanEqual_float2,
	lessThanEqual_double2,
	lessThanEqual_int2,
	lessThanEqual_uint2,
	lessThanEqual_float3,
	lessThanEqual_double3,
	lessThanEqual_int3,
	lessThanEqual_uint3,
	lessThanEqual_float4,
	lessThanEqual_double4,
	lessThanEqual_int4,
	lessThanEqual_uint4,
}
lessThanEqual_float   :: proc "c" (a, b: float) -> bool { return a <= b }
lessThanEqual_double   :: proc "c" (a, b: double) -> bool { return a <= b }
lessThanEqual_int   :: proc "c" (a, b: int) -> bool { return a <= b }
lessThanEqual_uint   :: proc "c" (a, b: uint) -> bool { return a <= b }
lessThanEqual_float2  :: proc "c" (a, b: float2) -> bool2 { return {a.x <= b.x, a.y <= b.y} }
lessThanEqual_double2  :: proc "c" (a, b: double2) -> bool2 { return {a.x <= b.x, a.y <= b.y} }
lessThanEqual_int2 :: proc "c" (a, b: int2) -> bool2 { return {a.x <= b.x, a.y <= b.y} }
lessThanEqual_uint2 :: proc "c" (a, b: uint2) -> bool2 { return {a.x <= b.x, a.y <= b.y} }
lessThanEqual_float3  :: proc "c" (a, b: float3) -> bool3 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z} }
lessThanEqual_double3  :: proc "c" (a, b: double3) -> bool3 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z} }
lessThanEqual_int3 :: proc "c" (a, b: int3) -> bool3 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z} }
lessThanEqual_uint3 :: proc "c" (a, b: uint3) -> bool3 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z} }
lessThanEqual_float4  :: proc "c" (a, b: float4) -> bool4 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z, a.w <= b.w} }
lessThanEqual_double4  :: proc "c" (a, b: double4) -> bool4 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z, a.w <= b.w} }
lessThanEqual_int4 :: proc "c" (a, b: int4) -> bool4 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z, a.w <= b.w} }
lessThanEqual_uint4 :: proc "c" (a, b: uint4) -> bool4 { return {a.x <= b.x, a.y <= b.y, a.z <= b.z, a.w <= b.w} }


greaterThan :: proc{
	greaterThan_float,
	greaterThan_double,
	greaterThan_int,
	greaterThan_uint,
	greaterThan_float2,
	greaterThan_double2,
	greaterThan_int2,
	greaterThan_uint2,
	greaterThan_float3,
	greaterThan_double3,
	greaterThan_int3,
	greaterThan_uint3,
	greaterThan_float4,
	greaterThan_double4,
	greaterThan_int4,
	greaterThan_uint4,
}
greaterThan_float   :: proc "c" (a, b: float) -> bool { return a > b }
greaterThan_double   :: proc "c" (a, b: double) -> bool { return a > b }
greaterThan_int   :: proc "c" (a, b: int) -> bool { return a > b }
greaterThan_uint   :: proc "c" (a, b: uint) -> bool { return a > b }
greaterThan_float2  :: proc "c" (a, b: float2) -> bool2 { return {a.x > b.x, a.y > b.y} }
greaterThan_double2  :: proc "c" (a, b: double2) -> bool2 { return {a.x > b.x, a.y > b.y} }
greaterThan_int2 :: proc "c" (a, b: int2) -> bool2 { return {a.x > b.x, a.y > b.y} }
greaterThan_uint2 :: proc "c" (a, b: uint2) -> bool2 { return {a.x > b.x, a.y > b.y} }
greaterThan_float3  :: proc "c" (a, b: float3) -> bool3 { return {a.x > b.x, a.y > b.y, a.z > b.z} }
greaterThan_double3  :: proc "c" (a, b: double3) -> bool3 { return {a.x > b.x, a.y > b.y, a.z > b.z} }
greaterThan_int3 :: proc "c" (a, b: int3) -> bool3 { return {a.x > b.x, a.y > b.y, a.z > b.z} }
greaterThan_uint3 :: proc "c" (a, b: uint3) -> bool3 { return {a.x > b.x, a.y > b.y, a.z > b.z} }
greaterThan_float4  :: proc "c" (a, b: float4) -> bool4 { return {a.x > b.x, a.y > b.y, a.z > b.z, a.w > b.w} }
greaterThan_double4  :: proc "c" (a, b: double4) -> bool4 { return {a.x > b.x, a.y > b.y, a.z > b.z, a.w > b.w} }
greaterThan_int4 :: proc "c" (a, b: int4) -> bool4 { return {a.x > b.x, a.y > b.y, a.z > b.z, a.w > b.w} }
greaterThan_uint4 :: proc "c" (a, b: uint4) -> bool4 { return {a.x > b.x, a.y > b.y, a.z > b.z, a.w > b.w} }


greaterThanEqual :: proc{
	greaterThanEqual_float,
	greaterThanEqual_double,
	greaterThanEqual_int,
	greaterThanEqual_uint,
	greaterThanEqual_float2,
	greaterThanEqual_double2,
	greaterThanEqual_int2,
	greaterThanEqual_uint2,
	greaterThanEqual_float3,
	greaterThanEqual_double3,
	greaterThanEqual_int3,
	greaterThanEqual_uint3,
	greaterThanEqual_float4,
	greaterThanEqual_double4,
	greaterThanEqual_int4,
	greaterThanEqual_uint4,
}
greaterThanEqual_float   :: proc "c" (a, b: float) -> bool { return a >= b }
greaterThanEqual_double   :: proc "c" (a, b: double) -> bool { return a >= b }
greaterThanEqual_int   :: proc "c" (a, b: int) -> bool { return a >= b }
greaterThanEqual_uint   :: proc "c" (a, b: uint) -> bool { return a >= b }
greaterThanEqual_float2  :: proc "c" (a, b: float2) -> bool2 { return {a.x >= b.x, a.y >= b.y} }
greaterThanEqual_double2  :: proc "c" (a, b: double2) -> bool2 { return {a.x >= b.x, a.y >= b.y} }
greaterThanEqual_int2 :: proc "c" (a, b: int2) -> bool2 { return {a.x >= b.x, a.y >= b.y} }
greaterThanEqual_uint2 :: proc "c" (a, b: uint2) -> bool2 { return {a.x >= b.x, a.y >= b.y} }
greaterThanEqual_float3  :: proc "c" (a, b: float3) -> bool3 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z} }
greaterThanEqual_double3  :: proc "c" (a, b: double3) -> bool3 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z} }
greaterThanEqual_int3 :: proc "c" (a, b: int3) -> bool3 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z} }
greaterThanEqual_uint3 :: proc "c" (a, b: uint3) -> bool3 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z} }
greaterThanEqual_float4  :: proc "c" (a, b: float4) -> bool4 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z, a.w >= b.w} }
greaterThanEqual_double4  :: proc "c" (a, b: double4) -> bool4 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z, a.w >= b.w} }
greaterThanEqual_int4 :: proc "c" (a, b: int4) -> bool4 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z, a.w >= b.w} }
greaterThanEqual_uint4 :: proc "c" (a, b: uint4) -> bool4 { return {a.x >= b.x, a.y >= b.y, a.z >= b.z, a.w >= b.w} }


equal :: proc{
	equal_float,
	equal_double,
	equal_int,
	equal_uint,
	equal_float2,
	equal_double2,
	equal_int2,
	equal_uint2,
	equal_float3,
	equal_double3,
	equal_int3,
	equal_uint3,
	equal_float4,
	equal_double4,
	equal_int4,
	equal_uint4,
}
equal_float   :: proc "c" (a, b: float) -> bool { return a == b }
equal_double   :: proc "c" (a, b: double) -> bool { return a == b }
equal_int   :: proc "c" (a, b: int) -> bool { return a == b }
equal_uint   :: proc "c" (a, b: uint) -> bool { return a == b }
equal_float2  :: proc "c" (a, b: float2) -> bool2 { return {a.x == b.x, a.y == b.y} }
equal_double2  :: proc "c" (a, b: double2) -> bool2 { return {a.x == b.x, a.y == b.y} }
equal_int2 :: proc "c" (a, b: int2) -> bool2 { return {a.x == b.x, a.y == b.y} }
equal_uint2 :: proc "c" (a, b: uint2) -> bool2 { return {a.x == b.x, a.y == b.y} }
equal_float3  :: proc "c" (a, b: float3) -> bool3 { return {a.x == b.x, a.y == b.y, a.z == b.z} }
equal_double3  :: proc "c" (a, b: double3) -> bool3 { return {a.x == b.x, a.y == b.y, a.z == b.z} }
equal_int3 :: proc "c" (a, b: int3) -> bool3 { return {a.x == b.x, a.y == b.y, a.z == b.z} }
equal_uint3 :: proc "c" (a, b: uint3) -> bool3 { return {a.x == b.x, a.y == b.y, a.z == b.z} }
equal_float4  :: proc "c" (a, b: float4) -> bool4 { return {a.x == b.x, a.y == b.y, a.z == b.z, a.w == b.w} }
equal_double4  :: proc "c" (a, b: double4) -> bool4 { return {a.x == b.x, a.y == b.y, a.z == b.z, a.w == b.w} }
equal_int4 :: proc "c" (a, b: int4) -> bool4 { return {a.x == b.x, a.y == b.y, a.z == b.z, a.w == b.w} }
equal_uint4 :: proc "c" (a, b: uint4) -> bool4 { return {a.x == b.x, a.y == b.y, a.z == b.z, a.w == b.w} }

notEqual :: proc{
	notEqual_float,
	notEqual_double,
	notEqual_int,
	notEqual_uint,
	notEqual_float2,
	notEqual_double2,
	notEqual_int2,
	notEqual_uint2,
	notEqual_float3,
	notEqual_double3,
	notEqual_int3,
	notEqual_uint3,
	notEqual_float4,
	notEqual_double4,
	notEqual_int4,
	notEqual_uint4,
}
notEqual_float   :: proc "c" (a, b: float) -> bool { return a != b }
notEqual_double   :: proc "c" (a, b: double) -> bool { return a != b }
notEqual_int   :: proc "c" (a, b: int) -> bool { return a != b }
notEqual_uint   :: proc "c" (a, b: uint) -> bool { return a != b }
notEqual_float2  :: proc "c" (a, b: float2) -> bool2 { return {a.x != b.x, a.y != b.y} }
notEqual_double2  :: proc "c" (a, b: double2) -> bool2 { return {a.x != b.x, a.y != b.y} }
notEqual_int2 :: proc "c" (a, b: int2) -> bool2 { return {a.x != b.x, a.y != b.y} }
notEqual_uint2 :: proc "c" (a, b: uint2) -> bool2 { return {a.x != b.x, a.y != b.y} }
notEqual_float3  :: proc "c" (a, b: float3) -> bool3 { return {a.x != b.x, a.y != b.y, a.z != b.z} }
notEqual_double3  :: proc "c" (a, b: double3) -> bool3 { return {a.x != b.x, a.y != b.y, a.z != b.z} }
notEqual_int3 :: proc "c" (a, b: int3) -> bool3 { return {a.x != b.x, a.y != b.y, a.z != b.z} }
notEqual_uint3 :: proc "c" (a, b: uint3) -> bool3 { return {a.x != b.x, a.y != b.y, a.z != b.z} }
notEqual_float4  :: proc "c" (a, b: float4) -> bool4 { return {a.x != b.x, a.y != b.y, a.z != b.z, a.w != b.w} }
notEqual_double4  :: proc "c" (a, b: double4) -> bool4 { return {a.x != b.x, a.y != b.y, a.z != b.z, a.w != b.w} }
notEqual_int4 :: proc "c" (a, b: int4) -> bool4 { return {a.x != b.x, a.y != b.y, a.z != b.z, a.w != b.w} }
notEqual_uint4 :: proc "c" (a, b: uint4) -> bool4 { return {a.x != b.x, a.y != b.y, a.z != b.z, a.w != b.w} }


any :: proc{
	any_bool,
	any_bool2,
	any_bool3,
	any_bool4,
}
any_bool  :: proc "c" (v: bool) -> bool  { return v }
any_bool2 :: proc "c" (v: bool2) -> bool { return v.x || v.y }
any_bool3 :: proc "c" (v: bool3) -> bool { return v.x || v.y || v.z }
any_bool4 :: proc "c" (v: bool4) -> bool { return v.x || v.y || v.z || v.w }

all :: proc{
	all_bool,
	all_bool2,
	all_bool3,
	all_bool4,
}
all_bool  :: proc "c" (v: bool) -> bool  { return v }
all_bool2 :: proc "c" (v: bool2) -> bool { return v.x && v.y }
all_bool3 :: proc "c" (v: bool3) -> bool { return v.x && v.y && v.z }
all_bool4 :: proc "c" (v: bool4) -> bool { return v.x && v.y && v.z && v.w }

not :: proc{
	not_bool,
	not_bool2,
	not_bool3,
	not_bool4,
}
not_bool  :: proc "c" (v: bool) -> bool { return !v }
not_bool2 :: proc "c" (v: bool2) -> bool2 { return {!v.x, !v.y} }
not_bool3 :: proc "c" (v: bool3) -> bool3 { return {!v.x, !v.y, !v.z} }
not_bool4 :: proc "c" (v: bool4) -> bool4 { return {!v.x, !v.y, !v.z, !v.w} }




inverse_float1x1  :: proc "c" (m: float1x1)  -> float1x1  { return builtin.inverse(m) }
inverse_float2x2  :: proc "c" (m: float2x2)  -> float2x2  { return builtin.inverse(m) }
inverse_float3x3  :: proc "c" (m: float3x3)  -> float3x3  { return builtin.inverse(m) }
inverse_float4x4  :: proc "c" (m: float4x4)  -> float4x4  { return builtin.inverse(m) }
inverse_double1x1 :: proc "c" (m: double1x1) -> double1x1 { return builtin.inverse(m) }
inverse_double2x2 :: proc "c" (m: double2x2) -> double2x2 { return builtin.inverse(m) }
inverse_double3x3 :: proc "c" (m: double3x3) -> double3x3 { return builtin.inverse(m) }
inverse_double4x4 :: proc "c" (m: double4x4) -> double4x4 { return builtin.inverse(m) }

inverse :: proc{
	inverse_float1x1,
	inverse_float2x2,
	inverse_float3x3,
	inverse_float4x4,
	inverse_double1x1,
	inverse_double2x2,
	inverse_double3x3,
	inverse_double4x4,
}

transpose         :: builtin.transpose
inverse_transpose :: builtin.inverse_transpose
adjugate          :: builtin.adjugate
hermitian_adjoint :: builtin.hermitian_adjoint
minor             :: builtin.matrix_minor
determinant       :: builtin.determinant
trace             :: builtin.matrix_trace

asfloat :: proc{
	asfloat_float,
	asfloat_double,
	asfloat_int,
	asfloat_uint,
	asfloat_float1x1,
	asfloat_float2x2,
	asfloat_float3x3,
	asfloat_float4x4,
	asfloat_float1x2,
	asfloat_float1x3,
	asfloat_float1x4,
	asfloat_float2x1,
	asfloat_float2x3,
	asfloat_float2x4,
	asfloat_float3x1,
	asfloat_float3x2,
	asfloat_float3x4,
	asfloat_float4x1,
	asfloat_float4x2,
	asfloat_float4x3,
	asfloat_float2,
	asfloat_float3,
	asfloat_float4,
	asfloat_int2,
	asfloat_int3,
	asfloat_int4,
	asfloat_uint2,
	asfloat_uint3,
	asfloat_uint4,
	asfloat_bool2,
	asfloat_bool3,
	asfloat_bool4,
	asfloat_double1x1,
	asfloat_double2x2,
	asfloat_double3x3,
	asfloat_double4x4,
	asfloat_double1x2,
	asfloat_double1x3,
	asfloat_double1x4,
	asfloat_double2x1,
	asfloat_double2x3,
	asfloat_double2x4,
	asfloat_double3x1,
	asfloat_double3x2,
	asfloat_double3x4,
	asfloat_double4x1,
	asfloat_double4x2,
	asfloat_double4x3,
	asfloat_double2,
	asfloat_double3,
	asfloat_double4,
}
asfloat_float     :: proc "c" (v: float)     -> float    { return float(v) }
asfloat_double    :: proc "c" (v: double)    -> float    { return float(v) }
asfloat_int       :: proc "c" (v: int)       -> float    { return float(v) }
asfloat_uint      :: proc "c" (v: uint)      -> float    { return float(v) }
asfloat_float1x1  :: proc "c" (v: float1x1)  -> float1x1 { return float1x1(v) }
asfloat_float2x2  :: proc "c" (v: float2x2)  -> float2x2 { return float2x2(v) }
asfloat_float3x3  :: proc "c" (v: float3x3)  -> float3x3 { return float3x3(v) }
asfloat_float4x4  :: proc "c" (v: float4x4)  -> float4x4 { return float4x4(v) }
asfloat_float1x2  :: proc "c" (v: float1x2)  -> float1x2 { return float1x2(v) }
asfloat_float1x3  :: proc "c" (v: float1x3)  -> float1x3 { return float1x3(v) }
asfloat_float1x4  :: proc "c" (v: float1x4)  -> float1x4 { return float1x4(v) }
asfloat_float2x1  :: proc "c" (v: float2x1)  -> float2x1 { return float2x1(v) }
asfloat_float2x3  :: proc "c" (v: float2x3)  -> float2x3 { return float2x3(v) }
asfloat_float2x4  :: proc "c" (v: float2x4)  -> float2x4 { return float2x4(v) }
asfloat_float3x1  :: proc "c" (v: float3x1)  -> float3x1 { return float3x1(v) }
asfloat_float3x2  :: proc "c" (v: float3x2)  -> float3x2 { return float3x2(v) }
asfloat_float3x4  :: proc "c" (v: float3x4)  -> float3x4 { return float3x4(v) }
asfloat_float4x1  :: proc "c" (v: float4x1)  -> float4x1 { return float4x1(v) }
asfloat_float4x2  :: proc "c" (v: float4x2)  -> float4x2 { return float4x2(v) }
asfloat_float4x3  :: proc "c" (v: float4x3)  -> float4x3 { return float4x3(v) }
asfloat_float2    :: proc "c" (v: float2)    -> float2   { return float2(v) }
asfloat_float3    :: proc "c" (v: float3)    -> float3   { return float3(v) }
asfloat_float4    :: proc "c" (v: float4)    -> float4   { return float4(v) }
asfloat_int2      :: proc "c" (v: int2)      -> float2   { return float2{float(v.x), float(v.y)} }
asfloat_int3      :: proc "c" (v: int3)      -> float3   { return float3{float(v.x), float(v.y), float(v.z)} }
asfloat_int4      :: proc "c" (v: int4)      -> float4   { return float4{float(v.x), float(v.y), float(v.z), float(v.w)} }
asfloat_uint2     :: proc "c" (v: uint2)     -> float2   { return float2{float(v.x), float(v.y)} }
asfloat_uint3     :: proc "c" (v: uint3)     -> float3   { return float3{float(v.x), float(v.y), float(v.z)} }
asfloat_uint4     :: proc "c" (v: uint4)     -> float4   { return float4{float(v.x), float(v.y), float(v.z), float(v.w)} }
asfloat_bool2     :: proc "c" (v: bool2)     -> float2   { return float2{float(int(v.x)), float(int(v.y))} }
asfloat_bool3     :: proc "c" (v: bool3)     -> float3   { return float3{float(int(v.x)), float(int(v.y)), float(int(v.z))} }
asfloat_bool4     :: proc "c" (v: bool4)     -> float4   { return float4{float(int(v.x)), float(int(v.y)), float(int(v.z)), float(int(v.w))} }
asfloat_double1x1 :: proc "c" (v: double1x1) -> float1x1 { return float1x1(v) }
asfloat_double2x2 :: proc "c" (v: double2x2) -> float2x2 { return float2x2(v) }
asfloat_double3x3 :: proc "c" (v: double3x3) -> float3x3 { return float3x3(v) }
asfloat_double4x4 :: proc "c" (v: double4x4) -> float4x4 { return float4x4(v) }
asfloat_double1x2 :: proc "c" (v: double1x2) -> float1x2 { return float1x2(v) }
asfloat_double1x3 :: proc "c" (v: double1x3) -> float1x3 { return float1x3(v) }
asfloat_double1x4 :: proc "c" (v: double1x4) -> float1x4 { return float1x4(v) }
asfloat_double2x1 :: proc "c" (v: double2x1) -> float2x1 { return float2x1(v) }
asfloat_double2x3 :: proc "c" (v: double2x3) -> float2x3 { return float2x3(v) }
asfloat_double2x4 :: proc "c" (v: double2x4) -> float2x4 { return float2x4(v) }
asfloat_double3x1 :: proc "c" (v: double3x1) -> float3x1 { return float3x1(v) }
asfloat_double3x2 :: proc "c" (v: double3x2) -> float3x2 { return float3x2(v) }
asfloat_double3x4 :: proc "c" (v: double3x4) -> float3x4 { return float3x4(v) }
asfloat_double4x1 :: proc "c" (v: double4x1) -> float4x1 { return float4x1(v) }
asfloat_double4x2 :: proc "c" (v: double4x2) -> float4x2 { return float4x2(v) }
asfloat_double4x3 :: proc "c" (v: double4x3) -> float4x3 { return float4x3(v) }
asfloat_double2   :: proc "c" (v: double2)   -> float2   { return float2{float(v.x), float(v.y)} }
asfloat_double3   :: proc "c" (v: double3)   -> float3   { return float3{float(v.x), float(v.y), float(v.z)} }
asfloat_double4   :: proc "c" (v: double4)   -> float4   { return float4{float(v.x), float(v.y), float(v.z), float(v.w)} }

asdouble :: proc{
	asdouble_float,
	asdouble_double,
	asdouble_int,
	asdouble_uint,
	asdouble_float1x1,
	asdouble_float2x2,
	asdouble_float3x3,
	asdouble_float4x4,
	asdouble_float1x2,
	asdouble_float1x3,
	asdouble_float1x4,
	asdouble_float2x1,
	asdouble_float2x3,
	asdouble_float2x4,
	asdouble_float3x1,
	asdouble_float3x2,
	asdouble_float3x4,
	asdouble_float4x1,
	asdouble_float4x2,
	asdouble_float4x3,
	asdouble_float2,
	asdouble_float3,
	asdouble_float4,
	asdouble_int2,
	asdouble_int3,
	asdouble_int4,
	asdouble_uint2,
	asdouble_uint3,
	asdouble_uint4,
	asdouble_bool2,
	asdouble_bool3,
	asdouble_bool4,
	asdouble_double1x1,
	asdouble_double2x2,
	asdouble_double3x3,
	asdouble_double4x4,
	asdouble_double1x2,
	asdouble_double1x3,
	asdouble_double1x4,
	asdouble_double2x1,
	asdouble_double2x3,
	asdouble_double2x4,
	asdouble_double3x1,
	asdouble_double3x2,
	asdouble_double3x4,
	asdouble_double4x1,
	asdouble_double4x2,
	asdouble_double4x3,
	asdouble_double2,
	asdouble_double3,
	asdouble_double4,
}
asdouble_float     :: proc "c" (v: float)     -> double    { return double(v) }
asdouble_double    :: proc "c" (v: double)    -> double    { return double(v) }
asdouble_int       :: proc "c" (v: int)       -> double    { return double(v) }
asdouble_uint      :: proc "c" (v: uint)      -> double    { return double(v) }
asdouble_float1x1  :: proc "c" (v: float1x1)  -> double1x1 { return double1x1(v) }
asdouble_float2x2  :: proc "c" (v: float2x2)  -> double2x2 { return double2x2(v) }
asdouble_float3x3  :: proc "c" (v: float3x3)  -> double3x3 { return double3x3(v) }
asdouble_float4x4  :: proc "c" (v: float4x4)  -> double4x4 { return double4x4(v) }
asdouble_float1x2  :: proc "c" (v: float1x2)  -> double1x2 { return double1x2(v) }
asdouble_float1x3  :: proc "c" (v: float1x3)  -> double1x3 { return double1x3(v) }
asdouble_float1x4  :: proc "c" (v: float1x4)  -> double1x4 { return double1x4(v) }
asdouble_float2x1  :: proc "c" (v: float2x1)  -> double2x1 { return double2x1(v) }
asdouble_float2x3  :: proc "c" (v: float2x3)  -> double2x3 { return double2x3(v) }
asdouble_float2x4  :: proc "c" (v: float2x4)  -> double2x4 { return double2x4(v) }
asdouble_float3x1  :: proc "c" (v: float3x1)  -> double3x1 { return double3x1(v) }
asdouble_float3x2  :: proc "c" (v: float3x2)  -> double3x2 { return double3x2(v) }
asdouble_float3x4  :: proc "c" (v: float3x4)  -> double3x4 { return double3x4(v) }
asdouble_float4x1  :: proc "c" (v: float4x1)  -> double4x1 { return double4x1(v) }
asdouble_float4x2  :: proc "c" (v: float4x2)  -> double4x2 { return double4x2(v) }
asdouble_float4x3  :: proc "c" (v: float4x3)  -> double4x3 { return double4x3(v) }
asdouble_float2    :: proc "c" (v: float2)    -> double2   { return double2{double(v.x), double(v.y)} }
asdouble_float3    :: proc "c" (v: float3)    -> double3   { return double3{double(v.x), double(v.y), double(v.z)} }
asdouble_float4    :: proc "c" (v: float4)    -> double4   { return double4{double(v.x), double(v.y), double(v.z), double(v.w)} }
asdouble_int2      :: proc "c" (v: int2)      -> double2   { return double2{double(v.x), double(v.y)} }
asdouble_int3      :: proc "c" (v: int3)      -> double3   { return double3{double(v.x), double(v.y), double(v.z)} }
asdouble_int4      :: proc "c" (v: int4)      -> double4   { return double4{double(v.x), double(v.y), double(v.z), double(v.w)} }
asdouble_uint2     :: proc "c" (v: uint2)     -> double2   { return double2{double(v.x), double(v.y)} }
asdouble_uint3     :: proc "c" (v: uint3)     -> double3   { return double3{double(v.x), double(v.y), double(v.z)} }
asdouble_uint4     :: proc "c" (v: uint4)     -> double4   { return double4{double(v.x), double(v.y), double(v.z), double(v.w)} }
asdouble_bool2     :: proc "c" (v: bool2)     -> double2   { return double2{double(int(v.x)), double(int(v.y))} }
asdouble_bool3     :: proc "c" (v: bool3)     -> double3   { return double3{double(int(v.x)), double(int(v.y)), double(int(v.z))} }
asdouble_bool4     :: proc "c" (v: bool4)     -> double4   { return double4{double(int(v.x)), double(int(v.y)), double(int(v.z)), double(int(v.w))} }
asdouble_double1x1 :: proc "c" (v: double1x1) -> double1x1 { return double1x1(v) }
asdouble_double2x2 :: proc "c" (v: double2x2) -> double2x2 { return double2x2(v) }
asdouble_double3x3 :: proc "c" (v: double3x3) -> double3x3 { return double3x3(v) }
asdouble_double4x4 :: proc "c" (v: double4x4) -> double4x4 { return double4x4(v) }
asdouble_double1x2 :: proc "c" (v: double1x2) -> double1x2 { return double1x2(v) }
asdouble_double1x3 :: proc "c" (v: double1x3) -> double1x3 { return double1x3(v) }
asdouble_double1x4 :: proc "c" (v: double1x4) -> double1x4 { return double1x4(v) }
asdouble_double2x1 :: proc "c" (v: double2x1) -> double2x1 { return double2x1(v) }
asdouble_double2x3 :: proc "c" (v: double2x3) -> double2x3 { return double2x3(v) }
asdouble_double2x4 :: proc "c" (v: double2x4) -> double2x4 { return double2x4(v) }
asdouble_double3x1 :: proc "c" (v: double3x1) -> double3x1 { return double3x1(v) }
asdouble_double3x2 :: proc "c" (v: double3x2) -> double3x2 { return double3x2(v) }
asdouble_double3x4 :: proc "c" (v: double3x4) -> double3x4 { return double3x4(v) }
asdouble_double4x1 :: proc "c" (v: double4x1) -> double4x1 { return double4x1(v) }
asdouble_double4x2 :: proc "c" (v: double4x2) -> double4x2 { return double4x2(v) }
asdouble_double4x3 :: proc "c" (v: double4x3) -> double4x3 { return double4x3(v) }
asdouble_double2   :: proc "c" (v: double2)   -> double2   { return double2{double(v.x), double(v.y)} }
asdouble_double3   :: proc "c" (v: double3)   -> double3   { return double3{double(v.x), double(v.y), double(v.z)} }
asdouble_double4   :: proc "c" (v: double4)   -> double4   { return double4{double(v.x), double(v.y), double(v.z), double(v.w)} }

asint :: proc{
	asint_float,
	asint_double,
	asint_int,
	asint_uint,
	asint_float1x1,
	asint_float2x2,
	asint_float3x3,
	asint_float4x4,
	asint_float1x2,
	asint_float1x3,
	asint_float1x4,
	asint_float2x1,
	asint_float2x3,
	asint_float2x4,
	asint_float3x1,
	asint_float3x2,
	asint_float3x4,
	asint_float4x1,
	asint_float4x2,
	asint_float4x3,
	asint_float2,
	asint_float3,
	asint_float4,
	asint_int2,
	asint_int3,
	asint_int4,
	asint_uint2,
	asint_uint3,
	asint_uint4,
	asint_bool2,
	asint_bool3,
	asint_bool4,
	asint_double1x1,
	asint_double2x2,
	asint_double3x3,
	asint_double4x4,
	asint_double1x2,
	asint_double1x3,
	asint_double1x4,
	asint_double2x1,
	asint_double2x3,
	asint_double2x4,
	asint_double3x1,
	asint_double3x2,
	asint_double3x4,
	asint_double4x1,
	asint_double4x2,
	asint_double4x3,
	asint_double2,
	asint_double3,
	asint_double4,
}
asint_float     :: proc "c" (v: float)     -> int    { return int(v) }
asint_double    :: proc "c" (v: double)    -> int    { return int(v) }
asint_int       :: proc "c" (v: int)       -> int    { return int(v) }
asint_uint      :: proc "c" (v: uint)      -> int    { return int(v) }
asint_float1x1  :: proc "c" (v: float1x1)  -> int1x1 { return int1x1(v) }
asint_float2x2  :: proc "c" (v: float2x2)  -> int2x2 { return int2x2(v) }
asint_float3x3  :: proc "c" (v: float3x3)  -> int3x3 { return int3x3(v) }
asint_float4x4  :: proc "c" (v: float4x4)  -> int4x4 { return int4x4(v) }
asint_float1x2  :: proc "c" (v: float1x2)  -> int1x2 { return int1x2(v) }
asint_float1x3  :: proc "c" (v: float1x3)  -> int1x3 { return int1x3(v) }
asint_float1x4  :: proc "c" (v: float1x4)  -> int1x4 { return int1x4(v) }
asint_float2x1  :: proc "c" (v: float2x1)  -> int2x1 { return int2x1(v) }
asint_float2x3  :: proc "c" (v: float2x3)  -> int2x3 { return int2x3(v) }
asint_float2x4  :: proc "c" (v: float2x4)  -> int2x4 { return int2x4(v) }
asint_float3x1  :: proc "c" (v: float3x1)  -> int3x1 { return int3x1(v) }
asint_float3x2  :: proc "c" (v: float3x2)  -> int3x2 { return int3x2(v) }
asint_float3x4  :: proc "c" (v: float3x4)  -> int3x4 { return int3x4(v) }
asint_float4x1  :: proc "c" (v: float4x1)  -> int4x1 { return int4x1(v) }
asint_float4x2  :: proc "c" (v: float4x2)  -> int4x2 { return int4x2(v) }
asint_float4x3  :: proc "c" (v: float4x3)  -> int4x3 { return int4x3(v) }
asint_float2    :: proc "c" (v: float2)    -> int2   { return int2{int(v.x), int(v.y)} }
asint_float3    :: proc "c" (v: float3)    -> int3   { return int3{int(v.x), int(v.y), int(v.z)} }
asint_float4    :: proc "c" (v: float4)    -> int4   { return int4{int(v.x), int(v.y), int(v.z), int(v.w)} }
asint_int2      :: proc "c" (v: int2)      -> int2   { return int2{int(v.x), int(v.y)} }
asint_int3      :: proc "c" (v: int3)      -> int3   { return int3{int(v.x), int(v.y), int(v.z)} }
asint_int4      :: proc "c" (v: int4)      -> int4   { return int4{int(v.x), int(v.y), int(v.z), int(v.w)} }
asint_uint2     :: proc "c" (v: uint2)     -> int2   { return int2{int(v.x), int(v.y)} }
asint_uint3     :: proc "c" (v: uint3)     -> int3   { return int3{int(v.x), int(v.y), int(v.z)} }
asint_uint4     :: proc "c" (v: uint4)     -> int4   { return int4{int(v.x), int(v.y), int(v.z), int(v.w)} }
asint_bool2     :: proc "c" (v: bool2)     -> int2   { return int2{int(int(v.x)), int(int(v.y))} }
asint_bool3     :: proc "c" (v: bool3)     -> int3   { return int3{int(int(v.x)), int(int(v.y)), int(int(v.z))} }
asint_bool4     :: proc "c" (v: bool4)     -> int4   { return int4{int(int(v.x)), int(int(v.y)), int(int(v.z)), int(int(v.w))} }
asint_double1x1 :: proc "c" (v: double1x1) -> int1x1 { return int1x1(v) }
asint_double2x2 :: proc "c" (v: double2x2) -> int2x2 { return int2x2(v) }
asint_double3x3 :: proc "c" (v: double3x3) -> int3x3 { return int3x3(v) }
asint_double4x4 :: proc "c" (v: double4x4) -> int4x4 { return int4x4(v) }
asint_double1x2 :: proc "c" (v: double1x2) -> int1x2 { return int1x2(v) }
asint_double1x3 :: proc "c" (v: double1x3) -> int1x3 { return int1x3(v) }
asint_double1x4 :: proc "c" (v: double1x4) -> int1x4 { return int1x4(v) }
asint_double2x1 :: proc "c" (v: double2x1) -> int2x1 { return int2x1(v) }
asint_double2x3 :: proc "c" (v: double2x3) -> int2x3 { return int2x3(v) }
asint_double2x4 :: proc "c" (v: double2x4) -> int2x4 { return int2x4(v) }
asint_double3x1 :: proc "c" (v: double3x1) -> int3x1 { return int3x1(v) }
asint_double3x2 :: proc "c" (v: double3x2) -> int3x2 { return int3x2(v) }
asint_double3x4 :: proc "c" (v: double3x4) -> int3x4 { return int3x4(v) }
asint_double4x1 :: proc "c" (v: double4x1) -> int4x1 { return int4x1(v) }
asint_double4x2 :: proc "c" (v: double4x2) -> int4x2 { return int4x2(v) }
asint_double4x3 :: proc "c" (v: double4x3) -> int4x3 { return int4x3(v) }
asint_double2   :: proc "c" (v: double2)   -> int2   { return int2{int(v.x), int(v.y)} }
asint_double3   :: proc "c" (v: double3)   -> int3   { return int3{int(v.x), int(v.y), int(v.z)} }
asint_double4   :: proc "c" (v: double4)   -> int4   { return int4{int(v.x), int(v.y), int(v.z), int(v.w)} }


asuint :: proc{
	asuint_float,
	asuint_double,
	asuint_int,
	asuint_uint,
	asuint_float2,
	asuint_float3,
	asuint_float4,
	asuint_int2,
	asuint_int3,
	asuint_int4,
	asuint_uint2,
	asuint_uint3,
	asuint_uint4,
	asuint_bool2,
	asuint_bool3,
	asuint_bool4,
	asuint_double2,
	asuint_double3,
	asuint_double4,
}
asuint_float     :: proc "c" (v: float)     -> uint    { return uint(v) }
asuint_double    :: proc "c" (v: double)    -> uint    { return uint(v) }
asuint_int       :: proc "c" (v: int)       -> uint    { return uint(v) }
asuint_uint      :: proc "c" (v: uint)      -> uint    { return uint(v) }
asuint_float2    :: proc "c" (v: float2)    -> uint2   { return uint2{uint(v.x), uint(v.y)} }
asuint_float3    :: proc "c" (v: float3)    -> uint3   { return uint3{uint(v.x), uint(v.y), uint(v.z)} }
asuint_float4    :: proc "c" (v: float4)    -> uint4   { return uint4{uint(v.x), uint(v.y), uint(v.z), uint(v.w)} }
asuint_int2      :: proc "c" (v: int2)      -> uint2   { return uint2{uint(v.x), uint(v.y)} }
asuint_int3      :: proc "c" (v: int3)      -> uint3   { return uint3{uint(v.x), uint(v.y), uint(v.z)} }
asuint_int4      :: proc "c" (v: int4)      -> uint4   { return uint4{uint(v.x), uint(v.y), uint(v.z), uint(v.w)} }
asuint_uint2     :: proc "c" (v: uint2)     -> uint2   { return uint2{uint(v.x), uint(v.y)} }
asuint_uint3     :: proc "c" (v: uint3)     -> uint3   { return uint3{uint(v.x), uint(v.y), uint(v.z)} }
asuint_uint4     :: proc "c" (v: uint4)     -> uint4   { return uint4{uint(v.x), uint(v.y), uint(v.z), uint(v.w)} }
asuint_bool2     :: proc "c" (v: bool2)     -> uint2   { return uint2{uint(uint(v.x)), uint(uint(v.y))} }
asuint_bool3     :: proc "c" (v: bool3)     -> uint3   { return uint3{uint(uint(v.x)), uint(uint(v.y)), uint(uint(v.z))} }
asuint_bool4     :: proc "c" (v: bool4)     -> uint4   { return uint4{uint(uint(v.x)), uint(uint(v.y)), uint(uint(v.z)), uint(uint(v.w))} }
asuint_double2   :: proc "c" (v: double2)   -> uint2   { return uint2{uint(v.x), uint(v.y)} }
asuint_double3   :: proc "c" (v: double3)   -> uint3   { return uint3{uint(v.x), uint(v.y), uint(v.z)} }
asuint_double4   :: proc "c" (v: double4)   -> uint4   { return uint4{uint(v.x), uint(v.y), uint(v.z), uint(v.w)} }


// TODO(bill): All of the `mul` procedures
