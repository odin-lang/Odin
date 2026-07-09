// SPDX-FileCopyrightText: 2025 Erin Catto
// SPDX-License-Identifier: MIT

// Required on Linux to expose pthread_setname_np. Must be defined before any
// system header is included.
#if defined( __linux__ ) && !defined( _GNU_SOURCE )
#define _GNU_SOURCE
#endif

#include "core.h"

#include "box3d/base.h"

#include <stddef.h>
#include <stdio.h>
#include <string.h>

#define NAME_LENGTH 16

#if defined( _WIN32 )

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN 1
#endif

#include <Windows.h>
#include <limits.h>

static double s_invFrequency = 0.0;

uint64_t b3GetTicks( void )
{
	LARGE_INTEGER counter;
	QueryPerformanceCounter( &counter );
	return (uint64_t)counter.QuadPart;
}

float b3GetMilliseconds( uint64_t ticks )
{
	if ( s_invFrequency == 0.0 )
	{
		LARGE_INTEGER frequency;
		QueryPerformanceFrequency( &frequency );

		s_invFrequency = (double)frequency.QuadPart;
		if ( s_invFrequency > 0.0 )
		{
			s_invFrequency = 1000.0 / s_invFrequency;
		}
	}

	uint64_t ticksNow = b3GetTicks();
	return (float)( s_invFrequency * ( ticksNow - ticks ) );
}

float b3GetMillisecondsAndReset( uint64_t* ticks )
{
	if ( s_invFrequency == 0.0 )
	{
		LARGE_INTEGER frequency;
		QueryPerformanceFrequency( &frequency );

		s_invFrequency = (double)frequency.QuadPart;
		if ( s_invFrequency > 0.0 )
		{
			s_invFrequency = 1000.0 / s_invFrequency;
		}
	}

	uint64_t ticksNow = b3GetTicks();
	float ms = (float)( s_invFrequency * ( ticksNow - *ticks ) );
	*ticks = ticksNow;
	return ms;
}

void b3Yield( void )
{
	SwitchToThread();
}

void b3Sleep( int milliseconds )
{
	Sleep( (DWORD)milliseconds );
}

typedef struct b3Mutex
{
	CRITICAL_SECTION cs;
} b3Mutex;

b3Mutex* b3CreateMutex( void )
{
	b3Mutex* m = b3Alloc( sizeof( b3Mutex ) );
	InitializeCriticalSection( &m->cs );
	return m;
}

void b3DestroyMutex( b3Mutex* m )
{
	DeleteCriticalSection( &m->cs );
	*m = (b3Mutex){ 0 };
	b3Free( m, sizeof( b3Mutex ) );
}

void b3LockMutex( b3Mutex* m )
{
	EnterCriticalSection( &m->cs );
}

void b3UnlockMutex( b3Mutex* m )
{
	LeaveCriticalSection( &m->cs );
}

typedef struct b3Semaphore
{
	HANDLE semaphore;
} b3Semaphore;

b3Semaphore* b3CreateSemaphore( int initCount )
{
	b3Semaphore* s = b3Alloc( sizeof( b3Semaphore ) );
	s->semaphore = CreateSemaphoreExW( NULL, initCount, INT_MAX, NULL, 0, SEMAPHORE_ALL_ACCESS );
	return s;
}

void b3DestroySemaphore( b3Semaphore* s )
{
	CloseHandle( s->semaphore );
	*s = (b3Semaphore){ 0 };
	b3Free( s, sizeof( b3Semaphore ) );
}

void b3WaitSemaphore( b3Semaphore* s )
{
	WaitForSingleObjectEx( s->semaphore, INFINITE, FALSE );
}

void b3SignalSemaphore( b3Semaphore* s )
{
	ReleaseSemaphore( s->semaphore, 1, NULL );
}

typedef struct b3Thread
{
	HANDLE thread;
	b3ThreadFunction* function;
	void* context;
	char name[NAME_LENGTH];
} b3Thread;

typedef HRESULT( WINAPI* b3SetThreadDescriptionFn )( HANDLE, PCWSTR );

// SetThreadDescription exists on Windows 10 1607+. Resolve it dynamically so
// older Windows versions still link. Resolved once, cached for subsequent calls.
static void b3SetCurrentThreadName( const char* name )
{
	if ( name == NULL || name[0] == 0 )
	{
		return;
	}

	static b3SetThreadDescriptionFn pfn = NULL;
	static int resolved = 0;

	if ( resolved == 0 )
	{
		HMODULE kernel = GetModuleHandleW( L"kernel32.dll" );
		if ( kernel != NULL )
		{
			// MSVC /Wall warns C4191 on every FARPROC function-pointer cast.
			// This is the intended use of GetProcAddress, so suppress locally.
#pragma warning( push )
#pragma warning( disable : 4191 )
			pfn = (b3SetThreadDescriptionFn)GetProcAddress( kernel, "SetThreadDescription" );
#pragma warning( pop )
		}
		resolved = 1;
	}

	if ( pfn == NULL )
	{
		return;
	}

	wchar_t wide[NAME_LENGTH];
	int n = MultiByteToWideChar( CP_UTF8, 0, name, -1, wide, (int)( sizeof( wide ) / sizeof( wide[0] ) ) );
	if ( n > 0 )
	{
		pfn( GetCurrentThread(), wide );
	}
}

