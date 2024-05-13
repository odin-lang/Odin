//+build amd64
package simd_x86

import "base:intrinsics"

cmpxchg16b :: #force_inline proc "c" (dst: ^u128, old, new: u128, $success, $failure: intrinsics.Atomic_Memory_Order) -> (val: u128) {
	return intrinsics.atomic_compare_exchange_strong_explicit(dst, old, new, success, failure)
}