// +build windows
package sync

import win32 "core:sys/windows"


Mutex :: struct {
	_handle: win32.SRWLOCK,

}

Recursive_Mutex :: struct {
	_handle: win32.CRITICAL_SECTION,
}


// Blocks until signalled.
// When signalled, awakens exactly one waiting thread.
Condition :: struct {
	_handle: win32.CONDITION_VARIABLE,

	mutex: ^Mutex,
}

// When waited upon, blocks until the internal count is greater than zero, then subtracts one.
// Posting to the semaphore increases the count by one, or the provided amount.
Semaphore :: struct {
	_handle: win32.HANDLE,
}


semaphore_init :: proc(s: ^Semaphore, initial_count := 0) {
	s._handle = win32.CreateSemaphoreW(nil, win32.LONG(initial_count), 1<<31-1, nil);
}

semaphore_destroy :: proc(s: ^Semaphore) {
	win32.CloseHandle(s._handle);
}

semaphore_post :: proc(s: ^Semaphore, count := 1) {
	win32.ReleaseSemaphore(s._handle, win32.LONG(count), nil);
}

semaphore_wait_for :: proc(s: ^Semaphore) {
	// NOTE(tetra, 2019-10-30): WaitForSingleObject decrements the count before it returns.
	result := win32.WaitForSingleObject(s._handle, win32.INFINITE);
	assert(result != win32.WAIT_FAILED);
}


mutex_init :: proc(m: ^Mutex, spin_count := 0) {
	win32.InitializeSRWLock(&m._handle);
}

mutex_destroy :: proc(m: ^Mutex) {
	win32.ReleaseSRWLockExclusive(&m._handle);
}

mutex_lock :: proc(m: ^Mutex) {
	win32.AcquireSRWLockExclusive(&m._handle);
}

mutex_try_lock :: proc(m: ^Mutex) -> bool {
	return bool(win32.TryAcquireSRWLockExclusive(&m._handle));
}

mutex_unlock :: proc(m: ^Mutex) {
	win32.ReleaseSRWLockExclusive(&m._handle);
}


recursive_mutex_init :: proc(m: ^Recursive_Mutex, spin_count := 0) {
	win32.InitializeCriticalSectionAndSpinCount(&m._handle, u32(spin_count));
}

recursive_mutex_destroy :: proc(m: ^Recursive_Mutex) {
	win32.DeleteCriticalSection(&m._handle);
}

recursive_mutex_lock :: proc(m: ^Recursive_Mutex) {
	win32.EnterCriticalSection(&m._handle);
}

recursive_mutex_try_lock :: proc(m: ^Recursive_Mutex) -> bool {
	return bool(win32.TryEnterCriticalSection(&m._handle));
}

recursive_mutex_unlock :: proc(m: ^Recursive_Mutex) {
	win32.LeaveCriticalSection(&m._handle);
}

condition_init :: proc(c: ^Condition, mutex: ^Mutex) -> bool {
	assert(mutex != nil);
	win32.InitializeConditionVariable(&c._handle);
	c.mutex = mutex;
	return true;
}

condition_destroy :: proc(c: ^Condition) {
	// Does nothing
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
	res := win32.SleepConditionVariableSRW(&c._handle, &c.mutex._handle, win32.INFINITE, 0);
	return bool(res);
}