static DWORD WINAPI b3ThreadStart( LPVOID param )
{
	b3Thread* t = (b3Thread*)param;
	b3SetCurrentThreadName( t->name );
	t->function( t->context );
	return 0;
}

b3Thread* b3CreateThread( b3ThreadFunction* function, void* context, const char* name )
{
	b3Thread* t = b3Alloc( sizeof( b3Thread ) );
	t->function = function;
	t->context = context;
	if ( name != NULL )
	{
		snprintf( t->name, sizeof( t->name ), "%s", name );
	}
	else
	{
		t->name[0] = 0;
	}
	t->thread = CreateThread( NULL, 0, b3ThreadStart, t, 0, NULL );
	return t;
}

void b3JoinThread( b3Thread* t )
{
	WaitForSingleObject( t->thread, INFINITE );
	CloseHandle( t->thread );
	*t = (b3Thread){ 0 };
	b3Free( t, sizeof( b3Thread ) );
}

#elif defined( __linux__ ) || defined( __EMSCRIPTEN__ )

#include <sched.h>
#include <time.h>

uint64_t b3GetTicks( void )
{
	struct timespec ts;
	clock_gettime( CLOCK_MONOTONIC, &ts );
	return ts.tv_sec * 1000000000LL + ts.tv_nsec;
}

float b3GetMilliseconds( uint64_t ticks )
{
	uint64_t ticksNow = b3GetTicks();
	return (float)( ( ticksNow - ticks ) / 1000000.0 );
}

float b3GetMillisecondsAndReset( uint64_t* ticks )
{
	uint64_t ticksNow = b3GetTicks();
	float ms = (float)( ( ticksNow - *ticks ) / 1000000.0 );
	*ticks = ticksNow;
	return ms;
}

void b3Yield( void )
{
	sched_yield();
}

void b3Sleep( int milliseconds )
{
	struct timespec ts;
	ts.tv_sec = milliseconds / 1000;
	ts.tv_nsec = ( milliseconds % 1000 ) * 1000000L;
	nanosleep( &ts, NULL );
}

#include <pthread.h>
typedef struct b3Mutex
{
	pthread_mutex_t mtx;
} b3Mutex;

b3Mutex* b3CreateMutex( void )
{
	b3Mutex* m = b3Alloc( sizeof( b3Mutex ) );
	pthread_mutex_init( &m->mtx, NULL );
	return m;
}

void b3DestroyMutex( b3Mutex* m )
{
	pthread_mutex_destroy( &m->mtx );
	*m = (b3Mutex){ 0 };
	b3Free( m, sizeof( b3Mutex ) );
}

void b3LockMutex( b3Mutex* m )
{
	pthread_mutex_lock( &m->mtx );
}

void b3UnlockMutex( b3Mutex* m )
{
	pthread_mutex_unlock( &m->mtx );
}

#include <semaphore.h>

typedef struct b3Semaphore
{
	sem_t semaphore;
} b3Semaphore;

b3Semaphore* b3CreateSemaphore( int initCount )
{
	b3Semaphore* s = b3Alloc( sizeof( b3Semaphore ) );
	sem_init( &s->semaphore, 0, (unsigned int)initCount );
	return s;
}

void b3DestroySemaphore( b3Semaphore* s )
{
	sem_destroy( &s->semaphore );
	*s = (b3Semaphore){ 0 };
	b3Free( s, sizeof( b3Semaphore ) );
}

void b3WaitSemaphore( b3Semaphore* s )
{
	sem_wait( &s->semaphore );
}

void b3SignalSemaphore( b3Semaphore* s )
{
	sem_post( &s->semaphore );
}

typedef struct b3Thread
{
	pthread_t thread;
	b3ThreadFunction* function;
	void* context;
	char name[NAME_LENGTH];
} b3Thread;

static void b3SetCurrentThreadName( const char* name )
{
	if ( name == NULL || name[0] == 0 )
	{
		return;
	}

#if defined( __linux__ )
	// Linux caps thread names at 15 chars + null terminator.
	char truncated[NAME_LENGTH];
	snprintf( truncated, sizeof( truncated ), "%s", name );
	pthread_setname_np( pthread_self(), truncated );
#else
	(void)name;
#endif
}

