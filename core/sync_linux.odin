import (
	"atomics.odin";
	"os.odin";
)

Semaphore :: struct {
	// _handle: win32.Handle,
}

Mutex :: struct {
	_semaphore: Semaphore,
	_counter:   i32,
	_owner:     i32,
	_recursion: i32,
}

proc current_thread_id() -> i32 {
	return i32(os.current_thread_id());
}

proc semaphore_init(s: ^Semaphore) {
	// s._handle = win32.CreateSemaphoreA(nil, 0, 1<<31-1, nil);
}

proc semaphore_destroy(s: ^Semaphore) {
	// win32.CloseHandle(s._handle);
}

proc semaphore_post(s: ^Semaphore, count: int) {
	// win32.ReleaseSemaphore(s._handle, cast(i32)count, nil);
}

proc semaphore_release(s: ^Semaphore) #inline {
	semaphore_post(s, 1);
}

proc semaphore_wait(s: ^Semaphore) {
	// win32.WaitForSingleObject(s._handle, win32.INFINITE);
}


proc mutex_init(m: ^Mutex) {
	atomics.store(&m._counter, 0);
	atomics.store(&m._owner, current_thread_id());
	semaphore_init(&m._semaphore);
	m._recursion = 0;
}
proc mutex_destroy(m: ^Mutex) {
	semaphore_destroy(&m._semaphore);
}
proc mutex_lock(m: ^Mutex) {
	thread_id := current_thread_id();
	if atomics.fetch_add(&m._counter, 1) > 0 {
		if thread_id != atomics.load(&m._owner) {
			semaphore_wait(&m._semaphore);
		}
	}
	atomics.store(&m._owner, thread_id);
	m._recursion++;
}
proc mutex_try_lock(m: ^Mutex) -> bool {
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
proc mutex_unlock(m: ^Mutex) {
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

