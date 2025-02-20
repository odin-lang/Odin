/* gb.h - v0.33  - Ginger Bill's C Helper Library - public domain
                 - no warranty implied; use at your own risk

	This is a single header file with a bunch of useful stuff
	to replace the C/C++ standard library

	IMPORTANT NOTE: THIS IS A HEAVILY MODIFIED VERSION OF THE ORIGINAL
	DO NO REPLACE IT WITH THE ORIGINAL
*/


#ifndef GB_INCLUDE_GB_H
#define GB_INCLUDE_GB_H

#if defined(__cplusplus)
extern "C" {
#endif

#if defined(__cplusplus)
	#define GB_EXTERN extern "C"
#else
	#define GB_EXTERN extern
#endif

#if defined(_WIN32)
	#define GB_DLL_EXPORT GB_EXTERN __declspec(dllexport)
	#define GB_DLL_IMPORT GB_EXTERN __declspec(dllimport)
#else
	#define GB_DLL_EXPORT GB_EXTERN __attribute__((visibility("default")))
	#define GB_DLL_IMPORT GB_EXTERN
#endif

// NOTE(bill): Redefine for DLL, etc.
#ifndef GB_DEF
	#ifdef GB_STATIC
		#define GB_DEF static
	#else
		#define GB_DEF extern
	#endif
#endif

#if defined(_WIN64) || defined(__x86_64__) || defined(_M_X64) || defined(__64BIT__) || defined(__powerpc64__) || defined(__ppc64__) || defined(__aarch64__) || (defined(__riscv) && __riscv_xlen == 64)
	#ifndef GB_ARCH_64_BIT
	#define GB_ARCH_64_BIT 1
	#endif
#else
	// NOTE(bill): I'm only supporting 32 bit and 64 bit systems
	#ifndef GB_ARCH_32_BIT
	#define GB_ARCH_32_BIT 1
	#endif
#endif


#ifndef GB_ENDIAN_ORDER
#define GB_ENDIAN_ORDER
	// TODO(bill): Is the a good way or is it better to test for certain compilers and macros?
	#define GB_IS_BIG_ENDIAN    (!*(u8*)&(u16){1})
	#define GB_IS_LITTLE_ENDIAN (!GB_IS_BIG_ENDIAN)
#endif

#if defined(_WIN32) || defined(_WIN64)
	#ifndef GB_SYSTEM_WINDOWS
	#define GB_SYSTEM_WINDOWS 1
	#endif
#elif defined(__APPLE__) && defined(__MACH__)
	#ifndef GB_SYSTEM_OSX
	#define GB_SYSTEM_OSX 1
	#endif
#elif defined(__unix__)
	#ifndef GB_SYSTEM_UNIX
	#define GB_SYSTEM_UNIX 1
	#endif

	#if defined(__linux__)
		#ifndef GB_SYSTEM_LINUX
		#define GB_SYSTEM_LINUX 1
		#endif
	#elif defined(__FreeBSD__) || defined(__FreeBSD_kernel__)
		#ifndef GB_SYSTEM_FREEBSD
		#define GB_SYSTEM_FREEBSD 1
		#endif
	#elif defined(__OpenBSD__)
		#ifndef GB_SYSTEM_OPENBSD
		#define GB_SYSTEM_OPENBSD 1
		#endif
	#elif defined(__NetBSD__)
		#ifndef GB_SYSTEM_NETBSD
		#define GB_SYSTEM_NETBSD 1
		#endif
	#elif defined(__HAIKU__) || defined(__haiku__)
		#ifndef GB_SYSTEM_HAIKU
		#define GB_SYSTEM_HAIKU 1
		#endif
	#else
		#error This UNIX operating system is not supported
	#endif
#else
	#error This operating system is not supported
#endif

#if defined(GB_SYSTEM_UNIX)
#include <sys/wait.h>
#endif

#if defined(_MSC_VER)
	#define GB_COMPILER_MSVC 1
#elif defined(__GNUC__)
	#define GB_COMPILER_GCC 1
#elif defined(__clang__)
	#define GB_COMPILER_CLANG 1
#else
	#error Unknown compiler
#endif

#if defined(_M_IX86) || defined(_M_X64) || defined(__i386__) || defined(__x86_64__)
	#ifndef GB_CPU_X86
	#define GB_CPU_X86 1
	#endif
	#ifndef GB_CACHE_LINE_SIZE
	#define GB_CACHE_LINE_SIZE 64
	#endif

#elif defined(_M_PPC) || defined(__powerpc__) || defined(__powerpc64__)
	#ifndef GB_CPU_PPC
	#define GB_CPU_PPC 1
	#endif
	#ifndef GB_CACHE_LINE_SIZE
	#define GB_CACHE_LINE_SIZE 128
	#endif

#elif defined(__arm__) || defined(__aarch64__) || defined(_M_ARM) || defined(_M_ARM64)
	#ifndef GB_CPU_ARM
	#define GB_CPU_ARM 1
	#endif
	#ifndef GB_CACHE_LINE_SIZE
	#define GB_CACHE_LINE_SIZE 64
	#endif

#elif defined(__MIPSEL__) || defined(__mips_isa_rev)
	#ifndef GB_CPU_MIPS
	#define GB_CPU_MIPS 1
	#endif
	#ifndef GB_CACHE_LINE_SIZE
	#define GB_CACHE_LINE_SIZE 64
	#endif

#elif defined(__riscv)
	#ifndef GB_CPU_RISCV
	#define GB_CPU_RISCV 1
	#endif
	#ifndef GB_CACHE_LINE_SIZE
	#define GB_CACHE_LINE_SIZE 64
	#endif
#else
	#error Unknown CPU Type
#endif

#ifndef GB_STATIC_ASSERT
	#define GB_STATIC_ASSERT3(cond, msg) typedef char static_assertion_##msg[(!!(cond))*2-1]
	// NOTE(bill): Token pasting madness!!
	#define GB_STATIC_ASSERT2(cond, line) GB_STATIC_ASSERT3(cond, static_assertion_at_line_##line)
	#define GB_STATIC_ASSERT1(cond, line) GB_STATIC_ASSERT2(cond, line)
	#define GB_STATIC_ASSERT(cond)        GB_STATIC_ASSERT1(cond, __LINE__)
#endif


////////////////////////////////////////////////////////////////
//
// Headers
//
//

#if defined(_WIN32) && !defined(__MINGW32__)
	#ifndef _CRT_SECURE_NO_WARNINGS
	#define _CRT_SECURE_NO_WARNINGS
	#endif
#endif

#if defined(GB_SYSTEM_UNIX)
	#define _GNU_SOURCE
	#define _LARGEFILE64_SOURCE
#endif


// TODO(bill): How many of these headers do I really need?
// #include <stdarg.h>
#if !defined(GB_SYSTEM_WINDOWS)
	#include <stddef.h>
	#include <stdarg.h>
#endif



#if defined(GB_SYSTEM_WINDOWS)
	#if !defined(GB_NO_WINDOWS_H)
		#define NOMINMAX            1
		#if !defined(GB_WINDOWS_H_INCLUDED)
		#define WIN32_LEAN_AND_MEAN 1
		#define WIN32_MEAN_AND_LEAN 1
		#define VC_EXTRALEAN        1
		#endif
		#include <windows.h>
		#undef NOMINMAX
		#if !defined(GB_WINDOWS_H_INCLUDED)
		#undef WIN32_LEAN_AND_MEAN
		#undef WIN32_MEAN_AND_LEAN
		#undef VC_EXTRALEAN
		#endif
	#endif

	#include <intrin.h>
#else
	#include <dlfcn.h>
	#include <errno.h>
	#include <fcntl.h>
	#include <pthread.h>
	#ifndef _IOSC11_SOURCE
	#define _IOSC11_SOURCE
	#endif
	#include <stdlib.h> // NOTE(bill): malloc on linux
	#include <sys/mman.h>
	#if !defined(GB_SYSTEM_OSX) && !defined(__FreeBSD__) && !defined(__OpenBSD__) && !defined(__NetBSD__) && !defined(__HAIKU__)
		#include <sys/sendfile.h>
	#endif
	#include <sys/stat.h>
	#include <sys/time.h>
	#include <sys/types.h>
	#include <time.h>
	#include <unistd.h>

	#if defined(GB_CPU_X86)
		#include <xmmintrin.h>
	#endif
#endif

#if defined(GB_SYSTEM_OSX)
	#include <mach/mach.h>
	#include <mach/mach_init.h>
	#include <mach/mach_time.h>
	#include <mach/thread_act.h>
	#include <mach/thread_policy.h>
	#include <sys/sysctl.h>
	#include <copyfile.h>
	#include <mach/clock.h>
#endif

#if defined(GB_SYSTEM_FREEBSD)
	#include <sys/sysctl.h>
	#include <pthread_np.h>
	#include <sys/cpuset.h>
	#include <sys/types.h>
	#include <sys/socket.h>
	#include <sys/uio.h>
	#define lseek64 lseek
	#define sendfile(out, in, offset, count) sendfile(out, in, offset, count, NULL, NULL, 0)
#endif

#if defined(GB_SYSTEM_OPENBSD)
	#include <stdio.h>
	#include <pthread_np.h>
	#define lseek64 lseek
#endif

#if defined(GB_SYSTEM_NETBSD)
	#include <stdio.h>
	#include <lwp.h>
	#define lseek64 lseek
#endif

#if defined(GB_SYSTEM_HAIKU)
	#include <stdio.h>
	#include <pthread.h>
	#include <kernel/OS.h>
	#define lseek64 lseek
#endif
    
#if defined(GB_SYSTEM_UNIX)
	#include <semaphore.h>
#endif


////////////////////////////////////////////////////////////////
//
// Base Types
//
//

#if defined(GB_COMPILER_MSVC)
	#if _MSC_VER < 1300
	typedef unsigned char     u8;
	typedef   signed char     i8;
	typedef unsigned short   u16;
	typedef   signed short   i16;
	typedef unsigned int     u32;
	typedef   signed int     i32;
	#else
	typedef unsigned __int8   u8;
	typedef   signed __int8   i8;
	typedef unsigned __int16 u16;
	typedef   signed __int16 i16;
	typedef unsigned __int32 u32;
	typedef   signed __int32 i32;
	#endif
	typedef unsigned __int64 u64;
	typedef   signed __int64 i64;
#else
	#include <stdint.h>
	typedef uint8_t   u8;
	typedef  int8_t   i8;
	typedef uint16_t u16;
	typedef  int16_t i16;
	typedef uint32_t u32;
	typedef  int32_t i32;
	typedef uint64_t u64;
	typedef  int64_t i64;
#endif

GB_STATIC_ASSERT(sizeof(u8)  == sizeof(i8));
GB_STATIC_ASSERT(sizeof(u16) == sizeof(i16));
GB_STATIC_ASSERT(sizeof(u32) == sizeof(i32));
GB_STATIC_ASSERT(sizeof(u64) == sizeof(i64));

GB_STATIC_ASSERT(sizeof(u8)  == 1);
GB_STATIC_ASSERT(sizeof(u16) == 2);
GB_STATIC_ASSERT(sizeof(u32) == 4);
GB_STATIC_ASSERT(sizeof(u64) == 8);

typedef size_t    usize;
typedef ptrdiff_t isize;

GB_STATIC_ASSERT(sizeof(usize) == sizeof(isize));

// NOTE(bill): (u)intptr is only here for semantic reasons really as this library will only support 32/64 bit OSes.
// NOTE(bill): Are there any modern OSes (not 16 bit) where intptr != isize ?
#if defined(_WIN64)
	typedef signed   __int64  intptr;
	typedef unsigned __int64 uintptr;
#elif defined(_WIN32)
	// NOTE(bill); To mark types changing their size, e.g. intptr
	#ifndef _W64
		#if !defined(__midl) && (defined(_X86_) || defined(_M_IX86)) && _MSC_VER >= 1300
			#define _W64 __w64
		#else
			#define _W64
		#endif
	#endif

	typedef _W64   signed int  intptr;
	typedef _W64 unsigned int uintptr;
#else
	typedef uintptr_t uintptr;
	typedef  intptr_t  intptr;
#endif

GB_STATIC_ASSERT(sizeof(uintptr) == sizeof(intptr));

typedef float  f32;
typedef double f64;

GB_STATIC_ASSERT(sizeof(f32) == 4);
GB_STATIC_ASSERT(sizeof(f64) == 8);

typedef i32 Rune; // NOTE(bill): Unicode codepoint
#define GB_RUNE_INVALID cast(Rune)(0xfffd)
#define GB_RUNE_MAX     cast(Rune)(0x0010ffff)
#define GB_RUNE_BOM     cast(Rune)(0xfeff)
#define GB_RUNE_EOF     cast(Rune)(-1)


typedef i8  b8;
typedef i16 b16;
typedef i32 b32; // NOTE(bill): Prefer this!!!

// NOTE(bill): Get true and false
#if !defined(__cplusplus)
	#if (defined(_MSC_VER) && _MSC_VER < 1800) || (!defined(_MSC_VER) && !defined(__STDC_VERSION__))
		#ifndef true
		#define true  (0 == 0)
		#endif
		#ifndef false
		#define false (0 != 0)
		#endif
		typedef b8 bool;
	#else
		#include <stdbool.h>
	#endif
#endif

// NOTE(bill): These do are not prefixed with gb because the types are not.
#ifndef U8_MIN
#define U8_MIN 0u
#define U8_MAX 0xffu
#define I8_MIN (-0x7f - 1)
#define I8_MAX 0x7f

#define U16_MIN 0u
#define U16_MAX 0xffffu
#define I16_MIN (-0x7fff - 1)
#define I16_MAX 0x7fff

#define U32_MIN 0u
#define U32_MAX 0xffffffffu
#define I32_MIN (-0x7fffffff - 1)
#define I32_MAX 0x7fffffff

#define U64_MIN 0ull
#define U64_MAX 0xffffffffffffffffull
#define I64_MIN (-0x7fffffffffffffffll - 1)
#define I64_MAX 0x7fffffffffffffffll

#if defined(GB_ARCH_32_BIT)
	#define USIZE_MIX U32_MIN
	#define USIZE_MAX U32_MAX

	#define ISIZE_MIX I32_MIN
	#define ISIZE_MAX I32_MAX
#elif defined(GB_ARCH_64_BIT)
	#define USIZE_MIX U64_MIN
	#define USIZE_MAX U64_MAX

	#define ISIZE_MIX I64_MIN
	#define ISIZE_MAX I64_MAX
#else
	#error Unknown architecture size. This library only supports 32 bit and 64 bit architectures.
#endif

#define F32_MIN 1.17549435e-38f
#define F32_MAX 3.40282347e+38f

#define F64_MIN 2.2250738585072014e-308
#define F64_MAX 1.7976931348623157e+308

#endif

#ifndef NULL
	#if defined(__cplusplus)
		#if __cplusplus >= 201103L
			#define NULL nullptr
		#else
			#define NULL 0
		#endif
	#else
		#define NULL ((void *)0)
	#endif
#endif

// TODO(bill): Is this enough to get inline working?
#if !defined(__cplusplus)
	#if defined(_MSC_VER) && _MSC_VER <= 1800
	#define inline __inline
	#elif !defined(__STDC_VERSION__)
	#define inline __inline__
	#else
	#define inline
	#endif
#endif

#if !defined(gb_restrict)
	#if defined(_MSC_VER)
		#define gb_restrict __restrict
	#elif defined(__STDC_VERSION__)
		#define gb_restrict restrict
	#else
		#define gb_restrict
	#endif
#endif

// TODO(bill): Should force inline be a separate keyword and gb_inline be inline?
#if !defined(gb_inline)
	#if defined(_MSC_VER)
		#if _MSC_VER < 1300
		#define gb_inline
		#else
		#define gb_inline __forceinline
		#endif
	#else
		#define gb_inline inline __attribute__ ((__always_inline__))
	#endif
#endif

#if !defined(gb_no_inline)
	#if defined(_MSC_VER)
		#define gb_no_inline __declspec(noinline)
	#else
		#define gb_no_inline __attribute__ ((noinline))
	#endif
#endif


#if !defined(gb_thread_local)
	#if defined(_MSC_VER) && _MSC_VER >= 1300
		#define gb_thread_local __declspec(thread)
	#else
		#define gb_thread_local thread_local
	#endif
#endif

#if !defined(gb_no_asan)
	#if defined(_MSC_VER)
		#define gb_no_asan __declspec(no_sanitize_address)
	#else
		#define gb_no_asan __attribute__((disable_sanitizer_instrumentation))
	#endif
#endif

// NOTE(bill): Easy to grep
// NOTE(bill): Not needed in macros
#ifndef cast
#define cast(Type) (Type)
#endif

// NOTE(bill): Because a signed sizeof is more useful
#ifndef gb_size_of
#define gb_size_of(x) (isize)(sizeof(x))
#endif

#ifndef gb_count_of
#define gb_count_of(x) ((gb_size_of(x)/gb_size_of(0[x])) / ((isize)(!(gb_size_of(x) % gb_size_of(0[x])))))
#endif

#ifndef gb_offset_of
#define gb_offset_of(Type, element) ((isize)&(((Type *)0)->element))
#endif

#if defined(__cplusplus)
#ifndef gb_align_of
	#if __cplusplus >= 201103L
		#define gb_align_of(Type) (isize)alignof(Type)
	#else
extern "C++" {
		// NOTE(bill): Fucking Templates!
		template <typename T> struct gbAlignment_Trick { char c; T member; };
		#define gb_align_of(Type) gb_offset_of(gbAlignment_Trick<Type>, member)
}
	#endif
#endif
#else
	#ifndef gb_align_of
	#define gb_align_of(Type) gb_offset_of(struct { char c; Type member; }, member)
	#endif
#endif

// NOTE(bill): I do wish I had a type_of that was portable
#ifndef gb_swap
#define gb_swap(Type, a, b) do { Type tmp = (a); (a) = (b); (b) = tmp; } while (0)
#endif

// NOTE(bill): Because static means 3/4 different things in C/C++. Great design (!)
#ifndef gb_global
#define gb_global        static // Global variables
#define gb_internal      static // Internal linkage
#define gb_local_persist static // Local Persisting variables
#endif


#ifndef gb_unused
	#if defined(_MSC_VER)
		#define gb_unused(x) (__pragma(warning(suppress:4100))(x))
	#elif defined (__GCC__)
		#define gb_unused(x) __attribute__((__unused__))(x)
	#else
		#define gb_unused(x) ((void)(gb_size_of(x)))
	#endif
#endif




////////////////////////////////////////////////////////////////
//
// Defer statement
// Akin to D's SCOPE_EXIT or
// similar to Go's defer but scope-based
//
// NOTE: C++11 (and above) only!
//
#if !defined(GB_NO_DEFER) && defined(__cplusplus) && ((defined(_MSC_VER) && _MSC_VER >= 1400) || (__cplusplus >= 201103L))
extern "C++" {
	// NOTE(bill): Stupid fucking templates
	template <typename T> struct gbRemoveReference       { typedef T Type; };
	template <typename T> struct gbRemoveReference<T &>  { typedef T Type; };
	template <typename T> struct gbRemoveReference<T &&> { typedef T Type; };

	/// NOTE(bill): "Move" semantics - invented because the C++ committee are idiots (as a collective not as indiviuals (well a least some aren't))
	template <typename T> inline T &&gb_forward(typename gbRemoveReference<T>::Type &t)  { return static_cast<T &&>(t); }
	template <typename T> inline T &&gb_forward(typename gbRemoveReference<T>::Type &&t) { return static_cast<T &&>(t); }
	template <typename T> inline T &&gb_move   (T &&t)                                   { return static_cast<typename gbRemoveReference<T>::Type &&>(t); }
	template <typename F>
	struct gbprivDefer {
		F f;
		gbprivDefer(F &&f) : f(gb_forward<F>(f)) {}
		~gbprivDefer() { f(); }
	};
	template <typename F> gbprivDefer<F> gb__defer_func(F &&f) { return gbprivDefer<F>(gb_forward<F>(f)); }

	#define GB_DEFER_1(x, y) x##y
	#define GB_DEFER_2(x, y) GB_DEFER_1(x, y)
	#define GB_DEFER_3(x)    GB_DEFER_2(x, __COUNTER__)
	#define defer(code)      auto GB_DEFER_3(_defer_) = gb__defer_func([&]()->void{code;})
}

// Example
#if 0
	gbMutex m;
	gb_mutex_init(&m);
	{
		gb_mutex_lock(&m);
		defer (gb_mutex_unlock(&m));

		...
	}
#endif

#endif


////////////////////////////////////////////////////////////////
//
// Macro Fun!
//
//

#ifndef GB_JOIN_MACROS
#define GB_JOIN_MACROS
	#define GB_JOIN2_IND(a, b) a##b

	#define GB_JOIN2(a, b)       GB_JOIN2_IND(a, b)
	#define GB_JOIN3(a, b, c)    GB_JOIN2(GB_JOIN2(a, b), c)
	#define GB_JOIN4(a, b, c, d) GB_JOIN2(GB_JOIN2(GB_JOIN2(a, b), c), d)
#endif


#ifndef GB_BIT
#define GB_BIT(x) (1<<(x))
#endif

#ifndef gb_min
#define gb_min(a, b) ((a) < (b) ? (a) : (b))
#endif

#ifndef gb_max
#define gb_max(a, b) ((a) > (b) ? (a) : (b))
#endif

#ifndef gb_min3
#define gb_min3(a, b, c) gb_min(gb_min(a, b), c)
#endif

#ifndef gb_max3
#define gb_max3(a, b, c) gb_max(gb_max(a, b), c)
#endif

#ifndef gb_clamp
#define gb_clamp(x, lower, upper) gb_min(gb_max((x), (lower)), (upper))
#endif

#ifndef gb_clamp01
#define gb_clamp01(x) gb_clamp((x), 0, 1)
#endif

#ifndef gb_is_between
#define gb_is_between(x, lower, upper) (((lower) <= (x)) && ((x) <= (upper)))
#endif

#ifndef gb_abs
#define gb_abs(x) ((x) < 0 ? -(x) : (x))
#endif

/* NOTE(bill): Very useful bit setting */
#ifndef GB_MASK_SET
#define GB_MASK_SET(var, set, mask) do { \
	if (set) (var) |=  (mask); \
	else     (var) &= ~(mask); \
} while (0)
#endif


// NOTE(bill): Some compilers support applying printf-style warnings to user functions.
#if defined(__clang__) || defined(__GNUC__)
#define GB_PRINTF_ARGS(FMT) __attribute__((format(printf, FMT, (FMT+1))))
#else
#define GB_PRINTF_ARGS(FMT)
#endif

////////////////////////////////////////////////////////////////
//
// Debug
//
//


#ifndef GB_DEBUG_TRAP
	#if defined(_MSC_VER)
	 	#if _MSC_VER < 1300
		#define GB_DEBUG_TRAP() __asm int 3 /* Trap to debugger! */
		#else
		#define GB_DEBUG_TRAP() __debugbreak()
		#endif
	#else
		#define GB_DEBUG_TRAP() __builtin_trap()
	#endif
#endif

#ifndef GB_ASSERT_MSG
#define GB_ASSERT_MSG(cond, msg, ...) do { \
	if (!(cond)) { \
		gb_assert_handler("Assertion Failure", #cond, __FILE__, cast(i64)__LINE__, msg, ##__VA_ARGS__); \
		GB_DEBUG_TRAP(); \
	} \
} while (0)
#endif

#ifndef GB_ASSERT
#define GB_ASSERT(cond) GB_ASSERT_MSG(cond, NULL)
#endif

#ifndef GB_ASSERT_NOT_NULL
#define GB_ASSERT_NOT_NULL(ptr) GB_ASSERT_MSG((ptr) != NULL, #ptr " must not be NULL")
#endif

// NOTE(bill): Things that shouldn't happen with a message!
#ifndef GB_PANIC
#define GB_PANIC(msg, ...) do { \
	gb_assert_handler("Panic", NULL, __FILE__, cast(i64)__LINE__, msg, ##__VA_ARGS__); \
	GB_DEBUG_TRAP(); \
} while (0)
#endif

GB_DEF void gb_assert_handler(char const *prefix, char const *condition, char const *file, i32 line, char const *msg, ...);



////////////////////////////////////////////////////////////////
//
// Memory
//
//


GB_DEF b32 gb_is_power_of_two(isize x);

GB_DEF void *      gb_align_forward(void *ptr, isize alignment);

GB_DEF void *      gb_pointer_add      (void *ptr, isize bytes);
GB_DEF void *      gb_pointer_sub      (void *ptr, isize bytes);
GB_DEF void const *gb_pointer_add_const(void const *ptr, isize bytes);
GB_DEF void const *gb_pointer_sub_const(void const *ptr, isize bytes);
GB_DEF isize       gb_pointer_diff     (void const *begin, void const *end);


GB_DEF void gb_zero_size(void *ptr, isize size);
#ifndef     gb_zero_item
#define     gb_zero_item(t)         gb_zero_size((t), gb_size_of(*(t))) // NOTE(bill): Pass pointer of struct
#define     gb_zero_array(a, count) gb_zero_size((a), gb_size_of(*(a))*count)
#endif

GB_DEF void *      gb_memcopy   (void *dest, void const *source, isize size);
GB_DEF void *      gb_memmove   (void *dest, void const *source, isize size);
GB_DEF void *      gb_memset    (void *data, u8 byte_value, isize size);
GB_DEF i32         gb_memcompare(void const *s1, void const *s2, isize size);
GB_DEF void        gb_memswap   (void *i, void *j, isize size);
GB_DEF void const *gb_memchr    (void const *data, u8 byte_value, isize size);
GB_DEF void const *gb_memrchr   (void const *data, u8 byte_value, isize size);


#ifndef gb_memcopy_array
#define gb_memcopy_array(dst, src, count) gb_memcopy((dst), (src), gb_size_of(*(dst))*(count))
#endif

#ifndef gb_memmove_array
#define gb_memmove_array(dst, src, count) gb_memmove((dst), (src), gb_size_of(*(dst))*(count))
#endif

// NOTE(bill): Very similar to doing `*cast(T *)(&u)`
#ifndef GB_BIT_CAST
#define GB_BIT_CAST(dest, source) do { \
	GB_STATIC_ASSERT(gb_size_of(*(dest)) <= gb_size_of(source)); \
	gb_memcopy((dest), &(source), gb_size_of(*dest)); \
} while (0)
#endif




#ifndef gb_kilobytes
#define gb_kilobytes(x) (            (x) * (i64)(1024))
#define gb_megabytes(x) (gb_kilobytes(x) * (i64)(1024))
#define gb_gigabytes(x) (gb_megabytes(x) * (i64)(1024))
#define gb_terabytes(x) (gb_gigabytes(x) * (i64)(1024))
#endif



// Fences
GB_DEF u32 gb_thread_current_id(void);

#if defined(GB_SYSTEM_WINDOWS)

typedef struct gbAffinity {
	b32   is_accurate;
	isize core_count;
	isize thread_count;
	#define GB_WIN32_MAX_THREADS (8 * gb_size_of(usize))
	usize core_masks[GB_WIN32_MAX_THREADS];

} gbAffinity;

#elif defined(GB_SYSTEM_OSX)
typedef struct gbAffinity {
	b32   is_accurate;
	isize core_count;
	isize thread_count;
	isize threads_per_core;
} gbAffinity;

#elif defined(GB_SYSTEM_LINUX)
typedef struct gbAffinity {
	b32   is_accurate;
	isize core_count;
	isize thread_count;
	isize threads_per_core;
} gbAffinity;
#elif defined(GB_SYSTEM_FREEBSD)
typedef struct gbAffinity {
	b32 is_accurate;
	isize core_count;
	isize thread_count;
	isize threads_per_core;
} gbAffinity;
#elif defined(GB_SYSTEM_OPENBSD)
typedef struct gbAffinity {
	b32   is_accurate;
	isize core_count;
	isize thread_count;
	isize threads_per_core;
} gbAffinity;
#elif defined(GB_SYSTEM_NETBSD)
typedef struct gbAffinity {
	b32 is_accurate;
	isize core_count;
	isize thread_count;
	isize threads_per_core;
} gbAffinity;
#elif defined(GB_SYSTEM_HAIKU)
typedef struct gbAffinity {
	b32   is_accurate;
	isize core_count;
	isize thread_count;
	isize threads_per_core;
} gbAffinity;
#else
#error TODO(bill): Unknown system
#endif

GB_DEF void  gb_affinity_init   (gbAffinity *a);
GB_DEF void  gb_affinity_destroy(gbAffinity *a);
GB_DEF b32   gb_affinity_set    (gbAffinity *a, isize core, isize thread);
GB_DEF isize gb_affinity_thread_count_for_core(gbAffinity *a, isize core);





////////////////////////////////////////////////////////////////
//
// Custom Allocation
//
//

typedef enum gbAllocationType {
	gbAllocation_Alloc,
	gbAllocation_Free,
	gbAllocation_FreeAll,
	gbAllocation_Resize,
} gbAllocationType;

