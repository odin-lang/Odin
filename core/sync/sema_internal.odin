//+private
package sync

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
			if original_count == atomic_compare_exchange_strong(&s.impl.count, original_count, original_count-1) {
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
			if original_count == atomic_compare_exchange_strong(&s.impl.count, original_count, original_count-1) {
				return true
			}
		}
	}
} else {
	_Sema :: struct {
		wg: Wait_Group,
	}

	_sema_post :: proc(s: ^Sema, count := 1) {
		wait_group_add(&s.impl.wg, count)
	}

	_sema_wait :: proc(s: ^Sema) {
		wait_group_wait(&s.impl.wg)
	}

	_sema_wait_with_timeout :: proc(s: ^Sema, duration: time.Duration) -> bool {
		return wait_group_wait_with_timeout(&s.impl.wg, duration)
	}
}