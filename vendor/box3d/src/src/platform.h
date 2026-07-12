// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include "core.h"

#include <stdbool.h>
#include <stdint.h>

// Software prefetch hint. T0 brings the line into all cache levels.
// On x86 MSVC exposes _mm_prefetch, ARM MSVC uses __prefetch instead.
// clang/gcc provide __builtin_prefetch on every target.
#if defined( B3_COMPILER_MSVC )
#include <intrin.h>
#if defined( B3_CPU_X86_X64 )
#define b3Prefetch( addr ) _mm_prefetch( (const char*)( addr ), _MM_HINT_T0 )
#else
#define b3Prefetch( addr ) __prefetch( (const void*)( addr ) )
#endif
#elif defined( B3_COMPILER_CLANG ) || defined( B3_COMPILER_GCC )
#define b3Prefetch( addr ) __builtin_prefetch( (const void*)( addr ), 0, 3 )
#else
#define b3Prefetch( addr ) ( (void)( addr ) )
#endif

static inline void b3AtomicStoreInt( b3AtomicInt* a, int value )
{
#if defined( _MSC_VER )
	(void)_InterlockedExchange( (long*)&a->value, value );
#elif defined( __GNUC__ ) || defined( __clang__ )
	__atomic_store_n( &a->value, value, __ATOMIC_SEQ_CST );
#else
#error "Unsupported platform"
#endif
}

static inline int b3AtomicLoadInt( b3AtomicInt* a )
{
#if defined( _MSC_VER ) && !defined( __clang__ )
	int value = __iso_volatile_load32( (volatile __int32*)&a->value );
#if defined( _M_ARM ) || defined( _M_ARM64 ) || defined( _M_ARM64EC )
	__dmb( 0xB );
#else
	_ReadWriteBarrier();
#endif
	return value;
#elif defined( __GNUC__ ) || defined( __clang__ )
	return __atomic_load_n( &a->value, __ATOMIC_SEQ_CST );
#else
#error "Unsupported platform"
#endif
}

static inline int b3AtomicFetchAddInt( b3AtomicInt* a, int increment )
{
#if defined( _MSC_VER )
	return _InterlockedExchangeAdd( (long*)&a->value, (long)increment );
#elif defined( __GNUC__ ) || defined( __clang__ )
	return __atomic_fetch_add( &a->value, increment, __ATOMIC_SEQ_CST );
#else
#error "Unsupported platform"
#endif
}

static inline bool b3AtomicCompareExchangeInt( b3AtomicInt* a, int expected, int desired )
{
#if defined( _MSC_VER )
	return _InterlockedCompareExchange( (long*)&a->value, (long)desired, (long)expected ) == expected;
#elif defined( __GNUC__ ) || defined( __clang__ )
	// The value written to expected is ignored
	return __atomic_compare_exchange_n( &a->value, &expected, desired, false, __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST );
#else
#error "Unsupported platform"
#endif
}

static inline void b3AtomicStoreU32( b3AtomicU32* a, uint32_t value )
{
#if defined( _MSC_VER )
	(void)_InterlockedExchange( (long*)&a->value, value );
#elif defined( __GNUC__ ) || defined( __clang__ )
	__atomic_store_n( &a->value, value, __ATOMIC_SEQ_CST );
#else
#error "Unsupported platform"
#endif
}

static inline uint32_t b3AtomicLoadU32( b3AtomicU32* a )
{
#if defined( _MSC_VER ) && !defined( __clang__ )
	uint32_t value = (uint32_t)__iso_volatile_load32( (volatile __int32*)&a->value );
#if defined( _M_ARM ) || defined( _M_ARM64 ) || defined( _M_ARM64EC )
	__dmb( 0xB );
#else
	_ReadWriteBarrier();
#endif
	return value;
#elif defined( __GNUC__ ) || defined( __clang__ )
	return __atomic_load_n( &a->value, __ATOMIC_SEQ_CST );
#else
#error "Unsupported platform"
#endif
}