// NOTE(bill): This is useful so you can define an allocator of the same type and parameters
#define GB_ALLOCATOR_PROC(name)                         \
void *name(void *allocator_data, gbAllocationType type, \
           isize size, isize alignment,                 \
           void *old_memory, isize old_size,            \
           u64 flags)
typedef GB_ALLOCATOR_PROC(gbAllocatorProc);

typedef struct gbAllocator {
	gbAllocatorProc *proc;
	void *           data;
} gbAllocator;

typedef enum gbAllocatorFlag {
	gbAllocatorFlag_ClearToZero = GB_BIT(0),
} gbAllocatorFlag;

// TODO(bill): Is this a decent default alignment?
#ifndef GB_DEFAULT_MEMORY_ALIGNMENT
#define GB_DEFAULT_MEMORY_ALIGNMENT (2 * gb_size_of(void *))
#endif

#ifndef GB_DEFAULT_ALLOCATOR_FLAGS
#define GB_DEFAULT_ALLOCATOR_FLAGS (gbAllocatorFlag_ClearToZero)
#endif

GB_DEF void *gb_alloc_align (gbAllocator a, isize size, isize alignment);
GB_DEF void *gb_alloc       (gbAllocator a, isize size);
GB_DEF void  gb_free        (gbAllocator a, void *ptr);
GB_DEF void  gb_free_all    (gbAllocator a);
GB_DEF void *gb_resize      (gbAllocator a, void *ptr, isize old_size, isize new_size);
GB_DEF void *gb_resize_align(gbAllocator a, void *ptr, isize old_size, isize new_size, isize alignment);
// TODO(bill): For gb_resize, should the use need to pass the old_size or only the new_size?

GB_DEF void *gb_alloc_copy      (gbAllocator a, void const *src, isize size);
GB_DEF void *gb_alloc_copy_align(gbAllocator a, void const *src, isize size, isize alignment);
GB_DEF char *gb_alloc_str       (gbAllocator a, char const *str);
GB_DEF char *gb_alloc_str_len   (gbAllocator a, char const *str, isize len);


// NOTE(bill): These are very useful and the type cast has saved me from numerous bugs
#ifndef gb_alloc_item
#define gb_alloc_item(allocator_, Type)         (Type *)gb_alloc(allocator_, gb_size_of(Type))
#define gb_alloc_array(allocator_, Type, count) (Type *)gb_alloc(allocator_, gb_size_of(Type) * (count))
#endif

// NOTE(bill): Use this if you don't need a "fancy" resize allocation
GB_DEF void *gb_default_resize_align(gbAllocator a, void *ptr, isize old_size, isize new_size, isize alignment);



// TODO(bill): Probably use a custom heap allocator system that doesn't depend on malloc/free
// Base it off TCMalloc or something else? Or something entirely custom?
GB_DEF gbAllocator gb_heap_allocator(void);

// NOTE(bill): Yep, I use my own allocator system!
#ifndef gb_malloc
#define gb_malloc(sz) gb_alloc(gb_heap_allocator(), sz)
#define gb_mfree(ptr) gb_free(gb_heap_allocator(), ptr)
#endif



// TODO(bill): Find better way of doing this without #if #elif etc.
#if defined(GB_ARCH_32_BIT)
#define GB_ISIZE_HIGH_BIT 0x80000000
#elif defined(GB_ARCH_64_BIT)
#define GB_ISIZE_HIGH_BIT 0x8000000000000000ll
#else
#error
#endif


////////////////////////////////////////////////////////////////
//
// Sort & Search
//
//

#define GB_COMPARE_PROC(name) int name(void const *a, void const *b)
typedef GB_COMPARE_PROC(gbCompareProc);

#define GB_COMPARE_PROC_PTR(def) GB_COMPARE_PROC((*def))

// Producure pointers
// NOTE(bill): The offset parameter specifies the offset in the structure
// e.g. gb_i32_cmp(gb_offset_of(Thing, value))
// Use 0 if it's just the type instead.

GB_DEF GB_COMPARE_PROC_PTR(gb_i16_cmp  (isize offset));
GB_DEF GB_COMPARE_PROC_PTR(gb_i32_cmp  (isize offset));
GB_DEF GB_COMPARE_PROC_PTR(gb_i64_cmp  (isize offset));
GB_DEF GB_COMPARE_PROC_PTR(gb_isize_cmp(isize offset));
GB_DEF GB_COMPARE_PROC_PTR(gb_str_cmp  (isize offset));
GB_DEF GB_COMPARE_PROC_PTR(gb_f32_cmp  (isize offset));
GB_DEF GB_COMPARE_PROC_PTR(gb_f64_cmp  (isize offset));
GB_DEF GB_COMPARE_PROC_PTR(gb_char_cmp (isize offset));

// TODO(bill): Better sorting algorithms
// NOTE(bill): Uses quick sort for large arrays but insertion sort for small
#define gb_sort_array(array, count, compare_proc) gb_sort(array, count, gb_size_of(*(array)), compare_proc)
GB_DEF void gb_sort(void *base, isize count, isize size, gbCompareProc compare_proc);

// NOTE(bill): the count of temp == count of items
#define gb_radix_sort(Type) gb_radix_sort_##Type
#define GB_RADIX_SORT_PROC(Type) void gb_radix_sort(Type)(Type *items, Type *temp, isize count)

GB_DEF GB_RADIX_SORT_PROC(u8);
GB_DEF GB_RADIX_SORT_PROC(u16);
GB_DEF GB_RADIX_SORT_PROC(u32);
GB_DEF GB_RADIX_SORT_PROC(u64);


// NOTE(bill): Returns index or -1 if not found
#define gb_binary_search_array(array, count, key, compare_proc) gb_binary_search(array, count, gb_size_of(*(array)), key, compare_proc)
GB_DEF isize gb_binary_search(void const *base, isize count, isize size, void const *key, gbCompareProc compare_proc);

#define gb_reverse_array(array, count) gb_reverse(array, count, gb_size_of(*(array)))
GB_DEF void gb_reverse(void *base, isize count, isize size);

////////////////////////////////////////////////////////////////
//
// Char Functions
//
//

GB_DEF char gb_char_to_lower       (char c);
GB_DEF char gb_char_to_upper       (char c);
GB_DEF b32  gb_char_is_space       (char c);
GB_DEF b32  gb_char_is_digit       (char c);
GB_DEF b32  gb_char_is_hex_digit   (char c);
GB_DEF b32  gb_char_is_alpha       (char c);
GB_DEF b32  gb_char_is_alphanumeric(char c);
GB_DEF i32  gb_digit_to_int        (char c);
GB_DEF i32  gb_hex_digit_to_int    (char c);

// NOTE(bill): ASCII only
GB_DEF void gb_str_to_lower(char *str);
GB_DEF void gb_str_to_upper(char *str);

GB_DEF isize gb_strlen (char const *str);
GB_DEF isize gb_strnlen(char const *str, isize max_len);
GB_DEF i32   gb_strcmp (char const *s1, char const *s2);
GB_DEF i32   gb_strncmp(char const *s1, char const *s2, isize len);
GB_DEF char *gb_strcpy (char *dest, char const *source);
GB_DEF char *gb_strncpy(char *dest, char const *source, isize len);
GB_DEF isize gb_strlcpy(char *dest, char const *source, isize len);
GB_DEF char *gb_strrev (char *str); // NOTE(bill): ASCII only

// NOTE(bill): A less fucking crazy strtok!
GB_DEF char const *gb_strtok(char *output, char const *src, char const *delimit);

GB_DEF b32 gb_str_has_prefix(char const *str, char const *prefix);
GB_DEF b32 gb_str_has_suffix(char const *str, char const *suffix);

GB_DEF char const *gb_char_first_occurence(char const *str, char c);
GB_DEF char const *gb_char_last_occurence (char const *str, char c);

GB_DEF void gb_str_concat(char *dest, isize dest_len,
                          char const *src_a, isize src_a_len,
                          char const *src_b, isize src_b_len);

GB_DEF u64   gb_str_to_u64(char const *str, char **end_ptr, i32 base); // TODO(bill): Support more than just decimal and hexadecimal
GB_DEF i64   gb_str_to_i64(char const *str, char **end_ptr, i32 base); // TODO(bill): Support more than just decimal and hexadecimal
GB_DEF f32   gb_str_to_f32(char const *str, char **end_ptr);
GB_DEF f64   gb_str_to_f64(char const *str, char **end_ptr);
GB_DEF void  gb_i64_to_str(i64 value, char *string, i32 base);
GB_DEF void  gb_u64_to_str(u64 value, char *string, i32 base);


////////////////////////////////////////////////////////////////
//
// UTF-8 Handling
//
//

// NOTE(bill): Does not check if utf-8 string is valid
GB_DEF isize gb_utf8_strlen (u8 const *str);
GB_DEF isize gb_utf8_strnlen(u8 const *str, isize max_len);

// NOTE(bill): Windows doesn't handle 8 bit filenames well ('cause Micro$hit)
GB_DEF u16 *gb_utf8_to_ucs2    (u16 *buffer, isize len, u8 const *str);
GB_DEF u8 * gb_ucs2_to_utf8    (u8 *buffer, isize len, u16 const *str);
GB_DEF u16 *gb_utf8_to_ucs2_buf(u8 const *str);   // NOTE(bill): Uses locally persisting buffer
GB_DEF u8 * gb_ucs2_to_utf8_buf(u16 const *str); // NOTE(bill): Uses locally persisting buffer

// NOTE(bill): Returns size of codepoint in bytes
GB_DEF isize gb_utf8_decode        (u8 const *str, isize str_len, Rune *codepoint);
GB_DEF isize gb_utf8_codepoint_size(u8 const *str, isize str_len);
GB_DEF isize gb_utf8_encode_rune   (u8 buf[4], Rune r);

////////////////////////////////////////////////////////////////
//
// gbString - C Read-Only-Compatible
//
//
/*
Reasoning:

	By default, strings in C are null terminated which means you have to count
	the number of character up to the null character to calculate the length.
	Many "better" C string libraries will create a struct for a string.
	i.e.

	    struct String {
	    	Allocator allocator;
	        size_t    length;
	        size_t    capacity;
	        char *    cstring;
	    };

	This library tries to augment normal C strings in a better way that is still
	compatible with C-style strings.

	+--------+-----------------------+-----------------+
	| Header | Binary C-style String | Null Terminator |
	+--------+-----------------------+-----------------+
	         |
	         +-> Pointer returned by functions

	Due to the meta-data being stored before the string pointer and every gb string
	having an implicit null terminator, gb strings are full compatible with c-style
	strings and read-only functions.

Advantages:

    * gb strings can be passed to C-style string functions without accessing a struct
      member of calling a function, i.e.

          gb_printf("%s\n", gb_str);

      Many other libraries do either of these:

          gb_printf("%s\n", string->cstr);
          gb_printf("%s\n", get_cstring(string));

    * You can access each character just like a C-style string:

          gb_printf("%c %c\n", str[0], str[13]);

    * gb strings are singularly allocated. The meta-data is next to the character
      array which is better for the cache.

Disadvantages:

    * In the C version of these functions, many return the new string. i.e.
          str = gb_string_appendc(str, "another string");
      This could be changed to gb_string_appendc(&str, "another string"); but I'm still not sure.

	* This is incompatible with "gb_string.h" strings
*/

#if 0
#define GB_IMPLEMENTATION
#include "gb.h"
int main(int argc, char **argv) {
	gbString str = gb_string_make("Hello");
	gbString other_str = gb_string_make_length(", ", 2);
	str = gb_string_append(str, other_str);
	str = gb_string_appendc(str, "world!");

	gb_printf("%s\n", str); // Hello, world!

	gb_printf("str length = %d\n", gb_string_length(str));

	str = gb_string_set(str, "Potato soup");
	gb_printf("%s\n", str); // Potato soup

	str = gb_string_set(str, "Hello");
	other_str = gb_string_set(other_str, "Pizza");
	if (gb_strings_are_equal(str, other_str))
		gb_printf("Not called\n");
	else
		gb_printf("Called\n");

	str = gb_string_set(str, "Ab.;!...AHello World       ??");
	str = gb_string_trim(str, "Ab.;!. ?");
	gb_printf("%s\n", str); // "Hello World"

	gb_string_free(str);
	gb_string_free(other_str);

	return 0;
}
#endif

// TODO(bill): Should this be a wrapper to gbArray(char) or this extra type safety better?
typedef char *gbString;

// NOTE(bill): If you only need a small string, just use a standard c string or change the size from isize to u16, etc.
typedef struct gbStringHeader {
	gbAllocator allocator;
	isize       length;
	isize       capacity;
} gbStringHeader;

#define GB_STRING_HEADER(str) (cast(gbStringHeader *)(str) - 1)

GB_DEF gbString gb_string_make_reserve   (gbAllocator a, isize capacity);
GB_DEF gbString gb_string_make           (gbAllocator a, char const *str);
GB_DEF gbString gb_string_make_length    (gbAllocator a, void const *str, isize num_bytes);
GB_DEF void     gb_string_free           (gbString str);
GB_DEF gbString gb_string_duplicate      (gbAllocator a, gbString const str);
GB_DEF isize    gb_string_length         (gbString const str);
GB_DEF isize    gb_string_capacity       (gbString const str);
GB_DEF isize    gb_string_available_space(gbString const str);
GB_DEF void     gb_string_clear          (gbString str);
GB_DEF gbString gb_string_append         (gbString str, gbString const other);
GB_DEF gbString gb_string_append_length  (gbString str, void const *other, isize num_bytes);
GB_DEF gbString gb_string_appendc        (gbString str, char const *other);
GB_DEF gbString gb_string_append_rune    (gbString str, Rune r);
GB_DEF gbString gb_string_append_fmt     (gbString str, char const *fmt, ...);
GB_DEF gbString gb_string_set            (gbString str, char const *cstr);
GB_DEF gbString gb_string_make_space_for (gbString str, isize add_len);
GB_DEF isize    gb_string_allocation_size(gbString const str);
GB_DEF b32      gb_string_are_equal      (gbString const lhs, gbString const rhs);
GB_DEF gbString gb_string_trim           (gbString str, char const *cut_set);
GB_DEF gbString gb_string_trim_space     (gbString str); // Whitespace ` \t\r\n\v\f`





////////////////////////////////////////////////////////////////
//
// Hashing and Checksum Functions
//
//

GB_EXTERN u32 gb_adler32(void const *data, isize len);

GB_EXTERN u32 gb_crc32(void const *data, isize len);
GB_EXTERN u64 gb_crc64(void const *data, isize len);

GB_EXTERN u32 gb_fnv32 (void const *data, isize len);
GB_EXTERN u64 gb_fnv64 (void const *data, isize len);
GB_EXTERN u32 gb_fnv32a(void const *data, isize len);
GB_EXTERN u64 gb_fnv64a(void const *data, isize len);

// NOTE(bill): Default seed of 0x9747b28c
// NOTE(bill): I prefer using murmur64 for most hashes
GB_EXTERN u32 gb_murmur32(void const *data, isize len);
GB_EXTERN u64 gb_murmur64(void const *data, isize len);

GB_EXTERN u32 gb_murmur32_seed(void const *data, isize len, u32 seed);
GB_EXTERN u64 gb_murmur64_seed(void const *data, isize len, u64 seed);


////////////////////////////////////////////////////////////////
//
// File Handling
//


typedef u32 gbFileMode;
typedef enum gbFileModeFlag {
	gbFileMode_Read       = GB_BIT(0),
	gbFileMode_Write      = GB_BIT(1),
	gbFileMode_Append     = GB_BIT(2),
	gbFileMode_Rw         = GB_BIT(3),

	gbFileMode_Modes = gbFileMode_Read | gbFileMode_Write | gbFileMode_Append | gbFileMode_Rw,
} gbFileModeFlag;

// NOTE(bill): Only used internally and for the file operations
typedef enum gbSeekWhenceType {
	gbSeekWhence_Begin   = 0,
	gbSeekWhence_Current = 1,
	gbSeekWhence_End     = 2,
} gbSeekWhenceType;

typedef enum gbFileError {
	gbFileError_None,
	gbFileError_Invalid,
	gbFileError_InvalidFilename,
	gbFileError_Exists,
	gbFileError_NotExists,
	gbFileError_Permission,
	gbFileError_TruncationFailure,
} gbFileError;

typedef union gbFileDescriptor {
	void *  p;
	intptr  i;
	uintptr u;
} gbFileDescriptor;

typedef struct gbFileOperations gbFileOperations;

#define GB_FILE_OPEN_PROC(name)     gbFileError name(gbFileDescriptor *fd, gbFileOperations *ops, gbFileMode mode, char const *filename)
#define GB_FILE_READ_AT_PROC(name)  b32         name(gbFileDescriptor fd, void *buffer, isize size, i64 offset, isize *bytes_read)
#define GB_FILE_WRITE_AT_PROC(name) b32         name(gbFileDescriptor fd, void const *buffer, isize size, i64 offset, isize *bytes_written)
#define GB_FILE_SEEK_PROC(name)     b32         name(gbFileDescriptor fd, i64 offset, gbSeekWhenceType whence, i64 *new_offset)
#define GB_FILE_CLOSE_PROC(name)    void        name(gbFileDescriptor fd)
typedef GB_FILE_OPEN_PROC(gbFileOpenProc);
typedef GB_FILE_READ_AT_PROC(gbFileReadProc);
typedef GB_FILE_WRITE_AT_PROC(gbFileWriteProc);
typedef GB_FILE_SEEK_PROC(gbFileSeekProc);
typedef GB_FILE_CLOSE_PROC(gbFileCloseProc);

struct gbFileOperations {
	gbFileReadProc  *read_at;
	gbFileWriteProc *write_at;
	gbFileSeekProc  *seek;
	gbFileCloseProc *close;
};

extern gbFileOperations const gbDefaultFileOperations;


// typedef struct gbDirInfo {
// 	u8 *buf;
// 	isize buf_count;
// 	isize buf_pos;
// } gbDirInfo;

typedef u64 gbFileTime;

typedef struct gbFile {
	gbFileOperations ops;
	gbFileDescriptor fd;
	char const *     filename;
	gbFileTime       last_write_time;
	// gbDirInfo *   dir_info; // TODO(bill): Get directory info
} gbFile;

// TODO(bill): gbAsyncFile

typedef enum gbFileStandardType {
	gbFileStandard_Input,
	gbFileStandard_Output,
	gbFileStandard_Error,

	gbFileStandard_Count,
} gbFileStandardType;

GB_DEF gbFile *gb_file_get_standard(gbFileStandardType std);

GB_DEF gbFileError gb_file_create        (gbFile *file, char const *filename);
GB_DEF gbFileError gb_file_open          (gbFile *file, char const *filename);
GB_DEF gbFileError gb_file_open_mode     (gbFile *file, gbFileMode mode, char const *filename);
GB_DEF gbFileError gb_file_new           (gbFile *file, gbFileDescriptor fd, gbFileOperations ops, char const *filename);
GB_DEF b32         gb_file_read_at_check (gbFile *file, void *buffer, isize size, i64 offset, isize *bytes_read);
GB_DEF b32         gb_file_write_at_check(gbFile *file, void const *buffer, isize size, i64 offset, isize *bytes_written);
GB_DEF b32         gb_file_read_at       (gbFile *file, void *buffer, isize size, i64 offset);
GB_DEF b32         gb_file_write_at      (gbFile *file, void const *buffer, isize size, i64 offset);
GB_DEF i64         gb_file_seek          (gbFile *file, i64 offset);
GB_DEF i64         gb_file_seek_to_end   (gbFile *file);
GB_DEF i64         gb_file_skip          (gbFile *file, i64 bytes); // NOTE(bill): Skips a certain amount of bytes
GB_DEF i64         gb_file_tell          (gbFile *file);
GB_DEF gbFileError gb_file_close         (gbFile *file);
GB_DEF b32         gb_file_read          (gbFile *file, void *buffer, isize size);
GB_DEF b32         gb_file_write         (gbFile *file, void const *buffer, isize size);
GB_DEF i64         gb_file_size          (gbFile *file);
GB_DEF char const *gb_file_name          (gbFile *file);
GB_DEF gbFileError gb_file_truncate      (gbFile *file, i64 size);
GB_DEF b32         gb_file_has_changed   (gbFile *file); // NOTE(bill): Changed since lasted checked
// TODO(bill):
// gbFileError gb_file_temp(gbFile *file);
//

typedef struct gbFileContents {
	gbAllocator allocator;
	void *      data;
	isize       size;
} gbFileContents;


GB_DEF gbFileContents gb_file_read_contents(gbAllocator a, b32 zero_terminate, char const *filepath);
GB_DEF void           gb_file_free_contents(gbFileContents *fc);


// TODO(bill): Should these have different names as they do not take in a gbFile * ???
GB_DEF b32        gb_file_exists         (char const *filepath);
GB_DEF gbFileTime gb_file_last_write_time(char const *filepath);
GB_DEF b32        gb_file_copy           (char const *existing_filename, char const *new_filename, b32 fail_if_exists);
GB_DEF b32        gb_file_move           (char const *existing_filename, char const *new_filename);
GB_DEF b32        gb_file_remove         (char const *filename);


#ifndef GB_PATH_SEPARATOR
	#if defined(GB_SYSTEM_WINDOWS)
		#define GB_PATH_SEPARATOR '\\'
	#else
		#define GB_PATH_SEPARATOR '/'
	#endif
#endif

GB_DEF b32         gb_path_is_absolute  (char const *path);
GB_DEF b32         gb_path_is_relative  (char const *path);
GB_DEF b32         gb_path_is_root      (char const *path);
GB_DEF char const *gb_path_base_name    (char const *path);
GB_DEF char const *gb_path_extension    (char const *path);
GB_DEF char *      gb_path_get_full_name(gbAllocator a, char const *path);


////////////////////////////////////////////////////////////////
//
// Printing
//
//

GB_DEF isize gb_printf        (char const *fmt, ...) GB_PRINTF_ARGS(1);
GB_DEF isize gb_printf_va     (char const *fmt, va_list va);
GB_DEF isize gb_printf_err    (char const *fmt, ...) GB_PRINTF_ARGS(1);
GB_DEF isize gb_printf_err_va (char const *fmt, va_list va);
GB_DEF isize gb_fprintf       (gbFile *f, char const *fmt, ...) GB_PRINTF_ARGS(2);
GB_DEF isize gb_fprintf_va    (gbFile *f, char const *fmt, va_list va);

GB_DEF char *gb_bprintf    (char const *fmt, ...) GB_PRINTF_ARGS(1); // NOTE(bill): A locally persisting buffer is used internally
GB_DEF char *gb_bprintf_va (char const *fmt, va_list va);            // NOTE(bill): A locally persisting buffer is used internally
GB_DEF isize gb_snprintf   (char *str, isize n, char const *fmt, ...) GB_PRINTF_ARGS(3);
GB_DEF isize gb_snprintf_va(char *str, isize n, char const *fmt, va_list va);


////////////////////////////////////////////////////////////////
//
// Time
//
//

GB_DEF u64  gb_rdtsc       (void);
GB_DEF f64  gb_time_now    (void); // NOTE(bill): This is only for relative time e.g. game loops
GB_DEF u64  gb_utc_time_now(void); // NOTE(bill): Number of microseconds since 1601-01-01 UTC
GB_DEF void gb_sleep_ms    (u32 ms);



GB_DEF void gb_exit(u32 code);
GB_DEF char const *gb_get_env  (char const *name, gbAllocator allocator);
GB_DEF void gb_set_env  (char const *name, char const *value);
GB_DEF void gb_unset_env(char const *name);

GB_DEF u16 gb_endian_swap16(u16 i);
GB_DEF u32 gb_endian_swap32(u32 i);
GB_DEF u64 gb_endian_swap64(u64 i);

GB_DEF isize gb_count_set_bits(u64 mask);

#if defined(__cplusplus)
}
#endif

#endif // GB_INCLUDE_GB_H






////////////////////////////////////////////////////////////////
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
// Implementation
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
// It's turtles all the way down!
////////////////////////////////////////////////////////////////
#if defined(GB_IMPLEMENTATION) && !defined(GB_IMPLEMENTATION_DONE)
#define GB_IMPLEMENTATION_DONE

