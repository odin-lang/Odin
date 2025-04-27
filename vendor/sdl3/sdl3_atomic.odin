package sdl3

import "base:intrinsics"
import "core:c"

SpinLock :: distinct c.int

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	@(require_results)
	TryLockSpinlock :: proc(lock: ^SpinLock) -> bool ---
	LockSpinlock    :: proc(lock: ^SpinLock) ---
	UnlockSpinlock  :: proc(lock: ^SpinLock) ---


	MemoryBarrierReleaseFunction :: proc() ---
	MemoryBarrierAcquireFunction :: proc() ---
}

MemoryBarrierRelease :: MemoryBarrierReleaseFunction
MemoryBarrierAcquire :: MemoryBarrierAcquireFunction

CPUPauseInstruction :: intrinsics.cpu_relax


AtomicInt :: distinct c.int
AtomicU32 :: distinct Uint32

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	CompareAndSwapAtomicInt :: proc(a: ^AtomicInt, oldval, newval: c.int) -> bool ---
	SetAtomicInt            :: proc(a: ^AtomicInt, v: c.int) -> int ---
	GetAtomicInt            :: proc(a: ^AtomicInt) -> int ---
	AddAtomicInt            :: proc(a: ^AtomicInt, v: c.int) -> int ---

	CompareAndSwapAtomicU32     :: proc(a: ^AtomicU32, oldval, newval: Uint32) -> bool ---
	SetAtomicU32                :: proc(a: ^AtomicU32, v: Uint32) -> Uint32 ---
	GetAtomicU32                :: proc(a: ^AtomicU32) -> Uint32 ---
	CompareAndSwapAtomicPointer :: proc(a: ^rawptr, oldval, newval: rawptr) -> bool ---
	SetAtomicPointer            :: proc(a: ^rawptr, v: rawptr) -> rawptr ---
	GetAtomicPointer            :: proc(a: ^rawptr) -> rawptr ---
}