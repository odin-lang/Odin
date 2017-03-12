#import win32 "sys/windows.odin" when ODIN_OS == "windows";
#import "atomic.odin";

Semaphore :: struct {
	_handle: win32.Handle,
}

Mutex :: struct {
	_semaphore: Semaphore,
	_counter:   i32,
	_owner:     i32,
	_recursion: i32,
}

current_thread_id :: proc() -> i32 {
	return cast(i32)win32.GetCurrentThreadId();
}

semaphore_init :: proc(s: ^Semaphore) {
	s._handle = win32.CreateSemaphoreA(nil, 0, 1<<31-1, nil);
}

semaphore_destroy :: proc(s: ^Semaphore) {
	win32.CloseHandle(s._handle);
}

semaphore_post :: proc(s: ^Semaphore, count: int) {
	win32.ReleaseSemaphore(s._handle, cast(i32)count, nil);
}

semaphore_release :: proc(s: ^Semaphore) #inline { semaphore_post(s, 1); }

semaphore_wait :: proc(s: ^Semaphore) {
	win32.WaitForSingleObject(s._handle, win32.INFINITE);
}


mutex_init :: proc(m: ^Mutex) {
	atomic.store(^m._counter, 0);
	atomic.store(^m._owner, current_thread_id());
	semaphore_init(^m._semaphore);
	m._recursion = 0;
}
mutex_destroy :: proc(m: ^Mutex) {
	semaphore_destroy(^m._semaphore);
}
mutex_lock :: proc(m: ^Mutex) {
	thread_id := current_thread_id();
	if atomic.fetch_add(^m._counter, 1) > 0 {
		if thread_id != atomic.load(^m._owner) {
			semaphore_wait(^m._semaphore);
		}
	}
	atomic.store(^m._owner, thread_id);
	m._recursion++;
}
mutex_try_lock :: proc(m: ^Mutex) -> bool {
	thread_id := current_thread_id();
	if atomic.load(^m._owner) == thread_id {
		atomic.fetch_add(^m._counter, 1);
	} else {
		expected: i32 = 0;
		if atomic.load(^m._counter) != 0 {
			return false;
		}
		if atomic.compare_exchange(^m._counter, expected, 1) == 0 {
			return false;
		}
		atomic.store(^m._owner, thread_id);
	}
	m._recursion++;
	return true;
}
mutex_unlock :: proc(m: ^Mutex) {
	recursion: i32;
	thread_id := current_thread_id();
	assert(thread_id == atomic.load(^m._owner));

	m._recursion--;
	recursion = m._recursion;
	if recursion == 0 {
		atomic.store(^m._owner, thread_id);
	}

	if atomic.fetch_add(^m._counter, -1) > 1 {
		if recursion == 0 {
			semaphore_release(^m._semaphore);
		}
	}
}