#if defined(__cplusplus)
extern "C" {
#endif


#if defined(GB_COMPILER_MSVC) && !defined(_WINDOWS_)
	////////////////////////////////////////////////////////////////
	//
	// Bill's Mini Windows.h
	//
	//

	#define WINAPI   __stdcall
	#define WINAPIV  __cdecl
	#define CALLBACK __stdcall
	#define MAX_PATH 260
	#define CCHDEVICENAME 32
	#define CCHFORMNAME   32

	typedef unsigned long DWORD;
	typedef int WINBOOL;
	#ifndef XFree86Server
		#ifndef __OBJC__
		typedef WINBOOL BOOL;
		#else
		#define BOOL WINBOOL
		#endif
	typedef unsigned char BYTE;
	#endif
	typedef unsigned short WORD;
	typedef float FLOAT;
	typedef int INT;
	typedef unsigned int UINT;
	typedef short SHORT;
	typedef long LONG;
	typedef long long LONGLONG;
	typedef unsigned short USHORT;
	typedef unsigned long ULONG;
	typedef unsigned long long ULONGLONG;

	typedef UINT WPARAM;
	typedef LONG LPARAM;
	typedef LONG LRESULT;
	#ifndef _HRESULT_DEFINED
	typedef LONG HRESULT;
	#define _HRESULT_DEFINED
	#endif
	#ifndef XFree86Server
	typedef WORD ATOM;
	#endif /* XFree86Server */
	typedef void *HANDLE;
	typedef HANDLE HGLOBAL;
	typedef HANDLE HLOCAL;
	typedef HANDLE GLOBALHANDLE;
	typedef HANDLE LOCALHANDLE;
	typedef void *HGDIOBJ;

	#define DECLARE_HANDLE(name) typedef HANDLE name
	DECLARE_HANDLE(HACCEL);
	DECLARE_HANDLE(HBITMAP);
	DECLARE_HANDLE(HBRUSH);
	DECLARE_HANDLE(HCOLORSPACE);
	DECLARE_HANDLE(HDC);
	DECLARE_HANDLE(HGLRC);
	DECLARE_HANDLE(HDESK);
	DECLARE_HANDLE(HENHMETAFILE);
	DECLARE_HANDLE(HFONT);
	DECLARE_HANDLE(HICON);
	DECLARE_HANDLE(HKEY);
	typedef HKEY *PHKEY;
	DECLARE_HANDLE(HMENU);
	DECLARE_HANDLE(HMETAFILE);
	DECLARE_HANDLE(HINSTANCE);
	typedef HINSTANCE HMODULE;
	DECLARE_HANDLE(HPALETTE);
	DECLARE_HANDLE(HPEN);
	DECLARE_HANDLE(HRGN);
	DECLARE_HANDLE(HRSRC);
	DECLARE_HANDLE(HSTR);
	DECLARE_HANDLE(HTASK);
	DECLARE_HANDLE(HWND);
	DECLARE_HANDLE(HWINSTA);
	DECLARE_HANDLE(HKL);
	DECLARE_HANDLE(HRAWINPUT);
	DECLARE_HANDLE(HMONITOR);
	#undef DECLARE_HANDLE

	typedef int HFILE;
	typedef HICON HCURSOR;
	typedef DWORD COLORREF;
	typedef int (WINAPI *FARPROC)();
	typedef int (WINAPI *NEARPROC)();
	typedef int (WINAPI *PROC)();
	typedef LRESULT (CALLBACK *WNDPROC)(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

	#if defined(_WIN64)
	typedef unsigned __int64 ULONG_PTR;
	typedef signed __int64 LONG_PTR;
	#else
	typedef unsigned long ULONG_PTR;
	typedef signed long LONG_PTR;
	#endif
	typedef ULONG_PTR DWORD_PTR;

	typedef struct tagRECT {
		LONG left;
		LONG top;
		LONG right;
		LONG bottom;
	} RECT;
	typedef struct tagRECTL {
		LONG left;
		LONG top;
		LONG right;
		LONG bottom;
	} RECTL;
	typedef struct tagPOINT {
		LONG x;
		LONG y;
	} POINT;
	typedef struct tagSIZE {
		LONG cx;
		LONG cy;
	} SIZE;
	typedef struct tagPOINTS {
		SHORT x;
		SHORT y;
	} POINTS;
	typedef struct _SECURITY_ATTRIBUTES {
		DWORD  nLength;
		HANDLE lpSecurityDescriptor;
		BOOL   bInheritHandle;
	} SECURITY_ATTRIBUTES;
	typedef enum _LOGICAL_PROCESSOR_RELATIONSHIP {
		RelationProcessorCore,
		RelationNumaNode,
		RelationCache,
		RelationProcessorPackage,
		RelationGroup,
		RelationAll               = 0xffff
	} LOGICAL_PROCESSOR_RELATIONSHIP;
	typedef enum _PROCESSOR_CACHE_TYPE {
		CacheUnified,
		CacheInstruction,
		CacheData,
		CacheTrace
	} PROCESSOR_CACHE_TYPE;
	typedef struct _CACHE_DESCRIPTOR {
		BYTE                 Level;
		BYTE                 Associativity;
		WORD                 LineSize;
		DWORD                Size;
		PROCESSOR_CACHE_TYPE Type;
	} CACHE_DESCRIPTOR;
	typedef struct _SYSTEM_LOGICAL_PROCESSOR_INFORMATION {
		ULONG_PTR                       ProcessorMask;
		LOGICAL_PROCESSOR_RELATIONSHIP Relationship;
		union {
			struct {
				BYTE Flags;
			} ProcessorCore;
			struct {
				DWORD NodeNumber;
			} NumaNode;
			CACHE_DESCRIPTOR Cache;
			ULONGLONG        Reserved[2];
		};
	} SYSTEM_LOGICAL_PROCESSOR_INFORMATION;
	typedef struct _MEMORY_BASIC_INFORMATION {
		void *BaseAddress;
		void *AllocationBase;
		DWORD AllocationProtect;
		usize RegionSize;
		DWORD State;
		DWORD Protect;
		DWORD Type;
	} MEMORY_BASIC_INFORMATION;
	typedef struct _SYSTEM_INFO {
		union {
			DWORD   dwOemId;
			struct {
				WORD wProcessorArchitecture;
				WORD wReserved;
			};
		};
		DWORD     dwPageSize;
		void *    lpMinimumApplicationAddress;
		void *    lpMaximumApplicationAddress;
		DWORD_PTR dwActiveProcessorMask;
		DWORD     dwNumberOfProcessors;
		DWORD     dwProcessorType;
		DWORD     dwAllocationGranularity;
		WORD      wProcessorLevel;
		WORD      wProcessorRevision;
	} SYSTEM_INFO;
	typedef union _LARGE_INTEGER {
		struct {
			DWORD LowPart;
			LONG  HighPart;
		};
		struct {
			DWORD LowPart;
			LONG  HighPart;
		} u;
		LONGLONG QuadPart;
	} LARGE_INTEGER;
	typedef union _ULARGE_INTEGER {
		struct {
			DWORD LowPart;
			DWORD HighPart;
		};
		struct {
			DWORD LowPart;
			DWORD HighPart;
		} u;
		ULONGLONG QuadPart;
	} ULARGE_INTEGER;

	typedef struct _OVERLAPPED {
		ULONG_PTR Internal;
		ULONG_PTR InternalHigh;
		union {
			struct {
				DWORD Offset;
				DWORD OffsetHigh;
			};
			void *Pointer;
		};
		HANDLE hEvent;
	} OVERLAPPED;
	typedef struct _FILETIME {
		DWORD dwLowDateTime;
		DWORD dwHighDateTime;
	} FILETIME;
	typedef struct _WIN32_FIND_DATAW {
		DWORD    dwFileAttributes;
		FILETIME ftCreationTime;
		FILETIME ftLastAccessTime;
		FILETIME ftLastWriteTime;
		DWORD    nFileSizeHigh;
		DWORD    nFileSizeLow;
		DWORD    dwReserved0;
		DWORD    dwReserved1;
		wchar_t  cFileName[MAX_PATH];
		wchar_t  cAlternateFileName[14];
	} WIN32_FIND_DATAW;
	typedef struct _WIN32_FILE_ATTRIBUTE_DATA {
		DWORD    dwFileAttributes;
		FILETIME ftCreationTime;
		FILETIME ftLastAccessTime;
		FILETIME ftLastWriteTime;
		DWORD    nFileSizeHigh;
		DWORD    nFileSizeLow;
	} WIN32_FILE_ATTRIBUTE_DATA;
	typedef enum _GET_FILEEX_INFO_LEVELS {
		GetFileExInfoStandard,
		GetFileExMaxInfoLevel
	} GET_FILEEX_INFO_LEVELS;
	typedef struct tagRAWINPUTHEADER {
		DWORD  dwType;
		DWORD  dwSize;
		HANDLE hDevice;
		WPARAM wParam;
	} RAWINPUTHEADER;
	typedef struct tagRAWINPUTDEVICE {
		USHORT usUsagePage;
		USHORT usUsage;
		DWORD  dwFlags;
		HWND   hwndTarget;
	} RAWINPUTDEVICE;
	typedef struct tagRAWMOUSE {
		WORD usFlags;
		union {
			ULONG ulButtons;
			struct {
				WORD usButtonFlags;
				WORD usButtonData;
			};
		};
		ULONG ulRawButtons;
		LONG  lLastX;
		LONG  lLastY;
		ULONG ulExtraInformation;
	} RAWMOUSE;
	typedef struct tagRAWKEYBOARD {
		WORD  MakeCode;
		WORD  Flags;
		WORD  Reserved;
		WORD  VKey;
		UINT  Message;
		ULONG ExtraInformation;
	} RAWKEYBOARD;
	typedef struct tagRAWHID {
		DWORD dwSizeHid;
		DWORD dwCount;
		BYTE  bRawData[1];
	} RAWHID;
	typedef struct tagRAWINPUT {
		RAWINPUTHEADER header;
		union {
			RAWMOUSE    mouse;
			RAWKEYBOARD keyboard;
			RAWHID      hid;
		} data;
	} RAWINPUT;
	typedef struct tagWNDCLASSEXW {
		UINT           cbSize;
		UINT           style;
		WNDPROC        lpfnWndProc;
		INT            cbClsExtra;
		INT            cbWndExtra;
		HINSTANCE      hInstance;
		HICON          hIcon;
		HCURSOR        hCursor;
		HANDLE         hbrBackground;
		wchar_t const *lpszMenuName;
		wchar_t const *lpszClassName;
		HICON          hIconSm;
	} WNDCLASSEXW;
	typedef struct _POINTL {
		LONG x;
		LONG y;
	} POINTL;
	typedef struct _devicemodew {
		wchar_t dmDeviceName[CCHDEVICENAME];
		WORD    dmSpecVersion;
		WORD    dmDriverVersion;
		WORD    dmSize;
		WORD    dmDriverExtra;
		DWORD   dmFields;
		union {
			struct {
				short dmOrientation;
				short dmPaperSize;
				short dmPaperLength;
				short dmPaperWidth;
				short dmScale;
				short dmCopies;
				short dmDefaultSource;
				short dmPrintQuality;
			};
			struct {
				POINTL dmPosition;
				DWORD  dmDisplayOrientation;
				DWORD  dmDisplayFixedOutput;
			};
		};
		short   dmColor;
		short   dmDuplex;
		short   dmYResolution;
		short   dmTTOption;
		short   dmCollate;
		wchar_t dmFormName[CCHFORMNAME];
		WORD    dmLogPixels;
		DWORD   dmBitsPerPel;
		DWORD   dmPelsWidth;
		DWORD   dmPelsHeight;
		union {
			DWORD dmDisplayFlags;
			DWORD dmNup;
		};
		DWORD dmDisplayFrequency;
	#if (WINVER >= 0x0400)
		DWORD dmICMMethod;
		DWORD dmICMIntent;
		DWORD dmMediaType;
		DWORD dmDitherType;
		DWORD dmReserved1;
		DWORD dmReserved2;
	#if (WINVER >= 0x0500) || (_WIN32_WINNT >= 0x0400)
		DWORD dmPanningWidth;
		DWORD dmPanningHeight;
	#endif
	#endif
	} DEVMODEW;
	typedef struct tagPIXELFORMATDESCRIPTOR {
		WORD  nSize;
		WORD  nVersion;
		DWORD dwFlags;
		BYTE  iPixelType;
		BYTE  cColorBits;
		BYTE  cRedBits;
		BYTE  cRedShift;
		BYTE  cGreenBits;
		BYTE  cGreenShift;
		BYTE  cBlueBits;
		BYTE  cBlueShift;
		BYTE  cAlphaBits;
		BYTE  cAlphaShift;
		BYTE  cAccumBits;
		BYTE  cAccumRedBits;
		BYTE  cAccumGreenBits;
		BYTE  cAccumBlueBits;
		BYTE  cAccumAlphaBits;
		BYTE  cDepthBits;
		BYTE  cStencilBits;
		BYTE  cAuxBuffers;
		BYTE  iLayerType;
		BYTE  bReserved;
		DWORD dwLayerMask;
		DWORD dwVisibleMask;
		DWORD dwDamageMask;
	} PIXELFORMATDESCRIPTOR;
	typedef struct tagMSG {     // msg
		HWND   hwnd;
		UINT   message;
		WPARAM wParam;
		LPARAM lParam;
		DWORD time;
		POINT pt;
	} MSG;
	typedef struct tagWINDOWPLACEMENT {
		UINT length;
		UINT flags;
		UINT showCmd;
		POINT ptMinPosition;
		POINT ptMaxPosition;
		RECT rcNormalPosition;
	} WINDOWPLACEMENT;
	typedef struct tagMONITORINFO {
		DWORD cbSize;
		RECT  rcMonitor;
		RECT  rcWork;
		DWORD dwFlags;
	} MONITORINFO;

	#define INFINITE 0xffffffffl
	#define INVALID_HANDLE_VALUE ((void *)(intptr)(-1))


	typedef DWORD WINAPI THREAD_START_ROUTINE(void *parameter);

	GB_DLL_IMPORT DWORD   WINAPI GetLastError       (void);
	GB_DLL_IMPORT BOOL    WINAPI CloseHandle        (HANDLE object);
	GB_DLL_IMPORT HANDLE  WINAPI CreateSemaphoreA   (SECURITY_ATTRIBUTES *semaphore_attributes, LONG initial_count,
	                                                 LONG maximum_count, char const *name);
	GB_DLL_IMPORT BOOL    WINAPI ReleaseSemaphore   (HANDLE semaphore, LONG release_count, LONG *previous_count);
	GB_DLL_IMPORT DWORD   WINAPI WaitForSingleObject(HANDLE handle, DWORD milliseconds);
	GB_DLL_IMPORT HANDLE  WINAPI CreateThread       (SECURITY_ATTRIBUTES *semaphore_attributes, usize stack_size,
	                                                 THREAD_START_ROUTINE *start_address, void *parameter,
	                                                 DWORD creation_flags, DWORD *thread_id);
	GB_DLL_IMPORT DWORD   WINAPI GetThreadId        (HANDLE handle);
	GB_DLL_IMPORT void    WINAPI RaiseException     (DWORD, DWORD, DWORD, ULONG_PTR const *);


	GB_DLL_IMPORT BOOL      WINAPI GetLogicalProcessorInformation(SYSTEM_LOGICAL_PROCESSOR_INFORMATION *buffer, DWORD *return_length);
	GB_DLL_IMPORT DWORD_PTR WINAPI SetThreadAffinityMask(HANDLE thread, DWORD_PTR check_mask);
	GB_DLL_IMPORT HANDLE    WINAPI GetCurrentThread(void);

	#define PAGE_NOACCESS          0x01
	#define PAGE_READONLY          0x02
	#define PAGE_READWRITE         0x04
	#define PAGE_WRITECOPY         0x08
	#define PAGE_EXECUTE           0x10
	#define PAGE_EXECUTE_READ      0x20
	#define PAGE_EXECUTE_READWRITE 0x40
	#define PAGE_EXECUTE_WRITECOPY 0x80
	#define PAGE_GUARD            0x100
	#define PAGE_NOCACHE          0x200
	#define PAGE_WRITECOMBINE     0x400

	#define MEM_COMMIT           0x1000
	#define MEM_RESERVE          0x2000
	#define MEM_DECOMMIT         0x4000
	#define MEM_RELEASE          0x8000
	#define MEM_FREE            0x10000
	#define MEM_PRIVATE         0x20000
	#define MEM_MAPPED          0x40000
	#define MEM_RESET           0x80000
	#define MEM_TOP_DOWN       0x100000
	#define MEM_LARGE_PAGES  0x20000000
	#define MEM_4MB_PAGES    0x80000000




	GB_DLL_IMPORT void * WINAPI VirtualAlloc (void *addr, usize size, DWORD allocation_type, DWORD protect);
	GB_DLL_IMPORT usize  WINAPI VirtualQuery (void const *address, MEMORY_BASIC_INFORMATION *buffer, usize length);
	GB_DLL_IMPORT BOOL   WINAPI VirtualFree  (void *address, usize size, DWORD free_type);
	GB_DLL_IMPORT void   WINAPI GetSystemInfo(SYSTEM_INFO *system_info);


	#ifndef VK_UNKNOWN
	#define VK_UNKNOWN 0
	#define VK_LBUTTON  0x01
	#define VK_RBUTTON  0x02
	#define VK_CANCEL   0x03
	#define VK_MBUTTON  0x04
	#define VK_XBUTTON1 0x05
	#define VK_XBUTTON2 0x06
	#define VK_BACK 0x08
	#define VK_TAB 0x09
	#define VK_CLEAR 0x0C
	#define VK_RETURN 0x0D
	#define VK_SHIFT 0x10
	#define VK_CONTROL 0x11 // CTRL key
	#define VK_MENU 0x12 // ALT key
	#define VK_PAUSE 0x13 // PAUSE key
	#define VK_CAPITAL 0x14 // CAPS LOCK key
	#define VK_KANA 0x15 // Input Method Editor (IME) Kana mode
	#define VK_HANGUL 0x15 // IME Hangul mode
	#define VK_JUNJA 0x17 // IME Junja mode
	#define VK_FINAL 0x18 // IME final mode
	#define VK_HANJA 0x19 // IME Hanja mode
	#define VK_KANJI 0x19 // IME Kanji mode
	#define VK_ESCAPE 0x1B // ESC key
	#define VK_CONVERT 0x1C // IME convert
	#define VK_NONCONVERT 0x1D // IME nonconvert
	#define VK_ACCEPT 0x1E // IME accept
	#define VK_MODECHANGE 0x1F // IME mode change request
	#define VK_SPACE 0x20 // SPACE key
	#define VK_PRIOR 0x21 // PAGE UP key
	#define VK_NEXT 0x22 // PAGE DOWN key
	#define VK_END 0x23 // END key
	#define VK_HOME 0x24 // HOME key
	#define VK_LEFT 0x25 // LEFT ARROW key
	#define VK_UP 0x26 // UP ARROW key
	#define VK_RIGHT 0x27 // RIGHT ARROW key
	#define VK_DOWN 0x28 // DOWN ARROW key
	#define VK_SELECT 0x29 // SELECT key
	#define VK_PRINT 0x2A // PRINT key
	#define VK_EXECUTE 0x2B // EXECUTE key
	#define VK_SNAPSHOT 0x2C // PRINT SCREEN key
	#define VK_INSERT 0x2D // INS key
	#define VK_DELETE 0x2E // DEL key
	#define VK_HELP 0x2F // HELP key
	#define VK_0 0x30
	#define VK_1 0x31
	#define VK_2 0x32
	#define VK_3 0x33
	#define VK_4 0x34
	#define VK_5 0x35
	#define VK_6 0x36
	#define VK_7 0x37
	#define VK_8 0x38
	#define VK_9 0x39
	#define VK_A 0x41
	#define VK_B 0x42
	#define VK_C 0x43
	#define VK_D 0x44
	#define VK_E 0x45
	#define VK_F 0x46
	#define VK_G 0x47
	#define VK_H 0x48
	#define VK_I 0x49
	#define VK_J 0x4A
	#define VK_K 0x4B
	#define VK_L 0x4C
	#define VK_M 0x4D
	#define VK_N 0x4E
	#define VK_O 0x4F
	#define VK_P 0x50
	#define VK_Q 0x51
	#define VK_R 0x52
	#define VK_S 0x53
	#define VK_T 0x54
	#define VK_U 0x55
	#define VK_V 0x56
	#define VK_W 0x57
	#define VK_X 0x58
	#define VK_Y 0x59
	#define VK_Z 0x5A
	#define VK_LWIN 0x5B // Left Windows key (Microsoft Natural keyboard)
	#define VK_RWIN 0x5C // Right Windows key (Natural keyboard)
	#define VK_APPS 0x5D // Applications key (Natural keyboard)
	#define VK_SLEEP 0x5F // Computer Sleep key
	// Num pad keys
	#define VK_NUMPAD0 0x60
	#define VK_NUMPAD1 0x61
	#define VK_NUMPAD2 0x62
	#define VK_NUMPAD3 0x63
	#define VK_NUMPAD4 0x64
	#define VK_NUMPAD5 0x65
	#define VK_NUMPAD6 0x66
	#define VK_NUMPAD7 0x67
	#define VK_NUMPAD8 0x68
	#define VK_NUMPAD9 0x69
	#define VK_MULTIPLY 0x6A
	#define VK_ADD 0x6B
	#define VK_SEPARATOR 0x6C
	#define VK_SUBTRACT 0x6D
	#define VK_DECIMAL 0x6E
	#define VK_DIVIDE 0x6F
	#define VK_F1 0x70
	#define VK_F2 0x71
	#define VK_F3 0x72
	#define VK_F4 0x73
	#define VK_F5 0x74
	#define VK_F6 0x75
	#define VK_F7 0x76
	#define VK_F8 0x77
	#define VK_F9 0x78
	#define VK_F10 0x79
	#define VK_F11 0x7A
	#define VK_F12 0x7B
	#define VK_F13 0x7C
	#define VK_F14 0x7D
	#define VK_F15 0x7E
	#define VK_F16 0x7F
	#define VK_F17 0x80
	#define VK_F18 0x81
	#define VK_F19 0x82
	#define VK_F20 0x83
	#define VK_F21 0x84
	#define VK_F22 0x85
	#define VK_F23 0x86
	#define VK_F24 0x87
	#define VK_NUMLOCK 0x90
	#define VK_SCROLL 0x91
	#define VK_LSHIFT 0xA0
	#define VK_RSHIFT 0xA1
	#define VK_LCONTROL 0xA2
	#define VK_RCONTROL 0xA3
	#define VK_LMENU 0xA4
	#define VK_RMENU 0xA5
	#define VK_BROWSER_BACK 0xA6 // Windows 2000/XP: Browser Back key
	#define VK_BROWSER_FORWARD 0xA7 // Windows 2000/XP: Browser Forward key
	#define VK_BROWSER_REFRESH 0xA8 // Windows 2000/XP: Browser Refresh key
	#define VK_BROWSER_STOP 0xA9 // Windows 2000/XP: Browser Stop key
	#define VK_BROWSER_SEARCH 0xAA // Windows 2000/XP: Browser Search key
	#define VK_BROWSER_FAVORITES 0xAB // Windows 2000/XP: Browser Favorites key
	#define VK_BROWSER_HOME 0xAC // Windows 2000/XP: Browser Start and Home key
	#define VK_VOLUME_MUTE 0xAD // Windows 2000/XP: Volume Mute key
	#define VK_VOLUME_DOWN 0xAE // Windows 2000/XP: Volume Down key
	#define VK_VOLUME_UP 0xAF // Windows 2000/XP: Volume Up key
	#define VK_MEDIA_NEXT_TRACK 0xB0 // Windows 2000/XP: Next Track key
	#define VK_MEDIA_PREV_TRACK 0xB1 // Windows 2000/XP: Previous Track key
	#define VK_MEDIA_STOP 0xB2 // Windows 2000/XP: Stop Media key
	#define VK_MEDIA_PLAY_PAUSE 0xB3 // Windows 2000/XP: Play/Pause Media key
	#define VK_MEDIA_LAUNCH_MAIL 0xB4 // Windows 2000/XP: Start Mail key
	#define VK_MEDIA_LAUNCH_MEDIA_SELECT 0xB5 // Windows 2000/XP: Select Media key
	#define VK_MEDIA_LAUNCH_APP1 0xB6 // VK_LAUNCH_APP1 (B6) Windows 2000/XP: Start Application 1 key
	#define VK_MEDIA_LAUNCH_APP2 0xB7 // VK_LAUNCH_APP2 (B7) Windows 2000/XP: Start Application 2 key
	#define VK_OEM_1 0xBA
	#define VK_OEM_PLUS 0xBB
	#define VK_OEM_COMMA 0xBC
	#define VK_OEM_MINUS 0xBD
	#define VK_OEM_PERIOD 0xBE
	#define VK_OEM_2 0xBF
	#define VK_OEM_3 0xC0
	#define VK_OEM_4 0xDB
	#define VK_OEM_5 0xDC
	#define VK_OEM_6 0xDD
	#define VK_OEM_7 0xDE
	#define VK_OEM_8 0xDF
	#define VK_OEM_102 0xE2
	#define VK_PROCESSKEY 0xE5
	#define VK_PACKET 0xE7
	#define VK_ATTN 0xF6 // Attn key
	#define VK_CRSEL 0xF7 // CrSel key
	#define VK_EXSEL 0xF8 // ExSel key
	#define VK_EREOF 0xF9 // Erase EOF key
	#define VK_PLAY 0xFA // Play key
	#define VK_ZOOM 0xFB // Zoom key
	#define VK_NONAME 0xFC // Reserved for future use
	#define VK_PA1 0xFD // VK_PA1 (FD) PA1 key
	#define VK_OEM_CLEAR 0xFE // Clear key
	#endif // VK_UNKNOWN



	#define GENERIC_READ             0x80000000
	#define GENERIC_WRITE            0x40000000
	#define GENERIC_EXECUTE          0x20000000
	#define GENERIC_ALL              0x10000000
	#define FILE_SHARE_READ          0x00000001
	#define FILE_SHARE_WRITE         0x00000002
	#define FILE_SHARE_DELETE        0x00000004
	#define CREATE_NEW               1
	#define CREATE_ALWAYS            2
	#define OPEN_EXISTING            3
	#define OPEN_ALWAYS              4
	#define TRUNCATE_EXISTING        5
	#define FILE_ATTRIBUTE_READONLY  0x00000001
	#define FILE_ATTRIBUTE_NORMAL    0x00000080
	#define FILE_ATTRIBUTE_TEMPORARY 0x00000100
	#define ERROR_FILE_NOT_FOUND     2l
	#define ERROR_ACCESS_DENIED      5L
	#define ERROR_NO_MORE_FILES      18l
	#define ERROR_FILE_EXISTS        80l
	#define ERROR_ALREADY_EXISTS     183l
	#define STD_INPUT_HANDLE         ((DWORD)-10)
	#define STD_OUTPUT_HANDLE        ((DWORD)-11)
	#define STD_ERROR_HANDLE         ((DWORD)-12)

	GB_DLL_IMPORT int           MultiByteToWideChar(UINT code_page, DWORD flags, char const *   multi_byte_str, int multi_byte_len, wchar_t const *wide_char_str,  int wide_char_len);
	GB_DLL_IMPORT int           WideCharToMultiByte(UINT code_page, DWORD flags, wchar_t const *wide_char_str,  int wide_char_len, char const *    multi_byte_str, int multi_byte_len);
	GB_DLL_IMPORT BOOL   WINAPI SetFilePointerEx(HANDLE file, LARGE_INTEGER distance_to_move,
	                                             LARGE_INTEGER *new_file_pointer, DWORD move_method);
	GB_DLL_IMPORT BOOL   WINAPI ReadFile        (HANDLE file, void *buffer, DWORD bytes_to_read, DWORD *bytes_read, OVERLAPPED *overlapped);
	GB_DLL_IMPORT BOOL   WINAPI WriteFile       (HANDLE file, void const *buffer, DWORD bytes_to_write, DWORD *bytes_written, OVERLAPPED *overlapped);
	GB_DLL_IMPORT HANDLE WINAPI CreateFileW     (wchar_t const *path, DWORD desired_access, DWORD share_mode,
	                                             SECURITY_ATTRIBUTES *, DWORD creation_disposition,
	                                             DWORD flags_and_attributes, HANDLE template_file);
	GB_DLL_IMPORT HANDLE WINAPI GetStdHandle    (DWORD std_handle);
	GB_DLL_IMPORT BOOL   WINAPI GetFileSizeEx   (HANDLE file, LARGE_INTEGER *size);
	GB_DLL_IMPORT BOOL   WINAPI SetEndOfFile    (HANDLE file);
	GB_DLL_IMPORT HANDLE WINAPI FindFirstFileW  (wchar_t const *path, WIN32_FIND_DATAW *data);
	GB_DLL_IMPORT BOOL   WINAPI FindClose       (HANDLE find_file);
	GB_DLL_IMPORT BOOL   WINAPI GetFileAttributesExW(wchar_t const *path, GET_FILEEX_INFO_LEVELS info_level_id, WIN32_FILE_ATTRIBUTE_DATA *data);
	GB_DLL_IMPORT BOOL   WINAPI CopyFileW(wchar_t const *old_f, wchar_t const *new_f, BOOL fail_if_exists);
	GB_DLL_IMPORT BOOL   WINAPI MoveFileW(wchar_t const *old_f, wchar_t const *new_f);

	GB_DLL_IMPORT HMODULE WINAPI LoadLibraryA  (char const *filename);
	GB_DLL_IMPORT BOOL    WINAPI FreeLibrary   (HMODULE module);
	GB_DLL_IMPORT FARPROC WINAPI GetProcAddress(HMODULE module, char const *name);

	GB_DLL_IMPORT BOOL WINAPI QueryPerformanceFrequency(LARGE_INTEGER *frequency);
	GB_DLL_IMPORT BOOL WINAPI QueryPerformanceCounter  (LARGE_INTEGER *counter);
	GB_DLL_IMPORT void WINAPI GetSystemTimeAsFileTime  (FILETIME *system_time_as_file_time);
	GB_DLL_IMPORT void WINAPI Sleep(DWORD milliseconds);
	GB_DLL_IMPORT void WINAPI ExitProcess(UINT exit_code);

	GB_DLL_IMPORT BOOL WINAPI SetEnvironmentVariableA(char const *name, char const *value);


	#define WM_NULL                   0x0000
	#define WM_CREATE                 0x0001
	#define WM_DESTROY                0x0002
	#define WM_MOVE                   0x0003
	#define WM_SIZE                   0x0005
	#define WM_ACTIVATE               0x0006
	#define WM_SETFOCUS               0x0007
	#define WM_KILLFOCUS              0x0008
	#define WM_ENABLE                 0x000A
	#define WM_SETREDRAW              0x000B
	#define WM_SETTEXT                0x000C
	#define WM_GETTEXT                0x000D
	#define WM_GETTEXTLENGTH          0x000E
	#define WM_PAINT                  0x000F
	#define WM_CLOSE                  0x0010
	#define WM_QUERYENDSESSION        0x0011
	#define WM_QUERYOPEN              0x0013
	#define WM_ENDSESSION             0x0016
	#define WM_QUIT                   0x0012
	#define WM_ERASEBKGND             0x0014
	#define WM_SYSCOLORCHANGE         0x0015
	#define WM_SHOWWINDOW             0x0018
	#define WM_WININICHANGE           0x001A
	#define WM_SETTINGCHANGE          WM_WININICHANGE
	#define WM_DEVMODECHANGE          0x001B
	#define WM_ACTIVATEAPP            0x001C
	#define WM_FONTCHANGE             0x001D
	#define WM_TIMECHANGE             0x001E
	#define WM_CANCELMODE             0x001F
	#define WM_SETCURSOR              0x0020
	#define WM_MOUSEACTIVATE          0x0021
	#define WM_CHILDACTIVATE          0x0022
	#define WM_QUEUESYNC              0x0023
	#define WM_GETMINMAXINFO          0x0024
	#define WM_PAINTICON              0x0026
	#define WM_ICONERASEBKGND         0x0027
	#define WM_NEXTDLGCTL             0x0028
	#define WM_SPOOLERSTATUS          0x002A
	#define WM_DRAWITEM               0x002B
	#define WM_MEASUREITEM            0x002C
	#define WM_DELETEITEM             0x002D
	#define WM_VKEYTOITEM             0x002E
	#define WM_CHARTOITEM             0x002F
	#define WM_SETFONT                0x0030
	#define WM_GETFONT                0x0031
	#define WM_SETHOTKEY              0x0032
	#define WM_GETHOTKEY              0x0033
	#define WM_QUERYDRAGICON          0x0037
	#define WM_COMPAREITEM            0x0039
	#define WM_GETOBJECT              0x003D
	#define WM_COMPACTING             0x0041
	#define WM_COMMNOTIFY             0x0044  /* no longer suported */
	#define WM_WINDOWPOSCHANGING      0x0046
	#define WM_WINDOWPOSCHANGED       0x0047
	#define WM_POWER                  0x0048
	#define WM_COPYDATA               0x004A
	#define WM_CANCELJOURNAL          0x004B
	#define WM_NOTIFY                 0x004E
	#define WM_INPUTLANGCHANGEREQUEST 0x0050
	#define WM_INPUTLANGCHANGE        0x0051
	#define WM_TCARD                  0x0052
	#define WM_HELP                   0x0053
	#define WM_USERCHANGED            0x0054
	#define WM_NOTIFYFORMAT           0x0055
	#define WM_CONTEXTMENU            0x007B
	#define WM_STYLECHANGING          0x007C
	#define WM_STYLECHANGED           0x007D
	#define WM_DISPLAYCHANGE          0x007E
	#define WM_GETICON                0x007F
	#define WM_SETICON                0x0080
	#define WM_INPUT                  0x00FF
	#define WM_KEYFIRST               0x0100
	#define WM_KEYDOWN                0x0100
	#define WM_KEYUP                  0x0101
	#define WM_CHAR                   0x0102
	#define WM_DEADCHAR               0x0103
	#define WM_SYSKEYDOWN             0x0104
	#define WM_SYSKEYUP               0x0105
	#define WM_SYSCHAR                0x0106
	#define WM_SYSDEADCHAR            0x0107
	#define WM_UNICHAR                0x0109
	#define WM_KEYLAST                0x0109
	#define WM_APP                    0x8000


	#define RID_INPUT 0x10000003

	#define RIM_TYPEMOUSE    0x00000000
	#define RIM_TYPEKEYBOARD 0x00000001
	#define RIM_TYPEHID      0x00000002

	#define RI_KEY_MAKE    0x0000
	#define RI_KEY_BREAK   0x0001
	#define RI_KEY_E0      0x0002
	#define RI_KEY_E1      0x0004
	#define RI_MOUSE_WHEEL 0x0400

	#define RIDEV_NOLEGACY 0x00000030

	#define MAPVK_VK_TO_VSC    0
	#define MAPVK_VSC_TO_VK    1
	#define MAPVK_VK_TO_CHAR   2
	#define MAPVK_VSC_TO_VK_EX 3

	GB_DLL_IMPORT BOOL WINAPI RegisterRawInputDevices(RAWINPUTDEVICE const *raw_input_devices, UINT num_devices, UINT size);
	GB_DLL_IMPORT UINT WINAPI GetRawInputData(HRAWINPUT raw_input, UINT ui_command, void *data, UINT *size, UINT size_header);
	GB_DLL_IMPORT UINT WINAPI MapVirtualKeyW(UINT code, UINT map_type);


	#define CS_DBLCLKS 		0x0008
	#define CS_VREDRAW 		0x0001
	#define CS_HREDRAW 		0x0002

	#define MB_OK              0x0000l
	#define MB_ICONSTOP        0x0010l
	#define MB_YESNO           0x0004l
	#define MB_HELP            0x4000l
	#define MB_ICONEXCLAMATION 0x0030l

	GB_DLL_IMPORT LRESULT WINAPI DefWindowProcW(HWND wnd, UINT msg, WPARAM wParam, LPARAM lParam);
	GB_DLL_IMPORT HGDIOBJ WINAPI GetStockObject(int object);
	GB_DLL_IMPORT HMODULE WINAPI GetModuleHandleW(wchar_t const *);
	GB_DLL_IMPORT ATOM    WINAPI RegisterClassExW(WNDCLASSEXW const *wcx); // u16 == ATOM
	GB_DLL_IMPORT int     WINAPI MessageBoxW(void *wnd, wchar_t const *text, wchar_t const *caption, unsigned int type);


	#define DM_BITSPERPEL 0x00040000l
	#define DM_PELSWIDTH  0x00080000l
	#define DM_PELSHEIGHT 0x00100000l

	#define CDS_FULLSCREEN 0x4
	#define DISP_CHANGE_SUCCESSFUL 0
	#define IDYES 6

	#define WS_VISIBLE          0x10000000
	#define WS_THICKFRAME       0x00040000
	#define WS_MAXIMIZE         0x01000000
	#define WS_MAXIMIZEBOX      0x00010000
	#define WS_MINIMIZE         0x20000000
	#define WS_MINIMIZEBOX      0x00020000
	#define WS_POPUP            0x80000000
	#define WS_OVERLAPPED	    0
	#define WS_OVERLAPPEDWINDOW	0xcf0000
	#define CW_USEDEFAULT       0x80000000
	#define WS_BORDER           0x800000
	#define WS_CAPTION          0xc00000
	#define WS_SYSMENU          0x80000

	#define HWND_NOTOPMOST (HWND)(-2)
	#define HWND_TOPMOST   (HWND)(-1)
	#define HWND_TOP       (HWND)(+0)
	#define HWND_BOTTOM    (HWND)(+1)
	#define SWP_NOSIZE          0x0001
	#define SWP_NOMOVE          0x0002
	#define SWP_NOZORDER        0x0004
	#define SWP_NOREDRAW        0x0008
	#define SWP_NOACTIVATE      0x0010
	#define SWP_FRAMECHANGED    0x0020
	#define SWP_SHOWWINDOW      0x0040
	#define SWP_HIDEWINDOW      0x0080
	#define SWP_NOCOPYBITS      0x0100
	#define SWP_NOOWNERZORDER   0x0200
	#define SWP_NOSENDCHANGING  0x0400

	#define SW_HIDE             0
	#define SW_SHOWNORMAL       1
	#define SW_NORMAL           1
	#define SW_SHOWMINIMIZED    2
	#define SW_SHOWMAXIMIZED    3
	#define SW_MAXIMIZE         3
	#define SW_SHOWNOACTIVATE   4
	#define SW_SHOW             5
	#define SW_MINIMIZE         6
	#define SW_SHOWMINNOACTIVE  7
	#define SW_SHOWNA           8
	#define SW_RESTORE          9
	#define SW_SHOWDEFAULT      10
	#define SW_FORCEMINIMIZE    11
	#define SW_MAX              11

	#define ENUM_CURRENT_SETTINGS  cast(DWORD)-1
	#define ENUM_REGISTRY_SETTINGS cast(DWORD)-2

	GB_DLL_IMPORT LONG    WINAPI ChangeDisplaySettingsW(DEVMODEW *dev_mode, DWORD flags);
	GB_DLL_IMPORT BOOL    WINAPI AdjustWindowRect(RECT *rect, DWORD style, BOOL enu);
	GB_DLL_IMPORT HWND    WINAPI CreateWindowExW(DWORD ex_style, wchar_t const *class_name, wchar_t const *window_name,
	                                             DWORD style, int x, int y, int width, int height, HWND wnd_parent,
	                                             HMENU menu, HINSTANCE instance, void *param);
	GB_DLL_IMPORT HMODULE  WINAPI GetModuleHandleW(wchar_t const *);
	GB_DLL_IMPORT HDC             GetDC(HANDLE);
	GB_DLL_IMPORT BOOL     WINAPI GetWindowPlacement(HWND hWnd, WINDOWPLACEMENT *lpwndpl);
	GB_DLL_IMPORT BOOL            GetMonitorInfoW(HMONITOR hMonitor, MONITORINFO *lpmi);
	GB_DLL_IMPORT HMONITOR        MonitorFromWindow(HWND hwnd, DWORD dwFlags);
	GB_DLL_IMPORT LONG     WINAPI SetWindowLongW(HWND hWnd, int nIndex, LONG dwNewLong);
	GB_DLL_IMPORT BOOL     WINAPI SetWindowPos(HWND hWnd, HWND hWndInsertAfter, int X, int Y, int cx, int cy, UINT uFlags);
	GB_DLL_IMPORT BOOL     WINAPI SetWindowPlacement(HWND hWnd, WINDOWPLACEMENT const *lpwndpl);
	GB_DLL_IMPORT BOOL     WINAPI ShowWindow(HWND hWnd, int nCmdShow);
	GB_DLL_IMPORT LONG_PTR WINAPI GetWindowLongPtrW(HWND wnd, int index);

	GB_DLL_IMPORT BOOL           EnumDisplaySettingsW(wchar_t const *lpszDeviceName, DWORD iModeNum, DEVMODEW *lpDevMode);
	GB_DLL_IMPORT void *  WINAPI GlobalLock(HGLOBAL hMem);
	GB_DLL_IMPORT BOOL    WINAPI GlobalUnlock(HGLOBAL hMem);
	GB_DLL_IMPORT HGLOBAL WINAPI GlobalAlloc(UINT uFlags, usize dwBytes);
	GB_DLL_IMPORT HANDLE  WINAPI GetClipboardData(UINT uFormat);
	GB_DLL_IMPORT BOOL    WINAPI IsClipboardFormatAvailable(UINT format);
	GB_DLL_IMPORT BOOL    WINAPI OpenClipboard(HWND hWndNewOwner);
	GB_DLL_IMPORT BOOL    WINAPI EmptyClipboard(void);
	GB_DLL_IMPORT BOOL    WINAPI CloseClipboard(void);
	GB_DLL_IMPORT HANDLE  WINAPI SetClipboardData(UINT uFormat, HANDLE hMem);

	#define PFD_TYPE_RGBA             0
	#define PFD_TYPE_COLORINDEX       1
	#define PFD_MAIN_PLANE            0
	#define PFD_OVERLAY_PLANE         1
	#define PFD_UNDERLAY_PLANE        (-1)
	#define PFD_DOUBLEBUFFER          1
	#define PFD_STEREO                2
	#define PFD_DRAW_TO_WINDOW        4
	#define PFD_DRAW_TO_BITMAP        8
	#define PFD_SUPPORT_GDI           16
	#define PFD_SUPPORT_OPENGL        32
	#define PFD_GENERIC_FORMAT        64
	#define PFD_NEED_PALETTE          128
	#define PFD_NEED_SYSTEM_PALETTE   0x00000100
	#define PFD_SWAP_EXCHANGE         0x00000200
	#define PFD_SWAP_COPY             0x00000400
	#define PFD_SWAP_LAYER_BUFFERS    0x00000800
	#define PFD_GENERIC_ACCELERATED   0x00001000
	#define PFD_DEPTH_DONTCARE        0x20000000
	#define PFD_DOUBLEBUFFER_DONTCARE 0x40000000
	#define PFD_STEREO_DONTCARE       0x80000000

	#define GWLP_USERDATA -21

	#define GWL_ID    -12
	#define GWL_STYLE -16

	GB_DLL_IMPORT BOOL  WINAPI SetPixelFormat   (HDC hdc, int pixel_format, PIXELFORMATDESCRIPTOR const *pfd);
	GB_DLL_IMPORT int   WINAPI ChoosePixelFormat(HDC hdc, PIXELFORMATDESCRIPTOR const *pfd);
	GB_DLL_IMPORT HGLRC WINAPI wglCreateContext (HDC hdc);
	GB_DLL_IMPORT BOOL  WINAPI wglMakeCurrent   (HDC hdc, HGLRC hglrc);
	GB_DLL_IMPORT PROC  WINAPI wglGetProcAddress(char const *str);
	GB_DLL_IMPORT BOOL  WINAPI wglDeleteContext (HGLRC hglrc);

	GB_DLL_IMPORT BOOL     WINAPI SetForegroundWindow(HWND hWnd);
	GB_DLL_IMPORT HWND     WINAPI SetFocus(HWND hWnd);
	GB_DLL_IMPORT LONG_PTR WINAPI SetWindowLongPtrW(HWND hWnd, int nIndex, LONG_PTR dwNewLong);
	GB_DLL_IMPORT BOOL     WINAPI GetClientRect(HWND hWnd, RECT *lpRect);
	GB_DLL_IMPORT BOOL     WINAPI IsIconic(HWND hWnd);
	GB_DLL_IMPORT HWND     WINAPI GetFocus(void);
	GB_DLL_IMPORT int      WINAPI ShowCursor(BOOL bShow);
	GB_DLL_IMPORT SHORT    WINAPI GetAsyncKeyState(int key);
	GB_DLL_IMPORT BOOL     WINAPI GetCursorPos(POINT *lpPoint);
	GB_DLL_IMPORT BOOL     WINAPI SetCursorPos(int x, int y);
	GB_DLL_IMPORT BOOL            ScreenToClient(HWND hWnd, POINT *lpPoint);
	GB_DLL_IMPORT BOOL            ClientToScreen(HWND hWnd, POINT *lpPoint);
	GB_DLL_IMPORT BOOL     WINAPI MoveWindow(HWND hWnd, int X, int Y, int nWidth, int nHeight, BOOL bRepaint);
	GB_DLL_IMPORT BOOL     WINAPI SetWindowTextW(HWND hWnd, wchar_t const *lpString);
	GB_DLL_IMPORT DWORD    WINAPI GetWindowLongW(HWND hWnd, int nIndex);




	#define PM_NOREMOVE 0
	#define PM_REMOVE   1

	GB_DLL_IMPORT BOOL    WINAPI PeekMessageW(MSG *lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax, UINT wRemoveMsg);
	GB_DLL_IMPORT BOOL    WINAPI TranslateMessage(MSG const *lpMsg);
	GB_DLL_IMPORT LRESULT WINAPI DispatchMessageW(MSG const *lpMsg);

	typedef  enum
	{
		DIB_RGB_COLORS  = 0x00,
		DIB_PAL_COLORS  = 0x01,
		DIB_PAL_INDICES = 0x02
	} DIBColors;

	#define SRCCOPY     (u32)0x00CC0020
	#define SRCPAINT    (u32)0x00EE0086
	#define SRCAND      (u32)0x008800C6
	#define SRCINVERT   (u32)0x00660046
	#define SRCERASE    (u32)0x00440328
	#define NOTSRCCOPY  (u32)0x00330008
	#define NOTSRCERASE (u32)0x001100A6
	#define MERGECOPY   (u32)0x00C000CA
	#define MERGEPAINT  (u32)0x00BB0226
	#define PATCOPY     (u32)0x00F00021
	#define PATPAINT    (u32)0x00FB0A09
	#define PATINVERT   (u32)0x005A0049
	#define DSTINVERT   (u32)0x00550009
	#define BLACKNESS   (u32)0x00000042
	#define WHITENESS   (u32)0x00FF0062

	GB_DLL_IMPORT BOOL WINAPI SwapBuffers(HDC hdc);
	GB_DLL_IMPORT BOOL WINAPI DestroyWindow(HWND hWnd);
	GB_DLL_IMPORT int         StretchDIBits(HDC hdc, int XDest, int YDest, int nDestWidth, int nDestHeight,
	                                        int XSrc, int YSrc, int nSrcWidth, int nSrcHeight,
	                                        void const *lpBits, /*BITMAPINFO*/void const *lpBitsInfo, UINT iUsage, DWORD dwRop);
	                                        // IMPORTANT TODO(bill): FIX THIS!!!!
#endif // Bill's Mini Windows.h



#if defined(__GCC__) || defined(__GNUC__)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wattributes"
#pragma GCC diagnostic ignored "-Wmissing-braces"
#endif

#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable:4201)
#pragma warning(disable:4127) // Conditional expression is constant
#endif

void gb_assert_handler(char const *prefix, char const *condition, char const *file, i32 line, char const *msg, ...) {
	gb_printf_err("%s(%d): %s: ", file, line, prefix);
	if (condition)
		gb_printf_err( "`%s` ", condition);
	if (msg) {
		va_list va;
		va_start(va, msg);
		gb_printf_err_va(msg, va);
		va_end(va);
	}
	gb_printf_err("\n");
}

b32 gb_is_power_of_two(isize x) {
	if (x <= 0)
		return false;
	return !(x & (x-1));
}

gb_inline void *gb_align_forward(void *ptr, isize alignment) {
	uintptr p;

	GB_ASSERT(gb_is_power_of_two(alignment));

	p = cast(uintptr)ptr;
	return cast(void *)((p + (alignment-1)) &~ (alignment-1));
}



gb_inline void *      gb_pointer_add      (void *ptr, isize bytes)             { return cast(void *)(cast(u8 *)ptr + bytes); }
gb_inline void *      gb_pointer_sub      (void *ptr, isize bytes)             { return cast(void *)(cast(u8 *)ptr - bytes); }
gb_inline void const *gb_pointer_add_const(void const *ptr, isize bytes)       { return cast(void const *)(cast(u8 const *)ptr + bytes); }
gb_inline void const *gb_pointer_sub_const(void const *ptr, isize bytes)       { return cast(void const *)(cast(u8 const *)ptr - bytes); }
gb_inline isize       gb_pointer_diff     (void const *begin, void const *end) { return cast(isize)(cast(u8 const *)end - cast(u8 const *)begin); }

gb_inline void gb_zero_size(void *ptr, isize size) {
	if (size != 0) {
		memset(ptr, 0, size);
	}
}


#if defined(_MSC_VER) && !defined(__clang__)
#pragma intrinsic(__movsb)
#endif

gb_inline void *gb_memcopy(void *dest, void const *source, isize n) {
#if defined(_MSC_VER) && !defined(__clang__)
	if (dest == NULL) {
		return NULL;
	}
	// TODO(bill): Is this good enough?
	__movsb(cast(u8 *)dest, cast(u8 *)source, n);
// #elif defined(GB_SYSTEM_OSX) || defined(GB_SYSTEM_UNIX)
	// NOTE(zangent): I assume there's a reason this isn't being used elsewhere,
	//   but casting pointers as arguments to an __asm__ call is considered an
	//   error on MacOS and (I think) Linux
	// TODO(zangent): Figure out how to refactor the asm code so it works on MacOS,
	//   since this is probably not the way the author intended this to work.
	// memcpy(dest, source, n);
#elif defined(GB_CPU_X86)
	if (dest == NULL) {
		return NULL;
	}

	void *dest_copy = dest;
	__asm__ __volatile__("rep movsb" : "+D"(dest_copy), "+S"(source), "+c"(n) : : "memory");
#elif defined(GB_CPU_ARM) || defined(GB_CPU_RISCV)
	u8 *s = cast(u8 *)source;
	u8 *d = cast(u8 *)dest;
	for (isize i = 0; i < n; i++) {
		*d++ = *s++;
	}
#else
	u8 *d = cast(u8 *)dest;
	u8 const *s = cast(u8 const *)source;
	u32 w, x;

	if (dest == NULL) {
		return NULL;
	}

	for (; cast(uintptr)s % 4 && n; n--) {
		*d++ = *s++;
	}

	if (cast(uintptr)d % 4 == 0) {
		for (; n >= 16;
		     s += 16, d += 16, n -= 16) {
			*cast(u32 *)(d+ 0) = *cast(u32 *)(s+ 0);
			*cast(u32 *)(d+ 4) = *cast(u32 *)(s+ 4);
			*cast(u32 *)(d+ 8) = *cast(u32 *)(s+ 8);
			*cast(u32 *)(d+12) = *cast(u32 *)(s+12);
		}
		if (n & 8) {
			*cast(u32 *)(d+0) = *cast(u32 *)(s+0);
			*cast(u32 *)(d+4) = *cast(u32 *)(s+4);
			d += 8;
			s += 8;
		}
		if (n&4) {
			*cast(u32 *)(d+0) = *cast(u32 *)(s+0);
			d += 4;
			s += 4;
		}
		if (n&2) {
			*d++ = *s++; *d++ = *s++;
		}
		if (n&1) {
			*d = *s;
		}
		return dest;
	}

	if (n >= 32) {
	#if __BYTE_ORDER == __BIG_ENDIAN
	#define LS <<
	#define RS >>
	#else
	#define LS >>
	#define RS <<
	#endif
		switch (cast(uintptr)d % 4) {
		case 1: {
			w = *cast(u32 *)s;
			*d++ = *s++;
			*d++ = *s++;
			*d++ = *s++;
			n -= 3;
			while (n > 16) {
				x = *cast(u32 *)(s+1);
				*cast(u32 *)(d+0)  = (w LS 24) | (x RS 8);
				w = *cast(u32 *)(s+5);
				*cast(u32 *)(d+4)  = (x LS 24) | (w RS 8);
				x = *cast(u32 *)(s+9);
				*cast(u32 *)(d+8)  = (w LS 24) | (x RS 8);
				w = *cast(u32 *)(s+13);
				*cast(u32 *)(d+12) = (x LS 24) | (w RS 8);

				s += 16;
				d += 16;
				n -= 16;
			}
		} break;
		case 2: {
			w = *cast(u32 *)s;
			*d++ = *s++;
			*d++ = *s++;
			n -= 2;
			while (n > 17) {
				x = *cast(u32 *)(s+2);
				*cast(u32 *)(d+0)  = (w LS 16) | (x RS 16);
				w = *cast(u32 *)(s+6);
				*cast(u32 *)(d+4)  = (x LS 16) | (w RS 16);
				x = *cast(u32 *)(s+10);
				*cast(u32 *)(d+8)  = (w LS 16) | (x RS 16);
				w = *cast(u32 *)(s+14);
				*cast(u32 *)(d+12) = (x LS 16) | (w RS 16);

				s += 16;
				d += 16;
				n -= 16;
			}
		} break;
		case 3: {
			w = *cast(u32 *)s;
			*d++ = *s++;
			n -= 1;
			while (n > 18) {
				x = *cast(u32 *)(s+3);
				*cast(u32 *)(d+0)  = (w LS 8) | (x RS 24);
				w = *cast(u32 *)(s+7);
				*cast(u32 *)(d+4)  = (x LS 8) | (w RS 24);
				x = *cast(u32 *)(s+11);
				*cast(u32 *)(d+8)  = (w LS 8) | (x RS 24);
				w = *cast(u32 *)(s+15);
				*cast(u32 *)(d+12) = (x LS 8) | (w RS 24);

				s += 16;
				d += 16;
				n -= 16;
			}
		} break;
		default: break; // NOTE(bill): Do nowt!
		}
	#undef LS
	#undef RS
		if (n & 16) {
			*d++ = *s++; *d++ = *s++; *d++ = *s++; *d++ = *s++;
			*d++ = *s++; *d++ = *s++; *d++ = *s++; *d++ = *s++;
			*d++ = *s++; *d++ = *s++; *d++ = *s++; *d++ = *s++;
			*d++ = *s++; *d++ = *s++; *d++ = *s++; *d++ = *s++;
		}
		if (n & 8) {
			*d++ = *s++; *d++ = *s++; *d++ = *s++; *d++ = *s++;
			*d++ = *s++; *d++ = *s++; *d++ = *s++; *d++ = *s++;
		}
		if (n & 4) {
			*d++ = *s++; *d++ = *s++; *d++ = *s++; *d++ = *s++;
		}
		if (n & 2) {
			*d++ = *s++; *d++ = *s++;
		}
		if (n & 1) {
			*d = *s;
		}
	}

#endif
	return dest;
}

gb_inline void *gb_memmove(void *dest, void const *source, isize n) {
	u8 *d = cast(u8 *)dest;
	u8 const *s = cast(u8 const *)source;

	if (dest == NULL) {
		return NULL;
	}

	if (d == s) {
		return d;
	}
	if (s+n <= d || d+n <= s) { // NOTE(bill): Non-overlapping
		return gb_memcopy(d, s, n);
	}

	if (d < s) {
		if (cast(uintptr)s % gb_size_of(isize) == cast(uintptr)d % gb_size_of(isize)) {
			while (cast(uintptr)d % gb_size_of(isize)) {
				if (!n--) return dest;
				*d++ = *s++;
			}
			while (n>=gb_size_of(isize)) {
				*cast(isize *)d = *cast(isize *)s;
				n -= gb_size_of(isize);
				d += gb_size_of(isize);
				s += gb_size_of(isize);
			}
		}
		for (; n; n--) *d++ = *s++;
	} else {
		if ((cast(uintptr)s % gb_size_of(isize)) == (cast(uintptr)d % gb_size_of(isize))) {
			while (cast(uintptr)(d+n) % gb_size_of(isize)) {
				if (!n--)
					return dest;
				d[n] = s[n];
			}
			while (n >= gb_size_of(isize)) {
				n -= gb_size_of(isize);
				*cast(isize *)(d+n) = *cast(isize *)(s+n);
			}
		}
		while (n) n--, d[n] = s[n];
	}

	return dest;
}

gb_inline void *gb_memset(void *dest, u8 c, isize n) {
	u8 *s = cast(u8 *)dest;
	isize k;
	u32 c32 = ((u32)-1)/255 * c;

	if (dest == NULL) {
		return NULL;
	}

	if (n <= 0) {
		return dest;
	}
	s[0] = s[n-1] = c;
	if (n < 3) {
		return dest;
	}
	s[1] = s[n-2] = c;
	s[2] = s[n-3] = c;
	if (n < 7) {
		return dest;
	}
	s[3] = s[n-4] = c;
	if (n < 9) {
		return dest;
	}

	k = -cast(intptr)s & 3;
	s += k;
	n -= k;
	n &= -4;

	*cast(u32 *)(s+0) = c32;
	*cast(u32 *)(s+n-4) = c32;
	if (n < 9) {
		return dest;
	}
	*cast(u32 *)(s +  4)    = c32;
	*cast(u32 *)(s +  8)    = c32;
	*cast(u32 *)(s+n-12) = c32;
	*cast(u32 *)(s+n- 8) = c32;
	if (n < 25) {
		return dest;
	}
	*cast(u32 *)(s + 12) = c32;
	*cast(u32 *)(s + 16) = c32;
	*cast(u32 *)(s + 20) = c32;
	*cast(u32 *)(s + 24) = c32;
	*cast(u32 *)(s+n-28) = c32;
	*cast(u32 *)(s+n-24) = c32;
	*cast(u32 *)(s+n-20) = c32;
	*cast(u32 *)(s+n-16) = c32;

	k = 24 + (cast(uintptr)s & 4);
	s += k;
	n -= k;


	{
		u64 c64 = (cast(u64)c32 << 32) | c32;
		while (n > 31) {
			*cast(u64 *)(s+0) = c64;
			*cast(u64 *)(s+8) = c64;
			*cast(u64 *)(s+16) = c64;
			*cast(u64 *)(s+24) = c64;

			n -= 32;
			s += 32;
		}
	}

	return dest;
}

gb_inline i32 gb_memcompare(void const *s1, void const *s2, isize size) {
	// TODO(bill): Heavily optimize
	u8 const *s1p8 = cast(u8 const *)s1;
	u8 const *s2p8 = cast(u8 const *)s2;

	if (s1 == NULL || s2 == NULL) {
		return 0;
	}

	while (size--) {
		if (*s1p8 != *s2p8) {
			return (*s1p8 - *s2p8);
		}
		s1p8++, s2p8++;
	}
	return 0;
}

void gb_memswap(void *i, void *j, isize size) {
	if (i == j) return;

	if (size == 4) {
		gb_swap(u32, *cast(u32 *)i, *cast(u32 *)j);
	} else if (size == 8) {
		gb_swap(u64, *cast(u64 *)i, *cast(u64 *)j);
	} else if (size < 8) {
		u8 *a = cast(u8 *)i;
		u8 *b = cast(u8 *)j;
		if (a != b) {
			while (size--) {
				gb_swap(u8, *a, *b);
				a++, b++;
			}
		}
	} else {
		char buffer[256];

		// TODO(bill): Is the recursion ever a problem?
		while (size > gb_size_of(buffer)) {
			gb_memswap(i, j, gb_size_of(buffer));
			i = gb_pointer_add(i, gb_size_of(buffer));
			j = gb_pointer_add(j, gb_size_of(buffer));
			size -= gb_size_of(buffer);
		}

		gb_memcopy(buffer, i,      size);
		gb_memcopy(i,      j,      size);
		gb_memcopy(j,      buffer, size);
	}
}

#define GB__ONES        (cast(usize)-1/U8_MAX)
#define GB__HIGHS       (GB__ONES * (U8_MAX/2+1))
#define GB__HAS_ZERO(x) ((x)-GB__ONES & ~(x) & GB__HIGHS)


void const *gb_memchr(void const *data, u8 c, isize n) {
	u8 const *s = cast(u8 const *)data;
	while ((cast(uintptr)s & (sizeof(usize)-1)) &&
	       n && *s != c) {
		s++;
		n--;
	}
	if (n && *s != c) {
		isize const *w;
		isize k = GB__ONES * c;
		w = cast(isize const *)s;
		while (n >= gb_size_of(isize) && !GB__HAS_ZERO(*w ^ k)) {
			w++;
			n -= gb_size_of(isize);
		}
		s = cast(u8 const *)w;
		while (n && *s != c) {
			s++;
			n--;
		}
	}

	return n ? cast(void const *)s : NULL;
}


void const *gb_memrchr(void const *data, u8 c, isize n) {
	u8 const *s = cast(u8 const *)data;
	while (n--) {
		if (s[n] == c)
			return cast(void const *)(s + n);
	}
	return NULL;
}



gb_inline void *gb_alloc_align (gbAllocator a, isize size, isize alignment) {
	if (size == 0) {
		return NULL;
	}
	return a.proc(a.data, gbAllocation_Alloc, size, alignment, NULL, 0, GB_DEFAULT_ALLOCATOR_FLAGS);
}
gb_inline void *gb_alloc(gbAllocator a, isize size) {
	return gb_alloc_align(a, size, GB_DEFAULT_MEMORY_ALIGNMENT);
}
gb_inline void  gb_free(gbAllocator a, void *ptr) {
	if (ptr != NULL) {
		a.proc(a.data, gbAllocation_Free, 0, 0, ptr, 0, GB_DEFAULT_ALLOCATOR_FLAGS);
	}
}
gb_inline void  gb_free_all(gbAllocator a) {
	a.proc(a.data, gbAllocation_FreeAll, 0, 0, NULL, 0, GB_DEFAULT_ALLOCATOR_FLAGS);
}
gb_inline void *gb_resize(gbAllocator a, void *ptr, isize old_size, isize new_size) {
	return gb_resize_align(a, ptr, old_size, new_size, GB_DEFAULT_MEMORY_ALIGNMENT);
}
gb_inline void *gb_resize_align(gbAllocator a, void *ptr, isize old_size, isize new_size, isize alignment) {
	if (new_size == 0) {
		if (ptr != NULL) {
			return a.proc(a.data, gbAllocation_Free, 0, 0, ptr, old_size, GB_DEFAULT_ALLOCATOR_FLAGS);
		}
		return NULL;
	} else if (ptr == NULL) {
		return a.proc(a.data, gbAllocation_Alloc, new_size, alignment, NULL, 0, GB_DEFAULT_ALLOCATOR_FLAGS);
	} else if (old_size == new_size && ((uintptr)ptr % (uintptr)alignment) == 0) {
		return ptr;
	}
	return a.proc(a.data, gbAllocation_Resize, new_size, alignment, ptr, old_size, GB_DEFAULT_ALLOCATOR_FLAGS);
}

gb_inline void *gb_alloc_copy      (gbAllocator a, void const *src, isize size) {
	return gb_memcopy(gb_alloc(a, size), src, size);
}
gb_inline void *gb_alloc_copy_align(gbAllocator a, void const *src, isize size, isize alignment) {
	return gb_memcopy(gb_alloc_align(a, size, alignment), src, size);
}

gb_inline char *gb_alloc_str(gbAllocator a, char const *str) {
	return gb_alloc_str_len(a, str, gb_strlen(str));
}

gb_inline char *gb_alloc_str_len(gbAllocator a, char const *str, isize len) {
	char *result;
	result = cast(char *)gb_alloc(a, len+1);
	gb_memmove(result, str, len);
	result[len] = '\0';
	return result;
}


gb_inline void *gb_default_resize_align(gbAllocator a, void *old_memory, isize old_size, isize new_size, isize alignment) {
	if (!old_memory) return gb_alloc_align(a, new_size, alignment);

	if (new_size == 0) {
		gb_free(a, old_memory);
		return NULL;
	}

	if (new_size < old_size)
		new_size = old_size;

	if (old_size == new_size) {
		return old_memory;
	} else {
		void *new_memory = gb_alloc_align(a, new_size, alignment);
		if (!new_memory) return NULL;
		gb_memmove(new_memory, old_memory, gb_min(new_size, old_size));
		gb_free(a, old_memory);
		return new_memory;
	}
}




////////////////////////////////////////////////////////////////
//
// Concurrency
//
//

gb_inline u32 gb_thread_current_id(void) {
	u32 thread_id;
#if defined(GB_SYSTEM_WINDOWS)
	#if defined(GB_ARCH_32_BIT) && defined(GB_CPU_X86)
		thread_id = (cast(u32 *)__readfsdword(24))[9];
	#elif defined(GB_ARCH_64_BIT) && defined(GB_CPU_X86)
		thread_id = (cast(u32 *)__readgsqword(48))[18];
	#else
		thread_id = GetCurrentThreadId();
	#endif

#elif defined(GB_SYSTEM_OSX) && defined(GB_ARCH_64_BIT)
	thread_id = pthread_mach_thread_np(pthread_self());
#elif defined(GB_ARCH_32_BIT) && defined(GB_CPU_X86)
	__asm__("mov %%gs:0x08,%0" : "=r"(thread_id));
#elif defined(GB_ARCH_64_BIT) && defined(GB_CPU_X86)
	__asm__("mov %%fs:0x10,%0" : "=r"(thread_id));
#elif defined(GB_SYSTEM_LINUX)
	thread_id = gettid();
#elif defined(GB_SYSTEM_HAIKU)
	thread_id = find_thread(NULL);
#elif defined(GB_SYSTEM_FREEBSD)
	thread_id = pthread_getthreadid_np();
#elif defined(GB_SYSTEM_NETBSD)
	thread_id = (u32)_lwp_self();
#else
	#error Unsupported architecture for gb_thread_current_id()
#endif

	return thread_id;
}




gb_internal gbAllocator heap_allocator(void); // this is defined in common_memory.cpp
gb_inline gbAllocator gb_heap_allocator(void) {
	return heap_allocator();
}


#if defined(GB_SYSTEM_WINDOWS)
void gb_affinity_init(gbAffinity *a) {
	SYSTEM_LOGICAL_PROCESSOR_INFORMATION *start_processor_info = NULL;
	DWORD length = 0;
	b32 result  = GetLogicalProcessorInformation(NULL, &length);

	gb_zero_item(a);

	if (!result && GetLastError() == 122l /*ERROR_INSUFFICIENT_BUFFER*/ && length > 0) {
		start_processor_info = cast(SYSTEM_LOGICAL_PROCESSOR_INFORMATION *)gb_alloc(gb_heap_allocator(), length);
		result = GetLogicalProcessorInformation(start_processor_info, &length);
		if (result) {
			SYSTEM_LOGICAL_PROCESSOR_INFORMATION *end_processor_info, *processor_info;

			a->is_accurate  = true;
			a->core_count   = 0;
			a->thread_count = 0;
			end_processor_info = cast(SYSTEM_LOGICAL_PROCESSOR_INFORMATION *)gb_pointer_add(start_processor_info, length);

			for (processor_info = start_processor_info;
			     processor_info < end_processor_info;
			     processor_info++) {
				if (processor_info->Relationship == RelationProcessorCore) {
					isize thread = gb_count_set_bits(processor_info->ProcessorMask);
					if (thread == 0) {
						a->is_accurate = false;
					} else if (a->thread_count + thread > GB_WIN32_MAX_THREADS) {
						a->is_accurate = false;
					} else {
						GB_ASSERT(a->core_count <= a->thread_count &&
						          a->thread_count < GB_WIN32_MAX_THREADS);
						a->core_masks[a->core_count++] = processor_info->ProcessorMask;
						a->thread_count += thread;
					}
				}
			}
		}

		gb_free(gb_heap_allocator(), start_processor_info);
	}

	GB_ASSERT(a->core_count <= a->thread_count);
	if (a->thread_count == 0) {
		a->is_accurate   = false;
		a->core_count    = 1;
		a->thread_count  = 1;
		a->core_masks[0] = 1;
	}

}
void gb_affinity_destroy(gbAffinity *a) {
	gb_unused(a);
}


b32 gb_affinity_set(gbAffinity *a, isize core, isize thread) {
	usize available_mask, check_mask = 1;
	GB_ASSERT(thread < gb_affinity_thread_count_for_core(a, core));

	available_mask = a->core_masks[core];
	for (;;) {
		if ((available_mask & check_mask) != 0) {
			if (thread-- == 0) {
				usize result = SetThreadAffinityMask(GetCurrentThread(), check_mask);
				return result != 0;
			}
		}
		check_mask <<= 1; // NOTE(bill): Onto the next bit
	}
}

isize gb_affinity_thread_count_for_core(gbAffinity *a, isize core) {
	GB_ASSERT(core >= 0 && core < a->core_count);
	return gb_count_set_bits(a->core_masks[core]);
}

#elif defined(GB_SYSTEM_OSX)
void gb_affinity_init(gbAffinity *a) {
	usize count = 0;
	usize count_size = sizeof(count);

	a->is_accurate      = false;
	a->thread_count     = 1;
	a->core_count       = 1;
	a->threads_per_core = 1;

	if (sysctlbyname("hw.logicalcpu", &count, &count_size, NULL, 0) == 0) {
		if (count > 0) {
			a->thread_count = count;
			// Get # of physical cores
			if (sysctlbyname("hw.physicalcpu", &count, &count_size, NULL, 0) == 0) {
				if (count > 0) {
					a->core_count = count;
					a->threads_per_core = a->thread_count / count;
					if (a->threads_per_core < 1)
						a->threads_per_core = 1;
					else
						a->is_accurate = true;
				}
			}
		}
	}

}

void gb_affinity_destroy(gbAffinity *a) {
	gb_unused(a);
}

b32 gb_affinity_set(gbAffinity *a, isize core, isize thread_index) {
	isize index;
	thread_t thread;
	thread_affinity_policy_data_t info;
	kern_return_t result;

	GB_ASSERT(core < a->core_count);
	GB_ASSERT(thread_index < a->threads_per_core);

	index = core * a->threads_per_core + thread_index;
	thread = mach_thread_self();
	info.affinity_tag = cast(integer_t)index;
	result = thread_policy_set(thread, THREAD_AFFINITY_POLICY, cast(thread_policy_t)&info, THREAD_AFFINITY_POLICY_COUNT);
	return result == KERN_SUCCESS;
}

isize gb_affinity_thread_count_for_core(gbAffinity *a, isize core) {
	GB_ASSERT(core >= 0 && core < a->core_count);
	return a->threads_per_core;
}

#elif defined(GB_SYSTEM_FREEBSD)
#include <stdio.h>

void gb_affinity_init(gbAffinity *a) {
	usize count = 0;
	usize count_size = sizeof(count);

	a->is_accurate      = false;
	a->thread_count     = 1;
	a->core_count       = 1;
	a->threads_per_core = 1;

	if (sysctlbyname("kern.smp.cpus", &count, &count_size, NULL, 0) == 0) {
		if (count > 0) {
			a->thread_count = count;
			// Get # of physical cores
			if (sysctlbyname("kern.smp.cores", &count, &count_size, NULL, 0) == 0) {
				if (count > 0) {
					a->core_count = count;
					a->threads_per_core = a->thread_count / count;
					if (a->threads_per_core < 1)
						a->threads_per_core = 1;
					else
						a->is_accurate = true;
				}
			}
		}
	} else if (sysctlbyname("hw.ncpu", &count, &count_size, NULL, 0) == 0) {
		// SMP disabled or unavailable.
		if (count > 0) {
			a->is_accurate      = true;
			a->thread_count     = count;
			a->core_count       = count;
			a->threads_per_core = 1;
		}
	}

}

void gb_affinity_destroy(gbAffinity *a) {
	gb_unused(a);
}

b32 gb_affinity_set(gbAffinity *a, isize core, isize thread_index) {
	isize index;
	pthread_t thread;

	int result;

	GB_ASSERT(core < a->core_count);
	GB_ASSERT(thread_index < a->threads_per_core);

	index = core * a->threads_per_core + thread_index;
	thread = pthread_self();


	cpuset_t mn;
	CPU_ZERO(&mn);
	CPU_SET(size_t(index), &mn);
	//info.affinity_tag = cast(integer_t)index;
	//result = thread_policy_set(thread, THREAD_AFFINITY_POLICY, cast(thread_policy_t)&info, THREAD_AFFINITY_POLICY_COUNT);

#if !defined(GB_SYSTEM_HAIKU)
	result = pthread_setaffinity_np(thread, sizeof(cpuset_t), &mn);
#endif
	return result == 0;
}

isize gb_affinity_thread_count_for_core(gbAffinity *a, isize core) {
	GB_ASSERT(core >= 0 && core < a->core_count);
	return a->threads_per_core;
}

#elif defined(GB_SYSTEM_LINUX)
#include <stdio.h>

void gb_affinity_init(gbAffinity *a) {
	a->core_count       = sysconf(_SC_NPROCESSORS_ONLN);
	a->threads_per_core = 1;
	a->is_accurate      = a->core_count > 0;
	a->core_count       = a->is_accurate ? a->core_count : 1;
	a->thread_count     = a->core_count;
}

void gb_affinity_destroy(gbAffinity *a) {
	gb_unused(a);
}

b32 gb_affinity_set(gbAffinity *a, isize core, isize thread_index) {
	return true;
}

isize gb_affinity_thread_count_for_core(gbAffinity *a, isize core) {
	GB_ASSERT(0 <= core && core < a->core_count);
	return a->threads_per_core;
}

#elif defined(GB_SYSTEM_OPENBSD)
#include <unistd.h>

void gb_affinity_init(gbAffinity *a) {
	a->core_count       = sysconf(_SC_NPROCESSORS_ONLN);
	a->threads_per_core = 1;
	a->is_accurate      = a->core_count > 0;
	a->core_count       = a->is_accurate ? a->core_count : 1;
	a->thread_count     = a->core_count;
}

void gb_affinity_destroy(gbAffinity *a) {
	gb_unused(a);
}

b32 gb_affinity_set(gbAffinity *a, isize core, isize thread_index) {
	return true;
}

isize gb_affinity_thread_count_for_core(gbAffinity *a, isize core) {
	GB_ASSERT(0 <= core && core < a->core_count);
	return a->threads_per_core;
}

#elif defined(GB_SYSTEM_NETBSD)
#include <unistd.h>

void gb_affinity_init(gbAffinity *a) {
	a->core_count       = sysconf(_SC_NPROCESSORS_ONLN);
	a->threads_per_core = 1;
	a->is_accurate      = a->core_count > 0;
	a->core_count       = a->is_accurate ? a->core_count : 1;
	a->thread_count     = a->core_count;
}

void gb_affinity_destroy(gbAffinity *a) {
	gb_unused(a);
}

b32 gb_affinity_set(gbAffinity *a, isize core, isize thread_index) {
	return true;
}

isize gb_affinity_thread_count_for_core(gbAffinity *a, isize core) {
	GB_ASSERT(0 <= core && core < a->core_count);
	return a->threads_per_core;
}

#elif defined(GB_SYSTEM_HAIKU)
#include <unistd.h>

void gb_affinity_init(gbAffinity *a) {
	a->core_count       = sysconf(_SC_NPROCESSORS_ONLN);
	a->threads_per_core = 1;
	a->is_accurate      = a->core_count > 0;
	a->core_count       = a->is_accurate ? a->core_count : 1;
	a->thread_count     = a->core_count;
}

void gb_affinity_destroy(gbAffinity *a) {
	gb_unused(a);
}

b32 gb_affinity_set(gbAffinity *a, isize core, isize thread_index) {
	return true;
}

isize gb_affinity_thread_count_for_core(gbAffinity *a, isize core) {
	GB_ASSERT(0 <= core && core < a->core_count);
	return a->threads_per_core;
}
#else
#error TODO(bill): Unknown system
#endif





////////////////////////////////////////////////////////////////
//
// Custom Allocation
//
//


////////////////////////////////////////////////////////////////
//
// Sorting
//
//

// TODO(bill): Should I make all the macros local?

#define GB__COMPARE_PROC(Type) \
gb_global isize gb__##Type##_cmp_offset; GB_COMPARE_PROC(gb__##Type##_cmp) { \
	Type const p = *cast(Type const *)gb_pointer_add_const(a, gb__##Type##_cmp_offset); \
	Type const q = *cast(Type const *)gb_pointer_add_const(b, gb__##Type##_cmp_offset); \
	return p < q ? -1 : p > q; \
} \
GB_COMPARE_PROC_PTR(gb_##Type##_cmp(isize offset)) { \
	gb__##Type##_cmp_offset = offset; \
	return &gb__##Type##_cmp; \
}


GB__COMPARE_PROC(i16);
GB__COMPARE_PROC(i32);
GB__COMPARE_PROC(i64);
GB__COMPARE_PROC(isize);
GB__COMPARE_PROC(f32);
GB__COMPARE_PROC(f64);
GB__COMPARE_PROC(char);

// NOTE(bill): str_cmp is special as it requires a funny type and funny comparison
gb_global isize gb__str_cmp_offset; GB_COMPARE_PROC(gb__str_cmp) {
	char const *p = *cast(char const **)gb_pointer_add_const(a, gb__str_cmp_offset);
	char const *q = *cast(char const **)gb_pointer_add_const(b, gb__str_cmp_offset);
	return gb_strcmp(p, q);
}
GB_COMPARE_PROC_PTR(gb_str_cmp(isize offset)) {
	gb__str_cmp_offset = offset;
	return &gb__str_cmp;
}

#undef GB__COMPARE_PROC




// TODO(bill): Make user definable?
#define GB__SORT_STACK_SIZE            64
#define GB__SORT_INSERT_SORT_THRESHOLD  8

#define GB__SORT_PUSH(_base, _limit) do { \
	stack_ptr[0] = (_base); \
	stack_ptr[1] = (_limit); \
	stack_ptr += 2; \
} while (0)


#define GB__SORT_POP(_base, _limit) do { \
	stack_ptr -= 2; \
	(_base)  = stack_ptr[0]; \
	(_limit) = stack_ptr[1]; \
} while (0)



void gb_sort(void *base_, isize count, isize size, gbCompareProc cmp) {
	u8 *i, *j;
	u8 *base = cast(u8 *)base_;
	u8 *limit = base + count*size;
	isize threshold = GB__SORT_INSERT_SORT_THRESHOLD * size;

	// NOTE(bill): Prepare the stack
	u8 *stack[GB__SORT_STACK_SIZE] = {0};
	u8 **stack_ptr = stack;

	for (;;) {
		if ((limit-base) > threshold) {
			// NOTE(bill): Quick sort
			i = base + size;
			j = limit - size;

			gb_memswap(((limit-base)/size/2) * size + base, base, size);
			if (cmp(i, j) > 0)    gb_memswap(i, j, size);
			if (cmp(base, j) > 0) gb_memswap(base, j, size);
			if (cmp(i, base) > 0) gb_memswap(i, base, size);

			for (;;) {
				do i += size; while (cmp(i, base) < 0);
				do j -= size; while (cmp(j, base) > 0);
				if (i > j) break;
				gb_memswap(i, j, size);
			}

			gb_memswap(base, j, size);

			if (j - base > limit - i) {
				GB__SORT_PUSH(base, j);
				base = i;
			} else {
				GB__SORT_PUSH(i, limit);
				limit = j;
			}
		} else {
			// NOTE(bill): Insertion sort
			for (j = base, i = j+size;
			     i < limit;
			     j = i, i += size) {
				for (; cmp(j, j+size) > 0; j -= size) {
					gb_memswap(j, j+size, size);
					if (j == base) break;
				}
			}

			if (stack_ptr == stack) break; // NOTE(bill): Sorting is done!
			GB__SORT_POP(base, limit);
		}
	}
}

#undef GB__SORT_PUSH
#undef GB__SORT_POP


#define GB_RADIX_SORT_PROC_GEN(Type) GB_RADIX_SORT_PROC(Type) { \
	Type *source = items; \
	Type *dest   = temp; \
	isize byte_index, i, byte_max = 8*gb_size_of(Type); \
	for (byte_index = 0; byte_index < byte_max; byte_index += 8) { \
		isize offsets[256] = {0}; \
		isize total = 0; \
		/* NOTE(bill): First pass - count how many of each key */ \
		for (i = 0; i < count; i++) { \
			Type radix_value = source[i]; \
			Type radix_piece = (radix_value >> byte_index) & 0xff; \
			offsets[radix_piece]++; \
		} \
		/* NOTE(bill): Change counts to offsets */ \
		for (i = 0; i < gb_count_of(offsets); i++) { \
			isize skcount = offsets[i]; \
			offsets[i] = total; \
			total += skcount; \
		} \
		/* NOTE(bill): Second pass - place elements into the right location */ \
		for (i = 0; i < count; i++) { \
			Type radix_value = source[i]; \
			Type radix_piece = (radix_value >> byte_index) & 0xff; \
			dest[offsets[radix_piece]++] = source[i]; \
		} \
		gb_swap(Type *, source, dest); \
	} \
}

