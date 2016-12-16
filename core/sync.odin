#import win32 "sys/windows.odin" when ODIN_OS == "windows";
#import "atomic.odin";

Semaphore :: struct {
	handle: win32.HANDLE;
}

Mutex :: struct {
	semaphore: Semaphore;
	counter:   i32;
	owner:     i32;
	recursion: i32;
}


current_thread_id :: proc() -> i32 {
	return win32.GetCurrentThreadId() as i32;
}

semaphore_init :: proc(s: ^Semaphore) {
	s.handle = win32.CreateSemaphoreA(nil, 0, 1<<31-1, nil);
}

semaphore_destroy :: proc(s: ^Semaphore) {
	win32.CloseHandle(s.handle);
}

semaphore_post :: proc(s: ^Semaphore, count: int) {
	win32.ReleaseSemaphore(s.handle, count as i32, nil);
}

semaphore_release :: proc(s: ^Semaphore) #inline { semaphore_post(s, 1); }

semaphore_wait :: proc(s: ^Semaphore) {
	win32.WaitForSingleObject(s.handle, win32.INFINITE);
}


mutex_init :: proc(m: ^Mutex) {
	atomic.store32(^m.counter, 0);
	atomic.store32(^m.owner, current_thread_id());
	semaphore_init(^m.semaphore);
	m.recursion = 0;
}
mutex_destroy :: proc(m: ^Mutex) {
	semaphore_destroy(^m.semaphore);
}
mutex_lock :: proc(m: ^Mutex) {
	thread_id := current_thread_id();
	if atomic.fetch_add32(^m.counter, 1) > 0 {
		if thread_id != atomic.load32(^m.owner) {
			semaphore_wait(^m.semaphore);
		}
	}
	atomic.store32(^m.owner, thread_id);
	m.recursion++;
}
mutex_try_lock :: proc(m: ^Mutex) -> bool {
	thread_id := current_thread_id();
	if atomic.load32(^m.owner) == thread_id {
		atomic.fetch_add32(^m.counter, 1);
	} else {
		expected: i32 = 0;
		if atomic.load32(^m.counter) != 0 {
			return false;
		}
		if atomic.compare_exchange32(^m.counter, expected, 1) == 0 {
			return false;
		}
		atomic.store32(^m.owner, thread_id);
	}
	m.recursion++;
	return true;
}
mutex_unlock :: proc(m: ^Mutex) {
	recursion: i32;
	thread_id := current_thread_id();
	assert(thread_id == atomic.load32(^m.owner));

	m.recursion--;
	recursion = m.recursion;
	if recursion == 0 {
		atomic.store32(^m.owner, thread_id);
	}

	if atomic.fetch_add32(^m.counter, -1) > 1 {
		if recursion == 0 {
			semaphore_release(^m.semaphore);
		}
	}
}

