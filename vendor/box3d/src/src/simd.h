// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "core.h"

#include <stdbool.h>

#if defined( B3_SIMD_NEON )

#include <arm_neon.h>

// wide float holds 4 numbers
typedef float32x4_t b3FloatW;

#elif defined( B3_SIMD_SSE2 )

#include <emmintrin.h>

// wide float holds 4 numbers
typedef __m128 b3FloatW;

#else

#include <math.h>
#include <string.h>

// scalar math
typedef struct b3FloatW
{
	float x, y, z, w;
} b3FloatW;

#endif

#if defined( B3_SIMD_SSE2 )

// wide float holds 4 numbers
typedef __m128 b3V32;

typedef union b3128
{
	b3V32 v;
	float f[4];
} b3128;

#if defined( _MSC_VER ) && !defined( __clang__ )

static const b3V32 b3_zeroV = { { 0.0f, 0.0f, 0.0f, 0.0f } };
static const b3V32 b3_halfV = { { 0.5f, 0.5f, 0.5f, 0.5f } };
static const b3V32 b3_oneV = { { 1.0f, 1.0f, 1.0f, 1.0f } };

#else

static const b3V32 b3_zeroV = { 0.0f, 0.0f, 0.0f, 0.0f };
static const b3V32 b3_halfV = { 0.5f, 0.5f, 0.5f, 0.5f };
static const b3V32 b3_oneV = { 1.0f, 1.0f, 1.0f, 1.0f };

#endif

static inline b3V32 b3AddV( b3V32 a, b3V32 b )
{
	return _mm_add_ps( a, b );
}

static inline b3V32 b3SubV( b3V32 a, b3V32 b )
{
	return _mm_sub_ps( a, b );
}

static inline b3V32 b3MulV( b3V32 a, b3V32 b )
{
	return _mm_mul_ps( a, b );
}

static inline b3V32 b3DivV( b3V32 a, b3V32 b )
{
	return _mm_div_ps( a, b );
}

static inline b3V32 b3NegV( b3V32 a )
{
	return _mm_sub_ps( _mm_setzero_ps(), a );
}

static inline b3V32 b3LoadV( const float* src )
{
	// Loads exactly 12 bytes: 8 via movsd, 4 via movss.
	// Result lane 3 is implicitly zero from the partial loads.
	__m128 xy = _mm_castpd_ps( _mm_load_sd( (const double*)( src ) ) );
	__m128 z = _mm_load_ss( src + 2 );
	return _mm_movelh_ps( xy, z ); // { src[0], src[1], src[2], 0.0f }
}

static inline b3V32 b3ZeroV( void )
{
	return _mm_setzero_ps();
}

static inline float b3GetXV( b3V32 a )
{
	return _mm_cvtss_f32( a );
}

static inline float b3GetYV( b3V32 a )
{
	return _mm_cvtss_f32( _mm_shuffle_ps( a, a, _MM_SHUFFLE( 1, 1, 1, 1 ) ) );
}

static inline float b3GetZV( b3V32 a )
{
	return _mm_cvtss_f32( _mm_shuffle_ps( a, a, _MM_SHUFFLE( 2, 2, 2, 2 ) ) );
}

static inline float b3GetV( b3V32 a, int index )
{
	b3128 b;
	b.v = a;
	return b.f[index];
}

static inline b3V32 b3SplatV( float x )
{
	return _mm_set_ps1( x );
}

static inline b3V32 b3AbsV( b3V32 a )
{
	// Abs( V ) = Max( -V, V )
	b3V32 zero = _mm_setzero_ps();
	return _mm_max_ps( _mm_sub_ps( zero, a ), a );
}

static inline b3V32 b3MinV( b3V32 a, b3V32 b )
{
	return _mm_min_ps( a, b );
}

static inline b3V32 b3MaxV( b3V32 a, b3V32 b )
{
	return _mm_max_ps( a, b );
}

