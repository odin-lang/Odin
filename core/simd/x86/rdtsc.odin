//+build i386, amd64
package simd_x86

_rdtsc :: #force_inline proc "c" () -> u64 {
	return rdtsc()
}

__rdtscp :: #force_inline proc "c" (aux: ^u32) -> u64 {
	return rdtscp(aux)
}

@(private, default_calling_convention="c")
foreign _ {
	@(link_name="llvm.x86.rdtsc")
	rdtsc  :: proc() -> u64 ---
	@(link_name="llvm.x86.rdtscp")
	rdtscp :: proc(aux: rawptr) -> u64 ---
}