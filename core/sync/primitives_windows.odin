#+build windows
#+private
package sync

import "core:time"
import win32 "core:sys/windows"

_current_thread_id :: proc "contextless" () -> int {
	return int(win32.GetCurrentThreadId())
}

_Mutex :: struct {
	srwlock: win32.SRWLOCK,
}

_mutex_lock :: proc "contextless" (m: ^Mutex) {
	win32.AcquireSRWLockExclusive(&m.impl.srwlock)
}

_mutex_unlock :: proc "contextless" (m: ^Mutex) {
	win32.ReleaseSRWLockExclusive(&m.impl.srwlock)
}

_mutex_try_lock :: proc "contextless" (m: ^Mutex) -> bool {
	return bool(win32.TryAcquireSRWLockExclusive(&m.impl.srwlock))
}

_RW_Mutex :: struct {
	srwlock: win32.SRWLOCK,
}

_rw_mutex_lock :: proc "contextless" (rw: ^RW_Mutex) {
	win32.AcquireSRWLockExclusive(&rw.impl.srwlock)
}

_rw_mutex_unlock :: proc "contextless" (rw: ^RW_Mutex) {
	win32.ReleaseSRWLockExclusive(&rw.impl.srwlock)
}

_rw_mutex_try_lock :: proc "contextless" (rw: ^RW_Mutex) -> bool {
	return bool(win32.TryAcquireSRWLockExclusive(&rw.impl.srwlock))
}

_rw_mutex_shared_lock :: proc "contextless" (rw: ^RW_Mutex) {
	win32.AcquireSRWLockShared(&rw.impl.srwlock)
}

_rw_mutex_shared_unlock :: proc "contextless" (rw: ^RW_Mutex) {
	win32.ReleaseSRWLockShared(&rw.impl.srwlock)
}

_rw_mutex_try_shared_lock :: proc "contextless" (rw: ^RW_Mutex) -> bool {
	return bool(win32.TryAcquireSRWLockShared(&rw.impl.srwlock))
}


_Cond :: struct {
	cond: win32.CONDITION_VARIABLE,
}

_cond_wait :: proc "contextless" (c: ^Cond, m: ^Mutex) {
	_ = win32.SleepConditionVariableSRW(&c.impl.cond, &m.impl.srwlock, win32.INFINITE, 0)
}

_cond_wait_with_timeout :: proc "contextless" (c: ^Cond, m: ^Mutex, duration: time.Duration) -> bool {
	duration := u32(duration / time.Millisecond)
	ok := win32.SleepConditionVariableSRW(&c.impl.cond, &m.impl.srwlock, duration, 0)
	return bool(ok)
}


_cond_signal :: proc "contextless" (c: ^Cond) {
	win32.WakeConditionVariable(&c.impl.cond)
}

_cond_broadcast :: proc "contextless" (c: ^Cond) {
	win32.WakeAllConditionVariable(&c.impl.cond)
}

