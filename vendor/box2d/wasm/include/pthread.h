#pragma once

// Stand-in for <pthread.h> when building Box2D for Odin's WASM targets, which have no threads and no libc to provide them.
// Box2D only creates threads for a world with more than one worker and no task callbacks of its own, which WASM can't do,
// so everything here is single threaded: the mutex is a no-op and creating a thread fails.

typedef struct { int unused; } pthread_mutex_t;
typedef int pthread_t;

static inline int pthread_mutex_init( pthread_mutex_t* mutex, const void* attributes ) { (void)mutex; (void)attributes; return 0; }
static inline int pthread_mutex_destroy( pthread_mutex_t* mutex ) { (void)mutex; return 0; }
static inline int pthread_mutex_lock( pthread_mutex_t* mutex ) { (void)mutex; return 0; }
static inline int pthread_mutex_unlock( pthread_mutex_t* mutex ) { (void)mutex; return 0; }
static inline int pthread_create( pthread_t* thread, const void* attributes, void* ( *start )( void* ), void* argument )
{
	(void)thread; (void)attributes; (void)start; (void)argument;
	return 1;
}
static inline int pthread_join( pthread_t thread, void** result ) { (void)thread; (void)result; return 0; }
