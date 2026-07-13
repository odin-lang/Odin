// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "core.h"

#include <stdbool.h>

#if defined( B3_SIMD_SSE2 )

#include <emmintrin.h>

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
