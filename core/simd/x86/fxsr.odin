#+build i386, amd64
package simd_x86

@(enable_target_feature="fxsr")
_fxsave :: #force_inline proc "c" (mem_addr: rawptr) {
	fxsave(mem_addr)
}
@(enable_target_feature="fxsr")
_fxrstor :: #force_inline proc "c" (mem_addr: rawptr) {
	fxrstor(mem_addr)
}

when ODIN_ARCH == .amd64 {
	@(enable_target_feature="fxsr")
	_fxsave64 :: #force_inline proc "c" (mem_addr: rawptr) {
		fxsave64(mem_addr)
	}
	@(enable_target_feature="fxsr")
	_fxrstor64 :: #force_inline proc "c" (mem_addr: rawptr) {
		fxrstor64(mem_addr)
	}
}

@(private, default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.fxsave")
	fxsave    :: proc(p: rawptr) ---
	@(link_name="llvm.x86.fxrstor")
	fxrstor   :: proc(p: rawptr) ---

	// amd64 only
	@(link_name="llvm.x86.fxsave64")
	fxsave64  :: proc(p: rawptr) ---
	@(link_name="llvm.x86.fxrstor64")
	fxrstor64 :: proc(p: rawptr) ---
}