static inline b3V32 b3CrossV( b3V32 a, b3V32 b )
{
	b3V32 yzX1 = _mm_shuffle_ps( a, a, _MM_SHUFFLE( 3, 0, 2, 1 ) );
	b3V32 zxY1 = _mm_shuffle_ps( a, a, _MM_SHUFFLE( 3, 1, 0, 2 ) );
	b3V32 yzX2 = _mm_shuffle_ps( b, b, _MM_SHUFFLE( 3, 0, 2, 1 ) );
	b3V32 zxY2 = _mm_shuffle_ps( b, b, _MM_SHUFFLE( 3, 1, 0, 2 ) );

	return _mm_sub_ps( _mm_mul_ps( yzX1, zxY2 ), _mm_mul_ps( zxY1, yzX2 ) );
}

static inline b3V32 b3ModifiedCrossV( b3V32 a, b3V32 b )
{
	b3V32 yzX1 = _mm_shuffle_ps( a, a, _MM_SHUFFLE( 3, 0, 2, 1 ) );
	b3V32 zxY1 = _mm_shuffle_ps( a, a, _MM_SHUFFLE( 3, 1, 0, 2 ) );
	b3V32 yzX2 = _mm_shuffle_ps( b, b, _MM_SHUFFLE( 3, 0, 2, 1 ) );
	b3V32 zxY2 = _mm_shuffle_ps( b, b, _MM_SHUFFLE( 3, 1, 0, 2 ) );

	return _mm_add_ps( _mm_mul_ps( yzX1, zxY2 ), _mm_mul_ps( zxY1, yzX2 ) );
}

static inline bool b3AnyLess3V( b3V32 a, b3V32 b )
{
	b3V32 v = _mm_cmplt_ps( a, b );
	return ( _mm_movemask_ps( v ) & 0x07 ) != 0;
}

static inline bool b3AnyLessEq3V( b3V32 a, b3V32 b )
{
	b3V32 v = _mm_cmple_ps( a, b );
	return ( _mm_movemask_ps( v ) & 0x07 ) != 0;
}

static inline bool b3AnyGreater3V( b3V32 a, b3V32 b )
{
	b3V32 v = _mm_cmpgt_ps( a, b );
	return ( _mm_movemask_ps( v ) & 0x07 ) != 0;
}

static inline bool b3AllLessEq3V( b3V32 a, b3V32 b )
{
	b3V32 v = _mm_cmple_ps( a, b );
	return ( _mm_movemask_ps( v ) & 0x07 ) == 0x07;
}

#else

// I don't expect the use case of b3V32 to benefit from Neon code.
// In particular the cross product is very complex in Neon.

// scalar math
typedef struct b3V32
{
	float x, y, z;
} b3V32;

typedef union b3128
{
	b3V32 v;
	float f[3];
} b3128;

static const b3V32 b3_zeroV = { 0.0f, 0.0f, 0.0f };
static const b3V32 b3_halfV = { 0.5f, 0.5f, 0.5f };
static const b3V32 b3_oneV = { 1.0f, 1.0f, 1.0f };

static inline b3V32 b3AddV( b3V32 a, b3V32 b )
{
	return B3_LITERAL( b3V32 ){
		a.x + b.x,
		a.y + b.y,
		a.z + b.z,
	};
}

static inline b3V32 b3SubV( b3V32 a, b3V32 b )
{
	return B3_LITERAL( b3V32 ){
		a.x - b.x,
		a.y - b.y,
		a.z - b.z,
	};
}

static inline b3V32 b3MulV( b3V32 a, b3V32 b )
{
	return B3_LITERAL( b3V32 ){
		a.x * b.x,
		a.y * b.y,
		a.z * b.z,
	};
}

static inline b3V32 b3DivV( b3V32 a, b3V32 b )
{
	return B3_LITERAL( b3V32 ){
		a.x / b.x,
		a.y / b.y,
		a.z / b.z,
	};
}

static inline b3V32 b3NegV( b3V32 a )
{
	return B3_LITERAL( b3V32 ){
		-a.x,
		-a.y,
		-a.z,
	};
}

// Unaligned loads are much faster on recent hardware with little to no penalty
static inline b3V32 b3LoadV( const float* src )
{
	return B3_LITERAL( b3V32 ){ src[0], src[1], src[2] };
}

