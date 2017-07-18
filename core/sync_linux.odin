import (
	"atomics.odin";
	"os.odin";
)

Semaphore :: struct {
	// _handle: win32.Handle;
}

Mutex :: struct {
	_semaphore: Semaphore;
	_counter:   i32;
	_owner:     i32;
	_recursion: i32;
}

current_thread_id :: proc() -> i32 {
	return i32(os.current_thread_id());
}

semaphore_init :: proc(s: ^Semaphore) {
	// s._handle = win32.CreateSemaphoreA(nil, 0, 1<<31-1, nil);
}

semaphore_destroy :: proc(s: ^Semaphore) {
	// win32.CloseHandle(s._handle);
}

semaphore_post :: proc(s: ^Semaphore, count: int) {
	// win32.ReleaseSemaphore(s._handle, cast(i32)count, nil);
}

semaphore_release :: proc(s: ^Semaphore) #inline {
	semaphore_post(s, 1);
}

semaphore_wait :: proc(s: ^Semaphore) {
	// win32.WaitForSingleObject(s._handle, win32.INFINITE);
}


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
	m._recursion += 1;
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
	m._recursion += 1;
	return true;
}
mutex_unlock :: proc(m: ^Mutex) {
	recursion: i32;
	thread_id := current_thread_id();
	assert(thread_id == atomics.load(&m._owner));

	m._recursion -= 1;
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