GB_RADIX_SORT_PROC_GEN(u8);
GB_RADIX_SORT_PROC_GEN(u16);
GB_RADIX_SORT_PROC_GEN(u32);
GB_RADIX_SORT_PROC_GEN(u64);

gb_inline isize gb_binary_search(void const *base, isize count, isize size, void const *key, gbCompareProc compare_proc) {
	isize start = 0;
	isize end = count;

	while (start < end) {
		isize mid = start + (end-start)/2;
		isize result = compare_proc(key, cast(u8 *)base + mid*size);
		if (result < 0)
			end = mid;
		else if (result > 0)
			start = mid+1;
		else
			return mid;
	}

	return -1;
}

void gb_reverse(void *base, isize count, isize size) {
	isize i, j = count-1;
	for (i = 0; i < j; i++, j++) {
		gb_memswap(cast(u8 *)base + i*size, cast(u8 *)base + j*size, size);
	}
}



////////////////////////////////////////////////////////////////
//
// Char things
//
//




gb_inline char gb_char_to_lower(char c) {
	if (c >= 'A' && c <= 'Z')
		return 'a' + (c - 'A');
	return c;
}

gb_inline char gb_char_to_upper(char c) {
	if (c >= 'a' && c <= 'z')
		return 'A' + (c - 'a');
	return c;
}

