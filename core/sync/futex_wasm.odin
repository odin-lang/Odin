//+private
//+build wasm32, wasm64
package sync

import "core:intrinsics"
import "core:time"

_futex_wait :: proc(f: ^Futex, expected: u32) -> bool {
	s := intrinsics.wasm_memory_atomic_wait32((^u32)(f), expected, -1)
	return s != 0
}

_futex_wait_with_timeout :: proc(f: ^Futex, expected: u32, duration: time.Duration) -> bool {
	s := intrinsics.wasm_memory_atomic_wait32((^u32)(f), expected, i64(duration))
	return s != 0

}

_futex_signal :: proc(f: ^Futex) {
	loop: for {
		s := intrinsics.wasm_memory_atomic_notify32((^u32)(f), 1)
		if s >= 1 {
			return
		}
	}
}

_futex_broadcast :: proc(f: ^Futex) {
	loop: for {
		s := intrinsics.wasm_memory_atomic_notify32((^u32)(f), ~u32(0))
		if s >= 0 {
			return
		}
	}
}

