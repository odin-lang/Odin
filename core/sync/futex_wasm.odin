//+private
//+build wasm32, wasm64p32
package sync

import "base:intrinsics"
import "core:time"

// NOTE: because `core:sync` is in the dependency chain of a lot of the core packages (mostly through `core:mem`)
// without actually calling into it much, I opted for a runtime panic instead of a compile error here.

_futex_wait :: proc "contextless" (f: ^Futex, expected: u32) -> bool {
	when !intrinsics.has_target_feature("atomics") {
		_panic("usage of `core:sync` requires the `-target-feature:\"atomics\"` or a `-microarch` that supports it")
	} else {
		s := intrinsics.wasm_memory_atomic_wait32((^u32)(f), expected, -1)
		return s != 0
	}
}

_futex_wait_with_timeout :: proc "contextless" (f: ^Futex, expected: u32, duration: time.Duration) -> bool {
	when !intrinsics.has_target_feature("atomics") {
		_panic("usage of `core:sync` requires the `-target-feature:\"atomics\"` or a `-microarch` that supports it")
	} else {
		s := intrinsics.wasm_memory_atomic_wait32((^u32)(f), expected, i64(duration))
		return s != 0
	}
}

_futex_signal :: proc "contextless" (f: ^Futex) {
	when !intrinsics.has_target_feature("atomics") {
		_panic("usage of `core:sync` requires the `-target-feature:\"atomics\"` or a `-microarch` that supports it")
	} else {
		loop: for {
			s := intrinsics.wasm_memory_atomic_notify32((^u32)(f), 1)
			if s >= 1 {
				return
			}
		}
	}
}

_futex_broadcast :: proc "contextless" (f: ^Futex) {
	when !intrinsics.has_target_feature("atomics") {
		_panic("usage of `core:sync` requires the `-target-feature:\"atomics\"` or a `-microarch` that supports it")
	} else {
		loop: for {
			s := intrinsics.wasm_memory_atomic_notify32((^u32)(f), ~u32(0))
			if s >= 0 {
				return
			}
		}
	}
}