gb_inline b32 gb_char_is_space(char c) {
	if (c == ' '  ||
	    c == '\t' ||
	    c == '\n' ||
	    c == '\r' ||
	    c == '\f' ||
	    c == '\v')
	    return true;
	return false;
}

gb_inline b32 gb_char_is_digit(char c) {
	if (c >= '0' && c <= '9')
		return true;
	return false;
}

gb_inline b32 gb_char_is_hex_digit(char c) {
	if (gb_char_is_digit(c) ||
	    (c >= 'a' && c <= 'f') ||
	    (c >= 'A' && c <= 'F'))
	    return true;
	return false;
}

gb_inline b32 gb_char_is_alpha(char c) {
	if ((c >= 'A' && c <= 'Z') ||
	    (c >= 'a' && c <= 'z'))
	    return true;
	return false;
}

gb_inline b32 gb_char_is_alphanumeric(char c) {
	return gb_char_is_alpha(c) || gb_char_is_digit(c);
}

gb_inline i32 gb_digit_to_int(char c) {
	return gb_char_is_digit(c) ? c - '0' : c - 'W';
}

gb_inline i32 gb_hex_digit_to_int(char c) {
	if (gb_char_is_digit(c))
		return gb_digit_to_int(c);
	else if (gb_is_between(c, 'a', 'f'))
		return c - 'a' + 10;
	else if (gb_is_between(c, 'A', 'F'))
		return c - 'A' + 10;
	return -1;
}




gb_inline void gb_str_to_lower(char *str) {
	if (!str) return;
	while (*str) {
		*str = gb_char_to_lower(*str);
		str++;
	}
}

gb_inline void gb_str_to_upper(char *str) {
	if (!str) return;
	while (*str) {
		*str = gb_char_to_upper(*str);
		str++;
	}
}


gb_no_asan isize gb_strlen(char const *str) {
	char const *begin = str;
	isize const *w;
	if (str == NULL)  {
		return 0;
	}
	while (cast(uintptr)str % sizeof(usize)) {
		if (!*str)
			return str - begin;
		str++;
	}
	w = cast(isize const *)str;
	while (!GB__HAS_ZERO(*w)) {
		w++;
	}
	str = cast(char const *)w;
	while (*str) {
		str++;
	}
	return str - begin;
}

gb_inline isize gb_strnlen(char const *str, isize max_len) {
	char const *end = cast(char const *)gb_memchr(str, 0, max_len);
	if (end) {
		return end - str;
	}
	return max_len;
}

gb_inline isize gb_utf8_strlen(u8 const *str) {
	isize count = 0;
	for (; *str; count++) {
		u8 c = *str;
		isize inc = 0;
		     if (c < 0x80)           inc = 1;
		else if ((c & 0xe0) == 0xc0) inc = 2;
		else if ((c & 0xf0) == 0xe0) inc = 3;
		else if ((c & 0xf8) == 0xf0) inc = 4;
		else return -1;

		str += inc;
	}
	return count;
}

gb_inline isize gb_utf8_strnlen(u8 const *str, isize max_len) {
	isize count = 0;
	for (; *str && max_len > 0; count++) {
		u8 c = *str;
		isize inc = 0;
		     if (c < 0x80)           inc = 1;
		else if ((c & 0xe0) == 0xc0) inc = 2;
		else if ((c & 0xf0) == 0xe0) inc = 3;
		else if ((c & 0xf8) == 0xf0) inc = 4;
		else return -1;

		str += inc;
		max_len -= inc;
	}
	return count;
}


gb_inline i32 gb_strcmp(char const *s1, char const *s2) {
	while (*s1 && (*s1 == *s2)) {
		s1++, s2++;
	}
	return *(u8 *)s1 - *(u8 *)s2;
}

gb_inline char *gb_strcpy(char *dest, char const *source) {
	GB_ASSERT_NOT_NULL(dest);
	if (source) {
		char *str = dest;
		while (*source) *str++ = *source++;
	}
	return dest;
}


gb_inline char *gb_strncpy(char *dest, char const *source, isize len) {
	GB_ASSERT_NOT_NULL(dest);
	if (source) {
		char *str = dest;
		while (len > 0 && *source) {
			*str++ = *source++;
			len--;
		}
		while (len > 0) {
			*str++ = '\0';
			len--;
		}
	}
	return dest;
}

gb_inline isize gb_strlcpy(char *dest, char const *source, isize len) {
	isize result = 0;
	GB_ASSERT_NOT_NULL(dest);
	if (source) {
		char const *source_start = source;
		char *str = dest;
		while (len > 0 && *source) {
			*str++ = *source++;
			len--;
		}
		while (len > 0) {
			*str++ = '\0';
			len--;
		}

		result = source - source_start;
	}
	return result;
}

gb_inline char *gb_strrev(char *str) {
	isize len = gb_strlen(str);
	char *a = str + 0;
	char *b = str + len-1;
	len /= 2;
	while (len--) {
		gb_swap(char, *a, *b);
		a++, b--;
	}
	return str;
}




gb_inline i32 gb_strncmp(char const *s1, char const *s2, isize len) {
	for (; len > 0;
	     s1++, s2++, len--) {
		if (*s1 != *s2) {
			return ((s1 < s2) ? -1 : +1);
		} else if (*s1 == '\0') {
			return 0;
		}
	}
	return 0;
}


gb_inline char const *gb_strtok(char *output, char const *src, char const *delimit) {
	while (*src && gb_char_first_occurence(delimit, *src) != NULL) {
		*output++ = *src++;
	}

	*output = 0;
	return *src ? src+1 : src;
}

gb_inline b32 gb_str_has_prefix(char const *str, char const *prefix) {
	while (*prefix) {
		if (*str++ != *prefix++) {
			return false;
		}
	}
	return true;
}

gb_inline b32 gb_str_has_suffix(char const *str, char const *suffix) {
	isize i = gb_strlen(str);
	isize j = gb_strlen(suffix);
	if (j <= i) {
		return gb_strcmp(str+i-j, suffix) == 0;
	}
	return false;
}




gb_inline char const *gb_char_first_occurence(char const *s, char c) {
	char ch = c;
	for (; *s != ch; s++) {
		if (*s == '\0') {
			return NULL;
		}
	}
	return s;
}


gb_inline char const *gb_char_last_occurence(char const *s, char c) {
	char const *result = NULL;
	do {
		if (*s == c) {
			result = s;
		}
	} while (*s++);

	return result;
}



gb_inline void gb_str_concat(char *dest, isize dest_len,
                             char const *src_a, isize src_a_len,
                             char const *src_b, isize src_b_len) {
	GB_ASSERT(dest_len >= src_a_len+src_b_len+1);
	if (dest) {
		gb_memcopy(dest, src_a, src_a_len);
		gb_memcopy(dest+src_a_len, src_b, src_b_len);
		dest[src_a_len+src_b_len] = '\0';
	}
}


gb_internal isize gb__scan_i64(char const *text, i32 base, i64 *value) {
	char const *text_begin = text;
	i64 result = 0;
	b32 negative = false;

	if (*text == '-') {
		negative = true;
		text++;
	}

	if (base == 16 && gb_strncmp(text, "0x", 2) == 0) {
		text += 2;
	}

	for (;;) {
		i64 v;
		if (gb_char_is_digit(*text)) {
			v = *text - '0';
		} else if (base == 16 && gb_char_is_hex_digit(*text)) {
			v = gb_hex_digit_to_int(*text);
		} else {
			break;
		}

		result *= base;
		result += v;
		text++;
	}

	if (value) {
		if (negative) result = -result;
		*value = result;
	}

	return (text - text_begin);
}

gb_internal isize gb__scan_u64(char const *text, i32 base, u64 *value) {
	char const *text_begin = text;
	u64 result = 0;

	if (base == 16 && gb_strncmp(text, "0x", 2) == 0) {
		text += 2;
	}

	for (;;) {
		u64 v;
		if (gb_char_is_digit(*text)) {
			v = *text - '0';
		} else if (base == 16 && gb_char_is_hex_digit(*text)) {
			v = gb_hex_digit_to_int(*text);
		} else {
			break;
		}

		result *= base;
		result += v;
		text++;
	}

	if (value) *value = result;
	return (text - text_begin);
}


// TODO(bill): Make better
u64 gb_str_to_u64(char const *str, char **end_ptr, i32 base) {
	isize len;
	u64 value = 0;

	if (!base) {
		if ((gb_strlen(str) > 2) && (gb_strncmp(str, "0x", 2) == 0)) {
			base = 16;
		} else {
			base = 10;
		}
	}

	len = gb__scan_u64(str, base, &value);
	if (end_ptr) *end_ptr = (char *)str + len;
	return value;
}

i64 gb_str_to_i64(char const *str, char **end_ptr, i32 base) {
	isize len;
	i64 value;

	if (!base) {
		if ((gb_strlen(str) > 2) && (gb_strncmp(str, "0x", 2) == 0)) {
			base = 16;
		} else {
			base = 10;
		}
	}

	len = gb__scan_i64(str, base, &value);
	if (end_ptr) *end_ptr = (char *)str + len;
	return value;
}

