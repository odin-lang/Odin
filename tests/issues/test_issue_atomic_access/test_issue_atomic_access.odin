// -vet-atomic-access: plain reads and writes of what is accessed atomically, and what synchronizes them
package test_issues

import "base:intrinsics"
import "core:sync"
import "core:thread"

Shared :: struct {
	m:     sync.Mutex,
	rw:    sync.RW_Mutex,
	c:     sync.Cond,
	count: int,
	ready: bool,
}

bump :: proc(s: ^Shared) { intrinsics.atomic_add(&s.count, 1) }

plain :: proc(s: ^Shared) -> int {
	s.count = 1    // error
	return s.count // error
}

// Within a lock, but not after it is unlocked
locked :: proc(s: ^Shared) -> int {
	sync.mutex_lock(&s.m)
	s.count = 1
	x := s.count
	sync.mutex_unlock(&s.m)
	return x + s.count // error
}

deferred_unlock :: proc(s: ^Shared) -> int {
	sync.mutex_lock(&s.m)
	defer sync.mutex_unlock(&s.m)
	return s.count
}

early_unlock :: proc(s: ^Shared, c: bool) -> int {
	sync.mutex_lock(&s.m)
	if c {
		sync.mutex_unlock(&s.m)
		return 0
	}
	x := s.count // fine, the unlock is in another branch
	sync.mutex_unlock(&s.m)
	return x
}

other_mutex :: proc(s: ^Shared, m: ^sync.Mutex) -> int {
	sync.mutex_lock(&s.m)
	sync.mutex_lock(m)
	sync.mutex_unlock(m)
	return s.count // fine, another mutex was unlocked
}

// A write is published by a release after it, but not by the unlock of a lock taken since
published :: proc(s: ^Shared) {
	s.count = 1
	t := thread.create(proc(_: ^thread.Thread) {})
	thread.start(t)
}

worker :: proc(s: ^Shared, wg: ^sync.Wait_Group) {
	s.count = 1
	sync.wait_group_done(wg)
}

before_lock :: proc(s: ^Shared) {
	s.count = 0 // error
	sync.mutex_lock(&s.m)
	sync.mutex_unlock(&s.m)
}

joined :: proc(s: ^Shared, t: ^thread.Thread) -> int {
	thread.join(t)
	return s.count
}

// A shared lock only covers reads
shared_read :: proc(s: ^Shared) -> int {
	sync.rw_mutex_shared_lock(&s.rw)
	defer sync.rw_mutex_shared_unlock(&s.rw)
	return s.count
}

shared_write :: proc(s: ^Shared) {
	sync.rw_mutex_shared_lock(&s.rw)
	s.count = 1 // error
	sync.rw_mutex_shared_unlock(&s.rw)
}

// Inferred for procedures without @(synchronizes=...), including a guard's deferred unlock
my_lock   :: proc(s: ^Shared) { sync.mutex_lock(&s.m) }
my_unlock :: proc(s: ^Shared) { sync.mutex_unlock(&s.m) }

wrapped :: proc(s: ^Shared) -> int {
	my_lock(s)
	x := s.count
	my_unlock(s)
	return x + s.count // error
}

wrapped_mixed :: proc(s: ^Shared) -> int {
	my_lock(s)
	x := s.count
	sync.mutex_unlock(&s.m)
	return x + s.count // error
}

guarded_bump :: proc(s: ^Shared) {
	sync.guard(&s.m)
	bump(s)
}

after_guard :: proc(s: ^Shared) -> int {
	guarded_bump(s)
	return s.count // error
}

// cond_wait relocks the mutex it is given
cond_waited :: proc(s: ^Shared) -> int {
	sync.mutex_lock(&s.m)
	for !s.ready {
		sync.cond_wait(&s.c, &s.m)
	}
	x := s.count
	sync.mutex_unlock(&s.m)
	return x + s.count // error
}

// What a call without arguments synchronizes on is not known, so it may release anything
global_count: int
@(synchronizes=.Acquire) lock_all   :: proc() {}
@(synchronizes=.Release) unlock_all :: proc() {}
global_bump :: proc() { intrinsics.atomic_add(&global_count, 1) }

unknown :: proc() -> int {
	lock_all()
	x := global_count
	unlock_all()
	return x + global_count // error
}

unknown_release :: proc(s: ^Shared) -> int {
	sync.mutex_lock(&s.m)
	x := s.count
	unlock_all()
	return x + s.count // error
}