static inline b3V32 b3ZeroV( void )
{
	return B3_LITERAL( b3V32 ){ 0.0f, 0.0f, 0.0f };
}

static inline float b3GetXV( b3V32 a )
{
	return a.x;
}

static inline float b3GetYV( b3V32 a )
{
	return a.y;
}

static inline float b3GetZV( b3V32 a )
{
	return a.z;
}

static inline float b3GetV( b3V32 a, int index )
{
	b3128 b;
	b.v = a;
	return b.f[index];
}

static inline b3V32 b3SplatV( float x )
{
	return B3_LITERAL( b3V32 ){ x, x, x };
}

static inline b3V32 b3AbsV( b3V32 a )
{
	return B3_LITERAL( b3V32 ){
		a.x < 0.0f ? -a.x : a.x,
		a.y < 0.0f ? -a.y : a.y,
		a.z < 0.0f ? -a.z : a.z,
	};
}

static inline b3V32 b3MinV( b3V32 a, b3V32 b )
{
	return B3_LITERAL( b3V32 ){
		a.x < b.x ? a.x : b.x,
		a.y < b.y ? a.y : b.y,
		a.z < b.z ? a.z : b.z,
	};
}

static inline b3V32 b3MaxV( b3V32 a, b3V32 b )
{
	return B3_LITERAL( b3V32 ){
		a.x > b.x ? a.x : b.x,
		a.y > b.y ? a.y : b.y,
		a.z > b.z ? a.z : b.z,
	};
}

static inline b3V32 b3CrossV( b3V32 a, b3V32 b )
{
	b3V32 c;
	c.x = a.y * b.z - a.z * b.y;
	c.y = a.z * b.x - a.x * b.z;
	c.z = a.x * b.y - a.y * b.x;
	return c;
}

static inline b3V32 b3ModifiedCrossV( b3V32 a, b3V32 b )
{
	b3V32 c;
	c.x = a.y * b.z + a.z * b.y;
	c.y = a.z * b.x + a.x * b.z;
	c.z = a.x * b.y + a.y * b.x;
	return c;
}

static inline bool b3AnyLess3V( b3V32 a, b3V32 b )
{
	return a.x < b.x || a.y < b.y || a.z < b.z;
}

static inline bool b3AnyLessEq3V( b3V32 a, b3V32 b )
{
	return a.x <= b.x || a.y <= b.y || a.z <= b.z;
}

static inline bool b3AnyGreater3V( b3V32 a, b3V32 b )
{
	return a.x > b.x || a.y > b.y || a.z > b.z;
}

static inline bool b3AllLessEq3V( b3V32 a, b3V32 b )
{
	return a.x <= b.x && a.y <= b.y && a.z <= b.z;
}

#endif

static inline bool b3TestBoundsOverlap( b3V32 nodeMin1, b3V32 nodeMax1, b3V32 nodeMin2, b3V32 nodeMax2 )
{
	b3V32 separation = b3MaxV( b3SubV( nodeMin2, nodeMax1 ), b3SubV( nodeMin1, nodeMax2 ) );
	return b3AllLessEq3V( separation, b3_zeroV );
}

// Test a ray for edge separation with an AABB (Gino, p80).
static inline bool b3TestBoundsRayOverlap( b3V32 nodeMin, b3V32 nodeMax, b3V32 rayStart, b3V32 rayDelta )
{
	// Setup node
	b3V32 nodeCenter = b3MulV( b3_halfV, b3AddV( nodeMin, nodeMax ) );
	b3V32 nodeExtent = b3SubV( nodeMax, nodeCenter );

	// Setup ray
	rayStart = b3SubV( rayStart, nodeCenter );

	// SAT: Edge separation
	b3V32 edgeSeparation = b3SubV( b3AbsV( b3CrossV( rayDelta, rayStart ) ), b3ModifiedCrossV( b3AbsV( rayDelta ), nodeExtent ) );
	return b3AllLessEq3V( edgeSeparation, b3_zeroV );
}

