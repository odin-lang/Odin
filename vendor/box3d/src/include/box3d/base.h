// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

#include <stdbool.h>
#include <stdint.h>

// Compile-time options. Edit box3d/config.h, or define BOX3D_USER_CONFIG to
// point at your own copy.
#ifdef BOX3D_USER_CONFIG
#include BOX3D_USER_CONFIG
#endif
#include "config.h"

// clang-format off
// 
// Shared library macros
// Predefine BOX3D_EXPORT to reuse an existing export/import scheme, for example
// when compiling Box3D into another shared library.
#ifndef BOX3D_EXPORT
#if defined(_WIN32) && defined(box3d_EXPORTS)
	// build the Windows DLL
	#define BOX3D_EXPORT __declspec(dllexport)
#elif defined(_WIN32) && defined(BOX3D_DLL)
	// using the Windows DLL
	#define BOX3D_EXPORT __declspec(dllimport)
#elif defined(box3d_EXPORTS)
	// building or using the shared library
	#define BOX3D_EXPORT __attribute__((visibility("default")))
#else
	// static library
	#define BOX3D_EXPORT
#endif
#endif

// C++ macros
#ifdef __cplusplus
	#define B3_API extern "C" BOX3D_EXPORT
	#define B3_INLINE inline

#if defined( _MSC_VER )
	#define B3_FORCE_INLINE __forceinline
#elif defined( __GNUC__ ) || defined( __clang__ )
	#define B3_FORCE_INLINE inline __attribute__((always_inline))
#else
	#define B3_FORCE_INLINE inline
#endif

	#define B3_LITERAL(T) T
	#define B3_ZERO_INIT {}
#else
	#define B3_API BOX3D_EXPORT
	#define B3_INLINE static inline

#if defined( _MSC_VER )
	#define B3_FORCE_INLINE static __forceinline
#elif defined( __GNUC__ ) || defined( __clang__ )
	#define B3_FORCE_INLINE static inline __attribute__((always_inline))
#else
	#define B3_FORCE_INLINE static inline
#endif

/// Used for C literals like (b3Vec3){1.0f, 2.0f, 3.0f} where C++ requires b3Vec3{1.0f, 2.0f, 3.0f}
	#define B3_LITERAL(T) (T)
	#define B3_ZERO_INIT {0}
#endif
// clang-format on

#if defined( BOX3D_VALIDATE ) && !defined( NDEBUG )
#define B3_ENABLE_VALIDATION 1
#else
#define B3_ENABLE_VALIDATION 0
#endif

/**
 * @defgroup base Base
 * Base functionality
 * @{
 */

/// This is used to indicate null for interfaces that work with indices instead of pointers
#define B3_NULL_INDEX -1

/// Prototype for user allocation function.
///	@param size the allocation size in bytes
///	@param alignment the required alignment, guaranteed to be a power of 2
typedef void* b3AllocFcn( int32_t size, int32_t alignment );

/// Prototype for user free function.
///	@param mem the memory previously allocated through `b3AllocFcn`
typedef void b3FreeFcn( void* mem );

/// Prototype for the user assert callback. Return 0 to skip the debugger break.
typedef int b3AssertFcn( const char* condition, const char* fileName, int lineNumber );

/// Prototype for user log callback. Used to log warnings.
typedef void b3LogFcn( const char* message );

/// This allows the user to override the allocation functions. These should be
///	set during application startup.
B3_API void b3SetAllocator( b3AllocFcn* allocFcn, b3FreeFcn* freeFcn );

/// Total bytes allocated by Box3D
B3_API int b3GetByteCount( void );

/// Override the default assert callback.
///	@param assertFcn a non-null assert callback
B3_API void b3SetAssertFcn( b3AssertFcn* assertFcn );

/// see https://github.com/scottt/debugbreak
#if defined( _MSC_VER )
/// Break to the debugger
#define B3_BREAKPOINT __debugbreak()
#elif defined( __GNUC__ ) || defined( __clang__ )
#define B3_BREAKPOINT __builtin_trap()
#else
/// Unknown compiler
#include <assert.h>
#define B3_BREAKPOINT assert( 0 )
#endif

#if !defined( NDEBUG ) || defined( B3_ENABLE_ASSERT )
/// Internal assertion handler. Allows for host intervention.
B3_API int b3InternalAssert( const char* condition, const char* fileName, int lineNumber );
/// Assert that a condition is true.
#define B3_ASSERT( condition )                                                                                                  \
	( (void)( ( !!( condition ) ) || ( b3InternalAssert( #condition, __FILE__, (int)( __LINE__ ) ), 0 ) ) )
#else
#define B3_ASSERT( ... ) ( (void)0 )
#endif

#if B3_ENABLE_VALIDATION
/// Validation is typically only enabled in debug builds.
/// Floating point tolerance checks should use this instead of the regular assertion
#define B3_VALIDATE( condition ) B3_ASSERT( condition )
#else
/// Validation is typically only enabled in debug builds.
/// Floating point tolerance checks should use this instead of the regular assertion
#define B3_VALIDATE( ... ) ( (void)0 )
#endif

/// Override the default logging callback.
B3_API void b3SetLogFcn( b3LogFcn* logFcn );

/// Version numbering scheme.
/// See https://semver.org/
typedef struct b3Version
{
	/// Significant changes
	int major;

	/// Incremental changes
	int minor;

	/// Bug fixes
	int revision;
} b3Version;

/// Get the current version of Box3D
B3_API b3Version b3GetVersion( void );

/// @return true if the library was built with BOX3D_DOUBLE_PRECISION (large world mode)
B3_API bool b3IsDoublePrecision( void );

/**@}*/

//! @cond

/// Get the absolute number of system ticks. The value is platform specific.
B3_API uint64_t b3GetTicks( void );

/// Get the milliseconds passed from an initial tick value.
B3_API float b3GetMilliseconds( uint64_t ticks );

/// Get the milliseconds passed from an initial tick value.
B3_API float b3GetMillisecondsAndReset( uint64_t* ticks );

/// Yield to be used in a busy loop.
B3_API void b3Yield( void );

/// Sleep the current thread for a number of milliseconds.
B3_API void b3Sleep( int milliseconds );

// Simple djb2 hash function for determinism testing
#define B3_HASH_INIT 5381
B3_API uint32_t b3Hash( uint32_t hash, const uint8_t* data, int count );

//! @endcond
