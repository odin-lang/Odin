package sdl3

import "core:c"

Mutex     :: struct {}
RWLock    :: struct {}
Semaphore :: struct {}
Condition :: struct {}

InitStatus :: enum c.int {
	UNINITIALIZED,
	INITIALIZING,
	INITIALIZED,
	UNINITIALIZING,
}

InitState :: struct {
	status:   AtomicInt,
	thread:   ThreadID,
	reserved: rawptr,
}

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	CreateMutex             :: proc() -> ^Mutex ---
	@(synchronizes=.Acquire)
	LockMutex               :: proc(mutex: ^Mutex) ---
	@(synchronizes=.Acquire)
	TryLockMutex            :: proc(mutex: ^Mutex) -> bool ---
	@(synchronizes=.Release)
	UnlockMutex             :: proc(mutex: ^Mutex) ---
	DestroyMutex            :: proc(mutex: ^Mutex) ---

	CreateRWLock            :: proc() -> ^RWLock ---
	@(synchronizes_shared=.Acquire)
	LockRWLockForReading    :: proc(rwlock: ^RWLock) ---
	@(synchronizes=.Acquire)
	LockRWLockForWriting    :: proc(rwlock: ^RWLock) ---
	@(synchronizes_shared=.Acquire)
	TryLockRWLockForReading :: proc(rwlock: ^RWLock) -> bool ---
	@(synchronizes=.Acquire)
	TryLockRWLockForWriting :: proc(rwlock: ^RWLock) -> bool ---
	@(synchronizes=.Release)
	UnlockRWLock            :: proc(rwlock: ^RWLock) ---
	DestroyRWLock           :: proc(rwlock: ^RWLock) ---

	CreateSemaphore         :: proc(initial_value: Uint32) -> ^Semaphore ---
	DestroySemaphore        :: proc(sem: ^Semaphore) ---
	GetSemaphoreValue       :: proc(sem: ^Semaphore) -> Uint32 ---
	@(synchronizes=.Release)
	SignalSemaphore         :: proc(sem: ^Semaphore) ---
	@(synchronizes=.Acquire)
	TryWaitSemaphore        :: proc(sem: ^Semaphore) -> bool ---
	@(synchronizes=.Acquire)
	WaitSemaphore           :: proc(sem: ^Semaphore) ---
	@(synchronizes=.Acquire)
	WaitSemaphoreTimeout    :: proc(sem: ^Semaphore, timeout_ms: Sint32) ---

	CreateCondition         :: proc() -> ^Condition ---
	DestroyCondition        :: proc(cond: ^Condition) ---
	SignalCondition         :: proc(cond: ^Condition) ---
	BroadcastCondition      :: proc(cond: ^Condition) ---
	WaitCondition           :: proc(cond: ^Condition, mutex: ^Mutex) ---
	WaitConditionTimeout    :: proc(cond: ^Condition, mutex: ^Mutex, timeout_ms: Sint32) -> bool ---

	@(synchronizes=.Acquire)
	ShouldInit              :: proc(state: ^InitState) -> bool ---
	@(synchronizes=.Acquire)
	ShouldQuit              :: proc(state: ^InitState) -> bool ---
	@(synchronizes=.Release)
	SetInitialized          :: proc(state: ^InitState, initialized: bool) ---
}
