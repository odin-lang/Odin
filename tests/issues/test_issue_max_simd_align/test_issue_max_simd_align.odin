package test_issues

import "core:testing"

// align_of() caps a vector alignment at max_simd_align (16 on arm64 and darwin_amd64, 8 on arm32),
// below LLVM's natural alignment for a 32-byte vector (32)

V :: #simd[8]i32
v: V

// val is as aligned as V requires and never aligned to size_of(V)
@(align=size_of(V)) vector_holder: struct { _: [align_of(V)]u8, val: V }

@(export)
vector_load_low_bits :: #force_no_inline proc (p: ^V) -> uintptr {
	v = p^
	return uintptr(p) & (size_of(V) - 1)
}

@(export)
vector_store_low_bits :: #force_no_inline proc (p: ^V) -> uintptr {
	p^ = v
	return uintptr(p) & (size_of(V) - 1)
}

@(export)
vector_zero_low_bits :: #force_no_inline proc (p: ^V) -> uintptr {
	p^ = {}
	return uintptr(p) & (size_of(V) - 1)
}

@(test)
test_vector_access_below_natural_alignment :: proc(t: ^testing.T) {
	when align_of(V) < size_of(V) {
		p := &vector_holder.val
		testing.expect_value(t, vector_load_low_bits(p),  uintptr(align_of(V)))
		testing.expect_value(t, vector_store_low_bits(p), uintptr(align_of(V)))
		testing.expect_value(t, vector_zero_low_bits(p),  uintptr(align_of(V)))
	}
}