bool b3TestBoundsTriangleOverlap( b3V32 nodeCenter, b3V32 nodeExtent, b3V32 vertex1, b3V32 vertex2, b3V32 vertex3 );
float b3IntersectRayTriangle( b3V32 rayStart, b3V32 rayDelta, b3V32 vertex1, b3V32 vertex2, b3V32 vertex3 );

#if defined( B3_SIMD_NEON )

static inline b3FloatW b3ZeroW( void )
{
	return vdupq_n_f32( 0.0f );
}

static inline b3FloatW b3SplatW( float scalar )
{
	return vdupq_n_f32( scalar );
}

static inline b3FloatW b3SetW( float a, float b, float c, float d )
{
	float32_t array[4] = { a, b, c, d };
	return vld1q_f32( array );
}

static inline b3FloatW b3LoadW( const float* data )
{
	return vld1q_f32( data );
}

static inline void b3StoreW( float* data, b3FloatW a )
{
	vst1q_f32( data, a );
}

static inline b3FloatW b3NegW( b3FloatW a )
{
	return vnegq_f32( a );
}

static inline b3FloatW b3AddW( b3FloatW a, b3FloatW b )
{
	return vaddq_f32( a, b );
}

static inline b3FloatW b3SubW( b3FloatW a, b3FloatW b )
{
	return vsubq_f32( a, b );
}

static inline b3FloatW b3MulW( b3FloatW a, b3FloatW b )
{
	return vmulq_f32( a, b );
}

static inline b3FloatW b3DivW( b3FloatW a, b3FloatW b )
{
	return vdivq_f32( a, b );
}

static inline b3FloatW b3SqrtW( b3FloatW a )
{
	return vsqrtq_f32( a );
}

// Cannot use real FMA because it doesn't match the non-SIMD path
static inline b3FloatW b3MulAddW( b3FloatW a, b3FloatW b, b3FloatW c )
{
	return vaddq_f32( a, vmulq_f32( b, c ) );
}

static inline b3FloatW b3MinW( b3FloatW a, b3FloatW b )
{
	return vminq_f32( a, b );
}

static inline b3FloatW b3MaxW( b3FloatW a, b3FloatW b )
{
	return vmaxq_f32( a, b );
}

// clamp a to [-b, b]
static inline b3FloatW b3SymClampW( b3FloatW a, b3FloatW b )
{
	b3FloatW nb = b3NegW( b );
	b3FloatW c = b3MaxW( nb, a );
	return b3MinW( c, b );
}

static inline b3FloatW b3AndW( b3FloatW a, b3FloatW b )
{
	return vreinterpretq_f32_u32( vandq_u32( vreinterpretq_u32_f32( a ), vreinterpretq_u32_f32( b ) ) );
}

static inline b3FloatW b3OrW( b3FloatW a, b3FloatW b )
{
	return vreinterpretq_f32_u32( vorrq_u32( vreinterpretq_u32_f32( a ), vreinterpretq_u32_f32( b ) ) );
}

static inline b3FloatW b3GreaterThanW( b3FloatW a, b3FloatW b )
{
	return vreinterpretq_f32_u32( vcgtq_f32( a, b ) );
}

static inline b3FloatW b3LessThanW( b3FloatW a, b3FloatW b )
{
	return vreinterpretq_f32_u32( vcltq_f32( a, b ) );
}

static inline b3FloatW b3EqualsW( b3FloatW a, b3FloatW b )
{
	return vreinterpretq_f32_u32( vceqq_f32( a, b ) );
}

static inline bool b3AllZeroW( b3FloatW a )
{
	// Create a zero vector for comparison
	b3FloatW zero = vdupq_n_f32( 0.0f );

	// Compare the input vector with zero
	uint32x4_t cmp_result = vceqq_f32( a, zero );

// Check if all comparison results are non-zero using vminvq
#ifdef __ARM_FEATURE_SVE
	// ARM v8.2+ has horizontal minimum instruction
	return vminvq_u32( cmp_result ) != 0;
#else
	// For older ARM architectures, we need to manually check all lanes
	return vgetq_lane_u32( cmp_result, 0 ) != 0 && vgetq_lane_u32( cmp_result, 1 ) != 0 && vgetq_lane_u32( cmp_result, 2 ) != 0 &&
		   vgetq_lane_u32( cmp_result, 3 ) != 0;
#endif
}

