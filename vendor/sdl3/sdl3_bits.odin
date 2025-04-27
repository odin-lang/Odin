package sdl3

import "base:intrinsics"
import "core:c"

@(require_results)
MostSignificantBitIndex32 :: #force_inline proc "c" (x: Uint32) -> c.int {
	if x == 0 {
		return -1
	}
	return c.int(31 - intrinsics.count_leading_zeros(x))
}

@(require_results)
HasExactlyOneBitSet32 :: #force_inline proc "c" (x: Uint32) -> bool {
	return x != 0 && (x & (x - 1)) == 0
}