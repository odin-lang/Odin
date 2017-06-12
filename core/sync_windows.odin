#import win32 "sys/windows.odin" when ODIN_OS == "windows";
#import "atomics.odin";

const Semaphore = struct {
	_handle: win32.Handle,
}

const Mutex = struct {
	_semaphore: Semaphore,
	_counter:   i32,
	_owner:     i32,
	_recursion: i32,
}

const current_thread_id = proc() -> i32 {
	return i32(win32.get_current_thread_id());
}

const semaphore_init = proc(s: ^Semaphore) {
	s._handle = win32.create_semaphore_a(nil, 0, 1<<31-1, nil);
}

const semaphore_destroy = proc(s: ^Semaphore) {
	win32.close_handle(s._handle);
}

const semaphore_post = proc(s: ^Semaphore, count: int) {
	win32.release_semaphore(s._handle, i32(count), nil);
}

const semaphore_release = proc(s: ^Semaphore) #inline { semaphore_post(s, 1); }

const semaphore_wait = proc(s: ^Semaphore) {
	win32.wait_for_single_object(s._handle, win32.INFINITE);
}


const mutex_init = proc(m: ^Mutex) {
	atomics.store(&m._counter, 0);
	atomics.store(&m._owner, current_thread_id());
	semaphore_init(&m._semaphore);
	m._recursion = 0;
}
const mutex_destroy = proc(m: ^Mutex) {
	semaphore_destroy(&m._semaphore);
}
const mutex_lock = proc(m: ^Mutex) {
	var thread_id = current_thread_id();
	if atomics.fetch_add(&m._counter, 1) > 0 {
		if thread_id != atomics.load(&m._owner) {
			semaphore_wait(&m._semaphore);
		}
	}
	atomics.store(&m._owner, thread_id);
	m._recursion++;
}
const mutex_try_lock = proc(m: ^Mutex) -> bool {
	var thread_id = current_thread_id();
	if atomics.load(&m._owner) == thread_id {
		atomics.fetch_add(&m._counter, 1);
	} else {
		var expected: i32 = 0;
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
const mutex_unlock = proc(m: ^Mutex) {
	var recursion: i32;
	var thread_id = current_thread_id();
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