// _mm_movemask_ps equivalent, compatible with ARM v7.
static inline bool b3AnyTrueW( b3FloatW mask )
{
	uint32x4_t m = vreinterpretq_u32_f32( mask );
	uint32x2_t p = vorr_u32( vget_low_u32( m ), vget_high_u32( m ) );
	return ( vget_lane_u32( p, 0 ) | vget_lane_u32( p, 1 ) ) != 0;
}

// component-wise returns mask ? b : a
static inline b3FloatW b3BlendW( b3FloatW a, b3FloatW b, b3FloatW mask )
{
	uint32x4_t mask32 = vreinterpretq_u32_f32( mask );
	return vbslq_f32( mask32, b, a );
}

static inline b3FloatW b3Dot3W( b3FloatW ax, b3FloatW ay, b3FloatW az, b3FloatW bx, b3FloatW by, b3FloatW bz )
{
	return vaddq_f32( vmulq_f32( ax, bx ), vaddq_f32( vmulq_f32( ay, by ), vmulq_f32( az, bz ) ) );
}

static inline b3FloatW b3EmbedIndexW( b3FloatW value, int baseIndex, int bitCount )
{
	uint32_t mask = ( 1u << bitCount ) - 1;
	const int32_t lanes[4] = { 0, 1, 2, 3 };
	int32x4_t index = vaddq_s32( vdupq_n_s32( baseIndex ), vld1q_s32( lanes ) );
	uint32x4_t clearLow = vdupq_n_u32( ~mask );
	uint32x4_t bits = vorrq_u32( vandq_u32( vreinterpretq_u32_f32( value ), clearLow ), vreinterpretq_u32_s32( index ) );
	return vreinterpretq_f32_u32( bits );
}

static inline int b3MinIndexW( b3FloatW a, int bitCount )
{
	float32x2_t m = vmin_f32( vget_low_f32( a ), vget_high_f32( a ) );
	m = vpmin_f32( m, m );
	uint32_t bits = vget_lane_u32( vreinterpret_u32_f32( m ), 0 );
	return (int)( bits & ( ( 1u << bitCount ) - 1 ) );
}

#elif defined( B3_SIMD_SSE2 )

static inline b3FloatW b3ZeroW( void )
{
	return _mm_setzero_ps();
}

static inline b3FloatW b3SplatW( float scalar )
{
	return _mm_set1_ps( scalar );
}

static inline b3FloatW b3SetW( float a, float b, float c, float d )
{
	return _mm_setr_ps( a, b, c, d );
}

static inline b3FloatW b3LoadW( const float* data )
{
	return _mm_loadu_ps( data );
}

static inline void b3StoreW( float* data, b3FloatW a )
{
	_mm_storeu_ps( data, a );
}

static inline b3FloatW b3NegW( b3FloatW a )
{
	// Create a mask with the sign bit set for each element
	__m128 mask = _mm_set1_ps( -0.0f );

	// XOR the input with the mask to negate each element
	return _mm_xor_ps( a, mask );
}

static inline b3FloatW b3AddW( b3FloatW a, b3FloatW b )
{
	return _mm_add_ps( a, b );
}

static inline b3FloatW b3SubW( b3FloatW a, b3FloatW b )
{
	return _mm_sub_ps( a, b );
}

static inline b3FloatW b3MulW( b3FloatW a, b3FloatW b )
{
	return _mm_mul_ps( a, b );
}

static inline b3FloatW b3DivW( b3FloatW a, b3FloatW b )
{
	return _mm_div_ps( a, b );
}

static inline b3FloatW b3SqrtW( b3FloatW a )
{
	return _mm_sqrt_ps( a );
}

// a + b * c
static inline b3FloatW b3MulAddW( b3FloatW a, b3FloatW b, b3FloatW c )
{
	return _mm_add_ps( a, _mm_mul_ps( b, c ) );
}

static inline b3FloatW b3MinW( b3FloatW a, b3FloatW b )
{
	return _mm_min_ps( a, b );
}

