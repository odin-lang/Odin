#+build i386, amd64
package simd_x86

@(require_results)
_addcarry_u32 :: #force_inline proc "c" (c_in: u8, a: u32, b: u32, out: ^u32) -> u8 {
	x, y := llvm_addcarry_u32(c_in, a, b)
	out^ = y
	return x
}
@(require_results)
_addcarryx_u32 :: #force_inline proc "c" (c_in: u8, a: u32, b: u32, out: ^u32) -> u8 {
	return llvm_addcarryx_u32(c_in, a, b, out)
}
@(require_results)
_subborrow_u32 :: #force_inline proc "c" (c_in: u8, a: u32, b: u32, out: ^u32) -> u8 {
	x, y := llvm_subborrow_u32(c_in, a, b)
	out^ = y
	return x
}

when ODIN_ARCH == .amd64 {
	@(require_results)
	_addcarry_u64 :: #force_inline proc "c" (c_in: u8, a: u64, b: u64, out: ^u64) -> u8 {
		x, y := llvm_addcarry_u64(c_in, a, b)
		out^ = y
		return x
	}
	@(require_results)
	_addcarryx_u64 :: #force_inline proc "c" (c_in: u8, a: u64, b: u64, out: ^u64) -> u8 {
		return llvm_addcarryx_u64(c_in, a, b, out)
	}
	@(require_results)
	_subborrow_u64 :: #force_inline proc "c" (c_in: u8, a: u64, b: u64, out: ^u64) -> u8 {
		x, y := llvm_subborrow_u64(c_in, a, b)
		out^ = y
		return x
	}
}

@(private, default_calling_convention="none")
foreign _ {
	@(link_name="llvm.x86.addcarry.32")
	llvm_addcarry_u32  :: proc(a: u8, b: u32, c: u32) -> (u8, u32) ---
	@(link_name="llvm.x86.addcarryx.u32")
	llvm_addcarryx_u32 :: proc(a: u8, b: u32, c: u32, d: rawptr) -> u8 ---
	@(link_name="llvm.x86.subborrow.32")
	llvm_subborrow_u32 :: proc(a: u8, b: u32, c: u32) -> (u8, u32) ---

	// amd64 only
	@(link_name="llvm.x86.addcarry.64")
	llvm_addcarry_u64  :: proc(a: u8, b: u64, c: u64) -> (u8, u64) ---
	@(link_name="llvm.x86.addcarryx.u64")
	llvm_addcarryx_u64 :: proc(a: u8, b: u64, c: u64, d: rawptr) -> u8 ---
	@(link_name="llvm.x86.subborrow.64")
	llvm_subborrow_u64 :: proc(a: u8, b: u64, c: u64) -> (u8, u64) ---
}
