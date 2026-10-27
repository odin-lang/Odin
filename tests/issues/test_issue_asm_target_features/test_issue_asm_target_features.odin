#+build amd64
// An `asm` template is inlined into whatever calls it, so the target features it enables must be enabled there too:
// globally, or by the calling procedure. It enabling 'avx' lets it use 256-bit vectors, and each of the three calls
// which do not have 'avx' is one error, rather than an error from LLVM
package test_issue_asm_target_features

@(enable_target_feature="avx")
add_ps :: asm(a, b: #simd[8]f32) -> (r: #simd[8]f32) { vaddps r, a, b }

// At file scope
file_scope := add_ps(1, 2)

// The caller does not enable 'avx'
not_enabled :: proc() -> #simd[8]f32 {
	return add_ps(1, 2)
}

@(enable_target_feature="avx")
enabled :: proc() -> #simd[8]f32 {
	// A procedure literal does not take the features of the procedure it is within
	literal := proc() -> #simd[8]f32 {
		return add_ps(1, 2)
	}
	return add_ps(1, 2) + literal()
}

main :: proc() {
	_ = not_enabled()
	_ = enabled()
}