static inline b3FloatW b3MaxW( b3FloatW a, b3FloatW b )
{
	return _mm_max_ps( a, b );
}

// Horizontal min over a 4-lane vector (result broadcast to all lanes).
static inline b3FloatW b3HorizontalMinW( b3FloatW v )
{
	v = _mm_min_ps( v, _mm_shuffle_ps( v, v, _MM_SHUFFLE( 2, 3, 0, 1 ) ) );
	return _mm_min_ps( v, _mm_shuffle_ps( v, v, _MM_SHUFFLE( 1, 0, 3, 2 ) ) );
}

// clamp a to [-b, b]
static inline b3FloatW b3SymClampW( b3FloatW a, b3FloatW b )
{
	b3FloatW nb = b3NegW( b );
	b3FloatW c = b3MaxW( nb, a );
	return b3MinW( c, b );
}

static inline b3FloatW b3AndW( b3FloatW a, b3FloatW b )
{
	return _mm_and_ps( a, b );
}

static inline b3FloatW b3OrW( b3FloatW a, b3FloatW b )
{
	return _mm_or_ps( a, b );
}

static inline b3FloatW b3GreaterThanW( b3FloatW a, b3FloatW b )
{
	return _mm_cmpgt_ps( a, b );
}

static inline b3FloatW b3LessThanW( b3FloatW a, b3FloatW b )
{
	return _mm_cmplt_ps( a, b );
}

static inline b3FloatW b3EqualsW( b3FloatW a, b3FloatW b )
{
	return _mm_cmpeq_ps( a, b );
}

static inline bool b3AllZeroW( b3FloatW a )
{
	// Compare each element with zero
	b3FloatW zero = _mm_setzero_ps();
	b3FloatW cmp = _mm_cmpeq_ps( a, zero );

	// Create a mask from the comparison results
	int mask = _mm_movemask_ps( cmp );

	// If all elements are zero, the mask will be 0xF (1111 in binary)
	return mask == 0xF;
}

static inline bool b3AnyTrueW( b3FloatW mask )
{
	return _mm_movemask_ps( mask ) != 0;
}

// component-wise returns mask ? b : a
static inline b3FloatW b3BlendW( b3FloatW a, b3FloatW b, b3FloatW mask )
{
	return _mm_or_ps( _mm_and_ps( mask, b ), _mm_andnot_ps( mask, a ) );
}

static inline b3FloatW b3Dot3W( b3FloatW ax, b3FloatW ay, b3FloatW az, b3FloatW bx, b3FloatW by, b3FloatW bz )
{
	return _mm_add_ps( _mm_mul_ps( ax, bx ), _mm_add_ps( _mm_mul_ps( ay, by ), _mm_mul_ps( az, bz ) ) );
}

// Replace the low bitCount mantissa bits of each lane with baseIndex + lane. The value must be
// positive so the embedded index sorts with the value, and ties fall to the lower index.
static inline b3FloatW b3EmbedIndexW( b3FloatW value, int baseIndex, int bitCount )
{
	int mask = ( 1 << bitCount ) - 1;
	__m128i index = _mm_add_epi32( _mm_set1_epi32( baseIndex ), _mm_setr_epi32( 0, 1, 2, 3 ) );
	__m128 clearLow = _mm_castsi128_ps( _mm_set1_epi32( ~mask ) );
	return _mm_or_ps( _mm_and_ps( value, clearLow ), _mm_castsi128_ps( index ) );
}

// Recovers the index embedded by b3EmbedIndexW from the lane holding the minimum.
static inline int b3MinIndexW( b3FloatW a, int bitCount )
{
	a = _mm_min_ps( a, _mm_shuffle_ps( a, a, _MM_SHUFFLE( 2, 3, 0, 1 ) ) );
	a = _mm_min_ps( a, _mm_shuffle_ps( a, a, _MM_SHUFFLE( 1, 0, 3, 2 ) ) );
	return _mm_cvtsi128_si32( _mm_castps_si128( a ) ) & ( ( 1 << bitCount ) - 1 );
}

#else