static void* b3ThreadStart( void* param )
{
	b3Thread* t = (b3Thread*)param;
	b3SetCurrentThreadName( t->name );
	t->function( t->context );
	return NULL;
}

b3Thread* b3CreateThread( b3ThreadFunction* function, void* context, const char* name )
{
	b3Thread* t = b3Alloc( sizeof( b3Thread ) );
	t->function = function;
	t->context = context;
	if ( name != NULL )
	{
		snprintf( t->name, sizeof( t->name ), "%s", name );
	}
	else
	{
		t->name[0] = 0;
	}
	pthread_create( &t->thread, NULL, b3ThreadStart, t );
	return t;
}

void b3JoinThread( b3Thread* t )
{
	pthread_join( t->thread, NULL );
	*t = (b3Thread){ 0 };
	b3Free( t, sizeof( b3Thread ) );
}

#elif defined( __APPLE__ )

#include <mach/mach_time.h>
#include <sched.h>
#include <sys/time.h>
#include <time.h>

static double s_invFrequency = 0.0;

uint64_t b3GetTicks( void )
{
	return mach_absolute_time();
}

float b3GetMilliseconds( uint64_t ticks )
{
	if ( s_invFrequency == 0 )
	{
		mach_timebase_info_data_t timebase;
		mach_timebase_info( &timebase );

		// convert to ns then to ms
		s_invFrequency = 1e-6 * (double)timebase.numer / (double)timebase.denom;
	}

	uint64_t ticksNow = b3GetTicks();
	return (float)( s_invFrequency * ( ticksNow - ticks ) );
}

float b3GetMillisecondsAndReset( uint64_t* ticks )
{
	if ( s_invFrequency == 0 )
	{
		mach_timebase_info_data_t timebase;
		mach_timebase_info( &timebase );

		// convert to ns then to ms
		s_invFrequency = 1e-6 * (double)timebase.numer / (double)timebase.denom;
	}

	uint64_t ticksNow = b3GetTicks();
	float ms = (float)( s_invFrequency * ( ticksNow - *ticks ) );
	*ticks = ticksNow;
	return ms;
}

void b3Yield( void )
{
	sched_yield();
}

void b3Sleep( int milliseconds )
{
	struct timespec ts;
	ts.tv_sec = milliseconds / 1000;
	ts.tv_nsec = ( milliseconds % 1000 ) * 1000000L;
	nanosleep( &ts, NULL );
}

#include <pthread.h>
typedef struct b3Mutex
{
	pthread_mutex_t mtx;
} b3Mutex;

b3Mutex* b3CreateMutex( void )
{
	b3Mutex* m = b3Alloc( sizeof( b3Mutex ) );
	pthread_mutex_init( &m->mtx, NULL );
	return m;
}

void b3DestroyMutex( b3Mutex* m )
{
	pthread_mutex_destroy( &m->mtx );
	*m = (b3Mutex){ 0 };
	b3Free( m, sizeof( b3Mutex ) );
}

void b3LockMutex( b3Mutex* m )
{
	pthread_mutex_lock( &m->mtx );
}

void b3UnlockMutex( b3Mutex* m )
{
	pthread_mutex_unlock( &m->mtx );
}

#include <dispatch/dispatch.h>

typedef struct b3Semaphore
{
	dispatch_semaphore_t semaphore;
	int initialCount;
} b3Semaphore;

b3Semaphore* b3CreateSemaphore( int initCount )
{
	b3Semaphore* s = b3Alloc( sizeof( b3Semaphore ) );
	s->semaphore = dispatch_semaphore_create( (long)initCount );
	s->initialCount = initCount;
	return s;
}

void b3DestroySemaphore( b3Semaphore* s )
{
	// libdispatch aborts if the current count is less than the initial count at release time.
	// Pad with signals so the invariant always holds; no one is waiting at this point.
	for ( int i = 0; i < s->initialCount; ++i )
	{
		dispatch_semaphore_signal( s->semaphore );
	}
	dispatch_release( s->semaphore );
	*s = (b3Semaphore){ 0 };
	b3Free( s, sizeof( b3Semaphore ) );
}

void b3WaitSemaphore( b3Semaphore* s )
{
	dispatch_semaphore_wait( s->semaphore, DISPATCH_TIME_FOREVER );
}

void b3SignalSemaphore( b3Semaphore* s )
{
	dispatch_semaphore_signal( s->semaphore );
}

typedef struct b3Thread
{
	pthread_t thread;
	b3ThreadFunction* function;
	void* context;
	char name[NAME_LENGTH];
} b3Thread;

