import (
	win32 "sys/windows.odin" when ODIN_OS == "windows";
	"atomics.odin";
)

Semaphore :: struct {
	_handle: win32.Handle;
}

/*
Mutex :: struct {
	_semaphore: Semaphore;
	_counter:   i32;
	_owner:     i32;
	_recursion: i32;
}
*/

Mutex :: struct {
	_critical_section: win32.Critical_Section;
}

current_thread_id :: proc() -> i32 {
	return i32(win32.get_current_thread_id());
}

semaphore_init :: proc(s: ^Semaphore) {
	s._handle = win32.create_semaphore_a(nil, 0, 1<<31-1, nil);
}

semaphore_destroy :: proc(s: ^Semaphore) {
	win32.close_handle(s._handle);
}

semaphore_post :: proc(s: ^Semaphore, count: int) {
	win32.release_semaphore(s._handle, i32(count), nil);
}

semaphore_release :: proc(s: ^Semaphore) #inline { semaphore_post(s, 1); }

semaphore_wait :: proc(s: ^Semaphore) {
	win32.wait_for_single_object(s._handle, win32.INFINITE);
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
	return win32.try_enter_critical_section(&m._critical_section) != 0;
}

mutex_unlock :: proc(m: ^Mutex) {
	win32.leave_critical_section(&m._critical_section);
}



/*
mutex_init :: proc(m: ^Mutex) {
	atomics.store(&m._counter, 0);
	atomics.store(&m._owner, current_thread_id());
	semaphore_init(&m._semaphore);
	m._recursion = 0;
}
mutex_destroy :: proc(m: ^Mutex) {
	semaphore_destroy(&m._semaphore);
}
mutex_lock :: proc(m: ^Mutex) {
	thread_id := current_thread_id();
	if atomics.fetch_add(&m._counter, 1) > 0 {
		if thread_id != atomics.load(&m._owner) {
			semaphore_wait(&m._semaphore);
		}
	}
	atomics.store(&m._owner, thread_id);
	m._recursion++;
}
mutex_try_lock :: proc(m: ^Mutex) -> bool {
	thread_id := current_thread_id();
	if atomics.load(&m._owner) == thread_id {
		atomics.fetch_add(&m._counter, 1);
	} else {
		expected: i32 = 0;
		if atomics.load(&m._counter) != 0 {
			return false;
		}
		if atomics.compare_exchange(&m._counter, expected, 1) == 0 {
			return false;
		}
		atomics.store(&m._owner, thread_id);
	}
	m._recursion++;
	return true;
}
mutex_unlock :: proc(m: ^Mutex) {
	recursion: i32;
	thread_id := current_thread_id();
	assert(thread_id == atomics.load(&m._owner));

	m._recursion--;
	recursion = m._recursion;
	if recursion == 0 {
		atomics.store(&m._owner, thread_id);
	}

	if atomics.fetch_add(&m._counter, -1) > 1 {
		if recursion == 0 {
			semaphore_release(&m._semaphore);
		}
	}
}
*/