static inline b3FloatW b3ZeroW( void )
{
	return (b3FloatW){ 0.0f, 0.0f, 0.0f, 0.0f };
}

static inline b3FloatW b3SplatW( float scalar )
{
	return (b3FloatW){ scalar, scalar, scalar, scalar };
}

static inline b3FloatW b3SetW( float a, float b, float c, float d )
{
	return (b3FloatW){ a, b, c, d };
}

static inline b3FloatW b3LoadW( const float* data )
{
	return (b3FloatW){ data[0], data[1], data[2], data[3] };
}

static inline void b3StoreW( float* data, b3FloatW a )
{
	data[0] = a.x;
	data[1] = a.y;
	data[2] = a.z;
	data[3] = a.w;
}

static inline b3FloatW b3NegW( b3FloatW a )
{
	return (b3FloatW){ -a.x, -a.y, -a.z, -a.w };
}

static inline b3FloatW b3AddW( b3FloatW a, b3FloatW b )
{
	return (b3FloatW){ a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w };
}

static inline b3FloatW b3SubW( b3FloatW a, b3FloatW b )
{
	return (b3FloatW){ a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w };
}

static inline b3FloatW b3MulW( b3FloatW a, b3FloatW b )
{
	return (b3FloatW){ a.x * b.x, a.y * b.y, a.z * b.z, a.w * b.w };
}

static inline b3FloatW b3DivW( b3FloatW a, b3FloatW b )
{
	return (b3FloatW){ a.x / b.x, a.y / b.y, a.z / b.z, a.w / b.w };
}

static inline b3FloatW b3SqrtW( b3FloatW a )
{
	return (b3FloatW){ sqrtf( a.x ), sqrtf( a.y ), sqrtf( a.z ), sqrtf( a.w ) };
}

static inline b3FloatW b3MulAddW( b3FloatW a, b3FloatW b, b3FloatW c )
{
	return (b3FloatW){ a.x + b.x * c.x, a.y + b.y * c.y, a.z + b.z * c.z, a.w + b.w * c.w };
}

static inline b3FloatW b3MinW( b3FloatW a, b3FloatW b )
{
	b3FloatW r;
	r.x = a.x <= b.x ? a.x : b.x;
	r.y = a.y <= b.y ? a.y : b.y;
	r.z = a.z <= b.z ? a.z : b.z;
	r.w = a.w <= b.w ? a.w : b.w;
	return r;
}

static inline b3FloatW b3MaxW( b3FloatW a, b3FloatW b )
{
	b3FloatW r;
	r.x = a.x >= b.x ? a.x : b.x;
	r.y = a.y >= b.y ? a.y : b.y;
	r.z = a.z >= b.z ? a.z : b.z;
	r.w = a.w >= b.w ? a.w : b.w;
	return r;
}

// clamp a to [-b, b]
static inline b3FloatW b3SymClampW( b3FloatW a, b3FloatW b )
{
	b3FloatW r;
	r.x = a.x <= b.x ? a.x : b.x;
	r.y = a.y <= b.y ? a.y : b.y;
	r.z = a.z <= b.z ? a.z : b.z;
	r.w = a.w <= b.w ? a.w : b.w;
	r.x = r.x <= -b.x ? -b.x : r.x;
	r.y = r.y <= -b.y ? -b.y : r.y;
	r.z = r.z <= -b.z ? -b.z : r.z;
	r.w = r.w <= -b.w ? -b.w : r.w;
	return r;
}

// Logical operations on the scalar path are 0/1 float values. Not bit-wise like SIMD.

static inline b3FloatW b3AndW( b3FloatW a, b3FloatW b )
{
	b3FloatW r;
	r.x = a.x != 0.0f && b.x != 0.0f ? 1.0f : 0.0f;
	r.y = a.y != 0.0f && b.y != 0.0f ? 1.0f : 0.0f;
	r.z = a.z != 0.0f && b.z != 0.0f ? 1.0f : 0.0f;
	r.w = a.w != 0.0f && b.w != 0.0f ? 1.0f : 0.0f;
	return r;
}

