package sdl3

Mutex     :: struct {}
RWLock    :: struct {}
Semaphore :: struct {}

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	CreateMutex             :: proc() -> ^Mutex ---
	LockMutex               :: proc(mutex: ^Mutex) ---
	TryLockMutex            :: proc(mutex: ^Mutex) -> bool ---
	UnlockMutex             :: proc(mutex: ^Mutex) ---
	DestroyMutex            :: proc(mutex: ^Mutex) ---

	CreateRWLock            :: proc() -> ^RWLock ---
	LockRWLockForReading    :: proc(rwlock: ^RWLock) ---
	LockRWLockForWriting    :: proc(rwlock: ^RWLock) ---
	TryLockRWLockForReading :: proc(rwlock: ^RWLock) -> bool ---
	TryLockRWLockForWriting :: proc(rwlock: ^RWLock) -> bool ---
	UnlockRWLock            :: proc(rwlock: ^RWLock) ---
	DestroyRWLock           :: proc(rwlock: ^RWLock) ---

	CreateSemaphore         :: proc(initial_value: Uint32) -> ^Semaphore ---
	DestroySemaphore        :: proc(sem: ^Semaphore) ---
	GetSemaphoreValue       :: proc(sem: ^Semaphore) -> Uint32 ---
	SignalSemaphore         :: proc(sem: ^Semaphore) ---
	TryWaitSemaphore        :: proc(sem: ^Semaphore) -> bool ---
	WaitSemaphore           :: proc(sem: ^Semaphore) ---
	WaitSemaphoreTimeout    :: proc(sem: ^Semaphore, timeout_ms: Sint32) ---
}
