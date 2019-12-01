// +build windows
package sync

import "core:sys/win32"

// A lock that can only be held by one thread at once.
Mutex :: struct {
	_critical_section: win32.Critical_Section,
}

// Blocks until signalled.
// When signalled, awakens exactly one waiting thread.
Condition :: struct {
	event: win32.Handle,
}

// When waited upon, blocks until the internal count is greater than zero, then subtracts one.
// Posting to the semaphore increases the count by one, or the provided amount.
Semaphore :: struct {
	_handle: win32.Handle,
}


semaphore_init :: proc(s: ^Semaphore, initial_count := 0) {
	s._handle = win32.create_semaphore_w(nil, i32(initial_count), 1<<31-1, nil);
}

semaphore_destroy :: proc(s: ^Semaphore) {
	win32.close_handle(s._handle);
}

semaphore_post :: proc(s: ^Semaphore, count := 1) {
	win32.release_semaphore(s._handle, i32(count), nil);
}

semaphore_wait_for :: proc(s: ^Semaphore) {
	// NOTE(tetra, 2019-10-30): wait_for_single_object decrements the count before it returns.
	result := win32.wait_for_single_object(s._handle, win32.INFINITE);
	assert(result != win32.WAIT_FAILED);
}


mutex_init :: proc(m: ^Mutex, spin_count := 0) {
	win32.initialize_critical_section_and_spin_count(&m._critical_section, u32(spin_count));
}

mutex_destroy :: proc(m: ^Mutex) {
	win32.delete_critical_section(&m._critical_section);
}

mutex_lock :: proc(m: ^Mutex) {
	win32.enter_critical_section(&m._critical_section);
}

mutex_try_lock :: proc(m: ^Mutex) -> bool {
	return bool(win32.try_enter_critical_section(&m._critical_section));
}

mutex_unlock :: proc(m: ^Mutex) {
	win32.leave_critical_section(&m._critical_section);
}


condition_init :: proc(using c: ^Condition) {
	// create an auto-reset event.
	// NOTE(tetra, 2019-10-30): this will, when signalled, signal exactly one waiting thread
	// and then reset itself automatically.
	event = win32.create_event_w(nil, false, false, nil);
	assert(event != nil);
}

condition_destroy :: proc(using c: ^Condition) {
	if event != nil {
		win32.close_handle(event);
	}
}

condition_signal :: proc(using c: ^Condition) {
	ok := win32.set_event(event);
	assert(bool(ok));
}

condition_wait_for :: proc(using c: ^Condition) {
	result := win32.wait_for_single_object(event, win32.INFINITE);
	assert(result != win32.WAIT_FAILED);
}