static inline b3FloatW b3OrW( b3FloatW a, b3FloatW b )
{
	b3FloatW r;
	r.x = a.x != 0.0f || b.x != 0.0f ? 1.0f : 0.0f;
	r.y = a.y != 0.0f || b.y != 0.0f ? 1.0f : 0.0f;
	r.z = a.z != 0.0f || b.z != 0.0f ? 1.0f : 0.0f;
	r.w = a.w != 0.0f || b.w != 0.0f ? 1.0f : 0.0f;
	return r;
}

static inline b3FloatW b3GreaterThanW( b3FloatW a, b3FloatW b )
{
	b3FloatW r;
	r.x = a.x > b.x ? 1.0f : 0.0f;
	r.y = a.y > b.y ? 1.0f : 0.0f;
	r.z = a.z > b.z ? 1.0f : 0.0f;
	r.w = a.w > b.w ? 1.0f : 0.0f;
	return r;
}

static inline b3FloatW b3LessThanW( b3FloatW a, b3FloatW b )
{
	b3FloatW r;
	r.x = a.x < b.x ? 1.0f : 0.0f;
	r.y = a.y < b.y ? 1.0f : 0.0f;
	r.z = a.z < b.z ? 1.0f : 0.0f;
	r.w = a.w < b.w ? 1.0f : 0.0f;
	return r;
}

static inline b3FloatW b3EqualsW( b3FloatW a, b3FloatW b )
{
	b3FloatW r;
	r.x = a.x == b.x ? 1.0f : 0.0f;
	r.y = a.y == b.y ? 1.0f : 0.0f;
	r.z = a.z == b.z ? 1.0f : 0.0f;
	r.w = a.w == b.w ? 1.0f : 0.0f;
	return r;
}

static inline bool b3AllZeroW( b3FloatW a )
{
	return a.x == 0.0f && a.y == 0.0f && a.z == 0.0f && a.w == 0.0f;
}

static inline bool b3AnyTrueW( b3FloatW mask )
{
	return mask.x != 0.0f || mask.y != 0.0f || mask.z != 0.0f || mask.w != 0.0f;
}

// component-wise returns mask ? b : a
static inline b3FloatW b3BlendW( b3FloatW a, b3FloatW b, b3FloatW mask )
{
	b3FloatW r;
	r.x = mask.x != 0.0f ? b.x : a.x;
	r.y = mask.y != 0.0f ? b.y : a.y;
	r.z = mask.z != 0.0f ? b.z : a.z;
	r.w = mask.w != 0.0f ? b.w : a.w;
	return r;
}

static inline b3FloatW b3Dot3W( b3FloatW ax, b3FloatW ay, b3FloatW az, b3FloatW bx, b3FloatW by, b3FloatW bz )
{
	b3FloatW r;
	r.x = ax.x * bx.x + ( ay.x * by.x + az.x * bz.x );
	r.y = ax.y * bx.y + ( ay.y * by.y + az.y * bz.y );
	r.z = ax.z * bx.z + ( ay.z * by.z + az.z * bz.z );
	r.w = ax.w * bx.w + ( ay.w * by.w + az.w * bz.w );
	return r;
}

static inline b3FloatW b3EmbedIndexW( b3FloatW value, int baseIndex, int bitCount )
{
	uint32_t mask = ( 1u << bitCount ) - 1;
	float lanes[4] = { value.x, value.y, value.z, value.w };

	for ( int i = 0; i < 4; ++i )
	{
		uint32_t bits;
		memcpy( &bits, lanes + i, sizeof( bits ) );
		bits = ( bits & ~mask ) | (uint32_t)( baseIndex + i );
		memcpy( lanes + i, &bits, sizeof( bits ) );
	}

	return (b3FloatW){ lanes[0], lanes[1], lanes[2], lanes[3] };
}

static inline int b3MinIndexW( b3FloatW a, int bitCount )
{
	float m = a.x;
	m = a.y < m ? a.y : m;
	m = a.z < m ? a.z : m;
	m = a.w < m ? a.w : m;

	uint32_t bits;
	memcpy( &bits, &m, sizeof( bits ) );
	return (int)( bits & ( ( 1u << bitCount ) - 1 ) );
}

#endif