// TODO(bill): Are these good enough for characters?
gb_global char const gb__num_to_char_table[] =
	"0123456789"
	"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	"abcdefghijklmnopqrstuvwxyz"
	"@$";

gb_inline void gb_i64_to_str(i64 value, char *string, i32 base) {
	char *buf = string;
	b32 negative = false;
	u64 v;
	if (value < 0) {
		negative = true;
		value = -value;
	}
	v = cast(u64)value;
	if (v != 0) {
		while (v > 0) {
			*buf++ = gb__num_to_char_table[v % base];
			v /= base;
		}
	} else {
		*buf++ = '0';
	}
	if (negative) {
		*buf++ = '-';
	}
	*buf = '\0';
	gb_strrev(string);
}



gb_inline void gb_u64_to_str(u64 value, char *string, i32 base) {
	char *buf = string;

	if (value) {
		while (value > 0) {
			*buf++ = gb__num_to_char_table[value % base];
			value /= base;
		}
	} else {
		*buf++ = '0';
	}
	*buf = '\0';

	gb_strrev(string);
}

gb_inline f32 gb_str_to_f32(char const *str, char **end_ptr) {
	f64 f = gb_str_to_f64(str, end_ptr);
	f32 r = cast(f32)f;
	return r;
}

gb_inline f64 gb_str_to_f64(char const *str, char **end_ptr) {
	f64 result, value, sign, scale;
	i32 frac;

	while (gb_char_is_space(*str)) {
		str++;
	}

	sign = 1.0;
	if (*str == '-') {
		sign = -1.0;
		str++;
	} else if (*str == '+') {
		str++;
	}

	for (value = 0.0; gb_char_is_digit(*str); str++) {
		value = value * 10.0 + (*str-'0');
	}

	if (*str == '.') {
		f64 pow10 = 10.0;
		str++;
		while (gb_char_is_digit(*str)) {
			value += (*str-'0') / pow10;
			pow10 *= 10.0;
			str++;
		}
	}

	frac = 0;
	scale = 1.0;
	if ((*str == 'e') || (*str == 'E')) {
		u32 exp;

		str++;
		if (*str == '-') {
			frac = 1;
			str++;
		} else if (*str == '+') {
			str++;
		}

		for (exp = 0; gb_char_is_digit(*str); str++) {
			exp = exp * 10 + (*str-'0');
		}
		if (exp > 308) exp = 308;

		while (exp >= 50) { scale *= 1e50; exp -= 50; }
		while (exp >=  8) { scale *= 1e8;  exp -=  8; }
		while (exp >   0) { scale *= 10.0; exp -=  1; }
	}

	result = sign * (frac ? (value / scale) : (value * scale));

	if (end_ptr) *end_ptr = cast(char *)str;

	return result;
}







gb_inline void gb__set_string_length  (gbString str, isize len) { GB_STRING_HEADER(str)->length = len; }
gb_inline void gb__set_string_capacity(gbString str, isize cap) { GB_STRING_HEADER(str)->capacity = cap; }


gbString gb_string_make_reserve(gbAllocator a, isize capacity) {
	isize header_size = gb_size_of(gbStringHeader);
	void *ptr = gb_alloc(a, header_size + capacity + 1);

	gbString str;
	gbStringHeader *header;

	if (ptr == NULL) return NULL;
	gb_zero_size(ptr, header_size + capacity + 1);

	str = cast(char *)ptr + header_size;
	header = GB_STRING_HEADER(str);
	header->allocator = a;
	header->length    = 0;
	header->capacity  = capacity;
	str[capacity] = '\0';

	return str;
}


gb_inline gbString gb_string_make(gbAllocator a, char const *str) {
	isize len = str ? gb_strlen(str) : 0;
	return gb_string_make_length(a, str, len);
}

gbString gb_string_make_length(gbAllocator a, void const *init_str, isize num_bytes) {
	isize header_size = gb_size_of(gbStringHeader);
	void *ptr = gb_alloc(a, header_size + num_bytes + 1);

	gbString str;
	gbStringHeader *header;

	if (ptr == NULL) return NULL;
	if (!init_str) gb_zero_size(ptr, header_size + num_bytes + 1);

	str = cast(char *)ptr + header_size;
	header = GB_STRING_HEADER(str);
	header->allocator = a;
	header->length    = num_bytes;
	header->capacity  = num_bytes;
	if (num_bytes && init_str) {
		gb_memcopy(str, init_str, num_bytes);
	}
	str[num_bytes] = '\0';

	return str;
}

gb_inline void gb_string_free(gbString str) {
	if (str) {
		gbStringHeader *header = GB_STRING_HEADER(str);
		gb_free(header->allocator, header);
	}

}

gb_inline gbString gb_string_duplicate(gbAllocator a, gbString const str) { return gb_string_make_length(a, str, gb_string_length(str)); }

gb_inline isize gb_string_length  (gbString const str) { return GB_STRING_HEADER(str)->length; }
gb_inline isize gb_string_capacity(gbString const str) { return GB_STRING_HEADER(str)->capacity; }

gb_inline isize gb_string_available_space(gbString const str) {
	gbStringHeader *h = GB_STRING_HEADER(str);
	if (h->capacity > h->length) {
		return h->capacity - h->length;
	}
	return 0;
}


gb_inline void gb_string_clear(gbString str) { gb__set_string_length(str, 0); str[0] = '\0'; }

gb_inline gbString gb_string_append(gbString str, gbString const other) { return gb_string_append_length(str, other, gb_string_length(other)); }

gbString gb_string_append_length(gbString str, void const *other, isize other_len) {
	if (other_len > 0) {
		isize curr_len = gb_string_length(str);

		str = gb_string_make_space_for(str, other_len);
		if (str == NULL) {
			return NULL;
		}

		gb_memcopy(str + curr_len, other, other_len);
		str[curr_len + other_len] = '\0';
		gb__set_string_length(str, curr_len + other_len);
	}
	return str;
}

gb_inline gbString gb_string_appendc(gbString str, char const *other) {
	return gb_string_append_length(str, other, gb_strlen(other));
}

gbString gb_string_append_rune(gbString str, Rune r) {
	if (r >= 0) {
		u8 buf[8] = {0};
		isize len = gb_utf8_encode_rune(buf, r);
		return gb_string_append_length(str, buf, len);
	}
	return str;
}

gbString gb_string_append_fmt(gbString str, char const *fmt, ...) {
	isize res;
	char buf[4096] = {0};
	va_list va;
	va_start(va, fmt);
	res = gb_snprintf_va(buf, gb_count_of(buf)-1, fmt, va)-1;
	va_end(va);
	return gb_string_append_length(str, buf, res);
}



gbString gb_string_set(gbString str, char const *cstr) {
	isize len = gb_strlen(cstr);
	if (gb_string_capacity(str) < len) {
		str = gb_string_make_space_for(str, len - gb_string_length(str));
		if (str == NULL) {
			return NULL;
		}
	}

	gb_memcopy(str, cstr, len);
	str[len] = '\0';
	gb__set_string_length(str, len);

	return str;
}



gbString gb_string_make_space_for(gbString str, isize add_len) {
	isize available = gb_string_available_space(str);

	// NOTE(bill): Return if there is enough space left
	if (available >= add_len) {
		return str;
	} else {
		isize new_len, old_size, new_size;
		void *ptr, *new_ptr;
		gbAllocator a = GB_STRING_HEADER(str)->allocator;
		gbStringHeader *header;

		new_len = gb_string_length(str) + add_len;
		ptr = GB_STRING_HEADER(str);
		old_size = gb_size_of(gbStringHeader) + gb_string_length(str) + 1;
		new_size = gb_size_of(gbStringHeader) + new_len + 1;

		new_ptr = gb_resize(a, ptr, old_size, new_size);
		if (new_ptr == NULL) return NULL;

		header = cast(gbStringHeader *)new_ptr;
		header->allocator = a;

		str = cast(gbString)(header+1);
		gb__set_string_capacity(str, new_len);

		return str;
	}
}

gb_inline isize gb_string_allocation_size(gbString const str) {
	isize cap = gb_string_capacity(str);
	return gb_size_of(gbStringHeader) + cap;
}


gb_inline b32 gb_string_are_equal(gbString const lhs, gbString const rhs) {
	isize lhs_len, rhs_len, i;
	lhs_len = gb_string_length(lhs);
	rhs_len = gb_string_length(rhs);
	if (lhs_len != rhs_len) {
		return false;
	}

	for (i = 0; i < lhs_len; i++) {
		if (lhs[i] != rhs[i]) {
			return false;
		}
	}

	return true;
}


gbString gb_string_trim(gbString str, char const *cut_set) {
	char *start, *end, *start_pos, *end_pos;
	isize len;

	start_pos = start = str;
	end_pos   = end   = str + gb_string_length(str) - 1;

	while (start_pos <= end && gb_char_first_occurence(cut_set, *start_pos)) {
		start_pos++;
	}
	while (end_pos > start_pos && gb_char_first_occurence(cut_set, *end_pos)) {
		end_pos--;
	}

	len = cast(isize)((start_pos > end_pos) ? 0 : ((end_pos - start_pos)+1));

	if (str != start_pos)
		gb_memmove(str, start_pos, len);
	str[len] = '\0';

	gb__set_string_length(str, len);

	return str;
}

gb_inline gbString gb_string_trim_space(gbString str) { return gb_string_trim(str, " \t\r\n\v\f"); }




////////////////////////////////////////////////////////////////
//
// Windows UTF-8 Handling
//
//


u16 *gb_utf8_to_ucs2(u16 *buffer, isize len, u8 const *str) {
	Rune c;
	isize i = 0;
	len--;
	while (*str) {
		if (i >= len)
			return NULL;
		if (!(*str & 0x80)) {
			buffer[i++] = *str++;
		} else if ((*str & 0xe0) == 0xc0) {
			if (*str < 0xc2)
				return NULL;
			c = (*str++ & 0x1f) << 6;
			if ((*str & 0xc0) != 0x80)
				return NULL;
			buffer[i++] = cast(u16)(c + (*str++ & 0x3f));
		} else if ((*str & 0xf0) == 0xe0) {
			if (*str == 0xe0 &&
			    (str[1] < 0xa0 || str[1] > 0xbf))
				return NULL;
			if (*str == 0xed && str[1] > 0x9f) // str[1] < 0x80 is checked below
				return NULL;
			c = (*str++ & 0x0f) << 12;
			if ((*str & 0xc0) != 0x80)
				return NULL;
			c += (*str++ & 0x3f) << 6;
			if ((*str & 0xc0) != 0x80)
				return NULL;
			buffer[i++] = cast(u16)(c + (*str++ & 0x3f));
		} else if ((*str & 0xf8) == 0xf0) {
			if (*str > 0xf4)
				return NULL;
			if (*str == 0xf0 && (str[1] < 0x90 || str[1] > 0xbf))
				return NULL;
			if (*str == 0xf4 && str[1] > 0x8f) // str[1] < 0x80 is checked below
				return NULL;
			c = (*str++ & 0x07) << 18;
			if ((*str & 0xc0) != 0x80)
				return NULL;
			c += (*str++ & 0x3f) << 12;
			if ((*str & 0xc0) != 0x80)
				return NULL;
			c += (*str++ & 0x3f) << 6;
			if ((*str & 0xc0) != 0x80)
				return NULL;
			c += (*str++ & 0x3f);
			// UTF-8 encodings of values used in surrogate pairs are invalid
			if ((c & 0xfffff800) == 0xd800)
				return NULL;
			if (c >= 0x10000) {
				c -= 0x10000;
				if (i+2 > len)
					return NULL;
				buffer[i++] = 0xd800 | (0x3ff & (c>>10));
				buffer[i++] = 0xdc00 | (0x3ff & (c    ));
			}
		} else {
			return NULL;
		}
	}
	buffer[i] = 0;
	return buffer;
}

u8 *gb_ucs2_to_utf8(u8 *buffer, isize len, u16 const *str) {
	isize i = 0;
	len--;
	while (*str) {
		if (*str < 0x80) {
			if (i+1 > len)
				return NULL;
			buffer[i++] = (char) *str++;
		} else if (*str < 0x800) {
			if (i+2 > len)
				return NULL;
			buffer[i++] = cast(char)(0xc0 + (*str >> 6));
			buffer[i++] = cast(char)(0x80 + (*str & 0x3f));
			str += 1;
		} else if (*str >= 0xd800 && *str < 0xdc00) {
			Rune c;
			if (i+4 > len)
				return NULL;
			c = ((str[0] - 0xd800) << 10) + ((str[1]) - 0xdc00) + 0x10000;
			buffer[i++] = cast(char)(0xf0 +  (c >> 18));
			buffer[i++] = cast(char)(0x80 + ((c >> 12) & 0x3f));
			buffer[i++] = cast(char)(0x80 + ((c >>  6) & 0x3f));
			buffer[i++] = cast(char)(0x80 + ((c      ) & 0x3f));
			str += 2;
		} else if (*str >= 0xdc00 && *str < 0xe000) {
			return NULL;
		} else {
			if (i+3 > len)
				return NULL;
			buffer[i++] = 0xe0 +  (*str >> 12);
			buffer[i++] = 0x80 + ((*str >>  6) & 0x3f);
			buffer[i++] = 0x80 + ((*str      ) & 0x3f);
			str += 1;
		}
	}
	buffer[i] = 0;
	return buffer;
}

u16 *gb_utf8_to_ucs2_buf(u8 const *str) { // NOTE(bill): Uses locally persisting buffer
	gb_local_persist u16 buf[4096];
	return gb_utf8_to_ucs2(buf, gb_count_of(buf), str);
}

u8 *gb_ucs2_to_utf8_buf(u16 const *str) { // NOTE(bill): Uses locally persisting buffer
	gb_local_persist u8 buf[4096];
	return gb_ucs2_to_utf8(buf, gb_count_of(buf), str);
}



gb_global u8 const gb__utf8_first[256] = {
	0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x00-0x0F
	0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x10-0x1F
	0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x20-0x2F
	0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x30-0x3F
	0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x40-0x4F
	0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x50-0x5F
	0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x60-0x6F
	0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, // 0x70-0x7F
	0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0x80-0x8F
	0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0x90-0x9F
	0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0xA0-0xAF
	0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0xB0-0xBF
	0xf1, 0xf1, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, // 0xC0-0xCF
	0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, // 0xD0-0xDF
	0x13, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x23, 0x03, 0x03, // 0xE0-0xEF
	0x34, 0x04, 0x04, 0x04, 0x44, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, 0xf1, // 0xF0-0xFF
};


typedef struct gbUtf8AcceptRange {
	u8 lo, hi;
} gbUtf8AcceptRange;

gb_global gbUtf8AcceptRange const gb__utf8_accept_ranges[] = {
	{0x80, 0xbf},
	{0xa0, 0xbf},
	{0x80, 0x9f},
	{0x90, 0xbf},
	{0x80, 0x8f},
};


isize gb_utf8_decode(u8 const *str, isize str_len, Rune *codepoint_out) {
	isize width = 0;
	Rune codepoint = GB_RUNE_INVALID;

	if (str_len > 0) {
		u8 s0 = str[0];
		u8 x = gb__utf8_first[s0], sz;
		u8 b1, b2, b3;
		gbUtf8AcceptRange accept;
		if (x >= 0xf0) {
			Rune mask = (cast(Rune)x << 31) >> 31;
			codepoint = (cast(Rune)s0 & (~mask)) | (GB_RUNE_INVALID & mask);
			width = 1;
			goto end;
		}
		if (s0 < 0x80) {
			codepoint = s0;
			width = 1;
			goto end;
		}

		sz = x&7;
		accept = gb__utf8_accept_ranges[x>>4];
		if (str_len < gb_size_of(sz))
			goto invalid_codepoint;

		b1 = str[1];
		if (b1 < accept.lo || accept.hi < b1)
			goto invalid_codepoint;

		if (sz == 2) {
			codepoint = (cast(Rune)s0&0x1f)<<6 | (cast(Rune)b1&0x3f);
			width = 2;
			goto end;
		}

		b2 = str[2];
		if (!gb_is_between(b2, 0x80, 0xbf))
			goto invalid_codepoint;

		if (sz == 3) {
			codepoint = (cast(Rune)s0&0x1f)<<12 | (cast(Rune)b1&0x3f)<<6 | (cast(Rune)b2&0x3f);
			width = 3;
			goto end;
		}

		b3 = str[3];
		if (!gb_is_between(b3, 0x80, 0xbf))
			goto invalid_codepoint;

		codepoint = (cast(Rune)s0&0x07)<<18 | (cast(Rune)b1&0x3f)<<12 | (cast(Rune)b2&0x3f)<<6 | (cast(Rune)b3&0x3f);
		width = 4;
		goto end;

	invalid_codepoint:
		codepoint = GB_RUNE_INVALID;
		width = 1;
	}

end:
	if (codepoint_out) *codepoint_out = codepoint;
	return width;
}

isize gb_utf8_codepoint_size(u8 const *str, isize str_len) {
	isize i = 0;
	for (; i < str_len && str[i]; i++) {
		if ((str[i] & 0xc0) != 0x80)
			break;
	}
	return i+1;
}

isize gb_utf8_encode_rune(u8 buf[4], Rune r) {
	u32 i = cast(u32)r;
	u8 mask = 0x3f;
	if (i <= (1<<7)-1) {
		buf[0] = cast(u8)r;
		return 1;
	}
	if (i <= (1<<11)-1) {
		buf[0] = 0xc0 | cast(u8)(r>>6);
		buf[1] = 0x80 | (cast(u8)(r)&mask);
		return 2;
	}

	// Invalid or Surrogate range
	if (i > GB_RUNE_MAX ||
	    gb_is_between(i, 0xd800, 0xdfff)) {
		r = GB_RUNE_INVALID;

		buf[0] = 0xe0 | cast(u8)(r>>12);
		buf[1] = 0x80 | (cast(u8)(r>>6)&mask);
		buf[2] = 0x80 | (cast(u8)(r)&mask);
		return 3;
	}

	if (i <= (1<<16)-1) {
		buf[0] = 0xe0 | cast(u8)(r>>12);
		buf[1] = 0x80 | (cast(u8)(r>>6)&mask);
		buf[2] = 0x80 | (cast(u8)(r)&mask);
		return 3;
	}

	buf[0] = 0xf0 | cast(u8)(r>>18);
	buf[1] = 0x80 | (cast(u8)(r>>12)&mask);
	buf[2] = 0x80 | (cast(u8)(r>>6)&mask);
	buf[3] = 0x80 | (cast(u8)(r)&mask);
	return 4;
}



////////////////////////////////////////////////////////////////
//
// Hashing functions
//
//

u32 gb_adler32(void const *data, isize len) {
	u32 const MOD_ALDER = 65521;
	u32 a = 1, b = 0;
	isize i, block_len;
	u8 const *bytes = cast(u8 const *)data;

	block_len = len % 5552;

	while (len) {
		for (i = 0; i+7 < block_len; i += 8) {
			a += bytes[0], b += a;
			a += bytes[1], b += a;
			a += bytes[2], b += a;
			a += bytes[3], b += a;
			a += bytes[4], b += a;
			a += bytes[5], b += a;
			a += bytes[6], b += a;
			a += bytes[7], b += a;

			bytes += 8;
		}
		for (; i < block_len; i++) {
			a += *bytes++, b += a;
		}

		a %= MOD_ALDER, b %= MOD_ALDER;
		len -= block_len;
		block_len = 5552;
	}

	return (b << 16) | a;
}


gb_global u32 const GB__CRC32_TABLE[256] = {
	0x00000000, 0x77073096, 0xee0e612c, 0x990951ba,
	0x076dc419, 0x706af48f, 0xe963a535, 0x9e6495a3,
	0x0edb8832, 0x79dcb8a4, 0xe0d5e91e, 0x97d2d988,
	0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91,
	0x1db71064, 0x6ab020f2, 0xf3b97148, 0x84be41de,
	0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7,
	0x136c9856, 0x646ba8c0, 0xfd62f97a, 0x8a65c9ec,
	0x14015c4f, 0x63066cd9, 0xfa0f3d63, 0x8d080df5,
	0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172,
	0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b,
	0x35b5a8fa, 0x42b2986c, 0xdbbbc9d6, 0xacbcf940,
	0x32d86ce3, 0x45df5c75, 0xdcd60dcf, 0xabd13d59,
	0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116,
	0x21b4f4b5, 0x56b3c423, 0xcfba9599, 0xb8bda50f,
	0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924,
	0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d,
	0x76dc4190, 0x01db7106, 0x98d220bc, 0xefd5102a,
	0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
	0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818,
	0x7f6a0dbb, 0x086d3d2d, 0x91646c97, 0xe6635c01,
	0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e,
	0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457,
	0x65b0d9c6, 0x12b7e950, 0x8bbeb8ea, 0xfcb9887c,
	0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65,
	0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2,
	0x4adfa541, 0x3dd895d7, 0xa4d1c46d, 0xd3d6f4fb,
	0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0,
	0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9,
	0x5005713c, 0x270241aa, 0xbe0b1010, 0xc90c2086,
	0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
	0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4,
	0x59b33d17, 0x2eb40d81, 0xb7bd5c3b, 0xc0ba6cad,
	0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a,
	0xead54739, 0x9dd277af, 0x04db2615, 0x73dc1683,
	0xe3630b12, 0x94643b84, 0x0d6d6a3e, 0x7a6a5aa8,
	0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
	0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe,
	0xf762575d, 0x806567cb, 0x196c3671, 0x6e6b06e7,
	0xfed41b76, 0x89d32be0, 0x10da7a5a, 0x67dd4acc,
	0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5,
	0xd6d6a3e8, 0xa1d1937e, 0x38d8c2c4, 0x4fdff252,
	0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b,
	0xd80d2bda, 0xaf0a1b4c, 0x36034af6, 0x41047a60,
	0xdf60efc3, 0xa867df55, 0x316e8eef, 0x4669be79,
	0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236,
	0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f,
	0xc5ba3bbe, 0xb2bd0b28, 0x2bb45a92, 0x5cb36a04,
	0xc2d7ffa7, 0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d,
	0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a,
	0x9c0906a9, 0xeb0e363f, 0x72076785, 0x05005713,
	0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38,
	0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21,
	0x86d3d2d4, 0xf1d4e242, 0x68ddb3f8, 0x1fda836e,
	0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
	0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c,
	0x8f659eff, 0xf862ae69, 0x616bffd3, 0x166ccf45,
	0xa00ae278, 0xd70dd2ee, 0x4e048354, 0x3903b3c2,
	0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db,
	0xaed16a4a, 0xd9d65adc, 0x40df0b66, 0x37d83bf0,
	0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
	0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6,
	0xbad03605, 0xcdd70693, 0x54de5729, 0x23d967bf,
	0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94,
	0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d,
};

gb_global u64 const GB__CRC64_TABLE[256] = {
	0x0000000000000000ull, 0x42f0e1eba9ea3693ull, 0x85e1c3d753d46d26ull, 0xc711223cfa3e5bb5ull,
	0x493366450e42ecdfull, 0x0bc387aea7a8da4cull, 0xccd2a5925d9681f9ull, 0x8e224479f47cb76aull,
	0x9266cc8a1c85d9beull, 0xd0962d61b56fef2dull, 0x17870f5d4f51b498ull, 0x5577eeb6e6bb820bull,
	0xdb55aacf12c73561ull, 0x99a54b24bb2d03f2ull, 0x5eb4691841135847ull, 0x1c4488f3e8f96ed4ull,
	0x663d78ff90e185efull, 0x24cd9914390bb37cull, 0xe3dcbb28c335e8c9ull, 0xa12c5ac36adfde5aull,
	0x2f0e1eba9ea36930ull, 0x6dfeff5137495fa3ull, 0xaaefdd6dcd770416ull, 0xe81f3c86649d3285ull,
	0xf45bb4758c645c51ull, 0xb6ab559e258e6ac2ull, 0x71ba77a2dfb03177ull, 0x334a9649765a07e4ull,
	0xbd68d2308226b08eull, 0xff9833db2bcc861dull, 0x388911e7d1f2dda8ull, 0x7a79f00c7818eb3bull,
	0xcc7af1ff21c30bdeull, 0x8e8a101488293d4dull, 0x499b3228721766f8ull, 0x0b6bd3c3dbfd506bull,
	0x854997ba2f81e701ull, 0xc7b97651866bd192ull, 0x00a8546d7c558a27ull, 0x4258b586d5bfbcb4ull,
	0x5e1c3d753d46d260ull, 0x1cecdc9e94ace4f3ull, 0xdbfdfea26e92bf46ull, 0x990d1f49c77889d5ull,
	0x172f5b3033043ebfull, 0x55dfbadb9aee082cull, 0x92ce98e760d05399ull, 0xd03e790cc93a650aull,
	0xaa478900b1228e31ull, 0xe8b768eb18c8b8a2ull, 0x2fa64ad7e2f6e317ull, 0x6d56ab3c4b1cd584ull,
	0xe374ef45bf6062eeull, 0xa1840eae168a547dull, 0x66952c92ecb40fc8ull, 0x2465cd79455e395bull,
	0x3821458aada7578full, 0x7ad1a461044d611cull, 0xbdc0865dfe733aa9ull, 0xff3067b657990c3aull,
	0x711223cfa3e5bb50ull, 0x33e2c2240a0f8dc3ull, 0xf4f3e018f031d676ull, 0xb60301f359dbe0e5ull,
	0xda050215ea6c212full, 0x98f5e3fe438617bcull, 0x5fe4c1c2b9b84c09ull, 0x1d14202910527a9aull,
	0x93366450e42ecdf0ull, 0xd1c685bb4dc4fb63ull, 0x16d7a787b7faa0d6ull, 0x5427466c1e109645ull,
	0x4863ce9ff6e9f891ull, 0x0a932f745f03ce02ull, 0xcd820d48a53d95b7ull, 0x8f72eca30cd7a324ull,
	0x0150a8daf8ab144eull, 0x43a04931514122ddull, 0x84b16b0dab7f7968ull, 0xc6418ae602954ffbull,
	0xbc387aea7a8da4c0ull, 0xfec89b01d3679253ull, 0x39d9b93d2959c9e6ull, 0x7b2958d680b3ff75ull,
	0xf50b1caf74cf481full, 0xb7fbfd44dd257e8cull, 0x70eadf78271b2539ull, 0x321a3e938ef113aaull,
	0x2e5eb66066087d7eull, 0x6cae578bcfe24bedull, 0xabbf75b735dc1058ull, 0xe94f945c9c3626cbull,
	0x676dd025684a91a1ull, 0x259d31cec1a0a732ull, 0xe28c13f23b9efc87ull, 0xa07cf2199274ca14ull,
	0x167ff3eacbaf2af1ull, 0x548f120162451c62ull, 0x939e303d987b47d7ull, 0xd16ed1d631917144ull,
	0x5f4c95afc5edc62eull, 0x1dbc74446c07f0bdull, 0xdaad56789639ab08ull, 0x985db7933fd39d9bull,
	0x84193f60d72af34full, 0xc6e9de8b7ec0c5dcull, 0x01f8fcb784fe9e69ull, 0x43081d5c2d14a8faull,
	0xcd2a5925d9681f90ull, 0x8fdab8ce70822903ull, 0x48cb9af28abc72b6ull, 0x0a3b7b1923564425ull,
	0x70428b155b4eaf1eull, 0x32b26afef2a4998dull, 0xf5a348c2089ac238ull, 0xb753a929a170f4abull,
	0x3971ed50550c43c1ull, 0x7b810cbbfce67552ull, 0xbc902e8706d82ee7ull, 0xfe60cf6caf321874ull,
	0xe224479f47cb76a0ull, 0xa0d4a674ee214033ull, 0x67c58448141f1b86ull, 0x253565a3bdf52d15ull,
	0xab1721da49899a7full, 0xe9e7c031e063acecull, 0x2ef6e20d1a5df759ull, 0x6c0603e6b3b7c1caull,
	0xf6fae5c07d3274cdull, 0xb40a042bd4d8425eull, 0x731b26172ee619ebull, 0x31ebc7fc870c2f78ull,
	0xbfc9838573709812ull, 0xfd39626eda9aae81ull, 0x3a28405220a4f534ull, 0x78d8a1b9894ec3a7ull,
	0x649c294a61b7ad73ull, 0x266cc8a1c85d9be0ull, 0xe17dea9d3263c055ull, 0xa38d0b769b89f6c6ull,
	0x2daf4f0f6ff541acull, 0x6f5faee4c61f773full, 0xa84e8cd83c212c8aull, 0xeabe6d3395cb1a19ull,
	0x90c79d3fedd3f122ull, 0xd2377cd44439c7b1ull, 0x15265ee8be079c04ull, 0x57d6bf0317edaa97ull,
	0xd9f4fb7ae3911dfdull, 0x9b041a914a7b2b6eull, 0x5c1538adb04570dbull, 0x1ee5d94619af4648ull,
	0x02a151b5f156289cull, 0x4051b05e58bc1e0full, 0x87409262a28245baull, 0xc5b073890b687329ull,
	0x4b9237f0ff14c443ull, 0x0962d61b56fef2d0ull, 0xce73f427acc0a965ull, 0x8c8315cc052a9ff6ull,
	0x3a80143f5cf17f13ull, 0x7870f5d4f51b4980ull, 0xbf61d7e80f251235ull, 0xfd913603a6cf24a6ull,
	0x73b3727a52b393ccull, 0x31439391fb59a55full, 0xf652b1ad0167feeaull, 0xb4a25046a88dc879ull,
	0xa8e6d8b54074a6adull, 0xea16395ee99e903eull, 0x2d071b6213a0cb8bull, 0x6ff7fa89ba4afd18ull,
	0xe1d5bef04e364a72ull, 0xa3255f1be7dc7ce1ull, 0x64347d271de22754ull, 0x26c49cccb40811c7ull,
	0x5cbd6cc0cc10fafcull, 0x1e4d8d2b65facc6full, 0xd95caf179fc497daull, 0x9bac4efc362ea149ull,
	0x158e0a85c2521623ull, 0x577eeb6e6bb820b0ull, 0x906fc95291867b05ull, 0xd29f28b9386c4d96ull,
	0xcedba04ad0952342ull, 0x8c2b41a1797f15d1ull, 0x4b3a639d83414e64ull, 0x09ca82762aab78f7ull,
	0x87e8c60fded7cf9dull, 0xc51827e4773df90eull, 0x020905d88d03a2bbull, 0x40f9e43324e99428ull,
	0x2cffe7d5975e55e2ull, 0x6e0f063e3eb46371ull, 0xa91e2402c48a38c4ull, 0xebeec5e96d600e57ull,
	0x65cc8190991cb93dull, 0x273c607b30f68faeull, 0xe02d4247cac8d41bull, 0xa2dda3ac6322e288ull,
	0xbe992b5f8bdb8c5cull, 0xfc69cab42231bacfull, 0x3b78e888d80fe17aull, 0x7988096371e5d7e9ull,
	0xf7aa4d1a85996083ull, 0xb55aacf12c735610ull, 0x724b8ecdd64d0da5ull, 0x30bb6f267fa73b36ull,
	0x4ac29f2a07bfd00dull, 0x08327ec1ae55e69eull, 0xcf235cfd546bbd2bull, 0x8dd3bd16fd818bb8ull,
	0x03f1f96f09fd3cd2ull, 0x41011884a0170a41ull, 0x86103ab85a2951f4ull, 0xc4e0db53f3c36767ull,
	0xd8a453a01b3a09b3ull, 0x9a54b24bb2d03f20ull, 0x5d45907748ee6495ull, 0x1fb5719ce1045206ull,
	0x919735e51578e56cull, 0xd367d40ebc92d3ffull, 0x1476f63246ac884aull, 0x568617d9ef46bed9ull,
	0xe085162ab69d5e3cull, 0xa275f7c11f7768afull, 0x6564d5fde549331aull, 0x279434164ca30589ull,
	0xa9b6706fb8dfb2e3ull, 0xeb46918411358470ull, 0x2c57b3b8eb0bdfc5ull, 0x6ea7525342e1e956ull,
	0x72e3daa0aa188782ull, 0x30133b4b03f2b111ull, 0xf7021977f9cceaa4ull, 0xb5f2f89c5026dc37ull,
	0x3bd0bce5a45a6b5dull, 0x79205d0e0db05dceull, 0xbe317f32f78e067bull, 0xfcc19ed95e6430e8ull,
	0x86b86ed5267cdbd3ull, 0xc4488f3e8f96ed40ull, 0x0359ad0275a8b6f5ull, 0x41a94ce9dc428066ull,
	0xcf8b0890283e370cull, 0x8d7be97b81d4019full, 0x4a6acb477bea5a2aull, 0x089a2aacd2006cb9ull,
	0x14dea25f3af9026dull, 0x562e43b4931334feull, 0x913f6188692d6f4bull, 0xd3cf8063c0c759d8ull,
	0x5dedc41a34bbeeb2ull, 0x1f1d25f19d51d821ull, 0xd80c07cd676f8394ull, 0x9afce626ce85b507ull,
};

