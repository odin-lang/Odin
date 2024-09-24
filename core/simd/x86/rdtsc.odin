#+build i386, amd64
package simd_x86

@(require_results)
_rdtsc :: #force_inline proc "c" () -> u64 {
	return rdtsc()
}

@(require_results)
__rdtscp :: #force_inline proc "c" (aux: ^u32) -> u64 {
	return rdtscp(aux)
}

@(private, default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.rdtsc")
	rdtsc  :: proc() -> u64 ---
	@(link_name="llvm.x86.rdtscp")
	rdtscp :: proc(aux: rawptr) -> u64 ---
}