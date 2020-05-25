// +build windows
package sync

import "core:sys/win32"

foreign import kernel32 "system:kernel32.lib"

// A lock that can only be held by one thread at once.
Mutex :: struct {
	_critical_section: win32.CRITICAL_SECTION,
}


// Blocks until signalled.
// When signalled, awakens exactly one waiting thread.
Condition :: struct {
	_handle: WIN32_CONDITION_VARIABLE,

	mutex: ^Mutex,
}

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
	// NOTE(tetra, 2019-10-30): WaitForSingleObject decrements the count before it returns.
	result := win32.WaitForSingleObject(s._handle, win32.INFINITE);
	assert(result != win32.WAIT_FAILED);
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

@private WIN32_CONDITION_VARIABLE :: distinct rawptr;
@private
foreign kernel32 {
	InitializeConditionVariable :: proc(ConditionVariable: ^WIN32_CONDITION_VARIABLE) ---
	WakeConditionVariable :: proc(ConditionVariable: ^WIN32_CONDITION_VARIABLE) ---
	WakeAllConditionVariable :: proc(ConditionVariable: ^WIN32_CONDITION_VARIABLE) ---
	SleepConditionVariableCS :: proc(ConditionVariable: ^WIN32_CONDITION_VARIABLE, CriticalSection: ^win32.CRITICAL_SECTION, dwMilliseconds: u32) -> b32 ---
}

condition_init :: proc(c: ^Condition, mutex: ^Mutex) -> bool {
	assert(mutex != nil);
	InitializeConditionVariable(&c._handle);
	c.mutex = mutex;
	return c._handle != nil;
}

condition_destroy :: proc(c: ^Condition) {
	if c._handle != nil {
		WakeAllConditionVariable(&c._handle);
	}
}

condition_signal :: proc(c: ^Condition) -> bool {
	if c._handle == nil {
		return false;
	}
	WakeConditionVariable(&c._handle);
	return true;
}

condition_broadcast :: proc(c: ^Condition) -> bool {
	if c._handle == nil {
		return false;
	}
	WakeAllConditionVariable(&c._handle);
	return true;
}

condition_wait_for :: proc(c: ^Condition) -> bool {
	return cast(bool)SleepConditionVariableCS(&c._handle, &c.mutex._critical_section, win32.INFINITE);
}
