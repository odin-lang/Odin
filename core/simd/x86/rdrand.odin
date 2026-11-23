#+build i386, amd64
package simd_x86

// Read a hardware generated 16-bit random value and store the result in `val`.
// Return 1 if a random value was generated, and 0 otherwise.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_rdrand16_step)
@(require_results, enable_target_feature="rdrnd")
_rdrand16_step :: #force_inline proc "c" (val: ^u16) -> b32 {
	v, flag := llvm_rdrand16_step()
	val^ = v
	return flag
}

// Read a hardware generated 32-bit random value and store the result in `val`.
// Return 1 if a random value was generated, and 0 otherwise.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_rdrand32_step)
@(require_results, enable_target_feature="rdrnd")
_rdrand32_step :: #force_inline proc "c" (val: ^u32) -> b32 {
	v, flag := llvm_rdrand32_step()
	val^ = v
	return flag
}

// Read a 16-bit NIST SP800-90B and SP800-90C compliant random value and store in `val`.
// Return 1 if a random value was generated, and 0 otherwise.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_rdseed16_step)
@(require_results, enable_target_feature="rdseed")
_rdseed16_step :: #force_inline proc "c" (val: ^u16) -> b32 {
	v, flag := llvm_rdseed16_step()
	val^ = v
	return flag
}

// Read a 32-bit NIST SP800-90B and SP800-90C compliant random value and store in `val`.
// Return 1 if a random value was generated, and 0 otherwise.
//
// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_rdseed32_step)
@(require_results, enable_target_feature="rdseed")
_rdseed32_step :: #force_inline proc "c" (val: ^u32) -> b32 {
	v, flag := llvm_rdseed32_step()
	val^ = v
	return flag
}

when ODIN_ARCH == .amd64 {
	// Read a hardware generated 64-bit random value and store the result in `val`.
	// Return 1 if a random value was generated, and 0 otherwise.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_rdrand64_step)
	@(require_results, enable_target_feature="rdrnd")
	_rdrand64_step :: #force_inline proc "c" (val: ^u64) -> b32 {
		v, flag := llvm_rdrand64_step()
		val^ = v
		return flag
	}

	// Read a 64-bit NIST SP800-90B and SP800-90C compliant random value and store in `val`.
	// Return 1 if a random value was generated, and 0 otherwise.
	//
	// [Intel's documentation](https://www.intel.com/content/www/us/en/docs/intrinsics-guide/index.html#text=_rdseed64_step)
	@(require_results, enable_target_feature="rdseed")
	_rdseed64_step :: #force_inline proc "c" (val: ^u64) -> b32 {
		v, flag := llvm_rdseed64_step()
		val^ = v
		return flag
	}
}

@(private="file", default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.rdrand.16") llvm_rdrand16_step :: proc() -> (u16, b32) ---
	@(link_name="llvm.x86.rdrand.32") llvm_rdrand32_step :: proc() -> (u32, b32) ---
	@(link_name="llvm.x86.rdseed.16") llvm_rdseed16_step :: proc() -> (u16, b32) ---
	@(link_name="llvm.x86.rdseed.32") llvm_rdseed32_step :: proc() -> (u32, b32) ---
}

when ODIN_ARCH == .amd64 {
	@(private="file", default_calling_convention="none")
	foreign _ {
		@(link_name="llvm.x86.rdrand.64") llvm_rdrand64_step :: proc() -> (u64, b32) ---
		@(link_name="llvm.x86.rdseed.64") llvm_rdseed64_step :: proc() -> (u64, b32) ---
	}
}
