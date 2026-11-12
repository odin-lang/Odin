#pragma once

// Stand-in for <semaphore.h>, see pthread.h next to it.

typedef struct { int count; } sem_t;

static inline int sem_init( sem_t* semaphore, int shared, unsigned int value ) { (void)shared; semaphore->count = (int)value; return 0; }
static inline int sem_destroy( sem_t* semaphore ) { (void)semaphore; return 0; }
static inline int sem_wait( sem_t* semaphore ) { semaphore->count -= 1; return 0; }
static inline int sem_post( sem_t* semaphore ) { semaphore->count += 1; return 0; }
