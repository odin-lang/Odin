package sdl2

import "core:c"

when ODIN_OS == .Windows {
	@(ignore_duplicates)
	foreign import lib "SDL2.lib"
} else {
	@(ignore_duplicates)
	foreign import lib "system:SDL2"
}

MUTEX_TIMEDOUT :: 1
MUTEX_MAXWAIT  :: ~u32(0)

mutex :: struct {}

semaphore :: struct {}
sem :: semaphore

cond :: struct {}

mutexP :: LockMutex
mutexV :: UnlockMutex

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	CreateMutex  :: proc() -> ^mutex ---
	LockMutex    :: proc(m: ^mutex) -> c.int ---
	TryLockMutex :: proc(m: ^mutex) -> c.int ---
	UnlockMutex  :: proc(m: ^mutex) -> c.int ---
	DestroyMutex :: proc(m: ^mutex) ---

	CreateSemaphore  :: proc(initial_value: u32) -> ^sem ---
	DestroySemaphore :: proc(s: ^sem) ---
	SemWait          :: proc(s: ^sem) -> c.int ---
	SemTryWait       :: proc(s: ^sem) -> c.int ---
	SemWaitTimeout   :: proc(s: ^sem, ms: u32) -> c.int ---
	SemPost          :: proc(s: ^sem) -> c.int ---
	SemValue         :: proc(s: ^sem) -> u32 ---

	CreateCond      :: proc() -> ^cond ---
	DestroyCond     :: proc(cv: ^cond) ---
	CondSignal      :: proc(cv: ^cond) -> c.int ---
	CondBroadcast   :: proc(cv: ^cond) -> c.int ---
	CondWait        :: proc(cv: ^cond, m: ^mutex) -> c.int ---
	CondWaitTimeout :: proc(cv: ^cond, m: ^mutex, ms: u32) -> c.int ---
}