u32 gb_crc32(void const *data, isize len) {
	isize remaining;
	u32 result = ~(cast(u32)0);
	u8 const *c = cast(u8 const *)data;
	for (remaining = len; remaining--; c++) {
		result = (result >> 8) ^ (GB__CRC32_TABLE[(result ^ *c) & 0xff]);
	}
	return ~result;
}

u64 gb_crc64(void const *data, isize len) {
	isize remaining;
	u64 result = ~(cast(u64)0);
	u8 const *c = cast(u8 const *)data;
	for (remaining = len; remaining--; c++) {
		result = (result >> 8) ^ (GB__CRC64_TABLE[(result ^ *c) & 0xff]);
	}
	return ~result;
}

u32 gb_fnv32(void const *data, isize len) {
	isize i;
	u32 h = 0x811c9dc5;
	u8 const *c = cast(u8 const *)data;

	for (i = 0; i < len; i++) {
		h = (h * 0x01000193) ^ c[i];
	}

	return h;
}

u64 gb_fnv64(void const *data, isize len) {
	isize i;
	u64 h = 0xcbf29ce484222325ull;
	u8 const *c = cast(u8 const *)data;

	for (i = 0; i < len; i++) {
		h = (h * 0x100000001b3ll) ^ c[i];
	}

	return h;
}

u32 gb_fnv32a(void const *data, isize len) {
	isize i;
	u32 h = 0x811c9dc5;
	u8 const *c = cast(u8 const *)data;

	for (i = 0; i < len; i++) {
		h = (h ^ c[i]) * 0x01000193;
	}

	return h;
}

u64 gb_fnv64a(void const *data, isize len) {
	isize i;
	u64 h = 0xcbf29ce484222325ull;
	u8 const *c = cast(u8 const *)data;

	for (i = 0; i < len; i++) {
		h = (h ^ c[i]) * 0x100000001b3ll;
	}

	return h;
}

gb_inline u32 gb_murmur32(void const *data, isize len) { return gb_murmur32_seed(data, len, 0x9747b28c); }
gb_inline u64 gb_murmur64(void const *data, isize len) { return gb_murmur64_seed(data, len, 0x9747b28c); }

u32 gb_murmur32_seed(void const *data, isize len, u32 seed) {
	u32 const c1 = 0xcc9e2d51;
	u32 const c2 = 0x1b873593;
	u32 const r1 = 15;
	u32 const r2 = 13;
	u32 const m  = 5;
	u32 const n  = 0xe6546b64;

	isize i, nblocks = len / 4;
	u32 hash = seed, k1 = 0;
	u32 const *blocks = cast(u32 const*)data;
	u8 const *tail = cast(u8 const *)(data) + nblocks*4;

	for (i = 0; i < nblocks; i++) {
		u32 k = blocks[i];
		k *= c1;
		k = (k << r1) | (k >> (32 - r1));
		k *= c2;

		hash ^= k;
		hash = ((hash << r2) | (hash >> (32 - r2))) * m + n;
	}

	switch (len & 3) {
	case 3:
		k1 ^= tail[2] << 16;
	case 2:
		k1 ^= tail[1] << 8;
	case 1:
		k1 ^= tail[0];

		k1 *= c1;
		k1 = (k1 << r1) | (k1 >> (32 - r1));
		k1 *= c2;
		hash ^= k1;
	}

	hash ^= len;
	hash ^= (hash >> 16);
	hash *= 0x85ebca6b;
	hash ^= (hash >> 13);
	hash *= 0xc2b2ae35;
	hash ^= (hash >> 16);

	return hash;
}

u64 gb_murmur64_seed(void const *data_, isize len, u64 seed) {
#if defined(GB_ARCH_64_BIT)
	u64 const m = 0xc6a4a7935bd1e995ULL;
	i32 const r = 47;

	u64 h = seed ^ (len * m);

	u64 const *data = cast(u64 const *)data_;
	u8  const *data2 = cast(u8 const *)data_;
	u64 const* end = data + (len / 8);

	while (data != end) {
		u64 k = *data++;

		k *= m;
		k ^= k >> r;
		k *= m;

		h ^= k;
		h *= m;
	}

	switch (len & 7) {
	case 7: h ^= cast(u64)(data2[6]) << 48;
	case 6: h ^= cast(u64)(data2[5]) << 40;
	case 5: h ^= cast(u64)(data2[4]) << 32;
	case 4: h ^= cast(u64)(data2[3]) << 24;
	case 3: h ^= cast(u64)(data2[2]) << 16;
	case 2: h ^= cast(u64)(data2[1]) << 8;
	case 1: h ^= cast(u64)(data2[0]);
		h *= m;
	};

	h ^= h >> r;
	h *= m;
	h ^= h >> r;

	return h;
#else
	u64 h;
	u32 const m = 0x5bd1e995;
	i32 const r = 24;

	u32 h1 = cast(u32)(seed) ^ cast(u32)(len);
	u32 h2 = cast(u32)(seed >> 32);

	u32 const *data = cast(u32 const *)data_;

	while (len >= 8) {
		u32 k1, k2;
		k1 = *data++;
		k1 *= m;
		k1 ^= k1 >> r;
		k1 *= m;
		h1 *= m;
		h1 ^= k1;
		len -= 4;

		k2 = *data++;
		k2 *= m;
		k2 ^= k2 >> r;
		k2 *= m;
		h2 *= m;
		h2 ^= k2;
		len -= 4;
	}

	if (len >= 4) {
		u32 k1 = *data++;
		k1 *= m;
		k1 ^= k1 >> r;
		k1 *= m;
		h1 *= m;
		h1 ^= k1;
		len -= 4;
	}

	switch (len) {
	case 3: h2 ^= (cast(u8 const *)data)[2] << 16;
	case 2: h2 ^= (cast(u8 const *)data)[1] <<  8;
	case 1: h2 ^= (cast(u8 const *)data)[0] <<  0;
		h2 *= m;
	};

	h1 ^= h2 >> 18;
	h1 *= m;
	h2 ^= h1 >> 22;
	h2 *= m;
	h1 ^= h2 >> 17;
	h1 *= m;
	h2 ^= h1 >> 19;
	h2 *= m;

	h = h1;
	h = (h << 32) | h2;

	return h;
#endif
}







////////////////////////////////////////////////////////////////
//
// File Handling
//
//

#if defined(GB_SYSTEM_WINDOWS)

	gb_internal wchar_t *gb__alloc_utf8_to_ucs2(gbAllocator a, char const *text, isize *w_len_) {
		wchar_t *w_text = NULL;
		isize len = 0, w_len = 0, w_len1 = 0;
		if (text == NULL) {
			if (w_len_) *w_len_ = w_len;
			return NULL;
		}
		len = gb_strlen(text);
		if (len == 0) {
			if (w_len_) *w_len_ = w_len;
			return NULL;
		}
		w_len = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, text, cast(int)len, NULL, 0);
		if (w_len == 0) {
			if (w_len_) *w_len_ = w_len;
			return NULL;
		}
		w_text = gb_alloc_array(a, wchar_t, w_len+1);
		w_len1 = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, text, cast(int)len, w_text, cast(int)w_len);
		if (w_len1 == 0) {
			gb_free(a, w_text);
			if (w_len_) *w_len_ = 0;
			return NULL;
		}
		w_text[w_len] = 0;
		if (w_len_) *w_len_ = w_len;
		return w_text;
	}

	gb_internal GB_FILE_SEEK_PROC(gb__win32_file_seek) {
		LARGE_INTEGER li_offset;
		li_offset.QuadPart = offset;
		if (!SetFilePointerEx(fd.p, li_offset, &li_offset, whence)) {
			return false;
		}

		if (new_offset) *new_offset = li_offset.QuadPart;
		return true;
	}

	gb_internal GB_FILE_READ_AT_PROC(gb__win32_file_read) {
		b32 result = false;
		DWORD size_ = cast(DWORD)(size > I32_MAX ? I32_MAX : size);
		DWORD bytes_read_;
		gb__win32_file_seek(fd, offset, gbSeekWhence_Begin, NULL);
		if (ReadFile(fd.p, buffer, size_, &bytes_read_, NULL)) {
			if (bytes_read) *bytes_read = bytes_read_;
			result = true;
		}

		return result;
	}

	gb_internal GB_FILE_WRITE_AT_PROC(gb__win32_file_write) {
		DWORD size_ = cast(DWORD)(size > I32_MAX ? I32_MAX : size);
		DWORD bytes_written_;
		gb__win32_file_seek(fd, offset, gbSeekWhence_Begin, NULL);
		if (WriteFile(fd.p, buffer, size_, &bytes_written_, NULL)) {
			if (bytes_written) *bytes_written = bytes_written_;
			return true;
		}
		return false;
	}

	gb_internal GB_FILE_CLOSE_PROC(gb__win32_file_close) {
		CloseHandle(fd.p);
	}

	gbFileOperations const gbDefaultFileOperations = {
		gb__win32_file_read,
		gb__win32_file_write,
		gb__win32_file_seek,
		gb__win32_file_close
	};

	gb_no_inline GB_FILE_OPEN_PROC(gb__win32_file_open) {
		DWORD desired_access;
		DWORD creation_disposition;
		void *handle;
		wchar_t *w_text;

		switch (mode & gbFileMode_Modes) {
		case gbFileMode_Read:
			desired_access = GENERIC_READ;
			creation_disposition = OPEN_EXISTING;
			break;
		case gbFileMode_Write:
			desired_access = GENERIC_WRITE;
			creation_disposition = CREATE_ALWAYS;
			break;
		case gbFileMode_Append:
			desired_access = GENERIC_WRITE;
			creation_disposition = OPEN_ALWAYS;
			break;
		case gbFileMode_Read | gbFileMode_Rw:
			desired_access = GENERIC_READ | GENERIC_WRITE;
			creation_disposition = OPEN_EXISTING;
			break;
		case gbFileMode_Write | gbFileMode_Rw:
			desired_access = GENERIC_READ | GENERIC_WRITE;
			creation_disposition = CREATE_ALWAYS;
			break;
		case gbFileMode_Append | gbFileMode_Rw:
			desired_access = GENERIC_READ | GENERIC_WRITE;
			creation_disposition = OPEN_ALWAYS;
			break;
		default:
			GB_PANIC("Invalid file mode");
			return gbFileError_Invalid;
		}

		w_text = gb__alloc_utf8_to_ucs2(gb_heap_allocator(), filename, NULL);
		if (w_text == NULL) {
			return gbFileError_InvalidFilename;
		}
		handle = CreateFileW(w_text,
		                     desired_access,
		                     FILE_SHARE_READ|FILE_SHARE_DELETE, NULL,
		                     creation_disposition, FILE_ATTRIBUTE_NORMAL, NULL);

		gb_free(gb_heap_allocator(), w_text);

		if (handle == INVALID_HANDLE_VALUE) {
			DWORD err = GetLastError();
			switch (err) {
			case ERROR_FILE_NOT_FOUND: return gbFileError_NotExists;
			case ERROR_FILE_EXISTS:    return gbFileError_Exists;
			case ERROR_ALREADY_EXISTS: return gbFileError_Exists;
			case ERROR_ACCESS_DENIED:  return gbFileError_Permission;
			}
			return gbFileError_Invalid;
		}

		if (mode & gbFileMode_Append) {
			LARGE_INTEGER offset = {0};
			if (!SetFilePointerEx(handle, offset, NULL, gbSeekWhence_End)) {
				CloseHandle(handle);
				return gbFileError_Invalid;
			}
		}

		fd->p = handle;
		*ops = gbDefaultFileOperations;
		return gbFileError_None;
	}

#else // POSIX
	gb_internal GB_FILE_SEEK_PROC(gb__posix_file_seek) {
		#if defined(GB_SYSTEM_OSX)
		i64 res = lseek(fd.i, offset, whence);
		#else
		i64 res = lseek64(fd.i, offset, whence);
		#endif
		if (res < 0) return false;
		if (new_offset) *new_offset = res;
		return true;
	}

	gb_internal GB_FILE_READ_AT_PROC(gb__posix_file_read) {
		isize res = pread(fd.i, buffer, size, offset);
		if (res < 0) return false;
		if (bytes_read) *bytes_read = res;
		return true;
	}

	gb_internal GB_FILE_WRITE_AT_PROC(gb__posix_file_write) {
		isize res;
		i64 curr_offset = 0;
		gb__posix_file_seek(fd, 0, gbSeekWhence_Current, &curr_offset);
		if (curr_offset == offset) {
			// NOTE(bill): Writing to stdout et al. doesn't like pwrite for numerous reasons
			res = write(cast(int)fd.i, buffer, size);
		} else {
			res = pwrite(cast(int)fd.i, buffer, size, offset);
		}
		if (res < 0) return false;
		if (bytes_written) *bytes_written = res;
		return true;
	}


	gb_internal GB_FILE_CLOSE_PROC(gb__posix_file_close) {
		close(fd.i);
	}

	gbFileOperations const gbDefaultFileOperations = {
		gb__posix_file_read,
		gb__posix_file_write,
		gb__posix_file_seek,
		gb__posix_file_close
	};

	gb_no_inline GB_FILE_OPEN_PROC(gb__posix_file_open) {
		i32 os_mode;
		switch (mode & gbFileMode_Modes) {
		case gbFileMode_Read:
			os_mode = O_RDONLY;
			break;
		case gbFileMode_Write:
			os_mode = O_WRONLY | O_CREAT | O_TRUNC;
			break;
		case gbFileMode_Append:
			os_mode = O_WRONLY | O_APPEND | O_CREAT;
			break;
		case gbFileMode_Read | gbFileMode_Rw:
			os_mode = O_RDWR;
			break;
		case gbFileMode_Write | gbFileMode_Rw:
			os_mode = O_RDWR | O_CREAT | O_TRUNC;
			break;
		case gbFileMode_Append | gbFileMode_Rw:
			os_mode = O_RDWR | O_APPEND | O_CREAT;
			break;
		default:
			GB_PANIC("Invalid file mode");
			return gbFileError_Invalid;
		}

		fd->i = open(filename, os_mode, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH);
		if (fd->i < 0) {
			// TODO(bill): More file errors
			return gbFileError_Invalid;
		}

		*ops = gbDefaultFileOperations;
		return gbFileError_None;
	}

#endif



gbFileError gb_file_new(gbFile *f, gbFileDescriptor fd, gbFileOperations ops, char const *filename) {
	gbFileError err = gbFileError_None;
	isize len = gb_strlen(filename);

	// gb_printf_err("gb_file_new: %s\n", filename);

	f->ops = ops;
	f->fd = fd;
	f->filename = gb_alloc_array(gb_heap_allocator(), char, len+1);
	gb_memcopy(cast(char *)f->filename, cast(char *)filename, len+1);
	f->last_write_time = gb_file_last_write_time(f->filename);

	return err;
}



gbFileError gb_file_open_mode(gbFile *f, gbFileMode mode, char const *filename) {
	gbFileError err;
#if defined(GB_SYSTEM_WINDOWS)
	err = gb__win32_file_open(&f->fd, &f->ops, mode, filename);
#else
	err = gb__posix_file_open(&f->fd, &f->ops, mode, filename);
#endif
	if (err == gbFileError_None) {
		return gb_file_new(f, f->fd, f->ops, filename);
	}
	return err;
}

gbFileError gb_file_close(gbFile *f) {
	if (f == NULL) {
		return gbFileError_Invalid;
	}

#if defined(GB_COMPILER_MSVC)
	if (f->filename != NULL) {
		gb_free(gb_heap_allocator(), cast(char *)f->filename);
	}
#else
	// TODO HACK(bill): Memory Leak!!!
#endif

#if defined(GB_SYSTEM_WINDOWS)
	if (f->fd.p == INVALID_HANDLE_VALUE) {
		return gbFileError_Invalid;
	}
#else
	if (f->fd.i < 0) {
		return gbFileError_Invalid;
	}
#endif

	if (!f->ops.read_at) f->ops = gbDefaultFileOperations;
	f->ops.close(f->fd);

	return gbFileError_None;
}

gb_inline b32 gb_file_read_at_check(gbFile *f, void *buffer, isize size, i64 offset, isize *bytes_read) {
	if (!f->ops.read_at) f->ops = gbDefaultFileOperations;
	return f->ops.read_at(f->fd, buffer, size, offset, bytes_read);
}

gb_inline b32 gb_file_write_at_check(gbFile *f, void const *buffer, isize size, i64 offset, isize *bytes_written) {
	if (!f->ops.read_at) f->ops = gbDefaultFileOperations;
	return f->ops.write_at(f->fd, buffer, size, offset, bytes_written);
}


gb_inline b32 gb_file_read_at(gbFile *f, void *buffer, isize size, i64 offset) {
	return gb_file_read_at_check(f, buffer, size, offset, NULL);
}

gb_inline b32 gb_file_write_at(gbFile *f, void const *buffer, isize size, i64 offset) {
	return gb_file_write_at_check(f, buffer, size, offset, NULL);
}

gb_inline i64 gb_file_seek(gbFile *f, i64 offset) {
	i64 new_offset = 0;
	if (!f->ops.read_at) f->ops = gbDefaultFileOperations;
	f->ops.seek(f->fd, offset, gbSeekWhence_Begin, &new_offset);
	return new_offset;
}

gb_inline i64 gb_file_seek_to_end(gbFile *f) {
	i64 new_offset = 0;
	if (!f->ops.read_at) f->ops = gbDefaultFileOperations;
	f->ops.seek(f->fd, 0, gbSeekWhence_End, &new_offset);
	return new_offset;
}

// NOTE(bill): Skips a certain amount of bytes
gb_inline i64 gb_file_skip(gbFile *f, i64 bytes) {
	i64 new_offset = 0;
	if (!f->ops.read_at) f->ops = gbDefaultFileOperations;
	f->ops.seek(f->fd, bytes, gbSeekWhence_Current, &new_offset);
	return new_offset;
}

gb_inline i64 gb_file_tell(gbFile *f) {
	i64 new_offset = 0;
	if (!f->ops.read_at) f->ops = gbDefaultFileOperations;
	f->ops.seek(f->fd, 0, gbSeekWhence_Current, &new_offset);
	return new_offset;
}
gb_inline b32 gb_file_read (gbFile *f, void *buffer, isize size)       { return gb_file_read_at(f, buffer, size, gb_file_tell(f)); }
gb_inline b32 gb_file_write(gbFile *f, void const *buffer, isize size) { return gb_file_write_at(f, buffer, size, gb_file_tell(f)); }


gbFileError gb_file_create(gbFile *f, char const *filename) {
	return gb_file_open_mode(f, gbFileMode_Write|gbFileMode_Rw, filename);
}


gbFileError gb_file_open(gbFile *f, char const *filename) {
	return gb_file_open_mode(f, gbFileMode_Read, filename);
}


char const *gb_file_name(gbFile *f) { return f->filename ? f->filename : ""; }

gb_inline b32 gb_file_has_changed(gbFile *f) {
	b32 result = false;
	gbFileTime last_write_time = gb_file_last_write_time(f->filename);
	if (f->last_write_time != last_write_time) {
		result = true;
		f->last_write_time = last_write_time;
	}
	return result;
}

// TODO(bill): Is this a bad idea?
gb_global b32    gb__std_file_set;
gb_global gbFile gb__std_files[gbFileStandard_Count];


#if defined(GB_SYSTEM_WINDOWS)

gb_inline gbFile *gb_file_get_standard(gbFileStandardType std) {
	if (!gb__std_file_set) {
	#define GB__SET_STD_FILE(type, v) gb__std_files[type].fd.p = v; gb__std_files[type].ops = gbDefaultFileOperations
		GB__SET_STD_FILE(gbFileStandard_Input,  GetStdHandle(STD_INPUT_HANDLE));
		GB__SET_STD_FILE(gbFileStandard_Output, GetStdHandle(STD_OUTPUT_HANDLE));
		GB__SET_STD_FILE(gbFileStandard_Error,  GetStdHandle(STD_ERROR_HANDLE));
	#undef GB__SET_STD_FILE
		gb__std_file_set = true;
	}
	return &gb__std_files[std];
}

gb_inline i64 gb_file_size(gbFile *f) {
	LARGE_INTEGER size;
	GetFileSizeEx(f->fd.p, &size);
	return size.QuadPart;
}

gbFileError gb_file_truncate(gbFile *f, i64 size) {
	gbFileError err = gbFileError_None;
	i64 prev_offset = gb_file_tell(f);
	gb_file_seek(f, size);
	if (!SetEndOfFile(f)) {
		err = gbFileError_TruncationFailure;
	}
	gb_file_seek(f, prev_offset);
	return err;
}


b32 gb_file_exists(char const *name) {
	WIN32_FIND_DATAW data;
	wchar_t *w_text;
	void *handle;
	b32 found = false;
	gbAllocator a = gb_heap_allocator();

	w_text = gb__alloc_utf8_to_ucs2(a, name, NULL);
	if (w_text == NULL) {
		return false;
	}
	handle = FindFirstFileW(w_text, &data);
	gb_free(a, w_text);
	found = handle != INVALID_HANDLE_VALUE;
	if (found) FindClose(handle);
	return found;
}

#else // POSIX

gb_inline gbFile *gb_file_get_standard(gbFileStandardType std) {
	if (!gb__std_file_set) {
	#define GB__SET_STD_FILE(type, v) gb__std_files[type].fd.i = v; gb__std_files[type].ops = gbDefaultFileOperations
		GB__SET_STD_FILE(gbFileStandard_Input,  0);
		GB__SET_STD_FILE(gbFileStandard_Output, 1);
		GB__SET_STD_FILE(gbFileStandard_Error,  2);
	#undef GB__SET_STD_FILE
		gb__std_file_set = true;
	}
	return &gb__std_files[std];
}

gb_inline i64 gb_file_size(gbFile *f) {
	i64 size = 0;
	i64 prev_offset = gb_file_tell(f);
	gb_file_seek_to_end(f);
	size = gb_file_tell(f);
	gb_file_seek(f, prev_offset);
	return size;
}

gb_inline gbFileError gb_file_truncate(gbFile *f, i64 size) {
	gbFileError err = gbFileError_None;
	int i = ftruncate(f->fd.i, size);
	if (i != 0) err = gbFileError_TruncationFailure;
	return err;
}

gb_inline b32 gb_file_exists(char const *name) {
	return access(name, F_OK) != -1;
}
#endif



#if defined(GB_SYSTEM_WINDOWS)
gbFileTime gb_file_last_write_time(char const *filepath) {
	ULARGE_INTEGER li = {0};
	FILETIME last_write_time = {0};
	WIN32_FILE_ATTRIBUTE_DATA data = {0};
	gbAllocator a = gb_heap_allocator();

	wchar_t *w_text = gb__alloc_utf8_to_ucs2(a, filepath, NULL);
	if (w_text == NULL) {
		return 0;
	}

	if (GetFileAttributesExW(w_text, GetFileExInfoStandard, &data)) {
		last_write_time = data.ftLastWriteTime;
	}
	gb_free(a, w_text);

	li.LowPart = last_write_time.dwLowDateTime;
	li.HighPart = last_write_time.dwHighDateTime;
	return cast(gbFileTime)li.QuadPart;
}


gb_inline b32 gb_file_copy(char const *existing_filename, char const *new_filename, b32 fail_if_exists) {
	wchar_t *w_old = NULL;
	wchar_t *w_new = NULL;
	gbAllocator a = gb_heap_allocator();
	b32 result = false;

	w_old = gb__alloc_utf8_to_ucs2(a, existing_filename, NULL);
	if (w_old == NULL) {
		return false;
	}
	w_new = gb__alloc_utf8_to_ucs2(a, new_filename, NULL);
	if (w_new != NULL) {
		result = CopyFileW(w_old, w_new, fail_if_exists);
	}
	gb_free(a, w_new);
	gb_free(a, w_old);
	return result;
}

gb_inline b32 gb_file_move(char const *existing_filename, char const *new_filename) {
	wchar_t *w_old = NULL;
	wchar_t *w_new = NULL;
	gbAllocator a = gb_heap_allocator();
	b32 result = false;

	w_old = gb__alloc_utf8_to_ucs2(a, existing_filename, NULL);
	if (w_old == NULL) {
		return false;
	}
	w_new = gb__alloc_utf8_to_ucs2(a, new_filename, NULL);
	if (w_new != NULL) {
		result = MoveFileW(w_old, w_new);
	}
	gb_free(a, w_new);
	gb_free(a, w_old);
	return result;
}

b32 gb_file_remove(char const *filename) {
	wchar_t *w_filename = NULL;
	gbAllocator a = gb_heap_allocator();
	b32 result = false;
	w_filename = gb__alloc_utf8_to_ucs2(a, filename, NULL);
	if (w_filename == NULL) {
		return false;
	}
	result = DeleteFileW(w_filename);
	gb_free(a, w_filename);
	return result;
}



#else

gbFileTime gb_file_last_write_time(char const *filepath) {
	time_t result = 0;
	struct stat file_stat;

	if (stat(filepath, &file_stat) == 0) {
		result = file_stat.st_mtime;
	}

	return cast(gbFileTime)result;
}


