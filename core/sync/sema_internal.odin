//+private
package sync

import "core:time"


when #config(ODIN_SYNC_SEMA_USE_FUTEX, true) {
	_Sema :: struct {
		sema: Atomic_Sema,
	}

	_sema_post :: proc(s: ^Sema, count := 1) {
		atomic_sema_post(&s.impl.sema, count)
	}

	_sema_wait :: proc(s: ^Sema) {
		atomic_sema_wait(&s.impl.sema)
	}

	_sema_wait_with_timeout :: proc(s: ^Sema, duration: time.Duration) -> bool {
		return atomic_sema_wait_with_timeout(&s.impl.sema, duration)
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