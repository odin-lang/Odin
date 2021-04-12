//+build linux, darwin, freebsd
//+private
package sync2

when !#config(ODIN_SYNC_USE_PTHREADS, false) {

import "core:time"

_Mutex_State :: enum i32 {
	Unlocked = 0,
	Locked   = 1,
	Waiting  = 2,
}
_Mutex :: struct {
	state: _Mutex_State,
}

_mutex_lock :: proc(m: ^Mutex) {
	if atomic_xchg_rel(&m.impl.state, .Unlocked) != .Unlocked {
		_mutex_unlock_slow(m);
	}
}

_mutex_unlock :: proc(m: ^Mutex) {
	switch atomic_xchg_rel(&m.impl.state, .Unlocked) {
	case .Unlocked:
		unreachable();
	case .Locked:
		// Okay
	case .Waiting:
		_mutex_unlock_slow(m);
	}
}

_mutex_try_lock :: proc(m: ^Mutex) -> bool {
	_, ok := atomic_cxchg_acq(&m.impl.state, .Unlocked, .Locked);
	return ok;
}



_mutex_lock_slow :: proc(m: ^Mutex, curr_state: _Mutex_State) {
	new_state := curr_state; // Make a copy of it

	spin_lock: for spin in 0..<i32(100) {
		state, ok := atomic_cxchgweak_acq(&m.impl.state, .Unlocked, new_state);
		if ok {
			return;
		}

		if state == .Waiting {
			break spin_lock;
		}

		for i := min(spin+1, 32); i > 0; i -= 1 {
			cpu_relax();
		}
	}

	for {
		if atomic_xchg_acq(&m.impl.state, .Waiting) == .Unlocked {
			return;
		}

		// TODO(bill): Use a Futex here for Linux to improve performance and error handling
		cpu_relax();
	}
}


_mutex_unlock_slow :: proc(m: ^Mutex) {
	// TODO(bill): Use a Futex here for Linux to improve performance and error handling
}


RW_Mutex_State :: distinct uint;
RW_Mutex_State_Half_Width :: size_of(RW_Mutex_State)*8/2;
RW_Mutex_State_Is_Writing :: RW_Mutex_State(1);
RW_Mutex_State_Writer     :: RW_Mutex_State(1)<<1;
RW_Mutex_State_Reader     :: RW_Mutex_State(1)<<RW_Mutex_State_Half_Width;

RW_Mutex_State_Writer_Mask :: RW_Mutex_State(1<<(RW_Mutex_State_Half_Width-1) - 1) << 1;
RW_Mutex_State_Reader_Mask :: RW_Mutex_State(1<<(RW_Mutex_State_Half_Width-1) - 1) << RW_Mutex_State_Half_Width;


_RW_Mutex :: struct {
	state: RW_Mutex_State,
	mutex: Mutex,
	sema:  Sema,
}

_rw_mutex_lock :: proc(rw: ^RW_Mutex) {
	_ = atomic_add(&rw.impl.state, RW_Mutex_State_Writer);
	mutex_lock(&rw.impl.mutex);

	state := atomic_or(&rw.impl.state, RW_Mutex_State_Writer);
	if state & RW_Mutex_State_Reader_Mask != 0 {
		sema_wait(&rw.impl.sema);
	}
}

_rw_mutex_unlock :: proc(rw: ^RW_Mutex) {
	_ = atomic_and(&rw.impl.state, ~RW_Mutex_State_Is_Writing);
	mutex_unlock(&rw.impl.mutex);
}

_rw_mutex_try_lock :: proc(rw: ^RW_Mutex) -> bool {
	if mutex_try_lock(&rw.impl.mutex) {
		state := atomic_load(&rw.impl.state);
		if state & RW_Mutex_State_Reader_Mask == 0 {
			_ = atomic_or(&rw.impl.state, RW_Mutex_State_Is_Writing);
			return true;
		}

		mutex_unlock(&rw.impl.mutex);
	}
	return false;
}