// macOS pthread_setname_np takes only the name — it always names the calling thread.
static void b3SetCurrentThreadName( const char* name )
{
	if ( name == NULL || name[0] == 0 )
	{
		return;
	}
	pthread_setname_np( name );
}

static void* b3ThreadStart( void* param )
{
	b3Thread* t = (b3Thread*)param;
	b3SetCurrentThreadName( t->name );
	t->function( t->context );
	return NULL;
}

b3Thread* b3CreateThread( b3ThreadFunction* function, void* context, const char* name )
{
	b3Thread* t = b3Alloc( sizeof( b3Thread ) );
	t->function = function;
	t->context = context;
	if ( name != NULL )
	{
		snprintf( t->name, sizeof( t->name ), "%s", name );
	}
	else
	{
		t->name[0] = 0;
	}
	pthread_create( &t->thread, NULL, b3ThreadStart, t );
	return t;
}

void b3JoinThread( b3Thread* t )
{
	pthread_join( t->thread, NULL );
	*t = (b3Thread){ 0 };
	b3Free( t, sizeof( b3Thread ) );
}

#else

uint64_t b3GetTicks( void )
{
	return 0;
}

float b3GetMilliseconds( uint64_t ticks )
{
	( (void)( ticks ) );
	return 0.0f;
}

float b3GetMillisecondsAndReset( uint64_t* ticks )
{
	( (void)( ticks ) );
	return 0.0f;
}

void b3Yield( void )
{
}

void b3Sleep( int milliseconds )
{
	( (void)( milliseconds ) );
}

typedef struct b3Mutex
{
	int dummy;
} b3Mutex;

b3Mutex* b3CreateMutex( void )
{
	b3Mutex* m = b3Alloc( sizeof( b3Mutex ) );
	m->dummy = 42;
	return m;
}

void b3DestroyMutex( b3Mutex* m )
{
	*m = (b3Mutex){ 0 };
	b3Free( m, sizeof( b3Mutex ) );
}

void b3LockMutex( b3Mutex* m )
{
	(void)m;
}

void b3UnlockMutex( b3Mutex* m )
{
	(void)m;
}

typedef struct b3Semaphore
{
	int dummy;
} b3Semaphore;

b3Semaphore* b3CreateSemaphore( int initCount )
{
	b3Semaphore* s = b3Alloc( sizeof( b3Semaphore ) );
	(void)initCount;
	s->dummy = 42;
	return s;
}

void b3DestroySemaphore( b3Semaphore* s )
{
	*s = (b3Semaphore){ 0 };
	b3Free( s, sizeof( b3Semaphore ) );
}

void b3WaitSemaphore( b3Semaphore* s )
{
	(void)s;
}

void b3SignalSemaphore( b3Semaphore* s )
{
	(void)s;
}

typedef struct b3Thread
{
	int dummy;
} b3Thread;

b3Thread* b3CreateThread( b3ThreadFunction* function, void* context, const char* name )
{
	(void)name;
	function( context );
	b3Thread* t = b3Alloc( sizeof( b3Thread ) );
	t->dummy = 42;
	return t;
}

void b3JoinThread( b3Thread* t )
{
	*t = (b3Thread){ 0 };
	b3Free( t, sizeof( b3Thread ) );
}

#endif

// djb2 hash, folded 8 bytes per iteration to shorten the dependency chain.
// memcpy lowers to a single load on most targets; on big-endian we byte-swap so
// the hash value is identical across endianness (preserving cross-platform determinism).
// Equivalent to byte-wise djb2 only in spirit; values differ from the original recurrence.
uint32_t b3Hash( uint32_t hash, const uint8_t* data, int count )
{
	uint32_t result = hash;
	int i = 0;

	while ( i + 8 <= count )
	{
		uint64_t word;
		memcpy( &word, data + i, sizeof( word ) );
#if defined( __BYTE_ORDER__ ) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
		word = ( ( word & 0x00000000000000FFULL ) << 56 ) | ( ( word & 0x000000000000FF00ULL ) << 40 ) |
			   ( ( word & 0x0000000000FF0000ULL ) << 24 ) | ( ( word & 0x00000000FF000000ULL ) << 8 ) |
			   ( ( word & 0x000000FF00000000ULL ) >> 8 ) | ( ( word & 0x0000FF0000000000ULL ) >> 24 ) |
			   ( ( word & 0x00FF000000000000ULL ) >> 40 ) | ( ( word & 0xFF00000000000000ULL ) >> 56 );
#endif
		result = ( result << 5 ) + result + (uint32_t)word;
		result = ( result << 5 ) + result + (uint32_t)( word >> 32 );
		i += 8;
	}

	while ( i < count )
	{
		result = ( result << 5 ) + result + data[i];
		i++;
	}

	return result;
}
