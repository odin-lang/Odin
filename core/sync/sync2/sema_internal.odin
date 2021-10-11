package sync2

import "core:time"


when #config(ODIN_SYNC_SEMA_USE_FUTEX, true) {
	_Sema :: struct {
		count: Futex,
	}

	_sema_post :: proc(s: ^Sema, count := 1) {
		atomic_add(&s.impl.count, Futex(count))
		if count == 1 {
			futex_signal(&s.impl.count)
		} else {
			futex_broadcast(&s.impl.count)
		}
	}

	_sema_wait :: proc(s: ^Sema) {
		for {
			original_count := atomic_load(&s.impl.count)
			for original_count == 0 {
				futex_wait(&s.impl.count, u32(original_count))
				original_count = s.impl.count
			}
			if original_count == atomic_compare_exchange_strong(&s.impl.count, original_count-1, original_count) {
				return
			}
		}
	}

	_sema_wait_with_timeout :: proc(s: ^Sema, duration: time.Duration) -> bool {
		if duration <= 0 {
			return false
		}
		for {
		
			original_count := atomic_load(&s.impl.count)
			for start := time.tick_now(); original_count == 0; /**/ {
				remaining := duration - time.tick_since(start)
				if remaining < 0 {
					return false
				}
				
				if !futex_wait_with_timeout(&s.impl.count, u32(original_count), remaining) {
					return false
				}
				original_count = s.impl.count
			}
			if original_count == atomic_compare_exchange_strong(&s.impl.count, original_count-1, original_count) {
				return true
			}
		}
	}
} else {
	_Sema :: struct {
		mutex: Mutex,
		cond:  Cond,
		count: i32,
	}

	_sema_post :: proc(s: ^Sema, count := 1) {
		mutex_lock(&s.impl.mutex)
		defer mutex_unlock(&s.impl.mutex)
		
		s.impl.count += i32(count)
		if count == 1 {
			cond_signal(&s.impl.cond)
		} else {
			cond_broadcast(&s.impl.cond)
		}
	}

	_sema_wait :: proc(s: ^Sema) {
		mutex_lock(&s.impl.mutex)
		defer mutex_unlock(&s.impl.mutex)
		
		for s.impl.count == 0 {
			cond_wait(&s.impl.cond, &s.impl.mutex)
		}
		
		s.impl.count -= 1
		if s.impl.count > 0 {
			cond_signal(&s.impl.cond)
		}
	}

	_sema_wait_with_timeout :: proc(s: ^Sema, duration: time.Duration) -> bool {
		if duration <= 0 {
			return false
		}
		
		mutex_lock(&s.impl.mutex)
		defer mutex_unlock(&s.impl.mutex)
		
		start := time.tick_now()
		for s.impl.count == 0 {
			remaining := duration - time.tick_since(start)
			if remaining < 0 {
				return false
			}
			
			if !cond_wait_with_timeout(&s.impl.cond, &s.impl.mutex, remaining) {
				return false
			}
		}
		
		s.impl.count -= 1
		if s.impl.count > 0 {
			cond_signal(&s.impl.cond)
		}
		
		return true
	}
}