_rw_mutex_shared_lock :: proc(rw: ^RW_Mutex) {
	state := atomic_load(&rw.impl.state);
	for state & (RW_Mutex_State_Is_Writing|RW_Mutex_State_Writer_Mask) == 0 {
		ok: bool;
		state, ok = atomic_cxchgweak(&rw.impl.state, state, state + RW_Mutex_State_Reader);
		if ok {
			return;
		}
	}

	mutex_lock(&rw.impl.mutex);
	_ = atomic_add(&rw.impl.state, RW_Mutex_State_Reader);
	mutex_unlock(&rw.impl.mutex);
}

_rw_mutex_shared_unlock :: proc(rw: ^RW_Mutex) {
	state := atomic_sub(&rw.impl.state, RW_Mutex_State_Reader);

	if (state & RW_Mutex_State_Reader_Mask == RW_Mutex_State_Reader) &&
	   (state & RW_Mutex_State_Is_Writing != 0) {
	   	sema_post(&rw.impl.sema);
	}
}

_rw_mutex_try_shared_lock :: proc(rw: ^RW_Mutex) -> bool {
	state := atomic_load(&rw.impl.state);
	if state & (RW_Mutex_State_Is_Writing|RW_Mutex_State_Writer_Mask) == 0 {
		_, ok := atomic_cxchg(&rw.impl.state, state, state + RW_Mutex_State_Reader);
		if ok {
			return true;
		}
	}
	if mutex_try_lock(&rw.impl.mutex) {
		_ = atomic_add(&rw.impl.state, RW_Mutex_State_Reader);
		mutex_unlock(&rw.impl.mutex);
		return true;
	}

	return false;
}



Queue_Item :: struct {
	next: ^Queue_Item,
	futex: i32,
}

queue_item_wait :: proc(item: ^Queue_Item) {
	for atomic_load_acq(&item.futex) == 0 {
		// TODO(bill): Use a Futex here for Linux to improve performance and error handling
		cpu_relax();
	}
}
queue_item_signal :: proc(item: ^Queue_Item) {
	atomic_store_rel(&item.futex, 1);
	// TODO(bill): Use a Futex here for Linux to improve performance and error handling
}


_Cond :: struct {
	queue_mutex: Mutex,
	queue_head:  ^Queue_Item,
	pending:     bool,
}

_cond_wait :: proc(c: ^Cond, m: ^Mutex) {
	waiter := &Queue_Item{};

	mutex_lock(&c.impl.queue_mutex);
	waiter.next = c.impl.queue_head;
	c.impl.queue_head = waiter;

	atomic_store(&c.impl.pending, true);
	mutex_unlock(&c.impl.queue_mutex);

	mutex_unlock(m);
	queue_item_wait(waiter);
	mutex_lock(m);
}

_cond_wait_with_timeout :: proc(c: ^Cond, m: ^Mutex, timeout: time.Duration) -> bool {
	// TODO(bill): _cond_wait_with_timeout for unix
	return false;
}

_cond_signal :: proc(c: ^Cond) {
	if !atomic_load(&c.impl.pending) {
		return;
	}

	mutex_lock(&c.impl.queue_mutex);
	waiter := c.impl.queue_head;
	if c.impl.queue_head != nil {
		c.impl.queue_head = c.impl.queue_head.next;
	}
	atomic_store(&c.impl.pending, c.impl.queue_head != nil);
	mutex_unlock(&c.impl.queue_mutex);

	if waiter != nil {
		queue_item_signal(waiter);
	}
}

_cond_broadcast :: proc(c: ^Cond) {
	if !atomic_load(&c.impl.pending) {
		return;
	}

	atomic_store(&c.impl.pending, false);

	mutex_lock(&c.impl.queue_mutex);
	waiters := c.impl.queue_head;
	c.impl.queue_head = nil;
	mutex_unlock(&c.impl.queue_mutex);

	for waiters != nil {
		queue_item_signal(waiters);
		waiters = waiters.next;
	}
}


} // !ODIN_SYNC_USE_PTHREADS
