// Atomic analysis errors, and the errors for its attributes
package test_issues

import "base:intrinsics"

// Atomic writes to @(rodata)
@(rodata) read_only: u32 = 1
rodata_store :: proc() { intrinsics.atomic_store(&read_only, 2) } // error
rodata_load :: proc() -> u32 { return intrinsics.atomic_load(&read_only) }

// An atomic on what may be less aligned than its size
narrow: u32
Pair :: struct #align(8) {
	a, b: u32,
}
pair: Pair
misaligned :: proc() -> u64 { return intrinsics.atomic_load((^u64)(&narrow)) } // error
aligned :: proc() -> u64 { return intrinsics.atomic_load((^u64)(&pair.a)) }

// @(futex=...) and @(futex_parameter=...)
@(futex=.Wait)                         futex_no_pointer :: proc(word: u32) {}              // error
@(futex="wait")                        futex_string     :: proc(word: ^u32) {}             // error
@(futex=.Wake, futex_parameter="nope") futex_bad_name   :: proc(word: ^u32) {}             // error
@(futex_parameter="word")              futex_alone      :: proc(word: ^u32) {}             // error
@(futex=.Wait, futex_parameter="word") futex_named      :: proc(timeout: int, word: ^u32) {}

// @(synchronizes=...) and @(synchronizes_shared=...)
@(synchronizes)                                         sync_no_value  :: proc(m: ^u32) {} // error
@(synchronizes="acquire")                               sync_string    :: proc(m: ^u32) {} // error
@(synchronizes=.Relaxed)                                sync_relaxed   :: proc(m: ^u32) {} // error
@(synchronizes_shared=.Relaxed)                         shared_relaxed :: proc(m: ^u32) {} // error
@(synchronizes=.Acquire, synchronizes_shared=.Acquire)  sync_both      :: proc(m: ^u32) {} // error
@(synchronizes=.Acquire)                                sync_acquire   :: proc(m: ^u32) {}
@(synchronizes_shared=.Release)                         shared_release :: proc(m: ^u32) {}
