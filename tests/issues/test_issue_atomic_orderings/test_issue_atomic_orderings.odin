// The atomic memory ordering warnings, each next to a case which must stay quiet
package test_issues

import "base:intrinsics"
import "core:sync"

// A release store which only relaxed loads read
release_flag: u32
release_set :: proc() { intrinsics.atomic_store_explicit(&release_flag, 1, .Release) } // warning
release_get :: proc() -> u32 { return intrinsics.atomic_load_explicit(&release_flag, .Relaxed) }

// An acquire load of what only relaxed stores write
acquire_flag: u32
acquire_set :: proc() { intrinsics.atomic_store_explicit(&acquire_flag, 1, .Relaxed) }
acquire_get :: proc() -> u32 { return intrinsics.atomic_load_explicit(&acquire_flag, .Acquire) } // warning

// A release read-modify-write is no different, but one only read-modify-written, e.g. a counter, is fine
rmw_flag: u32
rmw_set :: proc() { intrinsics.atomic_add_explicit(&rmw_flag, 1, .Release) } // warning
rmw_get :: proc() -> u32 { return intrinsics.atomic_load_explicit(&rmw_flag, .Relaxed) }
counter: u32
counter_add :: proc() { intrinsics.atomic_add_explicit(&counter, 1, .Release) }
counter_take :: proc() -> u32 { return intrinsics.atomic_exchange_explicit(&counter, 0, .Relaxed) }

// Fine: the address escapes, so it may be accessed through it
escaped_flag: u32
escaped_ptr :: proc() -> ^u32 { return &escaped_flag }
escaped_set :: proc() { intrinsics.atomic_store_explicit(&escaped_flag, 1, .Release) }
escaped_get :: proc() -> u32 { return intrinsics.atomic_load_explicit(&escaped_flag, .Relaxed) }

// Fine: an acquire fence after the relaxed load, in the same procedure, in a callee, or in a caller
fenced_a, fenced_b, fenced_c: u32
fenced_set :: proc() {
	intrinsics.atomic_store_explicit(&fenced_a, 1, .Release)
	intrinsics.atomic_store_explicit(&fenced_b, 1, .Release)
	intrinsics.atomic_store_explicit(&fenced_c, 1, .Release)
}
acquire_fence :: proc() { intrinsics.atomic_thread_fence(.Acquire) }
fenced_here :: proc() -> u32 {
	v := intrinsics.atomic_load_explicit(&fenced_a, .Relaxed)
	intrinsics.atomic_thread_fence(.Acquire)
	return v
}
fenced_callee :: proc() -> u32 {
	v := intrinsics.atomic_load_explicit(&fenced_b, .Relaxed)
	acquire_fence()
	return v
}
fenced_peek :: proc() -> u32 { return intrinsics.atomic_load_explicit(&fenced_c, .Relaxed) }
fenced_caller :: proc() -> u32 {
	v := fenced_peek()
	acquire_fence()
	return v
}

// An acquire fence before the load, or in another arm of a branch, does not count
before_flag: u32
before_set :: proc() { intrinsics.atomic_store_explicit(&before_flag, 1, .Release) } // warning
before_get :: proc() -> u32 {
	intrinsics.atomic_thread_fence(.Acquire)
	return intrinsics.atomic_load_explicit(&before_flag, .Relaxed)
}
arm_flag: u32
arm_set :: proc() { intrinsics.atomic_store_explicit(&arm_flag, 1, .Release) } // warning
arm_get :: proc(c: bool) -> u32 {
	if c {
		return intrinsics.atomic_load_explicit(&arm_flag, .Relaxed)
	} else {
		intrinsics.atomic_thread_fence(.Acquire)
	}
	return 0
}

// A weak compare-exchange whose `ok` is ignored
weak: u32
weak_ignored :: proc() -> u32 { return intrinsics.atomic_compare_exchange_weak(&weak, 0, 1) } // warning
weak_used :: proc() -> bool {
	_, ok := intrinsics.atomic_compare_exchange_weak(&weak, 0, 1)
	return ok
}

// A futex woken before it is written
Event :: struct {
	state: sync.Futex,
}
wake_early :: proc(e: ^Event) {
	sync.futex_broadcast(&e.state) // warning
	intrinsics.atomic_store_explicit(&e.state, 1, .Release)
}
wake_after :: proc(e: ^Event) {
	intrinsics.atomic_store_explicit(&e.state, 1, .Release)
	sync.futex_broadcast(&e.state)
}
event_wait :: proc(e: ^Event) {
	for intrinsics.atomic_load_explicit(&e.state, .Acquire) == 0 {
		sync.futex_wait(&e.state, 0)
	}
}

// A signal fence where a thread fence would pair
signal_flag: u32
signal_set :: proc() { intrinsics.atomic_store_explicit(&signal_flag, 1, .Release) } // warning
signal_get :: proc() -> u32 {
	v := intrinsics.atomic_load_explicit(&signal_flag, .Relaxed)
	intrinsics.atomic_signal_fence(.Acquire)
	return v
}

// Atomics on a local which nothing else can reach
local_only :: proc() -> u32 {
	x: u32
	intrinsics.atomic_store(&x, 1) // warning
	return intrinsics.atomic_load(&x)
}
local_shared :: proc() -> u32 {
	x: u32
	local_store(&x)
	return intrinsics.atomic_load(&x)
}
local_store :: proc(p: ^u32) { intrinsics.atomic_store(p, 1) }

// Atomics on a @(thread_local) whose address is never taken
@(thread_local) tls_count: u32
tls_add :: proc() { intrinsics.atomic_add(&tls_count, 1) } // warning
@(thread_local) tls_shared: u32
tls_shared_ptr :: proc() -> ^u32 { return &tls_shared }
tls_shared_add :: proc() { intrinsics.atomic_add(&tls_shared, 1) }

// Mixing volatile and atomic accesses of the same location
mixed: u32
mixed_volatile :: proc() -> u32 { return intrinsics.volatile_load(&mixed) } // warning
mixed_atomic :: proc() -> u32 { return intrinsics.atomic_load(&mixed) }
mmio: u32
mmio_read :: proc() -> u32 { return intrinsics.volatile_load(&mmio) }

// Dekker-style store-then-load pairs, unless .Seq_Cst orders both sides
dekker_a, dekker_b: u32
dekker_1 :: proc() -> u32 {
	intrinsics.atomic_store_explicit(&dekker_a, 1, .Release) // warning
	return intrinsics.atomic_load_explicit(&dekker_b, .Acquire)
}
dekker_2 :: proc() -> u32 {
	intrinsics.atomic_store_explicit(&dekker_b, 1, .Release)
	return intrinsics.atomic_load_explicit(&dekker_a, .Acquire)
}
seq_a, seq_b: u32
seq_1 :: proc() -> u32 {
	intrinsics.atomic_store(&seq_a, 1)
	return intrinsics.atomic_load(&seq_b)
}
seq_2 :: proc() -> u32 {
	intrinsics.atomic_store(&seq_b, 1)
	return intrinsics.atomic_load(&seq_a)
}

// Accessing the same location atomically with different sizes
Pair :: struct #align(8) {
	a, b: u32,
}
pair: Pair
pair_narrow :: proc() -> u32 { return intrinsics.atomic_load(&pair.a) }
pair_wide :: proc() -> u64 { return intrinsics.atomic_load((^u64)(&pair.a)) } // warning