gb_inline b32 gb_file_copy(char const *existing_filename, char const *new_filename, b32 fail_if_exists) {
#if defined(GB_SYSTEM_OSX)
	return copyfile(existing_filename, new_filename, NULL, COPYFILE_DATA) == 0;
#elif defined(GB_SYSTEM_LINUX) || defined(GB_SYSTEM_FREEBSD)
	isize size;
	int existing_fd = open(existing_filename, O_RDONLY, 0);
	int new_fd      = open(new_filename, O_WRONLY|O_CREAT, 0666);

	struct stat stat_existing;
	fstat(existing_fd, &stat_existing);
	size = sendfile(new_fd, existing_fd, 0, stat_existing.st_size);
	
	// set new handle to wanted size for safety
	int i = ftruncate(new_fd, size);
	GB_ASSERT(i == 0);

	close(new_fd);
	close(existing_fd);

	return size == stat_existing.st_size;
#else
	int new_flags = O_WRONLY | O_CREAT;
	if (fail_if_exists) {
		new_flags |= O_EXCL;
	}
	int existing_fd = open(existing_filename, O_RDONLY, 0);
	int new_fd      = open(new_filename, new_flags, 0666);

	struct stat stat_existing;
	if (fstat(existing_fd, &stat_existing) == -1) {
		return 0;
	}

	size_t bsize = stat_existing.st_blksize > BUFSIZ ? stat_existing.st_blksize : BUFSIZ;
	char *buf = (char *)gb_malloc(bsize);
	if (buf == NULL) {
		close(new_fd);
		close(existing_fd);
		return 0;
	}

	isize size = 0;
	ssize_t nread, nwrite, offset;
	while ((nread = read(existing_fd, buf, bsize)) != -1 && nread != 0) {
		for (offset = 0; nread; nread -= nwrite, offset += nwrite) {
			if ((nwrite = write(new_fd, buf + offset, nread)) == -1 || nwrite == 0) {
				free(buf);
				close(new_fd);
				close(existing_fd);
				return 0;
			}
			size += nwrite;
		}
	}
	
	gb_mfree(buf);
	close(new_fd);
	close(existing_fd);

	if (nread == -1) {
		return 0;
	}
	return size == stat_existing.st_size;
#endif
}

gb_inline b32 gb_file_move(char const *existing_filename, char const *new_filename) {
	if (link(existing_filename, new_filename) == 0) {
		return unlink(existing_filename) != -1;
	}
	return false;
}

b32 gb_file_remove(char const *filename) {
#if defined(GB_SYSTEM_OSX)
	return unlink(filename) != -1;
#else
	return remove(filename) == 0;
#endif
}


#endif





gbFileContents gb_file_read_contents(gbAllocator a, b32 zero_terminate, char const *filepath) {
	gbFileContents result = {0};
	gbFile file = {0};

	result.allocator = a;

	if (gb_file_open(&file, filepath) == gbFileError_None) {
		isize file_size = cast(isize)gb_file_size(&file);
		if (file_size > 0) {
			isize total_size = file_size + !!zero_terminate;
			total_size = (total_size+15)&~15;
			result.data = gb_alloc(a, total_size);
			result.size = file_size;
			gb_file_read_at(&file, result.data, result.size, 0);
			if (zero_terminate) {
				u8 *str = cast(u8 *)result.data;
				str[file_size] = '\0';
			}
		}
		gb_file_close(&file);
	}

	return result;
}

void gb_file_free_contents(gbFileContents *fc) {
    if (fc == NULL || fc->size == 0) return;
	GB_ASSERT_NOT_NULL(fc->data);
	gb_free(fc->allocator, fc->data);
	fc->data = NULL;
	fc->size = 0;
}





gb_inline b32 gb_path_is_absolute(char const *path) {
	b32 result = false;
	GB_ASSERT_NOT_NULL(path);
#if defined(GB_SYSTEM_WINDOWS)
	result == (gb_strlen(path) > 2) &&
	          gb_char_is_alpha(path[0]) &&
	          (path[1] == ':' && path[2] == GB_PATH_SEPARATOR);
#else
	result = (gb_strlen(path) > 0 && path[0] == GB_PATH_SEPARATOR);
#endif
	return result;
}

gb_inline b32 gb_path_is_relative(char const *path) { return !gb_path_is_absolute(path); }

gb_inline b32 gb_path_is_root(char const *path) {
	b32 result = false;
	GB_ASSERT_NOT_NULL(path);
#if defined(GB_SYSTEM_WINDOWS)
	result = gb_path_is_absolute(path) && (gb_strlen(path) == 3);
#else
	result = gb_path_is_absolute(path) && (gb_strlen(path) == 1);
#endif
	return result;
}

gb_inline char const *gb_path_base_name(char const *path) {
	char const *ls;
	GB_ASSERT_NOT_NULL(path);
	ls = gb_char_last_occurence(path, '/');
	return (ls == NULL) ? path : ls+1;
}

gb_inline char const *gb_path_extension(char const *path) {
	char const *ld;
	GB_ASSERT_NOT_NULL(path);
	ld = gb_char_last_occurence(path, '.');
	return (ld == NULL) ? NULL : ld+1;
}


#if !defined(_WINDOWS_) && defined(GB_SYSTEM_WINDOWS)
GB_DLL_IMPORT DWORD WINAPI GetFullPathNameA(char const *lpFileName, DWORD nBufferLength, char *lpBuffer, char **lpFilePart);
GB_DLL_IMPORT DWORD WINAPI GetFullPathNameW(wchar_t const *lpFileName, DWORD nBufferLength, wchar_t *lpBuffer, wchar_t **lpFilePart);
#endif

char *gb_path_get_full_name(gbAllocator a, char const *path) {
#if defined(GB_SYSTEM_WINDOWS)
// TODO(bill): Make UTF-8
	wchar_t *w_path = NULL;
	wchar_t *w_fullpath = NULL;
	isize w_len = 0;
	isize new_len = 0;
	isize new_len1 = 0;
	char *new_path = 0;
	w_path = gb__alloc_utf8_to_ucs2(gb_heap_allocator(), path, NULL);
	if (w_path == NULL) {
		return NULL;
	}
	w_len = GetFullPathNameW(w_path, 0, NULL, NULL);
	if (w_len == 0) {
		return NULL;
	}
	w_fullpath = gb_alloc_array(gb_heap_allocator(), wchar_t, w_len+1);
	GetFullPathNameW(w_path, cast(int)w_len, w_fullpath, NULL);
	w_fullpath[w_len] = 0;
	gb_free(gb_heap_allocator(), w_path);

	new_len = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, w_fullpath, cast(int)w_len, NULL, 0, NULL, NULL);
	if (new_len == 0) {
		gb_free(gb_heap_allocator(), w_fullpath);
		return NULL;
	}
	new_path = gb_alloc_array(a, char, new_len+1);
	new_len1 = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, w_fullpath, cast(int)w_len, new_path, cast(int)new_len, NULL, NULL);
	if (new_len1 == 0) {
		gb_free(gb_heap_allocator(), w_fullpath);
		gb_free(a, new_path);
		return NULL;
	}
	new_path[new_len] = 0;
	return new_path;
#else
	char *p, *result, *fullpath = NULL;
	isize len;
	fullpath = realpath(path, NULL);

	if (fullpath == NULL) {
		// NOTE(Jeroen): Path doesn't exist.
		if (gb_strlen(path) > 0 && path[0] == '/') {
			// But it is an absolute path, so return as-is.

			fullpath = (char *)path;
			len      = gb_strlen(fullpath) + 1;
			result   = gb_alloc_array(a, char, len + 1);

			gb_memmove(result, fullpath, len);
			result[len] = 0;

		} else {
			// Appears to be a relative path, so construct an absolute one relative to <cwd>.
			char cwd[4096];
			getcwd(&cwd[0], 4096);

			isize path_len = gb_strlen(path);
			isize cwd_len  = gb_strlen(cwd);
			len            = cwd_len + 1 + path_len + 1;
			result         = gb_alloc_array(a, char, len+1);

			gb_memmove(result, (void *)cwd, cwd_len);
			result[cwd_len] = '/';

			gb_memmove(result + cwd_len + 1, (void *)path, gb_strlen(path));
			result[len] = 0;

		}
	} else {
		len      = gb_strlen(fullpath) + 1;
		result   = gb_alloc_array(a, char, len + 1);
		gb_memmove(result, fullpath, len);
		result[len] = 0;
		free(fullpath);
	}
	return result;
#endif
}





////////////////////////////////////////////////////////////////
//
// Printing
//
//


isize gb_printf(char const *fmt, ...) {
	isize res;
	va_list va;
	va_start(va, fmt);
	res = gb_printf_va(fmt, va);
	va_end(va);
	return res;
}


isize gb_printf_err(char const *fmt, ...) {
	isize res;
	va_list va;
	va_start(va, fmt);
	res = gb_printf_err_va(fmt, va);
	va_end(va);
	return res;
}

isize gb_fprintf(struct gbFile *f, char const *fmt, ...) {
	isize res;
	va_list va;
	va_start(va, fmt);
	res = gb_fprintf_va(f, fmt, va);
	va_end(va);
	return res;
}

char *gb_bprintf(char const *fmt, ...) {
	va_list va;
	char *str;
	va_start(va, fmt);
	str = gb_bprintf_va(fmt, va);
	va_end(va);
	return str;
}

isize gb_snprintf(char *str, isize n, char const *fmt, ...) {
	isize res;
	va_list va;
	va_start(va, fmt);
	res = gb_snprintf_va(str, n, fmt, va);
	va_end(va);
	return res;
}



gb_inline isize gb_printf_va(char const *fmt, va_list va) {
	return gb_fprintf_va(gb_file_get_standard(gbFileStandard_Output), fmt, va);
}

gb_inline isize gb_printf_err_va(char const *fmt, va_list va) {
	return gb_fprintf_va(gb_file_get_standard(gbFileStandard_Error), fmt, va);
}

gb_inline isize gb_fprintf_va(struct gbFile *f, char const *fmt, va_list va) {
	char buf[4096];
	isize len = gb_snprintf_va(buf, gb_size_of(buf), fmt, va);
	char *new_buf = NULL;
	isize n = gb_size_of(buf);
	while (len < 0) {
		n <<= 1;
		gb_free(gb_heap_allocator(), new_buf);
		new_buf = gb_alloc_array(gb_heap_allocator(), char, n);;
		len = gb_snprintf_va(new_buf, n, fmt, va);
	}
	gb_file_write(f, buf, len-1); // NOTE(bill): prevent extra whitespace
	if (new_buf != NULL) {
		gb_free(gb_heap_allocator(), new_buf);
	}
	return len;
}


gb_inline char *gb_bprintf_va(char const *fmt, va_list va) {
	gb_thread_local gb_local_persist char buffer[4096];
	gb_snprintf_va(buffer, gb_size_of(buffer), fmt, va);
	return buffer;
}


enum {
	gbFmt_Minus     = GB_BIT(0),
	gbFmt_Plus      = GB_BIT(1),
	gbFmt_Alt       = GB_BIT(2),
	gbFmt_Space     = GB_BIT(3),
	gbFmt_Zero      = GB_BIT(4),

	gbFmt_Char      = GB_BIT(5),
	gbFmt_Short     = GB_BIT(6),
	gbFmt_Int       = GB_BIT(7),
	gbFmt_Long      = GB_BIT(8),
	gbFmt_Llong     = GB_BIT(9),
	gbFmt_Size      = GB_BIT(10),
	gbFmt_Intptr    = GB_BIT(11),

	gbFmt_Unsigned  = GB_BIT(12),
	gbFmt_Lower     = GB_BIT(13),
	gbFmt_Upper     = GB_BIT(14),


	gbFmt_Done      = GB_BIT(30),

	gbFmt_Ints = gbFmt_Char|gbFmt_Short|gbFmt_Int|gbFmt_Long|gbFmt_Llong|gbFmt_Size|gbFmt_Intptr
};

typedef struct {
	i32 base;
	i32 flags;
	i32 width;
	i32 precision;
} gbprivFmtInfo;


gb_internal isize gb__print_string(char *text, isize max_len, gbprivFmtInfo *info, char const *str) {
	// TODO(bill): Get precision and width to work correctly. How does it actually work?!
	// TODO(bill): This looks very buggy indeed.
	isize res = 0, len;
	isize remaining = max_len;

	if (info && info->precision >= 0) {
		len = gb_strnlen(str, info->precision);
	} else {
		len = gb_strlen(str);
	}

	if (info && (info->width == 0 || info->flags & gbFmt_Minus)) {
		if (info->precision > 0) {
			len = info->precision < len ? info->precision : len;
		}

		res += gb_strlcpy(text, str, len);

		if (info->width > res) {
			isize padding = info->width - len;
			char pad = (info->flags & gbFmt_Zero) ? '0' : ' ';
			while (padding --> 0 && remaining --> 0) {
				*text++ = pad, res++;
			}
		}
	} else {
		if (info && (info->width > res)) {
			isize padding = info->width - len;
			char pad = (info->flags & gbFmt_Zero) ? '0' : ' ';
			while (padding --> 0 && remaining --> 0) {
				*text++ = pad, res++;
			}
		}

		res += gb_strlcpy(text, str, len);
	}


	if (info) {
		if (info->flags & gbFmt_Upper) {
			gb_str_to_upper(text);
		} else if (info->flags & gbFmt_Lower) {
			gb_str_to_lower(text);
		}
	}

	return res;
}

gb_internal isize gb__print_char(char *text, isize max_len, gbprivFmtInfo *info, char arg) {
	char str[2] = "";
	str[0] = arg;
	return gb__print_string(text, max_len, info, str);
}


gb_internal isize gb__print_i64(char *text, isize max_len, gbprivFmtInfo *info, i64 value) {
	char num[130];
	gb_i64_to_str(value, num, info ? info->base : 10);
	return gb__print_string(text, max_len, info, num);
}

gb_internal isize gb__print_u64(char *text, isize max_len, gbprivFmtInfo *info, u64 value) {
	char num[130];
	gb_u64_to_str(value, num, info ? info->base : 10);
	return gb__print_string(text, max_len, info, num);
}


gb_internal isize gb__print_f64(char *text, isize max_len, gbprivFmtInfo *info, f64 arg) {
	// TODO(bill): Handle exponent notation
	isize width, len, remaining = max_len;
	char *text_begin = text;

	if (arg) {
		u64 value;
		if (arg < 0) {
			if (remaining > 1) {
				*text = '-', remaining--;
			}
			text++;
			arg = -arg;
		} else if (info->flags & gbFmt_Minus) {
			if (remaining > 1) {
				*text = '+', remaining--;
			}
			text++;
		}

		value = cast(u64)arg;
		len = gb__print_u64(text, remaining, NULL, value);
		text += len;

		if (len >= remaining) {
			remaining = gb_min(remaining, 1);
		} else {
			remaining -= len;
		}
		arg -= value;

		if (info->precision < 0) {
			info->precision = 6;
		}

		if ((info->flags & gbFmt_Alt) || info->precision > 0) {
			i64 mult = 10;
			if (remaining > 1) {
				*text = '.', remaining--;
			}
			text++;
			while (info->precision-- > 0) {
				value = cast(u64)(arg * mult);
				len = gb__print_u64(text, remaining, NULL, value);
				text += len;
				if (len >= remaining) {
					remaining = gb_min(remaining, 1);
				} else {
					remaining -= len;
				}
				arg -= cast(f64)value / mult;
				mult *= 10;
			}
		}
	} else {
		if (remaining > 1) {
			*text = '0', remaining--;
		}
		text++;
		if (info->flags & gbFmt_Alt) {
			if (remaining > 1) {
				*text = '.', remaining--;
			}
			text++;
		}
	}

	width = info->width - (text - text_begin);
	if (width > 0) {
		char fill = (info->flags & gbFmt_Zero) ? '0' : ' ';
		char *end = text+remaining-1;
		len = (text - text_begin);

		for (len = (text - text_begin); len--; ) {
			if ((text_begin+len+width) < end) {
				*(text_begin+len+width) = *(text_begin+len);
			}
		}

		len = width;
		text += len;
		if (len >= remaining) {
			remaining = gb_min(remaining, 1);
		} else {
			remaining -= len;
		}

		while (len--) {
			if (text_begin+len < end) {
				text_begin[len] = fill;
			}
		}
	}

	return (text - text_begin);
}



gb_no_inline isize gb_snprintf_va(char *text, isize max_len, char const *fmt, va_list va) {
	char const *text_begin = text;
	isize remaining = max_len, res;

	while (*fmt) {
		gbprivFmtInfo info = {0};
		isize len = 0;
		info.precision = -1;

		while (*fmt && *fmt != '%' && remaining) {
			*text++ = *fmt++;
		}

		if (*fmt == '%') {
			do {
				switch (*++fmt) {
				case '-': info.flags |= gbFmt_Minus; break;
				case '+': info.flags |= gbFmt_Plus;  break;
				case '#': info.flags |= gbFmt_Alt;   break;
				case ' ': info.flags |= gbFmt_Space; break;
				case '0': info.flags |= gbFmt_Zero;  break;
				default:  info.flags |= gbFmt_Done;  break;
				}
			} while (!(info.flags & gbFmt_Done));
		}

		// NOTE(bill): Optional Width
		if (*fmt == '*') {
			int width = va_arg(va, int);
			if (width < 0) {
				info.flags |= gbFmt_Minus;
				info.width = -width;
			} else {
				info.width = width;
			}
			fmt++;
		} else {
			info.width = cast(i32)gb_str_to_i64(fmt, cast(char **)&fmt, 10);
		}

		// NOTE(bill): Optional Precision
		if (*fmt == '.') {
			fmt++;
			if (*fmt == '*') {
				info.precision = va_arg(va, int);
				fmt++;
			} else {
				info.precision = cast(i32)gb_str_to_i64(fmt, cast(char **)&fmt, 10);
			}
			info.flags &= ~gbFmt_Zero;
		}


		switch (*fmt++) {
		case 'h':
			if (*fmt == 'h') { // hh => char
				info.flags |= gbFmt_Char;
				fmt++;
			} else { // h => short
				info.flags |= gbFmt_Short;
			}
			break;

		case 'l':
			if (*fmt == 'l') { // ll => long long
				info.flags |= gbFmt_Llong;
				fmt++;
			} else { // l => long
				info.flags |= gbFmt_Long;
			}
			break;

			break;

		case 'z': // NOTE(bill): usize
			info.flags |= gbFmt_Unsigned;
			// fallthrough
		case 't': // NOTE(bill): isize
			info.flags |= gbFmt_Size;
			break;

		default: fmt--; break;
		}


		switch (*fmt) {
		case 'u':
			info.flags |= gbFmt_Unsigned;
			// fallthrough
		case 'd':
		case 'i':
			info.base = 10;
			break;

		case 'o':
			info.base = 8;
			break;

		case 'x':
			info.base = 16;
			info.flags |= (gbFmt_Unsigned | gbFmt_Lower);
			break;

		case 'X':
			info.base = 16;
			info.flags |= (gbFmt_Unsigned | gbFmt_Upper);
			break;

		case 'f':
		case 'F':
		case 'g':
		case 'G':
			len = gb__print_f64(text, remaining, &info, va_arg(va, f64));
			break;

		case 'a':
		case 'A':
			// TODO(bill):
			break;

		case 'c':
			len = gb__print_char(text, remaining, &info, cast(char)va_arg(va, int));
			break;

		case 's':
			len = gb__print_string(text, remaining, &info, va_arg(va, char *));
			break;

		case 'p':
			info.base = 16;
			info.flags |= (gbFmt_Lower|gbFmt_Unsigned|gbFmt_Alt|gbFmt_Intptr);
			break;

		case '%':
			len = gb__print_char(text, remaining, &info, '%');
			break;

		default: fmt--; break;
		}

		fmt++;

		if (info.base != 0) {
			if (info.flags & gbFmt_Unsigned) {
				u64 value = 0;
				switch (info.flags & gbFmt_Ints) {
				case gbFmt_Char:   value = cast(u64)cast(u8) va_arg(va, int);       break;
				case gbFmt_Short:  value = cast(u64)cast(u16)va_arg(va, int);       break;
				case gbFmt_Long:   value = cast(u64)va_arg(va, unsigned long);      break;
				case gbFmt_Llong:  value = cast(u64)va_arg(va, unsigned long long); break;
				case gbFmt_Size:   value = cast(u64)va_arg(va, usize);              break;
				case gbFmt_Intptr: value = cast(u64)va_arg(va, uintptr);            break;
				default:             value = cast(u64)va_arg(va, unsigned int);       break;
				}

				len = gb__print_u64(text, remaining, &info, value);

			} else {
				i64 value = 0;
				switch (info.flags & gbFmt_Ints) {
				case gbFmt_Char:   value = cast(i64)cast(i8) va_arg(va, int); break;
				case gbFmt_Short:  value = cast(i64)cast(i16)va_arg(va, int); break;
				case gbFmt_Long:   value = cast(i64)va_arg(va, long);         break;
				case gbFmt_Llong:  value = cast(i64)va_arg(va, long long);    break;
				case gbFmt_Size:   value = cast(i64)va_arg(va, usize);        break;
				case gbFmt_Intptr: value = cast(i64)va_arg(va, uintptr);      break;
				default:             value = cast(i64)va_arg(va, int);          break;
				}

				len = gb__print_i64(text, remaining, &info, value);
			}
		}


		text += len;
		if (len >= remaining) {
			remaining = gb_min(remaining, 1);
		} else {
			remaining -= len;
		}
	}

	*text++ = '\0';
	res = (text - text_begin);
	return (res >= max_len || res < 0) ? -1 : res;
}


////////////////////////////////////////////////////////////////
//
// Time
//
//

#if defined(GB_COMPILER_MSVC) && !defined(__clang__)
	gb_inline u64 gb_rdtsc(void) { return __rdtsc(); }
#elif defined(__i386__)
	gb_inline u64 gb_rdtsc(void) {
		u64 x;
		__asm__ volatile (".byte 0x0f, 0x31" : "=A" (x));
		return x;
	}
#elif defined(__x86_64__)
	gb_inline u64 gb_rdtsc(void) {
		u32 hi, lo;
		__asm__ __volatile__ ("rdtsc" : "=a"(lo), "=d"(hi));
		return (cast(u64)lo) | ((cast(u64)hi)<<32);
	}
#elif defined(__powerpc__)
	gb_inline u64 gb_rdtsc(void) {
		u64 result = 0;
		u32 upper, lower,tmp;
		__asm__ volatile(
			"0:                   \n"
			"\tmftbu   %0         \n"
			"\tmftb    %1         \n"
			"\tmftbu   %2         \n"
			"\tcmpw    %2,%0      \n"
			"\tbne     0b         \n"
			: "=r"(upper),"=r"(lower),"=r"(tmp)
		);
		result = upper;
		result = result<<32;
		result = result|lower;

		return result;
	}
#elif defined(__aarch64__)
	gb_inline u64 gb_rdtsc(void) {
		int64_t virtual_timer_value;
		asm volatile("mrs %0, cntvct_el0" : "=r"(virtual_timer_value));
		return virtual_timer_value;
	}
#elif defined(__riscv)
	gb_inline u64 gb_rdtsc(void) {
		u64 result = 0;
		__asm__ volatile("rdcycle %0" : "=r"(result));
		return result;
	}
#else
#warning "gb_rdtsc not supported"
	gb_inline u64 gb_rdtsc(void) { return 0; }
#endif

#if defined(GB_SYSTEM_WINDOWS)

	gb_inline f64 gb_time_now(void) {
		gb_local_persist LARGE_INTEGER win32_perf_count_freq = {0};
		f64 result;
		LARGE_INTEGER counter;
		if (!win32_perf_count_freq.QuadPart) {
			QueryPerformanceFrequency(&win32_perf_count_freq);
			GB_ASSERT(win32_perf_count_freq.QuadPart != 0);
		}

		QueryPerformanceCounter(&counter);

		result = counter.QuadPart / cast(f64)(win32_perf_count_freq.QuadPart);
		return result;
	}

	gb_inline u64 gb_utc_time_now(void) {
		FILETIME ft;
		ULARGE_INTEGER li;

		GetSystemTimeAsFileTime(&ft);
		li.LowPart = ft.dwLowDateTime;
		li.HighPart = ft.dwHighDateTime;

		return li.QuadPart/10;
	}

	gb_inline void gb_sleep_ms(u32 ms) { Sleep(ms); }

#else

	gb_global f64 gb__timebase  = 0.0;
	gb_global u64 gb__timestart = 0;

	gb_inline f64 gb_time_now(void) {
#if defined(GB_SYSTEM_OSX)
		f64 result;

		if (!gb__timestart) {
			mach_timebase_info_data_t tb = {0};
			mach_timebase_info(&tb);
			gb__timebase = tb.numer;
			gb__timebase /= tb.denom;
			gb__timestart = mach_absolute_time();
		}

		// NOTE(bill): mach_absolute_time() returns things in nanoseconds
		result = 1.0e-9 * (mach_absolute_time() - gb__timestart) * gb__timebase;
		return result;
#else
		struct timespec t;
		f64 result;

		// IMPORTANT TODO(bill): THIS IS A HACK
		clock_gettime(1 /*CLOCK_MONOTONIC*/, &t);
		result = t.tv_sec + 1.0e-9 * t.tv_nsec;
		return result;
#endif
	}

	gb_inline u64 gb_utc_time_now(void) {
		struct timespec t;
#if defined(GB_SYSTEM_OSX)
		clock_serv_t cclock;
		mach_timespec_t mts;
		host_get_clock_service(mach_host_self(), CALENDAR_CLOCK, &cclock);
		clock_get_time(cclock, &mts);
		mach_port_deallocate(mach_task_self(), cclock);
		t.tv_sec = mts.tv_sec;
		t.tv_nsec = mts.tv_nsec;
#else
		// IMPORTANT TODO(bill): THIS IS A HACK
		clock_gettime(0 /*CLOCK_REALTIME*/, &t);
#endif
		return cast(u64)t.tv_sec * 1000000ull + t.tv_nsec/1000 + 11644473600000000ull;
	}

	gb_inline void gb_sleep_ms(u32 ms) {
		struct timespec req = {cast(time_t)ms/1000, cast(long)((ms%1000)*1000000)};
		struct timespec rem = {0, 0};
		nanosleep(&req, &rem);
	}

#endif




#if defined(GB_SYSTEM_WINDOWS)
gb_inline void gb_exit(u32 code) { ExitProcess(code); }
#else
gb_inline void gb_exit(u32 code) { exit(code); }
#endif

char const *gb_get_env(char const *name, gbAllocator allocator) {
	#if defined(GB_SYSTEM_WINDOWS)
		if (!name || !*name) {
			return NULL;
		} else {
			// TODO(bill): Should this be a Wide version?
			DWORD cap = 100;
			char *buf = gb_alloc_array(allocator, char, cap);
			for (;;) {
				DWORD n = GetEnvironmentVariableA(name, buf, cap-1);
				if (n == 0) {
					DWORD err = GetLastError();
					if (err == ERROR_ENVVAR_NOT_FOUND) {
						return NULL;
					}
				}

				if (n <= cap) {
					buf[n] = 0;
					return buf;
				}


				buf = cast(char *)gb_resize(allocator, buf, gb_size_of(char)*cap, gb_size_of(char)*cap*2);
				cap = cap*2;
			}
		}
	#else
		if (!name || !*name) {
			return NULL;
		} else {
			char const *res = getenv(name);
			if (!res) {
				return NULL;
			}
			return gb_alloc_str(allocator, res);
		}
	#endif
}


gb_inline void gb_set_env(char const *name, char const *value) {
#if defined(GB_SYSTEM_WINDOWS)
	// TODO(bill): Should this be a Wide version?
	SetEnvironmentVariableA(name, value);
#else
	setenv(name, value, 1);
#endif
}

gb_inline void gb_unset_env(char const *name) {
#if defined(GB_SYSTEM_WINDOWS)
	// TODO(bill): Should this be a Wide version?
	SetEnvironmentVariableA(name, NULL);
#else
	unsetenv(name);
#endif
}


gb_inline u16 gb_endian_swap16(u16 i) {
	return (i>>8) | (i<<8);
}

gb_inline u32 gb_endian_swap32(u32 i) {
	return (i>>24) |(i<<24) |
	       ((i&0x00ff0000u)>>8)  | ((i&0x0000ff00u)<<8);
}

gb_inline u64 gb_endian_swap64(u64 i) {
	return (i>>56) | (i<<56) |
	       ((i&0x00ff000000000000ull)>>40) | ((i&0x000000000000ff00ull)<<40) |
	       ((i&0x0000ff0000000000ull)>>24) | ((i&0x0000000000ff0000ull)<<24) |
	       ((i&0x000000ff00000000ull)>>8)  | ((i&0x00000000ff000000ull)<<8);
}


gb_inline isize gb_count_set_bits(u64 mask) {
	isize count = 0;
	while (mask) {
		count += (mask & 1);
		mask >>= 1;
	}
	return count;
}


#if defined(GB_COMPILER_MSVC)
#pragma warning(pop)
#endif

#if defined(__GCC__) || defined(__GNUC__)
#pragma GCC diagnostic pop
#endif


#if defined(__cplusplus)
}
#endif

#endif // GB_IMPLEMENTATION
