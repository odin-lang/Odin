// +build windows
package sync

import win32 "core:sys/windows"
import "core:time"


// When waited upon, blocks until the internal count is greater than zero, then subtracts one.
// Posting to the semaphore increases the count by one, or the provided amount.
Semaphore :: struct {
	_handle: win32.HANDLE,
}

semaphore_init :: proc(s: ^Semaphore, initial_count := 0) {
	s._handle = win32.CreateSemaphoreW(nil, i32(initial_count), 1<<31-1, nil);
}

semaphore_destroy :: proc(s: ^Semaphore) {
	win32.CloseHandle(s._handle);
}

semaphore_post :: proc(s: ^Semaphore, count := 1) {
	win32.ReleaseSemaphore(s._handle, i32(count), nil);
}

semaphore_wait_for :: proc(s: ^Semaphore) {
	// NOTE(tetra, 2019-10-30): wait_for_single_object decrements the count before it returns.
	result := win32.WaitForSingleObject(s._handle, win32.INFINITE);
	assert(result != win32.WAIT_FAILED);
}


Mutex :: struct {
	_critical_section: win32.CRITICAL_SECTION,
}


mutex_init :: proc(m: ^Mutex, spin_count := 0) {
	win32.InitializeCriticalSectionAndSpinCount(&m._critical_section, u32(spin_count));
}

mutex_destroy :: proc(m: ^Mutex) {
	win32.DeleteCriticalSection(&m._critical_section);
}

mutex_lock :: proc(m: ^Mutex) {
	win32.EnterCriticalSection(&m._critical_section);
}

mutex_try_lock :: proc(m: ^Mutex) -> bool {
	return bool(win32.TryEnterCriticalSection(&m._critical_section));
}

mutex_unlock :: proc(m: ^Mutex) {
	win32.LeaveCriticalSection(&m._critical_section);
}

Blocking_Mutex :: struct {
	_handle: win32.SRWLOCK,
}


blocking_mutex_init :: proc(m: ^Blocking_Mutex) {
	win32.InitializeSRWLock(&m._handle);
}

blocking_mutex_destroy :: proc(m: ^Blocking_Mutex) {
	//
}

blocking_mutex_lock :: proc(m: ^Blocking_Mutex) {
	win32.AcquireSRWLockExclusive(&m._handle);
}

blocking_mutex_try_lock :: proc(m: ^Blocking_Mutex) -> bool {
	return bool(win32.TryAcquireSRWLockExclusive(&m._handle));
}

blocking_mutex_unlock :: proc(m: ^Blocking_Mutex) {
	win32.ReleaseSRWLockExclusive(&m._handle);
}


// Blocks until signalled.
// When signalled, awakens exactly one waiting thread.
Condition :: struct {
	_handle: win32.CONDITION_VARIABLE,

	mutex: Condition_Mutex_Ptr,
}


condition_init :: proc(c: ^Condition, mutex: Condition_Mutex_Ptr) -> bool {
	assert(mutex != nil);
	win32.InitializeConditionVariable(&c._handle);
	c.mutex = mutex;
	return true;
}

condition_destroy :: proc(c: ^Condition) {
	//
}

condition_signal :: proc(c: ^Condition) -> bool {
	if c._handle.ptr == nil {
		return false;
	}
	win32.WakeConditionVariable(&c._handle);
	return true;
}

condition_broadcast :: proc(c: ^Condition) -> bool {
	if c._handle.ptr == nil {
		return false;
	}
	win32.WakeAllConditionVariable(&c._handle);
	return true;
}

condition_wait_for :: proc(c: ^Condition) -> bool {
	switch m in &c.mutex {
	case ^Mutex:
		return cast(bool)win32.SleepConditionVariableCS(&c._handle, &m._critical_section, win32.INFINITE);
	case ^Blocking_Mutex:
		return cast(bool)win32.SleepConditionVariableSRW(&c._handle, &m._handle, win32.INFINITE, 0);
	}
	return false;
}
condition_wait_for_timeout :: proc(c: ^Condition, duration: time.Duration) -> bool {
	ms := win32.DWORD((max(time.duration_nanoseconds(duration), 0) + 999999)/1000000);
	switch m in &c.mutex {
	case ^Mutex:
		return cast(bool)win32.SleepConditionVariableCS(&c._handle, &m._critical_section, ms);
	case ^Blocking_Mutex:
		return cast(bool)win32.SleepConditionVariableSRW(&c._handle, &m._handle, ms, 0);
	}
	return false;
}




RW_Lock :: struct {
	_handle: win32.SRWLOCK,
}

rw_lock_init :: proc(l: ^RW_Lock) {
	l._handle = win32.SRWLOCK_INIT;
}
rw_lock_destroy :: proc(l: ^RW_Lock) {
	//
}
rw_lock_read :: proc(l: ^RW_Lock) {
	win32.AcquireSRWLockShared(&l._handle);
}
rw_lock_try_read :: proc(l: ^RW_Lock) -> bool {
	return bool(win32.TryAcquireSRWLockShared(&l._handle));
}
rw_lock_write :: proc(l: ^RW_Lock) {
	win32.AcquireSRWLockExclusive(&l._handle);
}
rw_lock_try_write :: proc(l: ^RW_Lock) -> bool {
	return bool(win32.TryAcquireSRWLockExclusive(&l._handle));
}
rw_lock_read_unlock :: proc(l: ^RW_Lock) {
	win32.ReleaseSRWLockShared(&l._handle);
}
rw_lock_write_unlock :: proc(l: ^RW_Lock) {
	win32.ReleaseSRWLockExclusive(&l._handle);
}


thread_yield :: proc() {
	win32.SwitchToThread();
}

