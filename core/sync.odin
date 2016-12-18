#import win32 "sys/windows.odin" when ODIN_OS == "windows";
#import "atomic.odin";

type Semaphore struct {
	handle win32.HANDLE;
}

type Mutex struct {
	semaphore Semaphore;
	counter   i32;
	owner     i32;
	recursion i32;
}


proc current_thread_id() -> i32 {
	return win32.GetCurrentThreadId() as i32;
}

proc semaphore_init(s ^Semaphore) {
	s.handle = win32.CreateSemaphoreA(nil, 0, 1<<31-1, nil);
}

proc semaphore_destroy(s ^Semaphore) {
	win32.CloseHandle(s.handle);
}

proc semaphore_post(s ^Semaphore, count int) {
	win32.ReleaseSemaphore(s.handle, count as i32, nil);
}

proc semaphore_release(s ^Semaphore) #inline { semaphore_post(s, 1); }

proc semaphore_wait(s ^Semaphore) {
	win32.WaitForSingleObject(s.handle, win32.INFINITE);
}


proc mutex_init(m ^Mutex) {
	atomic.store32(^m.counter, 0);
	atomic.store32(^m.owner, current_thread_id());
	semaphore_init(^m.semaphore);
	m.recursion = 0;
}
proc mutex_destroy(m ^Mutex) {
	semaphore_destroy(^m.semaphore);
}
proc mutex_lock(m ^Mutex) {
	thread_id := current_thread_id();
	if atomic.fetch_add32(^m.counter, 1) > 0 {
		if thread_id != atomic.load32(^m.owner) {
			semaphore_wait(^m.semaphore);
		}
	}
	atomic.store32(^m.owner, thread_id);
	m.recursion++;
}
proc mutex_try_lock(m ^Mutex) -> bool {
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
proc mutex_unlock(m ^Mutex) {
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

