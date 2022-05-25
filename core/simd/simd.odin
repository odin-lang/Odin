package simd

import "core:intrinsics"

add        :: intrinsics.simd_add
sub        :: intrinsics.simd_sub
mul        :: intrinsics.simd_mul
div        :: intrinsics.simd_div
rem        :: intrinsics.simd_rem

// Keeps Odin's Behaviour
// (x << y) if y <= mask else 0
shl        :: intrinsics.simd_shl
shr        :: intrinsics.simd_shr

// Similar to C's Behaviour
// x << (y & mask)
shl_masked :: intrinsics.simd_shl_masked
shr_masked :: intrinsics.simd_shr_masked

and     :: intrinsics.simd_and
or      :: intrinsics.simd_or
xor     :: intrinsics.simd_xor
neg     :: intrinsics.simd_neg
abs     :: intrinsics.simd_abs
min     :: intrinsics.simd_min
max     :: intrinsics.simd_max
eq      :: intrinsics.simd_eq
ne      :: intrinsics.simd_ne
lt      :: intrinsics.simd_lt
le      :: intrinsics.simd_le
gt      :: intrinsics.simd_gt
ge      :: intrinsics.simd_ge
extract :: intrinsics.simd_extract
replace :: intrinsics.simd_replace

reduce_add_ordered :: intrinsics.simd_reduce_add_ordered
reduce_mul_ordered :: intrinsics.simd_reduce_mul_ordered
reduce_min         :: intrinsics.simd_reduce_min
reduce_max         :: intrinsics.simd_reduce_max
reduce_and         :: intrinsics.simd_reduce_and
reduce_or          :: intrinsics.simd_reduce_or
reduce_xor         :: intrinsics.simd_reduce_xor

splat :: #force_inline proc "contextless" ($T: typeid/#simd[$LANES]$E, value: E) -> T {
	return T{0..<LANES = value}
}

to_array_ptr :: #force_inline proc "contextless" (v: ^#simd[$LANES]$E) -> ^[LANES]E {
	return (^[LANES]E)(v)
}
to_array :: #force_inline proc "contextless" (v: #simd[$LANES]$E) -> [LANES]E {
	return transmute([LANES]E)(v)
}
from_array :: #force_inline proc "contextless" (v: $A/[$LANES]$E) -> #simd[LANES]E where LANES & (LANES-1) == 0 {
	return transmute(#simd[LANES]E)v
}

from_slice :: proc($T: typeid/#simd[$LANES]$E, slice: []E) -> T where LANES & (LANES-1) == 0 {
	assert(len(slice) >= LANES, "slice length must be a least the number of lanes")
	array: [LANES]E
	#no_bounds_check for i in 0..<LANES {
		array[i] = slice[i]
	}
	return transmute(T)array
}
